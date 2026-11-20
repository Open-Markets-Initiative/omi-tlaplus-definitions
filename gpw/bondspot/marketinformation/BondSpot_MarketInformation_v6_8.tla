------------------ MODULE BondSpot_MarketInformation_v6_8 ------------------
(***************************************************************************)
(* Giełda Papierów Wartościowych w Warszawie BondSpot Market Information   *)
(* v6.8                                                                    *)
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
(* Note: a Delivery Flag of 16 to 255 says Message Buffer was transformed, *)
(* and one of 0 to 15 that it was not, so it is then read as it stands.    *)
(*                                                                         *)
(* Note: Class Phase is written as 15 slots, however many of them the      *)
(* count beside it says are in use.                                        *)
(*                                                                         *)
(* Note: Depositary List is written as 5 slots, however many of them the   *)
(* count beside it says are in use.                                        *)
(*                                                                         *)
(* Note: Message Buffer untransformed is as many Message as Number Msg     *)
(* Entries says, which is read beside the flag and handed to the choice:   *)
(* the count says how many the bytes hold, and transformed they hold a run *)
(* no reading of them states, so it is carried rather than written from    *)
(* the run.                                                                *)
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
(* Message Buffer                                                          *)
(***************************************************************************)

MessageBufferZlib ==
    [ transformed : SampleBytes ]

EncodeMessageBufferZlib(message) ==
    message.transformed

DecodeMessageBufferZlib(bytes) ==
    LET transformed == Ok(bytes, << >>) IN IF ~transformed.ok THEN Fail ELSE
    Ok([ transformed |-> transformed.value ], transformed.rest)

ZeroMessageBufferZlib ==
    [ transformed |-> << >> ]

(* Message Buffer at zero, then each field in turn at the values it is checked at *)
CheckedMessageBufferZlib ==
    { ZeroMessageBufferZlib }
        \cup { [ZeroMessageBufferZlib EXCEPT !.transformed = one] : one \in SampleBytes }

(***************************************************************************)
(* Class State Change Message: 24 bytes                                    *)
(***************************************************************************)

ClassStateChangeMessage ==
    [ sourceSeqNum         : Sample(4),
      sourceTime           : Sample(4),
      systemId             : Sample(4),
      sourceTimeMicroSecs  : Sample(2),
      instrumentGroupCode  : Sample(3),
      instrumentGroupState : Sample(1),
      sessionType          : Sample(1),
      reserved1            : Sample(1),
      classState           : Sample(4) ]

EncodeClassStateChangeMessage(message) ==
    message.sourceSeqNum
        \o message.sourceTime
        \o message.systemId
        \o message.sourceTimeMicroSecs
        \o message.instrumentGroupCode
        \o message.instrumentGroupState
        \o message.sessionType
        \o message.reserved1
        \o message.classState

DecodeClassStateChangeMessage(bytes) ==
    LET sourceSeqNum == ReadBytes(bytes, 4) IN IF ~sourceSeqNum.ok THEN Fail ELSE
    LET sourceTime == ReadBytes(sourceSeqNum.rest, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET systemId == ReadBytes(sourceTime.rest, 4) IN IF ~systemId.ok THEN Fail ELSE
    LET sourceTimeMicroSecs == ReadBytes(systemId.rest, 2) IN IF ~sourceTimeMicroSecs.ok THEN Fail ELSE
    LET instrumentGroupCode == ReadBytes(sourceTimeMicroSecs.rest, 3) IN IF ~instrumentGroupCode.ok THEN Fail ELSE
    LET instrumentGroupState == ReadBytes(instrumentGroupCode.rest, 1) IN IF ~instrumentGroupState.ok THEN Fail ELSE
    LET sessionType == ReadBytes(instrumentGroupState.rest, 1) IN IF ~sessionType.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(sessionType.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET classState == ReadBytes(reserved1.rest, 4) IN IF ~classState.ok THEN Fail ELSE
    Ok([ sourceSeqNum         |-> sourceSeqNum.value,
         sourceTime           |-> sourceTime.value,
         systemId             |-> systemId.value,
         sourceTimeMicroSecs  |-> sourceTimeMicroSecs.value,
         instrumentGroupCode  |-> instrumentGroupCode.value,
         instrumentGroupState |-> instrumentGroupState.value,
         sessionType          |-> sessionType.value,
         reserved1            |-> reserved1.value,
         classState           |-> classState.value ], classState.rest)

ZeroClassStateChangeMessage ==
    [ sourceSeqNum         |-> [i \in 1 .. 4 |-> 0],
      sourceTime           |-> [i \in 1 .. 4 |-> 0],
      systemId             |-> [i \in 1 .. 4 |-> 0],
      sourceTimeMicroSecs  |-> [i \in 1 .. 2 |-> 0],
      instrumentGroupCode  |-> [i \in 1 .. 3 |-> 0],
      instrumentGroupState |-> [i \in 1 .. 1 |-> 0],
      sessionType          |-> [i \in 1 .. 1 |-> 0],
      reserved1            |-> [i \in 1 .. 1 |-> 0],
      classState           |-> [i \in 1 .. 4 |-> 0] ]

(* Class State Change Message at zero, then each field in turn at the values it is checked at *)
CheckedClassStateChangeMessage ==
    { ZeroClassStateChangeMessage }
        \cup { [ZeroClassStateChangeMessage EXCEPT !.sourceSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroClassStateChangeMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroClassStateChangeMessage EXCEPT !.systemId = one] : one \in Sample(4) }
        \cup { [ZeroClassStateChangeMessage EXCEPT !.sourceTimeMicroSecs = one] : one \in Sample(2) }
        \cup { [ZeroClassStateChangeMessage EXCEPT !.instrumentGroupCode = one] : one \in Sample(3) }
        \cup { [ZeroClassStateChangeMessage EXCEPT !.instrumentGroupState = one] : one \in Sample(1) }
        \cup { [ZeroClassStateChangeMessage EXCEPT !.sessionType = one] : one \in Sample(1) }
        \cup { [ZeroClassStateChangeMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroClassStateChangeMessage EXCEPT !.classState = one] : one \in Sample(4) }

(***************************************************************************)
(* Mail Message: 1098 bytes                                                *)
(***************************************************************************)

MailMessage ==
    [ sourceSeqNum        : Sample(4),
      sourceTime          : Sample(4),
      systemId            : Sample(4),
      sourceTimeMicroSecs : Sample(2),
      scope               : Sample(1),
      title               : Sample(80),
      text                : Sample(1000),
      reserved3           : Sample(3) ]

EncodeMailMessage(message) ==
    message.sourceSeqNum
        \o message.sourceTime
        \o message.systemId
        \o message.sourceTimeMicroSecs
        \o message.scope
        \o message.title
        \o message.text
        \o message.reserved3

DecodeMailMessage(bytes) ==
    LET sourceSeqNum == ReadBytes(bytes, 4) IN IF ~sourceSeqNum.ok THEN Fail ELSE
    LET sourceTime == ReadBytes(sourceSeqNum.rest, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET systemId == ReadBytes(sourceTime.rest, 4) IN IF ~systemId.ok THEN Fail ELSE
    LET sourceTimeMicroSecs == ReadBytes(systemId.rest, 2) IN IF ~sourceTimeMicroSecs.ok THEN Fail ELSE
    LET scope == ReadBytes(sourceTimeMicroSecs.rest, 1) IN IF ~scope.ok THEN Fail ELSE
    LET title == ReadBytes(scope.rest, 80) IN IF ~title.ok THEN Fail ELSE
    LET text == ReadBytes(title.rest, 1000) IN IF ~text.ok THEN Fail ELSE
    LET reserved3 == ReadBytes(text.rest, 3) IN IF ~reserved3.ok THEN Fail ELSE
    Ok([ sourceSeqNum        |-> sourceSeqNum.value,
         sourceTime          |-> sourceTime.value,
         systemId            |-> systemId.value,
         sourceTimeMicroSecs |-> sourceTimeMicroSecs.value,
         scope               |-> scope.value,
         title               |-> title.value,
         text                |-> text.value,
         reserved3           |-> reserved3.value ], reserved3.rest)

ZeroMailMessage ==
    [ sourceSeqNum        |-> [i \in 1 .. 4 |-> 0],
      sourceTime          |-> [i \in 1 .. 4 |-> 0],
      systemId            |-> [i \in 1 .. 4 |-> 0],
      sourceTimeMicroSecs |-> [i \in 1 .. 2 |-> 0],
      scope               |-> [i \in 1 .. 1 |-> 0],
      title               |-> [i \in 1 .. 80 |-> 0],
      text                |-> [i \in 1 .. 1000 |-> 0],
      reserved3           |-> [i \in 1 .. 3 |-> 0] ]

(* Mail Message at zero, then each field in turn at the values it is checked at *)
CheckedMailMessage ==
    { ZeroMailMessage }
        \cup { [ZeroMailMessage EXCEPT !.sourceSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroMailMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroMailMessage EXCEPT !.systemId = one] : one \in Sample(4) }
        \cup { [ZeroMailMessage EXCEPT !.sourceTimeMicroSecs = one] : one \in Sample(2) }
        \cup { [ZeroMailMessage EXCEPT !.scope = one] : one \in Sample(1) }
        \cup { [ZeroMailMessage EXCEPT !.title = one] : one \in Sample(80) }
        \cup { [ZeroMailMessage EXCEPT !.text = one] : one \in Sample(1000) }
        \cup { [ZeroMailMessage EXCEPT !.reserved3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Collars Message: 32 bytes                                               *)
(***************************************************************************)

CollarsMessage ==
    [ symbolIndex         : Sample(4),
      sourceSeqNum        : Sample(4),
      sourceTime          : Sample(4),
      highCollar          : Sample(4),
      lowCollar           : Sample(4),
      systemId            : Sample(4),
      sourceTimeMicroSecs : Sample(2),
      highScaleCode       : Sample(1),
      lowScaleCode        : Sample(1),
      collarType          : Sample(1),
      reserved3           : Sample(3) ]

EncodeCollarsMessage(message) ==
    message.symbolIndex
        \o message.sourceSeqNum
        \o message.sourceTime
        \o message.highCollar
        \o message.lowCollar
        \o message.systemId
        \o message.sourceTimeMicroSecs
        \o message.highScaleCode
        \o message.lowScaleCode
        \o message.collarType
        \o message.reserved3

DecodeCollarsMessage(bytes) ==
    LET symbolIndex == ReadBytes(bytes, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET sourceSeqNum == ReadBytes(symbolIndex.rest, 4) IN IF ~sourceSeqNum.ok THEN Fail ELSE
    LET sourceTime == ReadBytes(sourceSeqNum.rest, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET highCollar == ReadBytes(sourceTime.rest, 4) IN IF ~highCollar.ok THEN Fail ELSE
    LET lowCollar == ReadBytes(highCollar.rest, 4) IN IF ~lowCollar.ok THEN Fail ELSE
    LET systemId == ReadBytes(lowCollar.rest, 4) IN IF ~systemId.ok THEN Fail ELSE
    LET sourceTimeMicroSecs == ReadBytes(systemId.rest, 2) IN IF ~sourceTimeMicroSecs.ok THEN Fail ELSE
    LET highScaleCode == ReadBytes(sourceTimeMicroSecs.rest, 1) IN IF ~highScaleCode.ok THEN Fail ELSE
    LET lowScaleCode == ReadBytes(highScaleCode.rest, 1) IN IF ~lowScaleCode.ok THEN Fail ELSE
    LET collarType == ReadBytes(lowScaleCode.rest, 1) IN IF ~collarType.ok THEN Fail ELSE
    LET reserved3 == ReadBytes(collarType.rest, 3) IN IF ~reserved3.ok THEN Fail ELSE
    Ok([ symbolIndex         |-> symbolIndex.value,
         sourceSeqNum        |-> sourceSeqNum.value,
         sourceTime          |-> sourceTime.value,
         highCollar          |-> highCollar.value,
         lowCollar           |-> lowCollar.value,
         systemId            |-> systemId.value,
         sourceTimeMicroSecs |-> sourceTimeMicroSecs.value,
         highScaleCode       |-> highScaleCode.value,
         lowScaleCode        |-> lowScaleCode.value,
         collarType          |-> collarType.value,
         reserved3           |-> reserved3.value ], reserved3.rest)

ZeroCollarsMessage ==
    [ symbolIndex         |-> [i \in 1 .. 4 |-> 0],
      sourceSeqNum        |-> [i \in 1 .. 4 |-> 0],
      sourceTime          |-> [i \in 1 .. 4 |-> 0],
      highCollar          |-> [i \in 1 .. 4 |-> 0],
      lowCollar           |-> [i \in 1 .. 4 |-> 0],
      systemId            |-> [i \in 1 .. 4 |-> 0],
      sourceTimeMicroSecs |-> [i \in 1 .. 2 |-> 0],
      highScaleCode       |-> [i \in 1 .. 1 |-> 0],
      lowScaleCode        |-> [i \in 1 .. 1 |-> 0],
      collarType          |-> [i \in 1 .. 1 |-> 0],
      reserved3           |-> [i \in 1 .. 3 |-> 0] ]

(* Collars Message at zero, then each field in turn at the values it is checked at *)
CheckedCollarsMessage ==
    { ZeroCollarsMessage }
        \cup { [ZeroCollarsMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroCollarsMessage EXCEPT !.sourceSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroCollarsMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroCollarsMessage EXCEPT !.highCollar = one] : one \in Sample(4) }
        \cup { [ZeroCollarsMessage EXCEPT !.lowCollar = one] : one \in Sample(4) }
        \cup { [ZeroCollarsMessage EXCEPT !.systemId = one] : one \in Sample(4) }
        \cup { [ZeroCollarsMessage EXCEPT !.sourceTimeMicroSecs = one] : one \in Sample(2) }
        \cup { [ZeroCollarsMessage EXCEPT !.highScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroCollarsMessage EXCEPT !.lowScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroCollarsMessage EXCEPT !.collarType = one] : one \in Sample(1) }
        \cup { [ZeroCollarsMessage EXCEPT !.reserved3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Class Phase: 8 bytes                                                    *)
(***************************************************************************)

ClassPhase ==
    [ classStateTime : Sample(4),
      classState     : Sample(4) ]

EncodeClassPhase(message) ==
    message.classStateTime
        \o message.classState

DecodeClassPhase(bytes) ==
    LET classStateTime == ReadBytes(bytes, 4) IN IF ~classStateTime.ok THEN Fail ELSE
    LET classState == ReadBytes(classStateTime.rest, 4) IN IF ~classState.ok THEN Fail ELSE
    Ok([ classStateTime |-> classStateTime.value,
         classState     |-> classState.value ], classState.rest)

ZeroClassPhase ==
    [ classStateTime |-> [i \in 1 .. 4 |-> 0],
      classState     |-> [i \in 1 .. 4 |-> 0] ]

(* Class Phase at zero, then each field in turn at the values it is checked at *)
CheckedClassPhase ==
    { ZeroClassPhase }
        \cup { [ZeroClassPhase EXCEPT !.classStateTime = one] : one \in Sample(4) }
        \cup { [ZeroClassPhase EXCEPT !.classState = one] : one \in Sample(4) }

(* A run of Class Phase, written one after another *)
RECURSIVE EncodeClassPhaseList(_)
EncodeClassPhaseList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeClassPhase(Head(messages)) \o EncodeClassPhaseList(Tail(messages))

(* As many Class Phase as the field that counts them says *)
RECURSIVE ReadClassPhaseList(_, _)
ReadClassPhaseList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeClassPhase(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadClassPhaseList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Class Phase of each kind, for the lists that carry them *)
OneClassPhase == { ZeroClassPhase }

(* The 15 slots a run of Class Phase is written as, whatever the field beside it says are in use *)
SlotsClassPhase == { [i \in 1 .. 15 |-> one] : one \in OneClassPhase }

(***************************************************************************)
(* Session Timetable Message                                               *)
(***************************************************************************)

SessionTimetableMessage ==
    [ sourceSeqNum        : Sample(4),
      sourceTime          : Sample(4),
      systemId            : Sample(4),
      sourceTimeMicroSecs : Sample(2),
      instrumentGroupCode : Sample(3),
      reserved1           : Sample(1),
      classPhaseNumber    : Sample(2),
      classPhase          : SlotsClassPhase ]

EncodeSessionTimetableMessage(message) ==
    message.sourceSeqNum
        \o message.sourceTime
        \o message.systemId
        \o message.sourceTimeMicroSecs
        \o message.instrumentGroupCode
        \o message.reserved1
        \o message.classPhaseNumber
        \o EncodeClassPhaseList(message.classPhase)

DecodeSessionTimetableMessage(bytes) ==
    LET sourceSeqNum == ReadBytes(bytes, 4) IN IF ~sourceSeqNum.ok THEN Fail ELSE
    LET sourceTime == ReadBytes(sourceSeqNum.rest, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET systemId == ReadBytes(sourceTime.rest, 4) IN IF ~systemId.ok THEN Fail ELSE
    LET sourceTimeMicroSecs == ReadBytes(systemId.rest, 2) IN IF ~sourceTimeMicroSecs.ok THEN Fail ELSE
    LET instrumentGroupCode == ReadBytes(sourceTimeMicroSecs.rest, 3) IN IF ~instrumentGroupCode.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(instrumentGroupCode.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET classPhaseNumber == ReadBytes(reserved1.rest, 2) IN IF ~classPhaseNumber.ok THEN Fail ELSE
    LET classPhase == ReadClassPhaseList(classPhaseNumber.rest, 15) IN IF ~classPhase.ok THEN Fail ELSE
    Ok([ sourceSeqNum        |-> sourceSeqNum.value,
         sourceTime          |-> sourceTime.value,
         systemId            |-> systemId.value,
         sourceTimeMicroSecs |-> sourceTimeMicroSecs.value,
         instrumentGroupCode |-> instrumentGroupCode.value,
         reserved1           |-> reserved1.value,
         classPhaseNumber    |-> classPhaseNumber.value,
         classPhase          |-> classPhase.value ], classPhase.rest)

ZeroSessionTimetableMessage ==
    [ sourceSeqNum        |-> [i \in 1 .. 4 |-> 0],
      sourceTime          |-> [i \in 1 .. 4 |-> 0],
      systemId            |-> [i \in 1 .. 4 |-> 0],
      sourceTimeMicroSecs |-> [i \in 1 .. 2 |-> 0],
      instrumentGroupCode |-> [i \in 1 .. 3 |-> 0],
      reserved1           |-> [i \in 1 .. 1 |-> 0],
      classPhaseNumber    |-> [i \in 1 .. 2 |-> 0],
      classPhase          |-> [i \in 1 .. 15 |-> ZeroClassPhase] ]

(* Session Timetable Message at zero, then each field in turn at the values it is checked at *)
CheckedSessionTimetableMessage ==
    { ZeroSessionTimetableMessage }
        \cup { [ZeroSessionTimetableMessage EXCEPT !.sourceSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroSessionTimetableMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroSessionTimetableMessage EXCEPT !.systemId = one] : one \in Sample(4) }
        \cup { [ZeroSessionTimetableMessage EXCEPT !.sourceTimeMicroSecs = one] : one \in Sample(2) }
        \cup { [ZeroSessionTimetableMessage EXCEPT !.instrumentGroupCode = one] : one \in Sample(3) }
        \cup { [ZeroSessionTimetableMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroSessionTimetableMessage EXCEPT !.classPhaseNumber = one] : one \in Sample(2) }
        \cup { [ZeroSessionTimetableMessage EXCEPT !.classPhase = one] : one \in SlotsClassPhase }

(***************************************************************************)
(* Start Referential Message: 4 bytes                                      *)
(***************************************************************************)

StartReferentialMessage ==
    [ indicator : Sample(1),
      reserved3 : Sample(3) ]

EncodeStartReferentialMessage(message) ==
    message.indicator
        \o message.reserved3

DecodeStartReferentialMessage(bytes) ==
    LET indicator == ReadBytes(bytes, 1) IN IF ~indicator.ok THEN Fail ELSE
    LET reserved3 == ReadBytes(indicator.rest, 3) IN IF ~reserved3.ok THEN Fail ELSE
    Ok([ indicator |-> indicator.value,
         reserved3 |-> reserved3.value ], reserved3.rest)

ZeroStartReferentialMessage ==
    [ indicator |-> [i \in 1 .. 1 |-> 0],
      reserved3 |-> [i \in 1 .. 3 |-> 0] ]

(* Start Referential Message at zero, then each field in turn at the values it is checked at *)
CheckedStartReferentialMessage ==
    { ZeroStartReferentialMessage }
        \cup { [ZeroStartReferentialMessage EXCEPT !.indicator = one] : one \in Sample(1) }
        \cup { [ZeroStartReferentialMessage EXCEPT !.reserved3 = one] : one \in Sample(3) }

(***************************************************************************)
(* End Referential Message: 4 bytes                                        *)
(***************************************************************************)

EndReferentialMessage ==
    [ indicator : Sample(1),
      reserved3 : Sample(3) ]

EncodeEndReferentialMessage(message) ==
    message.indicator
        \o message.reserved3

DecodeEndReferentialMessage(bytes) ==
    LET indicator == ReadBytes(bytes, 1) IN IF ~indicator.ok THEN Fail ELSE
    LET reserved3 == ReadBytes(indicator.rest, 3) IN IF ~reserved3.ok THEN Fail ELSE
    Ok([ indicator |-> indicator.value,
         reserved3 |-> reserved3.value ], reserved3.rest)

ZeroEndReferentialMessage ==
    [ indicator |-> [i \in 1 .. 1 |-> 0],
      reserved3 |-> [i \in 1 .. 3 |-> 0] ]

(* End Referential Message at zero, then each field in turn at the values it is checked at *)
CheckedEndReferentialMessage ==
    { ZeroEndReferentialMessage }
        \cup { [ZeroEndReferentialMessage EXCEPT !.indicator = one] : one \in Sample(1) }
        \cup { [ZeroEndReferentialMessage EXCEPT !.reserved3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Depositary List: 5 bytes                                                *)
(***************************************************************************)

DepositaryList ==
    [ depositary : Sample(5) ]

EncodeDepositaryList(message) ==
    message.depositary

DecodeDepositaryList(bytes) ==
    LET depositary == ReadBytes(bytes, 5) IN IF ~depositary.ok THEN Fail ELSE
    Ok([ depositary |-> depositary.value ], depositary.rest)

ZeroDepositaryList ==
    [ depositary |-> [i \in 1 .. 5 |-> 0] ]

(* Depositary List at zero, then each field in turn at the values it is checked at *)
CheckedDepositaryList ==
    { ZeroDepositaryList }
        \cup { [ZeroDepositaryList EXCEPT !.depositary = one] : one \in Sample(5) }

(* A run of Depositary List, written one after another *)
RECURSIVE EncodeDepositaryListList(_)
EncodeDepositaryListList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeDepositaryList(Head(messages)) \o EncodeDepositaryListList(Tail(messages))

(* As many Depositary List as the field that counts them says *)
RECURSIVE ReadDepositaryListList(_, _)
ReadDepositaryListList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeDepositaryList(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadDepositaryListList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Depositary List of each kind, for the lists that carry them *)
OneDepositaryList == { ZeroDepositaryList }

(* The 5 slots a run of Depositary List is written as, whatever the field beside it says are in use *)
SlotsDepositaryList == { [i \in 1 .. 5 |-> one] : one \in OneDepositaryList }

(***************************************************************************)
(* Referential Message                                                     *)
(***************************************************************************)

ReferentialMessage ==
    [ symbolIndex                   : Sample(4),
      sourceSeqNum                  : Sample(4),
      sourceTime                    : Sample(4),
      lastAdjPrice                  : Sample(4),
      systemId                      : Sample(4),
      prevVolumeTraded              : Sample(4),
      reserved4                     : Sample(4),
      sourceTimeMicroSecs           : Sample(2),
      stockExchangeCode             : Sample(2),
      typeOfInstrument              : Sample(2),
      eventDate                     : Sample(8),
      instrumentName                : Sample(18),
      periodIndicator               : Sample(1),
      typeOfMarketAdmission         : Sample(1),
      issuingCountryCode            : Sample(3),
      tradingCurrency               : Sample(3),
      instrumentGroupCode           : Sample(3),
      instrumentCategory            : Sample(1),
      instrumentCode                : Sample(12),
      dateOfLastTrade               : Sample(8),
      underlyingRepoIsinCode        : Sample(12),
      expiryDate                    : Sample(8),
      firstSettlementDate           : Sample(8),
      typeOfDerivatives             : Sample(1),
      bicDepositary                 : Sample(11),
      icb                           : Sample(4),
      mic                           : Sample(4),
      underlyingIsinCode            : Sample(12),
      depositaryList                : SlotsDepositaryList,
      mainDepositary                : Sample(5),
      typeOfCorporateEvent          : Sample(2),
      timeLagEuronextUtc            : Sample(5),
      timeLagMiFidRegUtc            : Sample(5),
      cfi                           : Sample(6),
      secondReserved4               : Sample(4),
      indexSetOfVarPriceTick        : Sample(2),
      marketFeedCode                : Sample(2),
      micList                       : Sample(24),
      industryCode                  : Sample(4),
      industryText                  : Sample(100),
      financialMarketCode           : Sample(3),
      usIndicators                  : Sample(7),
      reserved2                     : Sample(2),
      prevDayCapitalTraded          : Sample(8),
      lotSize                       : Sample(8),
      numberInstrumentCirc          : Sample(8),
      sharesOut                     : Sample(8),
      authShares                    : Sample(8),
      priceNotation                 : Sample(4),
      repoIndicator                 : Sample(1),
      notionalAmount                : Sample(20),
      notionalCurrency              : Sample(3),
      lastAdjPriceScaleCode         : Sample(1),
      marketIndicator               : Sample(1),
      prevDayCapitalTradedScaleCode : Sample(1),
      taxCode                       : Sample(1),
      reserved1                     : Sample(1),
      lotSizeScaleCode              : Sample(1),
      secondReserved1               : Sample(1),
      mnemo                         : Sample(5),
      tradingCode                   : Sample(12),
      thirdReserved4                : Sample(4),
      strikePrice                   : Sample(4),
      strikeCurrency                : Sample(3),
      strikeScaleCode               : Sample(1),
      currencyCoef                  : Sample(4),
      currencyCoefScaleCode         : Sample(1),
      tradingCurrencyIndicator      : Sample(1),
      strikeCurrencyIndicator       : Sample(1),
      marketSegment                 : Sample(2),
      algo                          : Sample(1),
      localName                     : Sample(30),
      blockSize                     : Sample(4),
      ssMarketMaker                 : Sample(1),
      ssNonMarketMaker              : Sample(1),
      settlementDelay               : Sample(2),
      optionType                    : Sample(1),
      deliveryType                  : Sample(1),
      exerciseType                  : Sample(1),
      multiplierScaleCode           : Sample(1),
      warrantThresholdMinScaleCode  : Sample(1),
      warrantThresholdMaxScaleCode  : Sample(1),
      secondReserved2               : Sample(2),
      warrantThresholdMin           : Sample(4),
      warrantThresholdMax           : Sample(4),
      minQuantity                   : Sample(4),
      maxQuantity                   : Sample(4),
      multiplier                    : Sample(4),
      fourthReserved4               : Sample(4),
      maxValue                      : Sample(8) ]

EncodeReferentialMessage(message) ==
    message.symbolIndex
        \o message.sourceSeqNum
        \o message.sourceTime
        \o message.lastAdjPrice
        \o message.systemId
        \o message.prevVolumeTraded
        \o message.reserved4
        \o message.sourceTimeMicroSecs
        \o message.stockExchangeCode
        \o message.typeOfInstrument
        \o message.eventDate
        \o message.instrumentName
        \o message.periodIndicator
        \o message.typeOfMarketAdmission
        \o message.issuingCountryCode
        \o message.tradingCurrency
        \o message.instrumentGroupCode
        \o message.instrumentCategory
        \o message.instrumentCode
        \o message.dateOfLastTrade
        \o message.underlyingRepoIsinCode
        \o message.expiryDate
        \o message.firstSettlementDate
        \o message.typeOfDerivatives
        \o message.bicDepositary
        \o message.icb
        \o message.mic
        \o message.underlyingIsinCode
        \o EncodeDepositaryListList(message.depositaryList)
        \o message.mainDepositary
        \o message.typeOfCorporateEvent
        \o message.timeLagEuronextUtc
        \o message.timeLagMiFidRegUtc
        \o message.cfi
        \o message.secondReserved4
        \o message.indexSetOfVarPriceTick
        \o message.marketFeedCode
        \o message.micList
        \o message.industryCode
        \o message.industryText
        \o message.financialMarketCode
        \o message.usIndicators
        \o message.reserved2
        \o message.prevDayCapitalTraded
        \o message.lotSize
        \o message.numberInstrumentCirc
        \o message.sharesOut
        \o message.authShares
        \o message.priceNotation
        \o message.repoIndicator
        \o message.notionalAmount
        \o message.notionalCurrency
        \o message.lastAdjPriceScaleCode
        \o message.marketIndicator
        \o message.prevDayCapitalTradedScaleCode
        \o message.taxCode
        \o message.reserved1
        \o message.lotSizeScaleCode
        \o message.secondReserved1
        \o message.mnemo
        \o message.tradingCode
        \o message.thirdReserved4
        \o message.strikePrice
        \o message.strikeCurrency
        \o message.strikeScaleCode
        \o message.currencyCoef
        \o message.currencyCoefScaleCode
        \o message.tradingCurrencyIndicator
        \o message.strikeCurrencyIndicator
        \o message.marketSegment
        \o message.algo
        \o message.localName
        \o message.blockSize
        \o message.ssMarketMaker
        \o message.ssNonMarketMaker
        \o message.settlementDelay
        \o message.optionType
        \o message.deliveryType
        \o message.exerciseType
        \o message.multiplierScaleCode
        \o message.warrantThresholdMinScaleCode
        \o message.warrantThresholdMaxScaleCode
        \o message.secondReserved2
        \o message.warrantThresholdMin
        \o message.warrantThresholdMax
        \o message.minQuantity
        \o message.maxQuantity
        \o message.multiplier
        \o message.fourthReserved4
        \o message.maxValue

DecodeReferentialMessage(bytes) ==
    LET symbolIndex == ReadBytes(bytes, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET sourceSeqNum == ReadBytes(symbolIndex.rest, 4) IN IF ~sourceSeqNum.ok THEN Fail ELSE
    LET sourceTime == ReadBytes(sourceSeqNum.rest, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET lastAdjPrice == ReadBytes(sourceTime.rest, 4) IN IF ~lastAdjPrice.ok THEN Fail ELSE
    LET systemId == ReadBytes(lastAdjPrice.rest, 4) IN IF ~systemId.ok THEN Fail ELSE
    LET prevVolumeTraded == ReadBytes(systemId.rest, 4) IN IF ~prevVolumeTraded.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(prevVolumeTraded.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET sourceTimeMicroSecs == ReadBytes(reserved4.rest, 2) IN IF ~sourceTimeMicroSecs.ok THEN Fail ELSE
    LET stockExchangeCode == ReadBytes(sourceTimeMicroSecs.rest, 2) IN IF ~stockExchangeCode.ok THEN Fail ELSE
    LET typeOfInstrument == ReadBytes(stockExchangeCode.rest, 2) IN IF ~typeOfInstrument.ok THEN Fail ELSE
    LET eventDate == ReadBytes(typeOfInstrument.rest, 8) IN IF ~eventDate.ok THEN Fail ELSE
    LET instrumentName == ReadBytes(eventDate.rest, 18) IN IF ~instrumentName.ok THEN Fail ELSE
    LET periodIndicator == ReadBytes(instrumentName.rest, 1) IN IF ~periodIndicator.ok THEN Fail ELSE
    LET typeOfMarketAdmission == ReadBytes(periodIndicator.rest, 1) IN IF ~typeOfMarketAdmission.ok THEN Fail ELSE
    LET issuingCountryCode == ReadBytes(typeOfMarketAdmission.rest, 3) IN IF ~issuingCountryCode.ok THEN Fail ELSE
    LET tradingCurrency == ReadBytes(issuingCountryCode.rest, 3) IN IF ~tradingCurrency.ok THEN Fail ELSE
    LET instrumentGroupCode == ReadBytes(tradingCurrency.rest, 3) IN IF ~instrumentGroupCode.ok THEN Fail ELSE
    LET instrumentCategory == ReadBytes(instrumentGroupCode.rest, 1) IN IF ~instrumentCategory.ok THEN Fail ELSE
    LET instrumentCode == ReadBytes(instrumentCategory.rest, 12) IN IF ~instrumentCode.ok THEN Fail ELSE
    LET dateOfLastTrade == ReadBytes(instrumentCode.rest, 8) IN IF ~dateOfLastTrade.ok THEN Fail ELSE
    LET underlyingRepoIsinCode == ReadBytes(dateOfLastTrade.rest, 12) IN IF ~underlyingRepoIsinCode.ok THEN Fail ELSE
    LET expiryDate == ReadBytes(underlyingRepoIsinCode.rest, 8) IN IF ~expiryDate.ok THEN Fail ELSE
    LET firstSettlementDate == ReadBytes(expiryDate.rest, 8) IN IF ~firstSettlementDate.ok THEN Fail ELSE
    LET typeOfDerivatives == ReadBytes(firstSettlementDate.rest, 1) IN IF ~typeOfDerivatives.ok THEN Fail ELSE
    LET bicDepositary == ReadBytes(typeOfDerivatives.rest, 11) IN IF ~bicDepositary.ok THEN Fail ELSE
    LET icb == ReadBytes(bicDepositary.rest, 4) IN IF ~icb.ok THEN Fail ELSE
    LET mic == ReadBytes(icb.rest, 4) IN IF ~mic.ok THEN Fail ELSE
    LET underlyingIsinCode == ReadBytes(mic.rest, 12) IN IF ~underlyingIsinCode.ok THEN Fail ELSE
    LET depositaryList == ReadDepositaryListList(underlyingIsinCode.rest, 5) IN IF ~depositaryList.ok THEN Fail ELSE
    LET mainDepositary == ReadBytes(depositaryList.rest, 5) IN IF ~mainDepositary.ok THEN Fail ELSE
    LET typeOfCorporateEvent == ReadBytes(mainDepositary.rest, 2) IN IF ~typeOfCorporateEvent.ok THEN Fail ELSE
    LET timeLagEuronextUtc == ReadBytes(typeOfCorporateEvent.rest, 5) IN IF ~timeLagEuronextUtc.ok THEN Fail ELSE
    LET timeLagMiFidRegUtc == ReadBytes(timeLagEuronextUtc.rest, 5) IN IF ~timeLagMiFidRegUtc.ok THEN Fail ELSE
    LET cfi == ReadBytes(timeLagMiFidRegUtc.rest, 6) IN IF ~cfi.ok THEN Fail ELSE
    LET secondReserved4 == ReadBytes(cfi.rest, 4) IN IF ~secondReserved4.ok THEN Fail ELSE
    LET indexSetOfVarPriceTick == ReadBytes(secondReserved4.rest, 2) IN IF ~indexSetOfVarPriceTick.ok THEN Fail ELSE
    LET marketFeedCode == ReadBytes(indexSetOfVarPriceTick.rest, 2) IN IF ~marketFeedCode.ok THEN Fail ELSE
    LET micList == ReadBytes(marketFeedCode.rest, 24) IN IF ~micList.ok THEN Fail ELSE
    LET industryCode == ReadBytes(micList.rest, 4) IN IF ~industryCode.ok THEN Fail ELSE
    LET industryText == ReadBytes(industryCode.rest, 100) IN IF ~industryText.ok THEN Fail ELSE
    LET financialMarketCode == ReadBytes(industryText.rest, 3) IN IF ~financialMarketCode.ok THEN Fail ELSE
    LET usIndicators == ReadBytes(financialMarketCode.rest, 7) IN IF ~usIndicators.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(usIndicators.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET prevDayCapitalTraded == ReadBytes(reserved2.rest, 8) IN IF ~prevDayCapitalTraded.ok THEN Fail ELSE
    LET lotSize == ReadBytes(prevDayCapitalTraded.rest, 8) IN IF ~lotSize.ok THEN Fail ELSE
    LET numberInstrumentCirc == ReadBytes(lotSize.rest, 8) IN IF ~numberInstrumentCirc.ok THEN Fail ELSE
    LET sharesOut == ReadBytes(numberInstrumentCirc.rest, 8) IN IF ~sharesOut.ok THEN Fail ELSE
    LET authShares == ReadBytes(sharesOut.rest, 8) IN IF ~authShares.ok THEN Fail ELSE
    LET priceNotation == ReadBytes(authShares.rest, 4) IN IF ~priceNotation.ok THEN Fail ELSE
    LET repoIndicator == ReadBytes(priceNotation.rest, 1) IN IF ~repoIndicator.ok THEN Fail ELSE
    LET notionalAmount == ReadBytes(repoIndicator.rest, 20) IN IF ~notionalAmount.ok THEN Fail ELSE
    LET notionalCurrency == ReadBytes(notionalAmount.rest, 3) IN IF ~notionalCurrency.ok THEN Fail ELSE
    LET lastAdjPriceScaleCode == ReadBytes(notionalCurrency.rest, 1) IN IF ~lastAdjPriceScaleCode.ok THEN Fail ELSE
    LET marketIndicator == ReadBytes(lastAdjPriceScaleCode.rest, 1) IN IF ~marketIndicator.ok THEN Fail ELSE
    LET prevDayCapitalTradedScaleCode == ReadBytes(marketIndicator.rest, 1) IN IF ~prevDayCapitalTradedScaleCode.ok THEN Fail ELSE
    LET taxCode == ReadBytes(prevDayCapitalTradedScaleCode.rest, 1) IN IF ~taxCode.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(taxCode.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET lotSizeScaleCode == ReadBytes(reserved1.rest, 1) IN IF ~lotSizeScaleCode.ok THEN Fail ELSE
    LET secondReserved1 == ReadBytes(lotSizeScaleCode.rest, 1) IN IF ~secondReserved1.ok THEN Fail ELSE
    LET mnemo == ReadBytes(secondReserved1.rest, 5) IN IF ~mnemo.ok THEN Fail ELSE
    LET tradingCode == ReadBytes(mnemo.rest, 12) IN IF ~tradingCode.ok THEN Fail ELSE
    LET thirdReserved4 == ReadBytes(tradingCode.rest, 4) IN IF ~thirdReserved4.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(thirdReserved4.rest, 4) IN IF ~strikePrice.ok THEN Fail ELSE
    LET strikeCurrency == ReadBytes(strikePrice.rest, 3) IN IF ~strikeCurrency.ok THEN Fail ELSE
    LET strikeScaleCode == ReadBytes(strikeCurrency.rest, 1) IN IF ~strikeScaleCode.ok THEN Fail ELSE
    LET currencyCoef == ReadBytes(strikeScaleCode.rest, 4) IN IF ~currencyCoef.ok THEN Fail ELSE
    LET currencyCoefScaleCode == ReadBytes(currencyCoef.rest, 1) IN IF ~currencyCoefScaleCode.ok THEN Fail ELSE
    LET tradingCurrencyIndicator == ReadBytes(currencyCoefScaleCode.rest, 1) IN IF ~tradingCurrencyIndicator.ok THEN Fail ELSE
    LET strikeCurrencyIndicator == ReadBytes(tradingCurrencyIndicator.rest, 1) IN IF ~strikeCurrencyIndicator.ok THEN Fail ELSE
    LET marketSegment == ReadBytes(strikeCurrencyIndicator.rest, 2) IN IF ~marketSegment.ok THEN Fail ELSE
    LET algo == ReadBytes(marketSegment.rest, 1) IN IF ~algo.ok THEN Fail ELSE
    LET localName == ReadBytes(algo.rest, 30) IN IF ~localName.ok THEN Fail ELSE
    LET blockSize == ReadBytes(localName.rest, 4) IN IF ~blockSize.ok THEN Fail ELSE
    LET ssMarketMaker == ReadBytes(blockSize.rest, 1) IN IF ~ssMarketMaker.ok THEN Fail ELSE
    LET ssNonMarketMaker == ReadBytes(ssMarketMaker.rest, 1) IN IF ~ssNonMarketMaker.ok THEN Fail ELSE
    LET settlementDelay == ReadBytes(ssNonMarketMaker.rest, 2) IN IF ~settlementDelay.ok THEN Fail ELSE
    LET optionType == ReadBytes(settlementDelay.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET deliveryType == ReadBytes(optionType.rest, 1) IN IF ~deliveryType.ok THEN Fail ELSE
    LET exerciseType == ReadBytes(deliveryType.rest, 1) IN IF ~exerciseType.ok THEN Fail ELSE
    LET multiplierScaleCode == ReadBytes(exerciseType.rest, 1) IN IF ~multiplierScaleCode.ok THEN Fail ELSE
    LET warrantThresholdMinScaleCode == ReadBytes(multiplierScaleCode.rest, 1) IN IF ~warrantThresholdMinScaleCode.ok THEN Fail ELSE
    LET warrantThresholdMaxScaleCode == ReadBytes(warrantThresholdMinScaleCode.rest, 1) IN IF ~warrantThresholdMaxScaleCode.ok THEN Fail ELSE
    LET secondReserved2 == ReadBytes(warrantThresholdMaxScaleCode.rest, 2) IN IF ~secondReserved2.ok THEN Fail ELSE
    LET warrantThresholdMin == ReadBytes(secondReserved2.rest, 4) IN IF ~warrantThresholdMin.ok THEN Fail ELSE
    LET warrantThresholdMax == ReadBytes(warrantThresholdMin.rest, 4) IN IF ~warrantThresholdMax.ok THEN Fail ELSE
    LET minQuantity == ReadBytes(warrantThresholdMax.rest, 4) IN IF ~minQuantity.ok THEN Fail ELSE
    LET maxQuantity == ReadBytes(minQuantity.rest, 4) IN IF ~maxQuantity.ok THEN Fail ELSE
    LET multiplier == ReadBytes(maxQuantity.rest, 4) IN IF ~multiplier.ok THEN Fail ELSE
    LET fourthReserved4 == ReadBytes(multiplier.rest, 4) IN IF ~fourthReserved4.ok THEN Fail ELSE
    LET maxValue == ReadBytes(fourthReserved4.rest, 8) IN IF ~maxValue.ok THEN Fail ELSE
    Ok([ symbolIndex                   |-> symbolIndex.value,
         sourceSeqNum                  |-> sourceSeqNum.value,
         sourceTime                    |-> sourceTime.value,
         lastAdjPrice                  |-> lastAdjPrice.value,
         systemId                      |-> systemId.value,
         prevVolumeTraded              |-> prevVolumeTraded.value,
         reserved4                     |-> reserved4.value,
         sourceTimeMicroSecs           |-> sourceTimeMicroSecs.value,
         stockExchangeCode             |-> stockExchangeCode.value,
         typeOfInstrument              |-> typeOfInstrument.value,
         eventDate                     |-> eventDate.value,
         instrumentName                |-> instrumentName.value,
         periodIndicator               |-> periodIndicator.value,
         typeOfMarketAdmission         |-> typeOfMarketAdmission.value,
         issuingCountryCode            |-> issuingCountryCode.value,
         tradingCurrency               |-> tradingCurrency.value,
         instrumentGroupCode           |-> instrumentGroupCode.value,
         instrumentCategory            |-> instrumentCategory.value,
         instrumentCode                |-> instrumentCode.value,
         dateOfLastTrade               |-> dateOfLastTrade.value,
         underlyingRepoIsinCode        |-> underlyingRepoIsinCode.value,
         expiryDate                    |-> expiryDate.value,
         firstSettlementDate           |-> firstSettlementDate.value,
         typeOfDerivatives             |-> typeOfDerivatives.value,
         bicDepositary                 |-> bicDepositary.value,
         icb                           |-> icb.value,
         mic                           |-> mic.value,
         underlyingIsinCode            |-> underlyingIsinCode.value,
         depositaryList                |-> depositaryList.value,
         mainDepositary                |-> mainDepositary.value,
         typeOfCorporateEvent          |-> typeOfCorporateEvent.value,
         timeLagEuronextUtc            |-> timeLagEuronextUtc.value,
         timeLagMiFidRegUtc            |-> timeLagMiFidRegUtc.value,
         cfi                           |-> cfi.value,
         secondReserved4               |-> secondReserved4.value,
         indexSetOfVarPriceTick        |-> indexSetOfVarPriceTick.value,
         marketFeedCode                |-> marketFeedCode.value,
         micList                       |-> micList.value,
         industryCode                  |-> industryCode.value,
         industryText                  |-> industryText.value,
         financialMarketCode           |-> financialMarketCode.value,
         usIndicators                  |-> usIndicators.value,
         reserved2                     |-> reserved2.value,
         prevDayCapitalTraded          |-> prevDayCapitalTraded.value,
         lotSize                       |-> lotSize.value,
         numberInstrumentCirc          |-> numberInstrumentCirc.value,
         sharesOut                     |-> sharesOut.value,
         authShares                    |-> authShares.value,
         priceNotation                 |-> priceNotation.value,
         repoIndicator                 |-> repoIndicator.value,
         notionalAmount                |-> notionalAmount.value,
         notionalCurrency              |-> notionalCurrency.value,
         lastAdjPriceScaleCode         |-> lastAdjPriceScaleCode.value,
         marketIndicator               |-> marketIndicator.value,
         prevDayCapitalTradedScaleCode |-> prevDayCapitalTradedScaleCode.value,
         taxCode                       |-> taxCode.value,
         reserved1                     |-> reserved1.value,
         lotSizeScaleCode              |-> lotSizeScaleCode.value,
         secondReserved1               |-> secondReserved1.value,
         mnemo                         |-> mnemo.value,
         tradingCode                   |-> tradingCode.value,
         thirdReserved4                |-> thirdReserved4.value,
         strikePrice                   |-> strikePrice.value,
         strikeCurrency                |-> strikeCurrency.value,
         strikeScaleCode               |-> strikeScaleCode.value,
         currencyCoef                  |-> currencyCoef.value,
         currencyCoefScaleCode         |-> currencyCoefScaleCode.value,
         tradingCurrencyIndicator      |-> tradingCurrencyIndicator.value,
         strikeCurrencyIndicator       |-> strikeCurrencyIndicator.value,
         marketSegment                 |-> marketSegment.value,
         algo                          |-> algo.value,
         localName                     |-> localName.value,
         blockSize                     |-> blockSize.value,
         ssMarketMaker                 |-> ssMarketMaker.value,
         ssNonMarketMaker              |-> ssNonMarketMaker.value,
         settlementDelay               |-> settlementDelay.value,
         optionType                    |-> optionType.value,
         deliveryType                  |-> deliveryType.value,
         exerciseType                  |-> exerciseType.value,
         multiplierScaleCode           |-> multiplierScaleCode.value,
         warrantThresholdMinScaleCode  |-> warrantThresholdMinScaleCode.value,
         warrantThresholdMaxScaleCode  |-> warrantThresholdMaxScaleCode.value,
         secondReserved2               |-> secondReserved2.value,
         warrantThresholdMin           |-> warrantThresholdMin.value,
         warrantThresholdMax           |-> warrantThresholdMax.value,
         minQuantity                   |-> minQuantity.value,
         maxQuantity                   |-> maxQuantity.value,
         multiplier                    |-> multiplier.value,
         fourthReserved4               |-> fourthReserved4.value,
         maxValue                      |-> maxValue.value ], maxValue.rest)

ZeroReferentialMessage ==
    [ symbolIndex                   |-> [i \in 1 .. 4 |-> 0],
      sourceSeqNum                  |-> [i \in 1 .. 4 |-> 0],
      sourceTime                    |-> [i \in 1 .. 4 |-> 0],
      lastAdjPrice                  |-> [i \in 1 .. 4 |-> 0],
      systemId                      |-> [i \in 1 .. 4 |-> 0],
      prevVolumeTraded              |-> [i \in 1 .. 4 |-> 0],
      reserved4                     |-> [i \in 1 .. 4 |-> 0],
      sourceTimeMicroSecs           |-> [i \in 1 .. 2 |-> 0],
      stockExchangeCode             |-> [i \in 1 .. 2 |-> 0],
      typeOfInstrument              |-> [i \in 1 .. 2 |-> 0],
      eventDate                     |-> [i \in 1 .. 8 |-> 0],
      instrumentName                |-> [i \in 1 .. 18 |-> 0],
      periodIndicator               |-> [i \in 1 .. 1 |-> 0],
      typeOfMarketAdmission         |-> [i \in 1 .. 1 |-> 0],
      issuingCountryCode            |-> [i \in 1 .. 3 |-> 0],
      tradingCurrency               |-> [i \in 1 .. 3 |-> 0],
      instrumentGroupCode           |-> [i \in 1 .. 3 |-> 0],
      instrumentCategory            |-> [i \in 1 .. 1 |-> 0],
      instrumentCode                |-> [i \in 1 .. 12 |-> 0],
      dateOfLastTrade               |-> [i \in 1 .. 8 |-> 0],
      underlyingRepoIsinCode        |-> [i \in 1 .. 12 |-> 0],
      expiryDate                    |-> [i \in 1 .. 8 |-> 0],
      firstSettlementDate           |-> [i \in 1 .. 8 |-> 0],
      typeOfDerivatives             |-> [i \in 1 .. 1 |-> 0],
      bicDepositary                 |-> [i \in 1 .. 11 |-> 0],
      icb                           |-> [i \in 1 .. 4 |-> 0],
      mic                           |-> [i \in 1 .. 4 |-> 0],
      underlyingIsinCode            |-> [i \in 1 .. 12 |-> 0],
      depositaryList                |-> [i \in 1 .. 5 |-> ZeroDepositaryList],
      mainDepositary                |-> [i \in 1 .. 5 |-> 0],
      typeOfCorporateEvent          |-> [i \in 1 .. 2 |-> 0],
      timeLagEuronextUtc            |-> [i \in 1 .. 5 |-> 0],
      timeLagMiFidRegUtc            |-> [i \in 1 .. 5 |-> 0],
      cfi                           |-> [i \in 1 .. 6 |-> 0],
      secondReserved4               |-> [i \in 1 .. 4 |-> 0],
      indexSetOfVarPriceTick        |-> [i \in 1 .. 2 |-> 0],
      marketFeedCode                |-> [i \in 1 .. 2 |-> 0],
      micList                       |-> [i \in 1 .. 24 |-> 0],
      industryCode                  |-> [i \in 1 .. 4 |-> 0],
      industryText                  |-> [i \in 1 .. 100 |-> 0],
      financialMarketCode           |-> [i \in 1 .. 3 |-> 0],
      usIndicators                  |-> [i \in 1 .. 7 |-> 0],
      reserved2                     |-> [i \in 1 .. 2 |-> 0],
      prevDayCapitalTraded          |-> [i \in 1 .. 8 |-> 0],
      lotSize                       |-> [i \in 1 .. 8 |-> 0],
      numberInstrumentCirc          |-> [i \in 1 .. 8 |-> 0],
      sharesOut                     |-> [i \in 1 .. 8 |-> 0],
      authShares                    |-> [i \in 1 .. 8 |-> 0],
      priceNotation                 |-> [i \in 1 .. 4 |-> 0],
      repoIndicator                 |-> [i \in 1 .. 1 |-> 0],
      notionalAmount                |-> [i \in 1 .. 20 |-> 0],
      notionalCurrency              |-> [i \in 1 .. 3 |-> 0],
      lastAdjPriceScaleCode         |-> [i \in 1 .. 1 |-> 0],
      marketIndicator               |-> [i \in 1 .. 1 |-> 0],
      prevDayCapitalTradedScaleCode |-> [i \in 1 .. 1 |-> 0],
      taxCode                       |-> [i \in 1 .. 1 |-> 0],
      reserved1                     |-> [i \in 1 .. 1 |-> 0],
      lotSizeScaleCode              |-> [i \in 1 .. 1 |-> 0],
      secondReserved1               |-> [i \in 1 .. 1 |-> 0],
      mnemo                         |-> [i \in 1 .. 5 |-> 0],
      tradingCode                   |-> [i \in 1 .. 12 |-> 0],
      thirdReserved4                |-> [i \in 1 .. 4 |-> 0],
      strikePrice                   |-> [i \in 1 .. 4 |-> 0],
      strikeCurrency                |-> [i \in 1 .. 3 |-> 0],
      strikeScaleCode               |-> [i \in 1 .. 1 |-> 0],
      currencyCoef                  |-> [i \in 1 .. 4 |-> 0],
      currencyCoefScaleCode         |-> [i \in 1 .. 1 |-> 0],
      tradingCurrencyIndicator      |-> [i \in 1 .. 1 |-> 0],
      strikeCurrencyIndicator       |-> [i \in 1 .. 1 |-> 0],
      marketSegment                 |-> [i \in 1 .. 2 |-> 0],
      algo                          |-> [i \in 1 .. 1 |-> 0],
      localName                     |-> [i \in 1 .. 30 |-> 0],
      blockSize                     |-> [i \in 1 .. 4 |-> 0],
      ssMarketMaker                 |-> [i \in 1 .. 1 |-> 0],
      ssNonMarketMaker              |-> [i \in 1 .. 1 |-> 0],
      settlementDelay               |-> [i \in 1 .. 2 |-> 0],
      optionType                    |-> [i \in 1 .. 1 |-> 0],
      deliveryType                  |-> [i \in 1 .. 1 |-> 0],
      exerciseType                  |-> [i \in 1 .. 1 |-> 0],
      multiplierScaleCode           |-> [i \in 1 .. 1 |-> 0],
      warrantThresholdMinScaleCode  |-> [i \in 1 .. 1 |-> 0],
      warrantThresholdMaxScaleCode  |-> [i \in 1 .. 1 |-> 0],
      secondReserved2               |-> [i \in 1 .. 2 |-> 0],
      warrantThresholdMin           |-> [i \in 1 .. 4 |-> 0],
      warrantThresholdMax           |-> [i \in 1 .. 4 |-> 0],
      minQuantity                   |-> [i \in 1 .. 4 |-> 0],
      maxQuantity                   |-> [i \in 1 .. 4 |-> 0],
      multiplier                    |-> [i \in 1 .. 4 |-> 0],
      fourthReserved4               |-> [i \in 1 .. 4 |-> 0],
      maxValue                      |-> [i \in 1 .. 8 |-> 0] ]

(* Referential Message at zero, then each field in turn at the values it is checked at *)
CheckedReferentialMessage ==
    { ZeroReferentialMessage }
        \cup { [ZeroReferentialMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroReferentialMessage EXCEPT !.sourceSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroReferentialMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroReferentialMessage EXCEPT !.lastAdjPrice = one] : one \in Sample(4) }
        \cup { [ZeroReferentialMessage EXCEPT !.systemId = one] : one \in Sample(4) }
        \cup { [ZeroReferentialMessage EXCEPT !.prevVolumeTraded = one] : one \in Sample(4) }
        \cup { [ZeroReferentialMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroReferentialMessage EXCEPT !.sourceTimeMicroSecs = one] : one \in Sample(2) }
        \cup { [ZeroReferentialMessage EXCEPT !.stockExchangeCode = one] : one \in Sample(2) }
        \cup { [ZeroReferentialMessage EXCEPT !.typeOfInstrument = one] : one \in Sample(2) }
        \cup { [ZeroReferentialMessage EXCEPT !.eventDate = one] : one \in Sample(8) }
        \cup { [ZeroReferentialMessage EXCEPT !.instrumentName = one] : one \in Sample(18) }
        \cup { [ZeroReferentialMessage EXCEPT !.periodIndicator = one] : one \in Sample(1) }
        \cup { [ZeroReferentialMessage EXCEPT !.typeOfMarketAdmission = one] : one \in Sample(1) }
        \cup { [ZeroReferentialMessage EXCEPT !.issuingCountryCode = one] : one \in Sample(3) }
        \cup { [ZeroReferentialMessage EXCEPT !.tradingCurrency = one] : one \in Sample(3) }
        \cup { [ZeroReferentialMessage EXCEPT !.instrumentGroupCode = one] : one \in Sample(3) }
        \cup { [ZeroReferentialMessage EXCEPT !.instrumentCategory = one] : one \in Sample(1) }
        \cup { [ZeroReferentialMessage EXCEPT !.instrumentCode = one] : one \in Sample(12) }
        \cup { [ZeroReferentialMessage EXCEPT !.dateOfLastTrade = one] : one \in Sample(8) }
        \cup { [ZeroReferentialMessage EXCEPT !.underlyingRepoIsinCode = one] : one \in Sample(12) }
        \cup { [ZeroReferentialMessage EXCEPT !.expiryDate = one] : one \in Sample(8) }
        \cup { [ZeroReferentialMessage EXCEPT !.firstSettlementDate = one] : one \in Sample(8) }
        \cup { [ZeroReferentialMessage EXCEPT !.typeOfDerivatives = one] : one \in Sample(1) }
        \cup { [ZeroReferentialMessage EXCEPT !.bicDepositary = one] : one \in Sample(11) }
        \cup { [ZeroReferentialMessage EXCEPT !.icb = one] : one \in Sample(4) }
        \cup { [ZeroReferentialMessage EXCEPT !.mic = one] : one \in Sample(4) }
        \cup { [ZeroReferentialMessage EXCEPT !.underlyingIsinCode = one] : one \in Sample(12) }
        \cup { [ZeroReferentialMessage EXCEPT !.depositaryList = one] : one \in SlotsDepositaryList }
        \cup { [ZeroReferentialMessage EXCEPT !.mainDepositary = one] : one \in Sample(5) }
        \cup { [ZeroReferentialMessage EXCEPT !.typeOfCorporateEvent = one] : one \in Sample(2) }
        \cup { [ZeroReferentialMessage EXCEPT !.timeLagEuronextUtc = one] : one \in Sample(5) }
        \cup { [ZeroReferentialMessage EXCEPT !.timeLagMiFidRegUtc = one] : one \in Sample(5) }
        \cup { [ZeroReferentialMessage EXCEPT !.cfi = one] : one \in Sample(6) }
        \cup { [ZeroReferentialMessage EXCEPT !.secondReserved4 = one] : one \in Sample(4) }
        \cup { [ZeroReferentialMessage EXCEPT !.indexSetOfVarPriceTick = one] : one \in Sample(2) }
        \cup { [ZeroReferentialMessage EXCEPT !.marketFeedCode = one] : one \in Sample(2) }
        \cup { [ZeroReferentialMessage EXCEPT !.micList = one] : one \in Sample(24) }
        \cup { [ZeroReferentialMessage EXCEPT !.industryCode = one] : one \in Sample(4) }
        \cup { [ZeroReferentialMessage EXCEPT !.industryText = one] : one \in Sample(100) }
        \cup { [ZeroReferentialMessage EXCEPT !.financialMarketCode = one] : one \in Sample(3) }
        \cup { [ZeroReferentialMessage EXCEPT !.usIndicators = one] : one \in Sample(7) }
        \cup { [ZeroReferentialMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroReferentialMessage EXCEPT !.prevDayCapitalTraded = one] : one \in Sample(8) }
        \cup { [ZeroReferentialMessage EXCEPT !.lotSize = one] : one \in Sample(8) }
        \cup { [ZeroReferentialMessage EXCEPT !.numberInstrumentCirc = one] : one \in Sample(8) }
        \cup { [ZeroReferentialMessage EXCEPT !.sharesOut = one] : one \in Sample(8) }
        \cup { [ZeroReferentialMessage EXCEPT !.authShares = one] : one \in Sample(8) }
        \cup { [ZeroReferentialMessage EXCEPT !.priceNotation = one] : one \in Sample(4) }
        \cup { [ZeroReferentialMessage EXCEPT !.repoIndicator = one] : one \in Sample(1) }
        \cup { [ZeroReferentialMessage EXCEPT !.notionalAmount = one] : one \in Sample(20) }
        \cup { [ZeroReferentialMessage EXCEPT !.notionalCurrency = one] : one \in Sample(3) }
        \cup { [ZeroReferentialMessage EXCEPT !.lastAdjPriceScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroReferentialMessage EXCEPT !.marketIndicator = one] : one \in Sample(1) }
        \cup { [ZeroReferentialMessage EXCEPT !.prevDayCapitalTradedScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroReferentialMessage EXCEPT !.taxCode = one] : one \in Sample(1) }
        \cup { [ZeroReferentialMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroReferentialMessage EXCEPT !.lotSizeScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroReferentialMessage EXCEPT !.secondReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroReferentialMessage EXCEPT !.mnemo = one] : one \in Sample(5) }
        \cup { [ZeroReferentialMessage EXCEPT !.tradingCode = one] : one \in Sample(12) }
        \cup { [ZeroReferentialMessage EXCEPT !.thirdReserved4 = one] : one \in Sample(4) }
        \cup { [ZeroReferentialMessage EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroReferentialMessage EXCEPT !.strikeCurrency = one] : one \in Sample(3) }
        \cup { [ZeroReferentialMessage EXCEPT !.strikeScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroReferentialMessage EXCEPT !.currencyCoef = one] : one \in Sample(4) }
        \cup { [ZeroReferentialMessage EXCEPT !.currencyCoefScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroReferentialMessage EXCEPT !.tradingCurrencyIndicator = one] : one \in Sample(1) }
        \cup { [ZeroReferentialMessage EXCEPT !.strikeCurrencyIndicator = one] : one \in Sample(1) }
        \cup { [ZeroReferentialMessage EXCEPT !.marketSegment = one] : one \in Sample(2) }
        \cup { [ZeroReferentialMessage EXCEPT !.algo = one] : one \in Sample(1) }
        \cup { [ZeroReferentialMessage EXCEPT !.localName = one] : one \in Sample(30) }
        \cup { [ZeroReferentialMessage EXCEPT !.blockSize = one] : one \in Sample(4) }
        \cup { [ZeroReferentialMessage EXCEPT !.ssMarketMaker = one] : one \in Sample(1) }
        \cup { [ZeroReferentialMessage EXCEPT !.ssNonMarketMaker = one] : one \in Sample(1) }
        \cup { [ZeroReferentialMessage EXCEPT !.settlementDelay = one] : one \in Sample(2) }
        \cup { [ZeroReferentialMessage EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroReferentialMessage EXCEPT !.deliveryType = one] : one \in Sample(1) }
        \cup { [ZeroReferentialMessage EXCEPT !.exerciseType = one] : one \in Sample(1) }
        \cup { [ZeroReferentialMessage EXCEPT !.multiplierScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroReferentialMessage EXCEPT !.warrantThresholdMinScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroReferentialMessage EXCEPT !.warrantThresholdMaxScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroReferentialMessage EXCEPT !.secondReserved2 = one] : one \in Sample(2) }
        \cup { [ZeroReferentialMessage EXCEPT !.warrantThresholdMin = one] : one \in Sample(4) }
        \cup { [ZeroReferentialMessage EXCEPT !.warrantThresholdMax = one] : one \in Sample(4) }
        \cup { [ZeroReferentialMessage EXCEPT !.minQuantity = one] : one \in Sample(4) }
        \cup { [ZeroReferentialMessage EXCEPT !.maxQuantity = one] : one \in Sample(4) }
        \cup { [ZeroReferentialMessage EXCEPT !.multiplier = one] : one \in Sample(4) }
        \cup { [ZeroReferentialMessage EXCEPT !.fourthReserved4 = one] : one \in Sample(4) }
        \cup { [ZeroReferentialMessage EXCEPT !.maxValue = one] : one \in Sample(8) }

(***************************************************************************)
(* Session Summary Message: 260 bytes                                      *)
(***************************************************************************)

SessionSummaryMessage ==
    [ symbolIndex                      : Sample(4),
      sourceTime                       : Sample(4),
      sourceSeqNum                     : Sample(4),
      date                             : Sample(4),
      multiplier                       : Sample(4),
      accumulatedInterest              : Sample(4),
      openingPrice                     : Sample(4),
      maximumPrice                     : Sample(4),
      minimumPrice                     : Sample(4),
      closingPrice                     : Sample(4),
      impliedVolatility                : Sample(4),
      averageWeightedPrice             : Sample(4),
      referencePrice                   : Sample(4),
      pctChangePrice                   : Sample(4),
      dividendRate                     : Sample(4),
      settlementPrice                  : Sample(4),
      settlementValue                  : Sample(4),
      reserved4                        : Sample(4),
      openPositions                    : Sample(4),
      tradingVolume                    : Sample(4),
      transactionsNumber               : Sample(4),
      tradingValue                     : Sample(8),
      currencyPrice                    : Sample(4),
      delta                            : Sample(4),
      gamma                            : Sample(4),
      rho                              : Sample(4),
      theta                            : Sample(4),
      vega                             : Sample(4),
      endTrading                       : Sample(4),
      numberOfInstruments              : Sample(4),
      tradingValueCurrency             : Sample(8),
      interestRate                     : Sample(4),
      volatility                       : Sample(4),
      strikePrice                      : Sample(4),
      shortSellingTradesNumber         : Sample(4),
      volumeShortSellingTrades         : Sample(4),
      valueShortSellingTrades          : Sample(4),
      lastTradeDate                    : Sample(4),
      lastTradePrice                   : Sample(4),
      blockTradesNumber                : Sample(4),
      volumeBlockTrades                : Sample(4),
      valueBlockTrades                 : Sample(4),
      vwapBlocktrade                   : Sample(4),
      maximumBlockPrice                : Sample(4),
      minimumBlockPrice                : Sample(4),
      systemId                         : Sample(4),
      sourceTimeMicroSecs              : Sample(2),
      multiplierScaleCode              : Sample(1),
      accumulatedInterestScaleCode     : Sample(1),
      openingPriceScaleCode            : Sample(1),
      maximumPriceScaleCode            : Sample(1),
      minimumPriceScaleCode            : Sample(1),
      closingPriceScaleCode            : Sample(1),
      impliedVolatilityScaleCode       : Sample(1),
      averageWeightedPriceScaleCode    : Sample(1),
      referencePriceScaleCode          : Sample(1),
      pctChangePriceScaleCode          : Sample(1),
      dividendRateScaleCode            : Sample(1),
      settlementPriceScaleCode         : Sample(1),
      settlementValueScaleCode         : Sample(1),
      reserved1                        : Sample(1),
      tradingValueScaleCode            : Sample(1),
      currencyPriceScaleCode           : Sample(1),
      deltaScaleCode                   : Sample(1),
      gammaScaleCode                   : Sample(1),
      rhoScaleCode                     : Sample(1),
      thetaScaleCode                   : Sample(1),
      vegaScaleCode                    : Sample(1),
      tradingValueCurrencyScaleCode    : Sample(1),
      interestRateScaleCode            : Sample(1),
      volatilityScaleCode              : Sample(1),
      strikePriceScaleCode             : Sample(1),
      valueShortSellingTradesScaleCode : Sample(1),
      lastTradePriceScaleCode          : Sample(1),
      valueBlockTradesScaleCode        : Sample(1),
      vwapBlocktradeScaleCode          : Sample(1),
      maximumBlockPriceScaleCode       : Sample(1),
      minimumBlockPriceScaleCode       : Sample(1),
      statusIndicator                  : Sample(1),
      sector                           : Sample(3),
      market                           : Sample(1),
      secondReserved1                  : Sample(1),
      shortSale                        : Sample(1),
      markerPctChangePrice             : Sample(1),
      symbolDelta                      : Sample(1),
      symbolGamma                      : Sample(1),
      symbolRho                        : Sample(1),
      symbolTheta                      : Sample(1),
      symbolVega                       : Sample(1),
      thirdReserved1                   : Sample(1),
      fourthReserved1                  : Sample(1),
      fifthReserved1                   : Sample(1),
      sixthReserved1                   : Sample(1),
      seventhReserved1                 : Sample(1),
      eighthReserved1                  : Sample(1),
      segment                          : Sample(2),
      lowerLiquidity                   : Sample(1),
      dividend                         : Sample(2),
      subscriptionRight                : Sample(2),
      split                            : Sample(2),
      interimDividendRight             : Sample(2),
      quotationSystem                  : Sample(2),
      liquiditySupportPge              : Sample(2),
      ninthReserved1                   : Sample(1) ]

EncodeSessionSummaryMessage(message) ==
    message.symbolIndex
        \o message.sourceTime
        \o message.sourceSeqNum
        \o message.date
        \o message.multiplier
        \o message.accumulatedInterest
        \o message.openingPrice
        \o message.maximumPrice
        \o message.minimumPrice
        \o message.closingPrice
        \o message.impliedVolatility
        \o message.averageWeightedPrice
        \o message.referencePrice
        \o message.pctChangePrice
        \o message.dividendRate
        \o message.settlementPrice
        \o message.settlementValue
        \o message.reserved4
        \o message.openPositions
        \o message.tradingVolume
        \o message.transactionsNumber
        \o message.tradingValue
        \o message.currencyPrice
        \o message.delta
        \o message.gamma
        \o message.rho
        \o message.theta
        \o message.vega
        \o message.endTrading
        \o message.numberOfInstruments
        \o message.tradingValueCurrency
        \o message.interestRate
        \o message.volatility
        \o message.strikePrice
        \o message.shortSellingTradesNumber
        \o message.volumeShortSellingTrades
        \o message.valueShortSellingTrades
        \o message.lastTradeDate
        \o message.lastTradePrice
        \o message.blockTradesNumber
        \o message.volumeBlockTrades
        \o message.valueBlockTrades
        \o message.vwapBlocktrade
        \o message.maximumBlockPrice
        \o message.minimumBlockPrice
        \o message.systemId
        \o message.sourceTimeMicroSecs
        \o message.multiplierScaleCode
        \o message.accumulatedInterestScaleCode
        \o message.openingPriceScaleCode
        \o message.maximumPriceScaleCode
        \o message.minimumPriceScaleCode
        \o message.closingPriceScaleCode
        \o message.impliedVolatilityScaleCode
        \o message.averageWeightedPriceScaleCode
        \o message.referencePriceScaleCode
        \o message.pctChangePriceScaleCode
        \o message.dividendRateScaleCode
        \o message.settlementPriceScaleCode
        \o message.settlementValueScaleCode
        \o message.reserved1
        \o message.tradingValueScaleCode
        \o message.currencyPriceScaleCode
        \o message.deltaScaleCode
        \o message.gammaScaleCode
        \o message.rhoScaleCode
        \o message.thetaScaleCode
        \o message.vegaScaleCode
        \o message.tradingValueCurrencyScaleCode
        \o message.interestRateScaleCode
        \o message.volatilityScaleCode
        \o message.strikePriceScaleCode
        \o message.valueShortSellingTradesScaleCode
        \o message.lastTradePriceScaleCode
        \o message.valueBlockTradesScaleCode
        \o message.vwapBlocktradeScaleCode
        \o message.maximumBlockPriceScaleCode
        \o message.minimumBlockPriceScaleCode
        \o message.statusIndicator
        \o message.sector
        \o message.market
        \o message.secondReserved1
        \o message.shortSale
        \o message.markerPctChangePrice
        \o message.symbolDelta
        \o message.symbolGamma
        \o message.symbolRho
        \o message.symbolTheta
        \o message.symbolVega
        \o message.thirdReserved1
        \o message.fourthReserved1
        \o message.fifthReserved1
        \o message.sixthReserved1
        \o message.seventhReserved1
        \o message.eighthReserved1
        \o message.segment
        \o message.lowerLiquidity
        \o message.dividend
        \o message.subscriptionRight
        \o message.split
        \o message.interimDividendRight
        \o message.quotationSystem
        \o message.liquiditySupportPge
        \o message.ninthReserved1

DecodeSessionSummaryMessage(bytes) ==
    LET symbolIndex == ReadBytes(bytes, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET sourceTime == ReadBytes(symbolIndex.rest, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceSeqNum == ReadBytes(sourceTime.rest, 4) IN IF ~sourceSeqNum.ok THEN Fail ELSE
    LET date == ReadBytes(sourceSeqNum.rest, 4) IN IF ~date.ok THEN Fail ELSE
    LET multiplier == ReadBytes(date.rest, 4) IN IF ~multiplier.ok THEN Fail ELSE
    LET accumulatedInterest == ReadBytes(multiplier.rest, 4) IN IF ~accumulatedInterest.ok THEN Fail ELSE
    LET openingPrice == ReadBytes(accumulatedInterest.rest, 4) IN IF ~openingPrice.ok THEN Fail ELSE
    LET maximumPrice == ReadBytes(openingPrice.rest, 4) IN IF ~maximumPrice.ok THEN Fail ELSE
    LET minimumPrice == ReadBytes(maximumPrice.rest, 4) IN IF ~minimumPrice.ok THEN Fail ELSE
    LET closingPrice == ReadBytes(minimumPrice.rest, 4) IN IF ~closingPrice.ok THEN Fail ELSE
    LET impliedVolatility == ReadBytes(closingPrice.rest, 4) IN IF ~impliedVolatility.ok THEN Fail ELSE
    LET averageWeightedPrice == ReadBytes(impliedVolatility.rest, 4) IN IF ~averageWeightedPrice.ok THEN Fail ELSE
    LET referencePrice == ReadBytes(averageWeightedPrice.rest, 4) IN IF ~referencePrice.ok THEN Fail ELSE
    LET pctChangePrice == ReadBytes(referencePrice.rest, 4) IN IF ~pctChangePrice.ok THEN Fail ELSE
    LET dividendRate == ReadBytes(pctChangePrice.rest, 4) IN IF ~dividendRate.ok THEN Fail ELSE
    LET settlementPrice == ReadBytes(dividendRate.rest, 4) IN IF ~settlementPrice.ok THEN Fail ELSE
    LET settlementValue == ReadBytes(settlementPrice.rest, 4) IN IF ~settlementValue.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(settlementValue.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET openPositions == ReadBytes(reserved4.rest, 4) IN IF ~openPositions.ok THEN Fail ELSE
    LET tradingVolume == ReadBytes(openPositions.rest, 4) IN IF ~tradingVolume.ok THEN Fail ELSE
    LET transactionsNumber == ReadBytes(tradingVolume.rest, 4) IN IF ~transactionsNumber.ok THEN Fail ELSE
    LET tradingValue == ReadBytes(transactionsNumber.rest, 8) IN IF ~tradingValue.ok THEN Fail ELSE
    LET currencyPrice == ReadBytes(tradingValue.rest, 4) IN IF ~currencyPrice.ok THEN Fail ELSE
    LET delta == ReadBytes(currencyPrice.rest, 4) IN IF ~delta.ok THEN Fail ELSE
    LET gamma == ReadBytes(delta.rest, 4) IN IF ~gamma.ok THEN Fail ELSE
    LET rho == ReadBytes(gamma.rest, 4) IN IF ~rho.ok THEN Fail ELSE
    LET theta == ReadBytes(rho.rest, 4) IN IF ~theta.ok THEN Fail ELSE
    LET vega == ReadBytes(theta.rest, 4) IN IF ~vega.ok THEN Fail ELSE
    LET endTrading == ReadBytes(vega.rest, 4) IN IF ~endTrading.ok THEN Fail ELSE
    LET numberOfInstruments == ReadBytes(endTrading.rest, 4) IN IF ~numberOfInstruments.ok THEN Fail ELSE
    LET tradingValueCurrency == ReadBytes(numberOfInstruments.rest, 8) IN IF ~tradingValueCurrency.ok THEN Fail ELSE
    LET interestRate == ReadBytes(tradingValueCurrency.rest, 4) IN IF ~interestRate.ok THEN Fail ELSE
    LET volatility == ReadBytes(interestRate.rest, 4) IN IF ~volatility.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(volatility.rest, 4) IN IF ~strikePrice.ok THEN Fail ELSE
    LET shortSellingTradesNumber == ReadBytes(strikePrice.rest, 4) IN IF ~shortSellingTradesNumber.ok THEN Fail ELSE
    LET volumeShortSellingTrades == ReadBytes(shortSellingTradesNumber.rest, 4) IN IF ~volumeShortSellingTrades.ok THEN Fail ELSE
    LET valueShortSellingTrades == ReadBytes(volumeShortSellingTrades.rest, 4) IN IF ~valueShortSellingTrades.ok THEN Fail ELSE
    LET lastTradeDate == ReadBytes(valueShortSellingTrades.rest, 4) IN IF ~lastTradeDate.ok THEN Fail ELSE
    LET lastTradePrice == ReadBytes(lastTradeDate.rest, 4) IN IF ~lastTradePrice.ok THEN Fail ELSE
    LET blockTradesNumber == ReadBytes(lastTradePrice.rest, 4) IN IF ~blockTradesNumber.ok THEN Fail ELSE
    LET volumeBlockTrades == ReadBytes(blockTradesNumber.rest, 4) IN IF ~volumeBlockTrades.ok THEN Fail ELSE
    LET valueBlockTrades == ReadBytes(volumeBlockTrades.rest, 4) IN IF ~valueBlockTrades.ok THEN Fail ELSE
    LET vwapBlocktrade == ReadBytes(valueBlockTrades.rest, 4) IN IF ~vwapBlocktrade.ok THEN Fail ELSE
    LET maximumBlockPrice == ReadBytes(vwapBlocktrade.rest, 4) IN IF ~maximumBlockPrice.ok THEN Fail ELSE
    LET minimumBlockPrice == ReadBytes(maximumBlockPrice.rest, 4) IN IF ~minimumBlockPrice.ok THEN Fail ELSE
    LET systemId == ReadBytes(minimumBlockPrice.rest, 4) IN IF ~systemId.ok THEN Fail ELSE
    LET sourceTimeMicroSecs == ReadBytes(systemId.rest, 2) IN IF ~sourceTimeMicroSecs.ok THEN Fail ELSE
    LET multiplierScaleCode == ReadBytes(sourceTimeMicroSecs.rest, 1) IN IF ~multiplierScaleCode.ok THEN Fail ELSE
    LET accumulatedInterestScaleCode == ReadBytes(multiplierScaleCode.rest, 1) IN IF ~accumulatedInterestScaleCode.ok THEN Fail ELSE
    LET openingPriceScaleCode == ReadBytes(accumulatedInterestScaleCode.rest, 1) IN IF ~openingPriceScaleCode.ok THEN Fail ELSE
    LET maximumPriceScaleCode == ReadBytes(openingPriceScaleCode.rest, 1) IN IF ~maximumPriceScaleCode.ok THEN Fail ELSE
    LET minimumPriceScaleCode == ReadBytes(maximumPriceScaleCode.rest, 1) IN IF ~minimumPriceScaleCode.ok THEN Fail ELSE
    LET closingPriceScaleCode == ReadBytes(minimumPriceScaleCode.rest, 1) IN IF ~closingPriceScaleCode.ok THEN Fail ELSE
    LET impliedVolatilityScaleCode == ReadBytes(closingPriceScaleCode.rest, 1) IN IF ~impliedVolatilityScaleCode.ok THEN Fail ELSE
    LET averageWeightedPriceScaleCode == ReadBytes(impliedVolatilityScaleCode.rest, 1) IN IF ~averageWeightedPriceScaleCode.ok THEN Fail ELSE
    LET referencePriceScaleCode == ReadBytes(averageWeightedPriceScaleCode.rest, 1) IN IF ~referencePriceScaleCode.ok THEN Fail ELSE
    LET pctChangePriceScaleCode == ReadBytes(referencePriceScaleCode.rest, 1) IN IF ~pctChangePriceScaleCode.ok THEN Fail ELSE
    LET dividendRateScaleCode == ReadBytes(pctChangePriceScaleCode.rest, 1) IN IF ~dividendRateScaleCode.ok THEN Fail ELSE
    LET settlementPriceScaleCode == ReadBytes(dividendRateScaleCode.rest, 1) IN IF ~settlementPriceScaleCode.ok THEN Fail ELSE
    LET settlementValueScaleCode == ReadBytes(settlementPriceScaleCode.rest, 1) IN IF ~settlementValueScaleCode.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(settlementValueScaleCode.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET tradingValueScaleCode == ReadBytes(reserved1.rest, 1) IN IF ~tradingValueScaleCode.ok THEN Fail ELSE
    LET currencyPriceScaleCode == ReadBytes(tradingValueScaleCode.rest, 1) IN IF ~currencyPriceScaleCode.ok THEN Fail ELSE
    LET deltaScaleCode == ReadBytes(currencyPriceScaleCode.rest, 1) IN IF ~deltaScaleCode.ok THEN Fail ELSE
    LET gammaScaleCode == ReadBytes(deltaScaleCode.rest, 1) IN IF ~gammaScaleCode.ok THEN Fail ELSE
    LET rhoScaleCode == ReadBytes(gammaScaleCode.rest, 1) IN IF ~rhoScaleCode.ok THEN Fail ELSE
    LET thetaScaleCode == ReadBytes(rhoScaleCode.rest, 1) IN IF ~thetaScaleCode.ok THEN Fail ELSE
    LET vegaScaleCode == ReadBytes(thetaScaleCode.rest, 1) IN IF ~vegaScaleCode.ok THEN Fail ELSE
    LET tradingValueCurrencyScaleCode == ReadBytes(vegaScaleCode.rest, 1) IN IF ~tradingValueCurrencyScaleCode.ok THEN Fail ELSE
    LET interestRateScaleCode == ReadBytes(tradingValueCurrencyScaleCode.rest, 1) IN IF ~interestRateScaleCode.ok THEN Fail ELSE
    LET volatilityScaleCode == ReadBytes(interestRateScaleCode.rest, 1) IN IF ~volatilityScaleCode.ok THEN Fail ELSE
    LET strikePriceScaleCode == ReadBytes(volatilityScaleCode.rest, 1) IN IF ~strikePriceScaleCode.ok THEN Fail ELSE
    LET valueShortSellingTradesScaleCode == ReadBytes(strikePriceScaleCode.rest, 1) IN IF ~valueShortSellingTradesScaleCode.ok THEN Fail ELSE
    LET lastTradePriceScaleCode == ReadBytes(valueShortSellingTradesScaleCode.rest, 1) IN IF ~lastTradePriceScaleCode.ok THEN Fail ELSE
    LET valueBlockTradesScaleCode == ReadBytes(lastTradePriceScaleCode.rest, 1) IN IF ~valueBlockTradesScaleCode.ok THEN Fail ELSE
    LET vwapBlocktradeScaleCode == ReadBytes(valueBlockTradesScaleCode.rest, 1) IN IF ~vwapBlocktradeScaleCode.ok THEN Fail ELSE
    LET maximumBlockPriceScaleCode == ReadBytes(vwapBlocktradeScaleCode.rest, 1) IN IF ~maximumBlockPriceScaleCode.ok THEN Fail ELSE
    LET minimumBlockPriceScaleCode == ReadBytes(maximumBlockPriceScaleCode.rest, 1) IN IF ~minimumBlockPriceScaleCode.ok THEN Fail ELSE
    LET statusIndicator == ReadBytes(minimumBlockPriceScaleCode.rest, 1) IN IF ~statusIndicator.ok THEN Fail ELSE
    LET sector == ReadBytes(statusIndicator.rest, 3) IN IF ~sector.ok THEN Fail ELSE
    LET market == ReadBytes(sector.rest, 1) IN IF ~market.ok THEN Fail ELSE
    LET secondReserved1 == ReadBytes(market.rest, 1) IN IF ~secondReserved1.ok THEN Fail ELSE
    LET shortSale == ReadBytes(secondReserved1.rest, 1) IN IF ~shortSale.ok THEN Fail ELSE
    LET markerPctChangePrice == ReadBytes(shortSale.rest, 1) IN IF ~markerPctChangePrice.ok THEN Fail ELSE
    LET symbolDelta == ReadBytes(markerPctChangePrice.rest, 1) IN IF ~symbolDelta.ok THEN Fail ELSE
    LET symbolGamma == ReadBytes(symbolDelta.rest, 1) IN IF ~symbolGamma.ok THEN Fail ELSE
    LET symbolRho == ReadBytes(symbolGamma.rest, 1) IN IF ~symbolRho.ok THEN Fail ELSE
    LET symbolTheta == ReadBytes(symbolRho.rest, 1) IN IF ~symbolTheta.ok THEN Fail ELSE
    LET symbolVega == ReadBytes(symbolTheta.rest, 1) IN IF ~symbolVega.ok THEN Fail ELSE
    LET thirdReserved1 == ReadBytes(symbolVega.rest, 1) IN IF ~thirdReserved1.ok THEN Fail ELSE
    LET fourthReserved1 == ReadBytes(thirdReserved1.rest, 1) IN IF ~fourthReserved1.ok THEN Fail ELSE
    LET fifthReserved1 == ReadBytes(fourthReserved1.rest, 1) IN IF ~fifthReserved1.ok THEN Fail ELSE
    LET sixthReserved1 == ReadBytes(fifthReserved1.rest, 1) IN IF ~sixthReserved1.ok THEN Fail ELSE
    LET seventhReserved1 == ReadBytes(sixthReserved1.rest, 1) IN IF ~seventhReserved1.ok THEN Fail ELSE
    LET eighthReserved1 == ReadBytes(seventhReserved1.rest, 1) IN IF ~eighthReserved1.ok THEN Fail ELSE
    LET segment == ReadBytes(eighthReserved1.rest, 2) IN IF ~segment.ok THEN Fail ELSE
    LET lowerLiquidity == ReadBytes(segment.rest, 1) IN IF ~lowerLiquidity.ok THEN Fail ELSE
    LET dividend == ReadBytes(lowerLiquidity.rest, 2) IN IF ~dividend.ok THEN Fail ELSE
    LET subscriptionRight == ReadBytes(dividend.rest, 2) IN IF ~subscriptionRight.ok THEN Fail ELSE
    LET split == ReadBytes(subscriptionRight.rest, 2) IN IF ~split.ok THEN Fail ELSE
    LET interimDividendRight == ReadBytes(split.rest, 2) IN IF ~interimDividendRight.ok THEN Fail ELSE
    LET quotationSystem == ReadBytes(interimDividendRight.rest, 2) IN IF ~quotationSystem.ok THEN Fail ELSE
    LET liquiditySupportPge == ReadBytes(quotationSystem.rest, 2) IN IF ~liquiditySupportPge.ok THEN Fail ELSE
    LET ninthReserved1 == ReadBytes(liquiditySupportPge.rest, 1) IN IF ~ninthReserved1.ok THEN Fail ELSE
    Ok([ symbolIndex                      |-> symbolIndex.value,
         sourceTime                       |-> sourceTime.value,
         sourceSeqNum                     |-> sourceSeqNum.value,
         date                             |-> date.value,
         multiplier                       |-> multiplier.value,
         accumulatedInterest              |-> accumulatedInterest.value,
         openingPrice                     |-> openingPrice.value,
         maximumPrice                     |-> maximumPrice.value,
         minimumPrice                     |-> minimumPrice.value,
         closingPrice                     |-> closingPrice.value,
         impliedVolatility                |-> impliedVolatility.value,
         averageWeightedPrice             |-> averageWeightedPrice.value,
         referencePrice                   |-> referencePrice.value,
         pctChangePrice                   |-> pctChangePrice.value,
         dividendRate                     |-> dividendRate.value,
         settlementPrice                  |-> settlementPrice.value,
         settlementValue                  |-> settlementValue.value,
         reserved4                        |-> reserved4.value,
         openPositions                    |-> openPositions.value,
         tradingVolume                    |-> tradingVolume.value,
         transactionsNumber               |-> transactionsNumber.value,
         tradingValue                     |-> tradingValue.value,
         currencyPrice                    |-> currencyPrice.value,
         delta                            |-> delta.value,
         gamma                            |-> gamma.value,
         rho                              |-> rho.value,
         theta                            |-> theta.value,
         vega                             |-> vega.value,
         endTrading                       |-> endTrading.value,
         numberOfInstruments              |-> numberOfInstruments.value,
         tradingValueCurrency             |-> tradingValueCurrency.value,
         interestRate                     |-> interestRate.value,
         volatility                       |-> volatility.value,
         strikePrice                      |-> strikePrice.value,
         shortSellingTradesNumber         |-> shortSellingTradesNumber.value,
         volumeShortSellingTrades         |-> volumeShortSellingTrades.value,
         valueShortSellingTrades          |-> valueShortSellingTrades.value,
         lastTradeDate                    |-> lastTradeDate.value,
         lastTradePrice                   |-> lastTradePrice.value,
         blockTradesNumber                |-> blockTradesNumber.value,
         volumeBlockTrades                |-> volumeBlockTrades.value,
         valueBlockTrades                 |-> valueBlockTrades.value,
         vwapBlocktrade                   |-> vwapBlocktrade.value,
         maximumBlockPrice                |-> maximumBlockPrice.value,
         minimumBlockPrice                |-> minimumBlockPrice.value,
         systemId                         |-> systemId.value,
         sourceTimeMicroSecs              |-> sourceTimeMicroSecs.value,
         multiplierScaleCode              |-> multiplierScaleCode.value,
         accumulatedInterestScaleCode     |-> accumulatedInterestScaleCode.value,
         openingPriceScaleCode            |-> openingPriceScaleCode.value,
         maximumPriceScaleCode            |-> maximumPriceScaleCode.value,
         minimumPriceScaleCode            |-> minimumPriceScaleCode.value,
         closingPriceScaleCode            |-> closingPriceScaleCode.value,
         impliedVolatilityScaleCode       |-> impliedVolatilityScaleCode.value,
         averageWeightedPriceScaleCode    |-> averageWeightedPriceScaleCode.value,
         referencePriceScaleCode          |-> referencePriceScaleCode.value,
         pctChangePriceScaleCode          |-> pctChangePriceScaleCode.value,
         dividendRateScaleCode            |-> dividendRateScaleCode.value,
         settlementPriceScaleCode         |-> settlementPriceScaleCode.value,
         settlementValueScaleCode         |-> settlementValueScaleCode.value,
         reserved1                        |-> reserved1.value,
         tradingValueScaleCode            |-> tradingValueScaleCode.value,
         currencyPriceScaleCode           |-> currencyPriceScaleCode.value,
         deltaScaleCode                   |-> deltaScaleCode.value,
         gammaScaleCode                   |-> gammaScaleCode.value,
         rhoScaleCode                     |-> rhoScaleCode.value,
         thetaScaleCode                   |-> thetaScaleCode.value,
         vegaScaleCode                    |-> vegaScaleCode.value,
         tradingValueCurrencyScaleCode    |-> tradingValueCurrencyScaleCode.value,
         interestRateScaleCode            |-> interestRateScaleCode.value,
         volatilityScaleCode              |-> volatilityScaleCode.value,
         strikePriceScaleCode             |-> strikePriceScaleCode.value,
         valueShortSellingTradesScaleCode |-> valueShortSellingTradesScaleCode.value,
         lastTradePriceScaleCode          |-> lastTradePriceScaleCode.value,
         valueBlockTradesScaleCode        |-> valueBlockTradesScaleCode.value,
         vwapBlocktradeScaleCode          |-> vwapBlocktradeScaleCode.value,
         maximumBlockPriceScaleCode       |-> maximumBlockPriceScaleCode.value,
         minimumBlockPriceScaleCode       |-> minimumBlockPriceScaleCode.value,
         statusIndicator                  |-> statusIndicator.value,
         sector                           |-> sector.value,
         market                           |-> market.value,
         secondReserved1                  |-> secondReserved1.value,
         shortSale                        |-> shortSale.value,
         markerPctChangePrice             |-> markerPctChangePrice.value,
         symbolDelta                      |-> symbolDelta.value,
         symbolGamma                      |-> symbolGamma.value,
         symbolRho                        |-> symbolRho.value,
         symbolTheta                      |-> symbolTheta.value,
         symbolVega                       |-> symbolVega.value,
         thirdReserved1                   |-> thirdReserved1.value,
         fourthReserved1                  |-> fourthReserved1.value,
         fifthReserved1                   |-> fifthReserved1.value,
         sixthReserved1                   |-> sixthReserved1.value,
         seventhReserved1                 |-> seventhReserved1.value,
         eighthReserved1                  |-> eighthReserved1.value,
         segment                          |-> segment.value,
         lowerLiquidity                   |-> lowerLiquidity.value,
         dividend                         |-> dividend.value,
         subscriptionRight                |-> subscriptionRight.value,
         split                            |-> split.value,
         interimDividendRight             |-> interimDividendRight.value,
         quotationSystem                  |-> quotationSystem.value,
         liquiditySupportPge              |-> liquiditySupportPge.value,
         ninthReserved1                   |-> ninthReserved1.value ], ninthReserved1.rest)

ZeroSessionSummaryMessage ==
    [ symbolIndex                      |-> [i \in 1 .. 4 |-> 0],
      sourceTime                       |-> [i \in 1 .. 4 |-> 0],
      sourceSeqNum                     |-> [i \in 1 .. 4 |-> 0],
      date                             |-> [i \in 1 .. 4 |-> 0],
      multiplier                       |-> [i \in 1 .. 4 |-> 0],
      accumulatedInterest              |-> [i \in 1 .. 4 |-> 0],
      openingPrice                     |-> [i \in 1 .. 4 |-> 0],
      maximumPrice                     |-> [i \in 1 .. 4 |-> 0],
      minimumPrice                     |-> [i \in 1 .. 4 |-> 0],
      closingPrice                     |-> [i \in 1 .. 4 |-> 0],
      impliedVolatility                |-> [i \in 1 .. 4 |-> 0],
      averageWeightedPrice             |-> [i \in 1 .. 4 |-> 0],
      referencePrice                   |-> [i \in 1 .. 4 |-> 0],
      pctChangePrice                   |-> [i \in 1 .. 4 |-> 0],
      dividendRate                     |-> [i \in 1 .. 4 |-> 0],
      settlementPrice                  |-> [i \in 1 .. 4 |-> 0],
      settlementValue                  |-> [i \in 1 .. 4 |-> 0],
      reserved4                        |-> [i \in 1 .. 4 |-> 0],
      openPositions                    |-> [i \in 1 .. 4 |-> 0],
      tradingVolume                    |-> [i \in 1 .. 4 |-> 0],
      transactionsNumber               |-> [i \in 1 .. 4 |-> 0],
      tradingValue                     |-> [i \in 1 .. 8 |-> 0],
      currencyPrice                    |-> [i \in 1 .. 4 |-> 0],
      delta                            |-> [i \in 1 .. 4 |-> 0],
      gamma                            |-> [i \in 1 .. 4 |-> 0],
      rho                              |-> [i \in 1 .. 4 |-> 0],
      theta                            |-> [i \in 1 .. 4 |-> 0],
      vega                             |-> [i \in 1 .. 4 |-> 0],
      endTrading                       |-> [i \in 1 .. 4 |-> 0],
      numberOfInstruments              |-> [i \in 1 .. 4 |-> 0],
      tradingValueCurrency             |-> [i \in 1 .. 8 |-> 0],
      interestRate                     |-> [i \in 1 .. 4 |-> 0],
      volatility                       |-> [i \in 1 .. 4 |-> 0],
      strikePrice                      |-> [i \in 1 .. 4 |-> 0],
      shortSellingTradesNumber         |-> [i \in 1 .. 4 |-> 0],
      volumeShortSellingTrades         |-> [i \in 1 .. 4 |-> 0],
      valueShortSellingTrades          |-> [i \in 1 .. 4 |-> 0],
      lastTradeDate                    |-> [i \in 1 .. 4 |-> 0],
      lastTradePrice                   |-> [i \in 1 .. 4 |-> 0],
      blockTradesNumber                |-> [i \in 1 .. 4 |-> 0],
      volumeBlockTrades                |-> [i \in 1 .. 4 |-> 0],
      valueBlockTrades                 |-> [i \in 1 .. 4 |-> 0],
      vwapBlocktrade                   |-> [i \in 1 .. 4 |-> 0],
      maximumBlockPrice                |-> [i \in 1 .. 4 |-> 0],
      minimumBlockPrice                |-> [i \in 1 .. 4 |-> 0],
      systemId                         |-> [i \in 1 .. 4 |-> 0],
      sourceTimeMicroSecs              |-> [i \in 1 .. 2 |-> 0],
      multiplierScaleCode              |-> [i \in 1 .. 1 |-> 0],
      accumulatedInterestScaleCode     |-> [i \in 1 .. 1 |-> 0],
      openingPriceScaleCode            |-> [i \in 1 .. 1 |-> 0],
      maximumPriceScaleCode            |-> [i \in 1 .. 1 |-> 0],
      minimumPriceScaleCode            |-> [i \in 1 .. 1 |-> 0],
      closingPriceScaleCode            |-> [i \in 1 .. 1 |-> 0],
      impliedVolatilityScaleCode       |-> [i \in 1 .. 1 |-> 0],
      averageWeightedPriceScaleCode    |-> [i \in 1 .. 1 |-> 0],
      referencePriceScaleCode          |-> [i \in 1 .. 1 |-> 0],
      pctChangePriceScaleCode          |-> [i \in 1 .. 1 |-> 0],
      dividendRateScaleCode            |-> [i \in 1 .. 1 |-> 0],
      settlementPriceScaleCode         |-> [i \in 1 .. 1 |-> 0],
      settlementValueScaleCode         |-> [i \in 1 .. 1 |-> 0],
      reserved1                        |-> [i \in 1 .. 1 |-> 0],
      tradingValueScaleCode            |-> [i \in 1 .. 1 |-> 0],
      currencyPriceScaleCode           |-> [i \in 1 .. 1 |-> 0],
      deltaScaleCode                   |-> [i \in 1 .. 1 |-> 0],
      gammaScaleCode                   |-> [i \in 1 .. 1 |-> 0],
      rhoScaleCode                     |-> [i \in 1 .. 1 |-> 0],
      thetaScaleCode                   |-> [i \in 1 .. 1 |-> 0],
      vegaScaleCode                    |-> [i \in 1 .. 1 |-> 0],
      tradingValueCurrencyScaleCode    |-> [i \in 1 .. 1 |-> 0],
      interestRateScaleCode            |-> [i \in 1 .. 1 |-> 0],
      volatilityScaleCode              |-> [i \in 1 .. 1 |-> 0],
      strikePriceScaleCode             |-> [i \in 1 .. 1 |-> 0],
      valueShortSellingTradesScaleCode |-> [i \in 1 .. 1 |-> 0],
      lastTradePriceScaleCode          |-> [i \in 1 .. 1 |-> 0],
      valueBlockTradesScaleCode        |-> [i \in 1 .. 1 |-> 0],
      vwapBlocktradeScaleCode          |-> [i \in 1 .. 1 |-> 0],
      maximumBlockPriceScaleCode       |-> [i \in 1 .. 1 |-> 0],
      minimumBlockPriceScaleCode       |-> [i \in 1 .. 1 |-> 0],
      statusIndicator                  |-> [i \in 1 .. 1 |-> 0],
      sector                           |-> [i \in 1 .. 3 |-> 0],
      market                           |-> [i \in 1 .. 1 |-> 0],
      secondReserved1                  |-> [i \in 1 .. 1 |-> 0],
      shortSale                        |-> [i \in 1 .. 1 |-> 0],
      markerPctChangePrice             |-> [i \in 1 .. 1 |-> 0],
      symbolDelta                      |-> [i \in 1 .. 1 |-> 0],
      symbolGamma                      |-> [i \in 1 .. 1 |-> 0],
      symbolRho                        |-> [i \in 1 .. 1 |-> 0],
      symbolTheta                      |-> [i \in 1 .. 1 |-> 0],
      symbolVega                       |-> [i \in 1 .. 1 |-> 0],
      thirdReserved1                   |-> [i \in 1 .. 1 |-> 0],
      fourthReserved1                  |-> [i \in 1 .. 1 |-> 0],
      fifthReserved1                   |-> [i \in 1 .. 1 |-> 0],
      sixthReserved1                   |-> [i \in 1 .. 1 |-> 0],
      seventhReserved1                 |-> [i \in 1 .. 1 |-> 0],
      eighthReserved1                  |-> [i \in 1 .. 1 |-> 0],
      segment                          |-> [i \in 1 .. 2 |-> 0],
      lowerLiquidity                   |-> [i \in 1 .. 1 |-> 0],
      dividend                         |-> [i \in 1 .. 2 |-> 0],
      subscriptionRight                |-> [i \in 1 .. 2 |-> 0],
      split                            |-> [i \in 1 .. 2 |-> 0],
      interimDividendRight             |-> [i \in 1 .. 2 |-> 0],
      quotationSystem                  |-> [i \in 1 .. 2 |-> 0],
      liquiditySupportPge              |-> [i \in 1 .. 2 |-> 0],
      ninthReserved1                   |-> [i \in 1 .. 1 |-> 0] ]

(* Session Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedSessionSummaryMessage ==
    { ZeroSessionSummaryMessage }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.sourceSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.date = one] : one \in Sample(4) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.multiplier = one] : one \in Sample(4) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.accumulatedInterest = one] : one \in Sample(4) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.openingPrice = one] : one \in Sample(4) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.maximumPrice = one] : one \in Sample(4) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.minimumPrice = one] : one \in Sample(4) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.closingPrice = one] : one \in Sample(4) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.impliedVolatility = one] : one \in Sample(4) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.averageWeightedPrice = one] : one \in Sample(4) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.referencePrice = one] : one \in Sample(4) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.pctChangePrice = one] : one \in Sample(4) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.dividendRate = one] : one \in Sample(4) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.settlementPrice = one] : one \in Sample(4) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.settlementValue = one] : one \in Sample(4) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.openPositions = one] : one \in Sample(4) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.tradingVolume = one] : one \in Sample(4) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.transactionsNumber = one] : one \in Sample(4) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.tradingValue = one] : one \in Sample(8) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.currencyPrice = one] : one \in Sample(4) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.delta = one] : one \in Sample(4) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.gamma = one] : one \in Sample(4) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.rho = one] : one \in Sample(4) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.theta = one] : one \in Sample(4) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.vega = one] : one \in Sample(4) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.endTrading = one] : one \in Sample(4) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.numberOfInstruments = one] : one \in Sample(4) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.tradingValueCurrency = one] : one \in Sample(8) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.interestRate = one] : one \in Sample(4) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.volatility = one] : one \in Sample(4) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.shortSellingTradesNumber = one] : one \in Sample(4) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.volumeShortSellingTrades = one] : one \in Sample(4) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.valueShortSellingTrades = one] : one \in Sample(4) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.lastTradeDate = one] : one \in Sample(4) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.lastTradePrice = one] : one \in Sample(4) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.blockTradesNumber = one] : one \in Sample(4) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.volumeBlockTrades = one] : one \in Sample(4) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.valueBlockTrades = one] : one \in Sample(4) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.vwapBlocktrade = one] : one \in Sample(4) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.maximumBlockPrice = one] : one \in Sample(4) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.minimumBlockPrice = one] : one \in Sample(4) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.systemId = one] : one \in Sample(4) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.sourceTimeMicroSecs = one] : one \in Sample(2) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.multiplierScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.accumulatedInterestScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.openingPriceScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.maximumPriceScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.minimumPriceScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.closingPriceScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.impliedVolatilityScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.averageWeightedPriceScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.referencePriceScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.pctChangePriceScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.dividendRateScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.settlementPriceScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.settlementValueScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.tradingValueScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.currencyPriceScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.deltaScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.gammaScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.rhoScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.thetaScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.vegaScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.tradingValueCurrencyScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.interestRateScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.volatilityScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.strikePriceScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.valueShortSellingTradesScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.lastTradePriceScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.valueBlockTradesScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.vwapBlocktradeScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.maximumBlockPriceScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.minimumBlockPriceScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.statusIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.sector = one] : one \in Sample(3) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.market = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.secondReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.shortSale = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.markerPctChangePrice = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.symbolDelta = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.symbolGamma = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.symbolRho = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.symbolTheta = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.symbolVega = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.thirdReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.fourthReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.fifthReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.sixthReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.seventhReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.eighthReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.segment = one] : one \in Sample(2) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.lowerLiquidity = one] : one \in Sample(1) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.dividend = one] : one \in Sample(2) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.subscriptionRight = one] : one \in Sample(2) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.split = one] : one \in Sample(2) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.interimDividendRight = one] : one \in Sample(2) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.quotationSystem = one] : one \in Sample(2) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.liquiditySupportPge = one] : one \in Sample(2) }
        \cup { [ZeroSessionSummaryMessage EXCEPT !.ninthReserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

ClassStateChangeMessageCode == 516  \* 0x204
MailMessageCode == 523  \* 0x20b
CollarsMessageCode == 537  \* 0x219
SessionTimetableMessageCode == 539  \* 0x21b
StartReferentialMessageCode == 550  \* 0x226
EndReferentialMessageCode == 551  \* 0x227
ReferentialMessageCode == 556  \* 0x22c
SessionSummaryMessageCode == 561  \* 0x231

Payload ==
    [ tag : {ClassStateChangeMessageCode}, body : ClassStateChangeMessage ]
        \cup [ tag : {MailMessageCode}, body : MailMessage ]
        \cup [ tag : {CollarsMessageCode}, body : CollarsMessage ]
        \cup [ tag : {SessionTimetableMessageCode}, body : SessionTimetableMessage ]
        \cup [ tag : {StartReferentialMessageCode}, body : StartReferentialMessage ]
        \cup [ tag : {EndReferentialMessageCode}, body : EndReferentialMessage ]
        \cup [ tag : {ReferentialMessageCode}, body : ReferentialMessage ]
        \cup [ tag : {SessionSummaryMessageCode}, body : SessionSummaryMessage ]

EncodePayload(message) ==
    CASE message.tag = ClassStateChangeMessageCode -> EncodeClassStateChangeMessage(message.body)
      [] message.tag = MailMessageCode -> EncodeMailMessage(message.body)
      [] message.tag = CollarsMessageCode -> EncodeCollarsMessage(message.body)
      [] message.tag = SessionTimetableMessageCode -> EncodeSessionTimetableMessage(message.body)
      [] message.tag = StartReferentialMessageCode -> EncodeStartReferentialMessage(message.body)
      [] message.tag = EndReferentialMessageCode -> EncodeEndReferentialMessage(message.body)
      [] message.tag = ReferentialMessageCode -> EncodeReferentialMessage(message.body)
      [] message.tag = SessionSummaryMessageCode -> EncodeSessionSummaryMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = ClassStateChangeMessageCode -> DecodeClassStateChangeMessage(bytes)
              [] tag = MailMessageCode -> DecodeMailMessage(bytes)
              [] tag = CollarsMessageCode -> DecodeCollarsMessage(bytes)
              [] tag = SessionTimetableMessageCode -> DecodeSessionTimetableMessage(bytes)
              [] tag = StartReferentialMessageCode -> DecodeStartReferentialMessage(bytes)
              [] tag = EndReferentialMessageCode -> DecodeEndReferentialMessage(bytes)
              [] tag = ReferentialMessageCode -> DecodeReferentialMessage(bytes)
              [] tag = SessionSummaryMessageCode -> DecodeSessionSummaryMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> ClassStateChangeMessageCode, body |-> ZeroClassStateChangeMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> ClassStateChangeMessageCode, body |-> one] : one \in CheckedClassStateChangeMessage }
        \cup { [tag |-> MailMessageCode, body |-> one] : one \in CheckedMailMessage }
        \cup { [tag |-> CollarsMessageCode, body |-> one] : one \in CheckedCollarsMessage }
        \cup { [tag |-> SessionTimetableMessageCode, body |-> one] : one \in CheckedSessionTimetableMessage }
        \cup { [tag |-> StartReferentialMessageCode, body |-> one] : one \in CheckedStartReferentialMessage }
        \cup { [tag |-> EndReferentialMessageCode, body |-> one] : one \in CheckedEndReferentialMessage }
        \cup { [tag |-> ReferentialMessageCode, body |-> one] : one \in CheckedReferentialMessage }
        \cup { [tag |-> SessionSummaryMessageCode, body |-> one] : one \in CheckedSessionSummaryMessage }

(***************************************************************************)
(* Message, framed by Message Size                                         *)
(***************************************************************************)

Message ==
    [ payload : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntBE(message.payload.tag, 2)
        \o EncodePayload(message.payload)

(* Message Size counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntBE(bytes, 2) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> ClassStateChangeMessageCode, body |-> ZeroClassStateChangeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MailMessageCode, body |-> ZeroMailMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CollarsMessageCode, body |-> ZeroCollarsMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SessionTimetableMessageCode, body |-> ZeroSessionTimetableMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StartReferentialMessageCode, body |-> ZeroStartReferentialMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EndReferentialMessageCode, body |-> ZeroEndReferentialMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ReferentialMessageCode, body |-> ZeroReferentialMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SessionSummaryMessageCode, body |-> ZeroSessionSummaryMessage]] }

(***************************************************************************)
(* Message Buffer, selected by Delivery Flag                               *)
(***************************************************************************)

MessageBufferZlibCode == 16  \* 0x10
MessageBufferPlainCode == 0  \* 0x00

MessageBufferBody ==
    [ tag : 16 .. 255, body : MessageBufferZlib ]
        \cup { [tag |-> tag, body |-> one] : tag \in {0, 15}, one \in SampleLists(OneMessage) }

EncodeMessageBufferBody(message) ==
    CASE message.tag \in 16 .. 255 -> EncodeMessageBufferZlib(message.body)
      [] message.tag \in 0 .. 15 -> EncodeMessageList(message.body)

(* How many Message a Message Buffer holds, which is what Number Msg Entries states. *)
(* A case that is no run of them says nothing about the number, so it holds whatever was stated. *)
CountMessageBufferBody(choice, stated) ==
    CASE choice.tag \in 16 .. 255 -> stated
      [] choice.tag \in 0 .. 15 -> Len(choice.body)

DecodeMessageBufferBody(tag, count, bytes) ==
    LET read ==
            CASE tag \in 16 .. 255 -> DecodeMessageBufferZlib(bytes)
              [] tag \in 0 .. 15 -> ReadMessageList(bytes, count)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroMessageBufferBody == [tag |-> MessageBufferZlibCode, body |-> ZeroMessageBufferZlib]

(* Each Message Buffer in turn, at the values the message it names is checked at *)
CheckedMessageBufferBody ==
    { [tag |-> tag, body |-> one] : tag \in {16, 255}, one \in CheckedMessageBufferZlib }
        \cup { [tag |-> tag, body |-> one] : tag \in {0, 15}, one \in SampleLists(OneMessage) }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ packetLength         : Sample(2),
      packetType           : Sample(2),
      packetSequenceNumber : Sample(4),
      sendTime             : Sample(4),
      serviceId            : Sample(2),
      numberMsgEntries     : 0 .. 255,
      messageBuffer        : MessageBufferBody ]

EncodePacket(message) ==
    message.packetLength
        \o message.packetType
        \o message.packetSequenceNumber
        \o message.sendTime
        \o message.serviceId
        \o EncodeUIntBE(message.messageBuffer.tag, 1)
        \o EncodeUIntBE(message.numberMsgEntries, 1)
        \o EncodeMessageBufferBody(message.messageBuffer)

DecodePacket(bytes) ==
    LET packetLength == ReadBytes(bytes, 2) IN IF ~packetLength.ok THEN Fail ELSE
    LET packetType == ReadBytes(packetLength.rest, 2) IN IF ~packetType.ok THEN Fail ELSE
    LET packetSequenceNumber == ReadBytes(packetType.rest, 4) IN IF ~packetSequenceNumber.ok THEN Fail ELSE
    LET sendTime == ReadBytes(packetSequenceNumber.rest, 4) IN IF ~sendTime.ok THEN Fail ELSE
    LET serviceId == ReadBytes(sendTime.rest, 2) IN IF ~serviceId.ok THEN Fail ELSE
    LET deliveryFlag == ReadUIntBE(serviceId.rest, 1) IN IF ~deliveryFlag.ok THEN Fail ELSE
    LET numberMsgEntries == ReadUIntBE(deliveryFlag.rest, 1) IN IF ~numberMsgEntries.ok THEN Fail ELSE
    LET messageBuffer == DecodeMessageBufferBody(deliveryFlag.value, numberMsgEntries.value, numberMsgEntries.rest) IN IF ~messageBuffer.ok THEN Fail ELSE
    Ok([ packetLength         |-> packetLength.value,
         packetType           |-> packetType.value,
         packetSequenceNumber |-> packetSequenceNumber.value,
         sendTime             |-> sendTime.value,
         serviceId            |-> serviceId.value,
         numberMsgEntries     |-> numberMsgEntries.value,
         messageBuffer        |-> messageBuffer.value ], messageBuffer.rest)

ZeroPacket ==
    [ packetLength         |-> [i \in 1 .. 2 |-> 0],
      packetType           |-> [i \in 1 .. 2 |-> 0],
      packetSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      sendTime             |-> [i \in 1 .. 4 |-> 0],
      serviceId            |-> [i \in 1 .. 2 |-> 0],
      numberMsgEntries     |-> 0,
      messageBuffer        |-> ZeroMessageBufferBody ]

(* Packet at zero, then each field in turn at the values it is checked at *)
(* Number Msg Entries is varied with the Message Buffer it counts, which is read as many as it says *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.packetLength = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.packetType = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.packetSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.sendTime = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.serviceId = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.numberMsgEntries = one] : one \in {0, 1, 255} }
        \cup { [ZeroPacket EXCEPT !.numberMsgEntries = CountMessageBufferBody(one, 0), !.messageBuffer = one] : one \in CheckedMessageBufferBody }

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

(* Every Message Buffer decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageBufferZlib ==
    \A message \in CheckedMessageBufferZlib :
        LET read == DecodeMessageBufferZlib(EncodeMessageBufferZlib(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Class State Change Message decodes back to what was encoded, and leaves nothing over *)
RoundTripClassStateChangeMessage ==
    \A message \in CheckedClassStateChangeMessage :
        LET read == DecodeClassStateChangeMessage(EncodeClassStateChangeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mail Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMailMessage ==
    \A message \in CheckedMailMessage :
        LET read == DecodeMailMessage(EncodeMailMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Collars Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCollarsMessage ==
    \A message \in CheckedCollarsMessage :
        LET read == DecodeCollarsMessage(EncodeCollarsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Class Phase decodes back to what was encoded, and leaves nothing over *)
RoundTripClassPhase ==
    \A message \in CheckedClassPhase :
        LET read == DecodeClassPhase(EncodeClassPhase(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Session Timetable Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSessionTimetableMessage ==
    \A message \in CheckedSessionTimetableMessage :
        LET read == DecodeSessionTimetableMessage(EncodeSessionTimetableMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Start Referential Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStartReferentialMessage ==
    \A message \in CheckedStartReferentialMessage :
        LET read == DecodeStartReferentialMessage(EncodeStartReferentialMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Referential Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndReferentialMessage ==
    \A message \in CheckedEndReferentialMessage :
        LET read == DecodeEndReferentialMessage(EncodeEndReferentialMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Depositary List decodes back to what was encoded, and leaves nothing over *)
RoundTripDepositaryList ==
    \A message \in CheckedDepositaryList :
        LET read == DecodeDepositaryList(EncodeDepositaryList(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Referential Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReferentialMessage ==
    \A message \in CheckedReferentialMessage :
        LET read == DecodeReferentialMessage(EncodeReferentialMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Session Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSessionSummaryMessage ==
    \A message \in CheckedSessionSummaryMessage :
        LET read == DecodeSessionSummaryMessage(EncodeSessionSummaryMessage(message))
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
        LET sent == EncodePayload(message)
            read == DecodePayload(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Message Buffer is selected by the Delivery Flag it is written under *)
SelectsMessageBufferBody ==
    \A message \in CheckedMessageBufferBody :
        LET sent == EncodeMessageBufferBody(message)
            read == DecodeMessageBufferBody(message.tag, CountMessageBufferBody(message, 0), sent)
        IN  read.ok /\ read.value.tag = message.tag

(* Message Size is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
