---------------- MODULE CfeFutures_BinaryOrderEntry_v1_3_12 ----------------
(***************************************************************************)
(* Chicago Board Options Exchange Futures Binary Order Entry v1.3.12       *)
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
(* Note: Login Request Message fills what is left of the frame Message     *)
(* Length states, which is what it is read from.                           *)
(*                                                                         *)
(* Note: Login Response Message fills what is left of the frame Message    *)
(* Length states, which is what it is read from.                           *)
(*                                                                         *)
(* Note: Logout Message fills what is left of the frame Message Length     *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: A field marked present by fields read before it is read only when *)
(* they say it is there, and the records checked hold it exactly where     *)
(* they do: one holding it anywhere else is no message the protocol sends. *)
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
(* Note: Purge Orders Message fills what is left of the frame Message      *)
(* Length states, which is what it is read from.                           *)
(*                                                                         *)
(* Note: Reset Risk Message fills what is left of the frame Message Length *)
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
(* Note: Order Execution Message fills what is left of the frame Message   *)
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
(* Note: Tas Restatement New Order Message Message fills what is left of   *)
(* the frame Message Length states, which is what it is read from.         *)
(*                                                                         *)
(* Note: Variance Restatement New Order Message Message fills what is left *)
(* of the frame Message Length states, which is what it is read from.      *)
(*                                                                         *)
(* Note: Tas Quote Restatement Message fills what is left of the frame     *)
(* Message Length states, which is what it is read from.                   *)
(*                                                                         *)
(* Note: Variance Quote Restatement Message fills what is left of the      *)
(* frame Message Length states, which is what it is read from.             *)
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
      newOrderBitfield5         : { << >> } \cup { <<held>> : held \in Sample(1) },
      newOrderBitfield6         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      newOrderBitfield7         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      newOrderBitfield8         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      newOrderBitfield9         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      clearingFirm              : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingAccount           : { << >> } \cup { <<held>> : held \in Sample(4) },
      price                     : { << >> } \cup { <<held>> : held \in Sample(8) },
      ordType                   : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce               : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                    : { << >> } \cup { <<held>> : held \in Sample(4) },
      symbolLong                : { << >> } \cup { <<held>> : held \in Sample(8) },
      capacity                  : { << >> } \cup { <<held>> : held \in Sample(1) },
      account                   : { << >> } \cup { <<held>> : held \in Sample(16) },
      preventMatch              : { << >> } \cup { <<held>> : held \in Sample(3) },
      expireTime                : { << >> } \cup { <<held>> : held \in Sample(8) },
      maturityDate              : { << >> } \cup { <<held>> : held \in Sample(4) },
      riskReset                 : { << >> } \cup { <<held>> : held \in Sample(8) },
      openClose                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      cmtaNumber                : { << >> } \cup { <<held>> : held \in Sample(4) },
      stopPx                    : { << >> } \cup { <<held>> : held \in Sample(8) },
      customGroupId             : { << >> } \cup { <<held>> : held \in Sample(2) },
      ctiCode                   : { << >> } \cup { <<held>> : held \in Sample(1) },
      manualOrderIndicator      : { << >> } \cup { <<held>> : held \in Sample(1) },
      oeoid                     : { << >> } \cup { <<held>> : held \in Sample(18) },
      frequentTraderId          : { << >> } \cup { <<held>> : held \in Sample(6) },
      custOrderHandlingInst     : { << >> } \cup { <<held>> : held \in Sample(1) } ]

EncodeNewOrderMessage(message) ==
    message.clOrdId
        \o message.side
        \o message.orderQty
        \o EncodeUIntBE(message.numberOfNewOrderBitfields, 1)
        \o (IF message.newOrderBitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.newOrderBitfield1[1], 1))
        \o (IF message.newOrderBitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.newOrderBitfield2[1], 1))
        \o (IF message.newOrderBitfield3 = << >> THEN << >> ELSE EncodeUIntLE(message.newOrderBitfield3[1], 1))
        \o (IF message.newOrderBitfield4 = << >> THEN << >> ELSE EncodeUIntLE(message.newOrderBitfield4[1], 1))
        \o (IF message.newOrderBitfield5 = << >> THEN << >> ELSE message.newOrderBitfield5[1])
        \o (IF message.newOrderBitfield6 = << >> THEN << >> ELSE EncodeUIntLE(message.newOrderBitfield6[1], 1))
        \o (IF message.newOrderBitfield7 = << >> THEN << >> ELSE EncodeUIntLE(message.newOrderBitfield7[1], 1))
        \o (IF message.newOrderBitfield8 = << >> THEN << >> ELSE EncodeUIntLE(message.newOrderBitfield8[1], 1))
        \o (IF message.newOrderBitfield9 = << >> THEN << >> ELSE EncodeUIntLE(message.newOrderBitfield9[1], 1))
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])
        \o (IF message.clearingAccount = << >> THEN << >> ELSE message.clearingAccount[1])
        \o (IF message.price = << >> THEN << >> ELSE message.price[1])
        \o (IF message.ordType = << >> THEN << >> ELSE message.ordType[1])
        \o (IF message.timeInForce = << >> THEN << >> ELSE message.timeInForce[1])
        \o (IF message.minQty = << >> THEN << >> ELSE message.minQty[1])
        \o (IF message.symbolLong = << >> THEN << >> ELSE message.symbolLong[1])
        \o (IF message.capacity = << >> THEN << >> ELSE message.capacity[1])
        \o (IF message.account = << >> THEN << >> ELSE message.account[1])
        \o (IF message.preventMatch = << >> THEN << >> ELSE message.preventMatch[1])
        \o (IF message.expireTime = << >> THEN << >> ELSE message.expireTime[1])
        \o (IF message.maturityDate = << >> THEN << >> ELSE message.maturityDate[1])
        \o (IF message.riskReset = << >> THEN << >> ELSE message.riskReset[1])
        \o (IF message.openClose = << >> THEN << >> ELSE message.openClose[1])
        \o (IF message.cmtaNumber = << >> THEN << >> ELSE message.cmtaNumber[1])
        \o (IF message.stopPx = << >> THEN << >> ELSE message.stopPx[1])
        \o (IF message.customGroupId = << >> THEN << >> ELSE message.customGroupId[1])
        \o (IF message.ctiCode = << >> THEN << >> ELSE message.ctiCode[1])
        \o (IF message.manualOrderIndicator = << >> THEN << >> ELSE message.manualOrderIndicator[1])
        \o (IF message.oeoid = << >> THEN << >> ELSE message.oeoid[1])
        \o (IF message.frequentTraderId = << >> THEN << >> ELSE message.frequentTraderId[1])
        \o (IF message.custOrderHandlingInst = << >> THEN << >> ELSE message.custOrderHandlingInst[1])

DecodeNewOrderMessage(bytes) ==
    LET clOrdId == ReadBytes(bytes, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET side == ReadBytes(clOrdId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderQty == ReadBytes(side.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET numberOfNewOrderBitfields == ReadUIntBE(orderQty.rest, 1) IN IF ~numberOfNewOrderBitfields.ok THEN Fail ELSE
    LET newOrderBitfield1 == ReadWhen(numberOfNewOrderBitfields.value >= 1, ReadUIntLE(numberOfNewOrderBitfields.rest, 1), numberOfNewOrderBitfields.rest) IN IF ~newOrderBitfield1.ok THEN Fail ELSE
    LET newOrderBitfield2 == ReadWhen(numberOfNewOrderBitfields.value >= 2, ReadUIntLE(newOrderBitfield1.rest, 1), newOrderBitfield1.rest) IN IF ~newOrderBitfield2.ok THEN Fail ELSE
    LET newOrderBitfield3 == ReadWhen(numberOfNewOrderBitfields.value >= 3, ReadUIntLE(newOrderBitfield2.rest, 1), newOrderBitfield2.rest) IN IF ~newOrderBitfield3.ok THEN Fail ELSE
    LET newOrderBitfield4 == ReadWhen(numberOfNewOrderBitfields.value >= 4, ReadUIntLE(newOrderBitfield3.rest, 1), newOrderBitfield3.rest) IN IF ~newOrderBitfield4.ok THEN Fail ELSE
    LET newOrderBitfield5 == ReadWhen(numberOfNewOrderBitfields.value >= 5, ReadBytes(newOrderBitfield4.rest, 1), newOrderBitfield4.rest) IN IF ~newOrderBitfield5.ok THEN Fail ELSE
    LET newOrderBitfield6 == ReadWhen(numberOfNewOrderBitfields.value >= 6, ReadUIntLE(newOrderBitfield5.rest, 1), newOrderBitfield5.rest) IN IF ~newOrderBitfield6.ok THEN Fail ELSE
    LET newOrderBitfield7 == ReadWhen(numberOfNewOrderBitfields.value >= 7, ReadUIntLE(newOrderBitfield6.rest, 1), newOrderBitfield6.rest) IN IF ~newOrderBitfield7.ok THEN Fail ELSE
    LET newOrderBitfield8 == ReadWhen(numberOfNewOrderBitfields.value >= 8, ReadUIntLE(newOrderBitfield7.rest, 1), newOrderBitfield7.rest) IN IF ~newOrderBitfield8.ok THEN Fail ELSE
    LET newOrderBitfield9 == ReadWhen(numberOfNewOrderBitfields.value >= 9, ReadUIntLE(newOrderBitfield8.rest, 1), newOrderBitfield8.rest) IN IF ~newOrderBitfield9.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfNewOrderBitfields.value >= 1 /\ (newOrderBitfield1.value # << >> /\ newOrderBitfield1.value[1] % 2 > 0), ReadBytes(newOrderBitfield9.rest, 4), newOrderBitfield9.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadWhen(numberOfNewOrderBitfields.value >= 1 /\ (newOrderBitfield1.value # << >> /\ (newOrderBitfield1.value[1] \div 2) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET price == ReadWhen(numberOfNewOrderBitfields.value >= 1 /\ (newOrderBitfield1.value # << >> /\ (newOrderBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(clearingAccount.rest, 8), clearingAccount.rest) IN IF ~price.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfNewOrderBitfields.value >= 1 /\ (newOrderBitfield1.value # << >> /\ (newOrderBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(price.rest, 1), price.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfNewOrderBitfields.value >= 1 /\ (newOrderBitfield1.value # << >> /\ (newOrderBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfNewOrderBitfields.value >= 1 /\ (newOrderBitfield1.value # << >> /\ (newOrderBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET symbolLong == ReadWhen(numberOfNewOrderBitfields.value >= 2 /\ (newOrderBitfield2.value # << >> /\ newOrderBitfield2.value[1] % 2 > 0), ReadBytes(minQty.rest, 8), minQty.rest) IN IF ~symbolLong.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfNewOrderBitfields.value >= 2 /\ (newOrderBitfield2.value # << >> /\ (newOrderBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(symbolLong.rest, 1), symbolLong.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadWhen(numberOfNewOrderBitfields.value >= 3 /\ (newOrderBitfield3.value # << >> /\ newOrderBitfield3.value[1] % 2 > 0), ReadBytes(capacity.rest, 16), capacity.rest) IN IF ~account.ok THEN Fail ELSE
    LET preventMatch == ReadWhen(numberOfNewOrderBitfields.value >= 3 /\ (newOrderBitfield3.value # << >> /\ (newOrderBitfield3.value[1] \div 32) % 2 > 0), ReadBytes(account.rest, 3), account.rest) IN IF ~preventMatch.ok THEN Fail ELSE
    LET expireTime == ReadWhen(numberOfNewOrderBitfields.value >= 3 /\ (newOrderBitfield3.value # << >> /\ (newOrderBitfield3.value[1] \div 128) % 2 > 0), ReadBytes(preventMatch.rest, 8), preventMatch.rest) IN IF ~expireTime.ok THEN Fail ELSE
    LET maturityDate == ReadWhen(numberOfNewOrderBitfields.value >= 4 /\ (newOrderBitfield4.value # << >> /\ newOrderBitfield4.value[1] % 2 > 0), ReadBytes(expireTime.rest, 4), expireTime.rest) IN IF ~maturityDate.ok THEN Fail ELSE
    LET riskReset == ReadWhen(numberOfNewOrderBitfields.value >= 4 /\ (newOrderBitfield4.value # << >> /\ (newOrderBitfield4.value[1] \div 8) % 2 > 0), ReadBytes(maturityDate.rest, 8), maturityDate.rest) IN IF ~riskReset.ok THEN Fail ELSE
    LET openClose == ReadWhen(numberOfNewOrderBitfields.value >= 4 /\ (newOrderBitfield4.value # << >> /\ (newOrderBitfield4.value[1] \div 16) % 2 > 0), ReadBytes(riskReset.rest, 1), riskReset.rest) IN IF ~openClose.ok THEN Fail ELSE
    LET cmtaNumber == ReadWhen(numberOfNewOrderBitfields.value >= 4 /\ (newOrderBitfield4.value # << >> /\ (newOrderBitfield4.value[1] \div 32) % 2 > 0), ReadBytes(openClose.rest, 4), openClose.rest) IN IF ~cmtaNumber.ok THEN Fail ELSE
    LET stopPx == ReadWhen(numberOfNewOrderBitfields.value >= 6 /\ (newOrderBitfield6.value # << >> /\ (newOrderBitfield6.value[1] \div 2) % 2 > 0), ReadBytes(cmtaNumber.rest, 8), cmtaNumber.rest) IN IF ~stopPx.ok THEN Fail ELSE
    LET customGroupId == ReadWhen(numberOfNewOrderBitfields.value >= 7 /\ (newOrderBitfield7.value # << >> /\ (newOrderBitfield7.value[1] \div 2) % 2 > 0), ReadBytes(stopPx.rest, 2), stopPx.rest) IN IF ~customGroupId.ok THEN Fail ELSE
    LET ctiCode == ReadWhen(numberOfNewOrderBitfields.value >= 7 /\ (newOrderBitfield7.value # << >> /\ (newOrderBitfield7.value[1] \div 32) % 2 > 0), ReadBytes(customGroupId.rest, 1), customGroupId.rest) IN IF ~ctiCode.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadWhen(numberOfNewOrderBitfields.value >= 7 /\ (newOrderBitfield7.value # << >> /\ (newOrderBitfield7.value[1] \div 64) % 2 > 0), ReadBytes(ctiCode.rest, 1), ctiCode.rest) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET oeoid == ReadWhen(numberOfNewOrderBitfields.value >= 7 /\ (newOrderBitfield7.value # << >> /\ (newOrderBitfield7.value[1] \div 128) % 2 > 0), ReadBytes(manualOrderIndicator.rest, 18), manualOrderIndicator.rest) IN IF ~oeoid.ok THEN Fail ELSE
    LET frequentTraderId == ReadWhen(numberOfNewOrderBitfields.value >= 8 /\ (newOrderBitfield8.value # << >> /\ (newOrderBitfield8.value[1] \div 16) % 2 > 0), ReadBytes(oeoid.rest, 6), oeoid.rest) IN IF ~frequentTraderId.ok THEN Fail ELSE
    LET custOrderHandlingInst == ReadWhen(numberOfNewOrderBitfields.value >= 9 /\ (newOrderBitfield9.value # << >> /\ (newOrderBitfield9.value[1] \div 16) % 2 > 0), ReadBytes(frequentTraderId.rest, 1), frequentTraderId.rest) IN IF ~custOrderHandlingInst.ok THEN Fail ELSE
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
         clearingFirm              |-> clearingFirm.value,
         clearingAccount           |-> clearingAccount.value,
         price                     |-> price.value,
         ordType                   |-> ordType.value,
         timeInForce               |-> timeInForce.value,
         minQty                    |-> minQty.value,
         symbolLong                |-> symbolLong.value,
         capacity                  |-> capacity.value,
         account                   |-> account.value,
         preventMatch              |-> preventMatch.value,
         expireTime                |-> expireTime.value,
         maturityDate              |-> maturityDate.value,
         riskReset                 |-> riskReset.value,
         openClose                 |-> openClose.value,
         cmtaNumber                |-> cmtaNumber.value,
         stopPx                    |-> stopPx.value,
         customGroupId             |-> customGroupId.value,
         ctiCode                   |-> ctiCode.value,
         manualOrderIndicator      |-> manualOrderIndicator.value,
         oeoid                     |-> oeoid.value,
         frequentTraderId          |-> frequentTraderId.value,
         custOrderHandlingInst     |-> custOrderHandlingInst.value ], custOrderHandlingInst.rest)

(* New Order Message with each field marked present by fields before it there exactly where they say *)
SettleNewOrderMessage(message) ==
    LET settled1 == [message EXCEPT !.newOrderBitfield1 = IF message.numberOfNewOrderBitfields >= 1 THEN (IF message.newOrderBitfield1 = << >> THEN <<0>> ELSE message.newOrderBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.newOrderBitfield2 = IF settled1.numberOfNewOrderBitfields >= 2 THEN (IF settled1.newOrderBitfield2 = << >> THEN <<0>> ELSE settled1.newOrderBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.newOrderBitfield3 = IF settled2.numberOfNewOrderBitfields >= 3 THEN (IF settled2.newOrderBitfield3 = << >> THEN <<0>> ELSE settled2.newOrderBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.newOrderBitfield4 = IF settled3.numberOfNewOrderBitfields >= 4 THEN (IF settled3.newOrderBitfield4 = << >> THEN <<0>> ELSE settled3.newOrderBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.newOrderBitfield5 = IF settled4.numberOfNewOrderBitfields >= 5 THEN (IF settled4.newOrderBitfield5 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled4.newOrderBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.newOrderBitfield6 = IF settled5.numberOfNewOrderBitfields >= 6 THEN (IF settled5.newOrderBitfield6 = << >> THEN <<0>> ELSE settled5.newOrderBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.newOrderBitfield7 = IF settled6.numberOfNewOrderBitfields >= 7 THEN (IF settled6.newOrderBitfield7 = << >> THEN <<0>> ELSE settled6.newOrderBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.newOrderBitfield8 = IF settled7.numberOfNewOrderBitfields >= 8 THEN (IF settled7.newOrderBitfield8 = << >> THEN <<0>> ELSE settled7.newOrderBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.newOrderBitfield9 = IF settled8.numberOfNewOrderBitfields >= 9 THEN (IF settled8.newOrderBitfield9 = << >> THEN <<0>> ELSE settled8.newOrderBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.clearingFirm = IF settled9.numberOfNewOrderBitfields >= 1 /\ (settled9.newOrderBitfield1 # << >> /\ settled9.newOrderBitfield1[1] % 2 > 0) THEN (IF settled9.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled9.clearingFirm) ELSE << >>]
        settled11 == [settled10 EXCEPT !.clearingAccount = IF settled10.numberOfNewOrderBitfields >= 1 /\ (settled10.newOrderBitfield1 # << >> /\ (settled10.newOrderBitfield1[1] \div 2) % 2 > 0) THEN (IF settled10.clearingAccount = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled10.clearingAccount) ELSE << >>]
        settled12 == [settled11 EXCEPT !.price = IF settled11.numberOfNewOrderBitfields >= 1 /\ (settled11.newOrderBitfield1 # << >> /\ (settled11.newOrderBitfield1[1] \div 4) % 2 > 0) THEN (IF settled11.price = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled11.price) ELSE << >>]
        settled13 == [settled12 EXCEPT !.ordType = IF settled12.numberOfNewOrderBitfields >= 1 /\ (settled12.newOrderBitfield1 # << >> /\ (settled12.newOrderBitfield1[1] \div 16) % 2 > 0) THEN (IF settled12.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.ordType) ELSE << >>]
        settled14 == [settled13 EXCEPT !.timeInForce = IF settled13.numberOfNewOrderBitfields >= 1 /\ (settled13.newOrderBitfield1 # << >> /\ (settled13.newOrderBitfield1[1] \div 32) % 2 > 0) THEN (IF settled13.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.timeInForce) ELSE << >>]
        settled15 == [settled14 EXCEPT !.minQty = IF settled14.numberOfNewOrderBitfields >= 1 /\ (settled14.newOrderBitfield1 # << >> /\ (settled14.newOrderBitfield1[1] \div 64) % 2 > 0) THEN (IF settled14.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled14.minQty) ELSE << >>]
        settled16 == [settled15 EXCEPT !.symbolLong = IF settled15.numberOfNewOrderBitfields >= 2 /\ (settled15.newOrderBitfield2 # << >> /\ settled15.newOrderBitfield2[1] % 2 > 0) THEN (IF settled15.symbolLong = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled15.symbolLong) ELSE << >>]
        settled17 == [settled16 EXCEPT !.capacity = IF settled16.numberOfNewOrderBitfields >= 2 /\ (settled16.newOrderBitfield2 # << >> /\ (settled16.newOrderBitfield2[1] \div 64) % 2 > 0) THEN (IF settled16.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled16.capacity) ELSE << >>]
        settled18 == [settled17 EXCEPT !.account = IF settled17.numberOfNewOrderBitfields >= 3 /\ (settled17.newOrderBitfield3 # << >> /\ settled17.newOrderBitfield3[1] % 2 > 0) THEN (IF settled17.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled17.account) ELSE << >>]
        settled19 == [settled18 EXCEPT !.preventMatch = IF settled18.numberOfNewOrderBitfields >= 3 /\ (settled18.newOrderBitfield3 # << >> /\ (settled18.newOrderBitfield3[1] \div 32) % 2 > 0) THEN (IF settled18.preventMatch = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled18.preventMatch) ELSE << >>]
        settled20 == [settled19 EXCEPT !.expireTime = IF settled19.numberOfNewOrderBitfields >= 3 /\ (settled19.newOrderBitfield3 # << >> /\ (settled19.newOrderBitfield3[1] \div 128) % 2 > 0) THEN (IF settled19.expireTime = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled19.expireTime) ELSE << >>]
        settled21 == [settled20 EXCEPT !.maturityDate = IF settled20.numberOfNewOrderBitfields >= 4 /\ (settled20.newOrderBitfield4 # << >> /\ settled20.newOrderBitfield4[1] % 2 > 0) THEN (IF settled20.maturityDate = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled20.maturityDate) ELSE << >>]
        settled22 == [settled21 EXCEPT !.riskReset = IF settled21.numberOfNewOrderBitfields >= 4 /\ (settled21.newOrderBitfield4 # << >> /\ (settled21.newOrderBitfield4[1] \div 8) % 2 > 0) THEN (IF settled21.riskReset = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled21.riskReset) ELSE << >>]
        settled23 == [settled22 EXCEPT !.openClose = IF settled22.numberOfNewOrderBitfields >= 4 /\ (settled22.newOrderBitfield4 # << >> /\ (settled22.newOrderBitfield4[1] \div 16) % 2 > 0) THEN (IF settled22.openClose = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled22.openClose) ELSE << >>]
        settled24 == [settled23 EXCEPT !.cmtaNumber = IF settled23.numberOfNewOrderBitfields >= 4 /\ (settled23.newOrderBitfield4 # << >> /\ (settled23.newOrderBitfield4[1] \div 32) % 2 > 0) THEN (IF settled23.cmtaNumber = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled23.cmtaNumber) ELSE << >>]
        settled25 == [settled24 EXCEPT !.stopPx = IF settled24.numberOfNewOrderBitfields >= 6 /\ (settled24.newOrderBitfield6 # << >> /\ (settled24.newOrderBitfield6[1] \div 2) % 2 > 0) THEN (IF settled24.stopPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled24.stopPx) ELSE << >>]
        settled26 == [settled25 EXCEPT !.customGroupId = IF settled25.numberOfNewOrderBitfields >= 7 /\ (settled25.newOrderBitfield7 # << >> /\ (settled25.newOrderBitfield7[1] \div 2) % 2 > 0) THEN (IF settled25.customGroupId = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled25.customGroupId) ELSE << >>]
        settled27 == [settled26 EXCEPT !.ctiCode = IF settled26.numberOfNewOrderBitfields >= 7 /\ (settled26.newOrderBitfield7 # << >> /\ (settled26.newOrderBitfield7[1] \div 32) % 2 > 0) THEN (IF settled26.ctiCode = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled26.ctiCode) ELSE << >>]
        settled28 == [settled27 EXCEPT !.manualOrderIndicator = IF settled27.numberOfNewOrderBitfields >= 7 /\ (settled27.newOrderBitfield7 # << >> /\ (settled27.newOrderBitfield7[1] \div 64) % 2 > 0) THEN (IF settled27.manualOrderIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled27.manualOrderIndicator) ELSE << >>]
        settled29 == [settled28 EXCEPT !.oeoid = IF settled28.numberOfNewOrderBitfields >= 7 /\ (settled28.newOrderBitfield7 # << >> /\ (settled28.newOrderBitfield7[1] \div 128) % 2 > 0) THEN (IF settled28.oeoid = << >> THEN <<[i \in 1 .. 18 |-> 0]>> ELSE settled28.oeoid) ELSE << >>]
        settled30 == [settled29 EXCEPT !.frequentTraderId = IF settled29.numberOfNewOrderBitfields >= 8 /\ (settled29.newOrderBitfield8 # << >> /\ (settled29.newOrderBitfield8[1] \div 16) % 2 > 0) THEN (IF settled29.frequentTraderId = << >> THEN <<[i \in 1 .. 6 |-> 0]>> ELSE settled29.frequentTraderId) ELSE << >>]
        settled31 == [settled30 EXCEPT !.custOrderHandlingInst = IF settled30.numberOfNewOrderBitfields >= 9 /\ (settled30.newOrderBitfield9 # << >> /\ (settled30.newOrderBitfield9[1] \div 16) % 2 > 0) THEN (IF settled30.custOrderHandlingInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled30.custOrderHandlingInst) ELSE << >>]
    IN  settled31

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
                            clearingFirm              |-> << >>,
                            clearingAccount           |-> << >>,
                            price                     |-> << >>,
                            ordType                   |-> << >>,
                            timeInForce               |-> << >>,
                            minQty                    |-> << >>,
                            symbolLong                |-> << >>,
                            capacity                  |-> << >>,
                            account                   |-> << >>,
                            preventMatch              |-> << >>,
                            expireTime                |-> << >>,
                            maturityDate              |-> << >>,
                            riskReset                 |-> << >>,
                            openClose                 |-> << >>,
                            cmtaNumber                |-> << >>,
                            stopPx                    |-> << >>,
                            customGroupId             |-> << >>,
                            ctiCode                   |-> << >>,
                            manualOrderIndicator      |-> << >>,
                            oeoid                     |-> << >>,
                            frequentTraderId          |-> << >>,
                            custOrderHandlingInst     |-> << >> ])

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
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 5, !.newOrderBitfield5 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 6, !.newOrderBitfield6 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 7, !.newOrderBitfield7 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 8, !.newOrderBitfield8 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 9, !.newOrderBitfield9 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 1, !.newOrderBitfield1 = <<1>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 1, !.newOrderBitfield1 = <<2>>, !.clearingAccount = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 1, !.newOrderBitfield1 = <<4>>, !.price = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 1, !.newOrderBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 1, !.newOrderBitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 1, !.newOrderBitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 2, !.newOrderBitfield2 = <<1>>, !.symbolLong = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 2, !.newOrderBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 3, !.newOrderBitfield3 = <<1>>, !.account = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 3, !.newOrderBitfield3 = <<32>>, !.preventMatch = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 3, !.newOrderBitfield3 = <<128>>, !.expireTime = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 4, !.newOrderBitfield4 = <<1>>, !.maturityDate = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 4, !.newOrderBitfield4 = <<8>>, !.riskReset = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 4, !.newOrderBitfield4 = <<16>>, !.openClose = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 4, !.newOrderBitfield4 = <<32>>, !.cmtaNumber = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 6, !.newOrderBitfield6 = <<2>>, !.stopPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 7, !.newOrderBitfield7 = <<2>>, !.customGroupId = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 7, !.newOrderBitfield7 = <<32>>, !.ctiCode = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 7, !.newOrderBitfield7 = <<64>>, !.manualOrderIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 7, !.newOrderBitfield7 = <<128>>, !.oeoid = one]) : one \in { <<held>> : held \in Sample(18) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 8, !.newOrderBitfield8 = <<16>>, !.frequentTraderId = one]) : one \in { <<held>> : held \in Sample(6) } }
        \cup { SettleNewOrderMessage([ZeroNewOrderMessage EXCEPT !.numberOfNewOrderBitfields = 9, !.newOrderBitfield9 = <<16>>, !.custOrderHandlingInst = one]) : one \in { <<held>> : held \in Sample(1) } }

(***************************************************************************)
(* Cancel Order Message                                                    *)
(***************************************************************************)

CancelOrderMessage ==
    [ origClOrdId                  : Sample(20),
      numberOfCancelOrderBitfields : 0 .. 255,
      cancelOrderBitfield1         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      cancelOrderBitfield2         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      clearingFirm                 : { << >> } \cup { <<held>> : held \in Sample(4) },
      productName                  : { << >> } \cup { <<held>> : held \in Sample(6) },
      massCancelId                 : { << >> } \cup { <<held>> : held \in Sample(20) },
      manualOrderIndicator         : { << >> } \cup { <<held>> : held \in Sample(1) },
      oeoid                        : { << >> } \cup { <<held>> : held \in Sample(18) },
      massCancelInst               : { << >> } \cup { <<held>> : held \in Sample(16) } ]

EncodeCancelOrderMessage(message) ==
    message.origClOrdId
        \o EncodeUIntBE(message.numberOfCancelOrderBitfields, 1)
        \o (IF message.cancelOrderBitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.cancelOrderBitfield1[1], 1))
        \o (IF message.cancelOrderBitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.cancelOrderBitfield2[1], 1))
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])
        \o (IF message.productName = << >> THEN << >> ELSE message.productName[1])
        \o (IF message.massCancelId = << >> THEN << >> ELSE message.massCancelId[1])
        \o (IF message.manualOrderIndicator = << >> THEN << >> ELSE message.manualOrderIndicator[1])
        \o (IF message.oeoid = << >> THEN << >> ELSE message.oeoid[1])
        \o (IF message.massCancelInst = << >> THEN << >> ELSE message.massCancelInst[1])

DecodeCancelOrderMessage(bytes) ==
    LET origClOrdId == ReadBytes(bytes, 20) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET numberOfCancelOrderBitfields == ReadUIntBE(origClOrdId.rest, 1) IN IF ~numberOfCancelOrderBitfields.ok THEN Fail ELSE
    LET cancelOrderBitfield1 == ReadWhen(numberOfCancelOrderBitfields.value >= 1, ReadUIntLE(numberOfCancelOrderBitfields.rest, 1), numberOfCancelOrderBitfields.rest) IN IF ~cancelOrderBitfield1.ok THEN Fail ELSE
    LET cancelOrderBitfield2 == ReadWhen(numberOfCancelOrderBitfields.value >= 2, ReadUIntLE(cancelOrderBitfield1.rest, 1), cancelOrderBitfield1.rest) IN IF ~cancelOrderBitfield2.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfCancelOrderBitfields.value >= 1 /\ (cancelOrderBitfield1.value # << >> /\ cancelOrderBitfield1.value[1] % 2 > 0), ReadBytes(cancelOrderBitfield2.rest, 4), cancelOrderBitfield2.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET productName == ReadWhen(numberOfCancelOrderBitfields.value >= 1 /\ (cancelOrderBitfield1.value # << >> /\ (cancelOrderBitfield1.value[1] \div 8) % 2 > 0), ReadBytes(clearingFirm.rest, 6), clearingFirm.rest) IN IF ~productName.ok THEN Fail ELSE
    LET massCancelId == ReadWhen(numberOfCancelOrderBitfields.value >= 1 /\ (cancelOrderBitfield1.value # << >> /\ (cancelOrderBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(productName.rest, 20), productName.rest) IN IF ~massCancelId.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadWhen(numberOfCancelOrderBitfields.value >= 1 /\ (cancelOrderBitfield1.value # << >> /\ (cancelOrderBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(massCancelId.rest, 1), massCancelId.rest) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET oeoid == ReadWhen(numberOfCancelOrderBitfields.value >= 1 /\ (cancelOrderBitfield1.value # << >> /\ (cancelOrderBitfield1.value[1] \div 128) % 2 > 0), ReadBytes(manualOrderIndicator.rest, 18), manualOrderIndicator.rest) IN IF ~oeoid.ok THEN Fail ELSE
    LET massCancelInst == ReadWhen(numberOfCancelOrderBitfields.value >= 2 /\ (cancelOrderBitfield2.value # << >> /\ cancelOrderBitfield2.value[1] % 2 > 0), ReadBytes(oeoid.rest, 16), oeoid.rest) IN IF ~massCancelInst.ok THEN Fail ELSE
    Ok([ origClOrdId                  |-> origClOrdId.value,
         numberOfCancelOrderBitfields |-> numberOfCancelOrderBitfields.value,
         cancelOrderBitfield1         |-> cancelOrderBitfield1.value,
         cancelOrderBitfield2         |-> cancelOrderBitfield2.value,
         clearingFirm                 |-> clearingFirm.value,
         productName                  |-> productName.value,
         massCancelId                 |-> massCancelId.value,
         manualOrderIndicator         |-> manualOrderIndicator.value,
         oeoid                        |-> oeoid.value,
         massCancelInst               |-> massCancelInst.value ], massCancelInst.rest)

(* Cancel Order Message with each field marked present by fields before it there exactly where they say *)
SettleCancelOrderMessage(message) ==
    LET settled1 == [message EXCEPT !.cancelOrderBitfield1 = IF message.numberOfCancelOrderBitfields >= 1 THEN (IF message.cancelOrderBitfield1 = << >> THEN <<0>> ELSE message.cancelOrderBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.cancelOrderBitfield2 = IF settled1.numberOfCancelOrderBitfields >= 2 THEN (IF settled1.cancelOrderBitfield2 = << >> THEN <<0>> ELSE settled1.cancelOrderBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.clearingFirm = IF settled2.numberOfCancelOrderBitfields >= 1 /\ (settled2.cancelOrderBitfield1 # << >> /\ settled2.cancelOrderBitfield1[1] % 2 > 0) THEN (IF settled2.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled2.clearingFirm) ELSE << >>]
        settled4 == [settled3 EXCEPT !.productName = IF settled3.numberOfCancelOrderBitfields >= 1 /\ (settled3.cancelOrderBitfield1 # << >> /\ (settled3.cancelOrderBitfield1[1] \div 8) % 2 > 0) THEN (IF settled3.productName = << >> THEN <<[i \in 1 .. 6 |-> 0]>> ELSE settled3.productName) ELSE << >>]
        settled5 == [settled4 EXCEPT !.massCancelId = IF settled4.numberOfCancelOrderBitfields >= 1 /\ (settled4.cancelOrderBitfield1 # << >> /\ (settled4.cancelOrderBitfield1[1] \div 16) % 2 > 0) THEN (IF settled4.massCancelId = << >> THEN <<[i \in 1 .. 20 |-> 0]>> ELSE settled4.massCancelId) ELSE << >>]
        settled6 == [settled5 EXCEPT !.manualOrderIndicator = IF settled5.numberOfCancelOrderBitfields >= 1 /\ (settled5.cancelOrderBitfield1 # << >> /\ (settled5.cancelOrderBitfield1[1] \div 64) % 2 > 0) THEN (IF settled5.manualOrderIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled5.manualOrderIndicator) ELSE << >>]
        settled7 == [settled6 EXCEPT !.oeoid = IF settled6.numberOfCancelOrderBitfields >= 1 /\ (settled6.cancelOrderBitfield1 # << >> /\ (settled6.cancelOrderBitfield1[1] \div 128) % 2 > 0) THEN (IF settled6.oeoid = << >> THEN <<[i \in 1 .. 18 |-> 0]>> ELSE settled6.oeoid) ELSE << >>]
        settled8 == [settled7 EXCEPT !.massCancelInst = IF settled7.numberOfCancelOrderBitfields >= 2 /\ (settled7.cancelOrderBitfield2 # << >> /\ settled7.cancelOrderBitfield2[1] % 2 > 0) THEN (IF settled7.massCancelInst = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled7.massCancelInst) ELSE << >>]
    IN  settled8

ZeroCancelOrderMessage ==
    SettleCancelOrderMessage([ origClOrdId                  |-> [i \in 1 .. 20 |-> 0],
                               numberOfCancelOrderBitfields |-> 0,
                               cancelOrderBitfield1         |-> << >>,
                               cancelOrderBitfield2         |-> << >>,
                               clearingFirm                 |-> << >>,
                               productName                  |-> << >>,
                               massCancelId                 |-> << >>,
                               manualOrderIndicator         |-> << >>,
                               oeoid                        |-> << >>,
                               massCancelInst               |-> << >> ])

(* Cancel Order Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelOrderMessage ==
    { ZeroCancelOrderMessage }
        \cup { SettleCancelOrderMessage([ZeroCancelOrderMessage EXCEPT !.origClOrdId = one]) : one \in Sample(20) }
        \cup { SettleCancelOrderMessage([ZeroCancelOrderMessage EXCEPT !.numberOfCancelOrderBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleCancelOrderMessage([ZeroCancelOrderMessage EXCEPT !.numberOfCancelOrderBitfields = 1, !.cancelOrderBitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleCancelOrderMessage([ZeroCancelOrderMessage EXCEPT !.numberOfCancelOrderBitfields = 2, !.cancelOrderBitfield2 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleCancelOrderMessage([ZeroCancelOrderMessage EXCEPT !.numberOfCancelOrderBitfields = 1, !.cancelOrderBitfield1 = <<1>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleCancelOrderMessage([ZeroCancelOrderMessage EXCEPT !.numberOfCancelOrderBitfields = 1, !.cancelOrderBitfield1 = <<8>>, !.productName = one]) : one \in { <<held>> : held \in Sample(6) } }
        \cup { SettleCancelOrderMessage([ZeroCancelOrderMessage EXCEPT !.numberOfCancelOrderBitfields = 1, !.cancelOrderBitfield1 = <<16>>, !.massCancelId = one]) : one \in { <<held>> : held \in Sample(20) } }
        \cup { SettleCancelOrderMessage([ZeroCancelOrderMessage EXCEPT !.numberOfCancelOrderBitfields = 1, !.cancelOrderBitfield1 = <<64>>, !.manualOrderIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelOrderMessage([ZeroCancelOrderMessage EXCEPT !.numberOfCancelOrderBitfields = 1, !.cancelOrderBitfield1 = <<128>>, !.oeoid = one]) : one \in { <<held>> : held \in Sample(18) } }
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
      orderQty                     : { << >> } \cup { <<held>> : held \in Sample(4) },
      price                        : { << >> } \cup { <<held>> : held \in Sample(8) },
      ordType                      : { << >> } \cup { <<held>> : held \in Sample(1) },
      cancelOrigOnReject           : { << >> } \cup { <<held>> : held \in Sample(1) },
      stopPx                       : { << >> } \cup { <<held>> : held \in Sample(8) },
      manualOrderIndicator         : { << >> } \cup { <<held>> : held \in Sample(1) },
      oeoid                        : { << >> } \cup { <<held>> : held \in Sample(18) },
      frequentTraderId             : { << >> } \cup { <<held>> : held \in Sample(6) },
      custOrderHandlingInst        : { << >> } \cup { <<held>> : held \in Sample(1) } ]

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
        \o (IF message.stopPx = << >> THEN << >> ELSE message.stopPx[1])
        \o (IF message.manualOrderIndicator = << >> THEN << >> ELSE message.manualOrderIndicator[1])
        \o (IF message.oeoid = << >> THEN << >> ELSE message.oeoid[1])
        \o (IF message.frequentTraderId = << >> THEN << >> ELSE message.frequentTraderId[1])
        \o (IF message.custOrderHandlingInst = << >> THEN << >> ELSE message.custOrderHandlingInst[1])

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
    LET stopPx == ReadWhen(numberOfModifyOrderBitfields.value >= 2 /\ (modifyOrderBitfield2.value # << >> /\ (modifyOrderBitfield2.value[1] \div 2) % 2 > 0), ReadBytes(cancelOrigOnReject.rest, 8), cancelOrigOnReject.rest) IN IF ~stopPx.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadWhen(numberOfModifyOrderBitfields.value >= 2 /\ (modifyOrderBitfield2.value # << >> /\ (modifyOrderBitfield2.value[1] \div 8) % 2 > 0), ReadBytes(stopPx.rest, 1), stopPx.rest) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET oeoid == ReadWhen(numberOfModifyOrderBitfields.value >= 2 /\ (modifyOrderBitfield2.value # << >> /\ (modifyOrderBitfield2.value[1] \div 16) % 2 > 0), ReadBytes(manualOrderIndicator.rest, 18), manualOrderIndicator.rest) IN IF ~oeoid.ok THEN Fail ELSE
    LET frequentTraderId == ReadWhen(numberOfModifyOrderBitfields.value >= 2 /\ (modifyOrderBitfield2.value # << >> /\ (modifyOrderBitfield2.value[1] \div 32) % 2 > 0), ReadBytes(oeoid.rest, 6), oeoid.rest) IN IF ~frequentTraderId.ok THEN Fail ELSE
    LET custOrderHandlingInst == ReadWhen(numberOfModifyOrderBitfields.value >= 2 /\ (modifyOrderBitfield2.value # << >> /\ (modifyOrderBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(frequentTraderId.rest, 1), frequentTraderId.rest) IN IF ~custOrderHandlingInst.ok THEN Fail ELSE
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
         stopPx                       |-> stopPx.value,
         manualOrderIndicator         |-> manualOrderIndicator.value,
         oeoid                        |-> oeoid.value,
         frequentTraderId             |-> frequentTraderId.value,
         custOrderHandlingInst        |-> custOrderHandlingInst.value ], custOrderHandlingInst.rest)

(* Modify Order Message with each field marked present by fields before it there exactly where they say *)
SettleModifyOrderMessage(message) ==
    LET settled1 == [message EXCEPT !.modifyOrderBitfield1 = IF message.numberOfModifyOrderBitfields >= 1 THEN (IF message.modifyOrderBitfield1 = << >> THEN <<0>> ELSE message.modifyOrderBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.modifyOrderBitfield2 = IF settled1.numberOfModifyOrderBitfields >= 2 THEN (IF settled1.modifyOrderBitfield2 = << >> THEN <<0>> ELSE settled1.modifyOrderBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.clearingFirm = IF settled2.numberOfModifyOrderBitfields >= 1 /\ (settled2.modifyOrderBitfield1 # << >> /\ settled2.modifyOrderBitfield1[1] % 2 > 0) THEN (IF settled2.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled2.clearingFirm) ELSE << >>]
        settled4 == [settled3 EXCEPT !.orderQty = IF settled3.numberOfModifyOrderBitfields >= 1 /\ (settled3.modifyOrderBitfield1 # << >> /\ (settled3.modifyOrderBitfield1[1] \div 4) % 2 > 0) THEN (IF settled3.orderQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled3.orderQty) ELSE << >>]
        settled5 == [settled4 EXCEPT !.price = IF settled4.numberOfModifyOrderBitfields >= 1 /\ (settled4.modifyOrderBitfield1 # << >> /\ (settled4.modifyOrderBitfield1[1] \div 8) % 2 > 0) THEN (IF settled4.price = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled4.price) ELSE << >>]
        settled6 == [settled5 EXCEPT !.ordType = IF settled5.numberOfModifyOrderBitfields >= 1 /\ (settled5.modifyOrderBitfield1 # << >> /\ (settled5.modifyOrderBitfield1[1] \div 16) % 2 > 0) THEN (IF settled5.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled5.ordType) ELSE << >>]
        settled7 == [settled6 EXCEPT !.cancelOrigOnReject = IF settled6.numberOfModifyOrderBitfields >= 1 /\ (settled6.modifyOrderBitfield1 # << >> /\ (settled6.modifyOrderBitfield1[1] \div 32) % 2 > 0) THEN (IF settled6.cancelOrigOnReject = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.cancelOrigOnReject) ELSE << >>]
        settled8 == [settled7 EXCEPT !.stopPx = IF settled7.numberOfModifyOrderBitfields >= 2 /\ (settled7.modifyOrderBitfield2 # << >> /\ (settled7.modifyOrderBitfield2[1] \div 2) % 2 > 0) THEN (IF settled7.stopPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled7.stopPx) ELSE << >>]
        settled9 == [settled8 EXCEPT !.manualOrderIndicator = IF settled8.numberOfModifyOrderBitfields >= 2 /\ (settled8.modifyOrderBitfield2 # << >> /\ (settled8.modifyOrderBitfield2[1] \div 8) % 2 > 0) THEN (IF settled8.manualOrderIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled8.manualOrderIndicator) ELSE << >>]
        settled10 == [settled9 EXCEPT !.oeoid = IF settled9.numberOfModifyOrderBitfields >= 2 /\ (settled9.modifyOrderBitfield2 # << >> /\ (settled9.modifyOrderBitfield2[1] \div 16) % 2 > 0) THEN (IF settled9.oeoid = << >> THEN <<[i \in 1 .. 18 |-> 0]>> ELSE settled9.oeoid) ELSE << >>]
        settled11 == [settled10 EXCEPT !.frequentTraderId = IF settled10.numberOfModifyOrderBitfields >= 2 /\ (settled10.modifyOrderBitfield2 # << >> /\ (settled10.modifyOrderBitfield2[1] \div 32) % 2 > 0) THEN (IF settled10.frequentTraderId = << >> THEN <<[i \in 1 .. 6 |-> 0]>> ELSE settled10.frequentTraderId) ELSE << >>]
        settled12 == [settled11 EXCEPT !.custOrderHandlingInst = IF settled11.numberOfModifyOrderBitfields >= 2 /\ (settled11.modifyOrderBitfield2 # << >> /\ (settled11.modifyOrderBitfield2[1] \div 64) % 2 > 0) THEN (IF settled11.custOrderHandlingInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.custOrderHandlingInst) ELSE << >>]
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
                               stopPx                       |-> << >>,
                               manualOrderIndicator         |-> << >>,
                               oeoid                        |-> << >>,
                               frequentTraderId             |-> << >>,
                               custOrderHandlingInst        |-> << >> ])

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
        \cup { SettleModifyOrderMessage([ZeroModifyOrderMessage EXCEPT !.numberOfModifyOrderBitfields = 2, !.modifyOrderBitfield2 = <<2>>, !.stopPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleModifyOrderMessage([ZeroModifyOrderMessage EXCEPT !.numberOfModifyOrderBitfields = 2, !.modifyOrderBitfield2 = <<8>>, !.manualOrderIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleModifyOrderMessage([ZeroModifyOrderMessage EXCEPT !.numberOfModifyOrderBitfields = 2, !.modifyOrderBitfield2 = <<16>>, !.oeoid = one]) : one \in { <<held>> : held \in Sample(18) } }
        \cup { SettleModifyOrderMessage([ZeroModifyOrderMessage EXCEPT !.numberOfModifyOrderBitfields = 2, !.modifyOrderBitfield2 = <<32>>, !.frequentTraderId = one]) : one \in { <<held>> : held \in Sample(6) } }
        \cup { SettleModifyOrderMessage([ZeroModifyOrderMessage EXCEPT !.numberOfModifyOrderBitfields = 2, !.modifyOrderBitfield2 = <<64>>, !.custOrderHandlingInst = one]) : one \in { <<held>> : held \in Sample(1) } }

(***************************************************************************)
(* Quote: 32 bytes                                                         *)
(***************************************************************************)

Quote ==
    [ symbolShort : Sample(6),
      side        : Sample(1),
      openClose   : Sample(1),
      price       : Sample(8),
      orderQty    : Sample(4),
      reserved12  : Sample(12) ]

EncodeQuote(message) ==
    message.symbolShort
        \o message.side
        \o message.openClose
        \o message.price
        \o message.orderQty
        \o message.reserved12

DecodeQuote(bytes) ==
    LET symbolShort == ReadBytes(bytes, 6) IN IF ~symbolShort.ok THEN Fail ELSE
    LET side == ReadBytes(symbolShort.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET openClose == ReadBytes(side.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET price == ReadBytes(openClose.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderQty == ReadBytes(price.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET reserved12 == ReadBytes(orderQty.rest, 12) IN IF ~reserved12.ok THEN Fail ELSE
    Ok([ symbolShort |-> symbolShort.value,
         side        |-> side.value,
         openClose   |-> openClose.value,
         price       |-> price.value,
         orderQty    |-> orderQty.value,
         reserved12  |-> reserved12.value ], reserved12.rest)

ZeroQuote ==
    [ symbolShort |-> [i \in 1 .. 6 |-> 0],
      side        |-> [i \in 1 .. 1 |-> 0],
      openClose   |-> [i \in 1 .. 1 |-> 0],
      price       |-> [i \in 1 .. 8 |-> 0],
      orderQty    |-> [i \in 1 .. 4 |-> 0],
      reserved12  |-> [i \in 1 .. 12 |-> 0] ]

(* Quote at zero, then each field in turn at the values it is checked at *)
CheckedQuote ==
    { ZeroQuote }
        \cup { [ZeroQuote EXCEPT !.symbolShort = one] : one \in Sample(6) }
        \cup { [ZeroQuote EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroQuote EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroQuote EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroQuote EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroQuote EXCEPT !.reserved12 = one] : one \in Sample(12) }

(* A run of Quote, written one after another *)
RECURSIVE EncodeQuoteList(_)
EncodeQuoteList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeQuote(Head(messages)) \o EncodeQuoteList(Tail(messages))

(* As many Quote as the field that counts them says *)
RECURSIVE ReadQuoteList(_, _)
ReadQuoteList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeQuote(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadQuoteList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Quote of each kind, for the lists that carry them *)
OneQuote == { ZeroQuote }

(***************************************************************************)
(* Quote Update Message                                                    *)
(***************************************************************************)

QuoteUpdateMessage ==
    [ quoteUpdateId        : Sample(16),
      clearingFirm         : Sample(4),
      clearingAccount      : Sample(4),
      cmtaNumber           : Sample(4),
      account              : Sample(16),
      customGroupId        : Sample(2),
      capacity             : Sample(1),
      ctiCode              : Sample(1),
      manualOrderIndicator : Sample(1),
      oeoid                : Sample(18),
      sizeModifier         : Sample(1),
      reserved6            : Sample(6),
      quote                : SampleLists(OneQuote) ]

EncodeQuoteUpdateMessage(message) ==
    message.quoteUpdateId
        \o message.clearingFirm
        \o message.clearingAccount
        \o message.cmtaNumber
        \o message.account
        \o message.customGroupId
        \o message.capacity
        \o message.ctiCode
        \o message.manualOrderIndicator
        \o message.oeoid
        \o message.sizeModifier
        \o message.reserved6
        \o EncodeUIntBE(Len(message.quote), 1)
        \o EncodeQuoteList(message.quote)

DecodeQuoteUpdateMessage(bytes) ==
    LET quoteUpdateId == ReadBytes(bytes, 16) IN IF ~quoteUpdateId.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(quoteUpdateId.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadBytes(clearingFirm.rest, 4) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET cmtaNumber == ReadBytes(clearingAccount.rest, 4) IN IF ~cmtaNumber.ok THEN Fail ELSE
    LET account == ReadBytes(cmtaNumber.rest, 16) IN IF ~account.ok THEN Fail ELSE
    LET customGroupId == ReadBytes(account.rest, 2) IN IF ~customGroupId.ok THEN Fail ELSE
    LET capacity == ReadBytes(customGroupId.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET ctiCode == ReadBytes(capacity.rest, 1) IN IF ~ctiCode.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadBytes(ctiCode.rest, 1) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET oeoid == ReadBytes(manualOrderIndicator.rest, 18) IN IF ~oeoid.ok THEN Fail ELSE
    LET sizeModifier == ReadBytes(oeoid.rest, 1) IN IF ~sizeModifier.ok THEN Fail ELSE
    LET reserved6 == ReadBytes(sizeModifier.rest, 6) IN IF ~reserved6.ok THEN Fail ELSE
    LET quoteCnt == ReadUIntBE(reserved6.rest, 1) IN IF ~quoteCnt.ok THEN Fail ELSE
    LET quote == ReadQuoteList(quoteCnt.rest, quoteCnt.value) IN IF ~quote.ok THEN Fail ELSE
    Ok([ quoteUpdateId        |-> quoteUpdateId.value,
         clearingFirm         |-> clearingFirm.value,
         clearingAccount      |-> clearingAccount.value,
         cmtaNumber           |-> cmtaNumber.value,
         account              |-> account.value,
         customGroupId        |-> customGroupId.value,
         capacity             |-> capacity.value,
         ctiCode              |-> ctiCode.value,
         manualOrderIndicator |-> manualOrderIndicator.value,
         oeoid                |-> oeoid.value,
         sizeModifier         |-> sizeModifier.value,
         reserved6            |-> reserved6.value,
         quote                |-> quote.value ], quote.rest)

ZeroQuoteUpdateMessage ==
    [ quoteUpdateId        |-> [i \in 1 .. 16 |-> 0],
      clearingFirm         |-> [i \in 1 .. 4 |-> 0],
      clearingAccount      |-> [i \in 1 .. 4 |-> 0],
      cmtaNumber           |-> [i \in 1 .. 4 |-> 0],
      account              |-> [i \in 1 .. 16 |-> 0],
      customGroupId        |-> [i \in 1 .. 2 |-> 0],
      capacity             |-> [i \in 1 .. 1 |-> 0],
      ctiCode              |-> [i \in 1 .. 1 |-> 0],
      manualOrderIndicator |-> [i \in 1 .. 1 |-> 0],
      oeoid                |-> [i \in 1 .. 18 |-> 0],
      sizeModifier         |-> [i \in 1 .. 1 |-> 0],
      reserved6            |-> [i \in 1 .. 6 |-> 0],
      quote                |-> << >> ]

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
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.ctiCode = one] : one \in Sample(1) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.oeoid = one] : one \in Sample(18) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.sizeModifier = one] : one \in Sample(1) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.reserved6 = one] : one \in Sample(6) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.quote = one] : one \in SampleLists(OneQuote) }

(***************************************************************************)
(* Purge Orders Message                                                    *)
(***************************************************************************)

PurgeOrdersMessage ==
    [ reserved1                    : Sample(1),
      numberOfPurgeOrdersBitfields : 0 .. 255,
      purgeOrdersBitfield1         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      purgeOrdersBitfield2         : { << >> } \cup { <<held>> : held \in Sample(1) },
      customGroupIdCnt             : Sample(1),
      customGroupIdOne             : Sample(2),
      customGroupIdn               : Sample(2),
      clearingFirm                 : { << >> } \cup { <<held>> : held \in Sample(4) },
      massCancelInst               : { << >> } \cup { <<held>> : held \in Sample(16) },
      productName                  : { << >> } \cup { <<held>> : held \in Sample(6) },
      massCancelId                 : { << >> } \cup { <<held>> : held \in Sample(20) },
      manualOrderIndicator         : { << >> } \cup { <<held>> : held \in Sample(1) },
      oeoid                        : { << >> } \cup { <<held>> : held \in Sample(18) } ]

EncodePurgeOrdersMessage(message) ==
    message.reserved1
        \o EncodeUIntBE(message.numberOfPurgeOrdersBitfields, 1)
        \o (IF message.purgeOrdersBitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.purgeOrdersBitfield1[1], 1))
        \o (IF message.purgeOrdersBitfield2 = << >> THEN << >> ELSE message.purgeOrdersBitfield2[1])
        \o message.customGroupIdCnt
        \o message.customGroupIdOne
        \o message.customGroupIdn
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])
        \o (IF message.massCancelInst = << >> THEN << >> ELSE message.massCancelInst[1])
        \o (IF message.productName = << >> THEN << >> ELSE message.productName[1])
        \o (IF message.massCancelId = << >> THEN << >> ELSE message.massCancelId[1])
        \o (IF message.manualOrderIndicator = << >> THEN << >> ELSE message.manualOrderIndicator[1])
        \o (IF message.oeoid = << >> THEN << >> ELSE message.oeoid[1])

DecodePurgeOrdersMessage(bytes) ==
    LET reserved1 == ReadBytes(bytes, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET numberOfPurgeOrdersBitfields == ReadUIntBE(reserved1.rest, 1) IN IF ~numberOfPurgeOrdersBitfields.ok THEN Fail ELSE
    LET purgeOrdersBitfield1 == ReadWhen(numberOfPurgeOrdersBitfields.value >= 1, ReadUIntLE(numberOfPurgeOrdersBitfields.rest, 1), numberOfPurgeOrdersBitfields.rest) IN IF ~purgeOrdersBitfield1.ok THEN Fail ELSE
    LET purgeOrdersBitfield2 == ReadWhen(numberOfPurgeOrdersBitfields.value >= 2, ReadBytes(purgeOrdersBitfield1.rest, 1), purgeOrdersBitfield1.rest) IN IF ~purgeOrdersBitfield2.ok THEN Fail ELSE
    LET customGroupIdCnt == ReadBytes(purgeOrdersBitfield2.rest, 1) IN IF ~customGroupIdCnt.ok THEN Fail ELSE
    LET customGroupIdOne == ReadBytes(customGroupIdCnt.rest, 2) IN IF ~customGroupIdOne.ok THEN Fail ELSE
    LET customGroupIdn == ReadBytes(customGroupIdOne.rest, 2) IN IF ~customGroupIdn.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfPurgeOrdersBitfields.value >= 1 /\ (purgeOrdersBitfield1.value # << >> /\ purgeOrdersBitfield1.value[1] % 2 > 0), ReadBytes(customGroupIdn.rest, 4), customGroupIdn.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET massCancelInst == ReadWhen(numberOfPurgeOrdersBitfields.value >= 1 /\ (purgeOrdersBitfield1.value # << >> /\ (purgeOrdersBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(clearingFirm.rest, 16), clearingFirm.rest) IN IF ~massCancelInst.ok THEN Fail ELSE
    LET productName == ReadWhen(numberOfPurgeOrdersBitfields.value >= 1 /\ (purgeOrdersBitfield1.value # << >> /\ (purgeOrdersBitfield1.value[1] \div 8) % 2 > 0), ReadBytes(massCancelInst.rest, 6), massCancelInst.rest) IN IF ~productName.ok THEN Fail ELSE
    LET massCancelId == ReadWhen(numberOfPurgeOrdersBitfields.value >= 1 /\ (purgeOrdersBitfield1.value # << >> /\ (purgeOrdersBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(productName.rest, 20), productName.rest) IN IF ~massCancelId.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadWhen(numberOfPurgeOrdersBitfields.value >= 1 /\ (purgeOrdersBitfield1.value # << >> /\ (purgeOrdersBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(massCancelId.rest, 1), massCancelId.rest) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET oeoid == ReadWhen(numberOfPurgeOrdersBitfields.value >= 1 /\ (purgeOrdersBitfield1.value # << >> /\ (purgeOrdersBitfield1.value[1] \div 128) % 2 > 0), ReadBytes(manualOrderIndicator.rest, 18), manualOrderIndicator.rest) IN IF ~oeoid.ok THEN Fail ELSE
    Ok([ reserved1                    |-> reserved1.value,
         numberOfPurgeOrdersBitfields |-> numberOfPurgeOrdersBitfields.value,
         purgeOrdersBitfield1         |-> purgeOrdersBitfield1.value,
         purgeOrdersBitfield2         |-> purgeOrdersBitfield2.value,
         customGroupIdCnt             |-> customGroupIdCnt.value,
         customGroupIdOne             |-> customGroupIdOne.value,
         customGroupIdn               |-> customGroupIdn.value,
         clearingFirm                 |-> clearingFirm.value,
         massCancelInst               |-> massCancelInst.value,
         productName                  |-> productName.value,
         massCancelId                 |-> massCancelId.value,
         manualOrderIndicator         |-> manualOrderIndicator.value,
         oeoid                        |-> oeoid.value ], oeoid.rest)

(* Purge Orders Message with each field marked present by fields before it there exactly where they say *)
SettlePurgeOrdersMessage(message) ==
    LET settled1 == [message EXCEPT !.purgeOrdersBitfield1 = IF message.numberOfPurgeOrdersBitfields >= 1 THEN (IF message.purgeOrdersBitfield1 = << >> THEN <<0>> ELSE message.purgeOrdersBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.purgeOrdersBitfield2 = IF settled1.numberOfPurgeOrdersBitfields >= 2 THEN (IF settled1.purgeOrdersBitfield2 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled1.purgeOrdersBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.clearingFirm = IF settled2.numberOfPurgeOrdersBitfields >= 1 /\ (settled2.purgeOrdersBitfield1 # << >> /\ settled2.purgeOrdersBitfield1[1] % 2 > 0) THEN (IF settled2.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled2.clearingFirm) ELSE << >>]
        settled4 == [settled3 EXCEPT !.massCancelInst = IF settled3.numberOfPurgeOrdersBitfields >= 1 /\ (settled3.purgeOrdersBitfield1 # << >> /\ (settled3.purgeOrdersBitfield1[1] \div 4) % 2 > 0) THEN (IF settled3.massCancelInst = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled3.massCancelInst) ELSE << >>]
        settled5 == [settled4 EXCEPT !.productName = IF settled4.numberOfPurgeOrdersBitfields >= 1 /\ (settled4.purgeOrdersBitfield1 # << >> /\ (settled4.purgeOrdersBitfield1[1] \div 8) % 2 > 0) THEN (IF settled4.productName = << >> THEN <<[i \in 1 .. 6 |-> 0]>> ELSE settled4.productName) ELSE << >>]
        settled6 == [settled5 EXCEPT !.massCancelId = IF settled5.numberOfPurgeOrdersBitfields >= 1 /\ (settled5.purgeOrdersBitfield1 # << >> /\ (settled5.purgeOrdersBitfield1[1] \div 16) % 2 > 0) THEN (IF settled5.massCancelId = << >> THEN <<[i \in 1 .. 20 |-> 0]>> ELSE settled5.massCancelId) ELSE << >>]
        settled7 == [settled6 EXCEPT !.manualOrderIndicator = IF settled6.numberOfPurgeOrdersBitfields >= 1 /\ (settled6.purgeOrdersBitfield1 # << >> /\ (settled6.purgeOrdersBitfield1[1] \div 64) % 2 > 0) THEN (IF settled6.manualOrderIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.manualOrderIndicator) ELSE << >>]
        settled8 == [settled7 EXCEPT !.oeoid = IF settled7.numberOfPurgeOrdersBitfields >= 1 /\ (settled7.purgeOrdersBitfield1 # << >> /\ (settled7.purgeOrdersBitfield1[1] \div 128) % 2 > 0) THEN (IF settled7.oeoid = << >> THEN <<[i \in 1 .. 18 |-> 0]>> ELSE settled7.oeoid) ELSE << >>]
    IN  settled8

ZeroPurgeOrdersMessage ==
    SettlePurgeOrdersMessage([ reserved1                    |-> [i \in 1 .. 1 |-> 0],
                               numberOfPurgeOrdersBitfields |-> 0,
                               purgeOrdersBitfield1         |-> << >>,
                               purgeOrdersBitfield2         |-> << >>,
                               customGroupIdCnt             |-> [i \in 1 .. 1 |-> 0],
                               customGroupIdOne             |-> [i \in 1 .. 2 |-> 0],
                               customGroupIdn               |-> [i \in 1 .. 2 |-> 0],
                               clearingFirm                 |-> << >>,
                               massCancelInst               |-> << >>,
                               productName                  |-> << >>,
                               massCancelId                 |-> << >>,
                               manualOrderIndicator         |-> << >>,
                               oeoid                        |-> << >> ])

(* Purge Orders Message at zero, then each field in turn at the values it is checked at *)
CheckedPurgeOrdersMessage ==
    { ZeroPurgeOrdersMessage }
        \cup { SettlePurgeOrdersMessage([ZeroPurgeOrdersMessage EXCEPT !.reserved1 = one]) : one \in Sample(1) }
        \cup { SettlePurgeOrdersMessage([ZeroPurgeOrdersMessage EXCEPT !.numberOfPurgeOrdersBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettlePurgeOrdersMessage([ZeroPurgeOrdersMessage EXCEPT !.numberOfPurgeOrdersBitfields = 1, !.purgeOrdersBitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettlePurgeOrdersMessage([ZeroPurgeOrdersMessage EXCEPT !.numberOfPurgeOrdersBitfields = 2, !.purgeOrdersBitfield2 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettlePurgeOrdersMessage([ZeroPurgeOrdersMessage EXCEPT !.customGroupIdCnt = one]) : one \in Sample(1) }
        \cup { SettlePurgeOrdersMessage([ZeroPurgeOrdersMessage EXCEPT !.customGroupIdOne = one]) : one \in Sample(2) }
        \cup { SettlePurgeOrdersMessage([ZeroPurgeOrdersMessage EXCEPT !.customGroupIdn = one]) : one \in Sample(2) }
        \cup { SettlePurgeOrdersMessage([ZeroPurgeOrdersMessage EXCEPT !.numberOfPurgeOrdersBitfields = 1, !.purgeOrdersBitfield1 = <<1>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettlePurgeOrdersMessage([ZeroPurgeOrdersMessage EXCEPT !.numberOfPurgeOrdersBitfields = 1, !.purgeOrdersBitfield1 = <<4>>, !.massCancelInst = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettlePurgeOrdersMessage([ZeroPurgeOrdersMessage EXCEPT !.numberOfPurgeOrdersBitfields = 1, !.purgeOrdersBitfield1 = <<8>>, !.productName = one]) : one \in { <<held>> : held \in Sample(6) } }
        \cup { SettlePurgeOrdersMessage([ZeroPurgeOrdersMessage EXCEPT !.numberOfPurgeOrdersBitfields = 1, !.purgeOrdersBitfield1 = <<16>>, !.massCancelId = one]) : one \in { <<held>> : held \in Sample(20) } }
        \cup { SettlePurgeOrdersMessage([ZeroPurgeOrdersMessage EXCEPT !.numberOfPurgeOrdersBitfields = 1, !.purgeOrdersBitfield1 = <<64>>, !.manualOrderIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettlePurgeOrdersMessage([ZeroPurgeOrdersMessage EXCEPT !.numberOfPurgeOrdersBitfields = 1, !.purgeOrdersBitfield1 = <<128>>, !.oeoid = one]) : one \in { <<held>> : held \in Sample(18) } }

(***************************************************************************)
(* Reset Risk Message: 40 bytes                                            *)
(***************************************************************************)

ResetRiskMessage ==
    [ riskStatusId  : Sample(16),
      riskReset     : Sample(8),
      reserved4     : Sample(4),
      clearingFirm  : Sample(4),
      productName   : Sample(6),
      customGroupId : Sample(2) ]

EncodeResetRiskMessage(message) ==
    message.riskStatusId
        \o message.riskReset
        \o message.reserved4
        \o message.clearingFirm
        \o message.productName
        \o message.customGroupId

DecodeResetRiskMessage(bytes) ==
    LET riskStatusId == ReadBytes(bytes, 16) IN IF ~riskStatusId.ok THEN Fail ELSE
    LET riskReset == ReadBytes(riskStatusId.rest, 8) IN IF ~riskReset.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(riskReset.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(reserved4.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET productName == ReadBytes(clearingFirm.rest, 6) IN IF ~productName.ok THEN Fail ELSE
    LET customGroupId == ReadBytes(productName.rest, 2) IN IF ~customGroupId.ok THEN Fail ELSE
    Ok([ riskStatusId  |-> riskStatusId.value,
         riskReset     |-> riskReset.value,
         reserved4     |-> reserved4.value,
         clearingFirm  |-> clearingFirm.value,
         productName   |-> productName.value,
         customGroupId |-> customGroupId.value ], customGroupId.rest)

ZeroResetRiskMessage ==
    [ riskStatusId  |-> [i \in 1 .. 16 |-> 0],
      riskReset     |-> [i \in 1 .. 8 |-> 0],
      reserved4     |-> [i \in 1 .. 4 |-> 0],
      clearingFirm  |-> [i \in 1 .. 4 |-> 0],
      productName   |-> [i \in 1 .. 6 |-> 0],
      customGroupId |-> [i \in 1 .. 2 |-> 0] ]

(* Reset Risk Message at zero, then each field in turn at the values it is checked at *)
CheckedResetRiskMessage ==
    { ZeroResetRiskMessage }
        \cup { [ZeroResetRiskMessage EXCEPT !.riskStatusId = one] : one \in Sample(16) }
        \cup { [ZeroResetRiskMessage EXCEPT !.riskReset = one] : one \in Sample(8) }
        \cup { [ZeroResetRiskMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroResetRiskMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroResetRiskMessage EXCEPT !.productName = one] : one \in Sample(6) }
        \cup { [ZeroResetRiskMessage EXCEPT !.customGroupId = one] : one \in Sample(2) }

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
      orderAcknowledgmentReturnBitfield4  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderAcknowledgmentReturnBitfield5  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderAcknowledgmentReturnBitfield6  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield7  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderAcknowledgmentReturnBitfield8  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderAcknowledgmentReturnBitfield9  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderAcknowledgmentReturnBitfield10 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield11 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield12 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderAcknowledgmentReturnBitfield13 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderAcknowledgmentReturnBitfield14 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield15 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderAcknowledgmentReturnBitfield16 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderAcknowledgmentReturnBitfield17 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderAcknowledgmentReturnBitfield18 : { << >> } \cup { <<held>> : held \in Sample(1) },
      side                                : { << >> } \cup { <<held>> : held \in Sample(1) },
      price                               : { << >> } \cup { <<held>> : held \in Sample(8) },
      ordType                             : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce                         : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                              : { << >> } \cup { <<held>> : held \in Sample(4) },
      symbolLong                          : { << >> } \cup { <<held>> : held \in Sample(8) },
      capacity                            : { << >> } \cup { <<held>> : held \in Sample(1) },
      account                             : { << >> } \cup { <<held>> : held \in Sample(16) },
      clearingFirm                        : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingAccount                     : { << >> } \cup { <<held>> : held \in Sample(4) },
      orderQty                            : { << >> } \cup { <<held>> : held \in Sample(4) },
      preventMatch                        : { << >> } \cup { <<held>> : held \in Sample(3) },
      maturityDate                        : { << >> } \cup { <<held>> : held \in Sample(4) },
      openClose                           : { << >> } \cup { <<held>> : held \in Sample(1) },
      leavesQty                           : { << >> } \cup { <<held>> : held \in Sample(4) },
      baseLiquidityIndicator              : { << >> } \cup { <<held>> : held \in Sample(1) },
      expireTime                          : { << >> } \cup { <<held>> : held \in Sample(8) },
      subLiquidityIndicator               : { << >> } \cup { <<held>> : held \in Sample(1) },
      stopPx                              : { << >> } \cup { <<held>> : held \in Sample(8) },
      cmtaNumber                          : { << >> } \cup { <<held>> : held \in Sample(4) },
      ctiCode                             : { << >> } \cup { <<held>> : held \in Sample(1) },
      manualOrderIndicator                : { << >> } \cup { <<held>> : held \in Sample(1) },
      oeoid                               : { << >> } \cup { <<held>> : held \in Sample(18) },
      cumQty                              : { << >> } \cup { <<held>> : held \in Sample(4) },
      dayOrderQty                         : { << >> } \cup { <<held>> : held \in Sample(4) },
      dayCumQty                           : { << >> } \cup { <<held>> : held \in Sample(4) },
      avgPx                               : { << >> } \cup { <<held>> : held \in Sample(8) },
      dayAvgPx                            : { << >> } \cup { <<held>> : held \in Sample(8) },
      frequentTraderId                    : { << >> } \cup { <<held>> : held \in Sample(6) },
      custOrderHandlingInst               : { << >> } \cup { <<held>> : held \in Sample(1) } ]

EncodeOrderAcknowledgmentMessage(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.orderId
        \o message.reserved1
        \o EncodeUIntBE(message.numberOfReturnBitfields, 1)
        \o (IF message.orderAcknowledgmentReturnBitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.orderAcknowledgmentReturnBitfield1[1], 1))
        \o (IF message.orderAcknowledgmentReturnBitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.orderAcknowledgmentReturnBitfield2[1], 1))
        \o (IF message.orderAcknowledgmentReturnBitfield3 = << >> THEN << >> ELSE EncodeUIntLE(message.orderAcknowledgmentReturnBitfield3[1], 1))
        \o (IF message.orderAcknowledgmentReturnBitfield4 = << >> THEN << >> ELSE EncodeUIntLE(message.orderAcknowledgmentReturnBitfield4[1], 1))
        \o (IF message.orderAcknowledgmentReturnBitfield5 = << >> THEN << >> ELSE EncodeUIntLE(message.orderAcknowledgmentReturnBitfield5[1], 1))
        \o (IF message.orderAcknowledgmentReturnBitfield6 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield6[1])
        \o (IF message.orderAcknowledgmentReturnBitfield7 = << >> THEN << >> ELSE EncodeUIntLE(message.orderAcknowledgmentReturnBitfield7[1], 1))
        \o (IF message.orderAcknowledgmentReturnBitfield8 = << >> THEN << >> ELSE EncodeUIntLE(message.orderAcknowledgmentReturnBitfield8[1], 1))
        \o (IF message.orderAcknowledgmentReturnBitfield9 = << >> THEN << >> ELSE EncodeUIntLE(message.orderAcknowledgmentReturnBitfield9[1], 1))
        \o (IF message.orderAcknowledgmentReturnBitfield10 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield10[1])
        \o (IF message.orderAcknowledgmentReturnBitfield11 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield11[1])
        \o (IF message.orderAcknowledgmentReturnBitfield12 = << >> THEN << >> ELSE EncodeUIntLE(message.orderAcknowledgmentReturnBitfield12[1], 1))
        \o (IF message.orderAcknowledgmentReturnBitfield13 = << >> THEN << >> ELSE EncodeUIntLE(message.orderAcknowledgmentReturnBitfield13[1], 1))
        \o (IF message.orderAcknowledgmentReturnBitfield14 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield14[1])
        \o (IF message.orderAcknowledgmentReturnBitfield15 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield15[1])
        \o (IF message.orderAcknowledgmentReturnBitfield16 = << >> THEN << >> ELSE EncodeUIntLE(message.orderAcknowledgmentReturnBitfield16[1], 1))
        \o (IF message.orderAcknowledgmentReturnBitfield17 = << >> THEN << >> ELSE EncodeUIntLE(message.orderAcknowledgmentReturnBitfield17[1], 1))
        \o (IF message.orderAcknowledgmentReturnBitfield18 = << >> THEN << >> ELSE message.orderAcknowledgmentReturnBitfield18[1])
        \o (IF message.side = << >> THEN << >> ELSE message.side[1])
        \o (IF message.price = << >> THEN << >> ELSE message.price[1])
        \o (IF message.ordType = << >> THEN << >> ELSE message.ordType[1])
        \o (IF message.timeInForce = << >> THEN << >> ELSE message.timeInForce[1])
        \o (IF message.minQty = << >> THEN << >> ELSE message.minQty[1])
        \o (IF message.symbolLong = << >> THEN << >> ELSE message.symbolLong[1])
        \o (IF message.capacity = << >> THEN << >> ELSE message.capacity[1])
        \o (IF message.account = << >> THEN << >> ELSE message.account[1])
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])
        \o (IF message.clearingAccount = << >> THEN << >> ELSE message.clearingAccount[1])
        \o (IF message.orderQty = << >> THEN << >> ELSE message.orderQty[1])
        \o (IF message.preventMatch = << >> THEN << >> ELSE message.preventMatch[1])
        \o (IF message.maturityDate = << >> THEN << >> ELSE message.maturityDate[1])
        \o (IF message.openClose = << >> THEN << >> ELSE message.openClose[1])
        \o (IF message.leavesQty = << >> THEN << >> ELSE message.leavesQty[1])
        \o (IF message.baseLiquidityIndicator = << >> THEN << >> ELSE message.baseLiquidityIndicator[1])
        \o (IF message.expireTime = << >> THEN << >> ELSE message.expireTime[1])
        \o (IF message.subLiquidityIndicator = << >> THEN << >> ELSE message.subLiquidityIndicator[1])
        \o (IF message.stopPx = << >> THEN << >> ELSE message.stopPx[1])
        \o (IF message.cmtaNumber = << >> THEN << >> ELSE message.cmtaNumber[1])
        \o (IF message.ctiCode = << >> THEN << >> ELSE message.ctiCode[1])
        \o (IF message.manualOrderIndicator = << >> THEN << >> ELSE message.manualOrderIndicator[1])
        \o (IF message.oeoid = << >> THEN << >> ELSE message.oeoid[1])
        \o (IF message.cumQty = << >> THEN << >> ELSE message.cumQty[1])
        \o (IF message.dayOrderQty = << >> THEN << >> ELSE message.dayOrderQty[1])
        \o (IF message.dayCumQty = << >> THEN << >> ELSE message.dayCumQty[1])
        \o (IF message.avgPx = << >> THEN << >> ELSE message.avgPx[1])
        \o (IF message.dayAvgPx = << >> THEN << >> ELSE message.dayAvgPx[1])
        \o (IF message.frequentTraderId = << >> THEN << >> ELSE message.frequentTraderId[1])
        \o (IF message.custOrderHandlingInst = << >> THEN << >> ELSE message.custOrderHandlingInst[1])

DecodeOrderAcknowledgmentMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clOrdId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(orderId.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET numberOfReturnBitfields == ReadUIntBE(reserved1.rest, 1) IN IF ~numberOfReturnBitfields.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield1 == ReadWhen(numberOfReturnBitfields.value >= 1, ReadUIntLE(numberOfReturnBitfields.rest, 1), numberOfReturnBitfields.rest) IN IF ~orderAcknowledgmentReturnBitfield1.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield2 == ReadWhen(numberOfReturnBitfields.value >= 2, ReadUIntLE(orderAcknowledgmentReturnBitfield1.rest, 1), orderAcknowledgmentReturnBitfield1.rest) IN IF ~orderAcknowledgmentReturnBitfield2.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield3 == ReadWhen(numberOfReturnBitfields.value >= 3, ReadUIntLE(orderAcknowledgmentReturnBitfield2.rest, 1), orderAcknowledgmentReturnBitfield2.rest) IN IF ~orderAcknowledgmentReturnBitfield3.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadUIntLE(orderAcknowledgmentReturnBitfield3.rest, 1), orderAcknowledgmentReturnBitfield3.rest) IN IF ~orderAcknowledgmentReturnBitfield4.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadUIntLE(orderAcknowledgmentReturnBitfield4.rest, 1), orderAcknowledgmentReturnBitfield4.rest) IN IF ~orderAcknowledgmentReturnBitfield5.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadBytes(orderAcknowledgmentReturnBitfield5.rest, 1), orderAcknowledgmentReturnBitfield5.rest) IN IF ~orderAcknowledgmentReturnBitfield6.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadUIntLE(orderAcknowledgmentReturnBitfield6.rest, 1), orderAcknowledgmentReturnBitfield6.rest) IN IF ~orderAcknowledgmentReturnBitfield7.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadUIntLE(orderAcknowledgmentReturnBitfield7.rest, 1), orderAcknowledgmentReturnBitfield7.rest) IN IF ~orderAcknowledgmentReturnBitfield8.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadUIntLE(orderAcknowledgmentReturnBitfield8.rest, 1), orderAcknowledgmentReturnBitfield8.rest) IN IF ~orderAcknowledgmentReturnBitfield9.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadBytes(orderAcknowledgmentReturnBitfield9.rest, 1), orderAcknowledgmentReturnBitfield9.rest) IN IF ~orderAcknowledgmentReturnBitfield10.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadBytes(orderAcknowledgmentReturnBitfield10.rest, 1), orderAcknowledgmentReturnBitfield10.rest) IN IF ~orderAcknowledgmentReturnBitfield11.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadUIntLE(orderAcknowledgmentReturnBitfield11.rest, 1), orderAcknowledgmentReturnBitfield11.rest) IN IF ~orderAcknowledgmentReturnBitfield12.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadUIntLE(orderAcknowledgmentReturnBitfield12.rest, 1), orderAcknowledgmentReturnBitfield12.rest) IN IF ~orderAcknowledgmentReturnBitfield13.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(orderAcknowledgmentReturnBitfield13.rest, 1), orderAcknowledgmentReturnBitfield13.rest) IN IF ~orderAcknowledgmentReturnBitfield14.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield15 == ReadWhen(numberOfReturnBitfields.value >= 15, ReadBytes(orderAcknowledgmentReturnBitfield14.rest, 1), orderAcknowledgmentReturnBitfield14.rest) IN IF ~orderAcknowledgmentReturnBitfield15.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield16 == ReadWhen(numberOfReturnBitfields.value >= 16, ReadUIntLE(orderAcknowledgmentReturnBitfield15.rest, 1), orderAcknowledgmentReturnBitfield15.rest) IN IF ~orderAcknowledgmentReturnBitfield16.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield17 == ReadWhen(numberOfReturnBitfields.value >= 17, ReadUIntLE(orderAcknowledgmentReturnBitfield16.rest, 1), orderAcknowledgmentReturnBitfield16.rest) IN IF ~orderAcknowledgmentReturnBitfield17.ok THEN Fail ELSE
    LET orderAcknowledgmentReturnBitfield18 == ReadWhen(numberOfReturnBitfields.value >= 18, ReadBytes(orderAcknowledgmentReturnBitfield17.rest, 1), orderAcknowledgmentReturnBitfield17.rest) IN IF ~orderAcknowledgmentReturnBitfield18.ok THEN Fail ELSE
    LET side == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderAcknowledgmentReturnBitfield1.value # << >> /\ orderAcknowledgmentReturnBitfield1.value[1] % 2 > 0), ReadBytes(orderAcknowledgmentReturnBitfield18.rest, 1), orderAcknowledgmentReturnBitfield18.rest) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderAcknowledgmentReturnBitfield1.value # << >> /\ (orderAcknowledgmentReturnBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(side.rest, 8), side.rest) IN IF ~price.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderAcknowledgmentReturnBitfield1.value # << >> /\ (orderAcknowledgmentReturnBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(price.rest, 1), price.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderAcknowledgmentReturnBitfield1.value # << >> /\ (orderAcknowledgmentReturnBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderAcknowledgmentReturnBitfield1.value # << >> /\ (orderAcknowledgmentReturnBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET symbolLong == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderAcknowledgmentReturnBitfield2.value # << >> /\ orderAcknowledgmentReturnBitfield2.value[1] % 2 > 0), ReadBytes(minQty.rest, 8), minQty.rest) IN IF ~symbolLong.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderAcknowledgmentReturnBitfield2.value # << >> /\ (orderAcknowledgmentReturnBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(symbolLong.rest, 1), symbolLong.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderAcknowledgmentReturnBitfield3.value # << >> /\ orderAcknowledgmentReturnBitfield3.value[1] % 2 > 0), ReadBytes(capacity.rest, 16), capacity.rest) IN IF ~account.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderAcknowledgmentReturnBitfield3.value # << >> /\ (orderAcknowledgmentReturnBitfield3.value[1] \div 2) % 2 > 0), ReadBytes(account.rest, 4), account.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderAcknowledgmentReturnBitfield3.value # << >> /\ (orderAcknowledgmentReturnBitfield3.value[1] \div 4) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET orderQty == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderAcknowledgmentReturnBitfield3.value # << >> /\ (orderAcknowledgmentReturnBitfield3.value[1] \div 64) % 2 > 0), ReadBytes(clearingAccount.rest, 4), clearingAccount.rest) IN IF ~orderQty.ok THEN Fail ELSE
    LET preventMatch == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderAcknowledgmentReturnBitfield3.value # << >> /\ (orderAcknowledgmentReturnBitfield3.value[1] \div 128) % 2 > 0), ReadBytes(orderQty.rest, 3), orderQty.rest) IN IF ~preventMatch.ok THEN Fail ELSE
    LET maturityDate == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (orderAcknowledgmentReturnBitfield4.value # << >> /\ orderAcknowledgmentReturnBitfield4.value[1] % 2 > 0), ReadBytes(preventMatch.rest, 4), preventMatch.rest) IN IF ~maturityDate.ok THEN Fail ELSE
    LET openClose == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (orderAcknowledgmentReturnBitfield4.value # << >> /\ (orderAcknowledgmentReturnBitfield4.value[1] \div 8) % 2 > 0), ReadBytes(maturityDate.rest, 1), maturityDate.rest) IN IF ~openClose.ok THEN Fail ELSE
    LET leavesQty == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderAcknowledgmentReturnBitfield5.value # << >> /\ (orderAcknowledgmentReturnBitfield5.value[1] \div 2) % 2 > 0), ReadBytes(openClose.rest, 4), openClose.rest) IN IF ~leavesQty.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderAcknowledgmentReturnBitfield5.value # << >> /\ (orderAcknowledgmentReturnBitfield5.value[1] \div 64) % 2 > 0), ReadBytes(leavesQty.rest, 1), leavesQty.rest) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET expireTime == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderAcknowledgmentReturnBitfield5.value # << >> /\ (orderAcknowledgmentReturnBitfield5.value[1] \div 128) % 2 > 0), ReadBytes(baseLiquidityIndicator.rest, 8), baseLiquidityIndicator.rest) IN IF ~expireTime.ok THEN Fail ELSE
    LET subLiquidityIndicator == ReadWhen(numberOfReturnBitfields.value >= 7 /\ (orderAcknowledgmentReturnBitfield7.value # << >> /\ orderAcknowledgmentReturnBitfield7.value[1] % 2 > 0), ReadBytes(expireTime.rest, 1), expireTime.rest) IN IF ~subLiquidityIndicator.ok THEN Fail ELSE
    LET stopPx == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderAcknowledgmentReturnBitfield8.value # << >> /\ (orderAcknowledgmentReturnBitfield8.value[1] \div 4) % 2 > 0), ReadBytes(subLiquidityIndicator.rest, 8), subLiquidityIndicator.rest) IN IF ~stopPx.ok THEN Fail ELSE
    LET cmtaNumber == ReadWhen(numberOfReturnBitfields.value >= 9 /\ (orderAcknowledgmentReturnBitfield9.value # << >> /\ (orderAcknowledgmentReturnBitfield9.value[1] \div 32) % 2 > 0), ReadBytes(stopPx.rest, 4), stopPx.rest) IN IF ~cmtaNumber.ok THEN Fail ELSE
    LET ctiCode == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (orderAcknowledgmentReturnBitfield12.value # << >> /\ orderAcknowledgmentReturnBitfield12.value[1] % 2 > 0), ReadBytes(cmtaNumber.rest, 1), cmtaNumber.rest) IN IF ~ctiCode.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (orderAcknowledgmentReturnBitfield12.value # << >> /\ (orderAcknowledgmentReturnBitfield12.value[1] \div 2) % 2 > 0), ReadBytes(ctiCode.rest, 1), ctiCode.rest) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET oeoid == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (orderAcknowledgmentReturnBitfield12.value # << >> /\ (orderAcknowledgmentReturnBitfield12.value[1] \div 4) % 2 > 0), ReadBytes(manualOrderIndicator.rest, 18), manualOrderIndicator.rest) IN IF ~oeoid.ok THEN Fail ELSE
    LET cumQty == ReadWhen(numberOfReturnBitfields.value >= 13 /\ (orderAcknowledgmentReturnBitfield13.value # << >> /\ orderAcknowledgmentReturnBitfield13.value[1] % 2 > 0), ReadBytes(oeoid.rest, 4), oeoid.rest) IN IF ~cumQty.ok THEN Fail ELSE
    LET dayOrderQty == ReadWhen(numberOfReturnBitfields.value >= 13 /\ (orderAcknowledgmentReturnBitfield13.value # << >> /\ (orderAcknowledgmentReturnBitfield13.value[1] \div 2) % 2 > 0), ReadBytes(cumQty.rest, 4), cumQty.rest) IN IF ~dayOrderQty.ok THEN Fail ELSE
    LET dayCumQty == ReadWhen(numberOfReturnBitfields.value >= 13 /\ (orderAcknowledgmentReturnBitfield13.value # << >> /\ (orderAcknowledgmentReturnBitfield13.value[1] \div 4) % 2 > 0), ReadBytes(dayOrderQty.rest, 4), dayOrderQty.rest) IN IF ~dayCumQty.ok THEN Fail ELSE
    LET avgPx == ReadWhen(numberOfReturnBitfields.value >= 13 /\ (orderAcknowledgmentReturnBitfield13.value # << >> /\ (orderAcknowledgmentReturnBitfield13.value[1] \div 8) % 2 > 0), ReadBytes(dayCumQty.rest, 8), dayCumQty.rest) IN IF ~avgPx.ok THEN Fail ELSE
    LET dayAvgPx == ReadWhen(numberOfReturnBitfields.value >= 13 /\ (orderAcknowledgmentReturnBitfield13.value # << >> /\ (orderAcknowledgmentReturnBitfield13.value[1] \div 16) % 2 > 0), ReadBytes(avgPx.rest, 8), avgPx.rest) IN IF ~dayAvgPx.ok THEN Fail ELSE
    LET frequentTraderId == ReadWhen(numberOfReturnBitfields.value >= 16 /\ (orderAcknowledgmentReturnBitfield16.value # << >> /\ orderAcknowledgmentReturnBitfield16.value[1] % 2 > 0), ReadBytes(dayAvgPx.rest, 6), dayAvgPx.rest) IN IF ~frequentTraderId.ok THEN Fail ELSE
    LET custOrderHandlingInst == ReadWhen(numberOfReturnBitfields.value >= 17 /\ (orderAcknowledgmentReturnBitfield17.value # << >> /\ (orderAcknowledgmentReturnBitfield17.value[1] \div 128) % 2 > 0), ReadBytes(frequentTraderId.rest, 1), frequentTraderId.rest) IN IF ~custOrderHandlingInst.ok THEN Fail ELSE
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
         side                                |-> side.value,
         price                               |-> price.value,
         ordType                             |-> ordType.value,
         timeInForce                         |-> timeInForce.value,
         minQty                              |-> minQty.value,
         symbolLong                          |-> symbolLong.value,
         capacity                            |-> capacity.value,
         account                             |-> account.value,
         clearingFirm                        |-> clearingFirm.value,
         clearingAccount                     |-> clearingAccount.value,
         orderQty                            |-> orderQty.value,
         preventMatch                        |-> preventMatch.value,
         maturityDate                        |-> maturityDate.value,
         openClose                           |-> openClose.value,
         leavesQty                           |-> leavesQty.value,
         baseLiquidityIndicator              |-> baseLiquidityIndicator.value,
         expireTime                          |-> expireTime.value,
         subLiquidityIndicator               |-> subLiquidityIndicator.value,
         stopPx                              |-> stopPx.value,
         cmtaNumber                          |-> cmtaNumber.value,
         ctiCode                             |-> ctiCode.value,
         manualOrderIndicator                |-> manualOrderIndicator.value,
         oeoid                               |-> oeoid.value,
         cumQty                              |-> cumQty.value,
         dayOrderQty                         |-> dayOrderQty.value,
         dayCumQty                           |-> dayCumQty.value,
         avgPx                               |-> avgPx.value,
         dayAvgPx                            |-> dayAvgPx.value,
         frequentTraderId                    |-> frequentTraderId.value,
         custOrderHandlingInst               |-> custOrderHandlingInst.value ], custOrderHandlingInst.rest)

(* Order Acknowledgment Message with each field marked present by fields before it there exactly where they say *)
SettleOrderAcknowledgmentMessage(message) ==
    LET settled1 == [message EXCEPT !.orderAcknowledgmentReturnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.orderAcknowledgmentReturnBitfield1 = << >> THEN <<0>> ELSE message.orderAcknowledgmentReturnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.orderAcknowledgmentReturnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.orderAcknowledgmentReturnBitfield2 = << >> THEN <<0>> ELSE settled1.orderAcknowledgmentReturnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.orderAcknowledgmentReturnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.orderAcknowledgmentReturnBitfield3 = << >> THEN <<0>> ELSE settled2.orderAcknowledgmentReturnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.orderAcknowledgmentReturnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.orderAcknowledgmentReturnBitfield4 = << >> THEN <<0>> ELSE settled3.orderAcknowledgmentReturnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.orderAcknowledgmentReturnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.orderAcknowledgmentReturnBitfield5 = << >> THEN <<0>> ELSE settled4.orderAcknowledgmentReturnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.orderAcknowledgmentReturnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.orderAcknowledgmentReturnBitfield6 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled5.orderAcknowledgmentReturnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.orderAcknowledgmentReturnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.orderAcknowledgmentReturnBitfield7 = << >> THEN <<0>> ELSE settled6.orderAcknowledgmentReturnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.orderAcknowledgmentReturnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.orderAcknowledgmentReturnBitfield8 = << >> THEN <<0>> ELSE settled7.orderAcknowledgmentReturnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.orderAcknowledgmentReturnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.orderAcknowledgmentReturnBitfield9 = << >> THEN <<0>> ELSE settled8.orderAcknowledgmentReturnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.orderAcknowledgmentReturnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.orderAcknowledgmentReturnBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.orderAcknowledgmentReturnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.orderAcknowledgmentReturnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.orderAcknowledgmentReturnBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.orderAcknowledgmentReturnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.orderAcknowledgmentReturnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.orderAcknowledgmentReturnBitfield12 = << >> THEN <<0>> ELSE settled11.orderAcknowledgmentReturnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.orderAcknowledgmentReturnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.orderAcknowledgmentReturnBitfield13 = << >> THEN <<0>> ELSE settled12.orderAcknowledgmentReturnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.orderAcknowledgmentReturnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.orderAcknowledgmentReturnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.orderAcknowledgmentReturnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.orderAcknowledgmentReturnBitfield15 = IF settled14.numberOfReturnBitfields >= 15 THEN (IF settled14.orderAcknowledgmentReturnBitfield15 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.orderAcknowledgmentReturnBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.orderAcknowledgmentReturnBitfield16 = IF settled15.numberOfReturnBitfields >= 16 THEN (IF settled15.orderAcknowledgmentReturnBitfield16 = << >> THEN <<0>> ELSE settled15.orderAcknowledgmentReturnBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.orderAcknowledgmentReturnBitfield17 = IF settled16.numberOfReturnBitfields >= 17 THEN (IF settled16.orderAcknowledgmentReturnBitfield17 = << >> THEN <<0>> ELSE settled16.orderAcknowledgmentReturnBitfield17) ELSE << >>]
        settled18 == [settled17 EXCEPT !.orderAcknowledgmentReturnBitfield18 = IF settled17.numberOfReturnBitfields >= 18 THEN (IF settled17.orderAcknowledgmentReturnBitfield18 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.orderAcknowledgmentReturnBitfield18) ELSE << >>]
        settled19 == [settled18 EXCEPT !.side = IF settled18.numberOfReturnBitfields >= 1 /\ (settled18.orderAcknowledgmentReturnBitfield1 # << >> /\ settled18.orderAcknowledgmentReturnBitfield1[1] % 2 > 0) THEN (IF settled18.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled18.side) ELSE << >>]
        settled20 == [settled19 EXCEPT !.price = IF settled19.numberOfReturnBitfields >= 1 /\ (settled19.orderAcknowledgmentReturnBitfield1 # << >> /\ (settled19.orderAcknowledgmentReturnBitfield1[1] \div 4) % 2 > 0) THEN (IF settled19.price = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled19.price) ELSE << >>]
        settled21 == [settled20 EXCEPT !.ordType = IF settled20.numberOfReturnBitfields >= 1 /\ (settled20.orderAcknowledgmentReturnBitfield1 # << >> /\ (settled20.orderAcknowledgmentReturnBitfield1[1] \div 16) % 2 > 0) THEN (IF settled20.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled20.ordType) ELSE << >>]
        settled22 == [settled21 EXCEPT !.timeInForce = IF settled21.numberOfReturnBitfields >= 1 /\ (settled21.orderAcknowledgmentReturnBitfield1 # << >> /\ (settled21.orderAcknowledgmentReturnBitfield1[1] \div 32) % 2 > 0) THEN (IF settled21.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled21.timeInForce) ELSE << >>]
        settled23 == [settled22 EXCEPT !.minQty = IF settled22.numberOfReturnBitfields >= 1 /\ (settled22.orderAcknowledgmentReturnBitfield1 # << >> /\ (settled22.orderAcknowledgmentReturnBitfield1[1] \div 64) % 2 > 0) THEN (IF settled22.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled22.minQty) ELSE << >>]
        settled24 == [settled23 EXCEPT !.symbolLong = IF settled23.numberOfReturnBitfields >= 2 /\ (settled23.orderAcknowledgmentReturnBitfield2 # << >> /\ settled23.orderAcknowledgmentReturnBitfield2[1] % 2 > 0) THEN (IF settled23.symbolLong = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled23.symbolLong) ELSE << >>]
        settled25 == [settled24 EXCEPT !.capacity = IF settled24.numberOfReturnBitfields >= 2 /\ (settled24.orderAcknowledgmentReturnBitfield2 # << >> /\ (settled24.orderAcknowledgmentReturnBitfield2[1] \div 64) % 2 > 0) THEN (IF settled24.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled24.capacity) ELSE << >>]
        settled26 == [settled25 EXCEPT !.account = IF settled25.numberOfReturnBitfields >= 3 /\ (settled25.orderAcknowledgmentReturnBitfield3 # << >> /\ settled25.orderAcknowledgmentReturnBitfield3[1] % 2 > 0) THEN (IF settled25.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled25.account) ELSE << >>]
        settled27 == [settled26 EXCEPT !.clearingFirm = IF settled26.numberOfReturnBitfields >= 3 /\ (settled26.orderAcknowledgmentReturnBitfield3 # << >> /\ (settled26.orderAcknowledgmentReturnBitfield3[1] \div 2) % 2 > 0) THEN (IF settled26.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled26.clearingFirm) ELSE << >>]
        settled28 == [settled27 EXCEPT !.clearingAccount = IF settled27.numberOfReturnBitfields >= 3 /\ (settled27.orderAcknowledgmentReturnBitfield3 # << >> /\ (settled27.orderAcknowledgmentReturnBitfield3[1] \div 4) % 2 > 0) THEN (IF settled27.clearingAccount = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled27.clearingAccount) ELSE << >>]
        settled29 == [settled28 EXCEPT !.orderQty = IF settled28.numberOfReturnBitfields >= 3 /\ (settled28.orderAcknowledgmentReturnBitfield3 # << >> /\ (settled28.orderAcknowledgmentReturnBitfield3[1] \div 64) % 2 > 0) THEN (IF settled28.orderQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled28.orderQty) ELSE << >>]
        settled30 == [settled29 EXCEPT !.preventMatch = IF settled29.numberOfReturnBitfields >= 3 /\ (settled29.orderAcknowledgmentReturnBitfield3 # << >> /\ (settled29.orderAcknowledgmentReturnBitfield3[1] \div 128) % 2 > 0) THEN (IF settled29.preventMatch = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled29.preventMatch) ELSE << >>]
        settled31 == [settled30 EXCEPT !.maturityDate = IF settled30.numberOfReturnBitfields >= 4 /\ (settled30.orderAcknowledgmentReturnBitfield4 # << >> /\ settled30.orderAcknowledgmentReturnBitfield4[1] % 2 > 0) THEN (IF settled30.maturityDate = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled30.maturityDate) ELSE << >>]
        settled32 == [settled31 EXCEPT !.openClose = IF settled31.numberOfReturnBitfields >= 4 /\ (settled31.orderAcknowledgmentReturnBitfield4 # << >> /\ (settled31.orderAcknowledgmentReturnBitfield4[1] \div 8) % 2 > 0) THEN (IF settled31.openClose = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled31.openClose) ELSE << >>]
        settled33 == [settled32 EXCEPT !.leavesQty = IF settled32.numberOfReturnBitfields >= 5 /\ (settled32.orderAcknowledgmentReturnBitfield5 # << >> /\ (settled32.orderAcknowledgmentReturnBitfield5[1] \div 2) % 2 > 0) THEN (IF settled32.leavesQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled32.leavesQty) ELSE << >>]
        settled34 == [settled33 EXCEPT !.baseLiquidityIndicator = IF settled33.numberOfReturnBitfields >= 5 /\ (settled33.orderAcknowledgmentReturnBitfield5 # << >> /\ (settled33.orderAcknowledgmentReturnBitfield5[1] \div 64) % 2 > 0) THEN (IF settled33.baseLiquidityIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled33.baseLiquidityIndicator) ELSE << >>]
        settled35 == [settled34 EXCEPT !.expireTime = IF settled34.numberOfReturnBitfields >= 5 /\ (settled34.orderAcknowledgmentReturnBitfield5 # << >> /\ (settled34.orderAcknowledgmentReturnBitfield5[1] \div 128) % 2 > 0) THEN (IF settled34.expireTime = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled34.expireTime) ELSE << >>]
        settled36 == [settled35 EXCEPT !.subLiquidityIndicator = IF settled35.numberOfReturnBitfields >= 7 /\ (settled35.orderAcknowledgmentReturnBitfield7 # << >> /\ settled35.orderAcknowledgmentReturnBitfield7[1] % 2 > 0) THEN (IF settled35.subLiquidityIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled35.subLiquidityIndicator) ELSE << >>]
        settled37 == [settled36 EXCEPT !.stopPx = IF settled36.numberOfReturnBitfields >= 8 /\ (settled36.orderAcknowledgmentReturnBitfield8 # << >> /\ (settled36.orderAcknowledgmentReturnBitfield8[1] \div 4) % 2 > 0) THEN (IF settled36.stopPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled36.stopPx) ELSE << >>]
        settled38 == [settled37 EXCEPT !.cmtaNumber = IF settled37.numberOfReturnBitfields >= 9 /\ (settled37.orderAcknowledgmentReturnBitfield9 # << >> /\ (settled37.orderAcknowledgmentReturnBitfield9[1] \div 32) % 2 > 0) THEN (IF settled37.cmtaNumber = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled37.cmtaNumber) ELSE << >>]
        settled39 == [settled38 EXCEPT !.ctiCode = IF settled38.numberOfReturnBitfields >= 12 /\ (settled38.orderAcknowledgmentReturnBitfield12 # << >> /\ settled38.orderAcknowledgmentReturnBitfield12[1] % 2 > 0) THEN (IF settled38.ctiCode = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled38.ctiCode) ELSE << >>]
        settled40 == [settled39 EXCEPT !.manualOrderIndicator = IF settled39.numberOfReturnBitfields >= 12 /\ (settled39.orderAcknowledgmentReturnBitfield12 # << >> /\ (settled39.orderAcknowledgmentReturnBitfield12[1] \div 2) % 2 > 0) THEN (IF settled39.manualOrderIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled39.manualOrderIndicator) ELSE << >>]
        settled41 == [settled40 EXCEPT !.oeoid = IF settled40.numberOfReturnBitfields >= 12 /\ (settled40.orderAcknowledgmentReturnBitfield12 # << >> /\ (settled40.orderAcknowledgmentReturnBitfield12[1] \div 4) % 2 > 0) THEN (IF settled40.oeoid = << >> THEN <<[i \in 1 .. 18 |-> 0]>> ELSE settled40.oeoid) ELSE << >>]
        settled42 == [settled41 EXCEPT !.cumQty = IF settled41.numberOfReturnBitfields >= 13 /\ (settled41.orderAcknowledgmentReturnBitfield13 # << >> /\ settled41.orderAcknowledgmentReturnBitfield13[1] % 2 > 0) THEN (IF settled41.cumQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled41.cumQty) ELSE << >>]
        settled43 == [settled42 EXCEPT !.dayOrderQty = IF settled42.numberOfReturnBitfields >= 13 /\ (settled42.orderAcknowledgmentReturnBitfield13 # << >> /\ (settled42.orderAcknowledgmentReturnBitfield13[1] \div 2) % 2 > 0) THEN (IF settled42.dayOrderQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled42.dayOrderQty) ELSE << >>]
        settled44 == [settled43 EXCEPT !.dayCumQty = IF settled43.numberOfReturnBitfields >= 13 /\ (settled43.orderAcknowledgmentReturnBitfield13 # << >> /\ (settled43.orderAcknowledgmentReturnBitfield13[1] \div 4) % 2 > 0) THEN (IF settled43.dayCumQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled43.dayCumQty) ELSE << >>]
        settled45 == [settled44 EXCEPT !.avgPx = IF settled44.numberOfReturnBitfields >= 13 /\ (settled44.orderAcknowledgmentReturnBitfield13 # << >> /\ (settled44.orderAcknowledgmentReturnBitfield13[1] \div 8) % 2 > 0) THEN (IF settled44.avgPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled44.avgPx) ELSE << >>]
        settled46 == [settled45 EXCEPT !.dayAvgPx = IF settled45.numberOfReturnBitfields >= 13 /\ (settled45.orderAcknowledgmentReturnBitfield13 # << >> /\ (settled45.orderAcknowledgmentReturnBitfield13[1] \div 16) % 2 > 0) THEN (IF settled45.dayAvgPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled45.dayAvgPx) ELSE << >>]
        settled47 == [settled46 EXCEPT !.frequentTraderId = IF settled46.numberOfReturnBitfields >= 16 /\ (settled46.orderAcknowledgmentReturnBitfield16 # << >> /\ settled46.orderAcknowledgmentReturnBitfield16[1] % 2 > 0) THEN (IF settled46.frequentTraderId = << >> THEN <<[i \in 1 .. 6 |-> 0]>> ELSE settled46.frequentTraderId) ELSE << >>]
        settled48 == [settled47 EXCEPT !.custOrderHandlingInst = IF settled47.numberOfReturnBitfields >= 17 /\ (settled47.orderAcknowledgmentReturnBitfield17 # << >> /\ (settled47.orderAcknowledgmentReturnBitfield17[1] \div 128) % 2 > 0) THEN (IF settled47.custOrderHandlingInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled47.custOrderHandlingInst) ELSE << >>]
    IN  settled48

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
                                       side                                |-> << >>,
                                       price                               |-> << >>,
                                       ordType                             |-> << >>,
                                       timeInForce                         |-> << >>,
                                       minQty                              |-> << >>,
                                       symbolLong                          |-> << >>,
                                       capacity                            |-> << >>,
                                       account                             |-> << >>,
                                       clearingFirm                        |-> << >>,
                                       clearingAccount                     |-> << >>,
                                       orderQty                            |-> << >>,
                                       preventMatch                        |-> << >>,
                                       maturityDate                        |-> << >>,
                                       openClose                           |-> << >>,
                                       leavesQty                           |-> << >>,
                                       baseLiquidityIndicator              |-> << >>,
                                       expireTime                          |-> << >>,
                                       subLiquidityIndicator               |-> << >>,
                                       stopPx                              |-> << >>,
                                       cmtaNumber                          |-> << >>,
                                       ctiCode                             |-> << >>,
                                       manualOrderIndicator                |-> << >>,
                                       oeoid                               |-> << >>,
                                       cumQty                              |-> << >>,
                                       dayOrderQty                         |-> << >>,
                                       dayCumQty                           |-> << >>,
                                       avgPx                               |-> << >>,
                                       dayAvgPx                            |-> << >>,
                                       frequentTraderId                    |-> << >>,
                                       custOrderHandlingInst               |-> << >> ])

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
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 4, !.orderAcknowledgmentReturnBitfield4 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderAcknowledgmentReturnBitfield5 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 6, !.orderAcknowledgmentReturnBitfield6 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 7, !.orderAcknowledgmentReturnBitfield7 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderAcknowledgmentReturnBitfield8 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 9, !.orderAcknowledgmentReturnBitfield9 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 10, !.orderAcknowledgmentReturnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 11, !.orderAcknowledgmentReturnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 12, !.orderAcknowledgmentReturnBitfield12 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 13, !.orderAcknowledgmentReturnBitfield13 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 14, !.orderAcknowledgmentReturnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 15, !.orderAcknowledgmentReturnBitfield15 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 16, !.orderAcknowledgmentReturnBitfield16 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 17, !.orderAcknowledgmentReturnBitfield17 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 18, !.orderAcknowledgmentReturnBitfield18 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderAcknowledgmentReturnBitfield1 = <<1>>, !.side = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderAcknowledgmentReturnBitfield1 = <<4>>, !.price = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderAcknowledgmentReturnBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderAcknowledgmentReturnBitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderAcknowledgmentReturnBitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 2, !.orderAcknowledgmentReturnBitfield2 = <<1>>, !.symbolLong = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 2, !.orderAcknowledgmentReturnBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderAcknowledgmentReturnBitfield3 = <<1>>, !.account = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderAcknowledgmentReturnBitfield3 = <<2>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderAcknowledgmentReturnBitfield3 = <<4>>, !.clearingAccount = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderAcknowledgmentReturnBitfield3 = <<64>>, !.orderQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderAcknowledgmentReturnBitfield3 = <<128>>, !.preventMatch = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 4, !.orderAcknowledgmentReturnBitfield4 = <<1>>, !.maturityDate = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 4, !.orderAcknowledgmentReturnBitfield4 = <<8>>, !.openClose = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderAcknowledgmentReturnBitfield5 = <<2>>, !.leavesQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderAcknowledgmentReturnBitfield5 = <<64>>, !.baseLiquidityIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderAcknowledgmentReturnBitfield5 = <<128>>, !.expireTime = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 7, !.orderAcknowledgmentReturnBitfield7 = <<1>>, !.subLiquidityIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderAcknowledgmentReturnBitfield8 = <<4>>, !.stopPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 9, !.orderAcknowledgmentReturnBitfield9 = <<32>>, !.cmtaNumber = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 12, !.orderAcknowledgmentReturnBitfield12 = <<1>>, !.ctiCode = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 12, !.orderAcknowledgmentReturnBitfield12 = <<2>>, !.manualOrderIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 12, !.orderAcknowledgmentReturnBitfield12 = <<4>>, !.oeoid = one]) : one \in { <<held>> : held \in Sample(18) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 13, !.orderAcknowledgmentReturnBitfield13 = <<1>>, !.cumQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 13, !.orderAcknowledgmentReturnBitfield13 = <<2>>, !.dayOrderQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 13, !.orderAcknowledgmentReturnBitfield13 = <<4>>, !.dayCumQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 13, !.orderAcknowledgmentReturnBitfield13 = <<8>>, !.avgPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 13, !.orderAcknowledgmentReturnBitfield13 = <<16>>, !.dayAvgPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 16, !.orderAcknowledgmentReturnBitfield16 = <<1>>, !.frequentTraderId = one]) : one \in { <<held>> : held \in Sample(6) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 17, !.orderAcknowledgmentReturnBitfield17 = <<128>>, !.custOrderHandlingInst = one]) : one \in { <<held>> : held \in Sample(1) } }

(***************************************************************************)
(* Quote Update Acknowledgment Quote: 16 bytes                             *)
(***************************************************************************)

QuoteUpdateAcknowledgmentQuote ==
    [ orderId               : Sample(8),
      quoteResult           : Sample(1),
      subLiquidityIndicator : Sample(1),
      reserved6             : Sample(6) ]

EncodeQuoteUpdateAcknowledgmentQuote(message) ==
    message.orderId
        \o message.quoteResult
        \o message.subLiquidityIndicator
        \o message.reserved6

DecodeQuoteUpdateAcknowledgmentQuote(bytes) ==
    LET orderId == ReadBytes(bytes, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET quoteResult == ReadBytes(orderId.rest, 1) IN IF ~quoteResult.ok THEN Fail ELSE
    LET subLiquidityIndicator == ReadBytes(quoteResult.rest, 1) IN IF ~subLiquidityIndicator.ok THEN Fail ELSE
    LET reserved6 == ReadBytes(subLiquidityIndicator.rest, 6) IN IF ~reserved6.ok THEN Fail ELSE
    Ok([ orderId               |-> orderId.value,
         quoteResult           |-> quoteResult.value,
         subLiquidityIndicator |-> subLiquidityIndicator.value,
         reserved6             |-> reserved6.value ], reserved6.rest)

ZeroQuoteUpdateAcknowledgmentQuote ==
    [ orderId               |-> [i \in 1 .. 8 |-> 0],
      quoteResult           |-> [i \in 1 .. 1 |-> 0],
      subLiquidityIndicator |-> [i \in 1 .. 1 |-> 0],
      reserved6             |-> [i \in 1 .. 6 |-> 0] ]

(* Quote Update Acknowledgment Quote at zero, then each field in turn at the values it is checked at *)
CheckedQuoteUpdateAcknowledgmentQuote ==
    { ZeroQuoteUpdateAcknowledgmentQuote }
        \cup { [ZeroQuoteUpdateAcknowledgmentQuote EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteUpdateAcknowledgmentQuote EXCEPT !.quoteResult = one] : one \in Sample(1) }
        \cup { [ZeroQuoteUpdateAcknowledgmentQuote EXCEPT !.subLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroQuoteUpdateAcknowledgmentQuote EXCEPT !.reserved6 = one] : one \in Sample(6) }

(* A run of Quote Update Acknowledgment Quote, written one after another *)
RECURSIVE EncodeQuoteUpdateAcknowledgmentQuoteList(_)
EncodeQuoteUpdateAcknowledgmentQuoteList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeQuoteUpdateAcknowledgmentQuote(Head(messages)) \o EncodeQuoteUpdateAcknowledgmentQuoteList(Tail(messages))

(* As many Quote Update Acknowledgment Quote as the field that counts them says *)
RECURSIVE ReadQuoteUpdateAcknowledgmentQuoteList(_, _)
ReadQuoteUpdateAcknowledgmentQuoteList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeQuoteUpdateAcknowledgmentQuote(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadQuoteUpdateAcknowledgmentQuoteList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Quote Update Acknowledgment Quote of each kind, for the lists that carry them *)
OneQuoteUpdateAcknowledgmentQuote == { ZeroQuoteUpdateAcknowledgmentQuote }

(***************************************************************************)
(* Quote Update Acknowledgment Message                                     *)
(***************************************************************************)

QuoteUpdateAcknowledgmentMessage ==
    [ transactionTime                : Sample(8),
      quoteUpdateId                  : Sample(16),
      quoteRejectReason              : Sample(1),
      reserved17                     : Sample(17),
      quoteUpdateAcknowledgmentQuote : SampleLists(OneQuoteUpdateAcknowledgmentQuote) ]

EncodeQuoteUpdateAcknowledgmentMessage(message) ==
    message.transactionTime
        \o message.quoteUpdateId
        \o message.quoteRejectReason
        \o message.reserved17
        \o EncodeUIntBE(Len(message.quoteUpdateAcknowledgmentQuote), 1)
        \o EncodeQuoteUpdateAcknowledgmentQuoteList(message.quoteUpdateAcknowledgmentQuote)

DecodeQuoteUpdateAcknowledgmentMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET quoteUpdateId == ReadBytes(transactionTime.rest, 16) IN IF ~quoteUpdateId.ok THEN Fail ELSE
    LET quoteRejectReason == ReadBytes(quoteUpdateId.rest, 1) IN IF ~quoteRejectReason.ok THEN Fail ELSE
    LET reserved17 == ReadBytes(quoteRejectReason.rest, 17) IN IF ~reserved17.ok THEN Fail ELSE
    LET quoteCnt == ReadUIntBE(reserved17.rest, 1) IN IF ~quoteCnt.ok THEN Fail ELSE
    LET quoteUpdateAcknowledgmentQuote == ReadQuoteUpdateAcknowledgmentQuoteList(quoteCnt.rest, quoteCnt.value) IN IF ~quoteUpdateAcknowledgmentQuote.ok THEN Fail ELSE
    Ok([ transactionTime                |-> transactionTime.value,
         quoteUpdateId                  |-> quoteUpdateId.value,
         quoteRejectReason              |-> quoteRejectReason.value,
         reserved17                     |-> reserved17.value,
         quoteUpdateAcknowledgmentQuote |-> quoteUpdateAcknowledgmentQuote.value ], quoteUpdateAcknowledgmentQuote.rest)

ZeroQuoteUpdateAcknowledgmentMessage ==
    [ transactionTime                |-> [i \in 1 .. 8 |-> 0],
      quoteUpdateId                  |-> [i \in 1 .. 16 |-> 0],
      quoteRejectReason              |-> [i \in 1 .. 1 |-> 0],
      reserved17                     |-> [i \in 1 .. 17 |-> 0],
      quoteUpdateAcknowledgmentQuote |-> << >> ]

(* Quote Update Acknowledgment Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteUpdateAcknowledgmentMessage ==
    { ZeroQuoteUpdateAcknowledgmentMessage }
        \cup { [ZeroQuoteUpdateAcknowledgmentMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroQuoteUpdateAcknowledgmentMessage EXCEPT !.quoteUpdateId = one] : one \in Sample(16) }
        \cup { [ZeroQuoteUpdateAcknowledgmentMessage EXCEPT !.quoteRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroQuoteUpdateAcknowledgmentMessage EXCEPT !.reserved17 = one] : one \in Sample(17) }
        \cup { [ZeroQuoteUpdateAcknowledgmentMessage EXCEPT !.quoteUpdateAcknowledgmentQuote = one] : one \in SampleLists(OneQuoteUpdateAcknowledgmentQuote) }

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
      orderRejectedReturnBitfield4  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderRejectedReturnBitfield5  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRejectedReturnBitfield6  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRejectedReturnBitfield7  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRejectedReturnBitfield8  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderRejectedReturnBitfield9  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderRejectedReturnBitfield10 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRejectedReturnBitfield11 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRejectedReturnBitfield12 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderRejectedReturnBitfield13 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRejectedReturnBitfield14 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRejectedReturnBitfield15 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderRejectedReturnBitfield16 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderRejectedReturnBitfield17 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderRejectedReturnBitfield18 : { << >> } \cup { <<held>> : held \in Sample(1) },
      side                          : { << >> } \cup { <<held>> : held \in Sample(1) },
      price                         : { << >> } \cup { <<held>> : held \in Sample(8) },
      ordType                       : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce                   : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                        : { << >> } \cup { <<held>> : held \in Sample(4) },
      symbolLong                    : { << >> } \cup { <<held>> : held \in Sample(8) },
      capacity                      : { << >> } \cup { <<held>> : held \in Sample(1) },
      account                       : { << >> } \cup { <<held>> : held \in Sample(16) },
      clearingFirm                  : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingAccount               : { << >> } \cup { <<held>> : held \in Sample(4) },
      orderQty                      : { << >> } \cup { <<held>> : held \in Sample(4) },
      preventMatch                  : { << >> } \cup { <<held>> : held \in Sample(3) },
      maturityDate                  : { << >> } \cup { <<held>> : held \in Sample(4) },
      openClose                     : { << >> } \cup { <<held>> : held \in Sample(1) },
      stopPx                        : { << >> } \cup { <<held>> : held \in Sample(8) },
      cmtaNumber                    : { << >> } \cup { <<held>> : held \in Sample(4) },
      ctiCode                       : { << >> } \cup { <<held>> : held \in Sample(1) },
      manualOrderIndicator          : { << >> } \cup { <<held>> : held \in Sample(1) },
      oeoid                         : { << >> } \cup { <<held>> : held \in Sample(18) },
      frequentTraderId              : { << >> } \cup { <<held>> : held \in Sample(6) },
      custOrderHandlingInst         : { << >> } \cup { <<held>> : held \in Sample(1) } ]

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
        \o (IF message.orderRejectedReturnBitfield4 = << >> THEN << >> ELSE EncodeUIntLE(message.orderRejectedReturnBitfield4[1], 1))
        \o (IF message.orderRejectedReturnBitfield5 = << >> THEN << >> ELSE message.orderRejectedReturnBitfield5[1])
        \o (IF message.orderRejectedReturnBitfield6 = << >> THEN << >> ELSE message.orderRejectedReturnBitfield6[1])
        \o (IF message.orderRejectedReturnBitfield7 = << >> THEN << >> ELSE message.orderRejectedReturnBitfield7[1])
        \o (IF message.orderRejectedReturnBitfield8 = << >> THEN << >> ELSE EncodeUIntLE(message.orderRejectedReturnBitfield8[1], 1))
        \o (IF message.orderRejectedReturnBitfield9 = << >> THEN << >> ELSE EncodeUIntLE(message.orderRejectedReturnBitfield9[1], 1))
        \o (IF message.orderRejectedReturnBitfield10 = << >> THEN << >> ELSE message.orderRejectedReturnBitfield10[1])
        \o (IF message.orderRejectedReturnBitfield11 = << >> THEN << >> ELSE message.orderRejectedReturnBitfield11[1])
        \o (IF message.orderRejectedReturnBitfield12 = << >> THEN << >> ELSE EncodeUIntLE(message.orderRejectedReturnBitfield12[1], 1))
        \o (IF message.orderRejectedReturnBitfield13 = << >> THEN << >> ELSE message.orderRejectedReturnBitfield13[1])
        \o (IF message.orderRejectedReturnBitfield14 = << >> THEN << >> ELSE message.orderRejectedReturnBitfield14[1])
        \o (IF message.orderRejectedReturnBitfield15 = << >> THEN << >> ELSE message.orderRejectedReturnBitfield15[1])
        \o (IF message.orderRejectedReturnBitfield16 = << >> THEN << >> ELSE EncodeUIntLE(message.orderRejectedReturnBitfield16[1], 1))
        \o (IF message.orderRejectedReturnBitfield17 = << >> THEN << >> ELSE EncodeUIntLE(message.orderRejectedReturnBitfield17[1], 1))
        \o (IF message.orderRejectedReturnBitfield18 = << >> THEN << >> ELSE message.orderRejectedReturnBitfield18[1])
        \o (IF message.side = << >> THEN << >> ELSE message.side[1])
        \o (IF message.price = << >> THEN << >> ELSE message.price[1])
        \o (IF message.ordType = << >> THEN << >> ELSE message.ordType[1])
        \o (IF message.timeInForce = << >> THEN << >> ELSE message.timeInForce[1])
        \o (IF message.minQty = << >> THEN << >> ELSE message.minQty[1])
        \o (IF message.symbolLong = << >> THEN << >> ELSE message.symbolLong[1])
        \o (IF message.capacity = << >> THEN << >> ELSE message.capacity[1])
        \o (IF message.account = << >> THEN << >> ELSE message.account[1])
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])
        \o (IF message.clearingAccount = << >> THEN << >> ELSE message.clearingAccount[1])
        \o (IF message.orderQty = << >> THEN << >> ELSE message.orderQty[1])
        \o (IF message.preventMatch = << >> THEN << >> ELSE message.preventMatch[1])
        \o (IF message.maturityDate = << >> THEN << >> ELSE message.maturityDate[1])
        \o (IF message.openClose = << >> THEN << >> ELSE message.openClose[1])
        \o (IF message.stopPx = << >> THEN << >> ELSE message.stopPx[1])
        \o (IF message.cmtaNumber = << >> THEN << >> ELSE message.cmtaNumber[1])
        \o (IF message.ctiCode = << >> THEN << >> ELSE message.ctiCode[1])
        \o (IF message.manualOrderIndicator = << >> THEN << >> ELSE message.manualOrderIndicator[1])
        \o (IF message.oeoid = << >> THEN << >> ELSE message.oeoid[1])
        \o (IF message.frequentTraderId = << >> THEN << >> ELSE message.frequentTraderId[1])
        \o (IF message.custOrderHandlingInst = << >> THEN << >> ELSE message.custOrderHandlingInst[1])

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
    LET orderRejectedReturnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadUIntLE(orderRejectedReturnBitfield3.rest, 1), orderRejectedReturnBitfield3.rest) IN IF ~orderRejectedReturnBitfield4.ok THEN Fail ELSE
    LET orderRejectedReturnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadBytes(orderRejectedReturnBitfield4.rest, 1), orderRejectedReturnBitfield4.rest) IN IF ~orderRejectedReturnBitfield5.ok THEN Fail ELSE
    LET orderRejectedReturnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadBytes(orderRejectedReturnBitfield5.rest, 1), orderRejectedReturnBitfield5.rest) IN IF ~orderRejectedReturnBitfield6.ok THEN Fail ELSE
    LET orderRejectedReturnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadBytes(orderRejectedReturnBitfield6.rest, 1), orderRejectedReturnBitfield6.rest) IN IF ~orderRejectedReturnBitfield7.ok THEN Fail ELSE
    LET orderRejectedReturnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadUIntLE(orderRejectedReturnBitfield7.rest, 1), orderRejectedReturnBitfield7.rest) IN IF ~orderRejectedReturnBitfield8.ok THEN Fail ELSE
    LET orderRejectedReturnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadUIntLE(orderRejectedReturnBitfield8.rest, 1), orderRejectedReturnBitfield8.rest) IN IF ~orderRejectedReturnBitfield9.ok THEN Fail ELSE
    LET orderRejectedReturnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadBytes(orderRejectedReturnBitfield9.rest, 1), orderRejectedReturnBitfield9.rest) IN IF ~orderRejectedReturnBitfield10.ok THEN Fail ELSE
    LET orderRejectedReturnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadBytes(orderRejectedReturnBitfield10.rest, 1), orderRejectedReturnBitfield10.rest) IN IF ~orderRejectedReturnBitfield11.ok THEN Fail ELSE
    LET orderRejectedReturnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadUIntLE(orderRejectedReturnBitfield11.rest, 1), orderRejectedReturnBitfield11.rest) IN IF ~orderRejectedReturnBitfield12.ok THEN Fail ELSE
    LET orderRejectedReturnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(orderRejectedReturnBitfield12.rest, 1), orderRejectedReturnBitfield12.rest) IN IF ~orderRejectedReturnBitfield13.ok THEN Fail ELSE
    LET orderRejectedReturnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(orderRejectedReturnBitfield13.rest, 1), orderRejectedReturnBitfield13.rest) IN IF ~orderRejectedReturnBitfield14.ok THEN Fail ELSE
    LET orderRejectedReturnBitfield15 == ReadWhen(numberOfReturnBitfields.value >= 15, ReadBytes(orderRejectedReturnBitfield14.rest, 1), orderRejectedReturnBitfield14.rest) IN IF ~orderRejectedReturnBitfield15.ok THEN Fail ELSE
    LET orderRejectedReturnBitfield16 == ReadWhen(numberOfReturnBitfields.value >= 16, ReadUIntLE(orderRejectedReturnBitfield15.rest, 1), orderRejectedReturnBitfield15.rest) IN IF ~orderRejectedReturnBitfield16.ok THEN Fail ELSE
    LET orderRejectedReturnBitfield17 == ReadWhen(numberOfReturnBitfields.value >= 17, ReadUIntLE(orderRejectedReturnBitfield16.rest, 1), orderRejectedReturnBitfield16.rest) IN IF ~orderRejectedReturnBitfield17.ok THEN Fail ELSE
    LET orderRejectedReturnBitfield18 == ReadWhen(numberOfReturnBitfields.value >= 18, ReadBytes(orderRejectedReturnBitfield17.rest, 1), orderRejectedReturnBitfield17.rest) IN IF ~orderRejectedReturnBitfield18.ok THEN Fail ELSE
    LET side == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderRejectedReturnBitfield1.value # << >> /\ orderRejectedReturnBitfield1.value[1] % 2 > 0), ReadBytes(orderRejectedReturnBitfield18.rest, 1), orderRejectedReturnBitfield18.rest) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderRejectedReturnBitfield1.value # << >> /\ (orderRejectedReturnBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(side.rest, 8), side.rest) IN IF ~price.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderRejectedReturnBitfield1.value # << >> /\ (orderRejectedReturnBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(price.rest, 1), price.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderRejectedReturnBitfield1.value # << >> /\ (orderRejectedReturnBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderRejectedReturnBitfield1.value # << >> /\ (orderRejectedReturnBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET symbolLong == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderRejectedReturnBitfield2.value # << >> /\ orderRejectedReturnBitfield2.value[1] % 2 > 0), ReadBytes(minQty.rest, 8), minQty.rest) IN IF ~symbolLong.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderRejectedReturnBitfield2.value # << >> /\ (orderRejectedReturnBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(symbolLong.rest, 1), symbolLong.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderRejectedReturnBitfield3.value # << >> /\ orderRejectedReturnBitfield3.value[1] % 2 > 0), ReadBytes(capacity.rest, 16), capacity.rest) IN IF ~account.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderRejectedReturnBitfield3.value # << >> /\ (orderRejectedReturnBitfield3.value[1] \div 2) % 2 > 0), ReadBytes(account.rest, 4), account.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderRejectedReturnBitfield3.value # << >> /\ (orderRejectedReturnBitfield3.value[1] \div 4) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET orderQty == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderRejectedReturnBitfield3.value # << >> /\ (orderRejectedReturnBitfield3.value[1] \div 64) % 2 > 0), ReadBytes(clearingAccount.rest, 4), clearingAccount.rest) IN IF ~orderQty.ok THEN Fail ELSE
    LET preventMatch == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderRejectedReturnBitfield3.value # << >> /\ (orderRejectedReturnBitfield3.value[1] \div 128) % 2 > 0), ReadBytes(orderQty.rest, 3), orderQty.rest) IN IF ~preventMatch.ok THEN Fail ELSE
    LET maturityDate == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (orderRejectedReturnBitfield4.value # << >> /\ orderRejectedReturnBitfield4.value[1] % 2 > 0), ReadBytes(preventMatch.rest, 4), preventMatch.rest) IN IF ~maturityDate.ok THEN Fail ELSE
    LET openClose == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (orderRejectedReturnBitfield4.value # << >> /\ (orderRejectedReturnBitfield4.value[1] \div 8) % 2 > 0), ReadBytes(maturityDate.rest, 1), maturityDate.rest) IN IF ~openClose.ok THEN Fail ELSE
    LET stopPx == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderRejectedReturnBitfield8.value # << >> /\ (orderRejectedReturnBitfield8.value[1] \div 4) % 2 > 0), ReadBytes(openClose.rest, 8), openClose.rest) IN IF ~stopPx.ok THEN Fail ELSE
    LET cmtaNumber == ReadWhen(numberOfReturnBitfields.value >= 9 /\ (orderRejectedReturnBitfield9.value # << >> /\ (orderRejectedReturnBitfield9.value[1] \div 32) % 2 > 0), ReadBytes(stopPx.rest, 4), stopPx.rest) IN IF ~cmtaNumber.ok THEN Fail ELSE
    LET ctiCode == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (orderRejectedReturnBitfield12.value # << >> /\ orderRejectedReturnBitfield12.value[1] % 2 > 0), ReadBytes(cmtaNumber.rest, 1), cmtaNumber.rest) IN IF ~ctiCode.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (orderRejectedReturnBitfield12.value # << >> /\ (orderRejectedReturnBitfield12.value[1] \div 2) % 2 > 0), ReadBytes(ctiCode.rest, 1), ctiCode.rest) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET oeoid == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (orderRejectedReturnBitfield12.value # << >> /\ (orderRejectedReturnBitfield12.value[1] \div 4) % 2 > 0), ReadBytes(manualOrderIndicator.rest, 18), manualOrderIndicator.rest) IN IF ~oeoid.ok THEN Fail ELSE
    LET frequentTraderId == ReadWhen(numberOfReturnBitfields.value >= 16 /\ (orderRejectedReturnBitfield16.value # << >> /\ orderRejectedReturnBitfield16.value[1] % 2 > 0), ReadBytes(oeoid.rest, 6), oeoid.rest) IN IF ~frequentTraderId.ok THEN Fail ELSE
    LET custOrderHandlingInst == ReadWhen(numberOfReturnBitfields.value >= 17 /\ (orderRejectedReturnBitfield17.value # << >> /\ (orderRejectedReturnBitfield17.value[1] \div 128) % 2 > 0), ReadBytes(frequentTraderId.rest, 1), frequentTraderId.rest) IN IF ~custOrderHandlingInst.ok THEN Fail ELSE
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
         side                          |-> side.value,
         price                         |-> price.value,
         ordType                       |-> ordType.value,
         timeInForce                   |-> timeInForce.value,
         minQty                        |-> minQty.value,
         symbolLong                    |-> symbolLong.value,
         capacity                      |-> capacity.value,
         account                       |-> account.value,
         clearingFirm                  |-> clearingFirm.value,
         clearingAccount               |-> clearingAccount.value,
         orderQty                      |-> orderQty.value,
         preventMatch                  |-> preventMatch.value,
         maturityDate                  |-> maturityDate.value,
         openClose                     |-> openClose.value,
         stopPx                        |-> stopPx.value,
         cmtaNumber                    |-> cmtaNumber.value,
         ctiCode                       |-> ctiCode.value,
         manualOrderIndicator          |-> manualOrderIndicator.value,
         oeoid                         |-> oeoid.value,
         frequentTraderId              |-> frequentTraderId.value,
         custOrderHandlingInst         |-> custOrderHandlingInst.value ], custOrderHandlingInst.rest)

(* Order Rejected Message with each field marked present by fields before it there exactly where they say *)
SettleOrderRejectedMessage(message) ==
    LET settled1 == [message EXCEPT !.orderRejectedReturnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.orderRejectedReturnBitfield1 = << >> THEN <<0>> ELSE message.orderRejectedReturnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.orderRejectedReturnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.orderRejectedReturnBitfield2 = << >> THEN <<0>> ELSE settled1.orderRejectedReturnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.orderRejectedReturnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.orderRejectedReturnBitfield3 = << >> THEN <<0>> ELSE settled2.orderRejectedReturnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.orderRejectedReturnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.orderRejectedReturnBitfield4 = << >> THEN <<0>> ELSE settled3.orderRejectedReturnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.orderRejectedReturnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.orderRejectedReturnBitfield5 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled4.orderRejectedReturnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.orderRejectedReturnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.orderRejectedReturnBitfield6 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled5.orderRejectedReturnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.orderRejectedReturnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.orderRejectedReturnBitfield7 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.orderRejectedReturnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.orderRejectedReturnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.orderRejectedReturnBitfield8 = << >> THEN <<0>> ELSE settled7.orderRejectedReturnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.orderRejectedReturnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.orderRejectedReturnBitfield9 = << >> THEN <<0>> ELSE settled8.orderRejectedReturnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.orderRejectedReturnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.orderRejectedReturnBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.orderRejectedReturnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.orderRejectedReturnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.orderRejectedReturnBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.orderRejectedReturnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.orderRejectedReturnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.orderRejectedReturnBitfield12 = << >> THEN <<0>> ELSE settled11.orderRejectedReturnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.orderRejectedReturnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.orderRejectedReturnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.orderRejectedReturnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.orderRejectedReturnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.orderRejectedReturnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.orderRejectedReturnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.orderRejectedReturnBitfield15 = IF settled14.numberOfReturnBitfields >= 15 THEN (IF settled14.orderRejectedReturnBitfield15 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.orderRejectedReturnBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.orderRejectedReturnBitfield16 = IF settled15.numberOfReturnBitfields >= 16 THEN (IF settled15.orderRejectedReturnBitfield16 = << >> THEN <<0>> ELSE settled15.orderRejectedReturnBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.orderRejectedReturnBitfield17 = IF settled16.numberOfReturnBitfields >= 17 THEN (IF settled16.orderRejectedReturnBitfield17 = << >> THEN <<0>> ELSE settled16.orderRejectedReturnBitfield17) ELSE << >>]
        settled18 == [settled17 EXCEPT !.orderRejectedReturnBitfield18 = IF settled17.numberOfReturnBitfields >= 18 THEN (IF settled17.orderRejectedReturnBitfield18 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.orderRejectedReturnBitfield18) ELSE << >>]
        settled19 == [settled18 EXCEPT !.side = IF settled18.numberOfReturnBitfields >= 1 /\ (settled18.orderRejectedReturnBitfield1 # << >> /\ settled18.orderRejectedReturnBitfield1[1] % 2 > 0) THEN (IF settled18.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled18.side) ELSE << >>]
        settled20 == [settled19 EXCEPT !.price = IF settled19.numberOfReturnBitfields >= 1 /\ (settled19.orderRejectedReturnBitfield1 # << >> /\ (settled19.orderRejectedReturnBitfield1[1] \div 4) % 2 > 0) THEN (IF settled19.price = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled19.price) ELSE << >>]
        settled21 == [settled20 EXCEPT !.ordType = IF settled20.numberOfReturnBitfields >= 1 /\ (settled20.orderRejectedReturnBitfield1 # << >> /\ (settled20.orderRejectedReturnBitfield1[1] \div 16) % 2 > 0) THEN (IF settled20.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled20.ordType) ELSE << >>]
        settled22 == [settled21 EXCEPT !.timeInForce = IF settled21.numberOfReturnBitfields >= 1 /\ (settled21.orderRejectedReturnBitfield1 # << >> /\ (settled21.orderRejectedReturnBitfield1[1] \div 32) % 2 > 0) THEN (IF settled21.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled21.timeInForce) ELSE << >>]
        settled23 == [settled22 EXCEPT !.minQty = IF settled22.numberOfReturnBitfields >= 1 /\ (settled22.orderRejectedReturnBitfield1 # << >> /\ (settled22.orderRejectedReturnBitfield1[1] \div 64) % 2 > 0) THEN (IF settled22.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled22.minQty) ELSE << >>]
        settled24 == [settled23 EXCEPT !.symbolLong = IF settled23.numberOfReturnBitfields >= 2 /\ (settled23.orderRejectedReturnBitfield2 # << >> /\ settled23.orderRejectedReturnBitfield2[1] % 2 > 0) THEN (IF settled23.symbolLong = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled23.symbolLong) ELSE << >>]
        settled25 == [settled24 EXCEPT !.capacity = IF settled24.numberOfReturnBitfields >= 2 /\ (settled24.orderRejectedReturnBitfield2 # << >> /\ (settled24.orderRejectedReturnBitfield2[1] \div 64) % 2 > 0) THEN (IF settled24.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled24.capacity) ELSE << >>]
        settled26 == [settled25 EXCEPT !.account = IF settled25.numberOfReturnBitfields >= 3 /\ (settled25.orderRejectedReturnBitfield3 # << >> /\ settled25.orderRejectedReturnBitfield3[1] % 2 > 0) THEN (IF settled25.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled25.account) ELSE << >>]
        settled27 == [settled26 EXCEPT !.clearingFirm = IF settled26.numberOfReturnBitfields >= 3 /\ (settled26.orderRejectedReturnBitfield3 # << >> /\ (settled26.orderRejectedReturnBitfield3[1] \div 2) % 2 > 0) THEN (IF settled26.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled26.clearingFirm) ELSE << >>]
        settled28 == [settled27 EXCEPT !.clearingAccount = IF settled27.numberOfReturnBitfields >= 3 /\ (settled27.orderRejectedReturnBitfield3 # << >> /\ (settled27.orderRejectedReturnBitfield3[1] \div 4) % 2 > 0) THEN (IF settled27.clearingAccount = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled27.clearingAccount) ELSE << >>]
        settled29 == [settled28 EXCEPT !.orderQty = IF settled28.numberOfReturnBitfields >= 3 /\ (settled28.orderRejectedReturnBitfield3 # << >> /\ (settled28.orderRejectedReturnBitfield3[1] \div 64) % 2 > 0) THEN (IF settled28.orderQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled28.orderQty) ELSE << >>]
        settled30 == [settled29 EXCEPT !.preventMatch = IF settled29.numberOfReturnBitfields >= 3 /\ (settled29.orderRejectedReturnBitfield3 # << >> /\ (settled29.orderRejectedReturnBitfield3[1] \div 128) % 2 > 0) THEN (IF settled29.preventMatch = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled29.preventMatch) ELSE << >>]
        settled31 == [settled30 EXCEPT !.maturityDate = IF settled30.numberOfReturnBitfields >= 4 /\ (settled30.orderRejectedReturnBitfield4 # << >> /\ settled30.orderRejectedReturnBitfield4[1] % 2 > 0) THEN (IF settled30.maturityDate = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled30.maturityDate) ELSE << >>]
        settled32 == [settled31 EXCEPT !.openClose = IF settled31.numberOfReturnBitfields >= 4 /\ (settled31.orderRejectedReturnBitfield4 # << >> /\ (settled31.orderRejectedReturnBitfield4[1] \div 8) % 2 > 0) THEN (IF settled31.openClose = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled31.openClose) ELSE << >>]
        settled33 == [settled32 EXCEPT !.stopPx = IF settled32.numberOfReturnBitfields >= 8 /\ (settled32.orderRejectedReturnBitfield8 # << >> /\ (settled32.orderRejectedReturnBitfield8[1] \div 4) % 2 > 0) THEN (IF settled32.stopPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled32.stopPx) ELSE << >>]
        settled34 == [settled33 EXCEPT !.cmtaNumber = IF settled33.numberOfReturnBitfields >= 9 /\ (settled33.orderRejectedReturnBitfield9 # << >> /\ (settled33.orderRejectedReturnBitfield9[1] \div 32) % 2 > 0) THEN (IF settled33.cmtaNumber = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled33.cmtaNumber) ELSE << >>]
        settled35 == [settled34 EXCEPT !.ctiCode = IF settled34.numberOfReturnBitfields >= 12 /\ (settled34.orderRejectedReturnBitfield12 # << >> /\ settled34.orderRejectedReturnBitfield12[1] % 2 > 0) THEN (IF settled34.ctiCode = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled34.ctiCode) ELSE << >>]
        settled36 == [settled35 EXCEPT !.manualOrderIndicator = IF settled35.numberOfReturnBitfields >= 12 /\ (settled35.orderRejectedReturnBitfield12 # << >> /\ (settled35.orderRejectedReturnBitfield12[1] \div 2) % 2 > 0) THEN (IF settled35.manualOrderIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled35.manualOrderIndicator) ELSE << >>]
        settled37 == [settled36 EXCEPT !.oeoid = IF settled36.numberOfReturnBitfields >= 12 /\ (settled36.orderRejectedReturnBitfield12 # << >> /\ (settled36.orderRejectedReturnBitfield12[1] \div 4) % 2 > 0) THEN (IF settled36.oeoid = << >> THEN <<[i \in 1 .. 18 |-> 0]>> ELSE settled36.oeoid) ELSE << >>]
        settled38 == [settled37 EXCEPT !.frequentTraderId = IF settled37.numberOfReturnBitfields >= 16 /\ (settled37.orderRejectedReturnBitfield16 # << >> /\ settled37.orderRejectedReturnBitfield16[1] % 2 > 0) THEN (IF settled37.frequentTraderId = << >> THEN <<[i \in 1 .. 6 |-> 0]>> ELSE settled37.frequentTraderId) ELSE << >>]
        settled39 == [settled38 EXCEPT !.custOrderHandlingInst = IF settled38.numberOfReturnBitfields >= 17 /\ (settled38.orderRejectedReturnBitfield17 # << >> /\ (settled38.orderRejectedReturnBitfield17[1] \div 128) % 2 > 0) THEN (IF settled38.custOrderHandlingInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled38.custOrderHandlingInst) ELSE << >>]
    IN  settled39

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
                                 side                          |-> << >>,
                                 price                         |-> << >>,
                                 ordType                       |-> << >>,
                                 timeInForce                   |-> << >>,
                                 minQty                        |-> << >>,
                                 symbolLong                    |-> << >>,
                                 capacity                      |-> << >>,
                                 account                       |-> << >>,
                                 clearingFirm                  |-> << >>,
                                 clearingAccount               |-> << >>,
                                 orderQty                      |-> << >>,
                                 preventMatch                  |-> << >>,
                                 maturityDate                  |-> << >>,
                                 openClose                     |-> << >>,
                                 stopPx                        |-> << >>,
                                 cmtaNumber                    |-> << >>,
                                 ctiCode                       |-> << >>,
                                 manualOrderIndicator          |-> << >>,
                                 oeoid                         |-> << >>,
                                 frequentTraderId              |-> << >>,
                                 custOrderHandlingInst         |-> << >> ])

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
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 4, !.orderRejectedReturnBitfield4 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderRejectedReturnBitfield5 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 6, !.orderRejectedReturnBitfield6 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 7, !.orderRejectedReturnBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderRejectedReturnBitfield8 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 9, !.orderRejectedReturnBitfield9 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 10, !.orderRejectedReturnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 11, !.orderRejectedReturnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 12, !.orderRejectedReturnBitfield12 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 13, !.orderRejectedReturnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 14, !.orderRejectedReturnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 15, !.orderRejectedReturnBitfield15 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 16, !.orderRejectedReturnBitfield16 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 17, !.orderRejectedReturnBitfield17 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 18, !.orderRejectedReturnBitfield18 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderRejectedReturnBitfield1 = <<1>>, !.side = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderRejectedReturnBitfield1 = <<4>>, !.price = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderRejectedReturnBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderRejectedReturnBitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderRejectedReturnBitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 2, !.orderRejectedReturnBitfield2 = <<1>>, !.symbolLong = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 2, !.orderRejectedReturnBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderRejectedReturnBitfield3 = <<1>>, !.account = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderRejectedReturnBitfield3 = <<2>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderRejectedReturnBitfield3 = <<4>>, !.clearingAccount = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderRejectedReturnBitfield3 = <<64>>, !.orderQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderRejectedReturnBitfield3 = <<128>>, !.preventMatch = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 4, !.orderRejectedReturnBitfield4 = <<1>>, !.maturityDate = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 4, !.orderRejectedReturnBitfield4 = <<8>>, !.openClose = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderRejectedReturnBitfield8 = <<4>>, !.stopPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 9, !.orderRejectedReturnBitfield9 = <<32>>, !.cmtaNumber = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 12, !.orderRejectedReturnBitfield12 = <<1>>, !.ctiCode = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 12, !.orderRejectedReturnBitfield12 = <<2>>, !.manualOrderIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 12, !.orderRejectedReturnBitfield12 = <<4>>, !.oeoid = one]) : one \in { <<held>> : held \in Sample(18) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 16, !.orderRejectedReturnBitfield16 = <<1>>, !.frequentTraderId = one]) : one \in { <<held>> : held \in Sample(6) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 17, !.orderRejectedReturnBitfield17 = <<128>>, !.custOrderHandlingInst = one]) : one \in { <<held>> : held \in Sample(1) } }

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
    [ transactionTime               : Sample(8),
      clOrdId                       : Sample(20),
      orderId                       : Sample(8),
      reserved1                     : Sample(1),
      numberOfReturnBitfields       : 0 .. 255,
      orderModifiedReturnBitfield1  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderModifiedReturnBitfield2  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderModifiedReturnBitfield3  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderModifiedReturnBitfield4  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderModifiedReturnBitfield5  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderModifiedReturnBitfield6  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderModifiedReturnBitfield7  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderModifiedReturnBitfield8  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderModifiedReturnBitfield9  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderModifiedReturnBitfield10 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderModifiedReturnBitfield11 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderModifiedReturnBitfield12 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderModifiedReturnBitfield13 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderModifiedReturnBitfield14 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderModifiedReturnBitfield15 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderModifiedReturnBitfield16 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderModifiedReturnBitfield17 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderModifiedReturnBitfield18 : { << >> } \cup { <<held>> : held \in Sample(1) },
      side                          : { << >> } \cup { <<held>> : held \in Sample(1) },
      price                         : { << >> } \cup { <<held>> : held \in Sample(8) },
      ordType                       : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce                   : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                        : { << >> } \cup { <<held>> : held \in Sample(4) },
      symbolLong                    : { << >> } \cup { <<held>> : held \in Sample(8) },
      capacity                      : { << >> } \cup { <<held>> : held \in Sample(1) },
      account                       : { << >> } \cup { <<held>> : held \in Sample(16) },
      clearingFirm                  : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingAccount               : { << >> } \cup { <<held>> : held \in Sample(4) },
      orderQty                      : { << >> } \cup { <<held>> : held \in Sample(4) },
      preventMatch                  : { << >> } \cup { <<held>> : held \in Sample(3) },
      maturityDate                  : { << >> } \cup { <<held>> : held \in Sample(4) },
      openClose                     : { << >> } \cup { <<held>> : held \in Sample(1) },
      origClOrdId                   : { << >> } \cup { <<held>> : held \in Sample(20) },
      leavesQty                     : { << >> } \cup { <<held>> : held \in Sample(4) },
      baseLiquidityIndicator        : { << >> } \cup { <<held>> : held \in Sample(1) },
      expireTime                    : { << >> } \cup { <<held>> : held \in Sample(8) },
      stopPx                        : { << >> } \cup { <<held>> : held \in Sample(8) },
      cmtaNumber                    : { << >> } \cup { <<held>> : held \in Sample(4) },
      ctiCode                       : { << >> } \cup { <<held>> : held \in Sample(1) },
      manualOrderIndicator          : { << >> } \cup { <<held>> : held \in Sample(1) },
      oeoid                         : { << >> } \cup { <<held>> : held \in Sample(18) },
      frequentTraderId              : { << >> } \cup { <<held>> : held \in Sample(6) },
      custOrderHandlingInst         : { << >> } \cup { <<held>> : held \in Sample(1) } ]

EncodeOrderModifiedMessage(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.orderId
        \o message.reserved1
        \o EncodeUIntBE(message.numberOfReturnBitfields, 1)
        \o (IF message.orderModifiedReturnBitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.orderModifiedReturnBitfield1[1], 1))
        \o (IF message.orderModifiedReturnBitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.orderModifiedReturnBitfield2[1], 1))
        \o (IF message.orderModifiedReturnBitfield3 = << >> THEN << >> ELSE EncodeUIntLE(message.orderModifiedReturnBitfield3[1], 1))
        \o (IF message.orderModifiedReturnBitfield4 = << >> THEN << >> ELSE EncodeUIntLE(message.orderModifiedReturnBitfield4[1], 1))
        \o (IF message.orderModifiedReturnBitfield5 = << >> THEN << >> ELSE EncodeUIntLE(message.orderModifiedReturnBitfield5[1], 1))
        \o (IF message.orderModifiedReturnBitfield6 = << >> THEN << >> ELSE message.orderModifiedReturnBitfield6[1])
        \o (IF message.orderModifiedReturnBitfield7 = << >> THEN << >> ELSE message.orderModifiedReturnBitfield7[1])
        \o (IF message.orderModifiedReturnBitfield8 = << >> THEN << >> ELSE EncodeUIntLE(message.orderModifiedReturnBitfield8[1], 1))
        \o (IF message.orderModifiedReturnBitfield9 = << >> THEN << >> ELSE EncodeUIntLE(message.orderModifiedReturnBitfield9[1], 1))
        \o (IF message.orderModifiedReturnBitfield10 = << >> THEN << >> ELSE message.orderModifiedReturnBitfield10[1])
        \o (IF message.orderModifiedReturnBitfield11 = << >> THEN << >> ELSE message.orderModifiedReturnBitfield11[1])
        \o (IF message.orderModifiedReturnBitfield12 = << >> THEN << >> ELSE EncodeUIntLE(message.orderModifiedReturnBitfield12[1], 1))
        \o (IF message.orderModifiedReturnBitfield13 = << >> THEN << >> ELSE message.orderModifiedReturnBitfield13[1])
        \o (IF message.orderModifiedReturnBitfield14 = << >> THEN << >> ELSE message.orderModifiedReturnBitfield14[1])
        \o (IF message.orderModifiedReturnBitfield15 = << >> THEN << >> ELSE message.orderModifiedReturnBitfield15[1])
        \o (IF message.orderModifiedReturnBitfield16 = << >> THEN << >> ELSE EncodeUIntLE(message.orderModifiedReturnBitfield16[1], 1))
        \o (IF message.orderModifiedReturnBitfield17 = << >> THEN << >> ELSE EncodeUIntLE(message.orderModifiedReturnBitfield17[1], 1))
        \o (IF message.orderModifiedReturnBitfield18 = << >> THEN << >> ELSE message.orderModifiedReturnBitfield18[1])
        \o (IF message.side = << >> THEN << >> ELSE message.side[1])
        \o (IF message.price = << >> THEN << >> ELSE message.price[1])
        \o (IF message.ordType = << >> THEN << >> ELSE message.ordType[1])
        \o (IF message.timeInForce = << >> THEN << >> ELSE message.timeInForce[1])
        \o (IF message.minQty = << >> THEN << >> ELSE message.minQty[1])
        \o (IF message.symbolLong = << >> THEN << >> ELSE message.symbolLong[1])
        \o (IF message.capacity = << >> THEN << >> ELSE message.capacity[1])
        \o (IF message.account = << >> THEN << >> ELSE message.account[1])
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])
        \o (IF message.clearingAccount = << >> THEN << >> ELSE message.clearingAccount[1])
        \o (IF message.orderQty = << >> THEN << >> ELSE message.orderQty[1])
        \o (IF message.preventMatch = << >> THEN << >> ELSE message.preventMatch[1])
        \o (IF message.maturityDate = << >> THEN << >> ELSE message.maturityDate[1])
        \o (IF message.openClose = << >> THEN << >> ELSE message.openClose[1])
        \o (IF message.origClOrdId = << >> THEN << >> ELSE message.origClOrdId[1])
        \o (IF message.leavesQty = << >> THEN << >> ELSE message.leavesQty[1])
        \o (IF message.baseLiquidityIndicator = << >> THEN << >> ELSE message.baseLiquidityIndicator[1])
        \o (IF message.expireTime = << >> THEN << >> ELSE message.expireTime[1])
        \o (IF message.stopPx = << >> THEN << >> ELSE message.stopPx[1])
        \o (IF message.cmtaNumber = << >> THEN << >> ELSE message.cmtaNumber[1])
        \o (IF message.ctiCode = << >> THEN << >> ELSE message.ctiCode[1])
        \o (IF message.manualOrderIndicator = << >> THEN << >> ELSE message.manualOrderIndicator[1])
        \o (IF message.oeoid = << >> THEN << >> ELSE message.oeoid[1])
        \o (IF message.frequentTraderId = << >> THEN << >> ELSE message.frequentTraderId[1])
        \o (IF message.custOrderHandlingInst = << >> THEN << >> ELSE message.custOrderHandlingInst[1])

DecodeOrderModifiedMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clOrdId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(orderId.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET numberOfReturnBitfields == ReadUIntBE(reserved1.rest, 1) IN IF ~numberOfReturnBitfields.ok THEN Fail ELSE
    LET orderModifiedReturnBitfield1 == ReadWhen(numberOfReturnBitfields.value >= 1, ReadUIntLE(numberOfReturnBitfields.rest, 1), numberOfReturnBitfields.rest) IN IF ~orderModifiedReturnBitfield1.ok THEN Fail ELSE
    LET orderModifiedReturnBitfield2 == ReadWhen(numberOfReturnBitfields.value >= 2, ReadUIntLE(orderModifiedReturnBitfield1.rest, 1), orderModifiedReturnBitfield1.rest) IN IF ~orderModifiedReturnBitfield2.ok THEN Fail ELSE
    LET orderModifiedReturnBitfield3 == ReadWhen(numberOfReturnBitfields.value >= 3, ReadUIntLE(orderModifiedReturnBitfield2.rest, 1), orderModifiedReturnBitfield2.rest) IN IF ~orderModifiedReturnBitfield3.ok THEN Fail ELSE
    LET orderModifiedReturnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadUIntLE(orderModifiedReturnBitfield3.rest, 1), orderModifiedReturnBitfield3.rest) IN IF ~orderModifiedReturnBitfield4.ok THEN Fail ELSE
    LET orderModifiedReturnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadUIntLE(orderModifiedReturnBitfield4.rest, 1), orderModifiedReturnBitfield4.rest) IN IF ~orderModifiedReturnBitfield5.ok THEN Fail ELSE
    LET orderModifiedReturnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadBytes(orderModifiedReturnBitfield5.rest, 1), orderModifiedReturnBitfield5.rest) IN IF ~orderModifiedReturnBitfield6.ok THEN Fail ELSE
    LET orderModifiedReturnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadBytes(orderModifiedReturnBitfield6.rest, 1), orderModifiedReturnBitfield6.rest) IN IF ~orderModifiedReturnBitfield7.ok THEN Fail ELSE
    LET orderModifiedReturnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadUIntLE(orderModifiedReturnBitfield7.rest, 1), orderModifiedReturnBitfield7.rest) IN IF ~orderModifiedReturnBitfield8.ok THEN Fail ELSE
    LET orderModifiedReturnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadUIntLE(orderModifiedReturnBitfield8.rest, 1), orderModifiedReturnBitfield8.rest) IN IF ~orderModifiedReturnBitfield9.ok THEN Fail ELSE
    LET orderModifiedReturnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadBytes(orderModifiedReturnBitfield9.rest, 1), orderModifiedReturnBitfield9.rest) IN IF ~orderModifiedReturnBitfield10.ok THEN Fail ELSE
    LET orderModifiedReturnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadBytes(orderModifiedReturnBitfield10.rest, 1), orderModifiedReturnBitfield10.rest) IN IF ~orderModifiedReturnBitfield11.ok THEN Fail ELSE
    LET orderModifiedReturnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadUIntLE(orderModifiedReturnBitfield11.rest, 1), orderModifiedReturnBitfield11.rest) IN IF ~orderModifiedReturnBitfield12.ok THEN Fail ELSE
    LET orderModifiedReturnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(orderModifiedReturnBitfield12.rest, 1), orderModifiedReturnBitfield12.rest) IN IF ~orderModifiedReturnBitfield13.ok THEN Fail ELSE
    LET orderModifiedReturnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(orderModifiedReturnBitfield13.rest, 1), orderModifiedReturnBitfield13.rest) IN IF ~orderModifiedReturnBitfield14.ok THEN Fail ELSE
    LET orderModifiedReturnBitfield15 == ReadWhen(numberOfReturnBitfields.value >= 15, ReadBytes(orderModifiedReturnBitfield14.rest, 1), orderModifiedReturnBitfield14.rest) IN IF ~orderModifiedReturnBitfield15.ok THEN Fail ELSE
    LET orderModifiedReturnBitfield16 == ReadWhen(numberOfReturnBitfields.value >= 16, ReadUIntLE(orderModifiedReturnBitfield15.rest, 1), orderModifiedReturnBitfield15.rest) IN IF ~orderModifiedReturnBitfield16.ok THEN Fail ELSE
    LET orderModifiedReturnBitfield17 == ReadWhen(numberOfReturnBitfields.value >= 17, ReadUIntLE(orderModifiedReturnBitfield16.rest, 1), orderModifiedReturnBitfield16.rest) IN IF ~orderModifiedReturnBitfield17.ok THEN Fail ELSE
    LET orderModifiedReturnBitfield18 == ReadWhen(numberOfReturnBitfields.value >= 18, ReadBytes(orderModifiedReturnBitfield17.rest, 1), orderModifiedReturnBitfield17.rest) IN IF ~orderModifiedReturnBitfield18.ok THEN Fail ELSE
    LET side == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderModifiedReturnBitfield1.value # << >> /\ orderModifiedReturnBitfield1.value[1] % 2 > 0), ReadBytes(orderModifiedReturnBitfield18.rest, 1), orderModifiedReturnBitfield18.rest) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderModifiedReturnBitfield1.value # << >> /\ (orderModifiedReturnBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(side.rest, 8), side.rest) IN IF ~price.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderModifiedReturnBitfield1.value # << >> /\ (orderModifiedReturnBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(price.rest, 1), price.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderModifiedReturnBitfield1.value # << >> /\ (orderModifiedReturnBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderModifiedReturnBitfield1.value # << >> /\ (orderModifiedReturnBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET symbolLong == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderModifiedReturnBitfield2.value # << >> /\ orderModifiedReturnBitfield2.value[1] % 2 > 0), ReadBytes(minQty.rest, 8), minQty.rest) IN IF ~symbolLong.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderModifiedReturnBitfield2.value # << >> /\ (orderModifiedReturnBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(symbolLong.rest, 1), symbolLong.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderModifiedReturnBitfield3.value # << >> /\ orderModifiedReturnBitfield3.value[1] % 2 > 0), ReadBytes(capacity.rest, 16), capacity.rest) IN IF ~account.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderModifiedReturnBitfield3.value # << >> /\ (orderModifiedReturnBitfield3.value[1] \div 2) % 2 > 0), ReadBytes(account.rest, 4), account.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderModifiedReturnBitfield3.value # << >> /\ (orderModifiedReturnBitfield3.value[1] \div 4) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET orderQty == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderModifiedReturnBitfield3.value # << >> /\ (orderModifiedReturnBitfield3.value[1] \div 64) % 2 > 0), ReadBytes(clearingAccount.rest, 4), clearingAccount.rest) IN IF ~orderQty.ok THEN Fail ELSE
    LET preventMatch == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderModifiedReturnBitfield3.value # << >> /\ (orderModifiedReturnBitfield3.value[1] \div 128) % 2 > 0), ReadBytes(orderQty.rest, 3), orderQty.rest) IN IF ~preventMatch.ok THEN Fail ELSE
    LET maturityDate == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (orderModifiedReturnBitfield4.value # << >> /\ orderModifiedReturnBitfield4.value[1] % 2 > 0), ReadBytes(preventMatch.rest, 4), preventMatch.rest) IN IF ~maturityDate.ok THEN Fail ELSE
    LET openClose == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (orderModifiedReturnBitfield4.value # << >> /\ (orderModifiedReturnBitfield4.value[1] \div 8) % 2 > 0), ReadBytes(maturityDate.rest, 1), maturityDate.rest) IN IF ~openClose.ok THEN Fail ELSE
    LET origClOrdId == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderModifiedReturnBitfield5.value # << >> /\ orderModifiedReturnBitfield5.value[1] % 2 > 0), ReadBytes(openClose.rest, 20), openClose.rest) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET leavesQty == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderModifiedReturnBitfield5.value # << >> /\ (orderModifiedReturnBitfield5.value[1] \div 2) % 2 > 0), ReadBytes(origClOrdId.rest, 4), origClOrdId.rest) IN IF ~leavesQty.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderModifiedReturnBitfield5.value # << >> /\ (orderModifiedReturnBitfield5.value[1] \div 64) % 2 > 0), ReadBytes(leavesQty.rest, 1), leavesQty.rest) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET expireTime == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderModifiedReturnBitfield5.value # << >> /\ (orderModifiedReturnBitfield5.value[1] \div 128) % 2 > 0), ReadBytes(baseLiquidityIndicator.rest, 8), baseLiquidityIndicator.rest) IN IF ~expireTime.ok THEN Fail ELSE
    LET stopPx == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderModifiedReturnBitfield8.value # << >> /\ (orderModifiedReturnBitfield8.value[1] \div 4) % 2 > 0), ReadBytes(expireTime.rest, 8), expireTime.rest) IN IF ~stopPx.ok THEN Fail ELSE
    LET cmtaNumber == ReadWhen(numberOfReturnBitfields.value >= 9 /\ (orderModifiedReturnBitfield9.value # << >> /\ (orderModifiedReturnBitfield9.value[1] \div 32) % 2 > 0), ReadBytes(stopPx.rest, 4), stopPx.rest) IN IF ~cmtaNumber.ok THEN Fail ELSE
    LET ctiCode == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (orderModifiedReturnBitfield12.value # << >> /\ orderModifiedReturnBitfield12.value[1] % 2 > 0), ReadBytes(cmtaNumber.rest, 1), cmtaNumber.rest) IN IF ~ctiCode.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (orderModifiedReturnBitfield12.value # << >> /\ (orderModifiedReturnBitfield12.value[1] \div 2) % 2 > 0), ReadBytes(ctiCode.rest, 1), ctiCode.rest) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET oeoid == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (orderModifiedReturnBitfield12.value # << >> /\ (orderModifiedReturnBitfield12.value[1] \div 4) % 2 > 0), ReadBytes(manualOrderIndicator.rest, 18), manualOrderIndicator.rest) IN IF ~oeoid.ok THEN Fail ELSE
    LET frequentTraderId == ReadWhen(numberOfReturnBitfields.value >= 16 /\ (orderModifiedReturnBitfield16.value # << >> /\ orderModifiedReturnBitfield16.value[1] % 2 > 0), ReadBytes(oeoid.rest, 6), oeoid.rest) IN IF ~frequentTraderId.ok THEN Fail ELSE
    LET custOrderHandlingInst == ReadWhen(numberOfReturnBitfields.value >= 17 /\ (orderModifiedReturnBitfield17.value # << >> /\ (orderModifiedReturnBitfield17.value[1] \div 128) % 2 > 0), ReadBytes(frequentTraderId.rest, 1), frequentTraderId.rest) IN IF ~custOrderHandlingInst.ok THEN Fail ELSE
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
         side                          |-> side.value,
         price                         |-> price.value,
         ordType                       |-> ordType.value,
         timeInForce                   |-> timeInForce.value,
         minQty                        |-> minQty.value,
         symbolLong                    |-> symbolLong.value,
         capacity                      |-> capacity.value,
         account                       |-> account.value,
         clearingFirm                  |-> clearingFirm.value,
         clearingAccount               |-> clearingAccount.value,
         orderQty                      |-> orderQty.value,
         preventMatch                  |-> preventMatch.value,
         maturityDate                  |-> maturityDate.value,
         openClose                     |-> openClose.value,
         origClOrdId                   |-> origClOrdId.value,
         leavesQty                     |-> leavesQty.value,
         baseLiquidityIndicator        |-> baseLiquidityIndicator.value,
         expireTime                    |-> expireTime.value,
         stopPx                        |-> stopPx.value,
         cmtaNumber                    |-> cmtaNumber.value,
         ctiCode                       |-> ctiCode.value,
         manualOrderIndicator          |-> manualOrderIndicator.value,
         oeoid                         |-> oeoid.value,
         frequentTraderId              |-> frequentTraderId.value,
         custOrderHandlingInst         |-> custOrderHandlingInst.value ], custOrderHandlingInst.rest)

(* Order Modified Message with each field marked present by fields before it there exactly where they say *)
SettleOrderModifiedMessage(message) ==
    LET settled1 == [message EXCEPT !.orderModifiedReturnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.orderModifiedReturnBitfield1 = << >> THEN <<0>> ELSE message.orderModifiedReturnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.orderModifiedReturnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.orderModifiedReturnBitfield2 = << >> THEN <<0>> ELSE settled1.orderModifiedReturnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.orderModifiedReturnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.orderModifiedReturnBitfield3 = << >> THEN <<0>> ELSE settled2.orderModifiedReturnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.orderModifiedReturnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.orderModifiedReturnBitfield4 = << >> THEN <<0>> ELSE settled3.orderModifiedReturnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.orderModifiedReturnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.orderModifiedReturnBitfield5 = << >> THEN <<0>> ELSE settled4.orderModifiedReturnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.orderModifiedReturnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.orderModifiedReturnBitfield6 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled5.orderModifiedReturnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.orderModifiedReturnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.orderModifiedReturnBitfield7 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.orderModifiedReturnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.orderModifiedReturnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.orderModifiedReturnBitfield8 = << >> THEN <<0>> ELSE settled7.orderModifiedReturnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.orderModifiedReturnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.orderModifiedReturnBitfield9 = << >> THEN <<0>> ELSE settled8.orderModifiedReturnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.orderModifiedReturnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.orderModifiedReturnBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.orderModifiedReturnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.orderModifiedReturnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.orderModifiedReturnBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.orderModifiedReturnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.orderModifiedReturnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.orderModifiedReturnBitfield12 = << >> THEN <<0>> ELSE settled11.orderModifiedReturnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.orderModifiedReturnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.orderModifiedReturnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.orderModifiedReturnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.orderModifiedReturnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.orderModifiedReturnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.orderModifiedReturnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.orderModifiedReturnBitfield15 = IF settled14.numberOfReturnBitfields >= 15 THEN (IF settled14.orderModifiedReturnBitfield15 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.orderModifiedReturnBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.orderModifiedReturnBitfield16 = IF settled15.numberOfReturnBitfields >= 16 THEN (IF settled15.orderModifiedReturnBitfield16 = << >> THEN <<0>> ELSE settled15.orderModifiedReturnBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.orderModifiedReturnBitfield17 = IF settled16.numberOfReturnBitfields >= 17 THEN (IF settled16.orderModifiedReturnBitfield17 = << >> THEN <<0>> ELSE settled16.orderModifiedReturnBitfield17) ELSE << >>]
        settled18 == [settled17 EXCEPT !.orderModifiedReturnBitfield18 = IF settled17.numberOfReturnBitfields >= 18 THEN (IF settled17.orderModifiedReturnBitfield18 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.orderModifiedReturnBitfield18) ELSE << >>]
        settled19 == [settled18 EXCEPT !.side = IF settled18.numberOfReturnBitfields >= 1 /\ (settled18.orderModifiedReturnBitfield1 # << >> /\ settled18.orderModifiedReturnBitfield1[1] % 2 > 0) THEN (IF settled18.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled18.side) ELSE << >>]
        settled20 == [settled19 EXCEPT !.price = IF settled19.numberOfReturnBitfields >= 1 /\ (settled19.orderModifiedReturnBitfield1 # << >> /\ (settled19.orderModifiedReturnBitfield1[1] \div 4) % 2 > 0) THEN (IF settled19.price = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled19.price) ELSE << >>]
        settled21 == [settled20 EXCEPT !.ordType = IF settled20.numberOfReturnBitfields >= 1 /\ (settled20.orderModifiedReturnBitfield1 # << >> /\ (settled20.orderModifiedReturnBitfield1[1] \div 16) % 2 > 0) THEN (IF settled20.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled20.ordType) ELSE << >>]
        settled22 == [settled21 EXCEPT !.timeInForce = IF settled21.numberOfReturnBitfields >= 1 /\ (settled21.orderModifiedReturnBitfield1 # << >> /\ (settled21.orderModifiedReturnBitfield1[1] \div 32) % 2 > 0) THEN (IF settled21.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled21.timeInForce) ELSE << >>]
        settled23 == [settled22 EXCEPT !.minQty = IF settled22.numberOfReturnBitfields >= 1 /\ (settled22.orderModifiedReturnBitfield1 # << >> /\ (settled22.orderModifiedReturnBitfield1[1] \div 64) % 2 > 0) THEN (IF settled22.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled22.minQty) ELSE << >>]
        settled24 == [settled23 EXCEPT !.symbolLong = IF settled23.numberOfReturnBitfields >= 2 /\ (settled23.orderModifiedReturnBitfield2 # << >> /\ settled23.orderModifiedReturnBitfield2[1] % 2 > 0) THEN (IF settled23.symbolLong = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled23.symbolLong) ELSE << >>]
        settled25 == [settled24 EXCEPT !.capacity = IF settled24.numberOfReturnBitfields >= 2 /\ (settled24.orderModifiedReturnBitfield2 # << >> /\ (settled24.orderModifiedReturnBitfield2[1] \div 64) % 2 > 0) THEN (IF settled24.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled24.capacity) ELSE << >>]
        settled26 == [settled25 EXCEPT !.account = IF settled25.numberOfReturnBitfields >= 3 /\ (settled25.orderModifiedReturnBitfield3 # << >> /\ settled25.orderModifiedReturnBitfield3[1] % 2 > 0) THEN (IF settled25.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled25.account) ELSE << >>]
        settled27 == [settled26 EXCEPT !.clearingFirm = IF settled26.numberOfReturnBitfields >= 3 /\ (settled26.orderModifiedReturnBitfield3 # << >> /\ (settled26.orderModifiedReturnBitfield3[1] \div 2) % 2 > 0) THEN (IF settled26.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled26.clearingFirm) ELSE << >>]
        settled28 == [settled27 EXCEPT !.clearingAccount = IF settled27.numberOfReturnBitfields >= 3 /\ (settled27.orderModifiedReturnBitfield3 # << >> /\ (settled27.orderModifiedReturnBitfield3[1] \div 4) % 2 > 0) THEN (IF settled27.clearingAccount = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled27.clearingAccount) ELSE << >>]
        settled29 == [settled28 EXCEPT !.orderQty = IF settled28.numberOfReturnBitfields >= 3 /\ (settled28.orderModifiedReturnBitfield3 # << >> /\ (settled28.orderModifiedReturnBitfield3[1] \div 64) % 2 > 0) THEN (IF settled28.orderQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled28.orderQty) ELSE << >>]
        settled30 == [settled29 EXCEPT !.preventMatch = IF settled29.numberOfReturnBitfields >= 3 /\ (settled29.orderModifiedReturnBitfield3 # << >> /\ (settled29.orderModifiedReturnBitfield3[1] \div 128) % 2 > 0) THEN (IF settled29.preventMatch = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled29.preventMatch) ELSE << >>]
        settled31 == [settled30 EXCEPT !.maturityDate = IF settled30.numberOfReturnBitfields >= 4 /\ (settled30.orderModifiedReturnBitfield4 # << >> /\ settled30.orderModifiedReturnBitfield4[1] % 2 > 0) THEN (IF settled30.maturityDate = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled30.maturityDate) ELSE << >>]
        settled32 == [settled31 EXCEPT !.openClose = IF settled31.numberOfReturnBitfields >= 4 /\ (settled31.orderModifiedReturnBitfield4 # << >> /\ (settled31.orderModifiedReturnBitfield4[1] \div 8) % 2 > 0) THEN (IF settled31.openClose = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled31.openClose) ELSE << >>]
        settled33 == [settled32 EXCEPT !.origClOrdId = IF settled32.numberOfReturnBitfields >= 5 /\ (settled32.orderModifiedReturnBitfield5 # << >> /\ settled32.orderModifiedReturnBitfield5[1] % 2 > 0) THEN (IF settled32.origClOrdId = << >> THEN <<[i \in 1 .. 20 |-> 0]>> ELSE settled32.origClOrdId) ELSE << >>]
        settled34 == [settled33 EXCEPT !.leavesQty = IF settled33.numberOfReturnBitfields >= 5 /\ (settled33.orderModifiedReturnBitfield5 # << >> /\ (settled33.orderModifiedReturnBitfield5[1] \div 2) % 2 > 0) THEN (IF settled33.leavesQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled33.leavesQty) ELSE << >>]
        settled35 == [settled34 EXCEPT !.baseLiquidityIndicator = IF settled34.numberOfReturnBitfields >= 5 /\ (settled34.orderModifiedReturnBitfield5 # << >> /\ (settled34.orderModifiedReturnBitfield5[1] \div 64) % 2 > 0) THEN (IF settled34.baseLiquidityIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled34.baseLiquidityIndicator) ELSE << >>]
        settled36 == [settled35 EXCEPT !.expireTime = IF settled35.numberOfReturnBitfields >= 5 /\ (settled35.orderModifiedReturnBitfield5 # << >> /\ (settled35.orderModifiedReturnBitfield5[1] \div 128) % 2 > 0) THEN (IF settled35.expireTime = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled35.expireTime) ELSE << >>]
        settled37 == [settled36 EXCEPT !.stopPx = IF settled36.numberOfReturnBitfields >= 8 /\ (settled36.orderModifiedReturnBitfield8 # << >> /\ (settled36.orderModifiedReturnBitfield8[1] \div 4) % 2 > 0) THEN (IF settled36.stopPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled36.stopPx) ELSE << >>]
        settled38 == [settled37 EXCEPT !.cmtaNumber = IF settled37.numberOfReturnBitfields >= 9 /\ (settled37.orderModifiedReturnBitfield9 # << >> /\ (settled37.orderModifiedReturnBitfield9[1] \div 32) % 2 > 0) THEN (IF settled37.cmtaNumber = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled37.cmtaNumber) ELSE << >>]
        settled39 == [settled38 EXCEPT !.ctiCode = IF settled38.numberOfReturnBitfields >= 12 /\ (settled38.orderModifiedReturnBitfield12 # << >> /\ settled38.orderModifiedReturnBitfield12[1] % 2 > 0) THEN (IF settled38.ctiCode = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled38.ctiCode) ELSE << >>]
        settled40 == [settled39 EXCEPT !.manualOrderIndicator = IF settled39.numberOfReturnBitfields >= 12 /\ (settled39.orderModifiedReturnBitfield12 # << >> /\ (settled39.orderModifiedReturnBitfield12[1] \div 2) % 2 > 0) THEN (IF settled39.manualOrderIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled39.manualOrderIndicator) ELSE << >>]
        settled41 == [settled40 EXCEPT !.oeoid = IF settled40.numberOfReturnBitfields >= 12 /\ (settled40.orderModifiedReturnBitfield12 # << >> /\ (settled40.orderModifiedReturnBitfield12[1] \div 4) % 2 > 0) THEN (IF settled40.oeoid = << >> THEN <<[i \in 1 .. 18 |-> 0]>> ELSE settled40.oeoid) ELSE << >>]
        settled42 == [settled41 EXCEPT !.frequentTraderId = IF settled41.numberOfReturnBitfields >= 16 /\ (settled41.orderModifiedReturnBitfield16 # << >> /\ settled41.orderModifiedReturnBitfield16[1] % 2 > 0) THEN (IF settled41.frequentTraderId = << >> THEN <<[i \in 1 .. 6 |-> 0]>> ELSE settled41.frequentTraderId) ELSE << >>]
        settled43 == [settled42 EXCEPT !.custOrderHandlingInst = IF settled42.numberOfReturnBitfields >= 17 /\ (settled42.orderModifiedReturnBitfield17 # << >> /\ (settled42.orderModifiedReturnBitfield17[1] \div 128) % 2 > 0) THEN (IF settled42.custOrderHandlingInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled42.custOrderHandlingInst) ELSE << >>]
    IN  settled43

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
                                 side                          |-> << >>,
                                 price                         |-> << >>,
                                 ordType                       |-> << >>,
                                 timeInForce                   |-> << >>,
                                 minQty                        |-> << >>,
                                 symbolLong                    |-> << >>,
                                 capacity                      |-> << >>,
                                 account                       |-> << >>,
                                 clearingFirm                  |-> << >>,
                                 clearingAccount               |-> << >>,
                                 orderQty                      |-> << >>,
                                 preventMatch                  |-> << >>,
                                 maturityDate                  |-> << >>,
                                 openClose                     |-> << >>,
                                 origClOrdId                   |-> << >>,
                                 leavesQty                     |-> << >>,
                                 baseLiquidityIndicator        |-> << >>,
                                 expireTime                    |-> << >>,
                                 stopPx                        |-> << >>,
                                 cmtaNumber                    |-> << >>,
                                 ctiCode                       |-> << >>,
                                 manualOrderIndicator          |-> << >>,
                                 oeoid                         |-> << >>,
                                 frequentTraderId              |-> << >>,
                                 custOrderHandlingInst         |-> << >> ])

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
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 4, !.orderModifiedReturnBitfield4 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderModifiedReturnBitfield5 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 6, !.orderModifiedReturnBitfield6 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 7, !.orderModifiedReturnBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderModifiedReturnBitfield8 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 9, !.orderModifiedReturnBitfield9 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 10, !.orderModifiedReturnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 11, !.orderModifiedReturnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 12, !.orderModifiedReturnBitfield12 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 13, !.orderModifiedReturnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 14, !.orderModifiedReturnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 15, !.orderModifiedReturnBitfield15 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 16, !.orderModifiedReturnBitfield16 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 17, !.orderModifiedReturnBitfield17 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 18, !.orderModifiedReturnBitfield18 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderModifiedReturnBitfield1 = <<1>>, !.side = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderModifiedReturnBitfield1 = <<4>>, !.price = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderModifiedReturnBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderModifiedReturnBitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderModifiedReturnBitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 2, !.orderModifiedReturnBitfield2 = <<1>>, !.symbolLong = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 2, !.orderModifiedReturnBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderModifiedReturnBitfield3 = <<1>>, !.account = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderModifiedReturnBitfield3 = <<2>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderModifiedReturnBitfield3 = <<4>>, !.clearingAccount = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderModifiedReturnBitfield3 = <<64>>, !.orderQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderModifiedReturnBitfield3 = <<128>>, !.preventMatch = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 4, !.orderModifiedReturnBitfield4 = <<1>>, !.maturityDate = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 4, !.orderModifiedReturnBitfield4 = <<8>>, !.openClose = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderModifiedReturnBitfield5 = <<1>>, !.origClOrdId = one]) : one \in { <<held>> : held \in Sample(20) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderModifiedReturnBitfield5 = <<2>>, !.leavesQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderModifiedReturnBitfield5 = <<64>>, !.baseLiquidityIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderModifiedReturnBitfield5 = <<128>>, !.expireTime = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderModifiedReturnBitfield8 = <<4>>, !.stopPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 9, !.orderModifiedReturnBitfield9 = <<32>>, !.cmtaNumber = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 12, !.orderModifiedReturnBitfield12 = <<1>>, !.ctiCode = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 12, !.orderModifiedReturnBitfield12 = <<2>>, !.manualOrderIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 12, !.orderModifiedReturnBitfield12 = <<4>>, !.oeoid = one]) : one \in { <<held>> : held \in Sample(18) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 16, !.orderModifiedReturnBitfield16 = <<1>>, !.frequentTraderId = one]) : one \in { <<held>> : held \in Sample(6) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 17, !.orderModifiedReturnBitfield17 = <<128>>, !.custOrderHandlingInst = one]) : one \in { <<held>> : held \in Sample(1) } }

(***************************************************************************)
(* Quote Restated Message: 52 bytes                                        *)
(***************************************************************************)

QuoteRestatedMessage ==
    [ transactionTime   : Sample(8),
      quoteUpdateId     : Sample(16),
      orderId           : Sample(8),
      leavesQty         : Sample(4),
      workingPrice      : Sample(8),
      symbolShort       : Sample(6),
      side              : Sample(1),
      restatementReason : Sample(1) ]

EncodeQuoteRestatedMessage(message) ==
    message.transactionTime
        \o message.quoteUpdateId
        \o message.orderId
        \o message.leavesQty
        \o message.workingPrice
        \o message.symbolShort
        \o message.side
        \o message.restatementReason

DecodeQuoteRestatedMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET quoteUpdateId == ReadBytes(transactionTime.rest, 16) IN IF ~quoteUpdateId.ok THEN Fail ELSE
    LET orderId == ReadBytes(quoteUpdateId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(orderId.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET workingPrice == ReadBytes(leavesQty.rest, 8) IN IF ~workingPrice.ok THEN Fail ELSE
    LET symbolShort == ReadBytes(workingPrice.rest, 6) IN IF ~symbolShort.ok THEN Fail ELSE
    LET side == ReadBytes(symbolShort.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET restatementReason == ReadBytes(side.rest, 1) IN IF ~restatementReason.ok THEN Fail ELSE
    Ok([ transactionTime   |-> transactionTime.value,
         quoteUpdateId     |-> quoteUpdateId.value,
         orderId           |-> orderId.value,
         leavesQty         |-> leavesQty.value,
         workingPrice      |-> workingPrice.value,
         symbolShort       |-> symbolShort.value,
         side              |-> side.value,
         restatementReason |-> restatementReason.value ], restatementReason.rest)

ZeroQuoteRestatedMessage ==
    [ transactionTime   |-> [i \in 1 .. 8 |-> 0],
      quoteUpdateId     |-> [i \in 1 .. 16 |-> 0],
      orderId           |-> [i \in 1 .. 8 |-> 0],
      leavesQty         |-> [i \in 1 .. 4 |-> 0],
      workingPrice      |-> [i \in 1 .. 8 |-> 0],
      symbolShort       |-> [i \in 1 .. 6 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      restatementReason |-> [i \in 1 .. 1 |-> 0] ]

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
        \cup { [ZeroQuoteRestatedMessage EXCEPT !.restatementReason = one] : one \in Sample(1) }

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
      userModifyRejectedReturnBitfield18 : { << >> } \cup { <<held>> : held \in Sample(1) } ]

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
         userModifyRejectedReturnBitfield18 |-> userModifyRejectedReturnBitfield18.value ], userModifyRejectedReturnBitfield18.rest)

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
    IN  settled18

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
                                      userModifyRejectedReturnBitfield18 |-> << >> ])

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
      orderCancelledReturnBitfield4  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderCancelledReturnBitfield5  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderCancelledReturnBitfield6  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderCancelledReturnBitfield7  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderCancelledReturnBitfield8  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderCancelledReturnBitfield9  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderCancelledReturnBitfield10 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderCancelledReturnBitfield11 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderCancelledReturnBitfield12 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderCancelledReturnBitfield13 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderCancelledReturnBitfield14 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderCancelledReturnBitfield15 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderCancelledReturnBitfield16 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderCancelledReturnBitfield17 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderCancelledReturnBitfield18 : { << >> } \cup { <<held>> : held \in Sample(1) },
      side                           : { << >> } \cup { <<held>> : held \in Sample(1) },
      price                          : { << >> } \cup { <<held>> : held \in Sample(8) },
      ordType                        : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce                    : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                         : { << >> } \cup { <<held>> : held \in Sample(4) },
      symbolLong                     : { << >> } \cup { <<held>> : held \in Sample(8) },
      capacity                       : { << >> } \cup { <<held>> : held \in Sample(1) },
      account                        : { << >> } \cup { <<held>> : held \in Sample(16) },
      clearingFirm                   : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingAccount                : { << >> } \cup { <<held>> : held \in Sample(4) },
      orderQty                       : { << >> } \cup { <<held>> : held \in Sample(4) },
      preventMatch                   : { << >> } \cup { <<held>> : held \in Sample(3) },
      maturityDate                   : { << >> } \cup { <<held>> : held \in Sample(4) },
      openClose                      : { << >> } \cup { <<held>> : held \in Sample(1) },
      origClOrdId                    : { << >> } \cup { <<held>> : held \in Sample(20) },
      leavesQty                      : { << >> } \cup { <<held>> : held \in Sample(4) },
      lastShares                     : { << >> } \cup { <<held>> : held \in Sample(4) },
      lastPx                         : { << >> } \cup { <<held>> : held \in Sample(8) },
      expireTime                     : { << >> } \cup { <<held>> : held \in Sample(8) },
      secondaryOrderId               : { << >> } \cup { <<held>> : held \in Sample(8) },
      stopPx                         : { << >> } \cup { <<held>> : held \in Sample(8) },
      cmtaNumber                     : { << >> } \cup { <<held>> : held \in Sample(4) },
      ctiCode                        : { << >> } \cup { <<held>> : held \in Sample(1) },
      manualOrderIndicator           : { << >> } \cup { <<held>> : held \in Sample(1) },
      oeoid                          : { << >> } \cup { <<held>> : held \in Sample(18) },
      frequentTraderId               : { << >> } \cup { <<held>> : held \in Sample(6) },
      custOrderHandlingInst          : { << >> } \cup { <<held>> : held \in Sample(1) } ]

EncodeOrderCancelledMessage(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.cancelReason
        \o message.reserved1
        \o EncodeUIntBE(message.numberOfReturnBitfields, 1)
        \o (IF message.orderCancelledReturnBitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.orderCancelledReturnBitfield1[1], 1))
        \o (IF message.orderCancelledReturnBitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.orderCancelledReturnBitfield2[1], 1))
        \o (IF message.orderCancelledReturnBitfield3 = << >> THEN << >> ELSE EncodeUIntLE(message.orderCancelledReturnBitfield3[1], 1))
        \o (IF message.orderCancelledReturnBitfield4 = << >> THEN << >> ELSE EncodeUIntLE(message.orderCancelledReturnBitfield4[1], 1))
        \o (IF message.orderCancelledReturnBitfield5 = << >> THEN << >> ELSE EncodeUIntLE(message.orderCancelledReturnBitfield5[1], 1))
        \o (IF message.orderCancelledReturnBitfield6 = << >> THEN << >> ELSE EncodeUIntLE(message.orderCancelledReturnBitfield6[1], 1))
        \o (IF message.orderCancelledReturnBitfield7 = << >> THEN << >> ELSE message.orderCancelledReturnBitfield7[1])
        \o (IF message.orderCancelledReturnBitfield8 = << >> THEN << >> ELSE EncodeUIntLE(message.orderCancelledReturnBitfield8[1], 1))
        \o (IF message.orderCancelledReturnBitfield9 = << >> THEN << >> ELSE EncodeUIntLE(message.orderCancelledReturnBitfield9[1], 1))
        \o (IF message.orderCancelledReturnBitfield10 = << >> THEN << >> ELSE message.orderCancelledReturnBitfield10[1])
        \o (IF message.orderCancelledReturnBitfield11 = << >> THEN << >> ELSE message.orderCancelledReturnBitfield11[1])
        \o (IF message.orderCancelledReturnBitfield12 = << >> THEN << >> ELSE EncodeUIntLE(message.orderCancelledReturnBitfield12[1], 1))
        \o (IF message.orderCancelledReturnBitfield13 = << >> THEN << >> ELSE message.orderCancelledReturnBitfield13[1])
        \o (IF message.orderCancelledReturnBitfield14 = << >> THEN << >> ELSE message.orderCancelledReturnBitfield14[1])
        \o (IF message.orderCancelledReturnBitfield15 = << >> THEN << >> ELSE message.orderCancelledReturnBitfield15[1])
        \o (IF message.orderCancelledReturnBitfield16 = << >> THEN << >> ELSE EncodeUIntLE(message.orderCancelledReturnBitfield16[1], 1))
        \o (IF message.orderCancelledReturnBitfield17 = << >> THEN << >> ELSE EncodeUIntLE(message.orderCancelledReturnBitfield17[1], 1))
        \o (IF message.orderCancelledReturnBitfield18 = << >> THEN << >> ELSE message.orderCancelledReturnBitfield18[1])
        \o (IF message.side = << >> THEN << >> ELSE message.side[1])
        \o (IF message.price = << >> THEN << >> ELSE message.price[1])
        \o (IF message.ordType = << >> THEN << >> ELSE message.ordType[1])
        \o (IF message.timeInForce = << >> THEN << >> ELSE message.timeInForce[1])
        \o (IF message.minQty = << >> THEN << >> ELSE message.minQty[1])
        \o (IF message.symbolLong = << >> THEN << >> ELSE message.symbolLong[1])
        \o (IF message.capacity = << >> THEN << >> ELSE message.capacity[1])
        \o (IF message.account = << >> THEN << >> ELSE message.account[1])
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])
        \o (IF message.clearingAccount = << >> THEN << >> ELSE message.clearingAccount[1])
        \o (IF message.orderQty = << >> THEN << >> ELSE message.orderQty[1])
        \o (IF message.preventMatch = << >> THEN << >> ELSE message.preventMatch[1])
        \o (IF message.maturityDate = << >> THEN << >> ELSE message.maturityDate[1])
        \o (IF message.openClose = << >> THEN << >> ELSE message.openClose[1])
        \o (IF message.origClOrdId = << >> THEN << >> ELSE message.origClOrdId[1])
        \o (IF message.leavesQty = << >> THEN << >> ELSE message.leavesQty[1])
        \o (IF message.lastShares = << >> THEN << >> ELSE message.lastShares[1])
        \o (IF message.lastPx = << >> THEN << >> ELSE message.lastPx[1])
        \o (IF message.expireTime = << >> THEN << >> ELSE message.expireTime[1])
        \o (IF message.secondaryOrderId = << >> THEN << >> ELSE message.secondaryOrderId[1])
        \o (IF message.stopPx = << >> THEN << >> ELSE message.stopPx[1])
        \o (IF message.cmtaNumber = << >> THEN << >> ELSE message.cmtaNumber[1])
        \o (IF message.ctiCode = << >> THEN << >> ELSE message.ctiCode[1])
        \o (IF message.manualOrderIndicator = << >> THEN << >> ELSE message.manualOrderIndicator[1])
        \o (IF message.oeoid = << >> THEN << >> ELSE message.oeoid[1])
        \o (IF message.frequentTraderId = << >> THEN << >> ELSE message.frequentTraderId[1])
        \o (IF message.custOrderHandlingInst = << >> THEN << >> ELSE message.custOrderHandlingInst[1])

DecodeOrderCancelledMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET cancelReason == ReadBytes(clOrdId.rest, 1) IN IF ~cancelReason.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(cancelReason.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET numberOfReturnBitfields == ReadUIntBE(reserved1.rest, 1) IN IF ~numberOfReturnBitfields.ok THEN Fail ELSE
    LET orderCancelledReturnBitfield1 == ReadWhen(numberOfReturnBitfields.value >= 1, ReadUIntLE(numberOfReturnBitfields.rest, 1), numberOfReturnBitfields.rest) IN IF ~orderCancelledReturnBitfield1.ok THEN Fail ELSE
    LET orderCancelledReturnBitfield2 == ReadWhen(numberOfReturnBitfields.value >= 2, ReadUIntLE(orderCancelledReturnBitfield1.rest, 1), orderCancelledReturnBitfield1.rest) IN IF ~orderCancelledReturnBitfield2.ok THEN Fail ELSE
    LET orderCancelledReturnBitfield3 == ReadWhen(numberOfReturnBitfields.value >= 3, ReadUIntLE(orderCancelledReturnBitfield2.rest, 1), orderCancelledReturnBitfield2.rest) IN IF ~orderCancelledReturnBitfield3.ok THEN Fail ELSE
    LET orderCancelledReturnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadUIntLE(orderCancelledReturnBitfield3.rest, 1), orderCancelledReturnBitfield3.rest) IN IF ~orderCancelledReturnBitfield4.ok THEN Fail ELSE
    LET orderCancelledReturnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadUIntLE(orderCancelledReturnBitfield4.rest, 1), orderCancelledReturnBitfield4.rest) IN IF ~orderCancelledReturnBitfield5.ok THEN Fail ELSE
    LET orderCancelledReturnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadUIntLE(orderCancelledReturnBitfield5.rest, 1), orderCancelledReturnBitfield5.rest) IN IF ~orderCancelledReturnBitfield6.ok THEN Fail ELSE
    LET orderCancelledReturnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadBytes(orderCancelledReturnBitfield6.rest, 1), orderCancelledReturnBitfield6.rest) IN IF ~orderCancelledReturnBitfield7.ok THEN Fail ELSE
    LET orderCancelledReturnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadUIntLE(orderCancelledReturnBitfield7.rest, 1), orderCancelledReturnBitfield7.rest) IN IF ~orderCancelledReturnBitfield8.ok THEN Fail ELSE
    LET orderCancelledReturnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadUIntLE(orderCancelledReturnBitfield8.rest, 1), orderCancelledReturnBitfield8.rest) IN IF ~orderCancelledReturnBitfield9.ok THEN Fail ELSE
    LET orderCancelledReturnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadBytes(orderCancelledReturnBitfield9.rest, 1), orderCancelledReturnBitfield9.rest) IN IF ~orderCancelledReturnBitfield10.ok THEN Fail ELSE
    LET orderCancelledReturnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadBytes(orderCancelledReturnBitfield10.rest, 1), orderCancelledReturnBitfield10.rest) IN IF ~orderCancelledReturnBitfield11.ok THEN Fail ELSE
    LET orderCancelledReturnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadUIntLE(orderCancelledReturnBitfield11.rest, 1), orderCancelledReturnBitfield11.rest) IN IF ~orderCancelledReturnBitfield12.ok THEN Fail ELSE
    LET orderCancelledReturnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(orderCancelledReturnBitfield12.rest, 1), orderCancelledReturnBitfield12.rest) IN IF ~orderCancelledReturnBitfield13.ok THEN Fail ELSE
    LET orderCancelledReturnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(orderCancelledReturnBitfield13.rest, 1), orderCancelledReturnBitfield13.rest) IN IF ~orderCancelledReturnBitfield14.ok THEN Fail ELSE
    LET orderCancelledReturnBitfield15 == ReadWhen(numberOfReturnBitfields.value >= 15, ReadBytes(orderCancelledReturnBitfield14.rest, 1), orderCancelledReturnBitfield14.rest) IN IF ~orderCancelledReturnBitfield15.ok THEN Fail ELSE
    LET orderCancelledReturnBitfield16 == ReadWhen(numberOfReturnBitfields.value >= 16, ReadUIntLE(orderCancelledReturnBitfield15.rest, 1), orderCancelledReturnBitfield15.rest) IN IF ~orderCancelledReturnBitfield16.ok THEN Fail ELSE
    LET orderCancelledReturnBitfield17 == ReadWhen(numberOfReturnBitfields.value >= 17, ReadUIntLE(orderCancelledReturnBitfield16.rest, 1), orderCancelledReturnBitfield16.rest) IN IF ~orderCancelledReturnBitfield17.ok THEN Fail ELSE
    LET orderCancelledReturnBitfield18 == ReadWhen(numberOfReturnBitfields.value >= 18, ReadBytes(orderCancelledReturnBitfield17.rest, 1), orderCancelledReturnBitfield17.rest) IN IF ~orderCancelledReturnBitfield18.ok THEN Fail ELSE
    LET side == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderCancelledReturnBitfield1.value # << >> /\ orderCancelledReturnBitfield1.value[1] % 2 > 0), ReadBytes(orderCancelledReturnBitfield18.rest, 1), orderCancelledReturnBitfield18.rest) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderCancelledReturnBitfield1.value # << >> /\ (orderCancelledReturnBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(side.rest, 8), side.rest) IN IF ~price.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderCancelledReturnBitfield1.value # << >> /\ (orderCancelledReturnBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(price.rest, 1), price.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderCancelledReturnBitfield1.value # << >> /\ (orderCancelledReturnBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderCancelledReturnBitfield1.value # << >> /\ (orderCancelledReturnBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET symbolLong == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderCancelledReturnBitfield2.value # << >> /\ orderCancelledReturnBitfield2.value[1] % 2 > 0), ReadBytes(minQty.rest, 8), minQty.rest) IN IF ~symbolLong.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderCancelledReturnBitfield2.value # << >> /\ (orderCancelledReturnBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(symbolLong.rest, 1), symbolLong.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderCancelledReturnBitfield3.value # << >> /\ orderCancelledReturnBitfield3.value[1] % 2 > 0), ReadBytes(capacity.rest, 16), capacity.rest) IN IF ~account.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderCancelledReturnBitfield3.value # << >> /\ (orderCancelledReturnBitfield3.value[1] \div 2) % 2 > 0), ReadBytes(account.rest, 4), account.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderCancelledReturnBitfield3.value # << >> /\ (orderCancelledReturnBitfield3.value[1] \div 4) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET orderQty == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderCancelledReturnBitfield3.value # << >> /\ (orderCancelledReturnBitfield3.value[1] \div 64) % 2 > 0), ReadBytes(clearingAccount.rest, 4), clearingAccount.rest) IN IF ~orderQty.ok THEN Fail ELSE
    LET preventMatch == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderCancelledReturnBitfield3.value # << >> /\ (orderCancelledReturnBitfield3.value[1] \div 128) % 2 > 0), ReadBytes(orderQty.rest, 3), orderQty.rest) IN IF ~preventMatch.ok THEN Fail ELSE
    LET maturityDate == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (orderCancelledReturnBitfield4.value # << >> /\ orderCancelledReturnBitfield4.value[1] % 2 > 0), ReadBytes(preventMatch.rest, 4), preventMatch.rest) IN IF ~maturityDate.ok THEN Fail ELSE
    LET openClose == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (orderCancelledReturnBitfield4.value # << >> /\ (orderCancelledReturnBitfield4.value[1] \div 8) % 2 > 0), ReadBytes(maturityDate.rest, 1), maturityDate.rest) IN IF ~openClose.ok THEN Fail ELSE
    LET origClOrdId == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderCancelledReturnBitfield5.value # << >> /\ orderCancelledReturnBitfield5.value[1] % 2 > 0), ReadBytes(openClose.rest, 20), openClose.rest) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET leavesQty == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderCancelledReturnBitfield5.value # << >> /\ (orderCancelledReturnBitfield5.value[1] \div 2) % 2 > 0), ReadBytes(origClOrdId.rest, 4), origClOrdId.rest) IN IF ~leavesQty.ok THEN Fail ELSE
    LET lastShares == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderCancelledReturnBitfield5.value # << >> /\ (orderCancelledReturnBitfield5.value[1] \div 4) % 2 > 0), ReadBytes(leavesQty.rest, 4), leavesQty.rest) IN IF ~lastShares.ok THEN Fail ELSE
    LET lastPx == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderCancelledReturnBitfield5.value # << >> /\ (orderCancelledReturnBitfield5.value[1] \div 8) % 2 > 0), ReadBytes(lastShares.rest, 8), lastShares.rest) IN IF ~lastPx.ok THEN Fail ELSE
    LET expireTime == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderCancelledReturnBitfield5.value # << >> /\ (orderCancelledReturnBitfield5.value[1] \div 128) % 2 > 0), ReadBytes(lastPx.rest, 8), lastPx.rest) IN IF ~expireTime.ok THEN Fail ELSE
    LET secondaryOrderId == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (orderCancelledReturnBitfield6.value # << >> /\ orderCancelledReturnBitfield6.value[1] % 2 > 0), ReadBytes(expireTime.rest, 8), expireTime.rest) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET stopPx == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderCancelledReturnBitfield8.value # << >> /\ (orderCancelledReturnBitfield8.value[1] \div 4) % 2 > 0), ReadBytes(secondaryOrderId.rest, 8), secondaryOrderId.rest) IN IF ~stopPx.ok THEN Fail ELSE
    LET cmtaNumber == ReadWhen(numberOfReturnBitfields.value >= 9 /\ (orderCancelledReturnBitfield9.value # << >> /\ (orderCancelledReturnBitfield9.value[1] \div 32) % 2 > 0), ReadBytes(stopPx.rest, 4), stopPx.rest) IN IF ~cmtaNumber.ok THEN Fail ELSE
    LET ctiCode == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (orderCancelledReturnBitfield12.value # << >> /\ orderCancelledReturnBitfield12.value[1] % 2 > 0), ReadBytes(cmtaNumber.rest, 1), cmtaNumber.rest) IN IF ~ctiCode.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (orderCancelledReturnBitfield12.value # << >> /\ (orderCancelledReturnBitfield12.value[1] \div 2) % 2 > 0), ReadBytes(ctiCode.rest, 1), ctiCode.rest) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET oeoid == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (orderCancelledReturnBitfield12.value # << >> /\ (orderCancelledReturnBitfield12.value[1] \div 4) % 2 > 0), ReadBytes(manualOrderIndicator.rest, 18), manualOrderIndicator.rest) IN IF ~oeoid.ok THEN Fail ELSE
    LET frequentTraderId == ReadWhen(numberOfReturnBitfields.value >= 16 /\ (orderCancelledReturnBitfield16.value # << >> /\ orderCancelledReturnBitfield16.value[1] % 2 > 0), ReadBytes(oeoid.rest, 6), oeoid.rest) IN IF ~frequentTraderId.ok THEN Fail ELSE
    LET custOrderHandlingInst == ReadWhen(numberOfReturnBitfields.value >= 17 /\ (orderCancelledReturnBitfield17.value # << >> /\ (orderCancelledReturnBitfield17.value[1] \div 128) % 2 > 0), ReadBytes(frequentTraderId.rest, 1), frequentTraderId.rest) IN IF ~custOrderHandlingInst.ok THEN Fail ELSE
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
         side                           |-> side.value,
         price                          |-> price.value,
         ordType                        |-> ordType.value,
         timeInForce                    |-> timeInForce.value,
         minQty                         |-> minQty.value,
         symbolLong                     |-> symbolLong.value,
         capacity                       |-> capacity.value,
         account                        |-> account.value,
         clearingFirm                   |-> clearingFirm.value,
         clearingAccount                |-> clearingAccount.value,
         orderQty                       |-> orderQty.value,
         preventMatch                   |-> preventMatch.value,
         maturityDate                   |-> maturityDate.value,
         openClose                      |-> openClose.value,
         origClOrdId                    |-> origClOrdId.value,
         leavesQty                      |-> leavesQty.value,
         lastShares                     |-> lastShares.value,
         lastPx                         |-> lastPx.value,
         expireTime                     |-> expireTime.value,
         secondaryOrderId               |-> secondaryOrderId.value,
         stopPx                         |-> stopPx.value,
         cmtaNumber                     |-> cmtaNumber.value,
         ctiCode                        |-> ctiCode.value,
         manualOrderIndicator           |-> manualOrderIndicator.value,
         oeoid                          |-> oeoid.value,
         frequentTraderId               |-> frequentTraderId.value,
         custOrderHandlingInst          |-> custOrderHandlingInst.value ], custOrderHandlingInst.rest)

(* Order Cancelled Message with each field marked present by fields before it there exactly where they say *)
SettleOrderCancelledMessage(message) ==
    LET settled1 == [message EXCEPT !.orderCancelledReturnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.orderCancelledReturnBitfield1 = << >> THEN <<0>> ELSE message.orderCancelledReturnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.orderCancelledReturnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.orderCancelledReturnBitfield2 = << >> THEN <<0>> ELSE settled1.orderCancelledReturnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.orderCancelledReturnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.orderCancelledReturnBitfield3 = << >> THEN <<0>> ELSE settled2.orderCancelledReturnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.orderCancelledReturnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.orderCancelledReturnBitfield4 = << >> THEN <<0>> ELSE settled3.orderCancelledReturnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.orderCancelledReturnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.orderCancelledReturnBitfield5 = << >> THEN <<0>> ELSE settled4.orderCancelledReturnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.orderCancelledReturnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.orderCancelledReturnBitfield6 = << >> THEN <<0>> ELSE settled5.orderCancelledReturnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.orderCancelledReturnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.orderCancelledReturnBitfield7 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.orderCancelledReturnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.orderCancelledReturnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.orderCancelledReturnBitfield8 = << >> THEN <<0>> ELSE settled7.orderCancelledReturnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.orderCancelledReturnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.orderCancelledReturnBitfield9 = << >> THEN <<0>> ELSE settled8.orderCancelledReturnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.orderCancelledReturnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.orderCancelledReturnBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.orderCancelledReturnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.orderCancelledReturnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.orderCancelledReturnBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.orderCancelledReturnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.orderCancelledReturnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.orderCancelledReturnBitfield12 = << >> THEN <<0>> ELSE settled11.orderCancelledReturnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.orderCancelledReturnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.orderCancelledReturnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.orderCancelledReturnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.orderCancelledReturnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.orderCancelledReturnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.orderCancelledReturnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.orderCancelledReturnBitfield15 = IF settled14.numberOfReturnBitfields >= 15 THEN (IF settled14.orderCancelledReturnBitfield15 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.orderCancelledReturnBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.orderCancelledReturnBitfield16 = IF settled15.numberOfReturnBitfields >= 16 THEN (IF settled15.orderCancelledReturnBitfield16 = << >> THEN <<0>> ELSE settled15.orderCancelledReturnBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.orderCancelledReturnBitfield17 = IF settled16.numberOfReturnBitfields >= 17 THEN (IF settled16.orderCancelledReturnBitfield17 = << >> THEN <<0>> ELSE settled16.orderCancelledReturnBitfield17) ELSE << >>]
        settled18 == [settled17 EXCEPT !.orderCancelledReturnBitfield18 = IF settled17.numberOfReturnBitfields >= 18 THEN (IF settled17.orderCancelledReturnBitfield18 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.orderCancelledReturnBitfield18) ELSE << >>]
        settled19 == [settled18 EXCEPT !.side = IF settled18.numberOfReturnBitfields >= 1 /\ (settled18.orderCancelledReturnBitfield1 # << >> /\ settled18.orderCancelledReturnBitfield1[1] % 2 > 0) THEN (IF settled18.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled18.side) ELSE << >>]
        settled20 == [settled19 EXCEPT !.price = IF settled19.numberOfReturnBitfields >= 1 /\ (settled19.orderCancelledReturnBitfield1 # << >> /\ (settled19.orderCancelledReturnBitfield1[1] \div 4) % 2 > 0) THEN (IF settled19.price = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled19.price) ELSE << >>]
        settled21 == [settled20 EXCEPT !.ordType = IF settled20.numberOfReturnBitfields >= 1 /\ (settled20.orderCancelledReturnBitfield1 # << >> /\ (settled20.orderCancelledReturnBitfield1[1] \div 16) % 2 > 0) THEN (IF settled20.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled20.ordType) ELSE << >>]
        settled22 == [settled21 EXCEPT !.timeInForce = IF settled21.numberOfReturnBitfields >= 1 /\ (settled21.orderCancelledReturnBitfield1 # << >> /\ (settled21.orderCancelledReturnBitfield1[1] \div 32) % 2 > 0) THEN (IF settled21.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled21.timeInForce) ELSE << >>]
        settled23 == [settled22 EXCEPT !.minQty = IF settled22.numberOfReturnBitfields >= 1 /\ (settled22.orderCancelledReturnBitfield1 # << >> /\ (settled22.orderCancelledReturnBitfield1[1] \div 64) % 2 > 0) THEN (IF settled22.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled22.minQty) ELSE << >>]
        settled24 == [settled23 EXCEPT !.symbolLong = IF settled23.numberOfReturnBitfields >= 2 /\ (settled23.orderCancelledReturnBitfield2 # << >> /\ settled23.orderCancelledReturnBitfield2[1] % 2 > 0) THEN (IF settled23.symbolLong = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled23.symbolLong) ELSE << >>]
        settled25 == [settled24 EXCEPT !.capacity = IF settled24.numberOfReturnBitfields >= 2 /\ (settled24.orderCancelledReturnBitfield2 # << >> /\ (settled24.orderCancelledReturnBitfield2[1] \div 64) % 2 > 0) THEN (IF settled24.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled24.capacity) ELSE << >>]
        settled26 == [settled25 EXCEPT !.account = IF settled25.numberOfReturnBitfields >= 3 /\ (settled25.orderCancelledReturnBitfield3 # << >> /\ settled25.orderCancelledReturnBitfield3[1] % 2 > 0) THEN (IF settled25.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled25.account) ELSE << >>]
        settled27 == [settled26 EXCEPT !.clearingFirm = IF settled26.numberOfReturnBitfields >= 3 /\ (settled26.orderCancelledReturnBitfield3 # << >> /\ (settled26.orderCancelledReturnBitfield3[1] \div 2) % 2 > 0) THEN (IF settled26.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled26.clearingFirm) ELSE << >>]
        settled28 == [settled27 EXCEPT !.clearingAccount = IF settled27.numberOfReturnBitfields >= 3 /\ (settled27.orderCancelledReturnBitfield3 # << >> /\ (settled27.orderCancelledReturnBitfield3[1] \div 4) % 2 > 0) THEN (IF settled27.clearingAccount = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled27.clearingAccount) ELSE << >>]
        settled29 == [settled28 EXCEPT !.orderQty = IF settled28.numberOfReturnBitfields >= 3 /\ (settled28.orderCancelledReturnBitfield3 # << >> /\ (settled28.orderCancelledReturnBitfield3[1] \div 64) % 2 > 0) THEN (IF settled28.orderQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled28.orderQty) ELSE << >>]
        settled30 == [settled29 EXCEPT !.preventMatch = IF settled29.numberOfReturnBitfields >= 3 /\ (settled29.orderCancelledReturnBitfield3 # << >> /\ (settled29.orderCancelledReturnBitfield3[1] \div 128) % 2 > 0) THEN (IF settled29.preventMatch = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled29.preventMatch) ELSE << >>]
        settled31 == [settled30 EXCEPT !.maturityDate = IF settled30.numberOfReturnBitfields >= 4 /\ (settled30.orderCancelledReturnBitfield4 # << >> /\ settled30.orderCancelledReturnBitfield4[1] % 2 > 0) THEN (IF settled30.maturityDate = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled30.maturityDate) ELSE << >>]
        settled32 == [settled31 EXCEPT !.openClose = IF settled31.numberOfReturnBitfields >= 4 /\ (settled31.orderCancelledReturnBitfield4 # << >> /\ (settled31.orderCancelledReturnBitfield4[1] \div 8) % 2 > 0) THEN (IF settled31.openClose = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled31.openClose) ELSE << >>]
        settled33 == [settled32 EXCEPT !.origClOrdId = IF settled32.numberOfReturnBitfields >= 5 /\ (settled32.orderCancelledReturnBitfield5 # << >> /\ settled32.orderCancelledReturnBitfield5[1] % 2 > 0) THEN (IF settled32.origClOrdId = << >> THEN <<[i \in 1 .. 20 |-> 0]>> ELSE settled32.origClOrdId) ELSE << >>]
        settled34 == [settled33 EXCEPT !.leavesQty = IF settled33.numberOfReturnBitfields >= 5 /\ (settled33.orderCancelledReturnBitfield5 # << >> /\ (settled33.orderCancelledReturnBitfield5[1] \div 2) % 2 > 0) THEN (IF settled33.leavesQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled33.leavesQty) ELSE << >>]
        settled35 == [settled34 EXCEPT !.lastShares = IF settled34.numberOfReturnBitfields >= 5 /\ (settled34.orderCancelledReturnBitfield5 # << >> /\ (settled34.orderCancelledReturnBitfield5[1] \div 4) % 2 > 0) THEN (IF settled34.lastShares = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled34.lastShares) ELSE << >>]
        settled36 == [settled35 EXCEPT !.lastPx = IF settled35.numberOfReturnBitfields >= 5 /\ (settled35.orderCancelledReturnBitfield5 # << >> /\ (settled35.orderCancelledReturnBitfield5[1] \div 8) % 2 > 0) THEN (IF settled35.lastPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled35.lastPx) ELSE << >>]
        settled37 == [settled36 EXCEPT !.expireTime = IF settled36.numberOfReturnBitfields >= 5 /\ (settled36.orderCancelledReturnBitfield5 # << >> /\ (settled36.orderCancelledReturnBitfield5[1] \div 128) % 2 > 0) THEN (IF settled36.expireTime = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled36.expireTime) ELSE << >>]
        settled38 == [settled37 EXCEPT !.secondaryOrderId = IF settled37.numberOfReturnBitfields >= 6 /\ (settled37.orderCancelledReturnBitfield6 # << >> /\ settled37.orderCancelledReturnBitfield6[1] % 2 > 0) THEN (IF settled37.secondaryOrderId = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled37.secondaryOrderId) ELSE << >>]
        settled39 == [settled38 EXCEPT !.stopPx = IF settled38.numberOfReturnBitfields >= 8 /\ (settled38.orderCancelledReturnBitfield8 # << >> /\ (settled38.orderCancelledReturnBitfield8[1] \div 4) % 2 > 0) THEN (IF settled38.stopPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled38.stopPx) ELSE << >>]
        settled40 == [settled39 EXCEPT !.cmtaNumber = IF settled39.numberOfReturnBitfields >= 9 /\ (settled39.orderCancelledReturnBitfield9 # << >> /\ (settled39.orderCancelledReturnBitfield9[1] \div 32) % 2 > 0) THEN (IF settled39.cmtaNumber = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled39.cmtaNumber) ELSE << >>]
        settled41 == [settled40 EXCEPT !.ctiCode = IF settled40.numberOfReturnBitfields >= 12 /\ (settled40.orderCancelledReturnBitfield12 # << >> /\ settled40.orderCancelledReturnBitfield12[1] % 2 > 0) THEN (IF settled40.ctiCode = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled40.ctiCode) ELSE << >>]
        settled42 == [settled41 EXCEPT !.manualOrderIndicator = IF settled41.numberOfReturnBitfields >= 12 /\ (settled41.orderCancelledReturnBitfield12 # << >> /\ (settled41.orderCancelledReturnBitfield12[1] \div 2) % 2 > 0) THEN (IF settled41.manualOrderIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled41.manualOrderIndicator) ELSE << >>]
        settled43 == [settled42 EXCEPT !.oeoid = IF settled42.numberOfReturnBitfields >= 12 /\ (settled42.orderCancelledReturnBitfield12 # << >> /\ (settled42.orderCancelledReturnBitfield12[1] \div 4) % 2 > 0) THEN (IF settled42.oeoid = << >> THEN <<[i \in 1 .. 18 |-> 0]>> ELSE settled42.oeoid) ELSE << >>]
        settled44 == [settled43 EXCEPT !.frequentTraderId = IF settled43.numberOfReturnBitfields >= 16 /\ (settled43.orderCancelledReturnBitfield16 # << >> /\ settled43.orderCancelledReturnBitfield16[1] % 2 > 0) THEN (IF settled43.frequentTraderId = << >> THEN <<[i \in 1 .. 6 |-> 0]>> ELSE settled43.frequentTraderId) ELSE << >>]
        settled45 == [settled44 EXCEPT !.custOrderHandlingInst = IF settled44.numberOfReturnBitfields >= 17 /\ (settled44.orderCancelledReturnBitfield17 # << >> /\ (settled44.orderCancelledReturnBitfield17[1] \div 128) % 2 > 0) THEN (IF settled44.custOrderHandlingInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled44.custOrderHandlingInst) ELSE << >>]
    IN  settled45

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
                                  side                           |-> << >>,
                                  price                          |-> << >>,
                                  ordType                        |-> << >>,
                                  timeInForce                    |-> << >>,
                                  minQty                         |-> << >>,
                                  symbolLong                     |-> << >>,
                                  capacity                       |-> << >>,
                                  account                        |-> << >>,
                                  clearingFirm                   |-> << >>,
                                  clearingAccount                |-> << >>,
                                  orderQty                       |-> << >>,
                                  preventMatch                   |-> << >>,
                                  maturityDate                   |-> << >>,
                                  openClose                      |-> << >>,
                                  origClOrdId                    |-> << >>,
                                  leavesQty                      |-> << >>,
                                  lastShares                     |-> << >>,
                                  lastPx                         |-> << >>,
                                  expireTime                     |-> << >>,
                                  secondaryOrderId               |-> << >>,
                                  stopPx                         |-> << >>,
                                  cmtaNumber                     |-> << >>,
                                  ctiCode                        |-> << >>,
                                  manualOrderIndicator           |-> << >>,
                                  oeoid                          |-> << >>,
                                  frequentTraderId               |-> << >>,
                                  custOrderHandlingInst          |-> << >> ])

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
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 4, !.orderCancelledReturnBitfield4 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderCancelledReturnBitfield5 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 6, !.orderCancelledReturnBitfield6 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 7, !.orderCancelledReturnBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderCancelledReturnBitfield8 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 9, !.orderCancelledReturnBitfield9 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 10, !.orderCancelledReturnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 11, !.orderCancelledReturnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 12, !.orderCancelledReturnBitfield12 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 13, !.orderCancelledReturnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 14, !.orderCancelledReturnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 15, !.orderCancelledReturnBitfield15 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 16, !.orderCancelledReturnBitfield16 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 17, !.orderCancelledReturnBitfield17 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 18, !.orderCancelledReturnBitfield18 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderCancelledReturnBitfield1 = <<1>>, !.side = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderCancelledReturnBitfield1 = <<4>>, !.price = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderCancelledReturnBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderCancelledReturnBitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderCancelledReturnBitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 2, !.orderCancelledReturnBitfield2 = <<1>>, !.symbolLong = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 2, !.orderCancelledReturnBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderCancelledReturnBitfield3 = <<1>>, !.account = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderCancelledReturnBitfield3 = <<2>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderCancelledReturnBitfield3 = <<4>>, !.clearingAccount = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderCancelledReturnBitfield3 = <<64>>, !.orderQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderCancelledReturnBitfield3 = <<128>>, !.preventMatch = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 4, !.orderCancelledReturnBitfield4 = <<1>>, !.maturityDate = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 4, !.orderCancelledReturnBitfield4 = <<8>>, !.openClose = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderCancelledReturnBitfield5 = <<1>>, !.origClOrdId = one]) : one \in { <<held>> : held \in Sample(20) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderCancelledReturnBitfield5 = <<2>>, !.leavesQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderCancelledReturnBitfield5 = <<4>>, !.lastShares = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderCancelledReturnBitfield5 = <<8>>, !.lastPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderCancelledReturnBitfield5 = <<128>>, !.expireTime = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 6, !.orderCancelledReturnBitfield6 = <<1>>, !.secondaryOrderId = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderCancelledReturnBitfield8 = <<4>>, !.stopPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 9, !.orderCancelledReturnBitfield9 = <<32>>, !.cmtaNumber = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 12, !.orderCancelledReturnBitfield12 = <<1>>, !.ctiCode = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 12, !.orderCancelledReturnBitfield12 = <<2>>, !.manualOrderIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 12, !.orderCancelledReturnBitfield12 = <<4>>, !.oeoid = one]) : one \in { <<held>> : held \in Sample(18) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 16, !.orderCancelledReturnBitfield16 = <<1>>, !.frequentTraderId = one]) : one \in { <<held>> : held \in Sample(6) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 17, !.orderCancelledReturnBitfield17 = <<128>>, !.custOrderHandlingInst = one]) : one \in { <<held>> : held \in Sample(1) } }

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
    [ transactionTime                : Sample(8),
      clOrdId                        : Sample(20),
      cancelRejectReason             : Sample(1),
      text                           : Sample(60),
      reserved1                      : Sample(1),
      numberOfReturnBitfields        : 0 .. 255,
      cancelRejectedReturnBitfield1  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      cancelRejectedReturnBitfield2  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      cancelRejectedReturnBitfield3  : { << >> } \cup { <<held>> : held \in Sample(1) },
      cancelRejectedReturnBitfield4  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      cancelRejectedReturnBitfield5  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      cancelRejectedReturnBitfield6  : { << >> } \cup { <<held>> : held \in Sample(1) },
      cancelRejectedReturnBitfield7  : { << >> } \cup { <<held>> : held \in Sample(1) },
      cancelRejectedReturnBitfield8  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      cancelRejectedReturnBitfield9  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      cancelRejectedReturnBitfield10 : { << >> } \cup { <<held>> : held \in Sample(1) },
      cancelRejectedReturnBitfield11 : { << >> } \cup { <<held>> : held \in Sample(1) },
      cancelRejectedReturnBitfield12 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      cancelRejectedReturnBitfield13 : { << >> } \cup { <<held>> : held \in Sample(1) },
      cancelRejectedReturnBitfield14 : { << >> } \cup { <<held>> : held \in Sample(1) },
      cancelRejectedReturnBitfield15 : { << >> } \cup { <<held>> : held \in Sample(1) },
      cancelRejectedReturnBitfield16 : { << >> } \cup { <<held>> : held \in Sample(1) },
      cancelRejectedReturnBitfield17 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      cancelRejectedReturnBitfield18 : { << >> } \cup { <<held>> : held \in Sample(1) },
      side                           : { << >> } \cup { <<held>> : held \in Sample(1) },
      price                          : { << >> } \cup { <<held>> : held \in Sample(8) },
      ordType                        : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce                    : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                         : { << >> } \cup { <<held>> : held \in Sample(4) },
      symbolLong                     : { << >> } \cup { <<held>> : held \in Sample(8) },
      capacity                       : { << >> } \cup { <<held>> : held \in Sample(1) },
      maturityDate                   : { << >> } \cup { <<held>> : held \in Sample(4) },
      openClose                      : { << >> } \cup { <<held>> : held \in Sample(1) },
      expireTime                     : { << >> } \cup { <<held>> : held \in Sample(8) },
      stopPx                         : { << >> } \cup { <<held>> : held \in Sample(8) },
      cmtaNumber                     : { << >> } \cup { <<held>> : held \in Sample(4) },
      ctiCode                        : { << >> } \cup { <<held>> : held \in Sample(1) },
      manualOrderIndicator           : { << >> } \cup { <<held>> : held \in Sample(1) },
      oeoid                          : { << >> } \cup { <<held>> : held \in Sample(18) },
      custOrderHandlingInst          : { << >> } \cup { <<held>> : held \in Sample(1) } ]

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
        \o (IF message.cancelRejectedReturnBitfield4 = << >> THEN << >> ELSE EncodeUIntLE(message.cancelRejectedReturnBitfield4[1], 1))
        \o (IF message.cancelRejectedReturnBitfield5 = << >> THEN << >> ELSE EncodeUIntLE(message.cancelRejectedReturnBitfield5[1], 1))
        \o (IF message.cancelRejectedReturnBitfield6 = << >> THEN << >> ELSE message.cancelRejectedReturnBitfield6[1])
        \o (IF message.cancelRejectedReturnBitfield7 = << >> THEN << >> ELSE message.cancelRejectedReturnBitfield7[1])
        \o (IF message.cancelRejectedReturnBitfield8 = << >> THEN << >> ELSE EncodeUIntLE(message.cancelRejectedReturnBitfield8[1], 1))
        \o (IF message.cancelRejectedReturnBitfield9 = << >> THEN << >> ELSE EncodeUIntLE(message.cancelRejectedReturnBitfield9[1], 1))
        \o (IF message.cancelRejectedReturnBitfield10 = << >> THEN << >> ELSE message.cancelRejectedReturnBitfield10[1])
        \o (IF message.cancelRejectedReturnBitfield11 = << >> THEN << >> ELSE message.cancelRejectedReturnBitfield11[1])
        \o (IF message.cancelRejectedReturnBitfield12 = << >> THEN << >> ELSE EncodeUIntLE(message.cancelRejectedReturnBitfield12[1], 1))
        \o (IF message.cancelRejectedReturnBitfield13 = << >> THEN << >> ELSE message.cancelRejectedReturnBitfield13[1])
        \o (IF message.cancelRejectedReturnBitfield14 = << >> THEN << >> ELSE message.cancelRejectedReturnBitfield14[1])
        \o (IF message.cancelRejectedReturnBitfield15 = << >> THEN << >> ELSE message.cancelRejectedReturnBitfield15[1])
        \o (IF message.cancelRejectedReturnBitfield16 = << >> THEN << >> ELSE message.cancelRejectedReturnBitfield16[1])
        \o (IF message.cancelRejectedReturnBitfield17 = << >> THEN << >> ELSE EncodeUIntLE(message.cancelRejectedReturnBitfield17[1], 1))
        \o (IF message.cancelRejectedReturnBitfield18 = << >> THEN << >> ELSE message.cancelRejectedReturnBitfield18[1])
        \o (IF message.side = << >> THEN << >> ELSE message.side[1])
        \o (IF message.price = << >> THEN << >> ELSE message.price[1])
        \o (IF message.ordType = << >> THEN << >> ELSE message.ordType[1])
        \o (IF message.timeInForce = << >> THEN << >> ELSE message.timeInForce[1])
        \o (IF message.minQty = << >> THEN << >> ELSE message.minQty[1])
        \o (IF message.symbolLong = << >> THEN << >> ELSE message.symbolLong[1])
        \o (IF message.capacity = << >> THEN << >> ELSE message.capacity[1])
        \o (IF message.maturityDate = << >> THEN << >> ELSE message.maturityDate[1])
        \o (IF message.openClose = << >> THEN << >> ELSE message.openClose[1])
        \o (IF message.expireTime = << >> THEN << >> ELSE message.expireTime[1])
        \o (IF message.stopPx = << >> THEN << >> ELSE message.stopPx[1])
        \o (IF message.cmtaNumber = << >> THEN << >> ELSE message.cmtaNumber[1])
        \o (IF message.ctiCode = << >> THEN << >> ELSE message.ctiCode[1])
        \o (IF message.manualOrderIndicator = << >> THEN << >> ELSE message.manualOrderIndicator[1])
        \o (IF message.oeoid = << >> THEN << >> ELSE message.oeoid[1])
        \o (IF message.custOrderHandlingInst = << >> THEN << >> ELSE message.custOrderHandlingInst[1])

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
    LET cancelRejectedReturnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadUIntLE(cancelRejectedReturnBitfield3.rest, 1), cancelRejectedReturnBitfield3.rest) IN IF ~cancelRejectedReturnBitfield4.ok THEN Fail ELSE
    LET cancelRejectedReturnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadUIntLE(cancelRejectedReturnBitfield4.rest, 1), cancelRejectedReturnBitfield4.rest) IN IF ~cancelRejectedReturnBitfield5.ok THEN Fail ELSE
    LET cancelRejectedReturnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadBytes(cancelRejectedReturnBitfield5.rest, 1), cancelRejectedReturnBitfield5.rest) IN IF ~cancelRejectedReturnBitfield6.ok THEN Fail ELSE
    LET cancelRejectedReturnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadBytes(cancelRejectedReturnBitfield6.rest, 1), cancelRejectedReturnBitfield6.rest) IN IF ~cancelRejectedReturnBitfield7.ok THEN Fail ELSE
    LET cancelRejectedReturnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadUIntLE(cancelRejectedReturnBitfield7.rest, 1), cancelRejectedReturnBitfield7.rest) IN IF ~cancelRejectedReturnBitfield8.ok THEN Fail ELSE
    LET cancelRejectedReturnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadUIntLE(cancelRejectedReturnBitfield8.rest, 1), cancelRejectedReturnBitfield8.rest) IN IF ~cancelRejectedReturnBitfield9.ok THEN Fail ELSE
    LET cancelRejectedReturnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadBytes(cancelRejectedReturnBitfield9.rest, 1), cancelRejectedReturnBitfield9.rest) IN IF ~cancelRejectedReturnBitfield10.ok THEN Fail ELSE
    LET cancelRejectedReturnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadBytes(cancelRejectedReturnBitfield10.rest, 1), cancelRejectedReturnBitfield10.rest) IN IF ~cancelRejectedReturnBitfield11.ok THEN Fail ELSE
    LET cancelRejectedReturnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadUIntLE(cancelRejectedReturnBitfield11.rest, 1), cancelRejectedReturnBitfield11.rest) IN IF ~cancelRejectedReturnBitfield12.ok THEN Fail ELSE
    LET cancelRejectedReturnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(cancelRejectedReturnBitfield12.rest, 1), cancelRejectedReturnBitfield12.rest) IN IF ~cancelRejectedReturnBitfield13.ok THEN Fail ELSE
    LET cancelRejectedReturnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(cancelRejectedReturnBitfield13.rest, 1), cancelRejectedReturnBitfield13.rest) IN IF ~cancelRejectedReturnBitfield14.ok THEN Fail ELSE
    LET cancelRejectedReturnBitfield15 == ReadWhen(numberOfReturnBitfields.value >= 15, ReadBytes(cancelRejectedReturnBitfield14.rest, 1), cancelRejectedReturnBitfield14.rest) IN IF ~cancelRejectedReturnBitfield15.ok THEN Fail ELSE
    LET cancelRejectedReturnBitfield16 == ReadWhen(numberOfReturnBitfields.value >= 16, ReadBytes(cancelRejectedReturnBitfield15.rest, 1), cancelRejectedReturnBitfield15.rest) IN IF ~cancelRejectedReturnBitfield16.ok THEN Fail ELSE
    LET cancelRejectedReturnBitfield17 == ReadWhen(numberOfReturnBitfields.value >= 17, ReadUIntLE(cancelRejectedReturnBitfield16.rest, 1), cancelRejectedReturnBitfield16.rest) IN IF ~cancelRejectedReturnBitfield17.ok THEN Fail ELSE
    LET cancelRejectedReturnBitfield18 == ReadWhen(numberOfReturnBitfields.value >= 18, ReadBytes(cancelRejectedReturnBitfield17.rest, 1), cancelRejectedReturnBitfield17.rest) IN IF ~cancelRejectedReturnBitfield18.ok THEN Fail ELSE
    LET side == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (cancelRejectedReturnBitfield1.value # << >> /\ cancelRejectedReturnBitfield1.value[1] % 2 > 0), ReadBytes(cancelRejectedReturnBitfield18.rest, 1), cancelRejectedReturnBitfield18.rest) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (cancelRejectedReturnBitfield1.value # << >> /\ (cancelRejectedReturnBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(side.rest, 8), side.rest) IN IF ~price.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (cancelRejectedReturnBitfield1.value # << >> /\ (cancelRejectedReturnBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(price.rest, 1), price.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (cancelRejectedReturnBitfield1.value # << >> /\ (cancelRejectedReturnBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (cancelRejectedReturnBitfield1.value # << >> /\ (cancelRejectedReturnBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET symbolLong == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (cancelRejectedReturnBitfield2.value # << >> /\ cancelRejectedReturnBitfield2.value[1] % 2 > 0), ReadBytes(minQty.rest, 8), minQty.rest) IN IF ~symbolLong.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (cancelRejectedReturnBitfield2.value # << >> /\ (cancelRejectedReturnBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(symbolLong.rest, 1), symbolLong.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET maturityDate == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (cancelRejectedReturnBitfield4.value # << >> /\ cancelRejectedReturnBitfield4.value[1] % 2 > 0), ReadBytes(capacity.rest, 4), capacity.rest) IN IF ~maturityDate.ok THEN Fail ELSE
    LET openClose == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (cancelRejectedReturnBitfield4.value # << >> /\ (cancelRejectedReturnBitfield4.value[1] \div 8) % 2 > 0), ReadBytes(maturityDate.rest, 1), maturityDate.rest) IN IF ~openClose.ok THEN Fail ELSE
    LET expireTime == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (cancelRejectedReturnBitfield5.value # << >> /\ (cancelRejectedReturnBitfield5.value[1] \div 128) % 2 > 0), ReadBytes(openClose.rest, 8), openClose.rest) IN IF ~expireTime.ok THEN Fail ELSE
    LET stopPx == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (cancelRejectedReturnBitfield8.value # << >> /\ (cancelRejectedReturnBitfield8.value[1] \div 4) % 2 > 0), ReadBytes(expireTime.rest, 8), expireTime.rest) IN IF ~stopPx.ok THEN Fail ELSE
    LET cmtaNumber == ReadWhen(numberOfReturnBitfields.value >= 9 /\ (cancelRejectedReturnBitfield9.value # << >> /\ (cancelRejectedReturnBitfield9.value[1] \div 32) % 2 > 0), ReadBytes(stopPx.rest, 4), stopPx.rest) IN IF ~cmtaNumber.ok THEN Fail ELSE
    LET ctiCode == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (cancelRejectedReturnBitfield12.value # << >> /\ cancelRejectedReturnBitfield12.value[1] % 2 > 0), ReadBytes(cmtaNumber.rest, 1), cmtaNumber.rest) IN IF ~ctiCode.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (cancelRejectedReturnBitfield12.value # << >> /\ (cancelRejectedReturnBitfield12.value[1] \div 2) % 2 > 0), ReadBytes(ctiCode.rest, 1), ctiCode.rest) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET oeoid == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (cancelRejectedReturnBitfield12.value # << >> /\ (cancelRejectedReturnBitfield12.value[1] \div 4) % 2 > 0), ReadBytes(manualOrderIndicator.rest, 18), manualOrderIndicator.rest) IN IF ~oeoid.ok THEN Fail ELSE
    LET custOrderHandlingInst == ReadWhen(numberOfReturnBitfields.value >= 17 /\ (cancelRejectedReturnBitfield17.value # << >> /\ (cancelRejectedReturnBitfield17.value[1] \div 128) % 2 > 0), ReadBytes(oeoid.rest, 1), oeoid.rest) IN IF ~custOrderHandlingInst.ok THEN Fail ELSE
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
         side                           |-> side.value,
         price                          |-> price.value,
         ordType                        |-> ordType.value,
         timeInForce                    |-> timeInForce.value,
         minQty                         |-> minQty.value,
         symbolLong                     |-> symbolLong.value,
         capacity                       |-> capacity.value,
         maturityDate                   |-> maturityDate.value,
         openClose                      |-> openClose.value,
         expireTime                     |-> expireTime.value,
         stopPx                         |-> stopPx.value,
         cmtaNumber                     |-> cmtaNumber.value,
         ctiCode                        |-> ctiCode.value,
         manualOrderIndicator           |-> manualOrderIndicator.value,
         oeoid                          |-> oeoid.value,
         custOrderHandlingInst          |-> custOrderHandlingInst.value ], custOrderHandlingInst.rest)

(* Cancel Rejected Message with each field marked present by fields before it there exactly where they say *)
SettleCancelRejectedMessage(message) ==
    LET settled1 == [message EXCEPT !.cancelRejectedReturnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.cancelRejectedReturnBitfield1 = << >> THEN <<0>> ELSE message.cancelRejectedReturnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.cancelRejectedReturnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.cancelRejectedReturnBitfield2 = << >> THEN <<0>> ELSE settled1.cancelRejectedReturnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.cancelRejectedReturnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.cancelRejectedReturnBitfield3 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled2.cancelRejectedReturnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.cancelRejectedReturnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.cancelRejectedReturnBitfield4 = << >> THEN <<0>> ELSE settled3.cancelRejectedReturnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.cancelRejectedReturnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.cancelRejectedReturnBitfield5 = << >> THEN <<0>> ELSE settled4.cancelRejectedReturnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.cancelRejectedReturnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.cancelRejectedReturnBitfield6 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled5.cancelRejectedReturnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.cancelRejectedReturnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.cancelRejectedReturnBitfield7 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.cancelRejectedReturnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.cancelRejectedReturnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.cancelRejectedReturnBitfield8 = << >> THEN <<0>> ELSE settled7.cancelRejectedReturnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.cancelRejectedReturnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.cancelRejectedReturnBitfield9 = << >> THEN <<0>> ELSE settled8.cancelRejectedReturnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.cancelRejectedReturnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.cancelRejectedReturnBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.cancelRejectedReturnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.cancelRejectedReturnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.cancelRejectedReturnBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.cancelRejectedReturnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.cancelRejectedReturnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.cancelRejectedReturnBitfield12 = << >> THEN <<0>> ELSE settled11.cancelRejectedReturnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.cancelRejectedReturnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.cancelRejectedReturnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.cancelRejectedReturnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.cancelRejectedReturnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.cancelRejectedReturnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.cancelRejectedReturnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.cancelRejectedReturnBitfield15 = IF settled14.numberOfReturnBitfields >= 15 THEN (IF settled14.cancelRejectedReturnBitfield15 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.cancelRejectedReturnBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.cancelRejectedReturnBitfield16 = IF settled15.numberOfReturnBitfields >= 16 THEN (IF settled15.cancelRejectedReturnBitfield16 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled15.cancelRejectedReturnBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.cancelRejectedReturnBitfield17 = IF settled16.numberOfReturnBitfields >= 17 THEN (IF settled16.cancelRejectedReturnBitfield17 = << >> THEN <<0>> ELSE settled16.cancelRejectedReturnBitfield17) ELSE << >>]
        settled18 == [settled17 EXCEPT !.cancelRejectedReturnBitfield18 = IF settled17.numberOfReturnBitfields >= 18 THEN (IF settled17.cancelRejectedReturnBitfield18 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.cancelRejectedReturnBitfield18) ELSE << >>]
        settled19 == [settled18 EXCEPT !.side = IF settled18.numberOfReturnBitfields >= 1 /\ (settled18.cancelRejectedReturnBitfield1 # << >> /\ settled18.cancelRejectedReturnBitfield1[1] % 2 > 0) THEN (IF settled18.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled18.side) ELSE << >>]
        settled20 == [settled19 EXCEPT !.price = IF settled19.numberOfReturnBitfields >= 1 /\ (settled19.cancelRejectedReturnBitfield1 # << >> /\ (settled19.cancelRejectedReturnBitfield1[1] \div 4) % 2 > 0) THEN (IF settled19.price = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled19.price) ELSE << >>]
        settled21 == [settled20 EXCEPT !.ordType = IF settled20.numberOfReturnBitfields >= 1 /\ (settled20.cancelRejectedReturnBitfield1 # << >> /\ (settled20.cancelRejectedReturnBitfield1[1] \div 16) % 2 > 0) THEN (IF settled20.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled20.ordType) ELSE << >>]
        settled22 == [settled21 EXCEPT !.timeInForce = IF settled21.numberOfReturnBitfields >= 1 /\ (settled21.cancelRejectedReturnBitfield1 # << >> /\ (settled21.cancelRejectedReturnBitfield1[1] \div 32) % 2 > 0) THEN (IF settled21.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled21.timeInForce) ELSE << >>]
        settled23 == [settled22 EXCEPT !.minQty = IF settled22.numberOfReturnBitfields >= 1 /\ (settled22.cancelRejectedReturnBitfield1 # << >> /\ (settled22.cancelRejectedReturnBitfield1[1] \div 64) % 2 > 0) THEN (IF settled22.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled22.minQty) ELSE << >>]
        settled24 == [settled23 EXCEPT !.symbolLong = IF settled23.numberOfReturnBitfields >= 2 /\ (settled23.cancelRejectedReturnBitfield2 # << >> /\ settled23.cancelRejectedReturnBitfield2[1] % 2 > 0) THEN (IF settled23.symbolLong = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled23.symbolLong) ELSE << >>]
        settled25 == [settled24 EXCEPT !.capacity = IF settled24.numberOfReturnBitfields >= 2 /\ (settled24.cancelRejectedReturnBitfield2 # << >> /\ (settled24.cancelRejectedReturnBitfield2[1] \div 64) % 2 > 0) THEN (IF settled24.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled24.capacity) ELSE << >>]
        settled26 == [settled25 EXCEPT !.maturityDate = IF settled25.numberOfReturnBitfields >= 4 /\ (settled25.cancelRejectedReturnBitfield4 # << >> /\ settled25.cancelRejectedReturnBitfield4[1] % 2 > 0) THEN (IF settled25.maturityDate = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled25.maturityDate) ELSE << >>]
        settled27 == [settled26 EXCEPT !.openClose = IF settled26.numberOfReturnBitfields >= 4 /\ (settled26.cancelRejectedReturnBitfield4 # << >> /\ (settled26.cancelRejectedReturnBitfield4[1] \div 8) % 2 > 0) THEN (IF settled26.openClose = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled26.openClose) ELSE << >>]
        settled28 == [settled27 EXCEPT !.expireTime = IF settled27.numberOfReturnBitfields >= 5 /\ (settled27.cancelRejectedReturnBitfield5 # << >> /\ (settled27.cancelRejectedReturnBitfield5[1] \div 128) % 2 > 0) THEN (IF settled27.expireTime = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled27.expireTime) ELSE << >>]
        settled29 == [settled28 EXCEPT !.stopPx = IF settled28.numberOfReturnBitfields >= 8 /\ (settled28.cancelRejectedReturnBitfield8 # << >> /\ (settled28.cancelRejectedReturnBitfield8[1] \div 4) % 2 > 0) THEN (IF settled28.stopPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled28.stopPx) ELSE << >>]
        settled30 == [settled29 EXCEPT !.cmtaNumber = IF settled29.numberOfReturnBitfields >= 9 /\ (settled29.cancelRejectedReturnBitfield9 # << >> /\ (settled29.cancelRejectedReturnBitfield9[1] \div 32) % 2 > 0) THEN (IF settled29.cmtaNumber = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled29.cmtaNumber) ELSE << >>]
        settled31 == [settled30 EXCEPT !.ctiCode = IF settled30.numberOfReturnBitfields >= 12 /\ (settled30.cancelRejectedReturnBitfield12 # << >> /\ settled30.cancelRejectedReturnBitfield12[1] % 2 > 0) THEN (IF settled30.ctiCode = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled30.ctiCode) ELSE << >>]
        settled32 == [settled31 EXCEPT !.manualOrderIndicator = IF settled31.numberOfReturnBitfields >= 12 /\ (settled31.cancelRejectedReturnBitfield12 # << >> /\ (settled31.cancelRejectedReturnBitfield12[1] \div 2) % 2 > 0) THEN (IF settled31.manualOrderIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled31.manualOrderIndicator) ELSE << >>]
        settled33 == [settled32 EXCEPT !.oeoid = IF settled32.numberOfReturnBitfields >= 12 /\ (settled32.cancelRejectedReturnBitfield12 # << >> /\ (settled32.cancelRejectedReturnBitfield12[1] \div 4) % 2 > 0) THEN (IF settled32.oeoid = << >> THEN <<[i \in 1 .. 18 |-> 0]>> ELSE settled32.oeoid) ELSE << >>]
        settled34 == [settled33 EXCEPT !.custOrderHandlingInst = IF settled33.numberOfReturnBitfields >= 17 /\ (settled33.cancelRejectedReturnBitfield17 # << >> /\ (settled33.cancelRejectedReturnBitfield17[1] \div 128) % 2 > 0) THEN (IF settled33.custOrderHandlingInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled33.custOrderHandlingInst) ELSE << >>]
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
                                  side                           |-> << >>,
                                  price                          |-> << >>,
                                  ordType                        |-> << >>,
                                  timeInForce                    |-> << >>,
                                  minQty                         |-> << >>,
                                  symbolLong                     |-> << >>,
                                  capacity                       |-> << >>,
                                  maturityDate                   |-> << >>,
                                  openClose                      |-> << >>,
                                  expireTime                     |-> << >>,
                                  stopPx                         |-> << >>,
                                  cmtaNumber                     |-> << >>,
                                  ctiCode                        |-> << >>,
                                  manualOrderIndicator           |-> << >>,
                                  oeoid                          |-> << >>,
                                  custOrderHandlingInst          |-> << >> ])

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
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 4, !.cancelRejectedReturnBitfield4 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 5, !.cancelRejectedReturnBitfield5 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 6, !.cancelRejectedReturnBitfield6 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 7, !.cancelRejectedReturnBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 8, !.cancelRejectedReturnBitfield8 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 9, !.cancelRejectedReturnBitfield9 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 10, !.cancelRejectedReturnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 11, !.cancelRejectedReturnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 12, !.cancelRejectedReturnBitfield12 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 13, !.cancelRejectedReturnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 14, !.cancelRejectedReturnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 15, !.cancelRejectedReturnBitfield15 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 16, !.cancelRejectedReturnBitfield16 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 17, !.cancelRejectedReturnBitfield17 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 18, !.cancelRejectedReturnBitfield18 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.cancelRejectedReturnBitfield1 = <<1>>, !.side = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.cancelRejectedReturnBitfield1 = <<4>>, !.price = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.cancelRejectedReturnBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.cancelRejectedReturnBitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.cancelRejectedReturnBitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 2, !.cancelRejectedReturnBitfield2 = <<1>>, !.symbolLong = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 2, !.cancelRejectedReturnBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 4, !.cancelRejectedReturnBitfield4 = <<1>>, !.maturityDate = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 4, !.cancelRejectedReturnBitfield4 = <<8>>, !.openClose = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 5, !.cancelRejectedReturnBitfield5 = <<128>>, !.expireTime = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 8, !.cancelRejectedReturnBitfield8 = <<4>>, !.stopPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 9, !.cancelRejectedReturnBitfield9 = <<32>>, !.cmtaNumber = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 12, !.cancelRejectedReturnBitfield12 = <<1>>, !.ctiCode = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 12, !.cancelRejectedReturnBitfield12 = <<2>>, !.manualOrderIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 12, !.cancelRejectedReturnBitfield12 = <<4>>, !.oeoid = one]) : one \in { <<held>> : held \in Sample(18) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 17, !.cancelRejectedReturnBitfield17 = <<128>>, !.custOrderHandlingInst = one]) : one \in { <<held>> : held \in Sample(1) } }

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
      orderExecutionReturnBitfield4  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderExecutionReturnBitfield5  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderExecutionReturnBitfield6  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderExecutionReturnBitfield7  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderExecutionReturnBitfield8  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderExecutionReturnBitfield9  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderExecutionReturnBitfield10 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderExecutionReturnBitfield11 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderExecutionReturnBitfield12 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderExecutionReturnBitfield13 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderExecutionReturnBitfield14 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderExecutionReturnBitfield15 : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderExecutionReturnBitfield16 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderExecutionReturnBitfield17 : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      orderExecutionReturnBitfield18 : { << >> } \cup { <<held>> : held \in Sample(1) },
      side                           : { << >> } \cup { <<held>> : held \in Sample(1) },
      price                          : { << >> } \cup { <<held>> : held \in Sample(8) },
      ordType                        : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce                    : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                         : { << >> } \cup { <<held>> : held \in Sample(4) },
      symbolLong                     : { << >> } \cup { <<held>> : held \in Sample(8) },
      capacity                       : { << >> } \cup { <<held>> : held \in Sample(1) },
      account                        : { << >> } \cup { <<held>> : held \in Sample(16) },
      clearingFirm                   : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingAccount                : { << >> } \cup { <<held>> : held \in Sample(4) },
      orderQty                       : { << >> } \cup { <<held>> : held \in Sample(4) },
      preventMatch                   : { << >> } \cup { <<held>> : held \in Sample(3) },
      maturityDate                   : { << >> } \cup { <<held>> : held \in Sample(4) },
      openClose                      : { << >> } \cup { <<held>> : held \in Sample(1) },
      expireTime                     : { << >> } \cup { <<held>> : held \in Sample(8) },
      feeCode                        : { << >> } \cup { <<held>> : held \in Sample(2) },
      stopPx                         : { << >> } \cup { <<held>> : held \in Sample(8) },
      cmtaNumber                     : { << >> } \cup { <<held>> : held \in Sample(4) },
      ctiCode                        : { << >> } \cup { <<held>> : held \in Sample(1) },
      manualOrderIndicator           : { << >> } \cup { <<held>> : held \in Sample(1) },
      oeoid                          : { << >> } \cup { <<held>> : held \in Sample(18) },
      tradeDate                      : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingSize                   : { << >> } \cup { <<held>> : held \in Sample(4) },
      cumQty                         : { << >> } \cup { <<held>> : held \in Sample(4) },
      dayOrderQty                    : { << >> } \cup { <<held>> : held \in Sample(4) },
      dayCumQty                      : { << >> } \cup { <<held>> : held \in Sample(4) },
      avgPx                          : { << >> } \cup { <<held>> : held \in Sample(8) },
      dayAvgPx                       : { << >> } \cup { <<held>> : held \in Sample(8) },
      pendingStatus                  : { << >> } \cup { <<held>> : held \in Sample(1) },
      multilegReportingType          : { << >> } \cup { <<held>> : held \in Sample(1) },
      secondaryExecId                : { << >> } \cup { <<held>> : held \in Sample(8) },
      frequentTraderId               : { << >> } \cup { <<held>> : held \in Sample(6) },
      custOrderHandlingInst          : { << >> } \cup { <<held>> : held \in Sample(1) } ]

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
        \o (IF message.orderExecutionReturnBitfield4 = << >> THEN << >> ELSE EncodeUIntLE(message.orderExecutionReturnBitfield4[1], 1))
        \o (IF message.orderExecutionReturnBitfield5 = << >> THEN << >> ELSE EncodeUIntLE(message.orderExecutionReturnBitfield5[1], 1))
        \o (IF message.orderExecutionReturnBitfield6 = << >> THEN << >> ELSE message.orderExecutionReturnBitfield6[1])
        \o (IF message.orderExecutionReturnBitfield7 = << >> THEN << >> ELSE message.orderExecutionReturnBitfield7[1])
        \o (IF message.orderExecutionReturnBitfield8 = << >> THEN << >> ELSE EncodeUIntLE(message.orderExecutionReturnBitfield8[1], 1))
        \o (IF message.orderExecutionReturnBitfield9 = << >> THEN << >> ELSE EncodeUIntLE(message.orderExecutionReturnBitfield9[1], 1))
        \o (IF message.orderExecutionReturnBitfield10 = << >> THEN << >> ELSE message.orderExecutionReturnBitfield10[1])
        \o (IF message.orderExecutionReturnBitfield11 = << >> THEN << >> ELSE message.orderExecutionReturnBitfield11[1])
        \o (IF message.orderExecutionReturnBitfield12 = << >> THEN << >> ELSE EncodeUIntLE(message.orderExecutionReturnBitfield12[1], 1))
        \o (IF message.orderExecutionReturnBitfield13 = << >> THEN << >> ELSE EncodeUIntLE(message.orderExecutionReturnBitfield13[1], 1))
        \o (IF message.orderExecutionReturnBitfield14 = << >> THEN << >> ELSE EncodeUIntLE(message.orderExecutionReturnBitfield14[1], 1))
        \o (IF message.orderExecutionReturnBitfield15 = << >> THEN << >> ELSE message.orderExecutionReturnBitfield15[1])
        \o (IF message.orderExecutionReturnBitfield16 = << >> THEN << >> ELSE EncodeUIntLE(message.orderExecutionReturnBitfield16[1], 1))
        \o (IF message.orderExecutionReturnBitfield17 = << >> THEN << >> ELSE EncodeUIntLE(message.orderExecutionReturnBitfield17[1], 1))
        \o (IF message.orderExecutionReturnBitfield18 = << >> THEN << >> ELSE message.orderExecutionReturnBitfield18[1])
        \o (IF message.side = << >> THEN << >> ELSE message.side[1])
        \o (IF message.price = << >> THEN << >> ELSE message.price[1])
        \o (IF message.ordType = << >> THEN << >> ELSE message.ordType[1])
        \o (IF message.timeInForce = << >> THEN << >> ELSE message.timeInForce[1])
        \o (IF message.minQty = << >> THEN << >> ELSE message.minQty[1])
        \o (IF message.symbolLong = << >> THEN << >> ELSE message.symbolLong[1])
        \o (IF message.capacity = << >> THEN << >> ELSE message.capacity[1])
        \o (IF message.account = << >> THEN << >> ELSE message.account[1])
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])
        \o (IF message.clearingAccount = << >> THEN << >> ELSE message.clearingAccount[1])
        \o (IF message.orderQty = << >> THEN << >> ELSE message.orderQty[1])
        \o (IF message.preventMatch = << >> THEN << >> ELSE message.preventMatch[1])
        \o (IF message.maturityDate = << >> THEN << >> ELSE message.maturityDate[1])
        \o (IF message.openClose = << >> THEN << >> ELSE message.openClose[1])
        \o (IF message.expireTime = << >> THEN << >> ELSE message.expireTime[1])
        \o (IF message.feeCode = << >> THEN << >> ELSE message.feeCode[1])
        \o (IF message.stopPx = << >> THEN << >> ELSE message.stopPx[1])
        \o (IF message.cmtaNumber = << >> THEN << >> ELSE message.cmtaNumber[1])
        \o (IF message.ctiCode = << >> THEN << >> ELSE message.ctiCode[1])
        \o (IF message.manualOrderIndicator = << >> THEN << >> ELSE message.manualOrderIndicator[1])
        \o (IF message.oeoid = << >> THEN << >> ELSE message.oeoid[1])
        \o (IF message.tradeDate = << >> THEN << >> ELSE message.tradeDate[1])
        \o (IF message.clearingSize = << >> THEN << >> ELSE message.clearingSize[1])
        \o (IF message.cumQty = << >> THEN << >> ELSE message.cumQty[1])
        \o (IF message.dayOrderQty = << >> THEN << >> ELSE message.dayOrderQty[1])
        \o (IF message.dayCumQty = << >> THEN << >> ELSE message.dayCumQty[1])
        \o (IF message.avgPx = << >> THEN << >> ELSE message.avgPx[1])
        \o (IF message.dayAvgPx = << >> THEN << >> ELSE message.dayAvgPx[1])
        \o (IF message.pendingStatus = << >> THEN << >> ELSE message.pendingStatus[1])
        \o (IF message.multilegReportingType = << >> THEN << >> ELSE message.multilegReportingType[1])
        \o (IF message.secondaryExecId = << >> THEN << >> ELSE message.secondaryExecId[1])
        \o (IF message.frequentTraderId = << >> THEN << >> ELSE message.frequentTraderId[1])
        \o (IF message.custOrderHandlingInst = << >> THEN << >> ELSE message.custOrderHandlingInst[1])

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
    LET orderExecutionReturnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadUIntLE(orderExecutionReturnBitfield3.rest, 1), orderExecutionReturnBitfield3.rest) IN IF ~orderExecutionReturnBitfield4.ok THEN Fail ELSE
    LET orderExecutionReturnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadUIntLE(orderExecutionReturnBitfield4.rest, 1), orderExecutionReturnBitfield4.rest) IN IF ~orderExecutionReturnBitfield5.ok THEN Fail ELSE
    LET orderExecutionReturnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadBytes(orderExecutionReturnBitfield5.rest, 1), orderExecutionReturnBitfield5.rest) IN IF ~orderExecutionReturnBitfield6.ok THEN Fail ELSE
    LET orderExecutionReturnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadBytes(orderExecutionReturnBitfield6.rest, 1), orderExecutionReturnBitfield6.rest) IN IF ~orderExecutionReturnBitfield7.ok THEN Fail ELSE
    LET orderExecutionReturnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadUIntLE(orderExecutionReturnBitfield7.rest, 1), orderExecutionReturnBitfield7.rest) IN IF ~orderExecutionReturnBitfield8.ok THEN Fail ELSE
    LET orderExecutionReturnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadUIntLE(orderExecutionReturnBitfield8.rest, 1), orderExecutionReturnBitfield8.rest) IN IF ~orderExecutionReturnBitfield9.ok THEN Fail ELSE
    LET orderExecutionReturnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadBytes(orderExecutionReturnBitfield9.rest, 1), orderExecutionReturnBitfield9.rest) IN IF ~orderExecutionReturnBitfield10.ok THEN Fail ELSE
    LET orderExecutionReturnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadBytes(orderExecutionReturnBitfield10.rest, 1), orderExecutionReturnBitfield10.rest) IN IF ~orderExecutionReturnBitfield11.ok THEN Fail ELSE
    LET orderExecutionReturnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadUIntLE(orderExecutionReturnBitfield11.rest, 1), orderExecutionReturnBitfield11.rest) IN IF ~orderExecutionReturnBitfield12.ok THEN Fail ELSE
    LET orderExecutionReturnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadUIntLE(orderExecutionReturnBitfield12.rest, 1), orderExecutionReturnBitfield12.rest) IN IF ~orderExecutionReturnBitfield13.ok THEN Fail ELSE
    LET orderExecutionReturnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadUIntLE(orderExecutionReturnBitfield13.rest, 1), orderExecutionReturnBitfield13.rest) IN IF ~orderExecutionReturnBitfield14.ok THEN Fail ELSE
    LET orderExecutionReturnBitfield15 == ReadWhen(numberOfReturnBitfields.value >= 15, ReadBytes(orderExecutionReturnBitfield14.rest, 1), orderExecutionReturnBitfield14.rest) IN IF ~orderExecutionReturnBitfield15.ok THEN Fail ELSE
    LET orderExecutionReturnBitfield16 == ReadWhen(numberOfReturnBitfields.value >= 16, ReadUIntLE(orderExecutionReturnBitfield15.rest, 1), orderExecutionReturnBitfield15.rest) IN IF ~orderExecutionReturnBitfield16.ok THEN Fail ELSE
    LET orderExecutionReturnBitfield17 == ReadWhen(numberOfReturnBitfields.value >= 17, ReadUIntLE(orderExecutionReturnBitfield16.rest, 1), orderExecutionReturnBitfield16.rest) IN IF ~orderExecutionReturnBitfield17.ok THEN Fail ELSE
    LET orderExecutionReturnBitfield18 == ReadWhen(numberOfReturnBitfields.value >= 18, ReadBytes(orderExecutionReturnBitfield17.rest, 1), orderExecutionReturnBitfield17.rest) IN IF ~orderExecutionReturnBitfield18.ok THEN Fail ELSE
    LET side == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderExecutionReturnBitfield1.value # << >> /\ orderExecutionReturnBitfield1.value[1] % 2 > 0), ReadBytes(orderExecutionReturnBitfield18.rest, 1), orderExecutionReturnBitfield18.rest) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderExecutionReturnBitfield1.value # << >> /\ (orderExecutionReturnBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(side.rest, 8), side.rest) IN IF ~price.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderExecutionReturnBitfield1.value # << >> /\ (orderExecutionReturnBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(price.rest, 1), price.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderExecutionReturnBitfield1.value # << >> /\ (orderExecutionReturnBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (orderExecutionReturnBitfield1.value # << >> /\ (orderExecutionReturnBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET symbolLong == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderExecutionReturnBitfield2.value # << >> /\ orderExecutionReturnBitfield2.value[1] % 2 > 0), ReadBytes(minQty.rest, 8), minQty.rest) IN IF ~symbolLong.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (orderExecutionReturnBitfield2.value # << >> /\ (orderExecutionReturnBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(symbolLong.rest, 1), symbolLong.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderExecutionReturnBitfield3.value # << >> /\ orderExecutionReturnBitfield3.value[1] % 2 > 0), ReadBytes(capacity.rest, 16), capacity.rest) IN IF ~account.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderExecutionReturnBitfield3.value # << >> /\ (orderExecutionReturnBitfield3.value[1] \div 2) % 2 > 0), ReadBytes(account.rest, 4), account.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderExecutionReturnBitfield3.value # << >> /\ (orderExecutionReturnBitfield3.value[1] \div 4) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET orderQty == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderExecutionReturnBitfield3.value # << >> /\ (orderExecutionReturnBitfield3.value[1] \div 64) % 2 > 0), ReadBytes(clearingAccount.rest, 4), clearingAccount.rest) IN IF ~orderQty.ok THEN Fail ELSE
    LET preventMatch == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (orderExecutionReturnBitfield3.value # << >> /\ (orderExecutionReturnBitfield3.value[1] \div 128) % 2 > 0), ReadBytes(orderQty.rest, 3), orderQty.rest) IN IF ~preventMatch.ok THEN Fail ELSE
    LET maturityDate == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (orderExecutionReturnBitfield4.value # << >> /\ orderExecutionReturnBitfield4.value[1] % 2 > 0), ReadBytes(preventMatch.rest, 4), preventMatch.rest) IN IF ~maturityDate.ok THEN Fail ELSE
    LET openClose == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (orderExecutionReturnBitfield4.value # << >> /\ (orderExecutionReturnBitfield4.value[1] \div 8) % 2 > 0), ReadBytes(maturityDate.rest, 1), maturityDate.rest) IN IF ~openClose.ok THEN Fail ELSE
    LET expireTime == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (orderExecutionReturnBitfield5.value # << >> /\ (orderExecutionReturnBitfield5.value[1] \div 128) % 2 > 0), ReadBytes(openClose.rest, 8), openClose.rest) IN IF ~expireTime.ok THEN Fail ELSE
    LET feeCode == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderExecutionReturnBitfield8.value # << >> /\ orderExecutionReturnBitfield8.value[1] % 2 > 0), ReadBytes(expireTime.rest, 2), expireTime.rest) IN IF ~feeCode.ok THEN Fail ELSE
    LET stopPx == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (orderExecutionReturnBitfield8.value # << >> /\ (orderExecutionReturnBitfield8.value[1] \div 4) % 2 > 0), ReadBytes(feeCode.rest, 8), feeCode.rest) IN IF ~stopPx.ok THEN Fail ELSE
    LET cmtaNumber == ReadWhen(numberOfReturnBitfields.value >= 9 /\ (orderExecutionReturnBitfield9.value # << >> /\ (orderExecutionReturnBitfield9.value[1] \div 32) % 2 > 0), ReadBytes(stopPx.rest, 4), stopPx.rest) IN IF ~cmtaNumber.ok THEN Fail ELSE
    LET ctiCode == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (orderExecutionReturnBitfield12.value # << >> /\ orderExecutionReturnBitfield12.value[1] % 2 > 0), ReadBytes(cmtaNumber.rest, 1), cmtaNumber.rest) IN IF ~ctiCode.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (orderExecutionReturnBitfield12.value # << >> /\ (orderExecutionReturnBitfield12.value[1] \div 2) % 2 > 0), ReadBytes(ctiCode.rest, 1), ctiCode.rest) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET oeoid == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (orderExecutionReturnBitfield12.value # << >> /\ (orderExecutionReturnBitfield12.value[1] \div 4) % 2 > 0), ReadBytes(manualOrderIndicator.rest, 18), manualOrderIndicator.rest) IN IF ~oeoid.ok THEN Fail ELSE
    LET tradeDate == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (orderExecutionReturnBitfield12.value # << >> /\ (orderExecutionReturnBitfield12.value[1] \div 8) % 2 > 0), ReadBytes(oeoid.rest, 4), oeoid.rest) IN IF ~tradeDate.ok THEN Fail ELSE
    LET clearingSize == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (orderExecutionReturnBitfield12.value # << >> /\ (orderExecutionReturnBitfield12.value[1] \div 32) % 2 > 0), ReadBytes(tradeDate.rest, 4), tradeDate.rest) IN IF ~clearingSize.ok THEN Fail ELSE
    LET cumQty == ReadWhen(numberOfReturnBitfields.value >= 13 /\ (orderExecutionReturnBitfield13.value # << >> /\ orderExecutionReturnBitfield13.value[1] % 2 > 0), ReadBytes(clearingSize.rest, 4), clearingSize.rest) IN IF ~cumQty.ok THEN Fail ELSE
    LET dayOrderQty == ReadWhen(numberOfReturnBitfields.value >= 13 /\ (orderExecutionReturnBitfield13.value # << >> /\ (orderExecutionReturnBitfield13.value[1] \div 2) % 2 > 0), ReadBytes(cumQty.rest, 4), cumQty.rest) IN IF ~dayOrderQty.ok THEN Fail ELSE
    LET dayCumQty == ReadWhen(numberOfReturnBitfields.value >= 13 /\ (orderExecutionReturnBitfield13.value # << >> /\ (orderExecutionReturnBitfield13.value[1] \div 4) % 2 > 0), ReadBytes(dayOrderQty.rest, 4), dayOrderQty.rest) IN IF ~dayCumQty.ok THEN Fail ELSE
    LET avgPx == ReadWhen(numberOfReturnBitfields.value >= 13 /\ (orderExecutionReturnBitfield13.value # << >> /\ (orderExecutionReturnBitfield13.value[1] \div 8) % 2 > 0), ReadBytes(dayCumQty.rest, 8), dayCumQty.rest) IN IF ~avgPx.ok THEN Fail ELSE
    LET dayAvgPx == ReadWhen(numberOfReturnBitfields.value >= 13 /\ (orderExecutionReturnBitfield13.value # << >> /\ (orderExecutionReturnBitfield13.value[1] \div 16) % 2 > 0), ReadBytes(avgPx.rest, 8), avgPx.rest) IN IF ~dayAvgPx.ok THEN Fail ELSE
    LET pendingStatus == ReadWhen(numberOfReturnBitfields.value >= 13 /\ (orderExecutionReturnBitfield13.value # << >> /\ (orderExecutionReturnBitfield13.value[1] \div 32) % 2 > 0), ReadBytes(dayAvgPx.rest, 1), dayAvgPx.rest) IN IF ~pendingStatus.ok THEN Fail ELSE
    LET multilegReportingType == ReadWhen(numberOfReturnBitfields.value >= 13 /\ (orderExecutionReturnBitfield13.value # << >> /\ (orderExecutionReturnBitfield13.value[1] \div 128) % 2 > 0), ReadBytes(pendingStatus.rest, 1), pendingStatus.rest) IN IF ~multilegReportingType.ok THEN Fail ELSE
    LET secondaryExecId == ReadWhen(numberOfReturnBitfields.value >= 14 /\ (orderExecutionReturnBitfield14.value # << >> /\ (orderExecutionReturnBitfield14.value[1] \div 16) % 2 > 0), ReadBytes(multilegReportingType.rest, 8), multilegReportingType.rest) IN IF ~secondaryExecId.ok THEN Fail ELSE
    LET frequentTraderId == ReadWhen(numberOfReturnBitfields.value >= 16 /\ (orderExecutionReturnBitfield16.value # << >> /\ orderExecutionReturnBitfield16.value[1] % 2 > 0), ReadBytes(secondaryExecId.rest, 6), secondaryExecId.rest) IN IF ~frequentTraderId.ok THEN Fail ELSE
    LET custOrderHandlingInst == ReadWhen(numberOfReturnBitfields.value >= 17 /\ (orderExecutionReturnBitfield17.value # << >> /\ (orderExecutionReturnBitfield17.value[1] \div 128) % 2 > 0), ReadBytes(frequentTraderId.rest, 1), frequentTraderId.rest) IN IF ~custOrderHandlingInst.ok THEN Fail ELSE
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
         side                           |-> side.value,
         price                          |-> price.value,
         ordType                        |-> ordType.value,
         timeInForce                    |-> timeInForce.value,
         minQty                         |-> minQty.value,
         symbolLong                     |-> symbolLong.value,
         capacity                       |-> capacity.value,
         account                        |-> account.value,
         clearingFirm                   |-> clearingFirm.value,
         clearingAccount                |-> clearingAccount.value,
         orderQty                       |-> orderQty.value,
         preventMatch                   |-> preventMatch.value,
         maturityDate                   |-> maturityDate.value,
         openClose                      |-> openClose.value,
         expireTime                     |-> expireTime.value,
         feeCode                        |-> feeCode.value,
         stopPx                         |-> stopPx.value,
         cmtaNumber                     |-> cmtaNumber.value,
         ctiCode                        |-> ctiCode.value,
         manualOrderIndicator           |-> manualOrderIndicator.value,
         oeoid                          |-> oeoid.value,
         tradeDate                      |-> tradeDate.value,
         clearingSize                   |-> clearingSize.value,
         cumQty                         |-> cumQty.value,
         dayOrderQty                    |-> dayOrderQty.value,
         dayCumQty                      |-> dayCumQty.value,
         avgPx                          |-> avgPx.value,
         dayAvgPx                       |-> dayAvgPx.value,
         pendingStatus                  |-> pendingStatus.value,
         multilegReportingType          |-> multilegReportingType.value,
         secondaryExecId                |-> secondaryExecId.value,
         frequentTraderId               |-> frequentTraderId.value,
         custOrderHandlingInst          |-> custOrderHandlingInst.value ], custOrderHandlingInst.rest)

(* Order Execution Message with each field marked present by fields before it there exactly where they say *)
SettleOrderExecutionMessage(message) ==
    LET settled1 == [message EXCEPT !.orderExecutionReturnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.orderExecutionReturnBitfield1 = << >> THEN <<0>> ELSE message.orderExecutionReturnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.orderExecutionReturnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.orderExecutionReturnBitfield2 = << >> THEN <<0>> ELSE settled1.orderExecutionReturnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.orderExecutionReturnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.orderExecutionReturnBitfield3 = << >> THEN <<0>> ELSE settled2.orderExecutionReturnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.orderExecutionReturnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.orderExecutionReturnBitfield4 = << >> THEN <<0>> ELSE settled3.orderExecutionReturnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.orderExecutionReturnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.orderExecutionReturnBitfield5 = << >> THEN <<0>> ELSE settled4.orderExecutionReturnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.orderExecutionReturnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.orderExecutionReturnBitfield6 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled5.orderExecutionReturnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.orderExecutionReturnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.orderExecutionReturnBitfield7 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.orderExecutionReturnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.orderExecutionReturnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.orderExecutionReturnBitfield8 = << >> THEN <<0>> ELSE settled7.orderExecutionReturnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.orderExecutionReturnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.orderExecutionReturnBitfield9 = << >> THEN <<0>> ELSE settled8.orderExecutionReturnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.orderExecutionReturnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.orderExecutionReturnBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.orderExecutionReturnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.orderExecutionReturnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.orderExecutionReturnBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.orderExecutionReturnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.orderExecutionReturnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.orderExecutionReturnBitfield12 = << >> THEN <<0>> ELSE settled11.orderExecutionReturnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.orderExecutionReturnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.orderExecutionReturnBitfield13 = << >> THEN <<0>> ELSE settled12.orderExecutionReturnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.orderExecutionReturnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.orderExecutionReturnBitfield14 = << >> THEN <<0>> ELSE settled13.orderExecutionReturnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.orderExecutionReturnBitfield15 = IF settled14.numberOfReturnBitfields >= 15 THEN (IF settled14.orderExecutionReturnBitfield15 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.orderExecutionReturnBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.orderExecutionReturnBitfield16 = IF settled15.numberOfReturnBitfields >= 16 THEN (IF settled15.orderExecutionReturnBitfield16 = << >> THEN <<0>> ELSE settled15.orderExecutionReturnBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.orderExecutionReturnBitfield17 = IF settled16.numberOfReturnBitfields >= 17 THEN (IF settled16.orderExecutionReturnBitfield17 = << >> THEN <<0>> ELSE settled16.orderExecutionReturnBitfield17) ELSE << >>]
        settled18 == [settled17 EXCEPT !.orderExecutionReturnBitfield18 = IF settled17.numberOfReturnBitfields >= 18 THEN (IF settled17.orderExecutionReturnBitfield18 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.orderExecutionReturnBitfield18) ELSE << >>]
        settled19 == [settled18 EXCEPT !.side = IF settled18.numberOfReturnBitfields >= 1 /\ (settled18.orderExecutionReturnBitfield1 # << >> /\ settled18.orderExecutionReturnBitfield1[1] % 2 > 0) THEN (IF settled18.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled18.side) ELSE << >>]
        settled20 == [settled19 EXCEPT !.price = IF settled19.numberOfReturnBitfields >= 1 /\ (settled19.orderExecutionReturnBitfield1 # << >> /\ (settled19.orderExecutionReturnBitfield1[1] \div 4) % 2 > 0) THEN (IF settled19.price = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled19.price) ELSE << >>]
        settled21 == [settled20 EXCEPT !.ordType = IF settled20.numberOfReturnBitfields >= 1 /\ (settled20.orderExecutionReturnBitfield1 # << >> /\ (settled20.orderExecutionReturnBitfield1[1] \div 16) % 2 > 0) THEN (IF settled20.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled20.ordType) ELSE << >>]
        settled22 == [settled21 EXCEPT !.timeInForce = IF settled21.numberOfReturnBitfields >= 1 /\ (settled21.orderExecutionReturnBitfield1 # << >> /\ (settled21.orderExecutionReturnBitfield1[1] \div 32) % 2 > 0) THEN (IF settled21.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled21.timeInForce) ELSE << >>]
        settled23 == [settled22 EXCEPT !.minQty = IF settled22.numberOfReturnBitfields >= 1 /\ (settled22.orderExecutionReturnBitfield1 # << >> /\ (settled22.orderExecutionReturnBitfield1[1] \div 64) % 2 > 0) THEN (IF settled22.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled22.minQty) ELSE << >>]
        settled24 == [settled23 EXCEPT !.symbolLong = IF settled23.numberOfReturnBitfields >= 2 /\ (settled23.orderExecutionReturnBitfield2 # << >> /\ settled23.orderExecutionReturnBitfield2[1] % 2 > 0) THEN (IF settled23.symbolLong = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled23.symbolLong) ELSE << >>]
        settled25 == [settled24 EXCEPT !.capacity = IF settled24.numberOfReturnBitfields >= 2 /\ (settled24.orderExecutionReturnBitfield2 # << >> /\ (settled24.orderExecutionReturnBitfield2[1] \div 64) % 2 > 0) THEN (IF settled24.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled24.capacity) ELSE << >>]
        settled26 == [settled25 EXCEPT !.account = IF settled25.numberOfReturnBitfields >= 3 /\ (settled25.orderExecutionReturnBitfield3 # << >> /\ settled25.orderExecutionReturnBitfield3[1] % 2 > 0) THEN (IF settled25.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled25.account) ELSE << >>]
        settled27 == [settled26 EXCEPT !.clearingFirm = IF settled26.numberOfReturnBitfields >= 3 /\ (settled26.orderExecutionReturnBitfield3 # << >> /\ (settled26.orderExecutionReturnBitfield3[1] \div 2) % 2 > 0) THEN (IF settled26.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled26.clearingFirm) ELSE << >>]
        settled28 == [settled27 EXCEPT !.clearingAccount = IF settled27.numberOfReturnBitfields >= 3 /\ (settled27.orderExecutionReturnBitfield3 # << >> /\ (settled27.orderExecutionReturnBitfield3[1] \div 4) % 2 > 0) THEN (IF settled27.clearingAccount = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled27.clearingAccount) ELSE << >>]
        settled29 == [settled28 EXCEPT !.orderQty = IF settled28.numberOfReturnBitfields >= 3 /\ (settled28.orderExecutionReturnBitfield3 # << >> /\ (settled28.orderExecutionReturnBitfield3[1] \div 64) % 2 > 0) THEN (IF settled28.orderQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled28.orderQty) ELSE << >>]
        settled30 == [settled29 EXCEPT !.preventMatch = IF settled29.numberOfReturnBitfields >= 3 /\ (settled29.orderExecutionReturnBitfield3 # << >> /\ (settled29.orderExecutionReturnBitfield3[1] \div 128) % 2 > 0) THEN (IF settled29.preventMatch = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled29.preventMatch) ELSE << >>]
        settled31 == [settled30 EXCEPT !.maturityDate = IF settled30.numberOfReturnBitfields >= 4 /\ (settled30.orderExecutionReturnBitfield4 # << >> /\ settled30.orderExecutionReturnBitfield4[1] % 2 > 0) THEN (IF settled30.maturityDate = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled30.maturityDate) ELSE << >>]
        settled32 == [settled31 EXCEPT !.openClose = IF settled31.numberOfReturnBitfields >= 4 /\ (settled31.orderExecutionReturnBitfield4 # << >> /\ (settled31.orderExecutionReturnBitfield4[1] \div 8) % 2 > 0) THEN (IF settled31.openClose = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled31.openClose) ELSE << >>]
        settled33 == [settled32 EXCEPT !.expireTime = IF settled32.numberOfReturnBitfields >= 5 /\ (settled32.orderExecutionReturnBitfield5 # << >> /\ (settled32.orderExecutionReturnBitfield5[1] \div 128) % 2 > 0) THEN (IF settled32.expireTime = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled32.expireTime) ELSE << >>]
        settled34 == [settled33 EXCEPT !.feeCode = IF settled33.numberOfReturnBitfields >= 8 /\ (settled33.orderExecutionReturnBitfield8 # << >> /\ settled33.orderExecutionReturnBitfield8[1] % 2 > 0) THEN (IF settled33.feeCode = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled33.feeCode) ELSE << >>]
        settled35 == [settled34 EXCEPT !.stopPx = IF settled34.numberOfReturnBitfields >= 8 /\ (settled34.orderExecutionReturnBitfield8 # << >> /\ (settled34.orderExecutionReturnBitfield8[1] \div 4) % 2 > 0) THEN (IF settled34.stopPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled34.stopPx) ELSE << >>]
        settled36 == [settled35 EXCEPT !.cmtaNumber = IF settled35.numberOfReturnBitfields >= 9 /\ (settled35.orderExecutionReturnBitfield9 # << >> /\ (settled35.orderExecutionReturnBitfield9[1] \div 32) % 2 > 0) THEN (IF settled35.cmtaNumber = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled35.cmtaNumber) ELSE << >>]
        settled37 == [settled36 EXCEPT !.ctiCode = IF settled36.numberOfReturnBitfields >= 12 /\ (settled36.orderExecutionReturnBitfield12 # << >> /\ settled36.orderExecutionReturnBitfield12[1] % 2 > 0) THEN (IF settled36.ctiCode = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled36.ctiCode) ELSE << >>]
        settled38 == [settled37 EXCEPT !.manualOrderIndicator = IF settled37.numberOfReturnBitfields >= 12 /\ (settled37.orderExecutionReturnBitfield12 # << >> /\ (settled37.orderExecutionReturnBitfield12[1] \div 2) % 2 > 0) THEN (IF settled37.manualOrderIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled37.manualOrderIndicator) ELSE << >>]
        settled39 == [settled38 EXCEPT !.oeoid = IF settled38.numberOfReturnBitfields >= 12 /\ (settled38.orderExecutionReturnBitfield12 # << >> /\ (settled38.orderExecutionReturnBitfield12[1] \div 4) % 2 > 0) THEN (IF settled38.oeoid = << >> THEN <<[i \in 1 .. 18 |-> 0]>> ELSE settled38.oeoid) ELSE << >>]
        settled40 == [settled39 EXCEPT !.tradeDate = IF settled39.numberOfReturnBitfields >= 12 /\ (settled39.orderExecutionReturnBitfield12 # << >> /\ (settled39.orderExecutionReturnBitfield12[1] \div 8) % 2 > 0) THEN (IF settled39.tradeDate = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled39.tradeDate) ELSE << >>]
        settled41 == [settled40 EXCEPT !.clearingSize = IF settled40.numberOfReturnBitfields >= 12 /\ (settled40.orderExecutionReturnBitfield12 # << >> /\ (settled40.orderExecutionReturnBitfield12[1] \div 32) % 2 > 0) THEN (IF settled40.clearingSize = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled40.clearingSize) ELSE << >>]
        settled42 == [settled41 EXCEPT !.cumQty = IF settled41.numberOfReturnBitfields >= 13 /\ (settled41.orderExecutionReturnBitfield13 # << >> /\ settled41.orderExecutionReturnBitfield13[1] % 2 > 0) THEN (IF settled41.cumQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled41.cumQty) ELSE << >>]
        settled43 == [settled42 EXCEPT !.dayOrderQty = IF settled42.numberOfReturnBitfields >= 13 /\ (settled42.orderExecutionReturnBitfield13 # << >> /\ (settled42.orderExecutionReturnBitfield13[1] \div 2) % 2 > 0) THEN (IF settled42.dayOrderQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled42.dayOrderQty) ELSE << >>]
        settled44 == [settled43 EXCEPT !.dayCumQty = IF settled43.numberOfReturnBitfields >= 13 /\ (settled43.orderExecutionReturnBitfield13 # << >> /\ (settled43.orderExecutionReturnBitfield13[1] \div 4) % 2 > 0) THEN (IF settled43.dayCumQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled43.dayCumQty) ELSE << >>]
        settled45 == [settled44 EXCEPT !.avgPx = IF settled44.numberOfReturnBitfields >= 13 /\ (settled44.orderExecutionReturnBitfield13 # << >> /\ (settled44.orderExecutionReturnBitfield13[1] \div 8) % 2 > 0) THEN (IF settled44.avgPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled44.avgPx) ELSE << >>]
        settled46 == [settled45 EXCEPT !.dayAvgPx = IF settled45.numberOfReturnBitfields >= 13 /\ (settled45.orderExecutionReturnBitfield13 # << >> /\ (settled45.orderExecutionReturnBitfield13[1] \div 16) % 2 > 0) THEN (IF settled45.dayAvgPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled45.dayAvgPx) ELSE << >>]
        settled47 == [settled46 EXCEPT !.pendingStatus = IF settled46.numberOfReturnBitfields >= 13 /\ (settled46.orderExecutionReturnBitfield13 # << >> /\ (settled46.orderExecutionReturnBitfield13[1] \div 32) % 2 > 0) THEN (IF settled46.pendingStatus = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled46.pendingStatus) ELSE << >>]
        settled48 == [settled47 EXCEPT !.multilegReportingType = IF settled47.numberOfReturnBitfields >= 13 /\ (settled47.orderExecutionReturnBitfield13 # << >> /\ (settled47.orderExecutionReturnBitfield13[1] \div 128) % 2 > 0) THEN (IF settled47.multilegReportingType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled47.multilegReportingType) ELSE << >>]
        settled49 == [settled48 EXCEPT !.secondaryExecId = IF settled48.numberOfReturnBitfields >= 14 /\ (settled48.orderExecutionReturnBitfield14 # << >> /\ (settled48.orderExecutionReturnBitfield14[1] \div 16) % 2 > 0) THEN (IF settled48.secondaryExecId = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled48.secondaryExecId) ELSE << >>]
        settled50 == [settled49 EXCEPT !.frequentTraderId = IF settled49.numberOfReturnBitfields >= 16 /\ (settled49.orderExecutionReturnBitfield16 # << >> /\ settled49.orderExecutionReturnBitfield16[1] % 2 > 0) THEN (IF settled49.frequentTraderId = << >> THEN <<[i \in 1 .. 6 |-> 0]>> ELSE settled49.frequentTraderId) ELSE << >>]
        settled51 == [settled50 EXCEPT !.custOrderHandlingInst = IF settled50.numberOfReturnBitfields >= 17 /\ (settled50.orderExecutionReturnBitfield17 # << >> /\ (settled50.orderExecutionReturnBitfield17[1] \div 128) % 2 > 0) THEN (IF settled50.custOrderHandlingInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled50.custOrderHandlingInst) ELSE << >>]
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
                                  side                           |-> << >>,
                                  price                          |-> << >>,
                                  ordType                        |-> << >>,
                                  timeInForce                    |-> << >>,
                                  minQty                         |-> << >>,
                                  symbolLong                     |-> << >>,
                                  capacity                       |-> << >>,
                                  account                        |-> << >>,
                                  clearingFirm                   |-> << >>,
                                  clearingAccount                |-> << >>,
                                  orderQty                       |-> << >>,
                                  preventMatch                   |-> << >>,
                                  maturityDate                   |-> << >>,
                                  openClose                      |-> << >>,
                                  expireTime                     |-> << >>,
                                  feeCode                        |-> << >>,
                                  stopPx                         |-> << >>,
                                  cmtaNumber                     |-> << >>,
                                  ctiCode                        |-> << >>,
                                  manualOrderIndicator           |-> << >>,
                                  oeoid                          |-> << >>,
                                  tradeDate                      |-> << >>,
                                  clearingSize                   |-> << >>,
                                  cumQty                         |-> << >>,
                                  dayOrderQty                    |-> << >>,
                                  dayCumQty                      |-> << >>,
                                  avgPx                          |-> << >>,
                                  dayAvgPx                       |-> << >>,
                                  pendingStatus                  |-> << >>,
                                  multilegReportingType          |-> << >>,
                                  secondaryExecId                |-> << >>,
                                  frequentTraderId               |-> << >>,
                                  custOrderHandlingInst          |-> << >> ])

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
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 4, !.orderExecutionReturnBitfield4 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderExecutionReturnBitfield5 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 6, !.orderExecutionReturnBitfield6 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 7, !.orderExecutionReturnBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderExecutionReturnBitfield8 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 9, !.orderExecutionReturnBitfield9 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 10, !.orderExecutionReturnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 11, !.orderExecutionReturnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 12, !.orderExecutionReturnBitfield12 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 13, !.orderExecutionReturnBitfield13 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 14, !.orderExecutionReturnBitfield14 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 15, !.orderExecutionReturnBitfield15 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 16, !.orderExecutionReturnBitfield16 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 17, !.orderExecutionReturnBitfield17 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 18, !.orderExecutionReturnBitfield18 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderExecutionReturnBitfield1 = <<1>>, !.side = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderExecutionReturnBitfield1 = <<4>>, !.price = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderExecutionReturnBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderExecutionReturnBitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 1, !.orderExecutionReturnBitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 2, !.orderExecutionReturnBitfield2 = <<1>>, !.symbolLong = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 2, !.orderExecutionReturnBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderExecutionReturnBitfield3 = <<1>>, !.account = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderExecutionReturnBitfield3 = <<2>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderExecutionReturnBitfield3 = <<4>>, !.clearingAccount = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderExecutionReturnBitfield3 = <<64>>, !.orderQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 3, !.orderExecutionReturnBitfield3 = <<128>>, !.preventMatch = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 4, !.orderExecutionReturnBitfield4 = <<1>>, !.maturityDate = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 4, !.orderExecutionReturnBitfield4 = <<8>>, !.openClose = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 5, !.orderExecutionReturnBitfield5 = <<128>>, !.expireTime = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderExecutionReturnBitfield8 = <<1>>, !.feeCode = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 8, !.orderExecutionReturnBitfield8 = <<4>>, !.stopPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 9, !.orderExecutionReturnBitfield9 = <<32>>, !.cmtaNumber = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 12, !.orderExecutionReturnBitfield12 = <<1>>, !.ctiCode = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 12, !.orderExecutionReturnBitfield12 = <<2>>, !.manualOrderIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 12, !.orderExecutionReturnBitfield12 = <<4>>, !.oeoid = one]) : one \in { <<held>> : held \in Sample(18) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 12, !.orderExecutionReturnBitfield12 = <<8>>, !.tradeDate = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 12, !.orderExecutionReturnBitfield12 = <<32>>, !.clearingSize = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 13, !.orderExecutionReturnBitfield13 = <<1>>, !.cumQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 13, !.orderExecutionReturnBitfield13 = <<2>>, !.dayOrderQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 13, !.orderExecutionReturnBitfield13 = <<4>>, !.dayCumQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 13, !.orderExecutionReturnBitfield13 = <<8>>, !.avgPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 13, !.orderExecutionReturnBitfield13 = <<16>>, !.dayAvgPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 13, !.orderExecutionReturnBitfield13 = <<32>>, !.pendingStatus = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 13, !.orderExecutionReturnBitfield13 = <<128>>, !.multilegReportingType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 14, !.orderExecutionReturnBitfield14 = <<16>>, !.secondaryExecId = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 16, !.orderExecutionReturnBitfield16 = <<1>>, !.frequentTraderId = one]) : one \in { <<held>> : held \in Sample(6) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 17, !.orderExecutionReturnBitfield17 = <<128>>, !.custOrderHandlingInst = one]) : one \in { <<held>> : held \in Sample(1) } }

(***************************************************************************)
(* Quote Execution Message: 71 bytes                                       *)
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
      side                   : Sample(1),
      baseLiquidityIndicator : Sample(1),
      subLiquidityIndicator  : Sample(1),
      feeCode                : Sample(2) ]

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
        \o message.side
        \o message.baseLiquidityIndicator
        \o message.subLiquidityIndicator
        \o message.feeCode

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
    LET side == ReadBytes(leavesQty.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadBytes(side.rest, 1) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET subLiquidityIndicator == ReadBytes(baseLiquidityIndicator.rest, 1) IN IF ~subLiquidityIndicator.ok THEN Fail ELSE
    LET feeCode == ReadBytes(subLiquidityIndicator.rest, 2) IN IF ~feeCode.ok THEN Fail ELSE
    Ok([ transactionTime        |-> transactionTime.value,
         quoteUpdateId          |-> quoteUpdateId.value,
         orderId                |-> orderId.value,
         execId                 |-> execId.value,
         symbolShort            |-> symbolShort.value,
         clearingFirm           |-> clearingFirm.value,
         lastShares             |-> lastShares.value,
         lastPx                 |-> lastPx.value,
         leavesQty              |-> leavesQty.value,
         side                   |-> side.value,
         baseLiquidityIndicator |-> baseLiquidityIndicator.value,
         subLiquidityIndicator  |-> subLiquidityIndicator.value,
         feeCode                |-> feeCode.value ], feeCode.rest)

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
      side                   |-> [i \in 1 .. 1 |-> 0],
      baseLiquidityIndicator |-> [i \in 1 .. 1 |-> 0],
      subLiquidityIndicator  |-> [i \in 1 .. 1 |-> 0],
      feeCode                |-> [i \in 1 .. 2 |-> 0] ]

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
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.baseLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.subLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.feeCode = one] : one \in Sample(2) }

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
      tradeCancelorCorrectReturnBitfield4  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCancelorCorrectReturnBitfield5  : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCancelorCorrectReturnBitfield6  : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCancelorCorrectReturnBitfield7  : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCancelorCorrectReturnBitfield8  : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCancelorCorrectReturnBitfield9  : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tradeCancelorCorrectReturnBitfield10 : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCancelorCorrectReturnBitfield11 : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCancelorCorrectReturnBitfield12 : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCancelorCorrectReturnBitfield13 : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCancelorCorrectReturnBitfield14 : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCancelorCorrectReturnBitfield15 : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCancelorCorrectReturnBitfield16 : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCancelorCorrectReturnBitfield17 : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradeCancelorCorrectReturnBitfield18 : { << >> } \cup { <<held>> : held \in Sample(1) },
      symbolLong                           : { << >> } \cup { <<held>> : held \in Sample(8) },
      capacity                             : { << >> } \cup { <<held>> : held \in Sample(1) },
      maturityDate                         : { << >> } \cup { <<held>> : held \in Sample(4) },
      openClose                            : { << >> } \cup { <<held>> : held \in Sample(1) },
      correctedSize                        : { << >> } \cup { <<held>> : held \in Sample(4) },
      cmtaNumber                           : { << >> } \cup { <<held>> : held \in Sample(4) } ]

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
        \o (IF message.tradeCancelorCorrectReturnBitfield4 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCancelorCorrectReturnBitfield4[1], 1))
        \o (IF message.tradeCancelorCorrectReturnBitfield5 = << >> THEN << >> ELSE message.tradeCancelorCorrectReturnBitfield5[1])
        \o (IF message.tradeCancelorCorrectReturnBitfield6 = << >> THEN << >> ELSE message.tradeCancelorCorrectReturnBitfield6[1])
        \o (IF message.tradeCancelorCorrectReturnBitfield7 = << >> THEN << >> ELSE message.tradeCancelorCorrectReturnBitfield7[1])
        \o (IF message.tradeCancelorCorrectReturnBitfield8 = << >> THEN << >> ELSE message.tradeCancelorCorrectReturnBitfield8[1])
        \o (IF message.tradeCancelorCorrectReturnBitfield9 = << >> THEN << >> ELSE EncodeUIntLE(message.tradeCancelorCorrectReturnBitfield9[1], 1))
        \o (IF message.tradeCancelorCorrectReturnBitfield10 = << >> THEN << >> ELSE message.tradeCancelorCorrectReturnBitfield10[1])
        \o (IF message.tradeCancelorCorrectReturnBitfield11 = << >> THEN << >> ELSE message.tradeCancelorCorrectReturnBitfield11[1])
        \o (IF message.tradeCancelorCorrectReturnBitfield12 = << >> THEN << >> ELSE message.tradeCancelorCorrectReturnBitfield12[1])
        \o (IF message.tradeCancelorCorrectReturnBitfield13 = << >> THEN << >> ELSE message.tradeCancelorCorrectReturnBitfield13[1])
        \o (IF message.tradeCancelorCorrectReturnBitfield14 = << >> THEN << >> ELSE message.tradeCancelorCorrectReturnBitfield14[1])
        \o (IF message.tradeCancelorCorrectReturnBitfield15 = << >> THEN << >> ELSE message.tradeCancelorCorrectReturnBitfield15[1])
        \o (IF message.tradeCancelorCorrectReturnBitfield16 = << >> THEN << >> ELSE message.tradeCancelorCorrectReturnBitfield16[1])
        \o (IF message.tradeCancelorCorrectReturnBitfield17 = << >> THEN << >> ELSE message.tradeCancelorCorrectReturnBitfield17[1])
        \o (IF message.tradeCancelorCorrectReturnBitfield18 = << >> THEN << >> ELSE message.tradeCancelorCorrectReturnBitfield18[1])
        \o (IF message.symbolLong = << >> THEN << >> ELSE message.symbolLong[1])
        \o (IF message.capacity = << >> THEN << >> ELSE message.capacity[1])
        \o (IF message.maturityDate = << >> THEN << >> ELSE message.maturityDate[1])
        \o (IF message.openClose = << >> THEN << >> ELSE message.openClose[1])
        \o (IF message.correctedSize = << >> THEN << >> ELSE message.correctedSize[1])
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
    LET tradeCancelorCorrectReturnBitfield1 == ReadWhen(numberOfReturnBitfields.value >= 1, ReadBytes(numberOfReturnBitfields.rest, 1), numberOfReturnBitfields.rest) IN IF ~tradeCancelorCorrectReturnBitfield1.ok THEN Fail ELSE
    LET tradeCancelorCorrectReturnBitfield2 == ReadWhen(numberOfReturnBitfields.value >= 2, ReadUIntLE(tradeCancelorCorrectReturnBitfield1.rest, 1), tradeCancelorCorrectReturnBitfield1.rest) IN IF ~tradeCancelorCorrectReturnBitfield2.ok THEN Fail ELSE
    LET tradeCancelorCorrectReturnBitfield3 == ReadWhen(numberOfReturnBitfields.value >= 3, ReadBytes(tradeCancelorCorrectReturnBitfield2.rest, 1), tradeCancelorCorrectReturnBitfield2.rest) IN IF ~tradeCancelorCorrectReturnBitfield3.ok THEN Fail ELSE
    LET tradeCancelorCorrectReturnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadUIntLE(tradeCancelorCorrectReturnBitfield3.rest, 1), tradeCancelorCorrectReturnBitfield3.rest) IN IF ~tradeCancelorCorrectReturnBitfield4.ok THEN Fail ELSE
    LET tradeCancelorCorrectReturnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadBytes(tradeCancelorCorrectReturnBitfield4.rest, 1), tradeCancelorCorrectReturnBitfield4.rest) IN IF ~tradeCancelorCorrectReturnBitfield5.ok THEN Fail ELSE
    LET tradeCancelorCorrectReturnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadBytes(tradeCancelorCorrectReturnBitfield5.rest, 1), tradeCancelorCorrectReturnBitfield5.rest) IN IF ~tradeCancelorCorrectReturnBitfield6.ok THEN Fail ELSE
    LET tradeCancelorCorrectReturnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadBytes(tradeCancelorCorrectReturnBitfield6.rest, 1), tradeCancelorCorrectReturnBitfield6.rest) IN IF ~tradeCancelorCorrectReturnBitfield7.ok THEN Fail ELSE
    LET tradeCancelorCorrectReturnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadBytes(tradeCancelorCorrectReturnBitfield7.rest, 1), tradeCancelorCorrectReturnBitfield7.rest) IN IF ~tradeCancelorCorrectReturnBitfield8.ok THEN Fail ELSE
    LET tradeCancelorCorrectReturnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadUIntLE(tradeCancelorCorrectReturnBitfield8.rest, 1), tradeCancelorCorrectReturnBitfield8.rest) IN IF ~tradeCancelorCorrectReturnBitfield9.ok THEN Fail ELSE
    LET tradeCancelorCorrectReturnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadBytes(tradeCancelorCorrectReturnBitfield9.rest, 1), tradeCancelorCorrectReturnBitfield9.rest) IN IF ~tradeCancelorCorrectReturnBitfield10.ok THEN Fail ELSE
    LET tradeCancelorCorrectReturnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadBytes(tradeCancelorCorrectReturnBitfield10.rest, 1), tradeCancelorCorrectReturnBitfield10.rest) IN IF ~tradeCancelorCorrectReturnBitfield11.ok THEN Fail ELSE
    LET tradeCancelorCorrectReturnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadBytes(tradeCancelorCorrectReturnBitfield11.rest, 1), tradeCancelorCorrectReturnBitfield11.rest) IN IF ~tradeCancelorCorrectReturnBitfield12.ok THEN Fail ELSE
    LET tradeCancelorCorrectReturnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(tradeCancelorCorrectReturnBitfield12.rest, 1), tradeCancelorCorrectReturnBitfield12.rest) IN IF ~tradeCancelorCorrectReturnBitfield13.ok THEN Fail ELSE
    LET tradeCancelorCorrectReturnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(tradeCancelorCorrectReturnBitfield13.rest, 1), tradeCancelorCorrectReturnBitfield13.rest) IN IF ~tradeCancelorCorrectReturnBitfield14.ok THEN Fail ELSE
    LET tradeCancelorCorrectReturnBitfield15 == ReadWhen(numberOfReturnBitfields.value >= 15, ReadBytes(tradeCancelorCorrectReturnBitfield14.rest, 1), tradeCancelorCorrectReturnBitfield14.rest) IN IF ~tradeCancelorCorrectReturnBitfield15.ok THEN Fail ELSE
    LET tradeCancelorCorrectReturnBitfield16 == ReadWhen(numberOfReturnBitfields.value >= 16, ReadBytes(tradeCancelorCorrectReturnBitfield15.rest, 1), tradeCancelorCorrectReturnBitfield15.rest) IN IF ~tradeCancelorCorrectReturnBitfield16.ok THEN Fail ELSE
    LET tradeCancelorCorrectReturnBitfield17 == ReadWhen(numberOfReturnBitfields.value >= 17, ReadBytes(tradeCancelorCorrectReturnBitfield16.rest, 1), tradeCancelorCorrectReturnBitfield16.rest) IN IF ~tradeCancelorCorrectReturnBitfield17.ok THEN Fail ELSE
    LET tradeCancelorCorrectReturnBitfield18 == ReadWhen(numberOfReturnBitfields.value >= 18, ReadBytes(tradeCancelorCorrectReturnBitfield17.rest, 1), tradeCancelorCorrectReturnBitfield17.rest) IN IF ~tradeCancelorCorrectReturnBitfield18.ok THEN Fail ELSE
    LET symbolLong == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (tradeCancelorCorrectReturnBitfield2.value # << >> /\ tradeCancelorCorrectReturnBitfield2.value[1] % 2 > 0), ReadBytes(tradeCancelorCorrectReturnBitfield18.rest, 8), tradeCancelorCorrectReturnBitfield18.rest) IN IF ~symbolLong.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (tradeCancelorCorrectReturnBitfield2.value # << >> /\ (tradeCancelorCorrectReturnBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(symbolLong.rest, 1), symbolLong.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET maturityDate == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (tradeCancelorCorrectReturnBitfield4.value # << >> /\ tradeCancelorCorrectReturnBitfield4.value[1] % 2 > 0), ReadBytes(capacity.rest, 4), capacity.rest) IN IF ~maturityDate.ok THEN Fail ELSE
    LET openClose == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (tradeCancelorCorrectReturnBitfield4.value # << >> /\ (tradeCancelorCorrectReturnBitfield4.value[1] \div 8) % 2 > 0), ReadBytes(maturityDate.rest, 1), maturityDate.rest) IN IF ~openClose.ok THEN Fail ELSE
    LET correctedSize == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (tradeCancelorCorrectReturnBitfield4.value # << >> /\ (tradeCancelorCorrectReturnBitfield4.value[1] \div 32) % 2 > 0), ReadBytes(openClose.rest, 4), openClose.rest) IN IF ~correctedSize.ok THEN Fail ELSE
    LET cmtaNumber == ReadWhen(numberOfReturnBitfields.value >= 9 /\ (tradeCancelorCorrectReturnBitfield9.value # << >> /\ (tradeCancelorCorrectReturnBitfield9.value[1] \div 32) % 2 > 0), ReadBytes(correctedSize.rest, 4), correctedSize.rest) IN IF ~cmtaNumber.ok THEN Fail ELSE
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
         symbolLong                           |-> symbolLong.value,
         capacity                             |-> capacity.value,
         maturityDate                         |-> maturityDate.value,
         openClose                            |-> openClose.value,
         correctedSize                        |-> correctedSize.value,
         cmtaNumber                           |-> cmtaNumber.value ], cmtaNumber.rest)

(* Trade Cancel Or Correct Message with each field marked present by fields before it there exactly where they say *)
SettleTradeCancelOrCorrectMessage(message) ==
    LET settled1 == [message EXCEPT !.tradeCancelorCorrectReturnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.tradeCancelorCorrectReturnBitfield1 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE message.tradeCancelorCorrectReturnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.tradeCancelorCorrectReturnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.tradeCancelorCorrectReturnBitfield2 = << >> THEN <<0>> ELSE settled1.tradeCancelorCorrectReturnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.tradeCancelorCorrectReturnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.tradeCancelorCorrectReturnBitfield3 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled2.tradeCancelorCorrectReturnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.tradeCancelorCorrectReturnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.tradeCancelorCorrectReturnBitfield4 = << >> THEN <<0>> ELSE settled3.tradeCancelorCorrectReturnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.tradeCancelorCorrectReturnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.tradeCancelorCorrectReturnBitfield5 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled4.tradeCancelorCorrectReturnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.tradeCancelorCorrectReturnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.tradeCancelorCorrectReturnBitfield6 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled5.tradeCancelorCorrectReturnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.tradeCancelorCorrectReturnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.tradeCancelorCorrectReturnBitfield7 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.tradeCancelorCorrectReturnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.tradeCancelorCorrectReturnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.tradeCancelorCorrectReturnBitfield8 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled7.tradeCancelorCorrectReturnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.tradeCancelorCorrectReturnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.tradeCancelorCorrectReturnBitfield9 = << >> THEN <<0>> ELSE settled8.tradeCancelorCorrectReturnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.tradeCancelorCorrectReturnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.tradeCancelorCorrectReturnBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.tradeCancelorCorrectReturnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.tradeCancelorCorrectReturnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.tradeCancelorCorrectReturnBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.tradeCancelorCorrectReturnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.tradeCancelorCorrectReturnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.tradeCancelorCorrectReturnBitfield12 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.tradeCancelorCorrectReturnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.tradeCancelorCorrectReturnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.tradeCancelorCorrectReturnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.tradeCancelorCorrectReturnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.tradeCancelorCorrectReturnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.tradeCancelorCorrectReturnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.tradeCancelorCorrectReturnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.tradeCancelorCorrectReturnBitfield15 = IF settled14.numberOfReturnBitfields >= 15 THEN (IF settled14.tradeCancelorCorrectReturnBitfield15 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.tradeCancelorCorrectReturnBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.tradeCancelorCorrectReturnBitfield16 = IF settled15.numberOfReturnBitfields >= 16 THEN (IF settled15.tradeCancelorCorrectReturnBitfield16 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled15.tradeCancelorCorrectReturnBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.tradeCancelorCorrectReturnBitfield17 = IF settled16.numberOfReturnBitfields >= 17 THEN (IF settled16.tradeCancelorCorrectReturnBitfield17 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled16.tradeCancelorCorrectReturnBitfield17) ELSE << >>]
        settled18 == [settled17 EXCEPT !.tradeCancelorCorrectReturnBitfield18 = IF settled17.numberOfReturnBitfields >= 18 THEN (IF settled17.tradeCancelorCorrectReturnBitfield18 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.tradeCancelorCorrectReturnBitfield18) ELSE << >>]
        settled19 == [settled18 EXCEPT !.symbolLong = IF settled18.numberOfReturnBitfields >= 2 /\ (settled18.tradeCancelorCorrectReturnBitfield2 # << >> /\ settled18.tradeCancelorCorrectReturnBitfield2[1] % 2 > 0) THEN (IF settled18.symbolLong = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled18.symbolLong) ELSE << >>]
        settled20 == [settled19 EXCEPT !.capacity = IF settled19.numberOfReturnBitfields >= 2 /\ (settled19.tradeCancelorCorrectReturnBitfield2 # << >> /\ (settled19.tradeCancelorCorrectReturnBitfield2[1] \div 64) % 2 > 0) THEN (IF settled19.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled19.capacity) ELSE << >>]
        settled21 == [settled20 EXCEPT !.maturityDate = IF settled20.numberOfReturnBitfields >= 4 /\ (settled20.tradeCancelorCorrectReturnBitfield4 # << >> /\ settled20.tradeCancelorCorrectReturnBitfield4[1] % 2 > 0) THEN (IF settled20.maturityDate = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled20.maturityDate) ELSE << >>]
        settled22 == [settled21 EXCEPT !.openClose = IF settled21.numberOfReturnBitfields >= 4 /\ (settled21.tradeCancelorCorrectReturnBitfield4 # << >> /\ (settled21.tradeCancelorCorrectReturnBitfield4[1] \div 8) % 2 > 0) THEN (IF settled21.openClose = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled21.openClose) ELSE << >>]
        settled23 == [settled22 EXCEPT !.correctedSize = IF settled22.numberOfReturnBitfields >= 4 /\ (settled22.tradeCancelorCorrectReturnBitfield4 # << >> /\ (settled22.tradeCancelorCorrectReturnBitfield4[1] \div 32) % 2 > 0) THEN (IF settled22.correctedSize = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled22.correctedSize) ELSE << >>]
        settled24 == [settled23 EXCEPT !.cmtaNumber = IF settled23.numberOfReturnBitfields >= 9 /\ (settled23.tradeCancelorCorrectReturnBitfield9 # << >> /\ (settled23.tradeCancelorCorrectReturnBitfield9[1] \div 32) % 2 > 0) THEN (IF settled23.cmtaNumber = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled23.cmtaNumber) ELSE << >>]
    IN  settled24

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
                                        symbolLong                           |-> << >>,
                                        capacity                             |-> << >>,
                                        maturityDate                         |-> << >>,
                                        openClose                            |-> << >>,
                                        correctedSize                        |-> << >>,
                                        cmtaNumber                           |-> << >> ])

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
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 4, !.tradeCancelorCorrectReturnBitfield4 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 5, !.tradeCancelorCorrectReturnBitfield5 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 6, !.tradeCancelorCorrectReturnBitfield6 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 7, !.tradeCancelorCorrectReturnBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 8, !.tradeCancelorCorrectReturnBitfield8 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 9, !.tradeCancelorCorrectReturnBitfield9 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 10, !.tradeCancelorCorrectReturnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 11, !.tradeCancelorCorrectReturnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 12, !.tradeCancelorCorrectReturnBitfield12 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 13, !.tradeCancelorCorrectReturnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 14, !.tradeCancelorCorrectReturnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 15, !.tradeCancelorCorrectReturnBitfield15 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 16, !.tradeCancelorCorrectReturnBitfield16 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 17, !.tradeCancelorCorrectReturnBitfield17 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 18, !.tradeCancelorCorrectReturnBitfield18 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 2, !.tradeCancelorCorrectReturnBitfield2 = <<1>>, !.symbolLong = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 2, !.tradeCancelorCorrectReturnBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 4, !.tradeCancelorCorrectReturnBitfield4 = <<1>>, !.maturityDate = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 4, !.tradeCancelorCorrectReturnBitfield4 = <<8>>, !.openClose = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 4, !.tradeCancelorCorrectReturnBitfield4 = <<32>>, !.correctedSize = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 9, !.tradeCancelorCorrectReturnBitfield9 = <<32>>, !.cmtaNumber = one]) : one \in { <<held>> : held \in Sample(4) } }

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
    LET massCancelId == ReadWhen(numberOfReturnBitfields.value >= 15 /\ (purgeRejectedReturnBitfield15.value # << >> /\ (purgeRejectedReturnBitfield15.value[1] \div 8) % 2 > 0), ReadBytes(purgeRejectedReturnBitfield18.rest, 20), purgeRejectedReturnBitfield18.rest) IN IF ~massCancelId.ok THEN Fail ELSE
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
        settled19 == [settled18 EXCEPT !.massCancelId = IF settled18.numberOfReturnBitfields >= 15 /\ (settled18.purgeRejectedReturnBitfield15 # << >> /\ (settled18.purgeRejectedReturnBitfield15[1] \div 8) % 2 > 0) THEN (IF settled18.massCancelId = << >> THEN <<[i \in 1 .. 20 |-> 0]>> ELSE settled18.massCancelId) ELSE << >>]
    IN  settled19

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
        \cup { SettlePurgeRejectedMessage([ZeroPurgeRejectedMessage EXCEPT !.numberOfReturnBitfields = 15, !.purgeRejectedReturnBitfield15 = <<8>>, !.massCancelId = one]) : one \in { <<held>> : held \in Sample(20) } }

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
(* Tas Restatement New Order Message Message                               *)
(***************************************************************************)

TasRestatementNewOrderMessageMessage ==
    [ transactionTime                 : Sample(8),
      clOrdId                         : Sample(20),
      execId                          : Sample(8),
      reserved1                       : Sample(1),
      numberOfTasRestatementBitfields : 0 .. 255,
      tasRestatementBitfield1         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tasRestatementBitfield2         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tasRestatementBitfield3         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tasRestatementBitfield4         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tasRestatementBitfield5         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tasRestatementBitfield6         : { << >> } \cup { <<held>> : held \in Sample(1) },
      tasRestatementBitfield7         : { << >> } \cup { <<held>> : held \in Sample(1) },
      tasRestatementBitfield8         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tasRestatementBitfield9         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tasRestatementBitfield10        : { << >> } \cup { <<held>> : held \in Sample(1) },
      tasRestatementBitfield11        : { << >> } \cup { <<held>> : held \in Sample(1) },
      tasRestatementBitfield12        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tasRestatementBitfield13        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tasRestatementBitfield14        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tasRestatementBitfield15        : { << >> } \cup { <<held>> : held \in Sample(1) },
      tasRestatementBitfield16        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tasRestatementBitfield17        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      tasRestatementBitfield18        : { << >> } \cup { <<held>> : held \in Sample(1) },
      side                            : { << >> } \cup { <<held>> : held \in Sample(1) },
      price                           : { << >> } \cup { <<held>> : held \in Sample(8) },
      ordType                         : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce                     : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                          : { << >> } \cup { <<held>> : held \in Sample(4) },
      symbolLong                      : { << >> } \cup { <<held>> : held \in Sample(8) },
      capacity                        : { << >> } \cup { <<held>> : held \in Sample(1) },
      account                         : { << >> } \cup { <<held>> : held \in Sample(16) },
      clearingFirm                    : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingAccount                 : { << >> } \cup { <<held>> : held \in Sample(4) },
      preventMatch                    : { << >> } \cup { <<held>> : held \in Sample(3) },
      maturityDate                    : { << >> } \cup { <<held>> : held \in Sample(4) },
      openClose                       : { << >> } \cup { <<held>> : held \in Sample(1) },
      origClOrdId                     : { << >> } \cup { <<held>> : held \in Sample(20) },
      lastShares                      : { << >> } \cup { <<held>> : held \in Sample(4) },
      lastPx                          : { << >> } \cup { <<held>> : held \in Sample(8) },
      feeCode                         : { << >> } \cup { <<held>> : held \in Sample(2) },
      stopPx                          : { << >> } \cup { <<held>> : held \in Sample(8) },
      cmtaNumber                      : { << >> } \cup { <<held>> : held \in Sample(4) },
      ctiCode                         : { << >> } \cup { <<held>> : held \in Sample(1) },
      manualOrderIndicator            : { << >> } \cup { <<held>> : held \in Sample(1) },
      oeoid                           : { << >> } \cup { <<held>> : held \in Sample(18) },
      tradeDate                       : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingPrice                   : { << >> } \cup { <<held>> : held \in Sample(8) },
      clearingSymbol                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      multilegReportingType           : { << >> } \cup { <<held>> : held \in Sample(1) },
      secondaryExecId                 : { << >> } \cup { <<held>> : held \in Sample(8) },
      frequentTraderId                : { << >> } \cup { <<held>> : held \in Sample(6) },
      custOrderHandlingInst           : { << >> } \cup { <<held>> : held \in Sample(1) } ]

EncodeTasRestatementNewOrderMessageMessage(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.execId
        \o message.reserved1
        \o EncodeUIntBE(message.numberOfTasRestatementBitfields, 1)
        \o (IF message.tasRestatementBitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.tasRestatementBitfield1[1], 1))
        \o (IF message.tasRestatementBitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.tasRestatementBitfield2[1], 1))
        \o (IF message.tasRestatementBitfield3 = << >> THEN << >> ELSE EncodeUIntLE(message.tasRestatementBitfield3[1], 1))
        \o (IF message.tasRestatementBitfield4 = << >> THEN << >> ELSE EncodeUIntLE(message.tasRestatementBitfield4[1], 1))
        \o (IF message.tasRestatementBitfield5 = << >> THEN << >> ELSE EncodeUIntLE(message.tasRestatementBitfield5[1], 1))
        \o (IF message.tasRestatementBitfield6 = << >> THEN << >> ELSE message.tasRestatementBitfield6[1])
        \o (IF message.tasRestatementBitfield7 = << >> THEN << >> ELSE message.tasRestatementBitfield7[1])
        \o (IF message.tasRestatementBitfield8 = << >> THEN << >> ELSE EncodeUIntLE(message.tasRestatementBitfield8[1], 1))
        \o (IF message.tasRestatementBitfield9 = << >> THEN << >> ELSE EncodeUIntLE(message.tasRestatementBitfield9[1], 1))
        \o (IF message.tasRestatementBitfield10 = << >> THEN << >> ELSE message.tasRestatementBitfield10[1])
        \o (IF message.tasRestatementBitfield11 = << >> THEN << >> ELSE message.tasRestatementBitfield11[1])
        \o (IF message.tasRestatementBitfield12 = << >> THEN << >> ELSE EncodeUIntLE(message.tasRestatementBitfield12[1], 1))
        \o (IF message.tasRestatementBitfield13 = << >> THEN << >> ELSE EncodeUIntLE(message.tasRestatementBitfield13[1], 1))
        \o (IF message.tasRestatementBitfield14 = << >> THEN << >> ELSE EncodeUIntLE(message.tasRestatementBitfield14[1], 1))
        \o (IF message.tasRestatementBitfield15 = << >> THEN << >> ELSE message.tasRestatementBitfield15[1])
        \o (IF message.tasRestatementBitfield16 = << >> THEN << >> ELSE EncodeUIntLE(message.tasRestatementBitfield16[1], 1))
        \o (IF message.tasRestatementBitfield17 = << >> THEN << >> ELSE EncodeUIntLE(message.tasRestatementBitfield17[1], 1))
        \o (IF message.tasRestatementBitfield18 = << >> THEN << >> ELSE message.tasRestatementBitfield18[1])
        \o (IF message.side = << >> THEN << >> ELSE message.side[1])
        \o (IF message.price = << >> THEN << >> ELSE message.price[1])
        \o (IF message.ordType = << >> THEN << >> ELSE message.ordType[1])
        \o (IF message.timeInForce = << >> THEN << >> ELSE message.timeInForce[1])
        \o (IF message.minQty = << >> THEN << >> ELSE message.minQty[1])
        \o (IF message.symbolLong = << >> THEN << >> ELSE message.symbolLong[1])
        \o (IF message.capacity = << >> THEN << >> ELSE message.capacity[1])
        \o (IF message.account = << >> THEN << >> ELSE message.account[1])
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])
        \o (IF message.clearingAccount = << >> THEN << >> ELSE message.clearingAccount[1])
        \o (IF message.preventMatch = << >> THEN << >> ELSE message.preventMatch[1])
        \o (IF message.maturityDate = << >> THEN << >> ELSE message.maturityDate[1])
        \o (IF message.openClose = << >> THEN << >> ELSE message.openClose[1])
        \o (IF message.origClOrdId = << >> THEN << >> ELSE message.origClOrdId[1])
        \o (IF message.lastShares = << >> THEN << >> ELSE message.lastShares[1])
        \o (IF message.lastPx = << >> THEN << >> ELSE message.lastPx[1])
        \o (IF message.feeCode = << >> THEN << >> ELSE message.feeCode[1])
        \o (IF message.stopPx = << >> THEN << >> ELSE message.stopPx[1])
        \o (IF message.cmtaNumber = << >> THEN << >> ELSE message.cmtaNumber[1])
        \o (IF message.ctiCode = << >> THEN << >> ELSE message.ctiCode[1])
        \o (IF message.manualOrderIndicator = << >> THEN << >> ELSE message.manualOrderIndicator[1])
        \o (IF message.oeoid = << >> THEN << >> ELSE message.oeoid[1])
        \o (IF message.tradeDate = << >> THEN << >> ELSE message.tradeDate[1])
        \o (IF message.clearingPrice = << >> THEN << >> ELSE message.clearingPrice[1])
        \o (IF message.clearingSymbol = << >> THEN << >> ELSE message.clearingSymbol[1])
        \o (IF message.multilegReportingType = << >> THEN << >> ELSE message.multilegReportingType[1])
        \o (IF message.secondaryExecId = << >> THEN << >> ELSE message.secondaryExecId[1])
        \o (IF message.frequentTraderId = << >> THEN << >> ELSE message.frequentTraderId[1])
        \o (IF message.custOrderHandlingInst = << >> THEN << >> ELSE message.custOrderHandlingInst[1])

DecodeTasRestatementNewOrderMessageMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET execId == ReadBytes(clOrdId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(execId.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET numberOfTasRestatementBitfields == ReadUIntBE(reserved1.rest, 1) IN IF ~numberOfTasRestatementBitfields.ok THEN Fail ELSE
    LET tasRestatementBitfield1 == ReadWhen(numberOfTasRestatementBitfields.value >= 1, ReadUIntLE(numberOfTasRestatementBitfields.rest, 1), numberOfTasRestatementBitfields.rest) IN IF ~tasRestatementBitfield1.ok THEN Fail ELSE
    LET tasRestatementBitfield2 == ReadWhen(numberOfTasRestatementBitfields.value >= 2, ReadUIntLE(tasRestatementBitfield1.rest, 1), tasRestatementBitfield1.rest) IN IF ~tasRestatementBitfield2.ok THEN Fail ELSE
    LET tasRestatementBitfield3 == ReadWhen(numberOfTasRestatementBitfields.value >= 3, ReadUIntLE(tasRestatementBitfield2.rest, 1), tasRestatementBitfield2.rest) IN IF ~tasRestatementBitfield3.ok THEN Fail ELSE
    LET tasRestatementBitfield4 == ReadWhen(numberOfTasRestatementBitfields.value >= 4, ReadUIntLE(tasRestatementBitfield3.rest, 1), tasRestatementBitfield3.rest) IN IF ~tasRestatementBitfield4.ok THEN Fail ELSE
    LET tasRestatementBitfield5 == ReadWhen(numberOfTasRestatementBitfields.value >= 5, ReadUIntLE(tasRestatementBitfield4.rest, 1), tasRestatementBitfield4.rest) IN IF ~tasRestatementBitfield5.ok THEN Fail ELSE
    LET tasRestatementBitfield6 == ReadWhen(numberOfTasRestatementBitfields.value >= 6, ReadBytes(tasRestatementBitfield5.rest, 1), tasRestatementBitfield5.rest) IN IF ~tasRestatementBitfield6.ok THEN Fail ELSE
    LET tasRestatementBitfield7 == ReadWhen(numberOfTasRestatementBitfields.value >= 7, ReadBytes(tasRestatementBitfield6.rest, 1), tasRestatementBitfield6.rest) IN IF ~tasRestatementBitfield7.ok THEN Fail ELSE
    LET tasRestatementBitfield8 == ReadWhen(numberOfTasRestatementBitfields.value >= 8, ReadUIntLE(tasRestatementBitfield7.rest, 1), tasRestatementBitfield7.rest) IN IF ~tasRestatementBitfield8.ok THEN Fail ELSE
    LET tasRestatementBitfield9 == ReadWhen(numberOfTasRestatementBitfields.value >= 9, ReadUIntLE(tasRestatementBitfield8.rest, 1), tasRestatementBitfield8.rest) IN IF ~tasRestatementBitfield9.ok THEN Fail ELSE
    LET tasRestatementBitfield10 == ReadWhen(numberOfTasRestatementBitfields.value >= 10, ReadBytes(tasRestatementBitfield9.rest, 1), tasRestatementBitfield9.rest) IN IF ~tasRestatementBitfield10.ok THEN Fail ELSE
    LET tasRestatementBitfield11 == ReadWhen(numberOfTasRestatementBitfields.value >= 11, ReadBytes(tasRestatementBitfield10.rest, 1), tasRestatementBitfield10.rest) IN IF ~tasRestatementBitfield11.ok THEN Fail ELSE
    LET tasRestatementBitfield12 == ReadWhen(numberOfTasRestatementBitfields.value >= 12, ReadUIntLE(tasRestatementBitfield11.rest, 1), tasRestatementBitfield11.rest) IN IF ~tasRestatementBitfield12.ok THEN Fail ELSE
    LET tasRestatementBitfield13 == ReadWhen(numberOfTasRestatementBitfields.value >= 13, ReadUIntLE(tasRestatementBitfield12.rest, 1), tasRestatementBitfield12.rest) IN IF ~tasRestatementBitfield13.ok THEN Fail ELSE
    LET tasRestatementBitfield14 == ReadWhen(numberOfTasRestatementBitfields.value >= 14, ReadUIntLE(tasRestatementBitfield13.rest, 1), tasRestatementBitfield13.rest) IN IF ~tasRestatementBitfield14.ok THEN Fail ELSE
    LET tasRestatementBitfield15 == ReadWhen(numberOfTasRestatementBitfields.value >= 15, ReadBytes(tasRestatementBitfield14.rest, 1), tasRestatementBitfield14.rest) IN IF ~tasRestatementBitfield15.ok THEN Fail ELSE
    LET tasRestatementBitfield16 == ReadWhen(numberOfTasRestatementBitfields.value >= 16, ReadUIntLE(tasRestatementBitfield15.rest, 1), tasRestatementBitfield15.rest) IN IF ~tasRestatementBitfield16.ok THEN Fail ELSE
    LET tasRestatementBitfield17 == ReadWhen(numberOfTasRestatementBitfields.value >= 17, ReadUIntLE(tasRestatementBitfield16.rest, 1), tasRestatementBitfield16.rest) IN IF ~tasRestatementBitfield17.ok THEN Fail ELSE
    LET tasRestatementBitfield18 == ReadWhen(numberOfTasRestatementBitfields.value >= 18, ReadBytes(tasRestatementBitfield17.rest, 1), tasRestatementBitfield17.rest) IN IF ~tasRestatementBitfield18.ok THEN Fail ELSE
    LET side == ReadWhen(numberOfTasRestatementBitfields.value >= 1 /\ (tasRestatementBitfield1.value # << >> /\ tasRestatementBitfield1.value[1] % 2 > 0), ReadBytes(tasRestatementBitfield18.rest, 1), tasRestatementBitfield18.rest) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadWhen(numberOfTasRestatementBitfields.value >= 1 /\ (tasRestatementBitfield1.value # << >> /\ (tasRestatementBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(side.rest, 8), side.rest) IN IF ~price.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfTasRestatementBitfields.value >= 1 /\ (tasRestatementBitfield1.value # << >> /\ (tasRestatementBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(price.rest, 1), price.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfTasRestatementBitfields.value >= 1 /\ (tasRestatementBitfield1.value # << >> /\ (tasRestatementBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfTasRestatementBitfields.value >= 1 /\ (tasRestatementBitfield1.value # << >> /\ (tasRestatementBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET symbolLong == ReadWhen(numberOfTasRestatementBitfields.value >= 2 /\ (tasRestatementBitfield2.value # << >> /\ tasRestatementBitfield2.value[1] % 2 > 0), ReadBytes(minQty.rest, 8), minQty.rest) IN IF ~symbolLong.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfTasRestatementBitfields.value >= 2 /\ (tasRestatementBitfield2.value # << >> /\ (tasRestatementBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(symbolLong.rest, 1), symbolLong.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadWhen(numberOfTasRestatementBitfields.value >= 3 /\ (tasRestatementBitfield3.value # << >> /\ tasRestatementBitfield3.value[1] % 2 > 0), ReadBytes(capacity.rest, 16), capacity.rest) IN IF ~account.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfTasRestatementBitfields.value >= 3 /\ (tasRestatementBitfield3.value # << >> /\ (tasRestatementBitfield3.value[1] \div 2) % 2 > 0), ReadBytes(account.rest, 4), account.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadWhen(numberOfTasRestatementBitfields.value >= 3 /\ (tasRestatementBitfield3.value # << >> /\ (tasRestatementBitfield3.value[1] \div 4) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET preventMatch == ReadWhen(numberOfTasRestatementBitfields.value >= 3 /\ (tasRestatementBitfield3.value # << >> /\ (tasRestatementBitfield3.value[1] \div 128) % 2 > 0), ReadBytes(clearingAccount.rest, 3), clearingAccount.rest) IN IF ~preventMatch.ok THEN Fail ELSE
    LET maturityDate == ReadWhen(numberOfTasRestatementBitfields.value >= 4 /\ (tasRestatementBitfield4.value # << >> /\ tasRestatementBitfield4.value[1] % 2 > 0), ReadBytes(preventMatch.rest, 4), preventMatch.rest) IN IF ~maturityDate.ok THEN Fail ELSE
    LET openClose == ReadWhen(numberOfTasRestatementBitfields.value >= 4 /\ (tasRestatementBitfield4.value # << >> /\ (tasRestatementBitfield4.value[1] \div 8) % 2 > 0), ReadBytes(maturityDate.rest, 1), maturityDate.rest) IN IF ~openClose.ok THEN Fail ELSE
    LET origClOrdId == ReadWhen(numberOfTasRestatementBitfields.value >= 5 /\ (tasRestatementBitfield5.value # << >> /\ tasRestatementBitfield5.value[1] % 2 > 0), ReadBytes(openClose.rest, 20), openClose.rest) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET lastShares == ReadWhen(numberOfTasRestatementBitfields.value >= 5 /\ (tasRestatementBitfield5.value # << >> /\ (tasRestatementBitfield5.value[1] \div 4) % 2 > 0), ReadBytes(origClOrdId.rest, 4), origClOrdId.rest) IN IF ~lastShares.ok THEN Fail ELSE
    LET lastPx == ReadWhen(numberOfTasRestatementBitfields.value >= 5 /\ (tasRestatementBitfield5.value # << >> /\ (tasRestatementBitfield5.value[1] \div 8) % 2 > 0), ReadBytes(lastShares.rest, 8), lastShares.rest) IN IF ~lastPx.ok THEN Fail ELSE
    LET feeCode == ReadWhen(numberOfTasRestatementBitfields.value >= 8 /\ (tasRestatementBitfield8.value # << >> /\ tasRestatementBitfield8.value[1] % 2 > 0), ReadBytes(lastPx.rest, 2), lastPx.rest) IN IF ~feeCode.ok THEN Fail ELSE
    LET stopPx == ReadWhen(numberOfTasRestatementBitfields.value >= 8 /\ (tasRestatementBitfield8.value # << >> /\ (tasRestatementBitfield8.value[1] \div 4) % 2 > 0), ReadBytes(feeCode.rest, 8), feeCode.rest) IN IF ~stopPx.ok THEN Fail ELSE
    LET cmtaNumber == ReadWhen(numberOfTasRestatementBitfields.value >= 9 /\ (tasRestatementBitfield9.value # << >> /\ (tasRestatementBitfield9.value[1] \div 32) % 2 > 0), ReadBytes(stopPx.rest, 4), stopPx.rest) IN IF ~cmtaNumber.ok THEN Fail ELSE
    LET ctiCode == ReadWhen(numberOfTasRestatementBitfields.value >= 12 /\ (tasRestatementBitfield12.value # << >> /\ tasRestatementBitfield12.value[1] % 2 > 0), ReadBytes(cmtaNumber.rest, 1), cmtaNumber.rest) IN IF ~ctiCode.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadWhen(numberOfTasRestatementBitfields.value >= 12 /\ (tasRestatementBitfield12.value # << >> /\ (tasRestatementBitfield12.value[1] \div 2) % 2 > 0), ReadBytes(ctiCode.rest, 1), ctiCode.rest) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET oeoid == ReadWhen(numberOfTasRestatementBitfields.value >= 12 /\ (tasRestatementBitfield12.value # << >> /\ (tasRestatementBitfield12.value[1] \div 4) % 2 > 0), ReadBytes(manualOrderIndicator.rest, 18), manualOrderIndicator.rest) IN IF ~oeoid.ok THEN Fail ELSE
    LET tradeDate == ReadWhen(numberOfTasRestatementBitfields.value >= 12 /\ (tasRestatementBitfield12.value # << >> /\ (tasRestatementBitfield12.value[1] \div 8) % 2 > 0), ReadBytes(oeoid.rest, 4), oeoid.rest) IN IF ~tradeDate.ok THEN Fail ELSE
    LET clearingPrice == ReadWhen(numberOfTasRestatementBitfields.value >= 12 /\ (tasRestatementBitfield12.value # << >> /\ (tasRestatementBitfield12.value[1] \div 16) % 2 > 0), ReadBytes(tradeDate.rest, 8), tradeDate.rest) IN IF ~clearingPrice.ok THEN Fail ELSE
    LET clearingSymbol == ReadWhen(numberOfTasRestatementBitfields.value >= 12 /\ (tasRestatementBitfield12.value # << >> /\ (tasRestatementBitfield12.value[1] \div 64) % 2 > 0), ReadBytes(clearingPrice.rest, 8), clearingPrice.rest) IN IF ~clearingSymbol.ok THEN Fail ELSE
    LET multilegReportingType == ReadWhen(numberOfTasRestatementBitfields.value >= 13 /\ (tasRestatementBitfield13.value # << >> /\ (tasRestatementBitfield13.value[1] \div 128) % 2 > 0), ReadBytes(clearingSymbol.rest, 1), clearingSymbol.rest) IN IF ~multilegReportingType.ok THEN Fail ELSE
    LET secondaryExecId == ReadWhen(numberOfTasRestatementBitfields.value >= 14 /\ (tasRestatementBitfield14.value # << >> /\ (tasRestatementBitfield14.value[1] \div 16) % 2 > 0), ReadBytes(multilegReportingType.rest, 8), multilegReportingType.rest) IN IF ~secondaryExecId.ok THEN Fail ELSE
    LET frequentTraderId == ReadWhen(numberOfTasRestatementBitfields.value >= 16 /\ (tasRestatementBitfield16.value # << >> /\ tasRestatementBitfield16.value[1] % 2 > 0), ReadBytes(secondaryExecId.rest, 6), secondaryExecId.rest) IN IF ~frequentTraderId.ok THEN Fail ELSE
    LET custOrderHandlingInst == ReadWhen(numberOfTasRestatementBitfields.value >= 17 /\ (tasRestatementBitfield17.value # << >> /\ (tasRestatementBitfield17.value[1] \div 128) % 2 > 0), ReadBytes(frequentTraderId.rest, 1), frequentTraderId.rest) IN IF ~custOrderHandlingInst.ok THEN Fail ELSE
    Ok([ transactionTime                 |-> transactionTime.value,
         clOrdId                         |-> clOrdId.value,
         execId                          |-> execId.value,
         reserved1                       |-> reserved1.value,
         numberOfTasRestatementBitfields |-> numberOfTasRestatementBitfields.value,
         tasRestatementBitfield1         |-> tasRestatementBitfield1.value,
         tasRestatementBitfield2         |-> tasRestatementBitfield2.value,
         tasRestatementBitfield3         |-> tasRestatementBitfield3.value,
         tasRestatementBitfield4         |-> tasRestatementBitfield4.value,
         tasRestatementBitfield5         |-> tasRestatementBitfield5.value,
         tasRestatementBitfield6         |-> tasRestatementBitfield6.value,
         tasRestatementBitfield7         |-> tasRestatementBitfield7.value,
         tasRestatementBitfield8         |-> tasRestatementBitfield8.value,
         tasRestatementBitfield9         |-> tasRestatementBitfield9.value,
         tasRestatementBitfield10        |-> tasRestatementBitfield10.value,
         tasRestatementBitfield11        |-> tasRestatementBitfield11.value,
         tasRestatementBitfield12        |-> tasRestatementBitfield12.value,
         tasRestatementBitfield13        |-> tasRestatementBitfield13.value,
         tasRestatementBitfield14        |-> tasRestatementBitfield14.value,
         tasRestatementBitfield15        |-> tasRestatementBitfield15.value,
         tasRestatementBitfield16        |-> tasRestatementBitfield16.value,
         tasRestatementBitfield17        |-> tasRestatementBitfield17.value,
         tasRestatementBitfield18        |-> tasRestatementBitfield18.value,
         side                            |-> side.value,
         price                           |-> price.value,
         ordType                         |-> ordType.value,
         timeInForce                     |-> timeInForce.value,
         minQty                          |-> minQty.value,
         symbolLong                      |-> symbolLong.value,
         capacity                        |-> capacity.value,
         account                         |-> account.value,
         clearingFirm                    |-> clearingFirm.value,
         clearingAccount                 |-> clearingAccount.value,
         preventMatch                    |-> preventMatch.value,
         maturityDate                    |-> maturityDate.value,
         openClose                       |-> openClose.value,
         origClOrdId                     |-> origClOrdId.value,
         lastShares                      |-> lastShares.value,
         lastPx                          |-> lastPx.value,
         feeCode                         |-> feeCode.value,
         stopPx                          |-> stopPx.value,
         cmtaNumber                      |-> cmtaNumber.value,
         ctiCode                         |-> ctiCode.value,
         manualOrderIndicator            |-> manualOrderIndicator.value,
         oeoid                           |-> oeoid.value,
         tradeDate                       |-> tradeDate.value,
         clearingPrice                   |-> clearingPrice.value,
         clearingSymbol                  |-> clearingSymbol.value,
         multilegReportingType           |-> multilegReportingType.value,
         secondaryExecId                 |-> secondaryExecId.value,
         frequentTraderId                |-> frequentTraderId.value,
         custOrderHandlingInst           |-> custOrderHandlingInst.value ], custOrderHandlingInst.rest)

(* Tas Restatement New Order Message Message with each field marked present by fields before it there exactly where they say *)
SettleTasRestatementNewOrderMessageMessage(message) ==
    LET settled1 == [message EXCEPT !.tasRestatementBitfield1 = IF message.numberOfTasRestatementBitfields >= 1 THEN (IF message.tasRestatementBitfield1 = << >> THEN <<0>> ELSE message.tasRestatementBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.tasRestatementBitfield2 = IF settled1.numberOfTasRestatementBitfields >= 2 THEN (IF settled1.tasRestatementBitfield2 = << >> THEN <<0>> ELSE settled1.tasRestatementBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.tasRestatementBitfield3 = IF settled2.numberOfTasRestatementBitfields >= 3 THEN (IF settled2.tasRestatementBitfield3 = << >> THEN <<0>> ELSE settled2.tasRestatementBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.tasRestatementBitfield4 = IF settled3.numberOfTasRestatementBitfields >= 4 THEN (IF settled3.tasRestatementBitfield4 = << >> THEN <<0>> ELSE settled3.tasRestatementBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.tasRestatementBitfield5 = IF settled4.numberOfTasRestatementBitfields >= 5 THEN (IF settled4.tasRestatementBitfield5 = << >> THEN <<0>> ELSE settled4.tasRestatementBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.tasRestatementBitfield6 = IF settled5.numberOfTasRestatementBitfields >= 6 THEN (IF settled5.tasRestatementBitfield6 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled5.tasRestatementBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.tasRestatementBitfield7 = IF settled6.numberOfTasRestatementBitfields >= 7 THEN (IF settled6.tasRestatementBitfield7 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.tasRestatementBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.tasRestatementBitfield8 = IF settled7.numberOfTasRestatementBitfields >= 8 THEN (IF settled7.tasRestatementBitfield8 = << >> THEN <<0>> ELSE settled7.tasRestatementBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.tasRestatementBitfield9 = IF settled8.numberOfTasRestatementBitfields >= 9 THEN (IF settled8.tasRestatementBitfield9 = << >> THEN <<0>> ELSE settled8.tasRestatementBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.tasRestatementBitfield10 = IF settled9.numberOfTasRestatementBitfields >= 10 THEN (IF settled9.tasRestatementBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.tasRestatementBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.tasRestatementBitfield11 = IF settled10.numberOfTasRestatementBitfields >= 11 THEN (IF settled10.tasRestatementBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.tasRestatementBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.tasRestatementBitfield12 = IF settled11.numberOfTasRestatementBitfields >= 12 THEN (IF settled11.tasRestatementBitfield12 = << >> THEN <<0>> ELSE settled11.tasRestatementBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.tasRestatementBitfield13 = IF settled12.numberOfTasRestatementBitfields >= 13 THEN (IF settled12.tasRestatementBitfield13 = << >> THEN <<0>> ELSE settled12.tasRestatementBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.tasRestatementBitfield14 = IF settled13.numberOfTasRestatementBitfields >= 14 THEN (IF settled13.tasRestatementBitfield14 = << >> THEN <<0>> ELSE settled13.tasRestatementBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.tasRestatementBitfield15 = IF settled14.numberOfTasRestatementBitfields >= 15 THEN (IF settled14.tasRestatementBitfield15 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.tasRestatementBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.tasRestatementBitfield16 = IF settled15.numberOfTasRestatementBitfields >= 16 THEN (IF settled15.tasRestatementBitfield16 = << >> THEN <<0>> ELSE settled15.tasRestatementBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.tasRestatementBitfield17 = IF settled16.numberOfTasRestatementBitfields >= 17 THEN (IF settled16.tasRestatementBitfield17 = << >> THEN <<0>> ELSE settled16.tasRestatementBitfield17) ELSE << >>]
        settled18 == [settled17 EXCEPT !.tasRestatementBitfield18 = IF settled17.numberOfTasRestatementBitfields >= 18 THEN (IF settled17.tasRestatementBitfield18 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.tasRestatementBitfield18) ELSE << >>]
        settled19 == [settled18 EXCEPT !.side = IF settled18.numberOfTasRestatementBitfields >= 1 /\ (settled18.tasRestatementBitfield1 # << >> /\ settled18.tasRestatementBitfield1[1] % 2 > 0) THEN (IF settled18.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled18.side) ELSE << >>]
        settled20 == [settled19 EXCEPT !.price = IF settled19.numberOfTasRestatementBitfields >= 1 /\ (settled19.tasRestatementBitfield1 # << >> /\ (settled19.tasRestatementBitfield1[1] \div 4) % 2 > 0) THEN (IF settled19.price = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled19.price) ELSE << >>]
        settled21 == [settled20 EXCEPT !.ordType = IF settled20.numberOfTasRestatementBitfields >= 1 /\ (settled20.tasRestatementBitfield1 # << >> /\ (settled20.tasRestatementBitfield1[1] \div 16) % 2 > 0) THEN (IF settled20.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled20.ordType) ELSE << >>]
        settled22 == [settled21 EXCEPT !.timeInForce = IF settled21.numberOfTasRestatementBitfields >= 1 /\ (settled21.tasRestatementBitfield1 # << >> /\ (settled21.tasRestatementBitfield1[1] \div 32) % 2 > 0) THEN (IF settled21.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled21.timeInForce) ELSE << >>]
        settled23 == [settled22 EXCEPT !.minQty = IF settled22.numberOfTasRestatementBitfields >= 1 /\ (settled22.tasRestatementBitfield1 # << >> /\ (settled22.tasRestatementBitfield1[1] \div 64) % 2 > 0) THEN (IF settled22.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled22.minQty) ELSE << >>]
        settled24 == [settled23 EXCEPT !.symbolLong = IF settled23.numberOfTasRestatementBitfields >= 2 /\ (settled23.tasRestatementBitfield2 # << >> /\ settled23.tasRestatementBitfield2[1] % 2 > 0) THEN (IF settled23.symbolLong = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled23.symbolLong) ELSE << >>]
        settled25 == [settled24 EXCEPT !.capacity = IF settled24.numberOfTasRestatementBitfields >= 2 /\ (settled24.tasRestatementBitfield2 # << >> /\ (settled24.tasRestatementBitfield2[1] \div 64) % 2 > 0) THEN (IF settled24.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled24.capacity) ELSE << >>]
        settled26 == [settled25 EXCEPT !.account = IF settled25.numberOfTasRestatementBitfields >= 3 /\ (settled25.tasRestatementBitfield3 # << >> /\ settled25.tasRestatementBitfield3[1] % 2 > 0) THEN (IF settled25.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled25.account) ELSE << >>]
        settled27 == [settled26 EXCEPT !.clearingFirm = IF settled26.numberOfTasRestatementBitfields >= 3 /\ (settled26.tasRestatementBitfield3 # << >> /\ (settled26.tasRestatementBitfield3[1] \div 2) % 2 > 0) THEN (IF settled26.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled26.clearingFirm) ELSE << >>]
        settled28 == [settled27 EXCEPT !.clearingAccount = IF settled27.numberOfTasRestatementBitfields >= 3 /\ (settled27.tasRestatementBitfield3 # << >> /\ (settled27.tasRestatementBitfield3[1] \div 4) % 2 > 0) THEN (IF settled27.clearingAccount = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled27.clearingAccount) ELSE << >>]
        settled29 == [settled28 EXCEPT !.preventMatch = IF settled28.numberOfTasRestatementBitfields >= 3 /\ (settled28.tasRestatementBitfield3 # << >> /\ (settled28.tasRestatementBitfield3[1] \div 128) % 2 > 0) THEN (IF settled28.preventMatch = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled28.preventMatch) ELSE << >>]
        settled30 == [settled29 EXCEPT !.maturityDate = IF settled29.numberOfTasRestatementBitfields >= 4 /\ (settled29.tasRestatementBitfield4 # << >> /\ settled29.tasRestatementBitfield4[1] % 2 > 0) THEN (IF settled29.maturityDate = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled29.maturityDate) ELSE << >>]
        settled31 == [settled30 EXCEPT !.openClose = IF settled30.numberOfTasRestatementBitfields >= 4 /\ (settled30.tasRestatementBitfield4 # << >> /\ (settled30.tasRestatementBitfield4[1] \div 8) % 2 > 0) THEN (IF settled30.openClose = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled30.openClose) ELSE << >>]
        settled32 == [settled31 EXCEPT !.origClOrdId = IF settled31.numberOfTasRestatementBitfields >= 5 /\ (settled31.tasRestatementBitfield5 # << >> /\ settled31.tasRestatementBitfield5[1] % 2 > 0) THEN (IF settled31.origClOrdId = << >> THEN <<[i \in 1 .. 20 |-> 0]>> ELSE settled31.origClOrdId) ELSE << >>]
        settled33 == [settled32 EXCEPT !.lastShares = IF settled32.numberOfTasRestatementBitfields >= 5 /\ (settled32.tasRestatementBitfield5 # << >> /\ (settled32.tasRestatementBitfield5[1] \div 4) % 2 > 0) THEN (IF settled32.lastShares = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled32.lastShares) ELSE << >>]
        settled34 == [settled33 EXCEPT !.lastPx = IF settled33.numberOfTasRestatementBitfields >= 5 /\ (settled33.tasRestatementBitfield5 # << >> /\ (settled33.tasRestatementBitfield5[1] \div 8) % 2 > 0) THEN (IF settled33.lastPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled33.lastPx) ELSE << >>]
        settled35 == [settled34 EXCEPT !.feeCode = IF settled34.numberOfTasRestatementBitfields >= 8 /\ (settled34.tasRestatementBitfield8 # << >> /\ settled34.tasRestatementBitfield8[1] % 2 > 0) THEN (IF settled34.feeCode = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled34.feeCode) ELSE << >>]
        settled36 == [settled35 EXCEPT !.stopPx = IF settled35.numberOfTasRestatementBitfields >= 8 /\ (settled35.tasRestatementBitfield8 # << >> /\ (settled35.tasRestatementBitfield8[1] \div 4) % 2 > 0) THEN (IF settled35.stopPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled35.stopPx) ELSE << >>]
        settled37 == [settled36 EXCEPT !.cmtaNumber = IF settled36.numberOfTasRestatementBitfields >= 9 /\ (settled36.tasRestatementBitfield9 # << >> /\ (settled36.tasRestatementBitfield9[1] \div 32) % 2 > 0) THEN (IF settled36.cmtaNumber = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled36.cmtaNumber) ELSE << >>]
        settled38 == [settled37 EXCEPT !.ctiCode = IF settled37.numberOfTasRestatementBitfields >= 12 /\ (settled37.tasRestatementBitfield12 # << >> /\ settled37.tasRestatementBitfield12[1] % 2 > 0) THEN (IF settled37.ctiCode = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled37.ctiCode) ELSE << >>]
        settled39 == [settled38 EXCEPT !.manualOrderIndicator = IF settled38.numberOfTasRestatementBitfields >= 12 /\ (settled38.tasRestatementBitfield12 # << >> /\ (settled38.tasRestatementBitfield12[1] \div 2) % 2 > 0) THEN (IF settled38.manualOrderIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled38.manualOrderIndicator) ELSE << >>]
        settled40 == [settled39 EXCEPT !.oeoid = IF settled39.numberOfTasRestatementBitfields >= 12 /\ (settled39.tasRestatementBitfield12 # << >> /\ (settled39.tasRestatementBitfield12[1] \div 4) % 2 > 0) THEN (IF settled39.oeoid = << >> THEN <<[i \in 1 .. 18 |-> 0]>> ELSE settled39.oeoid) ELSE << >>]
        settled41 == [settled40 EXCEPT !.tradeDate = IF settled40.numberOfTasRestatementBitfields >= 12 /\ (settled40.tasRestatementBitfield12 # << >> /\ (settled40.tasRestatementBitfield12[1] \div 8) % 2 > 0) THEN (IF settled40.tradeDate = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled40.tradeDate) ELSE << >>]
        settled42 == [settled41 EXCEPT !.clearingPrice = IF settled41.numberOfTasRestatementBitfields >= 12 /\ (settled41.tasRestatementBitfield12 # << >> /\ (settled41.tasRestatementBitfield12[1] \div 16) % 2 > 0) THEN (IF settled41.clearingPrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled41.clearingPrice) ELSE << >>]
        settled43 == [settled42 EXCEPT !.clearingSymbol = IF settled42.numberOfTasRestatementBitfields >= 12 /\ (settled42.tasRestatementBitfield12 # << >> /\ (settled42.tasRestatementBitfield12[1] \div 64) % 2 > 0) THEN (IF settled42.clearingSymbol = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled42.clearingSymbol) ELSE << >>]
        settled44 == [settled43 EXCEPT !.multilegReportingType = IF settled43.numberOfTasRestatementBitfields >= 13 /\ (settled43.tasRestatementBitfield13 # << >> /\ (settled43.tasRestatementBitfield13[1] \div 128) % 2 > 0) THEN (IF settled43.multilegReportingType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled43.multilegReportingType) ELSE << >>]
        settled45 == [settled44 EXCEPT !.secondaryExecId = IF settled44.numberOfTasRestatementBitfields >= 14 /\ (settled44.tasRestatementBitfield14 # << >> /\ (settled44.tasRestatementBitfield14[1] \div 16) % 2 > 0) THEN (IF settled44.secondaryExecId = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled44.secondaryExecId) ELSE << >>]
        settled46 == [settled45 EXCEPT !.frequentTraderId = IF settled45.numberOfTasRestatementBitfields >= 16 /\ (settled45.tasRestatementBitfield16 # << >> /\ settled45.tasRestatementBitfield16[1] % 2 > 0) THEN (IF settled45.frequentTraderId = << >> THEN <<[i \in 1 .. 6 |-> 0]>> ELSE settled45.frequentTraderId) ELSE << >>]
        settled47 == [settled46 EXCEPT !.custOrderHandlingInst = IF settled46.numberOfTasRestatementBitfields >= 17 /\ (settled46.tasRestatementBitfield17 # << >> /\ (settled46.tasRestatementBitfield17[1] \div 128) % 2 > 0) THEN (IF settled46.custOrderHandlingInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled46.custOrderHandlingInst) ELSE << >>]
    IN  settled47

ZeroTasRestatementNewOrderMessageMessage ==
    SettleTasRestatementNewOrderMessageMessage([ transactionTime                 |-> [i \in 1 .. 8 |-> 0],
                                                 clOrdId                         |-> [i \in 1 .. 20 |-> 0],
                                                 execId                          |-> [i \in 1 .. 8 |-> 0],
                                                 reserved1                       |-> [i \in 1 .. 1 |-> 0],
                                                 numberOfTasRestatementBitfields |-> 0,
                                                 tasRestatementBitfield1         |-> << >>,
                                                 tasRestatementBitfield2         |-> << >>,
                                                 tasRestatementBitfield3         |-> << >>,
                                                 tasRestatementBitfield4         |-> << >>,
                                                 tasRestatementBitfield5         |-> << >>,
                                                 tasRestatementBitfield6         |-> << >>,
                                                 tasRestatementBitfield7         |-> << >>,
                                                 tasRestatementBitfield8         |-> << >>,
                                                 tasRestatementBitfield9         |-> << >>,
                                                 tasRestatementBitfield10        |-> << >>,
                                                 tasRestatementBitfield11        |-> << >>,
                                                 tasRestatementBitfield12        |-> << >>,
                                                 tasRestatementBitfield13        |-> << >>,
                                                 tasRestatementBitfield14        |-> << >>,
                                                 tasRestatementBitfield15        |-> << >>,
                                                 tasRestatementBitfield16        |-> << >>,
                                                 tasRestatementBitfield17        |-> << >>,
                                                 tasRestatementBitfield18        |-> << >>,
                                                 side                            |-> << >>,
                                                 price                           |-> << >>,
                                                 ordType                         |-> << >>,
                                                 timeInForce                     |-> << >>,
                                                 minQty                          |-> << >>,
                                                 symbolLong                      |-> << >>,
                                                 capacity                        |-> << >>,
                                                 account                         |-> << >>,
                                                 clearingFirm                    |-> << >>,
                                                 clearingAccount                 |-> << >>,
                                                 preventMatch                    |-> << >>,
                                                 maturityDate                    |-> << >>,
                                                 openClose                       |-> << >>,
                                                 origClOrdId                     |-> << >>,
                                                 lastShares                      |-> << >>,
                                                 lastPx                          |-> << >>,
                                                 feeCode                         |-> << >>,
                                                 stopPx                          |-> << >>,
                                                 cmtaNumber                      |-> << >>,
                                                 ctiCode                         |-> << >>,
                                                 manualOrderIndicator            |-> << >>,
                                                 oeoid                           |-> << >>,
                                                 tradeDate                       |-> << >>,
                                                 clearingPrice                   |-> << >>,
                                                 clearingSymbol                  |-> << >>,
                                                 multilegReportingType           |-> << >>,
                                                 secondaryExecId                 |-> << >>,
                                                 frequentTraderId                |-> << >>,
                                                 custOrderHandlingInst           |-> << >> ])

(* Tas Restatement New Order Message Message at zero, then each field in turn at the values it is checked at *)
CheckedTasRestatementNewOrderMessageMessage ==
    { ZeroTasRestatementNewOrderMessageMessage }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.transactionTime = one]) : one \in Sample(8) }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.clOrdId = one]) : one \in Sample(20) }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.execId = one]) : one \in Sample(8) }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.reserved1 = one]) : one \in Sample(1) }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = 1, !.tasRestatementBitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = 2, !.tasRestatementBitfield2 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = 3, !.tasRestatementBitfield3 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = 4, !.tasRestatementBitfield4 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = 5, !.tasRestatementBitfield5 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = 6, !.tasRestatementBitfield6 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = 7, !.tasRestatementBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = 8, !.tasRestatementBitfield8 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = 9, !.tasRestatementBitfield9 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = 10, !.tasRestatementBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = 11, !.tasRestatementBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = 12, !.tasRestatementBitfield12 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = 13, !.tasRestatementBitfield13 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = 14, !.tasRestatementBitfield14 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = 15, !.tasRestatementBitfield15 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = 16, !.tasRestatementBitfield16 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = 17, !.tasRestatementBitfield17 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = 18, !.tasRestatementBitfield18 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = 1, !.tasRestatementBitfield1 = <<1>>, !.side = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = 1, !.tasRestatementBitfield1 = <<4>>, !.price = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = 1, !.tasRestatementBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = 1, !.tasRestatementBitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = 1, !.tasRestatementBitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = 2, !.tasRestatementBitfield2 = <<1>>, !.symbolLong = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = 2, !.tasRestatementBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = 3, !.tasRestatementBitfield3 = <<1>>, !.account = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = 3, !.tasRestatementBitfield3 = <<2>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = 3, !.tasRestatementBitfield3 = <<4>>, !.clearingAccount = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = 3, !.tasRestatementBitfield3 = <<128>>, !.preventMatch = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = 4, !.tasRestatementBitfield4 = <<1>>, !.maturityDate = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = 4, !.tasRestatementBitfield4 = <<8>>, !.openClose = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = 5, !.tasRestatementBitfield5 = <<1>>, !.origClOrdId = one]) : one \in { <<held>> : held \in Sample(20) } }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = 5, !.tasRestatementBitfield5 = <<4>>, !.lastShares = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = 5, !.tasRestatementBitfield5 = <<8>>, !.lastPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = 8, !.tasRestatementBitfield8 = <<1>>, !.feeCode = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = 8, !.tasRestatementBitfield8 = <<4>>, !.stopPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = 9, !.tasRestatementBitfield9 = <<32>>, !.cmtaNumber = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = 12, !.tasRestatementBitfield12 = <<1>>, !.ctiCode = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = 12, !.tasRestatementBitfield12 = <<2>>, !.manualOrderIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = 12, !.tasRestatementBitfield12 = <<4>>, !.oeoid = one]) : one \in { <<held>> : held \in Sample(18) } }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = 12, !.tasRestatementBitfield12 = <<8>>, !.tradeDate = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = 12, !.tasRestatementBitfield12 = <<16>>, !.clearingPrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = 12, !.tasRestatementBitfield12 = <<64>>, !.clearingSymbol = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = 13, !.tasRestatementBitfield13 = <<128>>, !.multilegReportingType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = 14, !.tasRestatementBitfield14 = <<16>>, !.secondaryExecId = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = 16, !.tasRestatementBitfield16 = <<1>>, !.frequentTraderId = one]) : one \in { <<held>> : held \in Sample(6) } }
        \cup { SettleTasRestatementNewOrderMessageMessage([ZeroTasRestatementNewOrderMessageMessage EXCEPT !.numberOfTasRestatementBitfields = 17, !.tasRestatementBitfield17 = <<128>>, !.custOrderHandlingInst = one]) : one \in { <<held>> : held \in Sample(1) } }

(***************************************************************************)
(* Variance Restatement New Order Message Message                          *)
(***************************************************************************)

VarianceRestatementNewOrderMessageMessage ==
    [ transactionTime                      : Sample(8),
      clOrdId                              : Sample(20),
      execId                               : Sample(8),
      reserved1                            : Sample(1),
      numberOfVarianceRestatementBitfields : 0 .. 255,
      varianceRestatementBitfield1         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      varianceRestatementBitfield2         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      varianceRestatementBitfield3         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      varianceRestatementBitfield4         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      varianceRestatementBitfield5         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      varianceRestatementBitfield6         : { << >> } \cup { <<held>> : held \in Sample(1) },
      varianceRestatementBitfield7         : { << >> } \cup { <<held>> : held \in Sample(1) },
      varianceRestatementBitfield8         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      varianceRestatementBitfield9         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      varianceRestatementBitfield10        : { << >> } \cup { <<held>> : held \in Sample(1) },
      varianceRestatementBitfield11        : { << >> } \cup { <<held>> : held \in Sample(1) },
      varianceRestatementBitfield12        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      varianceRestatementBitfield13        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      varianceRestatementBitfield14        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      varianceRestatementBitfield15        : { << >> } \cup { <<held>> : held \in Sample(1) },
      varianceRestatementBitfield16        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      varianceRestatementBitfield17        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      varianceRestatementBitfield18        : { << >> } \cup { <<held>> : held \in Sample(1) },
      side                                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      price                                : { << >> } \cup { <<held>> : held \in Sample(8) },
      ordType                              : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce                          : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                               : { << >> } \cup { <<held>> : held \in Sample(4) },
      symbolLong                           : { << >> } \cup { <<held>> : held \in Sample(8) },
      capacity                             : { << >> } \cup { <<held>> : held \in Sample(1) },
      account                              : { << >> } \cup { <<held>> : held \in Sample(16) },
      clearingFirm                         : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingAccount                      : { << >> } \cup { <<held>> : held \in Sample(4) },
      preventParticipantMatch              : { << >> } \cup { <<held>> : held \in Sample(3) },
      maturityDate                         : { << >> } \cup { <<held>> : held \in Sample(4) },
      openClose                            : { << >> } \cup { <<held>> : held \in Sample(1) },
      origClOrdId                          : { << >> } \cup { <<held>> : held \in Sample(20) },
      lastShares                           : { << >> } \cup { <<held>> : held \in Sample(4) },
      lastPx                               : { << >> } \cup { <<held>> : held \in Sample(8) },
      feeCode                              : { << >> } \cup { <<held>> : held \in Sample(2) },
      stopPx                               : { << >> } \cup { <<held>> : held \in Sample(8) },
      cmtaNumber                           : { << >> } \cup { <<held>> : held \in Sample(4) },
      ctiCode                              : { << >> } \cup { <<held>> : held \in Sample(1) },
      manualOrderIndicator                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      oeoid                                : { << >> } \cup { <<held>> : held \in Sample(18) },
      tradeDate                            : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingPrice                        : { << >> } \cup { <<held>> : held \in Sample(8) },
      clearingSize                         : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingSymbol                       : { << >> } \cup { <<held>> : held \in Sample(8) },
      multilegReportingType                : { << >> } \cup { <<held>> : held \in Sample(1) },
      secondaryExecId                      : { << >> } \cup { <<held>> : held \in Sample(8) },
      frequentTraderId                     : { << >> } \cup { <<held>> : held \in Sample(6) },
      custOrderHandlingInst                : { << >> } \cup { <<held>> : held \in Sample(1) } ]

EncodeVarianceRestatementNewOrderMessageMessage(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.execId
        \o message.reserved1
        \o EncodeUIntBE(message.numberOfVarianceRestatementBitfields, 1)
        \o (IF message.varianceRestatementBitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.varianceRestatementBitfield1[1], 1))
        \o (IF message.varianceRestatementBitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.varianceRestatementBitfield2[1], 1))
        \o (IF message.varianceRestatementBitfield3 = << >> THEN << >> ELSE EncodeUIntLE(message.varianceRestatementBitfield3[1], 1))
        \o (IF message.varianceRestatementBitfield4 = << >> THEN << >> ELSE EncodeUIntLE(message.varianceRestatementBitfield4[1], 1))
        \o (IF message.varianceRestatementBitfield5 = << >> THEN << >> ELSE EncodeUIntLE(message.varianceRestatementBitfield5[1], 1))
        \o (IF message.varianceRestatementBitfield6 = << >> THEN << >> ELSE message.varianceRestatementBitfield6[1])
        \o (IF message.varianceRestatementBitfield7 = << >> THEN << >> ELSE message.varianceRestatementBitfield7[1])
        \o (IF message.varianceRestatementBitfield8 = << >> THEN << >> ELSE EncodeUIntLE(message.varianceRestatementBitfield8[1], 1))
        \o (IF message.varianceRestatementBitfield9 = << >> THEN << >> ELSE EncodeUIntLE(message.varianceRestatementBitfield9[1], 1))
        \o (IF message.varianceRestatementBitfield10 = << >> THEN << >> ELSE message.varianceRestatementBitfield10[1])
        \o (IF message.varianceRestatementBitfield11 = << >> THEN << >> ELSE message.varianceRestatementBitfield11[1])
        \o (IF message.varianceRestatementBitfield12 = << >> THEN << >> ELSE EncodeUIntLE(message.varianceRestatementBitfield12[1], 1))
        \o (IF message.varianceRestatementBitfield13 = << >> THEN << >> ELSE EncodeUIntLE(message.varianceRestatementBitfield13[1], 1))
        \o (IF message.varianceRestatementBitfield14 = << >> THEN << >> ELSE EncodeUIntLE(message.varianceRestatementBitfield14[1], 1))
        \o (IF message.varianceRestatementBitfield15 = << >> THEN << >> ELSE message.varianceRestatementBitfield15[1])
        \o (IF message.varianceRestatementBitfield16 = << >> THEN << >> ELSE EncodeUIntLE(message.varianceRestatementBitfield16[1], 1))
        \o (IF message.varianceRestatementBitfield17 = << >> THEN << >> ELSE EncodeUIntLE(message.varianceRestatementBitfield17[1], 1))
        \o (IF message.varianceRestatementBitfield18 = << >> THEN << >> ELSE message.varianceRestatementBitfield18[1])
        \o (IF message.side = << >> THEN << >> ELSE message.side[1])
        \o (IF message.price = << >> THEN << >> ELSE message.price[1])
        \o (IF message.ordType = << >> THEN << >> ELSE message.ordType[1])
        \o (IF message.timeInForce = << >> THEN << >> ELSE message.timeInForce[1])
        \o (IF message.minQty = << >> THEN << >> ELSE message.minQty[1])
        \o (IF message.symbolLong = << >> THEN << >> ELSE message.symbolLong[1])
        \o (IF message.capacity = << >> THEN << >> ELSE message.capacity[1])
        \o (IF message.account = << >> THEN << >> ELSE message.account[1])
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])
        \o (IF message.clearingAccount = << >> THEN << >> ELSE message.clearingAccount[1])
        \o (IF message.preventParticipantMatch = << >> THEN << >> ELSE message.preventParticipantMatch[1])
        \o (IF message.maturityDate = << >> THEN << >> ELSE message.maturityDate[1])
        \o (IF message.openClose = << >> THEN << >> ELSE message.openClose[1])
        \o (IF message.origClOrdId = << >> THEN << >> ELSE message.origClOrdId[1])
        \o (IF message.lastShares = << >> THEN << >> ELSE message.lastShares[1])
        \o (IF message.lastPx = << >> THEN << >> ELSE message.lastPx[1])
        \o (IF message.feeCode = << >> THEN << >> ELSE message.feeCode[1])
        \o (IF message.stopPx = << >> THEN << >> ELSE message.stopPx[1])
        \o (IF message.cmtaNumber = << >> THEN << >> ELSE message.cmtaNumber[1])
        \o (IF message.ctiCode = << >> THEN << >> ELSE message.ctiCode[1])
        \o (IF message.manualOrderIndicator = << >> THEN << >> ELSE message.manualOrderIndicator[1])
        \o (IF message.oeoid = << >> THEN << >> ELSE message.oeoid[1])
        \o (IF message.tradeDate = << >> THEN << >> ELSE message.tradeDate[1])
        \o (IF message.clearingPrice = << >> THEN << >> ELSE message.clearingPrice[1])
        \o (IF message.clearingSize = << >> THEN << >> ELSE message.clearingSize[1])
        \o (IF message.clearingSymbol = << >> THEN << >> ELSE message.clearingSymbol[1])
        \o (IF message.multilegReportingType = << >> THEN << >> ELSE message.multilegReportingType[1])
        \o (IF message.secondaryExecId = << >> THEN << >> ELSE message.secondaryExecId[1])
        \o (IF message.frequentTraderId = << >> THEN << >> ELSE message.frequentTraderId[1])
        \o (IF message.custOrderHandlingInst = << >> THEN << >> ELSE message.custOrderHandlingInst[1])

DecodeVarianceRestatementNewOrderMessageMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET execId == ReadBytes(clOrdId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(execId.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET numberOfVarianceRestatementBitfields == ReadUIntBE(reserved1.rest, 1) IN IF ~numberOfVarianceRestatementBitfields.ok THEN Fail ELSE
    LET varianceRestatementBitfield1 == ReadWhen(numberOfVarianceRestatementBitfields.value >= 1, ReadUIntLE(numberOfVarianceRestatementBitfields.rest, 1), numberOfVarianceRestatementBitfields.rest) IN IF ~varianceRestatementBitfield1.ok THEN Fail ELSE
    LET varianceRestatementBitfield2 == ReadWhen(numberOfVarianceRestatementBitfields.value >= 2, ReadUIntLE(varianceRestatementBitfield1.rest, 1), varianceRestatementBitfield1.rest) IN IF ~varianceRestatementBitfield2.ok THEN Fail ELSE
    LET varianceRestatementBitfield3 == ReadWhen(numberOfVarianceRestatementBitfields.value >= 3, ReadUIntLE(varianceRestatementBitfield2.rest, 1), varianceRestatementBitfield2.rest) IN IF ~varianceRestatementBitfield3.ok THEN Fail ELSE
    LET varianceRestatementBitfield4 == ReadWhen(numberOfVarianceRestatementBitfields.value >= 4, ReadUIntLE(varianceRestatementBitfield3.rest, 1), varianceRestatementBitfield3.rest) IN IF ~varianceRestatementBitfield4.ok THEN Fail ELSE
    LET varianceRestatementBitfield5 == ReadWhen(numberOfVarianceRestatementBitfields.value >= 5, ReadUIntLE(varianceRestatementBitfield4.rest, 1), varianceRestatementBitfield4.rest) IN IF ~varianceRestatementBitfield5.ok THEN Fail ELSE
    LET varianceRestatementBitfield6 == ReadWhen(numberOfVarianceRestatementBitfields.value >= 6, ReadBytes(varianceRestatementBitfield5.rest, 1), varianceRestatementBitfield5.rest) IN IF ~varianceRestatementBitfield6.ok THEN Fail ELSE
    LET varianceRestatementBitfield7 == ReadWhen(numberOfVarianceRestatementBitfields.value >= 7, ReadBytes(varianceRestatementBitfield6.rest, 1), varianceRestatementBitfield6.rest) IN IF ~varianceRestatementBitfield7.ok THEN Fail ELSE
    LET varianceRestatementBitfield8 == ReadWhen(numberOfVarianceRestatementBitfields.value >= 8, ReadUIntLE(varianceRestatementBitfield7.rest, 1), varianceRestatementBitfield7.rest) IN IF ~varianceRestatementBitfield8.ok THEN Fail ELSE
    LET varianceRestatementBitfield9 == ReadWhen(numberOfVarianceRestatementBitfields.value >= 9, ReadUIntLE(varianceRestatementBitfield8.rest, 1), varianceRestatementBitfield8.rest) IN IF ~varianceRestatementBitfield9.ok THEN Fail ELSE
    LET varianceRestatementBitfield10 == ReadWhen(numberOfVarianceRestatementBitfields.value >= 10, ReadBytes(varianceRestatementBitfield9.rest, 1), varianceRestatementBitfield9.rest) IN IF ~varianceRestatementBitfield10.ok THEN Fail ELSE
    LET varianceRestatementBitfield11 == ReadWhen(numberOfVarianceRestatementBitfields.value >= 11, ReadBytes(varianceRestatementBitfield10.rest, 1), varianceRestatementBitfield10.rest) IN IF ~varianceRestatementBitfield11.ok THEN Fail ELSE
    LET varianceRestatementBitfield12 == ReadWhen(numberOfVarianceRestatementBitfields.value >= 12, ReadUIntLE(varianceRestatementBitfield11.rest, 1), varianceRestatementBitfield11.rest) IN IF ~varianceRestatementBitfield12.ok THEN Fail ELSE
    LET varianceRestatementBitfield13 == ReadWhen(numberOfVarianceRestatementBitfields.value >= 13, ReadUIntLE(varianceRestatementBitfield12.rest, 1), varianceRestatementBitfield12.rest) IN IF ~varianceRestatementBitfield13.ok THEN Fail ELSE
    LET varianceRestatementBitfield14 == ReadWhen(numberOfVarianceRestatementBitfields.value >= 14, ReadUIntLE(varianceRestatementBitfield13.rest, 1), varianceRestatementBitfield13.rest) IN IF ~varianceRestatementBitfield14.ok THEN Fail ELSE
    LET varianceRestatementBitfield15 == ReadWhen(numberOfVarianceRestatementBitfields.value >= 15, ReadBytes(varianceRestatementBitfield14.rest, 1), varianceRestatementBitfield14.rest) IN IF ~varianceRestatementBitfield15.ok THEN Fail ELSE
    LET varianceRestatementBitfield16 == ReadWhen(numberOfVarianceRestatementBitfields.value >= 16, ReadUIntLE(varianceRestatementBitfield15.rest, 1), varianceRestatementBitfield15.rest) IN IF ~varianceRestatementBitfield16.ok THEN Fail ELSE
    LET varianceRestatementBitfield17 == ReadWhen(numberOfVarianceRestatementBitfields.value >= 17, ReadUIntLE(varianceRestatementBitfield16.rest, 1), varianceRestatementBitfield16.rest) IN IF ~varianceRestatementBitfield17.ok THEN Fail ELSE
    LET varianceRestatementBitfield18 == ReadWhen(numberOfVarianceRestatementBitfields.value >= 18, ReadBytes(varianceRestatementBitfield17.rest, 1), varianceRestatementBitfield17.rest) IN IF ~varianceRestatementBitfield18.ok THEN Fail ELSE
    LET side == ReadWhen(numberOfVarianceRestatementBitfields.value >= 1 /\ (varianceRestatementBitfield1.value # << >> /\ varianceRestatementBitfield1.value[1] % 2 > 0), ReadBytes(varianceRestatementBitfield18.rest, 1), varianceRestatementBitfield18.rest) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadWhen(numberOfVarianceRestatementBitfields.value >= 1 /\ (varianceRestatementBitfield1.value # << >> /\ (varianceRestatementBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(side.rest, 8), side.rest) IN IF ~price.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfVarianceRestatementBitfields.value >= 1 /\ (varianceRestatementBitfield1.value # << >> /\ (varianceRestatementBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(price.rest, 1), price.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfVarianceRestatementBitfields.value >= 1 /\ (varianceRestatementBitfield1.value # << >> /\ (varianceRestatementBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfVarianceRestatementBitfields.value >= 1 /\ (varianceRestatementBitfield1.value # << >> /\ (varianceRestatementBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET symbolLong == ReadWhen(numberOfVarianceRestatementBitfields.value >= 2 /\ (varianceRestatementBitfield2.value # << >> /\ varianceRestatementBitfield2.value[1] % 2 > 0), ReadBytes(minQty.rest, 8), minQty.rest) IN IF ~symbolLong.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfVarianceRestatementBitfields.value >= 2 /\ (varianceRestatementBitfield2.value # << >> /\ (varianceRestatementBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(symbolLong.rest, 1), symbolLong.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadWhen(numberOfVarianceRestatementBitfields.value >= 3 /\ (varianceRestatementBitfield3.value # << >> /\ varianceRestatementBitfield3.value[1] % 2 > 0), ReadBytes(capacity.rest, 16), capacity.rest) IN IF ~account.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfVarianceRestatementBitfields.value >= 3 /\ (varianceRestatementBitfield3.value # << >> /\ (varianceRestatementBitfield3.value[1] \div 2) % 2 > 0), ReadBytes(account.rest, 4), account.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadWhen(numberOfVarianceRestatementBitfields.value >= 3 /\ (varianceRestatementBitfield3.value # << >> /\ (varianceRestatementBitfield3.value[1] \div 4) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET preventParticipantMatch == ReadWhen(numberOfVarianceRestatementBitfields.value >= 3 /\ (varianceRestatementBitfield3.value # << >> /\ (varianceRestatementBitfield3.value[1] \div 128) % 2 > 0), ReadBytes(clearingAccount.rest, 3), clearingAccount.rest) IN IF ~preventParticipantMatch.ok THEN Fail ELSE
    LET maturityDate == ReadWhen(numberOfVarianceRestatementBitfields.value >= 4 /\ (varianceRestatementBitfield4.value # << >> /\ varianceRestatementBitfield4.value[1] % 2 > 0), ReadBytes(preventParticipantMatch.rest, 4), preventParticipantMatch.rest) IN IF ~maturityDate.ok THEN Fail ELSE
    LET openClose == ReadWhen(numberOfVarianceRestatementBitfields.value >= 4 /\ (varianceRestatementBitfield4.value # << >> /\ (varianceRestatementBitfield4.value[1] \div 8) % 2 > 0), ReadBytes(maturityDate.rest, 1), maturityDate.rest) IN IF ~openClose.ok THEN Fail ELSE
    LET origClOrdId == ReadWhen(numberOfVarianceRestatementBitfields.value >= 5 /\ (varianceRestatementBitfield5.value # << >> /\ varianceRestatementBitfield5.value[1] % 2 > 0), ReadBytes(openClose.rest, 20), openClose.rest) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET lastShares == ReadWhen(numberOfVarianceRestatementBitfields.value >= 5 /\ (varianceRestatementBitfield5.value # << >> /\ (varianceRestatementBitfield5.value[1] \div 4) % 2 > 0), ReadBytes(origClOrdId.rest, 4), origClOrdId.rest) IN IF ~lastShares.ok THEN Fail ELSE
    LET lastPx == ReadWhen(numberOfVarianceRestatementBitfields.value >= 5 /\ (varianceRestatementBitfield5.value # << >> /\ (varianceRestatementBitfield5.value[1] \div 8) % 2 > 0), ReadBytes(lastShares.rest, 8), lastShares.rest) IN IF ~lastPx.ok THEN Fail ELSE
    LET feeCode == ReadWhen(numberOfVarianceRestatementBitfields.value >= 8 /\ (varianceRestatementBitfield8.value # << >> /\ varianceRestatementBitfield8.value[1] % 2 > 0), ReadBytes(lastPx.rest, 2), lastPx.rest) IN IF ~feeCode.ok THEN Fail ELSE
    LET stopPx == ReadWhen(numberOfVarianceRestatementBitfields.value >= 8 /\ (varianceRestatementBitfield8.value # << >> /\ (varianceRestatementBitfield8.value[1] \div 4) % 2 > 0), ReadBytes(feeCode.rest, 8), feeCode.rest) IN IF ~stopPx.ok THEN Fail ELSE
    LET cmtaNumber == ReadWhen(numberOfVarianceRestatementBitfields.value >= 9 /\ (varianceRestatementBitfield9.value # << >> /\ (varianceRestatementBitfield9.value[1] \div 32) % 2 > 0), ReadBytes(stopPx.rest, 4), stopPx.rest) IN IF ~cmtaNumber.ok THEN Fail ELSE
    LET ctiCode == ReadWhen(numberOfVarianceRestatementBitfields.value >= 12 /\ (varianceRestatementBitfield12.value # << >> /\ varianceRestatementBitfield12.value[1] % 2 > 0), ReadBytes(cmtaNumber.rest, 1), cmtaNumber.rest) IN IF ~ctiCode.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadWhen(numberOfVarianceRestatementBitfields.value >= 12 /\ (varianceRestatementBitfield12.value # << >> /\ (varianceRestatementBitfield12.value[1] \div 2) % 2 > 0), ReadBytes(ctiCode.rest, 1), ctiCode.rest) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET oeoid == ReadWhen(numberOfVarianceRestatementBitfields.value >= 12 /\ (varianceRestatementBitfield12.value # << >> /\ (varianceRestatementBitfield12.value[1] \div 4) % 2 > 0), ReadBytes(manualOrderIndicator.rest, 18), manualOrderIndicator.rest) IN IF ~oeoid.ok THEN Fail ELSE
    LET tradeDate == ReadWhen(numberOfVarianceRestatementBitfields.value >= 12 /\ (varianceRestatementBitfield12.value # << >> /\ (varianceRestatementBitfield12.value[1] \div 8) % 2 > 0), ReadBytes(oeoid.rest, 4), oeoid.rest) IN IF ~tradeDate.ok THEN Fail ELSE
    LET clearingPrice == ReadWhen(numberOfVarianceRestatementBitfields.value >= 12 /\ (varianceRestatementBitfield12.value # << >> /\ (varianceRestatementBitfield12.value[1] \div 16) % 2 > 0), ReadBytes(tradeDate.rest, 8), tradeDate.rest) IN IF ~clearingPrice.ok THEN Fail ELSE
    LET clearingSize == ReadWhen(numberOfVarianceRestatementBitfields.value >= 12 /\ (varianceRestatementBitfield12.value # << >> /\ (varianceRestatementBitfield12.value[1] \div 32) % 2 > 0), ReadBytes(clearingPrice.rest, 4), clearingPrice.rest) IN IF ~clearingSize.ok THEN Fail ELSE
    LET clearingSymbol == ReadWhen(numberOfVarianceRestatementBitfields.value >= 12 /\ (varianceRestatementBitfield12.value # << >> /\ (varianceRestatementBitfield12.value[1] \div 64) % 2 > 0), ReadBytes(clearingSize.rest, 8), clearingSize.rest) IN IF ~clearingSymbol.ok THEN Fail ELSE
    LET multilegReportingType == ReadWhen(numberOfVarianceRestatementBitfields.value >= 13 /\ (varianceRestatementBitfield13.value # << >> /\ (varianceRestatementBitfield13.value[1] \div 128) % 2 > 0), ReadBytes(clearingSymbol.rest, 1), clearingSymbol.rest) IN IF ~multilegReportingType.ok THEN Fail ELSE
    LET secondaryExecId == ReadWhen(numberOfVarianceRestatementBitfields.value >= 14 /\ (varianceRestatementBitfield14.value # << >> /\ (varianceRestatementBitfield14.value[1] \div 16) % 2 > 0), ReadBytes(multilegReportingType.rest, 8), multilegReportingType.rest) IN IF ~secondaryExecId.ok THEN Fail ELSE
    LET frequentTraderId == ReadWhen(numberOfVarianceRestatementBitfields.value >= 16 /\ (varianceRestatementBitfield16.value # << >> /\ varianceRestatementBitfield16.value[1] % 2 > 0), ReadBytes(secondaryExecId.rest, 6), secondaryExecId.rest) IN IF ~frequentTraderId.ok THEN Fail ELSE
    LET custOrderHandlingInst == ReadWhen(numberOfVarianceRestatementBitfields.value >= 17 /\ (varianceRestatementBitfield17.value # << >> /\ (varianceRestatementBitfield17.value[1] \div 128) % 2 > 0), ReadBytes(frequentTraderId.rest, 1), frequentTraderId.rest) IN IF ~custOrderHandlingInst.ok THEN Fail ELSE
    Ok([ transactionTime                      |-> transactionTime.value,
         clOrdId                              |-> clOrdId.value,
         execId                               |-> execId.value,
         reserved1                            |-> reserved1.value,
         numberOfVarianceRestatementBitfields |-> numberOfVarianceRestatementBitfields.value,
         varianceRestatementBitfield1         |-> varianceRestatementBitfield1.value,
         varianceRestatementBitfield2         |-> varianceRestatementBitfield2.value,
         varianceRestatementBitfield3         |-> varianceRestatementBitfield3.value,
         varianceRestatementBitfield4         |-> varianceRestatementBitfield4.value,
         varianceRestatementBitfield5         |-> varianceRestatementBitfield5.value,
         varianceRestatementBitfield6         |-> varianceRestatementBitfield6.value,
         varianceRestatementBitfield7         |-> varianceRestatementBitfield7.value,
         varianceRestatementBitfield8         |-> varianceRestatementBitfield8.value,
         varianceRestatementBitfield9         |-> varianceRestatementBitfield9.value,
         varianceRestatementBitfield10        |-> varianceRestatementBitfield10.value,
         varianceRestatementBitfield11        |-> varianceRestatementBitfield11.value,
         varianceRestatementBitfield12        |-> varianceRestatementBitfield12.value,
         varianceRestatementBitfield13        |-> varianceRestatementBitfield13.value,
         varianceRestatementBitfield14        |-> varianceRestatementBitfield14.value,
         varianceRestatementBitfield15        |-> varianceRestatementBitfield15.value,
         varianceRestatementBitfield16        |-> varianceRestatementBitfield16.value,
         varianceRestatementBitfield17        |-> varianceRestatementBitfield17.value,
         varianceRestatementBitfield18        |-> varianceRestatementBitfield18.value,
         side                                 |-> side.value,
         price                                |-> price.value,
         ordType                              |-> ordType.value,
         timeInForce                          |-> timeInForce.value,
         minQty                               |-> minQty.value,
         symbolLong                           |-> symbolLong.value,
         capacity                             |-> capacity.value,
         account                              |-> account.value,
         clearingFirm                         |-> clearingFirm.value,
         clearingAccount                      |-> clearingAccount.value,
         preventParticipantMatch              |-> preventParticipantMatch.value,
         maturityDate                         |-> maturityDate.value,
         openClose                            |-> openClose.value,
         origClOrdId                          |-> origClOrdId.value,
         lastShares                           |-> lastShares.value,
         lastPx                               |-> lastPx.value,
         feeCode                              |-> feeCode.value,
         stopPx                               |-> stopPx.value,
         cmtaNumber                           |-> cmtaNumber.value,
         ctiCode                              |-> ctiCode.value,
         manualOrderIndicator                 |-> manualOrderIndicator.value,
         oeoid                                |-> oeoid.value,
         tradeDate                            |-> tradeDate.value,
         clearingPrice                        |-> clearingPrice.value,
         clearingSize                         |-> clearingSize.value,
         clearingSymbol                       |-> clearingSymbol.value,
         multilegReportingType                |-> multilegReportingType.value,
         secondaryExecId                      |-> secondaryExecId.value,
         frequentTraderId                     |-> frequentTraderId.value,
         custOrderHandlingInst                |-> custOrderHandlingInst.value ], custOrderHandlingInst.rest)

(* Variance Restatement New Order Message Message with each field marked present by fields before it there exactly where they say *)
SettleVarianceRestatementNewOrderMessageMessage(message) ==
    LET settled1 == [message EXCEPT !.varianceRestatementBitfield1 = IF message.numberOfVarianceRestatementBitfields >= 1 THEN (IF message.varianceRestatementBitfield1 = << >> THEN <<0>> ELSE message.varianceRestatementBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.varianceRestatementBitfield2 = IF settled1.numberOfVarianceRestatementBitfields >= 2 THEN (IF settled1.varianceRestatementBitfield2 = << >> THEN <<0>> ELSE settled1.varianceRestatementBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.varianceRestatementBitfield3 = IF settled2.numberOfVarianceRestatementBitfields >= 3 THEN (IF settled2.varianceRestatementBitfield3 = << >> THEN <<0>> ELSE settled2.varianceRestatementBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.varianceRestatementBitfield4 = IF settled3.numberOfVarianceRestatementBitfields >= 4 THEN (IF settled3.varianceRestatementBitfield4 = << >> THEN <<0>> ELSE settled3.varianceRestatementBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.varianceRestatementBitfield5 = IF settled4.numberOfVarianceRestatementBitfields >= 5 THEN (IF settled4.varianceRestatementBitfield5 = << >> THEN <<0>> ELSE settled4.varianceRestatementBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.varianceRestatementBitfield6 = IF settled5.numberOfVarianceRestatementBitfields >= 6 THEN (IF settled5.varianceRestatementBitfield6 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled5.varianceRestatementBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.varianceRestatementBitfield7 = IF settled6.numberOfVarianceRestatementBitfields >= 7 THEN (IF settled6.varianceRestatementBitfield7 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.varianceRestatementBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.varianceRestatementBitfield8 = IF settled7.numberOfVarianceRestatementBitfields >= 8 THEN (IF settled7.varianceRestatementBitfield8 = << >> THEN <<0>> ELSE settled7.varianceRestatementBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.varianceRestatementBitfield9 = IF settled8.numberOfVarianceRestatementBitfields >= 9 THEN (IF settled8.varianceRestatementBitfield9 = << >> THEN <<0>> ELSE settled8.varianceRestatementBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.varianceRestatementBitfield10 = IF settled9.numberOfVarianceRestatementBitfields >= 10 THEN (IF settled9.varianceRestatementBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.varianceRestatementBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.varianceRestatementBitfield11 = IF settled10.numberOfVarianceRestatementBitfields >= 11 THEN (IF settled10.varianceRestatementBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.varianceRestatementBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.varianceRestatementBitfield12 = IF settled11.numberOfVarianceRestatementBitfields >= 12 THEN (IF settled11.varianceRestatementBitfield12 = << >> THEN <<0>> ELSE settled11.varianceRestatementBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.varianceRestatementBitfield13 = IF settled12.numberOfVarianceRestatementBitfields >= 13 THEN (IF settled12.varianceRestatementBitfield13 = << >> THEN <<0>> ELSE settled12.varianceRestatementBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.varianceRestatementBitfield14 = IF settled13.numberOfVarianceRestatementBitfields >= 14 THEN (IF settled13.varianceRestatementBitfield14 = << >> THEN <<0>> ELSE settled13.varianceRestatementBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.varianceRestatementBitfield15 = IF settled14.numberOfVarianceRestatementBitfields >= 15 THEN (IF settled14.varianceRestatementBitfield15 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.varianceRestatementBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.varianceRestatementBitfield16 = IF settled15.numberOfVarianceRestatementBitfields >= 16 THEN (IF settled15.varianceRestatementBitfield16 = << >> THEN <<0>> ELSE settled15.varianceRestatementBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.varianceRestatementBitfield17 = IF settled16.numberOfVarianceRestatementBitfields >= 17 THEN (IF settled16.varianceRestatementBitfield17 = << >> THEN <<0>> ELSE settled16.varianceRestatementBitfield17) ELSE << >>]
        settled18 == [settled17 EXCEPT !.varianceRestatementBitfield18 = IF settled17.numberOfVarianceRestatementBitfields >= 18 THEN (IF settled17.varianceRestatementBitfield18 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.varianceRestatementBitfield18) ELSE << >>]
        settled19 == [settled18 EXCEPT !.side = IF settled18.numberOfVarianceRestatementBitfields >= 1 /\ (settled18.varianceRestatementBitfield1 # << >> /\ settled18.varianceRestatementBitfield1[1] % 2 > 0) THEN (IF settled18.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled18.side) ELSE << >>]
        settled20 == [settled19 EXCEPT !.price = IF settled19.numberOfVarianceRestatementBitfields >= 1 /\ (settled19.varianceRestatementBitfield1 # << >> /\ (settled19.varianceRestatementBitfield1[1] \div 4) % 2 > 0) THEN (IF settled19.price = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled19.price) ELSE << >>]
        settled21 == [settled20 EXCEPT !.ordType = IF settled20.numberOfVarianceRestatementBitfields >= 1 /\ (settled20.varianceRestatementBitfield1 # << >> /\ (settled20.varianceRestatementBitfield1[1] \div 16) % 2 > 0) THEN (IF settled20.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled20.ordType) ELSE << >>]
        settled22 == [settled21 EXCEPT !.timeInForce = IF settled21.numberOfVarianceRestatementBitfields >= 1 /\ (settled21.varianceRestatementBitfield1 # << >> /\ (settled21.varianceRestatementBitfield1[1] \div 32) % 2 > 0) THEN (IF settled21.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled21.timeInForce) ELSE << >>]
        settled23 == [settled22 EXCEPT !.minQty = IF settled22.numberOfVarianceRestatementBitfields >= 1 /\ (settled22.varianceRestatementBitfield1 # << >> /\ (settled22.varianceRestatementBitfield1[1] \div 64) % 2 > 0) THEN (IF settled22.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled22.minQty) ELSE << >>]
        settled24 == [settled23 EXCEPT !.symbolLong = IF settled23.numberOfVarianceRestatementBitfields >= 2 /\ (settled23.varianceRestatementBitfield2 # << >> /\ settled23.varianceRestatementBitfield2[1] % 2 > 0) THEN (IF settled23.symbolLong = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled23.symbolLong) ELSE << >>]
        settled25 == [settled24 EXCEPT !.capacity = IF settled24.numberOfVarianceRestatementBitfields >= 2 /\ (settled24.varianceRestatementBitfield2 # << >> /\ (settled24.varianceRestatementBitfield2[1] \div 64) % 2 > 0) THEN (IF settled24.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled24.capacity) ELSE << >>]
        settled26 == [settled25 EXCEPT !.account = IF settled25.numberOfVarianceRestatementBitfields >= 3 /\ (settled25.varianceRestatementBitfield3 # << >> /\ settled25.varianceRestatementBitfield3[1] % 2 > 0) THEN (IF settled25.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled25.account) ELSE << >>]
        settled27 == [settled26 EXCEPT !.clearingFirm = IF settled26.numberOfVarianceRestatementBitfields >= 3 /\ (settled26.varianceRestatementBitfield3 # << >> /\ (settled26.varianceRestatementBitfield3[1] \div 2) % 2 > 0) THEN (IF settled26.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled26.clearingFirm) ELSE << >>]
        settled28 == [settled27 EXCEPT !.clearingAccount = IF settled27.numberOfVarianceRestatementBitfields >= 3 /\ (settled27.varianceRestatementBitfield3 # << >> /\ (settled27.varianceRestatementBitfield3[1] \div 4) % 2 > 0) THEN (IF settled27.clearingAccount = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled27.clearingAccount) ELSE << >>]
        settled29 == [settled28 EXCEPT !.preventParticipantMatch = IF settled28.numberOfVarianceRestatementBitfields >= 3 /\ (settled28.varianceRestatementBitfield3 # << >> /\ (settled28.varianceRestatementBitfield3[1] \div 128) % 2 > 0) THEN (IF settled28.preventParticipantMatch = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled28.preventParticipantMatch) ELSE << >>]
        settled30 == [settled29 EXCEPT !.maturityDate = IF settled29.numberOfVarianceRestatementBitfields >= 4 /\ (settled29.varianceRestatementBitfield4 # << >> /\ settled29.varianceRestatementBitfield4[1] % 2 > 0) THEN (IF settled29.maturityDate = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled29.maturityDate) ELSE << >>]
        settled31 == [settled30 EXCEPT !.openClose = IF settled30.numberOfVarianceRestatementBitfields >= 4 /\ (settled30.varianceRestatementBitfield4 # << >> /\ (settled30.varianceRestatementBitfield4[1] \div 8) % 2 > 0) THEN (IF settled30.openClose = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled30.openClose) ELSE << >>]
        settled32 == [settled31 EXCEPT !.origClOrdId = IF settled31.numberOfVarianceRestatementBitfields >= 5 /\ (settled31.varianceRestatementBitfield5 # << >> /\ settled31.varianceRestatementBitfield5[1] % 2 > 0) THEN (IF settled31.origClOrdId = << >> THEN <<[i \in 1 .. 20 |-> 0]>> ELSE settled31.origClOrdId) ELSE << >>]
        settled33 == [settled32 EXCEPT !.lastShares = IF settled32.numberOfVarianceRestatementBitfields >= 5 /\ (settled32.varianceRestatementBitfield5 # << >> /\ (settled32.varianceRestatementBitfield5[1] \div 4) % 2 > 0) THEN (IF settled32.lastShares = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled32.lastShares) ELSE << >>]
        settled34 == [settled33 EXCEPT !.lastPx = IF settled33.numberOfVarianceRestatementBitfields >= 5 /\ (settled33.varianceRestatementBitfield5 # << >> /\ (settled33.varianceRestatementBitfield5[1] \div 8) % 2 > 0) THEN (IF settled33.lastPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled33.lastPx) ELSE << >>]
        settled35 == [settled34 EXCEPT !.feeCode = IF settled34.numberOfVarianceRestatementBitfields >= 8 /\ (settled34.varianceRestatementBitfield8 # << >> /\ settled34.varianceRestatementBitfield8[1] % 2 > 0) THEN (IF settled34.feeCode = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled34.feeCode) ELSE << >>]
        settled36 == [settled35 EXCEPT !.stopPx = IF settled35.numberOfVarianceRestatementBitfields >= 8 /\ (settled35.varianceRestatementBitfield8 # << >> /\ (settled35.varianceRestatementBitfield8[1] \div 4) % 2 > 0) THEN (IF settled35.stopPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled35.stopPx) ELSE << >>]
        settled37 == [settled36 EXCEPT !.cmtaNumber = IF settled36.numberOfVarianceRestatementBitfields >= 9 /\ (settled36.varianceRestatementBitfield9 # << >> /\ (settled36.varianceRestatementBitfield9[1] \div 32) % 2 > 0) THEN (IF settled36.cmtaNumber = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled36.cmtaNumber) ELSE << >>]
        settled38 == [settled37 EXCEPT !.ctiCode = IF settled37.numberOfVarianceRestatementBitfields >= 12 /\ (settled37.varianceRestatementBitfield12 # << >> /\ settled37.varianceRestatementBitfield12[1] % 2 > 0) THEN (IF settled37.ctiCode = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled37.ctiCode) ELSE << >>]
        settled39 == [settled38 EXCEPT !.manualOrderIndicator = IF settled38.numberOfVarianceRestatementBitfields >= 12 /\ (settled38.varianceRestatementBitfield12 # << >> /\ (settled38.varianceRestatementBitfield12[1] \div 2) % 2 > 0) THEN (IF settled38.manualOrderIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled38.manualOrderIndicator) ELSE << >>]
        settled40 == [settled39 EXCEPT !.oeoid = IF settled39.numberOfVarianceRestatementBitfields >= 12 /\ (settled39.varianceRestatementBitfield12 # << >> /\ (settled39.varianceRestatementBitfield12[1] \div 4) % 2 > 0) THEN (IF settled39.oeoid = << >> THEN <<[i \in 1 .. 18 |-> 0]>> ELSE settled39.oeoid) ELSE << >>]
        settled41 == [settled40 EXCEPT !.tradeDate = IF settled40.numberOfVarianceRestatementBitfields >= 12 /\ (settled40.varianceRestatementBitfield12 # << >> /\ (settled40.varianceRestatementBitfield12[1] \div 8) % 2 > 0) THEN (IF settled40.tradeDate = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled40.tradeDate) ELSE << >>]
        settled42 == [settled41 EXCEPT !.clearingPrice = IF settled41.numberOfVarianceRestatementBitfields >= 12 /\ (settled41.varianceRestatementBitfield12 # << >> /\ (settled41.varianceRestatementBitfield12[1] \div 16) % 2 > 0) THEN (IF settled41.clearingPrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled41.clearingPrice) ELSE << >>]
        settled43 == [settled42 EXCEPT !.clearingSize = IF settled42.numberOfVarianceRestatementBitfields >= 12 /\ (settled42.varianceRestatementBitfield12 # << >> /\ (settled42.varianceRestatementBitfield12[1] \div 32) % 2 > 0) THEN (IF settled42.clearingSize = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled42.clearingSize) ELSE << >>]
        settled44 == [settled43 EXCEPT !.clearingSymbol = IF settled43.numberOfVarianceRestatementBitfields >= 12 /\ (settled43.varianceRestatementBitfield12 # << >> /\ (settled43.varianceRestatementBitfield12[1] \div 64) % 2 > 0) THEN (IF settled43.clearingSymbol = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled43.clearingSymbol) ELSE << >>]
        settled45 == [settled44 EXCEPT !.multilegReportingType = IF settled44.numberOfVarianceRestatementBitfields >= 13 /\ (settled44.varianceRestatementBitfield13 # << >> /\ (settled44.varianceRestatementBitfield13[1] \div 128) % 2 > 0) THEN (IF settled44.multilegReportingType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled44.multilegReportingType) ELSE << >>]
        settled46 == [settled45 EXCEPT !.secondaryExecId = IF settled45.numberOfVarianceRestatementBitfields >= 14 /\ (settled45.varianceRestatementBitfield14 # << >> /\ (settled45.varianceRestatementBitfield14[1] \div 16) % 2 > 0) THEN (IF settled45.secondaryExecId = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled45.secondaryExecId) ELSE << >>]
        settled47 == [settled46 EXCEPT !.frequentTraderId = IF settled46.numberOfVarianceRestatementBitfields >= 16 /\ (settled46.varianceRestatementBitfield16 # << >> /\ settled46.varianceRestatementBitfield16[1] % 2 > 0) THEN (IF settled46.frequentTraderId = << >> THEN <<[i \in 1 .. 6 |-> 0]>> ELSE settled46.frequentTraderId) ELSE << >>]
        settled48 == [settled47 EXCEPT !.custOrderHandlingInst = IF settled47.numberOfVarianceRestatementBitfields >= 17 /\ (settled47.varianceRestatementBitfield17 # << >> /\ (settled47.varianceRestatementBitfield17[1] \div 128) % 2 > 0) THEN (IF settled47.custOrderHandlingInst = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled47.custOrderHandlingInst) ELSE << >>]
    IN  settled48

ZeroVarianceRestatementNewOrderMessageMessage ==
    SettleVarianceRestatementNewOrderMessageMessage([ transactionTime                      |-> [i \in 1 .. 8 |-> 0],
                                                      clOrdId                              |-> [i \in 1 .. 20 |-> 0],
                                                      execId                               |-> [i \in 1 .. 8 |-> 0],
                                                      reserved1                            |-> [i \in 1 .. 1 |-> 0],
                                                      numberOfVarianceRestatementBitfields |-> 0,
                                                      varianceRestatementBitfield1         |-> << >>,
                                                      varianceRestatementBitfield2         |-> << >>,
                                                      varianceRestatementBitfield3         |-> << >>,
                                                      varianceRestatementBitfield4         |-> << >>,
                                                      varianceRestatementBitfield5         |-> << >>,
                                                      varianceRestatementBitfield6         |-> << >>,
                                                      varianceRestatementBitfield7         |-> << >>,
                                                      varianceRestatementBitfield8         |-> << >>,
                                                      varianceRestatementBitfield9         |-> << >>,
                                                      varianceRestatementBitfield10        |-> << >>,
                                                      varianceRestatementBitfield11        |-> << >>,
                                                      varianceRestatementBitfield12        |-> << >>,
                                                      varianceRestatementBitfield13        |-> << >>,
                                                      varianceRestatementBitfield14        |-> << >>,
                                                      varianceRestatementBitfield15        |-> << >>,
                                                      varianceRestatementBitfield16        |-> << >>,
                                                      varianceRestatementBitfield17        |-> << >>,
                                                      varianceRestatementBitfield18        |-> << >>,
                                                      side                                 |-> << >>,
                                                      price                                |-> << >>,
                                                      ordType                              |-> << >>,
                                                      timeInForce                          |-> << >>,
                                                      minQty                               |-> << >>,
                                                      symbolLong                           |-> << >>,
                                                      capacity                             |-> << >>,
                                                      account                              |-> << >>,
                                                      clearingFirm                         |-> << >>,
                                                      clearingAccount                      |-> << >>,
                                                      preventParticipantMatch              |-> << >>,
                                                      maturityDate                         |-> << >>,
                                                      openClose                            |-> << >>,
                                                      origClOrdId                          |-> << >>,
                                                      lastShares                           |-> << >>,
                                                      lastPx                               |-> << >>,
                                                      feeCode                              |-> << >>,
                                                      stopPx                               |-> << >>,
                                                      cmtaNumber                           |-> << >>,
                                                      ctiCode                              |-> << >>,
                                                      manualOrderIndicator                 |-> << >>,
                                                      oeoid                                |-> << >>,
                                                      tradeDate                            |-> << >>,
                                                      clearingPrice                        |-> << >>,
                                                      clearingSize                         |-> << >>,
                                                      clearingSymbol                       |-> << >>,
                                                      multilegReportingType                |-> << >>,
                                                      secondaryExecId                      |-> << >>,
                                                      frequentTraderId                     |-> << >>,
                                                      custOrderHandlingInst                |-> << >> ])

(* Variance Restatement New Order Message Message at zero, then each field in turn at the values it is checked at *)
CheckedVarianceRestatementNewOrderMessageMessage ==
    { ZeroVarianceRestatementNewOrderMessageMessage }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.transactionTime = one]) : one \in Sample(8) }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.clOrdId = one]) : one \in Sample(20) }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.execId = one]) : one \in Sample(8) }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.reserved1 = one]) : one \in Sample(1) }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 1, !.varianceRestatementBitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 2, !.varianceRestatementBitfield2 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 3, !.varianceRestatementBitfield3 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 4, !.varianceRestatementBitfield4 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 5, !.varianceRestatementBitfield5 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 6, !.varianceRestatementBitfield6 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 7, !.varianceRestatementBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 8, !.varianceRestatementBitfield8 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 9, !.varianceRestatementBitfield9 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 10, !.varianceRestatementBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 11, !.varianceRestatementBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 12, !.varianceRestatementBitfield12 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 13, !.varianceRestatementBitfield13 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 14, !.varianceRestatementBitfield14 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 15, !.varianceRestatementBitfield15 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 16, !.varianceRestatementBitfield16 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 17, !.varianceRestatementBitfield17 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 18, !.varianceRestatementBitfield18 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 1, !.varianceRestatementBitfield1 = <<1>>, !.side = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 1, !.varianceRestatementBitfield1 = <<4>>, !.price = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 1, !.varianceRestatementBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 1, !.varianceRestatementBitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 1, !.varianceRestatementBitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 2, !.varianceRestatementBitfield2 = <<1>>, !.symbolLong = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 2, !.varianceRestatementBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 3, !.varianceRestatementBitfield3 = <<1>>, !.account = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 3, !.varianceRestatementBitfield3 = <<2>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 3, !.varianceRestatementBitfield3 = <<4>>, !.clearingAccount = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 3, !.varianceRestatementBitfield3 = <<128>>, !.preventParticipantMatch = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 4, !.varianceRestatementBitfield4 = <<1>>, !.maturityDate = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 4, !.varianceRestatementBitfield4 = <<8>>, !.openClose = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 5, !.varianceRestatementBitfield5 = <<1>>, !.origClOrdId = one]) : one \in { <<held>> : held \in Sample(20) } }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 5, !.varianceRestatementBitfield5 = <<4>>, !.lastShares = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 5, !.varianceRestatementBitfield5 = <<8>>, !.lastPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 8, !.varianceRestatementBitfield8 = <<1>>, !.feeCode = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 8, !.varianceRestatementBitfield8 = <<4>>, !.stopPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 9, !.varianceRestatementBitfield9 = <<32>>, !.cmtaNumber = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 12, !.varianceRestatementBitfield12 = <<1>>, !.ctiCode = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 12, !.varianceRestatementBitfield12 = <<2>>, !.manualOrderIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 12, !.varianceRestatementBitfield12 = <<4>>, !.oeoid = one]) : one \in { <<held>> : held \in Sample(18) } }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 12, !.varianceRestatementBitfield12 = <<8>>, !.tradeDate = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 12, !.varianceRestatementBitfield12 = <<16>>, !.clearingPrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 12, !.varianceRestatementBitfield12 = <<32>>, !.clearingSize = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 12, !.varianceRestatementBitfield12 = <<64>>, !.clearingSymbol = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 13, !.varianceRestatementBitfield13 = <<128>>, !.multilegReportingType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 14, !.varianceRestatementBitfield14 = <<16>>, !.secondaryExecId = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 16, !.varianceRestatementBitfield16 = <<1>>, !.frequentTraderId = one]) : one \in { <<held>> : held \in Sample(6) } }
        \cup { SettleVarianceRestatementNewOrderMessageMessage([ZeroVarianceRestatementNewOrderMessageMessage EXCEPT !.numberOfVarianceRestatementBitfields = 17, !.varianceRestatementBitfield17 = <<128>>, !.custOrderHandlingInst = one]) : one \in { <<held>> : held \in Sample(1) } }

(***************************************************************************)
(* Tas Quote Restatement Message: 70 bytes                                 *)
(***************************************************************************)

TasQuoteRestatementMessage ==
    [ transactionTime : Sample(8),
      quoteUpdateId   : Sample(16),
      execId          : Sample(8),
      symbolShort     : Sample(6),
      clearingSymbol  : Sample(8),
      clearingPrice   : Sample(8),
      reserved16      : Sample(16) ]

EncodeTasQuoteRestatementMessage(message) ==
    message.transactionTime
        \o message.quoteUpdateId
        \o message.execId
        \o message.symbolShort
        \o message.clearingSymbol
        \o message.clearingPrice
        \o message.reserved16

DecodeTasQuoteRestatementMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET quoteUpdateId == ReadBytes(transactionTime.rest, 16) IN IF ~quoteUpdateId.ok THEN Fail ELSE
    LET execId == ReadBytes(quoteUpdateId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET symbolShort == ReadBytes(execId.rest, 6) IN IF ~symbolShort.ok THEN Fail ELSE
    LET clearingSymbol == ReadBytes(symbolShort.rest, 8) IN IF ~clearingSymbol.ok THEN Fail ELSE
    LET clearingPrice == ReadBytes(clearingSymbol.rest, 8) IN IF ~clearingPrice.ok THEN Fail ELSE
    LET reserved16 == ReadBytes(clearingPrice.rest, 16) IN IF ~reserved16.ok THEN Fail ELSE
    Ok([ transactionTime |-> transactionTime.value,
         quoteUpdateId   |-> quoteUpdateId.value,
         execId          |-> execId.value,
         symbolShort     |-> symbolShort.value,
         clearingSymbol  |-> clearingSymbol.value,
         clearingPrice   |-> clearingPrice.value,
         reserved16      |-> reserved16.value ], reserved16.rest)

ZeroTasQuoteRestatementMessage ==
    [ transactionTime |-> [i \in 1 .. 8 |-> 0],
      quoteUpdateId   |-> [i \in 1 .. 16 |-> 0],
      execId          |-> [i \in 1 .. 8 |-> 0],
      symbolShort     |-> [i \in 1 .. 6 |-> 0],
      clearingSymbol  |-> [i \in 1 .. 8 |-> 0],
      clearingPrice   |-> [i \in 1 .. 8 |-> 0],
      reserved16      |-> [i \in 1 .. 16 |-> 0] ]

(* Tas Quote Restatement Message at zero, then each field in turn at the values it is checked at *)
CheckedTasQuoteRestatementMessage ==
    { ZeroTasQuoteRestatementMessage }
        \cup { [ZeroTasQuoteRestatementMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroTasQuoteRestatementMessage EXCEPT !.quoteUpdateId = one] : one \in Sample(16) }
        \cup { [ZeroTasQuoteRestatementMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroTasQuoteRestatementMessage EXCEPT !.symbolShort = one] : one \in Sample(6) }
        \cup { [ZeroTasQuoteRestatementMessage EXCEPT !.clearingSymbol = one] : one \in Sample(8) }
        \cup { [ZeroTasQuoteRestatementMessage EXCEPT !.clearingPrice = one] : one \in Sample(8) }
        \cup { [ZeroTasQuoteRestatementMessage EXCEPT !.reserved16 = one] : one \in Sample(16) }

(***************************************************************************)
(* Variance Quote Restatement Message: 74 bytes                            *)
(***************************************************************************)

VarianceQuoteRestatementMessage ==
    [ transactionTime : Sample(8),
      quoteUpdateId   : Sample(16),
      execId          : Sample(8),
      symbolShort     : Sample(6),
      clearingSymbol  : Sample(8),
      clearingPrice   : Sample(8),
      clearingSize    : Sample(4),
      reserved16      : Sample(16) ]

EncodeVarianceQuoteRestatementMessage(message) ==
    message.transactionTime
        \o message.quoteUpdateId
        \o message.execId
        \o message.symbolShort
        \o message.clearingSymbol
        \o message.clearingPrice
        \o message.clearingSize
        \o message.reserved16

DecodeVarianceQuoteRestatementMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET quoteUpdateId == ReadBytes(transactionTime.rest, 16) IN IF ~quoteUpdateId.ok THEN Fail ELSE
    LET execId == ReadBytes(quoteUpdateId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET symbolShort == ReadBytes(execId.rest, 6) IN IF ~symbolShort.ok THEN Fail ELSE
    LET clearingSymbol == ReadBytes(symbolShort.rest, 8) IN IF ~clearingSymbol.ok THEN Fail ELSE
    LET clearingPrice == ReadBytes(clearingSymbol.rest, 8) IN IF ~clearingPrice.ok THEN Fail ELSE
    LET clearingSize == ReadBytes(clearingPrice.rest, 4) IN IF ~clearingSize.ok THEN Fail ELSE
    LET reserved16 == ReadBytes(clearingSize.rest, 16) IN IF ~reserved16.ok THEN Fail ELSE
    Ok([ transactionTime |-> transactionTime.value,
         quoteUpdateId   |-> quoteUpdateId.value,
         execId          |-> execId.value,
         symbolShort     |-> symbolShort.value,
         clearingSymbol  |-> clearingSymbol.value,
         clearingPrice   |-> clearingPrice.value,
         clearingSize    |-> clearingSize.value,
         reserved16      |-> reserved16.value ], reserved16.rest)

ZeroVarianceQuoteRestatementMessage ==
    [ transactionTime |-> [i \in 1 .. 8 |-> 0],
      quoteUpdateId   |-> [i \in 1 .. 16 |-> 0],
      execId          |-> [i \in 1 .. 8 |-> 0],
      symbolShort     |-> [i \in 1 .. 6 |-> 0],
      clearingSymbol  |-> [i \in 1 .. 8 |-> 0],
      clearingPrice   |-> [i \in 1 .. 8 |-> 0],
      clearingSize    |-> [i \in 1 .. 4 |-> 0],
      reserved16      |-> [i \in 1 .. 16 |-> 0] ]

(* Variance Quote Restatement Message at zero, then each field in turn at the values it is checked at *)
CheckedVarianceQuoteRestatementMessage ==
    { ZeroVarianceQuoteRestatementMessage }
        \cup { [ZeroVarianceQuoteRestatementMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroVarianceQuoteRestatementMessage EXCEPT !.quoteUpdateId = one] : one \in Sample(16) }
        \cup { [ZeroVarianceQuoteRestatementMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroVarianceQuoteRestatementMessage EXCEPT !.symbolShort = one] : one \in Sample(6) }
        \cup { [ZeroVarianceQuoteRestatementMessage EXCEPT !.clearingSymbol = one] : one \in Sample(8) }
        \cup { [ZeroVarianceQuoteRestatementMessage EXCEPT !.clearingPrice = one] : one \in Sample(8) }
        \cup { [ZeroVarianceQuoteRestatementMessage EXCEPT !.clearingSize = one] : one \in Sample(4) }
        \cup { [ZeroVarianceQuoteRestatementMessage EXCEPT !.reserved16 = one] : one \in Sample(16) }

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
QuoteUpdateMessageCode == 112  \* 0x70
PurgeOrdersMessageCode == 71  \* 0x47
ResetRiskMessageCode == 86  \* 0x56
OrderAcknowledgmentMessageCode == 37  \* 0x25
QuoteUpdateAcknowledgmentMessageCode == 113  \* 0x71
OrderRejectedMessageCode == 38  \* 0x26
QuoteUpdateRejectedMessageCode == 120  \* 0x78
OrderModifiedMessageCode == 39  \* 0x27
QuoteRestatedMessageCode == 114  \* 0x72
UserModifyRejectedMessageCode == 41  \* 0x29
OrderCancelledMessageCode == 42  \* 0x2a
QuoteCancelledMessageCode == 115  \* 0x73
CancelRejectedMessageCode == 43  \* 0x2b
OrderExecutionMessageCode == 44  \* 0x2c
QuoteExecutionMessageCode == 116  \* 0x74
TradeCancelOrCorrectMessageCode == 45  \* 0x2d
PurgeRejectedMessageCode == 72  \* 0x48
ResetRiskAcknowledgmentMessageCode == 87  \* 0x57
MassCancelAcknowledgmentMessageCode == 54  \* 0x36
TasRestatementNewOrderMessageMessageCode == 73  \* 0x49
VarianceRestatementNewOrderMessageMessageCode == 74  \* 0x4a
TasQuoteRestatementMessageCode == 117  \* 0x75
VarianceQuoteRestatementMessageCode == 118  \* 0x76

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
        \cup [ tag : {PurgeOrdersMessageCode}, body : PurgeOrdersMessage ]
        \cup [ tag : {ResetRiskMessageCode}, body : ResetRiskMessage ]
        \cup [ tag : {OrderAcknowledgmentMessageCode}, body : OrderAcknowledgmentMessage ]
        \cup [ tag : {QuoteUpdateAcknowledgmentMessageCode}, body : QuoteUpdateAcknowledgmentMessage ]
        \cup [ tag : {OrderRejectedMessageCode}, body : OrderRejectedMessage ]
        \cup [ tag : {QuoteUpdateRejectedMessageCode}, body : QuoteUpdateRejectedMessage ]
        \cup [ tag : {OrderModifiedMessageCode}, body : OrderModifiedMessage ]
        \cup [ tag : {QuoteRestatedMessageCode}, body : QuoteRestatedMessage ]
        \cup [ tag : {UserModifyRejectedMessageCode}, body : UserModifyRejectedMessage ]
        \cup [ tag : {OrderCancelledMessageCode}, body : OrderCancelledMessage ]
        \cup [ tag : {QuoteCancelledMessageCode}, body : QuoteCancelledMessage ]
        \cup [ tag : {CancelRejectedMessageCode}, body : CancelRejectedMessage ]
        \cup [ tag : {OrderExecutionMessageCode}, body : OrderExecutionMessage ]
        \cup [ tag : {QuoteExecutionMessageCode}, body : QuoteExecutionMessage ]
        \cup [ tag : {TradeCancelOrCorrectMessageCode}, body : TradeCancelOrCorrectMessage ]
        \cup [ tag : {PurgeRejectedMessageCode}, body : PurgeRejectedMessage ]
        \cup [ tag : {ResetRiskAcknowledgmentMessageCode}, body : ResetRiskAcknowledgmentMessage ]
        \cup [ tag : {MassCancelAcknowledgmentMessageCode}, body : MassCancelAcknowledgmentMessage ]
        \cup [ tag : {TasRestatementNewOrderMessageMessageCode}, body : TasRestatementNewOrderMessageMessage ]
        \cup [ tag : {VarianceRestatementNewOrderMessageMessageCode}, body : VarianceRestatementNewOrderMessageMessage ]
        \cup [ tag : {TasQuoteRestatementMessageCode}, body : TasQuoteRestatementMessage ]
        \cup [ tag : {VarianceQuoteRestatementMessageCode}, body : VarianceQuoteRestatementMessage ]

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
      [] message.tag = PurgeOrdersMessageCode -> EncodePurgeOrdersMessage(message.body)
      [] message.tag = ResetRiskMessageCode -> EncodeResetRiskMessage(message.body)
      [] message.tag = OrderAcknowledgmentMessageCode -> EncodeOrderAcknowledgmentMessage(message.body)
      [] message.tag = QuoteUpdateAcknowledgmentMessageCode -> EncodeQuoteUpdateAcknowledgmentMessage(message.body)
      [] message.tag = OrderRejectedMessageCode -> EncodeOrderRejectedMessage(message.body)
      [] message.tag = QuoteUpdateRejectedMessageCode -> EncodeQuoteUpdateRejectedMessage(message.body)
      [] message.tag = OrderModifiedMessageCode -> EncodeOrderModifiedMessage(message.body)
      [] message.tag = QuoteRestatedMessageCode -> EncodeQuoteRestatedMessage(message.body)
      [] message.tag = UserModifyRejectedMessageCode -> EncodeUserModifyRejectedMessage(message.body)
      [] message.tag = OrderCancelledMessageCode -> EncodeOrderCancelledMessage(message.body)
      [] message.tag = QuoteCancelledMessageCode -> EncodeQuoteCancelledMessage(message.body)
      [] message.tag = CancelRejectedMessageCode -> EncodeCancelRejectedMessage(message.body)
      [] message.tag = OrderExecutionMessageCode -> EncodeOrderExecutionMessage(message.body)
      [] message.tag = QuoteExecutionMessageCode -> EncodeQuoteExecutionMessage(message.body)
      [] message.tag = TradeCancelOrCorrectMessageCode -> EncodeTradeCancelOrCorrectMessage(message.body)
      [] message.tag = PurgeRejectedMessageCode -> EncodePurgeRejectedMessage(message.body)
      [] message.tag = ResetRiskAcknowledgmentMessageCode -> EncodeResetRiskAcknowledgmentMessage(message.body)
      [] message.tag = MassCancelAcknowledgmentMessageCode -> EncodeMassCancelAcknowledgmentMessage(message.body)
      [] message.tag = TasRestatementNewOrderMessageMessageCode -> EncodeTasRestatementNewOrderMessageMessage(message.body)
      [] message.tag = VarianceRestatementNewOrderMessageMessageCode -> EncodeVarianceRestatementNewOrderMessageMessage(message.body)
      [] message.tag = TasQuoteRestatementMessageCode -> EncodeTasQuoteRestatementMessage(message.body)
      [] message.tag = VarianceQuoteRestatementMessageCode -> EncodeVarianceQuoteRestatementMessage(message.body)

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
              [] tag = PurgeOrdersMessageCode -> DecodePurgeOrdersMessage(bytes)
              [] tag = ResetRiskMessageCode -> DecodeResetRiskMessage(bytes)
              [] tag = OrderAcknowledgmentMessageCode -> DecodeOrderAcknowledgmentMessage(bytes)
              [] tag = QuoteUpdateAcknowledgmentMessageCode -> DecodeQuoteUpdateAcknowledgmentMessage(bytes)
              [] tag = OrderRejectedMessageCode -> DecodeOrderRejectedMessage(bytes)
              [] tag = QuoteUpdateRejectedMessageCode -> DecodeQuoteUpdateRejectedMessage(bytes)
              [] tag = OrderModifiedMessageCode -> DecodeOrderModifiedMessage(bytes)
              [] tag = QuoteRestatedMessageCode -> DecodeQuoteRestatedMessage(bytes)
              [] tag = UserModifyRejectedMessageCode -> DecodeUserModifyRejectedMessage(bytes)
              [] tag = OrderCancelledMessageCode -> DecodeOrderCancelledMessage(bytes)
              [] tag = QuoteCancelledMessageCode -> DecodeQuoteCancelledMessage(bytes)
              [] tag = CancelRejectedMessageCode -> DecodeCancelRejectedMessage(bytes)
              [] tag = OrderExecutionMessageCode -> DecodeOrderExecutionMessage(bytes)
              [] tag = QuoteExecutionMessageCode -> DecodeQuoteExecutionMessage(bytes)
              [] tag = TradeCancelOrCorrectMessageCode -> DecodeTradeCancelOrCorrectMessage(bytes)
              [] tag = PurgeRejectedMessageCode -> DecodePurgeRejectedMessage(bytes)
              [] tag = ResetRiskAcknowledgmentMessageCode -> DecodeResetRiskAcknowledgmentMessage(bytes)
              [] tag = MassCancelAcknowledgmentMessageCode -> DecodeMassCancelAcknowledgmentMessage(bytes)
              [] tag = TasRestatementNewOrderMessageMessageCode -> DecodeTasRestatementNewOrderMessageMessage(bytes)
              [] tag = VarianceRestatementNewOrderMessageMessageCode -> DecodeVarianceRestatementNewOrderMessageMessage(bytes)
              [] tag = TasQuoteRestatementMessageCode -> DecodeTasQuoteRestatementMessage(bytes)
              [] tag = VarianceQuoteRestatementMessageCode -> DecodeVarianceQuoteRestatementMessage(bytes)
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
        \cup { [tag |-> PurgeOrdersMessageCode, body |-> one] : one \in CheckedPurgeOrdersMessage }
        \cup { [tag |-> ResetRiskMessageCode, body |-> one] : one \in CheckedResetRiskMessage }
        \cup { [tag |-> OrderAcknowledgmentMessageCode, body |-> one] : one \in CheckedOrderAcknowledgmentMessage }
        \cup { [tag |-> QuoteUpdateAcknowledgmentMessageCode, body |-> one] : one \in CheckedQuoteUpdateAcknowledgmentMessage }
        \cup { [tag |-> OrderRejectedMessageCode, body |-> one] : one \in CheckedOrderRejectedMessage }
        \cup { [tag |-> QuoteUpdateRejectedMessageCode, body |-> one] : one \in CheckedQuoteUpdateRejectedMessage }
        \cup { [tag |-> OrderModifiedMessageCode, body |-> one] : one \in CheckedOrderModifiedMessage }
        \cup { [tag |-> QuoteRestatedMessageCode, body |-> one] : one \in CheckedQuoteRestatedMessage }
        \cup { [tag |-> UserModifyRejectedMessageCode, body |-> one] : one \in CheckedUserModifyRejectedMessage }
        \cup { [tag |-> OrderCancelledMessageCode, body |-> one] : one \in CheckedOrderCancelledMessage }
        \cup { [tag |-> QuoteCancelledMessageCode, body |-> one] : one \in CheckedQuoteCancelledMessage }
        \cup { [tag |-> CancelRejectedMessageCode, body |-> one] : one \in CheckedCancelRejectedMessage }
        \cup { [tag |-> OrderExecutionMessageCode, body |-> one] : one \in CheckedOrderExecutionMessage }
        \cup { [tag |-> QuoteExecutionMessageCode, body |-> one] : one \in CheckedQuoteExecutionMessage }
        \cup { [tag |-> TradeCancelOrCorrectMessageCode, body |-> one] : one \in CheckedTradeCancelOrCorrectMessage }
        \cup { [tag |-> PurgeRejectedMessageCode, body |-> one] : one \in CheckedPurgeRejectedMessage }
        \cup { [tag |-> ResetRiskAcknowledgmentMessageCode, body |-> one] : one \in CheckedResetRiskAcknowledgmentMessage }
        \cup { [tag |-> MassCancelAcknowledgmentMessageCode, body |-> one] : one \in CheckedMassCancelAcknowledgmentMessage }
        \cup { [tag |-> TasRestatementNewOrderMessageMessageCode, body |-> one] : one \in CheckedTasRestatementNewOrderMessageMessage }
        \cup { [tag |-> VarianceRestatementNewOrderMessageMessageCode, body |-> one] : one \in CheckedVarianceRestatementNewOrderMessageMessage }
        \cup { [tag |-> TasQuoteRestatementMessageCode, body |-> one] : one \in CheckedTasQuoteRestatementMessage }
        \cup { [tag |-> VarianceQuoteRestatementMessageCode, body |-> one] : one \in CheckedVarianceQuoteRestatementMessage }

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

(* Every Quote decodes back to what was encoded, and leaves nothing over *)
RoundTripQuote ==
    \A message \in CheckedQuote :
        LET read == DecodeQuote(EncodeQuote(message))
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

(* Every Purge Orders Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPurgeOrdersMessage ==
    \A message \in CheckedPurgeOrdersMessage :
        LET read == DecodePurgeOrdersMessage(EncodePurgeOrdersMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reset Risk Message decodes back to what was encoded, and leaves nothing over *)
RoundTripResetRiskMessage ==
    \A message \in CheckedResetRiskMessage :
        LET read == DecodeResetRiskMessage(EncodeResetRiskMessage(message))
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

(* Every Quote Update Acknowledgment Quote decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteUpdateAcknowledgmentQuote ==
    \A message \in CheckedQuoteUpdateAcknowledgmentQuote :
        LET read == DecodeQuoteUpdateAcknowledgmentQuote(EncodeQuoteUpdateAcknowledgmentQuote(message))
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

(* Every Order Execution Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutionMessage ==
    \A message \in CheckedOrderExecutionMessage :
        LET read == DecodeOrderExecutionMessage(EncodeOrderExecutionMessage(message))
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

(* Every Tas Restatement New Order Message Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTasRestatementNewOrderMessageMessage ==
    \A message \in CheckedTasRestatementNewOrderMessageMessage :
        LET read == DecodeTasRestatementNewOrderMessageMessage(EncodeTasRestatementNewOrderMessageMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Variance Restatement New Order Message Message decodes back to what was encoded, and leaves nothing over *)
RoundTripVarianceRestatementNewOrderMessageMessage ==
    \A message \in CheckedVarianceRestatementNewOrderMessageMessage :
        LET read == DecodeVarianceRestatementNewOrderMessageMessage(EncodeVarianceRestatementNewOrderMessageMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tas Quote Restatement Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTasQuoteRestatementMessage ==
    \A message \in CheckedTasQuoteRestatementMessage :
        LET read == DecodeTasQuoteRestatementMessage(EncodeTasQuoteRestatementMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Variance Quote Restatement Message decodes back to what was encoded, and leaves nothing over *)
RoundTripVarianceQuoteRestatementMessage ==
    \A message \in CheckedVarianceQuoteRestatementMessage :
        LET read == DecodeVarianceQuoteRestatementMessage(EncodeVarianceQuoteRestatementMessage(message))
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
