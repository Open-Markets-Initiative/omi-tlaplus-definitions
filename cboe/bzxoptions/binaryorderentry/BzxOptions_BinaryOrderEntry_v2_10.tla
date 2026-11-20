----------------- MODULE BzxOptions_BinaryOrderEntry_v2_10 -----------------
(***************************************************************************)
(* Chicago Board Options Exchange Binary Order Entry v2.10                 *)
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
(* Note: A field marked present by fields read before it is read only when *)
(* they say it is there, and the records checked hold it exactly where     *)
(* they do: one holding it anywhere else is no message the protocol sends. *)
(*                                                                         *)
(* Note: Login Request Message fills what is left of the frame Message     *)
(* Length states, which is what it is read from.                           *)
(*                                                                         *)
(* Note: Login Response Message fills what is left of the frame Message    *)
(* Length states, which is what it is read from.                           *)
(*                                                                         *)
(* Note: Logout Message fills what is left of the frame Message Length     *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: New Order Message fills what is left of the frame Message Length  *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Cancel Order Message fills what is left of the frame Message      *)
(* Length states, which is what it is read from.                           *)
(*                                                                         *)
(* Note: Modify Order Message fills what is left of the frame Message      *)
(* Length states, which is what it is read from.                           *)
(*                                                                         *)
(* Note: Quote Update Message fills what is left of the frame Message      *)
(* Length states, which is what it is read from.                           *)
(*                                                                         *)
(* Note: Short Quote Update Message fills what is left of the frame        *)
(* Message Length states, which is what it is read from.                   *)
(*                                                                         *)
(* Note: Purge Order Message fills what is left of the frame Message       *)
(* Length states, which is what it is read from.                           *)
(*                                                                         *)
(* Note: Risk Reset Message fills what is left of the frame Message Length *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Order Acknowledgment Message fills what is left of the frame      *)
(* Message Length states, which is what it is read from.                   *)
(*                                                                         *)
(* Note: Quote Update Acknowledgment Message fills what is left of the     *)
(* frame Message Length states, which is what it is read from.             *)
(*                                                                         *)
(* Note: Order Rejected Message fills what is left of the frame Message    *)
(* Length states, which is what it is read from.                           *)
(*                                                                         *)
(* Note: Quote Update Rejected Message fills what is left of the frame     *)
(* Message Length states, which is what it is read from.                   *)
(*                                                                         *)
(* Note: Order Modified Message fills what is left of the frame Message    *)
(* Length states, which is what it is read from.                           *)
(*                                                                         *)
(* Note: Order Restated Message fills what is left of the frame Message    *)
(* Length states, which is what it is read from.                           *)
(*                                                                         *)
(* Note: Quote Restated Message fills what is left of the frame Message    *)
(* Length states, which is what it is read from.                           *)
(*                                                                         *)
(* Note: User Modify Rejected Message fills what is left of the frame      *)
(* Message Length states, which is what it is read from.                   *)
(*                                                                         *)
(* Note: Order Cancelled Message fills what is left of the frame Message   *)
(* Length states, which is what it is read from.                           *)
(*                                                                         *)
(* Note: Quote Cancelled Message fills what is left of the frame Message   *)
(* Length states, which is what it is read from.                           *)
(*                                                                         *)
(* Note: Cancel Rejected Message fills what is left of the frame Message   *)
(* Length states, which is what it is read from.                           *)
(*                                                                         *)
(* Note: Quote Execution Message fills what is left of the frame Message   *)
(* Length states, which is what it is read from.                           *)
(*                                                                         *)
(* Note: Trade Cancel Or Correct Message fills what is left of the frame   *)
(* Message Length states, which is what it is read from.                   *)
(*                                                                         *)
(* Note: Purge Rejected Message fills what is left of the frame Message    *)
(* Length states, which is what it is read from.                           *)
(*                                                                         *)
(* Note: Reset Risk Acknowledgment Message fills what is left of the frame *)
(* Message Length states, which is what it is read from.                   *)
(*                                                                         *)
(* Note: Mass Cancel Acknowledgment Message fills what is left of the      *)
(* frame Message Length states, which is what it is read from.             *)
(*                                                                         *)
(* Note: Order Execution Message fills what is left of the frame Message   *)
(* Length states, which is what it is read from.                           *)
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

(* A field there only when what was read before it says so: read when it is, and held *)
(* as a sequence of the one value it read, or of none when it is not there. *)
ReadWhen(holds, read, bytes) ==
    IF ~holds
    THEN Ok(<< >>, bytes)
    ELSE IF ~read.ok THEN Fail ELSE Ok(<<read.value>>, read.rest)

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
(* Unit Sequence: 5 bytes                                                  *)
(***************************************************************************)

UnitSequence ==
    [ unitNumber         : Sample(1),
      unitSequenceNumber : Sample(4) ]

EncodeUnitSequence(message) ==
    message.unitNumber
        \o message.unitSequenceNumber

DecodeUnitSequence(bytes) ==
    LET unitNumber == ReadBytes(bytes, 1) IN IF ~unitNumber.ok THEN Fail ELSE
    LET unitSequenceNumber == ReadBytes(unitNumber.rest, 4) IN IF ~unitSequenceNumber.ok THEN Fail ELSE
    Ok([ unitNumber         |-> unitNumber.value,
         unitSequenceNumber |-> unitSequenceNumber.value ], unitSequenceNumber.rest)

ZeroUnitSequence ==
    [ unitNumber         |-> [i \in 1 .. 1 |-> 0],
      unitSequenceNumber |-> [i \in 1 .. 4 |-> 0] ]

(* Unit Sequence at zero, then each field in turn at the values it is checked at *)
CheckedUnitSequence ==
    { ZeroUnitSequence }
        \cup { [ZeroUnitSequence EXCEPT !.unitNumber = one] : one \in Sample(1) }
        \cup { [ZeroUnitSequence EXCEPT !.unitSequenceNumber = one] : one \in Sample(4) }

(* A run of Unit Sequence, written one after another *)
RECURSIVE EncodeUnitSequenceList(_)
EncodeUnitSequenceList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeUnitSequence(Head(messages)) \o EncodeUnitSequenceList(Tail(messages))

(* As many Unit Sequence as the field that counts them says *)
RECURSIVE ReadUnitSequenceList(_, _)
ReadUnitSequenceList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeUnitSequence(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadUnitSequenceList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Unit Sequence of each kind, for the lists that carry them *)
OneUnitSequence == { ZeroUnitSequence }

(***************************************************************************)
(* Unit Sequences Param Group                                              *)
(***************************************************************************)

UnitSequencesParamGroup ==
    [ noUnspecifiedUnitReplay : Sample(1),
      unitSequence            : SampleLists(OneUnitSequence) ]

EncodeUnitSequencesParamGroup(message) ==
    message.noUnspecifiedUnitReplay
        \o EncodeUIntBE(Len(message.unitSequence), 1)
        \o EncodeUnitSequenceList(message.unitSequence)

DecodeUnitSequencesParamGroup(bytes) ==
    LET noUnspecifiedUnitReplay == ReadBytes(bytes, 1) IN IF ~noUnspecifiedUnitReplay.ok THEN Fail ELSE
    LET numberOfUnits == ReadUIntBE(noUnspecifiedUnitReplay.rest, 1) IN IF ~numberOfUnits.ok THEN Fail ELSE
    LET unitSequence == ReadUnitSequenceList(numberOfUnits.rest, numberOfUnits.value) IN IF ~unitSequence.ok THEN Fail ELSE
    Ok([ noUnspecifiedUnitReplay |-> noUnspecifiedUnitReplay.value,
         unitSequence            |-> unitSequence.value ], unitSequence.rest)

ZeroUnitSequencesParamGroup ==
    [ noUnspecifiedUnitReplay |-> [i \in 1 .. 1 |-> 0],
      unitSequence            |-> << >> ]

(* Unit Sequences Param Group at zero, then each field in turn at the values it is checked at *)
CheckedUnitSequencesParamGroup ==
    { ZeroUnitSequencesParamGroup }
        \cup { [ZeroUnitSequencesParamGroup EXCEPT !.noUnspecifiedUnitReplay = one] : one \in Sample(1) }
        \cup { [ZeroUnitSequencesParamGroup EXCEPT !.unitSequence = one] : one \in SampleLists(OneUnitSequence) }

(***************************************************************************)
(* Return Bitfields Param Group                                            *)
(***************************************************************************)

ReturnBitfieldsParamGroup ==
    [ messageType             : Sample(1),
      numberOfReturnBitfields : 0 .. 255,
      returnBitfield1         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield2         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield3         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield4         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield5         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield6         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield7         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield8         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield9         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield10        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield11        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield12        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield13        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield14        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield15        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield16        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield17        : { << >> } \cup { <<held>> : held \in Sample(1) } ]

EncodeReturnBitfieldsParamGroup(message) ==
    message.messageType
        \o EncodeUIntBE(message.numberOfReturnBitfields, 1)
        \o (IF message.returnBitfield1 = << >> THEN << >> ELSE message.returnBitfield1[1])
        \o (IF message.returnBitfield2 = << >> THEN << >> ELSE message.returnBitfield2[1])
        \o (IF message.returnBitfield3 = << >> THEN << >> ELSE message.returnBitfield3[1])
        \o (IF message.returnBitfield4 = << >> THEN << >> ELSE message.returnBitfield4[1])
        \o (IF message.returnBitfield5 = << >> THEN << >> ELSE message.returnBitfield5[1])
        \o (IF message.returnBitfield6 = << >> THEN << >> ELSE message.returnBitfield6[1])
        \o (IF message.returnBitfield7 = << >> THEN << >> ELSE message.returnBitfield7[1])
        \o (IF message.returnBitfield8 = << >> THEN << >> ELSE message.returnBitfield8[1])
        \o (IF message.returnBitfield9 = << >> THEN << >> ELSE message.returnBitfield9[1])
        \o (IF message.returnBitfield10 = << >> THEN << >> ELSE message.returnBitfield10[1])
        \o (IF message.returnBitfield11 = << >> THEN << >> ELSE message.returnBitfield11[1])
        \o (IF message.returnBitfield12 = << >> THEN << >> ELSE message.returnBitfield12[1])
        \o (IF message.returnBitfield13 = << >> THEN << >> ELSE message.returnBitfield13[1])
        \o (IF message.returnBitfield14 = << >> THEN << >> ELSE message.returnBitfield14[1])
        \o (IF message.returnBitfield15 = << >> THEN << >> ELSE message.returnBitfield15[1])
        \o (IF message.returnBitfield16 = << >> THEN << >> ELSE message.returnBitfield16[1])
        \o (IF message.returnBitfield17 = << >> THEN << >> ELSE message.returnBitfield17[1])

DecodeReturnBitfieldsParamGroup(bytes) ==
    LET messageType == ReadBytes(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET numberOfReturnBitfields == ReadUIntBE(messageType.rest, 1) IN IF ~numberOfReturnBitfields.ok THEN Fail ELSE
    LET returnBitfield1 == ReadWhen(numberOfReturnBitfields.value >= 1, ReadBytes(numberOfReturnBitfields.rest, 1), numberOfReturnBitfields.rest) IN IF ~returnBitfield1.ok THEN Fail ELSE
    LET returnBitfield2 == ReadWhen(numberOfReturnBitfields.value >= 2, ReadBytes(returnBitfield1.rest, 1), returnBitfield1.rest) IN IF ~returnBitfield2.ok THEN Fail ELSE
    LET returnBitfield3 == ReadWhen(numberOfReturnBitfields.value >= 3, ReadBytes(returnBitfield2.rest, 1), returnBitfield2.rest) IN IF ~returnBitfield3.ok THEN Fail ELSE
    LET returnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadBytes(returnBitfield3.rest, 1), returnBitfield3.rest) IN IF ~returnBitfield4.ok THEN Fail ELSE
    LET returnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadBytes(returnBitfield4.rest, 1), returnBitfield4.rest) IN IF ~returnBitfield5.ok THEN Fail ELSE
    LET returnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadBytes(returnBitfield5.rest, 1), returnBitfield5.rest) IN IF ~returnBitfield6.ok THEN Fail ELSE
    LET returnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadBytes(returnBitfield6.rest, 1), returnBitfield6.rest) IN IF ~returnBitfield7.ok THEN Fail ELSE
    LET returnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadBytes(returnBitfield7.rest, 1), returnBitfield7.rest) IN IF ~returnBitfield8.ok THEN Fail ELSE
    LET returnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadBytes(returnBitfield8.rest, 1), returnBitfield8.rest) IN IF ~returnBitfield9.ok THEN Fail ELSE
    LET returnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadBytes(returnBitfield9.rest, 1), returnBitfield9.rest) IN IF ~returnBitfield10.ok THEN Fail ELSE
    LET returnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadBytes(returnBitfield10.rest, 1), returnBitfield10.rest) IN IF ~returnBitfield11.ok THEN Fail ELSE
    LET returnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadBytes(returnBitfield11.rest, 1), returnBitfield11.rest) IN IF ~returnBitfield12.ok THEN Fail ELSE
    LET returnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(returnBitfield12.rest, 1), returnBitfield12.rest) IN IF ~returnBitfield13.ok THEN Fail ELSE
    LET returnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(returnBitfield13.rest, 1), returnBitfield13.rest) IN IF ~returnBitfield14.ok THEN Fail ELSE
    LET returnBitfield15 == ReadWhen(numberOfReturnBitfields.value >= 15, ReadBytes(returnBitfield14.rest, 1), returnBitfield14.rest) IN IF ~returnBitfield15.ok THEN Fail ELSE
    LET returnBitfield16 == ReadWhen(numberOfReturnBitfields.value >= 16, ReadBytes(returnBitfield15.rest, 1), returnBitfield15.rest) IN IF ~returnBitfield16.ok THEN Fail ELSE
    LET returnBitfield17 == ReadWhen(numberOfReturnBitfields.value >= 17, ReadBytes(returnBitfield16.rest, 1), returnBitfield16.rest) IN IF ~returnBitfield17.ok THEN Fail ELSE
    Ok([ messageType             |-> messageType.value,
         numberOfReturnBitfields |-> numberOfReturnBitfields.value,
         returnBitfield1         |-> returnBitfield1.value,
         returnBitfield2         |-> returnBitfield2.value,
         returnBitfield3         |-> returnBitfield3.value,
         returnBitfield4         |-> returnBitfield4.value,
         returnBitfield5         |-> returnBitfield5.value,
         returnBitfield6         |-> returnBitfield6.value,
         returnBitfield7         |-> returnBitfield7.value,
         returnBitfield8         |-> returnBitfield8.value,
         returnBitfield9         |-> returnBitfield9.value,
         returnBitfield10        |-> returnBitfield10.value,
         returnBitfield11        |-> returnBitfield11.value,
         returnBitfield12        |-> returnBitfield12.value,
         returnBitfield13        |-> returnBitfield13.value,
         returnBitfield14        |-> returnBitfield14.value,
         returnBitfield15        |-> returnBitfield15.value,
         returnBitfield16        |-> returnBitfield16.value,
         returnBitfield17        |-> returnBitfield17.value ], returnBitfield17.rest)

(* Return Bitfields Param Group with each field marked present by fields before it there exactly where they say *)
SettleReturnBitfieldsParamGroup(message) ==
    LET settled1 == [message EXCEPT !.returnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.returnBitfield1 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE message.returnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.returnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.returnBitfield2 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled1.returnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.returnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.returnBitfield3 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled2.returnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.returnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.returnBitfield4 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled3.returnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.returnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.returnBitfield5 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled4.returnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.returnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.returnBitfield6 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled5.returnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.returnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.returnBitfield7 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.returnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.returnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.returnBitfield8 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled7.returnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.returnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.returnBitfield9 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled8.returnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.returnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.returnBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.returnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.returnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.returnBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.returnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.returnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.returnBitfield12 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.returnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.returnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.returnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.returnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.returnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.returnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.returnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.returnBitfield15 = IF settled14.numberOfReturnBitfields >= 15 THEN (IF settled14.returnBitfield15 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.returnBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.returnBitfield16 = IF settled15.numberOfReturnBitfields >= 16 THEN (IF settled15.returnBitfield16 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled15.returnBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.returnBitfield17 = IF settled16.numberOfReturnBitfields >= 17 THEN (IF settled16.returnBitfield17 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled16.returnBitfield17) ELSE << >>]
    IN  settled17

ZeroReturnBitfieldsParamGroup ==
    SettleReturnBitfieldsParamGroup([ messageType             |-> [i \in 1 .. 1 |-> 0],
                                      numberOfReturnBitfields |-> 0,
                                      returnBitfield1         |-> << >>,
                                      returnBitfield2         |-> << >>,
                                      returnBitfield3         |-> << >>,
                                      returnBitfield4         |-> << >>,
                                      returnBitfield5         |-> << >>,
                                      returnBitfield6         |-> << >>,
                                      returnBitfield7         |-> << >>,
                                      returnBitfield8         |-> << >>,
                                      returnBitfield9         |-> << >>,
                                      returnBitfield10        |-> << >>,
                                      returnBitfield11        |-> << >>,
                                      returnBitfield12        |-> << >>,
                                      returnBitfield13        |-> << >>,
                                      returnBitfield14        |-> << >>,
                                      returnBitfield15        |-> << >>,
                                      returnBitfield16        |-> << >>,
                                      returnBitfield17        |-> << >> ])

(* Return Bitfields Param Group at zero, then each field in turn at the values it is checked at *)
CheckedReturnBitfieldsParamGroup ==
    { ZeroReturnBitfieldsParamGroup }
        \cup { SettleReturnBitfieldsParamGroup([ZeroReturnBitfieldsParamGroup EXCEPT !.messageType = one]) : one \in Sample(1) }
        \cup { SettleReturnBitfieldsParamGroup([ZeroReturnBitfieldsParamGroup EXCEPT !.numberOfReturnBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleReturnBitfieldsParamGroup([ZeroReturnBitfieldsParamGroup EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup([ZeroReturnBitfieldsParamGroup EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup([ZeroReturnBitfieldsParamGroup EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup([ZeroReturnBitfieldsParamGroup EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup([ZeroReturnBitfieldsParamGroup EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup([ZeroReturnBitfieldsParamGroup EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup([ZeroReturnBitfieldsParamGroup EXCEPT !.numberOfReturnBitfields = 7, !.returnBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup([ZeroReturnBitfieldsParamGroup EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup([ZeroReturnBitfieldsParamGroup EXCEPT !.numberOfReturnBitfields = 9, !.returnBitfield9 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup([ZeroReturnBitfieldsParamGroup EXCEPT !.numberOfReturnBitfields = 10, !.returnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup([ZeroReturnBitfieldsParamGroup EXCEPT !.numberOfReturnBitfields = 11, !.returnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup([ZeroReturnBitfieldsParamGroup EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup([ZeroReturnBitfieldsParamGroup EXCEPT !.numberOfReturnBitfields = 13, !.returnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup([ZeroReturnBitfieldsParamGroup EXCEPT !.numberOfReturnBitfields = 14, !.returnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup([ZeroReturnBitfieldsParamGroup EXCEPT !.numberOfReturnBitfields = 15, !.returnBitfield15 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup([ZeroReturnBitfieldsParamGroup EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup([ZeroReturnBitfieldsParamGroup EXCEPT !.numberOfReturnBitfields = 17, !.returnBitfield17 = one]) : one \in { <<held>> : held \in Sample(1) } }

(***************************************************************************)
(* ParamGroupPayload, selected by Param Group Type                         *)
(***************************************************************************)

UnitSequencesParamGroupCode == 128  \* 0x80
ReturnBitfieldsParamGroupCode == 129  \* 0x81

Paramgrouppayload ==
    [ tag : {UnitSequencesParamGroupCode}, body : UnitSequencesParamGroup ]
        \cup [ tag : {ReturnBitfieldsParamGroupCode}, body : ReturnBitfieldsParamGroup ]

EncodeParamgrouppayload(message) ==
    CASE message.tag = UnitSequencesParamGroupCode -> EncodeUnitSequencesParamGroup(message.body)
      [] message.tag = ReturnBitfieldsParamGroupCode -> EncodeReturnBitfieldsParamGroup(message.body)

DecodeParamgrouppayload(tag, bytes) ==
    LET read ==
            CASE tag = UnitSequencesParamGroupCode -> DecodeUnitSequencesParamGroup(bytes)
              [] tag = ReturnBitfieldsParamGroupCode -> DecodeReturnBitfieldsParamGroup(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroParamgrouppayload == [tag |-> UnitSequencesParamGroupCode, body |-> ZeroUnitSequencesParamGroup]

(* Each ParamGroupPayload in turn, at the values the message it names is checked at *)
CheckedParamgrouppayload ==
    { [tag |-> UnitSequencesParamGroupCode, body |-> one] : one \in CheckedUnitSequencesParamGroup }
        \cup { [tag |-> ReturnBitfieldsParamGroupCode, body |-> one] : one \in CheckedReturnBitfieldsParamGroup }

(***************************************************************************)
(* Param Group                                                             *)
(***************************************************************************)

ParamGroup ==
    [ paramGroupLength  : Sample(2),
      paramgrouppayload : Paramgrouppayload ]

EncodeParamGroup(message) ==
    message.paramGroupLength
        \o EncodeUIntBE(message.paramgrouppayload.tag, 1)
        \o EncodeParamgrouppayload(message.paramgrouppayload)

DecodeParamGroup(bytes) ==
    LET paramGroupLength == ReadBytes(bytes, 2) IN IF ~paramGroupLength.ok THEN Fail ELSE
    LET paramGroupType == ReadUIntBE(paramGroupLength.rest, 1) IN IF ~paramGroupType.ok THEN Fail ELSE
    LET paramgrouppayload == DecodeParamgrouppayload(paramGroupType.value, paramGroupType.rest) IN IF ~paramgrouppayload.ok THEN Fail ELSE
    Ok([ paramGroupLength  |-> paramGroupLength.value,
         paramgrouppayload |-> paramgrouppayload.value ], paramgrouppayload.rest)

ZeroParamGroup ==
    [ paramGroupLength  |-> [i \in 1 .. 2 |-> 0],
      paramgrouppayload |-> ZeroParamgrouppayload ]

(* Param Group at zero, then each field in turn at the values it is checked at *)
CheckedParamGroup ==
    { ZeroParamGroup }
        \cup { [ZeroParamGroup EXCEPT !.paramGroupLength = one] : one \in Sample(2) }
        \cup { [ZeroParamGroup EXCEPT !.paramgrouppayload = one] : one \in CheckedParamgrouppayload }

(* A run of Param Group, written one after another *)
RECURSIVE EncodeParamGroupList(_)
EncodeParamGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeParamGroup(Head(messages)) \o EncodeParamGroupList(Tail(messages))

(* As many Param Group as the field that counts them says *)
RECURSIVE ReadParamGroupList(_, _)
ReadParamGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeParamGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadParamGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Param Group of each kind, for the lists that carry them *)
OneParamGroup ==
    { [ZeroParamGroup EXCEPT !.paramgrouppayload = [tag |-> UnitSequencesParamGroupCode, body |-> ZeroUnitSequencesParamGroup]],
      [ZeroParamGroup EXCEPT !.paramgrouppayload = [tag |-> ReturnBitfieldsParamGroupCode, body |-> ZeroReturnBitfieldsParamGroup]] }

(***************************************************************************)
(* Login Request Message                                                   *)
(***************************************************************************)

LoginRequestMessage ==
    [ sessionSubId : Sample(4),
      username     : Sample(4),
      password     : Sample(10),
      paramGroup   : SampleLists(OneParamGroup) ]

EncodeLoginRequestMessage(message) ==
    message.sessionSubId
        \o message.username
        \o message.password
        \o EncodeUIntBE(Len(message.paramGroup), 1)
        \o EncodeParamGroupList(message.paramGroup)

DecodeLoginRequestMessage(bytes) ==
    LET sessionSubId == ReadBytes(bytes, 4) IN IF ~sessionSubId.ok THEN Fail ELSE
    LET username == ReadBytes(sessionSubId.rest, 4) IN IF ~username.ok THEN Fail ELSE
    LET password == ReadBytes(username.rest, 10) IN IF ~password.ok THEN Fail ELSE
    LET numberOfParamGroups == ReadUIntBE(password.rest, 1) IN IF ~numberOfParamGroups.ok THEN Fail ELSE
    LET paramGroup == ReadParamGroupList(numberOfParamGroups.rest, numberOfParamGroups.value) IN IF ~paramGroup.ok THEN Fail ELSE
    Ok([ sessionSubId |-> sessionSubId.value,
         username     |-> username.value,
         password     |-> password.value,
         paramGroup   |-> paramGroup.value ], paramGroup.rest)

ZeroLoginRequestMessage ==
    [ sessionSubId |-> [i \in 1 .. 4 |-> 0],
      username     |-> [i \in 1 .. 4 |-> 0],
      password     |-> [i \in 1 .. 10 |-> 0],
      paramGroup   |-> << >> ]

(* Login Request Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginRequestMessage ==
    { ZeroLoginRequestMessage }
        \cup { [ZeroLoginRequestMessage EXCEPT !.sessionSubId = one] : one \in Sample(4) }
        \cup { [ZeroLoginRequestMessage EXCEPT !.username = one] : one \in Sample(4) }
        \cup { [ZeroLoginRequestMessage EXCEPT !.password = one] : one \in Sample(10) }
        \cup { [ZeroLoginRequestMessage EXCEPT !.paramGroup = one] : one \in SampleLists(OneParamGroup) }

(***************************************************************************)
(* Unit Sequence: 5 bytes                                                  *)
(***************************************************************************)

UnitSequence2 ==
    [ unitNumber         : Sample(1),
      unitSequenceNumber : Sample(4) ]

EncodeUnitSequence2(message) ==
    message.unitNumber
        \o message.unitSequenceNumber

DecodeUnitSequence2(bytes) ==
    LET unitNumber == ReadBytes(bytes, 1) IN IF ~unitNumber.ok THEN Fail ELSE
    LET unitSequenceNumber == ReadBytes(unitNumber.rest, 4) IN IF ~unitSequenceNumber.ok THEN Fail ELSE
    Ok([ unitNumber         |-> unitNumber.value,
         unitSequenceNumber |-> unitSequenceNumber.value ], unitSequenceNumber.rest)

ZeroUnitSequence2 ==
    [ unitNumber         |-> [i \in 1 .. 1 |-> 0],
      unitSequenceNumber |-> [i \in 1 .. 4 |-> 0] ]

(* Unit Sequence at zero, then each field in turn at the values it is checked at *)
CheckedUnitSequence2 ==
    { ZeroUnitSequence2 }
        \cup { [ZeroUnitSequence2 EXCEPT !.unitNumber = one] : one \in Sample(1) }
        \cup { [ZeroUnitSequence2 EXCEPT !.unitSequenceNumber = one] : one \in Sample(4) }

(* A run of Unit Sequence, written one after another *)
RECURSIVE EncodeUnitSequence2List(_)
EncodeUnitSequence2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeUnitSequence2(Head(messages)) \o EncodeUnitSequence2List(Tail(messages))

(* As many Unit Sequence as the field that counts them says *)
RECURSIVE ReadUnitSequence2List(_, _)
ReadUnitSequence2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeUnitSequence2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadUnitSequence2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Unit Sequence of each kind, for the lists that carry them *)
OneUnitSequence2 == { ZeroUnitSequence2 }

(***************************************************************************)
(* Unit Sequence: 5 bytes                                                  *)
(***************************************************************************)

UnitSequence3 ==
    [ unitNumber         : Sample(1),
      unitSequenceNumber : Sample(4) ]

EncodeUnitSequence3(message) ==
    message.unitNumber
        \o message.unitSequenceNumber

DecodeUnitSequence3(bytes) ==
    LET unitNumber == ReadBytes(bytes, 1) IN IF ~unitNumber.ok THEN Fail ELSE
    LET unitSequenceNumber == ReadBytes(unitNumber.rest, 4) IN IF ~unitSequenceNumber.ok THEN Fail ELSE
    Ok([ unitNumber         |-> unitNumber.value,
         unitSequenceNumber |-> unitSequenceNumber.value ], unitSequenceNumber.rest)

ZeroUnitSequence3 ==
    [ unitNumber         |-> [i \in 1 .. 1 |-> 0],
      unitSequenceNumber |-> [i \in 1 .. 4 |-> 0] ]

(* Unit Sequence at zero, then each field in turn at the values it is checked at *)
CheckedUnitSequence3 ==
    { ZeroUnitSequence3 }
        \cup { [ZeroUnitSequence3 EXCEPT !.unitNumber = one] : one \in Sample(1) }
        \cup { [ZeroUnitSequence3 EXCEPT !.unitSequenceNumber = one] : one \in Sample(4) }

(* A run of Unit Sequence, written one after another *)
RECURSIVE EncodeUnitSequence3List(_)
EncodeUnitSequence3List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeUnitSequence3(Head(messages)) \o EncodeUnitSequence3List(Tail(messages))

(* As many Unit Sequence as the field that counts them says *)
RECURSIVE ReadUnitSequence3List(_, _)
ReadUnitSequence3List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeUnitSequence3(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadUnitSequence3List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Unit Sequence of each kind, for the lists that carry them *)
OneUnitSequence3 == { ZeroUnitSequence3 }

(***************************************************************************)
(* Unit Sequences Param Group                                              *)
(***************************************************************************)

UnitSequencesParamGroup2 ==
    [ noUnspecifiedUnitReplay : Sample(1),
      unitSequence            : SampleLists(OneUnitSequence3) ]

EncodeUnitSequencesParamGroup2(message) ==
    message.noUnspecifiedUnitReplay
        \o EncodeUIntBE(Len(message.unitSequence), 1)
        \o EncodeUnitSequence3List(message.unitSequence)

DecodeUnitSequencesParamGroup2(bytes) ==
    LET noUnspecifiedUnitReplay == ReadBytes(bytes, 1) IN IF ~noUnspecifiedUnitReplay.ok THEN Fail ELSE
    LET numberOfUnits == ReadUIntBE(noUnspecifiedUnitReplay.rest, 1) IN IF ~numberOfUnits.ok THEN Fail ELSE
    LET unitSequence == ReadUnitSequence3List(numberOfUnits.rest, numberOfUnits.value) IN IF ~unitSequence.ok THEN Fail ELSE
    Ok([ noUnspecifiedUnitReplay |-> noUnspecifiedUnitReplay.value,
         unitSequence            |-> unitSequence.value ], unitSequence.rest)

ZeroUnitSequencesParamGroup2 ==
    [ noUnspecifiedUnitReplay |-> [i \in 1 .. 1 |-> 0],
      unitSequence            |-> << >> ]

(* Unit Sequences Param Group at zero, then each field in turn at the values it is checked at *)
CheckedUnitSequencesParamGroup2 ==
    { ZeroUnitSequencesParamGroup2 }
        \cup { [ZeroUnitSequencesParamGroup2 EXCEPT !.noUnspecifiedUnitReplay = one] : one \in Sample(1) }
        \cup { [ZeroUnitSequencesParamGroup2 EXCEPT !.unitSequence = one] : one \in SampleLists(OneUnitSequence3) }

(***************************************************************************)
(* Return Bitfields Param Group                                            *)
(***************************************************************************)

ReturnBitfieldsParamGroup2 ==
    [ messageType             : Sample(1),
      numberOfReturnBitfields : 0 .. 255,
      returnBitfield1         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield2         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield3         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield4         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield5         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield6         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield7         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield8         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield9         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield10        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield11        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield12        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield13        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield14        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield15        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield16        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield17        : { << >> } \cup { <<held>> : held \in Sample(1) } ]

EncodeReturnBitfieldsParamGroup2(message) ==
    message.messageType
        \o EncodeUIntBE(message.numberOfReturnBitfields, 1)
        \o (IF message.returnBitfield1 = << >> THEN << >> ELSE message.returnBitfield1[1])
        \o (IF message.returnBitfield2 = << >> THEN << >> ELSE message.returnBitfield2[1])
        \o (IF message.returnBitfield3 = << >> THEN << >> ELSE message.returnBitfield3[1])
        \o (IF message.returnBitfield4 = << >> THEN << >> ELSE message.returnBitfield4[1])
        \o (IF message.returnBitfield5 = << >> THEN << >> ELSE message.returnBitfield5[1])
        \o (IF message.returnBitfield6 = << >> THEN << >> ELSE message.returnBitfield6[1])
        \o (IF message.returnBitfield7 = << >> THEN << >> ELSE message.returnBitfield7[1])
        \o (IF message.returnBitfield8 = << >> THEN << >> ELSE message.returnBitfield8[1])
        \o (IF message.returnBitfield9 = << >> THEN << >> ELSE message.returnBitfield9[1])
        \o (IF message.returnBitfield10 = << >> THEN << >> ELSE message.returnBitfield10[1])
        \o (IF message.returnBitfield11 = << >> THEN << >> ELSE message.returnBitfield11[1])
        \o (IF message.returnBitfield12 = << >> THEN << >> ELSE message.returnBitfield12[1])
        \o (IF message.returnBitfield13 = << >> THEN << >> ELSE message.returnBitfield13[1])
        \o (IF message.returnBitfield14 = << >> THEN << >> ELSE message.returnBitfield14[1])
        \o (IF message.returnBitfield15 = << >> THEN << >> ELSE message.returnBitfield15[1])
        \o (IF message.returnBitfield16 = << >> THEN << >> ELSE message.returnBitfield16[1])
        \o (IF message.returnBitfield17 = << >> THEN << >> ELSE message.returnBitfield17[1])

DecodeReturnBitfieldsParamGroup2(bytes) ==
    LET messageType == ReadBytes(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET numberOfReturnBitfields == ReadUIntBE(messageType.rest, 1) IN IF ~numberOfReturnBitfields.ok THEN Fail ELSE
    LET returnBitfield1 == ReadWhen(numberOfReturnBitfields.value >= 1, ReadBytes(numberOfReturnBitfields.rest, 1), numberOfReturnBitfields.rest) IN IF ~returnBitfield1.ok THEN Fail ELSE
    LET returnBitfield2 == ReadWhen(numberOfReturnBitfields.value >= 2, ReadBytes(returnBitfield1.rest, 1), returnBitfield1.rest) IN IF ~returnBitfield2.ok THEN Fail ELSE
    LET returnBitfield3 == ReadWhen(numberOfReturnBitfields.value >= 3, ReadBytes(returnBitfield2.rest, 1), returnBitfield2.rest) IN IF ~returnBitfield3.ok THEN Fail ELSE
    LET returnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadBytes(returnBitfield3.rest, 1), returnBitfield3.rest) IN IF ~returnBitfield4.ok THEN Fail ELSE
    LET returnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadBytes(returnBitfield4.rest, 1), returnBitfield4.rest) IN IF ~returnBitfield5.ok THEN Fail ELSE
    LET returnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadBytes(returnBitfield5.rest, 1), returnBitfield5.rest) IN IF ~returnBitfield6.ok THEN Fail ELSE
    LET returnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadBytes(returnBitfield6.rest, 1), returnBitfield6.rest) IN IF ~returnBitfield7.ok THEN Fail ELSE
    LET returnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadBytes(returnBitfield7.rest, 1), returnBitfield7.rest) IN IF ~returnBitfield8.ok THEN Fail ELSE
    LET returnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadBytes(returnBitfield8.rest, 1), returnBitfield8.rest) IN IF ~returnBitfield9.ok THEN Fail ELSE
    LET returnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadBytes(returnBitfield9.rest, 1), returnBitfield9.rest) IN IF ~returnBitfield10.ok THEN Fail ELSE
    LET returnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadBytes(returnBitfield10.rest, 1), returnBitfield10.rest) IN IF ~returnBitfield11.ok THEN Fail ELSE
    LET returnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadBytes(returnBitfield11.rest, 1), returnBitfield11.rest) IN IF ~returnBitfield12.ok THEN Fail ELSE
    LET returnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(returnBitfield12.rest, 1), returnBitfield12.rest) IN IF ~returnBitfield13.ok THEN Fail ELSE
    LET returnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(returnBitfield13.rest, 1), returnBitfield13.rest) IN IF ~returnBitfield14.ok THEN Fail ELSE
    LET returnBitfield15 == ReadWhen(numberOfReturnBitfields.value >= 15, ReadBytes(returnBitfield14.rest, 1), returnBitfield14.rest) IN IF ~returnBitfield15.ok THEN Fail ELSE
    LET returnBitfield16 == ReadWhen(numberOfReturnBitfields.value >= 16, ReadBytes(returnBitfield15.rest, 1), returnBitfield15.rest) IN IF ~returnBitfield16.ok THEN Fail ELSE
    LET returnBitfield17 == ReadWhen(numberOfReturnBitfields.value >= 17, ReadBytes(returnBitfield16.rest, 1), returnBitfield16.rest) IN IF ~returnBitfield17.ok THEN Fail ELSE
    Ok([ messageType             |-> messageType.value,
         numberOfReturnBitfields |-> numberOfReturnBitfields.value,
         returnBitfield1         |-> returnBitfield1.value,
         returnBitfield2         |-> returnBitfield2.value,
         returnBitfield3         |-> returnBitfield3.value,
         returnBitfield4         |-> returnBitfield4.value,
         returnBitfield5         |-> returnBitfield5.value,
         returnBitfield6         |-> returnBitfield6.value,
         returnBitfield7         |-> returnBitfield7.value,
         returnBitfield8         |-> returnBitfield8.value,
         returnBitfield9         |-> returnBitfield9.value,
         returnBitfield10        |-> returnBitfield10.value,
         returnBitfield11        |-> returnBitfield11.value,
         returnBitfield12        |-> returnBitfield12.value,
         returnBitfield13        |-> returnBitfield13.value,
         returnBitfield14        |-> returnBitfield14.value,
         returnBitfield15        |-> returnBitfield15.value,
         returnBitfield16        |-> returnBitfield16.value,
         returnBitfield17        |-> returnBitfield17.value ], returnBitfield17.rest)

(* Return Bitfields Param Group with each field marked present by fields before it there exactly where they say *)
SettleReturnBitfieldsParamGroup2(message) ==
    LET settled1 == [message EXCEPT !.returnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.returnBitfield1 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE message.returnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.returnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.returnBitfield2 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled1.returnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.returnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.returnBitfield3 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled2.returnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.returnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.returnBitfield4 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled3.returnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.returnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.returnBitfield5 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled4.returnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.returnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.returnBitfield6 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled5.returnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.returnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.returnBitfield7 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.returnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.returnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.returnBitfield8 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled7.returnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.returnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.returnBitfield9 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled8.returnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.returnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.returnBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.returnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.returnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.returnBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.returnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.returnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.returnBitfield12 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.returnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.returnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.returnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.returnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.returnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.returnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.returnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.returnBitfield15 = IF settled14.numberOfReturnBitfields >= 15 THEN (IF settled14.returnBitfield15 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.returnBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.returnBitfield16 = IF settled15.numberOfReturnBitfields >= 16 THEN (IF settled15.returnBitfield16 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled15.returnBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.returnBitfield17 = IF settled16.numberOfReturnBitfields >= 17 THEN (IF settled16.returnBitfield17 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled16.returnBitfield17) ELSE << >>]
    IN  settled17

ZeroReturnBitfieldsParamGroup2 ==
    SettleReturnBitfieldsParamGroup2([ messageType             |-> [i \in 1 .. 1 |-> 0],
                                       numberOfReturnBitfields |-> 0,
                                       returnBitfield1         |-> << >>,
                                       returnBitfield2         |-> << >>,
                                       returnBitfield3         |-> << >>,
                                       returnBitfield4         |-> << >>,
                                       returnBitfield5         |-> << >>,
                                       returnBitfield6         |-> << >>,
                                       returnBitfield7         |-> << >>,
                                       returnBitfield8         |-> << >>,
                                       returnBitfield9         |-> << >>,
                                       returnBitfield10        |-> << >>,
                                       returnBitfield11        |-> << >>,
                                       returnBitfield12        |-> << >>,
                                       returnBitfield13        |-> << >>,
                                       returnBitfield14        |-> << >>,
                                       returnBitfield15        |-> << >>,
                                       returnBitfield16        |-> << >>,
                                       returnBitfield17        |-> << >> ])

(* Return Bitfields Param Group at zero, then each field in turn at the values it is checked at *)
CheckedReturnBitfieldsParamGroup2 ==
    { ZeroReturnBitfieldsParamGroup2 }
        \cup { SettleReturnBitfieldsParamGroup2([ZeroReturnBitfieldsParamGroup2 EXCEPT !.messageType = one]) : one \in Sample(1) }
        \cup { SettleReturnBitfieldsParamGroup2([ZeroReturnBitfieldsParamGroup2 EXCEPT !.numberOfReturnBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleReturnBitfieldsParamGroup2([ZeroReturnBitfieldsParamGroup2 EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup2([ZeroReturnBitfieldsParamGroup2 EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup2([ZeroReturnBitfieldsParamGroup2 EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup2([ZeroReturnBitfieldsParamGroup2 EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup2([ZeroReturnBitfieldsParamGroup2 EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup2([ZeroReturnBitfieldsParamGroup2 EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup2([ZeroReturnBitfieldsParamGroup2 EXCEPT !.numberOfReturnBitfields = 7, !.returnBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup2([ZeroReturnBitfieldsParamGroup2 EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup2([ZeroReturnBitfieldsParamGroup2 EXCEPT !.numberOfReturnBitfields = 9, !.returnBitfield9 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup2([ZeroReturnBitfieldsParamGroup2 EXCEPT !.numberOfReturnBitfields = 10, !.returnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup2([ZeroReturnBitfieldsParamGroup2 EXCEPT !.numberOfReturnBitfields = 11, !.returnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup2([ZeroReturnBitfieldsParamGroup2 EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup2([ZeroReturnBitfieldsParamGroup2 EXCEPT !.numberOfReturnBitfields = 13, !.returnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup2([ZeroReturnBitfieldsParamGroup2 EXCEPT !.numberOfReturnBitfields = 14, !.returnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup2([ZeroReturnBitfieldsParamGroup2 EXCEPT !.numberOfReturnBitfields = 15, !.returnBitfield15 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup2([ZeroReturnBitfieldsParamGroup2 EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup2([ZeroReturnBitfieldsParamGroup2 EXCEPT !.numberOfReturnBitfields = 17, !.returnBitfield17 = one]) : one \in { <<held>> : held \in Sample(1) } }

(***************************************************************************)
(* ParamGroupPayload, selected by Param Group Type                         *)
(***************************************************************************)

UnitSequencesParamGroupCode2 == 128  \* 0x80
ReturnBitfieldsParamGroupCode2 == 129  \* 0x81

Paramgrouppayload2 ==
    [ tag : {UnitSequencesParamGroupCode2}, body : UnitSequencesParamGroup2 ]
        \cup [ tag : {ReturnBitfieldsParamGroupCode2}, body : ReturnBitfieldsParamGroup2 ]

EncodeParamgrouppayload2(message) ==
    CASE message.tag = UnitSequencesParamGroupCode2 -> EncodeUnitSequencesParamGroup2(message.body)
      [] message.tag = ReturnBitfieldsParamGroupCode2 -> EncodeReturnBitfieldsParamGroup2(message.body)

DecodeParamgrouppayload2(tag, bytes) ==
    LET read ==
            CASE tag = UnitSequencesParamGroupCode2 -> DecodeUnitSequencesParamGroup2(bytes)
              [] tag = ReturnBitfieldsParamGroupCode2 -> DecodeReturnBitfieldsParamGroup2(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroParamgrouppayload2 == [tag |-> UnitSequencesParamGroupCode2, body |-> ZeroUnitSequencesParamGroup2]

(* Each ParamGroupPayload in turn, at the values the message it names is checked at *)
CheckedParamgrouppayload2 ==
    { [tag |-> UnitSequencesParamGroupCode2, body |-> one] : one \in CheckedUnitSequencesParamGroup2 }
        \cup { [tag |-> ReturnBitfieldsParamGroupCode2, body |-> one] : one \in CheckedReturnBitfieldsParamGroup2 }

(***************************************************************************)
(* Param Group                                                             *)
(***************************************************************************)

ParamGroup2 ==
    [ paramGroupLength  : Sample(2),
      paramgrouppayload : Paramgrouppayload2 ]

EncodeParamGroup2(message) ==
    message.paramGroupLength
        \o EncodeUIntBE(message.paramgrouppayload.tag, 1)
        \o EncodeParamgrouppayload2(message.paramgrouppayload)

DecodeParamGroup2(bytes) ==
    LET paramGroupLength == ReadBytes(bytes, 2) IN IF ~paramGroupLength.ok THEN Fail ELSE
    LET paramGroupType == ReadUIntBE(paramGroupLength.rest, 1) IN IF ~paramGroupType.ok THEN Fail ELSE
    LET paramgrouppayload == DecodeParamgrouppayload2(paramGroupType.value, paramGroupType.rest) IN IF ~paramgrouppayload.ok THEN Fail ELSE
    Ok([ paramGroupLength  |-> paramGroupLength.value,
         paramgrouppayload |-> paramgrouppayload.value ], paramgrouppayload.rest)

ZeroParamGroup2 ==
    [ paramGroupLength  |-> [i \in 1 .. 2 |-> 0],
      paramgrouppayload |-> ZeroParamgrouppayload2 ]

(* Param Group at zero, then each field in turn at the values it is checked at *)
CheckedParamGroup2 ==
    { ZeroParamGroup2 }
        \cup { [ZeroParamGroup2 EXCEPT !.paramGroupLength = one] : one \in Sample(2) }
        \cup { [ZeroParamGroup2 EXCEPT !.paramgrouppayload = one] : one \in CheckedParamgrouppayload2 }

(* A run of Param Group, written one after another *)
RECURSIVE EncodeParamGroup2List(_)
EncodeParamGroup2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeParamGroup2(Head(messages)) \o EncodeParamGroup2List(Tail(messages))

(* As many Param Group as the field that counts them says *)
RECURSIVE ReadParamGroup2List(_, _)
ReadParamGroup2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeParamGroup2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadParamGroup2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Param Group of each kind, for the lists that carry them *)
OneParamGroup2 ==
    { [ZeroParamGroup2 EXCEPT !.paramgrouppayload = [tag |-> UnitSequencesParamGroupCode2, body |-> ZeroUnitSequencesParamGroup2]],
      [ZeroParamGroup2 EXCEPT !.paramgrouppayload = [tag |-> ReturnBitfieldsParamGroupCode2, body |-> ZeroReturnBitfieldsParamGroup2]] }

(***************************************************************************)
(* Login Response Message                                                  *)
(***************************************************************************)

LoginResponseMessage ==
    [ loginResponseStatus        : Sample(1),
      loginResponseText          : Sample(60),
      noUnspecifiedUnitReplay    : Sample(1),
      lastReceivedSequenceNumber : Sample(4),
      unitSequence               : SampleLists(OneUnitSequence2),
      paramGroup                 : SampleLists(OneParamGroup2) ]

EncodeLoginResponseMessage(message) ==
    message.loginResponseStatus
        \o message.loginResponseText
        \o message.noUnspecifiedUnitReplay
        \o message.lastReceivedSequenceNumber
        \o EncodeUIntBE(Len(message.unitSequence), 1)
        \o EncodeUnitSequence2List(message.unitSequence)
        \o EncodeUIntBE(Len(message.paramGroup), 1)
        \o EncodeParamGroup2List(message.paramGroup)

DecodeLoginResponseMessage(bytes) ==
    LET loginResponseStatus == ReadBytes(bytes, 1) IN IF ~loginResponseStatus.ok THEN Fail ELSE
    LET loginResponseText == ReadBytes(loginResponseStatus.rest, 60) IN IF ~loginResponseText.ok THEN Fail ELSE
    LET noUnspecifiedUnitReplay == ReadBytes(loginResponseText.rest, 1) IN IF ~noUnspecifiedUnitReplay.ok THEN Fail ELSE
    LET lastReceivedSequenceNumber == ReadBytes(noUnspecifiedUnitReplay.rest, 4) IN IF ~lastReceivedSequenceNumber.ok THEN Fail ELSE
    LET numberOfUnits == ReadUIntBE(lastReceivedSequenceNumber.rest, 1) IN IF ~numberOfUnits.ok THEN Fail ELSE
    LET unitSequence == ReadUnitSequence2List(numberOfUnits.rest, numberOfUnits.value) IN IF ~unitSequence.ok THEN Fail ELSE
    LET numberOfParamGroups == ReadUIntBE(unitSequence.rest, 1) IN IF ~numberOfParamGroups.ok THEN Fail ELSE
    LET paramGroup == ReadParamGroup2List(numberOfParamGroups.rest, numberOfParamGroups.value) IN IF ~paramGroup.ok THEN Fail ELSE
    Ok([ loginResponseStatus        |-> loginResponseStatus.value,
         loginResponseText          |-> loginResponseText.value,
         noUnspecifiedUnitReplay    |-> noUnspecifiedUnitReplay.value,
         lastReceivedSequenceNumber |-> lastReceivedSequenceNumber.value,
         unitSequence               |-> unitSequence.value,
         paramGroup                 |-> paramGroup.value ], paramGroup.rest)

ZeroLoginResponseMessage ==
    [ loginResponseStatus        |-> [i \in 1 .. 1 |-> 0],
      loginResponseText          |-> [i \in 1 .. 60 |-> 0],
      noUnspecifiedUnitReplay    |-> [i \in 1 .. 1 |-> 0],
      lastReceivedSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      unitSequence               |-> << >>,
      paramGroup                 |-> << >> ]

(* Login Response Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginResponseMessage ==
    { ZeroLoginResponseMessage }
        \cup { [ZeroLoginResponseMessage EXCEPT !.loginResponseStatus = one] : one \in Sample(1) }
        \cup { [ZeroLoginResponseMessage EXCEPT !.loginResponseText = one] : one \in Sample(60) }
        \cup { [ZeroLoginResponseMessage EXCEPT !.noUnspecifiedUnitReplay = one] : one \in Sample(1) }
        \cup { [ZeroLoginResponseMessage EXCEPT !.lastReceivedSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroLoginResponseMessage EXCEPT !.unitSequence = one] : one \in SampleLists(OneUnitSequence2) }
        \cup { [ZeroLoginResponseMessage EXCEPT !.paramGroup = one] : one \in SampleLists(OneParamGroup2) }

(***************************************************************************)
(* Unit Sequence: 5 bytes                                                  *)
(***************************************************************************)

UnitSequence4 ==
    [ unitNumber         : Sample(1),
      unitSequenceNumber : Sample(4) ]

EncodeUnitSequence4(message) ==
    message.unitNumber
        \o message.unitSequenceNumber

DecodeUnitSequence4(bytes) ==
    LET unitNumber == ReadBytes(bytes, 1) IN IF ~unitNumber.ok THEN Fail ELSE
    LET unitSequenceNumber == ReadBytes(unitNumber.rest, 4) IN IF ~unitSequenceNumber.ok THEN Fail ELSE
    Ok([ unitNumber         |-> unitNumber.value,
         unitSequenceNumber |-> unitSequenceNumber.value ], unitSequenceNumber.rest)

ZeroUnitSequence4 ==
    [ unitNumber         |-> [i \in 1 .. 1 |-> 0],
      unitSequenceNumber |-> [i \in 1 .. 4 |-> 0] ]

(* Unit Sequence at zero, then each field in turn at the values it is checked at *)
CheckedUnitSequence4 ==
    { ZeroUnitSequence4 }
        \cup { [ZeroUnitSequence4 EXCEPT !.unitNumber = one] : one \in Sample(1) }
        \cup { [ZeroUnitSequence4 EXCEPT !.unitSequenceNumber = one] : one \in Sample(4) }

(* A run of Unit Sequence, written one after another *)
RECURSIVE EncodeUnitSequence4List(_)
EncodeUnitSequence4List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeUnitSequence4(Head(messages)) \o EncodeUnitSequence4List(Tail(messages))

(* As many Unit Sequence as the field that counts them says *)
RECURSIVE ReadUnitSequence4List(_, _)
ReadUnitSequence4List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeUnitSequence4(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadUnitSequence4List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Unit Sequence of each kind, for the lists that carry them *)
OneUnitSequence4 == { ZeroUnitSequence4 }

(***************************************************************************)
(* Logout Message                                                          *)
(***************************************************************************)

LogoutMessage ==
    [ logoutReason               : Sample(1),
      logoutReasonText           : Sample(60),
      lastReceivedSequenceNumber : Sample(4),
      unitSequence               : SampleLists(OneUnitSequence4) ]

EncodeLogoutMessage(message) ==
    message.logoutReason
        \o message.logoutReasonText
        \o message.lastReceivedSequenceNumber
        \o EncodeUIntBE(Len(message.unitSequence), 1)
        \o EncodeUnitSequence4List(message.unitSequence)

DecodeLogoutMessage(bytes) ==
    LET logoutReason == ReadBytes(bytes, 1) IN IF ~logoutReason.ok THEN Fail ELSE
    LET logoutReasonText == ReadBytes(logoutReason.rest, 60) IN IF ~logoutReasonText.ok THEN Fail ELSE
    LET lastReceivedSequenceNumber == ReadBytes(logoutReasonText.rest, 4) IN IF ~lastReceivedSequenceNumber.ok THEN Fail ELSE
    LET numberOfUnits == ReadUIntBE(lastReceivedSequenceNumber.rest, 1) IN IF ~numberOfUnits.ok THEN Fail ELSE
    LET unitSequence == ReadUnitSequence4List(numberOfUnits.rest, numberOfUnits.value) IN IF ~unitSequence.ok THEN Fail ELSE
    Ok([ logoutReason               |-> logoutReason.value,
         logoutReasonText           |-> logoutReasonText.value,
         lastReceivedSequenceNumber |-> lastReceivedSequenceNumber.value,
         unitSequence               |-> unitSequence.value ], unitSequence.rest)

ZeroLogoutMessage ==
    [ logoutReason               |-> [i \in 1 .. 1 |-> 0],
      logoutReasonText           |-> [i \in 1 .. 60 |-> 0],
      lastReceivedSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      unitSequence               |-> << >> ]

(* Logout Message at zero, then each field in turn at the values it is checked at *)
CheckedLogoutMessage ==
    { ZeroLogoutMessage }
        \cup { [ZeroLogoutMessage EXCEPT !.logoutReason = one] : one \in Sample(1) }
        \cup { [ZeroLogoutMessage EXCEPT !.logoutReasonText = one] : one \in Sample(60) }
        \cup { [ZeroLogoutMessage EXCEPT !.lastReceivedSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroLogoutMessage EXCEPT !.unitSequence = one] : one \in SampleLists(OneUnitSequence4) }

(***************************************************************************)
(* New Order Message                                                       *)
(***************************************************************************)

NewOrderMessage ==
    [ clOrdId                   : Sample(20),
      side                      : Sample(1),
      orderQtyLong              : Sample(4),
      numberOfNewOrderBitfields : 0 .. 255,
      newOrderBitfield1         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      newOrderBitfield2         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      newOrderBitfield3         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      newOrderBitfield4         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      newOrderBitfield5         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      newOrderBitfield6         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      newOrderBitfield7         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      newOrderBitfield8         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      newOrderBitfield9         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      clearingFirm              : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingAccount           : { << >> } \cup { <<held>> : held \in Sample(4) },
      priceLong                 : { << >> } \cup { <<held>> : held \in Sample(8) },
      execInst                  : { << >> } \cup { <<held>> : held \in Sample(1) },
      ordType                   : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce               : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                    : { << >> } \cup { <<held>> : held \in Sample(4) },
      maxFloor                  : { << >> } \cup { <<held>> : held \in Sample(4) },
      symbolLong                : { << >> } \cup { <<held>> : held \in Sample(8) },
      capacity                  : { << >> } \cup { <<held>> : held \in Sample(1) },
      routingInst               : { << >> } \cup { <<held>> : held \in Sample(4) },
      account                   : { << >> } \cup { <<held>> : held \in Sample(16) },
      displayIndicator          : { << >> } \cup { <<held>> : held \in Sample(1) },
      maxRemovePct              : { << >> } \cup { <<held>> : held \in Sample(1) },
      preventMatch              : { << >> } \cup { <<held>> : held \in Sample(3) },
      expireTime                : { << >> } \cup { <<held>> : held \in Sample(8) },
      maturityDate              : { << >> } \cup { <<held>> : held \in Sample(4) },
      strikePrice               : { << >> } \cup { <<held>> : held \in Sample(8) },
      putOrCall                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      riskReset                 : { << >> } \cup { <<held>> : held \in Sample(8) },
      openClose                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      cmtaNumber                : { << >> } \cup { <<held>> : held \in Sample(4) },
      sessionEligibility        : { << >> } \cup { <<held>> : held \in Sample(1) },
      attributedQuote           : { << >> } \cup { <<held>> : held \in Sample(1) },
      extExecInst               : { << >> } \cup { <<held>> : held \in Sample(1) },
      displayRange              : { << >> } \cup { <<held>> : held \in Sample(4) },
      stopPx                    : { << >> } \cup { <<held>> : held \in Sample(8) },
      routStrategy              : { << >> } \cup { <<held>> : held \in Sample(6) },
      routeDeliveryMethod       : { << >> } \cup { <<held>> : held \in Sample(3) },
      exDestination             : { << >> } \cup { <<held>> : held \in Sample(1) },
      echoText                  : { << >> } \cup { <<held>> : held \in Sample(64) },
      customGroupId             : { << >> } \cup { <<held>> : held \in Sample(2) },
      clearingOptionalData      : { << >> } \cup { <<held>> : held \in Sample(16) },
      clientIdAttr              : { << >> } \cup { <<held>> : held \in Sample(4) },
      floorRoutingInst          : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderOrigin               : { << >> } \cup { <<held>> : held \in Sample(3) } ]

EncodeNewOrderMessage(message) ==
    message.clOrdId
        \o message.side
        \o message.orderQtyLong
        \o EncodeUIntBE(message.numberOfNewOrderBitfields, 1)
        \o (IF message.newOrderBitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.newOrderBitfield1[1], 1))
        \o (IF message.newOrderBitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.newOrderBitfield2[1], 1))
        \o (IF message.newOrderBitfield3 = << >> THEN << >> ELSE EncodeUIntLE(message.newOrderBitfield3[1], 1))
        \o (IF message.newOrderBitfield4 = << >> THEN << >> ELSE EncodeUIntLE(message.newOrderBitfield4[1], 1))
        \o (IF message.newOrderBitfield5 = << >> THEN << >> ELSE EncodeUIntLE(message.newOrderBitfield5[1], 1))
        \o (IF message.newOrderBitfield6 = << >> THEN << >> ELSE EncodeUIntLE(message.newOrderBitfield6[1], 1))
        \o (IF message.newOrderBitfield7 = << >> THEN << >> ELSE EncodeUIntLE(message.newOrderBitfield7[1], 1))
        \o (IF message.newOrderBitfield8 = << >> THEN << >> ELSE EncodeUIntLE(message.newOrderBitfield8[1], 1))
        \o (IF message.newOrderBitfield9 = << >> THEN << >> ELSE EncodeUIntLE(message.newOrderBitfield9[1], 1))
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])
        \o (IF message.clearingAccount = << >> THEN << >> ELSE message.clearingAccount[1])
        \o (IF message.priceLong = << >> THEN << >> ELSE message.priceLong[1])
        \o (IF message.execInst = << >> THEN << >> ELSE message.execInst[1])
        \o (IF message.ordType = << >> THEN << >> ELSE message.ordType[1])
        \o (IF message.timeInForce = << >> THEN << >> ELSE message.timeInForce[1])
        \o (IF message.minQty = << >> THEN << >> ELSE message.minQty[1])
        \o (IF message.maxFloor = << >> THEN << >> ELSE message.maxFloor[1])
        \o (IF message.symbolLong = << >> THEN << >> ELSE message.symbolLong[1])
        \o (IF message.capacity = << >> THEN << >> ELSE message.capacity[1])
        \o (IF message.routingInst = << >> THEN << >> ELSE message.routingInst[1])
        \o (IF message.account = << >> THEN << >> ELSE message.account[1])
        \o (IF message.displayIndicator = << >> THEN << >> ELSE message.displayIndicator[1])
        \o (IF message.maxRemovePct = << >> THEN << >> ELSE message.maxRemovePct[1])
        \o (IF message.preventMatch = << >> THEN << >> ELSE message.preventMatch[1])
        \o (IF message.expireTime = << >> THEN << >> ELSE message.expireTime[1])
        \o (IF message.maturityDate = << >> THEN << >> ELSE message.maturityDate[1])
        \o (IF message.strikePrice = << >> THEN << >> ELSE message.strikePrice[1])
        \o (IF message.putOrCall = << >> THEN << >> ELSE message.putOrCall[1])
        \o (IF message.riskReset = << >> THEN << >> ELSE message.riskReset[1])
        \o (IF message.openClose = << >> THEN << >> ELSE message.openClose[1])
        \o (IF message.cmtaNumber = << >> THEN << >> ELSE message.cmtaNumber[1])
        \o (IF message.sessionEligibility = << >> THEN << >> ELSE message.sessionEligibility[1])
        \o (IF message.attributedQuote = << >> THEN << >> ELSE message.attributedQuote[1])
        \o (IF message.extExecInst = << >> THEN << >> ELSE message.extExecInst[1])
        \o (IF message.displayRange = << >> THEN << >> ELSE message.displayRange[1])
        \o (IF message.stopPx = << >> THEN << >> ELSE message.stopPx[1])
        \o (IF message.routStrategy = << >> THEN << >> ELSE message.routStrategy[1])
        \o (IF message.routeDeliveryMethod = << >> THEN << >> ELSE message.routeDeliveryMethod[1])
        \o (IF message.exDestination = << >> THEN << >> ELSE message.exDestination[1])
        \o (IF message.echoText = << >> THEN << >> ELSE message.echoText[1])
        \o (IF message.customGroupId = << >> THEN << >> ELSE message.customGroupId[1])
        \o (IF message.clearingOptionalData = << >> THEN << >> ELSE message.clearingOptionalData[1])
        \o (IF message.clientIdAttr = << >> THEN << >> ELSE message.clientIdAttr[1])
        \o (IF message.floorRoutingInst = << >> THEN << >> ELSE message.floorRoutingInst[1])
        \o (IF message.orderOrigin = << >> THEN << >> ELSE message.orderOrigin[1])

DecodeNewOrderMessage(bytes) ==
    LET clOrdId == ReadBytes(bytes, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET side == ReadBytes(clOrdId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderQtyLong == ReadBytes(side.rest, 4) IN IF ~orderQtyLong.ok THEN Fail ELSE
    LET numberOfNewOrderBitfields == ReadUIntBE(orderQtyLong.rest, 1) IN IF ~numberOfNewOrderBitfields.ok THEN Fail ELSE
    LET newOrderBitfield1 == ReadWhen(numberOfNewOrderBitfields.value >= 1, ReadUIntLE(numberOfNewOrderBitfields.rest, 1), numberOfNewOrderBitfields.rest) IN IF ~newOrderBitfield1.ok THEN Fail ELSE
    LET newOrderBitfield2 == ReadWhen(numberOfNewOrderBitfields.value >= 2, ReadUIntLE(newOrderBitfield1.rest, 1), newOrderBitfield1.rest) IN IF ~newOrderBitfield2.ok THEN Fail ELSE
    LET newOrderBitfield3 == ReadWhen(numberOfNewOrderBitfields.value >= 3, ReadUIntLE(newOrderBitfield2.rest, 1), newOrderBitfield2.rest) IN IF ~newOrderBitfield3.ok THEN Fail ELSE
    LET newOrderBitfield4 == ReadWhen(numberOfNewOrderBitfields.value >= 4, ReadUIntLE(newOrderBitfield3.rest, 1), newOrderBitfield3.rest) IN IF ~newOrderBitfield4.ok THEN Fail ELSE
    LET newOrderBitfield5 == ReadWhen(numberOfNewOrderBitfields.value >= 5, ReadUIntLE(newOrderBitfield4.rest, 1), newOrderBitfield4.rest) IN IF ~newOrderBitfield5.ok THEN Fail ELSE
    LET newOrderBitfield6 == ReadWhen(numberOfNewOrderBitfields.value >= 6, ReadUIntLE(newOrderBitfield5.rest, 1), newOrderBitfield5.rest) IN IF ~newOrderBitfield6.ok THEN Fail ELSE
    LET newOrderBitfield7 == ReadWhen(numberOfNewOrderBitfields.value >= 7, ReadUIntLE(newOrderBitfield6.rest, 1), newOrderBitfield6.rest) IN IF ~newOrderBitfield7.ok THEN Fail ELSE
    LET newOrderBitfield8 == ReadWhen(numberOfNewOrderBitfields.value >= 8, ReadUIntLE(newOrderBitfield7.rest, 1), newOrderBitfield7.rest) IN IF ~newOrderBitfield8.ok THEN Fail ELSE
    LET newOrderBitfield9 == ReadWhen(numberOfNewOrderBitfields.value >= 9, ReadUIntLE(newOrderBitfield8.rest, 1), newOrderBitfield8.rest) IN IF ~newOrderBitfield9.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfNewOrderBitfields.value >= 1 /\ (newOrderBitfield1.value # << >> /\ newOrderBitfield1.value[1] % 2 > 0), ReadBytes(newOrderBitfield9.rest, 4), newOrderBitfield9.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadWhen(numberOfNewOrderBitfields.value >= 1 /\ (newOrderBitfield1.value # << >> /\ (newOrderBitfield1.value[1] \div 2) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET priceLong == ReadWhen(numberOfNewOrderBitfields.value >= 1 /\ (newOrderBitfield1.value # << >> /\ (newOrderBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(clearingAccount.rest, 8), clearingAccount.rest) IN IF ~priceLong.ok THEN Fail ELSE
    LET execInst == ReadWhen(numberOfNewOrderBitfields.value >= 1 /\ (newOrderBitfield1.value # << >> /\ (newOrderBitfield1.value[1] \div 8) % 2 > 0), ReadBytes(priceLong.rest, 1), priceLong.rest) IN IF ~execInst.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfNewOrderBitfields.value >= 1 /\ (newOrderBitfield1.value # << >> /\ (newOrderBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(execInst.rest, 1), execInst.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfNewOrderBitfields.value >= 1 /\ (newOrderBitfield1.value # << >> /\ (newOrderBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfNewOrderBitfields.value >= 1 /\ (newOrderBitfield1.value # << >> /\ (newOrderBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET maxFloor == ReadWhen(numberOfNewOrderBitfields.value >= 1 /\ (newOrderBitfield1.value # << >> /\ (newOrderBitfield1.value[1] \div 128) % 2 > 0), ReadBytes(minQty.rest, 4), minQty.rest) IN IF ~maxFloor.ok THEN Fail ELSE
    LET symbolLong == ReadWhen(numberOfNewOrderBitfields.value >= 2 /\ (newOrderBitfield2.value # << >> /\ newOrderBitfield2.value[1] % 2 > 0), ReadBytes(maxFloor.rest, 8), maxFloor.rest) IN IF ~symbolLong.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfNewOrderBitfields.value >= 2 /\ (newOrderBitfield2.value # << >> /\ (newOrderBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(symbolLong.rest, 1), symbolLong.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET routingInst == ReadWhen(numberOfNewOrderBitfields.value >= 2 /\ (newOrderBitfield2.value # << >> /\ (newOrderBitfield2.value[1] \div 128) % 2 > 0), ReadBytes(capacity.rest, 4), capacity.rest) IN IF ~routingInst.ok THEN Fail ELSE
    LET account == ReadWhen(numberOfNewOrderBitfields.value >= 3 /\ (newOrderBitfield3.value # << >> /\ newOrderBitfield3.value[1] % 2 > 0), ReadBytes(routingInst.rest, 16), routingInst.rest) IN IF ~account.ok THEN Fail ELSE
    LET displayIndicator == ReadWhen(numberOfNewOrderBitfields.value >= 3 /\ (newOrderBitfield3.value # << >> /\ (newOrderBitfield3.value[1] \div 2) % 2 > 0), ReadBytes(account.rest, 1), account.rest) IN IF ~displayIndicator.ok THEN Fail ELSE
    LET maxRemovePct == ReadWhen(numberOfNewOrderBitfields.value >= 3 /\ (newOrderBitfield3.value # << >> /\ (newOrderBitfield3.value[1] \div 4) % 2 > 0), ReadBytes(displayIndicator.rest, 1), displayIndicator.rest) IN IF ~maxRemovePct.ok THEN Fail ELSE
    LET preventMatch == ReadWhen(numberOfNewOrderBitfields.value >= 3 /\ (newOrderBitfield3.value # << >> /\ (newOrderBitfield3.value[1] \div 32) % 2 > 0), ReadBytes(maxRemovePct.rest, 3), maxRemovePct.rest) IN IF ~preventMatch.ok THEN Fail ELSE
    LET expireTime == ReadWhen(numberOfNewOrderBitfields.value >= 3 /\ (newOrderBitfield3.value # << >> /\ (newOrderBitfield3.value[1] \div 128) % 2 > 0), ReadBytes(preventMatch.rest, 8), preventMatch.rest) IN IF ~expireTime.ok THEN Fail ELSE
    LET maturityDate == ReadWhen(numberOfNewOrderBitfields.value >= 4 /\ (newOrderBitfield4.value # << >> /\ newOrderBitfield4.value[1] % 2 > 0), ReadBytes(expireTime.rest, 4), expireTime.rest) IN IF ~maturityDate.ok THEN Fail ELSE
    LET strikePrice == ReadWhen(numberOfNewOrderBitfields.value >= 4 /\ (newOrderBitfield4.value # << >> /\ (newOrderBitfield4.value[1] \div 2) % 2 > 0), ReadBytes(maturityDate.rest, 8), maturityDate.rest) IN IF ~strikePrice.ok THEN Fail ELSE
    LET putOrCall == ReadWhen(numberOfNewOrderBitfields.value >= 4 /\ (newOrderBitfield4.value # << >> /\ (newOrderBitfield4.value[1] \div 4) % 2 > 0), ReadBytes(strikePrice.rest, 1), strikePrice.rest) IN IF ~putOrCall.ok THEN Fail ELSE
    LET riskReset == ReadWhen(numberOfNewOrderBitfields.value >= 4 /\ (newOrderBitfield4.value # << >> /\ (newOrderBitfield4.value[1] \div 8) % 2 > 0), ReadBytes(putOrCall.rest, 8), putOrCall.rest) IN IF ~riskReset.ok THEN Fail ELSE
    LET openClose == ReadWhen(numberOfNewOrderBitfields.value >= 4 /\ (newOrderBitfield4.value # << >> /\ (newOrderBitfield4.value[1] \div 16) % 2 > 0), ReadBytes(riskReset.rest, 1), riskReset.rest) IN IF ~openClose.ok THEN Fail ELSE
    LET cmtaNumber == ReadWhen(numberOfNewOrderBitfields.value >= 4 /\ (newOrderBitfield4.value # << >> /\ (newOrderBitfield4.value[1] \div 32) % 2 > 0), ReadBytes(openClose.rest, 4), openClose.rest) IN IF ~cmtaNumber.ok THEN Fail ELSE
    LET sessionEligibility == ReadWhen(numberOfNewOrderBitfields.value >= 5 /\ (newOrderBitfield5.value # << >> /\ newOrderBitfield5.value[1] % 2 > 0), ReadBytes(cmtaNumber.rest, 1), cmtaNumber.rest) IN IF ~sessionEligibility.ok THEN Fail ELSE
    LET attributedQuote == ReadWhen(numberOfNewOrderBitfields.value >= 5 /\ (newOrderBitfield5.value # << >> /\ (newOrderBitfield5.value[1] \div 2) % 2 > 0), ReadBytes(sessionEligibility.rest, 1), sessionEligibility.rest) IN IF ~attributedQuote.ok THEN Fail ELSE
    LET extExecInst == ReadWhen(numberOfNewOrderBitfields.value >= 5 /\ (newOrderBitfield5.value # << >> /\ (newOrderBitfield5.value[1] \div 8) % 2 > 0), ReadBytes(attributedQuote.rest, 1), attributedQuote.rest) IN IF ~extExecInst.ok THEN Fail ELSE
    LET displayRange == ReadWhen(numberOfNewOrderBitfields.value >= 6 /\ (newOrderBitfield6.value # << >> /\ newOrderBitfield6.value[1] % 2 > 0), ReadBytes(extExecInst.rest, 4), extExecInst.rest) IN IF ~displayRange.ok THEN Fail ELSE
    LET stopPx == ReadWhen(numberOfNewOrderBitfields.value >= 6 /\ (newOrderBitfield6.value # << >> /\ (newOrderBitfield6.value[1] \div 2) % 2 > 0), ReadBytes(displayRange.rest, 8), displayRange.rest) IN IF ~stopPx.ok THEN Fail ELSE
    LET routStrategy == ReadWhen(numberOfNewOrderBitfields.value >= 6 /\ (newOrderBitfield6.value # << >> /\ (newOrderBitfield6.value[1] \div 4) % 2 > 0), ReadBytes(stopPx.rest, 6), stopPx.rest) IN IF ~routStrategy.ok THEN Fail ELSE
    LET routeDeliveryMethod == ReadWhen(numberOfNewOrderBitfields.value >= 6 /\ (newOrderBitfield6.value # << >> /\ (newOrderBitfield6.value[1] \div 8) % 2 > 0), ReadBytes(routStrategy.rest, 3), routStrategy.rest) IN IF ~routeDeliveryMethod.ok THEN Fail ELSE
    LET exDestination == ReadWhen(numberOfNewOrderBitfields.value >= 6 /\ (newOrderBitfield6.value # << >> /\ (newOrderBitfield6.value[1] \div 16) % 2 > 0), ReadBytes(routeDeliveryMethod.rest, 1), routeDeliveryMethod.rest) IN IF ~exDestination.ok THEN Fail ELSE
    LET echoText == ReadWhen(numberOfNewOrderBitfields.value >= 6 /\ (newOrderBitfield6.value # << >> /\ (newOrderBitfield6.value[1] \div 32) % 2 > 0), ReadBytes(exDestination.rest, 64), exDestination.rest) IN IF ~echoText.ok THEN Fail ELSE
    LET customGroupId == ReadWhen(numberOfNewOrderBitfields.value >= 7 /\ (newOrderBitfield7.value # << >> /\ (newOrderBitfield7.value[1] \div 2) % 2 > 0), ReadBytes(echoText.rest, 2), echoText.rest) IN IF ~customGroupId.ok THEN Fail ELSE
    LET clearingOptionalData == ReadWhen(numberOfNewOrderBitfields.value >= 8 /\ (newOrderBitfield8.value # << >> /\ (newOrderBitfield8.value[1] \div 4) % 2 > 0), ReadBytes(customGroupId.rest, 16), customGroupId.rest) IN IF ~clearingOptionalData.ok THEN Fail ELSE
    LET clientIdAttr == ReadWhen(numberOfNewOrderBitfields.value >= 8 /\ (newOrderBitfield8.value # << >> /\ (newOrderBitfield8.value[1] \div 8) % 2 > 0), ReadBytes(clearingOptionalData.rest, 4), clearingOptionalData.rest) IN IF ~clientIdAttr.ok THEN Fail ELSE
    LET floorRoutingInst == ReadWhen(numberOfNewOrderBitfields.value >= 8 /\ (newOrderBitfield8.value # << >> /\ (newOrderBitfield8.value[1] \div 128) % 2 > 0), ReadBytes(clientIdAttr.rest, 1), clientIdAttr.rest) IN IF ~floorRoutingInst.ok THEN Fail ELSE
    LET orderOrigin == ReadWhen(numberOfNewOrderBitfields.value >= 9 /\ (newOrderBitfield9.value # << >> /\ newOrderBitfield9.value[1] % 2 > 0), ReadBytes(floorRoutingInst.rest, 3), floorRoutingInst.rest) IN IF ~orderOrigin.ok THEN Fail ELSE
    Ok([ clOrdId                   |-> clOrdId.value,
         side                      |-> side.value,
         orderQtyLong              |-> orderQtyLong.value,
         numberOfNewOrderBitfields |-> numberOfNewOrderBitfields.value,
         newOrderBitfield1         |-> newOrderBitfield1.value,
         newOrderBitfield2         |-> newOrderBitfield2.value,
         newOrderBitfield3         |-> newOrderBitfield3.value,
         newOrderBitfield4         |-> newOrderBitfield4.value,
         newOrderBitfield5         |-> newOrderBitfield5.value,
         newOrderBitfield6         |-> newOrderBitfield6.value,
         newOrderBitfield7         |-> newOrderBitfield7.value,
         newOrderBitfield8         |-> newOrderBitfield8.value,
         newOrderBitfield9         |-> newOrderBitfield9.value,
         clearingFirm              |-> clearingFirm.value,
         clearingAccount           |-> clearingAccount.value,
         priceLong                 |-> priceLong.value,
         execInst                  |-> execInst.value,
         ordType                   |-> ordType.value,
         timeInForce               |-> timeInForce.value,
         minQty                    |-> minQty.value,
         maxFloor                  |-> maxFloor.value,
         symbolLong                |-> symbolLong.value,
         capacity                  |-> capacity.value,
         routingInst               |-> routingInst.value,
         account                   |-> account.value,
         displayIndicator          |-> displayIndicator.value,
         maxRemovePct              |-> maxRemovePct.value,
         preventMatch              |-> preventMatch.value,
         expireTime                |-> expireTime.value,
         maturityDate              |-> maturityDate.value,
         strikePrice               |-> strikePrice.value,
         putOrCall                 |-> putOrCall.value,
         riskReset                 |-> riskReset.value,
         openClose                 |-> openClose.value,
         cmtaNumber                |-> cmtaNumber.value,
         sessionEligibility        |-> sessionEligibility.value,
         attributedQuote           |-> attributedQuote.value,
         extExecInst               |-> extExecInst.value,
         displayRange              |-> displayRange.value,
         stopPx                    |-> stopPx.value,
         routStrategy              |-> routStrategy.value,
         routeDeliveryMethod       |-> routeDeliveryMethod.value,
         exDestination             |-> exDestination.value,
         echoText                  |-> echoText.value,
         customGroupId             |-> customGroupId.value,
         clearingOptionalData      |-> clearingOptionalData.value,
         clientIdAttr              |-> clientIdAttr.value,
         floorRoutingInst          |-> floorRoutingInst.value,
         orderOrigin               |-> orderOrigin.value ], orderOrigin.rest)

(* New Order Message with each field marked present by fields before it there exactly where they say *)
SettleNewOrderMessage(message) ==
    LET settled1 == [message EXCEPT !.newOrderBitfield1 = IF message.numberOfNewOrderBitfields >= 1 THEN (IF message.newOrderBitfield1 = << >> THEN <<0>> ELSE message.newOrderBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.newOrderBitfield2 = IF settled1.numberOfNewOrderBitfields >= 2 THEN (IF settled1.newOrderBitfield2 = << >> THEN <<0>> ELSE settled1.newOrderBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.newOrderBitfield3 = IF settled2.numberOfNewOrderBitfields >= 3 THEN (IF settled2.newOrderBitfield3 = << >> THEN <<0>> ELSE settled2.newOrderBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.newOrderBitfield4 = IF settled3.numberOfNewOrderBitfields >= 4 THEN (IF settled3.newOrderBitfield4 = << >> THEN <<0>> ELSE settled3.newOrderBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.newOrderBitfield5 = IF settled4.numberOfNewOrderBitfields >= 5 THEN (IF settled4.newOrderBitfield5 = << >> THEN <<0>> ELSE settled4.newOrderBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.newOrderBitfield6 = IF settled5.numberOfNewOrderBitfields >= 6 THEN (IF settled5.newOrderBitfield6 = << >> THEN <<0>> ELSE settled5.newOrderBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.newOrderBitfield7 = IF settled6.numberOfNewOrderBitfields >= 7 THEN (IF settled6.newOrderBitfield7 = << >> THEN <<0>> ELSE settled6.newOrderBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.newOrderBitfield8 = IF settled7.numberOfNewOrderBitfields >= 8 THEN (IF settled7.newOrderBitfield8 = << >> THEN <<0>> ELSE settled7.newOrderBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.newOrderBitfield9 = IF settled8.numberOfNewOrderBitfields >= 9 THEN (IF settled8.newOrderBitfield9 = << >> THEN <<0>> ELSE settled8.newOrderBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.clearingFirm = IF settled9.numberOfNewOrderBitfields >= 1 /\ (settled9.newOrderBitfield1 # << >> /\ settled9.newOrderBitfield1[1] % 2 > 0) THEN (IF settled9.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled9.clearingFirm) ELSE << >>]
        settled11 == [settled10 EXCEPT !.clearingAccount = IF settled10.numberOfNewOrderBitfields >= 1 /\ (settled10.newOrderBitfield1 # << >> /\ (settled10.newOrderBitfield1[1] \div 2) % 2 > 0) THEN (IF settled10.clearingAccount = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled10.clearingAccount) ELSE << >>]
        settled12 == [settled11 EXCEPT !.priceLong = IF settled11.numberOfNewOrderBitfields >= 1 /\ (settled11.newOrderBitfield1 # << >> /\ (settled11.newOrderBitfield1[1] \div 4) % 2 > 0) THEN (IF settled11.priceLong = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled11.priceLong) ELSE << >>]
        settled13 == [settled12 EXCEPT !.execInst = IF settled12.numberOfNewOrderBitfields >= 1 /\ (settled12.newOrderBitfield1 # << >> /\ (settled12.newOrderBitfield1[1] \div 8) % 2 > 0) THEN (IF settled12.execInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.execInst) ELSE << >>]
        settled14 == [settled13 EXCEPT !.ordType = IF settled13.numberOfNewOrderBitfields >= 1 /\ (settled13.newOrderBitfield1 # << >> /\ (settled13.newOrderBitfield1[1] \div 16) % 2 > 0) THEN (IF settled13.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.ordType) ELSE << >>]
        settled15 == [settled14 EXCEPT !.timeInForce = IF settled14.numberOfNewOrderBitfields >= 1 /\ (settled14.newOrderBitfield1 # << >> /\ (settled14.newOrderBitfield1[1] \div 32) % 2 > 0) THEN (IF settled14.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.timeInForce) ELSE << >>]
        settled16 == [settled15 EXCEPT !.minQty = IF settled15.numberOfNewOrderBitfields >= 1 /\ (settled15.newOrderBitfield1 # << >> /\ (settled15.newOrderBitfield1[1] \div 64) % 2 > 0) THEN (IF settled15.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled15.minQty) ELSE << >>]
        settled17 == [settled16 EXCEPT !.maxFloor = IF settled16.numberOfNewOrderBitfields >= 1 /\ (settled16.newOrderBitfield1 # << >> /\ (settled16.newOrderBitfield1[1] \div 128) % 2 > 0) THEN (IF settled16.maxFloor = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled16.maxFloor) ELSE << >>]
        settled18 == [settled17 EXCEPT !.symbolLong = IF settled17.numberOfNewOrderBitfields >= 2 /\ (settled17.newOrderBitfield2 # << >> /\ settled17.newOrderBitfield2[1] % 2 > 0) THEN (IF settled17.symbolLong = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled17.symbolLong) ELSE << >>]
        settled19 == [settled18 EXCEPT !.capacity = IF settled18.numberOfNewOrderBitfields >= 2 /\ (settled18.newOrderBitfield2 # << >> /\ (settled18.newOrderBitfield2[1] \div 64) % 2 > 0) THEN (IF settled18.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled18.capacity) ELSE << >>]
        settled20 == [settled19 EXCEPT !.routingInst = IF settled19.numberOfNewOrderBitfields >= 2 /\ (settled19.newOrderBitfield2 # << >> /\ (settled19.newOrderBitfield2[1] \div 128) % 2 > 0) THEN (IF settled19.routingInst = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled19.routingInst) ELSE << >>]
        settled21 == [settled20 EXCEPT !.account = IF settled20.numberOfNewOrderBitfields >= 3 /\ (settled20.newOrderBitfield3 # << >> /\ settled20.newOrderBitfield3[1] % 2 > 0) THEN (IF settled20.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled20.account) ELSE << >>]
        settled22 == [settled21 EXCEPT !.displayIndicator = IF settled21.numberOfNewOrderBitfields >= 3 /\ (settled21.newOrderBitfield3 # << >> /\ (settled21.newOrderBitfield3[1] \div 2) % 2 > 0) THEN (IF settled21.displayIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled21.displayIndicator) ELSE << >>]
        settled23 == [settled22 EXCEPT !.maxRemovePct = IF settled22.numberOfNewOrderBitfields >= 3 /\ (settled22.newOrderBitfield3 # << >> /\ (settled22.newOrderBitfield3[1] \div 4) % 2 > 0) THEN (IF settled22.maxRemovePct = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled22.maxRemovePct) ELSE << >>]
        settled24 == [settled23 EXCEPT !.preventMatch = IF settled23.numberOfNewOrderBitfields >= 3 /\ (settled23.newOrderBitfield3 # << >> /\ (settled23.newOrderBitfield3[1] \div 32) % 2 > 0) THEN (IF settled23.preventMatch = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled23.preventMatch) ELSE << >>]
        settled25 == [settled24 EXCEPT !.expireTime = IF settled24.numberOfNewOrderBitfields >= 3 /\ (settled24.newOrderBitfield3 # << >> /\ (settled24.newOrderBitfield3[1] \div 128) % 2 > 0) THEN (IF settled24.expireTime = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled24.expireTime) ELSE << >>]
        settled26 == [settled25 EXCEPT !.maturityDate = IF settled25.numberOfNewOrderBitfields >= 4 /\ (settled25.newOrderBitfield4 # << >> /\ settled25.newOrderBitfield4[1] % 2 > 0) THEN (IF settled25.maturityDate = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled25.maturityDate) ELSE << >>]
        settled27 == [settled26 EXCEPT !.strikePrice = IF settled26.numberOfNewOrderBitfields >= 4 /\ (settled26.newOrderBitfield4 # << >> /\ (settled26.newOrderBitfield4[1] \div 2) % 2 > 0) THEN (IF settled26.strikePrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled26.strikePrice) ELSE << >>]
        settled28 == [settled27 EXCEPT !.putOrCall = IF settled27.numberOfNewOrderBitfields >= 4 /\ (settled27.newOrderBitfield4 # << >> /\ (settled27.newOrderBitfield4[1] \div 4) % 2 > 0) THEN (IF settled27.putOrCall = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled27.putOrCall) ELSE << >>]
        settled29 == [settled28 EXCEPT !.riskReset = IF settled28.numberOfNewOrderBitfields >= 4 /\ (settled28.newOrderBitfield4 # << >> /\ (settled28.newOrderBitfield4[1] \div 8) % 2 > 0) THEN (IF settled28.riskReset = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled28.riskReset) ELSE << >>]
        settled30 == [settled29 EXCEPT !.openClose = IF settled29.numberOfNewOrderBitfields >= 4 /\ (settled29.newOrderBitfield4 # << >> /\ (settled29.newOrderBitfield4[1] \div 16) % 2 > 0) THEN (IF settled29.openClose = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled29.openClose) ELSE << >>]
        settled31 == [settled30 EXCEPT !.cmtaNumber = IF settled30.numberOfNewOrderBitfields >= 4 /\ (settled30.newOrderBitfield4 # << >> /\ (settled30.newOrderBitfield4[1] \div 32) % 2 > 0) THEN (IF settled30.cmtaNumber = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled30.cmtaNumber) ELSE << >>]
        settled32 == [settled31 EXCEPT !.sessionEligibility = IF settled31.numberOfNewOrderBitfields >= 5 /\ (settled31.newOrderBitfield5 # << >> /\ settled31.newOrderBitfield5[1] % 2 > 0) THEN (IF settled31.sessionEligibility = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled31.sessionEligibility) ELSE << >>]
        settled33 == [settled32 EXCEPT !.attributedQuote = IF settled32.numberOfNewOrderBitfields >= 5 /\ (settled32.newOrderBitfield5 # << >> /\ (settled32.newOrderBitfield5[1] \div 2) % 2 > 0) THEN (IF settled32.attributedQuote = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled32.attributedQuote) ELSE << >>]
        settled34 == [settled33 EXCEPT !.extExecInst = IF settled33.numberOfNewOrderBitfields >= 5 /\ (settled33.newOrderBitfield5 # << >> /\ (settled33.newOrderBitfield5[1] \div 8) % 2 > 0) THEN (IF settled33.extExecInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled33.extExecInst) ELSE << >>]
        settled35 == [settled34 EXCEPT !.displayRange = IF settled34.numberOfNewOrderBitfields >= 6 /\ (settled34.newOrderBitfield6 # << >> /\ settled34.newOrderBitfield6[1] % 2 > 0) THEN (IF settled34.displayRange = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled34.displayRange) ELSE << >>]
        settled36 == [settled35 EXCEPT !.stopPx = IF settled35.numberOfNewOrderBitfields >= 6 /\ (settled35.newOrderBitfield6 # << >> /\ (settled35.newOrderBitfield6[1] \div 2) % 2 > 0) THEN (IF settled35.stopPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled35.stopPx) ELSE << >>]
        settled37 == [settled36 EXCEPT !.routStrategy = IF settled36.numberOfNewOrderBitfields >= 6 /\ (settled36.newOrderBitfield6 # << >> /\ (settled36.newOrderBitfield6[1] \div 4) % 2 > 0) THEN (IF settled36.routStrategy = << >> THEN <<[i \in 1 .. 6 |-> 0]>> ELSE settled36.routStrategy) ELSE << >>]
        settled38 == [settled37 EXCEPT !.routeDeliveryMethod = IF settled37.numberOfNewOrderBitfields >= 6 /\ (settled37.newOrderBitfield6 # << >> /\ (settled37.newOrderBitfield6[1] \div 8) % 2 > 0) THEN (IF settled37.routeDeliveryMethod = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled37.routeDeliveryMethod) ELSE << >>]
        settled39 == [settled38 EXCEPT !.exDestination = IF settled38.numberOfNewOrderBitfields >= 6 /\ (settled38.newOrderBitfield6 # << >> /\ (settled38.newOrderBitfield6[1] \div 16) % 2 > 0) THEN (IF settled38.exDestination = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled38.exDestination) ELSE << >>]
        settled40 == [settled39 EXCEPT !.echoText = IF settled39.numberOfNewOrderBitfields >= 6 /\ (settled39.newOrderBitfield6 # << >> /\ (settled39.newOrderBitfield6[1] \div 32) % 2 > 0) THEN (IF settled39.echoText = << >> THEN <<[i \in 1 .. 64 |-> 0]>> ELSE settled39.echoText) ELSE << >>]
        settled41 == [settled40 EXCEPT !.customGroupId = IF settled40.numberOfNewOrderBitfields >= 7 /\ (settled40.newOrderBitfield7 # << >> /\ (settled40.newOrderBitfield7[1] \div 2) % 2 > 0) THEN (IF settled40.customGroupId = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled40.customGroupId) ELSE << >>]
        settled42 == [settled41 EXCEPT !.clearingOptionalData = IF settled41.numberOfNewOrderBitfields >= 8 /\ (settled41.newOrderBitfield8 # << >> /\ (settled41.newOrderBitfield8[1] \div 4) % 2 > 0) THEN (IF settled41.clearingOptionalData = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled41.clearingOptionalData) ELSE << >>]
        settled43 == [settled42 EXCEPT !.clientIdAttr = IF settled42.numberOfNewOrderBitfields >= 8 /\ (settled42.newOrderBitfield8 # << >> /\ (settled42.newOrderBitfield8[1] \div 8) % 2 > 0) THEN (IF settled42.clientIdAttr = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled42.clientIdAttr) ELSE << >>]
        settled44 == [settled43 EXCEPT !.floorRoutingInst = IF settled43.numberOfNewOrderBitfields >= 8 /\ (settled43.newOrderBitfield8 # << >> /\ (settled43.newOrderBitfield8[1] \div 128) % 2 > 0) THEN (IF settled43.floorRoutingInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled43.floorRoutingInst) ELSE << >>]
        settled45 == [settled44 EXCEPT !.orderOrigin = IF settled44.numberOfNewOrderBitfields >= 9 /\ (settled44.newOrderBitfield9 # << >> /\ settled44.newOrderBitfield9[1] % 2 > 0) THEN (IF settled44.orderOrigin = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled44.orderOrigin) ELSE << >>]
    IN  settled45

ZeroNewOrderMessage ==
    SettleNewOrderMessage([ clOrdId                   |-> [i \in 1 .. 20 |-> 0],
                            side                      |-> [i \in 1 .. 1 |-> 0],
                            orderQtyLong              |-> [i \in 1 .. 4 |-> 0],
                            numberOfNewOrderBitfields |-> 0,
                            newOrderBitfield1         |-> << >>,
                            newOrderBitfield2         |-> << >>,
                            newOrderBitfield3         |-> << >>,
                            newOrderBitfield4         |-> << >>,
                            newOrderBitfield5         |-> << >>,
                            newOrderBitfield6         |-> << >>,
                            newOrderBitfield7         |-> << >>,
                            newOrderBitfield8         |-> << >>,
                            newOrderBitfield9         |-> << >>,
                            clearingFirm              |-> << >>,
                            clearingAccount           |-> << >>,
                            priceLong                 |-> << >>,
                            execInst                  |-> << >>,
                            ordType                   |-> << >>,
                            timeInForce               |-> << >>,
                            minQty                    |-> << >>,
                            maxFloor                  |-> << >>,
                            symbolLong                |-> << >>,
                            capacity                  |-> << >>,
                            routingInst               |-> << >>,
                            account                   |-> << >>,
                            displayIndicator          |-> << >>,
                            maxRemovePct              |-> << >>,
                            preventMatch              |-> << >>,
                            expireTime                |-> << >>,
                            maturityDate              |-> << >>,
                            strikePrice               |-> << >>,
                            putOrCall                 |-> << >>,
                            riskReset                 |-> << >>,
                            openClose                 |-> << >>,
                            cmtaNumber                |-> << >>,
                            sessionEligibility        |-> << >>,
                            attributedQuote           |-> << >>,
                            extExecInst               |-> << >>,
                            displayRange              |-> << >>,
                            stopPx                    |-> << >>,
                            routStrategy              |-> << >>,
                            routeDeliveryMethod       |-> << >>,
                            exDestination             |-> << >>,
                            echoText                  |-> << >>,
                            customGroupId             |-> << >>,
                            clearingOptionalData      |-> << >>,
                            clientIdAttr              |-> << >>,
                            floorRoutingInst          |-> << >>,
                            orderOrigin               |-> << >> ])

(* New Order Message at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderMessage ==
    { ZeroNewOrderMessage }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.clOrdId = one]) : one \in Sample(20) }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.side = one]) : one \in Sample(1) }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.orderQtyLong = one]) : one \in Sample(4) }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 1, !.newOrderBitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 2, !.newOrderBitfield2 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 3, !.newOrderBitfield3 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 4, !.newOrderBitfield4 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 5, !.newOrderBitfield5 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 6, !.newOrderBitfield6 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 7, !.newOrderBitfield7 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 8, !.newOrderBitfield8 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 9, !.newOrderBitfield9 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 1, !.newOrderBitfield1 = <<1>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 1, !.newOrderBitfield1 = <<2>>, !.clearingAccount = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 1, !.newOrderBitfield1 = <<4>>, !.priceLong = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 1, !.newOrderBitfield1 = <<8>>, !.execInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 1, !.newOrderBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 1, !.newOrderBitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 1, !.newOrderBitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 1, !.newOrderBitfield1 = <<128>>, !.maxFloor = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 2, !.newOrderBitfield2 = <<1>>, !.symbolLong = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 2, !.newOrderBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 2, !.newOrderBitfield2 = <<128>>, !.routingInst = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 3, !.newOrderBitfield3 = <<1>>, !.account = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 3, !.newOrderBitfield3 = <<2>>, !.displayIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 3, !.newOrderBitfield3 = <<4>>, !.maxRemovePct = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 3, !.newOrderBitfield3 = <<32>>, !.preventMatch = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 3, !.newOrderBitfield3 = <<128>>, !.expireTime = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 4, !.newOrderBitfield4 = <<1>>, !.maturityDate = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 4, !.newOrderBitfield4 = <<2>>, !.strikePrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 4, !.newOrderBitfield4 = <<4>>, !.putOrCall = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 4, !.newOrderBitfield4 = <<8>>, !.riskReset = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 4, !.newOrderBitfield4 = <<16>>, !.openClose = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 4, !.newOrderBitfield4 = <<32>>, !.cmtaNumber = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 5, !.newOrderBitfield5 = <<1>>, !.sessionEligibility = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 5, !.newOrderBitfield5 = <<2>>, !.attributedQuote = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 5, !.newOrderBitfield5 = <<8>>, !.extExecInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 6, !.newOrderBitfield6 = <<1>>, !.displayRange = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 6, !.newOrderBitfield6 = <<2>>, !.stopPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 6, !.newOrderBitfield6 = <<4>>, !.routStrategy = one]) : one \in { <<held>> : held \in Sample(6) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 6, !.newOrderBitfield6 = <<8>>, !.routeDeliveryMethod = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 6, !.newOrderBitfield6 = <<16>>, !.exDestination = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 6, !.newOrderBitfield6 = <<32>>, !.echoText = one]) : one \in { <<held>> : held \in Sample(64) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 7, !.newOrderBitfield7 = <<2>>, !.customGroupId = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 8, !.newOrderBitfield8 = <<4>>, !.clearingOptionalData = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 8, !.newOrderBitfield8 = <<8>>, !.clientIdAttr = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 8, !.newOrderBitfield8 = <<128>>, !.floorRoutingInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 9, !.newOrderBitfield9 = <<1>>, !.orderOrigin = one]) : one \in { <<held>> : held \in Sample(3) } }

(***************************************************************************)
(* Cancel Order Message                                                    *)
(***************************************************************************)

CancelOrderMessage ==
    [ origClOrdId                  : Sample(20),
      numberOfCancelOrderBitfields : 0 .. 255,
      cancelOrderBitfield1         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      cancelOrderBitfield2         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      clearingFirm                 : { << >> } \cup { <<held>> : held \in Sample(4) },
      massCancelLockout            : { << >> } \cup { <<held>> : held \in Sample(1) },
      massCancel                   : { << >> } \cup { <<held>> : held \in Sample(1) },
      riskRoot                     : { << >> } \cup { <<held>> : held \in Sample(6) },
      massCancelId                 : { << >> } \cup { <<held>> : held \in Sample(20) },
      massCancelInst               : { << >> } \cup { <<held>> : held \in Sample(16) } ]

EncodeCancelOrderMessage(message) ==
    message.origClOrdId
        \o EncodeUIntBE(message.numberOfCancelOrderBitfields, 1)
        \o (IF message.cancelOrderBitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.cancelOrderBitfield1[1], 1))
        \o (IF message.cancelOrderBitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.cancelOrderBitfield2[1], 1))
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])
        \o (IF message.massCancelLockout = << >> THEN << >> ELSE message.massCancelLockout[1])
        \o (IF message.massCancel = << >> THEN << >> ELSE message.massCancel[1])
        \o (IF message.riskRoot = << >> THEN << >> ELSE message.riskRoot[1])
        \o (IF message.massCancelId = << >> THEN << >> ELSE message.massCancelId[1])
        \o (IF message.massCancelInst = << >> THEN << >> ELSE message.massCancelInst[1])

DecodeCancelOrderMessage(bytes) ==
    LET origClOrdId == ReadBytes(bytes, 20) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET numberOfCancelOrderBitfields == ReadUIntBE(origClOrdId.rest, 1) IN IF ~numberOfCancelOrderBitfields.ok THEN Fail ELSE
    LET cancelOrderBitfield1 == ReadWhen(numberOfCancelOrderBitfields.value >= 1, ReadUIntLE(numberOfCancelOrderBitfields.rest, 1), numberOfCancelOrderBitfields.rest) IN IF ~cancelOrderBitfield1.ok THEN Fail ELSE
    LET cancelOrderBitfield2 == ReadWhen(numberOfCancelOrderBitfields.value >= 2, ReadUIntLE(cancelOrderBitfield1.rest, 1), cancelOrderBitfield1.rest) IN IF ~cancelOrderBitfield2.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfCancelOrderBitfields.value >= 1 /\ (cancelOrderBitfield1.value # << >> /\ cancelOrderBitfield1.value[1] % 2 > 0), ReadBytes(cancelOrderBitfield2.rest, 4), cancelOrderBitfield2.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET massCancelLockout == ReadWhen(numberOfCancelOrderBitfields.value >= 1 /\ (cancelOrderBitfield1.value # << >> /\ (cancelOrderBitfield1.value[1] \div 2) % 2 > 0), ReadBytes(clearingFirm.rest, 1), clearingFirm.rest) IN IF ~massCancelLockout.ok THEN Fail ELSE
    LET massCancel == ReadWhen(numberOfCancelOrderBitfields.value >= 1 /\ (cancelOrderBitfield1.value # << >> /\ (cancelOrderBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(massCancelLockout.rest, 1), massCancelLockout.rest) IN IF ~massCancel.ok THEN Fail ELSE
    LET riskRoot == ReadWhen(numberOfCancelOrderBitfields.value >= 1 /\ (cancelOrderBitfield1.value # << >> /\ (cancelOrderBitfield1.value[1] \div 8) % 2 > 0), ReadBytes(massCancel.rest, 6), massCancel.rest) IN IF ~riskRoot.ok THEN Fail ELSE
    LET massCancelId == ReadWhen(numberOfCancelOrderBitfields.value >= 1 /\ (cancelOrderBitfield1.value # << >> /\ (cancelOrderBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(riskRoot.rest, 20), riskRoot.rest) IN IF ~massCancelId.ok THEN Fail ELSE
    LET massCancelInst == ReadWhen(numberOfCancelOrderBitfields.value >= 2 /\ (cancelOrderBitfield2.value # << >> /\ cancelOrderBitfield2.value[1] % 2 > 0), ReadBytes(massCancelId.rest, 16), massCancelId.rest) IN IF ~massCancelInst.ok THEN Fail ELSE
    Ok([ origClOrdId                  |-> origClOrdId.value,
         numberOfCancelOrderBitfields |-> numberOfCancelOrderBitfields.value,
         cancelOrderBitfield1         |-> cancelOrderBitfield1.value,
         cancelOrderBitfield2         |-> cancelOrderBitfield2.value,
         clearingFirm                 |-> clearingFirm.value,
         massCancelLockout            |-> massCancelLockout.value,
         massCancel                   |-> massCancel.value,
         riskRoot                     |-> riskRoot.value,
         massCancelId                 |-> massCancelId.value,
         massCancelInst               |-> massCancelInst.value ], massCancelInst.rest)

(* Cancel Order Message with each field marked present by fields before it there exactly where they say *)
SettleCancelOrderMessage(message) ==
    LET settled1 == [message EXCEPT !.cancelOrderBitfield1 = IF message.numberOfCancelOrderBitfields >= 1 THEN (IF message.cancelOrderBitfield1 = << >> THEN <<0>> ELSE message.cancelOrderBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.cancelOrderBitfield2 = IF settled1.numberOfCancelOrderBitfields >= 2 THEN (IF settled1.cancelOrderBitfield2 = << >> THEN <<0>> ELSE settled1.cancelOrderBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.clearingFirm = IF settled2.numberOfCancelOrderBitfields >= 1 /\ (settled2.cancelOrderBitfield1 # << >> /\ settled2.cancelOrderBitfield1[1] % 2 > 0) THEN (IF settled2.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled2.clearingFirm) ELSE << >>]
        settled4 == [settled3 EXCEPT !.massCancelLockout = IF settled3.numberOfCancelOrderBitfields >= 1 /\ (settled3.cancelOrderBitfield1 # << >> /\ (settled3.cancelOrderBitfield1[1] \div 2) % 2 > 0) THEN (IF settled3.massCancelLockout = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled3.massCancelLockout) ELSE << >>]
        settled5 == [settled4 EXCEPT !.massCancel = IF settled4.numberOfCancelOrderBitfields >= 1 /\ (settled4.cancelOrderBitfield1 # << >> /\ (settled4.cancelOrderBitfield1[1] \div 4) % 2 > 0) THEN (IF settled4.massCancel = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled4.massCancel) ELSE << >>]
        settled6 == [settled5 EXCEPT !.riskRoot = IF settled5.numberOfCancelOrderBitfields >= 1 /\ (settled5.cancelOrderBitfield1 # << >> /\ (settled5.cancelOrderBitfield1[1] \div 8) % 2 > 0) THEN (IF settled5.riskRoot = << >> THEN <<[i \in 1 .. 6 |-> 0]>> ELSE settled5.riskRoot) ELSE << >>]
        settled7 == [settled6 EXCEPT !.massCancelId = IF settled6.numberOfCancelOrderBitfields >= 1 /\ (settled6.cancelOrderBitfield1 # << >> /\ (settled6.cancelOrderBitfield1[1] \div 16) % 2 > 0) THEN (IF settled6.massCancelId = << >> THEN <<[i \in 1 .. 20 |-> 0]>> ELSE settled6.massCancelId) ELSE << >>]
        settled8 == [settled7 EXCEPT !.massCancelInst = IF settled7.numberOfCancelOrderBitfields >= 2 /\ (settled7.cancelOrderBitfield2 # << >> /\ settled7.cancelOrderBitfield2[1] % 2 > 0) THEN (IF settled7.massCancelInst = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled7.massCancelInst) ELSE << >>]
    IN  settled8

ZeroCancelOrderMessage ==
    SettleCancelOrderMessage([ origClOrdId                  |-> [i \in 1 .. 20 |-> 0],
                               numberOfCancelOrderBitfields |-> 0,
                               cancelOrderBitfield1         |-> << >>,
                               cancelOrderBitfield2         |-> << >>,
                               clearingFirm                 |-> << >>,
                               massCancelLockout            |-> << >>,
                               massCancel                   |-> << >>,
                               riskRoot                     |-> << >>,
                               massCancelId                 |-> << >>,
                               massCancelInst               |-> << >> ])

(* Cancel Order Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelOrderMessage ==
    { ZeroCancelOrderMessage }
        \cup { SettleCancelOrderMessage([ZeroCancelOrderMessage EXCEPT !.origClOrdId = one]) : one \in Sample(20) }
        \cup { SettleCancelOrderMessage([ZeroCancelOrderMessage EXCEPT !.numberOfCancelOrderBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleCancelOrderMessage([ZeroCancelOrderMessage EXCEPT !.numberOfCancelOrderBitfields = 1, !.cancelOrderBitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleCancelOrderMessage([ZeroCancelOrderMessage EXCEPT !.numberOfCancelOrderBitfields = 2, !.cancelOrderBitfield2 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleCancelOrderMessage([ZeroCancelOrderMessage EXCEPT !.numberOfCancelOrderBitfields = 1, !.cancelOrderBitfield1 = <<1>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleCancelOrderMessage([ZeroCancelOrderMessage EXCEPT !.numberOfCancelOrderBitfields = 1, !.cancelOrderBitfield1 = <<2>>, !.massCancelLockout = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelOrderMessage([ZeroCancelOrderMessage EXCEPT !.numberOfCancelOrderBitfields = 1, !.cancelOrderBitfield1 = <<4>>, !.massCancel = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelOrderMessage([ZeroCancelOrderMessage EXCEPT !.numberOfCancelOrderBitfields = 1, !.cancelOrderBitfield1 = <<8>>, !.riskRoot = one]) : one \in { <<held>> : held \in Sample(6) } }
        \cup { SettleCancelOrderMessage([ZeroCancelOrderMessage EXCEPT !.numberOfCancelOrderBitfields = 1, !.cancelOrderBitfield1 = <<16>>, !.massCancelId = one]) : one \in { <<held>> : held \in Sample(20) } }
        \cup { SettleCancelOrderMessage([ZeroCancelOrderMessage EXCEPT !.numberOfCancelOrderBitfields = 2, !.cancelOrderBitfield2 = <<1>>, !.massCancelInst = one]) : one \in { <<held>> : held \in Sample(16) } }

(***************************************************************************)
(* Modify Order Message                                                    *)
(***************************************************************************)

ModifyOrderMessage ==
    [ clOrdId                      : Sample(20),
      origClOrdId                  : Sample(20),
      numberOfModifyOrderBitfields : 0 .. 255,
      modifyOrderBitfield1         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      modifyOrderBitfield2         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      clearingFirm                 : { << >> } \cup { <<held>> : held \in Sample(4) },
      orderQtyLong                 : { << >> } \cup { <<held>> : held \in Sample(4) },
      priceLong                    : { << >> } \cup { <<held>> : held \in Sample(8) },
      ordType                      : { << >> } \cup { <<held>> : held \in Sample(1) },
      cancelOrigOnReject           : { << >> } \cup { <<held>> : held \in Sample(1) },
      execInst                     : { << >> } \cup { <<held>> : held \in Sample(1) },
      maxFloor                     : { << >> } \cup { <<held>> : held \in Sample(4) },
      stopPx                       : { << >> } \cup { <<held>> : held \in Sample(8) } ]

EncodeModifyOrderMessage(message) ==
    message.clOrdId
        \o message.origClOrdId
        \o EncodeUIntBE(message.numberOfModifyOrderBitfields, 1)
        \o (IF message.modifyOrderBitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.modifyOrderBitfield1[1], 1))
        \o (IF message.modifyOrderBitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.modifyOrderBitfield2[1], 1))
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])
        \o (IF message.orderQtyLong = << >> THEN << >> ELSE message.orderQtyLong[1])
        \o (IF message.priceLong = << >> THEN << >> ELSE message.priceLong[1])
        \o (IF message.ordType = << >> THEN << >> ELSE message.ordType[1])
        \o (IF message.cancelOrigOnReject = << >> THEN << >> ELSE message.cancelOrigOnReject[1])
        \o (IF message.execInst = << >> THEN << >> ELSE message.execInst[1])
        \o (IF message.maxFloor = << >> THEN << >> ELSE message.maxFloor[1])
        \o (IF message.stopPx = << >> THEN << >> ELSE message.stopPx[1])

DecodeModifyOrderMessage(bytes) ==
    LET clOrdId == ReadBytes(bytes, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 20) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET numberOfModifyOrderBitfields == ReadUIntBE(origClOrdId.rest, 1) IN IF ~numberOfModifyOrderBitfields.ok THEN Fail ELSE
    LET modifyOrderBitfield1 == ReadWhen(numberOfModifyOrderBitfields.value >= 1, ReadUIntLE(numberOfModifyOrderBitfields.rest, 1), numberOfModifyOrderBitfields.rest) IN IF ~modifyOrderBitfield1.ok THEN Fail ELSE
    LET modifyOrderBitfield2 == ReadWhen(numberOfModifyOrderBitfields.value >= 2, ReadUIntLE(modifyOrderBitfield1.rest, 1), modifyOrderBitfield1.rest) IN IF ~modifyOrderBitfield2.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfModifyOrderBitfields.value >= 1 /\ (modifyOrderBitfield1.value # << >> /\ modifyOrderBitfield1.value[1] % 2 > 0), ReadBytes(modifyOrderBitfield2.rest, 4), modifyOrderBitfield2.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET orderQtyLong == ReadWhen(numberOfModifyOrderBitfields.value >= 1 /\ (modifyOrderBitfield1.value # << >> /\ (modifyOrderBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~orderQtyLong.ok THEN Fail ELSE
    LET priceLong == ReadWhen(numberOfModifyOrderBitfields.value >= 1 /\ (modifyOrderBitfield1.value # << >> /\ (modifyOrderBitfield1.value[1] \div 8) % 2 > 0), ReadBytes(orderQtyLong.rest, 8), orderQtyLong.rest) IN IF ~priceLong.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfModifyOrderBitfields.value >= 1 /\ (modifyOrderBitfield1.value # << >> /\ (modifyOrderBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(priceLong.rest, 1), priceLong.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET cancelOrigOnReject == ReadWhen(numberOfModifyOrderBitfields.value >= 1 /\ (modifyOrderBitfield1.value # << >> /\ (modifyOrderBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~cancelOrigOnReject.ok THEN Fail ELSE
    LET execInst == ReadWhen(numberOfModifyOrderBitfields.value >= 1 /\ (modifyOrderBitfield1.value # << >> /\ (modifyOrderBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(cancelOrigOnReject.rest, 1), cancelOrigOnReject.rest) IN IF ~execInst.ok THEN Fail ELSE
    LET maxFloor == ReadWhen(numberOfModifyOrderBitfields.value >= 2 /\ (modifyOrderBitfield2.value # << >> /\ modifyOrderBitfield2.value[1] % 2 > 0), ReadBytes(execInst.rest, 4), execInst.rest) IN IF ~maxFloor.ok THEN Fail ELSE
    LET stopPx == ReadWhen(numberOfModifyOrderBitfields.value >= 2 /\ (modifyOrderBitfield2.value # << >> /\ (modifyOrderBitfield2.value[1] \div 2) % 2 > 0), ReadBytes(maxFloor.rest, 8), maxFloor.rest) IN IF ~stopPx.ok THEN Fail ELSE
    Ok([ clOrdId                      |-> clOrdId.value,
         origClOrdId                  |-> origClOrdId.value,
         numberOfModifyOrderBitfields |-> numberOfModifyOrderBitfields.value,
         modifyOrderBitfield1         |-> modifyOrderBitfield1.value,
         modifyOrderBitfield2         |-> modifyOrderBitfield2.value,
         clearingFirm                 |-> clearingFirm.value,
         orderQtyLong                 |-> orderQtyLong.value,
         priceLong                    |-> priceLong.value,
         ordType                      |-> ordType.value,
         cancelOrigOnReject           |-> cancelOrigOnReject.value,
         execInst                     |-> execInst.value,
         maxFloor                     |-> maxFloor.value,
         stopPx                       |-> stopPx.value ], stopPx.rest)

(* Modify Order Message with each field marked present by fields before it there exactly where they say *)
SettleModifyOrderMessage(message) ==
    LET settled1 == [message EXCEPT !.modifyOrderBitfield1 = IF message.numberOfModifyOrderBitfields >= 1 THEN (IF message.modifyOrderBitfield1 = << >> THEN <<0>> ELSE message.modifyOrderBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.modifyOrderBitfield2 = IF settled1.numberOfModifyOrderBitfields >= 2 THEN (IF settled1.modifyOrderBitfield2 = << >> THEN <<0>> ELSE settled1.modifyOrderBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.clearingFirm = IF settled2.numberOfModifyOrderBitfields >= 1 /\ (settled2.modifyOrderBitfield1 # << >> /\ settled2.modifyOrderBitfield1[1] % 2 > 0) THEN (IF settled2.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled2.clearingFirm) ELSE << >>]
        settled4 == [settled3 EXCEPT !.orderQtyLong = IF settled3.numberOfModifyOrderBitfields >= 1 /\ (settled3.modifyOrderBitfield1 # << >> /\ (settled3.modifyOrderBitfield1[1] \div 4) % 2 > 0) THEN (IF settled3.orderQtyLong = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled3.orderQtyLong) ELSE << >>]
        settled5 == [settled4 EXCEPT !.priceLong = IF settled4.numberOfModifyOrderBitfields >= 1 /\ (settled4.modifyOrderBitfield1 # << >> /\ (settled4.modifyOrderBitfield1[1] \div 8) % 2 > 0) THEN (IF settled4.priceLong = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled4.priceLong) ELSE << >>]
        settled6 == [settled5 EXCEPT !.ordType = IF settled5.numberOfModifyOrderBitfields >= 1 /\ (settled5.modifyOrderBitfield1 # << >> /\ (settled5.modifyOrderBitfield1[1] \div 16) % 2 > 0) THEN (IF settled5.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled5.ordType) ELSE << >>]
        settled7 == [settled6 EXCEPT !.cancelOrigOnReject = IF settled6.numberOfModifyOrderBitfields >= 1 /\ (settled6.modifyOrderBitfield1 # << >> /\ (settled6.modifyOrderBitfield1[1] \div 32) % 2 > 0) THEN (IF settled6.cancelOrigOnReject = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.cancelOrigOnReject) ELSE << >>]
        settled8 == [settled7 EXCEPT !.execInst = IF settled7.numberOfModifyOrderBitfields >= 1 /\ (settled7.modifyOrderBitfield1 # << >> /\ (settled7.modifyOrderBitfield1[1] \div 64) % 2 > 0) THEN (IF settled7.execInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled7.execInst) ELSE << >>]
        settled9 == [settled8 EXCEPT !.maxFloor = IF settled8.numberOfModifyOrderBitfields >= 2 /\ (settled8.modifyOrderBitfield2 # << >> /\ settled8.modifyOrderBitfield2[1] % 2 > 0) THEN (IF settled8.maxFloor = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled8.maxFloor) ELSE << >>]
        settled10 == [settled9 EXCEPT !.stopPx = IF settled9.numberOfModifyOrderBitfields >= 2 /\ (settled9.modifyOrderBitfield2 # << >> /\ (settled9.modifyOrderBitfield2[1] \div 2) % 2 > 0) THEN (IF settled9.stopPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled9.stopPx) ELSE << >>]
    IN  settled10

ZeroModifyOrderMessage ==
    SettleModifyOrderMessage([ clOrdId                      |-> [i \in 1 .. 20 |-> 0],
                               origClOrdId                  |-> [i \in 1 .. 20 |-> 0],
                               numberOfModifyOrderBitfields |-> 0,
                               modifyOrderBitfield1         |-> << >>,
                               modifyOrderBitfield2         |-> << >>,
                               clearingFirm                 |-> << >>,
                               orderQtyLong                 |-> << >>,
                               priceLong                    |-> << >>,
                               ordType                      |-> << >>,
                               cancelOrigOnReject           |-> << >>,
                               execInst                     |-> << >>,
                               maxFloor                     |-> << >>,
                               stopPx                       |-> << >> ])

(* Modify Order Message at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderMessage ==
    { ZeroModifyOrderMessage }
        \cup { SettleModifyOrderMessage([ZeroModifyOrderMessage EXCEPT !.clOrdId = one]) : one \in Sample(20) }
        \cup { SettleModifyOrderMessage([ZeroModifyOrderMessage EXCEPT !.origClOrdId = one]) : one \in Sample(20) }
        \cup { SettleModifyOrderMessage([ZeroModifyOrderMessage EXCEPT !.numberOfModifyOrderBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleModifyOrderMessage([ZeroModifyOrderMessage EXCEPT !.numberOfModifyOrderBitfields = 1, !.modifyOrderBitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleModifyOrderMessage([ZeroModifyOrderMessage EXCEPT !.numberOfModifyOrderBitfields = 2, !.modifyOrderBitfield2 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleModifyOrderMessage([ZeroModifyOrderMessage EXCEPT !.numberOfModifyOrderBitfields = 1, !.modifyOrderBitfield1 = <<1>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleModifyOrderMessage([ZeroModifyOrderMessage EXCEPT !.numberOfModifyOrderBitfields = 1, !.modifyOrderBitfield1 = <<4>>, !.orderQtyLong = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleModifyOrderMessage([ZeroModifyOrderMessage EXCEPT !.numberOfModifyOrderBitfields = 1, !.modifyOrderBitfield1 = <<8>>, !.priceLong = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleModifyOrderMessage([ZeroModifyOrderMessage EXCEPT !.numberOfModifyOrderBitfields = 1, !.modifyOrderBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleModifyOrderMessage([ZeroModifyOrderMessage EXCEPT !.numberOfModifyOrderBitfields = 1, !.modifyOrderBitfield1 = <<32>>, !.cancelOrigOnReject = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleModifyOrderMessage([ZeroModifyOrderMessage EXCEPT !.numberOfModifyOrderBitfields = 1, !.modifyOrderBitfield1 = <<64>>, !.execInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleModifyOrderMessage([ZeroModifyOrderMessage EXCEPT !.numberOfModifyOrderBitfields = 2, !.modifyOrderBitfield2 = <<1>>, !.maxFloor = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleModifyOrderMessage([ZeroModifyOrderMessage EXCEPT !.numberOfModifyOrderBitfields = 2, !.modifyOrderBitfield2 = <<2>>, !.stopPx = one]) : one \in { <<held>> : held \in Sample(8) } }

(***************************************************************************)
(* Quote Update: 32 bytes                                                  *)
(***************************************************************************)

QuoteUpdate ==
    [ symbolShort  : Sample(6),
      side         : Sample(1),
      openClose    : Sample(1),
      priceLong    : Sample(8),
      orderQtyLong : Sample(4),
      reserved12   : Sample(12) ]

EncodeQuoteUpdate(message) ==
    message.symbolShort
        \o message.side
        \o message.openClose
        \o message.priceLong
        \o message.orderQtyLong
        \o message.reserved12

DecodeQuoteUpdate(bytes) ==
    LET symbolShort == ReadBytes(bytes, 6) IN IF ~symbolShort.ok THEN Fail ELSE
    LET side == ReadBytes(symbolShort.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET openClose == ReadBytes(side.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET priceLong == ReadBytes(openClose.rest, 8) IN IF ~priceLong.ok THEN Fail ELSE
    LET orderQtyLong == ReadBytes(priceLong.rest, 4) IN IF ~orderQtyLong.ok THEN Fail ELSE
    LET reserved12 == ReadBytes(orderQtyLong.rest, 12) IN IF ~reserved12.ok THEN Fail ELSE
    Ok([ symbolShort  |-> symbolShort.value,
         side         |-> side.value,
         openClose    |-> openClose.value,
         priceLong    |-> priceLong.value,
         orderQtyLong |-> orderQtyLong.value,
         reserved12   |-> reserved12.value ], reserved12.rest)

ZeroQuoteUpdate ==
    [ symbolShort  |-> [i \in 1 .. 6 |-> 0],
      side         |-> [i \in 1 .. 1 |-> 0],
      openClose    |-> [i \in 1 .. 1 |-> 0],
      priceLong    |-> [i \in 1 .. 8 |-> 0],
      orderQtyLong |-> [i \in 1 .. 4 |-> 0],
      reserved12   |-> [i \in 1 .. 12 |-> 0] ]

(* Quote Update at zero, then each field in turn at the values it is checked at *)
CheckedQuoteUpdate ==
    { ZeroQuoteUpdate }
        \cup { [ZeroQuoteUpdate EXCEPT !.symbolShort = one] : one \in Sample(6) }
        \cup { [ZeroQuoteUpdate EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroQuoteUpdate EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroQuoteUpdate EXCEPT !.priceLong = one] : one \in Sample(8) }
        \cup { [ZeroQuoteUpdate EXCEPT !.orderQtyLong = one] : one \in Sample(4) }
        \cup { [ZeroQuoteUpdate EXCEPT !.reserved12 = one] : one \in Sample(12) }

(* A run of Quote Update, written one after another *)
RECURSIVE EncodeQuoteUpdateList(_)
EncodeQuoteUpdateList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeQuoteUpdate(Head(messages)) \o EncodeQuoteUpdateList(Tail(messages))

(* As many Quote Update as the field that counts them says *)
RECURSIVE ReadQuoteUpdateList(_, _)
ReadQuoteUpdateList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeQuoteUpdate(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadQuoteUpdateList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Quote Update of each kind, for the lists that carry them *)
OneQuoteUpdate == { ZeroQuoteUpdate }

(***************************************************************************)
(* Quote Update Message                                                    *)
(***************************************************************************)

QuoteUpdateMessage ==
    [ quoteUpdateId      : Sample(16),
      clearingFirm       : Sample(4),
      clearingAccount    : Sample(4),
      cmtaNumber         : Sample(4),
      account            : Sample(16),
      customGroupId      : Sample(2),
      capacity           : Sample(1),
      reserved15         : Sample(15),
      sendTime           : Sample(8),
      postingInstruction : Sample(1),
      sessionEligibility : Sample(1),
      quoteUpdate        : SampleLists(OneQuoteUpdate) ]

EncodeQuoteUpdateMessage(message) ==
    message.quoteUpdateId
        \o message.clearingFirm
        \o message.clearingAccount
        \o message.cmtaNumber
        \o message.account
        \o message.customGroupId
        \o message.capacity
        \o message.reserved15
        \o message.sendTime
        \o message.postingInstruction
        \o message.sessionEligibility
        \o EncodeUIntBE(Len(message.quoteUpdate), 1)
        \o EncodeQuoteUpdateList(message.quoteUpdate)

DecodeQuoteUpdateMessage(bytes) ==
    LET quoteUpdateId == ReadBytes(bytes, 16) IN IF ~quoteUpdateId.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(quoteUpdateId.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadBytes(clearingFirm.rest, 4) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET cmtaNumber == ReadBytes(clearingAccount.rest, 4) IN IF ~cmtaNumber.ok THEN Fail ELSE
    LET account == ReadBytes(cmtaNumber.rest, 16) IN IF ~account.ok THEN Fail ELSE
    LET customGroupId == ReadBytes(account.rest, 2) IN IF ~customGroupId.ok THEN Fail ELSE
    LET capacity == ReadBytes(customGroupId.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET reserved15 == ReadBytes(capacity.rest, 15) IN IF ~reserved15.ok THEN Fail ELSE
    LET sendTime == ReadBytes(reserved15.rest, 8) IN IF ~sendTime.ok THEN Fail ELSE
    LET postingInstruction == ReadBytes(sendTime.rest, 1) IN IF ~postingInstruction.ok THEN Fail ELSE
    LET sessionEligibility == ReadBytes(postingInstruction.rest, 1) IN IF ~sessionEligibility.ok THEN Fail ELSE
    LET numberOfQuoteUpdates == ReadUIntBE(sessionEligibility.rest, 1) IN IF ~numberOfQuoteUpdates.ok THEN Fail ELSE
    LET quoteUpdate == ReadQuoteUpdateList(numberOfQuoteUpdates.rest, numberOfQuoteUpdates.value) IN IF ~quoteUpdate.ok THEN Fail ELSE
    Ok([ quoteUpdateId      |-> quoteUpdateId.value,
         clearingFirm       |-> clearingFirm.value,
         clearingAccount    |-> clearingAccount.value,
         cmtaNumber         |-> cmtaNumber.value,
         account            |-> account.value,
         customGroupId      |-> customGroupId.value,
         capacity           |-> capacity.value,
         reserved15         |-> reserved15.value,
         sendTime           |-> sendTime.value,
         postingInstruction |-> postingInstruction.value,
         sessionEligibility |-> sessionEligibility.value,
         quoteUpdate        |-> quoteUpdate.value ], quoteUpdate.rest)

ZeroQuoteUpdateMessage ==
    [ quoteUpdateId      |-> [i \in 1 .. 16 |-> 0],
      clearingFirm       |-> [i \in 1 .. 4 |-> 0],
      clearingAccount    |-> [i \in 1 .. 4 |-> 0],
      cmtaNumber         |-> [i \in 1 .. 4 |-> 0],
      account            |-> [i \in 1 .. 16 |-> 0],
      customGroupId      |-> [i \in 1 .. 2 |-> 0],
      capacity           |-> [i \in 1 .. 1 |-> 0],
      reserved15         |-> [i \in 1 .. 15 |-> 0],
      sendTime           |-> [i \in 1 .. 8 |-> 0],
      postingInstruction |-> [i \in 1 .. 1 |-> 0],
      sessionEligibility |-> [i \in 1 .. 1 |-> 0],
      quoteUpdate        |-> << >> ]

(* Quote Update Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteUpdateMessage ==
    { ZeroQuoteUpdateMessage }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.quoteUpdateId = one] : one \in Sample(16) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.clearingAccount = one] : one \in Sample(4) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.cmtaNumber = one] : one \in Sample(4) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.account = one] : one \in Sample(16) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.customGroupId = one] : one \in Sample(2) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.reserved15 = one] : one \in Sample(15) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.sendTime = one] : one \in Sample(8) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.postingInstruction = one] : one \in Sample(1) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.sessionEligibility = one] : one \in Sample(1) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.quoteUpdate = one] : one \in SampleLists(OneQuoteUpdate) }

(***************************************************************************)
(* Short Quote Update: 16 bytes                                            *)
(***************************************************************************)

ShortQuoteUpdate ==
    [ symbolShort   : Sample(6),
      side          : Sample(1),
      openClose     : Sample(1),
      priceShort    : Sample(4),
      orderQtyShort : Sample(2),
      reserved2     : Sample(2) ]

EncodeShortQuoteUpdate(message) ==
    message.symbolShort
        \o message.side
        \o message.openClose
        \o message.priceShort
        \o message.orderQtyShort
        \o message.reserved2

DecodeShortQuoteUpdate(bytes) ==
    LET symbolShort == ReadBytes(bytes, 6) IN IF ~symbolShort.ok THEN Fail ELSE
    LET side == ReadBytes(symbolShort.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET openClose == ReadBytes(side.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET priceShort == ReadBytes(openClose.rest, 4) IN IF ~priceShort.ok THEN Fail ELSE
    LET orderQtyShort == ReadBytes(priceShort.rest, 2) IN IF ~orderQtyShort.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(orderQtyShort.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    Ok([ symbolShort   |-> symbolShort.value,
         side          |-> side.value,
         openClose     |-> openClose.value,
         priceShort    |-> priceShort.value,
         orderQtyShort |-> orderQtyShort.value,
         reserved2     |-> reserved2.value ], reserved2.rest)

ZeroShortQuoteUpdate ==
    [ symbolShort   |-> [i \in 1 .. 6 |-> 0],
      side          |-> [i \in 1 .. 1 |-> 0],
      openClose     |-> [i \in 1 .. 1 |-> 0],
      priceShort    |-> [i \in 1 .. 4 |-> 0],
      orderQtyShort |-> [i \in 1 .. 2 |-> 0],
      reserved2     |-> [i \in 1 .. 2 |-> 0] ]

(* Short Quote Update at zero, then each field in turn at the values it is checked at *)
CheckedShortQuoteUpdate ==
    { ZeroShortQuoteUpdate }
        \cup { [ZeroShortQuoteUpdate EXCEPT !.symbolShort = one] : one \in Sample(6) }
        \cup { [ZeroShortQuoteUpdate EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroShortQuoteUpdate EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroShortQuoteUpdate EXCEPT !.priceShort = one] : one \in Sample(4) }
        \cup { [ZeroShortQuoteUpdate EXCEPT !.orderQtyShort = one] : one \in Sample(2) }
        \cup { [ZeroShortQuoteUpdate EXCEPT !.reserved2 = one] : one \in Sample(2) }

(* A run of Short Quote Update, written one after another *)
RECURSIVE EncodeShortQuoteUpdateList(_)
EncodeShortQuoteUpdateList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeShortQuoteUpdate(Head(messages)) \o EncodeShortQuoteUpdateList(Tail(messages))

(* As many Short Quote Update as the field that counts them says *)
RECURSIVE ReadShortQuoteUpdateList(_, _)
ReadShortQuoteUpdateList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeShortQuoteUpdate(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadShortQuoteUpdateList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Short Quote Update of each kind, for the lists that carry them *)
OneShortQuoteUpdate == { ZeroShortQuoteUpdate }

(***************************************************************************)
(* Short Quote Update Message                                              *)
(***************************************************************************)

ShortQuoteUpdateMessage ==
    [ quoteUpdateId      : Sample(16),
      clearingFirm       : Sample(4),
      clearingAccount    : Sample(4),
      customGroupId      : Sample(2),
      capacity           : Sample(1),
      reserved3          : Sample(3),
      sendTime           : Sample(8),
      postingInstruction : Sample(1),
      sessionEligibility : Sample(1),
      shortQuoteUpdate   : SampleLists(OneShortQuoteUpdate) ]

EncodeShortQuoteUpdateMessage(message) ==
    message.quoteUpdateId
        \o message.clearingFirm
        \o message.clearingAccount
        \o message.customGroupId
        \o message.capacity
        \o message.reserved3
        \o message.sendTime
        \o message.postingInstruction
        \o message.sessionEligibility
        \o EncodeUIntBE(Len(message.shortQuoteUpdate), 1)
        \o EncodeShortQuoteUpdateList(message.shortQuoteUpdate)

DecodeShortQuoteUpdateMessage(bytes) ==
    LET quoteUpdateId == ReadBytes(bytes, 16) IN IF ~quoteUpdateId.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(quoteUpdateId.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadBytes(clearingFirm.rest, 4) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET customGroupId == ReadBytes(clearingAccount.rest, 2) IN IF ~customGroupId.ok THEN Fail ELSE
    LET capacity == ReadBytes(customGroupId.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET reserved3 == ReadBytes(capacity.rest, 3) IN IF ~reserved3.ok THEN Fail ELSE
    LET sendTime == ReadBytes(reserved3.rest, 8) IN IF ~sendTime.ok THEN Fail ELSE
    LET postingInstruction == ReadBytes(sendTime.rest, 1) IN IF ~postingInstruction.ok THEN Fail ELSE
    LET sessionEligibility == ReadBytes(postingInstruction.rest, 1) IN IF ~sessionEligibility.ok THEN Fail ELSE
    LET numberOfShortQuoteUpdates == ReadUIntBE(sessionEligibility.rest, 1) IN IF ~numberOfShortQuoteUpdates.ok THEN Fail ELSE
    LET shortQuoteUpdate == ReadShortQuoteUpdateList(numberOfShortQuoteUpdates.rest, numberOfShortQuoteUpdates.value) IN IF ~shortQuoteUpdate.ok THEN Fail ELSE
    Ok([ quoteUpdateId      |-> quoteUpdateId.value,
         clearingFirm       |-> clearingFirm.value,
         clearingAccount    |-> clearingAccount.value,
         customGroupId      |-> customGroupId.value,
         capacity           |-> capacity.value,
         reserved3          |-> reserved3.value,
         sendTime           |-> sendTime.value,
         postingInstruction |-> postingInstruction.value,
         sessionEligibility |-> sessionEligibility.value,
         shortQuoteUpdate   |-> shortQuoteUpdate.value ], shortQuoteUpdate.rest)

ZeroShortQuoteUpdateMessage ==
    [ quoteUpdateId      |-> [i \in 1 .. 16 |-> 0],
      clearingFirm       |-> [i \in 1 .. 4 |-> 0],
      clearingAccount    |-> [i \in 1 .. 4 |-> 0],
      customGroupId      |-> [i \in 1 .. 2 |-> 0],
      capacity           |-> [i \in 1 .. 1 |-> 0],
      reserved3          |-> [i \in 1 .. 3 |-> 0],
      sendTime           |-> [i \in 1 .. 8 |-> 0],
      postingInstruction |-> [i \in 1 .. 1 |-> 0],
      sessionEligibility |-> [i \in 1 .. 1 |-> 0],
      shortQuoteUpdate   |-> << >> ]

(* Short Quote Update Message at zero, then each field in turn at the values it is checked at *)
CheckedShortQuoteUpdateMessage ==
    { ZeroShortQuoteUpdateMessage }
        \cup { [ZeroShortQuoteUpdateMessage EXCEPT !.quoteUpdateId = one] : one \in Sample(16) }
        \cup { [ZeroShortQuoteUpdateMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroShortQuoteUpdateMessage EXCEPT !.clearingAccount = one] : one \in Sample(4) }
        \cup { [ZeroShortQuoteUpdateMessage EXCEPT !.customGroupId = one] : one \in Sample(2) }
        \cup { [ZeroShortQuoteUpdateMessage EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroShortQuoteUpdateMessage EXCEPT !.reserved3 = one] : one \in Sample(3) }
        \cup { [ZeroShortQuoteUpdateMessage EXCEPT !.sendTime = one] : one \in Sample(8) }
        \cup { [ZeroShortQuoteUpdateMessage EXCEPT !.postingInstruction = one] : one \in Sample(1) }
        \cup { [ZeroShortQuoteUpdateMessage EXCEPT !.sessionEligibility = one] : one \in Sample(1) }
        \cup { [ZeroShortQuoteUpdateMessage EXCEPT !.shortQuoteUpdate = one] : one \in SampleLists(OneShortQuoteUpdate) }

(***************************************************************************)
(* Purge Order Message                                                     *)
(***************************************************************************)

PurgeOrderMessage ==
    [ massCancel                  : Sample(1),
      numberOfPurgeOrderBitfields : 0 .. 255,
      purgeOrderBitfield1         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      purgeOrderBitfield2         : { << >> } \cup { <<held>> : held \in Sample(1) },
      clearingFirm                : { << >> } \cup { <<held>> : held \in Sample(4) },
      massCancelLockout           : { << >> } \cup { <<held>> : held \in Sample(1) },
      massCancelInst              : { << >> } \cup { <<held>> : held \in Sample(16) },
      riskRoot                    : { << >> } \cup { <<held>> : held \in Sample(6) },
      massCancelId                : { << >> } \cup { <<held>> : held \in Sample(20) } ]

EncodePurgeOrderMessage(message) ==
    message.massCancel
        \o EncodeUIntBE(message.numberOfPurgeOrderBitfields, 1)
        \o (IF message.purgeOrderBitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.purgeOrderBitfield1[1], 1))
        \o (IF message.purgeOrderBitfield2 = << >> THEN << >> ELSE message.purgeOrderBitfield2[1])
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])
        \o (IF message.massCancelLockout = << >> THEN << >> ELSE message.massCancelLockout[1])
        \o (IF message.massCancelInst = << >> THEN << >> ELSE message.massCancelInst[1])
        \o (IF message.riskRoot = << >> THEN << >> ELSE message.riskRoot[1])
        \o (IF message.massCancelId = << >> THEN << >> ELSE message.massCancelId[1])

DecodePurgeOrderMessage(bytes) ==
    LET massCancel == ReadBytes(bytes, 1) IN IF ~massCancel.ok THEN Fail ELSE
    LET numberOfPurgeOrderBitfields == ReadUIntBE(massCancel.rest, 1) IN IF ~numberOfPurgeOrderBitfields.ok THEN Fail ELSE
    LET purgeOrderBitfield1 == ReadWhen(numberOfPurgeOrderBitfields.value >= 1, ReadUIntLE(numberOfPurgeOrderBitfields.rest, 1), numberOfPurgeOrderBitfields.rest) IN IF ~purgeOrderBitfield1.ok THEN Fail ELSE
    LET purgeOrderBitfield2 == ReadWhen(numberOfPurgeOrderBitfields.value >= 2, ReadBytes(purgeOrderBitfield1.rest, 1), purgeOrderBitfield1.rest) IN IF ~purgeOrderBitfield2.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfPurgeOrderBitfields.value >= 1 /\ (purgeOrderBitfield1.value # << >> /\ purgeOrderBitfield1.value[1] % 2 > 0), ReadBytes(purgeOrderBitfield2.rest, 4), purgeOrderBitfield2.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET massCancelLockout == ReadWhen(numberOfPurgeOrderBitfields.value >= 1 /\ (purgeOrderBitfield1.value # << >> /\ (purgeOrderBitfield1.value[1] \div 2) % 2 > 0), ReadBytes(clearingFirm.rest, 1), clearingFirm.rest) IN IF ~massCancelLockout.ok THEN Fail ELSE
    LET massCancelInst == ReadWhen(numberOfPurgeOrderBitfields.value >= 1 /\ (purgeOrderBitfield1.value # << >> /\ (purgeOrderBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(massCancelLockout.rest, 16), massCancelLockout.rest) IN IF ~massCancelInst.ok THEN Fail ELSE
    LET riskRoot == ReadWhen(numberOfPurgeOrderBitfields.value >= 1 /\ (purgeOrderBitfield1.value # << >> /\ (purgeOrderBitfield1.value[1] \div 8) % 2 > 0), ReadBytes(massCancelInst.rest, 6), massCancelInst.rest) IN IF ~riskRoot.ok THEN Fail ELSE
    LET massCancelId == ReadWhen(numberOfPurgeOrderBitfields.value >= 1 /\ (purgeOrderBitfield1.value # << >> /\ (purgeOrderBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(riskRoot.rest, 20), riskRoot.rest) IN IF ~massCancelId.ok THEN Fail ELSE
    Ok([ massCancel                  |-> massCancel.value,
         numberOfPurgeOrderBitfields |-> numberOfPurgeOrderBitfields.value,
         purgeOrderBitfield1         |-> purgeOrderBitfield1.value,
         purgeOrderBitfield2         |-> purgeOrderBitfield2.value,
         clearingFirm                |-> clearingFirm.value,
         massCancelLockout           |-> massCancelLockout.value,
         massCancelInst              |-> massCancelInst.value,
         riskRoot                    |-> riskRoot.value,
         massCancelId                |-> massCancelId.value ], massCancelId.rest)

(* Purge Order Message with each field marked present by fields before it there exactly where they say *)
SettlePurgeOrderMessage(message) ==
    LET settled1 == [message EXCEPT !.purgeOrderBitfield1 = IF message.numberOfPurgeOrderBitfields >= 1 THEN (IF message.purgeOrderBitfield1 = << >> THEN <<0>> ELSE message.purgeOrderBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.purgeOrderBitfield2 = IF settled1.numberOfPurgeOrderBitfields >= 2 THEN (IF settled1.purgeOrderBitfield2 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled1.purgeOrderBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.clearingFirm = IF settled2.numberOfPurgeOrderBitfields >= 1 /\ (settled2.purgeOrderBitfield1 # << >> /\ settled2.purgeOrderBitfield1[1] % 2 > 0) THEN (IF settled2.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled2.clearingFirm) ELSE << >>]
        settled4 == [settled3 EXCEPT !.massCancelLockout = IF settled3.numberOfPurgeOrderBitfields >= 1 /\ (settled3.purgeOrderBitfield1 # << >> /\ (settled3.purgeOrderBitfield1[1] \div 2) % 2 > 0) THEN (IF settled3.massCancelLockout = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled3.massCancelLockout) ELSE << >>]
        settled5 == [settled4 EXCEPT !.massCancelInst = IF settled4.numberOfPurgeOrderBitfields >= 1 /\ (settled4.purgeOrderBitfield1 # << >> /\ (settled4.purgeOrderBitfield1[1] \div 4) % 2 > 0) THEN (IF settled4.massCancelInst = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled4.massCancelInst) ELSE << >>]
        settled6 == [settled5 EXCEPT !.riskRoot = IF settled5.numberOfPurgeOrderBitfields >= 1 /\ (settled5.purgeOrderBitfield1 # << >> /\ (settled5.purgeOrderBitfield1[1] \div 8) % 2 > 0) THEN (IF settled5.riskRoot = << >> THEN <<[i \in 1 .. 6 |-> 0]>> ELSE settled5.riskRoot) ELSE << >>]
        settled7 == [settled6 EXCEPT !.massCancelId = IF settled6.numberOfPurgeOrderBitfields >= 1 /\ (settled6.purgeOrderBitfield1 # << >> /\ (settled6.purgeOrderBitfield1[1] \div 16) % 2 > 0) THEN (IF settled6.massCancelId = << >> THEN <<[i \in 1 .. 20 |-> 0]>> ELSE settled6.massCancelId) ELSE << >>]
    IN  settled7

ZeroPurgeOrderMessage ==
    SettlePurgeOrderMessage([ massCancel                  |-> [i \in 1 .. 1 |-> 0],
                              numberOfPurgeOrderBitfields |-> 0,
                              purgeOrderBitfield1         |-> << >>,
                              purgeOrderBitfield2         |-> << >>,
                              clearingFirm                |-> << >>,
                              massCancelLockout           |-> << >>,
                              massCancelInst              |-> << >>,
                              riskRoot                    |-> << >>,
                              massCancelId                |-> << >> ])

(* Purge Order Message at zero, then each field in turn at the values it is checked at *)
CheckedPurgeOrderMessage ==
    { ZeroPurgeOrderMessage }
        \cup { SettlePurgeOrderMessage([ZeroPurgeOrderMessage EXCEPT !.massCancel = one]) : one \in Sample(1) }
        \cup { SettlePurgeOrderMessage([ZeroPurgeOrderMessage EXCEPT !.numberOfPurgeOrderBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettlePurgeOrderMessage([ZeroPurgeOrderMessage EXCEPT !.numberOfPurgeOrderBitfields = 1, !.purgeOrderBitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettlePurgeOrderMessage([ZeroPurgeOrderMessage EXCEPT !.numberOfPurgeOrderBitfields = 2, !.purgeOrderBitfield2 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettlePurgeOrderMessage([ZeroPurgeOrderMessage EXCEPT !.numberOfPurgeOrderBitfields = 1, !.purgeOrderBitfield1 = <<1>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettlePurgeOrderMessage([ZeroPurgeOrderMessage EXCEPT !.numberOfPurgeOrderBitfields = 1, !.purgeOrderBitfield1 = <<2>>, !.massCancelLockout = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettlePurgeOrderMessage([ZeroPurgeOrderMessage EXCEPT !.numberOfPurgeOrderBitfields = 1, !.purgeOrderBitfield1 = <<4>>, !.massCancelInst = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettlePurgeOrderMessage([ZeroPurgeOrderMessage EXCEPT !.numberOfPurgeOrderBitfields = 1, !.purgeOrderBitfield1 = <<8>>, !.riskRoot = one]) : one \in { <<held>> : held \in Sample(6) } }
        \cup { SettlePurgeOrderMessage([ZeroPurgeOrderMessage EXCEPT !.numberOfPurgeOrderBitfields = 1, !.purgeOrderBitfield1 = <<16>>, !.massCancelId = one]) : one \in { <<held>> : held \in Sample(20) } }

(***************************************************************************)
(* Risk Reset Message: 40 bytes                                            *)
(***************************************************************************)

RiskResetMessage ==
    [ riskStatusId  : Sample(16),
      riskReset     : Sample(8),
      reserved4     : Sample(4),
      clearingFirm  : Sample(4),
      riskRoot      : Sample(6),
      customGroupId : Sample(2) ]

EncodeRiskResetMessage(message) ==
    message.riskStatusId
        \o message.riskReset
        \o message.reserved4
        \o message.clearingFirm
        \o message.riskRoot
        \o message.customGroupId

DecodeRiskResetMessage(bytes) ==
    LET riskStatusId == ReadBytes(bytes, 16) IN IF ~riskStatusId.ok THEN Fail ELSE
    LET riskReset == ReadBytes(riskStatusId.rest, 8) IN IF ~riskReset.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(riskReset.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(reserved4.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET riskRoot == ReadBytes(clearingFirm.rest, 6) IN IF ~riskRoot.ok THEN Fail ELSE
    LET customGroupId == ReadBytes(riskRoot.rest, 2) IN IF ~customGroupId.ok THEN Fail ELSE
    Ok([ riskStatusId  |-> riskStatusId.value,
         riskReset     |-> riskReset.value,
         reserved4     |-> reserved4.value,
         clearingFirm  |-> clearingFirm.value,
         riskRoot      |-> riskRoot.value,
         customGroupId |-> customGroupId.value ], customGroupId.rest)

ZeroRiskResetMessage ==
    [ riskStatusId  |-> [i \in 1 .. 16 |-> 0],
      riskReset     |-> [i \in 1 .. 8 |-> 0],
      reserved4     |-> [i \in 1 .. 4 |-> 0],
      clearingFirm  |-> [i \in 1 .. 4 |-> 0],
      riskRoot      |-> [i \in 1 .. 6 |-> 0],
      customGroupId |-> [i \in 1 .. 2 |-> 0] ]

(* Risk Reset Message at zero, then each field in turn at the values it is checked at *)
CheckedRiskResetMessage ==
    { ZeroRiskResetMessage }
        \cup { [ZeroRiskResetMessage EXCEPT !.riskStatusId = one] : one \in Sample(16) }
        \cup { [ZeroRiskResetMessage EXCEPT !.riskReset = one] : one \in Sample(8) }
        \cup { [ZeroRiskResetMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroRiskResetMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroRiskResetMessage EXCEPT !.riskRoot = one] : one \in Sample(6) }
        \cup { [ZeroRiskResetMessage EXCEPT !.customGroupId = one] : one \in Sample(2) }

(***************************************************************************)
(* Order Acknowledgment Message                                            *)
(***************************************************************************)

OrderAcknowledgmentMessage ==
    [ transactTime            : Sample(8),
      clOrdId                 : Sample(20),
      orderId                 : Sample(8),
      reserved1               : Sample(1),
      numberOfReturnBitfields : 0 .. 255,
      returnBitfield1         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield2         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield3         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield4         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield5         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield6         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield7         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield8         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield9         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield10        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield11        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield12        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield13        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield14        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield15        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield16        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield17        : { << >> } \cup { <<held>> : held \in Sample(1) },
      side                    : { << >> } \cup { <<held>> : held \in Sample(1) },
      priceLong               : { << >> } \cup { <<held>> : held \in Sample(8) },
      execInst                : { << >> } \cup { <<held>> : held \in Sample(1) },
      ordType                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce             : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                  : { << >> } \cup { <<held>> : held \in Sample(4) },
      maxRemovePct            : { << >> } \cup { <<held>> : held \in Sample(1) },
      symbolLong              : { << >> } \cup { <<held>> : held \in Sample(8) },
      capacity                : { << >> } \cup { <<held>> : held \in Sample(1) },
      account                 : { << >> } \cup { <<held>> : held \in Sample(16) },
      clearingFirm            : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingAccount         : { << >> } \cup { <<held>> : held \in Sample(4) },
      displayIndicator        : { << >> } \cup { <<held>> : held \in Sample(1) },
      maxFloor                : { << >> } \cup { <<held>> : held \in Sample(4) },
      orderQtyLong            : { << >> } \cup { <<held>> : held \in Sample(4) },
      preventMatch            : { << >> } \cup { <<held>> : held \in Sample(3) },
      maturityDate            : { << >> } \cup { <<held>> : held \in Sample(4) },
      strikePrice             : { << >> } \cup { <<held>> : held \in Sample(8) },
      putOrCall               : { << >> } \cup { <<held>> : held \in Sample(1) },
      openClose               : { << >> } \cup { <<held>> : held \in Sample(1) },
      correctedSize           : { << >> } \cup { <<held>> : held \in Sample(4) },
      origClOrdId             : { << >> } \cup { <<held>> : held \in Sample(20) },
      leavesQty               : { << >> } \cup { <<held>> : held \in Sample(4) },
      lastShares              : { << >> } \cup { <<held>> : held \in Sample(4) },
      lastPx                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      displayPrice            : { << >> } \cup { <<held>> : held \in Sample(8) },
      workingPrice            : { << >> } \cup { <<held>> : held \in Sample(8) },
      baseLiquidityIndicator  : { << >> } \cup { <<held>> : held \in Sample(1) },
      expireTime              : { << >> } \cup { <<held>> : held \in Sample(8) },
      secondaryOrderId        : { << >> } \cup { <<held>> : held \in Sample(8) },
      contraCapacity          : { << >> } \cup { <<held>> : held \in Sample(1) },
      attributedQuote         : { << >> } \cup { <<held>> : held \in Sample(1) },
      subLiquidityIndicator   : { << >> } \cup { <<held>> : held \in Sample(1) },
      echoText                : { << >> } \cup { <<held>> : held \in Sample(64) },
      stopPx                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      routingInst             : { << >> } \cup { <<held>> : held \in Sample(4) },
      routStrategy            : { << >> } \cup { <<held>> : held \in Sample(6) },
      routeDeliveryMethod     : { << >> } \cup { <<held>> : held \in Sample(3) },
      exDestination           : { << >> } \cup { <<held>> : held \in Sample(1) },
      cmtaNumber              : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingOptionalData    : { << >> } \cup { <<held>> : held \in Sample(16) },
      clientIdAttr            : { << >> } \cup { <<held>> : held \in Sample(4) },
      sessionEligibility      : { << >> } \cup { <<held>> : held \in Sample(1) },
      floorRoutingInst        : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderOrigin             : { << >> } \cup { <<held>> : held \in Sample(3) } ]

EncodeOrderAcknowledgmentMessage(message) ==
    message.transactTime
        \o message.clOrdId
        \o message.orderId
        \o message.reserved1
        \o EncodeUIntBE(message.numberOfReturnBitfields, 1)
        \o (IF message.returnBitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield1[1], 1))
        \o (IF message.returnBitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield2[1], 1))
        \o (IF message.returnBitfield3 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield3[1], 1))
        \o (IF message.returnBitfield4 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield4[1], 1))
        \o (IF message.returnBitfield5 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield5[1], 1))
        \o (IF message.returnBitfield6 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield6[1], 1))
        \o (IF message.returnBitfield7 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield7[1], 1))
        \o (IF message.returnBitfield8 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield8[1], 1))
        \o (IF message.returnBitfield9 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield9[1], 1))
        \o (IF message.returnBitfield10 = << >> THEN << >> ELSE message.returnBitfield10[1])
        \o (IF message.returnBitfield11 = << >> THEN << >> ELSE message.returnBitfield11[1])
        \o (IF message.returnBitfield12 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield12[1], 1))
        \o (IF message.returnBitfield13 = << >> THEN << >> ELSE message.returnBitfield13[1])
        \o (IF message.returnBitfield14 = << >> THEN << >> ELSE message.returnBitfield14[1])
        \o (IF message.returnBitfield15 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield15[1], 1))
        \o (IF message.returnBitfield16 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield16[1], 1))
        \o (IF message.returnBitfield17 = << >> THEN << >> ELSE message.returnBitfield17[1])
        \o (IF message.side = << >> THEN << >> ELSE message.side[1])
        \o (IF message.priceLong = << >> THEN << >> ELSE message.priceLong[1])
        \o (IF message.execInst = << >> THEN << >> ELSE message.execInst[1])
        \o (IF message.ordType = << >> THEN << >> ELSE message.ordType[1])
        \o (IF message.timeInForce = << >> THEN << >> ELSE message.timeInForce[1])
        \o (IF message.minQty = << >> THEN << >> ELSE message.minQty[1])
        \o (IF message.maxRemovePct = << >> THEN << >> ELSE message.maxRemovePct[1])
        \o (IF message.symbolLong = << >> THEN << >> ELSE message.symbolLong[1])
        \o (IF message.capacity = << >> THEN << >> ELSE message.capacity[1])
        \o (IF message.account = << >> THEN << >> ELSE message.account[1])
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])
        \o (IF message.clearingAccount = << >> THEN << >> ELSE message.clearingAccount[1])
        \o (IF message.displayIndicator = << >> THEN << >> ELSE message.displayIndicator[1])
        \o (IF message.maxFloor = << >> THEN << >> ELSE message.maxFloor[1])
        \o (IF message.orderQtyLong = << >> THEN << >> ELSE message.orderQtyLong[1])
        \o (IF message.preventMatch = << >> THEN << >> ELSE message.preventMatch[1])
        \o (IF message.maturityDate = << >> THEN << >> ELSE message.maturityDate[1])
        \o (IF message.strikePrice = << >> THEN << >> ELSE message.strikePrice[1])
        \o (IF message.putOrCall = << >> THEN << >> ELSE message.putOrCall[1])
        \o (IF message.openClose = << >> THEN << >> ELSE message.openClose[1])
        \o (IF message.correctedSize = << >> THEN << >> ELSE message.correctedSize[1])
        \o (IF message.origClOrdId = << >> THEN << >> ELSE message.origClOrdId[1])
        \o (IF message.leavesQty = << >> THEN << >> ELSE message.leavesQty[1])
        \o (IF message.lastShares = << >> THEN << >> ELSE message.lastShares[1])
        \o (IF message.lastPx = << >> THEN << >> ELSE message.lastPx[1])
        \o (IF message.displayPrice = << >> THEN << >> ELSE message.displayPrice[1])
        \o (IF message.workingPrice = << >> THEN << >> ELSE message.workingPrice[1])
        \o (IF message.baseLiquidityIndicator = << >> THEN << >> ELSE message.baseLiquidityIndicator[1])
        \o (IF message.expireTime = << >> THEN << >> ELSE message.expireTime[1])
        \o (IF message.secondaryOrderId = << >> THEN << >> ELSE message.secondaryOrderId[1])
        \o (IF message.contraCapacity = << >> THEN << >> ELSE message.contraCapacity[1])
        \o (IF message.attributedQuote = << >> THEN << >> ELSE message.attributedQuote[1])
        \o (IF message.subLiquidityIndicator = << >> THEN << >> ELSE message.subLiquidityIndicator[1])
        \o (IF message.echoText = << >> THEN << >> ELSE message.echoText[1])
        \o (IF message.stopPx = << >> THEN << >> ELSE message.stopPx[1])
        \o (IF message.routingInst = << >> THEN << >> ELSE message.routingInst[1])
        \o (IF message.routStrategy = << >> THEN << >> ELSE message.routStrategy[1])
        \o (IF message.routeDeliveryMethod = << >> THEN << >> ELSE message.routeDeliveryMethod[1])
        \o (IF message.exDestination = << >> THEN << >> ELSE message.exDestination[1])
        \o (IF message.cmtaNumber = << >> THEN << >> ELSE message.cmtaNumber[1])
        \o (IF message.clearingOptionalData = << >> THEN << >> ELSE message.clearingOptionalData[1])
        \o (IF message.clientIdAttr = << >> THEN << >> ELSE message.clientIdAttr[1])
        \o (IF message.sessionEligibility = << >> THEN << >> ELSE message.sessionEligibility[1])
        \o (IF message.floorRoutingInst = << >> THEN << >> ELSE message.floorRoutingInst[1])
        \o (IF message.orderOrigin = << >> THEN << >> ELSE message.orderOrigin[1])

DecodeOrderAcknowledgmentMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clOrdId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(orderId.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET numberOfReturnBitfields == ReadUIntBE(reserved1.rest, 1) IN IF ~numberOfReturnBitfields.ok THEN Fail ELSE
    LET returnBitfield1 == ReadWhen(numberOfReturnBitfields.value >= 1, ReadUIntLE(numberOfReturnBitfields.rest, 1), numberOfReturnBitfields.rest) IN IF ~returnBitfield1.ok THEN Fail ELSE
    LET returnBitfield2 == ReadWhen(numberOfReturnBitfields.value >= 2, ReadUIntLE(returnBitfield1.rest, 1), returnBitfield1.rest) IN IF ~returnBitfield2.ok THEN Fail ELSE
    LET returnBitfield3 == ReadWhen(numberOfReturnBitfields.value >= 3, ReadUIntLE(returnBitfield2.rest, 1), returnBitfield2.rest) IN IF ~returnBitfield3.ok THEN Fail ELSE
    LET returnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadUIntLE(returnBitfield3.rest, 1), returnBitfield3.rest) IN IF ~returnBitfield4.ok THEN Fail ELSE
    LET returnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadUIntLE(returnBitfield4.rest, 1), returnBitfield4.rest) IN IF ~returnBitfield5.ok THEN Fail ELSE
    LET returnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadUIntLE(returnBitfield5.rest, 1), returnBitfield5.rest) IN IF ~returnBitfield6.ok THEN Fail ELSE
    LET returnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadUIntLE(returnBitfield6.rest, 1), returnBitfield6.rest) IN IF ~returnBitfield7.ok THEN Fail ELSE
    LET returnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadUIntLE(returnBitfield7.rest, 1), returnBitfield7.rest) IN IF ~returnBitfield8.ok THEN Fail ELSE
    LET returnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadUIntLE(returnBitfield8.rest, 1), returnBitfield8.rest) IN IF ~returnBitfield9.ok THEN Fail ELSE
    LET returnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadBytes(returnBitfield9.rest, 1), returnBitfield9.rest) IN IF ~returnBitfield10.ok THEN Fail ELSE
    LET returnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadBytes(returnBitfield10.rest, 1), returnBitfield10.rest) IN IF ~returnBitfield11.ok THEN Fail ELSE
    LET returnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadUIntLE(returnBitfield11.rest, 1), returnBitfield11.rest) IN IF ~returnBitfield12.ok THEN Fail ELSE
    LET returnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(returnBitfield12.rest, 1), returnBitfield12.rest) IN IF ~returnBitfield13.ok THEN Fail ELSE
    LET returnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(returnBitfield13.rest, 1), returnBitfield13.rest) IN IF ~returnBitfield14.ok THEN Fail ELSE
    LET returnBitfield15 == ReadWhen(numberOfReturnBitfields.value >= 15, ReadUIntLE(returnBitfield14.rest, 1), returnBitfield14.rest) IN IF ~returnBitfield15.ok THEN Fail ELSE
    LET returnBitfield16 == ReadWhen(numberOfReturnBitfields.value >= 16, ReadUIntLE(returnBitfield15.rest, 1), returnBitfield15.rest) IN IF ~returnBitfield16.ok THEN Fail ELSE
    LET returnBitfield17 == ReadWhen(numberOfReturnBitfields.value >= 17, ReadBytes(returnBitfield16.rest, 1), returnBitfield16.rest) IN IF ~returnBitfield17.ok THEN Fail ELSE
    LET side == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ returnBitfield1.value[1] % 2 > 0), ReadBytes(returnBitfield17.rest, 1), returnBitfield17.rest) IN IF ~side.ok THEN Fail ELSE
    LET priceLong == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(side.rest, 8), side.rest) IN IF ~priceLong.ok THEN Fail ELSE
    LET execInst == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 8) % 2 > 0), ReadBytes(priceLong.rest, 1), priceLong.rest) IN IF ~execInst.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(execInst.rest, 1), execInst.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET maxRemovePct == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 128) % 2 > 0), ReadBytes(minQty.rest, 1), minQty.rest) IN IF ~maxRemovePct.ok THEN Fail ELSE
    LET symbolLong == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ returnBitfield2.value[1] % 2 > 0), ReadBytes(maxRemovePct.rest, 8), maxRemovePct.rest) IN IF ~symbolLong.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ (returnBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(symbolLong.rest, 1), symbolLong.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ returnBitfield3.value[1] % 2 > 0), ReadBytes(capacity.rest, 16), capacity.rest) IN IF ~account.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 2) % 2 > 0), ReadBytes(account.rest, 4), account.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 4) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET displayIndicator == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 8) % 2 > 0), ReadBytes(clearingAccount.rest, 1), clearingAccount.rest) IN IF ~displayIndicator.ok THEN Fail ELSE
    LET maxFloor == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 16) % 2 > 0), ReadBytes(displayIndicator.rest, 4), displayIndicator.rest) IN IF ~maxFloor.ok THEN Fail ELSE
    LET orderQtyLong == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 64) % 2 > 0), ReadBytes(maxFloor.rest, 4), maxFloor.rest) IN IF ~orderQtyLong.ok THEN Fail ELSE
    LET preventMatch == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 128) % 2 > 0), ReadBytes(orderQtyLong.rest, 3), orderQtyLong.rest) IN IF ~preventMatch.ok THEN Fail ELSE
    LET maturityDate == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ returnBitfield4.value[1] % 2 > 0), ReadBytes(preventMatch.rest, 4), preventMatch.rest) IN IF ~maturityDate.ok THEN Fail ELSE
    LET strikePrice == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ (returnBitfield4.value[1] \div 2) % 2 > 0), ReadBytes(maturityDate.rest, 8), maturityDate.rest) IN IF ~strikePrice.ok THEN Fail ELSE
    LET putOrCall == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ (returnBitfield4.value[1] \div 4) % 2 > 0), ReadBytes(strikePrice.rest, 1), strikePrice.rest) IN IF ~putOrCall.ok THEN Fail ELSE
    LET openClose == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ (returnBitfield4.value[1] \div 8) % 2 > 0), ReadBytes(putOrCall.rest, 1), putOrCall.rest) IN IF ~openClose.ok THEN Fail ELSE
    LET correctedSize == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ (returnBitfield4.value[1] \div 32) % 2 > 0), ReadBytes(openClose.rest, 4), openClose.rest) IN IF ~correctedSize.ok THEN Fail ELSE
    LET origClOrdId == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ returnBitfield5.value[1] % 2 > 0), ReadBytes(correctedSize.rest, 20), correctedSize.rest) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET leavesQty == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 2) % 2 > 0), ReadBytes(origClOrdId.rest, 4), origClOrdId.rest) IN IF ~leavesQty.ok THEN Fail ELSE
    LET lastShares == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 4) % 2 > 0), ReadBytes(leavesQty.rest, 4), leavesQty.rest) IN IF ~lastShares.ok THEN Fail ELSE
    LET lastPx == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 8) % 2 > 0), ReadBytes(lastShares.rest, 8), lastShares.rest) IN IF ~lastPx.ok THEN Fail ELSE
    LET displayPrice == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 16) % 2 > 0), ReadBytes(lastPx.rest, 8), lastPx.rest) IN IF ~displayPrice.ok THEN Fail ELSE
    LET workingPrice == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 32) % 2 > 0), ReadBytes(displayPrice.rest, 8), displayPrice.rest) IN IF ~workingPrice.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 64) % 2 > 0), ReadBytes(workingPrice.rest, 1), workingPrice.rest) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET expireTime == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 128) % 2 > 0), ReadBytes(baseLiquidityIndicator.rest, 8), baseLiquidityIndicator.rest) IN IF ~expireTime.ok THEN Fail ELSE
    LET secondaryOrderId == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (returnBitfield6.value # << >> /\ returnBitfield6.value[1] % 2 > 0), ReadBytes(expireTime.rest, 8), expireTime.rest) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET contraCapacity == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (returnBitfield6.value # << >> /\ (returnBitfield6.value[1] \div 4) % 2 > 0), ReadBytes(secondaryOrderId.rest, 1), secondaryOrderId.rest) IN IF ~contraCapacity.ok THEN Fail ELSE
    LET attributedQuote == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (returnBitfield6.value # << >> /\ (returnBitfield6.value[1] \div 8) % 2 > 0), ReadBytes(contraCapacity.rest, 1), contraCapacity.rest) IN IF ~attributedQuote.ok THEN Fail ELSE
    LET subLiquidityIndicator == ReadWhen(numberOfReturnBitfields.value >= 7 /\ (returnBitfield7.value # << >> /\ returnBitfield7.value[1] % 2 > 0), ReadBytes(attributedQuote.rest, 1), attributedQuote.rest) IN IF ~subLiquidityIndicator.ok THEN Fail ELSE
    LET echoText == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 2) % 2 > 0), ReadBytes(subLiquidityIndicator.rest, 64), subLiquidityIndicator.rest) IN IF ~echoText.ok THEN Fail ELSE
    LET stopPx == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 4) % 2 > 0), ReadBytes(echoText.rest, 8), echoText.rest) IN IF ~stopPx.ok THEN Fail ELSE
    LET routingInst == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 8) % 2 > 0), ReadBytes(stopPx.rest, 4), stopPx.rest) IN IF ~routingInst.ok THEN Fail ELSE
    LET routStrategy == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 16) % 2 > 0), ReadBytes(routingInst.rest, 6), routingInst.rest) IN IF ~routStrategy.ok THEN Fail ELSE
    LET routeDeliveryMethod == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 32) % 2 > 0), ReadBytes(routStrategy.rest, 3), routStrategy.rest) IN IF ~routeDeliveryMethod.ok THEN Fail ELSE
    LET exDestination == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 64) % 2 > 0), ReadBytes(routeDeliveryMethod.rest, 1), routeDeliveryMethod.rest) IN IF ~exDestination.ok THEN Fail ELSE
    LET cmtaNumber == ReadWhen(numberOfReturnBitfields.value >= 9 /\ (returnBitfield9.value # << >> /\ (returnBitfield9.value[1] \div 32) % 2 > 0), ReadBytes(exDestination.rest, 4), exDestination.rest) IN IF ~cmtaNumber.ok THEN Fail ELSE
    LET clearingOptionalData == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (returnBitfield12.value # << >> /\ (returnBitfield12.value[1] \div 128) % 2 > 0), ReadBytes(cmtaNumber.rest, 16), cmtaNumber.rest) IN IF ~clearingOptionalData.ok THEN Fail ELSE
    LET clientIdAttr == ReadWhen(numberOfReturnBitfields.value >= 15 /\ (returnBitfield15.value # << >> /\ (returnBitfield15.value[1] \div 128) % 2 > 0), ReadBytes(clearingOptionalData.rest, 4), clearingOptionalData.rest) IN IF ~clientIdAttr.ok THEN Fail ELSE
    LET sessionEligibility == ReadWhen(numberOfReturnBitfields.value >= 16 /\ (returnBitfield16.value # << >> /\ (returnBitfield16.value[1] \div 2) % 2 > 0), ReadBytes(clientIdAttr.rest, 1), clientIdAttr.rest) IN IF ~sessionEligibility.ok THEN Fail ELSE
    LET floorRoutingInst == ReadWhen(numberOfReturnBitfields.value >= 16 /\ (returnBitfield16.value # << >> /\ (returnBitfield16.value[1] \div 32) % 2 > 0), ReadBytes(sessionEligibility.rest, 1), sessionEligibility.rest) IN IF ~floorRoutingInst.ok THEN Fail ELSE
    LET orderOrigin == ReadWhen(numberOfReturnBitfields.value >= 16 /\ (returnBitfield16.value # << >> /\ (returnBitfield16.value[1] \div 128) % 2 > 0), ReadBytes(floorRoutingInst.rest, 3), floorRoutingInst.rest) IN IF ~orderOrigin.ok THEN Fail ELSE
    Ok([ transactTime            |-> transactTime.value,
         clOrdId                 |-> clOrdId.value,
         orderId                 |-> orderId.value,
         reserved1               |-> reserved1.value,
         numberOfReturnBitfields |-> numberOfReturnBitfields.value,
         returnBitfield1         |-> returnBitfield1.value,
         returnBitfield2         |-> returnBitfield2.value,
         returnBitfield3         |-> returnBitfield3.value,
         returnBitfield4         |-> returnBitfield4.value,
         returnBitfield5         |-> returnBitfield5.value,
         returnBitfield6         |-> returnBitfield6.value,
         returnBitfield7         |-> returnBitfield7.value,
         returnBitfield8         |-> returnBitfield8.value,
         returnBitfield9         |-> returnBitfield9.value,
         returnBitfield10        |-> returnBitfield10.value,
         returnBitfield11        |-> returnBitfield11.value,
         returnBitfield12        |-> returnBitfield12.value,
         returnBitfield13        |-> returnBitfield13.value,
         returnBitfield14        |-> returnBitfield14.value,
         returnBitfield15        |-> returnBitfield15.value,
         returnBitfield16        |-> returnBitfield16.value,
         returnBitfield17        |-> returnBitfield17.value,
         side                    |-> side.value,
         priceLong               |-> priceLong.value,
         execInst                |-> execInst.value,
         ordType                 |-> ordType.value,
         timeInForce             |-> timeInForce.value,
         minQty                  |-> minQty.value,
         maxRemovePct            |-> maxRemovePct.value,
         symbolLong              |-> symbolLong.value,
         capacity                |-> capacity.value,
         account                 |-> account.value,
         clearingFirm            |-> clearingFirm.value,
         clearingAccount         |-> clearingAccount.value,
         displayIndicator        |-> displayIndicator.value,
         maxFloor                |-> maxFloor.value,
         orderQtyLong            |-> orderQtyLong.value,
         preventMatch            |-> preventMatch.value,
         maturityDate            |-> maturityDate.value,
         strikePrice             |-> strikePrice.value,
         putOrCall               |-> putOrCall.value,
         openClose               |-> openClose.value,
         correctedSize           |-> correctedSize.value,
         origClOrdId             |-> origClOrdId.value,
         leavesQty               |-> leavesQty.value,
         lastShares              |-> lastShares.value,
         lastPx                  |-> lastPx.value,
         displayPrice            |-> displayPrice.value,
         workingPrice            |-> workingPrice.value,
         baseLiquidityIndicator  |-> baseLiquidityIndicator.value,
         expireTime              |-> expireTime.value,
         secondaryOrderId        |-> secondaryOrderId.value,
         contraCapacity          |-> contraCapacity.value,
         attributedQuote         |-> attributedQuote.value,
         subLiquidityIndicator   |-> subLiquidityIndicator.value,
         echoText                |-> echoText.value,
         stopPx                  |-> stopPx.value,
         routingInst             |-> routingInst.value,
         routStrategy            |-> routStrategy.value,
         routeDeliveryMethod     |-> routeDeliveryMethod.value,
         exDestination           |-> exDestination.value,
         cmtaNumber              |-> cmtaNumber.value,
         clearingOptionalData    |-> clearingOptionalData.value,
         clientIdAttr            |-> clientIdAttr.value,
         sessionEligibility      |-> sessionEligibility.value,
         floorRoutingInst        |-> floorRoutingInst.value,
         orderOrigin             |-> orderOrigin.value ], orderOrigin.rest)

(* Order Acknowledgment Message with each field marked present by fields before it there exactly where they say *)
SettleOrderAcknowledgmentMessage(message) ==
    LET settled1 == [message EXCEPT !.returnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.returnBitfield1 = << >> THEN <<0>> ELSE message.returnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.returnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.returnBitfield2 = << >> THEN <<0>> ELSE settled1.returnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.returnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.returnBitfield3 = << >> THEN <<0>> ELSE settled2.returnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.returnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.returnBitfield4 = << >> THEN <<0>> ELSE settled3.returnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.returnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.returnBitfield5 = << >> THEN <<0>> ELSE settled4.returnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.returnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.returnBitfield6 = << >> THEN <<0>> ELSE settled5.returnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.returnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.returnBitfield7 = << >> THEN <<0>> ELSE settled6.returnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.returnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.returnBitfield8 = << >> THEN <<0>> ELSE settled7.returnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.returnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.returnBitfield9 = << >> THEN <<0>> ELSE settled8.returnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.returnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.returnBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.returnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.returnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.returnBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.returnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.returnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.returnBitfield12 = << >> THEN <<0>> ELSE settled11.returnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.returnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.returnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.returnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.returnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.returnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.returnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.returnBitfield15 = IF settled14.numberOfReturnBitfields >= 15 THEN (IF settled14.returnBitfield15 = << >> THEN <<0>> ELSE settled14.returnBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.returnBitfield16 = IF settled15.numberOfReturnBitfields >= 16 THEN (IF settled15.returnBitfield16 = << >> THEN <<0>> ELSE settled15.returnBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.returnBitfield17 = IF settled16.numberOfReturnBitfields >= 17 THEN (IF settled16.returnBitfield17 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled16.returnBitfield17) ELSE << >>]
        settled18 == [settled17 EXCEPT !.side = IF settled17.numberOfReturnBitfields >= 1 /\ (settled17.returnBitfield1 # << >> /\ settled17.returnBitfield1[1] % 2 > 0) THEN (IF settled17.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.side) ELSE << >>]
        settled19 == [settled18 EXCEPT !.priceLong = IF settled18.numberOfReturnBitfields >= 1 /\ (settled18.returnBitfield1 # << >> /\ (settled18.returnBitfield1[1] \div 4) % 2 > 0) THEN (IF settled18.priceLong = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled18.priceLong) ELSE << >>]
        settled20 == [settled19 EXCEPT !.execInst = IF settled19.numberOfReturnBitfields >= 1 /\ (settled19.returnBitfield1 # << >> /\ (settled19.returnBitfield1[1] \div 8) % 2 > 0) THEN (IF settled19.execInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled19.execInst) ELSE << >>]
        settled21 == [settled20 EXCEPT !.ordType = IF settled20.numberOfReturnBitfields >= 1 /\ (settled20.returnBitfield1 # << >> /\ (settled20.returnBitfield1[1] \div 16) % 2 > 0) THEN (IF settled20.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled20.ordType) ELSE << >>]
        settled22 == [settled21 EXCEPT !.timeInForce = IF settled21.numberOfReturnBitfields >= 1 /\ (settled21.returnBitfield1 # << >> /\ (settled21.returnBitfield1[1] \div 32) % 2 > 0) THEN (IF settled21.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled21.timeInForce) ELSE << >>]
        settled23 == [settled22 EXCEPT !.minQty = IF settled22.numberOfReturnBitfields >= 1 /\ (settled22.returnBitfield1 # << >> /\ (settled22.returnBitfield1[1] \div 64) % 2 > 0) THEN (IF settled22.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled22.minQty) ELSE << >>]
        settled24 == [settled23 EXCEPT !.maxRemovePct = IF settled23.numberOfReturnBitfields >= 1 /\ (settled23.returnBitfield1 # << >> /\ (settled23.returnBitfield1[1] \div 128) % 2 > 0) THEN (IF settled23.maxRemovePct = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled23.maxRemovePct) ELSE << >>]
        settled25 == [settled24 EXCEPT !.symbolLong = IF settled24.numberOfReturnBitfields >= 2 /\ (settled24.returnBitfield2 # << >> /\ settled24.returnBitfield2[1] % 2 > 0) THEN (IF settled24.symbolLong = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled24.symbolLong) ELSE << >>]
        settled26 == [settled25 EXCEPT !.capacity = IF settled25.numberOfReturnBitfields >= 2 /\ (settled25.returnBitfield2 # << >> /\ (settled25.returnBitfield2[1] \div 64) % 2 > 0) THEN (IF settled25.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled25.capacity) ELSE << >>]
        settled27 == [settled26 EXCEPT !.account = IF settled26.numberOfReturnBitfields >= 3 /\ (settled26.returnBitfield3 # << >> /\ settled26.returnBitfield3[1] % 2 > 0) THEN (IF settled26.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled26.account) ELSE << >>]
        settled28 == [settled27 EXCEPT !.clearingFirm = IF settled27.numberOfReturnBitfields >= 3 /\ (settled27.returnBitfield3 # << >> /\ (settled27.returnBitfield3[1] \div 2) % 2 > 0) THEN (IF settled27.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled27.clearingFirm) ELSE << >>]
        settled29 == [settled28 EXCEPT !.clearingAccount = IF settled28.numberOfReturnBitfields >= 3 /\ (settled28.returnBitfield3 # << >> /\ (settled28.returnBitfield3[1] \div 4) % 2 > 0) THEN (IF settled28.clearingAccount = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled28.clearingAccount) ELSE << >>]
        settled30 == [settled29 EXCEPT !.displayIndicator = IF settled29.numberOfReturnBitfields >= 3 /\ (settled29.returnBitfield3 # << >> /\ (settled29.returnBitfield3[1] \div 8) % 2 > 0) THEN (IF settled29.displayIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled29.displayIndicator) ELSE << >>]
        settled31 == [settled30 EXCEPT !.maxFloor = IF settled30.numberOfReturnBitfields >= 3 /\ (settled30.returnBitfield3 # << >> /\ (settled30.returnBitfield3[1] \div 16) % 2 > 0) THEN (IF settled30.maxFloor = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled30.maxFloor) ELSE << >>]
        settled32 == [settled31 EXCEPT !.orderQtyLong = IF settled31.numberOfReturnBitfields >= 3 /\ (settled31.returnBitfield3 # << >> /\ (settled31.returnBitfield3[1] \div 64) % 2 > 0) THEN (IF settled31.orderQtyLong = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled31.orderQtyLong) ELSE << >>]
        settled33 == [settled32 EXCEPT !.preventMatch = IF settled32.numberOfReturnBitfields >= 3 /\ (settled32.returnBitfield3 # << >> /\ (settled32.returnBitfield3[1] \div 128) % 2 > 0) THEN (IF settled32.preventMatch = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled32.preventMatch) ELSE << >>]
        settled34 == [settled33 EXCEPT !.maturityDate = IF settled33.numberOfReturnBitfields >= 4 /\ (settled33.returnBitfield4 # << >> /\ settled33.returnBitfield4[1] % 2 > 0) THEN (IF settled33.maturityDate = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled33.maturityDate) ELSE << >>]
        settled35 == [settled34 EXCEPT !.strikePrice = IF settled34.numberOfReturnBitfields >= 4 /\ (settled34.returnBitfield4 # << >> /\ (settled34.returnBitfield4[1] \div 2) % 2 > 0) THEN (IF settled34.strikePrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled34.strikePrice) ELSE << >>]
        settled36 == [settled35 EXCEPT !.putOrCall = IF settled35.numberOfReturnBitfields >= 4 /\ (settled35.returnBitfield4 # << >> /\ (settled35.returnBitfield4[1] \div 4) % 2 > 0) THEN (IF settled35.putOrCall = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled35.putOrCall) ELSE << >>]
        settled37 == [settled36 EXCEPT !.openClose = IF settled36.numberOfReturnBitfields >= 4 /\ (settled36.returnBitfield4 # << >> /\ (settled36.returnBitfield4[1] \div 8) % 2 > 0) THEN (IF settled36.openClose = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled36.openClose) ELSE << >>]
        settled38 == [settled37 EXCEPT !.correctedSize = IF settled37.numberOfReturnBitfields >= 4 /\ (settled37.returnBitfield4 # << >> /\ (settled37.returnBitfield4[1] \div 32) % 2 > 0) THEN (IF settled37.correctedSize = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled37.correctedSize) ELSE << >>]
        settled39 == [settled38 EXCEPT !.origClOrdId = IF settled38.numberOfReturnBitfields >= 5 /\ (settled38.returnBitfield5 # << >> /\ settled38.returnBitfield5[1] % 2 > 0) THEN (IF settled38.origClOrdId = << >> THEN <<[i \in 1 .. 20 |-> 0]>> ELSE settled38.origClOrdId) ELSE << >>]
        settled40 == [settled39 EXCEPT !.leavesQty = IF settled39.numberOfReturnBitfields >= 5 /\ (settled39.returnBitfield5 # << >> /\ (settled39.returnBitfield5[1] \div 2) % 2 > 0) THEN (IF settled39.leavesQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled39.leavesQty) ELSE << >>]
        settled41 == [settled40 EXCEPT !.lastShares = IF settled40.numberOfReturnBitfields >= 5 /\ (settled40.returnBitfield5 # << >> /\ (settled40.returnBitfield5[1] \div 4) % 2 > 0) THEN (IF settled40.lastShares = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled40.lastShares) ELSE << >>]
        settled42 == [settled41 EXCEPT !.lastPx = IF settled41.numberOfReturnBitfields >= 5 /\ (settled41.returnBitfield5 # << >> /\ (settled41.returnBitfield5[1] \div 8) % 2 > 0) THEN (IF settled41.lastPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled41.lastPx) ELSE << >>]
        settled43 == [settled42 EXCEPT !.displayPrice = IF settled42.numberOfReturnBitfields >= 5 /\ (settled42.returnBitfield5 # << >> /\ (settled42.returnBitfield5[1] \div 16) % 2 > 0) THEN (IF settled42.displayPrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled42.displayPrice) ELSE << >>]
        settled44 == [settled43 EXCEPT !.workingPrice = IF settled43.numberOfReturnBitfields >= 5 /\ (settled43.returnBitfield5 # << >> /\ (settled43.returnBitfield5[1] \div 32) % 2 > 0) THEN (IF settled43.workingPrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled43.workingPrice) ELSE << >>]
        settled45 == [settled44 EXCEPT !.baseLiquidityIndicator = IF settled44.numberOfReturnBitfields >= 5 /\ (settled44.returnBitfield5 # << >> /\ (settled44.returnBitfield5[1] \div 64) % 2 > 0) THEN (IF settled44.baseLiquidityIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled44.baseLiquidityIndicator) ELSE << >>]
        settled46 == [settled45 EXCEPT !.expireTime = IF settled45.numberOfReturnBitfields >= 5 /\ (settled45.returnBitfield5 # << >> /\ (settled45.returnBitfield5[1] \div 128) % 2 > 0) THEN (IF settled45.expireTime = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled45.expireTime) ELSE << >>]
        settled47 == [settled46 EXCEPT !.secondaryOrderId = IF settled46.numberOfReturnBitfields >= 6 /\ (settled46.returnBitfield6 # << >> /\ settled46.returnBitfield6[1] % 2 > 0) THEN (IF settled46.secondaryOrderId = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled46.secondaryOrderId) ELSE << >>]
        settled48 == [settled47 EXCEPT !.contraCapacity = IF settled47.numberOfReturnBitfields >= 6 /\ (settled47.returnBitfield6 # << >> /\ (settled47.returnBitfield6[1] \div 4) % 2 > 0) THEN (IF settled47.contraCapacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled47.contraCapacity) ELSE << >>]
        settled49 == [settled48 EXCEPT !.attributedQuote = IF settled48.numberOfReturnBitfields >= 6 /\ (settled48.returnBitfield6 # << >> /\ (settled48.returnBitfield6[1] \div 8) % 2 > 0) THEN (IF settled48.attributedQuote = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled48.attributedQuote) ELSE << >>]
        settled50 == [settled49 EXCEPT !.subLiquidityIndicator = IF settled49.numberOfReturnBitfields >= 7 /\ (settled49.returnBitfield7 # << >> /\ settled49.returnBitfield7[1] % 2 > 0) THEN (IF settled49.subLiquidityIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled49.subLiquidityIndicator) ELSE << >>]
        settled51 == [settled50 EXCEPT !.echoText = IF settled50.numberOfReturnBitfields >= 8 /\ (settled50.returnBitfield8 # << >> /\ (settled50.returnBitfield8[1] \div 2) % 2 > 0) THEN (IF settled50.echoText = << >> THEN <<[i \in 1 .. 64 |-> 0]>> ELSE settled50.echoText) ELSE << >>]
        settled52 == [settled51 EXCEPT !.stopPx = IF settled51.numberOfReturnBitfields >= 8 /\ (settled51.returnBitfield8 # << >> /\ (settled51.returnBitfield8[1] \div 4) % 2 > 0) THEN (IF settled51.stopPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled51.stopPx) ELSE << >>]
        settled53 == [settled52 EXCEPT !.routingInst = IF settled52.numberOfReturnBitfields >= 8 /\ (settled52.returnBitfield8 # << >> /\ (settled52.returnBitfield8[1] \div 8) % 2 > 0) THEN (IF settled52.routingInst = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled52.routingInst) ELSE << >>]
        settled54 == [settled53 EXCEPT !.routStrategy = IF settled53.numberOfReturnBitfields >= 8 /\ (settled53.returnBitfield8 # << >> /\ (settled53.returnBitfield8[1] \div 16) % 2 > 0) THEN (IF settled53.routStrategy = << >> THEN <<[i \in 1 .. 6 |-> 0]>> ELSE settled53.routStrategy) ELSE << >>]
        settled55 == [settled54 EXCEPT !.routeDeliveryMethod = IF settled54.numberOfReturnBitfields >= 8 /\ (settled54.returnBitfield8 # << >> /\ (settled54.returnBitfield8[1] \div 32) % 2 > 0) THEN (IF settled54.routeDeliveryMethod = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled54.routeDeliveryMethod) ELSE << >>]
        settled56 == [settled55 EXCEPT !.exDestination = IF settled55.numberOfReturnBitfields >= 8 /\ (settled55.returnBitfield8 # << >> /\ (settled55.returnBitfield8[1] \div 64) % 2 > 0) THEN (IF settled55.exDestination = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled55.exDestination) ELSE << >>]
        settled57 == [settled56 EXCEPT !.cmtaNumber = IF settled56.numberOfReturnBitfields >= 9 /\ (settled56.returnBitfield9 # << >> /\ (settled56.returnBitfield9[1] \div 32) % 2 > 0) THEN (IF settled56.cmtaNumber = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled56.cmtaNumber) ELSE << >>]
        settled58 == [settled57 EXCEPT !.clearingOptionalData = IF settled57.numberOfReturnBitfields >= 12 /\ (settled57.returnBitfield12 # << >> /\ (settled57.returnBitfield12[1] \div 128) % 2 > 0) THEN (IF settled57.clearingOptionalData = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled57.clearingOptionalData) ELSE << >>]
        settled59 == [settled58 EXCEPT !.clientIdAttr = IF settled58.numberOfReturnBitfields >= 15 /\ (settled58.returnBitfield15 # << >> /\ (settled58.returnBitfield15[1] \div 128) % 2 > 0) THEN (IF settled58.clientIdAttr = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled58.clientIdAttr) ELSE << >>]
        settled60 == [settled59 EXCEPT !.sessionEligibility = IF settled59.numberOfReturnBitfields >= 16 /\ (settled59.returnBitfield16 # << >> /\ (settled59.returnBitfield16[1] \div 2) % 2 > 0) THEN (IF settled59.sessionEligibility = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled59.sessionEligibility) ELSE << >>]
        settled61 == [settled60 EXCEPT !.floorRoutingInst = IF settled60.numberOfReturnBitfields >= 16 /\ (settled60.returnBitfield16 # << >> /\ (settled60.returnBitfield16[1] \div 32) % 2 > 0) THEN (IF settled60.floorRoutingInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled60.floorRoutingInst) ELSE << >>]
        settled62 == [settled61 EXCEPT !.orderOrigin = IF settled61.numberOfReturnBitfields >= 16 /\ (settled61.returnBitfield16 # << >> /\ (settled61.returnBitfield16[1] \div 128) % 2 > 0) THEN (IF settled61.orderOrigin = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled61.orderOrigin) ELSE << >>]
    IN  settled62

ZeroOrderAcknowledgmentMessage ==
    SettleOrderAcknowledgmentMessage([ transactTime            |-> [i \in 1 .. 8 |-> 0],
                                       clOrdId                 |-> [i \in 1 .. 20 |-> 0],
                                       orderId                 |-> [i \in 1 .. 8 |-> 0],
                                       reserved1               |-> [i \in 1 .. 1 |-> 0],
                                       numberOfReturnBitfields |-> 0,
                                       returnBitfield1         |-> << >>,
                                       returnBitfield2         |-> << >>,
                                       returnBitfield3         |-> << >>,
                                       returnBitfield4         |-> << >>,
                                       returnBitfield5         |-> << >>,
                                       returnBitfield6         |-> << >>,
                                       returnBitfield7         |-> << >>,
                                       returnBitfield8         |-> << >>,
                                       returnBitfield9         |-> << >>,
                                       returnBitfield10        |-> << >>,
                                       returnBitfield11        |-> << >>,
                                       returnBitfield12        |-> << >>,
                                       returnBitfield13        |-> << >>,
                                       returnBitfield14        |-> << >>,
                                       returnBitfield15        |-> << >>,
                                       returnBitfield16        |-> << >>,
                                       returnBitfield17        |-> << >>,
                                       side                    |-> << >>,
                                       priceLong               |-> << >>,
                                       execInst                |-> << >>,
                                       ordType                 |-> << >>,
                                       timeInForce             |-> << >>,
                                       minQty                  |-> << >>,
                                       maxRemovePct            |-> << >>,
                                       symbolLong              |-> << >>,
                                       capacity                |-> << >>,
                                       account                 |-> << >>,
                                       clearingFirm            |-> << >>,
                                       clearingAccount         |-> << >>,
                                       displayIndicator        |-> << >>,
                                       maxFloor                |-> << >>,
                                       orderQtyLong            |-> << >>,
                                       preventMatch            |-> << >>,
                                       maturityDate            |-> << >>,
                                       strikePrice             |-> << >>,
                                       putOrCall               |-> << >>,
                                       openClose               |-> << >>,
                                       correctedSize           |-> << >>,
                                       origClOrdId             |-> << >>,
                                       leavesQty               |-> << >>,
                                       lastShares              |-> << >>,
                                       lastPx                  |-> << >>,
                                       displayPrice            |-> << >>,
                                       workingPrice            |-> << >>,
                                       baseLiquidityIndicator  |-> << >>,
                                       expireTime              |-> << >>,
                                       secondaryOrderId        |-> << >>,
                                       contraCapacity          |-> << >>,
                                       attributedQuote         |-> << >>,
                                       subLiquidityIndicator   |-> << >>,
                                       echoText                |-> << >>,
                                       stopPx                  |-> << >>,
                                       routingInst             |-> << >>,
                                       routStrategy            |-> << >>,
                                       routeDeliveryMethod     |-> << >>,
                                       exDestination           |-> << >>,
                                       cmtaNumber              |-> << >>,
                                       clearingOptionalData    |-> << >>,
                                       clientIdAttr            |-> << >>,
                                       sessionEligibility      |-> << >>,
                                       floorRoutingInst        |-> << >>,
                                       orderOrigin             |-> << >> ])

(* Order Acknowledgment Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderAcknowledgmentMessage ==
    { ZeroOrderAcknowledgmentMessage }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.transactTime = one]) : one \in Sample(8) }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.clOrdId = one]) : one \in Sample(20) }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.orderId = one]) : one \in Sample(8) }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.reserved1 = one]) : one \in Sample(1) }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 7, !.returnBitfield7 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 9, !.returnBitfield9 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 10, !.returnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 11, !.returnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 13, !.returnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 14, !.returnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 15, !.returnBitfield15 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 17, !.returnBitfield17 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<1>>, !.side = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<4>>, !.priceLong = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<8>>, !.execInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<128>>, !.maxRemovePct = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<1>>, !.symbolLong = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<1>>, !.account = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<2>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<4>>, !.clearingAccount = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<8>>, !.displayIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<16>>, !.maxFloor = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<64>>, !.orderQtyLong = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<128>>, !.preventMatch = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<1>>, !.maturityDate = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<2>>, !.strikePrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<4>>, !.putOrCall = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<8>>, !.openClose = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<32>>, !.correctedSize = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<1>>, !.origClOrdId = one]) : one \in { <<held>> : held \in Sample(20) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<2>>, !.leavesQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<4>>, !.lastShares = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<8>>, !.lastPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<16>>, !.displayPrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<32>>, !.workingPrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<64>>, !.baseLiquidityIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<128>>, !.expireTime = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = <<1>>, !.secondaryOrderId = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = <<4>>, !.contraCapacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = <<8>>, !.attributedQuote = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 7, !.returnBitfield7 = <<1>>, !.subLiquidityIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<2>>, !.echoText = one]) : one \in { <<held>> : held \in Sample(64) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<4>>, !.stopPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<8>>, !.routingInst = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<16>>, !.routStrategy = one]) : one \in { <<held>> : held \in Sample(6) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<32>>, !.routeDeliveryMethod = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<64>>, !.exDestination = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 9, !.returnBitfield9 = <<32>>, !.cmtaNumber = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = <<128>>, !.clearingOptionalData = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 15, !.returnBitfield15 = <<128>>, !.clientIdAttr = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = <<2>>, !.sessionEligibility = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = <<32>>, !.floorRoutingInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = <<128>>, !.orderOrigin = one]) : one \in { <<held>> : held \in Sample(3) } }

(***************************************************************************)
(* Quote Result Group: 16 bytes                                            *)
(***************************************************************************)

QuoteResultGroup ==
    [ orderId                 : Sample(8),
      quoteResult             : Sample(1),
      quoteLiquidityIndicator : Sample(1),
      reserved6               : Sample(6) ]

EncodeQuoteResultGroup(message) ==
    message.orderId
        \o message.quoteResult
        \o message.quoteLiquidityIndicator
        \o message.reserved6

DecodeQuoteResultGroup(bytes) ==
    LET orderId == ReadBytes(bytes, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET quoteResult == ReadBytes(orderId.rest, 1) IN IF ~quoteResult.ok THEN Fail ELSE
    LET quoteLiquidityIndicator == ReadBytes(quoteResult.rest, 1) IN IF ~quoteLiquidityIndicator.ok THEN Fail ELSE
    LET reserved6 == ReadBytes(quoteLiquidityIndicator.rest, 6) IN IF ~reserved6.ok THEN Fail ELSE
    Ok([ orderId                 |-> orderId.value,
         quoteResult             |-> quoteResult.value,
         quoteLiquidityIndicator |-> quoteLiquidityIndicator.value,
         reserved6               |-> reserved6.value ], reserved6.rest)

ZeroQuoteResultGroup ==
    [ orderId                 |-> [i \in 1 .. 8 |-> 0],
      quoteResult             |-> [i \in 1 .. 1 |-> 0],
      quoteLiquidityIndicator |-> [i \in 1 .. 1 |-> 0],
      reserved6               |-> [i \in 1 .. 6 |-> 0] ]

(* Quote Result Group at zero, then each field in turn at the values it is checked at *)
CheckedQuoteResultGroup ==
    { ZeroQuoteResultGroup }
        \cup { [ZeroQuoteResultGroup EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteResultGroup EXCEPT !.quoteResult = one] : one \in Sample(1) }
        \cup { [ZeroQuoteResultGroup EXCEPT !.quoteLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroQuoteResultGroup EXCEPT !.reserved6 = one] : one \in Sample(6) }

(* A run of Quote Result Group, written one after another *)
RECURSIVE EncodeQuoteResultGroupList(_)
EncodeQuoteResultGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeQuoteResultGroup(Head(messages)) \o EncodeQuoteResultGroupList(Tail(messages))

(* As many Quote Result Group as the field that counts them says *)
RECURSIVE ReadQuoteResultGroupList(_, _)
ReadQuoteResultGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeQuoteResultGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadQuoteResultGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Quote Result Group of each kind, for the lists that carry them *)
OneQuoteResultGroup == { ZeroQuoteResultGroup }

(***************************************************************************)
(* Quote Update Acknowledgment Message                                     *)
(***************************************************************************)

QuoteUpdateAcknowledgmentMessage ==
    [ transactionTime   : Sample(8),
      quoteUpdateId     : Sample(16),
      quoteRejectReason : Sample(1),
      reserved17        : Sample(17),
      quoteResultGroup  : SampleLists(OneQuoteResultGroup) ]

EncodeQuoteUpdateAcknowledgmentMessage(message) ==
    message.transactionTime
        \o message.quoteUpdateId
        \o message.quoteRejectReason
        \o message.reserved17
        \o EncodeUIntBE(Len(message.quoteResultGroup), 1)
        \o EncodeQuoteResultGroupList(message.quoteResultGroup)

DecodeQuoteUpdateAcknowledgmentMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET quoteUpdateId == ReadBytes(transactionTime.rest, 16) IN IF ~quoteUpdateId.ok THEN Fail ELSE
    LET quoteRejectReason == ReadBytes(quoteUpdateId.rest, 1) IN IF ~quoteRejectReason.ok THEN Fail ELSE
    LET reserved17 == ReadBytes(quoteRejectReason.rest, 17) IN IF ~reserved17.ok THEN Fail ELSE
    LET numberOfQuoteResults == ReadUIntBE(reserved17.rest, 1) IN IF ~numberOfQuoteResults.ok THEN Fail ELSE
    LET quoteResultGroup == ReadQuoteResultGroupList(numberOfQuoteResults.rest, numberOfQuoteResults.value) IN IF ~quoteResultGroup.ok THEN Fail ELSE
    Ok([ transactionTime   |-> transactionTime.value,
         quoteUpdateId     |-> quoteUpdateId.value,
         quoteRejectReason |-> quoteRejectReason.value,
         reserved17        |-> reserved17.value,
         quoteResultGroup  |-> quoteResultGroup.value ], quoteResultGroup.rest)

ZeroQuoteUpdateAcknowledgmentMessage ==
    [ transactionTime   |-> [i \in 1 .. 8 |-> 0],
      quoteUpdateId     |-> [i \in 1 .. 16 |-> 0],
      quoteRejectReason |-> [i \in 1 .. 1 |-> 0],
      reserved17        |-> [i \in 1 .. 17 |-> 0],
      quoteResultGroup  |-> << >> ]

(* Quote Update Acknowledgment Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteUpdateAcknowledgmentMessage ==
    { ZeroQuoteUpdateAcknowledgmentMessage }
        \cup { [ZeroQuoteUpdateAcknowledgmentMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroQuoteUpdateAcknowledgmentMessage EXCEPT !.quoteUpdateId = one] : one \in Sample(16) }
        \cup { [ZeroQuoteUpdateAcknowledgmentMessage EXCEPT !.quoteRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroQuoteUpdateAcknowledgmentMessage EXCEPT !.reserved17 = one] : one \in Sample(17) }
        \cup { [ZeroQuoteUpdateAcknowledgmentMessage EXCEPT !.quoteResultGroup = one] : one \in SampleLists(OneQuoteResultGroup) }

(***************************************************************************)
(* Order Rejected Message                                                  *)
(***************************************************************************)

OrderRejectedMessage ==
    [ transactionTime         : Sample(8),
      clOrdId                 : Sample(20),
      orderRejectReason       : Sample(1),
      text                    : Sample(60),
      reserved1               : Sample(1),
      numberOfReturnBitfields : 0 .. 255,
      returnBitfield1         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield2         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield3         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield4         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield5         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield6         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield7         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield8         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield9         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield10        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield11        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield12        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield13        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield14        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield15        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield16        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield17        : { << >> } \cup { <<held>> : held \in Sample(1) },
      side                    : { << >> } \cup { <<held>> : held \in Sample(1) },
      priceLong               : { << >> } \cup { <<held>> : held \in Sample(8) },
      execInst                : { << >> } \cup { <<held>> : held \in Sample(1) },
      ordType                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce             : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                  : { << >> } \cup { <<held>> : held \in Sample(4) },
      maxRemovePct            : { << >> } \cup { <<held>> : held \in Sample(1) },
      symbolLong              : { << >> } \cup { <<held>> : held \in Sample(8) },
      capacity                : { << >> } \cup { <<held>> : held \in Sample(1) },
      account                 : { << >> } \cup { <<held>> : held \in Sample(16) },
      clearingFirm            : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingAccount         : { << >> } \cup { <<held>> : held \in Sample(4) },
      displayIndicator        : { << >> } \cup { <<held>> : held \in Sample(1) },
      maxFloor                : { << >> } \cup { <<held>> : held \in Sample(4) },
      orderQtyLong            : { << >> } \cup { <<held>> : held \in Sample(4) },
      preventMatch            : { << >> } \cup { <<held>> : held \in Sample(3) },
      maturityDate            : { << >> } \cup { <<held>> : held \in Sample(4) },
      strikePrice             : { << >> } \cup { <<held>> : held \in Sample(8) },
      putOrCall               : { << >> } \cup { <<held>> : held \in Sample(1) },
      openClose               : { << >> } \cup { <<held>> : held \in Sample(1) },
      correctedSize           : { << >> } \cup { <<held>> : held \in Sample(4) },
      secondaryOrderId        : { << >> } \cup { <<held>> : held \in Sample(8) },
      contraCapacity          : { << >> } \cup { <<held>> : held \in Sample(1) },
      attributedQuote         : { << >> } \cup { <<held>> : held \in Sample(1) },
      echoText                : { << >> } \cup { <<held>> : held \in Sample(64) },
      stopPx                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      routingInst             : { << >> } \cup { <<held>> : held \in Sample(4) },
      routStrategy            : { << >> } \cup { <<held>> : held \in Sample(6) },
      routeDeliveryMethod     : { << >> } \cup { <<held>> : held \in Sample(3) },
      exDestination           : { << >> } \cup { <<held>> : held \in Sample(1) },
      cmtaNumber              : { << >> } \cup { <<held>> : held \in Sample(4) },
      clientIdAttr            : { << >> } \cup { <<held>> : held \in Sample(4) },
      sessionEligibility      : { << >> } \cup { <<held>> : held \in Sample(1) },
      floorRoutingInst        : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderOrigin             : { << >> } \cup { <<held>> : held \in Sample(3) } ]

EncodeOrderRejectedMessage(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.orderRejectReason
        \o message.text
        \o message.reserved1
        \o EncodeUIntBE(message.numberOfReturnBitfields, 1)
        \o (IF message.returnBitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield1[1], 1))
        \o (IF message.returnBitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield2[1], 1))
        \o (IF message.returnBitfield3 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield3[1], 1))
        \o (IF message.returnBitfield4 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield4[1], 1))
        \o (IF message.returnBitfield5 = << >> THEN << >> ELSE message.returnBitfield5[1])
        \o (IF message.returnBitfield6 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield6[1], 1))
        \o (IF message.returnBitfield7 = << >> THEN << >> ELSE message.returnBitfield7[1])
        \o (IF message.returnBitfield8 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield8[1], 1))
        \o (IF message.returnBitfield9 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield9[1], 1))
        \o (IF message.returnBitfield10 = << >> THEN << >> ELSE message.returnBitfield10[1])
        \o (IF message.returnBitfield11 = << >> THEN << >> ELSE message.returnBitfield11[1])
        \o (IF message.returnBitfield12 = << >> THEN << >> ELSE message.returnBitfield12[1])
        \o (IF message.returnBitfield13 = << >> THEN << >> ELSE message.returnBitfield13[1])
        \o (IF message.returnBitfield14 = << >> THEN << >> ELSE message.returnBitfield14[1])
        \o (IF message.returnBitfield15 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield15[1], 1))
        \o (IF message.returnBitfield16 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield16[1], 1))
        \o (IF message.returnBitfield17 = << >> THEN << >> ELSE message.returnBitfield17[1])
        \o (IF message.side = << >> THEN << >> ELSE message.side[1])
        \o (IF message.priceLong = << >> THEN << >> ELSE message.priceLong[1])
        \o (IF message.execInst = << >> THEN << >> ELSE message.execInst[1])
        \o (IF message.ordType = << >> THEN << >> ELSE message.ordType[1])
        \o (IF message.timeInForce = << >> THEN << >> ELSE message.timeInForce[1])
        \o (IF message.minQty = << >> THEN << >> ELSE message.minQty[1])
        \o (IF message.maxRemovePct = << >> THEN << >> ELSE message.maxRemovePct[1])
        \o (IF message.symbolLong = << >> THEN << >> ELSE message.symbolLong[1])
        \o (IF message.capacity = << >> THEN << >> ELSE message.capacity[1])
        \o (IF message.account = << >> THEN << >> ELSE message.account[1])
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])
        \o (IF message.clearingAccount = << >> THEN << >> ELSE message.clearingAccount[1])
        \o (IF message.displayIndicator = << >> THEN << >> ELSE message.displayIndicator[1])
        \o (IF message.maxFloor = << >> THEN << >> ELSE message.maxFloor[1])
        \o (IF message.orderQtyLong = << >> THEN << >> ELSE message.orderQtyLong[1])
        \o (IF message.preventMatch = << >> THEN << >> ELSE message.preventMatch[1])
        \o (IF message.maturityDate = << >> THEN << >> ELSE message.maturityDate[1])
        \o (IF message.strikePrice = << >> THEN << >> ELSE message.strikePrice[1])
        \o (IF message.putOrCall = << >> THEN << >> ELSE message.putOrCall[1])
        \o (IF message.openClose = << >> THEN << >> ELSE message.openClose[1])
        \o (IF message.correctedSize = << >> THEN << >> ELSE message.correctedSize[1])
        \o (IF message.secondaryOrderId = << >> THEN << >> ELSE message.secondaryOrderId[1])
        \o (IF message.contraCapacity = << >> THEN << >> ELSE message.contraCapacity[1])
        \o (IF message.attributedQuote = << >> THEN << >> ELSE message.attributedQuote[1])
        \o (IF message.echoText = << >> THEN << >> ELSE message.echoText[1])
        \o (IF message.stopPx = << >> THEN << >> ELSE message.stopPx[1])
        \o (IF message.routingInst = << >> THEN << >> ELSE message.routingInst[1])
        \o (IF message.routStrategy = << >> THEN << >> ELSE message.routStrategy[1])
        \o (IF message.routeDeliveryMethod = << >> THEN << >> ELSE message.routeDeliveryMethod[1])
        \o (IF message.exDestination = << >> THEN << >> ELSE message.exDestination[1])
        \o (IF message.cmtaNumber = << >> THEN << >> ELSE message.cmtaNumber[1])
        \o (IF message.clientIdAttr = << >> THEN << >> ELSE message.clientIdAttr[1])
        \o (IF message.sessionEligibility = << >> THEN << >> ELSE message.sessionEligibility[1])
        \o (IF message.floorRoutingInst = << >> THEN << >> ELSE message.floorRoutingInst[1])
        \o (IF message.orderOrigin = << >> THEN << >> ELSE message.orderOrigin[1])

DecodeOrderRejectedMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET orderRejectReason == ReadBytes(clOrdId.rest, 1) IN IF ~orderRejectReason.ok THEN Fail ELSE
    LET text == ReadBytes(orderRejectReason.rest, 60) IN IF ~text.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(text.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET numberOfReturnBitfields == ReadUIntBE(reserved1.rest, 1) IN IF ~numberOfReturnBitfields.ok THEN Fail ELSE
    LET returnBitfield1 == ReadWhen(numberOfReturnBitfields.value >= 1, ReadUIntLE(numberOfReturnBitfields.rest, 1), numberOfReturnBitfields.rest) IN IF ~returnBitfield1.ok THEN Fail ELSE
    LET returnBitfield2 == ReadWhen(numberOfReturnBitfields.value >= 2, ReadUIntLE(returnBitfield1.rest, 1), returnBitfield1.rest) IN IF ~returnBitfield2.ok THEN Fail ELSE
    LET returnBitfield3 == ReadWhen(numberOfReturnBitfields.value >= 3, ReadUIntLE(returnBitfield2.rest, 1), returnBitfield2.rest) IN IF ~returnBitfield3.ok THEN Fail ELSE
    LET returnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadUIntLE(returnBitfield3.rest, 1), returnBitfield3.rest) IN IF ~returnBitfield4.ok THEN Fail ELSE
    LET returnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadBytes(returnBitfield4.rest, 1), returnBitfield4.rest) IN IF ~returnBitfield5.ok THEN Fail ELSE
    LET returnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadUIntLE(returnBitfield5.rest, 1), returnBitfield5.rest) IN IF ~returnBitfield6.ok THEN Fail ELSE
    LET returnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadBytes(returnBitfield6.rest, 1), returnBitfield6.rest) IN IF ~returnBitfield7.ok THEN Fail ELSE
    LET returnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadUIntLE(returnBitfield7.rest, 1), returnBitfield7.rest) IN IF ~returnBitfield8.ok THEN Fail ELSE
    LET returnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadUIntLE(returnBitfield8.rest, 1), returnBitfield8.rest) IN IF ~returnBitfield9.ok THEN Fail ELSE
    LET returnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadBytes(returnBitfield9.rest, 1), returnBitfield9.rest) IN IF ~returnBitfield10.ok THEN Fail ELSE
    LET returnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadBytes(returnBitfield10.rest, 1), returnBitfield10.rest) IN IF ~returnBitfield11.ok THEN Fail ELSE
    LET returnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadBytes(returnBitfield11.rest, 1), returnBitfield11.rest) IN IF ~returnBitfield12.ok THEN Fail ELSE
    LET returnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(returnBitfield12.rest, 1), returnBitfield12.rest) IN IF ~returnBitfield13.ok THEN Fail ELSE
    LET returnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(returnBitfield13.rest, 1), returnBitfield13.rest) IN IF ~returnBitfield14.ok THEN Fail ELSE
    LET returnBitfield15 == ReadWhen(numberOfReturnBitfields.value >= 15, ReadUIntLE(returnBitfield14.rest, 1), returnBitfield14.rest) IN IF ~returnBitfield15.ok THEN Fail ELSE
    LET returnBitfield16 == ReadWhen(numberOfReturnBitfields.value >= 16, ReadUIntLE(returnBitfield15.rest, 1), returnBitfield15.rest) IN IF ~returnBitfield16.ok THEN Fail ELSE
    LET returnBitfield17 == ReadWhen(numberOfReturnBitfields.value >= 17, ReadBytes(returnBitfield16.rest, 1), returnBitfield16.rest) IN IF ~returnBitfield17.ok THEN Fail ELSE
    LET side == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ returnBitfield1.value[1] % 2 > 0), ReadBytes(returnBitfield17.rest, 1), returnBitfield17.rest) IN IF ~side.ok THEN Fail ELSE
    LET priceLong == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(side.rest, 8), side.rest) IN IF ~priceLong.ok THEN Fail ELSE
    LET execInst == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 8) % 2 > 0), ReadBytes(priceLong.rest, 1), priceLong.rest) IN IF ~execInst.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(execInst.rest, 1), execInst.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET maxRemovePct == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 128) % 2 > 0), ReadBytes(minQty.rest, 1), minQty.rest) IN IF ~maxRemovePct.ok THEN Fail ELSE
    LET symbolLong == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ returnBitfield2.value[1] % 2 > 0), ReadBytes(maxRemovePct.rest, 8), maxRemovePct.rest) IN IF ~symbolLong.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ (returnBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(symbolLong.rest, 1), symbolLong.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ returnBitfield3.value[1] % 2 > 0), ReadBytes(capacity.rest, 16), capacity.rest) IN IF ~account.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 2) % 2 > 0), ReadBytes(account.rest, 4), account.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 4) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET displayIndicator == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 8) % 2 > 0), ReadBytes(clearingAccount.rest, 1), clearingAccount.rest) IN IF ~displayIndicator.ok THEN Fail ELSE
    LET maxFloor == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 16) % 2 > 0), ReadBytes(displayIndicator.rest, 4), displayIndicator.rest) IN IF ~maxFloor.ok THEN Fail ELSE
    LET orderQtyLong == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 64) % 2 > 0), ReadBytes(maxFloor.rest, 4), maxFloor.rest) IN IF ~orderQtyLong.ok THEN Fail ELSE
    LET preventMatch == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 128) % 2 > 0), ReadBytes(orderQtyLong.rest, 3), orderQtyLong.rest) IN IF ~preventMatch.ok THEN Fail ELSE
    LET maturityDate == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ returnBitfield4.value[1] % 2 > 0), ReadBytes(preventMatch.rest, 4), preventMatch.rest) IN IF ~maturityDate.ok THEN Fail ELSE
    LET strikePrice == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ (returnBitfield4.value[1] \div 2) % 2 > 0), ReadBytes(maturityDate.rest, 8), maturityDate.rest) IN IF ~strikePrice.ok THEN Fail ELSE
    LET putOrCall == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ (returnBitfield4.value[1] \div 4) % 2 > 0), ReadBytes(strikePrice.rest, 1), strikePrice.rest) IN IF ~putOrCall.ok THEN Fail ELSE
    LET openClose == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ (returnBitfield4.value[1] \div 8) % 2 > 0), ReadBytes(putOrCall.rest, 1), putOrCall.rest) IN IF ~openClose.ok THEN Fail ELSE
    LET correctedSize == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ (returnBitfield4.value[1] \div 32) % 2 > 0), ReadBytes(openClose.rest, 4), openClose.rest) IN IF ~correctedSize.ok THEN Fail ELSE
    LET secondaryOrderId == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (returnBitfield6.value # << >> /\ returnBitfield6.value[1] % 2 > 0), ReadBytes(correctedSize.rest, 8), correctedSize.rest) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET contraCapacity == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (returnBitfield6.value # << >> /\ (returnBitfield6.value[1] \div 4) % 2 > 0), ReadBytes(secondaryOrderId.rest, 1), secondaryOrderId.rest) IN IF ~contraCapacity.ok THEN Fail ELSE
    LET attributedQuote == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (returnBitfield6.value # << >> /\ (returnBitfield6.value[1] \div 8) % 2 > 0), ReadBytes(contraCapacity.rest, 1), contraCapacity.rest) IN IF ~attributedQuote.ok THEN Fail ELSE
    LET echoText == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 2) % 2 > 0), ReadBytes(attributedQuote.rest, 64), attributedQuote.rest) IN IF ~echoText.ok THEN Fail ELSE
    LET stopPx == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 4) % 2 > 0), ReadBytes(echoText.rest, 8), echoText.rest) IN IF ~stopPx.ok THEN Fail ELSE
    LET routingInst == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 8) % 2 > 0), ReadBytes(stopPx.rest, 4), stopPx.rest) IN IF ~routingInst.ok THEN Fail ELSE
    LET routStrategy == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 16) % 2 > 0), ReadBytes(routingInst.rest, 6), routingInst.rest) IN IF ~routStrategy.ok THEN Fail ELSE
    LET routeDeliveryMethod == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 32) % 2 > 0), ReadBytes(routStrategy.rest, 3), routStrategy.rest) IN IF ~routeDeliveryMethod.ok THEN Fail ELSE
    LET exDestination == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 64) % 2 > 0), ReadBytes(routeDeliveryMethod.rest, 1), routeDeliveryMethod.rest) IN IF ~exDestination.ok THEN Fail ELSE
    LET cmtaNumber == ReadWhen(numberOfReturnBitfields.value >= 9 /\ (returnBitfield9.value # << >> /\ (returnBitfield9.value[1] \div 32) % 2 > 0), ReadBytes(exDestination.rest, 4), exDestination.rest) IN IF ~cmtaNumber.ok THEN Fail ELSE
    LET clientIdAttr == ReadWhen(numberOfReturnBitfields.value >= 15 /\ (returnBitfield15.value # << >> /\ (returnBitfield15.value[1] \div 128) % 2 > 0), ReadBytes(cmtaNumber.rest, 4), cmtaNumber.rest) IN IF ~clientIdAttr.ok THEN Fail ELSE
    LET sessionEligibility == ReadWhen(numberOfReturnBitfields.value >= 16 /\ (returnBitfield16.value # << >> /\ (returnBitfield16.value[1] \div 2) % 2 > 0), ReadBytes(clientIdAttr.rest, 1), clientIdAttr.rest) IN IF ~sessionEligibility.ok THEN Fail ELSE
    LET floorRoutingInst == ReadWhen(numberOfReturnBitfields.value >= 16 /\ (returnBitfield16.value # << >> /\ (returnBitfield16.value[1] \div 32) % 2 > 0), ReadBytes(sessionEligibility.rest, 1), sessionEligibility.rest) IN IF ~floorRoutingInst.ok THEN Fail ELSE
    LET orderOrigin == ReadWhen(numberOfReturnBitfields.value >= 16 /\ (returnBitfield16.value # << >> /\ (returnBitfield16.value[1] \div 128) % 2 > 0), ReadBytes(floorRoutingInst.rest, 3), floorRoutingInst.rest) IN IF ~orderOrigin.ok THEN Fail ELSE
    Ok([ transactionTime         |-> transactionTime.value,
         clOrdId                 |-> clOrdId.value,
         orderRejectReason       |-> orderRejectReason.value,
         text                    |-> text.value,
         reserved1               |-> reserved1.value,
         numberOfReturnBitfields |-> numberOfReturnBitfields.value,
         returnBitfield1         |-> returnBitfield1.value,
         returnBitfield2         |-> returnBitfield2.value,
         returnBitfield3         |-> returnBitfield3.value,
         returnBitfield4         |-> returnBitfield4.value,
         returnBitfield5         |-> returnBitfield5.value,
         returnBitfield6         |-> returnBitfield6.value,
         returnBitfield7         |-> returnBitfield7.value,
         returnBitfield8         |-> returnBitfield8.value,
         returnBitfield9         |-> returnBitfield9.value,
         returnBitfield10        |-> returnBitfield10.value,
         returnBitfield11        |-> returnBitfield11.value,
         returnBitfield12        |-> returnBitfield12.value,
         returnBitfield13        |-> returnBitfield13.value,
         returnBitfield14        |-> returnBitfield14.value,
         returnBitfield15        |-> returnBitfield15.value,
         returnBitfield16        |-> returnBitfield16.value,
         returnBitfield17        |-> returnBitfield17.value,
         side                    |-> side.value,
         priceLong               |-> priceLong.value,
         execInst                |-> execInst.value,
         ordType                 |-> ordType.value,
         timeInForce             |-> timeInForce.value,
         minQty                  |-> minQty.value,
         maxRemovePct            |-> maxRemovePct.value,
         symbolLong              |-> symbolLong.value,
         capacity                |-> capacity.value,
         account                 |-> account.value,
         clearingFirm            |-> clearingFirm.value,
         clearingAccount         |-> clearingAccount.value,
         displayIndicator        |-> displayIndicator.value,
         maxFloor                |-> maxFloor.value,
         orderQtyLong            |-> orderQtyLong.value,
         preventMatch            |-> preventMatch.value,
         maturityDate            |-> maturityDate.value,
         strikePrice             |-> strikePrice.value,
         putOrCall               |-> putOrCall.value,
         openClose               |-> openClose.value,
         correctedSize           |-> correctedSize.value,
         secondaryOrderId        |-> secondaryOrderId.value,
         contraCapacity          |-> contraCapacity.value,
         attributedQuote         |-> attributedQuote.value,
         echoText                |-> echoText.value,
         stopPx                  |-> stopPx.value,
         routingInst             |-> routingInst.value,
         routStrategy            |-> routStrategy.value,
         routeDeliveryMethod     |-> routeDeliveryMethod.value,
         exDestination           |-> exDestination.value,
         cmtaNumber              |-> cmtaNumber.value,
         clientIdAttr            |-> clientIdAttr.value,
         sessionEligibility      |-> sessionEligibility.value,
         floorRoutingInst        |-> floorRoutingInst.value,
         orderOrigin             |-> orderOrigin.value ], orderOrigin.rest)

(* Order Rejected Message with each field marked present by fields before it there exactly where they say *)
SettleOrderRejectedMessage(message) ==
    LET settled1 == [message EXCEPT !.returnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.returnBitfield1 = << >> THEN <<0>> ELSE message.returnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.returnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.returnBitfield2 = << >> THEN <<0>> ELSE settled1.returnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.returnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.returnBitfield3 = << >> THEN <<0>> ELSE settled2.returnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.returnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.returnBitfield4 = << >> THEN <<0>> ELSE settled3.returnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.returnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.returnBitfield5 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled4.returnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.returnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.returnBitfield6 = << >> THEN <<0>> ELSE settled5.returnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.returnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.returnBitfield7 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.returnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.returnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.returnBitfield8 = << >> THEN <<0>> ELSE settled7.returnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.returnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.returnBitfield9 = << >> THEN <<0>> ELSE settled8.returnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.returnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.returnBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.returnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.returnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.returnBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.returnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.returnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.returnBitfield12 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.returnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.returnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.returnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.returnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.returnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.returnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.returnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.returnBitfield15 = IF settled14.numberOfReturnBitfields >= 15 THEN (IF settled14.returnBitfield15 = << >> THEN <<0>> ELSE settled14.returnBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.returnBitfield16 = IF settled15.numberOfReturnBitfields >= 16 THEN (IF settled15.returnBitfield16 = << >> THEN <<0>> ELSE settled15.returnBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.returnBitfield17 = IF settled16.numberOfReturnBitfields >= 17 THEN (IF settled16.returnBitfield17 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled16.returnBitfield17) ELSE << >>]
        settled18 == [settled17 EXCEPT !.side = IF settled17.numberOfReturnBitfields >= 1 /\ (settled17.returnBitfield1 # << >> /\ settled17.returnBitfield1[1] % 2 > 0) THEN (IF settled17.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.side) ELSE << >>]
        settled19 == [settled18 EXCEPT !.priceLong = IF settled18.numberOfReturnBitfields >= 1 /\ (settled18.returnBitfield1 # << >> /\ (settled18.returnBitfield1[1] \div 4) % 2 > 0) THEN (IF settled18.priceLong = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled18.priceLong) ELSE << >>]
        settled20 == [settled19 EXCEPT !.execInst = IF settled19.numberOfReturnBitfields >= 1 /\ (settled19.returnBitfield1 # << >> /\ (settled19.returnBitfield1[1] \div 8) % 2 > 0) THEN (IF settled19.execInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled19.execInst) ELSE << >>]
        settled21 == [settled20 EXCEPT !.ordType = IF settled20.numberOfReturnBitfields >= 1 /\ (settled20.returnBitfield1 # << >> /\ (settled20.returnBitfield1[1] \div 16) % 2 > 0) THEN (IF settled20.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled20.ordType) ELSE << >>]
        settled22 == [settled21 EXCEPT !.timeInForce = IF settled21.numberOfReturnBitfields >= 1 /\ (settled21.returnBitfield1 # << >> /\ (settled21.returnBitfield1[1] \div 32) % 2 > 0) THEN (IF settled21.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled21.timeInForce) ELSE << >>]
        settled23 == [settled22 EXCEPT !.minQty = IF settled22.numberOfReturnBitfields >= 1 /\ (settled22.returnBitfield1 # << >> /\ (settled22.returnBitfield1[1] \div 64) % 2 > 0) THEN (IF settled22.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled22.minQty) ELSE << >>]
        settled24 == [settled23 EXCEPT !.maxRemovePct = IF settled23.numberOfReturnBitfields >= 1 /\ (settled23.returnBitfield1 # << >> /\ (settled23.returnBitfield1[1] \div 128) % 2 > 0) THEN (IF settled23.maxRemovePct = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled23.maxRemovePct) ELSE << >>]
        settled25 == [settled24 EXCEPT !.symbolLong = IF settled24.numberOfReturnBitfields >= 2 /\ (settled24.returnBitfield2 # << >> /\ settled24.returnBitfield2[1] % 2 > 0) THEN (IF settled24.symbolLong = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled24.symbolLong) ELSE << >>]
        settled26 == [settled25 EXCEPT !.capacity = IF settled25.numberOfReturnBitfields >= 2 /\ (settled25.returnBitfield2 # << >> /\ (settled25.returnBitfield2[1] \div 64) % 2 > 0) THEN (IF settled25.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled25.capacity) ELSE << >>]
        settled27 == [settled26 EXCEPT !.account = IF settled26.numberOfReturnBitfields >= 3 /\ (settled26.returnBitfield3 # << >> /\ settled26.returnBitfield3[1] % 2 > 0) THEN (IF settled26.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled26.account) ELSE << >>]
        settled28 == [settled27 EXCEPT !.clearingFirm = IF settled27.numberOfReturnBitfields >= 3 /\ (settled27.returnBitfield3 # << >> /\ (settled27.returnBitfield3[1] \div 2) % 2 > 0) THEN (IF settled27.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled27.clearingFirm) ELSE << >>]
        settled29 == [settled28 EXCEPT !.clearingAccount = IF settled28.numberOfReturnBitfields >= 3 /\ (settled28.returnBitfield3 # << >> /\ (settled28.returnBitfield3[1] \div 4) % 2 > 0) THEN (IF settled28.clearingAccount = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled28.clearingAccount) ELSE << >>]
        settled30 == [settled29 EXCEPT !.displayIndicator = IF settled29.numberOfReturnBitfields >= 3 /\ (settled29.returnBitfield3 # << >> /\ (settled29.returnBitfield3[1] \div 8) % 2 > 0) THEN (IF settled29.displayIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled29.displayIndicator) ELSE << >>]
        settled31 == [settled30 EXCEPT !.maxFloor = IF settled30.numberOfReturnBitfields >= 3 /\ (settled30.returnBitfield3 # << >> /\ (settled30.returnBitfield3[1] \div 16) % 2 > 0) THEN (IF settled30.maxFloor = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled30.maxFloor) ELSE << >>]
        settled32 == [settled31 EXCEPT !.orderQtyLong = IF settled31.numberOfReturnBitfields >= 3 /\ (settled31.returnBitfield3 # << >> /\ (settled31.returnBitfield3[1] \div 64) % 2 > 0) THEN (IF settled31.orderQtyLong = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled31.orderQtyLong) ELSE << >>]
        settled33 == [settled32 EXCEPT !.preventMatch = IF settled32.numberOfReturnBitfields >= 3 /\ (settled32.returnBitfield3 # << >> /\ (settled32.returnBitfield3[1] \div 128) % 2 > 0) THEN (IF settled32.preventMatch = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled32.preventMatch) ELSE << >>]
        settled34 == [settled33 EXCEPT !.maturityDate = IF settled33.numberOfReturnBitfields >= 4 /\ (settled33.returnBitfield4 # << >> /\ settled33.returnBitfield4[1] % 2 > 0) THEN (IF settled33.maturityDate = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled33.maturityDate) ELSE << >>]
        settled35 == [settled34 EXCEPT !.strikePrice = IF settled34.numberOfReturnBitfields >= 4 /\ (settled34.returnBitfield4 # << >> /\ (settled34.returnBitfield4[1] \div 2) % 2 > 0) THEN (IF settled34.strikePrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled34.strikePrice) ELSE << >>]
        settled36 == [settled35 EXCEPT !.putOrCall = IF settled35.numberOfReturnBitfields >= 4 /\ (settled35.returnBitfield4 # << >> /\ (settled35.returnBitfield4[1] \div 4) % 2 > 0) THEN (IF settled35.putOrCall = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled35.putOrCall) ELSE << >>]
        settled37 == [settled36 EXCEPT !.openClose = IF settled36.numberOfReturnBitfields >= 4 /\ (settled36.returnBitfield4 # << >> /\ (settled36.returnBitfield4[1] \div 8) % 2 > 0) THEN (IF settled36.openClose = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled36.openClose) ELSE << >>]
        settled38 == [settled37 EXCEPT !.correctedSize = IF settled37.numberOfReturnBitfields >= 4 /\ (settled37.returnBitfield4 # << >> /\ (settled37.returnBitfield4[1] \div 32) % 2 > 0) THEN (IF settled37.correctedSize = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled37.correctedSize) ELSE << >>]
        settled39 == [settled38 EXCEPT !.secondaryOrderId = IF settled38.numberOfReturnBitfields >= 6 /\ (settled38.returnBitfield6 # << >> /\ settled38.returnBitfield6[1] % 2 > 0) THEN (IF settled38.secondaryOrderId = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled38.secondaryOrderId) ELSE << >>]
        settled40 == [settled39 EXCEPT !.contraCapacity = IF settled39.numberOfReturnBitfields >= 6 /\ (settled39.returnBitfield6 # << >> /\ (settled39.returnBitfield6[1] \div 4) % 2 > 0) THEN (IF settled39.contraCapacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled39.contraCapacity) ELSE << >>]
        settled41 == [settled40 EXCEPT !.attributedQuote = IF settled40.numberOfReturnBitfields >= 6 /\ (settled40.returnBitfield6 # << >> /\ (settled40.returnBitfield6[1] \div 8) % 2 > 0) THEN (IF settled40.attributedQuote = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled40.attributedQuote) ELSE << >>]
        settled42 == [settled41 EXCEPT !.echoText = IF settled41.numberOfReturnBitfields >= 8 /\ (settled41.returnBitfield8 # << >> /\ (settled41.returnBitfield8[1] \div 2) % 2 > 0) THEN (IF settled41.echoText = << >> THEN <<[i \in 1 .. 64 |-> 0]>> ELSE settled41.echoText) ELSE << >>]
        settled43 == [settled42 EXCEPT !.stopPx = IF settled42.numberOfReturnBitfields >= 8 /\ (settled42.returnBitfield8 # << >> /\ (settled42.returnBitfield8[1] \div 4) % 2 > 0) THEN (IF settled42.stopPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled42.stopPx) ELSE << >>]
        settled44 == [settled43 EXCEPT !.routingInst = IF settled43.numberOfReturnBitfields >= 8 /\ (settled43.returnBitfield8 # << >> /\ (settled43.returnBitfield8[1] \div 8) % 2 > 0) THEN (IF settled43.routingInst = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled43.routingInst) ELSE << >>]
        settled45 == [settled44 EXCEPT !.routStrategy = IF settled44.numberOfReturnBitfields >= 8 /\ (settled44.returnBitfield8 # << >> /\ (settled44.returnBitfield8[1] \div 16) % 2 > 0) THEN (IF settled44.routStrategy = << >> THEN <<[i \in 1 .. 6 |-> 0]>> ELSE settled44.routStrategy) ELSE << >>]
        settled46 == [settled45 EXCEPT !.routeDeliveryMethod = IF settled45.numberOfReturnBitfields >= 8 /\ (settled45.returnBitfield8 # << >> /\ (settled45.returnBitfield8[1] \div 32) % 2 > 0) THEN (IF settled45.routeDeliveryMethod = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled45.routeDeliveryMethod) ELSE << >>]
        settled47 == [settled46 EXCEPT !.exDestination = IF settled46.numberOfReturnBitfields >= 8 /\ (settled46.returnBitfield8 # << >> /\ (settled46.returnBitfield8[1] \div 64) % 2 > 0) THEN (IF settled46.exDestination = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled46.exDestination) ELSE << >>]
        settled48 == [settled47 EXCEPT !.cmtaNumber = IF settled47.numberOfReturnBitfields >= 9 /\ (settled47.returnBitfield9 # << >> /\ (settled47.returnBitfield9[1] \div 32) % 2 > 0) THEN (IF settled47.cmtaNumber = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled47.cmtaNumber) ELSE << >>]
        settled49 == [settled48 EXCEPT !.clientIdAttr = IF settled48.numberOfReturnBitfields >= 15 /\ (settled48.returnBitfield15 # << >> /\ (settled48.returnBitfield15[1] \div 128) % 2 > 0) THEN (IF settled48.clientIdAttr = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled48.clientIdAttr) ELSE << >>]
        settled50 == [settled49 EXCEPT !.sessionEligibility = IF settled49.numberOfReturnBitfields >= 16 /\ (settled49.returnBitfield16 # << >> /\ (settled49.returnBitfield16[1] \div 2) % 2 > 0) THEN (IF settled49.sessionEligibility = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled49.sessionEligibility) ELSE << >>]
        settled51 == [settled50 EXCEPT !.floorRoutingInst = IF settled50.numberOfReturnBitfields >= 16 /\ (settled50.returnBitfield16 # << >> /\ (settled50.returnBitfield16[1] \div 32) % 2 > 0) THEN (IF settled50.floorRoutingInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled50.floorRoutingInst) ELSE << >>]
        settled52 == [settled51 EXCEPT !.orderOrigin = IF settled51.numberOfReturnBitfields >= 16 /\ (settled51.returnBitfield16 # << >> /\ (settled51.returnBitfield16[1] \div 128) % 2 > 0) THEN (IF settled51.orderOrigin = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled51.orderOrigin) ELSE << >>]
    IN  settled52

ZeroOrderRejectedMessage ==
    SettleOrderRejectedMessage([ transactionTime         |-> [i \in 1 .. 8 |-> 0],
                                 clOrdId                 |-> [i \in 1 .. 20 |-> 0],
                                 orderRejectReason       |-> [i \in 1 .. 1 |-> 0],
                                 text                    |-> [i \in 1 .. 60 |-> 0],
                                 reserved1               |-> [i \in 1 .. 1 |-> 0],
                                 numberOfReturnBitfields |-> 0,
                                 returnBitfield1         |-> << >>,
                                 returnBitfield2         |-> << >>,
                                 returnBitfield3         |-> << >>,
                                 returnBitfield4         |-> << >>,
                                 returnBitfield5         |-> << >>,
                                 returnBitfield6         |-> << >>,
                                 returnBitfield7         |-> << >>,
                                 returnBitfield8         |-> << >>,
                                 returnBitfield9         |-> << >>,
                                 returnBitfield10        |-> << >>,
                                 returnBitfield11        |-> << >>,
                                 returnBitfield12        |-> << >>,
                                 returnBitfield13        |-> << >>,
                                 returnBitfield14        |-> << >>,
                                 returnBitfield15        |-> << >>,
                                 returnBitfield16        |-> << >>,
                                 returnBitfield17        |-> << >>,
                                 side                    |-> << >>,
                                 priceLong               |-> << >>,
                                 execInst                |-> << >>,
                                 ordType                 |-> << >>,
                                 timeInForce             |-> << >>,
                                 minQty                  |-> << >>,
                                 maxRemovePct            |-> << >>,
                                 symbolLong              |-> << >>,
                                 capacity                |-> << >>,
                                 account                 |-> << >>,
                                 clearingFirm            |-> << >>,
                                 clearingAccount         |-> << >>,
                                 displayIndicator        |-> << >>,
                                 maxFloor                |-> << >>,
                                 orderQtyLong            |-> << >>,
                                 preventMatch            |-> << >>,
                                 maturityDate            |-> << >>,
                                 strikePrice             |-> << >>,
                                 putOrCall               |-> << >>,
                                 openClose               |-> << >>,
                                 correctedSize           |-> << >>,
                                 secondaryOrderId        |-> << >>,
                                 contraCapacity          |-> << >>,
                                 attributedQuote         |-> << >>,
                                 echoText                |-> << >>,
                                 stopPx                  |-> << >>,
                                 routingInst             |-> << >>,
                                 routStrategy            |-> << >>,
                                 routeDeliveryMethod     |-> << >>,
                                 exDestination           |-> << >>,
                                 cmtaNumber              |-> << >>,
                                 clientIdAttr            |-> << >>,
                                 sessionEligibility      |-> << >>,
                                 floorRoutingInst        |-> << >>,
                                 orderOrigin             |-> << >> ])

(* Order Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderRejectedMessage ==
    { ZeroOrderRejectedMessage }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.transactionTime = one]) : one \in Sample(8) }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.clOrdId = one]) : one \in Sample(20) }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.orderRejectReason = one]) : one \in Sample(1) }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.text = one]) : one \in Sample(60) }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.reserved1 = one]) : one \in Sample(1) }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 7, !.returnBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 9, !.returnBitfield9 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 10, !.returnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 11, !.returnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 13, !.returnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 14, !.returnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 15, !.returnBitfield15 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 17, !.returnBitfield17 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<1>>, !.side = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<4>>, !.priceLong = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<8>>, !.execInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<128>>, !.maxRemovePct = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<1>>, !.symbolLong = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<1>>, !.account = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<2>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<4>>, !.clearingAccount = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<8>>, !.displayIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<16>>, !.maxFloor = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<64>>, !.orderQtyLong = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<128>>, !.preventMatch = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<1>>, !.maturityDate = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<2>>, !.strikePrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<4>>, !.putOrCall = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<8>>, !.openClose = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<32>>, !.correctedSize = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = <<1>>, !.secondaryOrderId = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = <<4>>, !.contraCapacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = <<8>>, !.attributedQuote = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<2>>, !.echoText = one]) : one \in { <<held>> : held \in Sample(64) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<4>>, !.stopPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<8>>, !.routingInst = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<16>>, !.routStrategy = one]) : one \in { <<held>> : held \in Sample(6) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<32>>, !.routeDeliveryMethod = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<64>>, !.exDestination = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 9, !.returnBitfield9 = <<32>>, !.cmtaNumber = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 15, !.returnBitfield15 = <<128>>, !.clientIdAttr = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = <<2>>, !.sessionEligibility = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = <<32>>, !.floorRoutingInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = <<128>>, !.orderOrigin = one]) : one \in { <<held>> : held \in Sample(3) } }

(***************************************************************************)
(* Quote Update Rejected Message: 42 bytes                                 *)
(***************************************************************************)

QuoteUpdateRejectedMessage ==
    [ transactionTime   : Sample(8),
      quoteUpdateId     : Sample(16),
      quoteRejectReason : Sample(1),
      reserved17        : Sample(17) ]

EncodeQuoteUpdateRejectedMessage(message) ==
    message.transactionTime
        \o message.quoteUpdateId
        \o message.quoteRejectReason
        \o message.reserved17

DecodeQuoteUpdateRejectedMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET quoteUpdateId == ReadBytes(transactionTime.rest, 16) IN IF ~quoteUpdateId.ok THEN Fail ELSE
    LET quoteRejectReason == ReadBytes(quoteUpdateId.rest, 1) IN IF ~quoteRejectReason.ok THEN Fail ELSE
    LET reserved17 == ReadBytes(quoteRejectReason.rest, 17) IN IF ~reserved17.ok THEN Fail ELSE
    Ok([ transactionTime   |-> transactionTime.value,
         quoteUpdateId     |-> quoteUpdateId.value,
         quoteRejectReason |-> quoteRejectReason.value,
         reserved17        |-> reserved17.value ], reserved17.rest)

ZeroQuoteUpdateRejectedMessage ==
    [ transactionTime   |-> [i \in 1 .. 8 |-> 0],
      quoteUpdateId     |-> [i \in 1 .. 16 |-> 0],
      quoteRejectReason |-> [i \in 1 .. 1 |-> 0],
      reserved17        |-> [i \in 1 .. 17 |-> 0] ]

(* Quote Update Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteUpdateRejectedMessage ==
    { ZeroQuoteUpdateRejectedMessage }
        \cup { [ZeroQuoteUpdateRejectedMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroQuoteUpdateRejectedMessage EXCEPT !.quoteUpdateId = one] : one \in Sample(16) }
        \cup { [ZeroQuoteUpdateRejectedMessage EXCEPT !.quoteRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroQuoteUpdateRejectedMessage EXCEPT !.reserved17 = one] : one \in Sample(17) }

(***************************************************************************)
(* Order Modified Message                                                  *)
(***************************************************************************)

OrderModifiedMessage ==
    [ transactionTime         : Sample(8),
      clOrdId                 : Sample(20),
      orderId                 : Sample(8),
      reserved1               : Sample(1),
      numberOfReturnBitfields : 0 .. 255,
      returnBitfield1         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield2         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield3         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield4         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield5         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield6         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield7         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield8         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield9         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield10        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield11        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield12        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield13        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield14        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield15        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield16        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield17        : { << >> } \cup { <<held>> : held \in Sample(1) },
      side                    : { << >> } \cup { <<held>> : held \in Sample(1) },
      priceLong               : { << >> } \cup { <<held>> : held \in Sample(8) },
      execInst                : { << >> } \cup { <<held>> : held \in Sample(1) },
      ordType                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce             : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                  : { << >> } \cup { <<held>> : held \in Sample(4) },
      maxRemovePct            : { << >> } \cup { <<held>> : held \in Sample(1) },
      symbolLong              : { << >> } \cup { <<held>> : held \in Sample(8) },
      account                 : { << >> } \cup { <<held>> : held \in Sample(16) },
      clearingFirm            : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingAccount         : { << >> } \cup { <<held>> : held \in Sample(4) },
      displayIndicator        : { << >> } \cup { <<held>> : held \in Sample(1) },
      maxFloor                : { << >> } \cup { <<held>> : held \in Sample(4) },
      orderQtyLong            : { << >> } \cup { <<held>> : held \in Sample(4) },
      preventMatch            : { << >> } \cup { <<held>> : held \in Sample(3) },
      origClOrdId             : { << >> } \cup { <<held>> : held \in Sample(20) },
      leavesQty               : { << >> } \cup { <<held>> : held \in Sample(4) },
      lastShares              : { << >> } \cup { <<held>> : held \in Sample(4) },
      lastPx                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      displayPrice            : { << >> } \cup { <<held>> : held \in Sample(8) },
      workingPrice            : { << >> } \cup { <<held>> : held \in Sample(8) },
      baseLiquidityIndicator  : { << >> } \cup { <<held>> : held \in Sample(1) },
      expireTime              : { << >> } \cup { <<held>> : held \in Sample(8) },
      secondaryOrderId        : { << >> } \cup { <<held>> : held \in Sample(8) },
      contraCapacity          : { << >> } \cup { <<held>> : held \in Sample(1) },
      attributedQuote         : { << >> } \cup { <<held>> : held \in Sample(1) },
      echoText                : { << >> } \cup { <<held>> : held \in Sample(64) },
      stopPx                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      routingInst             : { << >> } \cup { <<held>> : held \in Sample(4) },
      routStrategy            : { << >> } \cup { <<held>> : held \in Sample(6) },
      routeDeliveryMethod     : { << >> } \cup { <<held>> : held \in Sample(3) },
      exDestination           : { << >> } \cup { <<held>> : held \in Sample(1) },
      cmtaNumber              : { << >> } \cup { <<held>> : held \in Sample(4) },
      floorRoutingInst        : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderOrigin             : { << >> } \cup { <<held>> : held \in Sample(3) } ]

EncodeOrderModifiedMessage(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.orderId
        \o message.reserved1
        \o EncodeUIntBE(message.numberOfReturnBitfields, 1)
        \o (IF message.returnBitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield1[1], 1))
        \o (IF message.returnBitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield2[1], 1))
        \o (IF message.returnBitfield3 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield3[1], 1))
        \o (IF message.returnBitfield4 = << >> THEN << >> ELSE message.returnBitfield4[1])
        \o (IF message.returnBitfield5 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield5[1], 1))
        \o (IF message.returnBitfield6 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield6[1], 1))
        \o (IF message.returnBitfield7 = << >> THEN << >> ELSE message.returnBitfield7[1])
        \o (IF message.returnBitfield8 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield8[1], 1))
        \o (IF message.returnBitfield9 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield9[1], 1))
        \o (IF message.returnBitfield10 = << >> THEN << >> ELSE message.returnBitfield10[1])
        \o (IF message.returnBitfield11 = << >> THEN << >> ELSE message.returnBitfield11[1])
        \o (IF message.returnBitfield12 = << >> THEN << >> ELSE message.returnBitfield12[1])
        \o (IF message.returnBitfield13 = << >> THEN << >> ELSE message.returnBitfield13[1])
        \o (IF message.returnBitfield14 = << >> THEN << >> ELSE message.returnBitfield14[1])
        \o (IF message.returnBitfield15 = << >> THEN << >> ELSE message.returnBitfield15[1])
        \o (IF message.returnBitfield16 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield16[1], 1))
        \o (IF message.returnBitfield17 = << >> THEN << >> ELSE message.returnBitfield17[1])
        \o (IF message.side = << >> THEN << >> ELSE message.side[1])
        \o (IF message.priceLong = << >> THEN << >> ELSE message.priceLong[1])
        \o (IF message.execInst = << >> THEN << >> ELSE message.execInst[1])
        \o (IF message.ordType = << >> THEN << >> ELSE message.ordType[1])
        \o (IF message.timeInForce = << >> THEN << >> ELSE message.timeInForce[1])
        \o (IF message.minQty = << >> THEN << >> ELSE message.minQty[1])
        \o (IF message.maxRemovePct = << >> THEN << >> ELSE message.maxRemovePct[1])
        \o (IF message.symbolLong = << >> THEN << >> ELSE message.symbolLong[1])
        \o (IF message.account = << >> THEN << >> ELSE message.account[1])
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])
        \o (IF message.clearingAccount = << >> THEN << >> ELSE message.clearingAccount[1])
        \o (IF message.displayIndicator = << >> THEN << >> ELSE message.displayIndicator[1])
        \o (IF message.maxFloor = << >> THEN << >> ELSE message.maxFloor[1])
        \o (IF message.orderQtyLong = << >> THEN << >> ELSE message.orderQtyLong[1])
        \o (IF message.preventMatch = << >> THEN << >> ELSE message.preventMatch[1])
        \o (IF message.origClOrdId = << >> THEN << >> ELSE message.origClOrdId[1])
        \o (IF message.leavesQty = << >> THEN << >> ELSE message.leavesQty[1])
        \o (IF message.lastShares = << >> THEN << >> ELSE message.lastShares[1])
        \o (IF message.lastPx = << >> THEN << >> ELSE message.lastPx[1])
        \o (IF message.displayPrice = << >> THEN << >> ELSE message.displayPrice[1])
        \o (IF message.workingPrice = << >> THEN << >> ELSE message.workingPrice[1])
        \o (IF message.baseLiquidityIndicator = << >> THEN << >> ELSE message.baseLiquidityIndicator[1])
        \o (IF message.expireTime = << >> THEN << >> ELSE message.expireTime[1])
        \o (IF message.secondaryOrderId = << >> THEN << >> ELSE message.secondaryOrderId[1])
        \o (IF message.contraCapacity = << >> THEN << >> ELSE message.contraCapacity[1])
        \o (IF message.attributedQuote = << >> THEN << >> ELSE message.attributedQuote[1])
        \o (IF message.echoText = << >> THEN << >> ELSE message.echoText[1])
        \o (IF message.stopPx = << >> THEN << >> ELSE message.stopPx[1])
        \o (IF message.routingInst = << >> THEN << >> ELSE message.routingInst[1])
        \o (IF message.routStrategy = << >> THEN << >> ELSE message.routStrategy[1])
        \o (IF message.routeDeliveryMethod = << >> THEN << >> ELSE message.routeDeliveryMethod[1])
        \o (IF message.exDestination = << >> THEN << >> ELSE message.exDestination[1])
        \o (IF message.cmtaNumber = << >> THEN << >> ELSE message.cmtaNumber[1])
        \o (IF message.floorRoutingInst = << >> THEN << >> ELSE message.floorRoutingInst[1])
        \o (IF message.orderOrigin = << >> THEN << >> ELSE message.orderOrigin[1])

DecodeOrderModifiedMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clOrdId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(orderId.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET numberOfReturnBitfields == ReadUIntBE(reserved1.rest, 1) IN IF ~numberOfReturnBitfields.ok THEN Fail ELSE
    LET returnBitfield1 == ReadWhen(numberOfReturnBitfields.value >= 1, ReadUIntLE(numberOfReturnBitfields.rest, 1), numberOfReturnBitfields.rest) IN IF ~returnBitfield1.ok THEN Fail ELSE
    LET returnBitfield2 == ReadWhen(numberOfReturnBitfields.value >= 2, ReadUIntLE(returnBitfield1.rest, 1), returnBitfield1.rest) IN IF ~returnBitfield2.ok THEN Fail ELSE
    LET returnBitfield3 == ReadWhen(numberOfReturnBitfields.value >= 3, ReadUIntLE(returnBitfield2.rest, 1), returnBitfield2.rest) IN IF ~returnBitfield3.ok THEN Fail ELSE
    LET returnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadBytes(returnBitfield3.rest, 1), returnBitfield3.rest) IN IF ~returnBitfield4.ok THEN Fail ELSE
    LET returnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadUIntLE(returnBitfield4.rest, 1), returnBitfield4.rest) IN IF ~returnBitfield5.ok THEN Fail ELSE
    LET returnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadUIntLE(returnBitfield5.rest, 1), returnBitfield5.rest) IN IF ~returnBitfield6.ok THEN Fail ELSE
    LET returnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadBytes(returnBitfield6.rest, 1), returnBitfield6.rest) IN IF ~returnBitfield7.ok THEN Fail ELSE
    LET returnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadUIntLE(returnBitfield7.rest, 1), returnBitfield7.rest) IN IF ~returnBitfield8.ok THEN Fail ELSE
    LET returnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadUIntLE(returnBitfield8.rest, 1), returnBitfield8.rest) IN IF ~returnBitfield9.ok THEN Fail ELSE
    LET returnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadBytes(returnBitfield9.rest, 1), returnBitfield9.rest) IN IF ~returnBitfield10.ok THEN Fail ELSE
    LET returnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadBytes(returnBitfield10.rest, 1), returnBitfield10.rest) IN IF ~returnBitfield11.ok THEN Fail ELSE
    LET returnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadBytes(returnBitfield11.rest, 1), returnBitfield11.rest) IN IF ~returnBitfield12.ok THEN Fail ELSE
    LET returnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(returnBitfield12.rest, 1), returnBitfield12.rest) IN IF ~returnBitfield13.ok THEN Fail ELSE
    LET returnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(returnBitfield13.rest, 1), returnBitfield13.rest) IN IF ~returnBitfield14.ok THEN Fail ELSE
    LET returnBitfield15 == ReadWhen(numberOfReturnBitfields.value >= 15, ReadBytes(returnBitfield14.rest, 1), returnBitfield14.rest) IN IF ~returnBitfield15.ok THEN Fail ELSE
    LET returnBitfield16 == ReadWhen(numberOfReturnBitfields.value >= 16, ReadUIntLE(returnBitfield15.rest, 1), returnBitfield15.rest) IN IF ~returnBitfield16.ok THEN Fail ELSE
    LET returnBitfield17 == ReadWhen(numberOfReturnBitfields.value >= 17, ReadBytes(returnBitfield16.rest, 1), returnBitfield16.rest) IN IF ~returnBitfield17.ok THEN Fail ELSE
    LET side == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ returnBitfield1.value[1] % 2 > 0), ReadBytes(returnBitfield17.rest, 1), returnBitfield17.rest) IN IF ~side.ok THEN Fail ELSE
    LET priceLong == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(side.rest, 8), side.rest) IN IF ~priceLong.ok THEN Fail ELSE
    LET execInst == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 8) % 2 > 0), ReadBytes(priceLong.rest, 1), priceLong.rest) IN IF ~execInst.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(execInst.rest, 1), execInst.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET maxRemovePct == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 128) % 2 > 0), ReadBytes(minQty.rest, 1), minQty.rest) IN IF ~maxRemovePct.ok THEN Fail ELSE
    LET symbolLong == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ returnBitfield2.value[1] % 2 > 0), ReadBytes(maxRemovePct.rest, 8), maxRemovePct.rest) IN IF ~symbolLong.ok THEN Fail ELSE
    LET account == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ returnBitfield3.value[1] % 2 > 0), ReadBytes(symbolLong.rest, 16), symbolLong.rest) IN IF ~account.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 2) % 2 > 0), ReadBytes(account.rest, 4), account.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 4) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET displayIndicator == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 8) % 2 > 0), ReadBytes(clearingAccount.rest, 1), clearingAccount.rest) IN IF ~displayIndicator.ok THEN Fail ELSE
    LET maxFloor == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 16) % 2 > 0), ReadBytes(displayIndicator.rest, 4), displayIndicator.rest) IN IF ~maxFloor.ok THEN Fail ELSE
    LET orderQtyLong == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 64) % 2 > 0), ReadBytes(maxFloor.rest, 4), maxFloor.rest) IN IF ~orderQtyLong.ok THEN Fail ELSE
    LET preventMatch == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 128) % 2 > 0), ReadBytes(orderQtyLong.rest, 3), orderQtyLong.rest) IN IF ~preventMatch.ok THEN Fail ELSE
    LET origClOrdId == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ returnBitfield5.value[1] % 2 > 0), ReadBytes(preventMatch.rest, 20), preventMatch.rest) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET leavesQty == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 2) % 2 > 0), ReadBytes(origClOrdId.rest, 4), origClOrdId.rest) IN IF ~leavesQty.ok THEN Fail ELSE
    LET lastShares == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 4) % 2 > 0), ReadBytes(leavesQty.rest, 4), leavesQty.rest) IN IF ~lastShares.ok THEN Fail ELSE
    LET lastPx == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 8) % 2 > 0), ReadBytes(lastShares.rest, 8), lastShares.rest) IN IF ~lastPx.ok THEN Fail ELSE
    LET displayPrice == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 16) % 2 > 0), ReadBytes(lastPx.rest, 8), lastPx.rest) IN IF ~displayPrice.ok THEN Fail ELSE
    LET workingPrice == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 32) % 2 > 0), ReadBytes(displayPrice.rest, 8), displayPrice.rest) IN IF ~workingPrice.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 64) % 2 > 0), ReadBytes(workingPrice.rest, 1), workingPrice.rest) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET expireTime == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 128) % 2 > 0), ReadBytes(baseLiquidityIndicator.rest, 8), baseLiquidityIndicator.rest) IN IF ~expireTime.ok THEN Fail ELSE
    LET secondaryOrderId == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (returnBitfield6.value # << >> /\ returnBitfield6.value[1] % 2 > 0), ReadBytes(expireTime.rest, 8), expireTime.rest) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET contraCapacity == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (returnBitfield6.value # << >> /\ (returnBitfield6.value[1] \div 4) % 2 > 0), ReadBytes(secondaryOrderId.rest, 1), secondaryOrderId.rest) IN IF ~contraCapacity.ok THEN Fail ELSE
    LET attributedQuote == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (returnBitfield6.value # << >> /\ (returnBitfield6.value[1] \div 8) % 2 > 0), ReadBytes(contraCapacity.rest, 1), contraCapacity.rest) IN IF ~attributedQuote.ok THEN Fail ELSE
    LET echoText == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 2) % 2 > 0), ReadBytes(attributedQuote.rest, 64), attributedQuote.rest) IN IF ~echoText.ok THEN Fail ELSE
    LET stopPx == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 4) % 2 > 0), ReadBytes(echoText.rest, 8), echoText.rest) IN IF ~stopPx.ok THEN Fail ELSE
    LET routingInst == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 8) % 2 > 0), ReadBytes(stopPx.rest, 4), stopPx.rest) IN IF ~routingInst.ok THEN Fail ELSE
    LET routStrategy == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 16) % 2 > 0), ReadBytes(routingInst.rest, 6), routingInst.rest) IN IF ~routStrategy.ok THEN Fail ELSE
    LET routeDeliveryMethod == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 32) % 2 > 0), ReadBytes(routStrategy.rest, 3), routStrategy.rest) IN IF ~routeDeliveryMethod.ok THEN Fail ELSE
    LET exDestination == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 64) % 2 > 0), ReadBytes(routeDeliveryMethod.rest, 1), routeDeliveryMethod.rest) IN IF ~exDestination.ok THEN Fail ELSE
    LET cmtaNumber == ReadWhen(numberOfReturnBitfields.value >= 9 /\ (returnBitfield9.value # << >> /\ (returnBitfield9.value[1] \div 32) % 2 > 0), ReadBytes(exDestination.rest, 4), exDestination.rest) IN IF ~cmtaNumber.ok THEN Fail ELSE
    LET floorRoutingInst == ReadWhen(numberOfReturnBitfields.value >= 16 /\ (returnBitfield16.value # << >> /\ (returnBitfield16.value[1] \div 32) % 2 > 0), ReadBytes(cmtaNumber.rest, 1), cmtaNumber.rest) IN IF ~floorRoutingInst.ok THEN Fail ELSE
    LET orderOrigin == ReadWhen(numberOfReturnBitfields.value >= 16 /\ (returnBitfield16.value # << >> /\ (returnBitfield16.value[1] \div 128) % 2 > 0), ReadBytes(floorRoutingInst.rest, 3), floorRoutingInst.rest) IN IF ~orderOrigin.ok THEN Fail ELSE
    Ok([ transactionTime         |-> transactionTime.value,
         clOrdId                 |-> clOrdId.value,
         orderId                 |-> orderId.value,
         reserved1               |-> reserved1.value,
         numberOfReturnBitfields |-> numberOfReturnBitfields.value,
         returnBitfield1         |-> returnBitfield1.value,
         returnBitfield2         |-> returnBitfield2.value,
         returnBitfield3         |-> returnBitfield3.value,
         returnBitfield4         |-> returnBitfield4.value,
         returnBitfield5         |-> returnBitfield5.value,
         returnBitfield6         |-> returnBitfield6.value,
         returnBitfield7         |-> returnBitfield7.value,
         returnBitfield8         |-> returnBitfield8.value,
         returnBitfield9         |-> returnBitfield9.value,
         returnBitfield10        |-> returnBitfield10.value,
         returnBitfield11        |-> returnBitfield11.value,
         returnBitfield12        |-> returnBitfield12.value,
         returnBitfield13        |-> returnBitfield13.value,
         returnBitfield14        |-> returnBitfield14.value,
         returnBitfield15        |-> returnBitfield15.value,
         returnBitfield16        |-> returnBitfield16.value,
         returnBitfield17        |-> returnBitfield17.value,
         side                    |-> side.value,
         priceLong               |-> priceLong.value,
         execInst                |-> execInst.value,
         ordType                 |-> ordType.value,
         timeInForce             |-> timeInForce.value,
         minQty                  |-> minQty.value,
         maxRemovePct            |-> maxRemovePct.value,
         symbolLong              |-> symbolLong.value,
         account                 |-> account.value,
         clearingFirm            |-> clearingFirm.value,
         clearingAccount         |-> clearingAccount.value,
         displayIndicator        |-> displayIndicator.value,
         maxFloor                |-> maxFloor.value,
         orderQtyLong            |-> orderQtyLong.value,
         preventMatch            |-> preventMatch.value,
         origClOrdId             |-> origClOrdId.value,
         leavesQty               |-> leavesQty.value,
         lastShares              |-> lastShares.value,
         lastPx                  |-> lastPx.value,
         displayPrice            |-> displayPrice.value,
         workingPrice            |-> workingPrice.value,
         baseLiquidityIndicator  |-> baseLiquidityIndicator.value,
         expireTime              |-> expireTime.value,
         secondaryOrderId        |-> secondaryOrderId.value,
         contraCapacity          |-> contraCapacity.value,
         attributedQuote         |-> attributedQuote.value,
         echoText                |-> echoText.value,
         stopPx                  |-> stopPx.value,
         routingInst             |-> routingInst.value,
         routStrategy            |-> routStrategy.value,
         routeDeliveryMethod     |-> routeDeliveryMethod.value,
         exDestination           |-> exDestination.value,
         cmtaNumber              |-> cmtaNumber.value,
         floorRoutingInst        |-> floorRoutingInst.value,
         orderOrigin             |-> orderOrigin.value ], orderOrigin.rest)

(* Order Modified Message with each field marked present by fields before it there exactly where they say *)
SettleOrderModifiedMessage(message) ==
    LET settled1 == [message EXCEPT !.returnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.returnBitfield1 = << >> THEN <<0>> ELSE message.returnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.returnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.returnBitfield2 = << >> THEN <<0>> ELSE settled1.returnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.returnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.returnBitfield3 = << >> THEN <<0>> ELSE settled2.returnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.returnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.returnBitfield4 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled3.returnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.returnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.returnBitfield5 = << >> THEN <<0>> ELSE settled4.returnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.returnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.returnBitfield6 = << >> THEN <<0>> ELSE settled5.returnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.returnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.returnBitfield7 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.returnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.returnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.returnBitfield8 = << >> THEN <<0>> ELSE settled7.returnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.returnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.returnBitfield9 = << >> THEN <<0>> ELSE settled8.returnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.returnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.returnBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.returnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.returnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.returnBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.returnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.returnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.returnBitfield12 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.returnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.returnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.returnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.returnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.returnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.returnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.returnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.returnBitfield15 = IF settled14.numberOfReturnBitfields >= 15 THEN (IF settled14.returnBitfield15 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.returnBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.returnBitfield16 = IF settled15.numberOfReturnBitfields >= 16 THEN (IF settled15.returnBitfield16 = << >> THEN <<0>> ELSE settled15.returnBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.returnBitfield17 = IF settled16.numberOfReturnBitfields >= 17 THEN (IF settled16.returnBitfield17 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled16.returnBitfield17) ELSE << >>]
        settled18 == [settled17 EXCEPT !.side = IF settled17.numberOfReturnBitfields >= 1 /\ (settled17.returnBitfield1 # << >> /\ settled17.returnBitfield1[1] % 2 > 0) THEN (IF settled17.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.side) ELSE << >>]
        settled19 == [settled18 EXCEPT !.priceLong = IF settled18.numberOfReturnBitfields >= 1 /\ (settled18.returnBitfield1 # << >> /\ (settled18.returnBitfield1[1] \div 4) % 2 > 0) THEN (IF settled18.priceLong = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled18.priceLong) ELSE << >>]
        settled20 == [settled19 EXCEPT !.execInst = IF settled19.numberOfReturnBitfields >= 1 /\ (settled19.returnBitfield1 # << >> /\ (settled19.returnBitfield1[1] \div 8) % 2 > 0) THEN (IF settled19.execInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled19.execInst) ELSE << >>]
        settled21 == [settled20 EXCEPT !.ordType = IF settled20.numberOfReturnBitfields >= 1 /\ (settled20.returnBitfield1 # << >> /\ (settled20.returnBitfield1[1] \div 16) % 2 > 0) THEN (IF settled20.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled20.ordType) ELSE << >>]
        settled22 == [settled21 EXCEPT !.timeInForce = IF settled21.numberOfReturnBitfields >= 1 /\ (settled21.returnBitfield1 # << >> /\ (settled21.returnBitfield1[1] \div 32) % 2 > 0) THEN (IF settled21.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled21.timeInForce) ELSE << >>]
        settled23 == [settled22 EXCEPT !.minQty = IF settled22.numberOfReturnBitfields >= 1 /\ (settled22.returnBitfield1 # << >> /\ (settled22.returnBitfield1[1] \div 64) % 2 > 0) THEN (IF settled22.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled22.minQty) ELSE << >>]
        settled24 == [settled23 EXCEPT !.maxRemovePct = IF settled23.numberOfReturnBitfields >= 1 /\ (settled23.returnBitfield1 # << >> /\ (settled23.returnBitfield1[1] \div 128) % 2 > 0) THEN (IF settled23.maxRemovePct = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled23.maxRemovePct) ELSE << >>]
        settled25 == [settled24 EXCEPT !.symbolLong = IF settled24.numberOfReturnBitfields >= 2 /\ (settled24.returnBitfield2 # << >> /\ settled24.returnBitfield2[1] % 2 > 0) THEN (IF settled24.symbolLong = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled24.symbolLong) ELSE << >>]
        settled26 == [settled25 EXCEPT !.account = IF settled25.numberOfReturnBitfields >= 3 /\ (settled25.returnBitfield3 # << >> /\ settled25.returnBitfield3[1] % 2 > 0) THEN (IF settled25.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled25.account) ELSE << >>]
        settled27 == [settled26 EXCEPT !.clearingFirm = IF settled26.numberOfReturnBitfields >= 3 /\ (settled26.returnBitfield3 # << >> /\ (settled26.returnBitfield3[1] \div 2) % 2 > 0) THEN (IF settled26.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled26.clearingFirm) ELSE << >>]
        settled28 == [settled27 EXCEPT !.clearingAccount = IF settled27.numberOfReturnBitfields >= 3 /\ (settled27.returnBitfield3 # << >> /\ (settled27.returnBitfield3[1] \div 4) % 2 > 0) THEN (IF settled27.clearingAccount = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled27.clearingAccount) ELSE << >>]
        settled29 == [settled28 EXCEPT !.displayIndicator = IF settled28.numberOfReturnBitfields >= 3 /\ (settled28.returnBitfield3 # << >> /\ (settled28.returnBitfield3[1] \div 8) % 2 > 0) THEN (IF settled28.displayIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled28.displayIndicator) ELSE << >>]
        settled30 == [settled29 EXCEPT !.maxFloor = IF settled29.numberOfReturnBitfields >= 3 /\ (settled29.returnBitfield3 # << >> /\ (settled29.returnBitfield3[1] \div 16) % 2 > 0) THEN (IF settled29.maxFloor = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled29.maxFloor) ELSE << >>]
        settled31 == [settled30 EXCEPT !.orderQtyLong = IF settled30.numberOfReturnBitfields >= 3 /\ (settled30.returnBitfield3 # << >> /\ (settled30.returnBitfield3[1] \div 64) % 2 > 0) THEN (IF settled30.orderQtyLong = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled30.orderQtyLong) ELSE << >>]
        settled32 == [settled31 EXCEPT !.preventMatch = IF settled31.numberOfReturnBitfields >= 3 /\ (settled31.returnBitfield3 # << >> /\ (settled31.returnBitfield3[1] \div 128) % 2 > 0) THEN (IF settled31.preventMatch = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled31.preventMatch) ELSE << >>]
        settled33 == [settled32 EXCEPT !.origClOrdId = IF settled32.numberOfReturnBitfields >= 5 /\ (settled32.returnBitfield5 # << >> /\ settled32.returnBitfield5[1] % 2 > 0) THEN (IF settled32.origClOrdId = << >> THEN <<[i \in 1 .. 20 |-> 0]>> ELSE settled32.origClOrdId) ELSE << >>]
        settled34 == [settled33 EXCEPT !.leavesQty = IF settled33.numberOfReturnBitfields >= 5 /\ (settled33.returnBitfield5 # << >> /\ (settled33.returnBitfield5[1] \div 2) % 2 > 0) THEN (IF settled33.leavesQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled33.leavesQty) ELSE << >>]
        settled35 == [settled34 EXCEPT !.lastShares = IF settled34.numberOfReturnBitfields >= 5 /\ (settled34.returnBitfield5 # << >> /\ (settled34.returnBitfield5[1] \div 4) % 2 > 0) THEN (IF settled34.lastShares = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled34.lastShares) ELSE << >>]
        settled36 == [settled35 EXCEPT !.lastPx = IF settled35.numberOfReturnBitfields >= 5 /\ (settled35.returnBitfield5 # << >> /\ (settled35.returnBitfield5[1] \div 8) % 2 > 0) THEN (IF settled35.lastPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled35.lastPx) ELSE << >>]
        settled37 == [settled36 EXCEPT !.displayPrice = IF settled36.numberOfReturnBitfields >= 5 /\ (settled36.returnBitfield5 # << >> /\ (settled36.returnBitfield5[1] \div 16) % 2 > 0) THEN (IF settled36.displayPrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled36.displayPrice) ELSE << >>]
        settled38 == [settled37 EXCEPT !.workingPrice = IF settled37.numberOfReturnBitfields >= 5 /\ (settled37.returnBitfield5 # << >> /\ (settled37.returnBitfield5[1] \div 32) % 2 > 0) THEN (IF settled37.workingPrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled37.workingPrice) ELSE << >>]
        settled39 == [settled38 EXCEPT !.baseLiquidityIndicator = IF settled38.numberOfReturnBitfields >= 5 /\ (settled38.returnBitfield5 # << >> /\ (settled38.returnBitfield5[1] \div 64) % 2 > 0) THEN (IF settled38.baseLiquidityIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled38.baseLiquidityIndicator) ELSE << >>]
        settled40 == [settled39 EXCEPT !.expireTime = IF settled39.numberOfReturnBitfields >= 5 /\ (settled39.returnBitfield5 # << >> /\ (settled39.returnBitfield5[1] \div 128) % 2 > 0) THEN (IF settled39.expireTime = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled39.expireTime) ELSE << >>]
        settled41 == [settled40 EXCEPT !.secondaryOrderId = IF settled40.numberOfReturnBitfields >= 6 /\ (settled40.returnBitfield6 # << >> /\ settled40.returnBitfield6[1] % 2 > 0) THEN (IF settled40.secondaryOrderId = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled40.secondaryOrderId) ELSE << >>]
        settled42 == [settled41 EXCEPT !.contraCapacity = IF settled41.numberOfReturnBitfields >= 6 /\ (settled41.returnBitfield6 # << >> /\ (settled41.returnBitfield6[1] \div 4) % 2 > 0) THEN (IF settled41.contraCapacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled41.contraCapacity) ELSE << >>]
        settled43 == [settled42 EXCEPT !.attributedQuote = IF settled42.numberOfReturnBitfields >= 6 /\ (settled42.returnBitfield6 # << >> /\ (settled42.returnBitfield6[1] \div 8) % 2 > 0) THEN (IF settled42.attributedQuote = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled42.attributedQuote) ELSE << >>]
        settled44 == [settled43 EXCEPT !.echoText = IF settled43.numberOfReturnBitfields >= 8 /\ (settled43.returnBitfield8 # << >> /\ (settled43.returnBitfield8[1] \div 2) % 2 > 0) THEN (IF settled43.echoText = << >> THEN <<[i \in 1 .. 64 |-> 0]>> ELSE settled43.echoText) ELSE << >>]
        settled45 == [settled44 EXCEPT !.stopPx = IF settled44.numberOfReturnBitfields >= 8 /\ (settled44.returnBitfield8 # << >> /\ (settled44.returnBitfield8[1] \div 4) % 2 > 0) THEN (IF settled44.stopPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled44.stopPx) ELSE << >>]
        settled46 == [settled45 EXCEPT !.routingInst = IF settled45.numberOfReturnBitfields >= 8 /\ (settled45.returnBitfield8 # << >> /\ (settled45.returnBitfield8[1] \div 8) % 2 > 0) THEN (IF settled45.routingInst = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled45.routingInst) ELSE << >>]
        settled47 == [settled46 EXCEPT !.routStrategy = IF settled46.numberOfReturnBitfields >= 8 /\ (settled46.returnBitfield8 # << >> /\ (settled46.returnBitfield8[1] \div 16) % 2 > 0) THEN (IF settled46.routStrategy = << >> THEN <<[i \in 1 .. 6 |-> 0]>> ELSE settled46.routStrategy) ELSE << >>]
        settled48 == [settled47 EXCEPT !.routeDeliveryMethod = IF settled47.numberOfReturnBitfields >= 8 /\ (settled47.returnBitfield8 # << >> /\ (settled47.returnBitfield8[1] \div 32) % 2 > 0) THEN (IF settled47.routeDeliveryMethod = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled47.routeDeliveryMethod) ELSE << >>]
        settled49 == [settled48 EXCEPT !.exDestination = IF settled48.numberOfReturnBitfields >= 8 /\ (settled48.returnBitfield8 # << >> /\ (settled48.returnBitfield8[1] \div 64) % 2 > 0) THEN (IF settled48.exDestination = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled48.exDestination) ELSE << >>]
        settled50 == [settled49 EXCEPT !.cmtaNumber = IF settled49.numberOfReturnBitfields >= 9 /\ (settled49.returnBitfield9 # << >> /\ (settled49.returnBitfield9[1] \div 32) % 2 > 0) THEN (IF settled49.cmtaNumber = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled49.cmtaNumber) ELSE << >>]
        settled51 == [settled50 EXCEPT !.floorRoutingInst = IF settled50.numberOfReturnBitfields >= 16 /\ (settled50.returnBitfield16 # << >> /\ (settled50.returnBitfield16[1] \div 32) % 2 > 0) THEN (IF settled50.floorRoutingInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled50.floorRoutingInst) ELSE << >>]
        settled52 == [settled51 EXCEPT !.orderOrigin = IF settled51.numberOfReturnBitfields >= 16 /\ (settled51.returnBitfield16 # << >> /\ (settled51.returnBitfield16[1] \div 128) % 2 > 0) THEN (IF settled51.orderOrigin = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled51.orderOrigin) ELSE << >>]
    IN  settled52

ZeroOrderModifiedMessage ==
    SettleOrderModifiedMessage([ transactionTime         |-> [i \in 1 .. 8 |-> 0],
                                 clOrdId                 |-> [i \in 1 .. 20 |-> 0],
                                 orderId                 |-> [i \in 1 .. 8 |-> 0],
                                 reserved1               |-> [i \in 1 .. 1 |-> 0],
                                 numberOfReturnBitfields |-> 0,
                                 returnBitfield1         |-> << >>,
                                 returnBitfield2         |-> << >>,
                                 returnBitfield3         |-> << >>,
                                 returnBitfield4         |-> << >>,
                                 returnBitfield5         |-> << >>,
                                 returnBitfield6         |-> << >>,
                                 returnBitfield7         |-> << >>,
                                 returnBitfield8         |-> << >>,
                                 returnBitfield9         |-> << >>,
                                 returnBitfield10        |-> << >>,
                                 returnBitfield11        |-> << >>,
                                 returnBitfield12        |-> << >>,
                                 returnBitfield13        |-> << >>,
                                 returnBitfield14        |-> << >>,
                                 returnBitfield15        |-> << >>,
                                 returnBitfield16        |-> << >>,
                                 returnBitfield17        |-> << >>,
                                 side                    |-> << >>,
                                 priceLong               |-> << >>,
                                 execInst                |-> << >>,
                                 ordType                 |-> << >>,
                                 timeInForce             |-> << >>,
                                 minQty                  |-> << >>,
                                 maxRemovePct            |-> << >>,
                                 symbolLong              |-> << >>,
                                 account                 |-> << >>,
                                 clearingFirm            |-> << >>,
                                 clearingAccount         |-> << >>,
                                 displayIndicator        |-> << >>,
                                 maxFloor                |-> << >>,
                                 orderQtyLong            |-> << >>,
                                 preventMatch            |-> << >>,
                                 origClOrdId             |-> << >>,
                                 leavesQty               |-> << >>,
                                 lastShares              |-> << >>,
                                 lastPx                  |-> << >>,
                                 displayPrice            |-> << >>,
                                 workingPrice            |-> << >>,
                                 baseLiquidityIndicator  |-> << >>,
                                 expireTime              |-> << >>,
                                 secondaryOrderId        |-> << >>,
                                 contraCapacity          |-> << >>,
                                 attributedQuote         |-> << >>,
                                 echoText                |-> << >>,
                                 stopPx                  |-> << >>,
                                 routingInst             |-> << >>,
                                 routStrategy            |-> << >>,
                                 routeDeliveryMethod     |-> << >>,
                                 exDestination           |-> << >>,
                                 cmtaNumber              |-> << >>,
                                 floorRoutingInst        |-> << >>,
                                 orderOrigin             |-> << >> ])

(* Order Modified Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderModifiedMessage ==
    { ZeroOrderModifiedMessage }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.transactionTime = one]) : one \in Sample(8) }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.clOrdId = one]) : one \in Sample(20) }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.orderId = one]) : one \in Sample(8) }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.reserved1 = one]) : one \in Sample(1) }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 7, !.returnBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 9, !.returnBitfield9 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 10, !.returnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 11, !.returnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 13, !.returnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 14, !.returnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 15, !.returnBitfield15 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 17, !.returnBitfield17 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<1>>, !.side = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<4>>, !.priceLong = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<8>>, !.execInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<128>>, !.maxRemovePct = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<1>>, !.symbolLong = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<1>>, !.account = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<2>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<4>>, !.clearingAccount = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<8>>, !.displayIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<16>>, !.maxFloor = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<64>>, !.orderQtyLong = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<128>>, !.preventMatch = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<1>>, !.origClOrdId = one]) : one \in { <<held>> : held \in Sample(20) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<2>>, !.leavesQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<4>>, !.lastShares = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<8>>, !.lastPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<16>>, !.displayPrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<32>>, !.workingPrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<64>>, !.baseLiquidityIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<128>>, !.expireTime = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = <<1>>, !.secondaryOrderId = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = <<4>>, !.contraCapacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = <<8>>, !.attributedQuote = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<2>>, !.echoText = one]) : one \in { <<held>> : held \in Sample(64) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<4>>, !.stopPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<8>>, !.routingInst = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<16>>, !.routStrategy = one]) : one \in { <<held>> : held \in Sample(6) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<32>>, !.routeDeliveryMethod = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<64>>, !.exDestination = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 9, !.returnBitfield9 = <<32>>, !.cmtaNumber = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = <<32>>, !.floorRoutingInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = <<128>>, !.orderOrigin = one]) : one \in { <<held>> : held \in Sample(3) } }

(***************************************************************************)
(* Order Restated Message                                                  *)
(***************************************************************************)

OrderRestatedMessage ==
    [ transactionTime         : Sample(8),
      clOrdId                 : Sample(20),
      orderId                 : Sample(8),
      restatementReason       : Sample(1),
      reserved1               : Sample(1),
      numberOfReturnBitfields : 0 .. 255,
      returnBitfield1         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield2         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield3         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield4         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield5         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield6         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield7         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield8         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield9         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield10        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield11        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield12        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield13        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield14        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield15        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield16        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield17        : { << >> } \cup { <<held>> : held \in Sample(1) },
      side                    : { << >> } \cup { <<held>> : held \in Sample(1) },
      priceLong               : { << >> } \cup { <<held>> : held \in Sample(8) },
      execInst                : { << >> } \cup { <<held>> : held \in Sample(1) },
      ordType                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce             : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                  : { << >> } \cup { <<held>> : held \in Sample(4) },
      maxRemovePct            : { << >> } \cup { <<held>> : held \in Sample(1) },
      symbolLong              : { << >> } \cup { <<held>> : held \in Sample(8) },
      capacity                : { << >> } \cup { <<held>> : held \in Sample(1) },
      account                 : { << >> } \cup { <<held>> : held \in Sample(16) },
      clearingFirm            : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingAccount         : { << >> } \cup { <<held>> : held \in Sample(4) },
      displayIndicator        : { << >> } \cup { <<held>> : held \in Sample(1) },
      maxFloor                : { << >> } \cup { <<held>> : held \in Sample(4) },
      orderQtyLong            : { << >> } \cup { <<held>> : held \in Sample(4) },
      preventMatch            : { << >> } \cup { <<held>> : held \in Sample(3) },
      maturityDate            : { << >> } \cup { <<held>> : held \in Sample(4) },
      strikePrice             : { << >> } \cup { <<held>> : held \in Sample(8) },
      putOrCall               : { << >> } \cup { <<held>> : held \in Sample(1) },
      openClose               : { << >> } \cup { <<held>> : held \in Sample(1) },
      correctedSize           : { << >> } \cup { <<held>> : held \in Sample(4) },
      origClOrdId             : { << >> } \cup { <<held>> : held \in Sample(20) },
      leavesQty               : { << >> } \cup { <<held>> : held \in Sample(4) },
      lastShares              : { << >> } \cup { <<held>> : held \in Sample(4) },
      lastPx                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      displayPrice            : { << >> } \cup { <<held>> : held \in Sample(8) },
      workingPrice            : { << >> } \cup { <<held>> : held \in Sample(8) },
      baseLiquidityIndicator  : { << >> } \cup { <<held>> : held \in Sample(1) },
      expireTime              : { << >> } \cup { <<held>> : held \in Sample(8) },
      secondaryOrderId        : { << >> } \cup { <<held>> : held \in Sample(8) },
      contraCapacity          : { << >> } \cup { <<held>> : held \in Sample(1) },
      attributedQuote         : { << >> } \cup { <<held>> : held \in Sample(1) },
      echoText                : { << >> } \cup { <<held>> : held \in Sample(64) },
      stopPx                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      routingInst             : { << >> } \cup { <<held>> : held \in Sample(4) },
      routStrategy            : { << >> } \cup { <<held>> : held \in Sample(6) },
      routeDeliveryMethod     : { << >> } \cup { <<held>> : held \in Sample(3) },
      exDestination           : { << >> } \cup { <<held>> : held \in Sample(1) },
      cmtaNumber              : { << >> } \cup { <<held>> : held \in Sample(4) },
      clientIdAttr            : { << >> } \cup { <<held>> : held \in Sample(4) },
      floorRoutingInst        : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderOrigin             : { << >> } \cup { <<held>> : held \in Sample(3) } ]

EncodeOrderRestatedMessage(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.orderId
        \o message.restatementReason
        \o message.reserved1
        \o EncodeUIntBE(message.numberOfReturnBitfields, 1)
        \o (IF message.returnBitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield1[1], 1))
        \o (IF message.returnBitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield2[1], 1))
        \o (IF message.returnBitfield3 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield3[1], 1))
        \o (IF message.returnBitfield4 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield4[1], 1))
        \o (IF message.returnBitfield5 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield5[1], 1))
        \o (IF message.returnBitfield6 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield6[1], 1))
        \o (IF message.returnBitfield7 = << >> THEN << >> ELSE message.returnBitfield7[1])
        \o (IF message.returnBitfield8 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield8[1], 1))
        \o (IF message.returnBitfield9 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield9[1], 1))
        \o (IF message.returnBitfield10 = << >> THEN << >> ELSE message.returnBitfield10[1])
        \o (IF message.returnBitfield11 = << >> THEN << >> ELSE message.returnBitfield11[1])
        \o (IF message.returnBitfield12 = << >> THEN << >> ELSE message.returnBitfield12[1])
        \o (IF message.returnBitfield13 = << >> THEN << >> ELSE message.returnBitfield13[1])
        \o (IF message.returnBitfield14 = << >> THEN << >> ELSE message.returnBitfield14[1])
        \o (IF message.returnBitfield15 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield15[1], 1))
        \o (IF message.returnBitfield16 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield16[1], 1))
        \o (IF message.returnBitfield17 = << >> THEN << >> ELSE message.returnBitfield17[1])
        \o (IF message.side = << >> THEN << >> ELSE message.side[1])
        \o (IF message.priceLong = << >> THEN << >> ELSE message.priceLong[1])
        \o (IF message.execInst = << >> THEN << >> ELSE message.execInst[1])
        \o (IF message.ordType = << >> THEN << >> ELSE message.ordType[1])
        \o (IF message.timeInForce = << >> THEN << >> ELSE message.timeInForce[1])
        \o (IF message.minQty = << >> THEN << >> ELSE message.minQty[1])
        \o (IF message.maxRemovePct = << >> THEN << >> ELSE message.maxRemovePct[1])
        \o (IF message.symbolLong = << >> THEN << >> ELSE message.symbolLong[1])
        \o (IF message.capacity = << >> THEN << >> ELSE message.capacity[1])
        \o (IF message.account = << >> THEN << >> ELSE message.account[1])
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])
        \o (IF message.clearingAccount = << >> THEN << >> ELSE message.clearingAccount[1])
        \o (IF message.displayIndicator = << >> THEN << >> ELSE message.displayIndicator[1])
        \o (IF message.maxFloor = << >> THEN << >> ELSE message.maxFloor[1])
        \o (IF message.orderQtyLong = << >> THEN << >> ELSE message.orderQtyLong[1])
        \o (IF message.preventMatch = << >> THEN << >> ELSE message.preventMatch[1])
        \o (IF message.maturityDate = << >> THEN << >> ELSE message.maturityDate[1])
        \o (IF message.strikePrice = << >> THEN << >> ELSE message.strikePrice[1])
        \o (IF message.putOrCall = << >> THEN << >> ELSE message.putOrCall[1])
        \o (IF message.openClose = << >> THEN << >> ELSE message.openClose[1])
        \o (IF message.correctedSize = << >> THEN << >> ELSE message.correctedSize[1])
        \o (IF message.origClOrdId = << >> THEN << >> ELSE message.origClOrdId[1])
        \o (IF message.leavesQty = << >> THEN << >> ELSE message.leavesQty[1])
        \o (IF message.lastShares = << >> THEN << >> ELSE message.lastShares[1])
        \o (IF message.lastPx = << >> THEN << >> ELSE message.lastPx[1])
        \o (IF message.displayPrice = << >> THEN << >> ELSE message.displayPrice[1])
        \o (IF message.workingPrice = << >> THEN << >> ELSE message.workingPrice[1])
        \o (IF message.baseLiquidityIndicator = << >> THEN << >> ELSE message.baseLiquidityIndicator[1])
        \o (IF message.expireTime = << >> THEN << >> ELSE message.expireTime[1])
        \o (IF message.secondaryOrderId = << >> THEN << >> ELSE message.secondaryOrderId[1])
        \o (IF message.contraCapacity = << >> THEN << >> ELSE message.contraCapacity[1])
        \o (IF message.attributedQuote = << >> THEN << >> ELSE message.attributedQuote[1])
        \o (IF message.echoText = << >> THEN << >> ELSE message.echoText[1])
        \o (IF message.stopPx = << >> THEN << >> ELSE message.stopPx[1])
        \o (IF message.routingInst = << >> THEN << >> ELSE message.routingInst[1])
        \o (IF message.routStrategy = << >> THEN << >> ELSE message.routStrategy[1])
        \o (IF message.routeDeliveryMethod = << >> THEN << >> ELSE message.routeDeliveryMethod[1])
        \o (IF message.exDestination = << >> THEN << >> ELSE message.exDestination[1])
        \o (IF message.cmtaNumber = << >> THEN << >> ELSE message.cmtaNumber[1])
        \o (IF message.clientIdAttr = << >> THEN << >> ELSE message.clientIdAttr[1])
        \o (IF message.floorRoutingInst = << >> THEN << >> ELSE message.floorRoutingInst[1])
        \o (IF message.orderOrigin = << >> THEN << >> ELSE message.orderOrigin[1])

DecodeOrderRestatedMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clOrdId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET restatementReason == ReadBytes(orderId.rest, 1) IN IF ~restatementReason.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(restatementReason.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET numberOfReturnBitfields == ReadUIntBE(reserved1.rest, 1) IN IF ~numberOfReturnBitfields.ok THEN Fail ELSE
    LET returnBitfield1 == ReadWhen(numberOfReturnBitfields.value >= 1, ReadUIntLE(numberOfReturnBitfields.rest, 1), numberOfReturnBitfields.rest) IN IF ~returnBitfield1.ok THEN Fail ELSE
    LET returnBitfield2 == ReadWhen(numberOfReturnBitfields.value >= 2, ReadUIntLE(returnBitfield1.rest, 1), returnBitfield1.rest) IN IF ~returnBitfield2.ok THEN Fail ELSE
    LET returnBitfield3 == ReadWhen(numberOfReturnBitfields.value >= 3, ReadUIntLE(returnBitfield2.rest, 1), returnBitfield2.rest) IN IF ~returnBitfield3.ok THEN Fail ELSE
    LET returnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadUIntLE(returnBitfield3.rest, 1), returnBitfield3.rest) IN IF ~returnBitfield4.ok THEN Fail ELSE
    LET returnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadUIntLE(returnBitfield4.rest, 1), returnBitfield4.rest) IN IF ~returnBitfield5.ok THEN Fail ELSE
    LET returnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadUIntLE(returnBitfield5.rest, 1), returnBitfield5.rest) IN IF ~returnBitfield6.ok THEN Fail ELSE
    LET returnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadBytes(returnBitfield6.rest, 1), returnBitfield6.rest) IN IF ~returnBitfield7.ok THEN Fail ELSE
    LET returnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadUIntLE(returnBitfield7.rest, 1), returnBitfield7.rest) IN IF ~returnBitfield8.ok THEN Fail ELSE
    LET returnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadUIntLE(returnBitfield8.rest, 1), returnBitfield8.rest) IN IF ~returnBitfield9.ok THEN Fail ELSE
    LET returnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadBytes(returnBitfield9.rest, 1), returnBitfield9.rest) IN IF ~returnBitfield10.ok THEN Fail ELSE
    LET returnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadBytes(returnBitfield10.rest, 1), returnBitfield10.rest) IN IF ~returnBitfield11.ok THEN Fail ELSE
    LET returnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadBytes(returnBitfield11.rest, 1), returnBitfield11.rest) IN IF ~returnBitfield12.ok THEN Fail ELSE
    LET returnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(returnBitfield12.rest, 1), returnBitfield12.rest) IN IF ~returnBitfield13.ok THEN Fail ELSE
    LET returnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(returnBitfield13.rest, 1), returnBitfield13.rest) IN IF ~returnBitfield14.ok THEN Fail ELSE
    LET returnBitfield15 == ReadWhen(numberOfReturnBitfields.value >= 15, ReadUIntLE(returnBitfield14.rest, 1), returnBitfield14.rest) IN IF ~returnBitfield15.ok THEN Fail ELSE
    LET returnBitfield16 == ReadWhen(numberOfReturnBitfields.value >= 16, ReadUIntLE(returnBitfield15.rest, 1), returnBitfield15.rest) IN IF ~returnBitfield16.ok THEN Fail ELSE
    LET returnBitfield17 == ReadWhen(numberOfReturnBitfields.value >= 17, ReadBytes(returnBitfield16.rest, 1), returnBitfield16.rest) IN IF ~returnBitfield17.ok THEN Fail ELSE
    LET side == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ returnBitfield1.value[1] % 2 > 0), ReadBytes(returnBitfield17.rest, 1), returnBitfield17.rest) IN IF ~side.ok THEN Fail ELSE
    LET priceLong == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(side.rest, 8), side.rest) IN IF ~priceLong.ok THEN Fail ELSE
    LET execInst == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 8) % 2 > 0), ReadBytes(priceLong.rest, 1), priceLong.rest) IN IF ~execInst.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(execInst.rest, 1), execInst.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET maxRemovePct == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 128) % 2 > 0), ReadBytes(minQty.rest, 1), minQty.rest) IN IF ~maxRemovePct.ok THEN Fail ELSE
    LET symbolLong == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ returnBitfield2.value[1] % 2 > 0), ReadBytes(maxRemovePct.rest, 8), maxRemovePct.rest) IN IF ~symbolLong.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ (returnBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(symbolLong.rest, 1), symbolLong.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ returnBitfield3.value[1] % 2 > 0), ReadBytes(capacity.rest, 16), capacity.rest) IN IF ~account.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 2) % 2 > 0), ReadBytes(account.rest, 4), account.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 4) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET displayIndicator == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 8) % 2 > 0), ReadBytes(clearingAccount.rest, 1), clearingAccount.rest) IN IF ~displayIndicator.ok THEN Fail ELSE
    LET maxFloor == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 16) % 2 > 0), ReadBytes(displayIndicator.rest, 4), displayIndicator.rest) IN IF ~maxFloor.ok THEN Fail ELSE
    LET orderQtyLong == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 64) % 2 > 0), ReadBytes(maxFloor.rest, 4), maxFloor.rest) IN IF ~orderQtyLong.ok THEN Fail ELSE
    LET preventMatch == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 128) % 2 > 0), ReadBytes(orderQtyLong.rest, 3), orderQtyLong.rest) IN IF ~preventMatch.ok THEN Fail ELSE
    LET maturityDate == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ returnBitfield4.value[1] % 2 > 0), ReadBytes(preventMatch.rest, 4), preventMatch.rest) IN IF ~maturityDate.ok THEN Fail ELSE
    LET strikePrice == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ (returnBitfield4.value[1] \div 2) % 2 > 0), ReadBytes(maturityDate.rest, 8), maturityDate.rest) IN IF ~strikePrice.ok THEN Fail ELSE
    LET putOrCall == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ (returnBitfield4.value[1] \div 4) % 2 > 0), ReadBytes(strikePrice.rest, 1), strikePrice.rest) IN IF ~putOrCall.ok THEN Fail ELSE
    LET openClose == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ (returnBitfield4.value[1] \div 8) % 2 > 0), ReadBytes(putOrCall.rest, 1), putOrCall.rest) IN IF ~openClose.ok THEN Fail ELSE
    LET correctedSize == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ (returnBitfield4.value[1] \div 32) % 2 > 0), ReadBytes(openClose.rest, 4), openClose.rest) IN IF ~correctedSize.ok THEN Fail ELSE
    LET origClOrdId == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ returnBitfield5.value[1] % 2 > 0), ReadBytes(correctedSize.rest, 20), correctedSize.rest) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET leavesQty == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 2) % 2 > 0), ReadBytes(origClOrdId.rest, 4), origClOrdId.rest) IN IF ~leavesQty.ok THEN Fail ELSE
    LET lastShares == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 4) % 2 > 0), ReadBytes(leavesQty.rest, 4), leavesQty.rest) IN IF ~lastShares.ok THEN Fail ELSE
    LET lastPx == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 8) % 2 > 0), ReadBytes(lastShares.rest, 8), lastShares.rest) IN IF ~lastPx.ok THEN Fail ELSE
    LET displayPrice == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 16) % 2 > 0), ReadBytes(lastPx.rest, 8), lastPx.rest) IN IF ~displayPrice.ok THEN Fail ELSE
    LET workingPrice == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 32) % 2 > 0), ReadBytes(displayPrice.rest, 8), displayPrice.rest) IN IF ~workingPrice.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 64) % 2 > 0), ReadBytes(workingPrice.rest, 1), workingPrice.rest) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET expireTime == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 128) % 2 > 0), ReadBytes(baseLiquidityIndicator.rest, 8), baseLiquidityIndicator.rest) IN IF ~expireTime.ok THEN Fail ELSE
    LET secondaryOrderId == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (returnBitfield6.value # << >> /\ returnBitfield6.value[1] % 2 > 0), ReadBytes(expireTime.rest, 8), expireTime.rest) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET contraCapacity == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (returnBitfield6.value # << >> /\ (returnBitfield6.value[1] \div 4) % 2 > 0), ReadBytes(secondaryOrderId.rest, 1), secondaryOrderId.rest) IN IF ~contraCapacity.ok THEN Fail ELSE
    LET attributedQuote == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (returnBitfield6.value # << >> /\ (returnBitfield6.value[1] \div 8) % 2 > 0), ReadBytes(contraCapacity.rest, 1), contraCapacity.rest) IN IF ~attributedQuote.ok THEN Fail ELSE
    LET echoText == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 2) % 2 > 0), ReadBytes(attributedQuote.rest, 64), attributedQuote.rest) IN IF ~echoText.ok THEN Fail ELSE
    LET stopPx == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 4) % 2 > 0), ReadBytes(echoText.rest, 8), echoText.rest) IN IF ~stopPx.ok THEN Fail ELSE
    LET routingInst == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 8) % 2 > 0), ReadBytes(stopPx.rest, 4), stopPx.rest) IN IF ~routingInst.ok THEN Fail ELSE
    LET routStrategy == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 16) % 2 > 0), ReadBytes(routingInst.rest, 6), routingInst.rest) IN IF ~routStrategy.ok THEN Fail ELSE
    LET routeDeliveryMethod == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 32) % 2 > 0), ReadBytes(routStrategy.rest, 3), routStrategy.rest) IN IF ~routeDeliveryMethod.ok THEN Fail ELSE
    LET exDestination == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 64) % 2 > 0), ReadBytes(routeDeliveryMethod.rest, 1), routeDeliveryMethod.rest) IN IF ~exDestination.ok THEN Fail ELSE
    LET cmtaNumber == ReadWhen(numberOfReturnBitfields.value >= 9 /\ (returnBitfield9.value # << >> /\ (returnBitfield9.value[1] \div 32) % 2 > 0), ReadBytes(exDestination.rest, 4), exDestination.rest) IN IF ~cmtaNumber.ok THEN Fail ELSE
    LET clientIdAttr == ReadWhen(numberOfReturnBitfields.value >= 15 /\ (returnBitfield15.value # << >> /\ (returnBitfield15.value[1] \div 128) % 2 > 0), ReadBytes(cmtaNumber.rest, 4), cmtaNumber.rest) IN IF ~clientIdAttr.ok THEN Fail ELSE
    LET floorRoutingInst == ReadWhen(numberOfReturnBitfields.value >= 16 /\ (returnBitfield16.value # << >> /\ (returnBitfield16.value[1] \div 32) % 2 > 0), ReadBytes(clientIdAttr.rest, 1), clientIdAttr.rest) IN IF ~floorRoutingInst.ok THEN Fail ELSE
    LET orderOrigin == ReadWhen(numberOfReturnBitfields.value >= 16 /\ (returnBitfield16.value # << >> /\ (returnBitfield16.value[1] \div 128) % 2 > 0), ReadBytes(floorRoutingInst.rest, 3), floorRoutingInst.rest) IN IF ~orderOrigin.ok THEN Fail ELSE
    Ok([ transactionTime         |-> transactionTime.value,
         clOrdId                 |-> clOrdId.value,
         orderId                 |-> orderId.value,
         restatementReason       |-> restatementReason.value,
         reserved1               |-> reserved1.value,
         numberOfReturnBitfields |-> numberOfReturnBitfields.value,
         returnBitfield1         |-> returnBitfield1.value,
         returnBitfield2         |-> returnBitfield2.value,
         returnBitfield3         |-> returnBitfield3.value,
         returnBitfield4         |-> returnBitfield4.value,
         returnBitfield5         |-> returnBitfield5.value,
         returnBitfield6         |-> returnBitfield6.value,
         returnBitfield7         |-> returnBitfield7.value,
         returnBitfield8         |-> returnBitfield8.value,
         returnBitfield9         |-> returnBitfield9.value,
         returnBitfield10        |-> returnBitfield10.value,
         returnBitfield11        |-> returnBitfield11.value,
         returnBitfield12        |-> returnBitfield12.value,
         returnBitfield13        |-> returnBitfield13.value,
         returnBitfield14        |-> returnBitfield14.value,
         returnBitfield15        |-> returnBitfield15.value,
         returnBitfield16        |-> returnBitfield16.value,
         returnBitfield17        |-> returnBitfield17.value,
         side                    |-> side.value,
         priceLong               |-> priceLong.value,
         execInst                |-> execInst.value,
         ordType                 |-> ordType.value,
         timeInForce             |-> timeInForce.value,
         minQty                  |-> minQty.value,
         maxRemovePct            |-> maxRemovePct.value,
         symbolLong              |-> symbolLong.value,
         capacity                |-> capacity.value,
         account                 |-> account.value,
         clearingFirm            |-> clearingFirm.value,
         clearingAccount         |-> clearingAccount.value,
         displayIndicator        |-> displayIndicator.value,
         maxFloor                |-> maxFloor.value,
         orderQtyLong            |-> orderQtyLong.value,
         preventMatch            |-> preventMatch.value,
         maturityDate            |-> maturityDate.value,
         strikePrice             |-> strikePrice.value,
         putOrCall               |-> putOrCall.value,
         openClose               |-> openClose.value,
         correctedSize           |-> correctedSize.value,
         origClOrdId             |-> origClOrdId.value,
         leavesQty               |-> leavesQty.value,
         lastShares              |-> lastShares.value,
         lastPx                  |-> lastPx.value,
         displayPrice            |-> displayPrice.value,
         workingPrice            |-> workingPrice.value,
         baseLiquidityIndicator  |-> baseLiquidityIndicator.value,
         expireTime              |-> expireTime.value,
         secondaryOrderId        |-> secondaryOrderId.value,
         contraCapacity          |-> contraCapacity.value,
         attributedQuote         |-> attributedQuote.value,
         echoText                |-> echoText.value,
         stopPx                  |-> stopPx.value,
         routingInst             |-> routingInst.value,
         routStrategy            |-> routStrategy.value,
         routeDeliveryMethod     |-> routeDeliveryMethod.value,
         exDestination           |-> exDestination.value,
         cmtaNumber              |-> cmtaNumber.value,
         clientIdAttr            |-> clientIdAttr.value,
         floorRoutingInst        |-> floorRoutingInst.value,
         orderOrigin             |-> orderOrigin.value ], orderOrigin.rest)

(* Order Restated Message with each field marked present by fields before it there exactly where they say *)
SettleOrderRestatedMessage(message) ==
    LET settled1 == [message EXCEPT !.returnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.returnBitfield1 = << >> THEN <<0>> ELSE message.returnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.returnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.returnBitfield2 = << >> THEN <<0>> ELSE settled1.returnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.returnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.returnBitfield3 = << >> THEN <<0>> ELSE settled2.returnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.returnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.returnBitfield4 = << >> THEN <<0>> ELSE settled3.returnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.returnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.returnBitfield5 = << >> THEN <<0>> ELSE settled4.returnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.returnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.returnBitfield6 = << >> THEN <<0>> ELSE settled5.returnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.returnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.returnBitfield7 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.returnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.returnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.returnBitfield8 = << >> THEN <<0>> ELSE settled7.returnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.returnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.returnBitfield9 = << >> THEN <<0>> ELSE settled8.returnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.returnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.returnBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.returnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.returnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.returnBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.returnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.returnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.returnBitfield12 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.returnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.returnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.returnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.returnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.returnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.returnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.returnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.returnBitfield15 = IF settled14.numberOfReturnBitfields >= 15 THEN (IF settled14.returnBitfield15 = << >> THEN <<0>> ELSE settled14.returnBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.returnBitfield16 = IF settled15.numberOfReturnBitfields >= 16 THEN (IF settled15.returnBitfield16 = << >> THEN <<0>> ELSE settled15.returnBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.returnBitfield17 = IF settled16.numberOfReturnBitfields >= 17 THEN (IF settled16.returnBitfield17 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled16.returnBitfield17) ELSE << >>]
        settled18 == [settled17 EXCEPT !.side = IF settled17.numberOfReturnBitfields >= 1 /\ (settled17.returnBitfield1 # << >> /\ settled17.returnBitfield1[1] % 2 > 0) THEN (IF settled17.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.side) ELSE << >>]
        settled19 == [settled18 EXCEPT !.priceLong = IF settled18.numberOfReturnBitfields >= 1 /\ (settled18.returnBitfield1 # << >> /\ (settled18.returnBitfield1[1] \div 4) % 2 > 0) THEN (IF settled18.priceLong = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled18.priceLong) ELSE << >>]
        settled20 == [settled19 EXCEPT !.execInst = IF settled19.numberOfReturnBitfields >= 1 /\ (settled19.returnBitfield1 # << >> /\ (settled19.returnBitfield1[1] \div 8) % 2 > 0) THEN (IF settled19.execInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled19.execInst) ELSE << >>]
        settled21 == [settled20 EXCEPT !.ordType = IF settled20.numberOfReturnBitfields >= 1 /\ (settled20.returnBitfield1 # << >> /\ (settled20.returnBitfield1[1] \div 16) % 2 > 0) THEN (IF settled20.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled20.ordType) ELSE << >>]
        settled22 == [settled21 EXCEPT !.timeInForce = IF settled21.numberOfReturnBitfields >= 1 /\ (settled21.returnBitfield1 # << >> /\ (settled21.returnBitfield1[1] \div 32) % 2 > 0) THEN (IF settled21.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled21.timeInForce) ELSE << >>]
        settled23 == [settled22 EXCEPT !.minQty = IF settled22.numberOfReturnBitfields >= 1 /\ (settled22.returnBitfield1 # << >> /\ (settled22.returnBitfield1[1] \div 64) % 2 > 0) THEN (IF settled22.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled22.minQty) ELSE << >>]
        settled24 == [settled23 EXCEPT !.maxRemovePct = IF settled23.numberOfReturnBitfields >= 1 /\ (settled23.returnBitfield1 # << >> /\ (settled23.returnBitfield1[1] \div 128) % 2 > 0) THEN (IF settled23.maxRemovePct = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled23.maxRemovePct) ELSE << >>]
        settled25 == [settled24 EXCEPT !.symbolLong = IF settled24.numberOfReturnBitfields >= 2 /\ (settled24.returnBitfield2 # << >> /\ settled24.returnBitfield2[1] % 2 > 0) THEN (IF settled24.symbolLong = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled24.symbolLong) ELSE << >>]
        settled26 == [settled25 EXCEPT !.capacity = IF settled25.numberOfReturnBitfields >= 2 /\ (settled25.returnBitfield2 # << >> /\ (settled25.returnBitfield2[1] \div 64) % 2 > 0) THEN (IF settled25.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled25.capacity) ELSE << >>]
        settled27 == [settled26 EXCEPT !.account = IF settled26.numberOfReturnBitfields >= 3 /\ (settled26.returnBitfield3 # << >> /\ settled26.returnBitfield3[1] % 2 > 0) THEN (IF settled26.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled26.account) ELSE << >>]
        settled28 == [settled27 EXCEPT !.clearingFirm = IF settled27.numberOfReturnBitfields >= 3 /\ (settled27.returnBitfield3 # << >> /\ (settled27.returnBitfield3[1] \div 2) % 2 > 0) THEN (IF settled27.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled27.clearingFirm) ELSE << >>]
        settled29 == [settled28 EXCEPT !.clearingAccount = IF settled28.numberOfReturnBitfields >= 3 /\ (settled28.returnBitfield3 # << >> /\ (settled28.returnBitfield3[1] \div 4) % 2 > 0) THEN (IF settled28.clearingAccount = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled28.clearingAccount) ELSE << >>]
        settled30 == [settled29 EXCEPT !.displayIndicator = IF settled29.numberOfReturnBitfields >= 3 /\ (settled29.returnBitfield3 # << >> /\ (settled29.returnBitfield3[1] \div 8) % 2 > 0) THEN (IF settled29.displayIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled29.displayIndicator) ELSE << >>]
        settled31 == [settled30 EXCEPT !.maxFloor = IF settled30.numberOfReturnBitfields >= 3 /\ (settled30.returnBitfield3 # << >> /\ (settled30.returnBitfield3[1] \div 16) % 2 > 0) THEN (IF settled30.maxFloor = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled30.maxFloor) ELSE << >>]
        settled32 == [settled31 EXCEPT !.orderQtyLong = IF settled31.numberOfReturnBitfields >= 3 /\ (settled31.returnBitfield3 # << >> /\ (settled31.returnBitfield3[1] \div 64) % 2 > 0) THEN (IF settled31.orderQtyLong = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled31.orderQtyLong) ELSE << >>]
        settled33 == [settled32 EXCEPT !.preventMatch = IF settled32.numberOfReturnBitfields >= 3 /\ (settled32.returnBitfield3 # << >> /\ (settled32.returnBitfield3[1] \div 128) % 2 > 0) THEN (IF settled32.preventMatch = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled32.preventMatch) ELSE << >>]
        settled34 == [settled33 EXCEPT !.maturityDate = IF settled33.numberOfReturnBitfields >= 4 /\ (settled33.returnBitfield4 # << >> /\ settled33.returnBitfield4[1] % 2 > 0) THEN (IF settled33.maturityDate = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled33.maturityDate) ELSE << >>]
        settled35 == [settled34 EXCEPT !.strikePrice = IF settled34.numberOfReturnBitfields >= 4 /\ (settled34.returnBitfield4 # << >> /\ (settled34.returnBitfield4[1] \div 2) % 2 > 0) THEN (IF settled34.strikePrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled34.strikePrice) ELSE << >>]
        settled36 == [settled35 EXCEPT !.putOrCall = IF settled35.numberOfReturnBitfields >= 4 /\ (settled35.returnBitfield4 # << >> /\ (settled35.returnBitfield4[1] \div 4) % 2 > 0) THEN (IF settled35.putOrCall = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled35.putOrCall) ELSE << >>]
        settled37 == [settled36 EXCEPT !.openClose = IF settled36.numberOfReturnBitfields >= 4 /\ (settled36.returnBitfield4 # << >> /\ (settled36.returnBitfield4[1] \div 8) % 2 > 0) THEN (IF settled36.openClose = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled36.openClose) ELSE << >>]
        settled38 == [settled37 EXCEPT !.correctedSize = IF settled37.numberOfReturnBitfields >= 4 /\ (settled37.returnBitfield4 # << >> /\ (settled37.returnBitfield4[1] \div 32) % 2 > 0) THEN (IF settled37.correctedSize = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled37.correctedSize) ELSE << >>]
        settled39 == [settled38 EXCEPT !.origClOrdId = IF settled38.numberOfReturnBitfields >= 5 /\ (settled38.returnBitfield5 # << >> /\ settled38.returnBitfield5[1] % 2 > 0) THEN (IF settled38.origClOrdId = << >> THEN <<[i \in 1 .. 20 |-> 0]>> ELSE settled38.origClOrdId) ELSE << >>]
        settled40 == [settled39 EXCEPT !.leavesQty = IF settled39.numberOfReturnBitfields >= 5 /\ (settled39.returnBitfield5 # << >> /\ (settled39.returnBitfield5[1] \div 2) % 2 > 0) THEN (IF settled39.leavesQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled39.leavesQty) ELSE << >>]
        settled41 == [settled40 EXCEPT !.lastShares = IF settled40.numberOfReturnBitfields >= 5 /\ (settled40.returnBitfield5 # << >> /\ (settled40.returnBitfield5[1] \div 4) % 2 > 0) THEN (IF settled40.lastShares = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled40.lastShares) ELSE << >>]
        settled42 == [settled41 EXCEPT !.lastPx = IF settled41.numberOfReturnBitfields >= 5 /\ (settled41.returnBitfield5 # << >> /\ (settled41.returnBitfield5[1] \div 8) % 2 > 0) THEN (IF settled41.lastPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled41.lastPx) ELSE << >>]
        settled43 == [settled42 EXCEPT !.displayPrice = IF settled42.numberOfReturnBitfields >= 5 /\ (settled42.returnBitfield5 # << >> /\ (settled42.returnBitfield5[1] \div 16) % 2 > 0) THEN (IF settled42.displayPrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled42.displayPrice) ELSE << >>]
        settled44 == [settled43 EXCEPT !.workingPrice = IF settled43.numberOfReturnBitfields >= 5 /\ (settled43.returnBitfield5 # << >> /\ (settled43.returnBitfield5[1] \div 32) % 2 > 0) THEN (IF settled43.workingPrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled43.workingPrice) ELSE << >>]
        settled45 == [settled44 EXCEPT !.baseLiquidityIndicator = IF settled44.numberOfReturnBitfields >= 5 /\ (settled44.returnBitfield5 # << >> /\ (settled44.returnBitfield5[1] \div 64) % 2 > 0) THEN (IF settled44.baseLiquidityIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled44.baseLiquidityIndicator) ELSE << >>]
        settled46 == [settled45 EXCEPT !.expireTime = IF settled45.numberOfReturnBitfields >= 5 /\ (settled45.returnBitfield5 # << >> /\ (settled45.returnBitfield5[1] \div 128) % 2 > 0) THEN (IF settled45.expireTime = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled45.expireTime) ELSE << >>]
        settled47 == [settled46 EXCEPT !.secondaryOrderId = IF settled46.numberOfReturnBitfields >= 6 /\ (settled46.returnBitfield6 # << >> /\ settled46.returnBitfield6[1] % 2 > 0) THEN (IF settled46.secondaryOrderId = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled46.secondaryOrderId) ELSE << >>]
        settled48 == [settled47 EXCEPT !.contraCapacity = IF settled47.numberOfReturnBitfields >= 6 /\ (settled47.returnBitfield6 # << >> /\ (settled47.returnBitfield6[1] \div 4) % 2 > 0) THEN (IF settled47.contraCapacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled47.contraCapacity) ELSE << >>]
        settled49 == [settled48 EXCEPT !.attributedQuote = IF settled48.numberOfReturnBitfields >= 6 /\ (settled48.returnBitfield6 # << >> /\ (settled48.returnBitfield6[1] \div 8) % 2 > 0) THEN (IF settled48.attributedQuote = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled48.attributedQuote) ELSE << >>]
        settled50 == [settled49 EXCEPT !.echoText = IF settled49.numberOfReturnBitfields >= 8 /\ (settled49.returnBitfield8 # << >> /\ (settled49.returnBitfield8[1] \div 2) % 2 > 0) THEN (IF settled49.echoText = << >> THEN <<[i \in 1 .. 64 |-> 0]>> ELSE settled49.echoText) ELSE << >>]
        settled51 == [settled50 EXCEPT !.stopPx = IF settled50.numberOfReturnBitfields >= 8 /\ (settled50.returnBitfield8 # << >> /\ (settled50.returnBitfield8[1] \div 4) % 2 > 0) THEN (IF settled50.stopPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled50.stopPx) ELSE << >>]
        settled52 == [settled51 EXCEPT !.routingInst = IF settled51.numberOfReturnBitfields >= 8 /\ (settled51.returnBitfield8 # << >> /\ (settled51.returnBitfield8[1] \div 8) % 2 > 0) THEN (IF settled51.routingInst = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled51.routingInst) ELSE << >>]
        settled53 == [settled52 EXCEPT !.routStrategy = IF settled52.numberOfReturnBitfields >= 8 /\ (settled52.returnBitfield8 # << >> /\ (settled52.returnBitfield8[1] \div 16) % 2 > 0) THEN (IF settled52.routStrategy = << >> THEN <<[i \in 1 .. 6 |-> 0]>> ELSE settled52.routStrategy) ELSE << >>]
        settled54 == [settled53 EXCEPT !.routeDeliveryMethod = IF settled53.numberOfReturnBitfields >= 8 /\ (settled53.returnBitfield8 # << >> /\ (settled53.returnBitfield8[1] \div 32) % 2 > 0) THEN (IF settled53.routeDeliveryMethod = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled53.routeDeliveryMethod) ELSE << >>]
        settled55 == [settled54 EXCEPT !.exDestination = IF settled54.numberOfReturnBitfields >= 8 /\ (settled54.returnBitfield8 # << >> /\ (settled54.returnBitfield8[1] \div 64) % 2 > 0) THEN (IF settled54.exDestination = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled54.exDestination) ELSE << >>]
        settled56 == [settled55 EXCEPT !.cmtaNumber = IF settled55.numberOfReturnBitfields >= 9 /\ (settled55.returnBitfield9 # << >> /\ (settled55.returnBitfield9[1] \div 32) % 2 > 0) THEN (IF settled55.cmtaNumber = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled55.cmtaNumber) ELSE << >>]
        settled57 == [settled56 EXCEPT !.clientIdAttr = IF settled56.numberOfReturnBitfields >= 15 /\ (settled56.returnBitfield15 # << >> /\ (settled56.returnBitfield15[1] \div 128) % 2 > 0) THEN (IF settled56.clientIdAttr = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled56.clientIdAttr) ELSE << >>]
        settled58 == [settled57 EXCEPT !.floorRoutingInst = IF settled57.numberOfReturnBitfields >= 16 /\ (settled57.returnBitfield16 # << >> /\ (settled57.returnBitfield16[1] \div 32) % 2 > 0) THEN (IF settled57.floorRoutingInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled57.floorRoutingInst) ELSE << >>]
        settled59 == [settled58 EXCEPT !.orderOrigin = IF settled58.numberOfReturnBitfields >= 16 /\ (settled58.returnBitfield16 # << >> /\ (settled58.returnBitfield16[1] \div 128) % 2 > 0) THEN (IF settled58.orderOrigin = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled58.orderOrigin) ELSE << >>]
    IN  settled59

ZeroOrderRestatedMessage ==
    SettleOrderRestatedMessage([ transactionTime         |-> [i \in 1 .. 8 |-> 0],
                                 clOrdId                 |-> [i \in 1 .. 20 |-> 0],
                                 orderId                 |-> [i \in 1 .. 8 |-> 0],
                                 restatementReason       |-> [i \in 1 .. 1 |-> 0],
                                 reserved1               |-> [i \in 1 .. 1 |-> 0],
                                 numberOfReturnBitfields |-> 0,
                                 returnBitfield1         |-> << >>,
                                 returnBitfield2         |-> << >>,
                                 returnBitfield3         |-> << >>,
                                 returnBitfield4         |-> << >>,
                                 returnBitfield5         |-> << >>,
                                 returnBitfield6         |-> << >>,
                                 returnBitfield7         |-> << >>,
                                 returnBitfield8         |-> << >>,
                                 returnBitfield9         |-> << >>,
                                 returnBitfield10        |-> << >>,
                                 returnBitfield11        |-> << >>,
                                 returnBitfield12        |-> << >>,
                                 returnBitfield13        |-> << >>,
                                 returnBitfield14        |-> << >>,
                                 returnBitfield15        |-> << >>,
                                 returnBitfield16        |-> << >>,
                                 returnBitfield17        |-> << >>,
                                 side                    |-> << >>,
                                 priceLong               |-> << >>,
                                 execInst                |-> << >>,
                                 ordType                 |-> << >>,
                                 timeInForce             |-> << >>,
                                 minQty                  |-> << >>,
                                 maxRemovePct            |-> << >>,
                                 symbolLong              |-> << >>,
                                 capacity                |-> << >>,
                                 account                 |-> << >>,
                                 clearingFirm            |-> << >>,
                                 clearingAccount         |-> << >>,
                                 displayIndicator        |-> << >>,
                                 maxFloor                |-> << >>,
                                 orderQtyLong            |-> << >>,
                                 preventMatch            |-> << >>,
                                 maturityDate            |-> << >>,
                                 strikePrice             |-> << >>,
                                 putOrCall               |-> << >>,
                                 openClose               |-> << >>,
                                 correctedSize           |-> << >>,
                                 origClOrdId             |-> << >>,
                                 leavesQty               |-> << >>,
                                 lastShares              |-> << >>,
                                 lastPx                  |-> << >>,
                                 displayPrice            |-> << >>,
                                 workingPrice            |-> << >>,
                                 baseLiquidityIndicator  |-> << >>,
                                 expireTime              |-> << >>,
                                 secondaryOrderId        |-> << >>,
                                 contraCapacity          |-> << >>,
                                 attributedQuote         |-> << >>,
                                 echoText                |-> << >>,
                                 stopPx                  |-> << >>,
                                 routingInst             |-> << >>,
                                 routStrategy            |-> << >>,
                                 routeDeliveryMethod     |-> << >>,
                                 exDestination           |-> << >>,
                                 cmtaNumber              |-> << >>,
                                 clientIdAttr            |-> << >>,
                                 floorRoutingInst        |-> << >>,
                                 orderOrigin             |-> << >> ])

(* Order Restated Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderRestatedMessage ==
    { ZeroOrderRestatedMessage }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.transactionTime = one]) : one \in Sample(8) }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.clOrdId = one]) : one \in Sample(20) }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.orderId = one]) : one \in Sample(8) }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.restatementReason = one]) : one \in Sample(1) }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.reserved1 = one]) : one \in Sample(1) }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 7, !.returnBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 9, !.returnBitfield9 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 10, !.returnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 11, !.returnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 13, !.returnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 14, !.returnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 15, !.returnBitfield15 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 17, !.returnBitfield17 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<1>>, !.side = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<4>>, !.priceLong = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<8>>, !.execInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<128>>, !.maxRemovePct = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<1>>, !.symbolLong = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<1>>, !.account = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<2>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<4>>, !.clearingAccount = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<8>>, !.displayIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<16>>, !.maxFloor = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<64>>, !.orderQtyLong = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<128>>, !.preventMatch = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<1>>, !.maturityDate = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<2>>, !.strikePrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<4>>, !.putOrCall = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<8>>, !.openClose = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<32>>, !.correctedSize = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<1>>, !.origClOrdId = one]) : one \in { <<held>> : held \in Sample(20) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<2>>, !.leavesQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<4>>, !.lastShares = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<8>>, !.lastPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<16>>, !.displayPrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<32>>, !.workingPrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<64>>, !.baseLiquidityIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<128>>, !.expireTime = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = <<1>>, !.secondaryOrderId = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = <<4>>, !.contraCapacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = <<8>>, !.attributedQuote = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<2>>, !.echoText = one]) : one \in { <<held>> : held \in Sample(64) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<4>>, !.stopPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<8>>, !.routingInst = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<16>>, !.routStrategy = one]) : one \in { <<held>> : held \in Sample(6) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<32>>, !.routeDeliveryMethod = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<64>>, !.exDestination = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 9, !.returnBitfield9 = <<32>>, !.cmtaNumber = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 15, !.returnBitfield15 = <<128>>, !.clientIdAttr = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = <<32>>, !.floorRoutingInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = <<128>>, !.orderOrigin = one]) : one \in { <<held>> : held \in Sample(3) } }

(***************************************************************************)
(* Quote Restated Message: 52 bytes                                        *)
(***************************************************************************)

QuoteRestatedMessage ==
    [ transactionTime        : Sample(8),
      quoteUpdateId          : Sample(16),
      orderId                : Sample(8),
      leavesQty              : Sample(4),
      workingPrice           : Sample(8),
      symbolShort            : Sample(6),
      side                   : Sample(1),
      quoteRestatementReason : Sample(1) ]

EncodeQuoteRestatedMessage(message) ==
    message.transactionTime
        \o message.quoteUpdateId
        \o message.orderId
        \o message.leavesQty
        \o message.workingPrice
        \o message.symbolShort
        \o message.side
        \o message.quoteRestatementReason

DecodeQuoteRestatedMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET quoteUpdateId == ReadBytes(transactionTime.rest, 16) IN IF ~quoteUpdateId.ok THEN Fail ELSE
    LET orderId == ReadBytes(quoteUpdateId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(orderId.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET workingPrice == ReadBytes(leavesQty.rest, 8) IN IF ~workingPrice.ok THEN Fail ELSE
    LET symbolShort == ReadBytes(workingPrice.rest, 6) IN IF ~symbolShort.ok THEN Fail ELSE
    LET side == ReadBytes(symbolShort.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET quoteRestatementReason == ReadBytes(side.rest, 1) IN IF ~quoteRestatementReason.ok THEN Fail ELSE
    Ok([ transactionTime        |-> transactionTime.value,
         quoteUpdateId          |-> quoteUpdateId.value,
         orderId                |-> orderId.value,
         leavesQty              |-> leavesQty.value,
         workingPrice           |-> workingPrice.value,
         symbolShort            |-> symbolShort.value,
         side                   |-> side.value,
         quoteRestatementReason |-> quoteRestatementReason.value ], quoteRestatementReason.rest)

ZeroQuoteRestatedMessage ==
    [ transactionTime        |-> [i \in 1 .. 8 |-> 0],
      quoteUpdateId          |-> [i \in 1 .. 16 |-> 0],
      orderId                |-> [i \in 1 .. 8 |-> 0],
      leavesQty              |-> [i \in 1 .. 4 |-> 0],
      workingPrice           |-> [i \in 1 .. 8 |-> 0],
      symbolShort            |-> [i \in 1 .. 6 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      quoteRestatementReason |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Restated Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteRestatedMessage ==
    { ZeroQuoteRestatedMessage }
        \cup { [ZeroQuoteRestatedMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRestatedMessage EXCEPT !.quoteUpdateId = one] : one \in Sample(16) }
        \cup { [ZeroQuoteRestatedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRestatedMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRestatedMessage EXCEPT !.workingPrice = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRestatedMessage EXCEPT !.symbolShort = one] : one \in Sample(6) }
        \cup { [ZeroQuoteRestatedMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRestatedMessage EXCEPT !.quoteRestatementReason = one] : one \in Sample(1) }

(***************************************************************************)
(* User Modify Rejected Message                                            *)
(***************************************************************************)

UserModifyRejectedMessage ==
    [ transactionTime         : Sample(8),
      clOrdId                 : Sample(20),
      modifyRejectReason      : Sample(1),
      text                    : Sample(60),
      reserved1               : Sample(1),
      numberOfReturnBitfields : 0 .. 255,
      returnBitfield1         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield2         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield3         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield4         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield5         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield6         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield7         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield8         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield9         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield10        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield11        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield12        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield13        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield14        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield15        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield16        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield17        : { << >> } \cup { <<held>> : held \in Sample(1) } ]

EncodeUserModifyRejectedMessage(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.modifyRejectReason
        \o message.text
        \o message.reserved1
        \o EncodeUIntBE(message.numberOfReturnBitfields, 1)
        \o (IF message.returnBitfield1 = << >> THEN << >> ELSE message.returnBitfield1[1])
        \o (IF message.returnBitfield2 = << >> THEN << >> ELSE message.returnBitfield2[1])
        \o (IF message.returnBitfield3 = << >> THEN << >> ELSE message.returnBitfield3[1])
        \o (IF message.returnBitfield4 = << >> THEN << >> ELSE message.returnBitfield4[1])
        \o (IF message.returnBitfield5 = << >> THEN << >> ELSE message.returnBitfield5[1])
        \o (IF message.returnBitfield6 = << >> THEN << >> ELSE message.returnBitfield6[1])
        \o (IF message.returnBitfield7 = << >> THEN << >> ELSE message.returnBitfield7[1])
        \o (IF message.returnBitfield8 = << >> THEN << >> ELSE message.returnBitfield8[1])
        \o (IF message.returnBitfield9 = << >> THEN << >> ELSE message.returnBitfield9[1])
        \o (IF message.returnBitfield10 = << >> THEN << >> ELSE message.returnBitfield10[1])
        \o (IF message.returnBitfield11 = << >> THEN << >> ELSE message.returnBitfield11[1])
        \o (IF message.returnBitfield12 = << >> THEN << >> ELSE message.returnBitfield12[1])
        \o (IF message.returnBitfield13 = << >> THEN << >> ELSE message.returnBitfield13[1])
        \o (IF message.returnBitfield14 = << >> THEN << >> ELSE message.returnBitfield14[1])
        \o (IF message.returnBitfield15 = << >> THEN << >> ELSE message.returnBitfield15[1])
        \o (IF message.returnBitfield16 = << >> THEN << >> ELSE message.returnBitfield16[1])
        \o (IF message.returnBitfield17 = << >> THEN << >> ELSE message.returnBitfield17[1])

DecodeUserModifyRejectedMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET modifyRejectReason == ReadBytes(clOrdId.rest, 1) IN IF ~modifyRejectReason.ok THEN Fail ELSE
    LET text == ReadBytes(modifyRejectReason.rest, 60) IN IF ~text.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(text.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET numberOfReturnBitfields == ReadUIntBE(reserved1.rest, 1) IN IF ~numberOfReturnBitfields.ok THEN Fail ELSE
    LET returnBitfield1 == ReadWhen(numberOfReturnBitfields.value >= 1, ReadBytes(numberOfReturnBitfields.rest, 1), numberOfReturnBitfields.rest) IN IF ~returnBitfield1.ok THEN Fail ELSE
    LET returnBitfield2 == ReadWhen(numberOfReturnBitfields.value >= 2, ReadBytes(returnBitfield1.rest, 1), returnBitfield1.rest) IN IF ~returnBitfield2.ok THEN Fail ELSE
    LET returnBitfield3 == ReadWhen(numberOfReturnBitfields.value >= 3, ReadBytes(returnBitfield2.rest, 1), returnBitfield2.rest) IN IF ~returnBitfield3.ok THEN Fail ELSE
    LET returnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadBytes(returnBitfield3.rest, 1), returnBitfield3.rest) IN IF ~returnBitfield4.ok THEN Fail ELSE
    LET returnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadBytes(returnBitfield4.rest, 1), returnBitfield4.rest) IN IF ~returnBitfield5.ok THEN Fail ELSE
    LET returnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadBytes(returnBitfield5.rest, 1), returnBitfield5.rest) IN IF ~returnBitfield6.ok THEN Fail ELSE
    LET returnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadBytes(returnBitfield6.rest, 1), returnBitfield6.rest) IN IF ~returnBitfield7.ok THEN Fail ELSE
    LET returnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadBytes(returnBitfield7.rest, 1), returnBitfield7.rest) IN IF ~returnBitfield8.ok THEN Fail ELSE
    LET returnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadBytes(returnBitfield8.rest, 1), returnBitfield8.rest) IN IF ~returnBitfield9.ok THEN Fail ELSE
    LET returnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadBytes(returnBitfield9.rest, 1), returnBitfield9.rest) IN IF ~returnBitfield10.ok THEN Fail ELSE
    LET returnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadBytes(returnBitfield10.rest, 1), returnBitfield10.rest) IN IF ~returnBitfield11.ok THEN Fail ELSE
    LET returnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadBytes(returnBitfield11.rest, 1), returnBitfield11.rest) IN IF ~returnBitfield12.ok THEN Fail ELSE
    LET returnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(returnBitfield12.rest, 1), returnBitfield12.rest) IN IF ~returnBitfield13.ok THEN Fail ELSE
    LET returnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(returnBitfield13.rest, 1), returnBitfield13.rest) IN IF ~returnBitfield14.ok THEN Fail ELSE
    LET returnBitfield15 == ReadWhen(numberOfReturnBitfields.value >= 15, ReadBytes(returnBitfield14.rest, 1), returnBitfield14.rest) IN IF ~returnBitfield15.ok THEN Fail ELSE
    LET returnBitfield16 == ReadWhen(numberOfReturnBitfields.value >= 16, ReadBytes(returnBitfield15.rest, 1), returnBitfield15.rest) IN IF ~returnBitfield16.ok THEN Fail ELSE
    LET returnBitfield17 == ReadWhen(numberOfReturnBitfields.value >= 17, ReadBytes(returnBitfield16.rest, 1), returnBitfield16.rest) IN IF ~returnBitfield17.ok THEN Fail ELSE
    Ok([ transactionTime         |-> transactionTime.value,
         clOrdId                 |-> clOrdId.value,
         modifyRejectReason      |-> modifyRejectReason.value,
         text                    |-> text.value,
         reserved1               |-> reserved1.value,
         numberOfReturnBitfields |-> numberOfReturnBitfields.value,
         returnBitfield1         |-> returnBitfield1.value,
         returnBitfield2         |-> returnBitfield2.value,
         returnBitfield3         |-> returnBitfield3.value,
         returnBitfield4         |-> returnBitfield4.value,
         returnBitfield5         |-> returnBitfield5.value,
         returnBitfield6         |-> returnBitfield6.value,
         returnBitfield7         |-> returnBitfield7.value,
         returnBitfield8         |-> returnBitfield8.value,
         returnBitfield9         |-> returnBitfield9.value,
         returnBitfield10        |-> returnBitfield10.value,
         returnBitfield11        |-> returnBitfield11.value,
         returnBitfield12        |-> returnBitfield12.value,
         returnBitfield13        |-> returnBitfield13.value,
         returnBitfield14        |-> returnBitfield14.value,
         returnBitfield15        |-> returnBitfield15.value,
         returnBitfield16        |-> returnBitfield16.value,
         returnBitfield17        |-> returnBitfield17.value ], returnBitfield17.rest)

(* User Modify Rejected Message with each field marked present by fields before it there exactly where they say *)
SettleUserModifyRejectedMessage(message) ==
    LET settled1 == [message EXCEPT !.returnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.returnBitfield1 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE message.returnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.returnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.returnBitfield2 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled1.returnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.returnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.returnBitfield3 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled2.returnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.returnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.returnBitfield4 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled3.returnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.returnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.returnBitfield5 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled4.returnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.returnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.returnBitfield6 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled5.returnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.returnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.returnBitfield7 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.returnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.returnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.returnBitfield8 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled7.returnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.returnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.returnBitfield9 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled8.returnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.returnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.returnBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.returnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.returnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.returnBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.returnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.returnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.returnBitfield12 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.returnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.returnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.returnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.returnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.returnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.returnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.returnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.returnBitfield15 = IF settled14.numberOfReturnBitfields >= 15 THEN (IF settled14.returnBitfield15 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.returnBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.returnBitfield16 = IF settled15.numberOfReturnBitfields >= 16 THEN (IF settled15.returnBitfield16 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled15.returnBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.returnBitfield17 = IF settled16.numberOfReturnBitfields >= 17 THEN (IF settled16.returnBitfield17 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled16.returnBitfield17) ELSE << >>]
    IN  settled17

ZeroUserModifyRejectedMessage ==
    SettleUserModifyRejectedMessage([ transactionTime         |-> [i \in 1 .. 8 |-> 0],
                                      clOrdId                 |-> [i \in 1 .. 20 |-> 0],
                                      modifyRejectReason      |-> [i \in 1 .. 1 |-> 0],
                                      text                    |-> [i \in 1 .. 60 |-> 0],
                                      reserved1               |-> [i \in 1 .. 1 |-> 0],
                                      numberOfReturnBitfields |-> 0,
                                      returnBitfield1         |-> << >>,
                                      returnBitfield2         |-> << >>,
                                      returnBitfield3         |-> << >>,
                                      returnBitfield4         |-> << >>,
                                      returnBitfield5         |-> << >>,
                                      returnBitfield6         |-> << >>,
                                      returnBitfield7         |-> << >>,
                                      returnBitfield8         |-> << >>,
                                      returnBitfield9         |-> << >>,
                                      returnBitfield10        |-> << >>,
                                      returnBitfield11        |-> << >>,
                                      returnBitfield12        |-> << >>,
                                      returnBitfield13        |-> << >>,
                                      returnBitfield14        |-> << >>,
                                      returnBitfield15        |-> << >>,
                                      returnBitfield16        |-> << >>,
                                      returnBitfield17        |-> << >> ])

(* User Modify Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedUserModifyRejectedMessage ==
    { ZeroUserModifyRejectedMessage }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.transactionTime = one]) : one \in Sample(8) }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.clOrdId = one]) : one \in Sample(20) }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.modifyRejectReason = one]) : one \in Sample(1) }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.text = one]) : one \in Sample(60) }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.reserved1 = one]) : one \in Sample(1) }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.numberOfReturnBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.numberOfReturnBitfields = 7, !.returnBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.numberOfReturnBitfields = 9, !.returnBitfield9 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.numberOfReturnBitfields = 10, !.returnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.numberOfReturnBitfields = 11, !.returnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.numberOfReturnBitfields = 13, !.returnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.numberOfReturnBitfields = 14, !.returnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.numberOfReturnBitfields = 15, !.returnBitfield15 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.numberOfReturnBitfields = 17, !.returnBitfield17 = one]) : one \in { <<held>> : held \in Sample(1) } }

(***************************************************************************)
(* Order Cancelled Message                                                 *)
(***************************************************************************)

OrderCancelledMessage ==
    [ transactTime            : Sample(8),
      clOrdId                 : Sample(20),
      cancelReason            : Sample(1),
      reserved1               : Sample(1),
      numberOfReturnBitfields : 0 .. 255,
      returnBitfield1         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield2         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield3         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield4         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield5         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield6         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield7         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield8         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield9         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield10        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield11        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield12        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield13        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield14        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield15        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield16        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield17        : { << >> } \cup { <<held>> : held \in Sample(1) },
      side                    : { << >> } \cup { <<held>> : held \in Sample(1) },
      priceLong               : { << >> } \cup { <<held>> : held \in Sample(8) },
      execInst                : { << >> } \cup { <<held>> : held \in Sample(1) },
      ordType                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce             : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                  : { << >> } \cup { <<held>> : held \in Sample(4) },
      maxRemovePct            : { << >> } \cup { <<held>> : held \in Sample(1) },
      symbolLong              : { << >> } \cup { <<held>> : held \in Sample(8) },
      capacity                : { << >> } \cup { <<held>> : held \in Sample(1) },
      account                 : { << >> } \cup { <<held>> : held \in Sample(16) },
      clearingFirm            : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingAccount         : { << >> } \cup { <<held>> : held \in Sample(4) },
      displayIndicator        : { << >> } \cup { <<held>> : held \in Sample(1) },
      maxFloor                : { << >> } \cup { <<held>> : held \in Sample(4) },
      orderQtyLong            : { << >> } \cup { <<held>> : held \in Sample(4) },
      preventMatch            : { << >> } \cup { <<held>> : held \in Sample(3) },
      maturityDate            : { << >> } \cup { <<held>> : held \in Sample(4) },
      strikePrice             : { << >> } \cup { <<held>> : held \in Sample(8) },
      putOrCall               : { << >> } \cup { <<held>> : held \in Sample(1) },
      openClose               : { << >> } \cup { <<held>> : held \in Sample(1) },
      correctedSize           : { << >> } \cup { <<held>> : held \in Sample(4) },
      origClOrdId             : { << >> } \cup { <<held>> : held \in Sample(20) },
      leavesQty               : { << >> } \cup { <<held>> : held \in Sample(4) },
      lastShares              : { << >> } \cup { <<held>> : held \in Sample(4) },
      lastPx                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      displayPrice            : { << >> } \cup { <<held>> : held \in Sample(8) },
      workingPrice            : { << >> } \cup { <<held>> : held \in Sample(8) },
      baseLiquidityIndicator  : { << >> } \cup { <<held>> : held \in Sample(1) },
      expireTime              : { << >> } \cup { <<held>> : held \in Sample(8) },
      secondaryOrderId        : { << >> } \cup { <<held>> : held \in Sample(8) },
      contraCapacity          : { << >> } \cup { <<held>> : held \in Sample(1) },
      attributedQuote         : { << >> } \cup { <<held>> : held \in Sample(1) },
      echoText                : { << >> } \cup { <<held>> : held \in Sample(64) },
      stopPx                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      routingInst             : { << >> } \cup { <<held>> : held \in Sample(4) },
      routStrategy            : { << >> } \cup { <<held>> : held \in Sample(6) },
      routeDeliveryMethod     : { << >> } \cup { <<held>> : held \in Sample(3) },
      exDestination           : { << >> } \cup { <<held>> : held \in Sample(1) },
      cmtaNumber              : { << >> } \cup { <<held>> : held \in Sample(4) },
      floorRoutingInst        : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderOrigin             : { << >> } \cup { <<held>> : held \in Sample(3) } ]

EncodeOrderCancelledMessage(message) ==
    message.transactTime
        \o message.clOrdId
        \o message.cancelReason
        \o message.reserved1
        \o EncodeUIntBE(message.numberOfReturnBitfields, 1)
        \o (IF message.returnBitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield1[1], 1))
        \o (IF message.returnBitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield2[1], 1))
        \o (IF message.returnBitfield3 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield3[1], 1))
        \o (IF message.returnBitfield4 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield4[1], 1))
        \o (IF message.returnBitfield5 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield5[1], 1))
        \o (IF message.returnBitfield6 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield6[1], 1))
        \o (IF message.returnBitfield7 = << >> THEN << >> ELSE message.returnBitfield7[1])
        \o (IF message.returnBitfield8 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield8[1], 1))
        \o (IF message.returnBitfield9 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield9[1], 1))
        \o (IF message.returnBitfield10 = << >> THEN << >> ELSE message.returnBitfield10[1])
        \o (IF message.returnBitfield11 = << >> THEN << >> ELSE message.returnBitfield11[1])
        \o (IF message.returnBitfield12 = << >> THEN << >> ELSE message.returnBitfield12[1])
        \o (IF message.returnBitfield13 = << >> THEN << >> ELSE message.returnBitfield13[1])
        \o (IF message.returnBitfield14 = << >> THEN << >> ELSE message.returnBitfield14[1])
        \o (IF message.returnBitfield15 = << >> THEN << >> ELSE message.returnBitfield15[1])
        \o (IF message.returnBitfield16 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield16[1], 1))
        \o (IF message.returnBitfield17 = << >> THEN << >> ELSE message.returnBitfield17[1])
        \o (IF message.side = << >> THEN << >> ELSE message.side[1])
        \o (IF message.priceLong = << >> THEN << >> ELSE message.priceLong[1])
        \o (IF message.execInst = << >> THEN << >> ELSE message.execInst[1])
        \o (IF message.ordType = << >> THEN << >> ELSE message.ordType[1])
        \o (IF message.timeInForce = << >> THEN << >> ELSE message.timeInForce[1])
        \o (IF message.minQty = << >> THEN << >> ELSE message.minQty[1])
        \o (IF message.maxRemovePct = << >> THEN << >> ELSE message.maxRemovePct[1])
        \o (IF message.symbolLong = << >> THEN << >> ELSE message.symbolLong[1])
        \o (IF message.capacity = << >> THEN << >> ELSE message.capacity[1])
        \o (IF message.account = << >> THEN << >> ELSE message.account[1])
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])
        \o (IF message.clearingAccount = << >> THEN << >> ELSE message.clearingAccount[1])
        \o (IF message.displayIndicator = << >> THEN << >> ELSE message.displayIndicator[1])
        \o (IF message.maxFloor = << >> THEN << >> ELSE message.maxFloor[1])
        \o (IF message.orderQtyLong = << >> THEN << >> ELSE message.orderQtyLong[1])
        \o (IF message.preventMatch = << >> THEN << >> ELSE message.preventMatch[1])
        \o (IF message.maturityDate = << >> THEN << >> ELSE message.maturityDate[1])
        \o (IF message.strikePrice = << >> THEN << >> ELSE message.strikePrice[1])
        \o (IF message.putOrCall = << >> THEN << >> ELSE message.putOrCall[1])
        \o (IF message.openClose = << >> THEN << >> ELSE message.openClose[1])
        \o (IF message.correctedSize = << >> THEN << >> ELSE message.correctedSize[1])
        \o (IF message.origClOrdId = << >> THEN << >> ELSE message.origClOrdId[1])
        \o (IF message.leavesQty = << >> THEN << >> ELSE message.leavesQty[1])
        \o (IF message.lastShares = << >> THEN << >> ELSE message.lastShares[1])
        \o (IF message.lastPx = << >> THEN << >> ELSE message.lastPx[1])
        \o (IF message.displayPrice = << >> THEN << >> ELSE message.displayPrice[1])
        \o (IF message.workingPrice = << >> THEN << >> ELSE message.workingPrice[1])
        \o (IF message.baseLiquidityIndicator = << >> THEN << >> ELSE message.baseLiquidityIndicator[1])
        \o (IF message.expireTime = << >> THEN << >> ELSE message.expireTime[1])
        \o (IF message.secondaryOrderId = << >> THEN << >> ELSE message.secondaryOrderId[1])
        \o (IF message.contraCapacity = << >> THEN << >> ELSE message.contraCapacity[1])
        \o (IF message.attributedQuote = << >> THEN << >> ELSE message.attributedQuote[1])
        \o (IF message.echoText = << >> THEN << >> ELSE message.echoText[1])
        \o (IF message.stopPx = << >> THEN << >> ELSE message.stopPx[1])
        \o (IF message.routingInst = << >> THEN << >> ELSE message.routingInst[1])
        \o (IF message.routStrategy = << >> THEN << >> ELSE message.routStrategy[1])
        \o (IF message.routeDeliveryMethod = << >> THEN << >> ELSE message.routeDeliveryMethod[1])
        \o (IF message.exDestination = << >> THEN << >> ELSE message.exDestination[1])
        \o (IF message.cmtaNumber = << >> THEN << >> ELSE message.cmtaNumber[1])
        \o (IF message.floorRoutingInst = << >> THEN << >> ELSE message.floorRoutingInst[1])
        \o (IF message.orderOrigin = << >> THEN << >> ELSE message.orderOrigin[1])

DecodeOrderCancelledMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET cancelReason == ReadBytes(clOrdId.rest, 1) IN IF ~cancelReason.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(cancelReason.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET numberOfReturnBitfields == ReadUIntBE(reserved1.rest, 1) IN IF ~numberOfReturnBitfields.ok THEN Fail ELSE
    LET returnBitfield1 == ReadWhen(numberOfReturnBitfields.value >= 1, ReadUIntLE(numberOfReturnBitfields.rest, 1), numberOfReturnBitfields.rest) IN IF ~returnBitfield1.ok THEN Fail ELSE
    LET returnBitfield2 == ReadWhen(numberOfReturnBitfields.value >= 2, ReadUIntLE(returnBitfield1.rest, 1), returnBitfield1.rest) IN IF ~returnBitfield2.ok THEN Fail ELSE
    LET returnBitfield3 == ReadWhen(numberOfReturnBitfields.value >= 3, ReadUIntLE(returnBitfield2.rest, 1), returnBitfield2.rest) IN IF ~returnBitfield3.ok THEN Fail ELSE
    LET returnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadUIntLE(returnBitfield3.rest, 1), returnBitfield3.rest) IN IF ~returnBitfield4.ok THEN Fail ELSE
    LET returnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadUIntLE(returnBitfield4.rest, 1), returnBitfield4.rest) IN IF ~returnBitfield5.ok THEN Fail ELSE
    LET returnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadUIntLE(returnBitfield5.rest, 1), returnBitfield5.rest) IN IF ~returnBitfield6.ok THEN Fail ELSE
    LET returnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadBytes(returnBitfield6.rest, 1), returnBitfield6.rest) IN IF ~returnBitfield7.ok THEN Fail ELSE
    LET returnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadUIntLE(returnBitfield7.rest, 1), returnBitfield7.rest) IN IF ~returnBitfield8.ok THEN Fail ELSE
    LET returnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadUIntLE(returnBitfield8.rest, 1), returnBitfield8.rest) IN IF ~returnBitfield9.ok THEN Fail ELSE
    LET returnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadBytes(returnBitfield9.rest, 1), returnBitfield9.rest) IN IF ~returnBitfield10.ok THEN Fail ELSE
    LET returnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadBytes(returnBitfield10.rest, 1), returnBitfield10.rest) IN IF ~returnBitfield11.ok THEN Fail ELSE
    LET returnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadBytes(returnBitfield11.rest, 1), returnBitfield11.rest) IN IF ~returnBitfield12.ok THEN Fail ELSE
    LET returnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(returnBitfield12.rest, 1), returnBitfield12.rest) IN IF ~returnBitfield13.ok THEN Fail ELSE
    LET returnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(returnBitfield13.rest, 1), returnBitfield13.rest) IN IF ~returnBitfield14.ok THEN Fail ELSE
    LET returnBitfield15 == ReadWhen(numberOfReturnBitfields.value >= 15, ReadBytes(returnBitfield14.rest, 1), returnBitfield14.rest) IN IF ~returnBitfield15.ok THEN Fail ELSE
    LET returnBitfield16 == ReadWhen(numberOfReturnBitfields.value >= 16, ReadUIntLE(returnBitfield15.rest, 1), returnBitfield15.rest) IN IF ~returnBitfield16.ok THEN Fail ELSE
    LET returnBitfield17 == ReadWhen(numberOfReturnBitfields.value >= 17, ReadBytes(returnBitfield16.rest, 1), returnBitfield16.rest) IN IF ~returnBitfield17.ok THEN Fail ELSE
    LET side == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ returnBitfield1.value[1] % 2 > 0), ReadBytes(returnBitfield17.rest, 1), returnBitfield17.rest) IN IF ~side.ok THEN Fail ELSE
    LET priceLong == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(side.rest, 8), side.rest) IN IF ~priceLong.ok THEN Fail ELSE
    LET execInst == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 8) % 2 > 0), ReadBytes(priceLong.rest, 1), priceLong.rest) IN IF ~execInst.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(execInst.rest, 1), execInst.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET maxRemovePct == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 128) % 2 > 0), ReadBytes(minQty.rest, 1), minQty.rest) IN IF ~maxRemovePct.ok THEN Fail ELSE
    LET symbolLong == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ returnBitfield2.value[1] % 2 > 0), ReadBytes(maxRemovePct.rest, 8), maxRemovePct.rest) IN IF ~symbolLong.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ (returnBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(symbolLong.rest, 1), symbolLong.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ returnBitfield3.value[1] % 2 > 0), ReadBytes(capacity.rest, 16), capacity.rest) IN IF ~account.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 2) % 2 > 0), ReadBytes(account.rest, 4), account.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 4) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET displayIndicator == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 8) % 2 > 0), ReadBytes(clearingAccount.rest, 1), clearingAccount.rest) IN IF ~displayIndicator.ok THEN Fail ELSE
    LET maxFloor == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 16) % 2 > 0), ReadBytes(displayIndicator.rest, 4), displayIndicator.rest) IN IF ~maxFloor.ok THEN Fail ELSE
    LET orderQtyLong == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 64) % 2 > 0), ReadBytes(maxFloor.rest, 4), maxFloor.rest) IN IF ~orderQtyLong.ok THEN Fail ELSE
    LET preventMatch == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 128) % 2 > 0), ReadBytes(orderQtyLong.rest, 3), orderQtyLong.rest) IN IF ~preventMatch.ok THEN Fail ELSE
    LET maturityDate == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ returnBitfield4.value[1] % 2 > 0), ReadBytes(preventMatch.rest, 4), preventMatch.rest) IN IF ~maturityDate.ok THEN Fail ELSE
    LET strikePrice == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ (returnBitfield4.value[1] \div 2) % 2 > 0), ReadBytes(maturityDate.rest, 8), maturityDate.rest) IN IF ~strikePrice.ok THEN Fail ELSE
    LET putOrCall == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ (returnBitfield4.value[1] \div 4) % 2 > 0), ReadBytes(strikePrice.rest, 1), strikePrice.rest) IN IF ~putOrCall.ok THEN Fail ELSE
    LET openClose == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ (returnBitfield4.value[1] \div 8) % 2 > 0), ReadBytes(putOrCall.rest, 1), putOrCall.rest) IN IF ~openClose.ok THEN Fail ELSE
    LET correctedSize == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ (returnBitfield4.value[1] \div 32) % 2 > 0), ReadBytes(openClose.rest, 4), openClose.rest) IN IF ~correctedSize.ok THEN Fail ELSE
    LET origClOrdId == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ returnBitfield5.value[1] % 2 > 0), ReadBytes(correctedSize.rest, 20), correctedSize.rest) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET leavesQty == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 2) % 2 > 0), ReadBytes(origClOrdId.rest, 4), origClOrdId.rest) IN IF ~leavesQty.ok THEN Fail ELSE
    LET lastShares == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 4) % 2 > 0), ReadBytes(leavesQty.rest, 4), leavesQty.rest) IN IF ~lastShares.ok THEN Fail ELSE
    LET lastPx == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 8) % 2 > 0), ReadBytes(lastShares.rest, 8), lastShares.rest) IN IF ~lastPx.ok THEN Fail ELSE
    LET displayPrice == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 16) % 2 > 0), ReadBytes(lastPx.rest, 8), lastPx.rest) IN IF ~displayPrice.ok THEN Fail ELSE
    LET workingPrice == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 32) % 2 > 0), ReadBytes(displayPrice.rest, 8), displayPrice.rest) IN IF ~workingPrice.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 64) % 2 > 0), ReadBytes(workingPrice.rest, 1), workingPrice.rest) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET expireTime == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 128) % 2 > 0), ReadBytes(baseLiquidityIndicator.rest, 8), baseLiquidityIndicator.rest) IN IF ~expireTime.ok THEN Fail ELSE
    LET secondaryOrderId == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (returnBitfield6.value # << >> /\ returnBitfield6.value[1] % 2 > 0), ReadBytes(expireTime.rest, 8), expireTime.rest) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET contraCapacity == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (returnBitfield6.value # << >> /\ (returnBitfield6.value[1] \div 4) % 2 > 0), ReadBytes(secondaryOrderId.rest, 1), secondaryOrderId.rest) IN IF ~contraCapacity.ok THEN Fail ELSE
    LET attributedQuote == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (returnBitfield6.value # << >> /\ (returnBitfield6.value[1] \div 8) % 2 > 0), ReadBytes(contraCapacity.rest, 1), contraCapacity.rest) IN IF ~attributedQuote.ok THEN Fail ELSE
    LET echoText == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 2) % 2 > 0), ReadBytes(attributedQuote.rest, 64), attributedQuote.rest) IN IF ~echoText.ok THEN Fail ELSE
    LET stopPx == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 4) % 2 > 0), ReadBytes(echoText.rest, 8), echoText.rest) IN IF ~stopPx.ok THEN Fail ELSE
    LET routingInst == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 8) % 2 > 0), ReadBytes(stopPx.rest, 4), stopPx.rest) IN IF ~routingInst.ok THEN Fail ELSE
    LET routStrategy == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 16) % 2 > 0), ReadBytes(routingInst.rest, 6), routingInst.rest) IN IF ~routStrategy.ok THEN Fail ELSE
    LET routeDeliveryMethod == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 32) % 2 > 0), ReadBytes(routStrategy.rest, 3), routStrategy.rest) IN IF ~routeDeliveryMethod.ok THEN Fail ELSE
    LET exDestination == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 64) % 2 > 0), ReadBytes(routeDeliveryMethod.rest, 1), routeDeliveryMethod.rest) IN IF ~exDestination.ok THEN Fail ELSE
    LET cmtaNumber == ReadWhen(numberOfReturnBitfields.value >= 9 /\ (returnBitfield9.value # << >> /\ (returnBitfield9.value[1] \div 32) % 2 > 0), ReadBytes(exDestination.rest, 4), exDestination.rest) IN IF ~cmtaNumber.ok THEN Fail ELSE
    LET floorRoutingInst == ReadWhen(numberOfReturnBitfields.value >= 16 /\ (returnBitfield16.value # << >> /\ (returnBitfield16.value[1] \div 32) % 2 > 0), ReadBytes(cmtaNumber.rest, 1), cmtaNumber.rest) IN IF ~floorRoutingInst.ok THEN Fail ELSE
    LET orderOrigin == ReadWhen(numberOfReturnBitfields.value >= 16 /\ (returnBitfield16.value # << >> /\ (returnBitfield16.value[1] \div 128) % 2 > 0), ReadBytes(floorRoutingInst.rest, 3), floorRoutingInst.rest) IN IF ~orderOrigin.ok THEN Fail ELSE
    Ok([ transactTime            |-> transactTime.value,
         clOrdId                 |-> clOrdId.value,
         cancelReason            |-> cancelReason.value,
         reserved1               |-> reserved1.value,
         numberOfReturnBitfields |-> numberOfReturnBitfields.value,
         returnBitfield1         |-> returnBitfield1.value,
         returnBitfield2         |-> returnBitfield2.value,
         returnBitfield3         |-> returnBitfield3.value,
         returnBitfield4         |-> returnBitfield4.value,
         returnBitfield5         |-> returnBitfield5.value,
         returnBitfield6         |-> returnBitfield6.value,
         returnBitfield7         |-> returnBitfield7.value,
         returnBitfield8         |-> returnBitfield8.value,
         returnBitfield9         |-> returnBitfield9.value,
         returnBitfield10        |-> returnBitfield10.value,
         returnBitfield11        |-> returnBitfield11.value,
         returnBitfield12        |-> returnBitfield12.value,
         returnBitfield13        |-> returnBitfield13.value,
         returnBitfield14        |-> returnBitfield14.value,
         returnBitfield15        |-> returnBitfield15.value,
         returnBitfield16        |-> returnBitfield16.value,
         returnBitfield17        |-> returnBitfield17.value,
         side                    |-> side.value,
         priceLong               |-> priceLong.value,
         execInst                |-> execInst.value,
         ordType                 |-> ordType.value,
         timeInForce             |-> timeInForce.value,
         minQty                  |-> minQty.value,
         maxRemovePct            |-> maxRemovePct.value,
         symbolLong              |-> symbolLong.value,
         capacity                |-> capacity.value,
         account                 |-> account.value,
         clearingFirm            |-> clearingFirm.value,
         clearingAccount         |-> clearingAccount.value,
         displayIndicator        |-> displayIndicator.value,
         maxFloor                |-> maxFloor.value,
         orderQtyLong            |-> orderQtyLong.value,
         preventMatch            |-> preventMatch.value,
         maturityDate            |-> maturityDate.value,
         strikePrice             |-> strikePrice.value,
         putOrCall               |-> putOrCall.value,
         openClose               |-> openClose.value,
         correctedSize           |-> correctedSize.value,
         origClOrdId             |-> origClOrdId.value,
         leavesQty               |-> leavesQty.value,
         lastShares              |-> lastShares.value,
         lastPx                  |-> lastPx.value,
         displayPrice            |-> displayPrice.value,
         workingPrice            |-> workingPrice.value,
         baseLiquidityIndicator  |-> baseLiquidityIndicator.value,
         expireTime              |-> expireTime.value,
         secondaryOrderId        |-> secondaryOrderId.value,
         contraCapacity          |-> contraCapacity.value,
         attributedQuote         |-> attributedQuote.value,
         echoText                |-> echoText.value,
         stopPx                  |-> stopPx.value,
         routingInst             |-> routingInst.value,
         routStrategy            |-> routStrategy.value,
         routeDeliveryMethod     |-> routeDeliveryMethod.value,
         exDestination           |-> exDestination.value,
         cmtaNumber              |-> cmtaNumber.value,
         floorRoutingInst        |-> floorRoutingInst.value,
         orderOrigin             |-> orderOrigin.value ], orderOrigin.rest)

(* Order Cancelled Message with each field marked present by fields before it there exactly where they say *)
SettleOrderCancelledMessage(message) ==
    LET settled1 == [message EXCEPT !.returnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.returnBitfield1 = << >> THEN <<0>> ELSE message.returnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.returnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.returnBitfield2 = << >> THEN <<0>> ELSE settled1.returnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.returnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.returnBitfield3 = << >> THEN <<0>> ELSE settled2.returnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.returnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.returnBitfield4 = << >> THEN <<0>> ELSE settled3.returnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.returnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.returnBitfield5 = << >> THEN <<0>> ELSE settled4.returnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.returnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.returnBitfield6 = << >> THEN <<0>> ELSE settled5.returnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.returnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.returnBitfield7 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.returnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.returnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.returnBitfield8 = << >> THEN <<0>> ELSE settled7.returnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.returnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.returnBitfield9 = << >> THEN <<0>> ELSE settled8.returnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.returnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.returnBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.returnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.returnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.returnBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.returnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.returnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.returnBitfield12 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.returnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.returnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.returnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.returnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.returnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.returnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.returnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.returnBitfield15 = IF settled14.numberOfReturnBitfields >= 15 THEN (IF settled14.returnBitfield15 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.returnBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.returnBitfield16 = IF settled15.numberOfReturnBitfields >= 16 THEN (IF settled15.returnBitfield16 = << >> THEN <<0>> ELSE settled15.returnBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.returnBitfield17 = IF settled16.numberOfReturnBitfields >= 17 THEN (IF settled16.returnBitfield17 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled16.returnBitfield17) ELSE << >>]
        settled18 == [settled17 EXCEPT !.side = IF settled17.numberOfReturnBitfields >= 1 /\ (settled17.returnBitfield1 # << >> /\ settled17.returnBitfield1[1] % 2 > 0) THEN (IF settled17.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.side) ELSE << >>]
        settled19 == [settled18 EXCEPT !.priceLong = IF settled18.numberOfReturnBitfields >= 1 /\ (settled18.returnBitfield1 # << >> /\ (settled18.returnBitfield1[1] \div 4) % 2 > 0) THEN (IF settled18.priceLong = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled18.priceLong) ELSE << >>]
        settled20 == [settled19 EXCEPT !.execInst = IF settled19.numberOfReturnBitfields >= 1 /\ (settled19.returnBitfield1 # << >> /\ (settled19.returnBitfield1[1] \div 8) % 2 > 0) THEN (IF settled19.execInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled19.execInst) ELSE << >>]
        settled21 == [settled20 EXCEPT !.ordType = IF settled20.numberOfReturnBitfields >= 1 /\ (settled20.returnBitfield1 # << >> /\ (settled20.returnBitfield1[1] \div 16) % 2 > 0) THEN (IF settled20.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled20.ordType) ELSE << >>]
        settled22 == [settled21 EXCEPT !.timeInForce = IF settled21.numberOfReturnBitfields >= 1 /\ (settled21.returnBitfield1 # << >> /\ (settled21.returnBitfield1[1] \div 32) % 2 > 0) THEN (IF settled21.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled21.timeInForce) ELSE << >>]
        settled23 == [settled22 EXCEPT !.minQty = IF settled22.numberOfReturnBitfields >= 1 /\ (settled22.returnBitfield1 # << >> /\ (settled22.returnBitfield1[1] \div 64) % 2 > 0) THEN (IF settled22.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled22.minQty) ELSE << >>]
        settled24 == [settled23 EXCEPT !.maxRemovePct = IF settled23.numberOfReturnBitfields >= 1 /\ (settled23.returnBitfield1 # << >> /\ (settled23.returnBitfield1[1] \div 128) % 2 > 0) THEN (IF settled23.maxRemovePct = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled23.maxRemovePct) ELSE << >>]
        settled25 == [settled24 EXCEPT !.symbolLong = IF settled24.numberOfReturnBitfields >= 2 /\ (settled24.returnBitfield2 # << >> /\ settled24.returnBitfield2[1] % 2 > 0) THEN (IF settled24.symbolLong = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled24.symbolLong) ELSE << >>]
        settled26 == [settled25 EXCEPT !.capacity = IF settled25.numberOfReturnBitfields >= 2 /\ (settled25.returnBitfield2 # << >> /\ (settled25.returnBitfield2[1] \div 64) % 2 > 0) THEN (IF settled25.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled25.capacity) ELSE << >>]
        settled27 == [settled26 EXCEPT !.account = IF settled26.numberOfReturnBitfields >= 3 /\ (settled26.returnBitfield3 # << >> /\ settled26.returnBitfield3[1] % 2 > 0) THEN (IF settled26.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled26.account) ELSE << >>]
        settled28 == [settled27 EXCEPT !.clearingFirm = IF settled27.numberOfReturnBitfields >= 3 /\ (settled27.returnBitfield3 # << >> /\ (settled27.returnBitfield3[1] \div 2) % 2 > 0) THEN (IF settled27.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled27.clearingFirm) ELSE << >>]
        settled29 == [settled28 EXCEPT !.clearingAccount = IF settled28.numberOfReturnBitfields >= 3 /\ (settled28.returnBitfield3 # << >> /\ (settled28.returnBitfield3[1] \div 4) % 2 > 0) THEN (IF settled28.clearingAccount = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled28.clearingAccount) ELSE << >>]
        settled30 == [settled29 EXCEPT !.displayIndicator = IF settled29.numberOfReturnBitfields >= 3 /\ (settled29.returnBitfield3 # << >> /\ (settled29.returnBitfield3[1] \div 8) % 2 > 0) THEN (IF settled29.displayIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled29.displayIndicator) ELSE << >>]
        settled31 == [settled30 EXCEPT !.maxFloor = IF settled30.numberOfReturnBitfields >= 3 /\ (settled30.returnBitfield3 # << >> /\ (settled30.returnBitfield3[1] \div 16) % 2 > 0) THEN (IF settled30.maxFloor = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled30.maxFloor) ELSE << >>]
        settled32 == [settled31 EXCEPT !.orderQtyLong = IF settled31.numberOfReturnBitfields >= 3 /\ (settled31.returnBitfield3 # << >> /\ (settled31.returnBitfield3[1] \div 64) % 2 > 0) THEN (IF settled31.orderQtyLong = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled31.orderQtyLong) ELSE << >>]
        settled33 == [settled32 EXCEPT !.preventMatch = IF settled32.numberOfReturnBitfields >= 3 /\ (settled32.returnBitfield3 # << >> /\ (settled32.returnBitfield3[1] \div 128) % 2 > 0) THEN (IF settled32.preventMatch = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled32.preventMatch) ELSE << >>]
        settled34 == [settled33 EXCEPT !.maturityDate = IF settled33.numberOfReturnBitfields >= 4 /\ (settled33.returnBitfield4 # << >> /\ settled33.returnBitfield4[1] % 2 > 0) THEN (IF settled33.maturityDate = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled33.maturityDate) ELSE << >>]
        settled35 == [settled34 EXCEPT !.strikePrice = IF settled34.numberOfReturnBitfields >= 4 /\ (settled34.returnBitfield4 # << >> /\ (settled34.returnBitfield4[1] \div 2) % 2 > 0) THEN (IF settled34.strikePrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled34.strikePrice) ELSE << >>]
        settled36 == [settled35 EXCEPT !.putOrCall = IF settled35.numberOfReturnBitfields >= 4 /\ (settled35.returnBitfield4 # << >> /\ (settled35.returnBitfield4[1] \div 4) % 2 > 0) THEN (IF settled35.putOrCall = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled35.putOrCall) ELSE << >>]
        settled37 == [settled36 EXCEPT !.openClose = IF settled36.numberOfReturnBitfields >= 4 /\ (settled36.returnBitfield4 # << >> /\ (settled36.returnBitfield4[1] \div 8) % 2 > 0) THEN (IF settled36.openClose = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled36.openClose) ELSE << >>]
        settled38 == [settled37 EXCEPT !.correctedSize = IF settled37.numberOfReturnBitfields >= 4 /\ (settled37.returnBitfield4 # << >> /\ (settled37.returnBitfield4[1] \div 32) % 2 > 0) THEN (IF settled37.correctedSize = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled37.correctedSize) ELSE << >>]
        settled39 == [settled38 EXCEPT !.origClOrdId = IF settled38.numberOfReturnBitfields >= 5 /\ (settled38.returnBitfield5 # << >> /\ settled38.returnBitfield5[1] % 2 > 0) THEN (IF settled38.origClOrdId = << >> THEN <<[i \in 1 .. 20 |-> 0]>> ELSE settled38.origClOrdId) ELSE << >>]
        settled40 == [settled39 EXCEPT !.leavesQty = IF settled39.numberOfReturnBitfields >= 5 /\ (settled39.returnBitfield5 # << >> /\ (settled39.returnBitfield5[1] \div 2) % 2 > 0) THEN (IF settled39.leavesQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled39.leavesQty) ELSE << >>]
        settled41 == [settled40 EXCEPT !.lastShares = IF settled40.numberOfReturnBitfields >= 5 /\ (settled40.returnBitfield5 # << >> /\ (settled40.returnBitfield5[1] \div 4) % 2 > 0) THEN (IF settled40.lastShares = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled40.lastShares) ELSE << >>]
        settled42 == [settled41 EXCEPT !.lastPx = IF settled41.numberOfReturnBitfields >= 5 /\ (settled41.returnBitfield5 # << >> /\ (settled41.returnBitfield5[1] \div 8) % 2 > 0) THEN (IF settled41.lastPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled41.lastPx) ELSE << >>]
        settled43 == [settled42 EXCEPT !.displayPrice = IF settled42.numberOfReturnBitfields >= 5 /\ (settled42.returnBitfield5 # << >> /\ (settled42.returnBitfield5[1] \div 16) % 2 > 0) THEN (IF settled42.displayPrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled42.displayPrice) ELSE << >>]
        settled44 == [settled43 EXCEPT !.workingPrice = IF settled43.numberOfReturnBitfields >= 5 /\ (settled43.returnBitfield5 # << >> /\ (settled43.returnBitfield5[1] \div 32) % 2 > 0) THEN (IF settled43.workingPrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled43.workingPrice) ELSE << >>]
        settled45 == [settled44 EXCEPT !.baseLiquidityIndicator = IF settled44.numberOfReturnBitfields >= 5 /\ (settled44.returnBitfield5 # << >> /\ (settled44.returnBitfield5[1] \div 64) % 2 > 0) THEN (IF settled44.baseLiquidityIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled44.baseLiquidityIndicator) ELSE << >>]
        settled46 == [settled45 EXCEPT !.expireTime = IF settled45.numberOfReturnBitfields >= 5 /\ (settled45.returnBitfield5 # << >> /\ (settled45.returnBitfield5[1] \div 128) % 2 > 0) THEN (IF settled45.expireTime = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled45.expireTime) ELSE << >>]
        settled47 == [settled46 EXCEPT !.secondaryOrderId = IF settled46.numberOfReturnBitfields >= 6 /\ (settled46.returnBitfield6 # << >> /\ settled46.returnBitfield6[1] % 2 > 0) THEN (IF settled46.secondaryOrderId = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled46.secondaryOrderId) ELSE << >>]
        settled48 == [settled47 EXCEPT !.contraCapacity = IF settled47.numberOfReturnBitfields >= 6 /\ (settled47.returnBitfield6 # << >> /\ (settled47.returnBitfield6[1] \div 4) % 2 > 0) THEN (IF settled47.contraCapacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled47.contraCapacity) ELSE << >>]
        settled49 == [settled48 EXCEPT !.attributedQuote = IF settled48.numberOfReturnBitfields >= 6 /\ (settled48.returnBitfield6 # << >> /\ (settled48.returnBitfield6[1] \div 8) % 2 > 0) THEN (IF settled48.attributedQuote = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled48.attributedQuote) ELSE << >>]
        settled50 == [settled49 EXCEPT !.echoText = IF settled49.numberOfReturnBitfields >= 8 /\ (settled49.returnBitfield8 # << >> /\ (settled49.returnBitfield8[1] \div 2) % 2 > 0) THEN (IF settled49.echoText = << >> THEN <<[i \in 1 .. 64 |-> 0]>> ELSE settled49.echoText) ELSE << >>]
        settled51 == [settled50 EXCEPT !.stopPx = IF settled50.numberOfReturnBitfields >= 8 /\ (settled50.returnBitfield8 # << >> /\ (settled50.returnBitfield8[1] \div 4) % 2 > 0) THEN (IF settled50.stopPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled50.stopPx) ELSE << >>]
        settled52 == [settled51 EXCEPT !.routingInst = IF settled51.numberOfReturnBitfields >= 8 /\ (settled51.returnBitfield8 # << >> /\ (settled51.returnBitfield8[1] \div 8) % 2 > 0) THEN (IF settled51.routingInst = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled51.routingInst) ELSE << >>]
        settled53 == [settled52 EXCEPT !.routStrategy = IF settled52.numberOfReturnBitfields >= 8 /\ (settled52.returnBitfield8 # << >> /\ (settled52.returnBitfield8[1] \div 16) % 2 > 0) THEN (IF settled52.routStrategy = << >> THEN <<[i \in 1 .. 6 |-> 0]>> ELSE settled52.routStrategy) ELSE << >>]
        settled54 == [settled53 EXCEPT !.routeDeliveryMethod = IF settled53.numberOfReturnBitfields >= 8 /\ (settled53.returnBitfield8 # << >> /\ (settled53.returnBitfield8[1] \div 32) % 2 > 0) THEN (IF settled53.routeDeliveryMethod = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled53.routeDeliveryMethod) ELSE << >>]
        settled55 == [settled54 EXCEPT !.exDestination = IF settled54.numberOfReturnBitfields >= 8 /\ (settled54.returnBitfield8 # << >> /\ (settled54.returnBitfield8[1] \div 64) % 2 > 0) THEN (IF settled54.exDestination = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled54.exDestination) ELSE << >>]
        settled56 == [settled55 EXCEPT !.cmtaNumber = IF settled55.numberOfReturnBitfields >= 9 /\ (settled55.returnBitfield9 # << >> /\ (settled55.returnBitfield9[1] \div 32) % 2 > 0) THEN (IF settled55.cmtaNumber = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled55.cmtaNumber) ELSE << >>]
        settled57 == [settled56 EXCEPT !.floorRoutingInst = IF settled56.numberOfReturnBitfields >= 16 /\ (settled56.returnBitfield16 # << >> /\ (settled56.returnBitfield16[1] \div 32) % 2 > 0) THEN (IF settled56.floorRoutingInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled56.floorRoutingInst) ELSE << >>]
        settled58 == [settled57 EXCEPT !.orderOrigin = IF settled57.numberOfReturnBitfields >= 16 /\ (settled57.returnBitfield16 # << >> /\ (settled57.returnBitfield16[1] \div 128) % 2 > 0) THEN (IF settled57.orderOrigin = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled57.orderOrigin) ELSE << >>]
    IN  settled58

ZeroOrderCancelledMessage ==
    SettleOrderCancelledMessage([ transactTime            |-> [i \in 1 .. 8 |-> 0],
                                  clOrdId                 |-> [i \in 1 .. 20 |-> 0],
                                  cancelReason            |-> [i \in 1 .. 1 |-> 0],
                                  reserved1               |-> [i \in 1 .. 1 |-> 0],
                                  numberOfReturnBitfields |-> 0,
                                  returnBitfield1         |-> << >>,
                                  returnBitfield2         |-> << >>,
                                  returnBitfield3         |-> << >>,
                                  returnBitfield4         |-> << >>,
                                  returnBitfield5         |-> << >>,
                                  returnBitfield6         |-> << >>,
                                  returnBitfield7         |-> << >>,
                                  returnBitfield8         |-> << >>,
                                  returnBitfield9         |-> << >>,
                                  returnBitfield10        |-> << >>,
                                  returnBitfield11        |-> << >>,
                                  returnBitfield12        |-> << >>,
                                  returnBitfield13        |-> << >>,
                                  returnBitfield14        |-> << >>,
                                  returnBitfield15        |-> << >>,
                                  returnBitfield16        |-> << >>,
                                  returnBitfield17        |-> << >>,
                                  side                    |-> << >>,
                                  priceLong               |-> << >>,
                                  execInst                |-> << >>,
                                  ordType                 |-> << >>,
                                  timeInForce             |-> << >>,
                                  minQty                  |-> << >>,
                                  maxRemovePct            |-> << >>,
                                  symbolLong              |-> << >>,
                                  capacity                |-> << >>,
                                  account                 |-> << >>,
                                  clearingFirm            |-> << >>,
                                  clearingAccount         |-> << >>,
                                  displayIndicator        |-> << >>,
                                  maxFloor                |-> << >>,
                                  orderQtyLong            |-> << >>,
                                  preventMatch            |-> << >>,
                                  maturityDate            |-> << >>,
                                  strikePrice             |-> << >>,
                                  putOrCall               |-> << >>,
                                  openClose               |-> << >>,
                                  correctedSize           |-> << >>,
                                  origClOrdId             |-> << >>,
                                  leavesQty               |-> << >>,
                                  lastShares              |-> << >>,
                                  lastPx                  |-> << >>,
                                  displayPrice            |-> << >>,
                                  workingPrice            |-> << >>,
                                  baseLiquidityIndicator  |-> << >>,
                                  expireTime              |-> << >>,
                                  secondaryOrderId        |-> << >>,
                                  contraCapacity          |-> << >>,
                                  attributedQuote         |-> << >>,
                                  echoText                |-> << >>,
                                  stopPx                  |-> << >>,
                                  routingInst             |-> << >>,
                                  routStrategy            |-> << >>,
                                  routeDeliveryMethod     |-> << >>,
                                  exDestination           |-> << >>,
                                  cmtaNumber              |-> << >>,
                                  floorRoutingInst        |-> << >>,
                                  orderOrigin             |-> << >> ])

(* Order Cancelled Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelledMessage ==
    { ZeroOrderCancelledMessage }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.transactTime = one]) : one \in Sample(8) }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.clOrdId = one]) : one \in Sample(20) }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.cancelReason = one]) : one \in Sample(1) }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.reserved1 = one]) : one \in Sample(1) }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 7, !.returnBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 9, !.returnBitfield9 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 10, !.returnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 11, !.returnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 13, !.returnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 14, !.returnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 15, !.returnBitfield15 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 17, !.returnBitfield17 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<1>>, !.side = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<4>>, !.priceLong = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<8>>, !.execInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<128>>, !.maxRemovePct = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<1>>, !.symbolLong = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<1>>, !.account = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<2>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<4>>, !.clearingAccount = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<8>>, !.displayIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<16>>, !.maxFloor = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<64>>, !.orderQtyLong = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<128>>, !.preventMatch = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<1>>, !.maturityDate = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<2>>, !.strikePrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<4>>, !.putOrCall = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<8>>, !.openClose = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<32>>, !.correctedSize = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<1>>, !.origClOrdId = one]) : one \in { <<held>> : held \in Sample(20) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<2>>, !.leavesQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<4>>, !.lastShares = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<8>>, !.lastPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<16>>, !.displayPrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<32>>, !.workingPrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<64>>, !.baseLiquidityIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<128>>, !.expireTime = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = <<1>>, !.secondaryOrderId = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = <<4>>, !.contraCapacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = <<8>>, !.attributedQuote = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<2>>, !.echoText = one]) : one \in { <<held>> : held \in Sample(64) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<4>>, !.stopPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<8>>, !.routingInst = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<16>>, !.routStrategy = one]) : one \in { <<held>> : held \in Sample(6) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<32>>, !.routeDeliveryMethod = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<64>>, !.exDestination = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 9, !.returnBitfield9 = <<32>>, !.cmtaNumber = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = <<32>>, !.floorRoutingInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = <<128>>, !.orderOrigin = one]) : one \in { <<held>> : held \in Sample(3) } }

(***************************************************************************)
(* Quote Cancelled Message: 40 bytes                                       *)
(***************************************************************************)

QuoteCancelledMessage ==
    [ transactionTime : Sample(8),
      quoteUpdateId   : Sample(16),
      orderId         : Sample(8),
      symbolShort     : Sample(6),
      side            : Sample(1),
      cancelReason    : Sample(1) ]

EncodeQuoteCancelledMessage(message) ==
    message.transactionTime
        \o message.quoteUpdateId
        \o message.orderId
        \o message.symbolShort
        \o message.side
        \o message.cancelReason

DecodeQuoteCancelledMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET quoteUpdateId == ReadBytes(transactionTime.rest, 16) IN IF ~quoteUpdateId.ok THEN Fail ELSE
    LET orderId == ReadBytes(quoteUpdateId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET symbolShort == ReadBytes(orderId.rest, 6) IN IF ~symbolShort.ok THEN Fail ELSE
    LET side == ReadBytes(symbolShort.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET cancelReason == ReadBytes(side.rest, 1) IN IF ~cancelReason.ok THEN Fail ELSE
    Ok([ transactionTime |-> transactionTime.value,
         quoteUpdateId   |-> quoteUpdateId.value,
         orderId         |-> orderId.value,
         symbolShort     |-> symbolShort.value,
         side            |-> side.value,
         cancelReason    |-> cancelReason.value ], cancelReason.rest)

ZeroQuoteCancelledMessage ==
    [ transactionTime |-> [i \in 1 .. 8 |-> 0],
      quoteUpdateId   |-> [i \in 1 .. 16 |-> 0],
      orderId         |-> [i \in 1 .. 8 |-> 0],
      symbolShort     |-> [i \in 1 .. 6 |-> 0],
      side            |-> [i \in 1 .. 1 |-> 0],
      cancelReason    |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Cancelled Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteCancelledMessage ==
    { ZeroQuoteCancelledMessage }
        \cup { [ZeroQuoteCancelledMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroQuoteCancelledMessage EXCEPT !.quoteUpdateId = one] : one \in Sample(16) }
        \cup { [ZeroQuoteCancelledMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteCancelledMessage EXCEPT !.symbolShort = one] : one \in Sample(6) }
        \cup { [ZeroQuoteCancelledMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroQuoteCancelledMessage EXCEPT !.cancelReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Cancel Rejected Message                                                 *)
(***************************************************************************)

CancelRejectedMessage ==
    [ transactionTime         : Sample(8),
      clOrdId                 : Sample(20),
      cancelRejectReason      : Sample(1),
      text                    : Sample(60),
      reserved1               : Sample(1),
      numberOfReturnBitfields : 0 .. 255,
      returnBitfield1         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield2         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield3         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield4         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield5         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield6         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield7         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield8         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield9         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield10        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield11        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield12        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield13        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield14        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield15        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield16        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield17        : { << >> } \cup { <<held>> : held \in Sample(1) },
      side                    : { << >> } \cup { <<held>> : held \in Sample(1) },
      priceLong               : { << >> } \cup { <<held>> : held \in Sample(8) },
      execInst                : { << >> } \cup { <<held>> : held \in Sample(1) },
      ordType                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce             : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                  : { << >> } \cup { <<held>> : held \in Sample(4) },
      maxRemovePct            : { << >> } \cup { <<held>> : held \in Sample(1) },
      symbolLong              : { << >> } \cup { <<held>> : held \in Sample(8) },
      capacity                : { << >> } \cup { <<held>> : held \in Sample(1) },
      maturityDate            : { << >> } \cup { <<held>> : held \in Sample(4) },
      strikePrice             : { << >> } \cup { <<held>> : held \in Sample(8) },
      putOrCall               : { << >> } \cup { <<held>> : held \in Sample(1) },
      openClose               : { << >> } \cup { <<held>> : held \in Sample(1) },
      correctedSize           : { << >> } \cup { <<held>> : held \in Sample(4) },
      echoText                : { << >> } \cup { <<held>> : held \in Sample(64) },
      stopPx                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      cmtaNumber              : { << >> } \cup { <<held>> : held \in Sample(4) },
      massCancelId            : { << >> } \cup { <<held>> : held \in Sample(20) } ]

EncodeCancelRejectedMessage(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.cancelRejectReason
        \o message.text
        \o message.reserved1
        \o EncodeUIntBE(message.numberOfReturnBitfields, 1)
        \o (IF message.returnBitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield1[1], 1))
        \o (IF message.returnBitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield2[1], 1))
        \o (IF message.returnBitfield3 = << >> THEN << >> ELSE message.returnBitfield3[1])
        \o (IF message.returnBitfield4 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield4[1], 1))
        \o (IF message.returnBitfield5 = << >> THEN << >> ELSE message.returnBitfield5[1])
        \o (IF message.returnBitfield6 = << >> THEN << >> ELSE message.returnBitfield6[1])
        \o (IF message.returnBitfield7 = << >> THEN << >> ELSE message.returnBitfield7[1])
        \o (IF message.returnBitfield8 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield8[1], 1))
        \o (IF message.returnBitfield9 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield9[1], 1))
        \o (IF message.returnBitfield10 = << >> THEN << >> ELSE message.returnBitfield10[1])
        \o (IF message.returnBitfield11 = << >> THEN << >> ELSE message.returnBitfield11[1])
        \o (IF message.returnBitfield12 = << >> THEN << >> ELSE message.returnBitfield12[1])
        \o (IF message.returnBitfield13 = << >> THEN << >> ELSE message.returnBitfield13[1])
        \o (IF message.returnBitfield14 = << >> THEN << >> ELSE message.returnBitfield14[1])
        \o (IF message.returnBitfield15 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield15[1], 1))
        \o (IF message.returnBitfield16 = << >> THEN << >> ELSE message.returnBitfield16[1])
        \o (IF message.returnBitfield17 = << >> THEN << >> ELSE message.returnBitfield17[1])
        \o (IF message.side = << >> THEN << >> ELSE message.side[1])
        \o (IF message.priceLong = << >> THEN << >> ELSE message.priceLong[1])
        \o (IF message.execInst = << >> THEN << >> ELSE message.execInst[1])
        \o (IF message.ordType = << >> THEN << >> ELSE message.ordType[1])
        \o (IF message.timeInForce = << >> THEN << >> ELSE message.timeInForce[1])
        \o (IF message.minQty = << >> THEN << >> ELSE message.minQty[1])
        \o (IF message.maxRemovePct = << >> THEN << >> ELSE message.maxRemovePct[1])
        \o (IF message.symbolLong = << >> THEN << >> ELSE message.symbolLong[1])
        \o (IF message.capacity = << >> THEN << >> ELSE message.capacity[1])
        \o (IF message.maturityDate = << >> THEN << >> ELSE message.maturityDate[1])
        \o (IF message.strikePrice = << >> THEN << >> ELSE message.strikePrice[1])
        \o (IF message.putOrCall = << >> THEN << >> ELSE message.putOrCall[1])
        \o (IF message.openClose = << >> THEN << >> ELSE message.openClose[1])
        \o (IF message.correctedSize = << >> THEN << >> ELSE message.correctedSize[1])
        \o (IF message.echoText = << >> THEN << >> ELSE message.echoText[1])
        \o (IF message.stopPx = << >> THEN << >> ELSE message.stopPx[1])
        \o (IF message.cmtaNumber = << >> THEN << >> ELSE message.cmtaNumber[1])
        \o (IF message.massCancelId = << >> THEN << >> ELSE message.massCancelId[1])

DecodeCancelRejectedMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET cancelRejectReason == ReadBytes(clOrdId.rest, 1) IN IF ~cancelRejectReason.ok THEN Fail ELSE
    LET text == ReadBytes(cancelRejectReason.rest, 60) IN IF ~text.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(text.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET numberOfReturnBitfields == ReadUIntBE(reserved1.rest, 1) IN IF ~numberOfReturnBitfields.ok THEN Fail ELSE
    LET returnBitfield1 == ReadWhen(numberOfReturnBitfields.value >= 1, ReadUIntLE(numberOfReturnBitfields.rest, 1), numberOfReturnBitfields.rest) IN IF ~returnBitfield1.ok THEN Fail ELSE
    LET returnBitfield2 == ReadWhen(numberOfReturnBitfields.value >= 2, ReadUIntLE(returnBitfield1.rest, 1), returnBitfield1.rest) IN IF ~returnBitfield2.ok THEN Fail ELSE
    LET returnBitfield3 == ReadWhen(numberOfReturnBitfields.value >= 3, ReadBytes(returnBitfield2.rest, 1), returnBitfield2.rest) IN IF ~returnBitfield3.ok THEN Fail ELSE
    LET returnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadUIntLE(returnBitfield3.rest, 1), returnBitfield3.rest) IN IF ~returnBitfield4.ok THEN Fail ELSE
    LET returnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadBytes(returnBitfield4.rest, 1), returnBitfield4.rest) IN IF ~returnBitfield5.ok THEN Fail ELSE
    LET returnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadBytes(returnBitfield5.rest, 1), returnBitfield5.rest) IN IF ~returnBitfield6.ok THEN Fail ELSE
    LET returnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadBytes(returnBitfield6.rest, 1), returnBitfield6.rest) IN IF ~returnBitfield7.ok THEN Fail ELSE
    LET returnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadUIntLE(returnBitfield7.rest, 1), returnBitfield7.rest) IN IF ~returnBitfield8.ok THEN Fail ELSE
    LET returnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadUIntLE(returnBitfield8.rest, 1), returnBitfield8.rest) IN IF ~returnBitfield9.ok THEN Fail ELSE
    LET returnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadBytes(returnBitfield9.rest, 1), returnBitfield9.rest) IN IF ~returnBitfield10.ok THEN Fail ELSE
    LET returnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadBytes(returnBitfield10.rest, 1), returnBitfield10.rest) IN IF ~returnBitfield11.ok THEN Fail ELSE
    LET returnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadBytes(returnBitfield11.rest, 1), returnBitfield11.rest) IN IF ~returnBitfield12.ok THEN Fail ELSE
    LET returnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(returnBitfield12.rest, 1), returnBitfield12.rest) IN IF ~returnBitfield13.ok THEN Fail ELSE
    LET returnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(returnBitfield13.rest, 1), returnBitfield13.rest) IN IF ~returnBitfield14.ok THEN Fail ELSE
    LET returnBitfield15 == ReadWhen(numberOfReturnBitfields.value >= 15, ReadUIntLE(returnBitfield14.rest, 1), returnBitfield14.rest) IN IF ~returnBitfield15.ok THEN Fail ELSE
    LET returnBitfield16 == ReadWhen(numberOfReturnBitfields.value >= 16, ReadBytes(returnBitfield15.rest, 1), returnBitfield15.rest) IN IF ~returnBitfield16.ok THEN Fail ELSE
    LET returnBitfield17 == ReadWhen(numberOfReturnBitfields.value >= 17, ReadBytes(returnBitfield16.rest, 1), returnBitfield16.rest) IN IF ~returnBitfield17.ok THEN Fail ELSE
    LET side == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ returnBitfield1.value[1] % 2 > 0), ReadBytes(returnBitfield17.rest, 1), returnBitfield17.rest) IN IF ~side.ok THEN Fail ELSE
    LET priceLong == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(side.rest, 8), side.rest) IN IF ~priceLong.ok THEN Fail ELSE
    LET execInst == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 8) % 2 > 0), ReadBytes(priceLong.rest, 1), priceLong.rest) IN IF ~execInst.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(execInst.rest, 1), execInst.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET maxRemovePct == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 128) % 2 > 0), ReadBytes(minQty.rest, 1), minQty.rest) IN IF ~maxRemovePct.ok THEN Fail ELSE
    LET symbolLong == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ returnBitfield2.value[1] % 2 > 0), ReadBytes(maxRemovePct.rest, 8), maxRemovePct.rest) IN IF ~symbolLong.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ (returnBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(symbolLong.rest, 1), symbolLong.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET maturityDate == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ returnBitfield4.value[1] % 2 > 0), ReadBytes(capacity.rest, 4), capacity.rest) IN IF ~maturityDate.ok THEN Fail ELSE
    LET strikePrice == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ (returnBitfield4.value[1] \div 2) % 2 > 0), ReadBytes(maturityDate.rest, 8), maturityDate.rest) IN IF ~strikePrice.ok THEN Fail ELSE
    LET putOrCall == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ (returnBitfield4.value[1] \div 4) % 2 > 0), ReadBytes(strikePrice.rest, 1), strikePrice.rest) IN IF ~putOrCall.ok THEN Fail ELSE
    LET openClose == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ (returnBitfield4.value[1] \div 8) % 2 > 0), ReadBytes(putOrCall.rest, 1), putOrCall.rest) IN IF ~openClose.ok THEN Fail ELSE
    LET correctedSize == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ (returnBitfield4.value[1] \div 32) % 2 > 0), ReadBytes(openClose.rest, 4), openClose.rest) IN IF ~correctedSize.ok THEN Fail ELSE
    LET echoText == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 2) % 2 > 0), ReadBytes(correctedSize.rest, 64), correctedSize.rest) IN IF ~echoText.ok THEN Fail ELSE
    LET stopPx == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 4) % 2 > 0), ReadBytes(echoText.rest, 8), echoText.rest) IN IF ~stopPx.ok THEN Fail ELSE
    LET cmtaNumber == ReadWhen(numberOfReturnBitfields.value >= 9 /\ (returnBitfield9.value # << >> /\ (returnBitfield9.value[1] \div 32) % 2 > 0), ReadBytes(stopPx.rest, 4), stopPx.rest) IN IF ~cmtaNumber.ok THEN Fail ELSE
    LET massCancelId == ReadWhen(numberOfReturnBitfields.value >= 15 /\ (returnBitfield15.value # << >> /\ (returnBitfield15.value[1] \div 8) % 2 > 0), ReadBytes(cmtaNumber.rest, 20), cmtaNumber.rest) IN IF ~massCancelId.ok THEN Fail ELSE
    Ok([ transactionTime         |-> transactionTime.value,
         clOrdId                 |-> clOrdId.value,
         cancelRejectReason      |-> cancelRejectReason.value,
         text                    |-> text.value,
         reserved1               |-> reserved1.value,
         numberOfReturnBitfields |-> numberOfReturnBitfields.value,
         returnBitfield1         |-> returnBitfield1.value,
         returnBitfield2         |-> returnBitfield2.value,
         returnBitfield3         |-> returnBitfield3.value,
         returnBitfield4         |-> returnBitfield4.value,
         returnBitfield5         |-> returnBitfield5.value,
         returnBitfield6         |-> returnBitfield6.value,
         returnBitfield7         |-> returnBitfield7.value,
         returnBitfield8         |-> returnBitfield8.value,
         returnBitfield9         |-> returnBitfield9.value,
         returnBitfield10        |-> returnBitfield10.value,
         returnBitfield11        |-> returnBitfield11.value,
         returnBitfield12        |-> returnBitfield12.value,
         returnBitfield13        |-> returnBitfield13.value,
         returnBitfield14        |-> returnBitfield14.value,
         returnBitfield15        |-> returnBitfield15.value,
         returnBitfield16        |-> returnBitfield16.value,
         returnBitfield17        |-> returnBitfield17.value,
         side                    |-> side.value,
         priceLong               |-> priceLong.value,
         execInst                |-> execInst.value,
         ordType                 |-> ordType.value,
         timeInForce             |-> timeInForce.value,
         minQty                  |-> minQty.value,
         maxRemovePct            |-> maxRemovePct.value,
         symbolLong              |-> symbolLong.value,
         capacity                |-> capacity.value,
         maturityDate            |-> maturityDate.value,
         strikePrice             |-> strikePrice.value,
         putOrCall               |-> putOrCall.value,
         openClose               |-> openClose.value,
         correctedSize           |-> correctedSize.value,
         echoText                |-> echoText.value,
         stopPx                  |-> stopPx.value,
         cmtaNumber              |-> cmtaNumber.value,
         massCancelId            |-> massCancelId.value ], massCancelId.rest)

(* Cancel Rejected Message with each field marked present by fields before it there exactly where they say *)
SettleCancelRejectedMessage(message) ==
    LET settled1 == [message EXCEPT !.returnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.returnBitfield1 = << >> THEN <<0>> ELSE message.returnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.returnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.returnBitfield2 = << >> THEN <<0>> ELSE settled1.returnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.returnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.returnBitfield3 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled2.returnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.returnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.returnBitfield4 = << >> THEN <<0>> ELSE settled3.returnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.returnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.returnBitfield5 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled4.returnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.returnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.returnBitfield6 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled5.returnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.returnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.returnBitfield7 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.returnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.returnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.returnBitfield8 = << >> THEN <<0>> ELSE settled7.returnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.returnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.returnBitfield9 = << >> THEN <<0>> ELSE settled8.returnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.returnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.returnBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.returnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.returnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.returnBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.returnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.returnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.returnBitfield12 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.returnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.returnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.returnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.returnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.returnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.returnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.returnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.returnBitfield15 = IF settled14.numberOfReturnBitfields >= 15 THEN (IF settled14.returnBitfield15 = << >> THEN <<0>> ELSE settled14.returnBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.returnBitfield16 = IF settled15.numberOfReturnBitfields >= 16 THEN (IF settled15.returnBitfield16 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled15.returnBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.returnBitfield17 = IF settled16.numberOfReturnBitfields >= 17 THEN (IF settled16.returnBitfield17 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled16.returnBitfield17) ELSE << >>]
        settled18 == [settled17 EXCEPT !.side = IF settled17.numberOfReturnBitfields >= 1 /\ (settled17.returnBitfield1 # << >> /\ settled17.returnBitfield1[1] % 2 > 0) THEN (IF settled17.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.side) ELSE << >>]
        settled19 == [settled18 EXCEPT !.priceLong = IF settled18.numberOfReturnBitfields >= 1 /\ (settled18.returnBitfield1 # << >> /\ (settled18.returnBitfield1[1] \div 4) % 2 > 0) THEN (IF settled18.priceLong = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled18.priceLong) ELSE << >>]
        settled20 == [settled19 EXCEPT !.execInst = IF settled19.numberOfReturnBitfields >= 1 /\ (settled19.returnBitfield1 # << >> /\ (settled19.returnBitfield1[1] \div 8) % 2 > 0) THEN (IF settled19.execInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled19.execInst) ELSE << >>]
        settled21 == [settled20 EXCEPT !.ordType = IF settled20.numberOfReturnBitfields >= 1 /\ (settled20.returnBitfield1 # << >> /\ (settled20.returnBitfield1[1] \div 16) % 2 > 0) THEN (IF settled20.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled20.ordType) ELSE << >>]
        settled22 == [settled21 EXCEPT !.timeInForce = IF settled21.numberOfReturnBitfields >= 1 /\ (settled21.returnBitfield1 # << >> /\ (settled21.returnBitfield1[1] \div 32) % 2 > 0) THEN (IF settled21.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled21.timeInForce) ELSE << >>]
        settled23 == [settled22 EXCEPT !.minQty = IF settled22.numberOfReturnBitfields >= 1 /\ (settled22.returnBitfield1 # << >> /\ (settled22.returnBitfield1[1] \div 64) % 2 > 0) THEN (IF settled22.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled22.minQty) ELSE << >>]
        settled24 == [settled23 EXCEPT !.maxRemovePct = IF settled23.numberOfReturnBitfields >= 1 /\ (settled23.returnBitfield1 # << >> /\ (settled23.returnBitfield1[1] \div 128) % 2 > 0) THEN (IF settled23.maxRemovePct = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled23.maxRemovePct) ELSE << >>]
        settled25 == [settled24 EXCEPT !.symbolLong = IF settled24.numberOfReturnBitfields >= 2 /\ (settled24.returnBitfield2 # << >> /\ settled24.returnBitfield2[1] % 2 > 0) THEN (IF settled24.symbolLong = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled24.symbolLong) ELSE << >>]
        settled26 == [settled25 EXCEPT !.capacity = IF settled25.numberOfReturnBitfields >= 2 /\ (settled25.returnBitfield2 # << >> /\ (settled25.returnBitfield2[1] \div 64) % 2 > 0) THEN (IF settled25.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled25.capacity) ELSE << >>]
        settled27 == [settled26 EXCEPT !.maturityDate = IF settled26.numberOfReturnBitfields >= 4 /\ (settled26.returnBitfield4 # << >> /\ settled26.returnBitfield4[1] % 2 > 0) THEN (IF settled26.maturityDate = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled26.maturityDate) ELSE << >>]
        settled28 == [settled27 EXCEPT !.strikePrice = IF settled27.numberOfReturnBitfields >= 4 /\ (settled27.returnBitfield4 # << >> /\ (settled27.returnBitfield4[1] \div 2) % 2 > 0) THEN (IF settled27.strikePrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled27.strikePrice) ELSE << >>]
        settled29 == [settled28 EXCEPT !.putOrCall = IF settled28.numberOfReturnBitfields >= 4 /\ (settled28.returnBitfield4 # << >> /\ (settled28.returnBitfield4[1] \div 4) % 2 > 0) THEN (IF settled28.putOrCall = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled28.putOrCall) ELSE << >>]
        settled30 == [settled29 EXCEPT !.openClose = IF settled29.numberOfReturnBitfields >= 4 /\ (settled29.returnBitfield4 # << >> /\ (settled29.returnBitfield4[1] \div 8) % 2 > 0) THEN (IF settled29.openClose = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled29.openClose) ELSE << >>]
        settled31 == [settled30 EXCEPT !.correctedSize = IF settled30.numberOfReturnBitfields >= 4 /\ (settled30.returnBitfield4 # << >> /\ (settled30.returnBitfield4[1] \div 32) % 2 > 0) THEN (IF settled30.correctedSize = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled30.correctedSize) ELSE << >>]
        settled32 == [settled31 EXCEPT !.echoText = IF settled31.numberOfReturnBitfields >= 8 /\ (settled31.returnBitfield8 # << >> /\ (settled31.returnBitfield8[1] \div 2) % 2 > 0) THEN (IF settled31.echoText = << >> THEN <<[i \in 1 .. 64 |-> 0]>> ELSE settled31.echoText) ELSE << >>]
        settled33 == [settled32 EXCEPT !.stopPx = IF settled32.numberOfReturnBitfields >= 8 /\ (settled32.returnBitfield8 # << >> /\ (settled32.returnBitfield8[1] \div 4) % 2 > 0) THEN (IF settled32.stopPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled32.stopPx) ELSE << >>]
        settled34 == [settled33 EXCEPT !.cmtaNumber = IF settled33.numberOfReturnBitfields >= 9 /\ (settled33.returnBitfield9 # << >> /\ (settled33.returnBitfield9[1] \div 32) % 2 > 0) THEN (IF settled33.cmtaNumber = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled33.cmtaNumber) ELSE << >>]
        settled35 == [settled34 EXCEPT !.massCancelId = IF settled34.numberOfReturnBitfields >= 15 /\ (settled34.returnBitfield15 # << >> /\ (settled34.returnBitfield15[1] \div 8) % 2 > 0) THEN (IF settled34.massCancelId = << >> THEN <<[i \in 1 .. 20 |-> 0]>> ELSE settled34.massCancelId) ELSE << >>]
    IN  settled35

ZeroCancelRejectedMessage ==
    SettleCancelRejectedMessage([ transactionTime         |-> [i \in 1 .. 8 |-> 0],
                                  clOrdId                 |-> [i \in 1 .. 20 |-> 0],
                                  cancelRejectReason      |-> [i \in 1 .. 1 |-> 0],
                                  text                    |-> [i \in 1 .. 60 |-> 0],
                                  reserved1               |-> [i \in 1 .. 1 |-> 0],
                                  numberOfReturnBitfields |-> 0,
                                  returnBitfield1         |-> << >>,
                                  returnBitfield2         |-> << >>,
                                  returnBitfield3         |-> << >>,
                                  returnBitfield4         |-> << >>,
                                  returnBitfield5         |-> << >>,
                                  returnBitfield6         |-> << >>,
                                  returnBitfield7         |-> << >>,
                                  returnBitfield8         |-> << >>,
                                  returnBitfield9         |-> << >>,
                                  returnBitfield10        |-> << >>,
                                  returnBitfield11        |-> << >>,
                                  returnBitfield12        |-> << >>,
                                  returnBitfield13        |-> << >>,
                                  returnBitfield14        |-> << >>,
                                  returnBitfield15        |-> << >>,
                                  returnBitfield16        |-> << >>,
                                  returnBitfield17        |-> << >>,
                                  side                    |-> << >>,
                                  priceLong               |-> << >>,
                                  execInst                |-> << >>,
                                  ordType                 |-> << >>,
                                  timeInForce             |-> << >>,
                                  minQty                  |-> << >>,
                                  maxRemovePct            |-> << >>,
                                  symbolLong              |-> << >>,
                                  capacity                |-> << >>,
                                  maturityDate            |-> << >>,
                                  strikePrice             |-> << >>,
                                  putOrCall               |-> << >>,
                                  openClose               |-> << >>,
                                  correctedSize           |-> << >>,
                                  echoText                |-> << >>,
                                  stopPx                  |-> << >>,
                                  cmtaNumber              |-> << >>,
                                  massCancelId            |-> << >> ])

(* Cancel Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelRejectedMessage ==
    { ZeroCancelRejectedMessage }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.transactionTime = one]) : one \in Sample(8) }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.clOrdId = one]) : one \in Sample(20) }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.cancelRejectReason = one]) : one \in Sample(1) }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.text = one]) : one \in Sample(60) }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.reserved1 = one]) : one \in Sample(1) }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 7, !.returnBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 9, !.returnBitfield9 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 10, !.returnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 11, !.returnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 13, !.returnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 14, !.returnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 15, !.returnBitfield15 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 17, !.returnBitfield17 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<1>>, !.side = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<4>>, !.priceLong = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<8>>, !.execInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<128>>, !.maxRemovePct = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<1>>, !.symbolLong = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<1>>, !.maturityDate = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<2>>, !.strikePrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<4>>, !.putOrCall = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<8>>, !.openClose = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<32>>, !.correctedSize = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<2>>, !.echoText = one]) : one \in { <<held>> : held \in Sample(64) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<4>>, !.stopPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 9, !.returnBitfield9 = <<32>>, !.cmtaNumber = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 15, !.returnBitfield15 = <<8>>, !.massCancelId = one]) : one \in { <<held>> : held \in Sample(20) } }

(***************************************************************************)
(* Quote Execution Message: 78 bytes                                       *)
(***************************************************************************)

QuoteExecutionMessage ==
    [ transactionTime        : Sample(8),
      quoteUpdateId          : Sample(16),
      orderId                : Sample(8),
      execId                 : Sample(8),
      symbolShort            : Sample(6),
      clearingFirm           : Sample(4),
      lastShares             : Sample(4),
      lastPx                 : Sample(8),
      leavesQty              : Sample(4),
      contraTrader           : Sample(4),
      contraCapacity         : Sample(1),
      side                   : Sample(1),
      baseLiquidityIndicator : Sample(1),
      subLiquidityIndicator  : Sample(1),
      feeCode                : Sample(2),
      marketingFeeCode       : Sample(2) ]

EncodeQuoteExecutionMessage(message) ==
    message.transactionTime
        \o message.quoteUpdateId
        \o message.orderId
        \o message.execId
        \o message.symbolShort
        \o message.clearingFirm
        \o message.lastShares
        \o message.lastPx
        \o message.leavesQty
        \o message.contraTrader
        \o message.contraCapacity
        \o message.side
        \o message.baseLiquidityIndicator
        \o message.subLiquidityIndicator
        \o message.feeCode
        \o message.marketingFeeCode

DecodeQuoteExecutionMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET quoteUpdateId == ReadBytes(transactionTime.rest, 16) IN IF ~quoteUpdateId.ok THEN Fail ELSE
    LET orderId == ReadBytes(quoteUpdateId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET execId == ReadBytes(orderId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET symbolShort == ReadBytes(execId.rest, 6) IN IF ~symbolShort.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(symbolShort.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET lastShares == ReadBytes(clearingFirm.rest, 4) IN IF ~lastShares.ok THEN Fail ELSE
    LET lastPx == ReadBytes(lastShares.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(lastPx.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET contraTrader == ReadBytes(leavesQty.rest, 4) IN IF ~contraTrader.ok THEN Fail ELSE
    LET contraCapacity == ReadBytes(contraTrader.rest, 1) IN IF ~contraCapacity.ok THEN Fail ELSE
    LET side == ReadBytes(contraCapacity.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadBytes(side.rest, 1) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET subLiquidityIndicator == ReadBytes(baseLiquidityIndicator.rest, 1) IN IF ~subLiquidityIndicator.ok THEN Fail ELSE
    LET feeCode == ReadBytes(subLiquidityIndicator.rest, 2) IN IF ~feeCode.ok THEN Fail ELSE
    LET marketingFeeCode == ReadBytes(feeCode.rest, 2) IN IF ~marketingFeeCode.ok THEN Fail ELSE
    Ok([ transactionTime        |-> transactionTime.value,
         quoteUpdateId          |-> quoteUpdateId.value,
         orderId                |-> orderId.value,
         execId                 |-> execId.value,
         symbolShort            |-> symbolShort.value,
         clearingFirm           |-> clearingFirm.value,
         lastShares             |-> lastShares.value,
         lastPx                 |-> lastPx.value,
         leavesQty              |-> leavesQty.value,
         contraTrader           |-> contraTrader.value,
         contraCapacity         |-> contraCapacity.value,
         side                   |-> side.value,
         baseLiquidityIndicator |-> baseLiquidityIndicator.value,
         subLiquidityIndicator  |-> subLiquidityIndicator.value,
         feeCode                |-> feeCode.value,
         marketingFeeCode       |-> marketingFeeCode.value ], marketingFeeCode.rest)

ZeroQuoteExecutionMessage ==
    [ transactionTime        |-> [i \in 1 .. 8 |-> 0],
      quoteUpdateId          |-> [i \in 1 .. 16 |-> 0],
      orderId                |-> [i \in 1 .. 8 |-> 0],
      execId                 |-> [i \in 1 .. 8 |-> 0],
      symbolShort            |-> [i \in 1 .. 6 |-> 0],
      clearingFirm           |-> [i \in 1 .. 4 |-> 0],
      lastShares             |-> [i \in 1 .. 4 |-> 0],
      lastPx                 |-> [i \in 1 .. 8 |-> 0],
      leavesQty              |-> [i \in 1 .. 4 |-> 0],
      contraTrader           |-> [i \in 1 .. 4 |-> 0],
      contraCapacity         |-> [i \in 1 .. 1 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      baseLiquidityIndicator |-> [i \in 1 .. 1 |-> 0],
      subLiquidityIndicator  |-> [i \in 1 .. 1 |-> 0],
      feeCode                |-> [i \in 1 .. 2 |-> 0],
      marketingFeeCode       |-> [i \in 1 .. 2 |-> 0] ]

(* Quote Execution Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteExecutionMessage ==
    { ZeroQuoteExecutionMessage }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.quoteUpdateId = one] : one \in Sample(16) }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.symbolShort = one] : one \in Sample(6) }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.lastShares = one] : one \in Sample(4) }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.contraTrader = one] : one \in Sample(4) }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.contraCapacity = one] : one \in Sample(1) }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.baseLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.subLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.feeCode = one] : one \in Sample(2) }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.marketingFeeCode = one] : one \in Sample(2) }

(***************************************************************************)
(* Trade Cancel Or Correct Message                                         *)
(***************************************************************************)

TradeCancelOrCorrectMessage ==
    [ transactionTime         : Sample(8),
      clOrdId                 : Sample(20),
      orderId                 : Sample(8),
      execRefId               : Sample(8),
      side                    : Sample(1),
      baseLiquidityIndicator  : Sample(1),
      clearingFirm            : Sample(4),
      clearingAccount         : Sample(4),
      lastShares              : Sample(4),
      lastPx                  : Sample(8),
      correctedPrice          : Sample(8),
      origTime                : Sample(8),
      reserved1               : Sample(1),
      numberOfReturnBitfields : 0 .. 255,
      returnBitfield1         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield2         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield3         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield4         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield5         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield6         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield7         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield8         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield9         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield10        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield11        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield12        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield13        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield14        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield15        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield16        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield17        : { << >> } \cup { <<held>> : held \in Sample(1) },
      symbolLong              : { << >> } \cup { <<held>> : held \in Sample(8) },
      capacity                : { << >> } \cup { <<held>> : held \in Sample(1) },
      maturityDate            : { << >> } \cup { <<held>> : held \in Sample(4) },
      strikePrice             : { << >> } \cup { <<held>> : held \in Sample(8) },
      putOrCall               : { << >> } \cup { <<held>> : held \in Sample(1) },
      openClose               : { << >> } \cup { <<held>> : held \in Sample(1) },
      correctedSize           : { << >> } \cup { <<held>> : held \in Sample(4) },
      subLiquidityIndicator   : { << >> } \cup { <<held>> : held \in Sample(1) },
      cmtaNumber              : { << >> } \cup { <<held>> : held \in Sample(4) } ]

EncodeTradeCancelOrCorrectMessage(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.orderId
        \o message.execRefId
        \o message.side
        \o message.baseLiquidityIndicator
        \o message.clearingFirm
        \o message.clearingAccount
        \o message.lastShares
        \o message.lastPx
        \o message.correctedPrice
        \o message.origTime
        \o message.reserved1
        \o EncodeUIntBE(message.numberOfReturnBitfields, 1)
        \o (IF message.returnBitfield1 = << >> THEN << >> ELSE message.returnBitfield1[1])
        \o (IF message.returnBitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield2[1], 1))
        \o (IF message.returnBitfield3 = << >> THEN << >> ELSE message.returnBitfield3[1])
        \o (IF message.returnBitfield4 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield4[1], 1))
        \o (IF message.returnBitfield5 = << >> THEN << >> ELSE message.returnBitfield5[1])
        \o (IF message.returnBitfield6 = << >> THEN << >> ELSE message.returnBitfield6[1])
        \o (IF message.returnBitfield7 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield7[1], 1))
        \o (IF message.returnBitfield8 = << >> THEN << >> ELSE message.returnBitfield8[1])
        \o (IF message.returnBitfield9 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield9[1], 1))
        \o (IF message.returnBitfield10 = << >> THEN << >> ELSE message.returnBitfield10[1])
        \o (IF message.returnBitfield11 = << >> THEN << >> ELSE message.returnBitfield11[1])
        \o (IF message.returnBitfield12 = << >> THEN << >> ELSE message.returnBitfield12[1])
        \o (IF message.returnBitfield13 = << >> THEN << >> ELSE message.returnBitfield13[1])
        \o (IF message.returnBitfield14 = << >> THEN << >> ELSE message.returnBitfield14[1])
        \o (IF message.returnBitfield15 = << >> THEN << >> ELSE message.returnBitfield15[1])
        \o (IF message.returnBitfield16 = << >> THEN << >> ELSE message.returnBitfield16[1])
        \o (IF message.returnBitfield17 = << >> THEN << >> ELSE message.returnBitfield17[1])
        \o (IF message.symbolLong = << >> THEN << >> ELSE message.symbolLong[1])
        \o (IF message.capacity = << >> THEN << >> ELSE message.capacity[1])
        \o (IF message.maturityDate = << >> THEN << >> ELSE message.maturityDate[1])
        \o (IF message.strikePrice = << >> THEN << >> ELSE message.strikePrice[1])
        \o (IF message.putOrCall = << >> THEN << >> ELSE message.putOrCall[1])
        \o (IF message.openClose = << >> THEN << >> ELSE message.openClose[1])
        \o (IF message.correctedSize = << >> THEN << >> ELSE message.correctedSize[1])
        \o (IF message.subLiquidityIndicator = << >> THEN << >> ELSE message.subLiquidityIndicator[1])
        \o (IF message.cmtaNumber = << >> THEN << >> ELSE message.cmtaNumber[1])

DecodeTradeCancelOrCorrectMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clOrdId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET execRefId == ReadBytes(orderId.rest, 8) IN IF ~execRefId.ok THEN Fail ELSE
    LET side == ReadBytes(execRefId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadBytes(side.rest, 1) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(baseLiquidityIndicator.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadBytes(clearingFirm.rest, 4) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET lastShares == ReadBytes(clearingAccount.rest, 4) IN IF ~lastShares.ok THEN Fail ELSE
    LET lastPx == ReadBytes(lastShares.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET correctedPrice == ReadBytes(lastPx.rest, 8) IN IF ~correctedPrice.ok THEN Fail ELSE
    LET origTime == ReadBytes(correctedPrice.rest, 8) IN IF ~origTime.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(origTime.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET numberOfReturnBitfields == ReadUIntBE(reserved1.rest, 1) IN IF ~numberOfReturnBitfields.ok THEN Fail ELSE
    LET returnBitfield1 == ReadWhen(numberOfReturnBitfields.value >= 1, ReadBytes(numberOfReturnBitfields.rest, 1), numberOfReturnBitfields.rest) IN IF ~returnBitfield1.ok THEN Fail ELSE
    LET returnBitfield2 == ReadWhen(numberOfReturnBitfields.value >= 2, ReadUIntLE(returnBitfield1.rest, 1), returnBitfield1.rest) IN IF ~returnBitfield2.ok THEN Fail ELSE
    LET returnBitfield3 == ReadWhen(numberOfReturnBitfields.value >= 3, ReadBytes(returnBitfield2.rest, 1), returnBitfield2.rest) IN IF ~returnBitfield3.ok THEN Fail ELSE
    LET returnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadUIntLE(returnBitfield3.rest, 1), returnBitfield3.rest) IN IF ~returnBitfield4.ok THEN Fail ELSE
    LET returnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadBytes(returnBitfield4.rest, 1), returnBitfield4.rest) IN IF ~returnBitfield5.ok THEN Fail ELSE
    LET returnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadBytes(returnBitfield5.rest, 1), returnBitfield5.rest) IN IF ~returnBitfield6.ok THEN Fail ELSE
    LET returnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadUIntLE(returnBitfield6.rest, 1), returnBitfield6.rest) IN IF ~returnBitfield7.ok THEN Fail ELSE
    LET returnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadBytes(returnBitfield7.rest, 1), returnBitfield7.rest) IN IF ~returnBitfield8.ok THEN Fail ELSE
    LET returnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadUIntLE(returnBitfield8.rest, 1), returnBitfield8.rest) IN IF ~returnBitfield9.ok THEN Fail ELSE
    LET returnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadBytes(returnBitfield9.rest, 1), returnBitfield9.rest) IN IF ~returnBitfield10.ok THEN Fail ELSE
    LET returnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadBytes(returnBitfield10.rest, 1), returnBitfield10.rest) IN IF ~returnBitfield11.ok THEN Fail ELSE
    LET returnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadBytes(returnBitfield11.rest, 1), returnBitfield11.rest) IN IF ~returnBitfield12.ok THEN Fail ELSE
    LET returnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(returnBitfield12.rest, 1), returnBitfield12.rest) IN IF ~returnBitfield13.ok THEN Fail ELSE
    LET returnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(returnBitfield13.rest, 1), returnBitfield13.rest) IN IF ~returnBitfield14.ok THEN Fail ELSE
    LET returnBitfield15 == ReadWhen(numberOfReturnBitfields.value >= 15, ReadBytes(returnBitfield14.rest, 1), returnBitfield14.rest) IN IF ~returnBitfield15.ok THEN Fail ELSE
    LET returnBitfield16 == ReadWhen(numberOfReturnBitfields.value >= 16, ReadBytes(returnBitfield15.rest, 1), returnBitfield15.rest) IN IF ~returnBitfield16.ok THEN Fail ELSE
    LET returnBitfield17 == ReadWhen(numberOfReturnBitfields.value >= 17, ReadBytes(returnBitfield16.rest, 1), returnBitfield16.rest) IN IF ~returnBitfield17.ok THEN Fail ELSE
    LET symbolLong == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ returnBitfield2.value[1] % 2 > 0), ReadBytes(returnBitfield17.rest, 8), returnBitfield17.rest) IN IF ~symbolLong.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ (returnBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(symbolLong.rest, 1), symbolLong.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET maturityDate == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ returnBitfield4.value[1] % 2 > 0), ReadBytes(capacity.rest, 4), capacity.rest) IN IF ~maturityDate.ok THEN Fail ELSE
    LET strikePrice == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ (returnBitfield4.value[1] \div 2) % 2 > 0), ReadBytes(maturityDate.rest, 8), maturityDate.rest) IN IF ~strikePrice.ok THEN Fail ELSE
    LET putOrCall == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ (returnBitfield4.value[1] \div 4) % 2 > 0), ReadBytes(strikePrice.rest, 1), strikePrice.rest) IN IF ~putOrCall.ok THEN Fail ELSE
    LET openClose == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ (returnBitfield4.value[1] \div 8) % 2 > 0), ReadBytes(putOrCall.rest, 1), putOrCall.rest) IN IF ~openClose.ok THEN Fail ELSE
    LET correctedSize == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ (returnBitfield4.value[1] \div 32) % 2 > 0), ReadBytes(openClose.rest, 4), openClose.rest) IN IF ~correctedSize.ok THEN Fail ELSE
    LET subLiquidityIndicator == ReadWhen(numberOfReturnBitfields.value >= 7 /\ (returnBitfield7.value # << >> /\ returnBitfield7.value[1] % 2 > 0), ReadBytes(correctedSize.rest, 1), correctedSize.rest) IN IF ~subLiquidityIndicator.ok THEN Fail ELSE
    LET cmtaNumber == ReadWhen(numberOfReturnBitfields.value >= 9 /\ (returnBitfield9.value # << >> /\ (returnBitfield9.value[1] \div 32) % 2 > 0), ReadBytes(subLiquidityIndicator.rest, 4), subLiquidityIndicator.rest) IN IF ~cmtaNumber.ok THEN Fail ELSE
    Ok([ transactionTime         |-> transactionTime.value,
         clOrdId                 |-> clOrdId.value,
         orderId                 |-> orderId.value,
         execRefId               |-> execRefId.value,
         side                    |-> side.value,
         baseLiquidityIndicator  |-> baseLiquidityIndicator.value,
         clearingFirm            |-> clearingFirm.value,
         clearingAccount         |-> clearingAccount.value,
         lastShares              |-> lastShares.value,
         lastPx                  |-> lastPx.value,
         correctedPrice          |-> correctedPrice.value,
         origTime                |-> origTime.value,
         reserved1               |-> reserved1.value,
         numberOfReturnBitfields |-> numberOfReturnBitfields.value,
         returnBitfield1         |-> returnBitfield1.value,
         returnBitfield2         |-> returnBitfield2.value,
         returnBitfield3         |-> returnBitfield3.value,
         returnBitfield4         |-> returnBitfield4.value,
         returnBitfield5         |-> returnBitfield5.value,
         returnBitfield6         |-> returnBitfield6.value,
         returnBitfield7         |-> returnBitfield7.value,
         returnBitfield8         |-> returnBitfield8.value,
         returnBitfield9         |-> returnBitfield9.value,
         returnBitfield10        |-> returnBitfield10.value,
         returnBitfield11        |-> returnBitfield11.value,
         returnBitfield12        |-> returnBitfield12.value,
         returnBitfield13        |-> returnBitfield13.value,
         returnBitfield14        |-> returnBitfield14.value,
         returnBitfield15        |-> returnBitfield15.value,
         returnBitfield16        |-> returnBitfield16.value,
         returnBitfield17        |-> returnBitfield17.value,
         symbolLong              |-> symbolLong.value,
         capacity                |-> capacity.value,
         maturityDate            |-> maturityDate.value,
         strikePrice             |-> strikePrice.value,
         putOrCall               |-> putOrCall.value,
         openClose               |-> openClose.value,
         correctedSize           |-> correctedSize.value,
         subLiquidityIndicator   |-> subLiquidityIndicator.value,
         cmtaNumber              |-> cmtaNumber.value ], cmtaNumber.rest)

(* Trade Cancel Or Correct Message with each field marked present by fields before it there exactly where they say *)
SettleTradeCancelOrCorrectMessage(message) ==
    LET settled1 == [message EXCEPT !.returnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.returnBitfield1 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE message.returnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.returnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.returnBitfield2 = << >> THEN <<0>> ELSE settled1.returnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.returnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.returnBitfield3 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled2.returnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.returnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.returnBitfield4 = << >> THEN <<0>> ELSE settled3.returnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.returnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.returnBitfield5 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled4.returnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.returnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.returnBitfield6 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled5.returnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.returnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.returnBitfield7 = << >> THEN <<0>> ELSE settled6.returnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.returnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.returnBitfield8 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled7.returnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.returnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.returnBitfield9 = << >> THEN <<0>> ELSE settled8.returnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.returnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.returnBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.returnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.returnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.returnBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.returnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.returnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.returnBitfield12 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.returnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.returnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.returnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.returnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.returnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.returnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.returnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.returnBitfield15 = IF settled14.numberOfReturnBitfields >= 15 THEN (IF settled14.returnBitfield15 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.returnBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.returnBitfield16 = IF settled15.numberOfReturnBitfields >= 16 THEN (IF settled15.returnBitfield16 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled15.returnBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.returnBitfield17 = IF settled16.numberOfReturnBitfields >= 17 THEN (IF settled16.returnBitfield17 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled16.returnBitfield17) ELSE << >>]
        settled18 == [settled17 EXCEPT !.symbolLong = IF settled17.numberOfReturnBitfields >= 2 /\ (settled17.returnBitfield2 # << >> /\ settled17.returnBitfield2[1] % 2 > 0) THEN (IF settled17.symbolLong = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled17.symbolLong) ELSE << >>]
        settled19 == [settled18 EXCEPT !.capacity = IF settled18.numberOfReturnBitfields >= 2 /\ (settled18.returnBitfield2 # << >> /\ (settled18.returnBitfield2[1] \div 64) % 2 > 0) THEN (IF settled18.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled18.capacity) ELSE << >>]
        settled20 == [settled19 EXCEPT !.maturityDate = IF settled19.numberOfReturnBitfields >= 4 /\ (settled19.returnBitfield4 # << >> /\ settled19.returnBitfield4[1] % 2 > 0) THEN (IF settled19.maturityDate = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled19.maturityDate) ELSE << >>]
        settled21 == [settled20 EXCEPT !.strikePrice = IF settled20.numberOfReturnBitfields >= 4 /\ (settled20.returnBitfield4 # << >> /\ (settled20.returnBitfield4[1] \div 2) % 2 > 0) THEN (IF settled20.strikePrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled20.strikePrice) ELSE << >>]
        settled22 == [settled21 EXCEPT !.putOrCall = IF settled21.numberOfReturnBitfields >= 4 /\ (settled21.returnBitfield4 # << >> /\ (settled21.returnBitfield4[1] \div 4) % 2 > 0) THEN (IF settled21.putOrCall = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled21.putOrCall) ELSE << >>]
        settled23 == [settled22 EXCEPT !.openClose = IF settled22.numberOfReturnBitfields >= 4 /\ (settled22.returnBitfield4 # << >> /\ (settled22.returnBitfield4[1] \div 8) % 2 > 0) THEN (IF settled22.openClose = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled22.openClose) ELSE << >>]
        settled24 == [settled23 EXCEPT !.correctedSize = IF settled23.numberOfReturnBitfields >= 4 /\ (settled23.returnBitfield4 # << >> /\ (settled23.returnBitfield4[1] \div 32) % 2 > 0) THEN (IF settled23.correctedSize = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled23.correctedSize) ELSE << >>]
        settled25 == [settled24 EXCEPT !.subLiquidityIndicator = IF settled24.numberOfReturnBitfields >= 7 /\ (settled24.returnBitfield7 # << >> /\ settled24.returnBitfield7[1] % 2 > 0) THEN (IF settled24.subLiquidityIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled24.subLiquidityIndicator) ELSE << >>]
        settled26 == [settled25 EXCEPT !.cmtaNumber = IF settled25.numberOfReturnBitfields >= 9 /\ (settled25.returnBitfield9 # << >> /\ (settled25.returnBitfield9[1] \div 32) % 2 > 0) THEN (IF settled25.cmtaNumber = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled25.cmtaNumber) ELSE << >>]
    IN  settled26

ZeroTradeCancelOrCorrectMessage ==
    SettleTradeCancelOrCorrectMessage([ transactionTime         |-> [i \in 1 .. 8 |-> 0],
                                        clOrdId                 |-> [i \in 1 .. 20 |-> 0],
                                        orderId                 |-> [i \in 1 .. 8 |-> 0],
                                        execRefId               |-> [i \in 1 .. 8 |-> 0],
                                        side                    |-> [i \in 1 .. 1 |-> 0],
                                        baseLiquidityIndicator  |-> [i \in 1 .. 1 |-> 0],
                                        clearingFirm            |-> [i \in 1 .. 4 |-> 0],
                                        clearingAccount         |-> [i \in 1 .. 4 |-> 0],
                                        lastShares              |-> [i \in 1 .. 4 |-> 0],
                                        lastPx                  |-> [i \in 1 .. 8 |-> 0],
                                        correctedPrice          |-> [i \in 1 .. 8 |-> 0],
                                        origTime                |-> [i \in 1 .. 8 |-> 0],
                                        reserved1               |-> [i \in 1 .. 1 |-> 0],
                                        numberOfReturnBitfields |-> 0,
                                        returnBitfield1         |-> << >>,
                                        returnBitfield2         |-> << >>,
                                        returnBitfield3         |-> << >>,
                                        returnBitfield4         |-> << >>,
                                        returnBitfield5         |-> << >>,
                                        returnBitfield6         |-> << >>,
                                        returnBitfield7         |-> << >>,
                                        returnBitfield8         |-> << >>,
                                        returnBitfield9         |-> << >>,
                                        returnBitfield10        |-> << >>,
                                        returnBitfield11        |-> << >>,
                                        returnBitfield12        |-> << >>,
                                        returnBitfield13        |-> << >>,
                                        returnBitfield14        |-> << >>,
                                        returnBitfield15        |-> << >>,
                                        returnBitfield16        |-> << >>,
                                        returnBitfield17        |-> << >>,
                                        symbolLong              |-> << >>,
                                        capacity                |-> << >>,
                                        maturityDate            |-> << >>,
                                        strikePrice             |-> << >>,
                                        putOrCall               |-> << >>,
                                        openClose               |-> << >>,
                                        correctedSize           |-> << >>,
                                        subLiquidityIndicator   |-> << >>,
                                        cmtaNumber              |-> << >> ])

(* Trade Cancel Or Correct Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCancelOrCorrectMessage ==
    { ZeroTradeCancelOrCorrectMessage }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.transactionTime = one]) : one \in Sample(8) }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.clOrdId = one]) : one \in Sample(20) }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.orderId = one]) : one \in Sample(8) }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.execRefId = one]) : one \in Sample(8) }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.side = one]) : one \in Sample(1) }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.baseLiquidityIndicator = one]) : one \in Sample(1) }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.clearingFirm = one]) : one \in Sample(4) }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.clearingAccount = one]) : one \in Sample(4) }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.lastShares = one]) : one \in Sample(4) }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.lastPx = one]) : one \in Sample(8) }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.correctedPrice = one]) : one \in Sample(8) }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.origTime = one]) : one \in Sample(8) }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.reserved1 = one]) : one \in Sample(1) }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 7, !.returnBitfield7 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 9, !.returnBitfield9 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 10, !.returnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 11, !.returnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 13, !.returnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 14, !.returnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 15, !.returnBitfield15 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 17, !.returnBitfield17 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<1>>, !.symbolLong = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<1>>, !.maturityDate = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<2>>, !.strikePrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<4>>, !.putOrCall = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<8>>, !.openClose = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<32>>, !.correctedSize = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 7, !.returnBitfield7 = <<1>>, !.subLiquidityIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 9, !.returnBitfield9 = <<32>>, !.cmtaNumber = one]) : one \in { <<held>> : held \in Sample(4) } }

(***************************************************************************)
(* Purge Rejected Message                                                  *)
(***************************************************************************)

PurgeRejectedMessage ==
    [ transactionTime         : Sample(8),
      purgeRejectReason       : Sample(1),
      text                    : Sample(60),
      reserved1               : Sample(1),
      numberOfReturnBitfields : 0 .. 255,
      returnBitfield1         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield2         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield3         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield4         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield5         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield6         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield7         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield8         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield9         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield10        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield11        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield12        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield13        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield14        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield15        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield16        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield17        : { << >> } \cup { <<held>> : held \in Sample(1) },
      massCancelId            : { << >> } \cup { <<held>> : held \in Sample(20) } ]

EncodePurgeRejectedMessage(message) ==
    message.transactionTime
        \o message.purgeRejectReason
        \o message.text
        \o message.reserved1
        \o EncodeUIntBE(message.numberOfReturnBitfields, 1)
        \o (IF message.returnBitfield1 = << >> THEN << >> ELSE message.returnBitfield1[1])
        \o (IF message.returnBitfield2 = << >> THEN << >> ELSE message.returnBitfield2[1])
        \o (IF message.returnBitfield3 = << >> THEN << >> ELSE message.returnBitfield3[1])
        \o (IF message.returnBitfield4 = << >> THEN << >> ELSE message.returnBitfield4[1])
        \o (IF message.returnBitfield5 = << >> THEN << >> ELSE message.returnBitfield5[1])
        \o (IF message.returnBitfield6 = << >> THEN << >> ELSE message.returnBitfield6[1])
        \o (IF message.returnBitfield7 = << >> THEN << >> ELSE message.returnBitfield7[1])
        \o (IF message.returnBitfield8 = << >> THEN << >> ELSE message.returnBitfield8[1])
        \o (IF message.returnBitfield9 = << >> THEN << >> ELSE message.returnBitfield9[1])
        \o (IF message.returnBitfield10 = << >> THEN << >> ELSE message.returnBitfield10[1])
        \o (IF message.returnBitfield11 = << >> THEN << >> ELSE message.returnBitfield11[1])
        \o (IF message.returnBitfield12 = << >> THEN << >> ELSE message.returnBitfield12[1])
        \o (IF message.returnBitfield13 = << >> THEN << >> ELSE message.returnBitfield13[1])
        \o (IF message.returnBitfield14 = << >> THEN << >> ELSE message.returnBitfield14[1])
        \o (IF message.returnBitfield15 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield15[1], 1))
        \o (IF message.returnBitfield16 = << >> THEN << >> ELSE message.returnBitfield16[1])
        \o (IF message.returnBitfield17 = << >> THEN << >> ELSE message.returnBitfield17[1])
        \o (IF message.massCancelId = << >> THEN << >> ELSE message.massCancelId[1])

DecodePurgeRejectedMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET purgeRejectReason == ReadBytes(transactionTime.rest, 1) IN IF ~purgeRejectReason.ok THEN Fail ELSE
    LET text == ReadBytes(purgeRejectReason.rest, 60) IN IF ~text.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(text.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET numberOfReturnBitfields == ReadUIntBE(reserved1.rest, 1) IN IF ~numberOfReturnBitfields.ok THEN Fail ELSE
    LET returnBitfield1 == ReadWhen(numberOfReturnBitfields.value >= 1, ReadBytes(numberOfReturnBitfields.rest, 1), numberOfReturnBitfields.rest) IN IF ~returnBitfield1.ok THEN Fail ELSE
    LET returnBitfield2 == ReadWhen(numberOfReturnBitfields.value >= 2, ReadBytes(returnBitfield1.rest, 1), returnBitfield1.rest) IN IF ~returnBitfield2.ok THEN Fail ELSE
    LET returnBitfield3 == ReadWhen(numberOfReturnBitfields.value >= 3, ReadBytes(returnBitfield2.rest, 1), returnBitfield2.rest) IN IF ~returnBitfield3.ok THEN Fail ELSE
    LET returnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadBytes(returnBitfield3.rest, 1), returnBitfield3.rest) IN IF ~returnBitfield4.ok THEN Fail ELSE
    LET returnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadBytes(returnBitfield4.rest, 1), returnBitfield4.rest) IN IF ~returnBitfield5.ok THEN Fail ELSE
    LET returnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadBytes(returnBitfield5.rest, 1), returnBitfield5.rest) IN IF ~returnBitfield6.ok THEN Fail ELSE
    LET returnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadBytes(returnBitfield6.rest, 1), returnBitfield6.rest) IN IF ~returnBitfield7.ok THEN Fail ELSE
    LET returnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadBytes(returnBitfield7.rest, 1), returnBitfield7.rest) IN IF ~returnBitfield8.ok THEN Fail ELSE
    LET returnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadBytes(returnBitfield8.rest, 1), returnBitfield8.rest) IN IF ~returnBitfield9.ok THEN Fail ELSE
    LET returnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadBytes(returnBitfield9.rest, 1), returnBitfield9.rest) IN IF ~returnBitfield10.ok THEN Fail ELSE
    LET returnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadBytes(returnBitfield10.rest, 1), returnBitfield10.rest) IN IF ~returnBitfield11.ok THEN Fail ELSE
    LET returnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadBytes(returnBitfield11.rest, 1), returnBitfield11.rest) IN IF ~returnBitfield12.ok THEN Fail ELSE
    LET returnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(returnBitfield12.rest, 1), returnBitfield12.rest) IN IF ~returnBitfield13.ok THEN Fail ELSE
    LET returnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(returnBitfield13.rest, 1), returnBitfield13.rest) IN IF ~returnBitfield14.ok THEN Fail ELSE
    LET returnBitfield15 == ReadWhen(numberOfReturnBitfields.value >= 15, ReadUIntLE(returnBitfield14.rest, 1), returnBitfield14.rest) IN IF ~returnBitfield15.ok THEN Fail ELSE
    LET returnBitfield16 == ReadWhen(numberOfReturnBitfields.value >= 16, ReadBytes(returnBitfield15.rest, 1), returnBitfield15.rest) IN IF ~returnBitfield16.ok THEN Fail ELSE
    LET returnBitfield17 == ReadWhen(numberOfReturnBitfields.value >= 17, ReadBytes(returnBitfield16.rest, 1), returnBitfield16.rest) IN IF ~returnBitfield17.ok THEN Fail ELSE
    LET massCancelId == ReadWhen(numberOfReturnBitfields.value >= 15 /\ (returnBitfield15.value # << >> /\ (returnBitfield15.value[1] \div 8) % 2 > 0), ReadBytes(returnBitfield17.rest, 20), returnBitfield17.rest) IN IF ~massCancelId.ok THEN Fail ELSE
    Ok([ transactionTime         |-> transactionTime.value,
         purgeRejectReason       |-> purgeRejectReason.value,
         text                    |-> text.value,
         reserved1               |-> reserved1.value,
         numberOfReturnBitfields |-> numberOfReturnBitfields.value,
         returnBitfield1         |-> returnBitfield1.value,
         returnBitfield2         |-> returnBitfield2.value,
         returnBitfield3         |-> returnBitfield3.value,
         returnBitfield4         |-> returnBitfield4.value,
         returnBitfield5         |-> returnBitfield5.value,
         returnBitfield6         |-> returnBitfield6.value,
         returnBitfield7         |-> returnBitfield7.value,
         returnBitfield8         |-> returnBitfield8.value,
         returnBitfield9         |-> returnBitfield9.value,
         returnBitfield10        |-> returnBitfield10.value,
         returnBitfield11        |-> returnBitfield11.value,
         returnBitfield12        |-> returnBitfield12.value,
         returnBitfield13        |-> returnBitfield13.value,
         returnBitfield14        |-> returnBitfield14.value,
         returnBitfield15        |-> returnBitfield15.value,
         returnBitfield16        |-> returnBitfield16.value,
         returnBitfield17        |-> returnBitfield17.value,
         massCancelId            |-> massCancelId.value ], massCancelId.rest)

(* Purge Rejected Message with each field marked present by fields before it there exactly where they say *)
SettlePurgeRejectedMessage(message) ==
    LET settled1 == [message EXCEPT !.returnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.returnBitfield1 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE message.returnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.returnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.returnBitfield2 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled1.returnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.returnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.returnBitfield3 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled2.returnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.returnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.returnBitfield4 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled3.returnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.returnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.returnBitfield5 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled4.returnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.returnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.returnBitfield6 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled5.returnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.returnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.returnBitfield7 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.returnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.returnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.returnBitfield8 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled7.returnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.returnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.returnBitfield9 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled8.returnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.returnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.returnBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.returnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.returnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.returnBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.returnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.returnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.returnBitfield12 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.returnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.returnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.returnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.returnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.returnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.returnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.returnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.returnBitfield15 = IF settled14.numberOfReturnBitfields >= 15 THEN (IF settled14.returnBitfield15 = << >> THEN <<0>> ELSE settled14.returnBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.returnBitfield16 = IF settled15.numberOfReturnBitfields >= 16 THEN (IF settled15.returnBitfield16 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled15.returnBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.returnBitfield17 = IF settled16.numberOfReturnBitfields >= 17 THEN (IF settled16.returnBitfield17 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled16.returnBitfield17) ELSE << >>]
        settled18 == [settled17 EXCEPT !.massCancelId = IF settled17.numberOfReturnBitfields >= 15 /\ (settled17.returnBitfield15 # << >> /\ (settled17.returnBitfield15[1] \div 8) % 2 > 0) THEN (IF settled17.massCancelId = << >> THEN <<[i \in 1 .. 20 |-> 0]>> ELSE settled17.massCancelId) ELSE << >>]
    IN  settled18

ZeroPurgeRejectedMessage ==
    SettlePurgeRejectedMessage([ transactionTime         |-> [i \in 1 .. 8 |-> 0],
                                 purgeRejectReason       |-> [i \in 1 .. 1 |-> 0],
                                 text                    |-> [i \in 1 .. 60 |-> 0],
                                 reserved1               |-> [i \in 1 .. 1 |-> 0],
                                 numberOfReturnBitfields |-> 0,
                                 returnBitfield1         |-> << >>,
                                 returnBitfield2         |-> << >>,
                                 returnBitfield3         |-> << >>,
                                 returnBitfield4         |-> << >>,
                                 returnBitfield5         |-> << >>,
                                 returnBitfield6         |-> << >>,
                                 returnBitfield7         |-> << >>,
                                 returnBitfield8         |-> << >>,
                                 returnBitfield9         |-> << >>,
                                 returnBitfield10        |-> << >>,
                                 returnBitfield11        |-> << >>,
                                 returnBitfield12        |-> << >>,
                                 returnBitfield13        |-> << >>,
                                 returnBitfield14        |-> << >>,
                                 returnBitfield15        |-> << >>,
                                 returnBitfield16        |-> << >>,
                                 returnBitfield17        |-> << >>,
                                 massCancelId            |-> << >> ])

(* Purge Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedPurgeRejectedMessage ==
    { ZeroPurgeRejectedMessage }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.transactionTime = one]) : one \in Sample(8) }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.purgeRejectReason = one]) : one \in Sample(1) }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.text = one]) : one \in Sample(60) }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.reserved1 = one]) : one \in Sample(1) }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.numberOfReturnBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.numberOfReturnBitfields = 7, !.returnBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.numberOfReturnBitfields = 9, !.returnBitfield9 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.numberOfReturnBitfields = 10, !.returnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.numberOfReturnBitfields = 11, !.returnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.numberOfReturnBitfields = 13, !.returnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.numberOfReturnBitfields = 14, !.returnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.numberOfReturnBitfields = 15, !.returnBitfield15 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.numberOfReturnBitfields = 17, !.returnBitfield17 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.numberOfReturnBitfields = 15, !.returnBitfield15 = <<8>>, !.massCancelId = one]) : one \in { <<held>> : held \in Sample(20) } }

(***************************************************************************)
(* Reset Risk Acknowledgment Message: 17 bytes                             *)
(***************************************************************************)

ResetRiskAcknowledgmentMessage ==
    [ riskStatusId    : Sample(16),
      riskResetResult : Sample(1) ]

EncodeResetRiskAcknowledgmentMessage(message) ==
    message.riskStatusId
        \o message.riskResetResult

DecodeResetRiskAcknowledgmentMessage(bytes) ==
    LET riskStatusId == ReadBytes(bytes, 16) IN IF ~riskStatusId.ok THEN Fail ELSE
    LET riskResetResult == ReadBytes(riskStatusId.rest, 1) IN IF ~riskResetResult.ok THEN Fail ELSE
    Ok([ riskStatusId    |-> riskStatusId.value,
         riskResetResult |-> riskResetResult.value ], riskResetResult.rest)

ZeroResetRiskAcknowledgmentMessage ==
    [ riskStatusId    |-> [i \in 1 .. 16 |-> 0],
      riskResetResult |-> [i \in 1 .. 1 |-> 0] ]

(* Reset Risk Acknowledgment Message at zero, then each field in turn at the values it is checked at *)
CheckedResetRiskAcknowledgmentMessage ==
    { ZeroResetRiskAcknowledgmentMessage }
        \cup { [ZeroResetRiskAcknowledgmentMessage EXCEPT !.riskStatusId = one] : one \in Sample(16) }
        \cup { [ZeroResetRiskAcknowledgmentMessage EXCEPT !.riskResetResult = one] : one \in Sample(1) }

(***************************************************************************)
(* Mass Cancel Acknowledgment Message: 33 bytes                            *)
(***************************************************************************)

MassCancelAcknowledgmentMessage ==
    [ transactionTime     : Sample(8),
      massCancelId        : Sample(20),
      cancelledOrderCount : Sample(4),
      reserved1           : Sample(1) ]

EncodeMassCancelAcknowledgmentMessage(message) ==
    message.transactionTime
        \o message.massCancelId
        \o message.cancelledOrderCount
        \o message.reserved1

DecodeMassCancelAcknowledgmentMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET massCancelId == ReadBytes(transactionTime.rest, 20) IN IF ~massCancelId.ok THEN Fail ELSE
    LET cancelledOrderCount == ReadBytes(massCancelId.rest, 4) IN IF ~cancelledOrderCount.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(cancelledOrderCount.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ transactionTime     |-> transactionTime.value,
         massCancelId        |-> massCancelId.value,
         cancelledOrderCount |-> cancelledOrderCount.value,
         reserved1           |-> reserved1.value ], reserved1.rest)

ZeroMassCancelAcknowledgmentMessage ==
    [ transactionTime     |-> [i \in 1 .. 8 |-> 0],
      massCancelId        |-> [i \in 1 .. 20 |-> 0],
      cancelledOrderCount |-> [i \in 1 .. 4 |-> 0],
      reserved1           |-> [i \in 1 .. 1 |-> 0] ]

(* Mass Cancel Acknowledgment Message at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelAcknowledgmentMessage ==
    { ZeroMassCancelAcknowledgmentMessage }
        \cup { [ZeroMassCancelAcknowledgmentMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelAcknowledgmentMessage EXCEPT !.massCancelId = one] : one \in Sample(20) }
        \cup { [ZeroMassCancelAcknowledgmentMessage EXCEPT !.cancelledOrderCount = one] : one \in Sample(4) }
        \cup { [ZeroMassCancelAcknowledgmentMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Execution Message                                                 *)
(***************************************************************************)

OrderExecutionMessage ==
    [ transactionTime         : Sample(8),
      clOrdId                 : Sample(20),
      execId                  : Sample(8),
      lastShares              : Sample(4),
      lastPx                  : Sample(8),
      leavesQty               : Sample(4),
      baseLiquidityIndicator  : Sample(1),
      subLiquidityIndicator   : Sample(1),
      contraBroker            : Sample(4),
      reserved1               : Sample(1),
      numberOfReturnBitfields : 0 .. 255,
      returnBitfield1         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield2         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield3         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield4         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield5         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield6         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield7         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield8         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield9         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield10        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield11        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield12        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield13        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield14        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield15        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield16        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield17        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      side                    : { << >> } \cup { <<held>> : held \in Sample(1) },
      priceLong               : { << >> } \cup { <<held>> : held \in Sample(8) },
      execInst                : { << >> } \cup { <<held>> : held \in Sample(1) },
      ordType                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce             : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                  : { << >> } \cup { <<held>> : held \in Sample(4) },
      maxRemovePct            : { << >> } \cup { <<held>> : held \in Sample(1) },
      symbolLong              : { << >> } \cup { <<held>> : held \in Sample(8) },
      capacity                : { << >> } \cup { <<held>> : held \in Sample(1) },
      contraTrader            : { << >> } \cup { <<held>> : held \in Sample(4) },
      account                 : { << >> } \cup { <<held>> : held \in Sample(16) },
      clearingFirm            : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingAccount         : { << >> } \cup { <<held>> : held \in Sample(4) },
      displayIndicator        : { << >> } \cup { <<held>> : held \in Sample(1) },
      maxFloor                : { << >> } \cup { <<held>> : held \in Sample(4) },
      orderQtyLong            : { << >> } \cup { <<held>> : held \in Sample(4) },
      preventMatch            : { << >> } \cup { <<held>> : held \in Sample(3) },
      maturityDate            : { << >> } \cup { <<held>> : held \in Sample(4) },
      strikePrice             : { << >> } \cup { <<held>> : held \in Sample(8) },
      putOrCall               : { << >> } \cup { <<held>> : held \in Sample(1) },
      openClose               : { << >> } \cup { <<held>> : held \in Sample(1) },
      correctedSize           : { << >> } \cup { <<held>> : held \in Sample(4) },
      contraCapacity          : { << >> } \cup { <<held>> : held \in Sample(1) },
      attributedQuote         : { << >> } \cup { <<held>> : held \in Sample(1) },
      feeCode                 : { << >> } \cup { <<held>> : held \in Sample(2) },
      echoText                : { << >> } \cup { <<held>> : held \in Sample(64) },
      stopPx                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      routingInst             : { << >> } \cup { <<held>> : held \in Sample(4) },
      routStrategy            : { << >> } \cup { <<held>> : held \in Sample(6) },
      routeDeliveryMethod     : { << >> } \cup { <<held>> : held \in Sample(3) },
      exDestination           : { << >> } \cup { <<held>> : held \in Sample(1) },
      cmtaNumber              : { << >> } \cup { <<held>> : held \in Sample(4) },
      crossType               : { << >> } \cup { <<held>> : held \in Sample(1) },
      clearingOptionalData    : { << >> } \cup { <<held>> : held \in Sample(16) },
      cumQty                  : { << >> } \cup { <<held>> : held \in Sample(4) },
      dayOrderQty             : { << >> } \cup { <<held>> : held \in Sample(4) },
      dayCumQty               : { << >> } \cup { <<held>> : held \in Sample(4) },
      avgPx                   : { << >> } \cup { <<held>> : held \in Sample(8) },
      dayAvgPx                : { << >> } \cup { <<held>> : held \in Sample(8) },
      clientIdAttr            : { << >> } \cup { <<held>> : held \in Sample(4) },
      floorRoutingInst        : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderOrigin             : { << >> } \cup { <<held>> : held \in Sample(3) },
      floorTraderAcronym      : { << >> } \cup { <<held>> : held \in Sample(3) } ]

EncodeOrderExecutionMessage(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.execId
        \o message.lastShares
        \o message.lastPx
        \o message.leavesQty
        \o message.baseLiquidityIndicator
        \o message.subLiquidityIndicator
        \o message.contraBroker
        \o message.reserved1
        \o EncodeUIntBE(message.numberOfReturnBitfields, 1)
        \o (IF message.returnBitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield1[1], 1))
        \o (IF message.returnBitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield2[1], 1))
        \o (IF message.returnBitfield3 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield3[1], 1))
        \o (IF message.returnBitfield4 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield4[1], 1))
        \o (IF message.returnBitfield5 = << >> THEN << >> ELSE message.returnBitfield5[1])
        \o (IF message.returnBitfield6 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield6[1], 1))
        \o (IF message.returnBitfield7 = << >> THEN << >> ELSE message.returnBitfield7[1])
        \o (IF message.returnBitfield8 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield8[1], 1))
        \o (IF message.returnBitfield9 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield9[1], 1))
        \o (IF message.returnBitfield10 = << >> THEN << >> ELSE message.returnBitfield10[1])
        \o (IF message.returnBitfield11 = << >> THEN << >> ELSE message.returnBitfield11[1])
        \o (IF message.returnBitfield12 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield12[1], 1))
        \o (IF message.returnBitfield13 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield13[1], 1))
        \o (IF message.returnBitfield14 = << >> THEN << >> ELSE message.returnBitfield14[1])
        \o (IF message.returnBitfield15 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield15[1], 1))
        \o (IF message.returnBitfield16 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield16[1], 1))
        \o (IF message.returnBitfield17 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield17[1], 1))
        \o (IF message.side = << >> THEN << >> ELSE message.side[1])
        \o (IF message.priceLong = << >> THEN << >> ELSE message.priceLong[1])
        \o (IF message.execInst = << >> THEN << >> ELSE message.execInst[1])
        \o (IF message.ordType = << >> THEN << >> ELSE message.ordType[1])
        \o (IF message.timeInForce = << >> THEN << >> ELSE message.timeInForce[1])
        \o (IF message.minQty = << >> THEN << >> ELSE message.minQty[1])
        \o (IF message.maxRemovePct = << >> THEN << >> ELSE message.maxRemovePct[1])
        \o (IF message.symbolLong = << >> THEN << >> ELSE message.symbolLong[1])
        \o (IF message.capacity = << >> THEN << >> ELSE message.capacity[1])
        \o (IF message.contraTrader = << >> THEN << >> ELSE message.contraTrader[1])
        \o (IF message.account = << >> THEN << >> ELSE message.account[1])
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])
        \o (IF message.clearingAccount = << >> THEN << >> ELSE message.clearingAccount[1])
        \o (IF message.displayIndicator = << >> THEN << >> ELSE message.displayIndicator[1])
        \o (IF message.maxFloor = << >> THEN << >> ELSE message.maxFloor[1])
        \o (IF message.orderQtyLong = << >> THEN << >> ELSE message.orderQtyLong[1])
        \o (IF message.preventMatch = << >> THEN << >> ELSE message.preventMatch[1])
        \o (IF message.maturityDate = << >> THEN << >> ELSE message.maturityDate[1])
        \o (IF message.strikePrice = << >> THEN << >> ELSE message.strikePrice[1])
        \o (IF message.putOrCall = << >> THEN << >> ELSE message.putOrCall[1])
        \o (IF message.openClose = << >> THEN << >> ELSE message.openClose[1])
        \o (IF message.correctedSize = << >> THEN << >> ELSE message.correctedSize[1])
        \o (IF message.contraCapacity = << >> THEN << >> ELSE message.contraCapacity[1])
        \o (IF message.attributedQuote = << >> THEN << >> ELSE message.attributedQuote[1])
        \o (IF message.feeCode = << >> THEN << >> ELSE message.feeCode[1])
        \o (IF message.echoText = << >> THEN << >> ELSE message.echoText[1])
        \o (IF message.stopPx = << >> THEN << >> ELSE message.stopPx[1])
        \o (IF message.routingInst = << >> THEN << >> ELSE message.routingInst[1])
        \o (IF message.routStrategy = << >> THEN << >> ELSE message.routStrategy[1])
        \o (IF message.routeDeliveryMethod = << >> THEN << >> ELSE message.routeDeliveryMethod[1])
        \o (IF message.exDestination = << >> THEN << >> ELSE message.exDestination[1])
        \o (IF message.cmtaNumber = << >> THEN << >> ELSE message.cmtaNumber[1])
        \o (IF message.crossType = << >> THEN << >> ELSE message.crossType[1])
        \o (IF message.clearingOptionalData = << >> THEN << >> ELSE message.clearingOptionalData[1])
        \o (IF message.cumQty = << >> THEN << >> ELSE message.cumQty[1])
        \o (IF message.dayOrderQty = << >> THEN << >> ELSE message.dayOrderQty[1])
        \o (IF message.dayCumQty = << >> THEN << >> ELSE message.dayCumQty[1])
        \o (IF message.avgPx = << >> THEN << >> ELSE message.avgPx[1])
        \o (IF message.dayAvgPx = << >> THEN << >> ELSE message.dayAvgPx[1])
        \o (IF message.clientIdAttr = << >> THEN << >> ELSE message.clientIdAttr[1])
        \o (IF message.floorRoutingInst = << >> THEN << >> ELSE message.floorRoutingInst[1])
        \o (IF message.orderOrigin = << >> THEN << >> ELSE message.orderOrigin[1])
        \o (IF message.floorTraderAcronym = << >> THEN << >> ELSE message.floorTraderAcronym[1])

DecodeOrderExecutionMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET execId == ReadBytes(clOrdId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET lastShares == ReadBytes(execId.rest, 4) IN IF ~lastShares.ok THEN Fail ELSE
    LET lastPx == ReadBytes(lastShares.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(lastPx.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadBytes(leavesQty.rest, 1) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET subLiquidityIndicator == ReadBytes(baseLiquidityIndicator.rest, 1) IN IF ~subLiquidityIndicator.ok THEN Fail ELSE
    LET contraBroker == ReadBytes(subLiquidityIndicator.rest, 4) IN IF ~contraBroker.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(contraBroker.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET numberOfReturnBitfields == ReadUIntBE(reserved1.rest, 1) IN IF ~numberOfReturnBitfields.ok THEN Fail ELSE
    LET returnBitfield1 == ReadWhen(numberOfReturnBitfields.value >= 1, ReadUIntLE(numberOfReturnBitfields.rest, 1), numberOfReturnBitfields.rest) IN IF ~returnBitfield1.ok THEN Fail ELSE
    LET returnBitfield2 == ReadWhen(numberOfReturnBitfields.value >= 2, ReadUIntLE(returnBitfield1.rest, 1), returnBitfield1.rest) IN IF ~returnBitfield2.ok THEN Fail ELSE
    LET returnBitfield3 == ReadWhen(numberOfReturnBitfields.value >= 3, ReadUIntLE(returnBitfield2.rest, 1), returnBitfield2.rest) IN IF ~returnBitfield3.ok THEN Fail ELSE
    LET returnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadUIntLE(returnBitfield3.rest, 1), returnBitfield3.rest) IN IF ~returnBitfield4.ok THEN Fail ELSE
    LET returnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadBytes(returnBitfield4.rest, 1), returnBitfield4.rest) IN IF ~returnBitfield5.ok THEN Fail ELSE
    LET returnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadUIntLE(returnBitfield5.rest, 1), returnBitfield5.rest) IN IF ~returnBitfield6.ok THEN Fail ELSE
    LET returnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadBytes(returnBitfield6.rest, 1), returnBitfield6.rest) IN IF ~returnBitfield7.ok THEN Fail ELSE
    LET returnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadUIntLE(returnBitfield7.rest, 1), returnBitfield7.rest) IN IF ~returnBitfield8.ok THEN Fail ELSE
    LET returnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadUIntLE(returnBitfield8.rest, 1), returnBitfield8.rest) IN IF ~returnBitfield9.ok THEN Fail ELSE
    LET returnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadBytes(returnBitfield9.rest, 1), returnBitfield9.rest) IN IF ~returnBitfield10.ok THEN Fail ELSE
    LET returnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadBytes(returnBitfield10.rest, 1), returnBitfield10.rest) IN IF ~returnBitfield11.ok THEN Fail ELSE
    LET returnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadUIntLE(returnBitfield11.rest, 1), returnBitfield11.rest) IN IF ~returnBitfield12.ok THEN Fail ELSE
    LET returnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadUIntLE(returnBitfield12.rest, 1), returnBitfield12.rest) IN IF ~returnBitfield13.ok THEN Fail ELSE
    LET returnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(returnBitfield13.rest, 1), returnBitfield13.rest) IN IF ~returnBitfield14.ok THEN Fail ELSE
    LET returnBitfield15 == ReadWhen(numberOfReturnBitfields.value >= 15, ReadUIntLE(returnBitfield14.rest, 1), returnBitfield14.rest) IN IF ~returnBitfield15.ok THEN Fail ELSE
    LET returnBitfield16 == ReadWhen(numberOfReturnBitfields.value >= 16, ReadUIntLE(returnBitfield15.rest, 1), returnBitfield15.rest) IN IF ~returnBitfield16.ok THEN Fail ELSE
    LET returnBitfield17 == ReadWhen(numberOfReturnBitfields.value >= 17, ReadUIntLE(returnBitfield16.rest, 1), returnBitfield16.rest) IN IF ~returnBitfield17.ok THEN Fail ELSE
    LET side == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ returnBitfield1.value[1] % 2 > 0), ReadBytes(returnBitfield17.rest, 1), returnBitfield17.rest) IN IF ~side.ok THEN Fail ELSE
    LET priceLong == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(side.rest, 8), side.rest) IN IF ~priceLong.ok THEN Fail ELSE
    LET execInst == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 8) % 2 > 0), ReadBytes(priceLong.rest, 1), priceLong.rest) IN IF ~execInst.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(execInst.rest, 1), execInst.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET maxRemovePct == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 128) % 2 > 0), ReadBytes(minQty.rest, 1), minQty.rest) IN IF ~maxRemovePct.ok THEN Fail ELSE
    LET symbolLong == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ returnBitfield2.value[1] % 2 > 0), ReadBytes(maxRemovePct.rest, 8), maxRemovePct.rest) IN IF ~symbolLong.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ (returnBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(symbolLong.rest, 1), symbolLong.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET contraTrader == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ (returnBitfield2.value[1] \div 128) % 2 > 0), ReadBytes(capacity.rest, 4), capacity.rest) IN IF ~contraTrader.ok THEN Fail ELSE
    LET account == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ returnBitfield3.value[1] % 2 > 0), ReadBytes(contraTrader.rest, 16), contraTrader.rest) IN IF ~account.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 2) % 2 > 0), ReadBytes(account.rest, 4), account.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 4) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET displayIndicator == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 8) % 2 > 0), ReadBytes(clearingAccount.rest, 1), clearingAccount.rest) IN IF ~displayIndicator.ok THEN Fail ELSE
    LET maxFloor == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 16) % 2 > 0), ReadBytes(displayIndicator.rest, 4), displayIndicator.rest) IN IF ~maxFloor.ok THEN Fail ELSE
    LET orderQtyLong == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 64) % 2 > 0), ReadBytes(maxFloor.rest, 4), maxFloor.rest) IN IF ~orderQtyLong.ok THEN Fail ELSE
    LET preventMatch == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 128) % 2 > 0), ReadBytes(orderQtyLong.rest, 3), orderQtyLong.rest) IN IF ~preventMatch.ok THEN Fail ELSE
    LET maturityDate == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ returnBitfield4.value[1] % 2 > 0), ReadBytes(preventMatch.rest, 4), preventMatch.rest) IN IF ~maturityDate.ok THEN Fail ELSE
    LET strikePrice == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ (returnBitfield4.value[1] \div 2) % 2 > 0), ReadBytes(maturityDate.rest, 8), maturityDate.rest) IN IF ~strikePrice.ok THEN Fail ELSE
    LET putOrCall == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ (returnBitfield4.value[1] \div 4) % 2 > 0), ReadBytes(strikePrice.rest, 1), strikePrice.rest) IN IF ~putOrCall.ok THEN Fail ELSE
    LET openClose == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ (returnBitfield4.value[1] \div 8) % 2 > 0), ReadBytes(putOrCall.rest, 1), putOrCall.rest) IN IF ~openClose.ok THEN Fail ELSE
    LET correctedSize == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ (returnBitfield4.value[1] \div 32) % 2 > 0), ReadBytes(openClose.rest, 4), openClose.rest) IN IF ~correctedSize.ok THEN Fail ELSE
    LET contraCapacity == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (returnBitfield6.value # << >> /\ (returnBitfield6.value[1] \div 4) % 2 > 0), ReadBytes(correctedSize.rest, 1), correctedSize.rest) IN IF ~contraCapacity.ok THEN Fail ELSE
    LET attributedQuote == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (returnBitfield6.value # << >> /\ (returnBitfield6.value[1] \div 8) % 2 > 0), ReadBytes(contraCapacity.rest, 1), contraCapacity.rest) IN IF ~attributedQuote.ok THEN Fail ELSE
    LET feeCode == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ returnBitfield8.value[1] % 2 > 0), ReadBytes(attributedQuote.rest, 2), attributedQuote.rest) IN IF ~feeCode.ok THEN Fail ELSE
    LET echoText == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 2) % 2 > 0), ReadBytes(feeCode.rest, 64), feeCode.rest) IN IF ~echoText.ok THEN Fail ELSE
    LET stopPx == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 4) % 2 > 0), ReadBytes(echoText.rest, 8), echoText.rest) IN IF ~stopPx.ok THEN Fail ELSE
    LET routingInst == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 8) % 2 > 0), ReadBytes(stopPx.rest, 4), stopPx.rest) IN IF ~routingInst.ok THEN Fail ELSE
    LET routStrategy == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 16) % 2 > 0), ReadBytes(routingInst.rest, 6), routingInst.rest) IN IF ~routStrategy.ok THEN Fail ELSE
    LET routeDeliveryMethod == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 32) % 2 > 0), ReadBytes(routStrategy.rest, 3), routStrategy.rest) IN IF ~routeDeliveryMethod.ok THEN Fail ELSE
    LET exDestination == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 64) % 2 > 0), ReadBytes(routeDeliveryMethod.rest, 1), routeDeliveryMethod.rest) IN IF ~exDestination.ok THEN Fail ELSE
    LET cmtaNumber == ReadWhen(numberOfReturnBitfields.value >= 9 /\ (returnBitfield9.value # << >> /\ (returnBitfield9.value[1] \div 32) % 2 > 0), ReadBytes(exDestination.rest, 4), exDestination.rest) IN IF ~cmtaNumber.ok THEN Fail ELSE
    LET crossType == ReadWhen(numberOfReturnBitfields.value >= 9 /\ (returnBitfield9.value # << >> /\ (returnBitfield9.value[1] \div 64) % 2 > 0), ReadBytes(cmtaNumber.rest, 1), cmtaNumber.rest) IN IF ~crossType.ok THEN Fail ELSE
    LET clearingOptionalData == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (returnBitfield12.value # << >> /\ (returnBitfield12.value[1] \div 128) % 2 > 0), ReadBytes(crossType.rest, 16), crossType.rest) IN IF ~clearingOptionalData.ok THEN Fail ELSE
    LET cumQty == ReadWhen(numberOfReturnBitfields.value >= 13 /\ (returnBitfield13.value # << >> /\ returnBitfield13.value[1] % 2 > 0), ReadBytes(clearingOptionalData.rest, 4), clearingOptionalData.rest) IN IF ~cumQty.ok THEN Fail ELSE
    LET dayOrderQty == ReadWhen(numberOfReturnBitfields.value >= 13 /\ (returnBitfield13.value # << >> /\ (returnBitfield13.value[1] \div 2) % 2 > 0), ReadBytes(cumQty.rest, 4), cumQty.rest) IN IF ~dayOrderQty.ok THEN Fail ELSE
    LET dayCumQty == ReadWhen(numberOfReturnBitfields.value >= 13 /\ (returnBitfield13.value # << >> /\ (returnBitfield13.value[1] \div 4) % 2 > 0), ReadBytes(dayOrderQty.rest, 4), dayOrderQty.rest) IN IF ~dayCumQty.ok THEN Fail ELSE
    LET avgPx == ReadWhen(numberOfReturnBitfields.value >= 13 /\ (returnBitfield13.value # << >> /\ (returnBitfield13.value[1] \div 8) % 2 > 0), ReadBytes(dayCumQty.rest, 8), dayCumQty.rest) IN IF ~avgPx.ok THEN Fail ELSE
    LET dayAvgPx == ReadWhen(numberOfReturnBitfields.value >= 13 /\ (returnBitfield13.value # << >> /\ (returnBitfield13.value[1] \div 16) % 2 > 0), ReadBytes(avgPx.rest, 8), avgPx.rest) IN IF ~dayAvgPx.ok THEN Fail ELSE
    LET clientIdAttr == ReadWhen(numberOfReturnBitfields.value >= 15 /\ (returnBitfield15.value # << >> /\ (returnBitfield15.value[1] \div 128) % 2 > 0), ReadBytes(dayAvgPx.rest, 4), dayAvgPx.rest) IN IF ~clientIdAttr.ok THEN Fail ELSE
    LET floorRoutingInst == ReadWhen(numberOfReturnBitfields.value >= 16 /\ (returnBitfield16.value # << >> /\ (returnBitfield16.value[1] \div 32) % 2 > 0), ReadBytes(clientIdAttr.rest, 1), clientIdAttr.rest) IN IF ~floorRoutingInst.ok THEN Fail ELSE
    LET orderOrigin == ReadWhen(numberOfReturnBitfields.value >= 16 /\ (returnBitfield16.value # << >> /\ (returnBitfield16.value[1] \div 128) % 2 > 0), ReadBytes(floorRoutingInst.rest, 3), floorRoutingInst.rest) IN IF ~orderOrigin.ok THEN Fail ELSE
    LET floorTraderAcronym == ReadWhen(numberOfReturnBitfields.value >= 17 /\ (returnBitfield17.value # << >> /\ (returnBitfield17.value[1] \div 32) % 2 > 0), ReadBytes(orderOrigin.rest, 3), orderOrigin.rest) IN IF ~floorTraderAcronym.ok THEN Fail ELSE
    Ok([ transactionTime         |-> transactionTime.value,
         clOrdId                 |-> clOrdId.value,
         execId                  |-> execId.value,
         lastShares              |-> lastShares.value,
         lastPx                  |-> lastPx.value,
         leavesQty               |-> leavesQty.value,
         baseLiquidityIndicator  |-> baseLiquidityIndicator.value,
         subLiquidityIndicator   |-> subLiquidityIndicator.value,
         contraBroker            |-> contraBroker.value,
         reserved1               |-> reserved1.value,
         numberOfReturnBitfields |-> numberOfReturnBitfields.value,
         returnBitfield1         |-> returnBitfield1.value,
         returnBitfield2         |-> returnBitfield2.value,
         returnBitfield3         |-> returnBitfield3.value,
         returnBitfield4         |-> returnBitfield4.value,
         returnBitfield5         |-> returnBitfield5.value,
         returnBitfield6         |-> returnBitfield6.value,
         returnBitfield7         |-> returnBitfield7.value,
         returnBitfield8         |-> returnBitfield8.value,
         returnBitfield9         |-> returnBitfield9.value,
         returnBitfield10        |-> returnBitfield10.value,
         returnBitfield11        |-> returnBitfield11.value,
         returnBitfield12        |-> returnBitfield12.value,
         returnBitfield13        |-> returnBitfield13.value,
         returnBitfield14        |-> returnBitfield14.value,
         returnBitfield15        |-> returnBitfield15.value,
         returnBitfield16        |-> returnBitfield16.value,
         returnBitfield17        |-> returnBitfield17.value,
         side                    |-> side.value,
         priceLong               |-> priceLong.value,
         execInst                |-> execInst.value,
         ordType                 |-> ordType.value,
         timeInForce             |-> timeInForce.value,
         minQty                  |-> minQty.value,
         maxRemovePct            |-> maxRemovePct.value,
         symbolLong              |-> symbolLong.value,
         capacity                |-> capacity.value,
         contraTrader            |-> contraTrader.value,
         account                 |-> account.value,
         clearingFirm            |-> clearingFirm.value,
         clearingAccount         |-> clearingAccount.value,
         displayIndicator        |-> displayIndicator.value,
         maxFloor                |-> maxFloor.value,
         orderQtyLong            |-> orderQtyLong.value,
         preventMatch            |-> preventMatch.value,
         maturityDate            |-> maturityDate.value,
         strikePrice             |-> strikePrice.value,
         putOrCall               |-> putOrCall.value,
         openClose               |-> openClose.value,
         correctedSize           |-> correctedSize.value,
         contraCapacity          |-> contraCapacity.value,
         attributedQuote         |-> attributedQuote.value,
         feeCode                 |-> feeCode.value,
         echoText                |-> echoText.value,
         stopPx                  |-> stopPx.value,
         routingInst             |-> routingInst.value,
         routStrategy            |-> routStrategy.value,
         routeDeliveryMethod     |-> routeDeliveryMethod.value,
         exDestination           |-> exDestination.value,
         cmtaNumber              |-> cmtaNumber.value,
         crossType               |-> crossType.value,
         clearingOptionalData    |-> clearingOptionalData.value,
         cumQty                  |-> cumQty.value,
         dayOrderQty             |-> dayOrderQty.value,
         dayCumQty               |-> dayCumQty.value,
         avgPx                   |-> avgPx.value,
         dayAvgPx                |-> dayAvgPx.value,
         clientIdAttr            |-> clientIdAttr.value,
         floorRoutingInst        |-> floorRoutingInst.value,
         orderOrigin             |-> orderOrigin.value,
         floorTraderAcronym      |-> floorTraderAcronym.value ], floorTraderAcronym.rest)

(* Order Execution Message with each field marked present by fields before it there exactly where they say *)
SettleOrderExecutionMessage(message) ==
    LET settled1 == [message EXCEPT !.returnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.returnBitfield1 = << >> THEN <<0>> ELSE message.returnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.returnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.returnBitfield2 = << >> THEN <<0>> ELSE settled1.returnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.returnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.returnBitfield3 = << >> THEN <<0>> ELSE settled2.returnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.returnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.returnBitfield4 = << >> THEN <<0>> ELSE settled3.returnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.returnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.returnBitfield5 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled4.returnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.returnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.returnBitfield6 = << >> THEN <<0>> ELSE settled5.returnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.returnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.returnBitfield7 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.returnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.returnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.returnBitfield8 = << >> THEN <<0>> ELSE settled7.returnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.returnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.returnBitfield9 = << >> THEN <<0>> ELSE settled8.returnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.returnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.returnBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.returnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.returnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.returnBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.returnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.returnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.returnBitfield12 = << >> THEN <<0>> ELSE settled11.returnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.returnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.returnBitfield13 = << >> THEN <<0>> ELSE settled12.returnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.returnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.returnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.returnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.returnBitfield15 = IF settled14.numberOfReturnBitfields >= 15 THEN (IF settled14.returnBitfield15 = << >> THEN <<0>> ELSE settled14.returnBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.returnBitfield16 = IF settled15.numberOfReturnBitfields >= 16 THEN (IF settled15.returnBitfield16 = << >> THEN <<0>> ELSE settled15.returnBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.returnBitfield17 = IF settled16.numberOfReturnBitfields >= 17 THEN (IF settled16.returnBitfield17 = << >> THEN <<0>> ELSE settled16.returnBitfield17) ELSE << >>]
        settled18 == [settled17 EXCEPT !.side = IF settled17.numberOfReturnBitfields >= 1 /\ (settled17.returnBitfield1 # << >> /\ settled17.returnBitfield1[1] % 2 > 0) THEN (IF settled17.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.side) ELSE << >>]
        settled19 == [settled18 EXCEPT !.priceLong = IF settled18.numberOfReturnBitfields >= 1 /\ (settled18.returnBitfield1 # << >> /\ (settled18.returnBitfield1[1] \div 4) % 2 > 0) THEN (IF settled18.priceLong = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled18.priceLong) ELSE << >>]
        settled20 == [settled19 EXCEPT !.execInst = IF settled19.numberOfReturnBitfields >= 1 /\ (settled19.returnBitfield1 # << >> /\ (settled19.returnBitfield1[1] \div 8) % 2 > 0) THEN (IF settled19.execInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled19.execInst) ELSE << >>]
        settled21 == [settled20 EXCEPT !.ordType = IF settled20.numberOfReturnBitfields >= 1 /\ (settled20.returnBitfield1 # << >> /\ (settled20.returnBitfield1[1] \div 16) % 2 > 0) THEN (IF settled20.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled20.ordType) ELSE << >>]
        settled22 == [settled21 EXCEPT !.timeInForce = IF settled21.numberOfReturnBitfields >= 1 /\ (settled21.returnBitfield1 # << >> /\ (settled21.returnBitfield1[1] \div 32) % 2 > 0) THEN (IF settled21.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled21.timeInForce) ELSE << >>]
        settled23 == [settled22 EXCEPT !.minQty = IF settled22.numberOfReturnBitfields >= 1 /\ (settled22.returnBitfield1 # << >> /\ (settled22.returnBitfield1[1] \div 64) % 2 > 0) THEN (IF settled22.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled22.minQty) ELSE << >>]
        settled24 == [settled23 EXCEPT !.maxRemovePct = IF settled23.numberOfReturnBitfields >= 1 /\ (settled23.returnBitfield1 # << >> /\ (settled23.returnBitfield1[1] \div 128) % 2 > 0) THEN (IF settled23.maxRemovePct = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled23.maxRemovePct) ELSE << >>]
        settled25 == [settled24 EXCEPT !.symbolLong = IF settled24.numberOfReturnBitfields >= 2 /\ (settled24.returnBitfield2 # << >> /\ settled24.returnBitfield2[1] % 2 > 0) THEN (IF settled24.symbolLong = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled24.symbolLong) ELSE << >>]
        settled26 == [settled25 EXCEPT !.capacity = IF settled25.numberOfReturnBitfields >= 2 /\ (settled25.returnBitfield2 # << >> /\ (settled25.returnBitfield2[1] \div 64) % 2 > 0) THEN (IF settled25.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled25.capacity) ELSE << >>]
        settled27 == [settled26 EXCEPT !.contraTrader = IF settled26.numberOfReturnBitfields >= 2 /\ (settled26.returnBitfield2 # << >> /\ (settled26.returnBitfield2[1] \div 128) % 2 > 0) THEN (IF settled26.contraTrader = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled26.contraTrader) ELSE << >>]
        settled28 == [settled27 EXCEPT !.account = IF settled27.numberOfReturnBitfields >= 3 /\ (settled27.returnBitfield3 # << >> /\ settled27.returnBitfield3[1] % 2 > 0) THEN (IF settled27.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled27.account) ELSE << >>]
        settled29 == [settled28 EXCEPT !.clearingFirm = IF settled28.numberOfReturnBitfields >= 3 /\ (settled28.returnBitfield3 # << >> /\ (settled28.returnBitfield3[1] \div 2) % 2 > 0) THEN (IF settled28.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled28.clearingFirm) ELSE << >>]
        settled30 == [settled29 EXCEPT !.clearingAccount = IF settled29.numberOfReturnBitfields >= 3 /\ (settled29.returnBitfield3 # << >> /\ (settled29.returnBitfield3[1] \div 4) % 2 > 0) THEN (IF settled29.clearingAccount = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled29.clearingAccount) ELSE << >>]
        settled31 == [settled30 EXCEPT !.displayIndicator = IF settled30.numberOfReturnBitfields >= 3 /\ (settled30.returnBitfield3 # << >> /\ (settled30.returnBitfield3[1] \div 8) % 2 > 0) THEN (IF settled30.displayIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled30.displayIndicator) ELSE << >>]
        settled32 == [settled31 EXCEPT !.maxFloor = IF settled31.numberOfReturnBitfields >= 3 /\ (settled31.returnBitfield3 # << >> /\ (settled31.returnBitfield3[1] \div 16) % 2 > 0) THEN (IF settled31.maxFloor = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled31.maxFloor) ELSE << >>]
        settled33 == [settled32 EXCEPT !.orderQtyLong = IF settled32.numberOfReturnBitfields >= 3 /\ (settled32.returnBitfield3 # << >> /\ (settled32.returnBitfield3[1] \div 64) % 2 > 0) THEN (IF settled32.orderQtyLong = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled32.orderQtyLong) ELSE << >>]
        settled34 == [settled33 EXCEPT !.preventMatch = IF settled33.numberOfReturnBitfields >= 3 /\ (settled33.returnBitfield3 # << >> /\ (settled33.returnBitfield3[1] \div 128) % 2 > 0) THEN (IF settled33.preventMatch = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled33.preventMatch) ELSE << >>]
        settled35 == [settled34 EXCEPT !.maturityDate = IF settled34.numberOfReturnBitfields >= 4 /\ (settled34.returnBitfield4 # << >> /\ settled34.returnBitfield4[1] % 2 > 0) THEN (IF settled34.maturityDate = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled34.maturityDate) ELSE << >>]
        settled36 == [settled35 EXCEPT !.strikePrice = IF settled35.numberOfReturnBitfields >= 4 /\ (settled35.returnBitfield4 # << >> /\ (settled35.returnBitfield4[1] \div 2) % 2 > 0) THEN (IF settled35.strikePrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled35.strikePrice) ELSE << >>]
        settled37 == [settled36 EXCEPT !.putOrCall = IF settled36.numberOfReturnBitfields >= 4 /\ (settled36.returnBitfield4 # << >> /\ (settled36.returnBitfield4[1] \div 4) % 2 > 0) THEN (IF settled36.putOrCall = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled36.putOrCall) ELSE << >>]
        settled38 == [settled37 EXCEPT !.openClose = IF settled37.numberOfReturnBitfields >= 4 /\ (settled37.returnBitfield4 # << >> /\ (settled37.returnBitfield4[1] \div 8) % 2 > 0) THEN (IF settled37.openClose = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled37.openClose) ELSE << >>]
        settled39 == [settled38 EXCEPT !.correctedSize = IF settled38.numberOfReturnBitfields >= 4 /\ (settled38.returnBitfield4 # << >> /\ (settled38.returnBitfield4[1] \div 32) % 2 > 0) THEN (IF settled38.correctedSize = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled38.correctedSize) ELSE << >>]
        settled40 == [settled39 EXCEPT !.contraCapacity = IF settled39.numberOfReturnBitfields >= 6 /\ (settled39.returnBitfield6 # << >> /\ (settled39.returnBitfield6[1] \div 4) % 2 > 0) THEN (IF settled39.contraCapacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled39.contraCapacity) ELSE << >>]
        settled41 == [settled40 EXCEPT !.attributedQuote = IF settled40.numberOfReturnBitfields >= 6 /\ (settled40.returnBitfield6 # << >> /\ (settled40.returnBitfield6[1] \div 8) % 2 > 0) THEN (IF settled40.attributedQuote = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled40.attributedQuote) ELSE << >>]
        settled42 == [settled41 EXCEPT !.feeCode = IF settled41.numberOfReturnBitfields >= 8 /\ (settled41.returnBitfield8 # << >> /\ settled41.returnBitfield8[1] % 2 > 0) THEN (IF settled41.feeCode = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled41.feeCode) ELSE << >>]
        settled43 == [settled42 EXCEPT !.echoText = IF settled42.numberOfReturnBitfields >= 8 /\ (settled42.returnBitfield8 # << >> /\ (settled42.returnBitfield8[1] \div 2) % 2 > 0) THEN (IF settled42.echoText = << >> THEN <<[i \in 1 .. 64 |-> 0]>> ELSE settled42.echoText) ELSE << >>]
        settled44 == [settled43 EXCEPT !.stopPx = IF settled43.numberOfReturnBitfields >= 8 /\ (settled43.returnBitfield8 # << >> /\ (settled43.returnBitfield8[1] \div 4) % 2 > 0) THEN (IF settled43.stopPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled43.stopPx) ELSE << >>]
        settled45 == [settled44 EXCEPT !.routingInst = IF settled44.numberOfReturnBitfields >= 8 /\ (settled44.returnBitfield8 # << >> /\ (settled44.returnBitfield8[1] \div 8) % 2 > 0) THEN (IF settled44.routingInst = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled44.routingInst) ELSE << >>]
        settled46 == [settled45 EXCEPT !.routStrategy = IF settled45.numberOfReturnBitfields >= 8 /\ (settled45.returnBitfield8 # << >> /\ (settled45.returnBitfield8[1] \div 16) % 2 > 0) THEN (IF settled45.routStrategy = << >> THEN <<[i \in 1 .. 6 |-> 0]>> ELSE settled45.routStrategy) ELSE << >>]
        settled47 == [settled46 EXCEPT !.routeDeliveryMethod = IF settled46.numberOfReturnBitfields >= 8 /\ (settled46.returnBitfield8 # << >> /\ (settled46.returnBitfield8[1] \div 32) % 2 > 0) THEN (IF settled46.routeDeliveryMethod = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled46.routeDeliveryMethod) ELSE << >>]
        settled48 == [settled47 EXCEPT !.exDestination = IF settled47.numberOfReturnBitfields >= 8 /\ (settled47.returnBitfield8 # << >> /\ (settled47.returnBitfield8[1] \div 64) % 2 > 0) THEN (IF settled47.exDestination = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled47.exDestination) ELSE << >>]
        settled49 == [settled48 EXCEPT !.cmtaNumber = IF settled48.numberOfReturnBitfields >= 9 /\ (settled48.returnBitfield9 # << >> /\ (settled48.returnBitfield9[1] \div 32) % 2 > 0) THEN (IF settled48.cmtaNumber = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled48.cmtaNumber) ELSE << >>]
        settled50 == [settled49 EXCEPT !.crossType = IF settled49.numberOfReturnBitfields >= 9 /\ (settled49.returnBitfield9 # << >> /\ (settled49.returnBitfield9[1] \div 64) % 2 > 0) THEN (IF settled49.crossType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled49.crossType) ELSE << >>]
        settled51 == [settled50 EXCEPT !.clearingOptionalData = IF settled50.numberOfReturnBitfields >= 12 /\ (settled50.returnBitfield12 # << >> /\ (settled50.returnBitfield12[1] \div 128) % 2 > 0) THEN (IF settled50.clearingOptionalData = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled50.clearingOptionalData) ELSE << >>]
        settled52 == [settled51 EXCEPT !.cumQty = IF settled51.numberOfReturnBitfields >= 13 /\ (settled51.returnBitfield13 # << >> /\ settled51.returnBitfield13[1] % 2 > 0) THEN (IF settled51.cumQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled51.cumQty) ELSE << >>]
        settled53 == [settled52 EXCEPT !.dayOrderQty = IF settled52.numberOfReturnBitfields >= 13 /\ (settled52.returnBitfield13 # << >> /\ (settled52.returnBitfield13[1] \div 2) % 2 > 0) THEN (IF settled52.dayOrderQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled52.dayOrderQty) ELSE << >>]
        settled54 == [settled53 EXCEPT !.dayCumQty = IF settled53.numberOfReturnBitfields >= 13 /\ (settled53.returnBitfield13 # << >> /\ (settled53.returnBitfield13[1] \div 4) % 2 > 0) THEN (IF settled53.dayCumQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled53.dayCumQty) ELSE << >>]
        settled55 == [settled54 EXCEPT !.avgPx = IF settled54.numberOfReturnBitfields >= 13 /\ (settled54.returnBitfield13 # << >> /\ (settled54.returnBitfield13[1] \div 8) % 2 > 0) THEN (IF settled54.avgPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled54.avgPx) ELSE << >>]
        settled56 == [settled55 EXCEPT !.dayAvgPx = IF settled55.numberOfReturnBitfields >= 13 /\ (settled55.returnBitfield13 # << >> /\ (settled55.returnBitfield13[1] \div 16) % 2 > 0) THEN (IF settled55.dayAvgPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled55.dayAvgPx) ELSE << >>]
        settled57 == [settled56 EXCEPT !.clientIdAttr = IF settled56.numberOfReturnBitfields >= 15 /\ (settled56.returnBitfield15 # << >> /\ (settled56.returnBitfield15[1] \div 128) % 2 > 0) THEN (IF settled56.clientIdAttr = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled56.clientIdAttr) ELSE << >>]
        settled58 == [settled57 EXCEPT !.floorRoutingInst = IF settled57.numberOfReturnBitfields >= 16 /\ (settled57.returnBitfield16 # << >> /\ (settled57.returnBitfield16[1] \div 32) % 2 > 0) THEN (IF settled57.floorRoutingInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled57.floorRoutingInst) ELSE << >>]
        settled59 == [settled58 EXCEPT !.orderOrigin = IF settled58.numberOfReturnBitfields >= 16 /\ (settled58.returnBitfield16 # << >> /\ (settled58.returnBitfield16[1] \div 128) % 2 > 0) THEN (IF settled58.orderOrigin = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled58.orderOrigin) ELSE << >>]
        settled60 == [settled59 EXCEPT !.floorTraderAcronym = IF settled59.numberOfReturnBitfields >= 17 /\ (settled59.returnBitfield17 # << >> /\ (settled59.returnBitfield17[1] \div 32) % 2 > 0) THEN (IF settled59.floorTraderAcronym = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled59.floorTraderAcronym) ELSE << >>]
    IN  settled60

ZeroOrderExecutionMessage ==
    SettleOrderExecutionMessage([ transactionTime         |-> [i \in 1 .. 8 |-> 0],
                                  clOrdId                 |-> [i \in 1 .. 20 |-> 0],
                                  execId                  |-> [i \in 1 .. 8 |-> 0],
                                  lastShares              |-> [i \in 1 .. 4 |-> 0],
                                  lastPx                  |-> [i \in 1 .. 8 |-> 0],
                                  leavesQty               |-> [i \in 1 .. 4 |-> 0],
                                  baseLiquidityIndicator  |-> [i \in 1 .. 1 |-> 0],
                                  subLiquidityIndicator   |-> [i \in 1 .. 1 |-> 0],
                                  contraBroker            |-> [i \in 1 .. 4 |-> 0],
                                  reserved1               |-> [i \in 1 .. 1 |-> 0],
                                  numberOfReturnBitfields |-> 0,
                                  returnBitfield1         |-> << >>,
                                  returnBitfield2         |-> << >>,
                                  returnBitfield3         |-> << >>,
                                  returnBitfield4         |-> << >>,
                                  returnBitfield5         |-> << >>,
                                  returnBitfield6         |-> << >>,
                                  returnBitfield7         |-> << >>,
                                  returnBitfield8         |-> << >>,
                                  returnBitfield9         |-> << >>,
                                  returnBitfield10        |-> << >>,
                                  returnBitfield11        |-> << >>,
                                  returnBitfield12        |-> << >>,
                                  returnBitfield13        |-> << >>,
                                  returnBitfield14        |-> << >>,
                                  returnBitfield15        |-> << >>,
                                  returnBitfield16        |-> << >>,
                                  returnBitfield17        |-> << >>,
                                  side                    |-> << >>,
                                  priceLong               |-> << >>,
                                  execInst                |-> << >>,
                                  ordType                 |-> << >>,
                                  timeInForce             |-> << >>,
                                  minQty                  |-> << >>,
                                  maxRemovePct            |-> << >>,
                                  symbolLong              |-> << >>,
                                  capacity                |-> << >>,
                                  contraTrader            |-> << >>,
                                  account                 |-> << >>,
                                  clearingFirm            |-> << >>,
                                  clearingAccount         |-> << >>,
                                  displayIndicator        |-> << >>,
                                  maxFloor                |-> << >>,
                                  orderQtyLong            |-> << >>,
                                  preventMatch            |-> << >>,
                                  maturityDate            |-> << >>,
                                  strikePrice             |-> << >>,
                                  putOrCall               |-> << >>,
                                  openClose               |-> << >>,
                                  correctedSize           |-> << >>,
                                  contraCapacity          |-> << >>,
                                  attributedQuote         |-> << >>,
                                  feeCode                 |-> << >>,
                                  echoText                |-> << >>,
                                  stopPx                  |-> << >>,
                                  routingInst             |-> << >>,
                                  routStrategy            |-> << >>,
                                  routeDeliveryMethod     |-> << >>,
                                  exDestination           |-> << >>,
                                  cmtaNumber              |-> << >>,
                                  crossType               |-> << >>,
                                  clearingOptionalData    |-> << >>,
                                  cumQty                  |-> << >>,
                                  dayOrderQty             |-> << >>,
                                  dayCumQty               |-> << >>,
                                  avgPx                   |-> << >>,
                                  dayAvgPx                |-> << >>,
                                  clientIdAttr            |-> << >>,
                                  floorRoutingInst        |-> << >>,
                                  orderOrigin             |-> << >>,
                                  floorTraderAcronym      |-> << >> ])

(* Order Execution Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutionMessage ==
    { ZeroOrderExecutionMessage }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.transactionTime = one]) : one \in Sample(8) }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.clOrdId = one]) : one \in Sample(20) }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.execId = one]) : one \in Sample(8) }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.lastShares = one]) : one \in Sample(4) }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.lastPx = one]) : one \in Sample(8) }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.leavesQty = one]) : one \in Sample(4) }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.baseLiquidityIndicator = one]) : one \in Sample(1) }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.subLiquidityIndicator = one]) : one \in Sample(1) }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.contraBroker = one]) : one \in Sample(4) }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.reserved1 = one]) : one \in Sample(1) }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 7, !.returnBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 9, !.returnBitfield9 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 10, !.returnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 11, !.returnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 13, !.returnBitfield13 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 14, !.returnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 15, !.returnBitfield15 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 17, !.returnBitfield17 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<1>>, !.side = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<4>>, !.priceLong = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<8>>, !.execInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<128>>, !.maxRemovePct = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<1>>, !.symbolLong = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<128>>, !.contraTrader = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<1>>, !.account = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<2>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<4>>, !.clearingAccount = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<8>>, !.displayIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<16>>, !.maxFloor = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<64>>, !.orderQtyLong = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<128>>, !.preventMatch = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<1>>, !.maturityDate = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<2>>, !.strikePrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<4>>, !.putOrCall = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<8>>, !.openClose = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<32>>, !.correctedSize = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = <<4>>, !.contraCapacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = <<8>>, !.attributedQuote = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<1>>, !.feeCode = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<2>>, !.echoText = one]) : one \in { <<held>> : held \in Sample(64) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<4>>, !.stopPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<8>>, !.routingInst = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<16>>, !.routStrategy = one]) : one \in { <<held>> : held \in Sample(6) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<32>>, !.routeDeliveryMethod = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<64>>, !.exDestination = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 9, !.returnBitfield9 = <<32>>, !.cmtaNumber = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 9, !.returnBitfield9 = <<64>>, !.crossType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = <<128>>, !.clearingOptionalData = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 13, !.returnBitfield13 = <<1>>, !.cumQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 13, !.returnBitfield13 = <<2>>, !.dayOrderQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 13, !.returnBitfield13 = <<4>>, !.dayCumQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 13, !.returnBitfield13 = <<8>>, !.avgPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 13, !.returnBitfield13 = <<16>>, !.dayAvgPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 15, !.returnBitfield15 = <<128>>, !.clientIdAttr = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = <<32>>, !.floorRoutingInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = <<128>>, !.orderOrigin = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 17, !.returnBitfield17 = <<32>>, !.floorTraderAcronym = one]) : one \in { <<held>> : held \in Sample(3) } }

(***************************************************************************)
(* Message, selected by Message Type                                       *)
(***************************************************************************)

LoginRequestMessageCode == 55  \* 0x37
LogoutRequestMessageCode == 2  \* 0x02
ClientHeartbeatMessageCode == 3  \* 0x03
LoginResponseMessageCode == 36  \* 0x24
LogoutMessageCode == 8  \* 0x08
ServerHeartbeatMessageCode == 9  \* 0x09
ReplayCompleteMessageCode == 19  \* 0x13
NewOrderMessageCode == 56  \* 0x38
CancelOrderMessageCode == 57  \* 0x39
ModifyOrderMessageCode == 58  \* 0x3a
QuoteUpdateMessageCode == 85  \* 0x55
ShortQuoteUpdateMessageCode == 89  \* 0x59
PurgeOrderMessageCode == 71  \* 0x47
RiskResetMessageCode == 86  \* 0x56
OrderAcknowledgmentMessageCode == 37  \* 0x25
QuoteUpdateAcknowledgmentMessageCode == 81  \* 0x51
OrderRejectedMessageCode == 38  \* 0x26
QuoteUpdateRejectedMessageCode == 88  \* 0x58
OrderModifiedMessageCode == 39  \* 0x27
OrderRestatedMessageCode == 40  \* 0x28
QuoteRestatedMessageCode == 82  \* 0x52
UserModifyRejectedMessageCode == 41  \* 0x29
OrderCancelledMessageCode == 42  \* 0x2a
QuoteCancelledMessageCode == 83  \* 0x53
CancelRejectedMessageCode == 43  \* 0x2b
QuoteExecutionMessageCode == 84  \* 0x54
TradeCancelOrCorrectMessageCode == 45  \* 0x2d
PurgeRejectedMessageCode == 72  \* 0x48
ResetRiskAcknowledgmentMessageCode == 87  \* 0x57
MassCancelAcknowledgmentMessageCode == 54  \* 0x36
OrderExecutionMessageCode == 44  \* 0x2c

Message ==
    [ tag : {LoginRequestMessageCode}, body : LoginRequestMessage ]
        \cup [ tag : {LogoutRequestMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ClientHeartbeatMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {LoginResponseMessageCode}, body : LoginResponseMessage ]
        \cup [ tag : {LogoutMessageCode}, body : LogoutMessage ]
        \cup [ tag : {ServerHeartbeatMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ReplayCompleteMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {NewOrderMessageCode}, body : NewOrderMessage ]
        \cup [ tag : {CancelOrderMessageCode}, body : CancelOrderMessage ]
        \cup [ tag : {ModifyOrderMessageCode}, body : ModifyOrderMessage ]
        \cup [ tag : {QuoteUpdateMessageCode}, body : QuoteUpdateMessage ]
        \cup [ tag : {ShortQuoteUpdateMessageCode}, body : ShortQuoteUpdateMessage ]
        \cup [ tag : {PurgeOrderMessageCode}, body : PurgeOrderMessage ]
        \cup [ tag : {RiskResetMessageCode}, body : RiskResetMessage ]
        \cup [ tag : {OrderAcknowledgmentMessageCode}, body : OrderAcknowledgmentMessage ]
        \cup [ tag : {QuoteUpdateAcknowledgmentMessageCode}, body : QuoteUpdateAcknowledgmentMessage ]
        \cup [ tag : {OrderRejectedMessageCode}, body : OrderRejectedMessage ]
        \cup [ tag : {QuoteUpdateRejectedMessageCode}, body : QuoteUpdateRejectedMessage ]
        \cup [ tag : {OrderModifiedMessageCode}, body : OrderModifiedMessage ]
        \cup [ tag : {OrderRestatedMessageCode}, body : OrderRestatedMessage ]
        \cup [ tag : {QuoteRestatedMessageCode}, body : QuoteRestatedMessage ]
        \cup [ tag : {UserModifyRejectedMessageCode}, body : UserModifyRejectedMessage ]
        \cup [ tag : {OrderCancelledMessageCode}, body : OrderCancelledMessage ]
        \cup [ tag : {QuoteCancelledMessageCode}, body : QuoteCancelledMessage ]
        \cup [ tag : {CancelRejectedMessageCode}, body : CancelRejectedMessage ]
        \cup [ tag : {QuoteExecutionMessageCode}, body : QuoteExecutionMessage ]
        \cup [ tag : {TradeCancelOrCorrectMessageCode}, body : TradeCancelOrCorrectMessage ]
        \cup [ tag : {PurgeRejectedMessageCode}, body : PurgeRejectedMessage ]
        \cup [ tag : {ResetRiskAcknowledgmentMessageCode}, body : ResetRiskAcknowledgmentMessage ]
        \cup [ tag : {MassCancelAcknowledgmentMessageCode}, body : MassCancelAcknowledgmentMessage ]
        \cup [ tag : {OrderExecutionMessageCode}, body : OrderExecutionMessage ]

EncodeMessage(message) ==
    CASE message.tag = LoginRequestMessageCode -> EncodeLoginRequestMessage(message.body)
      [] message.tag = LogoutRequestMessageCode -> << >>
      [] message.tag = ClientHeartbeatMessageCode -> << >>
      [] message.tag = LoginResponseMessageCode -> EncodeLoginResponseMessage(message.body)
      [] message.tag = LogoutMessageCode -> EncodeLogoutMessage(message.body)
      [] message.tag = ServerHeartbeatMessageCode -> << >>
      [] message.tag = ReplayCompleteMessageCode -> << >>
      [] message.tag = NewOrderMessageCode -> EncodeNewOrderMessage(message.body)
      [] message.tag = CancelOrderMessageCode -> EncodeCancelOrderMessage(message.body)
      [] message.tag = ModifyOrderMessageCode -> EncodeModifyOrderMessage(message.body)
      [] message.tag = QuoteUpdateMessageCode -> EncodeQuoteUpdateMessage(message.body)
      [] message.tag = ShortQuoteUpdateMessageCode -> EncodeShortQuoteUpdateMessage(message.body)
      [] message.tag = PurgeOrderMessageCode -> EncodePurgeOrderMessage(message.body)
      [] message.tag = RiskResetMessageCode -> EncodeRiskResetMessage(message.body)
      [] message.tag = OrderAcknowledgmentMessageCode -> EncodeOrderAcknowledgmentMessage(message.body)
      [] message.tag = QuoteUpdateAcknowledgmentMessageCode -> EncodeQuoteUpdateAcknowledgmentMessage(message.body)
      [] message.tag = OrderRejectedMessageCode -> EncodeOrderRejectedMessage(message.body)
      [] message.tag = QuoteUpdateRejectedMessageCode -> EncodeQuoteUpdateRejectedMessage(message.body)
      [] message.tag = OrderModifiedMessageCode -> EncodeOrderModifiedMessage(message.body)
      [] message.tag = OrderRestatedMessageCode -> EncodeOrderRestatedMessage(message.body)
      [] message.tag = QuoteRestatedMessageCode -> EncodeQuoteRestatedMessage(message.body)
      [] message.tag = UserModifyRejectedMessageCode -> EncodeUserModifyRejectedMessage(message.body)
      [] message.tag = OrderCancelledMessageCode -> EncodeOrderCancelledMessage(message.body)
      [] message.tag = QuoteCancelledMessageCode -> EncodeQuoteCancelledMessage(message.body)
      [] message.tag = CancelRejectedMessageCode -> EncodeCancelRejectedMessage(message.body)
      [] message.tag = QuoteExecutionMessageCode -> EncodeQuoteExecutionMessage(message.body)
      [] message.tag = TradeCancelOrCorrectMessageCode -> EncodeTradeCancelOrCorrectMessage(message.body)
      [] message.tag = PurgeRejectedMessageCode -> EncodePurgeRejectedMessage(message.body)
      [] message.tag = ResetRiskAcknowledgmentMessageCode -> EncodeResetRiskAcknowledgmentMessage(message.body)
      [] message.tag = MassCancelAcknowledgmentMessageCode -> EncodeMassCancelAcknowledgmentMessage(message.body)
      [] message.tag = OrderExecutionMessageCode -> EncodeOrderExecutionMessage(message.body)

DecodeMessage(tag, bytes) ==
    LET read ==
            CASE tag = LoginRequestMessageCode -> DecodeLoginRequestMessage(bytes)
              [] tag = LogoutRequestMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = ClientHeartbeatMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = LoginResponseMessageCode -> DecodeLoginResponseMessage(bytes)
              [] tag = LogoutMessageCode -> DecodeLogoutMessage(bytes)
              [] tag = ServerHeartbeatMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = ReplayCompleteMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = NewOrderMessageCode -> DecodeNewOrderMessage(bytes)
              [] tag = CancelOrderMessageCode -> DecodeCancelOrderMessage(bytes)
              [] tag = ModifyOrderMessageCode -> DecodeModifyOrderMessage(bytes)
              [] tag = QuoteUpdateMessageCode -> DecodeQuoteUpdateMessage(bytes)
              [] tag = ShortQuoteUpdateMessageCode -> DecodeShortQuoteUpdateMessage(bytes)
              [] tag = PurgeOrderMessageCode -> DecodePurgeOrderMessage(bytes)
              [] tag = RiskResetMessageCode -> DecodeRiskResetMessage(bytes)
              [] tag = OrderAcknowledgmentMessageCode -> DecodeOrderAcknowledgmentMessage(bytes)
              [] tag = QuoteUpdateAcknowledgmentMessageCode -> DecodeQuoteUpdateAcknowledgmentMessage(bytes)
              [] tag = OrderRejectedMessageCode -> DecodeOrderRejectedMessage(bytes)
              [] tag = QuoteUpdateRejectedMessageCode -> DecodeQuoteUpdateRejectedMessage(bytes)
              [] tag = OrderModifiedMessageCode -> DecodeOrderModifiedMessage(bytes)
              [] tag = OrderRestatedMessageCode -> DecodeOrderRestatedMessage(bytes)
              [] tag = QuoteRestatedMessageCode -> DecodeQuoteRestatedMessage(bytes)
              [] tag = UserModifyRejectedMessageCode -> DecodeUserModifyRejectedMessage(bytes)
              [] tag = OrderCancelledMessageCode -> DecodeOrderCancelledMessage(bytes)
              [] tag = QuoteCancelledMessageCode -> DecodeQuoteCancelledMessage(bytes)
              [] tag = CancelRejectedMessageCode -> DecodeCancelRejectedMessage(bytes)
              [] tag = QuoteExecutionMessageCode -> DecodeQuoteExecutionMessage(bytes)
              [] tag = TradeCancelOrCorrectMessageCode -> DecodeTradeCancelOrCorrectMessage(bytes)
              [] tag = PurgeRejectedMessageCode -> DecodePurgeRejectedMessage(bytes)
              [] tag = ResetRiskAcknowledgmentMessageCode -> DecodeResetRiskAcknowledgmentMessage(bytes)
              [] tag = MassCancelAcknowledgmentMessageCode -> DecodeMassCancelAcknowledgmentMessage(bytes)
              [] tag = OrderExecutionMessageCode -> DecodeOrderExecutionMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroMessage == [tag |-> LoginRequestMessageCode, body |-> ZeroLoginRequestMessage]

(* Each Message in turn, at the values the message it names is checked at *)
CheckedMessage ==
    { [tag |-> LoginRequestMessageCode, body |-> one] : one \in CheckedLoginRequestMessage }
        \cup { [tag |-> LogoutRequestMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> ClientHeartbeatMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> LoginResponseMessageCode, body |-> one] : one \in CheckedLoginResponseMessage }
        \cup { [tag |-> LogoutMessageCode, body |-> one] : one \in CheckedLogoutMessage }
        \cup { [tag |-> ServerHeartbeatMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> ReplayCompleteMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> NewOrderMessageCode, body |-> one] : one \in CheckedNewOrderMessage }
        \cup { [tag |-> CancelOrderMessageCode, body |-> one] : one \in CheckedCancelOrderMessage }
        \cup { [tag |-> ModifyOrderMessageCode, body |-> one] : one \in CheckedModifyOrderMessage }
        \cup { [tag |-> QuoteUpdateMessageCode, body |-> one] : one \in CheckedQuoteUpdateMessage }
        \cup { [tag |-> ShortQuoteUpdateMessageCode, body |-> one] : one \in CheckedShortQuoteUpdateMessage }
        \cup { [tag |-> PurgeOrderMessageCode, body |-> one] : one \in CheckedPurgeOrderMessage }
        \cup { [tag |-> RiskResetMessageCode, body |-> one] : one \in CheckedRiskResetMessage }
        \cup { [tag |-> OrderAcknowledgmentMessageCode, body |-> one] : one \in CheckedOrderAcknowledgmentMessage }
        \cup { [tag |-> QuoteUpdateAcknowledgmentMessageCode, body |-> one] : one \in CheckedQuoteUpdateAcknowledgmentMessage }
        \cup { [tag |-> OrderRejectedMessageCode, body |-> one] : one \in CheckedOrderRejectedMessage }
        \cup { [tag |-> QuoteUpdateRejectedMessageCode, body |-> one] : one \in CheckedQuoteUpdateRejectedMessage }
        \cup { [tag |-> OrderModifiedMessageCode, body |-> one] : one \in CheckedOrderModifiedMessage }
        \cup { [tag |-> OrderRestatedMessageCode, body |-> one] : one \in CheckedOrderRestatedMessage }
        \cup { [tag |-> QuoteRestatedMessageCode, body |-> one] : one \in CheckedQuoteRestatedMessage }
        \cup { [tag |-> UserModifyRejectedMessageCode, body |-> one] : one \in CheckedUserModifyRejectedMessage }
        \cup { [tag |-> OrderCancelledMessageCode, body |-> one] : one \in CheckedOrderCancelledMessage }
        \cup { [tag |-> QuoteCancelledMessageCode, body |-> one] : one \in CheckedQuoteCancelledMessage }
        \cup { [tag |-> CancelRejectedMessageCode, body |-> one] : one \in CheckedCancelRejectedMessage }
        \cup { [tag |-> QuoteExecutionMessageCode, body |-> one] : one \in CheckedQuoteExecutionMessage }
        \cup { [tag |-> TradeCancelOrCorrectMessageCode, body |-> one] : one \in CheckedTradeCancelOrCorrectMessage }
        \cup { [tag |-> PurgeRejectedMessageCode, body |-> one] : one \in CheckedPurgeRejectedMessage }
        \cup { [tag |-> ResetRiskAcknowledgmentMessageCode, body |-> one] : one \in CheckedResetRiskAcknowledgmentMessage }
        \cup { [tag |-> MassCancelAcknowledgmentMessageCode, body |-> one] : one \in CheckedMassCancelAcknowledgmentMessage }
        \cup { [tag |-> OrderExecutionMessageCode, body |-> one] : one \in CheckedOrderExecutionMessage }

(***************************************************************************)
(* Packet, framed by Message Length                                        *)
(***************************************************************************)

Packet ==
    [ startOfMessage : Sample(2),
      matchingUnit   : Sample(1),
      sequenceNumber : Sample(4),
      message        : Message ]

EncodePacketBody(message) ==
    EncodeUIntBE(message.message.tag, 1)
        \o message.matchingUnit
        \o message.sequenceNumber
        \o EncodeMessage(message.message)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodePacket(message) ==
    LET body == EncodePacketBody(message)
    IN  message.startOfMessage \o EncodeUIntLE(Len(body) + 2, 2) \o body

DecodePacket(bytes) ==
    LET startOfMessage == ReadBytes(bytes, 2) IN IF ~startOfMessage.ok THEN Fail ELSE
    LET length == ReadUIntLE(startOfMessage.rest, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
    IN
    LET messageType == ReadUIntBE(framed, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET matchingUnit == ReadBytes(messageType.rest, 1) IN IF ~matchingUnit.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(matchingUnit.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET message == DecodeMessage(messageType.value, sequenceNumber.rest) IN IF ~message.ok THEN Fail ELSE
    IF message.rest # << >> THEN Fail ELSE
    Ok([ startOfMessage |-> startOfMessage.value,
         matchingUnit   |-> matchingUnit.value,
         sequenceNumber |-> sequenceNumber.value,
         message        |-> message.value ], beyond)

ZeroPacket ==
    [ startOfMessage |-> [i \in 1 .. 2 |-> 0],
      matchingUnit   |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber |-> [i \in 1 .. 4 |-> 0],
      message        |-> ZeroMessage ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.startOfMessage = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.matchingUnit = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.message = one] : one \in CheckedMessage }

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

(* Every Unit Sequence decodes back to what was encoded, and leaves nothing over *)
RoundTripUnitSequence ==
    \A message \in CheckedUnitSequence :
        LET read == DecodeUnitSequence(EncodeUnitSequence(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Unit Sequences Param Group decodes back to what was encoded, and leaves nothing over *)
RoundTripUnitSequencesParamGroup ==
    \A message \in CheckedUnitSequencesParamGroup :
        LET read == DecodeUnitSequencesParamGroup(EncodeUnitSequencesParamGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Return Bitfields Param Group decodes back to what was encoded, and leaves nothing over *)
RoundTripReturnBitfieldsParamGroup ==
    \A message \in CheckedReturnBitfieldsParamGroup :
        LET read == DecodeReturnBitfieldsParamGroup(EncodeReturnBitfieldsParamGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Param Group decodes back to what was encoded, and leaves nothing over *)
RoundTripParamGroup ==
    \A message \in CheckedParamGroup :
        LET read == DecodeParamGroup(EncodeParamGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRequestMessage ==
    \A message \in CheckedLoginRequestMessage :
        LET read == DecodeLoginRequestMessage(EncodeLoginRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Unit Sequence decodes back to what was encoded, and leaves nothing over *)
RoundTripUnitSequence2 ==
    \A message \in CheckedUnitSequence2 :
        LET read == DecodeUnitSequence2(EncodeUnitSequence2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Unit Sequence decodes back to what was encoded, and leaves nothing over *)
RoundTripUnitSequence3 ==
    \A message \in CheckedUnitSequence3 :
        LET read == DecodeUnitSequence3(EncodeUnitSequence3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Unit Sequences Param Group decodes back to what was encoded, and leaves nothing over *)
RoundTripUnitSequencesParamGroup2 ==
    \A message \in CheckedUnitSequencesParamGroup2 :
        LET read == DecodeUnitSequencesParamGroup2(EncodeUnitSequencesParamGroup2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Return Bitfields Param Group decodes back to what was encoded, and leaves nothing over *)
RoundTripReturnBitfieldsParamGroup2 ==
    \A message \in CheckedReturnBitfieldsParamGroup2 :
        LET read == DecodeReturnBitfieldsParamGroup2(EncodeReturnBitfieldsParamGroup2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Param Group decodes back to what was encoded, and leaves nothing over *)
RoundTripParamGroup2 ==
    \A message \in CheckedParamGroup2 :
        LET read == DecodeParamGroup2(EncodeParamGroup2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginResponseMessage ==
    \A message \in CheckedLoginResponseMessage :
        LET read == DecodeLoginResponseMessage(EncodeLoginResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Unit Sequence decodes back to what was encoded, and leaves nothing over *)
RoundTripUnitSequence4 ==
    \A message \in CheckedUnitSequence4 :
        LET read == DecodeUnitSequence4(EncodeUnitSequence4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logout Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogoutMessage ==
    \A message \in CheckedLogoutMessage :
        LET read == DecodeLogoutMessage(EncodeLogoutMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderMessage ==
    \A message \in CheckedNewOrderMessage :
        LET read == DecodeNewOrderMessage(EncodeNewOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelOrderMessage ==
    \A message \in CheckedCancelOrderMessage :
        LET read == DecodeCancelOrderMessage(EncodeCancelOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyOrderMessage ==
    \A message \in CheckedModifyOrderMessage :
        LET read == DecodeModifyOrderMessage(EncodeModifyOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Update decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteUpdate ==
    \A message \in CheckedQuoteUpdate :
        LET read == DecodeQuoteUpdate(EncodeQuoteUpdate(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteUpdateMessage ==
    \A message \in CheckedQuoteUpdateMessage :
        LET read == DecodeQuoteUpdateMessage(EncodeQuoteUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Short Quote Update decodes back to what was encoded, and leaves nothing over *)
RoundTripShortQuoteUpdate ==
    \A message \in CheckedShortQuoteUpdate :
        LET read == DecodeShortQuoteUpdate(EncodeShortQuoteUpdate(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Short Quote Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripShortQuoteUpdateMessage ==
    \A message \in CheckedShortQuoteUpdateMessage :
        LET read == DecodeShortQuoteUpdateMessage(EncodeShortQuoteUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Purge Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPurgeOrderMessage ==
    \A message \in CheckedPurgeOrderMessage :
        LET read == DecodePurgeOrderMessage(EncodePurgeOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Risk Reset Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRiskResetMessage ==
    \A message \in CheckedRiskResetMessage :
        LET read == DecodeRiskResetMessage(EncodeRiskResetMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Acknowledgment Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderAcknowledgmentMessage ==
    \A message \in CheckedOrderAcknowledgmentMessage :
        LET read == DecodeOrderAcknowledgmentMessage(EncodeOrderAcknowledgmentMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Result Group decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteResultGroup ==
    \A message \in CheckedQuoteResultGroup :
        LET read == DecodeQuoteResultGroup(EncodeQuoteResultGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Update Acknowledgment Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteUpdateAcknowledgmentMessage ==
    \A message \in CheckedQuoteUpdateAcknowledgmentMessage :
        LET read == DecodeQuoteUpdateAcknowledgmentMessage(EncodeQuoteUpdateAcknowledgmentMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderRejectedMessage ==
    \A message \in CheckedOrderRejectedMessage :
        LET read == DecodeOrderRejectedMessage(EncodeOrderRejectedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Update Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteUpdateRejectedMessage ==
    \A message \in CheckedQuoteUpdateRejectedMessage :
        LET read == DecodeQuoteUpdateRejectedMessage(EncodeQuoteUpdateRejectedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Modified Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderModifiedMessage ==
    \A message \in CheckedOrderModifiedMessage :
        LET read == DecodeOrderModifiedMessage(EncodeOrderModifiedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Restated Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderRestatedMessage ==
    \A message \in CheckedOrderRestatedMessage :
        LET read == DecodeOrderRestatedMessage(EncodeOrderRestatedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Restated Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteRestatedMessage ==
    \A message \in CheckedQuoteRestatedMessage :
        LET read == DecodeQuoteRestatedMessage(EncodeQuoteRestatedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every User Modify Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUserModifyRejectedMessage ==
    \A message \in CheckedUserModifyRejectedMessage :
        LET read == DecodeUserModifyRejectedMessage(EncodeUserModifyRejectedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancelled Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelledMessage ==
    \A message \in CheckedOrderCancelledMessage :
        LET read == DecodeOrderCancelledMessage(EncodeOrderCancelledMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Cancelled Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteCancelledMessage ==
    \A message \in CheckedQuoteCancelledMessage :
        LET read == DecodeQuoteCancelledMessage(EncodeQuoteCancelledMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelRejectedMessage ==
    \A message \in CheckedCancelRejectedMessage :
        LET read == DecodeCancelRejectedMessage(EncodeCancelRejectedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Execution Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteExecutionMessage ==
    \A message \in CheckedQuoteExecutionMessage :
        LET read == DecodeQuoteExecutionMessage(EncodeQuoteExecutionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Cancel Or Correct Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCancelOrCorrectMessage ==
    \A message \in CheckedTradeCancelOrCorrectMessage :
        LET read == DecodeTradeCancelOrCorrectMessage(EncodeTradeCancelOrCorrectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Purge Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPurgeRejectedMessage ==
    \A message \in CheckedPurgeRejectedMessage :
        LET read == DecodePurgeRejectedMessage(EncodePurgeRejectedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reset Risk Acknowledgment Message decodes back to what was encoded, and leaves nothing over *)
RoundTripResetRiskAcknowledgmentMessage ==
    \A message \in CheckedResetRiskAcknowledgmentMessage :
        LET read == DecodeResetRiskAcknowledgmentMessage(EncodeResetRiskAcknowledgmentMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Cancel Acknowledgment Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMassCancelAcknowledgmentMessage ==
    \A message \in CheckedMassCancelAcknowledgmentMessage :
        LET read == DecodeMassCancelAcknowledgmentMessage(EncodeMassCancelAcknowledgmentMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Execution Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutionMessage ==
    \A message \in CheckedOrderExecutionMessage :
        LET read == DecodeOrderExecutionMessage(EncodeOrderExecutionMessage(message))
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

(* A ParamGroupPayload is selected by the Param Group Type it is written under *)
SelectsParamgrouppayload ==
    \A message \in CheckedParamgrouppayload :
        LET sent == EncodeParamgrouppayload(message)
            read == DecodeParamgrouppayload(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A ParamGroupPayload is selected by the Param Group Type it is written under *)
SelectsParamgrouppayload2 ==
    \A message \in CheckedParamgrouppayload2 :
        LET sent == EncodeParamgrouppayload2(message)
            read == DecodeParamgrouppayload2(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Message is selected by the Message Type it is written under *)
SelectsMessage ==
    \A message \in CheckedMessage :
        LET sent == EncodeMessage(message)
            read == DecodeMessage(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* Message Length is written from the bytes it frames *)
FramesPacket ==
    \A message \in CheckedPacket :
        LET bytes == EncodePacket(message)
        IN  DecodeUIntLE(SubSeq(bytes, 3, 4)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
