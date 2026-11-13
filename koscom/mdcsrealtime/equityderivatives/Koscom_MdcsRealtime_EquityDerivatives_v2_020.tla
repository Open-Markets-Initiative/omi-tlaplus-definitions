----------- MODULE Koscom_MdcsRealtime_EquityDerivatives_v2_020 ------------
(***************************************************************************)
(* Koscom Co., Ltd. MDCS Realtime Equity Derivatives v2.020                *)
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
      indexAccumulatedTradingValue         : Sample(12),
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
        \o message.indexAccumulatedTradingValue
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
    LET indexAccumulatedTradingValue == ReadBytes(accumulatedTradingVolume.rest, 12) IN IF ~indexAccumulatedTradingValue.ok THEN Fail ELSE
    LET filler4 == ReadBytes(indexAccumulatedTradingValue.rest, 4) IN IF ~filler4.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler4.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ indexId                              |-> indexId.value,
         isinCode                             |-> isinCode.value,
         calculationTime                      |-> calculationTime.value,
         index                                |-> index.value,
         indexChangeSignAgainstThePreviousDay |-> indexChangeSignAgainstThePreviousDay.value,
         indexChangeAgainstThePreviousDay     |-> indexChangeAgainstThePreviousDay.value,
         accumulatedTradingVolume             |-> accumulatedTradingVolume.value,
         indexAccumulatedTradingValue         |-> indexAccumulatedTradingValue.value,
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
      indexAccumulatedTradingValue         |-> [i \in 1 .. 12 |-> 0],
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
        \cup { [ZeroKrxIndexMessage EXCEPT !.indexAccumulatedTradingValue = one] : one \in Sample(12) }
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
      indexAccumulatedTradingValue         : Sample(12),
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
        \o message.indexAccumulatedTradingValue
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
    LET indexAccumulatedTradingValue == ReadBytes(accumulatedTradingVolume.rest, 12) IN IF ~indexAccumulatedTradingValue.ok THEN Fail ELSE
    LET filler4 == ReadBytes(indexAccumulatedTradingValue.rest, 4) IN IF ~filler4.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler4.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ indexId                              |-> indexId.value,
         isinCode                             |-> isinCode.value,
         calculationTime                      |-> calculationTime.value,
         index                                |-> index.value,
         indexChangeSignAgainstThePreviousDay |-> indexChangeSignAgainstThePreviousDay.value,
         indexChangeAgainstThePreviousDay     |-> indexChangeAgainstThePreviousDay.value,
         accumulatedTradingVolume             |-> accumulatedTradingVolume.value,
         indexAccumulatedTradingValue         |-> indexAccumulatedTradingValue.value,
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
      indexAccumulatedTradingValue         |-> [i \in 1 .. 12 |-> 0],
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
        \cup { [ZeroKrxEstimatedIndexMessage EXCEPT !.indexAccumulatedTradingValue = one] : one \in Sample(12) }
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
      currencyCode                         : Sample(3),
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
        \o message.currencyCode
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
    LET currencyCode == ReadBytes(indexChangeAgainstThePreviousDay.rest, 3) IN IF ~currencyCode.ok THEN Fail ELSE
    LET filler4 == ReadBytes(currencyCode.rest, 4) IN IF ~filler4.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler4.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ indexId                              |-> indexId.value,
         isinCode                             |-> isinCode.value,
         businessDate                         |-> businessDate.value,
         calculationTime                      |-> calculationTime.value,
         index                                |-> index.value,
         indexChangeSignAgainstThePreviousDay |-> indexChangeSignAgainstThePreviousDay.value,
         indexChangeAgainstThePreviousDay     |-> indexChangeAgainstThePreviousDay.value,
         currencyCode                         |-> currencyCode.value,
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
      currencyCode                         |-> [i \in 1 .. 3 |-> 0],
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
        \cup { [ZeroGlobalIndexMessage EXCEPT !.currencyCode = one] : one \in Sample(3) }
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
(* Equity Derivatives Underlying Snapshot Kospi Message: 131 bytes         *)
(***************************************************************************)

EquityDerivativesUnderlyingSnapshotKospiMessage ==
    [ boardId                           : Sample(2),
      sessionId                         : Sample(2),
      isinCode                          : Sample(12),
      priceChangeAgainstPreviousDay     : Sample(1),
      aPriceChangeAgainstThePreviousDay : Sample(11),
      tradingPrice                      : Sample(11),
      openingPrice                      : Sample(11),
      todaysHigh                        : Sample(11),
      todaysLow                         : Sample(11),
      closingPriceTypeCode              : Sample(1),
      accumulatedTradingVolume          : Sample(12),
      accumulatedTradingValue           : Sample(22),
      tradingHalt                       : Sample(1),
      theBestAsk                        : Sample(11),
      theBestBid                        : Sample(11),
      endKeyword                        : Sample(1) ]

EncodeEquityDerivativesUnderlyingSnapshotKospiMessage(message) ==
    message.boardId
        \o message.sessionId
        \o message.isinCode
        \o message.priceChangeAgainstPreviousDay
        \o message.aPriceChangeAgainstThePreviousDay
        \o message.tradingPrice
        \o message.openingPrice
        \o message.todaysHigh
        \o message.todaysLow
        \o message.closingPriceTypeCode
        \o message.accumulatedTradingVolume
        \o message.accumulatedTradingValue
        \o message.tradingHalt
        \o message.theBestAsk
        \o message.theBestBid
        \o message.endKeyword

DecodeEquityDerivativesUnderlyingSnapshotKospiMessage(bytes) ==
    LET boardId == ReadBytes(bytes, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(boardId.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(sessionId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET priceChangeAgainstPreviousDay == ReadBytes(isinCode.rest, 1) IN IF ~priceChangeAgainstPreviousDay.ok THEN Fail ELSE
    LET aPriceChangeAgainstThePreviousDay == ReadBytes(priceChangeAgainstPreviousDay.rest, 11) IN IF ~aPriceChangeAgainstThePreviousDay.ok THEN Fail ELSE
    LET tradingPrice == ReadBytes(aPriceChangeAgainstThePreviousDay.rest, 11) IN IF ~tradingPrice.ok THEN Fail ELSE
    LET openingPrice == ReadBytes(tradingPrice.rest, 11) IN IF ~openingPrice.ok THEN Fail ELSE
    LET todaysHigh == ReadBytes(openingPrice.rest, 11) IN IF ~todaysHigh.ok THEN Fail ELSE
    LET todaysLow == ReadBytes(todaysHigh.rest, 11) IN IF ~todaysLow.ok THEN Fail ELSE
    LET closingPriceTypeCode == ReadBytes(todaysLow.rest, 1) IN IF ~closingPriceTypeCode.ok THEN Fail ELSE
    LET accumulatedTradingVolume == ReadBytes(closingPriceTypeCode.rest, 12) IN IF ~accumulatedTradingVolume.ok THEN Fail ELSE
    LET accumulatedTradingValue == ReadBytes(accumulatedTradingVolume.rest, 22) IN IF ~accumulatedTradingValue.ok THEN Fail ELSE
    LET tradingHalt == ReadBytes(accumulatedTradingValue.rest, 1) IN IF ~tradingHalt.ok THEN Fail ELSE
    LET theBestAsk == ReadBytes(tradingHalt.rest, 11) IN IF ~theBestAsk.ok THEN Fail ELSE
    LET theBestBid == ReadBytes(theBestAsk.rest, 11) IN IF ~theBestBid.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(theBestBid.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ boardId                           |-> boardId.value,
         sessionId                         |-> sessionId.value,
         isinCode                          |-> isinCode.value,
         priceChangeAgainstPreviousDay     |-> priceChangeAgainstPreviousDay.value,
         aPriceChangeAgainstThePreviousDay |-> aPriceChangeAgainstThePreviousDay.value,
         tradingPrice                      |-> tradingPrice.value,
         openingPrice                      |-> openingPrice.value,
         todaysHigh                        |-> todaysHigh.value,
         todaysLow                         |-> todaysLow.value,
         closingPriceTypeCode              |-> closingPriceTypeCode.value,
         accumulatedTradingVolume          |-> accumulatedTradingVolume.value,
         accumulatedTradingValue           |-> accumulatedTradingValue.value,
         tradingHalt                       |-> tradingHalt.value,
         theBestAsk                        |-> theBestAsk.value,
         theBestBid                        |-> theBestBid.value,
         endKeyword                        |-> endKeyword.value ], endKeyword.rest)

ZeroEquityDerivativesUnderlyingSnapshotKospiMessage ==
    [ boardId                           |-> [i \in 1 .. 2 |-> 0],
      sessionId                         |-> [i \in 1 .. 2 |-> 0],
      isinCode                          |-> [i \in 1 .. 12 |-> 0],
      priceChangeAgainstPreviousDay     |-> [i \in 1 .. 1 |-> 0],
      aPriceChangeAgainstThePreviousDay |-> [i \in 1 .. 11 |-> 0],
      tradingPrice                      |-> [i \in 1 .. 11 |-> 0],
      openingPrice                      |-> [i \in 1 .. 11 |-> 0],
      todaysHigh                        |-> [i \in 1 .. 11 |-> 0],
      todaysLow                         |-> [i \in 1 .. 11 |-> 0],
      closingPriceTypeCode              |-> [i \in 1 .. 1 |-> 0],
      accumulatedTradingVolume          |-> [i \in 1 .. 12 |-> 0],
      accumulatedTradingValue           |-> [i \in 1 .. 22 |-> 0],
      tradingHalt                       |-> [i \in 1 .. 1 |-> 0],
      theBestAsk                        |-> [i \in 1 .. 11 |-> 0],
      theBestBid                        |-> [i \in 1 .. 11 |-> 0],
      endKeyword                        |-> [i \in 1 .. 1 |-> 0] ]

(* Equity Derivatives Underlying Snapshot Kospi Message at zero, then each field in turn at the values it is checked at *)
CheckedEquityDerivativesUnderlyingSnapshotKospiMessage ==
    { ZeroEquityDerivativesUnderlyingSnapshotKospiMessage }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKospiMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKospiMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKospiMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKospiMessage EXCEPT !.priceChangeAgainstPreviousDay = one] : one \in Sample(1) }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKospiMessage EXCEPT !.aPriceChangeAgainstThePreviousDay = one] : one \in Sample(11) }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKospiMessage EXCEPT !.tradingPrice = one] : one \in Sample(11) }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKospiMessage EXCEPT !.openingPrice = one] : one \in Sample(11) }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKospiMessage EXCEPT !.todaysHigh = one] : one \in Sample(11) }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKospiMessage EXCEPT !.todaysLow = one] : one \in Sample(11) }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKospiMessage EXCEPT !.closingPriceTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKospiMessage EXCEPT !.accumulatedTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKospiMessage EXCEPT !.accumulatedTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKospiMessage EXCEPT !.tradingHalt = one] : one \in Sample(1) }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKospiMessage EXCEPT !.theBestAsk = one] : one \in Sample(11) }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKospiMessage EXCEPT !.theBestBid = one] : one \in Sample(11) }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKospiMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Equity Derivatives Underlying Snapshot Kosdaq Message: 131 bytes        *)
(***************************************************************************)

EquityDerivativesUnderlyingSnapshotKosdaqMessage ==
    [ boardId                           : Sample(2),
      sessionId                         : Sample(2),
      isinCode                          : Sample(12),
      priceChangeAgainstPreviousDay     : Sample(1),
      aPriceChangeAgainstThePreviousDay : Sample(11),
      tradingPrice                      : Sample(11),
      openingPrice                      : Sample(11),
      todaysHigh                        : Sample(11),
      todaysLow                         : Sample(11),
      closingPriceTypeCode              : Sample(1),
      accumulatedTradingVolume          : Sample(12),
      accumulatedTradingValue           : Sample(22),
      tradingHalt                       : Sample(1),
      theBestAsk                        : Sample(11),
      theBestBid                        : Sample(11),
      endKeyword                        : Sample(1) ]

EncodeEquityDerivativesUnderlyingSnapshotKosdaqMessage(message) ==
    message.boardId
        \o message.sessionId
        \o message.isinCode
        \o message.priceChangeAgainstPreviousDay
        \o message.aPriceChangeAgainstThePreviousDay
        \o message.tradingPrice
        \o message.openingPrice
        \o message.todaysHigh
        \o message.todaysLow
        \o message.closingPriceTypeCode
        \o message.accumulatedTradingVolume
        \o message.accumulatedTradingValue
        \o message.tradingHalt
        \o message.theBestAsk
        \o message.theBestBid
        \o message.endKeyword

DecodeEquityDerivativesUnderlyingSnapshotKosdaqMessage(bytes) ==
    LET boardId == ReadBytes(bytes, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(boardId.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(sessionId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET priceChangeAgainstPreviousDay == ReadBytes(isinCode.rest, 1) IN IF ~priceChangeAgainstPreviousDay.ok THEN Fail ELSE
    LET aPriceChangeAgainstThePreviousDay == ReadBytes(priceChangeAgainstPreviousDay.rest, 11) IN IF ~aPriceChangeAgainstThePreviousDay.ok THEN Fail ELSE
    LET tradingPrice == ReadBytes(aPriceChangeAgainstThePreviousDay.rest, 11) IN IF ~tradingPrice.ok THEN Fail ELSE
    LET openingPrice == ReadBytes(tradingPrice.rest, 11) IN IF ~openingPrice.ok THEN Fail ELSE
    LET todaysHigh == ReadBytes(openingPrice.rest, 11) IN IF ~todaysHigh.ok THEN Fail ELSE
    LET todaysLow == ReadBytes(todaysHigh.rest, 11) IN IF ~todaysLow.ok THEN Fail ELSE
    LET closingPriceTypeCode == ReadBytes(todaysLow.rest, 1) IN IF ~closingPriceTypeCode.ok THEN Fail ELSE
    LET accumulatedTradingVolume == ReadBytes(closingPriceTypeCode.rest, 12) IN IF ~accumulatedTradingVolume.ok THEN Fail ELSE
    LET accumulatedTradingValue == ReadBytes(accumulatedTradingVolume.rest, 22) IN IF ~accumulatedTradingValue.ok THEN Fail ELSE
    LET tradingHalt == ReadBytes(accumulatedTradingValue.rest, 1) IN IF ~tradingHalt.ok THEN Fail ELSE
    LET theBestAsk == ReadBytes(tradingHalt.rest, 11) IN IF ~theBestAsk.ok THEN Fail ELSE
    LET theBestBid == ReadBytes(theBestAsk.rest, 11) IN IF ~theBestBid.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(theBestBid.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ boardId                           |-> boardId.value,
         sessionId                         |-> sessionId.value,
         isinCode                          |-> isinCode.value,
         priceChangeAgainstPreviousDay     |-> priceChangeAgainstPreviousDay.value,
         aPriceChangeAgainstThePreviousDay |-> aPriceChangeAgainstThePreviousDay.value,
         tradingPrice                      |-> tradingPrice.value,
         openingPrice                      |-> openingPrice.value,
         todaysHigh                        |-> todaysHigh.value,
         todaysLow                         |-> todaysLow.value,
         closingPriceTypeCode              |-> closingPriceTypeCode.value,
         accumulatedTradingVolume          |-> accumulatedTradingVolume.value,
         accumulatedTradingValue           |-> accumulatedTradingValue.value,
         tradingHalt                       |-> tradingHalt.value,
         theBestAsk                        |-> theBestAsk.value,
         theBestBid                        |-> theBestBid.value,
         endKeyword                        |-> endKeyword.value ], endKeyword.rest)

ZeroEquityDerivativesUnderlyingSnapshotKosdaqMessage ==
    [ boardId                           |-> [i \in 1 .. 2 |-> 0],
      sessionId                         |-> [i \in 1 .. 2 |-> 0],
      isinCode                          |-> [i \in 1 .. 12 |-> 0],
      priceChangeAgainstPreviousDay     |-> [i \in 1 .. 1 |-> 0],
      aPriceChangeAgainstThePreviousDay |-> [i \in 1 .. 11 |-> 0],
      tradingPrice                      |-> [i \in 1 .. 11 |-> 0],
      openingPrice                      |-> [i \in 1 .. 11 |-> 0],
      todaysHigh                        |-> [i \in 1 .. 11 |-> 0],
      todaysLow                         |-> [i \in 1 .. 11 |-> 0],
      closingPriceTypeCode              |-> [i \in 1 .. 1 |-> 0],
      accumulatedTradingVolume          |-> [i \in 1 .. 12 |-> 0],
      accumulatedTradingValue           |-> [i \in 1 .. 22 |-> 0],
      tradingHalt                       |-> [i \in 1 .. 1 |-> 0],
      theBestAsk                        |-> [i \in 1 .. 11 |-> 0],
      theBestBid                        |-> [i \in 1 .. 11 |-> 0],
      endKeyword                        |-> [i \in 1 .. 1 |-> 0] ]

(* Equity Derivatives Underlying Snapshot Kosdaq Message at zero, then each field in turn at the values it is checked at *)
CheckedEquityDerivativesUnderlyingSnapshotKosdaqMessage ==
    { ZeroEquityDerivativesUnderlyingSnapshotKosdaqMessage }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKosdaqMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKosdaqMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKosdaqMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKosdaqMessage EXCEPT !.priceChangeAgainstPreviousDay = one] : one \in Sample(1) }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKosdaqMessage EXCEPT !.aPriceChangeAgainstThePreviousDay = one] : one \in Sample(11) }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKosdaqMessage EXCEPT !.tradingPrice = one] : one \in Sample(11) }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKosdaqMessage EXCEPT !.openingPrice = one] : one \in Sample(11) }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKosdaqMessage EXCEPT !.todaysHigh = one] : one \in Sample(11) }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKosdaqMessage EXCEPT !.todaysLow = one] : one \in Sample(11) }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKosdaqMessage EXCEPT !.closingPriceTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKosdaqMessage EXCEPT !.accumulatedTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKosdaqMessage EXCEPT !.accumulatedTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKosdaqMessage EXCEPT !.tradingHalt = one] : one \in Sample(1) }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKosdaqMessage EXCEPT !.theBestAsk = one] : one \in Sample(11) }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKosdaqMessage EXCEPT !.theBestBid = one] : one \in Sample(11) }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKosdaqMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Equity Derivatives Underlying Snapshot Kospi Mm Lp Included Message:    *)
(* 131 bytes                                                               *)
(***************************************************************************)

EquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessage ==
    [ boardId                           : Sample(2),
      sessionId                         : Sample(2),
      isinCode                          : Sample(12),
      priceChangeAgainstPreviousDay     : Sample(1),
      aPriceChangeAgainstThePreviousDay : Sample(11),
      tradingPrice                      : Sample(11),
      openingPrice                      : Sample(11),
      todaysHigh                        : Sample(11),
      todaysLow                         : Sample(11),
      closingPriceTypeCode              : Sample(1),
      accumulatedTradingVolume          : Sample(12),
      accumulatedTradingValue           : Sample(22),
      tradingHalt                       : Sample(1),
      theBestAsk                        : Sample(11),
      theBestBid                        : Sample(11),
      endKeyword                        : Sample(1) ]

EncodeEquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessage(message) ==
    message.boardId
        \o message.sessionId
        \o message.isinCode
        \o message.priceChangeAgainstPreviousDay
        \o message.aPriceChangeAgainstThePreviousDay
        \o message.tradingPrice
        \o message.openingPrice
        \o message.todaysHigh
        \o message.todaysLow
        \o message.closingPriceTypeCode
        \o message.accumulatedTradingVolume
        \o message.accumulatedTradingValue
        \o message.tradingHalt
        \o message.theBestAsk
        \o message.theBestBid
        \o message.endKeyword

DecodeEquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessage(bytes) ==
    LET boardId == ReadBytes(bytes, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(boardId.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(sessionId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET priceChangeAgainstPreviousDay == ReadBytes(isinCode.rest, 1) IN IF ~priceChangeAgainstPreviousDay.ok THEN Fail ELSE
    LET aPriceChangeAgainstThePreviousDay == ReadBytes(priceChangeAgainstPreviousDay.rest, 11) IN IF ~aPriceChangeAgainstThePreviousDay.ok THEN Fail ELSE
    LET tradingPrice == ReadBytes(aPriceChangeAgainstThePreviousDay.rest, 11) IN IF ~tradingPrice.ok THEN Fail ELSE
    LET openingPrice == ReadBytes(tradingPrice.rest, 11) IN IF ~openingPrice.ok THEN Fail ELSE
    LET todaysHigh == ReadBytes(openingPrice.rest, 11) IN IF ~todaysHigh.ok THEN Fail ELSE
    LET todaysLow == ReadBytes(todaysHigh.rest, 11) IN IF ~todaysLow.ok THEN Fail ELSE
    LET closingPriceTypeCode == ReadBytes(todaysLow.rest, 1) IN IF ~closingPriceTypeCode.ok THEN Fail ELSE
    LET accumulatedTradingVolume == ReadBytes(closingPriceTypeCode.rest, 12) IN IF ~accumulatedTradingVolume.ok THEN Fail ELSE
    LET accumulatedTradingValue == ReadBytes(accumulatedTradingVolume.rest, 22) IN IF ~accumulatedTradingValue.ok THEN Fail ELSE
    LET tradingHalt == ReadBytes(accumulatedTradingValue.rest, 1) IN IF ~tradingHalt.ok THEN Fail ELSE
    LET theBestAsk == ReadBytes(tradingHalt.rest, 11) IN IF ~theBestAsk.ok THEN Fail ELSE
    LET theBestBid == ReadBytes(theBestAsk.rest, 11) IN IF ~theBestBid.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(theBestBid.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ boardId                           |-> boardId.value,
         sessionId                         |-> sessionId.value,
         isinCode                          |-> isinCode.value,
         priceChangeAgainstPreviousDay     |-> priceChangeAgainstPreviousDay.value,
         aPriceChangeAgainstThePreviousDay |-> aPriceChangeAgainstThePreviousDay.value,
         tradingPrice                      |-> tradingPrice.value,
         openingPrice                      |-> openingPrice.value,
         todaysHigh                        |-> todaysHigh.value,
         todaysLow                         |-> todaysLow.value,
         closingPriceTypeCode              |-> closingPriceTypeCode.value,
         accumulatedTradingVolume          |-> accumulatedTradingVolume.value,
         accumulatedTradingValue           |-> accumulatedTradingValue.value,
         tradingHalt                       |-> tradingHalt.value,
         theBestAsk                        |-> theBestAsk.value,
         theBestBid                        |-> theBestBid.value,
         endKeyword                        |-> endKeyword.value ], endKeyword.rest)

ZeroEquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessage ==
    [ boardId                           |-> [i \in 1 .. 2 |-> 0],
      sessionId                         |-> [i \in 1 .. 2 |-> 0],
      isinCode                          |-> [i \in 1 .. 12 |-> 0],
      priceChangeAgainstPreviousDay     |-> [i \in 1 .. 1 |-> 0],
      aPriceChangeAgainstThePreviousDay |-> [i \in 1 .. 11 |-> 0],
      tradingPrice                      |-> [i \in 1 .. 11 |-> 0],
      openingPrice                      |-> [i \in 1 .. 11 |-> 0],
      todaysHigh                        |-> [i \in 1 .. 11 |-> 0],
      todaysLow                         |-> [i \in 1 .. 11 |-> 0],
      closingPriceTypeCode              |-> [i \in 1 .. 1 |-> 0],
      accumulatedTradingVolume          |-> [i \in 1 .. 12 |-> 0],
      accumulatedTradingValue           |-> [i \in 1 .. 22 |-> 0],
      tradingHalt                       |-> [i \in 1 .. 1 |-> 0],
      theBestAsk                        |-> [i \in 1 .. 11 |-> 0],
      theBestBid                        |-> [i \in 1 .. 11 |-> 0],
      endKeyword                        |-> [i \in 1 .. 1 |-> 0] ]

(* Equity Derivatives Underlying Snapshot Kospi Mm Lp Included Message at zero, then each field in turn at the values it is checked at *)
CheckedEquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessage ==
    { ZeroEquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessage }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessage EXCEPT !.priceChangeAgainstPreviousDay = one] : one \in Sample(1) }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessage EXCEPT !.aPriceChangeAgainstThePreviousDay = one] : one \in Sample(11) }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessage EXCEPT !.tradingPrice = one] : one \in Sample(11) }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessage EXCEPT !.openingPrice = one] : one \in Sample(11) }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessage EXCEPT !.todaysHigh = one] : one \in Sample(11) }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessage EXCEPT !.todaysLow = one] : one \in Sample(11) }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessage EXCEPT !.closingPriceTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessage EXCEPT !.accumulatedTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessage EXCEPT !.accumulatedTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessage EXCEPT !.tradingHalt = one] : one \in Sample(1) }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessage EXCEPT !.theBestAsk = one] : one \in Sample(11) }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessage EXCEPT !.theBestBid = one] : one \in Sample(11) }
        \cup { [ZeroEquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Securities Equities Batch Data Message: 627 bytes                       *)
(***************************************************************************)

SecuritiesEquitiesBatchDataMessage ==
    [ messageSequenceNumber                                  : Sample(8),
      totalNumberOfInstrumentsOfTheContract                  : Sample(6),
      businessDate                                           : Sample(8),
      isinCode                                               : Sample(12),
      aDesignatedNumberForAnIssue                            : Sample(6),
      abbreviatedIssueCode                                   : Sample(9),
      abbreviatedIssueName                                   : Sample(40),
      abbreviatedIssueNameInEn                               : Sample(40),
      groupNumber                                            : Sample(5),
      marketOperationProductId                               : Sample(3),
      securityGroupId                                        : Sample(2),
      discreteTimeTrading                                    : Sample(1),
      rightsTypeCode                                         : Sample(2),
      parValueTypeCode                                       : Sample(2),
      anIssueOfWhichBasePriceIsSettledWithATodaysSinglePrice : Sample(1),
      reevaluationReasonCode                                 : Sample(2),
      basePriceChange                                        : Sample(1),
      randomEndTriggerCode                                   : Sample(1),
      marketAlert                                            : Sample(1),
      marketAlertTypeCode                                    : Sample(2),
      koreaCorporateGovernanceStockPriceIndexKogi            : Sample(1),
      issueForAdministration                                 : Sample(1),
      unfaithfulDisclosure                                   : Sample(1),
      backDoorListing                                        : Sample(1),
      tradingHalt                                            : Sample(1),
      industryId                                             : Sample(10),
      smallMediumSizedBusiness                               : Sample(1),
      sectionTypeCode                                        : Sample(1),
      investmentInstitutionTypeCode                          : Sample(1),
      basePrice                                              : Sample(11),
      yesterdaysClosingPriceTypeCode                         : Sample(1),
      yesterdaysClosingPrice                                 : Sample(11),
      yesterdaysAccumulatedTradingAmount                     : Sample(12),
      yesterdaysAccumulatedTradingValue                      : Sample(22),
      upperLimitPrice                                        : Sample(11),
      lowerLimitPrice                                        : Sample(11),
      substitutePriceOfSecurities                            : Sample(11),
      parValue                                               : Sample(11),
      issuingPrice                                           : Sample(11),
      listingDate                                            : Sample(8),
      numberOfListedShares                                   : Sample(16),
      liquidationTrade                                       : Sample(1),
      theEstablishmentDate                                   : Sample(8),
      maturityDate                                           : Sample(8),
      exercisingPeriod                                       : Sample(8),
      expirationDateForRight                                 : Sample(8),
      exercisePriceOfElwOrBw                                 : Sample(13),
      capital                                                : Sample(22),
      creditOrderPossibillity                                : Sample(1),
      limitOrderPermissionTypeCode                           : Sample(5),
      marketPriceOrderPermissionTypeCode                     : Sample(5),
      conditionedOrderPermissionTypeCode                     : Sample(5),
      bestFavorableOrderPermissionTypeCode                   : Sample(5),
      firstBestOrderPermissionTypeCode                       : Sample(5),
      midPriceOrderPermissionTypeCode                        : Sample(5),
      stopLimitPriceOrderPermissionTypeCode                  : Sample(5),
      capitalIncreaseTypeCode                                : Sample(2),
      otherStockTypeCode                                     : Sample(1),
      nationalStock                                          : Sample(1),
      appraisedPrice                                         : Sample(11),
      lowestOrderPrice                                       : Sample(11),
      highestOrderPrice                                      : Sample(11),
      unitOfVolumeInMainBoard                                : Sample(11),
      lotSizeAfterHoursTrading                               : Sample(11),
      reiTsTypeCode                                          : Sample(1),
      targetStockIsinCode                                    : Sample(12),
      currencyIsoCode                                        : Sample(3),
      countryCode                                            : Sample(3),
      marketMakingPossibility                                : Sample(1),
      closingPriceTradingPossibilityInTheAfterHours          : Sample(1),
      closingPriceTradingInThePreOpeningMarket               : Sample(1),
      blockTradingInThePreOpeningMarket                      : Sample(1),
      basketTradingInThePreOpeningMarket                     : Sample(1),
      announcementOfEstimatedTradingPrice                    : Sample(1),
      shortSelling                                           : Sample(1),
      etfTrackingDifference                                  : Sample(13),
      regs                                                   : Sample(1),
      spac                                                   : Sample(1),
      taxTypeCode                                            : Sample(1),
      appraisalRatioOfSubstitutePrice                        : Sample(13),
      investmentCautionIssue                                 : Sample(1),
      delistingDate                                          : Sample(8),
      shortTermOverheatIssueTypeCode                         : Sample(1),
      etfReplicationMethodsTypeCode                          : Sample(1),
      expirationDate                                         : Sample(8),
      distributionTypeCode                                   : Sample(2),
      calculationOfRedemptionPriceStartDate                  : Sample(8),
      calculationOfRedemptionPriceEndDate                    : Sample(8),
      etpProductTypeCode                                     : Sample(1),
      indexCalculationInstitutionTypeCode                    : Sample(2),
      indexMarketClassificationId                            : Sample(6),
      indexSequenceNumber                                    : Sample(3),
      trackingIndexLeverageInverseTypeCode                   : Sample(2),
      referenceIndexLeverageInverseTypeCode                  : Sample(2),
      indexAssetClassificationId1                            : Sample(6),
      indexAssetClassificationId2                            : Sample(6),
      ipoUnderwriterMemberNumber                             : Sample(5),
      lpOrder                                                : Sample(1),
      lowLiquidity                                           : Sample(1),
      abnormalRise                                           : Sample(1),
      upperLimitQuantity                                     : Sample(23),
      investmentPrecautionIssue                              : Sample(1),
      preferredStocksWithLesserShares                        : Sample(1),
      spacMerger                                             : Sample(1),
      segmentTypeCode                                        : Sample(1),
      afterMarketPossibility                                 : Sample(1),
      preMarketPossibility                                   : Sample(1),
      endKeyword                                             : Sample(1) ]

EncodeSecuritiesEquitiesBatchDataMessage(message) ==
    message.messageSequenceNumber
        \o message.totalNumberOfInstrumentsOfTheContract
        \o message.businessDate
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.abbreviatedIssueCode
        \o message.abbreviatedIssueName
        \o message.abbreviatedIssueNameInEn
        \o message.groupNumber
        \o message.marketOperationProductId
        \o message.securityGroupId
        \o message.discreteTimeTrading
        \o message.rightsTypeCode
        \o message.parValueTypeCode
        \o message.anIssueOfWhichBasePriceIsSettledWithATodaysSinglePrice
        \o message.reevaluationReasonCode
        \o message.basePriceChange
        \o message.randomEndTriggerCode
        \o message.marketAlert
        \o message.marketAlertTypeCode
        \o message.koreaCorporateGovernanceStockPriceIndexKogi
        \o message.issueForAdministration
        \o message.unfaithfulDisclosure
        \o message.backDoorListing
        \o message.tradingHalt
        \o message.industryId
        \o message.smallMediumSizedBusiness
        \o message.sectionTypeCode
        \o message.investmentInstitutionTypeCode
        \o message.basePrice
        \o message.yesterdaysClosingPriceTypeCode
        \o message.yesterdaysClosingPrice
        \o message.yesterdaysAccumulatedTradingAmount
        \o message.yesterdaysAccumulatedTradingValue
        \o message.upperLimitPrice
        \o message.lowerLimitPrice
        \o message.substitutePriceOfSecurities
        \o message.parValue
        \o message.issuingPrice
        \o message.listingDate
        \o message.numberOfListedShares
        \o message.liquidationTrade
        \o message.theEstablishmentDate
        \o message.maturityDate
        \o message.exercisingPeriod
        \o message.expirationDateForRight
        \o message.exercisePriceOfElwOrBw
        \o message.capital
        \o message.creditOrderPossibillity
        \o message.limitOrderPermissionTypeCode
        \o message.marketPriceOrderPermissionTypeCode
        \o message.conditionedOrderPermissionTypeCode
        \o message.bestFavorableOrderPermissionTypeCode
        \o message.firstBestOrderPermissionTypeCode
        \o message.midPriceOrderPermissionTypeCode
        \o message.stopLimitPriceOrderPermissionTypeCode
        \o message.capitalIncreaseTypeCode
        \o message.otherStockTypeCode
        \o message.nationalStock
        \o message.appraisedPrice
        \o message.lowestOrderPrice
        \o message.highestOrderPrice
        \o message.unitOfVolumeInMainBoard
        \o message.lotSizeAfterHoursTrading
        \o message.reiTsTypeCode
        \o message.targetStockIsinCode
        \o message.currencyIsoCode
        \o message.countryCode
        \o message.marketMakingPossibility
        \o message.closingPriceTradingPossibilityInTheAfterHours
        \o message.closingPriceTradingInThePreOpeningMarket
        \o message.blockTradingInThePreOpeningMarket
        \o message.basketTradingInThePreOpeningMarket
        \o message.announcementOfEstimatedTradingPrice
        \o message.shortSelling
        \o message.etfTrackingDifference
        \o message.regs
        \o message.spac
        \o message.taxTypeCode
        \o message.appraisalRatioOfSubstitutePrice
        \o message.investmentCautionIssue
        \o message.delistingDate
        \o message.shortTermOverheatIssueTypeCode
        \o message.etfReplicationMethodsTypeCode
        \o message.expirationDate
        \o message.distributionTypeCode
        \o message.calculationOfRedemptionPriceStartDate
        \o message.calculationOfRedemptionPriceEndDate
        \o message.etpProductTypeCode
        \o message.indexCalculationInstitutionTypeCode
        \o message.indexMarketClassificationId
        \o message.indexSequenceNumber
        \o message.trackingIndexLeverageInverseTypeCode
        \o message.referenceIndexLeverageInverseTypeCode
        \o message.indexAssetClassificationId1
        \o message.indexAssetClassificationId2
        \o message.ipoUnderwriterMemberNumber
        \o message.lpOrder
        \o message.lowLiquidity
        \o message.abnormalRise
        \o message.upperLimitQuantity
        \o message.investmentPrecautionIssue
        \o message.preferredStocksWithLesserShares
        \o message.spacMerger
        \o message.segmentTypeCode
        \o message.afterMarketPossibility
        \o message.preMarketPossibility
        \o message.endKeyword

DecodeSecuritiesEquitiesBatchDataMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET totalNumberOfInstrumentsOfTheContract == ReadBytes(messageSequenceNumber.rest, 6) IN IF ~totalNumberOfInstrumentsOfTheContract.ok THEN Fail ELSE
    LET businessDate == ReadBytes(totalNumberOfInstrumentsOfTheContract.rest, 8) IN IF ~businessDate.ok THEN Fail ELSE
    LET isinCode == ReadBytes(businessDate.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET abbreviatedIssueCode == ReadBytes(aDesignatedNumberForAnIssue.rest, 9) IN IF ~abbreviatedIssueCode.ok THEN Fail ELSE
    LET abbreviatedIssueName == ReadBytes(abbreviatedIssueCode.rest, 40) IN IF ~abbreviatedIssueName.ok THEN Fail ELSE
    LET abbreviatedIssueNameInEn == ReadBytes(abbreviatedIssueName.rest, 40) IN IF ~abbreviatedIssueNameInEn.ok THEN Fail ELSE
    LET groupNumber == ReadBytes(abbreviatedIssueNameInEn.rest, 5) IN IF ~groupNumber.ok THEN Fail ELSE
    LET marketOperationProductId == ReadBytes(groupNumber.rest, 3) IN IF ~marketOperationProductId.ok THEN Fail ELSE
    LET securityGroupId == ReadBytes(marketOperationProductId.rest, 2) IN IF ~securityGroupId.ok THEN Fail ELSE
    LET discreteTimeTrading == ReadBytes(securityGroupId.rest, 1) IN IF ~discreteTimeTrading.ok THEN Fail ELSE
    LET rightsTypeCode == ReadBytes(discreteTimeTrading.rest, 2) IN IF ~rightsTypeCode.ok THEN Fail ELSE
    LET parValueTypeCode == ReadBytes(rightsTypeCode.rest, 2) IN IF ~parValueTypeCode.ok THEN Fail ELSE
    LET anIssueOfWhichBasePriceIsSettledWithATodaysSinglePrice == ReadBytes(parValueTypeCode.rest, 1) IN IF ~anIssueOfWhichBasePriceIsSettledWithATodaysSinglePrice.ok THEN Fail ELSE
    LET reevaluationReasonCode == ReadBytes(anIssueOfWhichBasePriceIsSettledWithATodaysSinglePrice.rest, 2) IN IF ~reevaluationReasonCode.ok THEN Fail ELSE
    LET basePriceChange == ReadBytes(reevaluationReasonCode.rest, 1) IN IF ~basePriceChange.ok THEN Fail ELSE
    LET randomEndTriggerCode == ReadBytes(basePriceChange.rest, 1) IN IF ~randomEndTriggerCode.ok THEN Fail ELSE
    LET marketAlert == ReadBytes(randomEndTriggerCode.rest, 1) IN IF ~marketAlert.ok THEN Fail ELSE
    LET marketAlertTypeCode == ReadBytes(marketAlert.rest, 2) IN IF ~marketAlertTypeCode.ok THEN Fail ELSE
    LET koreaCorporateGovernanceStockPriceIndexKogi == ReadBytes(marketAlertTypeCode.rest, 1) IN IF ~koreaCorporateGovernanceStockPriceIndexKogi.ok THEN Fail ELSE
    LET issueForAdministration == ReadBytes(koreaCorporateGovernanceStockPriceIndexKogi.rest, 1) IN IF ~issueForAdministration.ok THEN Fail ELSE
    LET unfaithfulDisclosure == ReadBytes(issueForAdministration.rest, 1) IN IF ~unfaithfulDisclosure.ok THEN Fail ELSE
    LET backDoorListing == ReadBytes(unfaithfulDisclosure.rest, 1) IN IF ~backDoorListing.ok THEN Fail ELSE
    LET tradingHalt == ReadBytes(backDoorListing.rest, 1) IN IF ~tradingHalt.ok THEN Fail ELSE
    LET industryId == ReadBytes(tradingHalt.rest, 10) IN IF ~industryId.ok THEN Fail ELSE
    LET smallMediumSizedBusiness == ReadBytes(industryId.rest, 1) IN IF ~smallMediumSizedBusiness.ok THEN Fail ELSE
    LET sectionTypeCode == ReadBytes(smallMediumSizedBusiness.rest, 1) IN IF ~sectionTypeCode.ok THEN Fail ELSE
    LET investmentInstitutionTypeCode == ReadBytes(sectionTypeCode.rest, 1) IN IF ~investmentInstitutionTypeCode.ok THEN Fail ELSE
    LET basePrice == ReadBytes(investmentInstitutionTypeCode.rest, 11) IN IF ~basePrice.ok THEN Fail ELSE
    LET yesterdaysClosingPriceTypeCode == ReadBytes(basePrice.rest, 1) IN IF ~yesterdaysClosingPriceTypeCode.ok THEN Fail ELSE
    LET yesterdaysClosingPrice == ReadBytes(yesterdaysClosingPriceTypeCode.rest, 11) IN IF ~yesterdaysClosingPrice.ok THEN Fail ELSE
    LET yesterdaysAccumulatedTradingAmount == ReadBytes(yesterdaysClosingPrice.rest, 12) IN IF ~yesterdaysAccumulatedTradingAmount.ok THEN Fail ELSE
    LET yesterdaysAccumulatedTradingValue == ReadBytes(yesterdaysAccumulatedTradingAmount.rest, 22) IN IF ~yesterdaysAccumulatedTradingValue.ok THEN Fail ELSE
    LET upperLimitPrice == ReadBytes(yesterdaysAccumulatedTradingValue.rest, 11) IN IF ~upperLimitPrice.ok THEN Fail ELSE
    LET lowerLimitPrice == ReadBytes(upperLimitPrice.rest, 11) IN IF ~lowerLimitPrice.ok THEN Fail ELSE
    LET substitutePriceOfSecurities == ReadBytes(lowerLimitPrice.rest, 11) IN IF ~substitutePriceOfSecurities.ok THEN Fail ELSE
    LET parValue == ReadBytes(substitutePriceOfSecurities.rest, 11) IN IF ~parValue.ok THEN Fail ELSE
    LET issuingPrice == ReadBytes(parValue.rest, 11) IN IF ~issuingPrice.ok THEN Fail ELSE
    LET listingDate == ReadBytes(issuingPrice.rest, 8) IN IF ~listingDate.ok THEN Fail ELSE
    LET numberOfListedShares == ReadBytes(listingDate.rest, 16) IN IF ~numberOfListedShares.ok THEN Fail ELSE
    LET liquidationTrade == ReadBytes(numberOfListedShares.rest, 1) IN IF ~liquidationTrade.ok THEN Fail ELSE
    LET theEstablishmentDate == ReadBytes(liquidationTrade.rest, 8) IN IF ~theEstablishmentDate.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(theEstablishmentDate.rest, 8) IN IF ~maturityDate.ok THEN Fail ELSE
    LET exercisingPeriod == ReadBytes(maturityDate.rest, 8) IN IF ~exercisingPeriod.ok THEN Fail ELSE
    LET expirationDateForRight == ReadBytes(exercisingPeriod.rest, 8) IN IF ~expirationDateForRight.ok THEN Fail ELSE
    LET exercisePriceOfElwOrBw == ReadBytes(expirationDateForRight.rest, 13) IN IF ~exercisePriceOfElwOrBw.ok THEN Fail ELSE
    LET capital == ReadBytes(exercisePriceOfElwOrBw.rest, 22) IN IF ~capital.ok THEN Fail ELSE
    LET creditOrderPossibillity == ReadBytes(capital.rest, 1) IN IF ~creditOrderPossibillity.ok THEN Fail ELSE
    LET limitOrderPermissionTypeCode == ReadBytes(creditOrderPossibillity.rest, 5) IN IF ~limitOrderPermissionTypeCode.ok THEN Fail ELSE
    LET marketPriceOrderPermissionTypeCode == ReadBytes(limitOrderPermissionTypeCode.rest, 5) IN IF ~marketPriceOrderPermissionTypeCode.ok THEN Fail ELSE
    LET conditionedOrderPermissionTypeCode == ReadBytes(marketPriceOrderPermissionTypeCode.rest, 5) IN IF ~conditionedOrderPermissionTypeCode.ok THEN Fail ELSE
    LET bestFavorableOrderPermissionTypeCode == ReadBytes(conditionedOrderPermissionTypeCode.rest, 5) IN IF ~bestFavorableOrderPermissionTypeCode.ok THEN Fail ELSE
    LET firstBestOrderPermissionTypeCode == ReadBytes(bestFavorableOrderPermissionTypeCode.rest, 5) IN IF ~firstBestOrderPermissionTypeCode.ok THEN Fail ELSE
    LET midPriceOrderPermissionTypeCode == ReadBytes(firstBestOrderPermissionTypeCode.rest, 5) IN IF ~midPriceOrderPermissionTypeCode.ok THEN Fail ELSE
    LET stopLimitPriceOrderPermissionTypeCode == ReadBytes(midPriceOrderPermissionTypeCode.rest, 5) IN IF ~stopLimitPriceOrderPermissionTypeCode.ok THEN Fail ELSE
    LET capitalIncreaseTypeCode == ReadBytes(stopLimitPriceOrderPermissionTypeCode.rest, 2) IN IF ~capitalIncreaseTypeCode.ok THEN Fail ELSE
    LET otherStockTypeCode == ReadBytes(capitalIncreaseTypeCode.rest, 1) IN IF ~otherStockTypeCode.ok THEN Fail ELSE
    LET nationalStock == ReadBytes(otherStockTypeCode.rest, 1) IN IF ~nationalStock.ok THEN Fail ELSE
    LET appraisedPrice == ReadBytes(nationalStock.rest, 11) IN IF ~appraisedPrice.ok THEN Fail ELSE
    LET lowestOrderPrice == ReadBytes(appraisedPrice.rest, 11) IN IF ~lowestOrderPrice.ok THEN Fail ELSE
    LET highestOrderPrice == ReadBytes(lowestOrderPrice.rest, 11) IN IF ~highestOrderPrice.ok THEN Fail ELSE
    LET unitOfVolumeInMainBoard == ReadBytes(highestOrderPrice.rest, 11) IN IF ~unitOfVolumeInMainBoard.ok THEN Fail ELSE
    LET lotSizeAfterHoursTrading == ReadBytes(unitOfVolumeInMainBoard.rest, 11) IN IF ~lotSizeAfterHoursTrading.ok THEN Fail ELSE
    LET reiTsTypeCode == ReadBytes(lotSizeAfterHoursTrading.rest, 1) IN IF ~reiTsTypeCode.ok THEN Fail ELSE
    LET targetStockIsinCode == ReadBytes(reiTsTypeCode.rest, 12) IN IF ~targetStockIsinCode.ok THEN Fail ELSE
    LET currencyIsoCode == ReadBytes(targetStockIsinCode.rest, 3) IN IF ~currencyIsoCode.ok THEN Fail ELSE
    LET countryCode == ReadBytes(currencyIsoCode.rest, 3) IN IF ~countryCode.ok THEN Fail ELSE
    LET marketMakingPossibility == ReadBytes(countryCode.rest, 1) IN IF ~marketMakingPossibility.ok THEN Fail ELSE
    LET closingPriceTradingPossibilityInTheAfterHours == ReadBytes(marketMakingPossibility.rest, 1) IN IF ~closingPriceTradingPossibilityInTheAfterHours.ok THEN Fail ELSE
    LET closingPriceTradingInThePreOpeningMarket == ReadBytes(closingPriceTradingPossibilityInTheAfterHours.rest, 1) IN IF ~closingPriceTradingInThePreOpeningMarket.ok THEN Fail ELSE
    LET blockTradingInThePreOpeningMarket == ReadBytes(closingPriceTradingInThePreOpeningMarket.rest, 1) IN IF ~blockTradingInThePreOpeningMarket.ok THEN Fail ELSE
    LET basketTradingInThePreOpeningMarket == ReadBytes(blockTradingInThePreOpeningMarket.rest, 1) IN IF ~basketTradingInThePreOpeningMarket.ok THEN Fail ELSE
    LET announcementOfEstimatedTradingPrice == ReadBytes(basketTradingInThePreOpeningMarket.rest, 1) IN IF ~announcementOfEstimatedTradingPrice.ok THEN Fail ELSE
    LET shortSelling == ReadBytes(announcementOfEstimatedTradingPrice.rest, 1) IN IF ~shortSelling.ok THEN Fail ELSE
    LET etfTrackingDifference == ReadBytes(shortSelling.rest, 13) IN IF ~etfTrackingDifference.ok THEN Fail ELSE
    LET regs == ReadBytes(etfTrackingDifference.rest, 1) IN IF ~regs.ok THEN Fail ELSE
    LET spac == ReadBytes(regs.rest, 1) IN IF ~spac.ok THEN Fail ELSE
    LET taxTypeCode == ReadBytes(spac.rest, 1) IN IF ~taxTypeCode.ok THEN Fail ELSE
    LET appraisalRatioOfSubstitutePrice == ReadBytes(taxTypeCode.rest, 13) IN IF ~appraisalRatioOfSubstitutePrice.ok THEN Fail ELSE
    LET investmentCautionIssue == ReadBytes(appraisalRatioOfSubstitutePrice.rest, 1) IN IF ~investmentCautionIssue.ok THEN Fail ELSE
    LET delistingDate == ReadBytes(investmentCautionIssue.rest, 8) IN IF ~delistingDate.ok THEN Fail ELSE
    LET shortTermOverheatIssueTypeCode == ReadBytes(delistingDate.rest, 1) IN IF ~shortTermOverheatIssueTypeCode.ok THEN Fail ELSE
    LET etfReplicationMethodsTypeCode == ReadBytes(shortTermOverheatIssueTypeCode.rest, 1) IN IF ~etfReplicationMethodsTypeCode.ok THEN Fail ELSE
    LET expirationDate == ReadBytes(etfReplicationMethodsTypeCode.rest, 8) IN IF ~expirationDate.ok THEN Fail ELSE
    LET distributionTypeCode == ReadBytes(expirationDate.rest, 2) IN IF ~distributionTypeCode.ok THEN Fail ELSE
    LET calculationOfRedemptionPriceStartDate == ReadBytes(distributionTypeCode.rest, 8) IN IF ~calculationOfRedemptionPriceStartDate.ok THEN Fail ELSE
    LET calculationOfRedemptionPriceEndDate == ReadBytes(calculationOfRedemptionPriceStartDate.rest, 8) IN IF ~calculationOfRedemptionPriceEndDate.ok THEN Fail ELSE
    LET etpProductTypeCode == ReadBytes(calculationOfRedemptionPriceEndDate.rest, 1) IN IF ~etpProductTypeCode.ok THEN Fail ELSE
    LET indexCalculationInstitutionTypeCode == ReadBytes(etpProductTypeCode.rest, 2) IN IF ~indexCalculationInstitutionTypeCode.ok THEN Fail ELSE
    LET indexMarketClassificationId == ReadBytes(indexCalculationInstitutionTypeCode.rest, 6) IN IF ~indexMarketClassificationId.ok THEN Fail ELSE
    LET indexSequenceNumber == ReadBytes(indexMarketClassificationId.rest, 3) IN IF ~indexSequenceNumber.ok THEN Fail ELSE
    LET trackingIndexLeverageInverseTypeCode == ReadBytes(indexSequenceNumber.rest, 2) IN IF ~trackingIndexLeverageInverseTypeCode.ok THEN Fail ELSE
    LET referenceIndexLeverageInverseTypeCode == ReadBytes(trackingIndexLeverageInverseTypeCode.rest, 2) IN IF ~referenceIndexLeverageInverseTypeCode.ok THEN Fail ELSE
    LET indexAssetClassificationId1 == ReadBytes(referenceIndexLeverageInverseTypeCode.rest, 6) IN IF ~indexAssetClassificationId1.ok THEN Fail ELSE
    LET indexAssetClassificationId2 == ReadBytes(indexAssetClassificationId1.rest, 6) IN IF ~indexAssetClassificationId2.ok THEN Fail ELSE
    LET ipoUnderwriterMemberNumber == ReadBytes(indexAssetClassificationId2.rest, 5) IN IF ~ipoUnderwriterMemberNumber.ok THEN Fail ELSE
    LET lpOrder == ReadBytes(ipoUnderwriterMemberNumber.rest, 1) IN IF ~lpOrder.ok THEN Fail ELSE
    LET lowLiquidity == ReadBytes(lpOrder.rest, 1) IN IF ~lowLiquidity.ok THEN Fail ELSE
    LET abnormalRise == ReadBytes(lowLiquidity.rest, 1) IN IF ~abnormalRise.ok THEN Fail ELSE
    LET upperLimitQuantity == ReadBytes(abnormalRise.rest, 23) IN IF ~upperLimitQuantity.ok THEN Fail ELSE
    LET investmentPrecautionIssue == ReadBytes(upperLimitQuantity.rest, 1) IN IF ~investmentPrecautionIssue.ok THEN Fail ELSE
    LET preferredStocksWithLesserShares == ReadBytes(investmentPrecautionIssue.rest, 1) IN IF ~preferredStocksWithLesserShares.ok THEN Fail ELSE
    LET spacMerger == ReadBytes(preferredStocksWithLesserShares.rest, 1) IN IF ~spacMerger.ok THEN Fail ELSE
    LET segmentTypeCode == ReadBytes(spacMerger.rest, 1) IN IF ~segmentTypeCode.ok THEN Fail ELSE
    LET afterMarketPossibility == ReadBytes(segmentTypeCode.rest, 1) IN IF ~afterMarketPossibility.ok THEN Fail ELSE
    LET preMarketPossibility == ReadBytes(afterMarketPossibility.rest, 1) IN IF ~preMarketPossibility.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(preMarketPossibility.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber                                  |-> messageSequenceNumber.value,
         totalNumberOfInstrumentsOfTheContract                  |-> totalNumberOfInstrumentsOfTheContract.value,
         businessDate                                           |-> businessDate.value,
         isinCode                                               |-> isinCode.value,
         aDesignatedNumberForAnIssue                            |-> aDesignatedNumberForAnIssue.value,
         abbreviatedIssueCode                                   |-> abbreviatedIssueCode.value,
         abbreviatedIssueName                                   |-> abbreviatedIssueName.value,
         abbreviatedIssueNameInEn                               |-> abbreviatedIssueNameInEn.value,
         groupNumber                                            |-> groupNumber.value,
         marketOperationProductId                               |-> marketOperationProductId.value,
         securityGroupId                                        |-> securityGroupId.value,
         discreteTimeTrading                                    |-> discreteTimeTrading.value,
         rightsTypeCode                                         |-> rightsTypeCode.value,
         parValueTypeCode                                       |-> parValueTypeCode.value,
         anIssueOfWhichBasePriceIsSettledWithATodaysSinglePrice |-> anIssueOfWhichBasePriceIsSettledWithATodaysSinglePrice.value,
         reevaluationReasonCode                                 |-> reevaluationReasonCode.value,
         basePriceChange                                        |-> basePriceChange.value,
         randomEndTriggerCode                                   |-> randomEndTriggerCode.value,
         marketAlert                                            |-> marketAlert.value,
         marketAlertTypeCode                                    |-> marketAlertTypeCode.value,
         koreaCorporateGovernanceStockPriceIndexKogi            |-> koreaCorporateGovernanceStockPriceIndexKogi.value,
         issueForAdministration                                 |-> issueForAdministration.value,
         unfaithfulDisclosure                                   |-> unfaithfulDisclosure.value,
         backDoorListing                                        |-> backDoorListing.value,
         tradingHalt                                            |-> tradingHalt.value,
         industryId                                             |-> industryId.value,
         smallMediumSizedBusiness                               |-> smallMediumSizedBusiness.value,
         sectionTypeCode                                        |-> sectionTypeCode.value,
         investmentInstitutionTypeCode                          |-> investmentInstitutionTypeCode.value,
         basePrice                                              |-> basePrice.value,
         yesterdaysClosingPriceTypeCode                         |-> yesterdaysClosingPriceTypeCode.value,
         yesterdaysClosingPrice                                 |-> yesterdaysClosingPrice.value,
         yesterdaysAccumulatedTradingAmount                     |-> yesterdaysAccumulatedTradingAmount.value,
         yesterdaysAccumulatedTradingValue                      |-> yesterdaysAccumulatedTradingValue.value,
         upperLimitPrice                                        |-> upperLimitPrice.value,
         lowerLimitPrice                                        |-> lowerLimitPrice.value,
         substitutePriceOfSecurities                            |-> substitutePriceOfSecurities.value,
         parValue                                               |-> parValue.value,
         issuingPrice                                           |-> issuingPrice.value,
         listingDate                                            |-> listingDate.value,
         numberOfListedShares                                   |-> numberOfListedShares.value,
         liquidationTrade                                       |-> liquidationTrade.value,
         theEstablishmentDate                                   |-> theEstablishmentDate.value,
         maturityDate                                           |-> maturityDate.value,
         exercisingPeriod                                       |-> exercisingPeriod.value,
         expirationDateForRight                                 |-> expirationDateForRight.value,
         exercisePriceOfElwOrBw                                 |-> exercisePriceOfElwOrBw.value,
         capital                                                |-> capital.value,
         creditOrderPossibillity                                |-> creditOrderPossibillity.value,
         limitOrderPermissionTypeCode                           |-> limitOrderPermissionTypeCode.value,
         marketPriceOrderPermissionTypeCode                     |-> marketPriceOrderPermissionTypeCode.value,
         conditionedOrderPermissionTypeCode                     |-> conditionedOrderPermissionTypeCode.value,
         bestFavorableOrderPermissionTypeCode                   |-> bestFavorableOrderPermissionTypeCode.value,
         firstBestOrderPermissionTypeCode                       |-> firstBestOrderPermissionTypeCode.value,
         midPriceOrderPermissionTypeCode                        |-> midPriceOrderPermissionTypeCode.value,
         stopLimitPriceOrderPermissionTypeCode                  |-> stopLimitPriceOrderPermissionTypeCode.value,
         capitalIncreaseTypeCode                                |-> capitalIncreaseTypeCode.value,
         otherStockTypeCode                                     |-> otherStockTypeCode.value,
         nationalStock                                          |-> nationalStock.value,
         appraisedPrice                                         |-> appraisedPrice.value,
         lowestOrderPrice                                       |-> lowestOrderPrice.value,
         highestOrderPrice                                      |-> highestOrderPrice.value,
         unitOfVolumeInMainBoard                                |-> unitOfVolumeInMainBoard.value,
         lotSizeAfterHoursTrading                               |-> lotSizeAfterHoursTrading.value,
         reiTsTypeCode                                          |-> reiTsTypeCode.value,
         targetStockIsinCode                                    |-> targetStockIsinCode.value,
         currencyIsoCode                                        |-> currencyIsoCode.value,
         countryCode                                            |-> countryCode.value,
         marketMakingPossibility                                |-> marketMakingPossibility.value,
         closingPriceTradingPossibilityInTheAfterHours          |-> closingPriceTradingPossibilityInTheAfterHours.value,
         closingPriceTradingInThePreOpeningMarket               |-> closingPriceTradingInThePreOpeningMarket.value,
         blockTradingInThePreOpeningMarket                      |-> blockTradingInThePreOpeningMarket.value,
         basketTradingInThePreOpeningMarket                     |-> basketTradingInThePreOpeningMarket.value,
         announcementOfEstimatedTradingPrice                    |-> announcementOfEstimatedTradingPrice.value,
         shortSelling                                           |-> shortSelling.value,
         etfTrackingDifference                                  |-> etfTrackingDifference.value,
         regs                                                   |-> regs.value,
         spac                                                   |-> spac.value,
         taxTypeCode                                            |-> taxTypeCode.value,
         appraisalRatioOfSubstitutePrice                        |-> appraisalRatioOfSubstitutePrice.value,
         investmentCautionIssue                                 |-> investmentCautionIssue.value,
         delistingDate                                          |-> delistingDate.value,
         shortTermOverheatIssueTypeCode                         |-> shortTermOverheatIssueTypeCode.value,
         etfReplicationMethodsTypeCode                          |-> etfReplicationMethodsTypeCode.value,
         expirationDate                                         |-> expirationDate.value,
         distributionTypeCode                                   |-> distributionTypeCode.value,
         calculationOfRedemptionPriceStartDate                  |-> calculationOfRedemptionPriceStartDate.value,
         calculationOfRedemptionPriceEndDate                    |-> calculationOfRedemptionPriceEndDate.value,
         etpProductTypeCode                                     |-> etpProductTypeCode.value,
         indexCalculationInstitutionTypeCode                    |-> indexCalculationInstitutionTypeCode.value,
         indexMarketClassificationId                            |-> indexMarketClassificationId.value,
         indexSequenceNumber                                    |-> indexSequenceNumber.value,
         trackingIndexLeverageInverseTypeCode                   |-> trackingIndexLeverageInverseTypeCode.value,
         referenceIndexLeverageInverseTypeCode                  |-> referenceIndexLeverageInverseTypeCode.value,
         indexAssetClassificationId1                            |-> indexAssetClassificationId1.value,
         indexAssetClassificationId2                            |-> indexAssetClassificationId2.value,
         ipoUnderwriterMemberNumber                             |-> ipoUnderwriterMemberNumber.value,
         lpOrder                                                |-> lpOrder.value,
         lowLiquidity                                           |-> lowLiquidity.value,
         abnormalRise                                           |-> abnormalRise.value,
         upperLimitQuantity                                     |-> upperLimitQuantity.value,
         investmentPrecautionIssue                              |-> investmentPrecautionIssue.value,
         preferredStocksWithLesserShares                        |-> preferredStocksWithLesserShares.value,
         spacMerger                                             |-> spacMerger.value,
         segmentTypeCode                                        |-> segmentTypeCode.value,
         afterMarketPossibility                                 |-> afterMarketPossibility.value,
         preMarketPossibility                                   |-> preMarketPossibility.value,
         endKeyword                                             |-> endKeyword.value ], endKeyword.rest)

ZeroSecuritiesEquitiesBatchDataMessage ==
    [ messageSequenceNumber                                  |-> [i \in 1 .. 8 |-> 0],
      totalNumberOfInstrumentsOfTheContract                  |-> [i \in 1 .. 6 |-> 0],
      businessDate                                           |-> [i \in 1 .. 8 |-> 0],
      isinCode                                               |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue                            |-> [i \in 1 .. 6 |-> 0],
      abbreviatedIssueCode                                   |-> [i \in 1 .. 9 |-> 0],
      abbreviatedIssueName                                   |-> [i \in 1 .. 40 |-> 0],
      abbreviatedIssueNameInEn                               |-> [i \in 1 .. 40 |-> 0],
      groupNumber                                            |-> [i \in 1 .. 5 |-> 0],
      marketOperationProductId                               |-> [i \in 1 .. 3 |-> 0],
      securityGroupId                                        |-> [i \in 1 .. 2 |-> 0],
      discreteTimeTrading                                    |-> [i \in 1 .. 1 |-> 0],
      rightsTypeCode                                         |-> [i \in 1 .. 2 |-> 0],
      parValueTypeCode                                       |-> [i \in 1 .. 2 |-> 0],
      anIssueOfWhichBasePriceIsSettledWithATodaysSinglePrice |-> [i \in 1 .. 1 |-> 0],
      reevaluationReasonCode                                 |-> [i \in 1 .. 2 |-> 0],
      basePriceChange                                        |-> [i \in 1 .. 1 |-> 0],
      randomEndTriggerCode                                   |-> [i \in 1 .. 1 |-> 0],
      marketAlert                                            |-> [i \in 1 .. 1 |-> 0],
      marketAlertTypeCode                                    |-> [i \in 1 .. 2 |-> 0],
      koreaCorporateGovernanceStockPriceIndexKogi            |-> [i \in 1 .. 1 |-> 0],
      issueForAdministration                                 |-> [i \in 1 .. 1 |-> 0],
      unfaithfulDisclosure                                   |-> [i \in 1 .. 1 |-> 0],
      backDoorListing                                        |-> [i \in 1 .. 1 |-> 0],
      tradingHalt                                            |-> [i \in 1 .. 1 |-> 0],
      industryId                                             |-> [i \in 1 .. 10 |-> 0],
      smallMediumSizedBusiness                               |-> [i \in 1 .. 1 |-> 0],
      sectionTypeCode                                        |-> [i \in 1 .. 1 |-> 0],
      investmentInstitutionTypeCode                          |-> [i \in 1 .. 1 |-> 0],
      basePrice                                              |-> [i \in 1 .. 11 |-> 0],
      yesterdaysClosingPriceTypeCode                         |-> [i \in 1 .. 1 |-> 0],
      yesterdaysClosingPrice                                 |-> [i \in 1 .. 11 |-> 0],
      yesterdaysAccumulatedTradingAmount                     |-> [i \in 1 .. 12 |-> 0],
      yesterdaysAccumulatedTradingValue                      |-> [i \in 1 .. 22 |-> 0],
      upperLimitPrice                                        |-> [i \in 1 .. 11 |-> 0],
      lowerLimitPrice                                        |-> [i \in 1 .. 11 |-> 0],
      substitutePriceOfSecurities                            |-> [i \in 1 .. 11 |-> 0],
      parValue                                               |-> [i \in 1 .. 11 |-> 0],
      issuingPrice                                           |-> [i \in 1 .. 11 |-> 0],
      listingDate                                            |-> [i \in 1 .. 8 |-> 0],
      numberOfListedShares                                   |-> [i \in 1 .. 16 |-> 0],
      liquidationTrade                                       |-> [i \in 1 .. 1 |-> 0],
      theEstablishmentDate                                   |-> [i \in 1 .. 8 |-> 0],
      maturityDate                                           |-> [i \in 1 .. 8 |-> 0],
      exercisingPeriod                                       |-> [i \in 1 .. 8 |-> 0],
      expirationDateForRight                                 |-> [i \in 1 .. 8 |-> 0],
      exercisePriceOfElwOrBw                                 |-> [i \in 1 .. 13 |-> 0],
      capital                                                |-> [i \in 1 .. 22 |-> 0],
      creditOrderPossibillity                                |-> [i \in 1 .. 1 |-> 0],
      limitOrderPermissionTypeCode                           |-> [i \in 1 .. 5 |-> 0],
      marketPriceOrderPermissionTypeCode                     |-> [i \in 1 .. 5 |-> 0],
      conditionedOrderPermissionTypeCode                     |-> [i \in 1 .. 5 |-> 0],
      bestFavorableOrderPermissionTypeCode                   |-> [i \in 1 .. 5 |-> 0],
      firstBestOrderPermissionTypeCode                       |-> [i \in 1 .. 5 |-> 0],
      midPriceOrderPermissionTypeCode                        |-> [i \in 1 .. 5 |-> 0],
      stopLimitPriceOrderPermissionTypeCode                  |-> [i \in 1 .. 5 |-> 0],
      capitalIncreaseTypeCode                                |-> [i \in 1 .. 2 |-> 0],
      otherStockTypeCode                                     |-> [i \in 1 .. 1 |-> 0],
      nationalStock                                          |-> [i \in 1 .. 1 |-> 0],
      appraisedPrice                                         |-> [i \in 1 .. 11 |-> 0],
      lowestOrderPrice                                       |-> [i \in 1 .. 11 |-> 0],
      highestOrderPrice                                      |-> [i \in 1 .. 11 |-> 0],
      unitOfVolumeInMainBoard                                |-> [i \in 1 .. 11 |-> 0],
      lotSizeAfterHoursTrading                               |-> [i \in 1 .. 11 |-> 0],
      reiTsTypeCode                                          |-> [i \in 1 .. 1 |-> 0],
      targetStockIsinCode                                    |-> [i \in 1 .. 12 |-> 0],
      currencyIsoCode                                        |-> [i \in 1 .. 3 |-> 0],
      countryCode                                            |-> [i \in 1 .. 3 |-> 0],
      marketMakingPossibility                                |-> [i \in 1 .. 1 |-> 0],
      closingPriceTradingPossibilityInTheAfterHours          |-> [i \in 1 .. 1 |-> 0],
      closingPriceTradingInThePreOpeningMarket               |-> [i \in 1 .. 1 |-> 0],
      blockTradingInThePreOpeningMarket                      |-> [i \in 1 .. 1 |-> 0],
      basketTradingInThePreOpeningMarket                     |-> [i \in 1 .. 1 |-> 0],
      announcementOfEstimatedTradingPrice                    |-> [i \in 1 .. 1 |-> 0],
      shortSelling                                           |-> [i \in 1 .. 1 |-> 0],
      etfTrackingDifference                                  |-> [i \in 1 .. 13 |-> 0],
      regs                                                   |-> [i \in 1 .. 1 |-> 0],
      spac                                                   |-> [i \in 1 .. 1 |-> 0],
      taxTypeCode                                            |-> [i \in 1 .. 1 |-> 0],
      appraisalRatioOfSubstitutePrice                        |-> [i \in 1 .. 13 |-> 0],
      investmentCautionIssue                                 |-> [i \in 1 .. 1 |-> 0],
      delistingDate                                          |-> [i \in 1 .. 8 |-> 0],
      shortTermOverheatIssueTypeCode                         |-> [i \in 1 .. 1 |-> 0],
      etfReplicationMethodsTypeCode                          |-> [i \in 1 .. 1 |-> 0],
      expirationDate                                         |-> [i \in 1 .. 8 |-> 0],
      distributionTypeCode                                   |-> [i \in 1 .. 2 |-> 0],
      calculationOfRedemptionPriceStartDate                  |-> [i \in 1 .. 8 |-> 0],
      calculationOfRedemptionPriceEndDate                    |-> [i \in 1 .. 8 |-> 0],
      etpProductTypeCode                                     |-> [i \in 1 .. 1 |-> 0],
      indexCalculationInstitutionTypeCode                    |-> [i \in 1 .. 2 |-> 0],
      indexMarketClassificationId                            |-> [i \in 1 .. 6 |-> 0],
      indexSequenceNumber                                    |-> [i \in 1 .. 3 |-> 0],
      trackingIndexLeverageInverseTypeCode                   |-> [i \in 1 .. 2 |-> 0],
      referenceIndexLeverageInverseTypeCode                  |-> [i \in 1 .. 2 |-> 0],
      indexAssetClassificationId1                            |-> [i \in 1 .. 6 |-> 0],
      indexAssetClassificationId2                            |-> [i \in 1 .. 6 |-> 0],
      ipoUnderwriterMemberNumber                             |-> [i \in 1 .. 5 |-> 0],
      lpOrder                                                |-> [i \in 1 .. 1 |-> 0],
      lowLiquidity                                           |-> [i \in 1 .. 1 |-> 0],
      abnormalRise                                           |-> [i \in 1 .. 1 |-> 0],
      upperLimitQuantity                                     |-> [i \in 1 .. 23 |-> 0],
      investmentPrecautionIssue                              |-> [i \in 1 .. 1 |-> 0],
      preferredStocksWithLesserShares                        |-> [i \in 1 .. 1 |-> 0],
      spacMerger                                             |-> [i \in 1 .. 1 |-> 0],
      segmentTypeCode                                        |-> [i \in 1 .. 1 |-> 0],
      afterMarketPossibility                                 |-> [i \in 1 .. 1 |-> 0],
      preMarketPossibility                                   |-> [i \in 1 .. 1 |-> 0],
      endKeyword                                             |-> [i \in 1 .. 1 |-> 0] ]

(* Securities Equities Batch Data Message at zero, then each field in turn at the values it is checked at *)
CheckedSecuritiesEquitiesBatchDataMessage ==
    { ZeroSecuritiesEquitiesBatchDataMessage }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.totalNumberOfInstrumentsOfTheContract = one] : one \in Sample(6) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.businessDate = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.abbreviatedIssueCode = one] : one \in Sample(9) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.abbreviatedIssueName = one] : one \in Sample(40) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.abbreviatedIssueNameInEn = one] : one \in Sample(40) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.groupNumber = one] : one \in Sample(5) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.marketOperationProductId = one] : one \in Sample(3) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.securityGroupId = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.discreteTimeTrading = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.rightsTypeCode = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.parValueTypeCode = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.anIssueOfWhichBasePriceIsSettledWithATodaysSinglePrice = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.reevaluationReasonCode = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.basePriceChange = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.randomEndTriggerCode = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.marketAlert = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.marketAlertTypeCode = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.koreaCorporateGovernanceStockPriceIndexKogi = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.issueForAdministration = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.unfaithfulDisclosure = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.backDoorListing = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.tradingHalt = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.industryId = one] : one \in Sample(10) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.smallMediumSizedBusiness = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.sectionTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.investmentInstitutionTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.basePrice = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.yesterdaysClosingPriceTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.yesterdaysClosingPrice = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.yesterdaysAccumulatedTradingAmount = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.yesterdaysAccumulatedTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.upperLimitPrice = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.lowerLimitPrice = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.substitutePriceOfSecurities = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.parValue = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.issuingPrice = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.listingDate = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.numberOfListedShares = one] : one \in Sample(16) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.liquidationTrade = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.theEstablishmentDate = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.maturityDate = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.exercisingPeriod = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.expirationDateForRight = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.exercisePriceOfElwOrBw = one] : one \in Sample(13) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.capital = one] : one \in Sample(22) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.creditOrderPossibillity = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.limitOrderPermissionTypeCode = one] : one \in Sample(5) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.marketPriceOrderPermissionTypeCode = one] : one \in Sample(5) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.conditionedOrderPermissionTypeCode = one] : one \in Sample(5) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.bestFavorableOrderPermissionTypeCode = one] : one \in Sample(5) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.firstBestOrderPermissionTypeCode = one] : one \in Sample(5) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.midPriceOrderPermissionTypeCode = one] : one \in Sample(5) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.stopLimitPriceOrderPermissionTypeCode = one] : one \in Sample(5) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.capitalIncreaseTypeCode = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.otherStockTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.nationalStock = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.appraisedPrice = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.lowestOrderPrice = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.highestOrderPrice = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.unitOfVolumeInMainBoard = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.lotSizeAfterHoursTrading = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.reiTsTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.targetStockIsinCode = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.currencyIsoCode = one] : one \in Sample(3) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.countryCode = one] : one \in Sample(3) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.marketMakingPossibility = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.closingPriceTradingPossibilityInTheAfterHours = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.closingPriceTradingInThePreOpeningMarket = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.blockTradingInThePreOpeningMarket = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.basketTradingInThePreOpeningMarket = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.announcementOfEstimatedTradingPrice = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.shortSelling = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.etfTrackingDifference = one] : one \in Sample(13) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.regs = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.spac = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.taxTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.appraisalRatioOfSubstitutePrice = one] : one \in Sample(13) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.investmentCautionIssue = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.delistingDate = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.shortTermOverheatIssueTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.etfReplicationMethodsTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.expirationDate = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.distributionTypeCode = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.calculationOfRedemptionPriceStartDate = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.calculationOfRedemptionPriceEndDate = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.etpProductTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.indexCalculationInstitutionTypeCode = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.indexMarketClassificationId = one] : one \in Sample(6) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.indexSequenceNumber = one] : one \in Sample(3) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.trackingIndexLeverageInverseTypeCode = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.referenceIndexLeverageInverseTypeCode = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.indexAssetClassificationId1 = one] : one \in Sample(6) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.indexAssetClassificationId2 = one] : one \in Sample(6) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.ipoUnderwriterMemberNumber = one] : one \in Sample(5) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.lpOrder = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.lowLiquidity = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.abnormalRise = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.upperLimitQuantity = one] : one \in Sample(23) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.investmentPrecautionIssue = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.preferredStocksWithLesserShares = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.spacMerger = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.segmentTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.afterMarketPossibility = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.preMarketPossibility = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquitiesBatchDataMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Securities Closing Date Message: 25 bytes                               *)
(***************************************************************************)

SecuritiesClosingDateMessage ==
    [ messageSequenceNumber : Sample(8),
      isinCode              : Sample(12),
      closingDate           : Sample(4),
      endKeyword            : Sample(1) ]

EncodeSecuritiesClosingDateMessage(message) ==
    message.messageSequenceNumber
        \o message.isinCode
        \o message.closingDate
        \o message.endKeyword

DecodeSecuritiesClosingDateMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET isinCode == ReadBytes(messageSequenceNumber.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET closingDate == ReadBytes(isinCode.rest, 4) IN IF ~closingDate.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(closingDate.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber |-> messageSequenceNumber.value,
         isinCode              |-> isinCode.value,
         closingDate           |-> closingDate.value,
         endKeyword            |-> endKeyword.value ], endKeyword.rest)

ZeroSecuritiesClosingDateMessage ==
    [ messageSequenceNumber |-> [i \in 1 .. 8 |-> 0],
      isinCode              |-> [i \in 1 .. 12 |-> 0],
      closingDate           |-> [i \in 1 .. 4 |-> 0],
      endKeyword            |-> [i \in 1 .. 1 |-> 0] ]

(* Securities Closing Date Message at zero, then each field in turn at the values it is checked at *)
CheckedSecuritiesClosingDateMessage ==
    { ZeroSecuritiesClosingDateMessage }
        \cup { [ZeroSecuritiesClosingDateMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesClosingDateMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesClosingDateMessage EXCEPT !.closingDate = one] : one \in Sample(4) }
        \cup { [ZeroSecuritiesClosingDateMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Securities Mm Lp Information Message: 195 bytes                         *)
(***************************************************************************)

SecuritiesMmLpInformationMessage ==
    [ messageSequenceNumber                  : Sample(8),
      isinCode                               : Sample(12),
      marketParticipantNumber                : Sample(5),
      boardId                                : Sample(2),
      marketMakingLpTypeCode                 : Sample(1),
      lpStartDate                            : Sample(8),
      lpEndDate                              : Sample(8),
      minimumOrderVolume                     : Sample(11),
      maximumVolumeOfMultipleOrder           : Sample(11),
      bidAskSpreadUnitCode                   : Sample(1),
      upperLimitOfBidAskSpread               : Sample(22),
      spreadMultipleForMarketHolidays        : Sample(11),
      anObligatoryTimeIntervalToPlaceAnOrder : Sample(6),
      minimumAskPrice                        : Sample(22),
      maximumBidPrice                        : Sample(22),
      minimumOrderPrice                      : Sample(22),
      maximumOrderPrice                      : Sample(22),
      endKeyword                             : Sample(1) ]

EncodeSecuritiesMmLpInformationMessage(message) ==
    message.messageSequenceNumber
        \o message.isinCode
        \o message.marketParticipantNumber
        \o message.boardId
        \o message.marketMakingLpTypeCode
        \o message.lpStartDate
        \o message.lpEndDate
        \o message.minimumOrderVolume
        \o message.maximumVolumeOfMultipleOrder
        \o message.bidAskSpreadUnitCode
        \o message.upperLimitOfBidAskSpread
        \o message.spreadMultipleForMarketHolidays
        \o message.anObligatoryTimeIntervalToPlaceAnOrder
        \o message.minimumAskPrice
        \o message.maximumBidPrice
        \o message.minimumOrderPrice
        \o message.maximumOrderPrice
        \o message.endKeyword

DecodeSecuritiesMmLpInformationMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET isinCode == ReadBytes(messageSequenceNumber.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET marketParticipantNumber == ReadBytes(isinCode.rest, 5) IN IF ~marketParticipantNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(marketParticipantNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET marketMakingLpTypeCode == ReadBytes(boardId.rest, 1) IN IF ~marketMakingLpTypeCode.ok THEN Fail ELSE
    LET lpStartDate == ReadBytes(marketMakingLpTypeCode.rest, 8) IN IF ~lpStartDate.ok THEN Fail ELSE
    LET lpEndDate == ReadBytes(lpStartDate.rest, 8) IN IF ~lpEndDate.ok THEN Fail ELSE
    LET minimumOrderVolume == ReadBytes(lpEndDate.rest, 11) IN IF ~minimumOrderVolume.ok THEN Fail ELSE
    LET maximumVolumeOfMultipleOrder == ReadBytes(minimumOrderVolume.rest, 11) IN IF ~maximumVolumeOfMultipleOrder.ok THEN Fail ELSE
    LET bidAskSpreadUnitCode == ReadBytes(maximumVolumeOfMultipleOrder.rest, 1) IN IF ~bidAskSpreadUnitCode.ok THEN Fail ELSE
    LET upperLimitOfBidAskSpread == ReadBytes(bidAskSpreadUnitCode.rest, 22) IN IF ~upperLimitOfBidAskSpread.ok THEN Fail ELSE
    LET spreadMultipleForMarketHolidays == ReadBytes(upperLimitOfBidAskSpread.rest, 11) IN IF ~spreadMultipleForMarketHolidays.ok THEN Fail ELSE
    LET anObligatoryTimeIntervalToPlaceAnOrder == ReadBytes(spreadMultipleForMarketHolidays.rest, 6) IN IF ~anObligatoryTimeIntervalToPlaceAnOrder.ok THEN Fail ELSE
    LET minimumAskPrice == ReadBytes(anObligatoryTimeIntervalToPlaceAnOrder.rest, 22) IN IF ~minimumAskPrice.ok THEN Fail ELSE
    LET maximumBidPrice == ReadBytes(minimumAskPrice.rest, 22) IN IF ~maximumBidPrice.ok THEN Fail ELSE
    LET minimumOrderPrice == ReadBytes(maximumBidPrice.rest, 22) IN IF ~minimumOrderPrice.ok THEN Fail ELSE
    LET maximumOrderPrice == ReadBytes(minimumOrderPrice.rest, 22) IN IF ~maximumOrderPrice.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(maximumOrderPrice.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber                  |-> messageSequenceNumber.value,
         isinCode                               |-> isinCode.value,
         marketParticipantNumber                |-> marketParticipantNumber.value,
         boardId                                |-> boardId.value,
         marketMakingLpTypeCode                 |-> marketMakingLpTypeCode.value,
         lpStartDate                            |-> lpStartDate.value,
         lpEndDate                              |-> lpEndDate.value,
         minimumOrderVolume                     |-> minimumOrderVolume.value,
         maximumVolumeOfMultipleOrder           |-> maximumVolumeOfMultipleOrder.value,
         bidAskSpreadUnitCode                   |-> bidAskSpreadUnitCode.value,
         upperLimitOfBidAskSpread               |-> upperLimitOfBidAskSpread.value,
         spreadMultipleForMarketHolidays        |-> spreadMultipleForMarketHolidays.value,
         anObligatoryTimeIntervalToPlaceAnOrder |-> anObligatoryTimeIntervalToPlaceAnOrder.value,
         minimumAskPrice                        |-> minimumAskPrice.value,
         maximumBidPrice                        |-> maximumBidPrice.value,
         minimumOrderPrice                      |-> minimumOrderPrice.value,
         maximumOrderPrice                      |-> maximumOrderPrice.value,
         endKeyword                             |-> endKeyword.value ], endKeyword.rest)

ZeroSecuritiesMmLpInformationMessage ==
    [ messageSequenceNumber                  |-> [i \in 1 .. 8 |-> 0],
      isinCode                               |-> [i \in 1 .. 12 |-> 0],
      marketParticipantNumber                |-> [i \in 1 .. 5 |-> 0],
      boardId                                |-> [i \in 1 .. 2 |-> 0],
      marketMakingLpTypeCode                 |-> [i \in 1 .. 1 |-> 0],
      lpStartDate                            |-> [i \in 1 .. 8 |-> 0],
      lpEndDate                              |-> [i \in 1 .. 8 |-> 0],
      minimumOrderVolume                     |-> [i \in 1 .. 11 |-> 0],
      maximumVolumeOfMultipleOrder           |-> [i \in 1 .. 11 |-> 0],
      bidAskSpreadUnitCode                   |-> [i \in 1 .. 1 |-> 0],
      upperLimitOfBidAskSpread               |-> [i \in 1 .. 22 |-> 0],
      spreadMultipleForMarketHolidays        |-> [i \in 1 .. 11 |-> 0],
      anObligatoryTimeIntervalToPlaceAnOrder |-> [i \in 1 .. 6 |-> 0],
      minimumAskPrice                        |-> [i \in 1 .. 22 |-> 0],
      maximumBidPrice                        |-> [i \in 1 .. 22 |-> 0],
      minimumOrderPrice                      |-> [i \in 1 .. 22 |-> 0],
      maximumOrderPrice                      |-> [i \in 1 .. 22 |-> 0],
      endKeyword                             |-> [i \in 1 .. 1 |-> 0] ]

(* Securities Mm Lp Information Message at zero, then each field in turn at the values it is checked at *)
CheckedSecuritiesMmLpInformationMessage ==
    { ZeroSecuritiesMmLpInformationMessage }
        \cup { [ZeroSecuritiesMmLpInformationMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesMmLpInformationMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesMmLpInformationMessage EXCEPT !.marketParticipantNumber = one] : one \in Sample(5) }
        \cup { [ZeroSecuritiesMmLpInformationMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesMmLpInformationMessage EXCEPT !.marketMakingLpTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesMmLpInformationMessage EXCEPT !.lpStartDate = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesMmLpInformationMessage EXCEPT !.lpEndDate = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesMmLpInformationMessage EXCEPT !.minimumOrderVolume = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesMmLpInformationMessage EXCEPT !.maximumVolumeOfMultipleOrder = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesMmLpInformationMessage EXCEPT !.bidAskSpreadUnitCode = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesMmLpInformationMessage EXCEPT !.upperLimitOfBidAskSpread = one] : one \in Sample(22) }
        \cup { [ZeroSecuritiesMmLpInformationMessage EXCEPT !.spreadMultipleForMarketHolidays = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesMmLpInformationMessage EXCEPT !.anObligatoryTimeIntervalToPlaceAnOrder = one] : one \in Sample(6) }
        \cup { [ZeroSecuritiesMmLpInformationMessage EXCEPT !.minimumAskPrice = one] : one \in Sample(22) }
        \cup { [ZeroSecuritiesMmLpInformationMessage EXCEPT !.maximumBidPrice = one] : one \in Sample(22) }
        \cup { [ZeroSecuritiesMmLpInformationMessage EXCEPT !.minimumOrderPrice = one] : one \in Sample(22) }
        \cup { [ZeroSecuritiesMmLpInformationMessage EXCEPT !.maximumOrderPrice = one] : one \in Sample(22) }
        \cup { [ZeroSecuritiesMmLpInformationMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Securities Member Information Message: 202 bytes                        *)
(***************************************************************************)

SecuritiesMemberInformationMessage ==
    [ messageSequenceNumber                     : Sample(8),
      businessDate                              : Sample(8),
      marketParticipantNumber                   : Sample(5),
      nameOfAMarketParticipantInKr              : Sample(80),
      nameOfAMarketParticipantInEn              : Sample(80),
      anAbbreviatedNameOfAMarketParticipantInKr : Sample(20),
      endKeyword                                : Sample(1) ]

EncodeSecuritiesMemberInformationMessage(message) ==
    message.messageSequenceNumber
        \o message.businessDate
        \o message.marketParticipantNumber
        \o message.nameOfAMarketParticipantInKr
        \o message.nameOfAMarketParticipantInEn
        \o message.anAbbreviatedNameOfAMarketParticipantInKr
        \o message.endKeyword

DecodeSecuritiesMemberInformationMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET businessDate == ReadBytes(messageSequenceNumber.rest, 8) IN IF ~businessDate.ok THEN Fail ELSE
    LET marketParticipantNumber == ReadBytes(businessDate.rest, 5) IN IF ~marketParticipantNumber.ok THEN Fail ELSE
    LET nameOfAMarketParticipantInKr == ReadBytes(marketParticipantNumber.rest, 80) IN IF ~nameOfAMarketParticipantInKr.ok THEN Fail ELSE
    LET nameOfAMarketParticipantInEn == ReadBytes(nameOfAMarketParticipantInKr.rest, 80) IN IF ~nameOfAMarketParticipantInEn.ok THEN Fail ELSE
    LET anAbbreviatedNameOfAMarketParticipantInKr == ReadBytes(nameOfAMarketParticipantInEn.rest, 20) IN IF ~anAbbreviatedNameOfAMarketParticipantInKr.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(anAbbreviatedNameOfAMarketParticipantInKr.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber                     |-> messageSequenceNumber.value,
         businessDate                              |-> businessDate.value,
         marketParticipantNumber                   |-> marketParticipantNumber.value,
         nameOfAMarketParticipantInKr              |-> nameOfAMarketParticipantInKr.value,
         nameOfAMarketParticipantInEn              |-> nameOfAMarketParticipantInEn.value,
         anAbbreviatedNameOfAMarketParticipantInKr |-> anAbbreviatedNameOfAMarketParticipantInKr.value,
         endKeyword                                |-> endKeyword.value ], endKeyword.rest)

ZeroSecuritiesMemberInformationMessage ==
    [ messageSequenceNumber                     |-> [i \in 1 .. 8 |-> 0],
      businessDate                              |-> [i \in 1 .. 8 |-> 0],
      marketParticipantNumber                   |-> [i \in 1 .. 5 |-> 0],
      nameOfAMarketParticipantInKr              |-> [i \in 1 .. 80 |-> 0],
      nameOfAMarketParticipantInEn              |-> [i \in 1 .. 80 |-> 0],
      anAbbreviatedNameOfAMarketParticipantInKr |-> [i \in 1 .. 20 |-> 0],
      endKeyword                                |-> [i \in 1 .. 1 |-> 0] ]

(* Securities Member Information Message at zero, then each field in turn at the values it is checked at *)
CheckedSecuritiesMemberInformationMessage ==
    { ZeroSecuritiesMemberInformationMessage }
        \cup { [ZeroSecuritiesMemberInformationMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesMemberInformationMessage EXCEPT !.businessDate = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesMemberInformationMessage EXCEPT !.marketParticipantNumber = one] : one \in Sample(5) }
        \cup { [ZeroSecuritiesMemberInformationMessage EXCEPT !.nameOfAMarketParticipantInKr = one] : one \in Sample(80) }
        \cup { [ZeroSecuritiesMemberInformationMessage EXCEPT !.nameOfAMarketParticipantInEn = one] : one \in Sample(80) }
        \cup { [ZeroSecuritiesMemberInformationMessage EXCEPT !.anAbbreviatedNameOfAMarketParticipantInKr = one] : one \in Sample(20) }
        \cup { [ZeroSecuritiesMemberInformationMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Securities Treasury Stocks Batch Message: 130 bytes                     *)
(***************************************************************************)

SecuritiesTreasuryStocksBatchMessage ==
    [ messageSequenceNumber                     : Sample(8),
      isinCode                                  : Sample(12),
      treasuryStockReportId                     : Sample(5),
      treasuryStockAskBidTypeCode               : Sample(1),
      treasuryStockApplicationDate              : Sample(8),
      treasuryStockTradingStartDate             : Sample(8),
      treasuryStockTradingEndDate               : Sample(8),
      trearsuryStockTradingMethodTypeCode       : Sample(1),
      marketParticipantNumber                   : Sample(5),
      buyingVolumeOpenSinglePriceSession        : Sample(12),
      buyingVolumeRegularSession                : Sample(12),
      buyingVolumeBlockTradingInOffHoursSession : Sample(12),
      accumulatedTradingQuantity                : Sample(15),
      accumulatedTradingValue                   : Sample(22),
      endKeyword                                : Sample(1) ]

EncodeSecuritiesTreasuryStocksBatchMessage(message) ==
    message.messageSequenceNumber
        \o message.isinCode
        \o message.treasuryStockReportId
        \o message.treasuryStockAskBidTypeCode
        \o message.treasuryStockApplicationDate
        \o message.treasuryStockTradingStartDate
        \o message.treasuryStockTradingEndDate
        \o message.trearsuryStockTradingMethodTypeCode
        \o message.marketParticipantNumber
        \o message.buyingVolumeOpenSinglePriceSession
        \o message.buyingVolumeRegularSession
        \o message.buyingVolumeBlockTradingInOffHoursSession
        \o message.accumulatedTradingQuantity
        \o message.accumulatedTradingValue
        \o message.endKeyword

DecodeSecuritiesTreasuryStocksBatchMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET isinCode == ReadBytes(messageSequenceNumber.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET treasuryStockReportId == ReadBytes(isinCode.rest, 5) IN IF ~treasuryStockReportId.ok THEN Fail ELSE
    LET treasuryStockAskBidTypeCode == ReadBytes(treasuryStockReportId.rest, 1) IN IF ~treasuryStockAskBidTypeCode.ok THEN Fail ELSE
    LET treasuryStockApplicationDate == ReadBytes(treasuryStockAskBidTypeCode.rest, 8) IN IF ~treasuryStockApplicationDate.ok THEN Fail ELSE
    LET treasuryStockTradingStartDate == ReadBytes(treasuryStockApplicationDate.rest, 8) IN IF ~treasuryStockTradingStartDate.ok THEN Fail ELSE
    LET treasuryStockTradingEndDate == ReadBytes(treasuryStockTradingStartDate.rest, 8) IN IF ~treasuryStockTradingEndDate.ok THEN Fail ELSE
    LET trearsuryStockTradingMethodTypeCode == ReadBytes(treasuryStockTradingEndDate.rest, 1) IN IF ~trearsuryStockTradingMethodTypeCode.ok THEN Fail ELSE
    LET marketParticipantNumber == ReadBytes(trearsuryStockTradingMethodTypeCode.rest, 5) IN IF ~marketParticipantNumber.ok THEN Fail ELSE
    LET buyingVolumeOpenSinglePriceSession == ReadBytes(marketParticipantNumber.rest, 12) IN IF ~buyingVolumeOpenSinglePriceSession.ok THEN Fail ELSE
    LET buyingVolumeRegularSession == ReadBytes(buyingVolumeOpenSinglePriceSession.rest, 12) IN IF ~buyingVolumeRegularSession.ok THEN Fail ELSE
    LET buyingVolumeBlockTradingInOffHoursSession == ReadBytes(buyingVolumeRegularSession.rest, 12) IN IF ~buyingVolumeBlockTradingInOffHoursSession.ok THEN Fail ELSE
    LET accumulatedTradingQuantity == ReadBytes(buyingVolumeBlockTradingInOffHoursSession.rest, 15) IN IF ~accumulatedTradingQuantity.ok THEN Fail ELSE
    LET accumulatedTradingValue == ReadBytes(accumulatedTradingQuantity.rest, 22) IN IF ~accumulatedTradingValue.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(accumulatedTradingValue.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber                     |-> messageSequenceNumber.value,
         isinCode                                  |-> isinCode.value,
         treasuryStockReportId                     |-> treasuryStockReportId.value,
         treasuryStockAskBidTypeCode               |-> treasuryStockAskBidTypeCode.value,
         treasuryStockApplicationDate              |-> treasuryStockApplicationDate.value,
         treasuryStockTradingStartDate             |-> treasuryStockTradingStartDate.value,
         treasuryStockTradingEndDate               |-> treasuryStockTradingEndDate.value,
         trearsuryStockTradingMethodTypeCode       |-> trearsuryStockTradingMethodTypeCode.value,
         marketParticipantNumber                   |-> marketParticipantNumber.value,
         buyingVolumeOpenSinglePriceSession        |-> buyingVolumeOpenSinglePriceSession.value,
         buyingVolumeRegularSession                |-> buyingVolumeRegularSession.value,
         buyingVolumeBlockTradingInOffHoursSession |-> buyingVolumeBlockTradingInOffHoursSession.value,
         accumulatedTradingQuantity                |-> accumulatedTradingQuantity.value,
         accumulatedTradingValue                   |-> accumulatedTradingValue.value,
         endKeyword                                |-> endKeyword.value ], endKeyword.rest)

ZeroSecuritiesTreasuryStocksBatchMessage ==
    [ messageSequenceNumber                     |-> [i \in 1 .. 8 |-> 0],
      isinCode                                  |-> [i \in 1 .. 12 |-> 0],
      treasuryStockReportId                     |-> [i \in 1 .. 5 |-> 0],
      treasuryStockAskBidTypeCode               |-> [i \in 1 .. 1 |-> 0],
      treasuryStockApplicationDate              |-> [i \in 1 .. 8 |-> 0],
      treasuryStockTradingStartDate             |-> [i \in 1 .. 8 |-> 0],
      treasuryStockTradingEndDate               |-> [i \in 1 .. 8 |-> 0],
      trearsuryStockTradingMethodTypeCode       |-> [i \in 1 .. 1 |-> 0],
      marketParticipantNumber                   |-> [i \in 1 .. 5 |-> 0],
      buyingVolumeOpenSinglePriceSession        |-> [i \in 1 .. 12 |-> 0],
      buyingVolumeRegularSession                |-> [i \in 1 .. 12 |-> 0],
      buyingVolumeBlockTradingInOffHoursSession |-> [i \in 1 .. 12 |-> 0],
      accumulatedTradingQuantity                |-> [i \in 1 .. 15 |-> 0],
      accumulatedTradingValue                   |-> [i \in 1 .. 22 |-> 0],
      endKeyword                                |-> [i \in 1 .. 1 |-> 0] ]

(* Securities Treasury Stocks Batch Message at zero, then each field in turn at the values it is checked at *)
CheckedSecuritiesTreasuryStocksBatchMessage ==
    { ZeroSecuritiesTreasuryStocksBatchMessage }
        \cup { [ZeroSecuritiesTreasuryStocksBatchMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesTreasuryStocksBatchMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesTreasuryStocksBatchMessage EXCEPT !.treasuryStockReportId = one] : one \in Sample(5) }
        \cup { [ZeroSecuritiesTreasuryStocksBatchMessage EXCEPT !.treasuryStockAskBidTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesTreasuryStocksBatchMessage EXCEPT !.treasuryStockApplicationDate = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesTreasuryStocksBatchMessage EXCEPT !.treasuryStockTradingStartDate = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesTreasuryStocksBatchMessage EXCEPT !.treasuryStockTradingEndDate = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesTreasuryStocksBatchMessage EXCEPT !.trearsuryStockTradingMethodTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesTreasuryStocksBatchMessage EXCEPT !.marketParticipantNumber = one] : one \in Sample(5) }
        \cup { [ZeroSecuritiesTreasuryStocksBatchMessage EXCEPT !.buyingVolumeOpenSinglePriceSession = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesTreasuryStocksBatchMessage EXCEPT !.buyingVolumeRegularSession = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesTreasuryStocksBatchMessage EXCEPT !.buyingVolumeBlockTradingInOffHoursSession = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesTreasuryStocksBatchMessage EXCEPT !.accumulatedTradingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroSecuritiesTreasuryStocksBatchMessage EXCEPT !.accumulatedTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroSecuritiesTreasuryStocksBatchMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Securities Equity Index Indicator Message: 180 bytes                    *)
(***************************************************************************)

SecuritiesEquityIndexIndicatorMessage ==
    [ messageSequenceNumber          : Sample(8),
      isinCode                       : Sample(12),
      aDesignatedNumberForAnIssue    : Sample(6),
      securityGroupId                : Sample(2),
      epsCalculation                 : Sample(1),
      eps                            : Sample(22),
      lossCategory                   : Sample(1),
      per                            : Sample(13),
      bpsCalculation                 : Sample(1),
      bps                            : Sample(22),
      pbr                            : Sample(13),
      dpsCalculation                 : Sample(1),
      dps                            : Sample(22),
      dividendYield                  : Sample(13),
      marketCapitalizationTypeCode   : Sample(1),
      filler1                        : Sample(1),
      indexClassificationLevel1      : Sample(6),
      indexClassificationLevel2      : Sample(6),
      indexClassificationLevel3      : Sample(6),
      kospi200SectorCode1            : Sample(1),
      kospi200SectorCode2            : Sample(1),
      kospi                          : Sample(1),
      kosdaq                         : Sample(1),
      kospi100                       : Sample(1),
      kospi50                        : Sample(1),
      kosdaq150                      : Sample(1),
      krx100                         : Sample(1),
      krx300                         : Sample(1),
      kospi200HighDividendYieldIndex : Sample(1),
      krxBbigIndex                   : Sample(1),
      krxSecondaryBatteryTop10Index  : Sample(1),
      krxBioTop10Index               : Sample(1),
      koreaValueUpIndex              : Sample(1),
      filler8                        : Sample(8),
      endKeyword                     : Sample(1) ]

EncodeSecuritiesEquityIndexIndicatorMessage(message) ==
    message.messageSequenceNumber
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.securityGroupId
        \o message.epsCalculation
        \o message.eps
        \o message.lossCategory
        \o message.per
        \o message.bpsCalculation
        \o message.bps
        \o message.pbr
        \o message.dpsCalculation
        \o message.dps
        \o message.dividendYield
        \o message.marketCapitalizationTypeCode
        \o message.filler1
        \o message.indexClassificationLevel1
        \o message.indexClassificationLevel2
        \o message.indexClassificationLevel3
        \o message.kospi200SectorCode1
        \o message.kospi200SectorCode2
        \o message.kospi
        \o message.kosdaq
        \o message.kospi100
        \o message.kospi50
        \o message.kosdaq150
        \o message.krx100
        \o message.krx300
        \o message.kospi200HighDividendYieldIndex
        \o message.krxBbigIndex
        \o message.krxSecondaryBatteryTop10Index
        \o message.krxBioTop10Index
        \o message.koreaValueUpIndex
        \o message.filler8
        \o message.endKeyword

DecodeSecuritiesEquityIndexIndicatorMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET isinCode == ReadBytes(messageSequenceNumber.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET securityGroupId == ReadBytes(aDesignatedNumberForAnIssue.rest, 2) IN IF ~securityGroupId.ok THEN Fail ELSE
    LET epsCalculation == ReadBytes(securityGroupId.rest, 1) IN IF ~epsCalculation.ok THEN Fail ELSE
    LET eps == ReadBytes(epsCalculation.rest, 22) IN IF ~eps.ok THEN Fail ELSE
    LET lossCategory == ReadBytes(eps.rest, 1) IN IF ~lossCategory.ok THEN Fail ELSE
    LET per == ReadBytes(lossCategory.rest, 13) IN IF ~per.ok THEN Fail ELSE
    LET bpsCalculation == ReadBytes(per.rest, 1) IN IF ~bpsCalculation.ok THEN Fail ELSE
    LET bps == ReadBytes(bpsCalculation.rest, 22) IN IF ~bps.ok THEN Fail ELSE
    LET pbr == ReadBytes(bps.rest, 13) IN IF ~pbr.ok THEN Fail ELSE
    LET dpsCalculation == ReadBytes(pbr.rest, 1) IN IF ~dpsCalculation.ok THEN Fail ELSE
    LET dps == ReadBytes(dpsCalculation.rest, 22) IN IF ~dps.ok THEN Fail ELSE
    LET dividendYield == ReadBytes(dps.rest, 13) IN IF ~dividendYield.ok THEN Fail ELSE
    LET marketCapitalizationTypeCode == ReadBytes(dividendYield.rest, 1) IN IF ~marketCapitalizationTypeCode.ok THEN Fail ELSE
    LET filler1 == ReadBytes(marketCapitalizationTypeCode.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET indexClassificationLevel1 == ReadBytes(filler1.rest, 6) IN IF ~indexClassificationLevel1.ok THEN Fail ELSE
    LET indexClassificationLevel2 == ReadBytes(indexClassificationLevel1.rest, 6) IN IF ~indexClassificationLevel2.ok THEN Fail ELSE
    LET indexClassificationLevel3 == ReadBytes(indexClassificationLevel2.rest, 6) IN IF ~indexClassificationLevel3.ok THEN Fail ELSE
    LET kospi200SectorCode1 == ReadBytes(indexClassificationLevel3.rest, 1) IN IF ~kospi200SectorCode1.ok THEN Fail ELSE
    LET kospi200SectorCode2 == ReadBytes(kospi200SectorCode1.rest, 1) IN IF ~kospi200SectorCode2.ok THEN Fail ELSE
    LET kospi == ReadBytes(kospi200SectorCode2.rest, 1) IN IF ~kospi.ok THEN Fail ELSE
    LET kosdaq == ReadBytes(kospi.rest, 1) IN IF ~kosdaq.ok THEN Fail ELSE
    LET kospi100 == ReadBytes(kosdaq.rest, 1) IN IF ~kospi100.ok THEN Fail ELSE
    LET kospi50 == ReadBytes(kospi100.rest, 1) IN IF ~kospi50.ok THEN Fail ELSE
    LET kosdaq150 == ReadBytes(kospi50.rest, 1) IN IF ~kosdaq150.ok THEN Fail ELSE
    LET krx100 == ReadBytes(kosdaq150.rest, 1) IN IF ~krx100.ok THEN Fail ELSE
    LET krx300 == ReadBytes(krx100.rest, 1) IN IF ~krx300.ok THEN Fail ELSE
    LET kospi200HighDividendYieldIndex == ReadBytes(krx300.rest, 1) IN IF ~kospi200HighDividendYieldIndex.ok THEN Fail ELSE
    LET krxBbigIndex == ReadBytes(kospi200HighDividendYieldIndex.rest, 1) IN IF ~krxBbigIndex.ok THEN Fail ELSE
    LET krxSecondaryBatteryTop10Index == ReadBytes(krxBbigIndex.rest, 1) IN IF ~krxSecondaryBatteryTop10Index.ok THEN Fail ELSE
    LET krxBioTop10Index == ReadBytes(krxSecondaryBatteryTop10Index.rest, 1) IN IF ~krxBioTop10Index.ok THEN Fail ELSE
    LET koreaValueUpIndex == ReadBytes(krxBioTop10Index.rest, 1) IN IF ~koreaValueUpIndex.ok THEN Fail ELSE
    LET filler8 == ReadBytes(koreaValueUpIndex.rest, 8) IN IF ~filler8.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler8.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber          |-> messageSequenceNumber.value,
         isinCode                       |-> isinCode.value,
         aDesignatedNumberForAnIssue    |-> aDesignatedNumberForAnIssue.value,
         securityGroupId                |-> securityGroupId.value,
         epsCalculation                 |-> epsCalculation.value,
         eps                            |-> eps.value,
         lossCategory                   |-> lossCategory.value,
         per                            |-> per.value,
         bpsCalculation                 |-> bpsCalculation.value,
         bps                            |-> bps.value,
         pbr                            |-> pbr.value,
         dpsCalculation                 |-> dpsCalculation.value,
         dps                            |-> dps.value,
         dividendYield                  |-> dividendYield.value,
         marketCapitalizationTypeCode   |-> marketCapitalizationTypeCode.value,
         filler1                        |-> filler1.value,
         indexClassificationLevel1      |-> indexClassificationLevel1.value,
         indexClassificationLevel2      |-> indexClassificationLevel2.value,
         indexClassificationLevel3      |-> indexClassificationLevel3.value,
         kospi200SectorCode1            |-> kospi200SectorCode1.value,
         kospi200SectorCode2            |-> kospi200SectorCode2.value,
         kospi                          |-> kospi.value,
         kosdaq                         |-> kosdaq.value,
         kospi100                       |-> kospi100.value,
         kospi50                        |-> kospi50.value,
         kosdaq150                      |-> kosdaq150.value,
         krx100                         |-> krx100.value,
         krx300                         |-> krx300.value,
         kospi200HighDividendYieldIndex |-> kospi200HighDividendYieldIndex.value,
         krxBbigIndex                   |-> krxBbigIndex.value,
         krxSecondaryBatteryTop10Index  |-> krxSecondaryBatteryTop10Index.value,
         krxBioTop10Index               |-> krxBioTop10Index.value,
         koreaValueUpIndex              |-> koreaValueUpIndex.value,
         filler8                        |-> filler8.value,
         endKeyword                     |-> endKeyword.value ], endKeyword.rest)

ZeroSecuritiesEquityIndexIndicatorMessage ==
    [ messageSequenceNumber          |-> [i \in 1 .. 8 |-> 0],
      isinCode                       |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue    |-> [i \in 1 .. 6 |-> 0],
      securityGroupId                |-> [i \in 1 .. 2 |-> 0],
      epsCalculation                 |-> [i \in 1 .. 1 |-> 0],
      eps                            |-> [i \in 1 .. 22 |-> 0],
      lossCategory                   |-> [i \in 1 .. 1 |-> 0],
      per                            |-> [i \in 1 .. 13 |-> 0],
      bpsCalculation                 |-> [i \in 1 .. 1 |-> 0],
      bps                            |-> [i \in 1 .. 22 |-> 0],
      pbr                            |-> [i \in 1 .. 13 |-> 0],
      dpsCalculation                 |-> [i \in 1 .. 1 |-> 0],
      dps                            |-> [i \in 1 .. 22 |-> 0],
      dividendYield                  |-> [i \in 1 .. 13 |-> 0],
      marketCapitalizationTypeCode   |-> [i \in 1 .. 1 |-> 0],
      filler1                        |-> [i \in 1 .. 1 |-> 0],
      indexClassificationLevel1      |-> [i \in 1 .. 6 |-> 0],
      indexClassificationLevel2      |-> [i \in 1 .. 6 |-> 0],
      indexClassificationLevel3      |-> [i \in 1 .. 6 |-> 0],
      kospi200SectorCode1            |-> [i \in 1 .. 1 |-> 0],
      kospi200SectorCode2            |-> [i \in 1 .. 1 |-> 0],
      kospi                          |-> [i \in 1 .. 1 |-> 0],
      kosdaq                         |-> [i \in 1 .. 1 |-> 0],
      kospi100                       |-> [i \in 1 .. 1 |-> 0],
      kospi50                        |-> [i \in 1 .. 1 |-> 0],
      kosdaq150                      |-> [i \in 1 .. 1 |-> 0],
      krx100                         |-> [i \in 1 .. 1 |-> 0],
      krx300                         |-> [i \in 1 .. 1 |-> 0],
      kospi200HighDividendYieldIndex |-> [i \in 1 .. 1 |-> 0],
      krxBbigIndex                   |-> [i \in 1 .. 1 |-> 0],
      krxSecondaryBatteryTop10Index  |-> [i \in 1 .. 1 |-> 0],
      krxBioTop10Index               |-> [i \in 1 .. 1 |-> 0],
      koreaValueUpIndex              |-> [i \in 1 .. 1 |-> 0],
      filler8                        |-> [i \in 1 .. 8 |-> 0],
      endKeyword                     |-> [i \in 1 .. 1 |-> 0] ]

(* Securities Equity Index Indicator Message at zero, then each field in turn at the values it is checked at *)
CheckedSecuritiesEquityIndexIndicatorMessage ==
    { ZeroSecuritiesEquityIndexIndicatorMessage }
        \cup { [ZeroSecuritiesEquityIndexIndicatorMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesEquityIndexIndicatorMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesEquityIndexIndicatorMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroSecuritiesEquityIndexIndicatorMessage EXCEPT !.securityGroupId = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesEquityIndexIndicatorMessage EXCEPT !.epsCalculation = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquityIndexIndicatorMessage EXCEPT !.eps = one] : one \in Sample(22) }
        \cup { [ZeroSecuritiesEquityIndexIndicatorMessage EXCEPT !.lossCategory = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquityIndexIndicatorMessage EXCEPT !.per = one] : one \in Sample(13) }
        \cup { [ZeroSecuritiesEquityIndexIndicatorMessage EXCEPT !.bpsCalculation = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquityIndexIndicatorMessage EXCEPT !.bps = one] : one \in Sample(22) }
        \cup { [ZeroSecuritiesEquityIndexIndicatorMessage EXCEPT !.pbr = one] : one \in Sample(13) }
        \cup { [ZeroSecuritiesEquityIndexIndicatorMessage EXCEPT !.dpsCalculation = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquityIndexIndicatorMessage EXCEPT !.dps = one] : one \in Sample(22) }
        \cup { [ZeroSecuritiesEquityIndexIndicatorMessage EXCEPT !.dividendYield = one] : one \in Sample(13) }
        \cup { [ZeroSecuritiesEquityIndexIndicatorMessage EXCEPT !.marketCapitalizationTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquityIndexIndicatorMessage EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquityIndexIndicatorMessage EXCEPT !.indexClassificationLevel1 = one] : one \in Sample(6) }
        \cup { [ZeroSecuritiesEquityIndexIndicatorMessage EXCEPT !.indexClassificationLevel2 = one] : one \in Sample(6) }
        \cup { [ZeroSecuritiesEquityIndexIndicatorMessage EXCEPT !.indexClassificationLevel3 = one] : one \in Sample(6) }
        \cup { [ZeroSecuritiesEquityIndexIndicatorMessage EXCEPT !.kospi200SectorCode1 = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquityIndexIndicatorMessage EXCEPT !.kospi200SectorCode2 = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquityIndexIndicatorMessage EXCEPT !.kospi = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquityIndexIndicatorMessage EXCEPT !.kosdaq = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquityIndexIndicatorMessage EXCEPT !.kospi100 = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquityIndexIndicatorMessage EXCEPT !.kospi50 = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquityIndexIndicatorMessage EXCEPT !.kosdaq150 = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquityIndexIndicatorMessage EXCEPT !.krx100 = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquityIndexIndicatorMessage EXCEPT !.krx300 = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquityIndexIndicatorMessage EXCEPT !.kospi200HighDividendYieldIndex = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquityIndexIndicatorMessage EXCEPT !.krxBbigIndex = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquityIndexIndicatorMessage EXCEPT !.krxSecondaryBatteryTop10Index = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquityIndexIndicatorMessage EXCEPT !.krxBioTop10Index = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquityIndexIndicatorMessage EXCEPT !.koreaValueUpIndex = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquityIndexIndicatorMessage EXCEPT !.filler8 = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesEquityIndexIndicatorMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Securities Dividend Yield Per Industry Message: 31 bytes                *)
(***************************************************************************)

SecuritiesDividendYieldPerIndustryMessage ==
    [ messageSequenceNumber : Sample(8),
      indexId               : Sample(6),
      dividendYield         : Sample(13),
      filler3               : Sample(3),
      endKeyword            : Sample(1) ]

EncodeSecuritiesDividendYieldPerIndustryMessage(message) ==
    message.messageSequenceNumber
        \o message.indexId
        \o message.dividendYield
        \o message.filler3
        \o message.endKeyword

DecodeSecuritiesDividendYieldPerIndustryMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET indexId == ReadBytes(messageSequenceNumber.rest, 6) IN IF ~indexId.ok THEN Fail ELSE
    LET dividendYield == ReadBytes(indexId.rest, 13) IN IF ~dividendYield.ok THEN Fail ELSE
    LET filler3 == ReadBytes(dividendYield.rest, 3) IN IF ~filler3.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler3.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber |-> messageSequenceNumber.value,
         indexId               |-> indexId.value,
         dividendYield         |-> dividendYield.value,
         filler3               |-> filler3.value,
         endKeyword            |-> endKeyword.value ], endKeyword.rest)

ZeroSecuritiesDividendYieldPerIndustryMessage ==
    [ messageSequenceNumber |-> [i \in 1 .. 8 |-> 0],
      indexId               |-> [i \in 1 .. 6 |-> 0],
      dividendYield         |-> [i \in 1 .. 13 |-> 0],
      filler3               |-> [i \in 1 .. 3 |-> 0],
      endKeyword            |-> [i \in 1 .. 1 |-> 0] ]

(* Securities Dividend Yield Per Industry Message at zero, then each field in turn at the values it is checked at *)
CheckedSecuritiesDividendYieldPerIndustryMessage ==
    { ZeroSecuritiesDividendYieldPerIndustryMessage }
        \cup { [ZeroSecuritiesDividendYieldPerIndustryMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesDividendYieldPerIndustryMessage EXCEPT !.indexId = one] : one \in Sample(6) }
        \cup { [ZeroSecuritiesDividendYieldPerIndustryMessage EXCEPT !.dividendYield = one] : one \in Sample(13) }
        \cup { [ZeroSecuritiesDividendYieldPerIndustryMessage EXCEPT !.filler3 = one] : one \in Sample(3) }
        \cup { [ZeroSecuritiesDividendYieldPerIndustryMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Bonds Batch Data Message: 303 bytes                                     *)
(***************************************************************************)

BondsBatchDataMessage ==
    [ messageSequenceNumber                 : Sample(8),
      totalNumberOfInstrumentsOfTheContract : Sample(6),
      businessDate                          : Sample(8),
      isinCode                              : Sample(12),
      aDesignatedNumberForAnIssue           : Sample(6),
      retailBondTypeCode                    : Sample(2),
      abbreviatedIssueName                  : Sample(40),
      abbreviatedIssueNameInEn              : Sample(40),
      marketOperationProductId              : Sample(3),
      bondListingTypeCode                   : Sample(1),
      bondCategoryCode                      : Sample(6),
      bondGuaranteedTypeCode                : Sample(1),
      couponPaymentTypeCode                 : Sample(2),
      listingDate                           : Sample(8),
      issueDate                             : Sample(8),
      redemptionDate                        : Sample(8),
      saleDate                              : Sample(8),
      bondIssuanceRate                      : Sample(13),
      couponRate                            : Sample(14),
      monthlyCycleOfCouponPayment           : Sample(4),
      couponPaymentTimingCode               : Sample(1),
      interestPayment                       : Sample(1),
      couponPaymentDateTypeCode             : Sample(1),
      decimalPointOfCouponTypeCode          : Sample(1),
      preIssueSaleCouponPaymentTypeCode     : Sample(1),
      issuingAmount                         : Sample(22),
      listedAmount                          : Sample(22),
      redemptionRatioAtMaturity             : Sample(13),
      amortizationTypeCode                  : Sample(1),
      numberOfMonthsForGrace                : Sample(4),
      numberOfAmortization                  : Sample(5),
      tradingHalt                           : Sample(1),
      priorCouponPaymentDate                : Sample(8),
      nextCouponPaymentDate                 : Sample(8),
      perpetualBondMaturityStructureStatus  : Sample(1),
      stripBondTypeCode                     : Sample(1),
      basePrice                             : Sample(11),
      liquidationTrade                      : Sample(1),
      investmentCautionBondTypeCode         : Sample(1),
      endKeyword                            : Sample(1) ]

EncodeBondsBatchDataMessage(message) ==
    message.messageSequenceNumber
        \o message.totalNumberOfInstrumentsOfTheContract
        \o message.businessDate
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.retailBondTypeCode
        \o message.abbreviatedIssueName
        \o message.abbreviatedIssueNameInEn
        \o message.marketOperationProductId
        \o message.bondListingTypeCode
        \o message.bondCategoryCode
        \o message.bondGuaranteedTypeCode
        \o message.couponPaymentTypeCode
        \o message.listingDate
        \o message.issueDate
        \o message.redemptionDate
        \o message.saleDate
        \o message.bondIssuanceRate
        \o message.couponRate
        \o message.monthlyCycleOfCouponPayment
        \o message.couponPaymentTimingCode
        \o message.interestPayment
        \o message.couponPaymentDateTypeCode
        \o message.decimalPointOfCouponTypeCode
        \o message.preIssueSaleCouponPaymentTypeCode
        \o message.issuingAmount
        \o message.listedAmount
        \o message.redemptionRatioAtMaturity
        \o message.amortizationTypeCode
        \o message.numberOfMonthsForGrace
        \o message.numberOfAmortization
        \o message.tradingHalt
        \o message.priorCouponPaymentDate
        \o message.nextCouponPaymentDate
        \o message.perpetualBondMaturityStructureStatus
        \o message.stripBondTypeCode
        \o message.basePrice
        \o message.liquidationTrade
        \o message.investmentCautionBondTypeCode
        \o message.endKeyword

DecodeBondsBatchDataMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET totalNumberOfInstrumentsOfTheContract == ReadBytes(messageSequenceNumber.rest, 6) IN IF ~totalNumberOfInstrumentsOfTheContract.ok THEN Fail ELSE
    LET businessDate == ReadBytes(totalNumberOfInstrumentsOfTheContract.rest, 8) IN IF ~businessDate.ok THEN Fail ELSE
    LET isinCode == ReadBytes(businessDate.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET retailBondTypeCode == ReadBytes(aDesignatedNumberForAnIssue.rest, 2) IN IF ~retailBondTypeCode.ok THEN Fail ELSE
    LET abbreviatedIssueName == ReadBytes(retailBondTypeCode.rest, 40) IN IF ~abbreviatedIssueName.ok THEN Fail ELSE
    LET abbreviatedIssueNameInEn == ReadBytes(abbreviatedIssueName.rest, 40) IN IF ~abbreviatedIssueNameInEn.ok THEN Fail ELSE
    LET marketOperationProductId == ReadBytes(abbreviatedIssueNameInEn.rest, 3) IN IF ~marketOperationProductId.ok THEN Fail ELSE
    LET bondListingTypeCode == ReadBytes(marketOperationProductId.rest, 1) IN IF ~bondListingTypeCode.ok THEN Fail ELSE
    LET bondCategoryCode == ReadBytes(bondListingTypeCode.rest, 6) IN IF ~bondCategoryCode.ok THEN Fail ELSE
    LET bondGuaranteedTypeCode == ReadBytes(bondCategoryCode.rest, 1) IN IF ~bondGuaranteedTypeCode.ok THEN Fail ELSE
    LET couponPaymentTypeCode == ReadBytes(bondGuaranteedTypeCode.rest, 2) IN IF ~couponPaymentTypeCode.ok THEN Fail ELSE
    LET listingDate == ReadBytes(couponPaymentTypeCode.rest, 8) IN IF ~listingDate.ok THEN Fail ELSE
    LET issueDate == ReadBytes(listingDate.rest, 8) IN IF ~issueDate.ok THEN Fail ELSE
    LET redemptionDate == ReadBytes(issueDate.rest, 8) IN IF ~redemptionDate.ok THEN Fail ELSE
    LET saleDate == ReadBytes(redemptionDate.rest, 8) IN IF ~saleDate.ok THEN Fail ELSE
    LET bondIssuanceRate == ReadBytes(saleDate.rest, 13) IN IF ~bondIssuanceRate.ok THEN Fail ELSE
    LET couponRate == ReadBytes(bondIssuanceRate.rest, 14) IN IF ~couponRate.ok THEN Fail ELSE
    LET monthlyCycleOfCouponPayment == ReadBytes(couponRate.rest, 4) IN IF ~monthlyCycleOfCouponPayment.ok THEN Fail ELSE
    LET couponPaymentTimingCode == ReadBytes(monthlyCycleOfCouponPayment.rest, 1) IN IF ~couponPaymentTimingCode.ok THEN Fail ELSE
    LET interestPayment == ReadBytes(couponPaymentTimingCode.rest, 1) IN IF ~interestPayment.ok THEN Fail ELSE
    LET couponPaymentDateTypeCode == ReadBytes(interestPayment.rest, 1) IN IF ~couponPaymentDateTypeCode.ok THEN Fail ELSE
    LET decimalPointOfCouponTypeCode == ReadBytes(couponPaymentDateTypeCode.rest, 1) IN IF ~decimalPointOfCouponTypeCode.ok THEN Fail ELSE
    LET preIssueSaleCouponPaymentTypeCode == ReadBytes(decimalPointOfCouponTypeCode.rest, 1) IN IF ~preIssueSaleCouponPaymentTypeCode.ok THEN Fail ELSE
    LET issuingAmount == ReadBytes(preIssueSaleCouponPaymentTypeCode.rest, 22) IN IF ~issuingAmount.ok THEN Fail ELSE
    LET listedAmount == ReadBytes(issuingAmount.rest, 22) IN IF ~listedAmount.ok THEN Fail ELSE
    LET redemptionRatioAtMaturity == ReadBytes(listedAmount.rest, 13) IN IF ~redemptionRatioAtMaturity.ok THEN Fail ELSE
    LET amortizationTypeCode == ReadBytes(redemptionRatioAtMaturity.rest, 1) IN IF ~amortizationTypeCode.ok THEN Fail ELSE
    LET numberOfMonthsForGrace == ReadBytes(amortizationTypeCode.rest, 4) IN IF ~numberOfMonthsForGrace.ok THEN Fail ELSE
    LET numberOfAmortization == ReadBytes(numberOfMonthsForGrace.rest, 5) IN IF ~numberOfAmortization.ok THEN Fail ELSE
    LET tradingHalt == ReadBytes(numberOfAmortization.rest, 1) IN IF ~tradingHalt.ok THEN Fail ELSE
    LET priorCouponPaymentDate == ReadBytes(tradingHalt.rest, 8) IN IF ~priorCouponPaymentDate.ok THEN Fail ELSE
    LET nextCouponPaymentDate == ReadBytes(priorCouponPaymentDate.rest, 8) IN IF ~nextCouponPaymentDate.ok THEN Fail ELSE
    LET perpetualBondMaturityStructureStatus == ReadBytes(nextCouponPaymentDate.rest, 1) IN IF ~perpetualBondMaturityStructureStatus.ok THEN Fail ELSE
    LET stripBondTypeCode == ReadBytes(perpetualBondMaturityStructureStatus.rest, 1) IN IF ~stripBondTypeCode.ok THEN Fail ELSE
    LET basePrice == ReadBytes(stripBondTypeCode.rest, 11) IN IF ~basePrice.ok THEN Fail ELSE
    LET liquidationTrade == ReadBytes(basePrice.rest, 1) IN IF ~liquidationTrade.ok THEN Fail ELSE
    LET investmentCautionBondTypeCode == ReadBytes(liquidationTrade.rest, 1) IN IF ~investmentCautionBondTypeCode.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(investmentCautionBondTypeCode.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber                 |-> messageSequenceNumber.value,
         totalNumberOfInstrumentsOfTheContract |-> totalNumberOfInstrumentsOfTheContract.value,
         businessDate                          |-> businessDate.value,
         isinCode                              |-> isinCode.value,
         aDesignatedNumberForAnIssue           |-> aDesignatedNumberForAnIssue.value,
         retailBondTypeCode                    |-> retailBondTypeCode.value,
         abbreviatedIssueName                  |-> abbreviatedIssueName.value,
         abbreviatedIssueNameInEn              |-> abbreviatedIssueNameInEn.value,
         marketOperationProductId              |-> marketOperationProductId.value,
         bondListingTypeCode                   |-> bondListingTypeCode.value,
         bondCategoryCode                      |-> bondCategoryCode.value,
         bondGuaranteedTypeCode                |-> bondGuaranteedTypeCode.value,
         couponPaymentTypeCode                 |-> couponPaymentTypeCode.value,
         listingDate                           |-> listingDate.value,
         issueDate                             |-> issueDate.value,
         redemptionDate                        |-> redemptionDate.value,
         saleDate                              |-> saleDate.value,
         bondIssuanceRate                      |-> bondIssuanceRate.value,
         couponRate                            |-> couponRate.value,
         monthlyCycleOfCouponPayment           |-> monthlyCycleOfCouponPayment.value,
         couponPaymentTimingCode               |-> couponPaymentTimingCode.value,
         interestPayment                       |-> interestPayment.value,
         couponPaymentDateTypeCode             |-> couponPaymentDateTypeCode.value,
         decimalPointOfCouponTypeCode          |-> decimalPointOfCouponTypeCode.value,
         preIssueSaleCouponPaymentTypeCode     |-> preIssueSaleCouponPaymentTypeCode.value,
         issuingAmount                         |-> issuingAmount.value,
         listedAmount                          |-> listedAmount.value,
         redemptionRatioAtMaturity             |-> redemptionRatioAtMaturity.value,
         amortizationTypeCode                  |-> amortizationTypeCode.value,
         numberOfMonthsForGrace                |-> numberOfMonthsForGrace.value,
         numberOfAmortization                  |-> numberOfAmortization.value,
         tradingHalt                           |-> tradingHalt.value,
         priorCouponPaymentDate                |-> priorCouponPaymentDate.value,
         nextCouponPaymentDate                 |-> nextCouponPaymentDate.value,
         perpetualBondMaturityStructureStatus  |-> perpetualBondMaturityStructureStatus.value,
         stripBondTypeCode                     |-> stripBondTypeCode.value,
         basePrice                             |-> basePrice.value,
         liquidationTrade                      |-> liquidationTrade.value,
         investmentCautionBondTypeCode         |-> investmentCautionBondTypeCode.value,
         endKeyword                            |-> endKeyword.value ], endKeyword.rest)

ZeroBondsBatchDataMessage ==
    [ messageSequenceNumber                 |-> [i \in 1 .. 8 |-> 0],
      totalNumberOfInstrumentsOfTheContract |-> [i \in 1 .. 6 |-> 0],
      businessDate                          |-> [i \in 1 .. 8 |-> 0],
      isinCode                              |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue           |-> [i \in 1 .. 6 |-> 0],
      retailBondTypeCode                    |-> [i \in 1 .. 2 |-> 0],
      abbreviatedIssueName                  |-> [i \in 1 .. 40 |-> 0],
      abbreviatedIssueNameInEn              |-> [i \in 1 .. 40 |-> 0],
      marketOperationProductId              |-> [i \in 1 .. 3 |-> 0],
      bondListingTypeCode                   |-> [i \in 1 .. 1 |-> 0],
      bondCategoryCode                      |-> [i \in 1 .. 6 |-> 0],
      bondGuaranteedTypeCode                |-> [i \in 1 .. 1 |-> 0],
      couponPaymentTypeCode                 |-> [i \in 1 .. 2 |-> 0],
      listingDate                           |-> [i \in 1 .. 8 |-> 0],
      issueDate                             |-> [i \in 1 .. 8 |-> 0],
      redemptionDate                        |-> [i \in 1 .. 8 |-> 0],
      saleDate                              |-> [i \in 1 .. 8 |-> 0],
      bondIssuanceRate                      |-> [i \in 1 .. 13 |-> 0],
      couponRate                            |-> [i \in 1 .. 14 |-> 0],
      monthlyCycleOfCouponPayment           |-> [i \in 1 .. 4 |-> 0],
      couponPaymentTimingCode               |-> [i \in 1 .. 1 |-> 0],
      interestPayment                       |-> [i \in 1 .. 1 |-> 0],
      couponPaymentDateTypeCode             |-> [i \in 1 .. 1 |-> 0],
      decimalPointOfCouponTypeCode          |-> [i \in 1 .. 1 |-> 0],
      preIssueSaleCouponPaymentTypeCode     |-> [i \in 1 .. 1 |-> 0],
      issuingAmount                         |-> [i \in 1 .. 22 |-> 0],
      listedAmount                          |-> [i \in 1 .. 22 |-> 0],
      redemptionRatioAtMaturity             |-> [i \in 1 .. 13 |-> 0],
      amortizationTypeCode                  |-> [i \in 1 .. 1 |-> 0],
      numberOfMonthsForGrace                |-> [i \in 1 .. 4 |-> 0],
      numberOfAmortization                  |-> [i \in 1 .. 5 |-> 0],
      tradingHalt                           |-> [i \in 1 .. 1 |-> 0],
      priorCouponPaymentDate                |-> [i \in 1 .. 8 |-> 0],
      nextCouponPaymentDate                 |-> [i \in 1 .. 8 |-> 0],
      perpetualBondMaturityStructureStatus  |-> [i \in 1 .. 1 |-> 0],
      stripBondTypeCode                     |-> [i \in 1 .. 1 |-> 0],
      basePrice                             |-> [i \in 1 .. 11 |-> 0],
      liquidationTrade                      |-> [i \in 1 .. 1 |-> 0],
      investmentCautionBondTypeCode         |-> [i \in 1 .. 1 |-> 0],
      endKeyword                            |-> [i \in 1 .. 1 |-> 0] ]

(* Bonds Batch Data Message at zero, then each field in turn at the values it is checked at *)
CheckedBondsBatchDataMessage ==
    { ZeroBondsBatchDataMessage }
        \cup { [ZeroBondsBatchDataMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroBondsBatchDataMessage EXCEPT !.totalNumberOfInstrumentsOfTheContract = one] : one \in Sample(6) }
        \cup { [ZeroBondsBatchDataMessage EXCEPT !.businessDate = one] : one \in Sample(8) }
        \cup { [ZeroBondsBatchDataMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroBondsBatchDataMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroBondsBatchDataMessage EXCEPT !.retailBondTypeCode = one] : one \in Sample(2) }
        \cup { [ZeroBondsBatchDataMessage EXCEPT !.abbreviatedIssueName = one] : one \in Sample(40) }
        \cup { [ZeroBondsBatchDataMessage EXCEPT !.abbreviatedIssueNameInEn = one] : one \in Sample(40) }
        \cup { [ZeroBondsBatchDataMessage EXCEPT !.marketOperationProductId = one] : one \in Sample(3) }
        \cup { [ZeroBondsBatchDataMessage EXCEPT !.bondListingTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroBondsBatchDataMessage EXCEPT !.bondCategoryCode = one] : one \in Sample(6) }
        \cup { [ZeroBondsBatchDataMessage EXCEPT !.bondGuaranteedTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroBondsBatchDataMessage EXCEPT !.couponPaymentTypeCode = one] : one \in Sample(2) }
        \cup { [ZeroBondsBatchDataMessage EXCEPT !.listingDate = one] : one \in Sample(8) }
        \cup { [ZeroBondsBatchDataMessage EXCEPT !.issueDate = one] : one \in Sample(8) }
        \cup { [ZeroBondsBatchDataMessage EXCEPT !.redemptionDate = one] : one \in Sample(8) }
        \cup { [ZeroBondsBatchDataMessage EXCEPT !.saleDate = one] : one \in Sample(8) }
        \cup { [ZeroBondsBatchDataMessage EXCEPT !.bondIssuanceRate = one] : one \in Sample(13) }
        \cup { [ZeroBondsBatchDataMessage EXCEPT !.couponRate = one] : one \in Sample(14) }
        \cup { [ZeroBondsBatchDataMessage EXCEPT !.monthlyCycleOfCouponPayment = one] : one \in Sample(4) }
        \cup { [ZeroBondsBatchDataMessage EXCEPT !.couponPaymentTimingCode = one] : one \in Sample(1) }
        \cup { [ZeroBondsBatchDataMessage EXCEPT !.interestPayment = one] : one \in Sample(1) }
        \cup { [ZeroBondsBatchDataMessage EXCEPT !.couponPaymentDateTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroBondsBatchDataMessage EXCEPT !.decimalPointOfCouponTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroBondsBatchDataMessage EXCEPT !.preIssueSaleCouponPaymentTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroBondsBatchDataMessage EXCEPT !.issuingAmount = one] : one \in Sample(22) }
        \cup { [ZeroBondsBatchDataMessage EXCEPT !.listedAmount = one] : one \in Sample(22) }
        \cup { [ZeroBondsBatchDataMessage EXCEPT !.redemptionRatioAtMaturity = one] : one \in Sample(13) }
        \cup { [ZeroBondsBatchDataMessage EXCEPT !.amortizationTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroBondsBatchDataMessage EXCEPT !.numberOfMonthsForGrace = one] : one \in Sample(4) }
        \cup { [ZeroBondsBatchDataMessage EXCEPT !.numberOfAmortization = one] : one \in Sample(5) }
        \cup { [ZeroBondsBatchDataMessage EXCEPT !.tradingHalt = one] : one \in Sample(1) }
        \cup { [ZeroBondsBatchDataMessage EXCEPT !.priorCouponPaymentDate = one] : one \in Sample(8) }
        \cup { [ZeroBondsBatchDataMessage EXCEPT !.nextCouponPaymentDate = one] : one \in Sample(8) }
        \cup { [ZeroBondsBatchDataMessage EXCEPT !.perpetualBondMaturityStructureStatus = one] : one \in Sample(1) }
        \cup { [ZeroBondsBatchDataMessage EXCEPT !.stripBondTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroBondsBatchDataMessage EXCEPT !.basePrice = one] : one \in Sample(11) }
        \cup { [ZeroBondsBatchDataMessage EXCEPT !.liquidationTrade = one] : one \in Sample(1) }
        \cup { [ZeroBondsBatchDataMessage EXCEPT !.investmentCautionBondTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroBondsBatchDataMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Repo Batch Data Message: 95 bytes                                       *)
(***************************************************************************)

RepoBatchDataMessage ==
    [ messageSequenceNumber                 : Sample(8),
      totalNumberOfInstrumentsOfTheContract : Sample(6),
      businessDate                          : Sample(8),
      isinCode                              : Sample(12),
      aDesignatedNumberForAnIssue           : Sample(6),
      marketOperationProductId              : Sample(3),
      abbreviatedIssueName                  : Sample(40),
      marketValue                           : Sample(11),
      endKeyword                            : Sample(1) ]

EncodeRepoBatchDataMessage(message) ==
    message.messageSequenceNumber
        \o message.totalNumberOfInstrumentsOfTheContract
        \o message.businessDate
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.marketOperationProductId
        \o message.abbreviatedIssueName
        \o message.marketValue
        \o message.endKeyword

DecodeRepoBatchDataMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET totalNumberOfInstrumentsOfTheContract == ReadBytes(messageSequenceNumber.rest, 6) IN IF ~totalNumberOfInstrumentsOfTheContract.ok THEN Fail ELSE
    LET businessDate == ReadBytes(totalNumberOfInstrumentsOfTheContract.rest, 8) IN IF ~businessDate.ok THEN Fail ELSE
    LET isinCode == ReadBytes(businessDate.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET marketOperationProductId == ReadBytes(aDesignatedNumberForAnIssue.rest, 3) IN IF ~marketOperationProductId.ok THEN Fail ELSE
    LET abbreviatedIssueName == ReadBytes(marketOperationProductId.rest, 40) IN IF ~abbreviatedIssueName.ok THEN Fail ELSE
    LET marketValue == ReadBytes(abbreviatedIssueName.rest, 11) IN IF ~marketValue.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(marketValue.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber                 |-> messageSequenceNumber.value,
         totalNumberOfInstrumentsOfTheContract |-> totalNumberOfInstrumentsOfTheContract.value,
         businessDate                          |-> businessDate.value,
         isinCode                              |-> isinCode.value,
         aDesignatedNumberForAnIssue           |-> aDesignatedNumberForAnIssue.value,
         marketOperationProductId              |-> marketOperationProductId.value,
         abbreviatedIssueName                  |-> abbreviatedIssueName.value,
         marketValue                           |-> marketValue.value,
         endKeyword                            |-> endKeyword.value ], endKeyword.rest)

ZeroRepoBatchDataMessage ==
    [ messageSequenceNumber                 |-> [i \in 1 .. 8 |-> 0],
      totalNumberOfInstrumentsOfTheContract |-> [i \in 1 .. 6 |-> 0],
      businessDate                          |-> [i \in 1 .. 8 |-> 0],
      isinCode                              |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue           |-> [i \in 1 .. 6 |-> 0],
      marketOperationProductId              |-> [i \in 1 .. 3 |-> 0],
      abbreviatedIssueName                  |-> [i \in 1 .. 40 |-> 0],
      marketValue                           |-> [i \in 1 .. 11 |-> 0],
      endKeyword                            |-> [i \in 1 .. 1 |-> 0] ]

(* Repo Batch Data Message at zero, then each field in turn at the values it is checked at *)
CheckedRepoBatchDataMessage ==
    { ZeroRepoBatchDataMessage }
        \cup { [ZeroRepoBatchDataMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroRepoBatchDataMessage EXCEPT !.totalNumberOfInstrumentsOfTheContract = one] : one \in Sample(6) }
        \cup { [ZeroRepoBatchDataMessage EXCEPT !.businessDate = one] : one \in Sample(8) }
        \cup { [ZeroRepoBatchDataMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroRepoBatchDataMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroRepoBatchDataMessage EXCEPT !.marketOperationProductId = one] : one \in Sample(3) }
        \cup { [ZeroRepoBatchDataMessage EXCEPT !.abbreviatedIssueName = one] : one \in Sample(40) }
        \cup { [ZeroRepoBatchDataMessage EXCEPT !.marketValue = one] : one \in Sample(11) }
        \cup { [ZeroRepoBatchDataMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Issue Event Message: 43 bytes                                           *)
(***************************************************************************)

IssueEventMessage ==
    [ messageSequenceNumber : Sample(8),
      isinCode              : Sample(12),
      eventTypeCode         : Sample(2),
      eventReasonCode       : Sample(4),
      eventStartDate        : Sample(8),
      eventEndDate          : Sample(8),
      endKeyword            : Sample(1) ]

EncodeIssueEventMessage(message) ==
    message.messageSequenceNumber
        \o message.isinCode
        \o message.eventTypeCode
        \o message.eventReasonCode
        \o message.eventStartDate
        \o message.eventEndDate
        \o message.endKeyword

DecodeIssueEventMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET isinCode == ReadBytes(messageSequenceNumber.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET eventTypeCode == ReadBytes(isinCode.rest, 2) IN IF ~eventTypeCode.ok THEN Fail ELSE
    LET eventReasonCode == ReadBytes(eventTypeCode.rest, 4) IN IF ~eventReasonCode.ok THEN Fail ELSE
    LET eventStartDate == ReadBytes(eventReasonCode.rest, 8) IN IF ~eventStartDate.ok THEN Fail ELSE
    LET eventEndDate == ReadBytes(eventStartDate.rest, 8) IN IF ~eventEndDate.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(eventEndDate.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber |-> messageSequenceNumber.value,
         isinCode              |-> isinCode.value,
         eventTypeCode         |-> eventTypeCode.value,
         eventReasonCode       |-> eventReasonCode.value,
         eventStartDate        |-> eventStartDate.value,
         eventEndDate          |-> eventEndDate.value,
         endKeyword            |-> endKeyword.value ], endKeyword.rest)

ZeroIssueEventMessage ==
    [ messageSequenceNumber |-> [i \in 1 .. 8 |-> 0],
      isinCode              |-> [i \in 1 .. 12 |-> 0],
      eventTypeCode         |-> [i \in 1 .. 2 |-> 0],
      eventReasonCode       |-> [i \in 1 .. 4 |-> 0],
      eventStartDate        |-> [i \in 1 .. 8 |-> 0],
      eventEndDate          |-> [i \in 1 .. 8 |-> 0],
      endKeyword            |-> [i \in 1 .. 1 |-> 0] ]

(* Issue Event Message at zero, then each field in turn at the values it is checked at *)
CheckedIssueEventMessage ==
    { ZeroIssueEventMessage }
        \cup { [ZeroIssueEventMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroIssueEventMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroIssueEventMessage EXCEPT !.eventTypeCode = one] : one \in Sample(2) }
        \cup { [ZeroIssueEventMessage EXCEPT !.eventReasonCode = one] : one \in Sample(4) }
        \cup { [ZeroIssueEventMessage EXCEPT !.eventStartDate = one] : one \in Sample(8) }
        \cup { [ZeroIssueEventMessage EXCEPT !.eventEndDate = one] : one \in Sample(8) }
        \cup { [ZeroIssueEventMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Corporate Bonds Reference Message: 240 bytes                            *)
(***************************************************************************)

CorporateBondsReferenceMessage ==
    [ messageSequenceNumber                          : Sample(8),
      isinCode                                       : Sample(12),
      abbreviatedIssueName                           : Sample(40),
      issueDate                                      : Sample(8),
      redemptionDate                                 : Sample(8),
      listingDate                                    : Sample(8),
      couponPaymentTypeCode                          : Sample(2),
      issuingAmount                                  : Sample(22),
      listedAmount                                   : Sample(22),
      couponPaymentTimingCode                        : Sample(1),
      numberOfMonthsForGrace                         : Sample(4),
      numberOfAmortization                           : Sample(5),
      interestPayment                                : Sample(1),
      couponPaymentDateTypeCode                      : Sample(1),
      couponRate                                     : Sample(14),
      substitutePriceOfSecurities                    : Sample(11),
      isin                                           : Sample(12),
      dateToStartExercising                          : Sample(8),
      dateToEndExercising                            : Sample(8),
      recordDateOfDividendPayout                     : Sample(1),
      exerciseRatio                                  : Sample(7),
      yieldToMaturity                                : Sample(13),
      corporateBondsRelatedToSecuritiesExercisePrice : Sample(11),
      abbreviatedIssueCode                           : Sample(9),
      babyBondsTypeCode                              : Sample(3),
      endKeyword                                     : Sample(1) ]

EncodeCorporateBondsReferenceMessage(message) ==
    message.messageSequenceNumber
        \o message.isinCode
        \o message.abbreviatedIssueName
        \o message.issueDate
        \o message.redemptionDate
        \o message.listingDate
        \o message.couponPaymentTypeCode
        \o message.issuingAmount
        \o message.listedAmount
        \o message.couponPaymentTimingCode
        \o message.numberOfMonthsForGrace
        \o message.numberOfAmortization
        \o message.interestPayment
        \o message.couponPaymentDateTypeCode
        \o message.couponRate
        \o message.substitutePriceOfSecurities
        \o message.isin
        \o message.dateToStartExercising
        \o message.dateToEndExercising
        \o message.recordDateOfDividendPayout
        \o message.exerciseRatio
        \o message.yieldToMaturity
        \o message.corporateBondsRelatedToSecuritiesExercisePrice
        \o message.abbreviatedIssueCode
        \o message.babyBondsTypeCode
        \o message.endKeyword

DecodeCorporateBondsReferenceMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET isinCode == ReadBytes(messageSequenceNumber.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET abbreviatedIssueName == ReadBytes(isinCode.rest, 40) IN IF ~abbreviatedIssueName.ok THEN Fail ELSE
    LET issueDate == ReadBytes(abbreviatedIssueName.rest, 8) IN IF ~issueDate.ok THEN Fail ELSE
    LET redemptionDate == ReadBytes(issueDate.rest, 8) IN IF ~redemptionDate.ok THEN Fail ELSE
    LET listingDate == ReadBytes(redemptionDate.rest, 8) IN IF ~listingDate.ok THEN Fail ELSE
    LET couponPaymentTypeCode == ReadBytes(listingDate.rest, 2) IN IF ~couponPaymentTypeCode.ok THEN Fail ELSE
    LET issuingAmount == ReadBytes(couponPaymentTypeCode.rest, 22) IN IF ~issuingAmount.ok THEN Fail ELSE
    LET listedAmount == ReadBytes(issuingAmount.rest, 22) IN IF ~listedAmount.ok THEN Fail ELSE
    LET couponPaymentTimingCode == ReadBytes(listedAmount.rest, 1) IN IF ~couponPaymentTimingCode.ok THEN Fail ELSE
    LET numberOfMonthsForGrace == ReadBytes(couponPaymentTimingCode.rest, 4) IN IF ~numberOfMonthsForGrace.ok THEN Fail ELSE
    LET numberOfAmortization == ReadBytes(numberOfMonthsForGrace.rest, 5) IN IF ~numberOfAmortization.ok THEN Fail ELSE
    LET interestPayment == ReadBytes(numberOfAmortization.rest, 1) IN IF ~interestPayment.ok THEN Fail ELSE
    LET couponPaymentDateTypeCode == ReadBytes(interestPayment.rest, 1) IN IF ~couponPaymentDateTypeCode.ok THEN Fail ELSE
    LET couponRate == ReadBytes(couponPaymentDateTypeCode.rest, 14) IN IF ~couponRate.ok THEN Fail ELSE
    LET substitutePriceOfSecurities == ReadBytes(couponRate.rest, 11) IN IF ~substitutePriceOfSecurities.ok THEN Fail ELSE
    LET isin == ReadBytes(substitutePriceOfSecurities.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET dateToStartExercising == ReadBytes(isin.rest, 8) IN IF ~dateToStartExercising.ok THEN Fail ELSE
    LET dateToEndExercising == ReadBytes(dateToStartExercising.rest, 8) IN IF ~dateToEndExercising.ok THEN Fail ELSE
    LET recordDateOfDividendPayout == ReadBytes(dateToEndExercising.rest, 1) IN IF ~recordDateOfDividendPayout.ok THEN Fail ELSE
    LET exerciseRatio == ReadBytes(recordDateOfDividendPayout.rest, 7) IN IF ~exerciseRatio.ok THEN Fail ELSE
    LET yieldToMaturity == ReadBytes(exerciseRatio.rest, 13) IN IF ~yieldToMaturity.ok THEN Fail ELSE
    LET corporateBondsRelatedToSecuritiesExercisePrice == ReadBytes(yieldToMaturity.rest, 11) IN IF ~corporateBondsRelatedToSecuritiesExercisePrice.ok THEN Fail ELSE
    LET abbreviatedIssueCode == ReadBytes(corporateBondsRelatedToSecuritiesExercisePrice.rest, 9) IN IF ~abbreviatedIssueCode.ok THEN Fail ELSE
    LET babyBondsTypeCode == ReadBytes(abbreviatedIssueCode.rest, 3) IN IF ~babyBondsTypeCode.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(babyBondsTypeCode.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber                          |-> messageSequenceNumber.value,
         isinCode                                       |-> isinCode.value,
         abbreviatedIssueName                           |-> abbreviatedIssueName.value,
         issueDate                                      |-> issueDate.value,
         redemptionDate                                 |-> redemptionDate.value,
         listingDate                                    |-> listingDate.value,
         couponPaymentTypeCode                          |-> couponPaymentTypeCode.value,
         issuingAmount                                  |-> issuingAmount.value,
         listedAmount                                   |-> listedAmount.value,
         couponPaymentTimingCode                        |-> couponPaymentTimingCode.value,
         numberOfMonthsForGrace                         |-> numberOfMonthsForGrace.value,
         numberOfAmortization                           |-> numberOfAmortization.value,
         interestPayment                                |-> interestPayment.value,
         couponPaymentDateTypeCode                      |-> couponPaymentDateTypeCode.value,
         couponRate                                     |-> couponRate.value,
         substitutePriceOfSecurities                    |-> substitutePriceOfSecurities.value,
         isin                                           |-> isin.value,
         dateToStartExercising                          |-> dateToStartExercising.value,
         dateToEndExercising                            |-> dateToEndExercising.value,
         recordDateOfDividendPayout                     |-> recordDateOfDividendPayout.value,
         exerciseRatio                                  |-> exerciseRatio.value,
         yieldToMaturity                                |-> yieldToMaturity.value,
         corporateBondsRelatedToSecuritiesExercisePrice |-> corporateBondsRelatedToSecuritiesExercisePrice.value,
         abbreviatedIssueCode                           |-> abbreviatedIssueCode.value,
         babyBondsTypeCode                              |-> babyBondsTypeCode.value,
         endKeyword                                     |-> endKeyword.value ], endKeyword.rest)

ZeroCorporateBondsReferenceMessage ==
    [ messageSequenceNumber                          |-> [i \in 1 .. 8 |-> 0],
      isinCode                                       |-> [i \in 1 .. 12 |-> 0],
      abbreviatedIssueName                           |-> [i \in 1 .. 40 |-> 0],
      issueDate                                      |-> [i \in 1 .. 8 |-> 0],
      redemptionDate                                 |-> [i \in 1 .. 8 |-> 0],
      listingDate                                    |-> [i \in 1 .. 8 |-> 0],
      couponPaymentTypeCode                          |-> [i \in 1 .. 2 |-> 0],
      issuingAmount                                  |-> [i \in 1 .. 22 |-> 0],
      listedAmount                                   |-> [i \in 1 .. 22 |-> 0],
      couponPaymentTimingCode                        |-> [i \in 1 .. 1 |-> 0],
      numberOfMonthsForGrace                         |-> [i \in 1 .. 4 |-> 0],
      numberOfAmortization                           |-> [i \in 1 .. 5 |-> 0],
      interestPayment                                |-> [i \in 1 .. 1 |-> 0],
      couponPaymentDateTypeCode                      |-> [i \in 1 .. 1 |-> 0],
      couponRate                                     |-> [i \in 1 .. 14 |-> 0],
      substitutePriceOfSecurities                    |-> [i \in 1 .. 11 |-> 0],
      isin                                           |-> [i \in 1 .. 12 |-> 0],
      dateToStartExercising                          |-> [i \in 1 .. 8 |-> 0],
      dateToEndExercising                            |-> [i \in 1 .. 8 |-> 0],
      recordDateOfDividendPayout                     |-> [i \in 1 .. 1 |-> 0],
      exerciseRatio                                  |-> [i \in 1 .. 7 |-> 0],
      yieldToMaturity                                |-> [i \in 1 .. 13 |-> 0],
      corporateBondsRelatedToSecuritiesExercisePrice |-> [i \in 1 .. 11 |-> 0],
      abbreviatedIssueCode                           |-> [i \in 1 .. 9 |-> 0],
      babyBondsTypeCode                              |-> [i \in 1 .. 3 |-> 0],
      endKeyword                                     |-> [i \in 1 .. 1 |-> 0] ]

(* Corporate Bonds Reference Message at zero, then each field in turn at the values it is checked at *)
CheckedCorporateBondsReferenceMessage ==
    { ZeroCorporateBondsReferenceMessage }
        \cup { [ZeroCorporateBondsReferenceMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroCorporateBondsReferenceMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroCorporateBondsReferenceMessage EXCEPT !.abbreviatedIssueName = one] : one \in Sample(40) }
        \cup { [ZeroCorporateBondsReferenceMessage EXCEPT !.issueDate = one] : one \in Sample(8) }
        \cup { [ZeroCorporateBondsReferenceMessage EXCEPT !.redemptionDate = one] : one \in Sample(8) }
        \cup { [ZeroCorporateBondsReferenceMessage EXCEPT !.listingDate = one] : one \in Sample(8) }
        \cup { [ZeroCorporateBondsReferenceMessage EXCEPT !.couponPaymentTypeCode = one] : one \in Sample(2) }
        \cup { [ZeroCorporateBondsReferenceMessage EXCEPT !.issuingAmount = one] : one \in Sample(22) }
        \cup { [ZeroCorporateBondsReferenceMessage EXCEPT !.listedAmount = one] : one \in Sample(22) }
        \cup { [ZeroCorporateBondsReferenceMessage EXCEPT !.couponPaymentTimingCode = one] : one \in Sample(1) }
        \cup { [ZeroCorporateBondsReferenceMessage EXCEPT !.numberOfMonthsForGrace = one] : one \in Sample(4) }
        \cup { [ZeroCorporateBondsReferenceMessage EXCEPT !.numberOfAmortization = one] : one \in Sample(5) }
        \cup { [ZeroCorporateBondsReferenceMessage EXCEPT !.interestPayment = one] : one \in Sample(1) }
        \cup { [ZeroCorporateBondsReferenceMessage EXCEPT !.couponPaymentDateTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroCorporateBondsReferenceMessage EXCEPT !.couponRate = one] : one \in Sample(14) }
        \cup { [ZeroCorporateBondsReferenceMessage EXCEPT !.substitutePriceOfSecurities = one] : one \in Sample(11) }
        \cup { [ZeroCorporateBondsReferenceMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroCorporateBondsReferenceMessage EXCEPT !.dateToStartExercising = one] : one \in Sample(8) }
        \cup { [ZeroCorporateBondsReferenceMessage EXCEPT !.dateToEndExercising = one] : one \in Sample(8) }
        \cup { [ZeroCorporateBondsReferenceMessage EXCEPT !.recordDateOfDividendPayout = one] : one \in Sample(1) }
        \cup { [ZeroCorporateBondsReferenceMessage EXCEPT !.exerciseRatio = one] : one \in Sample(7) }
        \cup { [ZeroCorporateBondsReferenceMessage EXCEPT !.yieldToMaturity = one] : one \in Sample(13) }
        \cup { [ZeroCorporateBondsReferenceMessage EXCEPT !.corporateBondsRelatedToSecuritiesExercisePrice = one] : one \in Sample(11) }
        \cup { [ZeroCorporateBondsReferenceMessage EXCEPT !.abbreviatedIssueCode = one] : one \in Sample(9) }
        \cup { [ZeroCorporateBondsReferenceMessage EXCEPT !.babyBondsTypeCode = one] : one \in Sample(3) }
        \cup { [ZeroCorporateBondsReferenceMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Regular Bonds Installment Repayment Date Message: 29 bytes              *)
(***************************************************************************)

RegularBondsInstallmentRepaymentDateMessage ==
    [ messageSequenceNumber    : Sample(8),
      isinCode                 : Sample(12),
      installmentRepaymentDate : Sample(8),
      endKeyword               : Sample(1) ]

EncodeRegularBondsInstallmentRepaymentDateMessage(message) ==
    message.messageSequenceNumber
        \o message.isinCode
        \o message.installmentRepaymentDate
        \o message.endKeyword

DecodeRegularBondsInstallmentRepaymentDateMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET isinCode == ReadBytes(messageSequenceNumber.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET installmentRepaymentDate == ReadBytes(isinCode.rest, 8) IN IF ~installmentRepaymentDate.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(installmentRepaymentDate.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber    |-> messageSequenceNumber.value,
         isinCode                 |-> isinCode.value,
         installmentRepaymentDate |-> installmentRepaymentDate.value,
         endKeyword               |-> endKeyword.value ], endKeyword.rest)

ZeroRegularBondsInstallmentRepaymentDateMessage ==
    [ messageSequenceNumber    |-> [i \in 1 .. 8 |-> 0],
      isinCode                 |-> [i \in 1 .. 12 |-> 0],
      installmentRepaymentDate |-> [i \in 1 .. 8 |-> 0],
      endKeyword               |-> [i \in 1 .. 1 |-> 0] ]

(* Regular Bonds Installment Repayment Date Message at zero, then each field in turn at the values it is checked at *)
CheckedRegularBondsInstallmentRepaymentDateMessage ==
    { ZeroRegularBondsInstallmentRepaymentDateMessage }
        \cup { [ZeroRegularBondsInstallmentRepaymentDateMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroRegularBondsInstallmentRepaymentDateMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroRegularBondsInstallmentRepaymentDateMessage EXCEPT !.installmentRepaymentDate = one] : one \in Sample(8) }
        \cup { [ZeroRegularBondsInstallmentRepaymentDateMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Repo Classification Data Message: 39 bytes                              *)
(***************************************************************************)

RepoClassificationDataMessage ==
    [ messageSequenceNumber  : Sample(8),
      businessDate           : Sample(8),
      repoClassificationCode : Sample(2),
      repoClassificationName : Sample(20),
      endKeyword             : Sample(1) ]

EncodeRepoClassificationDataMessage(message) ==
    message.messageSequenceNumber
        \o message.businessDate
        \o message.repoClassificationCode
        \o message.repoClassificationName
        \o message.endKeyword

DecodeRepoClassificationDataMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET businessDate == ReadBytes(messageSequenceNumber.rest, 8) IN IF ~businessDate.ok THEN Fail ELSE
    LET repoClassificationCode == ReadBytes(businessDate.rest, 2) IN IF ~repoClassificationCode.ok THEN Fail ELSE
    LET repoClassificationName == ReadBytes(repoClassificationCode.rest, 20) IN IF ~repoClassificationName.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(repoClassificationName.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber  |-> messageSequenceNumber.value,
         businessDate           |-> businessDate.value,
         repoClassificationCode |-> repoClassificationCode.value,
         repoClassificationName |-> repoClassificationName.value,
         endKeyword             |-> endKeyword.value ], endKeyword.rest)

ZeroRepoClassificationDataMessage ==
    [ messageSequenceNumber  |-> [i \in 1 .. 8 |-> 0],
      businessDate           |-> [i \in 1 .. 8 |-> 0],
      repoClassificationCode |-> [i \in 1 .. 2 |-> 0],
      repoClassificationName |-> [i \in 1 .. 20 |-> 0],
      endKeyword             |-> [i \in 1 .. 1 |-> 0] ]

(* Repo Classification Data Message at zero, then each field in turn at the values it is checked at *)
CheckedRepoClassificationDataMessage ==
    { ZeroRepoClassificationDataMessage }
        \cup { [ZeroRepoClassificationDataMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroRepoClassificationDataMessage EXCEPT !.businessDate = one] : one \in Sample(8) }
        \cup { [ZeroRepoClassificationDataMessage EXCEPT !.repoClassificationCode = one] : one \in Sample(2) }
        \cup { [ZeroRepoClassificationDataMessage EXCEPT !.repoClassificationName = one] : one \in Sample(20) }
        \cup { [ZeroRepoClassificationDataMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Repo Trade Availability Per Term Message: 54 bytes                      *)
(***************************************************************************)

RepoTradeAvailabilityPerTermMessage ==
    [ messageSequenceNumber    : Sample(8),
      isinCode                 : Sample(12),
      numberOfRepoTradePeriods : Sample(3),
      repoTradePeriod1         : Sample(3),
      repoTradePeriod2         : Sample(3),
      repoTradePeriod3         : Sample(3),
      repoTradePeriod4         : Sample(3),
      repoTradePeriod5         : Sample(3),
      repoTradePeriod6         : Sample(3),
      repoTradePeriod7         : Sample(3),
      repoTradePeriod8         : Sample(3),
      repoTradePeriod9         : Sample(3),
      repoTradePeriod10        : Sample(3),
      endKeyword               : Sample(1) ]

EncodeRepoTradeAvailabilityPerTermMessage(message) ==
    message.messageSequenceNumber
        \o message.isinCode
        \o message.numberOfRepoTradePeriods
        \o message.repoTradePeriod1
        \o message.repoTradePeriod2
        \o message.repoTradePeriod3
        \o message.repoTradePeriod4
        \o message.repoTradePeriod5
        \o message.repoTradePeriod6
        \o message.repoTradePeriod7
        \o message.repoTradePeriod8
        \o message.repoTradePeriod9
        \o message.repoTradePeriod10
        \o message.endKeyword

DecodeRepoTradeAvailabilityPerTermMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET isinCode == ReadBytes(messageSequenceNumber.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET numberOfRepoTradePeriods == ReadBytes(isinCode.rest, 3) IN IF ~numberOfRepoTradePeriods.ok THEN Fail ELSE
    LET repoTradePeriod1 == ReadBytes(numberOfRepoTradePeriods.rest, 3) IN IF ~repoTradePeriod1.ok THEN Fail ELSE
    LET repoTradePeriod2 == ReadBytes(repoTradePeriod1.rest, 3) IN IF ~repoTradePeriod2.ok THEN Fail ELSE
    LET repoTradePeriod3 == ReadBytes(repoTradePeriod2.rest, 3) IN IF ~repoTradePeriod3.ok THEN Fail ELSE
    LET repoTradePeriod4 == ReadBytes(repoTradePeriod3.rest, 3) IN IF ~repoTradePeriod4.ok THEN Fail ELSE
    LET repoTradePeriod5 == ReadBytes(repoTradePeriod4.rest, 3) IN IF ~repoTradePeriod5.ok THEN Fail ELSE
    LET repoTradePeriod6 == ReadBytes(repoTradePeriod5.rest, 3) IN IF ~repoTradePeriod6.ok THEN Fail ELSE
    LET repoTradePeriod7 == ReadBytes(repoTradePeriod6.rest, 3) IN IF ~repoTradePeriod7.ok THEN Fail ELSE
    LET repoTradePeriod8 == ReadBytes(repoTradePeriod7.rest, 3) IN IF ~repoTradePeriod8.ok THEN Fail ELSE
    LET repoTradePeriod9 == ReadBytes(repoTradePeriod8.rest, 3) IN IF ~repoTradePeriod9.ok THEN Fail ELSE
    LET repoTradePeriod10 == ReadBytes(repoTradePeriod9.rest, 3) IN IF ~repoTradePeriod10.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(repoTradePeriod10.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber    |-> messageSequenceNumber.value,
         isinCode                 |-> isinCode.value,
         numberOfRepoTradePeriods |-> numberOfRepoTradePeriods.value,
         repoTradePeriod1         |-> repoTradePeriod1.value,
         repoTradePeriod2         |-> repoTradePeriod2.value,
         repoTradePeriod3         |-> repoTradePeriod3.value,
         repoTradePeriod4         |-> repoTradePeriod4.value,
         repoTradePeriod5         |-> repoTradePeriod5.value,
         repoTradePeriod6         |-> repoTradePeriod6.value,
         repoTradePeriod7         |-> repoTradePeriod7.value,
         repoTradePeriod8         |-> repoTradePeriod8.value,
         repoTradePeriod9         |-> repoTradePeriod9.value,
         repoTradePeriod10        |-> repoTradePeriod10.value,
         endKeyword               |-> endKeyword.value ], endKeyword.rest)

ZeroRepoTradeAvailabilityPerTermMessage ==
    [ messageSequenceNumber    |-> [i \in 1 .. 8 |-> 0],
      isinCode                 |-> [i \in 1 .. 12 |-> 0],
      numberOfRepoTradePeriods |-> [i \in 1 .. 3 |-> 0],
      repoTradePeriod1         |-> [i \in 1 .. 3 |-> 0],
      repoTradePeriod2         |-> [i \in 1 .. 3 |-> 0],
      repoTradePeriod3         |-> [i \in 1 .. 3 |-> 0],
      repoTradePeriod4         |-> [i \in 1 .. 3 |-> 0],
      repoTradePeriod5         |-> [i \in 1 .. 3 |-> 0],
      repoTradePeriod6         |-> [i \in 1 .. 3 |-> 0],
      repoTradePeriod7         |-> [i \in 1 .. 3 |-> 0],
      repoTradePeriod8         |-> [i \in 1 .. 3 |-> 0],
      repoTradePeriod9         |-> [i \in 1 .. 3 |-> 0],
      repoTradePeriod10        |-> [i \in 1 .. 3 |-> 0],
      endKeyword               |-> [i \in 1 .. 1 |-> 0] ]

(* Repo Trade Availability Per Term Message at zero, then each field in turn at the values it is checked at *)
CheckedRepoTradeAvailabilityPerTermMessage ==
    { ZeroRepoTradeAvailabilityPerTermMessage }
        \cup { [ZeroRepoTradeAvailabilityPerTermMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroRepoTradeAvailabilityPerTermMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroRepoTradeAvailabilityPerTermMessage EXCEPT !.numberOfRepoTradePeriods = one] : one \in Sample(3) }
        \cup { [ZeroRepoTradeAvailabilityPerTermMessage EXCEPT !.repoTradePeriod1 = one] : one \in Sample(3) }
        \cup { [ZeroRepoTradeAvailabilityPerTermMessage EXCEPT !.repoTradePeriod2 = one] : one \in Sample(3) }
        \cup { [ZeroRepoTradeAvailabilityPerTermMessage EXCEPT !.repoTradePeriod3 = one] : one \in Sample(3) }
        \cup { [ZeroRepoTradeAvailabilityPerTermMessage EXCEPT !.repoTradePeriod4 = one] : one \in Sample(3) }
        \cup { [ZeroRepoTradeAvailabilityPerTermMessage EXCEPT !.repoTradePeriod5 = one] : one \in Sample(3) }
        \cup { [ZeroRepoTradeAvailabilityPerTermMessage EXCEPT !.repoTradePeriod6 = one] : one \in Sample(3) }
        \cup { [ZeroRepoTradeAvailabilityPerTermMessage EXCEPT !.repoTradePeriod7 = one] : one \in Sample(3) }
        \cup { [ZeroRepoTradeAvailabilityPerTermMessage EXCEPT !.repoTradePeriod8 = one] : one \in Sample(3) }
        \cup { [ZeroRepoTradeAvailabilityPerTermMessage EXCEPT !.repoTradePeriod9 = one] : one \in Sample(3) }
        \cup { [ZeroRepoTradeAvailabilityPerTermMessage EXCEPT !.repoTradePeriod10 = one] : one \in Sample(3) }
        \cup { [ZeroRepoTradeAvailabilityPerTermMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Retail Bonds Type Code Message: 52 bytes                                *)
(***************************************************************************)

RetailBondsTypeCodeMessage ==
    [ messageSequenceNumber      : Sample(8),
      retailBondTypeCode         : Sample(2),
      retailBondCategoryName     : Sample(20),
      retailBondCategoryNameInEn : Sample(20),
      retailBondGeneratedQuotes  : Sample(1),
      endKeyword                 : Sample(1) ]

EncodeRetailBondsTypeCodeMessage(message) ==
    message.messageSequenceNumber
        \o message.retailBondTypeCode
        \o message.retailBondCategoryName
        \o message.retailBondCategoryNameInEn
        \o message.retailBondGeneratedQuotes
        \o message.endKeyword

DecodeRetailBondsTypeCodeMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET retailBondTypeCode == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~retailBondTypeCode.ok THEN Fail ELSE
    LET retailBondCategoryName == ReadBytes(retailBondTypeCode.rest, 20) IN IF ~retailBondCategoryName.ok THEN Fail ELSE
    LET retailBondCategoryNameInEn == ReadBytes(retailBondCategoryName.rest, 20) IN IF ~retailBondCategoryNameInEn.ok THEN Fail ELSE
    LET retailBondGeneratedQuotes == ReadBytes(retailBondCategoryNameInEn.rest, 1) IN IF ~retailBondGeneratedQuotes.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(retailBondGeneratedQuotes.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber      |-> messageSequenceNumber.value,
         retailBondTypeCode         |-> retailBondTypeCode.value,
         retailBondCategoryName     |-> retailBondCategoryName.value,
         retailBondCategoryNameInEn |-> retailBondCategoryNameInEn.value,
         retailBondGeneratedQuotes  |-> retailBondGeneratedQuotes.value,
         endKeyword                 |-> endKeyword.value ], endKeyword.rest)

ZeroRetailBondsTypeCodeMessage ==
    [ messageSequenceNumber      |-> [i \in 1 .. 8 |-> 0],
      retailBondTypeCode         |-> [i \in 1 .. 2 |-> 0],
      retailBondCategoryName     |-> [i \in 1 .. 20 |-> 0],
      retailBondCategoryNameInEn |-> [i \in 1 .. 20 |-> 0],
      retailBondGeneratedQuotes  |-> [i \in 1 .. 1 |-> 0],
      endKeyword                 |-> [i \in 1 .. 1 |-> 0] ]

(* Retail Bonds Type Code Message at zero, then each field in turn at the values it is checked at *)
CheckedRetailBondsTypeCodeMessage ==
    { ZeroRetailBondsTypeCodeMessage }
        \cup { [ZeroRetailBondsTypeCodeMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroRetailBondsTypeCodeMessage EXCEPT !.retailBondTypeCode = one] : one \in Sample(2) }
        \cup { [ZeroRetailBondsTypeCodeMessage EXCEPT !.retailBondCategoryName = one] : one \in Sample(20) }
        \cup { [ZeroRetailBondsTypeCodeMessage EXCEPT !.retailBondCategoryNameInEn = one] : one \in Sample(20) }
        \cup { [ZeroRetailBondsTypeCodeMessage EXCEPT !.retailBondGeneratedQuotes = one] : one \in Sample(1) }
        \cup { [ZeroRetailBondsTypeCodeMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

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
EquityDerivativesUnderlyingSnapshotKospiMessageCode == <<66, 50, 48, 49, 83>>  \* "B201S"
EquityDerivativesUnderlyingSnapshotKosdaqMessageCode == <<66, 50, 48, 49, 81>>  \* "B201Q"
EquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessageCode == <<66, 50, 48, 50, 83>>  \* "B202S"
EquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessageCode2 == <<66, 50, 48, 51, 83>>  \* "B203S"
EquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessageCode3 == <<66, 50, 48, 52, 83>>  \* "B204S"
EquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessageCode4 == <<66, 50, 48, 53, 83>>  \* "B205S"
SecuritiesEquitiesBatchDataMessageCode == <<65, 48, 48, 49, 83>>  \* "A001S"
SecuritiesEquitiesBatchDataMessageCode2 == <<65, 48, 48, 50, 83>>  \* "A002S"
SecuritiesEquitiesBatchDataMessageCode3 == <<65, 48, 48, 51, 83>>  \* "A003S"
SecuritiesEquitiesBatchDataMessageCode4 == <<65, 48, 48, 52, 83>>  \* "A004S"
SecuritiesEquitiesBatchDataMessageCode5 == <<65, 48, 48, 53, 83>>  \* "A005S"
SecuritiesEquitiesBatchDataMessageCode6 == <<65, 48, 48, 49, 81>>  \* "A001Q"
SecuritiesEquitiesBatchDataMessageCode7 == <<65, 48, 48, 49, 88>>  \* "A001X"
SecuritiesClosingDateMessageCode == <<73, 53, 48, 49, 83>>  \* "I501S"
SecuritiesClosingDateMessageCode2 == <<73, 53, 48, 51, 83>>  \* "I503S"
SecuritiesClosingDateMessageCode3 == <<73, 53, 48, 52, 83>>  \* "I504S"
SecuritiesClosingDateMessageCode4 == <<73, 53, 48, 53, 83>>  \* "I505S"
SecuritiesClosingDateMessageCode5 == <<73, 53, 48, 49, 81>>  \* "I501Q"
SecuritiesClosingDateMessageCode6 == <<73, 53, 48, 49, 88>>  \* "I501X"
SecuritiesMmLpInformationMessageCode == <<73, 55, 48, 49, 83>>  \* "I701S"
SecuritiesMmLpInformationMessageCode2 == <<73, 55, 48, 50, 83>>  \* "I702S"
SecuritiesMmLpInformationMessageCode3 == <<73, 55, 48, 51, 83>>  \* "I703S"
SecuritiesMmLpInformationMessageCode4 == <<73, 55, 48, 52, 83>>  \* "I704S"
SecuritiesMmLpInformationMessageCode5 == <<73, 55, 48, 53, 83>>  \* "I705S"
SecuritiesMmLpInformationMessageCode6 == <<73, 55, 48, 49, 81>>  \* "I701Q"
SecuritiesMmLpInformationMessageCode7 == <<73, 55, 48, 49, 88>>  \* "I701X"
SecuritiesMemberInformationMessageCode == <<77, 57, 48, 48, 83>>  \* "M900S"
SecuritiesMemberInformationMessageCode2 == <<77, 57, 48, 48, 81>>  \* "M900Q"
SecuritiesMemberInformationMessageCode3 == <<77, 57, 48, 48, 88>>  \* "M900X"
SecuritiesTreasuryStocksBatchMessageCode == <<65, 57, 48, 49, 83>>  \* "A901S"
SecuritiesTreasuryStocksBatchMessageCode2 == <<65, 57, 48, 49, 81>>  \* "A901Q"
SecuritiesTreasuryStocksBatchMessageCode3 == <<65, 57, 48, 49, 88>>  \* "A901X"
SecuritiesEquityIndexIndicatorMessageCode == <<67, 65, 48, 49, 83>>  \* "CA01S"
SecuritiesEquityIndexIndicatorMessageCode2 == <<67, 65, 48, 49, 81>>  \* "CA01Q"
SecuritiesDividendYieldPerIndustryMessageCode == <<80, 50, 48, 48, 83>>  \* "P200S"
SecuritiesDividendYieldPerIndustryMessageCode2 == <<80, 50, 48, 48, 81>>  \* "P200Q"
BondsBatchDataMessageCode == <<65, 48, 48, 49, 66>>  \* "A001B"
RepoBatchDataMessageCode == <<65, 48, 48, 49, 82>>  \* "A001R"
IssueEventMessageCode == <<73, 54, 48, 49, 83>>  \* "I601S"
IssueEventMessageCode2 == <<73, 54, 48, 50, 83>>  \* "I602S"
IssueEventMessageCode3 == <<73, 54, 48, 51, 83>>  \* "I603S"
IssueEventMessageCode4 == <<73, 54, 48, 52, 83>>  \* "I604S"
IssueEventMessageCode5 == <<73, 54, 48, 53, 83>>  \* "I605S"
IssueEventMessageCode6 == <<73, 54, 48, 49, 81>>  \* "I601Q"
IssueEventMessageCode7 == <<73, 54, 48, 49, 88>>  \* "I601X"
IssueEventMessageCode8 == <<73, 54, 48, 49, 66>>  \* "I601B"
IssueEventMessageCode9 == <<73, 54, 48, 49, 77>>  \* "I601M"
IssueEventMessageCode10 == <<73, 54, 48, 49, 75>>  \* "I601K"
IssueEventMessageCode11 == <<73, 54, 48, 49, 82>>  \* "I601R"
CorporateBondsReferenceMessageCode == <<70, 57, 48, 49, 66>>  \* "F901B"
CorporateBondsReferenceMessageCode2 == <<70, 57, 48, 49, 77>>  \* "F901M"
RegularBondsInstallmentRepaymentDateMessageCode == <<66, 78, 48, 49, 66>>  \* "BN01B"
RepoClassificationDataMessageCode == <<67, 66, 48, 49, 82>>  \* "CB01R"
RepoTradeAvailabilityPerTermMessageCode == <<83, 48, 48, 49, 82>>  \* "S001R"
RetailBondsTypeCodeMessageCode == <<71, 51, 48, 48, 66>>  \* "G300B"

Payload ==
    [ tag : {PollingDataMessageCode}, body : PollingDataMessage ]
        \cup [ tag : {KrxIndexMessageCode}, body : KrxIndexMessage ]
        \cup [ tag : {KrxEstimatedIndexMessageCode}, body : KrxEstimatedIndexMessage ]
        \cup [ tag : {GlobalIndexMessageCode}, body : GlobalIndexMessage ]
        \cup [ tag : {BondPrimeIndexMessageCode}, body : BondPrimeIndexMessage ]
        \cup [ tag : {BondKtbIndexMessageCode}, body : BondKtbIndexMessage ]
        \cup [ tag : {BondKtbIndexTermStructureMessageCode}, body : BondKtbIndexTermStructureMessage ]
        \cup [ tag : {BondIndexKrxMessageCode}, body : BondIndexKrxMessage ]
        \cup [ tag : {EquityDerivativesUnderlyingSnapshotKospiMessageCode}, body : EquityDerivativesUnderlyingSnapshotKospiMessage ]
        \cup [ tag : {EquityDerivativesUnderlyingSnapshotKosdaqMessageCode}, body : EquityDerivativesUnderlyingSnapshotKosdaqMessage ]
        \cup [ tag : {EquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessageCode}, body : EquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessage ]
        \cup [ tag : {EquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessageCode2}, body : EquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessage ]
        \cup [ tag : {EquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessageCode3}, body : EquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessage ]
        \cup [ tag : {EquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessageCode4}, body : EquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessage ]
        \cup [ tag : {SecuritiesEquitiesBatchDataMessageCode}, body : SecuritiesEquitiesBatchDataMessage ]
        \cup [ tag : {SecuritiesEquitiesBatchDataMessageCode2}, body : SecuritiesEquitiesBatchDataMessage ]
        \cup [ tag : {SecuritiesEquitiesBatchDataMessageCode3}, body : SecuritiesEquitiesBatchDataMessage ]
        \cup [ tag : {SecuritiesEquitiesBatchDataMessageCode4}, body : SecuritiesEquitiesBatchDataMessage ]
        \cup [ tag : {SecuritiesEquitiesBatchDataMessageCode5}, body : SecuritiesEquitiesBatchDataMessage ]
        \cup [ tag : {SecuritiesEquitiesBatchDataMessageCode6}, body : SecuritiesEquitiesBatchDataMessage ]
        \cup [ tag : {SecuritiesEquitiesBatchDataMessageCode7}, body : SecuritiesEquitiesBatchDataMessage ]
        \cup [ tag : {SecuritiesClosingDateMessageCode}, body : SecuritiesClosingDateMessage ]
        \cup [ tag : {SecuritiesClosingDateMessageCode2}, body : SecuritiesClosingDateMessage ]
        \cup [ tag : {SecuritiesClosingDateMessageCode3}, body : SecuritiesClosingDateMessage ]
        \cup [ tag : {SecuritiesClosingDateMessageCode4}, body : SecuritiesClosingDateMessage ]
        \cup [ tag : {SecuritiesClosingDateMessageCode5}, body : SecuritiesClosingDateMessage ]
        \cup [ tag : {SecuritiesClosingDateMessageCode6}, body : SecuritiesClosingDateMessage ]
        \cup [ tag : {SecuritiesMmLpInformationMessageCode}, body : SecuritiesMmLpInformationMessage ]
        \cup [ tag : {SecuritiesMmLpInformationMessageCode2}, body : SecuritiesMmLpInformationMessage ]
        \cup [ tag : {SecuritiesMmLpInformationMessageCode3}, body : SecuritiesMmLpInformationMessage ]
        \cup [ tag : {SecuritiesMmLpInformationMessageCode4}, body : SecuritiesMmLpInformationMessage ]
        \cup [ tag : {SecuritiesMmLpInformationMessageCode5}, body : SecuritiesMmLpInformationMessage ]
        \cup [ tag : {SecuritiesMmLpInformationMessageCode6}, body : SecuritiesMmLpInformationMessage ]
        \cup [ tag : {SecuritiesMmLpInformationMessageCode7}, body : SecuritiesMmLpInformationMessage ]
        \cup [ tag : {SecuritiesMemberInformationMessageCode}, body : SecuritiesMemberInformationMessage ]
        \cup [ tag : {SecuritiesMemberInformationMessageCode2}, body : SecuritiesMemberInformationMessage ]
        \cup [ tag : {SecuritiesMemberInformationMessageCode3}, body : SecuritiesMemberInformationMessage ]
        \cup [ tag : {SecuritiesTreasuryStocksBatchMessageCode}, body : SecuritiesTreasuryStocksBatchMessage ]
        \cup [ tag : {SecuritiesTreasuryStocksBatchMessageCode2}, body : SecuritiesTreasuryStocksBatchMessage ]
        \cup [ tag : {SecuritiesTreasuryStocksBatchMessageCode3}, body : SecuritiesTreasuryStocksBatchMessage ]
        \cup [ tag : {SecuritiesEquityIndexIndicatorMessageCode}, body : SecuritiesEquityIndexIndicatorMessage ]
        \cup [ tag : {SecuritiesEquityIndexIndicatorMessageCode2}, body : SecuritiesEquityIndexIndicatorMessage ]
        \cup [ tag : {SecuritiesDividendYieldPerIndustryMessageCode}, body : SecuritiesDividendYieldPerIndustryMessage ]
        \cup [ tag : {SecuritiesDividendYieldPerIndustryMessageCode2}, body : SecuritiesDividendYieldPerIndustryMessage ]
        \cup [ tag : {BondsBatchDataMessageCode}, body : BondsBatchDataMessage ]
        \cup [ tag : {RepoBatchDataMessageCode}, body : RepoBatchDataMessage ]
        \cup [ tag : {IssueEventMessageCode}, body : IssueEventMessage ]
        \cup [ tag : {IssueEventMessageCode2}, body : IssueEventMessage ]
        \cup [ tag : {IssueEventMessageCode3}, body : IssueEventMessage ]
        \cup [ tag : {IssueEventMessageCode4}, body : IssueEventMessage ]
        \cup [ tag : {IssueEventMessageCode5}, body : IssueEventMessage ]
        \cup [ tag : {IssueEventMessageCode6}, body : IssueEventMessage ]
        \cup [ tag : {IssueEventMessageCode7}, body : IssueEventMessage ]
        \cup [ tag : {IssueEventMessageCode8}, body : IssueEventMessage ]
        \cup [ tag : {IssueEventMessageCode9}, body : IssueEventMessage ]
        \cup [ tag : {IssueEventMessageCode10}, body : IssueEventMessage ]
        \cup [ tag : {IssueEventMessageCode11}, body : IssueEventMessage ]
        \cup [ tag : {CorporateBondsReferenceMessageCode}, body : CorporateBondsReferenceMessage ]
        \cup [ tag : {CorporateBondsReferenceMessageCode2}, body : CorporateBondsReferenceMessage ]
        \cup [ tag : {RegularBondsInstallmentRepaymentDateMessageCode}, body : RegularBondsInstallmentRepaymentDateMessage ]
        \cup [ tag : {RepoClassificationDataMessageCode}, body : RepoClassificationDataMessage ]
        \cup [ tag : {RepoTradeAvailabilityPerTermMessageCode}, body : RepoTradeAvailabilityPerTermMessage ]
        \cup [ tag : {RetailBondsTypeCodeMessageCode}, body : RetailBondsTypeCodeMessage ]

EncodePayload(message) ==
    CASE message.tag = PollingDataMessageCode -> EncodePollingDataMessage(message.body)
      [] message.tag = KrxIndexMessageCode -> EncodeKrxIndexMessage(message.body)
      [] message.tag = KrxEstimatedIndexMessageCode -> EncodeKrxEstimatedIndexMessage(message.body)
      [] message.tag = GlobalIndexMessageCode -> EncodeGlobalIndexMessage(message.body)
      [] message.tag = BondPrimeIndexMessageCode -> EncodeBondPrimeIndexMessage(message.body)
      [] message.tag = BondKtbIndexMessageCode -> EncodeBondKtbIndexMessage(message.body)
      [] message.tag = BondKtbIndexTermStructureMessageCode -> EncodeBondKtbIndexTermStructureMessage(message.body)
      [] message.tag = BondIndexKrxMessageCode -> EncodeBondIndexKrxMessage(message.body)
      [] message.tag = EquityDerivativesUnderlyingSnapshotKospiMessageCode -> EncodeEquityDerivativesUnderlyingSnapshotKospiMessage(message.body)
      [] message.tag = EquityDerivativesUnderlyingSnapshotKosdaqMessageCode -> EncodeEquityDerivativesUnderlyingSnapshotKosdaqMessage(message.body)
      [] message.tag = EquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessageCode -> EncodeEquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessage(message.body)
      [] message.tag = EquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessageCode2 -> EncodeEquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessage(message.body)
      [] message.tag = EquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessageCode3 -> EncodeEquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessage(message.body)
      [] message.tag = EquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessageCode4 -> EncodeEquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessage(message.body)
      [] message.tag = SecuritiesEquitiesBatchDataMessageCode -> EncodeSecuritiesEquitiesBatchDataMessage(message.body)
      [] message.tag = SecuritiesEquitiesBatchDataMessageCode2 -> EncodeSecuritiesEquitiesBatchDataMessage(message.body)
      [] message.tag = SecuritiesEquitiesBatchDataMessageCode3 -> EncodeSecuritiesEquitiesBatchDataMessage(message.body)
      [] message.tag = SecuritiesEquitiesBatchDataMessageCode4 -> EncodeSecuritiesEquitiesBatchDataMessage(message.body)
      [] message.tag = SecuritiesEquitiesBatchDataMessageCode5 -> EncodeSecuritiesEquitiesBatchDataMessage(message.body)
      [] message.tag = SecuritiesEquitiesBatchDataMessageCode6 -> EncodeSecuritiesEquitiesBatchDataMessage(message.body)
      [] message.tag = SecuritiesEquitiesBatchDataMessageCode7 -> EncodeSecuritiesEquitiesBatchDataMessage(message.body)
      [] message.tag = SecuritiesClosingDateMessageCode -> EncodeSecuritiesClosingDateMessage(message.body)
      [] message.tag = SecuritiesClosingDateMessageCode2 -> EncodeSecuritiesClosingDateMessage(message.body)
      [] message.tag = SecuritiesClosingDateMessageCode3 -> EncodeSecuritiesClosingDateMessage(message.body)
      [] message.tag = SecuritiesClosingDateMessageCode4 -> EncodeSecuritiesClosingDateMessage(message.body)
      [] message.tag = SecuritiesClosingDateMessageCode5 -> EncodeSecuritiesClosingDateMessage(message.body)
      [] message.tag = SecuritiesClosingDateMessageCode6 -> EncodeSecuritiesClosingDateMessage(message.body)
      [] message.tag = SecuritiesMmLpInformationMessageCode -> EncodeSecuritiesMmLpInformationMessage(message.body)
      [] message.tag = SecuritiesMmLpInformationMessageCode2 -> EncodeSecuritiesMmLpInformationMessage(message.body)
      [] message.tag = SecuritiesMmLpInformationMessageCode3 -> EncodeSecuritiesMmLpInformationMessage(message.body)
      [] message.tag = SecuritiesMmLpInformationMessageCode4 -> EncodeSecuritiesMmLpInformationMessage(message.body)
      [] message.tag = SecuritiesMmLpInformationMessageCode5 -> EncodeSecuritiesMmLpInformationMessage(message.body)
      [] message.tag = SecuritiesMmLpInformationMessageCode6 -> EncodeSecuritiesMmLpInformationMessage(message.body)
      [] message.tag = SecuritiesMmLpInformationMessageCode7 -> EncodeSecuritiesMmLpInformationMessage(message.body)
      [] message.tag = SecuritiesMemberInformationMessageCode -> EncodeSecuritiesMemberInformationMessage(message.body)
      [] message.tag = SecuritiesMemberInformationMessageCode2 -> EncodeSecuritiesMemberInformationMessage(message.body)
      [] message.tag = SecuritiesMemberInformationMessageCode3 -> EncodeSecuritiesMemberInformationMessage(message.body)
      [] message.tag = SecuritiesTreasuryStocksBatchMessageCode -> EncodeSecuritiesTreasuryStocksBatchMessage(message.body)
      [] message.tag = SecuritiesTreasuryStocksBatchMessageCode2 -> EncodeSecuritiesTreasuryStocksBatchMessage(message.body)
      [] message.tag = SecuritiesTreasuryStocksBatchMessageCode3 -> EncodeSecuritiesTreasuryStocksBatchMessage(message.body)
      [] message.tag = SecuritiesEquityIndexIndicatorMessageCode -> EncodeSecuritiesEquityIndexIndicatorMessage(message.body)
      [] message.tag = SecuritiesEquityIndexIndicatorMessageCode2 -> EncodeSecuritiesEquityIndexIndicatorMessage(message.body)
      [] message.tag = SecuritiesDividendYieldPerIndustryMessageCode -> EncodeSecuritiesDividendYieldPerIndustryMessage(message.body)
      [] message.tag = SecuritiesDividendYieldPerIndustryMessageCode2 -> EncodeSecuritiesDividendYieldPerIndustryMessage(message.body)
      [] message.tag = BondsBatchDataMessageCode -> EncodeBondsBatchDataMessage(message.body)
      [] message.tag = RepoBatchDataMessageCode -> EncodeRepoBatchDataMessage(message.body)
      [] message.tag = IssueEventMessageCode -> EncodeIssueEventMessage(message.body)
      [] message.tag = IssueEventMessageCode2 -> EncodeIssueEventMessage(message.body)
      [] message.tag = IssueEventMessageCode3 -> EncodeIssueEventMessage(message.body)
      [] message.tag = IssueEventMessageCode4 -> EncodeIssueEventMessage(message.body)
      [] message.tag = IssueEventMessageCode5 -> EncodeIssueEventMessage(message.body)
      [] message.tag = IssueEventMessageCode6 -> EncodeIssueEventMessage(message.body)
      [] message.tag = IssueEventMessageCode7 -> EncodeIssueEventMessage(message.body)
      [] message.tag = IssueEventMessageCode8 -> EncodeIssueEventMessage(message.body)
      [] message.tag = IssueEventMessageCode9 -> EncodeIssueEventMessage(message.body)
      [] message.tag = IssueEventMessageCode10 -> EncodeIssueEventMessage(message.body)
      [] message.tag = IssueEventMessageCode11 -> EncodeIssueEventMessage(message.body)
      [] message.tag = CorporateBondsReferenceMessageCode -> EncodeCorporateBondsReferenceMessage(message.body)
      [] message.tag = CorporateBondsReferenceMessageCode2 -> EncodeCorporateBondsReferenceMessage(message.body)
      [] message.tag = RegularBondsInstallmentRepaymentDateMessageCode -> EncodeRegularBondsInstallmentRepaymentDateMessage(message.body)
      [] message.tag = RepoClassificationDataMessageCode -> EncodeRepoClassificationDataMessage(message.body)
      [] message.tag = RepoTradeAvailabilityPerTermMessageCode -> EncodeRepoTradeAvailabilityPerTermMessage(message.body)
      [] message.tag = RetailBondsTypeCodeMessageCode -> EncodeRetailBondsTypeCodeMessage(message.body)

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
              [] tag = EquityDerivativesUnderlyingSnapshotKospiMessageCode -> DecodeEquityDerivativesUnderlyingSnapshotKospiMessage(bytes)
              [] tag = EquityDerivativesUnderlyingSnapshotKosdaqMessageCode -> DecodeEquityDerivativesUnderlyingSnapshotKosdaqMessage(bytes)
              [] tag = EquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessageCode -> DecodeEquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessage(bytes)
              [] tag = EquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessageCode2 -> DecodeEquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessage(bytes)
              [] tag = EquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessageCode3 -> DecodeEquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessage(bytes)
              [] tag = EquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessageCode4 -> DecodeEquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessage(bytes)
              [] tag = SecuritiesEquitiesBatchDataMessageCode -> DecodeSecuritiesEquitiesBatchDataMessage(bytes)
              [] tag = SecuritiesEquitiesBatchDataMessageCode2 -> DecodeSecuritiesEquitiesBatchDataMessage(bytes)
              [] tag = SecuritiesEquitiesBatchDataMessageCode3 -> DecodeSecuritiesEquitiesBatchDataMessage(bytes)
              [] tag = SecuritiesEquitiesBatchDataMessageCode4 -> DecodeSecuritiesEquitiesBatchDataMessage(bytes)
              [] tag = SecuritiesEquitiesBatchDataMessageCode5 -> DecodeSecuritiesEquitiesBatchDataMessage(bytes)
              [] tag = SecuritiesEquitiesBatchDataMessageCode6 -> DecodeSecuritiesEquitiesBatchDataMessage(bytes)
              [] tag = SecuritiesEquitiesBatchDataMessageCode7 -> DecodeSecuritiesEquitiesBatchDataMessage(bytes)
              [] tag = SecuritiesClosingDateMessageCode -> DecodeSecuritiesClosingDateMessage(bytes)
              [] tag = SecuritiesClosingDateMessageCode2 -> DecodeSecuritiesClosingDateMessage(bytes)
              [] tag = SecuritiesClosingDateMessageCode3 -> DecodeSecuritiesClosingDateMessage(bytes)
              [] tag = SecuritiesClosingDateMessageCode4 -> DecodeSecuritiesClosingDateMessage(bytes)
              [] tag = SecuritiesClosingDateMessageCode5 -> DecodeSecuritiesClosingDateMessage(bytes)
              [] tag = SecuritiesClosingDateMessageCode6 -> DecodeSecuritiesClosingDateMessage(bytes)
              [] tag = SecuritiesMmLpInformationMessageCode -> DecodeSecuritiesMmLpInformationMessage(bytes)
              [] tag = SecuritiesMmLpInformationMessageCode2 -> DecodeSecuritiesMmLpInformationMessage(bytes)
              [] tag = SecuritiesMmLpInformationMessageCode3 -> DecodeSecuritiesMmLpInformationMessage(bytes)
              [] tag = SecuritiesMmLpInformationMessageCode4 -> DecodeSecuritiesMmLpInformationMessage(bytes)
              [] tag = SecuritiesMmLpInformationMessageCode5 -> DecodeSecuritiesMmLpInformationMessage(bytes)
              [] tag = SecuritiesMmLpInformationMessageCode6 -> DecodeSecuritiesMmLpInformationMessage(bytes)
              [] tag = SecuritiesMmLpInformationMessageCode7 -> DecodeSecuritiesMmLpInformationMessage(bytes)
              [] tag = SecuritiesMemberInformationMessageCode -> DecodeSecuritiesMemberInformationMessage(bytes)
              [] tag = SecuritiesMemberInformationMessageCode2 -> DecodeSecuritiesMemberInformationMessage(bytes)
              [] tag = SecuritiesMemberInformationMessageCode3 -> DecodeSecuritiesMemberInformationMessage(bytes)
              [] tag = SecuritiesTreasuryStocksBatchMessageCode -> DecodeSecuritiesTreasuryStocksBatchMessage(bytes)
              [] tag = SecuritiesTreasuryStocksBatchMessageCode2 -> DecodeSecuritiesTreasuryStocksBatchMessage(bytes)
              [] tag = SecuritiesTreasuryStocksBatchMessageCode3 -> DecodeSecuritiesTreasuryStocksBatchMessage(bytes)
              [] tag = SecuritiesEquityIndexIndicatorMessageCode -> DecodeSecuritiesEquityIndexIndicatorMessage(bytes)
              [] tag = SecuritiesEquityIndexIndicatorMessageCode2 -> DecodeSecuritiesEquityIndexIndicatorMessage(bytes)
              [] tag = SecuritiesDividendYieldPerIndustryMessageCode -> DecodeSecuritiesDividendYieldPerIndustryMessage(bytes)
              [] tag = SecuritiesDividendYieldPerIndustryMessageCode2 -> DecodeSecuritiesDividendYieldPerIndustryMessage(bytes)
              [] tag = BondsBatchDataMessageCode -> DecodeBondsBatchDataMessage(bytes)
              [] tag = RepoBatchDataMessageCode -> DecodeRepoBatchDataMessage(bytes)
              [] tag = IssueEventMessageCode -> DecodeIssueEventMessage(bytes)
              [] tag = IssueEventMessageCode2 -> DecodeIssueEventMessage(bytes)
              [] tag = IssueEventMessageCode3 -> DecodeIssueEventMessage(bytes)
              [] tag = IssueEventMessageCode4 -> DecodeIssueEventMessage(bytes)
              [] tag = IssueEventMessageCode5 -> DecodeIssueEventMessage(bytes)
              [] tag = IssueEventMessageCode6 -> DecodeIssueEventMessage(bytes)
              [] tag = IssueEventMessageCode7 -> DecodeIssueEventMessage(bytes)
              [] tag = IssueEventMessageCode8 -> DecodeIssueEventMessage(bytes)
              [] tag = IssueEventMessageCode9 -> DecodeIssueEventMessage(bytes)
              [] tag = IssueEventMessageCode10 -> DecodeIssueEventMessage(bytes)
              [] tag = IssueEventMessageCode11 -> DecodeIssueEventMessage(bytes)
              [] tag = CorporateBondsReferenceMessageCode -> DecodeCorporateBondsReferenceMessage(bytes)
              [] tag = CorporateBondsReferenceMessageCode2 -> DecodeCorporateBondsReferenceMessage(bytes)
              [] tag = RegularBondsInstallmentRepaymentDateMessageCode -> DecodeRegularBondsInstallmentRepaymentDateMessage(bytes)
              [] tag = RepoClassificationDataMessageCode -> DecodeRepoClassificationDataMessage(bytes)
              [] tag = RepoTradeAvailabilityPerTermMessageCode -> DecodeRepoTradeAvailabilityPerTermMessage(bytes)
              [] tag = RetailBondsTypeCodeMessageCode -> DecodeRetailBondsTypeCodeMessage(bytes)
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
        \cup { [tag |-> EquityDerivativesUnderlyingSnapshotKospiMessageCode, body |-> one] : one \in CheckedEquityDerivativesUnderlyingSnapshotKospiMessage }
        \cup { [tag |-> EquityDerivativesUnderlyingSnapshotKosdaqMessageCode, body |-> one] : one \in CheckedEquityDerivativesUnderlyingSnapshotKosdaqMessage }
        \cup { [tag |-> EquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessageCode, body |-> one] : one \in CheckedEquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessage }
        \cup { [tag |-> EquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessageCode2, body |-> one] : one \in CheckedEquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessage }
        \cup { [tag |-> EquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessageCode3, body |-> one] : one \in CheckedEquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessage }
        \cup { [tag |-> EquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessageCode4, body |-> one] : one \in CheckedEquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessage }
        \cup { [tag |-> SecuritiesEquitiesBatchDataMessageCode, body |-> one] : one \in CheckedSecuritiesEquitiesBatchDataMessage }
        \cup { [tag |-> SecuritiesEquitiesBatchDataMessageCode2, body |-> one] : one \in CheckedSecuritiesEquitiesBatchDataMessage }
        \cup { [tag |-> SecuritiesEquitiesBatchDataMessageCode3, body |-> one] : one \in CheckedSecuritiesEquitiesBatchDataMessage }
        \cup { [tag |-> SecuritiesEquitiesBatchDataMessageCode4, body |-> one] : one \in CheckedSecuritiesEquitiesBatchDataMessage }
        \cup { [tag |-> SecuritiesEquitiesBatchDataMessageCode5, body |-> one] : one \in CheckedSecuritiesEquitiesBatchDataMessage }
        \cup { [tag |-> SecuritiesEquitiesBatchDataMessageCode6, body |-> one] : one \in CheckedSecuritiesEquitiesBatchDataMessage }
        \cup { [tag |-> SecuritiesEquitiesBatchDataMessageCode7, body |-> one] : one \in CheckedSecuritiesEquitiesBatchDataMessage }
        \cup { [tag |-> SecuritiesClosingDateMessageCode, body |-> one] : one \in CheckedSecuritiesClosingDateMessage }
        \cup { [tag |-> SecuritiesClosingDateMessageCode2, body |-> one] : one \in CheckedSecuritiesClosingDateMessage }
        \cup { [tag |-> SecuritiesClosingDateMessageCode3, body |-> one] : one \in CheckedSecuritiesClosingDateMessage }
        \cup { [tag |-> SecuritiesClosingDateMessageCode4, body |-> one] : one \in CheckedSecuritiesClosingDateMessage }
        \cup { [tag |-> SecuritiesClosingDateMessageCode5, body |-> one] : one \in CheckedSecuritiesClosingDateMessage }
        \cup { [tag |-> SecuritiesClosingDateMessageCode6, body |-> one] : one \in CheckedSecuritiesClosingDateMessage }
        \cup { [tag |-> SecuritiesMmLpInformationMessageCode, body |-> one] : one \in CheckedSecuritiesMmLpInformationMessage }
        \cup { [tag |-> SecuritiesMmLpInformationMessageCode2, body |-> one] : one \in CheckedSecuritiesMmLpInformationMessage }
        \cup { [tag |-> SecuritiesMmLpInformationMessageCode3, body |-> one] : one \in CheckedSecuritiesMmLpInformationMessage }
        \cup { [tag |-> SecuritiesMmLpInformationMessageCode4, body |-> one] : one \in CheckedSecuritiesMmLpInformationMessage }
        \cup { [tag |-> SecuritiesMmLpInformationMessageCode5, body |-> one] : one \in CheckedSecuritiesMmLpInformationMessage }
        \cup { [tag |-> SecuritiesMmLpInformationMessageCode6, body |-> one] : one \in CheckedSecuritiesMmLpInformationMessage }
        \cup { [tag |-> SecuritiesMmLpInformationMessageCode7, body |-> one] : one \in CheckedSecuritiesMmLpInformationMessage }
        \cup { [tag |-> SecuritiesMemberInformationMessageCode, body |-> one] : one \in CheckedSecuritiesMemberInformationMessage }
        \cup { [tag |-> SecuritiesMemberInformationMessageCode2, body |-> one] : one \in CheckedSecuritiesMemberInformationMessage }
        \cup { [tag |-> SecuritiesMemberInformationMessageCode3, body |-> one] : one \in CheckedSecuritiesMemberInformationMessage }
        \cup { [tag |-> SecuritiesTreasuryStocksBatchMessageCode, body |-> one] : one \in CheckedSecuritiesTreasuryStocksBatchMessage }
        \cup { [tag |-> SecuritiesTreasuryStocksBatchMessageCode2, body |-> one] : one \in CheckedSecuritiesTreasuryStocksBatchMessage }
        \cup { [tag |-> SecuritiesTreasuryStocksBatchMessageCode3, body |-> one] : one \in CheckedSecuritiesTreasuryStocksBatchMessage }
        \cup { [tag |-> SecuritiesEquityIndexIndicatorMessageCode, body |-> one] : one \in CheckedSecuritiesEquityIndexIndicatorMessage }
        \cup { [tag |-> SecuritiesEquityIndexIndicatorMessageCode2, body |-> one] : one \in CheckedSecuritiesEquityIndexIndicatorMessage }
        \cup { [tag |-> SecuritiesDividendYieldPerIndustryMessageCode, body |-> one] : one \in CheckedSecuritiesDividendYieldPerIndustryMessage }
        \cup { [tag |-> SecuritiesDividendYieldPerIndustryMessageCode2, body |-> one] : one \in CheckedSecuritiesDividendYieldPerIndustryMessage }
        \cup { [tag |-> BondsBatchDataMessageCode, body |-> one] : one \in CheckedBondsBatchDataMessage }
        \cup { [tag |-> RepoBatchDataMessageCode, body |-> one] : one \in CheckedRepoBatchDataMessage }
        \cup { [tag |-> IssueEventMessageCode, body |-> one] : one \in CheckedIssueEventMessage }
        \cup { [tag |-> IssueEventMessageCode2, body |-> one] : one \in CheckedIssueEventMessage }
        \cup { [tag |-> IssueEventMessageCode3, body |-> one] : one \in CheckedIssueEventMessage }
        \cup { [tag |-> IssueEventMessageCode4, body |-> one] : one \in CheckedIssueEventMessage }
        \cup { [tag |-> IssueEventMessageCode5, body |-> one] : one \in CheckedIssueEventMessage }
        \cup { [tag |-> IssueEventMessageCode6, body |-> one] : one \in CheckedIssueEventMessage }
        \cup { [tag |-> IssueEventMessageCode7, body |-> one] : one \in CheckedIssueEventMessage }
        \cup { [tag |-> IssueEventMessageCode8, body |-> one] : one \in CheckedIssueEventMessage }
        \cup { [tag |-> IssueEventMessageCode9, body |-> one] : one \in CheckedIssueEventMessage }
        \cup { [tag |-> IssueEventMessageCode10, body |-> one] : one \in CheckedIssueEventMessage }
        \cup { [tag |-> IssueEventMessageCode11, body |-> one] : one \in CheckedIssueEventMessage }
        \cup { [tag |-> CorporateBondsReferenceMessageCode, body |-> one] : one \in CheckedCorporateBondsReferenceMessage }
        \cup { [tag |-> CorporateBondsReferenceMessageCode2, body |-> one] : one \in CheckedCorporateBondsReferenceMessage }
        \cup { [tag |-> RegularBondsInstallmentRepaymentDateMessageCode, body |-> one] : one \in CheckedRegularBondsInstallmentRepaymentDateMessage }
        \cup { [tag |-> RepoClassificationDataMessageCode, body |-> one] : one \in CheckedRepoClassificationDataMessage }
        \cup { [tag |-> RepoTradeAvailabilityPerTermMessageCode, body |-> one] : one \in CheckedRepoTradeAvailabilityPerTermMessage }
        \cup { [tag |-> RetailBondsTypeCodeMessageCode, body |-> one] : one \in CheckedRetailBondsTypeCodeMessage }

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
      [ZeroPacket EXCEPT !.payload = [tag |-> EquityDerivativesUnderlyingSnapshotKospiMessageCode, body |-> ZeroEquityDerivativesUnderlyingSnapshotKospiMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> EquityDerivativesUnderlyingSnapshotKosdaqMessageCode, body |-> ZeroEquityDerivativesUnderlyingSnapshotKosdaqMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> EquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessageCode, body |-> ZeroEquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> EquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessageCode2, body |-> ZeroEquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> EquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessageCode3, body |-> ZeroEquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> EquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessageCode4, body |-> ZeroEquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesEquitiesBatchDataMessageCode, body |-> ZeroSecuritiesEquitiesBatchDataMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesEquitiesBatchDataMessageCode2, body |-> ZeroSecuritiesEquitiesBatchDataMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesEquitiesBatchDataMessageCode3, body |-> ZeroSecuritiesEquitiesBatchDataMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesEquitiesBatchDataMessageCode4, body |-> ZeroSecuritiesEquitiesBatchDataMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesEquitiesBatchDataMessageCode5, body |-> ZeroSecuritiesEquitiesBatchDataMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesEquitiesBatchDataMessageCode6, body |-> ZeroSecuritiesEquitiesBatchDataMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesEquitiesBatchDataMessageCode7, body |-> ZeroSecuritiesEquitiesBatchDataMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesClosingDateMessageCode, body |-> ZeroSecuritiesClosingDateMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesClosingDateMessageCode2, body |-> ZeroSecuritiesClosingDateMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesClosingDateMessageCode3, body |-> ZeroSecuritiesClosingDateMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesClosingDateMessageCode4, body |-> ZeroSecuritiesClosingDateMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesClosingDateMessageCode5, body |-> ZeroSecuritiesClosingDateMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesClosingDateMessageCode6, body |-> ZeroSecuritiesClosingDateMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMmLpInformationMessageCode, body |-> ZeroSecuritiesMmLpInformationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMmLpInformationMessageCode2, body |-> ZeroSecuritiesMmLpInformationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMmLpInformationMessageCode3, body |-> ZeroSecuritiesMmLpInformationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMmLpInformationMessageCode4, body |-> ZeroSecuritiesMmLpInformationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMmLpInformationMessageCode5, body |-> ZeroSecuritiesMmLpInformationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMmLpInformationMessageCode6, body |-> ZeroSecuritiesMmLpInformationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMmLpInformationMessageCode7, body |-> ZeroSecuritiesMmLpInformationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMemberInformationMessageCode, body |-> ZeroSecuritiesMemberInformationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMemberInformationMessageCode2, body |-> ZeroSecuritiesMemberInformationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMemberInformationMessageCode3, body |-> ZeroSecuritiesMemberInformationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesTreasuryStocksBatchMessageCode, body |-> ZeroSecuritiesTreasuryStocksBatchMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesTreasuryStocksBatchMessageCode2, body |-> ZeroSecuritiesTreasuryStocksBatchMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesTreasuryStocksBatchMessageCode3, body |-> ZeroSecuritiesTreasuryStocksBatchMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesEquityIndexIndicatorMessageCode, body |-> ZeroSecuritiesEquityIndexIndicatorMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesEquityIndexIndicatorMessageCode2, body |-> ZeroSecuritiesEquityIndexIndicatorMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesDividendYieldPerIndustryMessageCode, body |-> ZeroSecuritiesDividendYieldPerIndustryMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesDividendYieldPerIndustryMessageCode2, body |-> ZeroSecuritiesDividendYieldPerIndustryMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> BondsBatchDataMessageCode, body |-> ZeroBondsBatchDataMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> RepoBatchDataMessageCode, body |-> ZeroRepoBatchDataMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> IssueEventMessageCode, body |-> ZeroIssueEventMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> IssueEventMessageCode2, body |-> ZeroIssueEventMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> IssueEventMessageCode3, body |-> ZeroIssueEventMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> IssueEventMessageCode4, body |-> ZeroIssueEventMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> IssueEventMessageCode5, body |-> ZeroIssueEventMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> IssueEventMessageCode6, body |-> ZeroIssueEventMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> IssueEventMessageCode7, body |-> ZeroIssueEventMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> IssueEventMessageCode8, body |-> ZeroIssueEventMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> IssueEventMessageCode9, body |-> ZeroIssueEventMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> IssueEventMessageCode10, body |-> ZeroIssueEventMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> IssueEventMessageCode11, body |-> ZeroIssueEventMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> CorporateBondsReferenceMessageCode, body |-> ZeroCorporateBondsReferenceMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> CorporateBondsReferenceMessageCode2, body |-> ZeroCorporateBondsReferenceMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> RegularBondsInstallmentRepaymentDateMessageCode, body |-> ZeroRegularBondsInstallmentRepaymentDateMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> RepoClassificationDataMessageCode, body |-> ZeroRepoClassificationDataMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> RepoTradeAvailabilityPerTermMessageCode, body |-> ZeroRepoTradeAvailabilityPerTermMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> RetailBondsTypeCodeMessageCode, body |-> ZeroRetailBondsTypeCodeMessage]] }

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

(* Every Equity Derivatives Underlying Snapshot Kospi Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEquityDerivativesUnderlyingSnapshotKospiMessage ==
    \A message \in CheckedEquityDerivativesUnderlyingSnapshotKospiMessage :
        LET read == DecodeEquityDerivativesUnderlyingSnapshotKospiMessage(EncodeEquityDerivativesUnderlyingSnapshotKospiMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Equity Derivatives Underlying Snapshot Kosdaq Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEquityDerivativesUnderlyingSnapshotKosdaqMessage ==
    \A message \in CheckedEquityDerivativesUnderlyingSnapshotKosdaqMessage :
        LET read == DecodeEquityDerivativesUnderlyingSnapshotKosdaqMessage(EncodeEquityDerivativesUnderlyingSnapshotKosdaqMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Equity Derivatives Underlying Snapshot Kospi Mm Lp Included Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessage ==
    \A message \in CheckedEquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessage :
        LET read == DecodeEquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessage(EncodeEquityDerivativesUnderlyingSnapshotKospiMmLpIncludedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Securities Equities Batch Data Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecuritiesEquitiesBatchDataMessage ==
    \A message \in CheckedSecuritiesEquitiesBatchDataMessage :
        LET read == DecodeSecuritiesEquitiesBatchDataMessage(EncodeSecuritiesEquitiesBatchDataMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Securities Closing Date Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecuritiesClosingDateMessage ==
    \A message \in CheckedSecuritiesClosingDateMessage :
        LET read == DecodeSecuritiesClosingDateMessage(EncodeSecuritiesClosingDateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Securities Mm Lp Information Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecuritiesMmLpInformationMessage ==
    \A message \in CheckedSecuritiesMmLpInformationMessage :
        LET read == DecodeSecuritiesMmLpInformationMessage(EncodeSecuritiesMmLpInformationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Securities Member Information Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecuritiesMemberInformationMessage ==
    \A message \in CheckedSecuritiesMemberInformationMessage :
        LET read == DecodeSecuritiesMemberInformationMessage(EncodeSecuritiesMemberInformationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Securities Treasury Stocks Batch Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecuritiesTreasuryStocksBatchMessage ==
    \A message \in CheckedSecuritiesTreasuryStocksBatchMessage :
        LET read == DecodeSecuritiesTreasuryStocksBatchMessage(EncodeSecuritiesTreasuryStocksBatchMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Securities Equity Index Indicator Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecuritiesEquityIndexIndicatorMessage ==
    \A message \in CheckedSecuritiesEquityIndexIndicatorMessage :
        LET read == DecodeSecuritiesEquityIndexIndicatorMessage(EncodeSecuritiesEquityIndexIndicatorMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Securities Dividend Yield Per Industry Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecuritiesDividendYieldPerIndustryMessage ==
    \A message \in CheckedSecuritiesDividendYieldPerIndustryMessage :
        LET read == DecodeSecuritiesDividendYieldPerIndustryMessage(EncodeSecuritiesDividendYieldPerIndustryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bonds Batch Data Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBondsBatchDataMessage ==
    \A message \in CheckedBondsBatchDataMessage :
        LET read == DecodeBondsBatchDataMessage(EncodeBondsBatchDataMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Repo Batch Data Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRepoBatchDataMessage ==
    \A message \in CheckedRepoBatchDataMessage :
        LET read == DecodeRepoBatchDataMessage(EncodeRepoBatchDataMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Issue Event Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIssueEventMessage ==
    \A message \in CheckedIssueEventMessage :
        LET read == DecodeIssueEventMessage(EncodeIssueEventMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Corporate Bonds Reference Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCorporateBondsReferenceMessage ==
    \A message \in CheckedCorporateBondsReferenceMessage :
        LET read == DecodeCorporateBondsReferenceMessage(EncodeCorporateBondsReferenceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Regular Bonds Installment Repayment Date Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRegularBondsInstallmentRepaymentDateMessage ==
    \A message \in CheckedRegularBondsInstallmentRepaymentDateMessage :
        LET read == DecodeRegularBondsInstallmentRepaymentDateMessage(EncodeRegularBondsInstallmentRepaymentDateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Repo Classification Data Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRepoClassificationDataMessage ==
    \A message \in CheckedRepoClassificationDataMessage :
        LET read == DecodeRepoClassificationDataMessage(EncodeRepoClassificationDataMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Repo Trade Availability Per Term Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRepoTradeAvailabilityPerTermMessage ==
    \A message \in CheckedRepoTradeAvailabilityPerTermMessage :
        LET read == DecodeRepoTradeAvailabilityPerTermMessage(EncodeRepoTradeAvailabilityPerTermMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Retail Bonds Type Code Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRetailBondsTypeCodeMessage ==
    \A message \in CheckedRetailBondsTypeCodeMessage :
        LET read == DecodeRetailBondsTypeCodeMessage(EncodeRetailBondsTypeCodeMessage(message))
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
