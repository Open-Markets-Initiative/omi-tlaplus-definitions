-------------- MODULE Koscom_MdcsRealtime_Commodities_v2_018 ---------------
(***************************************************************************)
(* Koscom Co., Ltd. MDCS Realtime Commodities v2.018                       *)
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
(* Note: Packet fills its datagram with as many messages as the bytes      *)
(* hold, so it is read as a run of them.                                   *)
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

(* The integer a text protocol writes as the characters of itself: a count of one is *)
(* the character "1", which is the byte 49. Read by its digits, and written back *)
(* zero filled to the width the field states, which is how such a field is filled. *)
Digit == 48 .. 57

RECURSIVE DecodeDigits(_)
DecodeDigits(bytes) ==
    IF bytes = << >>
    THEN 0
    ELSE DecodeDigits(SubSeq(bytes, 1, Len(bytes) - 1)) * 10 + (bytes[Len(bytes)] - 48)

RECURSIVE EncodeDigits(_, _)
EncodeDigits(value, width) ==
    IF width = 0
    THEN << >>
    ELSE EncodeDigits(value \div 10, width - 1) \o <<48 + (value % 10)>>

(* A field written as digits that holds anything else is no number, so it is not read: *)
(* the value would not be what the bytes say, and would not write back as them. *)
ReadDigits(bytes, width) ==
    IF Len(bytes) < width \/ \E i \in 1 .. width : bytes[i] \notin Digit
    THEN Fail
    ELSE Ok(DecodeDigits(SubSeq(bytes, 1, width)), SubSeq(bytes, width + 1, Len(bytes)))

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
(* Polling Data Message: 5 bytes                                           *)
(***************************************************************************)

PollingDataMessage ==
    [ currentTime : Sample(4),
      endKeyword  : Sample(1) ]

EncodePollingDataMessage(message) ==
    message.currentTime
        \o message.endKeyword

DecodePollingDataMessage(bytes) ==
    LET currentTime == ReadBytes(bytes, 4) IN IF ~currentTime.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(currentTime.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ currentTime |-> currentTime.value,
         endKeyword  |-> endKeyword.value ], endKeyword.rest)

ZeroPollingDataMessage ==
    [ currentTime |-> [i \in 1 .. 4 |-> 0],
      endKeyword  |-> [i \in 1 .. 1 |-> 0] ]

(* Polling Data Message at zero, then each field in turn at the values it is checked at *)
CheckedPollingDataMessage ==
    { ZeroPollingDataMessage }
        \cup { [ZeroPollingDataMessage EXCEPT !.currentTime = one] : one \in Sample(4) }
        \cup { [ZeroPollingDataMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Krx Index Message: 72 bytes                                             *)
(***************************************************************************)

KrxIndexMessage ==
    [ indexId                              : Sample(6),
      isinCode                             : Sample(12),
      calculationTime                      : Sample(6),
      index                                : Sample(9),
      indexChangeSignAgainstThePreviousDay : Sample(1),
      indexChangeAgainstThePreviousDay     : Sample(9),
      accumulatedTradingVolume             : Sample(12),
      accumulatedTradingValueShort         : Sample(12),
      filler4                              : Sample(4),
      endKeyword                           : Sample(1) ]

EncodeKrxIndexMessage(message) ==
    message.indexId
        \o message.isinCode
        \o message.calculationTime
        \o message.index
        \o message.indexChangeSignAgainstThePreviousDay
        \o message.indexChangeAgainstThePreviousDay
        \o message.accumulatedTradingVolume
        \o message.accumulatedTradingValueShort
        \o message.filler4
        \o message.endKeyword

DecodeKrxIndexMessage(bytes) ==
    LET indexId == ReadBytes(bytes, 6) IN IF ~indexId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(indexId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET calculationTime == ReadBytes(isinCode.rest, 6) IN IF ~calculationTime.ok THEN Fail ELSE
    LET index == ReadBytes(calculationTime.rest, 9) IN IF ~index.ok THEN Fail ELSE
    LET indexChangeSignAgainstThePreviousDay == ReadBytes(index.rest, 1) IN IF ~indexChangeSignAgainstThePreviousDay.ok THEN Fail ELSE
    LET indexChangeAgainstThePreviousDay == ReadBytes(indexChangeSignAgainstThePreviousDay.rest, 9) IN IF ~indexChangeAgainstThePreviousDay.ok THEN Fail ELSE
    LET accumulatedTradingVolume == ReadBytes(indexChangeAgainstThePreviousDay.rest, 12) IN IF ~accumulatedTradingVolume.ok THEN Fail ELSE
    LET accumulatedTradingValueShort == ReadBytes(accumulatedTradingVolume.rest, 12) IN IF ~accumulatedTradingValueShort.ok THEN Fail ELSE
    LET filler4 == ReadBytes(accumulatedTradingValueShort.rest, 4) IN IF ~filler4.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler4.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ indexId                              |-> indexId.value,
         isinCode                             |-> isinCode.value,
         calculationTime                      |-> calculationTime.value,
         index                                |-> index.value,
         indexChangeSignAgainstThePreviousDay |-> indexChangeSignAgainstThePreviousDay.value,
         indexChangeAgainstThePreviousDay     |-> indexChangeAgainstThePreviousDay.value,
         accumulatedTradingVolume             |-> accumulatedTradingVolume.value,
         accumulatedTradingValueShort         |-> accumulatedTradingValueShort.value,
         filler4                              |-> filler4.value,
         endKeyword                           |-> endKeyword.value ], endKeyword.rest)

ZeroKrxIndexMessage ==
    [ indexId                              |-> [i \in 1 .. 6 |-> 0],
      isinCode                             |-> [i \in 1 .. 12 |-> 0],
      calculationTime                      |-> [i \in 1 .. 6 |-> 0],
      index                                |-> [i \in 1 .. 9 |-> 0],
      indexChangeSignAgainstThePreviousDay |-> [i \in 1 .. 1 |-> 0],
      indexChangeAgainstThePreviousDay     |-> [i \in 1 .. 9 |-> 0],
      accumulatedTradingVolume             |-> [i \in 1 .. 12 |-> 0],
      accumulatedTradingValueShort         |-> [i \in 1 .. 12 |-> 0],
      filler4                              |-> [i \in 1 .. 4 |-> 0],
      endKeyword                           |-> [i \in 1 .. 1 |-> 0] ]

(* Krx Index Message at zero, then each field in turn at the values it is checked at *)
CheckedKrxIndexMessage ==
    { ZeroKrxIndexMessage }
        \cup { [ZeroKrxIndexMessage EXCEPT !.indexId = one] : one \in Sample(6) }
        \cup { [ZeroKrxIndexMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroKrxIndexMessage EXCEPT !.calculationTime = one] : one \in Sample(6) }
        \cup { [ZeroKrxIndexMessage EXCEPT !.index = one] : one \in Sample(9) }
        \cup { [ZeroKrxIndexMessage EXCEPT !.indexChangeSignAgainstThePreviousDay = one] : one \in Sample(1) }
        \cup { [ZeroKrxIndexMessage EXCEPT !.indexChangeAgainstThePreviousDay = one] : one \in Sample(9) }
        \cup { [ZeroKrxIndexMessage EXCEPT !.accumulatedTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroKrxIndexMessage EXCEPT !.accumulatedTradingValueShort = one] : one \in Sample(12) }
        \cup { [ZeroKrxIndexMessage EXCEPT !.filler4 = one] : one \in Sample(4) }
        \cup { [ZeroKrxIndexMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Krx Estimated Index Message: 72 bytes                                   *)
(***************************************************************************)

KrxEstimatedIndexMessage ==
    [ indexId                              : Sample(6),
      isinCode                             : Sample(12),
      calculationTime                      : Sample(6),
      index                                : Sample(9),
      indexChangeSignAgainstThePreviousDay : Sample(1),
      indexChangeAgainstThePreviousDay     : Sample(9),
      accumulatedTradingVolume             : Sample(12),
      accumulatedTradingValueShort         : Sample(12),
      filler4                              : Sample(4),
      endKeyword                           : Sample(1) ]

EncodeKrxEstimatedIndexMessage(message) ==
    message.indexId
        \o message.isinCode
        \o message.calculationTime
        \o message.index
        \o message.indexChangeSignAgainstThePreviousDay
        \o message.indexChangeAgainstThePreviousDay
        \o message.accumulatedTradingVolume
        \o message.accumulatedTradingValueShort
        \o message.filler4
        \o message.endKeyword

DecodeKrxEstimatedIndexMessage(bytes) ==
    LET indexId == ReadBytes(bytes, 6) IN IF ~indexId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(indexId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET calculationTime == ReadBytes(isinCode.rest, 6) IN IF ~calculationTime.ok THEN Fail ELSE
    LET index == ReadBytes(calculationTime.rest, 9) IN IF ~index.ok THEN Fail ELSE
    LET indexChangeSignAgainstThePreviousDay == ReadBytes(index.rest, 1) IN IF ~indexChangeSignAgainstThePreviousDay.ok THEN Fail ELSE
    LET indexChangeAgainstThePreviousDay == ReadBytes(indexChangeSignAgainstThePreviousDay.rest, 9) IN IF ~indexChangeAgainstThePreviousDay.ok THEN Fail ELSE
    LET accumulatedTradingVolume == ReadBytes(indexChangeAgainstThePreviousDay.rest, 12) IN IF ~accumulatedTradingVolume.ok THEN Fail ELSE
    LET accumulatedTradingValueShort == ReadBytes(accumulatedTradingVolume.rest, 12) IN IF ~accumulatedTradingValueShort.ok THEN Fail ELSE
    LET filler4 == ReadBytes(accumulatedTradingValueShort.rest, 4) IN IF ~filler4.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler4.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ indexId                              |-> indexId.value,
         isinCode                             |-> isinCode.value,
         calculationTime                      |-> calculationTime.value,
         index                                |-> index.value,
         indexChangeSignAgainstThePreviousDay |-> indexChangeSignAgainstThePreviousDay.value,
         indexChangeAgainstThePreviousDay     |-> indexChangeAgainstThePreviousDay.value,
         accumulatedTradingVolume             |-> accumulatedTradingVolume.value,
         accumulatedTradingValueShort         |-> accumulatedTradingValueShort.value,
         filler4                              |-> filler4.value,
         endKeyword                           |-> endKeyword.value ], endKeyword.rest)

ZeroKrxEstimatedIndexMessage ==
    [ indexId                              |-> [i \in 1 .. 6 |-> 0],
      isinCode                             |-> [i \in 1 .. 12 |-> 0],
      calculationTime                      |-> [i \in 1 .. 6 |-> 0],
      index                                |-> [i \in 1 .. 9 |-> 0],
      indexChangeSignAgainstThePreviousDay |-> [i \in 1 .. 1 |-> 0],
      indexChangeAgainstThePreviousDay     |-> [i \in 1 .. 9 |-> 0],
      accumulatedTradingVolume             |-> [i \in 1 .. 12 |-> 0],
      accumulatedTradingValueShort         |-> [i \in 1 .. 12 |-> 0],
      filler4                              |-> [i \in 1 .. 4 |-> 0],
      endKeyword                           |-> [i \in 1 .. 1 |-> 0] ]

(* Krx Estimated Index Message at zero, then each field in turn at the values it is checked at *)
CheckedKrxEstimatedIndexMessage ==
    { ZeroKrxEstimatedIndexMessage }
        \cup { [ZeroKrxEstimatedIndexMessage EXCEPT !.indexId = one] : one \in Sample(6) }
        \cup { [ZeroKrxEstimatedIndexMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroKrxEstimatedIndexMessage EXCEPT !.calculationTime = one] : one \in Sample(6) }
        \cup { [ZeroKrxEstimatedIndexMessage EXCEPT !.index = one] : one \in Sample(9) }
        \cup { [ZeroKrxEstimatedIndexMessage EXCEPT !.indexChangeSignAgainstThePreviousDay = one] : one \in Sample(1) }
        \cup { [ZeroKrxEstimatedIndexMessage EXCEPT !.indexChangeAgainstThePreviousDay = one] : one \in Sample(9) }
        \cup { [ZeroKrxEstimatedIndexMessage EXCEPT !.accumulatedTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroKrxEstimatedIndexMessage EXCEPT !.accumulatedTradingValueShort = one] : one \in Sample(12) }
        \cup { [ZeroKrxEstimatedIndexMessage EXCEPT !.filler4 = one] : one \in Sample(4) }
        \cup { [ZeroKrxEstimatedIndexMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Global Index Message: 59 bytes                                          *)
(***************************************************************************)

GlobalIndexMessage ==
    [ indexId                              : Sample(6),
      isinCode                             : Sample(12),
      businessDate                         : Sample(8),
      calculationTime                      : Sample(6),
      index                                : Sample(9),
      indexChangeSignAgainstThePreviousDay : Sample(1),
      indexChangeAgainstThePreviousDay     : Sample(9),
      currencyCodeShort                    : Sample(3),
      filler4                              : Sample(4),
      endKeyword                           : Sample(1) ]

EncodeGlobalIndexMessage(message) ==
    message.indexId
        \o message.isinCode
        \o message.businessDate
        \o message.calculationTime
        \o message.index
        \o message.indexChangeSignAgainstThePreviousDay
        \o message.indexChangeAgainstThePreviousDay
        \o message.currencyCodeShort
        \o message.filler4
        \o message.endKeyword

DecodeGlobalIndexMessage(bytes) ==
    LET indexId == ReadBytes(bytes, 6) IN IF ~indexId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(indexId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET businessDate == ReadBytes(isinCode.rest, 8) IN IF ~businessDate.ok THEN Fail ELSE
    LET calculationTime == ReadBytes(businessDate.rest, 6) IN IF ~calculationTime.ok THEN Fail ELSE
    LET index == ReadBytes(calculationTime.rest, 9) IN IF ~index.ok THEN Fail ELSE
    LET indexChangeSignAgainstThePreviousDay == ReadBytes(index.rest, 1) IN IF ~indexChangeSignAgainstThePreviousDay.ok THEN Fail ELSE
    LET indexChangeAgainstThePreviousDay == ReadBytes(indexChangeSignAgainstThePreviousDay.rest, 9) IN IF ~indexChangeAgainstThePreviousDay.ok THEN Fail ELSE
    LET currencyCodeShort == ReadBytes(indexChangeAgainstThePreviousDay.rest, 3) IN IF ~currencyCodeShort.ok THEN Fail ELSE
    LET filler4 == ReadBytes(currencyCodeShort.rest, 4) IN IF ~filler4.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler4.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ indexId                              |-> indexId.value,
         isinCode                             |-> isinCode.value,
         businessDate                         |-> businessDate.value,
         calculationTime                      |-> calculationTime.value,
         index                                |-> index.value,
         indexChangeSignAgainstThePreviousDay |-> indexChangeSignAgainstThePreviousDay.value,
         indexChangeAgainstThePreviousDay     |-> indexChangeAgainstThePreviousDay.value,
         currencyCodeShort                    |-> currencyCodeShort.value,
         filler4                              |-> filler4.value,
         endKeyword                           |-> endKeyword.value ], endKeyword.rest)

ZeroGlobalIndexMessage ==
    [ indexId                              |-> [i \in 1 .. 6 |-> 0],
      isinCode                             |-> [i \in 1 .. 12 |-> 0],
      businessDate                         |-> [i \in 1 .. 8 |-> 0],
      calculationTime                      |-> [i \in 1 .. 6 |-> 0],
      index                                |-> [i \in 1 .. 9 |-> 0],
      indexChangeSignAgainstThePreviousDay |-> [i \in 1 .. 1 |-> 0],
      indexChangeAgainstThePreviousDay     |-> [i \in 1 .. 9 |-> 0],
      currencyCodeShort                    |-> [i \in 1 .. 3 |-> 0],
      filler4                              |-> [i \in 1 .. 4 |-> 0],
      endKeyword                           |-> [i \in 1 .. 1 |-> 0] ]

(* Global Index Message at zero, then each field in turn at the values it is checked at *)
CheckedGlobalIndexMessage ==
    { ZeroGlobalIndexMessage }
        \cup { [ZeroGlobalIndexMessage EXCEPT !.indexId = one] : one \in Sample(6) }
        \cup { [ZeroGlobalIndexMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroGlobalIndexMessage EXCEPT !.businessDate = one] : one \in Sample(8) }
        \cup { [ZeroGlobalIndexMessage EXCEPT !.calculationTime = one] : one \in Sample(6) }
        \cup { [ZeroGlobalIndexMessage EXCEPT !.index = one] : one \in Sample(9) }
        \cup { [ZeroGlobalIndexMessage EXCEPT !.indexChangeSignAgainstThePreviousDay = one] : one \in Sample(1) }
        \cup { [ZeroGlobalIndexMessage EXCEPT !.indexChangeAgainstThePreviousDay = one] : one \in Sample(9) }
        \cup { [ZeroGlobalIndexMessage EXCEPT !.currencyCodeShort = one] : one \in Sample(3) }
        \cup { [ZeroGlobalIndexMessage EXCEPT !.filler4 = one] : one \in Sample(4) }
        \cup { [ZeroGlobalIndexMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Bond Prime Index Message: 177 bytes                                     *)
(***************************************************************************)

BondPrimeIndexMessage ==
    [ calculatingDate                                : Sample(8),
      calculatingTime                                : Sample(8),
      groupCode                                      : Sample(5),
      maturityCode                                   : Sample(3),
      cleanPriceIndexKrx                             : Sample(16),
      totalEarningsIndex                             : Sample(16),
      cleanPriceIndexWeight                          : Sample(16),
      totalEarningsIndexWeight                       : Sample(16),
      weightOfCleanIndexValueForIntegrityIndexWeight : Sample(16),
      weightOfSumIndexValueForIntegrityIndexWeight   : Sample(16),
      averageDuration                                : Sample(16),
      averageConvexity                               : Sample(16),
      averageYld                                     : Sample(16),
      transmissionTime                               : Sample(8),
      endKeyword                                     : Sample(1) ]

EncodeBondPrimeIndexMessage(message) ==
    message.calculatingDate
        \o message.calculatingTime
        \o message.groupCode
        \o message.maturityCode
        \o message.cleanPriceIndexKrx
        \o message.totalEarningsIndex
        \o message.cleanPriceIndexWeight
        \o message.totalEarningsIndexWeight
        \o message.weightOfCleanIndexValueForIntegrityIndexWeight
        \o message.weightOfSumIndexValueForIntegrityIndexWeight
        \o message.averageDuration
        \o message.averageConvexity
        \o message.averageYld
        \o message.transmissionTime
        \o message.endKeyword

DecodeBondPrimeIndexMessage(bytes) ==
    LET calculatingDate == ReadBytes(bytes, 8) IN IF ~calculatingDate.ok THEN Fail ELSE
    LET calculatingTime == ReadBytes(calculatingDate.rest, 8) IN IF ~calculatingTime.ok THEN Fail ELSE
    LET groupCode == ReadBytes(calculatingTime.rest, 5) IN IF ~groupCode.ok THEN Fail ELSE
    LET maturityCode == ReadBytes(groupCode.rest, 3) IN IF ~maturityCode.ok THEN Fail ELSE
    LET cleanPriceIndexKrx == ReadBytes(maturityCode.rest, 16) IN IF ~cleanPriceIndexKrx.ok THEN Fail ELSE
    LET totalEarningsIndex == ReadBytes(cleanPriceIndexKrx.rest, 16) IN IF ~totalEarningsIndex.ok THEN Fail ELSE
    LET cleanPriceIndexWeight == ReadBytes(totalEarningsIndex.rest, 16) IN IF ~cleanPriceIndexWeight.ok THEN Fail ELSE
    LET totalEarningsIndexWeight == ReadBytes(cleanPriceIndexWeight.rest, 16) IN IF ~totalEarningsIndexWeight.ok THEN Fail ELSE
    LET weightOfCleanIndexValueForIntegrityIndexWeight == ReadBytes(totalEarningsIndexWeight.rest, 16) IN IF ~weightOfCleanIndexValueForIntegrityIndexWeight.ok THEN Fail ELSE
    LET weightOfSumIndexValueForIntegrityIndexWeight == ReadBytes(weightOfCleanIndexValueForIntegrityIndexWeight.rest, 16) IN IF ~weightOfSumIndexValueForIntegrityIndexWeight.ok THEN Fail ELSE
    LET averageDuration == ReadBytes(weightOfSumIndexValueForIntegrityIndexWeight.rest, 16) IN IF ~averageDuration.ok THEN Fail ELSE
    LET averageConvexity == ReadBytes(averageDuration.rest, 16) IN IF ~averageConvexity.ok THEN Fail ELSE
    LET averageYld == ReadBytes(averageConvexity.rest, 16) IN IF ~averageYld.ok THEN Fail ELSE
    LET transmissionTime == ReadBytes(averageYld.rest, 8) IN IF ~transmissionTime.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(transmissionTime.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ calculatingDate                                |-> calculatingDate.value,
         calculatingTime                                |-> calculatingTime.value,
         groupCode                                      |-> groupCode.value,
         maturityCode                                   |-> maturityCode.value,
         cleanPriceIndexKrx                             |-> cleanPriceIndexKrx.value,
         totalEarningsIndex                             |-> totalEarningsIndex.value,
         cleanPriceIndexWeight                          |-> cleanPriceIndexWeight.value,
         totalEarningsIndexWeight                       |-> totalEarningsIndexWeight.value,
         weightOfCleanIndexValueForIntegrityIndexWeight |-> weightOfCleanIndexValueForIntegrityIndexWeight.value,
         weightOfSumIndexValueForIntegrityIndexWeight   |-> weightOfSumIndexValueForIntegrityIndexWeight.value,
         averageDuration                                |-> averageDuration.value,
         averageConvexity                               |-> averageConvexity.value,
         averageYld                                     |-> averageYld.value,
         transmissionTime                               |-> transmissionTime.value,
         endKeyword                                     |-> endKeyword.value ], endKeyword.rest)

ZeroBondPrimeIndexMessage ==
    [ calculatingDate                                |-> [i \in 1 .. 8 |-> 0],
      calculatingTime                                |-> [i \in 1 .. 8 |-> 0],
      groupCode                                      |-> [i \in 1 .. 5 |-> 0],
      maturityCode                                   |-> [i \in 1 .. 3 |-> 0],
      cleanPriceIndexKrx                             |-> [i \in 1 .. 16 |-> 0],
      totalEarningsIndex                             |-> [i \in 1 .. 16 |-> 0],
      cleanPriceIndexWeight                          |-> [i \in 1 .. 16 |-> 0],
      totalEarningsIndexWeight                       |-> [i \in 1 .. 16 |-> 0],
      weightOfCleanIndexValueForIntegrityIndexWeight |-> [i \in 1 .. 16 |-> 0],
      weightOfSumIndexValueForIntegrityIndexWeight   |-> [i \in 1 .. 16 |-> 0],
      averageDuration                                |-> [i \in 1 .. 16 |-> 0],
      averageConvexity                               |-> [i \in 1 .. 16 |-> 0],
      averageYld                                     |-> [i \in 1 .. 16 |-> 0],
      transmissionTime                               |-> [i \in 1 .. 8 |-> 0],
      endKeyword                                     |-> [i \in 1 .. 1 |-> 0] ]

(* Bond Prime Index Message at zero, then each field in turn at the values it is checked at *)
CheckedBondPrimeIndexMessage ==
    { ZeroBondPrimeIndexMessage }
        \cup { [ZeroBondPrimeIndexMessage EXCEPT !.calculatingDate = one] : one \in Sample(8) }
        \cup { [ZeroBondPrimeIndexMessage EXCEPT !.calculatingTime = one] : one \in Sample(8) }
        \cup { [ZeroBondPrimeIndexMessage EXCEPT !.groupCode = one] : one \in Sample(5) }
        \cup { [ZeroBondPrimeIndexMessage EXCEPT !.maturityCode = one] : one \in Sample(3) }
        \cup { [ZeroBondPrimeIndexMessage EXCEPT !.cleanPriceIndexKrx = one] : one \in Sample(16) }
        \cup { [ZeroBondPrimeIndexMessage EXCEPT !.totalEarningsIndex = one] : one \in Sample(16) }
        \cup { [ZeroBondPrimeIndexMessage EXCEPT !.cleanPriceIndexWeight = one] : one \in Sample(16) }
        \cup { [ZeroBondPrimeIndexMessage EXCEPT !.totalEarningsIndexWeight = one] : one \in Sample(16) }
        \cup { [ZeroBondPrimeIndexMessage EXCEPT !.weightOfCleanIndexValueForIntegrityIndexWeight = one] : one \in Sample(16) }
        \cup { [ZeroBondPrimeIndexMessage EXCEPT !.weightOfSumIndexValueForIntegrityIndexWeight = one] : one \in Sample(16) }
        \cup { [ZeroBondPrimeIndexMessage EXCEPT !.averageDuration = one] : one \in Sample(16) }
        \cup { [ZeroBondPrimeIndexMessage EXCEPT !.averageConvexity = one] : one \in Sample(16) }
        \cup { [ZeroBondPrimeIndexMessage EXCEPT !.averageYld = one] : one \in Sample(16) }
        \cup { [ZeroBondPrimeIndexMessage EXCEPT !.transmissionTime = one] : one \in Sample(8) }
        \cup { [ZeroBondPrimeIndexMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Bond Ktb Index Message: 114 bytes                                       *)
(***************************************************************************)

BondKtbIndexMessage ==
    [ bondIndexId              : Sample(6),
      baseDate                 : Sample(8),
      baseTime                 : Sample(6),
      totalProfitIndex         : Sample(11),
      cleanPriceIndexKtb       : Sample(11),
      marketPriceIndexKtb      : Sample(11),
      callReinvestmentIndexKtb : Sample(11),
      zeroReinvestmentIndexKtb : Sample(11),
      futuresBasisPrice        : Sample(10),
      duration                 : Sample(7),
      convexity                : Sample(7),
      averageYtm               : Sample(7),
      averageForwardYtm        : Sample(7),
      endKeyword               : Sample(1) ]

EncodeBondKtbIndexMessage(message) ==
    message.bondIndexId
        \o message.baseDate
        \o message.baseTime
        \o message.totalProfitIndex
        \o message.cleanPriceIndexKtb
        \o message.marketPriceIndexKtb
        \o message.callReinvestmentIndexKtb
        \o message.zeroReinvestmentIndexKtb
        \o message.futuresBasisPrice
        \o message.duration
        \o message.convexity
        \o message.averageYtm
        \o message.averageForwardYtm
        \o message.endKeyword

DecodeBondKtbIndexMessage(bytes) ==
    LET bondIndexId == ReadBytes(bytes, 6) IN IF ~bondIndexId.ok THEN Fail ELSE
    LET baseDate == ReadBytes(bondIndexId.rest, 8) IN IF ~baseDate.ok THEN Fail ELSE
    LET baseTime == ReadBytes(baseDate.rest, 6) IN IF ~baseTime.ok THEN Fail ELSE
    LET totalProfitIndex == ReadBytes(baseTime.rest, 11) IN IF ~totalProfitIndex.ok THEN Fail ELSE
    LET cleanPriceIndexKtb == ReadBytes(totalProfitIndex.rest, 11) IN IF ~cleanPriceIndexKtb.ok THEN Fail ELSE
    LET marketPriceIndexKtb == ReadBytes(cleanPriceIndexKtb.rest, 11) IN IF ~marketPriceIndexKtb.ok THEN Fail ELSE
    LET callReinvestmentIndexKtb == ReadBytes(marketPriceIndexKtb.rest, 11) IN IF ~callReinvestmentIndexKtb.ok THEN Fail ELSE
    LET zeroReinvestmentIndexKtb == ReadBytes(callReinvestmentIndexKtb.rest, 11) IN IF ~zeroReinvestmentIndexKtb.ok THEN Fail ELSE
    LET futuresBasisPrice == ReadBytes(zeroReinvestmentIndexKtb.rest, 10) IN IF ~futuresBasisPrice.ok THEN Fail ELSE
    LET duration == ReadBytes(futuresBasisPrice.rest, 7) IN IF ~duration.ok THEN Fail ELSE
    LET convexity == ReadBytes(duration.rest, 7) IN IF ~convexity.ok THEN Fail ELSE
    LET averageYtm == ReadBytes(convexity.rest, 7) IN IF ~averageYtm.ok THEN Fail ELSE
    LET averageForwardYtm == ReadBytes(averageYtm.rest, 7) IN IF ~averageForwardYtm.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(averageForwardYtm.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ bondIndexId              |-> bondIndexId.value,
         baseDate                 |-> baseDate.value,
         baseTime                 |-> baseTime.value,
         totalProfitIndex         |-> totalProfitIndex.value,
         cleanPriceIndexKtb       |-> cleanPriceIndexKtb.value,
         marketPriceIndexKtb      |-> marketPriceIndexKtb.value,
         callReinvestmentIndexKtb |-> callReinvestmentIndexKtb.value,
         zeroReinvestmentIndexKtb |-> zeroReinvestmentIndexKtb.value,
         futuresBasisPrice        |-> futuresBasisPrice.value,
         duration                 |-> duration.value,
         convexity                |-> convexity.value,
         averageYtm               |-> averageYtm.value,
         averageForwardYtm        |-> averageForwardYtm.value,
         endKeyword               |-> endKeyword.value ], endKeyword.rest)

ZeroBondKtbIndexMessage ==
    [ bondIndexId              |-> [i \in 1 .. 6 |-> 0],
      baseDate                 |-> [i \in 1 .. 8 |-> 0],
      baseTime                 |-> [i \in 1 .. 6 |-> 0],
      totalProfitIndex         |-> [i \in 1 .. 11 |-> 0],
      cleanPriceIndexKtb       |-> [i \in 1 .. 11 |-> 0],
      marketPriceIndexKtb      |-> [i \in 1 .. 11 |-> 0],
      callReinvestmentIndexKtb |-> [i \in 1 .. 11 |-> 0],
      zeroReinvestmentIndexKtb |-> [i \in 1 .. 11 |-> 0],
      futuresBasisPrice        |-> [i \in 1 .. 10 |-> 0],
      duration                 |-> [i \in 1 .. 7 |-> 0],
      convexity                |-> [i \in 1 .. 7 |-> 0],
      averageYtm               |-> [i \in 1 .. 7 |-> 0],
      averageForwardYtm        |-> [i \in 1 .. 7 |-> 0],
      endKeyword               |-> [i \in 1 .. 1 |-> 0] ]

(* Bond Ktb Index Message at zero, then each field in turn at the values it is checked at *)
CheckedBondKtbIndexMessage ==
    { ZeroBondKtbIndexMessage }
        \cup { [ZeroBondKtbIndexMessage EXCEPT !.bondIndexId = one] : one \in Sample(6) }
        \cup { [ZeroBondKtbIndexMessage EXCEPT !.baseDate = one] : one \in Sample(8) }
        \cup { [ZeroBondKtbIndexMessage EXCEPT !.baseTime = one] : one \in Sample(6) }
        \cup { [ZeroBondKtbIndexMessage EXCEPT !.totalProfitIndex = one] : one \in Sample(11) }
        \cup { [ZeroBondKtbIndexMessage EXCEPT !.cleanPriceIndexKtb = one] : one \in Sample(11) }
        \cup { [ZeroBondKtbIndexMessage EXCEPT !.marketPriceIndexKtb = one] : one \in Sample(11) }
        \cup { [ZeroBondKtbIndexMessage EXCEPT !.callReinvestmentIndexKtb = one] : one \in Sample(11) }
        \cup { [ZeroBondKtbIndexMessage EXCEPT !.zeroReinvestmentIndexKtb = one] : one \in Sample(11) }
        \cup { [ZeroBondKtbIndexMessage EXCEPT !.futuresBasisPrice = one] : one \in Sample(10) }
        \cup { [ZeroBondKtbIndexMessage EXCEPT !.duration = one] : one \in Sample(7) }
        \cup { [ZeroBondKtbIndexMessage EXCEPT !.convexity = one] : one \in Sample(7) }
        \cup { [ZeroBondKtbIndexMessage EXCEPT !.averageYtm = one] : one \in Sample(7) }
        \cup { [ZeroBondKtbIndexMessage EXCEPT !.averageForwardYtm = one] : one \in Sample(7) }
        \cup { [ZeroBondKtbIndexMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Bond Ktb Index Term Structure Message: 61 bytes                         *)
(***************************************************************************)

BondKtbIndexTermStructureMessage ==
    [ bondIndexId      : Sample(6),
      baseDate         : Sample(8),
      baseTime         : Sample(6),
      isinCode         : Sample(12),
      basisPrice       : Sample(10),
      cleanPrice       : Sample(10),
      averageYtm       : Sample(7),
      indexConstituent : Sample(1),
      endKeyword       : Sample(1) ]

EncodeBondKtbIndexTermStructureMessage(message) ==
    message.bondIndexId
        \o message.baseDate
        \o message.baseTime
        \o message.isinCode
        \o message.basisPrice
        \o message.cleanPrice
        \o message.averageYtm
        \o message.indexConstituent
        \o message.endKeyword

DecodeBondKtbIndexTermStructureMessage(bytes) ==
    LET bondIndexId == ReadBytes(bytes, 6) IN IF ~bondIndexId.ok THEN Fail ELSE
    LET baseDate == ReadBytes(bondIndexId.rest, 8) IN IF ~baseDate.ok THEN Fail ELSE
    LET baseTime == ReadBytes(baseDate.rest, 6) IN IF ~baseTime.ok THEN Fail ELSE
    LET isinCode == ReadBytes(baseTime.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET basisPrice == ReadBytes(isinCode.rest, 10) IN IF ~basisPrice.ok THEN Fail ELSE
    LET cleanPrice == ReadBytes(basisPrice.rest, 10) IN IF ~cleanPrice.ok THEN Fail ELSE
    LET averageYtm == ReadBytes(cleanPrice.rest, 7) IN IF ~averageYtm.ok THEN Fail ELSE
    LET indexConstituent == ReadBytes(averageYtm.rest, 1) IN IF ~indexConstituent.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(indexConstituent.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ bondIndexId      |-> bondIndexId.value,
         baseDate         |-> baseDate.value,
         baseTime         |-> baseTime.value,
         isinCode         |-> isinCode.value,
         basisPrice       |-> basisPrice.value,
         cleanPrice       |-> cleanPrice.value,
         averageYtm       |-> averageYtm.value,
         indexConstituent |-> indexConstituent.value,
         endKeyword       |-> endKeyword.value ], endKeyword.rest)

ZeroBondKtbIndexTermStructureMessage ==
    [ bondIndexId      |-> [i \in 1 .. 6 |-> 0],
      baseDate         |-> [i \in 1 .. 8 |-> 0],
      baseTime         |-> [i \in 1 .. 6 |-> 0],
      isinCode         |-> [i \in 1 .. 12 |-> 0],
      basisPrice       |-> [i \in 1 .. 10 |-> 0],
      cleanPrice       |-> [i \in 1 .. 10 |-> 0],
      averageYtm       |-> [i \in 1 .. 7 |-> 0],
      indexConstituent |-> [i \in 1 .. 1 |-> 0],
      endKeyword       |-> [i \in 1 .. 1 |-> 0] ]

(* Bond Ktb Index Term Structure Message at zero, then each field in turn at the values it is checked at *)
CheckedBondKtbIndexTermStructureMessage ==
    { ZeroBondKtbIndexTermStructureMessage }
        \cup { [ZeroBondKtbIndexTermStructureMessage EXCEPT !.bondIndexId = one] : one \in Sample(6) }
        \cup { [ZeroBondKtbIndexTermStructureMessage EXCEPT !.baseDate = one] : one \in Sample(8) }
        \cup { [ZeroBondKtbIndexTermStructureMessage EXCEPT !.baseTime = one] : one \in Sample(6) }
        \cup { [ZeroBondKtbIndexTermStructureMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroBondKtbIndexTermStructureMessage EXCEPT !.basisPrice = one] : one \in Sample(10) }
        \cup { [ZeroBondKtbIndexTermStructureMessage EXCEPT !.cleanPrice = one] : one \in Sample(10) }
        \cup { [ZeroBondKtbIndexTermStructureMessage EXCEPT !.averageYtm = one] : one \in Sample(7) }
        \cup { [ZeroBondKtbIndexTermStructureMessage EXCEPT !.indexConstituent = one] : one \in Sample(1) }
        \cup { [ZeroBondKtbIndexTermStructureMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Bond Index Krx Message: 518 bytes                                       *)
(***************************************************************************)

BondIndexKrxMessage ==
    [ messageSequenceNumber                                     : Sample(8),
      calculatingDate                                           : Sample(8),
      indexId                                                   : Sample(6),
      cleanPriceIndexKrx                                        : Sample(16),
      totalEarningsIndex                                        : Sample(16),
      marketPriceIndexKrx                                       : Sample(16),
      zeroReinvestmentIndexKrx                                  : Sample(16),
      callReinvestmentIndexKrx                                  : Sample(16),
      cleanPriceIndexWeight                                     : Sample(16),
      totalEarningsIndexWeight                                  : Sample(16),
      marketPriceIndexWeight                                    : Sample(16),
      zeroReInvestmentIndexWeight                               : Sample(16),
      callReInvestmentIndexWeight                               : Sample(16),
      weightOfCleanIndexValueForIntegrityIndexWeight            : Sample(16),
      weightOfSumIndexValueForIntegrityIndexWeight              : Sample(16),
      weightOfZeroReInvestmentIndexValueForIntegrityIndexWeight : Sample(16),
      weightOfCallReInvestmentIndexValueForIntegrityIndexWeight : Sample(16),
      averageDuration                                           : Sample(16),
      averageConvexity                                          : Sample(16),
      averageYld                                                : Sample(16),
      averageCouponPrice                                        : Sample(16),
      averageRemainingMaturityPrice                             : Sample(16),
      averageCurrentYield                                       : Sample(16),
      averageSpreadSign                                         : Sample(1),
      averageSpread                                             : Sample(16),
      indexNumberOfSecurities                                   : Sample(8),
      issuedAmount                                              : Sample(20),
      issuedAmountWeight                                        : Sample(16),
      indexMarketCapitalization                                 : Sample(20),
      marketCapitalizationWeight                                : Sample(16),
      accumulatedCash                                           : Sample(26),
      cashInflow                                                : Sample(26),
      reinvestCallCash                                          : Sample(26),
      endKeyword                                                : Sample(1) ]

EncodeBondIndexKrxMessage(message) ==
    message.messageSequenceNumber
        \o message.calculatingDate
        \o message.indexId
        \o message.cleanPriceIndexKrx
        \o message.totalEarningsIndex
        \o message.marketPriceIndexKrx
        \o message.zeroReinvestmentIndexKrx
        \o message.callReinvestmentIndexKrx
        \o message.cleanPriceIndexWeight
        \o message.totalEarningsIndexWeight
        \o message.marketPriceIndexWeight
        \o message.zeroReInvestmentIndexWeight
        \o message.callReInvestmentIndexWeight
        \o message.weightOfCleanIndexValueForIntegrityIndexWeight
        \o message.weightOfSumIndexValueForIntegrityIndexWeight
        \o message.weightOfZeroReInvestmentIndexValueForIntegrityIndexWeight
        \o message.weightOfCallReInvestmentIndexValueForIntegrityIndexWeight
        \o message.averageDuration
        \o message.averageConvexity
        \o message.averageYld
        \o message.averageCouponPrice
        \o message.averageRemainingMaturityPrice
        \o message.averageCurrentYield
        \o message.averageSpreadSign
        \o message.averageSpread
        \o message.indexNumberOfSecurities
        \o message.issuedAmount
        \o message.issuedAmountWeight
        \o message.indexMarketCapitalization
        \o message.marketCapitalizationWeight
        \o message.accumulatedCash
        \o message.cashInflow
        \o message.reinvestCallCash
        \o message.endKeyword

DecodeBondIndexKrxMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET calculatingDate == ReadBytes(messageSequenceNumber.rest, 8) IN IF ~calculatingDate.ok THEN Fail ELSE
    LET indexId == ReadBytes(calculatingDate.rest, 6) IN IF ~indexId.ok THEN Fail ELSE
    LET cleanPriceIndexKrx == ReadBytes(indexId.rest, 16) IN IF ~cleanPriceIndexKrx.ok THEN Fail ELSE
    LET totalEarningsIndex == ReadBytes(cleanPriceIndexKrx.rest, 16) IN IF ~totalEarningsIndex.ok THEN Fail ELSE
    LET marketPriceIndexKrx == ReadBytes(totalEarningsIndex.rest, 16) IN IF ~marketPriceIndexKrx.ok THEN Fail ELSE
    LET zeroReinvestmentIndexKrx == ReadBytes(marketPriceIndexKrx.rest, 16) IN IF ~zeroReinvestmentIndexKrx.ok THEN Fail ELSE
    LET callReinvestmentIndexKrx == ReadBytes(zeroReinvestmentIndexKrx.rest, 16) IN IF ~callReinvestmentIndexKrx.ok THEN Fail ELSE
    LET cleanPriceIndexWeight == ReadBytes(callReinvestmentIndexKrx.rest, 16) IN IF ~cleanPriceIndexWeight.ok THEN Fail ELSE
    LET totalEarningsIndexWeight == ReadBytes(cleanPriceIndexWeight.rest, 16) IN IF ~totalEarningsIndexWeight.ok THEN Fail ELSE
    LET marketPriceIndexWeight == ReadBytes(totalEarningsIndexWeight.rest, 16) IN IF ~marketPriceIndexWeight.ok THEN Fail ELSE
    LET zeroReInvestmentIndexWeight == ReadBytes(marketPriceIndexWeight.rest, 16) IN IF ~zeroReInvestmentIndexWeight.ok THEN Fail ELSE
    LET callReInvestmentIndexWeight == ReadBytes(zeroReInvestmentIndexWeight.rest, 16) IN IF ~callReInvestmentIndexWeight.ok THEN Fail ELSE
    LET weightOfCleanIndexValueForIntegrityIndexWeight == ReadBytes(callReInvestmentIndexWeight.rest, 16) IN IF ~weightOfCleanIndexValueForIntegrityIndexWeight.ok THEN Fail ELSE
    LET weightOfSumIndexValueForIntegrityIndexWeight == ReadBytes(weightOfCleanIndexValueForIntegrityIndexWeight.rest, 16) IN IF ~weightOfSumIndexValueForIntegrityIndexWeight.ok THEN Fail ELSE
    LET weightOfZeroReInvestmentIndexValueForIntegrityIndexWeight == ReadBytes(weightOfSumIndexValueForIntegrityIndexWeight.rest, 16) IN IF ~weightOfZeroReInvestmentIndexValueForIntegrityIndexWeight.ok THEN Fail ELSE
    LET weightOfCallReInvestmentIndexValueForIntegrityIndexWeight == ReadBytes(weightOfZeroReInvestmentIndexValueForIntegrityIndexWeight.rest, 16) IN IF ~weightOfCallReInvestmentIndexValueForIntegrityIndexWeight.ok THEN Fail ELSE
    LET averageDuration == ReadBytes(weightOfCallReInvestmentIndexValueForIntegrityIndexWeight.rest, 16) IN IF ~averageDuration.ok THEN Fail ELSE
    LET averageConvexity == ReadBytes(averageDuration.rest, 16) IN IF ~averageConvexity.ok THEN Fail ELSE
    LET averageYld == ReadBytes(averageConvexity.rest, 16) IN IF ~averageYld.ok THEN Fail ELSE
    LET averageCouponPrice == ReadBytes(averageYld.rest, 16) IN IF ~averageCouponPrice.ok THEN Fail ELSE
    LET averageRemainingMaturityPrice == ReadBytes(averageCouponPrice.rest, 16) IN IF ~averageRemainingMaturityPrice.ok THEN Fail ELSE
    LET averageCurrentYield == ReadBytes(averageRemainingMaturityPrice.rest, 16) IN IF ~averageCurrentYield.ok THEN Fail ELSE
    LET averageSpreadSign == ReadBytes(averageCurrentYield.rest, 1) IN IF ~averageSpreadSign.ok THEN Fail ELSE
    LET averageSpread == ReadBytes(averageSpreadSign.rest, 16) IN IF ~averageSpread.ok THEN Fail ELSE
    LET indexNumberOfSecurities == ReadBytes(averageSpread.rest, 8) IN IF ~indexNumberOfSecurities.ok THEN Fail ELSE
    LET issuedAmount == ReadBytes(indexNumberOfSecurities.rest, 20) IN IF ~issuedAmount.ok THEN Fail ELSE
    LET issuedAmountWeight == ReadBytes(issuedAmount.rest, 16) IN IF ~issuedAmountWeight.ok THEN Fail ELSE
    LET indexMarketCapitalization == ReadBytes(issuedAmountWeight.rest, 20) IN IF ~indexMarketCapitalization.ok THEN Fail ELSE
    LET marketCapitalizationWeight == ReadBytes(indexMarketCapitalization.rest, 16) IN IF ~marketCapitalizationWeight.ok THEN Fail ELSE
    LET accumulatedCash == ReadBytes(marketCapitalizationWeight.rest, 26) IN IF ~accumulatedCash.ok THEN Fail ELSE
    LET cashInflow == ReadBytes(accumulatedCash.rest, 26) IN IF ~cashInflow.ok THEN Fail ELSE
    LET reinvestCallCash == ReadBytes(cashInflow.rest, 26) IN IF ~reinvestCallCash.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(reinvestCallCash.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber                                     |-> messageSequenceNumber.value,
         calculatingDate                                           |-> calculatingDate.value,
         indexId                                                   |-> indexId.value,
         cleanPriceIndexKrx                                        |-> cleanPriceIndexKrx.value,
         totalEarningsIndex                                        |-> totalEarningsIndex.value,
         marketPriceIndexKrx                                       |-> marketPriceIndexKrx.value,
         zeroReinvestmentIndexKrx                                  |-> zeroReinvestmentIndexKrx.value,
         callReinvestmentIndexKrx                                  |-> callReinvestmentIndexKrx.value,
         cleanPriceIndexWeight                                     |-> cleanPriceIndexWeight.value,
         totalEarningsIndexWeight                                  |-> totalEarningsIndexWeight.value,
         marketPriceIndexWeight                                    |-> marketPriceIndexWeight.value,
         zeroReInvestmentIndexWeight                               |-> zeroReInvestmentIndexWeight.value,
         callReInvestmentIndexWeight                               |-> callReInvestmentIndexWeight.value,
         weightOfCleanIndexValueForIntegrityIndexWeight            |-> weightOfCleanIndexValueForIntegrityIndexWeight.value,
         weightOfSumIndexValueForIntegrityIndexWeight              |-> weightOfSumIndexValueForIntegrityIndexWeight.value,
         weightOfZeroReInvestmentIndexValueForIntegrityIndexWeight |-> weightOfZeroReInvestmentIndexValueForIntegrityIndexWeight.value,
         weightOfCallReInvestmentIndexValueForIntegrityIndexWeight |-> weightOfCallReInvestmentIndexValueForIntegrityIndexWeight.value,
         averageDuration                                           |-> averageDuration.value,
         averageConvexity                                          |-> averageConvexity.value,
         averageYld                                                |-> averageYld.value,
         averageCouponPrice                                        |-> averageCouponPrice.value,
         averageRemainingMaturityPrice                             |-> averageRemainingMaturityPrice.value,
         averageCurrentYield                                       |-> averageCurrentYield.value,
         averageSpreadSign                                         |-> averageSpreadSign.value,
         averageSpread                                             |-> averageSpread.value,
         indexNumberOfSecurities                                   |-> indexNumberOfSecurities.value,
         issuedAmount                                              |-> issuedAmount.value,
         issuedAmountWeight                                        |-> issuedAmountWeight.value,
         indexMarketCapitalization                                 |-> indexMarketCapitalization.value,
         marketCapitalizationWeight                                |-> marketCapitalizationWeight.value,
         accumulatedCash                                           |-> accumulatedCash.value,
         cashInflow                                                |-> cashInflow.value,
         reinvestCallCash                                          |-> reinvestCallCash.value,
         endKeyword                                                |-> endKeyword.value ], endKeyword.rest)

ZeroBondIndexKrxMessage ==
    [ messageSequenceNumber                                     |-> [i \in 1 .. 8 |-> 0],
      calculatingDate                                           |-> [i \in 1 .. 8 |-> 0],
      indexId                                                   |-> [i \in 1 .. 6 |-> 0],
      cleanPriceIndexKrx                                        |-> [i \in 1 .. 16 |-> 0],
      totalEarningsIndex                                        |-> [i \in 1 .. 16 |-> 0],
      marketPriceIndexKrx                                       |-> [i \in 1 .. 16 |-> 0],
      zeroReinvestmentIndexKrx                                  |-> [i \in 1 .. 16 |-> 0],
      callReinvestmentIndexKrx                                  |-> [i \in 1 .. 16 |-> 0],
      cleanPriceIndexWeight                                     |-> [i \in 1 .. 16 |-> 0],
      totalEarningsIndexWeight                                  |-> [i \in 1 .. 16 |-> 0],
      marketPriceIndexWeight                                    |-> [i \in 1 .. 16 |-> 0],
      zeroReInvestmentIndexWeight                               |-> [i \in 1 .. 16 |-> 0],
      callReInvestmentIndexWeight                               |-> [i \in 1 .. 16 |-> 0],
      weightOfCleanIndexValueForIntegrityIndexWeight            |-> [i \in 1 .. 16 |-> 0],
      weightOfSumIndexValueForIntegrityIndexWeight              |-> [i \in 1 .. 16 |-> 0],
      weightOfZeroReInvestmentIndexValueForIntegrityIndexWeight |-> [i \in 1 .. 16 |-> 0],
      weightOfCallReInvestmentIndexValueForIntegrityIndexWeight |-> [i \in 1 .. 16 |-> 0],
      averageDuration                                           |-> [i \in 1 .. 16 |-> 0],
      averageConvexity                                          |-> [i \in 1 .. 16 |-> 0],
      averageYld                                                |-> [i \in 1 .. 16 |-> 0],
      averageCouponPrice                                        |-> [i \in 1 .. 16 |-> 0],
      averageRemainingMaturityPrice                             |-> [i \in 1 .. 16 |-> 0],
      averageCurrentYield                                       |-> [i \in 1 .. 16 |-> 0],
      averageSpreadSign                                         |-> [i \in 1 .. 1 |-> 0],
      averageSpread                                             |-> [i \in 1 .. 16 |-> 0],
      indexNumberOfSecurities                                   |-> [i \in 1 .. 8 |-> 0],
      issuedAmount                                              |-> [i \in 1 .. 20 |-> 0],
      issuedAmountWeight                                        |-> [i \in 1 .. 16 |-> 0],
      indexMarketCapitalization                                 |-> [i \in 1 .. 20 |-> 0],
      marketCapitalizationWeight                                |-> [i \in 1 .. 16 |-> 0],
      accumulatedCash                                           |-> [i \in 1 .. 26 |-> 0],
      cashInflow                                                |-> [i \in 1 .. 26 |-> 0],
      reinvestCallCash                                          |-> [i \in 1 .. 26 |-> 0],
      endKeyword                                                |-> [i \in 1 .. 1 |-> 0] ]

(* Bond Index Krx Message at zero, then each field in turn at the values it is checked at *)
CheckedBondIndexKrxMessage ==
    { ZeroBondIndexKrxMessage }
        \cup { [ZeroBondIndexKrxMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroBondIndexKrxMessage EXCEPT !.calculatingDate = one] : one \in Sample(8) }
        \cup { [ZeroBondIndexKrxMessage EXCEPT !.indexId = one] : one \in Sample(6) }
        \cup { [ZeroBondIndexKrxMessage EXCEPT !.cleanPriceIndexKrx = one] : one \in Sample(16) }
        \cup { [ZeroBondIndexKrxMessage EXCEPT !.totalEarningsIndex = one] : one \in Sample(16) }
        \cup { [ZeroBondIndexKrxMessage EXCEPT !.marketPriceIndexKrx = one] : one \in Sample(16) }
        \cup { [ZeroBondIndexKrxMessage EXCEPT !.zeroReinvestmentIndexKrx = one] : one \in Sample(16) }
        \cup { [ZeroBondIndexKrxMessage EXCEPT !.callReinvestmentIndexKrx = one] : one \in Sample(16) }
        \cup { [ZeroBondIndexKrxMessage EXCEPT !.cleanPriceIndexWeight = one] : one \in Sample(16) }
        \cup { [ZeroBondIndexKrxMessage EXCEPT !.totalEarningsIndexWeight = one] : one \in Sample(16) }
        \cup { [ZeroBondIndexKrxMessage EXCEPT !.marketPriceIndexWeight = one] : one \in Sample(16) }
        \cup { [ZeroBondIndexKrxMessage EXCEPT !.zeroReInvestmentIndexWeight = one] : one \in Sample(16) }
        \cup { [ZeroBondIndexKrxMessage EXCEPT !.callReInvestmentIndexWeight = one] : one \in Sample(16) }
        \cup { [ZeroBondIndexKrxMessage EXCEPT !.weightOfCleanIndexValueForIntegrityIndexWeight = one] : one \in Sample(16) }
        \cup { [ZeroBondIndexKrxMessage EXCEPT !.weightOfSumIndexValueForIntegrityIndexWeight = one] : one \in Sample(16) }
        \cup { [ZeroBondIndexKrxMessage EXCEPT !.weightOfZeroReInvestmentIndexValueForIntegrityIndexWeight = one] : one \in Sample(16) }
        \cup { [ZeroBondIndexKrxMessage EXCEPT !.weightOfCallReInvestmentIndexValueForIntegrityIndexWeight = one] : one \in Sample(16) }
        \cup { [ZeroBondIndexKrxMessage EXCEPT !.averageDuration = one] : one \in Sample(16) }
        \cup { [ZeroBondIndexKrxMessage EXCEPT !.averageConvexity = one] : one \in Sample(16) }
        \cup { [ZeroBondIndexKrxMessage EXCEPT !.averageYld = one] : one \in Sample(16) }
        \cup { [ZeroBondIndexKrxMessage EXCEPT !.averageCouponPrice = one] : one \in Sample(16) }
        \cup { [ZeroBondIndexKrxMessage EXCEPT !.averageRemainingMaturityPrice = one] : one \in Sample(16) }
        \cup { [ZeroBondIndexKrxMessage EXCEPT !.averageCurrentYield = one] : one \in Sample(16) }
        \cup { [ZeroBondIndexKrxMessage EXCEPT !.averageSpreadSign = one] : one \in Sample(1) }
        \cup { [ZeroBondIndexKrxMessage EXCEPT !.averageSpread = one] : one \in Sample(16) }
        \cup { [ZeroBondIndexKrxMessage EXCEPT !.indexNumberOfSecurities = one] : one \in Sample(8) }
        \cup { [ZeroBondIndexKrxMessage EXCEPT !.issuedAmount = one] : one \in Sample(20) }
        \cup { [ZeroBondIndexKrxMessage EXCEPT !.issuedAmountWeight = one] : one \in Sample(16) }
        \cup { [ZeroBondIndexKrxMessage EXCEPT !.indexMarketCapitalization = one] : one \in Sample(20) }
        \cup { [ZeroBondIndexKrxMessage EXCEPT !.marketCapitalizationWeight = one] : one \in Sample(16) }
        \cup { [ZeroBondIndexKrxMessage EXCEPT !.accumulatedCash = one] : one \in Sample(26) }
        \cup { [ZeroBondIndexKrxMessage EXCEPT !.cashInflow = one] : one \in Sample(26) }
        \cup { [ZeroBondIndexKrxMessage EXCEPT !.reinvestCallCash = one] : one \in Sample(26) }
        \cup { [ZeroBondIndexKrxMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Spot Gold Quote Message: 790 bytes                                      *)
(***************************************************************************)

SpotGoldQuoteMessage ==
    [ messageSequenceNumber         : Sample(8),
      boardId                       : Sample(2),
      sessionId                     : Sample(2),
      isinCode                      : Sample(12),
      aDesignatedNumberForAnIssue   : Sample(6),
      processingTimeOfTradingSystem : Sample(12),
      askLevel1Price                : Sample(11),
      bidLevel1Price                : Sample(11),
      askLevel1Volume               : Sample(12),
      bidLevel1Volume               : Sample(12),
      lpAskLevel1Volume             : Sample(12),
      lpBidLevel1Volume             : Sample(12),
      askLevel2Price                : Sample(11),
      bidLevel2Price                : Sample(11),
      askLevel2Volume               : Sample(12),
      bidLevel2Volume               : Sample(12),
      lpAskLevel2Volume             : Sample(12),
      lpBidLevel2Volume             : Sample(12),
      askLevel3Price                : Sample(11),
      bidLevel3Price                : Sample(11),
      askLevel3Volume               : Sample(12),
      bidLevel3Volume               : Sample(12),
      lpAskLevel3Volume             : Sample(12),
      lpBidLevel3Volume             : Sample(12),
      askLevel4Price                : Sample(11),
      bidLevel4Price                : Sample(11),
      askLevel4Volume               : Sample(12),
      bidLevel4Volume               : Sample(12),
      lpAskLevel4Volume             : Sample(12),
      lpBidLevel4Volume             : Sample(12),
      askLevel5Price                : Sample(11),
      bidLevel5Price                : Sample(11),
      askLevel5Volume               : Sample(12),
      bidLevel5Volume               : Sample(12),
      lpAskLevel5Volume             : Sample(12),
      lpBidLevel5Volume             : Sample(12),
      askLevel6Price                : Sample(11),
      bidLevel6Price                : Sample(11),
      askLevel6Volume               : Sample(12),
      bidLevel6Volume               : Sample(12),
      lpAskLevel6Volume             : Sample(12),
      lpBidLevel6Volume             : Sample(12),
      askLevel7Price                : Sample(11),
      bidLevel7Price                : Sample(11),
      askLevel7Volume               : Sample(12),
      bidLevel7Volume               : Sample(12),
      lpAskLevel7Volume             : Sample(12),
      lpBidLevel7Volume             : Sample(12),
      askLevel8Price                : Sample(11),
      bidLevel8Price                : Sample(11),
      askLevel8Volume               : Sample(12),
      bidLevel8Volume               : Sample(12),
      lpAskLevel8Volume             : Sample(12),
      lpBidLevel8Volume             : Sample(12),
      askLevel9Price                : Sample(11),
      bidLevel9Price                : Sample(11),
      askLevel9Volume               : Sample(12),
      bidLevel9Volume               : Sample(12),
      lpAskLevel9Volume             : Sample(12),
      lpBidLevel9Volume             : Sample(12),
      askLevel10Price               : Sample(11),
      bidLevel10Price               : Sample(11),
      askLevel10Volume              : Sample(12),
      bidLevel10Volume              : Sample(12),
      lpAskLevel10Volume            : Sample(12),
      lpBidLevel10Volume            : Sample(12),
      totalAskVolume                : Sample(12),
      totalBidVolume                : Sample(12),
      estimatedTradingPrice         : Sample(11),
      estimatedTradingVolume        : Sample(12),
      endKeyword                    : Sample(1) ]

EncodeSpotGoldQuoteMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.sessionId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.processingTimeOfTradingSystem
        \o message.askLevel1Price
        \o message.bidLevel1Price
        \o message.askLevel1Volume
        \o message.bidLevel1Volume
        \o message.lpAskLevel1Volume
        \o message.lpBidLevel1Volume
        \o message.askLevel2Price
        \o message.bidLevel2Price
        \o message.askLevel2Volume
        \o message.bidLevel2Volume
        \o message.lpAskLevel2Volume
        \o message.lpBidLevel2Volume
        \o message.askLevel3Price
        \o message.bidLevel3Price
        \o message.askLevel3Volume
        \o message.bidLevel3Volume
        \o message.lpAskLevel3Volume
        \o message.lpBidLevel3Volume
        \o message.askLevel4Price
        \o message.bidLevel4Price
        \o message.askLevel4Volume
        \o message.bidLevel4Volume
        \o message.lpAskLevel4Volume
        \o message.lpBidLevel4Volume
        \o message.askLevel5Price
        \o message.bidLevel5Price
        \o message.askLevel5Volume
        \o message.bidLevel5Volume
        \o message.lpAskLevel5Volume
        \o message.lpBidLevel5Volume
        \o message.askLevel6Price
        \o message.bidLevel6Price
        \o message.askLevel6Volume
        \o message.bidLevel6Volume
        \o message.lpAskLevel6Volume
        \o message.lpBidLevel6Volume
        \o message.askLevel7Price
        \o message.bidLevel7Price
        \o message.askLevel7Volume
        \o message.bidLevel7Volume
        \o message.lpAskLevel7Volume
        \o message.lpBidLevel7Volume
        \o message.askLevel8Price
        \o message.bidLevel8Price
        \o message.askLevel8Volume
        \o message.bidLevel8Volume
        \o message.lpAskLevel8Volume
        \o message.lpBidLevel8Volume
        \o message.askLevel9Price
        \o message.bidLevel9Price
        \o message.askLevel9Volume
        \o message.bidLevel9Volume
        \o message.lpAskLevel9Volume
        \o message.lpBidLevel9Volume
        \o message.askLevel10Price
        \o message.bidLevel10Price
        \o message.askLevel10Volume
        \o message.bidLevel10Volume
        \o message.lpAskLevel10Volume
        \o message.lpBidLevel10Volume
        \o message.totalAskVolume
        \o message.totalBidVolume
        \o message.estimatedTradingPrice
        \o message.estimatedTradingVolume
        \o message.endKeyword

DecodeSpotGoldQuoteMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(boardId.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(sessionId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET processingTimeOfTradingSystem == ReadBytes(aDesignatedNumberForAnIssue.rest, 12) IN IF ~processingTimeOfTradingSystem.ok THEN Fail ELSE
    LET askLevel1Price == ReadBytes(processingTimeOfTradingSystem.rest, 11) IN IF ~askLevel1Price.ok THEN Fail ELSE
    LET bidLevel1Price == ReadBytes(askLevel1Price.rest, 11) IN IF ~bidLevel1Price.ok THEN Fail ELSE
    LET askLevel1Volume == ReadBytes(bidLevel1Price.rest, 12) IN IF ~askLevel1Volume.ok THEN Fail ELSE
    LET bidLevel1Volume == ReadBytes(askLevel1Volume.rest, 12) IN IF ~bidLevel1Volume.ok THEN Fail ELSE
    LET lpAskLevel1Volume == ReadBytes(bidLevel1Volume.rest, 12) IN IF ~lpAskLevel1Volume.ok THEN Fail ELSE
    LET lpBidLevel1Volume == ReadBytes(lpAskLevel1Volume.rest, 12) IN IF ~lpBidLevel1Volume.ok THEN Fail ELSE
    LET askLevel2Price == ReadBytes(lpBidLevel1Volume.rest, 11) IN IF ~askLevel2Price.ok THEN Fail ELSE
    LET bidLevel2Price == ReadBytes(askLevel2Price.rest, 11) IN IF ~bidLevel2Price.ok THEN Fail ELSE
    LET askLevel2Volume == ReadBytes(bidLevel2Price.rest, 12) IN IF ~askLevel2Volume.ok THEN Fail ELSE
    LET bidLevel2Volume == ReadBytes(askLevel2Volume.rest, 12) IN IF ~bidLevel2Volume.ok THEN Fail ELSE
    LET lpAskLevel2Volume == ReadBytes(bidLevel2Volume.rest, 12) IN IF ~lpAskLevel2Volume.ok THEN Fail ELSE
    LET lpBidLevel2Volume == ReadBytes(lpAskLevel2Volume.rest, 12) IN IF ~lpBidLevel2Volume.ok THEN Fail ELSE
    LET askLevel3Price == ReadBytes(lpBidLevel2Volume.rest, 11) IN IF ~askLevel3Price.ok THEN Fail ELSE
    LET bidLevel3Price == ReadBytes(askLevel3Price.rest, 11) IN IF ~bidLevel3Price.ok THEN Fail ELSE
    LET askLevel3Volume == ReadBytes(bidLevel3Price.rest, 12) IN IF ~askLevel3Volume.ok THEN Fail ELSE
    LET bidLevel3Volume == ReadBytes(askLevel3Volume.rest, 12) IN IF ~bidLevel3Volume.ok THEN Fail ELSE
    LET lpAskLevel3Volume == ReadBytes(bidLevel3Volume.rest, 12) IN IF ~lpAskLevel3Volume.ok THEN Fail ELSE
    LET lpBidLevel3Volume == ReadBytes(lpAskLevel3Volume.rest, 12) IN IF ~lpBidLevel3Volume.ok THEN Fail ELSE
    LET askLevel4Price == ReadBytes(lpBidLevel3Volume.rest, 11) IN IF ~askLevel4Price.ok THEN Fail ELSE
    LET bidLevel4Price == ReadBytes(askLevel4Price.rest, 11) IN IF ~bidLevel4Price.ok THEN Fail ELSE
    LET askLevel4Volume == ReadBytes(bidLevel4Price.rest, 12) IN IF ~askLevel4Volume.ok THEN Fail ELSE
    LET bidLevel4Volume == ReadBytes(askLevel4Volume.rest, 12) IN IF ~bidLevel4Volume.ok THEN Fail ELSE
    LET lpAskLevel4Volume == ReadBytes(bidLevel4Volume.rest, 12) IN IF ~lpAskLevel4Volume.ok THEN Fail ELSE
    LET lpBidLevel4Volume == ReadBytes(lpAskLevel4Volume.rest, 12) IN IF ~lpBidLevel4Volume.ok THEN Fail ELSE
    LET askLevel5Price == ReadBytes(lpBidLevel4Volume.rest, 11) IN IF ~askLevel5Price.ok THEN Fail ELSE
    LET bidLevel5Price == ReadBytes(askLevel5Price.rest, 11) IN IF ~bidLevel5Price.ok THEN Fail ELSE
    LET askLevel5Volume == ReadBytes(bidLevel5Price.rest, 12) IN IF ~askLevel5Volume.ok THEN Fail ELSE
    LET bidLevel5Volume == ReadBytes(askLevel5Volume.rest, 12) IN IF ~bidLevel5Volume.ok THEN Fail ELSE
    LET lpAskLevel5Volume == ReadBytes(bidLevel5Volume.rest, 12) IN IF ~lpAskLevel5Volume.ok THEN Fail ELSE
    LET lpBidLevel5Volume == ReadBytes(lpAskLevel5Volume.rest, 12) IN IF ~lpBidLevel5Volume.ok THEN Fail ELSE
    LET askLevel6Price == ReadBytes(lpBidLevel5Volume.rest, 11) IN IF ~askLevel6Price.ok THEN Fail ELSE
    LET bidLevel6Price == ReadBytes(askLevel6Price.rest, 11) IN IF ~bidLevel6Price.ok THEN Fail ELSE
    LET askLevel6Volume == ReadBytes(bidLevel6Price.rest, 12) IN IF ~askLevel6Volume.ok THEN Fail ELSE
    LET bidLevel6Volume == ReadBytes(askLevel6Volume.rest, 12) IN IF ~bidLevel6Volume.ok THEN Fail ELSE
    LET lpAskLevel6Volume == ReadBytes(bidLevel6Volume.rest, 12) IN IF ~lpAskLevel6Volume.ok THEN Fail ELSE
    LET lpBidLevel6Volume == ReadBytes(lpAskLevel6Volume.rest, 12) IN IF ~lpBidLevel6Volume.ok THEN Fail ELSE
    LET askLevel7Price == ReadBytes(lpBidLevel6Volume.rest, 11) IN IF ~askLevel7Price.ok THEN Fail ELSE
    LET bidLevel7Price == ReadBytes(askLevel7Price.rest, 11) IN IF ~bidLevel7Price.ok THEN Fail ELSE
    LET askLevel7Volume == ReadBytes(bidLevel7Price.rest, 12) IN IF ~askLevel7Volume.ok THEN Fail ELSE
    LET bidLevel7Volume == ReadBytes(askLevel7Volume.rest, 12) IN IF ~bidLevel7Volume.ok THEN Fail ELSE
    LET lpAskLevel7Volume == ReadBytes(bidLevel7Volume.rest, 12) IN IF ~lpAskLevel7Volume.ok THEN Fail ELSE
    LET lpBidLevel7Volume == ReadBytes(lpAskLevel7Volume.rest, 12) IN IF ~lpBidLevel7Volume.ok THEN Fail ELSE
    LET askLevel8Price == ReadBytes(lpBidLevel7Volume.rest, 11) IN IF ~askLevel8Price.ok THEN Fail ELSE
    LET bidLevel8Price == ReadBytes(askLevel8Price.rest, 11) IN IF ~bidLevel8Price.ok THEN Fail ELSE
    LET askLevel8Volume == ReadBytes(bidLevel8Price.rest, 12) IN IF ~askLevel8Volume.ok THEN Fail ELSE
    LET bidLevel8Volume == ReadBytes(askLevel8Volume.rest, 12) IN IF ~bidLevel8Volume.ok THEN Fail ELSE
    LET lpAskLevel8Volume == ReadBytes(bidLevel8Volume.rest, 12) IN IF ~lpAskLevel8Volume.ok THEN Fail ELSE
    LET lpBidLevel8Volume == ReadBytes(lpAskLevel8Volume.rest, 12) IN IF ~lpBidLevel8Volume.ok THEN Fail ELSE
    LET askLevel9Price == ReadBytes(lpBidLevel8Volume.rest, 11) IN IF ~askLevel9Price.ok THEN Fail ELSE
    LET bidLevel9Price == ReadBytes(askLevel9Price.rest, 11) IN IF ~bidLevel9Price.ok THEN Fail ELSE
    LET askLevel9Volume == ReadBytes(bidLevel9Price.rest, 12) IN IF ~askLevel9Volume.ok THEN Fail ELSE
    LET bidLevel9Volume == ReadBytes(askLevel9Volume.rest, 12) IN IF ~bidLevel9Volume.ok THEN Fail ELSE
    LET lpAskLevel9Volume == ReadBytes(bidLevel9Volume.rest, 12) IN IF ~lpAskLevel9Volume.ok THEN Fail ELSE
    LET lpBidLevel9Volume == ReadBytes(lpAskLevel9Volume.rest, 12) IN IF ~lpBidLevel9Volume.ok THEN Fail ELSE
    LET askLevel10Price == ReadBytes(lpBidLevel9Volume.rest, 11) IN IF ~askLevel10Price.ok THEN Fail ELSE
    LET bidLevel10Price == ReadBytes(askLevel10Price.rest, 11) IN IF ~bidLevel10Price.ok THEN Fail ELSE
    LET askLevel10Volume == ReadBytes(bidLevel10Price.rest, 12) IN IF ~askLevel10Volume.ok THEN Fail ELSE
    LET bidLevel10Volume == ReadBytes(askLevel10Volume.rest, 12) IN IF ~bidLevel10Volume.ok THEN Fail ELSE
    LET lpAskLevel10Volume == ReadBytes(bidLevel10Volume.rest, 12) IN IF ~lpAskLevel10Volume.ok THEN Fail ELSE
    LET lpBidLevel10Volume == ReadBytes(lpAskLevel10Volume.rest, 12) IN IF ~lpBidLevel10Volume.ok THEN Fail ELSE
    LET totalAskVolume == ReadBytes(lpBidLevel10Volume.rest, 12) IN IF ~totalAskVolume.ok THEN Fail ELSE
    LET totalBidVolume == ReadBytes(totalAskVolume.rest, 12) IN IF ~totalBidVolume.ok THEN Fail ELSE
    LET estimatedTradingPrice == ReadBytes(totalBidVolume.rest, 11) IN IF ~estimatedTradingPrice.ok THEN Fail ELSE
    LET estimatedTradingVolume == ReadBytes(estimatedTradingPrice.rest, 12) IN IF ~estimatedTradingVolume.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(estimatedTradingVolume.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber         |-> messageSequenceNumber.value,
         boardId                       |-> boardId.value,
         sessionId                     |-> sessionId.value,
         isinCode                      |-> isinCode.value,
         aDesignatedNumberForAnIssue   |-> aDesignatedNumberForAnIssue.value,
         processingTimeOfTradingSystem |-> processingTimeOfTradingSystem.value,
         askLevel1Price                |-> askLevel1Price.value,
         bidLevel1Price                |-> bidLevel1Price.value,
         askLevel1Volume               |-> askLevel1Volume.value,
         bidLevel1Volume               |-> bidLevel1Volume.value,
         lpAskLevel1Volume             |-> lpAskLevel1Volume.value,
         lpBidLevel1Volume             |-> lpBidLevel1Volume.value,
         askLevel2Price                |-> askLevel2Price.value,
         bidLevel2Price                |-> bidLevel2Price.value,
         askLevel2Volume               |-> askLevel2Volume.value,
         bidLevel2Volume               |-> bidLevel2Volume.value,
         lpAskLevel2Volume             |-> lpAskLevel2Volume.value,
         lpBidLevel2Volume             |-> lpBidLevel2Volume.value,
         askLevel3Price                |-> askLevel3Price.value,
         bidLevel3Price                |-> bidLevel3Price.value,
         askLevel3Volume               |-> askLevel3Volume.value,
         bidLevel3Volume               |-> bidLevel3Volume.value,
         lpAskLevel3Volume             |-> lpAskLevel3Volume.value,
         lpBidLevel3Volume             |-> lpBidLevel3Volume.value,
         askLevel4Price                |-> askLevel4Price.value,
         bidLevel4Price                |-> bidLevel4Price.value,
         askLevel4Volume               |-> askLevel4Volume.value,
         bidLevel4Volume               |-> bidLevel4Volume.value,
         lpAskLevel4Volume             |-> lpAskLevel4Volume.value,
         lpBidLevel4Volume             |-> lpBidLevel4Volume.value,
         askLevel5Price                |-> askLevel5Price.value,
         bidLevel5Price                |-> bidLevel5Price.value,
         askLevel5Volume               |-> askLevel5Volume.value,
         bidLevel5Volume               |-> bidLevel5Volume.value,
         lpAskLevel5Volume             |-> lpAskLevel5Volume.value,
         lpBidLevel5Volume             |-> lpBidLevel5Volume.value,
         askLevel6Price                |-> askLevel6Price.value,
         bidLevel6Price                |-> bidLevel6Price.value,
         askLevel6Volume               |-> askLevel6Volume.value,
         bidLevel6Volume               |-> bidLevel6Volume.value,
         lpAskLevel6Volume             |-> lpAskLevel6Volume.value,
         lpBidLevel6Volume             |-> lpBidLevel6Volume.value,
         askLevel7Price                |-> askLevel7Price.value,
         bidLevel7Price                |-> bidLevel7Price.value,
         askLevel7Volume               |-> askLevel7Volume.value,
         bidLevel7Volume               |-> bidLevel7Volume.value,
         lpAskLevel7Volume             |-> lpAskLevel7Volume.value,
         lpBidLevel7Volume             |-> lpBidLevel7Volume.value,
         askLevel8Price                |-> askLevel8Price.value,
         bidLevel8Price                |-> bidLevel8Price.value,
         askLevel8Volume               |-> askLevel8Volume.value,
         bidLevel8Volume               |-> bidLevel8Volume.value,
         lpAskLevel8Volume             |-> lpAskLevel8Volume.value,
         lpBidLevel8Volume             |-> lpBidLevel8Volume.value,
         askLevel9Price                |-> askLevel9Price.value,
         bidLevel9Price                |-> bidLevel9Price.value,
         askLevel9Volume               |-> askLevel9Volume.value,
         bidLevel9Volume               |-> bidLevel9Volume.value,
         lpAskLevel9Volume             |-> lpAskLevel9Volume.value,
         lpBidLevel9Volume             |-> lpBidLevel9Volume.value,
         askLevel10Price               |-> askLevel10Price.value,
         bidLevel10Price               |-> bidLevel10Price.value,
         askLevel10Volume              |-> askLevel10Volume.value,
         bidLevel10Volume              |-> bidLevel10Volume.value,
         lpAskLevel10Volume            |-> lpAskLevel10Volume.value,
         lpBidLevel10Volume            |-> lpBidLevel10Volume.value,
         totalAskVolume                |-> totalAskVolume.value,
         totalBidVolume                |-> totalBidVolume.value,
         estimatedTradingPrice         |-> estimatedTradingPrice.value,
         estimatedTradingVolume        |-> estimatedTradingVolume.value,
         endKeyword                    |-> endKeyword.value ], endKeyword.rest)

ZeroSpotGoldQuoteMessage ==
    [ messageSequenceNumber         |-> [i \in 1 .. 8 |-> 0],
      boardId                       |-> [i \in 1 .. 2 |-> 0],
      sessionId                     |-> [i \in 1 .. 2 |-> 0],
      isinCode                      |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue   |-> [i \in 1 .. 6 |-> 0],
      processingTimeOfTradingSystem |-> [i \in 1 .. 12 |-> 0],
      askLevel1Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel1Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel1Volume               |-> [i \in 1 .. 12 |-> 0],
      bidLevel1Volume               |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel1Volume             |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel1Volume             |-> [i \in 1 .. 12 |-> 0],
      askLevel2Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel2Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel2Volume               |-> [i \in 1 .. 12 |-> 0],
      bidLevel2Volume               |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel2Volume             |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel2Volume             |-> [i \in 1 .. 12 |-> 0],
      askLevel3Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel3Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel3Volume               |-> [i \in 1 .. 12 |-> 0],
      bidLevel3Volume               |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel3Volume             |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel3Volume             |-> [i \in 1 .. 12 |-> 0],
      askLevel4Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel4Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel4Volume               |-> [i \in 1 .. 12 |-> 0],
      bidLevel4Volume               |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel4Volume             |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel4Volume             |-> [i \in 1 .. 12 |-> 0],
      askLevel5Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel5Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel5Volume               |-> [i \in 1 .. 12 |-> 0],
      bidLevel5Volume               |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel5Volume             |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel5Volume             |-> [i \in 1 .. 12 |-> 0],
      askLevel6Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel6Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel6Volume               |-> [i \in 1 .. 12 |-> 0],
      bidLevel6Volume               |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel6Volume             |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel6Volume             |-> [i \in 1 .. 12 |-> 0],
      askLevel7Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel7Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel7Volume               |-> [i \in 1 .. 12 |-> 0],
      bidLevel7Volume               |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel7Volume             |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel7Volume             |-> [i \in 1 .. 12 |-> 0],
      askLevel8Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel8Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel8Volume               |-> [i \in 1 .. 12 |-> 0],
      bidLevel8Volume               |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel8Volume             |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel8Volume             |-> [i \in 1 .. 12 |-> 0],
      askLevel9Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel9Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel9Volume               |-> [i \in 1 .. 12 |-> 0],
      bidLevel9Volume               |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel9Volume             |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel9Volume             |-> [i \in 1 .. 12 |-> 0],
      askLevel10Price               |-> [i \in 1 .. 11 |-> 0],
      bidLevel10Price               |-> [i \in 1 .. 11 |-> 0],
      askLevel10Volume              |-> [i \in 1 .. 12 |-> 0],
      bidLevel10Volume              |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel10Volume            |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel10Volume            |-> [i \in 1 .. 12 |-> 0],
      totalAskVolume                |-> [i \in 1 .. 12 |-> 0],
      totalBidVolume                |-> [i \in 1 .. 12 |-> 0],
      estimatedTradingPrice         |-> [i \in 1 .. 11 |-> 0],
      estimatedTradingVolume        |-> [i \in 1 .. 12 |-> 0],
      endKeyword                    |-> [i \in 1 .. 1 |-> 0] ]

(* Spot Gold Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedSpotGoldQuoteMessage ==
    { ZeroSpotGoldQuoteMessage }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.processingTimeOfTradingSystem = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.askLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.bidLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.askLevel1Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.bidLevel1Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.lpAskLevel1Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.lpBidLevel1Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.askLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.bidLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.askLevel2Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.bidLevel2Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.lpAskLevel2Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.lpBidLevel2Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.askLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.bidLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.askLevel3Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.bidLevel3Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.lpAskLevel3Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.lpBidLevel3Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.askLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.bidLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.askLevel4Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.bidLevel4Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.lpAskLevel4Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.lpBidLevel4Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.askLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.bidLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.askLevel5Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.bidLevel5Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.lpAskLevel5Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.lpBidLevel5Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.askLevel6Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.bidLevel6Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.askLevel6Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.bidLevel6Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.lpAskLevel6Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.lpBidLevel6Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.askLevel7Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.bidLevel7Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.askLevel7Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.bidLevel7Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.lpAskLevel7Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.lpBidLevel7Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.askLevel8Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.bidLevel8Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.askLevel8Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.bidLevel8Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.lpAskLevel8Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.lpBidLevel8Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.askLevel9Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.bidLevel9Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.askLevel9Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.bidLevel9Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.lpAskLevel9Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.lpBidLevel9Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.askLevel10Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.bidLevel10Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.askLevel10Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.bidLevel10Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.lpAskLevel10Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.lpBidLevel10Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.totalAskVolume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.totalBidVolume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.estimatedTradingPrice = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.estimatedTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldQuoteMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Spot Gold Order Filled Message: 158 bytes                               *)
(***************************************************************************)

SpotGoldOrderFilledMessage ==
    [ messageSequenceNumber         : Sample(8),
      boardId                       : Sample(2),
      sessionId                     : Sample(2),
      isinCode                      : Sample(12),
      aDesignatedNumberForAnIssue   : Sample(6),
      processingTimeOfTradingSystem : Sample(12),
      tradingPrice                  : Sample(11),
      tradingVolume                 : Sample(10),
      openingPriceLong              : Sample(11),
      todaysHigh                    : Sample(11),
      todaysLow                     : Sample(11),
      previousPrice                 : Sample(11),
      accumulatedTradingVolume      : Sample(12),
      accumulatedTradingValueLong   : Sample(22),
      finalAskBidTypeCode           : Sample(1),
      lpHoldingQuantity             : Sample(15),
      endKeyword                    : Sample(1) ]

EncodeSpotGoldOrderFilledMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.sessionId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.processingTimeOfTradingSystem
        \o message.tradingPrice
        \o message.tradingVolume
        \o message.openingPriceLong
        \o message.todaysHigh
        \o message.todaysLow
        \o message.previousPrice
        \o message.accumulatedTradingVolume
        \o message.accumulatedTradingValueLong
        \o message.finalAskBidTypeCode
        \o message.lpHoldingQuantity
        \o message.endKeyword

DecodeSpotGoldOrderFilledMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(boardId.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(sessionId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET processingTimeOfTradingSystem == ReadBytes(aDesignatedNumberForAnIssue.rest, 12) IN IF ~processingTimeOfTradingSystem.ok THEN Fail ELSE
    LET tradingPrice == ReadBytes(processingTimeOfTradingSystem.rest, 11) IN IF ~tradingPrice.ok THEN Fail ELSE
    LET tradingVolume == ReadBytes(tradingPrice.rest, 10) IN IF ~tradingVolume.ok THEN Fail ELSE
    LET openingPriceLong == ReadBytes(tradingVolume.rest, 11) IN IF ~openingPriceLong.ok THEN Fail ELSE
    LET todaysHigh == ReadBytes(openingPriceLong.rest, 11) IN IF ~todaysHigh.ok THEN Fail ELSE
    LET todaysLow == ReadBytes(todaysHigh.rest, 11) IN IF ~todaysLow.ok THEN Fail ELSE
    LET previousPrice == ReadBytes(todaysLow.rest, 11) IN IF ~previousPrice.ok THEN Fail ELSE
    LET accumulatedTradingVolume == ReadBytes(previousPrice.rest, 12) IN IF ~accumulatedTradingVolume.ok THEN Fail ELSE
    LET accumulatedTradingValueLong == ReadBytes(accumulatedTradingVolume.rest, 22) IN IF ~accumulatedTradingValueLong.ok THEN Fail ELSE
    LET finalAskBidTypeCode == ReadBytes(accumulatedTradingValueLong.rest, 1) IN IF ~finalAskBidTypeCode.ok THEN Fail ELSE
    LET lpHoldingQuantity == ReadBytes(finalAskBidTypeCode.rest, 15) IN IF ~lpHoldingQuantity.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(lpHoldingQuantity.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber         |-> messageSequenceNumber.value,
         boardId                       |-> boardId.value,
         sessionId                     |-> sessionId.value,
         isinCode                      |-> isinCode.value,
         aDesignatedNumberForAnIssue   |-> aDesignatedNumberForAnIssue.value,
         processingTimeOfTradingSystem |-> processingTimeOfTradingSystem.value,
         tradingPrice                  |-> tradingPrice.value,
         tradingVolume                 |-> tradingVolume.value,
         openingPriceLong              |-> openingPriceLong.value,
         todaysHigh                    |-> todaysHigh.value,
         todaysLow                     |-> todaysLow.value,
         previousPrice                 |-> previousPrice.value,
         accumulatedTradingVolume      |-> accumulatedTradingVolume.value,
         accumulatedTradingValueLong   |-> accumulatedTradingValueLong.value,
         finalAskBidTypeCode           |-> finalAskBidTypeCode.value,
         lpHoldingQuantity             |-> lpHoldingQuantity.value,
         endKeyword                    |-> endKeyword.value ], endKeyword.rest)

ZeroSpotGoldOrderFilledMessage ==
    [ messageSequenceNumber         |-> [i \in 1 .. 8 |-> 0],
      boardId                       |-> [i \in 1 .. 2 |-> 0],
      sessionId                     |-> [i \in 1 .. 2 |-> 0],
      isinCode                      |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue   |-> [i \in 1 .. 6 |-> 0],
      processingTimeOfTradingSystem |-> [i \in 1 .. 12 |-> 0],
      tradingPrice                  |-> [i \in 1 .. 11 |-> 0],
      tradingVolume                 |-> [i \in 1 .. 10 |-> 0],
      openingPriceLong              |-> [i \in 1 .. 11 |-> 0],
      todaysHigh                    |-> [i \in 1 .. 11 |-> 0],
      todaysLow                     |-> [i \in 1 .. 11 |-> 0],
      previousPrice                 |-> [i \in 1 .. 11 |-> 0],
      accumulatedTradingVolume      |-> [i \in 1 .. 12 |-> 0],
      accumulatedTradingValueLong   |-> [i \in 1 .. 22 |-> 0],
      finalAskBidTypeCode           |-> [i \in 1 .. 1 |-> 0],
      lpHoldingQuantity             |-> [i \in 1 .. 15 |-> 0],
      endKeyword                    |-> [i \in 1 .. 1 |-> 0] ]

(* Spot Gold Order Filled Message at zero, then each field in turn at the values it is checked at *)
CheckedSpotGoldOrderFilledMessage ==
    { ZeroSpotGoldOrderFilledMessage }
        \cup { [ZeroSpotGoldOrderFilledMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSpotGoldOrderFilledMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroSpotGoldOrderFilledMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroSpotGoldOrderFilledMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroSpotGoldOrderFilledMessage EXCEPT !.processingTimeOfTradingSystem = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledMessage EXCEPT !.tradingPrice = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldOrderFilledMessage EXCEPT !.tradingVolume = one] : one \in Sample(10) }
        \cup { [ZeroSpotGoldOrderFilledMessage EXCEPT !.openingPriceLong = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldOrderFilledMessage EXCEPT !.todaysHigh = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldOrderFilledMessage EXCEPT !.todaysLow = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldOrderFilledMessage EXCEPT !.previousPrice = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldOrderFilledMessage EXCEPT !.accumulatedTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledMessage EXCEPT !.accumulatedTradingValueLong = one] : one \in Sample(22) }
        \cup { [ZeroSpotGoldOrderFilledMessage EXCEPT !.finalAskBidTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroSpotGoldOrderFilledMessage EXCEPT !.lpHoldingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroSpotGoldOrderFilledMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Spot Gold Order Filled Plus Quote Message: 882 bytes                    *)
(***************************************************************************)

SpotGoldOrderFilledPlusQuoteMessage ==
    [ messageSequenceNumber         : Sample(8),
      boardId                       : Sample(2),
      sessionId                     : Sample(2),
      isinCode                      : Sample(12),
      aDesignatedNumberForAnIssue   : Sample(6),
      processingTimeOfTradingSystem : Sample(12),
      tradingPrice                  : Sample(11),
      tradingVolume                 : Sample(10),
      openingPriceLong              : Sample(11),
      todaysHigh                    : Sample(11),
      todaysLow                     : Sample(11),
      previousPrice                 : Sample(11),
      accumulatedTradingVolume      : Sample(12),
      accumulatedTradingValueLong   : Sample(22),
      finalAskBidTypeCode           : Sample(1),
      lpHoldingQuantity             : Sample(15),
      askLevel1Price                : Sample(11),
      bidLevel1Price                : Sample(11),
      askLevel1Volume               : Sample(12),
      bidLevel1Volume               : Sample(12),
      lpAskLevel1Volume             : Sample(12),
      lpBidLevel1Volume             : Sample(12),
      askLevel2Price                : Sample(11),
      bidLevel2Price                : Sample(11),
      askLevel2Volume               : Sample(12),
      bidLevel2Volume               : Sample(12),
      lpAskLevel2Volume             : Sample(12),
      lpBidLevel2Volume             : Sample(12),
      askLevel3Price                : Sample(11),
      bidLevel3Price                : Sample(11),
      askLevel3Volume               : Sample(12),
      bidLevel3Volume               : Sample(12),
      lpAskLevel3Volume             : Sample(12),
      lpBidLevel3Volume             : Sample(12),
      askLevel4Price                : Sample(11),
      bidLevel4Price                : Sample(11),
      askLevel4Volume               : Sample(12),
      bidLevel4Volume               : Sample(12),
      lpAskLevel4Volume             : Sample(12),
      lpBidLevel4Volume             : Sample(12),
      askLevel5Price                : Sample(11),
      bidLevel5Price                : Sample(11),
      askLevel5Volume               : Sample(12),
      bidLevel5Volume               : Sample(12),
      lpAskLevel5Volume             : Sample(12),
      lpBidLevel5Volume             : Sample(12),
      askLevel6Price                : Sample(11),
      bidLevel6Price                : Sample(11),
      askLevel6Volume               : Sample(12),
      bidLevel6Volume               : Sample(12),
      lpAskLevel6Volume             : Sample(12),
      lpBidLevel6Volume             : Sample(12),
      askLevel7Price                : Sample(11),
      bidLevel7Price                : Sample(11),
      askLevel7Volume               : Sample(12),
      bidLevel7Volume               : Sample(12),
      lpAskLevel7Volume             : Sample(12),
      lpBidLevel7Volume             : Sample(12),
      askLevel8Price                : Sample(11),
      bidLevel8Price                : Sample(11),
      askLevel8Volume               : Sample(12),
      bidLevel8Volume               : Sample(12),
      lpAskLevel8Volume             : Sample(12),
      lpBidLevel8Volume             : Sample(12),
      askLevel9Price                : Sample(11),
      bidLevel9Price                : Sample(11),
      askLevel9Volume               : Sample(12),
      bidLevel9Volume               : Sample(12),
      lpAskLevel9Volume             : Sample(12),
      lpBidLevel9Volume             : Sample(12),
      askLevel10Price               : Sample(11),
      bidLevel10Price               : Sample(11),
      askLevel10Volume              : Sample(12),
      bidLevel10Volume              : Sample(12),
      lpAskLevel10Volume            : Sample(12),
      lpBidLevel10Volume            : Sample(12),
      totalAskVolume                : Sample(12),
      totalBidVolume                : Sample(12),
      endKeyword                    : Sample(1) ]

EncodeSpotGoldOrderFilledPlusQuoteMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.sessionId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.processingTimeOfTradingSystem
        \o message.tradingPrice
        \o message.tradingVolume
        \o message.openingPriceLong
        \o message.todaysHigh
        \o message.todaysLow
        \o message.previousPrice
        \o message.accumulatedTradingVolume
        \o message.accumulatedTradingValueLong
        \o message.finalAskBidTypeCode
        \o message.lpHoldingQuantity
        \o message.askLevel1Price
        \o message.bidLevel1Price
        \o message.askLevel1Volume
        \o message.bidLevel1Volume
        \o message.lpAskLevel1Volume
        \o message.lpBidLevel1Volume
        \o message.askLevel2Price
        \o message.bidLevel2Price
        \o message.askLevel2Volume
        \o message.bidLevel2Volume
        \o message.lpAskLevel2Volume
        \o message.lpBidLevel2Volume
        \o message.askLevel3Price
        \o message.bidLevel3Price
        \o message.askLevel3Volume
        \o message.bidLevel3Volume
        \o message.lpAskLevel3Volume
        \o message.lpBidLevel3Volume
        \o message.askLevel4Price
        \o message.bidLevel4Price
        \o message.askLevel4Volume
        \o message.bidLevel4Volume
        \o message.lpAskLevel4Volume
        \o message.lpBidLevel4Volume
        \o message.askLevel5Price
        \o message.bidLevel5Price
        \o message.askLevel5Volume
        \o message.bidLevel5Volume
        \o message.lpAskLevel5Volume
        \o message.lpBidLevel5Volume
        \o message.askLevel6Price
        \o message.bidLevel6Price
        \o message.askLevel6Volume
        \o message.bidLevel6Volume
        \o message.lpAskLevel6Volume
        \o message.lpBidLevel6Volume
        \o message.askLevel7Price
        \o message.bidLevel7Price
        \o message.askLevel7Volume
        \o message.bidLevel7Volume
        \o message.lpAskLevel7Volume
        \o message.lpBidLevel7Volume
        \o message.askLevel8Price
        \o message.bidLevel8Price
        \o message.askLevel8Volume
        \o message.bidLevel8Volume
        \o message.lpAskLevel8Volume
        \o message.lpBidLevel8Volume
        \o message.askLevel9Price
        \o message.bidLevel9Price
        \o message.askLevel9Volume
        \o message.bidLevel9Volume
        \o message.lpAskLevel9Volume
        \o message.lpBidLevel9Volume
        \o message.askLevel10Price
        \o message.bidLevel10Price
        \o message.askLevel10Volume
        \o message.bidLevel10Volume
        \o message.lpAskLevel10Volume
        \o message.lpBidLevel10Volume
        \o message.totalAskVolume
        \o message.totalBidVolume
        \o message.endKeyword

DecodeSpotGoldOrderFilledPlusQuoteMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(boardId.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(sessionId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET processingTimeOfTradingSystem == ReadBytes(aDesignatedNumberForAnIssue.rest, 12) IN IF ~processingTimeOfTradingSystem.ok THEN Fail ELSE
    LET tradingPrice == ReadBytes(processingTimeOfTradingSystem.rest, 11) IN IF ~tradingPrice.ok THEN Fail ELSE
    LET tradingVolume == ReadBytes(tradingPrice.rest, 10) IN IF ~tradingVolume.ok THEN Fail ELSE
    LET openingPriceLong == ReadBytes(tradingVolume.rest, 11) IN IF ~openingPriceLong.ok THEN Fail ELSE
    LET todaysHigh == ReadBytes(openingPriceLong.rest, 11) IN IF ~todaysHigh.ok THEN Fail ELSE
    LET todaysLow == ReadBytes(todaysHigh.rest, 11) IN IF ~todaysLow.ok THEN Fail ELSE
    LET previousPrice == ReadBytes(todaysLow.rest, 11) IN IF ~previousPrice.ok THEN Fail ELSE
    LET accumulatedTradingVolume == ReadBytes(previousPrice.rest, 12) IN IF ~accumulatedTradingVolume.ok THEN Fail ELSE
    LET accumulatedTradingValueLong == ReadBytes(accumulatedTradingVolume.rest, 22) IN IF ~accumulatedTradingValueLong.ok THEN Fail ELSE
    LET finalAskBidTypeCode == ReadBytes(accumulatedTradingValueLong.rest, 1) IN IF ~finalAskBidTypeCode.ok THEN Fail ELSE
    LET lpHoldingQuantity == ReadBytes(finalAskBidTypeCode.rest, 15) IN IF ~lpHoldingQuantity.ok THEN Fail ELSE
    LET askLevel1Price == ReadBytes(lpHoldingQuantity.rest, 11) IN IF ~askLevel1Price.ok THEN Fail ELSE
    LET bidLevel1Price == ReadBytes(askLevel1Price.rest, 11) IN IF ~bidLevel1Price.ok THEN Fail ELSE
    LET askLevel1Volume == ReadBytes(bidLevel1Price.rest, 12) IN IF ~askLevel1Volume.ok THEN Fail ELSE
    LET bidLevel1Volume == ReadBytes(askLevel1Volume.rest, 12) IN IF ~bidLevel1Volume.ok THEN Fail ELSE
    LET lpAskLevel1Volume == ReadBytes(bidLevel1Volume.rest, 12) IN IF ~lpAskLevel1Volume.ok THEN Fail ELSE
    LET lpBidLevel1Volume == ReadBytes(lpAskLevel1Volume.rest, 12) IN IF ~lpBidLevel1Volume.ok THEN Fail ELSE
    LET askLevel2Price == ReadBytes(lpBidLevel1Volume.rest, 11) IN IF ~askLevel2Price.ok THEN Fail ELSE
    LET bidLevel2Price == ReadBytes(askLevel2Price.rest, 11) IN IF ~bidLevel2Price.ok THEN Fail ELSE
    LET askLevel2Volume == ReadBytes(bidLevel2Price.rest, 12) IN IF ~askLevel2Volume.ok THEN Fail ELSE
    LET bidLevel2Volume == ReadBytes(askLevel2Volume.rest, 12) IN IF ~bidLevel2Volume.ok THEN Fail ELSE
    LET lpAskLevel2Volume == ReadBytes(bidLevel2Volume.rest, 12) IN IF ~lpAskLevel2Volume.ok THEN Fail ELSE
    LET lpBidLevel2Volume == ReadBytes(lpAskLevel2Volume.rest, 12) IN IF ~lpBidLevel2Volume.ok THEN Fail ELSE
    LET askLevel3Price == ReadBytes(lpBidLevel2Volume.rest, 11) IN IF ~askLevel3Price.ok THEN Fail ELSE
    LET bidLevel3Price == ReadBytes(askLevel3Price.rest, 11) IN IF ~bidLevel3Price.ok THEN Fail ELSE
    LET askLevel3Volume == ReadBytes(bidLevel3Price.rest, 12) IN IF ~askLevel3Volume.ok THEN Fail ELSE
    LET bidLevel3Volume == ReadBytes(askLevel3Volume.rest, 12) IN IF ~bidLevel3Volume.ok THEN Fail ELSE
    LET lpAskLevel3Volume == ReadBytes(bidLevel3Volume.rest, 12) IN IF ~lpAskLevel3Volume.ok THEN Fail ELSE
    LET lpBidLevel3Volume == ReadBytes(lpAskLevel3Volume.rest, 12) IN IF ~lpBidLevel3Volume.ok THEN Fail ELSE
    LET askLevel4Price == ReadBytes(lpBidLevel3Volume.rest, 11) IN IF ~askLevel4Price.ok THEN Fail ELSE
    LET bidLevel4Price == ReadBytes(askLevel4Price.rest, 11) IN IF ~bidLevel4Price.ok THEN Fail ELSE
    LET askLevel4Volume == ReadBytes(bidLevel4Price.rest, 12) IN IF ~askLevel4Volume.ok THEN Fail ELSE
    LET bidLevel4Volume == ReadBytes(askLevel4Volume.rest, 12) IN IF ~bidLevel4Volume.ok THEN Fail ELSE
    LET lpAskLevel4Volume == ReadBytes(bidLevel4Volume.rest, 12) IN IF ~lpAskLevel4Volume.ok THEN Fail ELSE
    LET lpBidLevel4Volume == ReadBytes(lpAskLevel4Volume.rest, 12) IN IF ~lpBidLevel4Volume.ok THEN Fail ELSE
    LET askLevel5Price == ReadBytes(lpBidLevel4Volume.rest, 11) IN IF ~askLevel5Price.ok THEN Fail ELSE
    LET bidLevel5Price == ReadBytes(askLevel5Price.rest, 11) IN IF ~bidLevel5Price.ok THEN Fail ELSE
    LET askLevel5Volume == ReadBytes(bidLevel5Price.rest, 12) IN IF ~askLevel5Volume.ok THEN Fail ELSE
    LET bidLevel5Volume == ReadBytes(askLevel5Volume.rest, 12) IN IF ~bidLevel5Volume.ok THEN Fail ELSE
    LET lpAskLevel5Volume == ReadBytes(bidLevel5Volume.rest, 12) IN IF ~lpAskLevel5Volume.ok THEN Fail ELSE
    LET lpBidLevel5Volume == ReadBytes(lpAskLevel5Volume.rest, 12) IN IF ~lpBidLevel5Volume.ok THEN Fail ELSE
    LET askLevel6Price == ReadBytes(lpBidLevel5Volume.rest, 11) IN IF ~askLevel6Price.ok THEN Fail ELSE
    LET bidLevel6Price == ReadBytes(askLevel6Price.rest, 11) IN IF ~bidLevel6Price.ok THEN Fail ELSE
    LET askLevel6Volume == ReadBytes(bidLevel6Price.rest, 12) IN IF ~askLevel6Volume.ok THEN Fail ELSE
    LET bidLevel6Volume == ReadBytes(askLevel6Volume.rest, 12) IN IF ~bidLevel6Volume.ok THEN Fail ELSE
    LET lpAskLevel6Volume == ReadBytes(bidLevel6Volume.rest, 12) IN IF ~lpAskLevel6Volume.ok THEN Fail ELSE
    LET lpBidLevel6Volume == ReadBytes(lpAskLevel6Volume.rest, 12) IN IF ~lpBidLevel6Volume.ok THEN Fail ELSE
    LET askLevel7Price == ReadBytes(lpBidLevel6Volume.rest, 11) IN IF ~askLevel7Price.ok THEN Fail ELSE
    LET bidLevel7Price == ReadBytes(askLevel7Price.rest, 11) IN IF ~bidLevel7Price.ok THEN Fail ELSE
    LET askLevel7Volume == ReadBytes(bidLevel7Price.rest, 12) IN IF ~askLevel7Volume.ok THEN Fail ELSE
    LET bidLevel7Volume == ReadBytes(askLevel7Volume.rest, 12) IN IF ~bidLevel7Volume.ok THEN Fail ELSE
    LET lpAskLevel7Volume == ReadBytes(bidLevel7Volume.rest, 12) IN IF ~lpAskLevel7Volume.ok THEN Fail ELSE
    LET lpBidLevel7Volume == ReadBytes(lpAskLevel7Volume.rest, 12) IN IF ~lpBidLevel7Volume.ok THEN Fail ELSE
    LET askLevel8Price == ReadBytes(lpBidLevel7Volume.rest, 11) IN IF ~askLevel8Price.ok THEN Fail ELSE
    LET bidLevel8Price == ReadBytes(askLevel8Price.rest, 11) IN IF ~bidLevel8Price.ok THEN Fail ELSE
    LET askLevel8Volume == ReadBytes(bidLevel8Price.rest, 12) IN IF ~askLevel8Volume.ok THEN Fail ELSE
    LET bidLevel8Volume == ReadBytes(askLevel8Volume.rest, 12) IN IF ~bidLevel8Volume.ok THEN Fail ELSE
    LET lpAskLevel8Volume == ReadBytes(bidLevel8Volume.rest, 12) IN IF ~lpAskLevel8Volume.ok THEN Fail ELSE
    LET lpBidLevel8Volume == ReadBytes(lpAskLevel8Volume.rest, 12) IN IF ~lpBidLevel8Volume.ok THEN Fail ELSE
    LET askLevel9Price == ReadBytes(lpBidLevel8Volume.rest, 11) IN IF ~askLevel9Price.ok THEN Fail ELSE
    LET bidLevel9Price == ReadBytes(askLevel9Price.rest, 11) IN IF ~bidLevel9Price.ok THEN Fail ELSE
    LET askLevel9Volume == ReadBytes(bidLevel9Price.rest, 12) IN IF ~askLevel9Volume.ok THEN Fail ELSE
    LET bidLevel9Volume == ReadBytes(askLevel9Volume.rest, 12) IN IF ~bidLevel9Volume.ok THEN Fail ELSE
    LET lpAskLevel9Volume == ReadBytes(bidLevel9Volume.rest, 12) IN IF ~lpAskLevel9Volume.ok THEN Fail ELSE
    LET lpBidLevel9Volume == ReadBytes(lpAskLevel9Volume.rest, 12) IN IF ~lpBidLevel9Volume.ok THEN Fail ELSE
    LET askLevel10Price == ReadBytes(lpBidLevel9Volume.rest, 11) IN IF ~askLevel10Price.ok THEN Fail ELSE
    LET bidLevel10Price == ReadBytes(askLevel10Price.rest, 11) IN IF ~bidLevel10Price.ok THEN Fail ELSE
    LET askLevel10Volume == ReadBytes(bidLevel10Price.rest, 12) IN IF ~askLevel10Volume.ok THEN Fail ELSE
    LET bidLevel10Volume == ReadBytes(askLevel10Volume.rest, 12) IN IF ~bidLevel10Volume.ok THEN Fail ELSE
    LET lpAskLevel10Volume == ReadBytes(bidLevel10Volume.rest, 12) IN IF ~lpAskLevel10Volume.ok THEN Fail ELSE
    LET lpBidLevel10Volume == ReadBytes(lpAskLevel10Volume.rest, 12) IN IF ~lpBidLevel10Volume.ok THEN Fail ELSE
    LET totalAskVolume == ReadBytes(lpBidLevel10Volume.rest, 12) IN IF ~totalAskVolume.ok THEN Fail ELSE
    LET totalBidVolume == ReadBytes(totalAskVolume.rest, 12) IN IF ~totalBidVolume.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(totalBidVolume.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber         |-> messageSequenceNumber.value,
         boardId                       |-> boardId.value,
         sessionId                     |-> sessionId.value,
         isinCode                      |-> isinCode.value,
         aDesignatedNumberForAnIssue   |-> aDesignatedNumberForAnIssue.value,
         processingTimeOfTradingSystem |-> processingTimeOfTradingSystem.value,
         tradingPrice                  |-> tradingPrice.value,
         tradingVolume                 |-> tradingVolume.value,
         openingPriceLong              |-> openingPriceLong.value,
         todaysHigh                    |-> todaysHigh.value,
         todaysLow                     |-> todaysLow.value,
         previousPrice                 |-> previousPrice.value,
         accumulatedTradingVolume      |-> accumulatedTradingVolume.value,
         accumulatedTradingValueLong   |-> accumulatedTradingValueLong.value,
         finalAskBidTypeCode           |-> finalAskBidTypeCode.value,
         lpHoldingQuantity             |-> lpHoldingQuantity.value,
         askLevel1Price                |-> askLevel1Price.value,
         bidLevel1Price                |-> bidLevel1Price.value,
         askLevel1Volume               |-> askLevel1Volume.value,
         bidLevel1Volume               |-> bidLevel1Volume.value,
         lpAskLevel1Volume             |-> lpAskLevel1Volume.value,
         lpBidLevel1Volume             |-> lpBidLevel1Volume.value,
         askLevel2Price                |-> askLevel2Price.value,
         bidLevel2Price                |-> bidLevel2Price.value,
         askLevel2Volume               |-> askLevel2Volume.value,
         bidLevel2Volume               |-> bidLevel2Volume.value,
         lpAskLevel2Volume             |-> lpAskLevel2Volume.value,
         lpBidLevel2Volume             |-> lpBidLevel2Volume.value,
         askLevel3Price                |-> askLevel3Price.value,
         bidLevel3Price                |-> bidLevel3Price.value,
         askLevel3Volume               |-> askLevel3Volume.value,
         bidLevel3Volume               |-> bidLevel3Volume.value,
         lpAskLevel3Volume             |-> lpAskLevel3Volume.value,
         lpBidLevel3Volume             |-> lpBidLevel3Volume.value,
         askLevel4Price                |-> askLevel4Price.value,
         bidLevel4Price                |-> bidLevel4Price.value,
         askLevel4Volume               |-> askLevel4Volume.value,
         bidLevel4Volume               |-> bidLevel4Volume.value,
         lpAskLevel4Volume             |-> lpAskLevel4Volume.value,
         lpBidLevel4Volume             |-> lpBidLevel4Volume.value,
         askLevel5Price                |-> askLevel5Price.value,
         bidLevel5Price                |-> bidLevel5Price.value,
         askLevel5Volume               |-> askLevel5Volume.value,
         bidLevel5Volume               |-> bidLevel5Volume.value,
         lpAskLevel5Volume             |-> lpAskLevel5Volume.value,
         lpBidLevel5Volume             |-> lpBidLevel5Volume.value,
         askLevel6Price                |-> askLevel6Price.value,
         bidLevel6Price                |-> bidLevel6Price.value,
         askLevel6Volume               |-> askLevel6Volume.value,
         bidLevel6Volume               |-> bidLevel6Volume.value,
         lpAskLevel6Volume             |-> lpAskLevel6Volume.value,
         lpBidLevel6Volume             |-> lpBidLevel6Volume.value,
         askLevel7Price                |-> askLevel7Price.value,
         bidLevel7Price                |-> bidLevel7Price.value,
         askLevel7Volume               |-> askLevel7Volume.value,
         bidLevel7Volume               |-> bidLevel7Volume.value,
         lpAskLevel7Volume             |-> lpAskLevel7Volume.value,
         lpBidLevel7Volume             |-> lpBidLevel7Volume.value,
         askLevel8Price                |-> askLevel8Price.value,
         bidLevel8Price                |-> bidLevel8Price.value,
         askLevel8Volume               |-> askLevel8Volume.value,
         bidLevel8Volume               |-> bidLevel8Volume.value,
         lpAskLevel8Volume             |-> lpAskLevel8Volume.value,
         lpBidLevel8Volume             |-> lpBidLevel8Volume.value,
         askLevel9Price                |-> askLevel9Price.value,
         bidLevel9Price                |-> bidLevel9Price.value,
         askLevel9Volume               |-> askLevel9Volume.value,
         bidLevel9Volume               |-> bidLevel9Volume.value,
         lpAskLevel9Volume             |-> lpAskLevel9Volume.value,
         lpBidLevel9Volume             |-> lpBidLevel9Volume.value,
         askLevel10Price               |-> askLevel10Price.value,
         bidLevel10Price               |-> bidLevel10Price.value,
         askLevel10Volume              |-> askLevel10Volume.value,
         bidLevel10Volume              |-> bidLevel10Volume.value,
         lpAskLevel10Volume            |-> lpAskLevel10Volume.value,
         lpBidLevel10Volume            |-> lpBidLevel10Volume.value,
         totalAskVolume                |-> totalAskVolume.value,
         totalBidVolume                |-> totalBidVolume.value,
         endKeyword                    |-> endKeyword.value ], endKeyword.rest)

ZeroSpotGoldOrderFilledPlusQuoteMessage ==
    [ messageSequenceNumber         |-> [i \in 1 .. 8 |-> 0],
      boardId                       |-> [i \in 1 .. 2 |-> 0],
      sessionId                     |-> [i \in 1 .. 2 |-> 0],
      isinCode                      |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue   |-> [i \in 1 .. 6 |-> 0],
      processingTimeOfTradingSystem |-> [i \in 1 .. 12 |-> 0],
      tradingPrice                  |-> [i \in 1 .. 11 |-> 0],
      tradingVolume                 |-> [i \in 1 .. 10 |-> 0],
      openingPriceLong              |-> [i \in 1 .. 11 |-> 0],
      todaysHigh                    |-> [i \in 1 .. 11 |-> 0],
      todaysLow                     |-> [i \in 1 .. 11 |-> 0],
      previousPrice                 |-> [i \in 1 .. 11 |-> 0],
      accumulatedTradingVolume      |-> [i \in 1 .. 12 |-> 0],
      accumulatedTradingValueLong   |-> [i \in 1 .. 22 |-> 0],
      finalAskBidTypeCode           |-> [i \in 1 .. 1 |-> 0],
      lpHoldingQuantity             |-> [i \in 1 .. 15 |-> 0],
      askLevel1Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel1Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel1Volume               |-> [i \in 1 .. 12 |-> 0],
      bidLevel1Volume               |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel1Volume             |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel1Volume             |-> [i \in 1 .. 12 |-> 0],
      askLevel2Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel2Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel2Volume               |-> [i \in 1 .. 12 |-> 0],
      bidLevel2Volume               |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel2Volume             |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel2Volume             |-> [i \in 1 .. 12 |-> 0],
      askLevel3Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel3Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel3Volume               |-> [i \in 1 .. 12 |-> 0],
      bidLevel3Volume               |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel3Volume             |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel3Volume             |-> [i \in 1 .. 12 |-> 0],
      askLevel4Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel4Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel4Volume               |-> [i \in 1 .. 12 |-> 0],
      bidLevel4Volume               |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel4Volume             |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel4Volume             |-> [i \in 1 .. 12 |-> 0],
      askLevel5Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel5Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel5Volume               |-> [i \in 1 .. 12 |-> 0],
      bidLevel5Volume               |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel5Volume             |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel5Volume             |-> [i \in 1 .. 12 |-> 0],
      askLevel6Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel6Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel6Volume               |-> [i \in 1 .. 12 |-> 0],
      bidLevel6Volume               |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel6Volume             |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel6Volume             |-> [i \in 1 .. 12 |-> 0],
      askLevel7Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel7Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel7Volume               |-> [i \in 1 .. 12 |-> 0],
      bidLevel7Volume               |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel7Volume             |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel7Volume             |-> [i \in 1 .. 12 |-> 0],
      askLevel8Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel8Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel8Volume               |-> [i \in 1 .. 12 |-> 0],
      bidLevel8Volume               |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel8Volume             |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel8Volume             |-> [i \in 1 .. 12 |-> 0],
      askLevel9Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel9Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel9Volume               |-> [i \in 1 .. 12 |-> 0],
      bidLevel9Volume               |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel9Volume             |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel9Volume             |-> [i \in 1 .. 12 |-> 0],
      askLevel10Price               |-> [i \in 1 .. 11 |-> 0],
      bidLevel10Price               |-> [i \in 1 .. 11 |-> 0],
      askLevel10Volume              |-> [i \in 1 .. 12 |-> 0],
      bidLevel10Volume              |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel10Volume            |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel10Volume            |-> [i \in 1 .. 12 |-> 0],
      totalAskVolume                |-> [i \in 1 .. 12 |-> 0],
      totalBidVolume                |-> [i \in 1 .. 12 |-> 0],
      endKeyword                    |-> [i \in 1 .. 1 |-> 0] ]

(* Spot Gold Order Filled Plus Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedSpotGoldOrderFilledPlusQuoteMessage ==
    { ZeroSpotGoldOrderFilledPlusQuoteMessage }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.processingTimeOfTradingSystem = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.tradingPrice = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.tradingVolume = one] : one \in Sample(10) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.openingPriceLong = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.todaysHigh = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.todaysLow = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.previousPrice = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.accumulatedTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.accumulatedTradingValueLong = one] : one \in Sample(22) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.finalAskBidTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.lpHoldingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.askLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.bidLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.askLevel1Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.bidLevel1Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.lpAskLevel1Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.lpBidLevel1Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.askLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.bidLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.askLevel2Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.bidLevel2Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.lpAskLevel2Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.lpBidLevel2Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.askLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.bidLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.askLevel3Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.bidLevel3Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.lpAskLevel3Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.lpBidLevel3Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.askLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.bidLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.askLevel4Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.bidLevel4Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.lpAskLevel4Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.lpBidLevel4Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.askLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.bidLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.askLevel5Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.bidLevel5Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.lpAskLevel5Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.lpBidLevel5Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.askLevel6Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.bidLevel6Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.askLevel6Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.bidLevel6Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.lpAskLevel6Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.lpBidLevel6Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.askLevel7Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.bidLevel7Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.askLevel7Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.bidLevel7Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.lpAskLevel7Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.lpBidLevel7Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.askLevel8Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.bidLevel8Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.askLevel8Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.bidLevel8Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.lpAskLevel8Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.lpBidLevel8Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.askLevel9Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.bidLevel9Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.askLevel9Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.bidLevel9Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.lpAskLevel9Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.lpBidLevel9Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.askLevel10Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.bidLevel10Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.askLevel10Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.bidLevel10Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.lpAskLevel10Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.lpBidLevel10Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.totalAskVolume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.totalBidVolume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldOrderFilledPlusQuoteMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Spot Gold Market Operation Ts Plus Quote Message: 810 bytes             *)
(***************************************************************************)

SpotGoldMarketOperationTsPlusQuoteMessage ==
    [ messageSequenceNumber         : Sample(8),
      boardId                       : Sample(2),
      sessionId                     : Sample(2),
      isinCode                      : Sample(12),
      aDesignatedNumberForAnIssue   : Sample(6),
      processingTimeOfTradingSystem : Sample(12),
      boardEventId                  : Sample(3),
      startTimeOfABoardEvent        : Sample(9),
      boardEventGroupCode           : Sample(5),
      tradingHaltReasonCode         : Sample(3),
      askLevel1Price                : Sample(11),
      bidLevel1Price                : Sample(11),
      askLevel1Volume               : Sample(12),
      bidLevel1Volume               : Sample(12),
      lpAskLevel1Volume             : Sample(12),
      lpBidLevel1Volume             : Sample(12),
      askLevel2Price                : Sample(11),
      bidLevel2Price                : Sample(11),
      askLevel2Volume               : Sample(12),
      bidLevel2Volume               : Sample(12),
      lpAskLevel2Volume             : Sample(12),
      lpBidLevel2Volume             : Sample(12),
      askLevel3Price                : Sample(11),
      bidLevel3Price                : Sample(11),
      askLevel3Volume               : Sample(12),
      bidLevel3Volume               : Sample(12),
      lpAskLevel3Volume             : Sample(12),
      lpBidLevel3Volume             : Sample(12),
      askLevel4Price                : Sample(11),
      bidLevel4Price                : Sample(11),
      askLevel4Volume               : Sample(12),
      bidLevel4Volume               : Sample(12),
      lpAskLevel4Volume             : Sample(12),
      lpBidLevel4Volume             : Sample(12),
      askLevel5Price                : Sample(11),
      bidLevel5Price                : Sample(11),
      askLevel5Volume               : Sample(12),
      bidLevel5Volume               : Sample(12),
      lpAskLevel5Volume             : Sample(12),
      lpBidLevel5Volume             : Sample(12),
      askLevel6Price                : Sample(11),
      bidLevel6Price                : Sample(11),
      askLevel6Volume               : Sample(12),
      bidLevel6Volume               : Sample(12),
      lpAskLevel6Volume             : Sample(12),
      lpBidLevel6Volume             : Sample(12),
      askLevel7Price                : Sample(11),
      bidLevel7Price                : Sample(11),
      askLevel7Volume               : Sample(12),
      bidLevel7Volume               : Sample(12),
      lpAskLevel7Volume             : Sample(12),
      lpBidLevel7Volume             : Sample(12),
      askLevel8Price                : Sample(11),
      bidLevel8Price                : Sample(11),
      askLevel8Volume               : Sample(12),
      bidLevel8Volume               : Sample(12),
      lpAskLevel8Volume             : Sample(12),
      lpBidLevel8Volume             : Sample(12),
      askLevel9Price                : Sample(11),
      bidLevel9Price                : Sample(11),
      askLevel9Volume               : Sample(12),
      bidLevel9Volume               : Sample(12),
      lpAskLevel9Volume             : Sample(12),
      lpBidLevel9Volume             : Sample(12),
      askLevel10Price               : Sample(11),
      bidLevel10Price               : Sample(11),
      askLevel10Volume              : Sample(12),
      bidLevel10Volume              : Sample(12),
      lpAskLevel10Volume            : Sample(12),
      lpBidLevel10Volume            : Sample(12),
      totalAskVolume                : Sample(12),
      totalBidVolume                : Sample(12),
      estimatedTradingPrice         : Sample(11),
      estimatedTradingVolume        : Sample(12),
      endKeyword                    : Sample(1) ]

EncodeSpotGoldMarketOperationTsPlusQuoteMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.sessionId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.processingTimeOfTradingSystem
        \o message.boardEventId
        \o message.startTimeOfABoardEvent
        \o message.boardEventGroupCode
        \o message.tradingHaltReasonCode
        \o message.askLevel1Price
        \o message.bidLevel1Price
        \o message.askLevel1Volume
        \o message.bidLevel1Volume
        \o message.lpAskLevel1Volume
        \o message.lpBidLevel1Volume
        \o message.askLevel2Price
        \o message.bidLevel2Price
        \o message.askLevel2Volume
        \o message.bidLevel2Volume
        \o message.lpAskLevel2Volume
        \o message.lpBidLevel2Volume
        \o message.askLevel3Price
        \o message.bidLevel3Price
        \o message.askLevel3Volume
        \o message.bidLevel3Volume
        \o message.lpAskLevel3Volume
        \o message.lpBidLevel3Volume
        \o message.askLevel4Price
        \o message.bidLevel4Price
        \o message.askLevel4Volume
        \o message.bidLevel4Volume
        \o message.lpAskLevel4Volume
        \o message.lpBidLevel4Volume
        \o message.askLevel5Price
        \o message.bidLevel5Price
        \o message.askLevel5Volume
        \o message.bidLevel5Volume
        \o message.lpAskLevel5Volume
        \o message.lpBidLevel5Volume
        \o message.askLevel6Price
        \o message.bidLevel6Price
        \o message.askLevel6Volume
        \o message.bidLevel6Volume
        \o message.lpAskLevel6Volume
        \o message.lpBidLevel6Volume
        \o message.askLevel7Price
        \o message.bidLevel7Price
        \o message.askLevel7Volume
        \o message.bidLevel7Volume
        \o message.lpAskLevel7Volume
        \o message.lpBidLevel7Volume
        \o message.askLevel8Price
        \o message.bidLevel8Price
        \o message.askLevel8Volume
        \o message.bidLevel8Volume
        \o message.lpAskLevel8Volume
        \o message.lpBidLevel8Volume
        \o message.askLevel9Price
        \o message.bidLevel9Price
        \o message.askLevel9Volume
        \o message.bidLevel9Volume
        \o message.lpAskLevel9Volume
        \o message.lpBidLevel9Volume
        \o message.askLevel10Price
        \o message.bidLevel10Price
        \o message.askLevel10Volume
        \o message.bidLevel10Volume
        \o message.lpAskLevel10Volume
        \o message.lpBidLevel10Volume
        \o message.totalAskVolume
        \o message.totalBidVolume
        \o message.estimatedTradingPrice
        \o message.estimatedTradingVolume
        \o message.endKeyword

DecodeSpotGoldMarketOperationTsPlusQuoteMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(boardId.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(sessionId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET processingTimeOfTradingSystem == ReadBytes(aDesignatedNumberForAnIssue.rest, 12) IN IF ~processingTimeOfTradingSystem.ok THEN Fail ELSE
    LET boardEventId == ReadBytes(processingTimeOfTradingSystem.rest, 3) IN IF ~boardEventId.ok THEN Fail ELSE
    LET startTimeOfABoardEvent == ReadBytes(boardEventId.rest, 9) IN IF ~startTimeOfABoardEvent.ok THEN Fail ELSE
    LET boardEventGroupCode == ReadBytes(startTimeOfABoardEvent.rest, 5) IN IF ~boardEventGroupCode.ok THEN Fail ELSE
    LET tradingHaltReasonCode == ReadBytes(boardEventGroupCode.rest, 3) IN IF ~tradingHaltReasonCode.ok THEN Fail ELSE
    LET askLevel1Price == ReadBytes(tradingHaltReasonCode.rest, 11) IN IF ~askLevel1Price.ok THEN Fail ELSE
    LET bidLevel1Price == ReadBytes(askLevel1Price.rest, 11) IN IF ~bidLevel1Price.ok THEN Fail ELSE
    LET askLevel1Volume == ReadBytes(bidLevel1Price.rest, 12) IN IF ~askLevel1Volume.ok THEN Fail ELSE
    LET bidLevel1Volume == ReadBytes(askLevel1Volume.rest, 12) IN IF ~bidLevel1Volume.ok THEN Fail ELSE
    LET lpAskLevel1Volume == ReadBytes(bidLevel1Volume.rest, 12) IN IF ~lpAskLevel1Volume.ok THEN Fail ELSE
    LET lpBidLevel1Volume == ReadBytes(lpAskLevel1Volume.rest, 12) IN IF ~lpBidLevel1Volume.ok THEN Fail ELSE
    LET askLevel2Price == ReadBytes(lpBidLevel1Volume.rest, 11) IN IF ~askLevel2Price.ok THEN Fail ELSE
    LET bidLevel2Price == ReadBytes(askLevel2Price.rest, 11) IN IF ~bidLevel2Price.ok THEN Fail ELSE
    LET askLevel2Volume == ReadBytes(bidLevel2Price.rest, 12) IN IF ~askLevel2Volume.ok THEN Fail ELSE
    LET bidLevel2Volume == ReadBytes(askLevel2Volume.rest, 12) IN IF ~bidLevel2Volume.ok THEN Fail ELSE
    LET lpAskLevel2Volume == ReadBytes(bidLevel2Volume.rest, 12) IN IF ~lpAskLevel2Volume.ok THEN Fail ELSE
    LET lpBidLevel2Volume == ReadBytes(lpAskLevel2Volume.rest, 12) IN IF ~lpBidLevel2Volume.ok THEN Fail ELSE
    LET askLevel3Price == ReadBytes(lpBidLevel2Volume.rest, 11) IN IF ~askLevel3Price.ok THEN Fail ELSE
    LET bidLevel3Price == ReadBytes(askLevel3Price.rest, 11) IN IF ~bidLevel3Price.ok THEN Fail ELSE
    LET askLevel3Volume == ReadBytes(bidLevel3Price.rest, 12) IN IF ~askLevel3Volume.ok THEN Fail ELSE
    LET bidLevel3Volume == ReadBytes(askLevel3Volume.rest, 12) IN IF ~bidLevel3Volume.ok THEN Fail ELSE
    LET lpAskLevel3Volume == ReadBytes(bidLevel3Volume.rest, 12) IN IF ~lpAskLevel3Volume.ok THEN Fail ELSE
    LET lpBidLevel3Volume == ReadBytes(lpAskLevel3Volume.rest, 12) IN IF ~lpBidLevel3Volume.ok THEN Fail ELSE
    LET askLevel4Price == ReadBytes(lpBidLevel3Volume.rest, 11) IN IF ~askLevel4Price.ok THEN Fail ELSE
    LET bidLevel4Price == ReadBytes(askLevel4Price.rest, 11) IN IF ~bidLevel4Price.ok THEN Fail ELSE
    LET askLevel4Volume == ReadBytes(bidLevel4Price.rest, 12) IN IF ~askLevel4Volume.ok THEN Fail ELSE
    LET bidLevel4Volume == ReadBytes(askLevel4Volume.rest, 12) IN IF ~bidLevel4Volume.ok THEN Fail ELSE
    LET lpAskLevel4Volume == ReadBytes(bidLevel4Volume.rest, 12) IN IF ~lpAskLevel4Volume.ok THEN Fail ELSE
    LET lpBidLevel4Volume == ReadBytes(lpAskLevel4Volume.rest, 12) IN IF ~lpBidLevel4Volume.ok THEN Fail ELSE
    LET askLevel5Price == ReadBytes(lpBidLevel4Volume.rest, 11) IN IF ~askLevel5Price.ok THEN Fail ELSE
    LET bidLevel5Price == ReadBytes(askLevel5Price.rest, 11) IN IF ~bidLevel5Price.ok THEN Fail ELSE
    LET askLevel5Volume == ReadBytes(bidLevel5Price.rest, 12) IN IF ~askLevel5Volume.ok THEN Fail ELSE
    LET bidLevel5Volume == ReadBytes(askLevel5Volume.rest, 12) IN IF ~bidLevel5Volume.ok THEN Fail ELSE
    LET lpAskLevel5Volume == ReadBytes(bidLevel5Volume.rest, 12) IN IF ~lpAskLevel5Volume.ok THEN Fail ELSE
    LET lpBidLevel5Volume == ReadBytes(lpAskLevel5Volume.rest, 12) IN IF ~lpBidLevel5Volume.ok THEN Fail ELSE
    LET askLevel6Price == ReadBytes(lpBidLevel5Volume.rest, 11) IN IF ~askLevel6Price.ok THEN Fail ELSE
    LET bidLevel6Price == ReadBytes(askLevel6Price.rest, 11) IN IF ~bidLevel6Price.ok THEN Fail ELSE
    LET askLevel6Volume == ReadBytes(bidLevel6Price.rest, 12) IN IF ~askLevel6Volume.ok THEN Fail ELSE
    LET bidLevel6Volume == ReadBytes(askLevel6Volume.rest, 12) IN IF ~bidLevel6Volume.ok THEN Fail ELSE
    LET lpAskLevel6Volume == ReadBytes(bidLevel6Volume.rest, 12) IN IF ~lpAskLevel6Volume.ok THEN Fail ELSE
    LET lpBidLevel6Volume == ReadBytes(lpAskLevel6Volume.rest, 12) IN IF ~lpBidLevel6Volume.ok THEN Fail ELSE
    LET askLevel7Price == ReadBytes(lpBidLevel6Volume.rest, 11) IN IF ~askLevel7Price.ok THEN Fail ELSE
    LET bidLevel7Price == ReadBytes(askLevel7Price.rest, 11) IN IF ~bidLevel7Price.ok THEN Fail ELSE
    LET askLevel7Volume == ReadBytes(bidLevel7Price.rest, 12) IN IF ~askLevel7Volume.ok THEN Fail ELSE
    LET bidLevel7Volume == ReadBytes(askLevel7Volume.rest, 12) IN IF ~bidLevel7Volume.ok THEN Fail ELSE
    LET lpAskLevel7Volume == ReadBytes(bidLevel7Volume.rest, 12) IN IF ~lpAskLevel7Volume.ok THEN Fail ELSE
    LET lpBidLevel7Volume == ReadBytes(lpAskLevel7Volume.rest, 12) IN IF ~lpBidLevel7Volume.ok THEN Fail ELSE
    LET askLevel8Price == ReadBytes(lpBidLevel7Volume.rest, 11) IN IF ~askLevel8Price.ok THEN Fail ELSE
    LET bidLevel8Price == ReadBytes(askLevel8Price.rest, 11) IN IF ~bidLevel8Price.ok THEN Fail ELSE
    LET askLevel8Volume == ReadBytes(bidLevel8Price.rest, 12) IN IF ~askLevel8Volume.ok THEN Fail ELSE
    LET bidLevel8Volume == ReadBytes(askLevel8Volume.rest, 12) IN IF ~bidLevel8Volume.ok THEN Fail ELSE
    LET lpAskLevel8Volume == ReadBytes(bidLevel8Volume.rest, 12) IN IF ~lpAskLevel8Volume.ok THEN Fail ELSE
    LET lpBidLevel8Volume == ReadBytes(lpAskLevel8Volume.rest, 12) IN IF ~lpBidLevel8Volume.ok THEN Fail ELSE
    LET askLevel9Price == ReadBytes(lpBidLevel8Volume.rest, 11) IN IF ~askLevel9Price.ok THEN Fail ELSE
    LET bidLevel9Price == ReadBytes(askLevel9Price.rest, 11) IN IF ~bidLevel9Price.ok THEN Fail ELSE
    LET askLevel9Volume == ReadBytes(bidLevel9Price.rest, 12) IN IF ~askLevel9Volume.ok THEN Fail ELSE
    LET bidLevel9Volume == ReadBytes(askLevel9Volume.rest, 12) IN IF ~bidLevel9Volume.ok THEN Fail ELSE
    LET lpAskLevel9Volume == ReadBytes(bidLevel9Volume.rest, 12) IN IF ~lpAskLevel9Volume.ok THEN Fail ELSE
    LET lpBidLevel9Volume == ReadBytes(lpAskLevel9Volume.rest, 12) IN IF ~lpBidLevel9Volume.ok THEN Fail ELSE
    LET askLevel10Price == ReadBytes(lpBidLevel9Volume.rest, 11) IN IF ~askLevel10Price.ok THEN Fail ELSE
    LET bidLevel10Price == ReadBytes(askLevel10Price.rest, 11) IN IF ~bidLevel10Price.ok THEN Fail ELSE
    LET askLevel10Volume == ReadBytes(bidLevel10Price.rest, 12) IN IF ~askLevel10Volume.ok THEN Fail ELSE
    LET bidLevel10Volume == ReadBytes(askLevel10Volume.rest, 12) IN IF ~bidLevel10Volume.ok THEN Fail ELSE
    LET lpAskLevel10Volume == ReadBytes(bidLevel10Volume.rest, 12) IN IF ~lpAskLevel10Volume.ok THEN Fail ELSE
    LET lpBidLevel10Volume == ReadBytes(lpAskLevel10Volume.rest, 12) IN IF ~lpBidLevel10Volume.ok THEN Fail ELSE
    LET totalAskVolume == ReadBytes(lpBidLevel10Volume.rest, 12) IN IF ~totalAskVolume.ok THEN Fail ELSE
    LET totalBidVolume == ReadBytes(totalAskVolume.rest, 12) IN IF ~totalBidVolume.ok THEN Fail ELSE
    LET estimatedTradingPrice == ReadBytes(totalBidVolume.rest, 11) IN IF ~estimatedTradingPrice.ok THEN Fail ELSE
    LET estimatedTradingVolume == ReadBytes(estimatedTradingPrice.rest, 12) IN IF ~estimatedTradingVolume.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(estimatedTradingVolume.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber         |-> messageSequenceNumber.value,
         boardId                       |-> boardId.value,
         sessionId                     |-> sessionId.value,
         isinCode                      |-> isinCode.value,
         aDesignatedNumberForAnIssue   |-> aDesignatedNumberForAnIssue.value,
         processingTimeOfTradingSystem |-> processingTimeOfTradingSystem.value,
         boardEventId                  |-> boardEventId.value,
         startTimeOfABoardEvent        |-> startTimeOfABoardEvent.value,
         boardEventGroupCode           |-> boardEventGroupCode.value,
         tradingHaltReasonCode         |-> tradingHaltReasonCode.value,
         askLevel1Price                |-> askLevel1Price.value,
         bidLevel1Price                |-> bidLevel1Price.value,
         askLevel1Volume               |-> askLevel1Volume.value,
         bidLevel1Volume               |-> bidLevel1Volume.value,
         lpAskLevel1Volume             |-> lpAskLevel1Volume.value,
         lpBidLevel1Volume             |-> lpBidLevel1Volume.value,
         askLevel2Price                |-> askLevel2Price.value,
         bidLevel2Price                |-> bidLevel2Price.value,
         askLevel2Volume               |-> askLevel2Volume.value,
         bidLevel2Volume               |-> bidLevel2Volume.value,
         lpAskLevel2Volume             |-> lpAskLevel2Volume.value,
         lpBidLevel2Volume             |-> lpBidLevel2Volume.value,
         askLevel3Price                |-> askLevel3Price.value,
         bidLevel3Price                |-> bidLevel3Price.value,
         askLevel3Volume               |-> askLevel3Volume.value,
         bidLevel3Volume               |-> bidLevel3Volume.value,
         lpAskLevel3Volume             |-> lpAskLevel3Volume.value,
         lpBidLevel3Volume             |-> lpBidLevel3Volume.value,
         askLevel4Price                |-> askLevel4Price.value,
         bidLevel4Price                |-> bidLevel4Price.value,
         askLevel4Volume               |-> askLevel4Volume.value,
         bidLevel4Volume               |-> bidLevel4Volume.value,
         lpAskLevel4Volume             |-> lpAskLevel4Volume.value,
         lpBidLevel4Volume             |-> lpBidLevel4Volume.value,
         askLevel5Price                |-> askLevel5Price.value,
         bidLevel5Price                |-> bidLevel5Price.value,
         askLevel5Volume               |-> askLevel5Volume.value,
         bidLevel5Volume               |-> bidLevel5Volume.value,
         lpAskLevel5Volume             |-> lpAskLevel5Volume.value,
         lpBidLevel5Volume             |-> lpBidLevel5Volume.value,
         askLevel6Price                |-> askLevel6Price.value,
         bidLevel6Price                |-> bidLevel6Price.value,
         askLevel6Volume               |-> askLevel6Volume.value,
         bidLevel6Volume               |-> bidLevel6Volume.value,
         lpAskLevel6Volume             |-> lpAskLevel6Volume.value,
         lpBidLevel6Volume             |-> lpBidLevel6Volume.value,
         askLevel7Price                |-> askLevel7Price.value,
         bidLevel7Price                |-> bidLevel7Price.value,
         askLevel7Volume               |-> askLevel7Volume.value,
         bidLevel7Volume               |-> bidLevel7Volume.value,
         lpAskLevel7Volume             |-> lpAskLevel7Volume.value,
         lpBidLevel7Volume             |-> lpBidLevel7Volume.value,
         askLevel8Price                |-> askLevel8Price.value,
         bidLevel8Price                |-> bidLevel8Price.value,
         askLevel8Volume               |-> askLevel8Volume.value,
         bidLevel8Volume               |-> bidLevel8Volume.value,
         lpAskLevel8Volume             |-> lpAskLevel8Volume.value,
         lpBidLevel8Volume             |-> lpBidLevel8Volume.value,
         askLevel9Price                |-> askLevel9Price.value,
         bidLevel9Price                |-> bidLevel9Price.value,
         askLevel9Volume               |-> askLevel9Volume.value,
         bidLevel9Volume               |-> bidLevel9Volume.value,
         lpAskLevel9Volume             |-> lpAskLevel9Volume.value,
         lpBidLevel9Volume             |-> lpBidLevel9Volume.value,
         askLevel10Price               |-> askLevel10Price.value,
         bidLevel10Price               |-> bidLevel10Price.value,
         askLevel10Volume              |-> askLevel10Volume.value,
         bidLevel10Volume              |-> bidLevel10Volume.value,
         lpAskLevel10Volume            |-> lpAskLevel10Volume.value,
         lpBidLevel10Volume            |-> lpBidLevel10Volume.value,
         totalAskVolume                |-> totalAskVolume.value,
         totalBidVolume                |-> totalBidVolume.value,
         estimatedTradingPrice         |-> estimatedTradingPrice.value,
         estimatedTradingVolume        |-> estimatedTradingVolume.value,
         endKeyword                    |-> endKeyword.value ], endKeyword.rest)

ZeroSpotGoldMarketOperationTsPlusQuoteMessage ==
    [ messageSequenceNumber         |-> [i \in 1 .. 8 |-> 0],
      boardId                       |-> [i \in 1 .. 2 |-> 0],
      sessionId                     |-> [i \in 1 .. 2 |-> 0],
      isinCode                      |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue   |-> [i \in 1 .. 6 |-> 0],
      processingTimeOfTradingSystem |-> [i \in 1 .. 12 |-> 0],
      boardEventId                  |-> [i \in 1 .. 3 |-> 0],
      startTimeOfABoardEvent        |-> [i \in 1 .. 9 |-> 0],
      boardEventGroupCode           |-> [i \in 1 .. 5 |-> 0],
      tradingHaltReasonCode         |-> [i \in 1 .. 3 |-> 0],
      askLevel1Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel1Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel1Volume               |-> [i \in 1 .. 12 |-> 0],
      bidLevel1Volume               |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel1Volume             |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel1Volume             |-> [i \in 1 .. 12 |-> 0],
      askLevel2Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel2Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel2Volume               |-> [i \in 1 .. 12 |-> 0],
      bidLevel2Volume               |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel2Volume             |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel2Volume             |-> [i \in 1 .. 12 |-> 0],
      askLevel3Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel3Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel3Volume               |-> [i \in 1 .. 12 |-> 0],
      bidLevel3Volume               |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel3Volume             |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel3Volume             |-> [i \in 1 .. 12 |-> 0],
      askLevel4Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel4Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel4Volume               |-> [i \in 1 .. 12 |-> 0],
      bidLevel4Volume               |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel4Volume             |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel4Volume             |-> [i \in 1 .. 12 |-> 0],
      askLevel5Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel5Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel5Volume               |-> [i \in 1 .. 12 |-> 0],
      bidLevel5Volume               |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel5Volume             |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel5Volume             |-> [i \in 1 .. 12 |-> 0],
      askLevel6Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel6Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel6Volume               |-> [i \in 1 .. 12 |-> 0],
      bidLevel6Volume               |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel6Volume             |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel6Volume             |-> [i \in 1 .. 12 |-> 0],
      askLevel7Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel7Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel7Volume               |-> [i \in 1 .. 12 |-> 0],
      bidLevel7Volume               |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel7Volume             |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel7Volume             |-> [i \in 1 .. 12 |-> 0],
      askLevel8Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel8Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel8Volume               |-> [i \in 1 .. 12 |-> 0],
      bidLevel8Volume               |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel8Volume             |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel8Volume             |-> [i \in 1 .. 12 |-> 0],
      askLevel9Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel9Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel9Volume               |-> [i \in 1 .. 12 |-> 0],
      bidLevel9Volume               |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel9Volume             |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel9Volume             |-> [i \in 1 .. 12 |-> 0],
      askLevel10Price               |-> [i \in 1 .. 11 |-> 0],
      bidLevel10Price               |-> [i \in 1 .. 11 |-> 0],
      askLevel10Volume              |-> [i \in 1 .. 12 |-> 0],
      bidLevel10Volume              |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel10Volume            |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel10Volume            |-> [i \in 1 .. 12 |-> 0],
      totalAskVolume                |-> [i \in 1 .. 12 |-> 0],
      totalBidVolume                |-> [i \in 1 .. 12 |-> 0],
      estimatedTradingPrice         |-> [i \in 1 .. 11 |-> 0],
      estimatedTradingVolume        |-> [i \in 1 .. 12 |-> 0],
      endKeyword                    |-> [i \in 1 .. 1 |-> 0] ]

(* Spot Gold Market Operation Ts Plus Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedSpotGoldMarketOperationTsPlusQuoteMessage ==
    { ZeroSpotGoldMarketOperationTsPlusQuoteMessage }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.processingTimeOfTradingSystem = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.boardEventId = one] : one \in Sample(3) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.startTimeOfABoardEvent = one] : one \in Sample(9) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.boardEventGroupCode = one] : one \in Sample(5) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.tradingHaltReasonCode = one] : one \in Sample(3) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.askLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.bidLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.askLevel1Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.bidLevel1Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.lpAskLevel1Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.lpBidLevel1Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.askLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.bidLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.askLevel2Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.bidLevel2Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.lpAskLevel2Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.lpBidLevel2Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.askLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.bidLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.askLevel3Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.bidLevel3Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.lpAskLevel3Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.lpBidLevel3Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.askLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.bidLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.askLevel4Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.bidLevel4Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.lpAskLevel4Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.lpBidLevel4Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.askLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.bidLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.askLevel5Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.bidLevel5Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.lpAskLevel5Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.lpBidLevel5Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.askLevel6Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.bidLevel6Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.askLevel6Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.bidLevel6Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.lpAskLevel6Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.lpBidLevel6Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.askLevel7Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.bidLevel7Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.askLevel7Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.bidLevel7Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.lpAskLevel7Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.lpBidLevel7Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.askLevel8Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.bidLevel8Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.askLevel8Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.bidLevel8Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.lpAskLevel8Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.lpBidLevel8Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.askLevel9Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.bidLevel9Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.askLevel9Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.bidLevel9Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.lpAskLevel9Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.lpBidLevel9Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.askLevel10Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.bidLevel10Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.askLevel10Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.bidLevel10Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.lpAskLevel10Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.lpBidLevel10Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.totalAskVolume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.totalBidVolume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.estimatedTradingPrice = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.estimatedTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationTsPlusQuoteMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Spot Gold Snapshot Message: 849 bytes                                   *)
(***************************************************************************)

SpotGoldSnapshotMessage ==
    [ boardId                     : Sample(2),
      sessionId                   : Sample(2),
      isinCode                    : Sample(12),
      aDesignatedNumberForAnIssue : Sample(6),
      currentPrice                : Sample(11),
      openingPriceLong            : Sample(11),
      todaysHigh                  : Sample(11),
      todaysLow                   : Sample(11),
      accumulatedTradingVolume    : Sample(12),
      accumulatedTradingValueLong : Sample(22),
      tradingHalt                 : Sample(1),
      askLevel1Price              : Sample(11),
      bidLevel1Price              : Sample(11),
      askLevel1Volume             : Sample(12),
      bidLevel1Volume             : Sample(12),
      lpAskLevel1Volume           : Sample(12),
      lpBidLevel1Volume           : Sample(12),
      askLevel2Price              : Sample(11),
      bidLevel2Price              : Sample(11),
      askLevel2Volume             : Sample(12),
      bidLevel2Volume             : Sample(12),
      lpAskLevel2Volume           : Sample(12),
      lpBidLevel2Volume           : Sample(12),
      askLevel3Price              : Sample(11),
      bidLevel3Price              : Sample(11),
      askLevel3Volume             : Sample(12),
      bidLevel3Volume             : Sample(12),
      lpAskLevel3Volume           : Sample(12),
      lpBidLevel3Volume           : Sample(12),
      askLevel4Price              : Sample(11),
      bidLevel4Price              : Sample(11),
      askLevel4Volume             : Sample(12),
      bidLevel4Volume             : Sample(12),
      lpAskLevel4Volume           : Sample(12),
      lpBidLevel4Volume           : Sample(12),
      askLevel5Price              : Sample(11),
      bidLevel5Price              : Sample(11),
      askLevel5Volume             : Sample(12),
      bidLevel5Volume             : Sample(12),
      lpAskLevel5Volume           : Sample(12),
      lpBidLevel5Volume           : Sample(12),
      askLevel6Price              : Sample(11),
      bidLevel6Price              : Sample(11),
      askLevel6Volume             : Sample(12),
      bidLevel6Volume             : Sample(12),
      lpAskLevel6Volume           : Sample(12),
      lpBidLevel6Volume           : Sample(12),
      askLevel7Price              : Sample(11),
      bidLevel7Price              : Sample(11),
      askLevel7Volume             : Sample(12),
      bidLevel7Volume             : Sample(12),
      lpAskLevel7Volume           : Sample(12),
      lpBidLevel7Volume           : Sample(12),
      askLevel8Price              : Sample(11),
      bidLevel8Price              : Sample(11),
      askLevel8Volume             : Sample(12),
      bidLevel8Volume             : Sample(12),
      lpAskLevel8Volume           : Sample(12),
      lpBidLevel8Volume           : Sample(12),
      askLevel9Price              : Sample(11),
      bidLevel9Price              : Sample(11),
      askLevel9Volume             : Sample(12),
      bidLevel9Volume             : Sample(12),
      lpAskLevel9Volume           : Sample(12),
      lpBidLevel9Volume           : Sample(12),
      askLevel10Price             : Sample(11),
      bidLevel10Price             : Sample(11),
      askLevel10Volume            : Sample(12),
      bidLevel10Volume            : Sample(12),
      lpAskLevel10Volume          : Sample(12),
      lpBidLevel10Volume          : Sample(12),
      totalAskVolume              : Sample(12),
      totalBidVolume              : Sample(12),
      estimatedTradingPrice       : Sample(11),
      estimatedTradingVolume      : Sample(12),
      endKeyword                  : Sample(1) ]

EncodeSpotGoldSnapshotMessage(message) ==
    message.boardId
        \o message.sessionId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.currentPrice
        \o message.openingPriceLong
        \o message.todaysHigh
        \o message.todaysLow
        \o message.accumulatedTradingVolume
        \o message.accumulatedTradingValueLong
        \o message.tradingHalt
        \o message.askLevel1Price
        \o message.bidLevel1Price
        \o message.askLevel1Volume
        \o message.bidLevel1Volume
        \o message.lpAskLevel1Volume
        \o message.lpBidLevel1Volume
        \o message.askLevel2Price
        \o message.bidLevel2Price
        \o message.askLevel2Volume
        \o message.bidLevel2Volume
        \o message.lpAskLevel2Volume
        \o message.lpBidLevel2Volume
        \o message.askLevel3Price
        \o message.bidLevel3Price
        \o message.askLevel3Volume
        \o message.bidLevel3Volume
        \o message.lpAskLevel3Volume
        \o message.lpBidLevel3Volume
        \o message.askLevel4Price
        \o message.bidLevel4Price
        \o message.askLevel4Volume
        \o message.bidLevel4Volume
        \o message.lpAskLevel4Volume
        \o message.lpBidLevel4Volume
        \o message.askLevel5Price
        \o message.bidLevel5Price
        \o message.askLevel5Volume
        \o message.bidLevel5Volume
        \o message.lpAskLevel5Volume
        \o message.lpBidLevel5Volume
        \o message.askLevel6Price
        \o message.bidLevel6Price
        \o message.askLevel6Volume
        \o message.bidLevel6Volume
        \o message.lpAskLevel6Volume
        \o message.lpBidLevel6Volume
        \o message.askLevel7Price
        \o message.bidLevel7Price
        \o message.askLevel7Volume
        \o message.bidLevel7Volume
        \o message.lpAskLevel7Volume
        \o message.lpBidLevel7Volume
        \o message.askLevel8Price
        \o message.bidLevel8Price
        \o message.askLevel8Volume
        \o message.bidLevel8Volume
        \o message.lpAskLevel8Volume
        \o message.lpBidLevel8Volume
        \o message.askLevel9Price
        \o message.bidLevel9Price
        \o message.askLevel9Volume
        \o message.bidLevel9Volume
        \o message.lpAskLevel9Volume
        \o message.lpBidLevel9Volume
        \o message.askLevel10Price
        \o message.bidLevel10Price
        \o message.askLevel10Volume
        \o message.bidLevel10Volume
        \o message.lpAskLevel10Volume
        \o message.lpBidLevel10Volume
        \o message.totalAskVolume
        \o message.totalBidVolume
        \o message.estimatedTradingPrice
        \o message.estimatedTradingVolume
        \o message.endKeyword

DecodeSpotGoldSnapshotMessage(bytes) ==
    LET boardId == ReadBytes(bytes, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(boardId.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(sessionId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET currentPrice == ReadBytes(aDesignatedNumberForAnIssue.rest, 11) IN IF ~currentPrice.ok THEN Fail ELSE
    LET openingPriceLong == ReadBytes(currentPrice.rest, 11) IN IF ~openingPriceLong.ok THEN Fail ELSE
    LET todaysHigh == ReadBytes(openingPriceLong.rest, 11) IN IF ~todaysHigh.ok THEN Fail ELSE
    LET todaysLow == ReadBytes(todaysHigh.rest, 11) IN IF ~todaysLow.ok THEN Fail ELSE
    LET accumulatedTradingVolume == ReadBytes(todaysLow.rest, 12) IN IF ~accumulatedTradingVolume.ok THEN Fail ELSE
    LET accumulatedTradingValueLong == ReadBytes(accumulatedTradingVolume.rest, 22) IN IF ~accumulatedTradingValueLong.ok THEN Fail ELSE
    LET tradingHalt == ReadBytes(accumulatedTradingValueLong.rest, 1) IN IF ~tradingHalt.ok THEN Fail ELSE
    LET askLevel1Price == ReadBytes(tradingHalt.rest, 11) IN IF ~askLevel1Price.ok THEN Fail ELSE
    LET bidLevel1Price == ReadBytes(askLevel1Price.rest, 11) IN IF ~bidLevel1Price.ok THEN Fail ELSE
    LET askLevel1Volume == ReadBytes(bidLevel1Price.rest, 12) IN IF ~askLevel1Volume.ok THEN Fail ELSE
    LET bidLevel1Volume == ReadBytes(askLevel1Volume.rest, 12) IN IF ~bidLevel1Volume.ok THEN Fail ELSE
    LET lpAskLevel1Volume == ReadBytes(bidLevel1Volume.rest, 12) IN IF ~lpAskLevel1Volume.ok THEN Fail ELSE
    LET lpBidLevel1Volume == ReadBytes(lpAskLevel1Volume.rest, 12) IN IF ~lpBidLevel1Volume.ok THEN Fail ELSE
    LET askLevel2Price == ReadBytes(lpBidLevel1Volume.rest, 11) IN IF ~askLevel2Price.ok THEN Fail ELSE
    LET bidLevel2Price == ReadBytes(askLevel2Price.rest, 11) IN IF ~bidLevel2Price.ok THEN Fail ELSE
    LET askLevel2Volume == ReadBytes(bidLevel2Price.rest, 12) IN IF ~askLevel2Volume.ok THEN Fail ELSE
    LET bidLevel2Volume == ReadBytes(askLevel2Volume.rest, 12) IN IF ~bidLevel2Volume.ok THEN Fail ELSE
    LET lpAskLevel2Volume == ReadBytes(bidLevel2Volume.rest, 12) IN IF ~lpAskLevel2Volume.ok THEN Fail ELSE
    LET lpBidLevel2Volume == ReadBytes(lpAskLevel2Volume.rest, 12) IN IF ~lpBidLevel2Volume.ok THEN Fail ELSE
    LET askLevel3Price == ReadBytes(lpBidLevel2Volume.rest, 11) IN IF ~askLevel3Price.ok THEN Fail ELSE
    LET bidLevel3Price == ReadBytes(askLevel3Price.rest, 11) IN IF ~bidLevel3Price.ok THEN Fail ELSE
    LET askLevel3Volume == ReadBytes(bidLevel3Price.rest, 12) IN IF ~askLevel3Volume.ok THEN Fail ELSE
    LET bidLevel3Volume == ReadBytes(askLevel3Volume.rest, 12) IN IF ~bidLevel3Volume.ok THEN Fail ELSE
    LET lpAskLevel3Volume == ReadBytes(bidLevel3Volume.rest, 12) IN IF ~lpAskLevel3Volume.ok THEN Fail ELSE
    LET lpBidLevel3Volume == ReadBytes(lpAskLevel3Volume.rest, 12) IN IF ~lpBidLevel3Volume.ok THEN Fail ELSE
    LET askLevel4Price == ReadBytes(lpBidLevel3Volume.rest, 11) IN IF ~askLevel4Price.ok THEN Fail ELSE
    LET bidLevel4Price == ReadBytes(askLevel4Price.rest, 11) IN IF ~bidLevel4Price.ok THEN Fail ELSE
    LET askLevel4Volume == ReadBytes(bidLevel4Price.rest, 12) IN IF ~askLevel4Volume.ok THEN Fail ELSE
    LET bidLevel4Volume == ReadBytes(askLevel4Volume.rest, 12) IN IF ~bidLevel4Volume.ok THEN Fail ELSE
    LET lpAskLevel4Volume == ReadBytes(bidLevel4Volume.rest, 12) IN IF ~lpAskLevel4Volume.ok THEN Fail ELSE
    LET lpBidLevel4Volume == ReadBytes(lpAskLevel4Volume.rest, 12) IN IF ~lpBidLevel4Volume.ok THEN Fail ELSE
    LET askLevel5Price == ReadBytes(lpBidLevel4Volume.rest, 11) IN IF ~askLevel5Price.ok THEN Fail ELSE
    LET bidLevel5Price == ReadBytes(askLevel5Price.rest, 11) IN IF ~bidLevel5Price.ok THEN Fail ELSE
    LET askLevel5Volume == ReadBytes(bidLevel5Price.rest, 12) IN IF ~askLevel5Volume.ok THEN Fail ELSE
    LET bidLevel5Volume == ReadBytes(askLevel5Volume.rest, 12) IN IF ~bidLevel5Volume.ok THEN Fail ELSE
    LET lpAskLevel5Volume == ReadBytes(bidLevel5Volume.rest, 12) IN IF ~lpAskLevel5Volume.ok THEN Fail ELSE
    LET lpBidLevel5Volume == ReadBytes(lpAskLevel5Volume.rest, 12) IN IF ~lpBidLevel5Volume.ok THEN Fail ELSE
    LET askLevel6Price == ReadBytes(lpBidLevel5Volume.rest, 11) IN IF ~askLevel6Price.ok THEN Fail ELSE
    LET bidLevel6Price == ReadBytes(askLevel6Price.rest, 11) IN IF ~bidLevel6Price.ok THEN Fail ELSE
    LET askLevel6Volume == ReadBytes(bidLevel6Price.rest, 12) IN IF ~askLevel6Volume.ok THEN Fail ELSE
    LET bidLevel6Volume == ReadBytes(askLevel6Volume.rest, 12) IN IF ~bidLevel6Volume.ok THEN Fail ELSE
    LET lpAskLevel6Volume == ReadBytes(bidLevel6Volume.rest, 12) IN IF ~lpAskLevel6Volume.ok THEN Fail ELSE
    LET lpBidLevel6Volume == ReadBytes(lpAskLevel6Volume.rest, 12) IN IF ~lpBidLevel6Volume.ok THEN Fail ELSE
    LET askLevel7Price == ReadBytes(lpBidLevel6Volume.rest, 11) IN IF ~askLevel7Price.ok THEN Fail ELSE
    LET bidLevel7Price == ReadBytes(askLevel7Price.rest, 11) IN IF ~bidLevel7Price.ok THEN Fail ELSE
    LET askLevel7Volume == ReadBytes(bidLevel7Price.rest, 12) IN IF ~askLevel7Volume.ok THEN Fail ELSE
    LET bidLevel7Volume == ReadBytes(askLevel7Volume.rest, 12) IN IF ~bidLevel7Volume.ok THEN Fail ELSE
    LET lpAskLevel7Volume == ReadBytes(bidLevel7Volume.rest, 12) IN IF ~lpAskLevel7Volume.ok THEN Fail ELSE
    LET lpBidLevel7Volume == ReadBytes(lpAskLevel7Volume.rest, 12) IN IF ~lpBidLevel7Volume.ok THEN Fail ELSE
    LET askLevel8Price == ReadBytes(lpBidLevel7Volume.rest, 11) IN IF ~askLevel8Price.ok THEN Fail ELSE
    LET bidLevel8Price == ReadBytes(askLevel8Price.rest, 11) IN IF ~bidLevel8Price.ok THEN Fail ELSE
    LET askLevel8Volume == ReadBytes(bidLevel8Price.rest, 12) IN IF ~askLevel8Volume.ok THEN Fail ELSE
    LET bidLevel8Volume == ReadBytes(askLevel8Volume.rest, 12) IN IF ~bidLevel8Volume.ok THEN Fail ELSE
    LET lpAskLevel8Volume == ReadBytes(bidLevel8Volume.rest, 12) IN IF ~lpAskLevel8Volume.ok THEN Fail ELSE
    LET lpBidLevel8Volume == ReadBytes(lpAskLevel8Volume.rest, 12) IN IF ~lpBidLevel8Volume.ok THEN Fail ELSE
    LET askLevel9Price == ReadBytes(lpBidLevel8Volume.rest, 11) IN IF ~askLevel9Price.ok THEN Fail ELSE
    LET bidLevel9Price == ReadBytes(askLevel9Price.rest, 11) IN IF ~bidLevel9Price.ok THEN Fail ELSE
    LET askLevel9Volume == ReadBytes(bidLevel9Price.rest, 12) IN IF ~askLevel9Volume.ok THEN Fail ELSE
    LET bidLevel9Volume == ReadBytes(askLevel9Volume.rest, 12) IN IF ~bidLevel9Volume.ok THEN Fail ELSE
    LET lpAskLevel9Volume == ReadBytes(bidLevel9Volume.rest, 12) IN IF ~lpAskLevel9Volume.ok THEN Fail ELSE
    LET lpBidLevel9Volume == ReadBytes(lpAskLevel9Volume.rest, 12) IN IF ~lpBidLevel9Volume.ok THEN Fail ELSE
    LET askLevel10Price == ReadBytes(lpBidLevel9Volume.rest, 11) IN IF ~askLevel10Price.ok THEN Fail ELSE
    LET bidLevel10Price == ReadBytes(askLevel10Price.rest, 11) IN IF ~bidLevel10Price.ok THEN Fail ELSE
    LET askLevel10Volume == ReadBytes(bidLevel10Price.rest, 12) IN IF ~askLevel10Volume.ok THEN Fail ELSE
    LET bidLevel10Volume == ReadBytes(askLevel10Volume.rest, 12) IN IF ~bidLevel10Volume.ok THEN Fail ELSE
    LET lpAskLevel10Volume == ReadBytes(bidLevel10Volume.rest, 12) IN IF ~lpAskLevel10Volume.ok THEN Fail ELSE
    LET lpBidLevel10Volume == ReadBytes(lpAskLevel10Volume.rest, 12) IN IF ~lpBidLevel10Volume.ok THEN Fail ELSE
    LET totalAskVolume == ReadBytes(lpBidLevel10Volume.rest, 12) IN IF ~totalAskVolume.ok THEN Fail ELSE
    LET totalBidVolume == ReadBytes(totalAskVolume.rest, 12) IN IF ~totalBidVolume.ok THEN Fail ELSE
    LET estimatedTradingPrice == ReadBytes(totalBidVolume.rest, 11) IN IF ~estimatedTradingPrice.ok THEN Fail ELSE
    LET estimatedTradingVolume == ReadBytes(estimatedTradingPrice.rest, 12) IN IF ~estimatedTradingVolume.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(estimatedTradingVolume.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ boardId                     |-> boardId.value,
         sessionId                   |-> sessionId.value,
         isinCode                    |-> isinCode.value,
         aDesignatedNumberForAnIssue |-> aDesignatedNumberForAnIssue.value,
         currentPrice                |-> currentPrice.value,
         openingPriceLong            |-> openingPriceLong.value,
         todaysHigh                  |-> todaysHigh.value,
         todaysLow                   |-> todaysLow.value,
         accumulatedTradingVolume    |-> accumulatedTradingVolume.value,
         accumulatedTradingValueLong |-> accumulatedTradingValueLong.value,
         tradingHalt                 |-> tradingHalt.value,
         askLevel1Price              |-> askLevel1Price.value,
         bidLevel1Price              |-> bidLevel1Price.value,
         askLevel1Volume             |-> askLevel1Volume.value,
         bidLevel1Volume             |-> bidLevel1Volume.value,
         lpAskLevel1Volume           |-> lpAskLevel1Volume.value,
         lpBidLevel1Volume           |-> lpBidLevel1Volume.value,
         askLevel2Price              |-> askLevel2Price.value,
         bidLevel2Price              |-> bidLevel2Price.value,
         askLevel2Volume             |-> askLevel2Volume.value,
         bidLevel2Volume             |-> bidLevel2Volume.value,
         lpAskLevel2Volume           |-> lpAskLevel2Volume.value,
         lpBidLevel2Volume           |-> lpBidLevel2Volume.value,
         askLevel3Price              |-> askLevel3Price.value,
         bidLevel3Price              |-> bidLevel3Price.value,
         askLevel3Volume             |-> askLevel3Volume.value,
         bidLevel3Volume             |-> bidLevel3Volume.value,
         lpAskLevel3Volume           |-> lpAskLevel3Volume.value,
         lpBidLevel3Volume           |-> lpBidLevel3Volume.value,
         askLevel4Price              |-> askLevel4Price.value,
         bidLevel4Price              |-> bidLevel4Price.value,
         askLevel4Volume             |-> askLevel4Volume.value,
         bidLevel4Volume             |-> bidLevel4Volume.value,
         lpAskLevel4Volume           |-> lpAskLevel4Volume.value,
         lpBidLevel4Volume           |-> lpBidLevel4Volume.value,
         askLevel5Price              |-> askLevel5Price.value,
         bidLevel5Price              |-> bidLevel5Price.value,
         askLevel5Volume             |-> askLevel5Volume.value,
         bidLevel5Volume             |-> bidLevel5Volume.value,
         lpAskLevel5Volume           |-> lpAskLevel5Volume.value,
         lpBidLevel5Volume           |-> lpBidLevel5Volume.value,
         askLevel6Price              |-> askLevel6Price.value,
         bidLevel6Price              |-> bidLevel6Price.value,
         askLevel6Volume             |-> askLevel6Volume.value,
         bidLevel6Volume             |-> bidLevel6Volume.value,
         lpAskLevel6Volume           |-> lpAskLevel6Volume.value,
         lpBidLevel6Volume           |-> lpBidLevel6Volume.value,
         askLevel7Price              |-> askLevel7Price.value,
         bidLevel7Price              |-> bidLevel7Price.value,
         askLevel7Volume             |-> askLevel7Volume.value,
         bidLevel7Volume             |-> bidLevel7Volume.value,
         lpAskLevel7Volume           |-> lpAskLevel7Volume.value,
         lpBidLevel7Volume           |-> lpBidLevel7Volume.value,
         askLevel8Price              |-> askLevel8Price.value,
         bidLevel8Price              |-> bidLevel8Price.value,
         askLevel8Volume             |-> askLevel8Volume.value,
         bidLevel8Volume             |-> bidLevel8Volume.value,
         lpAskLevel8Volume           |-> lpAskLevel8Volume.value,
         lpBidLevel8Volume           |-> lpBidLevel8Volume.value,
         askLevel9Price              |-> askLevel9Price.value,
         bidLevel9Price              |-> bidLevel9Price.value,
         askLevel9Volume             |-> askLevel9Volume.value,
         bidLevel9Volume             |-> bidLevel9Volume.value,
         lpAskLevel9Volume           |-> lpAskLevel9Volume.value,
         lpBidLevel9Volume           |-> lpBidLevel9Volume.value,
         askLevel10Price             |-> askLevel10Price.value,
         bidLevel10Price             |-> bidLevel10Price.value,
         askLevel10Volume            |-> askLevel10Volume.value,
         bidLevel10Volume            |-> bidLevel10Volume.value,
         lpAskLevel10Volume          |-> lpAskLevel10Volume.value,
         lpBidLevel10Volume          |-> lpBidLevel10Volume.value,
         totalAskVolume              |-> totalAskVolume.value,
         totalBidVolume              |-> totalBidVolume.value,
         estimatedTradingPrice       |-> estimatedTradingPrice.value,
         estimatedTradingVolume      |-> estimatedTradingVolume.value,
         endKeyword                  |-> endKeyword.value ], endKeyword.rest)

ZeroSpotGoldSnapshotMessage ==
    [ boardId                     |-> [i \in 1 .. 2 |-> 0],
      sessionId                   |-> [i \in 1 .. 2 |-> 0],
      isinCode                    |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue |-> [i \in 1 .. 6 |-> 0],
      currentPrice                |-> [i \in 1 .. 11 |-> 0],
      openingPriceLong            |-> [i \in 1 .. 11 |-> 0],
      todaysHigh                  |-> [i \in 1 .. 11 |-> 0],
      todaysLow                   |-> [i \in 1 .. 11 |-> 0],
      accumulatedTradingVolume    |-> [i \in 1 .. 12 |-> 0],
      accumulatedTradingValueLong |-> [i \in 1 .. 22 |-> 0],
      tradingHalt                 |-> [i \in 1 .. 1 |-> 0],
      askLevel1Price              |-> [i \in 1 .. 11 |-> 0],
      bidLevel1Price              |-> [i \in 1 .. 11 |-> 0],
      askLevel1Volume             |-> [i \in 1 .. 12 |-> 0],
      bidLevel1Volume             |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel1Volume           |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel1Volume           |-> [i \in 1 .. 12 |-> 0],
      askLevel2Price              |-> [i \in 1 .. 11 |-> 0],
      bidLevel2Price              |-> [i \in 1 .. 11 |-> 0],
      askLevel2Volume             |-> [i \in 1 .. 12 |-> 0],
      bidLevel2Volume             |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel2Volume           |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel2Volume           |-> [i \in 1 .. 12 |-> 0],
      askLevel3Price              |-> [i \in 1 .. 11 |-> 0],
      bidLevel3Price              |-> [i \in 1 .. 11 |-> 0],
      askLevel3Volume             |-> [i \in 1 .. 12 |-> 0],
      bidLevel3Volume             |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel3Volume           |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel3Volume           |-> [i \in 1 .. 12 |-> 0],
      askLevel4Price              |-> [i \in 1 .. 11 |-> 0],
      bidLevel4Price              |-> [i \in 1 .. 11 |-> 0],
      askLevel4Volume             |-> [i \in 1 .. 12 |-> 0],
      bidLevel4Volume             |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel4Volume           |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel4Volume           |-> [i \in 1 .. 12 |-> 0],
      askLevel5Price              |-> [i \in 1 .. 11 |-> 0],
      bidLevel5Price              |-> [i \in 1 .. 11 |-> 0],
      askLevel5Volume             |-> [i \in 1 .. 12 |-> 0],
      bidLevel5Volume             |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel5Volume           |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel5Volume           |-> [i \in 1 .. 12 |-> 0],
      askLevel6Price              |-> [i \in 1 .. 11 |-> 0],
      bidLevel6Price              |-> [i \in 1 .. 11 |-> 0],
      askLevel6Volume             |-> [i \in 1 .. 12 |-> 0],
      bidLevel6Volume             |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel6Volume           |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel6Volume           |-> [i \in 1 .. 12 |-> 0],
      askLevel7Price              |-> [i \in 1 .. 11 |-> 0],
      bidLevel7Price              |-> [i \in 1 .. 11 |-> 0],
      askLevel7Volume             |-> [i \in 1 .. 12 |-> 0],
      bidLevel7Volume             |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel7Volume           |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel7Volume           |-> [i \in 1 .. 12 |-> 0],
      askLevel8Price              |-> [i \in 1 .. 11 |-> 0],
      bidLevel8Price              |-> [i \in 1 .. 11 |-> 0],
      askLevel8Volume             |-> [i \in 1 .. 12 |-> 0],
      bidLevel8Volume             |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel8Volume           |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel8Volume           |-> [i \in 1 .. 12 |-> 0],
      askLevel9Price              |-> [i \in 1 .. 11 |-> 0],
      bidLevel9Price              |-> [i \in 1 .. 11 |-> 0],
      askLevel9Volume             |-> [i \in 1 .. 12 |-> 0],
      bidLevel9Volume             |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel9Volume           |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel9Volume           |-> [i \in 1 .. 12 |-> 0],
      askLevel10Price             |-> [i \in 1 .. 11 |-> 0],
      bidLevel10Price             |-> [i \in 1 .. 11 |-> 0],
      askLevel10Volume            |-> [i \in 1 .. 12 |-> 0],
      bidLevel10Volume            |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel10Volume          |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel10Volume          |-> [i \in 1 .. 12 |-> 0],
      totalAskVolume              |-> [i \in 1 .. 12 |-> 0],
      totalBidVolume              |-> [i \in 1 .. 12 |-> 0],
      estimatedTradingPrice       |-> [i \in 1 .. 11 |-> 0],
      estimatedTradingVolume      |-> [i \in 1 .. 12 |-> 0],
      endKeyword                  |-> [i \in 1 .. 1 |-> 0] ]

(* Spot Gold Snapshot Message at zero, then each field in turn at the values it is checked at *)
CheckedSpotGoldSnapshotMessage ==
    { ZeroSpotGoldSnapshotMessage }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.currentPrice = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.openingPriceLong = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.todaysHigh = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.todaysLow = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.accumulatedTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.accumulatedTradingValueLong = one] : one \in Sample(22) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.tradingHalt = one] : one \in Sample(1) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.askLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.bidLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.askLevel1Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.bidLevel1Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.lpAskLevel1Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.lpBidLevel1Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.askLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.bidLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.askLevel2Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.bidLevel2Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.lpAskLevel2Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.lpBidLevel2Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.askLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.bidLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.askLevel3Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.bidLevel3Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.lpAskLevel3Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.lpBidLevel3Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.askLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.bidLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.askLevel4Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.bidLevel4Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.lpAskLevel4Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.lpBidLevel4Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.askLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.bidLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.askLevel5Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.bidLevel5Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.lpAskLevel5Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.lpBidLevel5Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.askLevel6Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.bidLevel6Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.askLevel6Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.bidLevel6Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.lpAskLevel6Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.lpBidLevel6Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.askLevel7Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.bidLevel7Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.askLevel7Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.bidLevel7Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.lpAskLevel7Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.lpBidLevel7Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.askLevel8Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.bidLevel8Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.askLevel8Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.bidLevel8Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.lpAskLevel8Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.lpBidLevel8Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.askLevel9Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.bidLevel9Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.askLevel9Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.bidLevel9Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.lpAskLevel9Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.lpBidLevel9Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.askLevel10Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.bidLevel10Price = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.askLevel10Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.bidLevel10Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.lpAskLevel10Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.lpBidLevel10Volume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.totalAskVolume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.totalBidVolume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.estimatedTradingPrice = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.estimatedTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldSnapshotMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Spot Gold Negotiated Trade Message: 93 bytes                            *)
(***************************************************************************)

SpotGoldNegotiatedTradeMessage ==
    [ isinCode                                : Sample(12),
      aDesignatedNumberForAnIssue             : Sample(6),
      negotiatedTradeAccumulatedTradingVolume : Sample(15),
      negotiatedTradeAccumulatedTradingValue  : Sample(22),
      totalAccumulatedTradingVolume           : Sample(15),
      totalAccumulatedTradingValue            : Sample(22),
      endKeyword                              : Sample(1) ]

EncodeSpotGoldNegotiatedTradeMessage(message) ==
    message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.negotiatedTradeAccumulatedTradingVolume
        \o message.negotiatedTradeAccumulatedTradingValue
        \o message.totalAccumulatedTradingVolume
        \o message.totalAccumulatedTradingValue
        \o message.endKeyword

DecodeSpotGoldNegotiatedTradeMessage(bytes) ==
    LET isinCode == ReadBytes(bytes, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET negotiatedTradeAccumulatedTradingVolume == ReadBytes(aDesignatedNumberForAnIssue.rest, 15) IN IF ~negotiatedTradeAccumulatedTradingVolume.ok THEN Fail ELSE
    LET negotiatedTradeAccumulatedTradingValue == ReadBytes(negotiatedTradeAccumulatedTradingVolume.rest, 22) IN IF ~negotiatedTradeAccumulatedTradingValue.ok THEN Fail ELSE
    LET totalAccumulatedTradingVolume == ReadBytes(negotiatedTradeAccumulatedTradingValue.rest, 15) IN IF ~totalAccumulatedTradingVolume.ok THEN Fail ELSE
    LET totalAccumulatedTradingValue == ReadBytes(totalAccumulatedTradingVolume.rest, 22) IN IF ~totalAccumulatedTradingValue.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(totalAccumulatedTradingValue.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ isinCode                                |-> isinCode.value,
         aDesignatedNumberForAnIssue             |-> aDesignatedNumberForAnIssue.value,
         negotiatedTradeAccumulatedTradingVolume |-> negotiatedTradeAccumulatedTradingVolume.value,
         negotiatedTradeAccumulatedTradingValue  |-> negotiatedTradeAccumulatedTradingValue.value,
         totalAccumulatedTradingVolume           |-> totalAccumulatedTradingVolume.value,
         totalAccumulatedTradingValue            |-> totalAccumulatedTradingValue.value,
         endKeyword                              |-> endKeyword.value ], endKeyword.rest)

ZeroSpotGoldNegotiatedTradeMessage ==
    [ isinCode                                |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue             |-> [i \in 1 .. 6 |-> 0],
      negotiatedTradeAccumulatedTradingVolume |-> [i \in 1 .. 15 |-> 0],
      negotiatedTradeAccumulatedTradingValue  |-> [i \in 1 .. 22 |-> 0],
      totalAccumulatedTradingVolume           |-> [i \in 1 .. 15 |-> 0],
      totalAccumulatedTradingValue            |-> [i \in 1 .. 22 |-> 0],
      endKeyword                              |-> [i \in 1 .. 1 |-> 0] ]

(* Spot Gold Negotiated Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedSpotGoldNegotiatedTradeMessage ==
    { ZeroSpotGoldNegotiatedTradeMessage }
        \cup { [ZeroSpotGoldNegotiatedTradeMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldNegotiatedTradeMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroSpotGoldNegotiatedTradeMessage EXCEPT !.negotiatedTradeAccumulatedTradingVolume = one] : one \in Sample(15) }
        \cup { [ZeroSpotGoldNegotiatedTradeMessage EXCEPT !.negotiatedTradeAccumulatedTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroSpotGoldNegotiatedTradeMessage EXCEPT !.totalAccumulatedTradingVolume = one] : one \in Sample(15) }
        \cup { [ZeroSpotGoldNegotiatedTradeMessage EXCEPT !.totalAccumulatedTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroSpotGoldNegotiatedTradeMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Emissions Quote Message: 320 bytes                                      *)
(***************************************************************************)

EmissionsQuoteMessage ==
    [ messageSequenceNumber         : Sample(8),
      boardId                       : Sample(2),
      sessionId                     : Sample(2),
      isinCode                      : Sample(12),
      aDesignatedNumberForAnIssue   : Sample(6),
      processingTimeOfTradingSystem : Sample(12),
      askLevel1Price                : Sample(11),
      bidLevel1Price                : Sample(11),
      askLevel1Volume               : Sample(12),
      bidLevel1Volume               : Sample(12),
      askLevel2Price                : Sample(11),
      bidLevel2Price                : Sample(11),
      askLevel2Volume               : Sample(12),
      bidLevel2Volume               : Sample(12),
      askLevel3Price                : Sample(11),
      bidLevel3Price                : Sample(11),
      askLevel3Volume               : Sample(12),
      bidLevel3Volume               : Sample(12),
      askLevel4Price                : Sample(11),
      bidLevel4Price                : Sample(11),
      askLevel4Volume               : Sample(12),
      bidLevel4Volume               : Sample(12),
      askLevel5Price                : Sample(11),
      bidLevel5Price                : Sample(11),
      askLevel5Volume               : Sample(12),
      bidLevel5Volume               : Sample(12),
      totalAskVolume                : Sample(12),
      totalBidVolume                : Sample(12),
      estimatedTradingPrice         : Sample(11),
      estimatedTradingVolume        : Sample(12),
      endKeyword                    : Sample(1) ]

EncodeEmissionsQuoteMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.sessionId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.processingTimeOfTradingSystem
        \o message.askLevel1Price
        \o message.bidLevel1Price
        \o message.askLevel1Volume
        \o message.bidLevel1Volume
        \o message.askLevel2Price
        \o message.bidLevel2Price
        \o message.askLevel2Volume
        \o message.bidLevel2Volume
        \o message.askLevel3Price
        \o message.bidLevel3Price
        \o message.askLevel3Volume
        \o message.bidLevel3Volume
        \o message.askLevel4Price
        \o message.bidLevel4Price
        \o message.askLevel4Volume
        \o message.bidLevel4Volume
        \o message.askLevel5Price
        \o message.bidLevel5Price
        \o message.askLevel5Volume
        \o message.bidLevel5Volume
        \o message.totalAskVolume
        \o message.totalBidVolume
        \o message.estimatedTradingPrice
        \o message.estimatedTradingVolume
        \o message.endKeyword

DecodeEmissionsQuoteMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(boardId.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(sessionId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET processingTimeOfTradingSystem == ReadBytes(aDesignatedNumberForAnIssue.rest, 12) IN IF ~processingTimeOfTradingSystem.ok THEN Fail ELSE
    LET askLevel1Price == ReadBytes(processingTimeOfTradingSystem.rest, 11) IN IF ~askLevel1Price.ok THEN Fail ELSE
    LET bidLevel1Price == ReadBytes(askLevel1Price.rest, 11) IN IF ~bidLevel1Price.ok THEN Fail ELSE
    LET askLevel1Volume == ReadBytes(bidLevel1Price.rest, 12) IN IF ~askLevel1Volume.ok THEN Fail ELSE
    LET bidLevel1Volume == ReadBytes(askLevel1Volume.rest, 12) IN IF ~bidLevel1Volume.ok THEN Fail ELSE
    LET askLevel2Price == ReadBytes(bidLevel1Volume.rest, 11) IN IF ~askLevel2Price.ok THEN Fail ELSE
    LET bidLevel2Price == ReadBytes(askLevel2Price.rest, 11) IN IF ~bidLevel2Price.ok THEN Fail ELSE
    LET askLevel2Volume == ReadBytes(bidLevel2Price.rest, 12) IN IF ~askLevel2Volume.ok THEN Fail ELSE
    LET bidLevel2Volume == ReadBytes(askLevel2Volume.rest, 12) IN IF ~bidLevel2Volume.ok THEN Fail ELSE
    LET askLevel3Price == ReadBytes(bidLevel2Volume.rest, 11) IN IF ~askLevel3Price.ok THEN Fail ELSE
    LET bidLevel3Price == ReadBytes(askLevel3Price.rest, 11) IN IF ~bidLevel3Price.ok THEN Fail ELSE
    LET askLevel3Volume == ReadBytes(bidLevel3Price.rest, 12) IN IF ~askLevel3Volume.ok THEN Fail ELSE
    LET bidLevel3Volume == ReadBytes(askLevel3Volume.rest, 12) IN IF ~bidLevel3Volume.ok THEN Fail ELSE
    LET askLevel4Price == ReadBytes(bidLevel3Volume.rest, 11) IN IF ~askLevel4Price.ok THEN Fail ELSE
    LET bidLevel4Price == ReadBytes(askLevel4Price.rest, 11) IN IF ~bidLevel4Price.ok THEN Fail ELSE
    LET askLevel4Volume == ReadBytes(bidLevel4Price.rest, 12) IN IF ~askLevel4Volume.ok THEN Fail ELSE
    LET bidLevel4Volume == ReadBytes(askLevel4Volume.rest, 12) IN IF ~bidLevel4Volume.ok THEN Fail ELSE
    LET askLevel5Price == ReadBytes(bidLevel4Volume.rest, 11) IN IF ~askLevel5Price.ok THEN Fail ELSE
    LET bidLevel5Price == ReadBytes(askLevel5Price.rest, 11) IN IF ~bidLevel5Price.ok THEN Fail ELSE
    LET askLevel5Volume == ReadBytes(bidLevel5Price.rest, 12) IN IF ~askLevel5Volume.ok THEN Fail ELSE
    LET bidLevel5Volume == ReadBytes(askLevel5Volume.rest, 12) IN IF ~bidLevel5Volume.ok THEN Fail ELSE
    LET totalAskVolume == ReadBytes(bidLevel5Volume.rest, 12) IN IF ~totalAskVolume.ok THEN Fail ELSE
    LET totalBidVolume == ReadBytes(totalAskVolume.rest, 12) IN IF ~totalBidVolume.ok THEN Fail ELSE
    LET estimatedTradingPrice == ReadBytes(totalBidVolume.rest, 11) IN IF ~estimatedTradingPrice.ok THEN Fail ELSE
    LET estimatedTradingVolume == ReadBytes(estimatedTradingPrice.rest, 12) IN IF ~estimatedTradingVolume.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(estimatedTradingVolume.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber         |-> messageSequenceNumber.value,
         boardId                       |-> boardId.value,
         sessionId                     |-> sessionId.value,
         isinCode                      |-> isinCode.value,
         aDesignatedNumberForAnIssue   |-> aDesignatedNumberForAnIssue.value,
         processingTimeOfTradingSystem |-> processingTimeOfTradingSystem.value,
         askLevel1Price                |-> askLevel1Price.value,
         bidLevel1Price                |-> bidLevel1Price.value,
         askLevel1Volume               |-> askLevel1Volume.value,
         bidLevel1Volume               |-> bidLevel1Volume.value,
         askLevel2Price                |-> askLevel2Price.value,
         bidLevel2Price                |-> bidLevel2Price.value,
         askLevel2Volume               |-> askLevel2Volume.value,
         bidLevel2Volume               |-> bidLevel2Volume.value,
         askLevel3Price                |-> askLevel3Price.value,
         bidLevel3Price                |-> bidLevel3Price.value,
         askLevel3Volume               |-> askLevel3Volume.value,
         bidLevel3Volume               |-> bidLevel3Volume.value,
         askLevel4Price                |-> askLevel4Price.value,
         bidLevel4Price                |-> bidLevel4Price.value,
         askLevel4Volume               |-> askLevel4Volume.value,
         bidLevel4Volume               |-> bidLevel4Volume.value,
         askLevel5Price                |-> askLevel5Price.value,
         bidLevel5Price                |-> bidLevel5Price.value,
         askLevel5Volume               |-> askLevel5Volume.value,
         bidLevel5Volume               |-> bidLevel5Volume.value,
         totalAskVolume                |-> totalAskVolume.value,
         totalBidVolume                |-> totalBidVolume.value,
         estimatedTradingPrice         |-> estimatedTradingPrice.value,
         estimatedTradingVolume        |-> estimatedTradingVolume.value,
         endKeyword                    |-> endKeyword.value ], endKeyword.rest)

ZeroEmissionsQuoteMessage ==
    [ messageSequenceNumber         |-> [i \in 1 .. 8 |-> 0],
      boardId                       |-> [i \in 1 .. 2 |-> 0],
      sessionId                     |-> [i \in 1 .. 2 |-> 0],
      isinCode                      |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue   |-> [i \in 1 .. 6 |-> 0],
      processingTimeOfTradingSystem |-> [i \in 1 .. 12 |-> 0],
      askLevel1Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel1Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel1Volume               |-> [i \in 1 .. 12 |-> 0],
      bidLevel1Volume               |-> [i \in 1 .. 12 |-> 0],
      askLevel2Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel2Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel2Volume               |-> [i \in 1 .. 12 |-> 0],
      bidLevel2Volume               |-> [i \in 1 .. 12 |-> 0],
      askLevel3Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel3Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel3Volume               |-> [i \in 1 .. 12 |-> 0],
      bidLevel3Volume               |-> [i \in 1 .. 12 |-> 0],
      askLevel4Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel4Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel4Volume               |-> [i \in 1 .. 12 |-> 0],
      bidLevel4Volume               |-> [i \in 1 .. 12 |-> 0],
      askLevel5Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel5Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel5Volume               |-> [i \in 1 .. 12 |-> 0],
      bidLevel5Volume               |-> [i \in 1 .. 12 |-> 0],
      totalAskVolume                |-> [i \in 1 .. 12 |-> 0],
      totalBidVolume                |-> [i \in 1 .. 12 |-> 0],
      estimatedTradingPrice         |-> [i \in 1 .. 11 |-> 0],
      estimatedTradingVolume        |-> [i \in 1 .. 12 |-> 0],
      endKeyword                    |-> [i \in 1 .. 1 |-> 0] ]

(* Emissions Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedEmissionsQuoteMessage ==
    { ZeroEmissionsQuoteMessage }
        \cup { [ZeroEmissionsQuoteMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroEmissionsQuoteMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroEmissionsQuoteMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroEmissionsQuoteMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsQuoteMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroEmissionsQuoteMessage EXCEPT !.processingTimeOfTradingSystem = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsQuoteMessage EXCEPT !.askLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsQuoteMessage EXCEPT !.bidLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsQuoteMessage EXCEPT !.askLevel1Volume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsQuoteMessage EXCEPT !.bidLevel1Volume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsQuoteMessage EXCEPT !.askLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsQuoteMessage EXCEPT !.bidLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsQuoteMessage EXCEPT !.askLevel2Volume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsQuoteMessage EXCEPT !.bidLevel2Volume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsQuoteMessage EXCEPT !.askLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsQuoteMessage EXCEPT !.bidLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsQuoteMessage EXCEPT !.askLevel3Volume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsQuoteMessage EXCEPT !.bidLevel3Volume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsQuoteMessage EXCEPT !.askLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsQuoteMessage EXCEPT !.bidLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsQuoteMessage EXCEPT !.askLevel4Volume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsQuoteMessage EXCEPT !.bidLevel4Volume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsQuoteMessage EXCEPT !.askLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsQuoteMessage EXCEPT !.bidLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsQuoteMessage EXCEPT !.askLevel5Volume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsQuoteMessage EXCEPT !.bidLevel5Volume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsQuoteMessage EXCEPT !.totalAskVolume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsQuoteMessage EXCEPT !.totalBidVolume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsQuoteMessage EXCEPT !.estimatedTradingPrice = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsQuoteMessage EXCEPT !.estimatedTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsQuoteMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Emissions Order Filled Message: 143 bytes                               *)
(***************************************************************************)

EmissionsOrderFilledMessage ==
    [ messageSequenceNumber         : Sample(8),
      boardId                       : Sample(2),
      sessionId                     : Sample(2),
      isinCode                      : Sample(12),
      aDesignatedNumberForAnIssue   : Sample(6),
      processingTimeOfTradingSystem : Sample(12),
      tradingPrice                  : Sample(11),
      tradingVolume                 : Sample(10),
      openingPriceLong              : Sample(11),
      todaysHigh                    : Sample(11),
      todaysLow                     : Sample(11),
      previousPrice                 : Sample(11),
      accumulatedTradingVolume      : Sample(12),
      accumulatedTradingValueLong   : Sample(22),
      finalAskBidTypeCode           : Sample(1),
      endKeyword                    : Sample(1) ]

EncodeEmissionsOrderFilledMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.sessionId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.processingTimeOfTradingSystem
        \o message.tradingPrice
        \o message.tradingVolume
        \o message.openingPriceLong
        \o message.todaysHigh
        \o message.todaysLow
        \o message.previousPrice
        \o message.accumulatedTradingVolume
        \o message.accumulatedTradingValueLong
        \o message.finalAskBidTypeCode
        \o message.endKeyword

DecodeEmissionsOrderFilledMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(boardId.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(sessionId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET processingTimeOfTradingSystem == ReadBytes(aDesignatedNumberForAnIssue.rest, 12) IN IF ~processingTimeOfTradingSystem.ok THEN Fail ELSE
    LET tradingPrice == ReadBytes(processingTimeOfTradingSystem.rest, 11) IN IF ~tradingPrice.ok THEN Fail ELSE
    LET tradingVolume == ReadBytes(tradingPrice.rest, 10) IN IF ~tradingVolume.ok THEN Fail ELSE
    LET openingPriceLong == ReadBytes(tradingVolume.rest, 11) IN IF ~openingPriceLong.ok THEN Fail ELSE
    LET todaysHigh == ReadBytes(openingPriceLong.rest, 11) IN IF ~todaysHigh.ok THEN Fail ELSE
    LET todaysLow == ReadBytes(todaysHigh.rest, 11) IN IF ~todaysLow.ok THEN Fail ELSE
    LET previousPrice == ReadBytes(todaysLow.rest, 11) IN IF ~previousPrice.ok THEN Fail ELSE
    LET accumulatedTradingVolume == ReadBytes(previousPrice.rest, 12) IN IF ~accumulatedTradingVolume.ok THEN Fail ELSE
    LET accumulatedTradingValueLong == ReadBytes(accumulatedTradingVolume.rest, 22) IN IF ~accumulatedTradingValueLong.ok THEN Fail ELSE
    LET finalAskBidTypeCode == ReadBytes(accumulatedTradingValueLong.rest, 1) IN IF ~finalAskBidTypeCode.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(finalAskBidTypeCode.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber         |-> messageSequenceNumber.value,
         boardId                       |-> boardId.value,
         sessionId                     |-> sessionId.value,
         isinCode                      |-> isinCode.value,
         aDesignatedNumberForAnIssue   |-> aDesignatedNumberForAnIssue.value,
         processingTimeOfTradingSystem |-> processingTimeOfTradingSystem.value,
         tradingPrice                  |-> tradingPrice.value,
         tradingVolume                 |-> tradingVolume.value,
         openingPriceLong              |-> openingPriceLong.value,
         todaysHigh                    |-> todaysHigh.value,
         todaysLow                     |-> todaysLow.value,
         previousPrice                 |-> previousPrice.value,
         accumulatedTradingVolume      |-> accumulatedTradingVolume.value,
         accumulatedTradingValueLong   |-> accumulatedTradingValueLong.value,
         finalAskBidTypeCode           |-> finalAskBidTypeCode.value,
         endKeyword                    |-> endKeyword.value ], endKeyword.rest)

ZeroEmissionsOrderFilledMessage ==
    [ messageSequenceNumber         |-> [i \in 1 .. 8 |-> 0],
      boardId                       |-> [i \in 1 .. 2 |-> 0],
      sessionId                     |-> [i \in 1 .. 2 |-> 0],
      isinCode                      |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue   |-> [i \in 1 .. 6 |-> 0],
      processingTimeOfTradingSystem |-> [i \in 1 .. 12 |-> 0],
      tradingPrice                  |-> [i \in 1 .. 11 |-> 0],
      tradingVolume                 |-> [i \in 1 .. 10 |-> 0],
      openingPriceLong              |-> [i \in 1 .. 11 |-> 0],
      todaysHigh                    |-> [i \in 1 .. 11 |-> 0],
      todaysLow                     |-> [i \in 1 .. 11 |-> 0],
      previousPrice                 |-> [i \in 1 .. 11 |-> 0],
      accumulatedTradingVolume      |-> [i \in 1 .. 12 |-> 0],
      accumulatedTradingValueLong   |-> [i \in 1 .. 22 |-> 0],
      finalAskBidTypeCode           |-> [i \in 1 .. 1 |-> 0],
      endKeyword                    |-> [i \in 1 .. 1 |-> 0] ]

(* Emissions Order Filled Message at zero, then each field in turn at the values it is checked at *)
CheckedEmissionsOrderFilledMessage ==
    { ZeroEmissionsOrderFilledMessage }
        \cup { [ZeroEmissionsOrderFilledMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroEmissionsOrderFilledMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroEmissionsOrderFilledMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroEmissionsOrderFilledMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsOrderFilledMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroEmissionsOrderFilledMessage EXCEPT !.processingTimeOfTradingSystem = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsOrderFilledMessage EXCEPT !.tradingPrice = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsOrderFilledMessage EXCEPT !.tradingVolume = one] : one \in Sample(10) }
        \cup { [ZeroEmissionsOrderFilledMessage EXCEPT !.openingPriceLong = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsOrderFilledMessage EXCEPT !.todaysHigh = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsOrderFilledMessage EXCEPT !.todaysLow = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsOrderFilledMessage EXCEPT !.previousPrice = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsOrderFilledMessage EXCEPT !.accumulatedTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsOrderFilledMessage EXCEPT !.accumulatedTradingValueLong = one] : one \in Sample(22) }
        \cup { [ZeroEmissionsOrderFilledMessage EXCEPT !.finalAskBidTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroEmissionsOrderFilledMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Emissions Order Filled Plus Quote Message: 397 bytes                    *)
(***************************************************************************)

EmissionsOrderFilledPlusQuoteMessage ==
    [ messageSequenceNumber         : Sample(8),
      boardId                       : Sample(2),
      sessionId                     : Sample(2),
      isinCode                      : Sample(12),
      aDesignatedNumberForAnIssue   : Sample(6),
      processingTimeOfTradingSystem : Sample(12),
      tradingPrice                  : Sample(11),
      tradingVolume                 : Sample(10),
      openingPriceLong              : Sample(11),
      todaysHigh                    : Sample(11),
      todaysLow                     : Sample(11),
      previousPrice                 : Sample(11),
      accumulatedTradingVolume      : Sample(12),
      accumulatedTradingValueLong   : Sample(22),
      finalAskBidTypeCode           : Sample(1),
      askLevel1Price                : Sample(11),
      bidLevel1Price                : Sample(11),
      askLevel1Volume               : Sample(12),
      bidLevel1Volume               : Sample(12),
      askLevel2Price                : Sample(11),
      bidLevel2Price                : Sample(11),
      askLevel2Volume               : Sample(12),
      bidLevel2Volume               : Sample(12),
      askLevel3Price                : Sample(11),
      bidLevel3Price                : Sample(11),
      askLevel3Volume               : Sample(12),
      bidLevel3Volume               : Sample(12),
      askLevel4Price                : Sample(11),
      bidLevel4Price                : Sample(11),
      askLevel4Volume               : Sample(12),
      bidLevel4Volume               : Sample(12),
      askLevel5Price                : Sample(11),
      bidLevel5Price                : Sample(11),
      askLevel5Volume               : Sample(12),
      bidLevel5Volume               : Sample(12),
      totalAskVolume                : Sample(12),
      totalBidVolume                : Sample(12),
      endKeyword                    : Sample(1) ]

EncodeEmissionsOrderFilledPlusQuoteMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.sessionId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.processingTimeOfTradingSystem
        \o message.tradingPrice
        \o message.tradingVolume
        \o message.openingPriceLong
        \o message.todaysHigh
        \o message.todaysLow
        \o message.previousPrice
        \o message.accumulatedTradingVolume
        \o message.accumulatedTradingValueLong
        \o message.finalAskBidTypeCode
        \o message.askLevel1Price
        \o message.bidLevel1Price
        \o message.askLevel1Volume
        \o message.bidLevel1Volume
        \o message.askLevel2Price
        \o message.bidLevel2Price
        \o message.askLevel2Volume
        \o message.bidLevel2Volume
        \o message.askLevel3Price
        \o message.bidLevel3Price
        \o message.askLevel3Volume
        \o message.bidLevel3Volume
        \o message.askLevel4Price
        \o message.bidLevel4Price
        \o message.askLevel4Volume
        \o message.bidLevel4Volume
        \o message.askLevel5Price
        \o message.bidLevel5Price
        \o message.askLevel5Volume
        \o message.bidLevel5Volume
        \o message.totalAskVolume
        \o message.totalBidVolume
        \o message.endKeyword

DecodeEmissionsOrderFilledPlusQuoteMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(boardId.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(sessionId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET processingTimeOfTradingSystem == ReadBytes(aDesignatedNumberForAnIssue.rest, 12) IN IF ~processingTimeOfTradingSystem.ok THEN Fail ELSE
    LET tradingPrice == ReadBytes(processingTimeOfTradingSystem.rest, 11) IN IF ~tradingPrice.ok THEN Fail ELSE
    LET tradingVolume == ReadBytes(tradingPrice.rest, 10) IN IF ~tradingVolume.ok THEN Fail ELSE
    LET openingPriceLong == ReadBytes(tradingVolume.rest, 11) IN IF ~openingPriceLong.ok THEN Fail ELSE
    LET todaysHigh == ReadBytes(openingPriceLong.rest, 11) IN IF ~todaysHigh.ok THEN Fail ELSE
    LET todaysLow == ReadBytes(todaysHigh.rest, 11) IN IF ~todaysLow.ok THEN Fail ELSE
    LET previousPrice == ReadBytes(todaysLow.rest, 11) IN IF ~previousPrice.ok THEN Fail ELSE
    LET accumulatedTradingVolume == ReadBytes(previousPrice.rest, 12) IN IF ~accumulatedTradingVolume.ok THEN Fail ELSE
    LET accumulatedTradingValueLong == ReadBytes(accumulatedTradingVolume.rest, 22) IN IF ~accumulatedTradingValueLong.ok THEN Fail ELSE
    LET finalAskBidTypeCode == ReadBytes(accumulatedTradingValueLong.rest, 1) IN IF ~finalAskBidTypeCode.ok THEN Fail ELSE
    LET askLevel1Price == ReadBytes(finalAskBidTypeCode.rest, 11) IN IF ~askLevel1Price.ok THEN Fail ELSE
    LET bidLevel1Price == ReadBytes(askLevel1Price.rest, 11) IN IF ~bidLevel1Price.ok THEN Fail ELSE
    LET askLevel1Volume == ReadBytes(bidLevel1Price.rest, 12) IN IF ~askLevel1Volume.ok THEN Fail ELSE
    LET bidLevel1Volume == ReadBytes(askLevel1Volume.rest, 12) IN IF ~bidLevel1Volume.ok THEN Fail ELSE
    LET askLevel2Price == ReadBytes(bidLevel1Volume.rest, 11) IN IF ~askLevel2Price.ok THEN Fail ELSE
    LET bidLevel2Price == ReadBytes(askLevel2Price.rest, 11) IN IF ~bidLevel2Price.ok THEN Fail ELSE
    LET askLevel2Volume == ReadBytes(bidLevel2Price.rest, 12) IN IF ~askLevel2Volume.ok THEN Fail ELSE
    LET bidLevel2Volume == ReadBytes(askLevel2Volume.rest, 12) IN IF ~bidLevel2Volume.ok THEN Fail ELSE
    LET askLevel3Price == ReadBytes(bidLevel2Volume.rest, 11) IN IF ~askLevel3Price.ok THEN Fail ELSE
    LET bidLevel3Price == ReadBytes(askLevel3Price.rest, 11) IN IF ~bidLevel3Price.ok THEN Fail ELSE
    LET askLevel3Volume == ReadBytes(bidLevel3Price.rest, 12) IN IF ~askLevel3Volume.ok THEN Fail ELSE
    LET bidLevel3Volume == ReadBytes(askLevel3Volume.rest, 12) IN IF ~bidLevel3Volume.ok THEN Fail ELSE
    LET askLevel4Price == ReadBytes(bidLevel3Volume.rest, 11) IN IF ~askLevel4Price.ok THEN Fail ELSE
    LET bidLevel4Price == ReadBytes(askLevel4Price.rest, 11) IN IF ~bidLevel4Price.ok THEN Fail ELSE
    LET askLevel4Volume == ReadBytes(bidLevel4Price.rest, 12) IN IF ~askLevel4Volume.ok THEN Fail ELSE
    LET bidLevel4Volume == ReadBytes(askLevel4Volume.rest, 12) IN IF ~bidLevel4Volume.ok THEN Fail ELSE
    LET askLevel5Price == ReadBytes(bidLevel4Volume.rest, 11) IN IF ~askLevel5Price.ok THEN Fail ELSE
    LET bidLevel5Price == ReadBytes(askLevel5Price.rest, 11) IN IF ~bidLevel5Price.ok THEN Fail ELSE
    LET askLevel5Volume == ReadBytes(bidLevel5Price.rest, 12) IN IF ~askLevel5Volume.ok THEN Fail ELSE
    LET bidLevel5Volume == ReadBytes(askLevel5Volume.rest, 12) IN IF ~bidLevel5Volume.ok THEN Fail ELSE
    LET totalAskVolume == ReadBytes(bidLevel5Volume.rest, 12) IN IF ~totalAskVolume.ok THEN Fail ELSE
    LET totalBidVolume == ReadBytes(totalAskVolume.rest, 12) IN IF ~totalBidVolume.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(totalBidVolume.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber         |-> messageSequenceNumber.value,
         boardId                       |-> boardId.value,
         sessionId                     |-> sessionId.value,
         isinCode                      |-> isinCode.value,
         aDesignatedNumberForAnIssue   |-> aDesignatedNumberForAnIssue.value,
         processingTimeOfTradingSystem |-> processingTimeOfTradingSystem.value,
         tradingPrice                  |-> tradingPrice.value,
         tradingVolume                 |-> tradingVolume.value,
         openingPriceLong              |-> openingPriceLong.value,
         todaysHigh                    |-> todaysHigh.value,
         todaysLow                     |-> todaysLow.value,
         previousPrice                 |-> previousPrice.value,
         accumulatedTradingVolume      |-> accumulatedTradingVolume.value,
         accumulatedTradingValueLong   |-> accumulatedTradingValueLong.value,
         finalAskBidTypeCode           |-> finalAskBidTypeCode.value,
         askLevel1Price                |-> askLevel1Price.value,
         bidLevel1Price                |-> bidLevel1Price.value,
         askLevel1Volume               |-> askLevel1Volume.value,
         bidLevel1Volume               |-> bidLevel1Volume.value,
         askLevel2Price                |-> askLevel2Price.value,
         bidLevel2Price                |-> bidLevel2Price.value,
         askLevel2Volume               |-> askLevel2Volume.value,
         bidLevel2Volume               |-> bidLevel2Volume.value,
         askLevel3Price                |-> askLevel3Price.value,
         bidLevel3Price                |-> bidLevel3Price.value,
         askLevel3Volume               |-> askLevel3Volume.value,
         bidLevel3Volume               |-> bidLevel3Volume.value,
         askLevel4Price                |-> askLevel4Price.value,
         bidLevel4Price                |-> bidLevel4Price.value,
         askLevel4Volume               |-> askLevel4Volume.value,
         bidLevel4Volume               |-> bidLevel4Volume.value,
         askLevel5Price                |-> askLevel5Price.value,
         bidLevel5Price                |-> bidLevel5Price.value,
         askLevel5Volume               |-> askLevel5Volume.value,
         bidLevel5Volume               |-> bidLevel5Volume.value,
         totalAskVolume                |-> totalAskVolume.value,
         totalBidVolume                |-> totalBidVolume.value,
         endKeyword                    |-> endKeyword.value ], endKeyword.rest)

ZeroEmissionsOrderFilledPlusQuoteMessage ==
    [ messageSequenceNumber         |-> [i \in 1 .. 8 |-> 0],
      boardId                       |-> [i \in 1 .. 2 |-> 0],
      sessionId                     |-> [i \in 1 .. 2 |-> 0],
      isinCode                      |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue   |-> [i \in 1 .. 6 |-> 0],
      processingTimeOfTradingSystem |-> [i \in 1 .. 12 |-> 0],
      tradingPrice                  |-> [i \in 1 .. 11 |-> 0],
      tradingVolume                 |-> [i \in 1 .. 10 |-> 0],
      openingPriceLong              |-> [i \in 1 .. 11 |-> 0],
      todaysHigh                    |-> [i \in 1 .. 11 |-> 0],
      todaysLow                     |-> [i \in 1 .. 11 |-> 0],
      previousPrice                 |-> [i \in 1 .. 11 |-> 0],
      accumulatedTradingVolume      |-> [i \in 1 .. 12 |-> 0],
      accumulatedTradingValueLong   |-> [i \in 1 .. 22 |-> 0],
      finalAskBidTypeCode           |-> [i \in 1 .. 1 |-> 0],
      askLevel1Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel1Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel1Volume               |-> [i \in 1 .. 12 |-> 0],
      bidLevel1Volume               |-> [i \in 1 .. 12 |-> 0],
      askLevel2Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel2Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel2Volume               |-> [i \in 1 .. 12 |-> 0],
      bidLevel2Volume               |-> [i \in 1 .. 12 |-> 0],
      askLevel3Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel3Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel3Volume               |-> [i \in 1 .. 12 |-> 0],
      bidLevel3Volume               |-> [i \in 1 .. 12 |-> 0],
      askLevel4Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel4Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel4Volume               |-> [i \in 1 .. 12 |-> 0],
      bidLevel4Volume               |-> [i \in 1 .. 12 |-> 0],
      askLevel5Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel5Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel5Volume               |-> [i \in 1 .. 12 |-> 0],
      bidLevel5Volume               |-> [i \in 1 .. 12 |-> 0],
      totalAskVolume                |-> [i \in 1 .. 12 |-> 0],
      totalBidVolume                |-> [i \in 1 .. 12 |-> 0],
      endKeyword                    |-> [i \in 1 .. 1 |-> 0] ]

(* Emissions Order Filled Plus Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedEmissionsOrderFilledPlusQuoteMessage ==
    { ZeroEmissionsOrderFilledPlusQuoteMessage }
        \cup { [ZeroEmissionsOrderFilledPlusQuoteMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroEmissionsOrderFilledPlusQuoteMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroEmissionsOrderFilledPlusQuoteMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroEmissionsOrderFilledPlusQuoteMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsOrderFilledPlusQuoteMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroEmissionsOrderFilledPlusQuoteMessage EXCEPT !.processingTimeOfTradingSystem = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsOrderFilledPlusQuoteMessage EXCEPT !.tradingPrice = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsOrderFilledPlusQuoteMessage EXCEPT !.tradingVolume = one] : one \in Sample(10) }
        \cup { [ZeroEmissionsOrderFilledPlusQuoteMessage EXCEPT !.openingPriceLong = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsOrderFilledPlusQuoteMessage EXCEPT !.todaysHigh = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsOrderFilledPlusQuoteMessage EXCEPT !.todaysLow = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsOrderFilledPlusQuoteMessage EXCEPT !.previousPrice = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsOrderFilledPlusQuoteMessage EXCEPT !.accumulatedTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsOrderFilledPlusQuoteMessage EXCEPT !.accumulatedTradingValueLong = one] : one \in Sample(22) }
        \cup { [ZeroEmissionsOrderFilledPlusQuoteMessage EXCEPT !.finalAskBidTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroEmissionsOrderFilledPlusQuoteMessage EXCEPT !.askLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsOrderFilledPlusQuoteMessage EXCEPT !.bidLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsOrderFilledPlusQuoteMessage EXCEPT !.askLevel1Volume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsOrderFilledPlusQuoteMessage EXCEPT !.bidLevel1Volume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsOrderFilledPlusQuoteMessage EXCEPT !.askLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsOrderFilledPlusQuoteMessage EXCEPT !.bidLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsOrderFilledPlusQuoteMessage EXCEPT !.askLevel2Volume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsOrderFilledPlusQuoteMessage EXCEPT !.bidLevel2Volume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsOrderFilledPlusQuoteMessage EXCEPT !.askLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsOrderFilledPlusQuoteMessage EXCEPT !.bidLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsOrderFilledPlusQuoteMessage EXCEPT !.askLevel3Volume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsOrderFilledPlusQuoteMessage EXCEPT !.bidLevel3Volume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsOrderFilledPlusQuoteMessage EXCEPT !.askLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsOrderFilledPlusQuoteMessage EXCEPT !.bidLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsOrderFilledPlusQuoteMessage EXCEPT !.askLevel4Volume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsOrderFilledPlusQuoteMessage EXCEPT !.bidLevel4Volume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsOrderFilledPlusQuoteMessage EXCEPT !.askLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsOrderFilledPlusQuoteMessage EXCEPT !.bidLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsOrderFilledPlusQuoteMessage EXCEPT !.askLevel5Volume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsOrderFilledPlusQuoteMessage EXCEPT !.bidLevel5Volume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsOrderFilledPlusQuoteMessage EXCEPT !.totalAskVolume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsOrderFilledPlusQuoteMessage EXCEPT !.totalBidVolume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsOrderFilledPlusQuoteMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Emissions Market Operation Ts Plus Quote Message: 340 bytes             *)
(***************************************************************************)

EmissionsMarketOperationTsPlusQuoteMessage ==
    [ messageSequenceNumber         : Sample(8),
      boardId                       : Sample(2),
      sessionId                     : Sample(2),
      isinCode                      : Sample(12),
      aDesignatedNumberForAnIssue   : Sample(6),
      processingTimeOfTradingSystem : Sample(12),
      boardEventId                  : Sample(3),
      startTimeOfABoardEvent        : Sample(9),
      boardEventGroupCode           : Sample(5),
      tradingHaltReasonCode         : Sample(3),
      askLevel1Price                : Sample(11),
      bidLevel1Price                : Sample(11),
      askLevel1Volume               : Sample(12),
      bidLevel1Volume               : Sample(12),
      askLevel2Price                : Sample(11),
      bidLevel2Price                : Sample(11),
      askLevel2Volume               : Sample(12),
      bidLevel2Volume               : Sample(12),
      askLevel3Price                : Sample(11),
      bidLevel3Price                : Sample(11),
      askLevel3Volume               : Sample(12),
      bidLevel3Volume               : Sample(12),
      askLevel4Price                : Sample(11),
      bidLevel4Price                : Sample(11),
      askLevel4Volume               : Sample(12),
      bidLevel4Volume               : Sample(12),
      askLevel5Price                : Sample(11),
      bidLevel5Price                : Sample(11),
      askLevel5Volume               : Sample(12),
      bidLevel5Volume               : Sample(12),
      totalAskVolume                : Sample(12),
      totalBidVolume                : Sample(12),
      estimatedTradingPrice         : Sample(11),
      estimatedTradingVolume        : Sample(12),
      endKeyword                    : Sample(1) ]

EncodeEmissionsMarketOperationTsPlusQuoteMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.sessionId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.processingTimeOfTradingSystem
        \o message.boardEventId
        \o message.startTimeOfABoardEvent
        \o message.boardEventGroupCode
        \o message.tradingHaltReasonCode
        \o message.askLevel1Price
        \o message.bidLevel1Price
        \o message.askLevel1Volume
        \o message.bidLevel1Volume
        \o message.askLevel2Price
        \o message.bidLevel2Price
        \o message.askLevel2Volume
        \o message.bidLevel2Volume
        \o message.askLevel3Price
        \o message.bidLevel3Price
        \o message.askLevel3Volume
        \o message.bidLevel3Volume
        \o message.askLevel4Price
        \o message.bidLevel4Price
        \o message.askLevel4Volume
        \o message.bidLevel4Volume
        \o message.askLevel5Price
        \o message.bidLevel5Price
        \o message.askLevel5Volume
        \o message.bidLevel5Volume
        \o message.totalAskVolume
        \o message.totalBidVolume
        \o message.estimatedTradingPrice
        \o message.estimatedTradingVolume
        \o message.endKeyword

DecodeEmissionsMarketOperationTsPlusQuoteMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(boardId.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(sessionId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET processingTimeOfTradingSystem == ReadBytes(aDesignatedNumberForAnIssue.rest, 12) IN IF ~processingTimeOfTradingSystem.ok THEN Fail ELSE
    LET boardEventId == ReadBytes(processingTimeOfTradingSystem.rest, 3) IN IF ~boardEventId.ok THEN Fail ELSE
    LET startTimeOfABoardEvent == ReadBytes(boardEventId.rest, 9) IN IF ~startTimeOfABoardEvent.ok THEN Fail ELSE
    LET boardEventGroupCode == ReadBytes(startTimeOfABoardEvent.rest, 5) IN IF ~boardEventGroupCode.ok THEN Fail ELSE
    LET tradingHaltReasonCode == ReadBytes(boardEventGroupCode.rest, 3) IN IF ~tradingHaltReasonCode.ok THEN Fail ELSE
    LET askLevel1Price == ReadBytes(tradingHaltReasonCode.rest, 11) IN IF ~askLevel1Price.ok THEN Fail ELSE
    LET bidLevel1Price == ReadBytes(askLevel1Price.rest, 11) IN IF ~bidLevel1Price.ok THEN Fail ELSE
    LET askLevel1Volume == ReadBytes(bidLevel1Price.rest, 12) IN IF ~askLevel1Volume.ok THEN Fail ELSE
    LET bidLevel1Volume == ReadBytes(askLevel1Volume.rest, 12) IN IF ~bidLevel1Volume.ok THEN Fail ELSE
    LET askLevel2Price == ReadBytes(bidLevel1Volume.rest, 11) IN IF ~askLevel2Price.ok THEN Fail ELSE
    LET bidLevel2Price == ReadBytes(askLevel2Price.rest, 11) IN IF ~bidLevel2Price.ok THEN Fail ELSE
    LET askLevel2Volume == ReadBytes(bidLevel2Price.rest, 12) IN IF ~askLevel2Volume.ok THEN Fail ELSE
    LET bidLevel2Volume == ReadBytes(askLevel2Volume.rest, 12) IN IF ~bidLevel2Volume.ok THEN Fail ELSE
    LET askLevel3Price == ReadBytes(bidLevel2Volume.rest, 11) IN IF ~askLevel3Price.ok THEN Fail ELSE
    LET bidLevel3Price == ReadBytes(askLevel3Price.rest, 11) IN IF ~bidLevel3Price.ok THEN Fail ELSE
    LET askLevel3Volume == ReadBytes(bidLevel3Price.rest, 12) IN IF ~askLevel3Volume.ok THEN Fail ELSE
    LET bidLevel3Volume == ReadBytes(askLevel3Volume.rest, 12) IN IF ~bidLevel3Volume.ok THEN Fail ELSE
    LET askLevel4Price == ReadBytes(bidLevel3Volume.rest, 11) IN IF ~askLevel4Price.ok THEN Fail ELSE
    LET bidLevel4Price == ReadBytes(askLevel4Price.rest, 11) IN IF ~bidLevel4Price.ok THEN Fail ELSE
    LET askLevel4Volume == ReadBytes(bidLevel4Price.rest, 12) IN IF ~askLevel4Volume.ok THEN Fail ELSE
    LET bidLevel4Volume == ReadBytes(askLevel4Volume.rest, 12) IN IF ~bidLevel4Volume.ok THEN Fail ELSE
    LET askLevel5Price == ReadBytes(bidLevel4Volume.rest, 11) IN IF ~askLevel5Price.ok THEN Fail ELSE
    LET bidLevel5Price == ReadBytes(askLevel5Price.rest, 11) IN IF ~bidLevel5Price.ok THEN Fail ELSE
    LET askLevel5Volume == ReadBytes(bidLevel5Price.rest, 12) IN IF ~askLevel5Volume.ok THEN Fail ELSE
    LET bidLevel5Volume == ReadBytes(askLevel5Volume.rest, 12) IN IF ~bidLevel5Volume.ok THEN Fail ELSE
    LET totalAskVolume == ReadBytes(bidLevel5Volume.rest, 12) IN IF ~totalAskVolume.ok THEN Fail ELSE
    LET totalBidVolume == ReadBytes(totalAskVolume.rest, 12) IN IF ~totalBidVolume.ok THEN Fail ELSE
    LET estimatedTradingPrice == ReadBytes(totalBidVolume.rest, 11) IN IF ~estimatedTradingPrice.ok THEN Fail ELSE
    LET estimatedTradingVolume == ReadBytes(estimatedTradingPrice.rest, 12) IN IF ~estimatedTradingVolume.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(estimatedTradingVolume.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber         |-> messageSequenceNumber.value,
         boardId                       |-> boardId.value,
         sessionId                     |-> sessionId.value,
         isinCode                      |-> isinCode.value,
         aDesignatedNumberForAnIssue   |-> aDesignatedNumberForAnIssue.value,
         processingTimeOfTradingSystem |-> processingTimeOfTradingSystem.value,
         boardEventId                  |-> boardEventId.value,
         startTimeOfABoardEvent        |-> startTimeOfABoardEvent.value,
         boardEventGroupCode           |-> boardEventGroupCode.value,
         tradingHaltReasonCode         |-> tradingHaltReasonCode.value,
         askLevel1Price                |-> askLevel1Price.value,
         bidLevel1Price                |-> bidLevel1Price.value,
         askLevel1Volume               |-> askLevel1Volume.value,
         bidLevel1Volume               |-> bidLevel1Volume.value,
         askLevel2Price                |-> askLevel2Price.value,
         bidLevel2Price                |-> bidLevel2Price.value,
         askLevel2Volume               |-> askLevel2Volume.value,
         bidLevel2Volume               |-> bidLevel2Volume.value,
         askLevel3Price                |-> askLevel3Price.value,
         bidLevel3Price                |-> bidLevel3Price.value,
         askLevel3Volume               |-> askLevel3Volume.value,
         bidLevel3Volume               |-> bidLevel3Volume.value,
         askLevel4Price                |-> askLevel4Price.value,
         bidLevel4Price                |-> bidLevel4Price.value,
         askLevel4Volume               |-> askLevel4Volume.value,
         bidLevel4Volume               |-> bidLevel4Volume.value,
         askLevel5Price                |-> askLevel5Price.value,
         bidLevel5Price                |-> bidLevel5Price.value,
         askLevel5Volume               |-> askLevel5Volume.value,
         bidLevel5Volume               |-> bidLevel5Volume.value,
         totalAskVolume                |-> totalAskVolume.value,
         totalBidVolume                |-> totalBidVolume.value,
         estimatedTradingPrice         |-> estimatedTradingPrice.value,
         estimatedTradingVolume        |-> estimatedTradingVolume.value,
         endKeyword                    |-> endKeyword.value ], endKeyword.rest)

ZeroEmissionsMarketOperationTsPlusQuoteMessage ==
    [ messageSequenceNumber         |-> [i \in 1 .. 8 |-> 0],
      boardId                       |-> [i \in 1 .. 2 |-> 0],
      sessionId                     |-> [i \in 1 .. 2 |-> 0],
      isinCode                      |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue   |-> [i \in 1 .. 6 |-> 0],
      processingTimeOfTradingSystem |-> [i \in 1 .. 12 |-> 0],
      boardEventId                  |-> [i \in 1 .. 3 |-> 0],
      startTimeOfABoardEvent        |-> [i \in 1 .. 9 |-> 0],
      boardEventGroupCode           |-> [i \in 1 .. 5 |-> 0],
      tradingHaltReasonCode         |-> [i \in 1 .. 3 |-> 0],
      askLevel1Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel1Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel1Volume               |-> [i \in 1 .. 12 |-> 0],
      bidLevel1Volume               |-> [i \in 1 .. 12 |-> 0],
      askLevel2Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel2Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel2Volume               |-> [i \in 1 .. 12 |-> 0],
      bidLevel2Volume               |-> [i \in 1 .. 12 |-> 0],
      askLevel3Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel3Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel3Volume               |-> [i \in 1 .. 12 |-> 0],
      bidLevel3Volume               |-> [i \in 1 .. 12 |-> 0],
      askLevel4Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel4Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel4Volume               |-> [i \in 1 .. 12 |-> 0],
      bidLevel4Volume               |-> [i \in 1 .. 12 |-> 0],
      askLevel5Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel5Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel5Volume               |-> [i \in 1 .. 12 |-> 0],
      bidLevel5Volume               |-> [i \in 1 .. 12 |-> 0],
      totalAskVolume                |-> [i \in 1 .. 12 |-> 0],
      totalBidVolume                |-> [i \in 1 .. 12 |-> 0],
      estimatedTradingPrice         |-> [i \in 1 .. 11 |-> 0],
      estimatedTradingVolume        |-> [i \in 1 .. 12 |-> 0],
      endKeyword                    |-> [i \in 1 .. 1 |-> 0] ]

(* Emissions Market Operation Ts Plus Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedEmissionsMarketOperationTsPlusQuoteMessage ==
    { ZeroEmissionsMarketOperationTsPlusQuoteMessage }
        \cup { [ZeroEmissionsMarketOperationTsPlusQuoteMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroEmissionsMarketOperationTsPlusQuoteMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroEmissionsMarketOperationTsPlusQuoteMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroEmissionsMarketOperationTsPlusQuoteMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsMarketOperationTsPlusQuoteMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroEmissionsMarketOperationTsPlusQuoteMessage EXCEPT !.processingTimeOfTradingSystem = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsMarketOperationTsPlusQuoteMessage EXCEPT !.boardEventId = one] : one \in Sample(3) }
        \cup { [ZeroEmissionsMarketOperationTsPlusQuoteMessage EXCEPT !.startTimeOfABoardEvent = one] : one \in Sample(9) }
        \cup { [ZeroEmissionsMarketOperationTsPlusQuoteMessage EXCEPT !.boardEventGroupCode = one] : one \in Sample(5) }
        \cup { [ZeroEmissionsMarketOperationTsPlusQuoteMessage EXCEPT !.tradingHaltReasonCode = one] : one \in Sample(3) }
        \cup { [ZeroEmissionsMarketOperationTsPlusQuoteMessage EXCEPT !.askLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsMarketOperationTsPlusQuoteMessage EXCEPT !.bidLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsMarketOperationTsPlusQuoteMessage EXCEPT !.askLevel1Volume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsMarketOperationTsPlusQuoteMessage EXCEPT !.bidLevel1Volume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsMarketOperationTsPlusQuoteMessage EXCEPT !.askLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsMarketOperationTsPlusQuoteMessage EXCEPT !.bidLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsMarketOperationTsPlusQuoteMessage EXCEPT !.askLevel2Volume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsMarketOperationTsPlusQuoteMessage EXCEPT !.bidLevel2Volume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsMarketOperationTsPlusQuoteMessage EXCEPT !.askLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsMarketOperationTsPlusQuoteMessage EXCEPT !.bidLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsMarketOperationTsPlusQuoteMessage EXCEPT !.askLevel3Volume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsMarketOperationTsPlusQuoteMessage EXCEPT !.bidLevel3Volume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsMarketOperationTsPlusQuoteMessage EXCEPT !.askLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsMarketOperationTsPlusQuoteMessage EXCEPT !.bidLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsMarketOperationTsPlusQuoteMessage EXCEPT !.askLevel4Volume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsMarketOperationTsPlusQuoteMessage EXCEPT !.bidLevel4Volume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsMarketOperationTsPlusQuoteMessage EXCEPT !.askLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsMarketOperationTsPlusQuoteMessage EXCEPT !.bidLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsMarketOperationTsPlusQuoteMessage EXCEPT !.askLevel5Volume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsMarketOperationTsPlusQuoteMessage EXCEPT !.bidLevel5Volume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsMarketOperationTsPlusQuoteMessage EXCEPT !.totalAskVolume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsMarketOperationTsPlusQuoteMessage EXCEPT !.totalBidVolume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsMarketOperationTsPlusQuoteMessage EXCEPT !.estimatedTradingPrice = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsMarketOperationTsPlusQuoteMessage EXCEPT !.estimatedTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsMarketOperationTsPlusQuoteMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Emissions Snapshot Message: 413 bytes                                   *)
(***************************************************************************)

EmissionsSnapshotMessage ==
    [ boardId                           : Sample(2),
      sessionId                         : Sample(2),
      isinCode                          : Sample(12),
      aDesignatedNumberForAnIssue       : Sample(6),
      currentPrice                      : Sample(11),
      openingPriceLong                  : Sample(11),
      todaysHigh                        : Sample(11),
      todaysLow                         : Sample(11),
      accumulatedTradingVolume          : Sample(12),
      accumulatedTradingValueLong       : Sample(22),
      negotiatedBlockTradeTradingVolume : Sample(12),
      negotiatedBlockTradeTradingValue  : Sample(22),
      tradingHalt                       : Sample(1),
      askLevel1Price                    : Sample(11),
      bidLevel1Price                    : Sample(11),
      askLevel1Volume                   : Sample(12),
      bidLevel1Volume                   : Sample(12),
      askLevel2Price                    : Sample(11),
      bidLevel2Price                    : Sample(11),
      askLevel2Volume                   : Sample(12),
      bidLevel2Volume                   : Sample(12),
      askLevel3Price                    : Sample(11),
      bidLevel3Price                    : Sample(11),
      askLevel3Volume                   : Sample(12),
      bidLevel3Volume                   : Sample(12),
      askLevel4Price                    : Sample(11),
      bidLevel4Price                    : Sample(11),
      askLevel4Volume                   : Sample(12),
      bidLevel4Volume                   : Sample(12),
      askLevel5Price                    : Sample(11),
      bidLevel5Price                    : Sample(11),
      askLevel5Volume                   : Sample(12),
      bidLevel5Volume                   : Sample(12),
      totalAskVolume                    : Sample(12),
      totalBidVolume                    : Sample(12),
      estimatedTradingPrice             : Sample(11),
      estimatedTradingVolume            : Sample(12),
      endKeyword                        : Sample(1) ]

EncodeEmissionsSnapshotMessage(message) ==
    message.boardId
        \o message.sessionId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.currentPrice
        \o message.openingPriceLong
        \o message.todaysHigh
        \o message.todaysLow
        \o message.accumulatedTradingVolume
        \o message.accumulatedTradingValueLong
        \o message.negotiatedBlockTradeTradingVolume
        \o message.negotiatedBlockTradeTradingValue
        \o message.tradingHalt
        \o message.askLevel1Price
        \o message.bidLevel1Price
        \o message.askLevel1Volume
        \o message.bidLevel1Volume
        \o message.askLevel2Price
        \o message.bidLevel2Price
        \o message.askLevel2Volume
        \o message.bidLevel2Volume
        \o message.askLevel3Price
        \o message.bidLevel3Price
        \o message.askLevel3Volume
        \o message.bidLevel3Volume
        \o message.askLevel4Price
        \o message.bidLevel4Price
        \o message.askLevel4Volume
        \o message.bidLevel4Volume
        \o message.askLevel5Price
        \o message.bidLevel5Price
        \o message.askLevel5Volume
        \o message.bidLevel5Volume
        \o message.totalAskVolume
        \o message.totalBidVolume
        \o message.estimatedTradingPrice
        \o message.estimatedTradingVolume
        \o message.endKeyword

DecodeEmissionsSnapshotMessage(bytes) ==
    LET boardId == ReadBytes(bytes, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(boardId.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(sessionId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET currentPrice == ReadBytes(aDesignatedNumberForAnIssue.rest, 11) IN IF ~currentPrice.ok THEN Fail ELSE
    LET openingPriceLong == ReadBytes(currentPrice.rest, 11) IN IF ~openingPriceLong.ok THEN Fail ELSE
    LET todaysHigh == ReadBytes(openingPriceLong.rest, 11) IN IF ~todaysHigh.ok THEN Fail ELSE
    LET todaysLow == ReadBytes(todaysHigh.rest, 11) IN IF ~todaysLow.ok THEN Fail ELSE
    LET accumulatedTradingVolume == ReadBytes(todaysLow.rest, 12) IN IF ~accumulatedTradingVolume.ok THEN Fail ELSE
    LET accumulatedTradingValueLong == ReadBytes(accumulatedTradingVolume.rest, 22) IN IF ~accumulatedTradingValueLong.ok THEN Fail ELSE
    LET negotiatedBlockTradeTradingVolume == ReadBytes(accumulatedTradingValueLong.rest, 12) IN IF ~negotiatedBlockTradeTradingVolume.ok THEN Fail ELSE
    LET negotiatedBlockTradeTradingValue == ReadBytes(negotiatedBlockTradeTradingVolume.rest, 22) IN IF ~negotiatedBlockTradeTradingValue.ok THEN Fail ELSE
    LET tradingHalt == ReadBytes(negotiatedBlockTradeTradingValue.rest, 1) IN IF ~tradingHalt.ok THEN Fail ELSE
    LET askLevel1Price == ReadBytes(tradingHalt.rest, 11) IN IF ~askLevel1Price.ok THEN Fail ELSE
    LET bidLevel1Price == ReadBytes(askLevel1Price.rest, 11) IN IF ~bidLevel1Price.ok THEN Fail ELSE
    LET askLevel1Volume == ReadBytes(bidLevel1Price.rest, 12) IN IF ~askLevel1Volume.ok THEN Fail ELSE
    LET bidLevel1Volume == ReadBytes(askLevel1Volume.rest, 12) IN IF ~bidLevel1Volume.ok THEN Fail ELSE
    LET askLevel2Price == ReadBytes(bidLevel1Volume.rest, 11) IN IF ~askLevel2Price.ok THEN Fail ELSE
    LET bidLevel2Price == ReadBytes(askLevel2Price.rest, 11) IN IF ~bidLevel2Price.ok THEN Fail ELSE
    LET askLevel2Volume == ReadBytes(bidLevel2Price.rest, 12) IN IF ~askLevel2Volume.ok THEN Fail ELSE
    LET bidLevel2Volume == ReadBytes(askLevel2Volume.rest, 12) IN IF ~bidLevel2Volume.ok THEN Fail ELSE
    LET askLevel3Price == ReadBytes(bidLevel2Volume.rest, 11) IN IF ~askLevel3Price.ok THEN Fail ELSE
    LET bidLevel3Price == ReadBytes(askLevel3Price.rest, 11) IN IF ~bidLevel3Price.ok THEN Fail ELSE
    LET askLevel3Volume == ReadBytes(bidLevel3Price.rest, 12) IN IF ~askLevel3Volume.ok THEN Fail ELSE
    LET bidLevel3Volume == ReadBytes(askLevel3Volume.rest, 12) IN IF ~bidLevel3Volume.ok THEN Fail ELSE
    LET askLevel4Price == ReadBytes(bidLevel3Volume.rest, 11) IN IF ~askLevel4Price.ok THEN Fail ELSE
    LET bidLevel4Price == ReadBytes(askLevel4Price.rest, 11) IN IF ~bidLevel4Price.ok THEN Fail ELSE
    LET askLevel4Volume == ReadBytes(bidLevel4Price.rest, 12) IN IF ~askLevel4Volume.ok THEN Fail ELSE
    LET bidLevel4Volume == ReadBytes(askLevel4Volume.rest, 12) IN IF ~bidLevel4Volume.ok THEN Fail ELSE
    LET askLevel5Price == ReadBytes(bidLevel4Volume.rest, 11) IN IF ~askLevel5Price.ok THEN Fail ELSE
    LET bidLevel5Price == ReadBytes(askLevel5Price.rest, 11) IN IF ~bidLevel5Price.ok THEN Fail ELSE
    LET askLevel5Volume == ReadBytes(bidLevel5Price.rest, 12) IN IF ~askLevel5Volume.ok THEN Fail ELSE
    LET bidLevel5Volume == ReadBytes(askLevel5Volume.rest, 12) IN IF ~bidLevel5Volume.ok THEN Fail ELSE
    LET totalAskVolume == ReadBytes(bidLevel5Volume.rest, 12) IN IF ~totalAskVolume.ok THEN Fail ELSE
    LET totalBidVolume == ReadBytes(totalAskVolume.rest, 12) IN IF ~totalBidVolume.ok THEN Fail ELSE
    LET estimatedTradingPrice == ReadBytes(totalBidVolume.rest, 11) IN IF ~estimatedTradingPrice.ok THEN Fail ELSE
    LET estimatedTradingVolume == ReadBytes(estimatedTradingPrice.rest, 12) IN IF ~estimatedTradingVolume.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(estimatedTradingVolume.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ boardId                           |-> boardId.value,
         sessionId                         |-> sessionId.value,
         isinCode                          |-> isinCode.value,
         aDesignatedNumberForAnIssue       |-> aDesignatedNumberForAnIssue.value,
         currentPrice                      |-> currentPrice.value,
         openingPriceLong                  |-> openingPriceLong.value,
         todaysHigh                        |-> todaysHigh.value,
         todaysLow                         |-> todaysLow.value,
         accumulatedTradingVolume          |-> accumulatedTradingVolume.value,
         accumulatedTradingValueLong       |-> accumulatedTradingValueLong.value,
         negotiatedBlockTradeTradingVolume |-> negotiatedBlockTradeTradingVolume.value,
         negotiatedBlockTradeTradingValue  |-> negotiatedBlockTradeTradingValue.value,
         tradingHalt                       |-> tradingHalt.value,
         askLevel1Price                    |-> askLevel1Price.value,
         bidLevel1Price                    |-> bidLevel1Price.value,
         askLevel1Volume                   |-> askLevel1Volume.value,
         bidLevel1Volume                   |-> bidLevel1Volume.value,
         askLevel2Price                    |-> askLevel2Price.value,
         bidLevel2Price                    |-> bidLevel2Price.value,
         askLevel2Volume                   |-> askLevel2Volume.value,
         bidLevel2Volume                   |-> bidLevel2Volume.value,
         askLevel3Price                    |-> askLevel3Price.value,
         bidLevel3Price                    |-> bidLevel3Price.value,
         askLevel3Volume                   |-> askLevel3Volume.value,
         bidLevel3Volume                   |-> bidLevel3Volume.value,
         askLevel4Price                    |-> askLevel4Price.value,
         bidLevel4Price                    |-> bidLevel4Price.value,
         askLevel4Volume                   |-> askLevel4Volume.value,
         bidLevel4Volume                   |-> bidLevel4Volume.value,
         askLevel5Price                    |-> askLevel5Price.value,
         bidLevel5Price                    |-> bidLevel5Price.value,
         askLevel5Volume                   |-> askLevel5Volume.value,
         bidLevel5Volume                   |-> bidLevel5Volume.value,
         totalAskVolume                    |-> totalAskVolume.value,
         totalBidVolume                    |-> totalBidVolume.value,
         estimatedTradingPrice             |-> estimatedTradingPrice.value,
         estimatedTradingVolume            |-> estimatedTradingVolume.value,
         endKeyword                        |-> endKeyword.value ], endKeyword.rest)

ZeroEmissionsSnapshotMessage ==
    [ boardId                           |-> [i \in 1 .. 2 |-> 0],
      sessionId                         |-> [i \in 1 .. 2 |-> 0],
      isinCode                          |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue       |-> [i \in 1 .. 6 |-> 0],
      currentPrice                      |-> [i \in 1 .. 11 |-> 0],
      openingPriceLong                  |-> [i \in 1 .. 11 |-> 0],
      todaysHigh                        |-> [i \in 1 .. 11 |-> 0],
      todaysLow                         |-> [i \in 1 .. 11 |-> 0],
      accumulatedTradingVolume          |-> [i \in 1 .. 12 |-> 0],
      accumulatedTradingValueLong       |-> [i \in 1 .. 22 |-> 0],
      negotiatedBlockTradeTradingVolume |-> [i \in 1 .. 12 |-> 0],
      negotiatedBlockTradeTradingValue  |-> [i \in 1 .. 22 |-> 0],
      tradingHalt                       |-> [i \in 1 .. 1 |-> 0],
      askLevel1Price                    |-> [i \in 1 .. 11 |-> 0],
      bidLevel1Price                    |-> [i \in 1 .. 11 |-> 0],
      askLevel1Volume                   |-> [i \in 1 .. 12 |-> 0],
      bidLevel1Volume                   |-> [i \in 1 .. 12 |-> 0],
      askLevel2Price                    |-> [i \in 1 .. 11 |-> 0],
      bidLevel2Price                    |-> [i \in 1 .. 11 |-> 0],
      askLevel2Volume                   |-> [i \in 1 .. 12 |-> 0],
      bidLevel2Volume                   |-> [i \in 1 .. 12 |-> 0],
      askLevel3Price                    |-> [i \in 1 .. 11 |-> 0],
      bidLevel3Price                    |-> [i \in 1 .. 11 |-> 0],
      askLevel3Volume                   |-> [i \in 1 .. 12 |-> 0],
      bidLevel3Volume                   |-> [i \in 1 .. 12 |-> 0],
      askLevel4Price                    |-> [i \in 1 .. 11 |-> 0],
      bidLevel4Price                    |-> [i \in 1 .. 11 |-> 0],
      askLevel4Volume                   |-> [i \in 1 .. 12 |-> 0],
      bidLevel4Volume                   |-> [i \in 1 .. 12 |-> 0],
      askLevel5Price                    |-> [i \in 1 .. 11 |-> 0],
      bidLevel5Price                    |-> [i \in 1 .. 11 |-> 0],
      askLevel5Volume                   |-> [i \in 1 .. 12 |-> 0],
      bidLevel5Volume                   |-> [i \in 1 .. 12 |-> 0],
      totalAskVolume                    |-> [i \in 1 .. 12 |-> 0],
      totalBidVolume                    |-> [i \in 1 .. 12 |-> 0],
      estimatedTradingPrice             |-> [i \in 1 .. 11 |-> 0],
      estimatedTradingVolume            |-> [i \in 1 .. 12 |-> 0],
      endKeyword                        |-> [i \in 1 .. 1 |-> 0] ]

(* Emissions Snapshot Message at zero, then each field in turn at the values it is checked at *)
CheckedEmissionsSnapshotMessage ==
    { ZeroEmissionsSnapshotMessage }
        \cup { [ZeroEmissionsSnapshotMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroEmissionsSnapshotMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroEmissionsSnapshotMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsSnapshotMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroEmissionsSnapshotMessage EXCEPT !.currentPrice = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsSnapshotMessage EXCEPT !.openingPriceLong = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsSnapshotMessage EXCEPT !.todaysHigh = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsSnapshotMessage EXCEPT !.todaysLow = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsSnapshotMessage EXCEPT !.accumulatedTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsSnapshotMessage EXCEPT !.accumulatedTradingValueLong = one] : one \in Sample(22) }
        \cup { [ZeroEmissionsSnapshotMessage EXCEPT !.negotiatedBlockTradeTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsSnapshotMessage EXCEPT !.negotiatedBlockTradeTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroEmissionsSnapshotMessage EXCEPT !.tradingHalt = one] : one \in Sample(1) }
        \cup { [ZeroEmissionsSnapshotMessage EXCEPT !.askLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsSnapshotMessage EXCEPT !.bidLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsSnapshotMessage EXCEPT !.askLevel1Volume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsSnapshotMessage EXCEPT !.bidLevel1Volume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsSnapshotMessage EXCEPT !.askLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsSnapshotMessage EXCEPT !.bidLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsSnapshotMessage EXCEPT !.askLevel2Volume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsSnapshotMessage EXCEPT !.bidLevel2Volume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsSnapshotMessage EXCEPT !.askLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsSnapshotMessage EXCEPT !.bidLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsSnapshotMessage EXCEPT !.askLevel3Volume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsSnapshotMessage EXCEPT !.bidLevel3Volume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsSnapshotMessage EXCEPT !.askLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsSnapshotMessage EXCEPT !.bidLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsSnapshotMessage EXCEPT !.askLevel4Volume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsSnapshotMessage EXCEPT !.bidLevel4Volume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsSnapshotMessage EXCEPT !.askLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsSnapshotMessage EXCEPT !.bidLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsSnapshotMessage EXCEPT !.askLevel5Volume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsSnapshotMessage EXCEPT !.bidLevel5Volume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsSnapshotMessage EXCEPT !.totalAskVolume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsSnapshotMessage EXCEPT !.totalBidVolume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsSnapshotMessage EXCEPT !.estimatedTradingPrice = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsSnapshotMessage EXCEPT !.estimatedTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsSnapshotMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Emissions Negotiated Trade Message: 76 bytes                            *)
(***************************************************************************)

EmissionsNegotiatedTradeMessage ==
    [ boardId                     : Sample(2),
      isinCode                    : Sample(12),
      aDesignatedNumberForAnIssue : Sample(6),
      tradingPrice                : Sample(11),
      tradingVolume               : Sample(10),
      accumulatedTradingVolume    : Sample(12),
      accumulatedTradingValueLong : Sample(22),
      endKeyword                  : Sample(1) ]

EncodeEmissionsNegotiatedTradeMessage(message) ==
    message.boardId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.tradingPrice
        \o message.tradingVolume
        \o message.accumulatedTradingVolume
        \o message.accumulatedTradingValueLong
        \o message.endKeyword

DecodeEmissionsNegotiatedTradeMessage(bytes) ==
    LET boardId == ReadBytes(bytes, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(boardId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET tradingPrice == ReadBytes(aDesignatedNumberForAnIssue.rest, 11) IN IF ~tradingPrice.ok THEN Fail ELSE
    LET tradingVolume == ReadBytes(tradingPrice.rest, 10) IN IF ~tradingVolume.ok THEN Fail ELSE
    LET accumulatedTradingVolume == ReadBytes(tradingVolume.rest, 12) IN IF ~accumulatedTradingVolume.ok THEN Fail ELSE
    LET accumulatedTradingValueLong == ReadBytes(accumulatedTradingVolume.rest, 22) IN IF ~accumulatedTradingValueLong.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(accumulatedTradingValueLong.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ boardId                     |-> boardId.value,
         isinCode                    |-> isinCode.value,
         aDesignatedNumberForAnIssue |-> aDesignatedNumberForAnIssue.value,
         tradingPrice                |-> tradingPrice.value,
         tradingVolume               |-> tradingVolume.value,
         accumulatedTradingVolume    |-> accumulatedTradingVolume.value,
         accumulatedTradingValueLong |-> accumulatedTradingValueLong.value,
         endKeyword                  |-> endKeyword.value ], endKeyword.rest)

ZeroEmissionsNegotiatedTradeMessage ==
    [ boardId                     |-> [i \in 1 .. 2 |-> 0],
      isinCode                    |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue |-> [i \in 1 .. 6 |-> 0],
      tradingPrice                |-> [i \in 1 .. 11 |-> 0],
      tradingVolume               |-> [i \in 1 .. 10 |-> 0],
      accumulatedTradingVolume    |-> [i \in 1 .. 12 |-> 0],
      accumulatedTradingValueLong |-> [i \in 1 .. 22 |-> 0],
      endKeyword                  |-> [i \in 1 .. 1 |-> 0] ]

(* Emissions Negotiated Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedEmissionsNegotiatedTradeMessage ==
    { ZeroEmissionsNegotiatedTradeMessage }
        \cup { [ZeroEmissionsNegotiatedTradeMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroEmissionsNegotiatedTradeMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsNegotiatedTradeMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroEmissionsNegotiatedTradeMessage EXCEPT !.tradingPrice = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsNegotiatedTradeMessage EXCEPT !.tradingVolume = one] : one \in Sample(10) }
        \cup { [ZeroEmissionsNegotiatedTradeMessage EXCEPT !.accumulatedTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsNegotiatedTradeMessage EXCEPT !.accumulatedTradingValueLong = one] : one \in Sample(22) }
        \cup { [ZeroEmissionsNegotiatedTradeMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Emissions Determination Of Base Price Message: 84 bytes                 *)
(***************************************************************************)

EmissionsDeterminationOfBasePriceMessage ==
    [ messageSequenceNumber       : Sample(8),
      boardId                     : Sample(2),
      isinCode                    : Sample(12),
      aDesignatedNumberForAnIssue : Sample(6),
      basePrice                   : Sample(11),
      upperLimitOfBasePrice       : Sample(11),
      lowerLimitOfBasePrice       : Sample(11),
      blockTradingUpperLimitPrice : Sample(11),
      blockTradingLowerLimitPrice : Sample(11),
      endKeyword                  : Sample(1) ]

EncodeEmissionsDeterminationOfBasePriceMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.basePrice
        \o message.upperLimitOfBasePrice
        \o message.lowerLimitOfBasePrice
        \o message.blockTradingUpperLimitPrice
        \o message.blockTradingLowerLimitPrice
        \o message.endKeyword

DecodeEmissionsDeterminationOfBasePriceMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(boardId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET basePrice == ReadBytes(aDesignatedNumberForAnIssue.rest, 11) IN IF ~basePrice.ok THEN Fail ELSE
    LET upperLimitOfBasePrice == ReadBytes(basePrice.rest, 11) IN IF ~upperLimitOfBasePrice.ok THEN Fail ELSE
    LET lowerLimitOfBasePrice == ReadBytes(upperLimitOfBasePrice.rest, 11) IN IF ~lowerLimitOfBasePrice.ok THEN Fail ELSE
    LET blockTradingUpperLimitPrice == ReadBytes(lowerLimitOfBasePrice.rest, 11) IN IF ~blockTradingUpperLimitPrice.ok THEN Fail ELSE
    LET blockTradingLowerLimitPrice == ReadBytes(blockTradingUpperLimitPrice.rest, 11) IN IF ~blockTradingLowerLimitPrice.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(blockTradingLowerLimitPrice.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber       |-> messageSequenceNumber.value,
         boardId                     |-> boardId.value,
         isinCode                    |-> isinCode.value,
         aDesignatedNumberForAnIssue |-> aDesignatedNumberForAnIssue.value,
         basePrice                   |-> basePrice.value,
         upperLimitOfBasePrice       |-> upperLimitOfBasePrice.value,
         lowerLimitOfBasePrice       |-> lowerLimitOfBasePrice.value,
         blockTradingUpperLimitPrice |-> blockTradingUpperLimitPrice.value,
         blockTradingLowerLimitPrice |-> blockTradingLowerLimitPrice.value,
         endKeyword                  |-> endKeyword.value ], endKeyword.rest)

ZeroEmissionsDeterminationOfBasePriceMessage ==
    [ messageSequenceNumber       |-> [i \in 1 .. 8 |-> 0],
      boardId                     |-> [i \in 1 .. 2 |-> 0],
      isinCode                    |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue |-> [i \in 1 .. 6 |-> 0],
      basePrice                   |-> [i \in 1 .. 11 |-> 0],
      upperLimitOfBasePrice       |-> [i \in 1 .. 11 |-> 0],
      lowerLimitOfBasePrice       |-> [i \in 1 .. 11 |-> 0],
      blockTradingUpperLimitPrice |-> [i \in 1 .. 11 |-> 0],
      blockTradingLowerLimitPrice |-> [i \in 1 .. 11 |-> 0],
      endKeyword                  |-> [i \in 1 .. 1 |-> 0] ]

(* Emissions Determination Of Base Price Message at zero, then each field in turn at the values it is checked at *)
CheckedEmissionsDeterminationOfBasePriceMessage ==
    { ZeroEmissionsDeterminationOfBasePriceMessage }
        \cup { [ZeroEmissionsDeterminationOfBasePriceMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroEmissionsDeterminationOfBasePriceMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroEmissionsDeterminationOfBasePriceMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsDeterminationOfBasePriceMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroEmissionsDeterminationOfBasePriceMessage EXCEPT !.basePrice = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsDeterminationOfBasePriceMessage EXCEPT !.upperLimitOfBasePrice = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsDeterminationOfBasePriceMessage EXCEPT !.lowerLimitOfBasePrice = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsDeterminationOfBasePriceMessage EXCEPT !.blockTradingUpperLimitPrice = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsDeterminationOfBasePriceMessage EXCEPT !.blockTradingLowerLimitPrice = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsDeterminationOfBasePriceMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Emissions Auction Results Message: 90 bytes                             *)
(***************************************************************************)

EmissionsAuctionResultsMessage ==
    [ isinCode                    : Sample(12),
      aDesignatedNumberForAnIssue : Sample(6),
      auctionBidVolume            : Sample(12),
      auctionPrice                : Sample(11),
      auctionVolume               : Sample(12),
      volumeInTheBidInvitation    : Sample(12),
      numberOfBidders             : Sample(13),
      bidToCoverRatio             : Sample(11),
      endKeyword                  : Sample(1) ]

EncodeEmissionsAuctionResultsMessage(message) ==
    message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.auctionBidVolume
        \o message.auctionPrice
        \o message.auctionVolume
        \o message.volumeInTheBidInvitation
        \o message.numberOfBidders
        \o message.bidToCoverRatio
        \o message.endKeyword

DecodeEmissionsAuctionResultsMessage(bytes) ==
    LET isinCode == ReadBytes(bytes, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET auctionBidVolume == ReadBytes(aDesignatedNumberForAnIssue.rest, 12) IN IF ~auctionBidVolume.ok THEN Fail ELSE
    LET auctionPrice == ReadBytes(auctionBidVolume.rest, 11) IN IF ~auctionPrice.ok THEN Fail ELSE
    LET auctionVolume == ReadBytes(auctionPrice.rest, 12) IN IF ~auctionVolume.ok THEN Fail ELSE
    LET volumeInTheBidInvitation == ReadBytes(auctionVolume.rest, 12) IN IF ~volumeInTheBidInvitation.ok THEN Fail ELSE
    LET numberOfBidders == ReadBytes(volumeInTheBidInvitation.rest, 13) IN IF ~numberOfBidders.ok THEN Fail ELSE
    LET bidToCoverRatio == ReadBytes(numberOfBidders.rest, 11) IN IF ~bidToCoverRatio.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(bidToCoverRatio.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ isinCode                    |-> isinCode.value,
         aDesignatedNumberForAnIssue |-> aDesignatedNumberForAnIssue.value,
         auctionBidVolume            |-> auctionBidVolume.value,
         auctionPrice                |-> auctionPrice.value,
         auctionVolume               |-> auctionVolume.value,
         volumeInTheBidInvitation    |-> volumeInTheBidInvitation.value,
         numberOfBidders             |-> numberOfBidders.value,
         bidToCoverRatio             |-> bidToCoverRatio.value,
         endKeyword                  |-> endKeyword.value ], endKeyword.rest)

ZeroEmissionsAuctionResultsMessage ==
    [ isinCode                    |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue |-> [i \in 1 .. 6 |-> 0],
      auctionBidVolume            |-> [i \in 1 .. 12 |-> 0],
      auctionPrice                |-> [i \in 1 .. 11 |-> 0],
      auctionVolume               |-> [i \in 1 .. 12 |-> 0],
      volumeInTheBidInvitation    |-> [i \in 1 .. 12 |-> 0],
      numberOfBidders             |-> [i \in 1 .. 13 |-> 0],
      bidToCoverRatio             |-> [i \in 1 .. 11 |-> 0],
      endKeyword                  |-> [i \in 1 .. 1 |-> 0] ]

(* Emissions Auction Results Message at zero, then each field in turn at the values it is checked at *)
CheckedEmissionsAuctionResultsMessage ==
    { ZeroEmissionsAuctionResultsMessage }
        \cup { [ZeroEmissionsAuctionResultsMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsAuctionResultsMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroEmissionsAuctionResultsMessage EXCEPT !.auctionBidVolume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsAuctionResultsMessage EXCEPT !.auctionPrice = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsAuctionResultsMessage EXCEPT !.auctionVolume = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsAuctionResultsMessage EXCEPT !.volumeInTheBidInvitation = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsAuctionResultsMessage EXCEPT !.numberOfBidders = one] : one \in Sample(13) }
        \cup { [ZeroEmissionsAuctionResultsMessage EXCEPT !.bidToCoverRatio = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsAuctionResultsMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Spot Gold Batch Data Message: 408 bytes                                 *)
(***************************************************************************)

SpotGoldBatchDataMessage ==
    [ messageSequenceNumber                    : Sample(8),
      totalNumberOfInstrumentsOfTheContract    : Sample(6),
      businessDate                             : Sample(8),
      isinCode                                 : Sample(12),
      aDesignatedNumberForAnIssue              : Sample(6),
      abbreviatedIssueCode                     : Sample(9),
      issueName                                : Sample(80),
      abbreviatedIssueName                     : Sample(40),
      englishIssueName                         : Sample(80),
      abbreviatedIssueNameInEn                 : Sample(40),
      marketOperationProductId                 : Sample(3),
      securityGroupId                          : Sample(2),
      listingDate                              : Sample(8),
      delistingDate                            : Sample(8),
      marketId                                 : Sample(3),
      upperLimitPrice                          : Sample(11),
      lowerLimitPrice                          : Sample(11),
      basePrice                                : Sample(11),
      randomEndTriggerCode                     : Sample(1),
      tradingHalt                              : Sample(1),
      unitOfVolumeInMainBoard                  : Sample(11),
      yesterdaysClosingPrice                   : Sample(11),
      yesterdaysClosingPriceTypeCode           : Sample(1),
      substitutePriceOfSecurities              : Sample(11),
      appraisalRatioOfSubstitutePrice          : Sample(13),
      aRepresentativeIssueToCalculateBasePrice : Sample(12),
      endKeyword                               : Sample(1) ]

EncodeSpotGoldBatchDataMessage(message) ==
    message.messageSequenceNumber
        \o message.totalNumberOfInstrumentsOfTheContract
        \o message.businessDate
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.abbreviatedIssueCode
        \o message.issueName
        \o message.abbreviatedIssueName
        \o message.englishIssueName
        \o message.abbreviatedIssueNameInEn
        \o message.marketOperationProductId
        \o message.securityGroupId
        \o message.listingDate
        \o message.delistingDate
        \o message.marketId
        \o message.upperLimitPrice
        \o message.lowerLimitPrice
        \o message.basePrice
        \o message.randomEndTriggerCode
        \o message.tradingHalt
        \o message.unitOfVolumeInMainBoard
        \o message.yesterdaysClosingPrice
        \o message.yesterdaysClosingPriceTypeCode
        \o message.substitutePriceOfSecurities
        \o message.appraisalRatioOfSubstitutePrice
        \o message.aRepresentativeIssueToCalculateBasePrice
        \o message.endKeyword

DecodeSpotGoldBatchDataMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET totalNumberOfInstrumentsOfTheContract == ReadBytes(messageSequenceNumber.rest, 6) IN IF ~totalNumberOfInstrumentsOfTheContract.ok THEN Fail ELSE
    LET businessDate == ReadBytes(totalNumberOfInstrumentsOfTheContract.rest, 8) IN IF ~businessDate.ok THEN Fail ELSE
    LET isinCode == ReadBytes(businessDate.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET abbreviatedIssueCode == ReadBytes(aDesignatedNumberForAnIssue.rest, 9) IN IF ~abbreviatedIssueCode.ok THEN Fail ELSE
    LET issueName == ReadBytes(abbreviatedIssueCode.rest, 80) IN IF ~issueName.ok THEN Fail ELSE
    LET abbreviatedIssueName == ReadBytes(issueName.rest, 40) IN IF ~abbreviatedIssueName.ok THEN Fail ELSE
    LET englishIssueName == ReadBytes(abbreviatedIssueName.rest, 80) IN IF ~englishIssueName.ok THEN Fail ELSE
    LET abbreviatedIssueNameInEn == ReadBytes(englishIssueName.rest, 40) IN IF ~abbreviatedIssueNameInEn.ok THEN Fail ELSE
    LET marketOperationProductId == ReadBytes(abbreviatedIssueNameInEn.rest, 3) IN IF ~marketOperationProductId.ok THEN Fail ELSE
    LET securityGroupId == ReadBytes(marketOperationProductId.rest, 2) IN IF ~securityGroupId.ok THEN Fail ELSE
    LET listingDate == ReadBytes(securityGroupId.rest, 8) IN IF ~listingDate.ok THEN Fail ELSE
    LET delistingDate == ReadBytes(listingDate.rest, 8) IN IF ~delistingDate.ok THEN Fail ELSE
    LET marketId == ReadBytes(delistingDate.rest, 3) IN IF ~marketId.ok THEN Fail ELSE
    LET upperLimitPrice == ReadBytes(marketId.rest, 11) IN IF ~upperLimitPrice.ok THEN Fail ELSE
    LET lowerLimitPrice == ReadBytes(upperLimitPrice.rest, 11) IN IF ~lowerLimitPrice.ok THEN Fail ELSE
    LET basePrice == ReadBytes(lowerLimitPrice.rest, 11) IN IF ~basePrice.ok THEN Fail ELSE
    LET randomEndTriggerCode == ReadBytes(basePrice.rest, 1) IN IF ~randomEndTriggerCode.ok THEN Fail ELSE
    LET tradingHalt == ReadBytes(randomEndTriggerCode.rest, 1) IN IF ~tradingHalt.ok THEN Fail ELSE
    LET unitOfVolumeInMainBoard == ReadBytes(tradingHalt.rest, 11) IN IF ~unitOfVolumeInMainBoard.ok THEN Fail ELSE
    LET yesterdaysClosingPrice == ReadBytes(unitOfVolumeInMainBoard.rest, 11) IN IF ~yesterdaysClosingPrice.ok THEN Fail ELSE
    LET yesterdaysClosingPriceTypeCode == ReadBytes(yesterdaysClosingPrice.rest, 1) IN IF ~yesterdaysClosingPriceTypeCode.ok THEN Fail ELSE
    LET substitutePriceOfSecurities == ReadBytes(yesterdaysClosingPriceTypeCode.rest, 11) IN IF ~substitutePriceOfSecurities.ok THEN Fail ELSE
    LET appraisalRatioOfSubstitutePrice == ReadBytes(substitutePriceOfSecurities.rest, 13) IN IF ~appraisalRatioOfSubstitutePrice.ok THEN Fail ELSE
    LET aRepresentativeIssueToCalculateBasePrice == ReadBytes(appraisalRatioOfSubstitutePrice.rest, 12) IN IF ~aRepresentativeIssueToCalculateBasePrice.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(aRepresentativeIssueToCalculateBasePrice.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber                    |-> messageSequenceNumber.value,
         totalNumberOfInstrumentsOfTheContract    |-> totalNumberOfInstrumentsOfTheContract.value,
         businessDate                             |-> businessDate.value,
         isinCode                                 |-> isinCode.value,
         aDesignatedNumberForAnIssue              |-> aDesignatedNumberForAnIssue.value,
         abbreviatedIssueCode                     |-> abbreviatedIssueCode.value,
         issueName                                |-> issueName.value,
         abbreviatedIssueName                     |-> abbreviatedIssueName.value,
         englishIssueName                         |-> englishIssueName.value,
         abbreviatedIssueNameInEn                 |-> abbreviatedIssueNameInEn.value,
         marketOperationProductId                 |-> marketOperationProductId.value,
         securityGroupId                          |-> securityGroupId.value,
         listingDate                              |-> listingDate.value,
         delistingDate                            |-> delistingDate.value,
         marketId                                 |-> marketId.value,
         upperLimitPrice                          |-> upperLimitPrice.value,
         lowerLimitPrice                          |-> lowerLimitPrice.value,
         basePrice                                |-> basePrice.value,
         randomEndTriggerCode                     |-> randomEndTriggerCode.value,
         tradingHalt                              |-> tradingHalt.value,
         unitOfVolumeInMainBoard                  |-> unitOfVolumeInMainBoard.value,
         yesterdaysClosingPrice                   |-> yesterdaysClosingPrice.value,
         yesterdaysClosingPriceTypeCode           |-> yesterdaysClosingPriceTypeCode.value,
         substitutePriceOfSecurities              |-> substitutePriceOfSecurities.value,
         appraisalRatioOfSubstitutePrice          |-> appraisalRatioOfSubstitutePrice.value,
         aRepresentativeIssueToCalculateBasePrice |-> aRepresentativeIssueToCalculateBasePrice.value,
         endKeyword                               |-> endKeyword.value ], endKeyword.rest)

ZeroSpotGoldBatchDataMessage ==
    [ messageSequenceNumber                    |-> [i \in 1 .. 8 |-> 0],
      totalNumberOfInstrumentsOfTheContract    |-> [i \in 1 .. 6 |-> 0],
      businessDate                             |-> [i \in 1 .. 8 |-> 0],
      isinCode                                 |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue              |-> [i \in 1 .. 6 |-> 0],
      abbreviatedIssueCode                     |-> [i \in 1 .. 9 |-> 0],
      issueName                                |-> [i \in 1 .. 80 |-> 0],
      abbreviatedIssueName                     |-> [i \in 1 .. 40 |-> 0],
      englishIssueName                         |-> [i \in 1 .. 80 |-> 0],
      abbreviatedIssueNameInEn                 |-> [i \in 1 .. 40 |-> 0],
      marketOperationProductId                 |-> [i \in 1 .. 3 |-> 0],
      securityGroupId                          |-> [i \in 1 .. 2 |-> 0],
      listingDate                              |-> [i \in 1 .. 8 |-> 0],
      delistingDate                            |-> [i \in 1 .. 8 |-> 0],
      marketId                                 |-> [i \in 1 .. 3 |-> 0],
      upperLimitPrice                          |-> [i \in 1 .. 11 |-> 0],
      lowerLimitPrice                          |-> [i \in 1 .. 11 |-> 0],
      basePrice                                |-> [i \in 1 .. 11 |-> 0],
      randomEndTriggerCode                     |-> [i \in 1 .. 1 |-> 0],
      tradingHalt                              |-> [i \in 1 .. 1 |-> 0],
      unitOfVolumeInMainBoard                  |-> [i \in 1 .. 11 |-> 0],
      yesterdaysClosingPrice                   |-> [i \in 1 .. 11 |-> 0],
      yesterdaysClosingPriceTypeCode           |-> [i \in 1 .. 1 |-> 0],
      substitutePriceOfSecurities              |-> [i \in 1 .. 11 |-> 0],
      appraisalRatioOfSubstitutePrice          |-> [i \in 1 .. 13 |-> 0],
      aRepresentativeIssueToCalculateBasePrice |-> [i \in 1 .. 12 |-> 0],
      endKeyword                               |-> [i \in 1 .. 1 |-> 0] ]

(* Spot Gold Batch Data Message at zero, then each field in turn at the values it is checked at *)
CheckedSpotGoldBatchDataMessage ==
    { ZeroSpotGoldBatchDataMessage }
        \cup { [ZeroSpotGoldBatchDataMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSpotGoldBatchDataMessage EXCEPT !.totalNumberOfInstrumentsOfTheContract = one] : one \in Sample(6) }
        \cup { [ZeroSpotGoldBatchDataMessage EXCEPT !.businessDate = one] : one \in Sample(8) }
        \cup { [ZeroSpotGoldBatchDataMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldBatchDataMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroSpotGoldBatchDataMessage EXCEPT !.abbreviatedIssueCode = one] : one \in Sample(9) }
        \cup { [ZeroSpotGoldBatchDataMessage EXCEPT !.issueName = one] : one \in Sample(80) }
        \cup { [ZeroSpotGoldBatchDataMessage EXCEPT !.abbreviatedIssueName = one] : one \in Sample(40) }
        \cup { [ZeroSpotGoldBatchDataMessage EXCEPT !.englishIssueName = one] : one \in Sample(80) }
        \cup { [ZeroSpotGoldBatchDataMessage EXCEPT !.abbreviatedIssueNameInEn = one] : one \in Sample(40) }
        \cup { [ZeroSpotGoldBatchDataMessage EXCEPT !.marketOperationProductId = one] : one \in Sample(3) }
        \cup { [ZeroSpotGoldBatchDataMessage EXCEPT !.securityGroupId = one] : one \in Sample(2) }
        \cup { [ZeroSpotGoldBatchDataMessage EXCEPT !.listingDate = one] : one \in Sample(8) }
        \cup { [ZeroSpotGoldBatchDataMessage EXCEPT !.delistingDate = one] : one \in Sample(8) }
        \cup { [ZeroSpotGoldBatchDataMessage EXCEPT !.marketId = one] : one \in Sample(3) }
        \cup { [ZeroSpotGoldBatchDataMessage EXCEPT !.upperLimitPrice = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldBatchDataMessage EXCEPT !.lowerLimitPrice = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldBatchDataMessage EXCEPT !.basePrice = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldBatchDataMessage EXCEPT !.randomEndTriggerCode = one] : one \in Sample(1) }
        \cup { [ZeroSpotGoldBatchDataMessage EXCEPT !.tradingHalt = one] : one \in Sample(1) }
        \cup { [ZeroSpotGoldBatchDataMessage EXCEPT !.unitOfVolumeInMainBoard = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldBatchDataMessage EXCEPT !.yesterdaysClosingPrice = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldBatchDataMessage EXCEPT !.yesterdaysClosingPriceTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroSpotGoldBatchDataMessage EXCEPT !.substitutePriceOfSecurities = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldBatchDataMessage EXCEPT !.appraisalRatioOfSubstitutePrice = one] : one \in Sample(13) }
        \cup { [ZeroSpotGoldBatchDataMessage EXCEPT !.aRepresentativeIssueToCalculateBasePrice = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldBatchDataMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Emissions Batch Data Message: 409 bytes                                 *)
(***************************************************************************)

EmissionsBatchDataMessage ==
    [ messageSequenceNumber                                  : Sample(8),
      totalNumberOfInstrumentsOfTheContract                  : Sample(6),
      businessDate                                           : Sample(8),
      isinCode                                               : Sample(12),
      aDesignatedNumberForAnIssue                            : Sample(6),
      abbreviatedIssueCode                                   : Sample(9),
      issueName                                              : Sample(80),
      abbreviatedIssueName                                   : Sample(40),
      englishIssueName                                       : Sample(80),
      abbreviatedIssueNameInEn                               : Sample(40),
      marketOperationProductId                               : Sample(3),
      securityGroupId                                        : Sample(2),
      listingDate                                            : Sample(8),
      delistingDate                                          : Sample(8),
      marketId                                               : Sample(3),
      upperLimitPrice                                        : Sample(11),
      lowerLimitPrice                                        : Sample(11),
      basePrice                                              : Sample(11),
      randomEndTriggerCode                                   : Sample(1),
      tradingHalt                                            : Sample(1),
      unitOfVolumeInMainBoard                                : Sample(11),
      yesterdaysClosingPrice                                 : Sample(11),
      yesterdaysClosingPriceTypeCode                         : Sample(1),
      substitutePriceOfSecurities                            : Sample(11),
      appraisalRatioOfSubstitutePrice                        : Sample(13),
      aRepresentativeIssueToCalculateBasePrice               : Sample(12),
      anIssueOfWhichBasePriceIsSettledWithATodaysSinglePrice : Sample(1),
      endKeyword                                             : Sample(1) ]

EncodeEmissionsBatchDataMessage(message) ==
    message.messageSequenceNumber
        \o message.totalNumberOfInstrumentsOfTheContract
        \o message.businessDate
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.abbreviatedIssueCode
        \o message.issueName
        \o message.abbreviatedIssueName
        \o message.englishIssueName
        \o message.abbreviatedIssueNameInEn
        \o message.marketOperationProductId
        \o message.securityGroupId
        \o message.listingDate
        \o message.delistingDate
        \o message.marketId
        \o message.upperLimitPrice
        \o message.lowerLimitPrice
        \o message.basePrice
        \o message.randomEndTriggerCode
        \o message.tradingHalt
        \o message.unitOfVolumeInMainBoard
        \o message.yesterdaysClosingPrice
        \o message.yesterdaysClosingPriceTypeCode
        \o message.substitutePriceOfSecurities
        \o message.appraisalRatioOfSubstitutePrice
        \o message.aRepresentativeIssueToCalculateBasePrice
        \o message.anIssueOfWhichBasePriceIsSettledWithATodaysSinglePrice
        \o message.endKeyword

DecodeEmissionsBatchDataMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET totalNumberOfInstrumentsOfTheContract == ReadBytes(messageSequenceNumber.rest, 6) IN IF ~totalNumberOfInstrumentsOfTheContract.ok THEN Fail ELSE
    LET businessDate == ReadBytes(totalNumberOfInstrumentsOfTheContract.rest, 8) IN IF ~businessDate.ok THEN Fail ELSE
    LET isinCode == ReadBytes(businessDate.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET abbreviatedIssueCode == ReadBytes(aDesignatedNumberForAnIssue.rest, 9) IN IF ~abbreviatedIssueCode.ok THEN Fail ELSE
    LET issueName == ReadBytes(abbreviatedIssueCode.rest, 80) IN IF ~issueName.ok THEN Fail ELSE
    LET abbreviatedIssueName == ReadBytes(issueName.rest, 40) IN IF ~abbreviatedIssueName.ok THEN Fail ELSE
    LET englishIssueName == ReadBytes(abbreviatedIssueName.rest, 80) IN IF ~englishIssueName.ok THEN Fail ELSE
    LET abbreviatedIssueNameInEn == ReadBytes(englishIssueName.rest, 40) IN IF ~abbreviatedIssueNameInEn.ok THEN Fail ELSE
    LET marketOperationProductId == ReadBytes(abbreviatedIssueNameInEn.rest, 3) IN IF ~marketOperationProductId.ok THEN Fail ELSE
    LET securityGroupId == ReadBytes(marketOperationProductId.rest, 2) IN IF ~securityGroupId.ok THEN Fail ELSE
    LET listingDate == ReadBytes(securityGroupId.rest, 8) IN IF ~listingDate.ok THEN Fail ELSE
    LET delistingDate == ReadBytes(listingDate.rest, 8) IN IF ~delistingDate.ok THEN Fail ELSE
    LET marketId == ReadBytes(delistingDate.rest, 3) IN IF ~marketId.ok THEN Fail ELSE
    LET upperLimitPrice == ReadBytes(marketId.rest, 11) IN IF ~upperLimitPrice.ok THEN Fail ELSE
    LET lowerLimitPrice == ReadBytes(upperLimitPrice.rest, 11) IN IF ~lowerLimitPrice.ok THEN Fail ELSE
    LET basePrice == ReadBytes(lowerLimitPrice.rest, 11) IN IF ~basePrice.ok THEN Fail ELSE
    LET randomEndTriggerCode == ReadBytes(basePrice.rest, 1) IN IF ~randomEndTriggerCode.ok THEN Fail ELSE
    LET tradingHalt == ReadBytes(randomEndTriggerCode.rest, 1) IN IF ~tradingHalt.ok THEN Fail ELSE
    LET unitOfVolumeInMainBoard == ReadBytes(tradingHalt.rest, 11) IN IF ~unitOfVolumeInMainBoard.ok THEN Fail ELSE
    LET yesterdaysClosingPrice == ReadBytes(unitOfVolumeInMainBoard.rest, 11) IN IF ~yesterdaysClosingPrice.ok THEN Fail ELSE
    LET yesterdaysClosingPriceTypeCode == ReadBytes(yesterdaysClosingPrice.rest, 1) IN IF ~yesterdaysClosingPriceTypeCode.ok THEN Fail ELSE
    LET substitutePriceOfSecurities == ReadBytes(yesterdaysClosingPriceTypeCode.rest, 11) IN IF ~substitutePriceOfSecurities.ok THEN Fail ELSE
    LET appraisalRatioOfSubstitutePrice == ReadBytes(substitutePriceOfSecurities.rest, 13) IN IF ~appraisalRatioOfSubstitutePrice.ok THEN Fail ELSE
    LET aRepresentativeIssueToCalculateBasePrice == ReadBytes(appraisalRatioOfSubstitutePrice.rest, 12) IN IF ~aRepresentativeIssueToCalculateBasePrice.ok THEN Fail ELSE
    LET anIssueOfWhichBasePriceIsSettledWithATodaysSinglePrice == ReadBytes(aRepresentativeIssueToCalculateBasePrice.rest, 1) IN IF ~anIssueOfWhichBasePriceIsSettledWithATodaysSinglePrice.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(anIssueOfWhichBasePriceIsSettledWithATodaysSinglePrice.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber                                  |-> messageSequenceNumber.value,
         totalNumberOfInstrumentsOfTheContract                  |-> totalNumberOfInstrumentsOfTheContract.value,
         businessDate                                           |-> businessDate.value,
         isinCode                                               |-> isinCode.value,
         aDesignatedNumberForAnIssue                            |-> aDesignatedNumberForAnIssue.value,
         abbreviatedIssueCode                                   |-> abbreviatedIssueCode.value,
         issueName                                              |-> issueName.value,
         abbreviatedIssueName                                   |-> abbreviatedIssueName.value,
         englishIssueName                                       |-> englishIssueName.value,
         abbreviatedIssueNameInEn                               |-> abbreviatedIssueNameInEn.value,
         marketOperationProductId                               |-> marketOperationProductId.value,
         securityGroupId                                        |-> securityGroupId.value,
         listingDate                                            |-> listingDate.value,
         delistingDate                                          |-> delistingDate.value,
         marketId                                               |-> marketId.value,
         upperLimitPrice                                        |-> upperLimitPrice.value,
         lowerLimitPrice                                        |-> lowerLimitPrice.value,
         basePrice                                              |-> basePrice.value,
         randomEndTriggerCode                                   |-> randomEndTriggerCode.value,
         tradingHalt                                            |-> tradingHalt.value,
         unitOfVolumeInMainBoard                                |-> unitOfVolumeInMainBoard.value,
         yesterdaysClosingPrice                                 |-> yesterdaysClosingPrice.value,
         yesterdaysClosingPriceTypeCode                         |-> yesterdaysClosingPriceTypeCode.value,
         substitutePriceOfSecurities                            |-> substitutePriceOfSecurities.value,
         appraisalRatioOfSubstitutePrice                        |-> appraisalRatioOfSubstitutePrice.value,
         aRepresentativeIssueToCalculateBasePrice               |-> aRepresentativeIssueToCalculateBasePrice.value,
         anIssueOfWhichBasePriceIsSettledWithATodaysSinglePrice |-> anIssueOfWhichBasePriceIsSettledWithATodaysSinglePrice.value,
         endKeyword                                             |-> endKeyword.value ], endKeyword.rest)

ZeroEmissionsBatchDataMessage ==
    [ messageSequenceNumber                                  |-> [i \in 1 .. 8 |-> 0],
      totalNumberOfInstrumentsOfTheContract                  |-> [i \in 1 .. 6 |-> 0],
      businessDate                                           |-> [i \in 1 .. 8 |-> 0],
      isinCode                                               |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue                            |-> [i \in 1 .. 6 |-> 0],
      abbreviatedIssueCode                                   |-> [i \in 1 .. 9 |-> 0],
      issueName                                              |-> [i \in 1 .. 80 |-> 0],
      abbreviatedIssueName                                   |-> [i \in 1 .. 40 |-> 0],
      englishIssueName                                       |-> [i \in 1 .. 80 |-> 0],
      abbreviatedIssueNameInEn                               |-> [i \in 1 .. 40 |-> 0],
      marketOperationProductId                               |-> [i \in 1 .. 3 |-> 0],
      securityGroupId                                        |-> [i \in 1 .. 2 |-> 0],
      listingDate                                            |-> [i \in 1 .. 8 |-> 0],
      delistingDate                                          |-> [i \in 1 .. 8 |-> 0],
      marketId                                               |-> [i \in 1 .. 3 |-> 0],
      upperLimitPrice                                        |-> [i \in 1 .. 11 |-> 0],
      lowerLimitPrice                                        |-> [i \in 1 .. 11 |-> 0],
      basePrice                                              |-> [i \in 1 .. 11 |-> 0],
      randomEndTriggerCode                                   |-> [i \in 1 .. 1 |-> 0],
      tradingHalt                                            |-> [i \in 1 .. 1 |-> 0],
      unitOfVolumeInMainBoard                                |-> [i \in 1 .. 11 |-> 0],
      yesterdaysClosingPrice                                 |-> [i \in 1 .. 11 |-> 0],
      yesterdaysClosingPriceTypeCode                         |-> [i \in 1 .. 1 |-> 0],
      substitutePriceOfSecurities                            |-> [i \in 1 .. 11 |-> 0],
      appraisalRatioOfSubstitutePrice                        |-> [i \in 1 .. 13 |-> 0],
      aRepresentativeIssueToCalculateBasePrice               |-> [i \in 1 .. 12 |-> 0],
      anIssueOfWhichBasePriceIsSettledWithATodaysSinglePrice |-> [i \in 1 .. 1 |-> 0],
      endKeyword                                             |-> [i \in 1 .. 1 |-> 0] ]

(* Emissions Batch Data Message at zero, then each field in turn at the values it is checked at *)
CheckedEmissionsBatchDataMessage ==
    { ZeroEmissionsBatchDataMessage }
        \cup { [ZeroEmissionsBatchDataMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroEmissionsBatchDataMessage EXCEPT !.totalNumberOfInstrumentsOfTheContract = one] : one \in Sample(6) }
        \cup { [ZeroEmissionsBatchDataMessage EXCEPT !.businessDate = one] : one \in Sample(8) }
        \cup { [ZeroEmissionsBatchDataMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsBatchDataMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroEmissionsBatchDataMessage EXCEPT !.abbreviatedIssueCode = one] : one \in Sample(9) }
        \cup { [ZeroEmissionsBatchDataMessage EXCEPT !.issueName = one] : one \in Sample(80) }
        \cup { [ZeroEmissionsBatchDataMessage EXCEPT !.abbreviatedIssueName = one] : one \in Sample(40) }
        \cup { [ZeroEmissionsBatchDataMessage EXCEPT !.englishIssueName = one] : one \in Sample(80) }
        \cup { [ZeroEmissionsBatchDataMessage EXCEPT !.abbreviatedIssueNameInEn = one] : one \in Sample(40) }
        \cup { [ZeroEmissionsBatchDataMessage EXCEPT !.marketOperationProductId = one] : one \in Sample(3) }
        \cup { [ZeroEmissionsBatchDataMessage EXCEPT !.securityGroupId = one] : one \in Sample(2) }
        \cup { [ZeroEmissionsBatchDataMessage EXCEPT !.listingDate = one] : one \in Sample(8) }
        \cup { [ZeroEmissionsBatchDataMessage EXCEPT !.delistingDate = one] : one \in Sample(8) }
        \cup { [ZeroEmissionsBatchDataMessage EXCEPT !.marketId = one] : one \in Sample(3) }
        \cup { [ZeroEmissionsBatchDataMessage EXCEPT !.upperLimitPrice = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsBatchDataMessage EXCEPT !.lowerLimitPrice = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsBatchDataMessage EXCEPT !.basePrice = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsBatchDataMessage EXCEPT !.randomEndTriggerCode = one] : one \in Sample(1) }
        \cup { [ZeroEmissionsBatchDataMessage EXCEPT !.tradingHalt = one] : one \in Sample(1) }
        \cup { [ZeroEmissionsBatchDataMessage EXCEPT !.unitOfVolumeInMainBoard = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsBatchDataMessage EXCEPT !.yesterdaysClosingPrice = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsBatchDataMessage EXCEPT !.yesterdaysClosingPriceTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroEmissionsBatchDataMessage EXCEPT !.substitutePriceOfSecurities = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsBatchDataMessage EXCEPT !.appraisalRatioOfSubstitutePrice = one] : one \in Sample(13) }
        \cup { [ZeroEmissionsBatchDataMessage EXCEPT !.aRepresentativeIssueToCalculateBasePrice = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsBatchDataMessage EXCEPT !.anIssueOfWhichBasePriceIsSettledWithATodaysSinglePrice = one] : one \in Sample(1) }
        \cup { [ZeroEmissionsBatchDataMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* External Gold Spot Closing Price Message: 120 bytes                     *)
(***************************************************************************)

ExternalGoldSpotClosingPriceMessage ==
    [ dataType                    : Sample(1),
      jobCodeSymbol               : Sample(16),
      tradingDate                 : Sample(8),
      tradingTime                 : Sample(6),
      openingPriceShort           : Sample(9),
      highPrice                   : Sample(9),
      lowPrice                    : Sample(9),
      closingPriceShort           : Sample(9),
      changeFromPreviousDaySign   : Sample(1),
      changeFromPreviousDay       : Sample(9),
      fluctuatingRate             : Sample(9),
      bidQuote                    : Sample(9),
      askQuote                    : Sample(9),
      currencyCodeLong            : Sample(6),
      conversionBasicExchangeRate : Sample(9),
      endKeyword                  : Sample(1) ]

EncodeExternalGoldSpotClosingPriceMessage(message) ==
    message.dataType
        \o message.jobCodeSymbol
        \o message.tradingDate
        \o message.tradingTime
        \o message.openingPriceShort
        \o message.highPrice
        \o message.lowPrice
        \o message.closingPriceShort
        \o message.changeFromPreviousDaySign
        \o message.changeFromPreviousDay
        \o message.fluctuatingRate
        \o message.bidQuote
        \o message.askQuote
        \o message.currencyCodeLong
        \o message.conversionBasicExchangeRate
        \o message.endKeyword

DecodeExternalGoldSpotClosingPriceMessage(bytes) ==
    LET dataType == ReadBytes(bytes, 1) IN IF ~dataType.ok THEN Fail ELSE
    LET jobCodeSymbol == ReadBytes(dataType.rest, 16) IN IF ~jobCodeSymbol.ok THEN Fail ELSE
    LET tradingDate == ReadBytes(jobCodeSymbol.rest, 8) IN IF ~tradingDate.ok THEN Fail ELSE
    LET tradingTime == ReadBytes(tradingDate.rest, 6) IN IF ~tradingTime.ok THEN Fail ELSE
    LET openingPriceShort == ReadBytes(tradingTime.rest, 9) IN IF ~openingPriceShort.ok THEN Fail ELSE
    LET highPrice == ReadBytes(openingPriceShort.rest, 9) IN IF ~highPrice.ok THEN Fail ELSE
    LET lowPrice == ReadBytes(highPrice.rest, 9) IN IF ~lowPrice.ok THEN Fail ELSE
    LET closingPriceShort == ReadBytes(lowPrice.rest, 9) IN IF ~closingPriceShort.ok THEN Fail ELSE
    LET changeFromPreviousDaySign == ReadBytes(closingPriceShort.rest, 1) IN IF ~changeFromPreviousDaySign.ok THEN Fail ELSE
    LET changeFromPreviousDay == ReadBytes(changeFromPreviousDaySign.rest, 9) IN IF ~changeFromPreviousDay.ok THEN Fail ELSE
    LET fluctuatingRate == ReadBytes(changeFromPreviousDay.rest, 9) IN IF ~fluctuatingRate.ok THEN Fail ELSE
    LET bidQuote == ReadBytes(fluctuatingRate.rest, 9) IN IF ~bidQuote.ok THEN Fail ELSE
    LET askQuote == ReadBytes(bidQuote.rest, 9) IN IF ~askQuote.ok THEN Fail ELSE
    LET currencyCodeLong == ReadBytes(askQuote.rest, 6) IN IF ~currencyCodeLong.ok THEN Fail ELSE
    LET conversionBasicExchangeRate == ReadBytes(currencyCodeLong.rest, 9) IN IF ~conversionBasicExchangeRate.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(conversionBasicExchangeRate.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ dataType                    |-> dataType.value,
         jobCodeSymbol               |-> jobCodeSymbol.value,
         tradingDate                 |-> tradingDate.value,
         tradingTime                 |-> tradingTime.value,
         openingPriceShort           |-> openingPriceShort.value,
         highPrice                   |-> highPrice.value,
         lowPrice                    |-> lowPrice.value,
         closingPriceShort           |-> closingPriceShort.value,
         changeFromPreviousDaySign   |-> changeFromPreviousDaySign.value,
         changeFromPreviousDay       |-> changeFromPreviousDay.value,
         fluctuatingRate             |-> fluctuatingRate.value,
         bidQuote                    |-> bidQuote.value,
         askQuote                    |-> askQuote.value,
         currencyCodeLong            |-> currencyCodeLong.value,
         conversionBasicExchangeRate |-> conversionBasicExchangeRate.value,
         endKeyword                  |-> endKeyword.value ], endKeyword.rest)

ZeroExternalGoldSpotClosingPriceMessage ==
    [ dataType                    |-> [i \in 1 .. 1 |-> 0],
      jobCodeSymbol               |-> [i \in 1 .. 16 |-> 0],
      tradingDate                 |-> [i \in 1 .. 8 |-> 0],
      tradingTime                 |-> [i \in 1 .. 6 |-> 0],
      openingPriceShort           |-> [i \in 1 .. 9 |-> 0],
      highPrice                   |-> [i \in 1 .. 9 |-> 0],
      lowPrice                    |-> [i \in 1 .. 9 |-> 0],
      closingPriceShort           |-> [i \in 1 .. 9 |-> 0],
      changeFromPreviousDaySign   |-> [i \in 1 .. 1 |-> 0],
      changeFromPreviousDay       |-> [i \in 1 .. 9 |-> 0],
      fluctuatingRate             |-> [i \in 1 .. 9 |-> 0],
      bidQuote                    |-> [i \in 1 .. 9 |-> 0],
      askQuote                    |-> [i \in 1 .. 9 |-> 0],
      currencyCodeLong            |-> [i \in 1 .. 6 |-> 0],
      conversionBasicExchangeRate |-> [i \in 1 .. 9 |-> 0],
      endKeyword                  |-> [i \in 1 .. 1 |-> 0] ]

(* External Gold Spot Closing Price Message at zero, then each field in turn at the values it is checked at *)
CheckedExternalGoldSpotClosingPriceMessage ==
    { ZeroExternalGoldSpotClosingPriceMessage }
        \cup { [ZeroExternalGoldSpotClosingPriceMessage EXCEPT !.dataType = one] : one \in Sample(1) }
        \cup { [ZeroExternalGoldSpotClosingPriceMessage EXCEPT !.jobCodeSymbol = one] : one \in Sample(16) }
        \cup { [ZeroExternalGoldSpotClosingPriceMessage EXCEPT !.tradingDate = one] : one \in Sample(8) }
        \cup { [ZeroExternalGoldSpotClosingPriceMessage EXCEPT !.tradingTime = one] : one \in Sample(6) }
        \cup { [ZeroExternalGoldSpotClosingPriceMessage EXCEPT !.openingPriceShort = one] : one \in Sample(9) }
        \cup { [ZeroExternalGoldSpotClosingPriceMessage EXCEPT !.highPrice = one] : one \in Sample(9) }
        \cup { [ZeroExternalGoldSpotClosingPriceMessage EXCEPT !.lowPrice = one] : one \in Sample(9) }
        \cup { [ZeroExternalGoldSpotClosingPriceMessage EXCEPT !.closingPriceShort = one] : one \in Sample(9) }
        \cup { [ZeroExternalGoldSpotClosingPriceMessage EXCEPT !.changeFromPreviousDaySign = one] : one \in Sample(1) }
        \cup { [ZeroExternalGoldSpotClosingPriceMessage EXCEPT !.changeFromPreviousDay = one] : one \in Sample(9) }
        \cup { [ZeroExternalGoldSpotClosingPriceMessage EXCEPT !.fluctuatingRate = one] : one \in Sample(9) }
        \cup { [ZeroExternalGoldSpotClosingPriceMessage EXCEPT !.bidQuote = one] : one \in Sample(9) }
        \cup { [ZeroExternalGoldSpotClosingPriceMessage EXCEPT !.askQuote = one] : one \in Sample(9) }
        \cup { [ZeroExternalGoldSpotClosingPriceMessage EXCEPT !.currencyCodeLong = one] : one \in Sample(6) }
        \cup { [ZeroExternalGoldSpotClosingPriceMessage EXCEPT !.conversionBasicExchangeRate = one] : one \in Sample(9) }
        \cup { [ZeroExternalGoldSpotClosingPriceMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Spot Gold Market Operation Ts Message: 63 bytes                         *)
(***************************************************************************)

SpotGoldMarketOperationTsMessage ==
    [ messageSequenceNumber         : Sample(8),
      boardId                       : Sample(2),
      sessionId                     : Sample(2),
      isinCode                      : Sample(12),
      aDesignatedNumberForAnIssue   : Sample(6),
      processingTimeOfTradingSystem : Sample(12),
      boardEventId                  : Sample(3),
      startTimeOfABoardEvent        : Sample(9),
      boardEventGroupCode           : Sample(5),
      tradingHaltReasonCode         : Sample(3),
      endKeyword                    : Sample(1) ]

EncodeSpotGoldMarketOperationTsMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.sessionId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.processingTimeOfTradingSystem
        \o message.boardEventId
        \o message.startTimeOfABoardEvent
        \o message.boardEventGroupCode
        \o message.tradingHaltReasonCode
        \o message.endKeyword

DecodeSpotGoldMarketOperationTsMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(boardId.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(sessionId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET processingTimeOfTradingSystem == ReadBytes(aDesignatedNumberForAnIssue.rest, 12) IN IF ~processingTimeOfTradingSystem.ok THEN Fail ELSE
    LET boardEventId == ReadBytes(processingTimeOfTradingSystem.rest, 3) IN IF ~boardEventId.ok THEN Fail ELSE
    LET startTimeOfABoardEvent == ReadBytes(boardEventId.rest, 9) IN IF ~startTimeOfABoardEvent.ok THEN Fail ELSE
    LET boardEventGroupCode == ReadBytes(startTimeOfABoardEvent.rest, 5) IN IF ~boardEventGroupCode.ok THEN Fail ELSE
    LET tradingHaltReasonCode == ReadBytes(boardEventGroupCode.rest, 3) IN IF ~tradingHaltReasonCode.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(tradingHaltReasonCode.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber         |-> messageSequenceNumber.value,
         boardId                       |-> boardId.value,
         sessionId                     |-> sessionId.value,
         isinCode                      |-> isinCode.value,
         aDesignatedNumberForAnIssue   |-> aDesignatedNumberForAnIssue.value,
         processingTimeOfTradingSystem |-> processingTimeOfTradingSystem.value,
         boardEventId                  |-> boardEventId.value,
         startTimeOfABoardEvent        |-> startTimeOfABoardEvent.value,
         boardEventGroupCode           |-> boardEventGroupCode.value,
         tradingHaltReasonCode         |-> tradingHaltReasonCode.value,
         endKeyword                    |-> endKeyword.value ], endKeyword.rest)

ZeroSpotGoldMarketOperationTsMessage ==
    [ messageSequenceNumber         |-> [i \in 1 .. 8 |-> 0],
      boardId                       |-> [i \in 1 .. 2 |-> 0],
      sessionId                     |-> [i \in 1 .. 2 |-> 0],
      isinCode                      |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue   |-> [i \in 1 .. 6 |-> 0],
      processingTimeOfTradingSystem |-> [i \in 1 .. 12 |-> 0],
      boardEventId                  |-> [i \in 1 .. 3 |-> 0],
      startTimeOfABoardEvent        |-> [i \in 1 .. 9 |-> 0],
      boardEventGroupCode           |-> [i \in 1 .. 5 |-> 0],
      tradingHaltReasonCode         |-> [i \in 1 .. 3 |-> 0],
      endKeyword                    |-> [i \in 1 .. 1 |-> 0] ]

(* Spot Gold Market Operation Ts Message at zero, then each field in turn at the values it is checked at *)
CheckedSpotGoldMarketOperationTsMessage ==
    { ZeroSpotGoldMarketOperationTsMessage }
        \cup { [ZeroSpotGoldMarketOperationTsMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSpotGoldMarketOperationTsMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroSpotGoldMarketOperationTsMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroSpotGoldMarketOperationTsMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationTsMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroSpotGoldMarketOperationTsMessage EXCEPT !.processingTimeOfTradingSystem = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationTsMessage EXCEPT !.boardEventId = one] : one \in Sample(3) }
        \cup { [ZeroSpotGoldMarketOperationTsMessage EXCEPT !.startTimeOfABoardEvent = one] : one \in Sample(9) }
        \cup { [ZeroSpotGoldMarketOperationTsMessage EXCEPT !.boardEventGroupCode = one] : one \in Sample(5) }
        \cup { [ZeroSpotGoldMarketOperationTsMessage EXCEPT !.tradingHaltReasonCode = one] : one \in Sample(3) }
        \cup { [ZeroSpotGoldMarketOperationTsMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Spot Gold Issue Closing Message: 107 bytes                              *)
(***************************************************************************)

SpotGoldIssueClosingMessage ==
    [ messageSequenceNumber                 : Sample(8),
      boardId                               : Sample(2),
      isinCode                              : Sample(12),
      aDesignatedNumberForAnIssue           : Sample(6),
      closingPriceLong                      : Sample(11),
      closingPriceTypeCode                  : Sample(1),
      filler11                              : Sample(11),
      secondFiller11                        : Sample(11),
      closingPriceWeightedStockPriceAverage : Sample(11),
      closingPriceBasePriceOfBuyIn          : Sample(11),
      closingPriceUpperLimitOfBuyIn         : Sample(11),
      closingPriceLowerLimitOfBuyIn         : Sample(11),
      endKeyword                            : Sample(1) ]

EncodeSpotGoldIssueClosingMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.closingPriceLong
        \o message.closingPriceTypeCode
        \o message.filler11
        \o message.secondFiller11
        \o message.closingPriceWeightedStockPriceAverage
        \o message.closingPriceBasePriceOfBuyIn
        \o message.closingPriceUpperLimitOfBuyIn
        \o message.closingPriceLowerLimitOfBuyIn
        \o message.endKeyword

DecodeSpotGoldIssueClosingMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(boardId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET closingPriceLong == ReadBytes(aDesignatedNumberForAnIssue.rest, 11) IN IF ~closingPriceLong.ok THEN Fail ELSE
    LET closingPriceTypeCode == ReadBytes(closingPriceLong.rest, 1) IN IF ~closingPriceTypeCode.ok THEN Fail ELSE
    LET filler11 == ReadBytes(closingPriceTypeCode.rest, 11) IN IF ~filler11.ok THEN Fail ELSE
    LET secondFiller11 == ReadBytes(filler11.rest, 11) IN IF ~secondFiller11.ok THEN Fail ELSE
    LET closingPriceWeightedStockPriceAverage == ReadBytes(secondFiller11.rest, 11) IN IF ~closingPriceWeightedStockPriceAverage.ok THEN Fail ELSE
    LET closingPriceBasePriceOfBuyIn == ReadBytes(closingPriceWeightedStockPriceAverage.rest, 11) IN IF ~closingPriceBasePriceOfBuyIn.ok THEN Fail ELSE
    LET closingPriceUpperLimitOfBuyIn == ReadBytes(closingPriceBasePriceOfBuyIn.rest, 11) IN IF ~closingPriceUpperLimitOfBuyIn.ok THEN Fail ELSE
    LET closingPriceLowerLimitOfBuyIn == ReadBytes(closingPriceUpperLimitOfBuyIn.rest, 11) IN IF ~closingPriceLowerLimitOfBuyIn.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(closingPriceLowerLimitOfBuyIn.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber                 |-> messageSequenceNumber.value,
         boardId                               |-> boardId.value,
         isinCode                              |-> isinCode.value,
         aDesignatedNumberForAnIssue           |-> aDesignatedNumberForAnIssue.value,
         closingPriceLong                      |-> closingPriceLong.value,
         closingPriceTypeCode                  |-> closingPriceTypeCode.value,
         filler11                              |-> filler11.value,
         secondFiller11                        |-> secondFiller11.value,
         closingPriceWeightedStockPriceAverage |-> closingPriceWeightedStockPriceAverage.value,
         closingPriceBasePriceOfBuyIn          |-> closingPriceBasePriceOfBuyIn.value,
         closingPriceUpperLimitOfBuyIn         |-> closingPriceUpperLimitOfBuyIn.value,
         closingPriceLowerLimitOfBuyIn         |-> closingPriceLowerLimitOfBuyIn.value,
         endKeyword                            |-> endKeyword.value ], endKeyword.rest)

ZeroSpotGoldIssueClosingMessage ==
    [ messageSequenceNumber                 |-> [i \in 1 .. 8 |-> 0],
      boardId                               |-> [i \in 1 .. 2 |-> 0],
      isinCode                              |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue           |-> [i \in 1 .. 6 |-> 0],
      closingPriceLong                      |-> [i \in 1 .. 11 |-> 0],
      closingPriceTypeCode                  |-> [i \in 1 .. 1 |-> 0],
      filler11                              |-> [i \in 1 .. 11 |-> 0],
      secondFiller11                        |-> [i \in 1 .. 11 |-> 0],
      closingPriceWeightedStockPriceAverage |-> [i \in 1 .. 11 |-> 0],
      closingPriceBasePriceOfBuyIn          |-> [i \in 1 .. 11 |-> 0],
      closingPriceUpperLimitOfBuyIn         |-> [i \in 1 .. 11 |-> 0],
      closingPriceLowerLimitOfBuyIn         |-> [i \in 1 .. 11 |-> 0],
      endKeyword                            |-> [i \in 1 .. 1 |-> 0] ]

(* Spot Gold Issue Closing Message at zero, then each field in turn at the values it is checked at *)
CheckedSpotGoldIssueClosingMessage ==
    { ZeroSpotGoldIssueClosingMessage }
        \cup { [ZeroSpotGoldIssueClosingMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSpotGoldIssueClosingMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroSpotGoldIssueClosingMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldIssueClosingMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroSpotGoldIssueClosingMessage EXCEPT !.closingPriceLong = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldIssueClosingMessage EXCEPT !.closingPriceTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroSpotGoldIssueClosingMessage EXCEPT !.filler11 = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldIssueClosingMessage EXCEPT !.secondFiller11 = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldIssueClosingMessage EXCEPT !.closingPriceWeightedStockPriceAverage = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldIssueClosingMessage EXCEPT !.closingPriceBasePriceOfBuyIn = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldIssueClosingMessage EXCEPT !.closingPriceUpperLimitOfBuyIn = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldIssueClosingMessage EXCEPT !.closingPriceLowerLimitOfBuyIn = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldIssueClosingMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Spot Gold Market Operation Schedule Message: 78 bytes                   *)
(***************************************************************************)

SpotGoldMarketOperationScheduleMessage ==
    [ marketOperationProductId                     : Sample(3),
      boardId                                      : Sample(2),
      boardEventId                                 : Sample(3),
      startTimeOfABoardEvent                       : Sample(9),
      boardEventGroupCode                          : Sample(5),
      sessionStartEndCode                          : Sample(2),
      sessionId                                    : Sample(2),
      isinCode                                     : Sample(12),
      isinCodeOfACommonStock                       : Sample(12),
      productId                                    : Sample(11),
      tradingHaltReasonCode                        : Sample(3),
      tradingHaltTypeCode                          : Sample(1),
      stepApplied                                  : Sample(2),
      priceLimitRangeExpansionForBaseIssueTypeCode : Sample(1),
      expectedTimeOfExpandingPriceLimitRange       : Sample(9),
      endKeyword                                   : Sample(1) ]

EncodeSpotGoldMarketOperationScheduleMessage(message) ==
    message.marketOperationProductId
        \o message.boardId
        \o message.boardEventId
        \o message.startTimeOfABoardEvent
        \o message.boardEventGroupCode
        \o message.sessionStartEndCode
        \o message.sessionId
        \o message.isinCode
        \o message.isinCodeOfACommonStock
        \o message.productId
        \o message.tradingHaltReasonCode
        \o message.tradingHaltTypeCode
        \o message.stepApplied
        \o message.priceLimitRangeExpansionForBaseIssueTypeCode
        \o message.expectedTimeOfExpandingPriceLimitRange
        \o message.endKeyword

DecodeSpotGoldMarketOperationScheduleMessage(bytes) ==
    LET marketOperationProductId == ReadBytes(bytes, 3) IN IF ~marketOperationProductId.ok THEN Fail ELSE
    LET boardId == ReadBytes(marketOperationProductId.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET boardEventId == ReadBytes(boardId.rest, 3) IN IF ~boardEventId.ok THEN Fail ELSE
    LET startTimeOfABoardEvent == ReadBytes(boardEventId.rest, 9) IN IF ~startTimeOfABoardEvent.ok THEN Fail ELSE
    LET boardEventGroupCode == ReadBytes(startTimeOfABoardEvent.rest, 5) IN IF ~boardEventGroupCode.ok THEN Fail ELSE
    LET sessionStartEndCode == ReadBytes(boardEventGroupCode.rest, 2) IN IF ~sessionStartEndCode.ok THEN Fail ELSE
    LET sessionId == ReadBytes(sessionStartEndCode.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(sessionId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET isinCodeOfACommonStock == ReadBytes(isinCode.rest, 12) IN IF ~isinCodeOfACommonStock.ok THEN Fail ELSE
    LET productId == ReadBytes(isinCodeOfACommonStock.rest, 11) IN IF ~productId.ok THEN Fail ELSE
    LET tradingHaltReasonCode == ReadBytes(productId.rest, 3) IN IF ~tradingHaltReasonCode.ok THEN Fail ELSE
    LET tradingHaltTypeCode == ReadBytes(tradingHaltReasonCode.rest, 1) IN IF ~tradingHaltTypeCode.ok THEN Fail ELSE
    LET stepApplied == ReadBytes(tradingHaltTypeCode.rest, 2) IN IF ~stepApplied.ok THEN Fail ELSE
    LET priceLimitRangeExpansionForBaseIssueTypeCode == ReadBytes(stepApplied.rest, 1) IN IF ~priceLimitRangeExpansionForBaseIssueTypeCode.ok THEN Fail ELSE
    LET expectedTimeOfExpandingPriceLimitRange == ReadBytes(priceLimitRangeExpansionForBaseIssueTypeCode.rest, 9) IN IF ~expectedTimeOfExpandingPriceLimitRange.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(expectedTimeOfExpandingPriceLimitRange.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ marketOperationProductId                     |-> marketOperationProductId.value,
         boardId                                      |-> boardId.value,
         boardEventId                                 |-> boardEventId.value,
         startTimeOfABoardEvent                       |-> startTimeOfABoardEvent.value,
         boardEventGroupCode                          |-> boardEventGroupCode.value,
         sessionStartEndCode                          |-> sessionStartEndCode.value,
         sessionId                                    |-> sessionId.value,
         isinCode                                     |-> isinCode.value,
         isinCodeOfACommonStock                       |-> isinCodeOfACommonStock.value,
         productId                                    |-> productId.value,
         tradingHaltReasonCode                        |-> tradingHaltReasonCode.value,
         tradingHaltTypeCode                          |-> tradingHaltTypeCode.value,
         stepApplied                                  |-> stepApplied.value,
         priceLimitRangeExpansionForBaseIssueTypeCode |-> priceLimitRangeExpansionForBaseIssueTypeCode.value,
         expectedTimeOfExpandingPriceLimitRange       |-> expectedTimeOfExpandingPriceLimitRange.value,
         endKeyword                                   |-> endKeyword.value ], endKeyword.rest)

ZeroSpotGoldMarketOperationScheduleMessage ==
    [ marketOperationProductId                     |-> [i \in 1 .. 3 |-> 0],
      boardId                                      |-> [i \in 1 .. 2 |-> 0],
      boardEventId                                 |-> [i \in 1 .. 3 |-> 0],
      startTimeOfABoardEvent                       |-> [i \in 1 .. 9 |-> 0],
      boardEventGroupCode                          |-> [i \in 1 .. 5 |-> 0],
      sessionStartEndCode                          |-> [i \in 1 .. 2 |-> 0],
      sessionId                                    |-> [i \in 1 .. 2 |-> 0],
      isinCode                                     |-> [i \in 1 .. 12 |-> 0],
      isinCodeOfACommonStock                       |-> [i \in 1 .. 12 |-> 0],
      productId                                    |-> [i \in 1 .. 11 |-> 0],
      tradingHaltReasonCode                        |-> [i \in 1 .. 3 |-> 0],
      tradingHaltTypeCode                          |-> [i \in 1 .. 1 |-> 0],
      stepApplied                                  |-> [i \in 1 .. 2 |-> 0],
      priceLimitRangeExpansionForBaseIssueTypeCode |-> [i \in 1 .. 1 |-> 0],
      expectedTimeOfExpandingPriceLimitRange       |-> [i \in 1 .. 9 |-> 0],
      endKeyword                                   |-> [i \in 1 .. 1 |-> 0] ]

(* Spot Gold Market Operation Schedule Message at zero, then each field in turn at the values it is checked at *)
CheckedSpotGoldMarketOperationScheduleMessage ==
    { ZeroSpotGoldMarketOperationScheduleMessage }
        \cup { [ZeroSpotGoldMarketOperationScheduleMessage EXCEPT !.marketOperationProductId = one] : one \in Sample(3) }
        \cup { [ZeroSpotGoldMarketOperationScheduleMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroSpotGoldMarketOperationScheduleMessage EXCEPT !.boardEventId = one] : one \in Sample(3) }
        \cup { [ZeroSpotGoldMarketOperationScheduleMessage EXCEPT !.startTimeOfABoardEvent = one] : one \in Sample(9) }
        \cup { [ZeroSpotGoldMarketOperationScheduleMessage EXCEPT !.boardEventGroupCode = one] : one \in Sample(5) }
        \cup { [ZeroSpotGoldMarketOperationScheduleMessage EXCEPT !.sessionStartEndCode = one] : one \in Sample(2) }
        \cup { [ZeroSpotGoldMarketOperationScheduleMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroSpotGoldMarketOperationScheduleMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationScheduleMessage EXCEPT !.isinCodeOfACommonStock = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldMarketOperationScheduleMessage EXCEPT !.productId = one] : one \in Sample(11) }
        \cup { [ZeroSpotGoldMarketOperationScheduleMessage EXCEPT !.tradingHaltReasonCode = one] : one \in Sample(3) }
        \cup { [ZeroSpotGoldMarketOperationScheduleMessage EXCEPT !.tradingHaltTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroSpotGoldMarketOperationScheduleMessage EXCEPT !.stepApplied = one] : one \in Sample(2) }
        \cup { [ZeroSpotGoldMarketOperationScheduleMessage EXCEPT !.priceLimitRangeExpansionForBaseIssueTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroSpotGoldMarketOperationScheduleMessage EXCEPT !.expectedTimeOfExpandingPriceLimitRange = one] : one \in Sample(9) }
        \cup { [ZeroSpotGoldMarketOperationScheduleMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Emissions Market Operation Ts Message: 63 bytes                         *)
(***************************************************************************)

EmissionsMarketOperationTsMessage ==
    [ messageSequenceNumber         : Sample(8),
      boardId                       : Sample(2),
      sessionId                     : Sample(2),
      isinCode                      : Sample(12),
      aDesignatedNumberForAnIssue   : Sample(6),
      processingTimeOfTradingSystem : Sample(12),
      boardEventId                  : Sample(3),
      startTimeOfABoardEvent        : Sample(9),
      boardEventGroupCode           : Sample(5),
      tradingHaltReasonCode         : Sample(3),
      endKeyword                    : Sample(1) ]

EncodeEmissionsMarketOperationTsMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.sessionId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.processingTimeOfTradingSystem
        \o message.boardEventId
        \o message.startTimeOfABoardEvent
        \o message.boardEventGroupCode
        \o message.tradingHaltReasonCode
        \o message.endKeyword

DecodeEmissionsMarketOperationTsMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(boardId.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(sessionId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET processingTimeOfTradingSystem == ReadBytes(aDesignatedNumberForAnIssue.rest, 12) IN IF ~processingTimeOfTradingSystem.ok THEN Fail ELSE
    LET boardEventId == ReadBytes(processingTimeOfTradingSystem.rest, 3) IN IF ~boardEventId.ok THEN Fail ELSE
    LET startTimeOfABoardEvent == ReadBytes(boardEventId.rest, 9) IN IF ~startTimeOfABoardEvent.ok THEN Fail ELSE
    LET boardEventGroupCode == ReadBytes(startTimeOfABoardEvent.rest, 5) IN IF ~boardEventGroupCode.ok THEN Fail ELSE
    LET tradingHaltReasonCode == ReadBytes(boardEventGroupCode.rest, 3) IN IF ~tradingHaltReasonCode.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(tradingHaltReasonCode.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber         |-> messageSequenceNumber.value,
         boardId                       |-> boardId.value,
         sessionId                     |-> sessionId.value,
         isinCode                      |-> isinCode.value,
         aDesignatedNumberForAnIssue   |-> aDesignatedNumberForAnIssue.value,
         processingTimeOfTradingSystem |-> processingTimeOfTradingSystem.value,
         boardEventId                  |-> boardEventId.value,
         startTimeOfABoardEvent        |-> startTimeOfABoardEvent.value,
         boardEventGroupCode           |-> boardEventGroupCode.value,
         tradingHaltReasonCode         |-> tradingHaltReasonCode.value,
         endKeyword                    |-> endKeyword.value ], endKeyword.rest)

ZeroEmissionsMarketOperationTsMessage ==
    [ messageSequenceNumber         |-> [i \in 1 .. 8 |-> 0],
      boardId                       |-> [i \in 1 .. 2 |-> 0],
      sessionId                     |-> [i \in 1 .. 2 |-> 0],
      isinCode                      |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue   |-> [i \in 1 .. 6 |-> 0],
      processingTimeOfTradingSystem |-> [i \in 1 .. 12 |-> 0],
      boardEventId                  |-> [i \in 1 .. 3 |-> 0],
      startTimeOfABoardEvent        |-> [i \in 1 .. 9 |-> 0],
      boardEventGroupCode           |-> [i \in 1 .. 5 |-> 0],
      tradingHaltReasonCode         |-> [i \in 1 .. 3 |-> 0],
      endKeyword                    |-> [i \in 1 .. 1 |-> 0] ]

(* Emissions Market Operation Ts Message at zero, then each field in turn at the values it is checked at *)
CheckedEmissionsMarketOperationTsMessage ==
    { ZeroEmissionsMarketOperationTsMessage }
        \cup { [ZeroEmissionsMarketOperationTsMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroEmissionsMarketOperationTsMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroEmissionsMarketOperationTsMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroEmissionsMarketOperationTsMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsMarketOperationTsMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroEmissionsMarketOperationTsMessage EXCEPT !.processingTimeOfTradingSystem = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsMarketOperationTsMessage EXCEPT !.boardEventId = one] : one \in Sample(3) }
        \cup { [ZeroEmissionsMarketOperationTsMessage EXCEPT !.startTimeOfABoardEvent = one] : one \in Sample(9) }
        \cup { [ZeroEmissionsMarketOperationTsMessage EXCEPT !.boardEventGroupCode = one] : one \in Sample(5) }
        \cup { [ZeroEmissionsMarketOperationTsMessage EXCEPT !.tradingHaltReasonCode = one] : one \in Sample(3) }
        \cup { [ZeroEmissionsMarketOperationTsMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Emissions Issue Closing Message: 107 bytes                              *)
(***************************************************************************)

EmissionsIssueClosingMessage ==
    [ messageSequenceNumber                 : Sample(8),
      boardId                               : Sample(2),
      isinCode                              : Sample(12),
      aDesignatedNumberForAnIssue           : Sample(6),
      closingPriceLong                      : Sample(11),
      closingPriceTypeCode                  : Sample(1),
      filler11                              : Sample(11),
      secondFiller11                        : Sample(11),
      closingPriceWeightedStockPriceAverage : Sample(11),
      closingPriceBasePriceOfBuyIn          : Sample(11),
      closingPriceUpperLimitOfBuyIn         : Sample(11),
      closingPriceLowerLimitOfBuyIn         : Sample(11),
      endKeyword                            : Sample(1) ]

EncodeEmissionsIssueClosingMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.closingPriceLong
        \o message.closingPriceTypeCode
        \o message.filler11
        \o message.secondFiller11
        \o message.closingPriceWeightedStockPriceAverage
        \o message.closingPriceBasePriceOfBuyIn
        \o message.closingPriceUpperLimitOfBuyIn
        \o message.closingPriceLowerLimitOfBuyIn
        \o message.endKeyword

DecodeEmissionsIssueClosingMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(boardId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET closingPriceLong == ReadBytes(aDesignatedNumberForAnIssue.rest, 11) IN IF ~closingPriceLong.ok THEN Fail ELSE
    LET closingPriceTypeCode == ReadBytes(closingPriceLong.rest, 1) IN IF ~closingPriceTypeCode.ok THEN Fail ELSE
    LET filler11 == ReadBytes(closingPriceTypeCode.rest, 11) IN IF ~filler11.ok THEN Fail ELSE
    LET secondFiller11 == ReadBytes(filler11.rest, 11) IN IF ~secondFiller11.ok THEN Fail ELSE
    LET closingPriceWeightedStockPriceAverage == ReadBytes(secondFiller11.rest, 11) IN IF ~closingPriceWeightedStockPriceAverage.ok THEN Fail ELSE
    LET closingPriceBasePriceOfBuyIn == ReadBytes(closingPriceWeightedStockPriceAverage.rest, 11) IN IF ~closingPriceBasePriceOfBuyIn.ok THEN Fail ELSE
    LET closingPriceUpperLimitOfBuyIn == ReadBytes(closingPriceBasePriceOfBuyIn.rest, 11) IN IF ~closingPriceUpperLimitOfBuyIn.ok THEN Fail ELSE
    LET closingPriceLowerLimitOfBuyIn == ReadBytes(closingPriceUpperLimitOfBuyIn.rest, 11) IN IF ~closingPriceLowerLimitOfBuyIn.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(closingPriceLowerLimitOfBuyIn.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber                 |-> messageSequenceNumber.value,
         boardId                               |-> boardId.value,
         isinCode                              |-> isinCode.value,
         aDesignatedNumberForAnIssue           |-> aDesignatedNumberForAnIssue.value,
         closingPriceLong                      |-> closingPriceLong.value,
         closingPriceTypeCode                  |-> closingPriceTypeCode.value,
         filler11                              |-> filler11.value,
         secondFiller11                        |-> secondFiller11.value,
         closingPriceWeightedStockPriceAverage |-> closingPriceWeightedStockPriceAverage.value,
         closingPriceBasePriceOfBuyIn          |-> closingPriceBasePriceOfBuyIn.value,
         closingPriceUpperLimitOfBuyIn         |-> closingPriceUpperLimitOfBuyIn.value,
         closingPriceLowerLimitOfBuyIn         |-> closingPriceLowerLimitOfBuyIn.value,
         endKeyword                            |-> endKeyword.value ], endKeyword.rest)

ZeroEmissionsIssueClosingMessage ==
    [ messageSequenceNumber                 |-> [i \in 1 .. 8 |-> 0],
      boardId                               |-> [i \in 1 .. 2 |-> 0],
      isinCode                              |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue           |-> [i \in 1 .. 6 |-> 0],
      closingPriceLong                      |-> [i \in 1 .. 11 |-> 0],
      closingPriceTypeCode                  |-> [i \in 1 .. 1 |-> 0],
      filler11                              |-> [i \in 1 .. 11 |-> 0],
      secondFiller11                        |-> [i \in 1 .. 11 |-> 0],
      closingPriceWeightedStockPriceAverage |-> [i \in 1 .. 11 |-> 0],
      closingPriceBasePriceOfBuyIn          |-> [i \in 1 .. 11 |-> 0],
      closingPriceUpperLimitOfBuyIn         |-> [i \in 1 .. 11 |-> 0],
      closingPriceLowerLimitOfBuyIn         |-> [i \in 1 .. 11 |-> 0],
      endKeyword                            |-> [i \in 1 .. 1 |-> 0] ]

(* Emissions Issue Closing Message at zero, then each field in turn at the values it is checked at *)
CheckedEmissionsIssueClosingMessage ==
    { ZeroEmissionsIssueClosingMessage }
        \cup { [ZeroEmissionsIssueClosingMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroEmissionsIssueClosingMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroEmissionsIssueClosingMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsIssueClosingMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroEmissionsIssueClosingMessage EXCEPT !.closingPriceLong = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsIssueClosingMessage EXCEPT !.closingPriceTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroEmissionsIssueClosingMessage EXCEPT !.filler11 = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsIssueClosingMessage EXCEPT !.secondFiller11 = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsIssueClosingMessage EXCEPT !.closingPriceWeightedStockPriceAverage = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsIssueClosingMessage EXCEPT !.closingPriceBasePriceOfBuyIn = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsIssueClosingMessage EXCEPT !.closingPriceUpperLimitOfBuyIn = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsIssueClosingMessage EXCEPT !.closingPriceLowerLimitOfBuyIn = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsIssueClosingMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Emissions Market Operation Schedule Message: 78 bytes                   *)
(***************************************************************************)

EmissionsMarketOperationScheduleMessage ==
    [ marketOperationProductId                     : Sample(3),
      boardId                                      : Sample(2),
      boardEventId                                 : Sample(3),
      startTimeOfABoardEvent                       : Sample(9),
      boardEventGroupCode                          : Sample(5),
      sessionStartEndCode                          : Sample(2),
      sessionId                                    : Sample(2),
      isinCode                                     : Sample(12),
      isinCodeOfACommonStock                       : Sample(12),
      productId                                    : Sample(11),
      tradingHaltReasonCode                        : Sample(3),
      tradingHaltTypeCode                          : Sample(1),
      stepApplied                                  : Sample(2),
      priceLimitRangeExpansionForBaseIssueTypeCode : Sample(1),
      expectedTimeOfExpandingPriceLimitRange       : Sample(9),
      endKeyword                                   : Sample(1) ]

EncodeEmissionsMarketOperationScheduleMessage(message) ==
    message.marketOperationProductId
        \o message.boardId
        \o message.boardEventId
        \o message.startTimeOfABoardEvent
        \o message.boardEventGroupCode
        \o message.sessionStartEndCode
        \o message.sessionId
        \o message.isinCode
        \o message.isinCodeOfACommonStock
        \o message.productId
        \o message.tradingHaltReasonCode
        \o message.tradingHaltTypeCode
        \o message.stepApplied
        \o message.priceLimitRangeExpansionForBaseIssueTypeCode
        \o message.expectedTimeOfExpandingPriceLimitRange
        \o message.endKeyword

DecodeEmissionsMarketOperationScheduleMessage(bytes) ==
    LET marketOperationProductId == ReadBytes(bytes, 3) IN IF ~marketOperationProductId.ok THEN Fail ELSE
    LET boardId == ReadBytes(marketOperationProductId.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET boardEventId == ReadBytes(boardId.rest, 3) IN IF ~boardEventId.ok THEN Fail ELSE
    LET startTimeOfABoardEvent == ReadBytes(boardEventId.rest, 9) IN IF ~startTimeOfABoardEvent.ok THEN Fail ELSE
    LET boardEventGroupCode == ReadBytes(startTimeOfABoardEvent.rest, 5) IN IF ~boardEventGroupCode.ok THEN Fail ELSE
    LET sessionStartEndCode == ReadBytes(boardEventGroupCode.rest, 2) IN IF ~sessionStartEndCode.ok THEN Fail ELSE
    LET sessionId == ReadBytes(sessionStartEndCode.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(sessionId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET isinCodeOfACommonStock == ReadBytes(isinCode.rest, 12) IN IF ~isinCodeOfACommonStock.ok THEN Fail ELSE
    LET productId == ReadBytes(isinCodeOfACommonStock.rest, 11) IN IF ~productId.ok THEN Fail ELSE
    LET tradingHaltReasonCode == ReadBytes(productId.rest, 3) IN IF ~tradingHaltReasonCode.ok THEN Fail ELSE
    LET tradingHaltTypeCode == ReadBytes(tradingHaltReasonCode.rest, 1) IN IF ~tradingHaltTypeCode.ok THEN Fail ELSE
    LET stepApplied == ReadBytes(tradingHaltTypeCode.rest, 2) IN IF ~stepApplied.ok THEN Fail ELSE
    LET priceLimitRangeExpansionForBaseIssueTypeCode == ReadBytes(stepApplied.rest, 1) IN IF ~priceLimitRangeExpansionForBaseIssueTypeCode.ok THEN Fail ELSE
    LET expectedTimeOfExpandingPriceLimitRange == ReadBytes(priceLimitRangeExpansionForBaseIssueTypeCode.rest, 9) IN IF ~expectedTimeOfExpandingPriceLimitRange.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(expectedTimeOfExpandingPriceLimitRange.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ marketOperationProductId                     |-> marketOperationProductId.value,
         boardId                                      |-> boardId.value,
         boardEventId                                 |-> boardEventId.value,
         startTimeOfABoardEvent                       |-> startTimeOfABoardEvent.value,
         boardEventGroupCode                          |-> boardEventGroupCode.value,
         sessionStartEndCode                          |-> sessionStartEndCode.value,
         sessionId                                    |-> sessionId.value,
         isinCode                                     |-> isinCode.value,
         isinCodeOfACommonStock                       |-> isinCodeOfACommonStock.value,
         productId                                    |-> productId.value,
         tradingHaltReasonCode                        |-> tradingHaltReasonCode.value,
         tradingHaltTypeCode                          |-> tradingHaltTypeCode.value,
         stepApplied                                  |-> stepApplied.value,
         priceLimitRangeExpansionForBaseIssueTypeCode |-> priceLimitRangeExpansionForBaseIssueTypeCode.value,
         expectedTimeOfExpandingPriceLimitRange       |-> expectedTimeOfExpandingPriceLimitRange.value,
         endKeyword                                   |-> endKeyword.value ], endKeyword.rest)

ZeroEmissionsMarketOperationScheduleMessage ==
    [ marketOperationProductId                     |-> [i \in 1 .. 3 |-> 0],
      boardId                                      |-> [i \in 1 .. 2 |-> 0],
      boardEventId                                 |-> [i \in 1 .. 3 |-> 0],
      startTimeOfABoardEvent                       |-> [i \in 1 .. 9 |-> 0],
      boardEventGroupCode                          |-> [i \in 1 .. 5 |-> 0],
      sessionStartEndCode                          |-> [i \in 1 .. 2 |-> 0],
      sessionId                                    |-> [i \in 1 .. 2 |-> 0],
      isinCode                                     |-> [i \in 1 .. 12 |-> 0],
      isinCodeOfACommonStock                       |-> [i \in 1 .. 12 |-> 0],
      productId                                    |-> [i \in 1 .. 11 |-> 0],
      tradingHaltReasonCode                        |-> [i \in 1 .. 3 |-> 0],
      tradingHaltTypeCode                          |-> [i \in 1 .. 1 |-> 0],
      stepApplied                                  |-> [i \in 1 .. 2 |-> 0],
      priceLimitRangeExpansionForBaseIssueTypeCode |-> [i \in 1 .. 1 |-> 0],
      expectedTimeOfExpandingPriceLimitRange       |-> [i \in 1 .. 9 |-> 0],
      endKeyword                                   |-> [i \in 1 .. 1 |-> 0] ]

(* Emissions Market Operation Schedule Message at zero, then each field in turn at the values it is checked at *)
CheckedEmissionsMarketOperationScheduleMessage ==
    { ZeroEmissionsMarketOperationScheduleMessage }
        \cup { [ZeroEmissionsMarketOperationScheduleMessage EXCEPT !.marketOperationProductId = one] : one \in Sample(3) }
        \cup { [ZeroEmissionsMarketOperationScheduleMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroEmissionsMarketOperationScheduleMessage EXCEPT !.boardEventId = one] : one \in Sample(3) }
        \cup { [ZeroEmissionsMarketOperationScheduleMessage EXCEPT !.startTimeOfABoardEvent = one] : one \in Sample(9) }
        \cup { [ZeroEmissionsMarketOperationScheduleMessage EXCEPT !.boardEventGroupCode = one] : one \in Sample(5) }
        \cup { [ZeroEmissionsMarketOperationScheduleMessage EXCEPT !.sessionStartEndCode = one] : one \in Sample(2) }
        \cup { [ZeroEmissionsMarketOperationScheduleMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroEmissionsMarketOperationScheduleMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsMarketOperationScheduleMessage EXCEPT !.isinCodeOfACommonStock = one] : one \in Sample(12) }
        \cup { [ZeroEmissionsMarketOperationScheduleMessage EXCEPT !.productId = one] : one \in Sample(11) }
        \cup { [ZeroEmissionsMarketOperationScheduleMessage EXCEPT !.tradingHaltReasonCode = one] : one \in Sample(3) }
        \cup { [ZeroEmissionsMarketOperationScheduleMessage EXCEPT !.tradingHaltTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroEmissionsMarketOperationScheduleMessage EXCEPT !.stepApplied = one] : one \in Sample(2) }
        \cup { [ZeroEmissionsMarketOperationScheduleMessage EXCEPT !.priceLimitRangeExpansionForBaseIssueTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroEmissionsMarketOperationScheduleMessage EXCEPT !.expectedTimeOfExpandingPriceLimitRange = one] : one \in Sample(9) }
        \cup { [ZeroEmissionsMarketOperationScheduleMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Spot Gold Random End Message: 30 bytes                                  *)
(***************************************************************************)

SpotGoldRandomEndMessage ==
    [ messageSequenceNumber       : Sample(8),
      boardId                     : Sample(2),
      isinCode                    : Sample(12),
      aDesignatedNumberForAnIssue : Sample(6),
      randomEndTriggerCode        : Sample(1),
      endKeyword                  : Sample(1) ]

EncodeSpotGoldRandomEndMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.randomEndTriggerCode
        \o message.endKeyword

DecodeSpotGoldRandomEndMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(boardId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET randomEndTriggerCode == ReadBytes(aDesignatedNumberForAnIssue.rest, 1) IN IF ~randomEndTriggerCode.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(randomEndTriggerCode.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber       |-> messageSequenceNumber.value,
         boardId                     |-> boardId.value,
         isinCode                    |-> isinCode.value,
         aDesignatedNumberForAnIssue |-> aDesignatedNumberForAnIssue.value,
         randomEndTriggerCode        |-> randomEndTriggerCode.value,
         endKeyword                  |-> endKeyword.value ], endKeyword.rest)

ZeroSpotGoldRandomEndMessage ==
    [ messageSequenceNumber       |-> [i \in 1 .. 8 |-> 0],
      boardId                     |-> [i \in 1 .. 2 |-> 0],
      isinCode                    |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue |-> [i \in 1 .. 6 |-> 0],
      randomEndTriggerCode        |-> [i \in 1 .. 1 |-> 0],
      endKeyword                  |-> [i \in 1 .. 1 |-> 0] ]

(* Spot Gold Random End Message at zero, then each field in turn at the values it is checked at *)
CheckedSpotGoldRandomEndMessage ==
    { ZeroSpotGoldRandomEndMessage }
        \cup { [ZeroSpotGoldRandomEndMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSpotGoldRandomEndMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroSpotGoldRandomEndMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSpotGoldRandomEndMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroSpotGoldRandomEndMessage EXCEPT !.randomEndTriggerCode = one] : one \in Sample(1) }
        \cup { [ZeroSpotGoldRandomEndMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by Tr Code                                            *)
(***************************************************************************)

PollingDataMessageCode == <<73, 50, 48, 48, 48>>  \* "I2000"
KrxIndexMessageCode == <<73, 65, 48, 48, 48>>  \* "IA000"
KrxEstimatedIndexMessageCode == <<73, 66, 48, 48, 48>>  \* "IB000"
GlobalIndexMessageCode == <<74, 50, 48, 48, 48>>  \* "J2000"
BondPrimeIndexMessageCode == <<74, 52, 48, 48, 48>>  \* "J4000"
BondKtbIndexMessageCode == <<75, 49, 48, 48, 48>>  \* "K1000"
BondKtbIndexTermStructureMessageCode == <<75, 56, 48, 48, 48>>  \* "K8000"
BondIndexKrxMessageCode == <<73, 71, 48, 48, 48>>  \* "IG000"
SpotGoldQuoteMessageCode == <<66, 54, 48, 49, 71>>  \* "B601G"
SpotGoldOrderFilledMessageCode == <<65, 51, 48, 49, 71>>  \* "A301G"
SpotGoldOrderFilledPlusQuoteMessageCode == <<71, 55, 48, 49, 71>>  \* "G701G"
SpotGoldMarketOperationTsPlusQuoteMessageCode == <<82, 49, 48, 49, 71>>  \* "R101G"
SpotGoldSnapshotMessageCode == <<66, 50, 48, 49, 71>>  \* "B201G"
SpotGoldNegotiatedTradeMessageCode == <<67, 52, 48, 49, 71>>  \* "C401G"
EmissionsQuoteMessageCode == <<66, 54, 48, 49, 69>>  \* "B601E"
EmissionsOrderFilledMessageCode == <<65, 51, 48, 49, 69>>  \* "A301E"
EmissionsOrderFilledPlusQuoteMessageCode == <<71, 55, 48, 49, 69>>  \* "G701E"
EmissionsMarketOperationTsPlusQuoteMessageCode == <<82, 49, 48, 49, 69>>  \* "R101E"
EmissionsSnapshotMessageCode == <<66, 50, 48, 49, 69>>  \* "B201E"
EmissionsNegotiatedTradeMessageCode == <<67, 52, 48, 49, 69>>  \* "C401E"
EmissionsDeterminationOfBasePriceMessageCode == <<65, 52, 48, 49, 69>>  \* "A401E"
EmissionsAuctionResultsMessageCode == <<65, 67, 48, 49, 69>>  \* "AC01E"
SpotGoldBatchDataMessageCode == <<65, 48, 48, 49, 71>>  \* "A001G"
EmissionsBatchDataMessageCode == <<65, 48, 48, 49, 69>>  \* "A001E"
ExternalGoldSpotClosingPriceMessageCode == <<77, 50, 48, 48, 71>>  \* "M200G"
SpotGoldMarketOperationTsMessageCode == <<65, 55, 48, 49, 71>>  \* "A701G"
SpotGoldIssueClosingMessageCode == <<65, 54, 48, 49, 71>>  \* "A601G"
SpotGoldMarketOperationScheduleMessageCode == <<77, 52, 48, 49, 71>>  \* "M401G"
EmissionsMarketOperationTsMessageCode == <<65, 55, 48, 49, 69>>  \* "A701E"
EmissionsIssueClosingMessageCode == <<65, 54, 48, 49, 69>>  \* "A601E"
EmissionsMarketOperationScheduleMessageCode == <<77, 52, 48, 49, 69>>  \* "M401E"
SpotGoldRandomEndMessageCode == <<65, 53, 48, 49, 88>>  \* "A501X"
SpotGoldRandomEndMessageCode2 == <<65, 53, 48, 49, 71>>  \* "A501G"

Payload ==
    [ tag : {PollingDataMessageCode}, body : PollingDataMessage ]
        \cup [ tag : {KrxIndexMessageCode}, body : KrxIndexMessage ]
        \cup [ tag : {KrxEstimatedIndexMessageCode}, body : KrxEstimatedIndexMessage ]
        \cup [ tag : {GlobalIndexMessageCode}, body : GlobalIndexMessage ]
        \cup [ tag : {BondPrimeIndexMessageCode}, body : BondPrimeIndexMessage ]
        \cup [ tag : {BondKtbIndexMessageCode}, body : BondKtbIndexMessage ]
        \cup [ tag : {BondKtbIndexTermStructureMessageCode}, body : BondKtbIndexTermStructureMessage ]
        \cup [ tag : {BondIndexKrxMessageCode}, body : BondIndexKrxMessage ]
        \cup [ tag : {SpotGoldQuoteMessageCode}, body : SpotGoldQuoteMessage ]
        \cup [ tag : {SpotGoldOrderFilledMessageCode}, body : SpotGoldOrderFilledMessage ]
        \cup [ tag : {SpotGoldOrderFilledPlusQuoteMessageCode}, body : SpotGoldOrderFilledPlusQuoteMessage ]
        \cup [ tag : {SpotGoldMarketOperationTsPlusQuoteMessageCode}, body : SpotGoldMarketOperationTsPlusQuoteMessage ]
        \cup [ tag : {SpotGoldSnapshotMessageCode}, body : SpotGoldSnapshotMessage ]
        \cup [ tag : {SpotGoldNegotiatedTradeMessageCode}, body : SpotGoldNegotiatedTradeMessage ]
        \cup [ tag : {EmissionsQuoteMessageCode}, body : EmissionsQuoteMessage ]
        \cup [ tag : {EmissionsOrderFilledMessageCode}, body : EmissionsOrderFilledMessage ]
        \cup [ tag : {EmissionsOrderFilledPlusQuoteMessageCode}, body : EmissionsOrderFilledPlusQuoteMessage ]
        \cup [ tag : {EmissionsMarketOperationTsPlusQuoteMessageCode}, body : EmissionsMarketOperationTsPlusQuoteMessage ]
        \cup [ tag : {EmissionsSnapshotMessageCode}, body : EmissionsSnapshotMessage ]
        \cup [ tag : {EmissionsNegotiatedTradeMessageCode}, body : EmissionsNegotiatedTradeMessage ]
        \cup [ tag : {EmissionsDeterminationOfBasePriceMessageCode}, body : EmissionsDeterminationOfBasePriceMessage ]
        \cup [ tag : {EmissionsAuctionResultsMessageCode}, body : EmissionsAuctionResultsMessage ]
        \cup [ tag : {SpotGoldBatchDataMessageCode}, body : SpotGoldBatchDataMessage ]
        \cup [ tag : {EmissionsBatchDataMessageCode}, body : EmissionsBatchDataMessage ]
        \cup [ tag : {ExternalGoldSpotClosingPriceMessageCode}, body : ExternalGoldSpotClosingPriceMessage ]
        \cup [ tag : {SpotGoldMarketOperationTsMessageCode}, body : SpotGoldMarketOperationTsMessage ]
        \cup [ tag : {SpotGoldIssueClosingMessageCode}, body : SpotGoldIssueClosingMessage ]
        \cup [ tag : {SpotGoldMarketOperationScheduleMessageCode}, body : SpotGoldMarketOperationScheduleMessage ]
        \cup [ tag : {EmissionsMarketOperationTsMessageCode}, body : EmissionsMarketOperationTsMessage ]
        \cup [ tag : {EmissionsIssueClosingMessageCode}, body : EmissionsIssueClosingMessage ]
        \cup [ tag : {EmissionsMarketOperationScheduleMessageCode}, body : EmissionsMarketOperationScheduleMessage ]
        \cup [ tag : {SpotGoldRandomEndMessageCode}, body : SpotGoldRandomEndMessage ]
        \cup [ tag : {SpotGoldRandomEndMessageCode2}, body : SpotGoldRandomEndMessage ]

EncodePayload(message) ==
    CASE message.tag = PollingDataMessageCode -> EncodePollingDataMessage(message.body)
      [] message.tag = KrxIndexMessageCode -> EncodeKrxIndexMessage(message.body)
      [] message.tag = KrxEstimatedIndexMessageCode -> EncodeKrxEstimatedIndexMessage(message.body)
      [] message.tag = GlobalIndexMessageCode -> EncodeGlobalIndexMessage(message.body)
      [] message.tag = BondPrimeIndexMessageCode -> EncodeBondPrimeIndexMessage(message.body)
      [] message.tag = BondKtbIndexMessageCode -> EncodeBondKtbIndexMessage(message.body)
      [] message.tag = BondKtbIndexTermStructureMessageCode -> EncodeBondKtbIndexTermStructureMessage(message.body)
      [] message.tag = BondIndexKrxMessageCode -> EncodeBondIndexKrxMessage(message.body)
      [] message.tag = SpotGoldQuoteMessageCode -> EncodeSpotGoldQuoteMessage(message.body)
      [] message.tag = SpotGoldOrderFilledMessageCode -> EncodeSpotGoldOrderFilledMessage(message.body)
      [] message.tag = SpotGoldOrderFilledPlusQuoteMessageCode -> EncodeSpotGoldOrderFilledPlusQuoteMessage(message.body)
      [] message.tag = SpotGoldMarketOperationTsPlusQuoteMessageCode -> EncodeSpotGoldMarketOperationTsPlusQuoteMessage(message.body)
      [] message.tag = SpotGoldSnapshotMessageCode -> EncodeSpotGoldSnapshotMessage(message.body)
      [] message.tag = SpotGoldNegotiatedTradeMessageCode -> EncodeSpotGoldNegotiatedTradeMessage(message.body)
      [] message.tag = EmissionsQuoteMessageCode -> EncodeEmissionsQuoteMessage(message.body)
      [] message.tag = EmissionsOrderFilledMessageCode -> EncodeEmissionsOrderFilledMessage(message.body)
      [] message.tag = EmissionsOrderFilledPlusQuoteMessageCode -> EncodeEmissionsOrderFilledPlusQuoteMessage(message.body)
      [] message.tag = EmissionsMarketOperationTsPlusQuoteMessageCode -> EncodeEmissionsMarketOperationTsPlusQuoteMessage(message.body)
      [] message.tag = EmissionsSnapshotMessageCode -> EncodeEmissionsSnapshotMessage(message.body)
      [] message.tag = EmissionsNegotiatedTradeMessageCode -> EncodeEmissionsNegotiatedTradeMessage(message.body)
      [] message.tag = EmissionsDeterminationOfBasePriceMessageCode -> EncodeEmissionsDeterminationOfBasePriceMessage(message.body)
      [] message.tag = EmissionsAuctionResultsMessageCode -> EncodeEmissionsAuctionResultsMessage(message.body)
      [] message.tag = SpotGoldBatchDataMessageCode -> EncodeSpotGoldBatchDataMessage(message.body)
      [] message.tag = EmissionsBatchDataMessageCode -> EncodeEmissionsBatchDataMessage(message.body)
      [] message.tag = ExternalGoldSpotClosingPriceMessageCode -> EncodeExternalGoldSpotClosingPriceMessage(message.body)
      [] message.tag = SpotGoldMarketOperationTsMessageCode -> EncodeSpotGoldMarketOperationTsMessage(message.body)
      [] message.tag = SpotGoldIssueClosingMessageCode -> EncodeSpotGoldIssueClosingMessage(message.body)
      [] message.tag = SpotGoldMarketOperationScheduleMessageCode -> EncodeSpotGoldMarketOperationScheduleMessage(message.body)
      [] message.tag = EmissionsMarketOperationTsMessageCode -> EncodeEmissionsMarketOperationTsMessage(message.body)
      [] message.tag = EmissionsIssueClosingMessageCode -> EncodeEmissionsIssueClosingMessage(message.body)
      [] message.tag = EmissionsMarketOperationScheduleMessageCode -> EncodeEmissionsMarketOperationScheduleMessage(message.body)
      [] message.tag = SpotGoldRandomEndMessageCode -> EncodeSpotGoldRandomEndMessage(message.body)
      [] message.tag = SpotGoldRandomEndMessageCode2 -> EncodeSpotGoldRandomEndMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = PollingDataMessageCode -> DecodePollingDataMessage(bytes)
              [] tag = KrxIndexMessageCode -> DecodeKrxIndexMessage(bytes)
              [] tag = KrxEstimatedIndexMessageCode -> DecodeKrxEstimatedIndexMessage(bytes)
              [] tag = GlobalIndexMessageCode -> DecodeGlobalIndexMessage(bytes)
              [] tag = BondPrimeIndexMessageCode -> DecodeBondPrimeIndexMessage(bytes)
              [] tag = BondKtbIndexMessageCode -> DecodeBondKtbIndexMessage(bytes)
              [] tag = BondKtbIndexTermStructureMessageCode -> DecodeBondKtbIndexTermStructureMessage(bytes)
              [] tag = BondIndexKrxMessageCode -> DecodeBondIndexKrxMessage(bytes)
              [] tag = SpotGoldQuoteMessageCode -> DecodeSpotGoldQuoteMessage(bytes)
              [] tag = SpotGoldOrderFilledMessageCode -> DecodeSpotGoldOrderFilledMessage(bytes)
              [] tag = SpotGoldOrderFilledPlusQuoteMessageCode -> DecodeSpotGoldOrderFilledPlusQuoteMessage(bytes)
              [] tag = SpotGoldMarketOperationTsPlusQuoteMessageCode -> DecodeSpotGoldMarketOperationTsPlusQuoteMessage(bytes)
              [] tag = SpotGoldSnapshotMessageCode -> DecodeSpotGoldSnapshotMessage(bytes)
              [] tag = SpotGoldNegotiatedTradeMessageCode -> DecodeSpotGoldNegotiatedTradeMessage(bytes)
              [] tag = EmissionsQuoteMessageCode -> DecodeEmissionsQuoteMessage(bytes)
              [] tag = EmissionsOrderFilledMessageCode -> DecodeEmissionsOrderFilledMessage(bytes)
              [] tag = EmissionsOrderFilledPlusQuoteMessageCode -> DecodeEmissionsOrderFilledPlusQuoteMessage(bytes)
              [] tag = EmissionsMarketOperationTsPlusQuoteMessageCode -> DecodeEmissionsMarketOperationTsPlusQuoteMessage(bytes)
              [] tag = EmissionsSnapshotMessageCode -> DecodeEmissionsSnapshotMessage(bytes)
              [] tag = EmissionsNegotiatedTradeMessageCode -> DecodeEmissionsNegotiatedTradeMessage(bytes)
              [] tag = EmissionsDeterminationOfBasePriceMessageCode -> DecodeEmissionsDeterminationOfBasePriceMessage(bytes)
              [] tag = EmissionsAuctionResultsMessageCode -> DecodeEmissionsAuctionResultsMessage(bytes)
              [] tag = SpotGoldBatchDataMessageCode -> DecodeSpotGoldBatchDataMessage(bytes)
              [] tag = EmissionsBatchDataMessageCode -> DecodeEmissionsBatchDataMessage(bytes)
              [] tag = ExternalGoldSpotClosingPriceMessageCode -> DecodeExternalGoldSpotClosingPriceMessage(bytes)
              [] tag = SpotGoldMarketOperationTsMessageCode -> DecodeSpotGoldMarketOperationTsMessage(bytes)
              [] tag = SpotGoldIssueClosingMessageCode -> DecodeSpotGoldIssueClosingMessage(bytes)
              [] tag = SpotGoldMarketOperationScheduleMessageCode -> DecodeSpotGoldMarketOperationScheduleMessage(bytes)
              [] tag = EmissionsMarketOperationTsMessageCode -> DecodeEmissionsMarketOperationTsMessage(bytes)
              [] tag = EmissionsIssueClosingMessageCode -> DecodeEmissionsIssueClosingMessage(bytes)
              [] tag = EmissionsMarketOperationScheduleMessageCode -> DecodeEmissionsMarketOperationScheduleMessage(bytes)
              [] tag = SpotGoldRandomEndMessageCode -> DecodeSpotGoldRandomEndMessage(bytes)
              [] tag = SpotGoldRandomEndMessageCode2 -> DecodeSpotGoldRandomEndMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> PollingDataMessageCode, body |-> ZeroPollingDataMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> PollingDataMessageCode, body |-> one] : one \in CheckedPollingDataMessage }
        \cup { [tag |-> KrxIndexMessageCode, body |-> one] : one \in CheckedKrxIndexMessage }
        \cup { [tag |-> KrxEstimatedIndexMessageCode, body |-> one] : one \in CheckedKrxEstimatedIndexMessage }
        \cup { [tag |-> GlobalIndexMessageCode, body |-> one] : one \in CheckedGlobalIndexMessage }
        \cup { [tag |-> BondPrimeIndexMessageCode, body |-> one] : one \in CheckedBondPrimeIndexMessage }
        \cup { [tag |-> BondKtbIndexMessageCode, body |-> one] : one \in CheckedBondKtbIndexMessage }
        \cup { [tag |-> BondKtbIndexTermStructureMessageCode, body |-> one] : one \in CheckedBondKtbIndexTermStructureMessage }
        \cup { [tag |-> BondIndexKrxMessageCode, body |-> one] : one \in CheckedBondIndexKrxMessage }
        \cup { [tag |-> SpotGoldQuoteMessageCode, body |-> one] : one \in CheckedSpotGoldQuoteMessage }
        \cup { [tag |-> SpotGoldOrderFilledMessageCode, body |-> one] : one \in CheckedSpotGoldOrderFilledMessage }
        \cup { [tag |-> SpotGoldOrderFilledPlusQuoteMessageCode, body |-> one] : one \in CheckedSpotGoldOrderFilledPlusQuoteMessage }
        \cup { [tag |-> SpotGoldMarketOperationTsPlusQuoteMessageCode, body |-> one] : one \in CheckedSpotGoldMarketOperationTsPlusQuoteMessage }
        \cup { [tag |-> SpotGoldSnapshotMessageCode, body |-> one] : one \in CheckedSpotGoldSnapshotMessage }
        \cup { [tag |-> SpotGoldNegotiatedTradeMessageCode, body |-> one] : one \in CheckedSpotGoldNegotiatedTradeMessage }
        \cup { [tag |-> EmissionsQuoteMessageCode, body |-> one] : one \in CheckedEmissionsQuoteMessage }
        \cup { [tag |-> EmissionsOrderFilledMessageCode, body |-> one] : one \in CheckedEmissionsOrderFilledMessage }
        \cup { [tag |-> EmissionsOrderFilledPlusQuoteMessageCode, body |-> one] : one \in CheckedEmissionsOrderFilledPlusQuoteMessage }
        \cup { [tag |-> EmissionsMarketOperationTsPlusQuoteMessageCode, body |-> one] : one \in CheckedEmissionsMarketOperationTsPlusQuoteMessage }
        \cup { [tag |-> EmissionsSnapshotMessageCode, body |-> one] : one \in CheckedEmissionsSnapshotMessage }
        \cup { [tag |-> EmissionsNegotiatedTradeMessageCode, body |-> one] : one \in CheckedEmissionsNegotiatedTradeMessage }
        \cup { [tag |-> EmissionsDeterminationOfBasePriceMessageCode, body |-> one] : one \in CheckedEmissionsDeterminationOfBasePriceMessage }
        \cup { [tag |-> EmissionsAuctionResultsMessageCode, body |-> one] : one \in CheckedEmissionsAuctionResultsMessage }
        \cup { [tag |-> SpotGoldBatchDataMessageCode, body |-> one] : one \in CheckedSpotGoldBatchDataMessage }
        \cup { [tag |-> EmissionsBatchDataMessageCode, body |-> one] : one \in CheckedEmissionsBatchDataMessage }
        \cup { [tag |-> ExternalGoldSpotClosingPriceMessageCode, body |-> one] : one \in CheckedExternalGoldSpotClosingPriceMessage }
        \cup { [tag |-> SpotGoldMarketOperationTsMessageCode, body |-> one] : one \in CheckedSpotGoldMarketOperationTsMessage }
        \cup { [tag |-> SpotGoldIssueClosingMessageCode, body |-> one] : one \in CheckedSpotGoldIssueClosingMessage }
        \cup { [tag |-> SpotGoldMarketOperationScheduleMessageCode, body |-> one] : one \in CheckedSpotGoldMarketOperationScheduleMessage }
        \cup { [tag |-> EmissionsMarketOperationTsMessageCode, body |-> one] : one \in CheckedEmissionsMarketOperationTsMessage }
        \cup { [tag |-> EmissionsIssueClosingMessageCode, body |-> one] : one \in CheckedEmissionsIssueClosingMessage }
        \cup { [tag |-> EmissionsMarketOperationScheduleMessageCode, body |-> one] : one \in CheckedEmissionsMarketOperationScheduleMessage }
        \cup { [tag |-> SpotGoldRandomEndMessageCode, body |-> one] : one \in CheckedSpotGoldRandomEndMessage }
        \cup { [tag |-> SpotGoldRandomEndMessageCode2, body |-> one] : one \in CheckedSpotGoldRandomEndMessage }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ payload : Payload ]

EncodePacket(message) ==
    message.payload.tag
        \o EncodePayload(message.payload)

DecodePacket(bytes) ==
    LET trCode == ReadBytes(bytes, 5) IN IF ~trCode.ok THEN Fail ELSE
    LET payload == DecodePayload(trCode.value, trCode.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

ZeroPacket ==
    [ payload |-> ZeroPayload ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.payload = one] : one \in CheckedPayload }

(* A run of Packet, written one after another *)
RECURSIVE EncodePacketList(_)
EncodePacketList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodePacket(Head(messages)) \o EncodePacketList(Tail(messages))

(* As many Packet as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadPacketAll(_)
ReadPacketAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodePacket(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadPacketAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Packet of each kind, for the lists that carry them *)
OnePacket ==
    { [ZeroPacket EXCEPT !.payload = [tag |-> PollingDataMessageCode, body |-> ZeroPollingDataMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> KrxIndexMessageCode, body |-> ZeroKrxIndexMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> KrxEstimatedIndexMessageCode, body |-> ZeroKrxEstimatedIndexMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> GlobalIndexMessageCode, body |-> ZeroGlobalIndexMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> BondPrimeIndexMessageCode, body |-> ZeroBondPrimeIndexMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> BondKtbIndexMessageCode, body |-> ZeroBondKtbIndexMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> BondKtbIndexTermStructureMessageCode, body |-> ZeroBondKtbIndexTermStructureMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> BondIndexKrxMessageCode, body |-> ZeroBondIndexKrxMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SpotGoldQuoteMessageCode, body |-> ZeroSpotGoldQuoteMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SpotGoldOrderFilledMessageCode, body |-> ZeroSpotGoldOrderFilledMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SpotGoldOrderFilledPlusQuoteMessageCode, body |-> ZeroSpotGoldOrderFilledPlusQuoteMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SpotGoldMarketOperationTsPlusQuoteMessageCode, body |-> ZeroSpotGoldMarketOperationTsPlusQuoteMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SpotGoldSnapshotMessageCode, body |-> ZeroSpotGoldSnapshotMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SpotGoldNegotiatedTradeMessageCode, body |-> ZeroSpotGoldNegotiatedTradeMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> EmissionsQuoteMessageCode, body |-> ZeroEmissionsQuoteMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> EmissionsOrderFilledMessageCode, body |-> ZeroEmissionsOrderFilledMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> EmissionsOrderFilledPlusQuoteMessageCode, body |-> ZeroEmissionsOrderFilledPlusQuoteMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> EmissionsMarketOperationTsPlusQuoteMessageCode, body |-> ZeroEmissionsMarketOperationTsPlusQuoteMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> EmissionsSnapshotMessageCode, body |-> ZeroEmissionsSnapshotMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> EmissionsNegotiatedTradeMessageCode, body |-> ZeroEmissionsNegotiatedTradeMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> EmissionsDeterminationOfBasePriceMessageCode, body |-> ZeroEmissionsDeterminationOfBasePriceMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> EmissionsAuctionResultsMessageCode, body |-> ZeroEmissionsAuctionResultsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SpotGoldBatchDataMessageCode, body |-> ZeroSpotGoldBatchDataMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> EmissionsBatchDataMessageCode, body |-> ZeroEmissionsBatchDataMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> ExternalGoldSpotClosingPriceMessageCode, body |-> ZeroExternalGoldSpotClosingPriceMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SpotGoldMarketOperationTsMessageCode, body |-> ZeroSpotGoldMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SpotGoldIssueClosingMessageCode, body |-> ZeroSpotGoldIssueClosingMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SpotGoldMarketOperationScheduleMessageCode, body |-> ZeroSpotGoldMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> EmissionsMarketOperationTsMessageCode, body |-> ZeroEmissionsMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> EmissionsIssueClosingMessageCode, body |-> ZeroEmissionsIssueClosingMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> EmissionsMarketOperationScheduleMessageCode, body |-> ZeroEmissionsMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SpotGoldRandomEndMessageCode, body |-> ZeroSpotGoldRandomEndMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SpotGoldRandomEndMessageCode2, body |-> ZeroSpotGoldRandomEndMessage]] }

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

(* Every Polling Data Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPollingDataMessage ==
    \A message \in CheckedPollingDataMessage :
        LET read == DecodePollingDataMessage(EncodePollingDataMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Krx Index Message decodes back to what was encoded, and leaves nothing over *)
RoundTripKrxIndexMessage ==
    \A message \in CheckedKrxIndexMessage :
        LET read == DecodeKrxIndexMessage(EncodeKrxIndexMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Krx Estimated Index Message decodes back to what was encoded, and leaves nothing over *)
RoundTripKrxEstimatedIndexMessage ==
    \A message \in CheckedKrxEstimatedIndexMessage :
        LET read == DecodeKrxEstimatedIndexMessage(EncodeKrxEstimatedIndexMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Global Index Message decodes back to what was encoded, and leaves nothing over *)
RoundTripGlobalIndexMessage ==
    \A message \in CheckedGlobalIndexMessage :
        LET read == DecodeGlobalIndexMessage(EncodeGlobalIndexMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bond Prime Index Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBondPrimeIndexMessage ==
    \A message \in CheckedBondPrimeIndexMessage :
        LET read == DecodeBondPrimeIndexMessage(EncodeBondPrimeIndexMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bond Ktb Index Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBondKtbIndexMessage ==
    \A message \in CheckedBondKtbIndexMessage :
        LET read == DecodeBondKtbIndexMessage(EncodeBondKtbIndexMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bond Ktb Index Term Structure Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBondKtbIndexTermStructureMessage ==
    \A message \in CheckedBondKtbIndexTermStructureMessage :
        LET read == DecodeBondKtbIndexTermStructureMessage(EncodeBondKtbIndexTermStructureMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bond Index Krx Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBondIndexKrxMessage ==
    \A message \in CheckedBondIndexKrxMessage :
        LET read == DecodeBondIndexKrxMessage(EncodeBondIndexKrxMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Spot Gold Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSpotGoldQuoteMessage ==
    \A message \in CheckedSpotGoldQuoteMessage :
        LET read == DecodeSpotGoldQuoteMessage(EncodeSpotGoldQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Spot Gold Order Filled Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSpotGoldOrderFilledMessage ==
    \A message \in CheckedSpotGoldOrderFilledMessage :
        LET read == DecodeSpotGoldOrderFilledMessage(EncodeSpotGoldOrderFilledMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Spot Gold Order Filled Plus Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSpotGoldOrderFilledPlusQuoteMessage ==
    \A message \in CheckedSpotGoldOrderFilledPlusQuoteMessage :
        LET read == DecodeSpotGoldOrderFilledPlusQuoteMessage(EncodeSpotGoldOrderFilledPlusQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Spot Gold Market Operation Ts Plus Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSpotGoldMarketOperationTsPlusQuoteMessage ==
    \A message \in CheckedSpotGoldMarketOperationTsPlusQuoteMessage :
        LET read == DecodeSpotGoldMarketOperationTsPlusQuoteMessage(EncodeSpotGoldMarketOperationTsPlusQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Spot Gold Snapshot Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSpotGoldSnapshotMessage ==
    \A message \in CheckedSpotGoldSnapshotMessage :
        LET read == DecodeSpotGoldSnapshotMessage(EncodeSpotGoldSnapshotMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Spot Gold Negotiated Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSpotGoldNegotiatedTradeMessage ==
    \A message \in CheckedSpotGoldNegotiatedTradeMessage :
        LET read == DecodeSpotGoldNegotiatedTradeMessage(EncodeSpotGoldNegotiatedTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Emissions Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEmissionsQuoteMessage ==
    \A message \in CheckedEmissionsQuoteMessage :
        LET read == DecodeEmissionsQuoteMessage(EncodeEmissionsQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Emissions Order Filled Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEmissionsOrderFilledMessage ==
    \A message \in CheckedEmissionsOrderFilledMessage :
        LET read == DecodeEmissionsOrderFilledMessage(EncodeEmissionsOrderFilledMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Emissions Order Filled Plus Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEmissionsOrderFilledPlusQuoteMessage ==
    \A message \in CheckedEmissionsOrderFilledPlusQuoteMessage :
        LET read == DecodeEmissionsOrderFilledPlusQuoteMessage(EncodeEmissionsOrderFilledPlusQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Emissions Market Operation Ts Plus Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEmissionsMarketOperationTsPlusQuoteMessage ==
    \A message \in CheckedEmissionsMarketOperationTsPlusQuoteMessage :
        LET read == DecodeEmissionsMarketOperationTsPlusQuoteMessage(EncodeEmissionsMarketOperationTsPlusQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Emissions Snapshot Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEmissionsSnapshotMessage ==
    \A message \in CheckedEmissionsSnapshotMessage :
        LET read == DecodeEmissionsSnapshotMessage(EncodeEmissionsSnapshotMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Emissions Negotiated Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEmissionsNegotiatedTradeMessage ==
    \A message \in CheckedEmissionsNegotiatedTradeMessage :
        LET read == DecodeEmissionsNegotiatedTradeMessage(EncodeEmissionsNegotiatedTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Emissions Determination Of Base Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEmissionsDeterminationOfBasePriceMessage ==
    \A message \in CheckedEmissionsDeterminationOfBasePriceMessage :
        LET read == DecodeEmissionsDeterminationOfBasePriceMessage(EncodeEmissionsDeterminationOfBasePriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Emissions Auction Results Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEmissionsAuctionResultsMessage ==
    \A message \in CheckedEmissionsAuctionResultsMessage :
        LET read == DecodeEmissionsAuctionResultsMessage(EncodeEmissionsAuctionResultsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Spot Gold Batch Data Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSpotGoldBatchDataMessage ==
    \A message \in CheckedSpotGoldBatchDataMessage :
        LET read == DecodeSpotGoldBatchDataMessage(EncodeSpotGoldBatchDataMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Emissions Batch Data Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEmissionsBatchDataMessage ==
    \A message \in CheckedEmissionsBatchDataMessage :
        LET read == DecodeEmissionsBatchDataMessage(EncodeEmissionsBatchDataMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every External Gold Spot Closing Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExternalGoldSpotClosingPriceMessage ==
    \A message \in CheckedExternalGoldSpotClosingPriceMessage :
        LET read == DecodeExternalGoldSpotClosingPriceMessage(EncodeExternalGoldSpotClosingPriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Spot Gold Market Operation Ts Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSpotGoldMarketOperationTsMessage ==
    \A message \in CheckedSpotGoldMarketOperationTsMessage :
        LET read == DecodeSpotGoldMarketOperationTsMessage(EncodeSpotGoldMarketOperationTsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Spot Gold Issue Closing Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSpotGoldIssueClosingMessage ==
    \A message \in CheckedSpotGoldIssueClosingMessage :
        LET read == DecodeSpotGoldIssueClosingMessage(EncodeSpotGoldIssueClosingMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Spot Gold Market Operation Schedule Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSpotGoldMarketOperationScheduleMessage ==
    \A message \in CheckedSpotGoldMarketOperationScheduleMessage :
        LET read == DecodeSpotGoldMarketOperationScheduleMessage(EncodeSpotGoldMarketOperationScheduleMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Emissions Market Operation Ts Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEmissionsMarketOperationTsMessage ==
    \A message \in CheckedEmissionsMarketOperationTsMessage :
        LET read == DecodeEmissionsMarketOperationTsMessage(EncodeEmissionsMarketOperationTsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Emissions Issue Closing Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEmissionsIssueClosingMessage ==
    \A message \in CheckedEmissionsIssueClosingMessage :
        LET read == DecodeEmissionsIssueClosingMessage(EncodeEmissionsIssueClosingMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Emissions Market Operation Schedule Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEmissionsMarketOperationScheduleMessage ==
    \A message \in CheckedEmissionsMarketOperationScheduleMessage :
        LET read == DecodeEmissionsMarketOperationScheduleMessage(EncodeEmissionsMarketOperationScheduleMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Spot Gold Random End Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSpotGoldRandomEndMessage ==
    \A message \in CheckedSpotGoldRandomEndMessage :
        LET read == DecodeSpotGoldRandomEndMessage(EncodeSpotGoldRandomEndMessage(message))
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

(* A Payload is selected by the Tr Code it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET sent == EncodePayload(message)
            read == DecodePayload(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
