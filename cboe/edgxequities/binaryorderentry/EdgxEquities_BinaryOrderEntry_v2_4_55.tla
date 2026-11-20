--------------- MODULE EdgxEquities_BinaryOrderEntry_v2_4_55 ---------------
(***************************************************************************)
(* Chicago Board Options Exchange Binary Order Entry v2.4.55               *)
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
(* Note: Purge Orders Message fills what is left of the frame Message      *)
(* Length states, which is what it is read from.                           *)
(*                                                                         *)
(* Note: Order Acknowledgment Message fills what is left of the frame      *)
(* Message Length states, which is what it is read from.                   *)
(*                                                                         *)
(* Note: Order Rejected Message fills what is left of the frame Message    *)
(* Length states, which is what it is read from.                           *)
(*                                                                         *)
(* Note: Order Modified Message fills what is left of the frame Message    *)
(* Length states, which is what it is read from.                           *)
(*                                                                         *)
(* Note: Order Restated Message fills what is left of the frame Message    *)
(* Length states, which is what it is read from.                           *)
(*                                                                         *)
(* Note: User Modify Rejected Message fills what is left of the frame      *)
(* Message Length states, which is what it is read from.                   *)
(*                                                                         *)
(* Note: Order Cancelled Message fills what is left of the frame Message   *)
(* Length states, which is what it is read from.                           *)
(*                                                                         *)
(* Note: Cancel Rejected Message fills what is left of the frame Message   *)
(* Length states, which is what it is read from.                           *)
(*                                                                         *)
(* Note: Order Execution Message fills what is left of the frame Message   *)
(* Length states, which is what it is read from.                           *)
(*                                                                         *)
(* Note: Trade Cancel Or Correct Message fills what is left of the frame   *)
(* Message Length states, which is what it is read from.                   *)
(*                                                                         *)
(* Note: Mass Cancel Acknowledgment Message fills what is left of the      *)
(* frame Message Length states, which is what it is read from.             *)
(*                                                                         *)
(* Note: Purge Rejected Message fills what is left of the frame Message    *)
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
(* Unit Sequences: 5 bytes                                                 *)
(***************************************************************************)

UnitSequences ==
    [ unitNumber   : Sample(1),
      unitSequence : Sample(4) ]

EncodeUnitSequences(message) ==
    message.unitNumber
        \o message.unitSequence

DecodeUnitSequences(bytes) ==
    LET unitNumber == ReadBytes(bytes, 1) IN IF ~unitNumber.ok THEN Fail ELSE
    LET unitSequence == ReadBytes(unitNumber.rest, 4) IN IF ~unitSequence.ok THEN Fail ELSE
    Ok([ unitNumber   |-> unitNumber.value,
         unitSequence |-> unitSequence.value ], unitSequence.rest)

ZeroUnitSequences ==
    [ unitNumber   |-> [i \in 1 .. 1 |-> 0],
      unitSequence |-> [i \in 1 .. 4 |-> 0] ]

(* Unit Sequences at zero, then each field in turn at the values it is checked at *)
CheckedUnitSequences ==
    { ZeroUnitSequences }
        \cup { [ZeroUnitSequences EXCEPT !.unitNumber = one] : one \in Sample(1) }
        \cup { [ZeroUnitSequences EXCEPT !.unitSequence = one] : one \in Sample(4) }

(* A run of Unit Sequences, written one after another *)
RECURSIVE EncodeUnitSequencesList(_)
EncodeUnitSequencesList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeUnitSequences(Head(messages)) \o EncodeUnitSequencesList(Tail(messages))

(* As many Unit Sequences as the field that counts them says *)
RECURSIVE ReadUnitSequencesList(_, _)
ReadUnitSequencesList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeUnitSequences(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadUnitSequencesList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Unit Sequences of each kind, for the lists that carry them *)
OneUnitSequences == { ZeroUnitSequences }

(***************************************************************************)
(* Unit Sequences Param Group                                              *)
(***************************************************************************)

UnitSequencesParamGroup ==
    [ noUnspecifiedUnitReplay : Sample(1),
      unitSequences           : SampleLists(OneUnitSequences) ]

EncodeUnitSequencesParamGroup(message) ==
    message.noUnspecifiedUnitReplay
        \o EncodeUIntBE(Len(message.unitSequences), 1)
        \o EncodeUnitSequencesList(message.unitSequences)

DecodeUnitSequencesParamGroup(bytes) ==
    LET noUnspecifiedUnitReplay == ReadBytes(bytes, 1) IN IF ~noUnspecifiedUnitReplay.ok THEN Fail ELSE
    LET numberOfUnits == ReadUIntBE(noUnspecifiedUnitReplay.rest, 1) IN IF ~numberOfUnits.ok THEN Fail ELSE
    LET unitSequences == ReadUnitSequencesList(numberOfUnits.rest, numberOfUnits.value) IN IF ~unitSequences.ok THEN Fail ELSE
    Ok([ noUnspecifiedUnitReplay |-> noUnspecifiedUnitReplay.value,
         unitSequences           |-> unitSequences.value ], unitSequences.rest)

ZeroUnitSequencesParamGroup ==
    [ noUnspecifiedUnitReplay |-> [i \in 1 .. 1 |-> 0],
      unitSequences           |-> << >> ]

(* Unit Sequences Param Group at zero, then each field in turn at the values it is checked at *)
CheckedUnitSequencesParamGroup ==
    { ZeroUnitSequencesParamGroup }
        \cup { [ZeroUnitSequencesParamGroup EXCEPT !.noUnspecifiedUnitReplay = one] : one \in Sample(1) }
        \cup { [ZeroUnitSequencesParamGroup EXCEPT !.unitSequences = one] : one \in SampleLists(OneUnitSequences) }

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
      returnBitfield17        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield18        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield19        : { << >> } \cup { <<held>> : held \in Sample(1) } ]

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
        \o (IF message.returnBitfield18 = << >> THEN << >> ELSE message.returnBitfield18[1])
        \o (IF message.returnBitfield19 = << >> THEN << >> ELSE message.returnBitfield19[1])

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
    LET returnBitfield18 == ReadWhen(numberOfReturnBitfields.value >= 18, ReadBytes(returnBitfield17.rest, 1), returnBitfield17.rest) IN IF ~returnBitfield18.ok THEN Fail ELSE
    LET returnBitfield19 == ReadWhen(numberOfReturnBitfields.value >= 19, ReadBytes(returnBitfield18.rest, 1), returnBitfield18.rest) IN IF ~returnBitfield19.ok THEN Fail ELSE
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
         returnBitfield17        |-> returnBitfield17.value,
         returnBitfield18        |-> returnBitfield18.value,
         returnBitfield19        |-> returnBitfield19.value ], returnBitfield19.rest)

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
        settled18 == [settled17 EXCEPT !.returnBitfield18 = IF settled17.numberOfReturnBitfields >= 18 THEN (IF settled17.returnBitfield18 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.returnBitfield18) ELSE << >>]
        settled19 == [settled18 EXCEPT !.returnBitfield19 = IF settled18.numberOfReturnBitfields >= 19 THEN (IF settled18.returnBitfield19 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled18.returnBitfield19) ELSE << >>]
    IN  settled19

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
                                      returnBitfield17        |-> << >>,
                                      returnBitfield18        |-> << >>,
                                      returnBitfield19        |-> << >> ])

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
        \cup { SettleReturnBitfieldsParamGroup([ZeroReturnBitfieldsParamGroup EXCEPT !.numberOfReturnBitfields = 18, !.returnBitfield18 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup([ZeroReturnBitfieldsParamGroup EXCEPT !.numberOfReturnBitfields = 19, !.returnBitfield19 = one]) : one \in { <<held>> : held \in Sample(1) } }

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
(* Unit Sequences: 5 bytes                                                 *)
(***************************************************************************)

UnitSequences2 ==
    [ unitNumber   : Sample(1),
      unitSequence : Sample(4) ]

EncodeUnitSequences2(message) ==
    message.unitNumber
        \o message.unitSequence

DecodeUnitSequences2(bytes) ==
    LET unitNumber == ReadBytes(bytes, 1) IN IF ~unitNumber.ok THEN Fail ELSE
    LET unitSequence == ReadBytes(unitNumber.rest, 4) IN IF ~unitSequence.ok THEN Fail ELSE
    Ok([ unitNumber   |-> unitNumber.value,
         unitSequence |-> unitSequence.value ], unitSequence.rest)

ZeroUnitSequences2 ==
    [ unitNumber   |-> [i \in 1 .. 1 |-> 0],
      unitSequence |-> [i \in 1 .. 4 |-> 0] ]

(* Unit Sequences at zero, then each field in turn at the values it is checked at *)
CheckedUnitSequences2 ==
    { ZeroUnitSequences2 }
        \cup { [ZeroUnitSequences2 EXCEPT !.unitNumber = one] : one \in Sample(1) }
        \cup { [ZeroUnitSequences2 EXCEPT !.unitSequence = one] : one \in Sample(4) }

(* A run of Unit Sequences, written one after another *)
RECURSIVE EncodeUnitSequences2List(_)
EncodeUnitSequences2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeUnitSequences2(Head(messages)) \o EncodeUnitSequences2List(Tail(messages))

(* As many Unit Sequences as the field that counts them says *)
RECURSIVE ReadUnitSequences2List(_, _)
ReadUnitSequences2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeUnitSequences2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadUnitSequences2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Unit Sequences of each kind, for the lists that carry them *)
OneUnitSequences2 == { ZeroUnitSequences2 }

(***************************************************************************)
(* Unit Sequences: 5 bytes                                                 *)
(***************************************************************************)

UnitSequences3 ==
    [ unitNumber   : Sample(1),
      unitSequence : Sample(4) ]

EncodeUnitSequences3(message) ==
    message.unitNumber
        \o message.unitSequence

DecodeUnitSequences3(bytes) ==
    LET unitNumber == ReadBytes(bytes, 1) IN IF ~unitNumber.ok THEN Fail ELSE
    LET unitSequence == ReadBytes(unitNumber.rest, 4) IN IF ~unitSequence.ok THEN Fail ELSE
    Ok([ unitNumber   |-> unitNumber.value,
         unitSequence |-> unitSequence.value ], unitSequence.rest)

ZeroUnitSequences3 ==
    [ unitNumber   |-> [i \in 1 .. 1 |-> 0],
      unitSequence |-> [i \in 1 .. 4 |-> 0] ]

(* Unit Sequences at zero, then each field in turn at the values it is checked at *)
CheckedUnitSequences3 ==
    { ZeroUnitSequences3 }
        \cup { [ZeroUnitSequences3 EXCEPT !.unitNumber = one] : one \in Sample(1) }
        \cup { [ZeroUnitSequences3 EXCEPT !.unitSequence = one] : one \in Sample(4) }

(* A run of Unit Sequences, written one after another *)
RECURSIVE EncodeUnitSequences3List(_)
EncodeUnitSequences3List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeUnitSequences3(Head(messages)) \o EncodeUnitSequences3List(Tail(messages))

(* As many Unit Sequences as the field that counts them says *)
RECURSIVE ReadUnitSequences3List(_, _)
ReadUnitSequences3List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeUnitSequences3(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadUnitSequences3List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Unit Sequences of each kind, for the lists that carry them *)
OneUnitSequences3 == { ZeroUnitSequences3 }

(***************************************************************************)
(* Unit Sequences Param Group                                              *)
(***************************************************************************)

UnitSequencesParamGroup2 ==
    [ noUnspecifiedUnitReplay : Sample(1),
      unitSequences           : SampleLists(OneUnitSequences3) ]

EncodeUnitSequencesParamGroup2(message) ==
    message.noUnspecifiedUnitReplay
        \o EncodeUIntBE(Len(message.unitSequences), 1)
        \o EncodeUnitSequences3List(message.unitSequences)

DecodeUnitSequencesParamGroup2(bytes) ==
    LET noUnspecifiedUnitReplay == ReadBytes(bytes, 1) IN IF ~noUnspecifiedUnitReplay.ok THEN Fail ELSE
    LET numberOfUnits == ReadUIntBE(noUnspecifiedUnitReplay.rest, 1) IN IF ~numberOfUnits.ok THEN Fail ELSE
    LET unitSequences == ReadUnitSequences3List(numberOfUnits.rest, numberOfUnits.value) IN IF ~unitSequences.ok THEN Fail ELSE
    Ok([ noUnspecifiedUnitReplay |-> noUnspecifiedUnitReplay.value,
         unitSequences           |-> unitSequences.value ], unitSequences.rest)

ZeroUnitSequencesParamGroup2 ==
    [ noUnspecifiedUnitReplay |-> [i \in 1 .. 1 |-> 0],
      unitSequences           |-> << >> ]

(* Unit Sequences Param Group at zero, then each field in turn at the values it is checked at *)
CheckedUnitSequencesParamGroup2 ==
    { ZeroUnitSequencesParamGroup2 }
        \cup { [ZeroUnitSequencesParamGroup2 EXCEPT !.noUnspecifiedUnitReplay = one] : one \in Sample(1) }
        \cup { [ZeroUnitSequencesParamGroup2 EXCEPT !.unitSequences = one] : one \in SampleLists(OneUnitSequences3) }

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
      returnBitfield17        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield18        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield19        : { << >> } \cup { <<held>> : held \in Sample(1) } ]

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
        \o (IF message.returnBitfield18 = << >> THEN << >> ELSE message.returnBitfield18[1])
        \o (IF message.returnBitfield19 = << >> THEN << >> ELSE message.returnBitfield19[1])

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
    LET returnBitfield18 == ReadWhen(numberOfReturnBitfields.value >= 18, ReadBytes(returnBitfield17.rest, 1), returnBitfield17.rest) IN IF ~returnBitfield18.ok THEN Fail ELSE
    LET returnBitfield19 == ReadWhen(numberOfReturnBitfields.value >= 19, ReadBytes(returnBitfield18.rest, 1), returnBitfield18.rest) IN IF ~returnBitfield19.ok THEN Fail ELSE
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
         returnBitfield17        |-> returnBitfield17.value,
         returnBitfield18        |-> returnBitfield18.value,
         returnBitfield19        |-> returnBitfield19.value ], returnBitfield19.rest)

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
        settled18 == [settled17 EXCEPT !.returnBitfield18 = IF settled17.numberOfReturnBitfields >= 18 THEN (IF settled17.returnBitfield18 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.returnBitfield18) ELSE << >>]
        settled19 == [settled18 EXCEPT !.returnBitfield19 = IF settled18.numberOfReturnBitfields >= 19 THEN (IF settled18.returnBitfield19 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled18.returnBitfield19) ELSE << >>]
    IN  settled19

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
                                       returnBitfield17        |-> << >>,
                                       returnBitfield18        |-> << >>,
                                       returnBitfield19        |-> << >> ])

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
        \cup { SettleReturnBitfieldsParamGroup2([ZeroReturnBitfieldsParamGroup2 EXCEPT !.numberOfReturnBitfields = 18, !.returnBitfield18 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup2([ZeroReturnBitfieldsParamGroup2 EXCEPT !.numberOfReturnBitfields = 19, !.returnBitfield19 = one]) : one \in { <<held>> : held \in Sample(1) } }

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
      unitSequences              : SampleLists(OneUnitSequences2),
      paramGroup                 : SampleLists(OneParamGroup2) ]

EncodeLoginResponseMessage(message) ==
    message.loginResponseStatus
        \o message.loginResponseText
        \o message.noUnspecifiedUnitReplay
        \o message.lastReceivedSequenceNumber
        \o EncodeUIntBE(Len(message.unitSequences), 1)
        \o EncodeUnitSequences2List(message.unitSequences)
        \o EncodeUIntBE(Len(message.paramGroup), 1)
        \o EncodeParamGroup2List(message.paramGroup)

DecodeLoginResponseMessage(bytes) ==
    LET loginResponseStatus == ReadBytes(bytes, 1) IN IF ~loginResponseStatus.ok THEN Fail ELSE
    LET loginResponseText == ReadBytes(loginResponseStatus.rest, 60) IN IF ~loginResponseText.ok THEN Fail ELSE
    LET noUnspecifiedUnitReplay == ReadBytes(loginResponseText.rest, 1) IN IF ~noUnspecifiedUnitReplay.ok THEN Fail ELSE
    LET lastReceivedSequenceNumber == ReadBytes(noUnspecifiedUnitReplay.rest, 4) IN IF ~lastReceivedSequenceNumber.ok THEN Fail ELSE
    LET numberOfUnits == ReadUIntBE(lastReceivedSequenceNumber.rest, 1) IN IF ~numberOfUnits.ok THEN Fail ELSE
    LET unitSequences == ReadUnitSequences2List(numberOfUnits.rest, numberOfUnits.value) IN IF ~unitSequences.ok THEN Fail ELSE
    LET numberOfParamGroups == ReadUIntBE(unitSequences.rest, 1) IN IF ~numberOfParamGroups.ok THEN Fail ELSE
    LET paramGroup == ReadParamGroup2List(numberOfParamGroups.rest, numberOfParamGroups.value) IN IF ~paramGroup.ok THEN Fail ELSE
    Ok([ loginResponseStatus        |-> loginResponseStatus.value,
         loginResponseText          |-> loginResponseText.value,
         noUnspecifiedUnitReplay    |-> noUnspecifiedUnitReplay.value,
         lastReceivedSequenceNumber |-> lastReceivedSequenceNumber.value,
         unitSequences              |-> unitSequences.value,
         paramGroup                 |-> paramGroup.value ], paramGroup.rest)

ZeroLoginResponseMessage ==
    [ loginResponseStatus        |-> [i \in 1 .. 1 |-> 0],
      loginResponseText          |-> [i \in 1 .. 60 |-> 0],
      noUnspecifiedUnitReplay    |-> [i \in 1 .. 1 |-> 0],
      lastReceivedSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      unitSequences              |-> << >>,
      paramGroup                 |-> << >> ]

(* Login Response Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginResponseMessage ==
    { ZeroLoginResponseMessage }
        \cup { [ZeroLoginResponseMessage EXCEPT !.loginResponseStatus = one] : one \in Sample(1) }
        \cup { [ZeroLoginResponseMessage EXCEPT !.loginResponseText = one] : one \in Sample(60) }
        \cup { [ZeroLoginResponseMessage EXCEPT !.noUnspecifiedUnitReplay = one] : one \in Sample(1) }
        \cup { [ZeroLoginResponseMessage EXCEPT !.lastReceivedSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroLoginResponseMessage EXCEPT !.unitSequences = one] : one \in SampleLists(OneUnitSequences2) }
        \cup { [ZeroLoginResponseMessage EXCEPT !.paramGroup = one] : one \in SampleLists(OneParamGroup2) }

(***************************************************************************)
(* Unit Sequences: 5 bytes                                                 *)
(***************************************************************************)

UnitSequences4 ==
    [ unitNumber   : Sample(1),
      unitSequence : Sample(4) ]

EncodeUnitSequences4(message) ==
    message.unitNumber
        \o message.unitSequence

DecodeUnitSequences4(bytes) ==
    LET unitNumber == ReadBytes(bytes, 1) IN IF ~unitNumber.ok THEN Fail ELSE
    LET unitSequence == ReadBytes(unitNumber.rest, 4) IN IF ~unitSequence.ok THEN Fail ELSE
    Ok([ unitNumber   |-> unitNumber.value,
         unitSequence |-> unitSequence.value ], unitSequence.rest)

ZeroUnitSequences4 ==
    [ unitNumber   |-> [i \in 1 .. 1 |-> 0],
      unitSequence |-> [i \in 1 .. 4 |-> 0] ]

(* Unit Sequences at zero, then each field in turn at the values it is checked at *)
CheckedUnitSequences4 ==
    { ZeroUnitSequences4 }
        \cup { [ZeroUnitSequences4 EXCEPT !.unitNumber = one] : one \in Sample(1) }
        \cup { [ZeroUnitSequences4 EXCEPT !.unitSequence = one] : one \in Sample(4) }

(* A run of Unit Sequences, written one after another *)
RECURSIVE EncodeUnitSequences4List(_)
EncodeUnitSequences4List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeUnitSequences4(Head(messages)) \o EncodeUnitSequences4List(Tail(messages))

(* As many Unit Sequences as the field that counts them says *)
RECURSIVE ReadUnitSequences4List(_, _)
ReadUnitSequences4List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeUnitSequences4(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadUnitSequences4List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Unit Sequences of each kind, for the lists that carry them *)
OneUnitSequences4 == { ZeroUnitSequences4 }

(***************************************************************************)
(* Logout Message                                                          *)
(***************************************************************************)

LogoutMessage ==
    [ logoutReason               : Sample(1),
      logoutReasonText           : Sample(60),
      lastReceivedSequenceNumber : Sample(4),
      unitSequences              : SampleLists(OneUnitSequences4) ]

EncodeLogoutMessage(message) ==
    message.logoutReason
        \o message.logoutReasonText
        \o message.lastReceivedSequenceNumber
        \o EncodeUIntBE(Len(message.unitSequences), 1)
        \o EncodeUnitSequences4List(message.unitSequences)

DecodeLogoutMessage(bytes) ==
    LET logoutReason == ReadBytes(bytes, 1) IN IF ~logoutReason.ok THEN Fail ELSE
    LET logoutReasonText == ReadBytes(logoutReason.rest, 60) IN IF ~logoutReasonText.ok THEN Fail ELSE
    LET lastReceivedSequenceNumber == ReadBytes(logoutReasonText.rest, 4) IN IF ~lastReceivedSequenceNumber.ok THEN Fail ELSE
    LET numberOfUnits == ReadUIntBE(lastReceivedSequenceNumber.rest, 1) IN IF ~numberOfUnits.ok THEN Fail ELSE
    LET unitSequences == ReadUnitSequences4List(numberOfUnits.rest, numberOfUnits.value) IN IF ~unitSequences.ok THEN Fail ELSE
    Ok([ logoutReason               |-> logoutReason.value,
         logoutReasonText           |-> logoutReasonText.value,
         lastReceivedSequenceNumber |-> lastReceivedSequenceNumber.value,
         unitSequences              |-> unitSequences.value ], unitSequences.rest)

ZeroLogoutMessage ==
    [ logoutReason               |-> [i \in 1 .. 1 |-> 0],
      logoutReasonText           |-> [i \in 1 .. 60 |-> 0],
      lastReceivedSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      unitSequences              |-> << >> ]

(* Logout Message at zero, then each field in turn at the values it is checked at *)
CheckedLogoutMessage ==
    { ZeroLogoutMessage }
        \cup { [ZeroLogoutMessage EXCEPT !.logoutReason = one] : one \in Sample(1) }
        \cup { [ZeroLogoutMessage EXCEPT !.logoutReasonText = one] : one \in Sample(60) }
        \cup { [ZeroLogoutMessage EXCEPT !.lastReceivedSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroLogoutMessage EXCEPT !.unitSequences = one] : one \in SampleLists(OneUnitSequences4) }

(***************************************************************************)
(* New Order Message                                                       *)
(***************************************************************************)

NewOrderMessage ==
    [ clOrdId                   : Sample(20),
      side                      : Sample(1),
      orderQty                  : Sample(4),
      numberOfNewOrderBitfields : 0 .. 255,
      newOrderBitfield1         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      newOrderBitfield2         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      newOrderBitfield3         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      newOrderBitfield4         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      newOrderBitfield5         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      newOrderBitfield6         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      newOrderBitfield7         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      newOrderBitfield8         : { << >> } \cup { <<held>> : held \in Sample(1) },
      newOrderBitfield9         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      newOrderBitfield10        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      clearingFirm              : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingAccount           : { << >> } \cup { <<held>> : held \in Sample(4) },
      price                     : { << >> } \cup { <<held>> : held \in Sample(8) },
      execInst                  : { << >> } \cup { <<held>> : held \in Sample(1) },
      ordType                   : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce               : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                    : { << >> } \cup { <<held>> : held \in Sample(4) },
      maxFloor                  : { << >> } \cup { <<held>> : held \in Sample(4) },
      symbol                    : { << >> } \cup { <<held>> : held \in Sample(8) },
      symbolSfx                 : { << >> } \cup { <<held>> : held \in Sample(8) },
      capacity                  : { << >> } \cup { <<held>> : held \in Sample(1) },
      routingInst               : { << >> } \cup { <<held>> : held \in Sample(4) },
      account                   : { << >> } \cup { <<held>> : held \in Sample(16) },
      displayIndicator          : { << >> } \cup { <<held>> : held \in Sample(1) },
      discretionAmount          : { << >> } \cup { <<held>> : held \in Sample(2) },
      pegDifference             : { << >> } \cup { <<held>> : held \in Sample(8) },
      preventMatch              : { << >> } \cup { <<held>> : held \in Sample(3) },
      locateReqd                : { << >> } \cup { <<held>> : held \in Sample(1) },
      expireTime                : { << >> } \cup { <<held>> : held \in Sample(8) },
      riskReset                 : { << >> } \cup { <<held>> : held \in Sample(8) },
      attributedQuote           : { << >> } \cup { <<held>> : held \in Sample(1) },
      extExecInst               : { << >> } \cup { <<held>> : held \in Sample(1) },
      displayRange              : { << >> } \cup { <<held>> : held \in Sample(4) },
      stopPx                    : { << >> } \cup { <<held>> : held \in Sample(8) },
      routStrategy              : { << >> } \cup { <<held>> : held \in Sample(6) },
      routeDeliveryMethod       : { << >> } \cup { <<held>> : held \in Sample(3) },
      exDestination             : { << >> } \cup { <<held>> : held \in Sample(1) },
      echoText                  : { << >> } \cup { <<held>> : held \in Sample(64) },
      riskGroupId               : { << >> } \cup { <<held>> : held \in Sample(2) },
      crossTradeFlag            : { << >> } \cup { <<held>> : held \in Sample(1) },
      locateBroker              : { << >> } \cup { <<held>> : held \in Sample(4) },
      cmcSessions               : { << >> } \cup { <<held>> : held \in Sample(2) },
      stepUpAmount              : { << >> } \cup { <<held>> : held \in Sample(8) } ]

EncodeNewOrderMessage(message) ==
    message.clOrdId
        \o message.side
        \o message.orderQty
        \o EncodeUIntBE(message.numberOfNewOrderBitfields, 1)
        \o (IF message.newOrderBitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.newOrderBitfield1[1], 1))
        \o (IF message.newOrderBitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.newOrderBitfield2[1], 1))
        \o (IF message.newOrderBitfield3 = << >> THEN << >> ELSE EncodeUIntLE(message.newOrderBitfield3[1], 1))
        \o (IF message.newOrderBitfield4 = << >> THEN << >> ELSE EncodeUIntLE(message.newOrderBitfield4[1], 1))
        \o (IF message.newOrderBitfield5 = << >> THEN << >> ELSE EncodeUIntLE(message.newOrderBitfield5[1], 1))
        \o (IF message.newOrderBitfield6 = << >> THEN << >> ELSE EncodeUIntLE(message.newOrderBitfield6[1], 1))
        \o (IF message.newOrderBitfield7 = << >> THEN << >> ELSE EncodeUIntLE(message.newOrderBitfield7[1], 1))
        \o (IF message.newOrderBitfield8 = << >> THEN << >> ELSE message.newOrderBitfield8[1])
        \o (IF message.newOrderBitfield9 = << >> THEN << >> ELSE EncodeUIntLE(message.newOrderBitfield9[1], 1))
        \o (IF message.newOrderBitfield10 = << >> THEN << >> ELSE EncodeUIntLE(message.newOrderBitfield10[1], 1))
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])
        \o (IF message.clearingAccount = << >> THEN << >> ELSE message.clearingAccount[1])
        \o (IF message.price = << >> THEN << >> ELSE message.price[1])
        \o (IF message.execInst = << >> THEN << >> ELSE message.execInst[1])
        \o (IF message.ordType = << >> THEN << >> ELSE message.ordType[1])
        \o (IF message.timeInForce = << >> THEN << >> ELSE message.timeInForce[1])
        \o (IF message.minQty = << >> THEN << >> ELSE message.minQty[1])
        \o (IF message.maxFloor = << >> THEN << >> ELSE message.maxFloor[1])
        \o (IF message.symbol = << >> THEN << >> ELSE message.symbol[1])
        \o (IF message.symbolSfx = << >> THEN << >> ELSE message.symbolSfx[1])
        \o (IF message.capacity = << >> THEN << >> ELSE message.capacity[1])
        \o (IF message.routingInst = << >> THEN << >> ELSE message.routingInst[1])
        \o (IF message.account = << >> THEN << >> ELSE message.account[1])
        \o (IF message.displayIndicator = << >> THEN << >> ELSE message.displayIndicator[1])
        \o (IF message.discretionAmount = << >> THEN << >> ELSE message.discretionAmount[1])
        \o (IF message.pegDifference = << >> THEN << >> ELSE message.pegDifference[1])
        \o (IF message.preventMatch = << >> THEN << >> ELSE message.preventMatch[1])
        \o (IF message.locateReqd = << >> THEN << >> ELSE message.locateReqd[1])
        \o (IF message.expireTime = << >> THEN << >> ELSE message.expireTime[1])
        \o (IF message.riskReset = << >> THEN << >> ELSE message.riskReset[1])
        \o (IF message.attributedQuote = << >> THEN << >> ELSE message.attributedQuote[1])
        \o (IF message.extExecInst = << >> THEN << >> ELSE message.extExecInst[1])
        \o (IF message.displayRange = << >> THEN << >> ELSE message.displayRange[1])
        \o (IF message.stopPx = << >> THEN << >> ELSE message.stopPx[1])
        \o (IF message.routStrategy = << >> THEN << >> ELSE message.routStrategy[1])
        \o (IF message.routeDeliveryMethod = << >> THEN << >> ELSE message.routeDeliveryMethod[1])
        \o (IF message.exDestination = << >> THEN << >> ELSE message.exDestination[1])
        \o (IF message.echoText = << >> THEN << >> ELSE message.echoText[1])
        \o (IF message.riskGroupId = << >> THEN << >> ELSE message.riskGroupId[1])
        \o (IF message.crossTradeFlag = << >> THEN << >> ELSE message.crossTradeFlag[1])
        \o (IF message.locateBroker = << >> THEN << >> ELSE message.locateBroker[1])
        \o (IF message.cmcSessions = << >> THEN << >> ELSE message.cmcSessions[1])
        \o (IF message.stepUpAmount = << >> THEN << >> ELSE message.stepUpAmount[1])

DecodeNewOrderMessage(bytes) ==
    LET clOrdId == ReadBytes(bytes, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET side == ReadBytes(clOrdId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderQty == ReadBytes(side.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET numberOfNewOrderBitfields == ReadUIntBE(orderQty.rest, 1) IN IF ~numberOfNewOrderBitfields.ok THEN Fail ELSE
    LET newOrderBitfield1 == ReadWhen(numberOfNewOrderBitfields.value >= 1, ReadUIntLE(numberOfNewOrderBitfields.rest, 1), numberOfNewOrderBitfields.rest) IN IF ~newOrderBitfield1.ok THEN Fail ELSE
    LET newOrderBitfield2 == ReadWhen(numberOfNewOrderBitfields.value >= 2, ReadUIntLE(newOrderBitfield1.rest, 1), newOrderBitfield1.rest) IN IF ~newOrderBitfield2.ok THEN Fail ELSE
    LET newOrderBitfield3 == ReadWhen(numberOfNewOrderBitfields.value >= 3, ReadUIntLE(newOrderBitfield2.rest, 1), newOrderBitfield2.rest) IN IF ~newOrderBitfield3.ok THEN Fail ELSE
    LET newOrderBitfield4 == ReadWhen(numberOfNewOrderBitfields.value >= 4, ReadUIntLE(newOrderBitfield3.rest, 1), newOrderBitfield3.rest) IN IF ~newOrderBitfield4.ok THEN Fail ELSE
    LET newOrderBitfield5 == ReadWhen(numberOfNewOrderBitfields.value >= 5, ReadUIntLE(newOrderBitfield4.rest, 1), newOrderBitfield4.rest) IN IF ~newOrderBitfield5.ok THEN Fail ELSE
    LET newOrderBitfield6 == ReadWhen(numberOfNewOrderBitfields.value >= 6, ReadUIntLE(newOrderBitfield5.rest, 1), newOrderBitfield5.rest) IN IF ~newOrderBitfield6.ok THEN Fail ELSE
    LET newOrderBitfield7 == ReadWhen(numberOfNewOrderBitfields.value >= 7, ReadUIntLE(newOrderBitfield6.rest, 1), newOrderBitfield6.rest) IN IF ~newOrderBitfield7.ok THEN Fail ELSE
    LET newOrderBitfield8 == ReadWhen(numberOfNewOrderBitfields.value >= 8, ReadBytes(newOrderBitfield7.rest, 1), newOrderBitfield7.rest) IN IF ~newOrderBitfield8.ok THEN Fail ELSE
    LET newOrderBitfield9 == ReadWhen(numberOfNewOrderBitfields.value >= 9, ReadUIntLE(newOrderBitfield8.rest, 1), newOrderBitfield8.rest) IN IF ~newOrderBitfield9.ok THEN Fail ELSE
    LET newOrderBitfield10 == ReadWhen(numberOfNewOrderBitfields.value >= 10, ReadUIntLE(newOrderBitfield9.rest, 1), newOrderBitfield9.rest) IN IF ~newOrderBitfield10.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfNewOrderBitfields.value >= 1 /\ (newOrderBitfield1.value # << >> /\ newOrderBitfield1.value[1] % 2 > 0), ReadBytes(newOrderBitfield10.rest, 4), newOrderBitfield10.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadWhen(numberOfNewOrderBitfields.value >= 1 /\ (newOrderBitfield1.value # << >> /\ (newOrderBitfield1.value[1] \div 2) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET price == ReadWhen(numberOfNewOrderBitfields.value >= 1 /\ (newOrderBitfield1.value # << >> /\ (newOrderBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(clearingAccount.rest, 8), clearingAccount.rest) IN IF ~price.ok THEN Fail ELSE
    LET execInst == ReadWhen(numberOfNewOrderBitfields.value >= 1 /\ (newOrderBitfield1.value # << >> /\ (newOrderBitfield1.value[1] \div 8) % 2 > 0), ReadBytes(price.rest, 1), price.rest) IN IF ~execInst.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfNewOrderBitfields.value >= 1 /\ (newOrderBitfield1.value # << >> /\ (newOrderBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(execInst.rest, 1), execInst.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfNewOrderBitfields.value >= 1 /\ (newOrderBitfield1.value # << >> /\ (newOrderBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfNewOrderBitfields.value >= 1 /\ (newOrderBitfield1.value # << >> /\ (newOrderBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET maxFloor == ReadWhen(numberOfNewOrderBitfields.value >= 1 /\ (newOrderBitfield1.value # << >> /\ (newOrderBitfield1.value[1] \div 128) % 2 > 0), ReadBytes(minQty.rest, 4), minQty.rest) IN IF ~maxFloor.ok THEN Fail ELSE
    LET symbol == ReadWhen(numberOfNewOrderBitfields.value >= 2 /\ (newOrderBitfield2.value # << >> /\ newOrderBitfield2.value[1] % 2 > 0), ReadBytes(maxFloor.rest, 8), maxFloor.rest) IN IF ~symbol.ok THEN Fail ELSE
    LET symbolSfx == ReadWhen(numberOfNewOrderBitfields.value >= 2 /\ (newOrderBitfield2.value # << >> /\ (newOrderBitfield2.value[1] \div 2) % 2 > 0), ReadBytes(symbol.rest, 8), symbol.rest) IN IF ~symbolSfx.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfNewOrderBitfields.value >= 2 /\ (newOrderBitfield2.value # << >> /\ (newOrderBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(symbolSfx.rest, 1), symbolSfx.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET routingInst == ReadWhen(numberOfNewOrderBitfields.value >= 2 /\ (newOrderBitfield2.value # << >> /\ (newOrderBitfield2.value[1] \div 128) % 2 > 0), ReadBytes(capacity.rest, 4), capacity.rest) IN IF ~routingInst.ok THEN Fail ELSE
    LET account == ReadWhen(numberOfNewOrderBitfields.value >= 3 /\ (newOrderBitfield3.value # << >> /\ newOrderBitfield3.value[1] % 2 > 0), ReadBytes(routingInst.rest, 16), routingInst.rest) IN IF ~account.ok THEN Fail ELSE
    LET displayIndicator == ReadWhen(numberOfNewOrderBitfields.value >= 3 /\ (newOrderBitfield3.value # << >> /\ (newOrderBitfield3.value[1] \div 2) % 2 > 0), ReadBytes(account.rest, 1), account.rest) IN IF ~displayIndicator.ok THEN Fail ELSE
    LET discretionAmount == ReadWhen(numberOfNewOrderBitfields.value >= 3 /\ (newOrderBitfield3.value # << >> /\ (newOrderBitfield3.value[1] \div 8) % 2 > 0), ReadBytes(displayIndicator.rest, 2), displayIndicator.rest) IN IF ~discretionAmount.ok THEN Fail ELSE
    LET pegDifference == ReadWhen(numberOfNewOrderBitfields.value >= 3 /\ (newOrderBitfield3.value # << >> /\ (newOrderBitfield3.value[1] \div 16) % 2 > 0), ReadBytes(discretionAmount.rest, 8), discretionAmount.rest) IN IF ~pegDifference.ok THEN Fail ELSE
    LET preventMatch == ReadWhen(numberOfNewOrderBitfields.value >= 3 /\ (newOrderBitfield3.value # << >> /\ (newOrderBitfield3.value[1] \div 32) % 2 > 0), ReadBytes(pegDifference.rest, 3), pegDifference.rest) IN IF ~preventMatch.ok THEN Fail ELSE
    LET locateReqd == ReadWhen(numberOfNewOrderBitfields.value >= 3 /\ (newOrderBitfield3.value # << >> /\ (newOrderBitfield3.value[1] \div 64) % 2 > 0), ReadBytes(preventMatch.rest, 1), preventMatch.rest) IN IF ~locateReqd.ok THEN Fail ELSE
    LET expireTime == ReadWhen(numberOfNewOrderBitfields.value >= 3 /\ (newOrderBitfield3.value # << >> /\ (newOrderBitfield3.value[1] \div 128) % 2 > 0), ReadBytes(locateReqd.rest, 8), locateReqd.rest) IN IF ~expireTime.ok THEN Fail ELSE
    LET riskReset == ReadWhen(numberOfNewOrderBitfields.value >= 4 /\ (newOrderBitfield4.value # << >> /\ (newOrderBitfield4.value[1] \div 8) % 2 > 0), ReadBytes(expireTime.rest, 8), expireTime.rest) IN IF ~riskReset.ok THEN Fail ELSE
    LET attributedQuote == ReadWhen(numberOfNewOrderBitfields.value >= 5 /\ (newOrderBitfield5.value # << >> /\ (newOrderBitfield5.value[1] \div 2) % 2 > 0), ReadBytes(riskReset.rest, 1), riskReset.rest) IN IF ~attributedQuote.ok THEN Fail ELSE
    LET extExecInst == ReadWhen(numberOfNewOrderBitfields.value >= 5 /\ (newOrderBitfield5.value # << >> /\ (newOrderBitfield5.value[1] \div 8) % 2 > 0), ReadBytes(attributedQuote.rest, 1), attributedQuote.rest) IN IF ~extExecInst.ok THEN Fail ELSE
    LET displayRange == ReadWhen(numberOfNewOrderBitfields.value >= 6 /\ (newOrderBitfield6.value # << >> /\ newOrderBitfield6.value[1] % 2 > 0), ReadBytes(extExecInst.rest, 4), extExecInst.rest) IN IF ~displayRange.ok THEN Fail ELSE
    LET stopPx == ReadWhen(numberOfNewOrderBitfields.value >= 6 /\ (newOrderBitfield6.value # << >> /\ (newOrderBitfield6.value[1] \div 2) % 2 > 0), ReadBytes(displayRange.rest, 8), displayRange.rest) IN IF ~stopPx.ok THEN Fail ELSE
    LET routStrategy == ReadWhen(numberOfNewOrderBitfields.value >= 6 /\ (newOrderBitfield6.value # << >> /\ (newOrderBitfield6.value[1] \div 4) % 2 > 0), ReadBytes(stopPx.rest, 6), stopPx.rest) IN IF ~routStrategy.ok THEN Fail ELSE
    LET routeDeliveryMethod == ReadWhen(numberOfNewOrderBitfields.value >= 6 /\ (newOrderBitfield6.value # << >> /\ (newOrderBitfield6.value[1] \div 8) % 2 > 0), ReadBytes(routStrategy.rest, 3), routStrategy.rest) IN IF ~routeDeliveryMethod.ok THEN Fail ELSE
    LET exDestination == ReadWhen(numberOfNewOrderBitfields.value >= 6 /\ (newOrderBitfield6.value # << >> /\ (newOrderBitfield6.value[1] \div 16) % 2 > 0), ReadBytes(routeDeliveryMethod.rest, 1), routeDeliveryMethod.rest) IN IF ~exDestination.ok THEN Fail ELSE
    LET echoText == ReadWhen(numberOfNewOrderBitfields.value >= 6 /\ (newOrderBitfield6.value # << >> /\ (newOrderBitfield6.value[1] \div 32) % 2 > 0), ReadBytes(exDestination.rest, 64), exDestination.rest) IN IF ~echoText.ok THEN Fail ELSE
    LET riskGroupId == ReadWhen(numberOfNewOrderBitfields.value >= 7 /\ (newOrderBitfield7.value # << >> /\ (newOrderBitfield7.value[1] \div 2) % 2 > 0), ReadBytes(echoText.rest, 2), echoText.rest) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET crossTradeFlag == ReadWhen(numberOfNewOrderBitfields.value >= 9 /\ (newOrderBitfield9.value # << >> /\ (newOrderBitfield9.value[1] \div 64) % 2 > 0), ReadBytes(riskGroupId.rest, 1), riskGroupId.rest) IN IF ~crossTradeFlag.ok THEN Fail ELSE
    LET locateBroker == ReadWhen(numberOfNewOrderBitfields.value >= 10 /\ (newOrderBitfield10.value # << >> /\ (newOrderBitfield10.value[1] \div 2) % 2 > 0), ReadBytes(crossTradeFlag.rest, 4), crossTradeFlag.rest) IN IF ~locateBroker.ok THEN Fail ELSE
    LET cmcSessions == ReadWhen(numberOfNewOrderBitfields.value >= 10 /\ (newOrderBitfield10.value # << >> /\ (newOrderBitfield10.value[1] \div 4) % 2 > 0), ReadBytes(locateBroker.rest, 2), locateBroker.rest) IN IF ~cmcSessions.ok THEN Fail ELSE
    LET stepUpAmount == ReadWhen(numberOfNewOrderBitfields.value >= 10 /\ (newOrderBitfield10.value # << >> /\ (newOrderBitfield10.value[1] \div 8) % 2 > 0), ReadBytes(cmcSessions.rest, 8), cmcSessions.rest) IN IF ~stepUpAmount.ok THEN Fail ELSE
    Ok([ clOrdId                   |-> clOrdId.value,
         side                      |-> side.value,
         orderQty                  |-> orderQty.value,
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
         newOrderBitfield10        |-> newOrderBitfield10.value,
         clearingFirm              |-> clearingFirm.value,
         clearingAccount           |-> clearingAccount.value,
         price                     |-> price.value,
         execInst                  |-> execInst.value,
         ordType                   |-> ordType.value,
         timeInForce               |-> timeInForce.value,
         minQty                    |-> minQty.value,
         maxFloor                  |-> maxFloor.value,
         symbol                    |-> symbol.value,
         symbolSfx                 |-> symbolSfx.value,
         capacity                  |-> capacity.value,
         routingInst               |-> routingInst.value,
         account                   |-> account.value,
         displayIndicator          |-> displayIndicator.value,
         discretionAmount          |-> discretionAmount.value,
         pegDifference             |-> pegDifference.value,
         preventMatch              |-> preventMatch.value,
         locateReqd                |-> locateReqd.value,
         expireTime                |-> expireTime.value,
         riskReset                 |-> riskReset.value,
         attributedQuote           |-> attributedQuote.value,
         extExecInst               |-> extExecInst.value,
         displayRange              |-> displayRange.value,
         stopPx                    |-> stopPx.value,
         routStrategy              |-> routStrategy.value,
         routeDeliveryMethod       |-> routeDeliveryMethod.value,
         exDestination             |-> exDestination.value,
         echoText                  |-> echoText.value,
         riskGroupId               |-> riskGroupId.value,
         crossTradeFlag            |-> crossTradeFlag.value,
         locateBroker              |-> locateBroker.value,
         cmcSessions               |-> cmcSessions.value,
         stepUpAmount              |-> stepUpAmount.value ], stepUpAmount.rest)

(* New Order Message with each field marked present by fields before it there exactly where they say *)
SettleNewOrderMessage(message) ==
    LET settled1 == [message EXCEPT !.newOrderBitfield1 = IF message.numberOfNewOrderBitfields >= 1 THEN (IF message.newOrderBitfield1 = << >> THEN <<0>> ELSE message.newOrderBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.newOrderBitfield2 = IF settled1.numberOfNewOrderBitfields >= 2 THEN (IF settled1.newOrderBitfield2 = << >> THEN <<0>> ELSE settled1.newOrderBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.newOrderBitfield3 = IF settled2.numberOfNewOrderBitfields >= 3 THEN (IF settled2.newOrderBitfield3 = << >> THEN <<0>> ELSE settled2.newOrderBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.newOrderBitfield4 = IF settled3.numberOfNewOrderBitfields >= 4 THEN (IF settled3.newOrderBitfield4 = << >> THEN <<0>> ELSE settled3.newOrderBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.newOrderBitfield5 = IF settled4.numberOfNewOrderBitfields >= 5 THEN (IF settled4.newOrderBitfield5 = << >> THEN <<0>> ELSE settled4.newOrderBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.newOrderBitfield6 = IF settled5.numberOfNewOrderBitfields >= 6 THEN (IF settled5.newOrderBitfield6 = << >> THEN <<0>> ELSE settled5.newOrderBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.newOrderBitfield7 = IF settled6.numberOfNewOrderBitfields >= 7 THEN (IF settled6.newOrderBitfield7 = << >> THEN <<0>> ELSE settled6.newOrderBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.newOrderBitfield8 = IF settled7.numberOfNewOrderBitfields >= 8 THEN (IF settled7.newOrderBitfield8 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled7.newOrderBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.newOrderBitfield9 = IF settled8.numberOfNewOrderBitfields >= 9 THEN (IF settled8.newOrderBitfield9 = << >> THEN <<0>> ELSE settled8.newOrderBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.newOrderBitfield10 = IF settled9.numberOfNewOrderBitfields >= 10 THEN (IF settled9.newOrderBitfield10 = << >> THEN <<0>> ELSE settled9.newOrderBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.clearingFirm = IF settled10.numberOfNewOrderBitfields >= 1 /\ (settled10.newOrderBitfield1 # << >> /\ settled10.newOrderBitfield1[1] % 2 > 0) THEN (IF settled10.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled10.clearingFirm) ELSE << >>]
        settled12 == [settled11 EXCEPT !.clearingAccount = IF settled11.numberOfNewOrderBitfields >= 1 /\ (settled11.newOrderBitfield1 # << >> /\ (settled11.newOrderBitfield1[1] \div 2) % 2 > 0) THEN (IF settled11.clearingAccount = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled11.clearingAccount) ELSE << >>]
        settled13 == [settled12 EXCEPT !.price = IF settled12.numberOfNewOrderBitfields >= 1 /\ (settled12.newOrderBitfield1 # << >> /\ (settled12.newOrderBitfield1[1] \div 4) % 2 > 0) THEN (IF settled12.price = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled12.price) ELSE << >>]
        settled14 == [settled13 EXCEPT !.execInst = IF settled13.numberOfNewOrderBitfields >= 1 /\ (settled13.newOrderBitfield1 # << >> /\ (settled13.newOrderBitfield1[1] \div 8) % 2 > 0) THEN (IF settled13.execInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.execInst) ELSE << >>]
        settled15 == [settled14 EXCEPT !.ordType = IF settled14.numberOfNewOrderBitfields >= 1 /\ (settled14.newOrderBitfield1 # << >> /\ (settled14.newOrderBitfield1[1] \div 16) % 2 > 0) THEN (IF settled14.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.ordType) ELSE << >>]
        settled16 == [settled15 EXCEPT !.timeInForce = IF settled15.numberOfNewOrderBitfields >= 1 /\ (settled15.newOrderBitfield1 # << >> /\ (settled15.newOrderBitfield1[1] \div 32) % 2 > 0) THEN (IF settled15.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled15.timeInForce) ELSE << >>]
        settled17 == [settled16 EXCEPT !.minQty = IF settled16.numberOfNewOrderBitfields >= 1 /\ (settled16.newOrderBitfield1 # << >> /\ (settled16.newOrderBitfield1[1] \div 64) % 2 > 0) THEN (IF settled16.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled16.minQty) ELSE << >>]
        settled18 == [settled17 EXCEPT !.maxFloor = IF settled17.numberOfNewOrderBitfields >= 1 /\ (settled17.newOrderBitfield1 # << >> /\ (settled17.newOrderBitfield1[1] \div 128) % 2 > 0) THEN (IF settled17.maxFloor = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled17.maxFloor) ELSE << >>]
        settled19 == [settled18 EXCEPT !.symbol = IF settled18.numberOfNewOrderBitfields >= 2 /\ (settled18.newOrderBitfield2 # << >> /\ settled18.newOrderBitfield2[1] % 2 > 0) THEN (IF settled18.symbol = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled18.symbol) ELSE << >>]
        settled20 == [settled19 EXCEPT !.symbolSfx = IF settled19.numberOfNewOrderBitfields >= 2 /\ (settled19.newOrderBitfield2 # << >> /\ (settled19.newOrderBitfield2[1] \div 2) % 2 > 0) THEN (IF settled19.symbolSfx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled19.symbolSfx) ELSE << >>]
        settled21 == [settled20 EXCEPT !.capacity = IF settled20.numberOfNewOrderBitfields >= 2 /\ (settled20.newOrderBitfield2 # << >> /\ (settled20.newOrderBitfield2[1] \div 64) % 2 > 0) THEN (IF settled20.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled20.capacity) ELSE << >>]
        settled22 == [settled21 EXCEPT !.routingInst = IF settled21.numberOfNewOrderBitfields >= 2 /\ (settled21.newOrderBitfield2 # << >> /\ (settled21.newOrderBitfield2[1] \div 128) % 2 > 0) THEN (IF settled21.routingInst = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled21.routingInst) ELSE << >>]
        settled23 == [settled22 EXCEPT !.account = IF settled22.numberOfNewOrderBitfields >= 3 /\ (settled22.newOrderBitfield3 # << >> /\ settled22.newOrderBitfield3[1] % 2 > 0) THEN (IF settled22.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled22.account) ELSE << >>]
        settled24 == [settled23 EXCEPT !.displayIndicator = IF settled23.numberOfNewOrderBitfields >= 3 /\ (settled23.newOrderBitfield3 # << >> /\ (settled23.newOrderBitfield3[1] \div 2) % 2 > 0) THEN (IF settled23.displayIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled23.displayIndicator) ELSE << >>]
        settled25 == [settled24 EXCEPT !.discretionAmount = IF settled24.numberOfNewOrderBitfields >= 3 /\ (settled24.newOrderBitfield3 # << >> /\ (settled24.newOrderBitfield3[1] \div 8) % 2 > 0) THEN (IF settled24.discretionAmount = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled24.discretionAmount) ELSE << >>]
        settled26 == [settled25 EXCEPT !.pegDifference = IF settled25.numberOfNewOrderBitfields >= 3 /\ (settled25.newOrderBitfield3 # << >> /\ (settled25.newOrderBitfield3[1] \div 16) % 2 > 0) THEN (IF settled25.pegDifference = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled25.pegDifference) ELSE << >>]
        settled27 == [settled26 EXCEPT !.preventMatch = IF settled26.numberOfNewOrderBitfields >= 3 /\ (settled26.newOrderBitfield3 # << >> /\ (settled26.newOrderBitfield3[1] \div 32) % 2 > 0) THEN (IF settled26.preventMatch = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled26.preventMatch) ELSE << >>]
        settled28 == [settled27 EXCEPT !.locateReqd = IF settled27.numberOfNewOrderBitfields >= 3 /\ (settled27.newOrderBitfield3 # << >> /\ (settled27.newOrderBitfield3[1] \div 64) % 2 > 0) THEN (IF settled27.locateReqd = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled27.locateReqd) ELSE << >>]
        settled29 == [settled28 EXCEPT !.expireTime = IF settled28.numberOfNewOrderBitfields >= 3 /\ (settled28.newOrderBitfield3 # << >> /\ (settled28.newOrderBitfield3[1] \div 128) % 2 > 0) THEN (IF settled28.expireTime = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled28.expireTime) ELSE << >>]
        settled30 == [settled29 EXCEPT !.riskReset = IF settled29.numberOfNewOrderBitfields >= 4 /\ (settled29.newOrderBitfield4 # << >> /\ (settled29.newOrderBitfield4[1] \div 8) % 2 > 0) THEN (IF settled29.riskReset = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled29.riskReset) ELSE << >>]
        settled31 == [settled30 EXCEPT !.attributedQuote = IF settled30.numberOfNewOrderBitfields >= 5 /\ (settled30.newOrderBitfield5 # << >> /\ (settled30.newOrderBitfield5[1] \div 2) % 2 > 0) THEN (IF settled30.attributedQuote = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled30.attributedQuote) ELSE << >>]
        settled32 == [settled31 EXCEPT !.extExecInst = IF settled31.numberOfNewOrderBitfields >= 5 /\ (settled31.newOrderBitfield5 # << >> /\ (settled31.newOrderBitfield5[1] \div 8) % 2 > 0) THEN (IF settled31.extExecInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled31.extExecInst) ELSE << >>]
        settled33 == [settled32 EXCEPT !.displayRange = IF settled32.numberOfNewOrderBitfields >= 6 /\ (settled32.newOrderBitfield6 # << >> /\ settled32.newOrderBitfield6[1] % 2 > 0) THEN (IF settled32.displayRange = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled32.displayRange) ELSE << >>]
        settled34 == [settled33 EXCEPT !.stopPx = IF settled33.numberOfNewOrderBitfields >= 6 /\ (settled33.newOrderBitfield6 # << >> /\ (settled33.newOrderBitfield6[1] \div 2) % 2 > 0) THEN (IF settled33.stopPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled33.stopPx) ELSE << >>]
        settled35 == [settled34 EXCEPT !.routStrategy = IF settled34.numberOfNewOrderBitfields >= 6 /\ (settled34.newOrderBitfield6 # << >> /\ (settled34.newOrderBitfield6[1] \div 4) % 2 > 0) THEN (IF settled34.routStrategy = << >> THEN <<[i \in 1 .. 6 |-> 0]>> ELSE settled34.routStrategy) ELSE << >>]
        settled36 == [settled35 EXCEPT !.routeDeliveryMethod = IF settled35.numberOfNewOrderBitfields >= 6 /\ (settled35.newOrderBitfield6 # << >> /\ (settled35.newOrderBitfield6[1] \div 8) % 2 > 0) THEN (IF settled35.routeDeliveryMethod = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled35.routeDeliveryMethod) ELSE << >>]
        settled37 == [settled36 EXCEPT !.exDestination = IF settled36.numberOfNewOrderBitfields >= 6 /\ (settled36.newOrderBitfield6 # << >> /\ (settled36.newOrderBitfield6[1] \div 16) % 2 > 0) THEN (IF settled36.exDestination = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled36.exDestination) ELSE << >>]
        settled38 == [settled37 EXCEPT !.echoText = IF settled37.numberOfNewOrderBitfields >= 6 /\ (settled37.newOrderBitfield6 # << >> /\ (settled37.newOrderBitfield6[1] \div 32) % 2 > 0) THEN (IF settled37.echoText = << >> THEN <<[i \in 1 .. 64 |-> 0]>> ELSE settled37.echoText) ELSE << >>]
        settled39 == [settled38 EXCEPT !.riskGroupId = IF settled38.numberOfNewOrderBitfields >= 7 /\ (settled38.newOrderBitfield7 # << >> /\ (settled38.newOrderBitfield7[1] \div 2) % 2 > 0) THEN (IF settled38.riskGroupId = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled38.riskGroupId) ELSE << >>]
        settled40 == [settled39 EXCEPT !.crossTradeFlag = IF settled39.numberOfNewOrderBitfields >= 9 /\ (settled39.newOrderBitfield9 # << >> /\ (settled39.newOrderBitfield9[1] \div 64) % 2 > 0) THEN (IF settled39.crossTradeFlag = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled39.crossTradeFlag) ELSE << >>]
        settled41 == [settled40 EXCEPT !.locateBroker = IF settled40.numberOfNewOrderBitfields >= 10 /\ (settled40.newOrderBitfield10 # << >> /\ (settled40.newOrderBitfield10[1] \div 2) % 2 > 0) THEN (IF settled40.locateBroker = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled40.locateBroker) ELSE << >>]
        settled42 == [settled41 EXCEPT !.cmcSessions = IF settled41.numberOfNewOrderBitfields >= 10 /\ (settled41.newOrderBitfield10 # << >> /\ (settled41.newOrderBitfield10[1] \div 4) % 2 > 0) THEN (IF settled41.cmcSessions = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled41.cmcSessions) ELSE << >>]
        settled43 == [settled42 EXCEPT !.stepUpAmount = IF settled42.numberOfNewOrderBitfields >= 10 /\ (settled42.newOrderBitfield10 # << >> /\ (settled42.newOrderBitfield10[1] \div 8) % 2 > 0) THEN (IF settled42.stepUpAmount = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled42.stepUpAmount) ELSE << >>]
    IN  settled43

ZeroNewOrderMessage ==
    SettleNewOrderMessage([ clOrdId                   |-> [i \in 1 .. 20 |-> 0],
                            side                      |-> [i \in 1 .. 1 |-> 0],
                            orderQty                  |-> [i \in 1 .. 4 |-> 0],
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
                            newOrderBitfield10        |-> << >>,
                            clearingFirm              |-> << >>,
                            clearingAccount           |-> << >>,
                            price                     |-> << >>,
                            execInst                  |-> << >>,
                            ordType                   |-> << >>,
                            timeInForce               |-> << >>,
                            minQty                    |-> << >>,
                            maxFloor                  |-> << >>,
                            symbol                    |-> << >>,
                            symbolSfx                 |-> << >>,
                            capacity                  |-> << >>,
                            routingInst               |-> << >>,
                            account                   |-> << >>,
                            displayIndicator          |-> << >>,
                            discretionAmount          |-> << >>,
                            pegDifference             |-> << >>,
                            preventMatch              |-> << >>,
                            locateReqd                |-> << >>,
                            expireTime                |-> << >>,
                            riskReset                 |-> << >>,
                            attributedQuote           |-> << >>,
                            extExecInst               |-> << >>,
                            displayRange              |-> << >>,
                            stopPx                    |-> << >>,
                            routStrategy              |-> << >>,
                            routeDeliveryMethod       |-> << >>,
                            exDestination             |-> << >>,
                            echoText                  |-> << >>,
                            riskGroupId               |-> << >>,
                            crossTradeFlag            |-> << >>,
                            locateBroker              |-> << >>,
                            cmcSessions               |-> << >>,
                            stepUpAmount              |-> << >> ])

(* New Order Message at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderMessage ==
    { ZeroNewOrderMessage }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.clOrdId = one]) : one \in Sample(20) }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.side = one]) : one \in Sample(1) }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.orderQty = one]) : one \in Sample(4) }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 1, !.newOrderBitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 2, !.newOrderBitfield2 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 3, !.newOrderBitfield3 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 4, !.newOrderBitfield4 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 5, !.newOrderBitfield5 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 6, !.newOrderBitfield6 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 7, !.newOrderBitfield7 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 8, !.newOrderBitfield8 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 9, !.newOrderBitfield9 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 10, !.newOrderBitfield10 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 1, !.newOrderBitfield1 = <<1>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 1, !.newOrderBitfield1 = <<2>>, !.clearingAccount = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 1, !.newOrderBitfield1 = <<4>>, !.price = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 1, !.newOrderBitfield1 = <<8>>, !.execInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 1, !.newOrderBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 1, !.newOrderBitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 1, !.newOrderBitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 1, !.newOrderBitfield1 = <<128>>, !.maxFloor = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 2, !.newOrderBitfield2 = <<1>>, !.symbol = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 2, !.newOrderBitfield2 = <<2>>, !.symbolSfx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 2, !.newOrderBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 2, !.newOrderBitfield2 = <<128>>, !.routingInst = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 3, !.newOrderBitfield3 = <<1>>, !.account = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 3, !.newOrderBitfield3 = <<2>>, !.displayIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 3, !.newOrderBitfield3 = <<8>>, !.discretionAmount = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 3, !.newOrderBitfield3 = <<16>>, !.pegDifference = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 3, !.newOrderBitfield3 = <<32>>, !.preventMatch = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 3, !.newOrderBitfield3 = <<64>>, !.locateReqd = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 3, !.newOrderBitfield3 = <<128>>, !.expireTime = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 4, !.newOrderBitfield4 = <<8>>, !.riskReset = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 5, !.newOrderBitfield5 = <<2>>, !.attributedQuote = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 5, !.newOrderBitfield5 = <<8>>, !.extExecInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 6, !.newOrderBitfield6 = <<1>>, !.displayRange = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 6, !.newOrderBitfield6 = <<2>>, !.stopPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 6, !.newOrderBitfield6 = <<4>>, !.routStrategy = one]) : one \in { <<held>> : held \in Sample(6) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 6, !.newOrderBitfield6 = <<8>>, !.routeDeliveryMethod = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 6, !.newOrderBitfield6 = <<16>>, !.exDestination = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 6, !.newOrderBitfield6 = <<32>>, !.echoText = one]) : one \in { <<held>> : held \in Sample(64) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 7, !.newOrderBitfield7 = <<2>>, !.riskGroupId = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 9, !.newOrderBitfield9 = <<64>>, !.crossTradeFlag = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 10, !.newOrderBitfield10 = <<2>>, !.locateBroker = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 10, !.newOrderBitfield10 = <<4>>, !.cmcSessions = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 10, !.newOrderBitfield10 = <<8>>, !.stepUpAmount = one]) : one \in { <<held>> : held \in Sample(8) } }

(***************************************************************************)
(* Cancel Order Message                                                    *)
(***************************************************************************)

CancelOrderMessage ==
    [ origClOrdId                  : Sample(20),
      numberOfCancelOrderBitfields : 0 .. 255,
      cancelOrderBitfield1         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      cancelOrderBitfield2         : { << >> } \cup { <<held>> : held \in Sample(1) },
      clearingFirm                 : { << >> } \cup { <<held>> : held \in Sample(4) } ]

EncodeCancelOrderMessage(message) ==
    message.origClOrdId
        \o EncodeUIntBE(message.numberOfCancelOrderBitfields, 1)
        \o (IF message.cancelOrderBitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.cancelOrderBitfield1[1], 1))
        \o (IF message.cancelOrderBitfield2 = << >> THEN << >> ELSE message.cancelOrderBitfield2[1])
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])

DecodeCancelOrderMessage(bytes) ==
    LET origClOrdId == ReadBytes(bytes, 20) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET numberOfCancelOrderBitfields == ReadUIntBE(origClOrdId.rest, 1) IN IF ~numberOfCancelOrderBitfields.ok THEN Fail ELSE
    LET cancelOrderBitfield1 == ReadWhen(numberOfCancelOrderBitfields.value >= 1, ReadUIntLE(numberOfCancelOrderBitfields.rest, 1), numberOfCancelOrderBitfields.rest) IN IF ~cancelOrderBitfield1.ok THEN Fail ELSE
    LET cancelOrderBitfield2 == ReadWhen(numberOfCancelOrderBitfields.value >= 2, ReadBytes(cancelOrderBitfield1.rest, 1), cancelOrderBitfield1.rest) IN IF ~cancelOrderBitfield2.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfCancelOrderBitfields.value >= 1 /\ (cancelOrderBitfield1.value # << >> /\ cancelOrderBitfield1.value[1] % 2 > 0), ReadBytes(cancelOrderBitfield2.rest, 4), cancelOrderBitfield2.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    Ok([ origClOrdId                  |-> origClOrdId.value,
         numberOfCancelOrderBitfields |-> numberOfCancelOrderBitfields.value,
         cancelOrderBitfield1         |-> cancelOrderBitfield1.value,
         cancelOrderBitfield2         |-> cancelOrderBitfield2.value,
         clearingFirm                 |-> clearingFirm.value ], clearingFirm.rest)

(* Cancel Order Message with each field marked present by fields before it there exactly where they say *)
SettleCancelOrderMessage(message) ==
    LET settled1 == [message EXCEPT !.cancelOrderBitfield1 = IF message.numberOfCancelOrderBitfields >= 1 THEN (IF message.cancelOrderBitfield1 = << >> THEN <<0>> ELSE message.cancelOrderBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.cancelOrderBitfield2 = IF settled1.numberOfCancelOrderBitfields >= 2 THEN (IF settled1.cancelOrderBitfield2 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled1.cancelOrderBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.clearingFirm = IF settled2.numberOfCancelOrderBitfields >= 1 /\ (settled2.cancelOrderBitfield1 # << >> /\ settled2.cancelOrderBitfield1[1] % 2 > 0) THEN (IF settled2.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled2.clearingFirm) ELSE << >>]
    IN  settled3

ZeroCancelOrderMessage ==
    SettleCancelOrderMessage([ origClOrdId                  |-> [i \in 1 .. 20 |-> 0],
                               numberOfCancelOrderBitfields |-> 0,
                               cancelOrderBitfield1         |-> << >>,
                               cancelOrderBitfield2         |-> << >>,
                               clearingFirm                 |-> << >> ])

(* Cancel Order Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelOrderMessage ==
    { ZeroCancelOrderMessage }
        \cup { SettleCancelOrderMessage([ZeroCancelOrderMessage EXCEPT !.origClOrdId = one]) : one \in Sample(20) }
        \cup { SettleCancelOrderMessage([ZeroCancelOrderMessage EXCEPT !.numberOfCancelOrderBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleCancelOrderMessage([ZeroCancelOrderMessage EXCEPT !.numberOfCancelOrderBitfields = 1, !.cancelOrderBitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleCancelOrderMessage([ZeroCancelOrderMessage EXCEPT !.numberOfCancelOrderBitfields = 2, !.cancelOrderBitfield2 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelOrderMessage([ZeroCancelOrderMessage EXCEPT !.numberOfCancelOrderBitfields = 1, !.cancelOrderBitfield1 = <<1>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }

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
      orderQty                     : { << >> } \cup { <<held>> : held \in Sample(4) },
      price                        : { << >> } \cup { <<held>> : held \in Sample(8) },
      ordType                      : { << >> } \cup { <<held>> : held \in Sample(1) },
      cancelOrigOnReject           : { << >> } \cup { <<held>> : held \in Sample(1) },
      execInst                     : { << >> } \cup { <<held>> : held \in Sample(1) },
      side                         : { << >> } \cup { <<held>> : held \in Sample(1) },
      maxFloor                     : { << >> } \cup { <<held>> : held \in Sample(4) },
      stopPx                       : { << >> } \cup { <<held>> : held \in Sample(8) },
      locateBroker                 : { << >> } \cup { <<held>> : held \in Sample(4) } ]

EncodeModifyOrderMessage(message) ==
    message.clOrdId
        \o message.origClOrdId
        \o EncodeUIntBE(message.numberOfModifyOrderBitfields, 1)
        \o (IF message.modifyOrderBitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.modifyOrderBitfield1[1], 1))
        \o (IF message.modifyOrderBitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.modifyOrderBitfield2[1], 1))
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])
        \o (IF message.orderQty = << >> THEN << >> ELSE message.orderQty[1])
        \o (IF message.price = << >> THEN << >> ELSE message.price[1])
        \o (IF message.ordType = << >> THEN << >> ELSE message.ordType[1])
        \o (IF message.cancelOrigOnReject = << >> THEN << >> ELSE message.cancelOrigOnReject[1])
        \o (IF message.execInst = << >> THEN << >> ELSE message.execInst[1])
        \o (IF message.side = << >> THEN << >> ELSE message.side[1])
        \o (IF message.maxFloor = << >> THEN << >> ELSE message.maxFloor[1])
        \o (IF message.stopPx = << >> THEN << >> ELSE message.stopPx[1])
        \o (IF message.locateBroker = << >> THEN << >> ELSE message.locateBroker[1])

DecodeModifyOrderMessage(bytes) ==
    LET clOrdId == ReadBytes(bytes, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 20) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET numberOfModifyOrderBitfields == ReadUIntBE(origClOrdId.rest, 1) IN IF ~numberOfModifyOrderBitfields.ok THEN Fail ELSE
    LET modifyOrderBitfield1 == ReadWhen(numberOfModifyOrderBitfields.value >= 1, ReadUIntLE(numberOfModifyOrderBitfields.rest, 1), numberOfModifyOrderBitfields.rest) IN IF ~modifyOrderBitfield1.ok THEN Fail ELSE
    LET modifyOrderBitfield2 == ReadWhen(numberOfModifyOrderBitfields.value >= 2, ReadUIntLE(modifyOrderBitfield1.rest, 1), modifyOrderBitfield1.rest) IN IF ~modifyOrderBitfield2.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfModifyOrderBitfields.value >= 1 /\ (modifyOrderBitfield1.value # << >> /\ modifyOrderBitfield1.value[1] % 2 > 0), ReadBytes(modifyOrderBitfield2.rest, 4), modifyOrderBitfield2.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET orderQty == ReadWhen(numberOfModifyOrderBitfields.value >= 1 /\ (modifyOrderBitfield1.value # << >> /\ (modifyOrderBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~orderQty.ok THEN Fail ELSE
    LET price == ReadWhen(numberOfModifyOrderBitfields.value >= 1 /\ (modifyOrderBitfield1.value # << >> /\ (modifyOrderBitfield1.value[1] \div 8) % 2 > 0), ReadBytes(orderQty.rest, 8), orderQty.rest) IN IF ~price.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfModifyOrderBitfields.value >= 1 /\ (modifyOrderBitfield1.value # << >> /\ (modifyOrderBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(price.rest, 1), price.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET cancelOrigOnReject == ReadWhen(numberOfModifyOrderBitfields.value >= 1 /\ (modifyOrderBitfield1.value # << >> /\ (modifyOrderBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~cancelOrigOnReject.ok THEN Fail ELSE
    LET execInst == ReadWhen(numberOfModifyOrderBitfields.value >= 1 /\ (modifyOrderBitfield1.value # << >> /\ (modifyOrderBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(cancelOrigOnReject.rest, 1), cancelOrigOnReject.rest) IN IF ~execInst.ok THEN Fail ELSE
    LET side == ReadWhen(numberOfModifyOrderBitfields.value >= 1 /\ (modifyOrderBitfield1.value # << >> /\ (modifyOrderBitfield1.value[1] \div 128) % 2 > 0), ReadBytes(execInst.rest, 1), execInst.rest) IN IF ~side.ok THEN Fail ELSE
    LET maxFloor == ReadWhen(numberOfModifyOrderBitfields.value >= 2 /\ (modifyOrderBitfield2.value # << >> /\ modifyOrderBitfield2.value[1] % 2 > 0), ReadBytes(side.rest, 4), side.rest) IN IF ~maxFloor.ok THEN Fail ELSE
    LET stopPx == ReadWhen(numberOfModifyOrderBitfields.value >= 2 /\ (modifyOrderBitfield2.value # << >> /\ (modifyOrderBitfield2.value[1] \div 2) % 2 > 0), ReadBytes(maxFloor.rest, 8), maxFloor.rest) IN IF ~stopPx.ok THEN Fail ELSE
    LET locateBroker == ReadWhen(numberOfModifyOrderBitfields.value >= 2 /\ (modifyOrderBitfield2.value # << >> /\ (modifyOrderBitfield2.value[1] \div 128) % 2 > 0), ReadBytes(stopPx.rest, 4), stopPx.rest) IN IF ~locateBroker.ok THEN Fail ELSE
    Ok([ clOrdId                      |-> clOrdId.value,
         origClOrdId                  |-> origClOrdId.value,
         numberOfModifyOrderBitfields |-> numberOfModifyOrderBitfields.value,
         modifyOrderBitfield1         |-> modifyOrderBitfield1.value,
         modifyOrderBitfield2         |-> modifyOrderBitfield2.value,
         clearingFirm                 |-> clearingFirm.value,
         orderQty                     |-> orderQty.value,
         price                        |-> price.value,
         ordType                      |-> ordType.value,
         cancelOrigOnReject           |-> cancelOrigOnReject.value,
         execInst                     |-> execInst.value,
         side                         |-> side.value,
         maxFloor                     |-> maxFloor.value,
         stopPx                       |-> stopPx.value,
         locateBroker                 |-> locateBroker.value ], locateBroker.rest)

(* Modify Order Message with each field marked present by fields before it there exactly where they say *)
SettleModifyOrderMessage(message) ==
    LET settled1 == [message EXCEPT !.modifyOrderBitfield1 = IF message.numberOfModifyOrderBitfields >= 1 THEN (IF message.modifyOrderBitfield1 = << >> THEN <<0>> ELSE message.modifyOrderBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.modifyOrderBitfield2 = IF settled1.numberOfModifyOrderBitfields >= 2 THEN (IF settled1.modifyOrderBitfield2 = << >> THEN <<0>> ELSE settled1.modifyOrderBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.clearingFirm = IF settled2.numberOfModifyOrderBitfields >= 1 /\ (settled2.modifyOrderBitfield1 # << >> /\ settled2.modifyOrderBitfield1[1] % 2 > 0) THEN (IF settled2.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled2.clearingFirm) ELSE << >>]
        settled4 == [settled3 EXCEPT !.orderQty = IF settled3.numberOfModifyOrderBitfields >= 1 /\ (settled3.modifyOrderBitfield1 # << >> /\ (settled3.modifyOrderBitfield1[1] \div 4) % 2 > 0) THEN (IF settled3.orderQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled3.orderQty) ELSE << >>]
        settled5 == [settled4 EXCEPT !.price = IF settled4.numberOfModifyOrderBitfields >= 1 /\ (settled4.modifyOrderBitfield1 # << >> /\ (settled4.modifyOrderBitfield1[1] \div 8) % 2 > 0) THEN (IF settled4.price = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled4.price) ELSE << >>]
        settled6 == [settled5 EXCEPT !.ordType = IF settled5.numberOfModifyOrderBitfields >= 1 /\ (settled5.modifyOrderBitfield1 # << >> /\ (settled5.modifyOrderBitfield1[1] \div 16) % 2 > 0) THEN (IF settled5.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled5.ordType) ELSE << >>]
        settled7 == [settled6 EXCEPT !.cancelOrigOnReject = IF settled6.numberOfModifyOrderBitfields >= 1 /\ (settled6.modifyOrderBitfield1 # << >> /\ (settled6.modifyOrderBitfield1[1] \div 32) % 2 > 0) THEN (IF settled6.cancelOrigOnReject = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.cancelOrigOnReject) ELSE << >>]
        settled8 == [settled7 EXCEPT !.execInst = IF settled7.numberOfModifyOrderBitfields >= 1 /\ (settled7.modifyOrderBitfield1 # << >> /\ (settled7.modifyOrderBitfield1[1] \div 64) % 2 > 0) THEN (IF settled7.execInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled7.execInst) ELSE << >>]
        settled9 == [settled8 EXCEPT !.side = IF settled8.numberOfModifyOrderBitfields >= 1 /\ (settled8.modifyOrderBitfield1 # << >> /\ (settled8.modifyOrderBitfield1[1] \div 128) % 2 > 0) THEN (IF settled8.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled8.side) ELSE << >>]
        settled10 == [settled9 EXCEPT !.maxFloor = IF settled9.numberOfModifyOrderBitfields >= 2 /\ (settled9.modifyOrderBitfield2 # << >> /\ settled9.modifyOrderBitfield2[1] % 2 > 0) THEN (IF settled9.maxFloor = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled9.maxFloor) ELSE << >>]
        settled11 == [settled10 EXCEPT !.stopPx = IF settled10.numberOfModifyOrderBitfields >= 2 /\ (settled10.modifyOrderBitfield2 # << >> /\ (settled10.modifyOrderBitfield2[1] \div 2) % 2 > 0) THEN (IF settled10.stopPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled10.stopPx) ELSE << >>]
        settled12 == [settled11 EXCEPT !.locateBroker = IF settled11.numberOfModifyOrderBitfields >= 2 /\ (settled11.modifyOrderBitfield2 # << >> /\ (settled11.modifyOrderBitfield2[1] \div 128) % 2 > 0) THEN (IF settled11.locateBroker = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled11.locateBroker) ELSE << >>]
    IN  settled12

ZeroModifyOrderMessage ==
    SettleModifyOrderMessage([ clOrdId                      |-> [i \in 1 .. 20 |-> 0],
                               origClOrdId                  |-> [i \in 1 .. 20 |-> 0],
                               numberOfModifyOrderBitfields |-> 0,
                               modifyOrderBitfield1         |-> << >>,
                               modifyOrderBitfield2         |-> << >>,
                               clearingFirm                 |-> << >>,
                               orderQty                     |-> << >>,
                               price                        |-> << >>,
                               ordType                      |-> << >>,
                               cancelOrigOnReject           |-> << >>,
                               execInst                     |-> << >>,
                               side                         |-> << >>,
                               maxFloor                     |-> << >>,
                               stopPx                       |-> << >>,
                               locateBroker                 |-> << >> ])

(* Modify Order Message at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderMessage ==
    { ZeroModifyOrderMessage }
        \cup { SettleModifyOrderMessage([ZeroModifyOrderMessage EXCEPT !.clOrdId = one]) : one \in Sample(20) }
        \cup { SettleModifyOrderMessage([ZeroModifyOrderMessage EXCEPT !.origClOrdId = one]) : one \in Sample(20) }
        \cup { SettleModifyOrderMessage([ZeroModifyOrderMessage EXCEPT !.numberOfModifyOrderBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleModifyOrderMessage([ZeroModifyOrderMessage EXCEPT !.numberOfModifyOrderBitfields = 1, !.modifyOrderBitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleModifyOrderMessage([ZeroModifyOrderMessage EXCEPT !.numberOfModifyOrderBitfields = 2, !.modifyOrderBitfield2 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleModifyOrderMessage([ZeroModifyOrderMessage EXCEPT !.numberOfModifyOrderBitfields = 1, !.modifyOrderBitfield1 = <<1>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleModifyOrderMessage([ZeroModifyOrderMessage EXCEPT !.numberOfModifyOrderBitfields = 1, !.modifyOrderBitfield1 = <<4>>, !.orderQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleModifyOrderMessage([ZeroModifyOrderMessage EXCEPT !.numberOfModifyOrderBitfields = 1, !.modifyOrderBitfield1 = <<8>>, !.price = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleModifyOrderMessage([ZeroModifyOrderMessage EXCEPT !.numberOfModifyOrderBitfields = 1, !.modifyOrderBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleModifyOrderMessage([ZeroModifyOrderMessage EXCEPT !.numberOfModifyOrderBitfields = 1, !.modifyOrderBitfield1 = <<32>>, !.cancelOrigOnReject = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleModifyOrderMessage([ZeroModifyOrderMessage EXCEPT !.numberOfModifyOrderBitfields = 1, !.modifyOrderBitfield1 = <<64>>, !.execInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleModifyOrderMessage([ZeroModifyOrderMessage EXCEPT !.numberOfModifyOrderBitfields = 1, !.modifyOrderBitfield1 = <<128>>, !.side = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleModifyOrderMessage([ZeroModifyOrderMessage EXCEPT !.numberOfModifyOrderBitfields = 2, !.modifyOrderBitfield2 = <<1>>, !.maxFloor = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleModifyOrderMessage([ZeroModifyOrderMessage EXCEPT !.numberOfModifyOrderBitfields = 2, !.modifyOrderBitfield2 = <<2>>, !.stopPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleModifyOrderMessage([ZeroModifyOrderMessage EXCEPT !.numberOfModifyOrderBitfields = 2, !.modifyOrderBitfield2 = <<128>>, !.locateBroker = one]) : one \in { <<held>> : held \in Sample(4) } }

(***************************************************************************)
(* Risk Group I Ds: 2 bytes                                                *)
(***************************************************************************)

RiskGroupIDs ==
    [ riskGroupId : Sample(2) ]

EncodeRiskGroupIDs(message) ==
    message.riskGroupId

DecodeRiskGroupIDs(bytes) ==
    LET riskGroupId == ReadBytes(bytes, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    Ok([ riskGroupId |-> riskGroupId.value ], riskGroupId.rest)

ZeroRiskGroupIDs ==
    [ riskGroupId |-> [i \in 1 .. 2 |-> 0] ]

(* Risk Group I Ds at zero, then each field in turn at the values it is checked at *)
CheckedRiskGroupIDs ==
    { ZeroRiskGroupIDs }
        \cup { [ZeroRiskGroupIDs EXCEPT !.riskGroupId = one] : one \in Sample(2) }

(* A run of Risk Group I Ds, written one after another *)
RECURSIVE EncodeRiskGroupIDsList(_)
EncodeRiskGroupIDsList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeRiskGroupIDs(Head(messages)) \o EncodeRiskGroupIDsList(Tail(messages))

(* As many Risk Group I Ds as the field that counts them says *)
RECURSIVE ReadRiskGroupIDsList(_, _)
ReadRiskGroupIDsList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeRiskGroupIDs(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadRiskGroupIDsList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Risk Group I Ds of each kind, for the lists that carry them *)
OneRiskGroupIDs == { ZeroRiskGroupIDs }

(***************************************************************************)
(* Purge Orders Message                                                    *)
(***************************************************************************)

PurgeOrdersMessage ==
    [ reserved1                    : Sample(1),
      numberOfPurgeOrdersBitfields : 0 .. 255,
      purgeOrdersBitfield1         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      purgeOrdersBitfield2         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      riskGroupIDs                 : SampleLists(OneRiskGroupIDs),
      clearingFirm                 : { << >> } \cup { <<held>> : held \in Sample(4) },
      massCancelInst               : { << >> } \cup { <<held>> : held \in Sample(16) },
      massCancelId                 : { << >> } \cup { <<held>> : held \in Sample(20) },
      symbol                       : { << >> } \cup { <<held>> : held \in Sample(8) },
      symbolSfx                    : { << >> } \cup { <<held>> : held \in Sample(8) },
      matchingUnit                 : { << >> } \cup { <<held>> : held \in Sample(1) } ]

EncodePurgeOrdersMessage(message) ==
    message.reserved1
        \o EncodeUIntBE(message.numberOfPurgeOrdersBitfields, 1)
        \o (IF message.purgeOrdersBitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.purgeOrdersBitfield1[1], 1))
        \o (IF message.purgeOrdersBitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.purgeOrdersBitfield2[1], 1))
        \o EncodeUIntBE(Len(message.riskGroupIDs), 1)
        \o EncodeRiskGroupIDsList(message.riskGroupIDs)
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])
        \o (IF message.massCancelInst = << >> THEN << >> ELSE message.massCancelInst[1])
        \o (IF message.massCancelId = << >> THEN << >> ELSE message.massCancelId[1])
        \o (IF message.symbol = << >> THEN << >> ELSE message.symbol[1])
        \o (IF message.symbolSfx = << >> THEN << >> ELSE message.symbolSfx[1])
        \o (IF message.matchingUnit = << >> THEN << >> ELSE message.matchingUnit[1])

DecodePurgeOrdersMessage(bytes) ==
    LET reserved1 == ReadBytes(bytes, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET numberOfPurgeOrdersBitfields == ReadUIntBE(reserved1.rest, 1) IN IF ~numberOfPurgeOrdersBitfields.ok THEN Fail ELSE
    LET purgeOrdersBitfield1 == ReadWhen(numberOfPurgeOrdersBitfields.value >= 1, ReadUIntLE(numberOfPurgeOrdersBitfields.rest, 1), numberOfPurgeOrdersBitfields.rest) IN IF ~purgeOrdersBitfield1.ok THEN Fail ELSE
    LET purgeOrdersBitfield2 == ReadWhen(numberOfPurgeOrdersBitfields.value >= 2, ReadUIntLE(purgeOrdersBitfield1.rest, 1), purgeOrdersBitfield1.rest) IN IF ~purgeOrdersBitfield2.ok THEN Fail ELSE
    LET riskGroupIdCnt == ReadUIntBE(purgeOrdersBitfield2.rest, 1) IN IF ~riskGroupIdCnt.ok THEN Fail ELSE
    LET riskGroupIDs == ReadRiskGroupIDsList(riskGroupIdCnt.rest, riskGroupIdCnt.value) IN IF ~riskGroupIDs.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfPurgeOrdersBitfields.value >= 1 /\ (purgeOrdersBitfield1.value # << >> /\ purgeOrdersBitfield1.value[1] % 2 > 0), ReadBytes(riskGroupIDs.rest, 4), riskGroupIDs.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET massCancelInst == ReadWhen(numberOfPurgeOrdersBitfields.value >= 1 /\ (purgeOrdersBitfield1.value # << >> /\ (purgeOrdersBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(clearingFirm.rest, 16), clearingFirm.rest) IN IF ~massCancelInst.ok THEN Fail ELSE
    LET massCancelId == ReadWhen(numberOfPurgeOrdersBitfields.value >= 1 /\ (purgeOrdersBitfield1.value # << >> /\ (purgeOrdersBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(massCancelInst.rest, 20), massCancelInst.rest) IN IF ~massCancelId.ok THEN Fail ELSE
    LET symbol == ReadWhen(numberOfPurgeOrdersBitfields.value >= 2 /\ (purgeOrdersBitfield2.value # << >> /\ purgeOrdersBitfield2.value[1] % 2 > 0), ReadBytes(massCancelId.rest, 8), massCancelId.rest) IN IF ~symbol.ok THEN Fail ELSE
    LET symbolSfx == ReadWhen(numberOfPurgeOrdersBitfields.value >= 2 /\ (purgeOrdersBitfield2.value # << >> /\ (purgeOrdersBitfield2.value[1] \div 2) % 2 > 0), ReadBytes(symbol.rest, 8), symbol.rest) IN IF ~symbolSfx.ok THEN Fail ELSE
    LET matchingUnit == ReadWhen(numberOfPurgeOrdersBitfields.value >= 2 /\ (purgeOrdersBitfield2.value # << >> /\ (purgeOrdersBitfield2.value[1] \div 128) % 2 > 0), ReadBytes(symbolSfx.rest, 1), symbolSfx.rest) IN IF ~matchingUnit.ok THEN Fail ELSE
    Ok([ reserved1                    |-> reserved1.value,
         numberOfPurgeOrdersBitfields |-> numberOfPurgeOrdersBitfields.value,
         purgeOrdersBitfield1         |-> purgeOrdersBitfield1.value,
         purgeOrdersBitfield2         |-> purgeOrdersBitfield2.value,
         riskGroupIDs                 |-> riskGroupIDs.value,
         clearingFirm                 |-> clearingFirm.value,
         massCancelInst               |-> massCancelInst.value,
         massCancelId                 |-> massCancelId.value,
         symbol                       |-> symbol.value,
         symbolSfx                    |-> symbolSfx.value,
         matchingUnit                 |-> matchingUnit.value ], matchingUnit.rest)

(* Purge Orders Message with each field marked present by fields before it there exactly where they say *)
SettlePurgeOrdersMessage(message) ==
    LET settled1 == [message EXCEPT !.purgeOrdersBitfield1 = IF message.numberOfPurgeOrdersBitfields >= 1 THEN (IF message.purgeOrdersBitfield1 = << >> THEN <<0>> ELSE message.purgeOrdersBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.purgeOrdersBitfield2 = IF settled1.numberOfPurgeOrdersBitfields >= 2 THEN (IF settled1.purgeOrdersBitfield2 = << >> THEN <<0>> ELSE settled1.purgeOrdersBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.clearingFirm = IF settled2.numberOfPurgeOrdersBitfields >= 1 /\ (settled2.purgeOrdersBitfield1 # << >> /\ settled2.purgeOrdersBitfield1[1] % 2 > 0) THEN (IF settled2.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled2.clearingFirm) ELSE << >>]
        settled4 == [settled3 EXCEPT !.massCancelInst = IF settled3.numberOfPurgeOrdersBitfields >= 1 /\ (settled3.purgeOrdersBitfield1 # << >> /\ (settled3.purgeOrdersBitfield1[1] \div 4) % 2 > 0) THEN (IF settled3.massCancelInst = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled3.massCancelInst) ELSE << >>]
        settled5 == [settled4 EXCEPT !.massCancelId = IF settled4.numberOfPurgeOrdersBitfields >= 1 /\ (settled4.purgeOrdersBitfield1 # << >> /\ (settled4.purgeOrdersBitfield1[1] \div 16) % 2 > 0) THEN (IF settled4.massCancelId = << >> THEN <<[i \in 1 .. 20 |-> 0]>> ELSE settled4.massCancelId) ELSE << >>]
        settled6 == [settled5 EXCEPT !.symbol = IF settled5.numberOfPurgeOrdersBitfields >= 2 /\ (settled5.purgeOrdersBitfield2 # << >> /\ settled5.purgeOrdersBitfield2[1] % 2 > 0) THEN (IF settled5.symbol = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled5.symbol) ELSE << >>]
        settled7 == [settled6 EXCEPT !.symbolSfx = IF settled6.numberOfPurgeOrdersBitfields >= 2 /\ (settled6.purgeOrdersBitfield2 # << >> /\ (settled6.purgeOrdersBitfield2[1] \div 2) % 2 > 0) THEN (IF settled6.symbolSfx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled6.symbolSfx) ELSE << >>]
        settled8 == [settled7 EXCEPT !.matchingUnit = IF settled7.numberOfPurgeOrdersBitfields >= 2 /\ (settled7.purgeOrdersBitfield2 # << >> /\ (settled7.purgeOrdersBitfield2[1] \div 128) % 2 > 0) THEN (IF settled7.matchingUnit = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled7.matchingUnit) ELSE << >>]
    IN  settled8

ZeroPurgeOrdersMessage ==
    SettlePurgeOrdersMessage([ reserved1                    |-> [i \in 1 .. 1 |-> 0],
                               numberOfPurgeOrdersBitfields |-> 0,
                               purgeOrdersBitfield1         |-> << >>,
                               purgeOrdersBitfield2         |-> << >>,
                               riskGroupIDs                 |-> << >>,
                               clearingFirm                 |-> << >>,
                               massCancelInst               |-> << >>,
                               massCancelId                 |-> << >>,
                               symbol                       |-> << >>,
                               symbolSfx                    |-> << >>,
                               matchingUnit                 |-> << >> ])

(* Purge Orders Message at zero, then each field in turn at the values it is checked at *)
CheckedPurgeOrdersMessage ==
    { ZeroPurgeOrdersMessage }
        \cup { SettlePurgeOrdersMessage([ZeroPurgeOrdersMessage EXCEPT !.reserved1 = one]) : one \in Sample(1) }
        \cup { SettlePurgeOrdersMessage([ZeroPurgeOrdersMessage EXCEPT !.numberOfPurgeOrdersBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettlePurgeOrdersMessage([ZeroPurgeOrdersMessage EXCEPT !.numberOfPurgeOrdersBitfields = 1, !.purgeOrdersBitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettlePurgeOrdersMessage([ZeroPurgeOrdersMessage EXCEPT !.numberOfPurgeOrdersBitfields = 2, !.purgeOrdersBitfield2 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettlePurgeOrdersMessage([ZeroPurgeOrdersMessage EXCEPT !.riskGroupIDs = one]) : one \in SampleLists(OneRiskGroupIDs) }
        \cup { SettlePurgeOrdersMessage([ZeroPurgeOrdersMessage EXCEPT !.numberOfPurgeOrdersBitfields = 1, !.purgeOrdersBitfield1 = <<1>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettlePurgeOrdersMessage([ZeroPurgeOrdersMessage EXCEPT !.numberOfPurgeOrdersBitfields = 1, !.purgeOrdersBitfield1 = <<4>>, !.massCancelInst = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettlePurgeOrdersMessage([ZeroPurgeOrdersMessage EXCEPT !.numberOfPurgeOrdersBitfields = 1, !.purgeOrdersBitfield1 = <<16>>, !.massCancelId = one]) : one \in { <<held>> : held \in Sample(20) } }
        \cup { SettlePurgeOrdersMessage([ZeroPurgeOrdersMessage EXCEPT !.numberOfPurgeOrdersBitfields = 2, !.purgeOrdersBitfield2 = <<1>>, !.symbol = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettlePurgeOrdersMessage([ZeroPurgeOrdersMessage EXCEPT !.numberOfPurgeOrdersBitfields = 2, !.purgeOrdersBitfield2 = <<2>>, !.symbolSfx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettlePurgeOrdersMessage([ZeroPurgeOrdersMessage EXCEPT !.numberOfPurgeOrdersBitfields = 2, !.purgeOrdersBitfield2 = <<128>>, !.matchingUnit = one]) : one \in { <<held>> : held \in Sample(1) } }

(***************************************************************************)
(* Order Acknowledgment Message                                            *)
(***************************************************************************)

OrderAcknowledgmentMessage ==
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
      returnBitfield7         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield8         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield9         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield10        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield11        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield12        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield13        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield14        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield15        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield16        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield17        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield18        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield19        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      side                    : { << >> } \cup { <<held>> : held \in Sample(1) },
      pegDifference           : { << >> } \cup { <<held>> : held \in Sample(8) },
      price                   : { << >> } \cup { <<held>> : held \in Sample(8) },
      execInst                : { << >> } \cup { <<held>> : held \in Sample(1) },
      ordType                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce             : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                  : { << >> } \cup { <<held>> : held \in Sample(4) },
      symbol                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      symbolSfx               : { << >> } \cup { <<held>> : held \in Sample(8) },
      capacity                : { << >> } \cup { <<held>> : held \in Sample(1) },
      account                 : { << >> } \cup { <<held>> : held \in Sample(16) },
      clearingFirm            : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingAccount         : { << >> } \cup { <<held>> : held \in Sample(4) },
      displayIndicator        : { << >> } \cup { <<held>> : held \in Sample(1) },
      maxFloor                : { << >> } \cup { <<held>> : held \in Sample(4) },
      discretionAmount        : { << >> } \cup { <<held>> : held \in Sample(2) },
      orderQty                : { << >> } \cup { <<held>> : held \in Sample(4) },
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
      attributedQuote         : { << >> } \cup { <<held>> : held \in Sample(1) },
      extExecInst             : { << >> } \cup { <<held>> : held \in Sample(1) },
      subLiquidityIndicator   : { << >> } \cup { <<held>> : held \in Sample(1) },
      echoText                : { << >> } \cup { <<held>> : held \in Sample(64) },
      stopPx                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      routingInst             : { << >> } \cup { <<held>> : held \in Sample(4) },
      routStrategy            : { << >> } \cup { <<held>> : held \in Sample(6) },
      routeDeliveryMethod     : { << >> } \cup { <<held>> : held \in Sample(3) },
      exDestination           : { << >> } \cup { <<held>> : held \in Sample(1) },
      crossTradeFlag          : { << >> } \cup { <<held>> : held \in Sample(1) },
      locateBroker            : { << >> } \cup { <<held>> : held \in Sample(4) },
      cmcSessions             : { << >> } \cup { <<held>> : held \in Sample(2) },
      stepUpAmount            : { << >> } \cup { <<held>> : held \in Sample(8) } ]

EncodeOrderAcknowledgmentMessage(message) ==
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
        \o (IF message.returnBitfield7 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield7[1], 1))
        \o (IF message.returnBitfield8 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield8[1], 1))
        \o (IF message.returnBitfield9 = << >> THEN << >> ELSE message.returnBitfield9[1])
        \o (IF message.returnBitfield10 = << >> THEN << >> ELSE message.returnBitfield10[1])
        \o (IF message.returnBitfield11 = << >> THEN << >> ELSE message.returnBitfield11[1])
        \o (IF message.returnBitfield12 = << >> THEN << >> ELSE message.returnBitfield12[1])
        \o (IF message.returnBitfield13 = << >> THEN << >> ELSE message.returnBitfield13[1])
        \o (IF message.returnBitfield14 = << >> THEN << >> ELSE message.returnBitfield14[1])
        \o (IF message.returnBitfield15 = << >> THEN << >> ELSE message.returnBitfield15[1])
        \o (IF message.returnBitfield16 = << >> THEN << >> ELSE message.returnBitfield16[1])
        \o (IF message.returnBitfield17 = << >> THEN << >> ELSE message.returnBitfield17[1])
        \o (IF message.returnBitfield18 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield18[1], 1))
        \o (IF message.returnBitfield19 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield19[1], 1))
        \o (IF message.side = << >> THEN << >> ELSE message.side[1])
        \o (IF message.pegDifference = << >> THEN << >> ELSE message.pegDifference[1])
        \o (IF message.price = << >> THEN << >> ELSE message.price[1])
        \o (IF message.execInst = << >> THEN << >> ELSE message.execInst[1])
        \o (IF message.ordType = << >> THEN << >> ELSE message.ordType[1])
        \o (IF message.timeInForce = << >> THEN << >> ELSE message.timeInForce[1])
        \o (IF message.minQty = << >> THEN << >> ELSE message.minQty[1])
        \o (IF message.symbol = << >> THEN << >> ELSE message.symbol[1])
        \o (IF message.symbolSfx = << >> THEN << >> ELSE message.symbolSfx[1])
        \o (IF message.capacity = << >> THEN << >> ELSE message.capacity[1])
        \o (IF message.account = << >> THEN << >> ELSE message.account[1])
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])
        \o (IF message.clearingAccount = << >> THEN << >> ELSE message.clearingAccount[1])
        \o (IF message.displayIndicator = << >> THEN << >> ELSE message.displayIndicator[1])
        \o (IF message.maxFloor = << >> THEN << >> ELSE message.maxFloor[1])
        \o (IF message.discretionAmount = << >> THEN << >> ELSE message.discretionAmount[1])
        \o (IF message.orderQty = << >> THEN << >> ELSE message.orderQty[1])
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
        \o (IF message.attributedQuote = << >> THEN << >> ELSE message.attributedQuote[1])
        \o (IF message.extExecInst = << >> THEN << >> ELSE message.extExecInst[1])
        \o (IF message.subLiquidityIndicator = << >> THEN << >> ELSE message.subLiquidityIndicator[1])
        \o (IF message.echoText = << >> THEN << >> ELSE message.echoText[1])
        \o (IF message.stopPx = << >> THEN << >> ELSE message.stopPx[1])
        \o (IF message.routingInst = << >> THEN << >> ELSE message.routingInst[1])
        \o (IF message.routStrategy = << >> THEN << >> ELSE message.routStrategy[1])
        \o (IF message.routeDeliveryMethod = << >> THEN << >> ELSE message.routeDeliveryMethod[1])
        \o (IF message.exDestination = << >> THEN << >> ELSE message.exDestination[1])
        \o (IF message.crossTradeFlag = << >> THEN << >> ELSE message.crossTradeFlag[1])
        \o (IF message.locateBroker = << >> THEN << >> ELSE message.locateBroker[1])
        \o (IF message.cmcSessions = << >> THEN << >> ELSE message.cmcSessions[1])
        \o (IF message.stepUpAmount = << >> THEN << >> ELSE message.stepUpAmount[1])

DecodeOrderAcknowledgmentMessage(bytes) ==
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
    LET returnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadUIntLE(returnBitfield6.rest, 1), returnBitfield6.rest) IN IF ~returnBitfield7.ok THEN Fail ELSE
    LET returnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadUIntLE(returnBitfield7.rest, 1), returnBitfield7.rest) IN IF ~returnBitfield8.ok THEN Fail ELSE
    LET returnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadBytes(returnBitfield8.rest, 1), returnBitfield8.rest) IN IF ~returnBitfield9.ok THEN Fail ELSE
    LET returnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadBytes(returnBitfield9.rest, 1), returnBitfield9.rest) IN IF ~returnBitfield10.ok THEN Fail ELSE
    LET returnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadBytes(returnBitfield10.rest, 1), returnBitfield10.rest) IN IF ~returnBitfield11.ok THEN Fail ELSE
    LET returnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadBytes(returnBitfield11.rest, 1), returnBitfield11.rest) IN IF ~returnBitfield12.ok THEN Fail ELSE
    LET returnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(returnBitfield12.rest, 1), returnBitfield12.rest) IN IF ~returnBitfield13.ok THEN Fail ELSE
    LET returnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(returnBitfield13.rest, 1), returnBitfield13.rest) IN IF ~returnBitfield14.ok THEN Fail ELSE
    LET returnBitfield15 == ReadWhen(numberOfReturnBitfields.value >= 15, ReadBytes(returnBitfield14.rest, 1), returnBitfield14.rest) IN IF ~returnBitfield15.ok THEN Fail ELSE
    LET returnBitfield16 == ReadWhen(numberOfReturnBitfields.value >= 16, ReadBytes(returnBitfield15.rest, 1), returnBitfield15.rest) IN IF ~returnBitfield16.ok THEN Fail ELSE
    LET returnBitfield17 == ReadWhen(numberOfReturnBitfields.value >= 17, ReadBytes(returnBitfield16.rest, 1), returnBitfield16.rest) IN IF ~returnBitfield17.ok THEN Fail ELSE
    LET returnBitfield18 == ReadWhen(numberOfReturnBitfields.value >= 18, ReadUIntLE(returnBitfield17.rest, 1), returnBitfield17.rest) IN IF ~returnBitfield18.ok THEN Fail ELSE
    LET returnBitfield19 == ReadWhen(numberOfReturnBitfields.value >= 19, ReadUIntLE(returnBitfield18.rest, 1), returnBitfield18.rest) IN IF ~returnBitfield19.ok THEN Fail ELSE
    LET side == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ returnBitfield1.value[1] % 2 > 0), ReadBytes(returnBitfield19.rest, 1), returnBitfield19.rest) IN IF ~side.ok THEN Fail ELSE
    LET pegDifference == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 2) % 2 > 0), ReadBytes(side.rest, 8), side.rest) IN IF ~pegDifference.ok THEN Fail ELSE
    LET price == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(pegDifference.rest, 8), pegDifference.rest) IN IF ~price.ok THEN Fail ELSE
    LET execInst == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 8) % 2 > 0), ReadBytes(price.rest, 1), price.rest) IN IF ~execInst.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(execInst.rest, 1), execInst.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET symbol == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ returnBitfield2.value[1] % 2 > 0), ReadBytes(minQty.rest, 8), minQty.rest) IN IF ~symbol.ok THEN Fail ELSE
    LET symbolSfx == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ (returnBitfield2.value[1] \div 2) % 2 > 0), ReadBytes(symbol.rest, 8), symbol.rest) IN IF ~symbolSfx.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ (returnBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(symbolSfx.rest, 1), symbolSfx.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ returnBitfield3.value[1] % 2 > 0), ReadBytes(capacity.rest, 16), capacity.rest) IN IF ~account.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 2) % 2 > 0), ReadBytes(account.rest, 4), account.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 4) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET displayIndicator == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 8) % 2 > 0), ReadBytes(clearingAccount.rest, 1), clearingAccount.rest) IN IF ~displayIndicator.ok THEN Fail ELSE
    LET maxFloor == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 16) % 2 > 0), ReadBytes(displayIndicator.rest, 4), displayIndicator.rest) IN IF ~maxFloor.ok THEN Fail ELSE
    LET discretionAmount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 32) % 2 > 0), ReadBytes(maxFloor.rest, 2), maxFloor.rest) IN IF ~discretionAmount.ok THEN Fail ELSE
    LET orderQty == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 64) % 2 > 0), ReadBytes(discretionAmount.rest, 4), discretionAmount.rest) IN IF ~orderQty.ok THEN Fail ELSE
    LET preventMatch == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 128) % 2 > 0), ReadBytes(orderQty.rest, 3), orderQty.rest) IN IF ~preventMatch.ok THEN Fail ELSE
    LET origClOrdId == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ returnBitfield5.value[1] % 2 > 0), ReadBytes(preventMatch.rest, 20), preventMatch.rest) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET leavesQty == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 2) % 2 > 0), ReadBytes(origClOrdId.rest, 4), origClOrdId.rest) IN IF ~leavesQty.ok THEN Fail ELSE
    LET lastShares == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 4) % 2 > 0), ReadBytes(leavesQty.rest, 4), leavesQty.rest) IN IF ~lastShares.ok THEN Fail ELSE
    LET lastPx == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 8) % 2 > 0), ReadBytes(lastShares.rest, 8), lastShares.rest) IN IF ~lastPx.ok THEN Fail ELSE
    LET displayPrice == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 16) % 2 > 0), ReadBytes(lastPx.rest, 8), lastPx.rest) IN IF ~displayPrice.ok THEN Fail ELSE
    LET workingPrice == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 32) % 2 > 0), ReadBytes(displayPrice.rest, 8), displayPrice.rest) IN IF ~workingPrice.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 64) % 2 > 0), ReadBytes(workingPrice.rest, 1), workingPrice.rest) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET expireTime == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 128) % 2 > 0), ReadBytes(baseLiquidityIndicator.rest, 8), baseLiquidityIndicator.rest) IN IF ~expireTime.ok THEN Fail ELSE
    LET secondaryOrderId == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (returnBitfield6.value # << >> /\ returnBitfield6.value[1] % 2 > 0), ReadBytes(expireTime.rest, 8), expireTime.rest) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET attributedQuote == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (returnBitfield6.value # << >> /\ (returnBitfield6.value[1] \div 8) % 2 > 0), ReadBytes(secondaryOrderId.rest, 1), secondaryOrderId.rest) IN IF ~attributedQuote.ok THEN Fail ELSE
    LET extExecInst == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (returnBitfield6.value # << >> /\ (returnBitfield6.value[1] \div 16) % 2 > 0), ReadBytes(attributedQuote.rest, 1), attributedQuote.rest) IN IF ~extExecInst.ok THEN Fail ELSE
    LET subLiquidityIndicator == ReadWhen(numberOfReturnBitfields.value >= 7 /\ (returnBitfield7.value # << >> /\ returnBitfield7.value[1] % 2 > 0), ReadBytes(extExecInst.rest, 1), extExecInst.rest) IN IF ~subLiquidityIndicator.ok THEN Fail ELSE
    LET echoText == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 2) % 2 > 0), ReadBytes(subLiquidityIndicator.rest, 64), subLiquidityIndicator.rest) IN IF ~echoText.ok THEN Fail ELSE
    LET stopPx == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 4) % 2 > 0), ReadBytes(echoText.rest, 8), echoText.rest) IN IF ~stopPx.ok THEN Fail ELSE
    LET routingInst == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 8) % 2 > 0), ReadBytes(stopPx.rest, 4), stopPx.rest) IN IF ~routingInst.ok THEN Fail ELSE
    LET routStrategy == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 16) % 2 > 0), ReadBytes(routingInst.rest, 6), routingInst.rest) IN IF ~routStrategy.ok THEN Fail ELSE
    LET routeDeliveryMethod == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 32) % 2 > 0), ReadBytes(routStrategy.rest, 3), routStrategy.rest) IN IF ~routeDeliveryMethod.ok THEN Fail ELSE
    LET exDestination == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 64) % 2 > 0), ReadBytes(routeDeliveryMethod.rest, 1), routeDeliveryMethod.rest) IN IF ~exDestination.ok THEN Fail ELSE
    LET crossTradeFlag == ReadWhen(numberOfReturnBitfields.value >= 18 /\ (returnBitfield18.value # << >> /\ (returnBitfield18.value[1] \div 8) % 2 > 0), ReadBytes(exDestination.rest, 1), exDestination.rest) IN IF ~crossTradeFlag.ok THEN Fail ELSE
    LET locateBroker == ReadWhen(numberOfReturnBitfields.value >= 18 /\ (returnBitfield18.value # << >> /\ (returnBitfield18.value[1] \div 64) % 2 > 0), ReadBytes(crossTradeFlag.rest, 4), crossTradeFlag.rest) IN IF ~locateBroker.ok THEN Fail ELSE
    LET cmcSessions == ReadWhen(numberOfReturnBitfields.value >= 19 /\ (returnBitfield19.value # << >> /\ (returnBitfield19.value[1] \div 8) % 2 > 0), ReadBytes(locateBroker.rest, 2), locateBroker.rest) IN IF ~cmcSessions.ok THEN Fail ELSE
    LET stepUpAmount == ReadWhen(numberOfReturnBitfields.value >= 19 /\ (returnBitfield19.value # << >> /\ (returnBitfield19.value[1] \div 64) % 2 > 0), ReadBytes(cmcSessions.rest, 8), cmcSessions.rest) IN IF ~stepUpAmount.ok THEN Fail ELSE
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
         returnBitfield18        |-> returnBitfield18.value,
         returnBitfield19        |-> returnBitfield19.value,
         side                    |-> side.value,
         pegDifference           |-> pegDifference.value,
         price                   |-> price.value,
         execInst                |-> execInst.value,
         ordType                 |-> ordType.value,
         timeInForce             |-> timeInForce.value,
         minQty                  |-> minQty.value,
         symbol                  |-> symbol.value,
         symbolSfx               |-> symbolSfx.value,
         capacity                |-> capacity.value,
         account                 |-> account.value,
         clearingFirm            |-> clearingFirm.value,
         clearingAccount         |-> clearingAccount.value,
         displayIndicator        |-> displayIndicator.value,
         maxFloor                |-> maxFloor.value,
         discretionAmount        |-> discretionAmount.value,
         orderQty                |-> orderQty.value,
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
         attributedQuote         |-> attributedQuote.value,
         extExecInst             |-> extExecInst.value,
         subLiquidityIndicator   |-> subLiquidityIndicator.value,
         echoText                |-> echoText.value,
         stopPx                  |-> stopPx.value,
         routingInst             |-> routingInst.value,
         routStrategy            |-> routStrategy.value,
         routeDeliveryMethod     |-> routeDeliveryMethod.value,
         exDestination           |-> exDestination.value,
         crossTradeFlag          |-> crossTradeFlag.value,
         locateBroker            |-> locateBroker.value,
         cmcSessions             |-> cmcSessions.value,
         stepUpAmount            |-> stepUpAmount.value ], stepUpAmount.rest)

(* Order Acknowledgment Message with each field marked present by fields before it there exactly where they say *)
SettleOrderAcknowledgmentMessage(message) ==
    LET settled1 == [message EXCEPT !.returnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.returnBitfield1 = << >> THEN <<0>> ELSE message.returnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.returnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.returnBitfield2 = << >> THEN <<0>> ELSE settled1.returnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.returnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.returnBitfield3 = << >> THEN <<0>> ELSE settled2.returnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.returnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.returnBitfield4 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled3.returnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.returnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.returnBitfield5 = << >> THEN <<0>> ELSE settled4.returnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.returnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.returnBitfield6 = << >> THEN <<0>> ELSE settled5.returnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.returnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.returnBitfield7 = << >> THEN <<0>> ELSE settled6.returnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.returnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.returnBitfield8 = << >> THEN <<0>> ELSE settled7.returnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.returnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.returnBitfield9 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled8.returnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.returnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.returnBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.returnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.returnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.returnBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.returnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.returnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.returnBitfield12 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.returnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.returnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.returnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.returnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.returnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.returnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.returnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.returnBitfield15 = IF settled14.numberOfReturnBitfields >= 15 THEN (IF settled14.returnBitfield15 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.returnBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.returnBitfield16 = IF settled15.numberOfReturnBitfields >= 16 THEN (IF settled15.returnBitfield16 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled15.returnBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.returnBitfield17 = IF settled16.numberOfReturnBitfields >= 17 THEN (IF settled16.returnBitfield17 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled16.returnBitfield17) ELSE << >>]
        settled18 == [settled17 EXCEPT !.returnBitfield18 = IF settled17.numberOfReturnBitfields >= 18 THEN (IF settled17.returnBitfield18 = << >> THEN <<0>> ELSE settled17.returnBitfield18) ELSE << >>]
        settled19 == [settled18 EXCEPT !.returnBitfield19 = IF settled18.numberOfReturnBitfields >= 19 THEN (IF settled18.returnBitfield19 = << >> THEN <<0>> ELSE settled18.returnBitfield19) ELSE << >>]
        settled20 == [settled19 EXCEPT !.side = IF settled19.numberOfReturnBitfields >= 1 /\ (settled19.returnBitfield1 # << >> /\ settled19.returnBitfield1[1] % 2 > 0) THEN (IF settled19.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled19.side) ELSE << >>]
        settled21 == [settled20 EXCEPT !.pegDifference = IF settled20.numberOfReturnBitfields >= 1 /\ (settled20.returnBitfield1 # << >> /\ (settled20.returnBitfield1[1] \div 2) % 2 > 0) THEN (IF settled20.pegDifference = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled20.pegDifference) ELSE << >>]
        settled22 == [settled21 EXCEPT !.price = IF settled21.numberOfReturnBitfields >= 1 /\ (settled21.returnBitfield1 # << >> /\ (settled21.returnBitfield1[1] \div 4) % 2 > 0) THEN (IF settled21.price = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled21.price) ELSE << >>]
        settled23 == [settled22 EXCEPT !.execInst = IF settled22.numberOfReturnBitfields >= 1 /\ (settled22.returnBitfield1 # << >> /\ (settled22.returnBitfield1[1] \div 8) % 2 > 0) THEN (IF settled22.execInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled22.execInst) ELSE << >>]
        settled24 == [settled23 EXCEPT !.ordType = IF settled23.numberOfReturnBitfields >= 1 /\ (settled23.returnBitfield1 # << >> /\ (settled23.returnBitfield1[1] \div 16) % 2 > 0) THEN (IF settled23.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled23.ordType) ELSE << >>]
        settled25 == [settled24 EXCEPT !.timeInForce = IF settled24.numberOfReturnBitfields >= 1 /\ (settled24.returnBitfield1 # << >> /\ (settled24.returnBitfield1[1] \div 32) % 2 > 0) THEN (IF settled24.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled24.timeInForce) ELSE << >>]
        settled26 == [settled25 EXCEPT !.minQty = IF settled25.numberOfReturnBitfields >= 1 /\ (settled25.returnBitfield1 # << >> /\ (settled25.returnBitfield1[1] \div 64) % 2 > 0) THEN (IF settled25.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled25.minQty) ELSE << >>]
        settled27 == [settled26 EXCEPT !.symbol = IF settled26.numberOfReturnBitfields >= 2 /\ (settled26.returnBitfield2 # << >> /\ settled26.returnBitfield2[1] % 2 > 0) THEN (IF settled26.symbol = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled26.symbol) ELSE << >>]
        settled28 == [settled27 EXCEPT !.symbolSfx = IF settled27.numberOfReturnBitfields >= 2 /\ (settled27.returnBitfield2 # << >> /\ (settled27.returnBitfield2[1] \div 2) % 2 > 0) THEN (IF settled27.symbolSfx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled27.symbolSfx) ELSE << >>]
        settled29 == [settled28 EXCEPT !.capacity = IF settled28.numberOfReturnBitfields >= 2 /\ (settled28.returnBitfield2 # << >> /\ (settled28.returnBitfield2[1] \div 64) % 2 > 0) THEN (IF settled28.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled28.capacity) ELSE << >>]
        settled30 == [settled29 EXCEPT !.account = IF settled29.numberOfReturnBitfields >= 3 /\ (settled29.returnBitfield3 # << >> /\ settled29.returnBitfield3[1] % 2 > 0) THEN (IF settled29.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled29.account) ELSE << >>]
        settled31 == [settled30 EXCEPT !.clearingFirm = IF settled30.numberOfReturnBitfields >= 3 /\ (settled30.returnBitfield3 # << >> /\ (settled30.returnBitfield3[1] \div 2) % 2 > 0) THEN (IF settled30.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled30.clearingFirm) ELSE << >>]
        settled32 == [settled31 EXCEPT !.clearingAccount = IF settled31.numberOfReturnBitfields >= 3 /\ (settled31.returnBitfield3 # << >> /\ (settled31.returnBitfield3[1] \div 4) % 2 > 0) THEN (IF settled31.clearingAccount = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled31.clearingAccount) ELSE << >>]
        settled33 == [settled32 EXCEPT !.displayIndicator = IF settled32.numberOfReturnBitfields >= 3 /\ (settled32.returnBitfield3 # << >> /\ (settled32.returnBitfield3[1] \div 8) % 2 > 0) THEN (IF settled32.displayIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled32.displayIndicator) ELSE << >>]
        settled34 == [settled33 EXCEPT !.maxFloor = IF settled33.numberOfReturnBitfields >= 3 /\ (settled33.returnBitfield3 # << >> /\ (settled33.returnBitfield3[1] \div 16) % 2 > 0) THEN (IF settled33.maxFloor = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled33.maxFloor) ELSE << >>]
        settled35 == [settled34 EXCEPT !.discretionAmount = IF settled34.numberOfReturnBitfields >= 3 /\ (settled34.returnBitfield3 # << >> /\ (settled34.returnBitfield3[1] \div 32) % 2 > 0) THEN (IF settled34.discretionAmount = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled34.discretionAmount) ELSE << >>]
        settled36 == [settled35 EXCEPT !.orderQty = IF settled35.numberOfReturnBitfields >= 3 /\ (settled35.returnBitfield3 # << >> /\ (settled35.returnBitfield3[1] \div 64) % 2 > 0) THEN (IF settled35.orderQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled35.orderQty) ELSE << >>]
        settled37 == [settled36 EXCEPT !.preventMatch = IF settled36.numberOfReturnBitfields >= 3 /\ (settled36.returnBitfield3 # << >> /\ (settled36.returnBitfield3[1] \div 128) % 2 > 0) THEN (IF settled36.preventMatch = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled36.preventMatch) ELSE << >>]
        settled38 == [settled37 EXCEPT !.origClOrdId = IF settled37.numberOfReturnBitfields >= 5 /\ (settled37.returnBitfield5 # << >> /\ settled37.returnBitfield5[1] % 2 > 0) THEN (IF settled37.origClOrdId = << >> THEN <<[i \in 1 .. 20 |-> 0]>> ELSE settled37.origClOrdId) ELSE << >>]
        settled39 == [settled38 EXCEPT !.leavesQty = IF settled38.numberOfReturnBitfields >= 5 /\ (settled38.returnBitfield5 # << >> /\ (settled38.returnBitfield5[1] \div 2) % 2 > 0) THEN (IF settled38.leavesQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled38.leavesQty) ELSE << >>]
        settled40 == [settled39 EXCEPT !.lastShares = IF settled39.numberOfReturnBitfields >= 5 /\ (settled39.returnBitfield5 # << >> /\ (settled39.returnBitfield5[1] \div 4) % 2 > 0) THEN (IF settled39.lastShares = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled39.lastShares) ELSE << >>]
        settled41 == [settled40 EXCEPT !.lastPx = IF settled40.numberOfReturnBitfields >= 5 /\ (settled40.returnBitfield5 # << >> /\ (settled40.returnBitfield5[1] \div 8) % 2 > 0) THEN (IF settled40.lastPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled40.lastPx) ELSE << >>]
        settled42 == [settled41 EXCEPT !.displayPrice = IF settled41.numberOfReturnBitfields >= 5 /\ (settled41.returnBitfield5 # << >> /\ (settled41.returnBitfield5[1] \div 16) % 2 > 0) THEN (IF settled41.displayPrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled41.displayPrice) ELSE << >>]
        settled43 == [settled42 EXCEPT !.workingPrice = IF settled42.numberOfReturnBitfields >= 5 /\ (settled42.returnBitfield5 # << >> /\ (settled42.returnBitfield5[1] \div 32) % 2 > 0) THEN (IF settled42.workingPrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled42.workingPrice) ELSE << >>]
        settled44 == [settled43 EXCEPT !.baseLiquidityIndicator = IF settled43.numberOfReturnBitfields >= 5 /\ (settled43.returnBitfield5 # << >> /\ (settled43.returnBitfield5[1] \div 64) % 2 > 0) THEN (IF settled43.baseLiquidityIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled43.baseLiquidityIndicator) ELSE << >>]
        settled45 == [settled44 EXCEPT !.expireTime = IF settled44.numberOfReturnBitfields >= 5 /\ (settled44.returnBitfield5 # << >> /\ (settled44.returnBitfield5[1] \div 128) % 2 > 0) THEN (IF settled44.expireTime = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled44.expireTime) ELSE << >>]
        settled46 == [settled45 EXCEPT !.secondaryOrderId = IF settled45.numberOfReturnBitfields >= 6 /\ (settled45.returnBitfield6 # << >> /\ settled45.returnBitfield6[1] % 2 > 0) THEN (IF settled45.secondaryOrderId = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled45.secondaryOrderId) ELSE << >>]
        settled47 == [settled46 EXCEPT !.attributedQuote = IF settled46.numberOfReturnBitfields >= 6 /\ (settled46.returnBitfield6 # << >> /\ (settled46.returnBitfield6[1] \div 8) % 2 > 0) THEN (IF settled46.attributedQuote = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled46.attributedQuote) ELSE << >>]
        settled48 == [settled47 EXCEPT !.extExecInst = IF settled47.numberOfReturnBitfields >= 6 /\ (settled47.returnBitfield6 # << >> /\ (settled47.returnBitfield6[1] \div 16) % 2 > 0) THEN (IF settled47.extExecInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled47.extExecInst) ELSE << >>]
        settled49 == [settled48 EXCEPT !.subLiquidityIndicator = IF settled48.numberOfReturnBitfields >= 7 /\ (settled48.returnBitfield7 # << >> /\ settled48.returnBitfield7[1] % 2 > 0) THEN (IF settled48.subLiquidityIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled48.subLiquidityIndicator) ELSE << >>]
        settled50 == [settled49 EXCEPT !.echoText = IF settled49.numberOfReturnBitfields >= 8 /\ (settled49.returnBitfield8 # << >> /\ (settled49.returnBitfield8[1] \div 2) % 2 > 0) THEN (IF settled49.echoText = << >> THEN <<[i \in 1 .. 64 |-> 0]>> ELSE settled49.echoText) ELSE << >>]
        settled51 == [settled50 EXCEPT !.stopPx = IF settled50.numberOfReturnBitfields >= 8 /\ (settled50.returnBitfield8 # << >> /\ (settled50.returnBitfield8[1] \div 4) % 2 > 0) THEN (IF settled50.stopPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled50.stopPx) ELSE << >>]
        settled52 == [settled51 EXCEPT !.routingInst = IF settled51.numberOfReturnBitfields >= 8 /\ (settled51.returnBitfield8 # << >> /\ (settled51.returnBitfield8[1] \div 8) % 2 > 0) THEN (IF settled51.routingInst = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled51.routingInst) ELSE << >>]
        settled53 == [settled52 EXCEPT !.routStrategy = IF settled52.numberOfReturnBitfields >= 8 /\ (settled52.returnBitfield8 # << >> /\ (settled52.returnBitfield8[1] \div 16) % 2 > 0) THEN (IF settled52.routStrategy = << >> THEN <<[i \in 1 .. 6 |-> 0]>> ELSE settled52.routStrategy) ELSE << >>]
        settled54 == [settled53 EXCEPT !.routeDeliveryMethod = IF settled53.numberOfReturnBitfields >= 8 /\ (settled53.returnBitfield8 # << >> /\ (settled53.returnBitfield8[1] \div 32) % 2 > 0) THEN (IF settled53.routeDeliveryMethod = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled53.routeDeliveryMethod) ELSE << >>]
        settled55 == [settled54 EXCEPT !.exDestination = IF settled54.numberOfReturnBitfields >= 8 /\ (settled54.returnBitfield8 # << >> /\ (settled54.returnBitfield8[1] \div 64) % 2 > 0) THEN (IF settled54.exDestination = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled54.exDestination) ELSE << >>]
        settled56 == [settled55 EXCEPT !.crossTradeFlag = IF settled55.numberOfReturnBitfields >= 18 /\ (settled55.returnBitfield18 # << >> /\ (settled55.returnBitfield18[1] \div 8) % 2 > 0) THEN (IF settled55.crossTradeFlag = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled55.crossTradeFlag) ELSE << >>]
        settled57 == [settled56 EXCEPT !.locateBroker = IF settled56.numberOfReturnBitfields >= 18 /\ (settled56.returnBitfield18 # << >> /\ (settled56.returnBitfield18[1] \div 64) % 2 > 0) THEN (IF settled56.locateBroker = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled56.locateBroker) ELSE << >>]
        settled58 == [settled57 EXCEPT !.cmcSessions = IF settled57.numberOfReturnBitfields >= 19 /\ (settled57.returnBitfield19 # << >> /\ (settled57.returnBitfield19[1] \div 8) % 2 > 0) THEN (IF settled57.cmcSessions = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled57.cmcSessions) ELSE << >>]
        settled59 == [settled58 EXCEPT !.stepUpAmount = IF settled58.numberOfReturnBitfields >= 19 /\ (settled58.returnBitfield19 # << >> /\ (settled58.returnBitfield19[1] \div 64) % 2 > 0) THEN (IF settled58.stepUpAmount = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled58.stepUpAmount) ELSE << >>]
    IN  settled59

ZeroOrderAcknowledgmentMessage ==
    SettleOrderAcknowledgmentMessage([ transactionTime         |-> [i \in 1 .. 8 |-> 0],
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
                                       returnBitfield18        |-> << >>,
                                       returnBitfield19        |-> << >>,
                                       side                    |-> << >>,
                                       pegDifference           |-> << >>,
                                       price                   |-> << >>,
                                       execInst                |-> << >>,
                                       ordType                 |-> << >>,
                                       timeInForce             |-> << >>,
                                       minQty                  |-> << >>,
                                       symbol                  |-> << >>,
                                       symbolSfx               |-> << >>,
                                       capacity                |-> << >>,
                                       account                 |-> << >>,
                                       clearingFirm            |-> << >>,
                                       clearingAccount         |-> << >>,
                                       displayIndicator        |-> << >>,
                                       maxFloor                |-> << >>,
                                       discretionAmount        |-> << >>,
                                       orderQty                |-> << >>,
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
                                       attributedQuote         |-> << >>,
                                       extExecInst             |-> << >>,
                                       subLiquidityIndicator   |-> << >>,
                                       echoText                |-> << >>,
                                       stopPx                  |-> << >>,
                                       routingInst             |-> << >>,
                                       routStrategy            |-> << >>,
                                       routeDeliveryMethod     |-> << >>,
                                       exDestination           |-> << >>,
                                       crossTradeFlag          |-> << >>,
                                       locateBroker            |-> << >>,
                                       cmcSessions             |-> << >>,
                                       stepUpAmount            |-> << >> ])

(* Order Acknowledgment Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderAcknowledgmentMessage ==
    { ZeroOrderAcknowledgmentMessage }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.transactionTime = one]) : one \in Sample(8) }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.clOrdId = one]) : one \in Sample(20) }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.orderId = one]) : one \in Sample(8) }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.reserved1 = one]) : one \in Sample(1) }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 7, !.returnBitfield7 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 9, !.returnBitfield9 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 10, !.returnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 11, !.returnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 13, !.returnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 14, !.returnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 15, !.returnBitfield15 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 17, !.returnBitfield17 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 18, !.returnBitfield18 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 19, !.returnBitfield19 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<1>>, !.side = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<2>>, !.pegDifference = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<4>>, !.price = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<8>>, !.execInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<1>>, !.symbol = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<2>>, !.symbolSfx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<1>>, !.account = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<2>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<4>>, !.clearingAccount = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<8>>, !.displayIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<16>>, !.maxFloor = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<32>>, !.discretionAmount = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<64>>, !.orderQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<128>>, !.preventMatch = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<1>>, !.origClOrdId = one]) : one \in { <<held>> : held \in Sample(20) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<2>>, !.leavesQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<4>>, !.lastShares = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<8>>, !.lastPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<16>>, !.displayPrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<32>>, !.workingPrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<64>>, !.baseLiquidityIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<128>>, !.expireTime = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = <<1>>, !.secondaryOrderId = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = <<8>>, !.attributedQuote = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = <<16>>, !.extExecInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 7, !.returnBitfield7 = <<1>>, !.subLiquidityIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<2>>, !.echoText = one]) : one \in { <<held>> : held \in Sample(64) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<4>>, !.stopPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<8>>, !.routingInst = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<16>>, !.routStrategy = one]) : one \in { <<held>> : held \in Sample(6) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<32>>, !.routeDeliveryMethod = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<64>>, !.exDestination = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 18, !.returnBitfield18 = <<8>>, !.crossTradeFlag = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 18, !.returnBitfield18 = <<64>>, !.locateBroker = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 19, !.returnBitfield19 = <<8>>, !.cmcSessions = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 19, !.returnBitfield19 = <<64>>, !.stepUpAmount = one]) : one \in { <<held>> : held \in Sample(8) } }

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
      returnBitfield4         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield5         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield6         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield7         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield8         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield9         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield10        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield11        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield12        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield13        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield14        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield15        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield16        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield17        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield18        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield19        : { << >> } \cup { <<held>> : held \in Sample(1) },
      side                    : { << >> } \cup { <<held>> : held \in Sample(1) },
      pegDifference           : { << >> } \cup { <<held>> : held \in Sample(8) },
      price                   : { << >> } \cup { <<held>> : held \in Sample(8) },
      execInst                : { << >> } \cup { <<held>> : held \in Sample(1) },
      ordType                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce             : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                  : { << >> } \cup { <<held>> : held \in Sample(4) },
      symbol                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      symbolSfx               : { << >> } \cup { <<held>> : held \in Sample(8) },
      capacity                : { << >> } \cup { <<held>> : held \in Sample(1) },
      account                 : { << >> } \cup { <<held>> : held \in Sample(16) },
      clearingFirm            : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingAccount         : { << >> } \cup { <<held>> : held \in Sample(4) },
      displayIndicator        : { << >> } \cup { <<held>> : held \in Sample(1) },
      maxFloor                : { << >> } \cup { <<held>> : held \in Sample(4) },
      discretionAmount        : { << >> } \cup { <<held>> : held \in Sample(2) },
      orderQty                : { << >> } \cup { <<held>> : held \in Sample(4) },
      preventMatch            : { << >> } \cup { <<held>> : held \in Sample(3) },
      secondaryOrderId        : { << >> } \cup { <<held>> : held \in Sample(8) },
      attributedQuote         : { << >> } \cup { <<held>> : held \in Sample(1) },
      extExecInst             : { << >> } \cup { <<held>> : held \in Sample(1) },
      echoText                : { << >> } \cup { <<held>> : held \in Sample(64) },
      stopPx                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      routingInst             : { << >> } \cup { <<held>> : held \in Sample(4) },
      routStrategy            : { << >> } \cup { <<held>> : held \in Sample(6) },
      routeDeliveryMethod     : { << >> } \cup { <<held>> : held \in Sample(3) },
      exDestination           : { << >> } \cup { <<held>> : held \in Sample(1) } ]

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
        \o (IF message.returnBitfield4 = << >> THEN << >> ELSE message.returnBitfield4[1])
        \o (IF message.returnBitfield5 = << >> THEN << >> ELSE message.returnBitfield5[1])
        \o (IF message.returnBitfield6 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield6[1], 1))
        \o (IF message.returnBitfield7 = << >> THEN << >> ELSE message.returnBitfield7[1])
        \o (IF message.returnBitfield8 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield8[1], 1))
        \o (IF message.returnBitfield9 = << >> THEN << >> ELSE message.returnBitfield9[1])
        \o (IF message.returnBitfield10 = << >> THEN << >> ELSE message.returnBitfield10[1])
        \o (IF message.returnBitfield11 = << >> THEN << >> ELSE message.returnBitfield11[1])
        \o (IF message.returnBitfield12 = << >> THEN << >> ELSE message.returnBitfield12[1])
        \o (IF message.returnBitfield13 = << >> THEN << >> ELSE message.returnBitfield13[1])
        \o (IF message.returnBitfield14 = << >> THEN << >> ELSE message.returnBitfield14[1])
        \o (IF message.returnBitfield15 = << >> THEN << >> ELSE message.returnBitfield15[1])
        \o (IF message.returnBitfield16 = << >> THEN << >> ELSE message.returnBitfield16[1])
        \o (IF message.returnBitfield17 = << >> THEN << >> ELSE message.returnBitfield17[1])
        \o (IF message.returnBitfield18 = << >> THEN << >> ELSE message.returnBitfield18[1])
        \o (IF message.returnBitfield19 = << >> THEN << >> ELSE message.returnBitfield19[1])
        \o (IF message.side = << >> THEN << >> ELSE message.side[1])
        \o (IF message.pegDifference = << >> THEN << >> ELSE message.pegDifference[1])
        \o (IF message.price = << >> THEN << >> ELSE message.price[1])
        \o (IF message.execInst = << >> THEN << >> ELSE message.execInst[1])
        \o (IF message.ordType = << >> THEN << >> ELSE message.ordType[1])
        \o (IF message.timeInForce = << >> THEN << >> ELSE message.timeInForce[1])
        \o (IF message.minQty = << >> THEN << >> ELSE message.minQty[1])
        \o (IF message.symbol = << >> THEN << >> ELSE message.symbol[1])
        \o (IF message.symbolSfx = << >> THEN << >> ELSE message.symbolSfx[1])
        \o (IF message.capacity = << >> THEN << >> ELSE message.capacity[1])
        \o (IF message.account = << >> THEN << >> ELSE message.account[1])
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])
        \o (IF message.clearingAccount = << >> THEN << >> ELSE message.clearingAccount[1])
        \o (IF message.displayIndicator = << >> THEN << >> ELSE message.displayIndicator[1])
        \o (IF message.maxFloor = << >> THEN << >> ELSE message.maxFloor[1])
        \o (IF message.discretionAmount = << >> THEN << >> ELSE message.discretionAmount[1])
        \o (IF message.orderQty = << >> THEN << >> ELSE message.orderQty[1])
        \o (IF message.preventMatch = << >> THEN << >> ELSE message.preventMatch[1])
        \o (IF message.secondaryOrderId = << >> THEN << >> ELSE message.secondaryOrderId[1])
        \o (IF message.attributedQuote = << >> THEN << >> ELSE message.attributedQuote[1])
        \o (IF message.extExecInst = << >> THEN << >> ELSE message.extExecInst[1])
        \o (IF message.echoText = << >> THEN << >> ELSE message.echoText[1])
        \o (IF message.stopPx = << >> THEN << >> ELSE message.stopPx[1])
        \o (IF message.routingInst = << >> THEN << >> ELSE message.routingInst[1])
        \o (IF message.routStrategy = << >> THEN << >> ELSE message.routStrategy[1])
        \o (IF message.routeDeliveryMethod = << >> THEN << >> ELSE message.routeDeliveryMethod[1])
        \o (IF message.exDestination = << >> THEN << >> ELSE message.exDestination[1])

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
    LET returnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadBytes(returnBitfield3.rest, 1), returnBitfield3.rest) IN IF ~returnBitfield4.ok THEN Fail ELSE
    LET returnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadBytes(returnBitfield4.rest, 1), returnBitfield4.rest) IN IF ~returnBitfield5.ok THEN Fail ELSE
    LET returnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadUIntLE(returnBitfield5.rest, 1), returnBitfield5.rest) IN IF ~returnBitfield6.ok THEN Fail ELSE
    LET returnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadBytes(returnBitfield6.rest, 1), returnBitfield6.rest) IN IF ~returnBitfield7.ok THEN Fail ELSE
    LET returnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadUIntLE(returnBitfield7.rest, 1), returnBitfield7.rest) IN IF ~returnBitfield8.ok THEN Fail ELSE
    LET returnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadBytes(returnBitfield8.rest, 1), returnBitfield8.rest) IN IF ~returnBitfield9.ok THEN Fail ELSE
    LET returnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadBytes(returnBitfield9.rest, 1), returnBitfield9.rest) IN IF ~returnBitfield10.ok THEN Fail ELSE
    LET returnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadBytes(returnBitfield10.rest, 1), returnBitfield10.rest) IN IF ~returnBitfield11.ok THEN Fail ELSE
    LET returnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadBytes(returnBitfield11.rest, 1), returnBitfield11.rest) IN IF ~returnBitfield12.ok THEN Fail ELSE
    LET returnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(returnBitfield12.rest, 1), returnBitfield12.rest) IN IF ~returnBitfield13.ok THEN Fail ELSE
    LET returnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(returnBitfield13.rest, 1), returnBitfield13.rest) IN IF ~returnBitfield14.ok THEN Fail ELSE
    LET returnBitfield15 == ReadWhen(numberOfReturnBitfields.value >= 15, ReadBytes(returnBitfield14.rest, 1), returnBitfield14.rest) IN IF ~returnBitfield15.ok THEN Fail ELSE
    LET returnBitfield16 == ReadWhen(numberOfReturnBitfields.value >= 16, ReadBytes(returnBitfield15.rest, 1), returnBitfield15.rest) IN IF ~returnBitfield16.ok THEN Fail ELSE
    LET returnBitfield17 == ReadWhen(numberOfReturnBitfields.value >= 17, ReadBytes(returnBitfield16.rest, 1), returnBitfield16.rest) IN IF ~returnBitfield17.ok THEN Fail ELSE
    LET returnBitfield18 == ReadWhen(numberOfReturnBitfields.value >= 18, ReadBytes(returnBitfield17.rest, 1), returnBitfield17.rest) IN IF ~returnBitfield18.ok THEN Fail ELSE
    LET returnBitfield19 == ReadWhen(numberOfReturnBitfields.value >= 19, ReadBytes(returnBitfield18.rest, 1), returnBitfield18.rest) IN IF ~returnBitfield19.ok THEN Fail ELSE
    LET side == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ returnBitfield1.value[1] % 2 > 0), ReadBytes(returnBitfield19.rest, 1), returnBitfield19.rest) IN IF ~side.ok THEN Fail ELSE
    LET pegDifference == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 2) % 2 > 0), ReadBytes(side.rest, 8), side.rest) IN IF ~pegDifference.ok THEN Fail ELSE
    LET price == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(pegDifference.rest, 8), pegDifference.rest) IN IF ~price.ok THEN Fail ELSE
    LET execInst == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 8) % 2 > 0), ReadBytes(price.rest, 1), price.rest) IN IF ~execInst.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(execInst.rest, 1), execInst.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET symbol == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ returnBitfield2.value[1] % 2 > 0), ReadBytes(minQty.rest, 8), minQty.rest) IN IF ~symbol.ok THEN Fail ELSE
    LET symbolSfx == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ (returnBitfield2.value[1] \div 2) % 2 > 0), ReadBytes(symbol.rest, 8), symbol.rest) IN IF ~symbolSfx.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ (returnBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(symbolSfx.rest, 1), symbolSfx.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ returnBitfield3.value[1] % 2 > 0), ReadBytes(capacity.rest, 16), capacity.rest) IN IF ~account.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 2) % 2 > 0), ReadBytes(account.rest, 4), account.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 4) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET displayIndicator == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 8) % 2 > 0), ReadBytes(clearingAccount.rest, 1), clearingAccount.rest) IN IF ~displayIndicator.ok THEN Fail ELSE
    LET maxFloor == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 16) % 2 > 0), ReadBytes(displayIndicator.rest, 4), displayIndicator.rest) IN IF ~maxFloor.ok THEN Fail ELSE
    LET discretionAmount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 32) % 2 > 0), ReadBytes(maxFloor.rest, 2), maxFloor.rest) IN IF ~discretionAmount.ok THEN Fail ELSE
    LET orderQty == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 64) % 2 > 0), ReadBytes(discretionAmount.rest, 4), discretionAmount.rest) IN IF ~orderQty.ok THEN Fail ELSE
    LET preventMatch == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 128) % 2 > 0), ReadBytes(orderQty.rest, 3), orderQty.rest) IN IF ~preventMatch.ok THEN Fail ELSE
    LET secondaryOrderId == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (returnBitfield6.value # << >> /\ returnBitfield6.value[1] % 2 > 0), ReadBytes(preventMatch.rest, 8), preventMatch.rest) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET attributedQuote == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (returnBitfield6.value # << >> /\ (returnBitfield6.value[1] \div 8) % 2 > 0), ReadBytes(secondaryOrderId.rest, 1), secondaryOrderId.rest) IN IF ~attributedQuote.ok THEN Fail ELSE
    LET extExecInst == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (returnBitfield6.value # << >> /\ (returnBitfield6.value[1] \div 16) % 2 > 0), ReadBytes(attributedQuote.rest, 1), attributedQuote.rest) IN IF ~extExecInst.ok THEN Fail ELSE
    LET echoText == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 2) % 2 > 0), ReadBytes(extExecInst.rest, 64), extExecInst.rest) IN IF ~echoText.ok THEN Fail ELSE
    LET stopPx == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 4) % 2 > 0), ReadBytes(echoText.rest, 8), echoText.rest) IN IF ~stopPx.ok THEN Fail ELSE
    LET routingInst == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 8) % 2 > 0), ReadBytes(stopPx.rest, 4), stopPx.rest) IN IF ~routingInst.ok THEN Fail ELSE
    LET routStrategy == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 16) % 2 > 0), ReadBytes(routingInst.rest, 6), routingInst.rest) IN IF ~routStrategy.ok THEN Fail ELSE
    LET routeDeliveryMethod == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 32) % 2 > 0), ReadBytes(routStrategy.rest, 3), routStrategy.rest) IN IF ~routeDeliveryMethod.ok THEN Fail ELSE
    LET exDestination == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 64) % 2 > 0), ReadBytes(routeDeliveryMethod.rest, 1), routeDeliveryMethod.rest) IN IF ~exDestination.ok THEN Fail ELSE
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
         returnBitfield18        |-> returnBitfield18.value,
         returnBitfield19        |-> returnBitfield19.value,
         side                    |-> side.value,
         pegDifference           |-> pegDifference.value,
         price                   |-> price.value,
         execInst                |-> execInst.value,
         ordType                 |-> ordType.value,
         timeInForce             |-> timeInForce.value,
         minQty                  |-> minQty.value,
         symbol                  |-> symbol.value,
         symbolSfx               |-> symbolSfx.value,
         capacity                |-> capacity.value,
         account                 |-> account.value,
         clearingFirm            |-> clearingFirm.value,
         clearingAccount         |-> clearingAccount.value,
         displayIndicator        |-> displayIndicator.value,
         maxFloor                |-> maxFloor.value,
         discretionAmount        |-> discretionAmount.value,
         orderQty                |-> orderQty.value,
         preventMatch            |-> preventMatch.value,
         secondaryOrderId        |-> secondaryOrderId.value,
         attributedQuote         |-> attributedQuote.value,
         extExecInst             |-> extExecInst.value,
         echoText                |-> echoText.value,
         stopPx                  |-> stopPx.value,
         routingInst             |-> routingInst.value,
         routStrategy            |-> routStrategy.value,
         routeDeliveryMethod     |-> routeDeliveryMethod.value,
         exDestination           |-> exDestination.value ], exDestination.rest)

(* Order Rejected Message with each field marked present by fields before it there exactly where they say *)
SettleOrderRejectedMessage(message) ==
    LET settled1 == [message EXCEPT !.returnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.returnBitfield1 = << >> THEN <<0>> ELSE message.returnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.returnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.returnBitfield2 = << >> THEN <<0>> ELSE settled1.returnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.returnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.returnBitfield3 = << >> THEN <<0>> ELSE settled2.returnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.returnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.returnBitfield4 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled3.returnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.returnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.returnBitfield5 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled4.returnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.returnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.returnBitfield6 = << >> THEN <<0>> ELSE settled5.returnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.returnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.returnBitfield7 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.returnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.returnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.returnBitfield8 = << >> THEN <<0>> ELSE settled7.returnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.returnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.returnBitfield9 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled8.returnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.returnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.returnBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.returnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.returnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.returnBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.returnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.returnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.returnBitfield12 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.returnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.returnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.returnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.returnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.returnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.returnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.returnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.returnBitfield15 = IF settled14.numberOfReturnBitfields >= 15 THEN (IF settled14.returnBitfield15 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.returnBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.returnBitfield16 = IF settled15.numberOfReturnBitfields >= 16 THEN (IF settled15.returnBitfield16 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled15.returnBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.returnBitfield17 = IF settled16.numberOfReturnBitfields >= 17 THEN (IF settled16.returnBitfield17 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled16.returnBitfield17) ELSE << >>]
        settled18 == [settled17 EXCEPT !.returnBitfield18 = IF settled17.numberOfReturnBitfields >= 18 THEN (IF settled17.returnBitfield18 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.returnBitfield18) ELSE << >>]
        settled19 == [settled18 EXCEPT !.returnBitfield19 = IF settled18.numberOfReturnBitfields >= 19 THEN (IF settled18.returnBitfield19 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled18.returnBitfield19) ELSE << >>]
        settled20 == [settled19 EXCEPT !.side = IF settled19.numberOfReturnBitfields >= 1 /\ (settled19.returnBitfield1 # << >> /\ settled19.returnBitfield1[1] % 2 > 0) THEN (IF settled19.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled19.side) ELSE << >>]
        settled21 == [settled20 EXCEPT !.pegDifference = IF settled20.numberOfReturnBitfields >= 1 /\ (settled20.returnBitfield1 # << >> /\ (settled20.returnBitfield1[1] \div 2) % 2 > 0) THEN (IF settled20.pegDifference = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled20.pegDifference) ELSE << >>]
        settled22 == [settled21 EXCEPT !.price = IF settled21.numberOfReturnBitfields >= 1 /\ (settled21.returnBitfield1 # << >> /\ (settled21.returnBitfield1[1] \div 4) % 2 > 0) THEN (IF settled21.price = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled21.price) ELSE << >>]
        settled23 == [settled22 EXCEPT !.execInst = IF settled22.numberOfReturnBitfields >= 1 /\ (settled22.returnBitfield1 # << >> /\ (settled22.returnBitfield1[1] \div 8) % 2 > 0) THEN (IF settled22.execInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled22.execInst) ELSE << >>]
        settled24 == [settled23 EXCEPT !.ordType = IF settled23.numberOfReturnBitfields >= 1 /\ (settled23.returnBitfield1 # << >> /\ (settled23.returnBitfield1[1] \div 16) % 2 > 0) THEN (IF settled23.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled23.ordType) ELSE << >>]
        settled25 == [settled24 EXCEPT !.timeInForce = IF settled24.numberOfReturnBitfields >= 1 /\ (settled24.returnBitfield1 # << >> /\ (settled24.returnBitfield1[1] \div 32) % 2 > 0) THEN (IF settled24.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled24.timeInForce) ELSE << >>]
        settled26 == [settled25 EXCEPT !.minQty = IF settled25.numberOfReturnBitfields >= 1 /\ (settled25.returnBitfield1 # << >> /\ (settled25.returnBitfield1[1] \div 64) % 2 > 0) THEN (IF settled25.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled25.minQty) ELSE << >>]
        settled27 == [settled26 EXCEPT !.symbol = IF settled26.numberOfReturnBitfields >= 2 /\ (settled26.returnBitfield2 # << >> /\ settled26.returnBitfield2[1] % 2 > 0) THEN (IF settled26.symbol = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled26.symbol) ELSE << >>]
        settled28 == [settled27 EXCEPT !.symbolSfx = IF settled27.numberOfReturnBitfields >= 2 /\ (settled27.returnBitfield2 # << >> /\ (settled27.returnBitfield2[1] \div 2) % 2 > 0) THEN (IF settled27.symbolSfx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled27.symbolSfx) ELSE << >>]
        settled29 == [settled28 EXCEPT !.capacity = IF settled28.numberOfReturnBitfields >= 2 /\ (settled28.returnBitfield2 # << >> /\ (settled28.returnBitfield2[1] \div 64) % 2 > 0) THEN (IF settled28.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled28.capacity) ELSE << >>]
        settled30 == [settled29 EXCEPT !.account = IF settled29.numberOfReturnBitfields >= 3 /\ (settled29.returnBitfield3 # << >> /\ settled29.returnBitfield3[1] % 2 > 0) THEN (IF settled29.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled29.account) ELSE << >>]
        settled31 == [settled30 EXCEPT !.clearingFirm = IF settled30.numberOfReturnBitfields >= 3 /\ (settled30.returnBitfield3 # << >> /\ (settled30.returnBitfield3[1] \div 2) % 2 > 0) THEN (IF settled30.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled30.clearingFirm) ELSE << >>]
        settled32 == [settled31 EXCEPT !.clearingAccount = IF settled31.numberOfReturnBitfields >= 3 /\ (settled31.returnBitfield3 # << >> /\ (settled31.returnBitfield3[1] \div 4) % 2 > 0) THEN (IF settled31.clearingAccount = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled31.clearingAccount) ELSE << >>]
        settled33 == [settled32 EXCEPT !.displayIndicator = IF settled32.numberOfReturnBitfields >= 3 /\ (settled32.returnBitfield3 # << >> /\ (settled32.returnBitfield3[1] \div 8) % 2 > 0) THEN (IF settled32.displayIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled32.displayIndicator) ELSE << >>]
        settled34 == [settled33 EXCEPT !.maxFloor = IF settled33.numberOfReturnBitfields >= 3 /\ (settled33.returnBitfield3 # << >> /\ (settled33.returnBitfield3[1] \div 16) % 2 > 0) THEN (IF settled33.maxFloor = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled33.maxFloor) ELSE << >>]
        settled35 == [settled34 EXCEPT !.discretionAmount = IF settled34.numberOfReturnBitfields >= 3 /\ (settled34.returnBitfield3 # << >> /\ (settled34.returnBitfield3[1] \div 32) % 2 > 0) THEN (IF settled34.discretionAmount = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled34.discretionAmount) ELSE << >>]
        settled36 == [settled35 EXCEPT !.orderQty = IF settled35.numberOfReturnBitfields >= 3 /\ (settled35.returnBitfield3 # << >> /\ (settled35.returnBitfield3[1] \div 64) % 2 > 0) THEN (IF settled35.orderQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled35.orderQty) ELSE << >>]
        settled37 == [settled36 EXCEPT !.preventMatch = IF settled36.numberOfReturnBitfields >= 3 /\ (settled36.returnBitfield3 # << >> /\ (settled36.returnBitfield3[1] \div 128) % 2 > 0) THEN (IF settled36.preventMatch = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled36.preventMatch) ELSE << >>]
        settled38 == [settled37 EXCEPT !.secondaryOrderId = IF settled37.numberOfReturnBitfields >= 6 /\ (settled37.returnBitfield6 # << >> /\ settled37.returnBitfield6[1] % 2 > 0) THEN (IF settled37.secondaryOrderId = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled37.secondaryOrderId) ELSE << >>]
        settled39 == [settled38 EXCEPT !.attributedQuote = IF settled38.numberOfReturnBitfields >= 6 /\ (settled38.returnBitfield6 # << >> /\ (settled38.returnBitfield6[1] \div 8) % 2 > 0) THEN (IF settled38.attributedQuote = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled38.attributedQuote) ELSE << >>]
        settled40 == [settled39 EXCEPT !.extExecInst = IF settled39.numberOfReturnBitfields >= 6 /\ (settled39.returnBitfield6 # << >> /\ (settled39.returnBitfield6[1] \div 16) % 2 > 0) THEN (IF settled39.extExecInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled39.extExecInst) ELSE << >>]
        settled41 == [settled40 EXCEPT !.echoText = IF settled40.numberOfReturnBitfields >= 8 /\ (settled40.returnBitfield8 # << >> /\ (settled40.returnBitfield8[1] \div 2) % 2 > 0) THEN (IF settled40.echoText = << >> THEN <<[i \in 1 .. 64 |-> 0]>> ELSE settled40.echoText) ELSE << >>]
        settled42 == [settled41 EXCEPT !.stopPx = IF settled41.numberOfReturnBitfields >= 8 /\ (settled41.returnBitfield8 # << >> /\ (settled41.returnBitfield8[1] \div 4) % 2 > 0) THEN (IF settled41.stopPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled41.stopPx) ELSE << >>]
        settled43 == [settled42 EXCEPT !.routingInst = IF settled42.numberOfReturnBitfields >= 8 /\ (settled42.returnBitfield8 # << >> /\ (settled42.returnBitfield8[1] \div 8) % 2 > 0) THEN (IF settled42.routingInst = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled42.routingInst) ELSE << >>]
        settled44 == [settled43 EXCEPT !.routStrategy = IF settled43.numberOfReturnBitfields >= 8 /\ (settled43.returnBitfield8 # << >> /\ (settled43.returnBitfield8[1] \div 16) % 2 > 0) THEN (IF settled43.routStrategy = << >> THEN <<[i \in 1 .. 6 |-> 0]>> ELSE settled43.routStrategy) ELSE << >>]
        settled45 == [settled44 EXCEPT !.routeDeliveryMethod = IF settled44.numberOfReturnBitfields >= 8 /\ (settled44.returnBitfield8 # << >> /\ (settled44.returnBitfield8[1] \div 32) % 2 > 0) THEN (IF settled44.routeDeliveryMethod = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled44.routeDeliveryMethod) ELSE << >>]
        settled46 == [settled45 EXCEPT !.exDestination = IF settled45.numberOfReturnBitfields >= 8 /\ (settled45.returnBitfield8 # << >> /\ (settled45.returnBitfield8[1] \div 64) % 2 > 0) THEN (IF settled45.exDestination = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled45.exDestination) ELSE << >>]
    IN  settled46

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
                                 returnBitfield18        |-> << >>,
                                 returnBitfield19        |-> << >>,
                                 side                    |-> << >>,
                                 pegDifference           |-> << >>,
                                 price                   |-> << >>,
                                 execInst                |-> << >>,
                                 ordType                 |-> << >>,
                                 timeInForce             |-> << >>,
                                 minQty                  |-> << >>,
                                 symbol                  |-> << >>,
                                 symbolSfx               |-> << >>,
                                 capacity                |-> << >>,
                                 account                 |-> << >>,
                                 clearingFirm            |-> << >>,
                                 clearingAccount         |-> << >>,
                                 displayIndicator        |-> << >>,
                                 maxFloor                |-> << >>,
                                 discretionAmount        |-> << >>,
                                 orderQty                |-> << >>,
                                 preventMatch            |-> << >>,
                                 secondaryOrderId        |-> << >>,
                                 attributedQuote         |-> << >>,
                                 extExecInst             |-> << >>,
                                 echoText                |-> << >>,
                                 stopPx                  |-> << >>,
                                 routingInst             |-> << >>,
                                 routStrategy            |-> << >>,
                                 routeDeliveryMethod     |-> << >>,
                                 exDestination           |-> << >> ])

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
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 7, !.returnBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 9, !.returnBitfield9 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 10, !.returnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 11, !.returnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 13, !.returnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 14, !.returnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 15, !.returnBitfield15 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 17, !.returnBitfield17 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 18, !.returnBitfield18 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 19, !.returnBitfield19 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<1>>, !.side = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<2>>, !.pegDifference = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<4>>, !.price = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<8>>, !.execInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<1>>, !.symbol = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<2>>, !.symbolSfx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<1>>, !.account = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<2>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<4>>, !.clearingAccount = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<8>>, !.displayIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<16>>, !.maxFloor = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<32>>, !.discretionAmount = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<64>>, !.orderQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<128>>, !.preventMatch = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = <<1>>, !.secondaryOrderId = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = <<8>>, !.attributedQuote = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = <<16>>, !.extExecInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<2>>, !.echoText = one]) : one \in { <<held>> : held \in Sample(64) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<4>>, !.stopPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<8>>, !.routingInst = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<16>>, !.routStrategy = one]) : one \in { <<held>> : held \in Sample(6) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<32>>, !.routeDeliveryMethod = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<64>>, !.exDestination = one]) : one \in { <<held>> : held \in Sample(1) } }

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
      returnBitfield9         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield10        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield11        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield12        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield13        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield14        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield15        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield16        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield17        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield18        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield19        : { << >> } \cup { <<held>> : held \in Sample(1) },
      side                    : { << >> } \cup { <<held>> : held \in Sample(1) },
      pegDifference           : { << >> } \cup { <<held>> : held \in Sample(8) },
      price                   : { << >> } \cup { <<held>> : held \in Sample(8) },
      execInst                : { << >> } \cup { <<held>> : held \in Sample(1) },
      ordType                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce             : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                  : { << >> } \cup { <<held>> : held \in Sample(4) },
      symbol                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      symbolSfx               : { << >> } \cup { <<held>> : held \in Sample(8) },
      account                 : { << >> } \cup { <<held>> : held \in Sample(16) },
      clearingFirm            : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingAccount         : { << >> } \cup { <<held>> : held \in Sample(4) },
      displayIndicator        : { << >> } \cup { <<held>> : held \in Sample(1) },
      maxFloor                : { << >> } \cup { <<held>> : held \in Sample(4) },
      discretionAmount        : { << >> } \cup { <<held>> : held \in Sample(2) },
      orderQty                : { << >> } \cup { <<held>> : held \in Sample(4) },
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
      attributedQuote         : { << >> } \cup { <<held>> : held \in Sample(1) },
      extExecInst             : { << >> } \cup { <<held>> : held \in Sample(1) },
      echoText                : { << >> } \cup { <<held>> : held \in Sample(64) },
      stopPx                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      routingInst             : { << >> } \cup { <<held>> : held \in Sample(4) },
      routStrategy            : { << >> } \cup { <<held>> : held \in Sample(6) },
      routeDeliveryMethod     : { << >> } \cup { <<held>> : held \in Sample(3) },
      exDestination           : { << >> } \cup { <<held>> : held \in Sample(1) },
      crossTradeFlag          : { << >> } \cup { <<held>> : held \in Sample(1) },
      locateBroker            : { << >> } \cup { <<held>> : held \in Sample(4) } ]

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
        \o (IF message.returnBitfield9 = << >> THEN << >> ELSE message.returnBitfield9[1])
        \o (IF message.returnBitfield10 = << >> THEN << >> ELSE message.returnBitfield10[1])
        \o (IF message.returnBitfield11 = << >> THEN << >> ELSE message.returnBitfield11[1])
        \o (IF message.returnBitfield12 = << >> THEN << >> ELSE message.returnBitfield12[1])
        \o (IF message.returnBitfield13 = << >> THEN << >> ELSE message.returnBitfield13[1])
        \o (IF message.returnBitfield14 = << >> THEN << >> ELSE message.returnBitfield14[1])
        \o (IF message.returnBitfield15 = << >> THEN << >> ELSE message.returnBitfield15[1])
        \o (IF message.returnBitfield16 = << >> THEN << >> ELSE message.returnBitfield16[1])
        \o (IF message.returnBitfield17 = << >> THEN << >> ELSE message.returnBitfield17[1])
        \o (IF message.returnBitfield18 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield18[1], 1))
        \o (IF message.returnBitfield19 = << >> THEN << >> ELSE message.returnBitfield19[1])
        \o (IF message.side = << >> THEN << >> ELSE message.side[1])
        \o (IF message.pegDifference = << >> THEN << >> ELSE message.pegDifference[1])
        \o (IF message.price = << >> THEN << >> ELSE message.price[1])
        \o (IF message.execInst = << >> THEN << >> ELSE message.execInst[1])
        \o (IF message.ordType = << >> THEN << >> ELSE message.ordType[1])
        \o (IF message.timeInForce = << >> THEN << >> ELSE message.timeInForce[1])
        \o (IF message.minQty = << >> THEN << >> ELSE message.minQty[1])
        \o (IF message.symbol = << >> THEN << >> ELSE message.symbol[1])
        \o (IF message.symbolSfx = << >> THEN << >> ELSE message.symbolSfx[1])
        \o (IF message.account = << >> THEN << >> ELSE message.account[1])
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])
        \o (IF message.clearingAccount = << >> THEN << >> ELSE message.clearingAccount[1])
        \o (IF message.displayIndicator = << >> THEN << >> ELSE message.displayIndicator[1])
        \o (IF message.maxFloor = << >> THEN << >> ELSE message.maxFloor[1])
        \o (IF message.discretionAmount = << >> THEN << >> ELSE message.discretionAmount[1])
        \o (IF message.orderQty = << >> THEN << >> ELSE message.orderQty[1])
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
        \o (IF message.attributedQuote = << >> THEN << >> ELSE message.attributedQuote[1])
        \o (IF message.extExecInst = << >> THEN << >> ELSE message.extExecInst[1])
        \o (IF message.echoText = << >> THEN << >> ELSE message.echoText[1])
        \o (IF message.stopPx = << >> THEN << >> ELSE message.stopPx[1])
        \o (IF message.routingInst = << >> THEN << >> ELSE message.routingInst[1])
        \o (IF message.routStrategy = << >> THEN << >> ELSE message.routStrategy[1])
        \o (IF message.routeDeliveryMethod = << >> THEN << >> ELSE message.routeDeliveryMethod[1])
        \o (IF message.exDestination = << >> THEN << >> ELSE message.exDestination[1])
        \o (IF message.crossTradeFlag = << >> THEN << >> ELSE message.crossTradeFlag[1])
        \o (IF message.locateBroker = << >> THEN << >> ELSE message.locateBroker[1])

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
    LET returnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadBytes(returnBitfield8.rest, 1), returnBitfield8.rest) IN IF ~returnBitfield9.ok THEN Fail ELSE
    LET returnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadBytes(returnBitfield9.rest, 1), returnBitfield9.rest) IN IF ~returnBitfield10.ok THEN Fail ELSE
    LET returnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadBytes(returnBitfield10.rest, 1), returnBitfield10.rest) IN IF ~returnBitfield11.ok THEN Fail ELSE
    LET returnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadBytes(returnBitfield11.rest, 1), returnBitfield11.rest) IN IF ~returnBitfield12.ok THEN Fail ELSE
    LET returnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(returnBitfield12.rest, 1), returnBitfield12.rest) IN IF ~returnBitfield13.ok THEN Fail ELSE
    LET returnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(returnBitfield13.rest, 1), returnBitfield13.rest) IN IF ~returnBitfield14.ok THEN Fail ELSE
    LET returnBitfield15 == ReadWhen(numberOfReturnBitfields.value >= 15, ReadBytes(returnBitfield14.rest, 1), returnBitfield14.rest) IN IF ~returnBitfield15.ok THEN Fail ELSE
    LET returnBitfield16 == ReadWhen(numberOfReturnBitfields.value >= 16, ReadBytes(returnBitfield15.rest, 1), returnBitfield15.rest) IN IF ~returnBitfield16.ok THEN Fail ELSE
    LET returnBitfield17 == ReadWhen(numberOfReturnBitfields.value >= 17, ReadBytes(returnBitfield16.rest, 1), returnBitfield16.rest) IN IF ~returnBitfield17.ok THEN Fail ELSE
    LET returnBitfield18 == ReadWhen(numberOfReturnBitfields.value >= 18, ReadUIntLE(returnBitfield17.rest, 1), returnBitfield17.rest) IN IF ~returnBitfield18.ok THEN Fail ELSE
    LET returnBitfield19 == ReadWhen(numberOfReturnBitfields.value >= 19, ReadBytes(returnBitfield18.rest, 1), returnBitfield18.rest) IN IF ~returnBitfield19.ok THEN Fail ELSE
    LET side == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ returnBitfield1.value[1] % 2 > 0), ReadBytes(returnBitfield19.rest, 1), returnBitfield19.rest) IN IF ~side.ok THEN Fail ELSE
    LET pegDifference == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 2) % 2 > 0), ReadBytes(side.rest, 8), side.rest) IN IF ~pegDifference.ok THEN Fail ELSE
    LET price == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(pegDifference.rest, 8), pegDifference.rest) IN IF ~price.ok THEN Fail ELSE
    LET execInst == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 8) % 2 > 0), ReadBytes(price.rest, 1), price.rest) IN IF ~execInst.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(execInst.rest, 1), execInst.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET symbol == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ returnBitfield2.value[1] % 2 > 0), ReadBytes(minQty.rest, 8), minQty.rest) IN IF ~symbol.ok THEN Fail ELSE
    LET symbolSfx == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ (returnBitfield2.value[1] \div 2) % 2 > 0), ReadBytes(symbol.rest, 8), symbol.rest) IN IF ~symbolSfx.ok THEN Fail ELSE
    LET account == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ returnBitfield3.value[1] % 2 > 0), ReadBytes(symbolSfx.rest, 16), symbolSfx.rest) IN IF ~account.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 2) % 2 > 0), ReadBytes(account.rest, 4), account.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 4) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET displayIndicator == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 8) % 2 > 0), ReadBytes(clearingAccount.rest, 1), clearingAccount.rest) IN IF ~displayIndicator.ok THEN Fail ELSE
    LET maxFloor == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 16) % 2 > 0), ReadBytes(displayIndicator.rest, 4), displayIndicator.rest) IN IF ~maxFloor.ok THEN Fail ELSE
    LET discretionAmount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 32) % 2 > 0), ReadBytes(maxFloor.rest, 2), maxFloor.rest) IN IF ~discretionAmount.ok THEN Fail ELSE
    LET orderQty == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 64) % 2 > 0), ReadBytes(discretionAmount.rest, 4), discretionAmount.rest) IN IF ~orderQty.ok THEN Fail ELSE
    LET preventMatch == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 128) % 2 > 0), ReadBytes(orderQty.rest, 3), orderQty.rest) IN IF ~preventMatch.ok THEN Fail ELSE
    LET origClOrdId == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ returnBitfield5.value[1] % 2 > 0), ReadBytes(preventMatch.rest, 20), preventMatch.rest) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET leavesQty == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 2) % 2 > 0), ReadBytes(origClOrdId.rest, 4), origClOrdId.rest) IN IF ~leavesQty.ok THEN Fail ELSE
    LET lastShares == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 4) % 2 > 0), ReadBytes(leavesQty.rest, 4), leavesQty.rest) IN IF ~lastShares.ok THEN Fail ELSE
    LET lastPx == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 8) % 2 > 0), ReadBytes(lastShares.rest, 8), lastShares.rest) IN IF ~lastPx.ok THEN Fail ELSE
    LET displayPrice == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 16) % 2 > 0), ReadBytes(lastPx.rest, 8), lastPx.rest) IN IF ~displayPrice.ok THEN Fail ELSE
    LET workingPrice == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 32) % 2 > 0), ReadBytes(displayPrice.rest, 8), displayPrice.rest) IN IF ~workingPrice.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 64) % 2 > 0), ReadBytes(workingPrice.rest, 1), workingPrice.rest) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET expireTime == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 128) % 2 > 0), ReadBytes(baseLiquidityIndicator.rest, 8), baseLiquidityIndicator.rest) IN IF ~expireTime.ok THEN Fail ELSE
    LET secondaryOrderId == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (returnBitfield6.value # << >> /\ returnBitfield6.value[1] % 2 > 0), ReadBytes(expireTime.rest, 8), expireTime.rest) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET attributedQuote == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (returnBitfield6.value # << >> /\ (returnBitfield6.value[1] \div 8) % 2 > 0), ReadBytes(secondaryOrderId.rest, 1), secondaryOrderId.rest) IN IF ~attributedQuote.ok THEN Fail ELSE
    LET extExecInst == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (returnBitfield6.value # << >> /\ (returnBitfield6.value[1] \div 16) % 2 > 0), ReadBytes(attributedQuote.rest, 1), attributedQuote.rest) IN IF ~extExecInst.ok THEN Fail ELSE
    LET echoText == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 2) % 2 > 0), ReadBytes(extExecInst.rest, 64), extExecInst.rest) IN IF ~echoText.ok THEN Fail ELSE
    LET stopPx == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 4) % 2 > 0), ReadBytes(echoText.rest, 8), echoText.rest) IN IF ~stopPx.ok THEN Fail ELSE
    LET routingInst == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 8) % 2 > 0), ReadBytes(stopPx.rest, 4), stopPx.rest) IN IF ~routingInst.ok THEN Fail ELSE
    LET routStrategy == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 16) % 2 > 0), ReadBytes(routingInst.rest, 6), routingInst.rest) IN IF ~routStrategy.ok THEN Fail ELSE
    LET routeDeliveryMethod == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 32) % 2 > 0), ReadBytes(routStrategy.rest, 3), routStrategy.rest) IN IF ~routeDeliveryMethod.ok THEN Fail ELSE
    LET exDestination == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 64) % 2 > 0), ReadBytes(routeDeliveryMethod.rest, 1), routeDeliveryMethod.rest) IN IF ~exDestination.ok THEN Fail ELSE
    LET crossTradeFlag == ReadWhen(numberOfReturnBitfields.value >= 18 /\ (returnBitfield18.value # << >> /\ (returnBitfield18.value[1] \div 8) % 2 > 0), ReadBytes(exDestination.rest, 1), exDestination.rest) IN IF ~crossTradeFlag.ok THEN Fail ELSE
    LET locateBroker == ReadWhen(numberOfReturnBitfields.value >= 18 /\ (returnBitfield18.value # << >> /\ (returnBitfield18.value[1] \div 64) % 2 > 0), ReadBytes(crossTradeFlag.rest, 4), crossTradeFlag.rest) IN IF ~locateBroker.ok THEN Fail ELSE
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
         returnBitfield18        |-> returnBitfield18.value,
         returnBitfield19        |-> returnBitfield19.value,
         side                    |-> side.value,
         pegDifference           |-> pegDifference.value,
         price                   |-> price.value,
         execInst                |-> execInst.value,
         ordType                 |-> ordType.value,
         timeInForce             |-> timeInForce.value,
         minQty                  |-> minQty.value,
         symbol                  |-> symbol.value,
         symbolSfx               |-> symbolSfx.value,
         account                 |-> account.value,
         clearingFirm            |-> clearingFirm.value,
         clearingAccount         |-> clearingAccount.value,
         displayIndicator        |-> displayIndicator.value,
         maxFloor                |-> maxFloor.value,
         discretionAmount        |-> discretionAmount.value,
         orderQty                |-> orderQty.value,
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
         attributedQuote         |-> attributedQuote.value,
         extExecInst             |-> extExecInst.value,
         echoText                |-> echoText.value,
         stopPx                  |-> stopPx.value,
         routingInst             |-> routingInst.value,
         routStrategy            |-> routStrategy.value,
         routeDeliveryMethod     |-> routeDeliveryMethod.value,
         exDestination           |-> exDestination.value,
         crossTradeFlag          |-> crossTradeFlag.value,
         locateBroker            |-> locateBroker.value ], locateBroker.rest)

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
        settled9 == [settled8 EXCEPT !.returnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.returnBitfield9 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled8.returnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.returnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.returnBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.returnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.returnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.returnBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.returnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.returnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.returnBitfield12 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.returnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.returnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.returnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.returnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.returnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.returnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.returnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.returnBitfield15 = IF settled14.numberOfReturnBitfields >= 15 THEN (IF settled14.returnBitfield15 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.returnBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.returnBitfield16 = IF settled15.numberOfReturnBitfields >= 16 THEN (IF settled15.returnBitfield16 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled15.returnBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.returnBitfield17 = IF settled16.numberOfReturnBitfields >= 17 THEN (IF settled16.returnBitfield17 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled16.returnBitfield17) ELSE << >>]
        settled18 == [settled17 EXCEPT !.returnBitfield18 = IF settled17.numberOfReturnBitfields >= 18 THEN (IF settled17.returnBitfield18 = << >> THEN <<0>> ELSE settled17.returnBitfield18) ELSE << >>]
        settled19 == [settled18 EXCEPT !.returnBitfield19 = IF settled18.numberOfReturnBitfields >= 19 THEN (IF settled18.returnBitfield19 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled18.returnBitfield19) ELSE << >>]
        settled20 == [settled19 EXCEPT !.side = IF settled19.numberOfReturnBitfields >= 1 /\ (settled19.returnBitfield1 # << >> /\ settled19.returnBitfield1[1] % 2 > 0) THEN (IF settled19.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled19.side) ELSE << >>]
        settled21 == [settled20 EXCEPT !.pegDifference = IF settled20.numberOfReturnBitfields >= 1 /\ (settled20.returnBitfield1 # << >> /\ (settled20.returnBitfield1[1] \div 2) % 2 > 0) THEN (IF settled20.pegDifference = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled20.pegDifference) ELSE << >>]
        settled22 == [settled21 EXCEPT !.price = IF settled21.numberOfReturnBitfields >= 1 /\ (settled21.returnBitfield1 # << >> /\ (settled21.returnBitfield1[1] \div 4) % 2 > 0) THEN (IF settled21.price = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled21.price) ELSE << >>]
        settled23 == [settled22 EXCEPT !.execInst = IF settled22.numberOfReturnBitfields >= 1 /\ (settled22.returnBitfield1 # << >> /\ (settled22.returnBitfield1[1] \div 8) % 2 > 0) THEN (IF settled22.execInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled22.execInst) ELSE << >>]
        settled24 == [settled23 EXCEPT !.ordType = IF settled23.numberOfReturnBitfields >= 1 /\ (settled23.returnBitfield1 # << >> /\ (settled23.returnBitfield1[1] \div 16) % 2 > 0) THEN (IF settled23.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled23.ordType) ELSE << >>]
        settled25 == [settled24 EXCEPT !.timeInForce = IF settled24.numberOfReturnBitfields >= 1 /\ (settled24.returnBitfield1 # << >> /\ (settled24.returnBitfield1[1] \div 32) % 2 > 0) THEN (IF settled24.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled24.timeInForce) ELSE << >>]
        settled26 == [settled25 EXCEPT !.minQty = IF settled25.numberOfReturnBitfields >= 1 /\ (settled25.returnBitfield1 # << >> /\ (settled25.returnBitfield1[1] \div 64) % 2 > 0) THEN (IF settled25.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled25.minQty) ELSE << >>]
        settled27 == [settled26 EXCEPT !.symbol = IF settled26.numberOfReturnBitfields >= 2 /\ (settled26.returnBitfield2 # << >> /\ settled26.returnBitfield2[1] % 2 > 0) THEN (IF settled26.symbol = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled26.symbol) ELSE << >>]
        settled28 == [settled27 EXCEPT !.symbolSfx = IF settled27.numberOfReturnBitfields >= 2 /\ (settled27.returnBitfield2 # << >> /\ (settled27.returnBitfield2[1] \div 2) % 2 > 0) THEN (IF settled27.symbolSfx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled27.symbolSfx) ELSE << >>]
        settled29 == [settled28 EXCEPT !.account = IF settled28.numberOfReturnBitfields >= 3 /\ (settled28.returnBitfield3 # << >> /\ settled28.returnBitfield3[1] % 2 > 0) THEN (IF settled28.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled28.account) ELSE << >>]
        settled30 == [settled29 EXCEPT !.clearingFirm = IF settled29.numberOfReturnBitfields >= 3 /\ (settled29.returnBitfield3 # << >> /\ (settled29.returnBitfield3[1] \div 2) % 2 > 0) THEN (IF settled29.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled29.clearingFirm) ELSE << >>]
        settled31 == [settled30 EXCEPT !.clearingAccount = IF settled30.numberOfReturnBitfields >= 3 /\ (settled30.returnBitfield3 # << >> /\ (settled30.returnBitfield3[1] \div 4) % 2 > 0) THEN (IF settled30.clearingAccount = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled30.clearingAccount) ELSE << >>]
        settled32 == [settled31 EXCEPT !.displayIndicator = IF settled31.numberOfReturnBitfields >= 3 /\ (settled31.returnBitfield3 # << >> /\ (settled31.returnBitfield3[1] \div 8) % 2 > 0) THEN (IF settled31.displayIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled31.displayIndicator) ELSE << >>]
        settled33 == [settled32 EXCEPT !.maxFloor = IF settled32.numberOfReturnBitfields >= 3 /\ (settled32.returnBitfield3 # << >> /\ (settled32.returnBitfield3[1] \div 16) % 2 > 0) THEN (IF settled32.maxFloor = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled32.maxFloor) ELSE << >>]
        settled34 == [settled33 EXCEPT !.discretionAmount = IF settled33.numberOfReturnBitfields >= 3 /\ (settled33.returnBitfield3 # << >> /\ (settled33.returnBitfield3[1] \div 32) % 2 > 0) THEN (IF settled33.discretionAmount = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled33.discretionAmount) ELSE << >>]
        settled35 == [settled34 EXCEPT !.orderQty = IF settled34.numberOfReturnBitfields >= 3 /\ (settled34.returnBitfield3 # << >> /\ (settled34.returnBitfield3[1] \div 64) % 2 > 0) THEN (IF settled34.orderQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled34.orderQty) ELSE << >>]
        settled36 == [settled35 EXCEPT !.preventMatch = IF settled35.numberOfReturnBitfields >= 3 /\ (settled35.returnBitfield3 # << >> /\ (settled35.returnBitfield3[1] \div 128) % 2 > 0) THEN (IF settled35.preventMatch = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled35.preventMatch) ELSE << >>]
        settled37 == [settled36 EXCEPT !.origClOrdId = IF settled36.numberOfReturnBitfields >= 5 /\ (settled36.returnBitfield5 # << >> /\ settled36.returnBitfield5[1] % 2 > 0) THEN (IF settled36.origClOrdId = << >> THEN <<[i \in 1 .. 20 |-> 0]>> ELSE settled36.origClOrdId) ELSE << >>]
        settled38 == [settled37 EXCEPT !.leavesQty = IF settled37.numberOfReturnBitfields >= 5 /\ (settled37.returnBitfield5 # << >> /\ (settled37.returnBitfield5[1] \div 2) % 2 > 0) THEN (IF settled37.leavesQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled37.leavesQty) ELSE << >>]
        settled39 == [settled38 EXCEPT !.lastShares = IF settled38.numberOfReturnBitfields >= 5 /\ (settled38.returnBitfield5 # << >> /\ (settled38.returnBitfield5[1] \div 4) % 2 > 0) THEN (IF settled38.lastShares = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled38.lastShares) ELSE << >>]
        settled40 == [settled39 EXCEPT !.lastPx = IF settled39.numberOfReturnBitfields >= 5 /\ (settled39.returnBitfield5 # << >> /\ (settled39.returnBitfield5[1] \div 8) % 2 > 0) THEN (IF settled39.lastPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled39.lastPx) ELSE << >>]
        settled41 == [settled40 EXCEPT !.displayPrice = IF settled40.numberOfReturnBitfields >= 5 /\ (settled40.returnBitfield5 # << >> /\ (settled40.returnBitfield5[1] \div 16) % 2 > 0) THEN (IF settled40.displayPrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled40.displayPrice) ELSE << >>]
        settled42 == [settled41 EXCEPT !.workingPrice = IF settled41.numberOfReturnBitfields >= 5 /\ (settled41.returnBitfield5 # << >> /\ (settled41.returnBitfield5[1] \div 32) % 2 > 0) THEN (IF settled41.workingPrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled41.workingPrice) ELSE << >>]
        settled43 == [settled42 EXCEPT !.baseLiquidityIndicator = IF settled42.numberOfReturnBitfields >= 5 /\ (settled42.returnBitfield5 # << >> /\ (settled42.returnBitfield5[1] \div 64) % 2 > 0) THEN (IF settled42.baseLiquidityIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled42.baseLiquidityIndicator) ELSE << >>]
        settled44 == [settled43 EXCEPT !.expireTime = IF settled43.numberOfReturnBitfields >= 5 /\ (settled43.returnBitfield5 # << >> /\ (settled43.returnBitfield5[1] \div 128) % 2 > 0) THEN (IF settled43.expireTime = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled43.expireTime) ELSE << >>]
        settled45 == [settled44 EXCEPT !.secondaryOrderId = IF settled44.numberOfReturnBitfields >= 6 /\ (settled44.returnBitfield6 # << >> /\ settled44.returnBitfield6[1] % 2 > 0) THEN (IF settled44.secondaryOrderId = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled44.secondaryOrderId) ELSE << >>]
        settled46 == [settled45 EXCEPT !.attributedQuote = IF settled45.numberOfReturnBitfields >= 6 /\ (settled45.returnBitfield6 # << >> /\ (settled45.returnBitfield6[1] \div 8) % 2 > 0) THEN (IF settled45.attributedQuote = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled45.attributedQuote) ELSE << >>]
        settled47 == [settled46 EXCEPT !.extExecInst = IF settled46.numberOfReturnBitfields >= 6 /\ (settled46.returnBitfield6 # << >> /\ (settled46.returnBitfield6[1] \div 16) % 2 > 0) THEN (IF settled46.extExecInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled46.extExecInst) ELSE << >>]
        settled48 == [settled47 EXCEPT !.echoText = IF settled47.numberOfReturnBitfields >= 8 /\ (settled47.returnBitfield8 # << >> /\ (settled47.returnBitfield8[1] \div 2) % 2 > 0) THEN (IF settled47.echoText = << >> THEN <<[i \in 1 .. 64 |-> 0]>> ELSE settled47.echoText) ELSE << >>]
        settled49 == [settled48 EXCEPT !.stopPx = IF settled48.numberOfReturnBitfields >= 8 /\ (settled48.returnBitfield8 # << >> /\ (settled48.returnBitfield8[1] \div 4) % 2 > 0) THEN (IF settled48.stopPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled48.stopPx) ELSE << >>]
        settled50 == [settled49 EXCEPT !.routingInst = IF settled49.numberOfReturnBitfields >= 8 /\ (settled49.returnBitfield8 # << >> /\ (settled49.returnBitfield8[1] \div 8) % 2 > 0) THEN (IF settled49.routingInst = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled49.routingInst) ELSE << >>]
        settled51 == [settled50 EXCEPT !.routStrategy = IF settled50.numberOfReturnBitfields >= 8 /\ (settled50.returnBitfield8 # << >> /\ (settled50.returnBitfield8[1] \div 16) % 2 > 0) THEN (IF settled50.routStrategy = << >> THEN <<[i \in 1 .. 6 |-> 0]>> ELSE settled50.routStrategy) ELSE << >>]
        settled52 == [settled51 EXCEPT !.routeDeliveryMethod = IF settled51.numberOfReturnBitfields >= 8 /\ (settled51.returnBitfield8 # << >> /\ (settled51.returnBitfield8[1] \div 32) % 2 > 0) THEN (IF settled51.routeDeliveryMethod = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled51.routeDeliveryMethod) ELSE << >>]
        settled53 == [settled52 EXCEPT !.exDestination = IF settled52.numberOfReturnBitfields >= 8 /\ (settled52.returnBitfield8 # << >> /\ (settled52.returnBitfield8[1] \div 64) % 2 > 0) THEN (IF settled52.exDestination = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled52.exDestination) ELSE << >>]
        settled54 == [settled53 EXCEPT !.crossTradeFlag = IF settled53.numberOfReturnBitfields >= 18 /\ (settled53.returnBitfield18 # << >> /\ (settled53.returnBitfield18[1] \div 8) % 2 > 0) THEN (IF settled53.crossTradeFlag = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled53.crossTradeFlag) ELSE << >>]
        settled55 == [settled54 EXCEPT !.locateBroker = IF settled54.numberOfReturnBitfields >= 18 /\ (settled54.returnBitfield18 # << >> /\ (settled54.returnBitfield18[1] \div 64) % 2 > 0) THEN (IF settled54.locateBroker = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled54.locateBroker) ELSE << >>]
    IN  settled55

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
                                 returnBitfield18        |-> << >>,
                                 returnBitfield19        |-> << >>,
                                 side                    |-> << >>,
                                 pegDifference           |-> << >>,
                                 price                   |-> << >>,
                                 execInst                |-> << >>,
                                 ordType                 |-> << >>,
                                 timeInForce             |-> << >>,
                                 minQty                  |-> << >>,
                                 symbol                  |-> << >>,
                                 symbolSfx               |-> << >>,
                                 account                 |-> << >>,
                                 clearingFirm            |-> << >>,
                                 clearingAccount         |-> << >>,
                                 displayIndicator        |-> << >>,
                                 maxFloor                |-> << >>,
                                 discretionAmount        |-> << >>,
                                 orderQty                |-> << >>,
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
                                 attributedQuote         |-> << >>,
                                 extExecInst             |-> << >>,
                                 echoText                |-> << >>,
                                 stopPx                  |-> << >>,
                                 routingInst             |-> << >>,
                                 routStrategy            |-> << >>,
                                 routeDeliveryMethod     |-> << >>,
                                 exDestination           |-> << >>,
                                 crossTradeFlag          |-> << >>,
                                 locateBroker            |-> << >> ])

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
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 9, !.returnBitfield9 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 10, !.returnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 11, !.returnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 13, !.returnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 14, !.returnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 15, !.returnBitfield15 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 17, !.returnBitfield17 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 18, !.returnBitfield18 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 19, !.returnBitfield19 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<1>>, !.side = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<2>>, !.pegDifference = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<4>>, !.price = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<8>>, !.execInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<1>>, !.symbol = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<2>>, !.symbolSfx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<1>>, !.account = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<2>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<4>>, !.clearingAccount = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<8>>, !.displayIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<16>>, !.maxFloor = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<32>>, !.discretionAmount = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<64>>, !.orderQty = one]) : one \in { <<held>> : held \in Sample(4) } }
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
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = <<8>>, !.attributedQuote = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = <<16>>, !.extExecInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<2>>, !.echoText = one]) : one \in { <<held>> : held \in Sample(64) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<4>>, !.stopPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<8>>, !.routingInst = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<16>>, !.routStrategy = one]) : one \in { <<held>> : held \in Sample(6) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<32>>, !.routeDeliveryMethod = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<64>>, !.exDestination = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 18, !.returnBitfield18 = <<8>>, !.crossTradeFlag = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 18, !.returnBitfield18 = <<64>>, !.locateBroker = one]) : one \in { <<held>> : held \in Sample(4) } }

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
      returnBitfield4         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield5         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield6         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield7         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield8         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield9         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield10        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield11        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield12        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield13        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield14        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield15        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield16        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield17        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield18        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield19        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      side                    : { << >> } \cup { <<held>> : held \in Sample(1) },
      pegDifference           : { << >> } \cup { <<held>> : held \in Sample(8) },
      price                   : { << >> } \cup { <<held>> : held \in Sample(8) },
      execInst                : { << >> } \cup { <<held>> : held \in Sample(1) },
      ordType                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce             : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                  : { << >> } \cup { <<held>> : held \in Sample(4) },
      symbol                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      symbolSfx               : { << >> } \cup { <<held>> : held \in Sample(8) },
      capacity                : { << >> } \cup { <<held>> : held \in Sample(1) },
      account                 : { << >> } \cup { <<held>> : held \in Sample(16) },
      clearingFirm            : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingAccount         : { << >> } \cup { <<held>> : held \in Sample(4) },
      displayIndicator        : { << >> } \cup { <<held>> : held \in Sample(1) },
      maxFloor                : { << >> } \cup { <<held>> : held \in Sample(4) },
      discretionAmount        : { << >> } \cup { <<held>> : held \in Sample(2) },
      orderQty                : { << >> } \cup { <<held>> : held \in Sample(4) },
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
      attributedQuote         : { << >> } \cup { <<held>> : held \in Sample(1) },
      extExecInst             : { << >> } \cup { <<held>> : held \in Sample(1) },
      echoText                : { << >> } \cup { <<held>> : held \in Sample(64) },
      stopPx                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      routingInst             : { << >> } \cup { <<held>> : held \in Sample(4) },
      routStrategy            : { << >> } \cup { <<held>> : held \in Sample(6) },
      routeDeliveryMethod     : { << >> } \cup { <<held>> : held \in Sample(3) },
      exDestination           : { << >> } \cup { <<held>> : held \in Sample(1) },
      cmcMatchQty             : { << >> } \cup { <<held>> : held \in Sample(4) },
      stepUpAmount            : { << >> } \cup { <<held>> : held \in Sample(8) } ]

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
        \o (IF message.returnBitfield4 = << >> THEN << >> ELSE message.returnBitfield4[1])
        \o (IF message.returnBitfield5 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield5[1], 1))
        \o (IF message.returnBitfield6 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield6[1], 1))
        \o (IF message.returnBitfield7 = << >> THEN << >> ELSE message.returnBitfield7[1])
        \o (IF message.returnBitfield8 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield8[1], 1))
        \o (IF message.returnBitfield9 = << >> THEN << >> ELSE message.returnBitfield9[1])
        \o (IF message.returnBitfield10 = << >> THEN << >> ELSE message.returnBitfield10[1])
        \o (IF message.returnBitfield11 = << >> THEN << >> ELSE message.returnBitfield11[1])
        \o (IF message.returnBitfield12 = << >> THEN << >> ELSE message.returnBitfield12[1])
        \o (IF message.returnBitfield13 = << >> THEN << >> ELSE message.returnBitfield13[1])
        \o (IF message.returnBitfield14 = << >> THEN << >> ELSE message.returnBitfield14[1])
        \o (IF message.returnBitfield15 = << >> THEN << >> ELSE message.returnBitfield15[1])
        \o (IF message.returnBitfield16 = << >> THEN << >> ELSE message.returnBitfield16[1])
        \o (IF message.returnBitfield17 = << >> THEN << >> ELSE message.returnBitfield17[1])
        \o (IF message.returnBitfield18 = << >> THEN << >> ELSE message.returnBitfield18[1])
        \o (IF message.returnBitfield19 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield19[1], 1))
        \o (IF message.side = << >> THEN << >> ELSE message.side[1])
        \o (IF message.pegDifference = << >> THEN << >> ELSE message.pegDifference[1])
        \o (IF message.price = << >> THEN << >> ELSE message.price[1])
        \o (IF message.execInst = << >> THEN << >> ELSE message.execInst[1])
        \o (IF message.ordType = << >> THEN << >> ELSE message.ordType[1])
        \o (IF message.timeInForce = << >> THEN << >> ELSE message.timeInForce[1])
        \o (IF message.minQty = << >> THEN << >> ELSE message.minQty[1])
        \o (IF message.symbol = << >> THEN << >> ELSE message.symbol[1])
        \o (IF message.symbolSfx = << >> THEN << >> ELSE message.symbolSfx[1])
        \o (IF message.capacity = << >> THEN << >> ELSE message.capacity[1])
        \o (IF message.account = << >> THEN << >> ELSE message.account[1])
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])
        \o (IF message.clearingAccount = << >> THEN << >> ELSE message.clearingAccount[1])
        \o (IF message.displayIndicator = << >> THEN << >> ELSE message.displayIndicator[1])
        \o (IF message.maxFloor = << >> THEN << >> ELSE message.maxFloor[1])
        \o (IF message.discretionAmount = << >> THEN << >> ELSE message.discretionAmount[1])
        \o (IF message.orderQty = << >> THEN << >> ELSE message.orderQty[1])
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
        \o (IF message.attributedQuote = << >> THEN << >> ELSE message.attributedQuote[1])
        \o (IF message.extExecInst = << >> THEN << >> ELSE message.extExecInst[1])
        \o (IF message.echoText = << >> THEN << >> ELSE message.echoText[1])
        \o (IF message.stopPx = << >> THEN << >> ELSE message.stopPx[1])
        \o (IF message.routingInst = << >> THEN << >> ELSE message.routingInst[1])
        \o (IF message.routStrategy = << >> THEN << >> ELSE message.routStrategy[1])
        \o (IF message.routeDeliveryMethod = << >> THEN << >> ELSE message.routeDeliveryMethod[1])
        \o (IF message.exDestination = << >> THEN << >> ELSE message.exDestination[1])
        \o (IF message.cmcMatchQty = << >> THEN << >> ELSE message.cmcMatchQty[1])
        \o (IF message.stepUpAmount = << >> THEN << >> ELSE message.stepUpAmount[1])

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
    LET returnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadBytes(returnBitfield3.rest, 1), returnBitfield3.rest) IN IF ~returnBitfield4.ok THEN Fail ELSE
    LET returnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadUIntLE(returnBitfield4.rest, 1), returnBitfield4.rest) IN IF ~returnBitfield5.ok THEN Fail ELSE
    LET returnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadUIntLE(returnBitfield5.rest, 1), returnBitfield5.rest) IN IF ~returnBitfield6.ok THEN Fail ELSE
    LET returnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadBytes(returnBitfield6.rest, 1), returnBitfield6.rest) IN IF ~returnBitfield7.ok THEN Fail ELSE
    LET returnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadUIntLE(returnBitfield7.rest, 1), returnBitfield7.rest) IN IF ~returnBitfield8.ok THEN Fail ELSE
    LET returnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadBytes(returnBitfield8.rest, 1), returnBitfield8.rest) IN IF ~returnBitfield9.ok THEN Fail ELSE
    LET returnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadBytes(returnBitfield9.rest, 1), returnBitfield9.rest) IN IF ~returnBitfield10.ok THEN Fail ELSE
    LET returnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadBytes(returnBitfield10.rest, 1), returnBitfield10.rest) IN IF ~returnBitfield11.ok THEN Fail ELSE
    LET returnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadBytes(returnBitfield11.rest, 1), returnBitfield11.rest) IN IF ~returnBitfield12.ok THEN Fail ELSE
    LET returnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(returnBitfield12.rest, 1), returnBitfield12.rest) IN IF ~returnBitfield13.ok THEN Fail ELSE
    LET returnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(returnBitfield13.rest, 1), returnBitfield13.rest) IN IF ~returnBitfield14.ok THEN Fail ELSE
    LET returnBitfield15 == ReadWhen(numberOfReturnBitfields.value >= 15, ReadBytes(returnBitfield14.rest, 1), returnBitfield14.rest) IN IF ~returnBitfield15.ok THEN Fail ELSE
    LET returnBitfield16 == ReadWhen(numberOfReturnBitfields.value >= 16, ReadBytes(returnBitfield15.rest, 1), returnBitfield15.rest) IN IF ~returnBitfield16.ok THEN Fail ELSE
    LET returnBitfield17 == ReadWhen(numberOfReturnBitfields.value >= 17, ReadBytes(returnBitfield16.rest, 1), returnBitfield16.rest) IN IF ~returnBitfield17.ok THEN Fail ELSE
    LET returnBitfield18 == ReadWhen(numberOfReturnBitfields.value >= 18, ReadBytes(returnBitfield17.rest, 1), returnBitfield17.rest) IN IF ~returnBitfield18.ok THEN Fail ELSE
    LET returnBitfield19 == ReadWhen(numberOfReturnBitfields.value >= 19, ReadUIntLE(returnBitfield18.rest, 1), returnBitfield18.rest) IN IF ~returnBitfield19.ok THEN Fail ELSE
    LET side == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ returnBitfield1.value[1] % 2 > 0), ReadBytes(returnBitfield19.rest, 1), returnBitfield19.rest) IN IF ~side.ok THEN Fail ELSE
    LET pegDifference == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 2) % 2 > 0), ReadBytes(side.rest, 8), side.rest) IN IF ~pegDifference.ok THEN Fail ELSE
    LET price == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(pegDifference.rest, 8), pegDifference.rest) IN IF ~price.ok THEN Fail ELSE
    LET execInst == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 8) % 2 > 0), ReadBytes(price.rest, 1), price.rest) IN IF ~execInst.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(execInst.rest, 1), execInst.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET symbol == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ returnBitfield2.value[1] % 2 > 0), ReadBytes(minQty.rest, 8), minQty.rest) IN IF ~symbol.ok THEN Fail ELSE
    LET symbolSfx == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ (returnBitfield2.value[1] \div 2) % 2 > 0), ReadBytes(symbol.rest, 8), symbol.rest) IN IF ~symbolSfx.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ (returnBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(symbolSfx.rest, 1), symbolSfx.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ returnBitfield3.value[1] % 2 > 0), ReadBytes(capacity.rest, 16), capacity.rest) IN IF ~account.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 2) % 2 > 0), ReadBytes(account.rest, 4), account.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 4) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET displayIndicator == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 8) % 2 > 0), ReadBytes(clearingAccount.rest, 1), clearingAccount.rest) IN IF ~displayIndicator.ok THEN Fail ELSE
    LET maxFloor == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 16) % 2 > 0), ReadBytes(displayIndicator.rest, 4), displayIndicator.rest) IN IF ~maxFloor.ok THEN Fail ELSE
    LET discretionAmount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 32) % 2 > 0), ReadBytes(maxFloor.rest, 2), maxFloor.rest) IN IF ~discretionAmount.ok THEN Fail ELSE
    LET orderQty == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 64) % 2 > 0), ReadBytes(discretionAmount.rest, 4), discretionAmount.rest) IN IF ~orderQty.ok THEN Fail ELSE
    LET preventMatch == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 128) % 2 > 0), ReadBytes(orderQty.rest, 3), orderQty.rest) IN IF ~preventMatch.ok THEN Fail ELSE
    LET origClOrdId == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ returnBitfield5.value[1] % 2 > 0), ReadBytes(preventMatch.rest, 20), preventMatch.rest) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET leavesQty == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 2) % 2 > 0), ReadBytes(origClOrdId.rest, 4), origClOrdId.rest) IN IF ~leavesQty.ok THEN Fail ELSE
    LET lastShares == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 4) % 2 > 0), ReadBytes(leavesQty.rest, 4), leavesQty.rest) IN IF ~lastShares.ok THEN Fail ELSE
    LET lastPx == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 8) % 2 > 0), ReadBytes(lastShares.rest, 8), lastShares.rest) IN IF ~lastPx.ok THEN Fail ELSE
    LET displayPrice == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 16) % 2 > 0), ReadBytes(lastPx.rest, 8), lastPx.rest) IN IF ~displayPrice.ok THEN Fail ELSE
    LET workingPrice == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 32) % 2 > 0), ReadBytes(displayPrice.rest, 8), displayPrice.rest) IN IF ~workingPrice.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 64) % 2 > 0), ReadBytes(workingPrice.rest, 1), workingPrice.rest) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET expireTime == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 128) % 2 > 0), ReadBytes(baseLiquidityIndicator.rest, 8), baseLiquidityIndicator.rest) IN IF ~expireTime.ok THEN Fail ELSE
    LET secondaryOrderId == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (returnBitfield6.value # << >> /\ returnBitfield6.value[1] % 2 > 0), ReadBytes(expireTime.rest, 8), expireTime.rest) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET attributedQuote == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (returnBitfield6.value # << >> /\ (returnBitfield6.value[1] \div 8) % 2 > 0), ReadBytes(secondaryOrderId.rest, 1), secondaryOrderId.rest) IN IF ~attributedQuote.ok THEN Fail ELSE
    LET extExecInst == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (returnBitfield6.value # << >> /\ (returnBitfield6.value[1] \div 16) % 2 > 0), ReadBytes(attributedQuote.rest, 1), attributedQuote.rest) IN IF ~extExecInst.ok THEN Fail ELSE
    LET echoText == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 2) % 2 > 0), ReadBytes(extExecInst.rest, 64), extExecInst.rest) IN IF ~echoText.ok THEN Fail ELSE
    LET stopPx == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 4) % 2 > 0), ReadBytes(echoText.rest, 8), echoText.rest) IN IF ~stopPx.ok THEN Fail ELSE
    LET routingInst == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 8) % 2 > 0), ReadBytes(stopPx.rest, 4), stopPx.rest) IN IF ~routingInst.ok THEN Fail ELSE
    LET routStrategy == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 16) % 2 > 0), ReadBytes(routingInst.rest, 6), routingInst.rest) IN IF ~routStrategy.ok THEN Fail ELSE
    LET routeDeliveryMethod == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 32) % 2 > 0), ReadBytes(routStrategy.rest, 3), routStrategy.rest) IN IF ~routeDeliveryMethod.ok THEN Fail ELSE
    LET exDestination == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 64) % 2 > 0), ReadBytes(routeDeliveryMethod.rest, 1), routeDeliveryMethod.rest) IN IF ~exDestination.ok THEN Fail ELSE
    LET cmcMatchQty == ReadWhen(numberOfReturnBitfields.value >= 19 /\ (returnBitfield19.value # << >> /\ (returnBitfield19.value[1] \div 32) % 2 > 0), ReadBytes(exDestination.rest, 4), exDestination.rest) IN IF ~cmcMatchQty.ok THEN Fail ELSE
    LET stepUpAmount == ReadWhen(numberOfReturnBitfields.value >= 19 /\ (returnBitfield19.value # << >> /\ (returnBitfield19.value[1] \div 64) % 2 > 0), ReadBytes(cmcMatchQty.rest, 8), cmcMatchQty.rest) IN IF ~stepUpAmount.ok THEN Fail ELSE
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
         returnBitfield18        |-> returnBitfield18.value,
         returnBitfield19        |-> returnBitfield19.value,
         side                    |-> side.value,
         pegDifference           |-> pegDifference.value,
         price                   |-> price.value,
         execInst                |-> execInst.value,
         ordType                 |-> ordType.value,
         timeInForce             |-> timeInForce.value,
         minQty                  |-> minQty.value,
         symbol                  |-> symbol.value,
         symbolSfx               |-> symbolSfx.value,
         capacity                |-> capacity.value,
         account                 |-> account.value,
         clearingFirm            |-> clearingFirm.value,
         clearingAccount         |-> clearingAccount.value,
         displayIndicator        |-> displayIndicator.value,
         maxFloor                |-> maxFloor.value,
         discretionAmount        |-> discretionAmount.value,
         orderQty                |-> orderQty.value,
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
         attributedQuote         |-> attributedQuote.value,
         extExecInst             |-> extExecInst.value,
         echoText                |-> echoText.value,
         stopPx                  |-> stopPx.value,
         routingInst             |-> routingInst.value,
         routStrategy            |-> routStrategy.value,
         routeDeliveryMethod     |-> routeDeliveryMethod.value,
         exDestination           |-> exDestination.value,
         cmcMatchQty             |-> cmcMatchQty.value,
         stepUpAmount            |-> stepUpAmount.value ], stepUpAmount.rest)

(* Order Restated Message with each field marked present by fields before it there exactly where they say *)
SettleOrderRestatedMessage(message) ==
    LET settled1 == [message EXCEPT !.returnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.returnBitfield1 = << >> THEN <<0>> ELSE message.returnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.returnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.returnBitfield2 = << >> THEN <<0>> ELSE settled1.returnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.returnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.returnBitfield3 = << >> THEN <<0>> ELSE settled2.returnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.returnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.returnBitfield4 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled3.returnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.returnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.returnBitfield5 = << >> THEN <<0>> ELSE settled4.returnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.returnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.returnBitfield6 = << >> THEN <<0>> ELSE settled5.returnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.returnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.returnBitfield7 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.returnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.returnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.returnBitfield8 = << >> THEN <<0>> ELSE settled7.returnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.returnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.returnBitfield9 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled8.returnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.returnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.returnBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.returnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.returnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.returnBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.returnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.returnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.returnBitfield12 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.returnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.returnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.returnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.returnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.returnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.returnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.returnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.returnBitfield15 = IF settled14.numberOfReturnBitfields >= 15 THEN (IF settled14.returnBitfield15 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.returnBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.returnBitfield16 = IF settled15.numberOfReturnBitfields >= 16 THEN (IF settled15.returnBitfield16 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled15.returnBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.returnBitfield17 = IF settled16.numberOfReturnBitfields >= 17 THEN (IF settled16.returnBitfield17 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled16.returnBitfield17) ELSE << >>]
        settled18 == [settled17 EXCEPT !.returnBitfield18 = IF settled17.numberOfReturnBitfields >= 18 THEN (IF settled17.returnBitfield18 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.returnBitfield18) ELSE << >>]
        settled19 == [settled18 EXCEPT !.returnBitfield19 = IF settled18.numberOfReturnBitfields >= 19 THEN (IF settled18.returnBitfield19 = << >> THEN <<0>> ELSE settled18.returnBitfield19) ELSE << >>]
        settled20 == [settled19 EXCEPT !.side = IF settled19.numberOfReturnBitfields >= 1 /\ (settled19.returnBitfield1 # << >> /\ settled19.returnBitfield1[1] % 2 > 0) THEN (IF settled19.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled19.side) ELSE << >>]
        settled21 == [settled20 EXCEPT !.pegDifference = IF settled20.numberOfReturnBitfields >= 1 /\ (settled20.returnBitfield1 # << >> /\ (settled20.returnBitfield1[1] \div 2) % 2 > 0) THEN (IF settled20.pegDifference = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled20.pegDifference) ELSE << >>]
        settled22 == [settled21 EXCEPT !.price = IF settled21.numberOfReturnBitfields >= 1 /\ (settled21.returnBitfield1 # << >> /\ (settled21.returnBitfield1[1] \div 4) % 2 > 0) THEN (IF settled21.price = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled21.price) ELSE << >>]
        settled23 == [settled22 EXCEPT !.execInst = IF settled22.numberOfReturnBitfields >= 1 /\ (settled22.returnBitfield1 # << >> /\ (settled22.returnBitfield1[1] \div 8) % 2 > 0) THEN (IF settled22.execInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled22.execInst) ELSE << >>]
        settled24 == [settled23 EXCEPT !.ordType = IF settled23.numberOfReturnBitfields >= 1 /\ (settled23.returnBitfield1 # << >> /\ (settled23.returnBitfield1[1] \div 16) % 2 > 0) THEN (IF settled23.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled23.ordType) ELSE << >>]
        settled25 == [settled24 EXCEPT !.timeInForce = IF settled24.numberOfReturnBitfields >= 1 /\ (settled24.returnBitfield1 # << >> /\ (settled24.returnBitfield1[1] \div 32) % 2 > 0) THEN (IF settled24.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled24.timeInForce) ELSE << >>]
        settled26 == [settled25 EXCEPT !.minQty = IF settled25.numberOfReturnBitfields >= 1 /\ (settled25.returnBitfield1 # << >> /\ (settled25.returnBitfield1[1] \div 64) % 2 > 0) THEN (IF settled25.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled25.minQty) ELSE << >>]
        settled27 == [settled26 EXCEPT !.symbol = IF settled26.numberOfReturnBitfields >= 2 /\ (settled26.returnBitfield2 # << >> /\ settled26.returnBitfield2[1] % 2 > 0) THEN (IF settled26.symbol = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled26.symbol) ELSE << >>]
        settled28 == [settled27 EXCEPT !.symbolSfx = IF settled27.numberOfReturnBitfields >= 2 /\ (settled27.returnBitfield2 # << >> /\ (settled27.returnBitfield2[1] \div 2) % 2 > 0) THEN (IF settled27.symbolSfx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled27.symbolSfx) ELSE << >>]
        settled29 == [settled28 EXCEPT !.capacity = IF settled28.numberOfReturnBitfields >= 2 /\ (settled28.returnBitfield2 # << >> /\ (settled28.returnBitfield2[1] \div 64) % 2 > 0) THEN (IF settled28.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled28.capacity) ELSE << >>]
        settled30 == [settled29 EXCEPT !.account = IF settled29.numberOfReturnBitfields >= 3 /\ (settled29.returnBitfield3 # << >> /\ settled29.returnBitfield3[1] % 2 > 0) THEN (IF settled29.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled29.account) ELSE << >>]
        settled31 == [settled30 EXCEPT !.clearingFirm = IF settled30.numberOfReturnBitfields >= 3 /\ (settled30.returnBitfield3 # << >> /\ (settled30.returnBitfield3[1] \div 2) % 2 > 0) THEN (IF settled30.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled30.clearingFirm) ELSE << >>]
        settled32 == [settled31 EXCEPT !.clearingAccount = IF settled31.numberOfReturnBitfields >= 3 /\ (settled31.returnBitfield3 # << >> /\ (settled31.returnBitfield3[1] \div 4) % 2 > 0) THEN (IF settled31.clearingAccount = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled31.clearingAccount) ELSE << >>]
        settled33 == [settled32 EXCEPT !.displayIndicator = IF settled32.numberOfReturnBitfields >= 3 /\ (settled32.returnBitfield3 # << >> /\ (settled32.returnBitfield3[1] \div 8) % 2 > 0) THEN (IF settled32.displayIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled32.displayIndicator) ELSE << >>]
        settled34 == [settled33 EXCEPT !.maxFloor = IF settled33.numberOfReturnBitfields >= 3 /\ (settled33.returnBitfield3 # << >> /\ (settled33.returnBitfield3[1] \div 16) % 2 > 0) THEN (IF settled33.maxFloor = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled33.maxFloor) ELSE << >>]
        settled35 == [settled34 EXCEPT !.discretionAmount = IF settled34.numberOfReturnBitfields >= 3 /\ (settled34.returnBitfield3 # << >> /\ (settled34.returnBitfield3[1] \div 32) % 2 > 0) THEN (IF settled34.discretionAmount = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled34.discretionAmount) ELSE << >>]
        settled36 == [settled35 EXCEPT !.orderQty = IF settled35.numberOfReturnBitfields >= 3 /\ (settled35.returnBitfield3 # << >> /\ (settled35.returnBitfield3[1] \div 64) % 2 > 0) THEN (IF settled35.orderQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled35.orderQty) ELSE << >>]
        settled37 == [settled36 EXCEPT !.preventMatch = IF settled36.numberOfReturnBitfields >= 3 /\ (settled36.returnBitfield3 # << >> /\ (settled36.returnBitfield3[1] \div 128) % 2 > 0) THEN (IF settled36.preventMatch = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled36.preventMatch) ELSE << >>]
        settled38 == [settled37 EXCEPT !.origClOrdId = IF settled37.numberOfReturnBitfields >= 5 /\ (settled37.returnBitfield5 # << >> /\ settled37.returnBitfield5[1] % 2 > 0) THEN (IF settled37.origClOrdId = << >> THEN <<[i \in 1 .. 20 |-> 0]>> ELSE settled37.origClOrdId) ELSE << >>]
        settled39 == [settled38 EXCEPT !.leavesQty = IF settled38.numberOfReturnBitfields >= 5 /\ (settled38.returnBitfield5 # << >> /\ (settled38.returnBitfield5[1] \div 2) % 2 > 0) THEN (IF settled38.leavesQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled38.leavesQty) ELSE << >>]
        settled40 == [settled39 EXCEPT !.lastShares = IF settled39.numberOfReturnBitfields >= 5 /\ (settled39.returnBitfield5 # << >> /\ (settled39.returnBitfield5[1] \div 4) % 2 > 0) THEN (IF settled39.lastShares = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled39.lastShares) ELSE << >>]
        settled41 == [settled40 EXCEPT !.lastPx = IF settled40.numberOfReturnBitfields >= 5 /\ (settled40.returnBitfield5 # << >> /\ (settled40.returnBitfield5[1] \div 8) % 2 > 0) THEN (IF settled40.lastPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled40.lastPx) ELSE << >>]
        settled42 == [settled41 EXCEPT !.displayPrice = IF settled41.numberOfReturnBitfields >= 5 /\ (settled41.returnBitfield5 # << >> /\ (settled41.returnBitfield5[1] \div 16) % 2 > 0) THEN (IF settled41.displayPrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled41.displayPrice) ELSE << >>]
        settled43 == [settled42 EXCEPT !.workingPrice = IF settled42.numberOfReturnBitfields >= 5 /\ (settled42.returnBitfield5 # << >> /\ (settled42.returnBitfield5[1] \div 32) % 2 > 0) THEN (IF settled42.workingPrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled42.workingPrice) ELSE << >>]
        settled44 == [settled43 EXCEPT !.baseLiquidityIndicator = IF settled43.numberOfReturnBitfields >= 5 /\ (settled43.returnBitfield5 # << >> /\ (settled43.returnBitfield5[1] \div 64) % 2 > 0) THEN (IF settled43.baseLiquidityIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled43.baseLiquidityIndicator) ELSE << >>]
        settled45 == [settled44 EXCEPT !.expireTime = IF settled44.numberOfReturnBitfields >= 5 /\ (settled44.returnBitfield5 # << >> /\ (settled44.returnBitfield5[1] \div 128) % 2 > 0) THEN (IF settled44.expireTime = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled44.expireTime) ELSE << >>]
        settled46 == [settled45 EXCEPT !.secondaryOrderId = IF settled45.numberOfReturnBitfields >= 6 /\ (settled45.returnBitfield6 # << >> /\ settled45.returnBitfield6[1] % 2 > 0) THEN (IF settled45.secondaryOrderId = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled45.secondaryOrderId) ELSE << >>]
        settled47 == [settled46 EXCEPT !.attributedQuote = IF settled46.numberOfReturnBitfields >= 6 /\ (settled46.returnBitfield6 # << >> /\ (settled46.returnBitfield6[1] \div 8) % 2 > 0) THEN (IF settled46.attributedQuote = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled46.attributedQuote) ELSE << >>]
        settled48 == [settled47 EXCEPT !.extExecInst = IF settled47.numberOfReturnBitfields >= 6 /\ (settled47.returnBitfield6 # << >> /\ (settled47.returnBitfield6[1] \div 16) % 2 > 0) THEN (IF settled47.extExecInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled47.extExecInst) ELSE << >>]
        settled49 == [settled48 EXCEPT !.echoText = IF settled48.numberOfReturnBitfields >= 8 /\ (settled48.returnBitfield8 # << >> /\ (settled48.returnBitfield8[1] \div 2) % 2 > 0) THEN (IF settled48.echoText = << >> THEN <<[i \in 1 .. 64 |-> 0]>> ELSE settled48.echoText) ELSE << >>]
        settled50 == [settled49 EXCEPT !.stopPx = IF settled49.numberOfReturnBitfields >= 8 /\ (settled49.returnBitfield8 # << >> /\ (settled49.returnBitfield8[1] \div 4) % 2 > 0) THEN (IF settled49.stopPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled49.stopPx) ELSE << >>]
        settled51 == [settled50 EXCEPT !.routingInst = IF settled50.numberOfReturnBitfields >= 8 /\ (settled50.returnBitfield8 # << >> /\ (settled50.returnBitfield8[1] \div 8) % 2 > 0) THEN (IF settled50.routingInst = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled50.routingInst) ELSE << >>]
        settled52 == [settled51 EXCEPT !.routStrategy = IF settled51.numberOfReturnBitfields >= 8 /\ (settled51.returnBitfield8 # << >> /\ (settled51.returnBitfield8[1] \div 16) % 2 > 0) THEN (IF settled51.routStrategy = << >> THEN <<[i \in 1 .. 6 |-> 0]>> ELSE settled51.routStrategy) ELSE << >>]
        settled53 == [settled52 EXCEPT !.routeDeliveryMethod = IF settled52.numberOfReturnBitfields >= 8 /\ (settled52.returnBitfield8 # << >> /\ (settled52.returnBitfield8[1] \div 32) % 2 > 0) THEN (IF settled52.routeDeliveryMethod = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled52.routeDeliveryMethod) ELSE << >>]
        settled54 == [settled53 EXCEPT !.exDestination = IF settled53.numberOfReturnBitfields >= 8 /\ (settled53.returnBitfield8 # << >> /\ (settled53.returnBitfield8[1] \div 64) % 2 > 0) THEN (IF settled53.exDestination = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled53.exDestination) ELSE << >>]
        settled55 == [settled54 EXCEPT !.cmcMatchQty = IF settled54.numberOfReturnBitfields >= 19 /\ (settled54.returnBitfield19 # << >> /\ (settled54.returnBitfield19[1] \div 32) % 2 > 0) THEN (IF settled54.cmcMatchQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled54.cmcMatchQty) ELSE << >>]
        settled56 == [settled55 EXCEPT !.stepUpAmount = IF settled55.numberOfReturnBitfields >= 19 /\ (settled55.returnBitfield19 # << >> /\ (settled55.returnBitfield19[1] \div 64) % 2 > 0) THEN (IF settled55.stepUpAmount = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled55.stepUpAmount) ELSE << >>]
    IN  settled56

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
                                 returnBitfield18        |-> << >>,
                                 returnBitfield19        |-> << >>,
                                 side                    |-> << >>,
                                 pegDifference           |-> << >>,
                                 price                   |-> << >>,
                                 execInst                |-> << >>,
                                 ordType                 |-> << >>,
                                 timeInForce             |-> << >>,
                                 minQty                  |-> << >>,
                                 symbol                  |-> << >>,
                                 symbolSfx               |-> << >>,
                                 capacity                |-> << >>,
                                 account                 |-> << >>,
                                 clearingFirm            |-> << >>,
                                 clearingAccount         |-> << >>,
                                 displayIndicator        |-> << >>,
                                 maxFloor                |-> << >>,
                                 discretionAmount        |-> << >>,
                                 orderQty                |-> << >>,
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
                                 attributedQuote         |-> << >>,
                                 extExecInst             |-> << >>,
                                 echoText                |-> << >>,
                                 stopPx                  |-> << >>,
                                 routingInst             |-> << >>,
                                 routStrategy            |-> << >>,
                                 routeDeliveryMethod     |-> << >>,
                                 exDestination           |-> << >>,
                                 cmcMatchQty             |-> << >>,
                                 stepUpAmount            |-> << >> ])

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
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 7, !.returnBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 9, !.returnBitfield9 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 10, !.returnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 11, !.returnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 13, !.returnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 14, !.returnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 15, !.returnBitfield15 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 17, !.returnBitfield17 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 18, !.returnBitfield18 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 19, !.returnBitfield19 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<1>>, !.side = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<2>>, !.pegDifference = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<4>>, !.price = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<8>>, !.execInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<1>>, !.symbol = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<2>>, !.symbolSfx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<1>>, !.account = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<2>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<4>>, !.clearingAccount = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<8>>, !.displayIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<16>>, !.maxFloor = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<32>>, !.discretionAmount = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<64>>, !.orderQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<128>>, !.preventMatch = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<1>>, !.origClOrdId = one]) : one \in { <<held>> : held \in Sample(20) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<2>>, !.leavesQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<4>>, !.lastShares = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<8>>, !.lastPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<16>>, !.displayPrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<32>>, !.workingPrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<64>>, !.baseLiquidityIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<128>>, !.expireTime = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = <<1>>, !.secondaryOrderId = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = <<8>>, !.attributedQuote = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = <<16>>, !.extExecInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<2>>, !.echoText = one]) : one \in { <<held>> : held \in Sample(64) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<4>>, !.stopPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<8>>, !.routingInst = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<16>>, !.routStrategy = one]) : one \in { <<held>> : held \in Sample(6) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<32>>, !.routeDeliveryMethod = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<64>>, !.exDestination = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 19, !.returnBitfield19 = <<32>>, !.cmcMatchQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 19, !.returnBitfield19 = <<64>>, !.stepUpAmount = one]) : one \in { <<held>> : held \in Sample(8) } }

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
      returnBitfield17        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield18        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield19        : { << >> } \cup { <<held>> : held \in Sample(1) } ]

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
        \o (IF message.returnBitfield18 = << >> THEN << >> ELSE message.returnBitfield18[1])
        \o (IF message.returnBitfield19 = << >> THEN << >> ELSE message.returnBitfield19[1])

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
    LET returnBitfield18 == ReadWhen(numberOfReturnBitfields.value >= 18, ReadBytes(returnBitfield17.rest, 1), returnBitfield17.rest) IN IF ~returnBitfield18.ok THEN Fail ELSE
    LET returnBitfield19 == ReadWhen(numberOfReturnBitfields.value >= 19, ReadBytes(returnBitfield18.rest, 1), returnBitfield18.rest) IN IF ~returnBitfield19.ok THEN Fail ELSE
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
         returnBitfield17        |-> returnBitfield17.value,
         returnBitfield18        |-> returnBitfield18.value,
         returnBitfield19        |-> returnBitfield19.value ], returnBitfield19.rest)

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
        settled18 == [settled17 EXCEPT !.returnBitfield18 = IF settled17.numberOfReturnBitfields >= 18 THEN (IF settled17.returnBitfield18 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.returnBitfield18) ELSE << >>]
        settled19 == [settled18 EXCEPT !.returnBitfield19 = IF settled18.numberOfReturnBitfields >= 19 THEN (IF settled18.returnBitfield19 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled18.returnBitfield19) ELSE << >>]
    IN  settled19

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
                                      returnBitfield17        |-> << >>,
                                      returnBitfield18        |-> << >>,
                                      returnBitfield19        |-> << >> ])

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
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.numberOfReturnBitfields = 18, !.returnBitfield18 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.numberOfReturnBitfields = 19, !.returnBitfield19 = one]) : one \in { <<held>> : held \in Sample(1) } }

(***************************************************************************)
(* Order Cancelled Message                                                 *)
(***************************************************************************)

OrderCancelledMessage ==
    [ transactionTime         : Sample(8),
      clOrdId                 : Sample(20),
      cancelReason            : Sample(1),
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
      returnBitfield9         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield10        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield11        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield12        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield13        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield14        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield15        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield16        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield17        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield18        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield19        : { << >> } \cup { <<held>> : held \in Sample(1) },
      side                    : { << >> } \cup { <<held>> : held \in Sample(1) },
      pegDifference           : { << >> } \cup { <<held>> : held \in Sample(8) },
      price                   : { << >> } \cup { <<held>> : held \in Sample(8) },
      execInst                : { << >> } \cup { <<held>> : held \in Sample(1) },
      ordType                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce             : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                  : { << >> } \cup { <<held>> : held \in Sample(4) },
      symbol                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      symbolSfx               : { << >> } \cup { <<held>> : held \in Sample(8) },
      capacity                : { << >> } \cup { <<held>> : held \in Sample(1) },
      account                 : { << >> } \cup { <<held>> : held \in Sample(16) },
      clearingFirm            : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingAccount         : { << >> } \cup { <<held>> : held \in Sample(4) },
      displayIndicator        : { << >> } \cup { <<held>> : held \in Sample(1) },
      maxFloor                : { << >> } \cup { <<held>> : held \in Sample(4) },
      discretionAmount        : { << >> } \cup { <<held>> : held \in Sample(2) },
      orderQty                : { << >> } \cup { <<held>> : held \in Sample(4) },
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
      attributedQuote         : { << >> } \cup { <<held>> : held \in Sample(1) },
      extExecInst             : { << >> } \cup { <<held>> : held \in Sample(1) },
      echoText                : { << >> } \cup { <<held>> : held \in Sample(64) },
      stopPx                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      routingInst             : { << >> } \cup { <<held>> : held \in Sample(4) },
      routStrategy            : { << >> } \cup { <<held>> : held \in Sample(6) },
      routeDeliveryMethod     : { << >> } \cup { <<held>> : held \in Sample(3) },
      exDestination           : { << >> } \cup { <<held>> : held \in Sample(1) },
      crossTradeFlag          : { << >> } \cup { <<held>> : held \in Sample(1) } ]

EncodeOrderCancelledMessage(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.cancelReason
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
        \o (IF message.returnBitfield9 = << >> THEN << >> ELSE message.returnBitfield9[1])
        \o (IF message.returnBitfield10 = << >> THEN << >> ELSE message.returnBitfield10[1])
        \o (IF message.returnBitfield11 = << >> THEN << >> ELSE message.returnBitfield11[1])
        \o (IF message.returnBitfield12 = << >> THEN << >> ELSE message.returnBitfield12[1])
        \o (IF message.returnBitfield13 = << >> THEN << >> ELSE message.returnBitfield13[1])
        \o (IF message.returnBitfield14 = << >> THEN << >> ELSE message.returnBitfield14[1])
        \o (IF message.returnBitfield15 = << >> THEN << >> ELSE message.returnBitfield15[1])
        \o (IF message.returnBitfield16 = << >> THEN << >> ELSE message.returnBitfield16[1])
        \o (IF message.returnBitfield17 = << >> THEN << >> ELSE message.returnBitfield17[1])
        \o (IF message.returnBitfield18 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield18[1], 1))
        \o (IF message.returnBitfield19 = << >> THEN << >> ELSE message.returnBitfield19[1])
        \o (IF message.side = << >> THEN << >> ELSE message.side[1])
        \o (IF message.pegDifference = << >> THEN << >> ELSE message.pegDifference[1])
        \o (IF message.price = << >> THEN << >> ELSE message.price[1])
        \o (IF message.execInst = << >> THEN << >> ELSE message.execInst[1])
        \o (IF message.ordType = << >> THEN << >> ELSE message.ordType[1])
        \o (IF message.timeInForce = << >> THEN << >> ELSE message.timeInForce[1])
        \o (IF message.minQty = << >> THEN << >> ELSE message.minQty[1])
        \o (IF message.symbol = << >> THEN << >> ELSE message.symbol[1])
        \o (IF message.symbolSfx = << >> THEN << >> ELSE message.symbolSfx[1])
        \o (IF message.capacity = << >> THEN << >> ELSE message.capacity[1])
        \o (IF message.account = << >> THEN << >> ELSE message.account[1])
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])
        \o (IF message.clearingAccount = << >> THEN << >> ELSE message.clearingAccount[1])
        \o (IF message.displayIndicator = << >> THEN << >> ELSE message.displayIndicator[1])
        \o (IF message.maxFloor = << >> THEN << >> ELSE message.maxFloor[1])
        \o (IF message.discretionAmount = << >> THEN << >> ELSE message.discretionAmount[1])
        \o (IF message.orderQty = << >> THEN << >> ELSE message.orderQty[1])
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
        \o (IF message.attributedQuote = << >> THEN << >> ELSE message.attributedQuote[1])
        \o (IF message.extExecInst = << >> THEN << >> ELSE message.extExecInst[1])
        \o (IF message.echoText = << >> THEN << >> ELSE message.echoText[1])
        \o (IF message.stopPx = << >> THEN << >> ELSE message.stopPx[1])
        \o (IF message.routingInst = << >> THEN << >> ELSE message.routingInst[1])
        \o (IF message.routStrategy = << >> THEN << >> ELSE message.routStrategy[1])
        \o (IF message.routeDeliveryMethod = << >> THEN << >> ELSE message.routeDeliveryMethod[1])
        \o (IF message.exDestination = << >> THEN << >> ELSE message.exDestination[1])
        \o (IF message.crossTradeFlag = << >> THEN << >> ELSE message.crossTradeFlag[1])

DecodeOrderCancelledMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET cancelReason == ReadBytes(clOrdId.rest, 1) IN IF ~cancelReason.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(cancelReason.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET numberOfReturnBitfields == ReadUIntBE(reserved1.rest, 1) IN IF ~numberOfReturnBitfields.ok THEN Fail ELSE
    LET returnBitfield1 == ReadWhen(numberOfReturnBitfields.value >= 1, ReadUIntLE(numberOfReturnBitfields.rest, 1), numberOfReturnBitfields.rest) IN IF ~returnBitfield1.ok THEN Fail ELSE
    LET returnBitfield2 == ReadWhen(numberOfReturnBitfields.value >= 2, ReadUIntLE(returnBitfield1.rest, 1), returnBitfield1.rest) IN IF ~returnBitfield2.ok THEN Fail ELSE
    LET returnBitfield3 == ReadWhen(numberOfReturnBitfields.value >= 3, ReadUIntLE(returnBitfield2.rest, 1), returnBitfield2.rest) IN IF ~returnBitfield3.ok THEN Fail ELSE
    LET returnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadBytes(returnBitfield3.rest, 1), returnBitfield3.rest) IN IF ~returnBitfield4.ok THEN Fail ELSE
    LET returnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadUIntLE(returnBitfield4.rest, 1), returnBitfield4.rest) IN IF ~returnBitfield5.ok THEN Fail ELSE
    LET returnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadUIntLE(returnBitfield5.rest, 1), returnBitfield5.rest) IN IF ~returnBitfield6.ok THEN Fail ELSE
    LET returnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadBytes(returnBitfield6.rest, 1), returnBitfield6.rest) IN IF ~returnBitfield7.ok THEN Fail ELSE
    LET returnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadUIntLE(returnBitfield7.rest, 1), returnBitfield7.rest) IN IF ~returnBitfield8.ok THEN Fail ELSE
    LET returnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadBytes(returnBitfield8.rest, 1), returnBitfield8.rest) IN IF ~returnBitfield9.ok THEN Fail ELSE
    LET returnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadBytes(returnBitfield9.rest, 1), returnBitfield9.rest) IN IF ~returnBitfield10.ok THEN Fail ELSE
    LET returnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadBytes(returnBitfield10.rest, 1), returnBitfield10.rest) IN IF ~returnBitfield11.ok THEN Fail ELSE
    LET returnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadBytes(returnBitfield11.rest, 1), returnBitfield11.rest) IN IF ~returnBitfield12.ok THEN Fail ELSE
    LET returnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(returnBitfield12.rest, 1), returnBitfield12.rest) IN IF ~returnBitfield13.ok THEN Fail ELSE
    LET returnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(returnBitfield13.rest, 1), returnBitfield13.rest) IN IF ~returnBitfield14.ok THEN Fail ELSE
    LET returnBitfield15 == ReadWhen(numberOfReturnBitfields.value >= 15, ReadBytes(returnBitfield14.rest, 1), returnBitfield14.rest) IN IF ~returnBitfield15.ok THEN Fail ELSE
    LET returnBitfield16 == ReadWhen(numberOfReturnBitfields.value >= 16, ReadBytes(returnBitfield15.rest, 1), returnBitfield15.rest) IN IF ~returnBitfield16.ok THEN Fail ELSE
    LET returnBitfield17 == ReadWhen(numberOfReturnBitfields.value >= 17, ReadBytes(returnBitfield16.rest, 1), returnBitfield16.rest) IN IF ~returnBitfield17.ok THEN Fail ELSE
    LET returnBitfield18 == ReadWhen(numberOfReturnBitfields.value >= 18, ReadUIntLE(returnBitfield17.rest, 1), returnBitfield17.rest) IN IF ~returnBitfield18.ok THEN Fail ELSE
    LET returnBitfield19 == ReadWhen(numberOfReturnBitfields.value >= 19, ReadBytes(returnBitfield18.rest, 1), returnBitfield18.rest) IN IF ~returnBitfield19.ok THEN Fail ELSE
    LET side == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ returnBitfield1.value[1] % 2 > 0), ReadBytes(returnBitfield19.rest, 1), returnBitfield19.rest) IN IF ~side.ok THEN Fail ELSE
    LET pegDifference == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 2) % 2 > 0), ReadBytes(side.rest, 8), side.rest) IN IF ~pegDifference.ok THEN Fail ELSE
    LET price == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(pegDifference.rest, 8), pegDifference.rest) IN IF ~price.ok THEN Fail ELSE
    LET execInst == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 8) % 2 > 0), ReadBytes(price.rest, 1), price.rest) IN IF ~execInst.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(execInst.rest, 1), execInst.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET symbol == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ returnBitfield2.value[1] % 2 > 0), ReadBytes(minQty.rest, 8), minQty.rest) IN IF ~symbol.ok THEN Fail ELSE
    LET symbolSfx == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ (returnBitfield2.value[1] \div 2) % 2 > 0), ReadBytes(symbol.rest, 8), symbol.rest) IN IF ~symbolSfx.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ (returnBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(symbolSfx.rest, 1), symbolSfx.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ returnBitfield3.value[1] % 2 > 0), ReadBytes(capacity.rest, 16), capacity.rest) IN IF ~account.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 2) % 2 > 0), ReadBytes(account.rest, 4), account.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 4) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET displayIndicator == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 8) % 2 > 0), ReadBytes(clearingAccount.rest, 1), clearingAccount.rest) IN IF ~displayIndicator.ok THEN Fail ELSE
    LET maxFloor == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 16) % 2 > 0), ReadBytes(displayIndicator.rest, 4), displayIndicator.rest) IN IF ~maxFloor.ok THEN Fail ELSE
    LET discretionAmount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 32) % 2 > 0), ReadBytes(maxFloor.rest, 2), maxFloor.rest) IN IF ~discretionAmount.ok THEN Fail ELSE
    LET orderQty == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 64) % 2 > 0), ReadBytes(discretionAmount.rest, 4), discretionAmount.rest) IN IF ~orderQty.ok THEN Fail ELSE
    LET preventMatch == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 128) % 2 > 0), ReadBytes(orderQty.rest, 3), orderQty.rest) IN IF ~preventMatch.ok THEN Fail ELSE
    LET origClOrdId == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ returnBitfield5.value[1] % 2 > 0), ReadBytes(preventMatch.rest, 20), preventMatch.rest) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET leavesQty == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 2) % 2 > 0), ReadBytes(origClOrdId.rest, 4), origClOrdId.rest) IN IF ~leavesQty.ok THEN Fail ELSE
    LET lastShares == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 4) % 2 > 0), ReadBytes(leavesQty.rest, 4), leavesQty.rest) IN IF ~lastShares.ok THEN Fail ELSE
    LET lastPx == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 8) % 2 > 0), ReadBytes(lastShares.rest, 8), lastShares.rest) IN IF ~lastPx.ok THEN Fail ELSE
    LET displayPrice == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 16) % 2 > 0), ReadBytes(lastPx.rest, 8), lastPx.rest) IN IF ~displayPrice.ok THEN Fail ELSE
    LET workingPrice == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 32) % 2 > 0), ReadBytes(displayPrice.rest, 8), displayPrice.rest) IN IF ~workingPrice.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 64) % 2 > 0), ReadBytes(workingPrice.rest, 1), workingPrice.rest) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET expireTime == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 128) % 2 > 0), ReadBytes(baseLiquidityIndicator.rest, 8), baseLiquidityIndicator.rest) IN IF ~expireTime.ok THEN Fail ELSE
    LET secondaryOrderId == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (returnBitfield6.value # << >> /\ returnBitfield6.value[1] % 2 > 0), ReadBytes(expireTime.rest, 8), expireTime.rest) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET attributedQuote == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (returnBitfield6.value # << >> /\ (returnBitfield6.value[1] \div 8) % 2 > 0), ReadBytes(secondaryOrderId.rest, 1), secondaryOrderId.rest) IN IF ~attributedQuote.ok THEN Fail ELSE
    LET extExecInst == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (returnBitfield6.value # << >> /\ (returnBitfield6.value[1] \div 16) % 2 > 0), ReadBytes(attributedQuote.rest, 1), attributedQuote.rest) IN IF ~extExecInst.ok THEN Fail ELSE
    LET echoText == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 2) % 2 > 0), ReadBytes(extExecInst.rest, 64), extExecInst.rest) IN IF ~echoText.ok THEN Fail ELSE
    LET stopPx == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 4) % 2 > 0), ReadBytes(echoText.rest, 8), echoText.rest) IN IF ~stopPx.ok THEN Fail ELSE
    LET routingInst == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 8) % 2 > 0), ReadBytes(stopPx.rest, 4), stopPx.rest) IN IF ~routingInst.ok THEN Fail ELSE
    LET routStrategy == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 16) % 2 > 0), ReadBytes(routingInst.rest, 6), routingInst.rest) IN IF ~routStrategy.ok THEN Fail ELSE
    LET routeDeliveryMethod == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 32) % 2 > 0), ReadBytes(routStrategy.rest, 3), routStrategy.rest) IN IF ~routeDeliveryMethod.ok THEN Fail ELSE
    LET exDestination == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 64) % 2 > 0), ReadBytes(routeDeliveryMethod.rest, 1), routeDeliveryMethod.rest) IN IF ~exDestination.ok THEN Fail ELSE
    LET crossTradeFlag == ReadWhen(numberOfReturnBitfields.value >= 18 /\ (returnBitfield18.value # << >> /\ (returnBitfield18.value[1] \div 8) % 2 > 0), ReadBytes(exDestination.rest, 1), exDestination.rest) IN IF ~crossTradeFlag.ok THEN Fail ELSE
    Ok([ transactionTime         |-> transactionTime.value,
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
         returnBitfield18        |-> returnBitfield18.value,
         returnBitfield19        |-> returnBitfield19.value,
         side                    |-> side.value,
         pegDifference           |-> pegDifference.value,
         price                   |-> price.value,
         execInst                |-> execInst.value,
         ordType                 |-> ordType.value,
         timeInForce             |-> timeInForce.value,
         minQty                  |-> minQty.value,
         symbol                  |-> symbol.value,
         symbolSfx               |-> symbolSfx.value,
         capacity                |-> capacity.value,
         account                 |-> account.value,
         clearingFirm            |-> clearingFirm.value,
         clearingAccount         |-> clearingAccount.value,
         displayIndicator        |-> displayIndicator.value,
         maxFloor                |-> maxFloor.value,
         discretionAmount        |-> discretionAmount.value,
         orderQty                |-> orderQty.value,
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
         attributedQuote         |-> attributedQuote.value,
         extExecInst             |-> extExecInst.value,
         echoText                |-> echoText.value,
         stopPx                  |-> stopPx.value,
         routingInst             |-> routingInst.value,
         routStrategy            |-> routStrategy.value,
         routeDeliveryMethod     |-> routeDeliveryMethod.value,
         exDestination           |-> exDestination.value,
         crossTradeFlag          |-> crossTradeFlag.value ], crossTradeFlag.rest)

(* Order Cancelled Message with each field marked present by fields before it there exactly where they say *)
SettleOrderCancelledMessage(message) ==
    LET settled1 == [message EXCEPT !.returnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.returnBitfield1 = << >> THEN <<0>> ELSE message.returnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.returnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.returnBitfield2 = << >> THEN <<0>> ELSE settled1.returnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.returnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.returnBitfield3 = << >> THEN <<0>> ELSE settled2.returnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.returnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.returnBitfield4 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled3.returnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.returnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.returnBitfield5 = << >> THEN <<0>> ELSE settled4.returnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.returnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.returnBitfield6 = << >> THEN <<0>> ELSE settled5.returnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.returnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.returnBitfield7 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.returnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.returnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.returnBitfield8 = << >> THEN <<0>> ELSE settled7.returnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.returnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.returnBitfield9 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled8.returnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.returnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.returnBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.returnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.returnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.returnBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.returnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.returnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.returnBitfield12 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.returnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.returnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.returnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.returnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.returnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.returnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.returnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.returnBitfield15 = IF settled14.numberOfReturnBitfields >= 15 THEN (IF settled14.returnBitfield15 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.returnBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.returnBitfield16 = IF settled15.numberOfReturnBitfields >= 16 THEN (IF settled15.returnBitfield16 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled15.returnBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.returnBitfield17 = IF settled16.numberOfReturnBitfields >= 17 THEN (IF settled16.returnBitfield17 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled16.returnBitfield17) ELSE << >>]
        settled18 == [settled17 EXCEPT !.returnBitfield18 = IF settled17.numberOfReturnBitfields >= 18 THEN (IF settled17.returnBitfield18 = << >> THEN <<0>> ELSE settled17.returnBitfield18) ELSE << >>]
        settled19 == [settled18 EXCEPT !.returnBitfield19 = IF settled18.numberOfReturnBitfields >= 19 THEN (IF settled18.returnBitfield19 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled18.returnBitfield19) ELSE << >>]
        settled20 == [settled19 EXCEPT !.side = IF settled19.numberOfReturnBitfields >= 1 /\ (settled19.returnBitfield1 # << >> /\ settled19.returnBitfield1[1] % 2 > 0) THEN (IF settled19.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled19.side) ELSE << >>]
        settled21 == [settled20 EXCEPT !.pegDifference = IF settled20.numberOfReturnBitfields >= 1 /\ (settled20.returnBitfield1 # << >> /\ (settled20.returnBitfield1[1] \div 2) % 2 > 0) THEN (IF settled20.pegDifference = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled20.pegDifference) ELSE << >>]
        settled22 == [settled21 EXCEPT !.price = IF settled21.numberOfReturnBitfields >= 1 /\ (settled21.returnBitfield1 # << >> /\ (settled21.returnBitfield1[1] \div 4) % 2 > 0) THEN (IF settled21.price = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled21.price) ELSE << >>]
        settled23 == [settled22 EXCEPT !.execInst = IF settled22.numberOfReturnBitfields >= 1 /\ (settled22.returnBitfield1 # << >> /\ (settled22.returnBitfield1[1] \div 8) % 2 > 0) THEN (IF settled22.execInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled22.execInst) ELSE << >>]
        settled24 == [settled23 EXCEPT !.ordType = IF settled23.numberOfReturnBitfields >= 1 /\ (settled23.returnBitfield1 # << >> /\ (settled23.returnBitfield1[1] \div 16) % 2 > 0) THEN (IF settled23.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled23.ordType) ELSE << >>]
        settled25 == [settled24 EXCEPT !.timeInForce = IF settled24.numberOfReturnBitfields >= 1 /\ (settled24.returnBitfield1 # << >> /\ (settled24.returnBitfield1[1] \div 32) % 2 > 0) THEN (IF settled24.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled24.timeInForce) ELSE << >>]
        settled26 == [settled25 EXCEPT !.minQty = IF settled25.numberOfReturnBitfields >= 1 /\ (settled25.returnBitfield1 # << >> /\ (settled25.returnBitfield1[1] \div 64) % 2 > 0) THEN (IF settled25.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled25.minQty) ELSE << >>]
        settled27 == [settled26 EXCEPT !.symbol = IF settled26.numberOfReturnBitfields >= 2 /\ (settled26.returnBitfield2 # << >> /\ settled26.returnBitfield2[1] % 2 > 0) THEN (IF settled26.symbol = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled26.symbol) ELSE << >>]
        settled28 == [settled27 EXCEPT !.symbolSfx = IF settled27.numberOfReturnBitfields >= 2 /\ (settled27.returnBitfield2 # << >> /\ (settled27.returnBitfield2[1] \div 2) % 2 > 0) THEN (IF settled27.symbolSfx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled27.symbolSfx) ELSE << >>]
        settled29 == [settled28 EXCEPT !.capacity = IF settled28.numberOfReturnBitfields >= 2 /\ (settled28.returnBitfield2 # << >> /\ (settled28.returnBitfield2[1] \div 64) % 2 > 0) THEN (IF settled28.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled28.capacity) ELSE << >>]
        settled30 == [settled29 EXCEPT !.account = IF settled29.numberOfReturnBitfields >= 3 /\ (settled29.returnBitfield3 # << >> /\ settled29.returnBitfield3[1] % 2 > 0) THEN (IF settled29.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled29.account) ELSE << >>]
        settled31 == [settled30 EXCEPT !.clearingFirm = IF settled30.numberOfReturnBitfields >= 3 /\ (settled30.returnBitfield3 # << >> /\ (settled30.returnBitfield3[1] \div 2) % 2 > 0) THEN (IF settled30.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled30.clearingFirm) ELSE << >>]
        settled32 == [settled31 EXCEPT !.clearingAccount = IF settled31.numberOfReturnBitfields >= 3 /\ (settled31.returnBitfield3 # << >> /\ (settled31.returnBitfield3[1] \div 4) % 2 > 0) THEN (IF settled31.clearingAccount = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled31.clearingAccount) ELSE << >>]
        settled33 == [settled32 EXCEPT !.displayIndicator = IF settled32.numberOfReturnBitfields >= 3 /\ (settled32.returnBitfield3 # << >> /\ (settled32.returnBitfield3[1] \div 8) % 2 > 0) THEN (IF settled32.displayIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled32.displayIndicator) ELSE << >>]
        settled34 == [settled33 EXCEPT !.maxFloor = IF settled33.numberOfReturnBitfields >= 3 /\ (settled33.returnBitfield3 # << >> /\ (settled33.returnBitfield3[1] \div 16) % 2 > 0) THEN (IF settled33.maxFloor = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled33.maxFloor) ELSE << >>]
        settled35 == [settled34 EXCEPT !.discretionAmount = IF settled34.numberOfReturnBitfields >= 3 /\ (settled34.returnBitfield3 # << >> /\ (settled34.returnBitfield3[1] \div 32) % 2 > 0) THEN (IF settled34.discretionAmount = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled34.discretionAmount) ELSE << >>]
        settled36 == [settled35 EXCEPT !.orderQty = IF settled35.numberOfReturnBitfields >= 3 /\ (settled35.returnBitfield3 # << >> /\ (settled35.returnBitfield3[1] \div 64) % 2 > 0) THEN (IF settled35.orderQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled35.orderQty) ELSE << >>]
        settled37 == [settled36 EXCEPT !.preventMatch = IF settled36.numberOfReturnBitfields >= 3 /\ (settled36.returnBitfield3 # << >> /\ (settled36.returnBitfield3[1] \div 128) % 2 > 0) THEN (IF settled36.preventMatch = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled36.preventMatch) ELSE << >>]
        settled38 == [settled37 EXCEPT !.origClOrdId = IF settled37.numberOfReturnBitfields >= 5 /\ (settled37.returnBitfield5 # << >> /\ settled37.returnBitfield5[1] % 2 > 0) THEN (IF settled37.origClOrdId = << >> THEN <<[i \in 1 .. 20 |-> 0]>> ELSE settled37.origClOrdId) ELSE << >>]
        settled39 == [settled38 EXCEPT !.leavesQty = IF settled38.numberOfReturnBitfields >= 5 /\ (settled38.returnBitfield5 # << >> /\ (settled38.returnBitfield5[1] \div 2) % 2 > 0) THEN (IF settled38.leavesQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled38.leavesQty) ELSE << >>]
        settled40 == [settled39 EXCEPT !.lastShares = IF settled39.numberOfReturnBitfields >= 5 /\ (settled39.returnBitfield5 # << >> /\ (settled39.returnBitfield5[1] \div 4) % 2 > 0) THEN (IF settled39.lastShares = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled39.lastShares) ELSE << >>]
        settled41 == [settled40 EXCEPT !.lastPx = IF settled40.numberOfReturnBitfields >= 5 /\ (settled40.returnBitfield5 # << >> /\ (settled40.returnBitfield5[1] \div 8) % 2 > 0) THEN (IF settled40.lastPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled40.lastPx) ELSE << >>]
        settled42 == [settled41 EXCEPT !.displayPrice = IF settled41.numberOfReturnBitfields >= 5 /\ (settled41.returnBitfield5 # << >> /\ (settled41.returnBitfield5[1] \div 16) % 2 > 0) THEN (IF settled41.displayPrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled41.displayPrice) ELSE << >>]
        settled43 == [settled42 EXCEPT !.workingPrice = IF settled42.numberOfReturnBitfields >= 5 /\ (settled42.returnBitfield5 # << >> /\ (settled42.returnBitfield5[1] \div 32) % 2 > 0) THEN (IF settled42.workingPrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled42.workingPrice) ELSE << >>]
        settled44 == [settled43 EXCEPT !.baseLiquidityIndicator = IF settled43.numberOfReturnBitfields >= 5 /\ (settled43.returnBitfield5 # << >> /\ (settled43.returnBitfield5[1] \div 64) % 2 > 0) THEN (IF settled43.baseLiquidityIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled43.baseLiquidityIndicator) ELSE << >>]
        settled45 == [settled44 EXCEPT !.expireTime = IF settled44.numberOfReturnBitfields >= 5 /\ (settled44.returnBitfield5 # << >> /\ (settled44.returnBitfield5[1] \div 128) % 2 > 0) THEN (IF settled44.expireTime = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled44.expireTime) ELSE << >>]
        settled46 == [settled45 EXCEPT !.secondaryOrderId = IF settled45.numberOfReturnBitfields >= 6 /\ (settled45.returnBitfield6 # << >> /\ settled45.returnBitfield6[1] % 2 > 0) THEN (IF settled45.secondaryOrderId = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled45.secondaryOrderId) ELSE << >>]
        settled47 == [settled46 EXCEPT !.attributedQuote = IF settled46.numberOfReturnBitfields >= 6 /\ (settled46.returnBitfield6 # << >> /\ (settled46.returnBitfield6[1] \div 8) % 2 > 0) THEN (IF settled46.attributedQuote = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled46.attributedQuote) ELSE << >>]
        settled48 == [settled47 EXCEPT !.extExecInst = IF settled47.numberOfReturnBitfields >= 6 /\ (settled47.returnBitfield6 # << >> /\ (settled47.returnBitfield6[1] \div 16) % 2 > 0) THEN (IF settled47.extExecInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled47.extExecInst) ELSE << >>]
        settled49 == [settled48 EXCEPT !.echoText = IF settled48.numberOfReturnBitfields >= 8 /\ (settled48.returnBitfield8 # << >> /\ (settled48.returnBitfield8[1] \div 2) % 2 > 0) THEN (IF settled48.echoText = << >> THEN <<[i \in 1 .. 64 |-> 0]>> ELSE settled48.echoText) ELSE << >>]
        settled50 == [settled49 EXCEPT !.stopPx = IF settled49.numberOfReturnBitfields >= 8 /\ (settled49.returnBitfield8 # << >> /\ (settled49.returnBitfield8[1] \div 4) % 2 > 0) THEN (IF settled49.stopPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled49.stopPx) ELSE << >>]
        settled51 == [settled50 EXCEPT !.routingInst = IF settled50.numberOfReturnBitfields >= 8 /\ (settled50.returnBitfield8 # << >> /\ (settled50.returnBitfield8[1] \div 8) % 2 > 0) THEN (IF settled50.routingInst = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled50.routingInst) ELSE << >>]
        settled52 == [settled51 EXCEPT !.routStrategy = IF settled51.numberOfReturnBitfields >= 8 /\ (settled51.returnBitfield8 # << >> /\ (settled51.returnBitfield8[1] \div 16) % 2 > 0) THEN (IF settled51.routStrategy = << >> THEN <<[i \in 1 .. 6 |-> 0]>> ELSE settled51.routStrategy) ELSE << >>]
        settled53 == [settled52 EXCEPT !.routeDeliveryMethod = IF settled52.numberOfReturnBitfields >= 8 /\ (settled52.returnBitfield8 # << >> /\ (settled52.returnBitfield8[1] \div 32) % 2 > 0) THEN (IF settled52.routeDeliveryMethod = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled52.routeDeliveryMethod) ELSE << >>]
        settled54 == [settled53 EXCEPT !.exDestination = IF settled53.numberOfReturnBitfields >= 8 /\ (settled53.returnBitfield8 # << >> /\ (settled53.returnBitfield8[1] \div 64) % 2 > 0) THEN (IF settled53.exDestination = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled53.exDestination) ELSE << >>]
        settled55 == [settled54 EXCEPT !.crossTradeFlag = IF settled54.numberOfReturnBitfields >= 18 /\ (settled54.returnBitfield18 # << >> /\ (settled54.returnBitfield18[1] \div 8) % 2 > 0) THEN (IF settled54.crossTradeFlag = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled54.crossTradeFlag) ELSE << >>]
    IN  settled55

ZeroOrderCancelledMessage ==
    SettleOrderCancelledMessage([ transactionTime         |-> [i \in 1 .. 8 |-> 0],
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
                                  returnBitfield18        |-> << >>,
                                  returnBitfield19        |-> << >>,
                                  side                    |-> << >>,
                                  pegDifference           |-> << >>,
                                  price                   |-> << >>,
                                  execInst                |-> << >>,
                                  ordType                 |-> << >>,
                                  timeInForce             |-> << >>,
                                  minQty                  |-> << >>,
                                  symbol                  |-> << >>,
                                  symbolSfx               |-> << >>,
                                  capacity                |-> << >>,
                                  account                 |-> << >>,
                                  clearingFirm            |-> << >>,
                                  clearingAccount         |-> << >>,
                                  displayIndicator        |-> << >>,
                                  maxFloor                |-> << >>,
                                  discretionAmount        |-> << >>,
                                  orderQty                |-> << >>,
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
                                  attributedQuote         |-> << >>,
                                  extExecInst             |-> << >>,
                                  echoText                |-> << >>,
                                  stopPx                  |-> << >>,
                                  routingInst             |-> << >>,
                                  routStrategy            |-> << >>,
                                  routeDeliveryMethod     |-> << >>,
                                  exDestination           |-> << >>,
                                  crossTradeFlag          |-> << >> ])

(* Order Cancelled Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelledMessage ==
    { ZeroOrderCancelledMessage }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.transactionTime = one]) : one \in Sample(8) }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.clOrdId = one]) : one \in Sample(20) }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.cancelReason = one]) : one \in Sample(1) }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.reserved1 = one]) : one \in Sample(1) }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 7, !.returnBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 9, !.returnBitfield9 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 10, !.returnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 11, !.returnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 13, !.returnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 14, !.returnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 15, !.returnBitfield15 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 17, !.returnBitfield17 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 18, !.returnBitfield18 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 19, !.returnBitfield19 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<1>>, !.side = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<2>>, !.pegDifference = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<4>>, !.price = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<8>>, !.execInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<1>>, !.symbol = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<2>>, !.symbolSfx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<1>>, !.account = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<2>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<4>>, !.clearingAccount = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<8>>, !.displayIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<16>>, !.maxFloor = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<32>>, !.discretionAmount = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<64>>, !.orderQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<128>>, !.preventMatch = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<1>>, !.origClOrdId = one]) : one \in { <<held>> : held \in Sample(20) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<2>>, !.leavesQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<4>>, !.lastShares = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<8>>, !.lastPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<16>>, !.displayPrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<32>>, !.workingPrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<64>>, !.baseLiquidityIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<128>>, !.expireTime = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = <<1>>, !.secondaryOrderId = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = <<8>>, !.attributedQuote = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = <<16>>, !.extExecInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<2>>, !.echoText = one]) : one \in { <<held>> : held \in Sample(64) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<4>>, !.stopPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<8>>, !.routingInst = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<16>>, !.routStrategy = one]) : one \in { <<held>> : held \in Sample(6) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<32>>, !.routeDeliveryMethod = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<64>>, !.exDestination = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 18, !.returnBitfield18 = <<8>>, !.crossTradeFlag = one]) : one \in { <<held>> : held \in Sample(1) } }

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
      returnBitfield4         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield5         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield6         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield7         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield8         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield9         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield10        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield11        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield12        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield13        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield14        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield15        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield16        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield17        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield18        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield19        : { << >> } \cup { <<held>> : held \in Sample(1) },
      side                    : { << >> } \cup { <<held>> : held \in Sample(1) },
      pegDifference           : { << >> } \cup { <<held>> : held \in Sample(8) },
      price                   : { << >> } \cup { <<held>> : held \in Sample(8) },
      execInst                : { << >> } \cup { <<held>> : held \in Sample(1) },
      ordType                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce             : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                  : { << >> } \cup { <<held>> : held \in Sample(4) },
      symbol                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      symbolSfx               : { << >> } \cup { <<held>> : held \in Sample(8) },
      capacity                : { << >> } \cup { <<held>> : held \in Sample(1) },
      echoText                : { << >> } \cup { <<held>> : held \in Sample(64) },
      stopPx                  : { << >> } \cup { <<held>> : held \in Sample(8) } ]

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
        \o (IF message.returnBitfield4 = << >> THEN << >> ELSE message.returnBitfield4[1])
        \o (IF message.returnBitfield5 = << >> THEN << >> ELSE message.returnBitfield5[1])
        \o (IF message.returnBitfield6 = << >> THEN << >> ELSE message.returnBitfield6[1])
        \o (IF message.returnBitfield7 = << >> THEN << >> ELSE message.returnBitfield7[1])
        \o (IF message.returnBitfield8 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield8[1], 1))
        \o (IF message.returnBitfield9 = << >> THEN << >> ELSE message.returnBitfield9[1])
        \o (IF message.returnBitfield10 = << >> THEN << >> ELSE message.returnBitfield10[1])
        \o (IF message.returnBitfield11 = << >> THEN << >> ELSE message.returnBitfield11[1])
        \o (IF message.returnBitfield12 = << >> THEN << >> ELSE message.returnBitfield12[1])
        \o (IF message.returnBitfield13 = << >> THEN << >> ELSE message.returnBitfield13[1])
        \o (IF message.returnBitfield14 = << >> THEN << >> ELSE message.returnBitfield14[1])
        \o (IF message.returnBitfield15 = << >> THEN << >> ELSE message.returnBitfield15[1])
        \o (IF message.returnBitfield16 = << >> THEN << >> ELSE message.returnBitfield16[1])
        \o (IF message.returnBitfield17 = << >> THEN << >> ELSE message.returnBitfield17[1])
        \o (IF message.returnBitfield18 = << >> THEN << >> ELSE message.returnBitfield18[1])
        \o (IF message.returnBitfield19 = << >> THEN << >> ELSE message.returnBitfield19[1])
        \o (IF message.side = << >> THEN << >> ELSE message.side[1])
        \o (IF message.pegDifference = << >> THEN << >> ELSE message.pegDifference[1])
        \o (IF message.price = << >> THEN << >> ELSE message.price[1])
        \o (IF message.execInst = << >> THEN << >> ELSE message.execInst[1])
        \o (IF message.ordType = << >> THEN << >> ELSE message.ordType[1])
        \o (IF message.timeInForce = << >> THEN << >> ELSE message.timeInForce[1])
        \o (IF message.minQty = << >> THEN << >> ELSE message.minQty[1])
        \o (IF message.symbol = << >> THEN << >> ELSE message.symbol[1])
        \o (IF message.symbolSfx = << >> THEN << >> ELSE message.symbolSfx[1])
        \o (IF message.capacity = << >> THEN << >> ELSE message.capacity[1])
        \o (IF message.echoText = << >> THEN << >> ELSE message.echoText[1])
        \o (IF message.stopPx = << >> THEN << >> ELSE message.stopPx[1])

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
    LET returnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadBytes(returnBitfield3.rest, 1), returnBitfield3.rest) IN IF ~returnBitfield4.ok THEN Fail ELSE
    LET returnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadBytes(returnBitfield4.rest, 1), returnBitfield4.rest) IN IF ~returnBitfield5.ok THEN Fail ELSE
    LET returnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadBytes(returnBitfield5.rest, 1), returnBitfield5.rest) IN IF ~returnBitfield6.ok THEN Fail ELSE
    LET returnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadBytes(returnBitfield6.rest, 1), returnBitfield6.rest) IN IF ~returnBitfield7.ok THEN Fail ELSE
    LET returnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadUIntLE(returnBitfield7.rest, 1), returnBitfield7.rest) IN IF ~returnBitfield8.ok THEN Fail ELSE
    LET returnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadBytes(returnBitfield8.rest, 1), returnBitfield8.rest) IN IF ~returnBitfield9.ok THEN Fail ELSE
    LET returnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadBytes(returnBitfield9.rest, 1), returnBitfield9.rest) IN IF ~returnBitfield10.ok THEN Fail ELSE
    LET returnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadBytes(returnBitfield10.rest, 1), returnBitfield10.rest) IN IF ~returnBitfield11.ok THEN Fail ELSE
    LET returnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadBytes(returnBitfield11.rest, 1), returnBitfield11.rest) IN IF ~returnBitfield12.ok THEN Fail ELSE
    LET returnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(returnBitfield12.rest, 1), returnBitfield12.rest) IN IF ~returnBitfield13.ok THEN Fail ELSE
    LET returnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(returnBitfield13.rest, 1), returnBitfield13.rest) IN IF ~returnBitfield14.ok THEN Fail ELSE
    LET returnBitfield15 == ReadWhen(numberOfReturnBitfields.value >= 15, ReadBytes(returnBitfield14.rest, 1), returnBitfield14.rest) IN IF ~returnBitfield15.ok THEN Fail ELSE
    LET returnBitfield16 == ReadWhen(numberOfReturnBitfields.value >= 16, ReadBytes(returnBitfield15.rest, 1), returnBitfield15.rest) IN IF ~returnBitfield16.ok THEN Fail ELSE
    LET returnBitfield17 == ReadWhen(numberOfReturnBitfields.value >= 17, ReadBytes(returnBitfield16.rest, 1), returnBitfield16.rest) IN IF ~returnBitfield17.ok THEN Fail ELSE
    LET returnBitfield18 == ReadWhen(numberOfReturnBitfields.value >= 18, ReadBytes(returnBitfield17.rest, 1), returnBitfield17.rest) IN IF ~returnBitfield18.ok THEN Fail ELSE
    LET returnBitfield19 == ReadWhen(numberOfReturnBitfields.value >= 19, ReadBytes(returnBitfield18.rest, 1), returnBitfield18.rest) IN IF ~returnBitfield19.ok THEN Fail ELSE
    LET side == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ returnBitfield1.value[1] % 2 > 0), ReadBytes(returnBitfield19.rest, 1), returnBitfield19.rest) IN IF ~side.ok THEN Fail ELSE
    LET pegDifference == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 2) % 2 > 0), ReadBytes(side.rest, 8), side.rest) IN IF ~pegDifference.ok THEN Fail ELSE
    LET price == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(pegDifference.rest, 8), pegDifference.rest) IN IF ~price.ok THEN Fail ELSE
    LET execInst == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 8) % 2 > 0), ReadBytes(price.rest, 1), price.rest) IN IF ~execInst.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(execInst.rest, 1), execInst.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET symbol == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ returnBitfield2.value[1] % 2 > 0), ReadBytes(minQty.rest, 8), minQty.rest) IN IF ~symbol.ok THEN Fail ELSE
    LET symbolSfx == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ (returnBitfield2.value[1] \div 2) % 2 > 0), ReadBytes(symbol.rest, 8), symbol.rest) IN IF ~symbolSfx.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ (returnBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(symbolSfx.rest, 1), symbolSfx.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET echoText == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 2) % 2 > 0), ReadBytes(capacity.rest, 64), capacity.rest) IN IF ~echoText.ok THEN Fail ELSE
    LET stopPx == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 4) % 2 > 0), ReadBytes(echoText.rest, 8), echoText.rest) IN IF ~stopPx.ok THEN Fail ELSE
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
         returnBitfield18        |-> returnBitfield18.value,
         returnBitfield19        |-> returnBitfield19.value,
         side                    |-> side.value,
         pegDifference           |-> pegDifference.value,
         price                   |-> price.value,
         execInst                |-> execInst.value,
         ordType                 |-> ordType.value,
         timeInForce             |-> timeInForce.value,
         minQty                  |-> minQty.value,
         symbol                  |-> symbol.value,
         symbolSfx               |-> symbolSfx.value,
         capacity                |-> capacity.value,
         echoText                |-> echoText.value,
         stopPx                  |-> stopPx.value ], stopPx.rest)

(* Cancel Rejected Message with each field marked present by fields before it there exactly where they say *)
SettleCancelRejectedMessage(message) ==
    LET settled1 == [message EXCEPT !.returnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.returnBitfield1 = << >> THEN <<0>> ELSE message.returnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.returnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.returnBitfield2 = << >> THEN <<0>> ELSE settled1.returnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.returnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.returnBitfield3 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled2.returnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.returnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.returnBitfield4 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled3.returnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.returnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.returnBitfield5 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled4.returnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.returnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.returnBitfield6 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled5.returnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.returnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.returnBitfield7 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.returnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.returnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.returnBitfield8 = << >> THEN <<0>> ELSE settled7.returnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.returnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.returnBitfield9 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled8.returnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.returnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.returnBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.returnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.returnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.returnBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.returnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.returnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.returnBitfield12 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.returnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.returnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.returnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.returnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.returnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.returnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.returnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.returnBitfield15 = IF settled14.numberOfReturnBitfields >= 15 THEN (IF settled14.returnBitfield15 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.returnBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.returnBitfield16 = IF settled15.numberOfReturnBitfields >= 16 THEN (IF settled15.returnBitfield16 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled15.returnBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.returnBitfield17 = IF settled16.numberOfReturnBitfields >= 17 THEN (IF settled16.returnBitfield17 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled16.returnBitfield17) ELSE << >>]
        settled18 == [settled17 EXCEPT !.returnBitfield18 = IF settled17.numberOfReturnBitfields >= 18 THEN (IF settled17.returnBitfield18 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.returnBitfield18) ELSE << >>]
        settled19 == [settled18 EXCEPT !.returnBitfield19 = IF settled18.numberOfReturnBitfields >= 19 THEN (IF settled18.returnBitfield19 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled18.returnBitfield19) ELSE << >>]
        settled20 == [settled19 EXCEPT !.side = IF settled19.numberOfReturnBitfields >= 1 /\ (settled19.returnBitfield1 # << >> /\ settled19.returnBitfield1[1] % 2 > 0) THEN (IF settled19.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled19.side) ELSE << >>]
        settled21 == [settled20 EXCEPT !.pegDifference = IF settled20.numberOfReturnBitfields >= 1 /\ (settled20.returnBitfield1 # << >> /\ (settled20.returnBitfield1[1] \div 2) % 2 > 0) THEN (IF settled20.pegDifference = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled20.pegDifference) ELSE << >>]
        settled22 == [settled21 EXCEPT !.price = IF settled21.numberOfReturnBitfields >= 1 /\ (settled21.returnBitfield1 # << >> /\ (settled21.returnBitfield1[1] \div 4) % 2 > 0) THEN (IF settled21.price = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled21.price) ELSE << >>]
        settled23 == [settled22 EXCEPT !.execInst = IF settled22.numberOfReturnBitfields >= 1 /\ (settled22.returnBitfield1 # << >> /\ (settled22.returnBitfield1[1] \div 8) % 2 > 0) THEN (IF settled22.execInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled22.execInst) ELSE << >>]
        settled24 == [settled23 EXCEPT !.ordType = IF settled23.numberOfReturnBitfields >= 1 /\ (settled23.returnBitfield1 # << >> /\ (settled23.returnBitfield1[1] \div 16) % 2 > 0) THEN (IF settled23.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled23.ordType) ELSE << >>]
        settled25 == [settled24 EXCEPT !.timeInForce = IF settled24.numberOfReturnBitfields >= 1 /\ (settled24.returnBitfield1 # << >> /\ (settled24.returnBitfield1[1] \div 32) % 2 > 0) THEN (IF settled24.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled24.timeInForce) ELSE << >>]
        settled26 == [settled25 EXCEPT !.minQty = IF settled25.numberOfReturnBitfields >= 1 /\ (settled25.returnBitfield1 # << >> /\ (settled25.returnBitfield1[1] \div 64) % 2 > 0) THEN (IF settled25.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled25.minQty) ELSE << >>]
        settled27 == [settled26 EXCEPT !.symbol = IF settled26.numberOfReturnBitfields >= 2 /\ (settled26.returnBitfield2 # << >> /\ settled26.returnBitfield2[1] % 2 > 0) THEN (IF settled26.symbol = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled26.symbol) ELSE << >>]
        settled28 == [settled27 EXCEPT !.symbolSfx = IF settled27.numberOfReturnBitfields >= 2 /\ (settled27.returnBitfield2 # << >> /\ (settled27.returnBitfield2[1] \div 2) % 2 > 0) THEN (IF settled27.symbolSfx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled27.symbolSfx) ELSE << >>]
        settled29 == [settled28 EXCEPT !.capacity = IF settled28.numberOfReturnBitfields >= 2 /\ (settled28.returnBitfield2 # << >> /\ (settled28.returnBitfield2[1] \div 64) % 2 > 0) THEN (IF settled28.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled28.capacity) ELSE << >>]
        settled30 == [settled29 EXCEPT !.echoText = IF settled29.numberOfReturnBitfields >= 8 /\ (settled29.returnBitfield8 # << >> /\ (settled29.returnBitfield8[1] \div 2) % 2 > 0) THEN (IF settled29.echoText = << >> THEN <<[i \in 1 .. 64 |-> 0]>> ELSE settled29.echoText) ELSE << >>]
        settled31 == [settled30 EXCEPT !.stopPx = IF settled30.numberOfReturnBitfields >= 8 /\ (settled30.returnBitfield8 # << >> /\ (settled30.returnBitfield8[1] \div 4) % 2 > 0) THEN (IF settled30.stopPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled30.stopPx) ELSE << >>]
    IN  settled31

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
                                  returnBitfield18        |-> << >>,
                                  returnBitfield19        |-> << >>,
                                  side                    |-> << >>,
                                  pegDifference           |-> << >>,
                                  price                   |-> << >>,
                                  execInst                |-> << >>,
                                  ordType                 |-> << >>,
                                  timeInForce             |-> << >>,
                                  minQty                  |-> << >>,
                                  symbol                  |-> << >>,
                                  symbolSfx               |-> << >>,
                                  capacity                |-> << >>,
                                  echoText                |-> << >>,
                                  stopPx                  |-> << >> ])

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
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 7, !.returnBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 9, !.returnBitfield9 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 10, !.returnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 11, !.returnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 13, !.returnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 14, !.returnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 15, !.returnBitfield15 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 17, !.returnBitfield17 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 18, !.returnBitfield18 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 19, !.returnBitfield19 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<1>>, !.side = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<2>>, !.pegDifference = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<4>>, !.price = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<8>>, !.execInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<1>>, !.symbol = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<2>>, !.symbolSfx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<2>>, !.echoText = one]) : one \in { <<held>> : held \in Sample(64) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<4>>, !.stopPx = one]) : one \in { <<held>> : held \in Sample(8) } }

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
      returnBitfield4         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield5         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield6         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield7         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield8         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield9         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield10        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield11        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield12        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield13        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield14        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield15        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield16        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield17        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield18        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield19        : { << >> } \cup { <<held>> : held \in Sample(1) },
      side                    : { << >> } \cup { <<held>> : held \in Sample(1) },
      pegDifference           : { << >> } \cup { <<held>> : held \in Sample(8) },
      price                   : { << >> } \cup { <<held>> : held \in Sample(8) },
      execInst                : { << >> } \cup { <<held>> : held \in Sample(1) },
      ordType                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce             : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                  : { << >> } \cup { <<held>> : held \in Sample(4) },
      symbol                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      symbolSfx               : { << >> } \cup { <<held>> : held \in Sample(8) },
      capacity                : { << >> } \cup { <<held>> : held \in Sample(1) },
      account                 : { << >> } \cup { <<held>> : held \in Sample(16) },
      clearingFirm            : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingAccount         : { << >> } \cup { <<held>> : held \in Sample(4) },
      displayIndicator        : { << >> } \cup { <<held>> : held \in Sample(1) },
      maxFloor                : { << >> } \cup { <<held>> : held \in Sample(4) },
      discretionAmount        : { << >> } \cup { <<held>> : held \in Sample(2) },
      orderQty                : { << >> } \cup { <<held>> : held \in Sample(4) },
      preventMatch            : { << >> } \cup { <<held>> : held \in Sample(3) },
      attributedQuote         : { << >> } \cup { <<held>> : held \in Sample(1) },
      extExecInst             : { << >> } \cup { <<held>> : held \in Sample(1) },
      feeCode                 : { << >> } \cup { <<held>> : held \in Sample(2) },
      echoText                : { << >> } \cup { <<held>> : held \in Sample(64) },
      stopPx                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      routingInst             : { << >> } \cup { <<held>> : held \in Sample(4) },
      routStrategy            : { << >> } \cup { <<held>> : held \in Sample(6) },
      routeDeliveryMethod     : { << >> } \cup { <<held>> : held \in Sample(3) },
      exDestination           : { << >> } \cup { <<held>> : held \in Sample(1) },
      crossTradeFlag          : { << >> } \cup { <<held>> : held \in Sample(1) },
      locateBroker            : { << >> } \cup { <<held>> : held \in Sample(4) } ]

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
        \o (IF message.returnBitfield4 = << >> THEN << >> ELSE message.returnBitfield4[1])
        \o (IF message.returnBitfield5 = << >> THEN << >> ELSE message.returnBitfield5[1])
        \o (IF message.returnBitfield6 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield6[1], 1))
        \o (IF message.returnBitfield7 = << >> THEN << >> ELSE message.returnBitfield7[1])
        \o (IF message.returnBitfield8 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield8[1], 1))
        \o (IF message.returnBitfield9 = << >> THEN << >> ELSE message.returnBitfield9[1])
        \o (IF message.returnBitfield10 = << >> THEN << >> ELSE message.returnBitfield10[1])
        \o (IF message.returnBitfield11 = << >> THEN << >> ELSE message.returnBitfield11[1])
        \o (IF message.returnBitfield12 = << >> THEN << >> ELSE message.returnBitfield12[1])
        \o (IF message.returnBitfield13 = << >> THEN << >> ELSE message.returnBitfield13[1])
        \o (IF message.returnBitfield14 = << >> THEN << >> ELSE message.returnBitfield14[1])
        \o (IF message.returnBitfield15 = << >> THEN << >> ELSE message.returnBitfield15[1])
        \o (IF message.returnBitfield16 = << >> THEN << >> ELSE message.returnBitfield16[1])
        \o (IF message.returnBitfield17 = << >> THEN << >> ELSE message.returnBitfield17[1])
        \o (IF message.returnBitfield18 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield18[1], 1))
        \o (IF message.returnBitfield19 = << >> THEN << >> ELSE message.returnBitfield19[1])
        \o (IF message.side = << >> THEN << >> ELSE message.side[1])
        \o (IF message.pegDifference = << >> THEN << >> ELSE message.pegDifference[1])
        \o (IF message.price = << >> THEN << >> ELSE message.price[1])
        \o (IF message.execInst = << >> THEN << >> ELSE message.execInst[1])
        \o (IF message.ordType = << >> THEN << >> ELSE message.ordType[1])
        \o (IF message.timeInForce = << >> THEN << >> ELSE message.timeInForce[1])
        \o (IF message.minQty = << >> THEN << >> ELSE message.minQty[1])
        \o (IF message.symbol = << >> THEN << >> ELSE message.symbol[1])
        \o (IF message.symbolSfx = << >> THEN << >> ELSE message.symbolSfx[1])
        \o (IF message.capacity = << >> THEN << >> ELSE message.capacity[1])
        \o (IF message.account = << >> THEN << >> ELSE message.account[1])
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])
        \o (IF message.clearingAccount = << >> THEN << >> ELSE message.clearingAccount[1])
        \o (IF message.displayIndicator = << >> THEN << >> ELSE message.displayIndicator[1])
        \o (IF message.maxFloor = << >> THEN << >> ELSE message.maxFloor[1])
        \o (IF message.discretionAmount = << >> THEN << >> ELSE message.discretionAmount[1])
        \o (IF message.orderQty = << >> THEN << >> ELSE message.orderQty[1])
        \o (IF message.preventMatch = << >> THEN << >> ELSE message.preventMatch[1])
        \o (IF message.attributedQuote = << >> THEN << >> ELSE message.attributedQuote[1])
        \o (IF message.extExecInst = << >> THEN << >> ELSE message.extExecInst[1])
        \o (IF message.feeCode = << >> THEN << >> ELSE message.feeCode[1])
        \o (IF message.echoText = << >> THEN << >> ELSE message.echoText[1])
        \o (IF message.stopPx = << >> THEN << >> ELSE message.stopPx[1])
        \o (IF message.routingInst = << >> THEN << >> ELSE message.routingInst[1])
        \o (IF message.routStrategy = << >> THEN << >> ELSE message.routStrategy[1])
        \o (IF message.routeDeliveryMethod = << >> THEN << >> ELSE message.routeDeliveryMethod[1])
        \o (IF message.exDestination = << >> THEN << >> ELSE message.exDestination[1])
        \o (IF message.crossTradeFlag = << >> THEN << >> ELSE message.crossTradeFlag[1])
        \o (IF message.locateBroker = << >> THEN << >> ELSE message.locateBroker[1])

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
    LET returnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadBytes(returnBitfield3.rest, 1), returnBitfield3.rest) IN IF ~returnBitfield4.ok THEN Fail ELSE
    LET returnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadBytes(returnBitfield4.rest, 1), returnBitfield4.rest) IN IF ~returnBitfield5.ok THEN Fail ELSE
    LET returnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadUIntLE(returnBitfield5.rest, 1), returnBitfield5.rest) IN IF ~returnBitfield6.ok THEN Fail ELSE
    LET returnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadBytes(returnBitfield6.rest, 1), returnBitfield6.rest) IN IF ~returnBitfield7.ok THEN Fail ELSE
    LET returnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadUIntLE(returnBitfield7.rest, 1), returnBitfield7.rest) IN IF ~returnBitfield8.ok THEN Fail ELSE
    LET returnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadBytes(returnBitfield8.rest, 1), returnBitfield8.rest) IN IF ~returnBitfield9.ok THEN Fail ELSE
    LET returnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadBytes(returnBitfield9.rest, 1), returnBitfield9.rest) IN IF ~returnBitfield10.ok THEN Fail ELSE
    LET returnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadBytes(returnBitfield10.rest, 1), returnBitfield10.rest) IN IF ~returnBitfield11.ok THEN Fail ELSE
    LET returnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadBytes(returnBitfield11.rest, 1), returnBitfield11.rest) IN IF ~returnBitfield12.ok THEN Fail ELSE
    LET returnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(returnBitfield12.rest, 1), returnBitfield12.rest) IN IF ~returnBitfield13.ok THEN Fail ELSE
    LET returnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(returnBitfield13.rest, 1), returnBitfield13.rest) IN IF ~returnBitfield14.ok THEN Fail ELSE
    LET returnBitfield15 == ReadWhen(numberOfReturnBitfields.value >= 15, ReadBytes(returnBitfield14.rest, 1), returnBitfield14.rest) IN IF ~returnBitfield15.ok THEN Fail ELSE
    LET returnBitfield16 == ReadWhen(numberOfReturnBitfields.value >= 16, ReadBytes(returnBitfield15.rest, 1), returnBitfield15.rest) IN IF ~returnBitfield16.ok THEN Fail ELSE
    LET returnBitfield17 == ReadWhen(numberOfReturnBitfields.value >= 17, ReadBytes(returnBitfield16.rest, 1), returnBitfield16.rest) IN IF ~returnBitfield17.ok THEN Fail ELSE
    LET returnBitfield18 == ReadWhen(numberOfReturnBitfields.value >= 18, ReadUIntLE(returnBitfield17.rest, 1), returnBitfield17.rest) IN IF ~returnBitfield18.ok THEN Fail ELSE
    LET returnBitfield19 == ReadWhen(numberOfReturnBitfields.value >= 19, ReadBytes(returnBitfield18.rest, 1), returnBitfield18.rest) IN IF ~returnBitfield19.ok THEN Fail ELSE
    LET side == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ returnBitfield1.value[1] % 2 > 0), ReadBytes(returnBitfield19.rest, 1), returnBitfield19.rest) IN IF ~side.ok THEN Fail ELSE
    LET pegDifference == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 2) % 2 > 0), ReadBytes(side.rest, 8), side.rest) IN IF ~pegDifference.ok THEN Fail ELSE
    LET price == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(pegDifference.rest, 8), pegDifference.rest) IN IF ~price.ok THEN Fail ELSE
    LET execInst == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 8) % 2 > 0), ReadBytes(price.rest, 1), price.rest) IN IF ~execInst.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(execInst.rest, 1), execInst.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET symbol == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ returnBitfield2.value[1] % 2 > 0), ReadBytes(minQty.rest, 8), minQty.rest) IN IF ~symbol.ok THEN Fail ELSE
    LET symbolSfx == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ (returnBitfield2.value[1] \div 2) % 2 > 0), ReadBytes(symbol.rest, 8), symbol.rest) IN IF ~symbolSfx.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ (returnBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(symbolSfx.rest, 1), symbolSfx.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ returnBitfield3.value[1] % 2 > 0), ReadBytes(capacity.rest, 16), capacity.rest) IN IF ~account.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 2) % 2 > 0), ReadBytes(account.rest, 4), account.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 4) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET displayIndicator == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 8) % 2 > 0), ReadBytes(clearingAccount.rest, 1), clearingAccount.rest) IN IF ~displayIndicator.ok THEN Fail ELSE
    LET maxFloor == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 16) % 2 > 0), ReadBytes(displayIndicator.rest, 4), displayIndicator.rest) IN IF ~maxFloor.ok THEN Fail ELSE
    LET discretionAmount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 32) % 2 > 0), ReadBytes(maxFloor.rest, 2), maxFloor.rest) IN IF ~discretionAmount.ok THEN Fail ELSE
    LET orderQty == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 64) % 2 > 0), ReadBytes(discretionAmount.rest, 4), discretionAmount.rest) IN IF ~orderQty.ok THEN Fail ELSE
    LET preventMatch == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 128) % 2 > 0), ReadBytes(orderQty.rest, 3), orderQty.rest) IN IF ~preventMatch.ok THEN Fail ELSE
    LET attributedQuote == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (returnBitfield6.value # << >> /\ (returnBitfield6.value[1] \div 8) % 2 > 0), ReadBytes(preventMatch.rest, 1), preventMatch.rest) IN IF ~attributedQuote.ok THEN Fail ELSE
    LET extExecInst == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (returnBitfield6.value # << >> /\ (returnBitfield6.value[1] \div 16) % 2 > 0), ReadBytes(attributedQuote.rest, 1), attributedQuote.rest) IN IF ~extExecInst.ok THEN Fail ELSE
    LET feeCode == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ returnBitfield8.value[1] % 2 > 0), ReadBytes(extExecInst.rest, 2), extExecInst.rest) IN IF ~feeCode.ok THEN Fail ELSE
    LET echoText == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 2) % 2 > 0), ReadBytes(feeCode.rest, 64), feeCode.rest) IN IF ~echoText.ok THEN Fail ELSE
    LET stopPx == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 4) % 2 > 0), ReadBytes(echoText.rest, 8), echoText.rest) IN IF ~stopPx.ok THEN Fail ELSE
    LET routingInst == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 8) % 2 > 0), ReadBytes(stopPx.rest, 4), stopPx.rest) IN IF ~routingInst.ok THEN Fail ELSE
    LET routStrategy == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 16) % 2 > 0), ReadBytes(routingInst.rest, 6), routingInst.rest) IN IF ~routStrategy.ok THEN Fail ELSE
    LET routeDeliveryMethod == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 32) % 2 > 0), ReadBytes(routStrategy.rest, 3), routStrategy.rest) IN IF ~routeDeliveryMethod.ok THEN Fail ELSE
    LET exDestination == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 64) % 2 > 0), ReadBytes(routeDeliveryMethod.rest, 1), routeDeliveryMethod.rest) IN IF ~exDestination.ok THEN Fail ELSE
    LET crossTradeFlag == ReadWhen(numberOfReturnBitfields.value >= 18 /\ (returnBitfield18.value # << >> /\ (returnBitfield18.value[1] \div 8) % 2 > 0), ReadBytes(exDestination.rest, 1), exDestination.rest) IN IF ~crossTradeFlag.ok THEN Fail ELSE
    LET locateBroker == ReadWhen(numberOfReturnBitfields.value >= 18 /\ (returnBitfield18.value # << >> /\ (returnBitfield18.value[1] \div 64) % 2 > 0), ReadBytes(crossTradeFlag.rest, 4), crossTradeFlag.rest) IN IF ~locateBroker.ok THEN Fail ELSE
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
         returnBitfield18        |-> returnBitfield18.value,
         returnBitfield19        |-> returnBitfield19.value,
         side                    |-> side.value,
         pegDifference           |-> pegDifference.value,
         price                   |-> price.value,
         execInst                |-> execInst.value,
         ordType                 |-> ordType.value,
         timeInForce             |-> timeInForce.value,
         minQty                  |-> minQty.value,
         symbol                  |-> symbol.value,
         symbolSfx               |-> symbolSfx.value,
         capacity                |-> capacity.value,
         account                 |-> account.value,
         clearingFirm            |-> clearingFirm.value,
         clearingAccount         |-> clearingAccount.value,
         displayIndicator        |-> displayIndicator.value,
         maxFloor                |-> maxFloor.value,
         discretionAmount        |-> discretionAmount.value,
         orderQty                |-> orderQty.value,
         preventMatch            |-> preventMatch.value,
         attributedQuote         |-> attributedQuote.value,
         extExecInst             |-> extExecInst.value,
         feeCode                 |-> feeCode.value,
         echoText                |-> echoText.value,
         stopPx                  |-> stopPx.value,
         routingInst             |-> routingInst.value,
         routStrategy            |-> routStrategy.value,
         routeDeliveryMethod     |-> routeDeliveryMethod.value,
         exDestination           |-> exDestination.value,
         crossTradeFlag          |-> crossTradeFlag.value,
         locateBroker            |-> locateBroker.value ], locateBroker.rest)

(* Order Execution Message with each field marked present by fields before it there exactly where they say *)
SettleOrderExecutionMessage(message) ==
    LET settled1 == [message EXCEPT !.returnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.returnBitfield1 = << >> THEN <<0>> ELSE message.returnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.returnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.returnBitfield2 = << >> THEN <<0>> ELSE settled1.returnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.returnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.returnBitfield3 = << >> THEN <<0>> ELSE settled2.returnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.returnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.returnBitfield4 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled3.returnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.returnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.returnBitfield5 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled4.returnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.returnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.returnBitfield6 = << >> THEN <<0>> ELSE settled5.returnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.returnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.returnBitfield7 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.returnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.returnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.returnBitfield8 = << >> THEN <<0>> ELSE settled7.returnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.returnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.returnBitfield9 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled8.returnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.returnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.returnBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.returnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.returnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.returnBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.returnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.returnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.returnBitfield12 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.returnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.returnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.returnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.returnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.returnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.returnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.returnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.returnBitfield15 = IF settled14.numberOfReturnBitfields >= 15 THEN (IF settled14.returnBitfield15 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.returnBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.returnBitfield16 = IF settled15.numberOfReturnBitfields >= 16 THEN (IF settled15.returnBitfield16 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled15.returnBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.returnBitfield17 = IF settled16.numberOfReturnBitfields >= 17 THEN (IF settled16.returnBitfield17 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled16.returnBitfield17) ELSE << >>]
        settled18 == [settled17 EXCEPT !.returnBitfield18 = IF settled17.numberOfReturnBitfields >= 18 THEN (IF settled17.returnBitfield18 = << >> THEN <<0>> ELSE settled17.returnBitfield18) ELSE << >>]
        settled19 == [settled18 EXCEPT !.returnBitfield19 = IF settled18.numberOfReturnBitfields >= 19 THEN (IF settled18.returnBitfield19 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled18.returnBitfield19) ELSE << >>]
        settled20 == [settled19 EXCEPT !.side = IF settled19.numberOfReturnBitfields >= 1 /\ (settled19.returnBitfield1 # << >> /\ settled19.returnBitfield1[1] % 2 > 0) THEN (IF settled19.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled19.side) ELSE << >>]
        settled21 == [settled20 EXCEPT !.pegDifference = IF settled20.numberOfReturnBitfields >= 1 /\ (settled20.returnBitfield1 # << >> /\ (settled20.returnBitfield1[1] \div 2) % 2 > 0) THEN (IF settled20.pegDifference = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled20.pegDifference) ELSE << >>]
        settled22 == [settled21 EXCEPT !.price = IF settled21.numberOfReturnBitfields >= 1 /\ (settled21.returnBitfield1 # << >> /\ (settled21.returnBitfield1[1] \div 4) % 2 > 0) THEN (IF settled21.price = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled21.price) ELSE << >>]
        settled23 == [settled22 EXCEPT !.execInst = IF settled22.numberOfReturnBitfields >= 1 /\ (settled22.returnBitfield1 # << >> /\ (settled22.returnBitfield1[1] \div 8) % 2 > 0) THEN (IF settled22.execInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled22.execInst) ELSE << >>]
        settled24 == [settled23 EXCEPT !.ordType = IF settled23.numberOfReturnBitfields >= 1 /\ (settled23.returnBitfield1 # << >> /\ (settled23.returnBitfield1[1] \div 16) % 2 > 0) THEN (IF settled23.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled23.ordType) ELSE << >>]
        settled25 == [settled24 EXCEPT !.timeInForce = IF settled24.numberOfReturnBitfields >= 1 /\ (settled24.returnBitfield1 # << >> /\ (settled24.returnBitfield1[1] \div 32) % 2 > 0) THEN (IF settled24.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled24.timeInForce) ELSE << >>]
        settled26 == [settled25 EXCEPT !.minQty = IF settled25.numberOfReturnBitfields >= 1 /\ (settled25.returnBitfield1 # << >> /\ (settled25.returnBitfield1[1] \div 64) % 2 > 0) THEN (IF settled25.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled25.minQty) ELSE << >>]
        settled27 == [settled26 EXCEPT !.symbol = IF settled26.numberOfReturnBitfields >= 2 /\ (settled26.returnBitfield2 # << >> /\ settled26.returnBitfield2[1] % 2 > 0) THEN (IF settled26.symbol = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled26.symbol) ELSE << >>]
        settled28 == [settled27 EXCEPT !.symbolSfx = IF settled27.numberOfReturnBitfields >= 2 /\ (settled27.returnBitfield2 # << >> /\ (settled27.returnBitfield2[1] \div 2) % 2 > 0) THEN (IF settled27.symbolSfx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled27.symbolSfx) ELSE << >>]
        settled29 == [settled28 EXCEPT !.capacity = IF settled28.numberOfReturnBitfields >= 2 /\ (settled28.returnBitfield2 # << >> /\ (settled28.returnBitfield2[1] \div 64) % 2 > 0) THEN (IF settled28.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled28.capacity) ELSE << >>]
        settled30 == [settled29 EXCEPT !.account = IF settled29.numberOfReturnBitfields >= 3 /\ (settled29.returnBitfield3 # << >> /\ settled29.returnBitfield3[1] % 2 > 0) THEN (IF settled29.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled29.account) ELSE << >>]
        settled31 == [settled30 EXCEPT !.clearingFirm = IF settled30.numberOfReturnBitfields >= 3 /\ (settled30.returnBitfield3 # << >> /\ (settled30.returnBitfield3[1] \div 2) % 2 > 0) THEN (IF settled30.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled30.clearingFirm) ELSE << >>]
        settled32 == [settled31 EXCEPT !.clearingAccount = IF settled31.numberOfReturnBitfields >= 3 /\ (settled31.returnBitfield3 # << >> /\ (settled31.returnBitfield3[1] \div 4) % 2 > 0) THEN (IF settled31.clearingAccount = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled31.clearingAccount) ELSE << >>]
        settled33 == [settled32 EXCEPT !.displayIndicator = IF settled32.numberOfReturnBitfields >= 3 /\ (settled32.returnBitfield3 # << >> /\ (settled32.returnBitfield3[1] \div 8) % 2 > 0) THEN (IF settled32.displayIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled32.displayIndicator) ELSE << >>]
        settled34 == [settled33 EXCEPT !.maxFloor = IF settled33.numberOfReturnBitfields >= 3 /\ (settled33.returnBitfield3 # << >> /\ (settled33.returnBitfield3[1] \div 16) % 2 > 0) THEN (IF settled33.maxFloor = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled33.maxFloor) ELSE << >>]
        settled35 == [settled34 EXCEPT !.discretionAmount = IF settled34.numberOfReturnBitfields >= 3 /\ (settled34.returnBitfield3 # << >> /\ (settled34.returnBitfield3[1] \div 32) % 2 > 0) THEN (IF settled34.discretionAmount = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled34.discretionAmount) ELSE << >>]
        settled36 == [settled35 EXCEPT !.orderQty = IF settled35.numberOfReturnBitfields >= 3 /\ (settled35.returnBitfield3 # << >> /\ (settled35.returnBitfield3[1] \div 64) % 2 > 0) THEN (IF settled35.orderQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled35.orderQty) ELSE << >>]
        settled37 == [settled36 EXCEPT !.preventMatch = IF settled36.numberOfReturnBitfields >= 3 /\ (settled36.returnBitfield3 # << >> /\ (settled36.returnBitfield3[1] \div 128) % 2 > 0) THEN (IF settled36.preventMatch = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled36.preventMatch) ELSE << >>]
        settled38 == [settled37 EXCEPT !.attributedQuote = IF settled37.numberOfReturnBitfields >= 6 /\ (settled37.returnBitfield6 # << >> /\ (settled37.returnBitfield6[1] \div 8) % 2 > 0) THEN (IF settled37.attributedQuote = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled37.attributedQuote) ELSE << >>]
        settled39 == [settled38 EXCEPT !.extExecInst = IF settled38.numberOfReturnBitfields >= 6 /\ (settled38.returnBitfield6 # << >> /\ (settled38.returnBitfield6[1] \div 16) % 2 > 0) THEN (IF settled38.extExecInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled38.extExecInst) ELSE << >>]
        settled40 == [settled39 EXCEPT !.feeCode = IF settled39.numberOfReturnBitfields >= 8 /\ (settled39.returnBitfield8 # << >> /\ settled39.returnBitfield8[1] % 2 > 0) THEN (IF settled39.feeCode = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled39.feeCode) ELSE << >>]
        settled41 == [settled40 EXCEPT !.echoText = IF settled40.numberOfReturnBitfields >= 8 /\ (settled40.returnBitfield8 # << >> /\ (settled40.returnBitfield8[1] \div 2) % 2 > 0) THEN (IF settled40.echoText = << >> THEN <<[i \in 1 .. 64 |-> 0]>> ELSE settled40.echoText) ELSE << >>]
        settled42 == [settled41 EXCEPT !.stopPx = IF settled41.numberOfReturnBitfields >= 8 /\ (settled41.returnBitfield8 # << >> /\ (settled41.returnBitfield8[1] \div 4) % 2 > 0) THEN (IF settled41.stopPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled41.stopPx) ELSE << >>]
        settled43 == [settled42 EXCEPT !.routingInst = IF settled42.numberOfReturnBitfields >= 8 /\ (settled42.returnBitfield8 # << >> /\ (settled42.returnBitfield8[1] \div 8) % 2 > 0) THEN (IF settled42.routingInst = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled42.routingInst) ELSE << >>]
        settled44 == [settled43 EXCEPT !.routStrategy = IF settled43.numberOfReturnBitfields >= 8 /\ (settled43.returnBitfield8 # << >> /\ (settled43.returnBitfield8[1] \div 16) % 2 > 0) THEN (IF settled43.routStrategy = << >> THEN <<[i \in 1 .. 6 |-> 0]>> ELSE settled43.routStrategy) ELSE << >>]
        settled45 == [settled44 EXCEPT !.routeDeliveryMethod = IF settled44.numberOfReturnBitfields >= 8 /\ (settled44.returnBitfield8 # << >> /\ (settled44.returnBitfield8[1] \div 32) % 2 > 0) THEN (IF settled44.routeDeliveryMethod = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled44.routeDeliveryMethod) ELSE << >>]
        settled46 == [settled45 EXCEPT !.exDestination = IF settled45.numberOfReturnBitfields >= 8 /\ (settled45.returnBitfield8 # << >> /\ (settled45.returnBitfield8[1] \div 64) % 2 > 0) THEN (IF settled45.exDestination = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled45.exDestination) ELSE << >>]
        settled47 == [settled46 EXCEPT !.crossTradeFlag = IF settled46.numberOfReturnBitfields >= 18 /\ (settled46.returnBitfield18 # << >> /\ (settled46.returnBitfield18[1] \div 8) % 2 > 0) THEN (IF settled46.crossTradeFlag = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled46.crossTradeFlag) ELSE << >>]
        settled48 == [settled47 EXCEPT !.locateBroker = IF settled47.numberOfReturnBitfields >= 18 /\ (settled47.returnBitfield18 # << >> /\ (settled47.returnBitfield18[1] \div 64) % 2 > 0) THEN (IF settled47.locateBroker = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled47.locateBroker) ELSE << >>]
    IN  settled48

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
                                  returnBitfield18        |-> << >>,
                                  returnBitfield19        |-> << >>,
                                  side                    |-> << >>,
                                  pegDifference           |-> << >>,
                                  price                   |-> << >>,
                                  execInst                |-> << >>,
                                  ordType                 |-> << >>,
                                  timeInForce             |-> << >>,
                                  minQty                  |-> << >>,
                                  symbol                  |-> << >>,
                                  symbolSfx               |-> << >>,
                                  capacity                |-> << >>,
                                  account                 |-> << >>,
                                  clearingFirm            |-> << >>,
                                  clearingAccount         |-> << >>,
                                  displayIndicator        |-> << >>,
                                  maxFloor                |-> << >>,
                                  discretionAmount        |-> << >>,
                                  orderQty                |-> << >>,
                                  preventMatch            |-> << >>,
                                  attributedQuote         |-> << >>,
                                  extExecInst             |-> << >>,
                                  feeCode                 |-> << >>,
                                  echoText                |-> << >>,
                                  stopPx                  |-> << >>,
                                  routingInst             |-> << >>,
                                  routStrategy            |-> << >>,
                                  routeDeliveryMethod     |-> << >>,
                                  exDestination           |-> << >>,
                                  crossTradeFlag          |-> << >>,
                                  locateBroker            |-> << >> ])

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
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 7, !.returnBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 9, !.returnBitfield9 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 10, !.returnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 11, !.returnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 13, !.returnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 14, !.returnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 15, !.returnBitfield15 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 17, !.returnBitfield17 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 18, !.returnBitfield18 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 19, !.returnBitfield19 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<1>>, !.side = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<2>>, !.pegDifference = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<4>>, !.price = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<8>>, !.execInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<1>>, !.symbol = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<2>>, !.symbolSfx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<1>>, !.account = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<2>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<4>>, !.clearingAccount = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<8>>, !.displayIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<16>>, !.maxFloor = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<32>>, !.discretionAmount = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<64>>, !.orderQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<128>>, !.preventMatch = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = <<8>>, !.attributedQuote = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = <<16>>, !.extExecInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<1>>, !.feeCode = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<2>>, !.echoText = one]) : one \in { <<held>> : held \in Sample(64) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<4>>, !.stopPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<8>>, !.routingInst = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<16>>, !.routStrategy = one]) : one \in { <<held>> : held \in Sample(6) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<32>>, !.routeDeliveryMethod = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<64>>, !.exDestination = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 18, !.returnBitfield18 = <<8>>, !.crossTradeFlag = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 18, !.returnBitfield18 = <<64>>, !.locateBroker = one]) : one \in { <<held>> : held \in Sample(4) } }

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
      returnBitfield4         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield5         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield6         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield7         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield8         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield9         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield10        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield11        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield12        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield13        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield14        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield15        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield16        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield17        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield18        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield19        : { << >> } \cup { <<held>> : held \in Sample(1) },
      symbol                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      symbolSfx               : { << >> } \cup { <<held>> : held \in Sample(8) },
      capacity                : { << >> } \cup { <<held>> : held \in Sample(1) },
      subLiquidityIndicator   : { << >> } \cup { <<held>> : held \in Sample(1) } ]

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
        \o (IF message.returnBitfield4 = << >> THEN << >> ELSE message.returnBitfield4[1])
        \o (IF message.returnBitfield5 = << >> THEN << >> ELSE message.returnBitfield5[1])
        \o (IF message.returnBitfield6 = << >> THEN << >> ELSE message.returnBitfield6[1])
        \o (IF message.returnBitfield7 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield7[1], 1))
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
        \o (IF message.returnBitfield18 = << >> THEN << >> ELSE message.returnBitfield18[1])
        \o (IF message.returnBitfield19 = << >> THEN << >> ELSE message.returnBitfield19[1])
        \o (IF message.symbol = << >> THEN << >> ELSE message.symbol[1])
        \o (IF message.symbolSfx = << >> THEN << >> ELSE message.symbolSfx[1])
        \o (IF message.capacity = << >> THEN << >> ELSE message.capacity[1])
        \o (IF message.subLiquidityIndicator = << >> THEN << >> ELSE message.subLiquidityIndicator[1])

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
    LET returnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadBytes(returnBitfield3.rest, 1), returnBitfield3.rest) IN IF ~returnBitfield4.ok THEN Fail ELSE
    LET returnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadBytes(returnBitfield4.rest, 1), returnBitfield4.rest) IN IF ~returnBitfield5.ok THEN Fail ELSE
    LET returnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadBytes(returnBitfield5.rest, 1), returnBitfield5.rest) IN IF ~returnBitfield6.ok THEN Fail ELSE
    LET returnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadUIntLE(returnBitfield6.rest, 1), returnBitfield6.rest) IN IF ~returnBitfield7.ok THEN Fail ELSE
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
    LET returnBitfield18 == ReadWhen(numberOfReturnBitfields.value >= 18, ReadBytes(returnBitfield17.rest, 1), returnBitfield17.rest) IN IF ~returnBitfield18.ok THEN Fail ELSE
    LET returnBitfield19 == ReadWhen(numberOfReturnBitfields.value >= 19, ReadBytes(returnBitfield18.rest, 1), returnBitfield18.rest) IN IF ~returnBitfield19.ok THEN Fail ELSE
    LET symbol == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ returnBitfield2.value[1] % 2 > 0), ReadBytes(returnBitfield19.rest, 8), returnBitfield19.rest) IN IF ~symbol.ok THEN Fail ELSE
    LET symbolSfx == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ (returnBitfield2.value[1] \div 2) % 2 > 0), ReadBytes(symbol.rest, 8), symbol.rest) IN IF ~symbolSfx.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ (returnBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(symbolSfx.rest, 1), symbolSfx.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET subLiquidityIndicator == ReadWhen(numberOfReturnBitfields.value >= 7 /\ (returnBitfield7.value # << >> /\ returnBitfield7.value[1] % 2 > 0), ReadBytes(capacity.rest, 1), capacity.rest) IN IF ~subLiquidityIndicator.ok THEN Fail ELSE
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
         returnBitfield18        |-> returnBitfield18.value,
         returnBitfield19        |-> returnBitfield19.value,
         symbol                  |-> symbol.value,
         symbolSfx               |-> symbolSfx.value,
         capacity                |-> capacity.value,
         subLiquidityIndicator   |-> subLiquidityIndicator.value ], subLiquidityIndicator.rest)

(* Trade Cancel Or Correct Message with each field marked present by fields before it there exactly where they say *)
SettleTradeCancelOrCorrectMessage(message) ==
    LET settled1 == [message EXCEPT !.returnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.returnBitfield1 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE message.returnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.returnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.returnBitfield2 = << >> THEN <<0>> ELSE settled1.returnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.returnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.returnBitfield3 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled2.returnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.returnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.returnBitfield4 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled3.returnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.returnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.returnBitfield5 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled4.returnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.returnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.returnBitfield6 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled5.returnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.returnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.returnBitfield7 = << >> THEN <<0>> ELSE settled6.returnBitfield7) ELSE << >>]
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
        settled18 == [settled17 EXCEPT !.returnBitfield18 = IF settled17.numberOfReturnBitfields >= 18 THEN (IF settled17.returnBitfield18 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.returnBitfield18) ELSE << >>]
        settled19 == [settled18 EXCEPT !.returnBitfield19 = IF settled18.numberOfReturnBitfields >= 19 THEN (IF settled18.returnBitfield19 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled18.returnBitfield19) ELSE << >>]
        settled20 == [settled19 EXCEPT !.symbol = IF settled19.numberOfReturnBitfields >= 2 /\ (settled19.returnBitfield2 # << >> /\ settled19.returnBitfield2[1] % 2 > 0) THEN (IF settled19.symbol = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled19.symbol) ELSE << >>]
        settled21 == [settled20 EXCEPT !.symbolSfx = IF settled20.numberOfReturnBitfields >= 2 /\ (settled20.returnBitfield2 # << >> /\ (settled20.returnBitfield2[1] \div 2) % 2 > 0) THEN (IF settled20.symbolSfx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled20.symbolSfx) ELSE << >>]
        settled22 == [settled21 EXCEPT !.capacity = IF settled21.numberOfReturnBitfields >= 2 /\ (settled21.returnBitfield2 # << >> /\ (settled21.returnBitfield2[1] \div 64) % 2 > 0) THEN (IF settled21.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled21.capacity) ELSE << >>]
        settled23 == [settled22 EXCEPT !.subLiquidityIndicator = IF settled22.numberOfReturnBitfields >= 7 /\ (settled22.returnBitfield7 # << >> /\ settled22.returnBitfield7[1] % 2 > 0) THEN (IF settled22.subLiquidityIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled22.subLiquidityIndicator) ELSE << >>]
    IN  settled23

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
                                        returnBitfield18        |-> << >>,
                                        returnBitfield19        |-> << >>,
                                        symbol                  |-> << >>,
                                        symbolSfx               |-> << >>,
                                        capacity                |-> << >>,
                                        subLiquidityIndicator   |-> << >> ])

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
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 7, !.returnBitfield7 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 9, !.returnBitfield9 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 10, !.returnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 11, !.returnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 13, !.returnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 14, !.returnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 15, !.returnBitfield15 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 17, !.returnBitfield17 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 18, !.returnBitfield18 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 19, !.returnBitfield19 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<1>>, !.symbol = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<2>>, !.symbolSfx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 7, !.returnBitfield7 = <<1>>, !.subLiquidityIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }

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
      returnBitfield18        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield19        : { << >> } \cup { <<held>> : held \in Sample(1) },
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
        \o (IF message.returnBitfield18 = << >> THEN << >> ELSE message.returnBitfield18[1])
        \o (IF message.returnBitfield19 = << >> THEN << >> ELSE message.returnBitfield19[1])
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
    LET returnBitfield18 == ReadWhen(numberOfReturnBitfields.value >= 18, ReadBytes(returnBitfield17.rest, 1), returnBitfield17.rest) IN IF ~returnBitfield18.ok THEN Fail ELSE
    LET returnBitfield19 == ReadWhen(numberOfReturnBitfields.value >= 19, ReadBytes(returnBitfield18.rest, 1), returnBitfield18.rest) IN IF ~returnBitfield19.ok THEN Fail ELSE
    LET massCancelId == ReadWhen(numberOfReturnBitfields.value >= 15 /\ (returnBitfield15.value # << >> /\ (returnBitfield15.value[1] \div 8) % 2 > 0), ReadBytes(returnBitfield19.rest, 20), returnBitfield19.rest) IN IF ~massCancelId.ok THEN Fail ELSE
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
         returnBitfield18        |-> returnBitfield18.value,
         returnBitfield19        |-> returnBitfield19.value,
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
        settled18 == [settled17 EXCEPT !.returnBitfield18 = IF settled17.numberOfReturnBitfields >= 18 THEN (IF settled17.returnBitfield18 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.returnBitfield18) ELSE << >>]
        settled19 == [settled18 EXCEPT !.returnBitfield19 = IF settled18.numberOfReturnBitfields >= 19 THEN (IF settled18.returnBitfield19 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled18.returnBitfield19) ELSE << >>]
        settled20 == [settled19 EXCEPT !.massCancelId = IF settled19.numberOfReturnBitfields >= 15 /\ (settled19.returnBitfield15 # << >> /\ (settled19.returnBitfield15[1] \div 8) % 2 > 0) THEN (IF settled19.massCancelId = << >> THEN <<[i \in 1 .. 20 |-> 0]>> ELSE settled19.massCancelId) ELSE << >>]
    IN  settled20

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
                                 returnBitfield18        |-> << >>,
                                 returnBitfield19        |-> << >>,
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
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.numberOfReturnBitfields = 18, !.returnBitfield18 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.numberOfReturnBitfields = 19, !.returnBitfield19 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.numberOfReturnBitfields = 15, !.returnBitfield15 = <<8>>, !.massCancelId = one]) : one \in { <<held>> : held \in Sample(20) } }

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
PurgeOrdersMessageCode == 71  \* 0x47
OrderAcknowledgmentMessageCode == 37  \* 0x25
OrderRejectedMessageCode == 38  \* 0x26
OrderModifiedMessageCode == 39  \* 0x27
OrderRestatedMessageCode == 40  \* 0x28
UserModifyRejectedMessageCode == 41  \* 0x29
OrderCancelledMessageCode == 42  \* 0x2a
CancelRejectedMessageCode == 43  \* 0x2b
OrderExecutionMessageCode == 44  \* 0x2c
TradeCancelOrCorrectMessageCode == 45  \* 0x2d
MassCancelAcknowledgmentMessageCode == 54  \* 0x36
PurgeRejectedMessageCode == 72  \* 0x48

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
        \cup [ tag : {PurgeOrdersMessageCode}, body : PurgeOrdersMessage ]
        \cup [ tag : {OrderAcknowledgmentMessageCode}, body : OrderAcknowledgmentMessage ]
        \cup [ tag : {OrderRejectedMessageCode}, body : OrderRejectedMessage ]
        \cup [ tag : {OrderModifiedMessageCode}, body : OrderModifiedMessage ]
        \cup [ tag : {OrderRestatedMessageCode}, body : OrderRestatedMessage ]
        \cup [ tag : {UserModifyRejectedMessageCode}, body : UserModifyRejectedMessage ]
        \cup [ tag : {OrderCancelledMessageCode}, body : OrderCancelledMessage ]
        \cup [ tag : {CancelRejectedMessageCode}, body : CancelRejectedMessage ]
        \cup [ tag : {OrderExecutionMessageCode}, body : OrderExecutionMessage ]
        \cup [ tag : {TradeCancelOrCorrectMessageCode}, body : TradeCancelOrCorrectMessage ]
        \cup [ tag : {MassCancelAcknowledgmentMessageCode}, body : MassCancelAcknowledgmentMessage ]
        \cup [ tag : {PurgeRejectedMessageCode}, body : PurgeRejectedMessage ]

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
      [] message.tag = PurgeOrdersMessageCode -> EncodePurgeOrdersMessage(message.body)
      [] message.tag = OrderAcknowledgmentMessageCode -> EncodeOrderAcknowledgmentMessage(message.body)
      [] message.tag = OrderRejectedMessageCode -> EncodeOrderRejectedMessage(message.body)
      [] message.tag = OrderModifiedMessageCode -> EncodeOrderModifiedMessage(message.body)
      [] message.tag = OrderRestatedMessageCode -> EncodeOrderRestatedMessage(message.body)
      [] message.tag = UserModifyRejectedMessageCode -> EncodeUserModifyRejectedMessage(message.body)
      [] message.tag = OrderCancelledMessageCode -> EncodeOrderCancelledMessage(message.body)
      [] message.tag = CancelRejectedMessageCode -> EncodeCancelRejectedMessage(message.body)
      [] message.tag = OrderExecutionMessageCode -> EncodeOrderExecutionMessage(message.body)
      [] message.tag = TradeCancelOrCorrectMessageCode -> EncodeTradeCancelOrCorrectMessage(message.body)
      [] message.tag = MassCancelAcknowledgmentMessageCode -> EncodeMassCancelAcknowledgmentMessage(message.body)
      [] message.tag = PurgeRejectedMessageCode -> EncodePurgeRejectedMessage(message.body)

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
              [] tag = PurgeOrdersMessageCode -> DecodePurgeOrdersMessage(bytes)
              [] tag = OrderAcknowledgmentMessageCode -> DecodeOrderAcknowledgmentMessage(bytes)
              [] tag = OrderRejectedMessageCode -> DecodeOrderRejectedMessage(bytes)
              [] tag = OrderModifiedMessageCode -> DecodeOrderModifiedMessage(bytes)
              [] tag = OrderRestatedMessageCode -> DecodeOrderRestatedMessage(bytes)
              [] tag = UserModifyRejectedMessageCode -> DecodeUserModifyRejectedMessage(bytes)
              [] tag = OrderCancelledMessageCode -> DecodeOrderCancelledMessage(bytes)
              [] tag = CancelRejectedMessageCode -> DecodeCancelRejectedMessage(bytes)
              [] tag = OrderExecutionMessageCode -> DecodeOrderExecutionMessage(bytes)
              [] tag = TradeCancelOrCorrectMessageCode -> DecodeTradeCancelOrCorrectMessage(bytes)
              [] tag = MassCancelAcknowledgmentMessageCode -> DecodeMassCancelAcknowledgmentMessage(bytes)
              [] tag = PurgeRejectedMessageCode -> DecodePurgeRejectedMessage(bytes)
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
        \cup { [tag |-> PurgeOrdersMessageCode, body |-> one] : one \in CheckedPurgeOrdersMessage }
        \cup { [tag |-> OrderAcknowledgmentMessageCode, body |-> one] : one \in CheckedOrderAcknowledgmentMessage }
        \cup { [tag |-> OrderRejectedMessageCode, body |-> one] : one \in CheckedOrderRejectedMessage }
        \cup { [tag |-> OrderModifiedMessageCode, body |-> one] : one \in CheckedOrderModifiedMessage }
        \cup { [tag |-> OrderRestatedMessageCode, body |-> one] : one \in CheckedOrderRestatedMessage }
        \cup { [tag |-> UserModifyRejectedMessageCode, body |-> one] : one \in CheckedUserModifyRejectedMessage }
        \cup { [tag |-> OrderCancelledMessageCode, body |-> one] : one \in CheckedOrderCancelledMessage }
        \cup { [tag |-> CancelRejectedMessageCode, body |-> one] : one \in CheckedCancelRejectedMessage }
        \cup { [tag |-> OrderExecutionMessageCode, body |-> one] : one \in CheckedOrderExecutionMessage }
        \cup { [tag |-> TradeCancelOrCorrectMessageCode, body |-> one] : one \in CheckedTradeCancelOrCorrectMessage }
        \cup { [tag |-> MassCancelAcknowledgmentMessageCode, body |-> one] : one \in CheckedMassCancelAcknowledgmentMessage }
        \cup { [tag |-> PurgeRejectedMessageCode, body |-> one] : one \in CheckedPurgeRejectedMessage }

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

(* Every Unit Sequences decodes back to what was encoded, and leaves nothing over *)
RoundTripUnitSequences ==
    \A message \in CheckedUnitSequences :
        LET read == DecodeUnitSequences(EncodeUnitSequences(message))
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

(* Every Unit Sequences decodes back to what was encoded, and leaves nothing over *)
RoundTripUnitSequences2 ==
    \A message \in CheckedUnitSequences2 :
        LET read == DecodeUnitSequences2(EncodeUnitSequences2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Unit Sequences decodes back to what was encoded, and leaves nothing over *)
RoundTripUnitSequences3 ==
    \A message \in CheckedUnitSequences3 :
        LET read == DecodeUnitSequences3(EncodeUnitSequences3(message))
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

(* Every Unit Sequences decodes back to what was encoded, and leaves nothing over *)
RoundTripUnitSequences4 ==
    \A message \in CheckedUnitSequences4 :
        LET read == DecodeUnitSequences4(EncodeUnitSequences4(message))
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

(* Every Risk Group I Ds decodes back to what was encoded, and leaves nothing over *)
RoundTripRiskGroupIDs ==
    \A message \in CheckedRiskGroupIDs :
        LET read == DecodeRiskGroupIDs(EncodeRiskGroupIDs(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Purge Orders Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPurgeOrdersMessage ==
    \A message \in CheckedPurgeOrdersMessage :
        LET read == DecodePurgeOrdersMessage(EncodePurgeOrdersMessage(message))
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

(* Every Order Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderRejectedMessage ==
    \A message \in CheckedOrderRejectedMessage :
        LET read == DecodeOrderRejectedMessage(EncodeOrderRejectedMessage(message))
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

(* Every Cancel Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelRejectedMessage ==
    \A message \in CheckedCancelRejectedMessage :
        LET read == DecodeCancelRejectedMessage(EncodeCancelRejectedMessage(message))
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

(* Every Trade Cancel Or Correct Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCancelOrCorrectMessage ==
    \A message \in CheckedTradeCancelOrCorrectMessage :
        LET read == DecodeTradeCancelOrCorrectMessage(EncodeTradeCancelOrCorrectMessage(message))
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

(* Every Purge Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPurgeRejectedMessage ==
    \A message \in CheckedPurgeRejectedMessage :
        LET read == DecodePurgeRejectedMessage(EncodePurgeRejectedMessage(message))
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
