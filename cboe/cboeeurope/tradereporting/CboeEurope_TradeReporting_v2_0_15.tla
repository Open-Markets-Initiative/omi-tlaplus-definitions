----------------- MODULE CboeEurope_TradeReporting_v2_0_15 -----------------
(***************************************************************************)
(* Chicago Board Options Exchange  v2.0.15                                 *)
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
(* Note: Trade Capture Report V 2 Message fills what is left of the frame  *)
(* Message Length states, which is what it is read from.                   *)
(*                                                                         *)
(* Note: Quote V 2 Message fills what is left of the frame Message Length  *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Quote Cancel V 2 Message fills what is left of the frame Message  *)
(* Length states, which is what it is read from.                           *)
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
(*                                                                         *)
(* Note: Quote Status V 2 Message fills what is left of the frame Message  *)
(* Length states, which is what it is read from.                           *)
(*                                                                         *)
(* Note: Quote Reject V 2 Message fills what is left of the frame Message  *)
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
      lastPx                                : Sample(8),
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
      grossTradeAmt                         : { << >> } \cup { <<held>> : held \in Sample(8) },
      orderCategory                         : { << >> } \cup { <<held>> : held \in Sample(1) },
      priceFormation                        : { << >> } \cup { <<held>> : held \in Sample(1) },
      algorithmicIndicator                  : { << >> } \cup { <<held>> : held \in Sample(1) },
      waiverType                            : { << >> } \cup { <<held>> : held \in Sample(1) },
      deferralReason                        : { << >> } \cup { <<held>> : held \in Sample(1) } ]

EncodeTradeCaptureReportV2Message(message) ==
    message.tradeReportId
        \o message.lastShares
        \o message.lastPx
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
        \o (IF message.grossTradeAmt = << >> THEN << >> ELSE message.grossTradeAmt[1])
        \o (IF message.orderCategory = << >> THEN << >> ELSE message.orderCategory[1])
        \o (IF message.priceFormation = << >> THEN << >> ELSE message.priceFormation[1])
        \o (IF message.algorithmicIndicator = << >> THEN << >> ELSE message.algorithmicIndicator[1])
        \o (IF message.waiverType = << >> THEN << >> ELSE message.waiverType[1])
        \o (IF message.deferralReason = << >> THEN << >> ELSE message.deferralReason[1])

DecodeTradeCaptureReportV2Message(bytes) ==
    LET tradeReportId == ReadBytes(bytes, 20) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET lastShares == ReadBytes(tradeReportId.rest, 4) IN IF ~lastShares.ok THEN Fail ELSE
    LET lastPx == ReadBytes(lastShares.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET numberOfTradeCaptureReportV2Bitfields == ReadUIntBE(lastPx.rest, 1) IN IF ~numberOfTradeCaptureReportV2Bitfields.ok THEN Fail ELSE
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
    LET transactionCategory == ReadWhen(numberOfTradeCaptureReportV2Bitfields.value >= 2 /\ (tradeCaptureReportV2Bitfield2.value # << >> /\ (tradeCaptureReportV2Bitfield2.value[1] \div 4) % 2 > 0), ReadBytes(securityExchange.rest, 1), securityExchange.rest) IN IF ~transactionCategory.ok THEN Fail ELSE
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
    LET grossTradeAmt == ReadWhen(numberOfTradeCaptureReportV2Bitfields.value >= 4 /\ (tradeCaptureReportV2Bitfield4.value # << >> /\ (tradeCaptureReportV2Bitfield4.value[1] \div 16) % 2 > 0), ReadBytes(executionMethod.rest, 8), executionMethod.rest) IN IF ~grossTradeAmt.ok THEN Fail ELSE
    LET orderCategory == ReadWhen(numberOfTradeCaptureReportV2Bitfields.value >= 4 /\ (tradeCaptureReportV2Bitfield4.value # << >> /\ (tradeCaptureReportV2Bitfield4.value[1] \div 64) % 2 > 0), ReadBytes(grossTradeAmt.rest, 1), grossTradeAmt.rest) IN IF ~orderCategory.ok THEN Fail ELSE
    LET priceFormation == ReadWhen(numberOfTradeCaptureReportV2Bitfields.value >= 5 /\ (tradeCaptureReportV2Bitfield5.value # << >> /\ (tradeCaptureReportV2Bitfield5.value[1] \div 2) % 2 > 0), ReadBytes(orderCategory.rest, 1), orderCategory.rest) IN IF ~priceFormation.ok THEN Fail ELSE
    LET algorithmicIndicator == ReadWhen(numberOfTradeCaptureReportV2Bitfields.value >= 5 /\ (tradeCaptureReportV2Bitfield5.value # << >> /\ (tradeCaptureReportV2Bitfield5.value[1] \div 4) % 2 > 0), ReadBytes(priceFormation.rest, 1), priceFormation.rest) IN IF ~algorithmicIndicator.ok THEN Fail ELSE
    LET waiverType == ReadWhen(numberOfTradeCaptureReportV2Bitfields.value >= 5 /\ (tradeCaptureReportV2Bitfield5.value # << >> /\ (tradeCaptureReportV2Bitfield5.value[1] \div 8) % 2 > 0), ReadBytes(algorithmicIndicator.rest, 1), algorithmicIndicator.rest) IN IF ~waiverType.ok THEN Fail ELSE
    LET deferralReason == ReadWhen(numberOfTradeCaptureReportV2Bitfields.value >= 5 /\ (tradeCaptureReportV2Bitfield5.value # << >> /\ (tradeCaptureReportV2Bitfield5.value[1] \div 16) % 2 > 0), ReadBytes(waiverType.rest, 1), waiverType.rest) IN IF ~deferralReason.ok THEN Fail ELSE
    Ok([ tradeReportId                         |-> tradeReportId.value,
         lastShares                            |-> lastShares.value,
         lastPx                                |-> lastPx.value,
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
         grossTradeAmt                         |-> grossTradeAmt.value,
         orderCategory                         |-> orderCategory.value,
         priceFormation                        |-> priceFormation.value,
         algorithmicIndicator                  |-> algorithmicIndicator.value,
         waiverType                            |-> waiverType.value,
         deferralReason                        |-> deferralReason.value ], deferralReason.rest)

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
        settled12 == [settled11 EXCEPT !.transactionCategory = IF settled11.numberOfTradeCaptureReportV2Bitfields >= 2 /\ (settled11.tradeCaptureReportV2Bitfield2 # << >> /\ (settled11.tradeCaptureReportV2Bitfield2[1] \div 4) % 2 > 0) THEN (IF settled11.transactionCategory = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.transactionCategory) ELSE << >>]
        settled13 == [settled12 EXCEPT !.tradeTime = IF settled12.numberOfTradeCaptureReportV2Bitfields >= 2 /\ (settled12.tradeCaptureReportV2Bitfield2 # << >> /\ (settled12.tradeCaptureReportV2Bitfield2[1] \div 8) % 2 > 0) THEN (IF settled12.tradeTime = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled12.tradeTime) ELSE << >>]
        settled14 == [settled13 EXCEPT !.tradeReportTransType = IF settled13.numberOfTradeCaptureReportV2Bitfields >= 2 /\ (settled13.tradeCaptureReportV2Bitfield2 # << >> /\ (settled13.tradeCaptureReportV2Bitfield2[1] \div 32) % 2 > 0) THEN (IF settled13.tradeReportTransType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.tradeReportTransType) ELSE << >>]
        settled15 == [settled14 EXCEPT !.tradeId = IF settled14.numberOfTradeCaptureReportV2Bitfields >= 2 /\ (settled14.tradeCaptureReportV2Bitfield2 # << >> /\ (settled14.tradeCaptureReportV2Bitfield2[1] \div 64) % 2 > 0) THEN (IF settled14.tradeId = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled14.tradeId) ELSE << >>]
        settled16 == [settled15 EXCEPT !.venueType = IF settled15.numberOfTradeCaptureReportV2Bitfields >= 2 /\ (settled15.tradeCaptureReportV2Bitfield2 # << >> /\ (settled15.tradeCaptureReportV2Bitfield2[1] \div 128) % 2 > 0) THEN (IF settled15.venueType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled15.venueType) ELSE << >>]
        settled17 == [settled16 EXCEPT !.tradingSessionSubId = IF settled16.numberOfTradeCaptureReportV2Bitfields >= 3 /\ (settled16.tradeCaptureReportV2Bitfield3 # << >> /\ settled16.tradeCaptureReportV2Bitfield3[1] % 2 > 0) THEN (IF settled16.tradingSessionSubId = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled16.tradingSessionSubId) ELSE << >>]
        settled18 == [settled17 EXCEPT !.matchType = IF settled17.numberOfTradeCaptureReportV2Bitfields >= 3 /\ (settled17.tradeCaptureReportV2Bitfield3 # << >> /\ (settled17.tradeCaptureReportV2Bitfield3[1] \div 2) % 2 > 0) THEN (IF settled17.matchType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.matchType) ELSE << >>]
        settled19 == [settled18 EXCEPT !.trdSubType = IF settled18.numberOfTradeCaptureReportV2Bitfields >= 3 /\ (settled18.tradeCaptureReportV2Bitfield3 # << >> /\ (settled18.tradeCaptureReportV2Bitfield3[1] \div 4) % 2 > 0) THEN (IF settled18.trdSubType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled18.trdSubType) ELSE << >>]
        settled20 == [settled19 EXCEPT !.secondaryTrdType = IF settled19.numberOfTradeCaptureReportV2Bitfields >= 3 /\ (settled19.tradeCaptureReportV2Bitfield3 # << >> /\ (settled19.tradeCaptureReportV2Bitfield3[1] \div 8) % 2 > 0) THEN (IF settled19.secondaryTrdType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled19.secondaryTrdType) ELSE << >>]
        settled21 == [settled20 EXCEPT !.tradePriceCondition = IF settled20.numberOfTradeCaptureReportV2Bitfields >= 3 /\ (settled20.tradeCaptureReportV2Bitfield3 # << >> /\ (settled20.tradeCaptureReportV2Bitfield3[1] \div 16) % 2 > 0) THEN (IF settled20.tradePriceCondition = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled20.tradePriceCondition) ELSE << >>]
        settled22 == [settled21 EXCEPT !.tradePublishIndicator = IF settled21.numberOfTradeCaptureReportV2Bitfields >= 3 /\ (settled21.tradeCaptureReportV2Bitfield3 # << >> /\ (settled21.tradeCaptureReportV2Bitfield3[1] \div 32) % 2 > 0) THEN (IF settled21.tradePublishIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled21.tradePublishIndicator) ELSE << >>]
        settled23 == [settled22 EXCEPT !.largeSize = IF settled22.numberOfTradeCaptureReportV2Bitfields >= 3 /\ (settled22.tradeCaptureReportV2Bitfield3 # << >> /\ (settled22.tradeCaptureReportV2Bitfield3[1] \div 64) % 2 > 0) THEN (IF settled22.largeSize = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled22.largeSize) ELSE << >>]
        settled24 == [settled23 EXCEPT !.executionMethod = IF settled23.numberOfTradeCaptureReportV2Bitfields >= 3 /\ (settled23.tradeCaptureReportV2Bitfield3 # << >> /\ (settled23.tradeCaptureReportV2Bitfield3[1] \div 128) % 2 > 0) THEN (IF settled23.executionMethod = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled23.executionMethod) ELSE << >>]
        settled25 == [settled24 EXCEPT !.grossTradeAmt = IF settled24.numberOfTradeCaptureReportV2Bitfields >= 4 /\ (settled24.tradeCaptureReportV2Bitfield4 # << >> /\ (settled24.tradeCaptureReportV2Bitfield4[1] \div 16) % 2 > 0) THEN (IF settled24.grossTradeAmt = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled24.grossTradeAmt) ELSE << >>]
        settled26 == [settled25 EXCEPT !.orderCategory = IF settled25.numberOfTradeCaptureReportV2Bitfields >= 4 /\ (settled25.tradeCaptureReportV2Bitfield4 # << >> /\ (settled25.tradeCaptureReportV2Bitfield4[1] \div 64) % 2 > 0) THEN (IF settled25.orderCategory = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled25.orderCategory) ELSE << >>]
        settled27 == [settled26 EXCEPT !.priceFormation = IF settled26.numberOfTradeCaptureReportV2Bitfields >= 5 /\ (settled26.tradeCaptureReportV2Bitfield5 # << >> /\ (settled26.tradeCaptureReportV2Bitfield5[1] \div 2) % 2 > 0) THEN (IF settled26.priceFormation = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled26.priceFormation) ELSE << >>]
        settled28 == [settled27 EXCEPT !.algorithmicIndicator = IF settled27.numberOfTradeCaptureReportV2Bitfields >= 5 /\ (settled27.tradeCaptureReportV2Bitfield5 # << >> /\ (settled27.tradeCaptureReportV2Bitfield5[1] \div 4) % 2 > 0) THEN (IF settled27.algorithmicIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled27.algorithmicIndicator) ELSE << >>]
        settled29 == [settled28 EXCEPT !.waiverType = IF settled28.numberOfTradeCaptureReportV2Bitfields >= 5 /\ (settled28.tradeCaptureReportV2Bitfield5 # << >> /\ (settled28.tradeCaptureReportV2Bitfield5[1] \div 8) % 2 > 0) THEN (IF settled28.waiverType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled28.waiverType) ELSE << >>]
        settled30 == [settled29 EXCEPT !.deferralReason = IF settled29.numberOfTradeCaptureReportV2Bitfields >= 5 /\ (settled29.tradeCaptureReportV2Bitfield5 # << >> /\ (settled29.tradeCaptureReportV2Bitfield5[1] \div 16) % 2 > 0) THEN (IF settled29.deferralReason = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled29.deferralReason) ELSE << >>]
    IN  settled30

ZeroTradeCaptureReportV2Message ==
    SettleTradeCaptureReportV2Message([ tradeReportId                         |-> [i \in 1 .. 20 |-> 0],
                                        lastShares                            |-> [i \in 1 .. 4 |-> 0],
                                        lastPx                                |-> [i \in 1 .. 8 |-> 0],
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
                                        grossTradeAmt                         |-> << >>,
                                        orderCategory                         |-> << >>,
                                        priceFormation                        |-> << >>,
                                        algorithmicIndicator                  |-> << >>,
                                        waiverType                            |-> << >>,
                                        deferralReason                        |-> << >> ])

(* Trade Capture Report V 2 Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCaptureReportV2Message ==
    { ZeroTradeCaptureReportV2Message }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.tradeReportId = one]) : one \in Sample(20) }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.lastShares = one]) : one \in Sample(4) }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.lastPx = one]) : one \in Sample(8) }
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
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.numberOfTradeCaptureReportV2Bitfields = 4, !.tradeCaptureReportV2Bitfield4 = <<16>>, !.grossTradeAmt = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.numberOfTradeCaptureReportV2Bitfields = 4, !.tradeCaptureReportV2Bitfield4 = <<64>>, !.orderCategory = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.numberOfTradeCaptureReportV2Bitfields = 5, !.tradeCaptureReportV2Bitfield5 = <<2>>, !.priceFormation = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.numberOfTradeCaptureReportV2Bitfields = 5, !.tradeCaptureReportV2Bitfield5 = <<4>>, !.algorithmicIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.numberOfTradeCaptureReportV2Bitfields = 5, !.tradeCaptureReportV2Bitfield5 = <<8>>, !.waiverType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportV2Message([ZeroTradeCaptureReportV2Message EXCEPT !.numberOfTradeCaptureReportV2Bitfields = 5, !.tradeCaptureReportV2Bitfield5 = <<16>>, !.deferralReason = one]) : one \in { <<held>> : held \in Sample(1) } }

(***************************************************************************)
(* Quote V 2 Message                                                       *)
(***************************************************************************)

QuoteV2Message ==
    [ quoteId                  : Sample(20),
      numberOfQuoteV2Bitfields : 0 .. 255,
      quoteV2Bitfield1         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      symbol                   : { << >> } \cup { <<held>> : held \in Sample(8) },
      currency                 : { << >> } \cup { <<held>> : held \in Sample(3) },
      idSource                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      securityId               : { << >> } \cup { <<held>> : held \in Sample(16) },
      securityExchange         : { << >> } \cup { <<held>> : held \in Sample(4) },
      bidPx                    : { << >> } \cup { <<held>> : held \in Sample(8) },
      bidSize                  : { << >> } \cup { <<held>> : held \in Sample(4) },
      offerPx                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      offerSize                : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingFirm             : { << >> } \cup { <<held>> : held \in Sample(4) } ]

EncodeQuoteV2Message(message) ==
    message.quoteId
        \o EncodeUIntBE(message.numberOfQuoteV2Bitfields, 1)
        \o (IF message.quoteV2Bitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.quoteV2Bitfield1[1], 1))
        \o (IF message.symbol = << >> THEN << >> ELSE message.symbol[1])
        \o (IF message.currency = << >> THEN << >> ELSE message.currency[1])
        \o (IF message.idSource = << >> THEN << >> ELSE message.idSource[1])
        \o (IF message.securityId = << >> THEN << >> ELSE message.securityId[1])
        \o (IF message.securityExchange = << >> THEN << >> ELSE message.securityExchange[1])
        \o (IF message.bidPx = << >> THEN << >> ELSE message.bidPx[1])
        \o (IF message.bidSize = << >> THEN << >> ELSE message.bidSize[1])
        \o (IF message.offerPx = << >> THEN << >> ELSE message.offerPx[1])
        \o (IF message.offerSize = << >> THEN << >> ELSE message.offerSize[1])
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])

DecodeQuoteV2Message(bytes) ==
    LET quoteId == ReadBytes(bytes, 20) IN IF ~quoteId.ok THEN Fail ELSE
    LET numberOfQuoteV2Bitfields == ReadUIntBE(quoteId.rest, 1) IN IF ~numberOfQuoteV2Bitfields.ok THEN Fail ELSE
    LET quoteV2Bitfield1 == ReadWhen(numberOfQuoteV2Bitfields.value >= 1, ReadUIntLE(numberOfQuoteV2Bitfields.rest, 1), numberOfQuoteV2Bitfields.rest) IN IF ~quoteV2Bitfield1.ok THEN Fail ELSE
    LET symbol == ReadWhen(numberOfQuoteV2Bitfields.value >= 1 /\ (quoteV2Bitfield1.value # << >> /\ quoteV2Bitfield1.value[1] % 2 > 0), ReadBytes(quoteV2Bitfield1.rest, 8), quoteV2Bitfield1.rest) IN IF ~symbol.ok THEN Fail ELSE
    LET currency == ReadWhen(numberOfQuoteV2Bitfields.value >= 1 /\ (quoteV2Bitfield1.value # << >> /\ (quoteV2Bitfield1.value[1] \div 2) % 2 > 0), ReadBytes(symbol.rest, 3), symbol.rest) IN IF ~currency.ok THEN Fail ELSE
    LET idSource == ReadWhen(numberOfQuoteV2Bitfields.value >= 1 /\ (quoteV2Bitfield1.value # << >> /\ (quoteV2Bitfield1.value[1] \div 4) % 2 > 0), ReadBytes(currency.rest, 1), currency.rest) IN IF ~idSource.ok THEN Fail ELSE
    LET securityId == ReadWhen(numberOfQuoteV2Bitfields.value >= 1 /\ (quoteV2Bitfield1.value # << >> /\ (quoteV2Bitfield1.value[1] \div 8) % 2 > 0), ReadBytes(idSource.rest, 16), idSource.rest) IN IF ~securityId.ok THEN Fail ELSE
    LET securityExchange == ReadWhen(numberOfQuoteV2Bitfields.value >= 1 /\ (quoteV2Bitfield1.value # << >> /\ (quoteV2Bitfield1.value[1] \div 16) % 2 > 0), ReadBytes(securityId.rest, 4), securityId.rest) IN IF ~securityExchange.ok THEN Fail ELSE
    LET bidPx == ReadWhen(numberOfQuoteV2Bitfields.value >= 1 /\ (quoteV2Bitfield1.value # << >> /\ (quoteV2Bitfield1.value[1] \div 32) % 2 > 0), ReadBytes(securityExchange.rest, 8), securityExchange.rest) IN IF ~bidPx.ok THEN Fail ELSE
    LET bidSize == ReadWhen(numberOfQuoteV2Bitfields.value >= 1 /\ (quoteV2Bitfield1.value # << >> /\ (quoteV2Bitfield1.value[1] \div 32) % 2 > 0), ReadBytes(bidPx.rest, 4), bidPx.rest) IN IF ~bidSize.ok THEN Fail ELSE
    LET offerPx == ReadWhen(numberOfQuoteV2Bitfields.value >= 1 /\ (quoteV2Bitfield1.value # << >> /\ (quoteV2Bitfield1.value[1] \div 64) % 2 > 0), ReadBytes(bidSize.rest, 8), bidSize.rest) IN IF ~offerPx.ok THEN Fail ELSE
    LET offerSize == ReadWhen(numberOfQuoteV2Bitfields.value >= 1 /\ (quoteV2Bitfield1.value # << >> /\ (quoteV2Bitfield1.value[1] \div 64) % 2 > 0), ReadBytes(offerPx.rest, 4), offerPx.rest) IN IF ~offerSize.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfQuoteV2Bitfields.value >= 1 /\ (quoteV2Bitfield1.value # << >> /\ (quoteV2Bitfield1.value[1] \div 128) % 2 > 0), ReadBytes(offerSize.rest, 4), offerSize.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    Ok([ quoteId                  |-> quoteId.value,
         numberOfQuoteV2Bitfields |-> numberOfQuoteV2Bitfields.value,
         quoteV2Bitfield1         |-> quoteV2Bitfield1.value,
         symbol                   |-> symbol.value,
         currency                 |-> currency.value,
         idSource                 |-> idSource.value,
         securityId               |-> securityId.value,
         securityExchange         |-> securityExchange.value,
         bidPx                    |-> bidPx.value,
         bidSize                  |-> bidSize.value,
         offerPx                  |-> offerPx.value,
         offerSize                |-> offerSize.value,
         clearingFirm             |-> clearingFirm.value ], clearingFirm.rest)

(* Quote V 2 Message with each field marked present by fields before it there exactly where they say *)
SettleQuoteV2Message(message) ==
    LET settled1 == [message EXCEPT !.quoteV2Bitfield1 = IF message.numberOfQuoteV2Bitfields >= 1 THEN (IF message.quoteV2Bitfield1 = << >> THEN <<0>> ELSE message.quoteV2Bitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.symbol = IF settled1.numberOfQuoteV2Bitfields >= 1 /\ (settled1.quoteV2Bitfield1 # << >> /\ settled1.quoteV2Bitfield1[1] % 2 > 0) THEN (IF settled1.symbol = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled1.symbol) ELSE << >>]
        settled3 == [settled2 EXCEPT !.currency = IF settled2.numberOfQuoteV2Bitfields >= 1 /\ (settled2.quoteV2Bitfield1 # << >> /\ (settled2.quoteV2Bitfield1[1] \div 2) % 2 > 0) THEN (IF settled2.currency = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled2.currency) ELSE << >>]
        settled4 == [settled3 EXCEPT !.idSource = IF settled3.numberOfQuoteV2Bitfields >= 1 /\ (settled3.quoteV2Bitfield1 # << >> /\ (settled3.quoteV2Bitfield1[1] \div 4) % 2 > 0) THEN (IF settled3.idSource = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled3.idSource) ELSE << >>]
        settled5 == [settled4 EXCEPT !.securityId = IF settled4.numberOfQuoteV2Bitfields >= 1 /\ (settled4.quoteV2Bitfield1 # << >> /\ (settled4.quoteV2Bitfield1[1] \div 8) % 2 > 0) THEN (IF settled4.securityId = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled4.securityId) ELSE << >>]
        settled6 == [settled5 EXCEPT !.securityExchange = IF settled5.numberOfQuoteV2Bitfields >= 1 /\ (settled5.quoteV2Bitfield1 # << >> /\ (settled5.quoteV2Bitfield1[1] \div 16) % 2 > 0) THEN (IF settled5.securityExchange = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled5.securityExchange) ELSE << >>]
        settled7 == [settled6 EXCEPT !.bidPx = IF settled6.numberOfQuoteV2Bitfields >= 1 /\ (settled6.quoteV2Bitfield1 # << >> /\ (settled6.quoteV2Bitfield1[1] \div 32) % 2 > 0) THEN (IF settled6.bidPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled6.bidPx) ELSE << >>]
        settled8 == [settled7 EXCEPT !.bidSize = IF settled7.numberOfQuoteV2Bitfields >= 1 /\ (settled7.quoteV2Bitfield1 # << >> /\ (settled7.quoteV2Bitfield1[1] \div 32) % 2 > 0) THEN (IF settled7.bidSize = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled7.bidSize) ELSE << >>]
        settled9 == [settled8 EXCEPT !.offerPx = IF settled8.numberOfQuoteV2Bitfields >= 1 /\ (settled8.quoteV2Bitfield1 # << >> /\ (settled8.quoteV2Bitfield1[1] \div 64) % 2 > 0) THEN (IF settled8.offerPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled8.offerPx) ELSE << >>]
        settled10 == [settled9 EXCEPT !.offerSize = IF settled9.numberOfQuoteV2Bitfields >= 1 /\ (settled9.quoteV2Bitfield1 # << >> /\ (settled9.quoteV2Bitfield1[1] \div 64) % 2 > 0) THEN (IF settled9.offerSize = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled9.offerSize) ELSE << >>]
        settled11 == [settled10 EXCEPT !.clearingFirm = IF settled10.numberOfQuoteV2Bitfields >= 1 /\ (settled10.quoteV2Bitfield1 # << >> /\ (settled10.quoteV2Bitfield1[1] \div 128) % 2 > 0) THEN (IF settled10.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled10.clearingFirm) ELSE << >>]
    IN  settled11

ZeroQuoteV2Message ==
    SettleQuoteV2Message([ quoteId                  |-> [i \in 1 .. 20 |-> 0],
                           numberOfQuoteV2Bitfields |-> 0,
                           quoteV2Bitfield1         |-> << >>,
                           symbol                   |-> << >>,
                           currency                 |-> << >>,
                           idSource                 |-> << >>,
                           securityId               |-> << >>,
                           securityExchange         |-> << >>,
                           bidPx                    |-> << >>,
                           bidSize                  |-> << >>,
                           offerPx                  |-> << >>,
                           offerSize                |-> << >>,
                           clearingFirm             |-> << >> ])

(* Quote V 2 Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteV2Message ==
    { ZeroQuoteV2Message }
        \cup { SettleQuoteV2Message([ZeroQuoteV2Message EXCEPT !.quoteId = one]) : one \in Sample(20) }
        \cup { SettleQuoteV2Message([ZeroQuoteV2Message EXCEPT !.numberOfQuoteV2Bitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleQuoteV2Message([ZeroQuoteV2Message EXCEPT !.numberOfQuoteV2Bitfields = 1, !.quoteV2Bitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleQuoteV2Message([ZeroQuoteV2Message EXCEPT !.numberOfQuoteV2Bitfields = 1, !.quoteV2Bitfield1 = <<1>>, !.symbol = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleQuoteV2Message([ZeroQuoteV2Message EXCEPT !.numberOfQuoteV2Bitfields = 1, !.quoteV2Bitfield1 = <<2>>, !.currency = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleQuoteV2Message([ZeroQuoteV2Message EXCEPT !.numberOfQuoteV2Bitfields = 1, !.quoteV2Bitfield1 = <<4>>, !.idSource = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleQuoteV2Message([ZeroQuoteV2Message EXCEPT !.numberOfQuoteV2Bitfields = 1, !.quoteV2Bitfield1 = <<8>>, !.securityId = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleQuoteV2Message([ZeroQuoteV2Message EXCEPT !.numberOfQuoteV2Bitfields = 1, !.quoteV2Bitfield1 = <<16>>, !.securityExchange = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleQuoteV2Message([ZeroQuoteV2Message EXCEPT !.numberOfQuoteV2Bitfields = 1, !.quoteV2Bitfield1 = <<32>>, !.bidPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleQuoteV2Message([ZeroQuoteV2Message EXCEPT !.numberOfQuoteV2Bitfields = 1, !.quoteV2Bitfield1 = <<32>>, !.bidSize = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleQuoteV2Message([ZeroQuoteV2Message EXCEPT !.numberOfQuoteV2Bitfields = 1, !.quoteV2Bitfield1 = <<64>>, !.offerPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleQuoteV2Message([ZeroQuoteV2Message EXCEPT !.numberOfQuoteV2Bitfields = 1, !.quoteV2Bitfield1 = <<64>>, !.offerSize = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleQuoteV2Message([ZeroQuoteV2Message EXCEPT !.numberOfQuoteV2Bitfields = 1, !.quoteV2Bitfield1 = <<128>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }

(***************************************************************************)
(* Quote Cancel Rpt Grp                                                    *)
(***************************************************************************)

QuoteCancelRptGrp ==
    [ symbol           : { << >> } \cup { <<held>> : held \in Sample(8) },
      currency         : { << >> } \cup { <<held>> : held \in Sample(3) },
      idSource         : { << >> } \cup { <<held>> : held \in Sample(1) },
      securityId       : { << >> } \cup { <<held>> : held \in Sample(16) },
      securityExchange : { << >> } \cup { <<held>> : held \in Sample(4) } ]

EncodeQuoteCancelRptGrp(message) ==
    (IF message.symbol = << >> THEN << >> ELSE message.symbol[1])
        \o (IF message.currency = << >> THEN << >> ELSE message.currency[1])
        \o (IF message.idSource = << >> THEN << >> ELSE message.idSource[1])
        \o (IF message.securityId = << >> THEN << >> ELSE message.securityId[1])
        \o (IF message.securityExchange = << >> THEN << >> ELSE message.securityExchange[1])

DecodeQuoteCancelRptGrp(bytes, handedNumberOfQuoteCancelV2Bitfields, handedQuoteCancelV2Bitfield1) ==
    LET symbol == ReadWhen(handedNumberOfQuoteCancelV2Bitfields >= 1 /\ (handedQuoteCancelV2Bitfield1 # << >> /\ handedQuoteCancelV2Bitfield1[1] % 2 > 0), ReadBytes(bytes, 8), bytes) IN IF ~symbol.ok THEN Fail ELSE
    LET currency == ReadWhen(handedNumberOfQuoteCancelV2Bitfields >= 1 /\ (handedQuoteCancelV2Bitfield1 # << >> /\ (handedQuoteCancelV2Bitfield1[1] \div 2) % 2 > 0), ReadBytes(symbol.rest, 3), symbol.rest) IN IF ~currency.ok THEN Fail ELSE
    LET idSource == ReadWhen(handedNumberOfQuoteCancelV2Bitfields >= 1 /\ (handedQuoteCancelV2Bitfield1 # << >> /\ (handedQuoteCancelV2Bitfield1[1] \div 4) % 2 > 0), ReadBytes(currency.rest, 1), currency.rest) IN IF ~idSource.ok THEN Fail ELSE
    LET securityId == ReadWhen(handedNumberOfQuoteCancelV2Bitfields >= 1 /\ (handedQuoteCancelV2Bitfield1 # << >> /\ (handedQuoteCancelV2Bitfield1[1] \div 8) % 2 > 0), ReadBytes(idSource.rest, 16), idSource.rest) IN IF ~securityId.ok THEN Fail ELSE
    LET securityExchange == ReadWhen(handedNumberOfQuoteCancelV2Bitfields >= 1 /\ (handedQuoteCancelV2Bitfield1 # << >> /\ (handedQuoteCancelV2Bitfield1[1] \div 16) % 2 > 0), ReadBytes(securityId.rest, 4), securityId.rest) IN IF ~securityExchange.ok THEN Fail ELSE
    Ok([ symbol           |-> symbol.value,
         currency         |-> currency.value,
         idSource         |-> idSource.value,
         securityId       |-> securityId.value,
         securityExchange |-> securityExchange.value ], securityExchange.rest)

(* Quote Cancel Rpt Grp with each field marked present by fields before it there exactly where they say *)
SettleQuoteCancelRptGrp(message, handedNumberOfQuoteCancelV2Bitfields, handedQuoteCancelV2Bitfield1) ==
    LET settled1 == [message EXCEPT !.symbol = IF handedNumberOfQuoteCancelV2Bitfields >= 1 /\ (handedQuoteCancelV2Bitfield1 # << >> /\ handedQuoteCancelV2Bitfield1[1] % 2 > 0) THEN (IF message.symbol = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE message.symbol) ELSE << >>]
        settled2 == [settled1 EXCEPT !.currency = IF handedNumberOfQuoteCancelV2Bitfields >= 1 /\ (handedQuoteCancelV2Bitfield1 # << >> /\ (handedQuoteCancelV2Bitfield1[1] \div 2) % 2 > 0) THEN (IF settled1.currency = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled1.currency) ELSE << >>]
        settled3 == [settled2 EXCEPT !.idSource = IF handedNumberOfQuoteCancelV2Bitfields >= 1 /\ (handedQuoteCancelV2Bitfield1 # << >> /\ (handedQuoteCancelV2Bitfield1[1] \div 4) % 2 > 0) THEN (IF settled2.idSource = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled2.idSource) ELSE << >>]
        settled4 == [settled3 EXCEPT !.securityId = IF handedNumberOfQuoteCancelV2Bitfields >= 1 /\ (handedQuoteCancelV2Bitfield1 # << >> /\ (handedQuoteCancelV2Bitfield1[1] \div 8) % 2 > 0) THEN (IF settled3.securityId = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled3.securityId) ELSE << >>]
        settled5 == [settled4 EXCEPT !.securityExchange = IF handedNumberOfQuoteCancelV2Bitfields >= 1 /\ (handedQuoteCancelV2Bitfield1 # << >> /\ (handedQuoteCancelV2Bitfield1[1] \div 16) % 2 > 0) THEN (IF settled4.securityExchange = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled4.securityExchange) ELSE << >>]
    IN  settled5

ZeroQuoteCancelRptGrp ==
    SettleQuoteCancelRptGrp([ symbol           |-> << >>,
                              currency         |-> << >>,
                              idSource         |-> << >>,
                              securityId       |-> << >>,
                              securityExchange |-> << >> ], 0, << >>)

(* Quote Cancel Rpt Grp at zero, then each field in turn at the values it is checked at *)
CheckedQuoteCancelRptGrp ==
    { [given |-> <<0, << >>>>, message |-> ZeroQuoteCancelRptGrp] }
        \cup { [given |-> <<1, <<1>>>>, message |-> SettleQuoteCancelRptGrp([ZeroQuoteCancelRptGrp EXCEPT !.symbol = one], 1, <<1>>)] : one \in { <<held>> : held \in Sample(8) } }
        \cup { [given |-> <<1, <<2>>>>, message |-> SettleQuoteCancelRptGrp([ZeroQuoteCancelRptGrp EXCEPT !.currency = one], 1, <<2>>)] : one \in { <<held>> : held \in Sample(3) } }
        \cup { [given |-> <<1, <<4>>>>, message |-> SettleQuoteCancelRptGrp([ZeroQuoteCancelRptGrp EXCEPT !.idSource = one], 1, <<4>>)] : one \in { <<held>> : held \in Sample(1) } }
        \cup { [given |-> <<1, <<8>>>>, message |-> SettleQuoteCancelRptGrp([ZeroQuoteCancelRptGrp EXCEPT !.securityId = one], 1, <<8>>)] : one \in { <<held>> : held \in Sample(16) } }
        \cup { [given |-> <<1, <<16>>>>, message |-> SettleQuoteCancelRptGrp([ZeroQuoteCancelRptGrp EXCEPT !.securityExchange = one], 1, <<16>>)] : one \in { <<held>> : held \in Sample(4) } }

(* A run of Quote Cancel Rpt Grp, written one after another *)
RECURSIVE EncodeQuoteCancelRptGrpList(_)
EncodeQuoteCancelRptGrpList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeQuoteCancelRptGrp(Head(messages)) \o EncodeQuoteCancelRptGrpList(Tail(messages))

(* As many Quote Cancel Rpt Grp as the field that counts them says *)
RECURSIVE ReadQuoteCancelRptGrpList(_, _, _, _)
ReadQuoteCancelRptGrpList(bytes, count, handedNumberOfQuoteCancelV2Bitfields, handedQuoteCancelV2Bitfield1) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeQuoteCancelRptGrp(bytes, handedNumberOfQuoteCancelV2Bitfields, handedQuoteCancelV2Bitfield1)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadQuoteCancelRptGrpList(one.rest, count - 1, handedNumberOfQuoteCancelV2Bitfields, handedQuoteCancelV2Bitfield1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Quote Cancel Rpt Grp of each kind, for the lists that carry them *)
OneQuoteCancelRptGrp == { ZeroQuoteCancelRptGrp }

(***************************************************************************)
(* Quote Cancel V 2 Message                                                *)
(***************************************************************************)

QuoteCancelV2Message ==
    [ quoteId                        : Sample(20),
      numberOfQuoteCancelV2Bitfields : 0 .. 255,
      quoteCancelV2Bitfield1         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      quoteCancelRptGrp              : SampleLists(OneQuoteCancelRptGrp),
      clearingFirm                   : { << >> } \cup { <<held>> : held \in Sample(4) } ]

EncodeQuoteCancelV2Message(message) ==
    message.quoteId
        \o EncodeUIntBE(message.numberOfQuoteCancelV2Bitfields, 1)
        \o (IF message.quoteCancelV2Bitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.quoteCancelV2Bitfield1[1], 1))
        \o EncodeUIntBE(Len(message.quoteCancelRptGrp), 1)
        \o EncodeQuoteCancelRptGrpList(message.quoteCancelRptGrp)
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])

DecodeQuoteCancelV2Message(bytes) ==
    LET quoteId == ReadBytes(bytes, 20) IN IF ~quoteId.ok THEN Fail ELSE
    LET numberOfQuoteCancelV2Bitfields == ReadUIntBE(quoteId.rest, 1) IN IF ~numberOfQuoteCancelV2Bitfields.ok THEN Fail ELSE
    LET quoteCancelV2Bitfield1 == ReadWhen(numberOfQuoteCancelV2Bitfields.value >= 1, ReadUIntLE(numberOfQuoteCancelV2Bitfields.rest, 1), numberOfQuoteCancelV2Bitfields.rest) IN IF ~quoteCancelV2Bitfield1.ok THEN Fail ELSE
    LET noQuoteEntries == ReadUIntBE(quoteCancelV2Bitfield1.rest, 1) IN IF ~noQuoteEntries.ok THEN Fail ELSE
    LET quoteCancelRptGrp == ReadQuoteCancelRptGrpList(noQuoteEntries.rest, noQuoteEntries.value, numberOfQuoteCancelV2Bitfields.value, quoteCancelV2Bitfield1.value) IN IF ~quoteCancelRptGrp.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfQuoteCancelV2Bitfields.value >= 1 /\ (quoteCancelV2Bitfield1.value # << >> /\ (quoteCancelV2Bitfield1.value[1] \div 32) % 2 > 0), ReadBytes(quoteCancelRptGrp.rest, 4), quoteCancelRptGrp.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    Ok([ quoteId                        |-> quoteId.value,
         numberOfQuoteCancelV2Bitfields |-> numberOfQuoteCancelV2Bitfields.value,
         quoteCancelV2Bitfield1         |-> quoteCancelV2Bitfield1.value,
         quoteCancelRptGrp              |-> quoteCancelRptGrp.value,
         clearingFirm                   |-> clearingFirm.value ], clearingFirm.rest)

(* Quote Cancel V 2 Message with each field marked present by fields before it there exactly where they say *)
SettleQuoteCancelV2Message(message) ==
    LET settled1 == [message EXCEPT !.quoteCancelV2Bitfield1 = IF message.numberOfQuoteCancelV2Bitfields >= 1 THEN (IF message.quoteCancelV2Bitfield1 = << >> THEN <<0>> ELSE message.quoteCancelV2Bitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.quoteCancelRptGrp = [i \in DOMAIN settled1.quoteCancelRptGrp |-> SettleQuoteCancelRptGrp(settled1.quoteCancelRptGrp[i], settled1.numberOfQuoteCancelV2Bitfields, settled1.quoteCancelV2Bitfield1)]]
        settled3 == [settled2 EXCEPT !.clearingFirm = IF settled2.numberOfQuoteCancelV2Bitfields >= 1 /\ (settled2.quoteCancelV2Bitfield1 # << >> /\ (settled2.quoteCancelV2Bitfield1[1] \div 32) % 2 > 0) THEN (IF settled2.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled2.clearingFirm) ELSE << >>]
    IN  settled3

ZeroQuoteCancelV2Message ==
    SettleQuoteCancelV2Message([ quoteId                        |-> [i \in 1 .. 20 |-> 0],
                                 numberOfQuoteCancelV2Bitfields |-> 0,
                                 quoteCancelV2Bitfield1         |-> << >>,
                                 quoteCancelRptGrp              |-> << >>,
                                 clearingFirm                   |-> << >> ])

(* Quote Cancel V 2 Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteCancelV2Message ==
    { ZeroQuoteCancelV2Message }
        \cup { SettleQuoteCancelV2Message([ZeroQuoteCancelV2Message EXCEPT !.quoteId = one]) : one \in Sample(20) }
        \cup { SettleQuoteCancelV2Message([ZeroQuoteCancelV2Message EXCEPT !.numberOfQuoteCancelV2Bitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleQuoteCancelV2Message([ZeroQuoteCancelV2Message EXCEPT !.numberOfQuoteCancelV2Bitfields = 1, !.quoteCancelV2Bitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleQuoteCancelV2Message([ZeroQuoteCancelV2Message EXCEPT !.quoteCancelRptGrp = one]) : one \in SampleLists(OneQuoteCancelRptGrp) }
        \cup { SettleQuoteCancelV2Message([ZeroQuoteCancelV2Message EXCEPT !.numberOfQuoteCancelV2Bitfields = 1, !.quoteCancelV2Bitfield1 = <<1>>, !.quoteCancelRptGrp = one]) : one \in SampleLists(OneQuoteCancelRptGrp) }
        \cup { SettleQuoteCancelV2Message([ZeroQuoteCancelV2Message EXCEPT !.numberOfQuoteCancelV2Bitfields = 1, !.quoteCancelV2Bitfield1 = <<2>>, !.quoteCancelRptGrp = one]) : one \in SampleLists(OneQuoteCancelRptGrp) }
        \cup { SettleQuoteCancelV2Message([ZeroQuoteCancelV2Message EXCEPT !.numberOfQuoteCancelV2Bitfields = 1, !.quoteCancelV2Bitfield1 = <<4>>, !.quoteCancelRptGrp = one]) : one \in SampleLists(OneQuoteCancelRptGrp) }
        \cup { SettleQuoteCancelV2Message([ZeroQuoteCancelV2Message EXCEPT !.numberOfQuoteCancelV2Bitfields = 1, !.quoteCancelV2Bitfield1 = <<8>>, !.quoteCancelRptGrp = one]) : one \in SampleLists(OneQuoteCancelRptGrp) }
        \cup { SettleQuoteCancelV2Message([ZeroQuoteCancelV2Message EXCEPT !.numberOfQuoteCancelV2Bitfields = 1, !.quoteCancelV2Bitfield1 = <<16>>, !.quoteCancelRptGrp = one]) : one \in SampleLists(OneQuoteCancelRptGrp) }
        \cup { SettleQuoteCancelV2Message([ZeroQuoteCancelV2Message EXCEPT !.numberOfQuoteCancelV2Bitfields = 1, !.quoteCancelV2Bitfield1 = <<32>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }

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
      tradeReportRefId                                    : { << >> } \cup { <<held>> : held \in Sample(20) },
      orderCategory                                       : { << >> } \cup { <<held>> : held \in Sample(1) },
      waiverType                                          : { << >> } \cup { <<held>> : held \in Sample(1) },
      priceFormation                                      : { << >> } \cup { <<held>> : held \in Sample(1) },
      algorithmicIndicator                                : { << >> } \cup { <<held>> : held \in Sample(1) },
      deferralReason                                      : { << >> } \cup { <<held>> : held \in Sample(1) } ]

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
        \o (IF message.tradeReportRefId = << >> THEN << >> ELSE message.tradeReportRefId[1])
        \o (IF message.orderCategory = << >> THEN << >> ELSE message.orderCategory[1])
        \o (IF message.waiverType = << >> THEN << >> ELSE message.waiverType[1])
        \o (IF message.priceFormation = << >> THEN << >> ELSE message.priceFormation[1])
        \o (IF message.algorithmicIndicator = << >> THEN << >> ELSE message.algorithmicIndicator[1])
        \o (IF message.deferralReason = << >> THEN << >> ELSE message.deferralReason[1])

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
    LET tradeReportRefId == ReadWhen(numberOfTradeCaptureReportAcknowledgmentV2Bitfields.value >= 8 /\ (tradeCaptureReportAcknowledgmentV2Bitfield8.value # << >> /\ (tradeCaptureReportAcknowledgmentV2Bitfield8.value[1] \div 128) % 2 > 0), ReadBytes(largeSize.rest, 20), largeSize.rest) IN IF ~tradeReportRefId.ok THEN Fail ELSE
    LET orderCategory == ReadWhen(numberOfTradeCaptureReportAcknowledgmentV2Bitfields.value >= 9 /\ (tradeCaptureReportAcknowledgmentV2Bitfield9.value # << >> /\ (tradeCaptureReportAcknowledgmentV2Bitfield9.value[1] \div 8) % 2 > 0), ReadBytes(tradeReportRefId.rest, 1), tradeReportRefId.rest) IN IF ~orderCategory.ok THEN Fail ELSE
    LET waiverType == ReadWhen(numberOfTradeCaptureReportAcknowledgmentV2Bitfields.value >= 10 /\ (tradeCaptureReportAcknowledgmentV2Bitfield10.value # << >> /\ (tradeCaptureReportAcknowledgmentV2Bitfield10.value[1] \div 16) % 2 > 0), ReadBytes(orderCategory.rest, 1), orderCategory.rest) IN IF ~waiverType.ok THEN Fail ELSE
    LET priceFormation == ReadWhen(numberOfTradeCaptureReportAcknowledgmentV2Bitfields.value >= 10 /\ (tradeCaptureReportAcknowledgmentV2Bitfield10.value # << >> /\ (tradeCaptureReportAcknowledgmentV2Bitfield10.value[1] \div 64) % 2 > 0), ReadBytes(waiverType.rest, 1), waiverType.rest) IN IF ~priceFormation.ok THEN Fail ELSE
    LET algorithmicIndicator == ReadWhen(numberOfTradeCaptureReportAcknowledgmentV2Bitfields.value >= 11 /\ (tradeCaptureReportAcknowledgmentV2Bitfield11.value # << >> /\ (tradeCaptureReportAcknowledgmentV2Bitfield11.value[1] \div 16) % 2 > 0), ReadBytes(priceFormation.rest, 1), priceFormation.rest) IN IF ~algorithmicIndicator.ok THEN Fail ELSE
    LET deferralReason == ReadWhen(numberOfTradeCaptureReportAcknowledgmentV2Bitfields.value >= 11 /\ (tradeCaptureReportAcknowledgmentV2Bitfield11.value # << >> /\ (tradeCaptureReportAcknowledgmentV2Bitfield11.value[1] \div 32) % 2 > 0), ReadBytes(algorithmicIndicator.rest, 1), algorithmicIndicator.rest) IN IF ~deferralReason.ok THEN Fail ELSE
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
         tradeReportRefId                                    |-> tradeReportRefId.value,
         orderCategory                                       |-> orderCategory.value,
         waiverType                                          |-> waiverType.value,
         priceFormation                                      |-> priceFormation.value,
         algorithmicIndicator                                |-> algorithmicIndicator.value,
         deferralReason                                      |-> deferralReason.value ], deferralReason.rest)

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
        settled26 == [settled25 EXCEPT !.tradeReportRefId = IF settled25.numberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 8 /\ (settled25.tradeCaptureReportAcknowledgmentV2Bitfield8 # << >> /\ (settled25.tradeCaptureReportAcknowledgmentV2Bitfield8[1] \div 128) % 2 > 0) THEN (IF settled25.tradeReportRefId = << >> THEN <<[i \in 1 .. 20 |-> 0]>> ELSE settled25.tradeReportRefId) ELSE << >>]
        settled27 == [settled26 EXCEPT !.orderCategory = IF settled26.numberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 9 /\ (settled26.tradeCaptureReportAcknowledgmentV2Bitfield9 # << >> /\ (settled26.tradeCaptureReportAcknowledgmentV2Bitfield9[1] \div 8) % 2 > 0) THEN (IF settled26.orderCategory = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled26.orderCategory) ELSE << >>]
        settled28 == [settled27 EXCEPT !.waiverType = IF settled27.numberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 10 /\ (settled27.tradeCaptureReportAcknowledgmentV2Bitfield10 # << >> /\ (settled27.tradeCaptureReportAcknowledgmentV2Bitfield10[1] \div 16) % 2 > 0) THEN (IF settled27.waiverType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled27.waiverType) ELSE << >>]
        settled29 == [settled28 EXCEPT !.priceFormation = IF settled28.numberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 10 /\ (settled28.tradeCaptureReportAcknowledgmentV2Bitfield10 # << >> /\ (settled28.tradeCaptureReportAcknowledgmentV2Bitfield10[1] \div 64) % 2 > 0) THEN (IF settled28.priceFormation = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled28.priceFormation) ELSE << >>]
        settled30 == [settled29 EXCEPT !.algorithmicIndicator = IF settled29.numberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 11 /\ (settled29.tradeCaptureReportAcknowledgmentV2Bitfield11 # << >> /\ (settled29.tradeCaptureReportAcknowledgmentV2Bitfield11[1] \div 16) % 2 > 0) THEN (IF settled29.algorithmicIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled29.algorithmicIndicator) ELSE << >>]
        settled31 == [settled30 EXCEPT !.deferralReason = IF settled30.numberOfTradeCaptureReportAcknowledgmentV2Bitfields >= 11 /\ (settled30.tradeCaptureReportAcknowledgmentV2Bitfield11 # << >> /\ (settled30.tradeCaptureReportAcknowledgmentV2Bitfield11[1] \div 32) % 2 > 0) THEN (IF settled30.deferralReason = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled30.deferralReason) ELSE << >>]
    IN  settled31

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
                                                      tradeReportRefId                                    |-> << >>,
                                                      orderCategory                                       |-> << >>,
                                                      waiverType                                          |-> << >>,
                                                      priceFormation                                      |-> << >>,
                                                      algorithmicIndicator                                |-> << >>,
                                                      deferralReason                                      |-> << >> ])

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
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 8, !.tradeCaptureReportAcknowledgmentV2Bitfield8 = <<128>>, !.tradeReportRefId = one]) : one \in { <<held>> : held \in Sample(20) } }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 9, !.tradeCaptureReportAcknowledgmentV2Bitfield9 = <<8>>, !.orderCategory = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 10, !.tradeCaptureReportAcknowledgmentV2Bitfield10 = <<16>>, !.waiverType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 10, !.tradeCaptureReportAcknowledgmentV2Bitfield10 = <<64>>, !.priceFormation = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 11, !.tradeCaptureReportAcknowledgmentV2Bitfield11 = <<16>>, !.algorithmicIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportAcknowledgmentV2Message([ZeroTradeCaptureReportAcknowledgmentV2Message EXCEPT !.numberOfTradeCaptureReportAcknowledgmentV2Bitfields = 11, !.tradeCaptureReportAcknowledgmentV2Bitfield11 = <<32>>, !.deferralReason = one]) : one \in { <<held>> : held \in Sample(1) } }

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
      tradeCaptureReportRejectV2ReturnBitfield9  : { << >> } \cup { <<held>> : held \in Sample(1) },
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
      echoText                                   : { << >> } \cup { <<held>> : held \in Sample(64) },
      waiverType                                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      priceFormation                             : { << >> } \cup { <<held>> : held \in Sample(1) },
      algorithmicIndicator                       : { << >> } \cup { <<held>> : held \in Sample(1) },
      deferralReason                             : { << >> } \cup { <<held>> : held \in Sample(1) } ]

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
        \o (IF message.tradeCaptureReportRejectV2ReturnBitfield9 = << >> THEN << >> ELSE message.tradeCaptureReportRejectV2ReturnBitfield9[1])
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
        \o (IF message.echoText = << >> THEN << >> ELSE message.echoText[1])
        \o (IF message.waiverType = << >> THEN << >> ELSE message.waiverType[1])
        \o (IF message.priceFormation = << >> THEN << >> ELSE message.priceFormation[1])
        \o (IF message.algorithmicIndicator = << >> THEN << >> ELSE message.algorithmicIndicator[1])
        \o (IF message.deferralReason = << >> THEN << >> ELSE message.deferralReason[1])

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
    LET tradeCaptureReportRejectV2ReturnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadBytes(tradeCaptureReportRejectV2ReturnBitfield8.rest, 1), tradeCaptureReportRejectV2ReturnBitfield8.rest) IN IF ~tradeCaptureReportRejectV2ReturnBitfield9.ok THEN Fail ELSE
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
    LET echoText == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (tradeCaptureReportRejectV2ReturnBitfield8.value # << >> /\ (tradeCaptureReportRejectV2ReturnBitfield8.value[1] \div 2) % 2 > 0), ReadBytes(largeSize.rest, 64), largeSize.rest) IN IF ~echoText.ok THEN Fail ELSE
    LET waiverType == ReadWhen(numberOfReturnBitfields.value >= 10 /\ (tradeCaptureReportRejectV2ReturnBitfield10.value # << >> /\ (tradeCaptureReportRejectV2ReturnBitfield10.value[1] \div 16) % 2 > 0), ReadBytes(echoText.rest, 1), echoText.rest) IN IF ~waiverType.ok THEN Fail ELSE
    LET priceFormation == ReadWhen(numberOfReturnBitfields.value >= 10 /\ (tradeCaptureReportRejectV2ReturnBitfield10.value # << >> /\ (tradeCaptureReportRejectV2ReturnBitfield10.value[1] \div 64) % 2 > 0), ReadBytes(waiverType.rest, 1), waiverType.rest) IN IF ~priceFormation.ok THEN Fail ELSE
    LET algorithmicIndicator == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (tradeCaptureReportRejectV2ReturnBitfield11.value # << >> /\ (tradeCaptureReportRejectV2ReturnBitfield11.value[1] \div 16) % 2 > 0), ReadBytes(priceFormation.rest, 1), priceFormation.rest) IN IF ~algorithmicIndicator.ok THEN Fail ELSE
    LET deferralReason == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (tradeCaptureReportRejectV2ReturnBitfield11.value # << >> /\ (tradeCaptureReportRejectV2ReturnBitfield11.value[1] \div 32) % 2 > 0), ReadBytes(algorithmicIndicator.rest, 1), algorithmicIndicator.rest) IN IF ~deferralReason.ok THEN Fail ELSE
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
         echoText                                   |-> echoText.value,
         waiverType                                 |-> waiverType.value,
         priceFormation                             |-> priceFormation.value,
         algorithmicIndicator                       |-> algorithmicIndicator.value,
         deferralReason                             |-> deferralReason.value ], deferralReason.rest)

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
        settled9 == [settled8 EXCEPT !.tradeCaptureReportRejectV2ReturnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.tradeCaptureReportRejectV2ReturnBitfield9 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled8.tradeCaptureReportRejectV2ReturnBitfield9) ELSE << >>]
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
        settled28 == [settled27 EXCEPT !.echoText = IF settled27.numberOfReturnBitfields >= 8 /\ (settled27.tradeCaptureReportRejectV2ReturnBitfield8 # << >> /\ (settled27.tradeCaptureReportRejectV2ReturnBitfield8[1] \div 2) % 2 > 0) THEN (IF settled27.echoText = << >> THEN <<[i \in 1 .. 64 |-> 0]>> ELSE settled27.echoText) ELSE << >>]
        settled29 == [settled28 EXCEPT !.waiverType = IF settled28.numberOfReturnBitfields >= 10 /\ (settled28.tradeCaptureReportRejectV2ReturnBitfield10 # << >> /\ (settled28.tradeCaptureReportRejectV2ReturnBitfield10[1] \div 16) % 2 > 0) THEN (IF settled28.waiverType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled28.waiverType) ELSE << >>]
        settled30 == [settled29 EXCEPT !.priceFormation = IF settled29.numberOfReturnBitfields >= 10 /\ (settled29.tradeCaptureReportRejectV2ReturnBitfield10 # << >> /\ (settled29.tradeCaptureReportRejectV2ReturnBitfield10[1] \div 64) % 2 > 0) THEN (IF settled29.priceFormation = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled29.priceFormation) ELSE << >>]
        settled31 == [settled30 EXCEPT !.algorithmicIndicator = IF settled30.numberOfReturnBitfields >= 11 /\ (settled30.tradeCaptureReportRejectV2ReturnBitfield11 # << >> /\ (settled30.tradeCaptureReportRejectV2ReturnBitfield11[1] \div 16) % 2 > 0) THEN (IF settled30.algorithmicIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled30.algorithmicIndicator) ELSE << >>]
        settled32 == [settled31 EXCEPT !.deferralReason = IF settled31.numberOfReturnBitfields >= 11 /\ (settled31.tradeCaptureReportRejectV2ReturnBitfield11 # << >> /\ (settled31.tradeCaptureReportRejectV2ReturnBitfield11[1] \div 32) % 2 > 0) THEN (IF settled31.deferralReason = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled31.deferralReason) ELSE << >>]
    IN  settled32

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
                                              echoText                                   |-> << >>,
                                              waiverType                                 |-> << >>,
                                              priceFormation                             |-> << >>,
                                              algorithmicIndicator                       |-> << >>,
                                              deferralReason                             |-> << >> ])

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
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 9, !.tradeCaptureReportRejectV2ReturnBitfield9 = one]) : one \in { <<held>> : held \in Sample(1) } }
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
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 8, !.tradeCaptureReportRejectV2ReturnBitfield8 = <<2>>, !.echoText = one]) : one \in { <<held>> : held \in Sample(64) } }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 10, !.tradeCaptureReportRejectV2ReturnBitfield10 = <<16>>, !.waiverType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 10, !.tradeCaptureReportRejectV2ReturnBitfield10 = <<64>>, !.priceFormation = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 11, !.tradeCaptureReportRejectV2ReturnBitfield11 = <<16>>, !.algorithmicIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportRejectV2Message([ZeroTradeCaptureReportRejectV2Message EXCEPT !.numberOfReturnBitfields = 11, !.tradeCaptureReportRejectV2ReturnBitfield11 = <<32>>, !.deferralReason = one]) : one \in { <<held>> : held \in Sample(1) } }

(***************************************************************************)
(* Trade Capture Confirm V 2 Trd Cap Ack Side Grp                          *)
(***************************************************************************)

TradeCaptureConfirmV2TrdCapAckSideGrp ==
    [ side                : { << >> } \cup { <<held>> : held \in Sample(1) },
      capacity            : { << >> } \cup { <<held>> : held \in Sample(1) },
      account             : { << >> } \cup { <<held>> : held \in Sample(16) },
      partyId             : { << >> } \cup { <<held>> : held \in Sample(4) },
      centralCounterparty : { << >> } \cup { <<held>> : held \in Sample(1) },
      partyRole           : { << >> } \cup { <<held>> : held \in Sample(1) } ]

EncodeTradeCaptureConfirmV2TrdCapAckSideGrp(message) ==
    (IF message.side = << >> THEN << >> ELSE message.side[1])
        \o (IF message.capacity = << >> THEN << >> ELSE message.capacity[1])
        \o (IF message.account = << >> THEN << >> ELSE message.account[1])
        \o (IF message.partyId = << >> THEN << >> ELSE message.partyId[1])
        \o (IF message.centralCounterparty = << >> THEN << >> ELSE message.centralCounterparty[1])
        \o (IF message.partyRole = << >> THEN << >> ELSE message.partyRole[1])

DecodeTradeCaptureConfirmV2TrdCapAckSideGrp(bytes, handedNumberOfTradeCaptureConfirmV2Bitfields, handedTradeCaptureConfirmV2Bitfield1, handedTradeCaptureConfirmV2Bitfield2, handedTradeCaptureConfirmV2Bitfield3, handedTradeCaptureConfirmV2Bitfield4, handedTradeCaptureConfirmV2Bitfield6) ==
    LET side == ReadWhen(handedNumberOfTradeCaptureConfirmV2Bitfields >= 1 /\ (handedTradeCaptureConfirmV2Bitfield1 # << >> /\ handedTradeCaptureConfirmV2Bitfield1[1] % 2 > 0), ReadBytes(bytes, 1), bytes) IN IF ~side.ok THEN Fail ELSE
    LET capacity == ReadWhen(handedNumberOfTradeCaptureConfirmV2Bitfields >= 2 /\ (handedTradeCaptureConfirmV2Bitfield2 # << >> /\ (handedTradeCaptureConfirmV2Bitfield2[1] \div 64) % 2 > 0), ReadBytes(side.rest, 1), side.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadWhen(handedNumberOfTradeCaptureConfirmV2Bitfields >= 3 /\ (handedTradeCaptureConfirmV2Bitfield3 # << >> /\ handedTradeCaptureConfirmV2Bitfield3[1] % 2 > 0), ReadBytes(capacity.rest, 16), capacity.rest) IN IF ~account.ok THEN Fail ELSE
    LET partyId == ReadWhen(handedNumberOfTradeCaptureConfirmV2Bitfields >= 4 /\ (handedTradeCaptureConfirmV2Bitfield4 # << >> /\ (handedTradeCaptureConfirmV2Bitfield4[1] \div 64) % 2 > 0), ReadBytes(account.rest, 4), account.rest) IN IF ~partyId.ok THEN Fail ELSE
    LET centralCounterparty == ReadWhen(handedNumberOfTradeCaptureConfirmV2Bitfields >= 6 /\ (handedTradeCaptureConfirmV2Bitfield6 # << >> /\ (handedTradeCaptureConfirmV2Bitfield6[1] \div 2) % 2 > 0), ReadBytes(partyId.rest, 1), partyId.rest) IN IF ~centralCounterparty.ok THEN Fail ELSE
    LET partyRole == ReadWhen(handedNumberOfTradeCaptureConfirmV2Bitfields >= 6 /\ (handedTradeCaptureConfirmV2Bitfield6 # << >> /\ (handedTradeCaptureConfirmV2Bitfield6[1] \div 128) % 2 > 0), ReadBytes(centralCounterparty.rest, 1), centralCounterparty.rest) IN IF ~partyRole.ok THEN Fail ELSE
    Ok([ side                |-> side.value,
         capacity            |-> capacity.value,
         account             |-> account.value,
         partyId             |-> partyId.value,
         centralCounterparty |-> centralCounterparty.value,
         partyRole           |-> partyRole.value ], partyRole.rest)

(* Trade Capture Confirm V 2 Trd Cap Ack Side Grp with each field marked present by fields before it there exactly where they say *)
SettleTradeCaptureConfirmV2TrdCapAckSideGrp(message, handedNumberOfTradeCaptureConfirmV2Bitfields, handedTradeCaptureConfirmV2Bitfield1, handedTradeCaptureConfirmV2Bitfield2, handedTradeCaptureConfirmV2Bitfield3, handedTradeCaptureConfirmV2Bitfield4, handedTradeCaptureConfirmV2Bitfield6) ==
    LET settled1 == [message EXCEPT !.side = IF handedNumberOfTradeCaptureConfirmV2Bitfields >= 1 /\ (handedTradeCaptureConfirmV2Bitfield1 # << >> /\ handedTradeCaptureConfirmV2Bitfield1[1] % 2 > 0) THEN (IF message.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE message.side) ELSE << >>]
        settled2 == [settled1 EXCEPT !.capacity = IF handedNumberOfTradeCaptureConfirmV2Bitfields >= 2 /\ (handedTradeCaptureConfirmV2Bitfield2 # << >> /\ (handedTradeCaptureConfirmV2Bitfield2[1] \div 64) % 2 > 0) THEN (IF settled1.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled1.capacity) ELSE << >>]
        settled3 == [settled2 EXCEPT !.account = IF handedNumberOfTradeCaptureConfirmV2Bitfields >= 3 /\ (handedTradeCaptureConfirmV2Bitfield3 # << >> /\ handedTradeCaptureConfirmV2Bitfield3[1] % 2 > 0) THEN (IF settled2.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled2.account) ELSE << >>]
        settled4 == [settled3 EXCEPT !.partyId = IF handedNumberOfTradeCaptureConfirmV2Bitfields >= 4 /\ (handedTradeCaptureConfirmV2Bitfield4 # << >> /\ (handedTradeCaptureConfirmV2Bitfield4[1] \div 64) % 2 > 0) THEN (IF settled3.partyId = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled3.partyId) ELSE << >>]
        settled5 == [settled4 EXCEPT !.centralCounterparty = IF handedNumberOfTradeCaptureConfirmV2Bitfields >= 6 /\ (handedTradeCaptureConfirmV2Bitfield6 # << >> /\ (handedTradeCaptureConfirmV2Bitfield6[1] \div 2) % 2 > 0) THEN (IF settled4.centralCounterparty = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled4.centralCounterparty) ELSE << >>]
        settled6 == [settled5 EXCEPT !.partyRole = IF handedNumberOfTradeCaptureConfirmV2Bitfields >= 6 /\ (handedTradeCaptureConfirmV2Bitfield6 # << >> /\ (handedTradeCaptureConfirmV2Bitfield6[1] \div 128) % 2 > 0) THEN (IF settled5.partyRole = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled5.partyRole) ELSE << >>]
    IN  settled6

ZeroTradeCaptureConfirmV2TrdCapAckSideGrp ==
    SettleTradeCaptureConfirmV2TrdCapAckSideGrp([ side                |-> << >>,
                                                  capacity            |-> << >>,
                                                  account             |-> << >>,
                                                  partyId             |-> << >>,
                                                  centralCounterparty |-> << >>,
                                                  partyRole           |-> << >> ], 0, << >>, << >>, << >>, << >>, << >>)

(* Trade Capture Confirm V 2 Trd Cap Ack Side Grp at zero, then each field in turn at the values it is checked at *)
CheckedTradeCaptureConfirmV2TrdCapAckSideGrp ==
    { [given |-> <<0, << >>, << >>, << >>, << >>, << >>>>, message |-> ZeroTradeCaptureConfirmV2TrdCapAckSideGrp] }
        \cup { [given |-> <<1, <<1>>, << >>, << >>, << >>, << >>>>, message |-> SettleTradeCaptureConfirmV2TrdCapAckSideGrp([ZeroTradeCaptureConfirmV2TrdCapAckSideGrp EXCEPT !.side = one], 1, <<1>>, << >>, << >>, << >>, << >>)] : one \in { <<held>> : held \in Sample(1) } }
        \cup { [given |-> <<2, << >>, <<64>>, << >>, << >>, << >>>>, message |-> SettleTradeCaptureConfirmV2TrdCapAckSideGrp([ZeroTradeCaptureConfirmV2TrdCapAckSideGrp EXCEPT !.capacity = one], 2, << >>, <<64>>, << >>, << >>, << >>)] : one \in { <<held>> : held \in Sample(1) } }
        \cup { [given |-> <<3, << >>, << >>, <<1>>, << >>, << >>>>, message |-> SettleTradeCaptureConfirmV2TrdCapAckSideGrp([ZeroTradeCaptureConfirmV2TrdCapAckSideGrp EXCEPT !.account = one], 3, << >>, << >>, <<1>>, << >>, << >>)] : one \in { <<held>> : held \in Sample(16) } }
        \cup { [given |-> <<4, << >>, << >>, << >>, <<64>>, << >>>>, message |-> SettleTradeCaptureConfirmV2TrdCapAckSideGrp([ZeroTradeCaptureConfirmV2TrdCapAckSideGrp EXCEPT !.partyId = one], 4, << >>, << >>, << >>, <<64>>, << >>)] : one \in { <<held>> : held \in Sample(4) } }
        \cup { [given |-> <<6, << >>, << >>, << >>, << >>, <<2>>>>, message |-> SettleTradeCaptureConfirmV2TrdCapAckSideGrp([ZeroTradeCaptureConfirmV2TrdCapAckSideGrp EXCEPT !.centralCounterparty = one], 6, << >>, << >>, << >>, << >>, <<2>>)] : one \in { <<held>> : held \in Sample(1) } }
        \cup { [given |-> <<6, << >>, << >>, << >>, << >>, <<128>>>>, message |-> SettleTradeCaptureConfirmV2TrdCapAckSideGrp([ZeroTradeCaptureConfirmV2TrdCapAckSideGrp EXCEPT !.partyRole = one], 6, << >>, << >>, << >>, << >>, <<128>>)] : one \in { <<held>> : held \in Sample(1) } }

(* A run of Trade Capture Confirm V 2 Trd Cap Ack Side Grp, written one after another *)
RECURSIVE EncodeTradeCaptureConfirmV2TrdCapAckSideGrpList(_)
EncodeTradeCaptureConfirmV2TrdCapAckSideGrpList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTradeCaptureConfirmV2TrdCapAckSideGrp(Head(messages)) \o EncodeTradeCaptureConfirmV2TrdCapAckSideGrpList(Tail(messages))

(* As many Trade Capture Confirm V 2 Trd Cap Ack Side Grp as the field that counts them says *)
RECURSIVE ReadTradeCaptureConfirmV2TrdCapAckSideGrpList(_, _, _, _, _, _, _, _)
ReadTradeCaptureConfirmV2TrdCapAckSideGrpList(bytes, count, handedNumberOfTradeCaptureConfirmV2Bitfields, handedTradeCaptureConfirmV2Bitfield1, handedTradeCaptureConfirmV2Bitfield2, handedTradeCaptureConfirmV2Bitfield3, handedTradeCaptureConfirmV2Bitfield4, handedTradeCaptureConfirmV2Bitfield6) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeTradeCaptureConfirmV2TrdCapAckSideGrp(bytes, handedNumberOfTradeCaptureConfirmV2Bitfields, handedTradeCaptureConfirmV2Bitfield1, handedTradeCaptureConfirmV2Bitfield2, handedTradeCaptureConfirmV2Bitfield3, handedTradeCaptureConfirmV2Bitfield4, handedTradeCaptureConfirmV2Bitfield6)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTradeCaptureConfirmV2TrdCapAckSideGrpList(one.rest, count - 1, handedNumberOfTradeCaptureConfirmV2Bitfields, handedTradeCaptureConfirmV2Bitfield1, handedTradeCaptureConfirmV2Bitfield2, handedTradeCaptureConfirmV2Bitfield3, handedTradeCaptureConfirmV2Bitfield4, handedTradeCaptureConfirmV2Bitfield6)
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
      lastPx                                 : Sample(8),
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
      feeCode                                : { << >> } \cup { <<held>> : held \in Sample(2) },
      echoText                               : { << >> } \cup { <<held>> : held \in Sample(64) },
      orderCategory                          : { << >> } \cup { <<held>> : held \in Sample(1) },
      waiverType                             : { << >> } \cup { <<held>> : held \in Sample(1) },
      priceFormation                         : { << >> } \cup { <<held>> : held \in Sample(1) },
      algorithmicIndicator                   : { << >> } \cup { <<held>> : held \in Sample(1) },
      deferralReason                         : { << >> } \cup { <<held>> : held \in Sample(1) } ]

EncodeTradeCaptureConfirmV2Message(message) ==
    message.transactionTime
        \o message.tradeReportId
        \o message.tradeReportRefId
        \o message.tradeId
        \o message.lastShares
        \o message.lastPx
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
        \o (IF message.feeCode = << >> THEN << >> ELSE message.feeCode[1])
        \o (IF message.echoText = << >> THEN << >> ELSE message.echoText[1])
        \o (IF message.orderCategory = << >> THEN << >> ELSE message.orderCategory[1])
        \o (IF message.waiverType = << >> THEN << >> ELSE message.waiverType[1])
        \o (IF message.priceFormation = << >> THEN << >> ELSE message.priceFormation[1])
        \o (IF message.algorithmicIndicator = << >> THEN << >> ELSE message.algorithmicIndicator[1])
        \o (IF message.deferralReason = << >> THEN << >> ELSE message.deferralReason[1])

DecodeTradeCaptureConfirmV2Message(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(transactionTime.rest, 20) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET tradeReportRefId == ReadBytes(tradeReportId.rest, 20) IN IF ~tradeReportRefId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(tradeReportRefId.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET lastShares == ReadBytes(tradeId.rest, 4) IN IF ~lastShares.ok THEN Fail ELSE
    LET lastPx == ReadBytes(lastShares.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET contraBroker == ReadBytes(lastPx.rest, 4) IN IF ~contraBroker.ok THEN Fail ELSE
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
    LET tradeCaptureConfirmV2TrdCapAckSideGrp == ReadTradeCaptureConfirmV2TrdCapAckSideGrpList(noSides.rest, noSides.value, numberOfTradeCaptureConfirmV2Bitfields.value, tradeCaptureConfirmV2Bitfield1.value, tradeCaptureConfirmV2Bitfield2.value, tradeCaptureConfirmV2Bitfield3.value, tradeCaptureConfirmV2Bitfield4.value, tradeCaptureConfirmV2Bitfield6.value) IN IF ~tradeCaptureConfirmV2TrdCapAckSideGrp.ok THEN Fail ELSE
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
    LET feeCode == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 8 /\ (tradeCaptureConfirmV2Bitfield8.value # << >> /\ tradeCaptureConfirmV2Bitfield8.value[1] % 2 > 0), ReadBytes(largeSize.rest, 2), largeSize.rest) IN IF ~feeCode.ok THEN Fail ELSE
    LET echoText == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 8 /\ (tradeCaptureConfirmV2Bitfield8.value # << >> /\ (tradeCaptureConfirmV2Bitfield8.value[1] \div 2) % 2 > 0), ReadBytes(feeCode.rest, 64), feeCode.rest) IN IF ~echoText.ok THEN Fail ELSE
    LET orderCategory == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 9 /\ (tradeCaptureConfirmV2Bitfield9.value # << >> /\ (tradeCaptureConfirmV2Bitfield9.value[1] \div 8) % 2 > 0), ReadBytes(echoText.rest, 1), echoText.rest) IN IF ~orderCategory.ok THEN Fail ELSE
    LET waiverType == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 10 /\ (tradeCaptureConfirmV2Bitfield10.value # << >> /\ (tradeCaptureConfirmV2Bitfield10.value[1] \div 16) % 2 > 0), ReadBytes(orderCategory.rest, 1), orderCategory.rest) IN IF ~waiverType.ok THEN Fail ELSE
    LET priceFormation == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 10 /\ (tradeCaptureConfirmV2Bitfield10.value # << >> /\ (tradeCaptureConfirmV2Bitfield10.value[1] \div 64) % 2 > 0), ReadBytes(waiverType.rest, 1), waiverType.rest) IN IF ~priceFormation.ok THEN Fail ELSE
    LET algorithmicIndicator == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 11 /\ (tradeCaptureConfirmV2Bitfield11.value # << >> /\ (tradeCaptureConfirmV2Bitfield11.value[1] \div 16) % 2 > 0), ReadBytes(priceFormation.rest, 1), priceFormation.rest) IN IF ~algorithmicIndicator.ok THEN Fail ELSE
    LET deferralReason == ReadWhen(numberOfTradeCaptureConfirmV2Bitfields.value >= 11 /\ (tradeCaptureConfirmV2Bitfield11.value # << >> /\ (tradeCaptureConfirmV2Bitfield11.value[1] \div 32) % 2 > 0), ReadBytes(algorithmicIndicator.rest, 1), algorithmicIndicator.rest) IN IF ~deferralReason.ok THEN Fail ELSE
    Ok([ transactionTime                        |-> transactionTime.value,
         tradeReportId                          |-> tradeReportId.value,
         tradeReportRefId                       |-> tradeReportRefId.value,
         tradeId                                |-> tradeId.value,
         lastShares                             |-> lastShares.value,
         lastPx                                 |-> lastPx.value,
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
         feeCode                                |-> feeCode.value,
         echoText                               |-> echoText.value,
         orderCategory                          |-> orderCategory.value,
         waiverType                             |-> waiverType.value,
         priceFormation                         |-> priceFormation.value,
         algorithmicIndicator                   |-> algorithmicIndicator.value,
         deferralReason                         |-> deferralReason.value ], deferralReason.rest)

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
        settled15 == [settled14 EXCEPT !.tradeCaptureConfirmV2TrdCapAckSideGrp = [i \in DOMAIN settled14.tradeCaptureConfirmV2TrdCapAckSideGrp |-> SettleTradeCaptureConfirmV2TrdCapAckSideGrp(settled14.tradeCaptureConfirmV2TrdCapAckSideGrp[i], settled14.numberOfTradeCaptureConfirmV2Bitfields, settled14.tradeCaptureConfirmV2Bitfield1, settled14.tradeCaptureConfirmV2Bitfield2, settled14.tradeCaptureConfirmV2Bitfield3, settled14.tradeCaptureConfirmV2Bitfield4, settled14.tradeCaptureConfirmV2Bitfield6)]]
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
        settled30 == [settled29 EXCEPT !.feeCode = IF settled29.numberOfTradeCaptureConfirmV2Bitfields >= 8 /\ (settled29.tradeCaptureConfirmV2Bitfield8 # << >> /\ settled29.tradeCaptureConfirmV2Bitfield8[1] % 2 > 0) THEN (IF settled29.feeCode = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled29.feeCode) ELSE << >>]
        settled31 == [settled30 EXCEPT !.echoText = IF settled30.numberOfTradeCaptureConfirmV2Bitfields >= 8 /\ (settled30.tradeCaptureConfirmV2Bitfield8 # << >> /\ (settled30.tradeCaptureConfirmV2Bitfield8[1] \div 2) % 2 > 0) THEN (IF settled30.echoText = << >> THEN <<[i \in 1 .. 64 |-> 0]>> ELSE settled30.echoText) ELSE << >>]
        settled32 == [settled31 EXCEPT !.orderCategory = IF settled31.numberOfTradeCaptureConfirmV2Bitfields >= 9 /\ (settled31.tradeCaptureConfirmV2Bitfield9 # << >> /\ (settled31.tradeCaptureConfirmV2Bitfield9[1] \div 8) % 2 > 0) THEN (IF settled31.orderCategory = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled31.orderCategory) ELSE << >>]
        settled33 == [settled32 EXCEPT !.waiverType = IF settled32.numberOfTradeCaptureConfirmV2Bitfields >= 10 /\ (settled32.tradeCaptureConfirmV2Bitfield10 # << >> /\ (settled32.tradeCaptureConfirmV2Bitfield10[1] \div 16) % 2 > 0) THEN (IF settled32.waiverType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled32.waiverType) ELSE << >>]
        settled34 == [settled33 EXCEPT !.priceFormation = IF settled33.numberOfTradeCaptureConfirmV2Bitfields >= 10 /\ (settled33.tradeCaptureConfirmV2Bitfield10 # << >> /\ (settled33.tradeCaptureConfirmV2Bitfield10[1] \div 64) % 2 > 0) THEN (IF settled33.priceFormation = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled33.priceFormation) ELSE << >>]
        settled35 == [settled34 EXCEPT !.algorithmicIndicator = IF settled34.numberOfTradeCaptureConfirmV2Bitfields >= 11 /\ (settled34.tradeCaptureConfirmV2Bitfield11 # << >> /\ (settled34.tradeCaptureConfirmV2Bitfield11[1] \div 16) % 2 > 0) THEN (IF settled34.algorithmicIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled34.algorithmicIndicator) ELSE << >>]
        settled36 == [settled35 EXCEPT !.deferralReason = IF settled35.numberOfTradeCaptureConfirmV2Bitfields >= 11 /\ (settled35.tradeCaptureConfirmV2Bitfield11 # << >> /\ (settled35.tradeCaptureConfirmV2Bitfield11[1] \div 32) % 2 > 0) THEN (IF settled35.deferralReason = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled35.deferralReason) ELSE << >>]
    IN  settled36

ZeroTradeCaptureConfirmV2Message ==
    SettleTradeCaptureConfirmV2Message([ transactionTime                        |-> [i \in 1 .. 8 |-> 0],
                                         tradeReportId                          |-> [i \in 1 .. 20 |-> 0],
                                         tradeReportRefId                       |-> [i \in 1 .. 20 |-> 0],
                                         tradeId                                |-> [i \in 1 .. 8 |-> 0],
                                         lastShares                             |-> [i \in 1 .. 4 |-> 0],
                                         lastPx                                 |-> [i \in 1 .. 8 |-> 0],
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
                                         feeCode                                |-> << >>,
                                         echoText                               |-> << >>,
                                         orderCategory                          |-> << >>,
                                         waiverType                             |-> << >>,
                                         priceFormation                         |-> << >>,
                                         algorithmicIndicator                   |-> << >>,
                                         deferralReason                         |-> << >> ])

(* Trade Capture Confirm V 2 Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCaptureConfirmV2Message ==
    { ZeroTradeCaptureConfirmV2Message }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.transactionTime = one]) : one \in Sample(8) }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.tradeReportId = one]) : one \in Sample(20) }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.tradeReportRefId = one]) : one \in Sample(20) }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.tradeId = one]) : one \in Sample(8) }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.lastShares = one]) : one \in Sample(4) }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.lastPx = one]) : one \in Sample(8) }
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
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 8, !.tradeCaptureConfirmV2Bitfield8 = <<1>>, !.feeCode = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 8, !.tradeCaptureConfirmV2Bitfield8 = <<2>>, !.echoText = one]) : one \in { <<held>> : held \in Sample(64) } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 9, !.tradeCaptureConfirmV2Bitfield9 = <<8>>, !.orderCategory = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 10, !.tradeCaptureConfirmV2Bitfield10 = <<16>>, !.waiverType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 10, !.tradeCaptureConfirmV2Bitfield10 = <<64>>, !.priceFormation = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 11, !.tradeCaptureConfirmV2Bitfield11 = <<16>>, !.algorithmicIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureConfirmV2Message([ZeroTradeCaptureConfirmV2Message EXCEPT !.numberOfTradeCaptureConfirmV2Bitfields = 11, !.tradeCaptureConfirmV2Bitfield11 = <<32>>, !.deferralReason = one]) : one \in { <<held>> : held \in Sample(1) } }

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
      lastPx                                      : Sample(8),
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
      tradeCaptureReportDeclineV2ReturnBitfield9  : { << >> } \cup { <<held>> : held \in Sample(1) },
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
      echoText                                    : { << >> } \cup { <<held>> : held \in Sample(64) },
      waiverType                                  : { << >> } \cup { <<held>> : held \in Sample(1) },
      priceFormation                              : { << >> } \cup { <<held>> : held \in Sample(1) },
      algorithmicIndicator                        : { << >> } \cup { <<held>> : held \in Sample(1) },
      deferralReason                              : { << >> } \cup { <<held>> : held \in Sample(1) } ]

EncodeTradeCaptureReportDeclineV2Message(message) ==
    message.transactionTime
        \o message.tradeReportId
        \o message.tradeReportRefId
        \o message.tradeId
        \o message.lastShares
        \o message.lastPx
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
        \o (IF message.tradeCaptureReportDeclineV2ReturnBitfield9 = << >> THEN << >> ELSE message.tradeCaptureReportDeclineV2ReturnBitfield9[1])
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
        \o (IF message.echoText = << >> THEN << >> ELSE message.echoText[1])
        \o (IF message.waiverType = << >> THEN << >> ELSE message.waiverType[1])
        \o (IF message.priceFormation = << >> THEN << >> ELSE message.priceFormation[1])
        \o (IF message.algorithmicIndicator = << >> THEN << >> ELSE message.algorithmicIndicator[1])
        \o (IF message.deferralReason = << >> THEN << >> ELSE message.deferralReason[1])

DecodeTradeCaptureReportDeclineV2Message(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(transactionTime.rest, 20) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET tradeReportRefId == ReadBytes(tradeReportId.rest, 20) IN IF ~tradeReportRefId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(tradeReportRefId.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET lastShares == ReadBytes(tradeId.rest, 4) IN IF ~lastShares.ok THEN Fail ELSE
    LET lastPx == ReadBytes(lastShares.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET contraBroker == ReadBytes(lastPx.rest, 4) IN IF ~contraBroker.ok THEN Fail ELSE
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
    LET tradeCaptureReportDeclineV2ReturnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadBytes(tradeCaptureReportDeclineV2ReturnBitfield8.rest, 1), tradeCaptureReportDeclineV2ReturnBitfield8.rest) IN IF ~tradeCaptureReportDeclineV2ReturnBitfield9.ok THEN Fail ELSE
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
    LET echoText == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (tradeCaptureReportDeclineV2ReturnBitfield8.value # << >> /\ (tradeCaptureReportDeclineV2ReturnBitfield8.value[1] \div 2) % 2 > 0), ReadBytes(largeSize.rest, 64), largeSize.rest) IN IF ~echoText.ok THEN Fail ELSE
    LET waiverType == ReadWhen(numberOfReturnBitfields.value >= 10 /\ (tradeCaptureReportDeclineV2ReturnBitfield10.value # << >> /\ (tradeCaptureReportDeclineV2ReturnBitfield10.value[1] \div 16) % 2 > 0), ReadBytes(echoText.rest, 1), echoText.rest) IN IF ~waiverType.ok THEN Fail ELSE
    LET priceFormation == ReadWhen(numberOfReturnBitfields.value >= 10 /\ (tradeCaptureReportDeclineV2ReturnBitfield10.value # << >> /\ (tradeCaptureReportDeclineV2ReturnBitfield10.value[1] \div 64) % 2 > 0), ReadBytes(waiverType.rest, 1), waiverType.rest) IN IF ~priceFormation.ok THEN Fail ELSE
    LET algorithmicIndicator == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (tradeCaptureReportDeclineV2ReturnBitfield11.value # << >> /\ (tradeCaptureReportDeclineV2ReturnBitfield11.value[1] \div 16) % 2 > 0), ReadBytes(priceFormation.rest, 1), priceFormation.rest) IN IF ~algorithmicIndicator.ok THEN Fail ELSE
    LET deferralReason == ReadWhen(numberOfReturnBitfields.value >= 11 /\ (tradeCaptureReportDeclineV2ReturnBitfield11.value # << >> /\ (tradeCaptureReportDeclineV2ReturnBitfield11.value[1] \div 32) % 2 > 0), ReadBytes(algorithmicIndicator.rest, 1), algorithmicIndicator.rest) IN IF ~deferralReason.ok THEN Fail ELSE
    Ok([ transactionTime                             |-> transactionTime.value,
         tradeReportId                               |-> tradeReportId.value,
         tradeReportRefId                            |-> tradeReportRefId.value,
         tradeId                                     |-> tradeId.value,
         lastShares                                  |-> lastShares.value,
         lastPx                                      |-> lastPx.value,
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
         echoText                                    |-> echoText.value,
         waiverType                                  |-> waiverType.value,
         priceFormation                              |-> priceFormation.value,
         algorithmicIndicator                        |-> algorithmicIndicator.value,
         deferralReason                              |-> deferralReason.value ], deferralReason.rest)

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
        settled9 == [settled8 EXCEPT !.tradeCaptureReportDeclineV2ReturnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.tradeCaptureReportDeclineV2ReturnBitfield9 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled8.tradeCaptureReportDeclineV2ReturnBitfield9) ELSE << >>]
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
        settled28 == [settled27 EXCEPT !.echoText = IF settled27.numberOfReturnBitfields >= 8 /\ (settled27.tradeCaptureReportDeclineV2ReturnBitfield8 # << >> /\ (settled27.tradeCaptureReportDeclineV2ReturnBitfield8[1] \div 2) % 2 > 0) THEN (IF settled27.echoText = << >> THEN <<[i \in 1 .. 64 |-> 0]>> ELSE settled27.echoText) ELSE << >>]
        settled29 == [settled28 EXCEPT !.waiverType = IF settled28.numberOfReturnBitfields >= 10 /\ (settled28.tradeCaptureReportDeclineV2ReturnBitfield10 # << >> /\ (settled28.tradeCaptureReportDeclineV2ReturnBitfield10[1] \div 16) % 2 > 0) THEN (IF settled28.waiverType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled28.waiverType) ELSE << >>]
        settled30 == [settled29 EXCEPT !.priceFormation = IF settled29.numberOfReturnBitfields >= 10 /\ (settled29.tradeCaptureReportDeclineV2ReturnBitfield10 # << >> /\ (settled29.tradeCaptureReportDeclineV2ReturnBitfield10[1] \div 64) % 2 > 0) THEN (IF settled29.priceFormation = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled29.priceFormation) ELSE << >>]
        settled31 == [settled30 EXCEPT !.algorithmicIndicator = IF settled30.numberOfReturnBitfields >= 11 /\ (settled30.tradeCaptureReportDeclineV2ReturnBitfield11 # << >> /\ (settled30.tradeCaptureReportDeclineV2ReturnBitfield11[1] \div 16) % 2 > 0) THEN (IF settled30.algorithmicIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled30.algorithmicIndicator) ELSE << >>]
        settled32 == [settled31 EXCEPT !.deferralReason = IF settled31.numberOfReturnBitfields >= 11 /\ (settled31.tradeCaptureReportDeclineV2ReturnBitfield11 # << >> /\ (settled31.tradeCaptureReportDeclineV2ReturnBitfield11[1] \div 32) % 2 > 0) THEN (IF settled31.deferralReason = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled31.deferralReason) ELSE << >>]
    IN  settled32

ZeroTradeCaptureReportDeclineV2Message ==
    SettleTradeCaptureReportDeclineV2Message([ transactionTime                             |-> [i \in 1 .. 8 |-> 0],
                                               tradeReportId                               |-> [i \in 1 .. 20 |-> 0],
                                               tradeReportRefId                            |-> [i \in 1 .. 20 |-> 0],
                                               tradeId                                     |-> [i \in 1 .. 8 |-> 0],
                                               lastShares                                  |-> [i \in 1 .. 4 |-> 0],
                                               lastPx                                      |-> [i \in 1 .. 8 |-> 0],
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
                                               echoText                                    |-> << >>,
                                               waiverType                                  |-> << >>,
                                               priceFormation                              |-> << >>,
                                               algorithmicIndicator                        |-> << >>,
                                               deferralReason                              |-> << >> ])

(* Trade Capture Report Decline V 2 Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCaptureReportDeclineV2Message ==
    { ZeroTradeCaptureReportDeclineV2Message }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.transactionTime = one]) : one \in Sample(8) }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.tradeReportId = one]) : one \in Sample(20) }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.tradeReportRefId = one]) : one \in Sample(20) }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.tradeId = one]) : one \in Sample(8) }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.lastShares = one]) : one \in Sample(4) }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.lastPx = one]) : one \in Sample(8) }
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
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 9, !.tradeCaptureReportDeclineV2ReturnBitfield9 = one]) : one \in { <<held>> : held \in Sample(1) } }
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
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 8, !.tradeCaptureReportDeclineV2ReturnBitfield8 = <<2>>, !.echoText = one]) : one \in { <<held>> : held \in Sample(64) } }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 10, !.tradeCaptureReportDeclineV2ReturnBitfield10 = <<16>>, !.waiverType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 10, !.tradeCaptureReportDeclineV2ReturnBitfield10 = <<64>>, !.priceFormation = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 11, !.tradeCaptureReportDeclineV2ReturnBitfield11 = <<16>>, !.algorithmicIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCaptureReportDeclineV2Message([ZeroTradeCaptureReportDeclineV2Message EXCEPT !.numberOfReturnBitfields = 11, !.tradeCaptureReportDeclineV2ReturnBitfield11 = <<32>>, !.deferralReason = one]) : one \in { <<held>> : held \in Sample(1) } }

(***************************************************************************)
(* Quote Status V 2 Message                                                *)
(***************************************************************************)

QuoteStatusV2Message ==
    [ quoteId                       : Sample(20),
      status                        : Sample(1),
      reserved1                     : Sample(1),
      numberOfReturnBitfields       : 0 .. 255,
      quoteStatusV2ReturnBitfield1  : { << >> } \cup { <<held>> : held \in Sample(1) },
      quoteStatusV2ReturnBitfield2  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      quoteStatusV2ReturnBitfield3  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      quoteStatusV2ReturnBitfield4  : { << >> } \cup { <<held>> : held \in Sample(1) },
      quoteStatusV2ReturnBitfield5  : { << >> } \cup { <<held>> : held \in Sample(1) },
      quoteStatusV2ReturnBitfield6  : { << >> } \cup { <<held>> : held \in Sample(1) },
      quoteStatusV2ReturnBitfield7  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      quoteStatusV2ReturnBitfield8  : { << >> } \cup { <<held>> : held \in Sample(1) },
      quoteStatusV2ReturnBitfield9  : { << >> } \cup { <<held>> : held \in Sample(1) },
      quoteStatusV2ReturnBitfield10 : { << >> } \cup { <<held>> : held \in Sample(1) },
      quoteStatusV2ReturnBitfield11 : { << >> } \cup { <<held>> : held \in Sample(1) },
      quoteStatusV2ReturnBitfield12 : { << >> } \cup { <<held>> : held \in Sample(1) },
      quoteStatusV2ReturnBitfield13 : { << >> } \cup { <<held>> : held \in Sample(1) },
      quoteStatusV2ReturnBitfield14 : { << >> } \cup { <<held>> : held \in Sample(1) },
      symbol                        : { << >> } \cup { <<held>> : held \in Sample(8) },
      currency                      : { << >> } \cup { <<held>> : held \in Sample(3) },
      idSource                      : { << >> } \cup { <<held>> : held \in Sample(1) },
      securityId                    : { << >> } \cup { <<held>> : held \in Sample(16) },
      securityExchange              : { << >> } \cup { <<held>> : held \in Sample(4) },
      capacity                      : { << >> } \cup { <<held>> : held \in Sample(1) },
      clearingFirm                  : { << >> } \cup { <<held>> : held \in Sample(4) },
      bidPx                         : { << >> } \cup { <<held>> : held \in Sample(8) },
      bidSize                       : { << >> } \cup { <<held>> : held \in Sample(4) },
      offerPx                       : { << >> } \cup { <<held>> : held \in Sample(8) },
      offerSize                     : { << >> } \cup { <<held>> : held \in Sample(4) } ]

EncodeQuoteStatusV2Message(message) ==
    message.quoteId
        \o message.status
        \o message.reserved1
        \o EncodeUIntBE(message.numberOfReturnBitfields, 1)
        \o (IF message.quoteStatusV2ReturnBitfield1 = << >> THEN << >> ELSE message.quoteStatusV2ReturnBitfield1[1])
        \o (IF message.quoteStatusV2ReturnBitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.quoteStatusV2ReturnBitfield2[1], 1))
        \o (IF message.quoteStatusV2ReturnBitfield3 = << >> THEN << >> ELSE EncodeUIntLE(message.quoteStatusV2ReturnBitfield3[1], 1))
        \o (IF message.quoteStatusV2ReturnBitfield4 = << >> THEN << >> ELSE message.quoteStatusV2ReturnBitfield4[1])
        \o (IF message.quoteStatusV2ReturnBitfield5 = << >> THEN << >> ELSE message.quoteStatusV2ReturnBitfield5[1])
        \o (IF message.quoteStatusV2ReturnBitfield6 = << >> THEN << >> ELSE message.quoteStatusV2ReturnBitfield6[1])
        \o (IF message.quoteStatusV2ReturnBitfield7 = << >> THEN << >> ELSE EncodeUIntLE(message.quoteStatusV2ReturnBitfield7[1], 1))
        \o (IF message.quoteStatusV2ReturnBitfield8 = << >> THEN << >> ELSE message.quoteStatusV2ReturnBitfield8[1])
        \o (IF message.quoteStatusV2ReturnBitfield9 = << >> THEN << >> ELSE message.quoteStatusV2ReturnBitfield9[1])
        \o (IF message.quoteStatusV2ReturnBitfield10 = << >> THEN << >> ELSE message.quoteStatusV2ReturnBitfield10[1])
        \o (IF message.quoteStatusV2ReturnBitfield11 = << >> THEN << >> ELSE message.quoteStatusV2ReturnBitfield11[1])
        \o (IF message.quoteStatusV2ReturnBitfield12 = << >> THEN << >> ELSE message.quoteStatusV2ReturnBitfield12[1])
        \o (IF message.quoteStatusV2ReturnBitfield13 = << >> THEN << >> ELSE message.quoteStatusV2ReturnBitfield13[1])
        \o (IF message.quoteStatusV2ReturnBitfield14 = << >> THEN << >> ELSE message.quoteStatusV2ReturnBitfield14[1])
        \o (IF message.symbol = << >> THEN << >> ELSE message.symbol[1])
        \o (IF message.currency = << >> THEN << >> ELSE message.currency[1])
        \o (IF message.idSource = << >> THEN << >> ELSE message.idSource[1])
        \o (IF message.securityId = << >> THEN << >> ELSE message.securityId[1])
        \o (IF message.securityExchange = << >> THEN << >> ELSE message.securityExchange[1])
        \o (IF message.capacity = << >> THEN << >> ELSE message.capacity[1])
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])
        \o (IF message.bidPx = << >> THEN << >> ELSE message.bidPx[1])
        \o (IF message.bidSize = << >> THEN << >> ELSE message.bidSize[1])
        \o (IF message.offerPx = << >> THEN << >> ELSE message.offerPx[1])
        \o (IF message.offerSize = << >> THEN << >> ELSE message.offerSize[1])

DecodeQuoteStatusV2Message(bytes) ==
    LET quoteId == ReadBytes(bytes, 20) IN IF ~quoteId.ok THEN Fail ELSE
    LET status == ReadBytes(quoteId.rest, 1) IN IF ~status.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(status.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET numberOfReturnBitfields == ReadUIntBE(reserved1.rest, 1) IN IF ~numberOfReturnBitfields.ok THEN Fail ELSE
    LET quoteStatusV2ReturnBitfield1 == ReadWhen(numberOfReturnBitfields.value >= 1, ReadBytes(numberOfReturnBitfields.rest, 1), numberOfReturnBitfields.rest) IN IF ~quoteStatusV2ReturnBitfield1.ok THEN Fail ELSE
    LET quoteStatusV2ReturnBitfield2 == ReadWhen(numberOfReturnBitfields.value >= 2, ReadUIntLE(quoteStatusV2ReturnBitfield1.rest, 1), quoteStatusV2ReturnBitfield1.rest) IN IF ~quoteStatusV2ReturnBitfield2.ok THEN Fail ELSE
    LET quoteStatusV2ReturnBitfield3 == ReadWhen(numberOfReturnBitfields.value >= 3, ReadUIntLE(quoteStatusV2ReturnBitfield2.rest, 1), quoteStatusV2ReturnBitfield2.rest) IN IF ~quoteStatusV2ReturnBitfield3.ok THEN Fail ELSE
    LET quoteStatusV2ReturnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadBytes(quoteStatusV2ReturnBitfield3.rest, 1), quoteStatusV2ReturnBitfield3.rest) IN IF ~quoteStatusV2ReturnBitfield4.ok THEN Fail ELSE
    LET quoteStatusV2ReturnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadBytes(quoteStatusV2ReturnBitfield4.rest, 1), quoteStatusV2ReturnBitfield4.rest) IN IF ~quoteStatusV2ReturnBitfield5.ok THEN Fail ELSE
    LET quoteStatusV2ReturnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadBytes(quoteStatusV2ReturnBitfield5.rest, 1), quoteStatusV2ReturnBitfield5.rest) IN IF ~quoteStatusV2ReturnBitfield6.ok THEN Fail ELSE
    LET quoteStatusV2ReturnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadUIntLE(quoteStatusV2ReturnBitfield6.rest, 1), quoteStatusV2ReturnBitfield6.rest) IN IF ~quoteStatusV2ReturnBitfield7.ok THEN Fail ELSE
    LET quoteStatusV2ReturnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadBytes(quoteStatusV2ReturnBitfield7.rest, 1), quoteStatusV2ReturnBitfield7.rest) IN IF ~quoteStatusV2ReturnBitfield8.ok THEN Fail ELSE
    LET quoteStatusV2ReturnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadBytes(quoteStatusV2ReturnBitfield8.rest, 1), quoteStatusV2ReturnBitfield8.rest) IN IF ~quoteStatusV2ReturnBitfield9.ok THEN Fail ELSE
    LET quoteStatusV2ReturnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadBytes(quoteStatusV2ReturnBitfield9.rest, 1), quoteStatusV2ReturnBitfield9.rest) IN IF ~quoteStatusV2ReturnBitfield10.ok THEN Fail ELSE
    LET quoteStatusV2ReturnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadBytes(quoteStatusV2ReturnBitfield10.rest, 1), quoteStatusV2ReturnBitfield10.rest) IN IF ~quoteStatusV2ReturnBitfield11.ok THEN Fail ELSE
    LET quoteStatusV2ReturnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadBytes(quoteStatusV2ReturnBitfield11.rest, 1), quoteStatusV2ReturnBitfield11.rest) IN IF ~quoteStatusV2ReturnBitfield12.ok THEN Fail ELSE
    LET quoteStatusV2ReturnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(quoteStatusV2ReturnBitfield12.rest, 1), quoteStatusV2ReturnBitfield12.rest) IN IF ~quoteStatusV2ReturnBitfield13.ok THEN Fail ELSE
    LET quoteStatusV2ReturnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(quoteStatusV2ReturnBitfield13.rest, 1), quoteStatusV2ReturnBitfield13.rest) IN IF ~quoteStatusV2ReturnBitfield14.ok THEN Fail ELSE
    LET symbol == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (quoteStatusV2ReturnBitfield2.value # << >> /\ quoteStatusV2ReturnBitfield2.value[1] % 2 > 0), ReadBytes(quoteStatusV2ReturnBitfield14.rest, 8), quoteStatusV2ReturnBitfield14.rest) IN IF ~symbol.ok THEN Fail ELSE
    LET currency == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (quoteStatusV2ReturnBitfield2.value # << >> /\ (quoteStatusV2ReturnBitfield2.value[1] \div 4) % 2 > 0), ReadBytes(symbol.rest, 3), symbol.rest) IN IF ~currency.ok THEN Fail ELSE
    LET idSource == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (quoteStatusV2ReturnBitfield2.value # << >> /\ (quoteStatusV2ReturnBitfield2.value[1] \div 8) % 2 > 0), ReadBytes(currency.rest, 1), currency.rest) IN IF ~idSource.ok THEN Fail ELSE
    LET securityId == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (quoteStatusV2ReturnBitfield2.value # << >> /\ (quoteStatusV2ReturnBitfield2.value[1] \div 16) % 2 > 0), ReadBytes(idSource.rest, 16), idSource.rest) IN IF ~securityId.ok THEN Fail ELSE
    LET securityExchange == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (quoteStatusV2ReturnBitfield2.value # << >> /\ (quoteStatusV2ReturnBitfield2.value[1] \div 32) % 2 > 0), ReadBytes(securityId.rest, 4), securityId.rest) IN IF ~securityExchange.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (quoteStatusV2ReturnBitfield2.value # << >> /\ (quoteStatusV2ReturnBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(securityExchange.rest, 1), securityExchange.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (quoteStatusV2ReturnBitfield3.value # << >> /\ (quoteStatusV2ReturnBitfield3.value[1] \div 2) % 2 > 0), ReadBytes(capacity.rest, 4), capacity.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET bidPx == ReadWhen(numberOfReturnBitfields.value >= 7 /\ (quoteStatusV2ReturnBitfield7.value # << >> /\ (quoteStatusV2ReturnBitfield7.value[1] \div 16) % 2 > 0), ReadBytes(clearingFirm.rest, 8), clearingFirm.rest) IN IF ~bidPx.ok THEN Fail ELSE
    LET bidSize == ReadWhen(numberOfReturnBitfields.value >= 7 /\ (quoteStatusV2ReturnBitfield7.value # << >> /\ (quoteStatusV2ReturnBitfield7.value[1] \div 16) % 2 > 0), ReadBytes(bidPx.rest, 4), bidPx.rest) IN IF ~bidSize.ok THEN Fail ELSE
    LET offerPx == ReadWhen(numberOfReturnBitfields.value >= 7 /\ (quoteStatusV2ReturnBitfield7.value # << >> /\ (quoteStatusV2ReturnBitfield7.value[1] \div 32) % 2 > 0), ReadBytes(bidSize.rest, 8), bidSize.rest) IN IF ~offerPx.ok THEN Fail ELSE
    LET offerSize == ReadWhen(numberOfReturnBitfields.value >= 7 /\ (quoteStatusV2ReturnBitfield7.value # << >> /\ (quoteStatusV2ReturnBitfield7.value[1] \div 32) % 2 > 0), ReadBytes(offerPx.rest, 4), offerPx.rest) IN IF ~offerSize.ok THEN Fail ELSE
    Ok([ quoteId                       |-> quoteId.value,
         status                        |-> status.value,
         reserved1                     |-> reserved1.value,
         numberOfReturnBitfields       |-> numberOfReturnBitfields.value,
         quoteStatusV2ReturnBitfield1  |-> quoteStatusV2ReturnBitfield1.value,
         quoteStatusV2ReturnBitfield2  |-> quoteStatusV2ReturnBitfield2.value,
         quoteStatusV2ReturnBitfield3  |-> quoteStatusV2ReturnBitfield3.value,
         quoteStatusV2ReturnBitfield4  |-> quoteStatusV2ReturnBitfield4.value,
         quoteStatusV2ReturnBitfield5  |-> quoteStatusV2ReturnBitfield5.value,
         quoteStatusV2ReturnBitfield6  |-> quoteStatusV2ReturnBitfield6.value,
         quoteStatusV2ReturnBitfield7  |-> quoteStatusV2ReturnBitfield7.value,
         quoteStatusV2ReturnBitfield8  |-> quoteStatusV2ReturnBitfield8.value,
         quoteStatusV2ReturnBitfield9  |-> quoteStatusV2ReturnBitfield9.value,
         quoteStatusV2ReturnBitfield10 |-> quoteStatusV2ReturnBitfield10.value,
         quoteStatusV2ReturnBitfield11 |-> quoteStatusV2ReturnBitfield11.value,
         quoteStatusV2ReturnBitfield12 |-> quoteStatusV2ReturnBitfield12.value,
         quoteStatusV2ReturnBitfield13 |-> quoteStatusV2ReturnBitfield13.value,
         quoteStatusV2ReturnBitfield14 |-> quoteStatusV2ReturnBitfield14.value,
         symbol                        |-> symbol.value,
         currency                      |-> currency.value,
         idSource                      |-> idSource.value,
         securityId                    |-> securityId.value,
         securityExchange              |-> securityExchange.value,
         capacity                      |-> capacity.value,
         clearingFirm                  |-> clearingFirm.value,
         bidPx                         |-> bidPx.value,
         bidSize                       |-> bidSize.value,
         offerPx                       |-> offerPx.value,
         offerSize                     |-> offerSize.value ], offerSize.rest)

(* Quote Status V 2 Message with each field marked present by fields before it there exactly where they say *)
SettleQuoteStatusV2Message(message) ==
    LET settled1 == [message EXCEPT !.quoteStatusV2ReturnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.quoteStatusV2ReturnBitfield1 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE message.quoteStatusV2ReturnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.quoteStatusV2ReturnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.quoteStatusV2ReturnBitfield2 = << >> THEN <<0>> ELSE settled1.quoteStatusV2ReturnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.quoteStatusV2ReturnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.quoteStatusV2ReturnBitfield3 = << >> THEN <<0>> ELSE settled2.quoteStatusV2ReturnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.quoteStatusV2ReturnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.quoteStatusV2ReturnBitfield4 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled3.quoteStatusV2ReturnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.quoteStatusV2ReturnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.quoteStatusV2ReturnBitfield5 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled4.quoteStatusV2ReturnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.quoteStatusV2ReturnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.quoteStatusV2ReturnBitfield6 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled5.quoteStatusV2ReturnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.quoteStatusV2ReturnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.quoteStatusV2ReturnBitfield7 = << >> THEN <<0>> ELSE settled6.quoteStatusV2ReturnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.quoteStatusV2ReturnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.quoteStatusV2ReturnBitfield8 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled7.quoteStatusV2ReturnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.quoteStatusV2ReturnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.quoteStatusV2ReturnBitfield9 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled8.quoteStatusV2ReturnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.quoteStatusV2ReturnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.quoteStatusV2ReturnBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.quoteStatusV2ReturnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.quoteStatusV2ReturnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.quoteStatusV2ReturnBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.quoteStatusV2ReturnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.quoteStatusV2ReturnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.quoteStatusV2ReturnBitfield12 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.quoteStatusV2ReturnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.quoteStatusV2ReturnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.quoteStatusV2ReturnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.quoteStatusV2ReturnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.quoteStatusV2ReturnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.quoteStatusV2ReturnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.quoteStatusV2ReturnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.symbol = IF settled14.numberOfReturnBitfields >= 2 /\ (settled14.quoteStatusV2ReturnBitfield2 # << >> /\ settled14.quoteStatusV2ReturnBitfield2[1] % 2 > 0) THEN (IF settled14.symbol = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled14.symbol) ELSE << >>]
        settled16 == [settled15 EXCEPT !.currency = IF settled15.numberOfReturnBitfields >= 2 /\ (settled15.quoteStatusV2ReturnBitfield2 # << >> /\ (settled15.quoteStatusV2ReturnBitfield2[1] \div 4) % 2 > 0) THEN (IF settled15.currency = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled15.currency) ELSE << >>]
        settled17 == [settled16 EXCEPT !.idSource = IF settled16.numberOfReturnBitfields >= 2 /\ (settled16.quoteStatusV2ReturnBitfield2 # << >> /\ (settled16.quoteStatusV2ReturnBitfield2[1] \div 8) % 2 > 0) THEN (IF settled16.idSource = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled16.idSource) ELSE << >>]
        settled18 == [settled17 EXCEPT !.securityId = IF settled17.numberOfReturnBitfields >= 2 /\ (settled17.quoteStatusV2ReturnBitfield2 # << >> /\ (settled17.quoteStatusV2ReturnBitfield2[1] \div 16) % 2 > 0) THEN (IF settled17.securityId = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled17.securityId) ELSE << >>]
        settled19 == [settled18 EXCEPT !.securityExchange = IF settled18.numberOfReturnBitfields >= 2 /\ (settled18.quoteStatusV2ReturnBitfield2 # << >> /\ (settled18.quoteStatusV2ReturnBitfield2[1] \div 32) % 2 > 0) THEN (IF settled18.securityExchange = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled18.securityExchange) ELSE << >>]
        settled20 == [settled19 EXCEPT !.capacity = IF settled19.numberOfReturnBitfields >= 2 /\ (settled19.quoteStatusV2ReturnBitfield2 # << >> /\ (settled19.quoteStatusV2ReturnBitfield2[1] \div 64) % 2 > 0) THEN (IF settled19.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled19.capacity) ELSE << >>]
        settled21 == [settled20 EXCEPT !.clearingFirm = IF settled20.numberOfReturnBitfields >= 3 /\ (settled20.quoteStatusV2ReturnBitfield3 # << >> /\ (settled20.quoteStatusV2ReturnBitfield3[1] \div 2) % 2 > 0) THEN (IF settled20.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled20.clearingFirm) ELSE << >>]
        settled22 == [settled21 EXCEPT !.bidPx = IF settled21.numberOfReturnBitfields >= 7 /\ (settled21.quoteStatusV2ReturnBitfield7 # << >> /\ (settled21.quoteStatusV2ReturnBitfield7[1] \div 16) % 2 > 0) THEN (IF settled21.bidPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled21.bidPx) ELSE << >>]
        settled23 == [settled22 EXCEPT !.bidSize = IF settled22.numberOfReturnBitfields >= 7 /\ (settled22.quoteStatusV2ReturnBitfield7 # << >> /\ (settled22.quoteStatusV2ReturnBitfield7[1] \div 16) % 2 > 0) THEN (IF settled22.bidSize = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled22.bidSize) ELSE << >>]
        settled24 == [settled23 EXCEPT !.offerPx = IF settled23.numberOfReturnBitfields >= 7 /\ (settled23.quoteStatusV2ReturnBitfield7 # << >> /\ (settled23.quoteStatusV2ReturnBitfield7[1] \div 32) % 2 > 0) THEN (IF settled23.offerPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled23.offerPx) ELSE << >>]
        settled25 == [settled24 EXCEPT !.offerSize = IF settled24.numberOfReturnBitfields >= 7 /\ (settled24.quoteStatusV2ReturnBitfield7 # << >> /\ (settled24.quoteStatusV2ReturnBitfield7[1] \div 32) % 2 > 0) THEN (IF settled24.offerSize = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled24.offerSize) ELSE << >>]
    IN  settled25

ZeroQuoteStatusV2Message ==
    SettleQuoteStatusV2Message([ quoteId                       |-> [i \in 1 .. 20 |-> 0],
                                 status                        |-> [i \in 1 .. 1 |-> 0],
                                 reserved1                     |-> [i \in 1 .. 1 |-> 0],
                                 numberOfReturnBitfields       |-> 0,
                                 quoteStatusV2ReturnBitfield1  |-> << >>,
                                 quoteStatusV2ReturnBitfield2  |-> << >>,
                                 quoteStatusV2ReturnBitfield3  |-> << >>,
                                 quoteStatusV2ReturnBitfield4  |-> << >>,
                                 quoteStatusV2ReturnBitfield5  |-> << >>,
                                 quoteStatusV2ReturnBitfield6  |-> << >>,
                                 quoteStatusV2ReturnBitfield7  |-> << >>,
                                 quoteStatusV2ReturnBitfield8  |-> << >>,
                                 quoteStatusV2ReturnBitfield9  |-> << >>,
                                 quoteStatusV2ReturnBitfield10 |-> << >>,
                                 quoteStatusV2ReturnBitfield11 |-> << >>,
                                 quoteStatusV2ReturnBitfield12 |-> << >>,
                                 quoteStatusV2ReturnBitfield13 |-> << >>,
                                 quoteStatusV2ReturnBitfield14 |-> << >>,
                                 symbol                        |-> << >>,
                                 currency                      |-> << >>,
                                 idSource                      |-> << >>,
                                 securityId                    |-> << >>,
                                 securityExchange              |-> << >>,
                                 capacity                      |-> << >>,
                                 clearingFirm                  |-> << >>,
                                 bidPx                         |-> << >>,
                                 bidSize                       |-> << >>,
                                 offerPx                       |-> << >>,
                                 offerSize                     |-> << >> ])

(* Quote Status V 2 Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteStatusV2Message ==
    { ZeroQuoteStatusV2Message }
        \cup { SettleQuoteStatusV2Message([ZeroQuoteStatusV2Message EXCEPT !.quoteId = one]) : one \in Sample(20) }
        \cup { SettleQuoteStatusV2Message([ZeroQuoteStatusV2Message EXCEPT !.status = one]) : one \in Sample(1) }
        \cup { SettleQuoteStatusV2Message([ZeroQuoteStatusV2Message EXCEPT !.reserved1 = one]) : one \in Sample(1) }
        \cup { SettleQuoteStatusV2Message([ZeroQuoteStatusV2Message EXCEPT !.numberOfReturnBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleQuoteStatusV2Message([ZeroQuoteStatusV2Message EXCEPT !.numberOfReturnBitfields = 1, !.quoteStatusV2ReturnBitfield1 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleQuoteStatusV2Message([ZeroQuoteStatusV2Message EXCEPT !.numberOfReturnBitfields = 2, !.quoteStatusV2ReturnBitfield2 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleQuoteStatusV2Message([ZeroQuoteStatusV2Message EXCEPT !.numberOfReturnBitfields = 3, !.quoteStatusV2ReturnBitfield3 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleQuoteStatusV2Message([ZeroQuoteStatusV2Message EXCEPT !.numberOfReturnBitfields = 4, !.quoteStatusV2ReturnBitfield4 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleQuoteStatusV2Message([ZeroQuoteStatusV2Message EXCEPT !.numberOfReturnBitfields = 5, !.quoteStatusV2ReturnBitfield5 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleQuoteStatusV2Message([ZeroQuoteStatusV2Message EXCEPT !.numberOfReturnBitfields = 6, !.quoteStatusV2ReturnBitfield6 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleQuoteStatusV2Message([ZeroQuoteStatusV2Message EXCEPT !.numberOfReturnBitfields = 7, !.quoteStatusV2ReturnBitfield7 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleQuoteStatusV2Message([ZeroQuoteStatusV2Message EXCEPT !.numberOfReturnBitfields = 8, !.quoteStatusV2ReturnBitfield8 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleQuoteStatusV2Message([ZeroQuoteStatusV2Message EXCEPT !.numberOfReturnBitfields = 9, !.quoteStatusV2ReturnBitfield9 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleQuoteStatusV2Message([ZeroQuoteStatusV2Message EXCEPT !.numberOfReturnBitfields = 10, !.quoteStatusV2ReturnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleQuoteStatusV2Message([ZeroQuoteStatusV2Message EXCEPT !.numberOfReturnBitfields = 11, !.quoteStatusV2ReturnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleQuoteStatusV2Message([ZeroQuoteStatusV2Message EXCEPT !.numberOfReturnBitfields = 12, !.quoteStatusV2ReturnBitfield12 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleQuoteStatusV2Message([ZeroQuoteStatusV2Message EXCEPT !.numberOfReturnBitfields = 13, !.quoteStatusV2ReturnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleQuoteStatusV2Message([ZeroQuoteStatusV2Message EXCEPT !.numberOfReturnBitfields = 14, !.quoteStatusV2ReturnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleQuoteStatusV2Message([ZeroQuoteStatusV2Message EXCEPT !.numberOfReturnBitfields = 2, !.quoteStatusV2ReturnBitfield2 = <<1>>, !.symbol = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleQuoteStatusV2Message([ZeroQuoteStatusV2Message EXCEPT !.numberOfReturnBitfields = 2, !.quoteStatusV2ReturnBitfield2 = <<4>>, !.currency = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleQuoteStatusV2Message([ZeroQuoteStatusV2Message EXCEPT !.numberOfReturnBitfields = 2, !.quoteStatusV2ReturnBitfield2 = <<8>>, !.idSource = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleQuoteStatusV2Message([ZeroQuoteStatusV2Message EXCEPT !.numberOfReturnBitfields = 2, !.quoteStatusV2ReturnBitfield2 = <<16>>, !.securityId = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleQuoteStatusV2Message([ZeroQuoteStatusV2Message EXCEPT !.numberOfReturnBitfields = 2, !.quoteStatusV2ReturnBitfield2 = <<32>>, !.securityExchange = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleQuoteStatusV2Message([ZeroQuoteStatusV2Message EXCEPT !.numberOfReturnBitfields = 2, !.quoteStatusV2ReturnBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleQuoteStatusV2Message([ZeroQuoteStatusV2Message EXCEPT !.numberOfReturnBitfields = 3, !.quoteStatusV2ReturnBitfield3 = <<2>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleQuoteStatusV2Message([ZeroQuoteStatusV2Message EXCEPT !.numberOfReturnBitfields = 7, !.quoteStatusV2ReturnBitfield7 = <<16>>, !.bidPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleQuoteStatusV2Message([ZeroQuoteStatusV2Message EXCEPT !.numberOfReturnBitfields = 7, !.quoteStatusV2ReturnBitfield7 = <<16>>, !.bidSize = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleQuoteStatusV2Message([ZeroQuoteStatusV2Message EXCEPT !.numberOfReturnBitfields = 7, !.quoteStatusV2ReturnBitfield7 = <<32>>, !.offerPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleQuoteStatusV2Message([ZeroQuoteStatusV2Message EXCEPT !.numberOfReturnBitfields = 7, !.quoteStatusV2ReturnBitfield7 = <<32>>, !.offerSize = one]) : one \in { <<held>> : held \in Sample(4) } }

(***************************************************************************)
(* Quote Reject V 2 Message                                                *)
(***************************************************************************)

QuoteRejectV2Message ==
    [ quoteId                       : Sample(20),
      reason                        : Sample(1),
      text                          : Sample(60),
      reserved1                     : Sample(1),
      numberOfReturnBitfields       : 0 .. 255,
      quoteRejectV2ReturnBitfield1  : { << >> } \cup { <<held>> : held \in Sample(1) },
      quoteRejectV2ReturnBitfield2  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      quoteRejectV2ReturnBitfield3  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      quoteRejectV2ReturnBitfield4  : { << >> } \cup { <<held>> : held \in Sample(1) },
      quoteRejectV2ReturnBitfield5  : { << >> } \cup { <<held>> : held \in Sample(1) },
      quoteRejectV2ReturnBitfield6  : { << >> } \cup { <<held>> : held \in Sample(1) },
      quoteRejectV2ReturnBitfield7  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      quoteRejectV2ReturnBitfield8  : { << >> } \cup { <<held>> : held \in Sample(1) },
      quoteRejectV2ReturnBitfield9  : { << >> } \cup { <<held>> : held \in Sample(1) },
      quoteRejectV2ReturnBitfield10 : { << >> } \cup { <<held>> : held \in Sample(1) },
      quoteRejectV2ReturnBitfield11 : { << >> } \cup { <<held>> : held \in Sample(1) },
      quoteRejectV2ReturnBitfield12 : { << >> } \cup { <<held>> : held \in Sample(1) },
      quoteRejectV2ReturnBitfield13 : { << >> } \cup { <<held>> : held \in Sample(1) },
      quoteRejectV2ReturnBitfield14 : { << >> } \cup { <<held>> : held \in Sample(1) },
      symbol                        : { << >> } \cup { <<held>> : held \in Sample(8) },
      currency                      : { << >> } \cup { <<held>> : held \in Sample(3) },
      idSource                      : { << >> } \cup { <<held>> : held \in Sample(1) },
      securityId                    : { << >> } \cup { <<held>> : held \in Sample(16) },
      securityExchange              : { << >> } \cup { <<held>> : held \in Sample(4) },
      capacity                      : { << >> } \cup { <<held>> : held \in Sample(1) },
      clearingFirm                  : { << >> } \cup { <<held>> : held \in Sample(4) },
      bidPx                         : { << >> } \cup { <<held>> : held \in Sample(8) },
      bidSize                       : { << >> } \cup { <<held>> : held \in Sample(4) },
      offerPx                       : { << >> } \cup { <<held>> : held \in Sample(8) },
      offerSize                     : { << >> } \cup { <<held>> : held \in Sample(4) } ]

EncodeQuoteRejectV2Message(message) ==
    message.quoteId
        \o message.reason
        \o message.text
        \o message.reserved1
        \o EncodeUIntBE(message.numberOfReturnBitfields, 1)
        \o (IF message.quoteRejectV2ReturnBitfield1 = << >> THEN << >> ELSE message.quoteRejectV2ReturnBitfield1[1])
        \o (IF message.quoteRejectV2ReturnBitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.quoteRejectV2ReturnBitfield2[1], 1))
        \o (IF message.quoteRejectV2ReturnBitfield3 = << >> THEN << >> ELSE EncodeUIntLE(message.quoteRejectV2ReturnBitfield3[1], 1))
        \o (IF message.quoteRejectV2ReturnBitfield4 = << >> THEN << >> ELSE message.quoteRejectV2ReturnBitfield4[1])
        \o (IF message.quoteRejectV2ReturnBitfield5 = << >> THEN << >> ELSE message.quoteRejectV2ReturnBitfield5[1])
        \o (IF message.quoteRejectV2ReturnBitfield6 = << >> THEN << >> ELSE message.quoteRejectV2ReturnBitfield6[1])
        \o (IF message.quoteRejectV2ReturnBitfield7 = << >> THEN << >> ELSE EncodeUIntLE(message.quoteRejectV2ReturnBitfield7[1], 1))
        \o (IF message.quoteRejectV2ReturnBitfield8 = << >> THEN << >> ELSE message.quoteRejectV2ReturnBitfield8[1])
        \o (IF message.quoteRejectV2ReturnBitfield9 = << >> THEN << >> ELSE message.quoteRejectV2ReturnBitfield9[1])
        \o (IF message.quoteRejectV2ReturnBitfield10 = << >> THEN << >> ELSE message.quoteRejectV2ReturnBitfield10[1])
        \o (IF message.quoteRejectV2ReturnBitfield11 = << >> THEN << >> ELSE message.quoteRejectV2ReturnBitfield11[1])
        \o (IF message.quoteRejectV2ReturnBitfield12 = << >> THEN << >> ELSE message.quoteRejectV2ReturnBitfield12[1])
        \o (IF message.quoteRejectV2ReturnBitfield13 = << >> THEN << >> ELSE message.quoteRejectV2ReturnBitfield13[1])
        \o (IF message.quoteRejectV2ReturnBitfield14 = << >> THEN << >> ELSE message.quoteRejectV2ReturnBitfield14[1])
        \o (IF message.symbol = << >> THEN << >> ELSE message.symbol[1])
        \o (IF message.currency = << >> THEN << >> ELSE message.currency[1])
        \o (IF message.idSource = << >> THEN << >> ELSE message.idSource[1])
        \o (IF message.securityId = << >> THEN << >> ELSE message.securityId[1])
        \o (IF message.securityExchange = << >> THEN << >> ELSE message.securityExchange[1])
        \o (IF message.capacity = << >> THEN << >> ELSE message.capacity[1])
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])
        \o (IF message.bidPx = << >> THEN << >> ELSE message.bidPx[1])
        \o (IF message.bidSize = << >> THEN << >> ELSE message.bidSize[1])
        \o (IF message.offerPx = << >> THEN << >> ELSE message.offerPx[1])
        \o (IF message.offerSize = << >> THEN << >> ELSE message.offerSize[1])

DecodeQuoteRejectV2Message(bytes) ==
    LET quoteId == ReadBytes(bytes, 20) IN IF ~quoteId.ok THEN Fail ELSE
    LET reason == ReadBytes(quoteId.rest, 1) IN IF ~reason.ok THEN Fail ELSE
    LET text == ReadBytes(reason.rest, 60) IN IF ~text.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(text.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET numberOfReturnBitfields == ReadUIntBE(reserved1.rest, 1) IN IF ~numberOfReturnBitfields.ok THEN Fail ELSE
    LET quoteRejectV2ReturnBitfield1 == ReadWhen(numberOfReturnBitfields.value >= 1, ReadBytes(numberOfReturnBitfields.rest, 1), numberOfReturnBitfields.rest) IN IF ~quoteRejectV2ReturnBitfield1.ok THEN Fail ELSE
    LET quoteRejectV2ReturnBitfield2 == ReadWhen(numberOfReturnBitfields.value >= 2, ReadUIntLE(quoteRejectV2ReturnBitfield1.rest, 1), quoteRejectV2ReturnBitfield1.rest) IN IF ~quoteRejectV2ReturnBitfield2.ok THEN Fail ELSE
    LET quoteRejectV2ReturnBitfield3 == ReadWhen(numberOfReturnBitfields.value >= 3, ReadUIntLE(quoteRejectV2ReturnBitfield2.rest, 1), quoteRejectV2ReturnBitfield2.rest) IN IF ~quoteRejectV2ReturnBitfield3.ok THEN Fail ELSE
    LET quoteRejectV2ReturnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadBytes(quoteRejectV2ReturnBitfield3.rest, 1), quoteRejectV2ReturnBitfield3.rest) IN IF ~quoteRejectV2ReturnBitfield4.ok THEN Fail ELSE
    LET quoteRejectV2ReturnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadBytes(quoteRejectV2ReturnBitfield4.rest, 1), quoteRejectV2ReturnBitfield4.rest) IN IF ~quoteRejectV2ReturnBitfield5.ok THEN Fail ELSE
    LET quoteRejectV2ReturnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadBytes(quoteRejectV2ReturnBitfield5.rest, 1), quoteRejectV2ReturnBitfield5.rest) IN IF ~quoteRejectV2ReturnBitfield6.ok THEN Fail ELSE
    LET quoteRejectV2ReturnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadUIntLE(quoteRejectV2ReturnBitfield6.rest, 1), quoteRejectV2ReturnBitfield6.rest) IN IF ~quoteRejectV2ReturnBitfield7.ok THEN Fail ELSE
    LET quoteRejectV2ReturnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadBytes(quoteRejectV2ReturnBitfield7.rest, 1), quoteRejectV2ReturnBitfield7.rest) IN IF ~quoteRejectV2ReturnBitfield8.ok THEN Fail ELSE
    LET quoteRejectV2ReturnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadBytes(quoteRejectV2ReturnBitfield8.rest, 1), quoteRejectV2ReturnBitfield8.rest) IN IF ~quoteRejectV2ReturnBitfield9.ok THEN Fail ELSE
    LET quoteRejectV2ReturnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadBytes(quoteRejectV2ReturnBitfield9.rest, 1), quoteRejectV2ReturnBitfield9.rest) IN IF ~quoteRejectV2ReturnBitfield10.ok THEN Fail ELSE
    LET quoteRejectV2ReturnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadBytes(quoteRejectV2ReturnBitfield10.rest, 1), quoteRejectV2ReturnBitfield10.rest) IN IF ~quoteRejectV2ReturnBitfield11.ok THEN Fail ELSE
    LET quoteRejectV2ReturnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadBytes(quoteRejectV2ReturnBitfield11.rest, 1), quoteRejectV2ReturnBitfield11.rest) IN IF ~quoteRejectV2ReturnBitfield12.ok THEN Fail ELSE
    LET quoteRejectV2ReturnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(quoteRejectV2ReturnBitfield12.rest, 1), quoteRejectV2ReturnBitfield12.rest) IN IF ~quoteRejectV2ReturnBitfield13.ok THEN Fail ELSE
    LET quoteRejectV2ReturnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(quoteRejectV2ReturnBitfield13.rest, 1), quoteRejectV2ReturnBitfield13.rest) IN IF ~quoteRejectV2ReturnBitfield14.ok THEN Fail ELSE
    LET symbol == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (quoteRejectV2ReturnBitfield2.value # << >> /\ quoteRejectV2ReturnBitfield2.value[1] % 2 > 0), ReadBytes(quoteRejectV2ReturnBitfield14.rest, 8), quoteRejectV2ReturnBitfield14.rest) IN IF ~symbol.ok THEN Fail ELSE
    LET currency == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (quoteRejectV2ReturnBitfield2.value # << >> /\ (quoteRejectV2ReturnBitfield2.value[1] \div 4) % 2 > 0), ReadBytes(symbol.rest, 3), symbol.rest) IN IF ~currency.ok THEN Fail ELSE
    LET idSource == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (quoteRejectV2ReturnBitfield2.value # << >> /\ (quoteRejectV2ReturnBitfield2.value[1] \div 8) % 2 > 0), ReadBytes(currency.rest, 1), currency.rest) IN IF ~idSource.ok THEN Fail ELSE
    LET securityId == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (quoteRejectV2ReturnBitfield2.value # << >> /\ (quoteRejectV2ReturnBitfield2.value[1] \div 16) % 2 > 0), ReadBytes(idSource.rest, 16), idSource.rest) IN IF ~securityId.ok THEN Fail ELSE
    LET securityExchange == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (quoteRejectV2ReturnBitfield2.value # << >> /\ (quoteRejectV2ReturnBitfield2.value[1] \div 32) % 2 > 0), ReadBytes(securityId.rest, 4), securityId.rest) IN IF ~securityExchange.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (quoteRejectV2ReturnBitfield2.value # << >> /\ (quoteRejectV2ReturnBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(securityExchange.rest, 1), securityExchange.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (quoteRejectV2ReturnBitfield3.value # << >> /\ (quoteRejectV2ReturnBitfield3.value[1] \div 2) % 2 > 0), ReadBytes(capacity.rest, 4), capacity.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET bidPx == ReadWhen(numberOfReturnBitfields.value >= 7 /\ (quoteRejectV2ReturnBitfield7.value # << >> /\ (quoteRejectV2ReturnBitfield7.value[1] \div 16) % 2 > 0), ReadBytes(clearingFirm.rest, 8), clearingFirm.rest) IN IF ~bidPx.ok THEN Fail ELSE
    LET bidSize == ReadWhen(numberOfReturnBitfields.value >= 7 /\ (quoteRejectV2ReturnBitfield7.value # << >> /\ (quoteRejectV2ReturnBitfield7.value[1] \div 16) % 2 > 0), ReadBytes(bidPx.rest, 4), bidPx.rest) IN IF ~bidSize.ok THEN Fail ELSE
    LET offerPx == ReadWhen(numberOfReturnBitfields.value >= 7 /\ (quoteRejectV2ReturnBitfield7.value # << >> /\ (quoteRejectV2ReturnBitfield7.value[1] \div 32) % 2 > 0), ReadBytes(bidSize.rest, 8), bidSize.rest) IN IF ~offerPx.ok THEN Fail ELSE
    LET offerSize == ReadWhen(numberOfReturnBitfields.value >= 7 /\ (quoteRejectV2ReturnBitfield7.value # << >> /\ (quoteRejectV2ReturnBitfield7.value[1] \div 32) % 2 > 0), ReadBytes(offerPx.rest, 4), offerPx.rest) IN IF ~offerSize.ok THEN Fail ELSE
    Ok([ quoteId                       |-> quoteId.value,
         reason                        |-> reason.value,
         text                          |-> text.value,
         reserved1                     |-> reserved1.value,
         numberOfReturnBitfields       |-> numberOfReturnBitfields.value,
         quoteRejectV2ReturnBitfield1  |-> quoteRejectV2ReturnBitfield1.value,
         quoteRejectV2ReturnBitfield2  |-> quoteRejectV2ReturnBitfield2.value,
         quoteRejectV2ReturnBitfield3  |-> quoteRejectV2ReturnBitfield3.value,
         quoteRejectV2ReturnBitfield4  |-> quoteRejectV2ReturnBitfield4.value,
         quoteRejectV2ReturnBitfield5  |-> quoteRejectV2ReturnBitfield5.value,
         quoteRejectV2ReturnBitfield6  |-> quoteRejectV2ReturnBitfield6.value,
         quoteRejectV2ReturnBitfield7  |-> quoteRejectV2ReturnBitfield7.value,
         quoteRejectV2ReturnBitfield8  |-> quoteRejectV2ReturnBitfield8.value,
         quoteRejectV2ReturnBitfield9  |-> quoteRejectV2ReturnBitfield9.value,
         quoteRejectV2ReturnBitfield10 |-> quoteRejectV2ReturnBitfield10.value,
         quoteRejectV2ReturnBitfield11 |-> quoteRejectV2ReturnBitfield11.value,
         quoteRejectV2ReturnBitfield12 |-> quoteRejectV2ReturnBitfield12.value,
         quoteRejectV2ReturnBitfield13 |-> quoteRejectV2ReturnBitfield13.value,
         quoteRejectV2ReturnBitfield14 |-> quoteRejectV2ReturnBitfield14.value,
         symbol                        |-> symbol.value,
         currency                      |-> currency.value,
         idSource                      |-> idSource.value,
         securityId                    |-> securityId.value,
         securityExchange              |-> securityExchange.value,
         capacity                      |-> capacity.value,
         clearingFirm                  |-> clearingFirm.value,
         bidPx                         |-> bidPx.value,
         bidSize                       |-> bidSize.value,
         offerPx                       |-> offerPx.value,
         offerSize                     |-> offerSize.value ], offerSize.rest)

(* Quote Reject V 2 Message with each field marked present by fields before it there exactly where they say *)
SettleQuoteRejectV2Message(message) ==
    LET settled1 == [message EXCEPT !.quoteRejectV2ReturnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.quoteRejectV2ReturnBitfield1 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE message.quoteRejectV2ReturnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.quoteRejectV2ReturnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.quoteRejectV2ReturnBitfield2 = << >> THEN <<0>> ELSE settled1.quoteRejectV2ReturnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.quoteRejectV2ReturnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.quoteRejectV2ReturnBitfield3 = << >> THEN <<0>> ELSE settled2.quoteRejectV2ReturnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.quoteRejectV2ReturnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.quoteRejectV2ReturnBitfield4 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled3.quoteRejectV2ReturnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.quoteRejectV2ReturnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.quoteRejectV2ReturnBitfield5 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled4.quoteRejectV2ReturnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.quoteRejectV2ReturnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.quoteRejectV2ReturnBitfield6 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled5.quoteRejectV2ReturnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.quoteRejectV2ReturnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.quoteRejectV2ReturnBitfield7 = << >> THEN <<0>> ELSE settled6.quoteRejectV2ReturnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.quoteRejectV2ReturnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.quoteRejectV2ReturnBitfield8 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled7.quoteRejectV2ReturnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.quoteRejectV2ReturnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.quoteRejectV2ReturnBitfield9 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled8.quoteRejectV2ReturnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.quoteRejectV2ReturnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.quoteRejectV2ReturnBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.quoteRejectV2ReturnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.quoteRejectV2ReturnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.quoteRejectV2ReturnBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.quoteRejectV2ReturnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.quoteRejectV2ReturnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.quoteRejectV2ReturnBitfield12 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.quoteRejectV2ReturnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.quoteRejectV2ReturnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.quoteRejectV2ReturnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.quoteRejectV2ReturnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.quoteRejectV2ReturnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.quoteRejectV2ReturnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.quoteRejectV2ReturnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.symbol = IF settled14.numberOfReturnBitfields >= 2 /\ (settled14.quoteRejectV2ReturnBitfield2 # << >> /\ settled14.quoteRejectV2ReturnBitfield2[1] % 2 > 0) THEN (IF settled14.symbol = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled14.symbol) ELSE << >>]
        settled16 == [settled15 EXCEPT !.currency = IF settled15.numberOfReturnBitfields >= 2 /\ (settled15.quoteRejectV2ReturnBitfield2 # << >> /\ (settled15.quoteRejectV2ReturnBitfield2[1] \div 4) % 2 > 0) THEN (IF settled15.currency = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled15.currency) ELSE << >>]
        settled17 == [settled16 EXCEPT !.idSource = IF settled16.numberOfReturnBitfields >= 2 /\ (settled16.quoteRejectV2ReturnBitfield2 # << >> /\ (settled16.quoteRejectV2ReturnBitfield2[1] \div 8) % 2 > 0) THEN (IF settled16.idSource = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled16.idSource) ELSE << >>]
        settled18 == [settled17 EXCEPT !.securityId = IF settled17.numberOfReturnBitfields >= 2 /\ (settled17.quoteRejectV2ReturnBitfield2 # << >> /\ (settled17.quoteRejectV2ReturnBitfield2[1] \div 16) % 2 > 0) THEN (IF settled17.securityId = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled17.securityId) ELSE << >>]
        settled19 == [settled18 EXCEPT !.securityExchange = IF settled18.numberOfReturnBitfields >= 2 /\ (settled18.quoteRejectV2ReturnBitfield2 # << >> /\ (settled18.quoteRejectV2ReturnBitfield2[1] \div 32) % 2 > 0) THEN (IF settled18.securityExchange = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled18.securityExchange) ELSE << >>]
        settled20 == [settled19 EXCEPT !.capacity = IF settled19.numberOfReturnBitfields >= 2 /\ (settled19.quoteRejectV2ReturnBitfield2 # << >> /\ (settled19.quoteRejectV2ReturnBitfield2[1] \div 64) % 2 > 0) THEN (IF settled19.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled19.capacity) ELSE << >>]
        settled21 == [settled20 EXCEPT !.clearingFirm = IF settled20.numberOfReturnBitfields >= 3 /\ (settled20.quoteRejectV2ReturnBitfield3 # << >> /\ (settled20.quoteRejectV2ReturnBitfield3[1] \div 2) % 2 > 0) THEN (IF settled20.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled20.clearingFirm) ELSE << >>]
        settled22 == [settled21 EXCEPT !.bidPx = IF settled21.numberOfReturnBitfields >= 7 /\ (settled21.quoteRejectV2ReturnBitfield7 # << >> /\ (settled21.quoteRejectV2ReturnBitfield7[1] \div 16) % 2 > 0) THEN (IF settled21.bidPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled21.bidPx) ELSE << >>]
        settled23 == [settled22 EXCEPT !.bidSize = IF settled22.numberOfReturnBitfields >= 7 /\ (settled22.quoteRejectV2ReturnBitfield7 # << >> /\ (settled22.quoteRejectV2ReturnBitfield7[1] \div 16) % 2 > 0) THEN (IF settled22.bidSize = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled22.bidSize) ELSE << >>]
        settled24 == [settled23 EXCEPT !.offerPx = IF settled23.numberOfReturnBitfields >= 7 /\ (settled23.quoteRejectV2ReturnBitfield7 # << >> /\ (settled23.quoteRejectV2ReturnBitfield7[1] \div 32) % 2 > 0) THEN (IF settled23.offerPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled23.offerPx) ELSE << >>]
        settled25 == [settled24 EXCEPT !.offerSize = IF settled24.numberOfReturnBitfields >= 7 /\ (settled24.quoteRejectV2ReturnBitfield7 # << >> /\ (settled24.quoteRejectV2ReturnBitfield7[1] \div 32) % 2 > 0) THEN (IF settled24.offerSize = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled24.offerSize) ELSE << >>]
    IN  settled25

ZeroQuoteRejectV2Message ==
    SettleQuoteRejectV2Message([ quoteId                       |-> [i \in 1 .. 20 |-> 0],
                                 reason                        |-> [i \in 1 .. 1 |-> 0],
                                 text                          |-> [i \in 1 .. 60 |-> 0],
                                 reserved1                     |-> [i \in 1 .. 1 |-> 0],
                                 numberOfReturnBitfields       |-> 0,
                                 quoteRejectV2ReturnBitfield1  |-> << >>,
                                 quoteRejectV2ReturnBitfield2  |-> << >>,
                                 quoteRejectV2ReturnBitfield3  |-> << >>,
                                 quoteRejectV2ReturnBitfield4  |-> << >>,
                                 quoteRejectV2ReturnBitfield5  |-> << >>,
                                 quoteRejectV2ReturnBitfield6  |-> << >>,
                                 quoteRejectV2ReturnBitfield7  |-> << >>,
                                 quoteRejectV2ReturnBitfield8  |-> << >>,
                                 quoteRejectV2ReturnBitfield9  |-> << >>,
                                 quoteRejectV2ReturnBitfield10 |-> << >>,
                                 quoteRejectV2ReturnBitfield11 |-> << >>,
                                 quoteRejectV2ReturnBitfield12 |-> << >>,
                                 quoteRejectV2ReturnBitfield13 |-> << >>,
                                 quoteRejectV2ReturnBitfield14 |-> << >>,
                                 symbol                        |-> << >>,
                                 currency                      |-> << >>,
                                 idSource                      |-> << >>,
                                 securityId                    |-> << >>,
                                 securityExchange              |-> << >>,
                                 capacity                      |-> << >>,
                                 clearingFirm                  |-> << >>,
                                 bidPx                         |-> << >>,
                                 bidSize                       |-> << >>,
                                 offerPx                       |-> << >>,
                                 offerSize                     |-> << >> ])

(* Quote Reject V 2 Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteRejectV2Message ==
    { ZeroQuoteRejectV2Message }
        \cup { SettleQuoteRejectV2Message([ZeroQuoteRejectV2Message EXCEPT !.quoteId = one]) : one \in Sample(20) }
        \cup { SettleQuoteRejectV2Message([ZeroQuoteRejectV2Message EXCEPT !.reason = one]) : one \in Sample(1) }
        \cup { SettleQuoteRejectV2Message([ZeroQuoteRejectV2Message EXCEPT !.text = one]) : one \in Sample(60) }
        \cup { SettleQuoteRejectV2Message([ZeroQuoteRejectV2Message EXCEPT !.reserved1 = one]) : one \in Sample(1) }
        \cup { SettleQuoteRejectV2Message([ZeroQuoteRejectV2Message EXCEPT !.numberOfReturnBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleQuoteRejectV2Message([ZeroQuoteRejectV2Message EXCEPT !.numberOfReturnBitfields = 1, !.quoteRejectV2ReturnBitfield1 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleQuoteRejectV2Message([ZeroQuoteRejectV2Message EXCEPT !.numberOfReturnBitfields = 2, !.quoteRejectV2ReturnBitfield2 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleQuoteRejectV2Message([ZeroQuoteRejectV2Message EXCEPT !.numberOfReturnBitfields = 3, !.quoteRejectV2ReturnBitfield3 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleQuoteRejectV2Message([ZeroQuoteRejectV2Message EXCEPT !.numberOfReturnBitfields = 4, !.quoteRejectV2ReturnBitfield4 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleQuoteRejectV2Message([ZeroQuoteRejectV2Message EXCEPT !.numberOfReturnBitfields = 5, !.quoteRejectV2ReturnBitfield5 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleQuoteRejectV2Message([ZeroQuoteRejectV2Message EXCEPT !.numberOfReturnBitfields = 6, !.quoteRejectV2ReturnBitfield6 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleQuoteRejectV2Message([ZeroQuoteRejectV2Message EXCEPT !.numberOfReturnBitfields = 7, !.quoteRejectV2ReturnBitfield7 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleQuoteRejectV2Message([ZeroQuoteRejectV2Message EXCEPT !.numberOfReturnBitfields = 8, !.quoteRejectV2ReturnBitfield8 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleQuoteRejectV2Message([ZeroQuoteRejectV2Message EXCEPT !.numberOfReturnBitfields = 9, !.quoteRejectV2ReturnBitfield9 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleQuoteRejectV2Message([ZeroQuoteRejectV2Message EXCEPT !.numberOfReturnBitfields = 10, !.quoteRejectV2ReturnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleQuoteRejectV2Message([ZeroQuoteRejectV2Message EXCEPT !.numberOfReturnBitfields = 11, !.quoteRejectV2ReturnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleQuoteRejectV2Message([ZeroQuoteRejectV2Message EXCEPT !.numberOfReturnBitfields = 12, !.quoteRejectV2ReturnBitfield12 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleQuoteRejectV2Message([ZeroQuoteRejectV2Message EXCEPT !.numberOfReturnBitfields = 13, !.quoteRejectV2ReturnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleQuoteRejectV2Message([ZeroQuoteRejectV2Message EXCEPT !.numberOfReturnBitfields = 14, !.quoteRejectV2ReturnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleQuoteRejectV2Message([ZeroQuoteRejectV2Message EXCEPT !.numberOfReturnBitfields = 2, !.quoteRejectV2ReturnBitfield2 = <<1>>, !.symbol = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleQuoteRejectV2Message([ZeroQuoteRejectV2Message EXCEPT !.numberOfReturnBitfields = 2, !.quoteRejectV2ReturnBitfield2 = <<4>>, !.currency = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleQuoteRejectV2Message([ZeroQuoteRejectV2Message EXCEPT !.numberOfReturnBitfields = 2, !.quoteRejectV2ReturnBitfield2 = <<8>>, !.idSource = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleQuoteRejectV2Message([ZeroQuoteRejectV2Message EXCEPT !.numberOfReturnBitfields = 2, !.quoteRejectV2ReturnBitfield2 = <<16>>, !.securityId = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleQuoteRejectV2Message([ZeroQuoteRejectV2Message EXCEPT !.numberOfReturnBitfields = 2, !.quoteRejectV2ReturnBitfield2 = <<32>>, !.securityExchange = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleQuoteRejectV2Message([ZeroQuoteRejectV2Message EXCEPT !.numberOfReturnBitfields = 2, !.quoteRejectV2ReturnBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleQuoteRejectV2Message([ZeroQuoteRejectV2Message EXCEPT !.numberOfReturnBitfields = 3, !.quoteRejectV2ReturnBitfield3 = <<2>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleQuoteRejectV2Message([ZeroQuoteRejectV2Message EXCEPT !.numberOfReturnBitfields = 7, !.quoteRejectV2ReturnBitfield7 = <<16>>, !.bidPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleQuoteRejectV2Message([ZeroQuoteRejectV2Message EXCEPT !.numberOfReturnBitfields = 7, !.quoteRejectV2ReturnBitfield7 = <<16>>, !.bidSize = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleQuoteRejectV2Message([ZeroQuoteRejectV2Message EXCEPT !.numberOfReturnBitfields = 7, !.quoteRejectV2ReturnBitfield7 = <<32>>, !.offerPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleQuoteRejectV2Message([ZeroQuoteRejectV2Message EXCEPT !.numberOfReturnBitfields = 7, !.quoteRejectV2ReturnBitfield7 = <<32>>, !.offerSize = one]) : one \in { <<held>> : held \in Sample(4) } }

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
TradeCaptureReportV2MessageCode == 60  \* 0x3c
QuoteV2MessageCode == 61  \* 0x3d
QuoteCancelV2MessageCode == 62  \* 0x3e
TradeCaptureReportAcknowledgmentV2MessageCode == 48  \* 0x30
TradeCaptureReportRejectV2MessageCode == 49  \* 0x31
TradeCaptureConfirmV2MessageCode == 50  \* 0x32
TradeCaptureReportDeclineV2MessageCode == 51  \* 0x33
QuoteStatusV2MessageCode == 63  \* 0x3f
QuoteRejectV2MessageCode == 64  \* 0x40

Message ==
    [ tag : {LoginRequestV2MessageCode}, body : LoginRequestV2Message ]
        \cup [ tag : {LogoutRequestMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ClientHeartbeatMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {LoginResponseV2MessageCode}, body : LoginResponseV2Message ]
        \cup [ tag : {LogoutMessageCode}, body : LogoutMessage ]
        \cup [ tag : {ServerHeartbeatMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ReplayCompleteMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {TradeCaptureReportV2MessageCode}, body : TradeCaptureReportV2Message ]
        \cup [ tag : {QuoteV2MessageCode}, body : QuoteV2Message ]
        \cup [ tag : {QuoteCancelV2MessageCode}, body : QuoteCancelV2Message ]
        \cup [ tag : {TradeCaptureReportAcknowledgmentV2MessageCode}, body : TradeCaptureReportAcknowledgmentV2Message ]
        \cup [ tag : {TradeCaptureReportRejectV2MessageCode}, body : TradeCaptureReportRejectV2Message ]
        \cup [ tag : {TradeCaptureConfirmV2MessageCode}, body : TradeCaptureConfirmV2Message ]
        \cup [ tag : {TradeCaptureReportDeclineV2MessageCode}, body : TradeCaptureReportDeclineV2Message ]
        \cup [ tag : {QuoteStatusV2MessageCode}, body : QuoteStatusV2Message ]
        \cup [ tag : {QuoteRejectV2MessageCode}, body : QuoteRejectV2Message ]

EncodeMessage(message) ==
    CASE message.tag = LoginRequestV2MessageCode -> EncodeLoginRequestV2Message(message.body)
      [] message.tag = LogoutRequestMessageCode -> << >>
      [] message.tag = ClientHeartbeatMessageCode -> << >>
      [] message.tag = LoginResponseV2MessageCode -> EncodeLoginResponseV2Message(message.body)
      [] message.tag = LogoutMessageCode -> EncodeLogoutMessage(message.body)
      [] message.tag = ServerHeartbeatMessageCode -> << >>
      [] message.tag = ReplayCompleteMessageCode -> << >>
      [] message.tag = TradeCaptureReportV2MessageCode -> EncodeTradeCaptureReportV2Message(message.body)
      [] message.tag = QuoteV2MessageCode -> EncodeQuoteV2Message(message.body)
      [] message.tag = QuoteCancelV2MessageCode -> EncodeQuoteCancelV2Message(message.body)
      [] message.tag = TradeCaptureReportAcknowledgmentV2MessageCode -> EncodeTradeCaptureReportAcknowledgmentV2Message(message.body)
      [] message.tag = TradeCaptureReportRejectV2MessageCode -> EncodeTradeCaptureReportRejectV2Message(message.body)
      [] message.tag = TradeCaptureConfirmV2MessageCode -> EncodeTradeCaptureConfirmV2Message(message.body)
      [] message.tag = TradeCaptureReportDeclineV2MessageCode -> EncodeTradeCaptureReportDeclineV2Message(message.body)
      [] message.tag = QuoteStatusV2MessageCode -> EncodeQuoteStatusV2Message(message.body)
      [] message.tag = QuoteRejectV2MessageCode -> EncodeQuoteRejectV2Message(message.body)

DecodeMessage(tag, bytes) ==
    LET read ==
            CASE tag = LoginRequestV2MessageCode -> DecodeLoginRequestV2Message(bytes)
              [] tag = LogoutRequestMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = ClientHeartbeatMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = LoginResponseV2MessageCode -> DecodeLoginResponseV2Message(bytes)
              [] tag = LogoutMessageCode -> DecodeLogoutMessage(bytes)
              [] tag = ServerHeartbeatMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = ReplayCompleteMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = TradeCaptureReportV2MessageCode -> DecodeTradeCaptureReportV2Message(bytes)
              [] tag = QuoteV2MessageCode -> DecodeQuoteV2Message(bytes)
              [] tag = QuoteCancelV2MessageCode -> DecodeQuoteCancelV2Message(bytes)
              [] tag = TradeCaptureReportAcknowledgmentV2MessageCode -> DecodeTradeCaptureReportAcknowledgmentV2Message(bytes)
              [] tag = TradeCaptureReportRejectV2MessageCode -> DecodeTradeCaptureReportRejectV2Message(bytes)
              [] tag = TradeCaptureConfirmV2MessageCode -> DecodeTradeCaptureConfirmV2Message(bytes)
              [] tag = TradeCaptureReportDeclineV2MessageCode -> DecodeTradeCaptureReportDeclineV2Message(bytes)
              [] tag = QuoteStatusV2MessageCode -> DecodeQuoteStatusV2Message(bytes)
              [] tag = QuoteRejectV2MessageCode -> DecodeQuoteRejectV2Message(bytes)
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
        \cup { [tag |-> TradeCaptureReportV2MessageCode, body |-> one] : one \in CheckedTradeCaptureReportV2Message }
        \cup { [tag |-> QuoteV2MessageCode, body |-> one] : one \in CheckedQuoteV2Message }
        \cup { [tag |-> QuoteCancelV2MessageCode, body |-> one] : one \in CheckedQuoteCancelV2Message }
        \cup { [tag |-> TradeCaptureReportAcknowledgmentV2MessageCode, body |-> one] : one \in CheckedTradeCaptureReportAcknowledgmentV2Message }
        \cup { [tag |-> TradeCaptureReportRejectV2MessageCode, body |-> one] : one \in CheckedTradeCaptureReportRejectV2Message }
        \cup { [tag |-> TradeCaptureConfirmV2MessageCode, body |-> one] : one \in CheckedTradeCaptureConfirmV2Message }
        \cup { [tag |-> TradeCaptureReportDeclineV2MessageCode, body |-> one] : one \in CheckedTradeCaptureReportDeclineV2Message }
        \cup { [tag |-> QuoteStatusV2MessageCode, body |-> one] : one \in CheckedQuoteStatusV2Message }
        \cup { [tag |-> QuoteRejectV2MessageCode, body |-> one] : one \in CheckedQuoteRejectV2Message }

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

(* Every Quote V 2 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteV2Message ==
    \A message \in CheckedQuoteV2Message :
        LET read == DecodeQuoteV2Message(EncodeQuoteV2Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Cancel Rpt Grp decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteCancelRptGrp ==
    \A checked \in CheckedQuoteCancelRptGrp :
        LET read == DecodeQuoteCancelRptGrp(EncodeQuoteCancelRptGrp(checked.message), checked.given[1], checked.given[2])
        IN  /\ read.ok
            /\ read.value = checked.message
            /\ read.rest = << >>

(* Every Quote Cancel V 2 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteCancelV2Message ==
    \A message \in CheckedQuoteCancelV2Message :
        LET read == DecodeQuoteCancelV2Message(EncodeQuoteCancelV2Message(message))
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
        LET read == DecodeTradeCaptureConfirmV2TrdCapAckSideGrp(EncodeTradeCaptureConfirmV2TrdCapAckSideGrp(checked.message), checked.given[1], checked.given[2], checked.given[3], checked.given[4], checked.given[5], checked.given[6])
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

(* Every Quote Status V 2 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteStatusV2Message ==
    \A message \in CheckedQuoteStatusV2Message :
        LET read == DecodeQuoteStatusV2Message(EncodeQuoteStatusV2Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Reject V 2 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteRejectV2Message ==
    \A message \in CheckedQuoteRejectV2Message :
        LET read == DecodeQuoteRejectV2Message(EncodeQuoteRejectV2Message(message))
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
