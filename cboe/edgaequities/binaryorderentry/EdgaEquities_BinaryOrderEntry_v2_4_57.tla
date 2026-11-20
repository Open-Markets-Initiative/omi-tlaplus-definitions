--------------- MODULE EdgaEquities_BinaryOrderEntry_v2_4_57 ---------------
(***************************************************************************)
(* Chicago Board Options Exchange Binary Order Entry v2.4.57               *)
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
(* Note: Purge Order Message fills what is left of the frame Message       *)
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
(* Units: 5 bytes                                                          *)
(***************************************************************************)

Units ==
    [ unitNumber   : Sample(1),
      unitSequence : Sample(4) ]

EncodeUnits(message) ==
    message.unitNumber
        \o message.unitSequence

DecodeUnits(bytes) ==
    LET unitNumber == ReadBytes(bytes, 1) IN IF ~unitNumber.ok THEN Fail ELSE
    LET unitSequence == ReadBytes(unitNumber.rest, 4) IN IF ~unitSequence.ok THEN Fail ELSE
    Ok([ unitNumber   |-> unitNumber.value,
         unitSequence |-> unitSequence.value ], unitSequence.rest)

ZeroUnits ==
    [ unitNumber   |-> [i \in 1 .. 1 |-> 0],
      unitSequence |-> [i \in 1 .. 4 |-> 0] ]

(* Units at zero, then each field in turn at the values it is checked at *)
CheckedUnits ==
    { ZeroUnits }
        \cup { [ZeroUnits EXCEPT !.unitNumber = one] : one \in Sample(1) }
        \cup { [ZeroUnits EXCEPT !.unitSequence = one] : one \in Sample(4) }

(* A run of Units, written one after another *)
RECURSIVE EncodeUnitsList(_)
EncodeUnitsList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeUnits(Head(messages)) \o EncodeUnitsList(Tail(messages))

(* As many Units as the field that counts them says *)
RECURSIVE ReadUnitsList(_, _)
ReadUnitsList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeUnits(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadUnitsList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Units of each kind, for the lists that carry them *)
OneUnits == { ZeroUnits }

(***************************************************************************)
(* Unit Sequences Param Group                                              *)
(***************************************************************************)

UnitSequencesParamGroup ==
    [ noUnspecifiedUnitReplay : Sample(1),
      units                   : SampleLists(OneUnits) ]

EncodeUnitSequencesParamGroup(message) ==
    message.noUnspecifiedUnitReplay
        \o EncodeUIntBE(Len(message.units), 1)
        \o EncodeUnitsList(message.units)

DecodeUnitSequencesParamGroup(bytes) ==
    LET noUnspecifiedUnitReplay == ReadBytes(bytes, 1) IN IF ~noUnspecifiedUnitReplay.ok THEN Fail ELSE
    LET numberOfUnits == ReadUIntBE(noUnspecifiedUnitReplay.rest, 1) IN IF ~numberOfUnits.ok THEN Fail ELSE
    LET units == ReadUnitsList(numberOfUnits.rest, numberOfUnits.value) IN IF ~units.ok THEN Fail ELSE
    Ok([ noUnspecifiedUnitReplay |-> noUnspecifiedUnitReplay.value,
         units                   |-> units.value ], units.rest)

ZeroUnitSequencesParamGroup ==
    [ noUnspecifiedUnitReplay |-> [i \in 1 .. 1 |-> 0],
      units                   |-> << >> ]

(* Unit Sequences Param Group at zero, then each field in turn at the values it is checked at *)
CheckedUnitSequencesParamGroup ==
    { ZeroUnitSequencesParamGroup }
        \cup { [ZeroUnitSequencesParamGroup EXCEPT !.noUnspecifiedUnitReplay = one] : one \in Sample(1) }
        \cup { [ZeroUnitSequencesParamGroup EXCEPT !.units = one] : one \in SampleLists(OneUnits) }

(***************************************************************************)
(* Return Bitfields Param Group                                            *)
(***************************************************************************)

ReturnBitfieldsParamGroup ==
    [ messageType                         : Sample(1),
      numberOfReturnBitfields             : 0 .. 255,
      orderAcknowledgmentReturnBitfield1  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield2  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield3  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield4  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield5  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield6  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield7  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield8  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield9  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield10 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield11 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield12 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield13 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield14 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield15 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield16 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield17 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield18 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield19 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield20 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield21 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield22 : { << >> } \cup { <<held>> : held \in Sample(1) } ]

EncodeReturnBitfieldsParamGroup(message) ==
    message.messageType
        \o EncodeUIntBE(message.numberOfReturnBitfields, 1)
        \o (IF message.orderAcknowledgmentReturnBitfield1 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield1[1])
        \o (IF message.orderAcknowledgmentReturnBitfield2 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield2[1])
        \o (IF message.orderAcknowledgmentReturnBitfield3 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield3[1])
        \o (IF message.orderAcknowledgmentReturnBitfield4 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield4[1])
        \o (IF message.orderAcknowledgmentReturnBitfield5 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield5[1])
        \o (IF message.orderAcknowledgmentReturnBitfield6 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield6[1])
        \o (IF message.orderAcknowledgmentReturnBitfield7 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield7[1])
        \o (IF message.orderAcknowledgmentReturnBitfield8 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield8[1])
        \o (IF message.orderAcknowledgmentReturnBitfield9 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield9[1])
        \o (IF message.orderAcknowledgmentReturnBitfield10 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield10[1])
        \o (IF message.orderAcknowledgmentReturnBitfield11 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield11[1])
        \o (IF message.orderAcknowledgmentReturnBitfield12 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield12[1])
        \o (IF message.orderAcknowledgmentReturnBitfield13 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield13[1])
        \o (IF message.orderAcknowledgmentReturnBitfield14 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield14[1])
        \o (IF message.orderAcknowledgmentReturnBitfield15 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield15[1])
        \o (IF message.orderAcknowledgmentReturnBitfield16 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield16[1])
        \o (IF message.orderAcknowledgmentReturnBitfield17 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield17[1])
        \o (IF message.orderAcknowledgmentReturnBitfield18 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield18[1])
        \o (IF message.orderAcknowledgmentReturnBitfield19 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield19[1])
        \o (IF message.orderAcknowledgmentReturnBitfield20 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield20[1])
        \o (IF message.orderAcknowledgmentReturnBitfield21 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield21[1])
        \o (IF message.orderAcknowledgmentReturnBitfield22 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield22[1])

DecodeReturnBitfieldsParamGroup(bytes) ==
    LET messageType == ReadBytes(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET numberOfReturnBitfields == ReadUIntBE(messageType.rest, 1) IN IF ~numberOfReturnBitfields.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield1 == ReadWhen(numberOfReturnBitfields.value >= 1, ReadBytes(numberOfReturnBitfields.rest, 1), numberOfReturnBitfields.rest) IN IF ~orderAcknowledgmentReturnBitfield1.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield2 == ReadWhen(numberOfReturnBitfields.value >= 2, ReadBytes(orderAcknowledgmentReturnBitfield1.rest, 1), orderAcknowledgmentReturnBitfield1.rest) IN IF ~orderAcknowledgmentReturnBitfield2.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield3 == ReadWhen(numberOfReturnBitfields.value >= 3, ReadBytes(orderAcknowledgmentReturnBitfield2.rest, 1), orderAcknowledgmentReturnBitfield2.rest) IN IF ~orderAcknowledgmentReturnBitfield3.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadBytes(orderAcknowledgmentReturnBitfield3.rest, 1), orderAcknowledgmentReturnBitfield3.rest) IN IF ~orderAcknowledgmentReturnBitfield4.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadBytes(orderAcknowledgmentReturnBitfield4.rest, 1), orderAcknowledgmentReturnBitfield4.rest) IN IF ~orderAcknowledgmentReturnBitfield5.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadBytes(orderAcknowledgmentReturnBitfield5.rest, 1), orderAcknowledgmentReturnBitfield5.rest) IN IF ~orderAcknowledgmentReturnBitfield6.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadBytes(orderAcknowledgmentReturnBitfield6.rest, 1), orderAcknowledgmentReturnBitfield6.rest) IN IF ~orderAcknowledgmentReturnBitfield7.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadBytes(orderAcknowledgmentReturnBitfield7.rest, 1), orderAcknowledgmentReturnBitfield7.rest) IN IF ~orderAcknowledgmentReturnBitfield8.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadBytes(orderAcknowledgmentReturnBitfield8.rest, 1), orderAcknowledgmentReturnBitfield8.rest) IN IF ~orderAcknowledgmentReturnBitfield9.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadBytes(orderAcknowledgmentReturnBitfield9.rest, 1), orderAcknowledgmentReturnBitfield9.rest) IN IF ~orderAcknowledgmentReturnBitfield10.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadBytes(orderAcknowledgmentReturnBitfield10.rest, 1), orderAcknowledgmentReturnBitfield10.rest) IN IF ~orderAcknowledgmentReturnBitfield11.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadBytes(orderAcknowledgmentReturnBitfield11.rest, 1), orderAcknowledgmentReturnBitfield11.rest) IN IF ~orderAcknowledgmentReturnBitfield12.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(orderAcknowledgmentReturnBitfield12.rest, 1), orderAcknowledgmentReturnBitfield12.rest) IN IF ~orderAcknowledgmentReturnBitfield13.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(orderAcknowledgmentReturnBitfield13.rest, 1), orderAcknowledgmentReturnBitfield13.rest) IN IF ~orderAcknowledgmentReturnBitfield14.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield15 == ReadWhen(numberOfReturnBitfields.value >= 15, ReadBytes(orderAcknowledgmentReturnBitfield14.rest, 1), orderAcknowledgmentReturnBitfield14.rest) IN IF ~orderAcknowledgmentReturnBitfield15.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield16 == ReadWhen(numberOfReturnBitfields.value >= 16, ReadBytes(orderAcknowledgmentReturnBitfield15.rest, 1), orderAcknowledgmentReturnBitfield15.rest) IN IF ~orderAcknowledgmentReturnBitfield16.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield17 == ReadWhen(numberOfReturnBitfields.value >= 17, ReadBytes(orderAcknowledgmentReturnBitfield16.rest, 1), orderAcknowledgmentReturnBitfield16.rest) IN IF ~orderAcknowledgmentReturnBitfield17.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield18 == ReadWhen(numberOfReturnBitfields.value >= 18, ReadBytes(orderAcknowledgmentReturnBitfield17.rest, 1), orderAcknowledgmentReturnBitfield17.rest) IN IF ~orderAcknowledgmentReturnBitfield18.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield19 == ReadWhen(numberOfReturnBitfields.value >= 19, ReadBytes(orderAcknowledgmentReturnBitfield18.rest, 1), orderAcknowledgmentReturnBitfield18.rest) IN IF ~orderAcknowledgmentReturnBitfield19.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield20 == ReadWhen(numberOfReturnBitfields.value >= 20, ReadBytes(orderAcknowledgmentReturnBitfield19.rest, 1), orderAcknowledgmentReturnBitfield19.rest) IN IF ~orderAcknowledgmentReturnBitfield20.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield21 == ReadWhen(numberOfReturnBitfields.value >= 21, ReadBytes(orderAcknowledgmentReturnBitfield20.rest, 1), orderAcknowledgmentReturnBitfield20.rest) IN IF ~orderAcknowledgmentReturnBitfield21.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield22 == ReadWhen(numberOfReturnBitfields.value >= 22, ReadBytes(orderAcknowledgmentReturnBitfield21.rest, 1), orderAcknowledgmentReturnBitfield21.rest) IN IF ~orderAcknowledgmentReturnBitfield22.ok THEN Fail ELSE
    Ok([ messageType                         |-> messageType.value,
         numberOfReturnBitfields             |-> numberOfReturnBitfields.value,
         orderAcknowledgmentReturnBitfield1  |-> orderAcknowledgmentReturnBitfield1.value,
         orderAcknowledgmentReturnBitfield2  |-> orderAcknowledgmentReturnBitfield2.value,
         orderAcknowledgmentReturnBitfield3  |-> orderAcknowledgmentReturnBitfield3.value,
         orderAcknowledgmentReturnBitfield4  |-> orderAcknowledgmentReturnBitfield4.value,
         orderAcknowledgmentReturnBitfield5  |-> orderAcknowledgmentReturnBitfield5.value,
         orderAcknowledgmentReturnBitfield6  |-> orderAcknowledgmentReturnBitfield6.value,
         orderAcknowledgmentReturnBitfield7  |-> orderAcknowledgmentReturnBitfield7.value,
         orderAcknowledgmentReturnBitfield8  |-> orderAcknowledgmentReturnBitfield8.value,
         orderAcknowledgmentReturnBitfield9  |-> orderAcknowledgmentReturnBitfield9.value,
         orderAcknowledgmentReturnBitfield10 |-> orderAcknowledgmentReturnBitfield10.value,
         orderAcknowledgmentReturnBitfield11 |-> orderAcknowledgmentReturnBitfield11.value,
         orderAcknowledgmentReturnBitfield12 |-> orderAcknowledgmentReturnBitfield12.value,
         orderAcknowledgmentReturnBitfield13 |-> orderAcknowledgmentReturnBitfield13.value,
         orderAcknowledgmentReturnBitfield14 |-> orderAcknowledgmentReturnBitfield14.value,
         orderAcknowledgmentReturnBitfield15 |-> orderAcknowledgmentReturnBitfield15.value,
         orderAcknowledgmentReturnBitfield16 |-> orderAcknowledgmentReturnBitfield16.value,
         orderAcknowledgmentReturnBitfield17 |-> orderAcknowledgmentReturnBitfield17.value,
         orderAcknowledgmentReturnBitfield18 |-> orderAcknowledgmentReturnBitfield18.value,
         orderAcknowledgmentReturnBitfield19 |-> orderAcknowledgmentReturnBitfield19.value,
         orderAcknowledgmentReturnBitfield20 |-> orderAcknowledgmentReturnBitfield20.value,
         orderAcknowledgmentReturnBitfield21 |-> orderAcknowledgmentReturnBitfield21.value,
         orderAcknowledgmentReturnBitfield22 |-> orderAcknowledgmentReturnBitfield22.value ], orderAcknowledgmentReturnBitfield22.rest)

(* Return Bitfields Param Group with each field marked present by fields before it there exactly where they say *)
SettleReturnBitfieldsParamGroup(message) ==
    LET settled1 == [message EXCEPT !.orderAcknowledgmentReturnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.orderAcknowledgmentReturnBitfield1 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE message.orderAcknowledgmentReturnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.orderAcknowledgmentReturnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.orderAcknowledgmentReturnBitfield2 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled1.orderAcknowledgmentReturnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.orderAcknowledgmentReturnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.orderAcknowledgmentReturnBitfield3 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled2.orderAcknowledgmentReturnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.orderAcknowledgmentReturnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.orderAcknowledgmentReturnBitfield4 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled3.orderAcknowledgmentReturnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.orderAcknowledgmentReturnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.orderAcknowledgmentReturnBitfield5 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled4.orderAcknowledgmentReturnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.orderAcknowledgmentReturnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.orderAcknowledgmentReturnBitfield6 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled5.orderAcknowledgmentReturnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.orderAcknowledgmentReturnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.orderAcknowledgmentReturnBitfield7 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.orderAcknowledgmentReturnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.orderAcknowledgmentReturnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.orderAcknowledgmentReturnBitfield8 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled7.orderAcknowledgmentReturnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.orderAcknowledgmentReturnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.orderAcknowledgmentReturnBitfield9 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled8.orderAcknowledgmentReturnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.orderAcknowledgmentReturnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.orderAcknowledgmentReturnBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.orderAcknowledgmentReturnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.orderAcknowledgmentReturnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.orderAcknowledgmentReturnBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.orderAcknowledgmentReturnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.orderAcknowledgmentReturnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.orderAcknowledgmentReturnBitfield12 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.orderAcknowledgmentReturnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.orderAcknowledgmentReturnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.orderAcknowledgmentReturnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.orderAcknowledgmentReturnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.orderAcknowledgmentReturnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.orderAcknowledgmentReturnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.orderAcknowledgmentReturnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.orderAcknowledgmentReturnBitfield15 = IF settled14.numberOfReturnBitfields >= 15 THEN (IF settled14.orderAcknowledgmentReturnBitfield15 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.orderAcknowledgmentReturnBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.orderAcknowledgmentReturnBitfield16 = IF settled15.numberOfReturnBitfields >= 16 THEN (IF settled15.orderAcknowledgmentReturnBitfield16 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled15.orderAcknowledgmentReturnBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.orderAcknowledgmentReturnBitfield17 = IF settled16.numberOfReturnBitfields >= 17 THEN (IF settled16.orderAcknowledgmentReturnBitfield17 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled16.orderAcknowledgmentReturnBitfield17) ELSE << >>]
        settled18 == [settled17 EXCEPT !.orderAcknowledgmentReturnBitfield18 = IF settled17.numberOfReturnBitfields >= 18 THEN (IF settled17.orderAcknowledgmentReturnBitfield18 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.orderAcknowledgmentReturnBitfield18) ELSE << >>]
        settled19 == [settled18 EXCEPT !.orderAcknowledgmentReturnBitfield19 = IF settled18.numberOfReturnBitfields >= 19 THEN (IF settled18.orderAcknowledgmentReturnBitfield19 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled18.orderAcknowledgmentReturnBitfield19) ELSE << >>]
        settled20 == [settled19 EXCEPT !.orderAcknowledgmentReturnBitfield20 = IF settled19.numberOfReturnBitfields >= 20 THEN (IF settled19.orderAcknowledgmentReturnBitfield20 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled19.orderAcknowledgmentReturnBitfield20) ELSE << >>]
        settled21 == [settled20 EXCEPT !.orderAcknowledgmentReturnBitfield21 = IF settled20.numberOfReturnBitfields >= 21 THEN (IF settled20.orderAcknowledgmentReturnBitfield21 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled20.orderAcknowledgmentReturnBitfield21) ELSE << >>]
        settled22 == [settled21 EXCEPT !.orderAcknowledgmentReturnBitfield22 = IF settled21.numberOfReturnBitfields >= 22 THEN (IF settled21.orderAcknowledgmentReturnBitfield22 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled21.orderAcknowledgmentReturnBitfield22) ELSE << >>]
    IN  settled22

ZeroReturnBitfieldsParamGroup ==
    SettleReturnBitfieldsParamGroup([ messageType                         |-> [i \in 1 .. 1 |-> 0],
                                      numberOfReturnBitfields             |-> 0,
                                      orderAcknowledgmentReturnBitfield1  |-> << >>,
                                      orderAcknowledgmentReturnBitfield2  |-> << >>,
                                      orderAcknowledgmentReturnBitfield3  |-> << >>,
                                      orderAcknowledgmentReturnBitfield4  |-> << >>,
                                      orderAcknowledgmentReturnBitfield5  |-> << >>,
                                      orderAcknowledgmentReturnBitfield6  |-> << >>,
                                      orderAcknowledgmentReturnBitfield7  |-> << >>,
                                      orderAcknowledgmentReturnBitfield8  |-> << >>,
                                      orderAcknowledgmentReturnBitfield9  |-> << >>,
                                      orderAcknowledgmentReturnBitfield10 |-> << >>,
                                      orderAcknowledgmentReturnBitfield11 |-> << >>,
                                      orderAcknowledgmentReturnBitfield12 |-> << >>,
                                      orderAcknowledgmentReturnBitfield13 |-> << >>,
                                      orderAcknowledgmentReturnBitfield14 |-> << >>,
                                      orderAcknowledgmentReturnBitfield15 |-> << >>,
                                      orderAcknowledgmentReturnBitfield16 |-> << >>,
                                      orderAcknowledgmentReturnBitfield17 |-> << >>,
                                      orderAcknowledgmentReturnBitfield18 |-> << >>,
                                      orderAcknowledgmentReturnBitfield19 |-> << >>,
                                      orderAcknowledgmentReturnBitfield20 |-> << >>,
                                      orderAcknowledgmentReturnBitfield21 |-> << >>,
                                      orderAcknowledgmentReturnBitfield22 |-> << >> ])

(* Return Bitfields Param Group at zero, then each field in turn at the values it is checked at *)
CheckedReturnBitfieldsParamGroup ==
    { ZeroReturnBitfieldsParamGroup }
        \cup { SettleReturnBitfieldsParamGroup([ZeroReturnBitfieldsParamGroup EXCEPT !.messageType = one]) : one \in Sample(1) }
        \cup { SettleReturnBitfieldsParamGroup([ZeroReturnBitfieldsParamGroup EXCEPT !.numberOfReturnBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleReturnBitfieldsParamGroup([ZeroReturnBitfieldsParamGroup EXCEPT !.numberOfReturnBitfields = 1, !.orderAcknowledgmentReturnBitfield1 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup([ZeroReturnBitfieldsParamGroup EXCEPT !.numberOfReturnBitfields = 2, !.orderAcknowledgmentReturnBitfield2 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup([ZeroReturnBitfieldsParamGroup EXCEPT !.numberOfReturnBitfields = 3, !.orderAcknowledgmentReturnBitfield3 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup([ZeroReturnBitfieldsParamGroup EXCEPT !.numberOfReturnBitfields = 4, !.orderAcknowledgmentReturnBitfield4 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup([ZeroReturnBitfieldsParamGroup EXCEPT !.numberOfReturnBitfields = 5, !.orderAcknowledgmentReturnBitfield5 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup([ZeroReturnBitfieldsParamGroup EXCEPT !.numberOfReturnBitfields = 6, !.orderAcknowledgmentReturnBitfield6 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup([ZeroReturnBitfieldsParamGroup EXCEPT !.numberOfReturnBitfields = 7, !.orderAcknowledgmentReturnBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup([ZeroReturnBitfieldsParamGroup EXCEPT !.numberOfReturnBitfields = 8, !.orderAcknowledgmentReturnBitfield8 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup([ZeroReturnBitfieldsParamGroup EXCEPT !.numberOfReturnBitfields = 9, !.orderAcknowledgmentReturnBitfield9 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup([ZeroReturnBitfieldsParamGroup EXCEPT !.numberOfReturnBitfields = 10, !.orderAcknowledgmentReturnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup([ZeroReturnBitfieldsParamGroup EXCEPT !.numberOfReturnBitfields = 11, !.orderAcknowledgmentReturnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup([ZeroReturnBitfieldsParamGroup EXCEPT !.numberOfReturnBitfields = 12, !.orderAcknowledgmentReturnBitfield12 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup([ZeroReturnBitfieldsParamGroup EXCEPT !.numberOfReturnBitfields = 13, !.orderAcknowledgmentReturnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup([ZeroReturnBitfieldsParamGroup EXCEPT !.numberOfReturnBitfields = 14, !.orderAcknowledgmentReturnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup([ZeroReturnBitfieldsParamGroup EXCEPT !.numberOfReturnBitfields = 15, !.orderAcknowledgmentReturnBitfield15 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup([ZeroReturnBitfieldsParamGroup EXCEPT !.numberOfReturnBitfields = 16, !.orderAcknowledgmentReturnBitfield16 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup([ZeroReturnBitfieldsParamGroup EXCEPT !.numberOfReturnBitfields = 17, !.orderAcknowledgmentReturnBitfield17 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup([ZeroReturnBitfieldsParamGroup EXCEPT !.numberOfReturnBitfields = 18, !.orderAcknowledgmentReturnBitfield18 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup([ZeroReturnBitfieldsParamGroup EXCEPT !.numberOfReturnBitfields = 19, !.orderAcknowledgmentReturnBitfield19 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup([ZeroReturnBitfieldsParamGroup EXCEPT !.numberOfReturnBitfields = 20, !.orderAcknowledgmentReturnBitfield20 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup([ZeroReturnBitfieldsParamGroup EXCEPT !.numberOfReturnBitfields = 21, !.orderAcknowledgmentReturnBitfield21 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup([ZeroReturnBitfieldsParamGroup EXCEPT !.numberOfReturnBitfields = 22, !.orderAcknowledgmentReturnBitfield22 = one]) : one \in { <<held>> : held \in Sample(1) } }

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
(* Units: 5 bytes                                                          *)
(***************************************************************************)

Units2 ==
    [ unitNumber   : Sample(1),
      unitSequence : Sample(4) ]

EncodeUnits2(message) ==
    message.unitNumber
        \o message.unitSequence

DecodeUnits2(bytes) ==
    LET unitNumber == ReadBytes(bytes, 1) IN IF ~unitNumber.ok THEN Fail ELSE
    LET unitSequence == ReadBytes(unitNumber.rest, 4) IN IF ~unitSequence.ok THEN Fail ELSE
    Ok([ unitNumber   |-> unitNumber.value,
         unitSequence |-> unitSequence.value ], unitSequence.rest)

ZeroUnits2 ==
    [ unitNumber   |-> [i \in 1 .. 1 |-> 0],
      unitSequence |-> [i \in 1 .. 4 |-> 0] ]

(* Units at zero, then each field in turn at the values it is checked at *)
CheckedUnits2 ==
    { ZeroUnits2 }
        \cup { [ZeroUnits2 EXCEPT !.unitNumber = one] : one \in Sample(1) }
        \cup { [ZeroUnits2 EXCEPT !.unitSequence = one] : one \in Sample(4) }

(* A run of Units, written one after another *)
RECURSIVE EncodeUnits2List(_)
EncodeUnits2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeUnits2(Head(messages)) \o EncodeUnits2List(Tail(messages))

(* As many Units as the field that counts them says *)
RECURSIVE ReadUnits2List(_, _)
ReadUnits2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeUnits2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadUnits2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Units of each kind, for the lists that carry them *)
OneUnits2 == { ZeroUnits2 }

(***************************************************************************)
(* Units: 5 bytes                                                          *)
(***************************************************************************)

Units3 ==
    [ unitNumber   : Sample(1),
      unitSequence : Sample(4) ]

EncodeUnits3(message) ==
    message.unitNumber
        \o message.unitSequence

DecodeUnits3(bytes) ==
    LET unitNumber == ReadBytes(bytes, 1) IN IF ~unitNumber.ok THEN Fail ELSE
    LET unitSequence == ReadBytes(unitNumber.rest, 4) IN IF ~unitSequence.ok THEN Fail ELSE
    Ok([ unitNumber   |-> unitNumber.value,
         unitSequence |-> unitSequence.value ], unitSequence.rest)

ZeroUnits3 ==
    [ unitNumber   |-> [i \in 1 .. 1 |-> 0],
      unitSequence |-> [i \in 1 .. 4 |-> 0] ]

(* Units at zero, then each field in turn at the values it is checked at *)
CheckedUnits3 ==
    { ZeroUnits3 }
        \cup { [ZeroUnits3 EXCEPT !.unitNumber = one] : one \in Sample(1) }
        \cup { [ZeroUnits3 EXCEPT !.unitSequence = one] : one \in Sample(4) }

(* A run of Units, written one after another *)
RECURSIVE EncodeUnits3List(_)
EncodeUnits3List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeUnits3(Head(messages)) \o EncodeUnits3List(Tail(messages))

(* As many Units as the field that counts them says *)
RECURSIVE ReadUnits3List(_, _)
ReadUnits3List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeUnits3(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadUnits3List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Units of each kind, for the lists that carry them *)
OneUnits3 == { ZeroUnits3 }

(***************************************************************************)
(* Unit Sequences Param Group                                              *)
(***************************************************************************)

UnitSequencesParamGroup2 ==
    [ noUnspecifiedUnitReplay : Sample(1),
      units                   : SampleLists(OneUnits3) ]

EncodeUnitSequencesParamGroup2(message) ==
    message.noUnspecifiedUnitReplay
        \o EncodeUIntBE(Len(message.units), 1)
        \o EncodeUnits3List(message.units)

DecodeUnitSequencesParamGroup2(bytes) ==
    LET noUnspecifiedUnitReplay == ReadBytes(bytes, 1) IN IF ~noUnspecifiedUnitReplay.ok THEN Fail ELSE
    LET numberOfUnits == ReadUIntBE(noUnspecifiedUnitReplay.rest, 1) IN IF ~numberOfUnits.ok THEN Fail ELSE
    LET units == ReadUnits3List(numberOfUnits.rest, numberOfUnits.value) IN IF ~units.ok THEN Fail ELSE
    Ok([ noUnspecifiedUnitReplay |-> noUnspecifiedUnitReplay.value,
         units                   |-> units.value ], units.rest)

ZeroUnitSequencesParamGroup2 ==
    [ noUnspecifiedUnitReplay |-> [i \in 1 .. 1 |-> 0],
      units                   |-> << >> ]

(* Unit Sequences Param Group at zero, then each field in turn at the values it is checked at *)
CheckedUnitSequencesParamGroup2 ==
    { ZeroUnitSequencesParamGroup2 }
        \cup { [ZeroUnitSequencesParamGroup2 EXCEPT !.noUnspecifiedUnitReplay = one] : one \in Sample(1) }
        \cup { [ZeroUnitSequencesParamGroup2 EXCEPT !.units = one] : one \in SampleLists(OneUnits3) }

(***************************************************************************)
(* Return Bitfields Param Group                                            *)
(***************************************************************************)

ReturnBitfieldsParamGroup2 ==
    [ messageType                         : Sample(1),
      numberOfReturnBitfields             : 0 .. 255,
      orderAcknowledgmentReturnBitfield1  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield2  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield3  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield4  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield5  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield6  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield7  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield8  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield9  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield10 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield11 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield12 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield13 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield14 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield15 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield16 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield17 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield18 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield19 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield20 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield21 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield22 : { << >> } \cup { <<held>> : held \in Sample(1) } ]

EncodeReturnBitfieldsParamGroup2(message) ==
    message.messageType
        \o EncodeUIntBE(message.numberOfReturnBitfields, 1)
        \o (IF message.orderAcknowledgmentReturnBitfield1 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield1[1])
        \o (IF message.orderAcknowledgmentReturnBitfield2 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield2[1])
        \o (IF message.orderAcknowledgmentReturnBitfield3 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield3[1])
        \o (IF message.orderAcknowledgmentReturnBitfield4 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield4[1])
        \o (IF message.orderAcknowledgmentReturnBitfield5 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield5[1])
        \o (IF message.orderAcknowledgmentReturnBitfield6 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield6[1])
        \o (IF message.orderAcknowledgmentReturnBitfield7 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield7[1])
        \o (IF message.orderAcknowledgmentReturnBitfield8 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield8[1])
        \o (IF message.orderAcknowledgmentReturnBitfield9 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield9[1])
        \o (IF message.orderAcknowledgmentReturnBitfield10 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield10[1])
        \o (IF message.orderAcknowledgmentReturnBitfield11 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield11[1])
        \o (IF message.orderAcknowledgmentReturnBitfield12 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield12[1])
        \o (IF message.orderAcknowledgmentReturnBitfield13 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield13[1])
        \o (IF message.orderAcknowledgmentReturnBitfield14 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield14[1])
        \o (IF message.orderAcknowledgmentReturnBitfield15 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield15[1])
        \o (IF message.orderAcknowledgmentReturnBitfield16 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield16[1])
        \o (IF message.orderAcknowledgmentReturnBitfield17 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield17[1])
        \o (IF message.orderAcknowledgmentReturnBitfield18 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield18[1])
        \o (IF message.orderAcknowledgmentReturnBitfield19 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield19[1])
        \o (IF message.orderAcknowledgmentReturnBitfield20 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield20[1])
        \o (IF message.orderAcknowledgmentReturnBitfield21 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield21[1])
        \o (IF message.orderAcknowledgmentReturnBitfield22 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield22[1])

DecodeReturnBitfieldsParamGroup2(bytes) ==
    LET messageType == ReadBytes(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET numberOfReturnBitfields == ReadUIntBE(messageType.rest, 1) IN IF ~numberOfReturnBitfields.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield1 == ReadWhen(numberOfReturnBitfields.value >= 1, ReadBytes(numberOfReturnBitfields.rest, 1), numberOfReturnBitfields.rest) IN IF ~orderAcknowledgmentReturnBitfield1.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield2 == ReadWhen(numberOfReturnBitfields.value >= 2, ReadBytes(orderAcknowledgmentReturnBitfield1.rest, 1), orderAcknowledgmentReturnBitfield1.rest) IN IF ~orderAcknowledgmentReturnBitfield2.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield3 == ReadWhen(numberOfReturnBitfields.value >= 3, ReadBytes(orderAcknowledgmentReturnBitfield2.rest, 1), orderAcknowledgmentReturnBitfield2.rest) IN IF ~orderAcknowledgmentReturnBitfield3.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadBytes(orderAcknowledgmentReturnBitfield3.rest, 1), orderAcknowledgmentReturnBitfield3.rest) IN IF ~orderAcknowledgmentReturnBitfield4.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadBytes(orderAcknowledgmentReturnBitfield4.rest, 1), orderAcknowledgmentReturnBitfield4.rest) IN IF ~orderAcknowledgmentReturnBitfield5.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadBytes(orderAcknowledgmentReturnBitfield5.rest, 1), orderAcknowledgmentReturnBitfield5.rest) IN IF ~orderAcknowledgmentReturnBitfield6.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadBytes(orderAcknowledgmentReturnBitfield6.rest, 1), orderAcknowledgmentReturnBitfield6.rest) IN IF ~orderAcknowledgmentReturnBitfield7.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadBytes(orderAcknowledgmentReturnBitfield7.rest, 1), orderAcknowledgmentReturnBitfield7.rest) IN IF ~orderAcknowledgmentReturnBitfield8.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadBytes(orderAcknowledgmentReturnBitfield8.rest, 1), orderAcknowledgmentReturnBitfield8.rest) IN IF ~orderAcknowledgmentReturnBitfield9.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadBytes(orderAcknowledgmentReturnBitfield9.rest, 1), orderAcknowledgmentReturnBitfield9.rest) IN IF ~orderAcknowledgmentReturnBitfield10.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadBytes(orderAcknowledgmentReturnBitfield10.rest, 1), orderAcknowledgmentReturnBitfield10.rest) IN IF ~orderAcknowledgmentReturnBitfield11.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadBytes(orderAcknowledgmentReturnBitfield11.rest, 1), orderAcknowledgmentReturnBitfield11.rest) IN IF ~orderAcknowledgmentReturnBitfield12.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(orderAcknowledgmentReturnBitfield12.rest, 1), orderAcknowledgmentReturnBitfield12.rest) IN IF ~orderAcknowledgmentReturnBitfield13.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(orderAcknowledgmentReturnBitfield13.rest, 1), orderAcknowledgmentReturnBitfield13.rest) IN IF ~orderAcknowledgmentReturnBitfield14.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield15 == ReadWhen(numberOfReturnBitfields.value >= 15, ReadBytes(orderAcknowledgmentReturnBitfield14.rest, 1), orderAcknowledgmentReturnBitfield14.rest) IN IF ~orderAcknowledgmentReturnBitfield15.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield16 == ReadWhen(numberOfReturnBitfields.value >= 16, ReadBytes(orderAcknowledgmentReturnBitfield15.rest, 1), orderAcknowledgmentReturnBitfield15.rest) IN IF ~orderAcknowledgmentReturnBitfield16.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield17 == ReadWhen(numberOfReturnBitfields.value >= 17, ReadBytes(orderAcknowledgmentReturnBitfield16.rest, 1), orderAcknowledgmentReturnBitfield16.rest) IN IF ~orderAcknowledgmentReturnBitfield17.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield18 == ReadWhen(numberOfReturnBitfields.value >= 18, ReadBytes(orderAcknowledgmentReturnBitfield17.rest, 1), orderAcknowledgmentReturnBitfield17.rest) IN IF ~orderAcknowledgmentReturnBitfield18.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield19 == ReadWhen(numberOfReturnBitfields.value >= 19, ReadBytes(orderAcknowledgmentReturnBitfield18.rest, 1), orderAcknowledgmentReturnBitfield18.rest) IN IF ~orderAcknowledgmentReturnBitfield19.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield20 == ReadWhen(numberOfReturnBitfields.value >= 20, ReadBytes(orderAcknowledgmentReturnBitfield19.rest, 1), orderAcknowledgmentReturnBitfield19.rest) IN IF ~orderAcknowledgmentReturnBitfield20.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield21 == ReadWhen(numberOfReturnBitfields.value >= 21, ReadBytes(orderAcknowledgmentReturnBitfield20.rest, 1), orderAcknowledgmentReturnBitfield20.rest) IN IF ~orderAcknowledgmentReturnBitfield21.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield22 == ReadWhen(numberOfReturnBitfields.value >= 22, ReadBytes(orderAcknowledgmentReturnBitfield21.rest, 1), orderAcknowledgmentReturnBitfield21.rest) IN IF ~orderAcknowledgmentReturnBitfield22.ok THEN Fail ELSE
    Ok([ messageType                         |-> messageType.value,
         numberOfReturnBitfields             |-> numberOfReturnBitfields.value,
         orderAcknowledgmentReturnBitfield1  |-> orderAcknowledgmentReturnBitfield1.value,
         orderAcknowledgmentReturnBitfield2  |-> orderAcknowledgmentReturnBitfield2.value,
         orderAcknowledgmentReturnBitfield3  |-> orderAcknowledgmentReturnBitfield3.value,
         orderAcknowledgmentReturnBitfield4  |-> orderAcknowledgmentReturnBitfield4.value,
         orderAcknowledgmentReturnBitfield5  |-> orderAcknowledgmentReturnBitfield5.value,
         orderAcknowledgmentReturnBitfield6  |-> orderAcknowledgmentReturnBitfield6.value,
         orderAcknowledgmentReturnBitfield7  |-> orderAcknowledgmentReturnBitfield7.value,
         orderAcknowledgmentReturnBitfield8  |-> orderAcknowledgmentReturnBitfield8.value,
         orderAcknowledgmentReturnBitfield9  |-> orderAcknowledgmentReturnBitfield9.value,
         orderAcknowledgmentReturnBitfield10 |-> orderAcknowledgmentReturnBitfield10.value,
         orderAcknowledgmentReturnBitfield11 |-> orderAcknowledgmentReturnBitfield11.value,
         orderAcknowledgmentReturnBitfield12 |-> orderAcknowledgmentReturnBitfield12.value,
         orderAcknowledgmentReturnBitfield13 |-> orderAcknowledgmentReturnBitfield13.value,
         orderAcknowledgmentReturnBitfield14 |-> orderAcknowledgmentReturnBitfield14.value,
         orderAcknowledgmentReturnBitfield15 |-> orderAcknowledgmentReturnBitfield15.value,
         orderAcknowledgmentReturnBitfield16 |-> orderAcknowledgmentReturnBitfield16.value,
         orderAcknowledgmentReturnBitfield17 |-> orderAcknowledgmentReturnBitfield17.value,
         orderAcknowledgmentReturnBitfield18 |-> orderAcknowledgmentReturnBitfield18.value,
         orderAcknowledgmentReturnBitfield19 |-> orderAcknowledgmentReturnBitfield19.value,
         orderAcknowledgmentReturnBitfield20 |-> orderAcknowledgmentReturnBitfield20.value,
         orderAcknowledgmentReturnBitfield21 |-> orderAcknowledgmentReturnBitfield21.value,
         orderAcknowledgmentReturnBitfield22 |-> orderAcknowledgmentReturnBitfield22.value ], orderAcknowledgmentReturnBitfield22.rest)

(* Return Bitfields Param Group with each field marked present by fields before it there exactly where they say *)
SettleReturnBitfieldsParamGroup2(message) ==
    LET settled1 == [message EXCEPT !.orderAcknowledgmentReturnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.orderAcknowledgmentReturnBitfield1 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE message.orderAcknowledgmentReturnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.orderAcknowledgmentReturnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.orderAcknowledgmentReturnBitfield2 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled1.orderAcknowledgmentReturnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.orderAcknowledgmentReturnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.orderAcknowledgmentReturnBitfield3 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled2.orderAcknowledgmentReturnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.orderAcknowledgmentReturnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.orderAcknowledgmentReturnBitfield4 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled3.orderAcknowledgmentReturnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.orderAcknowledgmentReturnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.orderAcknowledgmentReturnBitfield5 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled4.orderAcknowledgmentReturnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.orderAcknowledgmentReturnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.orderAcknowledgmentReturnBitfield6 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled5.orderAcknowledgmentReturnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.orderAcknowledgmentReturnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.orderAcknowledgmentReturnBitfield7 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.orderAcknowledgmentReturnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.orderAcknowledgmentReturnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.orderAcknowledgmentReturnBitfield8 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled7.orderAcknowledgmentReturnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.orderAcknowledgmentReturnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.orderAcknowledgmentReturnBitfield9 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled8.orderAcknowledgmentReturnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.orderAcknowledgmentReturnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.orderAcknowledgmentReturnBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.orderAcknowledgmentReturnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.orderAcknowledgmentReturnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.orderAcknowledgmentReturnBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.orderAcknowledgmentReturnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.orderAcknowledgmentReturnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.orderAcknowledgmentReturnBitfield12 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.orderAcknowledgmentReturnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.orderAcknowledgmentReturnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.orderAcknowledgmentReturnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.orderAcknowledgmentReturnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.orderAcknowledgmentReturnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.orderAcknowledgmentReturnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.orderAcknowledgmentReturnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.orderAcknowledgmentReturnBitfield15 = IF settled14.numberOfReturnBitfields >= 15 THEN (IF settled14.orderAcknowledgmentReturnBitfield15 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.orderAcknowledgmentReturnBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.orderAcknowledgmentReturnBitfield16 = IF settled15.numberOfReturnBitfields >= 16 THEN (IF settled15.orderAcknowledgmentReturnBitfield16 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled15.orderAcknowledgmentReturnBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.orderAcknowledgmentReturnBitfield17 = IF settled16.numberOfReturnBitfields >= 17 THEN (IF settled16.orderAcknowledgmentReturnBitfield17 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled16.orderAcknowledgmentReturnBitfield17) ELSE << >>]
        settled18 == [settled17 EXCEPT !.orderAcknowledgmentReturnBitfield18 = IF settled17.numberOfReturnBitfields >= 18 THEN (IF settled17.orderAcknowledgmentReturnBitfield18 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.orderAcknowledgmentReturnBitfield18) ELSE << >>]
        settled19 == [settled18 EXCEPT !.orderAcknowledgmentReturnBitfield19 = IF settled18.numberOfReturnBitfields >= 19 THEN (IF settled18.orderAcknowledgmentReturnBitfield19 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled18.orderAcknowledgmentReturnBitfield19) ELSE << >>]
        settled20 == [settled19 EXCEPT !.orderAcknowledgmentReturnBitfield20 = IF settled19.numberOfReturnBitfields >= 20 THEN (IF settled19.orderAcknowledgmentReturnBitfield20 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled19.orderAcknowledgmentReturnBitfield20) ELSE << >>]
        settled21 == [settled20 EXCEPT !.orderAcknowledgmentReturnBitfield21 = IF settled20.numberOfReturnBitfields >= 21 THEN (IF settled20.orderAcknowledgmentReturnBitfield21 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled20.orderAcknowledgmentReturnBitfield21) ELSE << >>]
        settled22 == [settled21 EXCEPT !.orderAcknowledgmentReturnBitfield22 = IF settled21.numberOfReturnBitfields >= 22 THEN (IF settled21.orderAcknowledgmentReturnBitfield22 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled21.orderAcknowledgmentReturnBitfield22) ELSE << >>]
    IN  settled22

ZeroReturnBitfieldsParamGroup2 ==
    SettleReturnBitfieldsParamGroup2([ messageType                         |-> [i \in 1 .. 1 |-> 0],
                                       numberOfReturnBitfields             |-> 0,
                                       orderAcknowledgmentReturnBitfield1  |-> << >>,
                                       orderAcknowledgmentReturnBitfield2  |-> << >>,
                                       orderAcknowledgmentReturnBitfield3  |-> << >>,
                                       orderAcknowledgmentReturnBitfield4  |-> << >>,
                                       orderAcknowledgmentReturnBitfield5  |-> << >>,
                                       orderAcknowledgmentReturnBitfield6  |-> << >>,
                                       orderAcknowledgmentReturnBitfield7  |-> << >>,
                                       orderAcknowledgmentReturnBitfield8  |-> << >>,
                                       orderAcknowledgmentReturnBitfield9  |-> << >>,
                                       orderAcknowledgmentReturnBitfield10 |-> << >>,
                                       orderAcknowledgmentReturnBitfield11 |-> << >>,
                                       orderAcknowledgmentReturnBitfield12 |-> << >>,
                                       orderAcknowledgmentReturnBitfield13 |-> << >>,
                                       orderAcknowledgmentReturnBitfield14 |-> << >>,
                                       orderAcknowledgmentReturnBitfield15 |-> << >>,
                                       orderAcknowledgmentReturnBitfield16 |-> << >>,
                                       orderAcknowledgmentReturnBitfield17 |-> << >>,
                                       orderAcknowledgmentReturnBitfield18 |-> << >>,
                                       orderAcknowledgmentReturnBitfield19 |-> << >>,
                                       orderAcknowledgmentReturnBitfield20 |-> << >>,
                                       orderAcknowledgmentReturnBitfield21 |-> << >>,
                                       orderAcknowledgmentReturnBitfield22 |-> << >> ])

(* Return Bitfields Param Group at zero, then each field in turn at the values it is checked at *)
CheckedReturnBitfieldsParamGroup2 ==
    { ZeroReturnBitfieldsParamGroup2 }
        \cup { SettleReturnBitfieldsParamGroup2([ZeroReturnBitfieldsParamGroup2 EXCEPT !.messageType = one]) : one \in Sample(1) }
        \cup { SettleReturnBitfieldsParamGroup2([ZeroReturnBitfieldsParamGroup2 EXCEPT !.numberOfReturnBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleReturnBitfieldsParamGroup2([ZeroReturnBitfieldsParamGroup2 EXCEPT !.numberOfReturnBitfields = 1, !.orderAcknowledgmentReturnBitfield1 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup2([ZeroReturnBitfieldsParamGroup2 EXCEPT !.numberOfReturnBitfields = 2, !.orderAcknowledgmentReturnBitfield2 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup2([ZeroReturnBitfieldsParamGroup2 EXCEPT !.numberOfReturnBitfields = 3, !.orderAcknowledgmentReturnBitfield3 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup2([ZeroReturnBitfieldsParamGroup2 EXCEPT !.numberOfReturnBitfields = 4, !.orderAcknowledgmentReturnBitfield4 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup2([ZeroReturnBitfieldsParamGroup2 EXCEPT !.numberOfReturnBitfields = 5, !.orderAcknowledgmentReturnBitfield5 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup2([ZeroReturnBitfieldsParamGroup2 EXCEPT !.numberOfReturnBitfields = 6, !.orderAcknowledgmentReturnBitfield6 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup2([ZeroReturnBitfieldsParamGroup2 EXCEPT !.numberOfReturnBitfields = 7, !.orderAcknowledgmentReturnBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup2([ZeroReturnBitfieldsParamGroup2 EXCEPT !.numberOfReturnBitfields = 8, !.orderAcknowledgmentReturnBitfield8 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup2([ZeroReturnBitfieldsParamGroup2 EXCEPT !.numberOfReturnBitfields = 9, !.orderAcknowledgmentReturnBitfield9 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup2([ZeroReturnBitfieldsParamGroup2 EXCEPT !.numberOfReturnBitfields = 10, !.orderAcknowledgmentReturnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup2([ZeroReturnBitfieldsParamGroup2 EXCEPT !.numberOfReturnBitfields = 11, !.orderAcknowledgmentReturnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup2([ZeroReturnBitfieldsParamGroup2 EXCEPT !.numberOfReturnBitfields = 12, !.orderAcknowledgmentReturnBitfield12 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup2([ZeroReturnBitfieldsParamGroup2 EXCEPT !.numberOfReturnBitfields = 13, !.orderAcknowledgmentReturnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup2([ZeroReturnBitfieldsParamGroup2 EXCEPT !.numberOfReturnBitfields = 14, !.orderAcknowledgmentReturnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup2([ZeroReturnBitfieldsParamGroup2 EXCEPT !.numberOfReturnBitfields = 15, !.orderAcknowledgmentReturnBitfield15 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup2([ZeroReturnBitfieldsParamGroup2 EXCEPT !.numberOfReturnBitfields = 16, !.orderAcknowledgmentReturnBitfield16 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup2([ZeroReturnBitfieldsParamGroup2 EXCEPT !.numberOfReturnBitfields = 17, !.orderAcknowledgmentReturnBitfield17 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup2([ZeroReturnBitfieldsParamGroup2 EXCEPT !.numberOfReturnBitfields = 18, !.orderAcknowledgmentReturnBitfield18 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup2([ZeroReturnBitfieldsParamGroup2 EXCEPT !.numberOfReturnBitfields = 19, !.orderAcknowledgmentReturnBitfield19 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup2([ZeroReturnBitfieldsParamGroup2 EXCEPT !.numberOfReturnBitfields = 20, !.orderAcknowledgmentReturnBitfield20 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup2([ZeroReturnBitfieldsParamGroup2 EXCEPT !.numberOfReturnBitfields = 21, !.orderAcknowledgmentReturnBitfield21 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReturnBitfieldsParamGroup2([ZeroReturnBitfieldsParamGroup2 EXCEPT !.numberOfReturnBitfields = 22, !.orderAcknowledgmentReturnBitfield22 = one]) : one \in { <<held>> : held \in Sample(1) } }

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
      units                      : SampleLists(OneUnits2),
      paramGroup                 : SampleLists(OneParamGroup2) ]

EncodeLoginResponseMessage(message) ==
    message.loginResponseStatus
        \o message.loginResponseText
        \o message.noUnspecifiedUnitReplay
        \o message.lastReceivedSequenceNumber
        \o EncodeUIntBE(Len(message.units), 1)
        \o EncodeUnits2List(message.units)
        \o EncodeUIntBE(Len(message.paramGroup), 1)
        \o EncodeParamGroup2List(message.paramGroup)

DecodeLoginResponseMessage(bytes) ==
    LET loginResponseStatus == ReadBytes(bytes, 1) IN IF ~loginResponseStatus.ok THEN Fail ELSE
    LET loginResponseText == ReadBytes(loginResponseStatus.rest, 60) IN IF ~loginResponseText.ok THEN Fail ELSE
    LET noUnspecifiedUnitReplay == ReadBytes(loginResponseText.rest, 1) IN IF ~noUnspecifiedUnitReplay.ok THEN Fail ELSE
    LET lastReceivedSequenceNumber == ReadBytes(noUnspecifiedUnitReplay.rest, 4) IN IF ~lastReceivedSequenceNumber.ok THEN Fail ELSE
    LET numberOfUnits == ReadUIntBE(lastReceivedSequenceNumber.rest, 1) IN IF ~numberOfUnits.ok THEN Fail ELSE
    LET units == ReadUnits2List(numberOfUnits.rest, numberOfUnits.value) IN IF ~units.ok THEN Fail ELSE
    LET numberOfParamGroups == ReadUIntBE(units.rest, 1) IN IF ~numberOfParamGroups.ok THEN Fail ELSE
    LET paramGroup == ReadParamGroup2List(numberOfParamGroups.rest, numberOfParamGroups.value) IN IF ~paramGroup.ok THEN Fail ELSE
    Ok([ loginResponseStatus        |-> loginResponseStatus.value,
         loginResponseText          |-> loginResponseText.value,
         noUnspecifiedUnitReplay    |-> noUnspecifiedUnitReplay.value,
         lastReceivedSequenceNumber |-> lastReceivedSequenceNumber.value,
         units                      |-> units.value,
         paramGroup                 |-> paramGroup.value ], paramGroup.rest)

ZeroLoginResponseMessage ==
    [ loginResponseStatus        |-> [i \in 1 .. 1 |-> 0],
      loginResponseText          |-> [i \in 1 .. 60 |-> 0],
      noUnspecifiedUnitReplay    |-> [i \in 1 .. 1 |-> 0],
      lastReceivedSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      units                      |-> << >>,
      paramGroup                 |-> << >> ]

(* Login Response Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginResponseMessage ==
    { ZeroLoginResponseMessage }
        \cup { [ZeroLoginResponseMessage EXCEPT !.loginResponseStatus = one] : one \in Sample(1) }
        \cup { [ZeroLoginResponseMessage EXCEPT !.loginResponseText = one] : one \in Sample(60) }
        \cup { [ZeroLoginResponseMessage EXCEPT !.noUnspecifiedUnitReplay = one] : one \in Sample(1) }
        \cup { [ZeroLoginResponseMessage EXCEPT !.lastReceivedSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroLoginResponseMessage EXCEPT !.units = one] : one \in SampleLists(OneUnits2) }
        \cup { [ZeroLoginResponseMessage EXCEPT !.paramGroup = one] : one \in SampleLists(OneParamGroup2) }

(***************************************************************************)
(* Units: 5 bytes                                                          *)
(***************************************************************************)

Units4 ==
    [ unitNumber   : Sample(1),
      unitSequence : Sample(4) ]

EncodeUnits4(message) ==
    message.unitNumber
        \o message.unitSequence

DecodeUnits4(bytes) ==
    LET unitNumber == ReadBytes(bytes, 1) IN IF ~unitNumber.ok THEN Fail ELSE
    LET unitSequence == ReadBytes(unitNumber.rest, 4) IN IF ~unitSequence.ok THEN Fail ELSE
    Ok([ unitNumber   |-> unitNumber.value,
         unitSequence |-> unitSequence.value ], unitSequence.rest)

ZeroUnits4 ==
    [ unitNumber   |-> [i \in 1 .. 1 |-> 0],
      unitSequence |-> [i \in 1 .. 4 |-> 0] ]

(* Units at zero, then each field in turn at the values it is checked at *)
CheckedUnits4 ==
    { ZeroUnits4 }
        \cup { [ZeroUnits4 EXCEPT !.unitNumber = one] : one \in Sample(1) }
        \cup { [ZeroUnits4 EXCEPT !.unitSequence = one] : one \in Sample(4) }

(* A run of Units, written one after another *)
RECURSIVE EncodeUnits4List(_)
EncodeUnits4List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeUnits4(Head(messages)) \o EncodeUnits4List(Tail(messages))

(* As many Units as the field that counts them says *)
RECURSIVE ReadUnits4List(_, _)
ReadUnits4List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeUnits4(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadUnits4List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Units of each kind, for the lists that carry them *)
OneUnits4 == { ZeroUnits4 }

(***************************************************************************)
(* Logout Message                                                          *)
(***************************************************************************)

LogoutMessage ==
    [ logoutReason               : Sample(1),
      logoutReasonText           : Sample(60),
      lastReceivedSequenceNumber : Sample(4),
      units                      : SampleLists(OneUnits4) ]

EncodeLogoutMessage(message) ==
    message.logoutReason
        \o message.logoutReasonText
        \o message.lastReceivedSequenceNumber
        \o EncodeUIntBE(Len(message.units), 1)
        \o EncodeUnits4List(message.units)

DecodeLogoutMessage(bytes) ==
    LET logoutReason == ReadBytes(bytes, 1) IN IF ~logoutReason.ok THEN Fail ELSE
    LET logoutReasonText == ReadBytes(logoutReason.rest, 60) IN IF ~logoutReasonText.ok THEN Fail ELSE
    LET lastReceivedSequenceNumber == ReadBytes(logoutReasonText.rest, 4) IN IF ~lastReceivedSequenceNumber.ok THEN Fail ELSE
    LET numberOfUnits == ReadUIntBE(lastReceivedSequenceNumber.rest, 1) IN IF ~numberOfUnits.ok THEN Fail ELSE
    LET units == ReadUnits4List(numberOfUnits.rest, numberOfUnits.value) IN IF ~units.ok THEN Fail ELSE
    Ok([ logoutReason               |-> logoutReason.value,
         logoutReasonText           |-> logoutReasonText.value,
         lastReceivedSequenceNumber |-> lastReceivedSequenceNumber.value,
         units                      |-> units.value ], units.rest)

ZeroLogoutMessage ==
    [ logoutReason               |-> [i \in 1 .. 1 |-> 0],
      logoutReasonText           |-> [i \in 1 .. 60 |-> 0],
      lastReceivedSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      units                      |-> << >> ]

(* Logout Message at zero, then each field in turn at the values it is checked at *)
CheckedLogoutMessage ==
    { ZeroLogoutMessage }
        \cup { [ZeroLogoutMessage EXCEPT !.logoutReason = one] : one \in Sample(1) }
        \cup { [ZeroLogoutMessage EXCEPT !.logoutReasonText = one] : one \in Sample(60) }
        \cup { [ZeroLogoutMessage EXCEPT !.lastReceivedSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroLogoutMessage EXCEPT !.units = one] : one \in SampleLists(OneUnits4) }

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
      newOrderBitfield11        : { << >> } \cup { <<held>> : held \in Sample(1) },
      newOrderBitfield12        : { << >> } \cup { <<held>> : held \in Sample(1) },
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
        \o (IF message.newOrderBitfield11 = << >> THEN << >> ELSE message.newOrderBitfield11[1])
        \o (IF message.newOrderBitfield12 = << >> THEN << >> ELSE message.newOrderBitfield12[1])
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
    LET newOrderBitfield11 == ReadWhen(numberOfNewOrderBitfields.value >= 11, ReadBytes(newOrderBitfield10.rest, 1), newOrderBitfield10.rest) IN IF ~newOrderBitfield11.ok THEN Fail ELSE
    LET newOrderBitfield12 == ReadWhen(numberOfNewOrderBitfields.value >= 12, ReadBytes(newOrderBitfield11.rest, 1), newOrderBitfield11.rest) IN IF ~newOrderBitfield12.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfNewOrderBitfields.value >= 1 /\ (newOrderBitfield1.value # << >> /\ newOrderBitfield1.value[1] % 2 > 0), ReadBytes(newOrderBitfield12.rest, 4), newOrderBitfield12.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
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
         newOrderBitfield11        |-> newOrderBitfield11.value,
         newOrderBitfield12        |-> newOrderBitfield12.value,
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
        settled11 == [settled10 EXCEPT !.newOrderBitfield11 = IF settled10.numberOfNewOrderBitfields >= 11 THEN (IF settled10.newOrderBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.newOrderBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.newOrderBitfield12 = IF settled11.numberOfNewOrderBitfields >= 12 THEN (IF settled11.newOrderBitfield12 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.newOrderBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.clearingFirm = IF settled12.numberOfNewOrderBitfields >= 1 /\ (settled12.newOrderBitfield1 # << >> /\ settled12.newOrderBitfield1[1] % 2 > 0) THEN (IF settled12.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled12.clearingFirm) ELSE << >>]
        settled14 == [settled13 EXCEPT !.clearingAccount = IF settled13.numberOfNewOrderBitfields >= 1 /\ (settled13.newOrderBitfield1 # << >> /\ (settled13.newOrderBitfield1[1] \div 2) % 2 > 0) THEN (IF settled13.clearingAccount = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled13.clearingAccount) ELSE << >>]
        settled15 == [settled14 EXCEPT !.price = IF settled14.numberOfNewOrderBitfields >= 1 /\ (settled14.newOrderBitfield1 # << >> /\ (settled14.newOrderBitfield1[1] \div 4) % 2 > 0) THEN (IF settled14.price = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled14.price) ELSE << >>]
        settled16 == [settled15 EXCEPT !.execInst = IF settled15.numberOfNewOrderBitfields >= 1 /\ (settled15.newOrderBitfield1 # << >> /\ (settled15.newOrderBitfield1[1] \div 8) % 2 > 0) THEN (IF settled15.execInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled15.execInst) ELSE << >>]
        settled17 == [settled16 EXCEPT !.ordType = IF settled16.numberOfNewOrderBitfields >= 1 /\ (settled16.newOrderBitfield1 # << >> /\ (settled16.newOrderBitfield1[1] \div 16) % 2 > 0) THEN (IF settled16.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled16.ordType) ELSE << >>]
        settled18 == [settled17 EXCEPT !.timeInForce = IF settled17.numberOfNewOrderBitfields >= 1 /\ (settled17.newOrderBitfield1 # << >> /\ (settled17.newOrderBitfield1[1] \div 32) % 2 > 0) THEN (IF settled17.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.timeInForce) ELSE << >>]
        settled19 == [settled18 EXCEPT !.minQty = IF settled18.numberOfNewOrderBitfields >= 1 /\ (settled18.newOrderBitfield1 # << >> /\ (settled18.newOrderBitfield1[1] \div 64) % 2 > 0) THEN (IF settled18.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled18.minQty) ELSE << >>]
        settled20 == [settled19 EXCEPT !.maxFloor = IF settled19.numberOfNewOrderBitfields >= 1 /\ (settled19.newOrderBitfield1 # << >> /\ (settled19.newOrderBitfield1[1] \div 128) % 2 > 0) THEN (IF settled19.maxFloor = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled19.maxFloor) ELSE << >>]
        settled21 == [settled20 EXCEPT !.symbol = IF settled20.numberOfNewOrderBitfields >= 2 /\ (settled20.newOrderBitfield2 # << >> /\ settled20.newOrderBitfield2[1] % 2 > 0) THEN (IF settled20.symbol = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled20.symbol) ELSE << >>]
        settled22 == [settled21 EXCEPT !.symbolSfx = IF settled21.numberOfNewOrderBitfields >= 2 /\ (settled21.newOrderBitfield2 # << >> /\ (settled21.newOrderBitfield2[1] \div 2) % 2 > 0) THEN (IF settled21.symbolSfx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled21.symbolSfx) ELSE << >>]
        settled23 == [settled22 EXCEPT !.capacity = IF settled22.numberOfNewOrderBitfields >= 2 /\ (settled22.newOrderBitfield2 # << >> /\ (settled22.newOrderBitfield2[1] \div 64) % 2 > 0) THEN (IF settled22.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled22.capacity) ELSE << >>]
        settled24 == [settled23 EXCEPT !.routingInst = IF settled23.numberOfNewOrderBitfields >= 2 /\ (settled23.newOrderBitfield2 # << >> /\ (settled23.newOrderBitfield2[1] \div 128) % 2 > 0) THEN (IF settled23.routingInst = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled23.routingInst) ELSE << >>]
        settled25 == [settled24 EXCEPT !.account = IF settled24.numberOfNewOrderBitfields >= 3 /\ (settled24.newOrderBitfield3 # << >> /\ settled24.newOrderBitfield3[1] % 2 > 0) THEN (IF settled24.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled24.account) ELSE << >>]
        settled26 == [settled25 EXCEPT !.displayIndicator = IF settled25.numberOfNewOrderBitfields >= 3 /\ (settled25.newOrderBitfield3 # << >> /\ (settled25.newOrderBitfield3[1] \div 2) % 2 > 0) THEN (IF settled25.displayIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled25.displayIndicator) ELSE << >>]
        settled27 == [settled26 EXCEPT !.discretionAmount = IF settled26.numberOfNewOrderBitfields >= 3 /\ (settled26.newOrderBitfield3 # << >> /\ (settled26.newOrderBitfield3[1] \div 8) % 2 > 0) THEN (IF settled26.discretionAmount = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled26.discretionAmount) ELSE << >>]
        settled28 == [settled27 EXCEPT !.pegDifference = IF settled27.numberOfNewOrderBitfields >= 3 /\ (settled27.newOrderBitfield3 # << >> /\ (settled27.newOrderBitfield3[1] \div 16) % 2 > 0) THEN (IF settled27.pegDifference = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled27.pegDifference) ELSE << >>]
        settled29 == [settled28 EXCEPT !.preventMatch = IF settled28.numberOfNewOrderBitfields >= 3 /\ (settled28.newOrderBitfield3 # << >> /\ (settled28.newOrderBitfield3[1] \div 32) % 2 > 0) THEN (IF settled28.preventMatch = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled28.preventMatch) ELSE << >>]
        settled30 == [settled29 EXCEPT !.locateReqd = IF settled29.numberOfNewOrderBitfields >= 3 /\ (settled29.newOrderBitfield3 # << >> /\ (settled29.newOrderBitfield3[1] \div 64) % 2 > 0) THEN (IF settled29.locateReqd = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled29.locateReqd) ELSE << >>]
        settled31 == [settled30 EXCEPT !.expireTime = IF settled30.numberOfNewOrderBitfields >= 3 /\ (settled30.newOrderBitfield3 # << >> /\ (settled30.newOrderBitfield3[1] \div 128) % 2 > 0) THEN (IF settled30.expireTime = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled30.expireTime) ELSE << >>]
        settled32 == [settled31 EXCEPT !.riskReset = IF settled31.numberOfNewOrderBitfields >= 4 /\ (settled31.newOrderBitfield4 # << >> /\ (settled31.newOrderBitfield4[1] \div 8) % 2 > 0) THEN (IF settled31.riskReset = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled31.riskReset) ELSE << >>]
        settled33 == [settled32 EXCEPT !.attributedQuote = IF settled32.numberOfNewOrderBitfields >= 5 /\ (settled32.newOrderBitfield5 # << >> /\ (settled32.newOrderBitfield5[1] \div 2) % 2 > 0) THEN (IF settled32.attributedQuote = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled32.attributedQuote) ELSE << >>]
        settled34 == [settled33 EXCEPT !.extExecInst = IF settled33.numberOfNewOrderBitfields >= 5 /\ (settled33.newOrderBitfield5 # << >> /\ (settled33.newOrderBitfield5[1] \div 8) % 2 > 0) THEN (IF settled33.extExecInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled33.extExecInst) ELSE << >>]
        settled35 == [settled34 EXCEPT !.displayRange = IF settled34.numberOfNewOrderBitfields >= 6 /\ (settled34.newOrderBitfield6 # << >> /\ settled34.newOrderBitfield6[1] % 2 > 0) THEN (IF settled34.displayRange = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled34.displayRange) ELSE << >>]
        settled36 == [settled35 EXCEPT !.stopPx = IF settled35.numberOfNewOrderBitfields >= 6 /\ (settled35.newOrderBitfield6 # << >> /\ (settled35.newOrderBitfield6[1] \div 2) % 2 > 0) THEN (IF settled35.stopPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled35.stopPx) ELSE << >>]
        settled37 == [settled36 EXCEPT !.routStrategy = IF settled36.numberOfNewOrderBitfields >= 6 /\ (settled36.newOrderBitfield6 # << >> /\ (settled36.newOrderBitfield6[1] \div 4) % 2 > 0) THEN (IF settled36.routStrategy = << >> THEN <<[i \in 1 .. 6 |-> 0]>> ELSE settled36.routStrategy) ELSE << >>]
        settled38 == [settled37 EXCEPT !.routeDeliveryMethod = IF settled37.numberOfNewOrderBitfields >= 6 /\ (settled37.newOrderBitfield6 # << >> /\ (settled37.newOrderBitfield6[1] \div 8) % 2 > 0) THEN (IF settled37.routeDeliveryMethod = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled37.routeDeliveryMethod) ELSE << >>]
        settled39 == [settled38 EXCEPT !.exDestination = IF settled38.numberOfNewOrderBitfields >= 6 /\ (settled38.newOrderBitfield6 # << >> /\ (settled38.newOrderBitfield6[1] \div 16) % 2 > 0) THEN (IF settled38.exDestination = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled38.exDestination) ELSE << >>]
        settled40 == [settled39 EXCEPT !.echoText = IF settled39.numberOfNewOrderBitfields >= 6 /\ (settled39.newOrderBitfield6 # << >> /\ (settled39.newOrderBitfield6[1] \div 32) % 2 > 0) THEN (IF settled39.echoText = << >> THEN <<[i \in 1 .. 64 |-> 0]>> ELSE settled39.echoText) ELSE << >>]
        settled41 == [settled40 EXCEPT !.riskGroupId = IF settled40.numberOfNewOrderBitfields >= 7 /\ (settled40.newOrderBitfield7 # << >> /\ (settled40.newOrderBitfield7[1] \div 2) % 2 > 0) THEN (IF settled40.riskGroupId = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled40.riskGroupId) ELSE << >>]
        settled42 == [settled41 EXCEPT !.crossTradeFlag = IF settled41.numberOfNewOrderBitfields >= 9 /\ (settled41.newOrderBitfield9 # << >> /\ (settled41.newOrderBitfield9[1] \div 64) % 2 > 0) THEN (IF settled41.crossTradeFlag = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled41.crossTradeFlag) ELSE << >>]
        settled43 == [settled42 EXCEPT !.locateBroker = IF settled42.numberOfNewOrderBitfields >= 10 /\ (settled42.newOrderBitfield10 # << >> /\ (settled42.newOrderBitfield10[1] \div 2) % 2 > 0) THEN (IF settled42.locateBroker = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled42.locateBroker) ELSE << >>]
        settled44 == [settled43 EXCEPT !.cmcSessions = IF settled43.numberOfNewOrderBitfields >= 10 /\ (settled43.newOrderBitfield10 # << >> /\ (settled43.newOrderBitfield10[1] \div 4) % 2 > 0) THEN (IF settled43.cmcSessions = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled43.cmcSessions) ELSE << >>]
        settled45 == [settled44 EXCEPT !.stepUpAmount = IF settled44.numberOfNewOrderBitfields >= 10 /\ (settled44.newOrderBitfield10 # << >> /\ (settled44.newOrderBitfield10[1] \div 8) % 2 > 0) THEN (IF settled44.stepUpAmount = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled44.stepUpAmount) ELSE << >>]
    IN  settled45

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
                            newOrderBitfield11        |-> << >>,
                            newOrderBitfield12        |-> << >>,
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
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 11, !.newOrderBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 12, !.newOrderBitfield12 = one]) : one \in { <<held>> : held \in Sample(1) } }
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
(* Purge Order Message                                                     *)
(***************************************************************************)

PurgeOrderMessage ==
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

EncodePurgeOrderMessage(message) ==
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

DecodePurgeOrderMessage(bytes) ==
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

(* Purge Order Message with each field marked present by fields before it there exactly where they say *)
SettlePurgeOrderMessage(message) ==
    LET settled1 == [message EXCEPT !.purgeOrdersBitfield1 = IF message.numberOfPurgeOrdersBitfields >= 1 THEN (IF message.purgeOrdersBitfield1 = << >> THEN <<0>> ELSE message.purgeOrdersBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.purgeOrdersBitfield2 = IF settled1.numberOfPurgeOrdersBitfields >= 2 THEN (IF settled1.purgeOrdersBitfield2 = << >> THEN <<0>> ELSE settled1.purgeOrdersBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.clearingFirm = IF settled2.numberOfPurgeOrdersBitfields >= 1 /\ (settled2.purgeOrdersBitfield1 # << >> /\ settled2.purgeOrdersBitfield1[1] % 2 > 0) THEN (IF settled2.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled2.clearingFirm) ELSE << >>]
        settled4 == [settled3 EXCEPT !.massCancelInst = IF settled3.numberOfPurgeOrdersBitfields >= 1 /\ (settled3.purgeOrdersBitfield1 # << >> /\ (settled3.purgeOrdersBitfield1[1] \div 4) % 2 > 0) THEN (IF settled3.massCancelInst = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled3.massCancelInst) ELSE << >>]
        settled5 == [settled4 EXCEPT !.massCancelId = IF settled4.numberOfPurgeOrdersBitfields >= 1 /\ (settled4.purgeOrdersBitfield1 # << >> /\ (settled4.purgeOrdersBitfield1[1] \div 16) % 2 > 0) THEN (IF settled4.massCancelId = << >> THEN <<[i \in 1 .. 20 |-> 0]>> ELSE settled4.massCancelId) ELSE << >>]
        settled6 == [settled5 EXCEPT !.symbol = IF settled5.numberOfPurgeOrdersBitfields >= 2 /\ (settled5.purgeOrdersBitfield2 # << >> /\ settled5.purgeOrdersBitfield2[1] % 2 > 0) THEN (IF settled5.symbol = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled5.symbol) ELSE << >>]
        settled7 == [settled6 EXCEPT !.symbolSfx = IF settled6.numberOfPurgeOrdersBitfields >= 2 /\ (settled6.purgeOrdersBitfield2 # << >> /\ (settled6.purgeOrdersBitfield2[1] \div 2) % 2 > 0) THEN (IF settled6.symbolSfx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled6.symbolSfx) ELSE << >>]
        settled8 == [settled7 EXCEPT !.matchingUnit = IF settled7.numberOfPurgeOrdersBitfields >= 2 /\ (settled7.purgeOrdersBitfield2 # << >> /\ (settled7.purgeOrdersBitfield2[1] \div 128) % 2 > 0) THEN (IF settled7.matchingUnit = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled7.matchingUnit) ELSE << >>]
    IN  settled8

ZeroPurgeOrderMessage ==
    SettlePurgeOrderMessage([ reserved1                    |-> [i \in 1 .. 1 |-> 0],
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

(* Purge Order Message at zero, then each field in turn at the values it is checked at *)
CheckedPurgeOrderMessage ==
    { ZeroPurgeOrderMessage }
        \cup { SettlePurgeOrderMessage([ZeroPurgeOrderMessage EXCEPT !.reserved1 = one]) : one \in Sample(1) }
        \cup { SettlePurgeOrderMessage([ZeroPurgeOrderMessage EXCEPT !.numberOfPurgeOrdersBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettlePurgeOrderMessage([ZeroPurgeOrderMessage EXCEPT !.numberOfPurgeOrdersBitfields = 1, !.purgeOrdersBitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettlePurgeOrderMessage([ZeroPurgeOrderMessage EXCEPT !.numberOfPurgeOrdersBitfields = 2, !.purgeOrdersBitfield2 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettlePurgeOrderMessage([ZeroPurgeOrderMessage EXCEPT !.riskGroupIDs = one]) : one \in SampleLists(OneRiskGroupIDs) }
        \cup { SettlePurgeOrderMessage([ZeroPurgeOrderMessage EXCEPT !.numberOfPurgeOrdersBitfields = 1, !.purgeOrdersBitfield1 = <<1>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettlePurgeOrderMessage([ZeroPurgeOrderMessage EXCEPT !.numberOfPurgeOrdersBitfields = 1, !.purgeOrdersBitfield1 = <<4>>, !.massCancelInst = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettlePurgeOrderMessage([ZeroPurgeOrderMessage EXCEPT !.numberOfPurgeOrdersBitfields = 1, !.purgeOrdersBitfield1 = <<16>>, !.massCancelId = one]) : one \in { <<held>> : held \in Sample(20) } }
        \cup { SettlePurgeOrderMessage([ZeroPurgeOrderMessage EXCEPT !.numberOfPurgeOrdersBitfields = 2, !.purgeOrdersBitfield2 = <<1>>, !.symbol = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettlePurgeOrderMessage([ZeroPurgeOrderMessage EXCEPT !.numberOfPurgeOrdersBitfields = 2, !.purgeOrdersBitfield2 = <<2>>, !.symbolSfx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettlePurgeOrderMessage([ZeroPurgeOrderMessage EXCEPT !.numberOfPurgeOrdersBitfields = 2, !.purgeOrdersBitfield2 = <<128>>, !.matchingUnit = one]) : one \in { <<held>> : held \in Sample(1) } }

(***************************************************************************)
(* Order Acknowledgment Message                                            *)
(***************************************************************************)

OrderAcknowledgmentMessage ==
    [ transactionTime                     : Sample(8),
      clOrdId                             : Sample(20),
      orderId                             : Sample(8),
      reserved1                           : Sample(1),
      numberOfReturnBitfields             : 0 .. 255,
      orderAcknowledgmentReturnBitfield1  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderAcknowledgmentReturnBitfield2  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderAcknowledgmentReturnBitfield3  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderAcknowledgmentReturnBitfield4  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield5  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderAcknowledgmentReturnBitfield6  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderAcknowledgmentReturnBitfield7  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderAcknowledgmentReturnBitfield8  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderAcknowledgmentReturnBitfield9  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield10 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield11 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield12 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield13 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield14 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield15 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield16 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield17 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield18 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderAcknowledgmentReturnBitfield19 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderAcknowledgmentReturnBitfield20 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield21 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield22 : { << >> } \cup { <<held>> : held \in Sample(1) },
      side                                : { << >> } \cup { <<held>> : held \in Sample(1) },
      pegDifference                       : { << >> } \cup { <<held>> : held \in Sample(8) },
      price                               : { << >> } \cup { <<held>> : held \in Sample(8) },
      execInst                            : { << >> } \cup { <<held>> : held \in Sample(1) },
      ordType                             : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce                         : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                              : { << >> } \cup { <<held>> : held \in Sample(4) },
      symbol                              : { << >> } \cup { <<held>> : held \in Sample(8) },
      symbolSfx                           : { << >> } \cup { <<held>> : held \in Sample(8) },
      capacity                            : { << >> } \cup { <<held>> : held \in Sample(1) },
      account                             : { << >> } \cup { <<held>> : held \in Sample(16) },
      clearingFirm                        : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingAccount                     : { << >> } \cup { <<held>> : held \in Sample(4) },
      displayIndicator                    : { << >> } \cup { <<held>> : held \in Sample(1) },
      maxFloor                            : { << >> } \cup { <<held>> : held \in Sample(4) },
      discretionAmount                    : { << >> } \cup { <<held>> : held \in Sample(2) },
      orderQty                            : { << >> } \cup { <<held>> : held \in Sample(4) },
      preventMatch                        : { << >> } \cup { <<held>> : held \in Sample(3) },
      origClOrdId                         : { << >> } \cup { <<held>> : held \in Sample(20) },
      leavesQty                           : { << >> } \cup { <<held>> : held \in Sample(4) },
      lastShares                          : { << >> } \cup { <<held>> : held \in Sample(4) },
      lastPx                              : { << >> } \cup { <<held>> : held \in Sample(8) },
      displayPrice                        : { << >> } \cup { <<held>> : held \in Sample(8) },
      workingPrice                        : { << >> } \cup { <<held>> : held \in Sample(8) },
      baseLiquidityIndicator              : { << >> } \cup { <<held>> : held \in Sample(1) },
      expireTime                          : { << >> } \cup { <<held>> : held \in Sample(8) },
      secondaryOrderId                    : { << >> } \cup { <<held>> : held \in Sample(8) },
      attributedQuote                     : { << >> } \cup { <<held>> : held \in Sample(1) },
      extExecInst                         : { << >> } \cup { <<held>> : held \in Sample(1) },
      subLiquidityIndicator               : { << >> } \cup { <<held>> : held \in Sample(1) },
      echoText                            : { << >> } \cup { <<held>> : held \in Sample(64) },
      stopPx                              : { << >> } \cup { <<held>> : held \in Sample(8) },
      routingInst                         : { << >> } \cup { <<held>> : held \in Sample(4) },
      routStrategy                        : { << >> } \cup { <<held>> : held \in Sample(6) },
      routeDeliveryMethod                 : { << >> } \cup { <<held>> : held \in Sample(3) },
      exDestination                       : { << >> } \cup { <<held>> : held \in Sample(1) },
      crossTradeFlag                      : { << >> } \cup { <<held>> : held \in Sample(1) },
      locateBroker                        : { << >> } \cup { <<held>> : held \in Sample(4) },
      cmcSessions                         : { << >> } \cup { <<held>> : held \in Sample(2) },
      stepUpAmount                        : { << >> } \cup { <<held>> : held \in Sample(8) } ]

EncodeOrderAcknowledgmentMessage(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.orderId
        \o message.reserved1
        \o EncodeUIntBE(message.numberOfReturnBitfields, 1)
        \o (IF message.orderAcknowledgmentReturnBitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.orderAcknowledgmentReturnBitfield1[1], 1))
        \o (IF message.orderAcknowledgmentReturnBitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.orderAcknowledgmentReturnBitfield2[1], 1))
        \o (IF message.orderAcknowledgmentReturnBitfield3 = << >> THEN << >> ELSE EncodeUIntLE(message.orderAcknowledgmentReturnBitfield3[1], 1))
        \o (IF message.orderAcknowledgmentReturnBitfield4 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield4[1])
        \o (IF message.orderAcknowledgmentReturnBitfield5 = << >> THEN << >> ELSE EncodeUIntLE(message.orderAcknowledgmentReturnBitfield5[1], 1))
        \o (IF message.orderAcknowledgmentReturnBitfield6 = << >> THEN << >> ELSE EncodeUIntLE(message.orderAcknowledgmentReturnBitfield6[1], 1))
        \o (IF message.orderAcknowledgmentReturnBitfield7 = << >> THEN << >> ELSE EncodeUIntLE(message.orderAcknowledgmentReturnBitfield7[1], 1))
        \o (IF message.orderAcknowledgmentReturnBitfield8 = << >> THEN << >> ELSE EncodeUIntLE(message.orderAcknowledgmentReturnBitfield8[1], 1))
        \o (IF message.orderAcknowledgmentReturnBitfield9 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield9[1])
        \o (IF message.orderAcknowledgmentReturnBitfield10 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield10[1])
        \o (IF message.orderAcknowledgmentReturnBitfield11 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield11[1])
        \o (IF message.orderAcknowledgmentReturnBitfield12 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield12[1])
        \o (IF message.orderAcknowledgmentReturnBitfield13 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield13[1])
        \o (IF message.orderAcknowledgmentReturnBitfield14 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield14[1])
        \o (IF message.orderAcknowledgmentReturnBitfield15 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield15[1])
        \o (IF message.orderAcknowledgmentReturnBitfield16 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield16[1])
        \o (IF message.orderAcknowledgmentReturnBitfield17 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield17[1])
        \o (IF message.orderAcknowledgmentReturnBitfield18 = << >> THEN << >> ELSE EncodeUIntLE(message.orderAcknowledgmentReturnBitfield18[1], 1))
        \o (IF message.orderAcknowledgmentReturnBitfield19 = << >> THEN << >> ELSE EncodeUIntLE(message.orderAcknowledgmentReturnBitfield19[1], 1))
        \o (IF message.orderAcknowledgmentReturnBitfield20 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield20[1])
        \o (IF message.orderAcknowledgmentReturnBitfield21 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield21[1])
        \o (IF message.orderAcknowledgmentReturnBitfield22 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield22[1])
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
    LET orderAcknowledgmentReturnBitfield1 == ReadWhen(numberOfReturnBitfields.value >= 1, ReadUIntLE(numberOfReturnBitfields.rest, 1), numberOfReturnBitfields.rest) IN IF ~orderAcknowledgmentReturnBitfield1.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield2 == ReadWhen(numberOfReturnBitfields.value >= 2, ReadUIntLE(orderAcknowledgmentReturnBitfield1.rest, 1), orderAcknowledgmentReturnBitfield1.rest) IN IF ~orderAcknowledgmentReturnBitfield2.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield3 == ReadWhen(numberOfReturnBitfields.value >= 3, ReadUIntLE(orderAcknowledgmentReturnBitfield2.rest, 1), orderAcknowledgmentReturnBitfield2.rest) IN IF ~orderAcknowledgmentReturnBitfield3.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadBytes(orderAcknowledgmentReturnBitfield3.rest, 1), orderAcknowledgmentReturnBitfield3.rest) IN IF ~orderAcknowledgmentReturnBitfield4.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadUIntLE(orderAcknowledgmentReturnBitfield4.rest, 1), orderAcknowledgmentReturnBitfield4.rest) IN IF ~orderAcknowledgmentReturnBitfield5.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadUIntLE(orderAcknowledgmentReturnBitfield5.rest, 1), orderAcknowledgmentReturnBitfield5.rest) IN IF ~orderAcknowledgmentReturnBitfield6.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadUIntLE(orderAcknowledgmentReturnBitfield6.rest, 1), orderAcknowledgmentReturnBitfield6.rest) IN IF ~orderAcknowledgmentReturnBitfield7.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadUIntLE(orderAcknowledgmentReturnBitfield7.rest, 1), orderAcknowledgmentReturnBitfield7.rest) IN IF ~orderAcknowledgmentReturnBitfield8.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadBytes(orderAcknowledgmentReturnBitfield8.rest, 1), orderAcknowledgmentReturnBitfield8.rest) IN IF ~orderAcknowledgmentReturnBitfield9.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadBytes(orderAcknowledgmentReturnBitfield9.rest, 1), orderAcknowledgmentReturnBitfield9.rest) IN IF ~orderAcknowledgmentReturnBitfield10.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadBytes(orderAcknowledgmentReturnBitfield10.rest, 1), orderAcknowledgmentReturnBitfield10.rest) IN IF ~orderAcknowledgmentReturnBitfield11.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadBytes(orderAcknowledgmentReturnBitfield11.rest, 1), orderAcknowledgmentReturnBitfield11.rest) IN IF ~orderAcknowledgmentReturnBitfield12.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(orderAcknowledgmentReturnBitfield12.rest, 1), orderAcknowledgmentReturnBitfield12.rest) IN IF ~orderAcknowledgmentReturnBitfield13.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(orderAcknowledgmentReturnBitfield13.rest, 1), orderAcknowledgmentReturnBitfield13.rest) IN IF ~orderAcknowledgmentReturnBitfield14.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield15 == ReadWhen(numberOfReturnBitfields.value >= 15, ReadBytes(orderAcknowledgmentReturnBitfield14.rest, 1), orderAcknowledgmentReturnBitfield14.rest) IN IF ~orderAcknowledgmentReturnBitfield15.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield16 == ReadWhen(numberOfReturnBitfields.value >= 16, ReadBytes(orderAcknowledgmentReturnBitfield15.rest, 1), orderAcknowledgmentReturnBitfield15.rest) IN IF ~orderAcknowledgmentReturnBitfield16.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield17 == ReadWhen(numberOfReturnBitfields.value >= 17, ReadBytes(orderAcknowledgmentReturnBitfield16.rest, 1), orderAcknowledgmentReturnBitfield16.rest) IN IF ~orderAcknowledgmentReturnBitfield17.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield18 == ReadWhen(numberOfReturnBitfields.value >= 18, ReadUIntLE(orderAcknowledgmentReturnBitfield17.rest, 1), orderAcknowledgmentReturnBitfield17.rest) IN IF ~orderAcknowledgmentReturnBitfield18.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield19 == ReadWhen(numberOfReturnBitfields.value >= 19, ReadUIntLE(orderAcknowledgmentReturnBitfield18.rest, 1), orderAcknowledgmentReturnBitfield18.rest) IN IF ~orderAcknowledgmentReturnBitfield19.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield20 == ReadWhen(numberOfReturnBitfields.value >= 20, ReadBytes(orderAcknowledgmentReturnBitfield19.rest, 1), orderAcknowledgmentReturnBitfield19.rest) IN IF ~orderAcknowledgmentReturnBitfield20.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield21 == ReadWhen(numberOfReturnBitfields.value >= 21, ReadBytes(orderAcknowledgmentReturnBitfield20.rest, 1), orderAcknowledgmentReturnBitfield20.rest) IN IF ~orderAcknowledgmentReturnBitfield21.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield22 == ReadWhen(numberOfReturnBitfields.value >= 22, ReadBytes(orderAcknowledgmentReturnBitfield21.rest, 1), orderAcknowledgmentReturnBitfield21.rest) IN IF ~orderAcknowledgmentReturnBitfield22.ok THEN Fail ELSE
    LET side == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderAcknowledgmentReturnBitfield1.value # << >> /\ orderAcknowledgmentReturnBitfield1.value[1] % 2 > 0), ReadBytes(orderAcknowledgmentReturnBitfield22.rest, 1), orderAcknowledgmentReturnBitfield22.rest) IN IF ~side.ok THEN Fail ELSE
    LET pegDifference == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderAcknowledgmentReturnBitfield1.value # << >> /\ (orderAcknowledgmentReturnBitfield1.value[1] \div 2) % 2 > 0), ReadBytes(side.rest, 8), side.rest) IN IF ~pegDifference.ok THEN Fail ELSE
    LET price == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderAcknowledgmentReturnBitfield1.value # << >> /\ (orderAcknowledgmentReturnBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(pegDifference.rest, 8), pegDifference.rest) IN IF ~price.ok THEN Fail ELSE
    LET execInst == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderAcknowledgmentReturnBitfield1.value # << >> /\ (orderAcknowledgmentReturnBitfield1.value[1] \div 8) % 2 > 0), ReadBytes(price.rest, 1), price.rest) IN IF ~execInst.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderAcknowledgmentReturnBitfield1.value # << >> /\ (orderAcknowledgmentReturnBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(execInst.rest, 1), execInst.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderAcknowledgmentReturnBitfield1.value # << >> /\ (orderAcknowledgmentReturnBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderAcknowledgmentReturnBitfield1.value # << >> /\ (orderAcknowledgmentReturnBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET symbol == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderAcknowledgmentReturnBitfield2.value # << >> /\ orderAcknowledgmentReturnBitfield2.value[1] % 2 > 0), ReadBytes(minQty.rest, 8), minQty.rest) IN IF ~symbol.ok THEN Fail ELSE
    LET symbolSfx == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderAcknowledgmentReturnBitfield2.value # << >> /\ (orderAcknowledgmentReturnBitfield2.value[1] \div 2) % 2 > 0), ReadBytes(symbol.rest, 8), symbol.rest) IN IF ~symbolSfx.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderAcknowledgmentReturnBitfield2.value # << >> /\ (orderAcknowledgmentReturnBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(symbolSfx.rest, 1), symbolSfx.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderAcknowledgmentReturnBitfield3.value # << >> /\ orderAcknowledgmentReturnBitfield3.value[1] % 2 > 0), ReadBytes(capacity.rest, 16), capacity.rest) IN IF ~account.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderAcknowledgmentReturnBitfield3.value # << >> /\ (orderAcknowledgmentReturnBitfield3.value[1] \div 2) % 2 > 0), ReadBytes(account.rest, 4), account.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderAcknowledgmentReturnBitfield3.value # << >> /\ (orderAcknowledgmentReturnBitfield3.value[1] \div 4) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET displayIndicator == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderAcknowledgmentReturnBitfield3.value # << >> /\ (orderAcknowledgmentReturnBitfield3.value[1] \div 8) % 2 > 0), ReadBytes(clearingAccount.rest, 1), clearingAccount.rest) IN IF ~displayIndicator.ok THEN Fail ELSE
    LET maxFloor == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderAcknowledgmentReturnBitfield3.value # << >> /\ (orderAcknowledgmentReturnBitfield3.value[1] \div 16) % 2 > 0), ReadBytes(displayIndicator.rest, 4), displayIndicator.rest) IN IF ~maxFloor.ok THEN Fail ELSE
    LET discretionAmount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderAcknowledgmentReturnBitfield3.value # << >> /\ (orderAcknowledgmentReturnBitfield3.value[1] \div 32) % 2 > 0), ReadBytes(maxFloor.rest, 2), maxFloor.rest) IN IF ~discretionAmount.ok THEN Fail ELSE
    LET orderQty == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderAcknowledgmentReturnBitfield3.value # << >> /\ (orderAcknowledgmentReturnBitfield3.value[1] \div 64) % 2 > 0), ReadBytes(discretionAmount.rest, 4), discretionAmount.rest) IN IF ~orderQty.ok THEN Fail ELSE
    LET preventMatch == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderAcknowledgmentReturnBitfield3.value # << >> /\ (orderAcknowledgmentReturnBitfield3.value[1] \div 128) % 2 > 0), ReadBytes(orderQty.rest, 3), orderQty.rest) IN IF ~preventMatch.ok THEN Fail ELSE
    LET origClOrdId == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderAcknowledgmentReturnBitfield5.value # << >> /\ orderAcknowledgmentReturnBitfield5.value[1] % 2 > 0), ReadBytes(preventMatch.rest, 20), preventMatch.rest) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET leavesQty == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderAcknowledgmentReturnBitfield5.value # << >> /\ (orderAcknowledgmentReturnBitfield5.value[1] \div 2) % 2 > 0), ReadBytes(origClOrdId.rest, 4), origClOrdId.rest) IN IF ~leavesQty.ok THEN Fail ELSE
    LET lastShares == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderAcknowledgmentReturnBitfield5.value # << >> /\ (orderAcknowledgmentReturnBitfield5.value[1] \div 4) % 2 > 0), ReadBytes(leavesQty.rest, 4), leavesQty.rest) IN IF ~lastShares.ok THEN Fail ELSE
    LET lastPx == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderAcknowledgmentReturnBitfield5.value # << >> /\ (orderAcknowledgmentReturnBitfield5.value[1] \div 8) % 2 > 0), ReadBytes(lastShares.rest, 8), lastShares.rest) IN IF ~lastPx.ok THEN Fail ELSE
    LET displayPrice == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderAcknowledgmentReturnBitfield5.value # << >> /\ (orderAcknowledgmentReturnBitfield5.value[1] \div 16) % 2 > 0), ReadBytes(lastPx.rest, 8), lastPx.rest) IN IF ~displayPrice.ok THEN Fail ELSE
    LET workingPrice == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderAcknowledgmentReturnBitfield5.value # << >> /\ (orderAcknowledgmentReturnBitfield5.value[1] \div 32) % 2 > 0), ReadBytes(displayPrice.rest, 8), displayPrice.rest) IN IF ~workingPrice.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderAcknowledgmentReturnBitfield5.value # << >> /\ (orderAcknowledgmentReturnBitfield5.value[1] \div 64) % 2 > 0), ReadBytes(workingPrice.rest, 1), workingPrice.rest) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET expireTime == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderAcknowledgmentReturnBitfield5.value # << >> /\ (orderAcknowledgmentReturnBitfield5.value[1] \div 128) % 2 > 0), ReadBytes(baseLiquidityIndicator.rest, 8), baseLiquidityIndicator.rest) IN IF ~expireTime.ok THEN Fail ELSE
    LET secondaryOrderId == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (orderAcknowledgmentReturnBitfield6.value # << >> /\ orderAcknowledgmentReturnBitfield6.value[1] % 2 > 0), ReadBytes(expireTime.rest, 8), expireTime.rest) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET attributedQuote == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (orderAcknowledgmentReturnBitfield6.value # << >> /\ (orderAcknowledgmentReturnBitfield6.value[1] \div 8) % 2 > 0), ReadBytes(secondaryOrderId.rest, 1), secondaryOrderId.rest) IN IF ~attributedQuote.ok THEN Fail ELSE
    LET extExecInst == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (orderAcknowledgmentReturnBitfield6.value # << >> /\ (orderAcknowledgmentReturnBitfield6.value[1] \div 16) % 2 > 0), ReadBytes(attributedQuote.rest, 1), attributedQuote.rest) IN IF ~extExecInst.ok THEN Fail ELSE
    LET subLiquidityIndicator == ReadWhen(numberOfReturnBitfields.value >= 7 /\ (orderAcknowledgmentReturnBitfield7.value # << >> /\ orderAcknowledgmentReturnBitfield7.value[1] % 2 > 0), ReadBytes(extExecInst.rest, 1), extExecInst.rest) IN IF ~subLiquidityIndicator.ok THEN Fail ELSE
    LET echoText == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderAcknowledgmentReturnBitfield8.value # << >> /\ (orderAcknowledgmentReturnBitfield8.value[1] \div 2) % 2 > 0), ReadBytes(subLiquidityIndicator.rest, 64), subLiquidityIndicator.rest) IN IF ~echoText.ok THEN Fail ELSE
    LET stopPx == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderAcknowledgmentReturnBitfield8.value # << >> /\ (orderAcknowledgmentReturnBitfield8.value[1] \div 4) % 2 > 0), ReadBytes(echoText.rest, 8), echoText.rest) IN IF ~stopPx.ok THEN Fail ELSE
    LET routingInst == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderAcknowledgmentReturnBitfield8.value # << >> /\ (orderAcknowledgmentReturnBitfield8.value[1] \div 8) % 2 > 0), ReadBytes(stopPx.rest, 4), stopPx.rest) IN IF ~routingInst.ok THEN Fail ELSE
    LET routStrategy == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderAcknowledgmentReturnBitfield8.value # << >> /\ (orderAcknowledgmentReturnBitfield8.value[1] \div 16) % 2 > 0), ReadBytes(routingInst.rest, 6), routingInst.rest) IN IF ~routStrategy.ok THEN Fail ELSE
    LET routeDeliveryMethod == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderAcknowledgmentReturnBitfield8.value # << >> /\ (orderAcknowledgmentReturnBitfield8.value[1] \div 32) % 2 > 0), ReadBytes(routStrategy.rest, 3), routStrategy.rest) IN IF ~routeDeliveryMethod.ok THEN Fail ELSE
    LET exDestination == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderAcknowledgmentReturnBitfield8.value # << >> /\ (orderAcknowledgmentReturnBitfield8.value[1] \div 64) % 2 > 0), ReadBytes(routeDeliveryMethod.rest, 1), routeDeliveryMethod.rest) IN IF ~exDestination.ok THEN Fail ELSE
    LET crossTradeFlag == ReadWhen(numberOfReturnBitfields.value >= 18 /\ (orderAcknowledgmentReturnBitfield18.value # << >> /\ (orderAcknowledgmentReturnBitfield18.value[1] \div 8) % 2 > 0), ReadBytes(exDestination.rest, 1), exDestination.rest) IN IF ~crossTradeFlag.ok THEN Fail ELSE
    LET locateBroker == ReadWhen(numberOfReturnBitfields.value >= 18 /\ (orderAcknowledgmentReturnBitfield18.value # << >> /\ (orderAcknowledgmentReturnBitfield18.value[1] \div 64) % 2 > 0), ReadBytes(crossTradeFlag.rest, 4), crossTradeFlag.rest) IN IF ~locateBroker.ok THEN Fail ELSE
    LET cmcSessions == ReadWhen(numberOfReturnBitfields.value >= 19 /\ (orderAcknowledgmentReturnBitfield19.value # << >> /\ (orderAcknowledgmentReturnBitfield19.value[1] \div 8) % 2 > 0), ReadBytes(locateBroker.rest, 2), locateBroker.rest) IN IF ~cmcSessions.ok THEN Fail ELSE
    LET stepUpAmount == ReadWhen(numberOfReturnBitfields.value >= 19 /\ (orderAcknowledgmentReturnBitfield19.value # << >> /\ (orderAcknowledgmentReturnBitfield19.value[1] \div 64) % 2 > 0), ReadBytes(cmcSessions.rest, 8), cmcSessions.rest) IN IF ~stepUpAmount.ok THEN Fail ELSE
    Ok([ transactionTime                     |-> transactionTime.value,
         clOrdId                             |-> clOrdId.value,
         orderId                             |-> orderId.value,
         reserved1                           |-> reserved1.value,
         numberOfReturnBitfields             |-> numberOfReturnBitfields.value,
         orderAcknowledgmentReturnBitfield1  |-> orderAcknowledgmentReturnBitfield1.value,
         orderAcknowledgmentReturnBitfield2  |-> orderAcknowledgmentReturnBitfield2.value,
         orderAcknowledgmentReturnBitfield3  |-> orderAcknowledgmentReturnBitfield3.value,
         orderAcknowledgmentReturnBitfield4  |-> orderAcknowledgmentReturnBitfield4.value,
         orderAcknowledgmentReturnBitfield5  |-> orderAcknowledgmentReturnBitfield5.value,
         orderAcknowledgmentReturnBitfield6  |-> orderAcknowledgmentReturnBitfield6.value,
         orderAcknowledgmentReturnBitfield7  |-> orderAcknowledgmentReturnBitfield7.value,
         orderAcknowledgmentReturnBitfield8  |-> orderAcknowledgmentReturnBitfield8.value,
         orderAcknowledgmentReturnBitfield9  |-> orderAcknowledgmentReturnBitfield9.value,
         orderAcknowledgmentReturnBitfield10 |-> orderAcknowledgmentReturnBitfield10.value,
         orderAcknowledgmentReturnBitfield11 |-> orderAcknowledgmentReturnBitfield11.value,
         orderAcknowledgmentReturnBitfield12 |-> orderAcknowledgmentReturnBitfield12.value,
         orderAcknowledgmentReturnBitfield13 |-> orderAcknowledgmentReturnBitfield13.value,
         orderAcknowledgmentReturnBitfield14 |-> orderAcknowledgmentReturnBitfield14.value,
         orderAcknowledgmentReturnBitfield15 |-> orderAcknowledgmentReturnBitfield15.value,
         orderAcknowledgmentReturnBitfield16 |-> orderAcknowledgmentReturnBitfield16.value,
         orderAcknowledgmentReturnBitfield17 |-> orderAcknowledgmentReturnBitfield17.value,
         orderAcknowledgmentReturnBitfield18 |-> orderAcknowledgmentReturnBitfield18.value,
         orderAcknowledgmentReturnBitfield19 |-> orderAcknowledgmentReturnBitfield19.value,
         orderAcknowledgmentReturnBitfield20 |-> orderAcknowledgmentReturnBitfield20.value,
         orderAcknowledgmentReturnBitfield21 |-> orderAcknowledgmentReturnBitfield21.value,
         orderAcknowledgmentReturnBitfield22 |-> orderAcknowledgmentReturnBitfield22.value,
         side                                |-> side.value,
         pegDifference                       |-> pegDifference.value,
         price                               |-> price.value,
         execInst                            |-> execInst.value,
         ordType                             |-> ordType.value,
         timeInForce                         |-> timeInForce.value,
         minQty                              |-> minQty.value,
         symbol                              |-> symbol.value,
         symbolSfx                           |-> symbolSfx.value,
         capacity                            |-> capacity.value,
         account                             |-> account.value,
         clearingFirm                        |-> clearingFirm.value,
         clearingAccount                     |-> clearingAccount.value,
         displayIndicator                    |-> displayIndicator.value,
         maxFloor                            |-> maxFloor.value,
         discretionAmount                    |-> discretionAmount.value,
         orderQty                            |-> orderQty.value,
         preventMatch                        |-> preventMatch.value,
         origClOrdId                         |-> origClOrdId.value,
         leavesQty                           |-> leavesQty.value,
         lastShares                          |-> lastShares.value,
         lastPx                              |-> lastPx.value,
         displayPrice                        |-> displayPrice.value,
         workingPrice                        |-> workingPrice.value,
         baseLiquidityIndicator              |-> baseLiquidityIndicator.value,
         expireTime                          |-> expireTime.value,
         secondaryOrderId                    |-> secondaryOrderId.value,
         attributedQuote                     |-> attributedQuote.value,
         extExecInst                         |-> extExecInst.value,
         subLiquidityIndicator               |-> subLiquidityIndicator.value,
         echoText                            |-> echoText.value,
         stopPx                              |-> stopPx.value,
         routingInst                         |-> routingInst.value,
         routStrategy                        |-> routStrategy.value,
         routeDeliveryMethod                 |-> routeDeliveryMethod.value,
         exDestination                       |-> exDestination.value,
         crossTradeFlag                      |-> crossTradeFlag.value,
         locateBroker                        |-> locateBroker.value,
         cmcSessions                         |-> cmcSessions.value,
         stepUpAmount                        |-> stepUpAmount.value ], stepUpAmount.rest)

(* Order Acknowledgment Message with each field marked present by fields before it there exactly where they say *)
SettleOrderAcknowledgmentMessage(message) ==
    LET settled1 == [message EXCEPT !.orderAcknowledgmentReturnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.orderAcknowledgmentReturnBitfield1 = << >> THEN <<0>> ELSE message.orderAcknowledgmentReturnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.orderAcknowledgmentReturnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.orderAcknowledgmentReturnBitfield2 = << >> THEN <<0>> ELSE settled1.orderAcknowledgmentReturnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.orderAcknowledgmentReturnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.orderAcknowledgmentReturnBitfield3 = << >> THEN <<0>> ELSE settled2.orderAcknowledgmentReturnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.orderAcknowledgmentReturnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.orderAcknowledgmentReturnBitfield4 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled3.orderAcknowledgmentReturnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.orderAcknowledgmentReturnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.orderAcknowledgmentReturnBitfield5 = << >> THEN <<0>> ELSE settled4.orderAcknowledgmentReturnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.orderAcknowledgmentReturnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.orderAcknowledgmentReturnBitfield6 = << >> THEN <<0>> ELSE settled5.orderAcknowledgmentReturnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.orderAcknowledgmentReturnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.orderAcknowledgmentReturnBitfield7 = << >> THEN <<0>> ELSE settled6.orderAcknowledgmentReturnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.orderAcknowledgmentReturnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.orderAcknowledgmentReturnBitfield8 = << >> THEN <<0>> ELSE settled7.orderAcknowledgmentReturnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.orderAcknowledgmentReturnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.orderAcknowledgmentReturnBitfield9 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled8.orderAcknowledgmentReturnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.orderAcknowledgmentReturnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.orderAcknowledgmentReturnBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.orderAcknowledgmentReturnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.orderAcknowledgmentReturnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.orderAcknowledgmentReturnBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.orderAcknowledgmentReturnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.orderAcknowledgmentReturnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.orderAcknowledgmentReturnBitfield12 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.orderAcknowledgmentReturnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.orderAcknowledgmentReturnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.orderAcknowledgmentReturnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.orderAcknowledgmentReturnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.orderAcknowledgmentReturnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.orderAcknowledgmentReturnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.orderAcknowledgmentReturnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.orderAcknowledgmentReturnBitfield15 = IF settled14.numberOfReturnBitfields >= 15 THEN (IF settled14.orderAcknowledgmentReturnBitfield15 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.orderAcknowledgmentReturnBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.orderAcknowledgmentReturnBitfield16 = IF settled15.numberOfReturnBitfields >= 16 THEN (IF settled15.orderAcknowledgmentReturnBitfield16 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled15.orderAcknowledgmentReturnBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.orderAcknowledgmentReturnBitfield17 = IF settled16.numberOfReturnBitfields >= 17 THEN (IF settled16.orderAcknowledgmentReturnBitfield17 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled16.orderAcknowledgmentReturnBitfield17) ELSE << >>]
        settled18 == [settled17 EXCEPT !.orderAcknowledgmentReturnBitfield18 = IF settled17.numberOfReturnBitfields >= 18 THEN (IF settled17.orderAcknowledgmentReturnBitfield18 = << >> THEN <<0>> ELSE settled17.orderAcknowledgmentReturnBitfield18) ELSE << >>]
        settled19 == [settled18 EXCEPT !.orderAcknowledgmentReturnBitfield19 = IF settled18.numberOfReturnBitfields >= 19 THEN (IF settled18.orderAcknowledgmentReturnBitfield19 = << >> THEN <<0>> ELSE settled18.orderAcknowledgmentReturnBitfield19) ELSE << >>]
        settled20 == [settled19 EXCEPT !.orderAcknowledgmentReturnBitfield20 = IF settled19.numberOfReturnBitfields >= 20 THEN (IF settled19.orderAcknowledgmentReturnBitfield20 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled19.orderAcknowledgmentReturnBitfield20) ELSE << >>]
        settled21 == [settled20 EXCEPT !.orderAcknowledgmentReturnBitfield21 = IF settled20.numberOfReturnBitfields >= 21 THEN (IF settled20.orderAcknowledgmentReturnBitfield21 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled20.orderAcknowledgmentReturnBitfield21) ELSE << >>]
        settled22 == [settled21 EXCEPT !.orderAcknowledgmentReturnBitfield22 = IF settled21.numberOfReturnBitfields >= 22 THEN (IF settled21.orderAcknowledgmentReturnBitfield22 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled21.orderAcknowledgmentReturnBitfield22) ELSE << >>]
        settled23 == [settled22 EXCEPT !.side = IF settled22.numberOfReturnBitfields >= 1 /\ (settled22.orderAcknowledgmentReturnBitfield1 # << >> /\ settled22.orderAcknowledgmentReturnBitfield1[1] % 2 > 0) THEN (IF settled22.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled22.side) ELSE << >>]
        settled24 == [settled23 EXCEPT !.pegDifference = IF settled23.numberOfReturnBitfields >= 1 /\ (settled23.orderAcknowledgmentReturnBitfield1 # << >> /\ (settled23.orderAcknowledgmentReturnBitfield1[1] \div 2) % 2 > 0) THEN (IF settled23.pegDifference = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled23.pegDifference) ELSE << >>]
        settled25 == [settled24 EXCEPT !.price = IF settled24.numberOfReturnBitfields >= 1 /\ (settled24.orderAcknowledgmentReturnBitfield1 # << >> /\ (settled24.orderAcknowledgmentReturnBitfield1[1] \div 4) % 2 > 0) THEN (IF settled24.price = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled24.price) ELSE << >>]
        settled26 == [settled25 EXCEPT !.execInst = IF settled25.numberOfReturnBitfields >= 1 /\ (settled25.orderAcknowledgmentReturnBitfield1 # << >> /\ (settled25.orderAcknowledgmentReturnBitfield1[1] \div 8) % 2 > 0) THEN (IF settled25.execInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled25.execInst) ELSE << >>]
        settled27 == [settled26 EXCEPT !.ordType = IF settled26.numberOfReturnBitfields >= 1 /\ (settled26.orderAcknowledgmentReturnBitfield1 # << >> /\ (settled26.orderAcknowledgmentReturnBitfield1[1] \div 16) % 2 > 0) THEN (IF settled26.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled26.ordType) ELSE << >>]
        settled28 == [settled27 EXCEPT !.timeInForce = IF settled27.numberOfReturnBitfields >= 1 /\ (settled27.orderAcknowledgmentReturnBitfield1 # << >> /\ (settled27.orderAcknowledgmentReturnBitfield1[1] \div 32) % 2 > 0) THEN (IF settled27.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled27.timeInForce) ELSE << >>]
        settled29 == [settled28 EXCEPT !.minQty = IF settled28.numberOfReturnBitfields >= 1 /\ (settled28.orderAcknowledgmentReturnBitfield1 # << >> /\ (settled28.orderAcknowledgmentReturnBitfield1[1] \div 64) % 2 > 0) THEN (IF settled28.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled28.minQty) ELSE << >>]
        settled30 == [settled29 EXCEPT !.symbol = IF settled29.numberOfReturnBitfields >= 2 /\ (settled29.orderAcknowledgmentReturnBitfield2 # << >> /\ settled29.orderAcknowledgmentReturnBitfield2[1] % 2 > 0) THEN (IF settled29.symbol = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled29.symbol) ELSE << >>]
        settled31 == [settled30 EXCEPT !.symbolSfx = IF settled30.numberOfReturnBitfields >= 2 /\ (settled30.orderAcknowledgmentReturnBitfield2 # << >> /\ (settled30.orderAcknowledgmentReturnBitfield2[1] \div 2) % 2 > 0) THEN (IF settled30.symbolSfx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled30.symbolSfx) ELSE << >>]
        settled32 == [settled31 EXCEPT !.capacity = IF settled31.numberOfReturnBitfields >= 2 /\ (settled31.orderAcknowledgmentReturnBitfield2 # << >> /\ (settled31.orderAcknowledgmentReturnBitfield2[1] \div 64) % 2 > 0) THEN (IF settled31.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled31.capacity) ELSE << >>]
        settled33 == [settled32 EXCEPT !.account = IF settled32.numberOfReturnBitfields >= 3 /\ (settled32.orderAcknowledgmentReturnBitfield3 # << >> /\ settled32.orderAcknowledgmentReturnBitfield3[1] % 2 > 0) THEN (IF settled32.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled32.account) ELSE << >>]
        settled34 == [settled33 EXCEPT !.clearingFirm = IF settled33.numberOfReturnBitfields >= 3 /\ (settled33.orderAcknowledgmentReturnBitfield3 # << >> /\ (settled33.orderAcknowledgmentReturnBitfield3[1] \div 2) % 2 > 0) THEN (IF settled33.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled33.clearingFirm) ELSE << >>]
        settled35 == [settled34 EXCEPT !.clearingAccount = IF settled34.numberOfReturnBitfields >= 3 /\ (settled34.orderAcknowledgmentReturnBitfield3 # << >> /\ (settled34.orderAcknowledgmentReturnBitfield3[1] \div 4) % 2 > 0) THEN (IF settled34.clearingAccount = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled34.clearingAccount) ELSE << >>]
        settled36 == [settled35 EXCEPT !.displayIndicator = IF settled35.numberOfReturnBitfields >= 3 /\ (settled35.orderAcknowledgmentReturnBitfield3 # << >> /\ (settled35.orderAcknowledgmentReturnBitfield3[1] \div 8) % 2 > 0) THEN (IF settled35.displayIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled35.displayIndicator) ELSE << >>]
        settled37 == [settled36 EXCEPT !.maxFloor = IF settled36.numberOfReturnBitfields >= 3 /\ (settled36.orderAcknowledgmentReturnBitfield3 # << >> /\ (settled36.orderAcknowledgmentReturnBitfield3[1] \div 16) % 2 > 0) THEN (IF settled36.maxFloor = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled36.maxFloor) ELSE << >>]
        settled38 == [settled37 EXCEPT !.discretionAmount = IF settled37.numberOfReturnBitfields >= 3 /\ (settled37.orderAcknowledgmentReturnBitfield3 # << >> /\ (settled37.orderAcknowledgmentReturnBitfield3[1] \div 32) % 2 > 0) THEN (IF settled37.discretionAmount = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled37.discretionAmount) ELSE << >>]
        settled39 == [settled38 EXCEPT !.orderQty = IF settled38.numberOfReturnBitfields >= 3 /\ (settled38.orderAcknowledgmentReturnBitfield3 # << >> /\ (settled38.orderAcknowledgmentReturnBitfield3[1] \div 64) % 2 > 0) THEN (IF settled38.orderQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled38.orderQty) ELSE << >>]
        settled40 == [settled39 EXCEPT !.preventMatch = IF settled39.numberOfReturnBitfields >= 3 /\ (settled39.orderAcknowledgmentReturnBitfield3 # << >> /\ (settled39.orderAcknowledgmentReturnBitfield3[1] \div 128) % 2 > 0) THEN (IF settled39.preventMatch = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled39.preventMatch) ELSE << >>]
        settled41 == [settled40 EXCEPT !.origClOrdId = IF settled40.numberOfReturnBitfields >= 5 /\ (settled40.orderAcknowledgmentReturnBitfield5 # << >> /\ settled40.orderAcknowledgmentReturnBitfield5[1] % 2 > 0) THEN (IF settled40.origClOrdId = << >> THEN <<[i \in 1 .. 20 |-> 0]>> ELSE settled40.origClOrdId) ELSE << >>]
        settled42 == [settled41 EXCEPT !.leavesQty = IF settled41.numberOfReturnBitfields >= 5 /\ (settled41.orderAcknowledgmentReturnBitfield5 # << >> /\ (settled41.orderAcknowledgmentReturnBitfield5[1] \div 2) % 2 > 0) THEN (IF settled41.leavesQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled41.leavesQty) ELSE << >>]
        settled43 == [settled42 EXCEPT !.lastShares = IF settled42.numberOfReturnBitfields >= 5 /\ (settled42.orderAcknowledgmentReturnBitfield5 # << >> /\ (settled42.orderAcknowledgmentReturnBitfield5[1] \div 4) % 2 > 0) THEN (IF settled42.lastShares = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled42.lastShares) ELSE << >>]
        settled44 == [settled43 EXCEPT !.lastPx = IF settled43.numberOfReturnBitfields >= 5 /\ (settled43.orderAcknowledgmentReturnBitfield5 # << >> /\ (settled43.orderAcknowledgmentReturnBitfield5[1] \div 8) % 2 > 0) THEN (IF settled43.lastPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled43.lastPx) ELSE << >>]
        settled45 == [settled44 EXCEPT !.displayPrice = IF settled44.numberOfReturnBitfields >= 5 /\ (settled44.orderAcknowledgmentReturnBitfield5 # << >> /\ (settled44.orderAcknowledgmentReturnBitfield5[1] \div 16) % 2 > 0) THEN (IF settled44.displayPrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled44.displayPrice) ELSE << >>]
        settled46 == [settled45 EXCEPT !.workingPrice = IF settled45.numberOfReturnBitfields >= 5 /\ (settled45.orderAcknowledgmentReturnBitfield5 # << >> /\ (settled45.orderAcknowledgmentReturnBitfield5[1] \div 32) % 2 > 0) THEN (IF settled45.workingPrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled45.workingPrice) ELSE << >>]
        settled47 == [settled46 EXCEPT !.baseLiquidityIndicator = IF settled46.numberOfReturnBitfields >= 5 /\ (settled46.orderAcknowledgmentReturnBitfield5 # << >> /\ (settled46.orderAcknowledgmentReturnBitfield5[1] \div 64) % 2 > 0) THEN (IF settled46.baseLiquidityIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled46.baseLiquidityIndicator) ELSE << >>]
        settled48 == [settled47 EXCEPT !.expireTime = IF settled47.numberOfReturnBitfields >= 5 /\ (settled47.orderAcknowledgmentReturnBitfield5 # << >> /\ (settled47.orderAcknowledgmentReturnBitfield5[1] \div 128) % 2 > 0) THEN (IF settled47.expireTime = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled47.expireTime) ELSE << >>]
        settled49 == [settled48 EXCEPT !.secondaryOrderId = IF settled48.numberOfReturnBitfields >= 6 /\ (settled48.orderAcknowledgmentReturnBitfield6 # << >> /\ settled48.orderAcknowledgmentReturnBitfield6[1] % 2 > 0) THEN (IF settled48.secondaryOrderId = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled48.secondaryOrderId) ELSE << >>]
        settled50 == [settled49 EXCEPT !.attributedQuote = IF settled49.numberOfReturnBitfields >= 6 /\ (settled49.orderAcknowledgmentReturnBitfield6 # << >> /\ (settled49.orderAcknowledgmentReturnBitfield6[1] \div 8) % 2 > 0) THEN (IF settled49.attributedQuote = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled49.attributedQuote) ELSE << >>]
        settled51 == [settled50 EXCEPT !.extExecInst = IF settled50.numberOfReturnBitfields >= 6 /\ (settled50.orderAcknowledgmentReturnBitfield6 # << >> /\ (settled50.orderAcknowledgmentReturnBitfield6[1] \div 16) % 2 > 0) THEN (IF settled50.extExecInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled50.extExecInst) ELSE << >>]
        settled52 == [settled51 EXCEPT !.subLiquidityIndicator = IF settled51.numberOfReturnBitfields >= 7 /\ (settled51.orderAcknowledgmentReturnBitfield7 # << >> /\ settled51.orderAcknowledgmentReturnBitfield7[1] % 2 > 0) THEN (IF settled51.subLiquidityIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled51.subLiquidityIndicator) ELSE << >>]
        settled53 == [settled52 EXCEPT !.echoText = IF settled52.numberOfReturnBitfields >= 8 /\ (settled52.orderAcknowledgmentReturnBitfield8 # << >> /\ (settled52.orderAcknowledgmentReturnBitfield8[1] \div 2) % 2 > 0) THEN (IF settled52.echoText = << >> THEN <<[i \in 1 .. 64 |-> 0]>> ELSE settled52.echoText) ELSE << >>]
        settled54 == [settled53 EXCEPT !.stopPx = IF settled53.numberOfReturnBitfields >= 8 /\ (settled53.orderAcknowledgmentReturnBitfield8 # << >> /\ (settled53.orderAcknowledgmentReturnBitfield8[1] \div 4) % 2 > 0) THEN (IF settled53.stopPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled53.stopPx) ELSE << >>]
        settled55 == [settled54 EXCEPT !.routingInst = IF settled54.numberOfReturnBitfields >= 8 /\ (settled54.orderAcknowledgmentReturnBitfield8 # << >> /\ (settled54.orderAcknowledgmentReturnBitfield8[1] \div 8) % 2 > 0) THEN (IF settled54.routingInst = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled54.routingInst) ELSE << >>]
        settled56 == [settled55 EXCEPT !.routStrategy = IF settled55.numberOfReturnBitfields >= 8 /\ (settled55.orderAcknowledgmentReturnBitfield8 # << >> /\ (settled55.orderAcknowledgmentReturnBitfield8[1] \div 16) % 2 > 0) THEN (IF settled55.routStrategy = << >> THEN <<[i \in 1 .. 6 |-> 0]>> ELSE settled55.routStrategy) ELSE << >>]
        settled57 == [settled56 EXCEPT !.routeDeliveryMethod = IF settled56.numberOfReturnBitfields >= 8 /\ (settled56.orderAcknowledgmentReturnBitfield8 # << >> /\ (settled56.orderAcknowledgmentReturnBitfield8[1] \div 32) % 2 > 0) THEN (IF settled56.routeDeliveryMethod = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled56.routeDeliveryMethod) ELSE << >>]
        settled58 == [settled57 EXCEPT !.exDestination = IF settled57.numberOfReturnBitfields >= 8 /\ (settled57.orderAcknowledgmentReturnBitfield8 # << >> /\ (settled57.orderAcknowledgmentReturnBitfield8[1] \div 64) % 2 > 0) THEN (IF settled57.exDestination = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled57.exDestination) ELSE << >>]
        settled59 == [settled58 EXCEPT !.crossTradeFlag = IF settled58.numberOfReturnBitfields >= 18 /\ (settled58.orderAcknowledgmentReturnBitfield18 # << >> /\ (settled58.orderAcknowledgmentReturnBitfield18[1] \div 8) % 2 > 0) THEN (IF settled58.crossTradeFlag = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled58.crossTradeFlag) ELSE << >>]
        settled60 == [settled59 EXCEPT !.locateBroker = IF settled59.numberOfReturnBitfields >= 18 /\ (settled59.orderAcknowledgmentReturnBitfield18 # << >> /\ (settled59.orderAcknowledgmentReturnBitfield18[1] \div 64) % 2 > 0) THEN (IF settled59.locateBroker = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled59.locateBroker) ELSE << >>]
        settled61 == [settled60 EXCEPT !.cmcSessions = IF settled60.numberOfReturnBitfields >= 19 /\ (settled60.orderAcknowledgmentReturnBitfield19 # << >> /\ (settled60.orderAcknowledgmentReturnBitfield19[1] \div 8) % 2 > 0) THEN (IF settled60.cmcSessions = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled60.cmcSessions) ELSE << >>]
        settled62 == [settled61 EXCEPT !.stepUpAmount = IF settled61.numberOfReturnBitfields >= 19 /\ (settled61.orderAcknowledgmentReturnBitfield19 # << >> /\ (settled61.orderAcknowledgmentReturnBitfield19[1] \div 64) % 2 > 0) THEN (IF settled61.stepUpAmount = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled61.stepUpAmount) ELSE << >>]
    IN  settled62

ZeroOrderAcknowledgmentMessage ==
    SettleOrderAcknowledgmentMessage([ transactionTime                     |-> [i \in 1 .. 8 |-> 0],
                                       clOrdId                             |-> [i \in 1 .. 20 |-> 0],
                                       orderId                             |-> [i \in 1 .. 8 |-> 0],
                                       reserved1                           |-> [i \in 1 .. 1 |-> 0],
                                       numberOfReturnBitfields             |-> 0,
                                       orderAcknowledgmentReturnBitfield1  |-> << >>,
                                       orderAcknowledgmentReturnBitfield2  |-> << >>,
                                       orderAcknowledgmentReturnBitfield3  |-> << >>,
                                       orderAcknowledgmentReturnBitfield4  |-> << >>,
                                       orderAcknowledgmentReturnBitfield5  |-> << >>,
                                       orderAcknowledgmentReturnBitfield6  |-> << >>,
                                       orderAcknowledgmentReturnBitfield7  |-> << >>,
                                       orderAcknowledgmentReturnBitfield8  |-> << >>,
                                       orderAcknowledgmentReturnBitfield9  |-> << >>,
                                       orderAcknowledgmentReturnBitfield10 |-> << >>,
                                       orderAcknowledgmentReturnBitfield11 |-> << >>,
                                       orderAcknowledgmentReturnBitfield12 |-> << >>,
                                       orderAcknowledgmentReturnBitfield13 |-> << >>,
                                       orderAcknowledgmentReturnBitfield14 |-> << >>,
                                       orderAcknowledgmentReturnBitfield15 |-> << >>,
                                       orderAcknowledgmentReturnBitfield16 |-> << >>,
                                       orderAcknowledgmentReturnBitfield17 |-> << >>,
                                       orderAcknowledgmentReturnBitfield18 |-> << >>,
                                       orderAcknowledgmentReturnBitfield19 |-> << >>,
                                       orderAcknowledgmentReturnBitfield20 |-> << >>,
                                       orderAcknowledgmentReturnBitfield21 |-> << >>,
                                       orderAcknowledgmentReturnBitfield22 |-> << >>,
                                       side                                |-> << >>,
                                       pegDifference                       |-> << >>,
                                       price                               |-> << >>,
                                       execInst                            |-> << >>,
                                       ordType                             |-> << >>,
                                       timeInForce                         |-> << >>,
                                       minQty                              |-> << >>,
                                       symbol                              |-> << >>,
                                       symbolSfx                           |-> << >>,
                                       capacity                            |-> << >>,
                                       account                             |-> << >>,
                                       clearingFirm                        |-> << >>,
                                       clearingAccount                     |-> << >>,
                                       displayIndicator                    |-> << >>,
                                       maxFloor                            |-> << >>,
                                       discretionAmount                    |-> << >>,
                                       orderQty                            |-> << >>,
                                       preventMatch                        |-> << >>,
                                       origClOrdId                         |-> << >>,
                                       leavesQty                           |-> << >>,
                                       lastShares                          |-> << >>,
                                       lastPx                              |-> << >>,
                                       displayPrice                        |-> << >>,
                                       workingPrice                        |-> << >>,
                                       baseLiquidityIndicator              |-> << >>,
                                       expireTime                          |-> << >>,
                                       secondaryOrderId                    |-> << >>,
                                       attributedQuote                     |-> << >>,
                                       extExecInst                         |-> << >>,
                                       subLiquidityIndicator               |-> << >>,
                                       echoText                            |-> << >>,
                                       stopPx                              |-> << >>,
                                       routingInst                         |-> << >>,
                                       routStrategy                        |-> << >>,
                                       routeDeliveryMethod                 |-> << >>,
                                       exDestination                       |-> << >>,
                                       crossTradeFlag                      |-> << >>,
                                       locateBroker                        |-> << >>,
                                       cmcSessions                         |-> << >>,
                                       stepUpAmount                        |-> << >> ])

(* Order Acknowledgment Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderAcknowledgmentMessage ==
    { ZeroOrderAcknowledgmentMessage }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.transactionTime = one]) : one \in Sample(8) }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.clOrdId = one]) : one \in Sample(20) }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.orderId = one]) : one \in Sample(8) }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.reserved1 = one]) : one \in Sample(1) }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderAcknowledgmentReturnBitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 2, !.orderAcknowledgmentReturnBitfield2 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderAcknowledgmentReturnBitfield3 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 4, !.orderAcknowledgmentReturnBitfield4 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderAcknowledgmentReturnBitfield5 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 6, !.orderAcknowledgmentReturnBitfield6 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 7, !.orderAcknowledgmentReturnBitfield7 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderAcknowledgmentReturnBitfield8 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 9, !.orderAcknowledgmentReturnBitfield9 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 10, !.orderAcknowledgmentReturnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 11, !.orderAcknowledgmentReturnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 12, !.orderAcknowledgmentReturnBitfield12 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 13, !.orderAcknowledgmentReturnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 14, !.orderAcknowledgmentReturnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 15, !.orderAcknowledgmentReturnBitfield15 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 16, !.orderAcknowledgmentReturnBitfield16 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 17, !.orderAcknowledgmentReturnBitfield17 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 18, !.orderAcknowledgmentReturnBitfield18 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 19, !.orderAcknowledgmentReturnBitfield19 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 20, !.orderAcknowledgmentReturnBitfield20 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 21, !.orderAcknowledgmentReturnBitfield21 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 22, !.orderAcknowledgmentReturnBitfield22 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderAcknowledgmentReturnBitfield1 = <<1>>, !.side = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderAcknowledgmentReturnBitfield1 = <<2>>, !.pegDifference = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderAcknowledgmentReturnBitfield1 = <<4>>, !.price = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderAcknowledgmentReturnBitfield1 = <<8>>, !.execInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderAcknowledgmentReturnBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderAcknowledgmentReturnBitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderAcknowledgmentReturnBitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 2, !.orderAcknowledgmentReturnBitfield2 = <<1>>, !.symbol = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 2, !.orderAcknowledgmentReturnBitfield2 = <<2>>, !.symbolSfx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 2, !.orderAcknowledgmentReturnBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderAcknowledgmentReturnBitfield3 = <<1>>, !.account = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderAcknowledgmentReturnBitfield3 = <<2>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderAcknowledgmentReturnBitfield3 = <<4>>, !.clearingAccount = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderAcknowledgmentReturnBitfield3 = <<8>>, !.displayIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderAcknowledgmentReturnBitfield3 = <<16>>, !.maxFloor = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderAcknowledgmentReturnBitfield3 = <<32>>, !.discretionAmount = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderAcknowledgmentReturnBitfield3 = <<64>>, !.orderQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderAcknowledgmentReturnBitfield3 = <<128>>, !.preventMatch = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderAcknowledgmentReturnBitfield5 = <<1>>, !.origClOrdId = one]) : one \in { <<held>> : held \in Sample(20) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderAcknowledgmentReturnBitfield5 = <<2>>, !.leavesQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderAcknowledgmentReturnBitfield5 = <<4>>, !.lastShares = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderAcknowledgmentReturnBitfield5 = <<8>>, !.lastPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderAcknowledgmentReturnBitfield5 = <<16>>, !.displayPrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderAcknowledgmentReturnBitfield5 = <<32>>, !.workingPrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderAcknowledgmentReturnBitfield5 = <<64>>, !.baseLiquidityIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderAcknowledgmentReturnBitfield5 = <<128>>, !.expireTime = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 6, !.orderAcknowledgmentReturnBitfield6 = <<1>>, !.secondaryOrderId = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 6, !.orderAcknowledgmentReturnBitfield6 = <<8>>, !.attributedQuote = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 6, !.orderAcknowledgmentReturnBitfield6 = <<16>>, !.extExecInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 7, !.orderAcknowledgmentReturnBitfield7 = <<1>>, !.subLiquidityIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderAcknowledgmentReturnBitfield8 = <<2>>, !.echoText = one]) : one \in { <<held>> : held \in Sample(64) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderAcknowledgmentReturnBitfield8 = <<4>>, !.stopPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderAcknowledgmentReturnBitfield8 = <<8>>, !.routingInst = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderAcknowledgmentReturnBitfield8 = <<16>>, !.routStrategy = one]) : one \in { <<held>> : held \in Sample(6) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderAcknowledgmentReturnBitfield8 = <<32>>, !.routeDeliveryMethod = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderAcknowledgmentReturnBitfield8 = <<64>>, !.exDestination = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 18, !.orderAcknowledgmentReturnBitfield18 = <<8>>, !.crossTradeFlag = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 18, !.orderAcknowledgmentReturnBitfield18 = <<64>>, !.locateBroker = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 19, !.orderAcknowledgmentReturnBitfield19 = <<8>>, !.cmcSessions = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 19, !.orderAcknowledgmentReturnBitfield19 = <<64>>, !.stepUpAmount = one]) : one \in { <<held>> : held \in Sample(8) } }

(***************************************************************************)
(* Order Rejected Message                                                  *)
(***************************************************************************)

OrderRejectedMessage ==
    [ transactionTime               : Sample(8),
      clOrdId                       : Sample(20),
      orderRejectReason             : Sample(1),
      text                          : Sample(60),
      reserved1                     : Sample(1),
      numberOfReturnBitfields       : 0 .. 255,
      orderRejectedReturnBitfield1  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderRejectedReturnBitfield2  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderRejectedReturnBitfield3  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderRejectedReturnBitfield4  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRejectedReturnBitfield5  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRejectedReturnBitfield6  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderRejectedReturnBitfield7  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRejectedReturnBitfield8  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderRejectedReturnBitfield9  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRejectedReturnBitfield10 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRejectedReturnBitfield11 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRejectedReturnBitfield12 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRejectedReturnBitfield13 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRejectedReturnBitfield14 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRejectedReturnBitfield15 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRejectedReturnBitfield16 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRejectedReturnBitfield17 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRejectedReturnBitfield18 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRejectedReturnBitfield19 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRejectedReturnBitfield20 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRejectedReturnBitfield21 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRejectedReturnBitfield22 : { << >> } \cup { <<held>> : held \in Sample(1) },
      side                          : { << >> } \cup { <<held>> : held \in Sample(1) },
      pegDifference                 : { << >> } \cup { <<held>> : held \in Sample(8) },
      price                         : { << >> } \cup { <<held>> : held \in Sample(8) },
      execInst                      : { << >> } \cup { <<held>> : held \in Sample(1) },
      ordType                       : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce                   : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                        : { << >> } \cup { <<held>> : held \in Sample(4) },
      symbol                        : { << >> } \cup { <<held>> : held \in Sample(8) },
      symbolSfx                     : { << >> } \cup { <<held>> : held \in Sample(8) },
      capacity                      : { << >> } \cup { <<held>> : held \in Sample(1) },
      account                       : { << >> } \cup { <<held>> : held \in Sample(16) },
      clearingFirm                  : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingAccount               : { << >> } \cup { <<held>> : held \in Sample(4) },
      displayIndicator              : { << >> } \cup { <<held>> : held \in Sample(1) },
      maxFloor                      : { << >> } \cup { <<held>> : held \in Sample(4) },
      discretionAmount              : { << >> } \cup { <<held>> : held \in Sample(2) },
      orderQty                      : { << >> } \cup { <<held>> : held \in Sample(4) },
      preventMatch                  : { << >> } \cup { <<held>> : held \in Sample(3) },
      secondaryOrderId              : { << >> } \cup { <<held>> : held \in Sample(8) },
      attributedQuote               : { << >> } \cup { <<held>> : held \in Sample(1) },
      extExecInst                   : { << >> } \cup { <<held>> : held \in Sample(1) },
      echoText                      : { << >> } \cup { <<held>> : held \in Sample(64) },
      stopPx                        : { << >> } \cup { <<held>> : held \in Sample(8) },
      routingInst                   : { << >> } \cup { <<held>> : held \in Sample(4) },
      routStrategy                  : { << >> } \cup { <<held>> : held \in Sample(6) },
      routeDeliveryMethod           : { << >> } \cup { <<held>> : held \in Sample(3) },
      exDestination                 : { << >> } \cup { <<held>> : held \in Sample(1) } ]

EncodeOrderRejectedMessage(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.orderRejectReason
        \o message.text
        \o message.reserved1
        \o EncodeUIntBE(message.numberOfReturnBitfields, 1)
        \o (IF message.orderRejectedReturnBitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.orderRejectedReturnBitfield1[1], 1))
        \o (IF message.orderRejectedReturnBitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.orderRejectedReturnBitfield2[1], 1))
        \o (IF message.orderRejectedReturnBitfield3 = << >> THEN << >> ELSE EncodeUIntLE(message.orderRejectedReturnBitfield3[1], 1))
        \o (IF message.orderRejectedReturnBitfield4 = << >> THEN << >> ELSE message.orderRejectedReturnBitfield4[1])
        \o (IF message.orderRejectedReturnBitfield5 = << >> THEN << >> ELSE message.orderRejectedReturnBitfield5[1])
        \o (IF message.orderRejectedReturnBitfield6 = << >> THEN << >> ELSE EncodeUIntLE(message.orderRejectedReturnBitfield6[1], 1))
        \o (IF message.orderRejectedReturnBitfield7 = << >> THEN << >> ELSE message.orderRejectedReturnBitfield7[1])
        \o (IF message.orderRejectedReturnBitfield8 = << >> THEN << >> ELSE EncodeUIntLE(message.orderRejectedReturnBitfield8[1], 1))
        \o (IF message.orderRejectedReturnBitfield9 = << >> THEN << >> ELSE message.orderRejectedReturnBitfield9[1])
        \o (IF message.orderRejectedReturnBitfield10 = << >> THEN << >> ELSE message.orderRejectedReturnBitfield10[1])
        \o (IF message.orderRejectedReturnBitfield11 = << >> THEN << >> ELSE message.orderRejectedReturnBitfield11[1])
        \o (IF message.orderRejectedReturnBitfield12 = << >> THEN << >> ELSE message.orderRejectedReturnBitfield12[1])
        \o (IF message.orderRejectedReturnBitfield13 = << >> THEN << >> ELSE message.orderRejectedReturnBitfield13[1])
        \o (IF message.orderRejectedReturnBitfield14 = << >> THEN << >> ELSE message.orderRejectedReturnBitfield14[1])
        \o (IF message.orderRejectedReturnBitfield15 = << >> THEN << >> ELSE message.orderRejectedReturnBitfield15[1])
        \o (IF message.orderRejectedReturnBitfield16 = << >> THEN << >> ELSE message.orderRejectedReturnBitfield16[1])
        \o (IF message.orderRejectedReturnBitfield17 = << >> THEN << >> ELSE message.orderRejectedReturnBitfield17[1])
        \o (IF message.orderRejectedReturnBitfield18 = << >> THEN << >> ELSE message.orderRejectedReturnBitfield18[1])
        \o (IF message.orderRejectedReturnBitfield19 = << >> THEN << >> ELSE message.orderRejectedReturnBitfield19[1])
        \o (IF message.orderRejectedReturnBitfield20 = << >> THEN << >> ELSE message.orderRejectedReturnBitfield20[1])
        \o (IF message.orderRejectedReturnBitfield21 = << >> THEN << >> ELSE message.orderRejectedReturnBitfield21[1])
        \o (IF message.orderRejectedReturnBitfield22 = << >> THEN << >> ELSE message.orderRejectedReturnBitfield22[1])
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
    LET orderRejectedReturnBitfield1 == ReadWhen(numberOfReturnBitfields.value >= 1, ReadUIntLE(numberOfReturnBitfields.rest, 1), numberOfReturnBitfields.rest) IN IF ~orderRejectedReturnBitfield1.ok THEN Fail ELSE
    LET orderRejectedReturnBitfield2 == ReadWhen(numberOfReturnBitfields.value >= 2, ReadUIntLE(orderRejectedReturnBitfield1.rest, 1), orderRejectedReturnBitfield1.rest) IN IF ~orderRejectedReturnBitfield2.ok THEN Fail ELSE
    LET orderRejectedReturnBitfield3 == ReadWhen(numberOfReturnBitfields.value >= 3, ReadUIntLE(orderRejectedReturnBitfield2.rest, 1), orderRejectedReturnBitfield2.rest) IN IF ~orderRejectedReturnBitfield3.ok THEN Fail ELSE
    LET orderRejectedReturnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadBytes(orderRejectedReturnBitfield3.rest, 1), orderRejectedReturnBitfield3.rest) IN IF ~orderRejectedReturnBitfield4.ok THEN Fail ELSE
    LET orderRejectedReturnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadBytes(orderRejectedReturnBitfield4.rest, 1), orderRejectedReturnBitfield4.rest) IN IF ~orderRejectedReturnBitfield5.ok THEN Fail ELSE
    LET orderRejectedReturnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadUIntLE(orderRejectedReturnBitfield5.rest, 1), orderRejectedReturnBitfield5.rest) IN IF ~orderRejectedReturnBitfield6.ok THEN Fail ELSE
    LET orderRejectedReturnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadBytes(orderRejectedReturnBitfield6.rest, 1), orderRejectedReturnBitfield6.rest) IN IF ~orderRejectedReturnBitfield7.ok THEN Fail ELSE
    LET orderRejectedReturnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadUIntLE(orderRejectedReturnBitfield7.rest, 1), orderRejectedReturnBitfield7.rest) IN IF ~orderRejectedReturnBitfield8.ok THEN Fail ELSE
    LET orderRejectedReturnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadBytes(orderRejectedReturnBitfield8.rest, 1), orderRejectedReturnBitfield8.rest) IN IF ~orderRejectedReturnBitfield9.ok THEN Fail ELSE
    LET orderRejectedReturnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadBytes(orderRejectedReturnBitfield9.rest, 1), orderRejectedReturnBitfield9.rest) IN IF ~orderRejectedReturnBitfield10.ok THEN Fail ELSE
    LET orderRejectedReturnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadBytes(orderRejectedReturnBitfield10.rest, 1), orderRejectedReturnBitfield10.rest) IN IF ~orderRejectedReturnBitfield11.ok THEN Fail ELSE
    LET orderRejectedReturnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadBytes(orderRejectedReturnBitfield11.rest, 1), orderRejectedReturnBitfield11.rest) IN IF ~orderRejectedReturnBitfield12.ok THEN Fail ELSE
    LET orderRejectedReturnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(orderRejectedReturnBitfield12.rest, 1), orderRejectedReturnBitfield12.rest) IN IF ~orderRejectedReturnBitfield13.ok THEN Fail ELSE
    LET orderRejectedReturnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(orderRejectedReturnBitfield13.rest, 1), orderRejectedReturnBitfield13.rest) IN IF ~orderRejectedReturnBitfield14.ok THEN Fail ELSE
    LET orderRejectedReturnBitfield15 == ReadWhen(numberOfReturnBitfields.value >= 15, ReadBytes(orderRejectedReturnBitfield14.rest, 1), orderRejectedReturnBitfield14.rest) IN IF ~orderRejectedReturnBitfield15.ok THEN Fail ELSE
    LET orderRejectedReturnBitfield16 == ReadWhen(numberOfReturnBitfields.value >= 16, ReadBytes(orderRejectedReturnBitfield15.rest, 1), orderRejectedReturnBitfield15.rest) IN IF ~orderRejectedReturnBitfield16.ok THEN Fail ELSE
    LET orderRejectedReturnBitfield17 == ReadWhen(numberOfReturnBitfields.value >= 17, ReadBytes(orderRejectedReturnBitfield16.rest, 1), orderRejectedReturnBitfield16.rest) IN IF ~orderRejectedReturnBitfield17.ok THEN Fail ELSE
    LET orderRejectedReturnBitfield18 == ReadWhen(numberOfReturnBitfields.value >= 18, ReadBytes(orderRejectedReturnBitfield17.rest, 1), orderRejectedReturnBitfield17.rest) IN IF ~orderRejectedReturnBitfield18.ok THEN Fail ELSE
    LET orderRejectedReturnBitfield19 == ReadWhen(numberOfReturnBitfields.value >= 19, ReadBytes(orderRejectedReturnBitfield18.rest, 1), orderRejectedReturnBitfield18.rest) IN IF ~orderRejectedReturnBitfield19.ok THEN Fail ELSE
    LET orderRejectedReturnBitfield20 == ReadWhen(numberOfReturnBitfields.value >= 20, ReadBytes(orderRejectedReturnBitfield19.rest, 1), orderRejectedReturnBitfield19.rest) IN IF ~orderRejectedReturnBitfield20.ok THEN Fail ELSE
    LET orderRejectedReturnBitfield21 == ReadWhen(numberOfReturnBitfields.value >= 21, ReadBytes(orderRejectedReturnBitfield20.rest, 1), orderRejectedReturnBitfield20.rest) IN IF ~orderRejectedReturnBitfield21.ok THEN Fail ELSE
    LET orderRejectedReturnBitfield22 == ReadWhen(numberOfReturnBitfields.value >= 22, ReadBytes(orderRejectedReturnBitfield21.rest, 1), orderRejectedReturnBitfield21.rest) IN IF ~orderRejectedReturnBitfield22.ok THEN Fail ELSE
    LET side == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderRejectedReturnBitfield1.value # << >> /\ orderRejectedReturnBitfield1.value[1] % 2 > 0), ReadBytes(orderRejectedReturnBitfield22.rest, 1), orderRejectedReturnBitfield22.rest) IN IF ~side.ok THEN Fail ELSE
    LET pegDifference == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderRejectedReturnBitfield1.value # << >> /\ (orderRejectedReturnBitfield1.value[1] \div 2) % 2 > 0), ReadBytes(side.rest, 8), side.rest) IN IF ~pegDifference.ok THEN Fail ELSE
    LET price == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderRejectedReturnBitfield1.value # << >> /\ (orderRejectedReturnBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(pegDifference.rest, 8), pegDifference.rest) IN IF ~price.ok THEN Fail ELSE
    LET execInst == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderRejectedReturnBitfield1.value # << >> /\ (orderRejectedReturnBitfield1.value[1] \div 8) % 2 > 0), ReadBytes(price.rest, 1), price.rest) IN IF ~execInst.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderRejectedReturnBitfield1.value # << >> /\ (orderRejectedReturnBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(execInst.rest, 1), execInst.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderRejectedReturnBitfield1.value # << >> /\ (orderRejectedReturnBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderRejectedReturnBitfield1.value # << >> /\ (orderRejectedReturnBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET symbol == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderRejectedReturnBitfield2.value # << >> /\ orderRejectedReturnBitfield2.value[1] % 2 > 0), ReadBytes(minQty.rest, 8), minQty.rest) IN IF ~symbol.ok THEN Fail ELSE
    LET symbolSfx == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderRejectedReturnBitfield2.value # << >> /\ (orderRejectedReturnBitfield2.value[1] \div 2) % 2 > 0), ReadBytes(symbol.rest, 8), symbol.rest) IN IF ~symbolSfx.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderRejectedReturnBitfield2.value # << >> /\ (orderRejectedReturnBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(symbolSfx.rest, 1), symbolSfx.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderRejectedReturnBitfield3.value # << >> /\ orderRejectedReturnBitfield3.value[1] % 2 > 0), ReadBytes(capacity.rest, 16), capacity.rest) IN IF ~account.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderRejectedReturnBitfield3.value # << >> /\ (orderRejectedReturnBitfield3.value[1] \div 2) % 2 > 0), ReadBytes(account.rest, 4), account.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderRejectedReturnBitfield3.value # << >> /\ (orderRejectedReturnBitfield3.value[1] \div 4) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET displayIndicator == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderRejectedReturnBitfield3.value # << >> /\ (orderRejectedReturnBitfield3.value[1] \div 8) % 2 > 0), ReadBytes(clearingAccount.rest, 1), clearingAccount.rest) IN IF ~displayIndicator.ok THEN Fail ELSE
    LET maxFloor == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderRejectedReturnBitfield3.value # << >> /\ (orderRejectedReturnBitfield3.value[1] \div 16) % 2 > 0), ReadBytes(displayIndicator.rest, 4), displayIndicator.rest) IN IF ~maxFloor.ok THEN Fail ELSE
    LET discretionAmount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderRejectedReturnBitfield3.value # << >> /\ (orderRejectedReturnBitfield3.value[1] \div 32) % 2 > 0), ReadBytes(maxFloor.rest, 2), maxFloor.rest) IN IF ~discretionAmount.ok THEN Fail ELSE
    LET orderQty == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderRejectedReturnBitfield3.value # << >> /\ (orderRejectedReturnBitfield3.value[1] \div 64) % 2 > 0), ReadBytes(discretionAmount.rest, 4), discretionAmount.rest) IN IF ~orderQty.ok THEN Fail ELSE
    LET preventMatch == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderRejectedReturnBitfield3.value # << >> /\ (orderRejectedReturnBitfield3.value[1] \div 128) % 2 > 0), ReadBytes(orderQty.rest, 3), orderQty.rest) IN IF ~preventMatch.ok THEN Fail ELSE
    LET secondaryOrderId == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (orderRejectedReturnBitfield6.value # << >> /\ orderRejectedReturnBitfield6.value[1] % 2 > 0), ReadBytes(preventMatch.rest, 8), preventMatch.rest) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET attributedQuote == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (orderRejectedReturnBitfield6.value # << >> /\ (orderRejectedReturnBitfield6.value[1] \div 8) % 2 > 0), ReadBytes(secondaryOrderId.rest, 1), secondaryOrderId.rest) IN IF ~attributedQuote.ok THEN Fail ELSE
    LET extExecInst == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (orderRejectedReturnBitfield6.value # << >> /\ (orderRejectedReturnBitfield6.value[1] \div 16) % 2 > 0), ReadBytes(attributedQuote.rest, 1), attributedQuote.rest) IN IF ~extExecInst.ok THEN Fail ELSE
    LET echoText == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderRejectedReturnBitfield8.value # << >> /\ (orderRejectedReturnBitfield8.value[1] \div 2) % 2 > 0), ReadBytes(extExecInst.rest, 64), extExecInst.rest) IN IF ~echoText.ok THEN Fail ELSE
    LET stopPx == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderRejectedReturnBitfield8.value # << >> /\ (orderRejectedReturnBitfield8.value[1] \div 4) % 2 > 0), ReadBytes(echoText.rest, 8), echoText.rest) IN IF ~stopPx.ok THEN Fail ELSE
    LET routingInst == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderRejectedReturnBitfield8.value # << >> /\ (orderRejectedReturnBitfield8.value[1] \div 8) % 2 > 0), ReadBytes(stopPx.rest, 4), stopPx.rest) IN IF ~routingInst.ok THEN Fail ELSE
    LET routStrategy == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderRejectedReturnBitfield8.value # << >> /\ (orderRejectedReturnBitfield8.value[1] \div 16) % 2 > 0), ReadBytes(routingInst.rest, 6), routingInst.rest) IN IF ~routStrategy.ok THEN Fail ELSE
    LET routeDeliveryMethod == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderRejectedReturnBitfield8.value # << >> /\ (orderRejectedReturnBitfield8.value[1] \div 32) % 2 > 0), ReadBytes(routStrategy.rest, 3), routStrategy.rest) IN IF ~routeDeliveryMethod.ok THEN Fail ELSE
    LET exDestination == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderRejectedReturnBitfield8.value # << >> /\ (orderRejectedReturnBitfield8.value[1] \div 64) % 2 > 0), ReadBytes(routeDeliveryMethod.rest, 1), routeDeliveryMethod.rest) IN IF ~exDestination.ok THEN Fail ELSE
    Ok([ transactionTime               |-> transactionTime.value,
         clOrdId                       |-> clOrdId.value,
         orderRejectReason             |-> orderRejectReason.value,
         text                          |-> text.value,
         reserved1                     |-> reserved1.value,
         numberOfReturnBitfields       |-> numberOfReturnBitfields.value,
         orderRejectedReturnBitfield1  |-> orderRejectedReturnBitfield1.value,
         orderRejectedReturnBitfield2  |-> orderRejectedReturnBitfield2.value,
         orderRejectedReturnBitfield3  |-> orderRejectedReturnBitfield3.value,
         orderRejectedReturnBitfield4  |-> orderRejectedReturnBitfield4.value,
         orderRejectedReturnBitfield5  |-> orderRejectedReturnBitfield5.value,
         orderRejectedReturnBitfield6  |-> orderRejectedReturnBitfield6.value,
         orderRejectedReturnBitfield7  |-> orderRejectedReturnBitfield7.value,
         orderRejectedReturnBitfield8  |-> orderRejectedReturnBitfield8.value,
         orderRejectedReturnBitfield9  |-> orderRejectedReturnBitfield9.value,
         orderRejectedReturnBitfield10 |-> orderRejectedReturnBitfield10.value,
         orderRejectedReturnBitfield11 |-> orderRejectedReturnBitfield11.value,
         orderRejectedReturnBitfield12 |-> orderRejectedReturnBitfield12.value,
         orderRejectedReturnBitfield13 |-> orderRejectedReturnBitfield13.value,
         orderRejectedReturnBitfield14 |-> orderRejectedReturnBitfield14.value,
         orderRejectedReturnBitfield15 |-> orderRejectedReturnBitfield15.value,
         orderRejectedReturnBitfield16 |-> orderRejectedReturnBitfield16.value,
         orderRejectedReturnBitfield17 |-> orderRejectedReturnBitfield17.value,
         orderRejectedReturnBitfield18 |-> orderRejectedReturnBitfield18.value,
         orderRejectedReturnBitfield19 |-> orderRejectedReturnBitfield19.value,
         orderRejectedReturnBitfield20 |-> orderRejectedReturnBitfield20.value,
         orderRejectedReturnBitfield21 |-> orderRejectedReturnBitfield21.value,
         orderRejectedReturnBitfield22 |-> orderRejectedReturnBitfield22.value,
         side                          |-> side.value,
         pegDifference                 |-> pegDifference.value,
         price                         |-> price.value,
         execInst                      |-> execInst.value,
         ordType                       |-> ordType.value,
         timeInForce                   |-> timeInForce.value,
         minQty                        |-> minQty.value,
         symbol                        |-> symbol.value,
         symbolSfx                     |-> symbolSfx.value,
         capacity                      |-> capacity.value,
         account                       |-> account.value,
         clearingFirm                  |-> clearingFirm.value,
         clearingAccount               |-> clearingAccount.value,
         displayIndicator              |-> displayIndicator.value,
         maxFloor                      |-> maxFloor.value,
         discretionAmount              |-> discretionAmount.value,
         orderQty                      |-> orderQty.value,
         preventMatch                  |-> preventMatch.value,
         secondaryOrderId              |-> secondaryOrderId.value,
         attributedQuote               |-> attributedQuote.value,
         extExecInst                   |-> extExecInst.value,
         echoText                      |-> echoText.value,
         stopPx                        |-> stopPx.value,
         routingInst                   |-> routingInst.value,
         routStrategy                  |-> routStrategy.value,
         routeDeliveryMethod           |-> routeDeliveryMethod.value,
         exDestination                 |-> exDestination.value ], exDestination.rest)

(* Order Rejected Message with each field marked present by fields before it there exactly where they say *)
SettleOrderRejectedMessage(message) ==
    LET settled1 == [message EXCEPT !.orderRejectedReturnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.orderRejectedReturnBitfield1 = << >> THEN <<0>> ELSE message.orderRejectedReturnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.orderRejectedReturnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.orderRejectedReturnBitfield2 = << >> THEN <<0>> ELSE settled1.orderRejectedReturnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.orderRejectedReturnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.orderRejectedReturnBitfield3 = << >> THEN <<0>> ELSE settled2.orderRejectedReturnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.orderRejectedReturnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.orderRejectedReturnBitfield4 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled3.orderRejectedReturnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.orderRejectedReturnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.orderRejectedReturnBitfield5 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled4.orderRejectedReturnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.orderRejectedReturnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.orderRejectedReturnBitfield6 = << >> THEN <<0>> ELSE settled5.orderRejectedReturnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.orderRejectedReturnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.orderRejectedReturnBitfield7 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.orderRejectedReturnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.orderRejectedReturnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.orderRejectedReturnBitfield8 = << >> THEN <<0>> ELSE settled7.orderRejectedReturnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.orderRejectedReturnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.orderRejectedReturnBitfield9 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled8.orderRejectedReturnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.orderRejectedReturnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.orderRejectedReturnBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.orderRejectedReturnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.orderRejectedReturnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.orderRejectedReturnBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.orderRejectedReturnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.orderRejectedReturnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.orderRejectedReturnBitfield12 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.orderRejectedReturnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.orderRejectedReturnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.orderRejectedReturnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.orderRejectedReturnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.orderRejectedReturnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.orderRejectedReturnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.orderRejectedReturnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.orderRejectedReturnBitfield15 = IF settled14.numberOfReturnBitfields >= 15 THEN (IF settled14.orderRejectedReturnBitfield15 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.orderRejectedReturnBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.orderRejectedReturnBitfield16 = IF settled15.numberOfReturnBitfields >= 16 THEN (IF settled15.orderRejectedReturnBitfield16 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled15.orderRejectedReturnBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.orderRejectedReturnBitfield17 = IF settled16.numberOfReturnBitfields >= 17 THEN (IF settled16.orderRejectedReturnBitfield17 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled16.orderRejectedReturnBitfield17) ELSE << >>]
        settled18 == [settled17 EXCEPT !.orderRejectedReturnBitfield18 = IF settled17.numberOfReturnBitfields >= 18 THEN (IF settled17.orderRejectedReturnBitfield18 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.orderRejectedReturnBitfield18) ELSE << >>]
        settled19 == [settled18 EXCEPT !.orderRejectedReturnBitfield19 = IF settled18.numberOfReturnBitfields >= 19 THEN (IF settled18.orderRejectedReturnBitfield19 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled18.orderRejectedReturnBitfield19) ELSE << >>]
        settled20 == [settled19 EXCEPT !.orderRejectedReturnBitfield20 = IF settled19.numberOfReturnBitfields >= 20 THEN (IF settled19.orderRejectedReturnBitfield20 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled19.orderRejectedReturnBitfield20) ELSE << >>]
        settled21 == [settled20 EXCEPT !.orderRejectedReturnBitfield21 = IF settled20.numberOfReturnBitfields >= 21 THEN (IF settled20.orderRejectedReturnBitfield21 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled20.orderRejectedReturnBitfield21) ELSE << >>]
        settled22 == [settled21 EXCEPT !.orderRejectedReturnBitfield22 = IF settled21.numberOfReturnBitfields >= 22 THEN (IF settled21.orderRejectedReturnBitfield22 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled21.orderRejectedReturnBitfield22) ELSE << >>]
        settled23 == [settled22 EXCEPT !.side = IF settled22.numberOfReturnBitfields >= 1 /\ (settled22.orderRejectedReturnBitfield1 # << >> /\ settled22.orderRejectedReturnBitfield1[1] % 2 > 0) THEN (IF settled22.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled22.side) ELSE << >>]
        settled24 == [settled23 EXCEPT !.pegDifference = IF settled23.numberOfReturnBitfields >= 1 /\ (settled23.orderRejectedReturnBitfield1 # << >> /\ (settled23.orderRejectedReturnBitfield1[1] \div 2) % 2 > 0) THEN (IF settled23.pegDifference = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled23.pegDifference) ELSE << >>]
        settled25 == [settled24 EXCEPT !.price = IF settled24.numberOfReturnBitfields >= 1 /\ (settled24.orderRejectedReturnBitfield1 # << >> /\ (settled24.orderRejectedReturnBitfield1[1] \div 4) % 2 > 0) THEN (IF settled24.price = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled24.price) ELSE << >>]
        settled26 == [settled25 EXCEPT !.execInst = IF settled25.numberOfReturnBitfields >= 1 /\ (settled25.orderRejectedReturnBitfield1 # << >> /\ (settled25.orderRejectedReturnBitfield1[1] \div 8) % 2 > 0) THEN (IF settled25.execInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled25.execInst) ELSE << >>]
        settled27 == [settled26 EXCEPT !.ordType = IF settled26.numberOfReturnBitfields >= 1 /\ (settled26.orderRejectedReturnBitfield1 # << >> /\ (settled26.orderRejectedReturnBitfield1[1] \div 16) % 2 > 0) THEN (IF settled26.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled26.ordType) ELSE << >>]
        settled28 == [settled27 EXCEPT !.timeInForce = IF settled27.numberOfReturnBitfields >= 1 /\ (settled27.orderRejectedReturnBitfield1 # << >> /\ (settled27.orderRejectedReturnBitfield1[1] \div 32) % 2 > 0) THEN (IF settled27.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled27.timeInForce) ELSE << >>]
        settled29 == [settled28 EXCEPT !.minQty = IF settled28.numberOfReturnBitfields >= 1 /\ (settled28.orderRejectedReturnBitfield1 # << >> /\ (settled28.orderRejectedReturnBitfield1[1] \div 64) % 2 > 0) THEN (IF settled28.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled28.minQty) ELSE << >>]
        settled30 == [settled29 EXCEPT !.symbol = IF settled29.numberOfReturnBitfields >= 2 /\ (settled29.orderRejectedReturnBitfield2 # << >> /\ settled29.orderRejectedReturnBitfield2[1] % 2 > 0) THEN (IF settled29.symbol = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled29.symbol) ELSE << >>]
        settled31 == [settled30 EXCEPT !.symbolSfx = IF settled30.numberOfReturnBitfields >= 2 /\ (settled30.orderRejectedReturnBitfield2 # << >> /\ (settled30.orderRejectedReturnBitfield2[1] \div 2) % 2 > 0) THEN (IF settled30.symbolSfx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled30.symbolSfx) ELSE << >>]
        settled32 == [settled31 EXCEPT !.capacity = IF settled31.numberOfReturnBitfields >= 2 /\ (settled31.orderRejectedReturnBitfield2 # << >> /\ (settled31.orderRejectedReturnBitfield2[1] \div 64) % 2 > 0) THEN (IF settled31.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled31.capacity) ELSE << >>]
        settled33 == [settled32 EXCEPT !.account = IF settled32.numberOfReturnBitfields >= 3 /\ (settled32.orderRejectedReturnBitfield3 # << >> /\ settled32.orderRejectedReturnBitfield3[1] % 2 > 0) THEN (IF settled32.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled32.account) ELSE << >>]
        settled34 == [settled33 EXCEPT !.clearingFirm = IF settled33.numberOfReturnBitfields >= 3 /\ (settled33.orderRejectedReturnBitfield3 # << >> /\ (settled33.orderRejectedReturnBitfield3[1] \div 2) % 2 > 0) THEN (IF settled33.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled33.clearingFirm) ELSE << >>]
        settled35 == [settled34 EXCEPT !.clearingAccount = IF settled34.numberOfReturnBitfields >= 3 /\ (settled34.orderRejectedReturnBitfield3 # << >> /\ (settled34.orderRejectedReturnBitfield3[1] \div 4) % 2 > 0) THEN (IF settled34.clearingAccount = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled34.clearingAccount) ELSE << >>]
        settled36 == [settled35 EXCEPT !.displayIndicator = IF settled35.numberOfReturnBitfields >= 3 /\ (settled35.orderRejectedReturnBitfield3 # << >> /\ (settled35.orderRejectedReturnBitfield3[1] \div 8) % 2 > 0) THEN (IF settled35.displayIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled35.displayIndicator) ELSE << >>]
        settled37 == [settled36 EXCEPT !.maxFloor = IF settled36.numberOfReturnBitfields >= 3 /\ (settled36.orderRejectedReturnBitfield3 # << >> /\ (settled36.orderRejectedReturnBitfield3[1] \div 16) % 2 > 0) THEN (IF settled36.maxFloor = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled36.maxFloor) ELSE << >>]
        settled38 == [settled37 EXCEPT !.discretionAmount = IF settled37.numberOfReturnBitfields >= 3 /\ (settled37.orderRejectedReturnBitfield3 # << >> /\ (settled37.orderRejectedReturnBitfield3[1] \div 32) % 2 > 0) THEN (IF settled37.discretionAmount = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled37.discretionAmount) ELSE << >>]
        settled39 == [settled38 EXCEPT !.orderQty = IF settled38.numberOfReturnBitfields >= 3 /\ (settled38.orderRejectedReturnBitfield3 # << >> /\ (settled38.orderRejectedReturnBitfield3[1] \div 64) % 2 > 0) THEN (IF settled38.orderQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled38.orderQty) ELSE << >>]
        settled40 == [settled39 EXCEPT !.preventMatch = IF settled39.numberOfReturnBitfields >= 3 /\ (settled39.orderRejectedReturnBitfield3 # << >> /\ (settled39.orderRejectedReturnBitfield3[1] \div 128) % 2 > 0) THEN (IF settled39.preventMatch = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled39.preventMatch) ELSE << >>]
        settled41 == [settled40 EXCEPT !.secondaryOrderId = IF settled40.numberOfReturnBitfields >= 6 /\ (settled40.orderRejectedReturnBitfield6 # << >> /\ settled40.orderRejectedReturnBitfield6[1] % 2 > 0) THEN (IF settled40.secondaryOrderId = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled40.secondaryOrderId) ELSE << >>]
        settled42 == [settled41 EXCEPT !.attributedQuote = IF settled41.numberOfReturnBitfields >= 6 /\ (settled41.orderRejectedReturnBitfield6 # << >> /\ (settled41.orderRejectedReturnBitfield6[1] \div 8) % 2 > 0) THEN (IF settled41.attributedQuote = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled41.attributedQuote) ELSE << >>]
        settled43 == [settled42 EXCEPT !.extExecInst = IF settled42.numberOfReturnBitfields >= 6 /\ (settled42.orderRejectedReturnBitfield6 # << >> /\ (settled42.orderRejectedReturnBitfield6[1] \div 16) % 2 > 0) THEN (IF settled42.extExecInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled42.extExecInst) ELSE << >>]
        settled44 == [settled43 EXCEPT !.echoText = IF settled43.numberOfReturnBitfields >= 8 /\ (settled43.orderRejectedReturnBitfield8 # << >> /\ (settled43.orderRejectedReturnBitfield8[1] \div 2) % 2 > 0) THEN (IF settled43.echoText = << >> THEN <<[i \in 1 .. 64 |-> 0]>> ELSE settled43.echoText) ELSE << >>]
        settled45 == [settled44 EXCEPT !.stopPx = IF settled44.numberOfReturnBitfields >= 8 /\ (settled44.orderRejectedReturnBitfield8 # << >> /\ (settled44.orderRejectedReturnBitfield8[1] \div 4) % 2 > 0) THEN (IF settled44.stopPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled44.stopPx) ELSE << >>]
        settled46 == [settled45 EXCEPT !.routingInst = IF settled45.numberOfReturnBitfields >= 8 /\ (settled45.orderRejectedReturnBitfield8 # << >> /\ (settled45.orderRejectedReturnBitfield8[1] \div 8) % 2 > 0) THEN (IF settled45.routingInst = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled45.routingInst) ELSE << >>]
        settled47 == [settled46 EXCEPT !.routStrategy = IF settled46.numberOfReturnBitfields >= 8 /\ (settled46.orderRejectedReturnBitfield8 # << >> /\ (settled46.orderRejectedReturnBitfield8[1] \div 16) % 2 > 0) THEN (IF settled46.routStrategy = << >> THEN <<[i \in 1 .. 6 |-> 0]>> ELSE settled46.routStrategy) ELSE << >>]
        settled48 == [settled47 EXCEPT !.routeDeliveryMethod = IF settled47.numberOfReturnBitfields >= 8 /\ (settled47.orderRejectedReturnBitfield8 # << >> /\ (settled47.orderRejectedReturnBitfield8[1] \div 32) % 2 > 0) THEN (IF settled47.routeDeliveryMethod = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled47.routeDeliveryMethod) ELSE << >>]
        settled49 == [settled48 EXCEPT !.exDestination = IF settled48.numberOfReturnBitfields >= 8 /\ (settled48.orderRejectedReturnBitfield8 # << >> /\ (settled48.orderRejectedReturnBitfield8[1] \div 64) % 2 > 0) THEN (IF settled48.exDestination = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled48.exDestination) ELSE << >>]
    IN  settled49

ZeroOrderRejectedMessage ==
    SettleOrderRejectedMessage([ transactionTime               |-> [i \in 1 .. 8 |-> 0],
                                 clOrdId                       |-> [i \in 1 .. 20 |-> 0],
                                 orderRejectReason             |-> [i \in 1 .. 1 |-> 0],
                                 text                          |-> [i \in 1 .. 60 |-> 0],
                                 reserved1                     |-> [i \in 1 .. 1 |-> 0],
                                 numberOfReturnBitfields       |-> 0,
                                 orderRejectedReturnBitfield1  |-> << >>,
                                 orderRejectedReturnBitfield2  |-> << >>,
                                 orderRejectedReturnBitfield3  |-> << >>,
                                 orderRejectedReturnBitfield4  |-> << >>,
                                 orderRejectedReturnBitfield5  |-> << >>,
                                 orderRejectedReturnBitfield6  |-> << >>,
                                 orderRejectedReturnBitfield7  |-> << >>,
                                 orderRejectedReturnBitfield8  |-> << >>,
                                 orderRejectedReturnBitfield9  |-> << >>,
                                 orderRejectedReturnBitfield10 |-> << >>,
                                 orderRejectedReturnBitfield11 |-> << >>,
                                 orderRejectedReturnBitfield12 |-> << >>,
                                 orderRejectedReturnBitfield13 |-> << >>,
                                 orderRejectedReturnBitfield14 |-> << >>,
                                 orderRejectedReturnBitfield15 |-> << >>,
                                 orderRejectedReturnBitfield16 |-> << >>,
                                 orderRejectedReturnBitfield17 |-> << >>,
                                 orderRejectedReturnBitfield18 |-> << >>,
                                 orderRejectedReturnBitfield19 |-> << >>,
                                 orderRejectedReturnBitfield20 |-> << >>,
                                 orderRejectedReturnBitfield21 |-> << >>,
                                 orderRejectedReturnBitfield22 |-> << >>,
                                 side                          |-> << >>,
                                 pegDifference                 |-> << >>,
                                 price                         |-> << >>,
                                 execInst                      |-> << >>,
                                 ordType                       |-> << >>,
                                 timeInForce                   |-> << >>,
                                 minQty                        |-> << >>,
                                 symbol                        |-> << >>,
                                 symbolSfx                     |-> << >>,
                                 capacity                      |-> << >>,
                                 account                       |-> << >>,
                                 clearingFirm                  |-> << >>,
                                 clearingAccount               |-> << >>,
                                 displayIndicator              |-> << >>,
                                 maxFloor                      |-> << >>,
                                 discretionAmount              |-> << >>,
                                 orderQty                      |-> << >>,
                                 preventMatch                  |-> << >>,
                                 secondaryOrderId              |-> << >>,
                                 attributedQuote               |-> << >>,
                                 extExecInst                   |-> << >>,
                                 echoText                      |-> << >>,
                                 stopPx                        |-> << >>,
                                 routingInst                   |-> << >>,
                                 routStrategy                  |-> << >>,
                                 routeDeliveryMethod           |-> << >>,
                                 exDestination                 |-> << >> ])

(* Order Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderRejectedMessage ==
    { ZeroOrderRejectedMessage }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.transactionTime = one]) : one \in Sample(8) }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.clOrdId = one]) : one \in Sample(20) }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.orderRejectReason = one]) : one \in Sample(1) }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.text = one]) : one \in Sample(60) }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.reserved1 = one]) : one \in Sample(1) }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderRejectedReturnBitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 2, !.orderRejectedReturnBitfield2 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderRejectedReturnBitfield3 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 4, !.orderRejectedReturnBitfield4 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderRejectedReturnBitfield5 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 6, !.orderRejectedReturnBitfield6 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 7, !.orderRejectedReturnBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderRejectedReturnBitfield8 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 9, !.orderRejectedReturnBitfield9 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 10, !.orderRejectedReturnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 11, !.orderRejectedReturnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 12, !.orderRejectedReturnBitfield12 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 13, !.orderRejectedReturnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 14, !.orderRejectedReturnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 15, !.orderRejectedReturnBitfield15 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 16, !.orderRejectedReturnBitfield16 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 17, !.orderRejectedReturnBitfield17 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 18, !.orderRejectedReturnBitfield18 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 19, !.orderRejectedReturnBitfield19 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 20, !.orderRejectedReturnBitfield20 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 21, !.orderRejectedReturnBitfield21 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 22, !.orderRejectedReturnBitfield22 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderRejectedReturnBitfield1 = <<1>>, !.side = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderRejectedReturnBitfield1 = <<2>>, !.pegDifference = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderRejectedReturnBitfield1 = <<4>>, !.price = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderRejectedReturnBitfield1 = <<8>>, !.execInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderRejectedReturnBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderRejectedReturnBitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderRejectedReturnBitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 2, !.orderRejectedReturnBitfield2 = <<1>>, !.symbol = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 2, !.orderRejectedReturnBitfield2 = <<2>>, !.symbolSfx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 2, !.orderRejectedReturnBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderRejectedReturnBitfield3 = <<1>>, !.account = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderRejectedReturnBitfield3 = <<2>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderRejectedReturnBitfield3 = <<4>>, !.clearingAccount = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderRejectedReturnBitfield3 = <<8>>, !.displayIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderRejectedReturnBitfield3 = <<16>>, !.maxFloor = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderRejectedReturnBitfield3 = <<32>>, !.discretionAmount = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderRejectedReturnBitfield3 = <<64>>, !.orderQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderRejectedReturnBitfield3 = <<128>>, !.preventMatch = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 6, !.orderRejectedReturnBitfield6 = <<1>>, !.secondaryOrderId = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 6, !.orderRejectedReturnBitfield6 = <<8>>, !.attributedQuote = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 6, !.orderRejectedReturnBitfield6 = <<16>>, !.extExecInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderRejectedReturnBitfield8 = <<2>>, !.echoText = one]) : one \in { <<held>> : held \in Sample(64) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderRejectedReturnBitfield8 = <<4>>, !.stopPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderRejectedReturnBitfield8 = <<8>>, !.routingInst = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderRejectedReturnBitfield8 = <<16>>, !.routStrategy = one]) : one \in { <<held>> : held \in Sample(6) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderRejectedReturnBitfield8 = <<32>>, !.routeDeliveryMethod = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderRejectedReturnBitfield8 = <<64>>, !.exDestination = one]) : one \in { <<held>> : held \in Sample(1) } }

(***************************************************************************)
(* Order Modified Message                                                  *)
(***************************************************************************)

OrderModifiedMessage ==
    [ transactionTime               : Sample(8),
      clOrdId                       : Sample(20),
      orderId                       : Sample(8),
      reserved1                     : Sample(1),
      numberOfReturnBitfields       : 0 .. 255,
      orderModifiedReturnBitfield1  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderModifiedReturnBitfield2  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderModifiedReturnBitfield3  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderModifiedReturnBitfield4  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderModifiedReturnBitfield5  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderModifiedReturnBitfield6  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderModifiedReturnBitfield7  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderModifiedReturnBitfield8  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderModifiedReturnBitfield9  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderModifiedReturnBitfield10 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderModifiedReturnBitfield11 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderModifiedReturnBitfield12 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderModifiedReturnBitfield13 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderModifiedReturnBitfield14 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderModifiedReturnBitfield15 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderModifiedReturnBitfield16 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderModifiedReturnBitfield17 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderModifiedReturnBitfield18 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderModifiedReturnBitfield19 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderModifiedReturnBitfield20 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderModifiedReturnBitfield21 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderModifiedReturnBitfield22 : { << >> } \cup { <<held>> : held \in Sample(1) },
      side                          : { << >> } \cup { <<held>> : held \in Sample(1) },
      pegDifference                 : { << >> } \cup { <<held>> : held \in Sample(8) },
      price                         : { << >> } \cup { <<held>> : held \in Sample(8) },
      execInst                      : { << >> } \cup { <<held>> : held \in Sample(1) },
      ordType                       : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce                   : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                        : { << >> } \cup { <<held>> : held \in Sample(4) },
      symbol                        : { << >> } \cup { <<held>> : held \in Sample(8) },
      symbolSfx                     : { << >> } \cup { <<held>> : held \in Sample(8) },
      account                       : { << >> } \cup { <<held>> : held \in Sample(16) },
      clearingFirm                  : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingAccount               : { << >> } \cup { <<held>> : held \in Sample(4) },
      displayIndicator              : { << >> } \cup { <<held>> : held \in Sample(1) },
      maxFloor                      : { << >> } \cup { <<held>> : held \in Sample(4) },
      discretionAmount              : { << >> } \cup { <<held>> : held \in Sample(2) },
      orderQty                      : { << >> } \cup { <<held>> : held \in Sample(4) },
      preventMatch                  : { << >> } \cup { <<held>> : held \in Sample(3) },
      origClOrdId                   : { << >> } \cup { <<held>> : held \in Sample(20) },
      leavesQty                     : { << >> } \cup { <<held>> : held \in Sample(4) },
      lastShares                    : { << >> } \cup { <<held>> : held \in Sample(4) },
      lastPx                        : { << >> } \cup { <<held>> : held \in Sample(8) },
      displayPrice                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      workingPrice                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      baseLiquidityIndicator        : { << >> } \cup { <<held>> : held \in Sample(1) },
      expireTime                    : { << >> } \cup { <<held>> : held \in Sample(8) },
      secondaryOrderId              : { << >> } \cup { <<held>> : held \in Sample(8) },
      attributedQuote               : { << >> } \cup { <<held>> : held \in Sample(1) },
      extExecInst                   : { << >> } \cup { <<held>> : held \in Sample(1) },
      echoText                      : { << >> } \cup { <<held>> : held \in Sample(64) },
      stopPx                        : { << >> } \cup { <<held>> : held \in Sample(8) },
      routingInst                   : { << >> } \cup { <<held>> : held \in Sample(4) },
      routStrategy                  : { << >> } \cup { <<held>> : held \in Sample(6) },
      routeDeliveryMethod           : { << >> } \cup { <<held>> : held \in Sample(3) },
      exDestination                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      crossTradeFlag                : { << >> } \cup { <<held>> : held \in Sample(1) },
      locateBroker                  : { << >> } \cup { <<held>> : held \in Sample(4) } ]

EncodeOrderModifiedMessage(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.orderId
        \o message.reserved1
        \o EncodeUIntBE(message.numberOfReturnBitfields, 1)
        \o (IF message.orderModifiedReturnBitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.orderModifiedReturnBitfield1[1], 1))
        \o (IF message.orderModifiedReturnBitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.orderModifiedReturnBitfield2[1], 1))
        \o (IF message.orderModifiedReturnBitfield3 = << >> THEN << >> ELSE EncodeUIntLE(message.orderModifiedReturnBitfield3[1], 1))
        \o (IF message.orderModifiedReturnBitfield4 = << >> THEN << >> ELSE message.orderModifiedReturnBitfield4[1])
        \o (IF message.orderModifiedReturnBitfield5 = << >> THEN << >> ELSE EncodeUIntLE(message.orderModifiedReturnBitfield5[1], 1))
        \o (IF message.orderModifiedReturnBitfield6 = << >> THEN << >> ELSE EncodeUIntLE(message.orderModifiedReturnBitfield6[1], 1))
        \o (IF message.orderModifiedReturnBitfield7 = << >> THEN << >> ELSE message.orderModifiedReturnBitfield7[1])
        \o (IF message.orderModifiedReturnBitfield8 = << >> THEN << >> ELSE EncodeUIntLE(message.orderModifiedReturnBitfield8[1], 1))
        \o (IF message.orderModifiedReturnBitfield9 = << >> THEN << >> ELSE message.orderModifiedReturnBitfield9[1])
        \o (IF message.orderModifiedReturnBitfield10 = << >> THEN << >> ELSE message.orderModifiedReturnBitfield10[1])
        \o (IF message.orderModifiedReturnBitfield11 = << >> THEN << >> ELSE message.orderModifiedReturnBitfield11[1])
        \o (IF message.orderModifiedReturnBitfield12 = << >> THEN << >> ELSE message.orderModifiedReturnBitfield12[1])
        \o (IF message.orderModifiedReturnBitfield13 = << >> THEN << >> ELSE message.orderModifiedReturnBitfield13[1])
        \o (IF message.orderModifiedReturnBitfield14 = << >> THEN << >> ELSE message.orderModifiedReturnBitfield14[1])
        \o (IF message.orderModifiedReturnBitfield15 = << >> THEN << >> ELSE message.orderModifiedReturnBitfield15[1])
        \o (IF message.orderModifiedReturnBitfield16 = << >> THEN << >> ELSE message.orderModifiedReturnBitfield16[1])
        \o (IF message.orderModifiedReturnBitfield17 = << >> THEN << >> ELSE message.orderModifiedReturnBitfield17[1])
        \o (IF message.orderModifiedReturnBitfield18 = << >> THEN << >> ELSE EncodeUIntLE(message.orderModifiedReturnBitfield18[1], 1))
        \o (IF message.orderModifiedReturnBitfield19 = << >> THEN << >> ELSE message.orderModifiedReturnBitfield19[1])
        \o (IF message.orderModifiedReturnBitfield20 = << >> THEN << >> ELSE message.orderModifiedReturnBitfield20[1])
        \o (IF message.orderModifiedReturnBitfield21 = << >> THEN << >> ELSE message.orderModifiedReturnBitfield21[1])
        \o (IF message.orderModifiedReturnBitfield22 = << >> THEN << >> ELSE message.orderModifiedReturnBitfield22[1])
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
    LET orderModifiedReturnBitfield1 == ReadWhen(numberOfReturnBitfields.value >= 1, ReadUIntLE(numberOfReturnBitfields.rest, 1), numberOfReturnBitfields.rest) IN IF ~orderModifiedReturnBitfield1.ok THEN Fail ELSE
    LET orderModifiedReturnBitfield2 == ReadWhen(numberOfReturnBitfields.value >= 2, ReadUIntLE(orderModifiedReturnBitfield1.rest, 1), orderModifiedReturnBitfield1.rest) IN IF ~orderModifiedReturnBitfield2.ok THEN Fail ELSE
    LET orderModifiedReturnBitfield3 == ReadWhen(numberOfReturnBitfields.value >= 3, ReadUIntLE(orderModifiedReturnBitfield2.rest, 1), orderModifiedReturnBitfield2.rest) IN IF ~orderModifiedReturnBitfield3.ok THEN Fail ELSE
    LET orderModifiedReturnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadBytes(orderModifiedReturnBitfield3.rest, 1), orderModifiedReturnBitfield3.rest) IN IF ~orderModifiedReturnBitfield4.ok THEN Fail ELSE
    LET orderModifiedReturnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadUIntLE(orderModifiedReturnBitfield4.rest, 1), orderModifiedReturnBitfield4.rest) IN IF ~orderModifiedReturnBitfield5.ok THEN Fail ELSE
    LET orderModifiedReturnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadUIntLE(orderModifiedReturnBitfield5.rest, 1), orderModifiedReturnBitfield5.rest) IN IF ~orderModifiedReturnBitfield6.ok THEN Fail ELSE
    LET orderModifiedReturnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadBytes(orderModifiedReturnBitfield6.rest, 1), orderModifiedReturnBitfield6.rest) IN IF ~orderModifiedReturnBitfield7.ok THEN Fail ELSE
    LET orderModifiedReturnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadUIntLE(orderModifiedReturnBitfield7.rest, 1), orderModifiedReturnBitfield7.rest) IN IF ~orderModifiedReturnBitfield8.ok THEN Fail ELSE
    LET orderModifiedReturnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadBytes(orderModifiedReturnBitfield8.rest, 1), orderModifiedReturnBitfield8.rest) IN IF ~orderModifiedReturnBitfield9.ok THEN Fail ELSE
    LET orderModifiedReturnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadBytes(orderModifiedReturnBitfield9.rest, 1), orderModifiedReturnBitfield9.rest) IN IF ~orderModifiedReturnBitfield10.ok THEN Fail ELSE
    LET orderModifiedReturnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadBytes(orderModifiedReturnBitfield10.rest, 1), orderModifiedReturnBitfield10.rest) IN IF ~orderModifiedReturnBitfield11.ok THEN Fail ELSE
    LET orderModifiedReturnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadBytes(orderModifiedReturnBitfield11.rest, 1), orderModifiedReturnBitfield11.rest) IN IF ~orderModifiedReturnBitfield12.ok THEN Fail ELSE
    LET orderModifiedReturnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(orderModifiedReturnBitfield12.rest, 1), orderModifiedReturnBitfield12.rest) IN IF ~orderModifiedReturnBitfield13.ok THEN Fail ELSE
    LET orderModifiedReturnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(orderModifiedReturnBitfield13.rest, 1), orderModifiedReturnBitfield13.rest) IN IF ~orderModifiedReturnBitfield14.ok THEN Fail ELSE
    LET orderModifiedReturnBitfield15 == ReadWhen(numberOfReturnBitfields.value >= 15, ReadBytes(orderModifiedReturnBitfield14.rest, 1), orderModifiedReturnBitfield14.rest) IN IF ~orderModifiedReturnBitfield15.ok THEN Fail ELSE
    LET orderModifiedReturnBitfield16 == ReadWhen(numberOfReturnBitfields.value >= 16, ReadBytes(orderModifiedReturnBitfield15.rest, 1), orderModifiedReturnBitfield15.rest) IN IF ~orderModifiedReturnBitfield16.ok THEN Fail ELSE
    LET orderModifiedReturnBitfield17 == ReadWhen(numberOfReturnBitfields.value >= 17, ReadBytes(orderModifiedReturnBitfield16.rest, 1), orderModifiedReturnBitfield16.rest) IN IF ~orderModifiedReturnBitfield17.ok THEN Fail ELSE
    LET orderModifiedReturnBitfield18 == ReadWhen(numberOfReturnBitfields.value >= 18, ReadUIntLE(orderModifiedReturnBitfield17.rest, 1), orderModifiedReturnBitfield17.rest) IN IF ~orderModifiedReturnBitfield18.ok THEN Fail ELSE
    LET orderModifiedReturnBitfield19 == ReadWhen(numberOfReturnBitfields.value >= 19, ReadBytes(orderModifiedReturnBitfield18.rest, 1), orderModifiedReturnBitfield18.rest) IN IF ~orderModifiedReturnBitfield19.ok THEN Fail ELSE
    LET orderModifiedReturnBitfield20 == ReadWhen(numberOfReturnBitfields.value >= 20, ReadBytes(orderModifiedReturnBitfield19.rest, 1), orderModifiedReturnBitfield19.rest) IN IF ~orderModifiedReturnBitfield20.ok THEN Fail ELSE
    LET orderModifiedReturnBitfield21 == ReadWhen(numberOfReturnBitfields.value >= 21, ReadBytes(orderModifiedReturnBitfield20.rest, 1), orderModifiedReturnBitfield20.rest) IN IF ~orderModifiedReturnBitfield21.ok THEN Fail ELSE
    LET orderModifiedReturnBitfield22 == ReadWhen(numberOfReturnBitfields.value >= 22, ReadBytes(orderModifiedReturnBitfield21.rest, 1), orderModifiedReturnBitfield21.rest) IN IF ~orderModifiedReturnBitfield22.ok THEN Fail ELSE
    LET side == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderModifiedReturnBitfield1.value # << >> /\ orderModifiedReturnBitfield1.value[1] % 2 > 0), ReadBytes(orderModifiedReturnBitfield22.rest, 1), orderModifiedReturnBitfield22.rest) IN IF ~side.ok THEN Fail ELSE
    LET pegDifference == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderModifiedReturnBitfield1.value # << >> /\ (orderModifiedReturnBitfield1.value[1] \div 2) % 2 > 0), ReadBytes(side.rest, 8), side.rest) IN IF ~pegDifference.ok THEN Fail ELSE
    LET price == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderModifiedReturnBitfield1.value # << >> /\ (orderModifiedReturnBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(pegDifference.rest, 8), pegDifference.rest) IN IF ~price.ok THEN Fail ELSE
    LET execInst == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderModifiedReturnBitfield1.value # << >> /\ (orderModifiedReturnBitfield1.value[1] \div 8) % 2 > 0), ReadBytes(price.rest, 1), price.rest) IN IF ~execInst.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderModifiedReturnBitfield1.value # << >> /\ (orderModifiedReturnBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(execInst.rest, 1), execInst.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderModifiedReturnBitfield1.value # << >> /\ (orderModifiedReturnBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderModifiedReturnBitfield1.value # << >> /\ (orderModifiedReturnBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET symbol == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderModifiedReturnBitfield2.value # << >> /\ orderModifiedReturnBitfield2.value[1] % 2 > 0), ReadBytes(minQty.rest, 8), minQty.rest) IN IF ~symbol.ok THEN Fail ELSE
    LET symbolSfx == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderModifiedReturnBitfield2.value # << >> /\ (orderModifiedReturnBitfield2.value[1] \div 2) % 2 > 0), ReadBytes(symbol.rest, 8), symbol.rest) IN IF ~symbolSfx.ok THEN Fail ELSE
    LET account == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderModifiedReturnBitfield3.value # << >> /\ orderModifiedReturnBitfield3.value[1] % 2 > 0), ReadBytes(symbolSfx.rest, 16), symbolSfx.rest) IN IF ~account.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderModifiedReturnBitfield3.value # << >> /\ (orderModifiedReturnBitfield3.value[1] \div 2) % 2 > 0), ReadBytes(account.rest, 4), account.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderModifiedReturnBitfield3.value # << >> /\ (orderModifiedReturnBitfield3.value[1] \div 4) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET displayIndicator == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderModifiedReturnBitfield3.value # << >> /\ (orderModifiedReturnBitfield3.value[1] \div 8) % 2 > 0), ReadBytes(clearingAccount.rest, 1), clearingAccount.rest) IN IF ~displayIndicator.ok THEN Fail ELSE
    LET maxFloor == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderModifiedReturnBitfield3.value # << >> /\ (orderModifiedReturnBitfield3.value[1] \div 16) % 2 > 0), ReadBytes(displayIndicator.rest, 4), displayIndicator.rest) IN IF ~maxFloor.ok THEN Fail ELSE
    LET discretionAmount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderModifiedReturnBitfield3.value # << >> /\ (orderModifiedReturnBitfield3.value[1] \div 32) % 2 > 0), ReadBytes(maxFloor.rest, 2), maxFloor.rest) IN IF ~discretionAmount.ok THEN Fail ELSE
    LET orderQty == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderModifiedReturnBitfield3.value # << >> /\ (orderModifiedReturnBitfield3.value[1] \div 64) % 2 > 0), ReadBytes(discretionAmount.rest, 4), discretionAmount.rest) IN IF ~orderQty.ok THEN Fail ELSE
    LET preventMatch == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderModifiedReturnBitfield3.value # << >> /\ (orderModifiedReturnBitfield3.value[1] \div 128) % 2 > 0), ReadBytes(orderQty.rest, 3), orderQty.rest) IN IF ~preventMatch.ok THEN Fail ELSE
    LET origClOrdId == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderModifiedReturnBitfield5.value # << >> /\ orderModifiedReturnBitfield5.value[1] % 2 > 0), ReadBytes(preventMatch.rest, 20), preventMatch.rest) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET leavesQty == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderModifiedReturnBitfield5.value # << >> /\ (orderModifiedReturnBitfield5.value[1] \div 2) % 2 > 0), ReadBytes(origClOrdId.rest, 4), origClOrdId.rest) IN IF ~leavesQty.ok THEN Fail ELSE
    LET lastShares == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderModifiedReturnBitfield5.value # << >> /\ (orderModifiedReturnBitfield5.value[1] \div 4) % 2 > 0), ReadBytes(leavesQty.rest, 4), leavesQty.rest) IN IF ~lastShares.ok THEN Fail ELSE
    LET lastPx == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderModifiedReturnBitfield5.value # << >> /\ (orderModifiedReturnBitfield5.value[1] \div 8) % 2 > 0), ReadBytes(lastShares.rest, 8), lastShares.rest) IN IF ~lastPx.ok THEN Fail ELSE
    LET displayPrice == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderModifiedReturnBitfield5.value # << >> /\ (orderModifiedReturnBitfield5.value[1] \div 16) % 2 > 0), ReadBytes(lastPx.rest, 8), lastPx.rest) IN IF ~displayPrice.ok THEN Fail ELSE
    LET workingPrice == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderModifiedReturnBitfield5.value # << >> /\ (orderModifiedReturnBitfield5.value[1] \div 32) % 2 > 0), ReadBytes(displayPrice.rest, 8), displayPrice.rest) IN IF ~workingPrice.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderModifiedReturnBitfield5.value # << >> /\ (orderModifiedReturnBitfield5.value[1] \div 64) % 2 > 0), ReadBytes(workingPrice.rest, 1), workingPrice.rest) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET expireTime == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderModifiedReturnBitfield5.value # << >> /\ (orderModifiedReturnBitfield5.value[1] \div 128) % 2 > 0), ReadBytes(baseLiquidityIndicator.rest, 8), baseLiquidityIndicator.rest) IN IF ~expireTime.ok THEN Fail ELSE
    LET secondaryOrderId == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (orderModifiedReturnBitfield6.value # << >> /\ orderModifiedReturnBitfield6.value[1] % 2 > 0), ReadBytes(expireTime.rest, 8), expireTime.rest) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET attributedQuote == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (orderModifiedReturnBitfield6.value # << >> /\ (orderModifiedReturnBitfield6.value[1] \div 8) % 2 > 0), ReadBytes(secondaryOrderId.rest, 1), secondaryOrderId.rest) IN IF ~attributedQuote.ok THEN Fail ELSE
    LET extExecInst == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (orderModifiedReturnBitfield6.value # << >> /\ (orderModifiedReturnBitfield6.value[1] \div 16) % 2 > 0), ReadBytes(attributedQuote.rest, 1), attributedQuote.rest) IN IF ~extExecInst.ok THEN Fail ELSE
    LET echoText == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderModifiedReturnBitfield8.value # << >> /\ (orderModifiedReturnBitfield8.value[1] \div 2) % 2 > 0), ReadBytes(extExecInst.rest, 64), extExecInst.rest) IN IF ~echoText.ok THEN Fail ELSE
    LET stopPx == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderModifiedReturnBitfield8.value # << >> /\ (orderModifiedReturnBitfield8.value[1] \div 4) % 2 > 0), ReadBytes(echoText.rest, 8), echoText.rest) IN IF ~stopPx.ok THEN Fail ELSE
    LET routingInst == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderModifiedReturnBitfield8.value # << >> /\ (orderModifiedReturnBitfield8.value[1] \div 8) % 2 > 0), ReadBytes(stopPx.rest, 4), stopPx.rest) IN IF ~routingInst.ok THEN Fail ELSE
    LET routStrategy == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderModifiedReturnBitfield8.value # << >> /\ (orderModifiedReturnBitfield8.value[1] \div 16) % 2 > 0), ReadBytes(routingInst.rest, 6), routingInst.rest) IN IF ~routStrategy.ok THEN Fail ELSE
    LET routeDeliveryMethod == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderModifiedReturnBitfield8.value # << >> /\ (orderModifiedReturnBitfield8.value[1] \div 32) % 2 > 0), ReadBytes(routStrategy.rest, 3), routStrategy.rest) IN IF ~routeDeliveryMethod.ok THEN Fail ELSE
    LET exDestination == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderModifiedReturnBitfield8.value # << >> /\ (orderModifiedReturnBitfield8.value[1] \div 64) % 2 > 0), ReadBytes(routeDeliveryMethod.rest, 1), routeDeliveryMethod.rest) IN IF ~exDestination.ok THEN Fail ELSE
    LET crossTradeFlag == ReadWhen(numberOfReturnBitfields.value >= 18 /\ (orderModifiedReturnBitfield18.value # << >> /\ (orderModifiedReturnBitfield18.value[1] \div 8) % 2 > 0), ReadBytes(exDestination.rest, 1), exDestination.rest) IN IF ~crossTradeFlag.ok THEN Fail ELSE
    LET locateBroker == ReadWhen(numberOfReturnBitfields.value >= 18 /\ (orderModifiedReturnBitfield18.value # << >> /\ (orderModifiedReturnBitfield18.value[1] \div 64) % 2 > 0), ReadBytes(crossTradeFlag.rest, 4), crossTradeFlag.rest) IN IF ~locateBroker.ok THEN Fail ELSE
    Ok([ transactionTime               |-> transactionTime.value,
         clOrdId                       |-> clOrdId.value,
         orderId                       |-> orderId.value,
         reserved1                     |-> reserved1.value,
         numberOfReturnBitfields       |-> numberOfReturnBitfields.value,
         orderModifiedReturnBitfield1  |-> orderModifiedReturnBitfield1.value,
         orderModifiedReturnBitfield2  |-> orderModifiedReturnBitfield2.value,
         orderModifiedReturnBitfield3  |-> orderModifiedReturnBitfield3.value,
         orderModifiedReturnBitfield4  |-> orderModifiedReturnBitfield4.value,
         orderModifiedReturnBitfield5  |-> orderModifiedReturnBitfield5.value,
         orderModifiedReturnBitfield6  |-> orderModifiedReturnBitfield6.value,
         orderModifiedReturnBitfield7  |-> orderModifiedReturnBitfield7.value,
         orderModifiedReturnBitfield8  |-> orderModifiedReturnBitfield8.value,
         orderModifiedReturnBitfield9  |-> orderModifiedReturnBitfield9.value,
         orderModifiedReturnBitfield10 |-> orderModifiedReturnBitfield10.value,
         orderModifiedReturnBitfield11 |-> orderModifiedReturnBitfield11.value,
         orderModifiedReturnBitfield12 |-> orderModifiedReturnBitfield12.value,
         orderModifiedReturnBitfield13 |-> orderModifiedReturnBitfield13.value,
         orderModifiedReturnBitfield14 |-> orderModifiedReturnBitfield14.value,
         orderModifiedReturnBitfield15 |-> orderModifiedReturnBitfield15.value,
         orderModifiedReturnBitfield16 |-> orderModifiedReturnBitfield16.value,
         orderModifiedReturnBitfield17 |-> orderModifiedReturnBitfield17.value,
         orderModifiedReturnBitfield18 |-> orderModifiedReturnBitfield18.value,
         orderModifiedReturnBitfield19 |-> orderModifiedReturnBitfield19.value,
         orderModifiedReturnBitfield20 |-> orderModifiedReturnBitfield20.value,
         orderModifiedReturnBitfield21 |-> orderModifiedReturnBitfield21.value,
         orderModifiedReturnBitfield22 |-> orderModifiedReturnBitfield22.value,
         side                          |-> side.value,
         pegDifference                 |-> pegDifference.value,
         price                         |-> price.value,
         execInst                      |-> execInst.value,
         ordType                       |-> ordType.value,
         timeInForce                   |-> timeInForce.value,
         minQty                        |-> minQty.value,
         symbol                        |-> symbol.value,
         symbolSfx                     |-> symbolSfx.value,
         account                       |-> account.value,
         clearingFirm                  |-> clearingFirm.value,
         clearingAccount               |-> clearingAccount.value,
         displayIndicator              |-> displayIndicator.value,
         maxFloor                      |-> maxFloor.value,
         discretionAmount              |-> discretionAmount.value,
         orderQty                      |-> orderQty.value,
         preventMatch                  |-> preventMatch.value,
         origClOrdId                   |-> origClOrdId.value,
         leavesQty                     |-> leavesQty.value,
         lastShares                    |-> lastShares.value,
         lastPx                        |-> lastPx.value,
         displayPrice                  |-> displayPrice.value,
         workingPrice                  |-> workingPrice.value,
         baseLiquidityIndicator        |-> baseLiquidityIndicator.value,
         expireTime                    |-> expireTime.value,
         secondaryOrderId              |-> secondaryOrderId.value,
         attributedQuote               |-> attributedQuote.value,
         extExecInst                   |-> extExecInst.value,
         echoText                      |-> echoText.value,
         stopPx                        |-> stopPx.value,
         routingInst                   |-> routingInst.value,
         routStrategy                  |-> routStrategy.value,
         routeDeliveryMethod           |-> routeDeliveryMethod.value,
         exDestination                 |-> exDestination.value,
         crossTradeFlag                |-> crossTradeFlag.value,
         locateBroker                  |-> locateBroker.value ], locateBroker.rest)

(* Order Modified Message with each field marked present by fields before it there exactly where they say *)
SettleOrderModifiedMessage(message) ==
    LET settled1 == [message EXCEPT !.orderModifiedReturnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.orderModifiedReturnBitfield1 = << >> THEN <<0>> ELSE message.orderModifiedReturnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.orderModifiedReturnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.orderModifiedReturnBitfield2 = << >> THEN <<0>> ELSE settled1.orderModifiedReturnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.orderModifiedReturnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.orderModifiedReturnBitfield3 = << >> THEN <<0>> ELSE settled2.orderModifiedReturnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.orderModifiedReturnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.orderModifiedReturnBitfield4 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled3.orderModifiedReturnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.orderModifiedReturnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.orderModifiedReturnBitfield5 = << >> THEN <<0>> ELSE settled4.orderModifiedReturnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.orderModifiedReturnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.orderModifiedReturnBitfield6 = << >> THEN <<0>> ELSE settled5.orderModifiedReturnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.orderModifiedReturnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.orderModifiedReturnBitfield7 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.orderModifiedReturnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.orderModifiedReturnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.orderModifiedReturnBitfield8 = << >> THEN <<0>> ELSE settled7.orderModifiedReturnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.orderModifiedReturnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.orderModifiedReturnBitfield9 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled8.orderModifiedReturnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.orderModifiedReturnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.orderModifiedReturnBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.orderModifiedReturnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.orderModifiedReturnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.orderModifiedReturnBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.orderModifiedReturnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.orderModifiedReturnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.orderModifiedReturnBitfield12 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.orderModifiedReturnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.orderModifiedReturnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.orderModifiedReturnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.orderModifiedReturnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.orderModifiedReturnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.orderModifiedReturnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.orderModifiedReturnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.orderModifiedReturnBitfield15 = IF settled14.numberOfReturnBitfields >= 15 THEN (IF settled14.orderModifiedReturnBitfield15 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.orderModifiedReturnBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.orderModifiedReturnBitfield16 = IF settled15.numberOfReturnBitfields >= 16 THEN (IF settled15.orderModifiedReturnBitfield16 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled15.orderModifiedReturnBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.orderModifiedReturnBitfield17 = IF settled16.numberOfReturnBitfields >= 17 THEN (IF settled16.orderModifiedReturnBitfield17 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled16.orderModifiedReturnBitfield17) ELSE << >>]
        settled18 == [settled17 EXCEPT !.orderModifiedReturnBitfield18 = IF settled17.numberOfReturnBitfields >= 18 THEN (IF settled17.orderModifiedReturnBitfield18 = << >> THEN <<0>> ELSE settled17.orderModifiedReturnBitfield18) ELSE << >>]
        settled19 == [settled18 EXCEPT !.orderModifiedReturnBitfield19 = IF settled18.numberOfReturnBitfields >= 19 THEN (IF settled18.orderModifiedReturnBitfield19 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled18.orderModifiedReturnBitfield19) ELSE << >>]
        settled20 == [settled19 EXCEPT !.orderModifiedReturnBitfield20 = IF settled19.numberOfReturnBitfields >= 20 THEN (IF settled19.orderModifiedReturnBitfield20 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled19.orderModifiedReturnBitfield20) ELSE << >>]
        settled21 == [settled20 EXCEPT !.orderModifiedReturnBitfield21 = IF settled20.numberOfReturnBitfields >= 21 THEN (IF settled20.orderModifiedReturnBitfield21 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled20.orderModifiedReturnBitfield21) ELSE << >>]
        settled22 == [settled21 EXCEPT !.orderModifiedReturnBitfield22 = IF settled21.numberOfReturnBitfields >= 22 THEN (IF settled21.orderModifiedReturnBitfield22 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled21.orderModifiedReturnBitfield22) ELSE << >>]
        settled23 == [settled22 EXCEPT !.side = IF settled22.numberOfReturnBitfields >= 1 /\ (settled22.orderModifiedReturnBitfield1 # << >> /\ settled22.orderModifiedReturnBitfield1[1] % 2 > 0) THEN (IF settled22.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled22.side) ELSE << >>]
        settled24 == [settled23 EXCEPT !.pegDifference = IF settled23.numberOfReturnBitfields >= 1 /\ (settled23.orderModifiedReturnBitfield1 # << >> /\ (settled23.orderModifiedReturnBitfield1[1] \div 2) % 2 > 0) THEN (IF settled23.pegDifference = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled23.pegDifference) ELSE << >>]
        settled25 == [settled24 EXCEPT !.price = IF settled24.numberOfReturnBitfields >= 1 /\ (settled24.orderModifiedReturnBitfield1 # << >> /\ (settled24.orderModifiedReturnBitfield1[1] \div 4) % 2 > 0) THEN (IF settled24.price = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled24.price) ELSE << >>]
        settled26 == [settled25 EXCEPT !.execInst = IF settled25.numberOfReturnBitfields >= 1 /\ (settled25.orderModifiedReturnBitfield1 # << >> /\ (settled25.orderModifiedReturnBitfield1[1] \div 8) % 2 > 0) THEN (IF settled25.execInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled25.execInst) ELSE << >>]
        settled27 == [settled26 EXCEPT !.ordType = IF settled26.numberOfReturnBitfields >= 1 /\ (settled26.orderModifiedReturnBitfield1 # << >> /\ (settled26.orderModifiedReturnBitfield1[1] \div 16) % 2 > 0) THEN (IF settled26.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled26.ordType) ELSE << >>]
        settled28 == [settled27 EXCEPT !.timeInForce = IF settled27.numberOfReturnBitfields >= 1 /\ (settled27.orderModifiedReturnBitfield1 # << >> /\ (settled27.orderModifiedReturnBitfield1[1] \div 32) % 2 > 0) THEN (IF settled27.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled27.timeInForce) ELSE << >>]
        settled29 == [settled28 EXCEPT !.minQty = IF settled28.numberOfReturnBitfields >= 1 /\ (settled28.orderModifiedReturnBitfield1 # << >> /\ (settled28.orderModifiedReturnBitfield1[1] \div 64) % 2 > 0) THEN (IF settled28.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled28.minQty) ELSE << >>]
        settled30 == [settled29 EXCEPT !.symbol = IF settled29.numberOfReturnBitfields >= 2 /\ (settled29.orderModifiedReturnBitfield2 # << >> /\ settled29.orderModifiedReturnBitfield2[1] % 2 > 0) THEN (IF settled29.symbol = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled29.symbol) ELSE << >>]
        settled31 == [settled30 EXCEPT !.symbolSfx = IF settled30.numberOfReturnBitfields >= 2 /\ (settled30.orderModifiedReturnBitfield2 # << >> /\ (settled30.orderModifiedReturnBitfield2[1] \div 2) % 2 > 0) THEN (IF settled30.symbolSfx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled30.symbolSfx) ELSE << >>]
        settled32 == [settled31 EXCEPT !.account = IF settled31.numberOfReturnBitfields >= 3 /\ (settled31.orderModifiedReturnBitfield3 # << >> /\ settled31.orderModifiedReturnBitfield3[1] % 2 > 0) THEN (IF settled31.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled31.account) ELSE << >>]
        settled33 == [settled32 EXCEPT !.clearingFirm = IF settled32.numberOfReturnBitfields >= 3 /\ (settled32.orderModifiedReturnBitfield3 # << >> /\ (settled32.orderModifiedReturnBitfield3[1] \div 2) % 2 > 0) THEN (IF settled32.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled32.clearingFirm) ELSE << >>]
        settled34 == [settled33 EXCEPT !.clearingAccount = IF settled33.numberOfReturnBitfields >= 3 /\ (settled33.orderModifiedReturnBitfield3 # << >> /\ (settled33.orderModifiedReturnBitfield3[1] \div 4) % 2 > 0) THEN (IF settled33.clearingAccount = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled33.clearingAccount) ELSE << >>]
        settled35 == [settled34 EXCEPT !.displayIndicator = IF settled34.numberOfReturnBitfields >= 3 /\ (settled34.orderModifiedReturnBitfield3 # << >> /\ (settled34.orderModifiedReturnBitfield3[1] \div 8) % 2 > 0) THEN (IF settled34.displayIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled34.displayIndicator) ELSE << >>]
        settled36 == [settled35 EXCEPT !.maxFloor = IF settled35.numberOfReturnBitfields >= 3 /\ (settled35.orderModifiedReturnBitfield3 # << >> /\ (settled35.orderModifiedReturnBitfield3[1] \div 16) % 2 > 0) THEN (IF settled35.maxFloor = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled35.maxFloor) ELSE << >>]
        settled37 == [settled36 EXCEPT !.discretionAmount = IF settled36.numberOfReturnBitfields >= 3 /\ (settled36.orderModifiedReturnBitfield3 # << >> /\ (settled36.orderModifiedReturnBitfield3[1] \div 32) % 2 > 0) THEN (IF settled36.discretionAmount = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled36.discretionAmount) ELSE << >>]
        settled38 == [settled37 EXCEPT !.orderQty = IF settled37.numberOfReturnBitfields >= 3 /\ (settled37.orderModifiedReturnBitfield3 # << >> /\ (settled37.orderModifiedReturnBitfield3[1] \div 64) % 2 > 0) THEN (IF settled37.orderQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled37.orderQty) ELSE << >>]
        settled39 == [settled38 EXCEPT !.preventMatch = IF settled38.numberOfReturnBitfields >= 3 /\ (settled38.orderModifiedReturnBitfield3 # << >> /\ (settled38.orderModifiedReturnBitfield3[1] \div 128) % 2 > 0) THEN (IF settled38.preventMatch = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled38.preventMatch) ELSE << >>]
        settled40 == [settled39 EXCEPT !.origClOrdId = IF settled39.numberOfReturnBitfields >= 5 /\ (settled39.orderModifiedReturnBitfield5 # << >> /\ settled39.orderModifiedReturnBitfield5[1] % 2 > 0) THEN (IF settled39.origClOrdId = << >> THEN <<[i \in 1 .. 20 |-> 0]>> ELSE settled39.origClOrdId) ELSE << >>]
        settled41 == [settled40 EXCEPT !.leavesQty = IF settled40.numberOfReturnBitfields >= 5 /\ (settled40.orderModifiedReturnBitfield5 # << >> /\ (settled40.orderModifiedReturnBitfield5[1] \div 2) % 2 > 0) THEN (IF settled40.leavesQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled40.leavesQty) ELSE << >>]
        settled42 == [settled41 EXCEPT !.lastShares = IF settled41.numberOfReturnBitfields >= 5 /\ (settled41.orderModifiedReturnBitfield5 # << >> /\ (settled41.orderModifiedReturnBitfield5[1] \div 4) % 2 > 0) THEN (IF settled41.lastShares = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled41.lastShares) ELSE << >>]
        settled43 == [settled42 EXCEPT !.lastPx = IF settled42.numberOfReturnBitfields >= 5 /\ (settled42.orderModifiedReturnBitfield5 # << >> /\ (settled42.orderModifiedReturnBitfield5[1] \div 8) % 2 > 0) THEN (IF settled42.lastPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled42.lastPx) ELSE << >>]
        settled44 == [settled43 EXCEPT !.displayPrice = IF settled43.numberOfReturnBitfields >= 5 /\ (settled43.orderModifiedReturnBitfield5 # << >> /\ (settled43.orderModifiedReturnBitfield5[1] \div 16) % 2 > 0) THEN (IF settled43.displayPrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled43.displayPrice) ELSE << >>]
        settled45 == [settled44 EXCEPT !.workingPrice = IF settled44.numberOfReturnBitfields >= 5 /\ (settled44.orderModifiedReturnBitfield5 # << >> /\ (settled44.orderModifiedReturnBitfield5[1] \div 32) % 2 > 0) THEN (IF settled44.workingPrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled44.workingPrice) ELSE << >>]
        settled46 == [settled45 EXCEPT !.baseLiquidityIndicator = IF settled45.numberOfReturnBitfields >= 5 /\ (settled45.orderModifiedReturnBitfield5 # << >> /\ (settled45.orderModifiedReturnBitfield5[1] \div 64) % 2 > 0) THEN (IF settled45.baseLiquidityIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled45.baseLiquidityIndicator) ELSE << >>]
        settled47 == [settled46 EXCEPT !.expireTime = IF settled46.numberOfReturnBitfields >= 5 /\ (settled46.orderModifiedReturnBitfield5 # << >> /\ (settled46.orderModifiedReturnBitfield5[1] \div 128) % 2 > 0) THEN (IF settled46.expireTime = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled46.expireTime) ELSE << >>]
        settled48 == [settled47 EXCEPT !.secondaryOrderId = IF settled47.numberOfReturnBitfields >= 6 /\ (settled47.orderModifiedReturnBitfield6 # << >> /\ settled47.orderModifiedReturnBitfield6[1] % 2 > 0) THEN (IF settled47.secondaryOrderId = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled47.secondaryOrderId) ELSE << >>]
        settled49 == [settled48 EXCEPT !.attributedQuote = IF settled48.numberOfReturnBitfields >= 6 /\ (settled48.orderModifiedReturnBitfield6 # << >> /\ (settled48.orderModifiedReturnBitfield6[1] \div 8) % 2 > 0) THEN (IF settled48.attributedQuote = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled48.attributedQuote) ELSE << >>]
        settled50 == [settled49 EXCEPT !.extExecInst = IF settled49.numberOfReturnBitfields >= 6 /\ (settled49.orderModifiedReturnBitfield6 # << >> /\ (settled49.orderModifiedReturnBitfield6[1] \div 16) % 2 > 0) THEN (IF settled49.extExecInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled49.extExecInst) ELSE << >>]
        settled51 == [settled50 EXCEPT !.echoText = IF settled50.numberOfReturnBitfields >= 8 /\ (settled50.orderModifiedReturnBitfield8 # << >> /\ (settled50.orderModifiedReturnBitfield8[1] \div 2) % 2 > 0) THEN (IF settled50.echoText = << >> THEN <<[i \in 1 .. 64 |-> 0]>> ELSE settled50.echoText) ELSE << >>]
        settled52 == [settled51 EXCEPT !.stopPx = IF settled51.numberOfReturnBitfields >= 8 /\ (settled51.orderModifiedReturnBitfield8 # << >> /\ (settled51.orderModifiedReturnBitfield8[1] \div 4) % 2 > 0) THEN (IF settled51.stopPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled51.stopPx) ELSE << >>]
        settled53 == [settled52 EXCEPT !.routingInst = IF settled52.numberOfReturnBitfields >= 8 /\ (settled52.orderModifiedReturnBitfield8 # << >> /\ (settled52.orderModifiedReturnBitfield8[1] \div 8) % 2 > 0) THEN (IF settled52.routingInst = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled52.routingInst) ELSE << >>]
        settled54 == [settled53 EXCEPT !.routStrategy = IF settled53.numberOfReturnBitfields >= 8 /\ (settled53.orderModifiedReturnBitfield8 # << >> /\ (settled53.orderModifiedReturnBitfield8[1] \div 16) % 2 > 0) THEN (IF settled53.routStrategy = << >> THEN <<[i \in 1 .. 6 |-> 0]>> ELSE settled53.routStrategy) ELSE << >>]
        settled55 == [settled54 EXCEPT !.routeDeliveryMethod = IF settled54.numberOfReturnBitfields >= 8 /\ (settled54.orderModifiedReturnBitfield8 # << >> /\ (settled54.orderModifiedReturnBitfield8[1] \div 32) % 2 > 0) THEN (IF settled54.routeDeliveryMethod = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled54.routeDeliveryMethod) ELSE << >>]
        settled56 == [settled55 EXCEPT !.exDestination = IF settled55.numberOfReturnBitfields >= 8 /\ (settled55.orderModifiedReturnBitfield8 # << >> /\ (settled55.orderModifiedReturnBitfield8[1] \div 64) % 2 > 0) THEN (IF settled55.exDestination = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled55.exDestination) ELSE << >>]
        settled57 == [settled56 EXCEPT !.crossTradeFlag = IF settled56.numberOfReturnBitfields >= 18 /\ (settled56.orderModifiedReturnBitfield18 # << >> /\ (settled56.orderModifiedReturnBitfield18[1] \div 8) % 2 > 0) THEN (IF settled56.crossTradeFlag = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled56.crossTradeFlag) ELSE << >>]
        settled58 == [settled57 EXCEPT !.locateBroker = IF settled57.numberOfReturnBitfields >= 18 /\ (settled57.orderModifiedReturnBitfield18 # << >> /\ (settled57.orderModifiedReturnBitfield18[1] \div 64) % 2 > 0) THEN (IF settled57.locateBroker = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled57.locateBroker) ELSE << >>]
    IN  settled58

ZeroOrderModifiedMessage ==
    SettleOrderModifiedMessage([ transactionTime               |-> [i \in 1 .. 8 |-> 0],
                                 clOrdId                       |-> [i \in 1 .. 20 |-> 0],
                                 orderId                       |-> [i \in 1 .. 8 |-> 0],
                                 reserved1                     |-> [i \in 1 .. 1 |-> 0],
                                 numberOfReturnBitfields       |-> 0,
                                 orderModifiedReturnBitfield1  |-> << >>,
                                 orderModifiedReturnBitfield2  |-> << >>,
                                 orderModifiedReturnBitfield3  |-> << >>,
                                 orderModifiedReturnBitfield4  |-> << >>,
                                 orderModifiedReturnBitfield5  |-> << >>,
                                 orderModifiedReturnBitfield6  |-> << >>,
                                 orderModifiedReturnBitfield7  |-> << >>,
                                 orderModifiedReturnBitfield8  |-> << >>,
                                 orderModifiedReturnBitfield9  |-> << >>,
                                 orderModifiedReturnBitfield10 |-> << >>,
                                 orderModifiedReturnBitfield11 |-> << >>,
                                 orderModifiedReturnBitfield12 |-> << >>,
                                 orderModifiedReturnBitfield13 |-> << >>,
                                 orderModifiedReturnBitfield14 |-> << >>,
                                 orderModifiedReturnBitfield15 |-> << >>,
                                 orderModifiedReturnBitfield16 |-> << >>,
                                 orderModifiedReturnBitfield17 |-> << >>,
                                 orderModifiedReturnBitfield18 |-> << >>,
                                 orderModifiedReturnBitfield19 |-> << >>,
                                 orderModifiedReturnBitfield20 |-> << >>,
                                 orderModifiedReturnBitfield21 |-> << >>,
                                 orderModifiedReturnBitfield22 |-> << >>,
                                 side                          |-> << >>,
                                 pegDifference                 |-> << >>,
                                 price                         |-> << >>,
                                 execInst                      |-> << >>,
                                 ordType                       |-> << >>,
                                 timeInForce                   |-> << >>,
                                 minQty                        |-> << >>,
                                 symbol                        |-> << >>,
                                 symbolSfx                     |-> << >>,
                                 account                       |-> << >>,
                                 clearingFirm                  |-> << >>,
                                 clearingAccount               |-> << >>,
                                 displayIndicator              |-> << >>,
                                 maxFloor                      |-> << >>,
                                 discretionAmount              |-> << >>,
                                 orderQty                      |-> << >>,
                                 preventMatch                  |-> << >>,
                                 origClOrdId                   |-> << >>,
                                 leavesQty                     |-> << >>,
                                 lastShares                    |-> << >>,
                                 lastPx                        |-> << >>,
                                 displayPrice                  |-> << >>,
                                 workingPrice                  |-> << >>,
                                 baseLiquidityIndicator        |-> << >>,
                                 expireTime                    |-> << >>,
                                 secondaryOrderId              |-> << >>,
                                 attributedQuote               |-> << >>,
                                 extExecInst                   |-> << >>,
                                 echoText                      |-> << >>,
                                 stopPx                        |-> << >>,
                                 routingInst                   |-> << >>,
                                 routStrategy                  |-> << >>,
                                 routeDeliveryMethod           |-> << >>,
                                 exDestination                 |-> << >>,
                                 crossTradeFlag                |-> << >>,
                                 locateBroker                  |-> << >> ])

(* Order Modified Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderModifiedMessage ==
    { ZeroOrderModifiedMessage }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.transactionTime = one]) : one \in Sample(8) }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.clOrdId = one]) : one \in Sample(20) }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.orderId = one]) : one \in Sample(8) }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.reserved1 = one]) : one \in Sample(1) }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderModifiedReturnBitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 2, !.orderModifiedReturnBitfield2 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderModifiedReturnBitfield3 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 4, !.orderModifiedReturnBitfield4 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderModifiedReturnBitfield5 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 6, !.orderModifiedReturnBitfield6 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 7, !.orderModifiedReturnBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderModifiedReturnBitfield8 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 9, !.orderModifiedReturnBitfield9 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 10, !.orderModifiedReturnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 11, !.orderModifiedReturnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 12, !.orderModifiedReturnBitfield12 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 13, !.orderModifiedReturnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 14, !.orderModifiedReturnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 15, !.orderModifiedReturnBitfield15 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 16, !.orderModifiedReturnBitfield16 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 17, !.orderModifiedReturnBitfield17 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 18, !.orderModifiedReturnBitfield18 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 19, !.orderModifiedReturnBitfield19 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 20, !.orderModifiedReturnBitfield20 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 21, !.orderModifiedReturnBitfield21 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 22, !.orderModifiedReturnBitfield22 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderModifiedReturnBitfield1 = <<1>>, !.side = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderModifiedReturnBitfield1 = <<2>>, !.pegDifference = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderModifiedReturnBitfield1 = <<4>>, !.price = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderModifiedReturnBitfield1 = <<8>>, !.execInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderModifiedReturnBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderModifiedReturnBitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderModifiedReturnBitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 2, !.orderModifiedReturnBitfield2 = <<1>>, !.symbol = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 2, !.orderModifiedReturnBitfield2 = <<2>>, !.symbolSfx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderModifiedReturnBitfield3 = <<1>>, !.account = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderModifiedReturnBitfield3 = <<2>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderModifiedReturnBitfield3 = <<4>>, !.clearingAccount = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderModifiedReturnBitfield3 = <<8>>, !.displayIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderModifiedReturnBitfield3 = <<16>>, !.maxFloor = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderModifiedReturnBitfield3 = <<32>>, !.discretionAmount = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderModifiedReturnBitfield3 = <<64>>, !.orderQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderModifiedReturnBitfield3 = <<128>>, !.preventMatch = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderModifiedReturnBitfield5 = <<1>>, !.origClOrdId = one]) : one \in { <<held>> : held \in Sample(20) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderModifiedReturnBitfield5 = <<2>>, !.leavesQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderModifiedReturnBitfield5 = <<4>>, !.lastShares = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderModifiedReturnBitfield5 = <<8>>, !.lastPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderModifiedReturnBitfield5 = <<16>>, !.displayPrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderModifiedReturnBitfield5 = <<32>>, !.workingPrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderModifiedReturnBitfield5 = <<64>>, !.baseLiquidityIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderModifiedReturnBitfield5 = <<128>>, !.expireTime = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 6, !.orderModifiedReturnBitfield6 = <<1>>, !.secondaryOrderId = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 6, !.orderModifiedReturnBitfield6 = <<8>>, !.attributedQuote = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 6, !.orderModifiedReturnBitfield6 = <<16>>, !.extExecInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderModifiedReturnBitfield8 = <<2>>, !.echoText = one]) : one \in { <<held>> : held \in Sample(64) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderModifiedReturnBitfield8 = <<4>>, !.stopPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderModifiedReturnBitfield8 = <<8>>, !.routingInst = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderModifiedReturnBitfield8 = <<16>>, !.routStrategy = one]) : one \in { <<held>> : held \in Sample(6) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderModifiedReturnBitfield8 = <<32>>, !.routeDeliveryMethod = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderModifiedReturnBitfield8 = <<64>>, !.exDestination = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 18, !.orderModifiedReturnBitfield18 = <<8>>, !.crossTradeFlag = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 18, !.orderModifiedReturnBitfield18 = <<64>>, !.locateBroker = one]) : one \in { <<held>> : held \in Sample(4) } }

(***************************************************************************)
(* Order Restated Message                                                  *)
(***************************************************************************)

OrderRestatedMessage ==
    [ transactionTime               : Sample(8),
      clOrdId                       : Sample(20),
      orderId                       : Sample(8),
      restatementReason             : Sample(1),
      reserved1                     : Sample(1),
      numberOfReturnBitfields       : 0 .. 255,
      orderRestatedReturnBitfield1  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderRestatedReturnBitfield2  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderRestatedReturnBitfield3  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderRestatedReturnBitfield4  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRestatedReturnBitfield5  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderRestatedReturnBitfield6  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderRestatedReturnBitfield7  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRestatedReturnBitfield8  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderRestatedReturnBitfield9  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRestatedReturnBitfield10 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRestatedReturnBitfield11 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRestatedReturnBitfield12 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRestatedReturnBitfield13 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRestatedReturnBitfield14 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRestatedReturnBitfield15 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRestatedReturnBitfield16 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRestatedReturnBitfield17 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRestatedReturnBitfield18 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRestatedReturnBitfield19 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderRestatedReturnBitfield20 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRestatedReturnBitfield21 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRestatedReturnBitfield22 : { << >> } \cup { <<held>> : held \in Sample(1) },
      side                          : { << >> } \cup { <<held>> : held \in Sample(1) },
      pegDifference                 : { << >> } \cup { <<held>> : held \in Sample(8) },
      price                         : { << >> } \cup { <<held>> : held \in Sample(8) },
      execInst                      : { << >> } \cup { <<held>> : held \in Sample(1) },
      ordType                       : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce                   : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                        : { << >> } \cup { <<held>> : held \in Sample(4) },
      symbol                        : { << >> } \cup { <<held>> : held \in Sample(8) },
      symbolSfx                     : { << >> } \cup { <<held>> : held \in Sample(8) },
      capacity                      : { << >> } \cup { <<held>> : held \in Sample(1) },
      account                       : { << >> } \cup { <<held>> : held \in Sample(16) },
      clearingFirm                  : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingAccount               : { << >> } \cup { <<held>> : held \in Sample(4) },
      displayIndicator              : { << >> } \cup { <<held>> : held \in Sample(1) },
      maxFloor                      : { << >> } \cup { <<held>> : held \in Sample(4) },
      discretionAmount              : { << >> } \cup { <<held>> : held \in Sample(2) },
      orderQty                      : { << >> } \cup { <<held>> : held \in Sample(4) },
      preventMatch                  : { << >> } \cup { <<held>> : held \in Sample(3) },
      origClOrdId                   : { << >> } \cup { <<held>> : held \in Sample(20) },
      leavesQty                     : { << >> } \cup { <<held>> : held \in Sample(4) },
      lastShares                    : { << >> } \cup { <<held>> : held \in Sample(4) },
      lastPx                        : { << >> } \cup { <<held>> : held \in Sample(8) },
      displayPrice                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      workingPrice                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      baseLiquidityIndicator        : { << >> } \cup { <<held>> : held \in Sample(1) },
      expireTime                    : { << >> } \cup { <<held>> : held \in Sample(8) },
      secondaryOrderId              : { << >> } \cup { <<held>> : held \in Sample(8) },
      attributedQuote               : { << >> } \cup { <<held>> : held \in Sample(1) },
      extExecInst                   : { << >> } \cup { <<held>> : held \in Sample(1) },
      echoText                      : { << >> } \cup { <<held>> : held \in Sample(64) },
      stopPx                        : { << >> } \cup { <<held>> : held \in Sample(8) },
      routingInst                   : { << >> } \cup { <<held>> : held \in Sample(4) },
      routStrategy                  : { << >> } \cup { <<held>> : held \in Sample(6) },
      routeDeliveryMethod           : { << >> } \cup { <<held>> : held \in Sample(3) },
      exDestination                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      cmcMatchQty                   : { << >> } \cup { <<held>> : held \in Sample(4) },
      stepUpAmount                  : { << >> } \cup { <<held>> : held \in Sample(8) } ]

EncodeOrderRestatedMessage(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.orderId
        \o message.restatementReason
        \o message.reserved1
        \o EncodeUIntBE(message.numberOfReturnBitfields, 1)
        \o (IF message.orderRestatedReturnBitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.orderRestatedReturnBitfield1[1], 1))
        \o (IF message.orderRestatedReturnBitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.orderRestatedReturnBitfield2[1], 1))
        \o (IF message.orderRestatedReturnBitfield3 = << >> THEN << >> ELSE EncodeUIntLE(message.orderRestatedReturnBitfield3[1], 1))
        \o (IF message.orderRestatedReturnBitfield4 = << >> THEN << >> ELSE message.orderRestatedReturnBitfield4[1])
        \o (IF message.orderRestatedReturnBitfield5 = << >> THEN << >> ELSE EncodeUIntLE(message.orderRestatedReturnBitfield5[1], 1))
        \o (IF message.orderRestatedReturnBitfield6 = << >> THEN << >> ELSE EncodeUIntLE(message.orderRestatedReturnBitfield6[1], 1))
        \o (IF message.orderRestatedReturnBitfield7 = << >> THEN << >> ELSE message.orderRestatedReturnBitfield7[1])
        \o (IF message.orderRestatedReturnBitfield8 = << >> THEN << >> ELSE EncodeUIntLE(message.orderRestatedReturnBitfield8[1], 1))
        \o (IF message.orderRestatedReturnBitfield9 = << >> THEN << >> ELSE message.orderRestatedReturnBitfield9[1])
        \o (IF message.orderRestatedReturnBitfield10 = << >> THEN << >> ELSE message.orderRestatedReturnBitfield10[1])
        \o (IF message.orderRestatedReturnBitfield11 = << >> THEN << >> ELSE message.orderRestatedReturnBitfield11[1])
        \o (IF message.orderRestatedReturnBitfield12 = << >> THEN << >> ELSE message.orderRestatedReturnBitfield12[1])
        \o (IF message.orderRestatedReturnBitfield13 = << >> THEN << >> ELSE message.orderRestatedReturnBitfield13[1])
        \o (IF message.orderRestatedReturnBitfield14 = << >> THEN << >> ELSE message.orderRestatedReturnBitfield14[1])
        \o (IF message.orderRestatedReturnBitfield15 = << >> THEN << >> ELSE message.orderRestatedReturnBitfield15[1])
        \o (IF message.orderRestatedReturnBitfield16 = << >> THEN << >> ELSE message.orderRestatedReturnBitfield16[1])
        \o (IF message.orderRestatedReturnBitfield17 = << >> THEN << >> ELSE message.orderRestatedReturnBitfield17[1])
        \o (IF message.orderRestatedReturnBitfield18 = << >> THEN << >> ELSE message.orderRestatedReturnBitfield18[1])
        \o (IF message.orderRestatedReturnBitfield19 = << >> THEN << >> ELSE EncodeUIntLE(message.orderRestatedReturnBitfield19[1], 1))
        \o (IF message.orderRestatedReturnBitfield20 = << >> THEN << >> ELSE message.orderRestatedReturnBitfield20[1])
        \o (IF message.orderRestatedReturnBitfield21 = << >> THEN << >> ELSE message.orderRestatedReturnBitfield21[1])
        \o (IF message.orderRestatedReturnBitfield22 = << >> THEN << >> ELSE message.orderRestatedReturnBitfield22[1])
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
    LET orderRestatedReturnBitfield1 == ReadWhen(numberOfReturnBitfields.value >= 1, ReadUIntLE(numberOfReturnBitfields.rest, 1), numberOfReturnBitfields.rest) IN IF ~orderRestatedReturnBitfield1.ok THEN Fail ELSE
    LET orderRestatedReturnBitfield2 == ReadWhen(numberOfReturnBitfields.value >= 2, ReadUIntLE(orderRestatedReturnBitfield1.rest, 1), orderRestatedReturnBitfield1.rest) IN IF ~orderRestatedReturnBitfield2.ok THEN Fail ELSE
    LET orderRestatedReturnBitfield3 == ReadWhen(numberOfReturnBitfields.value >= 3, ReadUIntLE(orderRestatedReturnBitfield2.rest, 1), orderRestatedReturnBitfield2.rest) IN IF ~orderRestatedReturnBitfield3.ok THEN Fail ELSE
    LET orderRestatedReturnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadBytes(orderRestatedReturnBitfield3.rest, 1), orderRestatedReturnBitfield3.rest) IN IF ~orderRestatedReturnBitfield4.ok THEN Fail ELSE
    LET orderRestatedReturnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadUIntLE(orderRestatedReturnBitfield4.rest, 1), orderRestatedReturnBitfield4.rest) IN IF ~orderRestatedReturnBitfield5.ok THEN Fail ELSE
    LET orderRestatedReturnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadUIntLE(orderRestatedReturnBitfield5.rest, 1), orderRestatedReturnBitfield5.rest) IN IF ~orderRestatedReturnBitfield6.ok THEN Fail ELSE
    LET orderRestatedReturnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadBytes(orderRestatedReturnBitfield6.rest, 1), orderRestatedReturnBitfield6.rest) IN IF ~orderRestatedReturnBitfield7.ok THEN Fail ELSE
    LET orderRestatedReturnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadUIntLE(orderRestatedReturnBitfield7.rest, 1), orderRestatedReturnBitfield7.rest) IN IF ~orderRestatedReturnBitfield8.ok THEN Fail ELSE
    LET orderRestatedReturnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadBytes(orderRestatedReturnBitfield8.rest, 1), orderRestatedReturnBitfield8.rest) IN IF ~orderRestatedReturnBitfield9.ok THEN Fail ELSE
    LET orderRestatedReturnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadBytes(orderRestatedReturnBitfield9.rest, 1), orderRestatedReturnBitfield9.rest) IN IF ~orderRestatedReturnBitfield10.ok THEN Fail ELSE
    LET orderRestatedReturnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadBytes(orderRestatedReturnBitfield10.rest, 1), orderRestatedReturnBitfield10.rest) IN IF ~orderRestatedReturnBitfield11.ok THEN Fail ELSE
    LET orderRestatedReturnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadBytes(orderRestatedReturnBitfield11.rest, 1), orderRestatedReturnBitfield11.rest) IN IF ~orderRestatedReturnBitfield12.ok THEN Fail ELSE
    LET orderRestatedReturnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(orderRestatedReturnBitfield12.rest, 1), orderRestatedReturnBitfield12.rest) IN IF ~orderRestatedReturnBitfield13.ok THEN Fail ELSE
    LET orderRestatedReturnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(orderRestatedReturnBitfield13.rest, 1), orderRestatedReturnBitfield13.rest) IN IF ~orderRestatedReturnBitfield14.ok THEN Fail ELSE
    LET orderRestatedReturnBitfield15 == ReadWhen(numberOfReturnBitfields.value >= 15, ReadBytes(orderRestatedReturnBitfield14.rest, 1), orderRestatedReturnBitfield14.rest) IN IF ~orderRestatedReturnBitfield15.ok THEN Fail ELSE
    LET orderRestatedReturnBitfield16 == ReadWhen(numberOfReturnBitfields.value >= 16, ReadBytes(orderRestatedReturnBitfield15.rest, 1), orderRestatedReturnBitfield15.rest) IN IF ~orderRestatedReturnBitfield16.ok THEN Fail ELSE
    LET orderRestatedReturnBitfield17 == ReadWhen(numberOfReturnBitfields.value >= 17, ReadBytes(orderRestatedReturnBitfield16.rest, 1), orderRestatedReturnBitfield16.rest) IN IF ~orderRestatedReturnBitfield17.ok THEN Fail ELSE
    LET orderRestatedReturnBitfield18 == ReadWhen(numberOfReturnBitfields.value >= 18, ReadBytes(orderRestatedReturnBitfield17.rest, 1), orderRestatedReturnBitfield17.rest) IN IF ~orderRestatedReturnBitfield18.ok THEN Fail ELSE
    LET orderRestatedReturnBitfield19 == ReadWhen(numberOfReturnBitfields.value >= 19, ReadUIntLE(orderRestatedReturnBitfield18.rest, 1), orderRestatedReturnBitfield18.rest) IN IF ~orderRestatedReturnBitfield19.ok THEN Fail ELSE
    LET orderRestatedReturnBitfield20 == ReadWhen(numberOfReturnBitfields.value >= 20, ReadBytes(orderRestatedReturnBitfield19.rest, 1), orderRestatedReturnBitfield19.rest) IN IF ~orderRestatedReturnBitfield20.ok THEN Fail ELSE
    LET orderRestatedReturnBitfield21 == ReadWhen(numberOfReturnBitfields.value >= 21, ReadBytes(orderRestatedReturnBitfield20.rest, 1), orderRestatedReturnBitfield20.rest) IN IF ~orderRestatedReturnBitfield21.ok THEN Fail ELSE
    LET orderRestatedReturnBitfield22 == ReadWhen(numberOfReturnBitfields.value >= 22, ReadBytes(orderRestatedReturnBitfield21.rest, 1), orderRestatedReturnBitfield21.rest) IN IF ~orderRestatedReturnBitfield22.ok THEN Fail ELSE
    LET side == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderRestatedReturnBitfield1.value # << >> /\ orderRestatedReturnBitfield1.value[1] % 2 > 0), ReadBytes(orderRestatedReturnBitfield22.rest, 1), orderRestatedReturnBitfield22.rest) IN IF ~side.ok THEN Fail ELSE
    LET pegDifference == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderRestatedReturnBitfield1.value # << >> /\ (orderRestatedReturnBitfield1.value[1] \div 2) % 2 > 0), ReadBytes(side.rest, 8), side.rest) IN IF ~pegDifference.ok THEN Fail ELSE
    LET price == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderRestatedReturnBitfield1.value # << >> /\ (orderRestatedReturnBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(pegDifference.rest, 8), pegDifference.rest) IN IF ~price.ok THEN Fail ELSE
    LET execInst == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderRestatedReturnBitfield1.value # << >> /\ (orderRestatedReturnBitfield1.value[1] \div 8) % 2 > 0), ReadBytes(price.rest, 1), price.rest) IN IF ~execInst.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderRestatedReturnBitfield1.value # << >> /\ (orderRestatedReturnBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(execInst.rest, 1), execInst.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderRestatedReturnBitfield1.value # << >> /\ (orderRestatedReturnBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderRestatedReturnBitfield1.value # << >> /\ (orderRestatedReturnBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET symbol == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderRestatedReturnBitfield2.value # << >> /\ orderRestatedReturnBitfield2.value[1] % 2 > 0), ReadBytes(minQty.rest, 8), minQty.rest) IN IF ~symbol.ok THEN Fail ELSE
    LET symbolSfx == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderRestatedReturnBitfield2.value # << >> /\ (orderRestatedReturnBitfield2.value[1] \div 2) % 2 > 0), ReadBytes(symbol.rest, 8), symbol.rest) IN IF ~symbolSfx.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderRestatedReturnBitfield2.value # << >> /\ (orderRestatedReturnBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(symbolSfx.rest, 1), symbolSfx.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderRestatedReturnBitfield3.value # << >> /\ orderRestatedReturnBitfield3.value[1] % 2 > 0), ReadBytes(capacity.rest, 16), capacity.rest) IN IF ~account.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderRestatedReturnBitfield3.value # << >> /\ (orderRestatedReturnBitfield3.value[1] \div 2) % 2 > 0), ReadBytes(account.rest, 4), account.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderRestatedReturnBitfield3.value # << >> /\ (orderRestatedReturnBitfield3.value[1] \div 4) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET displayIndicator == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderRestatedReturnBitfield3.value # << >> /\ (orderRestatedReturnBitfield3.value[1] \div 8) % 2 > 0), ReadBytes(clearingAccount.rest, 1), clearingAccount.rest) IN IF ~displayIndicator.ok THEN Fail ELSE
    LET maxFloor == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderRestatedReturnBitfield3.value # << >> /\ (orderRestatedReturnBitfield3.value[1] \div 16) % 2 > 0), ReadBytes(displayIndicator.rest, 4), displayIndicator.rest) IN IF ~maxFloor.ok THEN Fail ELSE
    LET discretionAmount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderRestatedReturnBitfield3.value # << >> /\ (orderRestatedReturnBitfield3.value[1] \div 32) % 2 > 0), ReadBytes(maxFloor.rest, 2), maxFloor.rest) IN IF ~discretionAmount.ok THEN Fail ELSE
    LET orderQty == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderRestatedReturnBitfield3.value # << >> /\ (orderRestatedReturnBitfield3.value[1] \div 64) % 2 > 0), ReadBytes(discretionAmount.rest, 4), discretionAmount.rest) IN IF ~orderQty.ok THEN Fail ELSE
    LET preventMatch == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderRestatedReturnBitfield3.value # << >> /\ (orderRestatedReturnBitfield3.value[1] \div 128) % 2 > 0), ReadBytes(orderQty.rest, 3), orderQty.rest) IN IF ~preventMatch.ok THEN Fail ELSE
    LET origClOrdId == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderRestatedReturnBitfield5.value # << >> /\ orderRestatedReturnBitfield5.value[1] % 2 > 0), ReadBytes(preventMatch.rest, 20), preventMatch.rest) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET leavesQty == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderRestatedReturnBitfield5.value # << >> /\ (orderRestatedReturnBitfield5.value[1] \div 2) % 2 > 0), ReadBytes(origClOrdId.rest, 4), origClOrdId.rest) IN IF ~leavesQty.ok THEN Fail ELSE
    LET lastShares == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderRestatedReturnBitfield5.value # << >> /\ (orderRestatedReturnBitfield5.value[1] \div 4) % 2 > 0), ReadBytes(leavesQty.rest, 4), leavesQty.rest) IN IF ~lastShares.ok THEN Fail ELSE
    LET lastPx == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderRestatedReturnBitfield5.value # << >> /\ (orderRestatedReturnBitfield5.value[1] \div 8) % 2 > 0), ReadBytes(lastShares.rest, 8), lastShares.rest) IN IF ~lastPx.ok THEN Fail ELSE
    LET displayPrice == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderRestatedReturnBitfield5.value # << >> /\ (orderRestatedReturnBitfield5.value[1] \div 16) % 2 > 0), ReadBytes(lastPx.rest, 8), lastPx.rest) IN IF ~displayPrice.ok THEN Fail ELSE
    LET workingPrice == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderRestatedReturnBitfield5.value # << >> /\ (orderRestatedReturnBitfield5.value[1] \div 32) % 2 > 0), ReadBytes(displayPrice.rest, 8), displayPrice.rest) IN IF ~workingPrice.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderRestatedReturnBitfield5.value # << >> /\ (orderRestatedReturnBitfield5.value[1] \div 64) % 2 > 0), ReadBytes(workingPrice.rest, 1), workingPrice.rest) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET expireTime == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderRestatedReturnBitfield5.value # << >> /\ (orderRestatedReturnBitfield5.value[1] \div 128) % 2 > 0), ReadBytes(baseLiquidityIndicator.rest, 8), baseLiquidityIndicator.rest) IN IF ~expireTime.ok THEN Fail ELSE
    LET secondaryOrderId == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (orderRestatedReturnBitfield6.value # << >> /\ orderRestatedReturnBitfield6.value[1] % 2 > 0), ReadBytes(expireTime.rest, 8), expireTime.rest) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET attributedQuote == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (orderRestatedReturnBitfield6.value # << >> /\ (orderRestatedReturnBitfield6.value[1] \div 8) % 2 > 0), ReadBytes(secondaryOrderId.rest, 1), secondaryOrderId.rest) IN IF ~attributedQuote.ok THEN Fail ELSE
    LET extExecInst == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (orderRestatedReturnBitfield6.value # << >> /\ (orderRestatedReturnBitfield6.value[1] \div 16) % 2 > 0), ReadBytes(attributedQuote.rest, 1), attributedQuote.rest) IN IF ~extExecInst.ok THEN Fail ELSE
    LET echoText == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderRestatedReturnBitfield8.value # << >> /\ (orderRestatedReturnBitfield8.value[1] \div 2) % 2 > 0), ReadBytes(extExecInst.rest, 64), extExecInst.rest) IN IF ~echoText.ok THEN Fail ELSE
    LET stopPx == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderRestatedReturnBitfield8.value # << >> /\ (orderRestatedReturnBitfield8.value[1] \div 4) % 2 > 0), ReadBytes(echoText.rest, 8), echoText.rest) IN IF ~stopPx.ok THEN Fail ELSE
    LET routingInst == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderRestatedReturnBitfield8.value # << >> /\ (orderRestatedReturnBitfield8.value[1] \div 8) % 2 > 0), ReadBytes(stopPx.rest, 4), stopPx.rest) IN IF ~routingInst.ok THEN Fail ELSE
    LET routStrategy == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderRestatedReturnBitfield8.value # << >> /\ (orderRestatedReturnBitfield8.value[1] \div 16) % 2 > 0), ReadBytes(routingInst.rest, 6), routingInst.rest) IN IF ~routStrategy.ok THEN Fail ELSE
    LET routeDeliveryMethod == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderRestatedReturnBitfield8.value # << >> /\ (orderRestatedReturnBitfield8.value[1] \div 32) % 2 > 0), ReadBytes(routStrategy.rest, 3), routStrategy.rest) IN IF ~routeDeliveryMethod.ok THEN Fail ELSE
    LET exDestination == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderRestatedReturnBitfield8.value # << >> /\ (orderRestatedReturnBitfield8.value[1] \div 64) % 2 > 0), ReadBytes(routeDeliveryMethod.rest, 1), routeDeliveryMethod.rest) IN IF ~exDestination.ok THEN Fail ELSE
    LET cmcMatchQty == ReadWhen(numberOfReturnBitfields.value >= 19 /\ (orderRestatedReturnBitfield19.value # << >> /\ (orderRestatedReturnBitfield19.value[1] \div 32) % 2 > 0), ReadBytes(exDestination.rest, 4), exDestination.rest) IN IF ~cmcMatchQty.ok THEN Fail ELSE
    LET stepUpAmount == ReadWhen(numberOfReturnBitfields.value >= 19 /\ (orderRestatedReturnBitfield19.value # << >> /\ (orderRestatedReturnBitfield19.value[1] \div 64) % 2 > 0), ReadBytes(cmcMatchQty.rest, 8), cmcMatchQty.rest) IN IF ~stepUpAmount.ok THEN Fail ELSE
    Ok([ transactionTime               |-> transactionTime.value,
         clOrdId                       |-> clOrdId.value,
         orderId                       |-> orderId.value,
         restatementReason             |-> restatementReason.value,
         reserved1                     |-> reserved1.value,
         numberOfReturnBitfields       |-> numberOfReturnBitfields.value,
         orderRestatedReturnBitfield1  |-> orderRestatedReturnBitfield1.value,
         orderRestatedReturnBitfield2  |-> orderRestatedReturnBitfield2.value,
         orderRestatedReturnBitfield3  |-> orderRestatedReturnBitfield3.value,
         orderRestatedReturnBitfield4  |-> orderRestatedReturnBitfield4.value,
         orderRestatedReturnBitfield5  |-> orderRestatedReturnBitfield5.value,
         orderRestatedReturnBitfield6  |-> orderRestatedReturnBitfield6.value,
         orderRestatedReturnBitfield7  |-> orderRestatedReturnBitfield7.value,
         orderRestatedReturnBitfield8  |-> orderRestatedReturnBitfield8.value,
         orderRestatedReturnBitfield9  |-> orderRestatedReturnBitfield9.value,
         orderRestatedReturnBitfield10 |-> orderRestatedReturnBitfield10.value,
         orderRestatedReturnBitfield11 |-> orderRestatedReturnBitfield11.value,
         orderRestatedReturnBitfield12 |-> orderRestatedReturnBitfield12.value,
         orderRestatedReturnBitfield13 |-> orderRestatedReturnBitfield13.value,
         orderRestatedReturnBitfield14 |-> orderRestatedReturnBitfield14.value,
         orderRestatedReturnBitfield15 |-> orderRestatedReturnBitfield15.value,
         orderRestatedReturnBitfield16 |-> orderRestatedReturnBitfield16.value,
         orderRestatedReturnBitfield17 |-> orderRestatedReturnBitfield17.value,
         orderRestatedReturnBitfield18 |-> orderRestatedReturnBitfield18.value,
         orderRestatedReturnBitfield19 |-> orderRestatedReturnBitfield19.value,
         orderRestatedReturnBitfield20 |-> orderRestatedReturnBitfield20.value,
         orderRestatedReturnBitfield21 |-> orderRestatedReturnBitfield21.value,
         orderRestatedReturnBitfield22 |-> orderRestatedReturnBitfield22.value,
         side                          |-> side.value,
         pegDifference                 |-> pegDifference.value,
         price                         |-> price.value,
         execInst                      |-> execInst.value,
         ordType                       |-> ordType.value,
         timeInForce                   |-> timeInForce.value,
         minQty                        |-> minQty.value,
         symbol                        |-> symbol.value,
         symbolSfx                     |-> symbolSfx.value,
         capacity                      |-> capacity.value,
         account                       |-> account.value,
         clearingFirm                  |-> clearingFirm.value,
         clearingAccount               |-> clearingAccount.value,
         displayIndicator              |-> displayIndicator.value,
         maxFloor                      |-> maxFloor.value,
         discretionAmount              |-> discretionAmount.value,
         orderQty                      |-> orderQty.value,
         preventMatch                  |-> preventMatch.value,
         origClOrdId                   |-> origClOrdId.value,
         leavesQty                     |-> leavesQty.value,
         lastShares                    |-> lastShares.value,
         lastPx                        |-> lastPx.value,
         displayPrice                  |-> displayPrice.value,
         workingPrice                  |-> workingPrice.value,
         baseLiquidityIndicator        |-> baseLiquidityIndicator.value,
         expireTime                    |-> expireTime.value,
         secondaryOrderId              |-> secondaryOrderId.value,
         attributedQuote               |-> attributedQuote.value,
         extExecInst                   |-> extExecInst.value,
         echoText                      |-> echoText.value,
         stopPx                        |-> stopPx.value,
         routingInst                   |-> routingInst.value,
         routStrategy                  |-> routStrategy.value,
         routeDeliveryMethod           |-> routeDeliveryMethod.value,
         exDestination                 |-> exDestination.value,
         cmcMatchQty                   |-> cmcMatchQty.value,
         stepUpAmount                  |-> stepUpAmount.value ], stepUpAmount.rest)

(* Order Restated Message with each field marked present by fields before it there exactly where they say *)
SettleOrderRestatedMessage(message) ==
    LET settled1 == [message EXCEPT !.orderRestatedReturnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.orderRestatedReturnBitfield1 = << >> THEN <<0>> ELSE message.orderRestatedReturnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.orderRestatedReturnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.orderRestatedReturnBitfield2 = << >> THEN <<0>> ELSE settled1.orderRestatedReturnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.orderRestatedReturnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.orderRestatedReturnBitfield3 = << >> THEN <<0>> ELSE settled2.orderRestatedReturnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.orderRestatedReturnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.orderRestatedReturnBitfield4 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled3.orderRestatedReturnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.orderRestatedReturnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.orderRestatedReturnBitfield5 = << >> THEN <<0>> ELSE settled4.orderRestatedReturnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.orderRestatedReturnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.orderRestatedReturnBitfield6 = << >> THEN <<0>> ELSE settled5.orderRestatedReturnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.orderRestatedReturnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.orderRestatedReturnBitfield7 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.orderRestatedReturnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.orderRestatedReturnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.orderRestatedReturnBitfield8 = << >> THEN <<0>> ELSE settled7.orderRestatedReturnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.orderRestatedReturnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.orderRestatedReturnBitfield9 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled8.orderRestatedReturnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.orderRestatedReturnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.orderRestatedReturnBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.orderRestatedReturnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.orderRestatedReturnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.orderRestatedReturnBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.orderRestatedReturnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.orderRestatedReturnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.orderRestatedReturnBitfield12 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.orderRestatedReturnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.orderRestatedReturnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.orderRestatedReturnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.orderRestatedReturnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.orderRestatedReturnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.orderRestatedReturnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.orderRestatedReturnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.orderRestatedReturnBitfield15 = IF settled14.numberOfReturnBitfields >= 15 THEN (IF settled14.orderRestatedReturnBitfield15 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.orderRestatedReturnBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.orderRestatedReturnBitfield16 = IF settled15.numberOfReturnBitfields >= 16 THEN (IF settled15.orderRestatedReturnBitfield16 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled15.orderRestatedReturnBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.orderRestatedReturnBitfield17 = IF settled16.numberOfReturnBitfields >= 17 THEN (IF settled16.orderRestatedReturnBitfield17 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled16.orderRestatedReturnBitfield17) ELSE << >>]
        settled18 == [settled17 EXCEPT !.orderRestatedReturnBitfield18 = IF settled17.numberOfReturnBitfields >= 18 THEN (IF settled17.orderRestatedReturnBitfield18 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.orderRestatedReturnBitfield18) ELSE << >>]
        settled19 == [settled18 EXCEPT !.orderRestatedReturnBitfield19 = IF settled18.numberOfReturnBitfields >= 19 THEN (IF settled18.orderRestatedReturnBitfield19 = << >> THEN <<0>> ELSE settled18.orderRestatedReturnBitfield19) ELSE << >>]
        settled20 == [settled19 EXCEPT !.orderRestatedReturnBitfield20 = IF settled19.numberOfReturnBitfields >= 20 THEN (IF settled19.orderRestatedReturnBitfield20 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled19.orderRestatedReturnBitfield20) ELSE << >>]
        settled21 == [settled20 EXCEPT !.orderRestatedReturnBitfield21 = IF settled20.numberOfReturnBitfields >= 21 THEN (IF settled20.orderRestatedReturnBitfield21 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled20.orderRestatedReturnBitfield21) ELSE << >>]
        settled22 == [settled21 EXCEPT !.orderRestatedReturnBitfield22 = IF settled21.numberOfReturnBitfields >= 22 THEN (IF settled21.orderRestatedReturnBitfield22 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled21.orderRestatedReturnBitfield22) ELSE << >>]
        settled23 == [settled22 EXCEPT !.side = IF settled22.numberOfReturnBitfields >= 1 /\ (settled22.orderRestatedReturnBitfield1 # << >> /\ settled22.orderRestatedReturnBitfield1[1] % 2 > 0) THEN (IF settled22.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled22.side) ELSE << >>]
        settled24 == [settled23 EXCEPT !.pegDifference = IF settled23.numberOfReturnBitfields >= 1 /\ (settled23.orderRestatedReturnBitfield1 # << >> /\ (settled23.orderRestatedReturnBitfield1[1] \div 2) % 2 > 0) THEN (IF settled23.pegDifference = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled23.pegDifference) ELSE << >>]
        settled25 == [settled24 EXCEPT !.price = IF settled24.numberOfReturnBitfields >= 1 /\ (settled24.orderRestatedReturnBitfield1 # << >> /\ (settled24.orderRestatedReturnBitfield1[1] \div 4) % 2 > 0) THEN (IF settled24.price = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled24.price) ELSE << >>]
        settled26 == [settled25 EXCEPT !.execInst = IF settled25.numberOfReturnBitfields >= 1 /\ (settled25.orderRestatedReturnBitfield1 # << >> /\ (settled25.orderRestatedReturnBitfield1[1] \div 8) % 2 > 0) THEN (IF settled25.execInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled25.execInst) ELSE << >>]
        settled27 == [settled26 EXCEPT !.ordType = IF settled26.numberOfReturnBitfields >= 1 /\ (settled26.orderRestatedReturnBitfield1 # << >> /\ (settled26.orderRestatedReturnBitfield1[1] \div 16) % 2 > 0) THEN (IF settled26.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled26.ordType) ELSE << >>]
        settled28 == [settled27 EXCEPT !.timeInForce = IF settled27.numberOfReturnBitfields >= 1 /\ (settled27.orderRestatedReturnBitfield1 # << >> /\ (settled27.orderRestatedReturnBitfield1[1] \div 32) % 2 > 0) THEN (IF settled27.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled27.timeInForce) ELSE << >>]
        settled29 == [settled28 EXCEPT !.minQty = IF settled28.numberOfReturnBitfields >= 1 /\ (settled28.orderRestatedReturnBitfield1 # << >> /\ (settled28.orderRestatedReturnBitfield1[1] \div 64) % 2 > 0) THEN (IF settled28.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled28.minQty) ELSE << >>]
        settled30 == [settled29 EXCEPT !.symbol = IF settled29.numberOfReturnBitfields >= 2 /\ (settled29.orderRestatedReturnBitfield2 # << >> /\ settled29.orderRestatedReturnBitfield2[1] % 2 > 0) THEN (IF settled29.symbol = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled29.symbol) ELSE << >>]
        settled31 == [settled30 EXCEPT !.symbolSfx = IF settled30.numberOfReturnBitfields >= 2 /\ (settled30.orderRestatedReturnBitfield2 # << >> /\ (settled30.orderRestatedReturnBitfield2[1] \div 2) % 2 > 0) THEN (IF settled30.symbolSfx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled30.symbolSfx) ELSE << >>]
        settled32 == [settled31 EXCEPT !.capacity = IF settled31.numberOfReturnBitfields >= 2 /\ (settled31.orderRestatedReturnBitfield2 # << >> /\ (settled31.orderRestatedReturnBitfield2[1] \div 64) % 2 > 0) THEN (IF settled31.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled31.capacity) ELSE << >>]
        settled33 == [settled32 EXCEPT !.account = IF settled32.numberOfReturnBitfields >= 3 /\ (settled32.orderRestatedReturnBitfield3 # << >> /\ settled32.orderRestatedReturnBitfield3[1] % 2 > 0) THEN (IF settled32.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled32.account) ELSE << >>]
        settled34 == [settled33 EXCEPT !.clearingFirm = IF settled33.numberOfReturnBitfields >= 3 /\ (settled33.orderRestatedReturnBitfield3 # << >> /\ (settled33.orderRestatedReturnBitfield3[1] \div 2) % 2 > 0) THEN (IF settled33.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled33.clearingFirm) ELSE << >>]
        settled35 == [settled34 EXCEPT !.clearingAccount = IF settled34.numberOfReturnBitfields >= 3 /\ (settled34.orderRestatedReturnBitfield3 # << >> /\ (settled34.orderRestatedReturnBitfield3[1] \div 4) % 2 > 0) THEN (IF settled34.clearingAccount = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled34.clearingAccount) ELSE << >>]
        settled36 == [settled35 EXCEPT !.displayIndicator = IF settled35.numberOfReturnBitfields >= 3 /\ (settled35.orderRestatedReturnBitfield3 # << >> /\ (settled35.orderRestatedReturnBitfield3[1] \div 8) % 2 > 0) THEN (IF settled35.displayIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled35.displayIndicator) ELSE << >>]
        settled37 == [settled36 EXCEPT !.maxFloor = IF settled36.numberOfReturnBitfields >= 3 /\ (settled36.orderRestatedReturnBitfield3 # << >> /\ (settled36.orderRestatedReturnBitfield3[1] \div 16) % 2 > 0) THEN (IF settled36.maxFloor = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled36.maxFloor) ELSE << >>]
        settled38 == [settled37 EXCEPT !.discretionAmount = IF settled37.numberOfReturnBitfields >= 3 /\ (settled37.orderRestatedReturnBitfield3 # << >> /\ (settled37.orderRestatedReturnBitfield3[1] \div 32) % 2 > 0) THEN (IF settled37.discretionAmount = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled37.discretionAmount) ELSE << >>]
        settled39 == [settled38 EXCEPT !.orderQty = IF settled38.numberOfReturnBitfields >= 3 /\ (settled38.orderRestatedReturnBitfield3 # << >> /\ (settled38.orderRestatedReturnBitfield3[1] \div 64) % 2 > 0) THEN (IF settled38.orderQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled38.orderQty) ELSE << >>]
        settled40 == [settled39 EXCEPT !.preventMatch = IF settled39.numberOfReturnBitfields >= 3 /\ (settled39.orderRestatedReturnBitfield3 # << >> /\ (settled39.orderRestatedReturnBitfield3[1] \div 128) % 2 > 0) THEN (IF settled39.preventMatch = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled39.preventMatch) ELSE << >>]
        settled41 == [settled40 EXCEPT !.origClOrdId = IF settled40.numberOfReturnBitfields >= 5 /\ (settled40.orderRestatedReturnBitfield5 # << >> /\ settled40.orderRestatedReturnBitfield5[1] % 2 > 0) THEN (IF settled40.origClOrdId = << >> THEN <<[i \in 1 .. 20 |-> 0]>> ELSE settled40.origClOrdId) ELSE << >>]
        settled42 == [settled41 EXCEPT !.leavesQty = IF settled41.numberOfReturnBitfields >= 5 /\ (settled41.orderRestatedReturnBitfield5 # << >> /\ (settled41.orderRestatedReturnBitfield5[1] \div 2) % 2 > 0) THEN (IF settled41.leavesQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled41.leavesQty) ELSE << >>]
        settled43 == [settled42 EXCEPT !.lastShares = IF settled42.numberOfReturnBitfields >= 5 /\ (settled42.orderRestatedReturnBitfield5 # << >> /\ (settled42.orderRestatedReturnBitfield5[1] \div 4) % 2 > 0) THEN (IF settled42.lastShares = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled42.lastShares) ELSE << >>]
        settled44 == [settled43 EXCEPT !.lastPx = IF settled43.numberOfReturnBitfields >= 5 /\ (settled43.orderRestatedReturnBitfield5 # << >> /\ (settled43.orderRestatedReturnBitfield5[1] \div 8) % 2 > 0) THEN (IF settled43.lastPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled43.lastPx) ELSE << >>]
        settled45 == [settled44 EXCEPT !.displayPrice = IF settled44.numberOfReturnBitfields >= 5 /\ (settled44.orderRestatedReturnBitfield5 # << >> /\ (settled44.orderRestatedReturnBitfield5[1] \div 16) % 2 > 0) THEN (IF settled44.displayPrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled44.displayPrice) ELSE << >>]
        settled46 == [settled45 EXCEPT !.workingPrice = IF settled45.numberOfReturnBitfields >= 5 /\ (settled45.orderRestatedReturnBitfield5 # << >> /\ (settled45.orderRestatedReturnBitfield5[1] \div 32) % 2 > 0) THEN (IF settled45.workingPrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled45.workingPrice) ELSE << >>]
        settled47 == [settled46 EXCEPT !.baseLiquidityIndicator = IF settled46.numberOfReturnBitfields >= 5 /\ (settled46.orderRestatedReturnBitfield5 # << >> /\ (settled46.orderRestatedReturnBitfield5[1] \div 64) % 2 > 0) THEN (IF settled46.baseLiquidityIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled46.baseLiquidityIndicator) ELSE << >>]
        settled48 == [settled47 EXCEPT !.expireTime = IF settled47.numberOfReturnBitfields >= 5 /\ (settled47.orderRestatedReturnBitfield5 # << >> /\ (settled47.orderRestatedReturnBitfield5[1] \div 128) % 2 > 0) THEN (IF settled47.expireTime = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled47.expireTime) ELSE << >>]
        settled49 == [settled48 EXCEPT !.secondaryOrderId = IF settled48.numberOfReturnBitfields >= 6 /\ (settled48.orderRestatedReturnBitfield6 # << >> /\ settled48.orderRestatedReturnBitfield6[1] % 2 > 0) THEN (IF settled48.secondaryOrderId = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled48.secondaryOrderId) ELSE << >>]
        settled50 == [settled49 EXCEPT !.attributedQuote = IF settled49.numberOfReturnBitfields >= 6 /\ (settled49.orderRestatedReturnBitfield6 # << >> /\ (settled49.orderRestatedReturnBitfield6[1] \div 8) % 2 > 0) THEN (IF settled49.attributedQuote = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled49.attributedQuote) ELSE << >>]
        settled51 == [settled50 EXCEPT !.extExecInst = IF settled50.numberOfReturnBitfields >= 6 /\ (settled50.orderRestatedReturnBitfield6 # << >> /\ (settled50.orderRestatedReturnBitfield6[1] \div 16) % 2 > 0) THEN (IF settled50.extExecInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled50.extExecInst) ELSE << >>]
        settled52 == [settled51 EXCEPT !.echoText = IF settled51.numberOfReturnBitfields >= 8 /\ (settled51.orderRestatedReturnBitfield8 # << >> /\ (settled51.orderRestatedReturnBitfield8[1] \div 2) % 2 > 0) THEN (IF settled51.echoText = << >> THEN <<[i \in 1 .. 64 |-> 0]>> ELSE settled51.echoText) ELSE << >>]
        settled53 == [settled52 EXCEPT !.stopPx = IF settled52.numberOfReturnBitfields >= 8 /\ (settled52.orderRestatedReturnBitfield8 # << >> /\ (settled52.orderRestatedReturnBitfield8[1] \div 4) % 2 > 0) THEN (IF settled52.stopPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled52.stopPx) ELSE << >>]
        settled54 == [settled53 EXCEPT !.routingInst = IF settled53.numberOfReturnBitfields >= 8 /\ (settled53.orderRestatedReturnBitfield8 # << >> /\ (settled53.orderRestatedReturnBitfield8[1] \div 8) % 2 > 0) THEN (IF settled53.routingInst = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled53.routingInst) ELSE << >>]
        settled55 == [settled54 EXCEPT !.routStrategy = IF settled54.numberOfReturnBitfields >= 8 /\ (settled54.orderRestatedReturnBitfield8 # << >> /\ (settled54.orderRestatedReturnBitfield8[1] \div 16) % 2 > 0) THEN (IF settled54.routStrategy = << >> THEN <<[i \in 1 .. 6 |-> 0]>> ELSE settled54.routStrategy) ELSE << >>]
        settled56 == [settled55 EXCEPT !.routeDeliveryMethod = IF settled55.numberOfReturnBitfields >= 8 /\ (settled55.orderRestatedReturnBitfield8 # << >> /\ (settled55.orderRestatedReturnBitfield8[1] \div 32) % 2 > 0) THEN (IF settled55.routeDeliveryMethod = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled55.routeDeliveryMethod) ELSE << >>]
        settled57 == [settled56 EXCEPT !.exDestination = IF settled56.numberOfReturnBitfields >= 8 /\ (settled56.orderRestatedReturnBitfield8 # << >> /\ (settled56.orderRestatedReturnBitfield8[1] \div 64) % 2 > 0) THEN (IF settled56.exDestination = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled56.exDestination) ELSE << >>]
        settled58 == [settled57 EXCEPT !.cmcMatchQty = IF settled57.numberOfReturnBitfields >= 19 /\ (settled57.orderRestatedReturnBitfield19 # << >> /\ (settled57.orderRestatedReturnBitfield19[1] \div 32) % 2 > 0) THEN (IF settled57.cmcMatchQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled57.cmcMatchQty) ELSE << >>]
        settled59 == [settled58 EXCEPT !.stepUpAmount = IF settled58.numberOfReturnBitfields >= 19 /\ (settled58.orderRestatedReturnBitfield19 # << >> /\ (settled58.orderRestatedReturnBitfield19[1] \div 64) % 2 > 0) THEN (IF settled58.stepUpAmount = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled58.stepUpAmount) ELSE << >>]
    IN  settled59

ZeroOrderRestatedMessage ==
    SettleOrderRestatedMessage([ transactionTime               |-> [i \in 1 .. 8 |-> 0],
                                 clOrdId                       |-> [i \in 1 .. 20 |-> 0],
                                 orderId                       |-> [i \in 1 .. 8 |-> 0],
                                 restatementReason             |-> [i \in 1 .. 1 |-> 0],
                                 reserved1                     |-> [i \in 1 .. 1 |-> 0],
                                 numberOfReturnBitfields       |-> 0,
                                 orderRestatedReturnBitfield1  |-> << >>,
                                 orderRestatedReturnBitfield2  |-> << >>,
                                 orderRestatedReturnBitfield3  |-> << >>,
                                 orderRestatedReturnBitfield4  |-> << >>,
                                 orderRestatedReturnBitfield5  |-> << >>,
                                 orderRestatedReturnBitfield6  |-> << >>,
                                 orderRestatedReturnBitfield7  |-> << >>,
                                 orderRestatedReturnBitfield8  |-> << >>,
                                 orderRestatedReturnBitfield9  |-> << >>,
                                 orderRestatedReturnBitfield10 |-> << >>,
                                 orderRestatedReturnBitfield11 |-> << >>,
                                 orderRestatedReturnBitfield12 |-> << >>,
                                 orderRestatedReturnBitfield13 |-> << >>,
                                 orderRestatedReturnBitfield14 |-> << >>,
                                 orderRestatedReturnBitfield15 |-> << >>,
                                 orderRestatedReturnBitfield16 |-> << >>,
                                 orderRestatedReturnBitfield17 |-> << >>,
                                 orderRestatedReturnBitfield18 |-> << >>,
                                 orderRestatedReturnBitfield19 |-> << >>,
                                 orderRestatedReturnBitfield20 |-> << >>,
                                 orderRestatedReturnBitfield21 |-> << >>,
                                 orderRestatedReturnBitfield22 |-> << >>,
                                 side                          |-> << >>,
                                 pegDifference                 |-> << >>,
                                 price                         |-> << >>,
                                 execInst                      |-> << >>,
                                 ordType                       |-> << >>,
                                 timeInForce                   |-> << >>,
                                 minQty                        |-> << >>,
                                 symbol                        |-> << >>,
                                 symbolSfx                     |-> << >>,
                                 capacity                      |-> << >>,
                                 account                       |-> << >>,
                                 clearingFirm                  |-> << >>,
                                 clearingAccount               |-> << >>,
                                 displayIndicator              |-> << >>,
                                 maxFloor                      |-> << >>,
                                 discretionAmount              |-> << >>,
                                 orderQty                      |-> << >>,
                                 preventMatch                  |-> << >>,
                                 origClOrdId                   |-> << >>,
                                 leavesQty                     |-> << >>,
                                 lastShares                    |-> << >>,
                                 lastPx                        |-> << >>,
                                 displayPrice                  |-> << >>,
                                 workingPrice                  |-> << >>,
                                 baseLiquidityIndicator        |-> << >>,
                                 expireTime                    |-> << >>,
                                 secondaryOrderId              |-> << >>,
                                 attributedQuote               |-> << >>,
                                 extExecInst                   |-> << >>,
                                 echoText                      |-> << >>,
                                 stopPx                        |-> << >>,
                                 routingInst                   |-> << >>,
                                 routStrategy                  |-> << >>,
                                 routeDeliveryMethod           |-> << >>,
                                 exDestination                 |-> << >>,
                                 cmcMatchQty                   |-> << >>,
                                 stepUpAmount                  |-> << >> ])

(* Order Restated Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderRestatedMessage ==
    { ZeroOrderRestatedMessage }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.transactionTime = one]) : one \in Sample(8) }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.clOrdId = one]) : one \in Sample(20) }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.orderId = one]) : one \in Sample(8) }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.restatementReason = one]) : one \in Sample(1) }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.reserved1 = one]) : one \in Sample(1) }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderRestatedReturnBitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 2, !.orderRestatedReturnBitfield2 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderRestatedReturnBitfield3 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 4, !.orderRestatedReturnBitfield4 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderRestatedReturnBitfield5 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 6, !.orderRestatedReturnBitfield6 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 7, !.orderRestatedReturnBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderRestatedReturnBitfield8 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 9, !.orderRestatedReturnBitfield9 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 10, !.orderRestatedReturnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 11, !.orderRestatedReturnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 12, !.orderRestatedReturnBitfield12 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 13, !.orderRestatedReturnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 14, !.orderRestatedReturnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 15, !.orderRestatedReturnBitfield15 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 16, !.orderRestatedReturnBitfield16 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 17, !.orderRestatedReturnBitfield17 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 18, !.orderRestatedReturnBitfield18 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 19, !.orderRestatedReturnBitfield19 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 20, !.orderRestatedReturnBitfield20 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 21, !.orderRestatedReturnBitfield21 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 22, !.orderRestatedReturnBitfield22 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderRestatedReturnBitfield1 = <<1>>, !.side = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderRestatedReturnBitfield1 = <<2>>, !.pegDifference = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderRestatedReturnBitfield1 = <<4>>, !.price = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderRestatedReturnBitfield1 = <<8>>, !.execInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderRestatedReturnBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderRestatedReturnBitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderRestatedReturnBitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 2, !.orderRestatedReturnBitfield2 = <<1>>, !.symbol = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 2, !.orderRestatedReturnBitfield2 = <<2>>, !.symbolSfx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 2, !.orderRestatedReturnBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderRestatedReturnBitfield3 = <<1>>, !.account = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderRestatedReturnBitfield3 = <<2>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderRestatedReturnBitfield3 = <<4>>, !.clearingAccount = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderRestatedReturnBitfield3 = <<8>>, !.displayIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderRestatedReturnBitfield3 = <<16>>, !.maxFloor = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderRestatedReturnBitfield3 = <<32>>, !.discretionAmount = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderRestatedReturnBitfield3 = <<64>>, !.orderQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderRestatedReturnBitfield3 = <<128>>, !.preventMatch = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderRestatedReturnBitfield5 = <<1>>, !.origClOrdId = one]) : one \in { <<held>> : held \in Sample(20) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderRestatedReturnBitfield5 = <<2>>, !.leavesQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderRestatedReturnBitfield5 = <<4>>, !.lastShares = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderRestatedReturnBitfield5 = <<8>>, !.lastPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderRestatedReturnBitfield5 = <<16>>, !.displayPrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderRestatedReturnBitfield5 = <<32>>, !.workingPrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderRestatedReturnBitfield5 = <<64>>, !.baseLiquidityIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderRestatedReturnBitfield5 = <<128>>, !.expireTime = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 6, !.orderRestatedReturnBitfield6 = <<1>>, !.secondaryOrderId = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 6, !.orderRestatedReturnBitfield6 = <<8>>, !.attributedQuote = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 6, !.orderRestatedReturnBitfield6 = <<16>>, !.extExecInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderRestatedReturnBitfield8 = <<2>>, !.echoText = one]) : one \in { <<held>> : held \in Sample(64) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderRestatedReturnBitfield8 = <<4>>, !.stopPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderRestatedReturnBitfield8 = <<8>>, !.routingInst = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderRestatedReturnBitfield8 = <<16>>, !.routStrategy = one]) : one \in { <<held>> : held \in Sample(6) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderRestatedReturnBitfield8 = <<32>>, !.routeDeliveryMethod = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderRestatedReturnBitfield8 = <<64>>, !.exDestination = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 19, !.orderRestatedReturnBitfield19 = <<32>>, !.cmcMatchQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.numberOfReturnBitfields = 19, !.orderRestatedReturnBitfield19 = <<64>>, !.stepUpAmount = one]) : one \in { <<held>> : held \in Sample(8) } }

(***************************************************************************)
(* User Modify Rejected Message                                            *)
(***************************************************************************)

UserModifyRejectedMessage ==
    [ transactionTime                    : Sample(8),
      clOrdId                            : Sample(20),
      modifyRejectReason                 : Sample(1),
      text                               : Sample(60),
      reserved1                          : Sample(1),
      numberOfReturnBitfields            : 0 .. 255,
      userModifyRejectedReturnBitfield1  : { << >> } \cup { <<held>> : held \in Sample(1) },
      userModifyRejectedReturnBitfield2  : { << >> } \cup { <<held>> : held \in Sample(1) },
      userModifyRejectedReturnBitfield3  : { << >> } \cup { <<held>> : held \in Sample(1) },
      userModifyRejectedReturnBitfield4  : { << >> } \cup { <<held>> : held \in Sample(1) },
      userModifyRejectedReturnBitfield5  : { << >> } \cup { <<held>> : held \in Sample(1) },
      userModifyRejectedReturnBitfield6  : { << >> } \cup { <<held>> : held \in Sample(1) },
      userModifyRejectedReturnBitfield7  : { << >> } \cup { <<held>> : held \in Sample(1) },
      userModifyRejectedReturnBitfield8  : { << >> } \cup { <<held>> : held \in Sample(1) },
      userModifyRejectedReturnBitfield9  : { << >> } \cup { <<held>> : held \in Sample(1) },
      userModifyRejectedReturnBitfield10 : { << >> } \cup { <<held>> : held \in Sample(1) },
      userModifyRejectedReturnBitfield11 : { << >> } \cup { <<held>> : held \in Sample(1) },
      userModifyRejectedReturnBitfield12 : { << >> } \cup { <<held>> : held \in Sample(1) },
      userModifyRejectedReturnBitfield13 : { << >> } \cup { <<held>> : held \in Sample(1) },
      userModifyRejectedReturnBitfield14 : { << >> } \cup { <<held>> : held \in Sample(1) },
      userModifyRejectedReturnBitfield15 : { << >> } \cup { <<held>> : held \in Sample(1) },
      userModifyRejectedReturnBitfield16 : { << >> } \cup { <<held>> : held \in Sample(1) },
      userModifyRejectedReturnBitfield17 : { << >> } \cup { <<held>> : held \in Sample(1) },
      userModifyRejectedReturnBitfield18 : { << >> } \cup { <<held>> : held \in Sample(1) },
      userModifyRejectedReturnBitfield19 : { << >> } \cup { <<held>> : held \in Sample(1) },
      userModifyRejectedReturnBitfield20 : { << >> } \cup { <<held>> : held \in Sample(1) },
      userModifyRejectedReturnBitfield21 : { << >> } \cup { <<held>> : held \in Sample(1) },
      userModifyRejectedReturnBitfield22 : { << >> } \cup { <<held>> : held \in Sample(1) } ]

EncodeUserModifyRejectedMessage(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.modifyRejectReason
        \o message.text
        \o message.reserved1
        \o EncodeUIntBE(message.numberOfReturnBitfields, 1)
        \o (IF message.userModifyRejectedReturnBitfield1 = << >> THEN << >> ELSE message.userModifyRejectedReturnBitfield1[1])
        \o (IF message.userModifyRejectedReturnBitfield2 = << >> THEN << >> ELSE message.userModifyRejectedReturnBitfield2[1])
        \o (IF message.userModifyRejectedReturnBitfield3 = << >> THEN << >> ELSE message.userModifyRejectedReturnBitfield3[1])
        \o (IF message.userModifyRejectedReturnBitfield4 = << >> THEN << >> ELSE message.userModifyRejectedReturnBitfield4[1])
        \o (IF message.userModifyRejectedReturnBitfield5 = << >> THEN << >> ELSE message.userModifyRejectedReturnBitfield5[1])
        \o (IF message.userModifyRejectedReturnBitfield6 = << >> THEN << >> ELSE message.userModifyRejectedReturnBitfield6[1])
        \o (IF message.userModifyRejectedReturnBitfield7 = << >> THEN << >> ELSE message.userModifyRejectedReturnBitfield7[1])
        \o (IF message.userModifyRejectedReturnBitfield8 = << >> THEN << >> ELSE message.userModifyRejectedReturnBitfield8[1])
        \o (IF message.userModifyRejectedReturnBitfield9 = << >> THEN << >> ELSE message.userModifyRejectedReturnBitfield9[1])
        \o (IF message.userModifyRejectedReturnBitfield10 = << >> THEN << >> ELSE message.userModifyRejectedReturnBitfield10[1])
        \o (IF message.userModifyRejectedReturnBitfield11 = << >> THEN << >> ELSE message.userModifyRejectedReturnBitfield11[1])
        \o (IF message.userModifyRejectedReturnBitfield12 = << >> THEN << >> ELSE message.userModifyRejectedReturnBitfield12[1])
        \o (IF message.userModifyRejectedReturnBitfield13 = << >> THEN << >> ELSE message.userModifyRejectedReturnBitfield13[1])
        \o (IF message.userModifyRejectedReturnBitfield14 = << >> THEN << >> ELSE message.userModifyRejectedReturnBitfield14[1])
        \o (IF message.userModifyRejectedReturnBitfield15 = << >> THEN << >> ELSE message.userModifyRejectedReturnBitfield15[1])
        \o (IF message.userModifyRejectedReturnBitfield16 = << >> THEN << >> ELSE message.userModifyRejectedReturnBitfield16[1])
        \o (IF message.userModifyRejectedReturnBitfield17 = << >> THEN << >> ELSE message.userModifyRejectedReturnBitfield17[1])
        \o (IF message.userModifyRejectedReturnBitfield18 = << >> THEN << >> ELSE message.userModifyRejectedReturnBitfield18[1])
        \o (IF message.userModifyRejectedReturnBitfield19 = << >> THEN << >> ELSE message.userModifyRejectedReturnBitfield19[1])
        \o (IF message.userModifyRejectedReturnBitfield20 = << >> THEN << >> ELSE message.userModifyRejectedReturnBitfield20[1])
        \o (IF message.userModifyRejectedReturnBitfield21 = << >> THEN << >> ELSE message.userModifyRejectedReturnBitfield21[1])
        \o (IF message.userModifyRejectedReturnBitfield22 = << >> THEN << >> ELSE message.userModifyRejectedReturnBitfield22[1])

DecodeUserModifyRejectedMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET modifyRejectReason == ReadBytes(clOrdId.rest, 1) IN IF ~modifyRejectReason.ok THEN Fail ELSE
    LET text == ReadBytes(modifyRejectReason.rest, 60) IN IF ~text.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(text.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET numberOfReturnBitfields == ReadUIntBE(reserved1.rest, 1) IN IF ~numberOfReturnBitfields.ok THEN Fail ELSE
    LET userModifyRejectedReturnBitfield1 == ReadWhen(numberOfReturnBitfields.value >= 1, ReadBytes(numberOfReturnBitfields.rest, 1), numberOfReturnBitfields.rest) IN IF ~userModifyRejectedReturnBitfield1.ok THEN Fail ELSE
    LET userModifyRejectedReturnBitfield2 == ReadWhen(numberOfReturnBitfields.value >= 2, ReadBytes(userModifyRejectedReturnBitfield1.rest, 1), userModifyRejectedReturnBitfield1.rest) IN IF ~userModifyRejectedReturnBitfield2.ok THEN Fail ELSE
    LET userModifyRejectedReturnBitfield3 == ReadWhen(numberOfReturnBitfields.value >= 3, ReadBytes(userModifyRejectedReturnBitfield2.rest, 1), userModifyRejectedReturnBitfield2.rest) IN IF ~userModifyRejectedReturnBitfield3.ok THEN Fail ELSE
    LET userModifyRejectedReturnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadBytes(userModifyRejectedReturnBitfield3.rest, 1), userModifyRejectedReturnBitfield3.rest) IN IF ~userModifyRejectedReturnBitfield4.ok THEN Fail ELSE
    LET userModifyRejectedReturnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadBytes(userModifyRejectedReturnBitfield4.rest, 1), userModifyRejectedReturnBitfield4.rest) IN IF ~userModifyRejectedReturnBitfield5.ok THEN Fail ELSE
    LET userModifyRejectedReturnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadBytes(userModifyRejectedReturnBitfield5.rest, 1), userModifyRejectedReturnBitfield5.rest) IN IF ~userModifyRejectedReturnBitfield6.ok THEN Fail ELSE
    LET userModifyRejectedReturnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadBytes(userModifyRejectedReturnBitfield6.rest, 1), userModifyRejectedReturnBitfield6.rest) IN IF ~userModifyRejectedReturnBitfield7.ok THEN Fail ELSE
    LET userModifyRejectedReturnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadBytes(userModifyRejectedReturnBitfield7.rest, 1), userModifyRejectedReturnBitfield7.rest) IN IF ~userModifyRejectedReturnBitfield8.ok THEN Fail ELSE
    LET userModifyRejectedReturnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadBytes(userModifyRejectedReturnBitfield8.rest, 1), userModifyRejectedReturnBitfield8.rest) IN IF ~userModifyRejectedReturnBitfield9.ok THEN Fail ELSE
    LET userModifyRejectedReturnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadBytes(userModifyRejectedReturnBitfield9.rest, 1), userModifyRejectedReturnBitfield9.rest) IN IF ~userModifyRejectedReturnBitfield10.ok THEN Fail ELSE
    LET userModifyRejectedReturnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadBytes(userModifyRejectedReturnBitfield10.rest, 1), userModifyRejectedReturnBitfield10.rest) IN IF ~userModifyRejectedReturnBitfield11.ok THEN Fail ELSE
    LET userModifyRejectedReturnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadBytes(userModifyRejectedReturnBitfield11.rest, 1), userModifyRejectedReturnBitfield11.rest) IN IF ~userModifyRejectedReturnBitfield12.ok THEN Fail ELSE
    LET userModifyRejectedReturnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(userModifyRejectedReturnBitfield12.rest, 1), userModifyRejectedReturnBitfield12.rest) IN IF ~userModifyRejectedReturnBitfield13.ok THEN Fail ELSE
    LET userModifyRejectedReturnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(userModifyRejectedReturnBitfield13.rest, 1), userModifyRejectedReturnBitfield13.rest) IN IF ~userModifyRejectedReturnBitfield14.ok THEN Fail ELSE
    LET userModifyRejectedReturnBitfield15 == ReadWhen(numberOfReturnBitfields.value >= 15, ReadBytes(userModifyRejectedReturnBitfield14.rest, 1), userModifyRejectedReturnBitfield14.rest) IN IF ~userModifyRejectedReturnBitfield15.ok THEN Fail ELSE
    LET userModifyRejectedReturnBitfield16 == ReadWhen(numberOfReturnBitfields.value >= 16, ReadBytes(userModifyRejectedReturnBitfield15.rest, 1), userModifyRejectedReturnBitfield15.rest) IN IF ~userModifyRejectedReturnBitfield16.ok THEN Fail ELSE
    LET userModifyRejectedReturnBitfield17 == ReadWhen(numberOfReturnBitfields.value >= 17, ReadBytes(userModifyRejectedReturnBitfield16.rest, 1), userModifyRejectedReturnBitfield16.rest) IN IF ~userModifyRejectedReturnBitfield17.ok THEN Fail ELSE
    LET userModifyRejectedReturnBitfield18 == ReadWhen(numberOfReturnBitfields.value >= 18, ReadBytes(userModifyRejectedReturnBitfield17.rest, 1), userModifyRejectedReturnBitfield17.rest) IN IF ~userModifyRejectedReturnBitfield18.ok THEN Fail ELSE
    LET userModifyRejectedReturnBitfield19 == ReadWhen(numberOfReturnBitfields.value >= 19, ReadBytes(userModifyRejectedReturnBitfield18.rest, 1), userModifyRejectedReturnBitfield18.rest) IN IF ~userModifyRejectedReturnBitfield19.ok THEN Fail ELSE
    LET userModifyRejectedReturnBitfield20 == ReadWhen(numberOfReturnBitfields.value >= 20, ReadBytes(userModifyRejectedReturnBitfield19.rest, 1), userModifyRejectedReturnBitfield19.rest) IN IF ~userModifyRejectedReturnBitfield20.ok THEN Fail ELSE
    LET userModifyRejectedReturnBitfield21 == ReadWhen(numberOfReturnBitfields.value >= 21, ReadBytes(userModifyRejectedReturnBitfield20.rest, 1), userModifyRejectedReturnBitfield20.rest) IN IF ~userModifyRejectedReturnBitfield21.ok THEN Fail ELSE
    LET userModifyRejectedReturnBitfield22 == ReadWhen(numberOfReturnBitfields.value >= 22, ReadBytes(userModifyRejectedReturnBitfield21.rest, 1), userModifyRejectedReturnBitfield21.rest) IN IF ~userModifyRejectedReturnBitfield22.ok THEN Fail ELSE
    Ok([ transactionTime                    |-> transactionTime.value,
         clOrdId                            |-> clOrdId.value,
         modifyRejectReason                 |-> modifyRejectReason.value,
         text                               |-> text.value,
         reserved1                          |-> reserved1.value,
         numberOfReturnBitfields            |-> numberOfReturnBitfields.value,
         userModifyRejectedReturnBitfield1  |-> userModifyRejectedReturnBitfield1.value,
         userModifyRejectedReturnBitfield2  |-> userModifyRejectedReturnBitfield2.value,
         userModifyRejectedReturnBitfield3  |-> userModifyRejectedReturnBitfield3.value,
         userModifyRejectedReturnBitfield4  |-> userModifyRejectedReturnBitfield4.value,
         userModifyRejectedReturnBitfield5  |-> userModifyRejectedReturnBitfield5.value,
         userModifyRejectedReturnBitfield6  |-> userModifyRejectedReturnBitfield6.value,
         userModifyRejectedReturnBitfield7  |-> userModifyRejectedReturnBitfield7.value,
         userModifyRejectedReturnBitfield8  |-> userModifyRejectedReturnBitfield8.value,
         userModifyRejectedReturnBitfield9  |-> userModifyRejectedReturnBitfield9.value,
         userModifyRejectedReturnBitfield10 |-> userModifyRejectedReturnBitfield10.value,
         userModifyRejectedReturnBitfield11 |-> userModifyRejectedReturnBitfield11.value,
         userModifyRejectedReturnBitfield12 |-> userModifyRejectedReturnBitfield12.value,
         userModifyRejectedReturnBitfield13 |-> userModifyRejectedReturnBitfield13.value,
         userModifyRejectedReturnBitfield14 |-> userModifyRejectedReturnBitfield14.value,
         userModifyRejectedReturnBitfield15 |-> userModifyRejectedReturnBitfield15.value,
         userModifyRejectedReturnBitfield16 |-> userModifyRejectedReturnBitfield16.value,
         userModifyRejectedReturnBitfield17 |-> userModifyRejectedReturnBitfield17.value,
         userModifyRejectedReturnBitfield18 |-> userModifyRejectedReturnBitfield18.value,
         userModifyRejectedReturnBitfield19 |-> userModifyRejectedReturnBitfield19.value,
         userModifyRejectedReturnBitfield20 |-> userModifyRejectedReturnBitfield20.value,
         userModifyRejectedReturnBitfield21 |-> userModifyRejectedReturnBitfield21.value,
         userModifyRejectedReturnBitfield22 |-> userModifyRejectedReturnBitfield22.value ], userModifyRejectedReturnBitfield22.rest)

(* User Modify Rejected Message with each field marked present by fields before it there exactly where they say *)
SettleUserModifyRejectedMessage(message) ==
    LET settled1 == [message EXCEPT !.userModifyRejectedReturnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.userModifyRejectedReturnBitfield1 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE message.userModifyRejectedReturnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.userModifyRejectedReturnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.userModifyRejectedReturnBitfield2 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled1.userModifyRejectedReturnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.userModifyRejectedReturnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.userModifyRejectedReturnBitfield3 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled2.userModifyRejectedReturnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.userModifyRejectedReturnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.userModifyRejectedReturnBitfield4 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled3.userModifyRejectedReturnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.userModifyRejectedReturnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.userModifyRejectedReturnBitfield5 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled4.userModifyRejectedReturnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.userModifyRejectedReturnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.userModifyRejectedReturnBitfield6 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled5.userModifyRejectedReturnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.userModifyRejectedReturnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.userModifyRejectedReturnBitfield7 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.userModifyRejectedReturnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.userModifyRejectedReturnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.userModifyRejectedReturnBitfield8 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled7.userModifyRejectedReturnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.userModifyRejectedReturnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.userModifyRejectedReturnBitfield9 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled8.userModifyRejectedReturnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.userModifyRejectedReturnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.userModifyRejectedReturnBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.userModifyRejectedReturnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.userModifyRejectedReturnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.userModifyRejectedReturnBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.userModifyRejectedReturnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.userModifyRejectedReturnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.userModifyRejectedReturnBitfield12 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.userModifyRejectedReturnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.userModifyRejectedReturnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.userModifyRejectedReturnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.userModifyRejectedReturnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.userModifyRejectedReturnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.userModifyRejectedReturnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.userModifyRejectedReturnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.userModifyRejectedReturnBitfield15 = IF settled14.numberOfReturnBitfields >= 15 THEN (IF settled14.userModifyRejectedReturnBitfield15 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.userModifyRejectedReturnBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.userModifyRejectedReturnBitfield16 = IF settled15.numberOfReturnBitfields >= 16 THEN (IF settled15.userModifyRejectedReturnBitfield16 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled15.userModifyRejectedReturnBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.userModifyRejectedReturnBitfield17 = IF settled16.numberOfReturnBitfields >= 17 THEN (IF settled16.userModifyRejectedReturnBitfield17 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled16.userModifyRejectedReturnBitfield17) ELSE << >>]
        settled18 == [settled17 EXCEPT !.userModifyRejectedReturnBitfield18 = IF settled17.numberOfReturnBitfields >= 18 THEN (IF settled17.userModifyRejectedReturnBitfield18 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.userModifyRejectedReturnBitfield18) ELSE << >>]
        settled19 == [settled18 EXCEPT !.userModifyRejectedReturnBitfield19 = IF settled18.numberOfReturnBitfields >= 19 THEN (IF settled18.userModifyRejectedReturnBitfield19 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled18.userModifyRejectedReturnBitfield19) ELSE << >>]
        settled20 == [settled19 EXCEPT !.userModifyRejectedReturnBitfield20 = IF settled19.numberOfReturnBitfields >= 20 THEN (IF settled19.userModifyRejectedReturnBitfield20 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled19.userModifyRejectedReturnBitfield20) ELSE << >>]
        settled21 == [settled20 EXCEPT !.userModifyRejectedReturnBitfield21 = IF settled20.numberOfReturnBitfields >= 21 THEN (IF settled20.userModifyRejectedReturnBitfield21 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled20.userModifyRejectedReturnBitfield21) ELSE << >>]
        settled22 == [settled21 EXCEPT !.userModifyRejectedReturnBitfield22 = IF settled21.numberOfReturnBitfields >= 22 THEN (IF settled21.userModifyRejectedReturnBitfield22 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled21.userModifyRejectedReturnBitfield22) ELSE << >>]
    IN  settled22

ZeroUserModifyRejectedMessage ==
    SettleUserModifyRejectedMessage([ transactionTime                    |-> [i \in 1 .. 8 |-> 0],
                                      clOrdId                            |-> [i \in 1 .. 20 |-> 0],
                                      modifyRejectReason                 |-> [i \in 1 .. 1 |-> 0],
                                      text                               |-> [i \in 1 .. 60 |-> 0],
                                      reserved1                          |-> [i \in 1 .. 1 |-> 0],
                                      numberOfReturnBitfields            |-> 0,
                                      userModifyRejectedReturnBitfield1  |-> << >>,
                                      userModifyRejectedReturnBitfield2  |-> << >>,
                                      userModifyRejectedReturnBitfield3  |-> << >>,
                                      userModifyRejectedReturnBitfield4  |-> << >>,
                                      userModifyRejectedReturnBitfield5  |-> << >>,
                                      userModifyRejectedReturnBitfield6  |-> << >>,
                                      userModifyRejectedReturnBitfield7  |-> << >>,
                                      userModifyRejectedReturnBitfield8  |-> << >>,
                                      userModifyRejectedReturnBitfield9  |-> << >>,
                                      userModifyRejectedReturnBitfield10 |-> << >>,
                                      userModifyRejectedReturnBitfield11 |-> << >>,
                                      userModifyRejectedReturnBitfield12 |-> << >>,
                                      userModifyRejectedReturnBitfield13 |-> << >>,
                                      userModifyRejectedReturnBitfield14 |-> << >>,
                                      userModifyRejectedReturnBitfield15 |-> << >>,
                                      userModifyRejectedReturnBitfield16 |-> << >>,
                                      userModifyRejectedReturnBitfield17 |-> << >>,
                                      userModifyRejectedReturnBitfield18 |-> << >>,
                                      userModifyRejectedReturnBitfield19 |-> << >>,
                                      userModifyRejectedReturnBitfield20 |-> << >>,
                                      userModifyRejectedReturnBitfield21 |-> << >>,
                                      userModifyRejectedReturnBitfield22 |-> << >> ])

(* User Modify Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedUserModifyRejectedMessage ==
    { ZeroUserModifyRejectedMessage }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.transactionTime = one]) : one \in Sample(8) }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.clOrdId = one]) : one \in Sample(20) }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.modifyRejectReason = one]) : one \in Sample(1) }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.text = one]) : one \in Sample(60) }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.reserved1 = one]) : one \in Sample(1) }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.numberOfReturnBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.userModifyRejectedReturnBitfield1 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.numberOfReturnBitfields = 2, !.userModifyRejectedReturnBitfield2 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.numberOfReturnBitfields = 3, !.userModifyRejectedReturnBitfield3 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.numberOfReturnBitfields = 4, !.userModifyRejectedReturnBitfield4 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.numberOfReturnBitfields = 5, !.userModifyRejectedReturnBitfield5 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.numberOfReturnBitfields = 6, !.userModifyRejectedReturnBitfield6 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.numberOfReturnBitfields = 7, !.userModifyRejectedReturnBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.numberOfReturnBitfields = 8, !.userModifyRejectedReturnBitfield8 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.numberOfReturnBitfields = 9, !.userModifyRejectedReturnBitfield9 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.numberOfReturnBitfields = 10, !.userModifyRejectedReturnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.numberOfReturnBitfields = 11, !.userModifyRejectedReturnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.numberOfReturnBitfields = 12, !.userModifyRejectedReturnBitfield12 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.numberOfReturnBitfields = 13, !.userModifyRejectedReturnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.numberOfReturnBitfields = 14, !.userModifyRejectedReturnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.numberOfReturnBitfields = 15, !.userModifyRejectedReturnBitfield15 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.numberOfReturnBitfields = 16, !.userModifyRejectedReturnBitfield16 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.numberOfReturnBitfields = 17, !.userModifyRejectedReturnBitfield17 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.numberOfReturnBitfields = 18, !.userModifyRejectedReturnBitfield18 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.numberOfReturnBitfields = 19, !.userModifyRejectedReturnBitfield19 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.numberOfReturnBitfields = 20, !.userModifyRejectedReturnBitfield20 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.numberOfReturnBitfields = 21, !.userModifyRejectedReturnBitfield21 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedMessage([ZeroUserModifyRejectedMessage EXCEPT !.numberOfReturnBitfields = 22, !.userModifyRejectedReturnBitfield22 = one]) : one \in { <<held>> : held \in Sample(1) } }

(***************************************************************************)
(* Order Cancelled Message                                                 *)
(***************************************************************************)

OrderCancelledMessage ==
    [ transactionTime                : Sample(8),
      clOrdId                        : Sample(20),
      cancelReason                   : Sample(1),
      reserved1                      : Sample(1),
      numberOfReturnBitfields        : 0 .. 255,
      orderCancelledReturnBitfield1  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderCancelledReturnBitfield2  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderCancelledReturnBitfield3  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderCancelledReturnBitfield4  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderCancelledReturnBitfield5  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderCancelledReturnBitfield6  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderCancelledReturnBitfield7  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderCancelledReturnBitfield8  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderCancelledReturnBitfield9  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderCancelledReturnBitfield10 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderCancelledReturnBitfield11 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderCancelledReturnBitfield12 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderCancelledReturnBitfield13 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderCancelledReturnBitfield14 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderCancelledReturnBitfield15 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderCancelledReturnBitfield16 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderCancelledReturnBitfield17 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderCancelledReturnBitfield18 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderCancelledReturnBitfield19 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderCancelledReturnBitfield20 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderCancelledReturnBitfield21 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderCancelledReturnBitfield22 : { << >> } \cup { <<held>> : held \in Sample(1) },
      side                           : { << >> } \cup { <<held>> : held \in Sample(1) },
      pegDifference                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      price                          : { << >> } \cup { <<held>> : held \in Sample(8) },
      execInst                       : { << >> } \cup { <<held>> : held \in Sample(1) },
      ordType                        : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce                    : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                         : { << >> } \cup { <<held>> : held \in Sample(4) },
      symbol                         : { << >> } \cup { <<held>> : held \in Sample(8) },
      symbolSfx                      : { << >> } \cup { <<held>> : held \in Sample(8) },
      capacity                       : { << >> } \cup { <<held>> : held \in Sample(1) },
      account                        : { << >> } \cup { <<held>> : held \in Sample(16) },
      clearingFirm                   : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingAccount                : { << >> } \cup { <<held>> : held \in Sample(4) },
      displayIndicator               : { << >> } \cup { <<held>> : held \in Sample(1) },
      maxFloor                       : { << >> } \cup { <<held>> : held \in Sample(4) },
      discretionAmount               : { << >> } \cup { <<held>> : held \in Sample(2) },
      orderQty                       : { << >> } \cup { <<held>> : held \in Sample(4) },
      preventMatch                   : { << >> } \cup { <<held>> : held \in Sample(3) },
      origClOrdId                    : { << >> } \cup { <<held>> : held \in Sample(20) },
      leavesQty                      : { << >> } \cup { <<held>> : held \in Sample(4) },
      lastShares                     : { << >> } \cup { <<held>> : held \in Sample(4) },
      lastPx                         : { << >> } \cup { <<held>> : held \in Sample(8) },
      displayPrice                   : { << >> } \cup { <<held>> : held \in Sample(8) },
      workingPrice                   : { << >> } \cup { <<held>> : held \in Sample(8) },
      baseLiquidityIndicator         : { << >> } \cup { <<held>> : held \in Sample(1) },
      expireTime                     : { << >> } \cup { <<held>> : held \in Sample(8) },
      secondaryOrderId               : { << >> } \cup { <<held>> : held \in Sample(8) },
      attributedQuote                : { << >> } \cup { <<held>> : held \in Sample(1) },
      extExecInst                    : { << >> } \cup { <<held>> : held \in Sample(1) },
      echoText                       : { << >> } \cup { <<held>> : held \in Sample(64) },
      stopPx                         : { << >> } \cup { <<held>> : held \in Sample(8) },
      routingInst                    : { << >> } \cup { <<held>> : held \in Sample(4) },
      routStrategy                   : { << >> } \cup { <<held>> : held \in Sample(6) },
      routeDeliveryMethod            : { << >> } \cup { <<held>> : held \in Sample(3) },
      exDestination                  : { << >> } \cup { <<held>> : held \in Sample(1) },
      crossTradeFlag                 : { << >> } \cup { <<held>> : held \in Sample(1) } ]

EncodeOrderCancelledMessage(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.cancelReason
        \o message.reserved1
        \o EncodeUIntBE(message.numberOfReturnBitfields, 1)
        \o (IF message.orderCancelledReturnBitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.orderCancelledReturnBitfield1[1], 1))
        \o (IF message.orderCancelledReturnBitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.orderCancelledReturnBitfield2[1], 1))
        \o (IF message.orderCancelledReturnBitfield3 = << >> THEN << >> ELSE EncodeUIntLE(message.orderCancelledReturnBitfield3[1], 1))
        \o (IF message.orderCancelledReturnBitfield4 = << >> THEN << >> ELSE message.orderCancelledReturnBitfield4[1])
        \o (IF message.orderCancelledReturnBitfield5 = << >> THEN << >> ELSE EncodeUIntLE(message.orderCancelledReturnBitfield5[1], 1))
        \o (IF message.orderCancelledReturnBitfield6 = << >> THEN << >> ELSE EncodeUIntLE(message.orderCancelledReturnBitfield6[1], 1))
        \o (IF message.orderCancelledReturnBitfield7 = << >> THEN << >> ELSE message.orderCancelledReturnBitfield7[1])
        \o (IF message.orderCancelledReturnBitfield8 = << >> THEN << >> ELSE EncodeUIntLE(message.orderCancelledReturnBitfield8[1], 1))
        \o (IF message.orderCancelledReturnBitfield9 = << >> THEN << >> ELSE message.orderCancelledReturnBitfield9[1])
        \o (IF message.orderCancelledReturnBitfield10 = << >> THEN << >> ELSE message.orderCancelledReturnBitfield10[1])
        \o (IF message.orderCancelledReturnBitfield11 = << >> THEN << >> ELSE message.orderCancelledReturnBitfield11[1])
        \o (IF message.orderCancelledReturnBitfield12 = << >> THEN << >> ELSE message.orderCancelledReturnBitfield12[1])
        \o (IF message.orderCancelledReturnBitfield13 = << >> THEN << >> ELSE message.orderCancelledReturnBitfield13[1])
        \o (IF message.orderCancelledReturnBitfield14 = << >> THEN << >> ELSE message.orderCancelledReturnBitfield14[1])
        \o (IF message.orderCancelledReturnBitfield15 = << >> THEN << >> ELSE message.orderCancelledReturnBitfield15[1])
        \o (IF message.orderCancelledReturnBitfield16 = << >> THEN << >> ELSE message.orderCancelledReturnBitfield16[1])
        \o (IF message.orderCancelledReturnBitfield17 = << >> THEN << >> ELSE message.orderCancelledReturnBitfield17[1])
        \o (IF message.orderCancelledReturnBitfield18 = << >> THEN << >> ELSE EncodeUIntLE(message.orderCancelledReturnBitfield18[1], 1))
        \o (IF message.orderCancelledReturnBitfield19 = << >> THEN << >> ELSE message.orderCancelledReturnBitfield19[1])
        \o (IF message.orderCancelledReturnBitfield20 = << >> THEN << >> ELSE message.orderCancelledReturnBitfield20[1])
        \o (IF message.orderCancelledReturnBitfield21 = << >> THEN << >> ELSE message.orderCancelledReturnBitfield21[1])
        \o (IF message.orderCancelledReturnBitfield22 = << >> THEN << >> ELSE message.orderCancelledReturnBitfield22[1])
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
    LET orderCancelledReturnBitfield1 == ReadWhen(numberOfReturnBitfields.value >= 1, ReadUIntLE(numberOfReturnBitfields.rest, 1), numberOfReturnBitfields.rest) IN IF ~orderCancelledReturnBitfield1.ok THEN Fail ELSE
    LET orderCancelledReturnBitfield2 == ReadWhen(numberOfReturnBitfields.value >= 2, ReadUIntLE(orderCancelledReturnBitfield1.rest, 1), orderCancelledReturnBitfield1.rest) IN IF ~orderCancelledReturnBitfield2.ok THEN Fail ELSE
    LET orderCancelledReturnBitfield3 == ReadWhen(numberOfReturnBitfields.value >= 3, ReadUIntLE(orderCancelledReturnBitfield2.rest, 1), orderCancelledReturnBitfield2.rest) IN IF ~orderCancelledReturnBitfield3.ok THEN Fail ELSE
    LET orderCancelledReturnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadBytes(orderCancelledReturnBitfield3.rest, 1), orderCancelledReturnBitfield3.rest) IN IF ~orderCancelledReturnBitfield4.ok THEN Fail ELSE
    LET orderCancelledReturnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadUIntLE(orderCancelledReturnBitfield4.rest, 1), orderCancelledReturnBitfield4.rest) IN IF ~orderCancelledReturnBitfield5.ok THEN Fail ELSE
    LET orderCancelledReturnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadUIntLE(orderCancelledReturnBitfield5.rest, 1), orderCancelledReturnBitfield5.rest) IN IF ~orderCancelledReturnBitfield6.ok THEN Fail ELSE
    LET orderCancelledReturnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadBytes(orderCancelledReturnBitfield6.rest, 1), orderCancelledReturnBitfield6.rest) IN IF ~orderCancelledReturnBitfield7.ok THEN Fail ELSE
    LET orderCancelledReturnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadUIntLE(orderCancelledReturnBitfield7.rest, 1), orderCancelledReturnBitfield7.rest) IN IF ~orderCancelledReturnBitfield8.ok THEN Fail ELSE
    LET orderCancelledReturnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadBytes(orderCancelledReturnBitfield8.rest, 1), orderCancelledReturnBitfield8.rest) IN IF ~orderCancelledReturnBitfield9.ok THEN Fail ELSE
    LET orderCancelledReturnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadBytes(orderCancelledReturnBitfield9.rest, 1), orderCancelledReturnBitfield9.rest) IN IF ~orderCancelledReturnBitfield10.ok THEN Fail ELSE
    LET orderCancelledReturnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadBytes(orderCancelledReturnBitfield10.rest, 1), orderCancelledReturnBitfield10.rest) IN IF ~orderCancelledReturnBitfield11.ok THEN Fail ELSE
    LET orderCancelledReturnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadBytes(orderCancelledReturnBitfield11.rest, 1), orderCancelledReturnBitfield11.rest) IN IF ~orderCancelledReturnBitfield12.ok THEN Fail ELSE
    LET orderCancelledReturnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(orderCancelledReturnBitfield12.rest, 1), orderCancelledReturnBitfield12.rest) IN IF ~orderCancelledReturnBitfield13.ok THEN Fail ELSE
    LET orderCancelledReturnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(orderCancelledReturnBitfield13.rest, 1), orderCancelledReturnBitfield13.rest) IN IF ~orderCancelledReturnBitfield14.ok THEN Fail ELSE
    LET orderCancelledReturnBitfield15 == ReadWhen(numberOfReturnBitfields.value >= 15, ReadBytes(orderCancelledReturnBitfield14.rest, 1), orderCancelledReturnBitfield14.rest) IN IF ~orderCancelledReturnBitfield15.ok THEN Fail ELSE
    LET orderCancelledReturnBitfield16 == ReadWhen(numberOfReturnBitfields.value >= 16, ReadBytes(orderCancelledReturnBitfield15.rest, 1), orderCancelledReturnBitfield15.rest) IN IF ~orderCancelledReturnBitfield16.ok THEN Fail ELSE
    LET orderCancelledReturnBitfield17 == ReadWhen(numberOfReturnBitfields.value >= 17, ReadBytes(orderCancelledReturnBitfield16.rest, 1), orderCancelledReturnBitfield16.rest) IN IF ~orderCancelledReturnBitfield17.ok THEN Fail ELSE
    LET orderCancelledReturnBitfield18 == ReadWhen(numberOfReturnBitfields.value >= 18, ReadUIntLE(orderCancelledReturnBitfield17.rest, 1), orderCancelledReturnBitfield17.rest) IN IF ~orderCancelledReturnBitfield18.ok THEN Fail ELSE
    LET orderCancelledReturnBitfield19 == ReadWhen(numberOfReturnBitfields.value >= 19, ReadBytes(orderCancelledReturnBitfield18.rest, 1), orderCancelledReturnBitfield18.rest) IN IF ~orderCancelledReturnBitfield19.ok THEN Fail ELSE
    LET orderCancelledReturnBitfield20 == ReadWhen(numberOfReturnBitfields.value >= 20, ReadBytes(orderCancelledReturnBitfield19.rest, 1), orderCancelledReturnBitfield19.rest) IN IF ~orderCancelledReturnBitfield20.ok THEN Fail ELSE
    LET orderCancelledReturnBitfield21 == ReadWhen(numberOfReturnBitfields.value >= 21, ReadBytes(orderCancelledReturnBitfield20.rest, 1), orderCancelledReturnBitfield20.rest) IN IF ~orderCancelledReturnBitfield21.ok THEN Fail ELSE
    LET orderCancelledReturnBitfield22 == ReadWhen(numberOfReturnBitfields.value >= 22, ReadBytes(orderCancelledReturnBitfield21.rest, 1), orderCancelledReturnBitfield21.rest) IN IF ~orderCancelledReturnBitfield22.ok THEN Fail ELSE
    LET side == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderCancelledReturnBitfield1.value # << >> /\ orderCancelledReturnBitfield1.value[1] % 2 > 0), ReadBytes(orderCancelledReturnBitfield22.rest, 1), orderCancelledReturnBitfield22.rest) IN IF ~side.ok THEN Fail ELSE
    LET pegDifference == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderCancelledReturnBitfield1.value # << >> /\ (orderCancelledReturnBitfield1.value[1] \div 2) % 2 > 0), ReadBytes(side.rest, 8), side.rest) IN IF ~pegDifference.ok THEN Fail ELSE
    LET price == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderCancelledReturnBitfield1.value # << >> /\ (orderCancelledReturnBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(pegDifference.rest, 8), pegDifference.rest) IN IF ~price.ok THEN Fail ELSE
    LET execInst == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderCancelledReturnBitfield1.value # << >> /\ (orderCancelledReturnBitfield1.value[1] \div 8) % 2 > 0), ReadBytes(price.rest, 1), price.rest) IN IF ~execInst.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderCancelledReturnBitfield1.value # << >> /\ (orderCancelledReturnBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(execInst.rest, 1), execInst.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderCancelledReturnBitfield1.value # << >> /\ (orderCancelledReturnBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderCancelledReturnBitfield1.value # << >> /\ (orderCancelledReturnBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET symbol == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderCancelledReturnBitfield2.value # << >> /\ orderCancelledReturnBitfield2.value[1] % 2 > 0), ReadBytes(minQty.rest, 8), minQty.rest) IN IF ~symbol.ok THEN Fail ELSE
    LET symbolSfx == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderCancelledReturnBitfield2.value # << >> /\ (orderCancelledReturnBitfield2.value[1] \div 2) % 2 > 0), ReadBytes(symbol.rest, 8), symbol.rest) IN IF ~symbolSfx.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderCancelledReturnBitfield2.value # << >> /\ (orderCancelledReturnBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(symbolSfx.rest, 1), symbolSfx.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderCancelledReturnBitfield3.value # << >> /\ orderCancelledReturnBitfield3.value[1] % 2 > 0), ReadBytes(capacity.rest, 16), capacity.rest) IN IF ~account.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderCancelledReturnBitfield3.value # << >> /\ (orderCancelledReturnBitfield3.value[1] \div 2) % 2 > 0), ReadBytes(account.rest, 4), account.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderCancelledReturnBitfield3.value # << >> /\ (orderCancelledReturnBitfield3.value[1] \div 4) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET displayIndicator == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderCancelledReturnBitfield3.value # << >> /\ (orderCancelledReturnBitfield3.value[1] \div 8) % 2 > 0), ReadBytes(clearingAccount.rest, 1), clearingAccount.rest) IN IF ~displayIndicator.ok THEN Fail ELSE
    LET maxFloor == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderCancelledReturnBitfield3.value # << >> /\ (orderCancelledReturnBitfield3.value[1] \div 16) % 2 > 0), ReadBytes(displayIndicator.rest, 4), displayIndicator.rest) IN IF ~maxFloor.ok THEN Fail ELSE
    LET discretionAmount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderCancelledReturnBitfield3.value # << >> /\ (orderCancelledReturnBitfield3.value[1] \div 32) % 2 > 0), ReadBytes(maxFloor.rest, 2), maxFloor.rest) IN IF ~discretionAmount.ok THEN Fail ELSE
    LET orderQty == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderCancelledReturnBitfield3.value # << >> /\ (orderCancelledReturnBitfield3.value[1] \div 64) % 2 > 0), ReadBytes(discretionAmount.rest, 4), discretionAmount.rest) IN IF ~orderQty.ok THEN Fail ELSE
    LET preventMatch == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderCancelledReturnBitfield3.value # << >> /\ (orderCancelledReturnBitfield3.value[1] \div 128) % 2 > 0), ReadBytes(orderQty.rest, 3), orderQty.rest) IN IF ~preventMatch.ok THEN Fail ELSE
    LET origClOrdId == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderCancelledReturnBitfield5.value # << >> /\ orderCancelledReturnBitfield5.value[1] % 2 > 0), ReadBytes(preventMatch.rest, 20), preventMatch.rest) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET leavesQty == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderCancelledReturnBitfield5.value # << >> /\ (orderCancelledReturnBitfield5.value[1] \div 2) % 2 > 0), ReadBytes(origClOrdId.rest, 4), origClOrdId.rest) IN IF ~leavesQty.ok THEN Fail ELSE
    LET lastShares == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderCancelledReturnBitfield5.value # << >> /\ (orderCancelledReturnBitfield5.value[1] \div 4) % 2 > 0), ReadBytes(leavesQty.rest, 4), leavesQty.rest) IN IF ~lastShares.ok THEN Fail ELSE
    LET lastPx == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderCancelledReturnBitfield5.value # << >> /\ (orderCancelledReturnBitfield5.value[1] \div 8) % 2 > 0), ReadBytes(lastShares.rest, 8), lastShares.rest) IN IF ~lastPx.ok THEN Fail ELSE
    LET displayPrice == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderCancelledReturnBitfield5.value # << >> /\ (orderCancelledReturnBitfield5.value[1] \div 16) % 2 > 0), ReadBytes(lastPx.rest, 8), lastPx.rest) IN IF ~displayPrice.ok THEN Fail ELSE
    LET workingPrice == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderCancelledReturnBitfield5.value # << >> /\ (orderCancelledReturnBitfield5.value[1] \div 32) % 2 > 0), ReadBytes(displayPrice.rest, 8), displayPrice.rest) IN IF ~workingPrice.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderCancelledReturnBitfield5.value # << >> /\ (orderCancelledReturnBitfield5.value[1] \div 64) % 2 > 0), ReadBytes(workingPrice.rest, 1), workingPrice.rest) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET expireTime == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderCancelledReturnBitfield5.value # << >> /\ (orderCancelledReturnBitfield5.value[1] \div 128) % 2 > 0), ReadBytes(baseLiquidityIndicator.rest, 8), baseLiquidityIndicator.rest) IN IF ~expireTime.ok THEN Fail ELSE
    LET secondaryOrderId == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (orderCancelledReturnBitfield6.value # << >> /\ orderCancelledReturnBitfield6.value[1] % 2 > 0), ReadBytes(expireTime.rest, 8), expireTime.rest) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET attributedQuote == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (orderCancelledReturnBitfield6.value # << >> /\ (orderCancelledReturnBitfield6.value[1] \div 8) % 2 > 0), ReadBytes(secondaryOrderId.rest, 1), secondaryOrderId.rest) IN IF ~attributedQuote.ok THEN Fail ELSE
    LET extExecInst == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (orderCancelledReturnBitfield6.value # << >> /\ (orderCancelledReturnBitfield6.value[1] \div 16) % 2 > 0), ReadBytes(attributedQuote.rest, 1), attributedQuote.rest) IN IF ~extExecInst.ok THEN Fail ELSE
    LET echoText == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderCancelledReturnBitfield8.value # << >> /\ (orderCancelledReturnBitfield8.value[1] \div 2) % 2 > 0), ReadBytes(extExecInst.rest, 64), extExecInst.rest) IN IF ~echoText.ok THEN Fail ELSE
    LET stopPx == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderCancelledReturnBitfield8.value # << >> /\ (orderCancelledReturnBitfield8.value[1] \div 4) % 2 > 0), ReadBytes(echoText.rest, 8), echoText.rest) IN IF ~stopPx.ok THEN Fail ELSE
    LET routingInst == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderCancelledReturnBitfield8.value # << >> /\ (orderCancelledReturnBitfield8.value[1] \div 8) % 2 > 0), ReadBytes(stopPx.rest, 4), stopPx.rest) IN IF ~routingInst.ok THEN Fail ELSE
    LET routStrategy == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderCancelledReturnBitfield8.value # << >> /\ (orderCancelledReturnBitfield8.value[1] \div 16) % 2 > 0), ReadBytes(routingInst.rest, 6), routingInst.rest) IN IF ~routStrategy.ok THEN Fail ELSE
    LET routeDeliveryMethod == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderCancelledReturnBitfield8.value # << >> /\ (orderCancelledReturnBitfield8.value[1] \div 32) % 2 > 0), ReadBytes(routStrategy.rest, 3), routStrategy.rest) IN IF ~routeDeliveryMethod.ok THEN Fail ELSE
    LET exDestination == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderCancelledReturnBitfield8.value # << >> /\ (orderCancelledReturnBitfield8.value[1] \div 64) % 2 > 0), ReadBytes(routeDeliveryMethod.rest, 1), routeDeliveryMethod.rest) IN IF ~exDestination.ok THEN Fail ELSE
    LET crossTradeFlag == ReadWhen(numberOfReturnBitfields.value >= 18 /\ (orderCancelledReturnBitfield18.value # << >> /\ (orderCancelledReturnBitfield18.value[1] \div 8) % 2 > 0), ReadBytes(exDestination.rest, 1), exDestination.rest) IN IF ~crossTradeFlag.ok THEN Fail ELSE
    Ok([ transactionTime                |-> transactionTime.value,
         clOrdId                        |-> clOrdId.value,
         cancelReason                   |-> cancelReason.value,
         reserved1                      |-> reserved1.value,
         numberOfReturnBitfields        |-> numberOfReturnBitfields.value,
         orderCancelledReturnBitfield1  |-> orderCancelledReturnBitfield1.value,
         orderCancelledReturnBitfield2  |-> orderCancelledReturnBitfield2.value,
         orderCancelledReturnBitfield3  |-> orderCancelledReturnBitfield3.value,
         orderCancelledReturnBitfield4  |-> orderCancelledReturnBitfield4.value,
         orderCancelledReturnBitfield5  |-> orderCancelledReturnBitfield5.value,
         orderCancelledReturnBitfield6  |-> orderCancelledReturnBitfield6.value,
         orderCancelledReturnBitfield7  |-> orderCancelledReturnBitfield7.value,
         orderCancelledReturnBitfield8  |-> orderCancelledReturnBitfield8.value,
         orderCancelledReturnBitfield9  |-> orderCancelledReturnBitfield9.value,
         orderCancelledReturnBitfield10 |-> orderCancelledReturnBitfield10.value,
         orderCancelledReturnBitfield11 |-> orderCancelledReturnBitfield11.value,
         orderCancelledReturnBitfield12 |-> orderCancelledReturnBitfield12.value,
         orderCancelledReturnBitfield13 |-> orderCancelledReturnBitfield13.value,
         orderCancelledReturnBitfield14 |-> orderCancelledReturnBitfield14.value,
         orderCancelledReturnBitfield15 |-> orderCancelledReturnBitfield15.value,
         orderCancelledReturnBitfield16 |-> orderCancelledReturnBitfield16.value,
         orderCancelledReturnBitfield17 |-> orderCancelledReturnBitfield17.value,
         orderCancelledReturnBitfield18 |-> orderCancelledReturnBitfield18.value,
         orderCancelledReturnBitfield19 |-> orderCancelledReturnBitfield19.value,
         orderCancelledReturnBitfield20 |-> orderCancelledReturnBitfield20.value,
         orderCancelledReturnBitfield21 |-> orderCancelledReturnBitfield21.value,
         orderCancelledReturnBitfield22 |-> orderCancelledReturnBitfield22.value,
         side                           |-> side.value,
         pegDifference                  |-> pegDifference.value,
         price                          |-> price.value,
         execInst                       |-> execInst.value,
         ordType                        |-> ordType.value,
         timeInForce                    |-> timeInForce.value,
         minQty                         |-> minQty.value,
         symbol                         |-> symbol.value,
         symbolSfx                      |-> symbolSfx.value,
         capacity                       |-> capacity.value,
         account                        |-> account.value,
         clearingFirm                   |-> clearingFirm.value,
         clearingAccount                |-> clearingAccount.value,
         displayIndicator               |-> displayIndicator.value,
         maxFloor                       |-> maxFloor.value,
         discretionAmount               |-> discretionAmount.value,
         orderQty                       |-> orderQty.value,
         preventMatch                   |-> preventMatch.value,
         origClOrdId                    |-> origClOrdId.value,
         leavesQty                      |-> leavesQty.value,
         lastShares                     |-> lastShares.value,
         lastPx                         |-> lastPx.value,
         displayPrice                   |-> displayPrice.value,
         workingPrice                   |-> workingPrice.value,
         baseLiquidityIndicator         |-> baseLiquidityIndicator.value,
         expireTime                     |-> expireTime.value,
         secondaryOrderId               |-> secondaryOrderId.value,
         attributedQuote                |-> attributedQuote.value,
         extExecInst                    |-> extExecInst.value,
         echoText                       |-> echoText.value,
         stopPx                         |-> stopPx.value,
         routingInst                    |-> routingInst.value,
         routStrategy                   |-> routStrategy.value,
         routeDeliveryMethod            |-> routeDeliveryMethod.value,
         exDestination                  |-> exDestination.value,
         crossTradeFlag                 |-> crossTradeFlag.value ], crossTradeFlag.rest)

(* Order Cancelled Message with each field marked present by fields before it there exactly where they say *)
SettleOrderCancelledMessage(message) ==
    LET settled1 == [message EXCEPT !.orderCancelledReturnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.orderCancelledReturnBitfield1 = << >> THEN <<0>> ELSE message.orderCancelledReturnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.orderCancelledReturnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.orderCancelledReturnBitfield2 = << >> THEN <<0>> ELSE settled1.orderCancelledReturnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.orderCancelledReturnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.orderCancelledReturnBitfield3 = << >> THEN <<0>> ELSE settled2.orderCancelledReturnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.orderCancelledReturnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.orderCancelledReturnBitfield4 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled3.orderCancelledReturnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.orderCancelledReturnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.orderCancelledReturnBitfield5 = << >> THEN <<0>> ELSE settled4.orderCancelledReturnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.orderCancelledReturnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.orderCancelledReturnBitfield6 = << >> THEN <<0>> ELSE settled5.orderCancelledReturnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.orderCancelledReturnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.orderCancelledReturnBitfield7 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.orderCancelledReturnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.orderCancelledReturnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.orderCancelledReturnBitfield8 = << >> THEN <<0>> ELSE settled7.orderCancelledReturnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.orderCancelledReturnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.orderCancelledReturnBitfield9 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled8.orderCancelledReturnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.orderCancelledReturnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.orderCancelledReturnBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.orderCancelledReturnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.orderCancelledReturnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.orderCancelledReturnBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.orderCancelledReturnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.orderCancelledReturnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.orderCancelledReturnBitfield12 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.orderCancelledReturnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.orderCancelledReturnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.orderCancelledReturnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.orderCancelledReturnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.orderCancelledReturnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.orderCancelledReturnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.orderCancelledReturnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.orderCancelledReturnBitfield15 = IF settled14.numberOfReturnBitfields >= 15 THEN (IF settled14.orderCancelledReturnBitfield15 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.orderCancelledReturnBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.orderCancelledReturnBitfield16 = IF settled15.numberOfReturnBitfields >= 16 THEN (IF settled15.orderCancelledReturnBitfield16 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled15.orderCancelledReturnBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.orderCancelledReturnBitfield17 = IF settled16.numberOfReturnBitfields >= 17 THEN (IF settled16.orderCancelledReturnBitfield17 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled16.orderCancelledReturnBitfield17) ELSE << >>]
        settled18 == [settled17 EXCEPT !.orderCancelledReturnBitfield18 = IF settled17.numberOfReturnBitfields >= 18 THEN (IF settled17.orderCancelledReturnBitfield18 = << >> THEN <<0>> ELSE settled17.orderCancelledReturnBitfield18) ELSE << >>]
        settled19 == [settled18 EXCEPT !.orderCancelledReturnBitfield19 = IF settled18.numberOfReturnBitfields >= 19 THEN (IF settled18.orderCancelledReturnBitfield19 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled18.orderCancelledReturnBitfield19) ELSE << >>]
        settled20 == [settled19 EXCEPT !.orderCancelledReturnBitfield20 = IF settled19.numberOfReturnBitfields >= 20 THEN (IF settled19.orderCancelledReturnBitfield20 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled19.orderCancelledReturnBitfield20) ELSE << >>]
        settled21 == [settled20 EXCEPT !.orderCancelledReturnBitfield21 = IF settled20.numberOfReturnBitfields >= 21 THEN (IF settled20.orderCancelledReturnBitfield21 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled20.orderCancelledReturnBitfield21) ELSE << >>]
        settled22 == [settled21 EXCEPT !.orderCancelledReturnBitfield22 = IF settled21.numberOfReturnBitfields >= 22 THEN (IF settled21.orderCancelledReturnBitfield22 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled21.orderCancelledReturnBitfield22) ELSE << >>]
        settled23 == [settled22 EXCEPT !.side = IF settled22.numberOfReturnBitfields >= 1 /\ (settled22.orderCancelledReturnBitfield1 # << >> /\ settled22.orderCancelledReturnBitfield1[1] % 2 > 0) THEN (IF settled22.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled22.side) ELSE << >>]
        settled24 == [settled23 EXCEPT !.pegDifference = IF settled23.numberOfReturnBitfields >= 1 /\ (settled23.orderCancelledReturnBitfield1 # << >> /\ (settled23.orderCancelledReturnBitfield1[1] \div 2) % 2 > 0) THEN (IF settled23.pegDifference = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled23.pegDifference) ELSE << >>]
        settled25 == [settled24 EXCEPT !.price = IF settled24.numberOfReturnBitfields >= 1 /\ (settled24.orderCancelledReturnBitfield1 # << >> /\ (settled24.orderCancelledReturnBitfield1[1] \div 4) % 2 > 0) THEN (IF settled24.price = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled24.price) ELSE << >>]
        settled26 == [settled25 EXCEPT !.execInst = IF settled25.numberOfReturnBitfields >= 1 /\ (settled25.orderCancelledReturnBitfield1 # << >> /\ (settled25.orderCancelledReturnBitfield1[1] \div 8) % 2 > 0) THEN (IF settled25.execInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled25.execInst) ELSE << >>]
        settled27 == [settled26 EXCEPT !.ordType = IF settled26.numberOfReturnBitfields >= 1 /\ (settled26.orderCancelledReturnBitfield1 # << >> /\ (settled26.orderCancelledReturnBitfield1[1] \div 16) % 2 > 0) THEN (IF settled26.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled26.ordType) ELSE << >>]
        settled28 == [settled27 EXCEPT !.timeInForce = IF settled27.numberOfReturnBitfields >= 1 /\ (settled27.orderCancelledReturnBitfield1 # << >> /\ (settled27.orderCancelledReturnBitfield1[1] \div 32) % 2 > 0) THEN (IF settled27.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled27.timeInForce) ELSE << >>]
        settled29 == [settled28 EXCEPT !.minQty = IF settled28.numberOfReturnBitfields >= 1 /\ (settled28.orderCancelledReturnBitfield1 # << >> /\ (settled28.orderCancelledReturnBitfield1[1] \div 64) % 2 > 0) THEN (IF settled28.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled28.minQty) ELSE << >>]
        settled30 == [settled29 EXCEPT !.symbol = IF settled29.numberOfReturnBitfields >= 2 /\ (settled29.orderCancelledReturnBitfield2 # << >> /\ settled29.orderCancelledReturnBitfield2[1] % 2 > 0) THEN (IF settled29.symbol = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled29.symbol) ELSE << >>]
        settled31 == [settled30 EXCEPT !.symbolSfx = IF settled30.numberOfReturnBitfields >= 2 /\ (settled30.orderCancelledReturnBitfield2 # << >> /\ (settled30.orderCancelledReturnBitfield2[1] \div 2) % 2 > 0) THEN (IF settled30.symbolSfx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled30.symbolSfx) ELSE << >>]
        settled32 == [settled31 EXCEPT !.capacity = IF settled31.numberOfReturnBitfields >= 2 /\ (settled31.orderCancelledReturnBitfield2 # << >> /\ (settled31.orderCancelledReturnBitfield2[1] \div 64) % 2 > 0) THEN (IF settled31.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled31.capacity) ELSE << >>]
        settled33 == [settled32 EXCEPT !.account = IF settled32.numberOfReturnBitfields >= 3 /\ (settled32.orderCancelledReturnBitfield3 # << >> /\ settled32.orderCancelledReturnBitfield3[1] % 2 > 0) THEN (IF settled32.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled32.account) ELSE << >>]
        settled34 == [settled33 EXCEPT !.clearingFirm = IF settled33.numberOfReturnBitfields >= 3 /\ (settled33.orderCancelledReturnBitfield3 # << >> /\ (settled33.orderCancelledReturnBitfield3[1] \div 2) % 2 > 0) THEN (IF settled33.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled33.clearingFirm) ELSE << >>]
        settled35 == [settled34 EXCEPT !.clearingAccount = IF settled34.numberOfReturnBitfields >= 3 /\ (settled34.orderCancelledReturnBitfield3 # << >> /\ (settled34.orderCancelledReturnBitfield3[1] \div 4) % 2 > 0) THEN (IF settled34.clearingAccount = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled34.clearingAccount) ELSE << >>]
        settled36 == [settled35 EXCEPT !.displayIndicator = IF settled35.numberOfReturnBitfields >= 3 /\ (settled35.orderCancelledReturnBitfield3 # << >> /\ (settled35.orderCancelledReturnBitfield3[1] \div 8) % 2 > 0) THEN (IF settled35.displayIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled35.displayIndicator) ELSE << >>]
        settled37 == [settled36 EXCEPT !.maxFloor = IF settled36.numberOfReturnBitfields >= 3 /\ (settled36.orderCancelledReturnBitfield3 # << >> /\ (settled36.orderCancelledReturnBitfield3[1] \div 16) % 2 > 0) THEN (IF settled36.maxFloor = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled36.maxFloor) ELSE << >>]
        settled38 == [settled37 EXCEPT !.discretionAmount = IF settled37.numberOfReturnBitfields >= 3 /\ (settled37.orderCancelledReturnBitfield3 # << >> /\ (settled37.orderCancelledReturnBitfield3[1] \div 32) % 2 > 0) THEN (IF settled37.discretionAmount = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled37.discretionAmount) ELSE << >>]
        settled39 == [settled38 EXCEPT !.orderQty = IF settled38.numberOfReturnBitfields >= 3 /\ (settled38.orderCancelledReturnBitfield3 # << >> /\ (settled38.orderCancelledReturnBitfield3[1] \div 64) % 2 > 0) THEN (IF settled38.orderQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled38.orderQty) ELSE << >>]
        settled40 == [settled39 EXCEPT !.preventMatch = IF settled39.numberOfReturnBitfields >= 3 /\ (settled39.orderCancelledReturnBitfield3 # << >> /\ (settled39.orderCancelledReturnBitfield3[1] \div 128) % 2 > 0) THEN (IF settled39.preventMatch = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled39.preventMatch) ELSE << >>]
        settled41 == [settled40 EXCEPT !.origClOrdId = IF settled40.numberOfReturnBitfields >= 5 /\ (settled40.orderCancelledReturnBitfield5 # << >> /\ settled40.orderCancelledReturnBitfield5[1] % 2 > 0) THEN (IF settled40.origClOrdId = << >> THEN <<[i \in 1 .. 20 |-> 0]>> ELSE settled40.origClOrdId) ELSE << >>]
        settled42 == [settled41 EXCEPT !.leavesQty = IF settled41.numberOfReturnBitfields >= 5 /\ (settled41.orderCancelledReturnBitfield5 # << >> /\ (settled41.orderCancelledReturnBitfield5[1] \div 2) % 2 > 0) THEN (IF settled41.leavesQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled41.leavesQty) ELSE << >>]
        settled43 == [settled42 EXCEPT !.lastShares = IF settled42.numberOfReturnBitfields >= 5 /\ (settled42.orderCancelledReturnBitfield5 # << >> /\ (settled42.orderCancelledReturnBitfield5[1] \div 4) % 2 > 0) THEN (IF settled42.lastShares = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled42.lastShares) ELSE << >>]
        settled44 == [settled43 EXCEPT !.lastPx = IF settled43.numberOfReturnBitfields >= 5 /\ (settled43.orderCancelledReturnBitfield5 # << >> /\ (settled43.orderCancelledReturnBitfield5[1] \div 8) % 2 > 0) THEN (IF settled43.lastPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled43.lastPx) ELSE << >>]
        settled45 == [settled44 EXCEPT !.displayPrice = IF settled44.numberOfReturnBitfields >= 5 /\ (settled44.orderCancelledReturnBitfield5 # << >> /\ (settled44.orderCancelledReturnBitfield5[1] \div 16) % 2 > 0) THEN (IF settled44.displayPrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled44.displayPrice) ELSE << >>]
        settled46 == [settled45 EXCEPT !.workingPrice = IF settled45.numberOfReturnBitfields >= 5 /\ (settled45.orderCancelledReturnBitfield5 # << >> /\ (settled45.orderCancelledReturnBitfield5[1] \div 32) % 2 > 0) THEN (IF settled45.workingPrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled45.workingPrice) ELSE << >>]
        settled47 == [settled46 EXCEPT !.baseLiquidityIndicator = IF settled46.numberOfReturnBitfields >= 5 /\ (settled46.orderCancelledReturnBitfield5 # << >> /\ (settled46.orderCancelledReturnBitfield5[1] \div 64) % 2 > 0) THEN (IF settled46.baseLiquidityIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled46.baseLiquidityIndicator) ELSE << >>]
        settled48 == [settled47 EXCEPT !.expireTime = IF settled47.numberOfReturnBitfields >= 5 /\ (settled47.orderCancelledReturnBitfield5 # << >> /\ (settled47.orderCancelledReturnBitfield5[1] \div 128) % 2 > 0) THEN (IF settled47.expireTime = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled47.expireTime) ELSE << >>]
        settled49 == [settled48 EXCEPT !.secondaryOrderId = IF settled48.numberOfReturnBitfields >= 6 /\ (settled48.orderCancelledReturnBitfield6 # << >> /\ settled48.orderCancelledReturnBitfield6[1] % 2 > 0) THEN (IF settled48.secondaryOrderId = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled48.secondaryOrderId) ELSE << >>]
        settled50 == [settled49 EXCEPT !.attributedQuote = IF settled49.numberOfReturnBitfields >= 6 /\ (settled49.orderCancelledReturnBitfield6 # << >> /\ (settled49.orderCancelledReturnBitfield6[1] \div 8) % 2 > 0) THEN (IF settled49.attributedQuote = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled49.attributedQuote) ELSE << >>]
        settled51 == [settled50 EXCEPT !.extExecInst = IF settled50.numberOfReturnBitfields >= 6 /\ (settled50.orderCancelledReturnBitfield6 # << >> /\ (settled50.orderCancelledReturnBitfield6[1] \div 16) % 2 > 0) THEN (IF settled50.extExecInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled50.extExecInst) ELSE << >>]
        settled52 == [settled51 EXCEPT !.echoText = IF settled51.numberOfReturnBitfields >= 8 /\ (settled51.orderCancelledReturnBitfield8 # << >> /\ (settled51.orderCancelledReturnBitfield8[1] \div 2) % 2 > 0) THEN (IF settled51.echoText = << >> THEN <<[i \in 1 .. 64 |-> 0]>> ELSE settled51.echoText) ELSE << >>]
        settled53 == [settled52 EXCEPT !.stopPx = IF settled52.numberOfReturnBitfields >= 8 /\ (settled52.orderCancelledReturnBitfield8 # << >> /\ (settled52.orderCancelledReturnBitfield8[1] \div 4) % 2 > 0) THEN (IF settled52.stopPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled52.stopPx) ELSE << >>]
        settled54 == [settled53 EXCEPT !.routingInst = IF settled53.numberOfReturnBitfields >= 8 /\ (settled53.orderCancelledReturnBitfield8 # << >> /\ (settled53.orderCancelledReturnBitfield8[1] \div 8) % 2 > 0) THEN (IF settled53.routingInst = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled53.routingInst) ELSE << >>]
        settled55 == [settled54 EXCEPT !.routStrategy = IF settled54.numberOfReturnBitfields >= 8 /\ (settled54.orderCancelledReturnBitfield8 # << >> /\ (settled54.orderCancelledReturnBitfield8[1] \div 16) % 2 > 0) THEN (IF settled54.routStrategy = << >> THEN <<[i \in 1 .. 6 |-> 0]>> ELSE settled54.routStrategy) ELSE << >>]
        settled56 == [settled55 EXCEPT !.routeDeliveryMethod = IF settled55.numberOfReturnBitfields >= 8 /\ (settled55.orderCancelledReturnBitfield8 # << >> /\ (settled55.orderCancelledReturnBitfield8[1] \div 32) % 2 > 0) THEN (IF settled55.routeDeliveryMethod = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled55.routeDeliveryMethod) ELSE << >>]
        settled57 == [settled56 EXCEPT !.exDestination = IF settled56.numberOfReturnBitfields >= 8 /\ (settled56.orderCancelledReturnBitfield8 # << >> /\ (settled56.orderCancelledReturnBitfield8[1] \div 64) % 2 > 0) THEN (IF settled56.exDestination = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled56.exDestination) ELSE << >>]
        settled58 == [settled57 EXCEPT !.crossTradeFlag = IF settled57.numberOfReturnBitfields >= 18 /\ (settled57.orderCancelledReturnBitfield18 # << >> /\ (settled57.orderCancelledReturnBitfield18[1] \div 8) % 2 > 0) THEN (IF settled57.crossTradeFlag = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled57.crossTradeFlag) ELSE << >>]
    IN  settled58

ZeroOrderCancelledMessage ==
    SettleOrderCancelledMessage([ transactionTime                |-> [i \in 1 .. 8 |-> 0],
                                  clOrdId                        |-> [i \in 1 .. 20 |-> 0],
                                  cancelReason                   |-> [i \in 1 .. 1 |-> 0],
                                  reserved1                      |-> [i \in 1 .. 1 |-> 0],
                                  numberOfReturnBitfields        |-> 0,
                                  orderCancelledReturnBitfield1  |-> << >>,
                                  orderCancelledReturnBitfield2  |-> << >>,
                                  orderCancelledReturnBitfield3  |-> << >>,
                                  orderCancelledReturnBitfield4  |-> << >>,
                                  orderCancelledReturnBitfield5  |-> << >>,
                                  orderCancelledReturnBitfield6  |-> << >>,
                                  orderCancelledReturnBitfield7  |-> << >>,
                                  orderCancelledReturnBitfield8  |-> << >>,
                                  orderCancelledReturnBitfield9  |-> << >>,
                                  orderCancelledReturnBitfield10 |-> << >>,
                                  orderCancelledReturnBitfield11 |-> << >>,
                                  orderCancelledReturnBitfield12 |-> << >>,
                                  orderCancelledReturnBitfield13 |-> << >>,
                                  orderCancelledReturnBitfield14 |-> << >>,
                                  orderCancelledReturnBitfield15 |-> << >>,
                                  orderCancelledReturnBitfield16 |-> << >>,
                                  orderCancelledReturnBitfield17 |-> << >>,
                                  orderCancelledReturnBitfield18 |-> << >>,
                                  orderCancelledReturnBitfield19 |-> << >>,
                                  orderCancelledReturnBitfield20 |-> << >>,
                                  orderCancelledReturnBitfield21 |-> << >>,
                                  orderCancelledReturnBitfield22 |-> << >>,
                                  side                           |-> << >>,
                                  pegDifference                  |-> << >>,
                                  price                          |-> << >>,
                                  execInst                       |-> << >>,
                                  ordType                        |-> << >>,
                                  timeInForce                    |-> << >>,
                                  minQty                         |-> << >>,
                                  symbol                         |-> << >>,
                                  symbolSfx                      |-> << >>,
                                  capacity                       |-> << >>,
                                  account                        |-> << >>,
                                  clearingFirm                   |-> << >>,
                                  clearingAccount                |-> << >>,
                                  displayIndicator               |-> << >>,
                                  maxFloor                       |-> << >>,
                                  discretionAmount               |-> << >>,
                                  orderQty                       |-> << >>,
                                  preventMatch                   |-> << >>,
                                  origClOrdId                    |-> << >>,
                                  leavesQty                      |-> << >>,
                                  lastShares                     |-> << >>,
                                  lastPx                         |-> << >>,
                                  displayPrice                   |-> << >>,
                                  workingPrice                   |-> << >>,
                                  baseLiquidityIndicator         |-> << >>,
                                  expireTime                     |-> << >>,
                                  secondaryOrderId               |-> << >>,
                                  attributedQuote                |-> << >>,
                                  extExecInst                    |-> << >>,
                                  echoText                       |-> << >>,
                                  stopPx                         |-> << >>,
                                  routingInst                    |-> << >>,
                                  routStrategy                   |-> << >>,
                                  routeDeliveryMethod            |-> << >>,
                                  exDestination                  |-> << >>,
                                  crossTradeFlag                 |-> << >> ])

(* Order Cancelled Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelledMessage ==
    { ZeroOrderCancelledMessage }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.transactionTime = one]) : one \in Sample(8) }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.clOrdId = one]) : one \in Sample(20) }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.cancelReason = one]) : one \in Sample(1) }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.reserved1 = one]) : one \in Sample(1) }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderCancelledReturnBitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 2, !.orderCancelledReturnBitfield2 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderCancelledReturnBitfield3 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 4, !.orderCancelledReturnBitfield4 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderCancelledReturnBitfield5 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 6, !.orderCancelledReturnBitfield6 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 7, !.orderCancelledReturnBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderCancelledReturnBitfield8 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 9, !.orderCancelledReturnBitfield9 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 10, !.orderCancelledReturnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 11, !.orderCancelledReturnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 12, !.orderCancelledReturnBitfield12 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 13, !.orderCancelledReturnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 14, !.orderCancelledReturnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 15, !.orderCancelledReturnBitfield15 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 16, !.orderCancelledReturnBitfield16 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 17, !.orderCancelledReturnBitfield17 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 18, !.orderCancelledReturnBitfield18 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 19, !.orderCancelledReturnBitfield19 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 20, !.orderCancelledReturnBitfield20 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 21, !.orderCancelledReturnBitfield21 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 22, !.orderCancelledReturnBitfield22 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderCancelledReturnBitfield1 = <<1>>, !.side = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderCancelledReturnBitfield1 = <<2>>, !.pegDifference = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderCancelledReturnBitfield1 = <<4>>, !.price = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderCancelledReturnBitfield1 = <<8>>, !.execInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderCancelledReturnBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderCancelledReturnBitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderCancelledReturnBitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 2, !.orderCancelledReturnBitfield2 = <<1>>, !.symbol = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 2, !.orderCancelledReturnBitfield2 = <<2>>, !.symbolSfx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 2, !.orderCancelledReturnBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderCancelledReturnBitfield3 = <<1>>, !.account = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderCancelledReturnBitfield3 = <<2>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderCancelledReturnBitfield3 = <<4>>, !.clearingAccount = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderCancelledReturnBitfield3 = <<8>>, !.displayIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderCancelledReturnBitfield3 = <<16>>, !.maxFloor = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderCancelledReturnBitfield3 = <<32>>, !.discretionAmount = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderCancelledReturnBitfield3 = <<64>>, !.orderQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderCancelledReturnBitfield3 = <<128>>, !.preventMatch = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderCancelledReturnBitfield5 = <<1>>, !.origClOrdId = one]) : one \in { <<held>> : held \in Sample(20) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderCancelledReturnBitfield5 = <<2>>, !.leavesQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderCancelledReturnBitfield5 = <<4>>, !.lastShares = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderCancelledReturnBitfield5 = <<8>>, !.lastPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderCancelledReturnBitfield5 = <<16>>, !.displayPrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderCancelledReturnBitfield5 = <<32>>, !.workingPrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderCancelledReturnBitfield5 = <<64>>, !.baseLiquidityIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderCancelledReturnBitfield5 = <<128>>, !.expireTime = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 6, !.orderCancelledReturnBitfield6 = <<1>>, !.secondaryOrderId = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 6, !.orderCancelledReturnBitfield6 = <<8>>, !.attributedQuote = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 6, !.orderCancelledReturnBitfield6 = <<16>>, !.extExecInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderCancelledReturnBitfield8 = <<2>>, !.echoText = one]) : one \in { <<held>> : held \in Sample(64) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderCancelledReturnBitfield8 = <<4>>, !.stopPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderCancelledReturnBitfield8 = <<8>>, !.routingInst = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderCancelledReturnBitfield8 = <<16>>, !.routStrategy = one]) : one \in { <<held>> : held \in Sample(6) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderCancelledReturnBitfield8 = <<32>>, !.routeDeliveryMethod = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderCancelledReturnBitfield8 = <<64>>, !.exDestination = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 18, !.orderCancelledReturnBitfield18 = <<8>>, !.crossTradeFlag = one]) : one \in { <<held>> : held \in Sample(1) } }

(***************************************************************************)
(* Cancel Rejected Message                                                 *)
(***************************************************************************)

CancelRejectedMessage ==
    [ transactionTime                : Sample(8),
      clOrdId                        : Sample(20),
      cancelRejectReason             : Sample(1),
      text                           : Sample(60),
      reserved1                      : Sample(1),
      numberOfReturnBitfields        : 0 .. 255,
      cancelRejectedReturnBitfield1  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      cancelRejectedReturnBitfield2  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      cancelRejectedReturnBitfield3  : { << >> } \cup { <<held>> : held \in Sample(1) },
      cancelRejectedReturnBitfield4  : { << >> } \cup { <<held>> : held \in Sample(1) },
      cancelRejectedReturnBitfield5  : { << >> } \cup { <<held>> : held \in Sample(1) },
      cancelRejectedReturnBitfield6  : { << >> } \cup { <<held>> : held \in Sample(1) },
      cancelRejectedReturnBitfield7  : { << >> } \cup { <<held>> : held \in Sample(1) },
      cancelRejectedReturnBitfield8  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      cancelRejectedReturnBitfield9  : { << >> } \cup { <<held>> : held \in Sample(1) },
      cancelRejectedReturnBitfield10 : { << >> } \cup { <<held>> : held \in Sample(1) },
      cancelRejectedReturnBitfield11 : { << >> } \cup { <<held>> : held \in Sample(1) },
      cancelRejectedReturnBitfield12 : { << >> } \cup { <<held>> : held \in Sample(1) },
      cancelRejectedReturnBitfield13 : { << >> } \cup { <<held>> : held \in Sample(1) },
      cancelRejectedReturnBitfield14 : { << >> } \cup { <<held>> : held \in Sample(1) },
      cancelRejectedReturnBitfield15 : { << >> } \cup { <<held>> : held \in Sample(1) },
      cancelRejectedReturnBitfield16 : { << >> } \cup { <<held>> : held \in Sample(1) },
      cancelRejectedReturnBitfield17 : { << >> } \cup { <<held>> : held \in Sample(1) },
      cancelRejectedReturnBitfield18 : { << >> } \cup { <<held>> : held \in Sample(1) },
      cancelRejectedReturnBitfield19 : { << >> } \cup { <<held>> : held \in Sample(1) },
      cancelRejectedReturnBitfield20 : { << >> } \cup { <<held>> : held \in Sample(1) },
      cancelRejectedReturnBitfield21 : { << >> } \cup { <<held>> : held \in Sample(1) },
      cancelRejectedReturnBitfield22 : { << >> } \cup { <<held>> : held \in Sample(1) },
      side                           : { << >> } \cup { <<held>> : held \in Sample(1) },
      pegDifference                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      price                          : { << >> } \cup { <<held>> : held \in Sample(8) },
      execInst                       : { << >> } \cup { <<held>> : held \in Sample(1) },
      ordType                        : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce                    : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                         : { << >> } \cup { <<held>> : held \in Sample(4) },
      symbol                         : { << >> } \cup { <<held>> : held \in Sample(8) },
      symbolSfx                      : { << >> } \cup { <<held>> : held \in Sample(8) },
      capacity                       : { << >> } \cup { <<held>> : held \in Sample(1) },
      echoText                       : { << >> } \cup { <<held>> : held \in Sample(64) },
      stopPx                         : { << >> } \cup { <<held>> : held \in Sample(8) } ]

EncodeCancelRejectedMessage(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.cancelRejectReason
        \o message.text
        \o message.reserved1
        \o EncodeUIntBE(message.numberOfReturnBitfields, 1)
        \o (IF message.cancelRejectedReturnBitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.cancelRejectedReturnBitfield1[1], 1))
        \o (IF message.cancelRejectedReturnBitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.cancelRejectedReturnBitfield2[1], 1))
        \o (IF message.cancelRejectedReturnBitfield3 = << >> THEN << >> ELSE message.cancelRejectedReturnBitfield3[1])
        \o (IF message.cancelRejectedReturnBitfield4 = << >> THEN << >> ELSE message.cancelRejectedReturnBitfield4[1])
        \o (IF message.cancelRejectedReturnBitfield5 = << >> THEN << >> ELSE message.cancelRejectedReturnBitfield5[1])
        \o (IF message.cancelRejectedReturnBitfield6 = << >> THEN << >> ELSE message.cancelRejectedReturnBitfield6[1])
        \o (IF message.cancelRejectedReturnBitfield7 = << >> THEN << >> ELSE message.cancelRejectedReturnBitfield7[1])
        \o (IF message.cancelRejectedReturnBitfield8 = << >> THEN << >> ELSE EncodeUIntLE(message.cancelRejectedReturnBitfield8[1], 1))
        \o (IF message.cancelRejectedReturnBitfield9 = << >> THEN << >> ELSE message.cancelRejectedReturnBitfield9[1])
        \o (IF message.cancelRejectedReturnBitfield10 = << >> THEN << >> ELSE message.cancelRejectedReturnBitfield10[1])
        \o (IF message.cancelRejectedReturnBitfield11 = << >> THEN << >> ELSE message.cancelRejectedReturnBitfield11[1])
        \o (IF message.cancelRejectedReturnBitfield12 = << >> THEN << >> ELSE message.cancelRejectedReturnBitfield12[1])
        \o (IF message.cancelRejectedReturnBitfield13 = << >> THEN << >> ELSE message.cancelRejectedReturnBitfield13[1])
        \o (IF message.cancelRejectedReturnBitfield14 = << >> THEN << >> ELSE message.cancelRejectedReturnBitfield14[1])
        \o (IF message.cancelRejectedReturnBitfield15 = << >> THEN << >> ELSE message.cancelRejectedReturnBitfield15[1])
        \o (IF message.cancelRejectedReturnBitfield16 = << >> THEN << >> ELSE message.cancelRejectedReturnBitfield16[1])
        \o (IF message.cancelRejectedReturnBitfield17 = << >> THEN << >> ELSE message.cancelRejectedReturnBitfield17[1])
        \o (IF message.cancelRejectedReturnBitfield18 = << >> THEN << >> ELSE message.cancelRejectedReturnBitfield18[1])
        \o (IF message.cancelRejectedReturnBitfield19 = << >> THEN << >> ELSE message.cancelRejectedReturnBitfield19[1])
        \o (IF message.cancelRejectedReturnBitfield20 = << >> THEN << >> ELSE message.cancelRejectedReturnBitfield20[1])
        \o (IF message.cancelRejectedReturnBitfield21 = << >> THEN << >> ELSE message.cancelRejectedReturnBitfield21[1])
        \o (IF message.cancelRejectedReturnBitfield22 = << >> THEN << >> ELSE message.cancelRejectedReturnBitfield22[1])
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
    LET cancelRejectedReturnBitfield1 == ReadWhen(numberOfReturnBitfields.value >= 1, ReadUIntLE(numberOfReturnBitfields.rest, 1), numberOfReturnBitfields.rest) IN IF ~cancelRejectedReturnBitfield1.ok THEN Fail ELSE
    LET cancelRejectedReturnBitfield2 == ReadWhen(numberOfReturnBitfields.value >= 2, ReadUIntLE(cancelRejectedReturnBitfield1.rest, 1), cancelRejectedReturnBitfield1.rest) IN IF ~cancelRejectedReturnBitfield2.ok THEN Fail ELSE
    LET cancelRejectedReturnBitfield3 == ReadWhen(numberOfReturnBitfields.value >= 3, ReadBytes(cancelRejectedReturnBitfield2.rest, 1), cancelRejectedReturnBitfield2.rest) IN IF ~cancelRejectedReturnBitfield3.ok THEN Fail ELSE
    LET cancelRejectedReturnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadBytes(cancelRejectedReturnBitfield3.rest, 1), cancelRejectedReturnBitfield3.rest) IN IF ~cancelRejectedReturnBitfield4.ok THEN Fail ELSE
    LET cancelRejectedReturnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadBytes(cancelRejectedReturnBitfield4.rest, 1), cancelRejectedReturnBitfield4.rest) IN IF ~cancelRejectedReturnBitfield5.ok THEN Fail ELSE
    LET cancelRejectedReturnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadBytes(cancelRejectedReturnBitfield5.rest, 1), cancelRejectedReturnBitfield5.rest) IN IF ~cancelRejectedReturnBitfield6.ok THEN Fail ELSE
    LET cancelRejectedReturnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadBytes(cancelRejectedReturnBitfield6.rest, 1), cancelRejectedReturnBitfield6.rest) IN IF ~cancelRejectedReturnBitfield7.ok THEN Fail ELSE
    LET cancelRejectedReturnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadUIntLE(cancelRejectedReturnBitfield7.rest, 1), cancelRejectedReturnBitfield7.rest) IN IF ~cancelRejectedReturnBitfield8.ok THEN Fail ELSE
    LET cancelRejectedReturnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadBytes(cancelRejectedReturnBitfield8.rest, 1), cancelRejectedReturnBitfield8.rest) IN IF ~cancelRejectedReturnBitfield9.ok THEN Fail ELSE
    LET cancelRejectedReturnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadBytes(cancelRejectedReturnBitfield9.rest, 1), cancelRejectedReturnBitfield9.rest) IN IF ~cancelRejectedReturnBitfield10.ok THEN Fail ELSE
    LET cancelRejectedReturnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadBytes(cancelRejectedReturnBitfield10.rest, 1), cancelRejectedReturnBitfield10.rest) IN IF ~cancelRejectedReturnBitfield11.ok THEN Fail ELSE
    LET cancelRejectedReturnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadBytes(cancelRejectedReturnBitfield11.rest, 1), cancelRejectedReturnBitfield11.rest) IN IF ~cancelRejectedReturnBitfield12.ok THEN Fail ELSE
    LET cancelRejectedReturnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(cancelRejectedReturnBitfield12.rest, 1), cancelRejectedReturnBitfield12.rest) IN IF ~cancelRejectedReturnBitfield13.ok THEN Fail ELSE
    LET cancelRejectedReturnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(cancelRejectedReturnBitfield13.rest, 1), cancelRejectedReturnBitfield13.rest) IN IF ~cancelRejectedReturnBitfield14.ok THEN Fail ELSE
    LET cancelRejectedReturnBitfield15 == ReadWhen(numberOfReturnBitfields.value >= 15, ReadBytes(cancelRejectedReturnBitfield14.rest, 1), cancelRejectedReturnBitfield14.rest) IN IF ~cancelRejectedReturnBitfield15.ok THEN Fail ELSE
    LET cancelRejectedReturnBitfield16 == ReadWhen(numberOfReturnBitfields.value >= 16, ReadBytes(cancelRejectedReturnBitfield15.rest, 1), cancelRejectedReturnBitfield15.rest) IN IF ~cancelRejectedReturnBitfield16.ok THEN Fail ELSE
    LET cancelRejectedReturnBitfield17 == ReadWhen(numberOfReturnBitfields.value >= 17, ReadBytes(cancelRejectedReturnBitfield16.rest, 1), cancelRejectedReturnBitfield16.rest) IN IF ~cancelRejectedReturnBitfield17.ok THEN Fail ELSE
    LET cancelRejectedReturnBitfield18 == ReadWhen(numberOfReturnBitfields.value >= 18, ReadBytes(cancelRejectedReturnBitfield17.rest, 1), cancelRejectedReturnBitfield17.rest) IN IF ~cancelRejectedReturnBitfield18.ok THEN Fail ELSE
    LET cancelRejectedReturnBitfield19 == ReadWhen(numberOfReturnBitfields.value >= 19, ReadBytes(cancelRejectedReturnBitfield18.rest, 1), cancelRejectedReturnBitfield18.rest) IN IF ~cancelRejectedReturnBitfield19.ok THEN Fail ELSE
    LET cancelRejectedReturnBitfield20 == ReadWhen(numberOfReturnBitfields.value >= 20, ReadBytes(cancelRejectedReturnBitfield19.rest, 1), cancelRejectedReturnBitfield19.rest) IN IF ~cancelRejectedReturnBitfield20.ok THEN Fail ELSE
    LET cancelRejectedReturnBitfield21 == ReadWhen(numberOfReturnBitfields.value >= 21, ReadBytes(cancelRejectedReturnBitfield20.rest, 1), cancelRejectedReturnBitfield20.rest) IN IF ~cancelRejectedReturnBitfield21.ok THEN Fail ELSE
    LET cancelRejectedReturnBitfield22 == ReadWhen(numberOfReturnBitfields.value >= 22, ReadBytes(cancelRejectedReturnBitfield21.rest, 1), cancelRejectedReturnBitfield21.rest) IN IF ~cancelRejectedReturnBitfield22.ok THEN Fail ELSE
    LET side == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (cancelRejectedReturnBitfield1.value # << >> /\ cancelRejectedReturnBitfield1.value[1] % 2 > 0), ReadBytes(cancelRejectedReturnBitfield22.rest, 1), cancelRejectedReturnBitfield22.rest) IN IF ~side.ok THEN Fail ELSE
    LET pegDifference == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (cancelRejectedReturnBitfield1.value # << >> /\ (cancelRejectedReturnBitfield1.value[1] \div 2) % 2 > 0), ReadBytes(side.rest, 8), side.rest) IN IF ~pegDifference.ok THEN Fail ELSE
    LET price == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (cancelRejectedReturnBitfield1.value # << >> /\ (cancelRejectedReturnBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(pegDifference.rest, 8), pegDifference.rest) IN IF ~price.ok THEN Fail ELSE
    LET execInst == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (cancelRejectedReturnBitfield1.value # << >> /\ (cancelRejectedReturnBitfield1.value[1] \div 8) % 2 > 0), ReadBytes(price.rest, 1), price.rest) IN IF ~execInst.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (cancelRejectedReturnBitfield1.value # << >> /\ (cancelRejectedReturnBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(execInst.rest, 1), execInst.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (cancelRejectedReturnBitfield1.value # << >> /\ (cancelRejectedReturnBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (cancelRejectedReturnBitfield1.value # << >> /\ (cancelRejectedReturnBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET symbol == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (cancelRejectedReturnBitfield2.value # << >> /\ cancelRejectedReturnBitfield2.value[1] % 2 > 0), ReadBytes(minQty.rest, 8), minQty.rest) IN IF ~symbol.ok THEN Fail ELSE
    LET symbolSfx == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (cancelRejectedReturnBitfield2.value # << >> /\ (cancelRejectedReturnBitfield2.value[1] \div 2) % 2 > 0), ReadBytes(symbol.rest, 8), symbol.rest) IN IF ~symbolSfx.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (cancelRejectedReturnBitfield2.value # << >> /\ (cancelRejectedReturnBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(symbolSfx.rest, 1), symbolSfx.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET echoText == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (cancelRejectedReturnBitfield8.value # << >> /\ (cancelRejectedReturnBitfield8.value[1] \div 2) % 2 > 0), ReadBytes(capacity.rest, 64), capacity.rest) IN IF ~echoText.ok THEN Fail ELSE
    LET stopPx == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (cancelRejectedReturnBitfield8.value # << >> /\ (cancelRejectedReturnBitfield8.value[1] \div 4) % 2 > 0), ReadBytes(echoText.rest, 8), echoText.rest) IN IF ~stopPx.ok THEN Fail ELSE
    Ok([ transactionTime                |-> transactionTime.value,
         clOrdId                        |-> clOrdId.value,
         cancelRejectReason             |-> cancelRejectReason.value,
         text                           |-> text.value,
         reserved1                      |-> reserved1.value,
         numberOfReturnBitfields        |-> numberOfReturnBitfields.value,
         cancelRejectedReturnBitfield1  |-> cancelRejectedReturnBitfield1.value,
         cancelRejectedReturnBitfield2  |-> cancelRejectedReturnBitfield2.value,
         cancelRejectedReturnBitfield3  |-> cancelRejectedReturnBitfield3.value,
         cancelRejectedReturnBitfield4  |-> cancelRejectedReturnBitfield4.value,
         cancelRejectedReturnBitfield5  |-> cancelRejectedReturnBitfield5.value,
         cancelRejectedReturnBitfield6  |-> cancelRejectedReturnBitfield6.value,
         cancelRejectedReturnBitfield7  |-> cancelRejectedReturnBitfield7.value,
         cancelRejectedReturnBitfield8  |-> cancelRejectedReturnBitfield8.value,
         cancelRejectedReturnBitfield9  |-> cancelRejectedReturnBitfield9.value,
         cancelRejectedReturnBitfield10 |-> cancelRejectedReturnBitfield10.value,
         cancelRejectedReturnBitfield11 |-> cancelRejectedReturnBitfield11.value,
         cancelRejectedReturnBitfield12 |-> cancelRejectedReturnBitfield12.value,
         cancelRejectedReturnBitfield13 |-> cancelRejectedReturnBitfield13.value,
         cancelRejectedReturnBitfield14 |-> cancelRejectedReturnBitfield14.value,
         cancelRejectedReturnBitfield15 |-> cancelRejectedReturnBitfield15.value,
         cancelRejectedReturnBitfield16 |-> cancelRejectedReturnBitfield16.value,
         cancelRejectedReturnBitfield17 |-> cancelRejectedReturnBitfield17.value,
         cancelRejectedReturnBitfield18 |-> cancelRejectedReturnBitfield18.value,
         cancelRejectedReturnBitfield19 |-> cancelRejectedReturnBitfield19.value,
         cancelRejectedReturnBitfield20 |-> cancelRejectedReturnBitfield20.value,
         cancelRejectedReturnBitfield21 |-> cancelRejectedReturnBitfield21.value,
         cancelRejectedReturnBitfield22 |-> cancelRejectedReturnBitfield22.value,
         side                           |-> side.value,
         pegDifference                  |-> pegDifference.value,
         price                          |-> price.value,
         execInst                       |-> execInst.value,
         ordType                        |-> ordType.value,
         timeInForce                    |-> timeInForce.value,
         minQty                         |-> minQty.value,
         symbol                         |-> symbol.value,
         symbolSfx                      |-> symbolSfx.value,
         capacity                       |-> capacity.value,
         echoText                       |-> echoText.value,
         stopPx                         |-> stopPx.value ], stopPx.rest)

(* Cancel Rejected Message with each field marked present by fields before it there exactly where they say *)
SettleCancelRejectedMessage(message) ==
    LET settled1 == [message EXCEPT !.cancelRejectedReturnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.cancelRejectedReturnBitfield1 = << >> THEN <<0>> ELSE message.cancelRejectedReturnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.cancelRejectedReturnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.cancelRejectedReturnBitfield2 = << >> THEN <<0>> ELSE settled1.cancelRejectedReturnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.cancelRejectedReturnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.cancelRejectedReturnBitfield3 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled2.cancelRejectedReturnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.cancelRejectedReturnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.cancelRejectedReturnBitfield4 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled3.cancelRejectedReturnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.cancelRejectedReturnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.cancelRejectedReturnBitfield5 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled4.cancelRejectedReturnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.cancelRejectedReturnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.cancelRejectedReturnBitfield6 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled5.cancelRejectedReturnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.cancelRejectedReturnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.cancelRejectedReturnBitfield7 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.cancelRejectedReturnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.cancelRejectedReturnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.cancelRejectedReturnBitfield8 = << >> THEN <<0>> ELSE settled7.cancelRejectedReturnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.cancelRejectedReturnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.cancelRejectedReturnBitfield9 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled8.cancelRejectedReturnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.cancelRejectedReturnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.cancelRejectedReturnBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.cancelRejectedReturnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.cancelRejectedReturnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.cancelRejectedReturnBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.cancelRejectedReturnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.cancelRejectedReturnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.cancelRejectedReturnBitfield12 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.cancelRejectedReturnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.cancelRejectedReturnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.cancelRejectedReturnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.cancelRejectedReturnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.cancelRejectedReturnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.cancelRejectedReturnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.cancelRejectedReturnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.cancelRejectedReturnBitfield15 = IF settled14.numberOfReturnBitfields >= 15 THEN (IF settled14.cancelRejectedReturnBitfield15 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.cancelRejectedReturnBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.cancelRejectedReturnBitfield16 = IF settled15.numberOfReturnBitfields >= 16 THEN (IF settled15.cancelRejectedReturnBitfield16 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled15.cancelRejectedReturnBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.cancelRejectedReturnBitfield17 = IF settled16.numberOfReturnBitfields >= 17 THEN (IF settled16.cancelRejectedReturnBitfield17 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled16.cancelRejectedReturnBitfield17) ELSE << >>]
        settled18 == [settled17 EXCEPT !.cancelRejectedReturnBitfield18 = IF settled17.numberOfReturnBitfields >= 18 THEN (IF settled17.cancelRejectedReturnBitfield18 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.cancelRejectedReturnBitfield18) ELSE << >>]
        settled19 == [settled18 EXCEPT !.cancelRejectedReturnBitfield19 = IF settled18.numberOfReturnBitfields >= 19 THEN (IF settled18.cancelRejectedReturnBitfield19 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled18.cancelRejectedReturnBitfield19) ELSE << >>]
        settled20 == [settled19 EXCEPT !.cancelRejectedReturnBitfield20 = IF settled19.numberOfReturnBitfields >= 20 THEN (IF settled19.cancelRejectedReturnBitfield20 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled19.cancelRejectedReturnBitfield20) ELSE << >>]
        settled21 == [settled20 EXCEPT !.cancelRejectedReturnBitfield21 = IF settled20.numberOfReturnBitfields >= 21 THEN (IF settled20.cancelRejectedReturnBitfield21 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled20.cancelRejectedReturnBitfield21) ELSE << >>]
        settled22 == [settled21 EXCEPT !.cancelRejectedReturnBitfield22 = IF settled21.numberOfReturnBitfields >= 22 THEN (IF settled21.cancelRejectedReturnBitfield22 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled21.cancelRejectedReturnBitfield22) ELSE << >>]
        settled23 == [settled22 EXCEPT !.side = IF settled22.numberOfReturnBitfields >= 1 /\ (settled22.cancelRejectedReturnBitfield1 # << >> /\ settled22.cancelRejectedReturnBitfield1[1] % 2 > 0) THEN (IF settled22.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled22.side) ELSE << >>]
        settled24 == [settled23 EXCEPT !.pegDifference = IF settled23.numberOfReturnBitfields >= 1 /\ (settled23.cancelRejectedReturnBitfield1 # << >> /\ (settled23.cancelRejectedReturnBitfield1[1] \div 2) % 2 > 0) THEN (IF settled23.pegDifference = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled23.pegDifference) ELSE << >>]
        settled25 == [settled24 EXCEPT !.price = IF settled24.numberOfReturnBitfields >= 1 /\ (settled24.cancelRejectedReturnBitfield1 # << >> /\ (settled24.cancelRejectedReturnBitfield1[1] \div 4) % 2 > 0) THEN (IF settled24.price = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled24.price) ELSE << >>]
        settled26 == [settled25 EXCEPT !.execInst = IF settled25.numberOfReturnBitfields >= 1 /\ (settled25.cancelRejectedReturnBitfield1 # << >> /\ (settled25.cancelRejectedReturnBitfield1[1] \div 8) % 2 > 0) THEN (IF settled25.execInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled25.execInst) ELSE << >>]
        settled27 == [settled26 EXCEPT !.ordType = IF settled26.numberOfReturnBitfields >= 1 /\ (settled26.cancelRejectedReturnBitfield1 # << >> /\ (settled26.cancelRejectedReturnBitfield1[1] \div 16) % 2 > 0) THEN (IF settled26.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled26.ordType) ELSE << >>]
        settled28 == [settled27 EXCEPT !.timeInForce = IF settled27.numberOfReturnBitfields >= 1 /\ (settled27.cancelRejectedReturnBitfield1 # << >> /\ (settled27.cancelRejectedReturnBitfield1[1] \div 32) % 2 > 0) THEN (IF settled27.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled27.timeInForce) ELSE << >>]
        settled29 == [settled28 EXCEPT !.minQty = IF settled28.numberOfReturnBitfields >= 1 /\ (settled28.cancelRejectedReturnBitfield1 # << >> /\ (settled28.cancelRejectedReturnBitfield1[1] \div 64) % 2 > 0) THEN (IF settled28.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled28.minQty) ELSE << >>]
        settled30 == [settled29 EXCEPT !.symbol = IF settled29.numberOfReturnBitfields >= 2 /\ (settled29.cancelRejectedReturnBitfield2 # << >> /\ settled29.cancelRejectedReturnBitfield2[1] % 2 > 0) THEN (IF settled29.symbol = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled29.symbol) ELSE << >>]
        settled31 == [settled30 EXCEPT !.symbolSfx = IF settled30.numberOfReturnBitfields >= 2 /\ (settled30.cancelRejectedReturnBitfield2 # << >> /\ (settled30.cancelRejectedReturnBitfield2[1] \div 2) % 2 > 0) THEN (IF settled30.symbolSfx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled30.symbolSfx) ELSE << >>]
        settled32 == [settled31 EXCEPT !.capacity = IF settled31.numberOfReturnBitfields >= 2 /\ (settled31.cancelRejectedReturnBitfield2 # << >> /\ (settled31.cancelRejectedReturnBitfield2[1] \div 64) % 2 > 0) THEN (IF settled31.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled31.capacity) ELSE << >>]
        settled33 == [settled32 EXCEPT !.echoText = IF settled32.numberOfReturnBitfields >= 8 /\ (settled32.cancelRejectedReturnBitfield8 # << >> /\ (settled32.cancelRejectedReturnBitfield8[1] \div 2) % 2 > 0) THEN (IF settled32.echoText = << >> THEN <<[i \in 1 .. 64 |-> 0]>> ELSE settled32.echoText) ELSE << >>]
        settled34 == [settled33 EXCEPT !.stopPx = IF settled33.numberOfReturnBitfields >= 8 /\ (settled33.cancelRejectedReturnBitfield8 # << >> /\ (settled33.cancelRejectedReturnBitfield8[1] \div 4) % 2 > 0) THEN (IF settled33.stopPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled33.stopPx) ELSE << >>]
    IN  settled34

ZeroCancelRejectedMessage ==
    SettleCancelRejectedMessage([ transactionTime                |-> [i \in 1 .. 8 |-> 0],
                                  clOrdId                        |-> [i \in 1 .. 20 |-> 0],
                                  cancelRejectReason             |-> [i \in 1 .. 1 |-> 0],
                                  text                           |-> [i \in 1 .. 60 |-> 0],
                                  reserved1                      |-> [i \in 1 .. 1 |-> 0],
                                  numberOfReturnBitfields        |-> 0,
                                  cancelRejectedReturnBitfield1  |-> << >>,
                                  cancelRejectedReturnBitfield2  |-> << >>,
                                  cancelRejectedReturnBitfield3  |-> << >>,
                                  cancelRejectedReturnBitfield4  |-> << >>,
                                  cancelRejectedReturnBitfield5  |-> << >>,
                                  cancelRejectedReturnBitfield6  |-> << >>,
                                  cancelRejectedReturnBitfield7  |-> << >>,
                                  cancelRejectedReturnBitfield8  |-> << >>,
                                  cancelRejectedReturnBitfield9  |-> << >>,
                                  cancelRejectedReturnBitfield10 |-> << >>,
                                  cancelRejectedReturnBitfield11 |-> << >>,
                                  cancelRejectedReturnBitfield12 |-> << >>,
                                  cancelRejectedReturnBitfield13 |-> << >>,
                                  cancelRejectedReturnBitfield14 |-> << >>,
                                  cancelRejectedReturnBitfield15 |-> << >>,
                                  cancelRejectedReturnBitfield16 |-> << >>,
                                  cancelRejectedReturnBitfield17 |-> << >>,
                                  cancelRejectedReturnBitfield18 |-> << >>,
                                  cancelRejectedReturnBitfield19 |-> << >>,
                                  cancelRejectedReturnBitfield20 |-> << >>,
                                  cancelRejectedReturnBitfield21 |-> << >>,
                                  cancelRejectedReturnBitfield22 |-> << >>,
                                  side                           |-> << >>,
                                  pegDifference                  |-> << >>,
                                  price                          |-> << >>,
                                  execInst                       |-> << >>,
                                  ordType                        |-> << >>,
                                  timeInForce                    |-> << >>,
                                  minQty                         |-> << >>,
                                  symbol                         |-> << >>,
                                  symbolSfx                      |-> << >>,
                                  capacity                       |-> << >>,
                                  echoText                       |-> << >>,
                                  stopPx                         |-> << >> ])

(* Cancel Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelRejectedMessage ==
    { ZeroCancelRejectedMessage }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.transactionTime = one]) : one \in Sample(8) }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.clOrdId = one]) : one \in Sample(20) }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.cancelRejectReason = one]) : one \in Sample(1) }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.text = one]) : one \in Sample(60) }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.reserved1 = one]) : one \in Sample(1) }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.cancelRejectedReturnBitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 2, !.cancelRejectedReturnBitfield2 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 3, !.cancelRejectedReturnBitfield3 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 4, !.cancelRejectedReturnBitfield4 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 5, !.cancelRejectedReturnBitfield5 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 6, !.cancelRejectedReturnBitfield6 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 7, !.cancelRejectedReturnBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 8, !.cancelRejectedReturnBitfield8 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 9, !.cancelRejectedReturnBitfield9 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 10, !.cancelRejectedReturnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 11, !.cancelRejectedReturnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 12, !.cancelRejectedReturnBitfield12 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 13, !.cancelRejectedReturnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 14, !.cancelRejectedReturnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 15, !.cancelRejectedReturnBitfield15 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 16, !.cancelRejectedReturnBitfield16 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 17, !.cancelRejectedReturnBitfield17 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 18, !.cancelRejectedReturnBitfield18 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 19, !.cancelRejectedReturnBitfield19 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 20, !.cancelRejectedReturnBitfield20 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 21, !.cancelRejectedReturnBitfield21 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 22, !.cancelRejectedReturnBitfield22 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.cancelRejectedReturnBitfield1 = <<1>>, !.side = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.cancelRejectedReturnBitfield1 = <<2>>, !.pegDifference = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.cancelRejectedReturnBitfield1 = <<4>>, !.price = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.cancelRejectedReturnBitfield1 = <<8>>, !.execInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.cancelRejectedReturnBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.cancelRejectedReturnBitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.cancelRejectedReturnBitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 2, !.cancelRejectedReturnBitfield2 = <<1>>, !.symbol = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 2, !.cancelRejectedReturnBitfield2 = <<2>>, !.symbolSfx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 2, !.cancelRejectedReturnBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 8, !.cancelRejectedReturnBitfield8 = <<2>>, !.echoText = one]) : one \in { <<held>> : held \in Sample(64) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 8, !.cancelRejectedReturnBitfield8 = <<4>>, !.stopPx = one]) : one \in { <<held>> : held \in Sample(8) } }

(***************************************************************************)
(* Order Execution Message                                                 *)
(***************************************************************************)

OrderExecutionMessage ==
    [ transactionTime                : Sample(8),
      clOrdId                        : Sample(20),
      execId                         : Sample(8),
      lastShares                     : Sample(4),
      lastPx                         : Sample(8),
      leavesQty                      : Sample(4),
      baseLiquidityIndicator         : Sample(1),
      subLiquidityIndicator          : Sample(1),
      contraBroker                   : Sample(4),
      reserved1                      : Sample(1),
      numberOfReturnBitfields        : 0 .. 255,
      orderExecutionReturnBitfield1  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderExecutionReturnBitfield2  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderExecutionReturnBitfield3  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderExecutionReturnBitfield4  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderExecutionReturnBitfield5  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderExecutionReturnBitfield6  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderExecutionReturnBitfield7  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderExecutionReturnBitfield8  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderExecutionReturnBitfield9  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderExecutionReturnBitfield10 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderExecutionReturnBitfield11 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderExecutionReturnBitfield12 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderExecutionReturnBitfield13 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderExecutionReturnBitfield14 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderExecutionReturnBitfield15 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderExecutionReturnBitfield16 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderExecutionReturnBitfield17 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderExecutionReturnBitfield18 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderExecutionReturnBitfield19 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderExecutionReturnBitfield20 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderExecutionReturnBitfield21 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderExecutionReturnBitfield22 : { << >> } \cup { <<held>> : held \in Sample(1) },
      side                           : { << >> } \cup { <<held>> : held \in Sample(1) },
      pegDifference                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      price                          : { << >> } \cup { <<held>> : held \in Sample(8) },
      execInst                       : { << >> } \cup { <<held>> : held \in Sample(1) },
      ordType                        : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce                    : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                         : { << >> } \cup { <<held>> : held \in Sample(4) },
      symbol                         : { << >> } \cup { <<held>> : held \in Sample(8) },
      symbolSfx                      : { << >> } \cup { <<held>> : held \in Sample(8) },
      capacity                       : { << >> } \cup { <<held>> : held \in Sample(1) },
      account                        : { << >> } \cup { <<held>> : held \in Sample(16) },
      clearingFirm                   : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingAccount                : { << >> } \cup { <<held>> : held \in Sample(4) },
      displayIndicator               : { << >> } \cup { <<held>> : held \in Sample(1) },
      maxFloor                       : { << >> } \cup { <<held>> : held \in Sample(4) },
      discretionAmount               : { << >> } \cup { <<held>> : held \in Sample(2) },
      orderQty                       : { << >> } \cup { <<held>> : held \in Sample(4) },
      preventMatch                   : { << >> } \cup { <<held>> : held \in Sample(3) },
      attributedQuote                : { << >> } \cup { <<held>> : held \in Sample(1) },
      extExecInst                    : { << >> } \cup { <<held>> : held \in Sample(1) },
      feeCode                        : { << >> } \cup { <<held>> : held \in Sample(2) },
      echoText                       : { << >> } \cup { <<held>> : held \in Sample(64) },
      stopPx                         : { << >> } \cup { <<held>> : held \in Sample(8) },
      routingInst                    : { << >> } \cup { <<held>> : held \in Sample(4) },
      routStrategy                   : { << >> } \cup { <<held>> : held \in Sample(6) },
      routeDeliveryMethod            : { << >> } \cup { <<held>> : held \in Sample(3) },
      exDestination                  : { << >> } \cup { <<held>> : held \in Sample(1) },
      crossTradeFlag                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      locateBroker                   : { << >> } \cup { <<held>> : held \in Sample(4) } ]

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
        \o (IF message.orderExecutionReturnBitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.orderExecutionReturnBitfield1[1], 1))
        \o (IF message.orderExecutionReturnBitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.orderExecutionReturnBitfield2[1], 1))
        \o (IF message.orderExecutionReturnBitfield3 = << >> THEN << >> ELSE EncodeUIntLE(message.orderExecutionReturnBitfield3[1], 1))
        \o (IF message.orderExecutionReturnBitfield4 = << >> THEN << >> ELSE message.orderExecutionReturnBitfield4[1])
        \o (IF message.orderExecutionReturnBitfield5 = << >> THEN << >> ELSE message.orderExecutionReturnBitfield5[1])
        \o (IF message.orderExecutionReturnBitfield6 = << >> THEN << >> ELSE EncodeUIntLE(message.orderExecutionReturnBitfield6[1], 1))
        \o (IF message.orderExecutionReturnBitfield7 = << >> THEN << >> ELSE message.orderExecutionReturnBitfield7[1])
        \o (IF message.orderExecutionReturnBitfield8 = << >> THEN << >> ELSE EncodeUIntLE(message.orderExecutionReturnBitfield8[1], 1))
        \o (IF message.orderExecutionReturnBitfield9 = << >> THEN << >> ELSE message.orderExecutionReturnBitfield9[1])
        \o (IF message.orderExecutionReturnBitfield10 = << >> THEN << >> ELSE message.orderExecutionReturnBitfield10[1])
        \o (IF message.orderExecutionReturnBitfield11 = << >> THEN << >> ELSE message.orderExecutionReturnBitfield11[1])
        \o (IF message.orderExecutionReturnBitfield12 = << >> THEN << >> ELSE message.orderExecutionReturnBitfield12[1])
        \o (IF message.orderExecutionReturnBitfield13 = << >> THEN << >> ELSE message.orderExecutionReturnBitfield13[1])
        \o (IF message.orderExecutionReturnBitfield14 = << >> THEN << >> ELSE message.orderExecutionReturnBitfield14[1])
        \o (IF message.orderExecutionReturnBitfield15 = << >> THEN << >> ELSE message.orderExecutionReturnBitfield15[1])
        \o (IF message.orderExecutionReturnBitfield16 = << >> THEN << >> ELSE message.orderExecutionReturnBitfield16[1])
        \o (IF message.orderExecutionReturnBitfield17 = << >> THEN << >> ELSE message.orderExecutionReturnBitfield17[1])
        \o (IF message.orderExecutionReturnBitfield18 = << >> THEN << >> ELSE EncodeUIntLE(message.orderExecutionReturnBitfield18[1], 1))
        \o (IF message.orderExecutionReturnBitfield19 = << >> THEN << >> ELSE message.orderExecutionReturnBitfield19[1])
        \o (IF message.orderExecutionReturnBitfield20 = << >> THEN << >> ELSE message.orderExecutionReturnBitfield20[1])
        \o (IF message.orderExecutionReturnBitfield21 = << >> THEN << >> ELSE message.orderExecutionReturnBitfield21[1])
        \o (IF message.orderExecutionReturnBitfield22 = << >> THEN << >> ELSE message.orderExecutionReturnBitfield22[1])
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
    LET orderExecutionReturnBitfield1 == ReadWhen(numberOfReturnBitfields.value >= 1, ReadUIntLE(numberOfReturnBitfields.rest, 1), numberOfReturnBitfields.rest) IN IF ~orderExecutionReturnBitfield1.ok THEN Fail ELSE
    LET orderExecutionReturnBitfield2 == ReadWhen(numberOfReturnBitfields.value >= 2, ReadUIntLE(orderExecutionReturnBitfield1.rest, 1), orderExecutionReturnBitfield1.rest) IN IF ~orderExecutionReturnBitfield2.ok THEN Fail ELSE
    LET orderExecutionReturnBitfield3 == ReadWhen(numberOfReturnBitfields.value >= 3, ReadUIntLE(orderExecutionReturnBitfield2.rest, 1), orderExecutionReturnBitfield2.rest) IN IF ~orderExecutionReturnBitfield3.ok THEN Fail ELSE
    LET orderExecutionReturnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadBytes(orderExecutionReturnBitfield3.rest, 1), orderExecutionReturnBitfield3.rest) IN IF ~orderExecutionReturnBitfield4.ok THEN Fail ELSE
    LET orderExecutionReturnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadBytes(orderExecutionReturnBitfield4.rest, 1), orderExecutionReturnBitfield4.rest) IN IF ~orderExecutionReturnBitfield5.ok THEN Fail ELSE
    LET orderExecutionReturnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadUIntLE(orderExecutionReturnBitfield5.rest, 1), orderExecutionReturnBitfield5.rest) IN IF ~orderExecutionReturnBitfield6.ok THEN Fail ELSE
    LET orderExecutionReturnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadBytes(orderExecutionReturnBitfield6.rest, 1), orderExecutionReturnBitfield6.rest) IN IF ~orderExecutionReturnBitfield7.ok THEN Fail ELSE
    LET orderExecutionReturnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadUIntLE(orderExecutionReturnBitfield7.rest, 1), orderExecutionReturnBitfield7.rest) IN IF ~orderExecutionReturnBitfield8.ok THEN Fail ELSE
    LET orderExecutionReturnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadBytes(orderExecutionReturnBitfield8.rest, 1), orderExecutionReturnBitfield8.rest) IN IF ~orderExecutionReturnBitfield9.ok THEN Fail ELSE
    LET orderExecutionReturnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadBytes(orderExecutionReturnBitfield9.rest, 1), orderExecutionReturnBitfield9.rest) IN IF ~orderExecutionReturnBitfield10.ok THEN Fail ELSE
    LET orderExecutionReturnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadBytes(orderExecutionReturnBitfield10.rest, 1), orderExecutionReturnBitfield10.rest) IN IF ~orderExecutionReturnBitfield11.ok THEN Fail ELSE
    LET orderExecutionReturnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadBytes(orderExecutionReturnBitfield11.rest, 1), orderExecutionReturnBitfield11.rest) IN IF ~orderExecutionReturnBitfield12.ok THEN Fail ELSE
    LET orderExecutionReturnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(orderExecutionReturnBitfield12.rest, 1), orderExecutionReturnBitfield12.rest) IN IF ~orderExecutionReturnBitfield13.ok THEN Fail ELSE
    LET orderExecutionReturnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(orderExecutionReturnBitfield13.rest, 1), orderExecutionReturnBitfield13.rest) IN IF ~orderExecutionReturnBitfield14.ok THEN Fail ELSE
    LET orderExecutionReturnBitfield15 == ReadWhen(numberOfReturnBitfields.value >= 15, ReadBytes(orderExecutionReturnBitfield14.rest, 1), orderExecutionReturnBitfield14.rest) IN IF ~orderExecutionReturnBitfield15.ok THEN Fail ELSE
    LET orderExecutionReturnBitfield16 == ReadWhen(numberOfReturnBitfields.value >= 16, ReadBytes(orderExecutionReturnBitfield15.rest, 1), orderExecutionReturnBitfield15.rest) IN IF ~orderExecutionReturnBitfield16.ok THEN Fail ELSE
    LET orderExecutionReturnBitfield17 == ReadWhen(numberOfReturnBitfields.value >= 17, ReadBytes(orderExecutionReturnBitfield16.rest, 1), orderExecutionReturnBitfield16.rest) IN IF ~orderExecutionReturnBitfield17.ok THEN Fail ELSE
    LET orderExecutionReturnBitfield18 == ReadWhen(numberOfReturnBitfields.value >= 18, ReadUIntLE(orderExecutionReturnBitfield17.rest, 1), orderExecutionReturnBitfield17.rest) IN IF ~orderExecutionReturnBitfield18.ok THEN Fail ELSE
    LET orderExecutionReturnBitfield19 == ReadWhen(numberOfReturnBitfields.value >= 19, ReadBytes(orderExecutionReturnBitfield18.rest, 1), orderExecutionReturnBitfield18.rest) IN IF ~orderExecutionReturnBitfield19.ok THEN Fail ELSE
    LET orderExecutionReturnBitfield20 == ReadWhen(numberOfReturnBitfields.value >= 20, ReadBytes(orderExecutionReturnBitfield19.rest, 1), orderExecutionReturnBitfield19.rest) IN IF ~orderExecutionReturnBitfield20.ok THEN Fail ELSE
    LET orderExecutionReturnBitfield21 == ReadWhen(numberOfReturnBitfields.value >= 21, ReadBytes(orderExecutionReturnBitfield20.rest, 1), orderExecutionReturnBitfield20.rest) IN IF ~orderExecutionReturnBitfield21.ok THEN Fail ELSE
    LET orderExecutionReturnBitfield22 == ReadWhen(numberOfReturnBitfields.value >= 22, ReadBytes(orderExecutionReturnBitfield21.rest, 1), orderExecutionReturnBitfield21.rest) IN IF ~orderExecutionReturnBitfield22.ok THEN Fail ELSE
    LET side == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderExecutionReturnBitfield1.value # << >> /\ orderExecutionReturnBitfield1.value[1] % 2 > 0), ReadBytes(orderExecutionReturnBitfield22.rest, 1), orderExecutionReturnBitfield22.rest) IN IF ~side.ok THEN Fail ELSE
    LET pegDifference == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderExecutionReturnBitfield1.value # << >> /\ (orderExecutionReturnBitfield1.value[1] \div 2) % 2 > 0), ReadBytes(side.rest, 8), side.rest) IN IF ~pegDifference.ok THEN Fail ELSE
    LET price == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderExecutionReturnBitfield1.value # << >> /\ (orderExecutionReturnBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(pegDifference.rest, 8), pegDifference.rest) IN IF ~price.ok THEN Fail ELSE
    LET execInst == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderExecutionReturnBitfield1.value # << >> /\ (orderExecutionReturnBitfield1.value[1] \div 8) % 2 > 0), ReadBytes(price.rest, 1), price.rest) IN IF ~execInst.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderExecutionReturnBitfield1.value # << >> /\ (orderExecutionReturnBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(execInst.rest, 1), execInst.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderExecutionReturnBitfield1.value # << >> /\ (orderExecutionReturnBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderExecutionReturnBitfield1.value # << >> /\ (orderExecutionReturnBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET symbol == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderExecutionReturnBitfield2.value # << >> /\ orderExecutionReturnBitfield2.value[1] % 2 > 0), ReadBytes(minQty.rest, 8), minQty.rest) IN IF ~symbol.ok THEN Fail ELSE
    LET symbolSfx == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderExecutionReturnBitfield2.value # << >> /\ (orderExecutionReturnBitfield2.value[1] \div 2) % 2 > 0), ReadBytes(symbol.rest, 8), symbol.rest) IN IF ~symbolSfx.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderExecutionReturnBitfield2.value # << >> /\ (orderExecutionReturnBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(symbolSfx.rest, 1), symbolSfx.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderExecutionReturnBitfield3.value # << >> /\ orderExecutionReturnBitfield3.value[1] % 2 > 0), ReadBytes(capacity.rest, 16), capacity.rest) IN IF ~account.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderExecutionReturnBitfield3.value # << >> /\ (orderExecutionReturnBitfield3.value[1] \div 2) % 2 > 0), ReadBytes(account.rest, 4), account.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderExecutionReturnBitfield3.value # << >> /\ (orderExecutionReturnBitfield3.value[1] \div 4) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET displayIndicator == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderExecutionReturnBitfield3.value # << >> /\ (orderExecutionReturnBitfield3.value[1] \div 8) % 2 > 0), ReadBytes(clearingAccount.rest, 1), clearingAccount.rest) IN IF ~displayIndicator.ok THEN Fail ELSE
    LET maxFloor == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderExecutionReturnBitfield3.value # << >> /\ (orderExecutionReturnBitfield3.value[1] \div 16) % 2 > 0), ReadBytes(displayIndicator.rest, 4), displayIndicator.rest) IN IF ~maxFloor.ok THEN Fail ELSE
    LET discretionAmount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderExecutionReturnBitfield3.value # << >> /\ (orderExecutionReturnBitfield3.value[1] \div 32) % 2 > 0), ReadBytes(maxFloor.rest, 2), maxFloor.rest) IN IF ~discretionAmount.ok THEN Fail ELSE
    LET orderQty == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderExecutionReturnBitfield3.value # << >> /\ (orderExecutionReturnBitfield3.value[1] \div 64) % 2 > 0), ReadBytes(discretionAmount.rest, 4), discretionAmount.rest) IN IF ~orderQty.ok THEN Fail ELSE
    LET preventMatch == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderExecutionReturnBitfield3.value # << >> /\ (orderExecutionReturnBitfield3.value[1] \div 128) % 2 > 0), ReadBytes(orderQty.rest, 3), orderQty.rest) IN IF ~preventMatch.ok THEN Fail ELSE
    LET attributedQuote == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (orderExecutionReturnBitfield6.value # << >> /\ (orderExecutionReturnBitfield6.value[1] \div 8) % 2 > 0), ReadBytes(preventMatch.rest, 1), preventMatch.rest) IN IF ~attributedQuote.ok THEN Fail ELSE
    LET extExecInst == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (orderExecutionReturnBitfield6.value # << >> /\ (orderExecutionReturnBitfield6.value[1] \div 16) % 2 > 0), ReadBytes(attributedQuote.rest, 1), attributedQuote.rest) IN IF ~extExecInst.ok THEN Fail ELSE
    LET feeCode == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderExecutionReturnBitfield8.value # << >> /\ orderExecutionReturnBitfield8.value[1] % 2 > 0), ReadBytes(extExecInst.rest, 2), extExecInst.rest) IN IF ~feeCode.ok THEN Fail ELSE
    LET echoText == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderExecutionReturnBitfield8.value # << >> /\ (orderExecutionReturnBitfield8.value[1] \div 2) % 2 > 0), ReadBytes(feeCode.rest, 64), feeCode.rest) IN IF ~echoText.ok THEN Fail ELSE
    LET stopPx == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderExecutionReturnBitfield8.value # << >> /\ (orderExecutionReturnBitfield8.value[1] \div 4) % 2 > 0), ReadBytes(echoText.rest, 8), echoText.rest) IN IF ~stopPx.ok THEN Fail ELSE
    LET routingInst == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderExecutionReturnBitfield8.value # << >> /\ (orderExecutionReturnBitfield8.value[1] \div 8) % 2 > 0), ReadBytes(stopPx.rest, 4), stopPx.rest) IN IF ~routingInst.ok THEN Fail ELSE
    LET routStrategy == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderExecutionReturnBitfield8.value # << >> /\ (orderExecutionReturnBitfield8.value[1] \div 16) % 2 > 0), ReadBytes(routingInst.rest, 6), routingInst.rest) IN IF ~routStrategy.ok THEN Fail ELSE
    LET routeDeliveryMethod == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderExecutionReturnBitfield8.value # << >> /\ (orderExecutionReturnBitfield8.value[1] \div 32) % 2 > 0), ReadBytes(routStrategy.rest, 3), routStrategy.rest) IN IF ~routeDeliveryMethod.ok THEN Fail ELSE
    LET exDestination == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderExecutionReturnBitfield8.value # << >> /\ (orderExecutionReturnBitfield8.value[1] \div 64) % 2 > 0), ReadBytes(routeDeliveryMethod.rest, 1), routeDeliveryMethod.rest) IN IF ~exDestination.ok THEN Fail ELSE
    LET crossTradeFlag == ReadWhen(numberOfReturnBitfields.value >= 18 /\ (orderExecutionReturnBitfield18.value # << >> /\ (orderExecutionReturnBitfield18.value[1] \div 8) % 2 > 0), ReadBytes(exDestination.rest, 1), exDestination.rest) IN IF ~crossTradeFlag.ok THEN Fail ELSE
    LET locateBroker == ReadWhen(numberOfReturnBitfields.value >= 18 /\ (orderExecutionReturnBitfield18.value # << >> /\ (orderExecutionReturnBitfield18.value[1] \div 64) % 2 > 0), ReadBytes(crossTradeFlag.rest, 4), crossTradeFlag.rest) IN IF ~locateBroker.ok THEN Fail ELSE
    Ok([ transactionTime                |-> transactionTime.value,
         clOrdId                        |-> clOrdId.value,
         execId                         |-> execId.value,
         lastShares                     |-> lastShares.value,
         lastPx                         |-> lastPx.value,
         leavesQty                      |-> leavesQty.value,
         baseLiquidityIndicator         |-> baseLiquidityIndicator.value,
         subLiquidityIndicator          |-> subLiquidityIndicator.value,
         contraBroker                   |-> contraBroker.value,
         reserved1                      |-> reserved1.value,
         numberOfReturnBitfields        |-> numberOfReturnBitfields.value,
         orderExecutionReturnBitfield1  |-> orderExecutionReturnBitfield1.value,
         orderExecutionReturnBitfield2  |-> orderExecutionReturnBitfield2.value,
         orderExecutionReturnBitfield3  |-> orderExecutionReturnBitfield3.value,
         orderExecutionReturnBitfield4  |-> orderExecutionReturnBitfield4.value,
         orderExecutionReturnBitfield5  |-> orderExecutionReturnBitfield5.value,
         orderExecutionReturnBitfield6  |-> orderExecutionReturnBitfield6.value,
         orderExecutionReturnBitfield7  |-> orderExecutionReturnBitfield7.value,
         orderExecutionReturnBitfield8  |-> orderExecutionReturnBitfield8.value,
         orderExecutionReturnBitfield9  |-> orderExecutionReturnBitfield9.value,
         orderExecutionReturnBitfield10 |-> orderExecutionReturnBitfield10.value,
         orderExecutionReturnBitfield11 |-> orderExecutionReturnBitfield11.value,
         orderExecutionReturnBitfield12 |-> orderExecutionReturnBitfield12.value,
         orderExecutionReturnBitfield13 |-> orderExecutionReturnBitfield13.value,
         orderExecutionReturnBitfield14 |-> orderExecutionReturnBitfield14.value,
         orderExecutionReturnBitfield15 |-> orderExecutionReturnBitfield15.value,
         orderExecutionReturnBitfield16 |-> orderExecutionReturnBitfield16.value,
         orderExecutionReturnBitfield17 |-> orderExecutionReturnBitfield17.value,
         orderExecutionReturnBitfield18 |-> orderExecutionReturnBitfield18.value,
         orderExecutionReturnBitfield19 |-> orderExecutionReturnBitfield19.value,
         orderExecutionReturnBitfield20 |-> orderExecutionReturnBitfield20.value,
         orderExecutionReturnBitfield21 |-> orderExecutionReturnBitfield21.value,
         orderExecutionReturnBitfield22 |-> orderExecutionReturnBitfield22.value,
         side                           |-> side.value,
         pegDifference                  |-> pegDifference.value,
         price                          |-> price.value,
         execInst                       |-> execInst.value,
         ordType                        |-> ordType.value,
         timeInForce                    |-> timeInForce.value,
         minQty                         |-> minQty.value,
         symbol                         |-> symbol.value,
         symbolSfx                      |-> symbolSfx.value,
         capacity                       |-> capacity.value,
         account                        |-> account.value,
         clearingFirm                   |-> clearingFirm.value,
         clearingAccount                |-> clearingAccount.value,
         displayIndicator               |-> displayIndicator.value,
         maxFloor                       |-> maxFloor.value,
         discretionAmount               |-> discretionAmount.value,
         orderQty                       |-> orderQty.value,
         preventMatch                   |-> preventMatch.value,
         attributedQuote                |-> attributedQuote.value,
         extExecInst                    |-> extExecInst.value,
         feeCode                        |-> feeCode.value,
         echoText                       |-> echoText.value,
         stopPx                         |-> stopPx.value,
         routingInst                    |-> routingInst.value,
         routStrategy                   |-> routStrategy.value,
         routeDeliveryMethod            |-> routeDeliveryMethod.value,
         exDestination                  |-> exDestination.value,
         crossTradeFlag                 |-> crossTradeFlag.value,
         locateBroker                   |-> locateBroker.value ], locateBroker.rest)

(* Order Execution Message with each field marked present by fields before it there exactly where they say *)
SettleOrderExecutionMessage(message) ==
    LET settled1 == [message EXCEPT !.orderExecutionReturnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.orderExecutionReturnBitfield1 = << >> THEN <<0>> ELSE message.orderExecutionReturnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.orderExecutionReturnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.orderExecutionReturnBitfield2 = << >> THEN <<0>> ELSE settled1.orderExecutionReturnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.orderExecutionReturnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.orderExecutionReturnBitfield3 = << >> THEN <<0>> ELSE settled2.orderExecutionReturnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.orderExecutionReturnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.orderExecutionReturnBitfield4 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled3.orderExecutionReturnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.orderExecutionReturnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.orderExecutionReturnBitfield5 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled4.orderExecutionReturnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.orderExecutionReturnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.orderExecutionReturnBitfield6 = << >> THEN <<0>> ELSE settled5.orderExecutionReturnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.orderExecutionReturnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.orderExecutionReturnBitfield7 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.orderExecutionReturnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.orderExecutionReturnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.orderExecutionReturnBitfield8 = << >> THEN <<0>> ELSE settled7.orderExecutionReturnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.orderExecutionReturnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.orderExecutionReturnBitfield9 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled8.orderExecutionReturnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.orderExecutionReturnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.orderExecutionReturnBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.orderExecutionReturnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.orderExecutionReturnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.orderExecutionReturnBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.orderExecutionReturnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.orderExecutionReturnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.orderExecutionReturnBitfield12 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.orderExecutionReturnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.orderExecutionReturnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.orderExecutionReturnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.orderExecutionReturnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.orderExecutionReturnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.orderExecutionReturnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.orderExecutionReturnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.orderExecutionReturnBitfield15 = IF settled14.numberOfReturnBitfields >= 15 THEN (IF settled14.orderExecutionReturnBitfield15 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.orderExecutionReturnBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.orderExecutionReturnBitfield16 = IF settled15.numberOfReturnBitfields >= 16 THEN (IF settled15.orderExecutionReturnBitfield16 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled15.orderExecutionReturnBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.orderExecutionReturnBitfield17 = IF settled16.numberOfReturnBitfields >= 17 THEN (IF settled16.orderExecutionReturnBitfield17 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled16.orderExecutionReturnBitfield17) ELSE << >>]
        settled18 == [settled17 EXCEPT !.orderExecutionReturnBitfield18 = IF settled17.numberOfReturnBitfields >= 18 THEN (IF settled17.orderExecutionReturnBitfield18 = << >> THEN <<0>> ELSE settled17.orderExecutionReturnBitfield18) ELSE << >>]
        settled19 == [settled18 EXCEPT !.orderExecutionReturnBitfield19 = IF settled18.numberOfReturnBitfields >= 19 THEN (IF settled18.orderExecutionReturnBitfield19 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled18.orderExecutionReturnBitfield19) ELSE << >>]
        settled20 == [settled19 EXCEPT !.orderExecutionReturnBitfield20 = IF settled19.numberOfReturnBitfields >= 20 THEN (IF settled19.orderExecutionReturnBitfield20 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled19.orderExecutionReturnBitfield20) ELSE << >>]
        settled21 == [settled20 EXCEPT !.orderExecutionReturnBitfield21 = IF settled20.numberOfReturnBitfields >= 21 THEN (IF settled20.orderExecutionReturnBitfield21 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled20.orderExecutionReturnBitfield21) ELSE << >>]
        settled22 == [settled21 EXCEPT !.orderExecutionReturnBitfield22 = IF settled21.numberOfReturnBitfields >= 22 THEN (IF settled21.orderExecutionReturnBitfield22 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled21.orderExecutionReturnBitfield22) ELSE << >>]
        settled23 == [settled22 EXCEPT !.side = IF settled22.numberOfReturnBitfields >= 1 /\ (settled22.orderExecutionReturnBitfield1 # << >> /\ settled22.orderExecutionReturnBitfield1[1] % 2 > 0) THEN (IF settled22.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled22.side) ELSE << >>]
        settled24 == [settled23 EXCEPT !.pegDifference = IF settled23.numberOfReturnBitfields >= 1 /\ (settled23.orderExecutionReturnBitfield1 # << >> /\ (settled23.orderExecutionReturnBitfield1[1] \div 2) % 2 > 0) THEN (IF settled23.pegDifference = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled23.pegDifference) ELSE << >>]
        settled25 == [settled24 EXCEPT !.price = IF settled24.numberOfReturnBitfields >= 1 /\ (settled24.orderExecutionReturnBitfield1 # << >> /\ (settled24.orderExecutionReturnBitfield1[1] \div 4) % 2 > 0) THEN (IF settled24.price = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled24.price) ELSE << >>]
        settled26 == [settled25 EXCEPT !.execInst = IF settled25.numberOfReturnBitfields >= 1 /\ (settled25.orderExecutionReturnBitfield1 # << >> /\ (settled25.orderExecutionReturnBitfield1[1] \div 8) % 2 > 0) THEN (IF settled25.execInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled25.execInst) ELSE << >>]
        settled27 == [settled26 EXCEPT !.ordType = IF settled26.numberOfReturnBitfields >= 1 /\ (settled26.orderExecutionReturnBitfield1 # << >> /\ (settled26.orderExecutionReturnBitfield1[1] \div 16) % 2 > 0) THEN (IF settled26.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled26.ordType) ELSE << >>]
        settled28 == [settled27 EXCEPT !.timeInForce = IF settled27.numberOfReturnBitfields >= 1 /\ (settled27.orderExecutionReturnBitfield1 # << >> /\ (settled27.orderExecutionReturnBitfield1[1] \div 32) % 2 > 0) THEN (IF settled27.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled27.timeInForce) ELSE << >>]
        settled29 == [settled28 EXCEPT !.minQty = IF settled28.numberOfReturnBitfields >= 1 /\ (settled28.orderExecutionReturnBitfield1 # << >> /\ (settled28.orderExecutionReturnBitfield1[1] \div 64) % 2 > 0) THEN (IF settled28.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled28.minQty) ELSE << >>]
        settled30 == [settled29 EXCEPT !.symbol = IF settled29.numberOfReturnBitfields >= 2 /\ (settled29.orderExecutionReturnBitfield2 # << >> /\ settled29.orderExecutionReturnBitfield2[1] % 2 > 0) THEN (IF settled29.symbol = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled29.symbol) ELSE << >>]
        settled31 == [settled30 EXCEPT !.symbolSfx = IF settled30.numberOfReturnBitfields >= 2 /\ (settled30.orderExecutionReturnBitfield2 # << >> /\ (settled30.orderExecutionReturnBitfield2[1] \div 2) % 2 > 0) THEN (IF settled30.symbolSfx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled30.symbolSfx) ELSE << >>]
        settled32 == [settled31 EXCEPT !.capacity = IF settled31.numberOfReturnBitfields >= 2 /\ (settled31.orderExecutionReturnBitfield2 # << >> /\ (settled31.orderExecutionReturnBitfield2[1] \div 64) % 2 > 0) THEN (IF settled31.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled31.capacity) ELSE << >>]
        settled33 == [settled32 EXCEPT !.account = IF settled32.numberOfReturnBitfields >= 3 /\ (settled32.orderExecutionReturnBitfield3 # << >> /\ settled32.orderExecutionReturnBitfield3[1] % 2 > 0) THEN (IF settled32.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled32.account) ELSE << >>]
        settled34 == [settled33 EXCEPT !.clearingFirm = IF settled33.numberOfReturnBitfields >= 3 /\ (settled33.orderExecutionReturnBitfield3 # << >> /\ (settled33.orderExecutionReturnBitfield3[1] \div 2) % 2 > 0) THEN (IF settled33.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled33.clearingFirm) ELSE << >>]
        settled35 == [settled34 EXCEPT !.clearingAccount = IF settled34.numberOfReturnBitfields >= 3 /\ (settled34.orderExecutionReturnBitfield3 # << >> /\ (settled34.orderExecutionReturnBitfield3[1] \div 4) % 2 > 0) THEN (IF settled34.clearingAccount = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled34.clearingAccount) ELSE << >>]
        settled36 == [settled35 EXCEPT !.displayIndicator = IF settled35.numberOfReturnBitfields >= 3 /\ (settled35.orderExecutionReturnBitfield3 # << >> /\ (settled35.orderExecutionReturnBitfield3[1] \div 8) % 2 > 0) THEN (IF settled35.displayIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled35.displayIndicator) ELSE << >>]
        settled37 == [settled36 EXCEPT !.maxFloor = IF settled36.numberOfReturnBitfields >= 3 /\ (settled36.orderExecutionReturnBitfield3 # << >> /\ (settled36.orderExecutionReturnBitfield3[1] \div 16) % 2 > 0) THEN (IF settled36.maxFloor = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled36.maxFloor) ELSE << >>]
        settled38 == [settled37 EXCEPT !.discretionAmount = IF settled37.numberOfReturnBitfields >= 3 /\ (settled37.orderExecutionReturnBitfield3 # << >> /\ (settled37.orderExecutionReturnBitfield3[1] \div 32) % 2 > 0) THEN (IF settled37.discretionAmount = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled37.discretionAmount) ELSE << >>]
        settled39 == [settled38 EXCEPT !.orderQty = IF settled38.numberOfReturnBitfields >= 3 /\ (settled38.orderExecutionReturnBitfield3 # << >> /\ (settled38.orderExecutionReturnBitfield3[1] \div 64) % 2 > 0) THEN (IF settled38.orderQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled38.orderQty) ELSE << >>]
        settled40 == [settled39 EXCEPT !.preventMatch = IF settled39.numberOfReturnBitfields >= 3 /\ (settled39.orderExecutionReturnBitfield3 # << >> /\ (settled39.orderExecutionReturnBitfield3[1] \div 128) % 2 > 0) THEN (IF settled39.preventMatch = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled39.preventMatch) ELSE << >>]
        settled41 == [settled40 EXCEPT !.attributedQuote = IF settled40.numberOfReturnBitfields >= 6 /\ (settled40.orderExecutionReturnBitfield6 # << >> /\ (settled40.orderExecutionReturnBitfield6[1] \div 8) % 2 > 0) THEN (IF settled40.attributedQuote = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled40.attributedQuote) ELSE << >>]
        settled42 == [settled41 EXCEPT !.extExecInst = IF settled41.numberOfReturnBitfields >= 6 /\ (settled41.orderExecutionReturnBitfield6 # << >> /\ (settled41.orderExecutionReturnBitfield6[1] \div 16) % 2 > 0) THEN (IF settled41.extExecInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled41.extExecInst) ELSE << >>]
        settled43 == [settled42 EXCEPT !.feeCode = IF settled42.numberOfReturnBitfields >= 8 /\ (settled42.orderExecutionReturnBitfield8 # << >> /\ settled42.orderExecutionReturnBitfield8[1] % 2 > 0) THEN (IF settled42.feeCode = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled42.feeCode) ELSE << >>]
        settled44 == [settled43 EXCEPT !.echoText = IF settled43.numberOfReturnBitfields >= 8 /\ (settled43.orderExecutionReturnBitfield8 # << >> /\ (settled43.orderExecutionReturnBitfield8[1] \div 2) % 2 > 0) THEN (IF settled43.echoText = << >> THEN <<[i \in 1 .. 64 |-> 0]>> ELSE settled43.echoText) ELSE << >>]
        settled45 == [settled44 EXCEPT !.stopPx = IF settled44.numberOfReturnBitfields >= 8 /\ (settled44.orderExecutionReturnBitfield8 # << >> /\ (settled44.orderExecutionReturnBitfield8[1] \div 4) % 2 > 0) THEN (IF settled44.stopPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled44.stopPx) ELSE << >>]
        settled46 == [settled45 EXCEPT !.routingInst = IF settled45.numberOfReturnBitfields >= 8 /\ (settled45.orderExecutionReturnBitfield8 # << >> /\ (settled45.orderExecutionReturnBitfield8[1] \div 8) % 2 > 0) THEN (IF settled45.routingInst = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled45.routingInst) ELSE << >>]
        settled47 == [settled46 EXCEPT !.routStrategy = IF settled46.numberOfReturnBitfields >= 8 /\ (settled46.orderExecutionReturnBitfield8 # << >> /\ (settled46.orderExecutionReturnBitfield8[1] \div 16) % 2 > 0) THEN (IF settled46.routStrategy = << >> THEN <<[i \in 1 .. 6 |-> 0]>> ELSE settled46.routStrategy) ELSE << >>]
        settled48 == [settled47 EXCEPT !.routeDeliveryMethod = IF settled47.numberOfReturnBitfields >= 8 /\ (settled47.orderExecutionReturnBitfield8 # << >> /\ (settled47.orderExecutionReturnBitfield8[1] \div 32) % 2 > 0) THEN (IF settled47.routeDeliveryMethod = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled47.routeDeliveryMethod) ELSE << >>]
        settled49 == [settled48 EXCEPT !.exDestination = IF settled48.numberOfReturnBitfields >= 8 /\ (settled48.orderExecutionReturnBitfield8 # << >> /\ (settled48.orderExecutionReturnBitfield8[1] \div 64) % 2 > 0) THEN (IF settled48.exDestination = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled48.exDestination) ELSE << >>]
        settled50 == [settled49 EXCEPT !.crossTradeFlag = IF settled49.numberOfReturnBitfields >= 18 /\ (settled49.orderExecutionReturnBitfield18 # << >> /\ (settled49.orderExecutionReturnBitfield18[1] \div 8) % 2 > 0) THEN (IF settled49.crossTradeFlag = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled49.crossTradeFlag) ELSE << >>]
        settled51 == [settled50 EXCEPT !.locateBroker = IF settled50.numberOfReturnBitfields >= 18 /\ (settled50.orderExecutionReturnBitfield18 # << >> /\ (settled50.orderExecutionReturnBitfield18[1] \div 64) % 2 > 0) THEN (IF settled50.locateBroker = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled50.locateBroker) ELSE << >>]
    IN  settled51

ZeroOrderExecutionMessage ==
    SettleOrderExecutionMessage([ transactionTime                |-> [i \in 1 .. 8 |-> 0],
                                  clOrdId                        |-> [i \in 1 .. 20 |-> 0],
                                  execId                         |-> [i \in 1 .. 8 |-> 0],
                                  lastShares                     |-> [i \in 1 .. 4 |-> 0],
                                  lastPx                         |-> [i \in 1 .. 8 |-> 0],
                                  leavesQty                      |-> [i \in 1 .. 4 |-> 0],
                                  baseLiquidityIndicator         |-> [i \in 1 .. 1 |-> 0],
                                  subLiquidityIndicator          |-> [i \in 1 .. 1 |-> 0],
                                  contraBroker                   |-> [i \in 1 .. 4 |-> 0],
                                  reserved1                      |-> [i \in 1 .. 1 |-> 0],
                                  numberOfReturnBitfields        |-> 0,
                                  orderExecutionReturnBitfield1  |-> << >>,
                                  orderExecutionReturnBitfield2  |-> << >>,
                                  orderExecutionReturnBitfield3  |-> << >>,
                                  orderExecutionReturnBitfield4  |-> << >>,
                                  orderExecutionReturnBitfield5  |-> << >>,
                                  orderExecutionReturnBitfield6  |-> << >>,
                                  orderExecutionReturnBitfield7  |-> << >>,
                                  orderExecutionReturnBitfield8  |-> << >>,
                                  orderExecutionReturnBitfield9  |-> << >>,
                                  orderExecutionReturnBitfield10 |-> << >>,
                                  orderExecutionReturnBitfield11 |-> << >>,
                                  orderExecutionReturnBitfield12 |-> << >>,
                                  orderExecutionReturnBitfield13 |-> << >>,
                                  orderExecutionReturnBitfield14 |-> << >>,
                                  orderExecutionReturnBitfield15 |-> << >>,
                                  orderExecutionReturnBitfield16 |-> << >>,
                                  orderExecutionReturnBitfield17 |-> << >>,
                                  orderExecutionReturnBitfield18 |-> << >>,
                                  orderExecutionReturnBitfield19 |-> << >>,
                                  orderExecutionReturnBitfield20 |-> << >>,
                                  orderExecutionReturnBitfield21 |-> << >>,
                                  orderExecutionReturnBitfield22 |-> << >>,
                                  side                           |-> << >>,
                                  pegDifference                  |-> << >>,
                                  price                          |-> << >>,
                                  execInst                       |-> << >>,
                                  ordType                        |-> << >>,
                                  timeInForce                    |-> << >>,
                                  minQty                         |-> << >>,
                                  symbol                         |-> << >>,
                                  symbolSfx                      |-> << >>,
                                  capacity                       |-> << >>,
                                  account                        |-> << >>,
                                  clearingFirm                   |-> << >>,
                                  clearingAccount                |-> << >>,
                                  displayIndicator               |-> << >>,
                                  maxFloor                       |-> << >>,
                                  discretionAmount               |-> << >>,
                                  orderQty                       |-> << >>,
                                  preventMatch                   |-> << >>,
                                  attributedQuote                |-> << >>,
                                  extExecInst                    |-> << >>,
                                  feeCode                        |-> << >>,
                                  echoText                       |-> << >>,
                                  stopPx                         |-> << >>,
                                  routingInst                    |-> << >>,
                                  routStrategy                   |-> << >>,
                                  routeDeliveryMethod            |-> << >>,
                                  exDestination                  |-> << >>,
                                  crossTradeFlag                 |-> << >>,
                                  locateBroker                   |-> << >> ])

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
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderExecutionReturnBitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 2, !.orderExecutionReturnBitfield2 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderExecutionReturnBitfield3 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 4, !.orderExecutionReturnBitfield4 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderExecutionReturnBitfield5 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 6, !.orderExecutionReturnBitfield6 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 7, !.orderExecutionReturnBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderExecutionReturnBitfield8 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 9, !.orderExecutionReturnBitfield9 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 10, !.orderExecutionReturnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 11, !.orderExecutionReturnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 12, !.orderExecutionReturnBitfield12 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 13, !.orderExecutionReturnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 14, !.orderExecutionReturnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 15, !.orderExecutionReturnBitfield15 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 16, !.orderExecutionReturnBitfield16 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 17, !.orderExecutionReturnBitfield17 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 18, !.orderExecutionReturnBitfield18 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 19, !.orderExecutionReturnBitfield19 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 20, !.orderExecutionReturnBitfield20 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 21, !.orderExecutionReturnBitfield21 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 22, !.orderExecutionReturnBitfield22 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderExecutionReturnBitfield1 = <<1>>, !.side = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderExecutionReturnBitfield1 = <<2>>, !.pegDifference = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderExecutionReturnBitfield1 = <<4>>, !.price = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderExecutionReturnBitfield1 = <<8>>, !.execInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderExecutionReturnBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderExecutionReturnBitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderExecutionReturnBitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 2, !.orderExecutionReturnBitfield2 = <<1>>, !.symbol = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 2, !.orderExecutionReturnBitfield2 = <<2>>, !.symbolSfx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 2, !.orderExecutionReturnBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderExecutionReturnBitfield3 = <<1>>, !.account = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderExecutionReturnBitfield3 = <<2>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderExecutionReturnBitfield3 = <<4>>, !.clearingAccount = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderExecutionReturnBitfield3 = <<8>>, !.displayIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderExecutionReturnBitfield3 = <<16>>, !.maxFloor = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderExecutionReturnBitfield3 = <<32>>, !.discretionAmount = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderExecutionReturnBitfield3 = <<64>>, !.orderQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderExecutionReturnBitfield3 = <<128>>, !.preventMatch = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 6, !.orderExecutionReturnBitfield6 = <<8>>, !.attributedQuote = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 6, !.orderExecutionReturnBitfield6 = <<16>>, !.extExecInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderExecutionReturnBitfield8 = <<1>>, !.feeCode = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderExecutionReturnBitfield8 = <<2>>, !.echoText = one]) : one \in { <<held>> : held \in Sample(64) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderExecutionReturnBitfield8 = <<4>>, !.stopPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderExecutionReturnBitfield8 = <<8>>, !.routingInst = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderExecutionReturnBitfield8 = <<16>>, !.routStrategy = one]) : one \in { <<held>> : held \in Sample(6) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderExecutionReturnBitfield8 = <<32>>, !.routeDeliveryMethod = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderExecutionReturnBitfield8 = <<64>>, !.exDestination = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 18, !.orderExecutionReturnBitfield18 = <<8>>, !.crossTradeFlag = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 18, !.orderExecutionReturnBitfield18 = <<64>>, !.locateBroker = one]) : one \in { <<held>> : held \in Sample(4) } }

(***************************************************************************)
(* Trade Cancel Or Correct Message                                         *)
(***************************************************************************)

TradeCancelOrCorrectMessage ==
    [ transactionTime                      : Sample(8),
      clOrdId                              : Sample(20),
      orderId                              : Sample(8),
      execRefId                            : Sample(8),
      side                                 : Sample(1),
      baseLiquidityIndicator               : Sample(1),
      clearingFirm                         : Sample(4),
      clearingAccount                      : Sample(4),
      lastShares                           : Sample(4),
      lastPx                               : Sample(8),
      correctedPrice                       : Sample(8),
      origTime                             : Sample(8),
      reserved1                            : Sample(1),
      numberOfReturnBitfields              : 0 .. 255,
      tradeCancelorCorrectReturnBitfield1  : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCancelorCorrectReturnBitfield2  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCancelorCorrectReturnBitfield3  : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCancelorCorrectReturnBitfield4  : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCancelorCorrectReturnBitfield5  : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCancelorCorrectReturnBitfield6  : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCancelorCorrectReturnBitfield7  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCancelorCorrectReturnBitfield8  : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCancelorCorrectReturnBitfield9  : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCancelorCorrectReturnBitfield10 : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCancelorCorrectReturnBitfield11 : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCancelorCorrectReturnBitfield12 : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCancelorCorrectReturnBitfield13 : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCancelorCorrectReturnBitfield14 : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCancelorCorrectReturnBitfield15 : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCancelorCorrectReturnBitfield16 : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCancelorCorrectReturnBitfield17 : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCancelorCorrectReturnBitfield18 : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCancelorCorrectReturnBitfield19 : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCancelorCorrectReturnBitfield20 : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCancelorCorrectReturnBitfield21 : { << >> } \cup { <<held>> : held \in Sample(1) },
      symbol                               : { << >> } \cup { <<held>> : held \in Sample(8) },
      symbolSfx                            : { << >> } \cup { <<held>> : held \in Sample(8) },
      capacity                             : { << >> } \cup { <<held>> : held \in Sample(1) },
      subLiquidityIndicator                : { << >> } \cup { <<held>> : held \in Sample(1) } ]

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
        \o (IF message.tradeCancelorCorrectReturnBitfield1 = << >> THEN << >> ELSE message.tradeCancelorCorrectReturnBitfield1[1])
        \o (IF message.tradeCancelorCorrectReturnBitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCancelorCorrectReturnBitfield2[1], 1))
        \o (IF message.tradeCancelorCorrectReturnBitfield3 = << >> THEN << >> ELSE message.tradeCancelorCorrectReturnBitfield3[1])
        \o (IF message.tradeCancelorCorrectReturnBitfield4 = << >> THEN << >> ELSE message.tradeCancelorCorrectReturnBitfield4[1])
        \o (IF message.tradeCancelorCorrectReturnBitfield5 = << >> THEN << >> ELSE message.tradeCancelorCorrectReturnBitfield5[1])
        \o (IF message.tradeCancelorCorrectReturnBitfield6 = << >> THEN << >> ELSE message.tradeCancelorCorrectReturnBitfield6[1])
        \o (IF message.tradeCancelorCorrectReturnBitfield7 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCancelorCorrectReturnBitfield7[1], 1))
        \o (IF message.tradeCancelorCorrectReturnBitfield8 = << >> THEN << >> ELSE message.tradeCancelorCorrectReturnBitfield8[1])
        \o (IF message.tradeCancelorCorrectReturnBitfield9 = << >> THEN << >> ELSE message.tradeCancelorCorrectReturnBitfield9[1])
        \o (IF message.tradeCancelorCorrectReturnBitfield10 = << >> THEN << >> ELSE message.tradeCancelorCorrectReturnBitfield10[1])
        \o (IF message.tradeCancelorCorrectReturnBitfield11 = << >> THEN << >> ELSE message.tradeCancelorCorrectReturnBitfield11[1])
        \o (IF message.tradeCancelorCorrectReturnBitfield12 = << >> THEN << >> ELSE message.tradeCancelorCorrectReturnBitfield12[1])
        \o (IF message.tradeCancelorCorrectReturnBitfield13 = << >> THEN << >> ELSE message.tradeCancelorCorrectReturnBitfield13[1])
        \o (IF message.tradeCancelorCorrectReturnBitfield14 = << >> THEN << >> ELSE message.tradeCancelorCorrectReturnBitfield14[1])
        \o (IF message.tradeCancelorCorrectReturnBitfield15 = << >> THEN << >> ELSE message.tradeCancelorCorrectReturnBitfield15[1])
        \o (IF message.tradeCancelorCorrectReturnBitfield16 = << >> THEN << >> ELSE message.tradeCancelorCorrectReturnBitfield16[1])
        \o (IF message.tradeCancelorCorrectReturnBitfield17 = << >> THEN << >> ELSE message.tradeCancelorCorrectReturnBitfield17[1])
        \o (IF message.tradeCancelorCorrectReturnBitfield18 = << >> THEN << >> ELSE message.tradeCancelorCorrectReturnBitfield18[1])
        \o (IF message.tradeCancelorCorrectReturnBitfield19 = << >> THEN << >> ELSE message.tradeCancelorCorrectReturnBitfield19[1])
        \o (IF message.tradeCancelorCorrectReturnBitfield20 = << >> THEN << >> ELSE message.tradeCancelorCorrectReturnBitfield20[1])
        \o (IF message.tradeCancelorCorrectReturnBitfield21 = << >> THEN << >> ELSE message.tradeCancelorCorrectReturnBitfield21[1])
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
    LET tradeCancelorCorrectReturnBitfield1 == ReadWhen(numberOfReturnBitfields.value >= 1, ReadBytes(numberOfReturnBitfields.rest, 1), numberOfReturnBitfields.rest) IN IF ~tradeCancelorCorrectReturnBitfield1.ok THEN Fail ELSE
    LET tradeCancelorCorrectReturnBitfield2 == ReadWhen(numberOfReturnBitfields.value >= 2, ReadUIntLE(tradeCancelorCorrectReturnBitfield1.rest, 1), tradeCancelorCorrectReturnBitfield1.rest) IN IF ~tradeCancelorCorrectReturnBitfield2.ok THEN Fail ELSE
    LET tradeCancelorCorrectReturnBitfield3 == ReadWhen(numberOfReturnBitfields.value >= 3, ReadBytes(tradeCancelorCorrectReturnBitfield2.rest, 1), tradeCancelorCorrectReturnBitfield2.rest) IN IF ~tradeCancelorCorrectReturnBitfield3.ok THEN Fail ELSE
    LET tradeCancelorCorrectReturnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadBytes(tradeCancelorCorrectReturnBitfield3.rest, 1), tradeCancelorCorrectReturnBitfield3.rest) IN IF ~tradeCancelorCorrectReturnBitfield4.ok THEN Fail ELSE
    LET tradeCancelorCorrectReturnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadBytes(tradeCancelorCorrectReturnBitfield4.rest, 1), tradeCancelorCorrectReturnBitfield4.rest) IN IF ~tradeCancelorCorrectReturnBitfield5.ok THEN Fail ELSE
    LET tradeCancelorCorrectReturnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadBytes(tradeCancelorCorrectReturnBitfield5.rest, 1), tradeCancelorCorrectReturnBitfield5.rest) IN IF ~tradeCancelorCorrectReturnBitfield6.ok THEN Fail ELSE
    LET tradeCancelorCorrectReturnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadUIntLE(tradeCancelorCorrectReturnBitfield6.rest, 1), tradeCancelorCorrectReturnBitfield6.rest) IN IF ~tradeCancelorCorrectReturnBitfield7.ok THEN Fail ELSE
    LET tradeCancelorCorrectReturnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadBytes(tradeCancelorCorrectReturnBitfield7.rest, 1), tradeCancelorCorrectReturnBitfield7.rest) IN IF ~tradeCancelorCorrectReturnBitfield8.ok THEN Fail ELSE
    LET tradeCancelorCorrectReturnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadBytes(tradeCancelorCorrectReturnBitfield8.rest, 1), tradeCancelorCorrectReturnBitfield8.rest) IN IF ~tradeCancelorCorrectReturnBitfield9.ok THEN Fail ELSE
    LET tradeCancelorCorrectReturnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadBytes(tradeCancelorCorrectReturnBitfield9.rest, 1), tradeCancelorCorrectReturnBitfield9.rest) IN IF ~tradeCancelorCorrectReturnBitfield10.ok THEN Fail ELSE
    LET tradeCancelorCorrectReturnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadBytes(tradeCancelorCorrectReturnBitfield10.rest, 1), tradeCancelorCorrectReturnBitfield10.rest) IN IF ~tradeCancelorCorrectReturnBitfield11.ok THEN Fail ELSE
    LET tradeCancelorCorrectReturnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadBytes(tradeCancelorCorrectReturnBitfield11.rest, 1), tradeCancelorCorrectReturnBitfield11.rest) IN IF ~tradeCancelorCorrectReturnBitfield12.ok THEN Fail ELSE
    LET tradeCancelorCorrectReturnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(tradeCancelorCorrectReturnBitfield12.rest, 1), tradeCancelorCorrectReturnBitfield12.rest) IN IF ~tradeCancelorCorrectReturnBitfield13.ok THEN Fail ELSE
    LET tradeCancelorCorrectReturnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(tradeCancelorCorrectReturnBitfield13.rest, 1), tradeCancelorCorrectReturnBitfield13.rest) IN IF ~tradeCancelorCorrectReturnBitfield14.ok THEN Fail ELSE
    LET tradeCancelorCorrectReturnBitfield15 == ReadWhen(numberOfReturnBitfields.value >= 15, ReadBytes(tradeCancelorCorrectReturnBitfield14.rest, 1), tradeCancelorCorrectReturnBitfield14.rest) IN IF ~tradeCancelorCorrectReturnBitfield15.ok THEN Fail ELSE
    LET tradeCancelorCorrectReturnBitfield16 == ReadWhen(numberOfReturnBitfields.value >= 16, ReadBytes(tradeCancelorCorrectReturnBitfield15.rest, 1), tradeCancelorCorrectReturnBitfield15.rest) IN IF ~tradeCancelorCorrectReturnBitfield16.ok THEN Fail ELSE
    LET tradeCancelorCorrectReturnBitfield17 == ReadWhen(numberOfReturnBitfields.value >= 17, ReadBytes(tradeCancelorCorrectReturnBitfield16.rest, 1), tradeCancelorCorrectReturnBitfield16.rest) IN IF ~tradeCancelorCorrectReturnBitfield17.ok THEN Fail ELSE
    LET tradeCancelorCorrectReturnBitfield18 == ReadWhen(numberOfReturnBitfields.value >= 18, ReadBytes(tradeCancelorCorrectReturnBitfield17.rest, 1), tradeCancelorCorrectReturnBitfield17.rest) IN IF ~tradeCancelorCorrectReturnBitfield18.ok THEN Fail ELSE
    LET tradeCancelorCorrectReturnBitfield19 == ReadWhen(numberOfReturnBitfields.value >= 19, ReadBytes(tradeCancelorCorrectReturnBitfield18.rest, 1), tradeCancelorCorrectReturnBitfield18.rest) IN IF ~tradeCancelorCorrectReturnBitfield19.ok THEN Fail ELSE
    LET tradeCancelorCorrectReturnBitfield20 == ReadWhen(numberOfReturnBitfields.value >= 20, ReadBytes(tradeCancelorCorrectReturnBitfield19.rest, 1), tradeCancelorCorrectReturnBitfield19.rest) IN IF ~tradeCancelorCorrectReturnBitfield20.ok THEN Fail ELSE
    LET tradeCancelorCorrectReturnBitfield21 == ReadWhen(numberOfReturnBitfields.value >= 21, ReadBytes(tradeCancelorCorrectReturnBitfield20.rest, 1), tradeCancelorCorrectReturnBitfield20.rest) IN IF ~tradeCancelorCorrectReturnBitfield21.ok THEN Fail ELSE
    LET symbol == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (tradeCancelorCorrectReturnBitfield2.value # << >> /\ tradeCancelorCorrectReturnBitfield2.value[1] % 2 > 0), ReadBytes(tradeCancelorCorrectReturnBitfield21.rest, 8), tradeCancelorCorrectReturnBitfield21.rest) IN IF ~symbol.ok THEN Fail ELSE
    LET symbolSfx == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (tradeCancelorCorrectReturnBitfield2.value # << >> /\ (tradeCancelorCorrectReturnBitfield2.value[1] \div 2) % 2 > 0), ReadBytes(symbol.rest, 8), symbol.rest) IN IF ~symbolSfx.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (tradeCancelorCorrectReturnBitfield2.value # << >> /\ (tradeCancelorCorrectReturnBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(symbolSfx.rest, 1), symbolSfx.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET subLiquidityIndicator == ReadWhen(numberOfReturnBitfields.value >= 7 /\ (tradeCancelorCorrectReturnBitfield7.value # << >> /\ tradeCancelorCorrectReturnBitfield7.value[1] % 2 > 0), ReadBytes(capacity.rest, 1), capacity.rest) IN IF ~subLiquidityIndicator.ok THEN Fail ELSE
    Ok([ transactionTime                      |-> transactionTime.value,
         clOrdId                              |-> clOrdId.value,
         orderId                              |-> orderId.value,
         execRefId                            |-> execRefId.value,
         side                                 |-> side.value,
         baseLiquidityIndicator               |-> baseLiquidityIndicator.value,
         clearingFirm                         |-> clearingFirm.value,
         clearingAccount                      |-> clearingAccount.value,
         lastShares                           |-> lastShares.value,
         lastPx                               |-> lastPx.value,
         correctedPrice                       |-> correctedPrice.value,
         origTime                             |-> origTime.value,
         reserved1                            |-> reserved1.value,
         numberOfReturnBitfields              |-> numberOfReturnBitfields.value,
         tradeCancelorCorrectReturnBitfield1  |-> tradeCancelorCorrectReturnBitfield1.value,
         tradeCancelorCorrectReturnBitfield2  |-> tradeCancelorCorrectReturnBitfield2.value,
         tradeCancelorCorrectReturnBitfield3  |-> tradeCancelorCorrectReturnBitfield3.value,
         tradeCancelorCorrectReturnBitfield4  |-> tradeCancelorCorrectReturnBitfield4.value,
         tradeCancelorCorrectReturnBitfield5  |-> tradeCancelorCorrectReturnBitfield5.value,
         tradeCancelorCorrectReturnBitfield6  |-> tradeCancelorCorrectReturnBitfield6.value,
         tradeCancelorCorrectReturnBitfield7  |-> tradeCancelorCorrectReturnBitfield7.value,
         tradeCancelorCorrectReturnBitfield8  |-> tradeCancelorCorrectReturnBitfield8.value,
         tradeCancelorCorrectReturnBitfield9  |-> tradeCancelorCorrectReturnBitfield9.value,
         tradeCancelorCorrectReturnBitfield10 |-> tradeCancelorCorrectReturnBitfield10.value,
         tradeCancelorCorrectReturnBitfield11 |-> tradeCancelorCorrectReturnBitfield11.value,
         tradeCancelorCorrectReturnBitfield12 |-> tradeCancelorCorrectReturnBitfield12.value,
         tradeCancelorCorrectReturnBitfield13 |-> tradeCancelorCorrectReturnBitfield13.value,
         tradeCancelorCorrectReturnBitfield14 |-> tradeCancelorCorrectReturnBitfield14.value,
         tradeCancelorCorrectReturnBitfield15 |-> tradeCancelorCorrectReturnBitfield15.value,
         tradeCancelorCorrectReturnBitfield16 |-> tradeCancelorCorrectReturnBitfield16.value,
         tradeCancelorCorrectReturnBitfield17 |-> tradeCancelorCorrectReturnBitfield17.value,
         tradeCancelorCorrectReturnBitfield18 |-> tradeCancelorCorrectReturnBitfield18.value,
         tradeCancelorCorrectReturnBitfield19 |-> tradeCancelorCorrectReturnBitfield19.value,
         tradeCancelorCorrectReturnBitfield20 |-> tradeCancelorCorrectReturnBitfield20.value,
         tradeCancelorCorrectReturnBitfield21 |-> tradeCancelorCorrectReturnBitfield21.value,
         symbol                               |-> symbol.value,
         symbolSfx                            |-> symbolSfx.value,
         capacity                             |-> capacity.value,
         subLiquidityIndicator                |-> subLiquidityIndicator.value ], subLiquidityIndicator.rest)

(* Trade Cancel Or Correct Message with each field marked present by fields before it there exactly where they say *)
SettleTradeCancelOrCorrectMessage(message) ==
    LET settled1 == [message EXCEPT !.tradeCancelorCorrectReturnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.tradeCancelorCorrectReturnBitfield1 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE message.tradeCancelorCorrectReturnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.tradeCancelorCorrectReturnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.tradeCancelorCorrectReturnBitfield2 = << >> THEN <<0>> ELSE settled1.tradeCancelorCorrectReturnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.tradeCancelorCorrectReturnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.tradeCancelorCorrectReturnBitfield3 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled2.tradeCancelorCorrectReturnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.tradeCancelorCorrectReturnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.tradeCancelorCorrectReturnBitfield4 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled3.tradeCancelorCorrectReturnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.tradeCancelorCorrectReturnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.tradeCancelorCorrectReturnBitfield5 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled4.tradeCancelorCorrectReturnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.tradeCancelorCorrectReturnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.tradeCancelorCorrectReturnBitfield6 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled5.tradeCancelorCorrectReturnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.tradeCancelorCorrectReturnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.tradeCancelorCorrectReturnBitfield7 = << >> THEN <<0>> ELSE settled6.tradeCancelorCorrectReturnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.tradeCancelorCorrectReturnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.tradeCancelorCorrectReturnBitfield8 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled7.tradeCancelorCorrectReturnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.tradeCancelorCorrectReturnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.tradeCancelorCorrectReturnBitfield9 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled8.tradeCancelorCorrectReturnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.tradeCancelorCorrectReturnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.tradeCancelorCorrectReturnBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.tradeCancelorCorrectReturnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.tradeCancelorCorrectReturnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.tradeCancelorCorrectReturnBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.tradeCancelorCorrectReturnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.tradeCancelorCorrectReturnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.tradeCancelorCorrectReturnBitfield12 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.tradeCancelorCorrectReturnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.tradeCancelorCorrectReturnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.tradeCancelorCorrectReturnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.tradeCancelorCorrectReturnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.tradeCancelorCorrectReturnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.tradeCancelorCorrectReturnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.tradeCancelorCorrectReturnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.tradeCancelorCorrectReturnBitfield15 = IF settled14.numberOfReturnBitfields >= 15 THEN (IF settled14.tradeCancelorCorrectReturnBitfield15 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.tradeCancelorCorrectReturnBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.tradeCancelorCorrectReturnBitfield16 = IF settled15.numberOfReturnBitfields >= 16 THEN (IF settled15.tradeCancelorCorrectReturnBitfield16 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled15.tradeCancelorCorrectReturnBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.tradeCancelorCorrectReturnBitfield17 = IF settled16.numberOfReturnBitfields >= 17 THEN (IF settled16.tradeCancelorCorrectReturnBitfield17 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled16.tradeCancelorCorrectReturnBitfield17) ELSE << >>]
        settled18 == [settled17 EXCEPT !.tradeCancelorCorrectReturnBitfield18 = IF settled17.numberOfReturnBitfields >= 18 THEN (IF settled17.tradeCancelorCorrectReturnBitfield18 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.tradeCancelorCorrectReturnBitfield18) ELSE << >>]
        settled19 == [settled18 EXCEPT !.tradeCancelorCorrectReturnBitfield19 = IF settled18.numberOfReturnBitfields >= 19 THEN (IF settled18.tradeCancelorCorrectReturnBitfield19 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled18.tradeCancelorCorrectReturnBitfield19) ELSE << >>]
        settled20 == [settled19 EXCEPT !.tradeCancelorCorrectReturnBitfield20 = IF settled19.numberOfReturnBitfields >= 20 THEN (IF settled19.tradeCancelorCorrectReturnBitfield20 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled19.tradeCancelorCorrectReturnBitfield20) ELSE << >>]
        settled21 == [settled20 EXCEPT !.tradeCancelorCorrectReturnBitfield21 = IF settled20.numberOfReturnBitfields >= 21 THEN (IF settled20.tradeCancelorCorrectReturnBitfield21 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled20.tradeCancelorCorrectReturnBitfield21) ELSE << >>]
        settled22 == [settled21 EXCEPT !.symbol = IF settled21.numberOfReturnBitfields >= 2 /\ (settled21.tradeCancelorCorrectReturnBitfield2 # << >> /\ settled21.tradeCancelorCorrectReturnBitfield2[1] % 2 > 0) THEN (IF settled21.symbol = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled21.symbol) ELSE << >>]
        settled23 == [settled22 EXCEPT !.symbolSfx = IF settled22.numberOfReturnBitfields >= 2 /\ (settled22.tradeCancelorCorrectReturnBitfield2 # << >> /\ (settled22.tradeCancelorCorrectReturnBitfield2[1] \div 2) % 2 > 0) THEN (IF settled22.symbolSfx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled22.symbolSfx) ELSE << >>]
        settled24 == [settled23 EXCEPT !.capacity = IF settled23.numberOfReturnBitfields >= 2 /\ (settled23.tradeCancelorCorrectReturnBitfield2 # << >> /\ (settled23.tradeCancelorCorrectReturnBitfield2[1] \div 64) % 2 > 0) THEN (IF settled23.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled23.capacity) ELSE << >>]
        settled25 == [settled24 EXCEPT !.subLiquidityIndicator = IF settled24.numberOfReturnBitfields >= 7 /\ (settled24.tradeCancelorCorrectReturnBitfield7 # << >> /\ settled24.tradeCancelorCorrectReturnBitfield7[1] % 2 > 0) THEN (IF settled24.subLiquidityIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled24.subLiquidityIndicator) ELSE << >>]
    IN  settled25

ZeroTradeCancelOrCorrectMessage ==
    SettleTradeCancelOrCorrectMessage([ transactionTime                      |-> [i \in 1 .. 8 |-> 0],
                                        clOrdId                              |-> [i \in 1 .. 20 |-> 0],
                                        orderId                              |-> [i \in 1 .. 8 |-> 0],
                                        execRefId                            |-> [i \in 1 .. 8 |-> 0],
                                        side                                 |-> [i \in 1 .. 1 |-> 0],
                                        baseLiquidityIndicator               |-> [i \in 1 .. 1 |-> 0],
                                        clearingFirm                         |-> [i \in 1 .. 4 |-> 0],
                                        clearingAccount                      |-> [i \in 1 .. 4 |-> 0],
                                        lastShares                           |-> [i \in 1 .. 4 |-> 0],
                                        lastPx                               |-> [i \in 1 .. 8 |-> 0],
                                        correctedPrice                       |-> [i \in 1 .. 8 |-> 0],
                                        origTime                             |-> [i \in 1 .. 8 |-> 0],
                                        reserved1                            |-> [i \in 1 .. 1 |-> 0],
                                        numberOfReturnBitfields              |-> 0,
                                        tradeCancelorCorrectReturnBitfield1  |-> << >>,
                                        tradeCancelorCorrectReturnBitfield2  |-> << >>,
                                        tradeCancelorCorrectReturnBitfield3  |-> << >>,
                                        tradeCancelorCorrectReturnBitfield4  |-> << >>,
                                        tradeCancelorCorrectReturnBitfield5  |-> << >>,
                                        tradeCancelorCorrectReturnBitfield6  |-> << >>,
                                        tradeCancelorCorrectReturnBitfield7  |-> << >>,
                                        tradeCancelorCorrectReturnBitfield8  |-> << >>,
                                        tradeCancelorCorrectReturnBitfield9  |-> << >>,
                                        tradeCancelorCorrectReturnBitfield10 |-> << >>,
                                        tradeCancelorCorrectReturnBitfield11 |-> << >>,
                                        tradeCancelorCorrectReturnBitfield12 |-> << >>,
                                        tradeCancelorCorrectReturnBitfield13 |-> << >>,
                                        tradeCancelorCorrectReturnBitfield14 |-> << >>,
                                        tradeCancelorCorrectReturnBitfield15 |-> << >>,
                                        tradeCancelorCorrectReturnBitfield16 |-> << >>,
                                        tradeCancelorCorrectReturnBitfield17 |-> << >>,
                                        tradeCancelorCorrectReturnBitfield18 |-> << >>,
                                        tradeCancelorCorrectReturnBitfield19 |-> << >>,
                                        tradeCancelorCorrectReturnBitfield20 |-> << >>,
                                        tradeCancelorCorrectReturnBitfield21 |-> << >>,
                                        symbol                               |-> << >>,
                                        symbolSfx                            |-> << >>,
                                        capacity                             |-> << >>,
                                        subLiquidityIndicator                |-> << >> ])

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
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 1, !.tradeCancelorCorrectReturnBitfield1 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 2, !.tradeCancelorCorrectReturnBitfield2 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 3, !.tradeCancelorCorrectReturnBitfield3 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 4, !.tradeCancelorCorrectReturnBitfield4 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 5, !.tradeCancelorCorrectReturnBitfield5 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 6, !.tradeCancelorCorrectReturnBitfield6 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 7, !.tradeCancelorCorrectReturnBitfield7 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 8, !.tradeCancelorCorrectReturnBitfield8 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 9, !.tradeCancelorCorrectReturnBitfield9 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 10, !.tradeCancelorCorrectReturnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 11, !.tradeCancelorCorrectReturnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 12, !.tradeCancelorCorrectReturnBitfield12 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 13, !.tradeCancelorCorrectReturnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 14, !.tradeCancelorCorrectReturnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 15, !.tradeCancelorCorrectReturnBitfield15 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 16, !.tradeCancelorCorrectReturnBitfield16 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 17, !.tradeCancelorCorrectReturnBitfield17 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 18, !.tradeCancelorCorrectReturnBitfield18 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 19, !.tradeCancelorCorrectReturnBitfield19 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 20, !.tradeCancelorCorrectReturnBitfield20 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 21, !.tradeCancelorCorrectReturnBitfield21 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 2, !.tradeCancelorCorrectReturnBitfield2 = <<1>>, !.symbol = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 2, !.tradeCancelorCorrectReturnBitfield2 = <<2>>, !.symbolSfx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 2, !.tradeCancelorCorrectReturnBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 7, !.tradeCancelorCorrectReturnBitfield7 = <<1>>, !.subLiquidityIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }

(***************************************************************************)
(* Mass Cancel Acknowledgment Message: 33 bytes                            *)
(***************************************************************************)

MassCancelAcknowledgmentMessage ==
    [ transactionTime    : Sample(8),
      massCancelId       : Sample(20),
      cancelledOrderCoun : Sample(4),
      reserved1          : Sample(1) ]

EncodeMassCancelAcknowledgmentMessage(message) ==
    message.transactionTime
        \o message.massCancelId
        \o message.cancelledOrderCoun
        \o message.reserved1

DecodeMassCancelAcknowledgmentMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET massCancelId == ReadBytes(transactionTime.rest, 20) IN IF ~massCancelId.ok THEN Fail ELSE
    LET cancelledOrderCoun == ReadBytes(massCancelId.rest, 4) IN IF ~cancelledOrderCoun.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(cancelledOrderCoun.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ transactionTime    |-> transactionTime.value,
         massCancelId       |-> massCancelId.value,
         cancelledOrderCoun |-> cancelledOrderCoun.value,
         reserved1          |-> reserved1.value ], reserved1.rest)

ZeroMassCancelAcknowledgmentMessage ==
    [ transactionTime    |-> [i \in 1 .. 8 |-> 0],
      massCancelId       |-> [i \in 1 .. 20 |-> 0],
      cancelledOrderCoun |-> [i \in 1 .. 4 |-> 0],
      reserved1          |-> [i \in 1 .. 1 |-> 0] ]

(* Mass Cancel Acknowledgment Message at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelAcknowledgmentMessage ==
    { ZeroMassCancelAcknowledgmentMessage }
        \cup { [ZeroMassCancelAcknowledgmentMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelAcknowledgmentMessage EXCEPT !.massCancelId = one] : one \in Sample(20) }
        \cup { [ZeroMassCancelAcknowledgmentMessage EXCEPT !.cancelledOrderCoun = one] : one \in Sample(4) }
        \cup { [ZeroMassCancelAcknowledgmentMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Purge Rejected Message                                                  *)
(***************************************************************************)

PurgeRejectedMessage ==
    [ transactionTime               : Sample(8),
      purgeRejectReason             : Sample(1),
      text                          : Sample(60),
      reserved1                     : Sample(1),
      numberOfReturnBitfields       : 0 .. 255,
      purgeRejectedReturnBitfield1  : { << >> } \cup { <<held>> : held \in Sample(1) },
      purgeRejectedReturnBitfield2  : { << >> } \cup { <<held>> : held \in Sample(1) },
      purgeRejectedReturnBitfield3  : { << >> } \cup { <<held>> : held \in Sample(1) },
      purgeRejectedReturnBitfield4  : { << >> } \cup { <<held>> : held \in Sample(1) },
      purgeRejectedReturnBitfield5  : { << >> } \cup { <<held>> : held \in Sample(1) },
      purgeRejectedReturnBitfield6  : { << >> } \cup { <<held>> : held \in Sample(1) },
      purgeRejectedReturnBitfield7  : { << >> } \cup { <<held>> : held \in Sample(1) },
      purgeRejectedReturnBitfield8  : { << >> } \cup { <<held>> : held \in Sample(1) },
      purgeRejectedReturnBitfield9  : { << >> } \cup { <<held>> : held \in Sample(1) },
      purgeRejectedReturnBitfield10 : { << >> } \cup { <<held>> : held \in Sample(1) },
      purgeRejectedReturnBitfield11 : { << >> } \cup { <<held>> : held \in Sample(1) },
      purgeRejectedReturnBitfield12 : { << >> } \cup { <<held>> : held \in Sample(1) },
      purgeRejectedReturnBitfield13 : { << >> } \cup { <<held>> : held \in Sample(1) },
      purgeRejectedReturnBitfield14 : { << >> } \cup { <<held>> : held \in Sample(1) },
      purgeRejectedReturnBitfield15 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      purgeRejectedReturnBitfield16 : { << >> } \cup { <<held>> : held \in Sample(1) },
      purgeRejectedReturnBitfield17 : { << >> } \cup { <<held>> : held \in Sample(1) },
      purgeRejectedReturnBitfield18 : { << >> } \cup { <<held>> : held \in Sample(1) },
      purgeRejectedReturnBitfield19 : { << >> } \cup { <<held>> : held \in Sample(1) },
      purgeRejectedReturnBitfield20 : { << >> } \cup { <<held>> : held \in Sample(1) },
      massCancelId                  : { << >> } \cup { <<held>> : held \in Sample(20) } ]

EncodePurgeRejectedMessage(message) ==
    message.transactionTime
        \o message.purgeRejectReason
        \o message.text
        \o message.reserved1
        \o EncodeUIntBE(message.numberOfReturnBitfields, 1)
        \o (IF message.purgeRejectedReturnBitfield1 = << >> THEN << >> ELSE message.purgeRejectedReturnBitfield1[1])
        \o (IF message.purgeRejectedReturnBitfield2 = << >> THEN << >> ELSE message.purgeRejectedReturnBitfield2[1])
        \o (IF message.purgeRejectedReturnBitfield3 = << >> THEN << >> ELSE message.purgeRejectedReturnBitfield3[1])
        \o (IF message.purgeRejectedReturnBitfield4 = << >> THEN << >> ELSE message.purgeRejectedReturnBitfield4[1])
        \o (IF message.purgeRejectedReturnBitfield5 = << >> THEN << >> ELSE message.purgeRejectedReturnBitfield5[1])
        \o (IF message.purgeRejectedReturnBitfield6 = << >> THEN << >> ELSE message.purgeRejectedReturnBitfield6[1])
        \o (IF message.purgeRejectedReturnBitfield7 = << >> THEN << >> ELSE message.purgeRejectedReturnBitfield7[1])
        \o (IF message.purgeRejectedReturnBitfield8 = << >> THEN << >> ELSE message.purgeRejectedReturnBitfield8[1])
        \o (IF message.purgeRejectedReturnBitfield9 = << >> THEN << >> ELSE message.purgeRejectedReturnBitfield9[1])
        \o (IF message.purgeRejectedReturnBitfield10 = << >> THEN << >> ELSE message.purgeRejectedReturnBitfield10[1])
        \o (IF message.purgeRejectedReturnBitfield11 = << >> THEN << >> ELSE message.purgeRejectedReturnBitfield11[1])
        \o (IF message.purgeRejectedReturnBitfield12 = << >> THEN << >> ELSE message.purgeRejectedReturnBitfield12[1])
        \o (IF message.purgeRejectedReturnBitfield13 = << >> THEN << >> ELSE message.purgeRejectedReturnBitfield13[1])
        \o (IF message.purgeRejectedReturnBitfield14 = << >> THEN << >> ELSE message.purgeRejectedReturnBitfield14[1])
        \o (IF message.purgeRejectedReturnBitfield15 = << >> THEN << >> ELSE EncodeUIntLE(message.purgeRejectedReturnBitfield15[1], 1))
        \o (IF message.purgeRejectedReturnBitfield16 = << >> THEN << >> ELSE message.purgeRejectedReturnBitfield16[1])
        \o (IF message.purgeRejectedReturnBitfield17 = << >> THEN << >> ELSE message.purgeRejectedReturnBitfield17[1])
        \o (IF message.purgeRejectedReturnBitfield18 = << >> THEN << >> ELSE message.purgeRejectedReturnBitfield18[1])
        \o (IF message.purgeRejectedReturnBitfield19 = << >> THEN << >> ELSE message.purgeRejectedReturnBitfield19[1])
        \o (IF message.purgeRejectedReturnBitfield20 = << >> THEN << >> ELSE message.purgeRejectedReturnBitfield20[1])
        \o (IF message.massCancelId = << >> THEN << >> ELSE message.massCancelId[1])

DecodePurgeRejectedMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET purgeRejectReason == ReadBytes(transactionTime.rest, 1) IN IF ~purgeRejectReason.ok THEN Fail ELSE
    LET text == ReadBytes(purgeRejectReason.rest, 60) IN IF ~text.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(text.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET numberOfReturnBitfields == ReadUIntBE(reserved1.rest, 1) IN IF ~numberOfReturnBitfields.ok THEN Fail ELSE
    LET purgeRejectedReturnBitfield1 == ReadWhen(numberOfReturnBitfields.value >= 1, ReadBytes(numberOfReturnBitfields.rest, 1), numberOfReturnBitfields.rest) IN IF ~purgeRejectedReturnBitfield1.ok THEN Fail ELSE
    LET purgeRejectedReturnBitfield2 == ReadWhen(numberOfReturnBitfields.value >= 2, ReadBytes(purgeRejectedReturnBitfield1.rest, 1), purgeRejectedReturnBitfield1.rest) IN IF ~purgeRejectedReturnBitfield2.ok THEN Fail ELSE
    LET purgeRejectedReturnBitfield3 == ReadWhen(numberOfReturnBitfields.value >= 3, ReadBytes(purgeRejectedReturnBitfield2.rest, 1), purgeRejectedReturnBitfield2.rest) IN IF ~purgeRejectedReturnBitfield3.ok THEN Fail ELSE
    LET purgeRejectedReturnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadBytes(purgeRejectedReturnBitfield3.rest, 1), purgeRejectedReturnBitfield3.rest) IN IF ~purgeRejectedReturnBitfield4.ok THEN Fail ELSE
    LET purgeRejectedReturnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadBytes(purgeRejectedReturnBitfield4.rest, 1), purgeRejectedReturnBitfield4.rest) IN IF ~purgeRejectedReturnBitfield5.ok THEN Fail ELSE
    LET purgeRejectedReturnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadBytes(purgeRejectedReturnBitfield5.rest, 1), purgeRejectedReturnBitfield5.rest) IN IF ~purgeRejectedReturnBitfield6.ok THEN Fail ELSE
    LET purgeRejectedReturnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadBytes(purgeRejectedReturnBitfield6.rest, 1), purgeRejectedReturnBitfield6.rest) IN IF ~purgeRejectedReturnBitfield7.ok THEN Fail ELSE
    LET purgeRejectedReturnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadBytes(purgeRejectedReturnBitfield7.rest, 1), purgeRejectedReturnBitfield7.rest) IN IF ~purgeRejectedReturnBitfield8.ok THEN Fail ELSE
    LET purgeRejectedReturnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadBytes(purgeRejectedReturnBitfield8.rest, 1), purgeRejectedReturnBitfield8.rest) IN IF ~purgeRejectedReturnBitfield9.ok THEN Fail ELSE
    LET purgeRejectedReturnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadBytes(purgeRejectedReturnBitfield9.rest, 1), purgeRejectedReturnBitfield9.rest) IN IF ~purgeRejectedReturnBitfield10.ok THEN Fail ELSE
    LET purgeRejectedReturnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadBytes(purgeRejectedReturnBitfield10.rest, 1), purgeRejectedReturnBitfield10.rest) IN IF ~purgeRejectedReturnBitfield11.ok THEN Fail ELSE
    LET purgeRejectedReturnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadBytes(purgeRejectedReturnBitfield11.rest, 1), purgeRejectedReturnBitfield11.rest) IN IF ~purgeRejectedReturnBitfield12.ok THEN Fail ELSE
    LET purgeRejectedReturnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(purgeRejectedReturnBitfield12.rest, 1), purgeRejectedReturnBitfield12.rest) IN IF ~purgeRejectedReturnBitfield13.ok THEN Fail ELSE
    LET purgeRejectedReturnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(purgeRejectedReturnBitfield13.rest, 1), purgeRejectedReturnBitfield13.rest) IN IF ~purgeRejectedReturnBitfield14.ok THEN Fail ELSE
    LET purgeRejectedReturnBitfield15 == ReadWhen(numberOfReturnBitfields.value >= 15, ReadUIntLE(purgeRejectedReturnBitfield14.rest, 1), purgeRejectedReturnBitfield14.rest) IN IF ~purgeRejectedReturnBitfield15.ok THEN Fail ELSE
    LET purgeRejectedReturnBitfield16 == ReadWhen(numberOfReturnBitfields.value >= 16, ReadBytes(purgeRejectedReturnBitfield15.rest, 1), purgeRejectedReturnBitfield15.rest) IN IF ~purgeRejectedReturnBitfield16.ok THEN Fail ELSE
    LET purgeRejectedReturnBitfield17 == ReadWhen(numberOfReturnBitfields.value >= 17, ReadBytes(purgeRejectedReturnBitfield16.rest, 1), purgeRejectedReturnBitfield16.rest) IN IF ~purgeRejectedReturnBitfield17.ok THEN Fail ELSE
    LET purgeRejectedReturnBitfield18 == ReadWhen(numberOfReturnBitfields.value >= 18, ReadBytes(purgeRejectedReturnBitfield17.rest, 1), purgeRejectedReturnBitfield17.rest) IN IF ~purgeRejectedReturnBitfield18.ok THEN Fail ELSE
    LET purgeRejectedReturnBitfield19 == ReadWhen(numberOfReturnBitfields.value >= 19, ReadBytes(purgeRejectedReturnBitfield18.rest, 1), purgeRejectedReturnBitfield18.rest) IN IF ~purgeRejectedReturnBitfield19.ok THEN Fail ELSE
    LET purgeRejectedReturnBitfield20 == ReadWhen(numberOfReturnBitfields.value >= 20, ReadBytes(purgeRejectedReturnBitfield19.rest, 1), purgeRejectedReturnBitfield19.rest) IN IF ~purgeRejectedReturnBitfield20.ok THEN Fail ELSE
    LET massCancelId == ReadWhen(numberOfReturnBitfields.value >= 15 /\ (purgeRejectedReturnBitfield15.value # << >> /\ (purgeRejectedReturnBitfield15.value[1] \div 8) % 2 > 0), ReadBytes(purgeRejectedReturnBitfield20.rest, 20), purgeRejectedReturnBitfield20.rest) IN IF ~massCancelId.ok THEN Fail ELSE
    Ok([ transactionTime               |-> transactionTime.value,
         purgeRejectReason             |-> purgeRejectReason.value,
         text                          |-> text.value,
         reserved1                     |-> reserved1.value,
         numberOfReturnBitfields       |-> numberOfReturnBitfields.value,
         purgeRejectedReturnBitfield1  |-> purgeRejectedReturnBitfield1.value,
         purgeRejectedReturnBitfield2  |-> purgeRejectedReturnBitfield2.value,
         purgeRejectedReturnBitfield3  |-> purgeRejectedReturnBitfield3.value,
         purgeRejectedReturnBitfield4  |-> purgeRejectedReturnBitfield4.value,
         purgeRejectedReturnBitfield5  |-> purgeRejectedReturnBitfield5.value,
         purgeRejectedReturnBitfield6  |-> purgeRejectedReturnBitfield6.value,
         purgeRejectedReturnBitfield7  |-> purgeRejectedReturnBitfield7.value,
         purgeRejectedReturnBitfield8  |-> purgeRejectedReturnBitfield8.value,
         purgeRejectedReturnBitfield9  |-> purgeRejectedReturnBitfield9.value,
         purgeRejectedReturnBitfield10 |-> purgeRejectedReturnBitfield10.value,
         purgeRejectedReturnBitfield11 |-> purgeRejectedReturnBitfield11.value,
         purgeRejectedReturnBitfield12 |-> purgeRejectedReturnBitfield12.value,
         purgeRejectedReturnBitfield13 |-> purgeRejectedReturnBitfield13.value,
         purgeRejectedReturnBitfield14 |-> purgeRejectedReturnBitfield14.value,
         purgeRejectedReturnBitfield15 |-> purgeRejectedReturnBitfield15.value,
         purgeRejectedReturnBitfield16 |-> purgeRejectedReturnBitfield16.value,
         purgeRejectedReturnBitfield17 |-> purgeRejectedReturnBitfield17.value,
         purgeRejectedReturnBitfield18 |-> purgeRejectedReturnBitfield18.value,
         purgeRejectedReturnBitfield19 |-> purgeRejectedReturnBitfield19.value,
         purgeRejectedReturnBitfield20 |-> purgeRejectedReturnBitfield20.value,
         massCancelId                  |-> massCancelId.value ], massCancelId.rest)

(* Purge Rejected Message with each field marked present by fields before it there exactly where they say *)
SettlePurgeRejectedMessage(message) ==
    LET settled1 == [message EXCEPT !.purgeRejectedReturnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.purgeRejectedReturnBitfield1 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE message.purgeRejectedReturnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.purgeRejectedReturnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.purgeRejectedReturnBitfield2 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled1.purgeRejectedReturnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.purgeRejectedReturnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.purgeRejectedReturnBitfield3 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled2.purgeRejectedReturnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.purgeRejectedReturnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.purgeRejectedReturnBitfield4 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled3.purgeRejectedReturnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.purgeRejectedReturnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.purgeRejectedReturnBitfield5 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled4.purgeRejectedReturnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.purgeRejectedReturnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.purgeRejectedReturnBitfield6 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled5.purgeRejectedReturnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.purgeRejectedReturnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.purgeRejectedReturnBitfield7 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.purgeRejectedReturnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.purgeRejectedReturnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.purgeRejectedReturnBitfield8 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled7.purgeRejectedReturnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.purgeRejectedReturnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.purgeRejectedReturnBitfield9 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled8.purgeRejectedReturnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.purgeRejectedReturnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.purgeRejectedReturnBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.purgeRejectedReturnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.purgeRejectedReturnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.purgeRejectedReturnBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.purgeRejectedReturnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.purgeRejectedReturnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.purgeRejectedReturnBitfield12 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.purgeRejectedReturnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.purgeRejectedReturnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.purgeRejectedReturnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.purgeRejectedReturnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.purgeRejectedReturnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.purgeRejectedReturnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.purgeRejectedReturnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.purgeRejectedReturnBitfield15 = IF settled14.numberOfReturnBitfields >= 15 THEN (IF settled14.purgeRejectedReturnBitfield15 = << >> THEN <<0>> ELSE settled14.purgeRejectedReturnBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.purgeRejectedReturnBitfield16 = IF settled15.numberOfReturnBitfields >= 16 THEN (IF settled15.purgeRejectedReturnBitfield16 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled15.purgeRejectedReturnBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.purgeRejectedReturnBitfield17 = IF settled16.numberOfReturnBitfields >= 17 THEN (IF settled16.purgeRejectedReturnBitfield17 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled16.purgeRejectedReturnBitfield17) ELSE << >>]
        settled18 == [settled17 EXCEPT !.purgeRejectedReturnBitfield18 = IF settled17.numberOfReturnBitfields >= 18 THEN (IF settled17.purgeRejectedReturnBitfield18 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.purgeRejectedReturnBitfield18) ELSE << >>]
        settled19 == [settled18 EXCEPT !.purgeRejectedReturnBitfield19 = IF settled18.numberOfReturnBitfields >= 19 THEN (IF settled18.purgeRejectedReturnBitfield19 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled18.purgeRejectedReturnBitfield19) ELSE << >>]
        settled20 == [settled19 EXCEPT !.purgeRejectedReturnBitfield20 = IF settled19.numberOfReturnBitfields >= 20 THEN (IF settled19.purgeRejectedReturnBitfield20 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled19.purgeRejectedReturnBitfield20) ELSE << >>]
        settled21 == [settled20 EXCEPT !.massCancelId = IF settled20.numberOfReturnBitfields >= 15 /\ (settled20.purgeRejectedReturnBitfield15 # << >> /\ (settled20.purgeRejectedReturnBitfield15[1] \div 8) % 2 > 0) THEN (IF settled20.massCancelId = << >> THEN <<[i \in 1 .. 20 |-> 0]>> ELSE settled20.massCancelId) ELSE << >>]
    IN  settled21

ZeroPurgeRejectedMessage ==
    SettlePurgeRejectedMessage([ transactionTime               |-> [i \in 1 .. 8 |-> 0],
                                 purgeRejectReason             |-> [i \in 1 .. 1 |-> 0],
                                 text                          |-> [i \in 1 .. 60 |-> 0],
                                 reserved1                     |-> [i \in 1 .. 1 |-> 0],
                                 numberOfReturnBitfields       |-> 0,
                                 purgeRejectedReturnBitfield1  |-> << >>,
                                 purgeRejectedReturnBitfield2  |-> << >>,
                                 purgeRejectedReturnBitfield3  |-> << >>,
                                 purgeRejectedReturnBitfield4  |-> << >>,
                                 purgeRejectedReturnBitfield5  |-> << >>,
                                 purgeRejectedReturnBitfield6  |-> << >>,
                                 purgeRejectedReturnBitfield7  |-> << >>,
                                 purgeRejectedReturnBitfield8  |-> << >>,
                                 purgeRejectedReturnBitfield9  |-> << >>,
                                 purgeRejectedReturnBitfield10 |-> << >>,
                                 purgeRejectedReturnBitfield11 |-> << >>,
                                 purgeRejectedReturnBitfield12 |-> << >>,
                                 purgeRejectedReturnBitfield13 |-> << >>,
                                 purgeRejectedReturnBitfield14 |-> << >>,
                                 purgeRejectedReturnBitfield15 |-> << >>,
                                 purgeRejectedReturnBitfield16 |-> << >>,
                                 purgeRejectedReturnBitfield17 |-> << >>,
                                 purgeRejectedReturnBitfield18 |-> << >>,
                                 purgeRejectedReturnBitfield19 |-> << >>,
                                 purgeRejectedReturnBitfield20 |-> << >>,
                                 massCancelId                  |-> << >> ])

(* Purge Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedPurgeRejectedMessage ==
    { ZeroPurgeRejectedMessage }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.transactionTime = one]) : one \in Sample(8) }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.purgeRejectReason = one]) : one \in Sample(1) }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.text = one]) : one \in Sample(60) }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.reserved1 = one]) : one \in Sample(1) }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.numberOfReturnBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.purgeRejectedReturnBitfield1 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.numberOfReturnBitfields = 2, !.purgeRejectedReturnBitfield2 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.numberOfReturnBitfields = 3, !.purgeRejectedReturnBitfield3 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.numberOfReturnBitfields = 4, !.purgeRejectedReturnBitfield4 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.numberOfReturnBitfields = 5, !.purgeRejectedReturnBitfield5 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.numberOfReturnBitfields = 6, !.purgeRejectedReturnBitfield6 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.numberOfReturnBitfields = 7, !.purgeRejectedReturnBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.numberOfReturnBitfields = 8, !.purgeRejectedReturnBitfield8 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.numberOfReturnBitfields = 9, !.purgeRejectedReturnBitfield9 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.numberOfReturnBitfields = 10, !.purgeRejectedReturnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.numberOfReturnBitfields = 11, !.purgeRejectedReturnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.numberOfReturnBitfields = 12, !.purgeRejectedReturnBitfield12 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.numberOfReturnBitfields = 13, !.purgeRejectedReturnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.numberOfReturnBitfields = 14, !.purgeRejectedReturnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.numberOfReturnBitfields = 15, !.purgeRejectedReturnBitfield15 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.numberOfReturnBitfields = 16, !.purgeRejectedReturnBitfield16 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.numberOfReturnBitfields = 17, !.purgeRejectedReturnBitfield17 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.numberOfReturnBitfields = 18, !.purgeRejectedReturnBitfield18 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.numberOfReturnBitfields = 19, !.purgeRejectedReturnBitfield19 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.numberOfReturnBitfields = 20, !.purgeRejectedReturnBitfield20 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.numberOfReturnBitfields = 15, !.purgeRejectedReturnBitfield15 = <<8>>, !.massCancelId = one]) : one \in { <<held>> : held \in Sample(20) } }

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
PurgeOrderMessageCode == 71  \* 0x47
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
        \cup [ tag : {PurgeOrderMessageCode}, body : PurgeOrderMessage ]
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
      [] message.tag = PurgeOrderMessageCode -> EncodePurgeOrderMessage(message.body)
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
              [] tag = PurgeOrderMessageCode -> DecodePurgeOrderMessage(bytes)
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
        \cup { [tag |-> PurgeOrderMessageCode, body |-> one] : one \in CheckedPurgeOrderMessage }
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

(* Every Units decodes back to what was encoded, and leaves nothing over *)
RoundTripUnits ==
    \A message \in CheckedUnits :
        LET read == DecodeUnits(EncodeUnits(message))
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

(* Every Units decodes back to what was encoded, and leaves nothing over *)
RoundTripUnits2 ==
    \A message \in CheckedUnits2 :
        LET read == DecodeUnits2(EncodeUnits2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Units decodes back to what was encoded, and leaves nothing over *)
RoundTripUnits3 ==
    \A message \in CheckedUnits3 :
        LET read == DecodeUnits3(EncodeUnits3(message))
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

(* Every Units decodes back to what was encoded, and leaves nothing over *)
RoundTripUnits4 ==
    \A message \in CheckedUnits4 :
        LET read == DecodeUnits4(EncodeUnits4(message))
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

(* Every Purge Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPurgeOrderMessage ==
    \A message \in CheckedPurgeOrderMessage :
        LET read == DecodePurgeOrderMessage(EncodePurgeOrderMessage(message))
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
