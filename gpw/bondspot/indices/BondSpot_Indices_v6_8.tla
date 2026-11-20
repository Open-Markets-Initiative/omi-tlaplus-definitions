----------------------- MODULE BondSpot_Indices_v6_8 -----------------------
(***************************************************************************)
(* Giełda Papierów Wartościowych w Warszawie BondSpot Indices v6.8         *)
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
(* Note: Index Portfolio Component is written as 20 slots, however many of *)
(* them the count beside it says are in use.                               *)
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
(* Real Time Index Message: 108 bytes                                      *)
(***************************************************************************)

RealTimeIndexMessage ==
    [ symbolIndex                   : Sample(4),
      sourceTime                    : Sample(4),
      sourceSeqNum                  : Sample(4),
      systemId                      : Sample(4),
      indexLevel                    : Sample(4),
      sessionHigh                   : Sample(4),
      sessionLow                    : Sample(4),
      indIndexOpeningPortfolio      : Sample(4),
      percentChangeToi              : Sample(4),
      pctChangeIndexValPrevSession  : Sample(4),
      pctChangeIndexValPrevYear     : Sample(4),
      toi                           : Sample(4),
      pointChange                   : Sample(4),
      valueTrading                  : Sample(8),
      indexValueBid                 : Sample(4),
      indexValueAsk                 : Sample(4),
      midSpreadIndex                : Sample(4),
      differenceCentralSpread       : Sample(4),
      numOfActiveInstruments        : Sample(2),
      numOfInstrOfDecreasingQt      : Sample(2),
      numOfInstrOfIncreasingQt      : Sample(2),
      numOfInstrOfUnchangedQt       : Sample(2),
      sourceTimeMicroSecs           : Sample(2),
      levelScaleCode                : Sample(1),
      timeFirstHigh                 : Sample(6),
      timeFirstLow                  : Sample(6),
      indexStatusIndicator          : Sample(2),
      indexLevelCode                : Sample(1),
      markerPercentChangeToi        : Sample(1),
      markerPctChgIndexValPrevSess  : Sample(1),
      markerPctChgIndexValPrevYear  : Sample(1),
      markerPointChange             : Sample(1),
      markerDifferenceCentralSpread : Sample(1),
      disseminationFrequencyMarker  : Sample(1) ]

EncodeRealTimeIndexMessage(message) ==
    message.symbolIndex
        \o message.sourceTime
        \o message.sourceSeqNum
        \o message.systemId
        \o message.indexLevel
        \o message.sessionHigh
        \o message.sessionLow
        \o message.indIndexOpeningPortfolio
        \o message.percentChangeToi
        \o message.pctChangeIndexValPrevSession
        \o message.pctChangeIndexValPrevYear
        \o message.toi
        \o message.pointChange
        \o message.valueTrading
        \o message.indexValueBid
        \o message.indexValueAsk
        \o message.midSpreadIndex
        \o message.differenceCentralSpread
        \o message.numOfActiveInstruments
        \o message.numOfInstrOfDecreasingQt
        \o message.numOfInstrOfIncreasingQt
        \o message.numOfInstrOfUnchangedQt
        \o message.sourceTimeMicroSecs
        \o message.levelScaleCode
        \o message.timeFirstHigh
        \o message.timeFirstLow
        \o message.indexStatusIndicator
        \o message.indexLevelCode
        \o message.markerPercentChangeToi
        \o message.markerPctChgIndexValPrevSess
        \o message.markerPctChgIndexValPrevYear
        \o message.markerPointChange
        \o message.markerDifferenceCentralSpread
        \o message.disseminationFrequencyMarker

DecodeRealTimeIndexMessage(bytes) ==
    LET symbolIndex == ReadBytes(bytes, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET sourceTime == ReadBytes(symbolIndex.rest, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceSeqNum == ReadBytes(sourceTime.rest, 4) IN IF ~sourceSeqNum.ok THEN Fail ELSE
    LET systemId == ReadBytes(sourceSeqNum.rest, 4) IN IF ~systemId.ok THEN Fail ELSE
    LET indexLevel == ReadBytes(systemId.rest, 4) IN IF ~indexLevel.ok THEN Fail ELSE
    LET sessionHigh == ReadBytes(indexLevel.rest, 4) IN IF ~sessionHigh.ok THEN Fail ELSE
    LET sessionLow == ReadBytes(sessionHigh.rest, 4) IN IF ~sessionLow.ok THEN Fail ELSE
    LET indIndexOpeningPortfolio == ReadBytes(sessionLow.rest, 4) IN IF ~indIndexOpeningPortfolio.ok THEN Fail ELSE
    LET percentChangeToi == ReadBytes(indIndexOpeningPortfolio.rest, 4) IN IF ~percentChangeToi.ok THEN Fail ELSE
    LET pctChangeIndexValPrevSession == ReadBytes(percentChangeToi.rest, 4) IN IF ~pctChangeIndexValPrevSession.ok THEN Fail ELSE
    LET pctChangeIndexValPrevYear == ReadBytes(pctChangeIndexValPrevSession.rest, 4) IN IF ~pctChangeIndexValPrevYear.ok THEN Fail ELSE
    LET toi == ReadBytes(pctChangeIndexValPrevYear.rest, 4) IN IF ~toi.ok THEN Fail ELSE
    LET pointChange == ReadBytes(toi.rest, 4) IN IF ~pointChange.ok THEN Fail ELSE
    LET valueTrading == ReadBytes(pointChange.rest, 8) IN IF ~valueTrading.ok THEN Fail ELSE
    LET indexValueBid == ReadBytes(valueTrading.rest, 4) IN IF ~indexValueBid.ok THEN Fail ELSE
    LET indexValueAsk == ReadBytes(indexValueBid.rest, 4) IN IF ~indexValueAsk.ok THEN Fail ELSE
    LET midSpreadIndex == ReadBytes(indexValueAsk.rest, 4) IN IF ~midSpreadIndex.ok THEN Fail ELSE
    LET differenceCentralSpread == ReadBytes(midSpreadIndex.rest, 4) IN IF ~differenceCentralSpread.ok THEN Fail ELSE
    LET numOfActiveInstruments == ReadBytes(differenceCentralSpread.rest, 2) IN IF ~numOfActiveInstruments.ok THEN Fail ELSE
    LET numOfInstrOfDecreasingQt == ReadBytes(numOfActiveInstruments.rest, 2) IN IF ~numOfInstrOfDecreasingQt.ok THEN Fail ELSE
    LET numOfInstrOfIncreasingQt == ReadBytes(numOfInstrOfDecreasingQt.rest, 2) IN IF ~numOfInstrOfIncreasingQt.ok THEN Fail ELSE
    LET numOfInstrOfUnchangedQt == ReadBytes(numOfInstrOfIncreasingQt.rest, 2) IN IF ~numOfInstrOfUnchangedQt.ok THEN Fail ELSE
    LET sourceTimeMicroSecs == ReadBytes(numOfInstrOfUnchangedQt.rest, 2) IN IF ~sourceTimeMicroSecs.ok THEN Fail ELSE
    LET levelScaleCode == ReadBytes(sourceTimeMicroSecs.rest, 1) IN IF ~levelScaleCode.ok THEN Fail ELSE
    LET timeFirstHigh == ReadBytes(levelScaleCode.rest, 6) IN IF ~timeFirstHigh.ok THEN Fail ELSE
    LET timeFirstLow == ReadBytes(timeFirstHigh.rest, 6) IN IF ~timeFirstLow.ok THEN Fail ELSE
    LET indexStatusIndicator == ReadBytes(timeFirstLow.rest, 2) IN IF ~indexStatusIndicator.ok THEN Fail ELSE
    LET indexLevelCode == ReadBytes(indexStatusIndicator.rest, 1) IN IF ~indexLevelCode.ok THEN Fail ELSE
    LET markerPercentChangeToi == ReadBytes(indexLevelCode.rest, 1) IN IF ~markerPercentChangeToi.ok THEN Fail ELSE
    LET markerPctChgIndexValPrevSess == ReadBytes(markerPercentChangeToi.rest, 1) IN IF ~markerPctChgIndexValPrevSess.ok THEN Fail ELSE
    LET markerPctChgIndexValPrevYear == ReadBytes(markerPctChgIndexValPrevSess.rest, 1) IN IF ~markerPctChgIndexValPrevYear.ok THEN Fail ELSE
    LET markerPointChange == ReadBytes(markerPctChgIndexValPrevYear.rest, 1) IN IF ~markerPointChange.ok THEN Fail ELSE
    LET markerDifferenceCentralSpread == ReadBytes(markerPointChange.rest, 1) IN IF ~markerDifferenceCentralSpread.ok THEN Fail ELSE
    LET disseminationFrequencyMarker == ReadBytes(markerDifferenceCentralSpread.rest, 1) IN IF ~disseminationFrequencyMarker.ok THEN Fail ELSE
    Ok([ symbolIndex                   |-> symbolIndex.value,
         sourceTime                    |-> sourceTime.value,
         sourceSeqNum                  |-> sourceSeqNum.value,
         systemId                      |-> systemId.value,
         indexLevel                    |-> indexLevel.value,
         sessionHigh                   |-> sessionHigh.value,
         sessionLow                    |-> sessionLow.value,
         indIndexOpeningPortfolio      |-> indIndexOpeningPortfolio.value,
         percentChangeToi              |-> percentChangeToi.value,
         pctChangeIndexValPrevSession  |-> pctChangeIndexValPrevSession.value,
         pctChangeIndexValPrevYear     |-> pctChangeIndexValPrevYear.value,
         toi                           |-> toi.value,
         pointChange                   |-> pointChange.value,
         valueTrading                  |-> valueTrading.value,
         indexValueBid                 |-> indexValueBid.value,
         indexValueAsk                 |-> indexValueAsk.value,
         midSpreadIndex                |-> midSpreadIndex.value,
         differenceCentralSpread       |-> differenceCentralSpread.value,
         numOfActiveInstruments        |-> numOfActiveInstruments.value,
         numOfInstrOfDecreasingQt      |-> numOfInstrOfDecreasingQt.value,
         numOfInstrOfIncreasingQt      |-> numOfInstrOfIncreasingQt.value,
         numOfInstrOfUnchangedQt       |-> numOfInstrOfUnchangedQt.value,
         sourceTimeMicroSecs           |-> sourceTimeMicroSecs.value,
         levelScaleCode                |-> levelScaleCode.value,
         timeFirstHigh                 |-> timeFirstHigh.value,
         timeFirstLow                  |-> timeFirstLow.value,
         indexStatusIndicator          |-> indexStatusIndicator.value,
         indexLevelCode                |-> indexLevelCode.value,
         markerPercentChangeToi        |-> markerPercentChangeToi.value,
         markerPctChgIndexValPrevSess  |-> markerPctChgIndexValPrevSess.value,
         markerPctChgIndexValPrevYear  |-> markerPctChgIndexValPrevYear.value,
         markerPointChange             |-> markerPointChange.value,
         markerDifferenceCentralSpread |-> markerDifferenceCentralSpread.value,
         disseminationFrequencyMarker  |-> disseminationFrequencyMarker.value ], disseminationFrequencyMarker.rest)

ZeroRealTimeIndexMessage ==
    [ symbolIndex                   |-> [i \in 1 .. 4 |-> 0],
      sourceTime                    |-> [i \in 1 .. 4 |-> 0],
      sourceSeqNum                  |-> [i \in 1 .. 4 |-> 0],
      systemId                      |-> [i \in 1 .. 4 |-> 0],
      indexLevel                    |-> [i \in 1 .. 4 |-> 0],
      sessionHigh                   |-> [i \in 1 .. 4 |-> 0],
      sessionLow                    |-> [i \in 1 .. 4 |-> 0],
      indIndexOpeningPortfolio      |-> [i \in 1 .. 4 |-> 0],
      percentChangeToi              |-> [i \in 1 .. 4 |-> 0],
      pctChangeIndexValPrevSession  |-> [i \in 1 .. 4 |-> 0],
      pctChangeIndexValPrevYear     |-> [i \in 1 .. 4 |-> 0],
      toi                           |-> [i \in 1 .. 4 |-> 0],
      pointChange                   |-> [i \in 1 .. 4 |-> 0],
      valueTrading                  |-> [i \in 1 .. 8 |-> 0],
      indexValueBid                 |-> [i \in 1 .. 4 |-> 0],
      indexValueAsk                 |-> [i \in 1 .. 4 |-> 0],
      midSpreadIndex                |-> [i \in 1 .. 4 |-> 0],
      differenceCentralSpread       |-> [i \in 1 .. 4 |-> 0],
      numOfActiveInstruments        |-> [i \in 1 .. 2 |-> 0],
      numOfInstrOfDecreasingQt      |-> [i \in 1 .. 2 |-> 0],
      numOfInstrOfIncreasingQt      |-> [i \in 1 .. 2 |-> 0],
      numOfInstrOfUnchangedQt       |-> [i \in 1 .. 2 |-> 0],
      sourceTimeMicroSecs           |-> [i \in 1 .. 2 |-> 0],
      levelScaleCode                |-> [i \in 1 .. 1 |-> 0],
      timeFirstHigh                 |-> [i \in 1 .. 6 |-> 0],
      timeFirstLow                  |-> [i \in 1 .. 6 |-> 0],
      indexStatusIndicator          |-> [i \in 1 .. 2 |-> 0],
      indexLevelCode                |-> [i \in 1 .. 1 |-> 0],
      markerPercentChangeToi        |-> [i \in 1 .. 1 |-> 0],
      markerPctChgIndexValPrevSess  |-> [i \in 1 .. 1 |-> 0],
      markerPctChgIndexValPrevYear  |-> [i \in 1 .. 1 |-> 0],
      markerPointChange             |-> [i \in 1 .. 1 |-> 0],
      markerDifferenceCentralSpread |-> [i \in 1 .. 1 |-> 0],
      disseminationFrequencyMarker  |-> [i \in 1 .. 1 |-> 0] ]

(* Real Time Index Message at zero, then each field in turn at the values it is checked at *)
CheckedRealTimeIndexMessage ==
    { ZeroRealTimeIndexMessage }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.sourceSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.systemId = one] : one \in Sample(4) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.indexLevel = one] : one \in Sample(4) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.sessionHigh = one] : one \in Sample(4) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.sessionLow = one] : one \in Sample(4) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.indIndexOpeningPortfolio = one] : one \in Sample(4) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.percentChangeToi = one] : one \in Sample(4) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.pctChangeIndexValPrevSession = one] : one \in Sample(4) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.pctChangeIndexValPrevYear = one] : one \in Sample(4) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.toi = one] : one \in Sample(4) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.pointChange = one] : one \in Sample(4) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.valueTrading = one] : one \in Sample(8) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.indexValueBid = one] : one \in Sample(4) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.indexValueAsk = one] : one \in Sample(4) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.midSpreadIndex = one] : one \in Sample(4) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.differenceCentralSpread = one] : one \in Sample(4) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.numOfActiveInstruments = one] : one \in Sample(2) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.numOfInstrOfDecreasingQt = one] : one \in Sample(2) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.numOfInstrOfIncreasingQt = one] : one \in Sample(2) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.numOfInstrOfUnchangedQt = one] : one \in Sample(2) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.sourceTimeMicroSecs = one] : one \in Sample(2) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.levelScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.timeFirstHigh = one] : one \in Sample(6) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.timeFirstLow = one] : one \in Sample(6) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.indexStatusIndicator = one] : one \in Sample(2) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.indexLevelCode = one] : one \in Sample(1) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.markerPercentChangeToi = one] : one \in Sample(1) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.markerPctChgIndexValPrevSess = one] : one \in Sample(1) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.markerPctChgIndexValPrevYear = one] : one \in Sample(1) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.markerPointChange = one] : one \in Sample(1) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.markerDifferenceCentralSpread = one] : one \in Sample(1) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.disseminationFrequencyMarker = one] : one \in Sample(1) }

(***************************************************************************)
(* Index Summary Message: 100 bytes                                        *)
(***************************************************************************)

IndexSummaryMessage ==
    [ symbolIndex                   : Sample(4),
      sourceTime                    : Sample(4),
      sourceSeqNum                  : Sample(4),
      systemId                      : Sample(4),
      closingIndexValue             : Sample(4),
      indOpeningPortfolio           : Sample(4),
      openingIndexValue             : Sample(4),
      sessionHigh                   : Sample(4),
      sessionLow                    : Sample(4),
      pctChgHighIndexValPrevSession : Sample(4),
      pctChgLowIndexValPrevSession  : Sample(4),
      pctChangeIndexValPrevSession  : Sample(4),
      pctChangeIndexValPrevYear     : Sample(4),
      capitalisationPortfolio       : Sample(4),
      indexAdjustmentCoefficient    : Sample(4),
      sourceTimeMicroSecs           : Sample(2),
      levelScaleCode                : Sample(1),
      capitalisationScaleCode       : Sample(1),
      indexAdjustmentScaleCode      : Sample(1),
      timeClosing                   : Sample(6),
      timeOpening                   : Sample(6),
      timeFullOpening               : Sample(6),
      timeHigh                      : Sample(6),
      timeLow                       : Sample(6),
      markerHigh                    : Sample(1),
      markerLow                     : Sample(1),
      markerClosingPrevSession      : Sample(1),
      markerClosingPrevYear         : Sample(1),
      reserved1                     : Sample(1) ]

EncodeIndexSummaryMessage(message) ==
    message.symbolIndex
        \o message.sourceTime
        \o message.sourceSeqNum
        \o message.systemId
        \o message.closingIndexValue
        \o message.indOpeningPortfolio
        \o message.openingIndexValue
        \o message.sessionHigh
        \o message.sessionLow
        \o message.pctChgHighIndexValPrevSession
        \o message.pctChgLowIndexValPrevSession
        \o message.pctChangeIndexValPrevSession
        \o message.pctChangeIndexValPrevYear
        \o message.capitalisationPortfolio
        \o message.indexAdjustmentCoefficient
        \o message.sourceTimeMicroSecs
        \o message.levelScaleCode
        \o message.capitalisationScaleCode
        \o message.indexAdjustmentScaleCode
        \o message.timeClosing
        \o message.timeOpening
        \o message.timeFullOpening
        \o message.timeHigh
        \o message.timeLow
        \o message.markerHigh
        \o message.markerLow
        \o message.markerClosingPrevSession
        \o message.markerClosingPrevYear
        \o message.reserved1

DecodeIndexSummaryMessage(bytes) ==
    LET symbolIndex == ReadBytes(bytes, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET sourceTime == ReadBytes(symbolIndex.rest, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceSeqNum == ReadBytes(sourceTime.rest, 4) IN IF ~sourceSeqNum.ok THEN Fail ELSE
    LET systemId == ReadBytes(sourceSeqNum.rest, 4) IN IF ~systemId.ok THEN Fail ELSE
    LET closingIndexValue == ReadBytes(systemId.rest, 4) IN IF ~closingIndexValue.ok THEN Fail ELSE
    LET indOpeningPortfolio == ReadBytes(closingIndexValue.rest, 4) IN IF ~indOpeningPortfolio.ok THEN Fail ELSE
    LET openingIndexValue == ReadBytes(indOpeningPortfolio.rest, 4) IN IF ~openingIndexValue.ok THEN Fail ELSE
    LET sessionHigh == ReadBytes(openingIndexValue.rest, 4) IN IF ~sessionHigh.ok THEN Fail ELSE
    LET sessionLow == ReadBytes(sessionHigh.rest, 4) IN IF ~sessionLow.ok THEN Fail ELSE
    LET pctChgHighIndexValPrevSession == ReadBytes(sessionLow.rest, 4) IN IF ~pctChgHighIndexValPrevSession.ok THEN Fail ELSE
    LET pctChgLowIndexValPrevSession == ReadBytes(pctChgHighIndexValPrevSession.rest, 4) IN IF ~pctChgLowIndexValPrevSession.ok THEN Fail ELSE
    LET pctChangeIndexValPrevSession == ReadBytes(pctChgLowIndexValPrevSession.rest, 4) IN IF ~pctChangeIndexValPrevSession.ok THEN Fail ELSE
    LET pctChangeIndexValPrevYear == ReadBytes(pctChangeIndexValPrevSession.rest, 4) IN IF ~pctChangeIndexValPrevYear.ok THEN Fail ELSE
    LET capitalisationPortfolio == ReadBytes(pctChangeIndexValPrevYear.rest, 4) IN IF ~capitalisationPortfolio.ok THEN Fail ELSE
    LET indexAdjustmentCoefficient == ReadBytes(capitalisationPortfolio.rest, 4) IN IF ~indexAdjustmentCoefficient.ok THEN Fail ELSE
    LET sourceTimeMicroSecs == ReadBytes(indexAdjustmentCoefficient.rest, 2) IN IF ~sourceTimeMicroSecs.ok THEN Fail ELSE
    LET levelScaleCode == ReadBytes(sourceTimeMicroSecs.rest, 1) IN IF ~levelScaleCode.ok THEN Fail ELSE
    LET capitalisationScaleCode == ReadBytes(levelScaleCode.rest, 1) IN IF ~capitalisationScaleCode.ok THEN Fail ELSE
    LET indexAdjustmentScaleCode == ReadBytes(capitalisationScaleCode.rest, 1) IN IF ~indexAdjustmentScaleCode.ok THEN Fail ELSE
    LET timeClosing == ReadBytes(indexAdjustmentScaleCode.rest, 6) IN IF ~timeClosing.ok THEN Fail ELSE
    LET timeOpening == ReadBytes(timeClosing.rest, 6) IN IF ~timeOpening.ok THEN Fail ELSE
    LET timeFullOpening == ReadBytes(timeOpening.rest, 6) IN IF ~timeFullOpening.ok THEN Fail ELSE
    LET timeHigh == ReadBytes(timeFullOpening.rest, 6) IN IF ~timeHigh.ok THEN Fail ELSE
    LET timeLow == ReadBytes(timeHigh.rest, 6) IN IF ~timeLow.ok THEN Fail ELSE
    LET markerHigh == ReadBytes(timeLow.rest, 1) IN IF ~markerHigh.ok THEN Fail ELSE
    LET markerLow == ReadBytes(markerHigh.rest, 1) IN IF ~markerLow.ok THEN Fail ELSE
    LET markerClosingPrevSession == ReadBytes(markerLow.rest, 1) IN IF ~markerClosingPrevSession.ok THEN Fail ELSE
    LET markerClosingPrevYear == ReadBytes(markerClosingPrevSession.rest, 1) IN IF ~markerClosingPrevYear.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(markerClosingPrevYear.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ symbolIndex                   |-> symbolIndex.value,
         sourceTime                    |-> sourceTime.value,
         sourceSeqNum                  |-> sourceSeqNum.value,
         systemId                      |-> systemId.value,
         closingIndexValue             |-> closingIndexValue.value,
         indOpeningPortfolio           |-> indOpeningPortfolio.value,
         openingIndexValue             |-> openingIndexValue.value,
         sessionHigh                   |-> sessionHigh.value,
         sessionLow                    |-> sessionLow.value,
         pctChgHighIndexValPrevSession |-> pctChgHighIndexValPrevSession.value,
         pctChgLowIndexValPrevSession  |-> pctChgLowIndexValPrevSession.value,
         pctChangeIndexValPrevSession  |-> pctChangeIndexValPrevSession.value,
         pctChangeIndexValPrevYear     |-> pctChangeIndexValPrevYear.value,
         capitalisationPortfolio       |-> capitalisationPortfolio.value,
         indexAdjustmentCoefficient    |-> indexAdjustmentCoefficient.value,
         sourceTimeMicroSecs           |-> sourceTimeMicroSecs.value,
         levelScaleCode                |-> levelScaleCode.value,
         capitalisationScaleCode       |-> capitalisationScaleCode.value,
         indexAdjustmentScaleCode      |-> indexAdjustmentScaleCode.value,
         timeClosing                   |-> timeClosing.value,
         timeOpening                   |-> timeOpening.value,
         timeFullOpening               |-> timeFullOpening.value,
         timeHigh                      |-> timeHigh.value,
         timeLow                       |-> timeLow.value,
         markerHigh                    |-> markerHigh.value,
         markerLow                     |-> markerLow.value,
         markerClosingPrevSession      |-> markerClosingPrevSession.value,
         markerClosingPrevYear         |-> markerClosingPrevYear.value,
         reserved1                     |-> reserved1.value ], reserved1.rest)

ZeroIndexSummaryMessage ==
    [ symbolIndex                   |-> [i \in 1 .. 4 |-> 0],
      sourceTime                    |-> [i \in 1 .. 4 |-> 0],
      sourceSeqNum                  |-> [i \in 1 .. 4 |-> 0],
      systemId                      |-> [i \in 1 .. 4 |-> 0],
      closingIndexValue             |-> [i \in 1 .. 4 |-> 0],
      indOpeningPortfolio           |-> [i \in 1 .. 4 |-> 0],
      openingIndexValue             |-> [i \in 1 .. 4 |-> 0],
      sessionHigh                   |-> [i \in 1 .. 4 |-> 0],
      sessionLow                    |-> [i \in 1 .. 4 |-> 0],
      pctChgHighIndexValPrevSession |-> [i \in 1 .. 4 |-> 0],
      pctChgLowIndexValPrevSession  |-> [i \in 1 .. 4 |-> 0],
      pctChangeIndexValPrevSession  |-> [i \in 1 .. 4 |-> 0],
      pctChangeIndexValPrevYear     |-> [i \in 1 .. 4 |-> 0],
      capitalisationPortfolio       |-> [i \in 1 .. 4 |-> 0],
      indexAdjustmentCoefficient    |-> [i \in 1 .. 4 |-> 0],
      sourceTimeMicroSecs           |-> [i \in 1 .. 2 |-> 0],
      levelScaleCode                |-> [i \in 1 .. 1 |-> 0],
      capitalisationScaleCode       |-> [i \in 1 .. 1 |-> 0],
      indexAdjustmentScaleCode      |-> [i \in 1 .. 1 |-> 0],
      timeClosing                   |-> [i \in 1 .. 6 |-> 0],
      timeOpening                   |-> [i \in 1 .. 6 |-> 0],
      timeFullOpening               |-> [i \in 1 .. 6 |-> 0],
      timeHigh                      |-> [i \in 1 .. 6 |-> 0],
      timeLow                       |-> [i \in 1 .. 6 |-> 0],
      markerHigh                    |-> [i \in 1 .. 1 |-> 0],
      markerLow                     |-> [i \in 1 .. 1 |-> 0],
      markerClosingPrevSession      |-> [i \in 1 .. 1 |-> 0],
      markerClosingPrevYear         |-> [i \in 1 .. 1 |-> 0],
      reserved1                     |-> [i \in 1 .. 1 |-> 0] ]

(* Index Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedIndexSummaryMessage ==
    { ZeroIndexSummaryMessage }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.sourceSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.systemId = one] : one \in Sample(4) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.closingIndexValue = one] : one \in Sample(4) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.indOpeningPortfolio = one] : one \in Sample(4) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.openingIndexValue = one] : one \in Sample(4) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.sessionHigh = one] : one \in Sample(4) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.sessionLow = one] : one \in Sample(4) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.pctChgHighIndexValPrevSession = one] : one \in Sample(4) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.pctChgLowIndexValPrevSession = one] : one \in Sample(4) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.pctChangeIndexValPrevSession = one] : one \in Sample(4) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.pctChangeIndexValPrevYear = one] : one \in Sample(4) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.capitalisationPortfolio = one] : one \in Sample(4) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.indexAdjustmentCoefficient = one] : one \in Sample(4) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.sourceTimeMicroSecs = one] : one \in Sample(2) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.levelScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.capitalisationScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.indexAdjustmentScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.timeClosing = one] : one \in Sample(6) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.timeOpening = one] : one \in Sample(6) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.timeFullOpening = one] : one \in Sample(6) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.timeHigh = one] : one \in Sample(6) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.timeLow = one] : one \in Sample(6) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.markerHigh = one] : one \in Sample(1) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.markerLow = one] : one \in Sample(1) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.markerClosingPrevSession = one] : one \in Sample(1) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.markerClosingPrevYear = one] : one \in Sample(1) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Index Portfolio Component: 32 bytes                                     *)
(***************************************************************************)

IndexPortfolioComponent ==
    [ instrumentIsin       : Sample(12),
      instrumentAbbrevName : Sample(10),
      instrumentPacket     : Sample(10) ]

EncodeIndexPortfolioComponent(message) ==
    message.instrumentIsin
        \o message.instrumentAbbrevName
        \o message.instrumentPacket

DecodeIndexPortfolioComponent(bytes) ==
    LET instrumentIsin == ReadBytes(bytes, 12) IN IF ~instrumentIsin.ok THEN Fail ELSE
    LET instrumentAbbrevName == ReadBytes(instrumentIsin.rest, 10) IN IF ~instrumentAbbrevName.ok THEN Fail ELSE
    LET instrumentPacket == ReadBytes(instrumentAbbrevName.rest, 10) IN IF ~instrumentPacket.ok THEN Fail ELSE
    Ok([ instrumentIsin       |-> instrumentIsin.value,
         instrumentAbbrevName |-> instrumentAbbrevName.value,
         instrumentPacket     |-> instrumentPacket.value ], instrumentPacket.rest)

ZeroIndexPortfolioComponent ==
    [ instrumentIsin       |-> [i \in 1 .. 12 |-> 0],
      instrumentAbbrevName |-> [i \in 1 .. 10 |-> 0],
      instrumentPacket     |-> [i \in 1 .. 10 |-> 0] ]

(* Index Portfolio Component at zero, then each field in turn at the values it is checked at *)
CheckedIndexPortfolioComponent ==
    { ZeroIndexPortfolioComponent }
        \cup { [ZeroIndexPortfolioComponent EXCEPT !.instrumentIsin = one] : one \in Sample(12) }
        \cup { [ZeroIndexPortfolioComponent EXCEPT !.instrumentAbbrevName = one] : one \in Sample(10) }
        \cup { [ZeroIndexPortfolioComponent EXCEPT !.instrumentPacket = one] : one \in Sample(10) }

(* A run of Index Portfolio Component, written one after another *)
RECURSIVE EncodeIndexPortfolioComponentList(_)
EncodeIndexPortfolioComponentList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeIndexPortfolioComponent(Head(messages)) \o EncodeIndexPortfolioComponentList(Tail(messages))

(* As many Index Portfolio Component as the field that counts them says *)
RECURSIVE ReadIndexPortfolioComponentList(_, _)
ReadIndexPortfolioComponentList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeIndexPortfolioComponent(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadIndexPortfolioComponentList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Index Portfolio Component of each kind, for the lists that carry them *)
OneIndexPortfolioComponent == { ZeroIndexPortfolioComponent }

(* The 20 slots a run of Index Portfolio Component is written as, whatever the field beside it says are in use *)
SlotsIndexPortfolioComponent == { [i \in 1 .. 20 |-> one] : one \in OneIndexPortfolioComponent }

(***************************************************************************)
(* Index Portfolio Message                                                 *)
(***************************************************************************)

IndexPortfolioMessage ==
    [ symbolIndex                : Sample(4),
      sourceTime                 : Sample(4),
      sourceSeqNum               : Sample(4),
      systemId                   : Sample(4),
      indexAdjustmentCoefficient : Sample(4),
      levelCashPortfolio         : Sample(4),
      valueLastClosingIndex      : Sample(4),
      numberOfComponents         : Sample(2),
      sourceTimeMicroSecs        : Sample(2),
      indexAdjustmentScaleCode   : Sample(1),
      cashPortfolioScaleCode     : Sample(1),
      levelScaleCode             : Sample(1),
      indexPortfolioComponent    : SlotsIndexPortfolioComponent,
      dateValidity               : Sample(8),
      indexCurrency              : Sample(3),
      indexStatusIndicator       : Sample(2),
      indexPresSeq               : Sample(2),
      modeIndexDissemination     : Sample(1),
      productClassification      : Sample(1),
      openingCalcFormula         : Sample(1),
      reserved1                  : Sample(1),
      toiDissemination           : Sample(1),
      spreadDissemination        : Sample(1),
      tradingValuePublication    : Sample(1),
      messageContinuation        : Sample(1),
      reserved2                  : Sample(2) ]

EncodeIndexPortfolioMessage(message) ==
    message.symbolIndex
        \o message.sourceTime
        \o message.sourceSeqNum
        \o message.systemId
        \o message.indexAdjustmentCoefficient
        \o message.levelCashPortfolio
        \o message.valueLastClosingIndex
        \o message.numberOfComponents
        \o message.sourceTimeMicroSecs
        \o message.indexAdjustmentScaleCode
        \o message.cashPortfolioScaleCode
        \o message.levelScaleCode
        \o EncodeIndexPortfolioComponentList(message.indexPortfolioComponent)
        \o message.dateValidity
        \o message.indexCurrency
        \o message.indexStatusIndicator
        \o message.indexPresSeq
        \o message.modeIndexDissemination
        \o message.productClassification
        \o message.openingCalcFormula
        \o message.reserved1
        \o message.toiDissemination
        \o message.spreadDissemination
        \o message.tradingValuePublication
        \o message.messageContinuation
        \o message.reserved2

DecodeIndexPortfolioMessage(bytes) ==
    LET symbolIndex == ReadBytes(bytes, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET sourceTime == ReadBytes(symbolIndex.rest, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceSeqNum == ReadBytes(sourceTime.rest, 4) IN IF ~sourceSeqNum.ok THEN Fail ELSE
    LET systemId == ReadBytes(sourceSeqNum.rest, 4) IN IF ~systemId.ok THEN Fail ELSE
    LET indexAdjustmentCoefficient == ReadBytes(systemId.rest, 4) IN IF ~indexAdjustmentCoefficient.ok THEN Fail ELSE
    LET levelCashPortfolio == ReadBytes(indexAdjustmentCoefficient.rest, 4) IN IF ~levelCashPortfolio.ok THEN Fail ELSE
    LET valueLastClosingIndex == ReadBytes(levelCashPortfolio.rest, 4) IN IF ~valueLastClosingIndex.ok THEN Fail ELSE
    LET numberOfComponents == ReadBytes(valueLastClosingIndex.rest, 2) IN IF ~numberOfComponents.ok THEN Fail ELSE
    LET sourceTimeMicroSecs == ReadBytes(numberOfComponents.rest, 2) IN IF ~sourceTimeMicroSecs.ok THEN Fail ELSE
    LET indexAdjustmentScaleCode == ReadBytes(sourceTimeMicroSecs.rest, 1) IN IF ~indexAdjustmentScaleCode.ok THEN Fail ELSE
    LET cashPortfolioScaleCode == ReadBytes(indexAdjustmentScaleCode.rest, 1) IN IF ~cashPortfolioScaleCode.ok THEN Fail ELSE
    LET levelScaleCode == ReadBytes(cashPortfolioScaleCode.rest, 1) IN IF ~levelScaleCode.ok THEN Fail ELSE
    LET indexPortfolioComponent == ReadIndexPortfolioComponentList(levelScaleCode.rest, 20) IN IF ~indexPortfolioComponent.ok THEN Fail ELSE
    LET dateValidity == ReadBytes(indexPortfolioComponent.rest, 8) IN IF ~dateValidity.ok THEN Fail ELSE
    LET indexCurrency == ReadBytes(dateValidity.rest, 3) IN IF ~indexCurrency.ok THEN Fail ELSE
    LET indexStatusIndicator == ReadBytes(indexCurrency.rest, 2) IN IF ~indexStatusIndicator.ok THEN Fail ELSE
    LET indexPresSeq == ReadBytes(indexStatusIndicator.rest, 2) IN IF ~indexPresSeq.ok THEN Fail ELSE
    LET modeIndexDissemination == ReadBytes(indexPresSeq.rest, 1) IN IF ~modeIndexDissemination.ok THEN Fail ELSE
    LET productClassification == ReadBytes(modeIndexDissemination.rest, 1) IN IF ~productClassification.ok THEN Fail ELSE
    LET openingCalcFormula == ReadBytes(productClassification.rest, 1) IN IF ~openingCalcFormula.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(openingCalcFormula.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET toiDissemination == ReadBytes(reserved1.rest, 1) IN IF ~toiDissemination.ok THEN Fail ELSE
    LET spreadDissemination == ReadBytes(toiDissemination.rest, 1) IN IF ~spreadDissemination.ok THEN Fail ELSE
    LET tradingValuePublication == ReadBytes(spreadDissemination.rest, 1) IN IF ~tradingValuePublication.ok THEN Fail ELSE
    LET messageContinuation == ReadBytes(tradingValuePublication.rest, 1) IN IF ~messageContinuation.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(messageContinuation.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    Ok([ symbolIndex                |-> symbolIndex.value,
         sourceTime                 |-> sourceTime.value,
         sourceSeqNum               |-> sourceSeqNum.value,
         systemId                   |-> systemId.value,
         indexAdjustmentCoefficient |-> indexAdjustmentCoefficient.value,
         levelCashPortfolio         |-> levelCashPortfolio.value,
         valueLastClosingIndex      |-> valueLastClosingIndex.value,
         numberOfComponents         |-> numberOfComponents.value,
         sourceTimeMicroSecs        |-> sourceTimeMicroSecs.value,
         indexAdjustmentScaleCode   |-> indexAdjustmentScaleCode.value,
         cashPortfolioScaleCode     |-> cashPortfolioScaleCode.value,
         levelScaleCode             |-> levelScaleCode.value,
         indexPortfolioComponent    |-> indexPortfolioComponent.value,
         dateValidity               |-> dateValidity.value,
         indexCurrency              |-> indexCurrency.value,
         indexStatusIndicator       |-> indexStatusIndicator.value,
         indexPresSeq               |-> indexPresSeq.value,
         modeIndexDissemination     |-> modeIndexDissemination.value,
         productClassification      |-> productClassification.value,
         openingCalcFormula         |-> openingCalcFormula.value,
         reserved1                  |-> reserved1.value,
         toiDissemination           |-> toiDissemination.value,
         spreadDissemination        |-> spreadDissemination.value,
         tradingValuePublication    |-> tradingValuePublication.value,
         messageContinuation        |-> messageContinuation.value,
         reserved2                  |-> reserved2.value ], reserved2.rest)

ZeroIndexPortfolioMessage ==
    [ symbolIndex                |-> [i \in 1 .. 4 |-> 0],
      sourceTime                 |-> [i \in 1 .. 4 |-> 0],
      sourceSeqNum               |-> [i \in 1 .. 4 |-> 0],
      systemId                   |-> [i \in 1 .. 4 |-> 0],
      indexAdjustmentCoefficient |-> [i \in 1 .. 4 |-> 0],
      levelCashPortfolio         |-> [i \in 1 .. 4 |-> 0],
      valueLastClosingIndex      |-> [i \in 1 .. 4 |-> 0],
      numberOfComponents         |-> [i \in 1 .. 2 |-> 0],
      sourceTimeMicroSecs        |-> [i \in 1 .. 2 |-> 0],
      indexAdjustmentScaleCode   |-> [i \in 1 .. 1 |-> 0],
      cashPortfolioScaleCode     |-> [i \in 1 .. 1 |-> 0],
      levelScaleCode             |-> [i \in 1 .. 1 |-> 0],
      indexPortfolioComponent    |-> [i \in 1 .. 20 |-> ZeroIndexPortfolioComponent],
      dateValidity               |-> [i \in 1 .. 8 |-> 0],
      indexCurrency              |-> [i \in 1 .. 3 |-> 0],
      indexStatusIndicator       |-> [i \in 1 .. 2 |-> 0],
      indexPresSeq               |-> [i \in 1 .. 2 |-> 0],
      modeIndexDissemination     |-> [i \in 1 .. 1 |-> 0],
      productClassification      |-> [i \in 1 .. 1 |-> 0],
      openingCalcFormula         |-> [i \in 1 .. 1 |-> 0],
      reserved1                  |-> [i \in 1 .. 1 |-> 0],
      toiDissemination           |-> [i \in 1 .. 1 |-> 0],
      spreadDissemination        |-> [i \in 1 .. 1 |-> 0],
      tradingValuePublication    |-> [i \in 1 .. 1 |-> 0],
      messageContinuation        |-> [i \in 1 .. 1 |-> 0],
      reserved2                  |-> [i \in 1 .. 2 |-> 0] ]

(* Index Portfolio Message at zero, then each field in turn at the values it is checked at *)
CheckedIndexPortfolioMessage ==
    { ZeroIndexPortfolioMessage }
        \cup { [ZeroIndexPortfolioMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroIndexPortfolioMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroIndexPortfolioMessage EXCEPT !.sourceSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroIndexPortfolioMessage EXCEPT !.systemId = one] : one \in Sample(4) }
        \cup { [ZeroIndexPortfolioMessage EXCEPT !.indexAdjustmentCoefficient = one] : one \in Sample(4) }
        \cup { [ZeroIndexPortfolioMessage EXCEPT !.levelCashPortfolio = one] : one \in Sample(4) }
        \cup { [ZeroIndexPortfolioMessage EXCEPT !.valueLastClosingIndex = one] : one \in Sample(4) }
        \cup { [ZeroIndexPortfolioMessage EXCEPT !.numberOfComponents = one] : one \in Sample(2) }
        \cup { [ZeroIndexPortfolioMessage EXCEPT !.sourceTimeMicroSecs = one] : one \in Sample(2) }
        \cup { [ZeroIndexPortfolioMessage EXCEPT !.indexAdjustmentScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroIndexPortfolioMessage EXCEPT !.cashPortfolioScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroIndexPortfolioMessage EXCEPT !.levelScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroIndexPortfolioMessage EXCEPT !.indexPortfolioComponent = one] : one \in SlotsIndexPortfolioComponent }
        \cup { [ZeroIndexPortfolioMessage EXCEPT !.dateValidity = one] : one \in Sample(8) }
        \cup { [ZeroIndexPortfolioMessage EXCEPT !.indexCurrency = one] : one \in Sample(3) }
        \cup { [ZeroIndexPortfolioMessage EXCEPT !.indexStatusIndicator = one] : one \in Sample(2) }
        \cup { [ZeroIndexPortfolioMessage EXCEPT !.indexPresSeq = one] : one \in Sample(2) }
        \cup { [ZeroIndexPortfolioMessage EXCEPT !.modeIndexDissemination = one] : one \in Sample(1) }
        \cup { [ZeroIndexPortfolioMessage EXCEPT !.productClassification = one] : one \in Sample(1) }
        \cup { [ZeroIndexPortfolioMessage EXCEPT !.openingCalcFormula = one] : one \in Sample(1) }
        \cup { [ZeroIndexPortfolioMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroIndexPortfolioMessage EXCEPT !.toiDissemination = one] : one \in Sample(1) }
        \cup { [ZeroIndexPortfolioMessage EXCEPT !.spreadDissemination = one] : one \in Sample(1) }
        \cup { [ZeroIndexPortfolioMessage EXCEPT !.tradingValuePublication = one] : one \in Sample(1) }
        \cup { [ZeroIndexPortfolioMessage EXCEPT !.messageContinuation = one] : one \in Sample(1) }
        \cup { [ZeroIndexPortfolioMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

RealTimeIndexMessageCode == 546  \* 0x222
IndexSummaryMessageCode == 547  \* 0x223
IndexPortfolioMessageCode == 548  \* 0x224

Payload ==
    [ tag : {RealTimeIndexMessageCode}, body : RealTimeIndexMessage ]
        \cup [ tag : {IndexSummaryMessageCode}, body : IndexSummaryMessage ]
        \cup [ tag : {IndexPortfolioMessageCode}, body : IndexPortfolioMessage ]

EncodePayload(message) ==
    CASE message.tag = RealTimeIndexMessageCode -> EncodeRealTimeIndexMessage(message.body)
      [] message.tag = IndexSummaryMessageCode -> EncodeIndexSummaryMessage(message.body)
      [] message.tag = IndexPortfolioMessageCode -> EncodeIndexPortfolioMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = RealTimeIndexMessageCode -> DecodeRealTimeIndexMessage(bytes)
              [] tag = IndexSummaryMessageCode -> DecodeIndexSummaryMessage(bytes)
              [] tag = IndexPortfolioMessageCode -> DecodeIndexPortfolioMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> RealTimeIndexMessageCode, body |-> ZeroRealTimeIndexMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> RealTimeIndexMessageCode, body |-> one] : one \in CheckedRealTimeIndexMessage }
        \cup { [tag |-> IndexSummaryMessageCode, body |-> one] : one \in CheckedIndexSummaryMessage }
        \cup { [tag |-> IndexPortfolioMessageCode, body |-> one] : one \in CheckedIndexPortfolioMessage }

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
    { [ZeroMessage EXCEPT !.payload = [tag |-> RealTimeIndexMessageCode, body |-> ZeroRealTimeIndexMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> IndexSummaryMessageCode, body |-> ZeroIndexSummaryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> IndexPortfolioMessageCode, body |-> ZeroIndexPortfolioMessage]] }

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

(* Every Real Time Index Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRealTimeIndexMessage ==
    \A message \in CheckedRealTimeIndexMessage :
        LET read == DecodeRealTimeIndexMessage(EncodeRealTimeIndexMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Index Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIndexSummaryMessage ==
    \A message \in CheckedIndexSummaryMessage :
        LET read == DecodeIndexSummaryMessage(EncodeIndexSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Index Portfolio Component decodes back to what was encoded, and leaves nothing over *)
RoundTripIndexPortfolioComponent ==
    \A message \in CheckedIndexPortfolioComponent :
        LET read == DecodeIndexPortfolioComponent(EncodeIndexPortfolioComponent(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Index Portfolio Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIndexPortfolioMessage ==
    \A message \in CheckedIndexPortfolioMessage :
        LET read == DecodeIndexPortfolioMessage(EncodeIndexPortfolioMessage(message))
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
