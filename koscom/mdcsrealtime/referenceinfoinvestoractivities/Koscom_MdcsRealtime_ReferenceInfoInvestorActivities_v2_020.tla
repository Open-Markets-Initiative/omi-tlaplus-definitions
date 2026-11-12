---- MODULE Koscom_MdcsRealtime_ReferenceInfoInvestorActivities_v2_020 -----
(***************************************************************************)
(* Koscom Co., Ltd. MDCS Realtime Reference Info and Investor Activities   *)
(* v2.020                                                                  *)
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
      accumulatedTradingValue              : Sample(12),
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
        \o message.accumulatedTradingValue
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
    LET accumulatedTradingValue == ReadBytes(accumulatedTradingVolume.rest, 12) IN IF ~accumulatedTradingValue.ok THEN Fail ELSE
    LET filler4 == ReadBytes(accumulatedTradingValue.rest, 4) IN IF ~filler4.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler4.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ indexId                              |-> indexId.value,
         isinCode                             |-> isinCode.value,
         calculationTime                      |-> calculationTime.value,
         index                                |-> index.value,
         indexChangeSignAgainstThePreviousDay |-> indexChangeSignAgainstThePreviousDay.value,
         indexChangeAgainstThePreviousDay     |-> indexChangeAgainstThePreviousDay.value,
         accumulatedTradingVolume             |-> accumulatedTradingVolume.value,
         accumulatedTradingValue              |-> accumulatedTradingValue.value,
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
      accumulatedTradingValue              |-> [i \in 1 .. 12 |-> 0],
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
        \cup { [ZeroKrxIndexMessage EXCEPT !.accumulatedTradingValue = one] : one \in Sample(12) }
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
      accumulatedTradingValue              : Sample(12),
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
        \o message.accumulatedTradingValue
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
    LET accumulatedTradingValue == ReadBytes(accumulatedTradingVolume.rest, 12) IN IF ~accumulatedTradingValue.ok THEN Fail ELSE
    LET filler4 == ReadBytes(accumulatedTradingValue.rest, 4) IN IF ~filler4.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler4.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ indexId                              |-> indexId.value,
         isinCode                             |-> isinCode.value,
         calculationTime                      |-> calculationTime.value,
         index                                |-> index.value,
         indexChangeSignAgainstThePreviousDay |-> indexChangeSignAgainstThePreviousDay.value,
         indexChangeAgainstThePreviousDay     |-> indexChangeAgainstThePreviousDay.value,
         accumulatedTradingVolume             |-> accumulatedTradingVolume.value,
         accumulatedTradingValue              |-> accumulatedTradingValue.value,
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
      accumulatedTradingValue              |-> [i \in 1 .. 12 |-> 0],
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
        \cup { [ZeroKrxEstimatedIndexMessage EXCEPT !.accumulatedTradingValue = one] : one \in Sample(12) }
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
(* Securities Investor Activities Per Industry Message: 100 bytes          *)
(***************************************************************************)

SecuritiesInvestorActivitiesPerIndustryMessage ==
    [ calculationTime             : Sample(6),
      investorCode                : Sample(4),
      indexId                     : Sample(6),
      isinCode                    : Sample(12),
      accumulatedAskTradingVolume : Sample(12),
      accumulatedAskTradingValue  : Sample(22),
      accumulatedBidTradingVolume : Sample(12),
      accumulatedBidTradingValue  : Sample(22),
      filler3                     : Sample(3),
      endKeyword                  : Sample(1) ]

EncodeSecuritiesInvestorActivitiesPerIndustryMessage(message) ==
    message.calculationTime
        \o message.investorCode
        \o message.indexId
        \o message.isinCode
        \o message.accumulatedAskTradingVolume
        \o message.accumulatedAskTradingValue
        \o message.accumulatedBidTradingVolume
        \o message.accumulatedBidTradingValue
        \o message.filler3
        \o message.endKeyword

DecodeSecuritiesInvestorActivitiesPerIndustryMessage(bytes) ==
    LET calculationTime == ReadBytes(bytes, 6) IN IF ~calculationTime.ok THEN Fail ELSE
    LET investorCode == ReadBytes(calculationTime.rest, 4) IN IF ~investorCode.ok THEN Fail ELSE
    LET indexId == ReadBytes(investorCode.rest, 6) IN IF ~indexId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(indexId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET accumulatedAskTradingVolume == ReadBytes(isinCode.rest, 12) IN IF ~accumulatedAskTradingVolume.ok THEN Fail ELSE
    LET accumulatedAskTradingValue == ReadBytes(accumulatedAskTradingVolume.rest, 22) IN IF ~accumulatedAskTradingValue.ok THEN Fail ELSE
    LET accumulatedBidTradingVolume == ReadBytes(accumulatedAskTradingValue.rest, 12) IN IF ~accumulatedBidTradingVolume.ok THEN Fail ELSE
    LET accumulatedBidTradingValue == ReadBytes(accumulatedBidTradingVolume.rest, 22) IN IF ~accumulatedBidTradingValue.ok THEN Fail ELSE
    LET filler3 == ReadBytes(accumulatedBidTradingValue.rest, 3) IN IF ~filler3.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler3.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ calculationTime             |-> calculationTime.value,
         investorCode                |-> investorCode.value,
         indexId                     |-> indexId.value,
         isinCode                    |-> isinCode.value,
         accumulatedAskTradingVolume |-> accumulatedAskTradingVolume.value,
         accumulatedAskTradingValue  |-> accumulatedAskTradingValue.value,
         accumulatedBidTradingVolume |-> accumulatedBidTradingVolume.value,
         accumulatedBidTradingValue  |-> accumulatedBidTradingValue.value,
         filler3                     |-> filler3.value,
         endKeyword                  |-> endKeyword.value ], endKeyword.rest)

ZeroSecuritiesInvestorActivitiesPerIndustryMessage ==
    [ calculationTime             |-> [i \in 1 .. 6 |-> 0],
      investorCode                |-> [i \in 1 .. 4 |-> 0],
      indexId                     |-> [i \in 1 .. 6 |-> 0],
      isinCode                    |-> [i \in 1 .. 12 |-> 0],
      accumulatedAskTradingVolume |-> [i \in 1 .. 12 |-> 0],
      accumulatedAskTradingValue  |-> [i \in 1 .. 22 |-> 0],
      accumulatedBidTradingVolume |-> [i \in 1 .. 12 |-> 0],
      accumulatedBidTradingValue  |-> [i \in 1 .. 22 |-> 0],
      filler3                     |-> [i \in 1 .. 3 |-> 0],
      endKeyword                  |-> [i \in 1 .. 1 |-> 0] ]

(* Securities Investor Activities Per Industry Message at zero, then each field in turn at the values it is checked at *)
CheckedSecuritiesInvestorActivitiesPerIndustryMessage ==
    { ZeroSecuritiesInvestorActivitiesPerIndustryMessage }
        \cup { [ZeroSecuritiesInvestorActivitiesPerIndustryMessage EXCEPT !.calculationTime = one] : one \in Sample(6) }
        \cup { [ZeroSecuritiesInvestorActivitiesPerIndustryMessage EXCEPT !.investorCode = one] : one \in Sample(4) }
        \cup { [ZeroSecuritiesInvestorActivitiesPerIndustryMessage EXCEPT !.indexId = one] : one \in Sample(6) }
        \cup { [ZeroSecuritiesInvestorActivitiesPerIndustryMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesInvestorActivitiesPerIndustryMessage EXCEPT !.accumulatedAskTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesInvestorActivitiesPerIndustryMessage EXCEPT !.accumulatedAskTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroSecuritiesInvestorActivitiesPerIndustryMessage EXCEPT !.accumulatedBidTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesInvestorActivitiesPerIndustryMessage EXCEPT !.accumulatedBidTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroSecuritiesInvestorActivitiesPerIndustryMessage EXCEPT !.filler3 = one] : one \in Sample(3) }
        \cup { [ZeroSecuritiesInvestorActivitiesPerIndustryMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Securities Investor Activities Per Issue Eod Message: 91 bytes          *)
(***************************************************************************)

SecuritiesInvestorActivitiesPerIssueEodMessage ==
    [ isinCode                    : Sample(12),
      aDesignatedNumberForAnIssue : Sample(6),
      investorCode                : Sample(4),
      accumulatedAskTradingVolume : Sample(12),
      accumulatedAskTradingValue  : Sample(22),
      accumulatedBidTradingVolume : Sample(12),
      accumulatedBidTradingValue  : Sample(22),
      endKeyword                  : Sample(1) ]

EncodeSecuritiesInvestorActivitiesPerIssueEodMessage(message) ==
    message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.investorCode
        \o message.accumulatedAskTradingVolume
        \o message.accumulatedAskTradingValue
        \o message.accumulatedBidTradingVolume
        \o message.accumulatedBidTradingValue
        \o message.endKeyword

DecodeSecuritiesInvestorActivitiesPerIssueEodMessage(bytes) ==
    LET isinCode == ReadBytes(bytes, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET investorCode == ReadBytes(aDesignatedNumberForAnIssue.rest, 4) IN IF ~investorCode.ok THEN Fail ELSE
    LET accumulatedAskTradingVolume == ReadBytes(investorCode.rest, 12) IN IF ~accumulatedAskTradingVolume.ok THEN Fail ELSE
    LET accumulatedAskTradingValue == ReadBytes(accumulatedAskTradingVolume.rest, 22) IN IF ~accumulatedAskTradingValue.ok THEN Fail ELSE
    LET accumulatedBidTradingVolume == ReadBytes(accumulatedAskTradingValue.rest, 12) IN IF ~accumulatedBidTradingVolume.ok THEN Fail ELSE
    LET accumulatedBidTradingValue == ReadBytes(accumulatedBidTradingVolume.rest, 22) IN IF ~accumulatedBidTradingValue.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(accumulatedBidTradingValue.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ isinCode                    |-> isinCode.value,
         aDesignatedNumberForAnIssue |-> aDesignatedNumberForAnIssue.value,
         investorCode                |-> investorCode.value,
         accumulatedAskTradingVolume |-> accumulatedAskTradingVolume.value,
         accumulatedAskTradingValue  |-> accumulatedAskTradingValue.value,
         accumulatedBidTradingVolume |-> accumulatedBidTradingVolume.value,
         accumulatedBidTradingValue  |-> accumulatedBidTradingValue.value,
         endKeyword                  |-> endKeyword.value ], endKeyword.rest)

ZeroSecuritiesInvestorActivitiesPerIssueEodMessage ==
    [ isinCode                    |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue |-> [i \in 1 .. 6 |-> 0],
      investorCode                |-> [i \in 1 .. 4 |-> 0],
      accumulatedAskTradingVolume |-> [i \in 1 .. 12 |-> 0],
      accumulatedAskTradingValue  |-> [i \in 1 .. 22 |-> 0],
      accumulatedBidTradingVolume |-> [i \in 1 .. 12 |-> 0],
      accumulatedBidTradingValue  |-> [i \in 1 .. 22 |-> 0],
      endKeyword                  |-> [i \in 1 .. 1 |-> 0] ]

(* Securities Investor Activities Per Issue Eod Message at zero, then each field in turn at the values it is checked at *)
CheckedSecuritiesInvestorActivitiesPerIssueEodMessage ==
    { ZeroSecuritiesInvestorActivitiesPerIssueEodMessage }
        \cup { [ZeroSecuritiesInvestorActivitiesPerIssueEodMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesInvestorActivitiesPerIssueEodMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroSecuritiesInvestorActivitiesPerIssueEodMessage EXCEPT !.investorCode = one] : one \in Sample(4) }
        \cup { [ZeroSecuritiesInvestorActivitiesPerIssueEodMessage EXCEPT !.accumulatedAskTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesInvestorActivitiesPerIssueEodMessage EXCEPT !.accumulatedAskTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroSecuritiesInvestorActivitiesPerIssueEodMessage EXCEPT !.accumulatedBidTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesInvestorActivitiesPerIssueEodMessage EXCEPT !.accumulatedBidTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroSecuritiesInvestorActivitiesPerIssueEodMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Securities Investor Activities Per Commodities Message: 79 bytes        *)
(***************************************************************************)

SecuritiesInvestorActivitiesPerCommoditiesMessage ==
    [ calculationTime             : Sample(6),
      investorCode                : Sample(4),
      accumulatedAskTradingVolume : Sample(12),
      accumulatedAskTradingValue  : Sample(22),
      accumulatedBidTradingVolume : Sample(12),
      accumulatedBidTradingValue  : Sample(22),
      endKeyword                  : Sample(1) ]

EncodeSecuritiesInvestorActivitiesPerCommoditiesMessage(message) ==
    message.calculationTime
        \o message.investorCode
        \o message.accumulatedAskTradingVolume
        \o message.accumulatedAskTradingValue
        \o message.accumulatedBidTradingVolume
        \o message.accumulatedBidTradingValue
        \o message.endKeyword

DecodeSecuritiesInvestorActivitiesPerCommoditiesMessage(bytes) ==
    LET calculationTime == ReadBytes(bytes, 6) IN IF ~calculationTime.ok THEN Fail ELSE
    LET investorCode == ReadBytes(calculationTime.rest, 4) IN IF ~investorCode.ok THEN Fail ELSE
    LET accumulatedAskTradingVolume == ReadBytes(investorCode.rest, 12) IN IF ~accumulatedAskTradingVolume.ok THEN Fail ELSE
    LET accumulatedAskTradingValue == ReadBytes(accumulatedAskTradingVolume.rest, 22) IN IF ~accumulatedAskTradingValue.ok THEN Fail ELSE
    LET accumulatedBidTradingVolume == ReadBytes(accumulatedAskTradingValue.rest, 12) IN IF ~accumulatedBidTradingVolume.ok THEN Fail ELSE
    LET accumulatedBidTradingValue == ReadBytes(accumulatedBidTradingVolume.rest, 22) IN IF ~accumulatedBidTradingValue.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(accumulatedBidTradingValue.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ calculationTime             |-> calculationTime.value,
         investorCode                |-> investorCode.value,
         accumulatedAskTradingVolume |-> accumulatedAskTradingVolume.value,
         accumulatedAskTradingValue  |-> accumulatedAskTradingValue.value,
         accumulatedBidTradingVolume |-> accumulatedBidTradingVolume.value,
         accumulatedBidTradingValue  |-> accumulatedBidTradingValue.value,
         endKeyword                  |-> endKeyword.value ], endKeyword.rest)

ZeroSecuritiesInvestorActivitiesPerCommoditiesMessage ==
    [ calculationTime             |-> [i \in 1 .. 6 |-> 0],
      investorCode                |-> [i \in 1 .. 4 |-> 0],
      accumulatedAskTradingVolume |-> [i \in 1 .. 12 |-> 0],
      accumulatedAskTradingValue  |-> [i \in 1 .. 22 |-> 0],
      accumulatedBidTradingVolume |-> [i \in 1 .. 12 |-> 0],
      accumulatedBidTradingValue  |-> [i \in 1 .. 22 |-> 0],
      endKeyword                  |-> [i \in 1 .. 1 |-> 0] ]

(* Securities Investor Activities Per Commodities Message at zero, then each field in turn at the values it is checked at *)
CheckedSecuritiesInvestorActivitiesPerCommoditiesMessage ==
    { ZeroSecuritiesInvestorActivitiesPerCommoditiesMessage }
        \cup { [ZeroSecuritiesInvestorActivitiesPerCommoditiesMessage EXCEPT !.calculationTime = one] : one \in Sample(6) }
        \cup { [ZeroSecuritiesInvestorActivitiesPerCommoditiesMessage EXCEPT !.investorCode = one] : one \in Sample(4) }
        \cup { [ZeroSecuritiesInvestorActivitiesPerCommoditiesMessage EXCEPT !.accumulatedAskTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesInvestorActivitiesPerCommoditiesMessage EXCEPT !.accumulatedAskTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroSecuritiesInvestorActivitiesPerCommoditiesMessage EXCEPT !.accumulatedBidTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesInvestorActivitiesPerCommoditiesMessage EXCEPT !.accumulatedBidTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroSecuritiesInvestorActivitiesPerCommoditiesMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Securities Short Selling Message: 115 bytes                             *)
(***************************************************************************)

SecuritiesShortSellingMessage ==
    [ isinCode                                            : Sample(12),
      coveredShortSellingTradingVolume                    : Sample(12),
      coveredShortSellingTradingValue                     : Sample(22),
      uptickRuleAppliedCoveredShortSellingTradingVolume   : Sample(12),
      uptickRuleAppliedCoveredShortSellingTradingValue    : Sample(22),
      uptickRuleUnappliedCoveredShortSellingTradingVolume : Sample(12),
      uptickRuleUnappliedCoveredShortSellingTradingValue  : Sample(22),
      endKeyword                                          : Sample(1) ]

EncodeSecuritiesShortSellingMessage(message) ==
    message.isinCode
        \o message.coveredShortSellingTradingVolume
        \o message.coveredShortSellingTradingValue
        \o message.uptickRuleAppliedCoveredShortSellingTradingVolume
        \o message.uptickRuleAppliedCoveredShortSellingTradingValue
        \o message.uptickRuleUnappliedCoveredShortSellingTradingVolume
        \o message.uptickRuleUnappliedCoveredShortSellingTradingValue
        \o message.endKeyword

DecodeSecuritiesShortSellingMessage(bytes) ==
    LET isinCode == ReadBytes(bytes, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET coveredShortSellingTradingVolume == ReadBytes(isinCode.rest, 12) IN IF ~coveredShortSellingTradingVolume.ok THEN Fail ELSE
    LET coveredShortSellingTradingValue == ReadBytes(coveredShortSellingTradingVolume.rest, 22) IN IF ~coveredShortSellingTradingValue.ok THEN Fail ELSE
    LET uptickRuleAppliedCoveredShortSellingTradingVolume == ReadBytes(coveredShortSellingTradingValue.rest, 12) IN IF ~uptickRuleAppliedCoveredShortSellingTradingVolume.ok THEN Fail ELSE
    LET uptickRuleAppliedCoveredShortSellingTradingValue == ReadBytes(uptickRuleAppliedCoveredShortSellingTradingVolume.rest, 22) IN IF ~uptickRuleAppliedCoveredShortSellingTradingValue.ok THEN Fail ELSE
    LET uptickRuleUnappliedCoveredShortSellingTradingVolume == ReadBytes(uptickRuleAppliedCoveredShortSellingTradingValue.rest, 12) IN IF ~uptickRuleUnappliedCoveredShortSellingTradingVolume.ok THEN Fail ELSE
    LET uptickRuleUnappliedCoveredShortSellingTradingValue == ReadBytes(uptickRuleUnappliedCoveredShortSellingTradingVolume.rest, 22) IN IF ~uptickRuleUnappliedCoveredShortSellingTradingValue.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(uptickRuleUnappliedCoveredShortSellingTradingValue.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ isinCode                                            |-> isinCode.value,
         coveredShortSellingTradingVolume                    |-> coveredShortSellingTradingVolume.value,
         coveredShortSellingTradingValue                     |-> coveredShortSellingTradingValue.value,
         uptickRuleAppliedCoveredShortSellingTradingVolume   |-> uptickRuleAppliedCoveredShortSellingTradingVolume.value,
         uptickRuleAppliedCoveredShortSellingTradingValue    |-> uptickRuleAppliedCoveredShortSellingTradingValue.value,
         uptickRuleUnappliedCoveredShortSellingTradingVolume |-> uptickRuleUnappliedCoveredShortSellingTradingVolume.value,
         uptickRuleUnappliedCoveredShortSellingTradingValue  |-> uptickRuleUnappliedCoveredShortSellingTradingValue.value,
         endKeyword                                          |-> endKeyword.value ], endKeyword.rest)

ZeroSecuritiesShortSellingMessage ==
    [ isinCode                                            |-> [i \in 1 .. 12 |-> 0],
      coveredShortSellingTradingVolume                    |-> [i \in 1 .. 12 |-> 0],
      coveredShortSellingTradingValue                     |-> [i \in 1 .. 22 |-> 0],
      uptickRuleAppliedCoveredShortSellingTradingVolume   |-> [i \in 1 .. 12 |-> 0],
      uptickRuleAppliedCoveredShortSellingTradingValue    |-> [i \in 1 .. 22 |-> 0],
      uptickRuleUnappliedCoveredShortSellingTradingVolume |-> [i \in 1 .. 12 |-> 0],
      uptickRuleUnappliedCoveredShortSellingTradingValue  |-> [i \in 1 .. 22 |-> 0],
      endKeyword                                          |-> [i \in 1 .. 1 |-> 0] ]

(* Securities Short Selling Message at zero, then each field in turn at the values it is checked at *)
CheckedSecuritiesShortSellingMessage ==
    { ZeroSecuritiesShortSellingMessage }
        \cup { [ZeroSecuritiesShortSellingMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesShortSellingMessage EXCEPT !.coveredShortSellingTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesShortSellingMessage EXCEPT !.coveredShortSellingTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroSecuritiesShortSellingMessage EXCEPT !.uptickRuleAppliedCoveredShortSellingTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesShortSellingMessage EXCEPT !.uptickRuleAppliedCoveredShortSellingTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroSecuritiesShortSellingMessage EXCEPT !.uptickRuleUnappliedCoveredShortSellingTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesShortSellingMessage EXCEPT !.uptickRuleUnappliedCoveredShortSellingTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroSecuritiesShortSellingMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Securities Treasury Stocks Traded Message: 52 bytes                     *)
(***************************************************************************)

SecuritiesTreasuryStocksTradedMessage ==
    [ sessionId                     : Sample(2),
      isinCode                      : Sample(12),
      aDesignatedNumberForAnIssue   : Sample(6),
      tradingPrice                  : Sample(11),
      tradingVolume                 : Sample(10),
      bidTreasuryStockDeclarationId : Sample(5),
      askTreasuryStockDeclarationId : Sample(5),
      endKeyword                    : Sample(1) ]

EncodeSecuritiesTreasuryStocksTradedMessage(message) ==
    message.sessionId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.tradingPrice
        \o message.tradingVolume
        \o message.bidTreasuryStockDeclarationId
        \o message.askTreasuryStockDeclarationId
        \o message.endKeyword

DecodeSecuritiesTreasuryStocksTradedMessage(bytes) ==
    LET sessionId == ReadBytes(bytes, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(sessionId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET tradingPrice == ReadBytes(aDesignatedNumberForAnIssue.rest, 11) IN IF ~tradingPrice.ok THEN Fail ELSE
    LET tradingVolume == ReadBytes(tradingPrice.rest, 10) IN IF ~tradingVolume.ok THEN Fail ELSE
    LET bidTreasuryStockDeclarationId == ReadBytes(tradingVolume.rest, 5) IN IF ~bidTreasuryStockDeclarationId.ok THEN Fail ELSE
    LET askTreasuryStockDeclarationId == ReadBytes(bidTreasuryStockDeclarationId.rest, 5) IN IF ~askTreasuryStockDeclarationId.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(askTreasuryStockDeclarationId.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ sessionId                     |-> sessionId.value,
         isinCode                      |-> isinCode.value,
         aDesignatedNumberForAnIssue   |-> aDesignatedNumberForAnIssue.value,
         tradingPrice                  |-> tradingPrice.value,
         tradingVolume                 |-> tradingVolume.value,
         bidTreasuryStockDeclarationId |-> bidTreasuryStockDeclarationId.value,
         askTreasuryStockDeclarationId |-> askTreasuryStockDeclarationId.value,
         endKeyword                    |-> endKeyword.value ], endKeyword.rest)

ZeroSecuritiesTreasuryStocksTradedMessage ==
    [ sessionId                     |-> [i \in 1 .. 2 |-> 0],
      isinCode                      |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue   |-> [i \in 1 .. 6 |-> 0],
      tradingPrice                  |-> [i \in 1 .. 11 |-> 0],
      tradingVolume                 |-> [i \in 1 .. 10 |-> 0],
      bidTreasuryStockDeclarationId |-> [i \in 1 .. 5 |-> 0],
      askTreasuryStockDeclarationId |-> [i \in 1 .. 5 |-> 0],
      endKeyword                    |-> [i \in 1 .. 1 |-> 0] ]

(* Securities Treasury Stocks Traded Message at zero, then each field in turn at the values it is checked at *)
CheckedSecuritiesTreasuryStocksTradedMessage ==
    { ZeroSecuritiesTreasuryStocksTradedMessage }
        \cup { [ZeroSecuritiesTreasuryStocksTradedMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesTreasuryStocksTradedMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesTreasuryStocksTradedMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroSecuritiesTreasuryStocksTradedMessage EXCEPT !.tradingPrice = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesTreasuryStocksTradedMessage EXCEPT !.tradingVolume = one] : one \in Sample(10) }
        \cup { [ZeroSecuritiesTreasuryStocksTradedMessage EXCEPT !.bidTreasuryStockDeclarationId = one] : one \in Sample(5) }
        \cup { [ZeroSecuritiesTreasuryStocksTradedMessage EXCEPT !.askTreasuryStockDeclarationId = one] : one \in Sample(5) }
        \cup { [ZeroSecuritiesTreasuryStocksTradedMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Securities Buy In Volume Message: 47 bytes                              *)
(***************************************************************************)

SecuritiesBuyInVolumeMessage ==
    [ messageSequenceNumber : Sample(8),
      isinCode              : Sample(12),
      transmissionDate      : Sample(8),
      buyInTypeCode         : Sample(1),
      securityGroupId       : Sample(2),
      buyInVolume           : Sample(15),
      endKeyword            : Sample(1) ]

EncodeSecuritiesBuyInVolumeMessage(message) ==
    message.messageSequenceNumber
        \o message.isinCode
        \o message.transmissionDate
        \o message.buyInTypeCode
        \o message.securityGroupId
        \o message.buyInVolume
        \o message.endKeyword

DecodeSecuritiesBuyInVolumeMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET isinCode == ReadBytes(messageSequenceNumber.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET transmissionDate == ReadBytes(isinCode.rest, 8) IN IF ~transmissionDate.ok THEN Fail ELSE
    LET buyInTypeCode == ReadBytes(transmissionDate.rest, 1) IN IF ~buyInTypeCode.ok THEN Fail ELSE
    LET securityGroupId == ReadBytes(buyInTypeCode.rest, 2) IN IF ~securityGroupId.ok THEN Fail ELSE
    LET buyInVolume == ReadBytes(securityGroupId.rest, 15) IN IF ~buyInVolume.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(buyInVolume.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber |-> messageSequenceNumber.value,
         isinCode              |-> isinCode.value,
         transmissionDate      |-> transmissionDate.value,
         buyInTypeCode         |-> buyInTypeCode.value,
         securityGroupId       |-> securityGroupId.value,
         buyInVolume           |-> buyInVolume.value,
         endKeyword            |-> endKeyword.value ], endKeyword.rest)

ZeroSecuritiesBuyInVolumeMessage ==
    [ messageSequenceNumber |-> [i \in 1 .. 8 |-> 0],
      isinCode              |-> [i \in 1 .. 12 |-> 0],
      transmissionDate      |-> [i \in 1 .. 8 |-> 0],
      buyInTypeCode         |-> [i \in 1 .. 1 |-> 0],
      securityGroupId       |-> [i \in 1 .. 2 |-> 0],
      buyInVolume           |-> [i \in 1 .. 15 |-> 0],
      endKeyword            |-> [i \in 1 .. 1 |-> 0] ]

(* Securities Buy In Volume Message at zero, then each field in turn at the values it is checked at *)
CheckedSecuritiesBuyInVolumeMessage ==
    { ZeroSecuritiesBuyInVolumeMessage }
        \cup { [ZeroSecuritiesBuyInVolumeMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesBuyInVolumeMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesBuyInVolumeMessage EXCEPT !.transmissionDate = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesBuyInVolumeMessage EXCEPT !.buyInTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesBuyInVolumeMessage EXCEPT !.securityGroupId = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesBuyInVolumeMessage EXCEPT !.buyInVolume = one] : one \in Sample(15) }
        \cup { [ZeroSecuritiesBuyInVolumeMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

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
SecuritiesInvestorActivitiesPerIndustryMessageCode == <<67, 48, 48, 49, 83>>  \* "C001S"
SecuritiesInvestorActivitiesPerIndustryMessageCode2 == <<67, 48, 48, 49, 81>>  \* "C001Q"
SecuritiesInvestorActivitiesPerIndustryMessageCode3 == <<67, 48, 48, 49, 88>>  \* "C001X"
SecuritiesInvestorActivitiesPerIssueEodMessageCode == <<67, 49, 48, 49, 83>>  \* "C101S"
SecuritiesInvestorActivitiesPerIssueEodMessageCode2 == <<67, 49, 48, 50, 83>>  \* "C102S"
SecuritiesInvestorActivitiesPerIssueEodMessageCode3 == <<67, 49, 48, 51, 83>>  \* "C103S"
SecuritiesInvestorActivitiesPerIssueEodMessageCode4 == <<67, 49, 48, 52, 83>>  \* "C104S"
SecuritiesInvestorActivitiesPerIssueEodMessageCode5 == <<67, 49, 48, 53, 83>>  \* "C105S"
SecuritiesInvestorActivitiesPerIssueEodMessageCode6 == <<67, 49, 48, 49, 81>>  \* "C101Q"
SecuritiesInvestorActivitiesPerIssueEodMessageCode7 == <<67, 49, 48, 49, 88>>  \* "C101X"
SecuritiesInvestorActivitiesPerIssueEodMessageCode8 == <<67, 49, 48, 49, 71>>  \* "C101G"
SecuritiesInvestorActivitiesPerCommoditiesMessageCode == <<73, 67, 48, 50, 83>>  \* "IC02S"
SecuritiesInvestorActivitiesPerCommoditiesMessageCode2 == <<73, 67, 48, 51, 83>>  \* "IC03S"
SecuritiesInvestorActivitiesPerCommoditiesMessageCode3 == <<73, 67, 48, 52, 83>>  \* "IC04S"
SecuritiesInvestorActivitiesPerCommoditiesMessageCode4 == <<73, 67, 48, 53, 83>>  \* "IC05S"
SecuritiesInvestorActivitiesPerCommoditiesMessageCode5 == <<73, 67, 48, 49, 71>>  \* "IC01G"
SecuritiesShortSellingMessageCode == <<73, 56, 48, 49, 83>>  \* "I801S"
SecuritiesShortSellingMessageCode2 == <<73, 56, 48, 51, 83>>  \* "I803S"
SecuritiesShortSellingMessageCode3 == <<73, 56, 48, 52, 83>>  \* "I804S"
SecuritiesShortSellingMessageCode4 == <<73, 56, 48, 53, 83>>  \* "I805S"
SecuritiesShortSellingMessageCode5 == <<73, 56, 48, 49, 81>>  \* "I801Q"
SecuritiesTreasuryStocksTradedMessageCode == <<66, 48, 48, 49, 83>>  \* "B001S"
SecuritiesTreasuryStocksTradedMessageCode2 == <<66, 48, 48, 49, 81>>  \* "B001Q"
SecuritiesTreasuryStocksTradedMessageCode3 == <<66, 48, 48, 49, 88>>  \* "B001X"
SecuritiesBuyInVolumeMessageCode == <<79, 52, 48, 49, 83>>  \* "O401S"
SecuritiesBuyInVolumeMessageCode2 == <<79, 52, 48, 50, 83>>  \* "O402S"
SecuritiesBuyInVolumeMessageCode3 == <<79, 52, 48, 51, 83>>  \* "O403S"
SecuritiesBuyInVolumeMessageCode4 == <<79, 52, 48, 52, 83>>  \* "O404S"
SecuritiesBuyInVolumeMessageCode5 == <<79, 52, 48, 49, 81>>  \* "O401Q"
SecuritiesBuyInVolumeMessageCode6 == <<79, 52, 48, 49, 88>>  \* "O401X"

Payload ==
    [ tag : {PollingDataMessageCode}, body : PollingDataMessage ]
        \cup [ tag : {KrxIndexMessageCode}, body : KrxIndexMessage ]
        \cup [ tag : {KrxEstimatedIndexMessageCode}, body : KrxEstimatedIndexMessage ]
        \cup [ tag : {GlobalIndexMessageCode}, body : GlobalIndexMessage ]
        \cup [ tag : {BondPrimeIndexMessageCode}, body : BondPrimeIndexMessage ]
        \cup [ tag : {BondKtbIndexMessageCode}, body : BondKtbIndexMessage ]
        \cup [ tag : {BondKtbIndexTermStructureMessageCode}, body : BondKtbIndexTermStructureMessage ]
        \cup [ tag : {BondIndexKrxMessageCode}, body : BondIndexKrxMessage ]
        \cup [ tag : {SecuritiesInvestorActivitiesPerIndustryMessageCode}, body : SecuritiesInvestorActivitiesPerIndustryMessage ]
        \cup [ tag : {SecuritiesInvestorActivitiesPerIndustryMessageCode2}, body : SecuritiesInvestorActivitiesPerIndustryMessage ]
        \cup [ tag : {SecuritiesInvestorActivitiesPerIndustryMessageCode3}, body : SecuritiesInvestorActivitiesPerIndustryMessage ]
        \cup [ tag : {SecuritiesInvestorActivitiesPerIssueEodMessageCode}, body : SecuritiesInvestorActivitiesPerIssueEodMessage ]
        \cup [ tag : {SecuritiesInvestorActivitiesPerIssueEodMessageCode2}, body : SecuritiesInvestorActivitiesPerIssueEodMessage ]
        \cup [ tag : {SecuritiesInvestorActivitiesPerIssueEodMessageCode3}, body : SecuritiesInvestorActivitiesPerIssueEodMessage ]
        \cup [ tag : {SecuritiesInvestorActivitiesPerIssueEodMessageCode4}, body : SecuritiesInvestorActivitiesPerIssueEodMessage ]
        \cup [ tag : {SecuritiesInvestorActivitiesPerIssueEodMessageCode5}, body : SecuritiesInvestorActivitiesPerIssueEodMessage ]
        \cup [ tag : {SecuritiesInvestorActivitiesPerIssueEodMessageCode6}, body : SecuritiesInvestorActivitiesPerIssueEodMessage ]
        \cup [ tag : {SecuritiesInvestorActivitiesPerIssueEodMessageCode7}, body : SecuritiesInvestorActivitiesPerIssueEodMessage ]
        \cup [ tag : {SecuritiesInvestorActivitiesPerIssueEodMessageCode8}, body : SecuritiesInvestorActivitiesPerIssueEodMessage ]
        \cup [ tag : {SecuritiesInvestorActivitiesPerCommoditiesMessageCode}, body : SecuritiesInvestorActivitiesPerCommoditiesMessage ]
        \cup [ tag : {SecuritiesInvestorActivitiesPerCommoditiesMessageCode2}, body : SecuritiesInvestorActivitiesPerCommoditiesMessage ]
        \cup [ tag : {SecuritiesInvestorActivitiesPerCommoditiesMessageCode3}, body : SecuritiesInvestorActivitiesPerCommoditiesMessage ]
        \cup [ tag : {SecuritiesInvestorActivitiesPerCommoditiesMessageCode4}, body : SecuritiesInvestorActivitiesPerCommoditiesMessage ]
        \cup [ tag : {SecuritiesInvestorActivitiesPerCommoditiesMessageCode5}, body : SecuritiesInvestorActivitiesPerCommoditiesMessage ]
        \cup [ tag : {SecuritiesShortSellingMessageCode}, body : SecuritiesShortSellingMessage ]
        \cup [ tag : {SecuritiesShortSellingMessageCode2}, body : SecuritiesShortSellingMessage ]
        \cup [ tag : {SecuritiesShortSellingMessageCode3}, body : SecuritiesShortSellingMessage ]
        \cup [ tag : {SecuritiesShortSellingMessageCode4}, body : SecuritiesShortSellingMessage ]
        \cup [ tag : {SecuritiesShortSellingMessageCode5}, body : SecuritiesShortSellingMessage ]
        \cup [ tag : {SecuritiesTreasuryStocksTradedMessageCode}, body : SecuritiesTreasuryStocksTradedMessage ]
        \cup [ tag : {SecuritiesTreasuryStocksTradedMessageCode2}, body : SecuritiesTreasuryStocksTradedMessage ]
        \cup [ tag : {SecuritiesTreasuryStocksTradedMessageCode3}, body : SecuritiesTreasuryStocksTradedMessage ]
        \cup [ tag : {SecuritiesBuyInVolumeMessageCode}, body : SecuritiesBuyInVolumeMessage ]
        \cup [ tag : {SecuritiesBuyInVolumeMessageCode2}, body : SecuritiesBuyInVolumeMessage ]
        \cup [ tag : {SecuritiesBuyInVolumeMessageCode3}, body : SecuritiesBuyInVolumeMessage ]
        \cup [ tag : {SecuritiesBuyInVolumeMessageCode4}, body : SecuritiesBuyInVolumeMessage ]
        \cup [ tag : {SecuritiesBuyInVolumeMessageCode5}, body : SecuritiesBuyInVolumeMessage ]
        \cup [ tag : {SecuritiesBuyInVolumeMessageCode6}, body : SecuritiesBuyInVolumeMessage ]

EncodePayload(message) ==
    CASE message.tag = PollingDataMessageCode -> EncodePollingDataMessage(message.body)
      [] message.tag = KrxIndexMessageCode -> EncodeKrxIndexMessage(message.body)
      [] message.tag = KrxEstimatedIndexMessageCode -> EncodeKrxEstimatedIndexMessage(message.body)
      [] message.tag = GlobalIndexMessageCode -> EncodeGlobalIndexMessage(message.body)
      [] message.tag = BondPrimeIndexMessageCode -> EncodeBondPrimeIndexMessage(message.body)
      [] message.tag = BondKtbIndexMessageCode -> EncodeBondKtbIndexMessage(message.body)
      [] message.tag = BondKtbIndexTermStructureMessageCode -> EncodeBondKtbIndexTermStructureMessage(message.body)
      [] message.tag = BondIndexKrxMessageCode -> EncodeBondIndexKrxMessage(message.body)
      [] message.tag = SecuritiesInvestorActivitiesPerIndustryMessageCode -> EncodeSecuritiesInvestorActivitiesPerIndustryMessage(message.body)
      [] message.tag = SecuritiesInvestorActivitiesPerIndustryMessageCode2 -> EncodeSecuritiesInvestorActivitiesPerIndustryMessage(message.body)
      [] message.tag = SecuritiesInvestorActivitiesPerIndustryMessageCode3 -> EncodeSecuritiesInvestorActivitiesPerIndustryMessage(message.body)
      [] message.tag = SecuritiesInvestorActivitiesPerIssueEodMessageCode -> EncodeSecuritiesInvestorActivitiesPerIssueEodMessage(message.body)
      [] message.tag = SecuritiesInvestorActivitiesPerIssueEodMessageCode2 -> EncodeSecuritiesInvestorActivitiesPerIssueEodMessage(message.body)
      [] message.tag = SecuritiesInvestorActivitiesPerIssueEodMessageCode3 -> EncodeSecuritiesInvestorActivitiesPerIssueEodMessage(message.body)
      [] message.tag = SecuritiesInvestorActivitiesPerIssueEodMessageCode4 -> EncodeSecuritiesInvestorActivitiesPerIssueEodMessage(message.body)
      [] message.tag = SecuritiesInvestorActivitiesPerIssueEodMessageCode5 -> EncodeSecuritiesInvestorActivitiesPerIssueEodMessage(message.body)
      [] message.tag = SecuritiesInvestorActivitiesPerIssueEodMessageCode6 -> EncodeSecuritiesInvestorActivitiesPerIssueEodMessage(message.body)
      [] message.tag = SecuritiesInvestorActivitiesPerIssueEodMessageCode7 -> EncodeSecuritiesInvestorActivitiesPerIssueEodMessage(message.body)
      [] message.tag = SecuritiesInvestorActivitiesPerIssueEodMessageCode8 -> EncodeSecuritiesInvestorActivitiesPerIssueEodMessage(message.body)
      [] message.tag = SecuritiesInvestorActivitiesPerCommoditiesMessageCode -> EncodeSecuritiesInvestorActivitiesPerCommoditiesMessage(message.body)
      [] message.tag = SecuritiesInvestorActivitiesPerCommoditiesMessageCode2 -> EncodeSecuritiesInvestorActivitiesPerCommoditiesMessage(message.body)
      [] message.tag = SecuritiesInvestorActivitiesPerCommoditiesMessageCode3 -> EncodeSecuritiesInvestorActivitiesPerCommoditiesMessage(message.body)
      [] message.tag = SecuritiesInvestorActivitiesPerCommoditiesMessageCode4 -> EncodeSecuritiesInvestorActivitiesPerCommoditiesMessage(message.body)
      [] message.tag = SecuritiesInvestorActivitiesPerCommoditiesMessageCode5 -> EncodeSecuritiesInvestorActivitiesPerCommoditiesMessage(message.body)
      [] message.tag = SecuritiesShortSellingMessageCode -> EncodeSecuritiesShortSellingMessage(message.body)
      [] message.tag = SecuritiesShortSellingMessageCode2 -> EncodeSecuritiesShortSellingMessage(message.body)
      [] message.tag = SecuritiesShortSellingMessageCode3 -> EncodeSecuritiesShortSellingMessage(message.body)
      [] message.tag = SecuritiesShortSellingMessageCode4 -> EncodeSecuritiesShortSellingMessage(message.body)
      [] message.tag = SecuritiesShortSellingMessageCode5 -> EncodeSecuritiesShortSellingMessage(message.body)
      [] message.tag = SecuritiesTreasuryStocksTradedMessageCode -> EncodeSecuritiesTreasuryStocksTradedMessage(message.body)
      [] message.tag = SecuritiesTreasuryStocksTradedMessageCode2 -> EncodeSecuritiesTreasuryStocksTradedMessage(message.body)
      [] message.tag = SecuritiesTreasuryStocksTradedMessageCode3 -> EncodeSecuritiesTreasuryStocksTradedMessage(message.body)
      [] message.tag = SecuritiesBuyInVolumeMessageCode -> EncodeSecuritiesBuyInVolumeMessage(message.body)
      [] message.tag = SecuritiesBuyInVolumeMessageCode2 -> EncodeSecuritiesBuyInVolumeMessage(message.body)
      [] message.tag = SecuritiesBuyInVolumeMessageCode3 -> EncodeSecuritiesBuyInVolumeMessage(message.body)
      [] message.tag = SecuritiesBuyInVolumeMessageCode4 -> EncodeSecuritiesBuyInVolumeMessage(message.body)
      [] message.tag = SecuritiesBuyInVolumeMessageCode5 -> EncodeSecuritiesBuyInVolumeMessage(message.body)
      [] message.tag = SecuritiesBuyInVolumeMessageCode6 -> EncodeSecuritiesBuyInVolumeMessage(message.body)

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
              [] tag = SecuritiesInvestorActivitiesPerIndustryMessageCode -> DecodeSecuritiesInvestorActivitiesPerIndustryMessage(bytes)
              [] tag = SecuritiesInvestorActivitiesPerIndustryMessageCode2 -> DecodeSecuritiesInvestorActivitiesPerIndustryMessage(bytes)
              [] tag = SecuritiesInvestorActivitiesPerIndustryMessageCode3 -> DecodeSecuritiesInvestorActivitiesPerIndustryMessage(bytes)
              [] tag = SecuritiesInvestorActivitiesPerIssueEodMessageCode -> DecodeSecuritiesInvestorActivitiesPerIssueEodMessage(bytes)
              [] tag = SecuritiesInvestorActivitiesPerIssueEodMessageCode2 -> DecodeSecuritiesInvestorActivitiesPerIssueEodMessage(bytes)
              [] tag = SecuritiesInvestorActivitiesPerIssueEodMessageCode3 -> DecodeSecuritiesInvestorActivitiesPerIssueEodMessage(bytes)
              [] tag = SecuritiesInvestorActivitiesPerIssueEodMessageCode4 -> DecodeSecuritiesInvestorActivitiesPerIssueEodMessage(bytes)
              [] tag = SecuritiesInvestorActivitiesPerIssueEodMessageCode5 -> DecodeSecuritiesInvestorActivitiesPerIssueEodMessage(bytes)
              [] tag = SecuritiesInvestorActivitiesPerIssueEodMessageCode6 -> DecodeSecuritiesInvestorActivitiesPerIssueEodMessage(bytes)
              [] tag = SecuritiesInvestorActivitiesPerIssueEodMessageCode7 -> DecodeSecuritiesInvestorActivitiesPerIssueEodMessage(bytes)
              [] tag = SecuritiesInvestorActivitiesPerIssueEodMessageCode8 -> DecodeSecuritiesInvestorActivitiesPerIssueEodMessage(bytes)
              [] tag = SecuritiesInvestorActivitiesPerCommoditiesMessageCode -> DecodeSecuritiesInvestorActivitiesPerCommoditiesMessage(bytes)
              [] tag = SecuritiesInvestorActivitiesPerCommoditiesMessageCode2 -> DecodeSecuritiesInvestorActivitiesPerCommoditiesMessage(bytes)
              [] tag = SecuritiesInvestorActivitiesPerCommoditiesMessageCode3 -> DecodeSecuritiesInvestorActivitiesPerCommoditiesMessage(bytes)
              [] tag = SecuritiesInvestorActivitiesPerCommoditiesMessageCode4 -> DecodeSecuritiesInvestorActivitiesPerCommoditiesMessage(bytes)
              [] tag = SecuritiesInvestorActivitiesPerCommoditiesMessageCode5 -> DecodeSecuritiesInvestorActivitiesPerCommoditiesMessage(bytes)
              [] tag = SecuritiesShortSellingMessageCode -> DecodeSecuritiesShortSellingMessage(bytes)
              [] tag = SecuritiesShortSellingMessageCode2 -> DecodeSecuritiesShortSellingMessage(bytes)
              [] tag = SecuritiesShortSellingMessageCode3 -> DecodeSecuritiesShortSellingMessage(bytes)
              [] tag = SecuritiesShortSellingMessageCode4 -> DecodeSecuritiesShortSellingMessage(bytes)
              [] tag = SecuritiesShortSellingMessageCode5 -> DecodeSecuritiesShortSellingMessage(bytes)
              [] tag = SecuritiesTreasuryStocksTradedMessageCode -> DecodeSecuritiesTreasuryStocksTradedMessage(bytes)
              [] tag = SecuritiesTreasuryStocksTradedMessageCode2 -> DecodeSecuritiesTreasuryStocksTradedMessage(bytes)
              [] tag = SecuritiesTreasuryStocksTradedMessageCode3 -> DecodeSecuritiesTreasuryStocksTradedMessage(bytes)
              [] tag = SecuritiesBuyInVolumeMessageCode -> DecodeSecuritiesBuyInVolumeMessage(bytes)
              [] tag = SecuritiesBuyInVolumeMessageCode2 -> DecodeSecuritiesBuyInVolumeMessage(bytes)
              [] tag = SecuritiesBuyInVolumeMessageCode3 -> DecodeSecuritiesBuyInVolumeMessage(bytes)
              [] tag = SecuritiesBuyInVolumeMessageCode4 -> DecodeSecuritiesBuyInVolumeMessage(bytes)
              [] tag = SecuritiesBuyInVolumeMessageCode5 -> DecodeSecuritiesBuyInVolumeMessage(bytes)
              [] tag = SecuritiesBuyInVolumeMessageCode6 -> DecodeSecuritiesBuyInVolumeMessage(bytes)
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
        \cup { [tag |-> SecuritiesInvestorActivitiesPerIndustryMessageCode, body |-> one] : one \in CheckedSecuritiesInvestorActivitiesPerIndustryMessage }
        \cup { [tag |-> SecuritiesInvestorActivitiesPerIndustryMessageCode2, body |-> one] : one \in CheckedSecuritiesInvestorActivitiesPerIndustryMessage }
        \cup { [tag |-> SecuritiesInvestorActivitiesPerIndustryMessageCode3, body |-> one] : one \in CheckedSecuritiesInvestorActivitiesPerIndustryMessage }
        \cup { [tag |-> SecuritiesInvestorActivitiesPerIssueEodMessageCode, body |-> one] : one \in CheckedSecuritiesInvestorActivitiesPerIssueEodMessage }
        \cup { [tag |-> SecuritiesInvestorActivitiesPerIssueEodMessageCode2, body |-> one] : one \in CheckedSecuritiesInvestorActivitiesPerIssueEodMessage }
        \cup { [tag |-> SecuritiesInvestorActivitiesPerIssueEodMessageCode3, body |-> one] : one \in CheckedSecuritiesInvestorActivitiesPerIssueEodMessage }
        \cup { [tag |-> SecuritiesInvestorActivitiesPerIssueEodMessageCode4, body |-> one] : one \in CheckedSecuritiesInvestorActivitiesPerIssueEodMessage }
        \cup { [tag |-> SecuritiesInvestorActivitiesPerIssueEodMessageCode5, body |-> one] : one \in CheckedSecuritiesInvestorActivitiesPerIssueEodMessage }
        \cup { [tag |-> SecuritiesInvestorActivitiesPerIssueEodMessageCode6, body |-> one] : one \in CheckedSecuritiesInvestorActivitiesPerIssueEodMessage }
        \cup { [tag |-> SecuritiesInvestorActivitiesPerIssueEodMessageCode7, body |-> one] : one \in CheckedSecuritiesInvestorActivitiesPerIssueEodMessage }
        \cup { [tag |-> SecuritiesInvestorActivitiesPerIssueEodMessageCode8, body |-> one] : one \in CheckedSecuritiesInvestorActivitiesPerIssueEodMessage }
        \cup { [tag |-> SecuritiesInvestorActivitiesPerCommoditiesMessageCode, body |-> one] : one \in CheckedSecuritiesInvestorActivitiesPerCommoditiesMessage }
        \cup { [tag |-> SecuritiesInvestorActivitiesPerCommoditiesMessageCode2, body |-> one] : one \in CheckedSecuritiesInvestorActivitiesPerCommoditiesMessage }
        \cup { [tag |-> SecuritiesInvestorActivitiesPerCommoditiesMessageCode3, body |-> one] : one \in CheckedSecuritiesInvestorActivitiesPerCommoditiesMessage }
        \cup { [tag |-> SecuritiesInvestorActivitiesPerCommoditiesMessageCode4, body |-> one] : one \in CheckedSecuritiesInvestorActivitiesPerCommoditiesMessage }
        \cup { [tag |-> SecuritiesInvestorActivitiesPerCommoditiesMessageCode5, body |-> one] : one \in CheckedSecuritiesInvestorActivitiesPerCommoditiesMessage }
        \cup { [tag |-> SecuritiesShortSellingMessageCode, body |-> one] : one \in CheckedSecuritiesShortSellingMessage }
        \cup { [tag |-> SecuritiesShortSellingMessageCode2, body |-> one] : one \in CheckedSecuritiesShortSellingMessage }
        \cup { [tag |-> SecuritiesShortSellingMessageCode3, body |-> one] : one \in CheckedSecuritiesShortSellingMessage }
        \cup { [tag |-> SecuritiesShortSellingMessageCode4, body |-> one] : one \in CheckedSecuritiesShortSellingMessage }
        \cup { [tag |-> SecuritiesShortSellingMessageCode5, body |-> one] : one \in CheckedSecuritiesShortSellingMessage }
        \cup { [tag |-> SecuritiesTreasuryStocksTradedMessageCode, body |-> one] : one \in CheckedSecuritiesTreasuryStocksTradedMessage }
        \cup { [tag |-> SecuritiesTreasuryStocksTradedMessageCode2, body |-> one] : one \in CheckedSecuritiesTreasuryStocksTradedMessage }
        \cup { [tag |-> SecuritiesTreasuryStocksTradedMessageCode3, body |-> one] : one \in CheckedSecuritiesTreasuryStocksTradedMessage }
        \cup { [tag |-> SecuritiesBuyInVolumeMessageCode, body |-> one] : one \in CheckedSecuritiesBuyInVolumeMessage }
        \cup { [tag |-> SecuritiesBuyInVolumeMessageCode2, body |-> one] : one \in CheckedSecuritiesBuyInVolumeMessage }
        \cup { [tag |-> SecuritiesBuyInVolumeMessageCode3, body |-> one] : one \in CheckedSecuritiesBuyInVolumeMessage }
        \cup { [tag |-> SecuritiesBuyInVolumeMessageCode4, body |-> one] : one \in CheckedSecuritiesBuyInVolumeMessage }
        \cup { [tag |-> SecuritiesBuyInVolumeMessageCode5, body |-> one] : one \in CheckedSecuritiesBuyInVolumeMessage }
        \cup { [tag |-> SecuritiesBuyInVolumeMessageCode6, body |-> one] : one \in CheckedSecuritiesBuyInVolumeMessage }

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
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesInvestorActivitiesPerIndustryMessageCode, body |-> ZeroSecuritiesInvestorActivitiesPerIndustryMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesInvestorActivitiesPerIndustryMessageCode2, body |-> ZeroSecuritiesInvestorActivitiesPerIndustryMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesInvestorActivitiesPerIndustryMessageCode3, body |-> ZeroSecuritiesInvestorActivitiesPerIndustryMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesInvestorActivitiesPerIssueEodMessageCode, body |-> ZeroSecuritiesInvestorActivitiesPerIssueEodMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesInvestorActivitiesPerIssueEodMessageCode2, body |-> ZeroSecuritiesInvestorActivitiesPerIssueEodMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesInvestorActivitiesPerIssueEodMessageCode3, body |-> ZeroSecuritiesInvestorActivitiesPerIssueEodMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesInvestorActivitiesPerIssueEodMessageCode4, body |-> ZeroSecuritiesInvestorActivitiesPerIssueEodMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesInvestorActivitiesPerIssueEodMessageCode5, body |-> ZeroSecuritiesInvestorActivitiesPerIssueEodMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesInvestorActivitiesPerIssueEodMessageCode6, body |-> ZeroSecuritiesInvestorActivitiesPerIssueEodMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesInvestorActivitiesPerIssueEodMessageCode7, body |-> ZeroSecuritiesInvestorActivitiesPerIssueEodMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesInvestorActivitiesPerIssueEodMessageCode8, body |-> ZeroSecuritiesInvestorActivitiesPerIssueEodMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesInvestorActivitiesPerCommoditiesMessageCode, body |-> ZeroSecuritiesInvestorActivitiesPerCommoditiesMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesInvestorActivitiesPerCommoditiesMessageCode2, body |-> ZeroSecuritiesInvestorActivitiesPerCommoditiesMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesInvestorActivitiesPerCommoditiesMessageCode3, body |-> ZeroSecuritiesInvestorActivitiesPerCommoditiesMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesInvestorActivitiesPerCommoditiesMessageCode4, body |-> ZeroSecuritiesInvestorActivitiesPerCommoditiesMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesInvestorActivitiesPerCommoditiesMessageCode5, body |-> ZeroSecuritiesInvestorActivitiesPerCommoditiesMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesShortSellingMessageCode, body |-> ZeroSecuritiesShortSellingMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesShortSellingMessageCode2, body |-> ZeroSecuritiesShortSellingMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesShortSellingMessageCode3, body |-> ZeroSecuritiesShortSellingMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesShortSellingMessageCode4, body |-> ZeroSecuritiesShortSellingMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesShortSellingMessageCode5, body |-> ZeroSecuritiesShortSellingMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesTreasuryStocksTradedMessageCode, body |-> ZeroSecuritiesTreasuryStocksTradedMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesTreasuryStocksTradedMessageCode2, body |-> ZeroSecuritiesTreasuryStocksTradedMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesTreasuryStocksTradedMessageCode3, body |-> ZeroSecuritiesTreasuryStocksTradedMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesBuyInVolumeMessageCode, body |-> ZeroSecuritiesBuyInVolumeMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesBuyInVolumeMessageCode2, body |-> ZeroSecuritiesBuyInVolumeMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesBuyInVolumeMessageCode3, body |-> ZeroSecuritiesBuyInVolumeMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesBuyInVolumeMessageCode4, body |-> ZeroSecuritiesBuyInVolumeMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesBuyInVolumeMessageCode5, body |-> ZeroSecuritiesBuyInVolumeMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesBuyInVolumeMessageCode6, body |-> ZeroSecuritiesBuyInVolumeMessage]] }

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

(* Every Securities Investor Activities Per Industry Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecuritiesInvestorActivitiesPerIndustryMessage ==
    \A message \in CheckedSecuritiesInvestorActivitiesPerIndustryMessage :
        LET read == DecodeSecuritiesInvestorActivitiesPerIndustryMessage(EncodeSecuritiesInvestorActivitiesPerIndustryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Securities Investor Activities Per Issue Eod Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecuritiesInvestorActivitiesPerIssueEodMessage ==
    \A message \in CheckedSecuritiesInvestorActivitiesPerIssueEodMessage :
        LET read == DecodeSecuritiesInvestorActivitiesPerIssueEodMessage(EncodeSecuritiesInvestorActivitiesPerIssueEodMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Securities Investor Activities Per Commodities Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecuritiesInvestorActivitiesPerCommoditiesMessage ==
    \A message \in CheckedSecuritiesInvestorActivitiesPerCommoditiesMessage :
        LET read == DecodeSecuritiesInvestorActivitiesPerCommoditiesMessage(EncodeSecuritiesInvestorActivitiesPerCommoditiesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Securities Short Selling Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecuritiesShortSellingMessage ==
    \A message \in CheckedSecuritiesShortSellingMessage :
        LET read == DecodeSecuritiesShortSellingMessage(EncodeSecuritiesShortSellingMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Securities Treasury Stocks Traded Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecuritiesTreasuryStocksTradedMessage ==
    \A message \in CheckedSecuritiesTreasuryStocksTradedMessage :
        LET read == DecodeSecuritiesTreasuryStocksTradedMessage(EncodeSecuritiesTreasuryStocksTradedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Securities Buy In Volume Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecuritiesBuyInVolumeMessage ==
    \A message \in CheckedSecuritiesBuyInVolumeMessage :
        LET read == DecodeSecuritiesBuyInVolumeMessage(EncodeSecuritiesBuyInVolumeMessage(message))
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
