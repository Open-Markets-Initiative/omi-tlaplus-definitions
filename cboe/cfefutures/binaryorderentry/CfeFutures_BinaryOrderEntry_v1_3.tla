----------------- MODULE CfeFutures_BinaryOrderEntry_v1_3 ------------------
(***************************************************************************)
(* Chicago Board Options Exchange Futures Binary Order Entry v1.3          *)
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
(* Note: Purge Order Message fills what is left of the frame Message       *)
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
(* Note: Risk Reset Acknowledgment Message fills what is left of the frame *)
(* Message Length states, which is what it is read from.                   *)
(*                                                                         *)
(* Note: Mass Cancel Acknowledgment Message fills what is left of the      *)
(* frame Message Length states, which is what it is read from.             *)
(*                                                                         *)
(* Note: Tas Restatement Message fills what is left of the frame Message   *)
(* Length states, which is what it is read from.                           *)
(*                                                                         *)
(* Note: Variance Restatement Message fills what is left of the frame      *)
(* Message Length states, which is what it is read from.                   *)
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
(* Param Group: 3 bytes                                                    *)
(***************************************************************************)

ParamGroup ==
    [ paramGroupLength : Sample(2),
      paramGroupType   : Sample(1) ]

EncodeParamGroup(message) ==
    message.paramGroupLength
        \o message.paramGroupType

DecodeParamGroup(bytes) ==
    LET paramGroupLength == ReadBytes(bytes, 2) IN IF ~paramGroupLength.ok THEN Fail ELSE
    LET paramGroupType == ReadBytes(paramGroupLength.rest, 1) IN IF ~paramGroupType.ok THEN Fail ELSE
    Ok([ paramGroupLength |-> paramGroupLength.value,
         paramGroupType   |-> paramGroupType.value ], paramGroupType.rest)

ZeroParamGroup ==
    [ paramGroupLength |-> [i \in 1 .. 2 |-> 0],
      paramGroupType   |-> [i \in 1 .. 1 |-> 0] ]

(* Param Group at zero, then each field in turn at the values it is checked at *)
CheckedParamGroup ==
    { ZeroParamGroup }
        \cup { [ZeroParamGroup EXCEPT !.paramGroupLength = one] : one \in Sample(2) }
        \cup { [ZeroParamGroup EXCEPT !.paramGroupType = one] : one \in Sample(1) }

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
OneParamGroup == { ZeroParamGroup }

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

UnitSequence ==
    [ unitNumber     : Sample(1),
      sequenceNumber : Sample(4) ]

EncodeUnitSequence(message) ==
    message.unitNumber
        \o message.sequenceNumber

DecodeUnitSequence(bytes) ==
    LET unitNumber == ReadBytes(bytes, 1) IN IF ~unitNumber.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(unitNumber.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    Ok([ unitNumber     |-> unitNumber.value,
         sequenceNumber |-> sequenceNumber.value ], sequenceNumber.rest)

ZeroUnitSequence ==
    [ unitNumber     |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber |-> [i \in 1 .. 4 |-> 0] ]

(* Unit Sequence at zero, then each field in turn at the values it is checked at *)
CheckedUnitSequence ==
    { ZeroUnitSequence }
        \cup { [ZeroUnitSequence EXCEPT !.unitNumber = one] : one \in Sample(1) }
        \cup { [ZeroUnitSequence EXCEPT !.sequenceNumber = one] : one \in Sample(4) }

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
(* Param Group: 3 bytes                                                    *)
(***************************************************************************)

ParamGroup2 ==
    [ paramGroupLength : Sample(2),
      paramGroupType   : Sample(1) ]

EncodeParamGroup2(message) ==
    message.paramGroupLength
        \o message.paramGroupType

DecodeParamGroup2(bytes) ==
    LET paramGroupLength == ReadBytes(bytes, 2) IN IF ~paramGroupLength.ok THEN Fail ELSE
    LET paramGroupType == ReadBytes(paramGroupLength.rest, 1) IN IF ~paramGroupType.ok THEN Fail ELSE
    Ok([ paramGroupLength |-> paramGroupLength.value,
         paramGroupType   |-> paramGroupType.value ], paramGroupType.rest)

ZeroParamGroup2 ==
    [ paramGroupLength |-> [i \in 1 .. 2 |-> 0],
      paramGroupType   |-> [i \in 1 .. 1 |-> 0] ]

(* Param Group at zero, then each field in turn at the values it is checked at *)
CheckedParamGroup2 ==
    { ZeroParamGroup2 }
        \cup { [ZeroParamGroup2 EXCEPT !.paramGroupLength = one] : one \in Sample(2) }
        \cup { [ZeroParamGroup2 EXCEPT !.paramGroupType = one] : one \in Sample(1) }

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
OneParamGroup2 == { ZeroParamGroup2 }

(***************************************************************************)
(* Login Response Message                                                  *)
(***************************************************************************)

LoginResponseMessage ==
    [ loginResponseStatus        : Sample(1),
      loginResponseText          : Sample(60),
      noUnspecifiedUnitReplay    : Sample(1),
      lastReceivedSequenceNumber : Sample(4),
      unitSequence               : SampleLists(OneUnitSequence),
      paramGroup                 : SampleLists(OneParamGroup2) ]

EncodeLoginResponseMessage(message) ==
    message.loginResponseStatus
        \o message.loginResponseText
        \o message.noUnspecifiedUnitReplay
        \o message.lastReceivedSequenceNumber
        \o EncodeUIntBE(Len(message.unitSequence), 1)
        \o EncodeUnitSequenceList(message.unitSequence)
        \o EncodeUIntBE(Len(message.paramGroup), 1)
        \o EncodeParamGroup2List(message.paramGroup)

DecodeLoginResponseMessage(bytes) ==
    LET loginResponseStatus == ReadBytes(bytes, 1) IN IF ~loginResponseStatus.ok THEN Fail ELSE
    LET loginResponseText == ReadBytes(loginResponseStatus.rest, 60) IN IF ~loginResponseText.ok THEN Fail ELSE
    LET noUnspecifiedUnitReplay == ReadBytes(loginResponseText.rest, 1) IN IF ~noUnspecifiedUnitReplay.ok THEN Fail ELSE
    LET lastReceivedSequenceNumber == ReadBytes(noUnspecifiedUnitReplay.rest, 4) IN IF ~lastReceivedSequenceNumber.ok THEN Fail ELSE
    LET numberOfUnits == ReadUIntBE(lastReceivedSequenceNumber.rest, 1) IN IF ~numberOfUnits.ok THEN Fail ELSE
    LET unitSequence == ReadUnitSequenceList(numberOfUnits.rest, numberOfUnits.value) IN IF ~unitSequence.ok THEN Fail ELSE
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
        \cup { [ZeroLoginResponseMessage EXCEPT !.unitSequence = one] : one \in SampleLists(OneUnitSequence) }
        \cup { [ZeroLoginResponseMessage EXCEPT !.paramGroup = one] : one \in SampleLists(OneParamGroup2) }

(***************************************************************************)
(* Unit Sequence: 5 bytes                                                  *)
(***************************************************************************)

UnitSequence2 ==
    [ unitNumber     : Sample(1),
      sequenceNumber : Sample(4) ]

EncodeUnitSequence2(message) ==
    message.unitNumber
        \o message.sequenceNumber

DecodeUnitSequence2(bytes) ==
    LET unitNumber == ReadBytes(bytes, 1) IN IF ~unitNumber.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(unitNumber.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    Ok([ unitNumber     |-> unitNumber.value,
         sequenceNumber |-> sequenceNumber.value ], sequenceNumber.rest)

ZeroUnitSequence2 ==
    [ unitNumber     |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber |-> [i \in 1 .. 4 |-> 0] ]

(* Unit Sequence at zero, then each field in turn at the values it is checked at *)
CheckedUnitSequence2 ==
    { ZeroUnitSequence2 }
        \cup { [ZeroUnitSequence2 EXCEPT !.unitNumber = one] : one \in Sample(1) }
        \cup { [ZeroUnitSequence2 EXCEPT !.sequenceNumber = one] : one \in Sample(4) }

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
(* Logout Message                                                          *)
(***************************************************************************)

LogoutMessage ==
    [ logoutReason               : Sample(1),
      logoutReasonText           : Sample(60),
      lastReceivedSequenceNumber : Sample(4),
      unitSequence               : SampleLists(OneUnitSequence2) ]

EncodeLogoutMessage(message) ==
    message.logoutReason
        \o message.logoutReasonText
        \o message.lastReceivedSequenceNumber
        \o EncodeUIntBE(Len(message.unitSequence), 1)
        \o EncodeUnitSequence2List(message.unitSequence)

DecodeLogoutMessage(bytes) ==
    LET logoutReason == ReadBytes(bytes, 1) IN IF ~logoutReason.ok THEN Fail ELSE
    LET logoutReasonText == ReadBytes(logoutReason.rest, 60) IN IF ~logoutReasonText.ok THEN Fail ELSE
    LET lastReceivedSequenceNumber == ReadBytes(logoutReasonText.rest, 4) IN IF ~lastReceivedSequenceNumber.ok THEN Fail ELSE
    LET numberOfUnits == ReadUIntBE(lastReceivedSequenceNumber.rest, 1) IN IF ~numberOfUnits.ok THEN Fail ELSE
    LET unitSequence == ReadUnitSequence2List(numberOfUnits.rest, numberOfUnits.value) IN IF ~unitSequence.ok THEN Fail ELSE
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
        \cup { [ZeroLogoutMessage EXCEPT !.unitSequence = one] : one \in SampleLists(OneUnitSequence2) }

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
      frequentTraderId          : { << >> } \cup { <<held>> : held \in Sample(6) } ]

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
    LET clearingFirm == ReadWhen(numberOfNewOrderBitfields.value >= 1 /\ (newOrderBitfield1.value # << >> /\ newOrderBitfield1.value[1] % 2 > 0), ReadBytes(newOrderBitfield8.rest, 4), newOrderBitfield8.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
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
         frequentTraderId          |-> frequentTraderId.value ], frequentTraderId.rest)

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
        settled9 == [settled8 EXCEPT !.clearingFirm = IF settled8.numberOfNewOrderBitfields >= 1 /\ (settled8.newOrderBitfield1 # << >> /\ settled8.newOrderBitfield1[1] % 2 > 0) THEN (IF settled8.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled8.clearingFirm) ELSE << >>]
        settled10 == [settled9 EXCEPT !.clearingAccount = IF settled9.numberOfNewOrderBitfields >= 1 /\ (settled9.newOrderBitfield1 # << >> /\ (settled9.newOrderBitfield1[1] \div 2) % 2 > 0) THEN (IF settled9.clearingAccount = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled9.clearingAccount) ELSE << >>]
        settled11 == [settled10 EXCEPT !.price = IF settled10.numberOfNewOrderBitfields >= 1 /\ (settled10.newOrderBitfield1 # << >> /\ (settled10.newOrderBitfield1[1] \div 4) % 2 > 0) THEN (IF settled10.price = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled10.price) ELSE << >>]
        settled12 == [settled11 EXCEPT !.ordType = IF settled11.numberOfNewOrderBitfields >= 1 /\ (settled11.newOrderBitfield1 # << >> /\ (settled11.newOrderBitfield1[1] \div 16) % 2 > 0) THEN (IF settled11.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled11.ordType) ELSE << >>]
        settled13 == [settled12 EXCEPT !.timeInForce = IF settled12.numberOfNewOrderBitfields >= 1 /\ (settled12.newOrderBitfield1 # << >> /\ (settled12.newOrderBitfield1[1] \div 32) % 2 > 0) THEN (IF settled12.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.timeInForce) ELSE << >>]
        settled14 == [settled13 EXCEPT !.minQty = IF settled13.numberOfNewOrderBitfields >= 1 /\ (settled13.newOrderBitfield1 # << >> /\ (settled13.newOrderBitfield1[1] \div 64) % 2 > 0) THEN (IF settled13.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled13.minQty) ELSE << >>]
        settled15 == [settled14 EXCEPT !.symbolLong = IF settled14.numberOfNewOrderBitfields >= 2 /\ (settled14.newOrderBitfield2 # << >> /\ settled14.newOrderBitfield2[1] % 2 > 0) THEN (IF settled14.symbolLong = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled14.symbolLong) ELSE << >>]
        settled16 == [settled15 EXCEPT !.capacity = IF settled15.numberOfNewOrderBitfields >= 2 /\ (settled15.newOrderBitfield2 # << >> /\ (settled15.newOrderBitfield2[1] \div 64) % 2 > 0) THEN (IF settled15.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled15.capacity) ELSE << >>]
        settled17 == [settled16 EXCEPT !.account = IF settled16.numberOfNewOrderBitfields >= 3 /\ (settled16.newOrderBitfield3 # << >> /\ settled16.newOrderBitfield3[1] % 2 > 0) THEN (IF settled16.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled16.account) ELSE << >>]
        settled18 == [settled17 EXCEPT !.preventMatch = IF settled17.numberOfNewOrderBitfields >= 3 /\ (settled17.newOrderBitfield3 # << >> /\ (settled17.newOrderBitfield3[1] \div 32) % 2 > 0) THEN (IF settled17.preventMatch = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled17.preventMatch) ELSE << >>]
        settled19 == [settled18 EXCEPT !.expireTime = IF settled18.numberOfNewOrderBitfields >= 3 /\ (settled18.newOrderBitfield3 # << >> /\ (settled18.newOrderBitfield3[1] \div 128) % 2 > 0) THEN (IF settled18.expireTime = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled18.expireTime) ELSE << >>]
        settled20 == [settled19 EXCEPT !.maturityDate = IF settled19.numberOfNewOrderBitfields >= 4 /\ (settled19.newOrderBitfield4 # << >> /\ settled19.newOrderBitfield4[1] % 2 > 0) THEN (IF settled19.maturityDate = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled19.maturityDate) ELSE << >>]
        settled21 == [settled20 EXCEPT !.riskReset = IF settled20.numberOfNewOrderBitfields >= 4 /\ (settled20.newOrderBitfield4 # << >> /\ (settled20.newOrderBitfield4[1] \div 8) % 2 > 0) THEN (IF settled20.riskReset = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled20.riskReset) ELSE << >>]
        settled22 == [settled21 EXCEPT !.openClose = IF settled21.numberOfNewOrderBitfields >= 4 /\ (settled21.newOrderBitfield4 # << >> /\ (settled21.newOrderBitfield4[1] \div 16) % 2 > 0) THEN (IF settled21.openClose = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled21.openClose) ELSE << >>]
        settled23 == [settled22 EXCEPT !.cmtaNumber = IF settled22.numberOfNewOrderBitfields >= 4 /\ (settled22.newOrderBitfield4 # << >> /\ (settled22.newOrderBitfield4[1] \div 32) % 2 > 0) THEN (IF settled22.cmtaNumber = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled22.cmtaNumber) ELSE << >>]
        settled24 == [settled23 EXCEPT !.stopPx = IF settled23.numberOfNewOrderBitfields >= 6 /\ (settled23.newOrderBitfield6 # << >> /\ (settled23.newOrderBitfield6[1] \div 2) % 2 > 0) THEN (IF settled23.stopPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled23.stopPx) ELSE << >>]
        settled25 == [settled24 EXCEPT !.customGroupId = IF settled24.numberOfNewOrderBitfields >= 7 /\ (settled24.newOrderBitfield7 # << >> /\ (settled24.newOrderBitfield7[1] \div 2) % 2 > 0) THEN (IF settled24.customGroupId = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled24.customGroupId) ELSE << >>]
        settled26 == [settled25 EXCEPT !.ctiCode = IF settled25.numberOfNewOrderBitfields >= 7 /\ (settled25.newOrderBitfield7 # << >> /\ (settled25.newOrderBitfield7[1] \div 32) % 2 > 0) THEN (IF settled25.ctiCode = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled25.ctiCode) ELSE << >>]
        settled27 == [settled26 EXCEPT !.manualOrderIndicator = IF settled26.numberOfNewOrderBitfields >= 7 /\ (settled26.newOrderBitfield7 # << >> /\ (settled26.newOrderBitfield7[1] \div 64) % 2 > 0) THEN (IF settled26.manualOrderIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled26.manualOrderIndicator) ELSE << >>]
        settled28 == [settled27 EXCEPT !.oeoid = IF settled27.numberOfNewOrderBitfields >= 7 /\ (settled27.newOrderBitfield7 # << >> /\ (settled27.newOrderBitfield7[1] \div 128) % 2 > 0) THEN (IF settled27.oeoid = << >> THEN <<[i \in 1 .. 18 |-> 0]>> ELSE settled27.oeoid) ELSE << >>]
        settled29 == [settled28 EXCEPT !.frequentTraderId = IF settled28.numberOfNewOrderBitfields >= 8 /\ (settled28.newOrderBitfield8 # << >> /\ (settled28.newOrderBitfield8[1] \div 16) % 2 > 0) THEN (IF settled28.frequentTraderId = << >> THEN <<[i \in 1 .. 6 |-> 0]>> ELSE settled28.frequentTraderId) ELSE << >>]
    IN  settled29

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
                            frequentTraderId          |-> << >> ])

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
      frequentTraderId             : { << >> } \cup { <<held>> : held \in Sample(6) } ]

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
         frequentTraderId             |-> frequentTraderId.value ], frequentTraderId.rest)

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
    IN  settled11

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
                               frequentTraderId             |-> << >> ])

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

(***************************************************************************)
(* Quote Group: 32 bytes                                                   *)
(***************************************************************************)

QuoteGroup ==
    [ symbolShort : Sample(6),
      side        : Sample(1),
      openClose   : Sample(1),
      price       : Sample(8),
      orderQty    : Sample(4),
      reserved12  : Sample(12) ]

EncodeQuoteGroup(message) ==
    message.symbolShort
        \o message.side
        \o message.openClose
        \o message.price
        \o message.orderQty
        \o message.reserved12

DecodeQuoteGroup(bytes) ==
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

ZeroQuoteGroup ==
    [ symbolShort |-> [i \in 1 .. 6 |-> 0],
      side        |-> [i \in 1 .. 1 |-> 0],
      openClose   |-> [i \in 1 .. 1 |-> 0],
      price       |-> [i \in 1 .. 8 |-> 0],
      orderQty    |-> [i \in 1 .. 4 |-> 0],
      reserved12  |-> [i \in 1 .. 12 |-> 0] ]

(* Quote Group at zero, then each field in turn at the values it is checked at *)
CheckedQuoteGroup ==
    { ZeroQuoteGroup }
        \cup { [ZeroQuoteGroup EXCEPT !.symbolShort = one] : one \in Sample(6) }
        \cup { [ZeroQuoteGroup EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroQuoteGroup EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroQuoteGroup EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroQuoteGroup EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroQuoteGroup EXCEPT !.reserved12 = one] : one \in Sample(12) }

(* A run of Quote Group, written one after another *)
RECURSIVE EncodeQuoteGroupList(_)
EncodeQuoteGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeQuoteGroup(Head(messages)) \o EncodeQuoteGroupList(Tail(messages))

(* As many Quote Group as the field that counts them says *)
RECURSIVE ReadQuoteGroupList(_, _)
ReadQuoteGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeQuoteGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadQuoteGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Quote Group of each kind, for the lists that carry them *)
OneQuoteGroup == { ZeroQuoteGroup }

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
      quoteGroup           : SampleLists(OneQuoteGroup) ]

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
        \o EncodeUIntBE(Len(message.quoteGroup), 1)
        \o EncodeQuoteGroupList(message.quoteGroup)

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
    LET numberOfQuotes == ReadUIntBE(reserved6.rest, 1) IN IF ~numberOfQuotes.ok THEN Fail ELSE
    LET quoteGroup == ReadQuoteGroupList(numberOfQuotes.rest, numberOfQuotes.value) IN IF ~quoteGroup.ok THEN Fail ELSE
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
         quoteGroup           |-> quoteGroup.value ], quoteGroup.rest)

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
      quoteGroup           |-> << >> ]

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
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.quoteGroup = one] : one \in SampleLists(OneQuoteGroup) }

(***************************************************************************)
(* Purge Order Message                                                     *)
(***************************************************************************)

PurgeOrderMessage ==
    [ reserved1                   : Sample(1),
      numberOfPurgeOrderBitfields : 0 .. 255,
      purgeOrderBitfield1         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      purgeOrderBitfield2         : { << >> } \cup { <<held>> : held \in Sample(1) },
      clearingFirm                : { << >> } \cup { <<held>> : held \in Sample(4) },
      massCancelInst              : { << >> } \cup { <<held>> : held \in Sample(16) },
      productName                 : { << >> } \cup { <<held>> : held \in Sample(6) },
      massCancelId                : { << >> } \cup { <<held>> : held \in Sample(20) },
      manualOrderIndicator        : { << >> } \cup { <<held>> : held \in Sample(1) },
      oeoid                       : { << >> } \cup { <<held>> : held \in Sample(18) } ]

EncodePurgeOrderMessage(message) ==
    message.reserved1
        \o EncodeUIntBE(message.numberOfPurgeOrderBitfields, 1)
        \o (IF message.purgeOrderBitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.purgeOrderBitfield1[1], 1))
        \o (IF message.purgeOrderBitfield2 = << >> THEN << >> ELSE message.purgeOrderBitfield2[1])
        \o (IF message.clearingFirm = << >> THEN << >> ELSE message.clearingFirm[1])
        \o (IF message.massCancelInst = << >> THEN << >> ELSE message.massCancelInst[1])
        \o (IF message.productName = << >> THEN << >> ELSE message.productName[1])
        \o (IF message.massCancelId = << >> THEN << >> ELSE message.massCancelId[1])
        \o (IF message.manualOrderIndicator = << >> THEN << >> ELSE message.manualOrderIndicator[1])
        \o (IF message.oeoid = << >> THEN << >> ELSE message.oeoid[1])

DecodePurgeOrderMessage(bytes) ==
    LET reserved1 == ReadBytes(bytes, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET numberOfPurgeOrderBitfields == ReadUIntBE(reserved1.rest, 1) IN IF ~numberOfPurgeOrderBitfields.ok THEN Fail ELSE
    LET purgeOrderBitfield1 == ReadWhen(numberOfPurgeOrderBitfields.value >= 1, ReadUIntLE(numberOfPurgeOrderBitfields.rest, 1), numberOfPurgeOrderBitfields.rest) IN IF ~purgeOrderBitfield1.ok THEN Fail ELSE
    LET purgeOrderBitfield2 == ReadWhen(numberOfPurgeOrderBitfields.value >= 2, ReadBytes(purgeOrderBitfield1.rest, 1), purgeOrderBitfield1.rest) IN IF ~purgeOrderBitfield2.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfPurgeOrderBitfields.value >= 1 /\ (purgeOrderBitfield1.value # << >> /\ purgeOrderBitfield1.value[1] % 2 > 0), ReadBytes(purgeOrderBitfield2.rest, 4), purgeOrderBitfield2.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET massCancelInst == ReadWhen(numberOfPurgeOrderBitfields.value >= 1 /\ (purgeOrderBitfield1.value # << >> /\ (purgeOrderBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(clearingFirm.rest, 16), clearingFirm.rest) IN IF ~massCancelInst.ok THEN Fail ELSE
    LET productName == ReadWhen(numberOfPurgeOrderBitfields.value >= 1 /\ (purgeOrderBitfield1.value # << >> /\ (purgeOrderBitfield1.value[1] \div 8) % 2 > 0), ReadBytes(massCancelInst.rest, 6), massCancelInst.rest) IN IF ~productName.ok THEN Fail ELSE
    LET massCancelId == ReadWhen(numberOfPurgeOrderBitfields.value >= 1 /\ (purgeOrderBitfield1.value # << >> /\ (purgeOrderBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(productName.rest, 20), productName.rest) IN IF ~massCancelId.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadWhen(numberOfPurgeOrderBitfields.value >= 1 /\ (purgeOrderBitfield1.value # << >> /\ (purgeOrderBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(massCancelId.rest, 1), massCancelId.rest) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET oeoid == ReadWhen(numberOfPurgeOrderBitfields.value >= 1 /\ (purgeOrderBitfield1.value # << >> /\ (purgeOrderBitfield1.value[1] \div 128) % 2 > 0), ReadBytes(manualOrderIndicator.rest, 18), manualOrderIndicator.rest) IN IF ~oeoid.ok THEN Fail ELSE
    Ok([ reserved1                   |-> reserved1.value,
         numberOfPurgeOrderBitfields |-> numberOfPurgeOrderBitfields.value,
         purgeOrderBitfield1         |-> purgeOrderBitfield1.value,
         purgeOrderBitfield2         |-> purgeOrderBitfield2.value,
         clearingFirm                |-> clearingFirm.value,
         massCancelInst              |-> massCancelInst.value,
         productName                 |-> productName.value,
         massCancelId                |-> massCancelId.value,
         manualOrderIndicator        |-> manualOrderIndicator.value,
         oeoid                       |-> oeoid.value ], oeoid.rest)

(* Purge Order Message with each field marked present by fields before it there exactly where they say *)
SettlePurgeOrderMessage(message) ==
    LET settled1 == [message EXCEPT !.purgeOrderBitfield1 = IF message.numberOfPurgeOrderBitfields >= 1 THEN (IF message.purgeOrderBitfield1 = << >> THEN <<0>> ELSE message.purgeOrderBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.purgeOrderBitfield2 = IF settled1.numberOfPurgeOrderBitfields >= 2 THEN (IF settled1.purgeOrderBitfield2 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled1.purgeOrderBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.clearingFirm = IF settled2.numberOfPurgeOrderBitfields >= 1 /\ (settled2.purgeOrderBitfield1 # << >> /\ settled2.purgeOrderBitfield1[1] % 2 > 0) THEN (IF settled2.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled2.clearingFirm) ELSE << >>]
        settled4 == [settled3 EXCEPT !.massCancelInst = IF settled3.numberOfPurgeOrderBitfields >= 1 /\ (settled3.purgeOrderBitfield1 # << >> /\ (settled3.purgeOrderBitfield1[1] \div 4) % 2 > 0) THEN (IF settled3.massCancelInst = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled3.massCancelInst) ELSE << >>]
        settled5 == [settled4 EXCEPT !.productName = IF settled4.numberOfPurgeOrderBitfields >= 1 /\ (settled4.purgeOrderBitfield1 # << >> /\ (settled4.purgeOrderBitfield1[1] \div 8) % 2 > 0) THEN (IF settled4.productName = << >> THEN <<[i \in 1 .. 6 |-> 0]>> ELSE settled4.productName) ELSE << >>]
        settled6 == [settled5 EXCEPT !.massCancelId = IF settled5.numberOfPurgeOrderBitfields >= 1 /\ (settled5.purgeOrderBitfield1 # << >> /\ (settled5.purgeOrderBitfield1[1] \div 16) % 2 > 0) THEN (IF settled5.massCancelId = << >> THEN <<[i \in 1 .. 20 |-> 0]>> ELSE settled5.massCancelId) ELSE << >>]
        settled7 == [settled6 EXCEPT !.manualOrderIndicator = IF settled6.numberOfPurgeOrderBitfields >= 1 /\ (settled6.purgeOrderBitfield1 # << >> /\ (settled6.purgeOrderBitfield1[1] \div 64) % 2 > 0) THEN (IF settled6.manualOrderIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.manualOrderIndicator) ELSE << >>]
        settled8 == [settled7 EXCEPT !.oeoid = IF settled7.numberOfPurgeOrderBitfields >= 1 /\ (settled7.purgeOrderBitfield1 # << >> /\ (settled7.purgeOrderBitfield1[1] \div 128) % 2 > 0) THEN (IF settled7.oeoid = << >> THEN <<[i \in 1 .. 18 |-> 0]>> ELSE settled7.oeoid) ELSE << >>]
    IN  settled8

ZeroPurgeOrderMessage ==
    SettlePurgeOrderMessage([ reserved1                   |-> [i \in 1 .. 1 |-> 0],
                              numberOfPurgeOrderBitfields |-> 0,
                              purgeOrderBitfield1         |-> << >>,
                              purgeOrderBitfield2         |-> << >>,
                              clearingFirm                |-> << >>,
                              massCancelInst              |-> << >>,
                              productName                 |-> << >>,
                              massCancelId                |-> << >>,
                              manualOrderIndicator        |-> << >>,
                              oeoid                       |-> << >> ])

(* Purge Order Message at zero, then each field in turn at the values it is checked at *)
CheckedPurgeOrderMessage ==
    { ZeroPurgeOrderMessage }
        \cup { SettlePurgeOrderMessage([ZeroPurgeOrderMessage EXCEPT !.reserved1 = one]) : one \in Sample(1) }
        \cup { SettlePurgeOrderMessage([ZeroPurgeOrderMessage EXCEPT !.numberOfPurgeOrderBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettlePurgeOrderMessage([ZeroPurgeOrderMessage EXCEPT !.numberOfPurgeOrderBitfields = 1, !.purgeOrderBitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettlePurgeOrderMessage([ZeroPurgeOrderMessage EXCEPT !.numberOfPurgeOrderBitfields = 2, !.purgeOrderBitfield2 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettlePurgeOrderMessage([ZeroPurgeOrderMessage EXCEPT !.numberOfPurgeOrderBitfields = 1, !.purgeOrderBitfield1 = <<1>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettlePurgeOrderMessage([ZeroPurgeOrderMessage EXCEPT !.numberOfPurgeOrderBitfields = 1, !.purgeOrderBitfield1 = <<4>>, !.massCancelInst = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettlePurgeOrderMessage([ZeroPurgeOrderMessage EXCEPT !.numberOfPurgeOrderBitfields = 1, !.purgeOrderBitfield1 = <<8>>, !.productName = one]) : one \in { <<held>> : held \in Sample(6) } }
        \cup { SettlePurgeOrderMessage([ZeroPurgeOrderMessage EXCEPT !.numberOfPurgeOrderBitfields = 1, !.purgeOrderBitfield1 = <<16>>, !.massCancelId = one]) : one \in { <<held>> : held \in Sample(20) } }
        \cup { SettlePurgeOrderMessage([ZeroPurgeOrderMessage EXCEPT !.numberOfPurgeOrderBitfields = 1, !.purgeOrderBitfield1 = <<64>>, !.manualOrderIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettlePurgeOrderMessage([ZeroPurgeOrderMessage EXCEPT !.numberOfPurgeOrderBitfields = 1, !.purgeOrderBitfield1 = <<128>>, !.oeoid = one]) : one \in { <<held>> : held \in Sample(18) } }

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
    [ transactionTime         : Sample(8),
      clOrdId                 : Sample(20),
      orderId                 : Sample(8),
      reserved1               : Sample(1),
      numberOfReturnBitfields : 0 .. 255,
      returnBitfield1         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield2         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield3         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield4         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield5         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield6         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield7         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield8         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield9         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield10        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield11        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield12        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield13        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield14        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield15        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield16        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield17        : { << >> } \cup { <<held>> : held \in Sample(1) },
      side                    : { << >> } \cup { <<held>> : held \in Sample(1) },
      price                   : { << >> } \cup { <<held>> : held \in Sample(8) },
      ordType                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce             : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                  : { << >> } \cup { <<held>> : held \in Sample(4) },
      symbolLong              : { << >> } \cup { <<held>> : held \in Sample(8) },
      capacity                : { << >> } \cup { <<held>> : held \in Sample(1) },
      account                 : { << >> } \cup { <<held>> : held \in Sample(16) },
      clearingFirm            : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingAccount         : { << >> } \cup { <<held>> : held \in Sample(4) },
      orderQty                : { << >> } \cup { <<held>> : held \in Sample(4) },
      preventMatch            : { << >> } \cup { <<held>> : held \in Sample(3) },
      maturityDate            : { << >> } \cup { <<held>> : held \in Sample(4) },
      openClose               : { << >> } \cup { <<held>> : held \in Sample(1) },
      leavesQty               : { << >> } \cup { <<held>> : held \in Sample(4) },
      baseLiquidityIndicator  : { << >> } \cup { <<held>> : held \in Sample(1) },
      expireTime              : { << >> } \cup { <<held>> : held \in Sample(8) },
      subLiquidityIndicator   : { << >> } \cup { <<held>> : held \in Sample(1) },
      stopPx                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      cmtaNumber              : { << >> } \cup { <<held>> : held \in Sample(4) },
      ctiCode                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      manualOrderIndicator    : { << >> } \cup { <<held>> : held \in Sample(1) },
      oeoid                   : { << >> } \cup { <<held>> : held \in Sample(18) },
      cumQty                  : { << >> } \cup { <<held>> : held \in Sample(4) },
      dayOrderQty             : { << >> } \cup { <<held>> : held \in Sample(4) },
      dayCumQty               : { << >> } \cup { <<held>> : held \in Sample(4) },
      avgPx                   : { << >> } \cup { <<held>> : held \in Sample(8) },
      dayAvgPx                : { << >> } \cup { <<held>> : held \in Sample(8) },
      frequentTraderId        : { << >> } \cup { <<held>> : held \in Sample(6) } ]

EncodeOrderAcknowledgmentMessage(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.orderId
        \o message.reserved1
        \o EncodeUIntBE(message.numberOfReturnBitfields, 1)
        \o (IF message.returnBitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield1[1], 1))
        \o (IF message.returnBitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield2[1], 1))
        \o (IF message.returnBitfield3 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield3[1], 1))
        \o (IF message.returnBitfield4 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield4[1], 1))
        \o (IF message.returnBitfield5 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield5[1], 1))
        \o (IF message.returnBitfield6 = << >> THEN << >> ELSE message.returnBitfield6[1])
        \o (IF message.returnBitfield7 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield7[1], 1))
        \o (IF message.returnBitfield8 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield8[1], 1))
        \o (IF message.returnBitfield9 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield9[1], 1))
        \o (IF message.returnBitfield10 = << >> THEN << >> ELSE message.returnBitfield10[1])
        \o (IF message.returnBitfield11 = << >> THEN << >> ELSE message.returnBitfield11[1])
        \o (IF message.returnBitfield12 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield12[1], 1))
        \o (IF message.returnBitfield13 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield13[1], 1))
        \o (IF message.returnBitfield14 = << >> THEN << >> ELSE message.returnBitfield14[1])
        \o (IF message.returnBitfield15 = << >> THEN << >> ELSE message.returnBitfield15[1])
        \o (IF message.returnBitfield16 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield16[1], 1))
        \o (IF message.returnBitfield17 = << >> THEN << >> ELSE message.returnBitfield17[1])
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

DecodeOrderAcknowledgmentMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clOrdId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(orderId.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET numberOfReturnBitfields == ReadUIntBE(reserved1.rest, 1) IN IF ~numberOfReturnBitfields.ok THEN Fail ELSE
    LET returnBitfield1 == ReadWhen(numberOfReturnBitfields.value >= 1, ReadUIntLE(numberOfReturnBitfields.rest, 1), numberOfReturnBitfields.rest) IN IF ~returnBitfield1.ok THEN Fail ELSE
    LET returnBitfield2 == ReadWhen(numberOfReturnBitfields.value >= 2, ReadUIntLE(returnBitfield1.rest, 1), returnBitfield1.rest) IN IF ~returnBitfield2.ok THEN Fail ELSE
    LET returnBitfield3 == ReadWhen(numberOfReturnBitfields.value >= 3, ReadUIntLE(returnBitfield2.rest, 1), returnBitfield2.rest) IN IF ~returnBitfield3.ok THEN Fail ELSE
    LET returnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadUIntLE(returnBitfield3.rest, 1), returnBitfield3.rest) IN IF ~returnBitfield4.ok THEN Fail ELSE
    LET returnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadUIntLE(returnBitfield4.rest, 1), returnBitfield4.rest) IN IF ~returnBitfield5.ok THEN Fail ELSE
    LET returnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadBytes(returnBitfield5.rest, 1), returnBitfield5.rest) IN IF ~returnBitfield6.ok THEN Fail ELSE
    LET returnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadUIntLE(returnBitfield6.rest, 1), returnBitfield6.rest) IN IF ~returnBitfield7.ok THEN Fail ELSE
    LET returnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadUIntLE(returnBitfield7.rest, 1), returnBitfield7.rest) IN IF ~returnBitfield8.ok THEN Fail ELSE
    LET returnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadUIntLE(returnBitfield8.rest, 1), returnBitfield8.rest) IN IF ~returnBitfield9.ok THEN Fail ELSE
    LET returnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadBytes(returnBitfield9.rest, 1), returnBitfield9.rest) IN IF ~returnBitfield10.ok THEN Fail ELSE
    LET returnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadBytes(returnBitfield10.rest, 1), returnBitfield10.rest) IN IF ~returnBitfield11.ok THEN Fail ELSE
    LET returnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadUIntLE(returnBitfield11.rest, 1), returnBitfield11.rest) IN IF ~returnBitfield12.ok THEN Fail ELSE
    LET returnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadUIntLE(returnBitfield12.rest, 1), returnBitfield12.rest) IN IF ~returnBitfield13.ok THEN Fail ELSE
    LET returnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(returnBitfield13.rest, 1), returnBitfield13.rest) IN IF ~returnBitfield14.ok THEN Fail ELSE
    LET returnBitfield15 == ReadWhen(numberOfReturnBitfields.value >= 15, ReadBytes(returnBitfield14.rest, 1), returnBitfield14.rest) IN IF ~returnBitfield15.ok THEN Fail ELSE
    LET returnBitfield16 == ReadWhen(numberOfReturnBitfields.value >= 16, ReadUIntLE(returnBitfield15.rest, 1), returnBitfield15.rest) IN IF ~returnBitfield16.ok THEN Fail ELSE
    LET returnBitfield17 == ReadWhen(numberOfReturnBitfields.value >= 17, ReadBytes(returnBitfield16.rest, 1), returnBitfield16.rest) IN IF ~returnBitfield17.ok THEN Fail ELSE
    LET side == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ returnBitfield1.value[1] % 2 > 0), ReadBytes(returnBitfield17.rest, 1), returnBitfield17.rest) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(side.rest, 8), side.rest) IN IF ~price.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(price.rest, 1), price.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET symbolLong == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ returnBitfield2.value[1] % 2 > 0), ReadBytes(minQty.rest, 8), minQty.rest) IN IF ~symbolLong.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ (returnBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(symbolLong.rest, 1), symbolLong.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ returnBitfield3.value[1] % 2 > 0), ReadBytes(capacity.rest, 16), capacity.rest) IN IF ~account.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 2) % 2 > 0), ReadBytes(account.rest, 4), account.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 4) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET orderQty == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 64) % 2 > 0), ReadBytes(clearingAccount.rest, 4), clearingAccount.rest) IN IF ~orderQty.ok THEN Fail ELSE
    LET preventMatch == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 128) % 2 > 0), ReadBytes(orderQty.rest, 3), orderQty.rest) IN IF ~preventMatch.ok THEN Fail ELSE
    LET maturityDate == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ returnBitfield4.value[1] % 2 > 0), ReadBytes(preventMatch.rest, 4), preventMatch.rest) IN IF ~maturityDate.ok THEN Fail ELSE
    LET openClose == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ (returnBitfield4.value[1] \div 8) % 2 > 0), ReadBytes(maturityDate.rest, 1), maturityDate.rest) IN IF ~openClose.ok THEN Fail ELSE
    LET leavesQty == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 2) % 2 > 0), ReadBytes(openClose.rest, 4), openClose.rest) IN IF ~leavesQty.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 64) % 2 > 0), ReadBytes(leavesQty.rest, 1), leavesQty.rest) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET expireTime == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 128) % 2 > 0), ReadBytes(baseLiquidityIndicator.rest, 8), baseLiquidityIndicator.rest) IN IF ~expireTime.ok THEN Fail ELSE
    LET subLiquidityIndicator == ReadWhen(numberOfReturnBitfields.value >= 7 /\ (returnBitfield7.value # << >> /\ returnBitfield7.value[1] % 2 > 0), ReadBytes(expireTime.rest, 1), expireTime.rest) IN IF ~subLiquidityIndicator.ok THEN Fail ELSE
    LET stopPx == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 4) % 2 > 0), ReadBytes(subLiquidityIndicator.rest, 8), subLiquidityIndicator.rest) IN IF ~stopPx.ok THEN Fail ELSE
    LET cmtaNumber == ReadWhen(numberOfReturnBitfields.value >= 9 /\ (returnBitfield9.value # << >> /\ (returnBitfield9.value[1] \div 32) % 2 > 0), ReadBytes(stopPx.rest, 4), stopPx.rest) IN IF ~cmtaNumber.ok THEN Fail ELSE
    LET ctiCode == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (returnBitfield12.value # << >> /\ returnBitfield12.value[1] % 2 > 0), ReadBytes(cmtaNumber.rest, 1), cmtaNumber.rest) IN IF ~ctiCode.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (returnBitfield12.value # << >> /\ (returnBitfield12.value[1] \div 2) % 2 > 0), ReadBytes(ctiCode.rest, 1), ctiCode.rest) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET oeoid == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (returnBitfield12.value # << >> /\ (returnBitfield12.value[1] \div 4) % 2 > 0), ReadBytes(manualOrderIndicator.rest, 18), manualOrderIndicator.rest) IN IF ~oeoid.ok THEN Fail ELSE
    LET cumQty == ReadWhen(numberOfReturnBitfields.value >= 13 /\ (returnBitfield13.value # << >> /\ returnBitfield13.value[1] % 2 > 0), ReadBytes(oeoid.rest, 4), oeoid.rest) IN IF ~cumQty.ok THEN Fail ELSE
    LET dayOrderQty == ReadWhen(numberOfReturnBitfields.value >= 13 /\ (returnBitfield13.value # << >> /\ (returnBitfield13.value[1] \div 2) % 2 > 0), ReadBytes(cumQty.rest, 4), cumQty.rest) IN IF ~dayOrderQty.ok THEN Fail ELSE
    LET dayCumQty == ReadWhen(numberOfReturnBitfields.value >= 13 /\ (returnBitfield13.value # << >> /\ (returnBitfield13.value[1] \div 4) % 2 > 0), ReadBytes(dayOrderQty.rest, 4), dayOrderQty.rest) IN IF ~dayCumQty.ok THEN Fail ELSE
    LET avgPx == ReadWhen(numberOfReturnBitfields.value >= 13 /\ (returnBitfield13.value # << >> /\ (returnBitfield13.value[1] \div 8) % 2 > 0), ReadBytes(dayCumQty.rest, 8), dayCumQty.rest) IN IF ~avgPx.ok THEN Fail ELSE
    LET dayAvgPx == ReadWhen(numberOfReturnBitfields.value >= 13 /\ (returnBitfield13.value # << >> /\ (returnBitfield13.value[1] \div 16) % 2 > 0), ReadBytes(avgPx.rest, 8), avgPx.rest) IN IF ~dayAvgPx.ok THEN Fail ELSE
    LET frequentTraderId == ReadWhen(numberOfReturnBitfields.value >= 16 /\ (returnBitfield16.value # << >> /\ returnBitfield16.value[1] % 2 > 0), ReadBytes(dayAvgPx.rest, 6), dayAvgPx.rest) IN IF ~frequentTraderId.ok THEN Fail ELSE
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
         price                   |-> price.value,
         ordType                 |-> ordType.value,
         timeInForce             |-> timeInForce.value,
         minQty                  |-> minQty.value,
         symbolLong              |-> symbolLong.value,
         capacity                |-> capacity.value,
         account                 |-> account.value,
         clearingFirm            |-> clearingFirm.value,
         clearingAccount         |-> clearingAccount.value,
         orderQty                |-> orderQty.value,
         preventMatch            |-> preventMatch.value,
         maturityDate            |-> maturityDate.value,
         openClose               |-> openClose.value,
         leavesQty               |-> leavesQty.value,
         baseLiquidityIndicator  |-> baseLiquidityIndicator.value,
         expireTime              |-> expireTime.value,
         subLiquidityIndicator   |-> subLiquidityIndicator.value,
         stopPx                  |-> stopPx.value,
         cmtaNumber              |-> cmtaNumber.value,
         ctiCode                 |-> ctiCode.value,
         manualOrderIndicator    |-> manualOrderIndicator.value,
         oeoid                   |-> oeoid.value,
         cumQty                  |-> cumQty.value,
         dayOrderQty             |-> dayOrderQty.value,
         dayCumQty               |-> dayCumQty.value,
         avgPx                   |-> avgPx.value,
         dayAvgPx                |-> dayAvgPx.value,
         frequentTraderId        |-> frequentTraderId.value ], frequentTraderId.rest)

(* Order Acknowledgment Message with each field marked present by fields before it there exactly where they say *)
SettleOrderAcknowledgmentMessage(message) ==
    LET settled1 == [message EXCEPT !.returnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.returnBitfield1 = << >> THEN <<0>> ELSE message.returnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.returnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.returnBitfield2 = << >> THEN <<0>> ELSE settled1.returnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.returnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.returnBitfield3 = << >> THEN <<0>> ELSE settled2.returnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.returnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.returnBitfield4 = << >> THEN <<0>> ELSE settled3.returnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.returnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.returnBitfield5 = << >> THEN <<0>> ELSE settled4.returnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.returnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.returnBitfield6 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled5.returnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.returnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.returnBitfield7 = << >> THEN <<0>> ELSE settled6.returnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.returnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.returnBitfield8 = << >> THEN <<0>> ELSE settled7.returnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.returnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.returnBitfield9 = << >> THEN <<0>> ELSE settled8.returnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.returnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.returnBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.returnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.returnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.returnBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.returnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.returnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.returnBitfield12 = << >> THEN <<0>> ELSE settled11.returnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.returnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.returnBitfield13 = << >> THEN <<0>> ELSE settled12.returnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.returnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.returnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.returnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.returnBitfield15 = IF settled14.numberOfReturnBitfields >= 15 THEN (IF settled14.returnBitfield15 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.returnBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.returnBitfield16 = IF settled15.numberOfReturnBitfields >= 16 THEN (IF settled15.returnBitfield16 = << >> THEN <<0>> ELSE settled15.returnBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.returnBitfield17 = IF settled16.numberOfReturnBitfields >= 17 THEN (IF settled16.returnBitfield17 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled16.returnBitfield17) ELSE << >>]
        settled18 == [settled17 EXCEPT !.side = IF settled17.numberOfReturnBitfields >= 1 /\ (settled17.returnBitfield1 # << >> /\ settled17.returnBitfield1[1] % 2 > 0) THEN (IF settled17.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.side) ELSE << >>]
        settled19 == [settled18 EXCEPT !.price = IF settled18.numberOfReturnBitfields >= 1 /\ (settled18.returnBitfield1 # << >> /\ (settled18.returnBitfield1[1] \div 4) % 2 > 0) THEN (IF settled18.price = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled18.price) ELSE << >>]
        settled20 == [settled19 EXCEPT !.ordType = IF settled19.numberOfReturnBitfields >= 1 /\ (settled19.returnBitfield1 # << >> /\ (settled19.returnBitfield1[1] \div 16) % 2 > 0) THEN (IF settled19.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled19.ordType) ELSE << >>]
        settled21 == [settled20 EXCEPT !.timeInForce = IF settled20.numberOfReturnBitfields >= 1 /\ (settled20.returnBitfield1 # << >> /\ (settled20.returnBitfield1[1] \div 32) % 2 > 0) THEN (IF settled20.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled20.timeInForce) ELSE << >>]
        settled22 == [settled21 EXCEPT !.minQty = IF settled21.numberOfReturnBitfields >= 1 /\ (settled21.returnBitfield1 # << >> /\ (settled21.returnBitfield1[1] \div 64) % 2 > 0) THEN (IF settled21.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled21.minQty) ELSE << >>]
        settled23 == [settled22 EXCEPT !.symbolLong = IF settled22.numberOfReturnBitfields >= 2 /\ (settled22.returnBitfield2 # << >> /\ settled22.returnBitfield2[1] % 2 > 0) THEN (IF settled22.symbolLong = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled22.symbolLong) ELSE << >>]
        settled24 == [settled23 EXCEPT !.capacity = IF settled23.numberOfReturnBitfields >= 2 /\ (settled23.returnBitfield2 # << >> /\ (settled23.returnBitfield2[1] \div 64) % 2 > 0) THEN (IF settled23.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled23.capacity) ELSE << >>]
        settled25 == [settled24 EXCEPT !.account = IF settled24.numberOfReturnBitfields >= 3 /\ (settled24.returnBitfield3 # << >> /\ settled24.returnBitfield3[1] % 2 > 0) THEN (IF settled24.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled24.account) ELSE << >>]
        settled26 == [settled25 EXCEPT !.clearingFirm = IF settled25.numberOfReturnBitfields >= 3 /\ (settled25.returnBitfield3 # << >> /\ (settled25.returnBitfield3[1] \div 2) % 2 > 0) THEN (IF settled25.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled25.clearingFirm) ELSE << >>]
        settled27 == [settled26 EXCEPT !.clearingAccount = IF settled26.numberOfReturnBitfields >= 3 /\ (settled26.returnBitfield3 # << >> /\ (settled26.returnBitfield3[1] \div 4) % 2 > 0) THEN (IF settled26.clearingAccount = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled26.clearingAccount) ELSE << >>]
        settled28 == [settled27 EXCEPT !.orderQty = IF settled27.numberOfReturnBitfields >= 3 /\ (settled27.returnBitfield3 # << >> /\ (settled27.returnBitfield3[1] \div 64) % 2 > 0) THEN (IF settled27.orderQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled27.orderQty) ELSE << >>]
        settled29 == [settled28 EXCEPT !.preventMatch = IF settled28.numberOfReturnBitfields >= 3 /\ (settled28.returnBitfield3 # << >> /\ (settled28.returnBitfield3[1] \div 128) % 2 > 0) THEN (IF settled28.preventMatch = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled28.preventMatch) ELSE << >>]
        settled30 == [settled29 EXCEPT !.maturityDate = IF settled29.numberOfReturnBitfields >= 4 /\ (settled29.returnBitfield4 # << >> /\ settled29.returnBitfield4[1] % 2 > 0) THEN (IF settled29.maturityDate = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled29.maturityDate) ELSE << >>]
        settled31 == [settled30 EXCEPT !.openClose = IF settled30.numberOfReturnBitfields >= 4 /\ (settled30.returnBitfield4 # << >> /\ (settled30.returnBitfield4[1] \div 8) % 2 > 0) THEN (IF settled30.openClose = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled30.openClose) ELSE << >>]
        settled32 == [settled31 EXCEPT !.leavesQty = IF settled31.numberOfReturnBitfields >= 5 /\ (settled31.returnBitfield5 # << >> /\ (settled31.returnBitfield5[1] \div 2) % 2 > 0) THEN (IF settled31.leavesQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled31.leavesQty) ELSE << >>]
        settled33 == [settled32 EXCEPT !.baseLiquidityIndicator = IF settled32.numberOfReturnBitfields >= 5 /\ (settled32.returnBitfield5 # << >> /\ (settled32.returnBitfield5[1] \div 64) % 2 > 0) THEN (IF settled32.baseLiquidityIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled32.baseLiquidityIndicator) ELSE << >>]
        settled34 == [settled33 EXCEPT !.expireTime = IF settled33.numberOfReturnBitfields >= 5 /\ (settled33.returnBitfield5 # << >> /\ (settled33.returnBitfield5[1] \div 128) % 2 > 0) THEN (IF settled33.expireTime = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled33.expireTime) ELSE << >>]
        settled35 == [settled34 EXCEPT !.subLiquidityIndicator = IF settled34.numberOfReturnBitfields >= 7 /\ (settled34.returnBitfield7 # << >> /\ settled34.returnBitfield7[1] % 2 > 0) THEN (IF settled34.subLiquidityIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled34.subLiquidityIndicator) ELSE << >>]
        settled36 == [settled35 EXCEPT !.stopPx = IF settled35.numberOfReturnBitfields >= 8 /\ (settled35.returnBitfield8 # << >> /\ (settled35.returnBitfield8[1] \div 4) % 2 > 0) THEN (IF settled35.stopPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled35.stopPx) ELSE << >>]
        settled37 == [settled36 EXCEPT !.cmtaNumber = IF settled36.numberOfReturnBitfields >= 9 /\ (settled36.returnBitfield9 # << >> /\ (settled36.returnBitfield9[1] \div 32) % 2 > 0) THEN (IF settled36.cmtaNumber = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled36.cmtaNumber) ELSE << >>]
        settled38 == [settled37 EXCEPT !.ctiCode = IF settled37.numberOfReturnBitfields >= 12 /\ (settled37.returnBitfield12 # << >> /\ settled37.returnBitfield12[1] % 2 > 0) THEN (IF settled37.ctiCode = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled37.ctiCode) ELSE << >>]
        settled39 == [settled38 EXCEPT !.manualOrderIndicator = IF settled38.numberOfReturnBitfields >= 12 /\ (settled38.returnBitfield12 # << >> /\ (settled38.returnBitfield12[1] \div 2) % 2 > 0) THEN (IF settled38.manualOrderIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled38.manualOrderIndicator) ELSE << >>]
        settled40 == [settled39 EXCEPT !.oeoid = IF settled39.numberOfReturnBitfields >= 12 /\ (settled39.returnBitfield12 # << >> /\ (settled39.returnBitfield12[1] \div 4) % 2 > 0) THEN (IF settled39.oeoid = << >> THEN <<[i \in 1 .. 18 |-> 0]>> ELSE settled39.oeoid) ELSE << >>]
        settled41 == [settled40 EXCEPT !.cumQty = IF settled40.numberOfReturnBitfields >= 13 /\ (settled40.returnBitfield13 # << >> /\ settled40.returnBitfield13[1] % 2 > 0) THEN (IF settled40.cumQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled40.cumQty) ELSE << >>]
        settled42 == [settled41 EXCEPT !.dayOrderQty = IF settled41.numberOfReturnBitfields >= 13 /\ (settled41.returnBitfield13 # << >> /\ (settled41.returnBitfield13[1] \div 2) % 2 > 0) THEN (IF settled41.dayOrderQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled41.dayOrderQty) ELSE << >>]
        settled43 == [settled42 EXCEPT !.dayCumQty = IF settled42.numberOfReturnBitfields >= 13 /\ (settled42.returnBitfield13 # << >> /\ (settled42.returnBitfield13[1] \div 4) % 2 > 0) THEN (IF settled42.dayCumQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled42.dayCumQty) ELSE << >>]
        settled44 == [settled43 EXCEPT !.avgPx = IF settled43.numberOfReturnBitfields >= 13 /\ (settled43.returnBitfield13 # << >> /\ (settled43.returnBitfield13[1] \div 8) % 2 > 0) THEN (IF settled43.avgPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled43.avgPx) ELSE << >>]
        settled45 == [settled44 EXCEPT !.dayAvgPx = IF settled44.numberOfReturnBitfields >= 13 /\ (settled44.returnBitfield13 # << >> /\ (settled44.returnBitfield13[1] \div 16) % 2 > 0) THEN (IF settled44.dayAvgPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled44.dayAvgPx) ELSE << >>]
        settled46 == [settled45 EXCEPT !.frequentTraderId = IF settled45.numberOfReturnBitfields >= 16 /\ (settled45.returnBitfield16 # << >> /\ settled45.returnBitfield16[1] % 2 > 0) THEN (IF settled45.frequentTraderId = << >> THEN <<[i \in 1 .. 6 |-> 0]>> ELSE settled45.frequentTraderId) ELSE << >>]
    IN  settled46

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
                                       side                    |-> << >>,
                                       price                   |-> << >>,
                                       ordType                 |-> << >>,
                                       timeInForce             |-> << >>,
                                       minQty                  |-> << >>,
                                       symbolLong              |-> << >>,
                                       capacity                |-> << >>,
                                       account                 |-> << >>,
                                       clearingFirm            |-> << >>,
                                       clearingAccount         |-> << >>,
                                       orderQty                |-> << >>,
                                       preventMatch            |-> << >>,
                                       maturityDate            |-> << >>,
                                       openClose               |-> << >>,
                                       leavesQty               |-> << >>,
                                       baseLiquidityIndicator  |-> << >>,
                                       expireTime              |-> << >>,
                                       subLiquidityIndicator   |-> << >>,
                                       stopPx                  |-> << >>,
                                       cmtaNumber              |-> << >>,
                                       ctiCode                 |-> << >>,
                                       manualOrderIndicator    |-> << >>,
                                       oeoid                   |-> << >>,
                                       cumQty                  |-> << >>,
                                       dayOrderQty             |-> << >>,
                                       dayCumQty               |-> << >>,
                                       avgPx                   |-> << >>,
                                       dayAvgPx                |-> << >>,
                                       frequentTraderId        |-> << >> ])

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
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 7, !.returnBitfield7 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 9, !.returnBitfield9 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 10, !.returnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 11, !.returnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 13, !.returnBitfield13 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 14, !.returnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 15, !.returnBitfield15 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 17, !.returnBitfield17 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<1>>, !.side = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<4>>, !.price = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<1>>, !.symbolLong = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<1>>, !.account = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<2>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<4>>, !.clearingAccount = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<64>>, !.orderQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<128>>, !.preventMatch = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<1>>, !.maturityDate = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<8>>, !.openClose = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<2>>, !.leavesQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<64>>, !.baseLiquidityIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<128>>, !.expireTime = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 7, !.returnBitfield7 = <<1>>, !.subLiquidityIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<4>>, !.stopPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 9, !.returnBitfield9 = <<32>>, !.cmtaNumber = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = <<1>>, !.ctiCode = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = <<2>>, !.manualOrderIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = <<4>>, !.oeoid = one]) : one \in { <<held>> : held \in Sample(18) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 13, !.returnBitfield13 = <<1>>, !.cumQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 13, !.returnBitfield13 = <<2>>, !.dayOrderQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 13, !.returnBitfield13 = <<4>>, !.dayCumQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 13, !.returnBitfield13 = <<8>>, !.avgPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 13, !.returnBitfield13 = <<16>>, !.dayAvgPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderAcknowledgmentMessage([ZeroOrderAcknowledgmentMessage EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = <<1>>, !.frequentTraderId = one]) : one \in { <<held>> : held \in Sample(6) } }

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
      returnBitfield6         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield7         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield8         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield9         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield10        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield11        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield12        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield13        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield14        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield15        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield16        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield17        : { << >> } \cup { <<held>> : held \in Sample(1) },
      side                    : { << >> } \cup { <<held>> : held \in Sample(1) },
      price                   : { << >> } \cup { <<held>> : held \in Sample(8) },
      ordType                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce             : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                  : { << >> } \cup { <<held>> : held \in Sample(4) },
      symbolLong              : { << >> } \cup { <<held>> : held \in Sample(8) },
      capacity                : { << >> } \cup { <<held>> : held \in Sample(1) },
      account                 : { << >> } \cup { <<held>> : held \in Sample(16) },
      clearingFirm            : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingAccount         : { << >> } \cup { <<held>> : held \in Sample(4) },
      orderQty                : { << >> } \cup { <<held>> : held \in Sample(4) },
      preventMatch            : { << >> } \cup { <<held>> : held \in Sample(3) },
      maturityDate            : { << >> } \cup { <<held>> : held \in Sample(4) },
      openClose               : { << >> } \cup { <<held>> : held \in Sample(1) },
      stopPx                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      cmtaNumber              : { << >> } \cup { <<held>> : held \in Sample(4) },
      ctiCode                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      manualOrderIndicator    : { << >> } \cup { <<held>> : held \in Sample(1) },
      oeoid                   : { << >> } \cup { <<held>> : held \in Sample(18) },
      frequentTraderId        : { << >> } \cup { <<held>> : held \in Sample(6) } ]

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
        \o (IF message.returnBitfield6 = << >> THEN << >> ELSE message.returnBitfield6[1])
        \o (IF message.returnBitfield7 = << >> THEN << >> ELSE message.returnBitfield7[1])
        \o (IF message.returnBitfield8 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield8[1], 1))
        \o (IF message.returnBitfield9 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield9[1], 1))
        \o (IF message.returnBitfield10 = << >> THEN << >> ELSE message.returnBitfield10[1])
        \o (IF message.returnBitfield11 = << >> THEN << >> ELSE message.returnBitfield11[1])
        \o (IF message.returnBitfield12 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield12[1], 1))
        \o (IF message.returnBitfield13 = << >> THEN << >> ELSE message.returnBitfield13[1])
        \o (IF message.returnBitfield14 = << >> THEN << >> ELSE message.returnBitfield14[1])
        \o (IF message.returnBitfield15 = << >> THEN << >> ELSE message.returnBitfield15[1])
        \o (IF message.returnBitfield16 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield16[1], 1))
        \o (IF message.returnBitfield17 = << >> THEN << >> ELSE message.returnBitfield17[1])
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
    LET returnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadBytes(returnBitfield5.rest, 1), returnBitfield5.rest) IN IF ~returnBitfield6.ok THEN Fail ELSE
    LET returnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadBytes(returnBitfield6.rest, 1), returnBitfield6.rest) IN IF ~returnBitfield7.ok THEN Fail ELSE
    LET returnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadUIntLE(returnBitfield7.rest, 1), returnBitfield7.rest) IN IF ~returnBitfield8.ok THEN Fail ELSE
    LET returnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadUIntLE(returnBitfield8.rest, 1), returnBitfield8.rest) IN IF ~returnBitfield9.ok THEN Fail ELSE
    LET returnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadBytes(returnBitfield9.rest, 1), returnBitfield9.rest) IN IF ~returnBitfield10.ok THEN Fail ELSE
    LET returnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadBytes(returnBitfield10.rest, 1), returnBitfield10.rest) IN IF ~returnBitfield11.ok THEN Fail ELSE
    LET returnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadUIntLE(returnBitfield11.rest, 1), returnBitfield11.rest) IN IF ~returnBitfield12.ok THEN Fail ELSE
    LET returnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(returnBitfield12.rest, 1), returnBitfield12.rest) IN IF ~returnBitfield13.ok THEN Fail ELSE
    LET returnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(returnBitfield13.rest, 1), returnBitfield13.rest) IN IF ~returnBitfield14.ok THEN Fail ELSE
    LET returnBitfield15 == ReadWhen(numberOfReturnBitfields.value >= 15, ReadBytes(returnBitfield14.rest, 1), returnBitfield14.rest) IN IF ~returnBitfield15.ok THEN Fail ELSE
    LET returnBitfield16 == ReadWhen(numberOfReturnBitfields.value >= 16, ReadUIntLE(returnBitfield15.rest, 1), returnBitfield15.rest) IN IF ~returnBitfield16.ok THEN Fail ELSE
    LET returnBitfield17 == ReadWhen(numberOfReturnBitfields.value >= 17, ReadBytes(returnBitfield16.rest, 1), returnBitfield16.rest) IN IF ~returnBitfield17.ok THEN Fail ELSE
    LET side == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ returnBitfield1.value[1] % 2 > 0), ReadBytes(returnBitfield17.rest, 1), returnBitfield17.rest) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(side.rest, 8), side.rest) IN IF ~price.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(price.rest, 1), price.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET symbolLong == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ returnBitfield2.value[1] % 2 > 0), ReadBytes(minQty.rest, 8), minQty.rest) IN IF ~symbolLong.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ (returnBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(symbolLong.rest, 1), symbolLong.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ returnBitfield3.value[1] % 2 > 0), ReadBytes(capacity.rest, 16), capacity.rest) IN IF ~account.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 2) % 2 > 0), ReadBytes(account.rest, 4), account.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 4) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET orderQty == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 64) % 2 > 0), ReadBytes(clearingAccount.rest, 4), clearingAccount.rest) IN IF ~orderQty.ok THEN Fail ELSE
    LET preventMatch == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 128) % 2 > 0), ReadBytes(orderQty.rest, 3), orderQty.rest) IN IF ~preventMatch.ok THEN Fail ELSE
    LET maturityDate == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ returnBitfield4.value[1] % 2 > 0), ReadBytes(preventMatch.rest, 4), preventMatch.rest) IN IF ~maturityDate.ok THEN Fail ELSE
    LET openClose == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ (returnBitfield4.value[1] \div 8) % 2 > 0), ReadBytes(maturityDate.rest, 1), maturityDate.rest) IN IF ~openClose.ok THEN Fail ELSE
    LET stopPx == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 4) % 2 > 0), ReadBytes(openClose.rest, 8), openClose.rest) IN IF ~stopPx.ok THEN Fail ELSE
    LET cmtaNumber == ReadWhen(numberOfReturnBitfields.value >= 9 /\ (returnBitfield9.value # << >> /\ (returnBitfield9.value[1] \div 32) % 2 > 0), ReadBytes(stopPx.rest, 4), stopPx.rest) IN IF ~cmtaNumber.ok THEN Fail ELSE
    LET ctiCode == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (returnBitfield12.value # << >> /\ returnBitfield12.value[1] % 2 > 0), ReadBytes(cmtaNumber.rest, 1), cmtaNumber.rest) IN IF ~ctiCode.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (returnBitfield12.value # << >> /\ (returnBitfield12.value[1] \div 2) % 2 > 0), ReadBytes(ctiCode.rest, 1), ctiCode.rest) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET oeoid == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (returnBitfield12.value # << >> /\ (returnBitfield12.value[1] \div 4) % 2 > 0), ReadBytes(manualOrderIndicator.rest, 18), manualOrderIndicator.rest) IN IF ~oeoid.ok THEN Fail ELSE
    LET frequentTraderId == ReadWhen(numberOfReturnBitfields.value >= 16 /\ (returnBitfield16.value # << >> /\ returnBitfield16.value[1] % 2 > 0), ReadBytes(oeoid.rest, 6), oeoid.rest) IN IF ~frequentTraderId.ok THEN Fail ELSE
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
         price                   |-> price.value,
         ordType                 |-> ordType.value,
         timeInForce             |-> timeInForce.value,
         minQty                  |-> minQty.value,
         symbolLong              |-> symbolLong.value,
         capacity                |-> capacity.value,
         account                 |-> account.value,
         clearingFirm            |-> clearingFirm.value,
         clearingAccount         |-> clearingAccount.value,
         orderQty                |-> orderQty.value,
         preventMatch            |-> preventMatch.value,
         maturityDate            |-> maturityDate.value,
         openClose               |-> openClose.value,
         stopPx                  |-> stopPx.value,
         cmtaNumber              |-> cmtaNumber.value,
         ctiCode                 |-> ctiCode.value,
         manualOrderIndicator    |-> manualOrderIndicator.value,
         oeoid                   |-> oeoid.value,
         frequentTraderId        |-> frequentTraderId.value ], frequentTraderId.rest)

(* Order Rejected Message with each field marked present by fields before it there exactly where they say *)
SettleOrderRejectedMessage(message) ==
    LET settled1 == [message EXCEPT !.returnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.returnBitfield1 = << >> THEN <<0>> ELSE message.returnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.returnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.returnBitfield2 = << >> THEN <<0>> ELSE settled1.returnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.returnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.returnBitfield3 = << >> THEN <<0>> ELSE settled2.returnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.returnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.returnBitfield4 = << >> THEN <<0>> ELSE settled3.returnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.returnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.returnBitfield5 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled4.returnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.returnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.returnBitfield6 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled5.returnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.returnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.returnBitfield7 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.returnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.returnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.returnBitfield8 = << >> THEN <<0>> ELSE settled7.returnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.returnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.returnBitfield9 = << >> THEN <<0>> ELSE settled8.returnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.returnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.returnBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.returnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.returnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.returnBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.returnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.returnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.returnBitfield12 = << >> THEN <<0>> ELSE settled11.returnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.returnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.returnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.returnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.returnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.returnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.returnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.returnBitfield15 = IF settled14.numberOfReturnBitfields >= 15 THEN (IF settled14.returnBitfield15 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.returnBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.returnBitfield16 = IF settled15.numberOfReturnBitfields >= 16 THEN (IF settled15.returnBitfield16 = << >> THEN <<0>> ELSE settled15.returnBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.returnBitfield17 = IF settled16.numberOfReturnBitfields >= 17 THEN (IF settled16.returnBitfield17 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled16.returnBitfield17) ELSE << >>]
        settled18 == [settled17 EXCEPT !.side = IF settled17.numberOfReturnBitfields >= 1 /\ (settled17.returnBitfield1 # << >> /\ settled17.returnBitfield1[1] % 2 > 0) THEN (IF settled17.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.side) ELSE << >>]
        settled19 == [settled18 EXCEPT !.price = IF settled18.numberOfReturnBitfields >= 1 /\ (settled18.returnBitfield1 # << >> /\ (settled18.returnBitfield1[1] \div 4) % 2 > 0) THEN (IF settled18.price = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled18.price) ELSE << >>]
        settled20 == [settled19 EXCEPT !.ordType = IF settled19.numberOfReturnBitfields >= 1 /\ (settled19.returnBitfield1 # << >> /\ (settled19.returnBitfield1[1] \div 16) % 2 > 0) THEN (IF settled19.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled19.ordType) ELSE << >>]
        settled21 == [settled20 EXCEPT !.timeInForce = IF settled20.numberOfReturnBitfields >= 1 /\ (settled20.returnBitfield1 # << >> /\ (settled20.returnBitfield1[1] \div 32) % 2 > 0) THEN (IF settled20.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled20.timeInForce) ELSE << >>]
        settled22 == [settled21 EXCEPT !.minQty = IF settled21.numberOfReturnBitfields >= 1 /\ (settled21.returnBitfield1 # << >> /\ (settled21.returnBitfield1[1] \div 64) % 2 > 0) THEN (IF settled21.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled21.minQty) ELSE << >>]
        settled23 == [settled22 EXCEPT !.symbolLong = IF settled22.numberOfReturnBitfields >= 2 /\ (settled22.returnBitfield2 # << >> /\ settled22.returnBitfield2[1] % 2 > 0) THEN (IF settled22.symbolLong = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled22.symbolLong) ELSE << >>]
        settled24 == [settled23 EXCEPT !.capacity = IF settled23.numberOfReturnBitfields >= 2 /\ (settled23.returnBitfield2 # << >> /\ (settled23.returnBitfield2[1] \div 64) % 2 > 0) THEN (IF settled23.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled23.capacity) ELSE << >>]
        settled25 == [settled24 EXCEPT !.account = IF settled24.numberOfReturnBitfields >= 3 /\ (settled24.returnBitfield3 # << >> /\ settled24.returnBitfield3[1] % 2 > 0) THEN (IF settled24.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled24.account) ELSE << >>]
        settled26 == [settled25 EXCEPT !.clearingFirm = IF settled25.numberOfReturnBitfields >= 3 /\ (settled25.returnBitfield3 # << >> /\ (settled25.returnBitfield3[1] \div 2) % 2 > 0) THEN (IF settled25.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled25.clearingFirm) ELSE << >>]
        settled27 == [settled26 EXCEPT !.clearingAccount = IF settled26.numberOfReturnBitfields >= 3 /\ (settled26.returnBitfield3 # << >> /\ (settled26.returnBitfield3[1] \div 4) % 2 > 0) THEN (IF settled26.clearingAccount = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled26.clearingAccount) ELSE << >>]
        settled28 == [settled27 EXCEPT !.orderQty = IF settled27.numberOfReturnBitfields >= 3 /\ (settled27.returnBitfield3 # << >> /\ (settled27.returnBitfield3[1] \div 64) % 2 > 0) THEN (IF settled27.orderQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled27.orderQty) ELSE << >>]
        settled29 == [settled28 EXCEPT !.preventMatch = IF settled28.numberOfReturnBitfields >= 3 /\ (settled28.returnBitfield3 # << >> /\ (settled28.returnBitfield3[1] \div 128) % 2 > 0) THEN (IF settled28.preventMatch = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled28.preventMatch) ELSE << >>]
        settled30 == [settled29 EXCEPT !.maturityDate = IF settled29.numberOfReturnBitfields >= 4 /\ (settled29.returnBitfield4 # << >> /\ settled29.returnBitfield4[1] % 2 > 0) THEN (IF settled29.maturityDate = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled29.maturityDate) ELSE << >>]
        settled31 == [settled30 EXCEPT !.openClose = IF settled30.numberOfReturnBitfields >= 4 /\ (settled30.returnBitfield4 # << >> /\ (settled30.returnBitfield4[1] \div 8) % 2 > 0) THEN (IF settled30.openClose = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled30.openClose) ELSE << >>]
        settled32 == [settled31 EXCEPT !.stopPx = IF settled31.numberOfReturnBitfields >= 8 /\ (settled31.returnBitfield8 # << >> /\ (settled31.returnBitfield8[1] \div 4) % 2 > 0) THEN (IF settled31.stopPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled31.stopPx) ELSE << >>]
        settled33 == [settled32 EXCEPT !.cmtaNumber = IF settled32.numberOfReturnBitfields >= 9 /\ (settled32.returnBitfield9 # << >> /\ (settled32.returnBitfield9[1] \div 32) % 2 > 0) THEN (IF settled32.cmtaNumber = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled32.cmtaNumber) ELSE << >>]
        settled34 == [settled33 EXCEPT !.ctiCode = IF settled33.numberOfReturnBitfields >= 12 /\ (settled33.returnBitfield12 # << >> /\ settled33.returnBitfield12[1] % 2 > 0) THEN (IF settled33.ctiCode = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled33.ctiCode) ELSE << >>]
        settled35 == [settled34 EXCEPT !.manualOrderIndicator = IF settled34.numberOfReturnBitfields >= 12 /\ (settled34.returnBitfield12 # << >> /\ (settled34.returnBitfield12[1] \div 2) % 2 > 0) THEN (IF settled34.manualOrderIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled34.manualOrderIndicator) ELSE << >>]
        settled36 == [settled35 EXCEPT !.oeoid = IF settled35.numberOfReturnBitfields >= 12 /\ (settled35.returnBitfield12 # << >> /\ (settled35.returnBitfield12[1] \div 4) % 2 > 0) THEN (IF settled35.oeoid = << >> THEN <<[i \in 1 .. 18 |-> 0]>> ELSE settled35.oeoid) ELSE << >>]
        settled37 == [settled36 EXCEPT !.frequentTraderId = IF settled36.numberOfReturnBitfields >= 16 /\ (settled36.returnBitfield16 # << >> /\ settled36.returnBitfield16[1] % 2 > 0) THEN (IF settled36.frequentTraderId = << >> THEN <<[i \in 1 .. 6 |-> 0]>> ELSE settled36.frequentTraderId) ELSE << >>]
    IN  settled37

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
                                 price                   |-> << >>,
                                 ordType                 |-> << >>,
                                 timeInForce             |-> << >>,
                                 minQty                  |-> << >>,
                                 symbolLong              |-> << >>,
                                 capacity                |-> << >>,
                                 account                 |-> << >>,
                                 clearingFirm            |-> << >>,
                                 clearingAccount         |-> << >>,
                                 orderQty                |-> << >>,
                                 preventMatch            |-> << >>,
                                 maturityDate            |-> << >>,
                                 openClose               |-> << >>,
                                 stopPx                  |-> << >>,
                                 cmtaNumber              |-> << >>,
                                 ctiCode                 |-> << >>,
                                 manualOrderIndicator    |-> << >>,
                                 oeoid                   |-> << >>,
                                 frequentTraderId        |-> << >> ])

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
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 7, !.returnBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 9, !.returnBitfield9 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 10, !.returnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 11, !.returnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 13, !.returnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 14, !.returnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 15, !.returnBitfield15 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 17, !.returnBitfield17 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<1>>, !.side = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<4>>, !.price = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<1>>, !.symbolLong = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<1>>, !.account = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<2>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<4>>, !.clearingAccount = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<64>>, !.orderQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<128>>, !.preventMatch = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<1>>, !.maturityDate = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<8>>, !.openClose = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<4>>, !.stopPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 9, !.returnBitfield9 = <<32>>, !.cmtaNumber = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = <<1>>, !.ctiCode = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = <<2>>, !.manualOrderIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = <<4>>, !.oeoid = one]) : one \in { <<held>> : held \in Sample(18) } }
        \cup { SettleOrderRejectedMessage([ZeroOrderRejectedMessage EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = <<1>>, !.frequentTraderId = one]) : one \in { <<held>> : held \in Sample(6) } }

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
      returnBitfield4         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield5         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield6         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield7         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield8         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield9         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield10        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield11        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield12        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield13        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield14        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield15        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield16        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield17        : { << >> } \cup { <<held>> : held \in Sample(1) },
      side                    : { << >> } \cup { <<held>> : held \in Sample(1) },
      price                   : { << >> } \cup { <<held>> : held \in Sample(8) },
      ordType                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce             : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                  : { << >> } \cup { <<held>> : held \in Sample(4) },
      symbolLong              : { << >> } \cup { <<held>> : held \in Sample(8) },
      capacity                : { << >> } \cup { <<held>> : held \in Sample(1) },
      account                 : { << >> } \cup { <<held>> : held \in Sample(16) },
      clearingFirm            : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingAccount         : { << >> } \cup { <<held>> : held \in Sample(4) },
      orderQty                : { << >> } \cup { <<held>> : held \in Sample(4) },
      preventMatch            : { << >> } \cup { <<held>> : held \in Sample(3) },
      maturityDate            : { << >> } \cup { <<held>> : held \in Sample(4) },
      openClose               : { << >> } \cup { <<held>> : held \in Sample(1) },
      origClOrdId             : { << >> } \cup { <<held>> : held \in Sample(20) },
      leavesQty               : { << >> } \cup { <<held>> : held \in Sample(4) },
      baseLiquidityIndicator  : { << >> } \cup { <<held>> : held \in Sample(1) },
      expireTime              : { << >> } \cup { <<held>> : held \in Sample(8) },
      stopPx                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      cmtaNumber              : { << >> } \cup { <<held>> : held \in Sample(4) },
      ctiCode                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      manualOrderIndicator    : { << >> } \cup { <<held>> : held \in Sample(1) },
      oeoid                   : { << >> } \cup { <<held>> : held \in Sample(18) },
      frequentTraderId        : { << >> } \cup { <<held>> : held \in Sample(6) } ]

EncodeOrderModifiedMessage(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.orderId
        \o message.reserved1
        \o EncodeUIntBE(message.numberOfReturnBitfields, 1)
        \o (IF message.returnBitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield1[1], 1))
        \o (IF message.returnBitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield2[1], 1))
        \o (IF message.returnBitfield3 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield3[1], 1))
        \o (IF message.returnBitfield4 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield4[1], 1))
        \o (IF message.returnBitfield5 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield5[1], 1))
        \o (IF message.returnBitfield6 = << >> THEN << >> ELSE message.returnBitfield6[1])
        \o (IF message.returnBitfield7 = << >> THEN << >> ELSE message.returnBitfield7[1])
        \o (IF message.returnBitfield8 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield8[1], 1))
        \o (IF message.returnBitfield9 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield9[1], 1))
        \o (IF message.returnBitfield10 = << >> THEN << >> ELSE message.returnBitfield10[1])
        \o (IF message.returnBitfield11 = << >> THEN << >> ELSE message.returnBitfield11[1])
        \o (IF message.returnBitfield12 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield12[1], 1))
        \o (IF message.returnBitfield13 = << >> THEN << >> ELSE message.returnBitfield13[1])
        \o (IF message.returnBitfield14 = << >> THEN << >> ELSE message.returnBitfield14[1])
        \o (IF message.returnBitfield15 = << >> THEN << >> ELSE message.returnBitfield15[1])
        \o (IF message.returnBitfield16 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield16[1], 1))
        \o (IF message.returnBitfield17 = << >> THEN << >> ELSE message.returnBitfield17[1])
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

DecodeOrderModifiedMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clOrdId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(orderId.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET numberOfReturnBitfields == ReadUIntBE(reserved1.rest, 1) IN IF ~numberOfReturnBitfields.ok THEN Fail ELSE
    LET returnBitfield1 == ReadWhen(numberOfReturnBitfields.value >= 1, ReadUIntLE(numberOfReturnBitfields.rest, 1), numberOfReturnBitfields.rest) IN IF ~returnBitfield1.ok THEN Fail ELSE
    LET returnBitfield2 == ReadWhen(numberOfReturnBitfields.value >= 2, ReadUIntLE(returnBitfield1.rest, 1), returnBitfield1.rest) IN IF ~returnBitfield2.ok THEN Fail ELSE
    LET returnBitfield3 == ReadWhen(numberOfReturnBitfields.value >= 3, ReadUIntLE(returnBitfield2.rest, 1), returnBitfield2.rest) IN IF ~returnBitfield3.ok THEN Fail ELSE
    LET returnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadUIntLE(returnBitfield3.rest, 1), returnBitfield3.rest) IN IF ~returnBitfield4.ok THEN Fail ELSE
    LET returnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadUIntLE(returnBitfield4.rest, 1), returnBitfield4.rest) IN IF ~returnBitfield5.ok THEN Fail ELSE
    LET returnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadBytes(returnBitfield5.rest, 1), returnBitfield5.rest) IN IF ~returnBitfield6.ok THEN Fail ELSE
    LET returnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadBytes(returnBitfield6.rest, 1), returnBitfield6.rest) IN IF ~returnBitfield7.ok THEN Fail ELSE
    LET returnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadUIntLE(returnBitfield7.rest, 1), returnBitfield7.rest) IN IF ~returnBitfield8.ok THEN Fail ELSE
    LET returnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadUIntLE(returnBitfield8.rest, 1), returnBitfield8.rest) IN IF ~returnBitfield9.ok THEN Fail ELSE
    LET returnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadBytes(returnBitfield9.rest, 1), returnBitfield9.rest) IN IF ~returnBitfield10.ok THEN Fail ELSE
    LET returnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadBytes(returnBitfield10.rest, 1), returnBitfield10.rest) IN IF ~returnBitfield11.ok THEN Fail ELSE
    LET returnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadUIntLE(returnBitfield11.rest, 1), returnBitfield11.rest) IN IF ~returnBitfield12.ok THEN Fail ELSE
    LET returnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(returnBitfield12.rest, 1), returnBitfield12.rest) IN IF ~returnBitfield13.ok THEN Fail ELSE
    LET returnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(returnBitfield13.rest, 1), returnBitfield13.rest) IN IF ~returnBitfield14.ok THEN Fail ELSE
    LET returnBitfield15 == ReadWhen(numberOfReturnBitfields.value >= 15, ReadBytes(returnBitfield14.rest, 1), returnBitfield14.rest) IN IF ~returnBitfield15.ok THEN Fail ELSE
    LET returnBitfield16 == ReadWhen(numberOfReturnBitfields.value >= 16, ReadUIntLE(returnBitfield15.rest, 1), returnBitfield15.rest) IN IF ~returnBitfield16.ok THEN Fail ELSE
    LET returnBitfield17 == ReadWhen(numberOfReturnBitfields.value >= 17, ReadBytes(returnBitfield16.rest, 1), returnBitfield16.rest) IN IF ~returnBitfield17.ok THEN Fail ELSE
    LET side == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ returnBitfield1.value[1] % 2 > 0), ReadBytes(returnBitfield17.rest, 1), returnBitfield17.rest) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(side.rest, 8), side.rest) IN IF ~price.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(price.rest, 1), price.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET symbolLong == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ returnBitfield2.value[1] % 2 > 0), ReadBytes(minQty.rest, 8), minQty.rest) IN IF ~symbolLong.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ (returnBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(symbolLong.rest, 1), symbolLong.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ returnBitfield3.value[1] % 2 > 0), ReadBytes(capacity.rest, 16), capacity.rest) IN IF ~account.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 2) % 2 > 0), ReadBytes(account.rest, 4), account.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 4) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET orderQty == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 64) % 2 > 0), ReadBytes(clearingAccount.rest, 4), clearingAccount.rest) IN IF ~orderQty.ok THEN Fail ELSE
    LET preventMatch == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 128) % 2 > 0), ReadBytes(orderQty.rest, 3), orderQty.rest) IN IF ~preventMatch.ok THEN Fail ELSE
    LET maturityDate == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ returnBitfield4.value[1] % 2 > 0), ReadBytes(preventMatch.rest, 4), preventMatch.rest) IN IF ~maturityDate.ok THEN Fail ELSE
    LET openClose == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ (returnBitfield4.value[1] \div 8) % 2 > 0), ReadBytes(maturityDate.rest, 1), maturityDate.rest) IN IF ~openClose.ok THEN Fail ELSE
    LET origClOrdId == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ returnBitfield5.value[1] % 2 > 0), ReadBytes(openClose.rest, 20), openClose.rest) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET leavesQty == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 2) % 2 > 0), ReadBytes(origClOrdId.rest, 4), origClOrdId.rest) IN IF ~leavesQty.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 64) % 2 > 0), ReadBytes(leavesQty.rest, 1), leavesQty.rest) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET expireTime == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 128) % 2 > 0), ReadBytes(baseLiquidityIndicator.rest, 8), baseLiquidityIndicator.rest) IN IF ~expireTime.ok THEN Fail ELSE
    LET stopPx == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 4) % 2 > 0), ReadBytes(expireTime.rest, 8), expireTime.rest) IN IF ~stopPx.ok THEN Fail ELSE
    LET cmtaNumber == ReadWhen(numberOfReturnBitfields.value >= 9 /\ (returnBitfield9.value # << >> /\ (returnBitfield9.value[1] \div 32) % 2 > 0), ReadBytes(stopPx.rest, 4), stopPx.rest) IN IF ~cmtaNumber.ok THEN Fail ELSE
    LET ctiCode == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (returnBitfield12.value # << >> /\ returnBitfield12.value[1] % 2 > 0), ReadBytes(cmtaNumber.rest, 1), cmtaNumber.rest) IN IF ~ctiCode.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (returnBitfield12.value # << >> /\ (returnBitfield12.value[1] \div 2) % 2 > 0), ReadBytes(ctiCode.rest, 1), ctiCode.rest) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET oeoid == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (returnBitfield12.value # << >> /\ (returnBitfield12.value[1] \div 4) % 2 > 0), ReadBytes(manualOrderIndicator.rest, 18), manualOrderIndicator.rest) IN IF ~oeoid.ok THEN Fail ELSE
    LET frequentTraderId == ReadWhen(numberOfReturnBitfields.value >= 16 /\ (returnBitfield16.value # << >> /\ returnBitfield16.value[1] % 2 > 0), ReadBytes(oeoid.rest, 6), oeoid.rest) IN IF ~frequentTraderId.ok THEN Fail ELSE
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
         price                   |-> price.value,
         ordType                 |-> ordType.value,
         timeInForce             |-> timeInForce.value,
         minQty                  |-> minQty.value,
         symbolLong              |-> symbolLong.value,
         capacity                |-> capacity.value,
         account                 |-> account.value,
         clearingFirm            |-> clearingFirm.value,
         clearingAccount         |-> clearingAccount.value,
         orderQty                |-> orderQty.value,
         preventMatch            |-> preventMatch.value,
         maturityDate            |-> maturityDate.value,
         openClose               |-> openClose.value,
         origClOrdId             |-> origClOrdId.value,
         leavesQty               |-> leavesQty.value,
         baseLiquidityIndicator  |-> baseLiquidityIndicator.value,
         expireTime              |-> expireTime.value,
         stopPx                  |-> stopPx.value,
         cmtaNumber              |-> cmtaNumber.value,
         ctiCode                 |-> ctiCode.value,
         manualOrderIndicator    |-> manualOrderIndicator.value,
         oeoid                   |-> oeoid.value,
         frequentTraderId        |-> frequentTraderId.value ], frequentTraderId.rest)

(* Order Modified Message with each field marked present by fields before it there exactly where they say *)
SettleOrderModifiedMessage(message) ==
    LET settled1 == [message EXCEPT !.returnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.returnBitfield1 = << >> THEN <<0>> ELSE message.returnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.returnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.returnBitfield2 = << >> THEN <<0>> ELSE settled1.returnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.returnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.returnBitfield3 = << >> THEN <<0>> ELSE settled2.returnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.returnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.returnBitfield4 = << >> THEN <<0>> ELSE settled3.returnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.returnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.returnBitfield5 = << >> THEN <<0>> ELSE settled4.returnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.returnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.returnBitfield6 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled5.returnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.returnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.returnBitfield7 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.returnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.returnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.returnBitfield8 = << >> THEN <<0>> ELSE settled7.returnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.returnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.returnBitfield9 = << >> THEN <<0>> ELSE settled8.returnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.returnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.returnBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.returnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.returnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.returnBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.returnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.returnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.returnBitfield12 = << >> THEN <<0>> ELSE settled11.returnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.returnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.returnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.returnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.returnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.returnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.returnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.returnBitfield15 = IF settled14.numberOfReturnBitfields >= 15 THEN (IF settled14.returnBitfield15 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.returnBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.returnBitfield16 = IF settled15.numberOfReturnBitfields >= 16 THEN (IF settled15.returnBitfield16 = << >> THEN <<0>> ELSE settled15.returnBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.returnBitfield17 = IF settled16.numberOfReturnBitfields >= 17 THEN (IF settled16.returnBitfield17 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled16.returnBitfield17) ELSE << >>]
        settled18 == [settled17 EXCEPT !.side = IF settled17.numberOfReturnBitfields >= 1 /\ (settled17.returnBitfield1 # << >> /\ settled17.returnBitfield1[1] % 2 > 0) THEN (IF settled17.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.side) ELSE << >>]
        settled19 == [settled18 EXCEPT !.price = IF settled18.numberOfReturnBitfields >= 1 /\ (settled18.returnBitfield1 # << >> /\ (settled18.returnBitfield1[1] \div 4) % 2 > 0) THEN (IF settled18.price = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled18.price) ELSE << >>]
        settled20 == [settled19 EXCEPT !.ordType = IF settled19.numberOfReturnBitfields >= 1 /\ (settled19.returnBitfield1 # << >> /\ (settled19.returnBitfield1[1] \div 16) % 2 > 0) THEN (IF settled19.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled19.ordType) ELSE << >>]
        settled21 == [settled20 EXCEPT !.timeInForce = IF settled20.numberOfReturnBitfields >= 1 /\ (settled20.returnBitfield1 # << >> /\ (settled20.returnBitfield1[1] \div 32) % 2 > 0) THEN (IF settled20.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled20.timeInForce) ELSE << >>]
        settled22 == [settled21 EXCEPT !.minQty = IF settled21.numberOfReturnBitfields >= 1 /\ (settled21.returnBitfield1 # << >> /\ (settled21.returnBitfield1[1] \div 64) % 2 > 0) THEN (IF settled21.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled21.minQty) ELSE << >>]
        settled23 == [settled22 EXCEPT !.symbolLong = IF settled22.numberOfReturnBitfields >= 2 /\ (settled22.returnBitfield2 # << >> /\ settled22.returnBitfield2[1] % 2 > 0) THEN (IF settled22.symbolLong = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled22.symbolLong) ELSE << >>]
        settled24 == [settled23 EXCEPT !.capacity = IF settled23.numberOfReturnBitfields >= 2 /\ (settled23.returnBitfield2 # << >> /\ (settled23.returnBitfield2[1] \div 64) % 2 > 0) THEN (IF settled23.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled23.capacity) ELSE << >>]
        settled25 == [settled24 EXCEPT !.account = IF settled24.numberOfReturnBitfields >= 3 /\ (settled24.returnBitfield3 # << >> /\ settled24.returnBitfield3[1] % 2 > 0) THEN (IF settled24.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled24.account) ELSE << >>]
        settled26 == [settled25 EXCEPT !.clearingFirm = IF settled25.numberOfReturnBitfields >= 3 /\ (settled25.returnBitfield3 # << >> /\ (settled25.returnBitfield3[1] \div 2) % 2 > 0) THEN (IF settled25.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled25.clearingFirm) ELSE << >>]
        settled27 == [settled26 EXCEPT !.clearingAccount = IF settled26.numberOfReturnBitfields >= 3 /\ (settled26.returnBitfield3 # << >> /\ (settled26.returnBitfield3[1] \div 4) % 2 > 0) THEN (IF settled26.clearingAccount = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled26.clearingAccount) ELSE << >>]
        settled28 == [settled27 EXCEPT !.orderQty = IF settled27.numberOfReturnBitfields >= 3 /\ (settled27.returnBitfield3 # << >> /\ (settled27.returnBitfield3[1] \div 64) % 2 > 0) THEN (IF settled27.orderQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled27.orderQty) ELSE << >>]
        settled29 == [settled28 EXCEPT !.preventMatch = IF settled28.numberOfReturnBitfields >= 3 /\ (settled28.returnBitfield3 # << >> /\ (settled28.returnBitfield3[1] \div 128) % 2 > 0) THEN (IF settled28.preventMatch = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled28.preventMatch) ELSE << >>]
        settled30 == [settled29 EXCEPT !.maturityDate = IF settled29.numberOfReturnBitfields >= 4 /\ (settled29.returnBitfield4 # << >> /\ settled29.returnBitfield4[1] % 2 > 0) THEN (IF settled29.maturityDate = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled29.maturityDate) ELSE << >>]
        settled31 == [settled30 EXCEPT !.openClose = IF settled30.numberOfReturnBitfields >= 4 /\ (settled30.returnBitfield4 # << >> /\ (settled30.returnBitfield4[1] \div 8) % 2 > 0) THEN (IF settled30.openClose = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled30.openClose) ELSE << >>]
        settled32 == [settled31 EXCEPT !.origClOrdId = IF settled31.numberOfReturnBitfields >= 5 /\ (settled31.returnBitfield5 # << >> /\ settled31.returnBitfield5[1] % 2 > 0) THEN (IF settled31.origClOrdId = << >> THEN <<[i \in 1 .. 20 |-> 0]>> ELSE settled31.origClOrdId) ELSE << >>]
        settled33 == [settled32 EXCEPT !.leavesQty = IF settled32.numberOfReturnBitfields >= 5 /\ (settled32.returnBitfield5 # << >> /\ (settled32.returnBitfield5[1] \div 2) % 2 > 0) THEN (IF settled32.leavesQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled32.leavesQty) ELSE << >>]
        settled34 == [settled33 EXCEPT !.baseLiquidityIndicator = IF settled33.numberOfReturnBitfields >= 5 /\ (settled33.returnBitfield5 # << >> /\ (settled33.returnBitfield5[1] \div 64) % 2 > 0) THEN (IF settled33.baseLiquidityIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled33.baseLiquidityIndicator) ELSE << >>]
        settled35 == [settled34 EXCEPT !.expireTime = IF settled34.numberOfReturnBitfields >= 5 /\ (settled34.returnBitfield5 # << >> /\ (settled34.returnBitfield5[1] \div 128) % 2 > 0) THEN (IF settled34.expireTime = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled34.expireTime) ELSE << >>]
        settled36 == [settled35 EXCEPT !.stopPx = IF settled35.numberOfReturnBitfields >= 8 /\ (settled35.returnBitfield8 # << >> /\ (settled35.returnBitfield8[1] \div 4) % 2 > 0) THEN (IF settled35.stopPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled35.stopPx) ELSE << >>]
        settled37 == [settled36 EXCEPT !.cmtaNumber = IF settled36.numberOfReturnBitfields >= 9 /\ (settled36.returnBitfield9 # << >> /\ (settled36.returnBitfield9[1] \div 32) % 2 > 0) THEN (IF settled36.cmtaNumber = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled36.cmtaNumber) ELSE << >>]
        settled38 == [settled37 EXCEPT !.ctiCode = IF settled37.numberOfReturnBitfields >= 12 /\ (settled37.returnBitfield12 # << >> /\ settled37.returnBitfield12[1] % 2 > 0) THEN (IF settled37.ctiCode = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled37.ctiCode) ELSE << >>]
        settled39 == [settled38 EXCEPT !.manualOrderIndicator = IF settled38.numberOfReturnBitfields >= 12 /\ (settled38.returnBitfield12 # << >> /\ (settled38.returnBitfield12[1] \div 2) % 2 > 0) THEN (IF settled38.manualOrderIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled38.manualOrderIndicator) ELSE << >>]
        settled40 == [settled39 EXCEPT !.oeoid = IF settled39.numberOfReturnBitfields >= 12 /\ (settled39.returnBitfield12 # << >> /\ (settled39.returnBitfield12[1] \div 4) % 2 > 0) THEN (IF settled39.oeoid = << >> THEN <<[i \in 1 .. 18 |-> 0]>> ELSE settled39.oeoid) ELSE << >>]
        settled41 == [settled40 EXCEPT !.frequentTraderId = IF settled40.numberOfReturnBitfields >= 16 /\ (settled40.returnBitfield16 # << >> /\ settled40.returnBitfield16[1] % 2 > 0) THEN (IF settled40.frequentTraderId = << >> THEN <<[i \in 1 .. 6 |-> 0]>> ELSE settled40.frequentTraderId) ELSE << >>]
    IN  settled41

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
                                 price                   |-> << >>,
                                 ordType                 |-> << >>,
                                 timeInForce             |-> << >>,
                                 minQty                  |-> << >>,
                                 symbolLong              |-> << >>,
                                 capacity                |-> << >>,
                                 account                 |-> << >>,
                                 clearingFirm            |-> << >>,
                                 clearingAccount         |-> << >>,
                                 orderQty                |-> << >>,
                                 preventMatch            |-> << >>,
                                 maturityDate            |-> << >>,
                                 openClose               |-> << >>,
                                 origClOrdId             |-> << >>,
                                 leavesQty               |-> << >>,
                                 baseLiquidityIndicator  |-> << >>,
                                 expireTime              |-> << >>,
                                 stopPx                  |-> << >>,
                                 cmtaNumber              |-> << >>,
                                 ctiCode                 |-> << >>,
                                 manualOrderIndicator    |-> << >>,
                                 oeoid                   |-> << >>,
                                 frequentTraderId        |-> << >> ])

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
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 7, !.returnBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 9, !.returnBitfield9 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 10, !.returnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 11, !.returnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 13, !.returnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 14, !.returnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 15, !.returnBitfield15 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 17, !.returnBitfield17 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<1>>, !.side = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<4>>, !.price = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<1>>, !.symbolLong = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<1>>, !.account = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<2>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<4>>, !.clearingAccount = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<64>>, !.orderQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<128>>, !.preventMatch = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<1>>, !.maturityDate = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<8>>, !.openClose = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<1>>, !.origClOrdId = one]) : one \in { <<held>> : held \in Sample(20) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<2>>, !.leavesQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<64>>, !.baseLiquidityIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<128>>, !.expireTime = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<4>>, !.stopPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 9, !.returnBitfield9 = <<32>>, !.cmtaNumber = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = <<1>>, !.ctiCode = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = <<2>>, !.manualOrderIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = <<4>>, !.oeoid = one]) : one \in { <<held>> : held \in Sample(18) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = <<1>>, !.frequentTraderId = one]) : one \in { <<held>> : held \in Sample(6) } }

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
    [ transactionTime         : Sample(8),
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
      returnBitfield12        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield13        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield14        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield15        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield16        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield17        : { << >> } \cup { <<held>> : held \in Sample(1) },
      side                    : { << >> } \cup { <<held>> : held \in Sample(1) },
      price                   : { << >> } \cup { <<held>> : held \in Sample(8) },
      ordType                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce             : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                  : { << >> } \cup { <<held>> : held \in Sample(4) },
      symbolLong              : { << >> } \cup { <<held>> : held \in Sample(8) },
      capacity                : { << >> } \cup { <<held>> : held \in Sample(1) },
      account                 : { << >> } \cup { <<held>> : held \in Sample(16) },
      clearingFirm            : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingAccount         : { << >> } \cup { <<held>> : held \in Sample(4) },
      orderQty                : { << >> } \cup { <<held>> : held \in Sample(4) },
      preventMatch            : { << >> } \cup { <<held>> : held \in Sample(3) },
      maturityDate            : { << >> } \cup { <<held>> : held \in Sample(4) },
      openClose               : { << >> } \cup { <<held>> : held \in Sample(1) },
      origClOrdId             : { << >> } \cup { <<held>> : held \in Sample(20) },
      leavesQty               : { << >> } \cup { <<held>> : held \in Sample(4) },
      lastShares              : { << >> } \cup { <<held>> : held \in Sample(4) },
      lastPx                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      expireTime              : { << >> } \cup { <<held>> : held \in Sample(8) },
      secondaryOrderId        : { << >> } \cup { <<held>> : held \in Sample(8) },
      stopPx                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      cmtaNumber              : { << >> } \cup { <<held>> : held \in Sample(4) },
      ctiCode                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      manualOrderIndicator    : { << >> } \cup { <<held>> : held \in Sample(1) },
      oeoid                   : { << >> } \cup { <<held>> : held \in Sample(18) },
      frequentTraderId        : { << >> } \cup { <<held>> : held \in Sample(6) } ]

EncodeOrderCancelledMessage(message) ==
    message.transactionTime
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
        \o (IF message.returnBitfield12 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield12[1], 1))
        \o (IF message.returnBitfield13 = << >> THEN << >> ELSE message.returnBitfield13[1])
        \o (IF message.returnBitfield14 = << >> THEN << >> ELSE message.returnBitfield14[1])
        \o (IF message.returnBitfield15 = << >> THEN << >> ELSE message.returnBitfield15[1])
        \o (IF message.returnBitfield16 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield16[1], 1))
        \o (IF message.returnBitfield17 = << >> THEN << >> ELSE message.returnBitfield17[1])
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

DecodeOrderCancelledMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
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
    LET returnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadUIntLE(returnBitfield11.rest, 1), returnBitfield11.rest) IN IF ~returnBitfield12.ok THEN Fail ELSE
    LET returnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(returnBitfield12.rest, 1), returnBitfield12.rest) IN IF ~returnBitfield13.ok THEN Fail ELSE
    LET returnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(returnBitfield13.rest, 1), returnBitfield13.rest) IN IF ~returnBitfield14.ok THEN Fail ELSE
    LET returnBitfield15 == ReadWhen(numberOfReturnBitfields.value >= 15, ReadBytes(returnBitfield14.rest, 1), returnBitfield14.rest) IN IF ~returnBitfield15.ok THEN Fail ELSE
    LET returnBitfield16 == ReadWhen(numberOfReturnBitfields.value >= 16, ReadUIntLE(returnBitfield15.rest, 1), returnBitfield15.rest) IN IF ~returnBitfield16.ok THEN Fail ELSE
    LET returnBitfield17 == ReadWhen(numberOfReturnBitfields.value >= 17, ReadBytes(returnBitfield16.rest, 1), returnBitfield16.rest) IN IF ~returnBitfield17.ok THEN Fail ELSE
    LET side == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ returnBitfield1.value[1] % 2 > 0), ReadBytes(returnBitfield17.rest, 1), returnBitfield17.rest) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(side.rest, 8), side.rest) IN IF ~price.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(price.rest, 1), price.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET symbolLong == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ returnBitfield2.value[1] % 2 > 0), ReadBytes(minQty.rest, 8), minQty.rest) IN IF ~symbolLong.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ (returnBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(symbolLong.rest, 1), symbolLong.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ returnBitfield3.value[1] % 2 > 0), ReadBytes(capacity.rest, 16), capacity.rest) IN IF ~account.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 2) % 2 > 0), ReadBytes(account.rest, 4), account.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 4) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET orderQty == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 64) % 2 > 0), ReadBytes(clearingAccount.rest, 4), clearingAccount.rest) IN IF ~orderQty.ok THEN Fail ELSE
    LET preventMatch == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 128) % 2 > 0), ReadBytes(orderQty.rest, 3), orderQty.rest) IN IF ~preventMatch.ok THEN Fail ELSE
    LET maturityDate == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ returnBitfield4.value[1] % 2 > 0), ReadBytes(preventMatch.rest, 4), preventMatch.rest) IN IF ~maturityDate.ok THEN Fail ELSE
    LET openClose == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ (returnBitfield4.value[1] \div 8) % 2 > 0), ReadBytes(maturityDate.rest, 1), maturityDate.rest) IN IF ~openClose.ok THEN Fail ELSE
    LET origClOrdId == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ returnBitfield5.value[1] % 2 > 0), ReadBytes(openClose.rest, 20), openClose.rest) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET leavesQty == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 2) % 2 > 0), ReadBytes(origClOrdId.rest, 4), origClOrdId.rest) IN IF ~leavesQty.ok THEN Fail ELSE
    LET lastShares == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 4) % 2 > 0), ReadBytes(leavesQty.rest, 4), leavesQty.rest) IN IF ~lastShares.ok THEN Fail ELSE
    LET lastPx == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 8) % 2 > 0), ReadBytes(lastShares.rest, 8), lastShares.rest) IN IF ~lastPx.ok THEN Fail ELSE
    LET expireTime == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 128) % 2 > 0), ReadBytes(lastPx.rest, 8), lastPx.rest) IN IF ~expireTime.ok THEN Fail ELSE
    LET secondaryOrderId == ReadWhen(numberOfReturnBitfields.value >= 6 /\ (returnBitfield6.value # << >> /\ returnBitfield6.value[1] % 2 > 0), ReadBytes(expireTime.rest, 8), expireTime.rest) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET stopPx == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 4) % 2 > 0), ReadBytes(secondaryOrderId.rest, 8), secondaryOrderId.rest) IN IF ~stopPx.ok THEN Fail ELSE
    LET cmtaNumber == ReadWhen(numberOfReturnBitfields.value >= 9 /\ (returnBitfield9.value # << >> /\ (returnBitfield9.value[1] \div 32) % 2 > 0), ReadBytes(stopPx.rest, 4), stopPx.rest) IN IF ~cmtaNumber.ok THEN Fail ELSE
    LET ctiCode == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (returnBitfield12.value # << >> /\ returnBitfield12.value[1] % 2 > 0), ReadBytes(cmtaNumber.rest, 1), cmtaNumber.rest) IN IF ~ctiCode.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (returnBitfield12.value # << >> /\ (returnBitfield12.value[1] \div 2) % 2 > 0), ReadBytes(ctiCode.rest, 1), ctiCode.rest) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET oeoid == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (returnBitfield12.value # << >> /\ (returnBitfield12.value[1] \div 4) % 2 > 0), ReadBytes(manualOrderIndicator.rest, 18), manualOrderIndicator.rest) IN IF ~oeoid.ok THEN Fail ELSE
    LET frequentTraderId == ReadWhen(numberOfReturnBitfields.value >= 16 /\ (returnBitfield16.value # << >> /\ returnBitfield16.value[1] % 2 > 0), ReadBytes(oeoid.rest, 6), oeoid.rest) IN IF ~frequentTraderId.ok THEN Fail ELSE
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
         side                    |-> side.value,
         price                   |-> price.value,
         ordType                 |-> ordType.value,
         timeInForce             |-> timeInForce.value,
         minQty                  |-> minQty.value,
         symbolLong              |-> symbolLong.value,
         capacity                |-> capacity.value,
         account                 |-> account.value,
         clearingFirm            |-> clearingFirm.value,
         clearingAccount         |-> clearingAccount.value,
         orderQty                |-> orderQty.value,
         preventMatch            |-> preventMatch.value,
         maturityDate            |-> maturityDate.value,
         openClose               |-> openClose.value,
         origClOrdId             |-> origClOrdId.value,
         leavesQty               |-> leavesQty.value,
         lastShares              |-> lastShares.value,
         lastPx                  |-> lastPx.value,
         expireTime              |-> expireTime.value,
         secondaryOrderId        |-> secondaryOrderId.value,
         stopPx                  |-> stopPx.value,
         cmtaNumber              |-> cmtaNumber.value,
         ctiCode                 |-> ctiCode.value,
         manualOrderIndicator    |-> manualOrderIndicator.value,
         oeoid                   |-> oeoid.value,
         frequentTraderId        |-> frequentTraderId.value ], frequentTraderId.rest)

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
        settled12 == [settled11 EXCEPT !.returnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.returnBitfield12 = << >> THEN <<0>> ELSE settled11.returnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.returnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.returnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.returnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.returnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.returnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.returnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.returnBitfield15 = IF settled14.numberOfReturnBitfields >= 15 THEN (IF settled14.returnBitfield15 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.returnBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.returnBitfield16 = IF settled15.numberOfReturnBitfields >= 16 THEN (IF settled15.returnBitfield16 = << >> THEN <<0>> ELSE settled15.returnBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.returnBitfield17 = IF settled16.numberOfReturnBitfields >= 17 THEN (IF settled16.returnBitfield17 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled16.returnBitfield17) ELSE << >>]
        settled18 == [settled17 EXCEPT !.side = IF settled17.numberOfReturnBitfields >= 1 /\ (settled17.returnBitfield1 # << >> /\ settled17.returnBitfield1[1] % 2 > 0) THEN (IF settled17.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.side) ELSE << >>]
        settled19 == [settled18 EXCEPT !.price = IF settled18.numberOfReturnBitfields >= 1 /\ (settled18.returnBitfield1 # << >> /\ (settled18.returnBitfield1[1] \div 4) % 2 > 0) THEN (IF settled18.price = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled18.price) ELSE << >>]
        settled20 == [settled19 EXCEPT !.ordType = IF settled19.numberOfReturnBitfields >= 1 /\ (settled19.returnBitfield1 # << >> /\ (settled19.returnBitfield1[1] \div 16) % 2 > 0) THEN (IF settled19.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled19.ordType) ELSE << >>]
        settled21 == [settled20 EXCEPT !.timeInForce = IF settled20.numberOfReturnBitfields >= 1 /\ (settled20.returnBitfield1 # << >> /\ (settled20.returnBitfield1[1] \div 32) % 2 > 0) THEN (IF settled20.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled20.timeInForce) ELSE << >>]
        settled22 == [settled21 EXCEPT !.minQty = IF settled21.numberOfReturnBitfields >= 1 /\ (settled21.returnBitfield1 # << >> /\ (settled21.returnBitfield1[1] \div 64) % 2 > 0) THEN (IF settled21.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled21.minQty) ELSE << >>]
        settled23 == [settled22 EXCEPT !.symbolLong = IF settled22.numberOfReturnBitfields >= 2 /\ (settled22.returnBitfield2 # << >> /\ settled22.returnBitfield2[1] % 2 > 0) THEN (IF settled22.symbolLong = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled22.symbolLong) ELSE << >>]
        settled24 == [settled23 EXCEPT !.capacity = IF settled23.numberOfReturnBitfields >= 2 /\ (settled23.returnBitfield2 # << >> /\ (settled23.returnBitfield2[1] \div 64) % 2 > 0) THEN (IF settled23.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled23.capacity) ELSE << >>]
        settled25 == [settled24 EXCEPT !.account = IF settled24.numberOfReturnBitfields >= 3 /\ (settled24.returnBitfield3 # << >> /\ settled24.returnBitfield3[1] % 2 > 0) THEN (IF settled24.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled24.account) ELSE << >>]
        settled26 == [settled25 EXCEPT !.clearingFirm = IF settled25.numberOfReturnBitfields >= 3 /\ (settled25.returnBitfield3 # << >> /\ (settled25.returnBitfield3[1] \div 2) % 2 > 0) THEN (IF settled25.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled25.clearingFirm) ELSE << >>]
        settled27 == [settled26 EXCEPT !.clearingAccount = IF settled26.numberOfReturnBitfields >= 3 /\ (settled26.returnBitfield3 # << >> /\ (settled26.returnBitfield3[1] \div 4) % 2 > 0) THEN (IF settled26.clearingAccount = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled26.clearingAccount) ELSE << >>]
        settled28 == [settled27 EXCEPT !.orderQty = IF settled27.numberOfReturnBitfields >= 3 /\ (settled27.returnBitfield3 # << >> /\ (settled27.returnBitfield3[1] \div 64) % 2 > 0) THEN (IF settled27.orderQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled27.orderQty) ELSE << >>]
        settled29 == [settled28 EXCEPT !.preventMatch = IF settled28.numberOfReturnBitfields >= 3 /\ (settled28.returnBitfield3 # << >> /\ (settled28.returnBitfield3[1] \div 128) % 2 > 0) THEN (IF settled28.preventMatch = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled28.preventMatch) ELSE << >>]
        settled30 == [settled29 EXCEPT !.maturityDate = IF settled29.numberOfReturnBitfields >= 4 /\ (settled29.returnBitfield4 # << >> /\ settled29.returnBitfield4[1] % 2 > 0) THEN (IF settled29.maturityDate = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled29.maturityDate) ELSE << >>]
        settled31 == [settled30 EXCEPT !.openClose = IF settled30.numberOfReturnBitfields >= 4 /\ (settled30.returnBitfield4 # << >> /\ (settled30.returnBitfield4[1] \div 8) % 2 > 0) THEN (IF settled30.openClose = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled30.openClose) ELSE << >>]
        settled32 == [settled31 EXCEPT !.origClOrdId = IF settled31.numberOfReturnBitfields >= 5 /\ (settled31.returnBitfield5 # << >> /\ settled31.returnBitfield5[1] % 2 > 0) THEN (IF settled31.origClOrdId = << >> THEN <<[i \in 1 .. 20 |-> 0]>> ELSE settled31.origClOrdId) ELSE << >>]
        settled33 == [settled32 EXCEPT !.leavesQty = IF settled32.numberOfReturnBitfields >= 5 /\ (settled32.returnBitfield5 # << >> /\ (settled32.returnBitfield5[1] \div 2) % 2 > 0) THEN (IF settled32.leavesQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled32.leavesQty) ELSE << >>]
        settled34 == [settled33 EXCEPT !.lastShares = IF settled33.numberOfReturnBitfields >= 5 /\ (settled33.returnBitfield5 # << >> /\ (settled33.returnBitfield5[1] \div 4) % 2 > 0) THEN (IF settled33.lastShares = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled33.lastShares) ELSE << >>]
        settled35 == [settled34 EXCEPT !.lastPx = IF settled34.numberOfReturnBitfields >= 5 /\ (settled34.returnBitfield5 # << >> /\ (settled34.returnBitfield5[1] \div 8) % 2 > 0) THEN (IF settled34.lastPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled34.lastPx) ELSE << >>]
        settled36 == [settled35 EXCEPT !.expireTime = IF settled35.numberOfReturnBitfields >= 5 /\ (settled35.returnBitfield5 # << >> /\ (settled35.returnBitfield5[1] \div 128) % 2 > 0) THEN (IF settled35.expireTime = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled35.expireTime) ELSE << >>]
        settled37 == [settled36 EXCEPT !.secondaryOrderId = IF settled36.numberOfReturnBitfields >= 6 /\ (settled36.returnBitfield6 # << >> /\ settled36.returnBitfield6[1] % 2 > 0) THEN (IF settled36.secondaryOrderId = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled36.secondaryOrderId) ELSE << >>]
        settled38 == [settled37 EXCEPT !.stopPx = IF settled37.numberOfReturnBitfields >= 8 /\ (settled37.returnBitfield8 # << >> /\ (settled37.returnBitfield8[1] \div 4) % 2 > 0) THEN (IF settled37.stopPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled37.stopPx) ELSE << >>]
        settled39 == [settled38 EXCEPT !.cmtaNumber = IF settled38.numberOfReturnBitfields >= 9 /\ (settled38.returnBitfield9 # << >> /\ (settled38.returnBitfield9[1] \div 32) % 2 > 0) THEN (IF settled38.cmtaNumber = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled38.cmtaNumber) ELSE << >>]
        settled40 == [settled39 EXCEPT !.ctiCode = IF settled39.numberOfReturnBitfields >= 12 /\ (settled39.returnBitfield12 # << >> /\ settled39.returnBitfield12[1] % 2 > 0) THEN (IF settled39.ctiCode = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled39.ctiCode) ELSE << >>]
        settled41 == [settled40 EXCEPT !.manualOrderIndicator = IF settled40.numberOfReturnBitfields >= 12 /\ (settled40.returnBitfield12 # << >> /\ (settled40.returnBitfield12[1] \div 2) % 2 > 0) THEN (IF settled40.manualOrderIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled40.manualOrderIndicator) ELSE << >>]
        settled42 == [settled41 EXCEPT !.oeoid = IF settled41.numberOfReturnBitfields >= 12 /\ (settled41.returnBitfield12 # << >> /\ (settled41.returnBitfield12[1] \div 4) % 2 > 0) THEN (IF settled41.oeoid = << >> THEN <<[i \in 1 .. 18 |-> 0]>> ELSE settled41.oeoid) ELSE << >>]
        settled43 == [settled42 EXCEPT !.frequentTraderId = IF settled42.numberOfReturnBitfields >= 16 /\ (settled42.returnBitfield16 # << >> /\ settled42.returnBitfield16[1] % 2 > 0) THEN (IF settled42.frequentTraderId = << >> THEN <<[i \in 1 .. 6 |-> 0]>> ELSE settled42.frequentTraderId) ELSE << >>]
    IN  settled43

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
                                  side                    |-> << >>,
                                  price                   |-> << >>,
                                  ordType                 |-> << >>,
                                  timeInForce             |-> << >>,
                                  minQty                  |-> << >>,
                                  symbolLong              |-> << >>,
                                  capacity                |-> << >>,
                                  account                 |-> << >>,
                                  clearingFirm            |-> << >>,
                                  clearingAccount         |-> << >>,
                                  orderQty                |-> << >>,
                                  preventMatch            |-> << >>,
                                  maturityDate            |-> << >>,
                                  openClose               |-> << >>,
                                  origClOrdId             |-> << >>,
                                  leavesQty               |-> << >>,
                                  lastShares              |-> << >>,
                                  lastPx                  |-> << >>,
                                  expireTime              |-> << >>,
                                  secondaryOrderId        |-> << >>,
                                  stopPx                  |-> << >>,
                                  cmtaNumber              |-> << >>,
                                  ctiCode                 |-> << >>,
                                  manualOrderIndicator    |-> << >>,
                                  oeoid                   |-> << >>,
                                  frequentTraderId        |-> << >> ])

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
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 7, !.returnBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 9, !.returnBitfield9 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 10, !.returnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 11, !.returnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 13, !.returnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 14, !.returnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 15, !.returnBitfield15 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 17, !.returnBitfield17 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<1>>, !.side = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<4>>, !.price = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<1>>, !.symbolLong = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<1>>, !.account = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<2>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<4>>, !.clearingAccount = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<64>>, !.orderQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<128>>, !.preventMatch = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<1>>, !.maturityDate = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<8>>, !.openClose = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<1>>, !.origClOrdId = one]) : one \in { <<held>> : held \in Sample(20) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<2>>, !.leavesQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<4>>, !.lastShares = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<8>>, !.lastPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<128>>, !.expireTime = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = <<1>>, !.secondaryOrderId = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<4>>, !.stopPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 9, !.returnBitfield9 = <<32>>, !.cmtaNumber = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = <<1>>, !.ctiCode = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = <<2>>, !.manualOrderIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = <<4>>, !.oeoid = one]) : one \in { <<held>> : held \in Sample(18) } }
        \cup { SettleOrderCancelledMessage([ZeroOrderCancelledMessage EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = <<1>>, !.frequentTraderId = one]) : one \in { <<held>> : held \in Sample(6) } }

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
      returnBitfield5         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield6         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield7         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield8         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield9         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield10        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield11        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield12        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield13        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield14        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield15        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield16        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield17        : { << >> } \cup { <<held>> : held \in Sample(1) },
      side                    : { << >> } \cup { <<held>> : held \in Sample(1) },
      price                   : { << >> } \cup { <<held>> : held \in Sample(8) },
      ordType                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce             : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                  : { << >> } \cup { <<held>> : held \in Sample(4) },
      symbolLong              : { << >> } \cup { <<held>> : held \in Sample(8) },
      capacity                : { << >> } \cup { <<held>> : held \in Sample(1) },
      maturityDate            : { << >> } \cup { <<held>> : held \in Sample(4) },
      openClose               : { << >> } \cup { <<held>> : held \in Sample(1) },
      expireTime              : { << >> } \cup { <<held>> : held \in Sample(8) },
      stopPx                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      cmtaNumber              : { << >> } \cup { <<held>> : held \in Sample(4) },
      ctiCode                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      manualOrderIndicator    : { << >> } \cup { <<held>> : held \in Sample(1) },
      oeoid                   : { << >> } \cup { <<held>> : held \in Sample(18) } ]

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
        \o (IF message.returnBitfield5 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield5[1], 1))
        \o (IF message.returnBitfield6 = << >> THEN << >> ELSE message.returnBitfield6[1])
        \o (IF message.returnBitfield7 = << >> THEN << >> ELSE message.returnBitfield7[1])
        \o (IF message.returnBitfield8 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield8[1], 1))
        \o (IF message.returnBitfield9 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield9[1], 1))
        \o (IF message.returnBitfield10 = << >> THEN << >> ELSE message.returnBitfield10[1])
        \o (IF message.returnBitfield11 = << >> THEN << >> ELSE message.returnBitfield11[1])
        \o (IF message.returnBitfield12 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield12[1], 1))
        \o (IF message.returnBitfield13 = << >> THEN << >> ELSE message.returnBitfield13[1])
        \o (IF message.returnBitfield14 = << >> THEN << >> ELSE message.returnBitfield14[1])
        \o (IF message.returnBitfield15 = << >> THEN << >> ELSE message.returnBitfield15[1])
        \o (IF message.returnBitfield16 = << >> THEN << >> ELSE message.returnBitfield16[1])
        \o (IF message.returnBitfield17 = << >> THEN << >> ELSE message.returnBitfield17[1])
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
    LET returnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadUIntLE(returnBitfield4.rest, 1), returnBitfield4.rest) IN IF ~returnBitfield5.ok THEN Fail ELSE
    LET returnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadBytes(returnBitfield5.rest, 1), returnBitfield5.rest) IN IF ~returnBitfield6.ok THEN Fail ELSE
    LET returnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadBytes(returnBitfield6.rest, 1), returnBitfield6.rest) IN IF ~returnBitfield7.ok THEN Fail ELSE
    LET returnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadUIntLE(returnBitfield7.rest, 1), returnBitfield7.rest) IN IF ~returnBitfield8.ok THEN Fail ELSE
    LET returnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadUIntLE(returnBitfield8.rest, 1), returnBitfield8.rest) IN IF ~returnBitfield9.ok THEN Fail ELSE
    LET returnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadBytes(returnBitfield9.rest, 1), returnBitfield9.rest) IN IF ~returnBitfield10.ok THEN Fail ELSE
    LET returnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadBytes(returnBitfield10.rest, 1), returnBitfield10.rest) IN IF ~returnBitfield11.ok THEN Fail ELSE
    LET returnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadUIntLE(returnBitfield11.rest, 1), returnBitfield11.rest) IN IF ~returnBitfield12.ok THEN Fail ELSE
    LET returnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadBytes(returnBitfield12.rest, 1), returnBitfield12.rest) IN IF ~returnBitfield13.ok THEN Fail ELSE
    LET returnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadBytes(returnBitfield13.rest, 1), returnBitfield13.rest) IN IF ~returnBitfield14.ok THEN Fail ELSE
    LET returnBitfield15 == ReadWhen(numberOfReturnBitfields.value >= 15, ReadBytes(returnBitfield14.rest, 1), returnBitfield14.rest) IN IF ~returnBitfield15.ok THEN Fail ELSE
    LET returnBitfield16 == ReadWhen(numberOfReturnBitfields.value >= 16, ReadBytes(returnBitfield15.rest, 1), returnBitfield15.rest) IN IF ~returnBitfield16.ok THEN Fail ELSE
    LET returnBitfield17 == ReadWhen(numberOfReturnBitfields.value >= 17, ReadBytes(returnBitfield16.rest, 1), returnBitfield16.rest) IN IF ~returnBitfield17.ok THEN Fail ELSE
    LET side == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ returnBitfield1.value[1] % 2 > 0), ReadBytes(returnBitfield17.rest, 1), returnBitfield17.rest) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(side.rest, 8), side.rest) IN IF ~price.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(price.rest, 1), price.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET symbolLong == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ returnBitfield2.value[1] % 2 > 0), ReadBytes(minQty.rest, 8), minQty.rest) IN IF ~symbolLong.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ (returnBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(symbolLong.rest, 1), symbolLong.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET maturityDate == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ returnBitfield4.value[1] % 2 > 0), ReadBytes(capacity.rest, 4), capacity.rest) IN IF ~maturityDate.ok THEN Fail ELSE
    LET openClose == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ (returnBitfield4.value[1] \div 8) % 2 > 0), ReadBytes(maturityDate.rest, 1), maturityDate.rest) IN IF ~openClose.ok THEN Fail ELSE
    LET expireTime == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 128) % 2 > 0), ReadBytes(openClose.rest, 8), openClose.rest) IN IF ~expireTime.ok THEN Fail ELSE
    LET stopPx == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 4) % 2 > 0), ReadBytes(expireTime.rest, 8), expireTime.rest) IN IF ~stopPx.ok THEN Fail ELSE
    LET cmtaNumber == ReadWhen(numberOfReturnBitfields.value >= 9 /\ (returnBitfield9.value # << >> /\ (returnBitfield9.value[1] \div 32) % 2 > 0), ReadBytes(stopPx.rest, 4), stopPx.rest) IN IF ~cmtaNumber.ok THEN Fail ELSE
    LET ctiCode == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (returnBitfield12.value # << >> /\ returnBitfield12.value[1] % 2 > 0), ReadBytes(cmtaNumber.rest, 1), cmtaNumber.rest) IN IF ~ctiCode.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (returnBitfield12.value # << >> /\ (returnBitfield12.value[1] \div 2) % 2 > 0), ReadBytes(ctiCode.rest, 1), ctiCode.rest) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET oeoid == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (returnBitfield12.value # << >> /\ (returnBitfield12.value[1] \div 4) % 2 > 0), ReadBytes(manualOrderIndicator.rest, 18), manualOrderIndicator.rest) IN IF ~oeoid.ok THEN Fail ELSE
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
         price                   |-> price.value,
         ordType                 |-> ordType.value,
         timeInForce             |-> timeInForce.value,
         minQty                  |-> minQty.value,
         symbolLong              |-> symbolLong.value,
         capacity                |-> capacity.value,
         maturityDate            |-> maturityDate.value,
         openClose               |-> openClose.value,
         expireTime              |-> expireTime.value,
         stopPx                  |-> stopPx.value,
         cmtaNumber              |-> cmtaNumber.value,
         ctiCode                 |-> ctiCode.value,
         manualOrderIndicator    |-> manualOrderIndicator.value,
         oeoid                   |-> oeoid.value ], oeoid.rest)

(* Cancel Rejected Message with each field marked present by fields before it there exactly where they say *)
SettleCancelRejectedMessage(message) ==
    LET settled1 == [message EXCEPT !.returnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.returnBitfield1 = << >> THEN <<0>> ELSE message.returnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.returnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.returnBitfield2 = << >> THEN <<0>> ELSE settled1.returnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.returnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.returnBitfield3 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled2.returnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.returnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.returnBitfield4 = << >> THEN <<0>> ELSE settled3.returnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.returnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.returnBitfield5 = << >> THEN <<0>> ELSE settled4.returnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.returnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.returnBitfield6 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled5.returnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.returnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.returnBitfield7 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.returnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.returnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.returnBitfield8 = << >> THEN <<0>> ELSE settled7.returnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.returnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.returnBitfield9 = << >> THEN <<0>> ELSE settled8.returnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.returnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.returnBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.returnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.returnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.returnBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.returnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.returnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.returnBitfield12 = << >> THEN <<0>> ELSE settled11.returnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.returnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.returnBitfield13 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled12.returnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.returnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.returnBitfield14 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled13.returnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.returnBitfield15 = IF settled14.numberOfReturnBitfields >= 15 THEN (IF settled14.returnBitfield15 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.returnBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.returnBitfield16 = IF settled15.numberOfReturnBitfields >= 16 THEN (IF settled15.returnBitfield16 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled15.returnBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.returnBitfield17 = IF settled16.numberOfReturnBitfields >= 17 THEN (IF settled16.returnBitfield17 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled16.returnBitfield17) ELSE << >>]
        settled18 == [settled17 EXCEPT !.side = IF settled17.numberOfReturnBitfields >= 1 /\ (settled17.returnBitfield1 # << >> /\ settled17.returnBitfield1[1] % 2 > 0) THEN (IF settled17.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.side) ELSE << >>]
        settled19 == [settled18 EXCEPT !.price = IF settled18.numberOfReturnBitfields >= 1 /\ (settled18.returnBitfield1 # << >> /\ (settled18.returnBitfield1[1] \div 4) % 2 > 0) THEN (IF settled18.price = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled18.price) ELSE << >>]
        settled20 == [settled19 EXCEPT !.ordType = IF settled19.numberOfReturnBitfields >= 1 /\ (settled19.returnBitfield1 # << >> /\ (settled19.returnBitfield1[1] \div 16) % 2 > 0) THEN (IF settled19.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled19.ordType) ELSE << >>]
        settled21 == [settled20 EXCEPT !.timeInForce = IF settled20.numberOfReturnBitfields >= 1 /\ (settled20.returnBitfield1 # << >> /\ (settled20.returnBitfield1[1] \div 32) % 2 > 0) THEN (IF settled20.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled20.timeInForce) ELSE << >>]
        settled22 == [settled21 EXCEPT !.minQty = IF settled21.numberOfReturnBitfields >= 1 /\ (settled21.returnBitfield1 # << >> /\ (settled21.returnBitfield1[1] \div 64) % 2 > 0) THEN (IF settled21.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled21.minQty) ELSE << >>]
        settled23 == [settled22 EXCEPT !.symbolLong = IF settled22.numberOfReturnBitfields >= 2 /\ (settled22.returnBitfield2 # << >> /\ settled22.returnBitfield2[1] % 2 > 0) THEN (IF settled22.symbolLong = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled22.symbolLong) ELSE << >>]
        settled24 == [settled23 EXCEPT !.capacity = IF settled23.numberOfReturnBitfields >= 2 /\ (settled23.returnBitfield2 # << >> /\ (settled23.returnBitfield2[1] \div 64) % 2 > 0) THEN (IF settled23.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled23.capacity) ELSE << >>]
        settled25 == [settled24 EXCEPT !.maturityDate = IF settled24.numberOfReturnBitfields >= 4 /\ (settled24.returnBitfield4 # << >> /\ settled24.returnBitfield4[1] % 2 > 0) THEN (IF settled24.maturityDate = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled24.maturityDate) ELSE << >>]
        settled26 == [settled25 EXCEPT !.openClose = IF settled25.numberOfReturnBitfields >= 4 /\ (settled25.returnBitfield4 # << >> /\ (settled25.returnBitfield4[1] \div 8) % 2 > 0) THEN (IF settled25.openClose = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled25.openClose) ELSE << >>]
        settled27 == [settled26 EXCEPT !.expireTime = IF settled26.numberOfReturnBitfields >= 5 /\ (settled26.returnBitfield5 # << >> /\ (settled26.returnBitfield5[1] \div 128) % 2 > 0) THEN (IF settled26.expireTime = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled26.expireTime) ELSE << >>]
        settled28 == [settled27 EXCEPT !.stopPx = IF settled27.numberOfReturnBitfields >= 8 /\ (settled27.returnBitfield8 # << >> /\ (settled27.returnBitfield8[1] \div 4) % 2 > 0) THEN (IF settled27.stopPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled27.stopPx) ELSE << >>]
        settled29 == [settled28 EXCEPT !.cmtaNumber = IF settled28.numberOfReturnBitfields >= 9 /\ (settled28.returnBitfield9 # << >> /\ (settled28.returnBitfield9[1] \div 32) % 2 > 0) THEN (IF settled28.cmtaNumber = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled28.cmtaNumber) ELSE << >>]
        settled30 == [settled29 EXCEPT !.ctiCode = IF settled29.numberOfReturnBitfields >= 12 /\ (settled29.returnBitfield12 # << >> /\ settled29.returnBitfield12[1] % 2 > 0) THEN (IF settled29.ctiCode = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled29.ctiCode) ELSE << >>]
        settled31 == [settled30 EXCEPT !.manualOrderIndicator = IF settled30.numberOfReturnBitfields >= 12 /\ (settled30.returnBitfield12 # << >> /\ (settled30.returnBitfield12[1] \div 2) % 2 > 0) THEN (IF settled30.manualOrderIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled30.manualOrderIndicator) ELSE << >>]
        settled32 == [settled31 EXCEPT !.oeoid = IF settled31.numberOfReturnBitfields >= 12 /\ (settled31.returnBitfield12 # << >> /\ (settled31.returnBitfield12[1] \div 4) % 2 > 0) THEN (IF settled31.oeoid = << >> THEN <<[i \in 1 .. 18 |-> 0]>> ELSE settled31.oeoid) ELSE << >>]
    IN  settled32

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
                                  price                   |-> << >>,
                                  ordType                 |-> << >>,
                                  timeInForce             |-> << >>,
                                  minQty                  |-> << >>,
                                  symbolLong              |-> << >>,
                                  capacity                |-> << >>,
                                  maturityDate            |-> << >>,
                                  openClose               |-> << >>,
                                  expireTime              |-> << >>,
                                  stopPx                  |-> << >>,
                                  cmtaNumber              |-> << >>,
                                  ctiCode                 |-> << >>,
                                  manualOrderIndicator    |-> << >>,
                                  oeoid                   |-> << >> ])

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
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 7, !.returnBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 9, !.returnBitfield9 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 10, !.returnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 11, !.returnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 13, !.returnBitfield13 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 14, !.returnBitfield14 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 15, !.returnBitfield15 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 17, !.returnBitfield17 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<1>>, !.side = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<4>>, !.price = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<1>>, !.symbolLong = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<1>>, !.maturityDate = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<8>>, !.openClose = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<128>>, !.expireTime = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<4>>, !.stopPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 9, !.returnBitfield9 = <<32>>, !.cmtaNumber = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = <<1>>, !.ctiCode = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = <<2>>, !.manualOrderIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleCancelRejectedMessage([ZeroCancelRejectedMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = <<4>>, !.oeoid = one]) : one \in { <<held>> : held \in Sample(18) } }

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
      returnBitfield5         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield6         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield7         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield8         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield9         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield10        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield11        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield12        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield13        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield14        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield15        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield16        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield17        : { << >> } \cup { <<held>> : held \in Sample(1) },
      side                    : { << >> } \cup { <<held>> : held \in Sample(1) },
      price                   : { << >> } \cup { <<held>> : held \in Sample(8) },
      ordType                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce             : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                  : { << >> } \cup { <<held>> : held \in Sample(4) },
      symbolLong              : { << >> } \cup { <<held>> : held \in Sample(8) },
      capacity                : { << >> } \cup { <<held>> : held \in Sample(1) },
      account                 : { << >> } \cup { <<held>> : held \in Sample(16) },
      clearingFirm            : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingAccount         : { << >> } \cup { <<held>> : held \in Sample(4) },
      orderQty                : { << >> } \cup { <<held>> : held \in Sample(4) },
      preventMatch            : { << >> } \cup { <<held>> : held \in Sample(3) },
      maturityDate            : { << >> } \cup { <<held>> : held \in Sample(4) },
      openClose               : { << >> } \cup { <<held>> : held \in Sample(1) },
      expireTime              : { << >> } \cup { <<held>> : held \in Sample(8) },
      feeCode                 : { << >> } \cup { <<held>> : held \in Sample(2) },
      stopPx                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      cmtaNumber              : { << >> } \cup { <<held>> : held \in Sample(4) },
      ctiCode                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      manualOrderIndicator    : { << >> } \cup { <<held>> : held \in Sample(1) },
      oeoid                   : { << >> } \cup { <<held>> : held \in Sample(18) },
      tradeDate               : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingSize            : { << >> } \cup { <<held>> : held \in Sample(4) },
      cumQty                  : { << >> } \cup { <<held>> : held \in Sample(4) },
      dayOrderQty             : { << >> } \cup { <<held>> : held \in Sample(4) },
      dayCumQty               : { << >> } \cup { <<held>> : held \in Sample(4) },
      avgPx                   : { << >> } \cup { <<held>> : held \in Sample(8) },
      dayAvgPx                : { << >> } \cup { <<held>> : held \in Sample(8) },
      pendingStatus           : { << >> } \cup { <<held>> : held \in Sample(1) },
      multilegReportingType   : { << >> } \cup { <<held>> : held \in Sample(1) },
      secondaryExecId         : { << >> } \cup { <<held>> : held \in Sample(8) },
      frequentTraderId        : { << >> } \cup { <<held>> : held \in Sample(6) } ]

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
        \o (IF message.returnBitfield5 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield5[1], 1))
        \o (IF message.returnBitfield6 = << >> THEN << >> ELSE message.returnBitfield6[1])
        \o (IF message.returnBitfield7 = << >> THEN << >> ELSE message.returnBitfield7[1])
        \o (IF message.returnBitfield8 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield8[1], 1))
        \o (IF message.returnBitfield9 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield9[1], 1))
        \o (IF message.returnBitfield10 = << >> THEN << >> ELSE message.returnBitfield10[1])
        \o (IF message.returnBitfield11 = << >> THEN << >> ELSE message.returnBitfield11[1])
        \o (IF message.returnBitfield12 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield12[1], 1))
        \o (IF message.returnBitfield13 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield13[1], 1))
        \o (IF message.returnBitfield14 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield14[1], 1))
        \o (IF message.returnBitfield15 = << >> THEN << >> ELSE message.returnBitfield15[1])
        \o (IF message.returnBitfield16 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield16[1], 1))
        \o (IF message.returnBitfield17 = << >> THEN << >> ELSE message.returnBitfield17[1])
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
    LET returnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadUIntLE(returnBitfield4.rest, 1), returnBitfield4.rest) IN IF ~returnBitfield5.ok THEN Fail ELSE
    LET returnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadBytes(returnBitfield5.rest, 1), returnBitfield5.rest) IN IF ~returnBitfield6.ok THEN Fail ELSE
    LET returnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadBytes(returnBitfield6.rest, 1), returnBitfield6.rest) IN IF ~returnBitfield7.ok THEN Fail ELSE
    LET returnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadUIntLE(returnBitfield7.rest, 1), returnBitfield7.rest) IN IF ~returnBitfield8.ok THEN Fail ELSE
    LET returnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadUIntLE(returnBitfield8.rest, 1), returnBitfield8.rest) IN IF ~returnBitfield9.ok THEN Fail ELSE
    LET returnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadBytes(returnBitfield9.rest, 1), returnBitfield9.rest) IN IF ~returnBitfield10.ok THEN Fail ELSE
    LET returnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadBytes(returnBitfield10.rest, 1), returnBitfield10.rest) IN IF ~returnBitfield11.ok THEN Fail ELSE
    LET returnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadUIntLE(returnBitfield11.rest, 1), returnBitfield11.rest) IN IF ~returnBitfield12.ok THEN Fail ELSE
    LET returnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadUIntLE(returnBitfield12.rest, 1), returnBitfield12.rest) IN IF ~returnBitfield13.ok THEN Fail ELSE
    LET returnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadUIntLE(returnBitfield13.rest, 1), returnBitfield13.rest) IN IF ~returnBitfield14.ok THEN Fail ELSE
    LET returnBitfield15 == ReadWhen(numberOfReturnBitfields.value >= 15, ReadBytes(returnBitfield14.rest, 1), returnBitfield14.rest) IN IF ~returnBitfield15.ok THEN Fail ELSE
    LET returnBitfield16 == ReadWhen(numberOfReturnBitfields.value >= 16, ReadUIntLE(returnBitfield15.rest, 1), returnBitfield15.rest) IN IF ~returnBitfield16.ok THEN Fail ELSE
    LET returnBitfield17 == ReadWhen(numberOfReturnBitfields.value >= 17, ReadBytes(returnBitfield16.rest, 1), returnBitfield16.rest) IN IF ~returnBitfield17.ok THEN Fail ELSE
    LET side == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ returnBitfield1.value[1] % 2 > 0), ReadBytes(returnBitfield17.rest, 1), returnBitfield17.rest) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(side.rest, 8), side.rest) IN IF ~price.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(price.rest, 1), price.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET symbolLong == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ returnBitfield2.value[1] % 2 > 0), ReadBytes(minQty.rest, 8), minQty.rest) IN IF ~symbolLong.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ (returnBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(symbolLong.rest, 1), symbolLong.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ returnBitfield3.value[1] % 2 > 0), ReadBytes(capacity.rest, 16), capacity.rest) IN IF ~account.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 2) % 2 > 0), ReadBytes(account.rest, 4), account.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 4) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET orderQty == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 64) % 2 > 0), ReadBytes(clearingAccount.rest, 4), clearingAccount.rest) IN IF ~orderQty.ok THEN Fail ELSE
    LET preventMatch == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 128) % 2 > 0), ReadBytes(orderQty.rest, 3), orderQty.rest) IN IF ~preventMatch.ok THEN Fail ELSE
    LET maturityDate == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ returnBitfield4.value[1] % 2 > 0), ReadBytes(preventMatch.rest, 4), preventMatch.rest) IN IF ~maturityDate.ok THEN Fail ELSE
    LET openClose == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ (returnBitfield4.value[1] \div 8) % 2 > 0), ReadBytes(maturityDate.rest, 1), maturityDate.rest) IN IF ~openClose.ok THEN Fail ELSE
    LET expireTime == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 128) % 2 > 0), ReadBytes(openClose.rest, 8), openClose.rest) IN IF ~expireTime.ok THEN Fail ELSE
    LET feeCode == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ returnBitfield8.value[1] % 2 > 0), ReadBytes(expireTime.rest, 2), expireTime.rest) IN IF ~feeCode.ok THEN Fail ELSE
    LET stopPx == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 4) % 2 > 0), ReadBytes(feeCode.rest, 8), feeCode.rest) IN IF ~stopPx.ok THEN Fail ELSE
    LET cmtaNumber == ReadWhen(numberOfReturnBitfields.value >= 9 /\ (returnBitfield9.value # << >> /\ (returnBitfield9.value[1] \div 32) % 2 > 0), ReadBytes(stopPx.rest, 4), stopPx.rest) IN IF ~cmtaNumber.ok THEN Fail ELSE
    LET ctiCode == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (returnBitfield12.value # << >> /\ returnBitfield12.value[1] % 2 > 0), ReadBytes(cmtaNumber.rest, 1), cmtaNumber.rest) IN IF ~ctiCode.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (returnBitfield12.value # << >> /\ (returnBitfield12.value[1] \div 2) % 2 > 0), ReadBytes(ctiCode.rest, 1), ctiCode.rest) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET oeoid == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (returnBitfield12.value # << >> /\ (returnBitfield12.value[1] \div 4) % 2 > 0), ReadBytes(manualOrderIndicator.rest, 18), manualOrderIndicator.rest) IN IF ~oeoid.ok THEN Fail ELSE
    LET tradeDate == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (returnBitfield12.value # << >> /\ (returnBitfield12.value[1] \div 8) % 2 > 0), ReadBytes(oeoid.rest, 4), oeoid.rest) IN IF ~tradeDate.ok THEN Fail ELSE
    LET clearingSize == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (returnBitfield12.value # << >> /\ (returnBitfield12.value[1] \div 32) % 2 > 0), ReadBytes(tradeDate.rest, 4), tradeDate.rest) IN IF ~clearingSize.ok THEN Fail ELSE
    LET cumQty == ReadWhen(numberOfReturnBitfields.value >= 13 /\ (returnBitfield13.value # << >> /\ returnBitfield13.value[1] % 2 > 0), ReadBytes(clearingSize.rest, 4), clearingSize.rest) IN IF ~cumQty.ok THEN Fail ELSE
    LET dayOrderQty == ReadWhen(numberOfReturnBitfields.value >= 13 /\ (returnBitfield13.value # << >> /\ (returnBitfield13.value[1] \div 2) % 2 > 0), ReadBytes(cumQty.rest, 4), cumQty.rest) IN IF ~dayOrderQty.ok THEN Fail ELSE
    LET dayCumQty == ReadWhen(numberOfReturnBitfields.value >= 13 /\ (returnBitfield13.value # << >> /\ (returnBitfield13.value[1] \div 4) % 2 > 0), ReadBytes(dayOrderQty.rest, 4), dayOrderQty.rest) IN IF ~dayCumQty.ok THEN Fail ELSE
    LET avgPx == ReadWhen(numberOfReturnBitfields.value >= 13 /\ (returnBitfield13.value # << >> /\ (returnBitfield13.value[1] \div 8) % 2 > 0), ReadBytes(dayCumQty.rest, 8), dayCumQty.rest) IN IF ~avgPx.ok THEN Fail ELSE
    LET dayAvgPx == ReadWhen(numberOfReturnBitfields.value >= 13 /\ (returnBitfield13.value # << >> /\ (returnBitfield13.value[1] \div 16) % 2 > 0), ReadBytes(avgPx.rest, 8), avgPx.rest) IN IF ~dayAvgPx.ok THEN Fail ELSE
    LET pendingStatus == ReadWhen(numberOfReturnBitfields.value >= 13 /\ (returnBitfield13.value # << >> /\ (returnBitfield13.value[1] \div 32) % 2 > 0), ReadBytes(dayAvgPx.rest, 1), dayAvgPx.rest) IN IF ~pendingStatus.ok THEN Fail ELSE
    LET multilegReportingType == ReadWhen(numberOfReturnBitfields.value >= 13 /\ (returnBitfield13.value # << >> /\ (returnBitfield13.value[1] \div 128) % 2 > 0), ReadBytes(pendingStatus.rest, 1), pendingStatus.rest) IN IF ~multilegReportingType.ok THEN Fail ELSE
    LET secondaryExecId == ReadWhen(numberOfReturnBitfields.value >= 14 /\ (returnBitfield14.value # << >> /\ (returnBitfield14.value[1] \div 16) % 2 > 0), ReadBytes(multilegReportingType.rest, 8), multilegReportingType.rest) IN IF ~secondaryExecId.ok THEN Fail ELSE
    LET frequentTraderId == ReadWhen(numberOfReturnBitfields.value >= 16 /\ (returnBitfield16.value # << >> /\ returnBitfield16.value[1] % 2 > 0), ReadBytes(secondaryExecId.rest, 6), secondaryExecId.rest) IN IF ~frequentTraderId.ok THEN Fail ELSE
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
         price                   |-> price.value,
         ordType                 |-> ordType.value,
         timeInForce             |-> timeInForce.value,
         minQty                  |-> minQty.value,
         symbolLong              |-> symbolLong.value,
         capacity                |-> capacity.value,
         account                 |-> account.value,
         clearingFirm            |-> clearingFirm.value,
         clearingAccount         |-> clearingAccount.value,
         orderQty                |-> orderQty.value,
         preventMatch            |-> preventMatch.value,
         maturityDate            |-> maturityDate.value,
         openClose               |-> openClose.value,
         expireTime              |-> expireTime.value,
         feeCode                 |-> feeCode.value,
         stopPx                  |-> stopPx.value,
         cmtaNumber              |-> cmtaNumber.value,
         ctiCode                 |-> ctiCode.value,
         manualOrderIndicator    |-> manualOrderIndicator.value,
         oeoid                   |-> oeoid.value,
         tradeDate               |-> tradeDate.value,
         clearingSize            |-> clearingSize.value,
         cumQty                  |-> cumQty.value,
         dayOrderQty             |-> dayOrderQty.value,
         dayCumQty               |-> dayCumQty.value,
         avgPx                   |-> avgPx.value,
         dayAvgPx                |-> dayAvgPx.value,
         pendingStatus           |-> pendingStatus.value,
         multilegReportingType   |-> multilegReportingType.value,
         secondaryExecId         |-> secondaryExecId.value,
         frequentTraderId        |-> frequentTraderId.value ], frequentTraderId.rest)

(* Order Execution Message with each field marked present by fields before it there exactly where they say *)
SettleOrderExecutionMessage(message) ==
    LET settled1 == [message EXCEPT !.returnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.returnBitfield1 = << >> THEN <<0>> ELSE message.returnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.returnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.returnBitfield2 = << >> THEN <<0>> ELSE settled1.returnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.returnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.returnBitfield3 = << >> THEN <<0>> ELSE settled2.returnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.returnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.returnBitfield4 = << >> THEN <<0>> ELSE settled3.returnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.returnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.returnBitfield5 = << >> THEN <<0>> ELSE settled4.returnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.returnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.returnBitfield6 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled5.returnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.returnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.returnBitfield7 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.returnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.returnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.returnBitfield8 = << >> THEN <<0>> ELSE settled7.returnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.returnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.returnBitfield9 = << >> THEN <<0>> ELSE settled8.returnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.returnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.returnBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.returnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.returnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.returnBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.returnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.returnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.returnBitfield12 = << >> THEN <<0>> ELSE settled11.returnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.returnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.returnBitfield13 = << >> THEN <<0>> ELSE settled12.returnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.returnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.returnBitfield14 = << >> THEN <<0>> ELSE settled13.returnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.returnBitfield15 = IF settled14.numberOfReturnBitfields >= 15 THEN (IF settled14.returnBitfield15 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.returnBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.returnBitfield16 = IF settled15.numberOfReturnBitfields >= 16 THEN (IF settled15.returnBitfield16 = << >> THEN <<0>> ELSE settled15.returnBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.returnBitfield17 = IF settled16.numberOfReturnBitfields >= 17 THEN (IF settled16.returnBitfield17 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled16.returnBitfield17) ELSE << >>]
        settled18 == [settled17 EXCEPT !.side = IF settled17.numberOfReturnBitfields >= 1 /\ (settled17.returnBitfield1 # << >> /\ settled17.returnBitfield1[1] % 2 > 0) THEN (IF settled17.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.side) ELSE << >>]
        settled19 == [settled18 EXCEPT !.price = IF settled18.numberOfReturnBitfields >= 1 /\ (settled18.returnBitfield1 # << >> /\ (settled18.returnBitfield1[1] \div 4) % 2 > 0) THEN (IF settled18.price = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled18.price) ELSE << >>]
        settled20 == [settled19 EXCEPT !.ordType = IF settled19.numberOfReturnBitfields >= 1 /\ (settled19.returnBitfield1 # << >> /\ (settled19.returnBitfield1[1] \div 16) % 2 > 0) THEN (IF settled19.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled19.ordType) ELSE << >>]
        settled21 == [settled20 EXCEPT !.timeInForce = IF settled20.numberOfReturnBitfields >= 1 /\ (settled20.returnBitfield1 # << >> /\ (settled20.returnBitfield1[1] \div 32) % 2 > 0) THEN (IF settled20.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled20.timeInForce) ELSE << >>]
        settled22 == [settled21 EXCEPT !.minQty = IF settled21.numberOfReturnBitfields >= 1 /\ (settled21.returnBitfield1 # << >> /\ (settled21.returnBitfield1[1] \div 64) % 2 > 0) THEN (IF settled21.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled21.minQty) ELSE << >>]
        settled23 == [settled22 EXCEPT !.symbolLong = IF settled22.numberOfReturnBitfields >= 2 /\ (settled22.returnBitfield2 # << >> /\ settled22.returnBitfield2[1] % 2 > 0) THEN (IF settled22.symbolLong = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled22.symbolLong) ELSE << >>]
        settled24 == [settled23 EXCEPT !.capacity = IF settled23.numberOfReturnBitfields >= 2 /\ (settled23.returnBitfield2 # << >> /\ (settled23.returnBitfield2[1] \div 64) % 2 > 0) THEN (IF settled23.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled23.capacity) ELSE << >>]
        settled25 == [settled24 EXCEPT !.account = IF settled24.numberOfReturnBitfields >= 3 /\ (settled24.returnBitfield3 # << >> /\ settled24.returnBitfield3[1] % 2 > 0) THEN (IF settled24.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled24.account) ELSE << >>]
        settled26 == [settled25 EXCEPT !.clearingFirm = IF settled25.numberOfReturnBitfields >= 3 /\ (settled25.returnBitfield3 # << >> /\ (settled25.returnBitfield3[1] \div 2) % 2 > 0) THEN (IF settled25.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled25.clearingFirm) ELSE << >>]
        settled27 == [settled26 EXCEPT !.clearingAccount = IF settled26.numberOfReturnBitfields >= 3 /\ (settled26.returnBitfield3 # << >> /\ (settled26.returnBitfield3[1] \div 4) % 2 > 0) THEN (IF settled26.clearingAccount = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled26.clearingAccount) ELSE << >>]
        settled28 == [settled27 EXCEPT !.orderQty = IF settled27.numberOfReturnBitfields >= 3 /\ (settled27.returnBitfield3 # << >> /\ (settled27.returnBitfield3[1] \div 64) % 2 > 0) THEN (IF settled27.orderQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled27.orderQty) ELSE << >>]
        settled29 == [settled28 EXCEPT !.preventMatch = IF settled28.numberOfReturnBitfields >= 3 /\ (settled28.returnBitfield3 # << >> /\ (settled28.returnBitfield3[1] \div 128) % 2 > 0) THEN (IF settled28.preventMatch = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled28.preventMatch) ELSE << >>]
        settled30 == [settled29 EXCEPT !.maturityDate = IF settled29.numberOfReturnBitfields >= 4 /\ (settled29.returnBitfield4 # << >> /\ settled29.returnBitfield4[1] % 2 > 0) THEN (IF settled29.maturityDate = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled29.maturityDate) ELSE << >>]
        settled31 == [settled30 EXCEPT !.openClose = IF settled30.numberOfReturnBitfields >= 4 /\ (settled30.returnBitfield4 # << >> /\ (settled30.returnBitfield4[1] \div 8) % 2 > 0) THEN (IF settled30.openClose = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled30.openClose) ELSE << >>]
        settled32 == [settled31 EXCEPT !.expireTime = IF settled31.numberOfReturnBitfields >= 5 /\ (settled31.returnBitfield5 # << >> /\ (settled31.returnBitfield5[1] \div 128) % 2 > 0) THEN (IF settled31.expireTime = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled31.expireTime) ELSE << >>]
        settled33 == [settled32 EXCEPT !.feeCode = IF settled32.numberOfReturnBitfields >= 8 /\ (settled32.returnBitfield8 # << >> /\ settled32.returnBitfield8[1] % 2 > 0) THEN (IF settled32.feeCode = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled32.feeCode) ELSE << >>]
        settled34 == [settled33 EXCEPT !.stopPx = IF settled33.numberOfReturnBitfields >= 8 /\ (settled33.returnBitfield8 # << >> /\ (settled33.returnBitfield8[1] \div 4) % 2 > 0) THEN (IF settled33.stopPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled33.stopPx) ELSE << >>]
        settled35 == [settled34 EXCEPT !.cmtaNumber = IF settled34.numberOfReturnBitfields >= 9 /\ (settled34.returnBitfield9 # << >> /\ (settled34.returnBitfield9[1] \div 32) % 2 > 0) THEN (IF settled34.cmtaNumber = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled34.cmtaNumber) ELSE << >>]
        settled36 == [settled35 EXCEPT !.ctiCode = IF settled35.numberOfReturnBitfields >= 12 /\ (settled35.returnBitfield12 # << >> /\ settled35.returnBitfield12[1] % 2 > 0) THEN (IF settled35.ctiCode = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled35.ctiCode) ELSE << >>]
        settled37 == [settled36 EXCEPT !.manualOrderIndicator = IF settled36.numberOfReturnBitfields >= 12 /\ (settled36.returnBitfield12 # << >> /\ (settled36.returnBitfield12[1] \div 2) % 2 > 0) THEN (IF settled36.manualOrderIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled36.manualOrderIndicator) ELSE << >>]
        settled38 == [settled37 EXCEPT !.oeoid = IF settled37.numberOfReturnBitfields >= 12 /\ (settled37.returnBitfield12 # << >> /\ (settled37.returnBitfield12[1] \div 4) % 2 > 0) THEN (IF settled37.oeoid = << >> THEN <<[i \in 1 .. 18 |-> 0]>> ELSE settled37.oeoid) ELSE << >>]
        settled39 == [settled38 EXCEPT !.tradeDate = IF settled38.numberOfReturnBitfields >= 12 /\ (settled38.returnBitfield12 # << >> /\ (settled38.returnBitfield12[1] \div 8) % 2 > 0) THEN (IF settled38.tradeDate = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled38.tradeDate) ELSE << >>]
        settled40 == [settled39 EXCEPT !.clearingSize = IF settled39.numberOfReturnBitfields >= 12 /\ (settled39.returnBitfield12 # << >> /\ (settled39.returnBitfield12[1] \div 32) % 2 > 0) THEN (IF settled39.clearingSize = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled39.clearingSize) ELSE << >>]
        settled41 == [settled40 EXCEPT !.cumQty = IF settled40.numberOfReturnBitfields >= 13 /\ (settled40.returnBitfield13 # << >> /\ settled40.returnBitfield13[1] % 2 > 0) THEN (IF settled40.cumQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled40.cumQty) ELSE << >>]
        settled42 == [settled41 EXCEPT !.dayOrderQty = IF settled41.numberOfReturnBitfields >= 13 /\ (settled41.returnBitfield13 # << >> /\ (settled41.returnBitfield13[1] \div 2) % 2 > 0) THEN (IF settled41.dayOrderQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled41.dayOrderQty) ELSE << >>]
        settled43 == [settled42 EXCEPT !.dayCumQty = IF settled42.numberOfReturnBitfields >= 13 /\ (settled42.returnBitfield13 # << >> /\ (settled42.returnBitfield13[1] \div 4) % 2 > 0) THEN (IF settled42.dayCumQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled42.dayCumQty) ELSE << >>]
        settled44 == [settled43 EXCEPT !.avgPx = IF settled43.numberOfReturnBitfields >= 13 /\ (settled43.returnBitfield13 # << >> /\ (settled43.returnBitfield13[1] \div 8) % 2 > 0) THEN (IF settled43.avgPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled43.avgPx) ELSE << >>]
        settled45 == [settled44 EXCEPT !.dayAvgPx = IF settled44.numberOfReturnBitfields >= 13 /\ (settled44.returnBitfield13 # << >> /\ (settled44.returnBitfield13[1] \div 16) % 2 > 0) THEN (IF settled44.dayAvgPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled44.dayAvgPx) ELSE << >>]
        settled46 == [settled45 EXCEPT !.pendingStatus = IF settled45.numberOfReturnBitfields >= 13 /\ (settled45.returnBitfield13 # << >> /\ (settled45.returnBitfield13[1] \div 32) % 2 > 0) THEN (IF settled45.pendingStatus = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled45.pendingStatus) ELSE << >>]
        settled47 == [settled46 EXCEPT !.multilegReportingType = IF settled46.numberOfReturnBitfields >= 13 /\ (settled46.returnBitfield13 # << >> /\ (settled46.returnBitfield13[1] \div 128) % 2 > 0) THEN (IF settled46.multilegReportingType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled46.multilegReportingType) ELSE << >>]
        settled48 == [settled47 EXCEPT !.secondaryExecId = IF settled47.numberOfReturnBitfields >= 14 /\ (settled47.returnBitfield14 # << >> /\ (settled47.returnBitfield14[1] \div 16) % 2 > 0) THEN (IF settled47.secondaryExecId = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled47.secondaryExecId) ELSE << >>]
        settled49 == [settled48 EXCEPT !.frequentTraderId = IF settled48.numberOfReturnBitfields >= 16 /\ (settled48.returnBitfield16 # << >> /\ settled48.returnBitfield16[1] % 2 > 0) THEN (IF settled48.frequentTraderId = << >> THEN <<[i \in 1 .. 6 |-> 0]>> ELSE settled48.frequentTraderId) ELSE << >>]
    IN  settled49

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
                                  price                   |-> << >>,
                                  ordType                 |-> << >>,
                                  timeInForce             |-> << >>,
                                  minQty                  |-> << >>,
                                  symbolLong              |-> << >>,
                                  capacity                |-> << >>,
                                  account                 |-> << >>,
                                  clearingFirm            |-> << >>,
                                  clearingAccount         |-> << >>,
                                  orderQty                |-> << >>,
                                  preventMatch            |-> << >>,
                                  maturityDate            |-> << >>,
                                  openClose               |-> << >>,
                                  expireTime              |-> << >>,
                                  feeCode                 |-> << >>,
                                  stopPx                  |-> << >>,
                                  cmtaNumber              |-> << >>,
                                  ctiCode                 |-> << >>,
                                  manualOrderIndicator    |-> << >>,
                                  oeoid                   |-> << >>,
                                  tradeDate               |-> << >>,
                                  clearingSize            |-> << >>,
                                  cumQty                  |-> << >>,
                                  dayOrderQty             |-> << >>,
                                  dayCumQty               |-> << >>,
                                  avgPx                   |-> << >>,
                                  dayAvgPx                |-> << >>,
                                  pendingStatus           |-> << >>,
                                  multilegReportingType   |-> << >>,
                                  secondaryExecId         |-> << >>,
                                  frequentTraderId        |-> << >> ])

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
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 7, !.returnBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 9, !.returnBitfield9 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 10, !.returnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 11, !.returnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 13, !.returnBitfield13 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 14, !.returnBitfield14 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 15, !.returnBitfield15 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 17, !.returnBitfield17 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<1>>, !.side = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<4>>, !.price = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<1>>, !.symbolLong = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<1>>, !.account = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<2>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<4>>, !.clearingAccount = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<64>>, !.orderQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<128>>, !.preventMatch = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<1>>, !.maturityDate = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<8>>, !.openClose = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<128>>, !.expireTime = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<1>>, !.feeCode = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<4>>, !.stopPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 9, !.returnBitfield9 = <<32>>, !.cmtaNumber = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = <<1>>, !.ctiCode = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = <<2>>, !.manualOrderIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = <<4>>, !.oeoid = one]) : one \in { <<held>> : held \in Sample(18) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = <<8>>, !.tradeDate = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = <<32>>, !.clearingSize = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 13, !.returnBitfield13 = <<1>>, !.cumQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 13, !.returnBitfield13 = <<2>>, !.dayOrderQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 13, !.returnBitfield13 = <<4>>, !.dayCumQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 13, !.returnBitfield13 = <<8>>, !.avgPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 13, !.returnBitfield13 = <<16>>, !.dayAvgPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 13, !.returnBitfield13 = <<32>>, !.pendingStatus = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 13, !.returnBitfield13 = <<128>>, !.multilegReportingType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 14, !.returnBitfield14 = <<16>>, !.secondaryExecId = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderExecutionMessage([ZeroOrderExecutionMessage EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = <<1>>, !.frequentTraderId = one]) : one \in { <<held>> : held \in Sample(6) } }

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
      returnBitfield7         : { << >> } \cup { <<held>> : held \in Sample(1) },
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
      openClose               : { << >> } \cup { <<held>> : held \in Sample(1) },
      correctedSize           : { << >> } \cup { <<held>> : held \in Sample(4) },
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
        \o (IF message.returnBitfield7 = << >> THEN << >> ELSE message.returnBitfield7[1])
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
    LET returnBitfield1 == ReadWhen(numberOfReturnBitfields.value >= 1, ReadBytes(numberOfReturnBitfields.rest, 1), numberOfReturnBitfields.rest) IN IF ~returnBitfield1.ok THEN Fail ELSE
    LET returnBitfield2 == ReadWhen(numberOfReturnBitfields.value >= 2, ReadUIntLE(returnBitfield1.rest, 1), returnBitfield1.rest) IN IF ~returnBitfield2.ok THEN Fail ELSE
    LET returnBitfield3 == ReadWhen(numberOfReturnBitfields.value >= 3, ReadBytes(returnBitfield2.rest, 1), returnBitfield2.rest) IN IF ~returnBitfield3.ok THEN Fail ELSE
    LET returnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadUIntLE(returnBitfield3.rest, 1), returnBitfield3.rest) IN IF ~returnBitfield4.ok THEN Fail ELSE
    LET returnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadBytes(returnBitfield4.rest, 1), returnBitfield4.rest) IN IF ~returnBitfield5.ok THEN Fail ELSE
    LET returnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadBytes(returnBitfield5.rest, 1), returnBitfield5.rest) IN IF ~returnBitfield6.ok THEN Fail ELSE
    LET returnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadBytes(returnBitfield6.rest, 1), returnBitfield6.rest) IN IF ~returnBitfield7.ok THEN Fail ELSE
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
    LET openClose == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ (returnBitfield4.value[1] \div 8) % 2 > 0), ReadBytes(maturityDate.rest, 1), maturityDate.rest) IN IF ~openClose.ok THEN Fail ELSE
    LET correctedSize == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ (returnBitfield4.value[1] \div 32) % 2 > 0), ReadBytes(openClose.rest, 4), openClose.rest) IN IF ~correctedSize.ok THEN Fail ELSE
    LET cmtaNumber == ReadWhen(numberOfReturnBitfields.value >= 9 /\ (returnBitfield9.value # << >> /\ (returnBitfield9.value[1] \div 32) % 2 > 0), ReadBytes(correctedSize.rest, 4), correctedSize.rest) IN IF ~cmtaNumber.ok THEN Fail ELSE
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
         openClose               |-> openClose.value,
         correctedSize           |-> correctedSize.value,
         cmtaNumber              |-> cmtaNumber.value ], cmtaNumber.rest)

(* Trade Cancel Or Correct Message with each field marked present by fields before it there exactly where they say *)
SettleTradeCancelOrCorrectMessage(message) ==
    LET settled1 == [message EXCEPT !.returnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.returnBitfield1 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE message.returnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.returnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.returnBitfield2 = << >> THEN <<0>> ELSE settled1.returnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.returnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.returnBitfield3 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled2.returnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.returnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.returnBitfield4 = << >> THEN <<0>> ELSE settled3.returnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.returnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.returnBitfield5 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled4.returnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.returnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.returnBitfield6 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled5.returnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.returnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.returnBitfield7 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.returnBitfield7) ELSE << >>]
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
        settled21 == [settled20 EXCEPT !.openClose = IF settled20.numberOfReturnBitfields >= 4 /\ (settled20.returnBitfield4 # << >> /\ (settled20.returnBitfield4[1] \div 8) % 2 > 0) THEN (IF settled20.openClose = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled20.openClose) ELSE << >>]
        settled22 == [settled21 EXCEPT !.correctedSize = IF settled21.numberOfReturnBitfields >= 4 /\ (settled21.returnBitfield4 # << >> /\ (settled21.returnBitfield4[1] \div 32) % 2 > 0) THEN (IF settled21.correctedSize = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled21.correctedSize) ELSE << >>]
        settled23 == [settled22 EXCEPT !.cmtaNumber = IF settled22.numberOfReturnBitfields >= 9 /\ (settled22.returnBitfield9 # << >> /\ (settled22.returnBitfield9[1] \div 32) % 2 > 0) THEN (IF settled22.cmtaNumber = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled22.cmtaNumber) ELSE << >>]
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
                                        symbolLong              |-> << >>,
                                        capacity                |-> << >>,
                                        maturityDate            |-> << >>,
                                        openClose               |-> << >>,
                                        correctedSize           |-> << >>,
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
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 7, !.returnBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
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
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<8>>, !.openClose = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradeCancelOrCorrectMessage([ZeroTradeCancelOrCorrectMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<32>>, !.correctedSize = one]) : one \in { <<held>> : held \in Sample(4) } }
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
(* Risk Reset Acknowledgment Message: 17 bytes                             *)
(***************************************************************************)

RiskResetAcknowledgmentMessage ==
    [ riskStatusId    : Sample(16),
      riskResetResult : Sample(1) ]

EncodeRiskResetAcknowledgmentMessage(message) ==
    message.riskStatusId
        \o message.riskResetResult

DecodeRiskResetAcknowledgmentMessage(bytes) ==
    LET riskStatusId == ReadBytes(bytes, 16) IN IF ~riskStatusId.ok THEN Fail ELSE
    LET riskResetResult == ReadBytes(riskStatusId.rest, 1) IN IF ~riskResetResult.ok THEN Fail ELSE
    Ok([ riskStatusId    |-> riskStatusId.value,
         riskResetResult |-> riskResetResult.value ], riskResetResult.rest)

ZeroRiskResetAcknowledgmentMessage ==
    [ riskStatusId    |-> [i \in 1 .. 16 |-> 0],
      riskResetResult |-> [i \in 1 .. 1 |-> 0] ]

(* Risk Reset Acknowledgment Message at zero, then each field in turn at the values it is checked at *)
CheckedRiskResetAcknowledgmentMessage ==
    { ZeroRiskResetAcknowledgmentMessage }
        \cup { [ZeroRiskResetAcknowledgmentMessage EXCEPT !.riskStatusId = one] : one \in Sample(16) }
        \cup { [ZeroRiskResetAcknowledgmentMessage EXCEPT !.riskResetResult = one] : one \in Sample(1) }

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
(* Tas Restatement Message                                                 *)
(***************************************************************************)

TasRestatementMessage ==
    [ transactionTime         : Sample(8),
      clOrdId                 : Sample(20),
      execId                  : Sample(8),
      reserved1               : Sample(1),
      numberOfReturnBitfields : 0 .. 255,
      returnBitfield1         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield2         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield3         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield4         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield5         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield6         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield7         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield8         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield9         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield10        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield11        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield12        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield13        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield14        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield15        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield16        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield17        : { << >> } \cup { <<held>> : held \in Sample(1) },
      side                    : { << >> } \cup { <<held>> : held \in Sample(1) },
      price                   : { << >> } \cup { <<held>> : held \in Sample(8) },
      ordType                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce             : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                  : { << >> } \cup { <<held>> : held \in Sample(4) },
      symbolLong              : { << >> } \cup { <<held>> : held \in Sample(8) },
      capacity                : { << >> } \cup { <<held>> : held \in Sample(1) },
      account                 : { << >> } \cup { <<held>> : held \in Sample(16) },
      clearingFirm            : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingAccount         : { << >> } \cup { <<held>> : held \in Sample(4) },
      preventMatch            : { << >> } \cup { <<held>> : held \in Sample(3) },
      maturityDate            : { << >> } \cup { <<held>> : held \in Sample(4) },
      openClose               : { << >> } \cup { <<held>> : held \in Sample(1) },
      origClOrdId             : { << >> } \cup { <<held>> : held \in Sample(20) },
      lastShares              : { << >> } \cup { <<held>> : held \in Sample(4) },
      lastPx                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      feeCode                 : { << >> } \cup { <<held>> : held \in Sample(2) },
      stopPx                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      cmtaNumber              : { << >> } \cup { <<held>> : held \in Sample(4) },
      ctiCode                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      manualOrderIndicator    : { << >> } \cup { <<held>> : held \in Sample(1) },
      oeoid                   : { << >> } \cup { <<held>> : held \in Sample(18) },
      tradeDate               : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingPrice           : { << >> } \cup { <<held>> : held \in Sample(8) },
      clearingSymbol          : { << >> } \cup { <<held>> : held \in Sample(8) },
      multilegReportingType   : { << >> } \cup { <<held>> : held \in Sample(1) },
      secondaryExecId         : { << >> } \cup { <<held>> : held \in Sample(8) },
      frequentTraderId        : { << >> } \cup { <<held>> : held \in Sample(6) } ]

EncodeTasRestatementMessage(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.execId
        \o message.reserved1
        \o EncodeUIntBE(message.numberOfReturnBitfields, 1)
        \o (IF message.returnBitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield1[1], 1))
        \o (IF message.returnBitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield2[1], 1))
        \o (IF message.returnBitfield3 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield3[1], 1))
        \o (IF message.returnBitfield4 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield4[1], 1))
        \o (IF message.returnBitfield5 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield5[1], 1))
        \o (IF message.returnBitfield6 = << >> THEN << >> ELSE message.returnBitfield6[1])
        \o (IF message.returnBitfield7 = << >> THEN << >> ELSE message.returnBitfield7[1])
        \o (IF message.returnBitfield8 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield8[1], 1))
        \o (IF message.returnBitfield9 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield9[1], 1))
        \o (IF message.returnBitfield10 = << >> THEN << >> ELSE message.returnBitfield10[1])
        \o (IF message.returnBitfield11 = << >> THEN << >> ELSE message.returnBitfield11[1])
        \o (IF message.returnBitfield12 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield12[1], 1))
        \o (IF message.returnBitfield13 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield13[1], 1))
        \o (IF message.returnBitfield14 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield14[1], 1))
        \o (IF message.returnBitfield15 = << >> THEN << >> ELSE message.returnBitfield15[1])
        \o (IF message.returnBitfield16 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield16[1], 1))
        \o (IF message.returnBitfield17 = << >> THEN << >> ELSE message.returnBitfield17[1])
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

DecodeTasRestatementMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET execId == ReadBytes(clOrdId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(execId.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET numberOfReturnBitfields == ReadUIntBE(reserved1.rest, 1) IN IF ~numberOfReturnBitfields.ok THEN Fail ELSE
    LET returnBitfield1 == ReadWhen(numberOfReturnBitfields.value >= 1, ReadUIntLE(numberOfReturnBitfields.rest, 1), numberOfReturnBitfields.rest) IN IF ~returnBitfield1.ok THEN Fail ELSE
    LET returnBitfield2 == ReadWhen(numberOfReturnBitfields.value >= 2, ReadUIntLE(returnBitfield1.rest, 1), returnBitfield1.rest) IN IF ~returnBitfield2.ok THEN Fail ELSE
    LET returnBitfield3 == ReadWhen(numberOfReturnBitfields.value >= 3, ReadUIntLE(returnBitfield2.rest, 1), returnBitfield2.rest) IN IF ~returnBitfield3.ok THEN Fail ELSE
    LET returnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadUIntLE(returnBitfield3.rest, 1), returnBitfield3.rest) IN IF ~returnBitfield4.ok THEN Fail ELSE
    LET returnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadUIntLE(returnBitfield4.rest, 1), returnBitfield4.rest) IN IF ~returnBitfield5.ok THEN Fail ELSE
    LET returnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadBytes(returnBitfield5.rest, 1), returnBitfield5.rest) IN IF ~returnBitfield6.ok THEN Fail ELSE
    LET returnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadBytes(returnBitfield6.rest, 1), returnBitfield6.rest) IN IF ~returnBitfield7.ok THEN Fail ELSE
    LET returnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadUIntLE(returnBitfield7.rest, 1), returnBitfield7.rest) IN IF ~returnBitfield8.ok THEN Fail ELSE
    LET returnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadUIntLE(returnBitfield8.rest, 1), returnBitfield8.rest) IN IF ~returnBitfield9.ok THEN Fail ELSE
    LET returnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadBytes(returnBitfield9.rest, 1), returnBitfield9.rest) IN IF ~returnBitfield10.ok THEN Fail ELSE
    LET returnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadBytes(returnBitfield10.rest, 1), returnBitfield10.rest) IN IF ~returnBitfield11.ok THEN Fail ELSE
    LET returnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadUIntLE(returnBitfield11.rest, 1), returnBitfield11.rest) IN IF ~returnBitfield12.ok THEN Fail ELSE
    LET returnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadUIntLE(returnBitfield12.rest, 1), returnBitfield12.rest) IN IF ~returnBitfield13.ok THEN Fail ELSE
    LET returnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadUIntLE(returnBitfield13.rest, 1), returnBitfield13.rest) IN IF ~returnBitfield14.ok THEN Fail ELSE
    LET returnBitfield15 == ReadWhen(numberOfReturnBitfields.value >= 15, ReadBytes(returnBitfield14.rest, 1), returnBitfield14.rest) IN IF ~returnBitfield15.ok THEN Fail ELSE
    LET returnBitfield16 == ReadWhen(numberOfReturnBitfields.value >= 16, ReadUIntLE(returnBitfield15.rest, 1), returnBitfield15.rest) IN IF ~returnBitfield16.ok THEN Fail ELSE
    LET returnBitfield17 == ReadWhen(numberOfReturnBitfields.value >= 17, ReadBytes(returnBitfield16.rest, 1), returnBitfield16.rest) IN IF ~returnBitfield17.ok THEN Fail ELSE
    LET side == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ returnBitfield1.value[1] % 2 > 0), ReadBytes(returnBitfield17.rest, 1), returnBitfield17.rest) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(side.rest, 8), side.rest) IN IF ~price.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(price.rest, 1), price.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET symbolLong == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ returnBitfield2.value[1] % 2 > 0), ReadBytes(minQty.rest, 8), minQty.rest) IN IF ~symbolLong.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ (returnBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(symbolLong.rest, 1), symbolLong.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ returnBitfield3.value[1] % 2 > 0), ReadBytes(capacity.rest, 16), capacity.rest) IN IF ~account.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 2) % 2 > 0), ReadBytes(account.rest, 4), account.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 4) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET preventMatch == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 128) % 2 > 0), ReadBytes(clearingAccount.rest, 3), clearingAccount.rest) IN IF ~preventMatch.ok THEN Fail ELSE
    LET maturityDate == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ returnBitfield4.value[1] % 2 > 0), ReadBytes(preventMatch.rest, 4), preventMatch.rest) IN IF ~maturityDate.ok THEN Fail ELSE
    LET openClose == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ (returnBitfield4.value[1] \div 8) % 2 > 0), ReadBytes(maturityDate.rest, 1), maturityDate.rest) IN IF ~openClose.ok THEN Fail ELSE
    LET origClOrdId == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ returnBitfield5.value[1] % 2 > 0), ReadBytes(openClose.rest, 20), openClose.rest) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET lastShares == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 4) % 2 > 0), ReadBytes(origClOrdId.rest, 4), origClOrdId.rest) IN IF ~lastShares.ok THEN Fail ELSE
    LET lastPx == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 8) % 2 > 0), ReadBytes(lastShares.rest, 8), lastShares.rest) IN IF ~lastPx.ok THEN Fail ELSE
    LET feeCode == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ returnBitfield8.value[1] % 2 > 0), ReadBytes(lastPx.rest, 2), lastPx.rest) IN IF ~feeCode.ok THEN Fail ELSE
    LET stopPx == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 4) % 2 > 0), ReadBytes(feeCode.rest, 8), feeCode.rest) IN IF ~stopPx.ok THEN Fail ELSE
    LET cmtaNumber == ReadWhen(numberOfReturnBitfields.value >= 9 /\ (returnBitfield9.value # << >> /\ (returnBitfield9.value[1] \div 32) % 2 > 0), ReadBytes(stopPx.rest, 4), stopPx.rest) IN IF ~cmtaNumber.ok THEN Fail ELSE
    LET ctiCode == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (returnBitfield12.value # << >> /\ returnBitfield12.value[1] % 2 > 0), ReadBytes(cmtaNumber.rest, 1), cmtaNumber.rest) IN IF ~ctiCode.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (returnBitfield12.value # << >> /\ (returnBitfield12.value[1] \div 2) % 2 > 0), ReadBytes(ctiCode.rest, 1), ctiCode.rest) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET oeoid == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (returnBitfield12.value # << >> /\ (returnBitfield12.value[1] \div 4) % 2 > 0), ReadBytes(manualOrderIndicator.rest, 18), manualOrderIndicator.rest) IN IF ~oeoid.ok THEN Fail ELSE
    LET tradeDate == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (returnBitfield12.value # << >> /\ (returnBitfield12.value[1] \div 8) % 2 > 0), ReadBytes(oeoid.rest, 4), oeoid.rest) IN IF ~tradeDate.ok THEN Fail ELSE
    LET clearingPrice == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (returnBitfield12.value # << >> /\ (returnBitfield12.value[1] \div 16) % 2 > 0), ReadBytes(tradeDate.rest, 8), tradeDate.rest) IN IF ~clearingPrice.ok THEN Fail ELSE
    LET clearingSymbol == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (returnBitfield12.value # << >> /\ (returnBitfield12.value[1] \div 64) % 2 > 0), ReadBytes(clearingPrice.rest, 8), clearingPrice.rest) IN IF ~clearingSymbol.ok THEN Fail ELSE
    LET multilegReportingType == ReadWhen(numberOfReturnBitfields.value >= 13 /\ (returnBitfield13.value # << >> /\ (returnBitfield13.value[1] \div 128) % 2 > 0), ReadBytes(clearingSymbol.rest, 1), clearingSymbol.rest) IN IF ~multilegReportingType.ok THEN Fail ELSE
    LET secondaryExecId == ReadWhen(numberOfReturnBitfields.value >= 14 /\ (returnBitfield14.value # << >> /\ (returnBitfield14.value[1] \div 16) % 2 > 0), ReadBytes(multilegReportingType.rest, 8), multilegReportingType.rest) IN IF ~secondaryExecId.ok THEN Fail ELSE
    LET frequentTraderId == ReadWhen(numberOfReturnBitfields.value >= 16 /\ (returnBitfield16.value # << >> /\ returnBitfield16.value[1] % 2 > 0), ReadBytes(secondaryExecId.rest, 6), secondaryExecId.rest) IN IF ~frequentTraderId.ok THEN Fail ELSE
    Ok([ transactionTime         |-> transactionTime.value,
         clOrdId                 |-> clOrdId.value,
         execId                  |-> execId.value,
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
         price                   |-> price.value,
         ordType                 |-> ordType.value,
         timeInForce             |-> timeInForce.value,
         minQty                  |-> minQty.value,
         symbolLong              |-> symbolLong.value,
         capacity                |-> capacity.value,
         account                 |-> account.value,
         clearingFirm            |-> clearingFirm.value,
         clearingAccount         |-> clearingAccount.value,
         preventMatch            |-> preventMatch.value,
         maturityDate            |-> maturityDate.value,
         openClose               |-> openClose.value,
         origClOrdId             |-> origClOrdId.value,
         lastShares              |-> lastShares.value,
         lastPx                  |-> lastPx.value,
         feeCode                 |-> feeCode.value,
         stopPx                  |-> stopPx.value,
         cmtaNumber              |-> cmtaNumber.value,
         ctiCode                 |-> ctiCode.value,
         manualOrderIndicator    |-> manualOrderIndicator.value,
         oeoid                   |-> oeoid.value,
         tradeDate               |-> tradeDate.value,
         clearingPrice           |-> clearingPrice.value,
         clearingSymbol          |-> clearingSymbol.value,
         multilegReportingType   |-> multilegReportingType.value,
         secondaryExecId         |-> secondaryExecId.value,
         frequentTraderId        |-> frequentTraderId.value ], frequentTraderId.rest)

(* Tas Restatement Message with each field marked present by fields before it there exactly where they say *)
SettleTasRestatementMessage(message) ==
    LET settled1 == [message EXCEPT !.returnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.returnBitfield1 = << >> THEN <<0>> ELSE message.returnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.returnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.returnBitfield2 = << >> THEN <<0>> ELSE settled1.returnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.returnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.returnBitfield3 = << >> THEN <<0>> ELSE settled2.returnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.returnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.returnBitfield4 = << >> THEN <<0>> ELSE settled3.returnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.returnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.returnBitfield5 = << >> THEN <<0>> ELSE settled4.returnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.returnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.returnBitfield6 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled5.returnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.returnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.returnBitfield7 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.returnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.returnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.returnBitfield8 = << >> THEN <<0>> ELSE settled7.returnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.returnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.returnBitfield9 = << >> THEN <<0>> ELSE settled8.returnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.returnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.returnBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.returnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.returnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.returnBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.returnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.returnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.returnBitfield12 = << >> THEN <<0>> ELSE settled11.returnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.returnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.returnBitfield13 = << >> THEN <<0>> ELSE settled12.returnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.returnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.returnBitfield14 = << >> THEN <<0>> ELSE settled13.returnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.returnBitfield15 = IF settled14.numberOfReturnBitfields >= 15 THEN (IF settled14.returnBitfield15 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.returnBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.returnBitfield16 = IF settled15.numberOfReturnBitfields >= 16 THEN (IF settled15.returnBitfield16 = << >> THEN <<0>> ELSE settled15.returnBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.returnBitfield17 = IF settled16.numberOfReturnBitfields >= 17 THEN (IF settled16.returnBitfield17 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled16.returnBitfield17) ELSE << >>]
        settled18 == [settled17 EXCEPT !.side = IF settled17.numberOfReturnBitfields >= 1 /\ (settled17.returnBitfield1 # << >> /\ settled17.returnBitfield1[1] % 2 > 0) THEN (IF settled17.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.side) ELSE << >>]
        settled19 == [settled18 EXCEPT !.price = IF settled18.numberOfReturnBitfields >= 1 /\ (settled18.returnBitfield1 # << >> /\ (settled18.returnBitfield1[1] \div 4) % 2 > 0) THEN (IF settled18.price = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled18.price) ELSE << >>]
        settled20 == [settled19 EXCEPT !.ordType = IF settled19.numberOfReturnBitfields >= 1 /\ (settled19.returnBitfield1 # << >> /\ (settled19.returnBitfield1[1] \div 16) % 2 > 0) THEN (IF settled19.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled19.ordType) ELSE << >>]
        settled21 == [settled20 EXCEPT !.timeInForce = IF settled20.numberOfReturnBitfields >= 1 /\ (settled20.returnBitfield1 # << >> /\ (settled20.returnBitfield1[1] \div 32) % 2 > 0) THEN (IF settled20.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled20.timeInForce) ELSE << >>]
        settled22 == [settled21 EXCEPT !.minQty = IF settled21.numberOfReturnBitfields >= 1 /\ (settled21.returnBitfield1 # << >> /\ (settled21.returnBitfield1[1] \div 64) % 2 > 0) THEN (IF settled21.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled21.minQty) ELSE << >>]
        settled23 == [settled22 EXCEPT !.symbolLong = IF settled22.numberOfReturnBitfields >= 2 /\ (settled22.returnBitfield2 # << >> /\ settled22.returnBitfield2[1] % 2 > 0) THEN (IF settled22.symbolLong = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled22.symbolLong) ELSE << >>]
        settled24 == [settled23 EXCEPT !.capacity = IF settled23.numberOfReturnBitfields >= 2 /\ (settled23.returnBitfield2 # << >> /\ (settled23.returnBitfield2[1] \div 64) % 2 > 0) THEN (IF settled23.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled23.capacity) ELSE << >>]
        settled25 == [settled24 EXCEPT !.account = IF settled24.numberOfReturnBitfields >= 3 /\ (settled24.returnBitfield3 # << >> /\ settled24.returnBitfield3[1] % 2 > 0) THEN (IF settled24.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled24.account) ELSE << >>]
        settled26 == [settled25 EXCEPT !.clearingFirm = IF settled25.numberOfReturnBitfields >= 3 /\ (settled25.returnBitfield3 # << >> /\ (settled25.returnBitfield3[1] \div 2) % 2 > 0) THEN (IF settled25.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled25.clearingFirm) ELSE << >>]
        settled27 == [settled26 EXCEPT !.clearingAccount = IF settled26.numberOfReturnBitfields >= 3 /\ (settled26.returnBitfield3 # << >> /\ (settled26.returnBitfield3[1] \div 4) % 2 > 0) THEN (IF settled26.clearingAccount = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled26.clearingAccount) ELSE << >>]
        settled28 == [settled27 EXCEPT !.preventMatch = IF settled27.numberOfReturnBitfields >= 3 /\ (settled27.returnBitfield3 # << >> /\ (settled27.returnBitfield3[1] \div 128) % 2 > 0) THEN (IF settled27.preventMatch = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled27.preventMatch) ELSE << >>]
        settled29 == [settled28 EXCEPT !.maturityDate = IF settled28.numberOfReturnBitfields >= 4 /\ (settled28.returnBitfield4 # << >> /\ settled28.returnBitfield4[1] % 2 > 0) THEN (IF settled28.maturityDate = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled28.maturityDate) ELSE << >>]
        settled30 == [settled29 EXCEPT !.openClose = IF settled29.numberOfReturnBitfields >= 4 /\ (settled29.returnBitfield4 # << >> /\ (settled29.returnBitfield4[1] \div 8) % 2 > 0) THEN (IF settled29.openClose = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled29.openClose) ELSE << >>]
        settled31 == [settled30 EXCEPT !.origClOrdId = IF settled30.numberOfReturnBitfields >= 5 /\ (settled30.returnBitfield5 # << >> /\ settled30.returnBitfield5[1] % 2 > 0) THEN (IF settled30.origClOrdId = << >> THEN <<[i \in 1 .. 20 |-> 0]>> ELSE settled30.origClOrdId) ELSE << >>]
        settled32 == [settled31 EXCEPT !.lastShares = IF settled31.numberOfReturnBitfields >= 5 /\ (settled31.returnBitfield5 # << >> /\ (settled31.returnBitfield5[1] \div 4) % 2 > 0) THEN (IF settled31.lastShares = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled31.lastShares) ELSE << >>]
        settled33 == [settled32 EXCEPT !.lastPx = IF settled32.numberOfReturnBitfields >= 5 /\ (settled32.returnBitfield5 # << >> /\ (settled32.returnBitfield5[1] \div 8) % 2 > 0) THEN (IF settled32.lastPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled32.lastPx) ELSE << >>]
        settled34 == [settled33 EXCEPT !.feeCode = IF settled33.numberOfReturnBitfields >= 8 /\ (settled33.returnBitfield8 # << >> /\ settled33.returnBitfield8[1] % 2 > 0) THEN (IF settled33.feeCode = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled33.feeCode) ELSE << >>]
        settled35 == [settled34 EXCEPT !.stopPx = IF settled34.numberOfReturnBitfields >= 8 /\ (settled34.returnBitfield8 # << >> /\ (settled34.returnBitfield8[1] \div 4) % 2 > 0) THEN (IF settled34.stopPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled34.stopPx) ELSE << >>]
        settled36 == [settled35 EXCEPT !.cmtaNumber = IF settled35.numberOfReturnBitfields >= 9 /\ (settled35.returnBitfield9 # << >> /\ (settled35.returnBitfield9[1] \div 32) % 2 > 0) THEN (IF settled35.cmtaNumber = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled35.cmtaNumber) ELSE << >>]
        settled37 == [settled36 EXCEPT !.ctiCode = IF settled36.numberOfReturnBitfields >= 12 /\ (settled36.returnBitfield12 # << >> /\ settled36.returnBitfield12[1] % 2 > 0) THEN (IF settled36.ctiCode = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled36.ctiCode) ELSE << >>]
        settled38 == [settled37 EXCEPT !.manualOrderIndicator = IF settled37.numberOfReturnBitfields >= 12 /\ (settled37.returnBitfield12 # << >> /\ (settled37.returnBitfield12[1] \div 2) % 2 > 0) THEN (IF settled37.manualOrderIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled37.manualOrderIndicator) ELSE << >>]
        settled39 == [settled38 EXCEPT !.oeoid = IF settled38.numberOfReturnBitfields >= 12 /\ (settled38.returnBitfield12 # << >> /\ (settled38.returnBitfield12[1] \div 4) % 2 > 0) THEN (IF settled38.oeoid = << >> THEN <<[i \in 1 .. 18 |-> 0]>> ELSE settled38.oeoid) ELSE << >>]
        settled40 == [settled39 EXCEPT !.tradeDate = IF settled39.numberOfReturnBitfields >= 12 /\ (settled39.returnBitfield12 # << >> /\ (settled39.returnBitfield12[1] \div 8) % 2 > 0) THEN (IF settled39.tradeDate = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled39.tradeDate) ELSE << >>]
        settled41 == [settled40 EXCEPT !.clearingPrice = IF settled40.numberOfReturnBitfields >= 12 /\ (settled40.returnBitfield12 # << >> /\ (settled40.returnBitfield12[1] \div 16) % 2 > 0) THEN (IF settled40.clearingPrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled40.clearingPrice) ELSE << >>]
        settled42 == [settled41 EXCEPT !.clearingSymbol = IF settled41.numberOfReturnBitfields >= 12 /\ (settled41.returnBitfield12 # << >> /\ (settled41.returnBitfield12[1] \div 64) % 2 > 0) THEN (IF settled41.clearingSymbol = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled41.clearingSymbol) ELSE << >>]
        settled43 == [settled42 EXCEPT !.multilegReportingType = IF settled42.numberOfReturnBitfields >= 13 /\ (settled42.returnBitfield13 # << >> /\ (settled42.returnBitfield13[1] \div 128) % 2 > 0) THEN (IF settled42.multilegReportingType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled42.multilegReportingType) ELSE << >>]
        settled44 == [settled43 EXCEPT !.secondaryExecId = IF settled43.numberOfReturnBitfields >= 14 /\ (settled43.returnBitfield14 # << >> /\ (settled43.returnBitfield14[1] \div 16) % 2 > 0) THEN (IF settled43.secondaryExecId = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled43.secondaryExecId) ELSE << >>]
        settled45 == [settled44 EXCEPT !.frequentTraderId = IF settled44.numberOfReturnBitfields >= 16 /\ (settled44.returnBitfield16 # << >> /\ settled44.returnBitfield16[1] % 2 > 0) THEN (IF settled44.frequentTraderId = << >> THEN <<[i \in 1 .. 6 |-> 0]>> ELSE settled44.frequentTraderId) ELSE << >>]
    IN  settled45

ZeroTasRestatementMessage ==
    SettleTasRestatementMessage([ transactionTime         |-> [i \in 1 .. 8 |-> 0],
                                  clOrdId                 |-> [i \in 1 .. 20 |-> 0],
                                  execId                  |-> [i \in 1 .. 8 |-> 0],
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
                                  price                   |-> << >>,
                                  ordType                 |-> << >>,
                                  timeInForce             |-> << >>,
                                  minQty                  |-> << >>,
                                  symbolLong              |-> << >>,
                                  capacity                |-> << >>,
                                  account                 |-> << >>,
                                  clearingFirm            |-> << >>,
                                  clearingAccount         |-> << >>,
                                  preventMatch            |-> << >>,
                                  maturityDate            |-> << >>,
                                  openClose               |-> << >>,
                                  origClOrdId             |-> << >>,
                                  lastShares              |-> << >>,
                                  lastPx                  |-> << >>,
                                  feeCode                 |-> << >>,
                                  stopPx                  |-> << >>,
                                  cmtaNumber              |-> << >>,
                                  ctiCode                 |-> << >>,
                                  manualOrderIndicator    |-> << >>,
                                  oeoid                   |-> << >>,
                                  tradeDate               |-> << >>,
                                  clearingPrice           |-> << >>,
                                  clearingSymbol          |-> << >>,
                                  multilegReportingType   |-> << >>,
                                  secondaryExecId         |-> << >>,
                                  frequentTraderId        |-> << >> ])

(* Tas Restatement Message at zero, then each field in turn at the values it is checked at *)
CheckedTasRestatementMessage ==
    { ZeroTasRestatementMessage }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.transactionTime = one]) : one \in Sample(8) }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.clOrdId = one]) : one \in Sample(20) }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.execId = one]) : one \in Sample(8) }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.reserved1 = one]) : one \in Sample(1) }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.numberOfReturnBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.numberOfReturnBitfields = 7, !.returnBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.numberOfReturnBitfields = 9, !.returnBitfield9 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.numberOfReturnBitfields = 10, !.returnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.numberOfReturnBitfields = 11, !.returnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.numberOfReturnBitfields = 13, !.returnBitfield13 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.numberOfReturnBitfields = 14, !.returnBitfield14 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.numberOfReturnBitfields = 15, !.returnBitfield15 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.numberOfReturnBitfields = 17, !.returnBitfield17 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<1>>, !.side = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<4>>, !.price = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<1>>, !.symbolLong = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<1>>, !.account = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<2>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<4>>, !.clearingAccount = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<128>>, !.preventMatch = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<1>>, !.maturityDate = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<8>>, !.openClose = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<1>>, !.origClOrdId = one]) : one \in { <<held>> : held \in Sample(20) } }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<4>>, !.lastShares = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<8>>, !.lastPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<1>>, !.feeCode = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<4>>, !.stopPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.numberOfReturnBitfields = 9, !.returnBitfield9 = <<32>>, !.cmtaNumber = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = <<1>>, !.ctiCode = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = <<2>>, !.manualOrderIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = <<4>>, !.oeoid = one]) : one \in { <<held>> : held \in Sample(18) } }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = <<8>>, !.tradeDate = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = <<16>>, !.clearingPrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = <<64>>, !.clearingSymbol = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.numberOfReturnBitfields = 13, !.returnBitfield13 = <<128>>, !.multilegReportingType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.numberOfReturnBitfields = 14, !.returnBitfield14 = <<16>>, !.secondaryExecId = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleTasRestatementMessage([ZeroTasRestatementMessage EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = <<1>>, !.frequentTraderId = one]) : one \in { <<held>> : held \in Sample(6) } }

(***************************************************************************)
(* Variance Restatement Message                                            *)
(***************************************************************************)

VarianceRestatementMessage ==
    [ transactionTime         : Sample(8),
      clOrdId                 : Sample(20),
      execId                  : Sample(8),
      reserved1               : Sample(1),
      numberOfReturnBitfields : 0 .. 255,
      returnBitfield1         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield2         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield3         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield4         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield5         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield6         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield7         : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield8         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield9         : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield10        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield11        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield12        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield13        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield14        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield15        : { << >> } \cup { <<held>> : held \in Sample(1) },
      returnBitfield16        : { << >> } \cup { <<held>> : held \in 0 .. 255 },
      returnBitfield17        : { << >> } \cup { <<held>> : held \in Sample(1) },
      side                    : { << >> } \cup { <<held>> : held \in Sample(1) },
      price                   : { << >> } \cup { <<held>> : held \in Sample(8) },
      ordType                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      timeInForce             : { << >> } \cup { <<held>> : held \in Sample(1) },
      minQty                  : { << >> } \cup { <<held>> : held \in Sample(4) },
      symbolLong              : { << >> } \cup { <<held>> : held \in Sample(8) },
      capacity                : { << >> } \cup { <<held>> : held \in Sample(1) },
      account                 : { << >> } \cup { <<held>> : held \in Sample(16) },
      clearingFirm            : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingAccount         : { << >> } \cup { <<held>> : held \in Sample(4) },
      preventMatch            : { << >> } \cup { <<held>> : held \in Sample(3) },
      maturityDate            : { << >> } \cup { <<held>> : held \in Sample(4) },
      openClose               : { << >> } \cup { <<held>> : held \in Sample(1) },
      origClOrdId             : { << >> } \cup { <<held>> : held \in Sample(20) },
      lastShares              : { << >> } \cup { <<held>> : held \in Sample(4) },
      lastPx                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      feeCode                 : { << >> } \cup { <<held>> : held \in Sample(2) },
      stopPx                  : { << >> } \cup { <<held>> : held \in Sample(8) },
      cmtaNumber              : { << >> } \cup { <<held>> : held \in Sample(4) },
      ctiCode                 : { << >> } \cup { <<held>> : held \in Sample(1) },
      manualOrderIndicator    : { << >> } \cup { <<held>> : held \in Sample(1) },
      oeoid                   : { << >> } \cup { <<held>> : held \in Sample(18) },
      tradeDate               : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingPrice           : { << >> } \cup { <<held>> : held \in Sample(8) },
      clearingSize            : { << >> } \cup { <<held>> : held \in Sample(4) },
      clearingSymbol          : { << >> } \cup { <<held>> : held \in Sample(8) },
      multilegReportingType   : { << >> } \cup { <<held>> : held \in Sample(1) },
      secondaryExecId         : { << >> } \cup { <<held>> : held \in Sample(8) },
      frequentTraderId        : { << >> } \cup { <<held>> : held \in Sample(6) } ]

EncodeVarianceRestatementMessage(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.execId
        \o message.reserved1
        \o EncodeUIntBE(message.numberOfReturnBitfields, 1)
        \o (IF message.returnBitfield1 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield1[1], 1))
        \o (IF message.returnBitfield2 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield2[1], 1))
        \o (IF message.returnBitfield3 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield3[1], 1))
        \o (IF message.returnBitfield4 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield4[1], 1))
        \o (IF message.returnBitfield5 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield5[1], 1))
        \o (IF message.returnBitfield6 = << >> THEN << >> ELSE message.returnBitfield6[1])
        \o (IF message.returnBitfield7 = << >> THEN << >> ELSE message.returnBitfield7[1])
        \o (IF message.returnBitfield8 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield8[1], 1))
        \o (IF message.returnBitfield9 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield9[1], 1))
        \o (IF message.returnBitfield10 = << >> THEN << >> ELSE message.returnBitfield10[1])
        \o (IF message.returnBitfield11 = << >> THEN << >> ELSE message.returnBitfield11[1])
        \o (IF message.returnBitfield12 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield12[1], 1))
        \o (IF message.returnBitfield13 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield13[1], 1))
        \o (IF message.returnBitfield14 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield14[1], 1))
        \o (IF message.returnBitfield15 = << >> THEN << >> ELSE message.returnBitfield15[1])
        \o (IF message.returnBitfield16 = << >> THEN << >> ELSE EncodeUIntLE(message.returnBitfield16[1], 1))
        \o (IF message.returnBitfield17 = << >> THEN << >> ELSE message.returnBitfield17[1])
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
        \o (IF message.clearingSize = << >> THEN << >> ELSE message.clearingSize[1])
        \o (IF message.clearingSymbol = << >> THEN << >> ELSE message.clearingSymbol[1])
        \o (IF message.multilegReportingType = << >> THEN << >> ELSE message.multilegReportingType[1])
        \o (IF message.secondaryExecId = << >> THEN << >> ELSE message.secondaryExecId[1])
        \o (IF message.frequentTraderId = << >> THEN << >> ELSE message.frequentTraderId[1])

DecodeVarianceRestatementMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET execId == ReadBytes(clOrdId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(execId.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET numberOfReturnBitfields == ReadUIntBE(reserved1.rest, 1) IN IF ~numberOfReturnBitfields.ok THEN Fail ELSE
    LET returnBitfield1 == ReadWhen(numberOfReturnBitfields.value >= 1, ReadUIntLE(numberOfReturnBitfields.rest, 1), numberOfReturnBitfields.rest) IN IF ~returnBitfield1.ok THEN Fail ELSE
    LET returnBitfield2 == ReadWhen(numberOfReturnBitfields.value >= 2, ReadUIntLE(returnBitfield1.rest, 1), returnBitfield1.rest) IN IF ~returnBitfield2.ok THEN Fail ELSE
    LET returnBitfield3 == ReadWhen(numberOfReturnBitfields.value >= 3, ReadUIntLE(returnBitfield2.rest, 1), returnBitfield2.rest) IN IF ~returnBitfield3.ok THEN Fail ELSE
    LET returnBitfield4 == ReadWhen(numberOfReturnBitfields.value >= 4, ReadUIntLE(returnBitfield3.rest, 1), returnBitfield3.rest) IN IF ~returnBitfield4.ok THEN Fail ELSE
    LET returnBitfield5 == ReadWhen(numberOfReturnBitfields.value >= 5, ReadUIntLE(returnBitfield4.rest, 1), returnBitfield4.rest) IN IF ~returnBitfield5.ok THEN Fail ELSE
    LET returnBitfield6 == ReadWhen(numberOfReturnBitfields.value >= 6, ReadBytes(returnBitfield5.rest, 1), returnBitfield5.rest) IN IF ~returnBitfield6.ok THEN Fail ELSE
    LET returnBitfield7 == ReadWhen(numberOfReturnBitfields.value >= 7, ReadBytes(returnBitfield6.rest, 1), returnBitfield6.rest) IN IF ~returnBitfield7.ok THEN Fail ELSE
    LET returnBitfield8 == ReadWhen(numberOfReturnBitfields.value >= 8, ReadUIntLE(returnBitfield7.rest, 1), returnBitfield7.rest) IN IF ~returnBitfield8.ok THEN Fail ELSE
    LET returnBitfield9 == ReadWhen(numberOfReturnBitfields.value >= 9, ReadUIntLE(returnBitfield8.rest, 1), returnBitfield8.rest) IN IF ~returnBitfield9.ok THEN Fail ELSE
    LET returnBitfield10 == ReadWhen(numberOfReturnBitfields.value >= 10, ReadBytes(returnBitfield9.rest, 1), returnBitfield9.rest) IN IF ~returnBitfield10.ok THEN Fail ELSE
    LET returnBitfield11 == ReadWhen(numberOfReturnBitfields.value >= 11, ReadBytes(returnBitfield10.rest, 1), returnBitfield10.rest) IN IF ~returnBitfield11.ok THEN Fail ELSE
    LET returnBitfield12 == ReadWhen(numberOfReturnBitfields.value >= 12, ReadUIntLE(returnBitfield11.rest, 1), returnBitfield11.rest) IN IF ~returnBitfield12.ok THEN Fail ELSE
    LET returnBitfield13 == ReadWhen(numberOfReturnBitfields.value >= 13, ReadUIntLE(returnBitfield12.rest, 1), returnBitfield12.rest) IN IF ~returnBitfield13.ok THEN Fail ELSE
    LET returnBitfield14 == ReadWhen(numberOfReturnBitfields.value >= 14, ReadUIntLE(returnBitfield13.rest, 1), returnBitfield13.rest) IN IF ~returnBitfield14.ok THEN Fail ELSE
    LET returnBitfield15 == ReadWhen(numberOfReturnBitfields.value >= 15, ReadBytes(returnBitfield14.rest, 1), returnBitfield14.rest) IN IF ~returnBitfield15.ok THEN Fail ELSE
    LET returnBitfield16 == ReadWhen(numberOfReturnBitfields.value >= 16, ReadUIntLE(returnBitfield15.rest, 1), returnBitfield15.rest) IN IF ~returnBitfield16.ok THEN Fail ELSE
    LET returnBitfield17 == ReadWhen(numberOfReturnBitfields.value >= 17, ReadBytes(returnBitfield16.rest, 1), returnBitfield16.rest) IN IF ~returnBitfield17.ok THEN Fail ELSE
    LET side == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ returnBitfield1.value[1] % 2 > 0), ReadBytes(returnBitfield17.rest, 1), returnBitfield17.rest) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 4) % 2 > 0), ReadBytes(side.rest, 8), side.rest) IN IF ~price.ok THEN Fail ELSE
    LET ordType == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 16) % 2 > 0), ReadBytes(price.rest, 1), price.rest) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 32) % 2 > 0), ReadBytes(ordType.rest, 1), ordType.rest) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadWhen(numberOfReturnBitfields.value >= 1 /\ (returnBitfield1.value # << >> /\ (returnBitfield1.value[1] \div 64) % 2 > 0), ReadBytes(timeInForce.rest, 4), timeInForce.rest) IN IF ~minQty.ok THEN Fail ELSE
    LET symbolLong == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ returnBitfield2.value[1] % 2 > 0), ReadBytes(minQty.rest, 8), minQty.rest) IN IF ~symbolLong.ok THEN Fail ELSE
    LET capacity == ReadWhen(numberOfReturnBitfields.value >= 2 /\ (returnBitfield2.value # << >> /\ (returnBitfield2.value[1] \div 64) % 2 > 0), ReadBytes(symbolLong.rest, 1), symbolLong.rest) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ returnBitfield3.value[1] % 2 > 0), ReadBytes(capacity.rest, 16), capacity.rest) IN IF ~account.ok THEN Fail ELSE
    LET clearingFirm == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 2) % 2 > 0), ReadBytes(account.rest, 4), account.rest) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 4) % 2 > 0), ReadBytes(clearingFirm.rest, 4), clearingFirm.rest) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET preventMatch == ReadWhen(numberOfReturnBitfields.value >= 3 /\ (returnBitfield3.value # << >> /\ (returnBitfield3.value[1] \div 128) % 2 > 0), ReadBytes(clearingAccount.rest, 3), clearingAccount.rest) IN IF ~preventMatch.ok THEN Fail ELSE
    LET maturityDate == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ returnBitfield4.value[1] % 2 > 0), ReadBytes(preventMatch.rest, 4), preventMatch.rest) IN IF ~maturityDate.ok THEN Fail ELSE
    LET openClose == ReadWhen(numberOfReturnBitfields.value >= 4 /\ (returnBitfield4.value # << >> /\ (returnBitfield4.value[1] \div 8) % 2 > 0), ReadBytes(maturityDate.rest, 1), maturityDate.rest) IN IF ~openClose.ok THEN Fail ELSE
    LET origClOrdId == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ returnBitfield5.value[1] % 2 > 0), ReadBytes(openClose.rest, 20), openClose.rest) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET lastShares == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 4) % 2 > 0), ReadBytes(origClOrdId.rest, 4), origClOrdId.rest) IN IF ~lastShares.ok THEN Fail ELSE
    LET lastPx == ReadWhen(numberOfReturnBitfields.value >= 5 /\ (returnBitfield5.value # << >> /\ (returnBitfield5.value[1] \div 8) % 2 > 0), ReadBytes(lastShares.rest, 8), lastShares.rest) IN IF ~lastPx.ok THEN Fail ELSE
    LET feeCode == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ returnBitfield8.value[1] % 2 > 0), ReadBytes(lastPx.rest, 2), lastPx.rest) IN IF ~feeCode.ok THEN Fail ELSE
    LET stopPx == ReadWhen(numberOfReturnBitfields.value >= 8 /\ (returnBitfield8.value # << >> /\ (returnBitfield8.value[1] \div 4) % 2 > 0), ReadBytes(feeCode.rest, 8), feeCode.rest) IN IF ~stopPx.ok THEN Fail ELSE
    LET cmtaNumber == ReadWhen(numberOfReturnBitfields.value >= 9 /\ (returnBitfield9.value # << >> /\ (returnBitfield9.value[1] \div 32) % 2 > 0), ReadBytes(stopPx.rest, 4), stopPx.rest) IN IF ~cmtaNumber.ok THEN Fail ELSE
    LET ctiCode == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (returnBitfield12.value # << >> /\ returnBitfield12.value[1] % 2 > 0), ReadBytes(cmtaNumber.rest, 1), cmtaNumber.rest) IN IF ~ctiCode.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (returnBitfield12.value # << >> /\ (returnBitfield12.value[1] \div 2) % 2 > 0), ReadBytes(ctiCode.rest, 1), ctiCode.rest) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET oeoid == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (returnBitfield12.value # << >> /\ (returnBitfield12.value[1] \div 4) % 2 > 0), ReadBytes(manualOrderIndicator.rest, 18), manualOrderIndicator.rest) IN IF ~oeoid.ok THEN Fail ELSE
    LET tradeDate == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (returnBitfield12.value # << >> /\ (returnBitfield12.value[1] \div 8) % 2 > 0), ReadBytes(oeoid.rest, 4), oeoid.rest) IN IF ~tradeDate.ok THEN Fail ELSE
    LET clearingPrice == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (returnBitfield12.value # << >> /\ (returnBitfield12.value[1] \div 16) % 2 > 0), ReadBytes(tradeDate.rest, 8), tradeDate.rest) IN IF ~clearingPrice.ok THEN Fail ELSE
    LET clearingSize == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (returnBitfield12.value # << >> /\ (returnBitfield12.value[1] \div 32) % 2 > 0), ReadBytes(clearingPrice.rest, 4), clearingPrice.rest) IN IF ~clearingSize.ok THEN Fail ELSE
    LET clearingSymbol == ReadWhen(numberOfReturnBitfields.value >= 12 /\ (returnBitfield12.value # << >> /\ (returnBitfield12.value[1] \div 64) % 2 > 0), ReadBytes(clearingSize.rest, 8), clearingSize.rest) IN IF ~clearingSymbol.ok THEN Fail ELSE
    LET multilegReportingType == ReadWhen(numberOfReturnBitfields.value >= 13 /\ (returnBitfield13.value # << >> /\ (returnBitfield13.value[1] \div 128) % 2 > 0), ReadBytes(clearingSymbol.rest, 1), clearingSymbol.rest) IN IF ~multilegReportingType.ok THEN Fail ELSE
    LET secondaryExecId == ReadWhen(numberOfReturnBitfields.value >= 14 /\ (returnBitfield14.value # << >> /\ (returnBitfield14.value[1] \div 16) % 2 > 0), ReadBytes(multilegReportingType.rest, 8), multilegReportingType.rest) IN IF ~secondaryExecId.ok THEN Fail ELSE
    LET frequentTraderId == ReadWhen(numberOfReturnBitfields.value >= 16 /\ (returnBitfield16.value # << >> /\ returnBitfield16.value[1] % 2 > 0), ReadBytes(secondaryExecId.rest, 6), secondaryExecId.rest) IN IF ~frequentTraderId.ok THEN Fail ELSE
    Ok([ transactionTime         |-> transactionTime.value,
         clOrdId                 |-> clOrdId.value,
         execId                  |-> execId.value,
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
         price                   |-> price.value,
         ordType                 |-> ordType.value,
         timeInForce             |-> timeInForce.value,
         minQty                  |-> minQty.value,
         symbolLong              |-> symbolLong.value,
         capacity                |-> capacity.value,
         account                 |-> account.value,
         clearingFirm            |-> clearingFirm.value,
         clearingAccount         |-> clearingAccount.value,
         preventMatch            |-> preventMatch.value,
         maturityDate            |-> maturityDate.value,
         openClose               |-> openClose.value,
         origClOrdId             |-> origClOrdId.value,
         lastShares              |-> lastShares.value,
         lastPx                  |-> lastPx.value,
         feeCode                 |-> feeCode.value,
         stopPx                  |-> stopPx.value,
         cmtaNumber              |-> cmtaNumber.value,
         ctiCode                 |-> ctiCode.value,
         manualOrderIndicator    |-> manualOrderIndicator.value,
         oeoid                   |-> oeoid.value,
         tradeDate               |-> tradeDate.value,
         clearingPrice           |-> clearingPrice.value,
         clearingSize            |-> clearingSize.value,
         clearingSymbol          |-> clearingSymbol.value,
         multilegReportingType   |-> multilegReportingType.value,
         secondaryExecId         |-> secondaryExecId.value,
         frequentTraderId        |-> frequentTraderId.value ], frequentTraderId.rest)

(* Variance Restatement Message with each field marked present by fields before it there exactly where they say *)
SettleVarianceRestatementMessage(message) ==
    LET settled1 == [message EXCEPT !.returnBitfield1 = IF message.numberOfReturnBitfields >= 1 THEN (IF message.returnBitfield1 = << >> THEN <<0>> ELSE message.returnBitfield1) ELSE << >>]
        settled2 == [settled1 EXCEPT !.returnBitfield2 = IF settled1.numberOfReturnBitfields >= 2 THEN (IF settled1.returnBitfield2 = << >> THEN <<0>> ELSE settled1.returnBitfield2) ELSE << >>]
        settled3 == [settled2 EXCEPT !.returnBitfield3 = IF settled2.numberOfReturnBitfields >= 3 THEN (IF settled2.returnBitfield3 = << >> THEN <<0>> ELSE settled2.returnBitfield3) ELSE << >>]
        settled4 == [settled3 EXCEPT !.returnBitfield4 = IF settled3.numberOfReturnBitfields >= 4 THEN (IF settled3.returnBitfield4 = << >> THEN <<0>> ELSE settled3.returnBitfield4) ELSE << >>]
        settled5 == [settled4 EXCEPT !.returnBitfield5 = IF settled4.numberOfReturnBitfields >= 5 THEN (IF settled4.returnBitfield5 = << >> THEN <<0>> ELSE settled4.returnBitfield5) ELSE << >>]
        settled6 == [settled5 EXCEPT !.returnBitfield6 = IF settled5.numberOfReturnBitfields >= 6 THEN (IF settled5.returnBitfield6 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled5.returnBitfield6) ELSE << >>]
        settled7 == [settled6 EXCEPT !.returnBitfield7 = IF settled6.numberOfReturnBitfields >= 7 THEN (IF settled6.returnBitfield7 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled6.returnBitfield7) ELSE << >>]
        settled8 == [settled7 EXCEPT !.returnBitfield8 = IF settled7.numberOfReturnBitfields >= 8 THEN (IF settled7.returnBitfield8 = << >> THEN <<0>> ELSE settled7.returnBitfield8) ELSE << >>]
        settled9 == [settled8 EXCEPT !.returnBitfield9 = IF settled8.numberOfReturnBitfields >= 9 THEN (IF settled8.returnBitfield9 = << >> THEN <<0>> ELSE settled8.returnBitfield9) ELSE << >>]
        settled10 == [settled9 EXCEPT !.returnBitfield10 = IF settled9.numberOfReturnBitfields >= 10 THEN (IF settled9.returnBitfield10 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled9.returnBitfield10) ELSE << >>]
        settled11 == [settled10 EXCEPT !.returnBitfield11 = IF settled10.numberOfReturnBitfields >= 11 THEN (IF settled10.returnBitfield11 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled10.returnBitfield11) ELSE << >>]
        settled12 == [settled11 EXCEPT !.returnBitfield12 = IF settled11.numberOfReturnBitfields >= 12 THEN (IF settled11.returnBitfield12 = << >> THEN <<0>> ELSE settled11.returnBitfield12) ELSE << >>]
        settled13 == [settled12 EXCEPT !.returnBitfield13 = IF settled12.numberOfReturnBitfields >= 13 THEN (IF settled12.returnBitfield13 = << >> THEN <<0>> ELSE settled12.returnBitfield13) ELSE << >>]
        settled14 == [settled13 EXCEPT !.returnBitfield14 = IF settled13.numberOfReturnBitfields >= 14 THEN (IF settled13.returnBitfield14 = << >> THEN <<0>> ELSE settled13.returnBitfield14) ELSE << >>]
        settled15 == [settled14 EXCEPT !.returnBitfield15 = IF settled14.numberOfReturnBitfields >= 15 THEN (IF settled14.returnBitfield15 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled14.returnBitfield15) ELSE << >>]
        settled16 == [settled15 EXCEPT !.returnBitfield16 = IF settled15.numberOfReturnBitfields >= 16 THEN (IF settled15.returnBitfield16 = << >> THEN <<0>> ELSE settled15.returnBitfield16) ELSE << >>]
        settled17 == [settled16 EXCEPT !.returnBitfield17 = IF settled16.numberOfReturnBitfields >= 17 THEN (IF settled16.returnBitfield17 = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled16.returnBitfield17) ELSE << >>]
        settled18 == [settled17 EXCEPT !.side = IF settled17.numberOfReturnBitfields >= 1 /\ (settled17.returnBitfield1 # << >> /\ settled17.returnBitfield1[1] % 2 > 0) THEN (IF settled17.side = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled17.side) ELSE << >>]
        settled19 == [settled18 EXCEPT !.price = IF settled18.numberOfReturnBitfields >= 1 /\ (settled18.returnBitfield1 # << >> /\ (settled18.returnBitfield1[1] \div 4) % 2 > 0) THEN (IF settled18.price = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled18.price) ELSE << >>]
        settled20 == [settled19 EXCEPT !.ordType = IF settled19.numberOfReturnBitfields >= 1 /\ (settled19.returnBitfield1 # << >> /\ (settled19.returnBitfield1[1] \div 16) % 2 > 0) THEN (IF settled19.ordType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled19.ordType) ELSE << >>]
        settled21 == [settled20 EXCEPT !.timeInForce = IF settled20.numberOfReturnBitfields >= 1 /\ (settled20.returnBitfield1 # << >> /\ (settled20.returnBitfield1[1] \div 32) % 2 > 0) THEN (IF settled20.timeInForce = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled20.timeInForce) ELSE << >>]
        settled22 == [settled21 EXCEPT !.minQty = IF settled21.numberOfReturnBitfields >= 1 /\ (settled21.returnBitfield1 # << >> /\ (settled21.returnBitfield1[1] \div 64) % 2 > 0) THEN (IF settled21.minQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled21.minQty) ELSE << >>]
        settled23 == [settled22 EXCEPT !.symbolLong = IF settled22.numberOfReturnBitfields >= 2 /\ (settled22.returnBitfield2 # << >> /\ settled22.returnBitfield2[1] % 2 > 0) THEN (IF settled22.symbolLong = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled22.symbolLong) ELSE << >>]
        settled24 == [settled23 EXCEPT !.capacity = IF settled23.numberOfReturnBitfields >= 2 /\ (settled23.returnBitfield2 # << >> /\ (settled23.returnBitfield2[1] \div 64) % 2 > 0) THEN (IF settled23.capacity = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled23.capacity) ELSE << >>]
        settled25 == [settled24 EXCEPT !.account = IF settled24.numberOfReturnBitfields >= 3 /\ (settled24.returnBitfield3 # << >> /\ settled24.returnBitfield3[1] % 2 > 0) THEN (IF settled24.account = << >> THEN <<[i \in 1 .. 16 |-> 0]>> ELSE settled24.account) ELSE << >>]
        settled26 == [settled25 EXCEPT !.clearingFirm = IF settled25.numberOfReturnBitfields >= 3 /\ (settled25.returnBitfield3 # << >> /\ (settled25.returnBitfield3[1] \div 2) % 2 > 0) THEN (IF settled25.clearingFirm = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled25.clearingFirm) ELSE << >>]
        settled27 == [settled26 EXCEPT !.clearingAccount = IF settled26.numberOfReturnBitfields >= 3 /\ (settled26.returnBitfield3 # << >> /\ (settled26.returnBitfield3[1] \div 4) % 2 > 0) THEN (IF settled26.clearingAccount = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled26.clearingAccount) ELSE << >>]
        settled28 == [settled27 EXCEPT !.preventMatch = IF settled27.numberOfReturnBitfields >= 3 /\ (settled27.returnBitfield3 # << >> /\ (settled27.returnBitfield3[1] \div 128) % 2 > 0) THEN (IF settled27.preventMatch = << >> THEN <<[i \in 1 .. 3 |-> 0]>> ELSE settled27.preventMatch) ELSE << >>]
        settled29 == [settled28 EXCEPT !.maturityDate = IF settled28.numberOfReturnBitfields >= 4 /\ (settled28.returnBitfield4 # << >> /\ settled28.returnBitfield4[1] % 2 > 0) THEN (IF settled28.maturityDate = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled28.maturityDate) ELSE << >>]
        settled30 == [settled29 EXCEPT !.openClose = IF settled29.numberOfReturnBitfields >= 4 /\ (settled29.returnBitfield4 # << >> /\ (settled29.returnBitfield4[1] \div 8) % 2 > 0) THEN (IF settled29.openClose = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled29.openClose) ELSE << >>]
        settled31 == [settled30 EXCEPT !.origClOrdId = IF settled30.numberOfReturnBitfields >= 5 /\ (settled30.returnBitfield5 # << >> /\ settled30.returnBitfield5[1] % 2 > 0) THEN (IF settled30.origClOrdId = << >> THEN <<[i \in 1 .. 20 |-> 0]>> ELSE settled30.origClOrdId) ELSE << >>]
        settled32 == [settled31 EXCEPT !.lastShares = IF settled31.numberOfReturnBitfields >= 5 /\ (settled31.returnBitfield5 # << >> /\ (settled31.returnBitfield5[1] \div 4) % 2 > 0) THEN (IF settled31.lastShares = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled31.lastShares) ELSE << >>]
        settled33 == [settled32 EXCEPT !.lastPx = IF settled32.numberOfReturnBitfields >= 5 /\ (settled32.returnBitfield5 # << >> /\ (settled32.returnBitfield5[1] \div 8) % 2 > 0) THEN (IF settled32.lastPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled32.lastPx) ELSE << >>]
        settled34 == [settled33 EXCEPT !.feeCode = IF settled33.numberOfReturnBitfields >= 8 /\ (settled33.returnBitfield8 # << >> /\ settled33.returnBitfield8[1] % 2 > 0) THEN (IF settled33.feeCode = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled33.feeCode) ELSE << >>]
        settled35 == [settled34 EXCEPT !.stopPx = IF settled34.numberOfReturnBitfields >= 8 /\ (settled34.returnBitfield8 # << >> /\ (settled34.returnBitfield8[1] \div 4) % 2 > 0) THEN (IF settled34.stopPx = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled34.stopPx) ELSE << >>]
        settled36 == [settled35 EXCEPT !.cmtaNumber = IF settled35.numberOfReturnBitfields >= 9 /\ (settled35.returnBitfield9 # << >> /\ (settled35.returnBitfield9[1] \div 32) % 2 > 0) THEN (IF settled35.cmtaNumber = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled35.cmtaNumber) ELSE << >>]
        settled37 == [settled36 EXCEPT !.ctiCode = IF settled36.numberOfReturnBitfields >= 12 /\ (settled36.returnBitfield12 # << >> /\ settled36.returnBitfield12[1] % 2 > 0) THEN (IF settled36.ctiCode = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled36.ctiCode) ELSE << >>]
        settled38 == [settled37 EXCEPT !.manualOrderIndicator = IF settled37.numberOfReturnBitfields >= 12 /\ (settled37.returnBitfield12 # << >> /\ (settled37.returnBitfield12[1] \div 2) % 2 > 0) THEN (IF settled37.manualOrderIndicator = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled37.manualOrderIndicator) ELSE << >>]
        settled39 == [settled38 EXCEPT !.oeoid = IF settled38.numberOfReturnBitfields >= 12 /\ (settled38.returnBitfield12 # << >> /\ (settled38.returnBitfield12[1] \div 4) % 2 > 0) THEN (IF settled38.oeoid = << >> THEN <<[i \in 1 .. 18 |-> 0]>> ELSE settled38.oeoid) ELSE << >>]
        settled40 == [settled39 EXCEPT !.tradeDate = IF settled39.numberOfReturnBitfields >= 12 /\ (settled39.returnBitfield12 # << >> /\ (settled39.returnBitfield12[1] \div 8) % 2 > 0) THEN (IF settled39.tradeDate = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled39.tradeDate) ELSE << >>]
        settled41 == [settled40 EXCEPT !.clearingPrice = IF settled40.numberOfReturnBitfields >= 12 /\ (settled40.returnBitfield12 # << >> /\ (settled40.returnBitfield12[1] \div 16) % 2 > 0) THEN (IF settled40.clearingPrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled40.clearingPrice) ELSE << >>]
        settled42 == [settled41 EXCEPT !.clearingSize = IF settled41.numberOfReturnBitfields >= 12 /\ (settled41.returnBitfield12 # << >> /\ (settled41.returnBitfield12[1] \div 32) % 2 > 0) THEN (IF settled41.clearingSize = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled41.clearingSize) ELSE << >>]
        settled43 == [settled42 EXCEPT !.clearingSymbol = IF settled42.numberOfReturnBitfields >= 12 /\ (settled42.returnBitfield12 # << >> /\ (settled42.returnBitfield12[1] \div 64) % 2 > 0) THEN (IF settled42.clearingSymbol = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled42.clearingSymbol) ELSE << >>]
        settled44 == [settled43 EXCEPT !.multilegReportingType = IF settled43.numberOfReturnBitfields >= 13 /\ (settled43.returnBitfield13 # << >> /\ (settled43.returnBitfield13[1] \div 128) % 2 > 0) THEN (IF settled43.multilegReportingType = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled43.multilegReportingType) ELSE << >>]
        settled45 == [settled44 EXCEPT !.secondaryExecId = IF settled44.numberOfReturnBitfields >= 14 /\ (settled44.returnBitfield14 # << >> /\ (settled44.returnBitfield14[1] \div 16) % 2 > 0) THEN (IF settled44.secondaryExecId = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled44.secondaryExecId) ELSE << >>]
        settled46 == [settled45 EXCEPT !.frequentTraderId = IF settled45.numberOfReturnBitfields >= 16 /\ (settled45.returnBitfield16 # << >> /\ settled45.returnBitfield16[1] % 2 > 0) THEN (IF settled45.frequentTraderId = << >> THEN <<[i \in 1 .. 6 |-> 0]>> ELSE settled45.frequentTraderId) ELSE << >>]
    IN  settled46

ZeroVarianceRestatementMessage ==
    SettleVarianceRestatementMessage([ transactionTime         |-> [i \in 1 .. 8 |-> 0],
                                       clOrdId                 |-> [i \in 1 .. 20 |-> 0],
                                       execId                  |-> [i \in 1 .. 8 |-> 0],
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
                                       price                   |-> << >>,
                                       ordType                 |-> << >>,
                                       timeInForce             |-> << >>,
                                       minQty                  |-> << >>,
                                       symbolLong              |-> << >>,
                                       capacity                |-> << >>,
                                       account                 |-> << >>,
                                       clearingFirm            |-> << >>,
                                       clearingAccount         |-> << >>,
                                       preventMatch            |-> << >>,
                                       maturityDate            |-> << >>,
                                       openClose               |-> << >>,
                                       origClOrdId             |-> << >>,
                                       lastShares              |-> << >>,
                                       lastPx                  |-> << >>,
                                       feeCode                 |-> << >>,
                                       stopPx                  |-> << >>,
                                       cmtaNumber              |-> << >>,
                                       ctiCode                 |-> << >>,
                                       manualOrderIndicator    |-> << >>,
                                       oeoid                   |-> << >>,
                                       tradeDate               |-> << >>,
                                       clearingPrice           |-> << >>,
                                       clearingSize            |-> << >>,
                                       clearingSymbol          |-> << >>,
                                       multilegReportingType   |-> << >>,
                                       secondaryExecId         |-> << >>,
                                       frequentTraderId        |-> << >> ])

(* Variance Restatement Message at zero, then each field in turn at the values it is checked at *)
CheckedVarianceRestatementMessage ==
    { ZeroVarianceRestatementMessage }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.transactionTime = one]) : one \in Sample(8) }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.clOrdId = one]) : one \in Sample(20) }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.execId = one]) : one \in Sample(8) }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.reserved1 = one]) : one \in Sample(1) }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.numberOfReturnBitfields = one]) : one \in {0, 1, 255} }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.numberOfReturnBitfields = 6, !.returnBitfield6 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.numberOfReturnBitfields = 7, !.returnBitfield7 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.numberOfReturnBitfields = 9, !.returnBitfield9 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.numberOfReturnBitfields = 10, !.returnBitfield10 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.numberOfReturnBitfields = 11, !.returnBitfield11 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.numberOfReturnBitfields = 13, !.returnBitfield13 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.numberOfReturnBitfields = 14, !.returnBitfield14 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.numberOfReturnBitfields = 15, !.returnBitfield15 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = one]) : one \in { <<held>> : held \in {0, 1, 255} } }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.numberOfReturnBitfields = 17, !.returnBitfield17 = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<1>>, !.side = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<4>>, !.price = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<16>>, !.ordType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<32>>, !.timeInForce = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.numberOfReturnBitfields = 1, !.returnBitfield1 = <<64>>, !.minQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<1>>, !.symbolLong = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.numberOfReturnBitfields = 2, !.returnBitfield2 = <<64>>, !.capacity = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<1>>, !.account = one]) : one \in { <<held>> : held \in Sample(16) } }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<2>>, !.clearingFirm = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<4>>, !.clearingAccount = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.numberOfReturnBitfields = 3, !.returnBitfield3 = <<128>>, !.preventMatch = one]) : one \in { <<held>> : held \in Sample(3) } }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<1>>, !.maturityDate = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.numberOfReturnBitfields = 4, !.returnBitfield4 = <<8>>, !.openClose = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<1>>, !.origClOrdId = one]) : one \in { <<held>> : held \in Sample(20) } }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<4>>, !.lastShares = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.numberOfReturnBitfields = 5, !.returnBitfield5 = <<8>>, !.lastPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<1>>, !.feeCode = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.numberOfReturnBitfields = 8, !.returnBitfield8 = <<4>>, !.stopPx = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.numberOfReturnBitfields = 9, !.returnBitfield9 = <<32>>, !.cmtaNumber = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = <<1>>, !.ctiCode = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = <<2>>, !.manualOrderIndicator = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = <<4>>, !.oeoid = one]) : one \in { <<held>> : held \in Sample(18) } }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = <<8>>, !.tradeDate = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = <<16>>, !.clearingPrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = <<32>>, !.clearingSize = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.numberOfReturnBitfields = 12, !.returnBitfield12 = <<64>>, !.clearingSymbol = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.numberOfReturnBitfields = 13, !.returnBitfield13 = <<128>>, !.multilegReportingType = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.numberOfReturnBitfields = 14, !.returnBitfield14 = <<16>>, !.secondaryExecId = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleVarianceRestatementMessage([ZeroVarianceRestatementMessage EXCEPT !.numberOfReturnBitfields = 16, !.returnBitfield16 = <<1>>, !.frequentTraderId = one]) : one \in { <<held>> : held \in Sample(6) } }

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
PurgeOrderMessageCode == 71  \* 0x47
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
RiskResetAcknowledgmentMessageCode == 87  \* 0x57
MassCancelAcknowledgmentMessageCode == 54  \* 0x36
TasRestatementMessageCode == 73  \* 0x49
VarianceRestatementMessageCode == 74  \* 0x4a
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
        \cup [ tag : {PurgeOrderMessageCode}, body : PurgeOrderMessage ]
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
        \cup [ tag : {RiskResetAcknowledgmentMessageCode}, body : RiskResetAcknowledgmentMessage ]
        \cup [ tag : {MassCancelAcknowledgmentMessageCode}, body : MassCancelAcknowledgmentMessage ]
        \cup [ tag : {TasRestatementMessageCode}, body : TasRestatementMessage ]
        \cup [ tag : {VarianceRestatementMessageCode}, body : VarianceRestatementMessage ]
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
      [] message.tag = PurgeOrderMessageCode -> EncodePurgeOrderMessage(message.body)
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
      [] message.tag = RiskResetAcknowledgmentMessageCode -> EncodeRiskResetAcknowledgmentMessage(message.body)
      [] message.tag = MassCancelAcknowledgmentMessageCode -> EncodeMassCancelAcknowledgmentMessage(message.body)
      [] message.tag = TasRestatementMessageCode -> EncodeTasRestatementMessage(message.body)
      [] message.tag = VarianceRestatementMessageCode -> EncodeVarianceRestatementMessage(message.body)
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
              [] tag = PurgeOrderMessageCode -> DecodePurgeOrderMessage(bytes)
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
              [] tag = RiskResetAcknowledgmentMessageCode -> DecodeRiskResetAcknowledgmentMessage(bytes)
              [] tag = MassCancelAcknowledgmentMessageCode -> DecodeMassCancelAcknowledgmentMessage(bytes)
              [] tag = TasRestatementMessageCode -> DecodeTasRestatementMessage(bytes)
              [] tag = VarianceRestatementMessageCode -> DecodeVarianceRestatementMessage(bytes)
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
        \cup { [tag |-> PurgeOrderMessageCode, body |-> one] : one \in CheckedPurgeOrderMessage }
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
        \cup { [tag |-> RiskResetAcknowledgmentMessageCode, body |-> one] : one \in CheckedRiskResetAcknowledgmentMessage }
        \cup { [tag |-> MassCancelAcknowledgmentMessageCode, body |-> one] : one \in CheckedMassCancelAcknowledgmentMessage }
        \cup { [tag |-> TasRestatementMessageCode, body |-> one] : one \in CheckedTasRestatementMessage }
        \cup { [tag |-> VarianceRestatementMessageCode, body |-> one] : one \in CheckedVarianceRestatementMessage }
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
RoundTripUnitSequence ==
    \A message \in CheckedUnitSequence :
        LET read == DecodeUnitSequence(EncodeUnitSequence(message))
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
RoundTripUnitSequence2 ==
    \A message \in CheckedUnitSequence2 :
        LET read == DecodeUnitSequence2(EncodeUnitSequence2(message))
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

(* Every Quote Group decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteGroup ==
    \A message \in CheckedQuoteGroup :
        LET read == DecodeQuoteGroup(EncodeQuoteGroup(message))
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

(* Every Purge Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPurgeOrderMessage ==
    \A message \in CheckedPurgeOrderMessage :
        LET read == DecodePurgeOrderMessage(EncodePurgeOrderMessage(message))
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

(* Every Risk Reset Acknowledgment Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRiskResetAcknowledgmentMessage ==
    \A message \in CheckedRiskResetAcknowledgmentMessage :
        LET read == DecodeRiskResetAcknowledgmentMessage(EncodeRiskResetAcknowledgmentMessage(message))
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

(* Every Tas Restatement Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTasRestatementMessage ==
    \A message \in CheckedTasRestatementMessage :
        LET read == DecodeTasRestatementMessage(EncodeTasRestatementMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Variance Restatement Message decodes back to what was encoded, and leaves nothing over *)
RoundTripVarianceRestatementMessage ==
    \A message \in CheckedVarianceRestatementMessage :
        LET read == DecodeVarianceRestatementMessage(EncodeVarianceRestatementMessage(message))
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
