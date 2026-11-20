--------------- MODULE BxeEquities_BinaryOrderEntry_v2_0_33 ----------------
(***************************************************************************)
(* Chicago Board Options Exchange  v2.0.33                                 *)
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
(* Note: Login Request V 2 Message fills what is left of the frame Message *)
(* Length states, which is what it is read from.                           *)
(*                                                                         *)
(* Note: Login Response V 2 Message fills what is left of the frame        *)
(* Message Length states, which is what it is read from.                   *)
(*                                                                         *)
(* Note: Logout Message fills what is left of the frame Message Length     *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: A field marked present by fields read before it is read only when *)
(* they say it is there, and the records checked hold it exactly where     *)
(* they do: one holding it anywhere else is no message the protocol sends. *)
(*                                                                         *)
(* Note: New Order V 2 Message fills what is left of the frame Message     *)
(* Length states, which is what it is read from.                           *)
(*                                                                         *)
(* Note: Cancel Order V 2 Message fills what is left of the frame Message  *)
(* Length states, which is what it is read from.                           *)
(*                                                                         *)
(* Note: Modify Order V 2 Message fills what is left of the frame Message  *)
(* Length states, which is what it is read from.                           *)
(*                                                                         *)
(* Note: Trade Capture Report V 2 Message fills what is left of the frame  *)
(* Message Length states, which is what it is read from.                   *)
(*                                                                         *)
(* Note: Order Acknowledgment V 2 Message fills what is left of the frame  *)
(* Message Length states, which is what it is read from.                   *)
(*                                                                         *)
(* Note: Order Rejected V 2 Message fills what is left of the frame        *)
(* Message Length states, which is what it is read from.                   *)
(*                                                                         *)
(* Note: Order Modified V 2 Message fills what is left of the frame        *)
(* Message Length states, which is what it is read from.                   *)
(*                                                                         *)
(* Note: Order Restated V 2 Message fills what is left of the frame        *)
(* Message Length states, which is what it is read from.                   *)
(*                                                                         *)
(* Note: User Modify Rejected V 2 Message fills what is left of the frame  *)
(* Message Length states, which is what it is read from.                   *)
(*                                                                         *)
(* Note: Order Cancelled V 2 Message fills what is left of the frame       *)
(* Message Length states, which is what it is read from.                   *)
(*                                                                         *)
(* Note: Cancel Rejected V 2 Message fills what is left of the frame       *)
(* Message Length states, which is what it is read from.                   *)
(*                                                                         *)
(* Note: Order Execution V 2 Message fills what is left of the frame       *)
(* Message Length states, which is what it is read from.                   *)
(*                                                                         *)
(* Note: Trade Cancel Or Correct V 2 Message fills what is left of the     *)
(* frame Message Length states, which is what it is read from.             *)
(*                                                                         *)
(* Note: Trade Capture Report Acknowledgment V 2 Message fills what is     *)
(* left of the frame Message Length states, which is what it is read from. *)
(*                                                                         *)
(* Note: Trade Capture Report Reject V 2 Message fills what is left of the *)
(* frame Message Length states, which is what it is read from.             *)
(*                                                                         *)
(* Note: Trade Capture Confirm V 2 Message fills what is left of the frame *)
(* Message Length states, which is what it is read from.                   *)
(*                                                                         *)
(* Note: Trade Capture Report Decline V 2 Message fills what is left of    *)
(* the frame Message Length states, which is what it is read from.         *)
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
(* Return Bitfields: 1 bytes                                               *)
(***************************************************************************)

ReturnBitfields ==
    [ returnBitfield : Sample(1) ]

EncodeReturnBitfields(message) ==
    message.returnBitfield

DecodeReturnBitfields(bytes) ==
    LET returnBitfield == ReadBytes(bytes, 1) IN IF ~returnBitfield.ok THEN Fail ELSE
    Ok([ returnBitfield |-> returnBitfield.value ], returnBitfield.rest)

ZeroReturnBitfields ==
    [ returnBitfield |-> [i \in 1 .. 1 |-> 0] ]

(* Return Bitfields at zero, then each field in turn at the values it is checked at *)
CheckedReturnBitfields ==
    { ZeroReturnBitfields }
        \cup { [ZeroReturnBitfields EXCEPT !.returnBitfield = one] : one \in Sample(1) }

(* A run of Return Bitfields, written one after another *)
RECURSIVE EncodeReturnBitfieldsList(_)
EncodeReturnBitfieldsList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeReturnBitfields(Head(messages)) \o EncodeReturnBitfieldsList(Tail(messages))

(* As many Return Bitfields as the field that counts them says *)
RECURSIVE ReadReturnBitfieldsList(_, _)
ReadReturnBitfieldsList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeReturnBitfields(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadReturnBitfieldsList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Return Bitfields of each kind, for the lists that carry them *)
OneReturnBitfields == { ZeroReturnBitfields }

(***************************************************************************)
(* Return Bitfields Param Group                                            *)
(***************************************************************************)

ReturnBitfieldsParamGroup ==
    [ messageType     : Sample(1),
      returnBitfields : SampleLists(OneReturnBitfields) ]

EncodeReturnBitfieldsParamGroup(message) ==
    message.messageType
        \o EncodeUIntBE(Len(message.returnBitfields), 1)
        \o EncodeReturnBitfieldsList(message.returnBitfields)

DecodeReturnBitfieldsParamGroup(bytes) ==
    LET messageType == ReadBytes(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET numberOfReturnBitfields == ReadUIntBE(messageType.rest, 1) IN IF ~numberOfReturnBitfields.ok THEN Fail ELSE
    LET returnBitfields == ReadReturnBitfieldsList(numberOfReturnBitfields.rest, numberOfReturnBitfields.value) IN IF ~returnBitfields.ok THEN Fail ELSE
    Ok([ messageType     |-> messageType.value,
         returnBitfields |-> returnBitfields.value ], returnBitfields.rest)

ZeroReturnBitfieldsParamGroup ==
    [ messageType     |-> [i \in 1 .. 1 |-> 0],
      returnBitfields |-> << >> ]

(* Return Bitfields Param Group at zero, then each field in turn at the values it is checked at *)
CheckedReturnBitfieldsParamGroup ==
    { ZeroReturnBitfieldsParamGroup }
        \cup { [ZeroReturnBitfieldsParamGroup EXCEPT !.messageType = one] : one \in Sample(1) }
        \cup { [ZeroReturnBitfieldsParamGroup EXCEPT !.returnBitfields = one] : one \in SampleLists(OneReturnBitfields) }

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
(* Login Request V 2 Message                                               *)
(***************************************************************************)

LoginRequestV2Message ==
    [ sessionSubId : Sample(4),
      username     : Sample(4),
      password     : Sample(10),
      paramGroup   : SampleLists(OneParamGroup) ]

EncodeLoginRequestV2Message(message) ==
    message.sessionSubId
        \o message.username
        \o message.password
        \o EncodeUIntBE(Len(message.paramGroup), 1)
        \o EncodeParamGroupList(message.paramGroup)

DecodeLoginRequestV2Message(bytes) ==
    LET sessionSubId == ReadBytes(bytes, 4) IN IF ~sessionSubId.ok THEN Fail ELSE
    LET username == ReadBytes(sessionSubId.rest, 4) IN IF ~username.ok THEN Fail ELSE
    LET password == ReadBytes(username.rest, 10) IN IF ~password.ok THEN Fail ELSE
    LET numberOfParamGroups == ReadUIntBE(password.rest, 1) IN IF ~numberOfParamGroups.ok THEN Fail ELSE
    LET paramGroup == ReadParamGroupList(numberOfParamGroups.rest, numberOfParamGroups.value) IN IF ~paramGroup.ok THEN Fail ELSE
    Ok([ sessionSubId |-> sessionSubId.value,
         username     |-> username.value,
         password     |-> password.value,
         paramGroup   |-> paramGroup.value ], paramGroup.rest)

ZeroLoginRequestV2Message ==
    [ sessionSubId |-> [i \in 1 .. 4 |-> 0],
      username     |-> [i \in 1 .. 4 |-> 0],
      password     |-> [i \in 1 .. 10 |-> 0],
      paramGroup   |-> << >> ]

(* Login Request V 2 Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginRequestV2Message ==
    { ZeroLoginRequestV2Message }
        \cup { [ZeroLoginRequestV2Message EXCEPT !.sessionSubId = one] : one \in Sample(4) }
        \cup { [ZeroLoginRequestV2Message EXCEPT !.username = one] : one \in Sample(4) }
        \cup { [ZeroLoginRequestV2Message EXCEPT !.password = one] : one \in Sample(10) }
        \cup { [ZeroLoginRequestV2Message EXCEPT !.paramGroup = one] : one \in SampleLists(OneParamGroup) }

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
(* Return Bitfields: 1 bytes                                               *)
(***************************************************************************)

ReturnBitfields2 ==
    [ returnBitfield : Sample(1) ]

EncodeReturnBitfields2(message) ==
    message.returnBitfield

DecodeReturnBitfields2(bytes) ==
    LET returnBitfield == ReadBytes(bytes, 1) IN IF ~returnBitfield.ok THEN Fail ELSE
    Ok([ returnBitfield |-> returnBitfield.value ], returnBitfield.rest)

ZeroReturnBitfields2 ==
    [ returnBitfield |-> [i \in 1 .. 1 |-> 0] ]

(* Return Bitfields at zero, then each field in turn at the values it is checked at *)
CheckedReturnBitfields2 ==
    { ZeroReturnBitfields2 }
        \cup { [ZeroReturnBitfields2 EXCEPT !.returnBitfield = one] : one \in Sample(1) }

(* A run of Return Bitfields, written one after another *)
RECURSIVE EncodeReturnBitfields2List(_)
EncodeReturnBitfields2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeReturnBitfields2(Head(messages)) \o EncodeReturnBitfields2List(Tail(messages))

(* As many Return Bitfields as the field that counts them says *)
RECURSIVE ReadReturnBitfields2List(_, _)
ReadReturnBitfields2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeReturnBitfields2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadReturnBitfields2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Return Bitfields of each kind, for the lists that carry them *)
OneReturnBitfields2 == { ZeroReturnBitfields2 }

(***************************************************************************)
(* Return Bitfields Param Group                                            *)
(***************************************************************************)

ReturnBitfieldsParamGroup2 ==
    [ messageType     : Sample(1),
      returnBitfields : SampleLists(OneReturnBitfields2) ]

EncodeReturnBitfieldsParamGroup2(message) ==
    message.messageType
        \o EncodeUIntBE(Len(message.returnBitfields), 1)
        \o EncodeReturnBitfields2List(message.returnBitfields)

DecodeReturnBitfieldsParamGroup2(bytes) ==
    LET messageType == ReadBytes(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET numberOfReturnBitfields == ReadUIntBE(messageType.rest, 1) IN IF ~numberOfReturnBitfields.ok THEN Fail ELSE
    LET returnBitfields == ReadReturnBitfields2List(numberOfReturnBitfields.rest, numberOfReturnBitfields.value) IN IF ~returnBitfields.ok THEN Fail ELSE
    Ok([ messageType     |-> messageType.value,
         returnBitfields |-> returnBitfields.value ], returnBitfields.rest)

ZeroReturnBitfieldsParamGroup2 ==
    [ messageType     |-> [i \in 1 .. 1 |-> 0],
      returnBitfields |-> << >> ]

(* Return Bitfields Param Group at zero, then each field in turn at the values it is checked at *)
CheckedReturnBitfieldsParamGroup2 ==
    { ZeroReturnBitfieldsParamGroup2 }
        \cup { [ZeroReturnBitfieldsParamGroup2 EXCEPT !.messageType = one] : one \in Sample(1) }
        \cup { [ZeroReturnBitfieldsParamGroup2 EXCEPT !.returnBitfields = one] : one \in SampleLists(OneReturnBitfields2) }

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
(* Login Response V 2 Message                                              *)
(***************************************************************************)

LoginResponseV2Message ==
    [ loginResponseStatus        : Sample(1),
      loginResponseText          : Sample(60),
      noUnspecifiedUnitReplay    : Sample(1),
      lastReceivedSequenceNumber : Sample(4),
      units                      : SampleLists(OneUnits2),
      paramGroup                 : SampleLists(OneParamGroup2) ]

EncodeLoginResponseV2Message(message) ==
    message.loginResponseStatus
        \o message.loginResponseText
        \o message.noUnspecifiedUnitReplay
        \o message.lastReceivedSequenceNumber
        \o EncodeUIntBE(Len(message.units), 1)
        \o EncodeUnits2List(message.units)
        \o EncodeUIntBE(Len(message.paramGroup), 1)
        \o EncodeParamGroup2List(message.paramGroup)

DecodeLoginResponseV2Message(bytes) ==
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

ZeroLoginResponseV2Message ==
    [ loginResponseStatus        |-> [i \in 1 .. 1 |-> 0],
      loginResponseText          |-> [i \in 1 .. 60 |-> 0],
      noUnspecifiedUnitReplay    |-> [i \in 1 .. 1 |-> 0],
      lastReceivedSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      units                      |-> << >>,
      paramGroup                 |-> << >> ]

(* Login Response V 2 Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginResponseV2Message ==
    { ZeroLoginResponseV2Message }
        \cup { [ZeroLoginResponseV2Message EXCEPT !.loginResponseStatus = one] : one \in Sample(1) }
        \cup { [ZeroLoginResponseV2Message EXCEPT !.loginResponseText = one] : one \in Sample(60) }
        \cup { [ZeroLoginResponseV2Message EXCEPT !.noUnspecifiedUnitReplay = one] : one \in Sample(1) }
        \cup { [ZeroLoginResponseV2Message EXCEPT !.lastReceivedSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroLoginResponseV2Message EXCEPT !.units = one] : one \in SampleLists(OneUnits2) }
        \cup { [ZeroLoginResponseV2Message EXCEPT !.paramGroup = one] : one \in SampleLists(OneParamGroup2) }

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
(* New Order V 2 Message                                                   *)
(***************************************************************************)

NewOrderV2Message ==
    [ clOrdId                     : Sample(20),
      side                        : Sample(1),
      orderQty                    : Sample(4),
      numberOfNewOrderV2Bitfields : 0 .. 255,
      newOrderV2Bitfield1         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      newOrderV2Bitfield2         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      newOrderV2Bitfield3         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      newOrderV2Bitfield4         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      newOrderV2Bitfield5         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      newOrderV2Bitfield6         : { << >> } \cup { <<held>> : held \in Sample(1) },
      newOrderV2Bitfield7         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      clearingFirm                : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingAccount             : { << >> } \cup { <<held>> : held \in Sample(4) },
      price                       : { << >> } \cup { <<held>> : held \in Sample(8) },
      execInst                    : { << >> } \cup { <<held>> : held \in Sample(1) },
      ordType                     : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                      : { << >> } \cup { <<held>> : held \in Sample(4) },
      maxFloor                    : { << >> } \cup { <<held>> : held \in Sample(4) },
      symbol                      : { << >> } \cup { <<held>> : held \in Sample(8) },
      currency                    : { << >> } \cup { <<held>> : held \in Sample(3) },
      idSource                    : { << >> } \cup { <<held>> : held \in Sample(1) },
      securityId                  : { << >> } \cup { <<held>> : held \in Sample(16) },
      securityExchange            : { << >> } \cup { <<held>> : held \in Sample(4) },
      capacity                    : { << >> } \cup { <<held>> : held \in Sample(1) },
      routingInst                 : { << >> } \cup { <<held>> : held \in Sample(4) },
      account                     : { << >> } \cup { <<held>> : held \in Sample(16) },
      displayIndicator            : { << >> } \cup { <<held>> : held \in Sample(1) },
      pegDifference               : { << >> } \cup { <<held>> : held \in Sample(8) },
      preventParticipantMatch     : { << >> } \cup { <<held>> : held \in Sample(3) },
      expireTime                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      liquidityProvision          : { << >> } \cup { <<held>> : held \in Sample(1) },
      clientId                    : { << >> } \cup { <<held>> : held \in Sample(4) },
      investorId                  : { << >> } \cup { <<held>> : held \in Sample(4) },
      executorId                  : { << >> } \cup { <<held>> : held \in Sample(4) },
      orderOrigination            : { << >> } \cup { <<held>> : held \in Sample(1) },
      algorithmicIndicator        : { << >> } \cup { <<held>> : held \in Sample(1) },
      clientQualifiedRole         : { << >> } \cup { <<held>> : held \in Sample(1) },
      investorQualifiedRole       : { << >> } \cup { <<held>> : held \in Sample(1) },
      executorQualifiedRole       : { << >> } \cup { <<held>> : held \in Sample(1) } ]

EncodeNewOrderV2Message(message) ==
    message.clOrdId
        \o message.side
        \o message.orderQty
        \o EncodeUIntBE(message.numberOfNewOrderV2Bitfields, 1)
        \o (IF message.newOrderV2Bitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.newOrderV2Bitfield1[1], 1))
        \o (IF message.newOrderV2Bitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.newOrderV2Bitfield2[1], 1))
        \o (IF message.newOrderV2Bitfield3 = << >> THEN << >> ELSE EncodeUIntLE(message.newOrderV2Bitfield3[1], 1))
        \o (IF message.newOrderV2Bitfield4 = << >> THEN << >> ELSE EncodeUIntLE(message.newOrderV2Bitfield4[1], 1))
        \o (IF message.newOrderV2Bitfield5 = << >> THEN << >> ELSE EncodeUIntLE(message.newOrderV2Bitfield5[1], 1))
        \o (IF message.newOrderV2Bitfield6 = << >> THEN << >> ELSE message.newOrderV2Bitfield6[1])
        \o (IF message.newOrderV2Bitfield7 = << >> THEN << >> ELSE EncodeUIntLE(message.newOrderV2Bitfield7[1], 1))
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])
        \o (IF message.clearingAccount = << >> THEN << >> ELSE message.clearingAccount[1])
        \o (IF message.price = << >> THEN << >> ELSE message.price[1])
        \o (IF message.execInst = << >> THEN << >> ELSE message.execInst[1])
        \o (IF message.ordType = << >> THEN << >> ELSE message.ordType[1])
        \o (IF message.timeInForce = << >> THEN << >> ELSE message.timeInForce[1])
        \o (IF message.minQty = << >> THEN << >> ELSE message.minQty[1])
        \o (IF message.maxFloor = << >> THEN << >> ELSE message.maxFloor[1])
        \o (IF message.symbol = << >> THEN << >> ELSE message.symbol[1])
        \o (IF message.currency = << >> THEN << >> ELSE message.currency[1])
        \o (IF message.idSource = << >> THEN << >> ELSE message.idSource[1])
        \o (IF message.securityId = << >> THEN << >> ELSE message.securityId[1])
        \o (IF message.securityExchange = << >> THEN << >> ELSE message.securityExchange[1])
        \o (IF message.capacity = << >> THEN << >> ELSE message.capacity[1])
        \o (IF message.routingInst = << >> THEN << >> ELSE message.routingInst[1])
        \o (IF message.account = << >> THEN << >> ELSE message.account[1])
        \o (IF message.displayIndicator = << >> THEN << >> ELSE message.displayIndicator[1])
        \o (IF message.pegDifference = << >> THEN << >> ELSE message.pegDifference[1])
        \o (IF message.preventParticipantMatch = << >> THEN << >> ELSE message.preventParticipantMatch[1])
        \o (IF message.expireTime = << >> THEN << >> ELSE message.expireTime[1])
        \o (IF message.liquidityProvision = << >> THEN << >> ELSE message.liquidityProvision[1])
        \o (IF message.clientId = << >> THEN << >> ELSE message.clientId[1])
        \o (IF message.investorId = << >> THEN << >> ELSE message.investorId[1])
        \o (IF message.executorId = << >> THEN << >> ELSE message.executorId[1])
        \o (IF message.orderOrigination = << >> THEN << >> ELSE message.orderOrigination[1])
        \o (IF message.algorithmicIndicator = << >> THEN << >> ELSE message.algorithmicIndicator[1])
        \o (IF message.clientQualifiedRole = << >> THEN << >> ELSE message.clientQualifiedRole[1])
        \o (IF message.investorQualifiedRole = << >> THEN << >> ELSE message.investorQualifiedRole[1])
        \o (IF message.executorQualifiedRole = << >> THEN << >> ELSE message.executorQualifiedRole[1])

DecodeNewOrderV2Message(bytes) ==
    LET clOrdId == ReadBytes(bytes, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET side == ReadBytes(clOrdId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderQty == ReadBytes(side.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET numberOfNewOrderV2Bitfields == ReadUIntBE(orderQty.rest, 1) IN IF ~numberOfNewOrderV2Bitfields.ok THEN Fail ELSE
    LET newOrderV2Bitfield1 == ReadWhen(numberOfNewOrderV2Bitfields.value >= 1, ReadUIntLE(numberOfNewOrderV2Bitfields.rest, 1), numberOfNewOrderV2Bitfields.rest) IN IF ~newOrderV2Bitfield1.ok THEN Fail ELSE
    LET newOrderV2Bitfield2 == ReadWhen(numberOfNewOrderV2Bitfields.value >= 2, ReadUIntLE(newOrderV2Bitfield1.rest, 1), newOrderV2Bitfield1.rest) IN IF ~newOrderV2Bitfield2.ok THEN Fail ELSE
    LET newOrderV2Bitfield3 == ReadWhen(numberOfNewOrderV2Bitfields.value >= 3, ReadUIntLE(newOrderV2Bitfield2.rest, 1), newOrderV2Bitfield2.rest) IN IF ~newOrderV2Bitfield3.ok THEN Fail ELSE
    LET newOrderV2Bitfield4 == ReadWhen(numberOfNewOrderV2Bitfields.value >= 4, ReadUIntLE(newOrderV2Bitfield3.rest, 1), newOrderV2Bitfield3.rest) IN IF ~newOrderV2Bitfield4.ok THEN Fail ELSE
    LET newOrderV2Bitfield5 == ReadWhen(numberOfNewOrderV2Bitfields.value >= 5, ReadUIntLE(newOrderV2Bitfield4.rest, 1), newOrderV2Bitfield4.rest) IN IF ~newOrderV2Bitfield5.ok THEN Fail ELSE
    LET newOrderV2Bitfield6 == ReadWhen(numberOfNewOrderV2Bitfields.value >= 6, ReadBytes(newOrderV2Bitfield5.rest, 1), newOrderV2Bitfield5.rest) IN IF ~newOrderV2Bitfield6.ok THEN Fail ELSE
    LET newOrderV2Bitfield7 == ReadWhen(numberOfNewOrderV2Bitfields.value >= 7, ReadUIntLE(newOrderV2Bitfield6.rest, 1), newOrderV2Bitfield6.rest) IN IF ~newOrderV2Bitfield7.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfNewOrderV2Bitfields.value >= 1 /\ (newOrderV2Bitfield1.value # << >> /\ newOrderV2Bitfield1.value[1] % 2 > 0), ReadBytes(newOrderV2Bitfield7.rest, 4), newOrderV2Bitfield7.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadWhen(numberOfNewOrderV2Bitfields.value >= 1 /\ (newOrderV2Bitfield1.value # << >> /\ (newOrderV2Bitfield1.value[1] \div 2) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET price == ReadWhen(numberOfNewOrderV2Bitfields.value >= 1 /\ (newOrderV2Bitfield1.value # << >> /\ (newOrderV2Bitfield1.value[1] \div 4) % 2 > 0), ReadBytes(clearingAccount.rest, 8), clearingAccount.rest) IN IF ~price.ok THEN Fail ELSE
    LET execInst == ReadWhen(numberOfNewOrderV2Bitfields.value >= 1 /\ (newOrderV2Bitfield1.value # << >> /\ (newOrderV2Bitfield1.value[1] \div 8) % 2 > 0), ReadBytes(price.rest, 1), price.rest) IN IF ~execInst.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfNewOrderV2Bitfields.value >= 1 /\ (newOrderV2Bitfield1.value # << >> /\ (newOrderV2Bitfield1.value[1] \div 16) % 2 > 0), ReadBytes(execInst.rest, 1), execInst.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfNewOrderV2Bitfields.value >= 1 /\ (newOrderV2Bitfield1.value # << >> /\ (newOrderV2Bitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfNewOrderV2Bitfields.value >= 1 /\ (newOrderV2Bitfield1.value # << >> /\ (newOrderV2Bitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET maxFloor == ReadWhen(numberOfNewOrderV2Bitfields.value >= 1 /\ (newOrderV2Bitfield1.value # << >> /\ (newOrderV2Bitfield1.value[1] \div 128) % 2 > 0), ReadBytes(minQty.rest, 4), minQty.rest) IN IF ~maxFloor.ok THEN Fail ELSE
    LET symbol == ReadWhen(numberOfNewOrderV2Bitfields.value >= 2 /\ (newOrderV2Bitfield2.value # << >> /\ newOrderV2Bitfield2.value[1] % 2 > 0), ReadBytes(maxFloor.rest, 8), maxFloor.rest) IN IF ~symbol.ok THEN Fail ELSE
    LET currency == ReadWhen(numberOfNewOrderV2Bitfields.value >= 2 /\ (newOrderV2Bitfield2.value # << >> /\ (newOrderV2Bitfield2.value[1] \div 4) % 2 > 0), ReadBytes(symbol.rest, 3), symbol.rest) IN IF ~currency.ok THEN Fail ELSE
    LET idSource == ReadWhen(numberOfNewOrderV2Bitfields.value >= 2 /\ (newOrderV2Bitfield2.value # << >> /\ (newOrderV2Bitfield2.value[1] \div 8) % 2 > 0), ReadBytes(currency.rest, 1), currency.rest) IN IF ~idSource.ok THEN Fail ELSE
    LET securityId == ReadWhen(numberOfNewOrderV2Bitfields.value >= 2 /\ (newOrderV2Bitfield2.value # << >> /\ (newOrderV2Bitfield2.value[1] \div 16) % 2 > 0), ReadBytes(idSource.rest, 16), idSource.rest) IN IF ~securityId.ok THEN Fail ELSE
    LET securityExchange == ReadWhen(numberOfNewOrderV2Bitfields.value >= 2 /\ (newOrderV2Bitfield2.value # << >> /\ (newOrderV2Bitfield2.value[1] \div 32) % 2 > 0), ReadBytes(securityId.rest, 4), securityId.rest) IN IF ~securityExchange.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfNewOrderV2Bitfields.value >= 2 /\ (newOrderV2Bitfield2.value # << >> /\ (newOrderV2Bitfield2.value[1] \div 64) % 2 > 0), ReadBytes(securityExchange.rest, 1), securityExchange.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET routingInst == ReadWhen(numberOfNewOrderV2Bitfields.value >= 2 /\ (newOrderV2Bitfield2.value # << >> /\ (newOrderV2Bitfield2.value[1] \div 128) % 2 > 0), ReadBytes(capacity.rest, 4), capacity.rest) IN IF ~routingInst.ok THEN Fail ELSE
    LET account == ReadWhen(numberOfNewOrderV2Bitfields.value >= 3 /\ (newOrderV2Bitfield3.value # << >> /\ newOrderV2Bitfield3.value[1] % 2 > 0), ReadBytes(routingInst.rest, 16), routingInst.rest) IN IF ~account.ok THEN Fail ELSE
    LET displayIndicator == ReadWhen(numberOfNewOrderV2Bitfields.value >= 3 /\ (newOrderV2Bitfield3.value # << >> /\ (newOrderV2Bitfield3.value[1] \div 2) % 2 > 0), ReadBytes(account.rest, 1), account.rest) IN IF ~displayIndicator.ok THEN Fail ELSE
    LET pegDifference == ReadWhen(numberOfNewOrderV2Bitfields.value >= 3 /\ (newOrderV2Bitfield3.value # << >> /\ (newOrderV2Bitfield3.value[1] \div 16) % 2 > 0), ReadBytes(displayIndicator.rest, 8), displayIndicator.rest) IN IF ~pegDifference.ok THEN Fail ELSE
    LET preventParticipantMatch == ReadWhen(numberOfNewOrderV2Bitfields.value >= 3 /\ (newOrderV2Bitfield3.value # << >> /\ (newOrderV2Bitfield3.value[1] \div 32) % 2 > 0), ReadBytes(pegDifference.rest, 3), pegDifference.rest) IN IF ~preventParticipantMatch.ok THEN Fail ELSE
    LET expireTime == ReadWhen(numberOfNewOrderV2Bitfields.value >= 3 /\ (newOrderV2Bitfield3.value # << >> /\ (newOrderV2Bitfield3.value[1] \div 128) % 2 > 0), ReadBytes(preventParticipantMatch.rest, 8), preventParticipantMatch.rest) IN IF ~expireTime.ok THEN Fail ELSE
    LET liquidityProvision == ReadWhen(numberOfNewOrderV2Bitfields.value >= 4 /\ (newOrderV2Bitfield4.value # << >> /\ (newOrderV2Bitfield4.value[1] \div 128) % 2 > 0), ReadBytes(expireTime.rest, 1), expireTime.rest) IN IF ~liquidityProvision.ok THEN Fail ELSE
    LET clientId == ReadWhen(numberOfNewOrderV2Bitfields.value >= 5 /\ (newOrderV2Bitfield5.value # << >> /\ (newOrderV2Bitfield5.value[1] \div 16) % 2 > 0), ReadBytes(liquidityProvision.rest, 4), liquidityProvision.rest) IN IF ~clientId.ok THEN Fail ELSE
    LET investorId == ReadWhen(numberOfNewOrderV2Bitfields.value >= 5 /\ (newOrderV2Bitfield5.value # << >> /\ (newOrderV2Bitfield5.value[1] \div 32) % 2 > 0), ReadBytes(clientId.rest, 4), clientId.rest) IN IF ~investorId.ok THEN Fail ELSE
    LET executorId == ReadWhen(numberOfNewOrderV2Bitfields.value >= 5 /\ (newOrderV2Bitfield5.value # << >> /\ (newOrderV2Bitfield5.value[1] \div 64) % 2 > 0), ReadBytes(investorId.rest, 4), investorId.rest) IN IF ~executorId.ok THEN Fail ELSE
    LET orderOrigination == ReadWhen(numberOfNewOrderV2Bitfields.value >= 5 /\ (newOrderV2Bitfield5.value # << >> /\ (newOrderV2Bitfield5.value[1] \div 128) % 2 > 0), ReadBytes(executorId.rest, 1), executorId.rest) IN IF ~orderOrigination.ok THEN Fail ELSE
    LET algorithmicIndicator == ReadWhen(numberOfNewOrderV2Bitfields.value >= 7 /\ (newOrderV2Bitfield7.value # << >> /\ newOrderV2Bitfield7.value[1] % 2 > 0), ReadBytes(orderOrigination.rest, 1), orderOrigination.rest) IN IF ~algorithmicIndicator.ok THEN Fail ELSE
    LET clientQualifiedRole == ReadWhen(numberOfNewOrderV2Bitfields.value >= 7 /\ (newOrderV2Bitfield7.value # << >> /\ (newOrderV2Bitfield7.value[1] \div 4) % 2 > 0), ReadBytes(algorithmicIndicator.rest, 1), algorithmicIndicator.rest) IN IF ~clientQualifiedRole.ok THEN Fail ELSE
    LET investorQualifiedRole == ReadWhen(numberOfNewOrderV2Bitfields.value >= 7 /\ (newOrderV2Bitfield7.value # << >> /\ (newOrderV2Bitfield7.value[1] \div 8) % 2 > 0), ReadBytes(clientQualifiedRole.rest, 1), clientQualifiedRole.rest) IN IF ~investorQualifiedRole.ok THEN Fail ELSE
    LET executorQualifiedRole == ReadWhen(numberOfNewOrderV2Bitfields.value >= 7 /\ (newOrderV2Bitfield7.value # << >> /\ (newOrderV2Bitfield7.value[1] \div 16) % 2 > 0), ReadBytes(investorQualifiedRole.rest, 1), investorQualifiedRole.rest) IN IF ~executorQualifiedRole.ok THEN Fail ELSE
    Ok([ clOrdId                     |-> clOrdId.value,
         side                        |-> side.value,
         orderQty                    |-> orderQty.value,
         numberOfNewOrderV2Bitfields |-> numberOfNewOrderV2Bitfields.value,
         newOrderV2Bitfield1         |-> newOrderV2Bitfield1.value,
         newOrderV2Bitfield2         |-> newOrderV2Bitfield2.value,
         newOrderV2Bitfield3         |-> newOrderV2Bitfield3.value,
         newOrderV2Bitfield4         |-> newOrderV2Bitfield4.value,
         newOrderV2Bitfield5         |-> newOrderV2Bitfield5.value,
         newOrderV2Bitfield6         |-> newOrderV2Bitfield6.value,
         newOrderV2Bitfield7         |-> newOrderV2Bitfield7.value,
         clearingFirm                |-> clearingFirm.value,
         clearingAccount             |-> clearingAccount.value,
         price                       |-> price.value,
         execInst                    |-> execInst.value,
         ordType                     |-> ordType.value,
         timeInForce                 |-> timeInForce.value,
         minQty                      |-> minQty.value,
         maxFloor                    |-> maxFloor.value,
         symbol                      |-> symbol.value,
         currency                    |-> currency.value,
         idSource                    |-> idSource.value,
         securityId                  |-> securityId.value,
         securityExchange            |-> securityExchange.value,
         capacity                    |-> capacity.value,
         routingInst                 |-> routingInst.value,
         account                     |-> account.value,
         displayIndicator            |-> displayIndicator.value,
         pegDifference               |-> pegDifference.value,
         preventParticipantMatch     |-> preventParticipantMatch.value,
         expireTime                  |-> expireTime.value,
         liquidityProvision          |-> liquidityProvision.value,
         clientId                    |-> clientId.value,
         investorId                  |-> investorId.value,
         executorId                  |-> executorId.value,
         orderOrigination            |-> orderOrigination.value,
         algorithmicIndicator        |-> algorithmicIndicator.value,
         clientQualifiedRole         |-> clientQualifiedRole.value,
         investorQualifiedRole       |-> investorQualifiedRole.value,
         executorQualifiedRole       |-> executorQualifiedRole.value ], executorQualifiedRole.rest)

(* New Order V 2 Message with each field marked present by fields before it there exactly where they say *)
SettleNewOrderV2Message(message) ==
    LET settled1 == [message EXCEPT !.newOrderV2Bitfield1 = IF message.numberOfNewOrderV2Bitfields >= 1 THEN (IF message.newOrderV2Bitfield1 = << >> THEN <<0>> ELSE message.newOrderV2Bitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.newOrderV2Bitfield2 = IF settled1.numberOfNewOrderV2Bitfields >= 2 THEN (IF settled1.newOrderV2Bitfield2 = << >> THEN <<0>> ELSE settled1.newOrderV2Bitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.newOrderV2Bitfield3 = IF settled2.numberOfNewOrderV2Bitfields >= 3 THEN (IF settled2.newOrderV2Bitfield3 = << >> THEN <<0>> ELSE settled2.newOrderV2Bitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.newOrderV2Bitfield4 = IF settled3.numberOfNewOrderV2Bitfields >= 4 THEN (IF settled3.newOrderV2Bitfield4 = << >> THEN <<0>> ELSE settled3.newOrderV2Bitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.newOrderV2Bitfield5 = IF settled4.numberOfNewOrderV2Bitfields >= 5 THEN (IF settled4.newOrderV2Bitfield5 = << >> THEN <<0>> ELSE settled4.newOrderV2Bitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.newOrderV2Bitfield6 = IF settled5.numberOfNewOrderV2Bitfields >= 6 THEN (IF settled5.newOrderV2Bitfield6 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled5.newOrderV2Bitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.newOrderV2Bitfield7 = IF settled6.numberOfNewOrderV2Bitfields >= 7 THEN (IF settled6.newOrderV2Bitfield7 = << >> THEN <<0>> ELSE settled6.newOrderV2Bitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.clearingFirm = IF settled7.numberOfNewOrderV2Bitfields >= 1 /\ (settled7.newOrderV2Bitfield1 # << >> /\ settled7.newOrderV2Bitfield1[1] % 2 > 0) THEN (IF settled7.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled7.clearingFirm) ELSE << >>]
        settled9 == [settled8 EXCEPT !.clearingAccount = IF settled8.numberOfNewOrderV2Bitfields >= 1 /\ (settled8.newOrderV2Bitfield1 # << >> /\ (settled8.newOrderV2Bitfield1[1] \div 2) % 2 > 0) THEN (IF settled8.clearingAccount = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled8.clearingAccount) ELSE << >>]
        settled10 == [settled9 EXCEPT !.price = IF settled9.numberOfNewOrderV2Bitfields >= 1 /\ (settled9.newOrderV2Bitfield1 # << >> /\ (settled9.newOrderV2Bitfield1[1] \div 4) % 2 > 0) THEN (IF settled9.price = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled9.price) ELSE << >>]
        settled11 == [settled10 EXCEPT !.execInst = IF settled10.numberOfNewOrderV2Bitfields >= 1 /\ (settled10.newOrderV2Bitfield1 # << >> /\ (settled10.newOrderV2Bitfield1[1] \div 8) % 2 > 0) THEN (IF settled10.execInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.execInst) ELSE << >>]
        settled12 == [settled11 EXCEPT !.ordType = IF settled11.numberOfNewOrderV2Bitfields >= 1 /\ (settled11.newOrderV2Bitfield1 # << >> /\ (settled11.newOrderV2Bitfield1[1] \div 16) % 2 > 0) THEN (IF settled11.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.ordType) ELSE << >>]
        settled13 == [settled12 EXCEPT !.timeInForce = IF settled12.numberOfNewOrderV2Bitfields >= 1 /\ (settled12.newOrderV2Bitfield1 # << >> /\ (settled12.newOrderV2Bitfield1[1] \div 32) % 2 > 0) THEN (IF settled12.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.timeInForce) ELSE << >>]
        settled14 == [settled13 EXCEPT !.minQty = IF settled13.numberOfNewOrderV2Bitfields >= 1 /\ (settled13.newOrderV2Bitfield1 # << >> /\ (settled13.newOrderV2Bitfield1[1] \div 64) % 2 > 0) THEN (IF settled13.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled13.minQty) ELSE << >>]
        settled15 == [settled14 EXCEPT !.maxFloor = IF settled14.numberOfNewOrderV2Bitfields >= 1 /\ (settled14.newOrderV2Bitfield1 # << >> /\ (settled14.newOrderV2Bitfield1[1] \div 128) % 2 > 0) THEN (IF settled14.maxFloor = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled14.maxFloor) ELSE << >>]
        settled16 == [settled15 EXCEPT !.symbol = IF settled15.numberOfNewOrderV2Bitfields >= 2 /\ (settled15.newOrderV2Bitfield2 # << >> /\ settled15.newOrderV2Bitfield2[1] % 2 > 0) THEN (IF settled15.symbol = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled15.symbol) ELSE << >>]
        settled17 == [settled16 EXCEPT !.currency = IF settled16.numberOfNewOrderV2Bitfields >= 2 /\ (settled16.newOrderV2Bitfield2 # << >> /\ (settled16.newOrderV2Bitfield2[1] \div 4) % 2 > 0) THEN (IF settled16.currency = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled16.currency) ELSE << >>]
        settled18 == [settled17 EXCEPT !.idSource = IF settled17.numberOfNewOrderV2Bitfields >= 2 /\ (settled17.newOrderV2Bitfield2 # << >> /\ (settled17.newOrderV2Bitfield2[1] \div 8) % 2 > 0) THEN (IF settled17.idSource = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.idSource) ELSE << >>]
        settled19 == [settled18 EXCEPT !.securityId = IF settled18.numberOfNewOrderV2Bitfields >= 2 /\ (settled18.newOrderV2Bitfield2 # << >> /\ (settled18.newOrderV2Bitfield2[1] \div 16) % 2 > 0) THEN (IF settled18.securityId = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled18.securityId) ELSE << >>]
        settled20 == [settled19 EXCEPT !.securityExchange = IF settled19.numberOfNewOrderV2Bitfields >= 2 /\ (settled19.newOrderV2Bitfield2 # << >> /\ (settled19.newOrderV2Bitfield2[1] \div 32) % 2 > 0) THEN (IF settled19.securityExchange = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled19.securityExchange) ELSE << >>]
        settled21 == [settled20 EXCEPT !.capacity = IF settled20.numberOfNewOrderV2Bitfields >= 2 /\ (settled20.newOrderV2Bitfield2 # << >> /\ (settled20.newOrderV2Bitfield2[1] \div 64) % 2 > 0) THEN (IF settled20.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled20.capacity) ELSE << >>]
        settled22 == [settled21 EXCEPT !.routingInst = IF settled21.numberOfNewOrderV2Bitfields >= 2 /\ (settled21.newOrderV2Bitfield2 # << >> /\ (settled21.newOrderV2Bitfield2[1] \div 128) % 2 > 0) THEN (IF settled21.routingInst = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled21.routingInst) ELSE << >>]
        settled23 == [settled22 EXCEPT !.account = IF settled22.numberOfNewOrderV2Bitfields >= 3 /\ (settled22.newOrderV2Bitfield3 # << >> /\ settled22.newOrderV2Bitfield3[1] % 2 > 0) THEN (IF settled22.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled22.account) ELSE << >>]
        settled24 == [settled23 EXCEPT !.displayIndicator = IF settled23.numberOfNewOrderV2Bitfields >= 3 /\ (settled23.newOrderV2Bitfield3 # << >> /\ (settled23.newOrderV2Bitfield3[1] \div 2) % 2 > 0) THEN (IF settled23.displayIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled23.displayIndicator) ELSE << >>]
        settled25 == [settled24 EXCEPT !.pegDifference = IF settled24.numberOfNewOrderV2Bitfields >= 3 /\ (settled24.newOrderV2Bitfield3 # << >> /\ (settled24.newOrderV2Bitfield3[1] \div 16) % 2 > 0) THEN (IF settled24.pegDifference = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled24.pegDifference) ELSE << >>]
        settled26 == [settled25 EXCEPT !.preventParticipantMatch = IF settled25.numberOfNewOrderV2Bitfields >= 3 /\ (settled25.newOrderV2Bitfield3 # << >> /\ (settled25.newOrderV2Bitfield3[1] \div 32) % 2 > 0) THEN (IF settled25.preventParticipantMatch = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled25.preventParticipantMatch) ELSE << >>]
        settled27 == [settled26 EXCEPT !.expireTime = IF settled26.numberOfNewOrderV2Bitfields >= 3 /\ (settled26.newOrderV2Bitfield3 # << >> /\ (settled26.newOrderV2Bitfield3[1] \div 128) % 2 > 0) THEN (IF settled26.expireTime = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled26.expireTime) ELSE << >>]
        settled28 == [settled27 EXCEPT !.liquidityProvision = IF settled27.numberOfNewOrderV2Bitfields >= 4 /\ (settled27.newOrderV2Bitfield4 # << >> /\ (settled27.newOrderV2Bitfield4[1] \div 128) % 2 > 0) THEN (IF settled27.liquidityProvision = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled27.liquidityProvision) ELSE << >>]
        settled29 == [settled28 EXCEPT !.clientId = IF settled28.numberOfNewOrderV2Bitfields >= 5 /\ (settled28.newOrderV2Bitfield5 # << >> /\ (settled28.newOrderV2Bitfield5[1] \div 16) % 2 > 0) THEN (IF settled28.clientId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled28.clientId) ELSE << >>]
        settled30 == [settled29 EXCEPT !.investorId = IF settled29.numberOfNewOrderV2Bitfields >= 5 /\ (settled29.newOrderV2Bitfield5 # << >> /\ (settled29.newOrderV2Bitfield5[1] \div 32) % 2 > 0) THEN (IF settled29.investorId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled29.investorId) ELSE << >>]
        settled31 == [settled30 EXCEPT !.executorId = IF settled30.numberOfNewOrderV2Bitfields >= 5 /\ (settled30.newOrderV2Bitfield5 # << >> /\ (settled30.newOrderV2Bitfield5[1] \div 64) % 2 > 0) THEN (IF settled30.executorId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled30.executorId) ELSE << >>]
        settled32 == [settled31 EXCEPT !.orderOrigination = IF settled31.numberOfNewOrderV2Bitfields >= 5 /\ (settled31.newOrderV2Bitfield5 # << >> /\ (settled31.newOrderV2Bitfield5[1] \div 128) % 2 > 0) THEN (IF settled31.orderOrigination = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled31.orderOrigination) ELSE << >>]
        settled33 == [settled32 EXCEPT !.algorithmicIndicator = IF settled32.numberOfNewOrderV2Bitfields >= 7 /\ (settled32.newOrderV2Bitfield7 # << >> /\ settled32.newOrderV2Bitfield7[1] % 2 > 0) THEN (IF settled32.algorithmicIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled32.algorithmicIndicator) ELSE << >>]
        settled34 == [settled33 EXCEPT !.clientQualifiedRole = IF settled33.numberOfNewOrderV2Bitfields >= 7 /\ (settled33.newOrderV2Bitfield7 # << >> /\ (settled33.newOrderV2Bitfield7[1] \div 4) % 2 > 0) THEN (IF settled33.clientQualifiedRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled33.clientQualifiedRole) ELSE << >>]
        settled35 == [settled34 EXCEPT !.investorQualifiedRole = IF settled34.numberOfNewOrderV2Bitfields >= 7 /\ (settled34.newOrderV2Bitfield7 # << >> /\ (settled34.newOrderV2Bitfield7[1] \div 8) % 2 > 0) THEN (IF settled34.investorQualifiedRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled34.investorQualifiedRole) ELSE << >>]
        settled36 == [settled35 EXCEPT !.executorQualifiedRole = IF settled35.numberOfNewOrderV2Bitfields >= 7 /\ (settled35.newOrderV2Bitfield7 # << >> /\ (settled35.newOrderV2Bitfield7[1] \div 16) % 2 > 0) THEN (IF settled35.executorQualifiedRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled35.executorQualifiedRole) ELSE << >>]
    IN  settled36

ZeroNewOrderV2Message ==
    SettleNewOrderV2Message([ clOrdId                     |-> [i \in 1 .. 20 |-> 0],
                              side                        |-> [i \in 1 .. 1 |-> 0],
                              orderQty                    |-> [i \in 1 .. 4 |-> 0],
                              numberOfNewOrderV2Bitfields |-> 0,
                              newOrderV2Bitfield1         |-> << >>,
                              newOrderV2Bitfield2         |-> << >>,
                              newOrderV2Bitfield3         |-> << >>,
                              newOrderV2Bitfield4         |-> << >>,
                              newOrderV2Bitfield5         |-> << >>,
                              newOrderV2Bitfield6         |-> << >>,
                              newOrderV2Bitfield7         |-> << >>,
                              clearingFirm                |-> << >>,
                              clearingAccount             |-> << >>,
                              price                       |-> << >>,
                              execInst                    |-> << >>,
                              ordType                     |-> << >>,
                              timeInForce                 |-> << >>,
                              minQty                      |-> << >>,
                              maxFloor                    |-> << >>,
                              symbol                      |-> << >>,
                              currency                    |-> << >>,
                              idSource                    |-> << >>,
                              securityId                  |-> << >>,
                              securityExchange            |-> << >>,
                              capacity                    |-> << >>,
                              routingInst                 |-> << >>,
                              account                     |-> << >>,
                              displayIndicator            |-> << >>,
                              pegDifference               |-> << >>,
                              preventParticipantMatch     |-> << >>,
                              expireTime                  |-> << >>,
                              liquidityProvision          |-> << >>,
                              clientId                    |-> << >>,
                              investorId                  |-> << >>,
                              executorId                  |-> << >>,
                              orderOrigination            |-> << >>,
                              algorithmicIndicator        |-> << >>,
                              clientQualifiedRole         |-> << >>,
                              investorQualifiedRole       |-> << >>,
                              executorQualifiedRole       |-> << >> ])

(* New Order V 2 Message at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderV2Message ==
    { ZeroNewOrderV2Message }
        \cup { SettleNewOrderV2Message([ZeroNewOrderV2Message EXCEPT !.clOrdId = one]) : one \in Sample(20) }
        \cup { SettleNewOrderV2Message([ZeroNewOrderV2Message EXCEPT !.side = one]) : one \in Sample(1) }
        \cup { SettleNewOrderV2Message([ZeroNewOrderV2Message EXCEPT !.orderQty = one]) : one \in Sample(4) }
        \cup { SettleNewOrderV2Message([ZeroNewOrderV2Message EXCEPT !.numberOfNewOrderV2Bitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleNewOrderV2Message([ZeroNewOrderV2Message EXCEPT !.numberOfNewOrderV2Bitfields = 1, !.newOrderV2Bitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleNewOrderV2Message([ZeroNewOrderV2Message EXCEPT !.numberOfNewOrderV2Bitfields = 2, !.newOrderV2Bitfield2 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleNewOrderV2Message([ZeroNewOrderV2Message EXCEPT !.numberOfNewOrderV2Bitfields = 3, !.newOrderV2Bitfield3 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleNewOrderV2Message([ZeroNewOrderV2Message EXCEPT !.numberOfNewOrderV2Bitfields = 4, !.newOrderV2Bitfield4 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleNewOrderV2Message([ZeroNewOrderV2Message EXCEPT !.numberOfNewOrderV2Bitfields = 5, !.newOrderV2Bitfield5 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleNewOrderV2Message([ZeroNewOrderV2Message EXCEPT !.numberOfNewOrderV2Bitfields = 6, !.newOrderV2Bitfield6 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleNewOrderV2Message([ZeroNewOrderV2Message EXCEPT !.numberOfNewOrderV2Bitfields = 7, !.newOrderV2Bitfield7 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleNewOrderV2Message([ZeroNewOrderV2Message EXCEPT !.numberOfNewOrderV2Bitfields = 1, !.newOrderV2Bitfield1 = <<1>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleNewOrderV2Message([ZeroNewOrderV2Message EXCEPT !.numberOfNewOrderV2Bitfields = 1, !.newOrderV2Bitfield1 = <<2>>, !.clearingAccount = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleNewOrderV2Message([ZeroNewOrderV2Message EXCEPT !.numberOfNewOrderV2Bitfields = 1, !.newOrderV2Bitfield1 = <<4>>, !.price = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleNewOrderV2Message([ZeroNewOrderV2Message EXCEPT !.numberOfNewOrderV2Bitfields = 1, !.newOrderV2Bitfield1 = <<8>>, !.execInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleNewOrderV2Message([ZeroNewOrderV2Message EXCEPT !.numberOfNewOrderV2Bitfields = 1, !.newOrderV2Bitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleNewOrderV2Message([ZeroNewOrderV2Message EXCEPT !.numberOfNewOrderV2Bitfields = 1, !.newOrderV2Bitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleNewOrderV2Message([ZeroNewOrderV2Message EXCEPT !.numberOfNewOrderV2Bitfields = 1, !.newOrderV2Bitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleNewOrderV2Message([ZeroNewOrderV2Message EXCEPT !.numberOfNewOrderV2Bitfields = 1, !.newOrderV2Bitfield1 = <<128>>, !.maxFloor = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleNewOrderV2Message([ZeroNewOrderV2Message EXCEPT !.numberOfNewOrderV2Bitfields = 2, !.newOrderV2Bitfield2 = <<1>>, !.symbol = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleNewOrderV2Message([ZeroNewOrderV2Message EXCEPT !.numberOfNewOrderV2Bitfields = 2, !.newOrderV2Bitfield2 = <<4>>, !.currency = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleNewOrderV2Message([ZeroNewOrderV2Message EXCEPT !.numberOfNewOrderV2Bitfields = 2, !.newOrderV2Bitfield2 = <<8>>, !.idSource = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleNewOrderV2Message([ZeroNewOrderV2Message EXCEPT !.numberOfNewOrderV2Bitfields = 2, !.newOrderV2Bitfield2 = <<16>>, !.securityId = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleNewOrderV2Message([ZeroNewOrderV2Message EXCEPT !.numberOfNewOrderV2Bitfields = 2, !.newOrderV2Bitfield2 = <<32>>, !.securityExchange = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleNewOrderV2Message([ZeroNewOrderV2Message EXCEPT !.numberOfNewOrderV2Bitfields = 2, !.newOrderV2Bitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleNewOrderV2Message([ZeroNewOrderV2Message EXCEPT !.numberOfNewOrderV2Bitfields = 2, !.newOrderV2Bitfield2 = <<128>>, !.routingInst = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleNewOrderV2Message([ZeroNewOrderV2Message EXCEPT !.numberOfNewOrderV2Bitfields = 3, !.newOrderV2Bitfield3 = <<1>>, !.account = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleNewOrderV2Message([ZeroNewOrderV2Message EXCEPT !.numberOfNewOrderV2Bitfields = 3, !.newOrderV2Bitfield3 = <<2>>, !.displayIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleNewOrderV2Message([ZeroNewOrderV2Message EXCEPT !.numberOfNewOrderV2Bitfields = 3, !.newOrderV2Bitfield3 = <<16>>, !.pegDifference = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleNewOrderV2Message([ZeroNewOrderV2Message EXCEPT !.numberOfNewOrderV2Bitfields = 3, !.newOrderV2Bitfield3 = <<32>>, !.preventParticipantMatch = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleNewOrderV2Message([ZeroNewOrderV2Message EXCEPT !.numberOfNewOrderV2Bitfields = 3, !.newOrderV2Bitfield3 = <<128>>, !.expireTime = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleNewOrderV2Message([ZeroNewOrderV2Message EXCEPT !.numberOfNewOrderV2Bitfields = 4, !.newOrderV2Bitfield4 = <<128>>, !.liquidityProvision = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleNewOrderV2Message([ZeroNewOrderV2Message EXCEPT !.numberOfNewOrderV2Bitfields = 5, !.newOrderV2Bitfield5 = <<16>>, !.clientId = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleNewOrderV2Message([ZeroNewOrderV2Message EXCEPT !.numberOfNewOrderV2Bitfields = 5, !.newOrderV2Bitfield5 = <<32>>, !.investorId = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleNewOrderV2Message([ZeroNewOrderV2Message EXCEPT !.numberOfNewOrderV2Bitfields = 5, !.newOrderV2Bitfield5 = <<64>>, !.executorId = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleNewOrderV2Message([ZeroNewOrderV2Message EXCEPT !.numberOfNewOrderV2Bitfields = 5, !.newOrderV2Bitfield5 = <<128>>, !.orderOrigination = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleNewOrderV2Message([ZeroNewOrderV2Message EXCEPT !.numberOfNewOrderV2Bitfields = 7, !.newOrderV2Bitfield7 = <<1>>, !.algorithmicIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleNewOrderV2Message([ZeroNewOrderV2Message EXCEPT !.numberOfNewOrderV2Bitfields = 7, !.newOrderV2Bitfield7 = <<4>>, !.clientQualifiedRole = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleNewOrderV2Message([ZeroNewOrderV2Message EXCEPT !.numberOfNewOrderV2Bitfields = 7, !.newOrderV2Bitfield7 = <<8>>, !.investorQualifiedRole = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleNewOrderV2Message([ZeroNewOrderV2Message EXCEPT !.numberOfNewOrderV2Bitfields = 7, !.newOrderV2Bitfield7 = <<16>>, !.executorQualifiedRole = one]) : one \in { <<held>> : held \in Sample(1) } }

(***************************************************************************)
(* Cancel Order V 2 Message                                                *)
(***************************************************************************)

CancelOrderV2Message ==
    [ origClOrdId                    : Sample(20),
      numberOfCancelOrderV2Bitfields : 0 .. 255,
      cancelOrderV2Bitfield1         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      cancelOrderV2Bitfield2         : { << >> } \cup { <<held>> : held \in Sample(1) },
      clearingFirm                   : { << >> } \cup { <<held>> : held \in Sample(4) } ]

EncodeCancelOrderV2Message(message) ==
    message.origClOrdId
        \o EncodeUIntBE(message.numberOfCancelOrderV2Bitfields, 1)
        \o (IF message.cancelOrderV2Bitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.cancelOrderV2Bitfield1[1], 1))
        \o (IF message.cancelOrderV2Bitfield2 = << >> THEN << >> ELSE message.cancelOrderV2Bitfield2[1])
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])

DecodeCancelOrderV2Message(bytes) ==
    LET origClOrdId == ReadBytes(bytes, 20) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET numberOfCancelOrderV2Bitfields == ReadUIntBE(origClOrdId.rest, 1) IN IF ~numberOfCancelOrderV2Bitfields.ok THEN Fail ELSE
    LET cancelOrderV2Bitfield1 == ReadWhen(numberOfCancelOrderV2Bitfields.value >= 1, ReadUIntLE(numberOfCancelOrderV2Bitfields.rest, 1), numberOfCancelOrderV2Bitfields.rest) IN IF ~cancelOrderV2Bitfield1.ok THEN Fail ELSE
    LET cancelOrderV2Bitfield2 == ReadWhen(numberOfCancelOrderV2Bitfields.value >= 2, ReadBytes(cancelOrderV2Bitfield1.rest, 1), cancelOrderV2Bitfield1.rest) IN IF ~cancelOrderV2Bitfield2.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfCancelOrderV2Bitfields.value >= 1 /\ (cancelOrderV2Bitfield1.value # << >> /\ cancelOrderV2Bitfield1.value[1] % 2 > 0), ReadBytes(cancelOrderV2Bitfield2.rest, 4), cancelOrderV2Bitfield2.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    Ok([ origClOrdId                    |-> origClOrdId.value,
         numberOfCancelOrderV2Bitfields |-> numberOfCancelOrderV2Bitfields.value,
         cancelOrderV2Bitfield1         |-> cancelOrderV2Bitfield1.value,
         cancelOrderV2Bitfield2         |-> cancelOrderV2Bitfield2.value,
         clearingFirm                   |-> clearingFirm.value ], clearingFirm.rest)

(* Cancel Order V 2 Message with each field marked present by fields before it there exactly where they say *)
SettleCancelOrderV2Message(message) ==
    LET settled1 == [message EXCEPT !.cancelOrderV2Bitfield1 = IF message.numberOfCancelOrderV2Bitfields >= 1 THEN (IF message.cancelOrderV2Bitfield1 = << >> THEN <<0>> ELSE message.cancelOrderV2Bitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.cancelOrderV2Bitfield2 = IF settled1.numberOfCancelOrderV2Bitfields >= 2 THEN (IF settled1.cancelOrderV2Bitfield2 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled1.cancelOrderV2Bitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.clearingFirm = IF settled2.numberOfCancelOrderV2Bitfields >= 1 /\ (settled2.cancelOrderV2Bitfield1 # << >> /\ settled2.cancelOrderV2Bitfield1[1] % 2 > 0) THEN (IF settled2.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled2.clearingFirm) ELSE << >>]
    IN  settled3

ZeroCancelOrderV2Message ==
    SettleCancelOrderV2Message([ origClOrdId                    |-> [i \in 1 .. 20 |-> 0],
                                 numberOfCancelOrderV2Bitfields |-> 0,
                                 cancelOrderV2Bitfield1         |-> << >>,
                                 cancelOrderV2Bitfield2         |-> << >>,
                                 clearingFirm                   |-> << >> ])

(* Cancel Order V 2 Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelOrderV2Message ==
    { ZeroCancelOrderV2Message }
        \cup { SettleCancelOrderV2Message([ZeroCancelOrderV2Message EXCEPT !.origClOrdId = one]) : one \in Sample(20) }
        \cup { SettleCancelOrderV2Message([ZeroCancelOrderV2Message EXCEPT !.numberOfCancelOrderV2Bitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleCancelOrderV2Message([ZeroCancelOrderV2Message EXCEPT !.numberOfCancelOrderV2Bitfields = 1, !.cancelOrderV2Bitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleCancelOrderV2Message([ZeroCancelOrderV2Message EXCEPT !.numberOfCancelOrderV2Bitfields = 2, !.cancelOrderV2Bitfield2 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelOrderV2Message([ZeroCancelOrderV2Message EXCEPT !.numberOfCancelOrderV2Bitfields = 1, !.cancelOrderV2Bitfield1 = <<1>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }

(***************************************************************************)
(* Modify Order V 2 Message                                                *)
(***************************************************************************)

ModifyOrderV2Message ==
    [ clOrdId                        : Sample(20),
      origClOrdId                    : Sample(20),
      numberOfModifyOrderV2Bitfields : 0 .. 255,
      modifyOrderV2Bitfield1         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      modifyOrderV2Bitfield2         : { << >> } \cup { <<held>> : held \in Sample(1) },
      clearingFirm                   : { << >> } \cup { <<held>> : held \in Sample(4) },
      ordType                        : { << >> } \cup { <<held>> : held \in Sample(1) },
      cancelOrigOnReject             : { << >> } \cup { <<held>> : held \in Sample(1) },
      execInst                       : { << >> } \cup { <<held>> : held \in Sample(1) } ]

EncodeModifyOrderV2Message(message) ==
    message.clOrdId
        \o message.origClOrdId
        \o EncodeUIntBE(message.numberOfModifyOrderV2Bitfields, 1)
        \o (IF message.modifyOrderV2Bitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.modifyOrderV2Bitfield1[1], 1))
        \o (IF message.modifyOrderV2Bitfield2 = << >> THEN << >> ELSE message.modifyOrderV2Bitfield2[1])
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])
        \o (IF message.ordType = << >> THEN << >> ELSE message.ordType[1])
        \o (IF message.cancelOrigOnReject = << >> THEN << >> ELSE message.cancelOrigOnReject[1])
        \o (IF message.execInst = << >> THEN << >> ELSE message.execInst[1])

DecodeModifyOrderV2Message(bytes) ==
    LET clOrdId == ReadBytes(bytes, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 20) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET numberOfModifyOrderV2Bitfields == ReadUIntBE(origClOrdId.rest, 1) IN IF ~numberOfModifyOrderV2Bitfields.ok THEN Fail ELSE
    LET modifyOrderV2Bitfield1 == ReadWhen(numberOfModifyOrderV2Bitfields.value >= 1, ReadUIntLE(numberOfModifyOrderV2Bitfields.rest, 1), numberOfModifyOrderV2Bitfields.rest) IN IF ~modifyOrderV2Bitfield1.ok THEN Fail ELSE
    LET modifyOrderV2Bitfield2 == ReadWhen(numberOfModifyOrderV2Bitfields.value >= 2, ReadBytes(modifyOrderV2Bitfield1.rest, 1), modifyOrderV2Bitfield1.rest) IN IF ~modifyOrderV2Bitfield2.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfModifyOrderV2Bitfields.value >= 1 /\ (modifyOrderV2Bitfield1.value # << >> /\ modifyOrderV2Bitfield1.value[1] % 2 > 0), ReadBytes(modifyOrderV2Bitfield2.rest, 4), modifyOrderV2Bitfield2.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfModifyOrderV2Bitfields.value >= 1 /\ (modifyOrderV2Bitfield1.value # << >> /\ (modifyOrderV2Bitfield1.value[1] \div 16) % 2 > 0), ReadBytes(clearingFirm.rest, 1), clearingFirm.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET cancelOrigOnReject == ReadWhen(numberOfModifyOrderV2Bitfields.value >= 1 /\ (modifyOrderV2Bitfield1.value # << >> /\ (modifyOrderV2Bitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~cancelOrigOnReject.ok THEN Fail ELSE
    LET execInst == ReadWhen(numberOfModifyOrderV2Bitfields.value >= 1 /\ (modifyOrderV2Bitfield1.value # << >> /\ (modifyOrderV2Bitfield1.value[1] \div 64) % 2 > 0), ReadBytes(cancelOrigOnReject.rest, 1), cancelOrigOnReject.rest) IN IF ~execInst.ok THEN Fail ELSE
    Ok([ clOrdId                        |-> clOrdId.value,
         origClOrdId                    |-> origClOrdId.value,
         numberOfModifyOrderV2Bitfields |-> numberOfModifyOrderV2Bitfields.value,
         modifyOrderV2Bitfield1         |-> modifyOrderV2Bitfield1.value,
         modifyOrderV2Bitfield2         |-> modifyOrderV2Bitfield2.value,
         clearingFirm                   |-> clearingFirm.value,
         ordType                        |-> ordType.value,
         cancelOrigOnReject             |-> cancelOrigOnReject.value,
         execInst                       |-> execInst.value ], execInst.rest)

(* Modify Order V 2 Message with each field marked present by fields before it there exactly where they say *)
SettleModifyOrderV2Message(message) ==
    LET settled1 == [message EXCEPT !.modifyOrderV2Bitfield1 = IF message.numberOfModifyOrderV2Bitfields >= 1 THEN (IF message.modifyOrderV2Bitfield1 = << >> THEN <<0>> ELSE message.modifyOrderV2Bitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.modifyOrderV2Bitfield2 = IF settled1.numberOfModifyOrderV2Bitfields >= 2 THEN (IF settled1.modifyOrderV2Bitfield2 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled1.modifyOrderV2Bitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.clearingFirm = IF settled2.numberOfModifyOrderV2Bitfields >= 1 /\ (settled2.modifyOrderV2Bitfield1 # << >> /\ settled2.modifyOrderV2Bitfield1[1] % 2 > 0) THEN (IF settled2.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled2.clearingFirm) ELSE << >>]
        settled4 == [settled3 EXCEPT !.ordType = IF settled3.numberOfModifyOrderV2Bitfields >= 1 /\ (settled3.modifyOrderV2Bitfield1 # << >> /\ (settled3.modifyOrderV2Bitfield1[1] \div 16) % 2 > 0) THEN (IF settled3.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled3.ordType) ELSE << >>]
        settled5 == [settled4 EXCEPT !.cancelOrigOnReject = IF settled4.numberOfModifyOrderV2Bitfields >= 1 /\ (settled4.modifyOrderV2Bitfield1 # << >> /\ (settled4.modifyOrderV2Bitfield1[1] \div 32) % 2 > 0) THEN (IF settled4.cancelOrigOnReject = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled4.cancelOrigOnReject) ELSE << >>]
        settled6 == [settled5 EXCEPT !.execInst = IF settled5.numberOfModifyOrderV2Bitfields >= 1 /\ (settled5.modifyOrderV2Bitfield1 # << >> /\ (settled5.modifyOrderV2Bitfield1[1] \div 64) % 2 > 0) THEN (IF settled5.execInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled5.execInst) ELSE << >>]
    IN  settled6

ZeroModifyOrderV2Message ==
    SettleModifyOrderV2Message([ clOrdId                        |-> [i \in 1 .. 20 |-> 0],
                                 origClOrdId                    |-> [i \in 1 .. 20 |-> 0],
                                 numberOfModifyOrderV2Bitfields |-> 0,
                                 modifyOrderV2Bitfield1         |-> << >>,
                                 modifyOrderV2Bitfield2         |-> << >>,
                                 clearingFirm                   |-> << >>,
                                 ordType                        |-> << >>,
                                 cancelOrigOnReject             |-> << >>,
                                 execInst                       |-> << >> ])

(* Modify Order V 2 Message at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderV2Message ==
    { ZeroModifyOrderV2Message }
        \cup { SettleModifyOrderV2Message([ZeroModifyOrderV2Message EXCEPT !.clOrdId = one]) : one \in Sample(20) }
        \cup { SettleModifyOrderV2Message([ZeroModifyOrderV2Message EXCEPT !.origClOrdId = one]) : one \in Sample(20) }
        \cup { SettleModifyOrderV2Message([ZeroModifyOrderV2Message EXCEPT !.numberOfModifyOrderV2Bitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleModifyOrderV2Message([ZeroModifyOrderV2Message EXCEPT !.numberOfModifyOrderV2Bitfields = 1, !.modifyOrderV2Bitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleModifyOrderV2Message([ZeroModifyOrderV2Message EXCEPT !.numberOfModifyOrderV2Bitfields = 2, !.modifyOrderV2Bitfield2 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleModifyOrderV2Message([ZeroModifyOrderV2Message EXCEPT !.numberOfModifyOrderV2Bitfields = 1, !.modifyOrderV2Bitfield1 = <<1>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleModifyOrderV2Message([ZeroModifyOrderV2Message EXCEPT !.numberOfModifyOrderV2Bitfields = 1, !.modifyOrderV2Bitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleModifyOrderV2Message([ZeroModifyOrderV2Message EXCEPT !.numberOfModifyOrderV2Bitfields = 1, !.modifyOrderV2Bitfield1 = <<32>>, !.cancelOrigOnReject = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleModifyOrderV2Message([ZeroModifyOrderV2Message EXCEPT !.numberOfModifyOrderV2Bitfields = 1, !.modifyOrderV2Bitfield1 = <<64>>, !.execInst = one]) : one \in { <<held>> : held \in Sample(1) } }

(***************************************************************************)
(* Trd Cap Rpt Side Grp                                                    *)
(***************************************************************************)

TrdCapRptSideGrp ==
    [ side      : Sample(1),
      capacity  : { << >> } \cup { <<held>> : held \in Sample(1) },
      partyId   : Sample(4),
      account   : { << >> } \cup { <<held>> : held \in Sample(16) },
      partyRole : { << >> } \cup { <<held>> : held \in Sample(1) } ]

EncodeTrdCapRptSideGrp(message) ==
    message.side
        \o (IF message.capacity = << >> THEN << >> ELSE message.capacity[1])
        \o message.partyId
        \o (IF message.account = << >> THEN << >> ELSE message.account[1])
        \o (IF message.partyRole = << >> THEN << >> ELSE message.partyRole[1])

DecodeTrdCapRptSideGrp(bytes, handedNumberOfTradeCaptureReportV2Bitfields, handedTradeCaptureReportV2Bitfield2) ==
    LET side == ReadBytes(bytes, 1) IN IF ~side.ok THEN Fail ELSE
    LET capacity == ReadWhen(handedNumberOfTradeCaptureReportV2Bitfields >= 2 /\ (handedTradeCaptureReportV2Bitfield2 # << >> /\ handedTradeCaptureReportV2Bitfield2[1] % 2 > 0), ReadBytes(side.rest, 1), side.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET partyId == ReadBytes(capacity.rest, 4) IN IF ~partyId.ok THEN Fail ELSE
    LET account == ReadWhen(handedNumberOfTradeCaptureReportV2Bitfields >= 2 /\ (handedTradeCaptureReportV2Bitfield2 # << >> /\ (handedTradeCaptureReportV2Bitfield2[1] \div 2) % 2 > 0), ReadBytes(partyId.rest, 16), partyId.rest) IN IF ~account.ok THEN Fail ELSE
    LET partyRole == ReadWhen(handedNumberOfTradeCaptureReportV2Bitfields >= 2 /\ (handedTradeCaptureReportV2Bitfield2 # << >> /\ (handedTradeCaptureReportV2Bitfield2[1] \div 16) % 2 > 0), ReadBytes(account.rest, 1), account.rest) IN IF ~partyRole.ok THEN Fail ELSE
    Ok([ side      |-> side.value,
         capacity  |-> capacity.value,
         partyId   |-> partyId.value,
         account   |-> account.value,
         partyRole |-> partyRole.value ], partyRole.rest)

(* Trd Cap Rpt Side Grp with each field marked present by fields before it there exactly where they say *)
SettleTrdCapRptSideGrp(message, handedNumberOfTradeCaptureReportV2Bitfields, handedTradeCaptureReportV2Bitfield2) ==
    LET settled1 == [message EXCEPT !.capacity = IF handedNumberOfTradeCaptureReportV2Bitfields >= 2 /\ (handedTradeCaptureReportV2Bitfield2 # << >> /\ handedTradeCaptureReportV2Bitfield2[1] % 2 > 0) THEN (IF message.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE message.capacity) ELSE << >>]
        settled2 == [settled1 EXCEPT !.account = IF handedNumberOfTradeCaptureReportV2Bitfields >= 2 /\ (handedTradeCaptureReportV2Bitfield2 # << >> /\ (handedTradeCaptureReportV2Bitfield2[1] \div 2) % 2 > 0) THEN (IF settled1.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled1.account) ELSE << >>]
        settled3 == [settled2 EXCEPT !.partyRole = IF handedNumberOfTradeCaptureReportV2Bitfields >= 2 /\ (handedTradeCaptureReportV2Bitfield2 # << >> /\ (handedTradeCaptureReportV2Bitfield2[1] \div 16) % 2 > 0) THEN (IF settled2.partyRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled2.partyRole) ELSE << >>]
    IN  settled3

ZeroTrdCapRptSideGrp ==
    SettleTrdCapRptSideGrp([ side      |-> [i \in 1 .. 1 |-> 0],
                             capacity  |-> << >>,
                             partyId   |-> [i \in 1 .. 4 |-> 0],
                             account   |-> << >>,
                             partyRole |-> << >> ], 0, << >>)

(* Trd Cap Rpt Side Grp at zero, then each field in turn at the values it is checked at *)
CheckedTrdCapRptSideGrp ==
    { [given |-> <<0, << >>>>, message |-> ZeroTrdCapRptSideGrp] }
        \cup { [given |-> <<0, << >>>>, message |-> SettleTrdCapRptSideGrp([ZeroTrdCapRptSideGrp EXCEPT !.side = one], 0, << >>)] : one \in Sample(1) }
        \cup { [given |-> <<2, <<1>>>>, message |-> SettleTrdCapRptSideGrp([ZeroTrdCapRptSideGrp EXCEPT !.capacity = one], 2, <<1>>)] : one \in { <<held>> : held \in Sample(1) } }
        \cup { [given |-> <<0, << >>>>, message |-> SettleTrdCapRptSideGrp([ZeroTrdCapRptSideGrp EXCEPT !.partyId = one], 0, << >>)] : one \in Sample(4) }
        \cup { [given |-> <<2, <<2>>>>, message |-> SettleTrdCapRptSideGrp([ZeroTrdCapRptSideGrp EXCEPT !.account = one], 2, <<2>>)] : one \in { <<held>> : held \in Sample(16) } }
        \cup { [given |-> <<2, <<16>>>>, message |-> SettleTrdCapRptSideGrp([ZeroTrdCapRptSideGrp EXCEPT !.partyRole = one], 2, <<16>>)] : one \in { <<held>> : held \in Sample(1) } }

(* A run of Trd Cap Rpt Side Grp, written one after another *)
RECURSIVE EncodeTrdCapRptSideGrpList(_)
EncodeTrdCapRptSideGrpList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTrdCapRptSideGrp(Head(messages)) \o EncodeTrdCapRptSideGrpList(Tail(messages))

(* As many Trd Cap Rpt Side Grp as the field that counts them says *)
RECURSIVE ReadTrdCapRptSideGrpList(_, _, _, _)
ReadTrdCapRptSideGrpList(bytes, count, handedNumberOfTradeCaptureReportV2Bitfields, handedTradeCaptureReportV2Bitfield2) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeTrdCapRptSideGrp(bytes, handedNumberOfTradeCaptureReportV2Bitfields, handedTradeCaptureReportV2Bitfield2)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTrdCapRptSideGrpList(one.rest, count - 1, handedNumberOfTradeCaptureReportV2Bitfields, handedTradeCaptureReportV2Bitfield2)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Trd Cap Rpt Side Grp of each kind, for the lists that carry them *)
OneTrdCapRptSideGrp == { ZeroTrdCapRptSideGrp }

(***************************************************************************)
(* Trade Capture Report V 2 Message                                        *)
(***************************************************************************)

TradeCaptureReportV2Message ==
    [ tradeReportId                         : Sample(20),
      lastShares                            : Sample(4),
      tradeCaptureLastPx                    : Sample(8),
      numberOfTradeCaptureReportV2Bitfields : 0 .. 255,
      tradeCaptureReportV2Bitfield1         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCaptureReportV2Bitfield2         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCaptureReportV2Bitfield3         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCaptureReportV2Bitfield4         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCaptureReportV2Bitfield5         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      trdCapRptSideGrp                      : SampleLists(OneTrdCapRptSideGrp),
      symbol                                : { << >> } \cup { <<held>> : held \in Sample(8) },
      currency                              : { << >> } \cup { <<held>> : held \in Sample(3) },
      idSource                              : { << >> } \cup { <<held>> : held \in Sample(1) },
      securityId                            : { << >> } \cup { <<held>> : held \in Sample(16) },
      securityExchange                      : { << >> } \cup { <<held>> : held \in Sample(4) },
      execInst                              : { << >> } \cup { <<held>> : held \in Sample(1) },
      transactionCategory                   : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeTime                             : { << >> } \cup { <<held>> : held \in Sample(8) },
      tradeReportTransType                  : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeId                               : { << >> } \cup { <<held>> : held \in Sample(8) },
      venueType                             : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradingSessionSubId                   : { << >> } \cup { <<held>> : held \in Sample(1) },
      matchType                             : { << >> } \cup { <<held>> : held \in Sample(1) },
      trdSubType                            : { << >> } \cup { <<held>> : held \in Sample(1) },
      secondaryTrdType                      : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradePriceCondition                   : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradePublishIndicator                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      largeSize                             : { << >> } \cup { <<held>> : held \in Sample(8) },
      executionMethod                       : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeReportType                       : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeHandlingInstruction              : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeLinkId                           : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeReportRefId                      : { << >> } \cup { <<held>> : held \in Sample(20) },
      grossTradeAmt                         : { << >> } \cup { <<held>> : held \in Sample(8) },
      tolerance                             : { << >> } \cup { <<held>> : held \in Sample(2) },
      orderCategory                         : { << >> } \cup { <<held>> : held \in Sample(1) },
      settlementPrice                       : { << >> } \cup { <<held>> : held \in Sample(8) },
      settlementDate                        : { << >> } \cup { <<held>> : held \in Sample(8) },
      priceFormation                        : { << >> } \cup { <<held>> : held \in Sample(1) },
      algorithmicIndicator                  : { << >> } \cup { <<held>> : held \in Sample(1) } ]

EncodeTradeCaptureReportV2Message(message) ==
    message.tradeReportId
        \o message.lastShares
        \o message.tradeCaptureLastPx
        \o EncodeUIntBE(message.numberOfTradeCaptureReportV2Bitfields, 1)
        \o (IF message.tradeCaptureReportV2Bitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCaptureReportV2Bitfield1[1], 1))
        \o (IF message.tradeCaptureReportV2Bitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCaptureReportV2Bitfield2[1], 1))
        \o (IF message.tradeCaptureReportV2Bitfield3 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCaptureReportV2Bitfield3[1], 1))
        \o (IF message.tradeCaptureReportV2Bitfield4 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCaptureReportV2Bitfield4[1], 1))
        \o (IF message.tradeCaptureReportV2Bitfield5 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCaptureReportV2Bitfield5[1], 1))
        \o EncodeUIntBE(Len(message.trdCapRptSideGrp), 1)
        \o EncodeTrdCapRptSideGrpList(message.trdCapRptSideGrp)
        \o (IF message.symbol = << >> THEN << >> ELSE message.symbol[1])
        \o (IF message.currency = << >> THEN << >> ELSE message.currency[1])
        \o (IF message.idSource = << >> THEN << >> ELSE message.idSource[1])
        \o (IF message.securityId = << >> THEN << >> ELSE message.securityId[1])
        \o (IF message.securityExchange = << >> THEN << >> ELSE message.securityExchange[1])
        \o (IF message.execInst = << >> THEN << >> ELSE message.execInst[1])
        \o (IF message.transactionCategory = << >> THEN << >> ELSE message.transactionCategory[1])
        \o (IF message.tradeTime = << >> THEN << >> ELSE message.tradeTime[1])
        \o (IF message.tradeReportTransType = << >> THEN << >> ELSE message.tradeReportTransType[1])
        \o (IF message.tradeId = << >> THEN << >> ELSE message.tradeId[1])
        \o (IF message.venueType = << >> THEN << >> ELSE message.venueType[1])
        \o (IF message.tradingSessionSubId = << >> THEN << >> ELSE message.tradingSessionSubId[1])
        \o (IF message.matchType = << >> THEN << >> ELSE message.matchType[1])
        \o (IF message.trdSubType = << >> THEN << >> ELSE message.trdSubType[1])
        \o (IF message.secondaryTrdType = << >> THEN << >> ELSE message.secondaryTrdType[1])
        \o (IF message.tradePriceCondition = << >> THEN << >> ELSE message.tradePriceCondition[1])
        \o (IF message.tradePublishIndicator = << >> THEN << >> ELSE message.tradePublishIndicator[1])
        \o (IF message.largeSize = << >> THEN << >> ELSE message.largeSize[1])
        \o (IF message.executionMethod = << >> THEN << >> ELSE message.executionMethod[1])
        \o (IF message.tradeReportType = << >> THEN << >> ELSE message.tradeReportType[1])
        \o (IF message.tradeHandlingInstruction = << >> THEN << >> ELSE message.tradeHandlingInstruction[1])
        \o (IF message.tradeLinkId = << >> THEN << >> ELSE message.tradeLinkId[1])
        \o (IF message.tradeReportRefId = << >> THEN << >> ELSE message.tradeReportRefId[1])
        \o (IF message.grossTradeAmt = << >> THEN << >> ELSE message.grossTradeAmt[1])
        \o (IF message.tolerance = << >> THEN << >> ELSE message.tolerance[1])
        \o (IF message.orderCategory = << >> THEN << >> ELSE message.orderCategory[1])
        \o (IF message.settlementPrice = << >> THEN << >> ELSE message.settlementPrice[1])
        \o (IF message.settlementDate = << >> THEN << >> ELSE message.settlementDate[1])
        \o (IF message.priceFormation = << >> THEN << >> ELSE message.priceFormation[1])
        \o (IF message.algorithmicIndicator = << >> THEN << >> ELSE message.algorithmicIndicator[1])

DecodeTradeCaptureReportV2Message(bytes) ==
    LET tradeReportId == ReadBytes(bytes, 20) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET lastShares == ReadBytes(tradeReportId.rest, 4) IN IF ~lastShares.ok THEN Fail ELSE
    LET tradeCaptureLastPx == ReadBytes(lastShares.rest, 8) IN IF ~tradeCaptureLastPx.ok THEN Fail ELSE
    LET numberOfTradeCaptureReportV2Bitfields == ReadUIntBE(tradeCaptureLastPx.rest, 1) IN IF ~numberOfTradeCaptureReportV2Bitfields.ok THEN Fail ELSE
    LET tradeCaptureReportV2Bitfield1 == ReadWhen(numberOfTradeCaptureReportV2Bitfields.value >= 1, ReadUIntLE(numberOfTradeCaptureReportV2Bitfields.rest, 1), numberOfTradeCaptureReportV2Bitfields.rest) IN IF ~tradeCaptureReportV2Bitfield1.ok THEN Fail ELSE
    LET tradeCaptureReportV2Bitfield2 == ReadWhen(numberOfTradeCaptureReportV2Bitfields.value >= 2, ReadUIntLE(tradeCaptureReportV2Bitfield1.rest, 1), tradeCaptureReportV2Bitfield1.rest) IN IF ~tradeCaptureReportV2Bitfield2.ok THEN Fail ELSE
    LET tradeCaptureReportV2Bitfield3 == ReadWhen(numberOfTradeCaptureReportV2Bitfields.value >= 3, ReadUIntLE(tradeCaptureReportV2Bitfield2.rest, 1), tradeCaptureReportV2Bitfield2.rest) IN IF ~tradeCaptureReportV2Bitfield3.ok THEN Fail ELSE
    LET tradeCaptureReportV2Bitfield4 == ReadWhen(numberOfTradeCaptureReportV2Bitfields.value >= 4, ReadUIntLE(tradeCaptureReportV2Bitfield3.rest, 1), tradeCaptureReportV2Bitfield3.rest) IN IF ~tradeCaptureReportV2Bitfield4.ok THEN Fail ELSE
    LET tradeCaptureReportV2Bitfield5 == ReadWhen(numberOfTradeCaptureReportV2Bitfields.value >= 5, ReadUIntLE(tradeCaptureReportV2Bitfield4.rest, 1), tradeCaptureReportV2Bitfield4.rest) IN IF ~tradeCaptureReportV2Bitfield5.ok THEN Fail ELSE
    LET noSides == ReadUIntBE(tradeCaptureReportV2Bitfield5.rest, 1) IN IF ~noSides.ok THEN Fail ELSE
    LET trdCapRptSideGrp == ReadTrdCapRptSideGrpList(noSides.rest, noSides.value, numberOfTradeCaptureReportV2Bitfields.value, tradeCaptureReportV2Bitfield2.value) IN IF ~trdCapRptSideGrp.ok THEN Fail ELSE
    LET symbol == ReadWhen(numberOfTradeCaptureReportV2Bitfields.value >= 1 /\ (tradeCaptureReportV2Bitfield1.value # << >> /\ tradeCaptureReportV2Bitfield1.value[1] % 2 > 0), ReadBytes(trdCapRptSideGrp.rest, 8), trdCapRptSideGrp.rest) IN IF ~symbol.ok THEN Fail ELSE
    LET currency == ReadWhen(numberOfTradeCaptureReportV2Bitfields.value >= 1 /\ (tradeCaptureReportV2Bitfield1.value # << >> /\ (tradeCaptureReportV2Bitfield1.value[1] \div 4) % 2 > 0), ReadBytes(symbol.rest, 3), symbol.rest) IN IF ~currency.ok THEN Fail ELSE
    LET idSource == ReadWhen(numberOfTradeCaptureReportV2Bitfields.value >= 1 /\ (tradeCaptureReportV2Bitfield1.value # << >> /\ (tradeCaptureReportV2Bitfield1.value[1] \div 8) % 2 > 0), ReadBytes(currency.rest, 1), currency.rest) IN IF ~idSource.ok THEN Fail ELSE
    LET securityId == ReadWhen(numberOfTradeCaptureReportV2Bitfields.value >= 1 /\ (tradeCaptureReportV2Bitfield1.value # << >> /\ (tradeCaptureReportV2Bitfield1.value[1] \div 16) % 2 > 0), ReadBytes(idSource.rest, 16), idSource.rest) IN IF ~securityId.ok THEN Fail ELSE
    LET securityExchange == ReadWhen(numberOfTradeCaptureReportV2Bitfields.value >= 1 /\ (tradeCaptureReportV2Bitfield1.value # << >> /\ (tradeCaptureReportV2Bitfield1.value[1] \div 32) % 2 > 0), ReadBytes(securityId.rest, 4), securityId.rest) IN IF ~securityExchange.ok THEN Fail ELSE
    LET execInst == ReadWhen(numberOfTradeCaptureReportV2Bitfields.value >= 1 /\ (tradeCaptureReportV2Bitfield1.value # << >> /\ (tradeCaptureReportV2Bitfield1.value[1] \div 64) % 2 > 0), ReadBytes(securityExchange.rest, 1), securityExchange.rest) IN IF ~execInst.ok THEN Fail ELSE
    LET transactionCategory == ReadWhen(numberOfTradeCaptureReportV2Bitfields.value >= 2 /\ (tradeCaptureReportV2Bitfield2.value # << >> /\ (tradeCaptureReportV2Bitfield2.value[1] \div 4) % 2 > 0), ReadBytes(execInst.rest, 1), execInst.rest) IN IF ~transactionCategory.ok THEN Fail ELSE
    LET tradeTime == ReadWhen(numberOfTradeCaptureReportV2Bitfields.value >= 2 /\ (tradeCaptureReportV2Bitfield2.value # << >> /\ (tradeCaptureReportV2Bitfield2.value[1] \div 8) % 2 > 0), ReadBytes(transactionCategory.rest, 8), transactionCategory.rest) IN IF ~tradeTime.ok THEN Fail ELSE
    LET tradeReportTransType == ReadWhen(numberOfTradeCaptureReportV2Bitfields.value >= 2 /\ (tradeCaptureReportV2Bitfield2.value # << >> /\ (tradeCaptureReportV2Bitfield2.value[1] \div 32) % 2 > 0), ReadBytes(tradeTime.rest, 1), tradeTime.rest) IN IF ~tradeReportTransType.ok THEN Fail ELSE
    LET tradeId == ReadWhen(numberOfTradeCaptureReportV2Bitfields.value >= 2 /\ (tradeCaptureReportV2Bitfield2.value # << >> /\ (tradeCaptureReportV2Bitfield2.value[1] \div 64) % 2 > 0), ReadBytes(tradeReportTransType.rest, 8), tradeReportTransType.rest) IN IF ~tradeId.ok THEN Fail ELSE
    LET venueType == ReadWhen(numberOfTradeCaptureReportV2Bitfields.value >= 2 /\ (tradeCaptureReportV2Bitfield2.value # << >> /\ (tradeCaptureReportV2Bitfield2.value[1] \div 128) % 2 > 0), ReadBytes(tradeId.rest, 1), tradeId.rest) IN IF ~venueType.ok THEN Fail ELSE
    LET tradingSessionSubId == ReadWhen(numberOfTradeCaptureReportV2Bitfields.value >= 3 /\ (tradeCaptureReportV2Bitfield3.value # << >> /\ tradeCaptureReportV2Bitfield3.value[1] % 2 > 0), ReadBytes(venueType.rest, 1), venueType.rest) IN IF ~tradingSessionSubId.ok THEN Fail ELSE
    LET matchType == ReadWhen(numberOfTradeCaptureReportV2Bitfields.value >= 3 /\ (tradeCaptureReportV2Bitfield3.value # << >> /\ (tradeCaptureReportV2Bitfield3.value[1] \div 2) % 2 > 0), ReadBytes(tradingSessionSubId.rest, 1), tradingSessionSubId.rest) IN IF ~matchType.ok THEN Fail ELSE
    LET trdSubType == ReadWhen(numberOfTradeCaptureReportV2Bitfields.value >= 3 /\ (tradeCaptureReportV2Bitfield3.value # << >> /\ (tradeCaptureReportV2Bitfield3.value[1] \div 4) % 2 > 0), ReadBytes(matchType.rest, 1), matchType.rest) IN IF ~trdSubType.ok THEN Fail ELSE
    LET secondaryTrdType == ReadWhen(numberOfTradeCaptureReportV2Bitfields.value >= 3 /\ (tradeCaptureReportV2Bitfield3.value # << >> /\ (tradeCaptureReportV2Bitfield3.value[1] \div 8) % 2 > 0), ReadBytes(trdSubType.rest, 1), trdSubType.rest) IN IF ~secondaryTrdType.ok THEN Fail ELSE
    LET tradePriceCondition == ReadWhen(numberOfTradeCaptureReportV2Bitfields.value >= 3 /\ (tradeCaptureReportV2Bitfield3.value # << >> /\ (tradeCaptureReportV2Bitfield3.value[1] \div 16) % 2 > 0), ReadBytes(secondaryTrdType.rest, 1), secondaryTrdType.rest) IN IF ~tradePriceCondition.ok THEN Fail ELSE
    LET tradePublishIndicator == ReadWhen(numberOfTradeCaptureReportV2Bitfields.value >= 3 /\ (tradeCaptureReportV2Bitfield3.value # << >> /\ (tradeCaptureReportV2Bitfield3.value[1] \div 32) % 2 > 0), ReadBytes(tradePriceCondition.rest, 1), tradePriceCondition.rest) IN IF ~tradePublishIndicator.ok THEN Fail ELSE
    LET largeSize == ReadWhen(numberOfTradeCaptureReportV2Bitfields.value >= 3 /\ (tradeCaptureReportV2Bitfield3.value # << >> /\ (tradeCaptureReportV2Bitfield3.value[1] \div 64) % 2 > 0), ReadBytes(tradePublishIndicator.rest, 8), tradePublishIndicator.rest) IN IF ~largeSize.ok THEN Fail ELSE
    LET executionMethod == ReadWhen(numberOfTradeCaptureReportV2Bitfields.value >= 3 /\ (tradeCaptureReportV2Bitfield3.value # << >> /\ (tradeCaptureReportV2Bitfield3.value[1] \div 128) % 2 > 0), ReadBytes(largeSize.rest, 1), largeSize.rest) IN IF ~executionMethod.ok THEN Fail ELSE
    LET tradeReportType == ReadWhen(numberOfTradeCaptureReportV2Bitfields.value >= 4 /\ (tradeCaptureReportV2Bitfield4.value # << >> /\ tradeCaptureReportV2Bitfield4.value[1] % 2 > 0), ReadBytes(executionMethod.rest, 1), executionMethod.rest) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET tradeHandlingInstruction == ReadWhen(numberOfTradeCaptureReportV2Bitfields.value >= 4 /\ (tradeCaptureReportV2Bitfield4.value # << >> /\ (tradeCaptureReportV2Bitfield4.value[1] \div 2) % 2 > 0), ReadBytes(tradeReportType.rest, 1), tradeReportType.rest) IN IF ~tradeHandlingInstruction.ok THEN Fail ELSE
    LET tradeLinkId == ReadWhen(numberOfTradeCaptureReportV2Bitfields.value >= 4 /\ (tradeCaptureReportV2Bitfield4.value # << >> /\ (tradeCaptureReportV2Bitfield4.value[1] \div 4) % 2 > 0), ReadBytes(tradeHandlingInstruction.rest, 1), tradeHandlingInstruction.rest) IN IF ~tradeLinkId.ok THEN Fail ELSE
    LET tradeReportRefId == ReadWhen(numberOfTradeCaptureReportV2Bitfields.value >= 4 /\ (tradeCaptureReportV2Bitfield4.value # << >> /\ (tradeCaptureReportV2Bitfield4.value[1] \div 8) % 2 > 0), ReadBytes(tradeLinkId.rest, 20), tradeLinkId.rest) IN IF ~tradeReportRefId.ok THEN Fail ELSE
    LET grossTradeAmt == ReadWhen(numberOfTradeCaptureReportV2Bitfields.value >= 4 /\ (tradeCaptureReportV2Bitfield4.value # << >> /\ (tradeCaptureReportV2Bitfield4.value[1] \div 16) % 2 > 0), ReadBytes(tradeReportRefId.rest, 8), tradeReportRefId.rest) IN IF ~grossTradeAmt.ok THEN Fail ELSE
    LET tolerance == ReadWhen(numberOfTradeCaptureReportV2Bitfields.value >= 4 /\ (tradeCaptureReportV2Bitfield4.value # << >> /\ (tradeCaptureReportV2Bitfield4.value[1] \div 32) % 2 > 0), ReadBytes(grossTradeAmt.rest, 2), grossTradeAmt.rest) IN IF ~tolerance.ok THEN Fail ELSE
    LET orderCategory == ReadWhen(numberOfTradeCaptureReportV2Bitfields.value >= 4 /\ (tradeCaptureReportV2Bitfield4.value # << >> /\ (tradeCaptureReportV2Bitfield4.value[1] \div 64) % 2 > 0), ReadBytes(tolerance.rest, 1), tolerance.rest) IN IF ~orderCategory.ok THEN Fail ELSE
    LET settlementPrice == ReadWhen(numberOfTradeCaptureReportV2Bitfields.value >= 4 /\ (tradeCaptureReportV2Bitfield4.value # << >> /\ (tradeCaptureReportV2Bitfield4.value[1] \div 128) % 2 > 0), ReadBytes(orderCategory.rest, 8), orderCategory.rest) IN IF ~settlementPrice.ok THEN Fail ELSE
    LET settlementDate == ReadWhen(numberOfTradeCaptureReportV2Bitfields.value >= 5 /\ (tradeCaptureReportV2Bitfield5.value # << >> /\ tradeCaptureReportV2Bitfield5.value[1] % 2 > 0), ReadBytes(settlementPrice.rest, 8), settlementPrice.rest) IN IF ~settlementDate.ok THEN Fail ELSE
    LET priceFormation == ReadWhen(numberOfTradeCaptureReportV2Bitfields.value >= 5 /\ (tradeCaptureReportV2Bitfield5.value # << >> /\ (tradeCaptureReportV2Bitfield5.value[1] \div 2) % 2 > 0), ReadBytes(settlementDate.rest, 1), settlementDate.rest) IN IF ~priceFormation.ok THEN Fail ELSE
    LET algorithmicIndicator == ReadWhen(numberOfTradeCaptureReportV2Bitfields.value >= 5 /\ (tradeCaptureReportV2Bitfield5.value # << >> /\ (tradeCaptureReportV2Bitfield5.value[1] \div 4) % 2 > 0), ReadBytes(priceFormation.rest, 1), priceFormation.rest) IN IF ~algorithmicIndicator.ok THEN Fail ELSE
    Ok([ tradeReportId                         |-> tradeReportId.value,
         lastShares                            |-> lastShares.value,
         tradeCaptureLastPx                    |-> tradeCaptureLastPx.value,
         numberOfTradeCaptureReportV2Bitfields |-> numberOfTradeCaptureReportV2Bitfields.value,
         tradeCaptureReportV2Bitfield1         |-> tradeCaptureReportV2Bitfield1.value,
         tradeCaptureReportV2Bitfield2         |-> tradeCaptureReportV2Bitfield2.value,
         tradeCaptureReportV2Bitfield3         |-> tradeCaptureReportV2Bitfield3.value,
         tradeCaptureReportV2Bitfield4         |-> tradeCaptureReportV2Bitfield4.value,
         tradeCaptureReportV2Bitfield5         |-> tradeCaptureReportV2Bitfield5.value,
         trdCapRptSideGrp                      |-> trdCapRptSideGrp.value,
         symbol                                |-> symbol.value,
         currency                              |-> currency.value,
         idSource                              |-> idSource.value,
         securityId                            |-> securityId.value,
         securityExchange                      |-> securityExchange.value,
         execInst                              |-> execInst.value,
         transactionCategory                   |-> transactionCategory.value,
         tradeTime                             |-> tradeTime.value,
         tradeReportTransType                  |-> tradeReportTransType.value,
         tradeId                               |-> tradeId.value,
         venueType                             |-> venueType.value,
         tradingSessionSubId                   |-> tradingSessionSubId.value,
         matchType                             |-> matchType.value,
         trdSubType                            |-> trdSubType.value,
         secondaryTrdType                      |-> secondaryTrdType.value,
         tradePriceCondition                   |-> tradePriceCondition.value,
         tradePublishIndicator                 |-> tradePublishIndicator.value,
         largeSize                             |-> largeSize.value,
         executionMethod                       |-> executionMethod.value,
         tradeReportType                       |-> tradeReportType.value,
         tradeHandlingInstruction              |-> tradeHandlingInstruction.value,
         tradeLinkId                           |-> tradeLinkId.value,
         tradeReportRefId                      |-> tradeReportRefId.value,
         grossTradeAmt                         |-> grossTradeAmt.value,
         tolerance                             |-> tolerance.value,
         orderCategory                         |-> orderCategory.value,
         settlementPrice                       |-> settlementPrice.value,
         settlementDate                        |-> settlementDate.value,
         priceFormation                        |-> priceFormation.value,
         algorithmicIndicator                  |-> algorithmicIndicator.value ], algorithmicIndicator.rest)

(* Trade Capture Report V 2 Message with each field marked present by fields before it there exactly where they say *)
SettleTradeCaptureReportV2Message(message) ==
    LET settled1 == [message EXCEPT !.tradeCaptureReportV2Bitfield1 = IF message.numberOfTradeCaptureReportV2Bitfields >= 1 THEN (IF message.tradeCaptureReportV2Bitfield1 = << >> THEN <<0>> ELSE message.tradeCaptureReportV2Bitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.tradeCaptureReportV2Bitfield2 = IF settled1.numberOfTradeCaptureReportV2Bitfields >= 2 THEN (IF settled1.tradeCaptureReportV2Bitfield2 = << >> THEN <<0>> ELSE settled1.tradeCaptureReportV2Bitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.tradeCaptureReportV2Bitfield3 = IF settled2.numberOfTradeCaptureReportV2Bitfields >= 3 THEN (IF settled2.tradeCaptureReportV2Bitfield3 = << >> THEN <<0>> ELSE settled2.tradeCaptureReportV2Bitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.tradeCaptureReportV2Bitfield4 = IF settled3.numberOfTradeCaptureReportV2Bitfields >= 4 THEN (IF settled3.tradeCaptureReportV2Bitfield4 = << >> THEN <<0>> ELSE settled3.tradeCaptureReportV2Bitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.tradeCaptureReportV2Bitfield5 = IF settled4.numberOfTradeCaptureReportV2Bitfields >= 5 THEN (IF settled4.tradeCaptureReportV2Bitfield5 = << >> THEN <<0>> ELSE settled4.tradeCaptureReportV2Bitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.trdCapRptSideGrp = [i \in DOMAIN settled5.trdCapRptSideGrp |-> SettleTrdCapRptSideGrp(settled5.trdCapRptSideGrp[i], settled5.numberOfTradeCaptureReportV2Bitfields, settled5.tradeCaptureReportV2Bitfield2)]]
        settled7 == [settled6 EXCEPT !.symbol = IF settled6.numberOfTradeCaptureReportV2Bitfields >= 1 /\ (settled6.tradeCaptureReportV2Bitfield1 # << >> /\ settled6.tradeCaptureReportV2Bitfield1[1] % 2 > 0) THEN (IF settled6.symbol = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled6.symbol) ELSE << >>]
        settled8 == [settled7 EXCEPT !.currency = IF settled7.numberOfTradeCaptureReportV2Bitfields >= 1 /\ (settled7.tradeCaptureReportV2Bitfield1 # << >> /\ (settled7.tradeCaptureReportV2Bitfield1[1] \div 4) % 2 > 0) THEN (IF settled7.currency = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled7.currency) ELSE << >>]
        settled9 == [settled8 EXCEPT !.idSource = IF settled8.numberOfTradeCaptureReportV2Bitfields >= 1 /\ (settled8.tradeCaptureReportV2Bitfield1 # << >> /\ (settled8.tradeCaptureReportV2Bitfield1[1] \div 8) % 2 > 0) THEN (IF settled8.idSource = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled8.idSource) ELSE << >>]
        settled10 == [settled9 EXCEPT !.securityId = IF settled9.numberOfTradeCaptureReportV2Bitfields >= 1 /\ (settled9.tradeCaptureReportV2Bitfield1 # << >> /\ (settled9.tradeCaptureReportV2Bitfield1[1] \div 16) % 2 > 0) THEN (IF settled9.securityId = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled9.securityId) ELSE << >>]
        settled11 == [settled10 EXCEPT !.securityExchange = IF settled10.numberOfTradeCaptureReportV2Bitfields >= 1 /\ (settled10.tradeCaptureReportV2Bitfield1 # << >> /\ (settled10.tradeCaptureReportV2Bitfield1[1] \div 32) % 2 > 0) THEN (IF settled10.securityExchange = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled10.securityExchange) ELSE << >>]
        settled12 == [settled11 EXCEPT !.execInst = IF settled11.numberOfTradeCaptureReportV2Bitfields >= 1 /\ (settled11.tradeCaptureReportV2Bitfield1 # << >> /\ (settled11.tradeCaptureReportV2Bitfield1[1] \div 64) % 2 > 0) THEN (IF settled11.execInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.execInst) ELSE << >>]
        settled13 == [settled12 EXCEPT !.transactionCategory = IF settled12.numberOfTradeCaptureReportV2Bitfields >= 2 /\ (settled12.tradeCaptureReportV2Bitfield2 # << >> /\ (settled12.tradeCaptureReportV2Bitfield2[1] \div 4) % 2 > 0) THEN (IF settled12.transactionCategory = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.transactionCategory) ELSE << >>]
        settled14 == [settled13 EXCEPT !.tradeTime = IF settled13.numberOfTradeCaptureReportV2Bitfields >= 2 /\ (settled13.tradeCaptureReportV2Bitfield2 # << >> /\ (settled13.tradeCaptureReportV2Bitfield2[1] \div 8) % 2 > 0) THEN (IF settled13.tradeTime = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled13.tradeTime) ELSE << >>]
        settled15 == [settled14 EXCEPT !.tradeReportTransType = IF settled14.numberOfTradeCaptureReportV2Bitfields >= 2 /\ (settled14.tradeCaptureReportV2Bitfield2 # << >> /\ (settled14.tradeCaptureReportV2Bitfield2[1] \div 32) % 2 > 0) THEN (IF settled14.tradeReportTransType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.tradeReportTransType) ELSE << >>]
        settled16 == [settled15 EXCEPT !.tradeId = IF settled15.numberOfTradeCaptureReportV2Bitfields >= 2 /\ (settled15.tradeCaptureReportV2Bitfield2 # << >> /\ (settled15.tradeCaptureReportV2Bitfield2[1] \div 64) % 2 > 0) THEN (IF settled15.tradeId = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled15.tradeId) ELSE << >>]
        settled17 == [settled16 EXCEPT !.venueType = IF settled16.numberOfTradeCaptureReportV2Bitfields >= 2 /\ (settled16.tradeCaptureReportV2Bitfield2 # << >> /\ (settled16.tradeCaptureReportV2Bitfield2[1] \div 128) % 2 > 0) THEN (IF settled16.venueType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled16.venueType) ELSE << >>]
        settled18 == [settled17 EXCEPT !.tradingSessionSubId = IF settled17.numberOfTradeCaptureReportV2Bitfields >= 3 /\ (settled17.tradeCaptureReportV2Bitfield3 # << >> /\ settled17.tradeCaptureReportV2Bitfield3[1] % 2 > 0) THEN (IF settled17.tradingSessionSubId = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.tradingSessionSubId) ELSE << >>]
        settled19 == [settled18 EXCEPT !.matchType = IF settled18.numberOfTradeCaptureReportV2Bitfields >= 3 /\ (settled18.tradeCaptureReportV2Bitfield3 # << >> /\ (settled18.tradeCaptureReportV2Bitfield3[1] \div 2) % 2 > 0) THEN (IF settled18.matchType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled18.matchType) ELSE << >>]
        settled20 == [settled19 EXCEPT !.trdSubType = IF settled19.numberOfTradeCaptureReportV2Bitfields >= 3 /\ (settled19.tradeCaptureReportV2Bitfield3 # << >> /\ (settled19.tradeCaptureReportV2Bitfield3[1] \div 4) % 2 > 0) THEN (IF settled19.trdSubType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled19.trdSubType) ELSE << >>]
        settled21 == [settled20 EXCEPT !.secondaryTrdType = IF settled20.numberOfTradeCaptureReportV2Bitfields >= 3 /\ (settled20.tradeCaptureReportV2Bitfield3 # << >> /\ (settled20.tradeCaptureReportV2Bitfield3[1] \div 8) % 2 > 0) THEN (IF settled20.secondaryTrdType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled20.secondaryTrdType) ELSE << >>]
        settled22 == [settled21 EXCEPT !.tradePriceCondition = IF settled21.numberOfTradeCaptureReportV2Bitfields >= 3 /\ (settled21.tradeCaptureReportV2Bitfield3 # << >> /\ (settled21.tradeCaptureReportV2Bitfield3[1] \div 16) % 2 > 0) THEN (IF settled21.tradePriceCondition = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled21.tradePriceCondition) ELSE << >>]
        settled23 == [settled22 EXCEPT !.tradePublishIndicator = IF settled22.numberOfTradeCaptureReportV2Bitfields >= 3 /\ (settled22.tradeCaptureReportV2Bitfield3 # << >> /\ (settled22.tradeCaptureReportV2Bitfield3[1] \div 32) % 2 > 0) THEN (IF settled22.tradePublishIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled22.tradePublishIndicator) ELSE << >>]
        settled24 == [settled23 EXCEPT !.largeSize = IF settled23.numberOfTradeCaptureReportV2Bitfields >= 3 /\ (settled23.tradeCaptureReportV2Bitfield3 # << >> /\ (settled23.tradeCaptureReportV2Bitfield3[1] \div 64) % 2 > 0) THEN (IF settled23.largeSize = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled23.largeSize) ELSE << >>]
        settled25 == [settled24 EXCEPT !.executionMethod = IF settled24.numberOfTradeCaptureReportV2Bitfields >= 3 /\ (settled24.tradeCaptureReportV2Bitfield3 # << >> /\ (settled24.tradeCaptureReportV2Bitfield3[1] \div 128) % 2 > 0) THEN (IF settled24.executionMethod = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled24.executionMethod) ELSE << >>]
        settled26 == [settled25 EXCEPT !.tradeReportType = IF settled25.numberOfTradeCaptureReportV2Bitfields >= 4 /\ (settled25.tradeCaptureReportV2Bitfield4 # << >> /\ settled25.tradeCaptureReportV2Bitfield4[1] % 2 > 0) THEN (IF settled25.tradeReportType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled25.tradeReportType) ELSE << >>]
        settled27 == [settled26 EXCEPT !.tradeHandlingInstruction = IF settled26.numberOfTradeCaptureReportV2Bitfields >= 4 /\ (settled26.tradeCaptureReportV2Bitfield4 # << >> /\ (settled26.tradeCaptureReportV2Bitfield4[1] \div 2) % 2 > 0) THEN (IF settled26.tradeHandlingInstruction = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled26.tradeHandlingInstruction) ELSE << >>]
        settled28 == [settled27 EXCEPT !.tradeLinkId = IF settled27.numberOfTradeCaptureReportV2Bitfields >= 4 /\ (settled27.tradeCaptureReportV2Bitfield4 # << >> /\ (settled27.tradeCaptureReportV2Bitfield4[1] \div 4) % 2 > 0) THEN (IF settled27.tradeLinkId = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled27.tradeLinkId) ELSE << >>]
        settled29 == [settled28 EXCEPT !.tradeReportRefId = IF settled28.numberOfTradeCaptureReportV2Bitfields >= 4 /\ (settled28.tradeCaptureReportV2Bitfield4 # << >> /\ (settled28.tradeCaptureReportV2Bitfield4[1] \div 8) % 2 > 0) THEN (IF settled28.tradeReportRefId = << >> THEN <<[i \in 1 .. 20 |-> 0]>> ELSE settled28.tradeReportRefId) ELSE << >>]
        settled30 == [settled29 EXCEPT !.grossTradeAmt = IF settled29.numberOfTradeCaptureReportV2Bitfields >= 4 /\ (settled29.tradeCaptureReportV2Bitfield4 # << >> /\ (settled29.tradeCaptureReportV2Bitfield4[1] \div 16) % 2 > 0) THEN (IF settled29.grossTradeAmt = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled29.grossTradeAmt) ELSE << >>]
        settled31 == [settled30 EXCEPT !.tolerance = IF settled30.numberOfTradeCaptureReportV2Bitfields >= 4 /\ (settled30.tradeCaptureReportV2Bitfield4 # << >> /\ (settled30.tradeCaptureReportV2Bitfield4[1] \div 32) % 2 > 0) THEN (IF settled30.tolerance = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled30.tolerance) ELSE << >>]
        settled32 == [settled31 EXCEPT !.orderCategory = IF settled31.numberOfTradeCaptureReportV2Bitfields >= 4 /\ (settled31.tradeCaptureReportV2Bitfield4 # << >> /\ (settled31.tradeCaptureReportV2Bitfield4[1] \div 64) % 2 > 0) THEN (IF settled31.orderCategory = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled31.orderCategory) ELSE << >>]
        settled33 == [settled32 EXCEPT !.settlementPrice = IF settled32.numberOfTradeCaptureReportV2Bitfields >= 4 /\ (settled32.tradeCaptureReportV2Bitfield4 # << >> /\ (settled32.tradeCaptureReportV2Bitfield4[1] \div 128) % 2 > 0) THEN (IF settled32.settlementPrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled32.settlementPrice) ELSE << >>]
        settled34 == [settled33 EXCEPT !.settlementDate = IF settled33.numberOfTradeCaptureReportV2Bitfields >= 5 /\ (settled33.tradeCaptureReportV2Bitfield5 # << >> /\ settled33.tradeCaptureReportV2Bitfield5[1] % 2 > 0) THEN (IF settled33.settlementDate = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled33.settlementDate) ELSE << >>]
        settled35 == [settled34 EXCEPT !.priceFormation = IF settled34.numberOfTradeCaptureReportV2Bitfields >= 5 /\ (settled34.tradeCaptureReportV2Bitfield5 # << >> /\ (settled34.tradeCaptureReportV2Bitfield5[1] \div 2) % 2 > 0) THEN (IF settled34.priceFormation = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled34.priceFormation) ELSE << >>]
        settled36 == [settled35 EXCEPT !.algorithmicIndicator = IF settled35.numberOfTradeCaptureReportV2Bitfields >= 5 /\ (settled35.tradeCaptureReportV2Bitfield5 # << >> /\ (settled35.tradeCaptureReportV2Bitfield5[1] \div 4) % 2 > 0) THEN (IF settled35.algorithmicIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled35.algorithmicIndicator) ELSE << >>]
    IN  settled36

ZeroTradeCaptureReportV2Message ==
    SettleTradeCaptureReportV2Message([ tradeReportId                         |-> [i \in 1 .. 20 |-> 0],
                                        lastShares                            |-> [i \in 1 .. 4 |-> 0],
                                        tradeCaptureLastPx                    |-> [i \in 1 .. 8 |-> 0],
                                        numberOfTradeCaptureReportV2Bitfields |-> 0,
                                        tradeCaptureReportV2Bitfield1         |-> << >>,
                                        tradeCaptureReportV2Bitfield2         |-> << >>,
                                        tradeCaptureReportV2Bitfield3         |-> << >>,
                                        tradeCaptureReportV2Bitfield4         |-> << >>,
                                        tradeCaptureReportV2Bitfield5         |-> << >>,
                                        trdCapRptSideGrp                      |-> << >>,
                                        symbol                                |-> << >>,
                                        currency                              |-> << >>,
                                        idSource                              |-> << >>,
                                        securityId                            |-> << >>,
                                        securityExchange                      |-> << >>,
                                        execInst                              |-> << >>,
                                        transactionCategory                   |-> << >>,
                                        tradeTime                             |-> << >>,
                                        tradeReportTransType                  |-> << >>,
                                        tradeId                               |-> << >>,
                                        venueType                             |-> << >>,
                                        tradingSessionSubId                   |-> << >>,
                                        matchType                             |-> << >>,
                                        trdSubType                            |-> << >>,
                                        secondaryTrdType                      |-> << >>,
                                        tradePriceCondition                   |-> << >>,
                                        tradePublishIndicator                 |-> << >>,
                                        largeSize                             |-> << >>,
                                        executionMethod                       |-> << >>,
                                        tradeReportType                       |-> << >>,
                                        tradeHandlingInstruction              |-> << >>,
                                        tradeLinkId                           |-> << >>,
                                        tradeReportRefId                      |-> << >>,
                                        grossTradeAmt                         |-> << >>,
                                        tolerance                             |-> << >>,
                                        orderCategory                         |-> << >>,
                                        settlementPrice                       |-> << >>,
                                        settlementDate                        |-> << >>,
                                        priceFormation                        |-> << >>,
                                        algorithmicIndicator                  |-> << >> ])

(* Trade Capture Report V 2 Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCaptureReportV2Message ==
    { ZeroTradeCaptureReportV2Message }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.tradeReportId = one]) : one \in Sample(20) }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.lastShares = one]) : one \in Sample(4) }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.tradeCaptureLastPx = one]) : one \in Sample(8) }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.numberOfTradeCaptureReportV2Bitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.numberOfTradeCaptureReportV2Bitfields = 1, !.tradeCaptureReportV2Bitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.numberOfTradeCaptureReportV2Bitfields = 2, !.tradeCaptureReportV2Bitfield2 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.numberOfTradeCaptureReportV2Bitfields = 3, !.tradeCaptureReportV2Bitfield3 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.numberOfTradeCaptureReportV2Bitfields = 4, !.tradeCaptureReportV2Bitfield4 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.numberOfTradeCaptureReportV2Bitfields = 5, !.tradeCaptureReportV2Bitfield5 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.trdCapRptSideGrp = one]) : one \in SampleLists(OneTrdCapRptSideGrp) }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.numberOfTradeCaptureReportV2Bitfields = 2, !.tradeCaptureReportV2Bitfield2 = <<1>>, !.trdCapRptSideGrp = one]) : one \in SampleLists(OneTrdCapRptSideGrp) }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.numberOfTradeCaptureReportV2Bitfields = 2, !.tradeCaptureReportV2Bitfield2 = <<2>>, !.trdCapRptSideGrp = one]) : one \in SampleLists(OneTrdCapRptSideGrp) }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.numberOfTradeCaptureReportV2Bitfields = 2, !.tradeCaptureReportV2Bitfield2 = <<16>>, !.trdCapRptSideGrp = one]) : one \in SampleLists(OneTrdCapRptSideGrp) }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.numberOfTradeCaptureReportV2Bitfields = 1, !.tradeCaptureReportV2Bitfield1 = <<1>>, !.symbol = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.numberOfTradeCaptureReportV2Bitfields = 1, !.tradeCaptureReportV2Bitfield1 = <<4>>, !.currency = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.numberOfTradeCaptureReportV2Bitfields = 1, !.tradeCaptureReportV2Bitfield1 = <<8>>, !.idSource = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.numberOfTradeCaptureReportV2Bitfields = 1, !.tradeCaptureReportV2Bitfield1 = <<16>>, !.securityId = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.numberOfTradeCaptureReportV2Bitfields = 1, !.tradeCaptureReportV2Bitfield1 = <<32>>, !.securityExchange = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.numberOfTradeCaptureReportV2Bitfields = 1, !.tradeCaptureReportV2Bitfield1 = <<64>>, !.execInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.numberOfTradeCaptureReportV2Bitfields = 2, !.tradeCaptureReportV2Bitfield2 = <<4>>, !.transactionCategory = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.numberOfTradeCaptureReportV2Bitfields = 2, !.tradeCaptureReportV2Bitfield2 = <<8>>, !.tradeTime = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.numberOfTradeCaptureReportV2Bitfields = 2, !.tradeCaptureReportV2Bitfield2 = <<32>>, !.tradeReportTransType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.numberOfTradeCaptureReportV2Bitfields = 2, !.tradeCaptureReportV2Bitfield2 = <<64>>, !.tradeId = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.numberOfTradeCaptureReportV2Bitfields = 2, !.tradeCaptureReportV2Bitfield2 = <<128>>, !.venueType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.numberOfTradeCaptureReportV2Bitfields = 3, !.tradeCaptureReportV2Bitfield3 = <<1>>, !.tradingSessionSubId = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.numberOfTradeCaptureReportV2Bitfields = 3, !.tradeCaptureReportV2Bitfield3 = <<2>>, !.matchType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.numberOfTradeCaptureReportV2Bitfields = 3, !.tradeCaptureReportV2Bitfield3 = <<4>>, !.trdSubType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.numberOfTradeCaptureReportV2Bitfields = 3, !.tradeCaptureReportV2Bitfield3 = <<8>>, !.secondaryTrdType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.numberOfTradeCaptureReportV2Bitfields = 3, !.tradeCaptureReportV2Bitfield3 = <<16>>, !.tradePriceCondition = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.numberOfTradeCaptureReportV2Bitfields = 3, !.tradeCaptureReportV2Bitfield3 = <<32>>, !.tradePublishIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.numberOfTradeCaptureReportV2Bitfields = 3, !.tradeCaptureReportV2Bitfield3 = <<64>>, !.largeSize = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.numberOfTradeCaptureReportV2Bitfields = 3, !.tradeCaptureReportV2Bitfield3 = <<128>>, !.executionMethod = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.numberOfTradeCaptureReportV2Bitfields = 4, !.tradeCaptureReportV2Bitfield4 = <<1>>, !.tradeReportType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.numberOfTradeCaptureReportV2Bitfields = 4, !.tradeCaptureReportV2Bitfield4 = <<2>>, !.tradeHandlingInstruction = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.numberOfTradeCaptureReportV2Bitfields = 4, !.tradeCaptureReportV2Bitfield4 = <<4>>, !.tradeLinkId = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.numberOfTradeCaptureReportV2Bitfields = 4, !.tradeCaptureReportV2Bitfield4 = <<8>>, !.tradeReportRefId = one]) : one \in { <<held>> : held \in Sample(20) } }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.numberOfTradeCaptureReportV2Bitfields = 4, !.tradeCaptureReportV2Bitfield4 = <<16>>, !.grossTradeAmt = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.numberOfTradeCaptureReportV2Bitfields = 4, !.tradeCaptureReportV2Bitfield4 = <<32>>, !.tolerance = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.numberOfTradeCaptureReportV2Bitfields = 4, !.tradeCaptureReportV2Bitfield4 = <<64>>, !.orderCategory = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.numberOfTradeCaptureReportV2Bitfields = 4, !.tradeCaptureReportV2Bitfield4 = <<128>>, !.settlementPrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.numberOfTradeCaptureReportV2Bitfields = 5, !.tradeCaptureReportV2Bitfield5 = <<1>>, !.settlementDate = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.numberOfTradeCaptureReportV2Bitfields = 5, !.tradeCaptureReportV2Bitfield5 = <<2>>, !.priceFormation = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.numberOfTradeCaptureReportV2Bitfields = 5, !.tradeCaptureReportV2Bitfield5 = <<4>>, !.algorithmicIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }

(***************************************************************************)
(* Order Acknowledgment V 2 Message                                        *)
(***************************************************************************)

OrderAcknowledgmentV2Message ==
    [ transactionTime                       : Sample(8),
      clOrdId                               : Sample(20),
      orderId                               : Sample(8),
      reserved1                             : Sample(1),
      numberOfReturnBitfields               : 0 .. 255,
      orderAcknowledgmentV2ReturnBitfield1  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderAcknowledgmentV2ReturnBitfield2  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderAcknowledgmentV2ReturnBitfield3  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderAcknowledgmentV2ReturnBitfield4  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentV2ReturnBitfield5  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderAcknowledgmentV2ReturnBitfield6  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderAcknowledgmentV2ReturnBitfield7  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentV2ReturnBitfield8  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentV2ReturnBitfield9  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderAcknowledgmentV2ReturnBitfield10 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderAcknowledgmentV2ReturnBitfield11 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderAcknowledgmentV2ReturnBitfield12 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentV2ReturnBitfield13 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentV2ReturnBitfield14 : { << >> } \cup { <<held>> : held \in Sample(1) },
      side                                  : { << >> } \cup { <<held>> : held \in Sample(1) },
      pegDifference                         : { << >> } \cup { <<held>> : held \in Sample(8) },
      price                                 : { << >> } \cup { <<held>> : held \in Sample(8) },
      execInst                              : { << >> } \cup { <<held>> : held \in Sample(1) },
      ordType                               : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce                           : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                                : { << >> } \cup { <<held>> : held \in Sample(4) },
      symbol                                : { << >> } \cup { <<held>> : held \in Sample(8) },
      currency                              : { << >> } \cup { <<held>> : held \in Sample(3) },
      idSource                              : { << >> } \cup { <<held>> : held \in Sample(1) },
      securityId                            : { << >> } \cup { <<held>> : held \in Sample(16) },
      securityExchange                      : { << >> } \cup { <<held>> : held \in Sample(4) },
      capacity                              : { << >> } \cup { <<held>> : held \in Sample(1) },
      account                               : { << >> } \cup { <<held>> : held \in Sample(16) },
      clearingFirm                          : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingAccount                       : { << >> } \cup { <<held>> : held \in Sample(4) },
      displayIndicator                      : { << >> } \cup { <<held>> : held \in Sample(1) },
      maxFloor                              : { << >> } \cup { <<held>> : held \in Sample(4) },
      orderQty                              : { << >> } \cup { <<held>> : held \in Sample(4) },
      preventParticipantMatch               : { << >> } \cup { <<held>> : held \in Sample(3) },
      origClOrdId                           : { << >> } \cup { <<held>> : held \in Sample(20) },
      leavesQty                             : { << >> } \cup { <<held>> : held \in Sample(4) },
      lastShares                            : { << >> } \cup { <<held>> : held \in Sample(4) },
      lastPx                                : { << >> } \cup { <<held>> : held \in Sample(8) },
      displayPrice                          : { << >> } \cup { <<held>> : held \in Sample(8) },
      workingPrice                          : { << >> } \cup { <<held>> : held \in Sample(8) },
      baseLiquidityIndicator                : { << >> } \cup { <<held>> : held \in Sample(1) },
      expireTime                            : { << >> } \cup { <<held>> : held \in Sample(8) },
      secondaryOrderId                      : { << >> } \cup { <<held>> : held \in Sample(8) },
      liquidityProvision                    : { << >> } \cup { <<held>> : held \in Sample(1) },
      waiverType                            : { << >> } \cup { <<held>> : held \in Sample(1) },
      priceFormation                        : { << >> } \cup { <<held>> : held \in Sample(1) },
      clientQualifiedRole                   : { << >> } \cup { <<held>> : held \in Sample(1) },
      clientId                              : { << >> } \cup { <<held>> : held \in Sample(4) },
      investorId                            : { << >> } \cup { <<held>> : held \in Sample(4) },
      executorId                            : { << >> } \cup { <<held>> : held \in Sample(4) },
      orderOrigination                      : { << >> } \cup { <<held>> : held \in Sample(1) },
      algorithmicIndicator                  : { << >> } \cup { <<held>> : held \in Sample(1) },
      deferralReason                        : { << >> } \cup { <<held>> : held \in Sample(1) },
      investorQualifiedRole                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      executorQualifiedRole                 : { << >> } \cup { <<held>> : held \in Sample(1) } ]

EncodeOrderAcknowledgmentV2Message(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.orderId
        \o message.reserved1
        \o EncodeUIntBE(message.numberOfReturnBitfields, 1)
        \o (IF message.orderAcknowledgmentV2ReturnBitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.orderAcknowledgmentV2ReturnBitfield1[1], 1))
        \o (IF message.orderAcknowledgmentV2ReturnBitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.orderAcknowledgmentV2ReturnBitfield2[1], 1))
        \o (IF message.orderAcknowledgmentV2ReturnBitfield3 = << >> THEN << >> ELSE EncodeUIntLE(message.orderAcknowledgmentV2ReturnBitfield3[1], 1))
        \o (IF message.orderAcknowledgmentV2ReturnBitfield4 = << >> THEN << >> ELSE message.orderAcknowledgmentV2ReturnBitfield4[1])
        \o (IF message.orderAcknowledgmentV2ReturnBitfield5 = << >> THEN << >> ELSE EncodeUIntLE(message.orderAcknowledgmentV2ReturnBitfield5[1], 1))
        \o (IF message.orderAcknowledgmentV2ReturnBitfield6 = << >> THEN << >> ELSE EncodeUIntLE(message.orderAcknowledgmentV2ReturnBitfield6[1], 1))
        \o (IF message.orderAcknowledgmentV2ReturnBitfield7 = << >> THEN << >> ELSE message.orderAcknowledgmentV2ReturnBitfield7[1])
        \o (IF message.orderAcknowledgmentV2ReturnBitfield8 = << >> THEN << >> ELSE message.orderAcknowledgmentV2ReturnBitfield8[1])
        \o (IF message.orderAcknowledgmentV2ReturnBitfield9 = << >> THEN << >> ELSE EncodeUIntLE(message.orderAcknowledgmentV2ReturnBitfield9[1], 1))
        \o (IF message.orderAcknowledgmentV2ReturnBitfield10 = << >> THEN << >> ELSE EncodeUIntLE(message.orderAcknowledgmentV2ReturnBitfield10[1], 1))
        \o (IF message.orderAcknowledgmentV2ReturnBitfield11 = << >> THEN << >> ELSE EncodeUIntLE(message.orderAcknowledgmentV2ReturnBitfield11[1], 1))
        \o (IF message.orderAcknowledgmentV2ReturnBitfield12 = << >> THEN << >> ELSE message.orderAcknowledgmentV2ReturnBitfield12[1])
        \o (IF message.orderAcknowledgmentV2ReturnBitfield13 = << >> THEN << >> ELSE message.orderAcknowledgmentV2ReturnBitfield13[1])
        \o (IF message.orderAcknowledgmentV2ReturnBitfield14 = << >> THEN << >> ELSE message.orderAcknowledgmentV2ReturnBitfield14[1])
        \o (IF message.side = << >> THEN << >> ELSE message.side[1])
        \o (IF message.pegDifference = << >> THEN << >> ELSE message.pegDifference[1])
        \o (IF message.price = << >> THEN << >> ELSE message.price[1])
        \o (IF message.execInst = << >> THEN << >> ELSE message.execInst[1])
        \o (IF message.ordType = << >> THEN << >> ELSE message.ordType[1])
        \o (IF message.timeInForce = << >> THEN << >> ELSE message.timeInForce[1])
        \o (IF message.minQty = << >> THEN << >> ELSE message.minQty[1])
        \o (IF message.symbol = << >> THEN << >> ELSE message.symbol[1])
        \o (IF message.currency = << >> THEN << >> ELSE message.currency[1])
        \o (IF message.idSource = << >> THEN << >> ELSE message.idSource[1])
        \o (IF message.securityId = << >> THEN << >> ELSE message.securityId[1])
        \o (IF message.securityExchange = << >> THEN << >> ELSE message.securityExchange[1])
        \o (IF message.capacity = << >> THEN << >> ELSE message.capacity[1])
        \o (IF message.account = << >> THEN << >> ELSE message.account[1])
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])
        \o (IF message.clearingAccount = << >> THEN << >> ELSE message.clearingAccount[1])
        \o (IF message.displayIndicator = << >> THEN << >> ELSE message.displayIndicator[1])
        \o (IF message.maxFloor = << >> THEN << >> ELSE message.maxFloor[1])
        \o (IF message.orderQty = << >> THEN << >> ELSE message.orderQty[1])
        \o (IF message.preventParticipantMatch = << >> THEN << >> ELSE message.preventParticipantMatch[1])
        \o (IF message.origClOrdId = << >> THEN << >> ELSE message.origClOrdId[1])
        \o (IF message.leavesQty = << >> THEN << >> ELSE message.leavesQty[1])
        \o (IF message.lastShares = << >> THEN << >> ELSE message.lastShares[1])
        \o (IF message.lastPx = << >> THEN << >> ELSE message.lastPx[1])
        \o (IF message.displayPrice = << >> THEN << >> ELSE message.displayPrice[1])
        \o (IF message.workingPrice = << >> THEN << >> ELSE message.workingPrice[1])
        \o (IF message.baseLiquidityIndicator = << >> THEN << >> ELSE message.baseLiquidityIndicator[1])
        \o (IF message.expireTime = << >> THEN << >> ELSE message.expireTime[1])
        \o (IF message.secondaryOrderId = << >> THEN << >> ELSE message.secondaryOrderId[1])
        \o (IF message.liquidityProvision = << >> THEN << >> ELSE message.liquidityProvision[1])
        \o (IF message.waiverType = << >> THEN << >> ELSE message.waiverType[1])
        \o (IF message.priceFormation = << >> THEN << >> ELSE message.priceFormation[1])
        \o (IF message.clientQualifiedRole = << >> THEN << >> ELSE message.clientQualifiedRole[1])
        \o (IF message.clientId = << >> THEN << >> ELSE message.clientId[1])
        \o (IF message.investorId = << >> THEN << >> ELSE message.investorId[1])
        \o (IF message.executorId = << >> THEN << >> ELSE message.executorId[1])
        \o (IF message.orderOrigination = << >> THEN << >> ELSE message.orderOrigination[1])
        \o (IF message.algorithmicIndicator = << >> THEN << >> ELSE message.algorithmicIndicator[1])
        \o (IF message.deferralReason = << >> THEN << >> ELSE message.deferralReason[1])
        \o (IF message.investorQualifiedRole = << >> THEN << >> ELSE message.investorQualifiedRole[1])
        \o (IF message.executorQualifiedRole = << >> THEN << >> ELSE message.executorQualifiedRole[1])

DecodeOrderAcknowledgmentV2Message(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clOrdId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(orderId.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET numberOfReturnBitfields == ReadUIntBE(reserved1.rest, 1) IN IF ~numberOfReturnBitfields.ok THEN Fail ELSE
    LET orderAcknowledgmentV2ReturnBitfield1 == ReadWhen(numberOfReturnBitfields.value >= 1, ReadUIntLE(numberOfReturnBitfields.rest, 1), numberOfReturnBitfields.rest) IN IF ~orderAcknowledgmentV2ReturnBitfield1.ok THEN Fail ELSE
    LET orderAcknowledgmentV2ReturnBitfield2 == ReadWhen(numberOfReturnBitfields.value >= 2, ReadUIntLE(orderAcknowledgmentV2ReturnBitfield1.rest, 1), orderAcknowledgmentV2ReturnBitfield1.rest) IN IF ~orderAcknowledgmentV2ReturnBitfield2.ok THEN Fail ELSE
    LET orderAcknowledgmentV2ReturnBitfield3 == ReadWhen(numberOfReturnBitfields.value >= 3, ReadUIntLE(orderAcknowledgmentV2ReturnBitfield2.rest, 1), orderAcknowledgmentV2ReturnBitfield2.rest) IN IF ~orderAcknowledgmentV2ReturnBitfield3.ok THEN Fail ELSE
    LET orderAcknowledgmentV2ReturnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadBytes(orderAcknowledgmentV2ReturnBitfield3.rest, 1), orderAcknowledgmentV2ReturnBitfield3.rest) IN IF ~orderAcknowledgmentV2ReturnBitfield4.ok THEN Fail ELSE
    LET orderAcknowledgmentV2ReturnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadUIntLE(orderAcknowledgmentV2ReturnBitfield4.rest, 1), orderAcknowledgmentV2ReturnBitfield4.rest) IN IF ~orderAcknowledgmentV2ReturnBitfield5.ok THEN Fail ELSE
    LET orderAcknowledgmentV2ReturnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadUIntLE(orderAcknowledgmentV2ReturnBitfield5.rest, 1), orderAcknowledgmentV2ReturnBitfield5.rest) IN IF ~orderAcknowledgmentV2ReturnBitfield6.ok THEN Fail ELSE
    LET orderAcknowledgmentV2ReturnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadBytes(orderAcknowledgmentV2ReturnBitfield6.rest, 1), orderAcknowledgmentV2ReturnBitfield6.rest) IN IF ~orderAcknowledgmentV2ReturnBitfield7.ok THEN Fail ELSE
    LET orderAcknowledgmentV2ReturnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadBytes(orderAcknowledgmentV2ReturnBitfield7.rest, 1), orderAcknowledgmentV2ReturnBitfield7.rest) IN IF ~orderAcknowledgmentV2ReturnBitfield8.ok THEN Fail ELSE
    LET orderAcknowledgmentV2ReturnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadUIntLE(orderAcknowledgmentV2ReturnBitfield8.rest, 1), orderAcknowledgmentV2ReturnBitfield8.rest) IN IF ~orderAcknowledgmentV2ReturnBitfield9.ok THEN Fail ELSE
    LET orderAcknowledgmentV2ReturnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadUIntLE(orderAcknowledgmentV2ReturnBitfield9.rest, 1), orderAcknowledgmentV2ReturnBitfield9.rest) IN IF ~orderAcknowledgmentV2ReturnBitfield10.ok THEN Fail ELSE
    LET orderAcknowledgmentV2ReturnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadUIntLE(orderAcknowledgmentV2ReturnBitfield10.rest, 1), orderAcknowledgmentV2ReturnBitfield10.rest) IN IF ~orderAcknowledgmentV2ReturnBitfield11.ok THEN Fail ELSE
    LET orderAcknowledgmentV2ReturnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadBytes(orderAcknowledgmentV2ReturnBitfield11.rest, 1), orderAcknowledgmentV2ReturnBitfield11.rest) IN IF ~orderAcknowledgmentV2ReturnBitfield12.ok THEN Fail ELSE
    LET orderAcknowledgmentV2ReturnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(orderAcknowledgmentV2ReturnBitfield12.rest, 1), orderAcknowledgmentV2ReturnBitfield12.rest) IN IF ~orderAcknowledgmentV2ReturnBitfield13.ok THEN Fail ELSE
    LET orderAcknowledgmentV2ReturnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(orderAcknowledgmentV2ReturnBitfield13.rest, 1), orderAcknowledgmentV2ReturnBitfield13.rest) IN IF ~orderAcknowledgmentV2ReturnBitfield14.ok THEN Fail ELSE
    LET side == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderAcknowledgmentV2ReturnBitfield1.value # << >> /\ orderAcknowledgmentV2ReturnBitfield1.value[1] % 2 > 0), ReadBytes(orderAcknowledgmentV2ReturnBitfield14.rest, 1), orderAcknowledgmentV2ReturnBitfield14.rest) IN IF ~side.ok THEN Fail ELSE
    LET pegDifference == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderAcknowledgmentV2ReturnBitfield1.value # << >> /\ (orderAcknowledgmentV2ReturnBitfield1.value[1] \div 2) % 2 > 0), ReadBytes(side.rest, 8), side.rest) IN IF ~pegDifference.ok THEN Fail ELSE
    LET price == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderAcknowledgmentV2ReturnBitfield1.value # << >> /\ (orderAcknowledgmentV2ReturnBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(pegDifference.rest, 8), pegDifference.rest) IN IF ~price.ok THEN Fail ELSE
    LET execInst == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderAcknowledgmentV2ReturnBitfield1.value # << >> /\ (orderAcknowledgmentV2ReturnBitfield1.value[1] \div 8) % 2 > 0), ReadBytes(price.rest, 1), price.rest) IN IF ~execInst.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderAcknowledgmentV2ReturnBitfield1.value # << >> /\ (orderAcknowledgmentV2ReturnBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(execInst.rest, 1), execInst.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderAcknowledgmentV2ReturnBitfield1.value # << >> /\ (orderAcknowledgmentV2ReturnBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderAcknowledgmentV2ReturnBitfield1.value # << >> /\ (orderAcknowledgmentV2ReturnBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET symbol == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderAcknowledgmentV2ReturnBitfield2.value # << >> /\ orderAcknowledgmentV2ReturnBitfield2.value[1] % 2 > 0), ReadBytes(minQty.rest, 8), minQty.rest) IN IF ~symbol.ok THEN Fail ELSE
    LET currency == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderAcknowledgmentV2ReturnBitfield2.value # << >> /\ (orderAcknowledgmentV2ReturnBitfield2.value[1] \div 4) % 2 > 0), ReadBytes(symbol.rest, 3), symbol.rest) IN IF ~currency.ok THEN Fail ELSE
    LET idSource == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderAcknowledgmentV2ReturnBitfield2.value # << >> /\ (orderAcknowledgmentV2ReturnBitfield2.value[1] \div 8) % 2 > 0), ReadBytes(currency.rest, 1), currency.rest) IN IF ~idSource.ok THEN Fail ELSE
    LET securityId == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderAcknowledgmentV2ReturnBitfield2.value # << >> /\ (orderAcknowledgmentV2ReturnBitfield2.value[1] \div 16) % 2 > 0), ReadBytes(idSource.rest, 16), idSource.rest) IN IF ~securityId.ok THEN Fail ELSE
    LET securityExchange == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderAcknowledgmentV2ReturnBitfield2.value # << >> /\ (orderAcknowledgmentV2ReturnBitfield2.value[1] \div 32) % 2 > 0), ReadBytes(securityId.rest, 4), securityId.rest) IN IF ~securityExchange.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderAcknowledgmentV2ReturnBitfield2.value # << >> /\ (orderAcknowledgmentV2ReturnBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(securityExchange.rest, 1), securityExchange.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderAcknowledgmentV2ReturnBitfield3.value # << >> /\ orderAcknowledgmentV2ReturnBitfield3.value[1] % 2 > 0), ReadBytes(capacity.rest, 16), capacity.rest) IN IF ~account.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderAcknowledgmentV2ReturnBitfield3.value # << >> /\ (orderAcknowledgmentV2ReturnBitfield3.value[1] \div 2) % 2 > 0), ReadBytes(account.rest, 4), account.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderAcknowledgmentV2ReturnBitfield3.value # << >> /\ (orderAcknowledgmentV2ReturnBitfield3.value[1] \div 4) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET displayIndicator == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderAcknowledgmentV2ReturnBitfield3.value # << >> /\ (orderAcknowledgmentV2ReturnBitfield3.value[1] \div 8) % 2 > 0), ReadBytes(clearingAccount.rest, 1), clearingAccount.rest) IN IF ~displayIndicator.ok THEN Fail ELSE
    LET maxFloor == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderAcknowledgmentV2ReturnBitfield3.value # << >> /\ (orderAcknowledgmentV2ReturnBitfield3.value[1] \div 16) % 2 > 0), ReadBytes(displayIndicator.rest, 4), displayIndicator.rest) IN IF ~maxFloor.ok THEN Fail ELSE
    LET orderQty == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderAcknowledgmentV2ReturnBitfield3.value # << >> /\ (orderAcknowledgmentV2ReturnBitfield3.value[1] \div 64) % 2 > 0), ReadBytes(maxFloor.rest, 4), maxFloor.rest) IN IF ~orderQty.ok THEN Fail ELSE
    LET preventParticipantMatch == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderAcknowledgmentV2ReturnBitfield3.value # << >> /\ (orderAcknowledgmentV2ReturnBitfield3.value[1] \div 128) % 2 > 0), ReadBytes(orderQty.rest, 3), orderQty.rest) IN IF ~preventParticipantMatch.ok THEN Fail ELSE
    LET origClOrdId == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderAcknowledgmentV2ReturnBitfield5.value # << >> /\ orderAcknowledgmentV2ReturnBitfield5.value[1] % 2 > 0), ReadBytes(preventParticipantMatch.rest, 20), preventParticipantMatch.rest) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET leavesQty == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderAcknowledgmentV2ReturnBitfield5.value # << >> /\ (orderAcknowledgmentV2ReturnBitfield5.value[1] \div 2) % 2 > 0), ReadBytes(origClOrdId.rest, 4), origClOrdId.rest) IN IF ~leavesQty.ok THEN Fail ELSE
    LET lastShares == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderAcknowledgmentV2ReturnBitfield5.value # << >> /\ (orderAcknowledgmentV2ReturnBitfield5.value[1] \div 4) % 2 > 0), ReadBytes(leavesQty.rest, 4), leavesQty.rest) IN IF ~lastShares.ok THEN Fail ELSE
    LET lastPx == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderAcknowledgmentV2ReturnBitfield5.value # << >> /\ (orderAcknowledgmentV2ReturnBitfield5.value[1] \div 8) % 2 > 0), ReadBytes(lastShares.rest, 8), lastShares.rest) IN IF ~lastPx.ok THEN Fail ELSE
    LET displayPrice == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderAcknowledgmentV2ReturnBitfield5.value # << >> /\ (orderAcknowledgmentV2ReturnBitfield5.value[1] \div 16) % 2 > 0), ReadBytes(lastPx.rest, 8), lastPx.rest) IN IF ~displayPrice.ok THEN Fail ELSE
    LET workingPrice == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderAcknowledgmentV2ReturnBitfield5.value # << >> /\ (orderAcknowledgmentV2ReturnBitfield5.value[1] \div 32) % 2 > 0), ReadBytes(displayPrice.rest, 8), displayPrice.rest) IN IF ~workingPrice.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderAcknowledgmentV2ReturnBitfield5.value # << >> /\ (orderAcknowledgmentV2ReturnBitfield5.value[1] \div 64) % 2 > 0), ReadBytes(workingPrice.rest, 1), workingPrice.rest) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET expireTime == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderAcknowledgmentV2ReturnBitfield5.value # << >> /\ (orderAcknowledgmentV2ReturnBitfield5.value[1] \div 128) % 2 > 0), ReadBytes(baseLiquidityIndicator.rest, 8), baseLiquidityIndicator.rest) IN IF ~expireTime.ok THEN Fail ELSE
    LET secondaryOrderId == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (orderAcknowledgmentV2ReturnBitfield6.value # << >> /\ orderAcknowledgmentV2ReturnBitfield6.value[1] % 2 > 0), ReadBytes(expireTime.rest, 8), expireTime.rest) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET liquidityProvision == ReadWhen(numberOfReturnBitfields.value >= 9 /\ (orderAcknowledgmentV2ReturnBitfield9.value # << >> /\ (orderAcknowledgmentV2ReturnBitfield9.value[1] \div 16) % 2 > 0), ReadBytes(secondaryOrderId.rest, 1), secondaryOrderId.rest) IN IF ~liquidityProvision.ok THEN Fail ELSE
    LET waiverType == ReadWhen(numberOfReturnBitfields.value >= 10 /\ (orderAcknowledgmentV2ReturnBitfield10.value # << >> /\ (orderAcknowledgmentV2ReturnBitfield10.value[1] \div 16) % 2 > 0), ReadBytes(liquidityProvision.rest, 1), liquidityProvision.rest) IN IF ~waiverType.ok THEN Fail ELSE
    LET priceFormation == ReadWhen(numberOfReturnBitfields.value >= 10 /\ (orderAcknowledgmentV2ReturnBitfield10.value # << >> /\ (orderAcknowledgmentV2ReturnBitfield10.value[1] \div 64) % 2 > 0), ReadBytes(waiverType.rest, 1), waiverType.rest) IN IF ~priceFormation.ok THEN Fail ELSE
    LET clientQualifiedRole == ReadWhen(numberOfReturnBitfields.value >= 10 /\ (orderAcknowledgmentV2ReturnBitfield10.value # << >> /\ (orderAcknowledgmentV2ReturnBitfield10.value[1] \div 128) % 2 > 0), ReadBytes(priceFormation.rest, 1), priceFormation.rest) IN IF ~clientQualifiedRole.ok THEN Fail ELSE
    LET clientId == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (orderAcknowledgmentV2ReturnBitfield11.value # << >> /\ orderAcknowledgmentV2ReturnBitfield11.value[1] % 2 > 0), ReadBytes(clientQualifiedRole.rest, 4), clientQualifiedRole.rest) IN IF ~clientId.ok THEN Fail ELSE
    LET investorId == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (orderAcknowledgmentV2ReturnBitfield11.value # << >> /\ (orderAcknowledgmentV2ReturnBitfield11.value[1] \div 2) % 2 > 0), ReadBytes(clientId.rest, 4), clientId.rest) IN IF ~investorId.ok THEN Fail ELSE
    LET executorId == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (orderAcknowledgmentV2ReturnBitfield11.value # << >> /\ (orderAcknowledgmentV2ReturnBitfield11.value[1] \div 4) % 2 > 0), ReadBytes(investorId.rest, 4), investorId.rest) IN IF ~executorId.ok THEN Fail ELSE
    LET orderOrigination == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (orderAcknowledgmentV2ReturnBitfield11.value # << >> /\ (orderAcknowledgmentV2ReturnBitfield11.value[1] \div 8) % 2 > 0), ReadBytes(executorId.rest, 1), executorId.rest) IN IF ~orderOrigination.ok THEN Fail ELSE
    LET algorithmicIndicator == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (orderAcknowledgmentV2ReturnBitfield11.value # << >> /\ (orderAcknowledgmentV2ReturnBitfield11.value[1] \div 16) % 2 > 0), ReadBytes(orderOrigination.rest, 1), orderOrigination.rest) IN IF ~algorithmicIndicator.ok THEN Fail ELSE
    LET deferralReason == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (orderAcknowledgmentV2ReturnBitfield11.value # << >> /\ (orderAcknowledgmentV2ReturnBitfield11.value[1] \div 32) % 2 > 0), ReadBytes(algorithmicIndicator.rest, 1), algorithmicIndicator.rest) IN IF ~deferralReason.ok THEN Fail ELSE
    LET investorQualifiedRole == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (orderAcknowledgmentV2ReturnBitfield11.value # << >> /\ (orderAcknowledgmentV2ReturnBitfield11.value[1] \div 64) % 2 > 0), ReadBytes(deferralReason.rest, 1), deferralReason.rest) IN IF ~investorQualifiedRole.ok THEN Fail ELSE
    LET executorQualifiedRole == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (orderAcknowledgmentV2ReturnBitfield11.value # << >> /\ (orderAcknowledgmentV2ReturnBitfield11.value[1] \div 128) % 2 > 0), ReadBytes(investorQualifiedRole.rest, 1), investorQualifiedRole.rest) IN IF ~executorQualifiedRole.ok THEN Fail ELSE
    Ok([ transactionTime                       |-> transactionTime.value,
         clOrdId                               |-> clOrdId.value,
         orderId                               |-> orderId.value,
         reserved1                             |-> reserved1.value,
         numberOfReturnBitfields               |-> numberOfReturnBitfields.value,
         orderAcknowledgmentV2ReturnBitfield1  |-> orderAcknowledgmentV2ReturnBitfield1.value,
         orderAcknowledgmentV2ReturnBitfield2  |-> orderAcknowledgmentV2ReturnBitfield2.value,
         orderAcknowledgmentV2ReturnBitfield3  |-> orderAcknowledgmentV2ReturnBitfield3.value,
         orderAcknowledgmentV2ReturnBitfield4  |-> orderAcknowledgmentV2ReturnBitfield4.value,
         orderAcknowledgmentV2ReturnBitfield5  |-> orderAcknowledgmentV2ReturnBitfield5.value,
         orderAcknowledgmentV2ReturnBitfield6  |-> orderAcknowledgmentV2ReturnBitfield6.value,
         orderAcknowledgmentV2ReturnBitfield7  |-> orderAcknowledgmentV2ReturnBitfield7.value,
         orderAcknowledgmentV2ReturnBitfield8  |-> orderAcknowledgmentV2ReturnBitfield8.value,
         orderAcknowledgmentV2ReturnBitfield9  |-> orderAcknowledgmentV2ReturnBitfield9.value,
         orderAcknowledgmentV2ReturnBitfield10 |-> orderAcknowledgmentV2ReturnBitfield10.value,
         orderAcknowledgmentV2ReturnBitfield11 |-> orderAcknowledgmentV2ReturnBitfield11.value,
         orderAcknowledgmentV2ReturnBitfield12 |-> orderAcknowledgmentV2ReturnBitfield12.value,
         orderAcknowledgmentV2ReturnBitfield13 |-> orderAcknowledgmentV2ReturnBitfield13.value,
         orderAcknowledgmentV2ReturnBitfield14 |-> orderAcknowledgmentV2ReturnBitfield14.value,
         side                                  |-> side.value,
         pegDifference                         |-> pegDifference.value,
         price                                 |-> price.value,
         execInst                              |-> execInst.value,
         ordType                               |-> ordType.value,
         timeInForce                           |-> timeInForce.value,
         minQty                                |-> minQty.value,
         symbol                                |-> symbol.value,
         currency                              |-> currency.value,
         idSource                              |-> idSource.value,
         securityId                            |-> securityId.value,
         securityExchange                      |-> securityExchange.value,
         capacity                              |-> capacity.value,
         account                               |-> account.value,
         clearingFirm                          |-> clearingFirm.value,
         clearingAccount                       |-> clearingAccount.value,
         displayIndicator                      |-> displayIndicator.value,
         maxFloor                              |-> maxFloor.value,
         orderQty                              |-> orderQty.value,
         preventParticipantMatch               |-> preventParticipantMatch.value,
         origClOrdId                           |-> origClOrdId.value,
         leavesQty                             |-> leavesQty.value,
         lastShares                            |-> lastShares.value,
         lastPx                                |-> lastPx.value,
         displayPrice                          |-> displayPrice.value,
         workingPrice                          |-> workingPrice.value,
         baseLiquidityIndicator                |-> baseLiquidityIndicator.value,
         expireTime                            |-> expireTime.value,
         secondaryOrderId                      |-> secondaryOrderId.value,
         liquidityProvision                    |-> liquidityProvision.value,
         waiverType                            |-> waiverType.value,
         priceFormation                        |-> priceFormation.value,
         clientQualifiedRole                   |-> clientQualifiedRole.value,
         clientId                              |-> clientId.value,
         investorId                            |-> investorId.value,
         executorId                            |-> executorId.value,
         orderOrigination                      |-> orderOrigination.value,
         algorithmicIndicator                  |-> algorithmicIndicator.value,
         deferralReason                        |-> deferralReason.value,
         investorQualifiedRole                 |-> investorQualifiedRole.value,
         executorQualifiedRole                 |-> executorQualifiedRole.value ], executorQualifiedRole.rest)

(* Order Acknowledgment V 2 Message with each field marked present by fields before it there exactly where they say *)
SettleOrderAcknowledgmentV2Message(message) ==
    LET settled1 == [message EXCEPT !.orderAcknowledgmentV2ReturnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.orderAcknowledgmentV2ReturnBitfield1 = << >> THEN <<0>> ELSE message.orderAcknowledgmentV2ReturnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.orderAcknowledgmentV2ReturnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.orderAcknowledgmentV2ReturnBitfield2 = << >> THEN <<0>> ELSE settled1.orderAcknowledgmentV2ReturnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.orderAcknowledgmentV2ReturnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.orderAcknowledgmentV2ReturnBitfield3 = << >> THEN <<0>> ELSE settled2.orderAcknowledgmentV2ReturnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.orderAcknowledgmentV2ReturnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.orderAcknowledgmentV2ReturnBitfield4 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled3.orderAcknowledgmentV2ReturnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.orderAcknowledgmentV2ReturnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.orderAcknowledgmentV2ReturnBitfield5 = << >> THEN <<0>> ELSE settled4.orderAcknowledgmentV2ReturnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.orderAcknowledgmentV2ReturnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.orderAcknowledgmentV2ReturnBitfield6 = << >> THEN <<0>> ELSE settled5.orderAcknowledgmentV2ReturnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.orderAcknowledgmentV2ReturnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.orderAcknowledgmentV2ReturnBitfield7 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.orderAcknowledgmentV2ReturnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.orderAcknowledgmentV2ReturnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.orderAcknowledgmentV2ReturnBitfield8 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled7.orderAcknowledgmentV2ReturnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.orderAcknowledgmentV2ReturnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.orderAcknowledgmentV2ReturnBitfield9 = << >> THEN <<0>> ELSE settled8.orderAcknowledgmentV2ReturnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.orderAcknowledgmentV2ReturnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.orderAcknowledgmentV2ReturnBitfield10 = << >> THEN <<0>> ELSE settled9.orderAcknowledgmentV2ReturnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.orderAcknowledgmentV2ReturnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.orderAcknowledgmentV2ReturnBitfield11 = << >> THEN <<0>> ELSE settled10.orderAcknowledgmentV2ReturnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.orderAcknowledgmentV2ReturnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.orderAcknowledgmentV2ReturnBitfield12 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.orderAcknowledgmentV2ReturnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.orderAcknowledgmentV2ReturnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.orderAcknowledgmentV2ReturnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.orderAcknowledgmentV2ReturnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.orderAcknowledgmentV2ReturnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.orderAcknowledgmentV2ReturnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.orderAcknowledgmentV2ReturnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.side = IF settled14.numberOfReturnBitfields >= 1 /\ (settled14.orderAcknowledgmentV2ReturnBitfield1 # << >> /\ settled14.orderAcknowledgmentV2ReturnBitfield1[1] % 2 > 0) THEN (IF settled14.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.side) ELSE << >>]
        settled16 == [settled15 EXCEPT !.pegDifference = IF settled15.numberOfReturnBitfields >= 1 /\ (settled15.orderAcknowledgmentV2ReturnBitfield1 # << >> /\ (settled15.orderAcknowledgmentV2ReturnBitfield1[1] \div 2) % 2 > 0) THEN (IF settled15.pegDifference = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled15.pegDifference) ELSE << >>]
        settled17 == [settled16 EXCEPT !.price = IF settled16.numberOfReturnBitfields >= 1 /\ (settled16.orderAcknowledgmentV2ReturnBitfield1 # << >> /\ (settled16.orderAcknowledgmentV2ReturnBitfield1[1] \div 4) % 2 > 0) THEN (IF settled16.price = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled16.price) ELSE << >>]
        settled18 == [settled17 EXCEPT !.execInst = IF settled17.numberOfReturnBitfields >= 1 /\ (settled17.orderAcknowledgmentV2ReturnBitfield1 # << >> /\ (settled17.orderAcknowledgmentV2ReturnBitfield1[1] \div 8) % 2 > 0) THEN (IF settled17.execInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.execInst) ELSE << >>]
        settled19 == [settled18 EXCEPT !.ordType = IF settled18.numberOfReturnBitfields >= 1 /\ (settled18.orderAcknowledgmentV2ReturnBitfield1 # << >> /\ (settled18.orderAcknowledgmentV2ReturnBitfield1[1] \div 16) % 2 > 0) THEN (IF settled18.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled18.ordType) ELSE << >>]
        settled20 == [settled19 EXCEPT !.timeInForce = IF settled19.numberOfReturnBitfields >= 1 /\ (settled19.orderAcknowledgmentV2ReturnBitfield1 # << >> /\ (settled19.orderAcknowledgmentV2ReturnBitfield1[1] \div 32) % 2 > 0) THEN (IF settled19.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled19.timeInForce) ELSE << >>]
        settled21 == [settled20 EXCEPT !.minQty = IF settled20.numberOfReturnBitfields >= 1 /\ (settled20.orderAcknowledgmentV2ReturnBitfield1 # << >> /\ (settled20.orderAcknowledgmentV2ReturnBitfield1[1] \div 64) % 2 > 0) THEN (IF settled20.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled20.minQty) ELSE << >>]
        settled22 == [settled21 EXCEPT !.symbol = IF settled21.numberOfReturnBitfields >= 2 /\ (settled21.orderAcknowledgmentV2ReturnBitfield2 # << >> /\ settled21.orderAcknowledgmentV2ReturnBitfield2[1] % 2 > 0) THEN (IF settled21.symbol = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled21.symbol) ELSE << >>]
        settled23 == [settled22 EXCEPT !.currency = IF settled22.numberOfReturnBitfields >= 2 /\ (settled22.orderAcknowledgmentV2ReturnBitfield2 # << >> /\ (settled22.orderAcknowledgmentV2ReturnBitfield2[1] \div 4) % 2 > 0) THEN (IF settled22.currency = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled22.currency) ELSE << >>]
        settled24 == [settled23 EXCEPT !.idSource = IF settled23.numberOfReturnBitfields >= 2 /\ (settled23.orderAcknowledgmentV2ReturnBitfield2 # << >> /\ (settled23.orderAcknowledgmentV2ReturnBitfield2[1] \div 8) % 2 > 0) THEN (IF settled23.idSource = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled23.idSource) ELSE << >>]
        settled25 == [settled24 EXCEPT !.securityId = IF settled24.numberOfReturnBitfields >= 2 /\ (settled24.orderAcknowledgmentV2ReturnBitfield2 # << >> /\ (settled24.orderAcknowledgmentV2ReturnBitfield2[1] \div 16) % 2 > 0) THEN (IF settled24.securityId = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled24.securityId) ELSE << >>]
        settled26 == [settled25 EXCEPT !.securityExchange = IF settled25.numberOfReturnBitfields >= 2 /\ (settled25.orderAcknowledgmentV2ReturnBitfield2 # << >> /\ (settled25.orderAcknowledgmentV2ReturnBitfield2[1] \div 32) % 2 > 0) THEN (IF settled25.securityExchange = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled25.securityExchange) ELSE << >>]
        settled27 == [settled26 EXCEPT !.capacity = IF settled26.numberOfReturnBitfields >= 2 /\ (settled26.orderAcknowledgmentV2ReturnBitfield2 # << >> /\ (settled26.orderAcknowledgmentV2ReturnBitfield2[1] \div 64) % 2 > 0) THEN (IF settled26.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled26.capacity) ELSE << >>]
        settled28 == [settled27 EXCEPT !.account = IF settled27.numberOfReturnBitfields >= 3 /\ (settled27.orderAcknowledgmentV2ReturnBitfield3 # << >> /\ settled27.orderAcknowledgmentV2ReturnBitfield3[1] % 2 > 0) THEN (IF settled27.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled27.account) ELSE << >>]
        settled29 == [settled28 EXCEPT !.clearingFirm = IF settled28.numberOfReturnBitfields >= 3 /\ (settled28.orderAcknowledgmentV2ReturnBitfield3 # << >> /\ (settled28.orderAcknowledgmentV2ReturnBitfield3[1] \div 2) % 2 > 0) THEN (IF settled28.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled28.clearingFirm) ELSE << >>]
        settled30 == [settled29 EXCEPT !.clearingAccount = IF settled29.numberOfReturnBitfields >= 3 /\ (settled29.orderAcknowledgmentV2ReturnBitfield3 # << >> /\ (settled29.orderAcknowledgmentV2ReturnBitfield3[1] \div 4) % 2 > 0) THEN (IF settled29.clearingAccount = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled29.clearingAccount) ELSE << >>]
        settled31 == [settled30 EXCEPT !.displayIndicator = IF settled30.numberOfReturnBitfields >= 3 /\ (settled30.orderAcknowledgmentV2ReturnBitfield3 # << >> /\ (settled30.orderAcknowledgmentV2ReturnBitfield3[1] \div 8) % 2 > 0) THEN (IF settled30.displayIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled30.displayIndicator) ELSE << >>]
        settled32 == [settled31 EXCEPT !.maxFloor = IF settled31.numberOfReturnBitfields >= 3 /\ (settled31.orderAcknowledgmentV2ReturnBitfield3 # << >> /\ (settled31.orderAcknowledgmentV2ReturnBitfield3[1] \div 16) % 2 > 0) THEN (IF settled31.maxFloor = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled31.maxFloor) ELSE << >>]
        settled33 == [settled32 EXCEPT !.orderQty = IF settled32.numberOfReturnBitfields >= 3 /\ (settled32.orderAcknowledgmentV2ReturnBitfield3 # << >> /\ (settled32.orderAcknowledgmentV2ReturnBitfield3[1] \div 64) % 2 > 0) THEN (IF settled32.orderQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled32.orderQty) ELSE << >>]
        settled34 == [settled33 EXCEPT !.preventParticipantMatch = IF settled33.numberOfReturnBitfields >= 3 /\ (settled33.orderAcknowledgmentV2ReturnBitfield3 # << >> /\ (settled33.orderAcknowledgmentV2ReturnBitfield3[1] \div 128) % 2 > 0) THEN (IF settled33.preventParticipantMatch = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled33.preventParticipantMatch) ELSE << >>]
        settled35 == [settled34 EXCEPT !.origClOrdId = IF settled34.numberOfReturnBitfields >= 5 /\ (settled34.orderAcknowledgmentV2ReturnBitfield5 # << >> /\ settled34.orderAcknowledgmentV2ReturnBitfield5[1] % 2 > 0) THEN (IF settled34.origClOrdId = << >> THEN <<[i \in 1 .. 20 |-> 0]>> ELSE settled34.origClOrdId) ELSE << >>]
        settled36 == [settled35 EXCEPT !.leavesQty = IF settled35.numberOfReturnBitfields >= 5 /\ (settled35.orderAcknowledgmentV2ReturnBitfield5 # << >> /\ (settled35.orderAcknowledgmentV2ReturnBitfield5[1] \div 2) % 2 > 0) THEN (IF settled35.leavesQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled35.leavesQty) ELSE << >>]
        settled37 == [settled36 EXCEPT !.lastShares = IF settled36.numberOfReturnBitfields >= 5 /\ (settled36.orderAcknowledgmentV2ReturnBitfield5 # << >> /\ (settled36.orderAcknowledgmentV2ReturnBitfield5[1] \div 4) % 2 > 0) THEN (IF settled36.lastShares = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled36.lastShares) ELSE << >>]
        settled38 == [settled37 EXCEPT !.lastPx = IF settled37.numberOfReturnBitfields >= 5 /\ (settled37.orderAcknowledgmentV2ReturnBitfield5 # << >> /\ (settled37.orderAcknowledgmentV2ReturnBitfield5[1] \div 8) % 2 > 0) THEN (IF settled37.lastPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled37.lastPx) ELSE << >>]
        settled39 == [settled38 EXCEPT !.displayPrice = IF settled38.numberOfReturnBitfields >= 5 /\ (settled38.orderAcknowledgmentV2ReturnBitfield5 # << >> /\ (settled38.orderAcknowledgmentV2ReturnBitfield5[1] \div 16) % 2 > 0) THEN (IF settled38.displayPrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled38.displayPrice) ELSE << >>]
        settled40 == [settled39 EXCEPT !.workingPrice = IF settled39.numberOfReturnBitfields >= 5 /\ (settled39.orderAcknowledgmentV2ReturnBitfield5 # << >> /\ (settled39.orderAcknowledgmentV2ReturnBitfield5[1] \div 32) % 2 > 0) THEN (IF settled39.workingPrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled39.workingPrice) ELSE << >>]
        settled41 == [settled40 EXCEPT !.baseLiquidityIndicator = IF settled40.numberOfReturnBitfields >= 5 /\ (settled40.orderAcknowledgmentV2ReturnBitfield5 # << >> /\ (settled40.orderAcknowledgmentV2ReturnBitfield5[1] \div 64) % 2 > 0) THEN (IF settled40.baseLiquidityIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled40.baseLiquidityIndicator) ELSE << >>]
        settled42 == [settled41 EXCEPT !.expireTime = IF settled41.numberOfReturnBitfields >= 5 /\ (settled41.orderAcknowledgmentV2ReturnBitfield5 # << >> /\ (settled41.orderAcknowledgmentV2ReturnBitfield5[1] \div 128) % 2 > 0) THEN (IF settled41.expireTime = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled41.expireTime) ELSE << >>]
        settled43 == [settled42 EXCEPT !.secondaryOrderId = IF settled42.numberOfReturnBitfields >= 6 /\ (settled42.orderAcknowledgmentV2ReturnBitfield6 # << >> /\ settled42.orderAcknowledgmentV2ReturnBitfield6[1] % 2 > 0) THEN (IF settled42.secondaryOrderId = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled42.secondaryOrderId) ELSE << >>]
        settled44 == [settled43 EXCEPT !.liquidityProvision = IF settled43.numberOfReturnBitfields >= 9 /\ (settled43.orderAcknowledgmentV2ReturnBitfield9 # << >> /\ (settled43.orderAcknowledgmentV2ReturnBitfield9[1] \div 16) % 2 > 0) THEN (IF settled43.liquidityProvision = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled43.liquidityProvision) ELSE << >>]
        settled45 == [settled44 EXCEPT !.waiverType = IF settled44.numberOfReturnBitfields >= 10 /\ (settled44.orderAcknowledgmentV2ReturnBitfield10 # << >> /\ (settled44.orderAcknowledgmentV2ReturnBitfield10[1] \div 16) % 2 > 0) THEN (IF settled44.waiverType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled44.waiverType) ELSE << >>]
        settled46 == [settled45 EXCEPT !.priceFormation = IF settled45.numberOfReturnBitfields >= 10 /\ (settled45.orderAcknowledgmentV2ReturnBitfield10 # << >> /\ (settled45.orderAcknowledgmentV2ReturnBitfield10[1] \div 64) % 2 > 0) THEN (IF settled45.priceFormation = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled45.priceFormation) ELSE << >>]
        settled47 == [settled46 EXCEPT !.clientQualifiedRole = IF settled46.numberOfReturnBitfields >= 10 /\ (settled46.orderAcknowledgmentV2ReturnBitfield10 # << >> /\ (settled46.orderAcknowledgmentV2ReturnBitfield10[1] \div 128) % 2 > 0) THEN (IF settled46.clientQualifiedRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled46.clientQualifiedRole) ELSE << >>]
        settled48 == [settled47 EXCEPT !.clientId = IF settled47.numberOfReturnBitfields >= 11 /\ (settled47.orderAcknowledgmentV2ReturnBitfield11 # << >> /\ settled47.orderAcknowledgmentV2ReturnBitfield11[1] % 2 > 0) THEN (IF settled47.clientId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled47.clientId) ELSE << >>]
        settled49 == [settled48 EXCEPT !.investorId = IF settled48.numberOfReturnBitfields >= 11 /\ (settled48.orderAcknowledgmentV2ReturnBitfield11 # << >> /\ (settled48.orderAcknowledgmentV2ReturnBitfield11[1] \div 2) % 2 > 0) THEN (IF settled48.investorId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled48.investorId) ELSE << >>]
        settled50 == [settled49 EXCEPT !.executorId = IF settled49.numberOfReturnBitfields >= 11 /\ (settled49.orderAcknowledgmentV2ReturnBitfield11 # << >> /\ (settled49.orderAcknowledgmentV2ReturnBitfield11[1] \div 4) % 2 > 0) THEN (IF settled49.executorId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled49.executorId) ELSE << >>]
        settled51 == [settled50 EXCEPT !.orderOrigination = IF settled50.numberOfReturnBitfields >= 11 /\ (settled50.orderAcknowledgmentV2ReturnBitfield11 # << >> /\ (settled50.orderAcknowledgmentV2ReturnBitfield11[1] \div 8) % 2 > 0) THEN (IF settled50.orderOrigination = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled50.orderOrigination) ELSE << >>]
        settled52 == [settled51 EXCEPT !.algorithmicIndicator = IF settled51.numberOfReturnBitfields >= 11 /\ (settled51.orderAcknowledgmentV2ReturnBitfield11 # << >> /\ (settled51.orderAcknowledgmentV2ReturnBitfield11[1] \div 16) % 2 > 0) THEN (IF settled51.algorithmicIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled51.algorithmicIndicator) ELSE << >>]
        settled53 == [settled52 EXCEPT !.deferralReason = IF settled52.numberOfReturnBitfields >= 11 /\ (settled52.orderAcknowledgmentV2ReturnBitfield11 # << >> /\ (settled52.orderAcknowledgmentV2ReturnBitfield11[1] \div 32) % 2 > 0) THEN (IF settled52.deferralReason = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled52.deferralReason) ELSE << >>]
        settled54 == [settled53 EXCEPT !.investorQualifiedRole = IF settled53.numberOfReturnBitfields >= 11 /\ (settled53.orderAcknowledgmentV2ReturnBitfield11 # << >> /\ (settled53.orderAcknowledgmentV2ReturnBitfield11[1] \div 64) % 2 > 0) THEN (IF settled53.investorQualifiedRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled53.investorQualifiedRole) ELSE << >>]
        settled55 == [settled54 EXCEPT !.executorQualifiedRole = IF settled54.numberOfReturnBitfields >= 11 /\ (settled54.orderAcknowledgmentV2ReturnBitfield11 # << >> /\ (settled54.orderAcknowledgmentV2ReturnBitfield11[1] \div 128) % 2 > 0) THEN (IF settled54.executorQualifiedRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled54.executorQualifiedRole) ELSE << >>]
    IN  settled55

ZeroOrderAcknowledgmentV2Message ==
    SettleOrderAcknowledgmentV2Message([ transactionTime                       |-> [i \in 1 .. 8 |-> 0],
                                         clOrdId                               |-> [i \in 1 .. 20 |-> 0],
                                         orderId                               |-> [i \in 1 .. 8 |-> 0],
                                         reserved1                             |-> [i \in 1 .. 1 |-> 0],
                                         numberOfReturnBitfields               |-> 0,
                                         orderAcknowledgmentV2ReturnBitfield1  |-> << >>,
                                         orderAcknowledgmentV2ReturnBitfield2  |-> << >>,
                                         orderAcknowledgmentV2ReturnBitfield3  |-> << >>,
                                         orderAcknowledgmentV2ReturnBitfield4  |-> << >>,
                                         orderAcknowledgmentV2ReturnBitfield5  |-> << >>,
                                         orderAcknowledgmentV2ReturnBitfield6  |-> << >>,
                                         orderAcknowledgmentV2ReturnBitfield7  |-> << >>,
                                         orderAcknowledgmentV2ReturnBitfield8  |-> << >>,
                                         orderAcknowledgmentV2ReturnBitfield9  |-> << >>,
                                         orderAcknowledgmentV2ReturnBitfield10 |-> << >>,
                                         orderAcknowledgmentV2ReturnBitfield11 |-> << >>,
                                         orderAcknowledgmentV2ReturnBitfield12 |-> << >>,
                                         orderAcknowledgmentV2ReturnBitfield13 |-> << >>,
                                         orderAcknowledgmentV2ReturnBitfield14 |-> << >>,
                                         side                                  |-> << >>,
                                         pegDifference                         |-> << >>,
                                         price                                 |-> << >>,
                                         execInst                              |-> << >>,
                                         ordType                               |-> << >>,
                                         timeInForce                           |-> << >>,
                                         minQty                                |-> << >>,
                                         symbol                                |-> << >>,
                                         currency                              |-> << >>,
                                         idSource                              |-> << >>,
                                         securityId                            |-> << >>,
                                         securityExchange                      |-> << >>,
                                         capacity                              |-> << >>,
                                         account                               |-> << >>,
                                         clearingFirm                          |-> << >>,
                                         clearingAccount                       |-> << >>,
                                         displayIndicator                      |-> << >>,
                                         maxFloor                              |-> << >>,
                                         orderQty                              |-> << >>,
                                         preventParticipantMatch               |-> << >>,
                                         origClOrdId                           |-> << >>,
                                         leavesQty                             |-> << >>,
                                         lastShares                            |-> << >>,
                                         lastPx                                |-> << >>,
                                         displayPrice                          |-> << >>,
                                         workingPrice                          |-> << >>,
                                         baseLiquidityIndicator                |-> << >>,
                                         expireTime                            |-> << >>,
                                         secondaryOrderId                      |-> << >>,
                                         liquidityProvision                    |-> << >>,
                                         waiverType                            |-> << >>,
                                         priceFormation                        |-> << >>,
                                         clientQualifiedRole                   |-> << >>,
                                         clientId                              |-> << >>,
                                         investorId                            |-> << >>,
                                         executorId                            |-> << >>,
                                         orderOrigination                      |-> << >>,
                                         algorithmicIndicator                  |-> << >>,
                                         deferralReason                        |-> << >>,
                                         investorQualifiedRole                 |-> << >>,
                                         executorQualifiedRole                 |-> << >> ])

(* Order Acknowledgment V 2 Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderAcknowledgmentV2Message ==
    { ZeroOrderAcknowledgmentV2Message }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.transactionTime = one]) : one \in Sample(8) }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.clOrdId = one]) : one \in Sample(20) }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.orderId = one]) : one \in Sample(8) }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.reserved1 = one]) : one \in Sample(1) }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderAcknowledgmentV2ReturnBitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 2, !.orderAcknowledgmentV2ReturnBitfield2 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderAcknowledgmentV2ReturnBitfield3 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 4, !.orderAcknowledgmentV2ReturnBitfield4 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 5, !.orderAcknowledgmentV2ReturnBitfield5 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 6, !.orderAcknowledgmentV2ReturnBitfield6 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 7, !.orderAcknowledgmentV2ReturnBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 8, !.orderAcknowledgmentV2ReturnBitfield8 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 9, !.orderAcknowledgmentV2ReturnBitfield9 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 10, !.orderAcknowledgmentV2ReturnBitfield10 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderAcknowledgmentV2ReturnBitfield11 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 12, !.orderAcknowledgmentV2ReturnBitfield12 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 13, !.orderAcknowledgmentV2ReturnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 14, !.orderAcknowledgmentV2ReturnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderAcknowledgmentV2ReturnBitfield1 = <<1>>, !.side = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderAcknowledgmentV2ReturnBitfield1 = <<2>>, !.pegDifference = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderAcknowledgmentV2ReturnBitfield1 = <<4>>, !.price = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderAcknowledgmentV2ReturnBitfield1 = <<8>>, !.execInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderAcknowledgmentV2ReturnBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderAcknowledgmentV2ReturnBitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderAcknowledgmentV2ReturnBitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 2, !.orderAcknowledgmentV2ReturnBitfield2 = <<1>>, !.symbol = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 2, !.orderAcknowledgmentV2ReturnBitfield2 = <<4>>, !.currency = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 2, !.orderAcknowledgmentV2ReturnBitfield2 = <<8>>, !.idSource = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 2, !.orderAcknowledgmentV2ReturnBitfield2 = <<16>>, !.securityId = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 2, !.orderAcknowledgmentV2ReturnBitfield2 = <<32>>, !.securityExchange = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 2, !.orderAcknowledgmentV2ReturnBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderAcknowledgmentV2ReturnBitfield3 = <<1>>, !.account = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderAcknowledgmentV2ReturnBitfield3 = <<2>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderAcknowledgmentV2ReturnBitfield3 = <<4>>, !.clearingAccount = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderAcknowledgmentV2ReturnBitfield3 = <<8>>, !.displayIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderAcknowledgmentV2ReturnBitfield3 = <<16>>, !.maxFloor = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderAcknowledgmentV2ReturnBitfield3 = <<64>>, !.orderQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderAcknowledgmentV2ReturnBitfield3 = <<128>>, !.preventParticipantMatch = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 5, !.orderAcknowledgmentV2ReturnBitfield5 = <<1>>, !.origClOrdId = one]) : one \in { <<held>> : held \in Sample(20) } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 5, !.orderAcknowledgmentV2ReturnBitfield5 = <<2>>, !.leavesQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 5, !.orderAcknowledgmentV2ReturnBitfield5 = <<4>>, !.lastShares = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 5, !.orderAcknowledgmentV2ReturnBitfield5 = <<8>>, !.lastPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 5, !.orderAcknowledgmentV2ReturnBitfield5 = <<16>>, !.displayPrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 5, !.orderAcknowledgmentV2ReturnBitfield5 = <<32>>, !.workingPrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 5, !.orderAcknowledgmentV2ReturnBitfield5 = <<64>>, !.baseLiquidityIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 5, !.orderAcknowledgmentV2ReturnBitfield5 = <<128>>, !.expireTime = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 6, !.orderAcknowledgmentV2ReturnBitfield6 = <<1>>, !.secondaryOrderId = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 9, !.orderAcknowledgmentV2ReturnBitfield9 = <<16>>, !.liquidityProvision = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 10, !.orderAcknowledgmentV2ReturnBitfield10 = <<16>>, !.waiverType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 10, !.orderAcknowledgmentV2ReturnBitfield10 = <<64>>, !.priceFormation = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 10, !.orderAcknowledgmentV2ReturnBitfield10 = <<128>>, !.clientQualifiedRole = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderAcknowledgmentV2ReturnBitfield11 = <<1>>, !.clientId = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderAcknowledgmentV2ReturnBitfield11 = <<2>>, !.investorId = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderAcknowledgmentV2ReturnBitfield11 = <<4>>, !.executorId = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderAcknowledgmentV2ReturnBitfield11 = <<8>>, !.orderOrigination = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderAcknowledgmentV2ReturnBitfield11 = <<16>>, !.algorithmicIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderAcknowledgmentV2ReturnBitfield11 = <<32>>, !.deferralReason = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderAcknowledgmentV2ReturnBitfield11 = <<64>>, !.investorQualifiedRole = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentV2Message([ZeroOrderAcknowledgmentV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderAcknowledgmentV2ReturnBitfield11 = <<128>>, !.executorQualifiedRole = one]) : one \in { <<held>> : held \in Sample(1) } }

(***************************************************************************)
(* Order Rejected V 2 Message                                              *)
(***************************************************************************)

OrderRejectedV2Message ==
    [ transactionTime                 : Sample(8),
      clOrdId                         : Sample(20),
      orderRejectReason               : Sample(1),
      text                            : Sample(60),
      reserved1                       : Sample(1),
      numberOfReturnBitfields         : 0 .. 255,
      orderRejectedV2ReturnBitfield1  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderRejectedV2ReturnBitfield2  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderRejectedV2ReturnBitfield3  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderRejectedV2ReturnBitfield4  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRejectedV2ReturnBitfield5  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRejectedV2ReturnBitfield6  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderRejectedV2ReturnBitfield7  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRejectedV2ReturnBitfield8  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRejectedV2ReturnBitfield9  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderRejectedV2ReturnBitfield10 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderRejectedV2ReturnBitfield11 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderRejectedV2ReturnBitfield12 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRejectedV2ReturnBitfield13 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRejectedV2ReturnBitfield14 : { << >> } \cup { <<held>> : held \in Sample(1) },
      side                            : { << >> } \cup { <<held>> : held \in Sample(1) },
      pegDifference                   : { << >> } \cup { <<held>> : held \in Sample(8) },
      price                           : { << >> } \cup { <<held>> : held \in Sample(8) },
      execInst                        : { << >> } \cup { <<held>> : held \in Sample(1) },
      ordType                         : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce                     : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                          : { << >> } \cup { <<held>> : held \in Sample(4) },
      symbol                          : { << >> } \cup { <<held>> : held \in Sample(8) },
      currency                        : { << >> } \cup { <<held>> : held \in Sample(3) },
      idSource                        : { << >> } \cup { <<held>> : held \in Sample(1) },
      securityId                      : { << >> } \cup { <<held>> : held \in Sample(16) },
      securityExchange                : { << >> } \cup { <<held>> : held \in Sample(4) },
      capacity                        : { << >> } \cup { <<held>> : held \in Sample(1) },
      account                         : { << >> } \cup { <<held>> : held \in Sample(16) },
      clearingFirm                    : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingAccount                 : { << >> } \cup { <<held>> : held \in Sample(4) },
      displayIndicator                : { << >> } \cup { <<held>> : held \in Sample(1) },
      maxFloor                        : { << >> } \cup { <<held>> : held \in Sample(4) },
      orderQty                        : { << >> } \cup { <<held>> : held \in Sample(4) },
      preventParticipantMatch         : { << >> } \cup { <<held>> : held \in Sample(3) },
      secondaryOrderId                : { << >> } \cup { <<held>> : held \in Sample(8) },
      liquidityProvision              : { << >> } \cup { <<held>> : held \in Sample(1) },
      waiverType                      : { << >> } \cup { <<held>> : held \in Sample(1) },
      priceFormation                  : { << >> } \cup { <<held>> : held \in Sample(1) },
      clientQualifiedRole             : { << >> } \cup { <<held>> : held \in Sample(1) },
      clientId                        : { << >> } \cup { <<held>> : held \in Sample(4) },
      investorId                      : { << >> } \cup { <<held>> : held \in Sample(4) },
      executorId                      : { << >> } \cup { <<held>> : held \in Sample(4) },
      orderOrigination                : { << >> } \cup { <<held>> : held \in Sample(1) },
      algorithmicIndicator            : { << >> } \cup { <<held>> : held \in Sample(1) },
      deferralReason                  : { << >> } \cup { <<held>> : held \in Sample(1) },
      investorQualifiedRole           : { << >> } \cup { <<held>> : held \in Sample(1) },
      executorQualifiedRole           : { << >> } \cup { <<held>> : held \in Sample(1) } ]

EncodeOrderRejectedV2Message(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.orderRejectReason
        \o message.text
        \o message.reserved1
        \o EncodeUIntBE(message.numberOfReturnBitfields, 1)
        \o (IF message.orderRejectedV2ReturnBitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.orderRejectedV2ReturnBitfield1[1], 1))
        \o (IF message.orderRejectedV2ReturnBitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.orderRejectedV2ReturnBitfield2[1], 1))
        \o (IF message.orderRejectedV2ReturnBitfield3 = << >> THEN << >> ELSE EncodeUIntLE(message.orderRejectedV2ReturnBitfield3[1], 1))
        \o (IF message.orderRejectedV2ReturnBitfield4 = << >> THEN << >> ELSE message.orderRejectedV2ReturnBitfield4[1])
        \o (IF message.orderRejectedV2ReturnBitfield5 = << >> THEN << >> ELSE message.orderRejectedV2ReturnBitfield5[1])
        \o (IF message.orderRejectedV2ReturnBitfield6 = << >> THEN << >> ELSE EncodeUIntLE(message.orderRejectedV2ReturnBitfield6[1], 1))
        \o (IF message.orderRejectedV2ReturnBitfield7 = << >> THEN << >> ELSE message.orderRejectedV2ReturnBitfield7[1])
        \o (IF message.orderRejectedV2ReturnBitfield8 = << >> THEN << >> ELSE message.orderRejectedV2ReturnBitfield8[1])
        \o (IF message.orderRejectedV2ReturnBitfield9 = << >> THEN << >> ELSE EncodeUIntLE(message.orderRejectedV2ReturnBitfield9[1], 1))
        \o (IF message.orderRejectedV2ReturnBitfield10 = << >> THEN << >> ELSE EncodeUIntLE(message.orderRejectedV2ReturnBitfield10[1], 1))
        \o (IF message.orderRejectedV2ReturnBitfield11 = << >> THEN << >> ELSE EncodeUIntLE(message.orderRejectedV2ReturnBitfield11[1], 1))
        \o (IF message.orderRejectedV2ReturnBitfield12 = << >> THEN << >> ELSE message.orderRejectedV2ReturnBitfield12[1])
        \o (IF message.orderRejectedV2ReturnBitfield13 = << >> THEN << >> ELSE message.orderRejectedV2ReturnBitfield13[1])
        \o (IF message.orderRejectedV2ReturnBitfield14 = << >> THEN << >> ELSE message.orderRejectedV2ReturnBitfield14[1])
        \o (IF message.side = << >> THEN << >> ELSE message.side[1])
        \o (IF message.pegDifference = << >> THEN << >> ELSE message.pegDifference[1])
        \o (IF message.price = << >> THEN << >> ELSE message.price[1])
        \o (IF message.execInst = << >> THEN << >> ELSE message.execInst[1])
        \o (IF message.ordType = << >> THEN << >> ELSE message.ordType[1])
        \o (IF message.timeInForce = << >> THEN << >> ELSE message.timeInForce[1])
        \o (IF message.minQty = << >> THEN << >> ELSE message.minQty[1])
        \o (IF message.symbol = << >> THEN << >> ELSE message.symbol[1])
        \o (IF message.currency = << >> THEN << >> ELSE message.currency[1])
        \o (IF message.idSource = << >> THEN << >> ELSE message.idSource[1])
        \o (IF message.securityId = << >> THEN << >> ELSE message.securityId[1])
        \o (IF message.securityExchange = << >> THEN << >> ELSE message.securityExchange[1])
        \o (IF message.capacity = << >> THEN << >> ELSE message.capacity[1])
        \o (IF message.account = << >> THEN << >> ELSE message.account[1])
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])
        \o (IF message.clearingAccount = << >> THEN << >> ELSE message.clearingAccount[1])
        \o (IF message.displayIndicator = << >> THEN << >> ELSE message.displayIndicator[1])
        \o (IF message.maxFloor = << >> THEN << >> ELSE message.maxFloor[1])
        \o (IF message.orderQty = << >> THEN << >> ELSE message.orderQty[1])
        \o (IF message.preventParticipantMatch = << >> THEN << >> ELSE message.preventParticipantMatch[1])
        \o (IF message.secondaryOrderId = << >> THEN << >> ELSE message.secondaryOrderId[1])
        \o (IF message.liquidityProvision = << >> THEN << >> ELSE message.liquidityProvision[1])
        \o (IF message.waiverType = << >> THEN << >> ELSE message.waiverType[1])
        \o (IF message.priceFormation = << >> THEN << >> ELSE message.priceFormation[1])
        \o (IF message.clientQualifiedRole = << >> THEN << >> ELSE message.clientQualifiedRole[1])
        \o (IF message.clientId = << >> THEN << >> ELSE message.clientId[1])
        \o (IF message.investorId = << >> THEN << >> ELSE message.investorId[1])
        \o (IF message.executorId = << >> THEN << >> ELSE message.executorId[1])
        \o (IF message.orderOrigination = << >> THEN << >> ELSE message.orderOrigination[1])
        \o (IF message.algorithmicIndicator = << >> THEN << >> ELSE message.algorithmicIndicator[1])
        \o (IF message.deferralReason = << >> THEN << >> ELSE message.deferralReason[1])
        \o (IF message.investorQualifiedRole = << >> THEN << >> ELSE message.investorQualifiedRole[1])
        \o (IF message.executorQualifiedRole = << >> THEN << >> ELSE message.executorQualifiedRole[1])

DecodeOrderRejectedV2Message(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET orderRejectReason == ReadBytes(clOrdId.rest, 1) IN IF ~orderRejectReason.ok THEN Fail ELSE
    LET text == ReadBytes(orderRejectReason.rest, 60) IN IF ~text.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(text.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET numberOfReturnBitfields == ReadUIntBE(reserved1.rest, 1) IN IF ~numberOfReturnBitfields.ok THEN Fail ELSE
    LET orderRejectedV2ReturnBitfield1 == ReadWhen(numberOfReturnBitfields.value >= 1, ReadUIntLE(numberOfReturnBitfields.rest, 1), numberOfReturnBitfields.rest) IN IF ~orderRejectedV2ReturnBitfield1.ok THEN Fail ELSE
    LET orderRejectedV2ReturnBitfield2 == ReadWhen(numberOfReturnBitfields.value >= 2, ReadUIntLE(orderRejectedV2ReturnBitfield1.rest, 1), orderRejectedV2ReturnBitfield1.rest) IN IF ~orderRejectedV2ReturnBitfield2.ok THEN Fail ELSE
    LET orderRejectedV2ReturnBitfield3 == ReadWhen(numberOfReturnBitfields.value >= 3, ReadUIntLE(orderRejectedV2ReturnBitfield2.rest, 1), orderRejectedV2ReturnBitfield2.rest) IN IF ~orderRejectedV2ReturnBitfield3.ok THEN Fail ELSE
    LET orderRejectedV2ReturnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadBytes(orderRejectedV2ReturnBitfield3.rest, 1), orderRejectedV2ReturnBitfield3.rest) IN IF ~orderRejectedV2ReturnBitfield4.ok THEN Fail ELSE
    LET orderRejectedV2ReturnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadBytes(orderRejectedV2ReturnBitfield4.rest, 1), orderRejectedV2ReturnBitfield4.rest) IN IF ~orderRejectedV2ReturnBitfield5.ok THEN Fail ELSE
    LET orderRejectedV2ReturnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadUIntLE(orderRejectedV2ReturnBitfield5.rest, 1), orderRejectedV2ReturnBitfield5.rest) IN IF ~orderRejectedV2ReturnBitfield6.ok THEN Fail ELSE
    LET orderRejectedV2ReturnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadBytes(orderRejectedV2ReturnBitfield6.rest, 1), orderRejectedV2ReturnBitfield6.rest) IN IF ~orderRejectedV2ReturnBitfield7.ok THEN Fail ELSE
    LET orderRejectedV2ReturnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadBytes(orderRejectedV2ReturnBitfield7.rest, 1), orderRejectedV2ReturnBitfield7.rest) IN IF ~orderRejectedV2ReturnBitfield8.ok THEN Fail ELSE
    LET orderRejectedV2ReturnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadUIntLE(orderRejectedV2ReturnBitfield8.rest, 1), orderRejectedV2ReturnBitfield8.rest) IN IF ~orderRejectedV2ReturnBitfield9.ok THEN Fail ELSE
    LET orderRejectedV2ReturnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadUIntLE(orderRejectedV2ReturnBitfield9.rest, 1), orderRejectedV2ReturnBitfield9.rest) IN IF ~orderRejectedV2ReturnBitfield10.ok THEN Fail ELSE
    LET orderRejectedV2ReturnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadUIntLE(orderRejectedV2ReturnBitfield10.rest, 1), orderRejectedV2ReturnBitfield10.rest) IN IF ~orderRejectedV2ReturnBitfield11.ok THEN Fail ELSE
    LET orderRejectedV2ReturnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadBytes(orderRejectedV2ReturnBitfield11.rest, 1), orderRejectedV2ReturnBitfield11.rest) IN IF ~orderRejectedV2ReturnBitfield12.ok THEN Fail ELSE
    LET orderRejectedV2ReturnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(orderRejectedV2ReturnBitfield12.rest, 1), orderRejectedV2ReturnBitfield12.rest) IN IF ~orderRejectedV2ReturnBitfield13.ok THEN Fail ELSE
    LET orderRejectedV2ReturnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(orderRejectedV2ReturnBitfield13.rest, 1), orderRejectedV2ReturnBitfield13.rest) IN IF ~orderRejectedV2ReturnBitfield14.ok THEN Fail ELSE
    LET side == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderRejectedV2ReturnBitfield1.value # << >> /\ orderRejectedV2ReturnBitfield1.value[1] % 2 > 0), ReadBytes(orderRejectedV2ReturnBitfield14.rest, 1), orderRejectedV2ReturnBitfield14.rest) IN IF ~side.ok THEN Fail ELSE
    LET pegDifference == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderRejectedV2ReturnBitfield1.value # << >> /\ (orderRejectedV2ReturnBitfield1.value[1] \div 2) % 2 > 0), ReadBytes(side.rest, 8), side.rest) IN IF ~pegDifference.ok THEN Fail ELSE
    LET price == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderRejectedV2ReturnBitfield1.value # << >> /\ (orderRejectedV2ReturnBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(pegDifference.rest, 8), pegDifference.rest) IN IF ~price.ok THEN Fail ELSE
    LET execInst == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderRejectedV2ReturnBitfield1.value # << >> /\ (orderRejectedV2ReturnBitfield1.value[1] \div 8) % 2 > 0), ReadBytes(price.rest, 1), price.rest) IN IF ~execInst.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderRejectedV2ReturnBitfield1.value # << >> /\ (orderRejectedV2ReturnBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(execInst.rest, 1), execInst.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderRejectedV2ReturnBitfield1.value # << >> /\ (orderRejectedV2ReturnBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderRejectedV2ReturnBitfield1.value # << >> /\ (orderRejectedV2ReturnBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET symbol == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderRejectedV2ReturnBitfield2.value # << >> /\ orderRejectedV2ReturnBitfield2.value[1] % 2 > 0), ReadBytes(minQty.rest, 8), minQty.rest) IN IF ~symbol.ok THEN Fail ELSE
    LET currency == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderRejectedV2ReturnBitfield2.value # << >> /\ (orderRejectedV2ReturnBitfield2.value[1] \div 4) % 2 > 0), ReadBytes(symbol.rest, 3), symbol.rest) IN IF ~currency.ok THEN Fail ELSE
    LET idSource == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderRejectedV2ReturnBitfield2.value # << >> /\ (orderRejectedV2ReturnBitfield2.value[1] \div 8) % 2 > 0), ReadBytes(currency.rest, 1), currency.rest) IN IF ~idSource.ok THEN Fail ELSE
    LET securityId == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderRejectedV2ReturnBitfield2.value # << >> /\ (orderRejectedV2ReturnBitfield2.value[1] \div 16) % 2 > 0), ReadBytes(idSource.rest, 16), idSource.rest) IN IF ~securityId.ok THEN Fail ELSE
    LET securityExchange == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderRejectedV2ReturnBitfield2.value # << >> /\ (orderRejectedV2ReturnBitfield2.value[1] \div 32) % 2 > 0), ReadBytes(securityId.rest, 4), securityId.rest) IN IF ~securityExchange.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderRejectedV2ReturnBitfield2.value # << >> /\ (orderRejectedV2ReturnBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(securityExchange.rest, 1), securityExchange.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderRejectedV2ReturnBitfield3.value # << >> /\ orderRejectedV2ReturnBitfield3.value[1] % 2 > 0), ReadBytes(capacity.rest, 16), capacity.rest) IN IF ~account.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderRejectedV2ReturnBitfield3.value # << >> /\ (orderRejectedV2ReturnBitfield3.value[1] \div 2) % 2 > 0), ReadBytes(account.rest, 4), account.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderRejectedV2ReturnBitfield3.value # << >> /\ (orderRejectedV2ReturnBitfield3.value[1] \div 4) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET displayIndicator == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderRejectedV2ReturnBitfield3.value # << >> /\ (orderRejectedV2ReturnBitfield3.value[1] \div 8) % 2 > 0), ReadBytes(clearingAccount.rest, 1), clearingAccount.rest) IN IF ~displayIndicator.ok THEN Fail ELSE
    LET maxFloor == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderRejectedV2ReturnBitfield3.value # << >> /\ (orderRejectedV2ReturnBitfield3.value[1] \div 16) % 2 > 0), ReadBytes(displayIndicator.rest, 4), displayIndicator.rest) IN IF ~maxFloor.ok THEN Fail ELSE
    LET orderQty == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderRejectedV2ReturnBitfield3.value # << >> /\ (orderRejectedV2ReturnBitfield3.value[1] \div 64) % 2 > 0), ReadBytes(maxFloor.rest, 4), maxFloor.rest) IN IF ~orderQty.ok THEN Fail ELSE
    LET preventParticipantMatch == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderRejectedV2ReturnBitfield3.value # << >> /\ (orderRejectedV2ReturnBitfield3.value[1] \div 128) % 2 > 0), ReadBytes(orderQty.rest, 3), orderQty.rest) IN IF ~preventParticipantMatch.ok THEN Fail ELSE
    LET secondaryOrderId == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (orderRejectedV2ReturnBitfield6.value # << >> /\ orderRejectedV2ReturnBitfield6.value[1] % 2 > 0), ReadBytes(preventParticipantMatch.rest, 8), preventParticipantMatch.rest) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET liquidityProvision == ReadWhen(numberOfReturnBitfields.value >= 9 /\ (orderRejectedV2ReturnBitfield9.value # << >> /\ (orderRejectedV2ReturnBitfield9.value[1] \div 16) % 2 > 0), ReadBytes(secondaryOrderId.rest, 1), secondaryOrderId.rest) IN IF ~liquidityProvision.ok THEN Fail ELSE
    LET waiverType == ReadWhen(numberOfReturnBitfields.value >= 10 /\ (orderRejectedV2ReturnBitfield10.value # << >> /\ (orderRejectedV2ReturnBitfield10.value[1] \div 16) % 2 > 0), ReadBytes(liquidityProvision.rest, 1), liquidityProvision.rest) IN IF ~waiverType.ok THEN Fail ELSE
    LET priceFormation == ReadWhen(numberOfReturnBitfields.value >= 10 /\ (orderRejectedV2ReturnBitfield10.value # << >> /\ (orderRejectedV2ReturnBitfield10.value[1] \div 64) % 2 > 0), ReadBytes(waiverType.rest, 1), waiverType.rest) IN IF ~priceFormation.ok THEN Fail ELSE
    LET clientQualifiedRole == ReadWhen(numberOfReturnBitfields.value >= 10 /\ (orderRejectedV2ReturnBitfield10.value # << >> /\ (orderRejectedV2ReturnBitfield10.value[1] \div 128) % 2 > 0), ReadBytes(priceFormation.rest, 1), priceFormation.rest) IN IF ~clientQualifiedRole.ok THEN Fail ELSE
    LET clientId == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (orderRejectedV2ReturnBitfield11.value # << >> /\ orderRejectedV2ReturnBitfield11.value[1] % 2 > 0), ReadBytes(clientQualifiedRole.rest, 4), clientQualifiedRole.rest) IN IF ~clientId.ok THEN Fail ELSE
    LET investorId == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (orderRejectedV2ReturnBitfield11.value # << >> /\ (orderRejectedV2ReturnBitfield11.value[1] \div 2) % 2 > 0), ReadBytes(clientId.rest, 4), clientId.rest) IN IF ~investorId.ok THEN Fail ELSE
    LET executorId == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (orderRejectedV2ReturnBitfield11.value # << >> /\ (orderRejectedV2ReturnBitfield11.value[1] \div 4) % 2 > 0), ReadBytes(investorId.rest, 4), investorId.rest) IN IF ~executorId.ok THEN Fail ELSE
    LET orderOrigination == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (orderRejectedV2ReturnBitfield11.value # << >> /\ (orderRejectedV2ReturnBitfield11.value[1] \div 8) % 2 > 0), ReadBytes(executorId.rest, 1), executorId.rest) IN IF ~orderOrigination.ok THEN Fail ELSE
    LET algorithmicIndicator == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (orderRejectedV2ReturnBitfield11.value # << >> /\ (orderRejectedV2ReturnBitfield11.value[1] \div 16) % 2 > 0), ReadBytes(orderOrigination.rest, 1), orderOrigination.rest) IN IF ~algorithmicIndicator.ok THEN Fail ELSE
    LET deferralReason == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (orderRejectedV2ReturnBitfield11.value # << >> /\ (orderRejectedV2ReturnBitfield11.value[1] \div 32) % 2 > 0), ReadBytes(algorithmicIndicator.rest, 1), algorithmicIndicator.rest) IN IF ~deferralReason.ok THEN Fail ELSE
    LET investorQualifiedRole == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (orderRejectedV2ReturnBitfield11.value # << >> /\ (orderRejectedV2ReturnBitfield11.value[1] \div 64) % 2 > 0), ReadBytes(deferralReason.rest, 1), deferralReason.rest) IN IF ~investorQualifiedRole.ok THEN Fail ELSE
    LET executorQualifiedRole == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (orderRejectedV2ReturnBitfield11.value # << >> /\ (orderRejectedV2ReturnBitfield11.value[1] \div 128) % 2 > 0), ReadBytes(investorQualifiedRole.rest, 1), investorQualifiedRole.rest) IN IF ~executorQualifiedRole.ok THEN Fail ELSE
    Ok([ transactionTime                 |-> transactionTime.value,
         clOrdId                         |-> clOrdId.value,
         orderRejectReason               |-> orderRejectReason.value,
         text                            |-> text.value,
         reserved1                       |-> reserved1.value,
         numberOfReturnBitfields         |-> numberOfReturnBitfields.value,
         orderRejectedV2ReturnBitfield1  |-> orderRejectedV2ReturnBitfield1.value,
         orderRejectedV2ReturnBitfield2  |-> orderRejectedV2ReturnBitfield2.value,
         orderRejectedV2ReturnBitfield3  |-> orderRejectedV2ReturnBitfield3.value,
         orderRejectedV2ReturnBitfield4  |-> orderRejectedV2ReturnBitfield4.value,
         orderRejectedV2ReturnBitfield5  |-> orderRejectedV2ReturnBitfield5.value,
         orderRejectedV2ReturnBitfield6  |-> orderRejectedV2ReturnBitfield6.value,
         orderRejectedV2ReturnBitfield7  |-> orderRejectedV2ReturnBitfield7.value,
         orderRejectedV2ReturnBitfield8  |-> orderRejectedV2ReturnBitfield8.value,
         orderRejectedV2ReturnBitfield9  |-> orderRejectedV2ReturnBitfield9.value,
         orderRejectedV2ReturnBitfield10 |-> orderRejectedV2ReturnBitfield10.value,
         orderRejectedV2ReturnBitfield11 |-> orderRejectedV2ReturnBitfield11.value,
         orderRejectedV2ReturnBitfield12 |-> orderRejectedV2ReturnBitfield12.value,
         orderRejectedV2ReturnBitfield13 |-> orderRejectedV2ReturnBitfield13.value,
         orderRejectedV2ReturnBitfield14 |-> orderRejectedV2ReturnBitfield14.value,
         side                            |-> side.value,
         pegDifference                   |-> pegDifference.value,
         price                           |-> price.value,
         execInst                        |-> execInst.value,
         ordType                         |-> ordType.value,
         timeInForce                     |-> timeInForce.value,
         minQty                          |-> minQty.value,
         symbol                          |-> symbol.value,
         currency                        |-> currency.value,
         idSource                        |-> idSource.value,
         securityId                      |-> securityId.value,
         securityExchange                |-> securityExchange.value,
         capacity                        |-> capacity.value,
         account                         |-> account.value,
         clearingFirm                    |-> clearingFirm.value,
         clearingAccount                 |-> clearingAccount.value,
         displayIndicator                |-> displayIndicator.value,
         maxFloor                        |-> maxFloor.value,
         orderQty                        |-> orderQty.value,
         preventParticipantMatch         |-> preventParticipantMatch.value,
         secondaryOrderId                |-> secondaryOrderId.value,
         liquidityProvision              |-> liquidityProvision.value,
         waiverType                      |-> waiverType.value,
         priceFormation                  |-> priceFormation.value,
         clientQualifiedRole             |-> clientQualifiedRole.value,
         clientId                        |-> clientId.value,
         investorId                      |-> investorId.value,
         executorId                      |-> executorId.value,
         orderOrigination                |-> orderOrigination.value,
         algorithmicIndicator            |-> algorithmicIndicator.value,
         deferralReason                  |-> deferralReason.value,
         investorQualifiedRole           |-> investorQualifiedRole.value,
         executorQualifiedRole           |-> executorQualifiedRole.value ], executorQualifiedRole.rest)

(* Order Rejected V 2 Message with each field marked present by fields before it there exactly where they say *)
SettleOrderRejectedV2Message(message) ==
    LET settled1 == [message EXCEPT !.orderRejectedV2ReturnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.orderRejectedV2ReturnBitfield1 = << >> THEN <<0>> ELSE message.orderRejectedV2ReturnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.orderRejectedV2ReturnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.orderRejectedV2ReturnBitfield2 = << >> THEN <<0>> ELSE settled1.orderRejectedV2ReturnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.orderRejectedV2ReturnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.orderRejectedV2ReturnBitfield3 = << >> THEN <<0>> ELSE settled2.orderRejectedV2ReturnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.orderRejectedV2ReturnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.orderRejectedV2ReturnBitfield4 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled3.orderRejectedV2ReturnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.orderRejectedV2ReturnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.orderRejectedV2ReturnBitfield5 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled4.orderRejectedV2ReturnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.orderRejectedV2ReturnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.orderRejectedV2ReturnBitfield6 = << >> THEN <<0>> ELSE settled5.orderRejectedV2ReturnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.orderRejectedV2ReturnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.orderRejectedV2ReturnBitfield7 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.orderRejectedV2ReturnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.orderRejectedV2ReturnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.orderRejectedV2ReturnBitfield8 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled7.orderRejectedV2ReturnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.orderRejectedV2ReturnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.orderRejectedV2ReturnBitfield9 = << >> THEN <<0>> ELSE settled8.orderRejectedV2ReturnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.orderRejectedV2ReturnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.orderRejectedV2ReturnBitfield10 = << >> THEN <<0>> ELSE settled9.orderRejectedV2ReturnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.orderRejectedV2ReturnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.orderRejectedV2ReturnBitfield11 = << >> THEN <<0>> ELSE settled10.orderRejectedV2ReturnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.orderRejectedV2ReturnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.orderRejectedV2ReturnBitfield12 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.orderRejectedV2ReturnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.orderRejectedV2ReturnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.orderRejectedV2ReturnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.orderRejectedV2ReturnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.orderRejectedV2ReturnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.orderRejectedV2ReturnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.orderRejectedV2ReturnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.side = IF settled14.numberOfReturnBitfields >= 1 /\ (settled14.orderRejectedV2ReturnBitfield1 # << >> /\ settled14.orderRejectedV2ReturnBitfield1[1] % 2 > 0) THEN (IF settled14.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.side) ELSE << >>]
        settled16 == [settled15 EXCEPT !.pegDifference = IF settled15.numberOfReturnBitfields >= 1 /\ (settled15.orderRejectedV2ReturnBitfield1 # << >> /\ (settled15.orderRejectedV2ReturnBitfield1[1] \div 2) % 2 > 0) THEN (IF settled15.pegDifference = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled15.pegDifference) ELSE << >>]
        settled17 == [settled16 EXCEPT !.price = IF settled16.numberOfReturnBitfields >= 1 /\ (settled16.orderRejectedV2ReturnBitfield1 # << >> /\ (settled16.orderRejectedV2ReturnBitfield1[1] \div 4) % 2 > 0) THEN (IF settled16.price = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled16.price) ELSE << >>]
        settled18 == [settled17 EXCEPT !.execInst = IF settled17.numberOfReturnBitfields >= 1 /\ (settled17.orderRejectedV2ReturnBitfield1 # << >> /\ (settled17.orderRejectedV2ReturnBitfield1[1] \div 8) % 2 > 0) THEN (IF settled17.execInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.execInst) ELSE << >>]
        settled19 == [settled18 EXCEPT !.ordType = IF settled18.numberOfReturnBitfields >= 1 /\ (settled18.orderRejectedV2ReturnBitfield1 # << >> /\ (settled18.orderRejectedV2ReturnBitfield1[1] \div 16) % 2 > 0) THEN (IF settled18.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled18.ordType) ELSE << >>]
        settled20 == [settled19 EXCEPT !.timeInForce = IF settled19.numberOfReturnBitfields >= 1 /\ (settled19.orderRejectedV2ReturnBitfield1 # << >> /\ (settled19.orderRejectedV2ReturnBitfield1[1] \div 32) % 2 > 0) THEN (IF settled19.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled19.timeInForce) ELSE << >>]
        settled21 == [settled20 EXCEPT !.minQty = IF settled20.numberOfReturnBitfields >= 1 /\ (settled20.orderRejectedV2ReturnBitfield1 # << >> /\ (settled20.orderRejectedV2ReturnBitfield1[1] \div 64) % 2 > 0) THEN (IF settled20.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled20.minQty) ELSE << >>]
        settled22 == [settled21 EXCEPT !.symbol = IF settled21.numberOfReturnBitfields >= 2 /\ (settled21.orderRejectedV2ReturnBitfield2 # << >> /\ settled21.orderRejectedV2ReturnBitfield2[1] % 2 > 0) THEN (IF settled21.symbol = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled21.symbol) ELSE << >>]
        settled23 == [settled22 EXCEPT !.currency = IF settled22.numberOfReturnBitfields >= 2 /\ (settled22.orderRejectedV2ReturnBitfield2 # << >> /\ (settled22.orderRejectedV2ReturnBitfield2[1] \div 4) % 2 > 0) THEN (IF settled22.currency = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled22.currency) ELSE << >>]
        settled24 == [settled23 EXCEPT !.idSource = IF settled23.numberOfReturnBitfields >= 2 /\ (settled23.orderRejectedV2ReturnBitfield2 # << >> /\ (settled23.orderRejectedV2ReturnBitfield2[1] \div 8) % 2 > 0) THEN (IF settled23.idSource = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled23.idSource) ELSE << >>]
        settled25 == [settled24 EXCEPT !.securityId = IF settled24.numberOfReturnBitfields >= 2 /\ (settled24.orderRejectedV2ReturnBitfield2 # << >> /\ (settled24.orderRejectedV2ReturnBitfield2[1] \div 16) % 2 > 0) THEN (IF settled24.securityId = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled24.securityId) ELSE << >>]
        settled26 == [settled25 EXCEPT !.securityExchange = IF settled25.numberOfReturnBitfields >= 2 /\ (settled25.orderRejectedV2ReturnBitfield2 # << >> /\ (settled25.orderRejectedV2ReturnBitfield2[1] \div 32) % 2 > 0) THEN (IF settled25.securityExchange = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled25.securityExchange) ELSE << >>]
        settled27 == [settled26 EXCEPT !.capacity = IF settled26.numberOfReturnBitfields >= 2 /\ (settled26.orderRejectedV2ReturnBitfield2 # << >> /\ (settled26.orderRejectedV2ReturnBitfield2[1] \div 64) % 2 > 0) THEN (IF settled26.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled26.capacity) ELSE << >>]
        settled28 == [settled27 EXCEPT !.account = IF settled27.numberOfReturnBitfields >= 3 /\ (settled27.orderRejectedV2ReturnBitfield3 # << >> /\ settled27.orderRejectedV2ReturnBitfield3[1] % 2 > 0) THEN (IF settled27.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled27.account) ELSE << >>]
        settled29 == [settled28 EXCEPT !.clearingFirm = IF settled28.numberOfReturnBitfields >= 3 /\ (settled28.orderRejectedV2ReturnBitfield3 # << >> /\ (settled28.orderRejectedV2ReturnBitfield3[1] \div 2) % 2 > 0) THEN (IF settled28.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled28.clearingFirm) ELSE << >>]
        settled30 == [settled29 EXCEPT !.clearingAccount = IF settled29.numberOfReturnBitfields >= 3 /\ (settled29.orderRejectedV2ReturnBitfield3 # << >> /\ (settled29.orderRejectedV2ReturnBitfield3[1] \div 4) % 2 > 0) THEN (IF settled29.clearingAccount = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled29.clearingAccount) ELSE << >>]
        settled31 == [settled30 EXCEPT !.displayIndicator = IF settled30.numberOfReturnBitfields >= 3 /\ (settled30.orderRejectedV2ReturnBitfield3 # << >> /\ (settled30.orderRejectedV2ReturnBitfield3[1] \div 8) % 2 > 0) THEN (IF settled30.displayIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled30.displayIndicator) ELSE << >>]
        settled32 == [settled31 EXCEPT !.maxFloor = IF settled31.numberOfReturnBitfields >= 3 /\ (settled31.orderRejectedV2ReturnBitfield3 # << >> /\ (settled31.orderRejectedV2ReturnBitfield3[1] \div 16) % 2 > 0) THEN (IF settled31.maxFloor = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled31.maxFloor) ELSE << >>]
        settled33 == [settled32 EXCEPT !.orderQty = IF settled32.numberOfReturnBitfields >= 3 /\ (settled32.orderRejectedV2ReturnBitfield3 # << >> /\ (settled32.orderRejectedV2ReturnBitfield3[1] \div 64) % 2 > 0) THEN (IF settled32.orderQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled32.orderQty) ELSE << >>]
        settled34 == [settled33 EXCEPT !.preventParticipantMatch = IF settled33.numberOfReturnBitfields >= 3 /\ (settled33.orderRejectedV2ReturnBitfield3 # << >> /\ (settled33.orderRejectedV2ReturnBitfield3[1] \div 128) % 2 > 0) THEN (IF settled33.preventParticipantMatch = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled33.preventParticipantMatch) ELSE << >>]
        settled35 == [settled34 EXCEPT !.secondaryOrderId = IF settled34.numberOfReturnBitfields >= 6 /\ (settled34.orderRejectedV2ReturnBitfield6 # << >> /\ settled34.orderRejectedV2ReturnBitfield6[1] % 2 > 0) THEN (IF settled34.secondaryOrderId = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled34.secondaryOrderId) ELSE << >>]
        settled36 == [settled35 EXCEPT !.liquidityProvision = IF settled35.numberOfReturnBitfields >= 9 /\ (settled35.orderRejectedV2ReturnBitfield9 # << >> /\ (settled35.orderRejectedV2ReturnBitfield9[1] \div 16) % 2 > 0) THEN (IF settled35.liquidityProvision = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled35.liquidityProvision) ELSE << >>]
        settled37 == [settled36 EXCEPT !.waiverType = IF settled36.numberOfReturnBitfields >= 10 /\ (settled36.orderRejectedV2ReturnBitfield10 # << >> /\ (settled36.orderRejectedV2ReturnBitfield10[1] \div 16) % 2 > 0) THEN (IF settled36.waiverType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled36.waiverType) ELSE << >>]
        settled38 == [settled37 EXCEPT !.priceFormation = IF settled37.numberOfReturnBitfields >= 10 /\ (settled37.orderRejectedV2ReturnBitfield10 # << >> /\ (settled37.orderRejectedV2ReturnBitfield10[1] \div 64) % 2 > 0) THEN (IF settled37.priceFormation = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled37.priceFormation) ELSE << >>]
        settled39 == [settled38 EXCEPT !.clientQualifiedRole = IF settled38.numberOfReturnBitfields >= 10 /\ (settled38.orderRejectedV2ReturnBitfield10 # << >> /\ (settled38.orderRejectedV2ReturnBitfield10[1] \div 128) % 2 > 0) THEN (IF settled38.clientQualifiedRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled38.clientQualifiedRole) ELSE << >>]
        settled40 == [settled39 EXCEPT !.clientId = IF settled39.numberOfReturnBitfields >= 11 /\ (settled39.orderRejectedV2ReturnBitfield11 # << >> /\ settled39.orderRejectedV2ReturnBitfield11[1] % 2 > 0) THEN (IF settled39.clientId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled39.clientId) ELSE << >>]
        settled41 == [settled40 EXCEPT !.investorId = IF settled40.numberOfReturnBitfields >= 11 /\ (settled40.orderRejectedV2ReturnBitfield11 # << >> /\ (settled40.orderRejectedV2ReturnBitfield11[1] \div 2) % 2 > 0) THEN (IF settled40.investorId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled40.investorId) ELSE << >>]
        settled42 == [settled41 EXCEPT !.executorId = IF settled41.numberOfReturnBitfields >= 11 /\ (settled41.orderRejectedV2ReturnBitfield11 # << >> /\ (settled41.orderRejectedV2ReturnBitfield11[1] \div 4) % 2 > 0) THEN (IF settled41.executorId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled41.executorId) ELSE << >>]
        settled43 == [settled42 EXCEPT !.orderOrigination = IF settled42.numberOfReturnBitfields >= 11 /\ (settled42.orderRejectedV2ReturnBitfield11 # << >> /\ (settled42.orderRejectedV2ReturnBitfield11[1] \div 8) % 2 > 0) THEN (IF settled42.orderOrigination = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled42.orderOrigination) ELSE << >>]
        settled44 == [settled43 EXCEPT !.algorithmicIndicator = IF settled43.numberOfReturnBitfields >= 11 /\ (settled43.orderRejectedV2ReturnBitfield11 # << >> /\ (settled43.orderRejectedV2ReturnBitfield11[1] \div 16) % 2 > 0) THEN (IF settled43.algorithmicIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled43.algorithmicIndicator) ELSE << >>]
        settled45 == [settled44 EXCEPT !.deferralReason = IF settled44.numberOfReturnBitfields >= 11 /\ (settled44.orderRejectedV2ReturnBitfield11 # << >> /\ (settled44.orderRejectedV2ReturnBitfield11[1] \div 32) % 2 > 0) THEN (IF settled44.deferralReason = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled44.deferralReason) ELSE << >>]
        settled46 == [settled45 EXCEPT !.investorQualifiedRole = IF settled45.numberOfReturnBitfields >= 11 /\ (settled45.orderRejectedV2ReturnBitfield11 # << >> /\ (settled45.orderRejectedV2ReturnBitfield11[1] \div 64) % 2 > 0) THEN (IF settled45.investorQualifiedRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled45.investorQualifiedRole) ELSE << >>]
        settled47 == [settled46 EXCEPT !.executorQualifiedRole = IF settled46.numberOfReturnBitfields >= 11 /\ (settled46.orderRejectedV2ReturnBitfield11 # << >> /\ (settled46.orderRejectedV2ReturnBitfield11[1] \div 128) % 2 > 0) THEN (IF settled46.executorQualifiedRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled46.executorQualifiedRole) ELSE << >>]
    IN  settled47

ZeroOrderRejectedV2Message ==
    SettleOrderRejectedV2Message([ transactionTime                 |-> [i \in 1 .. 8 |-> 0],
                                   clOrdId                         |-> [i \in 1 .. 20 |-> 0],
                                   orderRejectReason               |-> [i \in 1 .. 1 |-> 0],
                                   text                            |-> [i \in 1 .. 60 |-> 0],
                                   reserved1                       |-> [i \in 1 .. 1 |-> 0],
                                   numberOfReturnBitfields         |-> 0,
                                   orderRejectedV2ReturnBitfield1  |-> << >>,
                                   orderRejectedV2ReturnBitfield2  |-> << >>,
                                   orderRejectedV2ReturnBitfield3  |-> << >>,
                                   orderRejectedV2ReturnBitfield4  |-> << >>,
                                   orderRejectedV2ReturnBitfield5  |-> << >>,
                                   orderRejectedV2ReturnBitfield6  |-> << >>,
                                   orderRejectedV2ReturnBitfield7  |-> << >>,
                                   orderRejectedV2ReturnBitfield8  |-> << >>,
                                   orderRejectedV2ReturnBitfield9  |-> << >>,
                                   orderRejectedV2ReturnBitfield10 |-> << >>,
                                   orderRejectedV2ReturnBitfield11 |-> << >>,
                                   orderRejectedV2ReturnBitfield12 |-> << >>,
                                   orderRejectedV2ReturnBitfield13 |-> << >>,
                                   orderRejectedV2ReturnBitfield14 |-> << >>,
                                   side                            |-> << >>,
                                   pegDifference                   |-> << >>,
                                   price                           |-> << >>,
                                   execInst                        |-> << >>,
                                   ordType                         |-> << >>,
                                   timeInForce                     |-> << >>,
                                   minQty                          |-> << >>,
                                   symbol                          |-> << >>,
                                   currency                        |-> << >>,
                                   idSource                        |-> << >>,
                                   securityId                      |-> << >>,
                                   securityExchange                |-> << >>,
                                   capacity                        |-> << >>,
                                   account                         |-> << >>,
                                   clearingFirm                    |-> << >>,
                                   clearingAccount                 |-> << >>,
                                   displayIndicator                |-> << >>,
                                   maxFloor                        |-> << >>,
                                   orderQty                        |-> << >>,
                                   preventParticipantMatch         |-> << >>,
                                   secondaryOrderId                |-> << >>,
                                   liquidityProvision              |-> << >>,
                                   waiverType                      |-> << >>,
                                   priceFormation                  |-> << >>,
                                   clientQualifiedRole             |-> << >>,
                                   clientId                        |-> << >>,
                                   investorId                      |-> << >>,
                                   executorId                      |-> << >>,
                                   orderOrigination                |-> << >>,
                                   algorithmicIndicator            |-> << >>,
                                   deferralReason                  |-> << >>,
                                   investorQualifiedRole           |-> << >>,
                                   executorQualifiedRole           |-> << >> ])

(* Order Rejected V 2 Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderRejectedV2Message ==
    { ZeroOrderRejectedV2Message }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.transactionTime = one]) : one \in Sample(8) }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.clOrdId = one]) : one \in Sample(20) }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.orderRejectReason = one]) : one \in Sample(1) }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.text = one]) : one \in Sample(60) }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.reserved1 = one]) : one \in Sample(1) }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderRejectedV2ReturnBitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = 2, !.orderRejectedV2ReturnBitfield2 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderRejectedV2ReturnBitfield3 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = 4, !.orderRejectedV2ReturnBitfield4 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = 5, !.orderRejectedV2ReturnBitfield5 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = 6, !.orderRejectedV2ReturnBitfield6 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = 7, !.orderRejectedV2ReturnBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = 8, !.orderRejectedV2ReturnBitfield8 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = 9, !.orderRejectedV2ReturnBitfield9 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = 10, !.orderRejectedV2ReturnBitfield10 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderRejectedV2ReturnBitfield11 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = 12, !.orderRejectedV2ReturnBitfield12 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = 13, !.orderRejectedV2ReturnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = 14, !.orderRejectedV2ReturnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderRejectedV2ReturnBitfield1 = <<1>>, !.side = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderRejectedV2ReturnBitfield1 = <<2>>, !.pegDifference = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderRejectedV2ReturnBitfield1 = <<4>>, !.price = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderRejectedV2ReturnBitfield1 = <<8>>, !.execInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderRejectedV2ReturnBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderRejectedV2ReturnBitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderRejectedV2ReturnBitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = 2, !.orderRejectedV2ReturnBitfield2 = <<1>>, !.symbol = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = 2, !.orderRejectedV2ReturnBitfield2 = <<4>>, !.currency = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = 2, !.orderRejectedV2ReturnBitfield2 = <<8>>, !.idSource = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = 2, !.orderRejectedV2ReturnBitfield2 = <<16>>, !.securityId = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = 2, !.orderRejectedV2ReturnBitfield2 = <<32>>, !.securityExchange = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = 2, !.orderRejectedV2ReturnBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderRejectedV2ReturnBitfield3 = <<1>>, !.account = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderRejectedV2ReturnBitfield3 = <<2>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderRejectedV2ReturnBitfield3 = <<4>>, !.clearingAccount = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderRejectedV2ReturnBitfield3 = <<8>>, !.displayIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderRejectedV2ReturnBitfield3 = <<16>>, !.maxFloor = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderRejectedV2ReturnBitfield3 = <<64>>, !.orderQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderRejectedV2ReturnBitfield3 = <<128>>, !.preventParticipantMatch = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = 6, !.orderRejectedV2ReturnBitfield6 = <<1>>, !.secondaryOrderId = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = 9, !.orderRejectedV2ReturnBitfield9 = <<16>>, !.liquidityProvision = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = 10, !.orderRejectedV2ReturnBitfield10 = <<16>>, !.waiverType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = 10, !.orderRejectedV2ReturnBitfield10 = <<64>>, !.priceFormation = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = 10, !.orderRejectedV2ReturnBitfield10 = <<128>>, !.clientQualifiedRole = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderRejectedV2ReturnBitfield11 = <<1>>, !.clientId = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderRejectedV2ReturnBitfield11 = <<2>>, !.investorId = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderRejectedV2ReturnBitfield11 = <<4>>, !.executorId = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderRejectedV2ReturnBitfield11 = <<8>>, !.orderOrigination = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderRejectedV2ReturnBitfield11 = <<16>>, !.algorithmicIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderRejectedV2ReturnBitfield11 = <<32>>, !.deferralReason = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderRejectedV2ReturnBitfield11 = <<64>>, !.investorQualifiedRole = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedV2Message([ZeroOrderRejectedV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderRejectedV2ReturnBitfield11 = <<128>>, !.executorQualifiedRole = one]) : one \in { <<held>> : held \in Sample(1) } }

(***************************************************************************)
(* Order Modified V 2 Message                                              *)
(***************************************************************************)

OrderModifiedV2Message ==
    [ transactionTime                 : Sample(8),
      clOrdId                         : Sample(20),
      orderId                         : Sample(8),
      reserved1                       : Sample(1),
      numberOfReturnBitfields         : 0 .. 255,
      orderModifiedV2ReturnBitfield1  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderModifiedV2ReturnBitfield2  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderModifiedV2ReturnBitfield3  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderModifiedV2ReturnBitfield4  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderModifiedV2ReturnBitfield5  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderModifiedV2ReturnBitfield6  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderModifiedV2ReturnBitfield7  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderModifiedV2ReturnBitfield8  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderModifiedV2ReturnBitfield9  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderModifiedV2ReturnBitfield10 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderModifiedV2ReturnBitfield11 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderModifiedV2ReturnBitfield12 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderModifiedV2ReturnBitfield13 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderModifiedV2ReturnBitfield14 : { << >> } \cup { <<held>> : held \in Sample(1) },
      side                            : { << >> } \cup { <<held>> : held \in Sample(1) },
      pegDifference                   : { << >> } \cup { <<held>> : held \in Sample(8) },
      price                           : { << >> } \cup { <<held>> : held \in Sample(8) },
      execInst                        : { << >> } \cup { <<held>> : held \in Sample(1) },
      ordType                         : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce                     : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                          : { << >> } \cup { <<held>> : held \in Sample(4) },
      account                         : { << >> } \cup { <<held>> : held \in Sample(16) },
      clearingFirm                    : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingAccount                 : { << >> } \cup { <<held>> : held \in Sample(4) },
      displayIndicator                : { << >> } \cup { <<held>> : held \in Sample(1) },
      maxFloor                        : { << >> } \cup { <<held>> : held \in Sample(4) },
      orderQty                        : { << >> } \cup { <<held>> : held \in Sample(4) },
      preventParticipantMatch         : { << >> } \cup { <<held>> : held \in Sample(3) },
      origClOrdId                     : { << >> } \cup { <<held>> : held \in Sample(20) },
      leavesQty                       : { << >> } \cup { <<held>> : held \in Sample(4) },
      lastShares                      : { << >> } \cup { <<held>> : held \in Sample(4) },
      lastPx                          : { << >> } \cup { <<held>> : held \in Sample(8) },
      displayPrice                    : { << >> } \cup { <<held>> : held \in Sample(8) },
      workingPrice                    : { << >> } \cup { <<held>> : held \in Sample(8) },
      baseLiquidityIndicator          : { << >> } \cup { <<held>> : held \in Sample(1) },
      expireTime                      : { << >> } \cup { <<held>> : held \in Sample(8) },
      secondaryOrderId                : { << >> } \cup { <<held>> : held \in Sample(8) },
      liquidityProvision              : { << >> } \cup { <<held>> : held \in Sample(1) },
      waiverType                      : { << >> } \cup { <<held>> : held \in Sample(1) },
      priceFormation                  : { << >> } \cup { <<held>> : held \in Sample(1) },
      clientQualifiedRole             : { << >> } \cup { <<held>> : held \in Sample(1) },
      clientId                        : { << >> } \cup { <<held>> : held \in Sample(4) },
      investorId                      : { << >> } \cup { <<held>> : held \in Sample(4) },
      executorId                      : { << >> } \cup { <<held>> : held \in Sample(4) },
      orderOrigination                : { << >> } \cup { <<held>> : held \in Sample(1) },
      algorithmicIndicator            : { << >> } \cup { <<held>> : held \in Sample(1) },
      deferralReason                  : { << >> } \cup { <<held>> : held \in Sample(1) },
      investorQualifiedRole           : { << >> } \cup { <<held>> : held \in Sample(1) },
      executorQualifiedRole           : { << >> } \cup { <<held>> : held \in Sample(1) } ]

EncodeOrderModifiedV2Message(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.orderId
        \o message.reserved1
        \o EncodeUIntBE(message.numberOfReturnBitfields, 1)
        \o (IF message.orderModifiedV2ReturnBitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.orderModifiedV2ReturnBitfield1[1], 1))
        \o (IF message.orderModifiedV2ReturnBitfield2 = << >> THEN << >> ELSE message.orderModifiedV2ReturnBitfield2[1])
        \o (IF message.orderModifiedV2ReturnBitfield3 = << >> THEN << >> ELSE EncodeUIntLE(message.orderModifiedV2ReturnBitfield3[1], 1))
        \o (IF message.orderModifiedV2ReturnBitfield4 = << >> THEN << >> ELSE message.orderModifiedV2ReturnBitfield4[1])
        \o (IF message.orderModifiedV2ReturnBitfield5 = << >> THEN << >> ELSE EncodeUIntLE(message.orderModifiedV2ReturnBitfield5[1], 1))
        \o (IF message.orderModifiedV2ReturnBitfield6 = << >> THEN << >> ELSE EncodeUIntLE(message.orderModifiedV2ReturnBitfield6[1], 1))
        \o (IF message.orderModifiedV2ReturnBitfield7 = << >> THEN << >> ELSE message.orderModifiedV2ReturnBitfield7[1])
        \o (IF message.orderModifiedV2ReturnBitfield8 = << >> THEN << >> ELSE message.orderModifiedV2ReturnBitfield8[1])
        \o (IF message.orderModifiedV2ReturnBitfield9 = << >> THEN << >> ELSE EncodeUIntLE(message.orderModifiedV2ReturnBitfield9[1], 1))
        \o (IF message.orderModifiedV2ReturnBitfield10 = << >> THEN << >> ELSE EncodeUIntLE(message.orderModifiedV2ReturnBitfield10[1], 1))
        \o (IF message.orderModifiedV2ReturnBitfield11 = << >> THEN << >> ELSE EncodeUIntLE(message.orderModifiedV2ReturnBitfield11[1], 1))
        \o (IF message.orderModifiedV2ReturnBitfield12 = << >> THEN << >> ELSE message.orderModifiedV2ReturnBitfield12[1])
        \o (IF message.orderModifiedV2ReturnBitfield13 = << >> THEN << >> ELSE message.orderModifiedV2ReturnBitfield13[1])
        \o (IF message.orderModifiedV2ReturnBitfield14 = << >> THEN << >> ELSE message.orderModifiedV2ReturnBitfield14[1])
        \o (IF message.side = << >> THEN << >> ELSE message.side[1])
        \o (IF message.pegDifference = << >> THEN << >> ELSE message.pegDifference[1])
        \o (IF message.price = << >> THEN << >> ELSE message.price[1])
        \o (IF message.execInst = << >> THEN << >> ELSE message.execInst[1])
        \o (IF message.ordType = << >> THEN << >> ELSE message.ordType[1])
        \o (IF message.timeInForce = << >> THEN << >> ELSE message.timeInForce[1])
        \o (IF message.minQty = << >> THEN << >> ELSE message.minQty[1])
        \o (IF message.account = << >> THEN << >> ELSE message.account[1])
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])
        \o (IF message.clearingAccount = << >> THEN << >> ELSE message.clearingAccount[1])
        \o (IF message.displayIndicator = << >> THEN << >> ELSE message.displayIndicator[1])
        \o (IF message.maxFloor = << >> THEN << >> ELSE message.maxFloor[1])
        \o (IF message.orderQty = << >> THEN << >> ELSE message.orderQty[1])
        \o (IF message.preventParticipantMatch = << >> THEN << >> ELSE message.preventParticipantMatch[1])
        \o (IF message.origClOrdId = << >> THEN << >> ELSE message.origClOrdId[1])
        \o (IF message.leavesQty = << >> THEN << >> ELSE message.leavesQty[1])
        \o (IF message.lastShares = << >> THEN << >> ELSE message.lastShares[1])
        \o (IF message.lastPx = << >> THEN << >> ELSE message.lastPx[1])
        \o (IF message.displayPrice = << >> THEN << >> ELSE message.displayPrice[1])
        \o (IF message.workingPrice = << >> THEN << >> ELSE message.workingPrice[1])
        \o (IF message.baseLiquidityIndicator = << >> THEN << >> ELSE message.baseLiquidityIndicator[1])
        \o (IF message.expireTime = << >> THEN << >> ELSE message.expireTime[1])
        \o (IF message.secondaryOrderId = << >> THEN << >> ELSE message.secondaryOrderId[1])
        \o (IF message.liquidityProvision = << >> THEN << >> ELSE message.liquidityProvision[1])
        \o (IF message.waiverType = << >> THEN << >> ELSE message.waiverType[1])
        \o (IF message.priceFormation = << >> THEN << >> ELSE message.priceFormation[1])
        \o (IF message.clientQualifiedRole = << >> THEN << >> ELSE message.clientQualifiedRole[1])
        \o (IF message.clientId = << >> THEN << >> ELSE message.clientId[1])
        \o (IF message.investorId = << >> THEN << >> ELSE message.investorId[1])
        \o (IF message.executorId = << >> THEN << >> ELSE message.executorId[1])
        \o (IF message.orderOrigination = << >> THEN << >> ELSE message.orderOrigination[1])
        \o (IF message.algorithmicIndicator = << >> THEN << >> ELSE message.algorithmicIndicator[1])
        \o (IF message.deferralReason = << >> THEN << >> ELSE message.deferralReason[1])
        \o (IF message.investorQualifiedRole = << >> THEN << >> ELSE message.investorQualifiedRole[1])
        \o (IF message.executorQualifiedRole = << >> THEN << >> ELSE message.executorQualifiedRole[1])

DecodeOrderModifiedV2Message(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clOrdId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(orderId.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET numberOfReturnBitfields == ReadUIntBE(reserved1.rest, 1) IN IF ~numberOfReturnBitfields.ok THEN Fail ELSE
    LET orderModifiedV2ReturnBitfield1 == ReadWhen(numberOfReturnBitfields.value >= 1, ReadUIntLE(numberOfReturnBitfields.rest, 1), numberOfReturnBitfields.rest) IN IF ~orderModifiedV2ReturnBitfield1.ok THEN Fail ELSE
    LET orderModifiedV2ReturnBitfield2 == ReadWhen(numberOfReturnBitfields.value >= 2, ReadBytes(orderModifiedV2ReturnBitfield1.rest, 1), orderModifiedV2ReturnBitfield1.rest) IN IF ~orderModifiedV2ReturnBitfield2.ok THEN Fail ELSE
    LET orderModifiedV2ReturnBitfield3 == ReadWhen(numberOfReturnBitfields.value >= 3, ReadUIntLE(orderModifiedV2ReturnBitfield2.rest, 1), orderModifiedV2ReturnBitfield2.rest) IN IF ~orderModifiedV2ReturnBitfield3.ok THEN Fail ELSE
    LET orderModifiedV2ReturnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadBytes(orderModifiedV2ReturnBitfield3.rest, 1), orderModifiedV2ReturnBitfield3.rest) IN IF ~orderModifiedV2ReturnBitfield4.ok THEN Fail ELSE
    LET orderModifiedV2ReturnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadUIntLE(orderModifiedV2ReturnBitfield4.rest, 1), orderModifiedV2ReturnBitfield4.rest) IN IF ~orderModifiedV2ReturnBitfield5.ok THEN Fail ELSE
    LET orderModifiedV2ReturnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadUIntLE(orderModifiedV2ReturnBitfield5.rest, 1), orderModifiedV2ReturnBitfield5.rest) IN IF ~orderModifiedV2ReturnBitfield6.ok THEN Fail ELSE
    LET orderModifiedV2ReturnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadBytes(orderModifiedV2ReturnBitfield6.rest, 1), orderModifiedV2ReturnBitfield6.rest) IN IF ~orderModifiedV2ReturnBitfield7.ok THEN Fail ELSE
    LET orderModifiedV2ReturnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadBytes(orderModifiedV2ReturnBitfield7.rest, 1), orderModifiedV2ReturnBitfield7.rest) IN IF ~orderModifiedV2ReturnBitfield8.ok THEN Fail ELSE
    LET orderModifiedV2ReturnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadUIntLE(orderModifiedV2ReturnBitfield8.rest, 1), orderModifiedV2ReturnBitfield8.rest) IN IF ~orderModifiedV2ReturnBitfield9.ok THEN Fail ELSE
    LET orderModifiedV2ReturnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadUIntLE(orderModifiedV2ReturnBitfield9.rest, 1), orderModifiedV2ReturnBitfield9.rest) IN IF ~orderModifiedV2ReturnBitfield10.ok THEN Fail ELSE
    LET orderModifiedV2ReturnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadUIntLE(orderModifiedV2ReturnBitfield10.rest, 1), orderModifiedV2ReturnBitfield10.rest) IN IF ~orderModifiedV2ReturnBitfield11.ok THEN Fail ELSE
    LET orderModifiedV2ReturnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadBytes(orderModifiedV2ReturnBitfield11.rest, 1), orderModifiedV2ReturnBitfield11.rest) IN IF ~orderModifiedV2ReturnBitfield12.ok THEN Fail ELSE
    LET orderModifiedV2ReturnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(orderModifiedV2ReturnBitfield12.rest, 1), orderModifiedV2ReturnBitfield12.rest) IN IF ~orderModifiedV2ReturnBitfield13.ok THEN Fail ELSE
    LET orderModifiedV2ReturnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(orderModifiedV2ReturnBitfield13.rest, 1), orderModifiedV2ReturnBitfield13.rest) IN IF ~orderModifiedV2ReturnBitfield14.ok THEN Fail ELSE
    LET side == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderModifiedV2ReturnBitfield1.value # << >> /\ orderModifiedV2ReturnBitfield1.value[1] % 2 > 0), ReadBytes(orderModifiedV2ReturnBitfield14.rest, 1), orderModifiedV2ReturnBitfield14.rest) IN IF ~side.ok THEN Fail ELSE
    LET pegDifference == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderModifiedV2ReturnBitfield1.value # << >> /\ (orderModifiedV2ReturnBitfield1.value[1] \div 2) % 2 > 0), ReadBytes(side.rest, 8), side.rest) IN IF ~pegDifference.ok THEN Fail ELSE
    LET price == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderModifiedV2ReturnBitfield1.value # << >> /\ (orderModifiedV2ReturnBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(pegDifference.rest, 8), pegDifference.rest) IN IF ~price.ok THEN Fail ELSE
    LET execInst == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderModifiedV2ReturnBitfield1.value # << >> /\ (orderModifiedV2ReturnBitfield1.value[1] \div 8) % 2 > 0), ReadBytes(price.rest, 1), price.rest) IN IF ~execInst.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderModifiedV2ReturnBitfield1.value # << >> /\ (orderModifiedV2ReturnBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(execInst.rest, 1), execInst.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderModifiedV2ReturnBitfield1.value # << >> /\ (orderModifiedV2ReturnBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderModifiedV2ReturnBitfield1.value # << >> /\ (orderModifiedV2ReturnBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET account == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderModifiedV2ReturnBitfield3.value # << >> /\ orderModifiedV2ReturnBitfield3.value[1] % 2 > 0), ReadBytes(minQty.rest, 16), minQty.rest) IN IF ~account.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderModifiedV2ReturnBitfield3.value # << >> /\ (orderModifiedV2ReturnBitfield3.value[1] \div 2) % 2 > 0), ReadBytes(account.rest, 4), account.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderModifiedV2ReturnBitfield3.value # << >> /\ (orderModifiedV2ReturnBitfield3.value[1] \div 4) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET displayIndicator == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderModifiedV2ReturnBitfield3.value # << >> /\ (orderModifiedV2ReturnBitfield3.value[1] \div 8) % 2 > 0), ReadBytes(clearingAccount.rest, 1), clearingAccount.rest) IN IF ~displayIndicator.ok THEN Fail ELSE
    LET maxFloor == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderModifiedV2ReturnBitfield3.value # << >> /\ (orderModifiedV2ReturnBitfield3.value[1] \div 16) % 2 > 0), ReadBytes(displayIndicator.rest, 4), displayIndicator.rest) IN IF ~maxFloor.ok THEN Fail ELSE
    LET orderQty == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderModifiedV2ReturnBitfield3.value # << >> /\ (orderModifiedV2ReturnBitfield3.value[1] \div 64) % 2 > 0), ReadBytes(maxFloor.rest, 4), maxFloor.rest) IN IF ~orderQty.ok THEN Fail ELSE
    LET preventParticipantMatch == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderModifiedV2ReturnBitfield3.value # << >> /\ (orderModifiedV2ReturnBitfield3.value[1] \div 128) % 2 > 0), ReadBytes(orderQty.rest, 3), orderQty.rest) IN IF ~preventParticipantMatch.ok THEN Fail ELSE
    LET origClOrdId == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderModifiedV2ReturnBitfield5.value # << >> /\ orderModifiedV2ReturnBitfield5.value[1] % 2 > 0), ReadBytes(preventParticipantMatch.rest, 20), preventParticipantMatch.rest) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET leavesQty == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderModifiedV2ReturnBitfield5.value # << >> /\ (orderModifiedV2ReturnBitfield5.value[1] \div 2) % 2 > 0), ReadBytes(origClOrdId.rest, 4), origClOrdId.rest) IN IF ~leavesQty.ok THEN Fail ELSE
    LET lastShares == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderModifiedV2ReturnBitfield5.value # << >> /\ (orderModifiedV2ReturnBitfield5.value[1] \div 4) % 2 > 0), ReadBytes(leavesQty.rest, 4), leavesQty.rest) IN IF ~lastShares.ok THEN Fail ELSE
    LET lastPx == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderModifiedV2ReturnBitfield5.value # << >> /\ (orderModifiedV2ReturnBitfield5.value[1] \div 8) % 2 > 0), ReadBytes(lastShares.rest, 8), lastShares.rest) IN IF ~lastPx.ok THEN Fail ELSE
    LET displayPrice == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderModifiedV2ReturnBitfield5.value # << >> /\ (orderModifiedV2ReturnBitfield5.value[1] \div 16) % 2 > 0), ReadBytes(lastPx.rest, 8), lastPx.rest) IN IF ~displayPrice.ok THEN Fail ELSE
    LET workingPrice == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderModifiedV2ReturnBitfield5.value # << >> /\ (orderModifiedV2ReturnBitfield5.value[1] \div 32) % 2 > 0), ReadBytes(displayPrice.rest, 8), displayPrice.rest) IN IF ~workingPrice.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderModifiedV2ReturnBitfield5.value # << >> /\ (orderModifiedV2ReturnBitfield5.value[1] \div 64) % 2 > 0), ReadBytes(workingPrice.rest, 1), workingPrice.rest) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET expireTime == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderModifiedV2ReturnBitfield5.value # << >> /\ (orderModifiedV2ReturnBitfield5.value[1] \div 128) % 2 > 0), ReadBytes(baseLiquidityIndicator.rest, 8), baseLiquidityIndicator.rest) IN IF ~expireTime.ok THEN Fail ELSE
    LET secondaryOrderId == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (orderModifiedV2ReturnBitfield6.value # << >> /\ orderModifiedV2ReturnBitfield6.value[1] % 2 > 0), ReadBytes(expireTime.rest, 8), expireTime.rest) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET liquidityProvision == ReadWhen(numberOfReturnBitfields.value >= 9 /\ (orderModifiedV2ReturnBitfield9.value # << >> /\ (orderModifiedV2ReturnBitfield9.value[1] \div 16) % 2 > 0), ReadBytes(secondaryOrderId.rest, 1), secondaryOrderId.rest) IN IF ~liquidityProvision.ok THEN Fail ELSE
    LET waiverType == ReadWhen(numberOfReturnBitfields.value >= 10 /\ (orderModifiedV2ReturnBitfield10.value # << >> /\ (orderModifiedV2ReturnBitfield10.value[1] \div 16) % 2 > 0), ReadBytes(liquidityProvision.rest, 1), liquidityProvision.rest) IN IF ~waiverType.ok THEN Fail ELSE
    LET priceFormation == ReadWhen(numberOfReturnBitfields.value >= 10 /\ (orderModifiedV2ReturnBitfield10.value # << >> /\ (orderModifiedV2ReturnBitfield10.value[1] \div 64) % 2 > 0), ReadBytes(waiverType.rest, 1), waiverType.rest) IN IF ~priceFormation.ok THEN Fail ELSE
    LET clientQualifiedRole == ReadWhen(numberOfReturnBitfields.value >= 10 /\ (orderModifiedV2ReturnBitfield10.value # << >> /\ (orderModifiedV2ReturnBitfield10.value[1] \div 128) % 2 > 0), ReadBytes(priceFormation.rest, 1), priceFormation.rest) IN IF ~clientQualifiedRole.ok THEN Fail ELSE
    LET clientId == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (orderModifiedV2ReturnBitfield11.value # << >> /\ orderModifiedV2ReturnBitfield11.value[1] % 2 > 0), ReadBytes(clientQualifiedRole.rest, 4), clientQualifiedRole.rest) IN IF ~clientId.ok THEN Fail ELSE
    LET investorId == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (orderModifiedV2ReturnBitfield11.value # << >> /\ (orderModifiedV2ReturnBitfield11.value[1] \div 2) % 2 > 0), ReadBytes(clientId.rest, 4), clientId.rest) IN IF ~investorId.ok THEN Fail ELSE
    LET executorId == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (orderModifiedV2ReturnBitfield11.value # << >> /\ (orderModifiedV2ReturnBitfield11.value[1] \div 4) % 2 > 0), ReadBytes(investorId.rest, 4), investorId.rest) IN IF ~executorId.ok THEN Fail ELSE
    LET orderOrigination == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (orderModifiedV2ReturnBitfield11.value # << >> /\ (orderModifiedV2ReturnBitfield11.value[1] \div 8) % 2 > 0), ReadBytes(executorId.rest, 1), executorId.rest) IN IF ~orderOrigination.ok THEN Fail ELSE
    LET algorithmicIndicator == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (orderModifiedV2ReturnBitfield11.value # << >> /\ (orderModifiedV2ReturnBitfield11.value[1] \div 16) % 2 > 0), ReadBytes(orderOrigination.rest, 1), orderOrigination.rest) IN IF ~algorithmicIndicator.ok THEN Fail ELSE
    LET deferralReason == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (orderModifiedV2ReturnBitfield11.value # << >> /\ (orderModifiedV2ReturnBitfield11.value[1] \div 32) % 2 > 0), ReadBytes(algorithmicIndicator.rest, 1), algorithmicIndicator.rest) IN IF ~deferralReason.ok THEN Fail ELSE
    LET investorQualifiedRole == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (orderModifiedV2ReturnBitfield11.value # << >> /\ (orderModifiedV2ReturnBitfield11.value[1] \div 64) % 2 > 0), ReadBytes(deferralReason.rest, 1), deferralReason.rest) IN IF ~investorQualifiedRole.ok THEN Fail ELSE
    LET executorQualifiedRole == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (orderModifiedV2ReturnBitfield11.value # << >> /\ (orderModifiedV2ReturnBitfield11.value[1] \div 128) % 2 > 0), ReadBytes(investorQualifiedRole.rest, 1), investorQualifiedRole.rest) IN IF ~executorQualifiedRole.ok THEN Fail ELSE
    Ok([ transactionTime                 |-> transactionTime.value,
         clOrdId                         |-> clOrdId.value,
         orderId                         |-> orderId.value,
         reserved1                       |-> reserved1.value,
         numberOfReturnBitfields         |-> numberOfReturnBitfields.value,
         orderModifiedV2ReturnBitfield1  |-> orderModifiedV2ReturnBitfield1.value,
         orderModifiedV2ReturnBitfield2  |-> orderModifiedV2ReturnBitfield2.value,
         orderModifiedV2ReturnBitfield3  |-> orderModifiedV2ReturnBitfield3.value,
         orderModifiedV2ReturnBitfield4  |-> orderModifiedV2ReturnBitfield4.value,
         orderModifiedV2ReturnBitfield5  |-> orderModifiedV2ReturnBitfield5.value,
         orderModifiedV2ReturnBitfield6  |-> orderModifiedV2ReturnBitfield6.value,
         orderModifiedV2ReturnBitfield7  |-> orderModifiedV2ReturnBitfield7.value,
         orderModifiedV2ReturnBitfield8  |-> orderModifiedV2ReturnBitfield8.value,
         orderModifiedV2ReturnBitfield9  |-> orderModifiedV2ReturnBitfield9.value,
         orderModifiedV2ReturnBitfield10 |-> orderModifiedV2ReturnBitfield10.value,
         orderModifiedV2ReturnBitfield11 |-> orderModifiedV2ReturnBitfield11.value,
         orderModifiedV2ReturnBitfield12 |-> orderModifiedV2ReturnBitfield12.value,
         orderModifiedV2ReturnBitfield13 |-> orderModifiedV2ReturnBitfield13.value,
         orderModifiedV2ReturnBitfield14 |-> orderModifiedV2ReturnBitfield14.value,
         side                            |-> side.value,
         pegDifference                   |-> pegDifference.value,
         price                           |-> price.value,
         execInst                        |-> execInst.value,
         ordType                         |-> ordType.value,
         timeInForce                     |-> timeInForce.value,
         minQty                          |-> minQty.value,
         account                         |-> account.value,
         clearingFirm                    |-> clearingFirm.value,
         clearingAccount                 |-> clearingAccount.value,
         displayIndicator                |-> displayIndicator.value,
         maxFloor                        |-> maxFloor.value,
         orderQty                        |-> orderQty.value,
         preventParticipantMatch         |-> preventParticipantMatch.value,
         origClOrdId                     |-> origClOrdId.value,
         leavesQty                       |-> leavesQty.value,
         lastShares                      |-> lastShares.value,
         lastPx                          |-> lastPx.value,
         displayPrice                    |-> displayPrice.value,
         workingPrice                    |-> workingPrice.value,
         baseLiquidityIndicator          |-> baseLiquidityIndicator.value,
         expireTime                      |-> expireTime.value,
         secondaryOrderId                |-> secondaryOrderId.value,
         liquidityProvision              |-> liquidityProvision.value,
         waiverType                      |-> waiverType.value,
         priceFormation                  |-> priceFormation.value,
         clientQualifiedRole             |-> clientQualifiedRole.value,
         clientId                        |-> clientId.value,
         investorId                      |-> investorId.value,
         executorId                      |-> executorId.value,
         orderOrigination                |-> orderOrigination.value,
         algorithmicIndicator            |-> algorithmicIndicator.value,
         deferralReason                  |-> deferralReason.value,
         investorQualifiedRole           |-> investorQualifiedRole.value,
         executorQualifiedRole           |-> executorQualifiedRole.value ], executorQualifiedRole.rest)

(* Order Modified V 2 Message with each field marked present by fields before it there exactly where they say *)
SettleOrderModifiedV2Message(message) ==
    LET settled1 == [message EXCEPT !.orderModifiedV2ReturnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.orderModifiedV2ReturnBitfield1 = << >> THEN <<0>> ELSE message.orderModifiedV2ReturnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.orderModifiedV2ReturnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.orderModifiedV2ReturnBitfield2 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled1.orderModifiedV2ReturnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.orderModifiedV2ReturnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.orderModifiedV2ReturnBitfield3 = << >> THEN <<0>> ELSE settled2.orderModifiedV2ReturnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.orderModifiedV2ReturnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.orderModifiedV2ReturnBitfield4 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled3.orderModifiedV2ReturnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.orderModifiedV2ReturnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.orderModifiedV2ReturnBitfield5 = << >> THEN <<0>> ELSE settled4.orderModifiedV2ReturnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.orderModifiedV2ReturnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.orderModifiedV2ReturnBitfield6 = << >> THEN <<0>> ELSE settled5.orderModifiedV2ReturnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.orderModifiedV2ReturnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.orderModifiedV2ReturnBitfield7 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.orderModifiedV2ReturnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.orderModifiedV2ReturnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.orderModifiedV2ReturnBitfield8 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled7.orderModifiedV2ReturnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.orderModifiedV2ReturnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.orderModifiedV2ReturnBitfield9 = << >> THEN <<0>> ELSE settled8.orderModifiedV2ReturnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.orderModifiedV2ReturnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.orderModifiedV2ReturnBitfield10 = << >> THEN <<0>> ELSE settled9.orderModifiedV2ReturnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.orderModifiedV2ReturnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.orderModifiedV2ReturnBitfield11 = << >> THEN <<0>> ELSE settled10.orderModifiedV2ReturnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.orderModifiedV2ReturnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.orderModifiedV2ReturnBitfield12 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.orderModifiedV2ReturnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.orderModifiedV2ReturnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.orderModifiedV2ReturnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.orderModifiedV2ReturnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.orderModifiedV2ReturnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.orderModifiedV2ReturnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.orderModifiedV2ReturnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.side = IF settled14.numberOfReturnBitfields >= 1 /\ (settled14.orderModifiedV2ReturnBitfield1 # << >> /\ settled14.orderModifiedV2ReturnBitfield1[1] % 2 > 0) THEN (IF settled14.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.side) ELSE << >>]
        settled16 == [settled15 EXCEPT !.pegDifference = IF settled15.numberOfReturnBitfields >= 1 /\ (settled15.orderModifiedV2ReturnBitfield1 # << >> /\ (settled15.orderModifiedV2ReturnBitfield1[1] \div 2) % 2 > 0) THEN (IF settled15.pegDifference = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled15.pegDifference) ELSE << >>]
        settled17 == [settled16 EXCEPT !.price = IF settled16.numberOfReturnBitfields >= 1 /\ (settled16.orderModifiedV2ReturnBitfield1 # << >> /\ (settled16.orderModifiedV2ReturnBitfield1[1] \div 4) % 2 > 0) THEN (IF settled16.price = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled16.price) ELSE << >>]
        settled18 == [settled17 EXCEPT !.execInst = IF settled17.numberOfReturnBitfields >= 1 /\ (settled17.orderModifiedV2ReturnBitfield1 # << >> /\ (settled17.orderModifiedV2ReturnBitfield1[1] \div 8) % 2 > 0) THEN (IF settled17.execInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.execInst) ELSE << >>]
        settled19 == [settled18 EXCEPT !.ordType = IF settled18.numberOfReturnBitfields >= 1 /\ (settled18.orderModifiedV2ReturnBitfield1 # << >> /\ (settled18.orderModifiedV2ReturnBitfield1[1] \div 16) % 2 > 0) THEN (IF settled18.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled18.ordType) ELSE << >>]
        settled20 == [settled19 EXCEPT !.timeInForce = IF settled19.numberOfReturnBitfields >= 1 /\ (settled19.orderModifiedV2ReturnBitfield1 # << >> /\ (settled19.orderModifiedV2ReturnBitfield1[1] \div 32) % 2 > 0) THEN (IF settled19.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled19.timeInForce) ELSE << >>]
        settled21 == [settled20 EXCEPT !.minQty = IF settled20.numberOfReturnBitfields >= 1 /\ (settled20.orderModifiedV2ReturnBitfield1 # << >> /\ (settled20.orderModifiedV2ReturnBitfield1[1] \div 64) % 2 > 0) THEN (IF settled20.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled20.minQty) ELSE << >>]
        settled22 == [settled21 EXCEPT !.account = IF settled21.numberOfReturnBitfields >= 3 /\ (settled21.orderModifiedV2ReturnBitfield3 # << >> /\ settled21.orderModifiedV2ReturnBitfield3[1] % 2 > 0) THEN (IF settled21.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled21.account) ELSE << >>]
        settled23 == [settled22 EXCEPT !.clearingFirm = IF settled22.numberOfReturnBitfields >= 3 /\ (settled22.orderModifiedV2ReturnBitfield3 # << >> /\ (settled22.orderModifiedV2ReturnBitfield3[1] \div 2) % 2 > 0) THEN (IF settled22.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled22.clearingFirm) ELSE << >>]
        settled24 == [settled23 EXCEPT !.clearingAccount = IF settled23.numberOfReturnBitfields >= 3 /\ (settled23.orderModifiedV2ReturnBitfield3 # << >> /\ (settled23.orderModifiedV2ReturnBitfield3[1] \div 4) % 2 > 0) THEN (IF settled23.clearingAccount = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled23.clearingAccount) ELSE << >>]
        settled25 == [settled24 EXCEPT !.displayIndicator = IF settled24.numberOfReturnBitfields >= 3 /\ (settled24.orderModifiedV2ReturnBitfield3 # << >> /\ (settled24.orderModifiedV2ReturnBitfield3[1] \div 8) % 2 > 0) THEN (IF settled24.displayIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled24.displayIndicator) ELSE << >>]
        settled26 == [settled25 EXCEPT !.maxFloor = IF settled25.numberOfReturnBitfields >= 3 /\ (settled25.orderModifiedV2ReturnBitfield3 # << >> /\ (settled25.orderModifiedV2ReturnBitfield3[1] \div 16) % 2 > 0) THEN (IF settled25.maxFloor = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled25.maxFloor) ELSE << >>]
        settled27 == [settled26 EXCEPT !.orderQty = IF settled26.numberOfReturnBitfields >= 3 /\ (settled26.orderModifiedV2ReturnBitfield3 # << >> /\ (settled26.orderModifiedV2ReturnBitfield3[1] \div 64) % 2 > 0) THEN (IF settled26.orderQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled26.orderQty) ELSE << >>]
        settled28 == [settled27 EXCEPT !.preventParticipantMatch = IF settled27.numberOfReturnBitfields >= 3 /\ (settled27.orderModifiedV2ReturnBitfield3 # << >> /\ (settled27.orderModifiedV2ReturnBitfield3[1] \div 128) % 2 > 0) THEN (IF settled27.preventParticipantMatch = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled27.preventParticipantMatch) ELSE << >>]
        settled29 == [settled28 EXCEPT !.origClOrdId = IF settled28.numberOfReturnBitfields >= 5 /\ (settled28.orderModifiedV2ReturnBitfield5 # << >> /\ settled28.orderModifiedV2ReturnBitfield5[1] % 2 > 0) THEN (IF settled28.origClOrdId = << >> THEN <<[i \in 1 .. 20 |-> 0]>> ELSE settled28.origClOrdId) ELSE << >>]
        settled30 == [settled29 EXCEPT !.leavesQty = IF settled29.numberOfReturnBitfields >= 5 /\ (settled29.orderModifiedV2ReturnBitfield5 # << >> /\ (settled29.orderModifiedV2ReturnBitfield5[1] \div 2) % 2 > 0) THEN (IF settled29.leavesQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled29.leavesQty) ELSE << >>]
        settled31 == [settled30 EXCEPT !.lastShares = IF settled30.numberOfReturnBitfields >= 5 /\ (settled30.orderModifiedV2ReturnBitfield5 # << >> /\ (settled30.orderModifiedV2ReturnBitfield5[1] \div 4) % 2 > 0) THEN (IF settled30.lastShares = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled30.lastShares) ELSE << >>]
        settled32 == [settled31 EXCEPT !.lastPx = IF settled31.numberOfReturnBitfields >= 5 /\ (settled31.orderModifiedV2ReturnBitfield5 # << >> /\ (settled31.orderModifiedV2ReturnBitfield5[1] \div 8) % 2 > 0) THEN (IF settled31.lastPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled31.lastPx) ELSE << >>]
        settled33 == [settled32 EXCEPT !.displayPrice = IF settled32.numberOfReturnBitfields >= 5 /\ (settled32.orderModifiedV2ReturnBitfield5 # << >> /\ (settled32.orderModifiedV2ReturnBitfield5[1] \div 16) % 2 > 0) THEN (IF settled32.displayPrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled32.displayPrice) ELSE << >>]
        settled34 == [settled33 EXCEPT !.workingPrice = IF settled33.numberOfReturnBitfields >= 5 /\ (settled33.orderModifiedV2ReturnBitfield5 # << >> /\ (settled33.orderModifiedV2ReturnBitfield5[1] \div 32) % 2 > 0) THEN (IF settled33.workingPrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled33.workingPrice) ELSE << >>]
        settled35 == [settled34 EXCEPT !.baseLiquidityIndicator = IF settled34.numberOfReturnBitfields >= 5 /\ (settled34.orderModifiedV2ReturnBitfield5 # << >> /\ (settled34.orderModifiedV2ReturnBitfield5[1] \div 64) % 2 > 0) THEN (IF settled34.baseLiquidityIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled34.baseLiquidityIndicator) ELSE << >>]
        settled36 == [settled35 EXCEPT !.expireTime = IF settled35.numberOfReturnBitfields >= 5 /\ (settled35.orderModifiedV2ReturnBitfield5 # << >> /\ (settled35.orderModifiedV2ReturnBitfield5[1] \div 128) % 2 > 0) THEN (IF settled35.expireTime = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled35.expireTime) ELSE << >>]
        settled37 == [settled36 EXCEPT !.secondaryOrderId = IF settled36.numberOfReturnBitfields >= 6 /\ (settled36.orderModifiedV2ReturnBitfield6 # << >> /\ settled36.orderModifiedV2ReturnBitfield6[1] % 2 > 0) THEN (IF settled36.secondaryOrderId = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled36.secondaryOrderId) ELSE << >>]
        settled38 == [settled37 EXCEPT !.liquidityProvision = IF settled37.numberOfReturnBitfields >= 9 /\ (settled37.orderModifiedV2ReturnBitfield9 # << >> /\ (settled37.orderModifiedV2ReturnBitfield9[1] \div 16) % 2 > 0) THEN (IF settled37.liquidityProvision = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled37.liquidityProvision) ELSE << >>]
        settled39 == [settled38 EXCEPT !.waiverType = IF settled38.numberOfReturnBitfields >= 10 /\ (settled38.orderModifiedV2ReturnBitfield10 # << >> /\ (settled38.orderModifiedV2ReturnBitfield10[1] \div 16) % 2 > 0) THEN (IF settled38.waiverType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled38.waiverType) ELSE << >>]
        settled40 == [settled39 EXCEPT !.priceFormation = IF settled39.numberOfReturnBitfields >= 10 /\ (settled39.orderModifiedV2ReturnBitfield10 # << >> /\ (settled39.orderModifiedV2ReturnBitfield10[1] \div 64) % 2 > 0) THEN (IF settled39.priceFormation = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled39.priceFormation) ELSE << >>]
        settled41 == [settled40 EXCEPT !.clientQualifiedRole = IF settled40.numberOfReturnBitfields >= 10 /\ (settled40.orderModifiedV2ReturnBitfield10 # << >> /\ (settled40.orderModifiedV2ReturnBitfield10[1] \div 128) % 2 > 0) THEN (IF settled40.clientQualifiedRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled40.clientQualifiedRole) ELSE << >>]
        settled42 == [settled41 EXCEPT !.clientId = IF settled41.numberOfReturnBitfields >= 11 /\ (settled41.orderModifiedV2ReturnBitfield11 # << >> /\ settled41.orderModifiedV2ReturnBitfield11[1] % 2 > 0) THEN (IF settled41.clientId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled41.clientId) ELSE << >>]
        settled43 == [settled42 EXCEPT !.investorId = IF settled42.numberOfReturnBitfields >= 11 /\ (settled42.orderModifiedV2ReturnBitfield11 # << >> /\ (settled42.orderModifiedV2ReturnBitfield11[1] \div 2) % 2 > 0) THEN (IF settled42.investorId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled42.investorId) ELSE << >>]
        settled44 == [settled43 EXCEPT !.executorId = IF settled43.numberOfReturnBitfields >= 11 /\ (settled43.orderModifiedV2ReturnBitfield11 # << >> /\ (settled43.orderModifiedV2ReturnBitfield11[1] \div 4) % 2 > 0) THEN (IF settled43.executorId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled43.executorId) ELSE << >>]
        settled45 == [settled44 EXCEPT !.orderOrigination = IF settled44.numberOfReturnBitfields >= 11 /\ (settled44.orderModifiedV2ReturnBitfield11 # << >> /\ (settled44.orderModifiedV2ReturnBitfield11[1] \div 8) % 2 > 0) THEN (IF settled44.orderOrigination = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled44.orderOrigination) ELSE << >>]
        settled46 == [settled45 EXCEPT !.algorithmicIndicator = IF settled45.numberOfReturnBitfields >= 11 /\ (settled45.orderModifiedV2ReturnBitfield11 # << >> /\ (settled45.orderModifiedV2ReturnBitfield11[1] \div 16) % 2 > 0) THEN (IF settled45.algorithmicIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled45.algorithmicIndicator) ELSE << >>]
        settled47 == [settled46 EXCEPT !.deferralReason = IF settled46.numberOfReturnBitfields >= 11 /\ (settled46.orderModifiedV2ReturnBitfield11 # << >> /\ (settled46.orderModifiedV2ReturnBitfield11[1] \div 32) % 2 > 0) THEN (IF settled46.deferralReason = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled46.deferralReason) ELSE << >>]
        settled48 == [settled47 EXCEPT !.investorQualifiedRole = IF settled47.numberOfReturnBitfields >= 11 /\ (settled47.orderModifiedV2ReturnBitfield11 # << >> /\ (settled47.orderModifiedV2ReturnBitfield11[1] \div 64) % 2 > 0) THEN (IF settled47.investorQualifiedRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled47.investorQualifiedRole) ELSE << >>]
        settled49 == [settled48 EXCEPT !.executorQualifiedRole = IF settled48.numberOfReturnBitfields >= 11 /\ (settled48.orderModifiedV2ReturnBitfield11 # << >> /\ (settled48.orderModifiedV2ReturnBitfield11[1] \div 128) % 2 > 0) THEN (IF settled48.executorQualifiedRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled48.executorQualifiedRole) ELSE << >>]
    IN  settled49

ZeroOrderModifiedV2Message ==
    SettleOrderModifiedV2Message([ transactionTime                 |-> [i \in 1 .. 8 |-> 0],
                                   clOrdId                         |-> [i \in 1 .. 20 |-> 0],
                                   orderId                         |-> [i \in 1 .. 8 |-> 0],
                                   reserved1                       |-> [i \in 1 .. 1 |-> 0],
                                   numberOfReturnBitfields         |-> 0,
                                   orderModifiedV2ReturnBitfield1  |-> << >>,
                                   orderModifiedV2ReturnBitfield2  |-> << >>,
                                   orderModifiedV2ReturnBitfield3  |-> << >>,
                                   orderModifiedV2ReturnBitfield4  |-> << >>,
                                   orderModifiedV2ReturnBitfield5  |-> << >>,
                                   orderModifiedV2ReturnBitfield6  |-> << >>,
                                   orderModifiedV2ReturnBitfield7  |-> << >>,
                                   orderModifiedV2ReturnBitfield8  |-> << >>,
                                   orderModifiedV2ReturnBitfield9  |-> << >>,
                                   orderModifiedV2ReturnBitfield10 |-> << >>,
                                   orderModifiedV2ReturnBitfield11 |-> << >>,
                                   orderModifiedV2ReturnBitfield12 |-> << >>,
                                   orderModifiedV2ReturnBitfield13 |-> << >>,
                                   orderModifiedV2ReturnBitfield14 |-> << >>,
                                   side                            |-> << >>,
                                   pegDifference                   |-> << >>,
                                   price                           |-> << >>,
                                   execInst                        |-> << >>,
                                   ordType                         |-> << >>,
                                   timeInForce                     |-> << >>,
                                   minQty                          |-> << >>,
                                   account                         |-> << >>,
                                   clearingFirm                    |-> << >>,
                                   clearingAccount                 |-> << >>,
                                   displayIndicator                |-> << >>,
                                   maxFloor                        |-> << >>,
                                   orderQty                        |-> << >>,
                                   preventParticipantMatch         |-> << >>,
                                   origClOrdId                     |-> << >>,
                                   leavesQty                       |-> << >>,
                                   lastShares                      |-> << >>,
                                   lastPx                          |-> << >>,
                                   displayPrice                    |-> << >>,
                                   workingPrice                    |-> << >>,
                                   baseLiquidityIndicator          |-> << >>,
                                   expireTime                      |-> << >>,
                                   secondaryOrderId                |-> << >>,
                                   liquidityProvision              |-> << >>,
                                   waiverType                      |-> << >>,
                                   priceFormation                  |-> << >>,
                                   clientQualifiedRole             |-> << >>,
                                   clientId                        |-> << >>,
                                   investorId                      |-> << >>,
                                   executorId                      |-> << >>,
                                   orderOrigination                |-> << >>,
                                   algorithmicIndicator            |-> << >>,
                                   deferralReason                  |-> << >>,
                                   investorQualifiedRole           |-> << >>,
                                   executorQualifiedRole           |-> << >> ])

(* Order Modified V 2 Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderModifiedV2Message ==
    { ZeroOrderModifiedV2Message }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.transactionTime = one]) : one \in Sample(8) }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.clOrdId = one]) : one \in Sample(20) }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.orderId = one]) : one \in Sample(8) }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.reserved1 = one]) : one \in Sample(1) }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderModifiedV2ReturnBitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 2, !.orderModifiedV2ReturnBitfield2 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderModifiedV2ReturnBitfield3 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 4, !.orderModifiedV2ReturnBitfield4 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 5, !.orderModifiedV2ReturnBitfield5 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 6, !.orderModifiedV2ReturnBitfield6 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 7, !.orderModifiedV2ReturnBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 8, !.orderModifiedV2ReturnBitfield8 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 9, !.orderModifiedV2ReturnBitfield9 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 10, !.orderModifiedV2ReturnBitfield10 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderModifiedV2ReturnBitfield11 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 12, !.orderModifiedV2ReturnBitfield12 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 13, !.orderModifiedV2ReturnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 14, !.orderModifiedV2ReturnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderModifiedV2ReturnBitfield1 = <<1>>, !.side = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderModifiedV2ReturnBitfield1 = <<2>>, !.pegDifference = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderModifiedV2ReturnBitfield1 = <<4>>, !.price = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderModifiedV2ReturnBitfield1 = <<8>>, !.execInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderModifiedV2ReturnBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderModifiedV2ReturnBitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderModifiedV2ReturnBitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderModifiedV2ReturnBitfield3 = <<1>>, !.account = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderModifiedV2ReturnBitfield3 = <<2>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderModifiedV2ReturnBitfield3 = <<4>>, !.clearingAccount = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderModifiedV2ReturnBitfield3 = <<8>>, !.displayIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderModifiedV2ReturnBitfield3 = <<16>>, !.maxFloor = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderModifiedV2ReturnBitfield3 = <<64>>, !.orderQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderModifiedV2ReturnBitfield3 = <<128>>, !.preventParticipantMatch = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 5, !.orderModifiedV2ReturnBitfield5 = <<1>>, !.origClOrdId = one]) : one \in { <<held>> : held \in Sample(20) } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 5, !.orderModifiedV2ReturnBitfield5 = <<2>>, !.leavesQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 5, !.orderModifiedV2ReturnBitfield5 = <<4>>, !.lastShares = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 5, !.orderModifiedV2ReturnBitfield5 = <<8>>, !.lastPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 5, !.orderModifiedV2ReturnBitfield5 = <<16>>, !.displayPrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 5, !.orderModifiedV2ReturnBitfield5 = <<32>>, !.workingPrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 5, !.orderModifiedV2ReturnBitfield5 = <<64>>, !.baseLiquidityIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 5, !.orderModifiedV2ReturnBitfield5 = <<128>>, !.expireTime = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 6, !.orderModifiedV2ReturnBitfield6 = <<1>>, !.secondaryOrderId = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 9, !.orderModifiedV2ReturnBitfield9 = <<16>>, !.liquidityProvision = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 10, !.orderModifiedV2ReturnBitfield10 = <<16>>, !.waiverType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 10, !.orderModifiedV2ReturnBitfield10 = <<64>>, !.priceFormation = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 10, !.orderModifiedV2ReturnBitfield10 = <<128>>, !.clientQualifiedRole = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderModifiedV2ReturnBitfield11 = <<1>>, !.clientId = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderModifiedV2ReturnBitfield11 = <<2>>, !.investorId = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderModifiedV2ReturnBitfield11 = <<4>>, !.executorId = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderModifiedV2ReturnBitfield11 = <<8>>, !.orderOrigination = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderModifiedV2ReturnBitfield11 = <<16>>, !.algorithmicIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderModifiedV2ReturnBitfield11 = <<32>>, !.deferralReason = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderModifiedV2ReturnBitfield11 = <<64>>, !.investorQualifiedRole = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedV2Message([ZeroOrderModifiedV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderModifiedV2ReturnBitfield11 = <<128>>, !.executorQualifiedRole = one]) : one \in { <<held>> : held \in Sample(1) } }

(***************************************************************************)
(* Order Restated V 2 Message                                              *)
(***************************************************************************)

OrderRestatedV2Message ==
    [ transactionTime                 : Sample(8),
      clOrdId                         : Sample(20),
      orderId                         : Sample(8),
      restatementReason               : Sample(1),
      reserved1                       : Sample(1),
      numberOfReturnBitfields         : 0 .. 255,
      orderRestatedV2ReturnBitfield1  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderRestatedV2ReturnBitfield2  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderRestatedV2ReturnBitfield3  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderRestatedV2ReturnBitfield4  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRestatedV2ReturnBitfield5  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderRestatedV2ReturnBitfield6  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderRestatedV2ReturnBitfield7  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRestatedV2ReturnBitfield8  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRestatedV2ReturnBitfield9  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderRestatedV2ReturnBitfield10 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderRestatedV2ReturnBitfield11 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderRestatedV2ReturnBitfield12 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRestatedV2ReturnBitfield13 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRestatedV2ReturnBitfield14 : { << >> } \cup { <<held>> : held \in Sample(1) },
      side                            : { << >> } \cup { <<held>> : held \in Sample(1) },
      pegDifference                   : { << >> } \cup { <<held>> : held \in Sample(8) },
      price                           : { << >> } \cup { <<held>> : held \in Sample(8) },
      execInst                        : { << >> } \cup { <<held>> : held \in Sample(1) },
      ordType                         : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce                     : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                          : { << >> } \cup { <<held>> : held \in Sample(4) },
      symbol                          : { << >> } \cup { <<held>> : held \in Sample(8) },
      currency                        : { << >> } \cup { <<held>> : held \in Sample(3) },
      idSource                        : { << >> } \cup { <<held>> : held \in Sample(1) },
      securityId                      : { << >> } \cup { <<held>> : held \in Sample(16) },
      securityExchange                : { << >> } \cup { <<held>> : held \in Sample(4) },
      capacity                        : { << >> } \cup { <<held>> : held \in Sample(1) },
      account                         : { << >> } \cup { <<held>> : held \in Sample(16) },
      clearingFirm                    : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingAccount                 : { << >> } \cup { <<held>> : held \in Sample(4) },
      displayIndicator                : { << >> } \cup { <<held>> : held \in Sample(1) },
      maxFloor                        : { << >> } \cup { <<held>> : held \in Sample(4) },
      orderQty                        : { << >> } \cup { <<held>> : held \in Sample(4) },
      preventParticipantMatch         : { << >> } \cup { <<held>> : held \in Sample(3) },
      origClOrdId                     : { << >> } \cup { <<held>> : held \in Sample(20) },
      leavesQty                       : { << >> } \cup { <<held>> : held \in Sample(4) },
      lastShares                      : { << >> } \cup { <<held>> : held \in Sample(4) },
      lastPx                          : { << >> } \cup { <<held>> : held \in Sample(8) },
      displayPrice                    : { << >> } \cup { <<held>> : held \in Sample(8) },
      workingPrice                    : { << >> } \cup { <<held>> : held \in Sample(8) },
      baseLiquidityIndicator          : { << >> } \cup { <<held>> : held \in Sample(1) },
      expireTime                      : { << >> } \cup { <<held>> : held \in Sample(8) },
      secondaryOrderId                : { << >> } \cup { <<held>> : held \in Sample(8) },
      liquidityProvision              : { << >> } \cup { <<held>> : held \in Sample(1) },
      waiverType                      : { << >> } \cup { <<held>> : held \in Sample(1) },
      priceFormation                  : { << >> } \cup { <<held>> : held \in Sample(1) },
      clientQualifiedRole             : { << >> } \cup { <<held>> : held \in Sample(1) },
      clientId                        : { << >> } \cup { <<held>> : held \in Sample(4) },
      investorId                      : { << >> } \cup { <<held>> : held \in Sample(4) },
      executorId                      : { << >> } \cup { <<held>> : held \in Sample(4) },
      orderOrigination                : { << >> } \cup { <<held>> : held \in Sample(1) },
      algorithmicIndicator            : { << >> } \cup { <<held>> : held \in Sample(1) },
      deferralReason                  : { << >> } \cup { <<held>> : held \in Sample(1) },
      investorQualifiedRole           : { << >> } \cup { <<held>> : held \in Sample(1) },
      executorQualifiedRole           : { << >> } \cup { <<held>> : held \in Sample(1) } ]

EncodeOrderRestatedV2Message(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.orderId
        \o message.restatementReason
        \o message.reserved1
        \o EncodeUIntBE(message.numberOfReturnBitfields, 1)
        \o (IF message.orderRestatedV2ReturnBitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.orderRestatedV2ReturnBitfield1[1], 1))
        \o (IF message.orderRestatedV2ReturnBitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.orderRestatedV2ReturnBitfield2[1], 1))
        \o (IF message.orderRestatedV2ReturnBitfield3 = << >> THEN << >> ELSE EncodeUIntLE(message.orderRestatedV2ReturnBitfield3[1], 1))
        \o (IF message.orderRestatedV2ReturnBitfield4 = << >> THEN << >> ELSE message.orderRestatedV2ReturnBitfield4[1])
        \o (IF message.orderRestatedV2ReturnBitfield5 = << >> THEN << >> ELSE EncodeUIntLE(message.orderRestatedV2ReturnBitfield5[1], 1))
        \o (IF message.orderRestatedV2ReturnBitfield6 = << >> THEN << >> ELSE EncodeUIntLE(message.orderRestatedV2ReturnBitfield6[1], 1))
        \o (IF message.orderRestatedV2ReturnBitfield7 = << >> THEN << >> ELSE message.orderRestatedV2ReturnBitfield7[1])
        \o (IF message.orderRestatedV2ReturnBitfield8 = << >> THEN << >> ELSE message.orderRestatedV2ReturnBitfield8[1])
        \o (IF message.orderRestatedV2ReturnBitfield9 = << >> THEN << >> ELSE EncodeUIntLE(message.orderRestatedV2ReturnBitfield9[1], 1))
        \o (IF message.orderRestatedV2ReturnBitfield10 = << >> THEN << >> ELSE EncodeUIntLE(message.orderRestatedV2ReturnBitfield10[1], 1))
        \o (IF message.orderRestatedV2ReturnBitfield11 = << >> THEN << >> ELSE EncodeUIntLE(message.orderRestatedV2ReturnBitfield11[1], 1))
        \o (IF message.orderRestatedV2ReturnBitfield12 = << >> THEN << >> ELSE message.orderRestatedV2ReturnBitfield12[1])
        \o (IF message.orderRestatedV2ReturnBitfield13 = << >> THEN << >> ELSE message.orderRestatedV2ReturnBitfield13[1])
        \o (IF message.orderRestatedV2ReturnBitfield14 = << >> THEN << >> ELSE message.orderRestatedV2ReturnBitfield14[1])
        \o (IF message.side = << >> THEN << >> ELSE message.side[1])
        \o (IF message.pegDifference = << >> THEN << >> ELSE message.pegDifference[1])
        \o (IF message.price = << >> THEN << >> ELSE message.price[1])
        \o (IF message.execInst = << >> THEN << >> ELSE message.execInst[1])
        \o (IF message.ordType = << >> THEN << >> ELSE message.ordType[1])
        \o (IF message.timeInForce = << >> THEN << >> ELSE message.timeInForce[1])
        \o (IF message.minQty = << >> THEN << >> ELSE message.minQty[1])
        \o (IF message.symbol = << >> THEN << >> ELSE message.symbol[1])
        \o (IF message.currency = << >> THEN << >> ELSE message.currency[1])
        \o (IF message.idSource = << >> THEN << >> ELSE message.idSource[1])
        \o (IF message.securityId = << >> THEN << >> ELSE message.securityId[1])
        \o (IF message.securityExchange = << >> THEN << >> ELSE message.securityExchange[1])
        \o (IF message.capacity = << >> THEN << >> ELSE message.capacity[1])
        \o (IF message.account = << >> THEN << >> ELSE message.account[1])
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])
        \o (IF message.clearingAccount = << >> THEN << >> ELSE message.clearingAccount[1])
        \o (IF message.displayIndicator = << >> THEN << >> ELSE message.displayIndicator[1])
        \o (IF message.maxFloor = << >> THEN << >> ELSE message.maxFloor[1])
        \o (IF message.orderQty = << >> THEN << >> ELSE message.orderQty[1])
        \o (IF message.preventParticipantMatch = << >> THEN << >> ELSE message.preventParticipantMatch[1])
        \o (IF message.origClOrdId = << >> THEN << >> ELSE message.origClOrdId[1])
        \o (IF message.leavesQty = << >> THEN << >> ELSE message.leavesQty[1])
        \o (IF message.lastShares = << >> THEN << >> ELSE message.lastShares[1])
        \o (IF message.lastPx = << >> THEN << >> ELSE message.lastPx[1])
        \o (IF message.displayPrice = << >> THEN << >> ELSE message.displayPrice[1])
        \o (IF message.workingPrice = << >> THEN << >> ELSE message.workingPrice[1])
        \o (IF message.baseLiquidityIndicator = << >> THEN << >> ELSE message.baseLiquidityIndicator[1])
        \o (IF message.expireTime = << >> THEN << >> ELSE message.expireTime[1])
        \o (IF message.secondaryOrderId = << >> THEN << >> ELSE message.secondaryOrderId[1])
        \o (IF message.liquidityProvision = << >> THEN << >> ELSE message.liquidityProvision[1])
        \o (IF message.waiverType = << >> THEN << >> ELSE message.waiverType[1])
        \o (IF message.priceFormation = << >> THEN << >> ELSE message.priceFormation[1])
        \o (IF message.clientQualifiedRole = << >> THEN << >> ELSE message.clientQualifiedRole[1])
        \o (IF message.clientId = << >> THEN << >> ELSE message.clientId[1])
        \o (IF message.investorId = << >> THEN << >> ELSE message.investorId[1])
        \o (IF message.executorId = << >> THEN << >> ELSE message.executorId[1])
        \o (IF message.orderOrigination = << >> THEN << >> ELSE message.orderOrigination[1])
        \o (IF message.algorithmicIndicator = << >> THEN << >> ELSE message.algorithmicIndicator[1])
        \o (IF message.deferralReason = << >> THEN << >> ELSE message.deferralReason[1])
        \o (IF message.investorQualifiedRole = << >> THEN << >> ELSE message.investorQualifiedRole[1])
        \o (IF message.executorQualifiedRole = << >> THEN << >> ELSE message.executorQualifiedRole[1])

DecodeOrderRestatedV2Message(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clOrdId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET restatementReason == ReadBytes(orderId.rest, 1) IN IF ~restatementReason.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(restatementReason.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET numberOfReturnBitfields == ReadUIntBE(reserved1.rest, 1) IN IF ~numberOfReturnBitfields.ok THEN Fail ELSE
    LET orderRestatedV2ReturnBitfield1 == ReadWhen(numberOfReturnBitfields.value >= 1, ReadUIntLE(numberOfReturnBitfields.rest, 1), numberOfReturnBitfields.rest) IN IF ~orderRestatedV2ReturnBitfield1.ok THEN Fail ELSE
    LET orderRestatedV2ReturnBitfield2 == ReadWhen(numberOfReturnBitfields.value >= 2, ReadUIntLE(orderRestatedV2ReturnBitfield1.rest, 1), orderRestatedV2ReturnBitfield1.rest) IN IF ~orderRestatedV2ReturnBitfield2.ok THEN Fail ELSE
    LET orderRestatedV2ReturnBitfield3 == ReadWhen(numberOfReturnBitfields.value >= 3, ReadUIntLE(orderRestatedV2ReturnBitfield2.rest, 1), orderRestatedV2ReturnBitfield2.rest) IN IF ~orderRestatedV2ReturnBitfield3.ok THEN Fail ELSE
    LET orderRestatedV2ReturnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadBytes(orderRestatedV2ReturnBitfield3.rest, 1), orderRestatedV2ReturnBitfield3.rest) IN IF ~orderRestatedV2ReturnBitfield4.ok THEN Fail ELSE
    LET orderRestatedV2ReturnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadUIntLE(orderRestatedV2ReturnBitfield4.rest, 1), orderRestatedV2ReturnBitfield4.rest) IN IF ~orderRestatedV2ReturnBitfield5.ok THEN Fail ELSE
    LET orderRestatedV2ReturnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadUIntLE(orderRestatedV2ReturnBitfield5.rest, 1), orderRestatedV2ReturnBitfield5.rest) IN IF ~orderRestatedV2ReturnBitfield6.ok THEN Fail ELSE
    LET orderRestatedV2ReturnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadBytes(orderRestatedV2ReturnBitfield6.rest, 1), orderRestatedV2ReturnBitfield6.rest) IN IF ~orderRestatedV2ReturnBitfield7.ok THEN Fail ELSE
    LET orderRestatedV2ReturnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadBytes(orderRestatedV2ReturnBitfield7.rest, 1), orderRestatedV2ReturnBitfield7.rest) IN IF ~orderRestatedV2ReturnBitfield8.ok THEN Fail ELSE
    LET orderRestatedV2ReturnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadUIntLE(orderRestatedV2ReturnBitfield8.rest, 1), orderRestatedV2ReturnBitfield8.rest) IN IF ~orderRestatedV2ReturnBitfield9.ok THEN Fail ELSE
    LET orderRestatedV2ReturnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadUIntLE(orderRestatedV2ReturnBitfield9.rest, 1), orderRestatedV2ReturnBitfield9.rest) IN IF ~orderRestatedV2ReturnBitfield10.ok THEN Fail ELSE
    LET orderRestatedV2ReturnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadUIntLE(orderRestatedV2ReturnBitfield10.rest, 1), orderRestatedV2ReturnBitfield10.rest) IN IF ~orderRestatedV2ReturnBitfield11.ok THEN Fail ELSE
    LET orderRestatedV2ReturnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadBytes(orderRestatedV2ReturnBitfield11.rest, 1), orderRestatedV2ReturnBitfield11.rest) IN IF ~orderRestatedV2ReturnBitfield12.ok THEN Fail ELSE
    LET orderRestatedV2ReturnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(orderRestatedV2ReturnBitfield12.rest, 1), orderRestatedV2ReturnBitfield12.rest) IN IF ~orderRestatedV2ReturnBitfield13.ok THEN Fail ELSE
    LET orderRestatedV2ReturnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(orderRestatedV2ReturnBitfield13.rest, 1), orderRestatedV2ReturnBitfield13.rest) IN IF ~orderRestatedV2ReturnBitfield14.ok THEN Fail ELSE
    LET side == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderRestatedV2ReturnBitfield1.value # << >> /\ orderRestatedV2ReturnBitfield1.value[1] % 2 > 0), ReadBytes(orderRestatedV2ReturnBitfield14.rest, 1), orderRestatedV2ReturnBitfield14.rest) IN IF ~side.ok THEN Fail ELSE
    LET pegDifference == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderRestatedV2ReturnBitfield1.value # << >> /\ (orderRestatedV2ReturnBitfield1.value[1] \div 2) % 2 > 0), ReadBytes(side.rest, 8), side.rest) IN IF ~pegDifference.ok THEN Fail ELSE
    LET price == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderRestatedV2ReturnBitfield1.value # << >> /\ (orderRestatedV2ReturnBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(pegDifference.rest, 8), pegDifference.rest) IN IF ~price.ok THEN Fail ELSE
    LET execInst == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderRestatedV2ReturnBitfield1.value # << >> /\ (orderRestatedV2ReturnBitfield1.value[1] \div 8) % 2 > 0), ReadBytes(price.rest, 1), price.rest) IN IF ~execInst.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderRestatedV2ReturnBitfield1.value # << >> /\ (orderRestatedV2ReturnBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(execInst.rest, 1), execInst.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderRestatedV2ReturnBitfield1.value # << >> /\ (orderRestatedV2ReturnBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderRestatedV2ReturnBitfield1.value # << >> /\ (orderRestatedV2ReturnBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET symbol == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderRestatedV2ReturnBitfield2.value # << >> /\ orderRestatedV2ReturnBitfield2.value[1] % 2 > 0), ReadBytes(minQty.rest, 8), minQty.rest) IN IF ~symbol.ok THEN Fail ELSE
    LET currency == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderRestatedV2ReturnBitfield2.value # << >> /\ (orderRestatedV2ReturnBitfield2.value[1] \div 4) % 2 > 0), ReadBytes(symbol.rest, 3), symbol.rest) IN IF ~currency.ok THEN Fail ELSE
    LET idSource == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderRestatedV2ReturnBitfield2.value # << >> /\ (orderRestatedV2ReturnBitfield2.value[1] \div 8) % 2 > 0), ReadBytes(currency.rest, 1), currency.rest) IN IF ~idSource.ok THEN Fail ELSE
    LET securityId == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderRestatedV2ReturnBitfield2.value # << >> /\ (orderRestatedV2ReturnBitfield2.value[1] \div 16) % 2 > 0), ReadBytes(idSource.rest, 16), idSource.rest) IN IF ~securityId.ok THEN Fail ELSE
    LET securityExchange == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderRestatedV2ReturnBitfield2.value # << >> /\ (orderRestatedV2ReturnBitfield2.value[1] \div 32) % 2 > 0), ReadBytes(securityId.rest, 4), securityId.rest) IN IF ~securityExchange.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderRestatedV2ReturnBitfield2.value # << >> /\ (orderRestatedV2ReturnBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(securityExchange.rest, 1), securityExchange.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderRestatedV2ReturnBitfield3.value # << >> /\ orderRestatedV2ReturnBitfield3.value[1] % 2 > 0), ReadBytes(capacity.rest, 16), capacity.rest) IN IF ~account.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderRestatedV2ReturnBitfield3.value # << >> /\ (orderRestatedV2ReturnBitfield3.value[1] \div 2) % 2 > 0), ReadBytes(account.rest, 4), account.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderRestatedV2ReturnBitfield3.value # << >> /\ (orderRestatedV2ReturnBitfield3.value[1] \div 4) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET displayIndicator == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderRestatedV2ReturnBitfield3.value # << >> /\ (orderRestatedV2ReturnBitfield3.value[1] \div 8) % 2 > 0), ReadBytes(clearingAccount.rest, 1), clearingAccount.rest) IN IF ~displayIndicator.ok THEN Fail ELSE
    LET maxFloor == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderRestatedV2ReturnBitfield3.value # << >> /\ (orderRestatedV2ReturnBitfield3.value[1] \div 16) % 2 > 0), ReadBytes(displayIndicator.rest, 4), displayIndicator.rest) IN IF ~maxFloor.ok THEN Fail ELSE
    LET orderQty == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderRestatedV2ReturnBitfield3.value # << >> /\ (orderRestatedV2ReturnBitfield3.value[1] \div 64) % 2 > 0), ReadBytes(maxFloor.rest, 4), maxFloor.rest) IN IF ~orderQty.ok THEN Fail ELSE
    LET preventParticipantMatch == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderRestatedV2ReturnBitfield3.value # << >> /\ (orderRestatedV2ReturnBitfield3.value[1] \div 128) % 2 > 0), ReadBytes(orderQty.rest, 3), orderQty.rest) IN IF ~preventParticipantMatch.ok THEN Fail ELSE
    LET origClOrdId == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderRestatedV2ReturnBitfield5.value # << >> /\ orderRestatedV2ReturnBitfield5.value[1] % 2 > 0), ReadBytes(preventParticipantMatch.rest, 20), preventParticipantMatch.rest) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET leavesQty == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderRestatedV2ReturnBitfield5.value # << >> /\ (orderRestatedV2ReturnBitfield5.value[1] \div 2) % 2 > 0), ReadBytes(origClOrdId.rest, 4), origClOrdId.rest) IN IF ~leavesQty.ok THEN Fail ELSE
    LET lastShares == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderRestatedV2ReturnBitfield5.value # << >> /\ (orderRestatedV2ReturnBitfield5.value[1] \div 4) % 2 > 0), ReadBytes(leavesQty.rest, 4), leavesQty.rest) IN IF ~lastShares.ok THEN Fail ELSE
    LET lastPx == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderRestatedV2ReturnBitfield5.value # << >> /\ (orderRestatedV2ReturnBitfield5.value[1] \div 8) % 2 > 0), ReadBytes(lastShares.rest, 8), lastShares.rest) IN IF ~lastPx.ok THEN Fail ELSE
    LET displayPrice == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderRestatedV2ReturnBitfield5.value # << >> /\ (orderRestatedV2ReturnBitfield5.value[1] \div 16) % 2 > 0), ReadBytes(lastPx.rest, 8), lastPx.rest) IN IF ~displayPrice.ok THEN Fail ELSE
    LET workingPrice == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderRestatedV2ReturnBitfield5.value # << >> /\ (orderRestatedV2ReturnBitfield5.value[1] \div 32) % 2 > 0), ReadBytes(displayPrice.rest, 8), displayPrice.rest) IN IF ~workingPrice.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderRestatedV2ReturnBitfield5.value # << >> /\ (orderRestatedV2ReturnBitfield5.value[1] \div 64) % 2 > 0), ReadBytes(workingPrice.rest, 1), workingPrice.rest) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET expireTime == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderRestatedV2ReturnBitfield5.value # << >> /\ (orderRestatedV2ReturnBitfield5.value[1] \div 128) % 2 > 0), ReadBytes(baseLiquidityIndicator.rest, 8), baseLiquidityIndicator.rest) IN IF ~expireTime.ok THEN Fail ELSE
    LET secondaryOrderId == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (orderRestatedV2ReturnBitfield6.value # << >> /\ orderRestatedV2ReturnBitfield6.value[1] % 2 > 0), ReadBytes(expireTime.rest, 8), expireTime.rest) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET liquidityProvision == ReadWhen(numberOfReturnBitfields.value >= 9 /\ (orderRestatedV2ReturnBitfield9.value # << >> /\ (orderRestatedV2ReturnBitfield9.value[1] \div 16) % 2 > 0), ReadBytes(secondaryOrderId.rest, 1), secondaryOrderId.rest) IN IF ~liquidityProvision.ok THEN Fail ELSE
    LET waiverType == ReadWhen(numberOfReturnBitfields.value >= 10 /\ (orderRestatedV2ReturnBitfield10.value # << >> /\ (orderRestatedV2ReturnBitfield10.value[1] \div 16) % 2 > 0), ReadBytes(liquidityProvision.rest, 1), liquidityProvision.rest) IN IF ~waiverType.ok THEN Fail ELSE
    LET priceFormation == ReadWhen(numberOfReturnBitfields.value >= 10 /\ (orderRestatedV2ReturnBitfield10.value # << >> /\ (orderRestatedV2ReturnBitfield10.value[1] \div 64) % 2 > 0), ReadBytes(waiverType.rest, 1), waiverType.rest) IN IF ~priceFormation.ok THEN Fail ELSE
    LET clientQualifiedRole == ReadWhen(numberOfReturnBitfields.value >= 10 /\ (orderRestatedV2ReturnBitfield10.value # << >> /\ (orderRestatedV2ReturnBitfield10.value[1] \div 128) % 2 > 0), ReadBytes(priceFormation.rest, 1), priceFormation.rest) IN IF ~clientQualifiedRole.ok THEN Fail ELSE
    LET clientId == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (orderRestatedV2ReturnBitfield11.value # << >> /\ orderRestatedV2ReturnBitfield11.value[1] % 2 > 0), ReadBytes(clientQualifiedRole.rest, 4), clientQualifiedRole.rest) IN IF ~clientId.ok THEN Fail ELSE
    LET investorId == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (orderRestatedV2ReturnBitfield11.value # << >> /\ (orderRestatedV2ReturnBitfield11.value[1] \div 2) % 2 > 0), ReadBytes(clientId.rest, 4), clientId.rest) IN IF ~investorId.ok THEN Fail ELSE
    LET executorId == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (orderRestatedV2ReturnBitfield11.value # << >> /\ (orderRestatedV2ReturnBitfield11.value[1] \div 4) % 2 > 0), ReadBytes(investorId.rest, 4), investorId.rest) IN IF ~executorId.ok THEN Fail ELSE
    LET orderOrigination == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (orderRestatedV2ReturnBitfield11.value # << >> /\ (orderRestatedV2ReturnBitfield11.value[1] \div 8) % 2 > 0), ReadBytes(executorId.rest, 1), executorId.rest) IN IF ~orderOrigination.ok THEN Fail ELSE
    LET algorithmicIndicator == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (orderRestatedV2ReturnBitfield11.value # << >> /\ (orderRestatedV2ReturnBitfield11.value[1] \div 16) % 2 > 0), ReadBytes(orderOrigination.rest, 1), orderOrigination.rest) IN IF ~algorithmicIndicator.ok THEN Fail ELSE
    LET deferralReason == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (orderRestatedV2ReturnBitfield11.value # << >> /\ (orderRestatedV2ReturnBitfield11.value[1] \div 32) % 2 > 0), ReadBytes(algorithmicIndicator.rest, 1), algorithmicIndicator.rest) IN IF ~deferralReason.ok THEN Fail ELSE
    LET investorQualifiedRole == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (orderRestatedV2ReturnBitfield11.value # << >> /\ (orderRestatedV2ReturnBitfield11.value[1] \div 64) % 2 > 0), ReadBytes(deferralReason.rest, 1), deferralReason.rest) IN IF ~investorQualifiedRole.ok THEN Fail ELSE
    LET executorQualifiedRole == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (orderRestatedV2ReturnBitfield11.value # << >> /\ (orderRestatedV2ReturnBitfield11.value[1] \div 128) % 2 > 0), ReadBytes(investorQualifiedRole.rest, 1), investorQualifiedRole.rest) IN IF ~executorQualifiedRole.ok THEN Fail ELSE
    Ok([ transactionTime                 |-> transactionTime.value,
         clOrdId                         |-> clOrdId.value,
         orderId                         |-> orderId.value,
         restatementReason               |-> restatementReason.value,
         reserved1                       |-> reserved1.value,
         numberOfReturnBitfields         |-> numberOfReturnBitfields.value,
         orderRestatedV2ReturnBitfield1  |-> orderRestatedV2ReturnBitfield1.value,
         orderRestatedV2ReturnBitfield2  |-> orderRestatedV2ReturnBitfield2.value,
         orderRestatedV2ReturnBitfield3  |-> orderRestatedV2ReturnBitfield3.value,
         orderRestatedV2ReturnBitfield4  |-> orderRestatedV2ReturnBitfield4.value,
         orderRestatedV2ReturnBitfield5  |-> orderRestatedV2ReturnBitfield5.value,
         orderRestatedV2ReturnBitfield6  |-> orderRestatedV2ReturnBitfield6.value,
         orderRestatedV2ReturnBitfield7  |-> orderRestatedV2ReturnBitfield7.value,
         orderRestatedV2ReturnBitfield8  |-> orderRestatedV2ReturnBitfield8.value,
         orderRestatedV2ReturnBitfield9  |-> orderRestatedV2ReturnBitfield9.value,
         orderRestatedV2ReturnBitfield10 |-> orderRestatedV2ReturnBitfield10.value,
         orderRestatedV2ReturnBitfield11 |-> orderRestatedV2ReturnBitfield11.value,
         orderRestatedV2ReturnBitfield12 |-> orderRestatedV2ReturnBitfield12.value,
         orderRestatedV2ReturnBitfield13 |-> orderRestatedV2ReturnBitfield13.value,
         orderRestatedV2ReturnBitfield14 |-> orderRestatedV2ReturnBitfield14.value,
         side                            |-> side.value,
         pegDifference                   |-> pegDifference.value,
         price                           |-> price.value,
         execInst                        |-> execInst.value,
         ordType                         |-> ordType.value,
         timeInForce                     |-> timeInForce.value,
         minQty                          |-> minQty.value,
         symbol                          |-> symbol.value,
         currency                        |-> currency.value,
         idSource                        |-> idSource.value,
         securityId                      |-> securityId.value,
         securityExchange                |-> securityExchange.value,
         capacity                        |-> capacity.value,
         account                         |-> account.value,
         clearingFirm                    |-> clearingFirm.value,
         clearingAccount                 |-> clearingAccount.value,
         displayIndicator                |-> displayIndicator.value,
         maxFloor                        |-> maxFloor.value,
         orderQty                        |-> orderQty.value,
         preventParticipantMatch         |-> preventParticipantMatch.value,
         origClOrdId                     |-> origClOrdId.value,
         leavesQty                       |-> leavesQty.value,
         lastShares                      |-> lastShares.value,
         lastPx                          |-> lastPx.value,
         displayPrice                    |-> displayPrice.value,
         workingPrice                    |-> workingPrice.value,
         baseLiquidityIndicator          |-> baseLiquidityIndicator.value,
         expireTime                      |-> expireTime.value,
         secondaryOrderId                |-> secondaryOrderId.value,
         liquidityProvision              |-> liquidityProvision.value,
         waiverType                      |-> waiverType.value,
         priceFormation                  |-> priceFormation.value,
         clientQualifiedRole             |-> clientQualifiedRole.value,
         clientId                        |-> clientId.value,
         investorId                      |-> investorId.value,
         executorId                      |-> executorId.value,
         orderOrigination                |-> orderOrigination.value,
         algorithmicIndicator            |-> algorithmicIndicator.value,
         deferralReason                  |-> deferralReason.value,
         investorQualifiedRole           |-> investorQualifiedRole.value,
         executorQualifiedRole           |-> executorQualifiedRole.value ], executorQualifiedRole.rest)

(* Order Restated V 2 Message with each field marked present by fields before it there exactly where they say *)
SettleOrderRestatedV2Message(message) ==
    LET settled1 == [message EXCEPT !.orderRestatedV2ReturnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.orderRestatedV2ReturnBitfield1 = << >> THEN <<0>> ELSE message.orderRestatedV2ReturnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.orderRestatedV2ReturnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.orderRestatedV2ReturnBitfield2 = << >> THEN <<0>> ELSE settled1.orderRestatedV2ReturnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.orderRestatedV2ReturnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.orderRestatedV2ReturnBitfield3 = << >> THEN <<0>> ELSE settled2.orderRestatedV2ReturnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.orderRestatedV2ReturnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.orderRestatedV2ReturnBitfield4 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled3.orderRestatedV2ReturnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.orderRestatedV2ReturnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.orderRestatedV2ReturnBitfield5 = << >> THEN <<0>> ELSE settled4.orderRestatedV2ReturnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.orderRestatedV2ReturnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.orderRestatedV2ReturnBitfield6 = << >> THEN <<0>> ELSE settled5.orderRestatedV2ReturnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.orderRestatedV2ReturnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.orderRestatedV2ReturnBitfield7 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.orderRestatedV2ReturnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.orderRestatedV2ReturnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.orderRestatedV2ReturnBitfield8 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled7.orderRestatedV2ReturnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.orderRestatedV2ReturnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.orderRestatedV2ReturnBitfield9 = << >> THEN <<0>> ELSE settled8.orderRestatedV2ReturnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.orderRestatedV2ReturnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.orderRestatedV2ReturnBitfield10 = << >> THEN <<0>> ELSE settled9.orderRestatedV2ReturnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.orderRestatedV2ReturnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.orderRestatedV2ReturnBitfield11 = << >> THEN <<0>> ELSE settled10.orderRestatedV2ReturnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.orderRestatedV2ReturnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.orderRestatedV2ReturnBitfield12 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.orderRestatedV2ReturnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.orderRestatedV2ReturnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.orderRestatedV2ReturnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.orderRestatedV2ReturnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.orderRestatedV2ReturnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.orderRestatedV2ReturnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.orderRestatedV2ReturnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.side = IF settled14.numberOfReturnBitfields >= 1 /\ (settled14.orderRestatedV2ReturnBitfield1 # << >> /\ settled14.orderRestatedV2ReturnBitfield1[1] % 2 > 0) THEN (IF settled14.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.side) ELSE << >>]
        settled16 == [settled15 EXCEPT !.pegDifference = IF settled15.numberOfReturnBitfields >= 1 /\ (settled15.orderRestatedV2ReturnBitfield1 # << >> /\ (settled15.orderRestatedV2ReturnBitfield1[1] \div 2) % 2 > 0) THEN (IF settled15.pegDifference = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled15.pegDifference) ELSE << >>]
        settled17 == [settled16 EXCEPT !.price = IF settled16.numberOfReturnBitfields >= 1 /\ (settled16.orderRestatedV2ReturnBitfield1 # << >> /\ (settled16.orderRestatedV2ReturnBitfield1[1] \div 4) % 2 > 0) THEN (IF settled16.price = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled16.price) ELSE << >>]
        settled18 == [settled17 EXCEPT !.execInst = IF settled17.numberOfReturnBitfields >= 1 /\ (settled17.orderRestatedV2ReturnBitfield1 # << >> /\ (settled17.orderRestatedV2ReturnBitfield1[1] \div 8) % 2 > 0) THEN (IF settled17.execInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.execInst) ELSE << >>]
        settled19 == [settled18 EXCEPT !.ordType = IF settled18.numberOfReturnBitfields >= 1 /\ (settled18.orderRestatedV2ReturnBitfield1 # << >> /\ (settled18.orderRestatedV2ReturnBitfield1[1] \div 16) % 2 > 0) THEN (IF settled18.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled18.ordType) ELSE << >>]
        settled20 == [settled19 EXCEPT !.timeInForce = IF settled19.numberOfReturnBitfields >= 1 /\ (settled19.orderRestatedV2ReturnBitfield1 # << >> /\ (settled19.orderRestatedV2ReturnBitfield1[1] \div 32) % 2 > 0) THEN (IF settled19.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled19.timeInForce) ELSE << >>]
        settled21 == [settled20 EXCEPT !.minQty = IF settled20.numberOfReturnBitfields >= 1 /\ (settled20.orderRestatedV2ReturnBitfield1 # << >> /\ (settled20.orderRestatedV2ReturnBitfield1[1] \div 64) % 2 > 0) THEN (IF settled20.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled20.minQty) ELSE << >>]
        settled22 == [settled21 EXCEPT !.symbol = IF settled21.numberOfReturnBitfields >= 2 /\ (settled21.orderRestatedV2ReturnBitfield2 # << >> /\ settled21.orderRestatedV2ReturnBitfield2[1] % 2 > 0) THEN (IF settled21.symbol = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled21.symbol) ELSE << >>]
        settled23 == [settled22 EXCEPT !.currency = IF settled22.numberOfReturnBitfields >= 2 /\ (settled22.orderRestatedV2ReturnBitfield2 # << >> /\ (settled22.orderRestatedV2ReturnBitfield2[1] \div 4) % 2 > 0) THEN (IF settled22.currency = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled22.currency) ELSE << >>]
        settled24 == [settled23 EXCEPT !.idSource = IF settled23.numberOfReturnBitfields >= 2 /\ (settled23.orderRestatedV2ReturnBitfield2 # << >> /\ (settled23.orderRestatedV2ReturnBitfield2[1] \div 8) % 2 > 0) THEN (IF settled23.idSource = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled23.idSource) ELSE << >>]
        settled25 == [settled24 EXCEPT !.securityId = IF settled24.numberOfReturnBitfields >= 2 /\ (settled24.orderRestatedV2ReturnBitfield2 # << >> /\ (settled24.orderRestatedV2ReturnBitfield2[1] \div 16) % 2 > 0) THEN (IF settled24.securityId = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled24.securityId) ELSE << >>]
        settled26 == [settled25 EXCEPT !.securityExchange = IF settled25.numberOfReturnBitfields >= 2 /\ (settled25.orderRestatedV2ReturnBitfield2 # << >> /\ (settled25.orderRestatedV2ReturnBitfield2[1] \div 32) % 2 > 0) THEN (IF settled25.securityExchange = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled25.securityExchange) ELSE << >>]
        settled27 == [settled26 EXCEPT !.capacity = IF settled26.numberOfReturnBitfields >= 2 /\ (settled26.orderRestatedV2ReturnBitfield2 # << >> /\ (settled26.orderRestatedV2ReturnBitfield2[1] \div 64) % 2 > 0) THEN (IF settled26.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled26.capacity) ELSE << >>]
        settled28 == [settled27 EXCEPT !.account = IF settled27.numberOfReturnBitfields >= 3 /\ (settled27.orderRestatedV2ReturnBitfield3 # << >> /\ settled27.orderRestatedV2ReturnBitfield3[1] % 2 > 0) THEN (IF settled27.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled27.account) ELSE << >>]
        settled29 == [settled28 EXCEPT !.clearingFirm = IF settled28.numberOfReturnBitfields >= 3 /\ (settled28.orderRestatedV2ReturnBitfield3 # << >> /\ (settled28.orderRestatedV2ReturnBitfield3[1] \div 2) % 2 > 0) THEN (IF settled28.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled28.clearingFirm) ELSE << >>]
        settled30 == [settled29 EXCEPT !.clearingAccount = IF settled29.numberOfReturnBitfields >= 3 /\ (settled29.orderRestatedV2ReturnBitfield3 # << >> /\ (settled29.orderRestatedV2ReturnBitfield3[1] \div 4) % 2 > 0) THEN (IF settled29.clearingAccount = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled29.clearingAccount) ELSE << >>]
        settled31 == [settled30 EXCEPT !.displayIndicator = IF settled30.numberOfReturnBitfields >= 3 /\ (settled30.orderRestatedV2ReturnBitfield3 # << >> /\ (settled30.orderRestatedV2ReturnBitfield3[1] \div 8) % 2 > 0) THEN (IF settled30.displayIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled30.displayIndicator) ELSE << >>]
        settled32 == [settled31 EXCEPT !.maxFloor = IF settled31.numberOfReturnBitfields >= 3 /\ (settled31.orderRestatedV2ReturnBitfield3 # << >> /\ (settled31.orderRestatedV2ReturnBitfield3[1] \div 16) % 2 > 0) THEN (IF settled31.maxFloor = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled31.maxFloor) ELSE << >>]
        settled33 == [settled32 EXCEPT !.orderQty = IF settled32.numberOfReturnBitfields >= 3 /\ (settled32.orderRestatedV2ReturnBitfield3 # << >> /\ (settled32.orderRestatedV2ReturnBitfield3[1] \div 64) % 2 > 0) THEN (IF settled32.orderQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled32.orderQty) ELSE << >>]
        settled34 == [settled33 EXCEPT !.preventParticipantMatch = IF settled33.numberOfReturnBitfields >= 3 /\ (settled33.orderRestatedV2ReturnBitfield3 # << >> /\ (settled33.orderRestatedV2ReturnBitfield3[1] \div 128) % 2 > 0) THEN (IF settled33.preventParticipantMatch = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled33.preventParticipantMatch) ELSE << >>]
        settled35 == [settled34 EXCEPT !.origClOrdId = IF settled34.numberOfReturnBitfields >= 5 /\ (settled34.orderRestatedV2ReturnBitfield5 # << >> /\ settled34.orderRestatedV2ReturnBitfield5[1] % 2 > 0) THEN (IF settled34.origClOrdId = << >> THEN <<[i \in 1 .. 20 |-> 0]>> ELSE settled34.origClOrdId) ELSE << >>]
        settled36 == [settled35 EXCEPT !.leavesQty = IF settled35.numberOfReturnBitfields >= 5 /\ (settled35.orderRestatedV2ReturnBitfield5 # << >> /\ (settled35.orderRestatedV2ReturnBitfield5[1] \div 2) % 2 > 0) THEN (IF settled35.leavesQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled35.leavesQty) ELSE << >>]
        settled37 == [settled36 EXCEPT !.lastShares = IF settled36.numberOfReturnBitfields >= 5 /\ (settled36.orderRestatedV2ReturnBitfield5 # << >> /\ (settled36.orderRestatedV2ReturnBitfield5[1] \div 4) % 2 > 0) THEN (IF settled36.lastShares = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled36.lastShares) ELSE << >>]
        settled38 == [settled37 EXCEPT !.lastPx = IF settled37.numberOfReturnBitfields >= 5 /\ (settled37.orderRestatedV2ReturnBitfield5 # << >> /\ (settled37.orderRestatedV2ReturnBitfield5[1] \div 8) % 2 > 0) THEN (IF settled37.lastPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled37.lastPx) ELSE << >>]
        settled39 == [settled38 EXCEPT !.displayPrice = IF settled38.numberOfReturnBitfields >= 5 /\ (settled38.orderRestatedV2ReturnBitfield5 # << >> /\ (settled38.orderRestatedV2ReturnBitfield5[1] \div 16) % 2 > 0) THEN (IF settled38.displayPrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled38.displayPrice) ELSE << >>]
        settled40 == [settled39 EXCEPT !.workingPrice = IF settled39.numberOfReturnBitfields >= 5 /\ (settled39.orderRestatedV2ReturnBitfield5 # << >> /\ (settled39.orderRestatedV2ReturnBitfield5[1] \div 32) % 2 > 0) THEN (IF settled39.workingPrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled39.workingPrice) ELSE << >>]
        settled41 == [settled40 EXCEPT !.baseLiquidityIndicator = IF settled40.numberOfReturnBitfields >= 5 /\ (settled40.orderRestatedV2ReturnBitfield5 # << >> /\ (settled40.orderRestatedV2ReturnBitfield5[1] \div 64) % 2 > 0) THEN (IF settled40.baseLiquidityIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled40.baseLiquidityIndicator) ELSE << >>]
        settled42 == [settled41 EXCEPT !.expireTime = IF settled41.numberOfReturnBitfields >= 5 /\ (settled41.orderRestatedV2ReturnBitfield5 # << >> /\ (settled41.orderRestatedV2ReturnBitfield5[1] \div 128) % 2 > 0) THEN (IF settled41.expireTime = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled41.expireTime) ELSE << >>]
        settled43 == [settled42 EXCEPT !.secondaryOrderId = IF settled42.numberOfReturnBitfields >= 6 /\ (settled42.orderRestatedV2ReturnBitfield6 # << >> /\ settled42.orderRestatedV2ReturnBitfield6[1] % 2 > 0) THEN (IF settled42.secondaryOrderId = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled42.secondaryOrderId) ELSE << >>]
        settled44 == [settled43 EXCEPT !.liquidityProvision = IF settled43.numberOfReturnBitfields >= 9 /\ (settled43.orderRestatedV2ReturnBitfield9 # << >> /\ (settled43.orderRestatedV2ReturnBitfield9[1] \div 16) % 2 > 0) THEN (IF settled43.liquidityProvision = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled43.liquidityProvision) ELSE << >>]
        settled45 == [settled44 EXCEPT !.waiverType = IF settled44.numberOfReturnBitfields >= 10 /\ (settled44.orderRestatedV2ReturnBitfield10 # << >> /\ (settled44.orderRestatedV2ReturnBitfield10[1] \div 16) % 2 > 0) THEN (IF settled44.waiverType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled44.waiverType) ELSE << >>]
        settled46 == [settled45 EXCEPT !.priceFormation = IF settled45.numberOfReturnBitfields >= 10 /\ (settled45.orderRestatedV2ReturnBitfield10 # << >> /\ (settled45.orderRestatedV2ReturnBitfield10[1] \div 64) % 2 > 0) THEN (IF settled45.priceFormation = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled45.priceFormation) ELSE << >>]
        settled47 == [settled46 EXCEPT !.clientQualifiedRole = IF settled46.numberOfReturnBitfields >= 10 /\ (settled46.orderRestatedV2ReturnBitfield10 # << >> /\ (settled46.orderRestatedV2ReturnBitfield10[1] \div 128) % 2 > 0) THEN (IF settled46.clientQualifiedRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled46.clientQualifiedRole) ELSE << >>]
        settled48 == [settled47 EXCEPT !.clientId = IF settled47.numberOfReturnBitfields >= 11 /\ (settled47.orderRestatedV2ReturnBitfield11 # << >> /\ settled47.orderRestatedV2ReturnBitfield11[1] % 2 > 0) THEN (IF settled47.clientId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled47.clientId) ELSE << >>]
        settled49 == [settled48 EXCEPT !.investorId = IF settled48.numberOfReturnBitfields >= 11 /\ (settled48.orderRestatedV2ReturnBitfield11 # << >> /\ (settled48.orderRestatedV2ReturnBitfield11[1] \div 2) % 2 > 0) THEN (IF settled48.investorId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled48.investorId) ELSE << >>]
        settled50 == [settled49 EXCEPT !.executorId = IF settled49.numberOfReturnBitfields >= 11 /\ (settled49.orderRestatedV2ReturnBitfield11 # << >> /\ (settled49.orderRestatedV2ReturnBitfield11[1] \div 4) % 2 > 0) THEN (IF settled49.executorId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled49.executorId) ELSE << >>]
        settled51 == [settled50 EXCEPT !.orderOrigination = IF settled50.numberOfReturnBitfields >= 11 /\ (settled50.orderRestatedV2ReturnBitfield11 # << >> /\ (settled50.orderRestatedV2ReturnBitfield11[1] \div 8) % 2 > 0) THEN (IF settled50.orderOrigination = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled50.orderOrigination) ELSE << >>]
        settled52 == [settled51 EXCEPT !.algorithmicIndicator = IF settled51.numberOfReturnBitfields >= 11 /\ (settled51.orderRestatedV2ReturnBitfield11 # << >> /\ (settled51.orderRestatedV2ReturnBitfield11[1] \div 16) % 2 > 0) THEN (IF settled51.algorithmicIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled51.algorithmicIndicator) ELSE << >>]
        settled53 == [settled52 EXCEPT !.deferralReason = IF settled52.numberOfReturnBitfields >= 11 /\ (settled52.orderRestatedV2ReturnBitfield11 # << >> /\ (settled52.orderRestatedV2ReturnBitfield11[1] \div 32) % 2 > 0) THEN (IF settled52.deferralReason = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled52.deferralReason) ELSE << >>]
        settled54 == [settled53 EXCEPT !.investorQualifiedRole = IF settled53.numberOfReturnBitfields >= 11 /\ (settled53.orderRestatedV2ReturnBitfield11 # << >> /\ (settled53.orderRestatedV2ReturnBitfield11[1] \div 64) % 2 > 0) THEN (IF settled53.investorQualifiedRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled53.investorQualifiedRole) ELSE << >>]
        settled55 == [settled54 EXCEPT !.executorQualifiedRole = IF settled54.numberOfReturnBitfields >= 11 /\ (settled54.orderRestatedV2ReturnBitfield11 # << >> /\ (settled54.orderRestatedV2ReturnBitfield11[1] \div 128) % 2 > 0) THEN (IF settled54.executorQualifiedRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled54.executorQualifiedRole) ELSE << >>]
    IN  settled55

ZeroOrderRestatedV2Message ==
    SettleOrderRestatedV2Message([ transactionTime                 |-> [i \in 1 .. 8 |-> 0],
                                   clOrdId                         |-> [i \in 1 .. 20 |-> 0],
                                   orderId                         |-> [i \in 1 .. 8 |-> 0],
                                   restatementReason               |-> [i \in 1 .. 1 |-> 0],
                                   reserved1                       |-> [i \in 1 .. 1 |-> 0],
                                   numberOfReturnBitfields         |-> 0,
                                   orderRestatedV2ReturnBitfield1  |-> << >>,
                                   orderRestatedV2ReturnBitfield2  |-> << >>,
                                   orderRestatedV2ReturnBitfield3  |-> << >>,
                                   orderRestatedV2ReturnBitfield4  |-> << >>,
                                   orderRestatedV2ReturnBitfield5  |-> << >>,
                                   orderRestatedV2ReturnBitfield6  |-> << >>,
                                   orderRestatedV2ReturnBitfield7  |-> << >>,
                                   orderRestatedV2ReturnBitfield8  |-> << >>,
                                   orderRestatedV2ReturnBitfield9  |-> << >>,
                                   orderRestatedV2ReturnBitfield10 |-> << >>,
                                   orderRestatedV2ReturnBitfield11 |-> << >>,
                                   orderRestatedV2ReturnBitfield12 |-> << >>,
                                   orderRestatedV2ReturnBitfield13 |-> << >>,
                                   orderRestatedV2ReturnBitfield14 |-> << >>,
                                   side                            |-> << >>,
                                   pegDifference                   |-> << >>,
                                   price                           |-> << >>,
                                   execInst                        |-> << >>,
                                   ordType                         |-> << >>,
                                   timeInForce                     |-> << >>,
                                   minQty                          |-> << >>,
                                   symbol                          |-> << >>,
                                   currency                        |-> << >>,
                                   idSource                        |-> << >>,
                                   securityId                      |-> << >>,
                                   securityExchange                |-> << >>,
                                   capacity                        |-> << >>,
                                   account                         |-> << >>,
                                   clearingFirm                    |-> << >>,
                                   clearingAccount                 |-> << >>,
                                   displayIndicator                |-> << >>,
                                   maxFloor                        |-> << >>,
                                   orderQty                        |-> << >>,
                                   preventParticipantMatch         |-> << >>,
                                   origClOrdId                     |-> << >>,
                                   leavesQty                       |-> << >>,
                                   lastShares                      |-> << >>,
                                   lastPx                          |-> << >>,
                                   displayPrice                    |-> << >>,
                                   workingPrice                    |-> << >>,
                                   baseLiquidityIndicator          |-> << >>,
                                   expireTime                      |-> << >>,
                                   secondaryOrderId                |-> << >>,
                                   liquidityProvision              |-> << >>,
                                   waiverType                      |-> << >>,
                                   priceFormation                  |-> << >>,
                                   clientQualifiedRole             |-> << >>,
                                   clientId                        |-> << >>,
                                   investorId                      |-> << >>,
                                   executorId                      |-> << >>,
                                   orderOrigination                |-> << >>,
                                   algorithmicIndicator            |-> << >>,
                                   deferralReason                  |-> << >>,
                                   investorQualifiedRole           |-> << >>,
                                   executorQualifiedRole           |-> << >> ])

(* Order Restated V 2 Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderRestatedV2Message ==
    { ZeroOrderRestatedV2Message }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.transactionTime = one]) : one \in Sample(8) }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.clOrdId = one]) : one \in Sample(20) }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.orderId = one]) : one \in Sample(8) }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.restatementReason = one]) : one \in Sample(1) }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.reserved1 = one]) : one \in Sample(1) }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderRestatedV2ReturnBitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 2, !.orderRestatedV2ReturnBitfield2 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderRestatedV2ReturnBitfield3 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 4, !.orderRestatedV2ReturnBitfield4 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 5, !.orderRestatedV2ReturnBitfield5 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 6, !.orderRestatedV2ReturnBitfield6 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 7, !.orderRestatedV2ReturnBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 8, !.orderRestatedV2ReturnBitfield8 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 9, !.orderRestatedV2ReturnBitfield9 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 10, !.orderRestatedV2ReturnBitfield10 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderRestatedV2ReturnBitfield11 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 12, !.orderRestatedV2ReturnBitfield12 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 13, !.orderRestatedV2ReturnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 14, !.orderRestatedV2ReturnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderRestatedV2ReturnBitfield1 = <<1>>, !.side = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderRestatedV2ReturnBitfield1 = <<2>>, !.pegDifference = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderRestatedV2ReturnBitfield1 = <<4>>, !.price = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderRestatedV2ReturnBitfield1 = <<8>>, !.execInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderRestatedV2ReturnBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderRestatedV2ReturnBitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderRestatedV2ReturnBitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 2, !.orderRestatedV2ReturnBitfield2 = <<1>>, !.symbol = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 2, !.orderRestatedV2ReturnBitfield2 = <<4>>, !.currency = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 2, !.orderRestatedV2ReturnBitfield2 = <<8>>, !.idSource = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 2, !.orderRestatedV2ReturnBitfield2 = <<16>>, !.securityId = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 2, !.orderRestatedV2ReturnBitfield2 = <<32>>, !.securityExchange = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 2, !.orderRestatedV2ReturnBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderRestatedV2ReturnBitfield3 = <<1>>, !.account = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderRestatedV2ReturnBitfield3 = <<2>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderRestatedV2ReturnBitfield3 = <<4>>, !.clearingAccount = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderRestatedV2ReturnBitfield3 = <<8>>, !.displayIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderRestatedV2ReturnBitfield3 = <<16>>, !.maxFloor = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderRestatedV2ReturnBitfield3 = <<64>>, !.orderQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderRestatedV2ReturnBitfield3 = <<128>>, !.preventParticipantMatch = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 5, !.orderRestatedV2ReturnBitfield5 = <<1>>, !.origClOrdId = one]) : one \in { <<held>> : held \in Sample(20) } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 5, !.orderRestatedV2ReturnBitfield5 = <<2>>, !.leavesQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 5, !.orderRestatedV2ReturnBitfield5 = <<4>>, !.lastShares = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 5, !.orderRestatedV2ReturnBitfield5 = <<8>>, !.lastPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 5, !.orderRestatedV2ReturnBitfield5 = <<16>>, !.displayPrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 5, !.orderRestatedV2ReturnBitfield5 = <<32>>, !.workingPrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 5, !.orderRestatedV2ReturnBitfield5 = <<64>>, !.baseLiquidityIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 5, !.orderRestatedV2ReturnBitfield5 = <<128>>, !.expireTime = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 6, !.orderRestatedV2ReturnBitfield6 = <<1>>, !.secondaryOrderId = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 9, !.orderRestatedV2ReturnBitfield9 = <<16>>, !.liquidityProvision = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 10, !.orderRestatedV2ReturnBitfield10 = <<16>>, !.waiverType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 10, !.orderRestatedV2ReturnBitfield10 = <<64>>, !.priceFormation = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 10, !.orderRestatedV2ReturnBitfield10 = <<128>>, !.clientQualifiedRole = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderRestatedV2ReturnBitfield11 = <<1>>, !.clientId = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderRestatedV2ReturnBitfield11 = <<2>>, !.investorId = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderRestatedV2ReturnBitfield11 = <<4>>, !.executorId = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderRestatedV2ReturnBitfield11 = <<8>>, !.orderOrigination = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderRestatedV2ReturnBitfield11 = <<16>>, !.algorithmicIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderRestatedV2ReturnBitfield11 = <<32>>, !.deferralReason = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderRestatedV2ReturnBitfield11 = <<64>>, !.investorQualifiedRole = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRestatedV2Message([ZeroOrderRestatedV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderRestatedV2ReturnBitfield11 = <<128>>, !.executorQualifiedRole = one]) : one \in { <<held>> : held \in Sample(1) } }

(***************************************************************************)
(* User Modify Rejected V 2 Message                                        *)
(***************************************************************************)

UserModifyRejectedV2Message ==
    [ transactionTime                      : Sample(8),
      clOrdId                              : Sample(20),
      modifyRejectReason                   : Sample(1),
      text                                 : Sample(60),
      reserved1                            : Sample(1),
      numberOfReturnBitfields              : 0 .. 255,
      userModifyRejectedV2ReturnBitfield1  : { << >> } \cup { <<held>> : held \in Sample(1) },
      userModifyRejectedV2ReturnBitfield2  : { << >> } \cup { <<held>> : held \in Sample(1) },
      userModifyRejectedV2ReturnBitfield3  : { << >> } \cup { <<held>> : held \in Sample(1) },
      userModifyRejectedV2ReturnBitfield4  : { << >> } \cup { <<held>> : held \in Sample(1) },
      userModifyRejectedV2ReturnBitfield5  : { << >> } \cup { <<held>> : held \in Sample(1) },
      userModifyRejectedV2ReturnBitfield6  : { << >> } \cup { <<held>> : held \in Sample(1) },
      userModifyRejectedV2ReturnBitfield7  : { << >> } \cup { <<held>> : held \in Sample(1) },
      userModifyRejectedV2ReturnBitfield8  : { << >> } \cup { <<held>> : held \in Sample(1) },
      userModifyRejectedV2ReturnBitfield9  : { << >> } \cup { <<held>> : held \in Sample(1) },
      userModifyRejectedV2ReturnBitfield10 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      userModifyRejectedV2ReturnBitfield11 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      userModifyRejectedV2ReturnBitfield12 : { << >> } \cup { <<held>> : held \in Sample(1) },
      userModifyRejectedV2ReturnBitfield13 : { << >> } \cup { <<held>> : held \in Sample(1) },
      userModifyRejectedV2ReturnBitfield14 : { << >> } \cup { <<held>> : held \in Sample(1) },
      waiverType                           : { << >> } \cup { <<held>> : held \in Sample(1) },
      priceFormation                       : { << >> } \cup { <<held>> : held \in Sample(1) },
      clientQualifiedRole                  : { << >> } \cup { <<held>> : held \in Sample(1) },
      clientId                             : { << >> } \cup { <<held>> : held \in Sample(4) },
      investorId                           : { << >> } \cup { <<held>> : held \in Sample(4) },
      executorId                           : { << >> } \cup { <<held>> : held \in Sample(4) },
      orderOrigination                     : { << >> } \cup { <<held>> : held \in Sample(1) },
      algorithmicIndicator                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      deferralReason                       : { << >> } \cup { <<held>> : held \in Sample(1) },
      investorQualifiedRole                : { << >> } \cup { <<held>> : held \in Sample(1) },
      executorQualifiedRole                : { << >> } \cup { <<held>> : held \in Sample(1) } ]

EncodeUserModifyRejectedV2Message(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.modifyRejectReason
        \o message.text
        \o message.reserved1
        \o EncodeUIntBE(message.numberOfReturnBitfields, 1)
        \o (IF message.userModifyRejectedV2ReturnBitfield1 = << >> THEN << >> ELSE message.userModifyRejectedV2ReturnBitfield1[1])
        \o (IF message.userModifyRejectedV2ReturnBitfield2 = << >> THEN << >> ELSE message.userModifyRejectedV2ReturnBitfield2[1])
        \o (IF message.userModifyRejectedV2ReturnBitfield3 = << >> THEN << >> ELSE message.userModifyRejectedV2ReturnBitfield3[1])
        \o (IF message.userModifyRejectedV2ReturnBitfield4 = << >> THEN << >> ELSE message.userModifyRejectedV2ReturnBitfield4[1])
        \o (IF message.userModifyRejectedV2ReturnBitfield5 = << >> THEN << >> ELSE message.userModifyRejectedV2ReturnBitfield5[1])
        \o (IF message.userModifyRejectedV2ReturnBitfield6 = << >> THEN << >> ELSE message.userModifyRejectedV2ReturnBitfield6[1])
        \o (IF message.userModifyRejectedV2ReturnBitfield7 = << >> THEN << >> ELSE message.userModifyRejectedV2ReturnBitfield7[1])
        \o (IF message.userModifyRejectedV2ReturnBitfield8 = << >> THEN << >> ELSE message.userModifyRejectedV2ReturnBitfield8[1])
        \o (IF message.userModifyRejectedV2ReturnBitfield9 = << >> THEN << >> ELSE message.userModifyRejectedV2ReturnBitfield9[1])
        \o (IF message.userModifyRejectedV2ReturnBitfield10 = << >> THEN << >> ELSE EncodeUIntLE(message.userModifyRejectedV2ReturnBitfield10[1], 1))
        \o (IF message.userModifyRejectedV2ReturnBitfield11 = << >> THEN << >> ELSE EncodeUIntLE(message.userModifyRejectedV2ReturnBitfield11[1], 1))
        \o (IF message.userModifyRejectedV2ReturnBitfield12 = << >> THEN << >> ELSE message.userModifyRejectedV2ReturnBitfield12[1])
        \o (IF message.userModifyRejectedV2ReturnBitfield13 = << >> THEN << >> ELSE message.userModifyRejectedV2ReturnBitfield13[1])
        \o (IF message.userModifyRejectedV2ReturnBitfield14 = << >> THEN << >> ELSE message.userModifyRejectedV2ReturnBitfield14[1])
        \o (IF message.waiverType = << >> THEN << >> ELSE message.waiverType[1])
        \o (IF message.priceFormation = << >> THEN << >> ELSE message.priceFormation[1])
        \o (IF message.clientQualifiedRole = << >> THEN << >> ELSE message.clientQualifiedRole[1])
        \o (IF message.clientId = << >> THEN << >> ELSE message.clientId[1])
        \o (IF message.investorId = << >> THEN << >> ELSE message.investorId[1])
        \o (IF message.executorId = << >> THEN << >> ELSE message.executorId[1])
        \o (IF message.orderOrigination = << >> THEN << >> ELSE message.orderOrigination[1])
        \o (IF message.algorithmicIndicator = << >> THEN << >> ELSE message.algorithmicIndicator[1])
        \o (IF message.deferralReason = << >> THEN << >> ELSE message.deferralReason[1])
        \o (IF message.investorQualifiedRole = << >> THEN << >> ELSE message.investorQualifiedRole[1])
        \o (IF message.executorQualifiedRole = << >> THEN << >> ELSE message.executorQualifiedRole[1])

DecodeUserModifyRejectedV2Message(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET modifyRejectReason == ReadBytes(clOrdId.rest, 1) IN IF ~modifyRejectReason.ok THEN Fail ELSE
    LET text == ReadBytes(modifyRejectReason.rest, 60) IN IF ~text.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(text.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET numberOfReturnBitfields == ReadUIntBE(reserved1.rest, 1) IN IF ~numberOfReturnBitfields.ok THEN Fail ELSE
    LET userModifyRejectedV2ReturnBitfield1 == ReadWhen(numberOfReturnBitfields.value >= 1, ReadBytes(numberOfReturnBitfields.rest, 1), numberOfReturnBitfields.rest) IN IF ~userModifyRejectedV2ReturnBitfield1.ok THEN Fail ELSE
    LET userModifyRejectedV2ReturnBitfield2 == ReadWhen(numberOfReturnBitfields.value >= 2, ReadBytes(userModifyRejectedV2ReturnBitfield1.rest, 1), userModifyRejectedV2ReturnBitfield1.rest) IN IF ~userModifyRejectedV2ReturnBitfield2.ok THEN Fail ELSE
    LET userModifyRejectedV2ReturnBitfield3 == ReadWhen(numberOfReturnBitfields.value >= 3, ReadBytes(userModifyRejectedV2ReturnBitfield2.rest, 1), userModifyRejectedV2ReturnBitfield2.rest) IN IF ~userModifyRejectedV2ReturnBitfield3.ok THEN Fail ELSE
    LET userModifyRejectedV2ReturnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadBytes(userModifyRejectedV2ReturnBitfield3.rest, 1), userModifyRejectedV2ReturnBitfield3.rest) IN IF ~userModifyRejectedV2ReturnBitfield4.ok THEN Fail ELSE
    LET userModifyRejectedV2ReturnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadBytes(userModifyRejectedV2ReturnBitfield4.rest, 1), userModifyRejectedV2ReturnBitfield4.rest) IN IF ~userModifyRejectedV2ReturnBitfield5.ok THEN Fail ELSE
    LET userModifyRejectedV2ReturnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadBytes(userModifyRejectedV2ReturnBitfield5.rest, 1), userModifyRejectedV2ReturnBitfield5.rest) IN IF ~userModifyRejectedV2ReturnBitfield6.ok THEN Fail ELSE
    LET userModifyRejectedV2ReturnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadBytes(userModifyRejectedV2ReturnBitfield6.rest, 1), userModifyRejectedV2ReturnBitfield6.rest) IN IF ~userModifyRejectedV2ReturnBitfield7.ok THEN Fail ELSE
    LET userModifyRejectedV2ReturnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadBytes(userModifyRejectedV2ReturnBitfield7.rest, 1), userModifyRejectedV2ReturnBitfield7.rest) IN IF ~userModifyRejectedV2ReturnBitfield8.ok THEN Fail ELSE
    LET userModifyRejectedV2ReturnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadBytes(userModifyRejectedV2ReturnBitfield8.rest, 1), userModifyRejectedV2ReturnBitfield8.rest) IN IF ~userModifyRejectedV2ReturnBitfield9.ok THEN Fail ELSE
    LET userModifyRejectedV2ReturnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadUIntLE(userModifyRejectedV2ReturnBitfield9.rest, 1), userModifyRejectedV2ReturnBitfield9.rest) IN IF ~userModifyRejectedV2ReturnBitfield10.ok THEN Fail ELSE
    LET userModifyRejectedV2ReturnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadUIntLE(userModifyRejectedV2ReturnBitfield10.rest, 1), userModifyRejectedV2ReturnBitfield10.rest) IN IF ~userModifyRejectedV2ReturnBitfield11.ok THEN Fail ELSE
    LET userModifyRejectedV2ReturnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadBytes(userModifyRejectedV2ReturnBitfield11.rest, 1), userModifyRejectedV2ReturnBitfield11.rest) IN IF ~userModifyRejectedV2ReturnBitfield12.ok THEN Fail ELSE
    LET userModifyRejectedV2ReturnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(userModifyRejectedV2ReturnBitfield12.rest, 1), userModifyRejectedV2ReturnBitfield12.rest) IN IF ~userModifyRejectedV2ReturnBitfield13.ok THEN Fail ELSE
    LET userModifyRejectedV2ReturnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(userModifyRejectedV2ReturnBitfield13.rest, 1), userModifyRejectedV2ReturnBitfield13.rest) IN IF ~userModifyRejectedV2ReturnBitfield14.ok THEN Fail ELSE
    LET waiverType == ReadWhen(numberOfReturnBitfields.value >= 10 /\ (userModifyRejectedV2ReturnBitfield10.value # << >> /\ (userModifyRejectedV2ReturnBitfield10.value[1] \div 16) % 2 > 0), ReadBytes(userModifyRejectedV2ReturnBitfield14.rest, 1), userModifyRejectedV2ReturnBitfield14.rest) IN IF ~waiverType.ok THEN Fail ELSE
    LET priceFormation == ReadWhen(numberOfReturnBitfields.value >= 10 /\ (userModifyRejectedV2ReturnBitfield10.value # << >> /\ (userModifyRejectedV2ReturnBitfield10.value[1] \div 64) % 2 > 0), ReadBytes(waiverType.rest, 1), waiverType.rest) IN IF ~priceFormation.ok THEN Fail ELSE
    LET clientQualifiedRole == ReadWhen(numberOfReturnBitfields.value >= 10 /\ (userModifyRejectedV2ReturnBitfield10.value # << >> /\ (userModifyRejectedV2ReturnBitfield10.value[1] \div 128) % 2 > 0), ReadBytes(priceFormation.rest, 1), priceFormation.rest) IN IF ~clientQualifiedRole.ok THEN Fail ELSE
    LET clientId == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (userModifyRejectedV2ReturnBitfield11.value # << >> /\ userModifyRejectedV2ReturnBitfield11.value[1] % 2 > 0), ReadBytes(clientQualifiedRole.rest, 4), clientQualifiedRole.rest) IN IF ~clientId.ok THEN Fail ELSE
    LET investorId == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (userModifyRejectedV2ReturnBitfield11.value # << >> /\ (userModifyRejectedV2ReturnBitfield11.value[1] \div 2) % 2 > 0), ReadBytes(clientId.rest, 4), clientId.rest) IN IF ~investorId.ok THEN Fail ELSE
    LET executorId == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (userModifyRejectedV2ReturnBitfield11.value # << >> /\ (userModifyRejectedV2ReturnBitfield11.value[1] \div 4) % 2 > 0), ReadBytes(investorId.rest, 4), investorId.rest) IN IF ~executorId.ok THEN Fail ELSE
    LET orderOrigination == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (userModifyRejectedV2ReturnBitfield11.value # << >> /\ (userModifyRejectedV2ReturnBitfield11.value[1] \div 8) % 2 > 0), ReadBytes(executorId.rest, 1), executorId.rest) IN IF ~orderOrigination.ok THEN Fail ELSE
    LET algorithmicIndicator == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (userModifyRejectedV2ReturnBitfield11.value # << >> /\ (userModifyRejectedV2ReturnBitfield11.value[1] \div 16) % 2 > 0), ReadBytes(orderOrigination.rest, 1), orderOrigination.rest) IN IF ~algorithmicIndicator.ok THEN Fail ELSE
    LET deferralReason == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (userModifyRejectedV2ReturnBitfield11.value # << >> /\ (userModifyRejectedV2ReturnBitfield11.value[1] \div 32) % 2 > 0), ReadBytes(algorithmicIndicator.rest, 1), algorithmicIndicator.rest) IN IF ~deferralReason.ok THEN Fail ELSE
    LET investorQualifiedRole == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (userModifyRejectedV2ReturnBitfield11.value # << >> /\ (userModifyRejectedV2ReturnBitfield11.value[1] \div 64) % 2 > 0), ReadBytes(deferralReason.rest, 1), deferralReason.rest) IN IF ~investorQualifiedRole.ok THEN Fail ELSE
    LET executorQualifiedRole == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (userModifyRejectedV2ReturnBitfield11.value # << >> /\ (userModifyRejectedV2ReturnBitfield11.value[1] \div 128) % 2 > 0), ReadBytes(investorQualifiedRole.rest, 1), investorQualifiedRole.rest) IN IF ~executorQualifiedRole.ok THEN Fail ELSE
    Ok([ transactionTime                      |-> transactionTime.value,
         clOrdId                              |-> clOrdId.value,
         modifyRejectReason                   |-> modifyRejectReason.value,
         text                                 |-> text.value,
         reserved1                            |-> reserved1.value,
         numberOfReturnBitfields              |-> numberOfReturnBitfields.value,
         userModifyRejectedV2ReturnBitfield1  |-> userModifyRejectedV2ReturnBitfield1.value,
         userModifyRejectedV2ReturnBitfield2  |-> userModifyRejectedV2ReturnBitfield2.value,
         userModifyRejectedV2ReturnBitfield3  |-> userModifyRejectedV2ReturnBitfield3.value,
         userModifyRejectedV2ReturnBitfield4  |-> userModifyRejectedV2ReturnBitfield4.value,
         userModifyRejectedV2ReturnBitfield5  |-> userModifyRejectedV2ReturnBitfield5.value,
         userModifyRejectedV2ReturnBitfield6  |-> userModifyRejectedV2ReturnBitfield6.value,
         userModifyRejectedV2ReturnBitfield7  |-> userModifyRejectedV2ReturnBitfield7.value,
         userModifyRejectedV2ReturnBitfield8  |-> userModifyRejectedV2ReturnBitfield8.value,
         userModifyRejectedV2ReturnBitfield9  |-> userModifyRejectedV2ReturnBitfield9.value,
         userModifyRejectedV2ReturnBitfield10 |-> userModifyRejectedV2ReturnBitfield10.value,
         userModifyRejectedV2ReturnBitfield11 |-> userModifyRejectedV2ReturnBitfield11.value,
         userModifyRejectedV2ReturnBitfield12 |-> userModifyRejectedV2ReturnBitfield12.value,
         userModifyRejectedV2ReturnBitfield13 |-> userModifyRejectedV2ReturnBitfield13.value,
         userModifyRejectedV2ReturnBitfield14 |-> userModifyRejectedV2ReturnBitfield14.value,
         waiverType                           |-> waiverType.value,
         priceFormation                       |-> priceFormation.value,
         clientQualifiedRole                  |-> clientQualifiedRole.value,
         clientId                             |-> clientId.value,
         investorId                           |-> investorId.value,
         executorId                           |-> executorId.value,
         orderOrigination                     |-> orderOrigination.value,
         algorithmicIndicator                 |-> algorithmicIndicator.value,
         deferralReason                       |-> deferralReason.value,
         investorQualifiedRole                |-> investorQualifiedRole.value,
         executorQualifiedRole                |-> executorQualifiedRole.value ], executorQualifiedRole.rest)

(* User Modify Rejected V 2 Message with each field marked present by fields before it there exactly where they say *)
SettleUserModifyRejectedV2Message(message) ==
    LET settled1 == [message EXCEPT !.userModifyRejectedV2ReturnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.userModifyRejectedV2ReturnBitfield1 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE message.userModifyRejectedV2ReturnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.userModifyRejectedV2ReturnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.userModifyRejectedV2ReturnBitfield2 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled1.userModifyRejectedV2ReturnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.userModifyRejectedV2ReturnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.userModifyRejectedV2ReturnBitfield3 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled2.userModifyRejectedV2ReturnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.userModifyRejectedV2ReturnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.userModifyRejectedV2ReturnBitfield4 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled3.userModifyRejectedV2ReturnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.userModifyRejectedV2ReturnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.userModifyRejectedV2ReturnBitfield5 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled4.userModifyRejectedV2ReturnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.userModifyRejectedV2ReturnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.userModifyRejectedV2ReturnBitfield6 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled5.userModifyRejectedV2ReturnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.userModifyRejectedV2ReturnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.userModifyRejectedV2ReturnBitfield7 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.userModifyRejectedV2ReturnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.userModifyRejectedV2ReturnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.userModifyRejectedV2ReturnBitfield8 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled7.userModifyRejectedV2ReturnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.userModifyRejectedV2ReturnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.userModifyRejectedV2ReturnBitfield9 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled8.userModifyRejectedV2ReturnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.userModifyRejectedV2ReturnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.userModifyRejectedV2ReturnBitfield10 = << >> THEN <<0>> ELSE settled9.userModifyRejectedV2ReturnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.userModifyRejectedV2ReturnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.userModifyRejectedV2ReturnBitfield11 = << >> THEN <<0>> ELSE settled10.userModifyRejectedV2ReturnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.userModifyRejectedV2ReturnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.userModifyRejectedV2ReturnBitfield12 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.userModifyRejectedV2ReturnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.userModifyRejectedV2ReturnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.userModifyRejectedV2ReturnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.userModifyRejectedV2ReturnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.userModifyRejectedV2ReturnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.userModifyRejectedV2ReturnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.userModifyRejectedV2ReturnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.waiverType = IF settled14.numberOfReturnBitfields >= 10 /\ (settled14.userModifyRejectedV2ReturnBitfield10 # << >> /\ (settled14.userModifyRejectedV2ReturnBitfield10[1] \div 16) % 2 > 0) THEN (IF settled14.waiverType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.waiverType) ELSE << >>]
        settled16 == [settled15 EXCEPT !.priceFormation = IF settled15.numberOfReturnBitfields >= 10 /\ (settled15.userModifyRejectedV2ReturnBitfield10 # << >> /\ (settled15.userModifyRejectedV2ReturnBitfield10[1] \div 64) % 2 > 0) THEN (IF settled15.priceFormation = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled15.priceFormation) ELSE << >>]
        settled17 == [settled16 EXCEPT !.clientQualifiedRole = IF settled16.numberOfReturnBitfields >= 10 /\ (settled16.userModifyRejectedV2ReturnBitfield10 # << >> /\ (settled16.userModifyRejectedV2ReturnBitfield10[1] \div 128) % 2 > 0) THEN (IF settled16.clientQualifiedRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled16.clientQualifiedRole) ELSE << >>]
        settled18 == [settled17 EXCEPT !.clientId = IF settled17.numberOfReturnBitfields >= 11 /\ (settled17.userModifyRejectedV2ReturnBitfield11 # << >> /\ settled17.userModifyRejectedV2ReturnBitfield11[1] % 2 > 0) THEN (IF settled17.clientId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled17.clientId) ELSE << >>]
        settled19 == [settled18 EXCEPT !.investorId = IF settled18.numberOfReturnBitfields >= 11 /\ (settled18.userModifyRejectedV2ReturnBitfield11 # << >> /\ (settled18.userModifyRejectedV2ReturnBitfield11[1] \div 2) % 2 > 0) THEN (IF settled18.investorId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled18.investorId) ELSE << >>]
        settled20 == [settled19 EXCEPT !.executorId = IF settled19.numberOfReturnBitfields >= 11 /\ (settled19.userModifyRejectedV2ReturnBitfield11 # << >> /\ (settled19.userModifyRejectedV2ReturnBitfield11[1] \div 4) % 2 > 0) THEN (IF settled19.executorId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled19.executorId) ELSE << >>]
        settled21 == [settled20 EXCEPT !.orderOrigination = IF settled20.numberOfReturnBitfields >= 11 /\ (settled20.userModifyRejectedV2ReturnBitfield11 # << >> /\ (settled20.userModifyRejectedV2ReturnBitfield11[1] \div 8) % 2 > 0) THEN (IF settled20.orderOrigination = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled20.orderOrigination) ELSE << >>]
        settled22 == [settled21 EXCEPT !.algorithmicIndicator = IF settled21.numberOfReturnBitfields >= 11 /\ (settled21.userModifyRejectedV2ReturnBitfield11 # << >> /\ (settled21.userModifyRejectedV2ReturnBitfield11[1] \div 16) % 2 > 0) THEN (IF settled21.algorithmicIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled21.algorithmicIndicator) ELSE << >>]
        settled23 == [settled22 EXCEPT !.deferralReason = IF settled22.numberOfReturnBitfields >= 11 /\ (settled22.userModifyRejectedV2ReturnBitfield11 # << >> /\ (settled22.userModifyRejectedV2ReturnBitfield11[1] \div 32) % 2 > 0) THEN (IF settled22.deferralReason = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled22.deferralReason) ELSE << >>]
        settled24 == [settled23 EXCEPT !.investorQualifiedRole = IF settled23.numberOfReturnBitfields >= 11 /\ (settled23.userModifyRejectedV2ReturnBitfield11 # << >> /\ (settled23.userModifyRejectedV2ReturnBitfield11[1] \div 64) % 2 > 0) THEN (IF settled23.investorQualifiedRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled23.investorQualifiedRole) ELSE << >>]
        settled25 == [settled24 EXCEPT !.executorQualifiedRole = IF settled24.numberOfReturnBitfields >= 11 /\ (settled24.userModifyRejectedV2ReturnBitfield11 # << >> /\ (settled24.userModifyRejectedV2ReturnBitfield11[1] \div 128) % 2 > 0) THEN (IF settled24.executorQualifiedRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled24.executorQualifiedRole) ELSE << >>]
    IN  settled25

ZeroUserModifyRejectedV2Message ==
    SettleUserModifyRejectedV2Message([ transactionTime                      |-> [i \in 1 .. 8 |-> 0],
                                        clOrdId                              |-> [i \in 1 .. 20 |-> 0],
                                        modifyRejectReason                   |-> [i \in 1 .. 1 |-> 0],
                                        text                                 |-> [i \in 1 .. 60 |-> 0],
                                        reserved1                            |-> [i \in 1 .. 1 |-> 0],
                                        numberOfReturnBitfields              |-> 0,
                                        userModifyRejectedV2ReturnBitfield1  |-> << >>,
                                        userModifyRejectedV2ReturnBitfield2  |-> << >>,
                                        userModifyRejectedV2ReturnBitfield3  |-> << >>,
                                        userModifyRejectedV2ReturnBitfield4  |-> << >>,
                                        userModifyRejectedV2ReturnBitfield5  |-> << >>,
                                        userModifyRejectedV2ReturnBitfield6  |-> << >>,
                                        userModifyRejectedV2ReturnBitfield7  |-> << >>,
                                        userModifyRejectedV2ReturnBitfield8  |-> << >>,
                                        userModifyRejectedV2ReturnBitfield9  |-> << >>,
                                        userModifyRejectedV2ReturnBitfield10 |-> << >>,
                                        userModifyRejectedV2ReturnBitfield11 |-> << >>,
                                        userModifyRejectedV2ReturnBitfield12 |-> << >>,
                                        userModifyRejectedV2ReturnBitfield13 |-> << >>,
                                        userModifyRejectedV2ReturnBitfield14 |-> << >>,
                                        waiverType                           |-> << >>,
                                        priceFormation                       |-> << >>,
                                        clientQualifiedRole                  |-> << >>,
                                        clientId                             |-> << >>,
                                        investorId                           |-> << >>,
                                        executorId                           |-> << >>,
                                        orderOrigination                     |-> << >>,
                                        algorithmicIndicator                 |-> << >>,
                                        deferralReason                       |-> << >>,
                                        investorQualifiedRole                |-> << >>,
                                        executorQualifiedRole                |-> << >> ])

(* User Modify Rejected V 2 Message at zero, then each field in turn at the values it is checked at *)
CheckedUserModifyRejectedV2Message ==
    { ZeroUserModifyRejectedV2Message }
        \cup { SettleUserModifyRejectedV2Message([ZeroUserModifyRejectedV2Message EXCEPT !.transactionTime = one]) : one \in Sample(8) }
        \cup { SettleUserModifyRejectedV2Message([ZeroUserModifyRejectedV2Message EXCEPT !.clOrdId = one]) : one \in Sample(20) }
        \cup { SettleUserModifyRejectedV2Message([ZeroUserModifyRejectedV2Message EXCEPT !.modifyRejectReason = one]) : one \in Sample(1) }
        \cup { SettleUserModifyRejectedV2Message([ZeroUserModifyRejectedV2Message EXCEPT !.text = one]) : one \in Sample(60) }
        \cup { SettleUserModifyRejectedV2Message([ZeroUserModifyRejectedV2Message EXCEPT !.reserved1 = one]) : one \in Sample(1) }
        \cup { SettleUserModifyRejectedV2Message([ZeroUserModifyRejectedV2Message EXCEPT !.numberOfReturnBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleUserModifyRejectedV2Message([ZeroUserModifyRejectedV2Message EXCEPT !.numberOfReturnBitfields = 1, !.userModifyRejectedV2ReturnBitfield1 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedV2Message([ZeroUserModifyRejectedV2Message EXCEPT !.numberOfReturnBitfields = 2, !.userModifyRejectedV2ReturnBitfield2 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedV2Message([ZeroUserModifyRejectedV2Message EXCEPT !.numberOfReturnBitfields = 3, !.userModifyRejectedV2ReturnBitfield3 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedV2Message([ZeroUserModifyRejectedV2Message EXCEPT !.numberOfReturnBitfields = 4, !.userModifyRejectedV2ReturnBitfield4 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedV2Message([ZeroUserModifyRejectedV2Message EXCEPT !.numberOfReturnBitfields = 5, !.userModifyRejectedV2ReturnBitfield5 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedV2Message([ZeroUserModifyRejectedV2Message EXCEPT !.numberOfReturnBitfields = 6, !.userModifyRejectedV2ReturnBitfield6 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedV2Message([ZeroUserModifyRejectedV2Message EXCEPT !.numberOfReturnBitfields = 7, !.userModifyRejectedV2ReturnBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedV2Message([ZeroUserModifyRejectedV2Message EXCEPT !.numberOfReturnBitfields = 8, !.userModifyRejectedV2ReturnBitfield8 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedV2Message([ZeroUserModifyRejectedV2Message EXCEPT !.numberOfReturnBitfields = 9, !.userModifyRejectedV2ReturnBitfield9 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedV2Message([ZeroUserModifyRejectedV2Message EXCEPT !.numberOfReturnBitfields = 10, !.userModifyRejectedV2ReturnBitfield10 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleUserModifyRejectedV2Message([ZeroUserModifyRejectedV2Message EXCEPT !.numberOfReturnBitfields = 11, !.userModifyRejectedV2ReturnBitfield11 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleUserModifyRejectedV2Message([ZeroUserModifyRejectedV2Message EXCEPT !.numberOfReturnBitfields = 12, !.userModifyRejectedV2ReturnBitfield12 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedV2Message([ZeroUserModifyRejectedV2Message EXCEPT !.numberOfReturnBitfields = 13, !.userModifyRejectedV2ReturnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedV2Message([ZeroUserModifyRejectedV2Message EXCEPT !.numberOfReturnBitfields = 14, !.userModifyRejectedV2ReturnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedV2Message([ZeroUserModifyRejectedV2Message EXCEPT !.numberOfReturnBitfields = 10, !.userModifyRejectedV2ReturnBitfield10 = <<16>>, !.waiverType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedV2Message([ZeroUserModifyRejectedV2Message EXCEPT !.numberOfReturnBitfields = 10, !.userModifyRejectedV2ReturnBitfield10 = <<64>>, !.priceFormation = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedV2Message([ZeroUserModifyRejectedV2Message EXCEPT !.numberOfReturnBitfields = 10, !.userModifyRejectedV2ReturnBitfield10 = <<128>>, !.clientQualifiedRole = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedV2Message([ZeroUserModifyRejectedV2Message EXCEPT !.numberOfReturnBitfields = 11, !.userModifyRejectedV2ReturnBitfield11 = <<1>>, !.clientId = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleUserModifyRejectedV2Message([ZeroUserModifyRejectedV2Message EXCEPT !.numberOfReturnBitfields = 11, !.userModifyRejectedV2ReturnBitfield11 = <<2>>, !.investorId = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleUserModifyRejectedV2Message([ZeroUserModifyRejectedV2Message EXCEPT !.numberOfReturnBitfields = 11, !.userModifyRejectedV2ReturnBitfield11 = <<4>>, !.executorId = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleUserModifyRejectedV2Message([ZeroUserModifyRejectedV2Message EXCEPT !.numberOfReturnBitfields = 11, !.userModifyRejectedV2ReturnBitfield11 = <<8>>, !.orderOrigination = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedV2Message([ZeroUserModifyRejectedV2Message EXCEPT !.numberOfReturnBitfields = 11, !.userModifyRejectedV2ReturnBitfield11 = <<16>>, !.algorithmicIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedV2Message([ZeroUserModifyRejectedV2Message EXCEPT !.numberOfReturnBitfields = 11, !.userModifyRejectedV2ReturnBitfield11 = <<32>>, !.deferralReason = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedV2Message([ZeroUserModifyRejectedV2Message EXCEPT !.numberOfReturnBitfields = 11, !.userModifyRejectedV2ReturnBitfield11 = <<64>>, !.investorQualifiedRole = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleUserModifyRejectedV2Message([ZeroUserModifyRejectedV2Message EXCEPT !.numberOfReturnBitfields = 11, !.userModifyRejectedV2ReturnBitfield11 = <<128>>, !.executorQualifiedRole = one]) : one \in { <<held>> : held \in Sample(1) } }

(***************************************************************************)
(* Order Cancelled V 2 Message                                             *)
(***************************************************************************)

OrderCancelledV2Message ==
    [ transactionTime                  : Sample(8),
      clOrdId                          : Sample(20),
      cancelReason                     : Sample(1),
      reserved1                        : Sample(1),
      numberOfReturnBitfields          : 0 .. 255,
      orderCancelledV2ReturnBitfield1  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderCancelledV2ReturnBitfield2  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderCancelledV2ReturnBitfield3  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderCancelledV2ReturnBitfield4  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderCancelledV2ReturnBitfield5  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderCancelledV2ReturnBitfield6  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderCancelledV2ReturnBitfield7  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderCancelledV2ReturnBitfield8  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderCancelledV2ReturnBitfield9  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderCancelledV2ReturnBitfield10 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderCancelledV2ReturnBitfield11 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderCancelledV2ReturnBitfield12 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderCancelledV2ReturnBitfield13 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderCancelledV2ReturnBitfield14 : { << >> } \cup { <<held>> : held \in Sample(1) },
      side                             : { << >> } \cup { <<held>> : held \in Sample(1) },
      pegDifference                    : { << >> } \cup { <<held>> : held \in Sample(8) },
      price                            : { << >> } \cup { <<held>> : held \in Sample(8) },
      execInst                         : { << >> } \cup { <<held>> : held \in Sample(1) },
      ordType                          : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce                      : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                           : { << >> } \cup { <<held>> : held \in Sample(4) },
      symbol                           : { << >> } \cup { <<held>> : held \in Sample(8) },
      currency                         : { << >> } \cup { <<held>> : held \in Sample(3) },
      idSource                         : { << >> } \cup { <<held>> : held \in Sample(1) },
      securityId                       : { << >> } \cup { <<held>> : held \in Sample(16) },
      securityExchange                 : { << >> } \cup { <<held>> : held \in Sample(4) },
      capacity                         : { << >> } \cup { <<held>> : held \in Sample(1) },
      account                          : { << >> } \cup { <<held>> : held \in Sample(16) },
      clearingFirm                     : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingAccount                  : { << >> } \cup { <<held>> : held \in Sample(4) },
      displayIndicator                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      maxFloor                         : { << >> } \cup { <<held>> : held \in Sample(4) },
      orderQty                         : { << >> } \cup { <<held>> : held \in Sample(4) },
      preventParticipantMatch          : { << >> } \cup { <<held>> : held \in Sample(3) },
      correctedSize                    : { << >> } \cup { <<held>> : held \in Sample(4) },
      partyId                          : { << >> } \cup { <<held>> : held \in Sample(4) },
      origClOrdId                      : { << >> } \cup { <<held>> : held \in Sample(20) },
      leavesQty                        : { << >> } \cup { <<held>> : held \in Sample(4) },
      lastShares                       : { << >> } \cup { <<held>> : held \in Sample(4) },
      lastPx                           : { << >> } \cup { <<held>> : held \in Sample(8) },
      displayPrice                     : { << >> } \cup { <<held>> : held \in Sample(8) },
      workingPrice                     : { << >> } \cup { <<held>> : held \in Sample(8) },
      baseLiquidityIndicator           : { << >> } \cup { <<held>> : held \in Sample(1) },
      expireTime                       : { << >> } \cup { <<held>> : held \in Sample(8) },
      secondaryOrderId                 : { << >> } \cup { <<held>> : held \in Sample(8) },
      liquidityProvision               : { << >> } \cup { <<held>> : held \in Sample(1) },
      waiverType                       : { << >> } \cup { <<held>> : held \in Sample(1) },
      priceFormation                   : { << >> } \cup { <<held>> : held \in Sample(1) },
      clientQualifiedRole              : { << >> } \cup { <<held>> : held \in Sample(1) },
      clientId                         : { << >> } \cup { <<held>> : held \in Sample(4) },
      investorId                       : { << >> } \cup { <<held>> : held \in Sample(4) },
      executorId                       : { << >> } \cup { <<held>> : held \in Sample(4) },
      orderOrigination                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      algorithmicIndicator             : { << >> } \cup { <<held>> : held \in Sample(1) },
      deferralReason                   : { << >> } \cup { <<held>> : held \in Sample(1) },
      investorQualifiedRole            : { << >> } \cup { <<held>> : held \in Sample(1) },
      executorQualifiedRole            : { << >> } \cup { <<held>> : held \in Sample(1) } ]

EncodeOrderCancelledV2Message(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.cancelReason
        \o message.reserved1
        \o EncodeUIntBE(message.numberOfReturnBitfields, 1)
        \o (IF message.orderCancelledV2ReturnBitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.orderCancelledV2ReturnBitfield1[1], 1))
        \o (IF message.orderCancelledV2ReturnBitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.orderCancelledV2ReturnBitfield2[1], 1))
        \o (IF message.orderCancelledV2ReturnBitfield3 = << >> THEN << >> ELSE EncodeUIntLE(message.orderCancelledV2ReturnBitfield3[1], 1))
        \o (IF message.orderCancelledV2ReturnBitfield4 = << >> THEN << >> ELSE EncodeUIntLE(message.orderCancelledV2ReturnBitfield4[1], 1))
        \o (IF message.orderCancelledV2ReturnBitfield5 = << >> THEN << >> ELSE EncodeUIntLE(message.orderCancelledV2ReturnBitfield5[1], 1))
        \o (IF message.orderCancelledV2ReturnBitfield6 = << >> THEN << >> ELSE EncodeUIntLE(message.orderCancelledV2ReturnBitfield6[1], 1))
        \o (IF message.orderCancelledV2ReturnBitfield7 = << >> THEN << >> ELSE message.orderCancelledV2ReturnBitfield7[1])
        \o (IF message.orderCancelledV2ReturnBitfield8 = << >> THEN << >> ELSE message.orderCancelledV2ReturnBitfield8[1])
        \o (IF message.orderCancelledV2ReturnBitfield9 = << >> THEN << >> ELSE EncodeUIntLE(message.orderCancelledV2ReturnBitfield9[1], 1))
        \o (IF message.orderCancelledV2ReturnBitfield10 = << >> THEN << >> ELSE EncodeUIntLE(message.orderCancelledV2ReturnBitfield10[1], 1))
        \o (IF message.orderCancelledV2ReturnBitfield11 = << >> THEN << >> ELSE EncodeUIntLE(message.orderCancelledV2ReturnBitfield11[1], 1))
        \o (IF message.orderCancelledV2ReturnBitfield12 = << >> THEN << >> ELSE message.orderCancelledV2ReturnBitfield12[1])
        \o (IF message.orderCancelledV2ReturnBitfield13 = << >> THEN << >> ELSE message.orderCancelledV2ReturnBitfield13[1])
        \o (IF message.orderCancelledV2ReturnBitfield14 = << >> THEN << >> ELSE message.orderCancelledV2ReturnBitfield14[1])
        \o (IF message.side = << >> THEN << >> ELSE message.side[1])
        \o (IF message.pegDifference = << >> THEN << >> ELSE message.pegDifference[1])
        \o (IF message.price = << >> THEN << >> ELSE message.price[1])
        \o (IF message.execInst = << >> THEN << >> ELSE message.execInst[1])
        \o (IF message.ordType = << >> THEN << >> ELSE message.ordType[1])
        \o (IF message.timeInForce = << >> THEN << >> ELSE message.timeInForce[1])
        \o (IF message.minQty = << >> THEN << >> ELSE message.minQty[1])
        \o (IF message.symbol = << >> THEN << >> ELSE message.symbol[1])
        \o (IF message.currency = << >> THEN << >> ELSE message.currency[1])
        \o (IF message.idSource = << >> THEN << >> ELSE message.idSource[1])
        \o (IF message.securityId = << >> THEN << >> ELSE message.securityId[1])
        \o (IF message.securityExchange = << >> THEN << >> ELSE message.securityExchange[1])
        \o (IF message.capacity = << >> THEN << >> ELSE message.capacity[1])
        \o (IF message.account = << >> THEN << >> ELSE message.account[1])
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])
        \o (IF message.clearingAccount = << >> THEN << >> ELSE message.clearingAccount[1])
        \o (IF message.displayIndicator = << >> THEN << >> ELSE message.displayIndicator[1])
        \o (IF message.maxFloor = << >> THEN << >> ELSE message.maxFloor[1])
        \o (IF message.orderQty = << >> THEN << >> ELSE message.orderQty[1])
        \o (IF message.preventParticipantMatch = << >> THEN << >> ELSE message.preventParticipantMatch[1])
        \o (IF message.correctedSize = << >> THEN << >> ELSE message.correctedSize[1])
        \o (IF message.partyId = << >> THEN << >> ELSE message.partyId[1])
        \o (IF message.origClOrdId = << >> THEN << >> ELSE message.origClOrdId[1])
        \o (IF message.leavesQty = << >> THEN << >> ELSE message.leavesQty[1])
        \o (IF message.lastShares = << >> THEN << >> ELSE message.lastShares[1])
        \o (IF message.lastPx = << >> THEN << >> ELSE message.lastPx[1])
        \o (IF message.displayPrice = << >> THEN << >> ELSE message.displayPrice[1])
        \o (IF message.workingPrice = << >> THEN << >> ELSE message.workingPrice[1])
        \o (IF message.baseLiquidityIndicator = << >> THEN << >> ELSE message.baseLiquidityIndicator[1])
        \o (IF message.expireTime = << >> THEN << >> ELSE message.expireTime[1])
        \o (IF message.secondaryOrderId = << >> THEN << >> ELSE message.secondaryOrderId[1])
        \o (IF message.liquidityProvision = << >> THEN << >> ELSE message.liquidityProvision[1])
        \o (IF message.waiverType = << >> THEN << >> ELSE message.waiverType[1])
        \o (IF message.priceFormation = << >> THEN << >> ELSE message.priceFormation[1])
        \o (IF message.clientQualifiedRole = << >> THEN << >> ELSE message.clientQualifiedRole[1])
        \o (IF message.clientId = << >> THEN << >> ELSE message.clientId[1])
        \o (IF message.investorId = << >> THEN << >> ELSE message.investorId[1])
        \o (IF message.executorId = << >> THEN << >> ELSE message.executorId[1])
        \o (IF message.orderOrigination = << >> THEN << >> ELSE message.orderOrigination[1])
        \o (IF message.algorithmicIndicator = << >> THEN << >> ELSE message.algorithmicIndicator[1])
        \o (IF message.deferralReason = << >> THEN << >> ELSE message.deferralReason[1])
        \o (IF message.investorQualifiedRole = << >> THEN << >> ELSE message.investorQualifiedRole[1])
        \o (IF message.executorQualifiedRole = << >> THEN << >> ELSE message.executorQualifiedRole[1])

DecodeOrderCancelledV2Message(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET cancelReason == ReadBytes(clOrdId.rest, 1) IN IF ~cancelReason.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(cancelReason.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET numberOfReturnBitfields == ReadUIntBE(reserved1.rest, 1) IN IF ~numberOfReturnBitfields.ok THEN Fail ELSE
    LET orderCancelledV2ReturnBitfield1 == ReadWhen(numberOfReturnBitfields.value >= 1, ReadUIntLE(numberOfReturnBitfields.rest, 1), numberOfReturnBitfields.rest) IN IF ~orderCancelledV2ReturnBitfield1.ok THEN Fail ELSE
    LET orderCancelledV2ReturnBitfield2 == ReadWhen(numberOfReturnBitfields.value >= 2, ReadUIntLE(orderCancelledV2ReturnBitfield1.rest, 1), orderCancelledV2ReturnBitfield1.rest) IN IF ~orderCancelledV2ReturnBitfield2.ok THEN Fail ELSE
    LET orderCancelledV2ReturnBitfield3 == ReadWhen(numberOfReturnBitfields.value >= 3, ReadUIntLE(orderCancelledV2ReturnBitfield2.rest, 1), orderCancelledV2ReturnBitfield2.rest) IN IF ~orderCancelledV2ReturnBitfield3.ok THEN Fail ELSE
    LET orderCancelledV2ReturnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadUIntLE(orderCancelledV2ReturnBitfield3.rest, 1), orderCancelledV2ReturnBitfield3.rest) IN IF ~orderCancelledV2ReturnBitfield4.ok THEN Fail ELSE
    LET orderCancelledV2ReturnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadUIntLE(orderCancelledV2ReturnBitfield4.rest, 1), orderCancelledV2ReturnBitfield4.rest) IN IF ~orderCancelledV2ReturnBitfield5.ok THEN Fail ELSE
    LET orderCancelledV2ReturnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadUIntLE(orderCancelledV2ReturnBitfield5.rest, 1), orderCancelledV2ReturnBitfield5.rest) IN IF ~orderCancelledV2ReturnBitfield6.ok THEN Fail ELSE
    LET orderCancelledV2ReturnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadBytes(orderCancelledV2ReturnBitfield6.rest, 1), orderCancelledV2ReturnBitfield6.rest) IN IF ~orderCancelledV2ReturnBitfield7.ok THEN Fail ELSE
    LET orderCancelledV2ReturnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadBytes(orderCancelledV2ReturnBitfield7.rest, 1), orderCancelledV2ReturnBitfield7.rest) IN IF ~orderCancelledV2ReturnBitfield8.ok THEN Fail ELSE
    LET orderCancelledV2ReturnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadUIntLE(orderCancelledV2ReturnBitfield8.rest, 1), orderCancelledV2ReturnBitfield8.rest) IN IF ~orderCancelledV2ReturnBitfield9.ok THEN Fail ELSE
    LET orderCancelledV2ReturnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadUIntLE(orderCancelledV2ReturnBitfield9.rest, 1), orderCancelledV2ReturnBitfield9.rest) IN IF ~orderCancelledV2ReturnBitfield10.ok THEN Fail ELSE
    LET orderCancelledV2ReturnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadUIntLE(orderCancelledV2ReturnBitfield10.rest, 1), orderCancelledV2ReturnBitfield10.rest) IN IF ~orderCancelledV2ReturnBitfield11.ok THEN Fail ELSE
    LET orderCancelledV2ReturnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadBytes(orderCancelledV2ReturnBitfield11.rest, 1), orderCancelledV2ReturnBitfield11.rest) IN IF ~orderCancelledV2ReturnBitfield12.ok THEN Fail ELSE
    LET orderCancelledV2ReturnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(orderCancelledV2ReturnBitfield12.rest, 1), orderCancelledV2ReturnBitfield12.rest) IN IF ~orderCancelledV2ReturnBitfield13.ok THEN Fail ELSE
    LET orderCancelledV2ReturnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(orderCancelledV2ReturnBitfield13.rest, 1), orderCancelledV2ReturnBitfield13.rest) IN IF ~orderCancelledV2ReturnBitfield14.ok THEN Fail ELSE
    LET side == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderCancelledV2ReturnBitfield1.value # << >> /\ orderCancelledV2ReturnBitfield1.value[1] % 2 > 0), ReadBytes(orderCancelledV2ReturnBitfield14.rest, 1), orderCancelledV2ReturnBitfield14.rest) IN IF ~side.ok THEN Fail ELSE
    LET pegDifference == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderCancelledV2ReturnBitfield1.value # << >> /\ (orderCancelledV2ReturnBitfield1.value[1] \div 2) % 2 > 0), ReadBytes(side.rest, 8), side.rest) IN IF ~pegDifference.ok THEN Fail ELSE
    LET price == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderCancelledV2ReturnBitfield1.value # << >> /\ (orderCancelledV2ReturnBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(pegDifference.rest, 8), pegDifference.rest) IN IF ~price.ok THEN Fail ELSE
    LET execInst == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderCancelledV2ReturnBitfield1.value # << >> /\ (orderCancelledV2ReturnBitfield1.value[1] \div 8) % 2 > 0), ReadBytes(price.rest, 1), price.rest) IN IF ~execInst.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderCancelledV2ReturnBitfield1.value # << >> /\ (orderCancelledV2ReturnBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(execInst.rest, 1), execInst.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderCancelledV2ReturnBitfield1.value # << >> /\ (orderCancelledV2ReturnBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderCancelledV2ReturnBitfield1.value # << >> /\ (orderCancelledV2ReturnBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET symbol == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderCancelledV2ReturnBitfield2.value # << >> /\ orderCancelledV2ReturnBitfield2.value[1] % 2 > 0), ReadBytes(minQty.rest, 8), minQty.rest) IN IF ~symbol.ok THEN Fail ELSE
    LET currency == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderCancelledV2ReturnBitfield2.value # << >> /\ (orderCancelledV2ReturnBitfield2.value[1] \div 4) % 2 > 0), ReadBytes(symbol.rest, 3), symbol.rest) IN IF ~currency.ok THEN Fail ELSE
    LET idSource == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderCancelledV2ReturnBitfield2.value # << >> /\ (orderCancelledV2ReturnBitfield2.value[1] \div 8) % 2 > 0), ReadBytes(currency.rest, 1), currency.rest) IN IF ~idSource.ok THEN Fail ELSE
    LET securityId == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderCancelledV2ReturnBitfield2.value # << >> /\ (orderCancelledV2ReturnBitfield2.value[1] \div 16) % 2 > 0), ReadBytes(idSource.rest, 16), idSource.rest) IN IF ~securityId.ok THEN Fail ELSE
    LET securityExchange == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderCancelledV2ReturnBitfield2.value # << >> /\ (orderCancelledV2ReturnBitfield2.value[1] \div 32) % 2 > 0), ReadBytes(securityId.rest, 4), securityId.rest) IN IF ~securityExchange.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderCancelledV2ReturnBitfield2.value # << >> /\ (orderCancelledV2ReturnBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(securityExchange.rest, 1), securityExchange.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderCancelledV2ReturnBitfield3.value # << >> /\ orderCancelledV2ReturnBitfield3.value[1] % 2 > 0), ReadBytes(capacity.rest, 16), capacity.rest) IN IF ~account.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderCancelledV2ReturnBitfield3.value # << >> /\ (orderCancelledV2ReturnBitfield3.value[1] \div 2) % 2 > 0), ReadBytes(account.rest, 4), account.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderCancelledV2ReturnBitfield3.value # << >> /\ (orderCancelledV2ReturnBitfield3.value[1] \div 4) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET displayIndicator == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderCancelledV2ReturnBitfield3.value # << >> /\ (orderCancelledV2ReturnBitfield3.value[1] \div 8) % 2 > 0), ReadBytes(clearingAccount.rest, 1), clearingAccount.rest) IN IF ~displayIndicator.ok THEN Fail ELSE
    LET maxFloor == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderCancelledV2ReturnBitfield3.value # << >> /\ (orderCancelledV2ReturnBitfield3.value[1] \div 16) % 2 > 0), ReadBytes(displayIndicator.rest, 4), displayIndicator.rest) IN IF ~maxFloor.ok THEN Fail ELSE
    LET orderQty == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderCancelledV2ReturnBitfield3.value # << >> /\ (orderCancelledV2ReturnBitfield3.value[1] \div 64) % 2 > 0), ReadBytes(maxFloor.rest, 4), maxFloor.rest) IN IF ~orderQty.ok THEN Fail ELSE
    LET preventParticipantMatch == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderCancelledV2ReturnBitfield3.value # << >> /\ (orderCancelledV2ReturnBitfield3.value[1] \div 128) % 2 > 0), ReadBytes(orderQty.rest, 3), orderQty.rest) IN IF ~preventParticipantMatch.ok THEN Fail ELSE
    LET correctedSize == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (orderCancelledV2ReturnBitfield4.value # << >> /\ (orderCancelledV2ReturnBitfield4.value[1] \div 32) % 2 > 0), ReadBytes(preventParticipantMatch.rest, 4), preventParticipantMatch.rest) IN IF ~correctedSize.ok THEN Fail ELSE
    LET partyId == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (orderCancelledV2ReturnBitfield4.value # << >> /\ (orderCancelledV2ReturnBitfield4.value[1] \div 64) % 2 > 0), ReadBytes(correctedSize.rest, 4), correctedSize.rest) IN IF ~partyId.ok THEN Fail ELSE
    LET origClOrdId == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderCancelledV2ReturnBitfield5.value # << >> /\ orderCancelledV2ReturnBitfield5.value[1] % 2 > 0), ReadBytes(partyId.rest, 20), partyId.rest) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET leavesQty == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderCancelledV2ReturnBitfield5.value # << >> /\ (orderCancelledV2ReturnBitfield5.value[1] \div 2) % 2 > 0), ReadBytes(origClOrdId.rest, 4), origClOrdId.rest) IN IF ~leavesQty.ok THEN Fail ELSE
    LET lastShares == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderCancelledV2ReturnBitfield5.value # << >> /\ (orderCancelledV2ReturnBitfield5.value[1] \div 4) % 2 > 0), ReadBytes(leavesQty.rest, 4), leavesQty.rest) IN IF ~lastShares.ok THEN Fail ELSE
    LET lastPx == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderCancelledV2ReturnBitfield5.value # << >> /\ (orderCancelledV2ReturnBitfield5.value[1] \div 8) % 2 > 0), ReadBytes(lastShares.rest, 8), lastShares.rest) IN IF ~lastPx.ok THEN Fail ELSE
    LET displayPrice == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderCancelledV2ReturnBitfield5.value # << >> /\ (orderCancelledV2ReturnBitfield5.value[1] \div 16) % 2 > 0), ReadBytes(lastPx.rest, 8), lastPx.rest) IN IF ~displayPrice.ok THEN Fail ELSE
    LET workingPrice == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderCancelledV2ReturnBitfield5.value # << >> /\ (orderCancelledV2ReturnBitfield5.value[1] \div 32) % 2 > 0), ReadBytes(displayPrice.rest, 8), displayPrice.rest) IN IF ~workingPrice.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderCancelledV2ReturnBitfield5.value # << >> /\ (orderCancelledV2ReturnBitfield5.value[1] \div 64) % 2 > 0), ReadBytes(workingPrice.rest, 1), workingPrice.rest) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET expireTime == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderCancelledV2ReturnBitfield5.value # << >> /\ (orderCancelledV2ReturnBitfield5.value[1] \div 128) % 2 > 0), ReadBytes(baseLiquidityIndicator.rest, 8), baseLiquidityIndicator.rest) IN IF ~expireTime.ok THEN Fail ELSE
    LET secondaryOrderId == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (orderCancelledV2ReturnBitfield6.value # << >> /\ orderCancelledV2ReturnBitfield6.value[1] % 2 > 0), ReadBytes(expireTime.rest, 8), expireTime.rest) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET liquidityProvision == ReadWhen(numberOfReturnBitfields.value >= 9 /\ (orderCancelledV2ReturnBitfield9.value # << >> /\ (orderCancelledV2ReturnBitfield9.value[1] \div 16) % 2 > 0), ReadBytes(secondaryOrderId.rest, 1), secondaryOrderId.rest) IN IF ~liquidityProvision.ok THEN Fail ELSE
    LET waiverType == ReadWhen(numberOfReturnBitfields.value >= 10 /\ (orderCancelledV2ReturnBitfield10.value # << >> /\ (orderCancelledV2ReturnBitfield10.value[1] \div 16) % 2 > 0), ReadBytes(liquidityProvision.rest, 1), liquidityProvision.rest) IN IF ~waiverType.ok THEN Fail ELSE
    LET priceFormation == ReadWhen(numberOfReturnBitfields.value >= 10 /\ (orderCancelledV2ReturnBitfield10.value # << >> /\ (orderCancelledV2ReturnBitfield10.value[1] \div 64) % 2 > 0), ReadBytes(waiverType.rest, 1), waiverType.rest) IN IF ~priceFormation.ok THEN Fail ELSE
    LET clientQualifiedRole == ReadWhen(numberOfReturnBitfields.value >= 10 /\ (orderCancelledV2ReturnBitfield10.value # << >> /\ (orderCancelledV2ReturnBitfield10.value[1] \div 128) % 2 > 0), ReadBytes(priceFormation.rest, 1), priceFormation.rest) IN IF ~clientQualifiedRole.ok THEN Fail ELSE
    LET clientId == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (orderCancelledV2ReturnBitfield11.value # << >> /\ orderCancelledV2ReturnBitfield11.value[1] % 2 > 0), ReadBytes(clientQualifiedRole.rest, 4), clientQualifiedRole.rest) IN IF ~clientId.ok THEN Fail ELSE
    LET investorId == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (orderCancelledV2ReturnBitfield11.value # << >> /\ (orderCancelledV2ReturnBitfield11.value[1] \div 2) % 2 > 0), ReadBytes(clientId.rest, 4), clientId.rest) IN IF ~investorId.ok THEN Fail ELSE
    LET executorId == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (orderCancelledV2ReturnBitfield11.value # << >> /\ (orderCancelledV2ReturnBitfield11.value[1] \div 4) % 2 > 0), ReadBytes(investorId.rest, 4), investorId.rest) IN IF ~executorId.ok THEN Fail ELSE
    LET orderOrigination == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (orderCancelledV2ReturnBitfield11.value # << >> /\ (orderCancelledV2ReturnBitfield11.value[1] \div 8) % 2 > 0), ReadBytes(executorId.rest, 1), executorId.rest) IN IF ~orderOrigination.ok THEN Fail ELSE
    LET algorithmicIndicator == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (orderCancelledV2ReturnBitfield11.value # << >> /\ (orderCancelledV2ReturnBitfield11.value[1] \div 16) % 2 > 0), ReadBytes(orderOrigination.rest, 1), orderOrigination.rest) IN IF ~algorithmicIndicator.ok THEN Fail ELSE
    LET deferralReason == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (orderCancelledV2ReturnBitfield11.value # << >> /\ (orderCancelledV2ReturnBitfield11.value[1] \div 32) % 2 > 0), ReadBytes(algorithmicIndicator.rest, 1), algorithmicIndicator.rest) IN IF ~deferralReason.ok THEN Fail ELSE
    LET investorQualifiedRole == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (orderCancelledV2ReturnBitfield11.value # << >> /\ (orderCancelledV2ReturnBitfield11.value[1] \div 64) % 2 > 0), ReadBytes(deferralReason.rest, 1), deferralReason.rest) IN IF ~investorQualifiedRole.ok THEN Fail ELSE
    LET executorQualifiedRole == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (orderCancelledV2ReturnBitfield11.value # << >> /\ (orderCancelledV2ReturnBitfield11.value[1] \div 128) % 2 > 0), ReadBytes(investorQualifiedRole.rest, 1), investorQualifiedRole.rest) IN IF ~executorQualifiedRole.ok THEN Fail ELSE
    Ok([ transactionTime                  |-> transactionTime.value,
         clOrdId                          |-> clOrdId.value,
         cancelReason                     |-> cancelReason.value,
         reserved1                        |-> reserved1.value,
         numberOfReturnBitfields          |-> numberOfReturnBitfields.value,
         orderCancelledV2ReturnBitfield1  |-> orderCancelledV2ReturnBitfield1.value,
         orderCancelledV2ReturnBitfield2  |-> orderCancelledV2ReturnBitfield2.value,
         orderCancelledV2ReturnBitfield3  |-> orderCancelledV2ReturnBitfield3.value,
         orderCancelledV2ReturnBitfield4  |-> orderCancelledV2ReturnBitfield4.value,
         orderCancelledV2ReturnBitfield5  |-> orderCancelledV2ReturnBitfield5.value,
         orderCancelledV2ReturnBitfield6  |-> orderCancelledV2ReturnBitfield6.value,
         orderCancelledV2ReturnBitfield7  |-> orderCancelledV2ReturnBitfield7.value,
         orderCancelledV2ReturnBitfield8  |-> orderCancelledV2ReturnBitfield8.value,
         orderCancelledV2ReturnBitfield9  |-> orderCancelledV2ReturnBitfield9.value,
         orderCancelledV2ReturnBitfield10 |-> orderCancelledV2ReturnBitfield10.value,
         orderCancelledV2ReturnBitfield11 |-> orderCancelledV2ReturnBitfield11.value,
         orderCancelledV2ReturnBitfield12 |-> orderCancelledV2ReturnBitfield12.value,
         orderCancelledV2ReturnBitfield13 |-> orderCancelledV2ReturnBitfield13.value,
         orderCancelledV2ReturnBitfield14 |-> orderCancelledV2ReturnBitfield14.value,
         side                             |-> side.value,
         pegDifference                    |-> pegDifference.value,
         price                            |-> price.value,
         execInst                         |-> execInst.value,
         ordType                          |-> ordType.value,
         timeInForce                      |-> timeInForce.value,
         minQty                           |-> minQty.value,
         symbol                           |-> symbol.value,
         currency                         |-> currency.value,
         idSource                         |-> idSource.value,
         securityId                       |-> securityId.value,
         securityExchange                 |-> securityExchange.value,
         capacity                         |-> capacity.value,
         account                          |-> account.value,
         clearingFirm                     |-> clearingFirm.value,
         clearingAccount                  |-> clearingAccount.value,
         displayIndicator                 |-> displayIndicator.value,
         maxFloor                         |-> maxFloor.value,
         orderQty                         |-> orderQty.value,
         preventParticipantMatch          |-> preventParticipantMatch.value,
         correctedSize                    |-> correctedSize.value,
         partyId                          |-> partyId.value,
         origClOrdId                      |-> origClOrdId.value,
         leavesQty                        |-> leavesQty.value,
         lastShares                       |-> lastShares.value,
         lastPx                           |-> lastPx.value,
         displayPrice                     |-> displayPrice.value,
         workingPrice                     |-> workingPrice.value,
         baseLiquidityIndicator           |-> baseLiquidityIndicator.value,
         expireTime                       |-> expireTime.value,
         secondaryOrderId                 |-> secondaryOrderId.value,
         liquidityProvision               |-> liquidityProvision.value,
         waiverType                       |-> waiverType.value,
         priceFormation                   |-> priceFormation.value,
         clientQualifiedRole              |-> clientQualifiedRole.value,
         clientId                         |-> clientId.value,
         investorId                       |-> investorId.value,
         executorId                       |-> executorId.value,
         orderOrigination                 |-> orderOrigination.value,
         algorithmicIndicator             |-> algorithmicIndicator.value,
         deferralReason                   |-> deferralReason.value,
         investorQualifiedRole            |-> investorQualifiedRole.value,
         executorQualifiedRole            |-> executorQualifiedRole.value ], executorQualifiedRole.rest)

(* Order Cancelled V 2 Message with each field marked present by fields before it there exactly where they say *)
SettleOrderCancelledV2Message(message) ==
    LET settled1 == [message EXCEPT !.orderCancelledV2ReturnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.orderCancelledV2ReturnBitfield1 = << >> THEN <<0>> ELSE message.orderCancelledV2ReturnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.orderCancelledV2ReturnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.orderCancelledV2ReturnBitfield2 = << >> THEN <<0>> ELSE settled1.orderCancelledV2ReturnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.orderCancelledV2ReturnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.orderCancelledV2ReturnBitfield3 = << >> THEN <<0>> ELSE settled2.orderCancelledV2ReturnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.orderCancelledV2ReturnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.orderCancelledV2ReturnBitfield4 = << >> THEN <<0>> ELSE settled3.orderCancelledV2ReturnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.orderCancelledV2ReturnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.orderCancelledV2ReturnBitfield5 = << >> THEN <<0>> ELSE settled4.orderCancelledV2ReturnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.orderCancelledV2ReturnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.orderCancelledV2ReturnBitfield6 = << >> THEN <<0>> ELSE settled5.orderCancelledV2ReturnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.orderCancelledV2ReturnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.orderCancelledV2ReturnBitfield7 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.orderCancelledV2ReturnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.orderCancelledV2ReturnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.orderCancelledV2ReturnBitfield8 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled7.orderCancelledV2ReturnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.orderCancelledV2ReturnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.orderCancelledV2ReturnBitfield9 = << >> THEN <<0>> ELSE settled8.orderCancelledV2ReturnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.orderCancelledV2ReturnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.orderCancelledV2ReturnBitfield10 = << >> THEN <<0>> ELSE settled9.orderCancelledV2ReturnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.orderCancelledV2ReturnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.orderCancelledV2ReturnBitfield11 = << >> THEN <<0>> ELSE settled10.orderCancelledV2ReturnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.orderCancelledV2ReturnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.orderCancelledV2ReturnBitfield12 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.orderCancelledV2ReturnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.orderCancelledV2ReturnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.orderCancelledV2ReturnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.orderCancelledV2ReturnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.orderCancelledV2ReturnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.orderCancelledV2ReturnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.orderCancelledV2ReturnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.side = IF settled14.numberOfReturnBitfields >= 1 /\ (settled14.orderCancelledV2ReturnBitfield1 # << >> /\ settled14.orderCancelledV2ReturnBitfield1[1] % 2 > 0) THEN (IF settled14.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.side) ELSE << >>]
        settled16 == [settled15 EXCEPT !.pegDifference = IF settled15.numberOfReturnBitfields >= 1 /\ (settled15.orderCancelledV2ReturnBitfield1 # << >> /\ (settled15.orderCancelledV2ReturnBitfield1[1] \div 2) % 2 > 0) THEN (IF settled15.pegDifference = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled15.pegDifference) ELSE << >>]
        settled17 == [settled16 EXCEPT !.price = IF settled16.numberOfReturnBitfields >= 1 /\ (settled16.orderCancelledV2ReturnBitfield1 # << >> /\ (settled16.orderCancelledV2ReturnBitfield1[1] \div 4) % 2 > 0) THEN (IF settled16.price = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled16.price) ELSE << >>]
        settled18 == [settled17 EXCEPT !.execInst = IF settled17.numberOfReturnBitfields >= 1 /\ (settled17.orderCancelledV2ReturnBitfield1 # << >> /\ (settled17.orderCancelledV2ReturnBitfield1[1] \div 8) % 2 > 0) THEN (IF settled17.execInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.execInst) ELSE << >>]
        settled19 == [settled18 EXCEPT !.ordType = IF settled18.numberOfReturnBitfields >= 1 /\ (settled18.orderCancelledV2ReturnBitfield1 # << >> /\ (settled18.orderCancelledV2ReturnBitfield1[1] \div 16) % 2 > 0) THEN (IF settled18.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled18.ordType) ELSE << >>]
        settled20 == [settled19 EXCEPT !.timeInForce = IF settled19.numberOfReturnBitfields >= 1 /\ (settled19.orderCancelledV2ReturnBitfield1 # << >> /\ (settled19.orderCancelledV2ReturnBitfield1[1] \div 32) % 2 > 0) THEN (IF settled19.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled19.timeInForce) ELSE << >>]
        settled21 == [settled20 EXCEPT !.minQty = IF settled20.numberOfReturnBitfields >= 1 /\ (settled20.orderCancelledV2ReturnBitfield1 # << >> /\ (settled20.orderCancelledV2ReturnBitfield1[1] \div 64) % 2 > 0) THEN (IF settled20.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled20.minQty) ELSE << >>]
        settled22 == [settled21 EXCEPT !.symbol = IF settled21.numberOfReturnBitfields >= 2 /\ (settled21.orderCancelledV2ReturnBitfield2 # << >> /\ settled21.orderCancelledV2ReturnBitfield2[1] % 2 > 0) THEN (IF settled21.symbol = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled21.symbol) ELSE << >>]
        settled23 == [settled22 EXCEPT !.currency = IF settled22.numberOfReturnBitfields >= 2 /\ (settled22.orderCancelledV2ReturnBitfield2 # << >> /\ (settled22.orderCancelledV2ReturnBitfield2[1] \div 4) % 2 > 0) THEN (IF settled22.currency = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled22.currency) ELSE << >>]
        settled24 == [settled23 EXCEPT !.idSource = IF settled23.numberOfReturnBitfields >= 2 /\ (settled23.orderCancelledV2ReturnBitfield2 # << >> /\ (settled23.orderCancelledV2ReturnBitfield2[1] \div 8) % 2 > 0) THEN (IF settled23.idSource = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled23.idSource) ELSE << >>]
        settled25 == [settled24 EXCEPT !.securityId = IF settled24.numberOfReturnBitfields >= 2 /\ (settled24.orderCancelledV2ReturnBitfield2 # << >> /\ (settled24.orderCancelledV2ReturnBitfield2[1] \div 16) % 2 > 0) THEN (IF settled24.securityId = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled24.securityId) ELSE << >>]
        settled26 == [settled25 EXCEPT !.securityExchange = IF settled25.numberOfReturnBitfields >= 2 /\ (settled25.orderCancelledV2ReturnBitfield2 # << >> /\ (settled25.orderCancelledV2ReturnBitfield2[1] \div 32) % 2 > 0) THEN (IF settled25.securityExchange = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled25.securityExchange) ELSE << >>]
        settled27 == [settled26 EXCEPT !.capacity = IF settled26.numberOfReturnBitfields >= 2 /\ (settled26.orderCancelledV2ReturnBitfield2 # << >> /\ (settled26.orderCancelledV2ReturnBitfield2[1] \div 64) % 2 > 0) THEN (IF settled26.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled26.capacity) ELSE << >>]
        settled28 == [settled27 EXCEPT !.account = IF settled27.numberOfReturnBitfields >= 3 /\ (settled27.orderCancelledV2ReturnBitfield3 # << >> /\ settled27.orderCancelledV2ReturnBitfield3[1] % 2 > 0) THEN (IF settled27.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled27.account) ELSE << >>]
        settled29 == [settled28 EXCEPT !.clearingFirm = IF settled28.numberOfReturnBitfields >= 3 /\ (settled28.orderCancelledV2ReturnBitfield3 # << >> /\ (settled28.orderCancelledV2ReturnBitfield3[1] \div 2) % 2 > 0) THEN (IF settled28.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled28.clearingFirm) ELSE << >>]
        settled30 == [settled29 EXCEPT !.clearingAccount = IF settled29.numberOfReturnBitfields >= 3 /\ (settled29.orderCancelledV2ReturnBitfield3 # << >> /\ (settled29.orderCancelledV2ReturnBitfield3[1] \div 4) % 2 > 0) THEN (IF settled29.clearingAccount = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled29.clearingAccount) ELSE << >>]
        settled31 == [settled30 EXCEPT !.displayIndicator = IF settled30.numberOfReturnBitfields >= 3 /\ (settled30.orderCancelledV2ReturnBitfield3 # << >> /\ (settled30.orderCancelledV2ReturnBitfield3[1] \div 8) % 2 > 0) THEN (IF settled30.displayIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled30.displayIndicator) ELSE << >>]
        settled32 == [settled31 EXCEPT !.maxFloor = IF settled31.numberOfReturnBitfields >= 3 /\ (settled31.orderCancelledV2ReturnBitfield3 # << >> /\ (settled31.orderCancelledV2ReturnBitfield3[1] \div 16) % 2 > 0) THEN (IF settled31.maxFloor = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled31.maxFloor) ELSE << >>]
        settled33 == [settled32 EXCEPT !.orderQty = IF settled32.numberOfReturnBitfields >= 3 /\ (settled32.orderCancelledV2ReturnBitfield3 # << >> /\ (settled32.orderCancelledV2ReturnBitfield3[1] \div 64) % 2 > 0) THEN (IF settled32.orderQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled32.orderQty) ELSE << >>]
        settled34 == [settled33 EXCEPT !.preventParticipantMatch = IF settled33.numberOfReturnBitfields >= 3 /\ (settled33.orderCancelledV2ReturnBitfield3 # << >> /\ (settled33.orderCancelledV2ReturnBitfield3[1] \div 128) % 2 > 0) THEN (IF settled33.preventParticipantMatch = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled33.preventParticipantMatch) ELSE << >>]
        settled35 == [settled34 EXCEPT !.correctedSize = IF settled34.numberOfReturnBitfields >= 4 /\ (settled34.orderCancelledV2ReturnBitfield4 # << >> /\ (settled34.orderCancelledV2ReturnBitfield4[1] \div 32) % 2 > 0) THEN (IF settled34.correctedSize = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled34.correctedSize) ELSE << >>]
        settled36 == [settled35 EXCEPT !.partyId = IF settled35.numberOfReturnBitfields >= 4 /\ (settled35.orderCancelledV2ReturnBitfield4 # << >> /\ (settled35.orderCancelledV2ReturnBitfield4[1] \div 64) % 2 > 0) THEN (IF settled35.partyId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled35.partyId) ELSE << >>]
        settled37 == [settled36 EXCEPT !.origClOrdId = IF settled36.numberOfReturnBitfields >= 5 /\ (settled36.orderCancelledV2ReturnBitfield5 # << >> /\ settled36.orderCancelledV2ReturnBitfield5[1] % 2 > 0) THEN (IF settled36.origClOrdId = << >> THEN <<[i \in 1 .. 20 |-> 0]>> ELSE settled36.origClOrdId) ELSE << >>]
        settled38 == [settled37 EXCEPT !.leavesQty = IF settled37.numberOfReturnBitfields >= 5 /\ (settled37.orderCancelledV2ReturnBitfield5 # << >> /\ (settled37.orderCancelledV2ReturnBitfield5[1] \div 2) % 2 > 0) THEN (IF settled37.leavesQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled37.leavesQty) ELSE << >>]
        settled39 == [settled38 EXCEPT !.lastShares = IF settled38.numberOfReturnBitfields >= 5 /\ (settled38.orderCancelledV2ReturnBitfield5 # << >> /\ (settled38.orderCancelledV2ReturnBitfield5[1] \div 4) % 2 > 0) THEN (IF settled38.lastShares = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled38.lastShares) ELSE << >>]
        settled40 == [settled39 EXCEPT !.lastPx = IF settled39.numberOfReturnBitfields >= 5 /\ (settled39.orderCancelledV2ReturnBitfield5 # << >> /\ (settled39.orderCancelledV2ReturnBitfield5[1] \div 8) % 2 > 0) THEN (IF settled39.lastPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled39.lastPx) ELSE << >>]
        settled41 == [settled40 EXCEPT !.displayPrice = IF settled40.numberOfReturnBitfields >= 5 /\ (settled40.orderCancelledV2ReturnBitfield5 # << >> /\ (settled40.orderCancelledV2ReturnBitfield5[1] \div 16) % 2 > 0) THEN (IF settled40.displayPrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled40.displayPrice) ELSE << >>]
        settled42 == [settled41 EXCEPT !.workingPrice = IF settled41.numberOfReturnBitfields >= 5 /\ (settled41.orderCancelledV2ReturnBitfield5 # << >> /\ (settled41.orderCancelledV2ReturnBitfield5[1] \div 32) % 2 > 0) THEN (IF settled41.workingPrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled41.workingPrice) ELSE << >>]
        settled43 == [settled42 EXCEPT !.baseLiquidityIndicator = IF settled42.numberOfReturnBitfields >= 5 /\ (settled42.orderCancelledV2ReturnBitfield5 # << >> /\ (settled42.orderCancelledV2ReturnBitfield5[1] \div 64) % 2 > 0) THEN (IF settled42.baseLiquidityIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled42.baseLiquidityIndicator) ELSE << >>]
        settled44 == [settled43 EXCEPT !.expireTime = IF settled43.numberOfReturnBitfields >= 5 /\ (settled43.orderCancelledV2ReturnBitfield5 # << >> /\ (settled43.orderCancelledV2ReturnBitfield5[1] \div 128) % 2 > 0) THEN (IF settled43.expireTime = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled43.expireTime) ELSE << >>]
        settled45 == [settled44 EXCEPT !.secondaryOrderId = IF settled44.numberOfReturnBitfields >= 6 /\ (settled44.orderCancelledV2ReturnBitfield6 # << >> /\ settled44.orderCancelledV2ReturnBitfield6[1] % 2 > 0) THEN (IF settled44.secondaryOrderId = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled44.secondaryOrderId) ELSE << >>]
        settled46 == [settled45 EXCEPT !.liquidityProvision = IF settled45.numberOfReturnBitfields >= 9 /\ (settled45.orderCancelledV2ReturnBitfield9 # << >> /\ (settled45.orderCancelledV2ReturnBitfield9[1] \div 16) % 2 > 0) THEN (IF settled45.liquidityProvision = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled45.liquidityProvision) ELSE << >>]
        settled47 == [settled46 EXCEPT !.waiverType = IF settled46.numberOfReturnBitfields >= 10 /\ (settled46.orderCancelledV2ReturnBitfield10 # << >> /\ (settled46.orderCancelledV2ReturnBitfield10[1] \div 16) % 2 > 0) THEN (IF settled46.waiverType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled46.waiverType) ELSE << >>]
        settled48 == [settled47 EXCEPT !.priceFormation = IF settled47.numberOfReturnBitfields >= 10 /\ (settled47.orderCancelledV2ReturnBitfield10 # << >> /\ (settled47.orderCancelledV2ReturnBitfield10[1] \div 64) % 2 > 0) THEN (IF settled47.priceFormation = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled47.priceFormation) ELSE << >>]
        settled49 == [settled48 EXCEPT !.clientQualifiedRole = IF settled48.numberOfReturnBitfields >= 10 /\ (settled48.orderCancelledV2ReturnBitfield10 # << >> /\ (settled48.orderCancelledV2ReturnBitfield10[1] \div 128) % 2 > 0) THEN (IF settled48.clientQualifiedRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled48.clientQualifiedRole) ELSE << >>]
        settled50 == [settled49 EXCEPT !.clientId = IF settled49.numberOfReturnBitfields >= 11 /\ (settled49.orderCancelledV2ReturnBitfield11 # << >> /\ settled49.orderCancelledV2ReturnBitfield11[1] % 2 > 0) THEN (IF settled49.clientId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled49.clientId) ELSE << >>]
        settled51 == [settled50 EXCEPT !.investorId = IF settled50.numberOfReturnBitfields >= 11 /\ (settled50.orderCancelledV2ReturnBitfield11 # << >> /\ (settled50.orderCancelledV2ReturnBitfield11[1] \div 2) % 2 > 0) THEN (IF settled50.investorId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled50.investorId) ELSE << >>]
        settled52 == [settled51 EXCEPT !.executorId = IF settled51.numberOfReturnBitfields >= 11 /\ (settled51.orderCancelledV2ReturnBitfield11 # << >> /\ (settled51.orderCancelledV2ReturnBitfield11[1] \div 4) % 2 > 0) THEN (IF settled51.executorId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled51.executorId) ELSE << >>]
        settled53 == [settled52 EXCEPT !.orderOrigination = IF settled52.numberOfReturnBitfields >= 11 /\ (settled52.orderCancelledV2ReturnBitfield11 # << >> /\ (settled52.orderCancelledV2ReturnBitfield11[1] \div 8) % 2 > 0) THEN (IF settled52.orderOrigination = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled52.orderOrigination) ELSE << >>]
        settled54 == [settled53 EXCEPT !.algorithmicIndicator = IF settled53.numberOfReturnBitfields >= 11 /\ (settled53.orderCancelledV2ReturnBitfield11 # << >> /\ (settled53.orderCancelledV2ReturnBitfield11[1] \div 16) % 2 > 0) THEN (IF settled53.algorithmicIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled53.algorithmicIndicator) ELSE << >>]
        settled55 == [settled54 EXCEPT !.deferralReason = IF settled54.numberOfReturnBitfields >= 11 /\ (settled54.orderCancelledV2ReturnBitfield11 # << >> /\ (settled54.orderCancelledV2ReturnBitfield11[1] \div 32) % 2 > 0) THEN (IF settled54.deferralReason = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled54.deferralReason) ELSE << >>]
        settled56 == [settled55 EXCEPT !.investorQualifiedRole = IF settled55.numberOfReturnBitfields >= 11 /\ (settled55.orderCancelledV2ReturnBitfield11 # << >> /\ (settled55.orderCancelledV2ReturnBitfield11[1] \div 64) % 2 > 0) THEN (IF settled55.investorQualifiedRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled55.investorQualifiedRole) ELSE << >>]
        settled57 == [settled56 EXCEPT !.executorQualifiedRole = IF settled56.numberOfReturnBitfields >= 11 /\ (settled56.orderCancelledV2ReturnBitfield11 # << >> /\ (settled56.orderCancelledV2ReturnBitfield11[1] \div 128) % 2 > 0) THEN (IF settled56.executorQualifiedRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled56.executorQualifiedRole) ELSE << >>]
    IN  settled57

ZeroOrderCancelledV2Message ==
    SettleOrderCancelledV2Message([ transactionTime                  |-> [i \in 1 .. 8 |-> 0],
                                    clOrdId                          |-> [i \in 1 .. 20 |-> 0],
                                    cancelReason                     |-> [i \in 1 .. 1 |-> 0],
                                    reserved1                        |-> [i \in 1 .. 1 |-> 0],
                                    numberOfReturnBitfields          |-> 0,
                                    orderCancelledV2ReturnBitfield1  |-> << >>,
                                    orderCancelledV2ReturnBitfield2  |-> << >>,
                                    orderCancelledV2ReturnBitfield3  |-> << >>,
                                    orderCancelledV2ReturnBitfield4  |-> << >>,
                                    orderCancelledV2ReturnBitfield5  |-> << >>,
                                    orderCancelledV2ReturnBitfield6  |-> << >>,
                                    orderCancelledV2ReturnBitfield7  |-> << >>,
                                    orderCancelledV2ReturnBitfield8  |-> << >>,
                                    orderCancelledV2ReturnBitfield9  |-> << >>,
                                    orderCancelledV2ReturnBitfield10 |-> << >>,
                                    orderCancelledV2ReturnBitfield11 |-> << >>,
                                    orderCancelledV2ReturnBitfield12 |-> << >>,
                                    orderCancelledV2ReturnBitfield13 |-> << >>,
                                    orderCancelledV2ReturnBitfield14 |-> << >>,
                                    side                             |-> << >>,
                                    pegDifference                    |-> << >>,
                                    price                            |-> << >>,
                                    execInst                         |-> << >>,
                                    ordType                          |-> << >>,
                                    timeInForce                      |-> << >>,
                                    minQty                           |-> << >>,
                                    symbol                           |-> << >>,
                                    currency                         |-> << >>,
                                    idSource                         |-> << >>,
                                    securityId                       |-> << >>,
                                    securityExchange                 |-> << >>,
                                    capacity                         |-> << >>,
                                    account                          |-> << >>,
                                    clearingFirm                     |-> << >>,
                                    clearingAccount                  |-> << >>,
                                    displayIndicator                 |-> << >>,
                                    maxFloor                         |-> << >>,
                                    orderQty                         |-> << >>,
                                    preventParticipantMatch          |-> << >>,
                                    correctedSize                    |-> << >>,
                                    partyId                          |-> << >>,
                                    origClOrdId                      |-> << >>,
                                    leavesQty                        |-> << >>,
                                    lastShares                       |-> << >>,
                                    lastPx                           |-> << >>,
                                    displayPrice                     |-> << >>,
                                    workingPrice                     |-> << >>,
                                    baseLiquidityIndicator           |-> << >>,
                                    expireTime                       |-> << >>,
                                    secondaryOrderId                 |-> << >>,
                                    liquidityProvision               |-> << >>,
                                    waiverType                       |-> << >>,
                                    priceFormation                   |-> << >>,
                                    clientQualifiedRole              |-> << >>,
                                    clientId                         |-> << >>,
                                    investorId                       |-> << >>,
                                    executorId                       |-> << >>,
                                    orderOrigination                 |-> << >>,
                                    algorithmicIndicator             |-> << >>,
                                    deferralReason                   |-> << >>,
                                    investorQualifiedRole            |-> << >>,
                                    executorQualifiedRole            |-> << >> ])

(* Order Cancelled V 2 Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelledV2Message ==
    { ZeroOrderCancelledV2Message }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.transactionTime = one]) : one \in Sample(8) }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.clOrdId = one]) : one \in Sample(20) }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.cancelReason = one]) : one \in Sample(1) }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.reserved1 = one]) : one \in Sample(1) }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderCancelledV2ReturnBitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 2, !.orderCancelledV2ReturnBitfield2 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderCancelledV2ReturnBitfield3 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 4, !.orderCancelledV2ReturnBitfield4 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 5, !.orderCancelledV2ReturnBitfield5 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 6, !.orderCancelledV2ReturnBitfield6 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 7, !.orderCancelledV2ReturnBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 8, !.orderCancelledV2ReturnBitfield8 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 9, !.orderCancelledV2ReturnBitfield9 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 10, !.orderCancelledV2ReturnBitfield10 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderCancelledV2ReturnBitfield11 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 12, !.orderCancelledV2ReturnBitfield12 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 13, !.orderCancelledV2ReturnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 14, !.orderCancelledV2ReturnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderCancelledV2ReturnBitfield1 = <<1>>, !.side = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderCancelledV2ReturnBitfield1 = <<2>>, !.pegDifference = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderCancelledV2ReturnBitfield1 = <<4>>, !.price = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderCancelledV2ReturnBitfield1 = <<8>>, !.execInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderCancelledV2ReturnBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderCancelledV2ReturnBitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderCancelledV2ReturnBitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 2, !.orderCancelledV2ReturnBitfield2 = <<1>>, !.symbol = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 2, !.orderCancelledV2ReturnBitfield2 = <<4>>, !.currency = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 2, !.orderCancelledV2ReturnBitfield2 = <<8>>, !.idSource = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 2, !.orderCancelledV2ReturnBitfield2 = <<16>>, !.securityId = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 2, !.orderCancelledV2ReturnBitfield2 = <<32>>, !.securityExchange = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 2, !.orderCancelledV2ReturnBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderCancelledV2ReturnBitfield3 = <<1>>, !.account = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderCancelledV2ReturnBitfield3 = <<2>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderCancelledV2ReturnBitfield3 = <<4>>, !.clearingAccount = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderCancelledV2ReturnBitfield3 = <<8>>, !.displayIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderCancelledV2ReturnBitfield3 = <<16>>, !.maxFloor = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderCancelledV2ReturnBitfield3 = <<64>>, !.orderQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderCancelledV2ReturnBitfield3 = <<128>>, !.preventParticipantMatch = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 4, !.orderCancelledV2ReturnBitfield4 = <<32>>, !.correctedSize = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 4, !.orderCancelledV2ReturnBitfield4 = <<64>>, !.partyId = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 5, !.orderCancelledV2ReturnBitfield5 = <<1>>, !.origClOrdId = one]) : one \in { <<held>> : held \in Sample(20) } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 5, !.orderCancelledV2ReturnBitfield5 = <<2>>, !.leavesQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 5, !.orderCancelledV2ReturnBitfield5 = <<4>>, !.lastShares = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 5, !.orderCancelledV2ReturnBitfield5 = <<8>>, !.lastPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 5, !.orderCancelledV2ReturnBitfield5 = <<16>>, !.displayPrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 5, !.orderCancelledV2ReturnBitfield5 = <<32>>, !.workingPrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 5, !.orderCancelledV2ReturnBitfield5 = <<64>>, !.baseLiquidityIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 5, !.orderCancelledV2ReturnBitfield5 = <<128>>, !.expireTime = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 6, !.orderCancelledV2ReturnBitfield6 = <<1>>, !.secondaryOrderId = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 9, !.orderCancelledV2ReturnBitfield9 = <<16>>, !.liquidityProvision = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 10, !.orderCancelledV2ReturnBitfield10 = <<16>>, !.waiverType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 10, !.orderCancelledV2ReturnBitfield10 = <<64>>, !.priceFormation = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 10, !.orderCancelledV2ReturnBitfield10 = <<128>>, !.clientQualifiedRole = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderCancelledV2ReturnBitfield11 = <<1>>, !.clientId = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderCancelledV2ReturnBitfield11 = <<2>>, !.investorId = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderCancelledV2ReturnBitfield11 = <<4>>, !.executorId = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderCancelledV2ReturnBitfield11 = <<8>>, !.orderOrigination = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderCancelledV2ReturnBitfield11 = <<16>>, !.algorithmicIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderCancelledV2ReturnBitfield11 = <<32>>, !.deferralReason = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderCancelledV2ReturnBitfield11 = <<64>>, !.investorQualifiedRole = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledV2Message([ZeroOrderCancelledV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderCancelledV2ReturnBitfield11 = <<128>>, !.executorQualifiedRole = one]) : one \in { <<held>> : held \in Sample(1) } }

(***************************************************************************)
(* Cancel Rejected V 2 Message                                             *)
(***************************************************************************)

CancelRejectedV2Message ==
    [ transactionTime                  : Sample(8),
      clOrdId                          : Sample(20),
      cancelRejectReason               : Sample(1),
      text                             : Sample(60),
      reserved1                        : Sample(1),
      numberOfReturnBitfields          : 0 .. 255,
      cancelRejectedV2ReturnBitfield1  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      cancelRejectedV2ReturnBitfield2  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      cancelRejectedV2ReturnBitfield3  : { << >> } \cup { <<held>> : held \in Sample(1) },
      cancelRejectedV2ReturnBitfield4  : { << >> } \cup { <<held>> : held \in Sample(1) },
      cancelRejectedV2ReturnBitfield5  : { << >> } \cup { <<held>> : held \in Sample(1) },
      cancelRejectedV2ReturnBitfield6  : { << >> } \cup { <<held>> : held \in Sample(1) },
      cancelRejectedV2ReturnBitfield7  : { << >> } \cup { <<held>> : held \in Sample(1) },
      cancelRejectedV2ReturnBitfield8  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      cancelRejectedV2ReturnBitfield9  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      cancelRejectedV2ReturnBitfield10 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      cancelRejectedV2ReturnBitfield11 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      cancelRejectedV2ReturnBitfield12 : { << >> } \cup { <<held>> : held \in Sample(1) },
      cancelRejectedV2ReturnBitfield13 : { << >> } \cup { <<held>> : held \in Sample(1) },
      cancelRejectedV2ReturnBitfield14 : { << >> } \cup { <<held>> : held \in Sample(1) },
      side                             : { << >> } \cup { <<held>> : held \in Sample(1) },
      pegDifference                    : { << >> } \cup { <<held>> : held \in Sample(8) },
      price                            : { << >> } \cup { <<held>> : held \in Sample(8) },
      execInst                         : { << >> } \cup { <<held>> : held \in Sample(1) },
      ordType                          : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce                      : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                           : { << >> } \cup { <<held>> : held \in Sample(4) },
      symbol                           : { << >> } \cup { <<held>> : held \in Sample(8) },
      currency                         : { << >> } \cup { <<held>> : held \in Sample(3) },
      idSource                         : { << >> } \cup { <<held>> : held \in Sample(1) },
      securityId                       : { << >> } \cup { <<held>> : held \in Sample(16) },
      securityExchange                 : { << >> } \cup { <<held>> : held \in Sample(4) },
      capacity                         : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeReportRefId                 : { << >> } \cup { <<held>> : held \in Sample(20) },
      liquidityProvision               : { << >> } \cup { <<held>> : held \in Sample(1) },
      waiverType                       : { << >> } \cup { <<held>> : held \in Sample(1) },
      priceFormation                   : { << >> } \cup { <<held>> : held \in Sample(1) },
      clientQualifiedRole              : { << >> } \cup { <<held>> : held \in Sample(1) },
      clientId                         : { << >> } \cup { <<held>> : held \in Sample(4) },
      investorId                       : { << >> } \cup { <<held>> : held \in Sample(4) },
      executorId                       : { << >> } \cup { <<held>> : held \in Sample(4) },
      orderOrigination                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      algorithmicIndicator             : { << >> } \cup { <<held>> : held \in Sample(1) },
      deferralReason                   : { << >> } \cup { <<held>> : held \in Sample(1) },
      investorQualifiedRole            : { << >> } \cup { <<held>> : held \in Sample(1) },
      executorQualifiedRole            : { << >> } \cup { <<held>> : held \in Sample(1) } ]

EncodeCancelRejectedV2Message(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.cancelRejectReason
        \o message.text
        \o message.reserved1
        \o EncodeUIntBE(message.numberOfReturnBitfields, 1)
        \o (IF message.cancelRejectedV2ReturnBitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.cancelRejectedV2ReturnBitfield1[1], 1))
        \o (IF message.cancelRejectedV2ReturnBitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.cancelRejectedV2ReturnBitfield2[1], 1))
        \o (IF message.cancelRejectedV2ReturnBitfield3 = << >> THEN << >> ELSE message.cancelRejectedV2ReturnBitfield3[1])
        \o (IF message.cancelRejectedV2ReturnBitfield4 = << >> THEN << >> ELSE message.cancelRejectedV2ReturnBitfield4[1])
        \o (IF message.cancelRejectedV2ReturnBitfield5 = << >> THEN << >> ELSE message.cancelRejectedV2ReturnBitfield5[1])
        \o (IF message.cancelRejectedV2ReturnBitfield6 = << >> THEN << >> ELSE message.cancelRejectedV2ReturnBitfield6[1])
        \o (IF message.cancelRejectedV2ReturnBitfield7 = << >> THEN << >> ELSE message.cancelRejectedV2ReturnBitfield7[1])
        \o (IF message.cancelRejectedV2ReturnBitfield8 = << >> THEN << >> ELSE EncodeUIntLE(message.cancelRejectedV2ReturnBitfield8[1], 1))
        \o (IF message.cancelRejectedV2ReturnBitfield9 = << >> THEN << >> ELSE EncodeUIntLE(message.cancelRejectedV2ReturnBitfield9[1], 1))
        \o (IF message.cancelRejectedV2ReturnBitfield10 = << >> THEN << >> ELSE EncodeUIntLE(message.cancelRejectedV2ReturnBitfield10[1], 1))
        \o (IF message.cancelRejectedV2ReturnBitfield11 = << >> THEN << >> ELSE EncodeUIntLE(message.cancelRejectedV2ReturnBitfield11[1], 1))
        \o (IF message.cancelRejectedV2ReturnBitfield12 = << >> THEN << >> ELSE message.cancelRejectedV2ReturnBitfield12[1])
        \o (IF message.cancelRejectedV2ReturnBitfield13 = << >> THEN << >> ELSE message.cancelRejectedV2ReturnBitfield13[1])
        \o (IF message.cancelRejectedV2ReturnBitfield14 = << >> THEN << >> ELSE message.cancelRejectedV2ReturnBitfield14[1])
        \o (IF message.side = << >> THEN << >> ELSE message.side[1])
        \o (IF message.pegDifference = << >> THEN << >> ELSE message.pegDifference[1])
        \o (IF message.price = << >> THEN << >> ELSE message.price[1])
        \o (IF message.execInst = << >> THEN << >> ELSE message.execInst[1])
        \o (IF message.ordType = << >> THEN << >> ELSE message.ordType[1])
        \o (IF message.timeInForce = << >> THEN << >> ELSE message.timeInForce[1])
        \o (IF message.minQty = << >> THEN << >> ELSE message.minQty[1])
        \o (IF message.symbol = << >> THEN << >> ELSE message.symbol[1])
        \o (IF message.currency = << >> THEN << >> ELSE message.currency[1])
        \o (IF message.idSource = << >> THEN << >> ELSE message.idSource[1])
        \o (IF message.securityId = << >> THEN << >> ELSE message.securityId[1])
        \o (IF message.securityExchange = << >> THEN << >> ELSE message.securityExchange[1])
        \o (IF message.capacity = << >> THEN << >> ELSE message.capacity[1])
        \o (IF message.tradeReportRefId = << >> THEN << >> ELSE message.tradeReportRefId[1])
        \o (IF message.liquidityProvision = << >> THEN << >> ELSE message.liquidityProvision[1])
        \o (IF message.waiverType = << >> THEN << >> ELSE message.waiverType[1])
        \o (IF message.priceFormation = << >> THEN << >> ELSE message.priceFormation[1])
        \o (IF message.clientQualifiedRole = << >> THEN << >> ELSE message.clientQualifiedRole[1])
        \o (IF message.clientId = << >> THEN << >> ELSE message.clientId[1])
        \o (IF message.investorId = << >> THEN << >> ELSE message.investorId[1])
        \o (IF message.executorId = << >> THEN << >> ELSE message.executorId[1])
        \o (IF message.orderOrigination = << >> THEN << >> ELSE message.orderOrigination[1])
        \o (IF message.algorithmicIndicator = << >> THEN << >> ELSE message.algorithmicIndicator[1])
        \o (IF message.deferralReason = << >> THEN << >> ELSE message.deferralReason[1])
        \o (IF message.investorQualifiedRole = << >> THEN << >> ELSE message.investorQualifiedRole[1])
        \o (IF message.executorQualifiedRole = << >> THEN << >> ELSE message.executorQualifiedRole[1])

DecodeCancelRejectedV2Message(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET cancelRejectReason == ReadBytes(clOrdId.rest, 1) IN IF ~cancelRejectReason.ok THEN Fail ELSE
    LET text == ReadBytes(cancelRejectReason.rest, 60) IN IF ~text.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(text.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET numberOfReturnBitfields == ReadUIntBE(reserved1.rest, 1) IN IF ~numberOfReturnBitfields.ok THEN Fail ELSE
    LET cancelRejectedV2ReturnBitfield1 == ReadWhen(numberOfReturnBitfields.value >= 1, ReadUIntLE(numberOfReturnBitfields.rest, 1), numberOfReturnBitfields.rest) IN IF ~cancelRejectedV2ReturnBitfield1.ok THEN Fail ELSE
    LET cancelRejectedV2ReturnBitfield2 == ReadWhen(numberOfReturnBitfields.value >= 2, ReadUIntLE(cancelRejectedV2ReturnBitfield1.rest, 1), cancelRejectedV2ReturnBitfield1.rest) IN IF ~cancelRejectedV2ReturnBitfield2.ok THEN Fail ELSE
    LET cancelRejectedV2ReturnBitfield3 == ReadWhen(numberOfReturnBitfields.value >= 3, ReadBytes(cancelRejectedV2ReturnBitfield2.rest, 1), cancelRejectedV2ReturnBitfield2.rest) IN IF ~cancelRejectedV2ReturnBitfield3.ok THEN Fail ELSE
    LET cancelRejectedV2ReturnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadBytes(cancelRejectedV2ReturnBitfield3.rest, 1), cancelRejectedV2ReturnBitfield3.rest) IN IF ~cancelRejectedV2ReturnBitfield4.ok THEN Fail ELSE
    LET cancelRejectedV2ReturnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadBytes(cancelRejectedV2ReturnBitfield4.rest, 1), cancelRejectedV2ReturnBitfield4.rest) IN IF ~cancelRejectedV2ReturnBitfield5.ok THEN Fail ELSE
    LET cancelRejectedV2ReturnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadBytes(cancelRejectedV2ReturnBitfield5.rest, 1), cancelRejectedV2ReturnBitfield5.rest) IN IF ~cancelRejectedV2ReturnBitfield6.ok THEN Fail ELSE
    LET cancelRejectedV2ReturnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadBytes(cancelRejectedV2ReturnBitfield6.rest, 1), cancelRejectedV2ReturnBitfield6.rest) IN IF ~cancelRejectedV2ReturnBitfield7.ok THEN Fail ELSE
    LET cancelRejectedV2ReturnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadUIntLE(cancelRejectedV2ReturnBitfield7.rest, 1), cancelRejectedV2ReturnBitfield7.rest) IN IF ~cancelRejectedV2ReturnBitfield8.ok THEN Fail ELSE
    LET cancelRejectedV2ReturnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadUIntLE(cancelRejectedV2ReturnBitfield8.rest, 1), cancelRejectedV2ReturnBitfield8.rest) IN IF ~cancelRejectedV2ReturnBitfield9.ok THEN Fail ELSE
    LET cancelRejectedV2ReturnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadUIntLE(cancelRejectedV2ReturnBitfield9.rest, 1), cancelRejectedV2ReturnBitfield9.rest) IN IF ~cancelRejectedV2ReturnBitfield10.ok THEN Fail ELSE
    LET cancelRejectedV2ReturnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadUIntLE(cancelRejectedV2ReturnBitfield10.rest, 1), cancelRejectedV2ReturnBitfield10.rest) IN IF ~cancelRejectedV2ReturnBitfield11.ok THEN Fail ELSE
    LET cancelRejectedV2ReturnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadBytes(cancelRejectedV2ReturnBitfield11.rest, 1), cancelRejectedV2ReturnBitfield11.rest) IN IF ~cancelRejectedV2ReturnBitfield12.ok THEN Fail ELSE
    LET cancelRejectedV2ReturnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(cancelRejectedV2ReturnBitfield12.rest, 1), cancelRejectedV2ReturnBitfield12.rest) IN IF ~cancelRejectedV2ReturnBitfield13.ok THEN Fail ELSE
    LET cancelRejectedV2ReturnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(cancelRejectedV2ReturnBitfield13.rest, 1), cancelRejectedV2ReturnBitfield13.rest) IN IF ~cancelRejectedV2ReturnBitfield14.ok THEN Fail ELSE
    LET side == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (cancelRejectedV2ReturnBitfield1.value # << >> /\ cancelRejectedV2ReturnBitfield1.value[1] % 2 > 0), ReadBytes(cancelRejectedV2ReturnBitfield14.rest, 1), cancelRejectedV2ReturnBitfield14.rest) IN IF ~side.ok THEN Fail ELSE
    LET pegDifference == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (cancelRejectedV2ReturnBitfield1.value # << >> /\ (cancelRejectedV2ReturnBitfield1.value[1] \div 2) % 2 > 0), ReadBytes(side.rest, 8), side.rest) IN IF ~pegDifference.ok THEN Fail ELSE
    LET price == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (cancelRejectedV2ReturnBitfield1.value # << >> /\ (cancelRejectedV2ReturnBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(pegDifference.rest, 8), pegDifference.rest) IN IF ~price.ok THEN Fail ELSE
    LET execInst == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (cancelRejectedV2ReturnBitfield1.value # << >> /\ (cancelRejectedV2ReturnBitfield1.value[1] \div 8) % 2 > 0), ReadBytes(price.rest, 1), price.rest) IN IF ~execInst.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (cancelRejectedV2ReturnBitfield1.value # << >> /\ (cancelRejectedV2ReturnBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(execInst.rest, 1), execInst.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (cancelRejectedV2ReturnBitfield1.value # << >> /\ (cancelRejectedV2ReturnBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (cancelRejectedV2ReturnBitfield1.value # << >> /\ (cancelRejectedV2ReturnBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET symbol == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (cancelRejectedV2ReturnBitfield2.value # << >> /\ cancelRejectedV2ReturnBitfield2.value[1] % 2 > 0), ReadBytes(minQty.rest, 8), minQty.rest) IN IF ~symbol.ok THEN Fail ELSE
    LET currency == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (cancelRejectedV2ReturnBitfield2.value # << >> /\ (cancelRejectedV2ReturnBitfield2.value[1] \div 4) % 2 > 0), ReadBytes(symbol.rest, 3), symbol.rest) IN IF ~currency.ok THEN Fail ELSE
    LET idSource == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (cancelRejectedV2ReturnBitfield2.value # << >> /\ (cancelRejectedV2ReturnBitfield2.value[1] \div 8) % 2 > 0), ReadBytes(currency.rest, 1), currency.rest) IN IF ~idSource.ok THEN Fail ELSE
    LET securityId == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (cancelRejectedV2ReturnBitfield2.value # << >> /\ (cancelRejectedV2ReturnBitfield2.value[1] \div 16) % 2 > 0), ReadBytes(idSource.rest, 16), idSource.rest) IN IF ~securityId.ok THEN Fail ELSE
    LET securityExchange == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (cancelRejectedV2ReturnBitfield2.value # << >> /\ (cancelRejectedV2ReturnBitfield2.value[1] \div 32) % 2 > 0), ReadBytes(securityId.rest, 4), securityId.rest) IN IF ~securityExchange.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (cancelRejectedV2ReturnBitfield2.value # << >> /\ (cancelRejectedV2ReturnBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(securityExchange.rest, 1), securityExchange.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET tradeReportRefId == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (cancelRejectedV2ReturnBitfield8.value # << >> /\ (cancelRejectedV2ReturnBitfield8.value[1] \div 128) % 2 > 0), ReadBytes(capacity.rest, 20), capacity.rest) IN IF ~tradeReportRefId.ok THEN Fail ELSE
    LET liquidityProvision == ReadWhen(numberOfReturnBitfields.value >= 9 /\ (cancelRejectedV2ReturnBitfield9.value # << >> /\ (cancelRejectedV2ReturnBitfield9.value[1] \div 16) % 2 > 0), ReadBytes(tradeReportRefId.rest, 1), tradeReportRefId.rest) IN IF ~liquidityProvision.ok THEN Fail ELSE
    LET waiverType == ReadWhen(numberOfReturnBitfields.value >= 10 /\ (cancelRejectedV2ReturnBitfield10.value # << >> /\ (cancelRejectedV2ReturnBitfield10.value[1] \div 16) % 2 > 0), ReadBytes(liquidityProvision.rest, 1), liquidityProvision.rest) IN IF ~waiverType.ok THEN Fail ELSE
    LET priceFormation == ReadWhen(numberOfReturnBitfields.value >= 10 /\ (cancelRejectedV2ReturnBitfield10.value # << >> /\ (cancelRejectedV2ReturnBitfield10.value[1] \div 64) % 2 > 0), ReadBytes(waiverType.rest, 1), waiverType.rest) IN IF ~priceFormation.ok THEN Fail ELSE
    LET clientQualifiedRole == ReadWhen(numberOfReturnBitfields.value >= 10 /\ (cancelRejectedV2ReturnBitfield10.value # << >> /\ (cancelRejectedV2ReturnBitfield10.value[1] \div 128) % 2 > 0), ReadBytes(priceFormation.rest, 1), priceFormation.rest) IN IF ~clientQualifiedRole.ok THEN Fail ELSE
    LET clientId == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (cancelRejectedV2ReturnBitfield11.value # << >> /\ cancelRejectedV2ReturnBitfield11.value[1] % 2 > 0), ReadBytes(clientQualifiedRole.rest, 4), clientQualifiedRole.rest) IN IF ~clientId.ok THEN Fail ELSE
    LET investorId == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (cancelRejectedV2ReturnBitfield11.value # << >> /\ (cancelRejectedV2ReturnBitfield11.value[1] \div 2) % 2 > 0), ReadBytes(clientId.rest, 4), clientId.rest) IN IF ~investorId.ok THEN Fail ELSE
    LET executorId == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (cancelRejectedV2ReturnBitfield11.value # << >> /\ (cancelRejectedV2ReturnBitfield11.value[1] \div 4) % 2 > 0), ReadBytes(investorId.rest, 4), investorId.rest) IN IF ~executorId.ok THEN Fail ELSE
    LET orderOrigination == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (cancelRejectedV2ReturnBitfield11.value # << >> /\ (cancelRejectedV2ReturnBitfield11.value[1] \div 8) % 2 > 0), ReadBytes(executorId.rest, 1), executorId.rest) IN IF ~orderOrigination.ok THEN Fail ELSE
    LET algorithmicIndicator == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (cancelRejectedV2ReturnBitfield11.value # << >> /\ (cancelRejectedV2ReturnBitfield11.value[1] \div 16) % 2 > 0), ReadBytes(orderOrigination.rest, 1), orderOrigination.rest) IN IF ~algorithmicIndicator.ok THEN Fail ELSE
    LET deferralReason == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (cancelRejectedV2ReturnBitfield11.value # << >> /\ (cancelRejectedV2ReturnBitfield11.value[1] \div 32) % 2 > 0), ReadBytes(algorithmicIndicator.rest, 1), algorithmicIndicator.rest) IN IF ~deferralReason.ok THEN Fail ELSE
    LET investorQualifiedRole == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (cancelRejectedV2ReturnBitfield11.value # << >> /\ (cancelRejectedV2ReturnBitfield11.value[1] \div 64) % 2 > 0), ReadBytes(deferralReason.rest, 1), deferralReason.rest) IN IF ~investorQualifiedRole.ok THEN Fail ELSE
    LET executorQualifiedRole == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (cancelRejectedV2ReturnBitfield11.value # << >> /\ (cancelRejectedV2ReturnBitfield11.value[1] \div 128) % 2 > 0), ReadBytes(investorQualifiedRole.rest, 1), investorQualifiedRole.rest) IN IF ~executorQualifiedRole.ok THEN Fail ELSE
    Ok([ transactionTime                  |-> transactionTime.value,
         clOrdId                          |-> clOrdId.value,
         cancelRejectReason               |-> cancelRejectReason.value,
         text                             |-> text.value,
         reserved1                        |-> reserved1.value,
         numberOfReturnBitfields          |-> numberOfReturnBitfields.value,
         cancelRejectedV2ReturnBitfield1  |-> cancelRejectedV2ReturnBitfield1.value,
         cancelRejectedV2ReturnBitfield2  |-> cancelRejectedV2ReturnBitfield2.value,
         cancelRejectedV2ReturnBitfield3  |-> cancelRejectedV2ReturnBitfield3.value,
         cancelRejectedV2ReturnBitfield4  |-> cancelRejectedV2ReturnBitfield4.value,
         cancelRejectedV2ReturnBitfield5  |-> cancelRejectedV2ReturnBitfield5.value,
         cancelRejectedV2ReturnBitfield6  |-> cancelRejectedV2ReturnBitfield6.value,
         cancelRejectedV2ReturnBitfield7  |-> cancelRejectedV2ReturnBitfield7.value,
         cancelRejectedV2ReturnBitfield8  |-> cancelRejectedV2ReturnBitfield8.value,
         cancelRejectedV2ReturnBitfield9  |-> cancelRejectedV2ReturnBitfield9.value,
         cancelRejectedV2ReturnBitfield10 |-> cancelRejectedV2ReturnBitfield10.value,
         cancelRejectedV2ReturnBitfield11 |-> cancelRejectedV2ReturnBitfield11.value,
         cancelRejectedV2ReturnBitfield12 |-> cancelRejectedV2ReturnBitfield12.value,
         cancelRejectedV2ReturnBitfield13 |-> cancelRejectedV2ReturnBitfield13.value,
         cancelRejectedV2ReturnBitfield14 |-> cancelRejectedV2ReturnBitfield14.value,
         side                             |-> side.value,
         pegDifference                    |-> pegDifference.value,
         price                            |-> price.value,
         execInst                         |-> execInst.value,
         ordType                          |-> ordType.value,
         timeInForce                      |-> timeInForce.value,
         minQty                           |-> minQty.value,
         symbol                           |-> symbol.value,
         currency                         |-> currency.value,
         idSource                         |-> idSource.value,
         securityId                       |-> securityId.value,
         securityExchange                 |-> securityExchange.value,
         capacity                         |-> capacity.value,
         tradeReportRefId                 |-> tradeReportRefId.value,
         liquidityProvision               |-> liquidityProvision.value,
         waiverType                       |-> waiverType.value,
         priceFormation                   |-> priceFormation.value,
         clientQualifiedRole              |-> clientQualifiedRole.value,
         clientId                         |-> clientId.value,
         investorId                       |-> investorId.value,
         executorId                       |-> executorId.value,
         orderOrigination                 |-> orderOrigination.value,
         algorithmicIndicator             |-> algorithmicIndicator.value,
         deferralReason                   |-> deferralReason.value,
         investorQualifiedRole            |-> investorQualifiedRole.value,
         executorQualifiedRole            |-> executorQualifiedRole.value ], executorQualifiedRole.rest)

(* Cancel Rejected V 2 Message with each field marked present by fields before it there exactly where they say *)
SettleCancelRejectedV2Message(message) ==
    LET settled1 == [message EXCEPT !.cancelRejectedV2ReturnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.cancelRejectedV2ReturnBitfield1 = << >> THEN <<0>> ELSE message.cancelRejectedV2ReturnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.cancelRejectedV2ReturnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.cancelRejectedV2ReturnBitfield2 = << >> THEN <<0>> ELSE settled1.cancelRejectedV2ReturnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.cancelRejectedV2ReturnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.cancelRejectedV2ReturnBitfield3 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled2.cancelRejectedV2ReturnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.cancelRejectedV2ReturnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.cancelRejectedV2ReturnBitfield4 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled3.cancelRejectedV2ReturnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.cancelRejectedV2ReturnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.cancelRejectedV2ReturnBitfield5 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled4.cancelRejectedV2ReturnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.cancelRejectedV2ReturnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.cancelRejectedV2ReturnBitfield6 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled5.cancelRejectedV2ReturnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.cancelRejectedV2ReturnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.cancelRejectedV2ReturnBitfield7 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.cancelRejectedV2ReturnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.cancelRejectedV2ReturnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.cancelRejectedV2ReturnBitfield8 = << >> THEN <<0>> ELSE settled7.cancelRejectedV2ReturnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.cancelRejectedV2ReturnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.cancelRejectedV2ReturnBitfield9 = << >> THEN <<0>> ELSE settled8.cancelRejectedV2ReturnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.cancelRejectedV2ReturnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.cancelRejectedV2ReturnBitfield10 = << >> THEN <<0>> ELSE settled9.cancelRejectedV2ReturnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.cancelRejectedV2ReturnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.cancelRejectedV2ReturnBitfield11 = << >> THEN <<0>> ELSE settled10.cancelRejectedV2ReturnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.cancelRejectedV2ReturnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.cancelRejectedV2ReturnBitfield12 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.cancelRejectedV2ReturnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.cancelRejectedV2ReturnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.cancelRejectedV2ReturnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.cancelRejectedV2ReturnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.cancelRejectedV2ReturnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.cancelRejectedV2ReturnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.cancelRejectedV2ReturnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.side = IF settled14.numberOfReturnBitfields >= 1 /\ (settled14.cancelRejectedV2ReturnBitfield1 # << >> /\ settled14.cancelRejectedV2ReturnBitfield1[1] % 2 > 0) THEN (IF settled14.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.side) ELSE << >>]
        settled16 == [settled15 EXCEPT !.pegDifference = IF settled15.numberOfReturnBitfields >= 1 /\ (settled15.cancelRejectedV2ReturnBitfield1 # << >> /\ (settled15.cancelRejectedV2ReturnBitfield1[1] \div 2) % 2 > 0) THEN (IF settled15.pegDifference = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled15.pegDifference) ELSE << >>]
        settled17 == [settled16 EXCEPT !.price = IF settled16.numberOfReturnBitfields >= 1 /\ (settled16.cancelRejectedV2ReturnBitfield1 # << >> /\ (settled16.cancelRejectedV2ReturnBitfield1[1] \div 4) % 2 > 0) THEN (IF settled16.price = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled16.price) ELSE << >>]
        settled18 == [settled17 EXCEPT !.execInst = IF settled17.numberOfReturnBitfields >= 1 /\ (settled17.cancelRejectedV2ReturnBitfield1 # << >> /\ (settled17.cancelRejectedV2ReturnBitfield1[1] \div 8) % 2 > 0) THEN (IF settled17.execInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.execInst) ELSE << >>]
        settled19 == [settled18 EXCEPT !.ordType = IF settled18.numberOfReturnBitfields >= 1 /\ (settled18.cancelRejectedV2ReturnBitfield1 # << >> /\ (settled18.cancelRejectedV2ReturnBitfield1[1] \div 16) % 2 > 0) THEN (IF settled18.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled18.ordType) ELSE << >>]
        settled20 == [settled19 EXCEPT !.timeInForce = IF settled19.numberOfReturnBitfields >= 1 /\ (settled19.cancelRejectedV2ReturnBitfield1 # << >> /\ (settled19.cancelRejectedV2ReturnBitfield1[1] \div 32) % 2 > 0) THEN (IF settled19.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled19.timeInForce) ELSE << >>]
        settled21 == [settled20 EXCEPT !.minQty = IF settled20.numberOfReturnBitfields >= 1 /\ (settled20.cancelRejectedV2ReturnBitfield1 # << >> /\ (settled20.cancelRejectedV2ReturnBitfield1[1] \div 64) % 2 > 0) THEN (IF settled20.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled20.minQty) ELSE << >>]
        settled22 == [settled21 EXCEPT !.symbol = IF settled21.numberOfReturnBitfields >= 2 /\ (settled21.cancelRejectedV2ReturnBitfield2 # << >> /\ settled21.cancelRejectedV2ReturnBitfield2[1] % 2 > 0) THEN (IF settled21.symbol = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled21.symbol) ELSE << >>]
        settled23 == [settled22 EXCEPT !.currency = IF settled22.numberOfReturnBitfields >= 2 /\ (settled22.cancelRejectedV2ReturnBitfield2 # << >> /\ (settled22.cancelRejectedV2ReturnBitfield2[1] \div 4) % 2 > 0) THEN (IF settled22.currency = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled22.currency) ELSE << >>]
        settled24 == [settled23 EXCEPT !.idSource = IF settled23.numberOfReturnBitfields >= 2 /\ (settled23.cancelRejectedV2ReturnBitfield2 # << >> /\ (settled23.cancelRejectedV2ReturnBitfield2[1] \div 8) % 2 > 0) THEN (IF settled23.idSource = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled23.idSource) ELSE << >>]
        settled25 == [settled24 EXCEPT !.securityId = IF settled24.numberOfReturnBitfields >= 2 /\ (settled24.cancelRejectedV2ReturnBitfield2 # << >> /\ (settled24.cancelRejectedV2ReturnBitfield2[1] \div 16) % 2 > 0) THEN (IF settled24.securityId = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled24.securityId) ELSE << >>]
        settled26 == [settled25 EXCEPT !.securityExchange = IF settled25.numberOfReturnBitfields >= 2 /\ (settled25.cancelRejectedV2ReturnBitfield2 # << >> /\ (settled25.cancelRejectedV2ReturnBitfield2[1] \div 32) % 2 > 0) THEN (IF settled25.securityExchange = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled25.securityExchange) ELSE << >>]
        settled27 == [settled26 EXCEPT !.capacity = IF settled26.numberOfReturnBitfields >= 2 /\ (settled26.cancelRejectedV2ReturnBitfield2 # << >> /\ (settled26.cancelRejectedV2ReturnBitfield2[1] \div 64) % 2 > 0) THEN (IF settled26.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled26.capacity) ELSE << >>]
        settled28 == [settled27 EXCEPT !.tradeReportRefId = IF settled27.numberOfReturnBitfields >= 8 /\ (settled27.cancelRejectedV2ReturnBitfield8 # << >> /\ (settled27.cancelRejectedV2ReturnBitfield8[1] \div 128) % 2 > 0) THEN (IF settled27.tradeReportRefId = << >> THEN <<[i \in 1 .. 20 |-> 0]>> ELSE settled27.tradeReportRefId) ELSE << >>]
        settled29 == [settled28 EXCEPT !.liquidityProvision = IF settled28.numberOfReturnBitfields >= 9 /\ (settled28.cancelRejectedV2ReturnBitfield9 # << >> /\ (settled28.cancelRejectedV2ReturnBitfield9[1] \div 16) % 2 > 0) THEN (IF settled28.liquidityProvision = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled28.liquidityProvision) ELSE << >>]
        settled30 == [settled29 EXCEPT !.waiverType = IF settled29.numberOfReturnBitfields >= 10 /\ (settled29.cancelRejectedV2ReturnBitfield10 # << >> /\ (settled29.cancelRejectedV2ReturnBitfield10[1] \div 16) % 2 > 0) THEN (IF settled29.waiverType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled29.waiverType) ELSE << >>]
        settled31 == [settled30 EXCEPT !.priceFormation = IF settled30.numberOfReturnBitfields >= 10 /\ (settled30.cancelRejectedV2ReturnBitfield10 # << >> /\ (settled30.cancelRejectedV2ReturnBitfield10[1] \div 64) % 2 > 0) THEN (IF settled30.priceFormation = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled30.priceFormation) ELSE << >>]
        settled32 == [settled31 EXCEPT !.clientQualifiedRole = IF settled31.numberOfReturnBitfields >= 10 /\ (settled31.cancelRejectedV2ReturnBitfield10 # << >> /\ (settled31.cancelRejectedV2ReturnBitfield10[1] \div 128) % 2 > 0) THEN (IF settled31.clientQualifiedRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled31.clientQualifiedRole) ELSE << >>]
        settled33 == [settled32 EXCEPT !.clientId = IF settled32.numberOfReturnBitfields >= 11 /\ (settled32.cancelRejectedV2ReturnBitfield11 # << >> /\ settled32.cancelRejectedV2ReturnBitfield11[1] % 2 > 0) THEN (IF settled32.clientId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled32.clientId) ELSE << >>]
        settled34 == [settled33 EXCEPT !.investorId = IF settled33.numberOfReturnBitfields >= 11 /\ (settled33.cancelRejectedV2ReturnBitfield11 # << >> /\ (settled33.cancelRejectedV2ReturnBitfield11[1] \div 2) % 2 > 0) THEN (IF settled33.investorId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled33.investorId) ELSE << >>]
        settled35 == [settled34 EXCEPT !.executorId = IF settled34.numberOfReturnBitfields >= 11 /\ (settled34.cancelRejectedV2ReturnBitfield11 # << >> /\ (settled34.cancelRejectedV2ReturnBitfield11[1] \div 4) % 2 > 0) THEN (IF settled34.executorId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled34.executorId) ELSE << >>]
        settled36 == [settled35 EXCEPT !.orderOrigination = IF settled35.numberOfReturnBitfields >= 11 /\ (settled35.cancelRejectedV2ReturnBitfield11 # << >> /\ (settled35.cancelRejectedV2ReturnBitfield11[1] \div 8) % 2 > 0) THEN (IF settled35.orderOrigination = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled35.orderOrigination) ELSE << >>]
        settled37 == [settled36 EXCEPT !.algorithmicIndicator = IF settled36.numberOfReturnBitfields >= 11 /\ (settled36.cancelRejectedV2ReturnBitfield11 # << >> /\ (settled36.cancelRejectedV2ReturnBitfield11[1] \div 16) % 2 > 0) THEN (IF settled36.algorithmicIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled36.algorithmicIndicator) ELSE << >>]
        settled38 == [settled37 EXCEPT !.deferralReason = IF settled37.numberOfReturnBitfields >= 11 /\ (settled37.cancelRejectedV2ReturnBitfield11 # << >> /\ (settled37.cancelRejectedV2ReturnBitfield11[1] \div 32) % 2 > 0) THEN (IF settled37.deferralReason = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled37.deferralReason) ELSE << >>]
        settled39 == [settled38 EXCEPT !.investorQualifiedRole = IF settled38.numberOfReturnBitfields >= 11 /\ (settled38.cancelRejectedV2ReturnBitfield11 # << >> /\ (settled38.cancelRejectedV2ReturnBitfield11[1] \div 64) % 2 > 0) THEN (IF settled38.investorQualifiedRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled38.investorQualifiedRole) ELSE << >>]
        settled40 == [settled39 EXCEPT !.executorQualifiedRole = IF settled39.numberOfReturnBitfields >= 11 /\ (settled39.cancelRejectedV2ReturnBitfield11 # << >> /\ (settled39.cancelRejectedV2ReturnBitfield11[1] \div 128) % 2 > 0) THEN (IF settled39.executorQualifiedRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled39.executorQualifiedRole) ELSE << >>]
    IN  settled40

ZeroCancelRejectedV2Message ==
    SettleCancelRejectedV2Message([ transactionTime                  |-> [i \in 1 .. 8 |-> 0],
                                    clOrdId                          |-> [i \in 1 .. 20 |-> 0],
                                    cancelRejectReason               |-> [i \in 1 .. 1 |-> 0],
                                    text                             |-> [i \in 1 .. 60 |-> 0],
                                    reserved1                        |-> [i \in 1 .. 1 |-> 0],
                                    numberOfReturnBitfields          |-> 0,
                                    cancelRejectedV2ReturnBitfield1  |-> << >>,
                                    cancelRejectedV2ReturnBitfield2  |-> << >>,
                                    cancelRejectedV2ReturnBitfield3  |-> << >>,
                                    cancelRejectedV2ReturnBitfield4  |-> << >>,
                                    cancelRejectedV2ReturnBitfield5  |-> << >>,
                                    cancelRejectedV2ReturnBitfield6  |-> << >>,
                                    cancelRejectedV2ReturnBitfield7  |-> << >>,
                                    cancelRejectedV2ReturnBitfield8  |-> << >>,
                                    cancelRejectedV2ReturnBitfield9  |-> << >>,
                                    cancelRejectedV2ReturnBitfield10 |-> << >>,
                                    cancelRejectedV2ReturnBitfield11 |-> << >>,
                                    cancelRejectedV2ReturnBitfield12 |-> << >>,
                                    cancelRejectedV2ReturnBitfield13 |-> << >>,
                                    cancelRejectedV2ReturnBitfield14 |-> << >>,
                                    side                             |-> << >>,
                                    pegDifference                    |-> << >>,
                                    price                            |-> << >>,
                                    execInst                         |-> << >>,
                                    ordType                          |-> << >>,
                                    timeInForce                      |-> << >>,
                                    minQty                           |-> << >>,
                                    symbol                           |-> << >>,
                                    currency                         |-> << >>,
                                    idSource                         |-> << >>,
                                    securityId                       |-> << >>,
                                    securityExchange                 |-> << >>,
                                    capacity                         |-> << >>,
                                    tradeReportRefId                 |-> << >>,
                                    liquidityProvision               |-> << >>,
                                    waiverType                       |-> << >>,
                                    priceFormation                   |-> << >>,
                                    clientQualifiedRole              |-> << >>,
                                    clientId                         |-> << >>,
                                    investorId                       |-> << >>,
                                    executorId                       |-> << >>,
                                    orderOrigination                 |-> << >>,
                                    algorithmicIndicator             |-> << >>,
                                    deferralReason                   |-> << >>,
                                    investorQualifiedRole            |-> << >>,
                                    executorQualifiedRole            |-> << >> ])

(* Cancel Rejected V 2 Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelRejectedV2Message ==
    { ZeroCancelRejectedV2Message }
        \cup { SettleCancelRejectedV2Message([ZeroCancelRejectedV2Message EXCEPT !.transactionTime = one]) : one \in Sample(8) }
        \cup { SettleCancelRejectedV2Message([ZeroCancelRejectedV2Message EXCEPT !.clOrdId = one]) : one \in Sample(20) }
        \cup { SettleCancelRejectedV2Message([ZeroCancelRejectedV2Message EXCEPT !.cancelRejectReason = one]) : one \in Sample(1) }
        \cup { SettleCancelRejectedV2Message([ZeroCancelRejectedV2Message EXCEPT !.text = one]) : one \in Sample(60) }
        \cup { SettleCancelRejectedV2Message([ZeroCancelRejectedV2Message EXCEPT !.reserved1 = one]) : one \in Sample(1) }
        \cup { SettleCancelRejectedV2Message([ZeroCancelRejectedV2Message EXCEPT !.numberOfReturnBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleCancelRejectedV2Message([ZeroCancelRejectedV2Message EXCEPT !.numberOfReturnBitfields = 1, !.cancelRejectedV2ReturnBitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleCancelRejectedV2Message([ZeroCancelRejectedV2Message EXCEPT !.numberOfReturnBitfields = 2, !.cancelRejectedV2ReturnBitfield2 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleCancelRejectedV2Message([ZeroCancelRejectedV2Message EXCEPT !.numberOfReturnBitfields = 3, !.cancelRejectedV2ReturnBitfield3 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedV2Message([ZeroCancelRejectedV2Message EXCEPT !.numberOfReturnBitfields = 4, !.cancelRejectedV2ReturnBitfield4 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedV2Message([ZeroCancelRejectedV2Message EXCEPT !.numberOfReturnBitfields = 5, !.cancelRejectedV2ReturnBitfield5 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedV2Message([ZeroCancelRejectedV2Message EXCEPT !.numberOfReturnBitfields = 6, !.cancelRejectedV2ReturnBitfield6 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedV2Message([ZeroCancelRejectedV2Message EXCEPT !.numberOfReturnBitfields = 7, !.cancelRejectedV2ReturnBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedV2Message([ZeroCancelRejectedV2Message EXCEPT !.numberOfReturnBitfields = 8, !.cancelRejectedV2ReturnBitfield8 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleCancelRejectedV2Message([ZeroCancelRejectedV2Message EXCEPT !.numberOfReturnBitfields = 9, !.cancelRejectedV2ReturnBitfield9 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleCancelRejectedV2Message([ZeroCancelRejectedV2Message EXCEPT !.numberOfReturnBitfields = 10, !.cancelRejectedV2ReturnBitfield10 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleCancelRejectedV2Message([ZeroCancelRejectedV2Message EXCEPT !.numberOfReturnBitfields = 11, !.cancelRejectedV2ReturnBitfield11 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleCancelRejectedV2Message([ZeroCancelRejectedV2Message EXCEPT !.numberOfReturnBitfields = 12, !.cancelRejectedV2ReturnBitfield12 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedV2Message([ZeroCancelRejectedV2Message EXCEPT !.numberOfReturnBitfields = 13, !.cancelRejectedV2ReturnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedV2Message([ZeroCancelRejectedV2Message EXCEPT !.numberOfReturnBitfields = 14, !.cancelRejectedV2ReturnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedV2Message([ZeroCancelRejectedV2Message EXCEPT !.numberOfReturnBitfields = 1, !.cancelRejectedV2ReturnBitfield1 = <<1>>, !.side = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedV2Message([ZeroCancelRejectedV2Message EXCEPT !.numberOfReturnBitfields = 1, !.cancelRejectedV2ReturnBitfield1 = <<2>>, !.pegDifference = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleCancelRejectedV2Message([ZeroCancelRejectedV2Message EXCEPT !.numberOfReturnBitfields = 1, !.cancelRejectedV2ReturnBitfield1 = <<4>>, !.price = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleCancelRejectedV2Message([ZeroCancelRejectedV2Message EXCEPT !.numberOfReturnBitfields = 1, !.cancelRejectedV2ReturnBitfield1 = <<8>>, !.execInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedV2Message([ZeroCancelRejectedV2Message EXCEPT !.numberOfReturnBitfields = 1, !.cancelRejectedV2ReturnBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedV2Message([ZeroCancelRejectedV2Message EXCEPT !.numberOfReturnBitfields = 1, !.cancelRejectedV2ReturnBitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedV2Message([ZeroCancelRejectedV2Message EXCEPT !.numberOfReturnBitfields = 1, !.cancelRejectedV2ReturnBitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleCancelRejectedV2Message([ZeroCancelRejectedV2Message EXCEPT !.numberOfReturnBitfields = 2, !.cancelRejectedV2ReturnBitfield2 = <<1>>, !.symbol = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleCancelRejectedV2Message([ZeroCancelRejectedV2Message EXCEPT !.numberOfReturnBitfields = 2, !.cancelRejectedV2ReturnBitfield2 = <<4>>, !.currency = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleCancelRejectedV2Message([ZeroCancelRejectedV2Message EXCEPT !.numberOfReturnBitfields = 2, !.cancelRejectedV2ReturnBitfield2 = <<8>>, !.idSource = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedV2Message([ZeroCancelRejectedV2Message EXCEPT !.numberOfReturnBitfields = 2, !.cancelRejectedV2ReturnBitfield2 = <<16>>, !.securityId = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleCancelRejectedV2Message([ZeroCancelRejectedV2Message EXCEPT !.numberOfReturnBitfields = 2, !.cancelRejectedV2ReturnBitfield2 = <<32>>, !.securityExchange = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleCancelRejectedV2Message([ZeroCancelRejectedV2Message EXCEPT !.numberOfReturnBitfields = 2, !.cancelRejectedV2ReturnBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedV2Message([ZeroCancelRejectedV2Message EXCEPT !.numberOfReturnBitfields = 8, !.cancelRejectedV2ReturnBitfield8 = <<128>>, !.tradeReportRefId = one]) : one \in { <<held>> : held \in Sample(20) } }
        \cup { SettleCancelRejectedV2Message([ZeroCancelRejectedV2Message EXCEPT !.numberOfReturnBitfields = 9, !.cancelRejectedV2ReturnBitfield9 = <<16>>, !.liquidityProvision = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedV2Message([ZeroCancelRejectedV2Message EXCEPT !.numberOfReturnBitfields = 10, !.cancelRejectedV2ReturnBitfield10 = <<16>>, !.waiverType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedV2Message([ZeroCancelRejectedV2Message EXCEPT !.numberOfReturnBitfields = 10, !.cancelRejectedV2ReturnBitfield10 = <<64>>, !.priceFormation = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedV2Message([ZeroCancelRejectedV2Message EXCEPT !.numberOfReturnBitfields = 10, !.cancelRejectedV2ReturnBitfield10 = <<128>>, !.clientQualifiedRole = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedV2Message([ZeroCancelRejectedV2Message EXCEPT !.numberOfReturnBitfields = 11, !.cancelRejectedV2ReturnBitfield11 = <<1>>, !.clientId = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleCancelRejectedV2Message([ZeroCancelRejectedV2Message EXCEPT !.numberOfReturnBitfields = 11, !.cancelRejectedV2ReturnBitfield11 = <<2>>, !.investorId = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleCancelRejectedV2Message([ZeroCancelRejectedV2Message EXCEPT !.numberOfReturnBitfields = 11, !.cancelRejectedV2ReturnBitfield11 = <<4>>, !.executorId = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleCancelRejectedV2Message([ZeroCancelRejectedV2Message EXCEPT !.numberOfReturnBitfields = 11, !.cancelRejectedV2ReturnBitfield11 = <<8>>, !.orderOrigination = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedV2Message([ZeroCancelRejectedV2Message EXCEPT !.numberOfReturnBitfields = 11, !.cancelRejectedV2ReturnBitfield11 = <<16>>, !.algorithmicIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedV2Message([ZeroCancelRejectedV2Message EXCEPT !.numberOfReturnBitfields = 11, !.cancelRejectedV2ReturnBitfield11 = <<32>>, !.deferralReason = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedV2Message([ZeroCancelRejectedV2Message EXCEPT !.numberOfReturnBitfields = 11, !.cancelRejectedV2ReturnBitfield11 = <<64>>, !.investorQualifiedRole = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedV2Message([ZeroCancelRejectedV2Message EXCEPT !.numberOfReturnBitfields = 11, !.cancelRejectedV2ReturnBitfield11 = <<128>>, !.executorQualifiedRole = one]) : one \in { <<held>> : held \in Sample(1) } }

(***************************************************************************)
(* Order Execution V 2 Message                                             *)
(***************************************************************************)

OrderExecutionV2Message ==
    [ transactionTime                  : Sample(8),
      clOrdId                          : Sample(20),
      execId                           : Sample(8),
      lastShares                       : Sample(4),
      lastPx                           : Sample(8),
      leavesQty                        : Sample(4),
      baseLiquidityIndicator           : Sample(1),
      subLiquidityIndicator            : Sample(1),
      contraBroker                     : Sample(4),
      reserved1                        : Sample(1),
      numberOfReturnBitfields          : 0 .. 255,
      orderExecutionV2ReturnBitfield1  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderExecutionV2ReturnBitfield2  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderExecutionV2ReturnBitfield3  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderExecutionV2ReturnBitfield4  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderExecutionV2ReturnBitfield5  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderExecutionV2ReturnBitfield6  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderExecutionV2ReturnBitfield7  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderExecutionV2ReturnBitfield8  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderExecutionV2ReturnBitfield9  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderExecutionV2ReturnBitfield10 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderExecutionV2ReturnBitfield11 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderExecutionV2ReturnBitfield12 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderExecutionV2ReturnBitfield13 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderExecutionV2ReturnBitfield14 : { << >> } \cup { <<held>> : held \in Sample(1) },
      side                             : { << >> } \cup { <<held>> : held \in Sample(1) },
      pegDifference                    : { << >> } \cup { <<held>> : held \in Sample(8) },
      price                            : { << >> } \cup { <<held>> : held \in Sample(8) },
      execInst                         : { << >> } \cup { <<held>> : held \in Sample(1) },
      ordType                          : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce                      : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                           : { << >> } \cup { <<held>> : held \in Sample(4) },
      symbol                           : { << >> } \cup { <<held>> : held \in Sample(8) },
      currency                         : { << >> } \cup { <<held>> : held \in Sample(3) },
      idSource                         : { << >> } \cup { <<held>> : held \in Sample(1) },
      securityId                       : { << >> } \cup { <<held>> : held \in Sample(16) },
      securityExchange                 : { << >> } \cup { <<held>> : held \in Sample(4) },
      capacity                         : { << >> } \cup { <<held>> : held \in Sample(1) },
      account                          : { << >> } \cup { <<held>> : held \in Sample(16) },
      clearingFirm                     : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingAccount                  : { << >> } \cup { <<held>> : held \in Sample(4) },
      displayIndicator                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      maxFloor                         : { << >> } \cup { <<held>> : held \in Sample(4) },
      orderQty                         : { << >> } \cup { <<held>> : held \in Sample(4) },
      preventParticipantMatch          : { << >> } \cup { <<held>> : held \in Sample(3) },
      secondaryOrderId                 : { << >> } \cup { <<held>> : held \in Sample(8) },
      centralCounterparty              : { << >> } \cup { <<held>> : held \in Sample(1) },
      lastMkt                          : { << >> } \cup { <<held>> : held \in Sample(4) },
      feeCode                          : { << >> } \cup { <<held>> : held \in Sample(2) },
      echoText                         : { << >> } \cup { <<held>> : held \in Sample(64) },
      routingInst                      : { << >> } \cup { <<held>> : held \in Sample(4) },
      routStrategy                     : { << >> } \cup { <<held>> : held \in Sample(6) },
      routeDeliveryMethod              : { << >> } \cup { <<held>> : held \in Sample(3) },
      exDestination                    : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeReportRefId                 : { << >> } \cup { <<held>> : held \in Sample(20) },
      liquidityProvision               : { << >> } \cup { <<held>> : held \in Sample(1) },
      waiverType                       : { << >> } \cup { <<held>> : held \in Sample(1) },
      priceFormation                   : { << >> } \cup { <<held>> : held \in Sample(1) },
      clientQualifiedRole              : { << >> } \cup { <<held>> : held \in Sample(1) },
      clientId                         : { << >> } \cup { <<held>> : held \in Sample(4) },
      investorId                       : { << >> } \cup { <<held>> : held \in Sample(4) },
      executorId                       : { << >> } \cup { <<held>> : held \in Sample(4) },
      orderOrigination                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      algorithmicIndicator             : { << >> } \cup { <<held>> : held \in Sample(1) },
      investorQualifiedRole            : { << >> } \cup { <<held>> : held \in Sample(1) },
      executorQualifiedRole            : { << >> } \cup { <<held>> : held \in Sample(1) } ]

EncodeOrderExecutionV2Message(message) ==
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
        \o (IF message.orderExecutionV2ReturnBitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.orderExecutionV2ReturnBitfield1[1], 1))
        \o (IF message.orderExecutionV2ReturnBitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.orderExecutionV2ReturnBitfield2[1], 1))
        \o (IF message.orderExecutionV2ReturnBitfield3 = << >> THEN << >> ELSE EncodeUIntLE(message.orderExecutionV2ReturnBitfield3[1], 1))
        \o (IF message.orderExecutionV2ReturnBitfield4 = << >> THEN << >> ELSE message.orderExecutionV2ReturnBitfield4[1])
        \o (IF message.orderExecutionV2ReturnBitfield5 = << >> THEN << >> ELSE message.orderExecutionV2ReturnBitfield5[1])
        \o (IF message.orderExecutionV2ReturnBitfield6 = << >> THEN << >> ELSE EncodeUIntLE(message.orderExecutionV2ReturnBitfield6[1], 1))
        \o (IF message.orderExecutionV2ReturnBitfield7 = << >> THEN << >> ELSE EncodeUIntLE(message.orderExecutionV2ReturnBitfield7[1], 1))
        \o (IF message.orderExecutionV2ReturnBitfield8 = << >> THEN << >> ELSE EncodeUIntLE(message.orderExecutionV2ReturnBitfield8[1], 1))
        \o (IF message.orderExecutionV2ReturnBitfield9 = << >> THEN << >> ELSE EncodeUIntLE(message.orderExecutionV2ReturnBitfield9[1], 1))
        \o (IF message.orderExecutionV2ReturnBitfield10 = << >> THEN << >> ELSE EncodeUIntLE(message.orderExecutionV2ReturnBitfield10[1], 1))
        \o (IF message.orderExecutionV2ReturnBitfield11 = << >> THEN << >> ELSE EncodeUIntLE(message.orderExecutionV2ReturnBitfield11[1], 1))
        \o (IF message.orderExecutionV2ReturnBitfield12 = << >> THEN << >> ELSE message.orderExecutionV2ReturnBitfield12[1])
        \o (IF message.orderExecutionV2ReturnBitfield13 = << >> THEN << >> ELSE message.orderExecutionV2ReturnBitfield13[1])
        \o (IF message.orderExecutionV2ReturnBitfield14 = << >> THEN << >> ELSE message.orderExecutionV2ReturnBitfield14[1])
        \o (IF message.side = << >> THEN << >> ELSE message.side[1])
        \o (IF message.pegDifference = << >> THEN << >> ELSE message.pegDifference[1])
        \o (IF message.price = << >> THEN << >> ELSE message.price[1])
        \o (IF message.execInst = << >> THEN << >> ELSE message.execInst[1])
        \o (IF message.ordType = << >> THEN << >> ELSE message.ordType[1])
        \o (IF message.timeInForce = << >> THEN << >> ELSE message.timeInForce[1])
        \o (IF message.minQty = << >> THEN << >> ELSE message.minQty[1])
        \o (IF message.symbol = << >> THEN << >> ELSE message.symbol[1])
        \o (IF message.currency = << >> THEN << >> ELSE message.currency[1])
        \o (IF message.idSource = << >> THEN << >> ELSE message.idSource[1])
        \o (IF message.securityId = << >> THEN << >> ELSE message.securityId[1])
        \o (IF message.securityExchange = << >> THEN << >> ELSE message.securityExchange[1])
        \o (IF message.capacity = << >> THEN << >> ELSE message.capacity[1])
        \o (IF message.account = << >> THEN << >> ELSE message.account[1])
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])
        \o (IF message.clearingAccount = << >> THEN << >> ELSE message.clearingAccount[1])
        \o (IF message.displayIndicator = << >> THEN << >> ELSE message.displayIndicator[1])
        \o (IF message.maxFloor = << >> THEN << >> ELSE message.maxFloor[1])
        \o (IF message.orderQty = << >> THEN << >> ELSE message.orderQty[1])
        \o (IF message.preventParticipantMatch = << >> THEN << >> ELSE message.preventParticipantMatch[1])
        \o (IF message.secondaryOrderId = << >> THEN << >> ELSE message.secondaryOrderId[1])
        \o (IF message.centralCounterparty = << >> THEN << >> ELSE message.centralCounterparty[1])
        \o (IF message.lastMkt = << >> THEN << >> ELSE message.lastMkt[1])
        \o (IF message.feeCode = << >> THEN << >> ELSE message.feeCode[1])
        \o (IF message.echoText = << >> THEN << >> ELSE message.echoText[1])
        \o (IF message.routingInst = << >> THEN << >> ELSE message.routingInst[1])
        \o (IF message.routStrategy = << >> THEN << >> ELSE message.routStrategy[1])
        \o (IF message.routeDeliveryMethod = << >> THEN << >> ELSE message.routeDeliveryMethod[1])
        \o (IF message.exDestination = << >> THEN << >> ELSE message.exDestination[1])
        \o (IF message.tradeReportRefId = << >> THEN << >> ELSE message.tradeReportRefId[1])
        \o (IF message.liquidityProvision = << >> THEN << >> ELSE message.liquidityProvision[1])
        \o (IF message.waiverType = << >> THEN << >> ELSE message.waiverType[1])
        \o (IF message.priceFormation = << >> THEN << >> ELSE message.priceFormation[1])
        \o (IF message.clientQualifiedRole = << >> THEN << >> ELSE message.clientQualifiedRole[1])
        \o (IF message.clientId = << >> THEN << >> ELSE message.clientId[1])
        \o (IF message.investorId = << >> THEN << >> ELSE message.investorId[1])
        \o (IF message.executorId = << >> THEN << >> ELSE message.executorId[1])
        \o (IF message.orderOrigination = << >> THEN << >> ELSE message.orderOrigination[1])
        \o (IF message.algorithmicIndicator = << >> THEN << >> ELSE message.algorithmicIndicator[1])
        \o (IF message.investorQualifiedRole = << >> THEN << >> ELSE message.investorQualifiedRole[1])
        \o (IF message.executorQualifiedRole = << >> THEN << >> ELSE message.executorQualifiedRole[1])

DecodeOrderExecutionV2Message(bytes) ==
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
    LET orderExecutionV2ReturnBitfield1 == ReadWhen(numberOfReturnBitfields.value >= 1, ReadUIntLE(numberOfReturnBitfields.rest, 1), numberOfReturnBitfields.rest) IN IF ~orderExecutionV2ReturnBitfield1.ok THEN Fail ELSE
    LET orderExecutionV2ReturnBitfield2 == ReadWhen(numberOfReturnBitfields.value >= 2, ReadUIntLE(orderExecutionV2ReturnBitfield1.rest, 1), orderExecutionV2ReturnBitfield1.rest) IN IF ~orderExecutionV2ReturnBitfield2.ok THEN Fail ELSE
    LET orderExecutionV2ReturnBitfield3 == ReadWhen(numberOfReturnBitfields.value >= 3, ReadUIntLE(orderExecutionV2ReturnBitfield2.rest, 1), orderExecutionV2ReturnBitfield2.rest) IN IF ~orderExecutionV2ReturnBitfield3.ok THEN Fail ELSE
    LET orderExecutionV2ReturnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadBytes(orderExecutionV2ReturnBitfield3.rest, 1), orderExecutionV2ReturnBitfield3.rest) IN IF ~orderExecutionV2ReturnBitfield4.ok THEN Fail ELSE
    LET orderExecutionV2ReturnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadBytes(orderExecutionV2ReturnBitfield4.rest, 1), orderExecutionV2ReturnBitfield4.rest) IN IF ~orderExecutionV2ReturnBitfield5.ok THEN Fail ELSE
    LET orderExecutionV2ReturnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadUIntLE(orderExecutionV2ReturnBitfield5.rest, 1), orderExecutionV2ReturnBitfield5.rest) IN IF ~orderExecutionV2ReturnBitfield6.ok THEN Fail ELSE
    LET orderExecutionV2ReturnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadUIntLE(orderExecutionV2ReturnBitfield6.rest, 1), orderExecutionV2ReturnBitfield6.rest) IN IF ~orderExecutionV2ReturnBitfield7.ok THEN Fail ELSE
    LET orderExecutionV2ReturnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadUIntLE(orderExecutionV2ReturnBitfield7.rest, 1), orderExecutionV2ReturnBitfield7.rest) IN IF ~orderExecutionV2ReturnBitfield8.ok THEN Fail ELSE
    LET orderExecutionV2ReturnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadUIntLE(orderExecutionV2ReturnBitfield8.rest, 1), orderExecutionV2ReturnBitfield8.rest) IN IF ~orderExecutionV2ReturnBitfield9.ok THEN Fail ELSE
    LET orderExecutionV2ReturnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadUIntLE(orderExecutionV2ReturnBitfield9.rest, 1), orderExecutionV2ReturnBitfield9.rest) IN IF ~orderExecutionV2ReturnBitfield10.ok THEN Fail ELSE
    LET orderExecutionV2ReturnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadUIntLE(orderExecutionV2ReturnBitfield10.rest, 1), orderExecutionV2ReturnBitfield10.rest) IN IF ~orderExecutionV2ReturnBitfield11.ok THEN Fail ELSE
    LET orderExecutionV2ReturnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadBytes(orderExecutionV2ReturnBitfield11.rest, 1), orderExecutionV2ReturnBitfield11.rest) IN IF ~orderExecutionV2ReturnBitfield12.ok THEN Fail ELSE
    LET orderExecutionV2ReturnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(orderExecutionV2ReturnBitfield12.rest, 1), orderExecutionV2ReturnBitfield12.rest) IN IF ~orderExecutionV2ReturnBitfield13.ok THEN Fail ELSE
    LET orderExecutionV2ReturnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(orderExecutionV2ReturnBitfield13.rest, 1), orderExecutionV2ReturnBitfield13.rest) IN IF ~orderExecutionV2ReturnBitfield14.ok THEN Fail ELSE
    LET side == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderExecutionV2ReturnBitfield1.value # << >> /\ orderExecutionV2ReturnBitfield1.value[1] % 2 > 0), ReadBytes(orderExecutionV2ReturnBitfield14.rest, 1), orderExecutionV2ReturnBitfield14.rest) IN IF ~side.ok THEN Fail ELSE
    LET pegDifference == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderExecutionV2ReturnBitfield1.value # << >> /\ (orderExecutionV2ReturnBitfield1.value[1] \div 2) % 2 > 0), ReadBytes(side.rest, 8), side.rest) IN IF ~pegDifference.ok THEN Fail ELSE
    LET price == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderExecutionV2ReturnBitfield1.value # << >> /\ (orderExecutionV2ReturnBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(pegDifference.rest, 8), pegDifference.rest) IN IF ~price.ok THEN Fail ELSE
    LET execInst == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderExecutionV2ReturnBitfield1.value # << >> /\ (orderExecutionV2ReturnBitfield1.value[1] \div 8) % 2 > 0), ReadBytes(price.rest, 1), price.rest) IN IF ~execInst.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderExecutionV2ReturnBitfield1.value # << >> /\ (orderExecutionV2ReturnBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(execInst.rest, 1), execInst.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderExecutionV2ReturnBitfield1.value # << >> /\ (orderExecutionV2ReturnBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderExecutionV2ReturnBitfield1.value # << >> /\ (orderExecutionV2ReturnBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET symbol == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderExecutionV2ReturnBitfield2.value # << >> /\ orderExecutionV2ReturnBitfield2.value[1] % 2 > 0), ReadBytes(minQty.rest, 8), minQty.rest) IN IF ~symbol.ok THEN Fail ELSE
    LET currency == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderExecutionV2ReturnBitfield2.value # << >> /\ (orderExecutionV2ReturnBitfield2.value[1] \div 4) % 2 > 0), ReadBytes(symbol.rest, 3), symbol.rest) IN IF ~currency.ok THEN Fail ELSE
    LET idSource == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderExecutionV2ReturnBitfield2.value # << >> /\ (orderExecutionV2ReturnBitfield2.value[1] \div 8) % 2 > 0), ReadBytes(currency.rest, 1), currency.rest) IN IF ~idSource.ok THEN Fail ELSE
    LET securityId == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderExecutionV2ReturnBitfield2.value # << >> /\ (orderExecutionV2ReturnBitfield2.value[1] \div 16) % 2 > 0), ReadBytes(idSource.rest, 16), idSource.rest) IN IF ~securityId.ok THEN Fail ELSE
    LET securityExchange == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderExecutionV2ReturnBitfield2.value # << >> /\ (orderExecutionV2ReturnBitfield2.value[1] \div 32) % 2 > 0), ReadBytes(securityId.rest, 4), securityId.rest) IN IF ~securityExchange.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderExecutionV2ReturnBitfield2.value # << >> /\ (orderExecutionV2ReturnBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(securityExchange.rest, 1), securityExchange.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderExecutionV2ReturnBitfield3.value # << >> /\ orderExecutionV2ReturnBitfield3.value[1] % 2 > 0), ReadBytes(capacity.rest, 16), capacity.rest) IN IF ~account.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderExecutionV2ReturnBitfield3.value # << >> /\ (orderExecutionV2ReturnBitfield3.value[1] \div 2) % 2 > 0), ReadBytes(account.rest, 4), account.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderExecutionV2ReturnBitfield3.value # << >> /\ (orderExecutionV2ReturnBitfield3.value[1] \div 4) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET displayIndicator == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderExecutionV2ReturnBitfield3.value # << >> /\ (orderExecutionV2ReturnBitfield3.value[1] \div 8) % 2 > 0), ReadBytes(clearingAccount.rest, 1), clearingAccount.rest) IN IF ~displayIndicator.ok THEN Fail ELSE
    LET maxFloor == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderExecutionV2ReturnBitfield3.value # << >> /\ (orderExecutionV2ReturnBitfield3.value[1] \div 16) % 2 > 0), ReadBytes(displayIndicator.rest, 4), displayIndicator.rest) IN IF ~maxFloor.ok THEN Fail ELSE
    LET orderQty == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderExecutionV2ReturnBitfield3.value # << >> /\ (orderExecutionV2ReturnBitfield3.value[1] \div 64) % 2 > 0), ReadBytes(maxFloor.rest, 4), maxFloor.rest) IN IF ~orderQty.ok THEN Fail ELSE
    LET preventParticipantMatch == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderExecutionV2ReturnBitfield3.value # << >> /\ (orderExecutionV2ReturnBitfield3.value[1] \div 128) % 2 > 0), ReadBytes(orderQty.rest, 3), orderQty.rest) IN IF ~preventParticipantMatch.ok THEN Fail ELSE
    LET secondaryOrderId == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (orderExecutionV2ReturnBitfield6.value # << >> /\ orderExecutionV2ReturnBitfield6.value[1] % 2 > 0), ReadBytes(preventParticipantMatch.rest, 8), preventParticipantMatch.rest) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET centralCounterparty == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (orderExecutionV2ReturnBitfield6.value # << >> /\ (orderExecutionV2ReturnBitfield6.value[1] \div 2) % 2 > 0), ReadBytes(secondaryOrderId.rest, 1), secondaryOrderId.rest) IN IF ~centralCounterparty.ok THEN Fail ELSE
    LET lastMkt == ReadWhen(numberOfReturnBitfields.value >= 7 /\ (orderExecutionV2ReturnBitfield7.value # << >> /\ (orderExecutionV2ReturnBitfield7.value[1] \div 128) % 2 > 0), ReadBytes(centralCounterparty.rest, 4), centralCounterparty.rest) IN IF ~lastMkt.ok THEN Fail ELSE
    LET feeCode == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderExecutionV2ReturnBitfield8.value # << >> /\ orderExecutionV2ReturnBitfield8.value[1] % 2 > 0), ReadBytes(lastMkt.rest, 2), lastMkt.rest) IN IF ~feeCode.ok THEN Fail ELSE
    LET echoText == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderExecutionV2ReturnBitfield8.value # << >> /\ (orderExecutionV2ReturnBitfield8.value[1] \div 2) % 2 > 0), ReadBytes(feeCode.rest, 64), feeCode.rest) IN IF ~echoText.ok THEN Fail ELSE
    LET routingInst == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderExecutionV2ReturnBitfield8.value # << >> /\ (orderExecutionV2ReturnBitfield8.value[1] \div 8) % 2 > 0), ReadBytes(echoText.rest, 4), echoText.rest) IN IF ~routingInst.ok THEN Fail ELSE
    LET routStrategy == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderExecutionV2ReturnBitfield8.value # << >> /\ (orderExecutionV2ReturnBitfield8.value[1] \div 16) % 2 > 0), ReadBytes(routingInst.rest, 6), routingInst.rest) IN IF ~routStrategy.ok THEN Fail ELSE
    LET routeDeliveryMethod == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderExecutionV2ReturnBitfield8.value # << >> /\ (orderExecutionV2ReturnBitfield8.value[1] \div 32) % 2 > 0), ReadBytes(routStrategy.rest, 3), routStrategy.rest) IN IF ~routeDeliveryMethod.ok THEN Fail ELSE
    LET exDestination == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderExecutionV2ReturnBitfield8.value # << >> /\ (orderExecutionV2ReturnBitfield8.value[1] \div 64) % 2 > 0), ReadBytes(routeDeliveryMethod.rest, 1), routeDeliveryMethod.rest) IN IF ~exDestination.ok THEN Fail ELSE
    LET tradeReportRefId == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderExecutionV2ReturnBitfield8.value # << >> /\ (orderExecutionV2ReturnBitfield8.value[1] \div 128) % 2 > 0), ReadBytes(exDestination.rest, 20), exDestination.rest) IN IF ~tradeReportRefId.ok THEN Fail ELSE
    LET liquidityProvision == ReadWhen(numberOfReturnBitfields.value >= 9 /\ (orderExecutionV2ReturnBitfield9.value # << >> /\ (orderExecutionV2ReturnBitfield9.value[1] \div 16) % 2 > 0), ReadBytes(tradeReportRefId.rest, 1), tradeReportRefId.rest) IN IF ~liquidityProvision.ok THEN Fail ELSE
    LET waiverType == ReadWhen(numberOfReturnBitfields.value >= 10 /\ (orderExecutionV2ReturnBitfield10.value # << >> /\ (orderExecutionV2ReturnBitfield10.value[1] \div 16) % 2 > 0), ReadBytes(liquidityProvision.rest, 1), liquidityProvision.rest) IN IF ~waiverType.ok THEN Fail ELSE
    LET priceFormation == ReadWhen(numberOfReturnBitfields.value >= 10 /\ (orderExecutionV2ReturnBitfield10.value # << >> /\ (orderExecutionV2ReturnBitfield10.value[1] \div 64) % 2 > 0), ReadBytes(waiverType.rest, 1), waiverType.rest) IN IF ~priceFormation.ok THEN Fail ELSE
    LET clientQualifiedRole == ReadWhen(numberOfReturnBitfields.value >= 10 /\ (orderExecutionV2ReturnBitfield10.value # << >> /\ (orderExecutionV2ReturnBitfield10.value[1] \div 128) % 2 > 0), ReadBytes(priceFormation.rest, 1), priceFormation.rest) IN IF ~clientQualifiedRole.ok THEN Fail ELSE
    LET clientId == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (orderExecutionV2ReturnBitfield11.value # << >> /\ orderExecutionV2ReturnBitfield11.value[1] % 2 > 0), ReadBytes(clientQualifiedRole.rest, 4), clientQualifiedRole.rest) IN IF ~clientId.ok THEN Fail ELSE
    LET investorId == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (orderExecutionV2ReturnBitfield11.value # << >> /\ (orderExecutionV2ReturnBitfield11.value[1] \div 2) % 2 > 0), ReadBytes(clientId.rest, 4), clientId.rest) IN IF ~investorId.ok THEN Fail ELSE
    LET executorId == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (orderExecutionV2ReturnBitfield11.value # << >> /\ (orderExecutionV2ReturnBitfield11.value[1] \div 4) % 2 > 0), ReadBytes(investorId.rest, 4), investorId.rest) IN IF ~executorId.ok THEN Fail ELSE
    LET orderOrigination == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (orderExecutionV2ReturnBitfield11.value # << >> /\ (orderExecutionV2ReturnBitfield11.value[1] \div 8) % 2 > 0), ReadBytes(executorId.rest, 1), executorId.rest) IN IF ~orderOrigination.ok THEN Fail ELSE
    LET algorithmicIndicator == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (orderExecutionV2ReturnBitfield11.value # << >> /\ (orderExecutionV2ReturnBitfield11.value[1] \div 16) % 2 > 0), ReadBytes(orderOrigination.rest, 1), orderOrigination.rest) IN IF ~algorithmicIndicator.ok THEN Fail ELSE
    LET investorQualifiedRole == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (orderExecutionV2ReturnBitfield11.value # << >> /\ (orderExecutionV2ReturnBitfield11.value[1] \div 64) % 2 > 0), ReadBytes(algorithmicIndicator.rest, 1), algorithmicIndicator.rest) IN IF ~investorQualifiedRole.ok THEN Fail ELSE
    LET executorQualifiedRole == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (orderExecutionV2ReturnBitfield11.value # << >> /\ (orderExecutionV2ReturnBitfield11.value[1] \div 128) % 2 > 0), ReadBytes(investorQualifiedRole.rest, 1), investorQualifiedRole.rest) IN IF ~executorQualifiedRole.ok THEN Fail ELSE
    Ok([ transactionTime                  |-> transactionTime.value,
         clOrdId                          |-> clOrdId.value,
         execId                           |-> execId.value,
         lastShares                       |-> lastShares.value,
         lastPx                           |-> lastPx.value,
         leavesQty                        |-> leavesQty.value,
         baseLiquidityIndicator           |-> baseLiquidityIndicator.value,
         subLiquidityIndicator            |-> subLiquidityIndicator.value,
         contraBroker                     |-> contraBroker.value,
         reserved1                        |-> reserved1.value,
         numberOfReturnBitfields          |-> numberOfReturnBitfields.value,
         orderExecutionV2ReturnBitfield1  |-> orderExecutionV2ReturnBitfield1.value,
         orderExecutionV2ReturnBitfield2  |-> orderExecutionV2ReturnBitfield2.value,
         orderExecutionV2ReturnBitfield3  |-> orderExecutionV2ReturnBitfield3.value,
         orderExecutionV2ReturnBitfield4  |-> orderExecutionV2ReturnBitfield4.value,
         orderExecutionV2ReturnBitfield5  |-> orderExecutionV2ReturnBitfield5.value,
         orderExecutionV2ReturnBitfield6  |-> orderExecutionV2ReturnBitfield6.value,
         orderExecutionV2ReturnBitfield7  |-> orderExecutionV2ReturnBitfield7.value,
         orderExecutionV2ReturnBitfield8  |-> orderExecutionV2ReturnBitfield8.value,
         orderExecutionV2ReturnBitfield9  |-> orderExecutionV2ReturnBitfield9.value,
         orderExecutionV2ReturnBitfield10 |-> orderExecutionV2ReturnBitfield10.value,
         orderExecutionV2ReturnBitfield11 |-> orderExecutionV2ReturnBitfield11.value,
         orderExecutionV2ReturnBitfield12 |-> orderExecutionV2ReturnBitfield12.value,
         orderExecutionV2ReturnBitfield13 |-> orderExecutionV2ReturnBitfield13.value,
         orderExecutionV2ReturnBitfield14 |-> orderExecutionV2ReturnBitfield14.value,
         side                             |-> side.value,
         pegDifference                    |-> pegDifference.value,
         price                            |-> price.value,
         execInst                         |-> execInst.value,
         ordType                          |-> ordType.value,
         timeInForce                      |-> timeInForce.value,
         minQty                           |-> minQty.value,
         symbol                           |-> symbol.value,
         currency                         |-> currency.value,
         idSource                         |-> idSource.value,
         securityId                       |-> securityId.value,
         securityExchange                 |-> securityExchange.value,
         capacity                         |-> capacity.value,
         account                          |-> account.value,
         clearingFirm                     |-> clearingFirm.value,
         clearingAccount                  |-> clearingAccount.value,
         displayIndicator                 |-> displayIndicator.value,
         maxFloor                         |-> maxFloor.value,
         orderQty                         |-> orderQty.value,
         preventParticipantMatch          |-> preventParticipantMatch.value,
         secondaryOrderId                 |-> secondaryOrderId.value,
         centralCounterparty              |-> centralCounterparty.value,
         lastMkt                          |-> lastMkt.value,
         feeCode                          |-> feeCode.value,
         echoText                         |-> echoText.value,
         routingInst                      |-> routingInst.value,
         routStrategy                     |-> routStrategy.value,
         routeDeliveryMethod              |-> routeDeliveryMethod.value,
         exDestination                    |-> exDestination.value,
         tradeReportRefId                 |-> tradeReportRefId.value,
         liquidityProvision               |-> liquidityProvision.value,
         waiverType                       |-> waiverType.value,
         priceFormation                   |-> priceFormation.value,
         clientQualifiedRole              |-> clientQualifiedRole.value,
         clientId                         |-> clientId.value,
         investorId                       |-> investorId.value,
         executorId                       |-> executorId.value,
         orderOrigination                 |-> orderOrigination.value,
         algorithmicIndicator             |-> algorithmicIndicator.value,
         investorQualifiedRole            |-> investorQualifiedRole.value,
         executorQualifiedRole            |-> executorQualifiedRole.value ], executorQualifiedRole.rest)

(* Order Execution V 2 Message with each field marked present by fields before it there exactly where they say *)
SettleOrderExecutionV2Message(message) ==
    LET settled1 == [message EXCEPT !.orderExecutionV2ReturnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.orderExecutionV2ReturnBitfield1 = << >> THEN <<0>> ELSE message.orderExecutionV2ReturnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.orderExecutionV2ReturnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.orderExecutionV2ReturnBitfield2 = << >> THEN <<0>> ELSE settled1.orderExecutionV2ReturnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.orderExecutionV2ReturnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.orderExecutionV2ReturnBitfield3 = << >> THEN <<0>> ELSE settled2.orderExecutionV2ReturnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.orderExecutionV2ReturnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.orderExecutionV2ReturnBitfield4 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled3.orderExecutionV2ReturnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.orderExecutionV2ReturnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.orderExecutionV2ReturnBitfield5 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled4.orderExecutionV2ReturnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.orderExecutionV2ReturnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.orderExecutionV2ReturnBitfield6 = << >> THEN <<0>> ELSE settled5.orderExecutionV2ReturnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.orderExecutionV2ReturnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.orderExecutionV2ReturnBitfield7 = << >> THEN <<0>> ELSE settled6.orderExecutionV2ReturnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.orderExecutionV2ReturnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.orderExecutionV2ReturnBitfield8 = << >> THEN <<0>> ELSE settled7.orderExecutionV2ReturnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.orderExecutionV2ReturnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.orderExecutionV2ReturnBitfield9 = << >> THEN <<0>> ELSE settled8.orderExecutionV2ReturnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.orderExecutionV2ReturnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.orderExecutionV2ReturnBitfield10 = << >> THEN <<0>> ELSE settled9.orderExecutionV2ReturnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.orderExecutionV2ReturnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.orderExecutionV2ReturnBitfield11 = << >> THEN <<0>> ELSE settled10.orderExecutionV2ReturnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.orderExecutionV2ReturnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.orderExecutionV2ReturnBitfield12 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.orderExecutionV2ReturnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.orderExecutionV2ReturnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.orderExecutionV2ReturnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.orderExecutionV2ReturnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.orderExecutionV2ReturnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.orderExecutionV2ReturnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.orderExecutionV2ReturnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.side = IF settled14.numberOfReturnBitfields >= 1 /\ (settled14.orderExecutionV2ReturnBitfield1 # << >> /\ settled14.orderExecutionV2ReturnBitfield1[1] % 2 > 0) THEN (IF settled14.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.side) ELSE << >>]
        settled16 == [settled15 EXCEPT !.pegDifference = IF settled15.numberOfReturnBitfields >= 1 /\ (settled15.orderExecutionV2ReturnBitfield1 # << >> /\ (settled15.orderExecutionV2ReturnBitfield1[1] \div 2) % 2 > 0) THEN (IF settled15.pegDifference = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled15.pegDifference) ELSE << >>]
        settled17 == [settled16 EXCEPT !.price = IF settled16.numberOfReturnBitfields >= 1 /\ (settled16.orderExecutionV2ReturnBitfield1 # << >> /\ (settled16.orderExecutionV2ReturnBitfield1[1] \div 4) % 2 > 0) THEN (IF settled16.price = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled16.price) ELSE << >>]
        settled18 == [settled17 EXCEPT !.execInst = IF settled17.numberOfReturnBitfields >= 1 /\ (settled17.orderExecutionV2ReturnBitfield1 # << >> /\ (settled17.orderExecutionV2ReturnBitfield1[1] \div 8) % 2 > 0) THEN (IF settled17.execInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.execInst) ELSE << >>]
        settled19 == [settled18 EXCEPT !.ordType = IF settled18.numberOfReturnBitfields >= 1 /\ (settled18.orderExecutionV2ReturnBitfield1 # << >> /\ (settled18.orderExecutionV2ReturnBitfield1[1] \div 16) % 2 > 0) THEN (IF settled18.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled18.ordType) ELSE << >>]
        settled20 == [settled19 EXCEPT !.timeInForce = IF settled19.numberOfReturnBitfields >= 1 /\ (settled19.orderExecutionV2ReturnBitfield1 # << >> /\ (settled19.orderExecutionV2ReturnBitfield1[1] \div 32) % 2 > 0) THEN (IF settled19.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled19.timeInForce) ELSE << >>]
        settled21 == [settled20 EXCEPT !.minQty = IF settled20.numberOfReturnBitfields >= 1 /\ (settled20.orderExecutionV2ReturnBitfield1 # << >> /\ (settled20.orderExecutionV2ReturnBitfield1[1] \div 64) % 2 > 0) THEN (IF settled20.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled20.minQty) ELSE << >>]
        settled22 == [settled21 EXCEPT !.symbol = IF settled21.numberOfReturnBitfields >= 2 /\ (settled21.orderExecutionV2ReturnBitfield2 # << >> /\ settled21.orderExecutionV2ReturnBitfield2[1] % 2 > 0) THEN (IF settled21.symbol = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled21.symbol) ELSE << >>]
        settled23 == [settled22 EXCEPT !.currency = IF settled22.numberOfReturnBitfields >= 2 /\ (settled22.orderExecutionV2ReturnBitfield2 # << >> /\ (settled22.orderExecutionV2ReturnBitfield2[1] \div 4) % 2 > 0) THEN (IF settled22.currency = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled22.currency) ELSE << >>]
        settled24 == [settled23 EXCEPT !.idSource = IF settled23.numberOfReturnBitfields >= 2 /\ (settled23.orderExecutionV2ReturnBitfield2 # << >> /\ (settled23.orderExecutionV2ReturnBitfield2[1] \div 8) % 2 > 0) THEN (IF settled23.idSource = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled23.idSource) ELSE << >>]
        settled25 == [settled24 EXCEPT !.securityId = IF settled24.numberOfReturnBitfields >= 2 /\ (settled24.orderExecutionV2ReturnBitfield2 # << >> /\ (settled24.orderExecutionV2ReturnBitfield2[1] \div 16) % 2 > 0) THEN (IF settled24.securityId = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled24.securityId) ELSE << >>]
        settled26 == [settled25 EXCEPT !.securityExchange = IF settled25.numberOfReturnBitfields >= 2 /\ (settled25.orderExecutionV2ReturnBitfield2 # << >> /\ (settled25.orderExecutionV2ReturnBitfield2[1] \div 32) % 2 > 0) THEN (IF settled25.securityExchange = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled25.securityExchange) ELSE << >>]
        settled27 == [settled26 EXCEPT !.capacity = IF settled26.numberOfReturnBitfields >= 2 /\ (settled26.orderExecutionV2ReturnBitfield2 # << >> /\ (settled26.orderExecutionV2ReturnBitfield2[1] \div 64) % 2 > 0) THEN (IF settled26.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled26.capacity) ELSE << >>]
        settled28 == [settled27 EXCEPT !.account = IF settled27.numberOfReturnBitfields >= 3 /\ (settled27.orderExecutionV2ReturnBitfield3 # << >> /\ settled27.orderExecutionV2ReturnBitfield3[1] % 2 > 0) THEN (IF settled27.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled27.account) ELSE << >>]
        settled29 == [settled28 EXCEPT !.clearingFirm = IF settled28.numberOfReturnBitfields >= 3 /\ (settled28.orderExecutionV2ReturnBitfield3 # << >> /\ (settled28.orderExecutionV2ReturnBitfield3[1] \div 2) % 2 > 0) THEN (IF settled28.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled28.clearingFirm) ELSE << >>]
        settled30 == [settled29 EXCEPT !.clearingAccount = IF settled29.numberOfReturnBitfields >= 3 /\ (settled29.orderExecutionV2ReturnBitfield3 # << >> /\ (settled29.orderExecutionV2ReturnBitfield3[1] \div 4) % 2 > 0) THEN (IF settled29.clearingAccount = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled29.clearingAccount) ELSE << >>]
        settled31 == [settled30 EXCEPT !.displayIndicator = IF settled30.numberOfReturnBitfields >= 3 /\ (settled30.orderExecutionV2ReturnBitfield3 # << >> /\ (settled30.orderExecutionV2ReturnBitfield3[1] \div 8) % 2 > 0) THEN (IF settled30.displayIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled30.displayIndicator) ELSE << >>]
        settled32 == [settled31 EXCEPT !.maxFloor = IF settled31.numberOfReturnBitfields >= 3 /\ (settled31.orderExecutionV2ReturnBitfield3 # << >> /\ (settled31.orderExecutionV2ReturnBitfield3[1] \div 16) % 2 > 0) THEN (IF settled31.maxFloor = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled31.maxFloor) ELSE << >>]
        settled33 == [settled32 EXCEPT !.orderQty = IF settled32.numberOfReturnBitfields >= 3 /\ (settled32.orderExecutionV2ReturnBitfield3 # << >> /\ (settled32.orderExecutionV2ReturnBitfield3[1] \div 64) % 2 > 0) THEN (IF settled32.orderQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled32.orderQty) ELSE << >>]
        settled34 == [settled33 EXCEPT !.preventParticipantMatch = IF settled33.numberOfReturnBitfields >= 3 /\ (settled33.orderExecutionV2ReturnBitfield3 # << >> /\ (settled33.orderExecutionV2ReturnBitfield3[1] \div 128) % 2 > 0) THEN (IF settled33.preventParticipantMatch = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled33.preventParticipantMatch) ELSE << >>]
        settled35 == [settled34 EXCEPT !.secondaryOrderId = IF settled34.numberOfReturnBitfields >= 6 /\ (settled34.orderExecutionV2ReturnBitfield6 # << >> /\ settled34.orderExecutionV2ReturnBitfield6[1] % 2 > 0) THEN (IF settled34.secondaryOrderId = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled34.secondaryOrderId) ELSE << >>]
        settled36 == [settled35 EXCEPT !.centralCounterparty = IF settled35.numberOfReturnBitfields >= 6 /\ (settled35.orderExecutionV2ReturnBitfield6 # << >> /\ (settled35.orderExecutionV2ReturnBitfield6[1] \div 2) % 2 > 0) THEN (IF settled35.centralCounterparty = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled35.centralCounterparty) ELSE << >>]
        settled37 == [settled36 EXCEPT !.lastMkt = IF settled36.numberOfReturnBitfields >= 7 /\ (settled36.orderExecutionV2ReturnBitfield7 # << >> /\ (settled36.orderExecutionV2ReturnBitfield7[1] \div 128) % 2 > 0) THEN (IF settled36.lastMkt = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled36.lastMkt) ELSE << >>]
        settled38 == [settled37 EXCEPT !.feeCode = IF settled37.numberOfReturnBitfields >= 8 /\ (settled37.orderExecutionV2ReturnBitfield8 # << >> /\ settled37.orderExecutionV2ReturnBitfield8[1] % 2 > 0) THEN (IF settled37.feeCode = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled37.feeCode) ELSE << >>]
        settled39 == [settled38 EXCEPT !.echoText = IF settled38.numberOfReturnBitfields >= 8 /\ (settled38.orderExecutionV2ReturnBitfield8 # << >> /\ (settled38.orderExecutionV2ReturnBitfield8[1] \div 2) % 2 > 0) THEN (IF settled38.echoText = << >> THEN <<[i \in 1 .. 64 |-> 0]>> ELSE settled38.echoText) ELSE << >>]
        settled40 == [settled39 EXCEPT !.routingInst = IF settled39.numberOfReturnBitfields >= 8 /\ (settled39.orderExecutionV2ReturnBitfield8 # << >> /\ (settled39.orderExecutionV2ReturnBitfield8[1] \div 8) % 2 > 0) THEN (IF settled39.routingInst = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled39.routingInst) ELSE << >>]
        settled41 == [settled40 EXCEPT !.routStrategy = IF settled40.numberOfReturnBitfields >= 8 /\ (settled40.orderExecutionV2ReturnBitfield8 # << >> /\ (settled40.orderExecutionV2ReturnBitfield8[1] \div 16) % 2 > 0) THEN (IF settled40.routStrategy = << >> THEN <<[i \in 1 .. 6 |-> 0]>> ELSE settled40.routStrategy) ELSE << >>]
        settled42 == [settled41 EXCEPT !.routeDeliveryMethod = IF settled41.numberOfReturnBitfields >= 8 /\ (settled41.orderExecutionV2ReturnBitfield8 # << >> /\ (settled41.orderExecutionV2ReturnBitfield8[1] \div 32) % 2 > 0) THEN (IF settled41.routeDeliveryMethod = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled41.routeDeliveryMethod) ELSE << >>]
        settled43 == [settled42 EXCEPT !.exDestination = IF settled42.numberOfReturnBitfields >= 8 /\ (settled42.orderExecutionV2ReturnBitfield8 # << >> /\ (settled42.orderExecutionV2ReturnBitfield8[1] \div 64) % 2 > 0) THEN (IF settled42.exDestination = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled42.exDestination) ELSE << >>]
        settled44 == [settled43 EXCEPT !.tradeReportRefId = IF settled43.numberOfReturnBitfields >= 8 /\ (settled43.orderExecutionV2ReturnBitfield8 # << >> /\ (settled43.orderExecutionV2ReturnBitfield8[1] \div 128) % 2 > 0) THEN (IF settled43.tradeReportRefId = << >> THEN <<[i \in 1 .. 20 |-> 0]>> ELSE settled43.tradeReportRefId) ELSE << >>]
        settled45 == [settled44 EXCEPT !.liquidityProvision = IF settled44.numberOfReturnBitfields >= 9 /\ (settled44.orderExecutionV2ReturnBitfield9 # << >> /\ (settled44.orderExecutionV2ReturnBitfield9[1] \div 16) % 2 > 0) THEN (IF settled44.liquidityProvision = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled44.liquidityProvision) ELSE << >>]
        settled46 == [settled45 EXCEPT !.waiverType = IF settled45.numberOfReturnBitfields >= 10 /\ (settled45.orderExecutionV2ReturnBitfield10 # << >> /\ (settled45.orderExecutionV2ReturnBitfield10[1] \div 16) % 2 > 0) THEN (IF settled45.waiverType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled45.waiverType) ELSE << >>]
        settled47 == [settled46 EXCEPT !.priceFormation = IF settled46.numberOfReturnBitfields >= 10 /\ (settled46.orderExecutionV2ReturnBitfield10 # << >> /\ (settled46.orderExecutionV2ReturnBitfield10[1] \div 64) % 2 > 0) THEN (IF settled46.priceFormation = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled46.priceFormation) ELSE << >>]
        settled48 == [settled47 EXCEPT !.clientQualifiedRole = IF settled47.numberOfReturnBitfields >= 10 /\ (settled47.orderExecutionV2ReturnBitfield10 # << >> /\ (settled47.orderExecutionV2ReturnBitfield10[1] \div 128) % 2 > 0) THEN (IF settled47.clientQualifiedRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled47.clientQualifiedRole) ELSE << >>]
        settled49 == [settled48 EXCEPT !.clientId = IF settled48.numberOfReturnBitfields >= 11 /\ (settled48.orderExecutionV2ReturnBitfield11 # << >> /\ settled48.orderExecutionV2ReturnBitfield11[1] % 2 > 0) THEN (IF settled48.clientId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled48.clientId) ELSE << >>]
        settled50 == [settled49 EXCEPT !.investorId = IF settled49.numberOfReturnBitfields >= 11 /\ (settled49.orderExecutionV2ReturnBitfield11 # << >> /\ (settled49.orderExecutionV2ReturnBitfield11[1] \div 2) % 2 > 0) THEN (IF settled49.investorId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled49.investorId) ELSE << >>]
        settled51 == [settled50 EXCEPT !.executorId = IF settled50.numberOfReturnBitfields >= 11 /\ (settled50.orderExecutionV2ReturnBitfield11 # << >> /\ (settled50.orderExecutionV2ReturnBitfield11[1] \div 4) % 2 > 0) THEN (IF settled50.executorId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled50.executorId) ELSE << >>]
        settled52 == [settled51 EXCEPT !.orderOrigination = IF settled51.numberOfReturnBitfields >= 11 /\ (settled51.orderExecutionV2ReturnBitfield11 # << >> /\ (settled51.orderExecutionV2ReturnBitfield11[1] \div 8) % 2 > 0) THEN (IF settled51.orderOrigination = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled51.orderOrigination) ELSE << >>]
        settled53 == [settled52 EXCEPT !.algorithmicIndicator = IF settled52.numberOfReturnBitfields >= 11 /\ (settled52.orderExecutionV2ReturnBitfield11 # << >> /\ (settled52.orderExecutionV2ReturnBitfield11[1] \div 16) % 2 > 0) THEN (IF settled52.algorithmicIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled52.algorithmicIndicator) ELSE << >>]
        settled54 == [settled53 EXCEPT !.investorQualifiedRole = IF settled53.numberOfReturnBitfields >= 11 /\ (settled53.orderExecutionV2ReturnBitfield11 # << >> /\ (settled53.orderExecutionV2ReturnBitfield11[1] \div 64) % 2 > 0) THEN (IF settled53.investorQualifiedRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled53.investorQualifiedRole) ELSE << >>]
        settled55 == [settled54 EXCEPT !.executorQualifiedRole = IF settled54.numberOfReturnBitfields >= 11 /\ (settled54.orderExecutionV2ReturnBitfield11 # << >> /\ (settled54.orderExecutionV2ReturnBitfield11[1] \div 128) % 2 > 0) THEN (IF settled54.executorQualifiedRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled54.executorQualifiedRole) ELSE << >>]
    IN  settled55

ZeroOrderExecutionV2Message ==
    SettleOrderExecutionV2Message([ transactionTime                  |-> [i \in 1 .. 8 |-> 0],
                                    clOrdId                          |-> [i \in 1 .. 20 |-> 0],
                                    execId                           |-> [i \in 1 .. 8 |-> 0],
                                    lastShares                       |-> [i \in 1 .. 4 |-> 0],
                                    lastPx                           |-> [i \in 1 .. 8 |-> 0],
                                    leavesQty                        |-> [i \in 1 .. 4 |-> 0],
                                    baseLiquidityIndicator           |-> [i \in 1 .. 1 |-> 0],
                                    subLiquidityIndicator            |-> [i \in 1 .. 1 |-> 0],
                                    contraBroker                     |-> [i \in 1 .. 4 |-> 0],
                                    reserved1                        |-> [i \in 1 .. 1 |-> 0],
                                    numberOfReturnBitfields          |-> 0,
                                    orderExecutionV2ReturnBitfield1  |-> << >>,
                                    orderExecutionV2ReturnBitfield2  |-> << >>,
                                    orderExecutionV2ReturnBitfield3  |-> << >>,
                                    orderExecutionV2ReturnBitfield4  |-> << >>,
                                    orderExecutionV2ReturnBitfield5  |-> << >>,
                                    orderExecutionV2ReturnBitfield6  |-> << >>,
                                    orderExecutionV2ReturnBitfield7  |-> << >>,
                                    orderExecutionV2ReturnBitfield8  |-> << >>,
                                    orderExecutionV2ReturnBitfield9  |-> << >>,
                                    orderExecutionV2ReturnBitfield10 |-> << >>,
                                    orderExecutionV2ReturnBitfield11 |-> << >>,
                                    orderExecutionV2ReturnBitfield12 |-> << >>,
                                    orderExecutionV2ReturnBitfield13 |-> << >>,
                                    orderExecutionV2ReturnBitfield14 |-> << >>,
                                    side                             |-> << >>,
                                    pegDifference                    |-> << >>,
                                    price                            |-> << >>,
                                    execInst                         |-> << >>,
                                    ordType                          |-> << >>,
                                    timeInForce                      |-> << >>,
                                    minQty                           |-> << >>,
                                    symbol                           |-> << >>,
                                    currency                         |-> << >>,
                                    idSource                         |-> << >>,
                                    securityId                       |-> << >>,
                                    securityExchange                 |-> << >>,
                                    capacity                         |-> << >>,
                                    account                          |-> << >>,
                                    clearingFirm                     |-> << >>,
                                    clearingAccount                  |-> << >>,
                                    displayIndicator                 |-> << >>,
                                    maxFloor                         |-> << >>,
                                    orderQty                         |-> << >>,
                                    preventParticipantMatch          |-> << >>,
                                    secondaryOrderId                 |-> << >>,
                                    centralCounterparty              |-> << >>,
                                    lastMkt                          |-> << >>,
                                    feeCode                          |-> << >>,
                                    echoText                         |-> << >>,
                                    routingInst                      |-> << >>,
                                    routStrategy                     |-> << >>,
                                    routeDeliveryMethod              |-> << >>,
                                    exDestination                    |-> << >>,
                                    tradeReportRefId                 |-> << >>,
                                    liquidityProvision               |-> << >>,
                                    waiverType                       |-> << >>,
                                    priceFormation                   |-> << >>,
                                    clientQualifiedRole              |-> << >>,
                                    clientId                         |-> << >>,
                                    investorId                       |-> << >>,
                                    executorId                       |-> << >>,
                                    orderOrigination                 |-> << >>,
                                    algorithmicIndicator             |-> << >>,
                                    investorQualifiedRole            |-> << >>,
                                    executorQualifiedRole            |-> << >> ])

(* Order Execution V 2 Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutionV2Message ==
    { ZeroOrderExecutionV2Message }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.transactionTime = one]) : one \in Sample(8) }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.clOrdId = one]) : one \in Sample(20) }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.execId = one]) : one \in Sample(8) }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.lastShares = one]) : one \in Sample(4) }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.lastPx = one]) : one \in Sample(8) }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.leavesQty = one]) : one \in Sample(4) }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.baseLiquidityIndicator = one]) : one \in Sample(1) }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.subLiquidityIndicator = one]) : one \in Sample(1) }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.contraBroker = one]) : one \in Sample(4) }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.reserved1 = one]) : one \in Sample(1) }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderExecutionV2ReturnBitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 2, !.orderExecutionV2ReturnBitfield2 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderExecutionV2ReturnBitfield3 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 4, !.orderExecutionV2ReturnBitfield4 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 5, !.orderExecutionV2ReturnBitfield5 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 6, !.orderExecutionV2ReturnBitfield6 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 7, !.orderExecutionV2ReturnBitfield7 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 8, !.orderExecutionV2ReturnBitfield8 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 9, !.orderExecutionV2ReturnBitfield9 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 10, !.orderExecutionV2ReturnBitfield10 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderExecutionV2ReturnBitfield11 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 12, !.orderExecutionV2ReturnBitfield12 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 13, !.orderExecutionV2ReturnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 14, !.orderExecutionV2ReturnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderExecutionV2ReturnBitfield1 = <<1>>, !.side = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderExecutionV2ReturnBitfield1 = <<2>>, !.pegDifference = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderExecutionV2ReturnBitfield1 = <<4>>, !.price = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderExecutionV2ReturnBitfield1 = <<8>>, !.execInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderExecutionV2ReturnBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderExecutionV2ReturnBitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 1, !.orderExecutionV2ReturnBitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 2, !.orderExecutionV2ReturnBitfield2 = <<1>>, !.symbol = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 2, !.orderExecutionV2ReturnBitfield2 = <<4>>, !.currency = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 2, !.orderExecutionV2ReturnBitfield2 = <<8>>, !.idSource = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 2, !.orderExecutionV2ReturnBitfield2 = <<16>>, !.securityId = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 2, !.orderExecutionV2ReturnBitfield2 = <<32>>, !.securityExchange = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 2, !.orderExecutionV2ReturnBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderExecutionV2ReturnBitfield3 = <<1>>, !.account = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderExecutionV2ReturnBitfield3 = <<2>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderExecutionV2ReturnBitfield3 = <<4>>, !.clearingAccount = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderExecutionV2ReturnBitfield3 = <<8>>, !.displayIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderExecutionV2ReturnBitfield3 = <<16>>, !.maxFloor = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderExecutionV2ReturnBitfield3 = <<64>>, !.orderQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 3, !.orderExecutionV2ReturnBitfield3 = <<128>>, !.preventParticipantMatch = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 6, !.orderExecutionV2ReturnBitfield6 = <<1>>, !.secondaryOrderId = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 6, !.orderExecutionV2ReturnBitfield6 = <<2>>, !.centralCounterparty = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 7, !.orderExecutionV2ReturnBitfield7 = <<128>>, !.lastMkt = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 8, !.orderExecutionV2ReturnBitfield8 = <<1>>, !.feeCode = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 8, !.orderExecutionV2ReturnBitfield8 = <<2>>, !.echoText = one]) : one \in { <<held>> : held \in Sample(64) } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 8, !.orderExecutionV2ReturnBitfield8 = <<8>>, !.routingInst = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 8, !.orderExecutionV2ReturnBitfield8 = <<16>>, !.routStrategy = one]) : one \in { <<held>> : held \in Sample(6) } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 8, !.orderExecutionV2ReturnBitfield8 = <<32>>, !.routeDeliveryMethod = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 8, !.orderExecutionV2ReturnBitfield8 = <<64>>, !.exDestination = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 8, !.orderExecutionV2ReturnBitfield8 = <<128>>, !.tradeReportRefId = one]) : one \in { <<held>> : held \in Sample(20) } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 9, !.orderExecutionV2ReturnBitfield9 = <<16>>, !.liquidityProvision = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 10, !.orderExecutionV2ReturnBitfield10 = <<16>>, !.waiverType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 10, !.orderExecutionV2ReturnBitfield10 = <<64>>, !.priceFormation = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 10, !.orderExecutionV2ReturnBitfield10 = <<128>>, !.clientQualifiedRole = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderExecutionV2ReturnBitfield11 = <<1>>, !.clientId = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderExecutionV2ReturnBitfield11 = <<2>>, !.investorId = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderExecutionV2ReturnBitfield11 = <<4>>, !.executorId = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderExecutionV2ReturnBitfield11 = <<8>>, !.orderOrigination = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderExecutionV2ReturnBitfield11 = <<16>>, !.algorithmicIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderExecutionV2ReturnBitfield11 = <<64>>, !.investorQualifiedRole = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionV2Message([ZeroOrderExecutionV2Message EXCEPT !.numberOfReturnBitfields = 11, !.orderExecutionV2ReturnBitfield11 = <<128>>, !.executorQualifiedRole = one]) : one \in { <<held>> : held \in Sample(1) } }

(***************************************************************************)
(* Trade Cancel Or Correct V 2 Message                                     *)
(***************************************************************************)

TradeCancelOrCorrectV2Message ==
    [ transactionTime                        : Sample(8),
      clOrdId                                : Sample(20),
      orderId                                : Sample(8),
      execRefId                              : Sample(8),
      side                                   : Sample(1),
      baseLiquidityIndicator                 : Sample(1),
      clearingFirm                           : Sample(4),
      clearingAccount                        : Sample(4),
      lastShares                             : Sample(4),
      lastPx                                 : Sample(8),
      correctedPrice                         : Sample(8),
      origTime                               : Sample(8),
      reserved1                              : Sample(1),
      numberOfReturnBitfields                : 0 .. 255,
      tradeCancelorCorrectV2ReturnBitfield1  : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCancelorCorrectV2ReturnBitfield2  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCancelorCorrectV2ReturnBitfield3  : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCancelorCorrectV2ReturnBitfield4  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCancelorCorrectV2ReturnBitfield5  : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCancelorCorrectV2ReturnBitfield6  : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCancelorCorrectV2ReturnBitfield7  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCancelorCorrectV2ReturnBitfield8  : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCancelorCorrectV2ReturnBitfield9  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCancelorCorrectV2ReturnBitfield10 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCancelorCorrectV2ReturnBitfield11 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCancelorCorrectV2ReturnBitfield12 : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCancelorCorrectV2ReturnBitfield13 : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCancelorCorrectV2ReturnBitfield14 : { << >> } \cup { <<held>> : held \in Sample(1) },
      symbol                                 : { << >> } \cup { <<held>> : held \in Sample(8) },
      currency                               : { << >> } \cup { <<held>> : held \in Sample(3) },
      idSource                               : { << >> } \cup { <<held>> : held \in Sample(1) },
      securityId                             : { << >> } \cup { <<held>> : held \in Sample(16) },
      securityExchange                       : { << >> } \cup { <<held>> : held \in Sample(4) },
      capacity                               : { << >> } \cup { <<held>> : held \in Sample(1) },
      correctedSize                          : { << >> } \cup { <<held>> : held \in Sample(4) },
      tradeReportTypeReturn                  : { << >> } \cup { <<held>> : held \in Sample(2) },
      tradePublishIndicator                  : { << >> } \cup { <<held>> : held \in Sample(1) },
      rptTime                                : { << >> } \cup { <<held>> : held \in Sample(8) },
      text                                   : { << >> } \cup { <<held>> : held \in Sample(60) },
      bidPx                                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      bidSize                                : { << >> } \cup { <<held>> : held \in Sample(4) },
      offerPx                                : { << >> } \cup { <<held>> : held \in Sample(8) },
      offerSize                              : { << >> } \cup { <<held>> : held \in Sample(4) },
      largeSize                              : { << >> } \cup { <<held>> : held \in Sample(8) },
      lastMkt                                : { << >> } \cup { <<held>> : held \in Sample(4) },
      liquidityProvision                     : { << >> } \cup { <<held>> : held \in Sample(1) },
      priceFormation                         : { << >> } \cup { <<held>> : held \in Sample(1) },
      clientQualifiedRole                    : { << >> } \cup { <<held>> : held \in Sample(1) },
      clientId                               : { << >> } \cup { <<held>> : held \in Sample(4) },
      investorId                             : { << >> } \cup { <<held>> : held \in Sample(4) },
      executorId                             : { << >> } \cup { <<held>> : held \in Sample(4) },
      orderOrigination                       : { << >> } \cup { <<held>> : held \in Sample(1) },
      algorithmicIndicator                   : { << >> } \cup { <<held>> : held \in Sample(1) },
      investorQualifiedRole                  : { << >> } \cup { <<held>> : held \in Sample(1) },
      executorQualifiedRole                  : { << >> } \cup { <<held>> : held \in Sample(1) } ]

EncodeTradeCancelOrCorrectV2Message(message) ==
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
        \o (IF message.tradeCancelorCorrectV2ReturnBitfield1 = << >> THEN << >> ELSE message.tradeCancelorCorrectV2ReturnBitfield1[1])
        \o (IF message.tradeCancelorCorrectV2ReturnBitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCancelorCorrectV2ReturnBitfield2[1], 1))
        \o (IF message.tradeCancelorCorrectV2ReturnBitfield3 = << >> THEN << >> ELSE message.tradeCancelorCorrectV2ReturnBitfield3[1])
        \o (IF message.tradeCancelorCorrectV2ReturnBitfield4 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCancelorCorrectV2ReturnBitfield4[1], 1))
        \o (IF message.tradeCancelorCorrectV2ReturnBitfield5 = << >> THEN << >> ELSE message.tradeCancelorCorrectV2ReturnBitfield5[1])
        \o (IF message.tradeCancelorCorrectV2ReturnBitfield6 = << >> THEN << >> ELSE message.tradeCancelorCorrectV2ReturnBitfield6[1])
        \o (IF message.tradeCancelorCorrectV2ReturnBitfield7 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCancelorCorrectV2ReturnBitfield7[1], 1))
        \o (IF message.tradeCancelorCorrectV2ReturnBitfield8 = << >> THEN << >> ELSE message.tradeCancelorCorrectV2ReturnBitfield8[1])
        \o (IF message.tradeCancelorCorrectV2ReturnBitfield9 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCancelorCorrectV2ReturnBitfield9[1], 1))
        \o (IF message.tradeCancelorCorrectV2ReturnBitfield10 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCancelorCorrectV2ReturnBitfield10[1], 1))
        \o (IF message.tradeCancelorCorrectV2ReturnBitfield11 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCancelorCorrectV2ReturnBitfield11[1], 1))
        \o (IF message.tradeCancelorCorrectV2ReturnBitfield12 = << >> THEN << >> ELSE message.tradeCancelorCorrectV2ReturnBitfield12[1])
        \o (IF message.tradeCancelorCorrectV2ReturnBitfield13 = << >> THEN << >> ELSE message.tradeCancelorCorrectV2ReturnBitfield13[1])
        \o (IF message.tradeCancelorCorrectV2ReturnBitfield14 = << >> THEN << >> ELSE message.tradeCancelorCorrectV2ReturnBitfield14[1])
        \o (IF message.symbol = << >> THEN << >> ELSE message.symbol[1])
        \o (IF message.currency = << >> THEN << >> ELSE message.currency[1])
        \o (IF message.idSource = << >> THEN << >> ELSE message.idSource[1])
        \o (IF message.securityId = << >> THEN << >> ELSE message.securityId[1])
        \o (IF message.securityExchange = << >> THEN << >> ELSE message.securityExchange[1])
        \o (IF message.capacity = << >> THEN << >> ELSE message.capacity[1])
        \o (IF message.correctedSize = << >> THEN << >> ELSE message.correctedSize[1])
        \o (IF message.tradeReportTypeReturn = << >> THEN << >> ELSE message.tradeReportTypeReturn[1])
        \o (IF message.tradePublishIndicator = << >> THEN << >> ELSE message.tradePublishIndicator[1])
        \o (IF message.rptTime = << >> THEN << >> ELSE message.rptTime[1])
        \o (IF message.text = << >> THEN << >> ELSE message.text[1])
        \o (IF message.bidPx = << >> THEN << >> ELSE message.bidPx[1])
        \o (IF message.bidSize = << >> THEN << >> ELSE message.bidSize[1])
        \o (IF message.offerPx = << >> THEN << >> ELSE message.offerPx[1])
        \o (IF message.offerSize = << >> THEN << >> ELSE message.offerSize[1])
        \o (IF message.largeSize = << >> THEN << >> ELSE message.largeSize[1])
        \o (IF message.lastMkt = << >> THEN << >> ELSE message.lastMkt[1])
        \o (IF message.liquidityProvision = << >> THEN << >> ELSE message.liquidityProvision[1])
        \o (IF message.priceFormation = << >> THEN << >> ELSE message.priceFormation[1])
        \o (IF message.clientQualifiedRole = << >> THEN << >> ELSE message.clientQualifiedRole[1])
        \o (IF message.clientId = << >> THEN << >> ELSE message.clientId[1])
        \o (IF message.investorId = << >> THEN << >> ELSE message.investorId[1])
        \o (IF message.executorId = << >> THEN << >> ELSE message.executorId[1])
        \o (IF message.orderOrigination = << >> THEN << >> ELSE message.orderOrigination[1])
        \o (IF message.algorithmicIndicator = << >> THEN << >> ELSE message.algorithmicIndicator[1])
        \o (IF message.investorQualifiedRole = << >> THEN << >> ELSE message.investorQualifiedRole[1])
        \o (IF message.executorQualifiedRole = << >> THEN << >> ELSE message.executorQualifiedRole[1])

DecodeTradeCancelOrCorrectV2Message(bytes) ==
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
    LET tradeCancelorCorrectV2ReturnBitfield1 == ReadWhen(numberOfReturnBitfields.value >= 1, ReadBytes(numberOfReturnBitfields.rest, 1), numberOfReturnBitfields.rest) IN IF ~tradeCancelorCorrectV2ReturnBitfield1.ok THEN Fail ELSE
    LET tradeCancelorCorrectV2ReturnBitfield2 == ReadWhen(numberOfReturnBitfields.value >= 2, ReadUIntLE(tradeCancelorCorrectV2ReturnBitfield1.rest, 1), tradeCancelorCorrectV2ReturnBitfield1.rest) IN IF ~tradeCancelorCorrectV2ReturnBitfield2.ok THEN Fail ELSE
    LET tradeCancelorCorrectV2ReturnBitfield3 == ReadWhen(numberOfReturnBitfields.value >= 3, ReadBytes(tradeCancelorCorrectV2ReturnBitfield2.rest, 1), tradeCancelorCorrectV2ReturnBitfield2.rest) IN IF ~tradeCancelorCorrectV2ReturnBitfield3.ok THEN Fail ELSE
    LET tradeCancelorCorrectV2ReturnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadUIntLE(tradeCancelorCorrectV2ReturnBitfield3.rest, 1), tradeCancelorCorrectV2ReturnBitfield3.rest) IN IF ~tradeCancelorCorrectV2ReturnBitfield4.ok THEN Fail ELSE
    LET tradeCancelorCorrectV2ReturnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadBytes(tradeCancelorCorrectV2ReturnBitfield4.rest, 1), tradeCancelorCorrectV2ReturnBitfield4.rest) IN IF ~tradeCancelorCorrectV2ReturnBitfield5.ok THEN Fail ELSE
    LET tradeCancelorCorrectV2ReturnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadBytes(tradeCancelorCorrectV2ReturnBitfield5.rest, 1), tradeCancelorCorrectV2ReturnBitfield5.rest) IN IF ~tradeCancelorCorrectV2ReturnBitfield6.ok THEN Fail ELSE
    LET tradeCancelorCorrectV2ReturnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadUIntLE(tradeCancelorCorrectV2ReturnBitfield6.rest, 1), tradeCancelorCorrectV2ReturnBitfield6.rest) IN IF ~tradeCancelorCorrectV2ReturnBitfield7.ok THEN Fail ELSE
    LET tradeCancelorCorrectV2ReturnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadBytes(tradeCancelorCorrectV2ReturnBitfield7.rest, 1), tradeCancelorCorrectV2ReturnBitfield7.rest) IN IF ~tradeCancelorCorrectV2ReturnBitfield8.ok THEN Fail ELSE
    LET tradeCancelorCorrectV2ReturnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadUIntLE(tradeCancelorCorrectV2ReturnBitfield8.rest, 1), tradeCancelorCorrectV2ReturnBitfield8.rest) IN IF ~tradeCancelorCorrectV2ReturnBitfield9.ok THEN Fail ELSE
    LET tradeCancelorCorrectV2ReturnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadUIntLE(tradeCancelorCorrectV2ReturnBitfield9.rest, 1), tradeCancelorCorrectV2ReturnBitfield9.rest) IN IF ~tradeCancelorCorrectV2ReturnBitfield10.ok THEN Fail ELSE
    LET tradeCancelorCorrectV2ReturnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadUIntLE(tradeCancelorCorrectV2ReturnBitfield10.rest, 1), tradeCancelorCorrectV2ReturnBitfield10.rest) IN IF ~tradeCancelorCorrectV2ReturnBitfield11.ok THEN Fail ELSE
    LET tradeCancelorCorrectV2ReturnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadBytes(tradeCancelorCorrectV2ReturnBitfield11.rest, 1), tradeCancelorCorrectV2ReturnBitfield11.rest) IN IF ~tradeCancelorCorrectV2ReturnBitfield12.ok THEN Fail ELSE
    LET tradeCancelorCorrectV2ReturnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(tradeCancelorCorrectV2ReturnBitfield12.rest, 1), tradeCancelorCorrectV2ReturnBitfield12.rest) IN IF ~tradeCancelorCorrectV2ReturnBitfield13.ok THEN Fail ELSE
    LET tradeCancelorCorrectV2ReturnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(tradeCancelorCorrectV2ReturnBitfield13.rest, 1), tradeCancelorCorrectV2ReturnBitfield13.rest) IN IF ~tradeCancelorCorrectV2ReturnBitfield14.ok THEN Fail ELSE
    LET symbol == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (tradeCancelorCorrectV2ReturnBitfield2.value # << >> /\ tradeCancelorCorrectV2ReturnBitfield2.value[1] % 2 > 0), ReadBytes(tradeCancelorCorrectV2ReturnBitfield14.rest, 8), tradeCancelorCorrectV2ReturnBitfield14.rest) IN IF ~symbol.ok THEN Fail ELSE
    LET currency == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (tradeCancelorCorrectV2ReturnBitfield2.value # << >> /\ (tradeCancelorCorrectV2ReturnBitfield2.value[1] \div 4) % 2 > 0), ReadBytes(symbol.rest, 3), symbol.rest) IN IF ~currency.ok THEN Fail ELSE
    LET idSource == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (tradeCancelorCorrectV2ReturnBitfield2.value # << >> /\ (tradeCancelorCorrectV2ReturnBitfield2.value[1] \div 8) % 2 > 0), ReadBytes(currency.rest, 1), currency.rest) IN IF ~idSource.ok THEN Fail ELSE
    LET securityId == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (tradeCancelorCorrectV2ReturnBitfield2.value # << >> /\ (tradeCancelorCorrectV2ReturnBitfield2.value[1] \div 16) % 2 > 0), ReadBytes(idSource.rest, 16), idSource.rest) IN IF ~securityId.ok THEN Fail ELSE
    LET securityExchange == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (tradeCancelorCorrectV2ReturnBitfield2.value # << >> /\ (tradeCancelorCorrectV2ReturnBitfield2.value[1] \div 32) % 2 > 0), ReadBytes(securityId.rest, 4), securityId.rest) IN IF ~securityExchange.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (tradeCancelorCorrectV2ReturnBitfield2.value # << >> /\ (tradeCancelorCorrectV2ReturnBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(securityExchange.rest, 1), securityExchange.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET correctedSize == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (tradeCancelorCorrectV2ReturnBitfield4.value # << >> /\ (tradeCancelorCorrectV2ReturnBitfield4.value[1] \div 32) % 2 > 0), ReadBytes(capacity.rest, 4), capacity.rest) IN IF ~correctedSize.ok THEN Fail ELSE
    LET tradeReportTypeReturn == ReadWhen(numberOfReturnBitfields.value >= 7 /\ (tradeCancelorCorrectV2ReturnBitfield7.value # << >> /\ (tradeCancelorCorrectV2ReturnBitfield7.value[1] \div 2) % 2 > 0), ReadBytes(correctedSize.rest, 2), correctedSize.rest) IN IF ~tradeReportTypeReturn.ok THEN Fail ELSE
    LET tradePublishIndicator == ReadWhen(numberOfReturnBitfields.value >= 7 /\ (tradeCancelorCorrectV2ReturnBitfield7.value # << >> /\ (tradeCancelorCorrectV2ReturnBitfield7.value[1] \div 4) % 2 > 0), ReadBytes(tradeReportTypeReturn.rest, 1), tradeReportTypeReturn.rest) IN IF ~tradePublishIndicator.ok THEN Fail ELSE
    LET rptTime == ReadWhen(numberOfReturnBitfields.value >= 7 /\ (tradeCancelorCorrectV2ReturnBitfield7.value # << >> /\ (tradeCancelorCorrectV2ReturnBitfield7.value[1] \div 4) % 2 > 0), ReadBytes(tradePublishIndicator.rest, 8), tradePublishIndicator.rest) IN IF ~rptTime.ok THEN Fail ELSE
    LET text == ReadWhen(numberOfReturnBitfields.value >= 7 /\ (tradeCancelorCorrectV2ReturnBitfield7.value # << >> /\ (tradeCancelorCorrectV2ReturnBitfield7.value[1] \div 8) % 2 > 0), ReadBytes(rptTime.rest, 60), rptTime.rest) IN IF ~text.ok THEN Fail ELSE
    LET bidPx == ReadWhen(numberOfReturnBitfields.value >= 7 /\ (tradeCancelorCorrectV2ReturnBitfield7.value # << >> /\ (tradeCancelorCorrectV2ReturnBitfield7.value[1] \div 16) % 2 > 0), ReadBytes(text.rest, 8), text.rest) IN IF ~bidPx.ok THEN Fail ELSE
    LET bidSize == ReadWhen(numberOfReturnBitfields.value >= 7 /\ (tradeCancelorCorrectV2ReturnBitfield7.value # << >> /\ (tradeCancelorCorrectV2ReturnBitfield7.value[1] \div 16) % 2 > 0), ReadBytes(bidPx.rest, 4), bidPx.rest) IN IF ~bidSize.ok THEN Fail ELSE
    LET offerPx == ReadWhen(numberOfReturnBitfields.value >= 7 /\ (tradeCancelorCorrectV2ReturnBitfield7.value # << >> /\ (tradeCancelorCorrectV2ReturnBitfield7.value[1] \div 32) % 2 > 0), ReadBytes(bidSize.rest, 8), bidSize.rest) IN IF ~offerPx.ok THEN Fail ELSE
    LET offerSize == ReadWhen(numberOfReturnBitfields.value >= 7 /\ (tradeCancelorCorrectV2ReturnBitfield7.value # << >> /\ (tradeCancelorCorrectV2ReturnBitfield7.value[1] \div 32) % 2 > 0), ReadBytes(offerPx.rest, 4), offerPx.rest) IN IF ~offerSize.ok THEN Fail ELSE
    LET largeSize == ReadWhen(numberOfReturnBitfields.value >= 7 /\ (tradeCancelorCorrectV2ReturnBitfield7.value # << >> /\ (tradeCancelorCorrectV2ReturnBitfield7.value[1] \div 64) % 2 > 0), ReadBytes(offerSize.rest, 8), offerSize.rest) IN IF ~largeSize.ok THEN Fail ELSE
    LET lastMkt == ReadWhen(numberOfReturnBitfields.value >= 7 /\ (tradeCancelorCorrectV2ReturnBitfield7.value # << >> /\ (tradeCancelorCorrectV2ReturnBitfield7.value[1] \div 128) % 2 > 0), ReadBytes(largeSize.rest, 4), largeSize.rest) IN IF ~lastMkt.ok THEN Fail ELSE
    LET liquidityProvision == ReadWhen(numberOfReturnBitfields.value >= 9 /\ (tradeCancelorCorrectV2ReturnBitfield9.value # << >> /\ (tradeCancelorCorrectV2ReturnBitfield9.value[1] \div 16) % 2 > 0), ReadBytes(lastMkt.rest, 1), lastMkt.rest) IN IF ~liquidityProvision.ok THEN Fail ELSE
    LET priceFormation == ReadWhen(numberOfReturnBitfields.value >= 10 /\ (tradeCancelorCorrectV2ReturnBitfield10.value # << >> /\ (tradeCancelorCorrectV2ReturnBitfield10.value[1] \div 64) % 2 > 0), ReadBytes(liquidityProvision.rest, 1), liquidityProvision.rest) IN IF ~priceFormation.ok THEN Fail ELSE
    LET clientQualifiedRole == ReadWhen(numberOfReturnBitfields.value >= 10 /\ (tradeCancelorCorrectV2ReturnBitfield10.value # << >> /\ (tradeCancelorCorrectV2ReturnBitfield10.value[1] \div 128) % 2 > 0), ReadBytes(priceFormation.rest, 1), priceFormation.rest) IN IF ~clientQualifiedRole.ok THEN Fail ELSE
    LET clientId == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (tradeCancelorCorrectV2ReturnBitfield11.value # << >> /\ tradeCancelorCorrectV2ReturnBitfield11.value[1] % 2 > 0), ReadBytes(clientQualifiedRole.rest, 4), clientQualifiedRole.rest) IN IF ~clientId.ok THEN Fail ELSE
    LET investorId == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (tradeCancelorCorrectV2ReturnBitfield11.value # << >> /\ (tradeCancelorCorrectV2ReturnBitfield11.value[1] \div 2) % 2 > 0), ReadBytes(clientId.rest, 4), clientId.rest) IN IF ~investorId.ok THEN Fail ELSE
    LET executorId == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (tradeCancelorCorrectV2ReturnBitfield11.value # << >> /\ (tradeCancelorCorrectV2ReturnBitfield11.value[1] \div 4) % 2 > 0), ReadBytes(investorId.rest, 4), investorId.rest) IN IF ~executorId.ok THEN Fail ELSE
    LET orderOrigination == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (tradeCancelorCorrectV2ReturnBitfield11.value # << >> /\ (tradeCancelorCorrectV2ReturnBitfield11.value[1] \div 8) % 2 > 0), ReadBytes(executorId.rest, 1), executorId.rest) IN IF ~orderOrigination.ok THEN Fail ELSE
    LET algorithmicIndicator == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (tradeCancelorCorrectV2ReturnBitfield11.value # << >> /\ (tradeCancelorCorrectV2ReturnBitfield11.value[1] \div 16) % 2 > 0), ReadBytes(orderOrigination.rest, 1), orderOrigination.rest) IN IF ~algorithmicIndicator.ok THEN Fail ELSE
    LET investorQualifiedRole == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (tradeCancelorCorrectV2ReturnBitfield11.value # << >> /\ (tradeCancelorCorrectV2ReturnBitfield11.value[1] \div 64) % 2 > 0), ReadBytes(algorithmicIndicator.rest, 1), algorithmicIndicator.rest) IN IF ~investorQualifiedRole.ok THEN Fail ELSE
    LET executorQualifiedRole == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (tradeCancelorCorrectV2ReturnBitfield11.value # << >> /\ (tradeCancelorCorrectV2ReturnBitfield11.value[1] \div 128) % 2 > 0), ReadBytes(investorQualifiedRole.rest, 1), investorQualifiedRole.rest) IN IF ~executorQualifiedRole.ok THEN Fail ELSE
    Ok([ transactionTime                        |-> transactionTime.value,
         clOrdId                                |-> clOrdId.value,
         orderId                                |-> orderId.value,
         execRefId                              |-> execRefId.value,
         side                                   |-> side.value,
         baseLiquidityIndicator                 |-> baseLiquidityIndicator.value,
         clearingFirm                           |-> clearingFirm.value,
         clearingAccount                        |-> clearingAccount.value,
         lastShares                             |-> lastShares.value,
         lastPx                                 |-> lastPx.value,
         correctedPrice                         |-> correctedPrice.value,
         origTime                               |-> origTime.value,
         reserved1                              |-> reserved1.value,
         numberOfReturnBitfields                |-> numberOfReturnBitfields.value,
         tradeCancelorCorrectV2ReturnBitfield1  |-> tradeCancelorCorrectV2ReturnBitfield1.value,
         tradeCancelorCorrectV2ReturnBitfield2  |-> tradeCancelorCorrectV2ReturnBitfield2.value,
         tradeCancelorCorrectV2ReturnBitfield3  |-> tradeCancelorCorrectV2ReturnBitfield3.value,
         tradeCancelorCorrectV2ReturnBitfield4  |-> tradeCancelorCorrectV2ReturnBitfield4.value,
         tradeCancelorCorrectV2ReturnBitfield5  |-> tradeCancelorCorrectV2ReturnBitfield5.value,
         tradeCancelorCorrectV2ReturnBitfield6  |-> tradeCancelorCorrectV2ReturnBitfield6.value,
         tradeCancelorCorrectV2ReturnBitfield7  |-> tradeCancelorCorrectV2ReturnBitfield7.value,
         tradeCancelorCorrectV2ReturnBitfield8  |-> tradeCancelorCorrectV2ReturnBitfield8.value,
         tradeCancelorCorrectV2ReturnBitfield9  |-> tradeCancelorCorrectV2ReturnBitfield9.value,
         tradeCancelorCorrectV2ReturnBitfield10 |-> tradeCancelorCorrectV2ReturnBitfield10.value,
         tradeCancelorCorrectV2ReturnBitfield11 |-> tradeCancelorCorrectV2ReturnBitfield11.value,
         tradeCancelorCorrectV2ReturnBitfield12 |-> tradeCancelorCorrectV2ReturnBitfield12.value,
         tradeCancelorCorrectV2ReturnBitfield13 |-> tradeCancelorCorrectV2ReturnBitfield13.value,
         tradeCancelorCorrectV2ReturnBitfield14 |-> tradeCancelorCorrectV2ReturnBitfield14.value,
         symbol                                 |-> symbol.value,
         currency                               |-> currency.value,
         idSource                               |-> idSource.value,
         securityId                             |-> securityId.value,
         securityExchange                       |-> securityExchange.value,
         capacity                               |-> capacity.value,
         correctedSize                          |-> correctedSize.value,
         tradeReportTypeReturn                  |-> tradeReportTypeReturn.value,
         tradePublishIndicator                  |-> tradePublishIndicator.value,
         rptTime                                |-> rptTime.value,
         text                                   |-> text.value,
         bidPx                                  |-> bidPx.value,
         bidSize                                |-> bidSize.value,
         offerPx                                |-> offerPx.value,
         offerSize                              |-> offerSize.value,
         largeSize                              |-> largeSize.value,
         lastMkt                                |-> lastMkt.value,
         liquidityProvision                     |-> liquidityProvision.value,
         priceFormation                         |-> priceFormation.value,
         clientQualifiedRole                    |-> clientQualifiedRole.value,
         clientId                               |-> clientId.value,
         investorId                             |-> investorId.value,
         executorId                             |-> executorId.value,
         orderOrigination                       |-> orderOrigination.value,
         algorithmicIndicator                   |-> algorithmicIndicator.value,
         investorQualifiedRole                  |-> investorQualifiedRole.value,
         executorQualifiedRole                  |-> executorQualifiedRole.value ], executorQualifiedRole.rest)

(* Trade Cancel Or Correct V 2 Message with each field marked present by fields before it there exactly where they say *)
SettleTradeCancelOrCorrectV2Message(message) ==
    LET settled1 == [message EXCEPT !.tradeCancelorCorrectV2ReturnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.tradeCancelorCorrectV2ReturnBitfield1 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE message.tradeCancelorCorrectV2ReturnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.tradeCancelorCorrectV2ReturnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.tradeCancelorCorrectV2ReturnBitfield2 = << >> THEN <<0>> ELSE settled1.tradeCancelorCorrectV2ReturnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.tradeCancelorCorrectV2ReturnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.tradeCancelorCorrectV2ReturnBitfield3 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled2.tradeCancelorCorrectV2ReturnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.tradeCancelorCorrectV2ReturnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.tradeCancelorCorrectV2ReturnBitfield4 = << >> THEN <<0>> ELSE settled3.tradeCancelorCorrectV2ReturnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.tradeCancelorCorrectV2ReturnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.tradeCancelorCorrectV2ReturnBitfield5 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled4.tradeCancelorCorrectV2ReturnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.tradeCancelorCorrectV2ReturnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.tradeCancelorCorrectV2ReturnBitfield6 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled5.tradeCancelorCorrectV2ReturnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.tradeCancelorCorrectV2ReturnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.tradeCancelorCorrectV2ReturnBitfield7 = << >> THEN <<0>> ELSE settled6.tradeCancelorCorrectV2ReturnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.tradeCancelorCorrectV2ReturnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.tradeCancelorCorrectV2ReturnBitfield8 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled7.tradeCancelorCorrectV2ReturnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.tradeCancelorCorrectV2ReturnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.tradeCancelorCorrectV2ReturnBitfield9 = << >> THEN <<0>> ELSE settled8.tradeCancelorCorrectV2ReturnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.tradeCancelorCorrectV2ReturnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.tradeCancelorCorrectV2ReturnBitfield10 = << >> THEN <<0>> ELSE settled9.tradeCancelorCorrectV2ReturnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.tradeCancelorCorrectV2ReturnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.tradeCancelorCorrectV2ReturnBitfield11 = << >> THEN <<0>> ELSE settled10.tradeCancelorCorrectV2ReturnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.tradeCancelorCorrectV2ReturnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.tradeCancelorCorrectV2ReturnBitfield12 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.tradeCancelorCorrectV2ReturnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.tradeCancelorCorrectV2ReturnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.tradeCancelorCorrectV2ReturnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.tradeCancelorCorrectV2ReturnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.tradeCancelorCorrectV2ReturnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.tradeCancelorCorrectV2ReturnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.tradeCancelorCorrectV2ReturnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.symbol = IF settled14.numberOfReturnBitfields >= 2 /\ (settled14.tradeCancelorCorrectV2ReturnBitfield2 # << >> /\ settled14.tradeCancelorCorrectV2ReturnBitfield2[1] % 2 > 0) THEN (IF settled14.symbol = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled14.symbol) ELSE << >>]
        settled16 == [settled15 EXCEPT !.currency = IF settled15.numberOfReturnBitfields >= 2 /\ (settled15.tradeCancelorCorrectV2ReturnBitfield2 # << >> /\ (settled15.tradeCancelorCorrectV2ReturnBitfield2[1] \div 4) % 2 > 0) THEN (IF settled15.currency = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled15.currency) ELSE << >>]
        settled17 == [settled16 EXCEPT !.idSource = IF settled16.numberOfReturnBitfields >= 2 /\ (settled16.tradeCancelorCorrectV2ReturnBitfield2 # << >> /\ (settled16.tradeCancelorCorrectV2ReturnBitfield2[1] \div 8) % 2 > 0) THEN (IF settled16.idSource = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled16.idSource) ELSE << >>]
        settled18 == [settled17 EXCEPT !.securityId = IF settled17.numberOfReturnBitfields >= 2 /\ (settled17.tradeCancelorCorrectV2ReturnBitfield2 # << >> /\ (settled17.tradeCancelorCorrectV2ReturnBitfield2[1] \div 16) % 2 > 0) THEN (IF settled17.securityId = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled17.securityId) ELSE << >>]
        settled19 == [settled18 EXCEPT !.securityExchange = IF settled18.numberOfReturnBitfields >= 2 /\ (settled18.tradeCancelorCorrectV2ReturnBitfield2 # << >> /\ (settled18.tradeCancelorCorrectV2ReturnBitfield2[1] \div 32) % 2 > 0) THEN (IF settled18.securityExchange = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled18.securityExchange) ELSE << >>]
        settled20 == [settled19 EXCEPT !.capacity = IF settled19.numberOfReturnBitfields >= 2 /\ (settled19.tradeCancelorCorrectV2ReturnBitfield2 # << >> /\ (settled19.tradeCancelorCorrectV2ReturnBitfield2[1] \div 64) % 2 > 0) THEN (IF settled19.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled19.capacity) ELSE << >>]
        settled21 == [settled20 EXCEPT !.correctedSize = IF settled20.numberOfReturnBitfields >= 4 /\ (settled20.tradeCancelorCorrectV2ReturnBitfield4 # << >> /\ (settled20.tradeCancelorCorrectV2ReturnBitfield4[1] \div 32) % 2 > 0) THEN (IF settled20.correctedSize = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled20.correctedSize) ELSE << >>]
        settled22 == [settled21 EXCEPT !.tradeReportTypeReturn = IF settled21.numberOfReturnBitfields >= 7 /\ (settled21.tradeCancelorCorrectV2ReturnBitfield7 # << >> /\ (settled21.tradeCancelorCorrectV2ReturnBitfield7[1] \div 2) % 2 > 0) THEN (IF settled21.tradeReportTypeReturn = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled21.tradeReportTypeReturn) ELSE << >>]
        settled23 == [settled22 EXCEPT !.tradePublishIndicator = IF settled22.numberOfReturnBitfields >= 7 /\ (settled22.tradeCancelorCorrectV2ReturnBitfield7 # << >> /\ (settled22.tradeCancelorCorrectV2ReturnBitfield7[1] \div 4) % 2 > 0) THEN (IF settled22.tradePublishIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled22.tradePublishIndicator) ELSE << >>]
        settled24 == [settled23 EXCEPT !.rptTime = IF settled23.numberOfReturnBitfields >= 7 /\ (settled23.tradeCancelorCorrectV2ReturnBitfield7 # << >> /\ (settled23.tradeCancelorCorrectV2ReturnBitfield7[1] \div 4) % 2 > 0) THEN (IF settled23.rptTime = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled23.rptTime) ELSE << >>]
        settled25 == [settled24 EXCEPT !.text = IF settled24.numberOfReturnBitfields >= 7 /\ (settled24.tradeCancelorCorrectV2ReturnBitfield7 # << >> /\ (settled24.tradeCancelorCorrectV2ReturnBitfield7[1] \div 8) % 2 > 0) THEN (IF settled24.text = << >> THEN <<[i \in 1 .. 60 |-> 0]>> ELSE settled24.text) ELSE << >>]
        settled26 == [settled25 EXCEPT !.bidPx = IF settled25.numberOfReturnBitfields >= 7 /\ (settled25.tradeCancelorCorrectV2ReturnBitfield7 # << >> /\ (settled25.tradeCancelorCorrectV2ReturnBitfield7[1] \div 16) % 2 > 0) THEN (IF settled25.bidPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled25.bidPx) ELSE << >>]
        settled27 == [settled26 EXCEPT !.bidSize = IF settled26.numberOfReturnBitfields >= 7 /\ (settled26.tradeCancelorCorrectV2ReturnBitfield7 # << >> /\ (settled26.tradeCancelorCorrectV2ReturnBitfield7[1] \div 16) % 2 > 0) THEN (IF settled26.bidSize = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled26.bidSize) ELSE << >>]
        settled28 == [settled27 EXCEPT !.offerPx = IF settled27.numberOfReturnBitfields >= 7 /\ (settled27.tradeCancelorCorrectV2ReturnBitfield7 # << >> /\ (settled27.tradeCancelorCorrectV2ReturnBitfield7[1] \div 32) % 2 > 0) THEN (IF settled27.offerPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled27.offerPx) ELSE << >>]
        settled29 == [settled28 EXCEPT !.offerSize = IF settled28.numberOfReturnBitfields >= 7 /\ (settled28.tradeCancelorCorrectV2ReturnBitfield7 # << >> /\ (settled28.tradeCancelorCorrectV2ReturnBitfield7[1] \div 32) % 2 > 0) THEN (IF settled28.offerSize = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled28.offerSize) ELSE << >>]
        settled30 == [settled29 EXCEPT !.largeSize = IF settled29.numberOfReturnBitfields >= 7 /\ (settled29.tradeCancelorCorrectV2ReturnBitfield7 # << >> /\ (settled29.tradeCancelorCorrectV2ReturnBitfield7[1] \div 64) % 2 > 0) THEN (IF settled29.largeSize = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled29.largeSize) ELSE << >>]
        settled31 == [settled30 EXCEPT !.lastMkt = IF settled30.numberOfReturnBitfields >= 7 /\ (settled30.tradeCancelorCorrectV2ReturnBitfield7 # << >> /\ (settled30.tradeCancelorCorrectV2ReturnBitfield7[1] \div 128) % 2 > 0) THEN (IF settled30.lastMkt = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled30.lastMkt) ELSE << >>]
        settled32 == [settled31 EXCEPT !.liquidityProvision = IF settled31.numberOfReturnBitfields >= 9 /\ (settled31.tradeCancelorCorrectV2ReturnBitfield9 # << >> /\ (settled31.tradeCancelorCorrectV2ReturnBitfield9[1] \div 16) % 2 > 0) THEN (IF settled31.liquidityProvision = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled31.liquidityProvision) ELSE << >>]
        settled33 == [settled32 EXCEPT !.priceFormation = IF settled32.numberOfReturnBitfields >= 10 /\ (settled32.tradeCancelorCorrectV2ReturnBitfield10 # << >> /\ (settled32.tradeCancelorCorrectV2ReturnBitfield10[1] \div 64) % 2 > 0) THEN (IF settled32.priceFormation = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled32.priceFormation) ELSE << >>]
        settled34 == [settled33 EXCEPT !.clientQualifiedRole = IF settled33.numberOfReturnBitfields >= 10 /\ (settled33.tradeCancelorCorrectV2ReturnBitfield10 # << >> /\ (settled33.tradeCancelorCorrectV2ReturnBitfield10[1] \div 128) % 2 > 0) THEN (IF settled33.clientQualifiedRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled33.clientQualifiedRole) ELSE << >>]
        settled35 == [settled34 EXCEPT !.clientId = IF settled34.numberOfReturnBitfields >= 11 /\ (settled34.tradeCancelorCorrectV2ReturnBitfield11 # << >> /\ settled34.tradeCancelorCorrectV2ReturnBitfield11[1] % 2 > 0) THEN (IF settled34.clientId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled34.clientId) ELSE << >>]
        settled36 == [settled35 EXCEPT !.investorId = IF settled35.numberOfReturnBitfields >= 11 /\ (settled35.tradeCancelorCorrectV2ReturnBitfield11 # << >> /\ (settled35.tradeCancelorCorrectV2ReturnBitfield11[1] \div 2) % 2 > 0) THEN (IF settled35.investorId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled35.investorId) ELSE << >>]
        settled37 == [settled36 EXCEPT !.executorId = IF settled36.numberOfReturnBitfields >= 11 /\ (settled36.tradeCancelorCorrectV2ReturnBitfield11 # << >> /\ (settled36.tradeCancelorCorrectV2ReturnBitfield11[1] \div 4) % 2 > 0) THEN (IF settled36.executorId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled36.executorId) ELSE << >>]
        settled38 == [settled37 EXCEPT !.orderOrigination = IF settled37.numberOfReturnBitfields >= 11 /\ (settled37.tradeCancelorCorrectV2ReturnBitfield11 # << >> /\ (settled37.tradeCancelorCorrectV2ReturnBitfield11[1] \div 8) % 2 > 0) THEN (IF settled37.orderOrigination = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled37.orderOrigination) ELSE << >>]
        settled39 == [settled38 EXCEPT !.algorithmicIndicator = IF settled38.numberOfReturnBitfields >= 11 /\ (settled38.tradeCancelorCorrectV2ReturnBitfield11 # << >> /\ (settled38.tradeCancelorCorrectV2ReturnBitfield11[1] \div 16) % 2 > 0) THEN (IF settled38.algorithmicIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled38.algorithmicIndicator) ELSE << >>]
        settled40 == [settled39 EXCEPT !.investorQualifiedRole = IF settled39.numberOfReturnBitfields >= 11 /\ (settled39.tradeCancelorCorrectV2ReturnBitfield11 # << >> /\ (settled39.tradeCancelorCorrectV2ReturnBitfield11[1] \div 64) % 2 > 0) THEN (IF settled39.investorQualifiedRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled39.investorQualifiedRole) ELSE << >>]
        settled41 == [settled40 EXCEPT !.executorQualifiedRole = IF settled40.numberOfReturnBitfields >= 11 /\ (settled40.tradeCancelorCorrectV2ReturnBitfield11 # << >> /\ (settled40.tradeCancelorCorrectV2ReturnBitfield11[1] \div 128) % 2 > 0) THEN (IF settled40.executorQualifiedRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled40.executorQualifiedRole) ELSE << >>]
    IN  settled41

ZeroTradeCancelOrCorrectV2Message ==
    SettleTradeCancelOrCorrectV2Message([ transactionTime                        |-> [i \in 1 .. 8 |-> 0],
                                          clOrdId                                |-> [i \in 1 .. 20 |-> 0],
                                          orderId                                |-> [i \in 1 .. 8 |-> 0],
                                          execRefId                              |-> [i \in 1 .. 8 |-> 0],
                                          side                                   |-> [i \in 1 .. 1 |-> 0],
                                          baseLiquidityIndicator                 |-> [i \in 1 .. 1 |-> 0],
                                          clearingFirm                           |-> [i \in 1 .. 4 |-> 0],
                                          clearingAccount                        |-> [i \in 1 .. 4 |-> 0],
                                          lastShares                             |-> [i \in 1 .. 4 |-> 0],
                                          lastPx                                 |-> [i \in 1 .. 8 |-> 0],
                                          correctedPrice                         |-> [i \in 1 .. 8 |-> 0],
                                          origTime                               |-> [i \in 1 .. 8 |-> 0],
                                          reserved1                              |-> [i \in 1 .. 1 |-> 0],
                                          numberOfReturnBitfields                |-> 0,
                                          tradeCancelorCorrectV2ReturnBitfield1  |-> << >>,
                                          tradeCancelorCorrectV2ReturnBitfield2  |-> << >>,
                                          tradeCancelorCorrectV2ReturnBitfield3  |-> << >>,
                                          tradeCancelorCorrectV2ReturnBitfield4  |-> << >>,
                                          tradeCancelorCorrectV2ReturnBitfield5  |-> << >>,
                                          tradeCancelorCorrectV2ReturnBitfield6  |-> << >>,
                                          tradeCancelorCorrectV2ReturnBitfield7  |-> << >>,
                                          tradeCancelorCorrectV2ReturnBitfield8  |-> << >>,
                                          tradeCancelorCorrectV2ReturnBitfield9  |-> << >>,
                                          tradeCancelorCorrectV2ReturnBitfield10 |-> << >>,
                                          tradeCancelorCorrectV2ReturnBitfield11 |-> << >>,
                                          tradeCancelorCorrectV2ReturnBitfield12 |-> << >>,
                                          tradeCancelorCorrectV2ReturnBitfield13 |-> << >>,
                                          tradeCancelorCorrectV2ReturnBitfield14 |-> << >>,
                                          symbol                                 |-> << >>,
                                          currency                               |-> << >>,
                                          idSource                               |-> << >>,
                                          securityId                             |-> << >>,
                                          securityExchange                       |-> << >>,
                                          capacity                               |-> << >>,
                                          correctedSize                          |-> << >>,
                                          tradeReportTypeReturn                  |-> << >>,
                                          tradePublishIndicator                  |-> << >>,
                                          rptTime                                |-> << >>,
                                          text                                   |-> << >>,
                                          bidPx                                  |-> << >>,
                                          bidSize                                |-> << >>,
                                          offerPx                                |-> << >>,
                                          offerSize                              |-> << >>,
                                          largeSize                              |-> << >>,
                                          lastMkt                                |-> << >>,
                                          liquidityProvision                     |-> << >>,
                                          priceFormation                         |-> << >>,
                                          clientQualifiedRole                    |-> << >>,
                                          clientId                               |-> << >>,
                                          investorId                             |-> << >>,
                                          executorId                             |-> << >>,
                                          orderOrigination                       |-> << >>,
                                          algorithmicIndicator                   |-> << >>,
                                          investorQualifiedRole                  |-> << >>,
                                          executorQualifiedRole                  |-> << >> ])

(* Trade Cancel Or Correct V 2 Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCancelOrCorrectV2Message ==
    { ZeroTradeCancelOrCorrectV2Message }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.transactionTime = one]) : one \in Sample(8) }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.clOrdId = one]) : one \in Sample(20) }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.orderId = one]) : one \in Sample(8) }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.execRefId = one]) : one \in Sample(8) }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.side = one]) : one \in Sample(1) }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.baseLiquidityIndicator = one]) : one \in Sample(1) }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.clearingFirm = one]) : one \in Sample(4) }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.clearingAccount = one]) : one \in Sample(4) }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.lastShares = one]) : one \in Sample(4) }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.lastPx = one]) : one \in Sample(8) }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.correctedPrice = one]) : one \in Sample(8) }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.origTime = one]) : one \in Sample(8) }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.reserved1 = one]) : one \in Sample(1) }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.numberOfReturnBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.numberOfReturnBitfields = 1, !.tradeCancelorCorrectV2ReturnBitfield1 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.numberOfReturnBitfields = 2, !.tradeCancelorCorrectV2ReturnBitfield2 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.numberOfReturnBitfields = 3, !.tradeCancelorCorrectV2ReturnBitfield3 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.numberOfReturnBitfields = 4, !.tradeCancelorCorrectV2ReturnBitfield4 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.numberOfReturnBitfields = 5, !.tradeCancelorCorrectV2ReturnBitfield5 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.numberOfReturnBitfields = 6, !.tradeCancelorCorrectV2ReturnBitfield6 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.numberOfReturnBitfields = 7, !.tradeCancelorCorrectV2ReturnBitfield7 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.numberOfReturnBitfields = 8, !.tradeCancelorCorrectV2ReturnBitfield8 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.numberOfReturnBitfields = 9, !.tradeCancelorCorrectV2ReturnBitfield9 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.numberOfReturnBitfields = 10, !.tradeCancelorCorrectV2ReturnBitfield10 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.numberOfReturnBitfields = 11, !.tradeCancelorCorrectV2ReturnBitfield11 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.numberOfReturnBitfields = 12, !.tradeCancelorCorrectV2ReturnBitfield12 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.numberOfReturnBitfields = 13, !.tradeCancelorCorrectV2ReturnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.numberOfReturnBitfields = 14, !.tradeCancelorCorrectV2ReturnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.numberOfReturnBitfields = 2, !.tradeCancelorCorrectV2ReturnBitfield2 = <<1>>, !.symbol = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.numberOfReturnBitfields = 2, !.tradeCancelorCorrectV2ReturnBitfield2 = <<4>>, !.currency = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.numberOfReturnBitfields = 2, !.tradeCancelorCorrectV2ReturnBitfield2 = <<8>>, !.idSource = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.numberOfReturnBitfields = 2, !.tradeCancelorCorrectV2ReturnBitfield2 = <<16>>, !.securityId = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.numberOfReturnBitfields = 2, !.tradeCancelorCorrectV2ReturnBitfield2 = <<32>>, !.securityExchange = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.numberOfReturnBitfields = 2, !.tradeCancelorCorrectV2ReturnBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.numberOfReturnBitfields = 4, !.tradeCancelorCorrectV2ReturnBitfield4 = <<32>>, !.correctedSize = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.numberOfReturnBitfields = 7, !.tradeCancelorCorrectV2ReturnBitfield7 = <<2>>, !.tradeReportTypeReturn = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.numberOfReturnBitfields = 7, !.tradeCancelorCorrectV2ReturnBitfield7 = <<4>>, !.tradePublishIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.numberOfReturnBitfields = 7, !.tradeCancelorCorrectV2ReturnBitfield7 = <<4>>, !.rptTime = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.numberOfReturnBitfields = 7, !.tradeCancelorCorrectV2ReturnBitfield7 = <<8>>, !.text = one]) : one \in { <<held>> : held \in Sample(60) } }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.numberOfReturnBitfields = 7, !.tradeCancelorCorrectV2ReturnBitfield7 = <<16>>, !.bidPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.numberOfReturnBitfields = 7, !.tradeCancelorCorrectV2ReturnBitfield7 = <<16>>, !.bidSize = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.numberOfReturnBitfields = 7, !.tradeCancelorCorrectV2ReturnBitfield7 = <<32>>, !.offerPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.numberOfReturnBitfields = 7, !.tradeCancelorCorrectV2ReturnBitfield7 = <<32>>, !.offerSize = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.numberOfReturnBitfields = 7, !.tradeCancelorCorrectV2ReturnBitfield7 = <<64>>, !.largeSize = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.numberOfReturnBitfields = 7, !.tradeCancelorCorrectV2ReturnBitfield7 = <<128>>, !.lastMkt = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.numberOfReturnBitfields = 9, !.tradeCancelorCorrectV2ReturnBitfield9 = <<16>>, !.liquidityProvision = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.numberOfReturnBitfields = 10, !.tradeCancelorCorrectV2ReturnBitfield10 = <<64>>, !.priceFormation = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.numberOfReturnBitfields = 10, !.tradeCancelorCorrectV2ReturnBitfield10 = <<128>>, !.clientQualifiedRole = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.numberOfReturnBitfields = 11, !.tradeCancelorCorrectV2ReturnBitfield11 = <<1>>, !.clientId = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.numberOfReturnBitfields = 11, !.tradeCancelorCorrectV2ReturnBitfield11 = <<2>>, !.investorId = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.numberOfReturnBitfields = 11, !.tradeCancelorCorrectV2ReturnBitfield11 = <<4>>, !.executorId = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.numberOfReturnBitfields = 11, !.tradeCancelorCorrectV2ReturnBitfield11 = <<8>>, !.orderOrigination = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.numberOfReturnBitfields = 11, !.tradeCancelorCorrectV2ReturnBitfield11 = <<16>>, !.algorithmicIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.numberOfReturnBitfields = 11, !.tradeCancelorCorrectV2ReturnBitfield11 = <<64>>, !.investorQualifiedRole = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectV2Message([ZeroTradeCancelOrCorrectV2Message EXCEPT !.numberOfReturnBitfields = 11, !.tradeCancelorCorrectV2ReturnBitfield11 = <<128>>, !.executorQualifiedRole = one]) : one \in { <<held>> : held \in Sample(1) } }

(***************************************************************************)
(* Trd Cap Ack Side Grp                                                    *)
(***************************************************************************)

TrdCapAckSideGrp ==
    [ side      : { << >> } \cup { <<held>> : held \in Sample(1) },
      capacity  : { << >> } \cup { <<held>> : held \in Sample(1) },
      account   : { << >> } \cup { <<held>> : held \in Sample(16) },
      partyId   : { << >> } \cup { <<held>> : held \in Sample(4) },
      partyRole : { << >> } \cup { <<held>> : held \in Sample(1) } ]

EncodeTrdCapAckSideGrp(message) ==
    (IF message.side = << >> THEN << >> ELSE message.side[1])
        \o (IF message.capacity = << >> THEN << >> ELSE message.capacity[1])
        \o (IF message.account = << >> THEN << >> ELSE message.account[1])
        \o (IF message.partyId = << >> THEN << >> ELSE message.partyId[1])
        \o (IF message.partyRole = << >> THEN << >> ELSE message.partyRole[1])

DecodeTrdCapAckSideGrp(bytes, handedNumberOfTradeCaptureReportAcknowledgmentV2Bitfields, handedTradeCaptureReportAcknowledgmentV2Bitfield1, handedTradeCaptureReportAcknowledgmentV2Bitfield2, handedTradeCaptureReportAcknowledgmentV2Bitfield3, handedTradeCaptureReportAcknowledgmentV2Bitfield4, handedTradeCaptureReportAcknowledgmentV2Bitfield6) ==
    LET side == ReadWhen(handedNumberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 1 /\ (handedTradeCaptureReportAcknowledgmentV2Bitfield1 # << >> /\ handedTradeCaptureReportAcknowledgmentV2Bitfield1[1] % 2 > 0), ReadBytes(bytes, 1), bytes) IN IF ~side.ok THEN Fail ELSE
    LET capacity == ReadWhen(handedNumberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 2 /\ (handedTradeCaptureReportAcknowledgmentV2Bitfield2 # << >> /\ (handedTradeCaptureReportAcknowledgmentV2Bitfield2[1] \div 64) % 2 > 0), ReadBytes(side.rest, 1), side.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadWhen(handedNumberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 3 /\ (handedTradeCaptureReportAcknowledgmentV2Bitfield3 # << >> /\ handedTradeCaptureReportAcknowledgmentV2Bitfield3[1] % 2 > 0), ReadBytes(capacity.rest, 16), capacity.rest) IN IF ~account.ok THEN Fail ELSE
    LET partyId == ReadWhen(handedNumberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 4 /\ (handedTradeCaptureReportAcknowledgmentV2Bitfield4 # << >> /\ (handedTradeCaptureReportAcknowledgmentV2Bitfield4[1] \div 64) % 2 > 0), ReadBytes(account.rest, 4), account.rest) IN IF ~partyId.ok THEN Fail ELSE
    LET partyRole == ReadWhen(handedNumberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 6 /\ (handedTradeCaptureReportAcknowledgmentV2Bitfield6 # << >> /\ (handedTradeCaptureReportAcknowledgmentV2Bitfield6[1] \div 128) % 2 > 0), ReadBytes(partyId.rest, 1), partyId.rest) IN IF ~partyRole.ok THEN Fail ELSE
    Ok([ side      |-> side.value,
         capacity  |-> capacity.value,
         account   |-> account.value,
         partyId   |-> partyId.value,
         partyRole |-> partyRole.value ], partyRole.rest)

(* Trd Cap Ack Side Grp with each field marked present by fields before it there exactly where they say *)
SettleTrdCapAckSideGrp(message, handedNumberOfTradeCaptureReportAcknowledgmentV2Bitfields, handedTradeCaptureReportAcknowledgmentV2Bitfield1, handedTradeCaptureReportAcknowledgmentV2Bitfield2, handedTradeCaptureReportAcknowledgmentV2Bitfield3, handedTradeCaptureReportAcknowledgmentV2Bitfield4, handedTradeCaptureReportAcknowledgmentV2Bitfield6) ==
    LET settled1 == [message EXCEPT !.side = IF handedNumberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 1 /\ (handedTradeCaptureReportAcknowledgmentV2Bitfield1 # << >> /\ handedTradeCaptureReportAcknowledgmentV2Bitfield1[1] % 2 > 0) THEN (IF message.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE message.side) ELSE << >>]
        settled2 == [settled1 EXCEPT !.capacity = IF handedNumberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 2 /\ (handedTradeCaptureReportAcknowledgmentV2Bitfield2 # << >> /\ (handedTradeCaptureReportAcknowledgmentV2Bitfield2[1] \div 64) % 2 > 0) THEN (IF settled1.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled1.capacity) ELSE << >>]
        settled3 == [settled2 EXCEPT !.account = IF handedNumberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 3 /\ (handedTradeCaptureReportAcknowledgmentV2Bitfield3 # << >> /\ handedTradeCaptureReportAcknowledgmentV2Bitfield3[1] % 2 > 0) THEN (IF settled2.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled2.account) ELSE << >>]
        settled4 == [settled3 EXCEPT !.partyId = IF handedNumberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 4 /\ (handedTradeCaptureReportAcknowledgmentV2Bitfield4 # << >> /\ (handedTradeCaptureReportAcknowledgmentV2Bitfield4[1] \div 64) % 2 > 0) THEN (IF settled3.partyId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled3.partyId) ELSE << >>]
        settled5 == [settled4 EXCEPT !.partyRole = IF handedNumberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 6 /\ (handedTradeCaptureReportAcknowledgmentV2Bitfield6 # << >> /\ (handedTradeCaptureReportAcknowledgmentV2Bitfield6[1] \div 128) % 2 > 0) THEN (IF settled4.partyRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled4.partyRole) ELSE << >>]
    IN  settled5

ZeroTrdCapAckSideGrp ==
    SettleTrdCapAckSideGrp([ side      |-> << >>,
                             capacity  |-> << >>,
                             account   |-> << >>,
                             partyId   |-> << >>,
                             partyRole |-> << >> ], 0, << >>, << >>, << >>, << >>, << >>)

(* Trd Cap Ack Side Grp at zero, then each field in turn at the values it is checked at *)
CheckedTrdCapAckSideGrp ==
    { [given |-> <<0, << >>, << >>, << >>, << >>, << >>>>, message |-> ZeroTrdCapAckSideGrp] }
        \cup { [given |-> <<1, <<1>>, << >>, << >>, << >>, << >>>>, message |-> SettleTrdCapAckSideGrp([ZeroTrdCapAckSideGrp EXCEPT !.side = one], 1, <<1>>, << >>, << >>, << >>, << >>)] : one \in { <<held>> : held \in Sample(1) } }
        \cup { [given |-> <<2, << >>, <<64>>, << >>, << >>, << >>>>, message |-> SettleTrdCapAckSideGrp([ZeroTrdCapAckSideGrp EXCEPT !.capacity = one], 2, << >>, <<64>>, << >>, << >>, << >>)] : one \in { <<held>> : held \in Sample(1) } }
        \cup { [given |-> <<3, << >>, << >>, <<1>>, << >>, << >>>>, message |-> SettleTrdCapAckSideGrp([ZeroTrdCapAckSideGrp EXCEPT !.account = one], 3, << >>, << >>, <<1>>, << >>, << >>)] : one \in { <<held>> : held \in Sample(16) } }
        \cup { [given |-> <<4, << >>, << >>, << >>, <<64>>, << >>>>, message |-> SettleTrdCapAckSideGrp([ZeroTrdCapAckSideGrp EXCEPT !.partyId = one], 4, << >>, << >>, << >>, <<64>>, << >>)] : one \in { <<held>> : held \in Sample(4) } }
        \cup { [given |-> <<6, << >>, << >>, << >>, << >>, <<128>>>>, message |-> SettleTrdCapAckSideGrp([ZeroTrdCapAckSideGrp EXCEPT !.partyRole = one], 6, << >>, << >>, << >>, << >>, <<128>>)] : one \in { <<held>> : held \in Sample(1) } }

(* A run of Trd Cap Ack Side Grp, written one after another *)
RECURSIVE EncodeTrdCapAckSideGrpList(_)
EncodeTrdCapAckSideGrpList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTrdCapAckSideGrp(Head(messages)) \o EncodeTrdCapAckSideGrpList(Tail(messages))

(* As many Trd Cap Ack Side Grp as the field that counts them says *)
RECURSIVE ReadTrdCapAckSideGrpList(_, _, _, _, _, _, _, _)
ReadTrdCapAckSideGrpList(bytes, count, handedNumberOfTradeCaptureReportAcknowledgmentV2Bitfields, handedTradeCaptureReportAcknowledgmentV2Bitfield1, handedTradeCaptureReportAcknowledgmentV2Bitfield2, handedTradeCaptureReportAcknowledgmentV2Bitfield3, handedTradeCaptureReportAcknowledgmentV2Bitfield4, handedTradeCaptureReportAcknowledgmentV2Bitfield6) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeTrdCapAckSideGrp(bytes, handedNumberOfTradeCaptureReportAcknowledgmentV2Bitfields, handedTradeCaptureReportAcknowledgmentV2Bitfield1, handedTradeCaptureReportAcknowledgmentV2Bitfield2, handedTradeCaptureReportAcknowledgmentV2Bitfield3, handedTradeCaptureReportAcknowledgmentV2Bitfield4, handedTradeCaptureReportAcknowledgmentV2Bitfield6)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTrdCapAckSideGrpList(one.rest, count - 1, handedNumberOfTradeCaptureReportAcknowledgmentV2Bitfields, handedTradeCaptureReportAcknowledgmentV2Bitfield1, handedTradeCaptureReportAcknowledgmentV2Bitfield2, handedTradeCaptureReportAcknowledgmentV2Bitfield3, handedTradeCaptureReportAcknowledgmentV2Bitfield4, handedTradeCaptureReportAcknowledgmentV2Bitfield6)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Trd Cap Ack Side Grp of each kind, for the lists that carry them *)
OneTrdCapAckSideGrp == { ZeroTrdCapAckSideGrp }

(***************************************************************************)
(* Trade Capture Report Acknowledgment V 2 Message                         *)
(***************************************************************************)

TradeCaptureReportAcknowledgmentV2Message ==
    [ transactionTime                                     : Sample(8),
      tradeReportId                                       : Sample(20),
      reserved1                                           : Sample(1),
      numberOfTradeCaptureReportAcknowledgmentV2Bitfields : 0 .. 255,
      tradeCaptureReportAcknowledgmentV2Bitfield1         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCaptureReportAcknowledgmentV2Bitfield2         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCaptureReportAcknowledgmentV2Bitfield3         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCaptureReportAcknowledgmentV2Bitfield4         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCaptureReportAcknowledgmentV2Bitfield5         : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCaptureReportAcknowledgmentV2Bitfield6         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCaptureReportAcknowledgmentV2Bitfield7         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCaptureReportAcknowledgmentV2Bitfield8         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCaptureReportAcknowledgmentV2Bitfield9         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCaptureReportAcknowledgmentV2Bitfield10        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCaptureReportAcknowledgmentV2Bitfield11        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCaptureReportAcknowledgmentV2Bitfield12        : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCaptureReportAcknowledgmentV2Bitfield13        : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCaptureReportAcknowledgmentV2Bitfield14        : { << >> } \cup { <<held>> : held \in Sample(1) },
      trdCapAckSideGrp                                    : SampleLists(OneTrdCapAckSideGrp),
      execInst                                            : { << >> } \cup { <<held>> : held \in Sample(1) },
      symbol                                              : { << >> } \cup { <<held>> : held \in Sample(8) },
      currency                                            : { << >> } \cup { <<held>> : held \in Sample(3) },
      idSource                                            : { << >> } \cup { <<held>> : held \in Sample(1) },
      securityId                                          : { << >> } \cup { <<held>> : held \in Sample(16) },
      securityExchange                                    : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingFirm                                        : { << >> } \cup { <<held>> : held \in Sample(4) },
      orderQty                                            : { << >> } \cup { <<held>> : held \in Sample(4) },
      tradeReportTypeReturn                               : { << >> } \cup { <<held>> : held \in Sample(2) },
      largeSize                                           : { << >> } \cup { <<held>> : held \in Sample(8) },
      lastMkt                                             : { << >> } \cup { <<held>> : held \in Sample(4) },
      tradeReportRefId                                    : { << >> } \cup { <<held>> : held \in Sample(20) },
      orderCategory                                       : { << >> } \cup { <<held>> : held \in Sample(1) },
      liquidityProvision                                  : { << >> } \cup { <<held>> : held \in Sample(1) },
      waiverType                                          : { << >> } \cup { <<held>> : held \in Sample(1) },
      priceFormation                                      : { << >> } \cup { <<held>> : held \in Sample(1) },
      clientQualifiedRole                                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      clientId                                            : { << >> } \cup { <<held>> : held \in Sample(4) },
      investorId                                          : { << >> } \cup { <<held>> : held \in Sample(4) },
      executorId                                          : { << >> } \cup { <<held>> : held \in Sample(4) },
      orderOrigination                                    : { << >> } \cup { <<held>> : held \in Sample(1) },
      algorithmicIndicator                                : { << >> } \cup { <<held>> : held \in Sample(1) },
      investorQualifiedRole                               : { << >> } \cup { <<held>> : held \in Sample(1) },
      executorQualifiedRole                               : { << >> } \cup { <<held>> : held \in Sample(1) } ]

EncodeTradeCaptureReportAcknowledgmentV2Message(message) ==
    message.transactionTime
        \o message.tradeReportId
        \o message.reserved1
        \o EncodeUIntBE(message.numberOfTradeCaptureReportAcknowledgmentV2Bitfields, 1)
        \o (IF message.tradeCaptureReportAcknowledgmentV2Bitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCaptureReportAcknowledgmentV2Bitfield1[1], 1))
        \o (IF message.tradeCaptureReportAcknowledgmentV2Bitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCaptureReportAcknowledgmentV2Bitfield2[1], 1))
        \o (IF message.tradeCaptureReportAcknowledgmentV2Bitfield3 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCaptureReportAcknowledgmentV2Bitfield3[1], 1))
        \o (IF message.tradeCaptureReportAcknowledgmentV2Bitfield4 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCaptureReportAcknowledgmentV2Bitfield4[1], 1))
        \o (IF message.tradeCaptureReportAcknowledgmentV2Bitfield5 = << >> THEN << >> ELSE message.tradeCaptureReportAcknowledgmentV2Bitfield5[1])
        \o (IF message.tradeCaptureReportAcknowledgmentV2Bitfield6 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCaptureReportAcknowledgmentV2Bitfield6[1], 1))
        \o (IF message.tradeCaptureReportAcknowledgmentV2Bitfield7 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCaptureReportAcknowledgmentV2Bitfield7[1], 1))
        \o (IF message.tradeCaptureReportAcknowledgmentV2Bitfield8 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCaptureReportAcknowledgmentV2Bitfield8[1], 1))
        \o (IF message.tradeCaptureReportAcknowledgmentV2Bitfield9 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCaptureReportAcknowledgmentV2Bitfield9[1], 1))
        \o (IF message.tradeCaptureReportAcknowledgmentV2Bitfield10 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCaptureReportAcknowledgmentV2Bitfield10[1], 1))
        \o (IF message.tradeCaptureReportAcknowledgmentV2Bitfield11 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCaptureReportAcknowledgmentV2Bitfield11[1], 1))
        \o (IF message.tradeCaptureReportAcknowledgmentV2Bitfield12 = << >> THEN << >> ELSE message.tradeCaptureReportAcknowledgmentV2Bitfield12[1])
        \o (IF message.tradeCaptureReportAcknowledgmentV2Bitfield13 = << >> THEN << >> ELSE message.tradeCaptureReportAcknowledgmentV2Bitfield13[1])
        \o (IF message.tradeCaptureReportAcknowledgmentV2Bitfield14 = << >> THEN << >> ELSE message.tradeCaptureReportAcknowledgmentV2Bitfield14[1])
        \o EncodeUIntBE(Len(message.trdCapAckSideGrp), 1)
        \o EncodeTrdCapAckSideGrpList(message.trdCapAckSideGrp)
        \o (IF message.execInst = << >> THEN << >> ELSE message.execInst[1])
        \o (IF message.symbol = << >> THEN << >> ELSE message.symbol[1])
        \o (IF message.currency = << >> THEN << >> ELSE message.currency[1])
        \o (IF message.idSource = << >> THEN << >> ELSE message.idSource[1])
        \o (IF message.securityId = << >> THEN << >> ELSE message.securityId[1])
        \o (IF message.securityExchange = << >> THEN << >> ELSE message.securityExchange[1])
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])
        \o (IF message.orderQty = << >> THEN << >> ELSE message.orderQty[1])
        \o (IF message.tradeReportTypeReturn = << >> THEN << >> ELSE message.tradeReportTypeReturn[1])
        \o (IF message.largeSize = << >> THEN << >> ELSE message.largeSize[1])
        \o (IF message.lastMkt = << >> THEN << >> ELSE message.lastMkt[1])
        \o (IF message.tradeReportRefId = << >> THEN << >> ELSE message.tradeReportRefId[1])
        \o (IF message.orderCategory = << >> THEN << >> ELSE message.orderCategory[1])
        \o (IF message.liquidityProvision = << >> THEN << >> ELSE message.liquidityProvision[1])
        \o (IF message.waiverType = << >> THEN << >> ELSE message.waiverType[1])
        \o (IF message.priceFormation = << >> THEN << >> ELSE message.priceFormation[1])
        \o (IF message.clientQualifiedRole = << >> THEN << >> ELSE message.clientQualifiedRole[1])
        \o (IF message.clientId = << >> THEN << >> ELSE message.clientId[1])
        \o (IF message.investorId = << >> THEN << >> ELSE message.investorId[1])
        \o (IF message.executorId = << >> THEN << >> ELSE message.executorId[1])
        \o (IF message.orderOrigination = << >> THEN << >> ELSE message.orderOrigination[1])
        \o (IF message.algorithmicIndicator = << >> THEN << >> ELSE message.algorithmicIndicator[1])
        \o (IF message.investorQualifiedRole = << >> THEN << >> ELSE message.investorQualifiedRole[1])
        \o (IF message.executorQualifiedRole = << >> THEN << >> ELSE message.executorQualifiedRole[1])

DecodeTradeCaptureReportAcknowledgmentV2Message(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(transactionTime.rest, 20) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(tradeReportId.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET numberOfTradeCaptureReportAcknowledgmentV2Bitfields == ReadUIntBE(reserved1.rest, 1) IN IF ~numberOfTradeCaptureReportAcknowledgmentV2Bitfields.ok THEN Fail ELSE
    LET tradeCaptureReportAcknowledgmentV2Bitfield1 == ReadWhen(numberOfTradeCaptureReportAcknowledgmentV2Bitfields.value >= 1, ReadUIntLE(numberOfTradeCaptureReportAcknowledgmentV2Bitfields.rest, 1), numberOfTradeCaptureReportAcknowledgmentV2Bitfields.rest) IN IF ~tradeCaptureReportAcknowledgmentV2Bitfield1.ok THEN Fail ELSE
    LET tradeCaptureReportAcknowledgmentV2Bitfield2 == ReadWhen(numberOfTradeCaptureReportAcknowledgmentV2Bitfields.value >= 2, ReadUIntLE(tradeCaptureReportAcknowledgmentV2Bitfield1.rest, 1), tradeCaptureReportAcknowledgmentV2Bitfield1.rest) IN IF ~tradeCaptureReportAcknowledgmentV2Bitfield2.ok THEN Fail ELSE
    LET tradeCaptureReportAcknowledgmentV2Bitfield3 == ReadWhen(numberOfTradeCaptureReportAcknowledgmentV2Bitfields.value >= 3, ReadUIntLE(tradeCaptureReportAcknowledgmentV2Bitfield2.rest, 1), tradeCaptureReportAcknowledgmentV2Bitfield2.rest) IN IF ~tradeCaptureReportAcknowledgmentV2Bitfield3.ok THEN Fail ELSE
    LET tradeCaptureReportAcknowledgmentV2Bitfield4 == ReadWhen(numberOfTradeCaptureReportAcknowledgmentV2Bitfields.value >= 4, ReadUIntLE(tradeCaptureReportAcknowledgmentV2Bitfield3.rest, 1), tradeCaptureReportAcknowledgmentV2Bitfield3.rest) IN IF ~tradeCaptureReportAcknowledgmentV2Bitfield4.ok THEN Fail ELSE
    LET tradeCaptureReportAcknowledgmentV2Bitfield5 == ReadWhen(numberOfTradeCaptureReportAcknowledgmentV2Bitfields.value >= 5, ReadBytes(tradeCaptureReportAcknowledgmentV2Bitfield4.rest, 1), tradeCaptureReportAcknowledgmentV2Bitfield4.rest) IN IF ~tradeCaptureReportAcknowledgmentV2Bitfield5.ok THEN Fail ELSE
    LET tradeCaptureReportAcknowledgmentV2Bitfield6 == ReadWhen(numberOfTradeCaptureReportAcknowledgmentV2Bitfields.value >= 6, ReadUIntLE(tradeCaptureReportAcknowledgmentV2Bitfield5.rest, 1), tradeCaptureReportAcknowledgmentV2Bitfield5.rest) IN IF ~tradeCaptureReportAcknowledgmentV2Bitfield6.ok THEN Fail ELSE
    LET tradeCaptureReportAcknowledgmentV2Bitfield7 == ReadWhen(numberOfTradeCaptureReportAcknowledgmentV2Bitfields.value >= 7, ReadUIntLE(tradeCaptureReportAcknowledgmentV2Bitfield6.rest, 1), tradeCaptureReportAcknowledgmentV2Bitfield6.rest) IN IF ~tradeCaptureReportAcknowledgmentV2Bitfield7.ok THEN Fail ELSE
    LET tradeCaptureReportAcknowledgmentV2Bitfield8 == ReadWhen(numberOfTradeCaptureReportAcknowledgmentV2Bitfields.value >= 8, ReadUIntLE(tradeCaptureReportAcknowledgmentV2Bitfield7.rest, 1), tradeCaptureReportAcknowledgmentV2Bitfield7.rest) IN IF ~tradeCaptureReportAcknowledgmentV2Bitfield8.ok THEN Fail ELSE
    LET tradeCaptureReportAcknowledgmentV2Bitfield9 == ReadWhen(numberOfTradeCaptureReportAcknowledgmentV2Bitfields.value >= 9, ReadUIntLE(tradeCaptureReportAcknowledgmentV2Bitfield8.rest, 1), tradeCaptureReportAcknowledgmentV2Bitfield8.rest) IN IF ~tradeCaptureReportAcknowledgmentV2Bitfield9.ok THEN Fail ELSE
    LET tradeCaptureReportAcknowledgmentV2Bitfield10 == ReadWhen(numberOfTradeCaptureReportAcknowledgmentV2Bitfields.value >= 10, ReadUIntLE(tradeCaptureReportAcknowledgmentV2Bitfield9.rest, 1), tradeCaptureReportAcknowledgmentV2Bitfield9.rest) IN IF ~tradeCaptureReportAcknowledgmentV2Bitfield10.ok THEN Fail ELSE
    LET tradeCaptureReportAcknowledgmentV2Bitfield11 == ReadWhen(numberOfTradeCaptureReportAcknowledgmentV2Bitfields.value >= 11, ReadUIntLE(tradeCaptureReportAcknowledgmentV2Bitfield10.rest, 1), tradeCaptureReportAcknowledgmentV2Bitfield10.rest) IN IF ~tradeCaptureReportAcknowledgmentV2Bitfield11.ok THEN Fail ELSE
    LET tradeCaptureReportAcknowledgmentV2Bitfield12 == ReadWhen(numberOfTradeCaptureReportAcknowledgmentV2Bitfields.value >= 12, ReadBytes(tradeCaptureReportAcknowledgmentV2Bitfield11.rest, 1), tradeCaptureReportAcknowledgmentV2Bitfield11.rest) IN IF ~tradeCaptureReportAcknowledgmentV2Bitfield12.ok THEN Fail ELSE
    LET tradeCaptureReportAcknowledgmentV2Bitfield13 == ReadWhen(numberOfTradeCaptureReportAcknowledgmentV2Bitfields.value >= 13, ReadBytes(tradeCaptureReportAcknowledgmentV2Bitfield12.rest, 1), tradeCaptureReportAcknowledgmentV2Bitfield12.rest) IN IF ~tradeCaptureReportAcknowledgmentV2Bitfield13.ok THEN Fail ELSE
    LET tradeCaptureReportAcknowledgmentV2Bitfield14 == ReadWhen(numberOfTradeCaptureReportAcknowledgmentV2Bitfields.value >= 14, ReadBytes(tradeCaptureReportAcknowledgmentV2Bitfield13.rest, 1), tradeCaptureReportAcknowledgmentV2Bitfield13.rest) IN IF ~tradeCaptureReportAcknowledgmentV2Bitfield14.ok THEN Fail ELSE
    LET noSides == ReadUIntBE(tradeCaptureReportAcknowledgmentV2Bitfield14.rest, 1) IN IF ~noSides.ok THEN Fail ELSE
    LET trdCapAckSideGrp == ReadTrdCapAckSideGrpList(noSides.rest, noSides.value, numberOfTradeCaptureReportAcknowledgmentV2Bitfields.value, tradeCaptureReportAcknowledgmentV2Bitfield1.value, tradeCaptureReportAcknowledgmentV2Bitfield2.value, tradeCaptureReportAcknowledgmentV2Bitfield3.value, tradeCaptureReportAcknowledgmentV2Bitfield4.value, tradeCaptureReportAcknowledgmentV2Bitfield6.value) IN IF ~trdCapAckSideGrp.ok THEN Fail ELSE
    LET execInst == ReadWhen(numberOfTradeCaptureReportAcknowledgmentV2Bitfields.value >= 1 /\ (tradeCaptureReportAcknowledgmentV2Bitfield1.value # << >> /\ (tradeCaptureReportAcknowledgmentV2Bitfield1.value[1] \div 8) % 2 > 0), ReadBytes(trdCapAckSideGrp.rest, 1), trdCapAckSideGrp.rest) IN IF ~execInst.ok THEN Fail ELSE
    LET symbol == ReadWhen(numberOfTradeCaptureReportAcknowledgmentV2Bitfields.value >= 2 /\ (tradeCaptureReportAcknowledgmentV2Bitfield2.value # << >> /\ tradeCaptureReportAcknowledgmentV2Bitfield2.value[1] % 2 > 0), ReadBytes(execInst.rest, 8), execInst.rest) IN IF ~symbol.ok THEN Fail ELSE
    LET currency == ReadWhen(numberOfTradeCaptureReportAcknowledgmentV2Bitfields.value >= 2 /\ (tradeCaptureReportAcknowledgmentV2Bitfield2.value # << >> /\ (tradeCaptureReportAcknowledgmentV2Bitfield2.value[1] \div 4) % 2 > 0), ReadBytes(symbol.rest, 3), symbol.rest) IN IF ~currency.ok THEN Fail ELSE
    LET idSource == ReadWhen(numberOfTradeCaptureReportAcknowledgmentV2Bitfields.value >= 2 /\ (tradeCaptureReportAcknowledgmentV2Bitfield2.value # << >> /\ (tradeCaptureReportAcknowledgmentV2Bitfield2.value[1] \div 8) % 2 > 0), ReadBytes(currency.rest, 1), currency.rest) IN IF ~idSource.ok THEN Fail ELSE
    LET securityId == ReadWhen(numberOfTradeCaptureReportAcknowledgmentV2Bitfields.value >= 2 /\ (tradeCaptureReportAcknowledgmentV2Bitfield2.value # << >> /\ (tradeCaptureReportAcknowledgmentV2Bitfield2.value[1] \div 16) % 2 > 0), ReadBytes(idSource.rest, 16), idSource.rest) IN IF ~securityId.ok THEN Fail ELSE
    LET securityExchange == ReadWhen(numberOfTradeCaptureReportAcknowledgmentV2Bitfields.value >= 2 /\ (tradeCaptureReportAcknowledgmentV2Bitfield2.value # << >> /\ (tradeCaptureReportAcknowledgmentV2Bitfield2.value[1] \div 32) % 2 > 0), ReadBytes(securityId.rest, 4), securityId.rest) IN IF ~securityExchange.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfTradeCaptureReportAcknowledgmentV2Bitfields.value >= 3 /\ (tradeCaptureReportAcknowledgmentV2Bitfield3.value # << >> /\ (tradeCaptureReportAcknowledgmentV2Bitfield3.value[1] \div 2) % 2 > 0), ReadBytes(securityExchange.rest, 4), securityExchange.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET orderQty == ReadWhen(numberOfTradeCaptureReportAcknowledgmentV2Bitfields.value >= 3 /\ (tradeCaptureReportAcknowledgmentV2Bitfield3.value # << >> /\ (tradeCaptureReportAcknowledgmentV2Bitfield3.value[1] \div 64) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~orderQty.ok THEN Fail ELSE
    LET tradeReportTypeReturn == ReadWhen(numberOfTradeCaptureReportAcknowledgmentV2Bitfields.value >= 7 /\ (tradeCaptureReportAcknowledgmentV2Bitfield7.value # << >> /\ (tradeCaptureReportAcknowledgmentV2Bitfield7.value[1] \div 2) % 2 > 0), ReadBytes(orderQty.rest, 2), orderQty.rest) IN IF ~tradeReportTypeReturn.ok THEN Fail ELSE
    LET largeSize == ReadWhen(numberOfTradeCaptureReportAcknowledgmentV2Bitfields.value >= 7 /\ (tradeCaptureReportAcknowledgmentV2Bitfield7.value # << >> /\ (tradeCaptureReportAcknowledgmentV2Bitfield7.value[1] \div 64) % 2 > 0), ReadBytes(tradeReportTypeReturn.rest, 8), tradeReportTypeReturn.rest) IN IF ~largeSize.ok THEN Fail ELSE
    LET lastMkt == ReadWhen(numberOfTradeCaptureReportAcknowledgmentV2Bitfields.value >= 7 /\ (tradeCaptureReportAcknowledgmentV2Bitfield7.value # << >> /\ (tradeCaptureReportAcknowledgmentV2Bitfield7.value[1] \div 128) % 2 > 0), ReadBytes(largeSize.rest, 4), largeSize.rest) IN IF ~lastMkt.ok THEN Fail ELSE
    LET tradeReportRefId == ReadWhen(numberOfTradeCaptureReportAcknowledgmentV2Bitfields.value >= 8 /\ (tradeCaptureReportAcknowledgmentV2Bitfield8.value # << >> /\ (tradeCaptureReportAcknowledgmentV2Bitfield8.value[1] \div 128) % 2 > 0), ReadBytes(lastMkt.rest, 20), lastMkt.rest) IN IF ~tradeReportRefId.ok THEN Fail ELSE
    LET orderCategory == ReadWhen(numberOfTradeCaptureReportAcknowledgmentV2Bitfields.value >= 9 /\ (tradeCaptureReportAcknowledgmentV2Bitfield9.value # << >> /\ (tradeCaptureReportAcknowledgmentV2Bitfield9.value[1] \div 8) % 2 > 0), ReadBytes(tradeReportRefId.rest, 1), tradeReportRefId.rest) IN IF ~orderCategory.ok THEN Fail ELSE
    LET liquidityProvision == ReadWhen(numberOfTradeCaptureReportAcknowledgmentV2Bitfields.value >= 9 /\ (tradeCaptureReportAcknowledgmentV2Bitfield9.value # << >> /\ (tradeCaptureReportAcknowledgmentV2Bitfield9.value[1] \div 16) % 2 > 0), ReadBytes(orderCategory.rest, 1), orderCategory.rest) IN IF ~liquidityProvision.ok THEN Fail ELSE
    LET waiverType == ReadWhen(numberOfTradeCaptureReportAcknowledgmentV2Bitfields.value >= 10 /\ (tradeCaptureReportAcknowledgmentV2Bitfield10.value # << >> /\ (tradeCaptureReportAcknowledgmentV2Bitfield10.value[1] \div 16) % 2 > 0), ReadBytes(liquidityProvision.rest, 1), liquidityProvision.rest) IN IF ~waiverType.ok THEN Fail ELSE
    LET priceFormation == ReadWhen(numberOfTradeCaptureReportAcknowledgmentV2Bitfields.value >= 10 /\ (tradeCaptureReportAcknowledgmentV2Bitfield10.value # << >> /\ (tradeCaptureReportAcknowledgmentV2Bitfield10.value[1] \div 64) % 2 > 0), ReadBytes(waiverType.rest, 1), waiverType.rest) IN IF ~priceFormation.ok THEN Fail ELSE
    LET clientQualifiedRole == ReadWhen(numberOfTradeCaptureReportAcknowledgmentV2Bitfields.value >= 10 /\ (tradeCaptureReportAcknowledgmentV2Bitfield10.value # << >> /\ (tradeCaptureReportAcknowledgmentV2Bitfield10.value[1] \div 128) % 2 > 0), ReadBytes(priceFormation.rest, 1), priceFormation.rest) IN IF ~clientQualifiedRole.ok THEN Fail ELSE
    LET clientId == ReadWhen(numberOfTradeCaptureReportAcknowledgmentV2Bitfields.value >= 11 /\ (tradeCaptureReportAcknowledgmentV2Bitfield11.value # << >> /\ tradeCaptureReportAcknowledgmentV2Bitfield11.value[1] % 2 > 0), ReadBytes(clientQualifiedRole.rest, 4), clientQualifiedRole.rest) IN IF ~clientId.ok THEN Fail ELSE
    LET investorId == ReadWhen(numberOfTradeCaptureReportAcknowledgmentV2Bitfields.value >= 11 /\ (tradeCaptureReportAcknowledgmentV2Bitfield11.value # << >> /\ (tradeCaptureReportAcknowledgmentV2Bitfield11.value[1] \div 2) % 2 > 0), ReadBytes(clientId.rest, 4), clientId.rest) IN IF ~investorId.ok THEN Fail ELSE
    LET executorId == ReadWhen(numberOfTradeCaptureReportAcknowledgmentV2Bitfields.value >= 11 /\ (tradeCaptureReportAcknowledgmentV2Bitfield11.value # << >> /\ (tradeCaptureReportAcknowledgmentV2Bitfield11.value[1] \div 4) % 2 > 0), ReadBytes(investorId.rest, 4), investorId.rest) IN IF ~executorId.ok THEN Fail ELSE
    LET orderOrigination == ReadWhen(numberOfTradeCaptureReportAcknowledgmentV2Bitfields.value >= 11 /\ (tradeCaptureReportAcknowledgmentV2Bitfield11.value # << >> /\ (tradeCaptureReportAcknowledgmentV2Bitfield11.value[1] \div 8) % 2 > 0), ReadBytes(executorId.rest, 1), executorId.rest) IN IF ~orderOrigination.ok THEN Fail ELSE
    LET algorithmicIndicator == ReadWhen(numberOfTradeCaptureReportAcknowledgmentV2Bitfields.value >= 11 /\ (tradeCaptureReportAcknowledgmentV2Bitfield11.value # << >> /\ (tradeCaptureReportAcknowledgmentV2Bitfield11.value[1] \div 16) % 2 > 0), ReadBytes(orderOrigination.rest, 1), orderOrigination.rest) IN IF ~algorithmicIndicator.ok THEN Fail ELSE
    LET investorQualifiedRole == ReadWhen(numberOfTradeCaptureReportAcknowledgmentV2Bitfields.value >= 11 /\ (tradeCaptureReportAcknowledgmentV2Bitfield11.value # << >> /\ (tradeCaptureReportAcknowledgmentV2Bitfield11.value[1] \div 64) % 2 > 0), ReadBytes(algorithmicIndicator.rest, 1), algorithmicIndicator.rest) IN IF ~investorQualifiedRole.ok THEN Fail ELSE
    LET executorQualifiedRole == ReadWhen(numberOfTradeCaptureReportAcknowledgmentV2Bitfields.value >= 11 /\ (tradeCaptureReportAcknowledgmentV2Bitfield11.value # << >> /\ (tradeCaptureReportAcknowledgmentV2Bitfield11.value[1] \div 128) % 2 > 0), ReadBytes(investorQualifiedRole.rest, 1), investorQualifiedRole.rest) IN IF ~executorQualifiedRole.ok THEN Fail ELSE
    Ok([ transactionTime                                     |-> transactionTime.value,
         tradeReportId                                       |-> tradeReportId.value,
         reserved1                                           |-> reserved1.value,
         numberOfTradeCaptureReportAcknowledgmentV2Bitfields |-> numberOfTradeCaptureReportAcknowledgmentV2Bitfields.value,
         tradeCaptureReportAcknowledgmentV2Bitfield1         |-> tradeCaptureReportAcknowledgmentV2Bitfield1.value,
         tradeCaptureReportAcknowledgmentV2Bitfield2         |-> tradeCaptureReportAcknowledgmentV2Bitfield2.value,
         tradeCaptureReportAcknowledgmentV2Bitfield3         |-> tradeCaptureReportAcknowledgmentV2Bitfield3.value,
         tradeCaptureReportAcknowledgmentV2Bitfield4         |-> tradeCaptureReportAcknowledgmentV2Bitfield4.value,
         tradeCaptureReportAcknowledgmentV2Bitfield5         |-> tradeCaptureReportAcknowledgmentV2Bitfield5.value,
         tradeCaptureReportAcknowledgmentV2Bitfield6         |-> tradeCaptureReportAcknowledgmentV2Bitfield6.value,
         tradeCaptureReportAcknowledgmentV2Bitfield7         |-> tradeCaptureReportAcknowledgmentV2Bitfield7.value,
         tradeCaptureReportAcknowledgmentV2Bitfield8         |-> tradeCaptureReportAcknowledgmentV2Bitfield8.value,
         tradeCaptureReportAcknowledgmentV2Bitfield9         |-> tradeCaptureReportAcknowledgmentV2Bitfield9.value,
         tradeCaptureReportAcknowledgmentV2Bitfield10        |-> tradeCaptureReportAcknowledgmentV2Bitfield10.value,
         tradeCaptureReportAcknowledgmentV2Bitfield11        |-> tradeCaptureReportAcknowledgmentV2Bitfield11.value,
         tradeCaptureReportAcknowledgmentV2Bitfield12        |-> tradeCaptureReportAcknowledgmentV2Bitfield12.value,
         tradeCaptureReportAcknowledgmentV2Bitfield13        |-> tradeCaptureReportAcknowledgmentV2Bitfield13.value,
         tradeCaptureReportAcknowledgmentV2Bitfield14        |-> tradeCaptureReportAcknowledgmentV2Bitfield14.value,
         trdCapAckSideGrp                                    |-> trdCapAckSideGrp.value,
         execInst                                            |-> execInst.value,
         symbol                                              |-> symbol.value,
         currency                                            |-> currency.value,
         idSource                                            |-> idSource.value,
         securityId                                          |-> securityId.value,
         securityExchange                                    |-> securityExchange.value,
         clearingFirm                                        |-> clearingFirm.value,
         orderQty                                            |-> orderQty.value,
         tradeReportTypeReturn                               |-> tradeReportTypeReturn.value,
         largeSize                                           |-> largeSize.value,
         lastMkt                                             |-> lastMkt.value,
         tradeReportRefId                                    |-> tradeReportRefId.value,
         orderCategory                                       |-> orderCategory.value,
         liquidityProvision                                  |-> liquidityProvision.value,
         waiverType                                          |-> waiverType.value,
         priceFormation                                      |-> priceFormation.value,
         clientQualifiedRole                                 |-> clientQualifiedRole.value,
         clientId                                            |-> clientId.value,
         investorId                                          |-> investorId.value,
         executorId                                          |-> executorId.value,
         orderOrigination                                    |-> orderOrigination.value,
         algorithmicIndicator                                |-> algorithmicIndicator.value,
         investorQualifiedRole                               |-> investorQualifiedRole.value,
         executorQualifiedRole                               |-> executorQualifiedRole.value ], executorQualifiedRole.rest)

(* Trade Capture Report Acknowledgment V 2 Message with each field marked present by fields before it there exactly where they say *)
SettleTradeCaptureReportAcknowledgmentV2Message(message) ==
    LET settled1 == [message EXCEPT !.tradeCaptureReportAcknowledgmentV2Bitfield1 = IF message.numberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 1 THEN (IF message.tradeCaptureReportAcknowledgmentV2Bitfield1 = << >> THEN <<0>> ELSE message.tradeCaptureReportAcknowledgmentV2Bitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.tradeCaptureReportAcknowledgmentV2Bitfield2 = IF settled1.numberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 2 THEN (IF settled1.tradeCaptureReportAcknowledgmentV2Bitfield2 = << >> THEN <<0>> ELSE settled1.tradeCaptureReportAcknowledgmentV2Bitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.tradeCaptureReportAcknowledgmentV2Bitfield3 = IF settled2.numberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 3 THEN (IF settled2.tradeCaptureReportAcknowledgmentV2Bitfield3 = << >> THEN <<0>> ELSE settled2.tradeCaptureReportAcknowledgmentV2Bitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.tradeCaptureReportAcknowledgmentV2Bitfield4 = IF settled3.numberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 4 THEN (IF settled3.tradeCaptureReportAcknowledgmentV2Bitfield4 = << >> THEN <<0>> ELSE settled3.tradeCaptureReportAcknowledgmentV2Bitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.tradeCaptureReportAcknowledgmentV2Bitfield5 = IF settled4.numberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 5 THEN (IF settled4.tradeCaptureReportAcknowledgmentV2Bitfield5 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled4.tradeCaptureReportAcknowledgmentV2Bitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.tradeCaptureReportAcknowledgmentV2Bitfield6 = IF settled5.numberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 6 THEN (IF settled5.tradeCaptureReportAcknowledgmentV2Bitfield6 = << >> THEN <<0>> ELSE settled5.tradeCaptureReportAcknowledgmentV2Bitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.tradeCaptureReportAcknowledgmentV2Bitfield7 = IF settled6.numberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 7 THEN (IF settled6.tradeCaptureReportAcknowledgmentV2Bitfield7 = << >> THEN <<0>> ELSE settled6.tradeCaptureReportAcknowledgmentV2Bitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.tradeCaptureReportAcknowledgmentV2Bitfield8 = IF settled7.numberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 8 THEN (IF settled7.tradeCaptureReportAcknowledgmentV2Bitfield8 = << >> THEN <<0>> ELSE settled7.tradeCaptureReportAcknowledgmentV2Bitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.tradeCaptureReportAcknowledgmentV2Bitfield9 = IF settled8.numberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 9 THEN (IF settled8.tradeCaptureReportAcknowledgmentV2Bitfield9 = << >> THEN <<0>> ELSE settled8.tradeCaptureReportAcknowledgmentV2Bitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.tradeCaptureReportAcknowledgmentV2Bitfield10 = IF settled9.numberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 10 THEN (IF settled9.tradeCaptureReportAcknowledgmentV2Bitfield10 = << >> THEN <<0>> ELSE settled9.tradeCaptureReportAcknowledgmentV2Bitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.tradeCaptureReportAcknowledgmentV2Bitfield11 = IF settled10.numberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 11 THEN (IF settled10.tradeCaptureReportAcknowledgmentV2Bitfield11 = << >> THEN <<0>> ELSE settled10.tradeCaptureReportAcknowledgmentV2Bitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.tradeCaptureReportAcknowledgmentV2Bitfield12 = IF settled11.numberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 12 THEN (IF settled11.tradeCaptureReportAcknowledgmentV2Bitfield12 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.tradeCaptureReportAcknowledgmentV2Bitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.tradeCaptureReportAcknowledgmentV2Bitfield13 = IF settled12.numberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 13 THEN (IF settled12.tradeCaptureReportAcknowledgmentV2Bitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.tradeCaptureReportAcknowledgmentV2Bitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.tradeCaptureReportAcknowledgmentV2Bitfield14 = IF settled13.numberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 14 THEN (IF settled13.tradeCaptureReportAcknowledgmentV2Bitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.tradeCaptureReportAcknowledgmentV2Bitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.trdCapAckSideGrp = [i \in DOMAIN settled14.trdCapAckSideGrp |-> SettleTrdCapAckSideGrp(settled14.trdCapAckSideGrp[i], settled14.numberOfTradeCaptureReportAcknowledgmentV2Bitfields, settled14.tradeCaptureReportAcknowledgmentV2Bitfield1, settled14.tradeCaptureReportAcknowledgmentV2Bitfield2, settled14.tradeCaptureReportAcknowledgmentV2Bitfield3, settled14.tradeCaptureReportAcknowledgmentV2Bitfield4, settled14.tradeCaptureReportAcknowledgmentV2Bitfield6)]]
        settled16 == [settled15 EXCEPT !.execInst = IF settled15.numberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 1 /\ (settled15.tradeCaptureReportAcknowledgmentV2Bitfield1 # << >> /\ (settled15.tradeCaptureReportAcknowledgmentV2Bitfield1[1] \div 8) % 2 > 0) THEN (IF settled15.execInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled15.execInst) ELSE << >>]
        settled17 == [settled16 EXCEPT !.symbol = IF settled16.numberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 2 /\ (settled16.tradeCaptureReportAcknowledgmentV2Bitfield2 # << >> /\ settled16.tradeCaptureReportAcknowledgmentV2Bitfield2[1] % 2 > 0) THEN (IF settled16.symbol = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled16.symbol) ELSE << >>]
        settled18 == [settled17 EXCEPT !.currency = IF settled17.numberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 2 /\ (settled17.tradeCaptureReportAcknowledgmentV2Bitfield2 # << >> /\ (settled17.tradeCaptureReportAcknowledgmentV2Bitfield2[1] \div 4) % 2 > 0) THEN (IF settled17.currency = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled17.currency) ELSE << >>]
        settled19 == [settled18 EXCEPT !.idSource = IF settled18.numberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 2 /\ (settled18.tradeCaptureReportAcknowledgmentV2Bitfield2 # << >> /\ (settled18.tradeCaptureReportAcknowledgmentV2Bitfield2[1] \div 8) % 2 > 0) THEN (IF settled18.idSource = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled18.idSource) ELSE << >>]
        settled20 == [settled19 EXCEPT !.securityId = IF settled19.numberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 2 /\ (settled19.tradeCaptureReportAcknowledgmentV2Bitfield2 # << >> /\ (settled19.tradeCaptureReportAcknowledgmentV2Bitfield2[1] \div 16) % 2 > 0) THEN (IF settled19.securityId = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled19.securityId) ELSE << >>]
        settled21 == [settled20 EXCEPT !.securityExchange = IF settled20.numberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 2 /\ (settled20.tradeCaptureReportAcknowledgmentV2Bitfield2 # << >> /\ (settled20.tradeCaptureReportAcknowledgmentV2Bitfield2[1] \div 32) % 2 > 0) THEN (IF settled20.securityExchange = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled20.securityExchange) ELSE << >>]
        settled22 == [settled21 EXCEPT !.clearingFirm = IF settled21.numberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 3 /\ (settled21.tradeCaptureReportAcknowledgmentV2Bitfield3 # << >> /\ (settled21.tradeCaptureReportAcknowledgmentV2Bitfield3[1] \div 2) % 2 > 0) THEN (IF settled21.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled21.clearingFirm) ELSE << >>]
        settled23 == [settled22 EXCEPT !.orderQty = IF settled22.numberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 3 /\ (settled22.tradeCaptureReportAcknowledgmentV2Bitfield3 # << >> /\ (settled22.tradeCaptureReportAcknowledgmentV2Bitfield3[1] \div 64) % 2 > 0) THEN (IF settled22.orderQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled22.orderQty) ELSE << >>]
        settled24 == [settled23 EXCEPT !.tradeReportTypeReturn = IF settled23.numberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 7 /\ (settled23.tradeCaptureReportAcknowledgmentV2Bitfield7 # << >> /\ (settled23.tradeCaptureReportAcknowledgmentV2Bitfield7[1] \div 2) % 2 > 0) THEN (IF settled23.tradeReportTypeReturn = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled23.tradeReportTypeReturn) ELSE << >>]
        settled25 == [settled24 EXCEPT !.largeSize = IF settled24.numberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 7 /\ (settled24.tradeCaptureReportAcknowledgmentV2Bitfield7 # << >> /\ (settled24.tradeCaptureReportAcknowledgmentV2Bitfield7[1] \div 64) % 2 > 0) THEN (IF settled24.largeSize = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled24.largeSize) ELSE << >>]
        settled26 == [settled25 EXCEPT !.lastMkt = IF settled25.numberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 7 /\ (settled25.tradeCaptureReportAcknowledgmentV2Bitfield7 # << >> /\ (settled25.tradeCaptureReportAcknowledgmentV2Bitfield7[1] \div 128) % 2 > 0) THEN (IF settled25.lastMkt = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled25.lastMkt) ELSE << >>]
        settled27 == [settled26 EXCEPT !.tradeReportRefId = IF settled26.numberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 8 /\ (settled26.tradeCaptureReportAcknowledgmentV2Bitfield8 # << >> /\ (settled26.tradeCaptureReportAcknowledgmentV2Bitfield8[1] \div 128) % 2 > 0) THEN (IF settled26.tradeReportRefId = << >> THEN <<[i \in 1 .. 20 |-> 0]>> ELSE settled26.tradeReportRefId) ELSE << >>]
        settled28 == [settled27 EXCEPT !.orderCategory = IF settled27.numberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 9 /\ (settled27.tradeCaptureReportAcknowledgmentV2Bitfield9 # << >> /\ (settled27.tradeCaptureReportAcknowledgmentV2Bitfield9[1] \div 8) % 2 > 0) THEN (IF settled27.orderCategory = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled27.orderCategory) ELSE << >>]
        settled29 == [settled28 EXCEPT !.liquidityProvision = IF settled28.numberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 9 /\ (settled28.tradeCaptureReportAcknowledgmentV2Bitfield9 # << >> /\ (settled28.tradeCaptureReportAcknowledgmentV2Bitfield9[1] \div 16) % 2 > 0) THEN (IF settled28.liquidityProvision = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled28.liquidityProvision) ELSE << >>]
        settled30 == [settled29 EXCEPT !.waiverType = IF settled29.numberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 10 /\ (settled29.tradeCaptureReportAcknowledgmentV2Bitfield10 # << >> /\ (settled29.tradeCaptureReportAcknowledgmentV2Bitfield10[1] \div 16) % 2 > 0) THEN (IF settled29.waiverType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled29.waiverType) ELSE << >>]
        settled31 == [settled30 EXCEPT !.priceFormation = IF settled30.numberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 10 /\ (settled30.tradeCaptureReportAcknowledgmentV2Bitfield10 # << >> /\ (settled30.tradeCaptureReportAcknowledgmentV2Bitfield10[1] \div 64) % 2 > 0) THEN (IF settled30.priceFormation = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled30.priceFormation) ELSE << >>]
        settled32 == [settled31 EXCEPT !.clientQualifiedRole = IF settled31.numberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 10 /\ (settled31.tradeCaptureReportAcknowledgmentV2Bitfield10 # << >> /\ (settled31.tradeCaptureReportAcknowledgmentV2Bitfield10[1] \div 128) % 2 > 0) THEN (IF settled31.clientQualifiedRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled31.clientQualifiedRole) ELSE << >>]
        settled33 == [settled32 EXCEPT !.clientId = IF settled32.numberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 11 /\ (settled32.tradeCaptureReportAcknowledgmentV2Bitfield11 # << >> /\ settled32.tradeCaptureReportAcknowledgmentV2Bitfield11[1] % 2 > 0) THEN (IF settled32.clientId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled32.clientId) ELSE << >>]
        settled34 == [settled33 EXCEPT !.investorId = IF settled33.numberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 11 /\ (settled33.tradeCaptureReportAcknowledgmentV2Bitfield11 # << >> /\ (settled33.tradeCaptureReportAcknowledgmentV2Bitfield11[1] \div 2) % 2 > 0) THEN (IF settled33.investorId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled33.investorId) ELSE << >>]
        settled35 == [settled34 EXCEPT !.executorId = IF settled34.numberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 11 /\ (settled34.tradeCaptureReportAcknowledgmentV2Bitfield11 # << >> /\ (settled34.tradeCaptureReportAcknowledgmentV2Bitfield11[1] \div 4) % 2 > 0) THEN (IF settled34.executorId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled34.executorId) ELSE << >>]
        settled36 == [settled35 EXCEPT !.orderOrigination = IF settled35.numberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 11 /\ (settled35.tradeCaptureReportAcknowledgmentV2Bitfield11 # << >> /\ (settled35.tradeCaptureReportAcknowledgmentV2Bitfield11[1] \div 8) % 2 > 0) THEN (IF settled35.orderOrigination = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled35.orderOrigination) ELSE << >>]
        settled37 == [settled36 EXCEPT !.algorithmicIndicator = IF settled36.numberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 11 /\ (settled36.tradeCaptureReportAcknowledgmentV2Bitfield11 # << >> /\ (settled36.tradeCaptureReportAcknowledgmentV2Bitfield11[1] \div 16) % 2 > 0) THEN (IF settled36.algorithmicIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled36.algorithmicIndicator) ELSE << >>]
        settled38 == [settled37 EXCEPT !.investorQualifiedRole = IF settled37.numberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 11 /\ (settled37.tradeCaptureReportAcknowledgmentV2Bitfield11 # << >> /\ (settled37.tradeCaptureReportAcknowledgmentV2Bitfield11[1] \div 64) % 2 > 0) THEN (IF settled37.investorQualifiedRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled37.investorQualifiedRole) ELSE << >>]
        settled39 == [settled38 EXCEPT !.executorQualifiedRole = IF settled38.numberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 11 /\ (settled38.tradeCaptureReportAcknowledgmentV2Bitfield11 # << >> /\ (settled38.tradeCaptureReportAcknowledgmentV2Bitfield11[1] \div 128) % 2 > 0) THEN (IF settled38.executorQualifiedRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled38.executorQualifiedRole) ELSE << >>]
    IN  settled39

ZeroTradeCaptureReportAcknowledgmentV2Message ==
    SettleTradeCaptureReportAcknowledgmentV2Message([ transactionTime                                     |-> [i \in 1 .. 8 |-> 0],
                                                      tradeReportId                                       |-> [i \in 1 .. 20 |-> 0],
                                                      reserved1                                           |-> [i \in 1 .. 1 |-> 0],
                                                      numberOfTradeCaptureReportAcknowledgmentV2Bitfields |-> 0,
                                                      tradeCaptureReportAcknowledgmentV2Bitfield1         |-> << >>,
                                                      tradeCaptureReportAcknowledgmentV2Bitfield2         |-> << >>,
                                                      tradeCaptureReportAcknowledgmentV2Bitfield3         |-> << >>,
                                                      tradeCaptureReportAcknowledgmentV2Bitfield4         |-> << >>,
                                                      tradeCaptureReportAcknowledgmentV2Bitfield5         |-> << >>,
                                                      tradeCaptureReportAcknowledgmentV2Bitfield6         |-> << >>,
                                                      tradeCaptureReportAcknowledgmentV2Bitfield7         |-> << >>,
                                                      tradeCaptureReportAcknowledgmentV2Bitfield8         |-> << >>,
                                                      tradeCaptureReportAcknowledgmentV2Bitfield9         |-> << >>,
                                                      tradeCaptureReportAcknowledgmentV2Bitfield10        |-> << >>,
                                                      tradeCaptureReportAcknowledgmentV2Bitfield11        |-> << >>,
                                                      tradeCaptureReportAcknowledgmentV2Bitfield12        |-> << >>,
                                                      tradeCaptureReportAcknowledgmentV2Bitfield13        |-> << >>,
                                                      tradeCaptureReportAcknowledgmentV2Bitfield14        |-> << >>,
                                                      trdCapAckSideGrp                                    |-> << >>,
                                                      execInst                                            |-> << >>,
                                                      symbol                                              |-> << >>,
                                                      currency                                            |-> << >>,
                                                      idSource                                            |-> << >>,
                                                      securityId                                          |-> << >>,
                                                      securityExchange                                    |-> << >>,
                                                      clearingFirm                                        |-> << >>,
                                                      orderQty                                            |-> << >>,
                                                      tradeReportTypeReturn                               |-> << >>,
                                                      largeSize                                           |-> << >>,
                                                      lastMkt                                             |-> << >>,
                                                      tradeReportRefId                                    |-> << >>,
                                                      orderCategory                                       |-> << >>,
                                                      liquidityProvision                                  |-> << >>,
                                                      waiverType                                          |-> << >>,
                                                      priceFormation                                      |-> << >>,
                                                      clientQualifiedRole                                 |-> << >>,
                                                      clientId                                            |-> << >>,
                                                      investorId                                          |-> << >>,
                                                      executorId                                          |-> << >>,
                                                      orderOrigination                                    |-> << >>,
                                                      algorithmicIndicator                                |-> << >>,
                                                      investorQualifiedRole                               |-> << >>,
                                                      executorQualifiedRole                               |-> << >> ])

(* Trade Capture Report Acknowledgment V 2 Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCaptureReportAcknowledgmentV2Message ==
    { ZeroTradeCaptureReportAcknowledgmentV2Message }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.transactionTime = one]) : one \in Sample(8) }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.tradeReportId = one]) : one \in Sample(20) }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.reserved1 = one]) : one \in Sample(1) }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 1, !.tradeCaptureReportAcknowledgmentV2Bitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 2, !.tradeCaptureReportAcknowledgmentV2Bitfield2 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 3, !.tradeCaptureReportAcknowledgmentV2Bitfield3 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 4, !.tradeCaptureReportAcknowledgmentV2Bitfield4 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 5, !.tradeCaptureReportAcknowledgmentV2Bitfield5 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 6, !.tradeCaptureReportAcknowledgmentV2Bitfield6 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 7, !.tradeCaptureReportAcknowledgmentV2Bitfield7 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 8, !.tradeCaptureReportAcknowledgmentV2Bitfield8 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 9, !.tradeCaptureReportAcknowledgmentV2Bitfield9 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 10, !.tradeCaptureReportAcknowledgmentV2Bitfield10 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 11, !.tradeCaptureReportAcknowledgmentV2Bitfield11 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 12, !.tradeCaptureReportAcknowledgmentV2Bitfield12 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 13, !.tradeCaptureReportAcknowledgmentV2Bitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 14, !.tradeCaptureReportAcknowledgmentV2Bitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.trdCapAckSideGrp = one]) : one \in SampleLists(OneTrdCapAckSideGrp) }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 1, !.tradeCaptureReportAcknowledgmentV2Bitfield1 = <<1>>, !.trdCapAckSideGrp = one]) : one \in SampleLists(OneTrdCapAckSideGrp) }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 2, !.tradeCaptureReportAcknowledgmentV2Bitfield2 = <<64>>, !.trdCapAckSideGrp = one]) : one \in SampleLists(OneTrdCapAckSideGrp) }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 3, !.tradeCaptureReportAcknowledgmentV2Bitfield3 = <<1>>, !.trdCapAckSideGrp = one]) : one \in SampleLists(OneTrdCapAckSideGrp) }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 4, !.tradeCaptureReportAcknowledgmentV2Bitfield4 = <<64>>, !.trdCapAckSideGrp = one]) : one \in SampleLists(OneTrdCapAckSideGrp) }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 6, !.tradeCaptureReportAcknowledgmentV2Bitfield6 = <<128>>, !.trdCapAckSideGrp = one]) : one \in SampleLists(OneTrdCapAckSideGrp) }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 1, !.tradeCaptureReportAcknowledgmentV2Bitfield1 = <<8>>, !.execInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 2, !.tradeCaptureReportAcknowledgmentV2Bitfield2 = <<1>>, !.symbol = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 2, !.tradeCaptureReportAcknowledgmentV2Bitfield2 = <<4>>, !.currency = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 2, !.tradeCaptureReportAcknowledgmentV2Bitfield2 = <<8>>, !.idSource = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 2, !.tradeCaptureReportAcknowledgmentV2Bitfield2 = <<16>>, !.securityId = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 2, !.tradeCaptureReportAcknowledgmentV2Bitfield2 = <<32>>, !.securityExchange = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 3, !.tradeCaptureReportAcknowledgmentV2Bitfield3 = <<2>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 3, !.tradeCaptureReportAcknowledgmentV2Bitfield3 = <<64>>, !.orderQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 7, !.tradeCaptureReportAcknowledgmentV2Bitfield7 = <<2>>, !.tradeReportTypeReturn = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 7, !.tradeCaptureReportAcknowledgmentV2Bitfield7 = <<64>>, !.largeSize = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 7, !.tradeCaptureReportAcknowledgmentV2Bitfield7 = <<128>>, !.lastMkt = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 8, !.tradeCaptureReportAcknowledgmentV2Bitfield8 = <<128>>, !.tradeReportRefId = one]) : one \in { <<held>> : held \in Sample(20) } }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 9, !.tradeCaptureReportAcknowledgmentV2Bitfield9 = <<8>>, !.orderCategory = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 9, !.tradeCaptureReportAcknowledgmentV2Bitfield9 = <<16>>, !.liquidityProvision = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 10, !.tradeCaptureReportAcknowledgmentV2Bitfield10 = <<16>>, !.waiverType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 10, !.tradeCaptureReportAcknowledgmentV2Bitfield10 = <<64>>, !.priceFormation = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 10, !.tradeCaptureReportAcknowledgmentV2Bitfield10 = <<128>>, !.clientQualifiedRole = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 11, !.tradeCaptureReportAcknowledgmentV2Bitfield11 = <<1>>, !.clientId = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 11, !.tradeCaptureReportAcknowledgmentV2Bitfield11 = <<2>>, !.investorId = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 11, !.tradeCaptureReportAcknowledgmentV2Bitfield11 = <<4>>, !.executorId = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 11, !.tradeCaptureReportAcknowledgmentV2Bitfield11 = <<8>>, !.orderOrigination = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 11, !.tradeCaptureReportAcknowledgmentV2Bitfield11 = <<16>>, !.algorithmicIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 11, !.tradeCaptureReportAcknowledgmentV2Bitfield11 = <<64>>, !.investorQualifiedRole = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 11, !.tradeCaptureReportAcknowledgmentV2Bitfield11 = <<128>>, !.executorQualifiedRole = one]) : one \in { <<held>> : held \in Sample(1) } }

(***************************************************************************)
(* Trade Capture Report Reject V 2 Trd Cap Ack Side Grp                    *)
(***************************************************************************)

TradeCaptureReportRejectV2TrdCapAckSideGrp ==
    [ side      : { << >> } \cup { <<held>> : held \in Sample(1) },
      capacity  : { << >> } \cup { <<held>> : held \in Sample(1) },
      account   : { << >> } \cup { <<held>> : held \in Sample(16) },
      partyId   : { << >> } \cup { <<held>> : held \in Sample(4) },
      partyRole : { << >> } \cup { <<held>> : held \in Sample(1) } ]

EncodeTradeCaptureReportRejectV2TrdCapAckSideGrp(message) ==
    (IF message.side = << >> THEN << >> ELSE message.side[1])
        \o (IF message.capacity = << >> THEN << >> ELSE message.capacity[1])
        \o (IF message.account = << >> THEN << >> ELSE message.account[1])
        \o (IF message.partyId = << >> THEN << >> ELSE message.partyId[1])
        \o (IF message.partyRole = << >> THEN << >> ELSE message.partyRole[1])

DecodeTradeCaptureReportRejectV2TrdCapAckSideGrp(bytes, handedNumberOfReturnBitfields, handedTradeCaptureReportRejectV2ReturnBitfield1, handedTradeCaptureReportRejectV2ReturnBitfield2, handedTradeCaptureReportRejectV2ReturnBitfield3, handedTradeCaptureReportRejectV2ReturnBitfield4, handedTradeCaptureReportRejectV2ReturnBitfield6) ==
    LET side == ReadWhen(handedNumberOfReturnBitfields >= 1 /\ (handedTradeCaptureReportRejectV2ReturnBitfield1 # << >> /\ handedTradeCaptureReportRejectV2ReturnBitfield1[1] % 2 > 0), ReadBytes(bytes, 1), bytes) IN IF ~side.ok THEN Fail ELSE
    LET capacity == ReadWhen(handedNumberOfReturnBitfields >= 2 /\ (handedTradeCaptureReportRejectV2ReturnBitfield2 # << >> /\ (handedTradeCaptureReportRejectV2ReturnBitfield2[1] \div 64) % 2 > 0), ReadBytes(side.rest, 1), side.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadWhen(handedNumberOfReturnBitfields >= 3 /\ (handedTradeCaptureReportRejectV2ReturnBitfield3 # << >> /\ handedTradeCaptureReportRejectV2ReturnBitfield3[1] % 2 > 0), ReadBytes(capacity.rest, 16), capacity.rest) IN IF ~account.ok THEN Fail ELSE
    LET partyId == ReadWhen(handedNumberOfReturnBitfields >= 4 /\ (handedTradeCaptureReportRejectV2ReturnBitfield4 # << >> /\ (handedTradeCaptureReportRejectV2ReturnBitfield4[1] \div 64) % 2 > 0), ReadBytes(account.rest, 4), account.rest) IN IF ~partyId.ok THEN Fail ELSE
    LET partyRole == ReadWhen(handedNumberOfReturnBitfields >= 6 /\ (handedTradeCaptureReportRejectV2ReturnBitfield6 # << >> /\ (handedTradeCaptureReportRejectV2ReturnBitfield6[1] \div 128) % 2 > 0), ReadBytes(partyId.rest, 1), partyId.rest) IN IF ~partyRole.ok THEN Fail ELSE
    Ok([ side      |-> side.value,
         capacity  |-> capacity.value,
         account   |-> account.value,
         partyId   |-> partyId.value,
         partyRole |-> partyRole.value ], partyRole.rest)

(* Trade Capture Report Reject V 2 Trd Cap Ack Side Grp with each field marked present by fields before it there exactly where they say *)
SettleTradeCaptureReportRejectV2TrdCapAckSideGrp(message, handedNumberOfReturnBitfields, handedTradeCaptureReportRejectV2ReturnBitfield1, handedTradeCaptureReportRejectV2ReturnBitfield2, handedTradeCaptureReportRejectV2ReturnBitfield3, handedTradeCaptureReportRejectV2ReturnBitfield4, handedTradeCaptureReportRejectV2ReturnBitfield6) ==
    LET settled1 == [message EXCEPT !.side = IF handedNumberOfReturnBitfields >= 1 /\ (handedTradeCaptureReportRejectV2ReturnBitfield1 # << >> /\ handedTradeCaptureReportRejectV2ReturnBitfield1[1] % 2 > 0) THEN (IF message.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE message.side) ELSE << >>]
        settled2 == [settled1 EXCEPT !.capacity = IF handedNumberOfReturnBitfields >= 2 /\ (handedTradeCaptureReportRejectV2ReturnBitfield2 # << >> /\ (handedTradeCaptureReportRejectV2ReturnBitfield2[1] \div 64) % 2 > 0) THEN (IF settled1.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled1.capacity) ELSE << >>]
        settled3 == [settled2 EXCEPT !.account = IF handedNumberOfReturnBitfields >= 3 /\ (handedTradeCaptureReportRejectV2ReturnBitfield3 # << >> /\ handedTradeCaptureReportRejectV2ReturnBitfield3[1] % 2 > 0) THEN (IF settled2.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled2.account) ELSE << >>]
        settled4 == [settled3 EXCEPT !.partyId = IF handedNumberOfReturnBitfields >= 4 /\ (handedTradeCaptureReportRejectV2ReturnBitfield4 # << >> /\ (handedTradeCaptureReportRejectV2ReturnBitfield4[1] \div 64) % 2 > 0) THEN (IF settled3.partyId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled3.partyId) ELSE << >>]
        settled5 == [settled4 EXCEPT !.partyRole = IF handedNumberOfReturnBitfields >= 6 /\ (handedTradeCaptureReportRejectV2ReturnBitfield6 # << >> /\ (handedTradeCaptureReportRejectV2ReturnBitfield6[1] \div 128) % 2 > 0) THEN (IF settled4.partyRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled4.partyRole) ELSE << >>]
    IN  settled5

ZeroTradeCaptureReportRejectV2TrdCapAckSideGrp ==
    SettleTradeCaptureReportRejectV2TrdCapAckSideGrp([ side      |-> << >>,
                                                       capacity  |-> << >>,
                                                       account   |-> << >>,
                                                       partyId   |-> << >>,
                                                       partyRole |-> << >> ], 0, << >>, << >>, << >>, << >>, << >>)

(* Trade Capture Report Reject V 2 Trd Cap Ack Side Grp at zero, then each field in turn at the values it is checked at *)
CheckedTradeCaptureReportRejectV2TrdCapAckSideGrp ==
    { [given |-> <<0, << >>, << >>, << >>, << >>, << >>>>, message |-> ZeroTradeCaptureReportRejectV2TrdCapAckSideGrp] }
        \cup { [given |-> <<1, <<1>>, << >>, << >>, << >>, << >>>>, message |-> SettleTradeCaptureReportRejectV2TrdCapAckSideGrp([ZeroTradeCaptureReportRejectV2TrdCapAckSideGrp EXCEPT !.side = one], 1, <<1>>, << >>, << >>, << >>, << >>)] : one \in { <<held>> : held \in Sample(1) } }
        \cup { [given |-> <<2, << >>, <<64>>, << >>, << >>, << >>>>, message |-> SettleTradeCaptureReportRejectV2TrdCapAckSideGrp([ZeroTradeCaptureReportRejectV2TrdCapAckSideGrp EXCEPT !.capacity = one], 2, << >>, <<64>>, << >>, << >>, << >>)] : one \in { <<held>> : held \in Sample(1) } }
        \cup { [given |-> <<3, << >>, << >>, <<1>>, << >>, << >>>>, message |-> SettleTradeCaptureReportRejectV2TrdCapAckSideGrp([ZeroTradeCaptureReportRejectV2TrdCapAckSideGrp EXCEPT !.account = one], 3, << >>, << >>, <<1>>, << >>, << >>)] : one \in { <<held>> : held \in Sample(16) } }
        \cup { [given |-> <<4, << >>, << >>, << >>, <<64>>, << >>>>, message |-> SettleTradeCaptureReportRejectV2TrdCapAckSideGrp([ZeroTradeCaptureReportRejectV2TrdCapAckSideGrp EXCEPT !.partyId = one], 4, << >>, << >>, << >>, <<64>>, << >>)] : one \in { <<held>> : held \in Sample(4) } }
        \cup { [given |-> <<6, << >>, << >>, << >>, << >>, <<128>>>>, message |-> SettleTradeCaptureReportRejectV2TrdCapAckSideGrp([ZeroTradeCaptureReportRejectV2TrdCapAckSideGrp EXCEPT !.partyRole = one], 6, << >>, << >>, << >>, << >>, <<128>>)] : one \in { <<held>> : held \in Sample(1) } }

(* A run of Trade Capture Report Reject V 2 Trd Cap Ack Side Grp, written one after another *)
RECURSIVE EncodeTradeCaptureReportRejectV2TrdCapAckSideGrpList(_)
EncodeTradeCaptureReportRejectV2TrdCapAckSideGrpList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTradeCaptureReportRejectV2TrdCapAckSideGrp(Head(messages)) \o EncodeTradeCaptureReportRejectV2TrdCapAckSideGrpList(Tail(messages))

(* As many Trade Capture Report Reject V 2 Trd Cap Ack Side Grp as the field that counts them says *)
RECURSIVE ReadTradeCaptureReportRejectV2TrdCapAckSideGrpList(_, _, _, _, _, _, _, _)
ReadTradeCaptureReportRejectV2TrdCapAckSideGrpList(bytes, count, handedNumberOfReturnBitfields, handedTradeCaptureReportRejectV2ReturnBitfield1, handedTradeCaptureReportRejectV2ReturnBitfield2, handedTradeCaptureReportRejectV2ReturnBitfield3, handedTradeCaptureReportRejectV2ReturnBitfield4, handedTradeCaptureReportRejectV2ReturnBitfield6) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeTradeCaptureReportRejectV2TrdCapAckSideGrp(bytes, handedNumberOfReturnBitfields, handedTradeCaptureReportRejectV2ReturnBitfield1, handedTradeCaptureReportRejectV2ReturnBitfield2, handedTradeCaptureReportRejectV2ReturnBitfield3, handedTradeCaptureReportRejectV2ReturnBitfield4, handedTradeCaptureReportRejectV2ReturnBitfield6)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTradeCaptureReportRejectV2TrdCapAckSideGrpList(one.rest, count - 1, handedNumberOfReturnBitfields, handedTradeCaptureReportRejectV2ReturnBitfield1, handedTradeCaptureReportRejectV2ReturnBitfield2, handedTradeCaptureReportRejectV2ReturnBitfield3, handedTradeCaptureReportRejectV2ReturnBitfield4, handedTradeCaptureReportRejectV2ReturnBitfield6)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Trade Capture Report Reject V 2 Trd Cap Ack Side Grp of each kind, for the lists that carry them *)
OneTradeCaptureReportRejectV2TrdCapAckSideGrp == { ZeroTradeCaptureReportRejectV2TrdCapAckSideGrp }

(***************************************************************************)
(* Trade Capture Report Reject V 2 Message                                 *)
(***************************************************************************)

TradeCaptureReportRejectV2Message ==
    [ transactionTime                            : Sample(8),
      tradeReportId                              : Sample(20),
      reason                                     : Sample(1),
      text                                       : Sample(60),
      reserved1                                  : Sample(1),
      numberOfReturnBitfields                    : 0 .. 255,
      tradeCaptureReportRejectV2ReturnBitfield1  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCaptureReportRejectV2ReturnBitfield2  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCaptureReportRejectV2ReturnBitfield3  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCaptureReportRejectV2ReturnBitfield4  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCaptureReportRejectV2ReturnBitfield5  : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCaptureReportRejectV2ReturnBitfield6  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCaptureReportRejectV2ReturnBitfield7  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCaptureReportRejectV2ReturnBitfield8  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCaptureReportRejectV2ReturnBitfield9  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCaptureReportRejectV2ReturnBitfield10 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCaptureReportRejectV2ReturnBitfield11 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCaptureReportRejectV2ReturnBitfield12 : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCaptureReportRejectV2ReturnBitfield13 : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCaptureReportRejectV2ReturnBitfield14 : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCaptureReportRejectV2TrdCapAckSideGrp : SampleLists(OneTradeCaptureReportRejectV2TrdCapAckSideGrp),
      execInst                                   : { << >> } \cup { <<held>> : held \in Sample(1) },
      symbol                                     : { << >> } \cup { <<held>> : held \in Sample(8) },
      currency                                   : { << >> } \cup { <<held>> : held \in Sample(3) },
      idSource                                   : { << >> } \cup { <<held>> : held \in Sample(1) },
      securityId                                 : { << >> } \cup { <<held>> : held \in Sample(16) },
      securityExchange                           : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingFirm                               : { << >> } \cup { <<held>> : held \in Sample(4) },
      orderQty                                   : { << >> } \cup { <<held>> : held \in Sample(4) },
      tradeReportTypeReturn                      : { << >> } \cup { <<held>> : held \in Sample(2) },
      tradePublishIndicator                      : { << >> } \cup { <<held>> : held \in Sample(1) },
      rptTime                                    : { << >> } \cup { <<held>> : held \in Sample(8) },
      largeSize                                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      lastMkt                                    : { << >> } \cup { <<held>> : held \in Sample(4) },
      echoText                                   : { << >> } \cup { <<held>> : held \in Sample(64) },
      liquidityProvision                         : { << >> } \cup { <<held>> : held \in Sample(1) },
      waiverType                                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      priceFormation                             : { << >> } \cup { <<held>> : held \in Sample(1) },
      clientQualifiedRole                        : { << >> } \cup { <<held>> : held \in Sample(1) },
      clientId                                   : { << >> } \cup { <<held>> : held \in Sample(4) },
      investorId                                 : { << >> } \cup { <<held>> : held \in Sample(4) },
      executorId                                 : { << >> } \cup { <<held>> : held \in Sample(4) },
      orderOrigination                           : { << >> } \cup { <<held>> : held \in Sample(1) },
      algorithmicIndicator                       : { << >> } \cup { <<held>> : held \in Sample(1) },
      investorQualifiedRole                      : { << >> } \cup { <<held>> : held \in Sample(1) },
      executorQualifiedRole                      : { << >> } \cup { <<held>> : held \in Sample(1) } ]

EncodeTradeCaptureReportRejectV2Message(message) ==
    message.transactionTime
        \o message.tradeReportId
        \o message.reason
        \o message.text
        \o message.reserved1
        \o EncodeUIntBE(message.numberOfReturnBitfields, 1)
        \o (IF message.tradeCaptureReportRejectV2ReturnBitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCaptureReportRejectV2ReturnBitfield1[1], 1))
        \o (IF message.tradeCaptureReportRejectV2ReturnBitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCaptureReportRejectV2ReturnBitfield2[1], 1))
        \o (IF message.tradeCaptureReportRejectV2ReturnBitfield3 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCaptureReportRejectV2ReturnBitfield3[1], 1))
        \o (IF message.tradeCaptureReportRejectV2ReturnBitfield4 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCaptureReportRejectV2ReturnBitfield4[1], 1))
        \o (IF message.tradeCaptureReportRejectV2ReturnBitfield5 = << >> THEN << >> ELSE message.tradeCaptureReportRejectV2ReturnBitfield5[1])
        \o (IF message.tradeCaptureReportRejectV2ReturnBitfield6 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCaptureReportRejectV2ReturnBitfield6[1], 1))
        \o (IF message.tradeCaptureReportRejectV2ReturnBitfield7 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCaptureReportRejectV2ReturnBitfield7[1], 1))
        \o (IF message.tradeCaptureReportRejectV2ReturnBitfield8 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCaptureReportRejectV2ReturnBitfield8[1], 1))
        \o (IF message.tradeCaptureReportRejectV2ReturnBitfield9 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCaptureReportRejectV2ReturnBitfield9[1], 1))
        \o (IF message.tradeCaptureReportRejectV2ReturnBitfield10 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCaptureReportRejectV2ReturnBitfield10[1], 1))
        \o (IF message.tradeCaptureReportRejectV2ReturnBitfield11 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCaptureReportRejectV2ReturnBitfield11[1], 1))
        \o (IF message.tradeCaptureReportRejectV2ReturnBitfield12 = << >> THEN << >> ELSE message.tradeCaptureReportRejectV2ReturnBitfield12[1])
        \o (IF message.tradeCaptureReportRejectV2ReturnBitfield13 = << >> THEN << >> ELSE message.tradeCaptureReportRejectV2ReturnBitfield13[1])
        \o (IF message.tradeCaptureReportRejectV2ReturnBitfield14 = << >> THEN << >> ELSE message.tradeCaptureReportRejectV2ReturnBitfield14[1])
        \o EncodeUIntBE(Len(message.tradeCaptureReportRejectV2TrdCapAckSideGrp), 1)
        \o EncodeTradeCaptureReportRejectV2TrdCapAckSideGrpList(message.tradeCaptureReportRejectV2TrdCapAckSideGrp)
        \o (IF message.execInst = << >> THEN << >> ELSE message.execInst[1])
        \o (IF message.symbol = << >> THEN << >> ELSE message.symbol[1])
        \o (IF message.currency = << >> THEN << >> ELSE message.currency[1])
        \o (IF message.idSource = << >> THEN << >> ELSE message.idSource[1])
        \o (IF message.securityId = << >> THEN << >> ELSE message.securityId[1])
        \o (IF message.securityExchange = << >> THEN << >> ELSE message.securityExchange[1])
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])
        \o (IF message.orderQty = << >> THEN << >> ELSE message.orderQty[1])
        \o (IF message.tradeReportTypeReturn = << >> THEN << >> ELSE message.tradeReportTypeReturn[1])
        \o (IF message.tradePublishIndicator = << >> THEN << >> ELSE message.tradePublishIndicator[1])
        \o (IF message.rptTime = << >> THEN << >> ELSE message.rptTime[1])
        \o (IF message.largeSize = << >> THEN << >> ELSE message.largeSize[1])
        \o (IF message.lastMkt = << >> THEN << >> ELSE message.lastMkt[1])
        \o (IF message.echoText = << >> THEN << >> ELSE message.echoText[1])
        \o (IF message.liquidityProvision = << >> THEN << >> ELSE message.liquidityProvision[1])
        \o (IF message.waiverType = << >> THEN << >> ELSE message.waiverType[1])
        \o (IF message.priceFormation = << >> THEN << >> ELSE message.priceFormation[1])
        \o (IF message.clientQualifiedRole = << >> THEN << >> ELSE message.clientQualifiedRole[1])
        \o (IF message.clientId = << >> THEN << >> ELSE message.clientId[1])
        \o (IF message.investorId = << >> THEN << >> ELSE message.investorId[1])
        \o (IF message.executorId = << >> THEN << >> ELSE message.executorId[1])
        \o (IF message.orderOrigination = << >> THEN << >> ELSE message.orderOrigination[1])
        \o (IF message.algorithmicIndicator = << >> THEN << >> ELSE message.algorithmicIndicator[1])
        \o (IF message.investorQualifiedRole = << >> THEN << >> ELSE message.investorQualifiedRole[1])
        \o (IF message.executorQualifiedRole = << >> THEN << >> ELSE message.executorQualifiedRole[1])

DecodeTradeCaptureReportRejectV2Message(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(transactionTime.rest, 20) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET reason == ReadBytes(tradeReportId.rest, 1) IN IF ~reason.ok THEN Fail ELSE
    LET text == ReadBytes(reason.rest, 60) IN IF ~text.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(text.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET numberOfReturnBitfields == ReadUIntBE(reserved1.rest, 1) IN IF ~numberOfReturnBitfields.ok THEN Fail ELSE
    LET tradeCaptureReportRejectV2ReturnBitfield1 == ReadWhen(numberOfReturnBitfields.value >= 1, ReadUIntLE(numberOfReturnBitfields.rest, 1), numberOfReturnBitfields.rest) IN IF ~tradeCaptureReportRejectV2ReturnBitfield1.ok THEN Fail ELSE
    LET tradeCaptureReportRejectV2ReturnBitfield2 == ReadWhen(numberOfReturnBitfields.value >= 2, ReadUIntLE(tradeCaptureReportRejectV2ReturnBitfield1.rest, 1), tradeCaptureReportRejectV2ReturnBitfield1.rest) IN IF ~tradeCaptureReportRejectV2ReturnBitfield2.ok THEN Fail ELSE
    LET tradeCaptureReportRejectV2ReturnBitfield3 == ReadWhen(numberOfReturnBitfields.value >= 3, ReadUIntLE(tradeCaptureReportRejectV2ReturnBitfield2.rest, 1), tradeCaptureReportRejectV2ReturnBitfield2.rest) IN IF ~tradeCaptureReportRejectV2ReturnBitfield3.ok THEN Fail ELSE
    LET tradeCaptureReportRejectV2ReturnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadUIntLE(tradeCaptureReportRejectV2ReturnBitfield3.rest, 1), tradeCaptureReportRejectV2ReturnBitfield3.rest) IN IF ~tradeCaptureReportRejectV2ReturnBitfield4.ok THEN Fail ELSE
    LET tradeCaptureReportRejectV2ReturnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadBytes(tradeCaptureReportRejectV2ReturnBitfield4.rest, 1), tradeCaptureReportRejectV2ReturnBitfield4.rest) IN IF ~tradeCaptureReportRejectV2ReturnBitfield5.ok THEN Fail ELSE
    LET tradeCaptureReportRejectV2ReturnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadUIntLE(tradeCaptureReportRejectV2ReturnBitfield5.rest, 1), tradeCaptureReportRejectV2ReturnBitfield5.rest) IN IF ~tradeCaptureReportRejectV2ReturnBitfield6.ok THEN Fail ELSE
    LET tradeCaptureReportRejectV2ReturnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadUIntLE(tradeCaptureReportRejectV2ReturnBitfield6.rest, 1), tradeCaptureReportRejectV2ReturnBitfield6.rest) IN IF ~tradeCaptureReportRejectV2ReturnBitfield7.ok THEN Fail ELSE
    LET tradeCaptureReportRejectV2ReturnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadUIntLE(tradeCaptureReportRejectV2ReturnBitfield7.rest, 1), tradeCaptureReportRejectV2ReturnBitfield7.rest) IN IF ~tradeCaptureReportRejectV2ReturnBitfield8.ok THEN Fail ELSE
    LET tradeCaptureReportRejectV2ReturnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadUIntLE(tradeCaptureReportRejectV2ReturnBitfield8.rest, 1), tradeCaptureReportRejectV2ReturnBitfield8.rest) IN IF ~tradeCaptureReportRejectV2ReturnBitfield9.ok THEN Fail ELSE
    LET tradeCaptureReportRejectV2ReturnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadUIntLE(tradeCaptureReportRejectV2ReturnBitfield9.rest, 1), tradeCaptureReportRejectV2ReturnBitfield9.rest) IN IF ~tradeCaptureReportRejectV2ReturnBitfield10.ok THEN Fail ELSE
    LET tradeCaptureReportRejectV2ReturnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadUIntLE(tradeCaptureReportRejectV2ReturnBitfield10.rest, 1), tradeCaptureReportRejectV2ReturnBitfield10.rest) IN IF ~tradeCaptureReportRejectV2ReturnBitfield11.ok THEN Fail ELSE
    LET tradeCaptureReportRejectV2ReturnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadBytes(tradeCaptureReportRejectV2ReturnBitfield11.rest, 1), tradeCaptureReportRejectV2ReturnBitfield11.rest) IN IF ~tradeCaptureReportRejectV2ReturnBitfield12.ok THEN Fail ELSE
    LET tradeCaptureReportRejectV2ReturnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(tradeCaptureReportRejectV2ReturnBitfield12.rest, 1), tradeCaptureReportRejectV2ReturnBitfield12.rest) IN IF ~tradeCaptureReportRejectV2ReturnBitfield13.ok THEN Fail ELSE
    LET tradeCaptureReportRejectV2ReturnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(tradeCaptureReportRejectV2ReturnBitfield13.rest, 1), tradeCaptureReportRejectV2ReturnBitfield13.rest) IN IF ~tradeCaptureReportRejectV2ReturnBitfield14.ok THEN Fail ELSE
    LET noSides == ReadUIntBE(tradeCaptureReportRejectV2ReturnBitfield14.rest, 1) IN IF ~noSides.ok THEN Fail ELSE
    LET tradeCaptureReportRejectV2TrdCapAckSideGrp == ReadTradeCaptureReportRejectV2TrdCapAckSideGrpList(noSides.rest, noSides.value, numberOfReturnBitfields.value, tradeCaptureReportRejectV2ReturnBitfield1.value, tradeCaptureReportRejectV2ReturnBitfield2.value, tradeCaptureReportRejectV2ReturnBitfield3.value, tradeCaptureReportRejectV2ReturnBitfield4.value, tradeCaptureReportRejectV2ReturnBitfield6.value) IN IF ~tradeCaptureReportRejectV2TrdCapAckSideGrp.ok THEN Fail ELSE
    LET execInst == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (tradeCaptureReportRejectV2ReturnBitfield1.value # << >> /\ (tradeCaptureReportRejectV2ReturnBitfield1.value[1] \div 8) % 2 > 0), ReadBytes(tradeCaptureReportRejectV2TrdCapAckSideGrp.rest, 1), tradeCaptureReportRejectV2TrdCapAckSideGrp.rest) IN IF ~execInst.ok THEN Fail ELSE
    LET symbol == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (tradeCaptureReportRejectV2ReturnBitfield2.value # << >> /\ tradeCaptureReportRejectV2ReturnBitfield2.value[1] % 2 > 0), ReadBytes(execInst.rest, 8), execInst.rest) IN IF ~symbol.ok THEN Fail ELSE
    LET currency == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (tradeCaptureReportRejectV2ReturnBitfield2.value # << >> /\ (tradeCaptureReportRejectV2ReturnBitfield2.value[1] \div 4) % 2 > 0), ReadBytes(symbol.rest, 3), symbol.rest) IN IF ~currency.ok THEN Fail ELSE
    LET idSource == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (tradeCaptureReportRejectV2ReturnBitfield2.value # << >> /\ (tradeCaptureReportRejectV2ReturnBitfield2.value[1] \div 8) % 2 > 0), ReadBytes(currency.rest, 1), currency.rest) IN IF ~idSource.ok THEN Fail ELSE
    LET securityId == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (tradeCaptureReportRejectV2ReturnBitfield2.value # << >> /\ (tradeCaptureReportRejectV2ReturnBitfield2.value[1] \div 16) % 2 > 0), ReadBytes(idSource.rest, 16), idSource.rest) IN IF ~securityId.ok THEN Fail ELSE
    LET securityExchange == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (tradeCaptureReportRejectV2ReturnBitfield2.value # << >> /\ (tradeCaptureReportRejectV2ReturnBitfield2.value[1] \div 32) % 2 > 0), ReadBytes(securityId.rest, 4), securityId.rest) IN IF ~securityExchange.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (tradeCaptureReportRejectV2ReturnBitfield3.value # << >> /\ (tradeCaptureReportRejectV2ReturnBitfield3.value[1] \div 2) % 2 > 0), ReadBytes(securityExchange.rest, 4), securityExchange.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET orderQty == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (tradeCaptureReportRejectV2ReturnBitfield3.value # << >> /\ (tradeCaptureReportRejectV2ReturnBitfield3.value[1] \div 64) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~orderQty.ok THEN Fail ELSE
    LET tradeReportTypeReturn == ReadWhen(numberOfReturnBitfields.value >= 7 /\ (tradeCaptureReportRejectV2ReturnBitfield7.value # << >> /\ (tradeCaptureReportRejectV2ReturnBitfield7.value[1] \div 2) % 2 > 0), ReadBytes(orderQty.rest, 2), orderQty.rest) IN IF ~tradeReportTypeReturn.ok THEN Fail ELSE
    LET tradePublishIndicator == ReadWhen(numberOfReturnBitfields.value >= 7 /\ (tradeCaptureReportRejectV2ReturnBitfield7.value # << >> /\ (tradeCaptureReportRejectV2ReturnBitfield7.value[1] \div 4) % 2 > 0), ReadBytes(tradeReportTypeReturn.rest, 1), tradeReportTypeReturn.rest) IN IF ~tradePublishIndicator.ok THEN Fail ELSE
    LET rptTime == ReadWhen(numberOfReturnBitfields.value >= 7 /\ (tradeCaptureReportRejectV2ReturnBitfield7.value # << >> /\ (tradeCaptureReportRejectV2ReturnBitfield7.value[1] \div 4) % 2 > 0), ReadBytes(tradePublishIndicator.rest, 8), tradePublishIndicator.rest) IN IF ~rptTime.ok THEN Fail ELSE
    LET largeSize == ReadWhen(numberOfReturnBitfields.value >= 7 /\ (tradeCaptureReportRejectV2ReturnBitfield7.value # << >> /\ (tradeCaptureReportRejectV2ReturnBitfield7.value[1] \div 64) % 2 > 0), ReadBytes(rptTime.rest, 8), rptTime.rest) IN IF ~largeSize.ok THEN Fail ELSE
    LET lastMkt == ReadWhen(numberOfReturnBitfields.value >= 7 /\ (tradeCaptureReportRejectV2ReturnBitfield7.value # << >> /\ (tradeCaptureReportRejectV2ReturnBitfield7.value[1] \div 128) % 2 > 0), ReadBytes(largeSize.rest, 4), largeSize.rest) IN IF ~lastMkt.ok THEN Fail ELSE
    LET echoText == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (tradeCaptureReportRejectV2ReturnBitfield8.value # << >> /\ (tradeCaptureReportRejectV2ReturnBitfield8.value[1] \div 2) % 2 > 0), ReadBytes(lastMkt.rest, 64), lastMkt.rest) IN IF ~echoText.ok THEN Fail ELSE
    LET liquidityProvision == ReadWhen(numberOfReturnBitfields.value >= 9 /\ (tradeCaptureReportRejectV2ReturnBitfield9.value # << >> /\ (tradeCaptureReportRejectV2ReturnBitfield9.value[1] \div 16) % 2 > 0), ReadBytes(echoText.rest, 1), echoText.rest) IN IF ~liquidityProvision.ok THEN Fail ELSE
    LET waiverType == ReadWhen(numberOfReturnBitfields.value >= 10 /\ (tradeCaptureReportRejectV2ReturnBitfield10.value # << >> /\ (tradeCaptureReportRejectV2ReturnBitfield10.value[1] \div 16) % 2 > 0), ReadBytes(liquidityProvision.rest, 1), liquidityProvision.rest) IN IF ~waiverType.ok THEN Fail ELSE
    LET priceFormation == ReadWhen(numberOfReturnBitfields.value >= 10 /\ (tradeCaptureReportRejectV2ReturnBitfield10.value # << >> /\ (tradeCaptureReportRejectV2ReturnBitfield10.value[1] \div 64) % 2 > 0), ReadBytes(waiverType.rest, 1), waiverType.rest) IN IF ~priceFormation.ok THEN Fail ELSE
    LET clientQualifiedRole == ReadWhen(numberOfReturnBitfields.value >= 10 /\ (tradeCaptureReportRejectV2ReturnBitfield10.value # << >> /\ (tradeCaptureReportRejectV2ReturnBitfield10.value[1] \div 128) % 2 > 0), ReadBytes(priceFormation.rest, 1), priceFormation.rest) IN IF ~clientQualifiedRole.ok THEN Fail ELSE
    LET clientId == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (tradeCaptureReportRejectV2ReturnBitfield11.value # << >> /\ tradeCaptureReportRejectV2ReturnBitfield11.value[1] % 2 > 0), ReadBytes(clientQualifiedRole.rest, 4), clientQualifiedRole.rest) IN IF ~clientId.ok THEN Fail ELSE
    LET investorId == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (tradeCaptureReportRejectV2ReturnBitfield11.value # << >> /\ (tradeCaptureReportRejectV2ReturnBitfield11.value[1] \div 2) % 2 > 0), ReadBytes(clientId.rest, 4), clientId.rest) IN IF ~investorId.ok THEN Fail ELSE
    LET executorId == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (tradeCaptureReportRejectV2ReturnBitfield11.value # << >> /\ (tradeCaptureReportRejectV2ReturnBitfield11.value[1] \div 4) % 2 > 0), ReadBytes(investorId.rest, 4), investorId.rest) IN IF ~executorId.ok THEN Fail ELSE
    LET orderOrigination == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (tradeCaptureReportRejectV2ReturnBitfield11.value # << >> /\ (tradeCaptureReportRejectV2ReturnBitfield11.value[1] \div 8) % 2 > 0), ReadBytes(executorId.rest, 1), executorId.rest) IN IF ~orderOrigination.ok THEN Fail ELSE
    LET algorithmicIndicator == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (tradeCaptureReportRejectV2ReturnBitfield11.value # << >> /\ (tradeCaptureReportRejectV2ReturnBitfield11.value[1] \div 16) % 2 > 0), ReadBytes(orderOrigination.rest, 1), orderOrigination.rest) IN IF ~algorithmicIndicator.ok THEN Fail ELSE
    LET investorQualifiedRole == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (tradeCaptureReportRejectV2ReturnBitfield11.value # << >> /\ (tradeCaptureReportRejectV2ReturnBitfield11.value[1] \div 64) % 2 > 0), ReadBytes(algorithmicIndicator.rest, 1), algorithmicIndicator.rest) IN IF ~investorQualifiedRole.ok THEN Fail ELSE
    LET executorQualifiedRole == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (tradeCaptureReportRejectV2ReturnBitfield11.value # << >> /\ (tradeCaptureReportRejectV2ReturnBitfield11.value[1] \div 128) % 2 > 0), ReadBytes(investorQualifiedRole.rest, 1), investorQualifiedRole.rest) IN IF ~executorQualifiedRole.ok THEN Fail ELSE
    Ok([ transactionTime                            |-> transactionTime.value,
         tradeReportId                              |-> tradeReportId.value,
         reason                                     |-> reason.value,
         text                                       |-> text.value,
         reserved1                                  |-> reserved1.value,
         numberOfReturnBitfields                    |-> numberOfReturnBitfields.value,
         tradeCaptureReportRejectV2ReturnBitfield1  |-> tradeCaptureReportRejectV2ReturnBitfield1.value,
         tradeCaptureReportRejectV2ReturnBitfield2  |-> tradeCaptureReportRejectV2ReturnBitfield2.value,
         tradeCaptureReportRejectV2ReturnBitfield3  |-> tradeCaptureReportRejectV2ReturnBitfield3.value,
         tradeCaptureReportRejectV2ReturnBitfield4  |-> tradeCaptureReportRejectV2ReturnBitfield4.value,
         tradeCaptureReportRejectV2ReturnBitfield5  |-> tradeCaptureReportRejectV2ReturnBitfield5.value,
         tradeCaptureReportRejectV2ReturnBitfield6  |-> tradeCaptureReportRejectV2ReturnBitfield6.value,
         tradeCaptureReportRejectV2ReturnBitfield7  |-> tradeCaptureReportRejectV2ReturnBitfield7.value,
         tradeCaptureReportRejectV2ReturnBitfield8  |-> tradeCaptureReportRejectV2ReturnBitfield8.value,
         tradeCaptureReportRejectV2ReturnBitfield9  |-> tradeCaptureReportRejectV2ReturnBitfield9.value,
         tradeCaptureReportRejectV2ReturnBitfield10 |-> tradeCaptureReportRejectV2ReturnBitfield10.value,
         tradeCaptureReportRejectV2ReturnBitfield11 |-> tradeCaptureReportRejectV2ReturnBitfield11.value,
         tradeCaptureReportRejectV2ReturnBitfield12 |-> tradeCaptureReportRejectV2ReturnBitfield12.value,
         tradeCaptureReportRejectV2ReturnBitfield13 |-> tradeCaptureReportRejectV2ReturnBitfield13.value,
         tradeCaptureReportRejectV2ReturnBitfield14 |-> tradeCaptureReportRejectV2ReturnBitfield14.value,
         tradeCaptureReportRejectV2TrdCapAckSideGrp |-> tradeCaptureReportRejectV2TrdCapAckSideGrp.value,
         execInst                                   |-> execInst.value,
         symbol                                     |-> symbol.value,
         currency                                   |-> currency.value,
         idSource                                   |-> idSource.value,
         securityId                                 |-> securityId.value,
         securityExchange                           |-> securityExchange.value,
         clearingFirm                               |-> clearingFirm.value,
         orderQty                                   |-> orderQty.value,
         tradeReportTypeReturn                      |-> tradeReportTypeReturn.value,
         tradePublishIndicator                      |-> tradePublishIndicator.value,
         rptTime                                    |-> rptTime.value,
         largeSize                                  |-> largeSize.value,
         lastMkt                                    |-> lastMkt.value,
         echoText                                   |-> echoText.value,
         liquidityProvision                         |-> liquidityProvision.value,
         waiverType                                 |-> waiverType.value,
         priceFormation                             |-> priceFormation.value,
         clientQualifiedRole                        |-> clientQualifiedRole.value,
         clientId                                   |-> clientId.value,
         investorId                                 |-> investorId.value,
         executorId                                 |-> executorId.value,
         orderOrigination                           |-> orderOrigination.value,
         algorithmicIndicator                       |-> algorithmicIndicator.value,
         investorQualifiedRole                      |-> investorQualifiedRole.value,
         executorQualifiedRole                      |-> executorQualifiedRole.value ], executorQualifiedRole.rest)

(* Trade Capture Report Reject V 2 Message with each field marked present by fields before it there exactly where they say *)
SettleTradeCaptureReportRejectV2Message(message) ==
    LET settled1 == [message EXCEPT !.tradeCaptureReportRejectV2ReturnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.tradeCaptureReportRejectV2ReturnBitfield1 = << >> THEN <<0>> ELSE message.tradeCaptureReportRejectV2ReturnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.tradeCaptureReportRejectV2ReturnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.tradeCaptureReportRejectV2ReturnBitfield2 = << >> THEN <<0>> ELSE settled1.tradeCaptureReportRejectV2ReturnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.tradeCaptureReportRejectV2ReturnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.tradeCaptureReportRejectV2ReturnBitfield3 = << >> THEN <<0>> ELSE settled2.tradeCaptureReportRejectV2ReturnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.tradeCaptureReportRejectV2ReturnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.tradeCaptureReportRejectV2ReturnBitfield4 = << >> THEN <<0>> ELSE settled3.tradeCaptureReportRejectV2ReturnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.tradeCaptureReportRejectV2ReturnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.tradeCaptureReportRejectV2ReturnBitfield5 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled4.tradeCaptureReportRejectV2ReturnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.tradeCaptureReportRejectV2ReturnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.tradeCaptureReportRejectV2ReturnBitfield6 = << >> THEN <<0>> ELSE settled5.tradeCaptureReportRejectV2ReturnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.tradeCaptureReportRejectV2ReturnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.tradeCaptureReportRejectV2ReturnBitfield7 = << >> THEN <<0>> ELSE settled6.tradeCaptureReportRejectV2ReturnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.tradeCaptureReportRejectV2ReturnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.tradeCaptureReportRejectV2ReturnBitfield8 = << >> THEN <<0>> ELSE settled7.tradeCaptureReportRejectV2ReturnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.tradeCaptureReportRejectV2ReturnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.tradeCaptureReportRejectV2ReturnBitfield9 = << >> THEN <<0>> ELSE settled8.tradeCaptureReportRejectV2ReturnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.tradeCaptureReportRejectV2ReturnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.tradeCaptureReportRejectV2ReturnBitfield10 = << >> THEN <<0>> ELSE settled9.tradeCaptureReportRejectV2ReturnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.tradeCaptureReportRejectV2ReturnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.tradeCaptureReportRejectV2ReturnBitfield11 = << >> THEN <<0>> ELSE settled10.tradeCaptureReportRejectV2ReturnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.tradeCaptureReportRejectV2ReturnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.tradeCaptureReportRejectV2ReturnBitfield12 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.tradeCaptureReportRejectV2ReturnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.tradeCaptureReportRejectV2ReturnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.tradeCaptureReportRejectV2ReturnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.tradeCaptureReportRejectV2ReturnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.tradeCaptureReportRejectV2ReturnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.tradeCaptureReportRejectV2ReturnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.tradeCaptureReportRejectV2ReturnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.tradeCaptureReportRejectV2TrdCapAckSideGrp = [i \in DOMAIN settled14.tradeCaptureReportRejectV2TrdCapAckSideGrp |-> SettleTradeCaptureReportRejectV2TrdCapAckSideGrp(settled14.tradeCaptureReportRejectV2TrdCapAckSideGrp[i], settled14.numberOfReturnBitfields, settled14.tradeCaptureReportRejectV2ReturnBitfield1, settled14.tradeCaptureReportRejectV2ReturnBitfield2, settled14.tradeCaptureReportRejectV2ReturnBitfield3, settled14.tradeCaptureReportRejectV2ReturnBitfield4, settled14.tradeCaptureReportRejectV2ReturnBitfield6)]]
        settled16 == [settled15 EXCEPT !.execInst = IF settled15.numberOfReturnBitfields >= 1 /\ (settled15.tradeCaptureReportRejectV2ReturnBitfield1 # << >> /\ (settled15.tradeCaptureReportRejectV2ReturnBitfield1[1] \div 8) % 2 > 0) THEN (IF settled15.execInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled15.execInst) ELSE << >>]
        settled17 == [settled16 EXCEPT !.symbol = IF settled16.numberOfReturnBitfields >= 2 /\ (settled16.tradeCaptureReportRejectV2ReturnBitfield2 # << >> /\ settled16.tradeCaptureReportRejectV2ReturnBitfield2[1] % 2 > 0) THEN (IF settled16.symbol = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled16.symbol) ELSE << >>]
        settled18 == [settled17 EXCEPT !.currency = IF settled17.numberOfReturnBitfields >= 2 /\ (settled17.tradeCaptureReportRejectV2ReturnBitfield2 # << >> /\ (settled17.tradeCaptureReportRejectV2ReturnBitfield2[1] \div 4) % 2 > 0) THEN (IF settled17.currency = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled17.currency) ELSE << >>]
        settled19 == [settled18 EXCEPT !.idSource = IF settled18.numberOfReturnBitfields >= 2 /\ (settled18.tradeCaptureReportRejectV2ReturnBitfield2 # << >> /\ (settled18.tradeCaptureReportRejectV2ReturnBitfield2[1] \div 8) % 2 > 0) THEN (IF settled18.idSource = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled18.idSource) ELSE << >>]
        settled20 == [settled19 EXCEPT !.securityId = IF settled19.numberOfReturnBitfields >= 2 /\ (settled19.tradeCaptureReportRejectV2ReturnBitfield2 # << >> /\ (settled19.tradeCaptureReportRejectV2ReturnBitfield2[1] \div 16) % 2 > 0) THEN (IF settled19.securityId = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled19.securityId) ELSE << >>]
        settled21 == [settled20 EXCEPT !.securityExchange = IF settled20.numberOfReturnBitfields >= 2 /\ (settled20.tradeCaptureReportRejectV2ReturnBitfield2 # << >> /\ (settled20.tradeCaptureReportRejectV2ReturnBitfield2[1] \div 32) % 2 > 0) THEN (IF settled20.securityExchange = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled20.securityExchange) ELSE << >>]
        settled22 == [settled21 EXCEPT !.clearingFirm = IF settled21.numberOfReturnBitfields >= 3 /\ (settled21.tradeCaptureReportRejectV2ReturnBitfield3 # << >> /\ (settled21.tradeCaptureReportRejectV2ReturnBitfield3[1] \div 2) % 2 > 0) THEN (IF settled21.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled21.clearingFirm) ELSE << >>]
        settled23 == [settled22 EXCEPT !.orderQty = IF settled22.numberOfReturnBitfields >= 3 /\ (settled22.tradeCaptureReportRejectV2ReturnBitfield3 # << >> /\ (settled22.tradeCaptureReportRejectV2ReturnBitfield3[1] \div 64) % 2 > 0) THEN (IF settled22.orderQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled22.orderQty) ELSE << >>]
        settled24 == [settled23 EXCEPT !.tradeReportTypeReturn = IF settled23.numberOfReturnBitfields >= 7 /\ (settled23.tradeCaptureReportRejectV2ReturnBitfield7 # << >> /\ (settled23.tradeCaptureReportRejectV2ReturnBitfield7[1] \div 2) % 2 > 0) THEN (IF settled23.tradeReportTypeReturn = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled23.tradeReportTypeReturn) ELSE << >>]
        settled25 == [settled24 EXCEPT !.tradePublishIndicator = IF settled24.numberOfReturnBitfields >= 7 /\ (settled24.tradeCaptureReportRejectV2ReturnBitfield7 # << >> /\ (settled24.tradeCaptureReportRejectV2ReturnBitfield7[1] \div 4) % 2 > 0) THEN (IF settled24.tradePublishIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled24.tradePublishIndicator) ELSE << >>]
        settled26 == [settled25 EXCEPT !.rptTime = IF settled25.numberOfReturnBitfields >= 7 /\ (settled25.tradeCaptureReportRejectV2ReturnBitfield7 # << >> /\ (settled25.tradeCaptureReportRejectV2ReturnBitfield7[1] \div 4) % 2 > 0) THEN (IF settled25.rptTime = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled25.rptTime) ELSE << >>]
        settled27 == [settled26 EXCEPT !.largeSize = IF settled26.numberOfReturnBitfields >= 7 /\ (settled26.tradeCaptureReportRejectV2ReturnBitfield7 # << >> /\ (settled26.tradeCaptureReportRejectV2ReturnBitfield7[1] \div 64) % 2 > 0) THEN (IF settled26.largeSize = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled26.largeSize) ELSE << >>]
        settled28 == [settled27 EXCEPT !.lastMkt = IF settled27.numberOfReturnBitfields >= 7 /\ (settled27.tradeCaptureReportRejectV2ReturnBitfield7 # << >> /\ (settled27.tradeCaptureReportRejectV2ReturnBitfield7[1] \div 128) % 2 > 0) THEN (IF settled27.lastMkt = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled27.lastMkt) ELSE << >>]
        settled29 == [settled28 EXCEPT !.echoText = IF settled28.numberOfReturnBitfields >= 8 /\ (settled28.tradeCaptureReportRejectV2ReturnBitfield8 # << >> /\ (settled28.tradeCaptureReportRejectV2ReturnBitfield8[1] \div 2) % 2 > 0) THEN (IF settled28.echoText = << >> THEN <<[i \in 1 .. 64 |-> 0]>> ELSE settled28.echoText) ELSE << >>]
        settled30 == [settled29 EXCEPT !.liquidityProvision = IF settled29.numberOfReturnBitfields >= 9 /\ (settled29.tradeCaptureReportRejectV2ReturnBitfield9 # << >> /\ (settled29.tradeCaptureReportRejectV2ReturnBitfield9[1] \div 16) % 2 > 0) THEN (IF settled29.liquidityProvision = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled29.liquidityProvision) ELSE << >>]
        settled31 == [settled30 EXCEPT !.waiverType = IF settled30.numberOfReturnBitfields >= 10 /\ (settled30.tradeCaptureReportRejectV2ReturnBitfield10 # << >> /\ (settled30.tradeCaptureReportRejectV2ReturnBitfield10[1] \div 16) % 2 > 0) THEN (IF settled30.waiverType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled30.waiverType) ELSE << >>]
        settled32 == [settled31 EXCEPT !.priceFormation = IF settled31.numberOfReturnBitfields >= 10 /\ (settled31.tradeCaptureReportRejectV2ReturnBitfield10 # << >> /\ (settled31.tradeCaptureReportRejectV2ReturnBitfield10[1] \div 64) % 2 > 0) THEN (IF settled31.priceFormation = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled31.priceFormation) ELSE << >>]
        settled33 == [settled32 EXCEPT !.clientQualifiedRole = IF settled32.numberOfReturnBitfields >= 10 /\ (settled32.tradeCaptureReportRejectV2ReturnBitfield10 # << >> /\ (settled32.tradeCaptureReportRejectV2ReturnBitfield10[1] \div 128) % 2 > 0) THEN (IF settled32.clientQualifiedRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled32.clientQualifiedRole) ELSE << >>]
        settled34 == [settled33 EXCEPT !.clientId = IF settled33.numberOfReturnBitfields >= 11 /\ (settled33.tradeCaptureReportRejectV2ReturnBitfield11 # << >> /\ settled33.tradeCaptureReportRejectV2ReturnBitfield11[1] % 2 > 0) THEN (IF settled33.clientId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled33.clientId) ELSE << >>]
        settled35 == [settled34 EXCEPT !.investorId = IF settled34.numberOfReturnBitfields >= 11 /\ (settled34.tradeCaptureReportRejectV2ReturnBitfield11 # << >> /\ (settled34.tradeCaptureReportRejectV2ReturnBitfield11[1] \div 2) % 2 > 0) THEN (IF settled34.investorId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled34.investorId) ELSE << >>]
        settled36 == [settled35 EXCEPT !.executorId = IF settled35.numberOfReturnBitfields >= 11 /\ (settled35.tradeCaptureReportRejectV2ReturnBitfield11 # << >> /\ (settled35.tradeCaptureReportRejectV2ReturnBitfield11[1] \div 4) % 2 > 0) THEN (IF settled35.executorId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled35.executorId) ELSE << >>]
        settled37 == [settled36 EXCEPT !.orderOrigination = IF settled36.numberOfReturnBitfields >= 11 /\ (settled36.tradeCaptureReportRejectV2ReturnBitfield11 # << >> /\ (settled36.tradeCaptureReportRejectV2ReturnBitfield11[1] \div 8) % 2 > 0) THEN (IF settled36.orderOrigination = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled36.orderOrigination) ELSE << >>]
        settled38 == [settled37 EXCEPT !.algorithmicIndicator = IF settled37.numberOfReturnBitfields >= 11 /\ (settled37.tradeCaptureReportRejectV2ReturnBitfield11 # << >> /\ (settled37.tradeCaptureReportRejectV2ReturnBitfield11[1] \div 16) % 2 > 0) THEN (IF settled37.algorithmicIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled37.algorithmicIndicator) ELSE << >>]
        settled39 == [settled38 EXCEPT !.investorQualifiedRole = IF settled38.numberOfReturnBitfields >= 11 /\ (settled38.tradeCaptureReportRejectV2ReturnBitfield11 # << >> /\ (settled38.tradeCaptureReportRejectV2ReturnBitfield11[1] \div 64) % 2 > 0) THEN (IF settled38.investorQualifiedRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled38.investorQualifiedRole) ELSE << >>]
        settled40 == [settled39 EXCEPT !.executorQualifiedRole = IF settled39.numberOfReturnBitfields >= 11 /\ (settled39.tradeCaptureReportRejectV2ReturnBitfield11 # << >> /\ (settled39.tradeCaptureReportRejectV2ReturnBitfield11[1] \div 128) % 2 > 0) THEN (IF settled39.executorQualifiedRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled39.executorQualifiedRole) ELSE << >>]
    IN  settled40

ZeroTradeCaptureReportRejectV2Message ==
    SettleTradeCaptureReportRejectV2Message([ transactionTime                            |-> [i \in 1 .. 8 |-> 0],
                                              tradeReportId                              |-> [i \in 1 .. 20 |-> 0],
                                              reason                                     |-> [i \in 1 .. 1 |-> 0],
                                              text                                       |-> [i \in 1 .. 60 |-> 0],
                                              reserved1                                  |-> [i \in 1 .. 1 |-> 0],
                                              numberOfReturnBitfields                    |-> 0,
                                              tradeCaptureReportRejectV2ReturnBitfield1  |-> << >>,
                                              tradeCaptureReportRejectV2ReturnBitfield2  |-> << >>,
                                              tradeCaptureReportRejectV2ReturnBitfield3  |-> << >>,
                                              tradeCaptureReportRejectV2ReturnBitfield4  |-> << >>,
                                              tradeCaptureReportRejectV2ReturnBitfield5  |-> << >>,
                                              tradeCaptureReportRejectV2ReturnBitfield6  |-> << >>,
                                              tradeCaptureReportRejectV2ReturnBitfield7  |-> << >>,
                                              tradeCaptureReportRejectV2ReturnBitfield8  |-> << >>,
                                              tradeCaptureReportRejectV2ReturnBitfield9  |-> << >>,
                                              tradeCaptureReportRejectV2ReturnBitfield10 |-> << >>,
                                              tradeCaptureReportRejectV2ReturnBitfield11 |-> << >>,
                                              tradeCaptureReportRejectV2ReturnBitfield12 |-> << >>,
                                              tradeCaptureReportRejectV2ReturnBitfield13 |-> << >>,
                                              tradeCaptureReportRejectV2ReturnBitfield14 |-> << >>,
                                              tradeCaptureReportRejectV2TrdCapAckSideGrp |-> << >>,
                                              execInst                                   |-> << >>,
                                              symbol                                     |-> << >>,
                                              currency                                   |-> << >>,
                                              idSource                                   |-> << >>,
                                              securityId                                 |-> << >>,
                                              securityExchange                           |-> << >>,
                                              clearingFirm                               |-> << >>,
                                              orderQty                                   |-> << >>,
                                              tradeReportTypeReturn                      |-> << >>,
                                              tradePublishIndicator                      |-> << >>,
                                              rptTime                                    |-> << >>,
                                              largeSize                                  |-> << >>,
                                              lastMkt                                    |-> << >>,
                                              echoText                                   |-> << >>,
                                              liquidityProvision                         |-> << >>,
                                              waiverType                                 |-> << >>,
                                              priceFormation                             |-> << >>,
                                              clientQualifiedRole                        |-> << >>,
                                              clientId                                   |-> << >>,
                                              investorId                                 |-> << >>,
                                              executorId                                 |-> << >>,
                                              orderOrigination                           |-> << >>,
                                              algorithmicIndicator                       |-> << >>,
                                              investorQualifiedRole                      |-> << >>,
                                              executorQualifiedRole                      |-> << >> ])

(* Trade Capture Report Reject V 2 Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCaptureReportRejectV2Message ==
    { ZeroTradeCaptureReportRejectV2Message }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.transactionTime = one]) : one \in Sample(8) }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.tradeReportId = one]) : one \in Sample(20) }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.reason = one]) : one \in Sample(1) }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.text = one]) : one \in Sample(60) }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.reserved1 = one]) : one \in Sample(1) }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 1, !.tradeCaptureReportRejectV2ReturnBitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 2, !.tradeCaptureReportRejectV2ReturnBitfield2 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 3, !.tradeCaptureReportRejectV2ReturnBitfield3 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 4, !.tradeCaptureReportRejectV2ReturnBitfield4 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 5, !.tradeCaptureReportRejectV2ReturnBitfield5 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 6, !.tradeCaptureReportRejectV2ReturnBitfield6 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 7, !.tradeCaptureReportRejectV2ReturnBitfield7 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 8, !.tradeCaptureReportRejectV2ReturnBitfield8 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 9, !.tradeCaptureReportRejectV2ReturnBitfield9 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 10, !.tradeCaptureReportRejectV2ReturnBitfield10 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 11, !.tradeCaptureReportRejectV2ReturnBitfield11 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 12, !.tradeCaptureReportRejectV2ReturnBitfield12 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 13, !.tradeCaptureReportRejectV2ReturnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 14, !.tradeCaptureReportRejectV2ReturnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.tradeCaptureReportRejectV2TrdCapAckSideGrp = one]) : one \in SampleLists(OneTradeCaptureReportRejectV2TrdCapAckSideGrp) }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 1, !.tradeCaptureReportRejectV2ReturnBitfield1 = <<1>>, !.tradeCaptureReportRejectV2TrdCapAckSideGrp = one]) : one \in SampleLists(OneTradeCaptureReportRejectV2TrdCapAckSideGrp) }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 2, !.tradeCaptureReportRejectV2ReturnBitfield2 = <<64>>, !.tradeCaptureReportRejectV2TrdCapAckSideGrp = one]) : one \in SampleLists(OneTradeCaptureReportRejectV2TrdCapAckSideGrp) }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 3, !.tradeCaptureReportRejectV2ReturnBitfield3 = <<1>>, !.tradeCaptureReportRejectV2TrdCapAckSideGrp = one]) : one \in SampleLists(OneTradeCaptureReportRejectV2TrdCapAckSideGrp) }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 4, !.tradeCaptureReportRejectV2ReturnBitfield4 = <<64>>, !.tradeCaptureReportRejectV2TrdCapAckSideGrp = one]) : one \in SampleLists(OneTradeCaptureReportRejectV2TrdCapAckSideGrp) }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 6, !.tradeCaptureReportRejectV2ReturnBitfield6 = <<128>>, !.tradeCaptureReportRejectV2TrdCapAckSideGrp = one]) : one \in SampleLists(OneTradeCaptureReportRejectV2TrdCapAckSideGrp) }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 1, !.tradeCaptureReportRejectV2ReturnBitfield1 = <<8>>, !.execInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 2, !.tradeCaptureReportRejectV2ReturnBitfield2 = <<1>>, !.symbol = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 2, !.tradeCaptureReportRejectV2ReturnBitfield2 = <<4>>, !.currency = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 2, !.tradeCaptureReportRejectV2ReturnBitfield2 = <<8>>, !.idSource = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 2, !.tradeCaptureReportRejectV2ReturnBitfield2 = <<16>>, !.securityId = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 2, !.tradeCaptureReportRejectV2ReturnBitfield2 = <<32>>, !.securityExchange = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 3, !.tradeCaptureReportRejectV2ReturnBitfield3 = <<2>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 3, !.tradeCaptureReportRejectV2ReturnBitfield3 = <<64>>, !.orderQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 7, !.tradeCaptureReportRejectV2ReturnBitfield7 = <<2>>, !.tradeReportTypeReturn = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 7, !.tradeCaptureReportRejectV2ReturnBitfield7 = <<4>>, !.tradePublishIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 7, !.tradeCaptureReportRejectV2ReturnBitfield7 = <<4>>, !.rptTime = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 7, !.tradeCaptureReportRejectV2ReturnBitfield7 = <<64>>, !.largeSize = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 7, !.tradeCaptureReportRejectV2ReturnBitfield7 = <<128>>, !.lastMkt = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 8, !.tradeCaptureReportRejectV2ReturnBitfield8 = <<2>>, !.echoText = one]) : one \in { <<held>> : held \in Sample(64) } }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 9, !.tradeCaptureReportRejectV2ReturnBitfield9 = <<16>>, !.liquidityProvision = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 10, !.tradeCaptureReportRejectV2ReturnBitfield10 = <<16>>, !.waiverType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 10, !.tradeCaptureReportRejectV2ReturnBitfield10 = <<64>>, !.priceFormation = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 10, !.tradeCaptureReportRejectV2ReturnBitfield10 = <<128>>, !.clientQualifiedRole = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 11, !.tradeCaptureReportRejectV2ReturnBitfield11 = <<1>>, !.clientId = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 11, !.tradeCaptureReportRejectV2ReturnBitfield11 = <<2>>, !.investorId = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 11, !.tradeCaptureReportRejectV2ReturnBitfield11 = <<4>>, !.executorId = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 11, !.tradeCaptureReportRejectV2ReturnBitfield11 = <<8>>, !.orderOrigination = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 11, !.tradeCaptureReportRejectV2ReturnBitfield11 = <<16>>, !.algorithmicIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 11, !.tradeCaptureReportRejectV2ReturnBitfield11 = <<64>>, !.investorQualifiedRole = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 11, !.tradeCaptureReportRejectV2ReturnBitfield11 = <<128>>, !.executorQualifiedRole = one]) : one \in { <<held>> : held \in Sample(1) } }

(***************************************************************************)
(* Trade Capture Confirm V 2 Trd Cap Ack Side Grp                          *)
(***************************************************************************)

TradeCaptureConfirmV2TrdCapAckSideGrp ==
    [ side                : { << >> } \cup { <<held>> : held \in Sample(1) },
      capacity            : { << >> } \cup { <<held>> : held \in Sample(1) },
      account             : { << >> } \cup { <<held>> : held \in Sample(16) },
      partyId             : { << >> } \cup { <<held>> : held \in Sample(4) },
      centralCounterparty : { << >> } \cup { <<held>> : held \in Sample(1) },
      partyRole           : { << >> } \cup { <<held>> : held \in Sample(1) },
      feeCode             : { << >> } \cup { <<held>> : held \in Sample(2) } ]

EncodeTradeCaptureConfirmV2TrdCapAckSideGrp(message) ==
    (IF message.side = << >> THEN << >> ELSE message.side[1])
        \o (IF message.capacity = << >> THEN << >> ELSE message.capacity[1])
        \o (IF message.account = << >> THEN << >> ELSE message.account[1])
        \o (IF message.partyId = << >> THEN << >> ELSE message.partyId[1])
        \o (IF message.centralCounterparty = << >> THEN << >> ELSE message.centralCounterparty[1])
        \o (IF message.partyRole = << >> THEN << >> ELSE message.partyRole[1])
        \o (IF message.feeCode = << >> THEN << >> ELSE message.feeCode[1])

DecodeTradeCaptureConfirmV2TrdCapAckSideGrp(bytes, handedNumberOfTradeCaptureConfirmV2Bitfields, handedTradeCaptureConfirmV2Bitfield1, handedTradeCaptureConfirmV2Bitfield2, handedTradeCaptureConfirmV2Bitfield3, handedTradeCaptureConfirmV2Bitfield4, handedTradeCaptureConfirmV2Bitfield6, handedTradeCaptureConfirmV2Bitfield8) ==
    LET side == ReadWhen(handedNumberOfTradeCaptureConfirmV2Bitfields >= 1 /\ (handedTradeCaptureConfirmV2Bitfield1 # << >> /\ handedTradeCaptureConfirmV2Bitfield1[1] % 2 > 0), ReadBytes(bytes, 1), bytes) IN IF ~side.ok THEN Fail ELSE
    LET capacity == ReadWhen(handedNumberOfTradeCaptureConfirmV2Bitfields >= 2 /\ (handedTradeCaptureConfirmV2Bitfield2 # << >> /\ (handedTradeCaptureConfirmV2Bitfield2[1] \div 64) % 2 > 0), ReadBytes(side.rest, 1), side.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadWhen(handedNumberOfTradeCaptureConfirmV2Bitfields >= 3 /\ (handedTradeCaptureConfirmV2Bitfield3 # << >> /\ handedTradeCaptureConfirmV2Bitfield3[1] % 2 > 0), ReadBytes(capacity.rest, 16), capacity.rest) IN IF ~account.ok THEN Fail ELSE
    LET partyId == ReadWhen(handedNumberOfTradeCaptureConfirmV2Bitfields >= 4 /\ (handedTradeCaptureConfirmV2Bitfield4 # << >> /\ (handedTradeCaptureConfirmV2Bitfield4[1] \div 64) % 2 > 0), ReadBytes(account.rest, 4), account.rest) IN IF ~partyId.ok THEN Fail ELSE
    LET centralCounterparty == ReadWhen(handedNumberOfTradeCaptureConfirmV2Bitfields >= 6 /\ (handedTradeCaptureConfirmV2Bitfield6 # << >> /\ (handedTradeCaptureConfirmV2Bitfield6[1] \div 2) % 2 > 0), ReadBytes(partyId.rest, 1), partyId.rest) IN IF ~centralCounterparty.ok THEN Fail ELSE
    LET partyRole == ReadWhen(handedNumberOfTradeCaptureConfirmV2Bitfields >= 6 /\ (handedTradeCaptureConfirmV2Bitfield6 # << >> /\ (handedTradeCaptureConfirmV2Bitfield6[1] \div 128) % 2 > 0), ReadBytes(centralCounterparty.rest, 1), centralCounterparty.rest) IN IF ~partyRole.ok THEN Fail ELSE
    LET feeCode == ReadWhen(handedNumberOfTradeCaptureConfirmV2Bitfields >= 8 /\ (handedTradeCaptureConfirmV2Bitfield8 # << >> /\ handedTradeCaptureConfirmV2Bitfield8[1] % 2 > 0), ReadBytes(partyRole.rest, 2), partyRole.rest) IN IF ~feeCode.ok THEN Fail ELSE
    Ok([ side                |-> side.value,
         capacity            |-> capacity.value,
         account             |-> account.value,
         partyId             |-> partyId.value,
         centralCounterparty |-> centralCounterparty.value,
         partyRole           |-> partyRole.value,
         feeCode             |-> feeCode.value ], feeCode.rest)

(* Trade Capture Confirm V 2 Trd Cap Ack Side Grp with each field marked present by fields before it there exactly where they say *)
SettleTradeCaptureConfirmV2TrdCapAckSideGrp(message, handedNumberOfTradeCaptureConfirmV2Bitfields, handedTradeCaptureConfirmV2Bitfield1, handedTradeCaptureConfirmV2Bitfield2, handedTradeCaptureConfirmV2Bitfield3, handedTradeCaptureConfirmV2Bitfield4, handedTradeCaptureConfirmV2Bitfield6, handedTradeCaptureConfirmV2Bitfield8) ==
    LET settled1 == [message EXCEPT !.side = IF handedNumberOfTradeCaptureConfirmV2Bitfields >= 1 /\ (handedTradeCaptureConfirmV2Bitfield1 # << >> /\ handedTradeCaptureConfirmV2Bitfield1[1] % 2 > 0) THEN (IF message.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE message.side) ELSE << >>]
        settled2 == [settled1 EXCEPT !.capacity = IF handedNumberOfTradeCaptureConfirmV2Bitfields >= 2 /\ (handedTradeCaptureConfirmV2Bitfield2 # << >> /\ (handedTradeCaptureConfirmV2Bitfield2[1] \div 64) % 2 > 0) THEN (IF settled1.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled1.capacity) ELSE << >>]
        settled3 == [settled2 EXCEPT !.account = IF handedNumberOfTradeCaptureConfirmV2Bitfields >= 3 /\ (handedTradeCaptureConfirmV2Bitfield3 # << >> /\ handedTradeCaptureConfirmV2Bitfield3[1] % 2 > 0) THEN (IF settled2.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled2.account) ELSE << >>]
        settled4 == [settled3 EXCEPT !.partyId = IF handedNumberOfTradeCaptureConfirmV2Bitfields >= 4 /\ (handedTradeCaptureConfirmV2Bitfield4 # << >> /\ (handedTradeCaptureConfirmV2Bitfield4[1] \div 64) % 2 > 0) THEN (IF settled3.partyId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled3.partyId) ELSE << >>]
        settled5 == [settled4 EXCEPT !.centralCounterparty = IF handedNumberOfTradeCaptureConfirmV2Bitfields >= 6 /\ (handedTradeCaptureConfirmV2Bitfield6 # << >> /\ (handedTradeCaptureConfirmV2Bitfield6[1] \div 2) % 2 > 0) THEN (IF settled4.centralCounterparty = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled4.centralCounterparty) ELSE << >>]
        settled6 == [settled5 EXCEPT !.partyRole = IF handedNumberOfTradeCaptureConfirmV2Bitfields >= 6 /\ (handedTradeCaptureConfirmV2Bitfield6 # << >> /\ (handedTradeCaptureConfirmV2Bitfield6[1] \div 128) % 2 > 0) THEN (IF settled5.partyRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled5.partyRole) ELSE << >>]
        settled7 == [settled6 EXCEPT !.feeCode = IF handedNumberOfTradeCaptureConfirmV2Bitfields >= 8 /\ (handedTradeCaptureConfirmV2Bitfield8 # << >> /\ handedTradeCaptureConfirmV2Bitfield8[1] % 2 > 0) THEN (IF settled6.feeCode = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled6.feeCode) ELSE << >>]
    IN  settled7

ZeroTradeCaptureConfirmV2TrdCapAckSideGrp ==
    SettleTradeCaptureConfirmV2TrdCapAckSideGrp([ side                |-> << >>,
                                                  capacity            |-> << >>,
                                                  account             |-> << >>,
                                                  partyId             |-> << >>,
                                                  centralCounterparty |-> << >>,
                                                  partyRole           |-> << >>,
                                                  feeCode             |-> << >> ], 0, << >>, << >>, << >>, << >>, << >>, << >>)

(* Trade Capture Confirm V 2 Trd Cap Ack Side Grp at zero, then each field in turn at the values it is checked at *)
CheckedTradeCaptureConfirmV2TrdCapAckSideGrp ==
    { [given |-> <<0, << >>, << >>, << >>, << >>, << >>, << >>>>, message |-> ZeroTradeCaptureConfirmV2TrdCapAckSideGrp] }
        \cup { [given |-> <<1, <<1>>, << >>, << >>, << >>, << >>, << >>>>, message |-> SettleTradeCaptureConfirmV2TrdCapAckSideGrp([ZeroTradeCaptureConfirmV2TrdCapAckSideGrp EXCEPT !.side = one], 1, <<1>>, << >>, << >>, << >>, << >>, << >>)] : one \in { <<held>> : held \in Sample(1) } }
        \cup { [given |-> <<2, << >>, <<64>>, << >>, << >>, << >>, << >>>>, message |-> SettleTradeCaptureConfirmV2TrdCapAckSideGrp([ZeroTradeCaptureConfirmV2TrdCapAckSideGrp EXCEPT !.capacity = one], 2, << >>, <<64>>, << >>, << >>, << >>, << >>)] : one \in { <<held>> : held \in Sample(1) } }
        \cup { [given |-> <<3, << >>, << >>, <<1>>, << >>, << >>, << >>>>, message |-> SettleTradeCaptureConfirmV2TrdCapAckSideGrp([ZeroTradeCaptureConfirmV2TrdCapAckSideGrp EXCEPT !.account = one], 3, << >>, << >>, <<1>>, << >>, << >>, << >>)] : one \in { <<held>> : held \in Sample(16) } }
        \cup { [given |-> <<4, << >>, << >>, << >>, <<64>>, << >>, << >>>>, message |-> SettleTradeCaptureConfirmV2TrdCapAckSideGrp([ZeroTradeCaptureConfirmV2TrdCapAckSideGrp EXCEPT !.partyId = one], 4, << >>, << >>, << >>, <<64>>, << >>, << >>)] : one \in { <<held>> : held \in Sample(4) } }
        \cup { [given |-> <<6, << >>, << >>, << >>, << >>, <<2>>, << >>>>, message |-> SettleTradeCaptureConfirmV2TrdCapAckSideGrp([ZeroTradeCaptureConfirmV2TrdCapAckSideGrp EXCEPT !.centralCounterparty = one], 6, << >>, << >>, << >>, << >>, <<2>>, << >>)] : one \in { <<held>> : held \in Sample(1) } }
        \cup { [given |-> <<6, << >>, << >>, << >>, << >>, <<128>>, << >>>>, message |-> SettleTradeCaptureConfirmV2TrdCapAckSideGrp([ZeroTradeCaptureConfirmV2TrdCapAckSideGrp EXCEPT !.partyRole = one], 6, << >>, << >>, << >>, << >>, <<128>>, << >>)] : one \in { <<held>> : held \in Sample(1) } }
        \cup { [given |-> <<8, << >>, << >>, << >>, << >>, << >>, <<1>>>>, message |-> SettleTradeCaptureConfirmV2TrdCapAckSideGrp([ZeroTradeCaptureConfirmV2TrdCapAckSideGrp EXCEPT !.feeCode = one], 8, << >>, << >>, << >>, << >>, << >>, <<1>>)] : one \in { <<held>> : held \in Sample(2) } }

(* A run of Trade Capture Confirm V 2 Trd Cap Ack Side Grp, written one after another *)
RECURSIVE EncodeTradeCaptureConfirmV2TrdCapAckSideGrpList(_)
EncodeTradeCaptureConfirmV2TrdCapAckSideGrpList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTradeCaptureConfirmV2TrdCapAckSideGrp(Head(messages)) \o EncodeTradeCaptureConfirmV2TrdCapAckSideGrpList(Tail(messages))

(* As many Trade Capture Confirm V 2 Trd Cap Ack Side Grp as the field that counts them says *)
RECURSIVE ReadTradeCaptureConfirmV2TrdCapAckSideGrpList(_, _, _, _, _, _, _, _, _)
ReadTradeCaptureConfirmV2TrdCapAckSideGrpList(bytes, count, handedNumberOfTradeCaptureConfirmV2Bitfields, handedTradeCaptureConfirmV2Bitfield1, handedTradeCaptureConfirmV2Bitfield2, handedTradeCaptureConfirmV2Bitfield3, handedTradeCaptureConfirmV2Bitfield4, handedTradeCaptureConfirmV2Bitfield6, handedTradeCaptureConfirmV2Bitfield8) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeTradeCaptureConfirmV2TrdCapAckSideGrp(bytes, handedNumberOfTradeCaptureConfirmV2Bitfields, handedTradeCaptureConfirmV2Bitfield1, handedTradeCaptureConfirmV2Bitfield2, handedTradeCaptureConfirmV2Bitfield3, handedTradeCaptureConfirmV2Bitfield4, handedTradeCaptureConfirmV2Bitfield6, handedTradeCaptureConfirmV2Bitfield8)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTradeCaptureConfirmV2TrdCapAckSideGrpList(one.rest, count - 1, handedNumberOfTradeCaptureConfirmV2Bitfields, handedTradeCaptureConfirmV2Bitfield1, handedTradeCaptureConfirmV2Bitfield2, handedTradeCaptureConfirmV2Bitfield3, handedTradeCaptureConfirmV2Bitfield4, handedTradeCaptureConfirmV2Bitfield6, handedTradeCaptureConfirmV2Bitfield8)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Trade Capture Confirm V 2 Trd Cap Ack Side Grp of each kind, for the lists that carry them *)
OneTradeCaptureConfirmV2TrdCapAckSideGrp == { ZeroTradeCaptureConfirmV2TrdCapAckSideGrp }

(***************************************************************************)
(* Trade Capture Confirm V 2 Message                                       *)
(***************************************************************************)

TradeCaptureConfirmV2Message ==
    [ transactionTime                        : Sample(8),
      tradeReportId                          : Sample(20),
      tradeReportRefId                       : Sample(20),
      tradeId                                : Sample(8),
      lastShares                             : Sample(4),
      tradeCaptureLastPx                     : Sample(8),
      contraBroker                           : Sample(4),
      reserved1                              : Sample(1),
      numberOfTradeCaptureConfirmV2Bitfields : 0 .. 255,
      tradeCaptureConfirmV2Bitfield1         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCaptureConfirmV2Bitfield2         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCaptureConfirmV2Bitfield3         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCaptureConfirmV2Bitfield4         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCaptureConfirmV2Bitfield5         : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCaptureConfirmV2Bitfield6         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCaptureConfirmV2Bitfield7         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCaptureConfirmV2Bitfield8         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCaptureConfirmV2Bitfield9         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCaptureConfirmV2Bitfield10        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCaptureConfirmV2Bitfield11        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCaptureConfirmV2Bitfield12        : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCaptureConfirmV2Bitfield13        : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCaptureConfirmV2Bitfield14        : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCaptureConfirmV2TrdCapAckSideGrp  : SampleLists(OneTradeCaptureConfirmV2TrdCapAckSideGrp),
      execInst                               : { << >> } \cup { <<held>> : held \in Sample(1) },
      symbol                                 : { << >> } \cup { <<held>> : held \in Sample(8) },
      currency                               : { << >> } \cup { <<held>> : held \in Sample(3) },
      idSource                               : { << >> } \cup { <<held>> : held \in Sample(1) },
      securityId                             : { << >> } \cup { <<held>> : held \in Sample(16) },
      securityExchange                       : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingFirm                           : { << >> } \cup { <<held>> : held \in Sample(4) },
      orderQty                               : { << >> } \cup { <<held>> : held \in Sample(4) },
      correctedSize                          : { << >> } \cup { <<held>> : held \in Sample(4) },
      tradeReportTypeReturn                  : { << >> } \cup { <<held>> : held \in Sample(2) },
      tradePublishIndicator                  : { << >> } \cup { <<held>> : held \in Sample(1) },
      rptTime                                : { << >> } \cup { <<held>> : held \in Sample(8) },
      text                                   : { << >> } \cup { <<held>> : held \in Sample(60) },
      largeSize                              : { << >> } \cup { <<held>> : held \in Sample(8) },
      lastMkt                                : { << >> } \cup { <<held>> : held \in Sample(4) },
      echoText                               : { << >> } \cup { <<held>> : held \in Sample(64) },
      orderCategory                          : { << >> } \cup { <<held>> : held \in Sample(1) },
      liquidityProvision                     : { << >> } \cup { <<held>> : held \in Sample(1) },
      waiverType                             : { << >> } \cup { <<held>> : held \in Sample(1) },
      priceFormation                         : { << >> } \cup { <<held>> : held \in Sample(1) },
      clientQualifiedRole                    : { << >> } \cup { <<held>> : held \in Sample(1) },
      clientId                               : { << >> } \cup { <<held>> : held \in Sample(4) },
      investorId                             : { << >> } \cup { <<held>> : held \in Sample(4) },
      executorId                             : { << >> } \cup { <<held>> : held \in Sample(4) },
      orderOrigination                       : { << >> } \cup { <<held>> : held \in Sample(1) },
      algorithmicIndicator                   : { << >> } \cup { <<held>> : held \in Sample(1) },
      deferralReason                         : { << >> } \cup { <<held>> : held \in Sample(1) },
      investorQualifiedRole                  : { << >> } \cup { <<held>> : held \in Sample(1) },
      executorQualifiedRole                  : { << >> } \cup { <<held>> : held \in Sample(1) } ]

EncodeTradeCaptureConfirmV2Message(message) ==
    message.transactionTime
        \o message.tradeReportId
        \o message.tradeReportRefId
        \o message.tradeId
        \o message.lastShares
        \o message.tradeCaptureLastPx
        \o message.contraBroker
        \o message.reserved1
        \o EncodeUIntBE(message.numberOfTradeCaptureConfirmV2Bitfields, 1)
        \o (IF message.tradeCaptureConfirmV2Bitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCaptureConfirmV2Bitfield1[1], 1))
        \o (IF message.tradeCaptureConfirmV2Bitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCaptureConfirmV2Bitfield2[1], 1))
        \o (IF message.tradeCaptureConfirmV2Bitfield3 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCaptureConfirmV2Bitfield3[1], 1))
        \o (IF message.tradeCaptureConfirmV2Bitfield4 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCaptureConfirmV2Bitfield4[1], 1))
        \o (IF message.tradeCaptureConfirmV2Bitfield5 = << >> THEN << >> ELSE message.tradeCaptureConfirmV2Bitfield5[1])
        \o (IF message.tradeCaptureConfirmV2Bitfield6 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCaptureConfirmV2Bitfield6[1], 1))
        \o (IF message.tradeCaptureConfirmV2Bitfield7 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCaptureConfirmV2Bitfield7[1], 1))
        \o (IF message.tradeCaptureConfirmV2Bitfield8 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCaptureConfirmV2Bitfield8[1], 1))
        \o (IF message.tradeCaptureConfirmV2Bitfield9 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCaptureConfirmV2Bitfield9[1], 1))
        \o (IF message.tradeCaptureConfirmV2Bitfield10 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCaptureConfirmV2Bitfield10[1], 1))
        \o (IF message.tradeCaptureConfirmV2Bitfield11 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCaptureConfirmV2Bitfield11[1], 1))
        \o (IF message.tradeCaptureConfirmV2Bitfield12 = << >> THEN << >> ELSE message.tradeCaptureConfirmV2Bitfield12[1])
        \o (IF message.tradeCaptureConfirmV2Bitfield13 = << >> THEN << >> ELSE message.tradeCaptureConfirmV2Bitfield13[1])
        \o (IF message.tradeCaptureConfirmV2Bitfield14 = << >> THEN << >> ELSE message.tradeCaptureConfirmV2Bitfield14[1])
        \o EncodeUIntBE(Len(message.tradeCaptureConfirmV2TrdCapAckSideGrp), 1)
        \o EncodeTradeCaptureConfirmV2TrdCapAckSideGrpList(message.tradeCaptureConfirmV2TrdCapAckSideGrp)
        \o (IF message.execInst = << >> THEN << >> ELSE message.execInst[1])
        \o (IF message.symbol = << >> THEN << >> ELSE message.symbol[1])
        \o (IF message.currency = << >> THEN << >> ELSE message.currency[1])
        \o (IF message.idSource = << >> THEN << >> ELSE message.idSource[1])
        \o (IF message.securityId = << >> THEN << >> ELSE message.securityId[1])
        \o (IF message.securityExchange = << >> THEN << >> ELSE message.securityExchange[1])
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])
        \o (IF message.orderQty = << >> THEN << >> ELSE message.orderQty[1])
        \o (IF message.correctedSize = << >> THEN << >> ELSE message.correctedSize[1])
        \o (IF message.tradeReportTypeReturn = << >> THEN << >> ELSE message.tradeReportTypeReturn[1])
        \o (IF message.tradePublishIndicator = << >> THEN << >> ELSE message.tradePublishIndicator[1])
        \o (IF message.rptTime = << >> THEN << >> ELSE message.rptTime[1])
        \o (IF message.text = << >> THEN << >> ELSE message.text[1])
        \o (IF message.largeSize = << >> THEN << >> ELSE message.largeSize[1])
        \o (IF message.lastMkt = << >> THEN << >> ELSE message.lastMkt[1])
        \o (IF message.echoText = << >> THEN << >> ELSE message.echoText[1])
        \o (IF message.orderCategory = << >> THEN << >> ELSE message.orderCategory[1])
        \o (IF message.liquidityProvision = << >> THEN << >> ELSE message.liquidityProvision[1])
        \o (IF message.waiverType = << >> THEN << >> ELSE message.waiverType[1])
        \o (IF message.priceFormation = << >> THEN << >> ELSE message.priceFormation[1])
        \o (IF message.clientQualifiedRole = << >> THEN << >> ELSE message.clientQualifiedRole[1])
        \o (IF message.clientId = << >> THEN << >> ELSE message.clientId[1])
        \o (IF message.investorId = << >> THEN << >> ELSE message.investorId[1])
        \o (IF message.executorId = << >> THEN << >> ELSE message.executorId[1])
        \o (IF message.orderOrigination = << >> THEN << >> ELSE message.orderOrigination[1])
        \o (IF message.algorithmicIndicator = << >> THEN << >> ELSE message.algorithmicIndicator[1])
        \o (IF message.deferralReason = << >> THEN << >> ELSE message.deferralReason[1])
        \o (IF message.investorQualifiedRole = << >> THEN << >> ELSE message.investorQualifiedRole[1])
        \o (IF message.executorQualifiedRole = << >> THEN << >> ELSE message.executorQualifiedRole[1])

DecodeTradeCaptureConfirmV2Message(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(transactionTime.rest, 20) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET tradeReportRefId == ReadBytes(tradeReportId.rest, 20) IN IF ~tradeReportRefId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(tradeReportRefId.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET lastShares == ReadBytes(tradeId.rest, 4) IN IF ~lastShares.ok THEN Fail ELSE
    LET tradeCaptureLastPx == ReadBytes(lastShares.rest, 8) IN IF ~tradeCaptureLastPx.ok THEN Fail ELSE
    LET contraBroker == ReadBytes(tradeCaptureLastPx.rest, 4) IN IF ~contraBroker.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(contraBroker.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET numberOfTradeCaptureConfirmV2Bitfields == ReadUIntBE(reserved1.rest, 1) IN IF ~numberOfTradeCaptureConfirmV2Bitfields.ok THEN Fail ELSE
    LET tradeCaptureConfirmV2Bitfield1 == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 1, ReadUIntLE(numberOfTradeCaptureConfirmV2Bitfields.rest, 1), numberOfTradeCaptureConfirmV2Bitfields.rest) IN IF ~tradeCaptureConfirmV2Bitfield1.ok THEN Fail ELSE
    LET tradeCaptureConfirmV2Bitfield2 == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 2, ReadUIntLE(tradeCaptureConfirmV2Bitfield1.rest, 1), tradeCaptureConfirmV2Bitfield1.rest) IN IF ~tradeCaptureConfirmV2Bitfield2.ok THEN Fail ELSE
    LET tradeCaptureConfirmV2Bitfield3 == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 3, ReadUIntLE(tradeCaptureConfirmV2Bitfield2.rest, 1), tradeCaptureConfirmV2Bitfield2.rest) IN IF ~tradeCaptureConfirmV2Bitfield3.ok THEN Fail ELSE
    LET tradeCaptureConfirmV2Bitfield4 == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 4, ReadUIntLE(tradeCaptureConfirmV2Bitfield3.rest, 1), tradeCaptureConfirmV2Bitfield3.rest) IN IF ~tradeCaptureConfirmV2Bitfield4.ok THEN Fail ELSE
    LET tradeCaptureConfirmV2Bitfield5 == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 5, ReadBytes(tradeCaptureConfirmV2Bitfield4.rest, 1), tradeCaptureConfirmV2Bitfield4.rest) IN IF ~tradeCaptureConfirmV2Bitfield5.ok THEN Fail ELSE
    LET tradeCaptureConfirmV2Bitfield6 == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 6, ReadUIntLE(tradeCaptureConfirmV2Bitfield5.rest, 1), tradeCaptureConfirmV2Bitfield5.rest) IN IF ~tradeCaptureConfirmV2Bitfield6.ok THEN Fail ELSE
    LET tradeCaptureConfirmV2Bitfield7 == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 7, ReadUIntLE(tradeCaptureConfirmV2Bitfield6.rest, 1), tradeCaptureConfirmV2Bitfield6.rest) IN IF ~tradeCaptureConfirmV2Bitfield7.ok THEN Fail ELSE
    LET tradeCaptureConfirmV2Bitfield8 == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 8, ReadUIntLE(tradeCaptureConfirmV2Bitfield7.rest, 1), tradeCaptureConfirmV2Bitfield7.rest) IN IF ~tradeCaptureConfirmV2Bitfield8.ok THEN Fail ELSE
    LET tradeCaptureConfirmV2Bitfield9 == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 9, ReadUIntLE(tradeCaptureConfirmV2Bitfield8.rest, 1), tradeCaptureConfirmV2Bitfield8.rest) IN IF ~tradeCaptureConfirmV2Bitfield9.ok THEN Fail ELSE
    LET tradeCaptureConfirmV2Bitfield10 == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 10, ReadUIntLE(tradeCaptureConfirmV2Bitfield9.rest, 1), tradeCaptureConfirmV2Bitfield9.rest) IN IF ~tradeCaptureConfirmV2Bitfield10.ok THEN Fail ELSE
    LET tradeCaptureConfirmV2Bitfield11 == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 11, ReadUIntLE(tradeCaptureConfirmV2Bitfield10.rest, 1), tradeCaptureConfirmV2Bitfield10.rest) IN IF ~tradeCaptureConfirmV2Bitfield11.ok THEN Fail ELSE
    LET tradeCaptureConfirmV2Bitfield12 == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 12, ReadBytes(tradeCaptureConfirmV2Bitfield11.rest, 1), tradeCaptureConfirmV2Bitfield11.rest) IN IF ~tradeCaptureConfirmV2Bitfield12.ok THEN Fail ELSE
    LET tradeCaptureConfirmV2Bitfield13 == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 13, ReadBytes(tradeCaptureConfirmV2Bitfield12.rest, 1), tradeCaptureConfirmV2Bitfield12.rest) IN IF ~tradeCaptureConfirmV2Bitfield13.ok THEN Fail ELSE
    LET tradeCaptureConfirmV2Bitfield14 == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 14, ReadBytes(tradeCaptureConfirmV2Bitfield13.rest, 1), tradeCaptureConfirmV2Bitfield13.rest) IN IF ~tradeCaptureConfirmV2Bitfield14.ok THEN Fail ELSE
    LET noSides == ReadUIntBE(tradeCaptureConfirmV2Bitfield14.rest, 1) IN IF ~noSides.ok THEN Fail ELSE
    LET tradeCaptureConfirmV2TrdCapAckSideGrp == ReadTradeCaptureConfirmV2TrdCapAckSideGrpList(noSides.rest, noSides.value, numberOfTradeCaptureConfirmV2Bitfields.value, tradeCaptureConfirmV2Bitfield1.value, tradeCaptureConfirmV2Bitfield2.value, tradeCaptureConfirmV2Bitfield3.value, tradeCaptureConfirmV2Bitfield4.value, tradeCaptureConfirmV2Bitfield6.value, tradeCaptureConfirmV2Bitfield8.value) IN IF ~tradeCaptureConfirmV2TrdCapAckSideGrp.ok THEN Fail ELSE
    LET execInst == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 1 /\ (tradeCaptureConfirmV2Bitfield1.value # << >> /\ (tradeCaptureConfirmV2Bitfield1.value[1] \div 8) % 2 > 0), ReadBytes(tradeCaptureConfirmV2TrdCapAckSideGrp.rest, 1), tradeCaptureConfirmV2TrdCapAckSideGrp.rest) IN IF ~execInst.ok THEN Fail ELSE
    LET symbol == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 2 /\ (tradeCaptureConfirmV2Bitfield2.value # << >> /\ tradeCaptureConfirmV2Bitfield2.value[1] % 2 > 0), ReadBytes(execInst.rest, 8), execInst.rest) IN IF ~symbol.ok THEN Fail ELSE
    LET currency == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 2 /\ (tradeCaptureConfirmV2Bitfield2.value # << >> /\ (tradeCaptureConfirmV2Bitfield2.value[1] \div 4) % 2 > 0), ReadBytes(symbol.rest, 3), symbol.rest) IN IF ~currency.ok THEN Fail ELSE
    LET idSource == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 2 /\ (tradeCaptureConfirmV2Bitfield2.value # << >> /\ (tradeCaptureConfirmV2Bitfield2.value[1] \div 8) % 2 > 0), ReadBytes(currency.rest, 1), currency.rest) IN IF ~idSource.ok THEN Fail ELSE
    LET securityId == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 2 /\ (tradeCaptureConfirmV2Bitfield2.value # << >> /\ (tradeCaptureConfirmV2Bitfield2.value[1] \div 16) % 2 > 0), ReadBytes(idSource.rest, 16), idSource.rest) IN IF ~securityId.ok THEN Fail ELSE
    LET securityExchange == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 2 /\ (tradeCaptureConfirmV2Bitfield2.value # << >> /\ (tradeCaptureConfirmV2Bitfield2.value[1] \div 32) % 2 > 0), ReadBytes(securityId.rest, 4), securityId.rest) IN IF ~securityExchange.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 3 /\ (tradeCaptureConfirmV2Bitfield3.value # << >> /\ (tradeCaptureConfirmV2Bitfield3.value[1] \div 2) % 2 > 0), ReadBytes(securityExchange.rest, 4), securityExchange.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET orderQty == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 3 /\ (tradeCaptureConfirmV2Bitfield3.value # << >> /\ (tradeCaptureConfirmV2Bitfield3.value[1] \div 64) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~orderQty.ok THEN Fail ELSE
    LET correctedSize == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 4 /\ (tradeCaptureConfirmV2Bitfield4.value # << >> /\ (tradeCaptureConfirmV2Bitfield4.value[1] \div 32) % 2 > 0), ReadBytes(orderQty.rest, 4), orderQty.rest) IN IF ~correctedSize.ok THEN Fail ELSE
    LET tradeReportTypeReturn == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 7 /\ (tradeCaptureConfirmV2Bitfield7.value # << >> /\ (tradeCaptureConfirmV2Bitfield7.value[1] \div 2) % 2 > 0), ReadBytes(correctedSize.rest, 2), correctedSize.rest) IN IF ~tradeReportTypeReturn.ok THEN Fail ELSE
    LET tradePublishIndicator == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 7 /\ (tradeCaptureConfirmV2Bitfield7.value # << >> /\ (tradeCaptureConfirmV2Bitfield7.value[1] \div 4) % 2 > 0), ReadBytes(tradeReportTypeReturn.rest, 1), tradeReportTypeReturn.rest) IN IF ~tradePublishIndicator.ok THEN Fail ELSE
    LET rptTime == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 7 /\ (tradeCaptureConfirmV2Bitfield7.value # << >> /\ (tradeCaptureConfirmV2Bitfield7.value[1] \div 4) % 2 > 0), ReadBytes(tradePublishIndicator.rest, 8), tradePublishIndicator.rest) IN IF ~rptTime.ok THEN Fail ELSE
    LET text == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 7 /\ (tradeCaptureConfirmV2Bitfield7.value # << >> /\ (tradeCaptureConfirmV2Bitfield7.value[1] \div 8) % 2 > 0), ReadBytes(rptTime.rest, 60), rptTime.rest) IN IF ~text.ok THEN Fail ELSE
    LET largeSize == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 7 /\ (tradeCaptureConfirmV2Bitfield7.value # << >> /\ (tradeCaptureConfirmV2Bitfield7.value[1] \div 64) % 2 > 0), ReadBytes(text.rest, 8), text.rest) IN IF ~largeSize.ok THEN Fail ELSE
    LET lastMkt == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 7 /\ (tradeCaptureConfirmV2Bitfield7.value # << >> /\ (tradeCaptureConfirmV2Bitfield7.value[1] \div 128) % 2 > 0), ReadBytes(largeSize.rest, 4), largeSize.rest) IN IF ~lastMkt.ok THEN Fail ELSE
    LET echoText == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 8 /\ (tradeCaptureConfirmV2Bitfield8.value # << >> /\ (tradeCaptureConfirmV2Bitfield8.value[1] \div 2) % 2 > 0), ReadBytes(lastMkt.rest, 64), lastMkt.rest) IN IF ~echoText.ok THEN Fail ELSE
    LET orderCategory == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 9 /\ (tradeCaptureConfirmV2Bitfield9.value # << >> /\ (tradeCaptureConfirmV2Bitfield9.value[1] \div 8) % 2 > 0), ReadBytes(echoText.rest, 1), echoText.rest) IN IF ~orderCategory.ok THEN Fail ELSE
    LET liquidityProvision == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 9 /\ (tradeCaptureConfirmV2Bitfield9.value # << >> /\ (tradeCaptureConfirmV2Bitfield9.value[1] \div 16) % 2 > 0), ReadBytes(orderCategory.rest, 1), orderCategory.rest) IN IF ~liquidityProvision.ok THEN Fail ELSE
    LET waiverType == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 10 /\ (tradeCaptureConfirmV2Bitfield10.value # << >> /\ (tradeCaptureConfirmV2Bitfield10.value[1] \div 16) % 2 > 0), ReadBytes(liquidityProvision.rest, 1), liquidityProvision.rest) IN IF ~waiverType.ok THEN Fail ELSE
    LET priceFormation == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 10 /\ (tradeCaptureConfirmV2Bitfield10.value # << >> /\ (tradeCaptureConfirmV2Bitfield10.value[1] \div 64) % 2 > 0), ReadBytes(waiverType.rest, 1), waiverType.rest) IN IF ~priceFormation.ok THEN Fail ELSE
    LET clientQualifiedRole == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 10 /\ (tradeCaptureConfirmV2Bitfield10.value # << >> /\ (tradeCaptureConfirmV2Bitfield10.value[1] \div 128) % 2 > 0), ReadBytes(priceFormation.rest, 1), priceFormation.rest) IN IF ~clientQualifiedRole.ok THEN Fail ELSE
    LET clientId == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 11 /\ (tradeCaptureConfirmV2Bitfield11.value # << >> /\ tradeCaptureConfirmV2Bitfield11.value[1] % 2 > 0), ReadBytes(clientQualifiedRole.rest, 4), clientQualifiedRole.rest) IN IF ~clientId.ok THEN Fail ELSE
    LET investorId == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 11 /\ (tradeCaptureConfirmV2Bitfield11.value # << >> /\ (tradeCaptureConfirmV2Bitfield11.value[1] \div 2) % 2 > 0), ReadBytes(clientId.rest, 4), clientId.rest) IN IF ~investorId.ok THEN Fail ELSE
    LET executorId == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 11 /\ (tradeCaptureConfirmV2Bitfield11.value # << >> /\ (tradeCaptureConfirmV2Bitfield11.value[1] \div 4) % 2 > 0), ReadBytes(investorId.rest, 4), investorId.rest) IN IF ~executorId.ok THEN Fail ELSE
    LET orderOrigination == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 11 /\ (tradeCaptureConfirmV2Bitfield11.value # << >> /\ (tradeCaptureConfirmV2Bitfield11.value[1] \div 8) % 2 > 0), ReadBytes(executorId.rest, 1), executorId.rest) IN IF ~orderOrigination.ok THEN Fail ELSE
    LET algorithmicIndicator == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 11 /\ (tradeCaptureConfirmV2Bitfield11.value # << >> /\ (tradeCaptureConfirmV2Bitfield11.value[1] \div 16) % 2 > 0), ReadBytes(orderOrigination.rest, 1), orderOrigination.rest) IN IF ~algorithmicIndicator.ok THEN Fail ELSE
    LET deferralReason == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 11 /\ (tradeCaptureConfirmV2Bitfield11.value # << >> /\ (tradeCaptureConfirmV2Bitfield11.value[1] \div 32) % 2 > 0), ReadBytes(algorithmicIndicator.rest, 1), algorithmicIndicator.rest) IN IF ~deferralReason.ok THEN Fail ELSE
    LET investorQualifiedRole == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 11 /\ (tradeCaptureConfirmV2Bitfield11.value # << >> /\ (tradeCaptureConfirmV2Bitfield11.value[1] \div 64) % 2 > 0), ReadBytes(deferralReason.rest, 1), deferralReason.rest) IN IF ~investorQualifiedRole.ok THEN Fail ELSE
    LET executorQualifiedRole == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 11 /\ (tradeCaptureConfirmV2Bitfield11.value # << >> /\ (tradeCaptureConfirmV2Bitfield11.value[1] \div 128) % 2 > 0), ReadBytes(investorQualifiedRole.rest, 1), investorQualifiedRole.rest) IN IF ~executorQualifiedRole.ok THEN Fail ELSE
    Ok([ transactionTime                        |-> transactionTime.value,
         tradeReportId                          |-> tradeReportId.value,
         tradeReportRefId                       |-> tradeReportRefId.value,
         tradeId                                |-> tradeId.value,
         lastShares                             |-> lastShares.value,
         tradeCaptureLastPx                     |-> tradeCaptureLastPx.value,
         contraBroker                           |-> contraBroker.value,
         reserved1                              |-> reserved1.value,
         numberOfTradeCaptureConfirmV2Bitfields |-> numberOfTradeCaptureConfirmV2Bitfields.value,
         tradeCaptureConfirmV2Bitfield1         |-> tradeCaptureConfirmV2Bitfield1.value,
         tradeCaptureConfirmV2Bitfield2         |-> tradeCaptureConfirmV2Bitfield2.value,
         tradeCaptureConfirmV2Bitfield3         |-> tradeCaptureConfirmV2Bitfield3.value,
         tradeCaptureConfirmV2Bitfield4         |-> tradeCaptureConfirmV2Bitfield4.value,
         tradeCaptureConfirmV2Bitfield5         |-> tradeCaptureConfirmV2Bitfield5.value,
         tradeCaptureConfirmV2Bitfield6         |-> tradeCaptureConfirmV2Bitfield6.value,
         tradeCaptureConfirmV2Bitfield7         |-> tradeCaptureConfirmV2Bitfield7.value,
         tradeCaptureConfirmV2Bitfield8         |-> tradeCaptureConfirmV2Bitfield8.value,
         tradeCaptureConfirmV2Bitfield9         |-> tradeCaptureConfirmV2Bitfield9.value,
         tradeCaptureConfirmV2Bitfield10        |-> tradeCaptureConfirmV2Bitfield10.value,
         tradeCaptureConfirmV2Bitfield11        |-> tradeCaptureConfirmV2Bitfield11.value,
         tradeCaptureConfirmV2Bitfield12        |-> tradeCaptureConfirmV2Bitfield12.value,
         tradeCaptureConfirmV2Bitfield13        |-> tradeCaptureConfirmV2Bitfield13.value,
         tradeCaptureConfirmV2Bitfield14        |-> tradeCaptureConfirmV2Bitfield14.value,
         tradeCaptureConfirmV2TrdCapAckSideGrp  |-> tradeCaptureConfirmV2TrdCapAckSideGrp.value,
         execInst                               |-> execInst.value,
         symbol                                 |-> symbol.value,
         currency                               |-> currency.value,
         idSource                               |-> idSource.value,
         securityId                             |-> securityId.value,
         securityExchange                       |-> securityExchange.value,
         clearingFirm                           |-> clearingFirm.value,
         orderQty                               |-> orderQty.value,
         correctedSize                          |-> correctedSize.value,
         tradeReportTypeReturn                  |-> tradeReportTypeReturn.value,
         tradePublishIndicator                  |-> tradePublishIndicator.value,
         rptTime                                |-> rptTime.value,
         text                                   |-> text.value,
         largeSize                              |-> largeSize.value,
         lastMkt                                |-> lastMkt.value,
         echoText                               |-> echoText.value,
         orderCategory                          |-> orderCategory.value,
         liquidityProvision                     |-> liquidityProvision.value,
         waiverType                             |-> waiverType.value,
         priceFormation                         |-> priceFormation.value,
         clientQualifiedRole                    |-> clientQualifiedRole.value,
         clientId                               |-> clientId.value,
         investorId                             |-> investorId.value,
         executorId                             |-> executorId.value,
         orderOrigination                       |-> orderOrigination.value,
         algorithmicIndicator                   |-> algorithmicIndicator.value,
         deferralReason                         |-> deferralReason.value,
         investorQualifiedRole                  |-> investorQualifiedRole.value,
         executorQualifiedRole                  |-> executorQualifiedRole.value ], executorQualifiedRole.rest)

(* Trade Capture Confirm V 2 Message with each field marked present by fields before it there exactly where they say *)
SettleTradeCaptureConfirmV2Message(message) ==
    LET settled1 == [message EXCEPT !.tradeCaptureConfirmV2Bitfield1 = IF message.numberOfTradeCaptureConfirmV2Bitfields >= 1 THEN (IF message.tradeCaptureConfirmV2Bitfield1 = << >> THEN <<0>> ELSE message.tradeCaptureConfirmV2Bitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.tradeCaptureConfirmV2Bitfield2 = IF settled1.numberOfTradeCaptureConfirmV2Bitfields >= 2 THEN (IF settled1.tradeCaptureConfirmV2Bitfield2 = << >> THEN <<0>> ELSE settled1.tradeCaptureConfirmV2Bitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.tradeCaptureConfirmV2Bitfield3 = IF settled2.numberOfTradeCaptureConfirmV2Bitfields >= 3 THEN (IF settled2.tradeCaptureConfirmV2Bitfield3 = << >> THEN <<0>> ELSE settled2.tradeCaptureConfirmV2Bitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.tradeCaptureConfirmV2Bitfield4 = IF settled3.numberOfTradeCaptureConfirmV2Bitfields >= 4 THEN (IF settled3.tradeCaptureConfirmV2Bitfield4 = << >> THEN <<0>> ELSE settled3.tradeCaptureConfirmV2Bitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.tradeCaptureConfirmV2Bitfield5 = IF settled4.numberOfTradeCaptureConfirmV2Bitfields >= 5 THEN (IF settled4.tradeCaptureConfirmV2Bitfield5 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled4.tradeCaptureConfirmV2Bitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.tradeCaptureConfirmV2Bitfield6 = IF settled5.numberOfTradeCaptureConfirmV2Bitfields >= 6 THEN (IF settled5.tradeCaptureConfirmV2Bitfield6 = << >> THEN <<0>> ELSE settled5.tradeCaptureConfirmV2Bitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.tradeCaptureConfirmV2Bitfield7 = IF settled6.numberOfTradeCaptureConfirmV2Bitfields >= 7 THEN (IF settled6.tradeCaptureConfirmV2Bitfield7 = << >> THEN <<0>> ELSE settled6.tradeCaptureConfirmV2Bitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.tradeCaptureConfirmV2Bitfield8 = IF settled7.numberOfTradeCaptureConfirmV2Bitfields >= 8 THEN (IF settled7.tradeCaptureConfirmV2Bitfield8 = << >> THEN <<0>> ELSE settled7.tradeCaptureConfirmV2Bitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.tradeCaptureConfirmV2Bitfield9 = IF settled8.numberOfTradeCaptureConfirmV2Bitfields >= 9 THEN (IF settled8.tradeCaptureConfirmV2Bitfield9 = << >> THEN <<0>> ELSE settled8.tradeCaptureConfirmV2Bitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.tradeCaptureConfirmV2Bitfield10 = IF settled9.numberOfTradeCaptureConfirmV2Bitfields >= 10 THEN (IF settled9.tradeCaptureConfirmV2Bitfield10 = << >> THEN <<0>> ELSE settled9.tradeCaptureConfirmV2Bitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.tradeCaptureConfirmV2Bitfield11 = IF settled10.numberOfTradeCaptureConfirmV2Bitfields >= 11 THEN (IF settled10.tradeCaptureConfirmV2Bitfield11 = << >> THEN <<0>> ELSE settled10.tradeCaptureConfirmV2Bitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.tradeCaptureConfirmV2Bitfield12 = IF settled11.numberOfTradeCaptureConfirmV2Bitfields >= 12 THEN (IF settled11.tradeCaptureConfirmV2Bitfield12 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.tradeCaptureConfirmV2Bitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.tradeCaptureConfirmV2Bitfield13 = IF settled12.numberOfTradeCaptureConfirmV2Bitfields >= 13 THEN (IF settled12.tradeCaptureConfirmV2Bitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.tradeCaptureConfirmV2Bitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.tradeCaptureConfirmV2Bitfield14 = IF settled13.numberOfTradeCaptureConfirmV2Bitfields >= 14 THEN (IF settled13.tradeCaptureConfirmV2Bitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.tradeCaptureConfirmV2Bitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.tradeCaptureConfirmV2TrdCapAckSideGrp = [i \in DOMAIN settled14.tradeCaptureConfirmV2TrdCapAckSideGrp |-> SettleTradeCaptureConfirmV2TrdCapAckSideGrp(settled14.tradeCaptureConfirmV2TrdCapAckSideGrp[i], settled14.numberOfTradeCaptureConfirmV2Bitfields, settled14.tradeCaptureConfirmV2Bitfield1, settled14.tradeCaptureConfirmV2Bitfield2, settled14.tradeCaptureConfirmV2Bitfield3, settled14.tradeCaptureConfirmV2Bitfield4, settled14.tradeCaptureConfirmV2Bitfield6, settled14.tradeCaptureConfirmV2Bitfield8)]]
        settled16 == [settled15 EXCEPT !.execInst = IF settled15.numberOfTradeCaptureConfirmV2Bitfields >= 1 /\ (settled15.tradeCaptureConfirmV2Bitfield1 # << >> /\ (settled15.tradeCaptureConfirmV2Bitfield1[1] \div 8) % 2 > 0) THEN (IF settled15.execInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled15.execInst) ELSE << >>]
        settled17 == [settled16 EXCEPT !.symbol = IF settled16.numberOfTradeCaptureConfirmV2Bitfields >= 2 /\ (settled16.tradeCaptureConfirmV2Bitfield2 # << >> /\ settled16.tradeCaptureConfirmV2Bitfield2[1] % 2 > 0) THEN (IF settled16.symbol = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled16.symbol) ELSE << >>]
        settled18 == [settled17 EXCEPT !.currency = IF settled17.numberOfTradeCaptureConfirmV2Bitfields >= 2 /\ (settled17.tradeCaptureConfirmV2Bitfield2 # << >> /\ (settled17.tradeCaptureConfirmV2Bitfield2[1] \div 4) % 2 > 0) THEN (IF settled17.currency = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled17.currency) ELSE << >>]
        settled19 == [settled18 EXCEPT !.idSource = IF settled18.numberOfTradeCaptureConfirmV2Bitfields >= 2 /\ (settled18.tradeCaptureConfirmV2Bitfield2 # << >> /\ (settled18.tradeCaptureConfirmV2Bitfield2[1] \div 8) % 2 > 0) THEN (IF settled18.idSource = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled18.idSource) ELSE << >>]
        settled20 == [settled19 EXCEPT !.securityId = IF settled19.numberOfTradeCaptureConfirmV2Bitfields >= 2 /\ (settled19.tradeCaptureConfirmV2Bitfield2 # << >> /\ (settled19.tradeCaptureConfirmV2Bitfield2[1] \div 16) % 2 > 0) THEN (IF settled19.securityId = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled19.securityId) ELSE << >>]
        settled21 == [settled20 EXCEPT !.securityExchange = IF settled20.numberOfTradeCaptureConfirmV2Bitfields >= 2 /\ (settled20.tradeCaptureConfirmV2Bitfield2 # << >> /\ (settled20.tradeCaptureConfirmV2Bitfield2[1] \div 32) % 2 > 0) THEN (IF settled20.securityExchange = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled20.securityExchange) ELSE << >>]
        settled22 == [settled21 EXCEPT !.clearingFirm = IF settled21.numberOfTradeCaptureConfirmV2Bitfields >= 3 /\ (settled21.tradeCaptureConfirmV2Bitfield3 # << >> /\ (settled21.tradeCaptureConfirmV2Bitfield3[1] \div 2) % 2 > 0) THEN (IF settled21.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled21.clearingFirm) ELSE << >>]
        settled23 == [settled22 EXCEPT !.orderQty = IF settled22.numberOfTradeCaptureConfirmV2Bitfields >= 3 /\ (settled22.tradeCaptureConfirmV2Bitfield3 # << >> /\ (settled22.tradeCaptureConfirmV2Bitfield3[1] \div 64) % 2 > 0) THEN (IF settled22.orderQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled22.orderQty) ELSE << >>]
        settled24 == [settled23 EXCEPT !.correctedSize = IF settled23.numberOfTradeCaptureConfirmV2Bitfields >= 4 /\ (settled23.tradeCaptureConfirmV2Bitfield4 # << >> /\ (settled23.tradeCaptureConfirmV2Bitfield4[1] \div 32) % 2 > 0) THEN (IF settled23.correctedSize = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled23.correctedSize) ELSE << >>]
        settled25 == [settled24 EXCEPT !.tradeReportTypeReturn = IF settled24.numberOfTradeCaptureConfirmV2Bitfields >= 7 /\ (settled24.tradeCaptureConfirmV2Bitfield7 # << >> /\ (settled24.tradeCaptureConfirmV2Bitfield7[1] \div 2) % 2 > 0) THEN (IF settled24.tradeReportTypeReturn = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled24.tradeReportTypeReturn) ELSE << >>]
        settled26 == [settled25 EXCEPT !.tradePublishIndicator = IF settled25.numberOfTradeCaptureConfirmV2Bitfields >= 7 /\ (settled25.tradeCaptureConfirmV2Bitfield7 # << >> /\ (settled25.tradeCaptureConfirmV2Bitfield7[1] \div 4) % 2 > 0) THEN (IF settled25.tradePublishIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled25.tradePublishIndicator) ELSE << >>]
        settled27 == [settled26 EXCEPT !.rptTime = IF settled26.numberOfTradeCaptureConfirmV2Bitfields >= 7 /\ (settled26.tradeCaptureConfirmV2Bitfield7 # << >> /\ (settled26.tradeCaptureConfirmV2Bitfield7[1] \div 4) % 2 > 0) THEN (IF settled26.rptTime = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled26.rptTime) ELSE << >>]
        settled28 == [settled27 EXCEPT !.text = IF settled27.numberOfTradeCaptureConfirmV2Bitfields >= 7 /\ (settled27.tradeCaptureConfirmV2Bitfield7 # << >> /\ (settled27.tradeCaptureConfirmV2Bitfield7[1] \div 8) % 2 > 0) THEN (IF settled27.text = << >> THEN <<[i \in 1 .. 60 |-> 0]>> ELSE settled27.text) ELSE << >>]
        settled29 == [settled28 EXCEPT !.largeSize = IF settled28.numberOfTradeCaptureConfirmV2Bitfields >= 7 /\ (settled28.tradeCaptureConfirmV2Bitfield7 # << >> /\ (settled28.tradeCaptureConfirmV2Bitfield7[1] \div 64) % 2 > 0) THEN (IF settled28.largeSize = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled28.largeSize) ELSE << >>]
        settled30 == [settled29 EXCEPT !.lastMkt = IF settled29.numberOfTradeCaptureConfirmV2Bitfields >= 7 /\ (settled29.tradeCaptureConfirmV2Bitfield7 # << >> /\ (settled29.tradeCaptureConfirmV2Bitfield7[1] \div 128) % 2 > 0) THEN (IF settled29.lastMkt = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled29.lastMkt) ELSE << >>]
        settled31 == [settled30 EXCEPT !.echoText = IF settled30.numberOfTradeCaptureConfirmV2Bitfields >= 8 /\ (settled30.tradeCaptureConfirmV2Bitfield8 # << >> /\ (settled30.tradeCaptureConfirmV2Bitfield8[1] \div 2) % 2 > 0) THEN (IF settled30.echoText = << >> THEN <<[i \in 1 .. 64 |-> 0]>> ELSE settled30.echoText) ELSE << >>]
        settled32 == [settled31 EXCEPT !.orderCategory = IF settled31.numberOfTradeCaptureConfirmV2Bitfields >= 9 /\ (settled31.tradeCaptureConfirmV2Bitfield9 # << >> /\ (settled31.tradeCaptureConfirmV2Bitfield9[1] \div 8) % 2 > 0) THEN (IF settled31.orderCategory = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled31.orderCategory) ELSE << >>]
        settled33 == [settled32 EXCEPT !.liquidityProvision = IF settled32.numberOfTradeCaptureConfirmV2Bitfields >= 9 /\ (settled32.tradeCaptureConfirmV2Bitfield9 # << >> /\ (settled32.tradeCaptureConfirmV2Bitfield9[1] \div 16) % 2 > 0) THEN (IF settled32.liquidityProvision = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled32.liquidityProvision) ELSE << >>]
        settled34 == [settled33 EXCEPT !.waiverType = IF settled33.numberOfTradeCaptureConfirmV2Bitfields >= 10 /\ (settled33.tradeCaptureConfirmV2Bitfield10 # << >> /\ (settled33.tradeCaptureConfirmV2Bitfield10[1] \div 16) % 2 > 0) THEN (IF settled33.waiverType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled33.waiverType) ELSE << >>]
        settled35 == [settled34 EXCEPT !.priceFormation = IF settled34.numberOfTradeCaptureConfirmV2Bitfields >= 10 /\ (settled34.tradeCaptureConfirmV2Bitfield10 # << >> /\ (settled34.tradeCaptureConfirmV2Bitfield10[1] \div 64) % 2 > 0) THEN (IF settled34.priceFormation = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled34.priceFormation) ELSE << >>]
        settled36 == [settled35 EXCEPT !.clientQualifiedRole = IF settled35.numberOfTradeCaptureConfirmV2Bitfields >= 10 /\ (settled35.tradeCaptureConfirmV2Bitfield10 # << >> /\ (settled35.tradeCaptureConfirmV2Bitfield10[1] \div 128) % 2 > 0) THEN (IF settled35.clientQualifiedRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled35.clientQualifiedRole) ELSE << >>]
        settled37 == [settled36 EXCEPT !.clientId = IF settled36.numberOfTradeCaptureConfirmV2Bitfields >= 11 /\ (settled36.tradeCaptureConfirmV2Bitfield11 # << >> /\ settled36.tradeCaptureConfirmV2Bitfield11[1] % 2 > 0) THEN (IF settled36.clientId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled36.clientId) ELSE << >>]
        settled38 == [settled37 EXCEPT !.investorId = IF settled37.numberOfTradeCaptureConfirmV2Bitfields >= 11 /\ (settled37.tradeCaptureConfirmV2Bitfield11 # << >> /\ (settled37.tradeCaptureConfirmV2Bitfield11[1] \div 2) % 2 > 0) THEN (IF settled37.investorId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled37.investorId) ELSE << >>]
        settled39 == [settled38 EXCEPT !.executorId = IF settled38.numberOfTradeCaptureConfirmV2Bitfields >= 11 /\ (settled38.tradeCaptureConfirmV2Bitfield11 # << >> /\ (settled38.tradeCaptureConfirmV2Bitfield11[1] \div 4) % 2 > 0) THEN (IF settled38.executorId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled38.executorId) ELSE << >>]
        settled40 == [settled39 EXCEPT !.orderOrigination = IF settled39.numberOfTradeCaptureConfirmV2Bitfields >= 11 /\ (settled39.tradeCaptureConfirmV2Bitfield11 # << >> /\ (settled39.tradeCaptureConfirmV2Bitfield11[1] \div 8) % 2 > 0) THEN (IF settled39.orderOrigination = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled39.orderOrigination) ELSE << >>]
        settled41 == [settled40 EXCEPT !.algorithmicIndicator = IF settled40.numberOfTradeCaptureConfirmV2Bitfields >= 11 /\ (settled40.tradeCaptureConfirmV2Bitfield11 # << >> /\ (settled40.tradeCaptureConfirmV2Bitfield11[1] \div 16) % 2 > 0) THEN (IF settled40.algorithmicIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled40.algorithmicIndicator) ELSE << >>]
        settled42 == [settled41 EXCEPT !.deferralReason = IF settled41.numberOfTradeCaptureConfirmV2Bitfields >= 11 /\ (settled41.tradeCaptureConfirmV2Bitfield11 # << >> /\ (settled41.tradeCaptureConfirmV2Bitfield11[1] \div 32) % 2 > 0) THEN (IF settled41.deferralReason = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled41.deferralReason) ELSE << >>]
        settled43 == [settled42 EXCEPT !.investorQualifiedRole = IF settled42.numberOfTradeCaptureConfirmV2Bitfields >= 11 /\ (settled42.tradeCaptureConfirmV2Bitfield11 # << >> /\ (settled42.tradeCaptureConfirmV2Bitfield11[1] \div 64) % 2 > 0) THEN (IF settled42.investorQualifiedRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled42.investorQualifiedRole) ELSE << >>]
        settled44 == [settled43 EXCEPT !.executorQualifiedRole = IF settled43.numberOfTradeCaptureConfirmV2Bitfields >= 11 /\ (settled43.tradeCaptureConfirmV2Bitfield11 # << >> /\ (settled43.tradeCaptureConfirmV2Bitfield11[1] \div 128) % 2 > 0) THEN (IF settled43.executorQualifiedRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled43.executorQualifiedRole) ELSE << >>]
    IN  settled44

ZeroTradeCaptureConfirmV2Message ==
    SettleTradeCaptureConfirmV2Message([ transactionTime                        |-> [i \in 1 .. 8 |-> 0],
                                         tradeReportId                          |-> [i \in 1 .. 20 |-> 0],
                                         tradeReportRefId                       |-> [i \in 1 .. 20 |-> 0],
                                         tradeId                                |-> [i \in 1 .. 8 |-> 0],
                                         lastShares                             |-> [i \in 1 .. 4 |-> 0],
                                         tradeCaptureLastPx                     |-> [i \in 1 .. 8 |-> 0],
                                         contraBroker                           |-> [i \in 1 .. 4 |-> 0],
                                         reserved1                              |-> [i \in 1 .. 1 |-> 0],
                                         numberOfTradeCaptureConfirmV2Bitfields |-> 0,
                                         tradeCaptureConfirmV2Bitfield1         |-> << >>,
                                         tradeCaptureConfirmV2Bitfield2         |-> << >>,
                                         tradeCaptureConfirmV2Bitfield3         |-> << >>,
                                         tradeCaptureConfirmV2Bitfield4         |-> << >>,
                                         tradeCaptureConfirmV2Bitfield5         |-> << >>,
                                         tradeCaptureConfirmV2Bitfield6         |-> << >>,
                                         tradeCaptureConfirmV2Bitfield7         |-> << >>,
                                         tradeCaptureConfirmV2Bitfield8         |-> << >>,
                                         tradeCaptureConfirmV2Bitfield9         |-> << >>,
                                         tradeCaptureConfirmV2Bitfield10        |-> << >>,
                                         tradeCaptureConfirmV2Bitfield11        |-> << >>,
                                         tradeCaptureConfirmV2Bitfield12        |-> << >>,
                                         tradeCaptureConfirmV2Bitfield13        |-> << >>,
                                         tradeCaptureConfirmV2Bitfield14        |-> << >>,
                                         tradeCaptureConfirmV2TrdCapAckSideGrp  |-> << >>,
                                         execInst                               |-> << >>,
                                         symbol                                 |-> << >>,
                                         currency                               |-> << >>,
                                         idSource                               |-> << >>,
                                         securityId                             |-> << >>,
                                         securityExchange                       |-> << >>,
                                         clearingFirm                           |-> << >>,
                                         orderQty                               |-> << >>,
                                         correctedSize                          |-> << >>,
                                         tradeReportTypeReturn                  |-> << >>,
                                         tradePublishIndicator                  |-> << >>,
                                         rptTime                                |-> << >>,
                                         text                                   |-> << >>,
                                         largeSize                              |-> << >>,
                                         lastMkt                                |-> << >>,
                                         echoText                               |-> << >>,
                                         orderCategory                          |-> << >>,
                                         liquidityProvision                     |-> << >>,
                                         waiverType                             |-> << >>,
                                         priceFormation                         |-> << >>,
                                         clientQualifiedRole                    |-> << >>,
                                         clientId                               |-> << >>,
                                         investorId                             |-> << >>,
                                         executorId                             |-> << >>,
                                         orderOrigination                       |-> << >>,
                                         algorithmicIndicator                   |-> << >>,
                                         deferralReason                         |-> << >>,
                                         investorQualifiedRole                  |-> << >>,
                                         executorQualifiedRole                  |-> << >> ])

(* Trade Capture Confirm V 2 Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCaptureConfirmV2Message ==
    { ZeroTradeCaptureConfirmV2Message }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.transactionTime = one]) : one \in Sample(8) }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.tradeReportId = one]) : one \in Sample(20) }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.tradeReportRefId = one]) : one \in Sample(20) }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.tradeId = one]) : one \in Sample(8) }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.lastShares = one]) : one \in Sample(4) }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.tradeCaptureLastPx = one]) : one \in Sample(8) }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.contraBroker = one]) : one \in Sample(4) }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.reserved1 = one]) : one \in Sample(1) }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 1, !.tradeCaptureConfirmV2Bitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 2, !.tradeCaptureConfirmV2Bitfield2 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 3, !.tradeCaptureConfirmV2Bitfield3 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 4, !.tradeCaptureConfirmV2Bitfield4 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 5, !.tradeCaptureConfirmV2Bitfield5 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 6, !.tradeCaptureConfirmV2Bitfield6 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 7, !.tradeCaptureConfirmV2Bitfield7 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 8, !.tradeCaptureConfirmV2Bitfield8 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 9, !.tradeCaptureConfirmV2Bitfield9 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 10, !.tradeCaptureConfirmV2Bitfield10 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 11, !.tradeCaptureConfirmV2Bitfield11 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 12, !.tradeCaptureConfirmV2Bitfield12 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 13, !.tradeCaptureConfirmV2Bitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 14, !.tradeCaptureConfirmV2Bitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.tradeCaptureConfirmV2TrdCapAckSideGrp = one]) : one \in SampleLists(OneTradeCaptureConfirmV2TrdCapAckSideGrp) }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 1, !.tradeCaptureConfirmV2Bitfield1 = <<1>>, !.tradeCaptureConfirmV2TrdCapAckSideGrp = one]) : one \in SampleLists(OneTradeCaptureConfirmV2TrdCapAckSideGrp) }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 2, !.tradeCaptureConfirmV2Bitfield2 = <<64>>, !.tradeCaptureConfirmV2TrdCapAckSideGrp = one]) : one \in SampleLists(OneTradeCaptureConfirmV2TrdCapAckSideGrp) }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 3, !.tradeCaptureConfirmV2Bitfield3 = <<1>>, !.tradeCaptureConfirmV2TrdCapAckSideGrp = one]) : one \in SampleLists(OneTradeCaptureConfirmV2TrdCapAckSideGrp) }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 4, !.tradeCaptureConfirmV2Bitfield4 = <<64>>, !.tradeCaptureConfirmV2TrdCapAckSideGrp = one]) : one \in SampleLists(OneTradeCaptureConfirmV2TrdCapAckSideGrp) }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 6, !.tradeCaptureConfirmV2Bitfield6 = <<2>>, !.tradeCaptureConfirmV2TrdCapAckSideGrp = one]) : one \in SampleLists(OneTradeCaptureConfirmV2TrdCapAckSideGrp) }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 6, !.tradeCaptureConfirmV2Bitfield6 = <<128>>, !.tradeCaptureConfirmV2TrdCapAckSideGrp = one]) : one \in SampleLists(OneTradeCaptureConfirmV2TrdCapAckSideGrp) }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 8, !.tradeCaptureConfirmV2Bitfield8 = <<1>>, !.tradeCaptureConfirmV2TrdCapAckSideGrp = one]) : one \in SampleLists(OneTradeCaptureConfirmV2TrdCapAckSideGrp) }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 1, !.tradeCaptureConfirmV2Bitfield1 = <<8>>, !.execInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 2, !.tradeCaptureConfirmV2Bitfield2 = <<1>>, !.symbol = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 2, !.tradeCaptureConfirmV2Bitfield2 = <<4>>, !.currency = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 2, !.tradeCaptureConfirmV2Bitfield2 = <<8>>, !.idSource = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 2, !.tradeCaptureConfirmV2Bitfield2 = <<16>>, !.securityId = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 2, !.tradeCaptureConfirmV2Bitfield2 = <<32>>, !.securityExchange = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 3, !.tradeCaptureConfirmV2Bitfield3 = <<2>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 3, !.tradeCaptureConfirmV2Bitfield3 = <<64>>, !.orderQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 4, !.tradeCaptureConfirmV2Bitfield4 = <<32>>, !.correctedSize = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 7, !.tradeCaptureConfirmV2Bitfield7 = <<2>>, !.tradeReportTypeReturn = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 7, !.tradeCaptureConfirmV2Bitfield7 = <<4>>, !.tradePublishIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 7, !.tradeCaptureConfirmV2Bitfield7 = <<4>>, !.rptTime = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 7, !.tradeCaptureConfirmV2Bitfield7 = <<8>>, !.text = one]) : one \in { <<held>> : held \in Sample(60) } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 7, !.tradeCaptureConfirmV2Bitfield7 = <<64>>, !.largeSize = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 7, !.tradeCaptureConfirmV2Bitfield7 = <<128>>, !.lastMkt = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 8, !.tradeCaptureConfirmV2Bitfield8 = <<2>>, !.echoText = one]) : one \in { <<held>> : held \in Sample(64) } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 9, !.tradeCaptureConfirmV2Bitfield9 = <<8>>, !.orderCategory = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 9, !.tradeCaptureConfirmV2Bitfield9 = <<16>>, !.liquidityProvision = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 10, !.tradeCaptureConfirmV2Bitfield10 = <<16>>, !.waiverType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 10, !.tradeCaptureConfirmV2Bitfield10 = <<64>>, !.priceFormation = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 10, !.tradeCaptureConfirmV2Bitfield10 = <<128>>, !.clientQualifiedRole = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 11, !.tradeCaptureConfirmV2Bitfield11 = <<1>>, !.clientId = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 11, !.tradeCaptureConfirmV2Bitfield11 = <<2>>, !.investorId = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 11, !.tradeCaptureConfirmV2Bitfield11 = <<4>>, !.executorId = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 11, !.tradeCaptureConfirmV2Bitfield11 = <<8>>, !.orderOrigination = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 11, !.tradeCaptureConfirmV2Bitfield11 = <<16>>, !.algorithmicIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 11, !.tradeCaptureConfirmV2Bitfield11 = <<32>>, !.deferralReason = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 11, !.tradeCaptureConfirmV2Bitfield11 = <<64>>, !.investorQualifiedRole = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 11, !.tradeCaptureConfirmV2Bitfield11 = <<128>>, !.executorQualifiedRole = one]) : one \in { <<held>> : held \in Sample(1) } }

(***************************************************************************)
(* Trade Capture Report Decline V 2 Trd Cap Ack Side Grp                   *)
(***************************************************************************)

TradeCaptureReportDeclineV2TrdCapAckSideGrp ==
    [ side      : { << >> } \cup { <<held>> : held \in Sample(1) },
      capacity  : { << >> } \cup { <<held>> : held \in Sample(1) },
      account   : { << >> } \cup { <<held>> : held \in Sample(16) },
      partyId   : { << >> } \cup { <<held>> : held \in Sample(4) },
      partyRole : { << >> } \cup { <<held>> : held \in Sample(1) } ]

EncodeTradeCaptureReportDeclineV2TrdCapAckSideGrp(message) ==
    (IF message.side = << >> THEN << >> ELSE message.side[1])
        \o (IF message.capacity = << >> THEN << >> ELSE message.capacity[1])
        \o (IF message.account = << >> THEN << >> ELSE message.account[1])
        \o (IF message.partyId = << >> THEN << >> ELSE message.partyId[1])
        \o (IF message.partyRole = << >> THEN << >> ELSE message.partyRole[1])

DecodeTradeCaptureReportDeclineV2TrdCapAckSideGrp(bytes, handedNumberOfReturnBitfields, handedTradeCaptureReportDeclineV2ReturnBitfield1, handedTradeCaptureReportDeclineV2ReturnBitfield2, handedTradeCaptureReportDeclineV2ReturnBitfield3, handedTradeCaptureReportDeclineV2ReturnBitfield4, handedTradeCaptureReportDeclineV2ReturnBitfield6) ==
    LET side == ReadWhen(handedNumberOfReturnBitfields >= 1 /\ (handedTradeCaptureReportDeclineV2ReturnBitfield1 # << >> /\ handedTradeCaptureReportDeclineV2ReturnBitfield1[1] % 2 > 0), ReadBytes(bytes, 1), bytes) IN IF ~side.ok THEN Fail ELSE
    LET capacity == ReadWhen(handedNumberOfReturnBitfields >= 2 /\ (handedTradeCaptureReportDeclineV2ReturnBitfield2 # << >> /\ (handedTradeCaptureReportDeclineV2ReturnBitfield2[1] \div 64) % 2 > 0), ReadBytes(side.rest, 1), side.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadWhen(handedNumberOfReturnBitfields >= 3 /\ (handedTradeCaptureReportDeclineV2ReturnBitfield3 # << >> /\ handedTradeCaptureReportDeclineV2ReturnBitfield3[1] % 2 > 0), ReadBytes(capacity.rest, 16), capacity.rest) IN IF ~account.ok THEN Fail ELSE
    LET partyId == ReadWhen(handedNumberOfReturnBitfields >= 4 /\ (handedTradeCaptureReportDeclineV2ReturnBitfield4 # << >> /\ (handedTradeCaptureReportDeclineV2ReturnBitfield4[1] \div 64) % 2 > 0), ReadBytes(account.rest, 4), account.rest) IN IF ~partyId.ok THEN Fail ELSE
    LET partyRole == ReadWhen(handedNumberOfReturnBitfields >= 6 /\ (handedTradeCaptureReportDeclineV2ReturnBitfield6 # << >> /\ (handedTradeCaptureReportDeclineV2ReturnBitfield6[1] \div 128) % 2 > 0), ReadBytes(partyId.rest, 1), partyId.rest) IN IF ~partyRole.ok THEN Fail ELSE
    Ok([ side      |-> side.value,
         capacity  |-> capacity.value,
         account   |-> account.value,
         partyId   |-> partyId.value,
         partyRole |-> partyRole.value ], partyRole.rest)

(* Trade Capture Report Decline V 2 Trd Cap Ack Side Grp with each field marked present by fields before it there exactly where they say *)
SettleTradeCaptureReportDeclineV2TrdCapAckSideGrp(message, handedNumberOfReturnBitfields, handedTradeCaptureReportDeclineV2ReturnBitfield1, handedTradeCaptureReportDeclineV2ReturnBitfield2, handedTradeCaptureReportDeclineV2ReturnBitfield3, handedTradeCaptureReportDeclineV2ReturnBitfield4, handedTradeCaptureReportDeclineV2ReturnBitfield6) ==
    LET settled1 == [message EXCEPT !.side = IF handedNumberOfReturnBitfields >= 1 /\ (handedTradeCaptureReportDeclineV2ReturnBitfield1 # << >> /\ handedTradeCaptureReportDeclineV2ReturnBitfield1[1] % 2 > 0) THEN (IF message.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE message.side) ELSE << >>]
        settled2 == [settled1 EXCEPT !.capacity = IF handedNumberOfReturnBitfields >= 2 /\ (handedTradeCaptureReportDeclineV2ReturnBitfield2 # << >> /\ (handedTradeCaptureReportDeclineV2ReturnBitfield2[1] \div 64) % 2 > 0) THEN (IF settled1.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled1.capacity) ELSE << >>]
        settled3 == [settled2 EXCEPT !.account = IF handedNumberOfReturnBitfields >= 3 /\ (handedTradeCaptureReportDeclineV2ReturnBitfield3 # << >> /\ handedTradeCaptureReportDeclineV2ReturnBitfield3[1] % 2 > 0) THEN (IF settled2.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled2.account) ELSE << >>]
        settled4 == [settled3 EXCEPT !.partyId = IF handedNumberOfReturnBitfields >= 4 /\ (handedTradeCaptureReportDeclineV2ReturnBitfield4 # << >> /\ (handedTradeCaptureReportDeclineV2ReturnBitfield4[1] \div 64) % 2 > 0) THEN (IF settled3.partyId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled3.partyId) ELSE << >>]
        settled5 == [settled4 EXCEPT !.partyRole = IF handedNumberOfReturnBitfields >= 6 /\ (handedTradeCaptureReportDeclineV2ReturnBitfield6 # << >> /\ (handedTradeCaptureReportDeclineV2ReturnBitfield6[1] \div 128) % 2 > 0) THEN (IF settled4.partyRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled4.partyRole) ELSE << >>]
    IN  settled5

ZeroTradeCaptureReportDeclineV2TrdCapAckSideGrp ==
    SettleTradeCaptureReportDeclineV2TrdCapAckSideGrp([ side      |-> << >>,
                                                        capacity  |-> << >>,
                                                        account   |-> << >>,
                                                        partyId   |-> << >>,
                                                        partyRole |-> << >> ], 0, << >>, << >>, << >>, << >>, << >>)

(* Trade Capture Report Decline V 2 Trd Cap Ack Side Grp at zero, then each field in turn at the values it is checked at *)
CheckedTradeCaptureReportDeclineV2TrdCapAckSideGrp ==
    { [given |-> <<0, << >>, << >>, << >>, << >>, << >>>>, message |-> ZeroTradeCaptureReportDeclineV2TrdCapAckSideGrp] }
        \cup { [given |-> <<1, <<1>>, << >>, << >>, << >>, << >>>>, message |-> SettleTradeCaptureReportDeclineV2TrdCapAckSideGrp([ZeroTradeCaptureReportDeclineV2TrdCapAckSideGrp EXCEPT !.side = one], 1, <<1>>, << >>, << >>, << >>, << >>)] : one \in { <<held>> : held \in Sample(1) } }
        \cup { [given |-> <<2, << >>, <<64>>, << >>, << >>, << >>>>, message |-> SettleTradeCaptureReportDeclineV2TrdCapAckSideGrp([ZeroTradeCaptureReportDeclineV2TrdCapAckSideGrp EXCEPT !.capacity = one], 2, << >>, <<64>>, << >>, << >>, << >>)] : one \in { <<held>> : held \in Sample(1) } }
        \cup { [given |-> <<3, << >>, << >>, <<1>>, << >>, << >>>>, message |-> SettleTradeCaptureReportDeclineV2TrdCapAckSideGrp([ZeroTradeCaptureReportDeclineV2TrdCapAckSideGrp EXCEPT !.account = one], 3, << >>, << >>, <<1>>, << >>, << >>)] : one \in { <<held>> : held \in Sample(16) } }
        \cup { [given |-> <<4, << >>, << >>, << >>, <<64>>, << >>>>, message |-> SettleTradeCaptureReportDeclineV2TrdCapAckSideGrp([ZeroTradeCaptureReportDeclineV2TrdCapAckSideGrp EXCEPT !.partyId = one], 4, << >>, << >>, << >>, <<64>>, << >>)] : one \in { <<held>> : held \in Sample(4) } }
        \cup { [given |-> <<6, << >>, << >>, << >>, << >>, <<128>>>>, message |-> SettleTradeCaptureReportDeclineV2TrdCapAckSideGrp([ZeroTradeCaptureReportDeclineV2TrdCapAckSideGrp EXCEPT !.partyRole = one], 6, << >>, << >>, << >>, << >>, <<128>>)] : one \in { <<held>> : held \in Sample(1) } }

(* A run of Trade Capture Report Decline V 2 Trd Cap Ack Side Grp, written one after another *)
RECURSIVE EncodeTradeCaptureReportDeclineV2TrdCapAckSideGrpList(_)
EncodeTradeCaptureReportDeclineV2TrdCapAckSideGrpList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTradeCaptureReportDeclineV2TrdCapAckSideGrp(Head(messages)) \o EncodeTradeCaptureReportDeclineV2TrdCapAckSideGrpList(Tail(messages))

(* As many Trade Capture Report Decline V 2 Trd Cap Ack Side Grp as the field that counts them says *)
RECURSIVE ReadTradeCaptureReportDeclineV2TrdCapAckSideGrpList(_, _, _, _, _, _, _, _)
ReadTradeCaptureReportDeclineV2TrdCapAckSideGrpList(bytes, count, handedNumberOfReturnBitfields, handedTradeCaptureReportDeclineV2ReturnBitfield1, handedTradeCaptureReportDeclineV2ReturnBitfield2, handedTradeCaptureReportDeclineV2ReturnBitfield3, handedTradeCaptureReportDeclineV2ReturnBitfield4, handedTradeCaptureReportDeclineV2ReturnBitfield6) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeTradeCaptureReportDeclineV2TrdCapAckSideGrp(bytes, handedNumberOfReturnBitfields, handedTradeCaptureReportDeclineV2ReturnBitfield1, handedTradeCaptureReportDeclineV2ReturnBitfield2, handedTradeCaptureReportDeclineV2ReturnBitfield3, handedTradeCaptureReportDeclineV2ReturnBitfield4, handedTradeCaptureReportDeclineV2ReturnBitfield6)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTradeCaptureReportDeclineV2TrdCapAckSideGrpList(one.rest, count - 1, handedNumberOfReturnBitfields, handedTradeCaptureReportDeclineV2ReturnBitfield1, handedTradeCaptureReportDeclineV2ReturnBitfield2, handedTradeCaptureReportDeclineV2ReturnBitfield3, handedTradeCaptureReportDeclineV2ReturnBitfield4, handedTradeCaptureReportDeclineV2ReturnBitfield6)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Trade Capture Report Decline V 2 Trd Cap Ack Side Grp of each kind, for the lists that carry them *)
OneTradeCaptureReportDeclineV2TrdCapAckSideGrp == { ZeroTradeCaptureReportDeclineV2TrdCapAckSideGrp }

(***************************************************************************)
(* Trade Capture Report Decline V 2 Message                                *)
(***************************************************************************)

TradeCaptureReportDeclineV2Message ==
    [ transactionTime                             : Sample(8),
      tradeReportId                               : Sample(20),
      tradeReportRefId                            : Sample(20),
      tradeId                                     : Sample(8),
      lastShares                                  : Sample(4),
      tradeCaptureLastPx                          : Sample(8),
      contraBroker                                : Sample(4),
      reason                                      : Sample(1),
      text                                        : Sample(60),
      reserved1                                   : Sample(1),
      numberOfReturnBitfields                     : 0 .. 255,
      tradeCaptureReportDeclineV2ReturnBitfield1  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCaptureReportDeclineV2ReturnBitfield2  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCaptureReportDeclineV2ReturnBitfield3  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCaptureReportDeclineV2ReturnBitfield4  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCaptureReportDeclineV2ReturnBitfield5  : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCaptureReportDeclineV2ReturnBitfield6  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCaptureReportDeclineV2ReturnBitfield7  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCaptureReportDeclineV2ReturnBitfield8  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCaptureReportDeclineV2ReturnBitfield9  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCaptureReportDeclineV2ReturnBitfield10 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCaptureReportDeclineV2ReturnBitfield11 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCaptureReportDeclineV2ReturnBitfield12 : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCaptureReportDeclineV2ReturnBitfield13 : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCaptureReportDeclineV2ReturnBitfield14 : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCaptureReportDeclineV2TrdCapAckSideGrp : SampleLists(OneTradeCaptureReportDeclineV2TrdCapAckSideGrp),
      execInst                                    : { << >> } \cup { <<held>> : held \in Sample(1) },
      symbol                                      : { << >> } \cup { <<held>> : held \in Sample(8) },
      currency                                    : { << >> } \cup { <<held>> : held \in Sample(3) },
      idSource                                    : { << >> } \cup { <<held>> : held \in Sample(1) },
      securityId                                  : { << >> } \cup { <<held>> : held \in Sample(16) },
      securityExchange                            : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingFirm                                : { << >> } \cup { <<held>> : held \in Sample(4) },
      orderQty                                    : { << >> } \cup { <<held>> : held \in Sample(4) },
      tradeReportTypeReturn                       : { << >> } \cup { <<held>> : held \in Sample(2) },
      tradePublishIndicator                       : { << >> } \cup { <<held>> : held \in Sample(1) },
      rptTime                                     : { << >> } \cup { <<held>> : held \in Sample(8) },
      largeSize                                   : { << >> } \cup { <<held>> : held \in Sample(8) },
      lastMkt                                     : { << >> } \cup { <<held>> : held \in Sample(4) },
      echoText                                    : { << >> } \cup { <<held>> : held \in Sample(64) },
      liquidityProvision                          : { << >> } \cup { <<held>> : held \in Sample(1) },
      waiverType                                  : { << >> } \cup { <<held>> : held \in Sample(1) },
      priceFormation                              : { << >> } \cup { <<held>> : held \in Sample(1) },
      clientQualifiedRole                         : { << >> } \cup { <<held>> : held \in Sample(1) },
      clientId                                    : { << >> } \cup { <<held>> : held \in Sample(4) },
      investorId                                  : { << >> } \cup { <<held>> : held \in Sample(4) },
      executorId                                  : { << >> } \cup { <<held>> : held \in Sample(4) },
      orderOrigination                            : { << >> } \cup { <<held>> : held \in Sample(1) },
      algorithmicIndicator                        : { << >> } \cup { <<held>> : held \in Sample(1) },
      investorQualifiedRole                       : { << >> } \cup { <<held>> : held \in Sample(1) },
      executorQualifiedRole                       : { << >> } \cup { <<held>> : held \in Sample(1) } ]

EncodeTradeCaptureReportDeclineV2Message(message) ==
    message.transactionTime
        \o message.tradeReportId
        \o message.tradeReportRefId
        \o message.tradeId
        \o message.lastShares
        \o message.tradeCaptureLastPx
        \o message.contraBroker
        \o message.reason
        \o message.text
        \o message.reserved1
        \o EncodeUIntBE(message.numberOfReturnBitfields, 1)
        \o (IF message.tradeCaptureReportDeclineV2ReturnBitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCaptureReportDeclineV2ReturnBitfield1[1], 1))
        \o (IF message.tradeCaptureReportDeclineV2ReturnBitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCaptureReportDeclineV2ReturnBitfield2[1], 1))
        \o (IF message.tradeCaptureReportDeclineV2ReturnBitfield3 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCaptureReportDeclineV2ReturnBitfield3[1], 1))
        \o (IF message.tradeCaptureReportDeclineV2ReturnBitfield4 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCaptureReportDeclineV2ReturnBitfield4[1], 1))
        \o (IF message.tradeCaptureReportDeclineV2ReturnBitfield5 = << >> THEN << >> ELSE message.tradeCaptureReportDeclineV2ReturnBitfield5[1])
        \o (IF message.tradeCaptureReportDeclineV2ReturnBitfield6 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCaptureReportDeclineV2ReturnBitfield6[1], 1))
        \o (IF message.tradeCaptureReportDeclineV2ReturnBitfield7 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCaptureReportDeclineV2ReturnBitfield7[1], 1))
        \o (IF message.tradeCaptureReportDeclineV2ReturnBitfield8 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCaptureReportDeclineV2ReturnBitfield8[1], 1))
        \o (IF message.tradeCaptureReportDeclineV2ReturnBitfield9 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCaptureReportDeclineV2ReturnBitfield9[1], 1))
        \o (IF message.tradeCaptureReportDeclineV2ReturnBitfield10 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCaptureReportDeclineV2ReturnBitfield10[1], 1))
        \o (IF message.tradeCaptureReportDeclineV2ReturnBitfield11 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCaptureReportDeclineV2ReturnBitfield11[1], 1))
        \o (IF message.tradeCaptureReportDeclineV2ReturnBitfield12 = << >> THEN << >> ELSE message.tradeCaptureReportDeclineV2ReturnBitfield12[1])
        \o (IF message.tradeCaptureReportDeclineV2ReturnBitfield13 = << >> THEN << >> ELSE message.tradeCaptureReportDeclineV2ReturnBitfield13[1])
        \o (IF message.tradeCaptureReportDeclineV2ReturnBitfield14 = << >> THEN << >> ELSE message.tradeCaptureReportDeclineV2ReturnBitfield14[1])
        \o EncodeUIntBE(Len(message.tradeCaptureReportDeclineV2TrdCapAckSideGrp), 1)
        \o EncodeTradeCaptureReportDeclineV2TrdCapAckSideGrpList(message.tradeCaptureReportDeclineV2TrdCapAckSideGrp)
        \o (IF message.execInst = << >> THEN << >> ELSE message.execInst[1])
        \o (IF message.symbol = << >> THEN << >> ELSE message.symbol[1])
        \o (IF message.currency = << >> THEN << >> ELSE message.currency[1])
        \o (IF message.idSource = << >> THEN << >> ELSE message.idSource[1])
        \o (IF message.securityId = << >> THEN << >> ELSE message.securityId[1])
        \o (IF message.securityExchange = << >> THEN << >> ELSE message.securityExchange[1])
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])
        \o (IF message.orderQty = << >> THEN << >> ELSE message.orderQty[1])
        \o (IF message.tradeReportTypeReturn = << >> THEN << >> ELSE message.tradeReportTypeReturn[1])
        \o (IF message.tradePublishIndicator = << >> THEN << >> ELSE message.tradePublishIndicator[1])
        \o (IF message.rptTime = << >> THEN << >> ELSE message.rptTime[1])
        \o (IF message.largeSize = << >> THEN << >> ELSE message.largeSize[1])
        \o (IF message.lastMkt = << >> THEN << >> ELSE message.lastMkt[1])
        \o (IF message.echoText = << >> THEN << >> ELSE message.echoText[1])
        \o (IF message.liquidityProvision = << >> THEN << >> ELSE message.liquidityProvision[1])
        \o (IF message.waiverType = << >> THEN << >> ELSE message.waiverType[1])
        \o (IF message.priceFormation = << >> THEN << >> ELSE message.priceFormation[1])
        \o (IF message.clientQualifiedRole = << >> THEN << >> ELSE message.clientQualifiedRole[1])
        \o (IF message.clientId = << >> THEN << >> ELSE message.clientId[1])
        \o (IF message.investorId = << >> THEN << >> ELSE message.investorId[1])
        \o (IF message.executorId = << >> THEN << >> ELSE message.executorId[1])
        \o (IF message.orderOrigination = << >> THEN << >> ELSE message.orderOrigination[1])
        \o (IF message.algorithmicIndicator = << >> THEN << >> ELSE message.algorithmicIndicator[1])
        \o (IF message.investorQualifiedRole = << >> THEN << >> ELSE message.investorQualifiedRole[1])
        \o (IF message.executorQualifiedRole = << >> THEN << >> ELSE message.executorQualifiedRole[1])

DecodeTradeCaptureReportDeclineV2Message(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(transactionTime.rest, 20) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET tradeReportRefId == ReadBytes(tradeReportId.rest, 20) IN IF ~tradeReportRefId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(tradeReportRefId.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET lastShares == ReadBytes(tradeId.rest, 4) IN IF ~lastShares.ok THEN Fail ELSE
    LET tradeCaptureLastPx == ReadBytes(lastShares.rest, 8) IN IF ~tradeCaptureLastPx.ok THEN Fail ELSE
    LET contraBroker == ReadBytes(tradeCaptureLastPx.rest, 4) IN IF ~contraBroker.ok THEN Fail ELSE
    LET reason == ReadBytes(contraBroker.rest, 1) IN IF ~reason.ok THEN Fail ELSE
    LET text == ReadBytes(reason.rest, 60) IN IF ~text.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(text.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET numberOfReturnBitfields == ReadUIntBE(reserved1.rest, 1) IN IF ~numberOfReturnBitfields.ok THEN Fail ELSE
    LET tradeCaptureReportDeclineV2ReturnBitfield1 == ReadWhen(numberOfReturnBitfields.value >= 1, ReadUIntLE(numberOfReturnBitfields.rest, 1), numberOfReturnBitfields.rest) IN IF ~tradeCaptureReportDeclineV2ReturnBitfield1.ok THEN Fail ELSE
    LET tradeCaptureReportDeclineV2ReturnBitfield2 == ReadWhen(numberOfReturnBitfields.value >= 2, ReadUIntLE(tradeCaptureReportDeclineV2ReturnBitfield1.rest, 1), tradeCaptureReportDeclineV2ReturnBitfield1.rest) IN IF ~tradeCaptureReportDeclineV2ReturnBitfield2.ok THEN Fail ELSE
    LET tradeCaptureReportDeclineV2ReturnBitfield3 == ReadWhen(numberOfReturnBitfields.value >= 3, ReadUIntLE(tradeCaptureReportDeclineV2ReturnBitfield2.rest, 1), tradeCaptureReportDeclineV2ReturnBitfield2.rest) IN IF ~tradeCaptureReportDeclineV2ReturnBitfield3.ok THEN Fail ELSE
    LET tradeCaptureReportDeclineV2ReturnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadUIntLE(tradeCaptureReportDeclineV2ReturnBitfield3.rest, 1), tradeCaptureReportDeclineV2ReturnBitfield3.rest) IN IF ~tradeCaptureReportDeclineV2ReturnBitfield4.ok THEN Fail ELSE
    LET tradeCaptureReportDeclineV2ReturnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadBytes(tradeCaptureReportDeclineV2ReturnBitfield4.rest, 1), tradeCaptureReportDeclineV2ReturnBitfield4.rest) IN IF ~tradeCaptureReportDeclineV2ReturnBitfield5.ok THEN Fail ELSE
    LET tradeCaptureReportDeclineV2ReturnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadUIntLE(tradeCaptureReportDeclineV2ReturnBitfield5.rest, 1), tradeCaptureReportDeclineV2ReturnBitfield5.rest) IN IF ~tradeCaptureReportDeclineV2ReturnBitfield6.ok THEN Fail ELSE
    LET tradeCaptureReportDeclineV2ReturnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadUIntLE(tradeCaptureReportDeclineV2ReturnBitfield6.rest, 1), tradeCaptureReportDeclineV2ReturnBitfield6.rest) IN IF ~tradeCaptureReportDeclineV2ReturnBitfield7.ok THEN Fail ELSE
    LET tradeCaptureReportDeclineV2ReturnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadUIntLE(tradeCaptureReportDeclineV2ReturnBitfield7.rest, 1), tradeCaptureReportDeclineV2ReturnBitfield7.rest) IN IF ~tradeCaptureReportDeclineV2ReturnBitfield8.ok THEN Fail ELSE
    LET tradeCaptureReportDeclineV2ReturnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadUIntLE(tradeCaptureReportDeclineV2ReturnBitfield8.rest, 1), tradeCaptureReportDeclineV2ReturnBitfield8.rest) IN IF ~tradeCaptureReportDeclineV2ReturnBitfield9.ok THEN Fail ELSE
    LET tradeCaptureReportDeclineV2ReturnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadUIntLE(tradeCaptureReportDeclineV2ReturnBitfield9.rest, 1), tradeCaptureReportDeclineV2ReturnBitfield9.rest) IN IF ~tradeCaptureReportDeclineV2ReturnBitfield10.ok THEN Fail ELSE
    LET tradeCaptureReportDeclineV2ReturnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadUIntLE(tradeCaptureReportDeclineV2ReturnBitfield10.rest, 1), tradeCaptureReportDeclineV2ReturnBitfield10.rest) IN IF ~tradeCaptureReportDeclineV2ReturnBitfield11.ok THEN Fail ELSE
    LET tradeCaptureReportDeclineV2ReturnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadBytes(tradeCaptureReportDeclineV2ReturnBitfield11.rest, 1), tradeCaptureReportDeclineV2ReturnBitfield11.rest) IN IF ~tradeCaptureReportDeclineV2ReturnBitfield12.ok THEN Fail ELSE
    LET tradeCaptureReportDeclineV2ReturnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(tradeCaptureReportDeclineV2ReturnBitfield12.rest, 1), tradeCaptureReportDeclineV2ReturnBitfield12.rest) IN IF ~tradeCaptureReportDeclineV2ReturnBitfield13.ok THEN Fail ELSE
    LET tradeCaptureReportDeclineV2ReturnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(tradeCaptureReportDeclineV2ReturnBitfield13.rest, 1), tradeCaptureReportDeclineV2ReturnBitfield13.rest) IN IF ~tradeCaptureReportDeclineV2ReturnBitfield14.ok THEN Fail ELSE
    LET noSides == ReadUIntBE(tradeCaptureReportDeclineV2ReturnBitfield14.rest, 1) IN IF ~noSides.ok THEN Fail ELSE
    LET tradeCaptureReportDeclineV2TrdCapAckSideGrp == ReadTradeCaptureReportDeclineV2TrdCapAckSideGrpList(noSides.rest, noSides.value, numberOfReturnBitfields.value, tradeCaptureReportDeclineV2ReturnBitfield1.value, tradeCaptureReportDeclineV2ReturnBitfield2.value, tradeCaptureReportDeclineV2ReturnBitfield3.value, tradeCaptureReportDeclineV2ReturnBitfield4.value, tradeCaptureReportDeclineV2ReturnBitfield6.value) IN IF ~tradeCaptureReportDeclineV2TrdCapAckSideGrp.ok THEN Fail ELSE
    LET execInst == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (tradeCaptureReportDeclineV2ReturnBitfield1.value # << >> /\ (tradeCaptureReportDeclineV2ReturnBitfield1.value[1] \div 8) % 2 > 0), ReadBytes(tradeCaptureReportDeclineV2TrdCapAckSideGrp.rest, 1), tradeCaptureReportDeclineV2TrdCapAckSideGrp.rest) IN IF ~execInst.ok THEN Fail ELSE
    LET symbol == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (tradeCaptureReportDeclineV2ReturnBitfield2.value # << >> /\ tradeCaptureReportDeclineV2ReturnBitfield2.value[1] % 2 > 0), ReadBytes(execInst.rest, 8), execInst.rest) IN IF ~symbol.ok THEN Fail ELSE
    LET currency == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (tradeCaptureReportDeclineV2ReturnBitfield2.value # << >> /\ (tradeCaptureReportDeclineV2ReturnBitfield2.value[1] \div 4) % 2 > 0), ReadBytes(symbol.rest, 3), symbol.rest) IN IF ~currency.ok THEN Fail ELSE
    LET idSource == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (tradeCaptureReportDeclineV2ReturnBitfield2.value # << >> /\ (tradeCaptureReportDeclineV2ReturnBitfield2.value[1] \div 8) % 2 > 0), ReadBytes(currency.rest, 1), currency.rest) IN IF ~idSource.ok THEN Fail ELSE
    LET securityId == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (tradeCaptureReportDeclineV2ReturnBitfield2.value # << >> /\ (tradeCaptureReportDeclineV2ReturnBitfield2.value[1] \div 16) % 2 > 0), ReadBytes(idSource.rest, 16), idSource.rest) IN IF ~securityId.ok THEN Fail ELSE
    LET securityExchange == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (tradeCaptureReportDeclineV2ReturnBitfield2.value # << >> /\ (tradeCaptureReportDeclineV2ReturnBitfield2.value[1] \div 32) % 2 > 0), ReadBytes(securityId.rest, 4), securityId.rest) IN IF ~securityExchange.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (tradeCaptureReportDeclineV2ReturnBitfield3.value # << >> /\ (tradeCaptureReportDeclineV2ReturnBitfield3.value[1] \div 2) % 2 > 0), ReadBytes(securityExchange.rest, 4), securityExchange.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET orderQty == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (tradeCaptureReportDeclineV2ReturnBitfield3.value # << >> /\ (tradeCaptureReportDeclineV2ReturnBitfield3.value[1] \div 64) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~orderQty.ok THEN Fail ELSE
    LET tradeReportTypeReturn == ReadWhen(numberOfReturnBitfields.value >= 7 /\ (tradeCaptureReportDeclineV2ReturnBitfield7.value # << >> /\ (tradeCaptureReportDeclineV2ReturnBitfield7.value[1] \div 2) % 2 > 0), ReadBytes(orderQty.rest, 2), orderQty.rest) IN IF ~tradeReportTypeReturn.ok THEN Fail ELSE
    LET tradePublishIndicator == ReadWhen(numberOfReturnBitfields.value >= 7 /\ (tradeCaptureReportDeclineV2ReturnBitfield7.value # << >> /\ (tradeCaptureReportDeclineV2ReturnBitfield7.value[1] \div 4) % 2 > 0), ReadBytes(tradeReportTypeReturn.rest, 1), tradeReportTypeReturn.rest) IN IF ~tradePublishIndicator.ok THEN Fail ELSE
    LET rptTime == ReadWhen(numberOfReturnBitfields.value >= 7 /\ (tradeCaptureReportDeclineV2ReturnBitfield7.value # << >> /\ (tradeCaptureReportDeclineV2ReturnBitfield7.value[1] \div 4) % 2 > 0), ReadBytes(tradePublishIndicator.rest, 8), tradePublishIndicator.rest) IN IF ~rptTime.ok THEN Fail ELSE
    LET largeSize == ReadWhen(numberOfReturnBitfields.value >= 7 /\ (tradeCaptureReportDeclineV2ReturnBitfield7.value # << >> /\ (tradeCaptureReportDeclineV2ReturnBitfield7.value[1] \div 64) % 2 > 0), ReadBytes(rptTime.rest, 8), rptTime.rest) IN IF ~largeSize.ok THEN Fail ELSE
    LET lastMkt == ReadWhen(numberOfReturnBitfields.value >= 7 /\ (tradeCaptureReportDeclineV2ReturnBitfield7.value # << >> /\ (tradeCaptureReportDeclineV2ReturnBitfield7.value[1] \div 128) % 2 > 0), ReadBytes(largeSize.rest, 4), largeSize.rest) IN IF ~lastMkt.ok THEN Fail ELSE
    LET echoText == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (tradeCaptureReportDeclineV2ReturnBitfield8.value # << >> /\ (tradeCaptureReportDeclineV2ReturnBitfield8.value[1] \div 2) % 2 > 0), ReadBytes(lastMkt.rest, 64), lastMkt.rest) IN IF ~echoText.ok THEN Fail ELSE
    LET liquidityProvision == ReadWhen(numberOfReturnBitfields.value >= 9 /\ (tradeCaptureReportDeclineV2ReturnBitfield9.value # << >> /\ (tradeCaptureReportDeclineV2ReturnBitfield9.value[1] \div 16) % 2 > 0), ReadBytes(echoText.rest, 1), echoText.rest) IN IF ~liquidityProvision.ok THEN Fail ELSE
    LET waiverType == ReadWhen(numberOfReturnBitfields.value >= 10 /\ (tradeCaptureReportDeclineV2ReturnBitfield10.value # << >> /\ (tradeCaptureReportDeclineV2ReturnBitfield10.value[1] \div 16) % 2 > 0), ReadBytes(liquidityProvision.rest, 1), liquidityProvision.rest) IN IF ~waiverType.ok THEN Fail ELSE
    LET priceFormation == ReadWhen(numberOfReturnBitfields.value >= 10 /\ (tradeCaptureReportDeclineV2ReturnBitfield10.value # << >> /\ (tradeCaptureReportDeclineV2ReturnBitfield10.value[1] \div 64) % 2 > 0), ReadBytes(waiverType.rest, 1), waiverType.rest) IN IF ~priceFormation.ok THEN Fail ELSE
    LET clientQualifiedRole == ReadWhen(numberOfReturnBitfields.value >= 10 /\ (tradeCaptureReportDeclineV2ReturnBitfield10.value # << >> /\ (tradeCaptureReportDeclineV2ReturnBitfield10.value[1] \div 128) % 2 > 0), ReadBytes(priceFormation.rest, 1), priceFormation.rest) IN IF ~clientQualifiedRole.ok THEN Fail ELSE
    LET clientId == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (tradeCaptureReportDeclineV2ReturnBitfield11.value # << >> /\ tradeCaptureReportDeclineV2ReturnBitfield11.value[1] % 2 > 0), ReadBytes(clientQualifiedRole.rest, 4), clientQualifiedRole.rest) IN IF ~clientId.ok THEN Fail ELSE
    LET investorId == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (tradeCaptureReportDeclineV2ReturnBitfield11.value # << >> /\ (tradeCaptureReportDeclineV2ReturnBitfield11.value[1] \div 2) % 2 > 0), ReadBytes(clientId.rest, 4), clientId.rest) IN IF ~investorId.ok THEN Fail ELSE
    LET executorId == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (tradeCaptureReportDeclineV2ReturnBitfield11.value # << >> /\ (tradeCaptureReportDeclineV2ReturnBitfield11.value[1] \div 4) % 2 > 0), ReadBytes(investorId.rest, 4), investorId.rest) IN IF ~executorId.ok THEN Fail ELSE
    LET orderOrigination == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (tradeCaptureReportDeclineV2ReturnBitfield11.value # << >> /\ (tradeCaptureReportDeclineV2ReturnBitfield11.value[1] \div 8) % 2 > 0), ReadBytes(executorId.rest, 1), executorId.rest) IN IF ~orderOrigination.ok THEN Fail ELSE
    LET algorithmicIndicator == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (tradeCaptureReportDeclineV2ReturnBitfield11.value # << >> /\ (tradeCaptureReportDeclineV2ReturnBitfield11.value[1] \div 16) % 2 > 0), ReadBytes(orderOrigination.rest, 1), orderOrigination.rest) IN IF ~algorithmicIndicator.ok THEN Fail ELSE
    LET investorQualifiedRole == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (tradeCaptureReportDeclineV2ReturnBitfield11.value # << >> /\ (tradeCaptureReportDeclineV2ReturnBitfield11.value[1] \div 64) % 2 > 0), ReadBytes(algorithmicIndicator.rest, 1), algorithmicIndicator.rest) IN IF ~investorQualifiedRole.ok THEN Fail ELSE
    LET executorQualifiedRole == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (tradeCaptureReportDeclineV2ReturnBitfield11.value # << >> /\ (tradeCaptureReportDeclineV2ReturnBitfield11.value[1] \div 128) % 2 > 0), ReadBytes(investorQualifiedRole.rest, 1), investorQualifiedRole.rest) IN IF ~executorQualifiedRole.ok THEN Fail ELSE
    Ok([ transactionTime                             |-> transactionTime.value,
         tradeReportId                               |-> tradeReportId.value,
         tradeReportRefId                            |-> tradeReportRefId.value,
         tradeId                                     |-> tradeId.value,
         lastShares                                  |-> lastShares.value,
         tradeCaptureLastPx                          |-> tradeCaptureLastPx.value,
         contraBroker                                |-> contraBroker.value,
         reason                                      |-> reason.value,
         text                                        |-> text.value,
         reserved1                                   |-> reserved1.value,
         numberOfReturnBitfields                     |-> numberOfReturnBitfields.value,
         tradeCaptureReportDeclineV2ReturnBitfield1  |-> tradeCaptureReportDeclineV2ReturnBitfield1.value,
         tradeCaptureReportDeclineV2ReturnBitfield2  |-> tradeCaptureReportDeclineV2ReturnBitfield2.value,
         tradeCaptureReportDeclineV2ReturnBitfield3  |-> tradeCaptureReportDeclineV2ReturnBitfield3.value,
         tradeCaptureReportDeclineV2ReturnBitfield4  |-> tradeCaptureReportDeclineV2ReturnBitfield4.value,
         tradeCaptureReportDeclineV2ReturnBitfield5  |-> tradeCaptureReportDeclineV2ReturnBitfield5.value,
         tradeCaptureReportDeclineV2ReturnBitfield6  |-> tradeCaptureReportDeclineV2ReturnBitfield6.value,
         tradeCaptureReportDeclineV2ReturnBitfield7  |-> tradeCaptureReportDeclineV2ReturnBitfield7.value,
         tradeCaptureReportDeclineV2ReturnBitfield8  |-> tradeCaptureReportDeclineV2ReturnBitfield8.value,
         tradeCaptureReportDeclineV2ReturnBitfield9  |-> tradeCaptureReportDeclineV2ReturnBitfield9.value,
         tradeCaptureReportDeclineV2ReturnBitfield10 |-> tradeCaptureReportDeclineV2ReturnBitfield10.value,
         tradeCaptureReportDeclineV2ReturnBitfield11 |-> tradeCaptureReportDeclineV2ReturnBitfield11.value,
         tradeCaptureReportDeclineV2ReturnBitfield12 |-> tradeCaptureReportDeclineV2ReturnBitfield12.value,
         tradeCaptureReportDeclineV2ReturnBitfield13 |-> tradeCaptureReportDeclineV2ReturnBitfield13.value,
         tradeCaptureReportDeclineV2ReturnBitfield14 |-> tradeCaptureReportDeclineV2ReturnBitfield14.value,
         tradeCaptureReportDeclineV2TrdCapAckSideGrp |-> tradeCaptureReportDeclineV2TrdCapAckSideGrp.value,
         execInst                                    |-> execInst.value,
         symbol                                      |-> symbol.value,
         currency                                    |-> currency.value,
         idSource                                    |-> idSource.value,
         securityId                                  |-> securityId.value,
         securityExchange                            |-> securityExchange.value,
         clearingFirm                                |-> clearingFirm.value,
         orderQty                                    |-> orderQty.value,
         tradeReportTypeReturn                       |-> tradeReportTypeReturn.value,
         tradePublishIndicator                       |-> tradePublishIndicator.value,
         rptTime                                     |-> rptTime.value,
         largeSize                                   |-> largeSize.value,
         lastMkt                                     |-> lastMkt.value,
         echoText                                    |-> echoText.value,
         liquidityProvision                          |-> liquidityProvision.value,
         waiverType                                  |-> waiverType.value,
         priceFormation                              |-> priceFormation.value,
         clientQualifiedRole                         |-> clientQualifiedRole.value,
         clientId                                    |-> clientId.value,
         investorId                                  |-> investorId.value,
         executorId                                  |-> executorId.value,
         orderOrigination                            |-> orderOrigination.value,
         algorithmicIndicator                        |-> algorithmicIndicator.value,
         investorQualifiedRole                       |-> investorQualifiedRole.value,
         executorQualifiedRole                       |-> executorQualifiedRole.value ], executorQualifiedRole.rest)

(* Trade Capture Report Decline V 2 Message with each field marked present by fields before it there exactly where they say *)
SettleTradeCaptureReportDeclineV2Message(message) ==
    LET settled1 == [message EXCEPT !.tradeCaptureReportDeclineV2ReturnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.tradeCaptureReportDeclineV2ReturnBitfield1 = << >> THEN <<0>> ELSE message.tradeCaptureReportDeclineV2ReturnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.tradeCaptureReportDeclineV2ReturnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.tradeCaptureReportDeclineV2ReturnBitfield2 = << >> THEN <<0>> ELSE settled1.tradeCaptureReportDeclineV2ReturnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.tradeCaptureReportDeclineV2ReturnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.tradeCaptureReportDeclineV2ReturnBitfield3 = << >> THEN <<0>> ELSE settled2.tradeCaptureReportDeclineV2ReturnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.tradeCaptureReportDeclineV2ReturnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.tradeCaptureReportDeclineV2ReturnBitfield4 = << >> THEN <<0>> ELSE settled3.tradeCaptureReportDeclineV2ReturnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.tradeCaptureReportDeclineV2ReturnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.tradeCaptureReportDeclineV2ReturnBitfield5 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled4.tradeCaptureReportDeclineV2ReturnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.tradeCaptureReportDeclineV2ReturnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.tradeCaptureReportDeclineV2ReturnBitfield6 = << >> THEN <<0>> ELSE settled5.tradeCaptureReportDeclineV2ReturnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.tradeCaptureReportDeclineV2ReturnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.tradeCaptureReportDeclineV2ReturnBitfield7 = << >> THEN <<0>> ELSE settled6.tradeCaptureReportDeclineV2ReturnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.tradeCaptureReportDeclineV2ReturnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.tradeCaptureReportDeclineV2ReturnBitfield8 = << >> THEN <<0>> ELSE settled7.tradeCaptureReportDeclineV2ReturnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.tradeCaptureReportDeclineV2ReturnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.tradeCaptureReportDeclineV2ReturnBitfield9 = << >> THEN <<0>> ELSE settled8.tradeCaptureReportDeclineV2ReturnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.tradeCaptureReportDeclineV2ReturnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.tradeCaptureReportDeclineV2ReturnBitfield10 = << >> THEN <<0>> ELSE settled9.tradeCaptureReportDeclineV2ReturnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.tradeCaptureReportDeclineV2ReturnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.tradeCaptureReportDeclineV2ReturnBitfield11 = << >> THEN <<0>> ELSE settled10.tradeCaptureReportDeclineV2ReturnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.tradeCaptureReportDeclineV2ReturnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.tradeCaptureReportDeclineV2ReturnBitfield12 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.tradeCaptureReportDeclineV2ReturnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.tradeCaptureReportDeclineV2ReturnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.tradeCaptureReportDeclineV2ReturnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.tradeCaptureReportDeclineV2ReturnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.tradeCaptureReportDeclineV2ReturnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.tradeCaptureReportDeclineV2ReturnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.tradeCaptureReportDeclineV2ReturnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.tradeCaptureReportDeclineV2TrdCapAckSideGrp = [i \in DOMAIN settled14.tradeCaptureReportDeclineV2TrdCapAckSideGrp |-> SettleTradeCaptureReportDeclineV2TrdCapAckSideGrp(settled14.tradeCaptureReportDeclineV2TrdCapAckSideGrp[i], settled14.numberOfReturnBitfields, settled14.tradeCaptureReportDeclineV2ReturnBitfield1, settled14.tradeCaptureReportDeclineV2ReturnBitfield2, settled14.tradeCaptureReportDeclineV2ReturnBitfield3, settled14.tradeCaptureReportDeclineV2ReturnBitfield4, settled14.tradeCaptureReportDeclineV2ReturnBitfield6)]]
        settled16 == [settled15 EXCEPT !.execInst = IF settled15.numberOfReturnBitfields >= 1 /\ (settled15.tradeCaptureReportDeclineV2ReturnBitfield1 # << >> /\ (settled15.tradeCaptureReportDeclineV2ReturnBitfield1[1] \div 8) % 2 > 0) THEN (IF settled15.execInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled15.execInst) ELSE << >>]
        settled17 == [settled16 EXCEPT !.symbol = IF settled16.numberOfReturnBitfields >= 2 /\ (settled16.tradeCaptureReportDeclineV2ReturnBitfield2 # << >> /\ settled16.tradeCaptureReportDeclineV2ReturnBitfield2[1] % 2 > 0) THEN (IF settled16.symbol = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled16.symbol) ELSE << >>]
        settled18 == [settled17 EXCEPT !.currency = IF settled17.numberOfReturnBitfields >= 2 /\ (settled17.tradeCaptureReportDeclineV2ReturnBitfield2 # << >> /\ (settled17.tradeCaptureReportDeclineV2ReturnBitfield2[1] \div 4) % 2 > 0) THEN (IF settled17.currency = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled17.currency) ELSE << >>]
        settled19 == [settled18 EXCEPT !.idSource = IF settled18.numberOfReturnBitfields >= 2 /\ (settled18.tradeCaptureReportDeclineV2ReturnBitfield2 # << >> /\ (settled18.tradeCaptureReportDeclineV2ReturnBitfield2[1] \div 8) % 2 > 0) THEN (IF settled18.idSource = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled18.idSource) ELSE << >>]
        settled20 == [settled19 EXCEPT !.securityId = IF settled19.numberOfReturnBitfields >= 2 /\ (settled19.tradeCaptureReportDeclineV2ReturnBitfield2 # << >> /\ (settled19.tradeCaptureReportDeclineV2ReturnBitfield2[1] \div 16) % 2 > 0) THEN (IF settled19.securityId = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled19.securityId) ELSE << >>]
        settled21 == [settled20 EXCEPT !.securityExchange = IF settled20.numberOfReturnBitfields >= 2 /\ (settled20.tradeCaptureReportDeclineV2ReturnBitfield2 # << >> /\ (settled20.tradeCaptureReportDeclineV2ReturnBitfield2[1] \div 32) % 2 > 0) THEN (IF settled20.securityExchange = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled20.securityExchange) ELSE << >>]
        settled22 == [settled21 EXCEPT !.clearingFirm = IF settled21.numberOfReturnBitfields >= 3 /\ (settled21.tradeCaptureReportDeclineV2ReturnBitfield3 # << >> /\ (settled21.tradeCaptureReportDeclineV2ReturnBitfield3[1] \div 2) % 2 > 0) THEN (IF settled21.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled21.clearingFirm) ELSE << >>]
        settled23 == [settled22 EXCEPT !.orderQty = IF settled22.numberOfReturnBitfields >= 3 /\ (settled22.tradeCaptureReportDeclineV2ReturnBitfield3 # << >> /\ (settled22.tradeCaptureReportDeclineV2ReturnBitfield3[1] \div 64) % 2 > 0) THEN (IF settled22.orderQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled22.orderQty) ELSE << >>]
        settled24 == [settled23 EXCEPT !.tradeReportTypeReturn = IF settled23.numberOfReturnBitfields >= 7 /\ (settled23.tradeCaptureReportDeclineV2ReturnBitfield7 # << >> /\ (settled23.tradeCaptureReportDeclineV2ReturnBitfield7[1] \div 2) % 2 > 0) THEN (IF settled23.tradeReportTypeReturn = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled23.tradeReportTypeReturn) ELSE << >>]
        settled25 == [settled24 EXCEPT !.tradePublishIndicator = IF settled24.numberOfReturnBitfields >= 7 /\ (settled24.tradeCaptureReportDeclineV2ReturnBitfield7 # << >> /\ (settled24.tradeCaptureReportDeclineV2ReturnBitfield7[1] \div 4) % 2 > 0) THEN (IF settled24.tradePublishIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled24.tradePublishIndicator) ELSE << >>]
        settled26 == [settled25 EXCEPT !.rptTime = IF settled25.numberOfReturnBitfields >= 7 /\ (settled25.tradeCaptureReportDeclineV2ReturnBitfield7 # << >> /\ (settled25.tradeCaptureReportDeclineV2ReturnBitfield7[1] \div 4) % 2 > 0) THEN (IF settled25.rptTime = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled25.rptTime) ELSE << >>]
        settled27 == [settled26 EXCEPT !.largeSize = IF settled26.numberOfReturnBitfields >= 7 /\ (settled26.tradeCaptureReportDeclineV2ReturnBitfield7 # << >> /\ (settled26.tradeCaptureReportDeclineV2ReturnBitfield7[1] \div 64) % 2 > 0) THEN (IF settled26.largeSize = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled26.largeSize) ELSE << >>]
        settled28 == [settled27 EXCEPT !.lastMkt = IF settled27.numberOfReturnBitfields >= 7 /\ (settled27.tradeCaptureReportDeclineV2ReturnBitfield7 # << >> /\ (settled27.tradeCaptureReportDeclineV2ReturnBitfield7[1] \div 128) % 2 > 0) THEN (IF settled27.lastMkt = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled27.lastMkt) ELSE << >>]
        settled29 == [settled28 EXCEPT !.echoText = IF settled28.numberOfReturnBitfields >= 8 /\ (settled28.tradeCaptureReportDeclineV2ReturnBitfield8 # << >> /\ (settled28.tradeCaptureReportDeclineV2ReturnBitfield8[1] \div 2) % 2 > 0) THEN (IF settled28.echoText = << >> THEN <<[i \in 1 .. 64 |-> 0]>> ELSE settled28.echoText) ELSE << >>]
        settled30 == [settled29 EXCEPT !.liquidityProvision = IF settled29.numberOfReturnBitfields >= 9 /\ (settled29.tradeCaptureReportDeclineV2ReturnBitfield9 # << >> /\ (settled29.tradeCaptureReportDeclineV2ReturnBitfield9[1] \div 16) % 2 > 0) THEN (IF settled29.liquidityProvision = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled29.liquidityProvision) ELSE << >>]
        settled31 == [settled30 EXCEPT !.waiverType = IF settled30.numberOfReturnBitfields >= 10 /\ (settled30.tradeCaptureReportDeclineV2ReturnBitfield10 # << >> /\ (settled30.tradeCaptureReportDeclineV2ReturnBitfield10[1] \div 16) % 2 > 0) THEN (IF settled30.waiverType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled30.waiverType) ELSE << >>]
        settled32 == [settled31 EXCEPT !.priceFormation = IF settled31.numberOfReturnBitfields >= 10 /\ (settled31.tradeCaptureReportDeclineV2ReturnBitfield10 # << >> /\ (settled31.tradeCaptureReportDeclineV2ReturnBitfield10[1] \div 64) % 2 > 0) THEN (IF settled31.priceFormation = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled31.priceFormation) ELSE << >>]
        settled33 == [settled32 EXCEPT !.clientQualifiedRole = IF settled32.numberOfReturnBitfields >= 10 /\ (settled32.tradeCaptureReportDeclineV2ReturnBitfield10 # << >> /\ (settled32.tradeCaptureReportDeclineV2ReturnBitfield10[1] \div 128) % 2 > 0) THEN (IF settled32.clientQualifiedRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled32.clientQualifiedRole) ELSE << >>]
        settled34 == [settled33 EXCEPT !.clientId = IF settled33.numberOfReturnBitfields >= 11 /\ (settled33.tradeCaptureReportDeclineV2ReturnBitfield11 # << >> /\ settled33.tradeCaptureReportDeclineV2ReturnBitfield11[1] % 2 > 0) THEN (IF settled33.clientId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled33.clientId) ELSE << >>]
        settled35 == [settled34 EXCEPT !.investorId = IF settled34.numberOfReturnBitfields >= 11 /\ (settled34.tradeCaptureReportDeclineV2ReturnBitfield11 # << >> /\ (settled34.tradeCaptureReportDeclineV2ReturnBitfield11[1] \div 2) % 2 > 0) THEN (IF settled34.investorId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled34.investorId) ELSE << >>]
        settled36 == [settled35 EXCEPT !.executorId = IF settled35.numberOfReturnBitfields >= 11 /\ (settled35.tradeCaptureReportDeclineV2ReturnBitfield11 # << >> /\ (settled35.tradeCaptureReportDeclineV2ReturnBitfield11[1] \div 4) % 2 > 0) THEN (IF settled35.executorId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled35.executorId) ELSE << >>]
        settled37 == [settled36 EXCEPT !.orderOrigination = IF settled36.numberOfReturnBitfields >= 11 /\ (settled36.tradeCaptureReportDeclineV2ReturnBitfield11 # << >> /\ (settled36.tradeCaptureReportDeclineV2ReturnBitfield11[1] \div 8) % 2 > 0) THEN (IF settled36.orderOrigination = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled36.orderOrigination) ELSE << >>]
        settled38 == [settled37 EXCEPT !.algorithmicIndicator = IF settled37.numberOfReturnBitfields >= 11 /\ (settled37.tradeCaptureReportDeclineV2ReturnBitfield11 # << >> /\ (settled37.tradeCaptureReportDeclineV2ReturnBitfield11[1] \div 16) % 2 > 0) THEN (IF settled37.algorithmicIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled37.algorithmicIndicator) ELSE << >>]
        settled39 == [settled38 EXCEPT !.investorQualifiedRole = IF settled38.numberOfReturnBitfields >= 11 /\ (settled38.tradeCaptureReportDeclineV2ReturnBitfield11 # << >> /\ (settled38.tradeCaptureReportDeclineV2ReturnBitfield11[1] \div 64) % 2 > 0) THEN (IF settled38.investorQualifiedRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled38.investorQualifiedRole) ELSE << >>]
        settled40 == [settled39 EXCEPT !.executorQualifiedRole = IF settled39.numberOfReturnBitfields >= 11 /\ (settled39.tradeCaptureReportDeclineV2ReturnBitfield11 # << >> /\ (settled39.tradeCaptureReportDeclineV2ReturnBitfield11[1] \div 128) % 2 > 0) THEN (IF settled39.executorQualifiedRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled39.executorQualifiedRole) ELSE << >>]
    IN  settled40

ZeroTradeCaptureReportDeclineV2Message ==
    SettleTradeCaptureReportDeclineV2Message([ transactionTime                             |-> [i \in 1 .. 8 |-> 0],
                                               tradeReportId                               |-> [i \in 1 .. 20 |-> 0],
                                               tradeReportRefId                            |-> [i \in 1 .. 20 |-> 0],
                                               tradeId                                     |-> [i \in 1 .. 8 |-> 0],
                                               lastShares                                  |-> [i \in 1 .. 4 |-> 0],
                                               tradeCaptureLastPx                          |-> [i \in 1 .. 8 |-> 0],
                                               contraBroker                                |-> [i \in 1 .. 4 |-> 0],
                                               reason                                      |-> [i \in 1 .. 1 |-> 0],
                                               text                                        |-> [i \in 1 .. 60 |-> 0],
                                               reserved1                                   |-> [i \in 1 .. 1 |-> 0],
                                               numberOfReturnBitfields                     |-> 0,
                                               tradeCaptureReportDeclineV2ReturnBitfield1  |-> << >>,
                                               tradeCaptureReportDeclineV2ReturnBitfield2  |-> << >>,
                                               tradeCaptureReportDeclineV2ReturnBitfield3  |-> << >>,
                                               tradeCaptureReportDeclineV2ReturnBitfield4  |-> << >>,
                                               tradeCaptureReportDeclineV2ReturnBitfield5  |-> << >>,
                                               tradeCaptureReportDeclineV2ReturnBitfield6  |-> << >>,
                                               tradeCaptureReportDeclineV2ReturnBitfield7  |-> << >>,
                                               tradeCaptureReportDeclineV2ReturnBitfield8  |-> << >>,
                                               tradeCaptureReportDeclineV2ReturnBitfield9  |-> << >>,
                                               tradeCaptureReportDeclineV2ReturnBitfield10 |-> << >>,
                                               tradeCaptureReportDeclineV2ReturnBitfield11 |-> << >>,
                                               tradeCaptureReportDeclineV2ReturnBitfield12 |-> << >>,
                                               tradeCaptureReportDeclineV2ReturnBitfield13 |-> << >>,
                                               tradeCaptureReportDeclineV2ReturnBitfield14 |-> << >>,
                                               tradeCaptureReportDeclineV2TrdCapAckSideGrp |-> << >>,
                                               execInst                                    |-> << >>,
                                               symbol                                      |-> << >>,
                                               currency                                    |-> << >>,
                                               idSource                                    |-> << >>,
                                               securityId                                  |-> << >>,
                                               securityExchange                            |-> << >>,
                                               clearingFirm                                |-> << >>,
                                               orderQty                                    |-> << >>,
                                               tradeReportTypeReturn                       |-> << >>,
                                               tradePublishIndicator                       |-> << >>,
                                               rptTime                                     |-> << >>,
                                               largeSize                                   |-> << >>,
                                               lastMkt                                     |-> << >>,
                                               echoText                                    |-> << >>,
                                               liquidityProvision                          |-> << >>,
                                               waiverType                                  |-> << >>,
                                               priceFormation                              |-> << >>,
                                               clientQualifiedRole                         |-> << >>,
                                               clientId                                    |-> << >>,
                                               investorId                                  |-> << >>,
                                               executorId                                  |-> << >>,
                                               orderOrigination                            |-> << >>,
                                               algorithmicIndicator                        |-> << >>,
                                               investorQualifiedRole                       |-> << >>,
                                               executorQualifiedRole                       |-> << >> ])

(* Trade Capture Report Decline V 2 Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCaptureReportDeclineV2Message ==
    { ZeroTradeCaptureReportDeclineV2Message }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.transactionTime = one]) : one \in Sample(8) }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.tradeReportId = one]) : one \in Sample(20) }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.tradeReportRefId = one]) : one \in Sample(20) }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.tradeId = one]) : one \in Sample(8) }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.lastShares = one]) : one \in Sample(4) }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.tradeCaptureLastPx = one]) : one \in Sample(8) }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.contraBroker = one]) : one \in Sample(4) }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.reason = one]) : one \in Sample(1) }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.text = one]) : one \in Sample(60) }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.reserved1 = one]) : one \in Sample(1) }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 1, !.tradeCaptureReportDeclineV2ReturnBitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 2, !.tradeCaptureReportDeclineV2ReturnBitfield2 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 3, !.tradeCaptureReportDeclineV2ReturnBitfield3 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 4, !.tradeCaptureReportDeclineV2ReturnBitfield4 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 5, !.tradeCaptureReportDeclineV2ReturnBitfield5 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 6, !.tradeCaptureReportDeclineV2ReturnBitfield6 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 7, !.tradeCaptureReportDeclineV2ReturnBitfield7 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 8, !.tradeCaptureReportDeclineV2ReturnBitfield8 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 9, !.tradeCaptureReportDeclineV2ReturnBitfield9 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 10, !.tradeCaptureReportDeclineV2ReturnBitfield10 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 11, !.tradeCaptureReportDeclineV2ReturnBitfield11 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 12, !.tradeCaptureReportDeclineV2ReturnBitfield12 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 13, !.tradeCaptureReportDeclineV2ReturnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 14, !.tradeCaptureReportDeclineV2ReturnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.tradeCaptureReportDeclineV2TrdCapAckSideGrp = one]) : one \in SampleLists(OneTradeCaptureReportDeclineV2TrdCapAckSideGrp) }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 1, !.tradeCaptureReportDeclineV2ReturnBitfield1 = <<1>>, !.tradeCaptureReportDeclineV2TrdCapAckSideGrp = one]) : one \in SampleLists(OneTradeCaptureReportDeclineV2TrdCapAckSideGrp) }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 2, !.tradeCaptureReportDeclineV2ReturnBitfield2 = <<64>>, !.tradeCaptureReportDeclineV2TrdCapAckSideGrp = one]) : one \in SampleLists(OneTradeCaptureReportDeclineV2TrdCapAckSideGrp) }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 3, !.tradeCaptureReportDeclineV2ReturnBitfield3 = <<1>>, !.tradeCaptureReportDeclineV2TrdCapAckSideGrp = one]) : one \in SampleLists(OneTradeCaptureReportDeclineV2TrdCapAckSideGrp) }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 4, !.tradeCaptureReportDeclineV2ReturnBitfield4 = <<64>>, !.tradeCaptureReportDeclineV2TrdCapAckSideGrp = one]) : one \in SampleLists(OneTradeCaptureReportDeclineV2TrdCapAckSideGrp) }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 6, !.tradeCaptureReportDeclineV2ReturnBitfield6 = <<128>>, !.tradeCaptureReportDeclineV2TrdCapAckSideGrp = one]) : one \in SampleLists(OneTradeCaptureReportDeclineV2TrdCapAckSideGrp) }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 1, !.tradeCaptureReportDeclineV2ReturnBitfield1 = <<8>>, !.execInst = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 2, !.tradeCaptureReportDeclineV2ReturnBitfield2 = <<1>>, !.symbol = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 2, !.tradeCaptureReportDeclineV2ReturnBitfield2 = <<4>>, !.currency = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 2, !.tradeCaptureReportDeclineV2ReturnBitfield2 = <<8>>, !.idSource = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 2, !.tradeCaptureReportDeclineV2ReturnBitfield2 = <<16>>, !.securityId = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 2, !.tradeCaptureReportDeclineV2ReturnBitfield2 = <<32>>, !.securityExchange = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 3, !.tradeCaptureReportDeclineV2ReturnBitfield3 = <<2>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 3, !.tradeCaptureReportDeclineV2ReturnBitfield3 = <<64>>, !.orderQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 7, !.tradeCaptureReportDeclineV2ReturnBitfield7 = <<2>>, !.tradeReportTypeReturn = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 7, !.tradeCaptureReportDeclineV2ReturnBitfield7 = <<4>>, !.tradePublishIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 7, !.tradeCaptureReportDeclineV2ReturnBitfield7 = <<4>>, !.rptTime = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 7, !.tradeCaptureReportDeclineV2ReturnBitfield7 = <<64>>, !.largeSize = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 7, !.tradeCaptureReportDeclineV2ReturnBitfield7 = <<128>>, !.lastMkt = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 8, !.tradeCaptureReportDeclineV2ReturnBitfield8 = <<2>>, !.echoText = one]) : one \in { <<held>> : held \in Sample(64) } }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 9, !.tradeCaptureReportDeclineV2ReturnBitfield9 = <<16>>, !.liquidityProvision = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 10, !.tradeCaptureReportDeclineV2ReturnBitfield10 = <<16>>, !.waiverType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 10, !.tradeCaptureReportDeclineV2ReturnBitfield10 = <<64>>, !.priceFormation = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 10, !.tradeCaptureReportDeclineV2ReturnBitfield10 = <<128>>, !.clientQualifiedRole = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 11, !.tradeCaptureReportDeclineV2ReturnBitfield11 = <<1>>, !.clientId = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 11, !.tradeCaptureReportDeclineV2ReturnBitfield11 = <<2>>, !.investorId = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 11, !.tradeCaptureReportDeclineV2ReturnBitfield11 = <<4>>, !.executorId = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 11, !.tradeCaptureReportDeclineV2ReturnBitfield11 = <<8>>, !.orderOrigination = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 11, !.tradeCaptureReportDeclineV2ReturnBitfield11 = <<16>>, !.algorithmicIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 11, !.tradeCaptureReportDeclineV2ReturnBitfield11 = <<64>>, !.investorQualifiedRole = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 11, !.tradeCaptureReportDeclineV2ReturnBitfield11 = <<128>>, !.executorQualifiedRole = one]) : one \in { <<held>> : held \in Sample(1) } }

(***************************************************************************)
(* Message, selected by Message Type                                       *)
(***************************************************************************)

LoginRequestV2MessageCode == 55  \* 0x37
LogoutRequestMessageCode == 2  \* 0x02
ClientHeartbeatMessageCode == 3  \* 0x03
LoginResponseV2MessageCode == 36  \* 0x24
LogoutMessageCode == 8  \* 0x08
ServerHeartbeatMessageCode == 9  \* 0x09
ReplayCompleteMessageCode == 19  \* 0x13
NewOrderV2MessageCode == 56  \* 0x38
CancelOrderV2MessageCode == 57  \* 0x39
ModifyOrderV2MessageCode == 58  \* 0x3a
TradeCaptureReportV2MessageCode == 60  \* 0x3c
OrderAcknowledgmentV2MessageCode == 37  \* 0x25
OrderRejectedV2MessageCode == 38  \* 0x26
OrderModifiedV2MessageCode == 39  \* 0x27
OrderRestatedV2MessageCode == 40  \* 0x28
UserModifyRejectedV2MessageCode == 41  \* 0x29
OrderCancelledV2MessageCode == 42  \* 0x2a
CancelRejectedV2MessageCode == 43  \* 0x2b
OrderExecutionV2MessageCode == 44  \* 0x2c
TradeCancelOrCorrectV2MessageCode == 45  \* 0x2d
TradeCaptureReportAcknowledgmentV2MessageCode == 48  \* 0x30
TradeCaptureReportRejectV2MessageCode == 49  \* 0x31
TradeCaptureConfirmV2MessageCode == 50  \* 0x32
TradeCaptureReportDeclineV2MessageCode == 51  \* 0x33

Message ==
    [ tag : {LoginRequestV2MessageCode}, body : LoginRequestV2Message ]
        \cup [ tag : {LogoutRequestMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ClientHeartbeatMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {LoginResponseV2MessageCode}, body : LoginResponseV2Message ]
        \cup [ tag : {LogoutMessageCode}, body : LogoutMessage ]
        \cup [ tag : {ServerHeartbeatMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ReplayCompleteMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {NewOrderV2MessageCode}, body : NewOrderV2Message ]
        \cup [ tag : {CancelOrderV2MessageCode}, body : CancelOrderV2Message ]
        \cup [ tag : {ModifyOrderV2MessageCode}, body : ModifyOrderV2Message ]
        \cup [ tag : {TradeCaptureReportV2MessageCode}, body : TradeCaptureReportV2Message ]
        \cup [ tag : {OrderAcknowledgmentV2MessageCode}, body : OrderAcknowledgmentV2Message ]
        \cup [ tag : {OrderRejectedV2MessageCode}, body : OrderRejectedV2Message ]
        \cup [ tag : {OrderModifiedV2MessageCode}, body : OrderModifiedV2Message ]
        \cup [ tag : {OrderRestatedV2MessageCode}, body : OrderRestatedV2Message ]
        \cup [ tag : {UserModifyRejectedV2MessageCode}, body : UserModifyRejectedV2Message ]
        \cup [ tag : {OrderCancelledV2MessageCode}, body : OrderCancelledV2Message ]
        \cup [ tag : {CancelRejectedV2MessageCode}, body : CancelRejectedV2Message ]
        \cup [ tag : {OrderExecutionV2MessageCode}, body : OrderExecutionV2Message ]
        \cup [ tag : {TradeCancelOrCorrectV2MessageCode}, body : TradeCancelOrCorrectV2Message ]
        \cup [ tag : {TradeCaptureReportAcknowledgmentV2MessageCode}, body : TradeCaptureReportAcknowledgmentV2Message ]
        \cup [ tag : {TradeCaptureReportRejectV2MessageCode}, body : TradeCaptureReportRejectV2Message ]
        \cup [ tag : {TradeCaptureConfirmV2MessageCode}, body : TradeCaptureConfirmV2Message ]
        \cup [ tag : {TradeCaptureReportDeclineV2MessageCode}, body : TradeCaptureReportDeclineV2Message ]

EncodeMessage(message) ==
    CASE message.tag = LoginRequestV2MessageCode -> EncodeLoginRequestV2Message(message.body)
      [] message.tag = LogoutRequestMessageCode -> << >>
      [] message.tag = ClientHeartbeatMessageCode -> << >>
      [] message.tag = LoginResponseV2MessageCode -> EncodeLoginResponseV2Message(message.body)
      [] message.tag = LogoutMessageCode -> EncodeLogoutMessage(message.body)
      [] message.tag = ServerHeartbeatMessageCode -> << >>
      [] message.tag = ReplayCompleteMessageCode -> << >>
      [] message.tag = NewOrderV2MessageCode -> EncodeNewOrderV2Message(message.body)
      [] message.tag = CancelOrderV2MessageCode -> EncodeCancelOrderV2Message(message.body)
      [] message.tag = ModifyOrderV2MessageCode -> EncodeModifyOrderV2Message(message.body)
      [] message.tag = TradeCaptureReportV2MessageCode -> EncodeTradeCaptureReportV2Message(message.body)
      [] message.tag = OrderAcknowledgmentV2MessageCode -> EncodeOrderAcknowledgmentV2Message(message.body)
      [] message.tag = OrderRejectedV2MessageCode -> EncodeOrderRejectedV2Message(message.body)
      [] message.tag = OrderModifiedV2MessageCode -> EncodeOrderModifiedV2Message(message.body)
      [] message.tag = OrderRestatedV2MessageCode -> EncodeOrderRestatedV2Message(message.body)
      [] message.tag = UserModifyRejectedV2MessageCode -> EncodeUserModifyRejectedV2Message(message.body)
      [] message.tag = OrderCancelledV2MessageCode -> EncodeOrderCancelledV2Message(message.body)
      [] message.tag = CancelRejectedV2MessageCode -> EncodeCancelRejectedV2Message(message.body)
      [] message.tag = OrderExecutionV2MessageCode -> EncodeOrderExecutionV2Message(message.body)
      [] message.tag = TradeCancelOrCorrectV2MessageCode -> EncodeTradeCancelOrCorrectV2Message(message.body)
      [] message.tag = TradeCaptureReportAcknowledgmentV2MessageCode -> EncodeTradeCaptureReportAcknowledgmentV2Message(message.body)
      [] message.tag = TradeCaptureReportRejectV2MessageCode -> EncodeTradeCaptureReportRejectV2Message(message.body)
      [] message.tag = TradeCaptureConfirmV2MessageCode -> EncodeTradeCaptureConfirmV2Message(message.body)
      [] message.tag = TradeCaptureReportDeclineV2MessageCode -> EncodeTradeCaptureReportDeclineV2Message(message.body)

DecodeMessage(tag, bytes) ==
    LET read ==
            CASE tag = LoginRequestV2MessageCode -> DecodeLoginRequestV2Message(bytes)
              [] tag = LogoutRequestMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = ClientHeartbeatMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = LoginResponseV2MessageCode -> DecodeLoginResponseV2Message(bytes)
              [] tag = LogoutMessageCode -> DecodeLogoutMessage(bytes)
              [] tag = ServerHeartbeatMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = ReplayCompleteMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = NewOrderV2MessageCode -> DecodeNewOrderV2Message(bytes)
              [] tag = CancelOrderV2MessageCode -> DecodeCancelOrderV2Message(bytes)
              [] tag = ModifyOrderV2MessageCode -> DecodeModifyOrderV2Message(bytes)
              [] tag = TradeCaptureReportV2MessageCode -> DecodeTradeCaptureReportV2Message(bytes)
              [] tag = OrderAcknowledgmentV2MessageCode -> DecodeOrderAcknowledgmentV2Message(bytes)
              [] tag = OrderRejectedV2MessageCode -> DecodeOrderRejectedV2Message(bytes)
              [] tag = OrderModifiedV2MessageCode -> DecodeOrderModifiedV2Message(bytes)
              [] tag = OrderRestatedV2MessageCode -> DecodeOrderRestatedV2Message(bytes)
              [] tag = UserModifyRejectedV2MessageCode -> DecodeUserModifyRejectedV2Message(bytes)
              [] tag = OrderCancelledV2MessageCode -> DecodeOrderCancelledV2Message(bytes)
              [] tag = CancelRejectedV2MessageCode -> DecodeCancelRejectedV2Message(bytes)
              [] tag = OrderExecutionV2MessageCode -> DecodeOrderExecutionV2Message(bytes)
              [] tag = TradeCancelOrCorrectV2MessageCode -> DecodeTradeCancelOrCorrectV2Message(bytes)
              [] tag = TradeCaptureReportAcknowledgmentV2MessageCode -> DecodeTradeCaptureReportAcknowledgmentV2Message(bytes)
              [] tag = TradeCaptureReportRejectV2MessageCode -> DecodeTradeCaptureReportRejectV2Message(bytes)
              [] tag = TradeCaptureConfirmV2MessageCode -> DecodeTradeCaptureConfirmV2Message(bytes)
              [] tag = TradeCaptureReportDeclineV2MessageCode -> DecodeTradeCaptureReportDeclineV2Message(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroMessage == [tag |-> LoginRequestV2MessageCode, body |-> ZeroLoginRequestV2Message]

(* Each Message in turn, at the values the message it names is checked at *)
CheckedMessage ==
    { [tag |-> LoginRequestV2MessageCode, body |-> one] : one \in CheckedLoginRequestV2Message }
        \cup { [tag |-> LogoutRequestMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> ClientHeartbeatMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> LoginResponseV2MessageCode, body |-> one] : one \in CheckedLoginResponseV2Message }
        \cup { [tag |-> LogoutMessageCode, body |-> one] : one \in CheckedLogoutMessage }
        \cup { [tag |-> ServerHeartbeatMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> ReplayCompleteMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> NewOrderV2MessageCode, body |-> one] : one \in CheckedNewOrderV2Message }
        \cup { [tag |-> CancelOrderV2MessageCode, body |-> one] : one \in CheckedCancelOrderV2Message }
        \cup { [tag |-> ModifyOrderV2MessageCode, body |-> one] : one \in CheckedModifyOrderV2Message }
        \cup { [tag |-> TradeCaptureReportV2MessageCode, body |-> one] : one \in CheckedTradeCaptureReportV2Message }
        \cup { [tag |-> OrderAcknowledgmentV2MessageCode, body |-> one] : one \in CheckedOrderAcknowledgmentV2Message }
        \cup { [tag |-> OrderRejectedV2MessageCode, body |-> one] : one \in CheckedOrderRejectedV2Message }
        \cup { [tag |-> OrderModifiedV2MessageCode, body |-> one] : one \in CheckedOrderModifiedV2Message }
        \cup { [tag |-> OrderRestatedV2MessageCode, body |-> one] : one \in CheckedOrderRestatedV2Message }
        \cup { [tag |-> UserModifyRejectedV2MessageCode, body |-> one] : one \in CheckedUserModifyRejectedV2Message }
        \cup { [tag |-> OrderCancelledV2MessageCode, body |-> one] : one \in CheckedOrderCancelledV2Message }
        \cup { [tag |-> CancelRejectedV2MessageCode, body |-> one] : one \in CheckedCancelRejectedV2Message }
        \cup { [tag |-> OrderExecutionV2MessageCode, body |-> one] : one \in CheckedOrderExecutionV2Message }
        \cup { [tag |-> TradeCancelOrCorrectV2MessageCode, body |-> one] : one \in CheckedTradeCancelOrCorrectV2Message }
        \cup { [tag |-> TradeCaptureReportAcknowledgmentV2MessageCode, body |-> one] : one \in CheckedTradeCaptureReportAcknowledgmentV2Message }
        \cup { [tag |-> TradeCaptureReportRejectV2MessageCode, body |-> one] : one \in CheckedTradeCaptureReportRejectV2Message }
        \cup { [tag |-> TradeCaptureConfirmV2MessageCode, body |-> one] : one \in CheckedTradeCaptureConfirmV2Message }
        \cup { [tag |-> TradeCaptureReportDeclineV2MessageCode, body |-> one] : one \in CheckedTradeCaptureReportDeclineV2Message }

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

(* Every Return Bitfields decodes back to what was encoded, and leaves nothing over *)
RoundTripReturnBitfields ==
    \A message \in CheckedReturnBitfields :
        LET read == DecodeReturnBitfields(EncodeReturnBitfields(message))
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

(* Every Login Request V 2 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRequestV2Message ==
    \A message \in CheckedLoginRequestV2Message :
        LET read == DecodeLoginRequestV2Message(EncodeLoginRequestV2Message(message))
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

(* Every Return Bitfields decodes back to what was encoded, and leaves nothing over *)
RoundTripReturnBitfields2 ==
    \A message \in CheckedReturnBitfields2 :
        LET read == DecodeReturnBitfields2(EncodeReturnBitfields2(message))
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

(* Every Login Response V 2 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginResponseV2Message ==
    \A message \in CheckedLoginResponseV2Message :
        LET read == DecodeLoginResponseV2Message(EncodeLoginResponseV2Message(message))
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

(* Every New Order V 2 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderV2Message ==
    \A message \in CheckedNewOrderV2Message :
        LET read == DecodeNewOrderV2Message(EncodeNewOrderV2Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Order V 2 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelOrderV2Message ==
    \A message \in CheckedCancelOrderV2Message :
        LET read == DecodeCancelOrderV2Message(EncodeCancelOrderV2Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Order V 2 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyOrderV2Message ==
    \A message \in CheckedModifyOrderV2Message :
        LET read == DecodeModifyOrderV2Message(EncodeModifyOrderV2Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trd Cap Rpt Side Grp decodes back to what was encoded, and leaves nothing over *)
RoundTripTrdCapRptSideGrp ==
    \A checked \in CheckedTrdCapRptSideGrp :
        LET read == DecodeTrdCapRptSideGrp(EncodeTrdCapRptSideGrp(checked.message), checked.given[1], checked.given[2])
        IN  /\ read.ok
            /\ read.value = checked.message
            /\ read.rest = << >>

(* Every Trade Capture Report V 2 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCaptureReportV2Message ==
    \A message \in CheckedTradeCaptureReportV2Message :
        LET read == DecodeTradeCaptureReportV2Message(EncodeTradeCaptureReportV2Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Acknowledgment V 2 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderAcknowledgmentV2Message ==
    \A message \in CheckedOrderAcknowledgmentV2Message :
        LET read == DecodeOrderAcknowledgmentV2Message(EncodeOrderAcknowledgmentV2Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Rejected V 2 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderRejectedV2Message ==
    \A message \in CheckedOrderRejectedV2Message :
        LET read == DecodeOrderRejectedV2Message(EncodeOrderRejectedV2Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Modified V 2 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderModifiedV2Message ==
    \A message \in CheckedOrderModifiedV2Message :
        LET read == DecodeOrderModifiedV2Message(EncodeOrderModifiedV2Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Restated V 2 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderRestatedV2Message ==
    \A message \in CheckedOrderRestatedV2Message :
        LET read == DecodeOrderRestatedV2Message(EncodeOrderRestatedV2Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every User Modify Rejected V 2 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUserModifyRejectedV2Message ==
    \A message \in CheckedUserModifyRejectedV2Message :
        LET read == DecodeUserModifyRejectedV2Message(EncodeUserModifyRejectedV2Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancelled V 2 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelledV2Message ==
    \A message \in CheckedOrderCancelledV2Message :
        LET read == DecodeOrderCancelledV2Message(EncodeOrderCancelledV2Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Rejected V 2 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelRejectedV2Message ==
    \A message \in CheckedCancelRejectedV2Message :
        LET read == DecodeCancelRejectedV2Message(EncodeCancelRejectedV2Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Execution V 2 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutionV2Message ==
    \A message \in CheckedOrderExecutionV2Message :
        LET read == DecodeOrderExecutionV2Message(EncodeOrderExecutionV2Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Cancel Or Correct V 2 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCancelOrCorrectV2Message ==
    \A message \in CheckedTradeCancelOrCorrectV2Message :
        LET read == DecodeTradeCancelOrCorrectV2Message(EncodeTradeCancelOrCorrectV2Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trd Cap Ack Side Grp decodes back to what was encoded, and leaves nothing over *)
RoundTripTrdCapAckSideGrp ==
    \A checked \in CheckedTrdCapAckSideGrp :
        LET read == DecodeTrdCapAckSideGrp(EncodeTrdCapAckSideGrp(checked.message), checked.given[1], checked.given[2], checked.given[3], checked.given[4], checked.given[5], checked.given[6])
        IN  /\ read.ok
            /\ read.value = checked.message
            /\ read.rest = << >>

(* Every Trade Capture Report Acknowledgment V 2 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCaptureReportAcknowledgmentV2Message ==
    \A message \in CheckedTradeCaptureReportAcknowledgmentV2Message :
        LET read == DecodeTradeCaptureReportAcknowledgmentV2Message(EncodeTradeCaptureReportAcknowledgmentV2Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Capture Report Reject V 2 Trd Cap Ack Side Grp decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCaptureReportRejectV2TrdCapAckSideGrp ==
    \A checked \in CheckedTradeCaptureReportRejectV2TrdCapAckSideGrp :
        LET read == DecodeTradeCaptureReportRejectV2TrdCapAckSideGrp(EncodeTradeCaptureReportRejectV2TrdCapAckSideGrp(checked.message), checked.given[1], checked.given[2], checked.given[3], checked.given[4], checked.given[5], checked.given[6])
        IN  /\ read.ok
            /\ read.value = checked.message
            /\ read.rest = << >>

(* Every Trade Capture Report Reject V 2 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCaptureReportRejectV2Message ==
    \A message \in CheckedTradeCaptureReportRejectV2Message :
        LET read == DecodeTradeCaptureReportRejectV2Message(EncodeTradeCaptureReportRejectV2Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Capture Confirm V 2 Trd Cap Ack Side Grp decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCaptureConfirmV2TrdCapAckSideGrp ==
    \A checked \in CheckedTradeCaptureConfirmV2TrdCapAckSideGrp :
        LET read == DecodeTradeCaptureConfirmV2TrdCapAckSideGrp(EncodeTradeCaptureConfirmV2TrdCapAckSideGrp(checked.message), checked.given[1], checked.given[2], checked.given[3], checked.given[4], checked.given[5], checked.given[6], checked.given[7])
        IN  /\ read.ok
            /\ read.value = checked.message
            /\ read.rest = << >>

(* Every Trade Capture Confirm V 2 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCaptureConfirmV2Message ==
    \A message \in CheckedTradeCaptureConfirmV2Message :
        LET read == DecodeTradeCaptureConfirmV2Message(EncodeTradeCaptureConfirmV2Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Capture Report Decline V 2 Trd Cap Ack Side Grp decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCaptureReportDeclineV2TrdCapAckSideGrp ==
    \A checked \in CheckedTradeCaptureReportDeclineV2TrdCapAckSideGrp :
        LET read == DecodeTradeCaptureReportDeclineV2TrdCapAckSideGrp(EncodeTradeCaptureReportDeclineV2TrdCapAckSideGrp(checked.message), checked.given[1], checked.given[2], checked.given[3], checked.given[4], checked.given[5], checked.given[6])
        IN  /\ read.ok
            /\ read.value = checked.message
            /\ read.rest = << >>

(* Every Trade Capture Report Decline V 2 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCaptureReportDeclineV2Message ==
    \A message \in CheckedTradeCaptureReportDeclineV2Message :
        LET read == DecodeTradeCaptureReportDeclineV2Message(EncodeTradeCaptureReportDeclineV2Message(message))
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
