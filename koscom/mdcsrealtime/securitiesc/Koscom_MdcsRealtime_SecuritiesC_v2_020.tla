-------------- MODULE Koscom_MdcsRealtime_SecuritiesC_v2_020 ---------------
(***************************************************************************)
(* Koscom Co., Ltd. MDCS Realtime Securities C v2.020                      *)
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
(* Krx Index Message: 82 bytes                                             *)
(***************************************************************************)

KrxIndexMessage ==
    [ indexId                              : Sample(6),
      isinCode                             : Sample(12),
      calculationTime                      : Sample(6),
      index                                : Sample(9),
      indexChangeSignAgainstThePreviousDay : Sample(1),
      indexChangeAgainstThePreviousDay     : Sample(9),
      accumulatedTradingVolume             : Sample(12),
      accumulatedTradingValue              : Sample(22),
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
    LET accumulatedTradingValue == ReadBytes(accumulatedTradingVolume.rest, 22) IN IF ~accumulatedTradingValue.ok THEN Fail ELSE
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
      accumulatedTradingValue              |-> [i \in 1 .. 22 |-> 0],
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
        \cup { [ZeroKrxIndexMessage EXCEPT !.accumulatedTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroKrxIndexMessage EXCEPT !.filler4 = one] : one \in Sample(4) }
        \cup { [ZeroKrxIndexMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Krx Estimated Index Message: 82 bytes                                   *)
(***************************************************************************)

KrxEstimatedIndexMessage ==
    [ indexId                              : Sample(6),
      isinCode                             : Sample(12),
      calculationTime                      : Sample(6),
      index                                : Sample(9),
      indexChangeSignAgainstThePreviousDay : Sample(1),
      indexChangeAgainstThePreviousDay     : Sample(9),
      accumulatedTradingVolume             : Sample(12),
      accumulatedTradingValue              : Sample(22),
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
    LET accumulatedTradingValue == ReadBytes(accumulatedTradingVolume.rest, 22) IN IF ~accumulatedTradingValue.ok THEN Fail ELSE
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
      accumulatedTradingValue              |-> [i \in 1 .. 22 |-> 0],
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
        \cup { [ZeroKrxEstimatedIndexMessage EXCEPT !.accumulatedTradingValue = one] : one \in Sample(22) }
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
(* Securities Quote Mm Lp Excluded Message: 585 bytes                      *)
(***************************************************************************)

SecuritiesQuoteMmLpExcludedMessage ==
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
      askLevel6Price                : Sample(11),
      bidLevel6Price                : Sample(11),
      askLevel6Volume               : Sample(12),
      bidLevel6Volume               : Sample(12),
      askLevel7Price                : Sample(11),
      bidLevel7Price                : Sample(11),
      askLevel7Volume               : Sample(12),
      bidLevel7Volume               : Sample(12),
      askLevel8Price                : Sample(11),
      bidLevel8Price                : Sample(11),
      askLevel8Volume               : Sample(12),
      bidLevel8Volume               : Sample(12),
      askLevel9Price                : Sample(11),
      bidLevel9Price                : Sample(11),
      askLevel9Volume               : Sample(12),
      bidLevel9Volume               : Sample(12),
      askLevel10Price               : Sample(11),
      bidLevel10Price               : Sample(11),
      askLevel10Volume              : Sample(12),
      bidLevel10Volume              : Sample(12),
      totalAskVolume                : Sample(12),
      totalBidVolume                : Sample(12),
      estimatedTradingPrice         : Sample(11),
      estimatedTradingVolume        : Sample(12),
      midpoint                      : Sample(11),
      askMidPriceTotalVolume        : Sample(12),
      bidMidPriceTotalVolume        : Sample(12),
      endKeyword                    : Sample(1) ]

EncodeSecuritiesQuoteMmLpExcludedMessage(message) ==
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
        \o message.askLevel6Price
        \o message.bidLevel6Price
        \o message.askLevel6Volume
        \o message.bidLevel6Volume
        \o message.askLevel7Price
        \o message.bidLevel7Price
        \o message.askLevel7Volume
        \o message.bidLevel7Volume
        \o message.askLevel8Price
        \o message.bidLevel8Price
        \o message.askLevel8Volume
        \o message.bidLevel8Volume
        \o message.askLevel9Price
        \o message.bidLevel9Price
        \o message.askLevel9Volume
        \o message.bidLevel9Volume
        \o message.askLevel10Price
        \o message.bidLevel10Price
        \o message.askLevel10Volume
        \o message.bidLevel10Volume
        \o message.totalAskVolume
        \o message.totalBidVolume
        \o message.estimatedTradingPrice
        \o message.estimatedTradingVolume
        \o message.midpoint
        \o message.askMidPriceTotalVolume
        \o message.bidMidPriceTotalVolume
        \o message.endKeyword

DecodeSecuritiesQuoteMmLpExcludedMessage(bytes) ==
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
    LET askLevel6Price == ReadBytes(bidLevel5Volume.rest, 11) IN IF ~askLevel6Price.ok THEN Fail ELSE
    LET bidLevel6Price == ReadBytes(askLevel6Price.rest, 11) IN IF ~bidLevel6Price.ok THEN Fail ELSE
    LET askLevel6Volume == ReadBytes(bidLevel6Price.rest, 12) IN IF ~askLevel6Volume.ok THEN Fail ELSE
    LET bidLevel6Volume == ReadBytes(askLevel6Volume.rest, 12) IN IF ~bidLevel6Volume.ok THEN Fail ELSE
    LET askLevel7Price == ReadBytes(bidLevel6Volume.rest, 11) IN IF ~askLevel7Price.ok THEN Fail ELSE
    LET bidLevel7Price == ReadBytes(askLevel7Price.rest, 11) IN IF ~bidLevel7Price.ok THEN Fail ELSE
    LET askLevel7Volume == ReadBytes(bidLevel7Price.rest, 12) IN IF ~askLevel7Volume.ok THEN Fail ELSE
    LET bidLevel7Volume == ReadBytes(askLevel7Volume.rest, 12) IN IF ~bidLevel7Volume.ok THEN Fail ELSE
    LET askLevel8Price == ReadBytes(bidLevel7Volume.rest, 11) IN IF ~askLevel8Price.ok THEN Fail ELSE
    LET bidLevel8Price == ReadBytes(askLevel8Price.rest, 11) IN IF ~bidLevel8Price.ok THEN Fail ELSE
    LET askLevel8Volume == ReadBytes(bidLevel8Price.rest, 12) IN IF ~askLevel8Volume.ok THEN Fail ELSE
    LET bidLevel8Volume == ReadBytes(askLevel8Volume.rest, 12) IN IF ~bidLevel8Volume.ok THEN Fail ELSE
    LET askLevel9Price == ReadBytes(bidLevel8Volume.rest, 11) IN IF ~askLevel9Price.ok THEN Fail ELSE
    LET bidLevel9Price == ReadBytes(askLevel9Price.rest, 11) IN IF ~bidLevel9Price.ok THEN Fail ELSE
    LET askLevel9Volume == ReadBytes(bidLevel9Price.rest, 12) IN IF ~askLevel9Volume.ok THEN Fail ELSE
    LET bidLevel9Volume == ReadBytes(askLevel9Volume.rest, 12) IN IF ~bidLevel9Volume.ok THEN Fail ELSE
    LET askLevel10Price == ReadBytes(bidLevel9Volume.rest, 11) IN IF ~askLevel10Price.ok THEN Fail ELSE
    LET bidLevel10Price == ReadBytes(askLevel10Price.rest, 11) IN IF ~bidLevel10Price.ok THEN Fail ELSE
    LET askLevel10Volume == ReadBytes(bidLevel10Price.rest, 12) IN IF ~askLevel10Volume.ok THEN Fail ELSE
    LET bidLevel10Volume == ReadBytes(askLevel10Volume.rest, 12) IN IF ~bidLevel10Volume.ok THEN Fail ELSE
    LET totalAskVolume == ReadBytes(bidLevel10Volume.rest, 12) IN IF ~totalAskVolume.ok THEN Fail ELSE
    LET totalBidVolume == ReadBytes(totalAskVolume.rest, 12) IN IF ~totalBidVolume.ok THEN Fail ELSE
    LET estimatedTradingPrice == ReadBytes(totalBidVolume.rest, 11) IN IF ~estimatedTradingPrice.ok THEN Fail ELSE
    LET estimatedTradingVolume == ReadBytes(estimatedTradingPrice.rest, 12) IN IF ~estimatedTradingVolume.ok THEN Fail ELSE
    LET midpoint == ReadBytes(estimatedTradingVolume.rest, 11) IN IF ~midpoint.ok THEN Fail ELSE
    LET askMidPriceTotalVolume == ReadBytes(midpoint.rest, 12) IN IF ~askMidPriceTotalVolume.ok THEN Fail ELSE
    LET bidMidPriceTotalVolume == ReadBytes(askMidPriceTotalVolume.rest, 12) IN IF ~bidMidPriceTotalVolume.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(bidMidPriceTotalVolume.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
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
         askLevel6Price                |-> askLevel6Price.value,
         bidLevel6Price                |-> bidLevel6Price.value,
         askLevel6Volume               |-> askLevel6Volume.value,
         bidLevel6Volume               |-> bidLevel6Volume.value,
         askLevel7Price                |-> askLevel7Price.value,
         bidLevel7Price                |-> bidLevel7Price.value,
         askLevel7Volume               |-> askLevel7Volume.value,
         bidLevel7Volume               |-> bidLevel7Volume.value,
         askLevel8Price                |-> askLevel8Price.value,
         bidLevel8Price                |-> bidLevel8Price.value,
         askLevel8Volume               |-> askLevel8Volume.value,
         bidLevel8Volume               |-> bidLevel8Volume.value,
         askLevel9Price                |-> askLevel9Price.value,
         bidLevel9Price                |-> bidLevel9Price.value,
         askLevel9Volume               |-> askLevel9Volume.value,
         bidLevel9Volume               |-> bidLevel9Volume.value,
         askLevel10Price               |-> askLevel10Price.value,
         bidLevel10Price               |-> bidLevel10Price.value,
         askLevel10Volume              |-> askLevel10Volume.value,
         bidLevel10Volume              |-> bidLevel10Volume.value,
         totalAskVolume                |-> totalAskVolume.value,
         totalBidVolume                |-> totalBidVolume.value,
         estimatedTradingPrice         |-> estimatedTradingPrice.value,
         estimatedTradingVolume        |-> estimatedTradingVolume.value,
         midpoint                      |-> midpoint.value,
         askMidPriceTotalVolume        |-> askMidPriceTotalVolume.value,
         bidMidPriceTotalVolume        |-> bidMidPriceTotalVolume.value,
         endKeyword                    |-> endKeyword.value ], endKeyword.rest)

ZeroSecuritiesQuoteMmLpExcludedMessage ==
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
      askLevel6Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel6Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel6Volume               |-> [i \in 1 .. 12 |-> 0],
      bidLevel6Volume               |-> [i \in 1 .. 12 |-> 0],
      askLevel7Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel7Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel7Volume               |-> [i \in 1 .. 12 |-> 0],
      bidLevel7Volume               |-> [i \in 1 .. 12 |-> 0],
      askLevel8Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel8Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel8Volume               |-> [i \in 1 .. 12 |-> 0],
      bidLevel8Volume               |-> [i \in 1 .. 12 |-> 0],
      askLevel9Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel9Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel9Volume               |-> [i \in 1 .. 12 |-> 0],
      bidLevel9Volume               |-> [i \in 1 .. 12 |-> 0],
      askLevel10Price               |-> [i \in 1 .. 11 |-> 0],
      bidLevel10Price               |-> [i \in 1 .. 11 |-> 0],
      askLevel10Volume              |-> [i \in 1 .. 12 |-> 0],
      bidLevel10Volume              |-> [i \in 1 .. 12 |-> 0],
      totalAskVolume                |-> [i \in 1 .. 12 |-> 0],
      totalBidVolume                |-> [i \in 1 .. 12 |-> 0],
      estimatedTradingPrice         |-> [i \in 1 .. 11 |-> 0],
      estimatedTradingVolume        |-> [i \in 1 .. 12 |-> 0],
      midpoint                      |-> [i \in 1 .. 11 |-> 0],
      askMidPriceTotalVolume        |-> [i \in 1 .. 12 |-> 0],
      bidMidPriceTotalVolume        |-> [i \in 1 .. 12 |-> 0],
      endKeyword                    |-> [i \in 1 .. 1 |-> 0] ]

(* Securities Quote Mm Lp Excluded Message at zero, then each field in turn at the values it is checked at *)
CheckedSecuritiesQuoteMmLpExcludedMessage ==
    { ZeroSecuritiesQuoteMmLpExcludedMessage }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.processingTimeOfTradingSystem = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.askLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.bidLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.askLevel1Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.bidLevel1Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.askLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.bidLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.askLevel2Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.bidLevel2Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.askLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.bidLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.askLevel3Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.bidLevel3Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.askLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.bidLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.askLevel4Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.bidLevel4Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.askLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.bidLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.askLevel5Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.bidLevel5Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.askLevel6Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.bidLevel6Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.askLevel6Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.bidLevel6Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.askLevel7Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.bidLevel7Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.askLevel7Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.bidLevel7Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.askLevel8Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.bidLevel8Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.askLevel8Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.bidLevel8Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.askLevel9Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.bidLevel9Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.askLevel9Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.bidLevel9Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.askLevel10Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.bidLevel10Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.askLevel10Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.bidLevel10Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.totalAskVolume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.totalBidVolume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.estimatedTradingPrice = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.estimatedTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.midpoint = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.askMidPriceTotalVolume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.bidMidPriceTotalVolume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpExcludedMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Securities Quote Mm Lp Included Message: 825 bytes                      *)
(***************************************************************************)

SecuritiesQuoteMmLpIncludedMessage ==
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
      midpoint                      : Sample(11),
      askMidPriceTotalVolume        : Sample(12),
      bidMidPriceTotalVolume        : Sample(12),
      endKeyword                    : Sample(1) ]

EncodeSecuritiesQuoteMmLpIncludedMessage(message) ==
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
        \o message.midpoint
        \o message.askMidPriceTotalVolume
        \o message.bidMidPriceTotalVolume
        \o message.endKeyword

DecodeSecuritiesQuoteMmLpIncludedMessage(bytes) ==
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
    LET midpoint == ReadBytes(estimatedTradingVolume.rest, 11) IN IF ~midpoint.ok THEN Fail ELSE
    LET askMidPriceTotalVolume == ReadBytes(midpoint.rest, 12) IN IF ~askMidPriceTotalVolume.ok THEN Fail ELSE
    LET bidMidPriceTotalVolume == ReadBytes(askMidPriceTotalVolume.rest, 12) IN IF ~bidMidPriceTotalVolume.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(bidMidPriceTotalVolume.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
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
         midpoint                      |-> midpoint.value,
         askMidPriceTotalVolume        |-> askMidPriceTotalVolume.value,
         bidMidPriceTotalVolume        |-> bidMidPriceTotalVolume.value,
         endKeyword                    |-> endKeyword.value ], endKeyword.rest)

ZeroSecuritiesQuoteMmLpIncludedMessage ==
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
      midpoint                      |-> [i \in 1 .. 11 |-> 0],
      askMidPriceTotalVolume        |-> [i \in 1 .. 12 |-> 0],
      bidMidPriceTotalVolume        |-> [i \in 1 .. 12 |-> 0],
      endKeyword                    |-> [i \in 1 .. 1 |-> 0] ]

(* Securities Quote Mm Lp Included Message at zero, then each field in turn at the values it is checked at *)
CheckedSecuritiesQuoteMmLpIncludedMessage ==
    { ZeroSecuritiesQuoteMmLpIncludedMessage }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.processingTimeOfTradingSystem = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.askLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.bidLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.askLevel1Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.bidLevel1Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.lpAskLevel1Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.lpBidLevel1Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.askLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.bidLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.askLevel2Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.bidLevel2Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.lpAskLevel2Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.lpBidLevel2Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.askLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.bidLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.askLevel3Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.bidLevel3Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.lpAskLevel3Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.lpBidLevel3Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.askLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.bidLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.askLevel4Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.bidLevel4Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.lpAskLevel4Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.lpBidLevel4Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.askLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.bidLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.askLevel5Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.bidLevel5Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.lpAskLevel5Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.lpBidLevel5Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.askLevel6Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.bidLevel6Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.askLevel6Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.bidLevel6Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.lpAskLevel6Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.lpBidLevel6Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.askLevel7Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.bidLevel7Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.askLevel7Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.bidLevel7Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.lpAskLevel7Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.lpBidLevel7Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.askLevel8Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.bidLevel8Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.askLevel8Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.bidLevel8Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.lpAskLevel8Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.lpBidLevel8Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.askLevel9Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.bidLevel9Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.askLevel9Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.bidLevel9Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.lpAskLevel9Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.lpBidLevel9Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.askLevel10Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.bidLevel10Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.askLevel10Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.bidLevel10Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.lpAskLevel10Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.lpBidLevel10Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.totalAskVolume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.totalBidVolume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.estimatedTradingPrice = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.estimatedTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.midpoint = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.askMidPriceTotalVolume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.bidMidPriceTotalVolume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuoteMmLpIncludedMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Securities Snapshot Mm Lp Excluded Message: 680 bytes                   *)
(***************************************************************************)

SecuritiesSnapshotMmLpExcludedMessage ==
    [ boardId                           : Sample(2),
      sessionId                         : Sample(2),
      isinCode                          : Sample(12),
      aDesignatedNumberForAnIssue       : Sample(6),
      priceChangeAgainstPreviousDay     : Sample(1),
      aPriceChangeAgainstThePreviousDay : Sample(11),
      upperLimitPrice                   : Sample(11),
      lowerLimitPrice                   : Sample(11),
      currentPrice                      : Sample(11),
      openingPrice                      : Sample(11),
      todaysHigh                        : Sample(11),
      todaysLow                         : Sample(11),
      accumulatedTradingVolume          : Sample(12),
      accumulatedTradingValue           : Sample(22),
      finalAskBidTypeCode               : Sample(1),
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
      askLevel6Price                    : Sample(11),
      bidLevel6Price                    : Sample(11),
      askLevel6Volume                   : Sample(12),
      bidLevel6Volume                   : Sample(12),
      askLevel7Price                    : Sample(11),
      bidLevel7Price                    : Sample(11),
      askLevel7Volume                   : Sample(12),
      bidLevel7Volume                   : Sample(12),
      askLevel8Price                    : Sample(11),
      bidLevel8Price                    : Sample(11),
      askLevel8Volume                   : Sample(12),
      bidLevel8Volume                   : Sample(12),
      askLevel9Price                    : Sample(11),
      bidLevel9Price                    : Sample(11),
      askLevel9Volume                   : Sample(12),
      bidLevel9Volume                   : Sample(12),
      askLevel10Price                   : Sample(11),
      bidLevel10Price                   : Sample(11),
      askLevel10Volume                  : Sample(12),
      bidLevel10Volume                  : Sample(12),
      totalAskVolume                    : Sample(12),
      totalBidVolume                    : Sample(12),
      estimatedTradingPrice             : Sample(11),
      estimatedTradingVolume            : Sample(12),
      closingPriceTypeCode              : Sample(1),
      tradingHalt                       : Sample(1),
      midpoint                          : Sample(11),
      askMidPriceTotalVolume            : Sample(12),
      bidMidPriceTotalVolume            : Sample(12),
      endKeyword                        : Sample(1) ]

EncodeSecuritiesSnapshotMmLpExcludedMessage(message) ==
    message.boardId
        \o message.sessionId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.priceChangeAgainstPreviousDay
        \o message.aPriceChangeAgainstThePreviousDay
        \o message.upperLimitPrice
        \o message.lowerLimitPrice
        \o message.currentPrice
        \o message.openingPrice
        \o message.todaysHigh
        \o message.todaysLow
        \o message.accumulatedTradingVolume
        \o message.accumulatedTradingValue
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
        \o message.askLevel6Price
        \o message.bidLevel6Price
        \o message.askLevel6Volume
        \o message.bidLevel6Volume
        \o message.askLevel7Price
        \o message.bidLevel7Price
        \o message.askLevel7Volume
        \o message.bidLevel7Volume
        \o message.askLevel8Price
        \o message.bidLevel8Price
        \o message.askLevel8Volume
        \o message.bidLevel8Volume
        \o message.askLevel9Price
        \o message.bidLevel9Price
        \o message.askLevel9Volume
        \o message.bidLevel9Volume
        \o message.askLevel10Price
        \o message.bidLevel10Price
        \o message.askLevel10Volume
        \o message.bidLevel10Volume
        \o message.totalAskVolume
        \o message.totalBidVolume
        \o message.estimatedTradingPrice
        \o message.estimatedTradingVolume
        \o message.closingPriceTypeCode
        \o message.tradingHalt
        \o message.midpoint
        \o message.askMidPriceTotalVolume
        \o message.bidMidPriceTotalVolume
        \o message.endKeyword

DecodeSecuritiesSnapshotMmLpExcludedMessage(bytes) ==
    LET boardId == ReadBytes(bytes, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(boardId.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(sessionId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET priceChangeAgainstPreviousDay == ReadBytes(aDesignatedNumberForAnIssue.rest, 1) IN IF ~priceChangeAgainstPreviousDay.ok THEN Fail ELSE
    LET aPriceChangeAgainstThePreviousDay == ReadBytes(priceChangeAgainstPreviousDay.rest, 11) IN IF ~aPriceChangeAgainstThePreviousDay.ok THEN Fail ELSE
    LET upperLimitPrice == ReadBytes(aPriceChangeAgainstThePreviousDay.rest, 11) IN IF ~upperLimitPrice.ok THEN Fail ELSE
    LET lowerLimitPrice == ReadBytes(upperLimitPrice.rest, 11) IN IF ~lowerLimitPrice.ok THEN Fail ELSE
    LET currentPrice == ReadBytes(lowerLimitPrice.rest, 11) IN IF ~currentPrice.ok THEN Fail ELSE
    LET openingPrice == ReadBytes(currentPrice.rest, 11) IN IF ~openingPrice.ok THEN Fail ELSE
    LET todaysHigh == ReadBytes(openingPrice.rest, 11) IN IF ~todaysHigh.ok THEN Fail ELSE
    LET todaysLow == ReadBytes(todaysHigh.rest, 11) IN IF ~todaysLow.ok THEN Fail ELSE
    LET accumulatedTradingVolume == ReadBytes(todaysLow.rest, 12) IN IF ~accumulatedTradingVolume.ok THEN Fail ELSE
    LET accumulatedTradingValue == ReadBytes(accumulatedTradingVolume.rest, 22) IN IF ~accumulatedTradingValue.ok THEN Fail ELSE
    LET finalAskBidTypeCode == ReadBytes(accumulatedTradingValue.rest, 1) IN IF ~finalAskBidTypeCode.ok THEN Fail ELSE
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
    LET askLevel6Price == ReadBytes(bidLevel5Volume.rest, 11) IN IF ~askLevel6Price.ok THEN Fail ELSE
    LET bidLevel6Price == ReadBytes(askLevel6Price.rest, 11) IN IF ~bidLevel6Price.ok THEN Fail ELSE
    LET askLevel6Volume == ReadBytes(bidLevel6Price.rest, 12) IN IF ~askLevel6Volume.ok THEN Fail ELSE
    LET bidLevel6Volume == ReadBytes(askLevel6Volume.rest, 12) IN IF ~bidLevel6Volume.ok THEN Fail ELSE
    LET askLevel7Price == ReadBytes(bidLevel6Volume.rest, 11) IN IF ~askLevel7Price.ok THEN Fail ELSE
    LET bidLevel7Price == ReadBytes(askLevel7Price.rest, 11) IN IF ~bidLevel7Price.ok THEN Fail ELSE
    LET askLevel7Volume == ReadBytes(bidLevel7Price.rest, 12) IN IF ~askLevel7Volume.ok THEN Fail ELSE
    LET bidLevel7Volume == ReadBytes(askLevel7Volume.rest, 12) IN IF ~bidLevel7Volume.ok THEN Fail ELSE
    LET askLevel8Price == ReadBytes(bidLevel7Volume.rest, 11) IN IF ~askLevel8Price.ok THEN Fail ELSE
    LET bidLevel8Price == ReadBytes(askLevel8Price.rest, 11) IN IF ~bidLevel8Price.ok THEN Fail ELSE
    LET askLevel8Volume == ReadBytes(bidLevel8Price.rest, 12) IN IF ~askLevel8Volume.ok THEN Fail ELSE
    LET bidLevel8Volume == ReadBytes(askLevel8Volume.rest, 12) IN IF ~bidLevel8Volume.ok THEN Fail ELSE
    LET askLevel9Price == ReadBytes(bidLevel8Volume.rest, 11) IN IF ~askLevel9Price.ok THEN Fail ELSE
    LET bidLevel9Price == ReadBytes(askLevel9Price.rest, 11) IN IF ~bidLevel9Price.ok THEN Fail ELSE
    LET askLevel9Volume == ReadBytes(bidLevel9Price.rest, 12) IN IF ~askLevel9Volume.ok THEN Fail ELSE
    LET bidLevel9Volume == ReadBytes(askLevel9Volume.rest, 12) IN IF ~bidLevel9Volume.ok THEN Fail ELSE
    LET askLevel10Price == ReadBytes(bidLevel9Volume.rest, 11) IN IF ~askLevel10Price.ok THEN Fail ELSE
    LET bidLevel10Price == ReadBytes(askLevel10Price.rest, 11) IN IF ~bidLevel10Price.ok THEN Fail ELSE
    LET askLevel10Volume == ReadBytes(bidLevel10Price.rest, 12) IN IF ~askLevel10Volume.ok THEN Fail ELSE
    LET bidLevel10Volume == ReadBytes(askLevel10Volume.rest, 12) IN IF ~bidLevel10Volume.ok THEN Fail ELSE
    LET totalAskVolume == ReadBytes(bidLevel10Volume.rest, 12) IN IF ~totalAskVolume.ok THEN Fail ELSE
    LET totalBidVolume == ReadBytes(totalAskVolume.rest, 12) IN IF ~totalBidVolume.ok THEN Fail ELSE
    LET estimatedTradingPrice == ReadBytes(totalBidVolume.rest, 11) IN IF ~estimatedTradingPrice.ok THEN Fail ELSE
    LET estimatedTradingVolume == ReadBytes(estimatedTradingPrice.rest, 12) IN IF ~estimatedTradingVolume.ok THEN Fail ELSE
    LET closingPriceTypeCode == ReadBytes(estimatedTradingVolume.rest, 1) IN IF ~closingPriceTypeCode.ok THEN Fail ELSE
    LET tradingHalt == ReadBytes(closingPriceTypeCode.rest, 1) IN IF ~tradingHalt.ok THEN Fail ELSE
    LET midpoint == ReadBytes(tradingHalt.rest, 11) IN IF ~midpoint.ok THEN Fail ELSE
    LET askMidPriceTotalVolume == ReadBytes(midpoint.rest, 12) IN IF ~askMidPriceTotalVolume.ok THEN Fail ELSE
    LET bidMidPriceTotalVolume == ReadBytes(askMidPriceTotalVolume.rest, 12) IN IF ~bidMidPriceTotalVolume.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(bidMidPriceTotalVolume.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ boardId                           |-> boardId.value,
         sessionId                         |-> sessionId.value,
         isinCode                          |-> isinCode.value,
         aDesignatedNumberForAnIssue       |-> aDesignatedNumberForAnIssue.value,
         priceChangeAgainstPreviousDay     |-> priceChangeAgainstPreviousDay.value,
         aPriceChangeAgainstThePreviousDay |-> aPriceChangeAgainstThePreviousDay.value,
         upperLimitPrice                   |-> upperLimitPrice.value,
         lowerLimitPrice                   |-> lowerLimitPrice.value,
         currentPrice                      |-> currentPrice.value,
         openingPrice                      |-> openingPrice.value,
         todaysHigh                        |-> todaysHigh.value,
         todaysLow                         |-> todaysLow.value,
         accumulatedTradingVolume          |-> accumulatedTradingVolume.value,
         accumulatedTradingValue           |-> accumulatedTradingValue.value,
         finalAskBidTypeCode               |-> finalAskBidTypeCode.value,
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
         askLevel6Price                    |-> askLevel6Price.value,
         bidLevel6Price                    |-> bidLevel6Price.value,
         askLevel6Volume                   |-> askLevel6Volume.value,
         bidLevel6Volume                   |-> bidLevel6Volume.value,
         askLevel7Price                    |-> askLevel7Price.value,
         bidLevel7Price                    |-> bidLevel7Price.value,
         askLevel7Volume                   |-> askLevel7Volume.value,
         bidLevel7Volume                   |-> bidLevel7Volume.value,
         askLevel8Price                    |-> askLevel8Price.value,
         bidLevel8Price                    |-> bidLevel8Price.value,
         askLevel8Volume                   |-> askLevel8Volume.value,
         bidLevel8Volume                   |-> bidLevel8Volume.value,
         askLevel9Price                    |-> askLevel9Price.value,
         bidLevel9Price                    |-> bidLevel9Price.value,
         askLevel9Volume                   |-> askLevel9Volume.value,
         bidLevel9Volume                   |-> bidLevel9Volume.value,
         askLevel10Price                   |-> askLevel10Price.value,
         bidLevel10Price                   |-> bidLevel10Price.value,
         askLevel10Volume                  |-> askLevel10Volume.value,
         bidLevel10Volume                  |-> bidLevel10Volume.value,
         totalAskVolume                    |-> totalAskVolume.value,
         totalBidVolume                    |-> totalBidVolume.value,
         estimatedTradingPrice             |-> estimatedTradingPrice.value,
         estimatedTradingVolume            |-> estimatedTradingVolume.value,
         closingPriceTypeCode              |-> closingPriceTypeCode.value,
         tradingHalt                       |-> tradingHalt.value,
         midpoint                          |-> midpoint.value,
         askMidPriceTotalVolume            |-> askMidPriceTotalVolume.value,
         bidMidPriceTotalVolume            |-> bidMidPriceTotalVolume.value,
         endKeyword                        |-> endKeyword.value ], endKeyword.rest)

ZeroSecuritiesSnapshotMmLpExcludedMessage ==
    [ boardId                           |-> [i \in 1 .. 2 |-> 0],
      sessionId                         |-> [i \in 1 .. 2 |-> 0],
      isinCode                          |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue       |-> [i \in 1 .. 6 |-> 0],
      priceChangeAgainstPreviousDay     |-> [i \in 1 .. 1 |-> 0],
      aPriceChangeAgainstThePreviousDay |-> [i \in 1 .. 11 |-> 0],
      upperLimitPrice                   |-> [i \in 1 .. 11 |-> 0],
      lowerLimitPrice                   |-> [i \in 1 .. 11 |-> 0],
      currentPrice                      |-> [i \in 1 .. 11 |-> 0],
      openingPrice                      |-> [i \in 1 .. 11 |-> 0],
      todaysHigh                        |-> [i \in 1 .. 11 |-> 0],
      todaysLow                         |-> [i \in 1 .. 11 |-> 0],
      accumulatedTradingVolume          |-> [i \in 1 .. 12 |-> 0],
      accumulatedTradingValue           |-> [i \in 1 .. 22 |-> 0],
      finalAskBidTypeCode               |-> [i \in 1 .. 1 |-> 0],
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
      askLevel6Price                    |-> [i \in 1 .. 11 |-> 0],
      bidLevel6Price                    |-> [i \in 1 .. 11 |-> 0],
      askLevel6Volume                   |-> [i \in 1 .. 12 |-> 0],
      bidLevel6Volume                   |-> [i \in 1 .. 12 |-> 0],
      askLevel7Price                    |-> [i \in 1 .. 11 |-> 0],
      bidLevel7Price                    |-> [i \in 1 .. 11 |-> 0],
      askLevel7Volume                   |-> [i \in 1 .. 12 |-> 0],
      bidLevel7Volume                   |-> [i \in 1 .. 12 |-> 0],
      askLevel8Price                    |-> [i \in 1 .. 11 |-> 0],
      bidLevel8Price                    |-> [i \in 1 .. 11 |-> 0],
      askLevel8Volume                   |-> [i \in 1 .. 12 |-> 0],
      bidLevel8Volume                   |-> [i \in 1 .. 12 |-> 0],
      askLevel9Price                    |-> [i \in 1 .. 11 |-> 0],
      bidLevel9Price                    |-> [i \in 1 .. 11 |-> 0],
      askLevel9Volume                   |-> [i \in 1 .. 12 |-> 0],
      bidLevel9Volume                   |-> [i \in 1 .. 12 |-> 0],
      askLevel10Price                   |-> [i \in 1 .. 11 |-> 0],
      bidLevel10Price                   |-> [i \in 1 .. 11 |-> 0],
      askLevel10Volume                  |-> [i \in 1 .. 12 |-> 0],
      bidLevel10Volume                  |-> [i \in 1 .. 12 |-> 0],
      totalAskVolume                    |-> [i \in 1 .. 12 |-> 0],
      totalBidVolume                    |-> [i \in 1 .. 12 |-> 0],
      estimatedTradingPrice             |-> [i \in 1 .. 11 |-> 0],
      estimatedTradingVolume            |-> [i \in 1 .. 12 |-> 0],
      closingPriceTypeCode              |-> [i \in 1 .. 1 |-> 0],
      tradingHalt                       |-> [i \in 1 .. 1 |-> 0],
      midpoint                          |-> [i \in 1 .. 11 |-> 0],
      askMidPriceTotalVolume            |-> [i \in 1 .. 12 |-> 0],
      bidMidPriceTotalVolume            |-> [i \in 1 .. 12 |-> 0],
      endKeyword                        |-> [i \in 1 .. 1 |-> 0] ]

(* Securities Snapshot Mm Lp Excluded Message at zero, then each field in turn at the values it is checked at *)
CheckedSecuritiesSnapshotMmLpExcludedMessage ==
    { ZeroSecuritiesSnapshotMmLpExcludedMessage }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.priceChangeAgainstPreviousDay = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.aPriceChangeAgainstThePreviousDay = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.upperLimitPrice = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.lowerLimitPrice = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.currentPrice = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.openingPrice = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.todaysHigh = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.todaysLow = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.accumulatedTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.accumulatedTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.finalAskBidTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.askLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.bidLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.askLevel1Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.bidLevel1Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.askLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.bidLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.askLevel2Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.bidLevel2Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.askLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.bidLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.askLevel3Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.bidLevel3Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.askLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.bidLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.askLevel4Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.bidLevel4Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.askLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.bidLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.askLevel5Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.bidLevel5Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.askLevel6Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.bidLevel6Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.askLevel6Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.bidLevel6Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.askLevel7Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.bidLevel7Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.askLevel7Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.bidLevel7Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.askLevel8Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.bidLevel8Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.askLevel8Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.bidLevel8Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.askLevel9Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.bidLevel9Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.askLevel9Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.bidLevel9Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.askLevel10Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.bidLevel10Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.askLevel10Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.bidLevel10Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.totalAskVolume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.totalBidVolume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.estimatedTradingPrice = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.estimatedTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.closingPriceTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.tradingHalt = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.midpoint = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.askMidPriceTotalVolume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.bidMidPriceTotalVolume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpExcludedMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Securities Snapshot Mm Lp Included Message: 930 bytes                   *)
(***************************************************************************)

SecuritiesSnapshotMmLpIncludedMessage ==
    [ boardId                           : Sample(2),
      sessionId                         : Sample(2),
      isinCode                          : Sample(12),
      aDesignatedNumberForAnIssue       : Sample(6),
      priceChangeAgainstPreviousDay     : Sample(1),
      aPriceChangeAgainstThePreviousDay : Sample(11),
      upperLimitPrice                   : Sample(11),
      lowerLimitPrice                   : Sample(11),
      currentPrice                      : Sample(11),
      openingPrice                      : Sample(11),
      todaysHigh                        : Sample(11),
      todaysLow                         : Sample(11),
      accumulatedTradingVolume          : Sample(12),
      accumulatedTradingValue           : Sample(22),
      finalAskBidTypeCode               : Sample(1),
      askLevel1Price                    : Sample(11),
      bidLevel1Price                    : Sample(11),
      askLevel1Volume                   : Sample(12),
      bidLevel1Volume                   : Sample(12),
      lpAskLevel1Volume                 : Sample(12),
      lpBidLevel1Volume                 : Sample(12),
      askLevel2Price                    : Sample(11),
      bidLevel2Price                    : Sample(11),
      askLevel2Volume                   : Sample(12),
      bidLevel2Volume                   : Sample(12),
      lpAskLevel2Volume                 : Sample(12),
      lpBidLevel2Volume                 : Sample(12),
      askLevel3Price                    : Sample(11),
      bidLevel3Price                    : Sample(11),
      askLevel3Volume                   : Sample(12),
      bidLevel3Volume                   : Sample(12),
      lpAskLevel3Volume                 : Sample(12),
      lpBidLevel3Volume                 : Sample(12),
      askLevel4Price                    : Sample(11),
      bidLevel4Price                    : Sample(11),
      askLevel4Volume                   : Sample(12),
      bidLevel4Volume                   : Sample(12),
      lpAskLevel4Volume                 : Sample(12),
      lpBidLevel4Volume                 : Sample(12),
      askLevel5Price                    : Sample(11),
      bidLevel5Price                    : Sample(11),
      askLevel5Volume                   : Sample(12),
      bidLevel5Volume                   : Sample(12),
      lpAskLevel5Volume                 : Sample(12),
      lpBidLevel5Volume                 : Sample(12),
      askLevel6Price                    : Sample(11),
      bidLevel6Price                    : Sample(11),
      askLevel6Volume                   : Sample(12),
      bidLevel6Volume                   : Sample(12),
      lpAskLevel6Volume                 : Sample(12),
      lpBidLevel6Volume                 : Sample(12),
      askLevel7Price                    : Sample(11),
      bidLevel7Price                    : Sample(11),
      askLevel7Volume                   : Sample(12),
      bidLevel7Volume                   : Sample(12),
      lpAskLevel7Volume                 : Sample(12),
      lpBidLevel7Volume                 : Sample(12),
      askLevel8Price                    : Sample(11),
      bidLevel8Price                    : Sample(11),
      askLevel8Volume                   : Sample(12),
      bidLevel8Volume                   : Sample(12),
      lpAskLevel8Volume                 : Sample(12),
      lpBidLevel8Volume                 : Sample(12),
      askLevel9Price                    : Sample(11),
      bidLevel9Price                    : Sample(11),
      askLevel9Volume                   : Sample(12),
      bidLevel9Volume                   : Sample(12),
      lpAskLevel9Volume                 : Sample(12),
      lpBidLevel9Volume                 : Sample(12),
      askLevel10Price                   : Sample(11),
      bidLevel10Price                   : Sample(11),
      askLevel10Volume                  : Sample(12),
      bidLevel10Volume                  : Sample(12),
      lpAskLevel10Volume                : Sample(12),
      lpBidLevel10Volume                : Sample(12),
      totalAskVolume                    : Sample(12),
      totalBidVolume                    : Sample(12),
      estimatedTradingPrice             : Sample(11),
      estimatedTradingVolume            : Sample(12),
      closingPriceTypeCode              : Sample(1),
      tradingHalt                       : Sample(1),
      knockOutElwTypeCode               : Sample(1),
      knockOutElwTriggeringTime         : Sample(9),
      midpoint                          : Sample(11),
      askMidPriceTotalVolume            : Sample(12),
      bidMidPriceTotalVolume            : Sample(12),
      endKeyword                        : Sample(1) ]

EncodeSecuritiesSnapshotMmLpIncludedMessage(message) ==
    message.boardId
        \o message.sessionId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.priceChangeAgainstPreviousDay
        \o message.aPriceChangeAgainstThePreviousDay
        \o message.upperLimitPrice
        \o message.lowerLimitPrice
        \o message.currentPrice
        \o message.openingPrice
        \o message.todaysHigh
        \o message.todaysLow
        \o message.accumulatedTradingVolume
        \o message.accumulatedTradingValue
        \o message.finalAskBidTypeCode
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
        \o message.closingPriceTypeCode
        \o message.tradingHalt
        \o message.knockOutElwTypeCode
        \o message.knockOutElwTriggeringTime
        \o message.midpoint
        \o message.askMidPriceTotalVolume
        \o message.bidMidPriceTotalVolume
        \o message.endKeyword

DecodeSecuritiesSnapshotMmLpIncludedMessage(bytes) ==
    LET boardId == ReadBytes(bytes, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(boardId.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(sessionId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET priceChangeAgainstPreviousDay == ReadBytes(aDesignatedNumberForAnIssue.rest, 1) IN IF ~priceChangeAgainstPreviousDay.ok THEN Fail ELSE
    LET aPriceChangeAgainstThePreviousDay == ReadBytes(priceChangeAgainstPreviousDay.rest, 11) IN IF ~aPriceChangeAgainstThePreviousDay.ok THEN Fail ELSE
    LET upperLimitPrice == ReadBytes(aPriceChangeAgainstThePreviousDay.rest, 11) IN IF ~upperLimitPrice.ok THEN Fail ELSE
    LET lowerLimitPrice == ReadBytes(upperLimitPrice.rest, 11) IN IF ~lowerLimitPrice.ok THEN Fail ELSE
    LET currentPrice == ReadBytes(lowerLimitPrice.rest, 11) IN IF ~currentPrice.ok THEN Fail ELSE
    LET openingPrice == ReadBytes(currentPrice.rest, 11) IN IF ~openingPrice.ok THEN Fail ELSE
    LET todaysHigh == ReadBytes(openingPrice.rest, 11) IN IF ~todaysHigh.ok THEN Fail ELSE
    LET todaysLow == ReadBytes(todaysHigh.rest, 11) IN IF ~todaysLow.ok THEN Fail ELSE
    LET accumulatedTradingVolume == ReadBytes(todaysLow.rest, 12) IN IF ~accumulatedTradingVolume.ok THEN Fail ELSE
    LET accumulatedTradingValue == ReadBytes(accumulatedTradingVolume.rest, 22) IN IF ~accumulatedTradingValue.ok THEN Fail ELSE
    LET finalAskBidTypeCode == ReadBytes(accumulatedTradingValue.rest, 1) IN IF ~finalAskBidTypeCode.ok THEN Fail ELSE
    LET askLevel1Price == ReadBytes(finalAskBidTypeCode.rest, 11) IN IF ~askLevel1Price.ok THEN Fail ELSE
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
    LET closingPriceTypeCode == ReadBytes(estimatedTradingVolume.rest, 1) IN IF ~closingPriceTypeCode.ok THEN Fail ELSE
    LET tradingHalt == ReadBytes(closingPriceTypeCode.rest, 1) IN IF ~tradingHalt.ok THEN Fail ELSE
    LET knockOutElwTypeCode == ReadBytes(tradingHalt.rest, 1) IN IF ~knockOutElwTypeCode.ok THEN Fail ELSE
    LET knockOutElwTriggeringTime == ReadBytes(knockOutElwTypeCode.rest, 9) IN IF ~knockOutElwTriggeringTime.ok THEN Fail ELSE
    LET midpoint == ReadBytes(knockOutElwTriggeringTime.rest, 11) IN IF ~midpoint.ok THEN Fail ELSE
    LET askMidPriceTotalVolume == ReadBytes(midpoint.rest, 12) IN IF ~askMidPriceTotalVolume.ok THEN Fail ELSE
    LET bidMidPriceTotalVolume == ReadBytes(askMidPriceTotalVolume.rest, 12) IN IF ~bidMidPriceTotalVolume.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(bidMidPriceTotalVolume.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ boardId                           |-> boardId.value,
         sessionId                         |-> sessionId.value,
         isinCode                          |-> isinCode.value,
         aDesignatedNumberForAnIssue       |-> aDesignatedNumberForAnIssue.value,
         priceChangeAgainstPreviousDay     |-> priceChangeAgainstPreviousDay.value,
         aPriceChangeAgainstThePreviousDay |-> aPriceChangeAgainstThePreviousDay.value,
         upperLimitPrice                   |-> upperLimitPrice.value,
         lowerLimitPrice                   |-> lowerLimitPrice.value,
         currentPrice                      |-> currentPrice.value,
         openingPrice                      |-> openingPrice.value,
         todaysHigh                        |-> todaysHigh.value,
         todaysLow                         |-> todaysLow.value,
         accumulatedTradingVolume          |-> accumulatedTradingVolume.value,
         accumulatedTradingValue           |-> accumulatedTradingValue.value,
         finalAskBidTypeCode               |-> finalAskBidTypeCode.value,
         askLevel1Price                    |-> askLevel1Price.value,
         bidLevel1Price                    |-> bidLevel1Price.value,
         askLevel1Volume                   |-> askLevel1Volume.value,
         bidLevel1Volume                   |-> bidLevel1Volume.value,
         lpAskLevel1Volume                 |-> lpAskLevel1Volume.value,
         lpBidLevel1Volume                 |-> lpBidLevel1Volume.value,
         askLevel2Price                    |-> askLevel2Price.value,
         bidLevel2Price                    |-> bidLevel2Price.value,
         askLevel2Volume                   |-> askLevel2Volume.value,
         bidLevel2Volume                   |-> bidLevel2Volume.value,
         lpAskLevel2Volume                 |-> lpAskLevel2Volume.value,
         lpBidLevel2Volume                 |-> lpBidLevel2Volume.value,
         askLevel3Price                    |-> askLevel3Price.value,
         bidLevel3Price                    |-> bidLevel3Price.value,
         askLevel3Volume                   |-> askLevel3Volume.value,
         bidLevel3Volume                   |-> bidLevel3Volume.value,
         lpAskLevel3Volume                 |-> lpAskLevel3Volume.value,
         lpBidLevel3Volume                 |-> lpBidLevel3Volume.value,
         askLevel4Price                    |-> askLevel4Price.value,
         bidLevel4Price                    |-> bidLevel4Price.value,
         askLevel4Volume                   |-> askLevel4Volume.value,
         bidLevel4Volume                   |-> bidLevel4Volume.value,
         lpAskLevel4Volume                 |-> lpAskLevel4Volume.value,
         lpBidLevel4Volume                 |-> lpBidLevel4Volume.value,
         askLevel5Price                    |-> askLevel5Price.value,
         bidLevel5Price                    |-> bidLevel5Price.value,
         askLevel5Volume                   |-> askLevel5Volume.value,
         bidLevel5Volume                   |-> bidLevel5Volume.value,
         lpAskLevel5Volume                 |-> lpAskLevel5Volume.value,
         lpBidLevel5Volume                 |-> lpBidLevel5Volume.value,
         askLevel6Price                    |-> askLevel6Price.value,
         bidLevel6Price                    |-> bidLevel6Price.value,
         askLevel6Volume                   |-> askLevel6Volume.value,
         bidLevel6Volume                   |-> bidLevel6Volume.value,
         lpAskLevel6Volume                 |-> lpAskLevel6Volume.value,
         lpBidLevel6Volume                 |-> lpBidLevel6Volume.value,
         askLevel7Price                    |-> askLevel7Price.value,
         bidLevel7Price                    |-> bidLevel7Price.value,
         askLevel7Volume                   |-> askLevel7Volume.value,
         bidLevel7Volume                   |-> bidLevel7Volume.value,
         lpAskLevel7Volume                 |-> lpAskLevel7Volume.value,
         lpBidLevel7Volume                 |-> lpBidLevel7Volume.value,
         askLevel8Price                    |-> askLevel8Price.value,
         bidLevel8Price                    |-> bidLevel8Price.value,
         askLevel8Volume                   |-> askLevel8Volume.value,
         bidLevel8Volume                   |-> bidLevel8Volume.value,
         lpAskLevel8Volume                 |-> lpAskLevel8Volume.value,
         lpBidLevel8Volume                 |-> lpBidLevel8Volume.value,
         askLevel9Price                    |-> askLevel9Price.value,
         bidLevel9Price                    |-> bidLevel9Price.value,
         askLevel9Volume                   |-> askLevel9Volume.value,
         bidLevel9Volume                   |-> bidLevel9Volume.value,
         lpAskLevel9Volume                 |-> lpAskLevel9Volume.value,
         lpBidLevel9Volume                 |-> lpBidLevel9Volume.value,
         askLevel10Price                   |-> askLevel10Price.value,
         bidLevel10Price                   |-> bidLevel10Price.value,
         askLevel10Volume                  |-> askLevel10Volume.value,
         bidLevel10Volume                  |-> bidLevel10Volume.value,
         lpAskLevel10Volume                |-> lpAskLevel10Volume.value,
         lpBidLevel10Volume                |-> lpBidLevel10Volume.value,
         totalAskVolume                    |-> totalAskVolume.value,
         totalBidVolume                    |-> totalBidVolume.value,
         estimatedTradingPrice             |-> estimatedTradingPrice.value,
         estimatedTradingVolume            |-> estimatedTradingVolume.value,
         closingPriceTypeCode              |-> closingPriceTypeCode.value,
         tradingHalt                       |-> tradingHalt.value,
         knockOutElwTypeCode               |-> knockOutElwTypeCode.value,
         knockOutElwTriggeringTime         |-> knockOutElwTriggeringTime.value,
         midpoint                          |-> midpoint.value,
         askMidPriceTotalVolume            |-> askMidPriceTotalVolume.value,
         bidMidPriceTotalVolume            |-> bidMidPriceTotalVolume.value,
         endKeyword                        |-> endKeyword.value ], endKeyword.rest)

ZeroSecuritiesSnapshotMmLpIncludedMessage ==
    [ boardId                           |-> [i \in 1 .. 2 |-> 0],
      sessionId                         |-> [i \in 1 .. 2 |-> 0],
      isinCode                          |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue       |-> [i \in 1 .. 6 |-> 0],
      priceChangeAgainstPreviousDay     |-> [i \in 1 .. 1 |-> 0],
      aPriceChangeAgainstThePreviousDay |-> [i \in 1 .. 11 |-> 0],
      upperLimitPrice                   |-> [i \in 1 .. 11 |-> 0],
      lowerLimitPrice                   |-> [i \in 1 .. 11 |-> 0],
      currentPrice                      |-> [i \in 1 .. 11 |-> 0],
      openingPrice                      |-> [i \in 1 .. 11 |-> 0],
      todaysHigh                        |-> [i \in 1 .. 11 |-> 0],
      todaysLow                         |-> [i \in 1 .. 11 |-> 0],
      accumulatedTradingVolume          |-> [i \in 1 .. 12 |-> 0],
      accumulatedTradingValue           |-> [i \in 1 .. 22 |-> 0],
      finalAskBidTypeCode               |-> [i \in 1 .. 1 |-> 0],
      askLevel1Price                    |-> [i \in 1 .. 11 |-> 0],
      bidLevel1Price                    |-> [i \in 1 .. 11 |-> 0],
      askLevel1Volume                   |-> [i \in 1 .. 12 |-> 0],
      bidLevel1Volume                   |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel1Volume                 |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel1Volume                 |-> [i \in 1 .. 12 |-> 0],
      askLevel2Price                    |-> [i \in 1 .. 11 |-> 0],
      bidLevel2Price                    |-> [i \in 1 .. 11 |-> 0],
      askLevel2Volume                   |-> [i \in 1 .. 12 |-> 0],
      bidLevel2Volume                   |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel2Volume                 |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel2Volume                 |-> [i \in 1 .. 12 |-> 0],
      askLevel3Price                    |-> [i \in 1 .. 11 |-> 0],
      bidLevel3Price                    |-> [i \in 1 .. 11 |-> 0],
      askLevel3Volume                   |-> [i \in 1 .. 12 |-> 0],
      bidLevel3Volume                   |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel3Volume                 |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel3Volume                 |-> [i \in 1 .. 12 |-> 0],
      askLevel4Price                    |-> [i \in 1 .. 11 |-> 0],
      bidLevel4Price                    |-> [i \in 1 .. 11 |-> 0],
      askLevel4Volume                   |-> [i \in 1 .. 12 |-> 0],
      bidLevel4Volume                   |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel4Volume                 |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel4Volume                 |-> [i \in 1 .. 12 |-> 0],
      askLevel5Price                    |-> [i \in 1 .. 11 |-> 0],
      bidLevel5Price                    |-> [i \in 1 .. 11 |-> 0],
      askLevel5Volume                   |-> [i \in 1 .. 12 |-> 0],
      bidLevel5Volume                   |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel5Volume                 |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel5Volume                 |-> [i \in 1 .. 12 |-> 0],
      askLevel6Price                    |-> [i \in 1 .. 11 |-> 0],
      bidLevel6Price                    |-> [i \in 1 .. 11 |-> 0],
      askLevel6Volume                   |-> [i \in 1 .. 12 |-> 0],
      bidLevel6Volume                   |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel6Volume                 |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel6Volume                 |-> [i \in 1 .. 12 |-> 0],
      askLevel7Price                    |-> [i \in 1 .. 11 |-> 0],
      bidLevel7Price                    |-> [i \in 1 .. 11 |-> 0],
      askLevel7Volume                   |-> [i \in 1 .. 12 |-> 0],
      bidLevel7Volume                   |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel7Volume                 |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel7Volume                 |-> [i \in 1 .. 12 |-> 0],
      askLevel8Price                    |-> [i \in 1 .. 11 |-> 0],
      bidLevel8Price                    |-> [i \in 1 .. 11 |-> 0],
      askLevel8Volume                   |-> [i \in 1 .. 12 |-> 0],
      bidLevel8Volume                   |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel8Volume                 |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel8Volume                 |-> [i \in 1 .. 12 |-> 0],
      askLevel9Price                    |-> [i \in 1 .. 11 |-> 0],
      bidLevel9Price                    |-> [i \in 1 .. 11 |-> 0],
      askLevel9Volume                   |-> [i \in 1 .. 12 |-> 0],
      bidLevel9Volume                   |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel9Volume                 |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel9Volume                 |-> [i \in 1 .. 12 |-> 0],
      askLevel10Price                   |-> [i \in 1 .. 11 |-> 0],
      bidLevel10Price                   |-> [i \in 1 .. 11 |-> 0],
      askLevel10Volume                  |-> [i \in 1 .. 12 |-> 0],
      bidLevel10Volume                  |-> [i \in 1 .. 12 |-> 0],
      lpAskLevel10Volume                |-> [i \in 1 .. 12 |-> 0],
      lpBidLevel10Volume                |-> [i \in 1 .. 12 |-> 0],
      totalAskVolume                    |-> [i \in 1 .. 12 |-> 0],
      totalBidVolume                    |-> [i \in 1 .. 12 |-> 0],
      estimatedTradingPrice             |-> [i \in 1 .. 11 |-> 0],
      estimatedTradingVolume            |-> [i \in 1 .. 12 |-> 0],
      closingPriceTypeCode              |-> [i \in 1 .. 1 |-> 0],
      tradingHalt                       |-> [i \in 1 .. 1 |-> 0],
      knockOutElwTypeCode               |-> [i \in 1 .. 1 |-> 0],
      knockOutElwTriggeringTime         |-> [i \in 1 .. 9 |-> 0],
      midpoint                          |-> [i \in 1 .. 11 |-> 0],
      askMidPriceTotalVolume            |-> [i \in 1 .. 12 |-> 0],
      bidMidPriceTotalVolume            |-> [i \in 1 .. 12 |-> 0],
      endKeyword                        |-> [i \in 1 .. 1 |-> 0] ]

(* Securities Snapshot Mm Lp Included Message at zero, then each field in turn at the values it is checked at *)
CheckedSecuritiesSnapshotMmLpIncludedMessage ==
    { ZeroSecuritiesSnapshotMmLpIncludedMessage }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.priceChangeAgainstPreviousDay = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.aPriceChangeAgainstThePreviousDay = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.upperLimitPrice = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.lowerLimitPrice = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.currentPrice = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.openingPrice = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.todaysHigh = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.todaysLow = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.accumulatedTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.accumulatedTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.finalAskBidTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.askLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.bidLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.askLevel1Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.bidLevel1Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.lpAskLevel1Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.lpBidLevel1Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.askLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.bidLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.askLevel2Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.bidLevel2Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.lpAskLevel2Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.lpBidLevel2Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.askLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.bidLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.askLevel3Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.bidLevel3Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.lpAskLevel3Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.lpBidLevel3Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.askLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.bidLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.askLevel4Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.bidLevel4Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.lpAskLevel4Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.lpBidLevel4Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.askLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.bidLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.askLevel5Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.bidLevel5Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.lpAskLevel5Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.lpBidLevel5Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.askLevel6Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.bidLevel6Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.askLevel6Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.bidLevel6Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.lpAskLevel6Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.lpBidLevel6Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.askLevel7Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.bidLevel7Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.askLevel7Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.bidLevel7Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.lpAskLevel7Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.lpBidLevel7Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.askLevel8Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.bidLevel8Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.askLevel8Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.bidLevel8Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.lpAskLevel8Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.lpBidLevel8Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.askLevel9Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.bidLevel9Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.askLevel9Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.bidLevel9Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.lpAskLevel9Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.lpBidLevel9Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.askLevel10Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.bidLevel10Price = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.askLevel10Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.bidLevel10Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.lpAskLevel10Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.lpBidLevel10Volume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.totalAskVolume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.totalBidVolume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.estimatedTradingPrice = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.estimatedTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.closingPriceTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.tradingHalt = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.knockOutElwTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.knockOutElwTriggeringTime = one] : one \in Sample(9) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.midpoint = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.askMidPriceTotalVolume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.bidMidPriceTotalVolume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesSnapshotMmLpIncludedMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Securities Order Filled Message: 181 bytes                              *)
(***************************************************************************)

SecuritiesOrderFilledMessage ==
    [ messageSequenceNumber             : Sample(8),
      boardId                           : Sample(2),
      sessionId                         : Sample(2),
      isinCode                          : Sample(12),
      aDesignatedNumberForAnIssue       : Sample(6),
      processingTimeOfTradingSystem     : Sample(12),
      priceChangeAgainstPreviousDay     : Sample(1),
      aPriceChangeAgainstThePreviousDay : Sample(11),
      tradingPrice                      : Sample(11),
      tradingVolume                     : Sample(10),
      openingPrice                      : Sample(11),
      todaysHigh                        : Sample(11),
      todaysLow                         : Sample(11),
      accumulatedTradingVolume          : Sample(12),
      accumulatedTradingValue           : Sample(22),
      finalAskBidTypeCode               : Sample(1),
      lpHoldingQuantity                 : Sample(15),
      theBestAsk                        : Sample(11),
      theBestBid                        : Sample(11),
      endKeyword                        : Sample(1) ]

EncodeSecuritiesOrderFilledMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.sessionId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.processingTimeOfTradingSystem
        \o message.priceChangeAgainstPreviousDay
        \o message.aPriceChangeAgainstThePreviousDay
        \o message.tradingPrice
        \o message.tradingVolume
        \o message.openingPrice
        \o message.todaysHigh
        \o message.todaysLow
        \o message.accumulatedTradingVolume
        \o message.accumulatedTradingValue
        \o message.finalAskBidTypeCode
        \o message.lpHoldingQuantity
        \o message.theBestAsk
        \o message.theBestBid
        \o message.endKeyword

DecodeSecuritiesOrderFilledMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(boardId.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(sessionId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET processingTimeOfTradingSystem == ReadBytes(aDesignatedNumberForAnIssue.rest, 12) IN IF ~processingTimeOfTradingSystem.ok THEN Fail ELSE
    LET priceChangeAgainstPreviousDay == ReadBytes(processingTimeOfTradingSystem.rest, 1) IN IF ~priceChangeAgainstPreviousDay.ok THEN Fail ELSE
    LET aPriceChangeAgainstThePreviousDay == ReadBytes(priceChangeAgainstPreviousDay.rest, 11) IN IF ~aPriceChangeAgainstThePreviousDay.ok THEN Fail ELSE
    LET tradingPrice == ReadBytes(aPriceChangeAgainstThePreviousDay.rest, 11) IN IF ~tradingPrice.ok THEN Fail ELSE
    LET tradingVolume == ReadBytes(tradingPrice.rest, 10) IN IF ~tradingVolume.ok THEN Fail ELSE
    LET openingPrice == ReadBytes(tradingVolume.rest, 11) IN IF ~openingPrice.ok THEN Fail ELSE
    LET todaysHigh == ReadBytes(openingPrice.rest, 11) IN IF ~todaysHigh.ok THEN Fail ELSE
    LET todaysLow == ReadBytes(todaysHigh.rest, 11) IN IF ~todaysLow.ok THEN Fail ELSE
    LET accumulatedTradingVolume == ReadBytes(todaysLow.rest, 12) IN IF ~accumulatedTradingVolume.ok THEN Fail ELSE
    LET accumulatedTradingValue == ReadBytes(accumulatedTradingVolume.rest, 22) IN IF ~accumulatedTradingValue.ok THEN Fail ELSE
    LET finalAskBidTypeCode == ReadBytes(accumulatedTradingValue.rest, 1) IN IF ~finalAskBidTypeCode.ok THEN Fail ELSE
    LET lpHoldingQuantity == ReadBytes(finalAskBidTypeCode.rest, 15) IN IF ~lpHoldingQuantity.ok THEN Fail ELSE
    LET theBestAsk == ReadBytes(lpHoldingQuantity.rest, 11) IN IF ~theBestAsk.ok THEN Fail ELSE
    LET theBestBid == ReadBytes(theBestAsk.rest, 11) IN IF ~theBestBid.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(theBestBid.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber             |-> messageSequenceNumber.value,
         boardId                           |-> boardId.value,
         sessionId                         |-> sessionId.value,
         isinCode                          |-> isinCode.value,
         aDesignatedNumberForAnIssue       |-> aDesignatedNumberForAnIssue.value,
         processingTimeOfTradingSystem     |-> processingTimeOfTradingSystem.value,
         priceChangeAgainstPreviousDay     |-> priceChangeAgainstPreviousDay.value,
         aPriceChangeAgainstThePreviousDay |-> aPriceChangeAgainstThePreviousDay.value,
         tradingPrice                      |-> tradingPrice.value,
         tradingVolume                     |-> tradingVolume.value,
         openingPrice                      |-> openingPrice.value,
         todaysHigh                        |-> todaysHigh.value,
         todaysLow                         |-> todaysLow.value,
         accumulatedTradingVolume          |-> accumulatedTradingVolume.value,
         accumulatedTradingValue           |-> accumulatedTradingValue.value,
         finalAskBidTypeCode               |-> finalAskBidTypeCode.value,
         lpHoldingQuantity                 |-> lpHoldingQuantity.value,
         theBestAsk                        |-> theBestAsk.value,
         theBestBid                        |-> theBestBid.value,
         endKeyword                        |-> endKeyword.value ], endKeyword.rest)

ZeroSecuritiesOrderFilledMessage ==
    [ messageSequenceNumber             |-> [i \in 1 .. 8 |-> 0],
      boardId                           |-> [i \in 1 .. 2 |-> 0],
      sessionId                         |-> [i \in 1 .. 2 |-> 0],
      isinCode                          |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue       |-> [i \in 1 .. 6 |-> 0],
      processingTimeOfTradingSystem     |-> [i \in 1 .. 12 |-> 0],
      priceChangeAgainstPreviousDay     |-> [i \in 1 .. 1 |-> 0],
      aPriceChangeAgainstThePreviousDay |-> [i \in 1 .. 11 |-> 0],
      tradingPrice                      |-> [i \in 1 .. 11 |-> 0],
      tradingVolume                     |-> [i \in 1 .. 10 |-> 0],
      openingPrice                      |-> [i \in 1 .. 11 |-> 0],
      todaysHigh                        |-> [i \in 1 .. 11 |-> 0],
      todaysLow                         |-> [i \in 1 .. 11 |-> 0],
      accumulatedTradingVolume          |-> [i \in 1 .. 12 |-> 0],
      accumulatedTradingValue           |-> [i \in 1 .. 22 |-> 0],
      finalAskBidTypeCode               |-> [i \in 1 .. 1 |-> 0],
      lpHoldingQuantity                 |-> [i \in 1 .. 15 |-> 0],
      theBestAsk                        |-> [i \in 1 .. 11 |-> 0],
      theBestBid                        |-> [i \in 1 .. 11 |-> 0],
      endKeyword                        |-> [i \in 1 .. 1 |-> 0] ]

(* Securities Order Filled Message at zero, then each field in turn at the values it is checked at *)
CheckedSecuritiesOrderFilledMessage ==
    { ZeroSecuritiesOrderFilledMessage }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.processingTimeOfTradingSystem = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.priceChangeAgainstPreviousDay = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.aPriceChangeAgainstThePreviousDay = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.tradingPrice = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.tradingVolume = one] : one \in Sample(10) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.openingPrice = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.todaysHigh = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.todaysLow = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.accumulatedTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.accumulatedTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.finalAskBidTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.lpHoldingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.theBestAsk = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.theBestBid = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesOrderFilledMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Securities Negotiated Trade Message: 55 bytes                           *)
(***************************************************************************)

SecuritiesNegotiatedTradeMessage ==
    [ boardId                     : Sample(2),
      isinCode                    : Sample(12),
      aDesignatedNumberForAnIssue : Sample(6),
      accumulatedTradingVolume    : Sample(12),
      accumulatedTradingValue     : Sample(22),
      endKeyword                  : Sample(1) ]

EncodeSecuritiesNegotiatedTradeMessage(message) ==
    message.boardId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.accumulatedTradingVolume
        \o message.accumulatedTradingValue
        \o message.endKeyword

DecodeSecuritiesNegotiatedTradeMessage(bytes) ==
    LET boardId == ReadBytes(bytes, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(boardId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET accumulatedTradingVolume == ReadBytes(aDesignatedNumberForAnIssue.rest, 12) IN IF ~accumulatedTradingVolume.ok THEN Fail ELSE
    LET accumulatedTradingValue == ReadBytes(accumulatedTradingVolume.rest, 22) IN IF ~accumulatedTradingValue.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(accumulatedTradingValue.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ boardId                     |-> boardId.value,
         isinCode                    |-> isinCode.value,
         aDesignatedNumberForAnIssue |-> aDesignatedNumberForAnIssue.value,
         accumulatedTradingVolume    |-> accumulatedTradingVolume.value,
         accumulatedTradingValue     |-> accumulatedTradingValue.value,
         endKeyword                  |-> endKeyword.value ], endKeyword.rest)

ZeroSecuritiesNegotiatedTradeMessage ==
    [ boardId                     |-> [i \in 1 .. 2 |-> 0],
      isinCode                    |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue |-> [i \in 1 .. 6 |-> 0],
      accumulatedTradingVolume    |-> [i \in 1 .. 12 |-> 0],
      accumulatedTradingValue     |-> [i \in 1 .. 22 |-> 0],
      endKeyword                  |-> [i \in 1 .. 1 |-> 0] ]

(* Securities Negotiated Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedSecuritiesNegotiatedTradeMessage ==
    { ZeroSecuritiesNegotiatedTradeMessage }
        \cup { [ZeroSecuritiesNegotiatedTradeMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesNegotiatedTradeMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesNegotiatedTradeMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroSecuritiesNegotiatedTradeMessage EXCEPT !.accumulatedTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesNegotiatedTradeMessage EXCEPT !.accumulatedTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroSecuritiesNegotiatedTradeMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Securities Market Operation Ts Message: 63 bytes                        *)
(***************************************************************************)

SecuritiesMarketOperationTsMessage ==
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

EncodeSecuritiesMarketOperationTsMessage(message) ==
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

DecodeSecuritiesMarketOperationTsMessage(bytes) ==
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

ZeroSecuritiesMarketOperationTsMessage ==
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

(* Securities Market Operation Ts Message at zero, then each field in turn at the values it is checked at *)
CheckedSecuritiesMarketOperationTsMessage ==
    { ZeroSecuritiesMarketOperationTsMessage }
        \cup { [ZeroSecuritiesMarketOperationTsMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesMarketOperationTsMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesMarketOperationTsMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesMarketOperationTsMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesMarketOperationTsMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroSecuritiesMarketOperationTsMessage EXCEPT !.processingTimeOfTradingSystem = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesMarketOperationTsMessage EXCEPT !.boardEventId = one] : one \in Sample(3) }
        \cup { [ZeroSecuritiesMarketOperationTsMessage EXCEPT !.startTimeOfABoardEvent = one] : one \in Sample(9) }
        \cup { [ZeroSecuritiesMarketOperationTsMessage EXCEPT !.boardEventGroupCode = one] : one \in Sample(5) }
        \cup { [ZeroSecuritiesMarketOperationTsMessage EXCEPT !.tradingHaltReasonCode = one] : one \in Sample(3) }
        \cup { [ZeroSecuritiesMarketOperationTsMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Securities Determination Of Base Price Message: 62 bytes                *)
(***************************************************************************)

SecuritiesDeterminationOfBasePriceMessage ==
    [ messageSequenceNumber       : Sample(8),
      boardId                     : Sample(2),
      isinCode                    : Sample(12),
      aDesignatedNumberForAnIssue : Sample(6),
      basePrice                   : Sample(11),
      upperLimitOfBasePrice       : Sample(11),
      lowerLimitOfBasePrice       : Sample(11),
      endKeyword                  : Sample(1) ]

EncodeSecuritiesDeterminationOfBasePriceMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.basePrice
        \o message.upperLimitOfBasePrice
        \o message.lowerLimitOfBasePrice
        \o message.endKeyword

DecodeSecuritiesDeterminationOfBasePriceMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(boardId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET basePrice == ReadBytes(aDesignatedNumberForAnIssue.rest, 11) IN IF ~basePrice.ok THEN Fail ELSE
    LET upperLimitOfBasePrice == ReadBytes(basePrice.rest, 11) IN IF ~upperLimitOfBasePrice.ok THEN Fail ELSE
    LET lowerLimitOfBasePrice == ReadBytes(upperLimitOfBasePrice.rest, 11) IN IF ~lowerLimitOfBasePrice.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(lowerLimitOfBasePrice.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber       |-> messageSequenceNumber.value,
         boardId                     |-> boardId.value,
         isinCode                    |-> isinCode.value,
         aDesignatedNumberForAnIssue |-> aDesignatedNumberForAnIssue.value,
         basePrice                   |-> basePrice.value,
         upperLimitOfBasePrice       |-> upperLimitOfBasePrice.value,
         lowerLimitOfBasePrice       |-> lowerLimitOfBasePrice.value,
         endKeyword                  |-> endKeyword.value ], endKeyword.rest)

ZeroSecuritiesDeterminationOfBasePriceMessage ==
    [ messageSequenceNumber       |-> [i \in 1 .. 8 |-> 0],
      boardId                     |-> [i \in 1 .. 2 |-> 0],
      isinCode                    |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue |-> [i \in 1 .. 6 |-> 0],
      basePrice                   |-> [i \in 1 .. 11 |-> 0],
      upperLimitOfBasePrice       |-> [i \in 1 .. 11 |-> 0],
      lowerLimitOfBasePrice       |-> [i \in 1 .. 11 |-> 0],
      endKeyword                  |-> [i \in 1 .. 1 |-> 0] ]

(* Securities Determination Of Base Price Message at zero, then each field in turn at the values it is checked at *)
CheckedSecuritiesDeterminationOfBasePriceMessage ==
    { ZeroSecuritiesDeterminationOfBasePriceMessage }
        \cup { [ZeroSecuritiesDeterminationOfBasePriceMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesDeterminationOfBasePriceMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesDeterminationOfBasePriceMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesDeterminationOfBasePriceMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroSecuritiesDeterminationOfBasePriceMessage EXCEPT !.basePrice = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesDeterminationOfBasePriceMessage EXCEPT !.upperLimitOfBasePrice = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesDeterminationOfBasePriceMessage EXCEPT !.lowerLimitOfBasePrice = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesDeterminationOfBasePriceMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Securities Issue Closing Message: 107 bytes                             *)
(***************************************************************************)

SecuritiesIssueClosingMessage ==
    [ messageSequenceNumber                 : Sample(8),
      boardId                               : Sample(2),
      isinCode                              : Sample(12),
      aDesignatedNumberForAnIssue           : Sample(6),
      closingPrice                          : Sample(11),
      closingPriceTypeCode                  : Sample(1),
      filler11                              : Sample(11),
      secondFiller11                        : Sample(11),
      closingPriceWeightedStockPriceAverage : Sample(11),
      closingPriceBasePriceOfBuyIn          : Sample(11),
      closingPriceUpperLimitOfBuyIn         : Sample(11),
      closingPriceLowerLimitOfBuyIn         : Sample(11),
      endKeyword                            : Sample(1) ]

EncodeSecuritiesIssueClosingMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.closingPrice
        \o message.closingPriceTypeCode
        \o message.filler11
        \o message.secondFiller11
        \o message.closingPriceWeightedStockPriceAverage
        \o message.closingPriceBasePriceOfBuyIn
        \o message.closingPriceUpperLimitOfBuyIn
        \o message.closingPriceLowerLimitOfBuyIn
        \o message.endKeyword

DecodeSecuritiesIssueClosingMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(boardId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET closingPrice == ReadBytes(aDesignatedNumberForAnIssue.rest, 11) IN IF ~closingPrice.ok THEN Fail ELSE
    LET closingPriceTypeCode == ReadBytes(closingPrice.rest, 1) IN IF ~closingPriceTypeCode.ok THEN Fail ELSE
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
         closingPrice                          |-> closingPrice.value,
         closingPriceTypeCode                  |-> closingPriceTypeCode.value,
         filler11                              |-> filler11.value,
         secondFiller11                        |-> secondFiller11.value,
         closingPriceWeightedStockPriceAverage |-> closingPriceWeightedStockPriceAverage.value,
         closingPriceBasePriceOfBuyIn          |-> closingPriceBasePriceOfBuyIn.value,
         closingPriceUpperLimitOfBuyIn         |-> closingPriceUpperLimitOfBuyIn.value,
         closingPriceLowerLimitOfBuyIn         |-> closingPriceLowerLimitOfBuyIn.value,
         endKeyword                            |-> endKeyword.value ], endKeyword.rest)

ZeroSecuritiesIssueClosingMessage ==
    [ messageSequenceNumber                 |-> [i \in 1 .. 8 |-> 0],
      boardId                               |-> [i \in 1 .. 2 |-> 0],
      isinCode                              |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue           |-> [i \in 1 .. 6 |-> 0],
      closingPrice                          |-> [i \in 1 .. 11 |-> 0],
      closingPriceTypeCode                  |-> [i \in 1 .. 1 |-> 0],
      filler11                              |-> [i \in 1 .. 11 |-> 0],
      secondFiller11                        |-> [i \in 1 .. 11 |-> 0],
      closingPriceWeightedStockPriceAverage |-> [i \in 1 .. 11 |-> 0],
      closingPriceBasePriceOfBuyIn          |-> [i \in 1 .. 11 |-> 0],
      closingPriceUpperLimitOfBuyIn         |-> [i \in 1 .. 11 |-> 0],
      closingPriceLowerLimitOfBuyIn         |-> [i \in 1 .. 11 |-> 0],
      endKeyword                            |-> [i \in 1 .. 1 |-> 0] ]

(* Securities Issue Closing Message at zero, then each field in turn at the values it is checked at *)
CheckedSecuritiesIssueClosingMessage ==
    { ZeroSecuritiesIssueClosingMessage }
        \cup { [ZeroSecuritiesIssueClosingMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesIssueClosingMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesIssueClosingMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesIssueClosingMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroSecuritiesIssueClosingMessage EXCEPT !.closingPrice = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesIssueClosingMessage EXCEPT !.closingPriceTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesIssueClosingMessage EXCEPT !.filler11 = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesIssueClosingMessage EXCEPT !.secondFiller11 = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesIssueClosingMessage EXCEPT !.closingPriceWeightedStockPriceAverage = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesIssueClosingMessage EXCEPT !.closingPriceBasePriceOfBuyIn = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesIssueClosingMessage EXCEPT !.closingPriceUpperLimitOfBuyIn = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesIssueClosingMessage EXCEPT !.closingPriceLowerLimitOfBuyIn = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesIssueClosingMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Securities Market Operation Schedule Message: 78 bytes                  *)
(***************************************************************************)

SecuritiesMarketOperationScheduleMessage ==
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

EncodeSecuritiesMarketOperationScheduleMessage(message) ==
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

DecodeSecuritiesMarketOperationScheduleMessage(bytes) ==
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

ZeroSecuritiesMarketOperationScheduleMessage ==
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

(* Securities Market Operation Schedule Message at zero, then each field in turn at the values it is checked at *)
CheckedSecuritiesMarketOperationScheduleMessage ==
    { ZeroSecuritiesMarketOperationScheduleMessage }
        \cup { [ZeroSecuritiesMarketOperationScheduleMessage EXCEPT !.marketOperationProductId = one] : one \in Sample(3) }
        \cup { [ZeroSecuritiesMarketOperationScheduleMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesMarketOperationScheduleMessage EXCEPT !.boardEventId = one] : one \in Sample(3) }
        \cup { [ZeroSecuritiesMarketOperationScheduleMessage EXCEPT !.startTimeOfABoardEvent = one] : one \in Sample(9) }
        \cup { [ZeroSecuritiesMarketOperationScheduleMessage EXCEPT !.boardEventGroupCode = one] : one \in Sample(5) }
        \cup { [ZeroSecuritiesMarketOperationScheduleMessage EXCEPT !.sessionStartEndCode = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesMarketOperationScheduleMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesMarketOperationScheduleMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesMarketOperationScheduleMessage EXCEPT !.isinCodeOfACommonStock = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesMarketOperationScheduleMessage EXCEPT !.productId = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesMarketOperationScheduleMessage EXCEPT !.tradingHaltReasonCode = one] : one \in Sample(3) }
        \cup { [ZeroSecuritiesMarketOperationScheduleMessage EXCEPT !.tradingHaltTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesMarketOperationScheduleMessage EXCEPT !.stepApplied = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesMarketOperationScheduleMessage EXCEPT !.priceLimitRangeExpansionForBaseIssueTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesMarketOperationScheduleMessage EXCEPT !.expectedTimeOfExpandingPriceLimitRange = one] : one \in Sample(9) }
        \cup { [ZeroSecuritiesMarketOperationScheduleMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Securities Random End Message: 30 bytes                                 *)
(***************************************************************************)

SecuritiesRandomEndMessage ==
    [ messageSequenceNumber       : Sample(8),
      boardId                     : Sample(2),
      isinCode                    : Sample(12),
      aDesignatedNumberForAnIssue : Sample(6),
      randomEndTriggerCode        : Sample(1),
      endKeyword                  : Sample(1) ]

EncodeSecuritiesRandomEndMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.randomEndTriggerCode
        \o message.endKeyword

DecodeSecuritiesRandomEndMessage(bytes) ==
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

ZeroSecuritiesRandomEndMessage ==
    [ messageSequenceNumber       |-> [i \in 1 .. 8 |-> 0],
      boardId                     |-> [i \in 1 .. 2 |-> 0],
      isinCode                    |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue |-> [i \in 1 .. 6 |-> 0],
      randomEndTriggerCode        |-> [i \in 1 .. 1 |-> 0],
      endKeyword                  |-> [i \in 1 .. 1 |-> 0] ]

(* Securities Random End Message at zero, then each field in turn at the values it is checked at *)
CheckedSecuritiesRandomEndMessage ==
    { ZeroSecuritiesRandomEndMessage }
        \cup { [ZeroSecuritiesRandomEndMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesRandomEndMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesRandomEndMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesRandomEndMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroSecuritiesRandomEndMessage EXCEPT !.randomEndTriggerCode = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesRandomEndMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Securities Triggering Vi Message: 111 bytes                             *)
(***************************************************************************)

SecuritiesTriggeringViMessage ==
    [ messageSequenceNumber            : Sample(8),
      boardId                          : Sample(2),
      isinCode                         : Sample(12),
      aDesignatedNumberForAnIssue      : Sample(6),
      processingTimeOfTradingSystem    : Sample(12),
      theTimeEndingVi                  : Sample(9),
      viStatusCode                     : Sample(1),
      viTypeCode                       : Sample(1),
      aBasePriceToTriggerStaticVi      : Sample(11),
      aBasePriceToTriggerDynamicVi     : Sample(11),
      viTriggeringPrice                : Sample(11),
      disparateRatioToTriggerStaticVi  : Sample(13),
      disparateRatioToTriggerDynamicVi : Sample(13),
      endKeyword                       : Sample(1) ]

EncodeSecuritiesTriggeringViMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.processingTimeOfTradingSystem
        \o message.theTimeEndingVi
        \o message.viStatusCode
        \o message.viTypeCode
        \o message.aBasePriceToTriggerStaticVi
        \o message.aBasePriceToTriggerDynamicVi
        \o message.viTriggeringPrice
        \o message.disparateRatioToTriggerStaticVi
        \o message.disparateRatioToTriggerDynamicVi
        \o message.endKeyword

DecodeSecuritiesTriggeringViMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(boardId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET processingTimeOfTradingSystem == ReadBytes(aDesignatedNumberForAnIssue.rest, 12) IN IF ~processingTimeOfTradingSystem.ok THEN Fail ELSE
    LET theTimeEndingVi == ReadBytes(processingTimeOfTradingSystem.rest, 9) IN IF ~theTimeEndingVi.ok THEN Fail ELSE
    LET viStatusCode == ReadBytes(theTimeEndingVi.rest, 1) IN IF ~viStatusCode.ok THEN Fail ELSE
    LET viTypeCode == ReadBytes(viStatusCode.rest, 1) IN IF ~viTypeCode.ok THEN Fail ELSE
    LET aBasePriceToTriggerStaticVi == ReadBytes(viTypeCode.rest, 11) IN IF ~aBasePriceToTriggerStaticVi.ok THEN Fail ELSE
    LET aBasePriceToTriggerDynamicVi == ReadBytes(aBasePriceToTriggerStaticVi.rest, 11) IN IF ~aBasePriceToTriggerDynamicVi.ok THEN Fail ELSE
    LET viTriggeringPrice == ReadBytes(aBasePriceToTriggerDynamicVi.rest, 11) IN IF ~viTriggeringPrice.ok THEN Fail ELSE
    LET disparateRatioToTriggerStaticVi == ReadBytes(viTriggeringPrice.rest, 13) IN IF ~disparateRatioToTriggerStaticVi.ok THEN Fail ELSE
    LET disparateRatioToTriggerDynamicVi == ReadBytes(disparateRatioToTriggerStaticVi.rest, 13) IN IF ~disparateRatioToTriggerDynamicVi.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(disparateRatioToTriggerDynamicVi.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber            |-> messageSequenceNumber.value,
         boardId                          |-> boardId.value,
         isinCode                         |-> isinCode.value,
         aDesignatedNumberForAnIssue      |-> aDesignatedNumberForAnIssue.value,
         processingTimeOfTradingSystem    |-> processingTimeOfTradingSystem.value,
         theTimeEndingVi                  |-> theTimeEndingVi.value,
         viStatusCode                     |-> viStatusCode.value,
         viTypeCode                       |-> viTypeCode.value,
         aBasePriceToTriggerStaticVi      |-> aBasePriceToTriggerStaticVi.value,
         aBasePriceToTriggerDynamicVi     |-> aBasePriceToTriggerDynamicVi.value,
         viTriggeringPrice                |-> viTriggeringPrice.value,
         disparateRatioToTriggerStaticVi  |-> disparateRatioToTriggerStaticVi.value,
         disparateRatioToTriggerDynamicVi |-> disparateRatioToTriggerDynamicVi.value,
         endKeyword                       |-> endKeyword.value ], endKeyword.rest)

ZeroSecuritiesTriggeringViMessage ==
    [ messageSequenceNumber            |-> [i \in 1 .. 8 |-> 0],
      boardId                          |-> [i \in 1 .. 2 |-> 0],
      isinCode                         |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue      |-> [i \in 1 .. 6 |-> 0],
      processingTimeOfTradingSystem    |-> [i \in 1 .. 12 |-> 0],
      theTimeEndingVi                  |-> [i \in 1 .. 9 |-> 0],
      viStatusCode                     |-> [i \in 1 .. 1 |-> 0],
      viTypeCode                       |-> [i \in 1 .. 1 |-> 0],
      aBasePriceToTriggerStaticVi      |-> [i \in 1 .. 11 |-> 0],
      aBasePriceToTriggerDynamicVi     |-> [i \in 1 .. 11 |-> 0],
      viTriggeringPrice                |-> [i \in 1 .. 11 |-> 0],
      disparateRatioToTriggerStaticVi  |-> [i \in 1 .. 13 |-> 0],
      disparateRatioToTriggerDynamicVi |-> [i \in 1 .. 13 |-> 0],
      endKeyword                       |-> [i \in 1 .. 1 |-> 0] ]

(* Securities Triggering Vi Message at zero, then each field in turn at the values it is checked at *)
CheckedSecuritiesTriggeringViMessage ==
    { ZeroSecuritiesTriggeringViMessage }
        \cup { [ZeroSecuritiesTriggeringViMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesTriggeringViMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesTriggeringViMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesTriggeringViMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroSecuritiesTriggeringViMessage EXCEPT !.processingTimeOfTradingSystem = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesTriggeringViMessage EXCEPT !.theTimeEndingVi = one] : one \in Sample(9) }
        \cup { [ZeroSecuritiesTriggeringViMessage EXCEPT !.viStatusCode = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesTriggeringViMessage EXCEPT !.viTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesTriggeringViMessage EXCEPT !.aBasePriceToTriggerStaticVi = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesTriggeringViMessage EXCEPT !.aBasePriceToTriggerDynamicVi = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesTriggeringViMessage EXCEPT !.viTriggeringPrice = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesTriggeringViMessage EXCEPT !.disparateRatioToTriggerStaticVi = one] : one \in Sample(13) }
        \cup { [ZeroSecuritiesTriggeringViMessage EXCEPT !.disparateRatioToTriggerDynamicVi = one] : one \in Sample(13) }
        \cup { [ZeroSecuritiesTriggeringViMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Securities Quantity Allocation Message: 40 bytes                        *)
(***************************************************************************)

SecuritiesQuantityAllocationMessage ==
    [ messageSequenceNumber       : Sample(8),
      boardId                     : Sample(2),
      isinCode                    : Sample(12),
      aDesignatedNumberForAnIssue : Sample(6),
      startEndOfAllocation        : Sample(1),
      allocationTypeCode          : Sample(1),
      timeWhenAllocationEnded     : Sample(9),
      endKeyword                  : Sample(1) ]

EncodeSecuritiesQuantityAllocationMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.startEndOfAllocation
        \o message.allocationTypeCode
        \o message.timeWhenAllocationEnded
        \o message.endKeyword

DecodeSecuritiesQuantityAllocationMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(boardId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET startEndOfAllocation == ReadBytes(aDesignatedNumberForAnIssue.rest, 1) IN IF ~startEndOfAllocation.ok THEN Fail ELSE
    LET allocationTypeCode == ReadBytes(startEndOfAllocation.rest, 1) IN IF ~allocationTypeCode.ok THEN Fail ELSE
    LET timeWhenAllocationEnded == ReadBytes(allocationTypeCode.rest, 9) IN IF ~timeWhenAllocationEnded.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(timeWhenAllocationEnded.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber       |-> messageSequenceNumber.value,
         boardId                     |-> boardId.value,
         isinCode                    |-> isinCode.value,
         aDesignatedNumberForAnIssue |-> aDesignatedNumberForAnIssue.value,
         startEndOfAllocation        |-> startEndOfAllocation.value,
         allocationTypeCode          |-> allocationTypeCode.value,
         timeWhenAllocationEnded     |-> timeWhenAllocationEnded.value,
         endKeyword                  |-> endKeyword.value ], endKeyword.rest)

ZeroSecuritiesQuantityAllocationMessage ==
    [ messageSequenceNumber       |-> [i \in 1 .. 8 |-> 0],
      boardId                     |-> [i \in 1 .. 2 |-> 0],
      isinCode                    |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue |-> [i \in 1 .. 6 |-> 0],
      startEndOfAllocation        |-> [i \in 1 .. 1 |-> 0],
      allocationTypeCode          |-> [i \in 1 .. 1 |-> 0],
      timeWhenAllocationEnded     |-> [i \in 1 .. 9 |-> 0],
      endKeyword                  |-> [i \in 1 .. 1 |-> 0] ]

(* Securities Quantity Allocation Message at zero, then each field in turn at the values it is checked at *)
CheckedSecuritiesQuantityAllocationMessage ==
    { ZeroSecuritiesQuantityAllocationMessage }
        \cup { [ZeroSecuritiesQuantityAllocationMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesQuantityAllocationMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesQuantityAllocationMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesQuantityAllocationMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroSecuritiesQuantityAllocationMessage EXCEPT !.startEndOfAllocation = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesQuantityAllocationMessage EXCEPT !.allocationTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesQuantityAllocationMessage EXCEPT !.timeWhenAllocationEnded = one] : one \in Sample(9) }
        \cup { [ZeroSecuritiesQuantityAllocationMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Securities Member Firm Sanctions Message: 41 bytes                      *)
(***************************************************************************)

SecuritiesMemberFirmSanctionsMessage ==
    [ isinCode                         : Sample(12),
      aDesignatedNumberForAnIssue      : Sample(6),
      disclosingDataTypeCode           : Sample(3),
      disclosureTime                   : Sample(9),
      memberNumber                     : Sample(5),
      memberFirmTrustPrincipalTypeCode : Sample(5),
      endKeyword                       : Sample(1) ]

EncodeSecuritiesMemberFirmSanctionsMessage(message) ==
    message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.disclosingDataTypeCode
        \o message.disclosureTime
        \o message.memberNumber
        \o message.memberFirmTrustPrincipalTypeCode
        \o message.endKeyword

DecodeSecuritiesMemberFirmSanctionsMessage(bytes) ==
    LET isinCode == ReadBytes(bytes, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET disclosingDataTypeCode == ReadBytes(aDesignatedNumberForAnIssue.rest, 3) IN IF ~disclosingDataTypeCode.ok THEN Fail ELSE
    LET disclosureTime == ReadBytes(disclosingDataTypeCode.rest, 9) IN IF ~disclosureTime.ok THEN Fail ELSE
    LET memberNumber == ReadBytes(disclosureTime.rest, 5) IN IF ~memberNumber.ok THEN Fail ELSE
    LET memberFirmTrustPrincipalTypeCode == ReadBytes(memberNumber.rest, 5) IN IF ~memberFirmTrustPrincipalTypeCode.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(memberFirmTrustPrincipalTypeCode.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ isinCode                         |-> isinCode.value,
         aDesignatedNumberForAnIssue      |-> aDesignatedNumberForAnIssue.value,
         disclosingDataTypeCode           |-> disclosingDataTypeCode.value,
         disclosureTime                   |-> disclosureTime.value,
         memberNumber                     |-> memberNumber.value,
         memberFirmTrustPrincipalTypeCode |-> memberFirmTrustPrincipalTypeCode.value,
         endKeyword                       |-> endKeyword.value ], endKeyword.rest)

ZeroSecuritiesMemberFirmSanctionsMessage ==
    [ isinCode                         |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue      |-> [i \in 1 .. 6 |-> 0],
      disclosingDataTypeCode           |-> [i \in 1 .. 3 |-> 0],
      disclosureTime                   |-> [i \in 1 .. 9 |-> 0],
      memberNumber                     |-> [i \in 1 .. 5 |-> 0],
      memberFirmTrustPrincipalTypeCode |-> [i \in 1 .. 5 |-> 0],
      endKeyword                       |-> [i \in 1 .. 1 |-> 0] ]

(* Securities Member Firm Sanctions Message at zero, then each field in turn at the values it is checked at *)
CheckedSecuritiesMemberFirmSanctionsMessage ==
    { ZeroSecuritiesMemberFirmSanctionsMessage }
        \cup { [ZeroSecuritiesMemberFirmSanctionsMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesMemberFirmSanctionsMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroSecuritiesMemberFirmSanctionsMessage EXCEPT !.disclosingDataTypeCode = one] : one \in Sample(3) }
        \cup { [ZeroSecuritiesMemberFirmSanctionsMessage EXCEPT !.disclosureTime = one] : one \in Sample(9) }
        \cup { [ZeroSecuritiesMemberFirmSanctionsMessage EXCEPT !.memberNumber = one] : one \in Sample(5) }
        \cup { [ZeroSecuritiesMemberFirmSanctionsMessage EXCEPT !.memberFirmTrustPrincipalTypeCode = one] : one \in Sample(5) }
        \cup { [ZeroSecuritiesMemberFirmSanctionsMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Securities Equities Changes Of Batch Data Message: 124 bytes            *)
(***************************************************************************)

SecuritiesEquitiesChangesOfBatchDataMessage ==
    [ boardId                                                           : Sample(2),
      isinCode                                                          : Sample(12),
      aDesignatedNumberForAnIssue                                       : Sample(6),
      disclosingDataTypeCode                                            : Sample(3),
      basePrice                                                         : Sample(11),
      upperLimitPrice                                                   : Sample(11),
      lowerLimitPrice                                                   : Sample(11),
      appraisedPrice                                                    : Sample(11),
      highestOrderPrice                                                 : Sample(11),
      lowestOrderPrice                                                  : Sample(11),
      typeCodeForAnIssueOfWhichBasePriceIsSettledWithATodaysSinglePrice : Sample(1),
      rightsTypeCode                                                    : Sample(2),
      parValueTypeCode                                                  : Sample(2),
      lotSizes                                                          : Sample(11),
      numberOfListedShares                                              : Sample(16),
      designation                                                       : Sample(1),
      closingPriceTradingInThePreOpeningMarket                          : Sample(1),
      endKeyword                                                        : Sample(1) ]

EncodeSecuritiesEquitiesChangesOfBatchDataMessage(message) ==
    message.boardId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.disclosingDataTypeCode
        \o message.basePrice
        \o message.upperLimitPrice
        \o message.lowerLimitPrice
        \o message.appraisedPrice
        \o message.highestOrderPrice
        \o message.lowestOrderPrice
        \o message.typeCodeForAnIssueOfWhichBasePriceIsSettledWithATodaysSinglePrice
        \o message.rightsTypeCode
        \o message.parValueTypeCode
        \o message.lotSizes
        \o message.numberOfListedShares
        \o message.designation
        \o message.closingPriceTradingInThePreOpeningMarket
        \o message.endKeyword

DecodeSecuritiesEquitiesChangesOfBatchDataMessage(bytes) ==
    LET boardId == ReadBytes(bytes, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(boardId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET disclosingDataTypeCode == ReadBytes(aDesignatedNumberForAnIssue.rest, 3) IN IF ~disclosingDataTypeCode.ok THEN Fail ELSE
    LET basePrice == ReadBytes(disclosingDataTypeCode.rest, 11) IN IF ~basePrice.ok THEN Fail ELSE
    LET upperLimitPrice == ReadBytes(basePrice.rest, 11) IN IF ~upperLimitPrice.ok THEN Fail ELSE
    LET lowerLimitPrice == ReadBytes(upperLimitPrice.rest, 11) IN IF ~lowerLimitPrice.ok THEN Fail ELSE
    LET appraisedPrice == ReadBytes(lowerLimitPrice.rest, 11) IN IF ~appraisedPrice.ok THEN Fail ELSE
    LET highestOrderPrice == ReadBytes(appraisedPrice.rest, 11) IN IF ~highestOrderPrice.ok THEN Fail ELSE
    LET lowestOrderPrice == ReadBytes(highestOrderPrice.rest, 11) IN IF ~lowestOrderPrice.ok THEN Fail ELSE
    LET typeCodeForAnIssueOfWhichBasePriceIsSettledWithATodaysSinglePrice == ReadBytes(lowestOrderPrice.rest, 1) IN IF ~typeCodeForAnIssueOfWhichBasePriceIsSettledWithATodaysSinglePrice.ok THEN Fail ELSE
    LET rightsTypeCode == ReadBytes(typeCodeForAnIssueOfWhichBasePriceIsSettledWithATodaysSinglePrice.rest, 2) IN IF ~rightsTypeCode.ok THEN Fail ELSE
    LET parValueTypeCode == ReadBytes(rightsTypeCode.rest, 2) IN IF ~parValueTypeCode.ok THEN Fail ELSE
    LET lotSizes == ReadBytes(parValueTypeCode.rest, 11) IN IF ~lotSizes.ok THEN Fail ELSE
    LET numberOfListedShares == ReadBytes(lotSizes.rest, 16) IN IF ~numberOfListedShares.ok THEN Fail ELSE
    LET designation == ReadBytes(numberOfListedShares.rest, 1) IN IF ~designation.ok THEN Fail ELSE
    LET closingPriceTradingInThePreOpeningMarket == ReadBytes(designation.rest, 1) IN IF ~closingPriceTradingInThePreOpeningMarket.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(closingPriceTradingInThePreOpeningMarket.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ boardId                                                           |-> boardId.value,
         isinCode                                                          |-> isinCode.value,
         aDesignatedNumberForAnIssue                                       |-> aDesignatedNumberForAnIssue.value,
         disclosingDataTypeCode                                            |-> disclosingDataTypeCode.value,
         basePrice                                                         |-> basePrice.value,
         upperLimitPrice                                                   |-> upperLimitPrice.value,
         lowerLimitPrice                                                   |-> lowerLimitPrice.value,
         appraisedPrice                                                    |-> appraisedPrice.value,
         highestOrderPrice                                                 |-> highestOrderPrice.value,
         lowestOrderPrice                                                  |-> lowestOrderPrice.value,
         typeCodeForAnIssueOfWhichBasePriceIsSettledWithATodaysSinglePrice |-> typeCodeForAnIssueOfWhichBasePriceIsSettledWithATodaysSinglePrice.value,
         rightsTypeCode                                                    |-> rightsTypeCode.value,
         parValueTypeCode                                                  |-> parValueTypeCode.value,
         lotSizes                                                          |-> lotSizes.value,
         numberOfListedShares                                              |-> numberOfListedShares.value,
         designation                                                       |-> designation.value,
         closingPriceTradingInThePreOpeningMarket                          |-> closingPriceTradingInThePreOpeningMarket.value,
         endKeyword                                                        |-> endKeyword.value ], endKeyword.rest)

ZeroSecuritiesEquitiesChangesOfBatchDataMessage ==
    [ boardId                                                           |-> [i \in 1 .. 2 |-> 0],
      isinCode                                                          |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue                                       |-> [i \in 1 .. 6 |-> 0],
      disclosingDataTypeCode                                            |-> [i \in 1 .. 3 |-> 0],
      basePrice                                                         |-> [i \in 1 .. 11 |-> 0],
      upperLimitPrice                                                   |-> [i \in 1 .. 11 |-> 0],
      lowerLimitPrice                                                   |-> [i \in 1 .. 11 |-> 0],
      appraisedPrice                                                    |-> [i \in 1 .. 11 |-> 0],
      highestOrderPrice                                                 |-> [i \in 1 .. 11 |-> 0],
      lowestOrderPrice                                                  |-> [i \in 1 .. 11 |-> 0],
      typeCodeForAnIssueOfWhichBasePriceIsSettledWithATodaysSinglePrice |-> [i \in 1 .. 1 |-> 0],
      rightsTypeCode                                                    |-> [i \in 1 .. 2 |-> 0],
      parValueTypeCode                                                  |-> [i \in 1 .. 2 |-> 0],
      lotSizes                                                          |-> [i \in 1 .. 11 |-> 0],
      numberOfListedShares                                              |-> [i \in 1 .. 16 |-> 0],
      designation                                                       |-> [i \in 1 .. 1 |-> 0],
      closingPriceTradingInThePreOpeningMarket                          |-> [i \in 1 .. 1 |-> 0],
      endKeyword                                                        |-> [i \in 1 .. 1 |-> 0] ]

(* Securities Equities Changes Of Batch Data Message at zero, then each field in turn at the values it is checked at *)
CheckedSecuritiesEquitiesChangesOfBatchDataMessage ==
    { ZeroSecuritiesEquitiesChangesOfBatchDataMessage }
        \cup { [ZeroSecuritiesEquitiesChangesOfBatchDataMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesEquitiesChangesOfBatchDataMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesEquitiesChangesOfBatchDataMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroSecuritiesEquitiesChangesOfBatchDataMessage EXCEPT !.disclosingDataTypeCode = one] : one \in Sample(3) }
        \cup { [ZeroSecuritiesEquitiesChangesOfBatchDataMessage EXCEPT !.basePrice = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesEquitiesChangesOfBatchDataMessage EXCEPT !.upperLimitPrice = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesEquitiesChangesOfBatchDataMessage EXCEPT !.lowerLimitPrice = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesEquitiesChangesOfBatchDataMessage EXCEPT !.appraisedPrice = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesEquitiesChangesOfBatchDataMessage EXCEPT !.highestOrderPrice = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesEquitiesChangesOfBatchDataMessage EXCEPT !.lowestOrderPrice = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesEquitiesChangesOfBatchDataMessage EXCEPT !.typeCodeForAnIssueOfWhichBasePriceIsSettledWithATodaysSinglePrice = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquitiesChangesOfBatchDataMessage EXCEPT !.rightsTypeCode = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesEquitiesChangesOfBatchDataMessage EXCEPT !.parValueTypeCode = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesEquitiesChangesOfBatchDataMessage EXCEPT !.lotSizes = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesEquitiesChangesOfBatchDataMessage EXCEPT !.numberOfListedShares = one] : one \in Sample(16) }
        \cup { [ZeroSecuritiesEquitiesChangesOfBatchDataMessage EXCEPT !.designation = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquitiesChangesOfBatchDataMessage EXCEPT !.closingPriceTradingInThePreOpeningMarket = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEquitiesChangesOfBatchDataMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Securities Group Order Acceptance Halt Message: 28 bytes                *)
(***************************************************************************)

SecuritiesGroupOrderAcceptanceHaltMessage ==
    [ marketId                 : Sample(3),
      meGroupNumber            : Sample(5),
      boardId                  : Sample(2),
      boardEventId             : Sample(3),
      boardEventGroupCode      : Sample(5),
      boardEventProcessingTime : Sample(9),
      endKeyword               : Sample(1) ]

EncodeSecuritiesGroupOrderAcceptanceHaltMessage(message) ==
    message.marketId
        \o message.meGroupNumber
        \o message.boardId
        \o message.boardEventId
        \o message.boardEventGroupCode
        \o message.boardEventProcessingTime
        \o message.endKeyword

DecodeSecuritiesGroupOrderAcceptanceHaltMessage(bytes) ==
    LET marketId == ReadBytes(bytes, 3) IN IF ~marketId.ok THEN Fail ELSE
    LET meGroupNumber == ReadBytes(marketId.rest, 5) IN IF ~meGroupNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(meGroupNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET boardEventId == ReadBytes(boardId.rest, 3) IN IF ~boardEventId.ok THEN Fail ELSE
    LET boardEventGroupCode == ReadBytes(boardEventId.rest, 5) IN IF ~boardEventGroupCode.ok THEN Fail ELSE
    LET boardEventProcessingTime == ReadBytes(boardEventGroupCode.rest, 9) IN IF ~boardEventProcessingTime.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(boardEventProcessingTime.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ marketId                 |-> marketId.value,
         meGroupNumber            |-> meGroupNumber.value,
         boardId                  |-> boardId.value,
         boardEventId             |-> boardEventId.value,
         boardEventGroupCode      |-> boardEventGroupCode.value,
         boardEventProcessingTime |-> boardEventProcessingTime.value,
         endKeyword               |-> endKeyword.value ], endKeyword.rest)

ZeroSecuritiesGroupOrderAcceptanceHaltMessage ==
    [ marketId                 |-> [i \in 1 .. 3 |-> 0],
      meGroupNumber            |-> [i \in 1 .. 5 |-> 0],
      boardId                  |-> [i \in 1 .. 2 |-> 0],
      boardEventId             |-> [i \in 1 .. 3 |-> 0],
      boardEventGroupCode      |-> [i \in 1 .. 5 |-> 0],
      boardEventProcessingTime |-> [i \in 1 .. 9 |-> 0],
      endKeyword               |-> [i \in 1 .. 1 |-> 0] ]

(* Securities Group Order Acceptance Halt Message at zero, then each field in turn at the values it is checked at *)
CheckedSecuritiesGroupOrderAcceptanceHaltMessage ==
    { ZeroSecuritiesGroupOrderAcceptanceHaltMessage }
        \cup { [ZeroSecuritiesGroupOrderAcceptanceHaltMessage EXCEPT !.marketId = one] : one \in Sample(3) }
        \cup { [ZeroSecuritiesGroupOrderAcceptanceHaltMessage EXCEPT !.meGroupNumber = one] : one \in Sample(5) }
        \cup { [ZeroSecuritiesGroupOrderAcceptanceHaltMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesGroupOrderAcceptanceHaltMessage EXCEPT !.boardEventId = one] : one \in Sample(3) }
        \cup { [ZeroSecuritiesGroupOrderAcceptanceHaltMessage EXCEPT !.boardEventGroupCode = one] : one \in Sample(5) }
        \cup { [ZeroSecuritiesGroupOrderAcceptanceHaltMessage EXCEPT !.boardEventProcessingTime = one] : one \in Sample(9) }
        \cup { [ZeroSecuritiesGroupOrderAcceptanceHaltMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

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
(* Securities Mm Lp Information Message: 192 bytes                         *)
(***************************************************************************)

SecuritiesMmLpInformationMessage ==
    [ messageSequenceNumber                  : Sample(8),
      isinCode                               : Sample(12),
      marketParticipantNumber                : Sample(5),
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
    LET lpStartDate == ReadBytes(marketParticipantNumber.rest, 8) IN IF ~lpStartDate.ok THEN Fail ELSE
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
(* Securities Elw Batch Data Message: 925 bytes                            *)
(***************************************************************************)

SecuritiesElwBatchDataMessage ==
    [ messageSequenceNumber                        : Sample(8),
      isinCode                                     : Sample(12),
      aDesignatedNumberForAnIssue                  : Sample(6),
      nameOfIssuer                                 : Sample(80),
      englishNameOfIssuer                          : Sample(80),
      numbersOfIssuer                              : Sample(5),
      marketId1ForUnderlyingAssetsIndices          : Sample(3),
      marketId2ForUnderlyingAssetsIndices          : Sample(3),
      marketId3ForUnderlyingAssetsIndices          : Sample(3),
      marketId4ForUnderlyingAssetsIndices          : Sample(3),
      marketId5ForUnderlyingAssetsIndices          : Sample(3),
      underlyingAssetTypeCode1                     : Sample(12),
      underlyingAssetTypeCode2                     : Sample(12),
      underlyingAssetTypeCode3                     : Sample(12),
      underlyingAssetTypeCode4                     : Sample(12),
      underlyingAssetTypeCode5                     : Sample(12),
      underlyingAssetCompositionRatio1             : Sample(13),
      underlyingAssetCompositionRatio2             : Sample(13),
      underlyingAssetCompositionRatio3             : Sample(13),
      underlyingAssetCompositionRatio4             : Sample(13),
      underlyingAssetCompositionRatio5             : Sample(13),
      indexId                                      : Sample(6),
      optionRightsTypeCode                         : Sample(1),
      rightsExecutionTypeCode                      : Sample(1),
      paymentMethods                               : Sample(1),
      lastTradingDate                              : Sample(8),
      elwPaymentDate                               : Sample(8),
      basePriceOfUnderlyingAsset                   : Sample(13),
      detailsOfRights                              : Sample(200),
      elwConversionRate                            : Sample(13),
      elwGuaranteedRateForPriceIncreases           : Sample(10),
      elwGuaranteedRateForPriceDecreases           : Sample(10),
      elwFixedPayment                              : Sample(22),
      elwPaymentAgent                              : Sample(80),
      calculationMethodsOfAppraisedPriceAtMaturity : Sample(200),
      elwRightsTypeCode                            : Sample(1),
      elwLpHoldingQuantity                         : Sample(15),
      filler4                                      : Sample(4),
      endKeyword                                   : Sample(1) ]

EncodeSecuritiesElwBatchDataMessage(message) ==
    message.messageSequenceNumber
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.nameOfIssuer
        \o message.englishNameOfIssuer
        \o message.numbersOfIssuer
        \o message.marketId1ForUnderlyingAssetsIndices
        \o message.marketId2ForUnderlyingAssetsIndices
        \o message.marketId3ForUnderlyingAssetsIndices
        \o message.marketId4ForUnderlyingAssetsIndices
        \o message.marketId5ForUnderlyingAssetsIndices
        \o message.underlyingAssetTypeCode1
        \o message.underlyingAssetTypeCode2
        \o message.underlyingAssetTypeCode3
        \o message.underlyingAssetTypeCode4
        \o message.underlyingAssetTypeCode5
        \o message.underlyingAssetCompositionRatio1
        \o message.underlyingAssetCompositionRatio2
        \o message.underlyingAssetCompositionRatio3
        \o message.underlyingAssetCompositionRatio4
        \o message.underlyingAssetCompositionRatio5
        \o message.indexId
        \o message.optionRightsTypeCode
        \o message.rightsExecutionTypeCode
        \o message.paymentMethods
        \o message.lastTradingDate
        \o message.elwPaymentDate
        \o message.basePriceOfUnderlyingAsset
        \o message.detailsOfRights
        \o message.elwConversionRate
        \o message.elwGuaranteedRateForPriceIncreases
        \o message.elwGuaranteedRateForPriceDecreases
        \o message.elwFixedPayment
        \o message.elwPaymentAgent
        \o message.calculationMethodsOfAppraisedPriceAtMaturity
        \o message.elwRightsTypeCode
        \o message.elwLpHoldingQuantity
        \o message.filler4
        \o message.endKeyword

DecodeSecuritiesElwBatchDataMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET isinCode == ReadBytes(messageSequenceNumber.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET nameOfIssuer == ReadBytes(aDesignatedNumberForAnIssue.rest, 80) IN IF ~nameOfIssuer.ok THEN Fail ELSE
    LET englishNameOfIssuer == ReadBytes(nameOfIssuer.rest, 80) IN IF ~englishNameOfIssuer.ok THEN Fail ELSE
    LET numbersOfIssuer == ReadBytes(englishNameOfIssuer.rest, 5) IN IF ~numbersOfIssuer.ok THEN Fail ELSE
    LET marketId1ForUnderlyingAssetsIndices == ReadBytes(numbersOfIssuer.rest, 3) IN IF ~marketId1ForUnderlyingAssetsIndices.ok THEN Fail ELSE
    LET marketId2ForUnderlyingAssetsIndices == ReadBytes(marketId1ForUnderlyingAssetsIndices.rest, 3) IN IF ~marketId2ForUnderlyingAssetsIndices.ok THEN Fail ELSE
    LET marketId3ForUnderlyingAssetsIndices == ReadBytes(marketId2ForUnderlyingAssetsIndices.rest, 3) IN IF ~marketId3ForUnderlyingAssetsIndices.ok THEN Fail ELSE
    LET marketId4ForUnderlyingAssetsIndices == ReadBytes(marketId3ForUnderlyingAssetsIndices.rest, 3) IN IF ~marketId4ForUnderlyingAssetsIndices.ok THEN Fail ELSE
    LET marketId5ForUnderlyingAssetsIndices == ReadBytes(marketId4ForUnderlyingAssetsIndices.rest, 3) IN IF ~marketId5ForUnderlyingAssetsIndices.ok THEN Fail ELSE
    LET underlyingAssetTypeCode1 == ReadBytes(marketId5ForUnderlyingAssetsIndices.rest, 12) IN IF ~underlyingAssetTypeCode1.ok THEN Fail ELSE
    LET underlyingAssetTypeCode2 == ReadBytes(underlyingAssetTypeCode1.rest, 12) IN IF ~underlyingAssetTypeCode2.ok THEN Fail ELSE
    LET underlyingAssetTypeCode3 == ReadBytes(underlyingAssetTypeCode2.rest, 12) IN IF ~underlyingAssetTypeCode3.ok THEN Fail ELSE
    LET underlyingAssetTypeCode4 == ReadBytes(underlyingAssetTypeCode3.rest, 12) IN IF ~underlyingAssetTypeCode4.ok THEN Fail ELSE
    LET underlyingAssetTypeCode5 == ReadBytes(underlyingAssetTypeCode4.rest, 12) IN IF ~underlyingAssetTypeCode5.ok THEN Fail ELSE
    LET underlyingAssetCompositionRatio1 == ReadBytes(underlyingAssetTypeCode5.rest, 13) IN IF ~underlyingAssetCompositionRatio1.ok THEN Fail ELSE
    LET underlyingAssetCompositionRatio2 == ReadBytes(underlyingAssetCompositionRatio1.rest, 13) IN IF ~underlyingAssetCompositionRatio2.ok THEN Fail ELSE
    LET underlyingAssetCompositionRatio3 == ReadBytes(underlyingAssetCompositionRatio2.rest, 13) IN IF ~underlyingAssetCompositionRatio3.ok THEN Fail ELSE
    LET underlyingAssetCompositionRatio4 == ReadBytes(underlyingAssetCompositionRatio3.rest, 13) IN IF ~underlyingAssetCompositionRatio4.ok THEN Fail ELSE
    LET underlyingAssetCompositionRatio5 == ReadBytes(underlyingAssetCompositionRatio4.rest, 13) IN IF ~underlyingAssetCompositionRatio5.ok THEN Fail ELSE
    LET indexId == ReadBytes(underlyingAssetCompositionRatio5.rest, 6) IN IF ~indexId.ok THEN Fail ELSE
    LET optionRightsTypeCode == ReadBytes(indexId.rest, 1) IN IF ~optionRightsTypeCode.ok THEN Fail ELSE
    LET rightsExecutionTypeCode == ReadBytes(optionRightsTypeCode.rest, 1) IN IF ~rightsExecutionTypeCode.ok THEN Fail ELSE
    LET paymentMethods == ReadBytes(rightsExecutionTypeCode.rest, 1) IN IF ~paymentMethods.ok THEN Fail ELSE
    LET lastTradingDate == ReadBytes(paymentMethods.rest, 8) IN IF ~lastTradingDate.ok THEN Fail ELSE
    LET elwPaymentDate == ReadBytes(lastTradingDate.rest, 8) IN IF ~elwPaymentDate.ok THEN Fail ELSE
    LET basePriceOfUnderlyingAsset == ReadBytes(elwPaymentDate.rest, 13) IN IF ~basePriceOfUnderlyingAsset.ok THEN Fail ELSE
    LET detailsOfRights == ReadBytes(basePriceOfUnderlyingAsset.rest, 200) IN IF ~detailsOfRights.ok THEN Fail ELSE
    LET elwConversionRate == ReadBytes(detailsOfRights.rest, 13) IN IF ~elwConversionRate.ok THEN Fail ELSE
    LET elwGuaranteedRateForPriceIncreases == ReadBytes(elwConversionRate.rest, 10) IN IF ~elwGuaranteedRateForPriceIncreases.ok THEN Fail ELSE
    LET elwGuaranteedRateForPriceDecreases == ReadBytes(elwGuaranteedRateForPriceIncreases.rest, 10) IN IF ~elwGuaranteedRateForPriceDecreases.ok THEN Fail ELSE
    LET elwFixedPayment == ReadBytes(elwGuaranteedRateForPriceDecreases.rest, 22) IN IF ~elwFixedPayment.ok THEN Fail ELSE
    LET elwPaymentAgent == ReadBytes(elwFixedPayment.rest, 80) IN IF ~elwPaymentAgent.ok THEN Fail ELSE
    LET calculationMethodsOfAppraisedPriceAtMaturity == ReadBytes(elwPaymentAgent.rest, 200) IN IF ~calculationMethodsOfAppraisedPriceAtMaturity.ok THEN Fail ELSE
    LET elwRightsTypeCode == ReadBytes(calculationMethodsOfAppraisedPriceAtMaturity.rest, 1) IN IF ~elwRightsTypeCode.ok THEN Fail ELSE
    LET elwLpHoldingQuantity == ReadBytes(elwRightsTypeCode.rest, 15) IN IF ~elwLpHoldingQuantity.ok THEN Fail ELSE
    LET filler4 == ReadBytes(elwLpHoldingQuantity.rest, 4) IN IF ~filler4.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler4.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber                        |-> messageSequenceNumber.value,
         isinCode                                     |-> isinCode.value,
         aDesignatedNumberForAnIssue                  |-> aDesignatedNumberForAnIssue.value,
         nameOfIssuer                                 |-> nameOfIssuer.value,
         englishNameOfIssuer                          |-> englishNameOfIssuer.value,
         numbersOfIssuer                              |-> numbersOfIssuer.value,
         marketId1ForUnderlyingAssetsIndices          |-> marketId1ForUnderlyingAssetsIndices.value,
         marketId2ForUnderlyingAssetsIndices          |-> marketId2ForUnderlyingAssetsIndices.value,
         marketId3ForUnderlyingAssetsIndices          |-> marketId3ForUnderlyingAssetsIndices.value,
         marketId4ForUnderlyingAssetsIndices          |-> marketId4ForUnderlyingAssetsIndices.value,
         marketId5ForUnderlyingAssetsIndices          |-> marketId5ForUnderlyingAssetsIndices.value,
         underlyingAssetTypeCode1                     |-> underlyingAssetTypeCode1.value,
         underlyingAssetTypeCode2                     |-> underlyingAssetTypeCode2.value,
         underlyingAssetTypeCode3                     |-> underlyingAssetTypeCode3.value,
         underlyingAssetTypeCode4                     |-> underlyingAssetTypeCode4.value,
         underlyingAssetTypeCode5                     |-> underlyingAssetTypeCode5.value,
         underlyingAssetCompositionRatio1             |-> underlyingAssetCompositionRatio1.value,
         underlyingAssetCompositionRatio2             |-> underlyingAssetCompositionRatio2.value,
         underlyingAssetCompositionRatio3             |-> underlyingAssetCompositionRatio3.value,
         underlyingAssetCompositionRatio4             |-> underlyingAssetCompositionRatio4.value,
         underlyingAssetCompositionRatio5             |-> underlyingAssetCompositionRatio5.value,
         indexId                                      |-> indexId.value,
         optionRightsTypeCode                         |-> optionRightsTypeCode.value,
         rightsExecutionTypeCode                      |-> rightsExecutionTypeCode.value,
         paymentMethods                               |-> paymentMethods.value,
         lastTradingDate                              |-> lastTradingDate.value,
         elwPaymentDate                               |-> elwPaymentDate.value,
         basePriceOfUnderlyingAsset                   |-> basePriceOfUnderlyingAsset.value,
         detailsOfRights                              |-> detailsOfRights.value,
         elwConversionRate                            |-> elwConversionRate.value,
         elwGuaranteedRateForPriceIncreases           |-> elwGuaranteedRateForPriceIncreases.value,
         elwGuaranteedRateForPriceDecreases           |-> elwGuaranteedRateForPriceDecreases.value,
         elwFixedPayment                              |-> elwFixedPayment.value,
         elwPaymentAgent                              |-> elwPaymentAgent.value,
         calculationMethodsOfAppraisedPriceAtMaturity |-> calculationMethodsOfAppraisedPriceAtMaturity.value,
         elwRightsTypeCode                            |-> elwRightsTypeCode.value,
         elwLpHoldingQuantity                         |-> elwLpHoldingQuantity.value,
         filler4                                      |-> filler4.value,
         endKeyword                                   |-> endKeyword.value ], endKeyword.rest)

ZeroSecuritiesElwBatchDataMessage ==
    [ messageSequenceNumber                        |-> [i \in 1 .. 8 |-> 0],
      isinCode                                     |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue                  |-> [i \in 1 .. 6 |-> 0],
      nameOfIssuer                                 |-> [i \in 1 .. 80 |-> 0],
      englishNameOfIssuer                          |-> [i \in 1 .. 80 |-> 0],
      numbersOfIssuer                              |-> [i \in 1 .. 5 |-> 0],
      marketId1ForUnderlyingAssetsIndices          |-> [i \in 1 .. 3 |-> 0],
      marketId2ForUnderlyingAssetsIndices          |-> [i \in 1 .. 3 |-> 0],
      marketId3ForUnderlyingAssetsIndices          |-> [i \in 1 .. 3 |-> 0],
      marketId4ForUnderlyingAssetsIndices          |-> [i \in 1 .. 3 |-> 0],
      marketId5ForUnderlyingAssetsIndices          |-> [i \in 1 .. 3 |-> 0],
      underlyingAssetTypeCode1                     |-> [i \in 1 .. 12 |-> 0],
      underlyingAssetTypeCode2                     |-> [i \in 1 .. 12 |-> 0],
      underlyingAssetTypeCode3                     |-> [i \in 1 .. 12 |-> 0],
      underlyingAssetTypeCode4                     |-> [i \in 1 .. 12 |-> 0],
      underlyingAssetTypeCode5                     |-> [i \in 1 .. 12 |-> 0],
      underlyingAssetCompositionRatio1             |-> [i \in 1 .. 13 |-> 0],
      underlyingAssetCompositionRatio2             |-> [i \in 1 .. 13 |-> 0],
      underlyingAssetCompositionRatio3             |-> [i \in 1 .. 13 |-> 0],
      underlyingAssetCompositionRatio4             |-> [i \in 1 .. 13 |-> 0],
      underlyingAssetCompositionRatio5             |-> [i \in 1 .. 13 |-> 0],
      indexId                                      |-> [i \in 1 .. 6 |-> 0],
      optionRightsTypeCode                         |-> [i \in 1 .. 1 |-> 0],
      rightsExecutionTypeCode                      |-> [i \in 1 .. 1 |-> 0],
      paymentMethods                               |-> [i \in 1 .. 1 |-> 0],
      lastTradingDate                              |-> [i \in 1 .. 8 |-> 0],
      elwPaymentDate                               |-> [i \in 1 .. 8 |-> 0],
      basePriceOfUnderlyingAsset                   |-> [i \in 1 .. 13 |-> 0],
      detailsOfRights                              |-> [i \in 1 .. 200 |-> 0],
      elwConversionRate                            |-> [i \in 1 .. 13 |-> 0],
      elwGuaranteedRateForPriceIncreases           |-> [i \in 1 .. 10 |-> 0],
      elwGuaranteedRateForPriceDecreases           |-> [i \in 1 .. 10 |-> 0],
      elwFixedPayment                              |-> [i \in 1 .. 22 |-> 0],
      elwPaymentAgent                              |-> [i \in 1 .. 80 |-> 0],
      calculationMethodsOfAppraisedPriceAtMaturity |-> [i \in 1 .. 200 |-> 0],
      elwRightsTypeCode                            |-> [i \in 1 .. 1 |-> 0],
      elwLpHoldingQuantity                         |-> [i \in 1 .. 15 |-> 0],
      filler4                                      |-> [i \in 1 .. 4 |-> 0],
      endKeyword                                   |-> [i \in 1 .. 1 |-> 0] ]

(* Securities Elw Batch Data Message at zero, then each field in turn at the values it is checked at *)
CheckedSecuritiesElwBatchDataMessage ==
    { ZeroSecuritiesElwBatchDataMessage }
        \cup { [ZeroSecuritiesElwBatchDataMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesElwBatchDataMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesElwBatchDataMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroSecuritiesElwBatchDataMessage EXCEPT !.nameOfIssuer = one] : one \in Sample(80) }
        \cup { [ZeroSecuritiesElwBatchDataMessage EXCEPT !.englishNameOfIssuer = one] : one \in Sample(80) }
        \cup { [ZeroSecuritiesElwBatchDataMessage EXCEPT !.numbersOfIssuer = one] : one \in Sample(5) }
        \cup { [ZeroSecuritiesElwBatchDataMessage EXCEPT !.marketId1ForUnderlyingAssetsIndices = one] : one \in Sample(3) }
        \cup { [ZeroSecuritiesElwBatchDataMessage EXCEPT !.marketId2ForUnderlyingAssetsIndices = one] : one \in Sample(3) }
        \cup { [ZeroSecuritiesElwBatchDataMessage EXCEPT !.marketId3ForUnderlyingAssetsIndices = one] : one \in Sample(3) }
        \cup { [ZeroSecuritiesElwBatchDataMessage EXCEPT !.marketId4ForUnderlyingAssetsIndices = one] : one \in Sample(3) }
        \cup { [ZeroSecuritiesElwBatchDataMessage EXCEPT !.marketId5ForUnderlyingAssetsIndices = one] : one \in Sample(3) }
        \cup { [ZeroSecuritiesElwBatchDataMessage EXCEPT !.underlyingAssetTypeCode1 = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesElwBatchDataMessage EXCEPT !.underlyingAssetTypeCode2 = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesElwBatchDataMessage EXCEPT !.underlyingAssetTypeCode3 = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesElwBatchDataMessage EXCEPT !.underlyingAssetTypeCode4 = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesElwBatchDataMessage EXCEPT !.underlyingAssetTypeCode5 = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesElwBatchDataMessage EXCEPT !.underlyingAssetCompositionRatio1 = one] : one \in Sample(13) }
        \cup { [ZeroSecuritiesElwBatchDataMessage EXCEPT !.underlyingAssetCompositionRatio2 = one] : one \in Sample(13) }
        \cup { [ZeroSecuritiesElwBatchDataMessage EXCEPT !.underlyingAssetCompositionRatio3 = one] : one \in Sample(13) }
        \cup { [ZeroSecuritiesElwBatchDataMessage EXCEPT !.underlyingAssetCompositionRatio4 = one] : one \in Sample(13) }
        \cup { [ZeroSecuritiesElwBatchDataMessage EXCEPT !.underlyingAssetCompositionRatio5 = one] : one \in Sample(13) }
        \cup { [ZeroSecuritiesElwBatchDataMessage EXCEPT !.indexId = one] : one \in Sample(6) }
        \cup { [ZeroSecuritiesElwBatchDataMessage EXCEPT !.optionRightsTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesElwBatchDataMessage EXCEPT !.rightsExecutionTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesElwBatchDataMessage EXCEPT !.paymentMethods = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesElwBatchDataMessage EXCEPT !.lastTradingDate = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesElwBatchDataMessage EXCEPT !.elwPaymentDate = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesElwBatchDataMessage EXCEPT !.basePriceOfUnderlyingAsset = one] : one \in Sample(13) }
        \cup { [ZeroSecuritiesElwBatchDataMessage EXCEPT !.detailsOfRights = one] : one \in Sample(200) }
        \cup { [ZeroSecuritiesElwBatchDataMessage EXCEPT !.elwConversionRate = one] : one \in Sample(13) }
        \cup { [ZeroSecuritiesElwBatchDataMessage EXCEPT !.elwGuaranteedRateForPriceIncreases = one] : one \in Sample(10) }
        \cup { [ZeroSecuritiesElwBatchDataMessage EXCEPT !.elwGuaranteedRateForPriceDecreases = one] : one \in Sample(10) }
        \cup { [ZeroSecuritiesElwBatchDataMessage EXCEPT !.elwFixedPayment = one] : one \in Sample(22) }
        \cup { [ZeroSecuritiesElwBatchDataMessage EXCEPT !.elwPaymentAgent = one] : one \in Sample(80) }
        \cup { [ZeroSecuritiesElwBatchDataMessage EXCEPT !.calculationMethodsOfAppraisedPriceAtMaturity = one] : one \in Sample(200) }
        \cup { [ZeroSecuritiesElwBatchDataMessage EXCEPT !.elwRightsTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesElwBatchDataMessage EXCEPT !.elwLpHoldingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroSecuritiesElwBatchDataMessage EXCEPT !.filler4 = one] : one \in Sample(4) }
        \cup { [ZeroSecuritiesElwBatchDataMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Securities Etn Batch Data Message: 255 bytes                            *)
(***************************************************************************)

SecuritiesEtnBatchDataMessage ==
    [ messageSequenceNumber                     : Sample(8),
      isinCode                                  : Sample(12),
      aDesignatedNumberForAnIssue               : Sample(6),
      nameOfIssuer                              : Sample(80),
      englishNameOfIssuer                       : Sample(80),
      numbersOfIssuer                           : Sample(5),
      paymentMethods                            : Sample(1),
      lastTradingDate                           : Sample(8),
      etnPaymentDate                            : Sample(8),
      etnLpHoldingQuantity                      : Sample(15),
      lossProtectionEtnProfitStructureCode      : Sample(2),
      etnMaximumRedemptionPrice                 : Sample(11),
      etnMinimumRedemptionPrice                 : Sample(11),
      etnEarlyRedemptionPossibility             : Sample(1),
      etnEarlyRedemptionPeriod                  : Sample(2),
      institutionCode1AppraisedPriceCalculation : Sample(2),
      institutionCode2AppraisedPriceCalculation : Sample(2),
      endKeyword                                : Sample(1) ]

EncodeSecuritiesEtnBatchDataMessage(message) ==
    message.messageSequenceNumber
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.nameOfIssuer
        \o message.englishNameOfIssuer
        \o message.numbersOfIssuer
        \o message.paymentMethods
        \o message.lastTradingDate
        \o message.etnPaymentDate
        \o message.etnLpHoldingQuantity
        \o message.lossProtectionEtnProfitStructureCode
        \o message.etnMaximumRedemptionPrice
        \o message.etnMinimumRedemptionPrice
        \o message.etnEarlyRedemptionPossibility
        \o message.etnEarlyRedemptionPeriod
        \o message.institutionCode1AppraisedPriceCalculation
        \o message.institutionCode2AppraisedPriceCalculation
        \o message.endKeyword

DecodeSecuritiesEtnBatchDataMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET isinCode == ReadBytes(messageSequenceNumber.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET nameOfIssuer == ReadBytes(aDesignatedNumberForAnIssue.rest, 80) IN IF ~nameOfIssuer.ok THEN Fail ELSE
    LET englishNameOfIssuer == ReadBytes(nameOfIssuer.rest, 80) IN IF ~englishNameOfIssuer.ok THEN Fail ELSE
    LET numbersOfIssuer == ReadBytes(englishNameOfIssuer.rest, 5) IN IF ~numbersOfIssuer.ok THEN Fail ELSE
    LET paymentMethods == ReadBytes(numbersOfIssuer.rest, 1) IN IF ~paymentMethods.ok THEN Fail ELSE
    LET lastTradingDate == ReadBytes(paymentMethods.rest, 8) IN IF ~lastTradingDate.ok THEN Fail ELSE
    LET etnPaymentDate == ReadBytes(lastTradingDate.rest, 8) IN IF ~etnPaymentDate.ok THEN Fail ELSE
    LET etnLpHoldingQuantity == ReadBytes(etnPaymentDate.rest, 15) IN IF ~etnLpHoldingQuantity.ok THEN Fail ELSE
    LET lossProtectionEtnProfitStructureCode == ReadBytes(etnLpHoldingQuantity.rest, 2) IN IF ~lossProtectionEtnProfitStructureCode.ok THEN Fail ELSE
    LET etnMaximumRedemptionPrice == ReadBytes(lossProtectionEtnProfitStructureCode.rest, 11) IN IF ~etnMaximumRedemptionPrice.ok THEN Fail ELSE
    LET etnMinimumRedemptionPrice == ReadBytes(etnMaximumRedemptionPrice.rest, 11) IN IF ~etnMinimumRedemptionPrice.ok THEN Fail ELSE
    LET etnEarlyRedemptionPossibility == ReadBytes(etnMinimumRedemptionPrice.rest, 1) IN IF ~etnEarlyRedemptionPossibility.ok THEN Fail ELSE
    LET etnEarlyRedemptionPeriod == ReadBytes(etnEarlyRedemptionPossibility.rest, 2) IN IF ~etnEarlyRedemptionPeriod.ok THEN Fail ELSE
    LET institutionCode1AppraisedPriceCalculation == ReadBytes(etnEarlyRedemptionPeriod.rest, 2) IN IF ~institutionCode1AppraisedPriceCalculation.ok THEN Fail ELSE
    LET institutionCode2AppraisedPriceCalculation == ReadBytes(institutionCode1AppraisedPriceCalculation.rest, 2) IN IF ~institutionCode2AppraisedPriceCalculation.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(institutionCode2AppraisedPriceCalculation.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber                     |-> messageSequenceNumber.value,
         isinCode                                  |-> isinCode.value,
         aDesignatedNumberForAnIssue               |-> aDesignatedNumberForAnIssue.value,
         nameOfIssuer                              |-> nameOfIssuer.value,
         englishNameOfIssuer                       |-> englishNameOfIssuer.value,
         numbersOfIssuer                           |-> numbersOfIssuer.value,
         paymentMethods                            |-> paymentMethods.value,
         lastTradingDate                           |-> lastTradingDate.value,
         etnPaymentDate                            |-> etnPaymentDate.value,
         etnLpHoldingQuantity                      |-> etnLpHoldingQuantity.value,
         lossProtectionEtnProfitStructureCode      |-> lossProtectionEtnProfitStructureCode.value,
         etnMaximumRedemptionPrice                 |-> etnMaximumRedemptionPrice.value,
         etnMinimumRedemptionPrice                 |-> etnMinimumRedemptionPrice.value,
         etnEarlyRedemptionPossibility             |-> etnEarlyRedemptionPossibility.value,
         etnEarlyRedemptionPeriod                  |-> etnEarlyRedemptionPeriod.value,
         institutionCode1AppraisedPriceCalculation |-> institutionCode1AppraisedPriceCalculation.value,
         institutionCode2AppraisedPriceCalculation |-> institutionCode2AppraisedPriceCalculation.value,
         endKeyword                                |-> endKeyword.value ], endKeyword.rest)

ZeroSecuritiesEtnBatchDataMessage ==
    [ messageSequenceNumber                     |-> [i \in 1 .. 8 |-> 0],
      isinCode                                  |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue               |-> [i \in 1 .. 6 |-> 0],
      nameOfIssuer                              |-> [i \in 1 .. 80 |-> 0],
      englishNameOfIssuer                       |-> [i \in 1 .. 80 |-> 0],
      numbersOfIssuer                           |-> [i \in 1 .. 5 |-> 0],
      paymentMethods                            |-> [i \in 1 .. 1 |-> 0],
      lastTradingDate                           |-> [i \in 1 .. 8 |-> 0],
      etnPaymentDate                            |-> [i \in 1 .. 8 |-> 0],
      etnLpHoldingQuantity                      |-> [i \in 1 .. 15 |-> 0],
      lossProtectionEtnProfitStructureCode      |-> [i \in 1 .. 2 |-> 0],
      etnMaximumRedemptionPrice                 |-> [i \in 1 .. 11 |-> 0],
      etnMinimumRedemptionPrice                 |-> [i \in 1 .. 11 |-> 0],
      etnEarlyRedemptionPossibility             |-> [i \in 1 .. 1 |-> 0],
      etnEarlyRedemptionPeriod                  |-> [i \in 1 .. 2 |-> 0],
      institutionCode1AppraisedPriceCalculation |-> [i \in 1 .. 2 |-> 0],
      institutionCode2AppraisedPriceCalculation |-> [i \in 1 .. 2 |-> 0],
      endKeyword                                |-> [i \in 1 .. 1 |-> 0] ]

(* Securities Etn Batch Data Message at zero, then each field in turn at the values it is checked at *)
CheckedSecuritiesEtnBatchDataMessage ==
    { ZeroSecuritiesEtnBatchDataMessage }
        \cup { [ZeroSecuritiesEtnBatchDataMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesEtnBatchDataMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesEtnBatchDataMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroSecuritiesEtnBatchDataMessage EXCEPT !.nameOfIssuer = one] : one \in Sample(80) }
        \cup { [ZeroSecuritiesEtnBatchDataMessage EXCEPT !.englishNameOfIssuer = one] : one \in Sample(80) }
        \cup { [ZeroSecuritiesEtnBatchDataMessage EXCEPT !.numbersOfIssuer = one] : one \in Sample(5) }
        \cup { [ZeroSecuritiesEtnBatchDataMessage EXCEPT !.paymentMethods = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEtnBatchDataMessage EXCEPT !.lastTradingDate = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesEtnBatchDataMessage EXCEPT !.etnPaymentDate = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesEtnBatchDataMessage EXCEPT !.etnLpHoldingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroSecuritiesEtnBatchDataMessage EXCEPT !.lossProtectionEtnProfitStructureCode = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesEtnBatchDataMessage EXCEPT !.etnMaximumRedemptionPrice = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesEtnBatchDataMessage EXCEPT !.etnMinimumRedemptionPrice = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesEtnBatchDataMessage EXCEPT !.etnEarlyRedemptionPossibility = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEtnBatchDataMessage EXCEPT !.etnEarlyRedemptionPeriod = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesEtnBatchDataMessage EXCEPT !.institutionCode1AppraisedPriceCalculation = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesEtnBatchDataMessage EXCEPT !.institutionCode2AppraisedPriceCalculation = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesEtnBatchDataMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Securities Etn Early Redemption Message: 83 bytes                       *)
(***************************************************************************)

SecuritiesEtnEarlyRedemptionMessage ==
    [ messageSequenceNumber        : Sample(8),
      isinCode                     : Sample(12),
      etnEarlyRedemptionPeriod     : Sample(2),
      earlyRedemptionAppraisalDate : Sample(8),
      earlyRedemptionCriteriaCode  : Sample(1),
      earlyRedemptionBaseIndex1    : Sample(10),
      earlyRedemptionBaseIndex2    : Sample(10),
      earlyRedemptionPrice         : Sample(23),
      earlyRepemptionPaymentDate   : Sample(8),
      endKeyword                   : Sample(1) ]

EncodeSecuritiesEtnEarlyRedemptionMessage(message) ==
    message.messageSequenceNumber
        \o message.isinCode
        \o message.etnEarlyRedemptionPeriod
        \o message.earlyRedemptionAppraisalDate
        \o message.earlyRedemptionCriteriaCode
        \o message.earlyRedemptionBaseIndex1
        \o message.earlyRedemptionBaseIndex2
        \o message.earlyRedemptionPrice
        \o message.earlyRepemptionPaymentDate
        \o message.endKeyword

DecodeSecuritiesEtnEarlyRedemptionMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET isinCode == ReadBytes(messageSequenceNumber.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET etnEarlyRedemptionPeriod == ReadBytes(isinCode.rest, 2) IN IF ~etnEarlyRedemptionPeriod.ok THEN Fail ELSE
    LET earlyRedemptionAppraisalDate == ReadBytes(etnEarlyRedemptionPeriod.rest, 8) IN IF ~earlyRedemptionAppraisalDate.ok THEN Fail ELSE
    LET earlyRedemptionCriteriaCode == ReadBytes(earlyRedemptionAppraisalDate.rest, 1) IN IF ~earlyRedemptionCriteriaCode.ok THEN Fail ELSE
    LET earlyRedemptionBaseIndex1 == ReadBytes(earlyRedemptionCriteriaCode.rest, 10) IN IF ~earlyRedemptionBaseIndex1.ok THEN Fail ELSE
    LET earlyRedemptionBaseIndex2 == ReadBytes(earlyRedemptionBaseIndex1.rest, 10) IN IF ~earlyRedemptionBaseIndex2.ok THEN Fail ELSE
    LET earlyRedemptionPrice == ReadBytes(earlyRedemptionBaseIndex2.rest, 23) IN IF ~earlyRedemptionPrice.ok THEN Fail ELSE
    LET earlyRepemptionPaymentDate == ReadBytes(earlyRedemptionPrice.rest, 8) IN IF ~earlyRepemptionPaymentDate.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(earlyRepemptionPaymentDate.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber        |-> messageSequenceNumber.value,
         isinCode                     |-> isinCode.value,
         etnEarlyRedemptionPeriod     |-> etnEarlyRedemptionPeriod.value,
         earlyRedemptionAppraisalDate |-> earlyRedemptionAppraisalDate.value,
         earlyRedemptionCriteriaCode  |-> earlyRedemptionCriteriaCode.value,
         earlyRedemptionBaseIndex1    |-> earlyRedemptionBaseIndex1.value,
         earlyRedemptionBaseIndex2    |-> earlyRedemptionBaseIndex2.value,
         earlyRedemptionPrice         |-> earlyRedemptionPrice.value,
         earlyRepemptionPaymentDate   |-> earlyRepemptionPaymentDate.value,
         endKeyword                   |-> endKeyword.value ], endKeyword.rest)

ZeroSecuritiesEtnEarlyRedemptionMessage ==
    [ messageSequenceNumber        |-> [i \in 1 .. 8 |-> 0],
      isinCode                     |-> [i \in 1 .. 12 |-> 0],
      etnEarlyRedemptionPeriod     |-> [i \in 1 .. 2 |-> 0],
      earlyRedemptionAppraisalDate |-> [i \in 1 .. 8 |-> 0],
      earlyRedemptionCriteriaCode  |-> [i \in 1 .. 1 |-> 0],
      earlyRedemptionBaseIndex1    |-> [i \in 1 .. 10 |-> 0],
      earlyRedemptionBaseIndex2    |-> [i \in 1 .. 10 |-> 0],
      earlyRedemptionPrice         |-> [i \in 1 .. 23 |-> 0],
      earlyRepemptionPaymentDate   |-> [i \in 1 .. 8 |-> 0],
      endKeyword                   |-> [i \in 1 .. 1 |-> 0] ]

(* Securities Etn Early Redemption Message at zero, then each field in turn at the values it is checked at *)
CheckedSecuritiesEtnEarlyRedemptionMessage ==
    { ZeroSecuritiesEtnEarlyRedemptionMessage }
        \cup { [ZeroSecuritiesEtnEarlyRedemptionMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesEtnEarlyRedemptionMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesEtnEarlyRedemptionMessage EXCEPT !.etnEarlyRedemptionPeriod = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesEtnEarlyRedemptionMessage EXCEPT !.earlyRedemptionAppraisalDate = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesEtnEarlyRedemptionMessage EXCEPT !.earlyRedemptionCriteriaCode = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesEtnEarlyRedemptionMessage EXCEPT !.earlyRedemptionBaseIndex1 = one] : one \in Sample(10) }
        \cup { [ZeroSecuritiesEtnEarlyRedemptionMessage EXCEPT !.earlyRedemptionBaseIndex2 = one] : one \in Sample(10) }
        \cup { [ZeroSecuritiesEtnEarlyRedemptionMessage EXCEPT !.earlyRedemptionPrice = one] : one \in Sample(23) }
        \cup { [ZeroSecuritiesEtnEarlyRedemptionMessage EXCEPT !.earlyRepemptionPaymentDate = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesEtnEarlyRedemptionMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Securities Etp Constituents Message: 204 bytes                          *)
(***************************************************************************)

SecuritiesEtpConstituentsMessage ==
    [ messageSequenceNumber               : Sample(8),
      indexCalculationInstitutionTypeCode : Sample(2),
      indexMarketClassificationId         : Sample(6),
      indexSequenceNumber                 : Sample(3),
      indexLeverageInverseTypeCode        : Sample(2),
      indexName                           : Sample(80),
      indexNameInEn                       : Sample(80),
      indexAssetClassificationId1         : Sample(6),
      indexAssetClassificationId2         : Sample(6),
      indexId                             : Sample(6),
      filler4                             : Sample(4),
      endKeyword                          : Sample(1) ]

EncodeSecuritiesEtpConstituentsMessage(message) ==
    message.messageSequenceNumber
        \o message.indexCalculationInstitutionTypeCode
        \o message.indexMarketClassificationId
        \o message.indexSequenceNumber
        \o message.indexLeverageInverseTypeCode
        \o message.indexName
        \o message.indexNameInEn
        \o message.indexAssetClassificationId1
        \o message.indexAssetClassificationId2
        \o message.indexId
        \o message.filler4
        \o message.endKeyword

DecodeSecuritiesEtpConstituentsMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET indexCalculationInstitutionTypeCode == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~indexCalculationInstitutionTypeCode.ok THEN Fail ELSE
    LET indexMarketClassificationId == ReadBytes(indexCalculationInstitutionTypeCode.rest, 6) IN IF ~indexMarketClassificationId.ok THEN Fail ELSE
    LET indexSequenceNumber == ReadBytes(indexMarketClassificationId.rest, 3) IN IF ~indexSequenceNumber.ok THEN Fail ELSE
    LET indexLeverageInverseTypeCode == ReadBytes(indexSequenceNumber.rest, 2) IN IF ~indexLeverageInverseTypeCode.ok THEN Fail ELSE
    LET indexName == ReadBytes(indexLeverageInverseTypeCode.rest, 80) IN IF ~indexName.ok THEN Fail ELSE
    LET indexNameInEn == ReadBytes(indexName.rest, 80) IN IF ~indexNameInEn.ok THEN Fail ELSE
    LET indexAssetClassificationId1 == ReadBytes(indexNameInEn.rest, 6) IN IF ~indexAssetClassificationId1.ok THEN Fail ELSE
    LET indexAssetClassificationId2 == ReadBytes(indexAssetClassificationId1.rest, 6) IN IF ~indexAssetClassificationId2.ok THEN Fail ELSE
    LET indexId == ReadBytes(indexAssetClassificationId2.rest, 6) IN IF ~indexId.ok THEN Fail ELSE
    LET filler4 == ReadBytes(indexId.rest, 4) IN IF ~filler4.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler4.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber               |-> messageSequenceNumber.value,
         indexCalculationInstitutionTypeCode |-> indexCalculationInstitutionTypeCode.value,
         indexMarketClassificationId         |-> indexMarketClassificationId.value,
         indexSequenceNumber                 |-> indexSequenceNumber.value,
         indexLeverageInverseTypeCode        |-> indexLeverageInverseTypeCode.value,
         indexName                           |-> indexName.value,
         indexNameInEn                       |-> indexNameInEn.value,
         indexAssetClassificationId1         |-> indexAssetClassificationId1.value,
         indexAssetClassificationId2         |-> indexAssetClassificationId2.value,
         indexId                             |-> indexId.value,
         filler4                             |-> filler4.value,
         endKeyword                          |-> endKeyword.value ], endKeyword.rest)

ZeroSecuritiesEtpConstituentsMessage ==
    [ messageSequenceNumber               |-> [i \in 1 .. 8 |-> 0],
      indexCalculationInstitutionTypeCode |-> [i \in 1 .. 2 |-> 0],
      indexMarketClassificationId         |-> [i \in 1 .. 6 |-> 0],
      indexSequenceNumber                 |-> [i \in 1 .. 3 |-> 0],
      indexLeverageInverseTypeCode        |-> [i \in 1 .. 2 |-> 0],
      indexName                           |-> [i \in 1 .. 80 |-> 0],
      indexNameInEn                       |-> [i \in 1 .. 80 |-> 0],
      indexAssetClassificationId1         |-> [i \in 1 .. 6 |-> 0],
      indexAssetClassificationId2         |-> [i \in 1 .. 6 |-> 0],
      indexId                             |-> [i \in 1 .. 6 |-> 0],
      filler4                             |-> [i \in 1 .. 4 |-> 0],
      endKeyword                          |-> [i \in 1 .. 1 |-> 0] ]

(* Securities Etp Constituents Message at zero, then each field in turn at the values it is checked at *)
CheckedSecuritiesEtpConstituentsMessage ==
    { ZeroSecuritiesEtpConstituentsMessage }
        \cup { [ZeroSecuritiesEtpConstituentsMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesEtpConstituentsMessage EXCEPT !.indexCalculationInstitutionTypeCode = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesEtpConstituentsMessage EXCEPT !.indexMarketClassificationId = one] : one \in Sample(6) }
        \cup { [ZeroSecuritiesEtpConstituentsMessage EXCEPT !.indexSequenceNumber = one] : one \in Sample(3) }
        \cup { [ZeroSecuritiesEtpConstituentsMessage EXCEPT !.indexLeverageInverseTypeCode = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesEtpConstituentsMessage EXCEPT !.indexName = one] : one \in Sample(80) }
        \cup { [ZeroSecuritiesEtpConstituentsMessage EXCEPT !.indexNameInEn = one] : one \in Sample(80) }
        \cup { [ZeroSecuritiesEtpConstituentsMessage EXCEPT !.indexAssetClassificationId1 = one] : one \in Sample(6) }
        \cup { [ZeroSecuritiesEtpConstituentsMessage EXCEPT !.indexAssetClassificationId2 = one] : one \in Sample(6) }
        \cup { [ZeroSecuritiesEtpConstituentsMessage EXCEPT !.indexId = one] : one \in Sample(6) }
        \cup { [ZeroSecuritiesEtpConstituentsMessage EXCEPT !.filler4 = one] : one \in Sample(4) }
        \cup { [ZeroSecuritiesEtpConstituentsMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Securities Knock Out Elw Message: 534 bytes                             *)
(***************************************************************************)

SecuritiesKnockOutElwMessage ==
    [ messageSequenceNumber                  : Sample(8),
      isinCode                               : Sample(12),
      basePriceToKnockOutElw                 : Sample(13),
      knockOutElwRights                      : Sample(200),
      knockOutElwCalculationOfAppraisedPrice : Sample(300),
      endKeyword                             : Sample(1) ]

EncodeSecuritiesKnockOutElwMessage(message) ==
    message.messageSequenceNumber
        \o message.isinCode
        \o message.basePriceToKnockOutElw
        \o message.knockOutElwRights
        \o message.knockOutElwCalculationOfAppraisedPrice
        \o message.endKeyword

DecodeSecuritiesKnockOutElwMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET isinCode == ReadBytes(messageSequenceNumber.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET basePriceToKnockOutElw == ReadBytes(isinCode.rest, 13) IN IF ~basePriceToKnockOutElw.ok THEN Fail ELSE
    LET knockOutElwRights == ReadBytes(basePriceToKnockOutElw.rest, 200) IN IF ~knockOutElwRights.ok THEN Fail ELSE
    LET knockOutElwCalculationOfAppraisedPrice == ReadBytes(knockOutElwRights.rest, 300) IN IF ~knockOutElwCalculationOfAppraisedPrice.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(knockOutElwCalculationOfAppraisedPrice.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber                  |-> messageSequenceNumber.value,
         isinCode                               |-> isinCode.value,
         basePriceToKnockOutElw                 |-> basePriceToKnockOutElw.value,
         knockOutElwRights                      |-> knockOutElwRights.value,
         knockOutElwCalculationOfAppraisedPrice |-> knockOutElwCalculationOfAppraisedPrice.value,
         endKeyword                             |-> endKeyword.value ], endKeyword.rest)

ZeroSecuritiesKnockOutElwMessage ==
    [ messageSequenceNumber                  |-> [i \in 1 .. 8 |-> 0],
      isinCode                               |-> [i \in 1 .. 12 |-> 0],
      basePriceToKnockOutElw                 |-> [i \in 1 .. 13 |-> 0],
      knockOutElwRights                      |-> [i \in 1 .. 200 |-> 0],
      knockOutElwCalculationOfAppraisedPrice |-> [i \in 1 .. 300 |-> 0],
      endKeyword                             |-> [i \in 1 .. 1 |-> 0] ]

(* Securities Knock Out Elw Message at zero, then each field in turn at the values it is checked at *)
CheckedSecuritiesKnockOutElwMessage ==
    { ZeroSecuritiesKnockOutElwMessage }
        \cup { [ZeroSecuritiesKnockOutElwMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesKnockOutElwMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesKnockOutElwMessage EXCEPT !.basePriceToKnockOutElw = one] : one \in Sample(13) }
        \cup { [ZeroSecuritiesKnockOutElwMessage EXCEPT !.knockOutElwRights = one] : one \in Sample(200) }
        \cup { [ZeroSecuritiesKnockOutElwMessage EXCEPT !.knockOutElwCalculationOfAppraisedPrice = one] : one \in Sample(300) }
        \cup { [ZeroSecuritiesKnockOutElwMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Securities Knock Out Underlying Message: 90 bytes                       *)
(***************************************************************************)

SecuritiesKnockOutUnderlyingMessage ==
    [ isinCode                     : Sample(12),
      messageSequenceNumber        : Sample(8),
      transmissionDate             : Sample(8),
      tradingDateOfUnderlyingAsset : Sample(8),
      theDateKnockOutOccurred      : Sample(8),
      ampmTypeCode                 : Sample(1),
      underlyingIsinCode           : Sample(12),
      indexId                      : Sample(6),
      todaysHigh                   : Sample(11),
      todaysLow                    : Sample(11),
      filler4                      : Sample(4),
      endKeyword                   : Sample(1) ]

EncodeSecuritiesKnockOutUnderlyingMessage(message) ==
    message.isinCode
        \o message.messageSequenceNumber
        \o message.transmissionDate
        \o message.tradingDateOfUnderlyingAsset
        \o message.theDateKnockOutOccurred
        \o message.ampmTypeCode
        \o message.underlyingIsinCode
        \o message.indexId
        \o message.todaysHigh
        \o message.todaysLow
        \o message.filler4
        \o message.endKeyword

DecodeSecuritiesKnockOutUnderlyingMessage(bytes) ==
    LET isinCode == ReadBytes(bytes, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET messageSequenceNumber == ReadBytes(isinCode.rest, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET transmissionDate == ReadBytes(messageSequenceNumber.rest, 8) IN IF ~transmissionDate.ok THEN Fail ELSE
    LET tradingDateOfUnderlyingAsset == ReadBytes(transmissionDate.rest, 8) IN IF ~tradingDateOfUnderlyingAsset.ok THEN Fail ELSE
    LET theDateKnockOutOccurred == ReadBytes(tradingDateOfUnderlyingAsset.rest, 8) IN IF ~theDateKnockOutOccurred.ok THEN Fail ELSE
    LET ampmTypeCode == ReadBytes(theDateKnockOutOccurred.rest, 1) IN IF ~ampmTypeCode.ok THEN Fail ELSE
    LET underlyingIsinCode == ReadBytes(ampmTypeCode.rest, 12) IN IF ~underlyingIsinCode.ok THEN Fail ELSE
    LET indexId == ReadBytes(underlyingIsinCode.rest, 6) IN IF ~indexId.ok THEN Fail ELSE
    LET todaysHigh == ReadBytes(indexId.rest, 11) IN IF ~todaysHigh.ok THEN Fail ELSE
    LET todaysLow == ReadBytes(todaysHigh.rest, 11) IN IF ~todaysLow.ok THEN Fail ELSE
    LET filler4 == ReadBytes(todaysLow.rest, 4) IN IF ~filler4.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler4.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ isinCode                     |-> isinCode.value,
         messageSequenceNumber        |-> messageSequenceNumber.value,
         transmissionDate             |-> transmissionDate.value,
         tradingDateOfUnderlyingAsset |-> tradingDateOfUnderlyingAsset.value,
         theDateKnockOutOccurred      |-> theDateKnockOutOccurred.value,
         ampmTypeCode                 |-> ampmTypeCode.value,
         underlyingIsinCode           |-> underlyingIsinCode.value,
         indexId                      |-> indexId.value,
         todaysHigh                   |-> todaysHigh.value,
         todaysLow                    |-> todaysLow.value,
         filler4                      |-> filler4.value,
         endKeyword                   |-> endKeyword.value ], endKeyword.rest)

ZeroSecuritiesKnockOutUnderlyingMessage ==
    [ isinCode                     |-> [i \in 1 .. 12 |-> 0],
      messageSequenceNumber        |-> [i \in 1 .. 8 |-> 0],
      transmissionDate             |-> [i \in 1 .. 8 |-> 0],
      tradingDateOfUnderlyingAsset |-> [i \in 1 .. 8 |-> 0],
      theDateKnockOutOccurred      |-> [i \in 1 .. 8 |-> 0],
      ampmTypeCode                 |-> [i \in 1 .. 1 |-> 0],
      underlyingIsinCode           |-> [i \in 1 .. 12 |-> 0],
      indexId                      |-> [i \in 1 .. 6 |-> 0],
      todaysHigh                   |-> [i \in 1 .. 11 |-> 0],
      todaysLow                    |-> [i \in 1 .. 11 |-> 0],
      filler4                      |-> [i \in 1 .. 4 |-> 0],
      endKeyword                   |-> [i \in 1 .. 1 |-> 0] ]

(* Securities Knock Out Underlying Message at zero, then each field in turn at the values it is checked at *)
CheckedSecuritiesKnockOutUnderlyingMessage ==
    { ZeroSecuritiesKnockOutUnderlyingMessage }
        \cup { [ZeroSecuritiesKnockOutUnderlyingMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesKnockOutUnderlyingMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesKnockOutUnderlyingMessage EXCEPT !.transmissionDate = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesKnockOutUnderlyingMessage EXCEPT !.tradingDateOfUnderlyingAsset = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesKnockOutUnderlyingMessage EXCEPT !.theDateKnockOutOccurred = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesKnockOutUnderlyingMessage EXCEPT !.ampmTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesKnockOutUnderlyingMessage EXCEPT !.underlyingIsinCode = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesKnockOutUnderlyingMessage EXCEPT !.indexId = one] : one \in Sample(6) }
        \cup { [ZeroSecuritiesKnockOutUnderlyingMessage EXCEPT !.todaysHigh = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesKnockOutUnderlyingMessage EXCEPT !.todaysLow = one] : one \in Sample(11) }
        \cup { [ZeroSecuritiesKnockOutUnderlyingMessage EXCEPT !.filler4 = one] : one \in Sample(4) }
        \cup { [ZeroSecuritiesKnockOutUnderlyingMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Securities Closing Price Trade Remaining Quantity On Quotes Message: 77 *)
(* bytes                                                                   *)
(***************************************************************************)

SecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage ==
    [ messageSequenceNumber         : Sample(8),
      boardId                       : Sample(2),
      isinCode                      : Sample(12),
      aDesignatedNumberForAnIssue   : Sample(6),
      processingTimeOfTradingSystem : Sample(12),
      accumulatedTradingVolume      : Sample(12),
      askTotalVolume                : Sample(12),
      bidTotalVolume                : Sample(12),
      endKeyword                    : Sample(1) ]

EncodeSecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.processingTimeOfTradingSystem
        \o message.accumulatedTradingVolume
        \o message.askTotalVolume
        \o message.bidTotalVolume
        \o message.endKeyword

DecodeSecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(boardId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET processingTimeOfTradingSystem == ReadBytes(aDesignatedNumberForAnIssue.rest, 12) IN IF ~processingTimeOfTradingSystem.ok THEN Fail ELSE
    LET accumulatedTradingVolume == ReadBytes(processingTimeOfTradingSystem.rest, 12) IN IF ~accumulatedTradingVolume.ok THEN Fail ELSE
    LET askTotalVolume == ReadBytes(accumulatedTradingVolume.rest, 12) IN IF ~askTotalVolume.ok THEN Fail ELSE
    LET bidTotalVolume == ReadBytes(askTotalVolume.rest, 12) IN IF ~bidTotalVolume.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(bidTotalVolume.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber         |-> messageSequenceNumber.value,
         boardId                       |-> boardId.value,
         isinCode                      |-> isinCode.value,
         aDesignatedNumberForAnIssue   |-> aDesignatedNumberForAnIssue.value,
         processingTimeOfTradingSystem |-> processingTimeOfTradingSystem.value,
         accumulatedTradingVolume      |-> accumulatedTradingVolume.value,
         askTotalVolume                |-> askTotalVolume.value,
         bidTotalVolume                |-> bidTotalVolume.value,
         endKeyword                    |-> endKeyword.value ], endKeyword.rest)

ZeroSecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage ==
    [ messageSequenceNumber         |-> [i \in 1 .. 8 |-> 0],
      boardId                       |-> [i \in 1 .. 2 |-> 0],
      isinCode                      |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue   |-> [i \in 1 .. 6 |-> 0],
      processingTimeOfTradingSystem |-> [i \in 1 .. 12 |-> 0],
      accumulatedTradingVolume      |-> [i \in 1 .. 12 |-> 0],
      askTotalVolume                |-> [i \in 1 .. 12 |-> 0],
      bidTotalVolume                |-> [i \in 1 .. 12 |-> 0],
      endKeyword                    |-> [i \in 1 .. 1 |-> 0] ]

(* Securities Closing Price Trade Remaining Quantity On Quotes Message at zero, then each field in turn at the values it is checked at *)
CheckedSecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage ==
    { ZeroSecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage }
        \cup { [ZeroSecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroSecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage EXCEPT !.processingTimeOfTradingSystem = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage EXCEPT !.accumulatedTradingVolume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage EXCEPT !.askTotalVolume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage EXCEPT !.bidTotalVolume = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Securities A Blox Trade Quotes Message: 42 bytes                        *)
(***************************************************************************)

SecuritiesABloxTradeQuotesMessage ==
    [ messageSequenceNumber         : Sample(8),
      boardId                       : Sample(2),
      isinCode                      : Sample(12),
      aDesignatedNumberForAnIssue   : Sample(6),
      processingTimeOfTradingSystem : Sample(12),
      askBidTypeCode                : Sample(1),
      endKeyword                    : Sample(1) ]

EncodeSecuritiesABloxTradeQuotesMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.processingTimeOfTradingSystem
        \o message.askBidTypeCode
        \o message.endKeyword

DecodeSecuritiesABloxTradeQuotesMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(boardId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET processingTimeOfTradingSystem == ReadBytes(aDesignatedNumberForAnIssue.rest, 12) IN IF ~processingTimeOfTradingSystem.ok THEN Fail ELSE
    LET askBidTypeCode == ReadBytes(processingTimeOfTradingSystem.rest, 1) IN IF ~askBidTypeCode.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(askBidTypeCode.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber         |-> messageSequenceNumber.value,
         boardId                       |-> boardId.value,
         isinCode                      |-> isinCode.value,
         aDesignatedNumberForAnIssue   |-> aDesignatedNumberForAnIssue.value,
         processingTimeOfTradingSystem |-> processingTimeOfTradingSystem.value,
         askBidTypeCode                |-> askBidTypeCode.value,
         endKeyword                    |-> endKeyword.value ], endKeyword.rest)

ZeroSecuritiesABloxTradeQuotesMessage ==
    [ messageSequenceNumber         |-> [i \in 1 .. 8 |-> 0],
      boardId                       |-> [i \in 1 .. 2 |-> 0],
      isinCode                      |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue   |-> [i \in 1 .. 6 |-> 0],
      processingTimeOfTradingSystem |-> [i \in 1 .. 12 |-> 0],
      askBidTypeCode                |-> [i \in 1 .. 1 |-> 0],
      endKeyword                    |-> [i \in 1 .. 1 |-> 0] ]

(* Securities A Blox Trade Quotes Message at zero, then each field in turn at the values it is checked at *)
CheckedSecuritiesABloxTradeQuotesMessage ==
    { ZeroSecuritiesABloxTradeQuotesMessage }
        \cup { [ZeroSecuritiesABloxTradeQuotesMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesABloxTradeQuotesMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesABloxTradeQuotesMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesABloxTradeQuotesMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroSecuritiesABloxTradeQuotesMessage EXCEPT !.processingTimeOfTradingSystem = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesABloxTradeQuotesMessage EXCEPT !.askBidTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesABloxTradeQuotesMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Securities Etn Profit Structure Message: 2021 bytes                     *)
(***************************************************************************)

SecuritiesEtnProfitStructureMessage ==
    [ messageSequenceNumber       : Sample(8),
      isinCode                    : Sample(12),
      detailsOfEtnProfitStructure : Sample(2000),
      endKeyword                  : Sample(1) ]

EncodeSecuritiesEtnProfitStructureMessage(message) ==
    message.messageSequenceNumber
        \o message.isinCode
        \o message.detailsOfEtnProfitStructure
        \o message.endKeyword

DecodeSecuritiesEtnProfitStructureMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET isinCode == ReadBytes(messageSequenceNumber.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET detailsOfEtnProfitStructure == ReadBytes(isinCode.rest, 2000) IN IF ~detailsOfEtnProfitStructure.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(detailsOfEtnProfitStructure.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber       |-> messageSequenceNumber.value,
         isinCode                    |-> isinCode.value,
         detailsOfEtnProfitStructure |-> detailsOfEtnProfitStructure.value,
         endKeyword                  |-> endKeyword.value ], endKeyword.rest)

ZeroSecuritiesEtnProfitStructureMessage ==
    [ messageSequenceNumber       |-> [i \in 1 .. 8 |-> 0],
      isinCode                    |-> [i \in 1 .. 12 |-> 0],
      detailsOfEtnProfitStructure |-> [i \in 1 .. 2000 |-> 0],
      endKeyword                  |-> [i \in 1 .. 1 |-> 0] ]

(* Securities Etn Profit Structure Message at zero, then each field in turn at the values it is checked at *)
CheckedSecuritiesEtnProfitStructureMessage ==
    { ZeroSecuritiesEtnProfitStructureMessage }
        \cup { [ZeroSecuritiesEtnProfitStructureMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesEtnProfitStructureMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesEtnProfitStructureMessage EXCEPT !.detailsOfEtnProfitStructure = one] : one \in Sample(2000) }
        \cup { [ZeroSecuritiesEtnProfitStructureMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Securities Top Five Traders Activities Message: 409 bytes               *)
(***************************************************************************)

SecuritiesTopFiveTradersActivitiesMessage ==
    [ isinCode                    : Sample(12),
      aDesignatedNumberForAnIssue : Sample(6),
      memberNumber1ForAsk         : Sample(5),
      askTradingVolume1           : Sample(12),
      askTradingValue1            : Sample(22),
      memberNumber1ForBid         : Sample(5),
      bidTradingVolume1           : Sample(12),
      bidTradingValue1            : Sample(22),
      memberNumber2ForAsk         : Sample(5),
      askTradingVolume2           : Sample(12),
      askTradingValue2            : Sample(22),
      memberNumber2ForBid         : Sample(5),
      bidTradingVolume2           : Sample(12),
      bidTradingValue2            : Sample(22),
      memberNumber3ForAsk         : Sample(5),
      askTradingVolume3           : Sample(12),
      askTradingValue3            : Sample(22),
      memberNumber3ForBid         : Sample(5),
      bidTradingVolume3           : Sample(12),
      bidTradingValue3            : Sample(22),
      memberNumber4ForAsk         : Sample(5),
      askTradingVolume4           : Sample(12),
      askTradingValue4            : Sample(22),
      memberNumber4ForBid         : Sample(5),
      bidTradingVolume4           : Sample(12),
      bidTradingValue4            : Sample(22),
      memberNumber5ForAsk         : Sample(5),
      askTradingVolume5           : Sample(12),
      askTradingValue5            : Sample(22),
      memberNumber5ForBid         : Sample(5),
      bidTradingVolume5           : Sample(12),
      bidTradingValue5            : Sample(22),
      endKeyword                  : Sample(1) ]

EncodeSecuritiesTopFiveTradersActivitiesMessage(message) ==
    message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.memberNumber1ForAsk
        \o message.askTradingVolume1
        \o message.askTradingValue1
        \o message.memberNumber1ForBid
        \o message.bidTradingVolume1
        \o message.bidTradingValue1
        \o message.memberNumber2ForAsk
        \o message.askTradingVolume2
        \o message.askTradingValue2
        \o message.memberNumber2ForBid
        \o message.bidTradingVolume2
        \o message.bidTradingValue2
        \o message.memberNumber3ForAsk
        \o message.askTradingVolume3
        \o message.askTradingValue3
        \o message.memberNumber3ForBid
        \o message.bidTradingVolume3
        \o message.bidTradingValue3
        \o message.memberNumber4ForAsk
        \o message.askTradingVolume4
        \o message.askTradingValue4
        \o message.memberNumber4ForBid
        \o message.bidTradingVolume4
        \o message.bidTradingValue4
        \o message.memberNumber5ForAsk
        \o message.askTradingVolume5
        \o message.askTradingValue5
        \o message.memberNumber5ForBid
        \o message.bidTradingVolume5
        \o message.bidTradingValue5
        \o message.endKeyword

DecodeSecuritiesTopFiveTradersActivitiesMessage(bytes) ==
    LET isinCode == ReadBytes(bytes, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET memberNumber1ForAsk == ReadBytes(aDesignatedNumberForAnIssue.rest, 5) IN IF ~memberNumber1ForAsk.ok THEN Fail ELSE
    LET askTradingVolume1 == ReadBytes(memberNumber1ForAsk.rest, 12) IN IF ~askTradingVolume1.ok THEN Fail ELSE
    LET askTradingValue1 == ReadBytes(askTradingVolume1.rest, 22) IN IF ~askTradingValue1.ok THEN Fail ELSE
    LET memberNumber1ForBid == ReadBytes(askTradingValue1.rest, 5) IN IF ~memberNumber1ForBid.ok THEN Fail ELSE
    LET bidTradingVolume1 == ReadBytes(memberNumber1ForBid.rest, 12) IN IF ~bidTradingVolume1.ok THEN Fail ELSE
    LET bidTradingValue1 == ReadBytes(bidTradingVolume1.rest, 22) IN IF ~bidTradingValue1.ok THEN Fail ELSE
    LET memberNumber2ForAsk == ReadBytes(bidTradingValue1.rest, 5) IN IF ~memberNumber2ForAsk.ok THEN Fail ELSE
    LET askTradingVolume2 == ReadBytes(memberNumber2ForAsk.rest, 12) IN IF ~askTradingVolume2.ok THEN Fail ELSE
    LET askTradingValue2 == ReadBytes(askTradingVolume2.rest, 22) IN IF ~askTradingValue2.ok THEN Fail ELSE
    LET memberNumber2ForBid == ReadBytes(askTradingValue2.rest, 5) IN IF ~memberNumber2ForBid.ok THEN Fail ELSE
    LET bidTradingVolume2 == ReadBytes(memberNumber2ForBid.rest, 12) IN IF ~bidTradingVolume2.ok THEN Fail ELSE
    LET bidTradingValue2 == ReadBytes(bidTradingVolume2.rest, 22) IN IF ~bidTradingValue2.ok THEN Fail ELSE
    LET memberNumber3ForAsk == ReadBytes(bidTradingValue2.rest, 5) IN IF ~memberNumber3ForAsk.ok THEN Fail ELSE
    LET askTradingVolume3 == ReadBytes(memberNumber3ForAsk.rest, 12) IN IF ~askTradingVolume3.ok THEN Fail ELSE
    LET askTradingValue3 == ReadBytes(askTradingVolume3.rest, 22) IN IF ~askTradingValue3.ok THEN Fail ELSE
    LET memberNumber3ForBid == ReadBytes(askTradingValue3.rest, 5) IN IF ~memberNumber3ForBid.ok THEN Fail ELSE
    LET bidTradingVolume3 == ReadBytes(memberNumber3ForBid.rest, 12) IN IF ~bidTradingVolume3.ok THEN Fail ELSE
    LET bidTradingValue3 == ReadBytes(bidTradingVolume3.rest, 22) IN IF ~bidTradingValue3.ok THEN Fail ELSE
    LET memberNumber4ForAsk == ReadBytes(bidTradingValue3.rest, 5) IN IF ~memberNumber4ForAsk.ok THEN Fail ELSE
    LET askTradingVolume4 == ReadBytes(memberNumber4ForAsk.rest, 12) IN IF ~askTradingVolume4.ok THEN Fail ELSE
    LET askTradingValue4 == ReadBytes(askTradingVolume4.rest, 22) IN IF ~askTradingValue4.ok THEN Fail ELSE
    LET memberNumber4ForBid == ReadBytes(askTradingValue4.rest, 5) IN IF ~memberNumber4ForBid.ok THEN Fail ELSE
    LET bidTradingVolume4 == ReadBytes(memberNumber4ForBid.rest, 12) IN IF ~bidTradingVolume4.ok THEN Fail ELSE
    LET bidTradingValue4 == ReadBytes(bidTradingVolume4.rest, 22) IN IF ~bidTradingValue4.ok THEN Fail ELSE
    LET memberNumber5ForAsk == ReadBytes(bidTradingValue4.rest, 5) IN IF ~memberNumber5ForAsk.ok THEN Fail ELSE
    LET askTradingVolume5 == ReadBytes(memberNumber5ForAsk.rest, 12) IN IF ~askTradingVolume5.ok THEN Fail ELSE
    LET askTradingValue5 == ReadBytes(askTradingVolume5.rest, 22) IN IF ~askTradingValue5.ok THEN Fail ELSE
    LET memberNumber5ForBid == ReadBytes(askTradingValue5.rest, 5) IN IF ~memberNumber5ForBid.ok THEN Fail ELSE
    LET bidTradingVolume5 == ReadBytes(memberNumber5ForBid.rest, 12) IN IF ~bidTradingVolume5.ok THEN Fail ELSE
    LET bidTradingValue5 == ReadBytes(bidTradingVolume5.rest, 22) IN IF ~bidTradingValue5.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(bidTradingValue5.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ isinCode                    |-> isinCode.value,
         aDesignatedNumberForAnIssue |-> aDesignatedNumberForAnIssue.value,
         memberNumber1ForAsk         |-> memberNumber1ForAsk.value,
         askTradingVolume1           |-> askTradingVolume1.value,
         askTradingValue1            |-> askTradingValue1.value,
         memberNumber1ForBid         |-> memberNumber1ForBid.value,
         bidTradingVolume1           |-> bidTradingVolume1.value,
         bidTradingValue1            |-> bidTradingValue1.value,
         memberNumber2ForAsk         |-> memberNumber2ForAsk.value,
         askTradingVolume2           |-> askTradingVolume2.value,
         askTradingValue2            |-> askTradingValue2.value,
         memberNumber2ForBid         |-> memberNumber2ForBid.value,
         bidTradingVolume2           |-> bidTradingVolume2.value,
         bidTradingValue2            |-> bidTradingValue2.value,
         memberNumber3ForAsk         |-> memberNumber3ForAsk.value,
         askTradingVolume3           |-> askTradingVolume3.value,
         askTradingValue3            |-> askTradingValue3.value,
         memberNumber3ForBid         |-> memberNumber3ForBid.value,
         bidTradingVolume3           |-> bidTradingVolume3.value,
         bidTradingValue3            |-> bidTradingValue3.value,
         memberNumber4ForAsk         |-> memberNumber4ForAsk.value,
         askTradingVolume4           |-> askTradingVolume4.value,
         askTradingValue4            |-> askTradingValue4.value,
         memberNumber4ForBid         |-> memberNumber4ForBid.value,
         bidTradingVolume4           |-> bidTradingVolume4.value,
         bidTradingValue4            |-> bidTradingValue4.value,
         memberNumber5ForAsk         |-> memberNumber5ForAsk.value,
         askTradingVolume5           |-> askTradingVolume5.value,
         askTradingValue5            |-> askTradingValue5.value,
         memberNumber5ForBid         |-> memberNumber5ForBid.value,
         bidTradingVolume5           |-> bidTradingVolume5.value,
         bidTradingValue5            |-> bidTradingValue5.value,
         endKeyword                  |-> endKeyword.value ], endKeyword.rest)

ZeroSecuritiesTopFiveTradersActivitiesMessage ==
    [ isinCode                    |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue |-> [i \in 1 .. 6 |-> 0],
      memberNumber1ForAsk         |-> [i \in 1 .. 5 |-> 0],
      askTradingVolume1           |-> [i \in 1 .. 12 |-> 0],
      askTradingValue1            |-> [i \in 1 .. 22 |-> 0],
      memberNumber1ForBid         |-> [i \in 1 .. 5 |-> 0],
      bidTradingVolume1           |-> [i \in 1 .. 12 |-> 0],
      bidTradingValue1            |-> [i \in 1 .. 22 |-> 0],
      memberNumber2ForAsk         |-> [i \in 1 .. 5 |-> 0],
      askTradingVolume2           |-> [i \in 1 .. 12 |-> 0],
      askTradingValue2            |-> [i \in 1 .. 22 |-> 0],
      memberNumber2ForBid         |-> [i \in 1 .. 5 |-> 0],
      bidTradingVolume2           |-> [i \in 1 .. 12 |-> 0],
      bidTradingValue2            |-> [i \in 1 .. 22 |-> 0],
      memberNumber3ForAsk         |-> [i \in 1 .. 5 |-> 0],
      askTradingVolume3           |-> [i \in 1 .. 12 |-> 0],
      askTradingValue3            |-> [i \in 1 .. 22 |-> 0],
      memberNumber3ForBid         |-> [i \in 1 .. 5 |-> 0],
      bidTradingVolume3           |-> [i \in 1 .. 12 |-> 0],
      bidTradingValue3            |-> [i \in 1 .. 22 |-> 0],
      memberNumber4ForAsk         |-> [i \in 1 .. 5 |-> 0],
      askTradingVolume4           |-> [i \in 1 .. 12 |-> 0],
      askTradingValue4            |-> [i \in 1 .. 22 |-> 0],
      memberNumber4ForBid         |-> [i \in 1 .. 5 |-> 0],
      bidTradingVolume4           |-> [i \in 1 .. 12 |-> 0],
      bidTradingValue4            |-> [i \in 1 .. 22 |-> 0],
      memberNumber5ForAsk         |-> [i \in 1 .. 5 |-> 0],
      askTradingVolume5           |-> [i \in 1 .. 12 |-> 0],
      askTradingValue5            |-> [i \in 1 .. 22 |-> 0],
      memberNumber5ForBid         |-> [i \in 1 .. 5 |-> 0],
      bidTradingVolume5           |-> [i \in 1 .. 12 |-> 0],
      bidTradingValue5            |-> [i \in 1 .. 22 |-> 0],
      endKeyword                  |-> [i \in 1 .. 1 |-> 0] ]

(* Securities Top Five Traders Activities Message at zero, then each field in turn at the values it is checked at *)
CheckedSecuritiesTopFiveTradersActivitiesMessage ==
    { ZeroSecuritiesTopFiveTradersActivitiesMessage }
        \cup { [ZeroSecuritiesTopFiveTradersActivitiesMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesTopFiveTradersActivitiesMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroSecuritiesTopFiveTradersActivitiesMessage EXCEPT !.memberNumber1ForAsk = one] : one \in Sample(5) }
        \cup { [ZeroSecuritiesTopFiveTradersActivitiesMessage EXCEPT !.askTradingVolume1 = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesTopFiveTradersActivitiesMessage EXCEPT !.askTradingValue1 = one] : one \in Sample(22) }
        \cup { [ZeroSecuritiesTopFiveTradersActivitiesMessage EXCEPT !.memberNumber1ForBid = one] : one \in Sample(5) }
        \cup { [ZeroSecuritiesTopFiveTradersActivitiesMessage EXCEPT !.bidTradingVolume1 = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesTopFiveTradersActivitiesMessage EXCEPT !.bidTradingValue1 = one] : one \in Sample(22) }
        \cup { [ZeroSecuritiesTopFiveTradersActivitiesMessage EXCEPT !.memberNumber2ForAsk = one] : one \in Sample(5) }
        \cup { [ZeroSecuritiesTopFiveTradersActivitiesMessage EXCEPT !.askTradingVolume2 = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesTopFiveTradersActivitiesMessage EXCEPT !.askTradingValue2 = one] : one \in Sample(22) }
        \cup { [ZeroSecuritiesTopFiveTradersActivitiesMessage EXCEPT !.memberNumber2ForBid = one] : one \in Sample(5) }
        \cup { [ZeroSecuritiesTopFiveTradersActivitiesMessage EXCEPT !.bidTradingVolume2 = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesTopFiveTradersActivitiesMessage EXCEPT !.bidTradingValue2 = one] : one \in Sample(22) }
        \cup { [ZeroSecuritiesTopFiveTradersActivitiesMessage EXCEPT !.memberNumber3ForAsk = one] : one \in Sample(5) }
        \cup { [ZeroSecuritiesTopFiveTradersActivitiesMessage EXCEPT !.askTradingVolume3 = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesTopFiveTradersActivitiesMessage EXCEPT !.askTradingValue3 = one] : one \in Sample(22) }
        \cup { [ZeroSecuritiesTopFiveTradersActivitiesMessage EXCEPT !.memberNumber3ForBid = one] : one \in Sample(5) }
        \cup { [ZeroSecuritiesTopFiveTradersActivitiesMessage EXCEPT !.bidTradingVolume3 = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesTopFiveTradersActivitiesMessage EXCEPT !.bidTradingValue3 = one] : one \in Sample(22) }
        \cup { [ZeroSecuritiesTopFiveTradersActivitiesMessage EXCEPT !.memberNumber4ForAsk = one] : one \in Sample(5) }
        \cup { [ZeroSecuritiesTopFiveTradersActivitiesMessage EXCEPT !.askTradingVolume4 = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesTopFiveTradersActivitiesMessage EXCEPT !.askTradingValue4 = one] : one \in Sample(22) }
        \cup { [ZeroSecuritiesTopFiveTradersActivitiesMessage EXCEPT !.memberNumber4ForBid = one] : one \in Sample(5) }
        \cup { [ZeroSecuritiesTopFiveTradersActivitiesMessage EXCEPT !.bidTradingVolume4 = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesTopFiveTradersActivitiesMessage EXCEPT !.bidTradingValue4 = one] : one \in Sample(22) }
        \cup { [ZeroSecuritiesTopFiveTradersActivitiesMessage EXCEPT !.memberNumber5ForAsk = one] : one \in Sample(5) }
        \cup { [ZeroSecuritiesTopFiveTradersActivitiesMessage EXCEPT !.askTradingVolume5 = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesTopFiveTradersActivitiesMessage EXCEPT !.askTradingValue5 = one] : one \in Sample(22) }
        \cup { [ZeroSecuritiesTopFiveTradersActivitiesMessage EXCEPT !.memberNumber5ForBid = one] : one \in Sample(5) }
        \cup { [ZeroSecuritiesTopFiveTradersActivitiesMessage EXCEPT !.bidTradingVolume5 = one] : one \in Sample(12) }
        \cup { [ZeroSecuritiesTopFiveTradersActivitiesMessage EXCEPT !.bidTradingValue5 = one] : one \in Sample(22) }
        \cup { [ZeroSecuritiesTopFiveTradersActivitiesMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

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
SecuritiesQuoteMmLpExcludedMessageCode == <<66, 54, 48, 49, 83>>  \* "B601S"
SecuritiesQuoteMmLpExcludedMessageCode2 == <<66, 54, 48, 49, 81>>  \* "B601Q"
SecuritiesQuoteMmLpExcludedMessageCode3 == <<66, 54, 48, 49, 88>>  \* "B601X"
SecuritiesQuoteMmLpIncludedMessageCode == <<66, 55, 48, 50, 83>>  \* "B702S"
SecuritiesQuoteMmLpIncludedMessageCode2 == <<66, 55, 48, 51, 83>>  \* "B703S"
SecuritiesQuoteMmLpIncludedMessageCode3 == <<66, 55, 48, 52, 83>>  \* "B704S"
SecuritiesQuoteMmLpIncludedMessageCode4 == <<66, 55, 48, 53, 83>>  \* "B705S"
SecuritiesSnapshotMmLpExcludedMessageCode == <<66, 50, 48, 49, 83>>  \* "B201S"
SecuritiesSnapshotMmLpExcludedMessageCode2 == <<66, 50, 48, 49, 81>>  \* "B201Q"
SecuritiesSnapshotMmLpIncludedMessageCode == <<66, 50, 48, 50, 83>>  \* "B202S"
SecuritiesSnapshotMmLpIncludedMessageCode2 == <<66, 50, 48, 51, 83>>  \* "B203S"
SecuritiesSnapshotMmLpIncludedMessageCode3 == <<66, 50, 48, 52, 83>>  \* "B204S"
SecuritiesSnapshotMmLpIncludedMessageCode4 == <<66, 50, 48, 53, 83>>  \* "B205S"
SecuritiesOrderFilledMessageCode == <<65, 51, 48, 49, 83>>  \* "A301S"
SecuritiesOrderFilledMessageCode2 == <<65, 51, 48, 50, 83>>  \* "A302S"
SecuritiesOrderFilledMessageCode3 == <<65, 51, 48, 51, 83>>  \* "A303S"
SecuritiesOrderFilledMessageCode4 == <<65, 51, 48, 52, 83>>  \* "A304S"
SecuritiesOrderFilledMessageCode5 == <<65, 51, 48, 53, 83>>  \* "A305S"
SecuritiesOrderFilledMessageCode6 == <<65, 51, 48, 49, 81>>  \* "A301Q"
SecuritiesOrderFilledMessageCode7 == <<65, 51, 48, 49, 88>>  \* "A301X"
SecuritiesNegotiatedTradeMessageCode == <<67, 52, 48, 49, 83>>  \* "C401S"
SecuritiesNegotiatedTradeMessageCode2 == <<67, 52, 48, 50, 83>>  \* "C402S"
SecuritiesNegotiatedTradeMessageCode3 == <<67, 52, 48, 51, 83>>  \* "C403S"
SecuritiesNegotiatedTradeMessageCode4 == <<67, 52, 48, 52, 83>>  \* "C404S"
SecuritiesNegotiatedTradeMessageCode5 == <<67, 52, 48, 53, 83>>  \* "C405S"
SecuritiesNegotiatedTradeMessageCode6 == <<67, 52, 48, 49, 81>>  \* "C401Q"
SecuritiesNegotiatedTradeMessageCode7 == <<67, 52, 48, 49, 88>>  \* "C401X"
SecuritiesMarketOperationTsMessageCode == <<65, 55, 48, 49, 83>>  \* "A701S"
SecuritiesMarketOperationTsMessageCode2 == <<65, 55, 48, 50, 83>>  \* "A702S"
SecuritiesMarketOperationTsMessageCode3 == <<65, 55, 48, 51, 83>>  \* "A703S"
SecuritiesMarketOperationTsMessageCode4 == <<65, 55, 48, 52, 83>>  \* "A704S"
SecuritiesMarketOperationTsMessageCode5 == <<65, 55, 48, 53, 83>>  \* "A705S"
SecuritiesMarketOperationTsMessageCode6 == <<65, 55, 48, 49, 81>>  \* "A701Q"
SecuritiesMarketOperationTsMessageCode7 == <<65, 55, 48, 49, 88>>  \* "A701X"
SecuritiesMarketOperationTsMessageCode8 == <<65, 55, 48, 49, 66>>  \* "A701B"
SecuritiesMarketOperationTsMessageCode9 == <<65, 55, 48, 49, 77>>  \* "A701M"
SecuritiesMarketOperationTsMessageCode10 == <<65, 55, 48, 49, 75>>  \* "A701K"
SecuritiesMarketOperationTsMessageCode11 == <<65, 55, 48, 49, 82>>  \* "A701R"
SecuritiesMarketOperationTsMessageCode12 == <<65, 55, 48, 49, 70>>  \* "A701F"
SecuritiesMarketOperationTsMessageCode13 == <<65, 55, 48, 50, 70>>  \* "A702F"
SecuritiesMarketOperationTsMessageCode14 == <<65, 55, 48, 51, 70>>  \* "A703F"
SecuritiesMarketOperationTsMessageCode15 == <<65, 55, 48, 52, 70>>  \* "A704F"
SecuritiesMarketOperationTsMessageCode16 == <<65, 55, 48, 53, 70>>  \* "A705F"
SecuritiesMarketOperationTsMessageCode17 == <<65, 55, 48, 54, 70>>  \* "A706F"
SecuritiesMarketOperationTsMessageCode18 == <<65, 55, 48, 55, 70>>  \* "A707F"
SecuritiesMarketOperationTsMessageCode19 == <<65, 55, 48, 56, 70>>  \* "A708F"
SecuritiesMarketOperationTsMessageCode20 == <<65, 55, 48, 57, 70>>  \* "A709F"
SecuritiesMarketOperationTsMessageCode21 == <<65, 55, 49, 48, 70>>  \* "A710F"
SecuritiesMarketOperationTsMessageCode22 == <<65, 55, 49, 49, 70>>  \* "A711F"
SecuritiesMarketOperationTsMessageCode23 == <<65, 55, 49, 50, 70>>  \* "A712F"
SecuritiesMarketOperationTsMessageCode24 == <<65, 55, 49, 51, 70>>  \* "A713F"
SecuritiesMarketOperationTsMessageCode25 == <<65, 55, 49, 53, 70>>  \* "A715F"
SecuritiesMarketOperationTsMessageCode26 == <<65, 55, 49, 54, 70>>  \* "A716F"
SecuritiesMarketOperationTsMessageCode27 == <<65, 55, 49, 55, 70>>  \* "A717F"
SecuritiesMarketOperationTsMessageCode28 == <<65, 55, 49, 56, 70>>  \* "A718F"
SecuritiesMarketOperationTsMessageCode29 == <<65, 55, 48, 49, 71>>  \* "A701G"
SecuritiesMarketOperationTsMessageCode30 == <<65, 55, 48, 49, 69>>  \* "A701E"
SecuritiesDeterminationOfBasePriceMessageCode == <<65, 52, 48, 49, 83>>  \* "A401S"
SecuritiesDeterminationOfBasePriceMessageCode2 == <<65, 52, 48, 51, 83>>  \* "A403S"
SecuritiesDeterminationOfBasePriceMessageCode3 == <<65, 52, 48, 52, 83>>  \* "A404S"
SecuritiesDeterminationOfBasePriceMessageCode4 == <<65, 52, 48, 53, 83>>  \* "A405S"
SecuritiesDeterminationOfBasePriceMessageCode5 == <<65, 52, 48, 49, 81>>  \* "A401Q"
SecuritiesDeterminationOfBasePriceMessageCode6 == <<65, 52, 48, 49, 88>>  \* "A401X"
SecuritiesIssueClosingMessageCode == <<65, 54, 48, 49, 83>>  \* "A601S"
SecuritiesIssueClosingMessageCode2 == <<65, 54, 48, 50, 83>>  \* "A602S"
SecuritiesIssueClosingMessageCode3 == <<65, 54, 48, 51, 83>>  \* "A603S"
SecuritiesIssueClosingMessageCode4 == <<65, 54, 48, 52, 83>>  \* "A604S"
SecuritiesIssueClosingMessageCode5 == <<65, 54, 48, 53, 83>>  \* "A605S"
SecuritiesIssueClosingMessageCode6 == <<65, 54, 48, 49, 81>>  \* "A601Q"
SecuritiesIssueClosingMessageCode7 == <<65, 54, 48, 49, 88>>  \* "A601X"
SecuritiesIssueClosingMessageCode8 == <<65, 54, 48, 49, 71>>  \* "A601G"
SecuritiesIssueClosingMessageCode9 == <<65, 54, 48, 49, 69>>  \* "A601E"
SecuritiesMarketOperationScheduleMessageCode == <<77, 52, 48, 49, 83>>  \* "M401S"
SecuritiesMarketOperationScheduleMessageCode2 == <<77, 52, 48, 50, 83>>  \* "M402S"
SecuritiesMarketOperationScheduleMessageCode3 == <<77, 52, 48, 51, 83>>  \* "M403S"
SecuritiesMarketOperationScheduleMessageCode4 == <<77, 52, 48, 52, 83>>  \* "M404S"
SecuritiesMarketOperationScheduleMessageCode5 == <<77, 52, 48, 53, 83>>  \* "M405S"
SecuritiesMarketOperationScheduleMessageCode6 == <<77, 52, 48, 49, 81>>  \* "M401Q"
SecuritiesMarketOperationScheduleMessageCode7 == <<77, 52, 48, 49, 88>>  \* "M401X"
SecuritiesMarketOperationScheduleMessageCode8 == <<77, 52, 48, 49, 66>>  \* "M401B"
SecuritiesMarketOperationScheduleMessageCode9 == <<77, 52, 48, 49, 77>>  \* "M401M"
SecuritiesMarketOperationScheduleMessageCode10 == <<77, 52, 48, 49, 75>>  \* "M401K"
SecuritiesMarketOperationScheduleMessageCode11 == <<77, 52, 48, 49, 82>>  \* "M401R"
SecuritiesMarketOperationScheduleMessageCode12 == <<77, 52, 48, 49, 70>>  \* "M401F"
SecuritiesMarketOperationScheduleMessageCode13 == <<77, 52, 48, 50, 70>>  \* "M402F"
SecuritiesMarketOperationScheduleMessageCode14 == <<77, 52, 48, 51, 70>>  \* "M403F"
SecuritiesMarketOperationScheduleMessageCode15 == <<77, 52, 48, 52, 70>>  \* "M404F"
SecuritiesMarketOperationScheduleMessageCode16 == <<77, 52, 48, 53, 70>>  \* "M405F"
SecuritiesMarketOperationScheduleMessageCode17 == <<77, 52, 48, 54, 70>>  \* "M406F"
SecuritiesMarketOperationScheduleMessageCode18 == <<77, 52, 48, 55, 70>>  \* "M407F"
SecuritiesMarketOperationScheduleMessageCode19 == <<77, 52, 48, 56, 70>>  \* "M408F"
SecuritiesMarketOperationScheduleMessageCode20 == <<77, 52, 48, 57, 70>>  \* "M409F"
SecuritiesMarketOperationScheduleMessageCode21 == <<77, 52, 49, 48, 70>>  \* "M410F"
SecuritiesMarketOperationScheduleMessageCode22 == <<77, 52, 49, 49, 70>>  \* "M411F"
SecuritiesMarketOperationScheduleMessageCode23 == <<77, 52, 49, 50, 70>>  \* "M412F"
SecuritiesMarketOperationScheduleMessageCode24 == <<77, 52, 49, 51, 70>>  \* "M413F"
SecuritiesMarketOperationScheduleMessageCode25 == <<77, 52, 49, 53, 70>>  \* "M415F"
SecuritiesMarketOperationScheduleMessageCode26 == <<77, 52, 49, 54, 70>>  \* "M416F"
SecuritiesMarketOperationScheduleMessageCode27 == <<77, 52, 49, 55, 70>>  \* "M417F"
SecuritiesMarketOperationScheduleMessageCode28 == <<77, 52, 49, 56, 70>>  \* "M418F"
SecuritiesMarketOperationScheduleMessageCode29 == <<77, 52, 48, 49, 71>>  \* "M401G"
SecuritiesMarketOperationScheduleMessageCode30 == <<77, 52, 48, 49, 69>>  \* "M401E"
SecuritiesRandomEndMessageCode == <<65, 53, 48, 49, 88>>  \* "A501X"
SecuritiesRandomEndMessageCode2 == <<65, 53, 48, 49, 71>>  \* "A501G"
SecuritiesTriggeringViMessageCode == <<82, 56, 48, 49, 83>>  \* "R801S"
SecuritiesTriggeringViMessageCode2 == <<82, 56, 48, 51, 83>>  \* "R803S"
SecuritiesTriggeringViMessageCode3 == <<82, 56, 48, 52, 83>>  \* "R804S"
SecuritiesTriggeringViMessageCode4 == <<82, 56, 48, 53, 83>>  \* "R805S"
SecuritiesTriggeringViMessageCode5 == <<82, 56, 48, 49, 81>>  \* "R801Q"
SecuritiesQuantityAllocationMessageCode == <<79, 54, 48, 49, 83>>  \* "O601S"
SecuritiesQuantityAllocationMessageCode2 == <<79, 54, 48, 51, 83>>  \* "O603S"
SecuritiesQuantityAllocationMessageCode3 == <<79, 54, 48, 52, 83>>  \* "O604S"
SecuritiesQuantityAllocationMessageCode4 == <<79, 54, 48, 53, 83>>  \* "O605S"
SecuritiesQuantityAllocationMessageCode5 == <<79, 54, 48, 49, 81>>  \* "O601Q"
SecuritiesQuantityAllocationMessageCode6 == <<79, 54, 48, 49, 88>>  \* "O601X"
SecuritiesQuantityAllocationMessageCode7 == <<79, 54, 48, 49, 70>>  \* "O601F"
SecuritiesQuantityAllocationMessageCode8 == <<79, 54, 48, 50, 70>>  \* "O602F"
SecuritiesQuantityAllocationMessageCode9 == <<79, 54, 48, 51, 70>>  \* "O603F"
SecuritiesQuantityAllocationMessageCode10 == <<79, 54, 48, 52, 70>>  \* "O604F"
SecuritiesQuantityAllocationMessageCode11 == <<79, 54, 48, 53, 70>>  \* "O605F"
SecuritiesQuantityAllocationMessageCode12 == <<79, 54, 48, 54, 70>>  \* "O606F"
SecuritiesQuantityAllocationMessageCode13 == <<79, 54, 48, 55, 70>>  \* "O607F"
SecuritiesQuantityAllocationMessageCode14 == <<79, 54, 48, 56, 70>>  \* "O608F"
SecuritiesQuantityAllocationMessageCode15 == <<79, 54, 48, 57, 70>>  \* "O609F"
SecuritiesQuantityAllocationMessageCode16 == <<79, 54, 49, 48, 70>>  \* "O610F"
SecuritiesQuantityAllocationMessageCode17 == <<79, 54, 49, 49, 70>>  \* "O611F"
SecuritiesQuantityAllocationMessageCode18 == <<79, 54, 49, 50, 70>>  \* "O612F"
SecuritiesQuantityAllocationMessageCode19 == <<79, 54, 49, 51, 70>>  \* "O613F"
SecuritiesQuantityAllocationMessageCode20 == <<79, 54, 49, 53, 70>>  \* "O615F"
SecuritiesQuantityAllocationMessageCode21 == <<79, 54, 49, 54, 70>>  \* "O616F"
SecuritiesQuantityAllocationMessageCode22 == <<79, 54, 49, 55, 70>>  \* "O617F"
SecuritiesQuantityAllocationMessageCode23 == <<79, 54, 49, 56, 70>>  \* "O618F"
SecuritiesMemberFirmSanctionsMessageCode == <<82, 51, 48, 49, 83>>  \* "R301S"
SecuritiesMemberFirmSanctionsMessageCode2 == <<82, 51, 48, 50, 83>>  \* "R302S"
SecuritiesMemberFirmSanctionsMessageCode3 == <<82, 51, 48, 51, 83>>  \* "R303S"
SecuritiesMemberFirmSanctionsMessageCode4 == <<82, 51, 48, 52, 83>>  \* "R304S"
SecuritiesMemberFirmSanctionsMessageCode5 == <<82, 51, 48, 53, 83>>  \* "R305S"
SecuritiesMemberFirmSanctionsMessageCode6 == <<82, 51, 48, 49, 81>>  \* "R301Q"
SecuritiesMemberFirmSanctionsMessageCode7 == <<82, 51, 48, 49, 88>>  \* "R301X"
SecuritiesMemberFirmSanctionsMessageCode8 == <<82, 51, 48, 49, 66>>  \* "R301B"
SecuritiesMemberFirmSanctionsMessageCode9 == <<82, 51, 48, 49, 77>>  \* "R301M"
SecuritiesMemberFirmSanctionsMessageCode10 == <<82, 51, 48, 49, 75>>  \* "R301K"
SecuritiesMemberFirmSanctionsMessageCode11 == <<82, 51, 48, 49, 82>>  \* "R301R"
SecuritiesEquitiesChangesOfBatchDataMessageCode == <<65, 56, 48, 49, 83>>  \* "A801S"
SecuritiesEquitiesChangesOfBatchDataMessageCode2 == <<65, 56, 48, 50, 83>>  \* "A802S"
SecuritiesEquitiesChangesOfBatchDataMessageCode3 == <<65, 56, 48, 51, 83>>  \* "A803S"
SecuritiesEquitiesChangesOfBatchDataMessageCode4 == <<65, 56, 48, 52, 83>>  \* "A804S"
SecuritiesEquitiesChangesOfBatchDataMessageCode5 == <<65, 56, 48, 53, 83>>  \* "A805S"
SecuritiesEquitiesChangesOfBatchDataMessageCode6 == <<65, 56, 48, 49, 81>>  \* "A801Q"
SecuritiesEquitiesChangesOfBatchDataMessageCode7 == <<65, 56, 48, 49, 88>>  \* "A801X"
SecuritiesGroupOrderAcceptanceHaltMessageCode == <<73, 70, 48, 49, 83>>  \* "IF01S"
SecuritiesGroupOrderAcceptanceHaltMessageCode2 == <<73, 70, 48, 50, 83>>  \* "IF02S"
SecuritiesGroupOrderAcceptanceHaltMessageCode3 == <<73, 70, 48, 51, 83>>  \* "IF03S"
SecuritiesGroupOrderAcceptanceHaltMessageCode4 == <<73, 70, 48, 52, 83>>  \* "IF04S"
SecuritiesGroupOrderAcceptanceHaltMessageCode5 == <<73, 70, 48, 53, 83>>  \* "IF05S"
SecuritiesGroupOrderAcceptanceHaltMessageCode6 == <<73, 70, 48, 49, 81>>  \* "IF01Q"
SecuritiesGroupOrderAcceptanceHaltMessageCode7 == <<73, 70, 48, 49, 70>>  \* "IF01F"
SecuritiesGroupOrderAcceptanceHaltMessageCode8 == <<73, 70, 48, 50, 70>>  \* "IF02F"
SecuritiesGroupOrderAcceptanceHaltMessageCode9 == <<73, 70, 48, 51, 70>>  \* "IF03F"
SecuritiesGroupOrderAcceptanceHaltMessageCode10 == <<73, 70, 48, 52, 70>>  \* "IF04F"
SecuritiesGroupOrderAcceptanceHaltMessageCode11 == <<73, 70, 48, 53, 70>>  \* "IF05F"
SecuritiesGroupOrderAcceptanceHaltMessageCode12 == <<73, 70, 48, 54, 70>>  \* "IF06F"
SecuritiesGroupOrderAcceptanceHaltMessageCode13 == <<73, 70, 48, 55, 70>>  \* "IF07F"
SecuritiesGroupOrderAcceptanceHaltMessageCode14 == <<73, 70, 48, 56, 70>>  \* "IF08F"
SecuritiesGroupOrderAcceptanceHaltMessageCode15 == <<73, 70, 48, 57, 70>>  \* "IF09F"
SecuritiesGroupOrderAcceptanceHaltMessageCode16 == <<73, 70, 49, 48, 70>>  \* "IF10F"
SecuritiesGroupOrderAcceptanceHaltMessageCode17 == <<73, 70, 49, 49, 70>>  \* "IF11F"
SecuritiesGroupOrderAcceptanceHaltMessageCode18 == <<73, 70, 49, 50, 70>>  \* "IF12F"
SecuritiesGroupOrderAcceptanceHaltMessageCode19 == <<73, 70, 49, 51, 70>>  \* "IF13F"
SecuritiesGroupOrderAcceptanceHaltMessageCode20 == <<73, 70, 49, 53, 70>>  \* "IF15F"
SecuritiesGroupOrderAcceptanceHaltMessageCode21 == <<73, 70, 49, 54, 70>>  \* "IF16F"
SecuritiesGroupOrderAcceptanceHaltMessageCode22 == <<73, 70, 49, 55, 70>>  \* "IF17F"
SecuritiesGroupOrderAcceptanceHaltMessageCode23 == <<73, 70, 49, 56, 70>>  \* "IF18F"
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
SecuritiesElwBatchDataMessageCode == <<65, 49, 48, 50, 83>>  \* "A102S"
SecuritiesEtnBatchDataMessageCode == <<65, 49, 48, 52, 83>>  \* "A104S"
SecuritiesEtnEarlyRedemptionMessageCode == <<88, 51, 48, 52, 83>>  \* "X304S"
SecuritiesEtpConstituentsMessageCode == <<86, 54, 48, 48, 83>>  \* "V600S"
SecuritiesKnockOutElwMessageCode == <<77, 54, 48, 50, 83>>  \* "M602S"
SecuritiesKnockOutUnderlyingMessageCode == <<77, 53, 48, 50, 83>>  \* "M502S"
SecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessageCode == <<66, 56, 48, 49, 83>>  \* "B801S"
SecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessageCode2 == <<66, 56, 48, 49, 81>>  \* "B801Q"
SecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessageCode3 == <<66, 56, 48, 49, 88>>  \* "B801X"
SecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessageCode4 == <<66, 56, 48, 51, 83>>  \* "B803S"
SecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessageCode5 == <<66, 56, 48, 52, 83>>  \* "B804S"
SecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessageCode6 == <<66, 56, 48, 53, 83>>  \* "B805S"
SecuritiesABloxTradeQuotesMessageCode == <<73, 69, 48, 49, 83>>  \* "IE01S"
SecuritiesABloxTradeQuotesMessageCode2 == <<73, 69, 48, 49, 81>>  \* "IE01Q"
SecuritiesABloxTradeQuotesMessageCode3 == <<73, 69, 48, 51, 83>>  \* "IE03S"
SecuritiesABloxTradeQuotesMessageCode4 == <<73, 69, 48, 52, 83>>  \* "IE04S"
SecuritiesABloxTradeQuotesMessageCode5 == <<73, 69, 48, 53, 83>>  \* "IE05S"
SecuritiesEtnProfitStructureMessageCode == <<88, 56, 48, 52, 83>>  \* "X804S"
SecuritiesTopFiveTradersActivitiesMessageCode == <<66, 57, 48, 49, 83>>  \* "B901S"
SecuritiesTopFiveTradersActivitiesMessageCode2 == <<66, 57, 48, 49, 81>>  \* "B901Q"
SecuritiesTopFiveTradersActivitiesMessageCode3 == <<66, 57, 48, 49, 88>>  \* "B901X"
SecuritiesTopFiveTradersActivitiesMessageCode4 == <<66, 57, 48, 50, 83>>  \* "B902S"
SecuritiesTopFiveTradersActivitiesMessageCode5 == <<66, 57, 48, 51, 83>>  \* "B903S"
SecuritiesTopFiveTradersActivitiesMessageCode6 == <<66, 57, 48, 52, 83>>  \* "B904S"
SecuritiesTopFiveTradersActivitiesMessageCode7 == <<66, 57, 48, 53, 83>>  \* "B905S"
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
        \cup [ tag : {SecuritiesQuoteMmLpExcludedMessageCode}, body : SecuritiesQuoteMmLpExcludedMessage ]
        \cup [ tag : {SecuritiesQuoteMmLpExcludedMessageCode2}, body : SecuritiesQuoteMmLpExcludedMessage ]
        \cup [ tag : {SecuritiesQuoteMmLpExcludedMessageCode3}, body : SecuritiesQuoteMmLpExcludedMessage ]
        \cup [ tag : {SecuritiesQuoteMmLpIncludedMessageCode}, body : SecuritiesQuoteMmLpIncludedMessage ]
        \cup [ tag : {SecuritiesQuoteMmLpIncludedMessageCode2}, body : SecuritiesQuoteMmLpIncludedMessage ]
        \cup [ tag : {SecuritiesQuoteMmLpIncludedMessageCode3}, body : SecuritiesQuoteMmLpIncludedMessage ]
        \cup [ tag : {SecuritiesQuoteMmLpIncludedMessageCode4}, body : SecuritiesQuoteMmLpIncludedMessage ]
        \cup [ tag : {SecuritiesSnapshotMmLpExcludedMessageCode}, body : SecuritiesSnapshotMmLpExcludedMessage ]
        \cup [ tag : {SecuritiesSnapshotMmLpExcludedMessageCode2}, body : SecuritiesSnapshotMmLpExcludedMessage ]
        \cup [ tag : {SecuritiesSnapshotMmLpIncludedMessageCode}, body : SecuritiesSnapshotMmLpIncludedMessage ]
        \cup [ tag : {SecuritiesSnapshotMmLpIncludedMessageCode2}, body : SecuritiesSnapshotMmLpIncludedMessage ]
        \cup [ tag : {SecuritiesSnapshotMmLpIncludedMessageCode3}, body : SecuritiesSnapshotMmLpIncludedMessage ]
        \cup [ tag : {SecuritiesSnapshotMmLpIncludedMessageCode4}, body : SecuritiesSnapshotMmLpIncludedMessage ]
        \cup [ tag : {SecuritiesOrderFilledMessageCode}, body : SecuritiesOrderFilledMessage ]
        \cup [ tag : {SecuritiesOrderFilledMessageCode2}, body : SecuritiesOrderFilledMessage ]
        \cup [ tag : {SecuritiesOrderFilledMessageCode3}, body : SecuritiesOrderFilledMessage ]
        \cup [ tag : {SecuritiesOrderFilledMessageCode4}, body : SecuritiesOrderFilledMessage ]
        \cup [ tag : {SecuritiesOrderFilledMessageCode5}, body : SecuritiesOrderFilledMessage ]
        \cup [ tag : {SecuritiesOrderFilledMessageCode6}, body : SecuritiesOrderFilledMessage ]
        \cup [ tag : {SecuritiesOrderFilledMessageCode7}, body : SecuritiesOrderFilledMessage ]
        \cup [ tag : {SecuritiesNegotiatedTradeMessageCode}, body : SecuritiesNegotiatedTradeMessage ]
        \cup [ tag : {SecuritiesNegotiatedTradeMessageCode2}, body : SecuritiesNegotiatedTradeMessage ]
        \cup [ tag : {SecuritiesNegotiatedTradeMessageCode3}, body : SecuritiesNegotiatedTradeMessage ]
        \cup [ tag : {SecuritiesNegotiatedTradeMessageCode4}, body : SecuritiesNegotiatedTradeMessage ]
        \cup [ tag : {SecuritiesNegotiatedTradeMessageCode5}, body : SecuritiesNegotiatedTradeMessage ]
        \cup [ tag : {SecuritiesNegotiatedTradeMessageCode6}, body : SecuritiesNegotiatedTradeMessage ]
        \cup [ tag : {SecuritiesNegotiatedTradeMessageCode7}, body : SecuritiesNegotiatedTradeMessage ]
        \cup [ tag : {SecuritiesMarketOperationTsMessageCode}, body : SecuritiesMarketOperationTsMessage ]
        \cup [ tag : {SecuritiesMarketOperationTsMessageCode2}, body : SecuritiesMarketOperationTsMessage ]
        \cup [ tag : {SecuritiesMarketOperationTsMessageCode3}, body : SecuritiesMarketOperationTsMessage ]
        \cup [ tag : {SecuritiesMarketOperationTsMessageCode4}, body : SecuritiesMarketOperationTsMessage ]
        \cup [ tag : {SecuritiesMarketOperationTsMessageCode5}, body : SecuritiesMarketOperationTsMessage ]
        \cup [ tag : {SecuritiesMarketOperationTsMessageCode6}, body : SecuritiesMarketOperationTsMessage ]
        \cup [ tag : {SecuritiesMarketOperationTsMessageCode7}, body : SecuritiesMarketOperationTsMessage ]
        \cup [ tag : {SecuritiesMarketOperationTsMessageCode8}, body : SecuritiesMarketOperationTsMessage ]
        \cup [ tag : {SecuritiesMarketOperationTsMessageCode9}, body : SecuritiesMarketOperationTsMessage ]
        \cup [ tag : {SecuritiesMarketOperationTsMessageCode10}, body : SecuritiesMarketOperationTsMessage ]
        \cup [ tag : {SecuritiesMarketOperationTsMessageCode11}, body : SecuritiesMarketOperationTsMessage ]
        \cup [ tag : {SecuritiesMarketOperationTsMessageCode12}, body : SecuritiesMarketOperationTsMessage ]
        \cup [ tag : {SecuritiesMarketOperationTsMessageCode13}, body : SecuritiesMarketOperationTsMessage ]
        \cup [ tag : {SecuritiesMarketOperationTsMessageCode14}, body : SecuritiesMarketOperationTsMessage ]
        \cup [ tag : {SecuritiesMarketOperationTsMessageCode15}, body : SecuritiesMarketOperationTsMessage ]
        \cup [ tag : {SecuritiesMarketOperationTsMessageCode16}, body : SecuritiesMarketOperationTsMessage ]
        \cup [ tag : {SecuritiesMarketOperationTsMessageCode17}, body : SecuritiesMarketOperationTsMessage ]
        \cup [ tag : {SecuritiesMarketOperationTsMessageCode18}, body : SecuritiesMarketOperationTsMessage ]
        \cup [ tag : {SecuritiesMarketOperationTsMessageCode19}, body : SecuritiesMarketOperationTsMessage ]
        \cup [ tag : {SecuritiesMarketOperationTsMessageCode20}, body : SecuritiesMarketOperationTsMessage ]
        \cup [ tag : {SecuritiesMarketOperationTsMessageCode21}, body : SecuritiesMarketOperationTsMessage ]
        \cup [ tag : {SecuritiesMarketOperationTsMessageCode22}, body : SecuritiesMarketOperationTsMessage ]
        \cup [ tag : {SecuritiesMarketOperationTsMessageCode23}, body : SecuritiesMarketOperationTsMessage ]
        \cup [ tag : {SecuritiesMarketOperationTsMessageCode24}, body : SecuritiesMarketOperationTsMessage ]
        \cup [ tag : {SecuritiesMarketOperationTsMessageCode25}, body : SecuritiesMarketOperationTsMessage ]
        \cup [ tag : {SecuritiesMarketOperationTsMessageCode26}, body : SecuritiesMarketOperationTsMessage ]
        \cup [ tag : {SecuritiesMarketOperationTsMessageCode27}, body : SecuritiesMarketOperationTsMessage ]
        \cup [ tag : {SecuritiesMarketOperationTsMessageCode28}, body : SecuritiesMarketOperationTsMessage ]
        \cup [ tag : {SecuritiesMarketOperationTsMessageCode29}, body : SecuritiesMarketOperationTsMessage ]
        \cup [ tag : {SecuritiesMarketOperationTsMessageCode30}, body : SecuritiesMarketOperationTsMessage ]
        \cup [ tag : {SecuritiesDeterminationOfBasePriceMessageCode}, body : SecuritiesDeterminationOfBasePriceMessage ]
        \cup [ tag : {SecuritiesDeterminationOfBasePriceMessageCode2}, body : SecuritiesDeterminationOfBasePriceMessage ]
        \cup [ tag : {SecuritiesDeterminationOfBasePriceMessageCode3}, body : SecuritiesDeterminationOfBasePriceMessage ]
        \cup [ tag : {SecuritiesDeterminationOfBasePriceMessageCode4}, body : SecuritiesDeterminationOfBasePriceMessage ]
        \cup [ tag : {SecuritiesDeterminationOfBasePriceMessageCode5}, body : SecuritiesDeterminationOfBasePriceMessage ]
        \cup [ tag : {SecuritiesDeterminationOfBasePriceMessageCode6}, body : SecuritiesDeterminationOfBasePriceMessage ]
        \cup [ tag : {SecuritiesIssueClosingMessageCode}, body : SecuritiesIssueClosingMessage ]
        \cup [ tag : {SecuritiesIssueClosingMessageCode2}, body : SecuritiesIssueClosingMessage ]
        \cup [ tag : {SecuritiesIssueClosingMessageCode3}, body : SecuritiesIssueClosingMessage ]
        \cup [ tag : {SecuritiesIssueClosingMessageCode4}, body : SecuritiesIssueClosingMessage ]
        \cup [ tag : {SecuritiesIssueClosingMessageCode5}, body : SecuritiesIssueClosingMessage ]
        \cup [ tag : {SecuritiesIssueClosingMessageCode6}, body : SecuritiesIssueClosingMessage ]
        \cup [ tag : {SecuritiesIssueClosingMessageCode7}, body : SecuritiesIssueClosingMessage ]
        \cup [ tag : {SecuritiesIssueClosingMessageCode8}, body : SecuritiesIssueClosingMessage ]
        \cup [ tag : {SecuritiesIssueClosingMessageCode9}, body : SecuritiesIssueClosingMessage ]
        \cup [ tag : {SecuritiesMarketOperationScheduleMessageCode}, body : SecuritiesMarketOperationScheduleMessage ]
        \cup [ tag : {SecuritiesMarketOperationScheduleMessageCode2}, body : SecuritiesMarketOperationScheduleMessage ]
        \cup [ tag : {SecuritiesMarketOperationScheduleMessageCode3}, body : SecuritiesMarketOperationScheduleMessage ]
        \cup [ tag : {SecuritiesMarketOperationScheduleMessageCode4}, body : SecuritiesMarketOperationScheduleMessage ]
        \cup [ tag : {SecuritiesMarketOperationScheduleMessageCode5}, body : SecuritiesMarketOperationScheduleMessage ]
        \cup [ tag : {SecuritiesMarketOperationScheduleMessageCode6}, body : SecuritiesMarketOperationScheduleMessage ]
        \cup [ tag : {SecuritiesMarketOperationScheduleMessageCode7}, body : SecuritiesMarketOperationScheduleMessage ]
        \cup [ tag : {SecuritiesMarketOperationScheduleMessageCode8}, body : SecuritiesMarketOperationScheduleMessage ]
        \cup [ tag : {SecuritiesMarketOperationScheduleMessageCode9}, body : SecuritiesMarketOperationScheduleMessage ]
        \cup [ tag : {SecuritiesMarketOperationScheduleMessageCode10}, body : SecuritiesMarketOperationScheduleMessage ]
        \cup [ tag : {SecuritiesMarketOperationScheduleMessageCode11}, body : SecuritiesMarketOperationScheduleMessage ]
        \cup [ tag : {SecuritiesMarketOperationScheduleMessageCode12}, body : SecuritiesMarketOperationScheduleMessage ]
        \cup [ tag : {SecuritiesMarketOperationScheduleMessageCode13}, body : SecuritiesMarketOperationScheduleMessage ]
        \cup [ tag : {SecuritiesMarketOperationScheduleMessageCode14}, body : SecuritiesMarketOperationScheduleMessage ]
        \cup [ tag : {SecuritiesMarketOperationScheduleMessageCode15}, body : SecuritiesMarketOperationScheduleMessage ]
        \cup [ tag : {SecuritiesMarketOperationScheduleMessageCode16}, body : SecuritiesMarketOperationScheduleMessage ]
        \cup [ tag : {SecuritiesMarketOperationScheduleMessageCode17}, body : SecuritiesMarketOperationScheduleMessage ]
        \cup [ tag : {SecuritiesMarketOperationScheduleMessageCode18}, body : SecuritiesMarketOperationScheduleMessage ]
        \cup [ tag : {SecuritiesMarketOperationScheduleMessageCode19}, body : SecuritiesMarketOperationScheduleMessage ]
        \cup [ tag : {SecuritiesMarketOperationScheduleMessageCode20}, body : SecuritiesMarketOperationScheduleMessage ]
        \cup [ tag : {SecuritiesMarketOperationScheduleMessageCode21}, body : SecuritiesMarketOperationScheduleMessage ]
        \cup [ tag : {SecuritiesMarketOperationScheduleMessageCode22}, body : SecuritiesMarketOperationScheduleMessage ]
        \cup [ tag : {SecuritiesMarketOperationScheduleMessageCode23}, body : SecuritiesMarketOperationScheduleMessage ]
        \cup [ tag : {SecuritiesMarketOperationScheduleMessageCode24}, body : SecuritiesMarketOperationScheduleMessage ]
        \cup [ tag : {SecuritiesMarketOperationScheduleMessageCode25}, body : SecuritiesMarketOperationScheduleMessage ]
        \cup [ tag : {SecuritiesMarketOperationScheduleMessageCode26}, body : SecuritiesMarketOperationScheduleMessage ]
        \cup [ tag : {SecuritiesMarketOperationScheduleMessageCode27}, body : SecuritiesMarketOperationScheduleMessage ]
        \cup [ tag : {SecuritiesMarketOperationScheduleMessageCode28}, body : SecuritiesMarketOperationScheduleMessage ]
        \cup [ tag : {SecuritiesMarketOperationScheduleMessageCode29}, body : SecuritiesMarketOperationScheduleMessage ]
        \cup [ tag : {SecuritiesMarketOperationScheduleMessageCode30}, body : SecuritiesMarketOperationScheduleMessage ]
        \cup [ tag : {SecuritiesRandomEndMessageCode}, body : SecuritiesRandomEndMessage ]
        \cup [ tag : {SecuritiesRandomEndMessageCode2}, body : SecuritiesRandomEndMessage ]
        \cup [ tag : {SecuritiesTriggeringViMessageCode}, body : SecuritiesTriggeringViMessage ]
        \cup [ tag : {SecuritiesTriggeringViMessageCode2}, body : SecuritiesTriggeringViMessage ]
        \cup [ tag : {SecuritiesTriggeringViMessageCode3}, body : SecuritiesTriggeringViMessage ]
        \cup [ tag : {SecuritiesTriggeringViMessageCode4}, body : SecuritiesTriggeringViMessage ]
        \cup [ tag : {SecuritiesTriggeringViMessageCode5}, body : SecuritiesTriggeringViMessage ]
        \cup [ tag : {SecuritiesQuantityAllocationMessageCode}, body : SecuritiesQuantityAllocationMessage ]
        \cup [ tag : {SecuritiesQuantityAllocationMessageCode2}, body : SecuritiesQuantityAllocationMessage ]
        \cup [ tag : {SecuritiesQuantityAllocationMessageCode3}, body : SecuritiesQuantityAllocationMessage ]
        \cup [ tag : {SecuritiesQuantityAllocationMessageCode4}, body : SecuritiesQuantityAllocationMessage ]
        \cup [ tag : {SecuritiesQuantityAllocationMessageCode5}, body : SecuritiesQuantityAllocationMessage ]
        \cup [ tag : {SecuritiesQuantityAllocationMessageCode6}, body : SecuritiesQuantityAllocationMessage ]
        \cup [ tag : {SecuritiesQuantityAllocationMessageCode7}, body : SecuritiesQuantityAllocationMessage ]
        \cup [ tag : {SecuritiesQuantityAllocationMessageCode8}, body : SecuritiesQuantityAllocationMessage ]
        \cup [ tag : {SecuritiesQuantityAllocationMessageCode9}, body : SecuritiesQuantityAllocationMessage ]
        \cup [ tag : {SecuritiesQuantityAllocationMessageCode10}, body : SecuritiesQuantityAllocationMessage ]
        \cup [ tag : {SecuritiesQuantityAllocationMessageCode11}, body : SecuritiesQuantityAllocationMessage ]
        \cup [ tag : {SecuritiesQuantityAllocationMessageCode12}, body : SecuritiesQuantityAllocationMessage ]
        \cup [ tag : {SecuritiesQuantityAllocationMessageCode13}, body : SecuritiesQuantityAllocationMessage ]
        \cup [ tag : {SecuritiesQuantityAllocationMessageCode14}, body : SecuritiesQuantityAllocationMessage ]
        \cup [ tag : {SecuritiesQuantityAllocationMessageCode15}, body : SecuritiesQuantityAllocationMessage ]
        \cup [ tag : {SecuritiesQuantityAllocationMessageCode16}, body : SecuritiesQuantityAllocationMessage ]
        \cup [ tag : {SecuritiesQuantityAllocationMessageCode17}, body : SecuritiesQuantityAllocationMessage ]
        \cup [ tag : {SecuritiesQuantityAllocationMessageCode18}, body : SecuritiesQuantityAllocationMessage ]
        \cup [ tag : {SecuritiesQuantityAllocationMessageCode19}, body : SecuritiesQuantityAllocationMessage ]
        \cup [ tag : {SecuritiesQuantityAllocationMessageCode20}, body : SecuritiesQuantityAllocationMessage ]
        \cup [ tag : {SecuritiesQuantityAllocationMessageCode21}, body : SecuritiesQuantityAllocationMessage ]
        \cup [ tag : {SecuritiesQuantityAllocationMessageCode22}, body : SecuritiesQuantityAllocationMessage ]
        \cup [ tag : {SecuritiesQuantityAllocationMessageCode23}, body : SecuritiesQuantityAllocationMessage ]
        \cup [ tag : {SecuritiesMemberFirmSanctionsMessageCode}, body : SecuritiesMemberFirmSanctionsMessage ]
        \cup [ tag : {SecuritiesMemberFirmSanctionsMessageCode2}, body : SecuritiesMemberFirmSanctionsMessage ]
        \cup [ tag : {SecuritiesMemberFirmSanctionsMessageCode3}, body : SecuritiesMemberFirmSanctionsMessage ]
        \cup [ tag : {SecuritiesMemberFirmSanctionsMessageCode4}, body : SecuritiesMemberFirmSanctionsMessage ]
        \cup [ tag : {SecuritiesMemberFirmSanctionsMessageCode5}, body : SecuritiesMemberFirmSanctionsMessage ]
        \cup [ tag : {SecuritiesMemberFirmSanctionsMessageCode6}, body : SecuritiesMemberFirmSanctionsMessage ]
        \cup [ tag : {SecuritiesMemberFirmSanctionsMessageCode7}, body : SecuritiesMemberFirmSanctionsMessage ]
        \cup [ tag : {SecuritiesMemberFirmSanctionsMessageCode8}, body : SecuritiesMemberFirmSanctionsMessage ]
        \cup [ tag : {SecuritiesMemberFirmSanctionsMessageCode9}, body : SecuritiesMemberFirmSanctionsMessage ]
        \cup [ tag : {SecuritiesMemberFirmSanctionsMessageCode10}, body : SecuritiesMemberFirmSanctionsMessage ]
        \cup [ tag : {SecuritiesMemberFirmSanctionsMessageCode11}, body : SecuritiesMemberFirmSanctionsMessage ]
        \cup [ tag : {SecuritiesEquitiesChangesOfBatchDataMessageCode}, body : SecuritiesEquitiesChangesOfBatchDataMessage ]
        \cup [ tag : {SecuritiesEquitiesChangesOfBatchDataMessageCode2}, body : SecuritiesEquitiesChangesOfBatchDataMessage ]
        \cup [ tag : {SecuritiesEquitiesChangesOfBatchDataMessageCode3}, body : SecuritiesEquitiesChangesOfBatchDataMessage ]
        \cup [ tag : {SecuritiesEquitiesChangesOfBatchDataMessageCode4}, body : SecuritiesEquitiesChangesOfBatchDataMessage ]
        \cup [ tag : {SecuritiesEquitiesChangesOfBatchDataMessageCode5}, body : SecuritiesEquitiesChangesOfBatchDataMessage ]
        \cup [ tag : {SecuritiesEquitiesChangesOfBatchDataMessageCode6}, body : SecuritiesEquitiesChangesOfBatchDataMessage ]
        \cup [ tag : {SecuritiesEquitiesChangesOfBatchDataMessageCode7}, body : SecuritiesEquitiesChangesOfBatchDataMessage ]
        \cup [ tag : {SecuritiesGroupOrderAcceptanceHaltMessageCode}, body : SecuritiesGroupOrderAcceptanceHaltMessage ]
        \cup [ tag : {SecuritiesGroupOrderAcceptanceHaltMessageCode2}, body : SecuritiesGroupOrderAcceptanceHaltMessage ]
        \cup [ tag : {SecuritiesGroupOrderAcceptanceHaltMessageCode3}, body : SecuritiesGroupOrderAcceptanceHaltMessage ]
        \cup [ tag : {SecuritiesGroupOrderAcceptanceHaltMessageCode4}, body : SecuritiesGroupOrderAcceptanceHaltMessage ]
        \cup [ tag : {SecuritiesGroupOrderAcceptanceHaltMessageCode5}, body : SecuritiesGroupOrderAcceptanceHaltMessage ]
        \cup [ tag : {SecuritiesGroupOrderAcceptanceHaltMessageCode6}, body : SecuritiesGroupOrderAcceptanceHaltMessage ]
        \cup [ tag : {SecuritiesGroupOrderAcceptanceHaltMessageCode7}, body : SecuritiesGroupOrderAcceptanceHaltMessage ]
        \cup [ tag : {SecuritiesGroupOrderAcceptanceHaltMessageCode8}, body : SecuritiesGroupOrderAcceptanceHaltMessage ]
        \cup [ tag : {SecuritiesGroupOrderAcceptanceHaltMessageCode9}, body : SecuritiesGroupOrderAcceptanceHaltMessage ]
        \cup [ tag : {SecuritiesGroupOrderAcceptanceHaltMessageCode10}, body : SecuritiesGroupOrderAcceptanceHaltMessage ]
        \cup [ tag : {SecuritiesGroupOrderAcceptanceHaltMessageCode11}, body : SecuritiesGroupOrderAcceptanceHaltMessage ]
        \cup [ tag : {SecuritiesGroupOrderAcceptanceHaltMessageCode12}, body : SecuritiesGroupOrderAcceptanceHaltMessage ]
        \cup [ tag : {SecuritiesGroupOrderAcceptanceHaltMessageCode13}, body : SecuritiesGroupOrderAcceptanceHaltMessage ]
        \cup [ tag : {SecuritiesGroupOrderAcceptanceHaltMessageCode14}, body : SecuritiesGroupOrderAcceptanceHaltMessage ]
        \cup [ tag : {SecuritiesGroupOrderAcceptanceHaltMessageCode15}, body : SecuritiesGroupOrderAcceptanceHaltMessage ]
        \cup [ tag : {SecuritiesGroupOrderAcceptanceHaltMessageCode16}, body : SecuritiesGroupOrderAcceptanceHaltMessage ]
        \cup [ tag : {SecuritiesGroupOrderAcceptanceHaltMessageCode17}, body : SecuritiesGroupOrderAcceptanceHaltMessage ]
        \cup [ tag : {SecuritiesGroupOrderAcceptanceHaltMessageCode18}, body : SecuritiesGroupOrderAcceptanceHaltMessage ]
        \cup [ tag : {SecuritiesGroupOrderAcceptanceHaltMessageCode19}, body : SecuritiesGroupOrderAcceptanceHaltMessage ]
        \cup [ tag : {SecuritiesGroupOrderAcceptanceHaltMessageCode20}, body : SecuritiesGroupOrderAcceptanceHaltMessage ]
        \cup [ tag : {SecuritiesGroupOrderAcceptanceHaltMessageCode21}, body : SecuritiesGroupOrderAcceptanceHaltMessage ]
        \cup [ tag : {SecuritiesGroupOrderAcceptanceHaltMessageCode22}, body : SecuritiesGroupOrderAcceptanceHaltMessage ]
        \cup [ tag : {SecuritiesGroupOrderAcceptanceHaltMessageCode23}, body : SecuritiesGroupOrderAcceptanceHaltMessage ]
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
        \cup [ tag : {SecuritiesElwBatchDataMessageCode}, body : SecuritiesElwBatchDataMessage ]
        \cup [ tag : {SecuritiesEtnBatchDataMessageCode}, body : SecuritiesEtnBatchDataMessage ]
        \cup [ tag : {SecuritiesEtnEarlyRedemptionMessageCode}, body : SecuritiesEtnEarlyRedemptionMessage ]
        \cup [ tag : {SecuritiesEtpConstituentsMessageCode}, body : SecuritiesEtpConstituentsMessage ]
        \cup [ tag : {SecuritiesKnockOutElwMessageCode}, body : SecuritiesKnockOutElwMessage ]
        \cup [ tag : {SecuritiesKnockOutUnderlyingMessageCode}, body : SecuritiesKnockOutUnderlyingMessage ]
        \cup [ tag : {SecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessageCode}, body : SecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage ]
        \cup [ tag : {SecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessageCode2}, body : SecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage ]
        \cup [ tag : {SecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessageCode3}, body : SecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage ]
        \cup [ tag : {SecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessageCode4}, body : SecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage ]
        \cup [ tag : {SecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessageCode5}, body : SecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage ]
        \cup [ tag : {SecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessageCode6}, body : SecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage ]
        \cup [ tag : {SecuritiesABloxTradeQuotesMessageCode}, body : SecuritiesABloxTradeQuotesMessage ]
        \cup [ tag : {SecuritiesABloxTradeQuotesMessageCode2}, body : SecuritiesABloxTradeQuotesMessage ]
        \cup [ tag : {SecuritiesABloxTradeQuotesMessageCode3}, body : SecuritiesABloxTradeQuotesMessage ]
        \cup [ tag : {SecuritiesABloxTradeQuotesMessageCode4}, body : SecuritiesABloxTradeQuotesMessage ]
        \cup [ tag : {SecuritiesABloxTradeQuotesMessageCode5}, body : SecuritiesABloxTradeQuotesMessage ]
        \cup [ tag : {SecuritiesEtnProfitStructureMessageCode}, body : SecuritiesEtnProfitStructureMessage ]
        \cup [ tag : {SecuritiesTopFiveTradersActivitiesMessageCode}, body : SecuritiesTopFiveTradersActivitiesMessage ]
        \cup [ tag : {SecuritiesTopFiveTradersActivitiesMessageCode2}, body : SecuritiesTopFiveTradersActivitiesMessage ]
        \cup [ tag : {SecuritiesTopFiveTradersActivitiesMessageCode3}, body : SecuritiesTopFiveTradersActivitiesMessage ]
        \cup [ tag : {SecuritiesTopFiveTradersActivitiesMessageCode4}, body : SecuritiesTopFiveTradersActivitiesMessage ]
        \cup [ tag : {SecuritiesTopFiveTradersActivitiesMessageCode5}, body : SecuritiesTopFiveTradersActivitiesMessage ]
        \cup [ tag : {SecuritiesTopFiveTradersActivitiesMessageCode6}, body : SecuritiesTopFiveTradersActivitiesMessage ]
        \cup [ tag : {SecuritiesTopFiveTradersActivitiesMessageCode7}, body : SecuritiesTopFiveTradersActivitiesMessage ]
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
      [] message.tag = SecuritiesQuoteMmLpExcludedMessageCode -> EncodeSecuritiesQuoteMmLpExcludedMessage(message.body)
      [] message.tag = SecuritiesQuoteMmLpExcludedMessageCode2 -> EncodeSecuritiesQuoteMmLpExcludedMessage(message.body)
      [] message.tag = SecuritiesQuoteMmLpExcludedMessageCode3 -> EncodeSecuritiesQuoteMmLpExcludedMessage(message.body)
      [] message.tag = SecuritiesQuoteMmLpIncludedMessageCode -> EncodeSecuritiesQuoteMmLpIncludedMessage(message.body)
      [] message.tag = SecuritiesQuoteMmLpIncludedMessageCode2 -> EncodeSecuritiesQuoteMmLpIncludedMessage(message.body)
      [] message.tag = SecuritiesQuoteMmLpIncludedMessageCode3 -> EncodeSecuritiesQuoteMmLpIncludedMessage(message.body)
      [] message.tag = SecuritiesQuoteMmLpIncludedMessageCode4 -> EncodeSecuritiesQuoteMmLpIncludedMessage(message.body)
      [] message.tag = SecuritiesSnapshotMmLpExcludedMessageCode -> EncodeSecuritiesSnapshotMmLpExcludedMessage(message.body)
      [] message.tag = SecuritiesSnapshotMmLpExcludedMessageCode2 -> EncodeSecuritiesSnapshotMmLpExcludedMessage(message.body)
      [] message.tag = SecuritiesSnapshotMmLpIncludedMessageCode -> EncodeSecuritiesSnapshotMmLpIncludedMessage(message.body)
      [] message.tag = SecuritiesSnapshotMmLpIncludedMessageCode2 -> EncodeSecuritiesSnapshotMmLpIncludedMessage(message.body)
      [] message.tag = SecuritiesSnapshotMmLpIncludedMessageCode3 -> EncodeSecuritiesSnapshotMmLpIncludedMessage(message.body)
      [] message.tag = SecuritiesSnapshotMmLpIncludedMessageCode4 -> EncodeSecuritiesSnapshotMmLpIncludedMessage(message.body)
      [] message.tag = SecuritiesOrderFilledMessageCode -> EncodeSecuritiesOrderFilledMessage(message.body)
      [] message.tag = SecuritiesOrderFilledMessageCode2 -> EncodeSecuritiesOrderFilledMessage(message.body)
      [] message.tag = SecuritiesOrderFilledMessageCode3 -> EncodeSecuritiesOrderFilledMessage(message.body)
      [] message.tag = SecuritiesOrderFilledMessageCode4 -> EncodeSecuritiesOrderFilledMessage(message.body)
      [] message.tag = SecuritiesOrderFilledMessageCode5 -> EncodeSecuritiesOrderFilledMessage(message.body)
      [] message.tag = SecuritiesOrderFilledMessageCode6 -> EncodeSecuritiesOrderFilledMessage(message.body)
      [] message.tag = SecuritiesOrderFilledMessageCode7 -> EncodeSecuritiesOrderFilledMessage(message.body)
      [] message.tag = SecuritiesNegotiatedTradeMessageCode -> EncodeSecuritiesNegotiatedTradeMessage(message.body)
      [] message.tag = SecuritiesNegotiatedTradeMessageCode2 -> EncodeSecuritiesNegotiatedTradeMessage(message.body)
      [] message.tag = SecuritiesNegotiatedTradeMessageCode3 -> EncodeSecuritiesNegotiatedTradeMessage(message.body)
      [] message.tag = SecuritiesNegotiatedTradeMessageCode4 -> EncodeSecuritiesNegotiatedTradeMessage(message.body)
      [] message.tag = SecuritiesNegotiatedTradeMessageCode5 -> EncodeSecuritiesNegotiatedTradeMessage(message.body)
      [] message.tag = SecuritiesNegotiatedTradeMessageCode6 -> EncodeSecuritiesNegotiatedTradeMessage(message.body)
      [] message.tag = SecuritiesNegotiatedTradeMessageCode7 -> EncodeSecuritiesNegotiatedTradeMessage(message.body)
      [] message.tag = SecuritiesMarketOperationTsMessageCode -> EncodeSecuritiesMarketOperationTsMessage(message.body)
      [] message.tag = SecuritiesMarketOperationTsMessageCode2 -> EncodeSecuritiesMarketOperationTsMessage(message.body)
      [] message.tag = SecuritiesMarketOperationTsMessageCode3 -> EncodeSecuritiesMarketOperationTsMessage(message.body)
      [] message.tag = SecuritiesMarketOperationTsMessageCode4 -> EncodeSecuritiesMarketOperationTsMessage(message.body)
      [] message.tag = SecuritiesMarketOperationTsMessageCode5 -> EncodeSecuritiesMarketOperationTsMessage(message.body)
      [] message.tag = SecuritiesMarketOperationTsMessageCode6 -> EncodeSecuritiesMarketOperationTsMessage(message.body)
      [] message.tag = SecuritiesMarketOperationTsMessageCode7 -> EncodeSecuritiesMarketOperationTsMessage(message.body)
      [] message.tag = SecuritiesMarketOperationTsMessageCode8 -> EncodeSecuritiesMarketOperationTsMessage(message.body)
      [] message.tag = SecuritiesMarketOperationTsMessageCode9 -> EncodeSecuritiesMarketOperationTsMessage(message.body)
      [] message.tag = SecuritiesMarketOperationTsMessageCode10 -> EncodeSecuritiesMarketOperationTsMessage(message.body)
      [] message.tag = SecuritiesMarketOperationTsMessageCode11 -> EncodeSecuritiesMarketOperationTsMessage(message.body)
      [] message.tag = SecuritiesMarketOperationTsMessageCode12 -> EncodeSecuritiesMarketOperationTsMessage(message.body)
      [] message.tag = SecuritiesMarketOperationTsMessageCode13 -> EncodeSecuritiesMarketOperationTsMessage(message.body)
      [] message.tag = SecuritiesMarketOperationTsMessageCode14 -> EncodeSecuritiesMarketOperationTsMessage(message.body)
      [] message.tag = SecuritiesMarketOperationTsMessageCode15 -> EncodeSecuritiesMarketOperationTsMessage(message.body)
      [] message.tag = SecuritiesMarketOperationTsMessageCode16 -> EncodeSecuritiesMarketOperationTsMessage(message.body)
      [] message.tag = SecuritiesMarketOperationTsMessageCode17 -> EncodeSecuritiesMarketOperationTsMessage(message.body)
      [] message.tag = SecuritiesMarketOperationTsMessageCode18 -> EncodeSecuritiesMarketOperationTsMessage(message.body)
      [] message.tag = SecuritiesMarketOperationTsMessageCode19 -> EncodeSecuritiesMarketOperationTsMessage(message.body)
      [] message.tag = SecuritiesMarketOperationTsMessageCode20 -> EncodeSecuritiesMarketOperationTsMessage(message.body)
      [] message.tag = SecuritiesMarketOperationTsMessageCode21 -> EncodeSecuritiesMarketOperationTsMessage(message.body)
      [] message.tag = SecuritiesMarketOperationTsMessageCode22 -> EncodeSecuritiesMarketOperationTsMessage(message.body)
      [] message.tag = SecuritiesMarketOperationTsMessageCode23 -> EncodeSecuritiesMarketOperationTsMessage(message.body)
      [] message.tag = SecuritiesMarketOperationTsMessageCode24 -> EncodeSecuritiesMarketOperationTsMessage(message.body)
      [] message.tag = SecuritiesMarketOperationTsMessageCode25 -> EncodeSecuritiesMarketOperationTsMessage(message.body)
      [] message.tag = SecuritiesMarketOperationTsMessageCode26 -> EncodeSecuritiesMarketOperationTsMessage(message.body)
      [] message.tag = SecuritiesMarketOperationTsMessageCode27 -> EncodeSecuritiesMarketOperationTsMessage(message.body)
      [] message.tag = SecuritiesMarketOperationTsMessageCode28 -> EncodeSecuritiesMarketOperationTsMessage(message.body)
      [] message.tag = SecuritiesMarketOperationTsMessageCode29 -> EncodeSecuritiesMarketOperationTsMessage(message.body)
      [] message.tag = SecuritiesMarketOperationTsMessageCode30 -> EncodeSecuritiesMarketOperationTsMessage(message.body)
      [] message.tag = SecuritiesDeterminationOfBasePriceMessageCode -> EncodeSecuritiesDeterminationOfBasePriceMessage(message.body)
      [] message.tag = SecuritiesDeterminationOfBasePriceMessageCode2 -> EncodeSecuritiesDeterminationOfBasePriceMessage(message.body)
      [] message.tag = SecuritiesDeterminationOfBasePriceMessageCode3 -> EncodeSecuritiesDeterminationOfBasePriceMessage(message.body)
      [] message.tag = SecuritiesDeterminationOfBasePriceMessageCode4 -> EncodeSecuritiesDeterminationOfBasePriceMessage(message.body)
      [] message.tag = SecuritiesDeterminationOfBasePriceMessageCode5 -> EncodeSecuritiesDeterminationOfBasePriceMessage(message.body)
      [] message.tag = SecuritiesDeterminationOfBasePriceMessageCode6 -> EncodeSecuritiesDeterminationOfBasePriceMessage(message.body)
      [] message.tag = SecuritiesIssueClosingMessageCode -> EncodeSecuritiesIssueClosingMessage(message.body)
      [] message.tag = SecuritiesIssueClosingMessageCode2 -> EncodeSecuritiesIssueClosingMessage(message.body)
      [] message.tag = SecuritiesIssueClosingMessageCode3 -> EncodeSecuritiesIssueClosingMessage(message.body)
      [] message.tag = SecuritiesIssueClosingMessageCode4 -> EncodeSecuritiesIssueClosingMessage(message.body)
      [] message.tag = SecuritiesIssueClosingMessageCode5 -> EncodeSecuritiesIssueClosingMessage(message.body)
      [] message.tag = SecuritiesIssueClosingMessageCode6 -> EncodeSecuritiesIssueClosingMessage(message.body)
      [] message.tag = SecuritiesIssueClosingMessageCode7 -> EncodeSecuritiesIssueClosingMessage(message.body)
      [] message.tag = SecuritiesIssueClosingMessageCode8 -> EncodeSecuritiesIssueClosingMessage(message.body)
      [] message.tag = SecuritiesIssueClosingMessageCode9 -> EncodeSecuritiesIssueClosingMessage(message.body)
      [] message.tag = SecuritiesMarketOperationScheduleMessageCode -> EncodeSecuritiesMarketOperationScheduleMessage(message.body)
      [] message.tag = SecuritiesMarketOperationScheduleMessageCode2 -> EncodeSecuritiesMarketOperationScheduleMessage(message.body)
      [] message.tag = SecuritiesMarketOperationScheduleMessageCode3 -> EncodeSecuritiesMarketOperationScheduleMessage(message.body)
      [] message.tag = SecuritiesMarketOperationScheduleMessageCode4 -> EncodeSecuritiesMarketOperationScheduleMessage(message.body)
      [] message.tag = SecuritiesMarketOperationScheduleMessageCode5 -> EncodeSecuritiesMarketOperationScheduleMessage(message.body)
      [] message.tag = SecuritiesMarketOperationScheduleMessageCode6 -> EncodeSecuritiesMarketOperationScheduleMessage(message.body)
      [] message.tag = SecuritiesMarketOperationScheduleMessageCode7 -> EncodeSecuritiesMarketOperationScheduleMessage(message.body)
      [] message.tag = SecuritiesMarketOperationScheduleMessageCode8 -> EncodeSecuritiesMarketOperationScheduleMessage(message.body)
      [] message.tag = SecuritiesMarketOperationScheduleMessageCode9 -> EncodeSecuritiesMarketOperationScheduleMessage(message.body)
      [] message.tag = SecuritiesMarketOperationScheduleMessageCode10 -> EncodeSecuritiesMarketOperationScheduleMessage(message.body)
      [] message.tag = SecuritiesMarketOperationScheduleMessageCode11 -> EncodeSecuritiesMarketOperationScheduleMessage(message.body)
      [] message.tag = SecuritiesMarketOperationScheduleMessageCode12 -> EncodeSecuritiesMarketOperationScheduleMessage(message.body)
      [] message.tag = SecuritiesMarketOperationScheduleMessageCode13 -> EncodeSecuritiesMarketOperationScheduleMessage(message.body)
      [] message.tag = SecuritiesMarketOperationScheduleMessageCode14 -> EncodeSecuritiesMarketOperationScheduleMessage(message.body)
      [] message.tag = SecuritiesMarketOperationScheduleMessageCode15 -> EncodeSecuritiesMarketOperationScheduleMessage(message.body)
      [] message.tag = SecuritiesMarketOperationScheduleMessageCode16 -> EncodeSecuritiesMarketOperationScheduleMessage(message.body)
      [] message.tag = SecuritiesMarketOperationScheduleMessageCode17 -> EncodeSecuritiesMarketOperationScheduleMessage(message.body)
      [] message.tag = SecuritiesMarketOperationScheduleMessageCode18 -> EncodeSecuritiesMarketOperationScheduleMessage(message.body)
      [] message.tag = SecuritiesMarketOperationScheduleMessageCode19 -> EncodeSecuritiesMarketOperationScheduleMessage(message.body)
      [] message.tag = SecuritiesMarketOperationScheduleMessageCode20 -> EncodeSecuritiesMarketOperationScheduleMessage(message.body)
      [] message.tag = SecuritiesMarketOperationScheduleMessageCode21 -> EncodeSecuritiesMarketOperationScheduleMessage(message.body)
      [] message.tag = SecuritiesMarketOperationScheduleMessageCode22 -> EncodeSecuritiesMarketOperationScheduleMessage(message.body)
      [] message.tag = SecuritiesMarketOperationScheduleMessageCode23 -> EncodeSecuritiesMarketOperationScheduleMessage(message.body)
      [] message.tag = SecuritiesMarketOperationScheduleMessageCode24 -> EncodeSecuritiesMarketOperationScheduleMessage(message.body)
      [] message.tag = SecuritiesMarketOperationScheduleMessageCode25 -> EncodeSecuritiesMarketOperationScheduleMessage(message.body)
      [] message.tag = SecuritiesMarketOperationScheduleMessageCode26 -> EncodeSecuritiesMarketOperationScheduleMessage(message.body)
      [] message.tag = SecuritiesMarketOperationScheduleMessageCode27 -> EncodeSecuritiesMarketOperationScheduleMessage(message.body)
      [] message.tag = SecuritiesMarketOperationScheduleMessageCode28 -> EncodeSecuritiesMarketOperationScheduleMessage(message.body)
      [] message.tag = SecuritiesMarketOperationScheduleMessageCode29 -> EncodeSecuritiesMarketOperationScheduleMessage(message.body)
      [] message.tag = SecuritiesMarketOperationScheduleMessageCode30 -> EncodeSecuritiesMarketOperationScheduleMessage(message.body)
      [] message.tag = SecuritiesRandomEndMessageCode -> EncodeSecuritiesRandomEndMessage(message.body)
      [] message.tag = SecuritiesRandomEndMessageCode2 -> EncodeSecuritiesRandomEndMessage(message.body)
      [] message.tag = SecuritiesTriggeringViMessageCode -> EncodeSecuritiesTriggeringViMessage(message.body)
      [] message.tag = SecuritiesTriggeringViMessageCode2 -> EncodeSecuritiesTriggeringViMessage(message.body)
      [] message.tag = SecuritiesTriggeringViMessageCode3 -> EncodeSecuritiesTriggeringViMessage(message.body)
      [] message.tag = SecuritiesTriggeringViMessageCode4 -> EncodeSecuritiesTriggeringViMessage(message.body)
      [] message.tag = SecuritiesTriggeringViMessageCode5 -> EncodeSecuritiesTriggeringViMessage(message.body)
      [] message.tag = SecuritiesQuantityAllocationMessageCode -> EncodeSecuritiesQuantityAllocationMessage(message.body)
      [] message.tag = SecuritiesQuantityAllocationMessageCode2 -> EncodeSecuritiesQuantityAllocationMessage(message.body)
      [] message.tag = SecuritiesQuantityAllocationMessageCode3 -> EncodeSecuritiesQuantityAllocationMessage(message.body)
      [] message.tag = SecuritiesQuantityAllocationMessageCode4 -> EncodeSecuritiesQuantityAllocationMessage(message.body)
      [] message.tag = SecuritiesQuantityAllocationMessageCode5 -> EncodeSecuritiesQuantityAllocationMessage(message.body)
      [] message.tag = SecuritiesQuantityAllocationMessageCode6 -> EncodeSecuritiesQuantityAllocationMessage(message.body)
      [] message.tag = SecuritiesQuantityAllocationMessageCode7 -> EncodeSecuritiesQuantityAllocationMessage(message.body)
      [] message.tag = SecuritiesQuantityAllocationMessageCode8 -> EncodeSecuritiesQuantityAllocationMessage(message.body)
      [] message.tag = SecuritiesQuantityAllocationMessageCode9 -> EncodeSecuritiesQuantityAllocationMessage(message.body)
      [] message.tag = SecuritiesQuantityAllocationMessageCode10 -> EncodeSecuritiesQuantityAllocationMessage(message.body)
      [] message.tag = SecuritiesQuantityAllocationMessageCode11 -> EncodeSecuritiesQuantityAllocationMessage(message.body)
      [] message.tag = SecuritiesQuantityAllocationMessageCode12 -> EncodeSecuritiesQuantityAllocationMessage(message.body)
      [] message.tag = SecuritiesQuantityAllocationMessageCode13 -> EncodeSecuritiesQuantityAllocationMessage(message.body)
      [] message.tag = SecuritiesQuantityAllocationMessageCode14 -> EncodeSecuritiesQuantityAllocationMessage(message.body)
      [] message.tag = SecuritiesQuantityAllocationMessageCode15 -> EncodeSecuritiesQuantityAllocationMessage(message.body)
      [] message.tag = SecuritiesQuantityAllocationMessageCode16 -> EncodeSecuritiesQuantityAllocationMessage(message.body)
      [] message.tag = SecuritiesQuantityAllocationMessageCode17 -> EncodeSecuritiesQuantityAllocationMessage(message.body)
      [] message.tag = SecuritiesQuantityAllocationMessageCode18 -> EncodeSecuritiesQuantityAllocationMessage(message.body)
      [] message.tag = SecuritiesQuantityAllocationMessageCode19 -> EncodeSecuritiesQuantityAllocationMessage(message.body)
      [] message.tag = SecuritiesQuantityAllocationMessageCode20 -> EncodeSecuritiesQuantityAllocationMessage(message.body)
      [] message.tag = SecuritiesQuantityAllocationMessageCode21 -> EncodeSecuritiesQuantityAllocationMessage(message.body)
      [] message.tag = SecuritiesQuantityAllocationMessageCode22 -> EncodeSecuritiesQuantityAllocationMessage(message.body)
      [] message.tag = SecuritiesQuantityAllocationMessageCode23 -> EncodeSecuritiesQuantityAllocationMessage(message.body)
      [] message.tag = SecuritiesMemberFirmSanctionsMessageCode -> EncodeSecuritiesMemberFirmSanctionsMessage(message.body)
      [] message.tag = SecuritiesMemberFirmSanctionsMessageCode2 -> EncodeSecuritiesMemberFirmSanctionsMessage(message.body)
      [] message.tag = SecuritiesMemberFirmSanctionsMessageCode3 -> EncodeSecuritiesMemberFirmSanctionsMessage(message.body)
      [] message.tag = SecuritiesMemberFirmSanctionsMessageCode4 -> EncodeSecuritiesMemberFirmSanctionsMessage(message.body)
      [] message.tag = SecuritiesMemberFirmSanctionsMessageCode5 -> EncodeSecuritiesMemberFirmSanctionsMessage(message.body)
      [] message.tag = SecuritiesMemberFirmSanctionsMessageCode6 -> EncodeSecuritiesMemberFirmSanctionsMessage(message.body)
      [] message.tag = SecuritiesMemberFirmSanctionsMessageCode7 -> EncodeSecuritiesMemberFirmSanctionsMessage(message.body)
      [] message.tag = SecuritiesMemberFirmSanctionsMessageCode8 -> EncodeSecuritiesMemberFirmSanctionsMessage(message.body)
      [] message.tag = SecuritiesMemberFirmSanctionsMessageCode9 -> EncodeSecuritiesMemberFirmSanctionsMessage(message.body)
      [] message.tag = SecuritiesMemberFirmSanctionsMessageCode10 -> EncodeSecuritiesMemberFirmSanctionsMessage(message.body)
      [] message.tag = SecuritiesMemberFirmSanctionsMessageCode11 -> EncodeSecuritiesMemberFirmSanctionsMessage(message.body)
      [] message.tag = SecuritiesEquitiesChangesOfBatchDataMessageCode -> EncodeSecuritiesEquitiesChangesOfBatchDataMessage(message.body)
      [] message.tag = SecuritiesEquitiesChangesOfBatchDataMessageCode2 -> EncodeSecuritiesEquitiesChangesOfBatchDataMessage(message.body)
      [] message.tag = SecuritiesEquitiesChangesOfBatchDataMessageCode3 -> EncodeSecuritiesEquitiesChangesOfBatchDataMessage(message.body)
      [] message.tag = SecuritiesEquitiesChangesOfBatchDataMessageCode4 -> EncodeSecuritiesEquitiesChangesOfBatchDataMessage(message.body)
      [] message.tag = SecuritiesEquitiesChangesOfBatchDataMessageCode5 -> EncodeSecuritiesEquitiesChangesOfBatchDataMessage(message.body)
      [] message.tag = SecuritiesEquitiesChangesOfBatchDataMessageCode6 -> EncodeSecuritiesEquitiesChangesOfBatchDataMessage(message.body)
      [] message.tag = SecuritiesEquitiesChangesOfBatchDataMessageCode7 -> EncodeSecuritiesEquitiesChangesOfBatchDataMessage(message.body)
      [] message.tag = SecuritiesGroupOrderAcceptanceHaltMessageCode -> EncodeSecuritiesGroupOrderAcceptanceHaltMessage(message.body)
      [] message.tag = SecuritiesGroupOrderAcceptanceHaltMessageCode2 -> EncodeSecuritiesGroupOrderAcceptanceHaltMessage(message.body)
      [] message.tag = SecuritiesGroupOrderAcceptanceHaltMessageCode3 -> EncodeSecuritiesGroupOrderAcceptanceHaltMessage(message.body)
      [] message.tag = SecuritiesGroupOrderAcceptanceHaltMessageCode4 -> EncodeSecuritiesGroupOrderAcceptanceHaltMessage(message.body)
      [] message.tag = SecuritiesGroupOrderAcceptanceHaltMessageCode5 -> EncodeSecuritiesGroupOrderAcceptanceHaltMessage(message.body)
      [] message.tag = SecuritiesGroupOrderAcceptanceHaltMessageCode6 -> EncodeSecuritiesGroupOrderAcceptanceHaltMessage(message.body)
      [] message.tag = SecuritiesGroupOrderAcceptanceHaltMessageCode7 -> EncodeSecuritiesGroupOrderAcceptanceHaltMessage(message.body)
      [] message.tag = SecuritiesGroupOrderAcceptanceHaltMessageCode8 -> EncodeSecuritiesGroupOrderAcceptanceHaltMessage(message.body)
      [] message.tag = SecuritiesGroupOrderAcceptanceHaltMessageCode9 -> EncodeSecuritiesGroupOrderAcceptanceHaltMessage(message.body)
      [] message.tag = SecuritiesGroupOrderAcceptanceHaltMessageCode10 -> EncodeSecuritiesGroupOrderAcceptanceHaltMessage(message.body)
      [] message.tag = SecuritiesGroupOrderAcceptanceHaltMessageCode11 -> EncodeSecuritiesGroupOrderAcceptanceHaltMessage(message.body)
      [] message.tag = SecuritiesGroupOrderAcceptanceHaltMessageCode12 -> EncodeSecuritiesGroupOrderAcceptanceHaltMessage(message.body)
      [] message.tag = SecuritiesGroupOrderAcceptanceHaltMessageCode13 -> EncodeSecuritiesGroupOrderAcceptanceHaltMessage(message.body)
      [] message.tag = SecuritiesGroupOrderAcceptanceHaltMessageCode14 -> EncodeSecuritiesGroupOrderAcceptanceHaltMessage(message.body)
      [] message.tag = SecuritiesGroupOrderAcceptanceHaltMessageCode15 -> EncodeSecuritiesGroupOrderAcceptanceHaltMessage(message.body)
      [] message.tag = SecuritiesGroupOrderAcceptanceHaltMessageCode16 -> EncodeSecuritiesGroupOrderAcceptanceHaltMessage(message.body)
      [] message.tag = SecuritiesGroupOrderAcceptanceHaltMessageCode17 -> EncodeSecuritiesGroupOrderAcceptanceHaltMessage(message.body)
      [] message.tag = SecuritiesGroupOrderAcceptanceHaltMessageCode18 -> EncodeSecuritiesGroupOrderAcceptanceHaltMessage(message.body)
      [] message.tag = SecuritiesGroupOrderAcceptanceHaltMessageCode19 -> EncodeSecuritiesGroupOrderAcceptanceHaltMessage(message.body)
      [] message.tag = SecuritiesGroupOrderAcceptanceHaltMessageCode20 -> EncodeSecuritiesGroupOrderAcceptanceHaltMessage(message.body)
      [] message.tag = SecuritiesGroupOrderAcceptanceHaltMessageCode21 -> EncodeSecuritiesGroupOrderAcceptanceHaltMessage(message.body)
      [] message.tag = SecuritiesGroupOrderAcceptanceHaltMessageCode22 -> EncodeSecuritiesGroupOrderAcceptanceHaltMessage(message.body)
      [] message.tag = SecuritiesGroupOrderAcceptanceHaltMessageCode23 -> EncodeSecuritiesGroupOrderAcceptanceHaltMessage(message.body)
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
      [] message.tag = SecuritiesElwBatchDataMessageCode -> EncodeSecuritiesElwBatchDataMessage(message.body)
      [] message.tag = SecuritiesEtnBatchDataMessageCode -> EncodeSecuritiesEtnBatchDataMessage(message.body)
      [] message.tag = SecuritiesEtnEarlyRedemptionMessageCode -> EncodeSecuritiesEtnEarlyRedemptionMessage(message.body)
      [] message.tag = SecuritiesEtpConstituentsMessageCode -> EncodeSecuritiesEtpConstituentsMessage(message.body)
      [] message.tag = SecuritiesKnockOutElwMessageCode -> EncodeSecuritiesKnockOutElwMessage(message.body)
      [] message.tag = SecuritiesKnockOutUnderlyingMessageCode -> EncodeSecuritiesKnockOutUnderlyingMessage(message.body)
      [] message.tag = SecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessageCode -> EncodeSecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage(message.body)
      [] message.tag = SecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessageCode2 -> EncodeSecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage(message.body)
      [] message.tag = SecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessageCode3 -> EncodeSecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage(message.body)
      [] message.tag = SecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessageCode4 -> EncodeSecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage(message.body)
      [] message.tag = SecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessageCode5 -> EncodeSecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage(message.body)
      [] message.tag = SecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessageCode6 -> EncodeSecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage(message.body)
      [] message.tag = SecuritiesABloxTradeQuotesMessageCode -> EncodeSecuritiesABloxTradeQuotesMessage(message.body)
      [] message.tag = SecuritiesABloxTradeQuotesMessageCode2 -> EncodeSecuritiesABloxTradeQuotesMessage(message.body)
      [] message.tag = SecuritiesABloxTradeQuotesMessageCode3 -> EncodeSecuritiesABloxTradeQuotesMessage(message.body)
      [] message.tag = SecuritiesABloxTradeQuotesMessageCode4 -> EncodeSecuritiesABloxTradeQuotesMessage(message.body)
      [] message.tag = SecuritiesABloxTradeQuotesMessageCode5 -> EncodeSecuritiesABloxTradeQuotesMessage(message.body)
      [] message.tag = SecuritiesEtnProfitStructureMessageCode -> EncodeSecuritiesEtnProfitStructureMessage(message.body)
      [] message.tag = SecuritiesTopFiveTradersActivitiesMessageCode -> EncodeSecuritiesTopFiveTradersActivitiesMessage(message.body)
      [] message.tag = SecuritiesTopFiveTradersActivitiesMessageCode2 -> EncodeSecuritiesTopFiveTradersActivitiesMessage(message.body)
      [] message.tag = SecuritiesTopFiveTradersActivitiesMessageCode3 -> EncodeSecuritiesTopFiveTradersActivitiesMessage(message.body)
      [] message.tag = SecuritiesTopFiveTradersActivitiesMessageCode4 -> EncodeSecuritiesTopFiveTradersActivitiesMessage(message.body)
      [] message.tag = SecuritiesTopFiveTradersActivitiesMessageCode5 -> EncodeSecuritiesTopFiveTradersActivitiesMessage(message.body)
      [] message.tag = SecuritiesTopFiveTradersActivitiesMessageCode6 -> EncodeSecuritiesTopFiveTradersActivitiesMessage(message.body)
      [] message.tag = SecuritiesTopFiveTradersActivitiesMessageCode7 -> EncodeSecuritiesTopFiveTradersActivitiesMessage(message.body)
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
              [] tag = SecuritiesQuoteMmLpExcludedMessageCode -> DecodeSecuritiesQuoteMmLpExcludedMessage(bytes)
              [] tag = SecuritiesQuoteMmLpExcludedMessageCode2 -> DecodeSecuritiesQuoteMmLpExcludedMessage(bytes)
              [] tag = SecuritiesQuoteMmLpExcludedMessageCode3 -> DecodeSecuritiesQuoteMmLpExcludedMessage(bytes)
              [] tag = SecuritiesQuoteMmLpIncludedMessageCode -> DecodeSecuritiesQuoteMmLpIncludedMessage(bytes)
              [] tag = SecuritiesQuoteMmLpIncludedMessageCode2 -> DecodeSecuritiesQuoteMmLpIncludedMessage(bytes)
              [] tag = SecuritiesQuoteMmLpIncludedMessageCode3 -> DecodeSecuritiesQuoteMmLpIncludedMessage(bytes)
              [] tag = SecuritiesQuoteMmLpIncludedMessageCode4 -> DecodeSecuritiesQuoteMmLpIncludedMessage(bytes)
              [] tag = SecuritiesSnapshotMmLpExcludedMessageCode -> DecodeSecuritiesSnapshotMmLpExcludedMessage(bytes)
              [] tag = SecuritiesSnapshotMmLpExcludedMessageCode2 -> DecodeSecuritiesSnapshotMmLpExcludedMessage(bytes)
              [] tag = SecuritiesSnapshotMmLpIncludedMessageCode -> DecodeSecuritiesSnapshotMmLpIncludedMessage(bytes)
              [] tag = SecuritiesSnapshotMmLpIncludedMessageCode2 -> DecodeSecuritiesSnapshotMmLpIncludedMessage(bytes)
              [] tag = SecuritiesSnapshotMmLpIncludedMessageCode3 -> DecodeSecuritiesSnapshotMmLpIncludedMessage(bytes)
              [] tag = SecuritiesSnapshotMmLpIncludedMessageCode4 -> DecodeSecuritiesSnapshotMmLpIncludedMessage(bytes)
              [] tag = SecuritiesOrderFilledMessageCode -> DecodeSecuritiesOrderFilledMessage(bytes)
              [] tag = SecuritiesOrderFilledMessageCode2 -> DecodeSecuritiesOrderFilledMessage(bytes)
              [] tag = SecuritiesOrderFilledMessageCode3 -> DecodeSecuritiesOrderFilledMessage(bytes)
              [] tag = SecuritiesOrderFilledMessageCode4 -> DecodeSecuritiesOrderFilledMessage(bytes)
              [] tag = SecuritiesOrderFilledMessageCode5 -> DecodeSecuritiesOrderFilledMessage(bytes)
              [] tag = SecuritiesOrderFilledMessageCode6 -> DecodeSecuritiesOrderFilledMessage(bytes)
              [] tag = SecuritiesOrderFilledMessageCode7 -> DecodeSecuritiesOrderFilledMessage(bytes)
              [] tag = SecuritiesNegotiatedTradeMessageCode -> DecodeSecuritiesNegotiatedTradeMessage(bytes)
              [] tag = SecuritiesNegotiatedTradeMessageCode2 -> DecodeSecuritiesNegotiatedTradeMessage(bytes)
              [] tag = SecuritiesNegotiatedTradeMessageCode3 -> DecodeSecuritiesNegotiatedTradeMessage(bytes)
              [] tag = SecuritiesNegotiatedTradeMessageCode4 -> DecodeSecuritiesNegotiatedTradeMessage(bytes)
              [] tag = SecuritiesNegotiatedTradeMessageCode5 -> DecodeSecuritiesNegotiatedTradeMessage(bytes)
              [] tag = SecuritiesNegotiatedTradeMessageCode6 -> DecodeSecuritiesNegotiatedTradeMessage(bytes)
              [] tag = SecuritiesNegotiatedTradeMessageCode7 -> DecodeSecuritiesNegotiatedTradeMessage(bytes)
              [] tag = SecuritiesMarketOperationTsMessageCode -> DecodeSecuritiesMarketOperationTsMessage(bytes)
              [] tag = SecuritiesMarketOperationTsMessageCode2 -> DecodeSecuritiesMarketOperationTsMessage(bytes)
              [] tag = SecuritiesMarketOperationTsMessageCode3 -> DecodeSecuritiesMarketOperationTsMessage(bytes)
              [] tag = SecuritiesMarketOperationTsMessageCode4 -> DecodeSecuritiesMarketOperationTsMessage(bytes)
              [] tag = SecuritiesMarketOperationTsMessageCode5 -> DecodeSecuritiesMarketOperationTsMessage(bytes)
              [] tag = SecuritiesMarketOperationTsMessageCode6 -> DecodeSecuritiesMarketOperationTsMessage(bytes)
              [] tag = SecuritiesMarketOperationTsMessageCode7 -> DecodeSecuritiesMarketOperationTsMessage(bytes)
              [] tag = SecuritiesMarketOperationTsMessageCode8 -> DecodeSecuritiesMarketOperationTsMessage(bytes)
              [] tag = SecuritiesMarketOperationTsMessageCode9 -> DecodeSecuritiesMarketOperationTsMessage(bytes)
              [] tag = SecuritiesMarketOperationTsMessageCode10 -> DecodeSecuritiesMarketOperationTsMessage(bytes)
              [] tag = SecuritiesMarketOperationTsMessageCode11 -> DecodeSecuritiesMarketOperationTsMessage(bytes)
              [] tag = SecuritiesMarketOperationTsMessageCode12 -> DecodeSecuritiesMarketOperationTsMessage(bytes)
              [] tag = SecuritiesMarketOperationTsMessageCode13 -> DecodeSecuritiesMarketOperationTsMessage(bytes)
              [] tag = SecuritiesMarketOperationTsMessageCode14 -> DecodeSecuritiesMarketOperationTsMessage(bytes)
              [] tag = SecuritiesMarketOperationTsMessageCode15 -> DecodeSecuritiesMarketOperationTsMessage(bytes)
              [] tag = SecuritiesMarketOperationTsMessageCode16 -> DecodeSecuritiesMarketOperationTsMessage(bytes)
              [] tag = SecuritiesMarketOperationTsMessageCode17 -> DecodeSecuritiesMarketOperationTsMessage(bytes)
              [] tag = SecuritiesMarketOperationTsMessageCode18 -> DecodeSecuritiesMarketOperationTsMessage(bytes)
              [] tag = SecuritiesMarketOperationTsMessageCode19 -> DecodeSecuritiesMarketOperationTsMessage(bytes)
              [] tag = SecuritiesMarketOperationTsMessageCode20 -> DecodeSecuritiesMarketOperationTsMessage(bytes)
              [] tag = SecuritiesMarketOperationTsMessageCode21 -> DecodeSecuritiesMarketOperationTsMessage(bytes)
              [] tag = SecuritiesMarketOperationTsMessageCode22 -> DecodeSecuritiesMarketOperationTsMessage(bytes)
              [] tag = SecuritiesMarketOperationTsMessageCode23 -> DecodeSecuritiesMarketOperationTsMessage(bytes)
              [] tag = SecuritiesMarketOperationTsMessageCode24 -> DecodeSecuritiesMarketOperationTsMessage(bytes)
              [] tag = SecuritiesMarketOperationTsMessageCode25 -> DecodeSecuritiesMarketOperationTsMessage(bytes)
              [] tag = SecuritiesMarketOperationTsMessageCode26 -> DecodeSecuritiesMarketOperationTsMessage(bytes)
              [] tag = SecuritiesMarketOperationTsMessageCode27 -> DecodeSecuritiesMarketOperationTsMessage(bytes)
              [] tag = SecuritiesMarketOperationTsMessageCode28 -> DecodeSecuritiesMarketOperationTsMessage(bytes)
              [] tag = SecuritiesMarketOperationTsMessageCode29 -> DecodeSecuritiesMarketOperationTsMessage(bytes)
              [] tag = SecuritiesMarketOperationTsMessageCode30 -> DecodeSecuritiesMarketOperationTsMessage(bytes)
              [] tag = SecuritiesDeterminationOfBasePriceMessageCode -> DecodeSecuritiesDeterminationOfBasePriceMessage(bytes)
              [] tag = SecuritiesDeterminationOfBasePriceMessageCode2 -> DecodeSecuritiesDeterminationOfBasePriceMessage(bytes)
              [] tag = SecuritiesDeterminationOfBasePriceMessageCode3 -> DecodeSecuritiesDeterminationOfBasePriceMessage(bytes)
              [] tag = SecuritiesDeterminationOfBasePriceMessageCode4 -> DecodeSecuritiesDeterminationOfBasePriceMessage(bytes)
              [] tag = SecuritiesDeterminationOfBasePriceMessageCode5 -> DecodeSecuritiesDeterminationOfBasePriceMessage(bytes)
              [] tag = SecuritiesDeterminationOfBasePriceMessageCode6 -> DecodeSecuritiesDeterminationOfBasePriceMessage(bytes)
              [] tag = SecuritiesIssueClosingMessageCode -> DecodeSecuritiesIssueClosingMessage(bytes)
              [] tag = SecuritiesIssueClosingMessageCode2 -> DecodeSecuritiesIssueClosingMessage(bytes)
              [] tag = SecuritiesIssueClosingMessageCode3 -> DecodeSecuritiesIssueClosingMessage(bytes)
              [] tag = SecuritiesIssueClosingMessageCode4 -> DecodeSecuritiesIssueClosingMessage(bytes)
              [] tag = SecuritiesIssueClosingMessageCode5 -> DecodeSecuritiesIssueClosingMessage(bytes)
              [] tag = SecuritiesIssueClosingMessageCode6 -> DecodeSecuritiesIssueClosingMessage(bytes)
              [] tag = SecuritiesIssueClosingMessageCode7 -> DecodeSecuritiesIssueClosingMessage(bytes)
              [] tag = SecuritiesIssueClosingMessageCode8 -> DecodeSecuritiesIssueClosingMessage(bytes)
              [] tag = SecuritiesIssueClosingMessageCode9 -> DecodeSecuritiesIssueClosingMessage(bytes)
              [] tag = SecuritiesMarketOperationScheduleMessageCode -> DecodeSecuritiesMarketOperationScheduleMessage(bytes)
              [] tag = SecuritiesMarketOperationScheduleMessageCode2 -> DecodeSecuritiesMarketOperationScheduleMessage(bytes)
              [] tag = SecuritiesMarketOperationScheduleMessageCode3 -> DecodeSecuritiesMarketOperationScheduleMessage(bytes)
              [] tag = SecuritiesMarketOperationScheduleMessageCode4 -> DecodeSecuritiesMarketOperationScheduleMessage(bytes)
              [] tag = SecuritiesMarketOperationScheduleMessageCode5 -> DecodeSecuritiesMarketOperationScheduleMessage(bytes)
              [] tag = SecuritiesMarketOperationScheduleMessageCode6 -> DecodeSecuritiesMarketOperationScheduleMessage(bytes)
              [] tag = SecuritiesMarketOperationScheduleMessageCode7 -> DecodeSecuritiesMarketOperationScheduleMessage(bytes)
              [] tag = SecuritiesMarketOperationScheduleMessageCode8 -> DecodeSecuritiesMarketOperationScheduleMessage(bytes)
              [] tag = SecuritiesMarketOperationScheduleMessageCode9 -> DecodeSecuritiesMarketOperationScheduleMessage(bytes)
              [] tag = SecuritiesMarketOperationScheduleMessageCode10 -> DecodeSecuritiesMarketOperationScheduleMessage(bytes)
              [] tag = SecuritiesMarketOperationScheduleMessageCode11 -> DecodeSecuritiesMarketOperationScheduleMessage(bytes)
              [] tag = SecuritiesMarketOperationScheduleMessageCode12 -> DecodeSecuritiesMarketOperationScheduleMessage(bytes)
              [] tag = SecuritiesMarketOperationScheduleMessageCode13 -> DecodeSecuritiesMarketOperationScheduleMessage(bytes)
              [] tag = SecuritiesMarketOperationScheduleMessageCode14 -> DecodeSecuritiesMarketOperationScheduleMessage(bytes)
              [] tag = SecuritiesMarketOperationScheduleMessageCode15 -> DecodeSecuritiesMarketOperationScheduleMessage(bytes)
              [] tag = SecuritiesMarketOperationScheduleMessageCode16 -> DecodeSecuritiesMarketOperationScheduleMessage(bytes)
              [] tag = SecuritiesMarketOperationScheduleMessageCode17 -> DecodeSecuritiesMarketOperationScheduleMessage(bytes)
              [] tag = SecuritiesMarketOperationScheduleMessageCode18 -> DecodeSecuritiesMarketOperationScheduleMessage(bytes)
              [] tag = SecuritiesMarketOperationScheduleMessageCode19 -> DecodeSecuritiesMarketOperationScheduleMessage(bytes)
              [] tag = SecuritiesMarketOperationScheduleMessageCode20 -> DecodeSecuritiesMarketOperationScheduleMessage(bytes)
              [] tag = SecuritiesMarketOperationScheduleMessageCode21 -> DecodeSecuritiesMarketOperationScheduleMessage(bytes)
              [] tag = SecuritiesMarketOperationScheduleMessageCode22 -> DecodeSecuritiesMarketOperationScheduleMessage(bytes)
              [] tag = SecuritiesMarketOperationScheduleMessageCode23 -> DecodeSecuritiesMarketOperationScheduleMessage(bytes)
              [] tag = SecuritiesMarketOperationScheduleMessageCode24 -> DecodeSecuritiesMarketOperationScheduleMessage(bytes)
              [] tag = SecuritiesMarketOperationScheduleMessageCode25 -> DecodeSecuritiesMarketOperationScheduleMessage(bytes)
              [] tag = SecuritiesMarketOperationScheduleMessageCode26 -> DecodeSecuritiesMarketOperationScheduleMessage(bytes)
              [] tag = SecuritiesMarketOperationScheduleMessageCode27 -> DecodeSecuritiesMarketOperationScheduleMessage(bytes)
              [] tag = SecuritiesMarketOperationScheduleMessageCode28 -> DecodeSecuritiesMarketOperationScheduleMessage(bytes)
              [] tag = SecuritiesMarketOperationScheduleMessageCode29 -> DecodeSecuritiesMarketOperationScheduleMessage(bytes)
              [] tag = SecuritiesMarketOperationScheduleMessageCode30 -> DecodeSecuritiesMarketOperationScheduleMessage(bytes)
              [] tag = SecuritiesRandomEndMessageCode -> DecodeSecuritiesRandomEndMessage(bytes)
              [] tag = SecuritiesRandomEndMessageCode2 -> DecodeSecuritiesRandomEndMessage(bytes)
              [] tag = SecuritiesTriggeringViMessageCode -> DecodeSecuritiesTriggeringViMessage(bytes)
              [] tag = SecuritiesTriggeringViMessageCode2 -> DecodeSecuritiesTriggeringViMessage(bytes)
              [] tag = SecuritiesTriggeringViMessageCode3 -> DecodeSecuritiesTriggeringViMessage(bytes)
              [] tag = SecuritiesTriggeringViMessageCode4 -> DecodeSecuritiesTriggeringViMessage(bytes)
              [] tag = SecuritiesTriggeringViMessageCode5 -> DecodeSecuritiesTriggeringViMessage(bytes)
              [] tag = SecuritiesQuantityAllocationMessageCode -> DecodeSecuritiesQuantityAllocationMessage(bytes)
              [] tag = SecuritiesQuantityAllocationMessageCode2 -> DecodeSecuritiesQuantityAllocationMessage(bytes)
              [] tag = SecuritiesQuantityAllocationMessageCode3 -> DecodeSecuritiesQuantityAllocationMessage(bytes)
              [] tag = SecuritiesQuantityAllocationMessageCode4 -> DecodeSecuritiesQuantityAllocationMessage(bytes)
              [] tag = SecuritiesQuantityAllocationMessageCode5 -> DecodeSecuritiesQuantityAllocationMessage(bytes)
              [] tag = SecuritiesQuantityAllocationMessageCode6 -> DecodeSecuritiesQuantityAllocationMessage(bytes)
              [] tag = SecuritiesQuantityAllocationMessageCode7 -> DecodeSecuritiesQuantityAllocationMessage(bytes)
              [] tag = SecuritiesQuantityAllocationMessageCode8 -> DecodeSecuritiesQuantityAllocationMessage(bytes)
              [] tag = SecuritiesQuantityAllocationMessageCode9 -> DecodeSecuritiesQuantityAllocationMessage(bytes)
              [] tag = SecuritiesQuantityAllocationMessageCode10 -> DecodeSecuritiesQuantityAllocationMessage(bytes)
              [] tag = SecuritiesQuantityAllocationMessageCode11 -> DecodeSecuritiesQuantityAllocationMessage(bytes)
              [] tag = SecuritiesQuantityAllocationMessageCode12 -> DecodeSecuritiesQuantityAllocationMessage(bytes)
              [] tag = SecuritiesQuantityAllocationMessageCode13 -> DecodeSecuritiesQuantityAllocationMessage(bytes)
              [] tag = SecuritiesQuantityAllocationMessageCode14 -> DecodeSecuritiesQuantityAllocationMessage(bytes)
              [] tag = SecuritiesQuantityAllocationMessageCode15 -> DecodeSecuritiesQuantityAllocationMessage(bytes)
              [] tag = SecuritiesQuantityAllocationMessageCode16 -> DecodeSecuritiesQuantityAllocationMessage(bytes)
              [] tag = SecuritiesQuantityAllocationMessageCode17 -> DecodeSecuritiesQuantityAllocationMessage(bytes)
              [] tag = SecuritiesQuantityAllocationMessageCode18 -> DecodeSecuritiesQuantityAllocationMessage(bytes)
              [] tag = SecuritiesQuantityAllocationMessageCode19 -> DecodeSecuritiesQuantityAllocationMessage(bytes)
              [] tag = SecuritiesQuantityAllocationMessageCode20 -> DecodeSecuritiesQuantityAllocationMessage(bytes)
              [] tag = SecuritiesQuantityAllocationMessageCode21 -> DecodeSecuritiesQuantityAllocationMessage(bytes)
              [] tag = SecuritiesQuantityAllocationMessageCode22 -> DecodeSecuritiesQuantityAllocationMessage(bytes)
              [] tag = SecuritiesQuantityAllocationMessageCode23 -> DecodeSecuritiesQuantityAllocationMessage(bytes)
              [] tag = SecuritiesMemberFirmSanctionsMessageCode -> DecodeSecuritiesMemberFirmSanctionsMessage(bytes)
              [] tag = SecuritiesMemberFirmSanctionsMessageCode2 -> DecodeSecuritiesMemberFirmSanctionsMessage(bytes)
              [] tag = SecuritiesMemberFirmSanctionsMessageCode3 -> DecodeSecuritiesMemberFirmSanctionsMessage(bytes)
              [] tag = SecuritiesMemberFirmSanctionsMessageCode4 -> DecodeSecuritiesMemberFirmSanctionsMessage(bytes)
              [] tag = SecuritiesMemberFirmSanctionsMessageCode5 -> DecodeSecuritiesMemberFirmSanctionsMessage(bytes)
              [] tag = SecuritiesMemberFirmSanctionsMessageCode6 -> DecodeSecuritiesMemberFirmSanctionsMessage(bytes)
              [] tag = SecuritiesMemberFirmSanctionsMessageCode7 -> DecodeSecuritiesMemberFirmSanctionsMessage(bytes)
              [] tag = SecuritiesMemberFirmSanctionsMessageCode8 -> DecodeSecuritiesMemberFirmSanctionsMessage(bytes)
              [] tag = SecuritiesMemberFirmSanctionsMessageCode9 -> DecodeSecuritiesMemberFirmSanctionsMessage(bytes)
              [] tag = SecuritiesMemberFirmSanctionsMessageCode10 -> DecodeSecuritiesMemberFirmSanctionsMessage(bytes)
              [] tag = SecuritiesMemberFirmSanctionsMessageCode11 -> DecodeSecuritiesMemberFirmSanctionsMessage(bytes)
              [] tag = SecuritiesEquitiesChangesOfBatchDataMessageCode -> DecodeSecuritiesEquitiesChangesOfBatchDataMessage(bytes)
              [] tag = SecuritiesEquitiesChangesOfBatchDataMessageCode2 -> DecodeSecuritiesEquitiesChangesOfBatchDataMessage(bytes)
              [] tag = SecuritiesEquitiesChangesOfBatchDataMessageCode3 -> DecodeSecuritiesEquitiesChangesOfBatchDataMessage(bytes)
              [] tag = SecuritiesEquitiesChangesOfBatchDataMessageCode4 -> DecodeSecuritiesEquitiesChangesOfBatchDataMessage(bytes)
              [] tag = SecuritiesEquitiesChangesOfBatchDataMessageCode5 -> DecodeSecuritiesEquitiesChangesOfBatchDataMessage(bytes)
              [] tag = SecuritiesEquitiesChangesOfBatchDataMessageCode6 -> DecodeSecuritiesEquitiesChangesOfBatchDataMessage(bytes)
              [] tag = SecuritiesEquitiesChangesOfBatchDataMessageCode7 -> DecodeSecuritiesEquitiesChangesOfBatchDataMessage(bytes)
              [] tag = SecuritiesGroupOrderAcceptanceHaltMessageCode -> DecodeSecuritiesGroupOrderAcceptanceHaltMessage(bytes)
              [] tag = SecuritiesGroupOrderAcceptanceHaltMessageCode2 -> DecodeSecuritiesGroupOrderAcceptanceHaltMessage(bytes)
              [] tag = SecuritiesGroupOrderAcceptanceHaltMessageCode3 -> DecodeSecuritiesGroupOrderAcceptanceHaltMessage(bytes)
              [] tag = SecuritiesGroupOrderAcceptanceHaltMessageCode4 -> DecodeSecuritiesGroupOrderAcceptanceHaltMessage(bytes)
              [] tag = SecuritiesGroupOrderAcceptanceHaltMessageCode5 -> DecodeSecuritiesGroupOrderAcceptanceHaltMessage(bytes)
              [] tag = SecuritiesGroupOrderAcceptanceHaltMessageCode6 -> DecodeSecuritiesGroupOrderAcceptanceHaltMessage(bytes)
              [] tag = SecuritiesGroupOrderAcceptanceHaltMessageCode7 -> DecodeSecuritiesGroupOrderAcceptanceHaltMessage(bytes)
              [] tag = SecuritiesGroupOrderAcceptanceHaltMessageCode8 -> DecodeSecuritiesGroupOrderAcceptanceHaltMessage(bytes)
              [] tag = SecuritiesGroupOrderAcceptanceHaltMessageCode9 -> DecodeSecuritiesGroupOrderAcceptanceHaltMessage(bytes)
              [] tag = SecuritiesGroupOrderAcceptanceHaltMessageCode10 -> DecodeSecuritiesGroupOrderAcceptanceHaltMessage(bytes)
              [] tag = SecuritiesGroupOrderAcceptanceHaltMessageCode11 -> DecodeSecuritiesGroupOrderAcceptanceHaltMessage(bytes)
              [] tag = SecuritiesGroupOrderAcceptanceHaltMessageCode12 -> DecodeSecuritiesGroupOrderAcceptanceHaltMessage(bytes)
              [] tag = SecuritiesGroupOrderAcceptanceHaltMessageCode13 -> DecodeSecuritiesGroupOrderAcceptanceHaltMessage(bytes)
              [] tag = SecuritiesGroupOrderAcceptanceHaltMessageCode14 -> DecodeSecuritiesGroupOrderAcceptanceHaltMessage(bytes)
              [] tag = SecuritiesGroupOrderAcceptanceHaltMessageCode15 -> DecodeSecuritiesGroupOrderAcceptanceHaltMessage(bytes)
              [] tag = SecuritiesGroupOrderAcceptanceHaltMessageCode16 -> DecodeSecuritiesGroupOrderAcceptanceHaltMessage(bytes)
              [] tag = SecuritiesGroupOrderAcceptanceHaltMessageCode17 -> DecodeSecuritiesGroupOrderAcceptanceHaltMessage(bytes)
              [] tag = SecuritiesGroupOrderAcceptanceHaltMessageCode18 -> DecodeSecuritiesGroupOrderAcceptanceHaltMessage(bytes)
              [] tag = SecuritiesGroupOrderAcceptanceHaltMessageCode19 -> DecodeSecuritiesGroupOrderAcceptanceHaltMessage(bytes)
              [] tag = SecuritiesGroupOrderAcceptanceHaltMessageCode20 -> DecodeSecuritiesGroupOrderAcceptanceHaltMessage(bytes)
              [] tag = SecuritiesGroupOrderAcceptanceHaltMessageCode21 -> DecodeSecuritiesGroupOrderAcceptanceHaltMessage(bytes)
              [] tag = SecuritiesGroupOrderAcceptanceHaltMessageCode22 -> DecodeSecuritiesGroupOrderAcceptanceHaltMessage(bytes)
              [] tag = SecuritiesGroupOrderAcceptanceHaltMessageCode23 -> DecodeSecuritiesGroupOrderAcceptanceHaltMessage(bytes)
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
              [] tag = SecuritiesElwBatchDataMessageCode -> DecodeSecuritiesElwBatchDataMessage(bytes)
              [] tag = SecuritiesEtnBatchDataMessageCode -> DecodeSecuritiesEtnBatchDataMessage(bytes)
              [] tag = SecuritiesEtnEarlyRedemptionMessageCode -> DecodeSecuritiesEtnEarlyRedemptionMessage(bytes)
              [] tag = SecuritiesEtpConstituentsMessageCode -> DecodeSecuritiesEtpConstituentsMessage(bytes)
              [] tag = SecuritiesKnockOutElwMessageCode -> DecodeSecuritiesKnockOutElwMessage(bytes)
              [] tag = SecuritiesKnockOutUnderlyingMessageCode -> DecodeSecuritiesKnockOutUnderlyingMessage(bytes)
              [] tag = SecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessageCode -> DecodeSecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage(bytes)
              [] tag = SecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessageCode2 -> DecodeSecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage(bytes)
              [] tag = SecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessageCode3 -> DecodeSecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage(bytes)
              [] tag = SecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessageCode4 -> DecodeSecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage(bytes)
              [] tag = SecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessageCode5 -> DecodeSecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage(bytes)
              [] tag = SecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessageCode6 -> DecodeSecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage(bytes)
              [] tag = SecuritiesABloxTradeQuotesMessageCode -> DecodeSecuritiesABloxTradeQuotesMessage(bytes)
              [] tag = SecuritiesABloxTradeQuotesMessageCode2 -> DecodeSecuritiesABloxTradeQuotesMessage(bytes)
              [] tag = SecuritiesABloxTradeQuotesMessageCode3 -> DecodeSecuritiesABloxTradeQuotesMessage(bytes)
              [] tag = SecuritiesABloxTradeQuotesMessageCode4 -> DecodeSecuritiesABloxTradeQuotesMessage(bytes)
              [] tag = SecuritiesABloxTradeQuotesMessageCode5 -> DecodeSecuritiesABloxTradeQuotesMessage(bytes)
              [] tag = SecuritiesEtnProfitStructureMessageCode -> DecodeSecuritiesEtnProfitStructureMessage(bytes)
              [] tag = SecuritiesTopFiveTradersActivitiesMessageCode -> DecodeSecuritiesTopFiveTradersActivitiesMessage(bytes)
              [] tag = SecuritiesTopFiveTradersActivitiesMessageCode2 -> DecodeSecuritiesTopFiveTradersActivitiesMessage(bytes)
              [] tag = SecuritiesTopFiveTradersActivitiesMessageCode3 -> DecodeSecuritiesTopFiveTradersActivitiesMessage(bytes)
              [] tag = SecuritiesTopFiveTradersActivitiesMessageCode4 -> DecodeSecuritiesTopFiveTradersActivitiesMessage(bytes)
              [] tag = SecuritiesTopFiveTradersActivitiesMessageCode5 -> DecodeSecuritiesTopFiveTradersActivitiesMessage(bytes)
              [] tag = SecuritiesTopFiveTradersActivitiesMessageCode6 -> DecodeSecuritiesTopFiveTradersActivitiesMessage(bytes)
              [] tag = SecuritiesTopFiveTradersActivitiesMessageCode7 -> DecodeSecuritiesTopFiveTradersActivitiesMessage(bytes)
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
        \cup { [tag |-> SecuritiesQuoteMmLpExcludedMessageCode, body |-> one] : one \in CheckedSecuritiesQuoteMmLpExcludedMessage }
        \cup { [tag |-> SecuritiesQuoteMmLpExcludedMessageCode2, body |-> one] : one \in CheckedSecuritiesQuoteMmLpExcludedMessage }
        \cup { [tag |-> SecuritiesQuoteMmLpExcludedMessageCode3, body |-> one] : one \in CheckedSecuritiesQuoteMmLpExcludedMessage }
        \cup { [tag |-> SecuritiesQuoteMmLpIncludedMessageCode, body |-> one] : one \in CheckedSecuritiesQuoteMmLpIncludedMessage }
        \cup { [tag |-> SecuritiesQuoteMmLpIncludedMessageCode2, body |-> one] : one \in CheckedSecuritiesQuoteMmLpIncludedMessage }
        \cup { [tag |-> SecuritiesQuoteMmLpIncludedMessageCode3, body |-> one] : one \in CheckedSecuritiesQuoteMmLpIncludedMessage }
        \cup { [tag |-> SecuritiesQuoteMmLpIncludedMessageCode4, body |-> one] : one \in CheckedSecuritiesQuoteMmLpIncludedMessage }
        \cup { [tag |-> SecuritiesSnapshotMmLpExcludedMessageCode, body |-> one] : one \in CheckedSecuritiesSnapshotMmLpExcludedMessage }
        \cup { [tag |-> SecuritiesSnapshotMmLpExcludedMessageCode2, body |-> one] : one \in CheckedSecuritiesSnapshotMmLpExcludedMessage }
        \cup { [tag |-> SecuritiesSnapshotMmLpIncludedMessageCode, body |-> one] : one \in CheckedSecuritiesSnapshotMmLpIncludedMessage }
        \cup { [tag |-> SecuritiesSnapshotMmLpIncludedMessageCode2, body |-> one] : one \in CheckedSecuritiesSnapshotMmLpIncludedMessage }
        \cup { [tag |-> SecuritiesSnapshotMmLpIncludedMessageCode3, body |-> one] : one \in CheckedSecuritiesSnapshotMmLpIncludedMessage }
        \cup { [tag |-> SecuritiesSnapshotMmLpIncludedMessageCode4, body |-> one] : one \in CheckedSecuritiesSnapshotMmLpIncludedMessage }
        \cup { [tag |-> SecuritiesOrderFilledMessageCode, body |-> one] : one \in CheckedSecuritiesOrderFilledMessage }
        \cup { [tag |-> SecuritiesOrderFilledMessageCode2, body |-> one] : one \in CheckedSecuritiesOrderFilledMessage }
        \cup { [tag |-> SecuritiesOrderFilledMessageCode3, body |-> one] : one \in CheckedSecuritiesOrderFilledMessage }
        \cup { [tag |-> SecuritiesOrderFilledMessageCode4, body |-> one] : one \in CheckedSecuritiesOrderFilledMessage }
        \cup { [tag |-> SecuritiesOrderFilledMessageCode5, body |-> one] : one \in CheckedSecuritiesOrderFilledMessage }
        \cup { [tag |-> SecuritiesOrderFilledMessageCode6, body |-> one] : one \in CheckedSecuritiesOrderFilledMessage }
        \cup { [tag |-> SecuritiesOrderFilledMessageCode7, body |-> one] : one \in CheckedSecuritiesOrderFilledMessage }
        \cup { [tag |-> SecuritiesNegotiatedTradeMessageCode, body |-> one] : one \in CheckedSecuritiesNegotiatedTradeMessage }
        \cup { [tag |-> SecuritiesNegotiatedTradeMessageCode2, body |-> one] : one \in CheckedSecuritiesNegotiatedTradeMessage }
        \cup { [tag |-> SecuritiesNegotiatedTradeMessageCode3, body |-> one] : one \in CheckedSecuritiesNegotiatedTradeMessage }
        \cup { [tag |-> SecuritiesNegotiatedTradeMessageCode4, body |-> one] : one \in CheckedSecuritiesNegotiatedTradeMessage }
        \cup { [tag |-> SecuritiesNegotiatedTradeMessageCode5, body |-> one] : one \in CheckedSecuritiesNegotiatedTradeMessage }
        \cup { [tag |-> SecuritiesNegotiatedTradeMessageCode6, body |-> one] : one \in CheckedSecuritiesNegotiatedTradeMessage }
        \cup { [tag |-> SecuritiesNegotiatedTradeMessageCode7, body |-> one] : one \in CheckedSecuritiesNegotiatedTradeMessage }
        \cup { [tag |-> SecuritiesMarketOperationTsMessageCode, body |-> one] : one \in CheckedSecuritiesMarketOperationTsMessage }
        \cup { [tag |-> SecuritiesMarketOperationTsMessageCode2, body |-> one] : one \in CheckedSecuritiesMarketOperationTsMessage }
        \cup { [tag |-> SecuritiesMarketOperationTsMessageCode3, body |-> one] : one \in CheckedSecuritiesMarketOperationTsMessage }
        \cup { [tag |-> SecuritiesMarketOperationTsMessageCode4, body |-> one] : one \in CheckedSecuritiesMarketOperationTsMessage }
        \cup { [tag |-> SecuritiesMarketOperationTsMessageCode5, body |-> one] : one \in CheckedSecuritiesMarketOperationTsMessage }
        \cup { [tag |-> SecuritiesMarketOperationTsMessageCode6, body |-> one] : one \in CheckedSecuritiesMarketOperationTsMessage }
        \cup { [tag |-> SecuritiesMarketOperationTsMessageCode7, body |-> one] : one \in CheckedSecuritiesMarketOperationTsMessage }
        \cup { [tag |-> SecuritiesMarketOperationTsMessageCode8, body |-> one] : one \in CheckedSecuritiesMarketOperationTsMessage }
        \cup { [tag |-> SecuritiesMarketOperationTsMessageCode9, body |-> one] : one \in CheckedSecuritiesMarketOperationTsMessage }
        \cup { [tag |-> SecuritiesMarketOperationTsMessageCode10, body |-> one] : one \in CheckedSecuritiesMarketOperationTsMessage }
        \cup { [tag |-> SecuritiesMarketOperationTsMessageCode11, body |-> one] : one \in CheckedSecuritiesMarketOperationTsMessage }
        \cup { [tag |-> SecuritiesMarketOperationTsMessageCode12, body |-> one] : one \in CheckedSecuritiesMarketOperationTsMessage }
        \cup { [tag |-> SecuritiesMarketOperationTsMessageCode13, body |-> one] : one \in CheckedSecuritiesMarketOperationTsMessage }
        \cup { [tag |-> SecuritiesMarketOperationTsMessageCode14, body |-> one] : one \in CheckedSecuritiesMarketOperationTsMessage }
        \cup { [tag |-> SecuritiesMarketOperationTsMessageCode15, body |-> one] : one \in CheckedSecuritiesMarketOperationTsMessage }
        \cup { [tag |-> SecuritiesMarketOperationTsMessageCode16, body |-> one] : one \in CheckedSecuritiesMarketOperationTsMessage }
        \cup { [tag |-> SecuritiesMarketOperationTsMessageCode17, body |-> one] : one \in CheckedSecuritiesMarketOperationTsMessage }
        \cup { [tag |-> SecuritiesMarketOperationTsMessageCode18, body |-> one] : one \in CheckedSecuritiesMarketOperationTsMessage }
        \cup { [tag |-> SecuritiesMarketOperationTsMessageCode19, body |-> one] : one \in CheckedSecuritiesMarketOperationTsMessage }
        \cup { [tag |-> SecuritiesMarketOperationTsMessageCode20, body |-> one] : one \in CheckedSecuritiesMarketOperationTsMessage }
        \cup { [tag |-> SecuritiesMarketOperationTsMessageCode21, body |-> one] : one \in CheckedSecuritiesMarketOperationTsMessage }
        \cup { [tag |-> SecuritiesMarketOperationTsMessageCode22, body |-> one] : one \in CheckedSecuritiesMarketOperationTsMessage }
        \cup { [tag |-> SecuritiesMarketOperationTsMessageCode23, body |-> one] : one \in CheckedSecuritiesMarketOperationTsMessage }
        \cup { [tag |-> SecuritiesMarketOperationTsMessageCode24, body |-> one] : one \in CheckedSecuritiesMarketOperationTsMessage }
        \cup { [tag |-> SecuritiesMarketOperationTsMessageCode25, body |-> one] : one \in CheckedSecuritiesMarketOperationTsMessage }
        \cup { [tag |-> SecuritiesMarketOperationTsMessageCode26, body |-> one] : one \in CheckedSecuritiesMarketOperationTsMessage }
        \cup { [tag |-> SecuritiesMarketOperationTsMessageCode27, body |-> one] : one \in CheckedSecuritiesMarketOperationTsMessage }
        \cup { [tag |-> SecuritiesMarketOperationTsMessageCode28, body |-> one] : one \in CheckedSecuritiesMarketOperationTsMessage }
        \cup { [tag |-> SecuritiesMarketOperationTsMessageCode29, body |-> one] : one \in CheckedSecuritiesMarketOperationTsMessage }
        \cup { [tag |-> SecuritiesMarketOperationTsMessageCode30, body |-> one] : one \in CheckedSecuritiesMarketOperationTsMessage }
        \cup { [tag |-> SecuritiesDeterminationOfBasePriceMessageCode, body |-> one] : one \in CheckedSecuritiesDeterminationOfBasePriceMessage }
        \cup { [tag |-> SecuritiesDeterminationOfBasePriceMessageCode2, body |-> one] : one \in CheckedSecuritiesDeterminationOfBasePriceMessage }
        \cup { [tag |-> SecuritiesDeterminationOfBasePriceMessageCode3, body |-> one] : one \in CheckedSecuritiesDeterminationOfBasePriceMessage }
        \cup { [tag |-> SecuritiesDeterminationOfBasePriceMessageCode4, body |-> one] : one \in CheckedSecuritiesDeterminationOfBasePriceMessage }
        \cup { [tag |-> SecuritiesDeterminationOfBasePriceMessageCode5, body |-> one] : one \in CheckedSecuritiesDeterminationOfBasePriceMessage }
        \cup { [tag |-> SecuritiesDeterminationOfBasePriceMessageCode6, body |-> one] : one \in CheckedSecuritiesDeterminationOfBasePriceMessage }
        \cup { [tag |-> SecuritiesIssueClosingMessageCode, body |-> one] : one \in CheckedSecuritiesIssueClosingMessage }
        \cup { [tag |-> SecuritiesIssueClosingMessageCode2, body |-> one] : one \in CheckedSecuritiesIssueClosingMessage }
        \cup { [tag |-> SecuritiesIssueClosingMessageCode3, body |-> one] : one \in CheckedSecuritiesIssueClosingMessage }
        \cup { [tag |-> SecuritiesIssueClosingMessageCode4, body |-> one] : one \in CheckedSecuritiesIssueClosingMessage }
        \cup { [tag |-> SecuritiesIssueClosingMessageCode5, body |-> one] : one \in CheckedSecuritiesIssueClosingMessage }
        \cup { [tag |-> SecuritiesIssueClosingMessageCode6, body |-> one] : one \in CheckedSecuritiesIssueClosingMessage }
        \cup { [tag |-> SecuritiesIssueClosingMessageCode7, body |-> one] : one \in CheckedSecuritiesIssueClosingMessage }
        \cup { [tag |-> SecuritiesIssueClosingMessageCode8, body |-> one] : one \in CheckedSecuritiesIssueClosingMessage }
        \cup { [tag |-> SecuritiesIssueClosingMessageCode9, body |-> one] : one \in CheckedSecuritiesIssueClosingMessage }
        \cup { [tag |-> SecuritiesMarketOperationScheduleMessageCode, body |-> one] : one \in CheckedSecuritiesMarketOperationScheduleMessage }
        \cup { [tag |-> SecuritiesMarketOperationScheduleMessageCode2, body |-> one] : one \in CheckedSecuritiesMarketOperationScheduleMessage }
        \cup { [tag |-> SecuritiesMarketOperationScheduleMessageCode3, body |-> one] : one \in CheckedSecuritiesMarketOperationScheduleMessage }
        \cup { [tag |-> SecuritiesMarketOperationScheduleMessageCode4, body |-> one] : one \in CheckedSecuritiesMarketOperationScheduleMessage }
        \cup { [tag |-> SecuritiesMarketOperationScheduleMessageCode5, body |-> one] : one \in CheckedSecuritiesMarketOperationScheduleMessage }
        \cup { [tag |-> SecuritiesMarketOperationScheduleMessageCode6, body |-> one] : one \in CheckedSecuritiesMarketOperationScheduleMessage }
        \cup { [tag |-> SecuritiesMarketOperationScheduleMessageCode7, body |-> one] : one \in CheckedSecuritiesMarketOperationScheduleMessage }
        \cup { [tag |-> SecuritiesMarketOperationScheduleMessageCode8, body |-> one] : one \in CheckedSecuritiesMarketOperationScheduleMessage }
        \cup { [tag |-> SecuritiesMarketOperationScheduleMessageCode9, body |-> one] : one \in CheckedSecuritiesMarketOperationScheduleMessage }
        \cup { [tag |-> SecuritiesMarketOperationScheduleMessageCode10, body |-> one] : one \in CheckedSecuritiesMarketOperationScheduleMessage }
        \cup { [tag |-> SecuritiesMarketOperationScheduleMessageCode11, body |-> one] : one \in CheckedSecuritiesMarketOperationScheduleMessage }
        \cup { [tag |-> SecuritiesMarketOperationScheduleMessageCode12, body |-> one] : one \in CheckedSecuritiesMarketOperationScheduleMessage }
        \cup { [tag |-> SecuritiesMarketOperationScheduleMessageCode13, body |-> one] : one \in CheckedSecuritiesMarketOperationScheduleMessage }
        \cup { [tag |-> SecuritiesMarketOperationScheduleMessageCode14, body |-> one] : one \in CheckedSecuritiesMarketOperationScheduleMessage }
        \cup { [tag |-> SecuritiesMarketOperationScheduleMessageCode15, body |-> one] : one \in CheckedSecuritiesMarketOperationScheduleMessage }
        \cup { [tag |-> SecuritiesMarketOperationScheduleMessageCode16, body |-> one] : one \in CheckedSecuritiesMarketOperationScheduleMessage }
        \cup { [tag |-> SecuritiesMarketOperationScheduleMessageCode17, body |-> one] : one \in CheckedSecuritiesMarketOperationScheduleMessage }
        \cup { [tag |-> SecuritiesMarketOperationScheduleMessageCode18, body |-> one] : one \in CheckedSecuritiesMarketOperationScheduleMessage }
        \cup { [tag |-> SecuritiesMarketOperationScheduleMessageCode19, body |-> one] : one \in CheckedSecuritiesMarketOperationScheduleMessage }
        \cup { [tag |-> SecuritiesMarketOperationScheduleMessageCode20, body |-> one] : one \in CheckedSecuritiesMarketOperationScheduleMessage }
        \cup { [tag |-> SecuritiesMarketOperationScheduleMessageCode21, body |-> one] : one \in CheckedSecuritiesMarketOperationScheduleMessage }
        \cup { [tag |-> SecuritiesMarketOperationScheduleMessageCode22, body |-> one] : one \in CheckedSecuritiesMarketOperationScheduleMessage }
        \cup { [tag |-> SecuritiesMarketOperationScheduleMessageCode23, body |-> one] : one \in CheckedSecuritiesMarketOperationScheduleMessage }
        \cup { [tag |-> SecuritiesMarketOperationScheduleMessageCode24, body |-> one] : one \in CheckedSecuritiesMarketOperationScheduleMessage }
        \cup { [tag |-> SecuritiesMarketOperationScheduleMessageCode25, body |-> one] : one \in CheckedSecuritiesMarketOperationScheduleMessage }
        \cup { [tag |-> SecuritiesMarketOperationScheduleMessageCode26, body |-> one] : one \in CheckedSecuritiesMarketOperationScheduleMessage }
        \cup { [tag |-> SecuritiesMarketOperationScheduleMessageCode27, body |-> one] : one \in CheckedSecuritiesMarketOperationScheduleMessage }
        \cup { [tag |-> SecuritiesMarketOperationScheduleMessageCode28, body |-> one] : one \in CheckedSecuritiesMarketOperationScheduleMessage }
        \cup { [tag |-> SecuritiesMarketOperationScheduleMessageCode29, body |-> one] : one \in CheckedSecuritiesMarketOperationScheduleMessage }
        \cup { [tag |-> SecuritiesMarketOperationScheduleMessageCode30, body |-> one] : one \in CheckedSecuritiesMarketOperationScheduleMessage }
        \cup { [tag |-> SecuritiesRandomEndMessageCode, body |-> one] : one \in CheckedSecuritiesRandomEndMessage }
        \cup { [tag |-> SecuritiesRandomEndMessageCode2, body |-> one] : one \in CheckedSecuritiesRandomEndMessage }
        \cup { [tag |-> SecuritiesTriggeringViMessageCode, body |-> one] : one \in CheckedSecuritiesTriggeringViMessage }
        \cup { [tag |-> SecuritiesTriggeringViMessageCode2, body |-> one] : one \in CheckedSecuritiesTriggeringViMessage }
        \cup { [tag |-> SecuritiesTriggeringViMessageCode3, body |-> one] : one \in CheckedSecuritiesTriggeringViMessage }
        \cup { [tag |-> SecuritiesTriggeringViMessageCode4, body |-> one] : one \in CheckedSecuritiesTriggeringViMessage }
        \cup { [tag |-> SecuritiesTriggeringViMessageCode5, body |-> one] : one \in CheckedSecuritiesTriggeringViMessage }
        \cup { [tag |-> SecuritiesQuantityAllocationMessageCode, body |-> one] : one \in CheckedSecuritiesQuantityAllocationMessage }
        \cup { [tag |-> SecuritiesQuantityAllocationMessageCode2, body |-> one] : one \in CheckedSecuritiesQuantityAllocationMessage }
        \cup { [tag |-> SecuritiesQuantityAllocationMessageCode3, body |-> one] : one \in CheckedSecuritiesQuantityAllocationMessage }
        \cup { [tag |-> SecuritiesQuantityAllocationMessageCode4, body |-> one] : one \in CheckedSecuritiesQuantityAllocationMessage }
        \cup { [tag |-> SecuritiesQuantityAllocationMessageCode5, body |-> one] : one \in CheckedSecuritiesQuantityAllocationMessage }
        \cup { [tag |-> SecuritiesQuantityAllocationMessageCode6, body |-> one] : one \in CheckedSecuritiesQuantityAllocationMessage }
        \cup { [tag |-> SecuritiesQuantityAllocationMessageCode7, body |-> one] : one \in CheckedSecuritiesQuantityAllocationMessage }
        \cup { [tag |-> SecuritiesQuantityAllocationMessageCode8, body |-> one] : one \in CheckedSecuritiesQuantityAllocationMessage }
        \cup { [tag |-> SecuritiesQuantityAllocationMessageCode9, body |-> one] : one \in CheckedSecuritiesQuantityAllocationMessage }
        \cup { [tag |-> SecuritiesQuantityAllocationMessageCode10, body |-> one] : one \in CheckedSecuritiesQuantityAllocationMessage }
        \cup { [tag |-> SecuritiesQuantityAllocationMessageCode11, body |-> one] : one \in CheckedSecuritiesQuantityAllocationMessage }
        \cup { [tag |-> SecuritiesQuantityAllocationMessageCode12, body |-> one] : one \in CheckedSecuritiesQuantityAllocationMessage }
        \cup { [tag |-> SecuritiesQuantityAllocationMessageCode13, body |-> one] : one \in CheckedSecuritiesQuantityAllocationMessage }
        \cup { [tag |-> SecuritiesQuantityAllocationMessageCode14, body |-> one] : one \in CheckedSecuritiesQuantityAllocationMessage }
        \cup { [tag |-> SecuritiesQuantityAllocationMessageCode15, body |-> one] : one \in CheckedSecuritiesQuantityAllocationMessage }
        \cup { [tag |-> SecuritiesQuantityAllocationMessageCode16, body |-> one] : one \in CheckedSecuritiesQuantityAllocationMessage }
        \cup { [tag |-> SecuritiesQuantityAllocationMessageCode17, body |-> one] : one \in CheckedSecuritiesQuantityAllocationMessage }
        \cup { [tag |-> SecuritiesQuantityAllocationMessageCode18, body |-> one] : one \in CheckedSecuritiesQuantityAllocationMessage }
        \cup { [tag |-> SecuritiesQuantityAllocationMessageCode19, body |-> one] : one \in CheckedSecuritiesQuantityAllocationMessage }
        \cup { [tag |-> SecuritiesQuantityAllocationMessageCode20, body |-> one] : one \in CheckedSecuritiesQuantityAllocationMessage }
        \cup { [tag |-> SecuritiesQuantityAllocationMessageCode21, body |-> one] : one \in CheckedSecuritiesQuantityAllocationMessage }
        \cup { [tag |-> SecuritiesQuantityAllocationMessageCode22, body |-> one] : one \in CheckedSecuritiesQuantityAllocationMessage }
        \cup { [tag |-> SecuritiesQuantityAllocationMessageCode23, body |-> one] : one \in CheckedSecuritiesQuantityAllocationMessage }
        \cup { [tag |-> SecuritiesMemberFirmSanctionsMessageCode, body |-> one] : one \in CheckedSecuritiesMemberFirmSanctionsMessage }
        \cup { [tag |-> SecuritiesMemberFirmSanctionsMessageCode2, body |-> one] : one \in CheckedSecuritiesMemberFirmSanctionsMessage }
        \cup { [tag |-> SecuritiesMemberFirmSanctionsMessageCode3, body |-> one] : one \in CheckedSecuritiesMemberFirmSanctionsMessage }
        \cup { [tag |-> SecuritiesMemberFirmSanctionsMessageCode4, body |-> one] : one \in CheckedSecuritiesMemberFirmSanctionsMessage }
        \cup { [tag |-> SecuritiesMemberFirmSanctionsMessageCode5, body |-> one] : one \in CheckedSecuritiesMemberFirmSanctionsMessage }
        \cup { [tag |-> SecuritiesMemberFirmSanctionsMessageCode6, body |-> one] : one \in CheckedSecuritiesMemberFirmSanctionsMessage }
        \cup { [tag |-> SecuritiesMemberFirmSanctionsMessageCode7, body |-> one] : one \in CheckedSecuritiesMemberFirmSanctionsMessage }
        \cup { [tag |-> SecuritiesMemberFirmSanctionsMessageCode8, body |-> one] : one \in CheckedSecuritiesMemberFirmSanctionsMessage }
        \cup { [tag |-> SecuritiesMemberFirmSanctionsMessageCode9, body |-> one] : one \in CheckedSecuritiesMemberFirmSanctionsMessage }
        \cup { [tag |-> SecuritiesMemberFirmSanctionsMessageCode10, body |-> one] : one \in CheckedSecuritiesMemberFirmSanctionsMessage }
        \cup { [tag |-> SecuritiesMemberFirmSanctionsMessageCode11, body |-> one] : one \in CheckedSecuritiesMemberFirmSanctionsMessage }
        \cup { [tag |-> SecuritiesEquitiesChangesOfBatchDataMessageCode, body |-> one] : one \in CheckedSecuritiesEquitiesChangesOfBatchDataMessage }
        \cup { [tag |-> SecuritiesEquitiesChangesOfBatchDataMessageCode2, body |-> one] : one \in CheckedSecuritiesEquitiesChangesOfBatchDataMessage }
        \cup { [tag |-> SecuritiesEquitiesChangesOfBatchDataMessageCode3, body |-> one] : one \in CheckedSecuritiesEquitiesChangesOfBatchDataMessage }
        \cup { [tag |-> SecuritiesEquitiesChangesOfBatchDataMessageCode4, body |-> one] : one \in CheckedSecuritiesEquitiesChangesOfBatchDataMessage }
        \cup { [tag |-> SecuritiesEquitiesChangesOfBatchDataMessageCode5, body |-> one] : one \in CheckedSecuritiesEquitiesChangesOfBatchDataMessage }
        \cup { [tag |-> SecuritiesEquitiesChangesOfBatchDataMessageCode6, body |-> one] : one \in CheckedSecuritiesEquitiesChangesOfBatchDataMessage }
        \cup { [tag |-> SecuritiesEquitiesChangesOfBatchDataMessageCode7, body |-> one] : one \in CheckedSecuritiesEquitiesChangesOfBatchDataMessage }
        \cup { [tag |-> SecuritiesGroupOrderAcceptanceHaltMessageCode, body |-> one] : one \in CheckedSecuritiesGroupOrderAcceptanceHaltMessage }
        \cup { [tag |-> SecuritiesGroupOrderAcceptanceHaltMessageCode2, body |-> one] : one \in CheckedSecuritiesGroupOrderAcceptanceHaltMessage }
        \cup { [tag |-> SecuritiesGroupOrderAcceptanceHaltMessageCode3, body |-> one] : one \in CheckedSecuritiesGroupOrderAcceptanceHaltMessage }
        \cup { [tag |-> SecuritiesGroupOrderAcceptanceHaltMessageCode4, body |-> one] : one \in CheckedSecuritiesGroupOrderAcceptanceHaltMessage }
        \cup { [tag |-> SecuritiesGroupOrderAcceptanceHaltMessageCode5, body |-> one] : one \in CheckedSecuritiesGroupOrderAcceptanceHaltMessage }
        \cup { [tag |-> SecuritiesGroupOrderAcceptanceHaltMessageCode6, body |-> one] : one \in CheckedSecuritiesGroupOrderAcceptanceHaltMessage }
        \cup { [tag |-> SecuritiesGroupOrderAcceptanceHaltMessageCode7, body |-> one] : one \in CheckedSecuritiesGroupOrderAcceptanceHaltMessage }
        \cup { [tag |-> SecuritiesGroupOrderAcceptanceHaltMessageCode8, body |-> one] : one \in CheckedSecuritiesGroupOrderAcceptanceHaltMessage }
        \cup { [tag |-> SecuritiesGroupOrderAcceptanceHaltMessageCode9, body |-> one] : one \in CheckedSecuritiesGroupOrderAcceptanceHaltMessage }
        \cup { [tag |-> SecuritiesGroupOrderAcceptanceHaltMessageCode10, body |-> one] : one \in CheckedSecuritiesGroupOrderAcceptanceHaltMessage }
        \cup { [tag |-> SecuritiesGroupOrderAcceptanceHaltMessageCode11, body |-> one] : one \in CheckedSecuritiesGroupOrderAcceptanceHaltMessage }
        \cup { [tag |-> SecuritiesGroupOrderAcceptanceHaltMessageCode12, body |-> one] : one \in CheckedSecuritiesGroupOrderAcceptanceHaltMessage }
        \cup { [tag |-> SecuritiesGroupOrderAcceptanceHaltMessageCode13, body |-> one] : one \in CheckedSecuritiesGroupOrderAcceptanceHaltMessage }
        \cup { [tag |-> SecuritiesGroupOrderAcceptanceHaltMessageCode14, body |-> one] : one \in CheckedSecuritiesGroupOrderAcceptanceHaltMessage }
        \cup { [tag |-> SecuritiesGroupOrderAcceptanceHaltMessageCode15, body |-> one] : one \in CheckedSecuritiesGroupOrderAcceptanceHaltMessage }
        \cup { [tag |-> SecuritiesGroupOrderAcceptanceHaltMessageCode16, body |-> one] : one \in CheckedSecuritiesGroupOrderAcceptanceHaltMessage }
        \cup { [tag |-> SecuritiesGroupOrderAcceptanceHaltMessageCode17, body |-> one] : one \in CheckedSecuritiesGroupOrderAcceptanceHaltMessage }
        \cup { [tag |-> SecuritiesGroupOrderAcceptanceHaltMessageCode18, body |-> one] : one \in CheckedSecuritiesGroupOrderAcceptanceHaltMessage }
        \cup { [tag |-> SecuritiesGroupOrderAcceptanceHaltMessageCode19, body |-> one] : one \in CheckedSecuritiesGroupOrderAcceptanceHaltMessage }
        \cup { [tag |-> SecuritiesGroupOrderAcceptanceHaltMessageCode20, body |-> one] : one \in CheckedSecuritiesGroupOrderAcceptanceHaltMessage }
        \cup { [tag |-> SecuritiesGroupOrderAcceptanceHaltMessageCode21, body |-> one] : one \in CheckedSecuritiesGroupOrderAcceptanceHaltMessage }
        \cup { [tag |-> SecuritiesGroupOrderAcceptanceHaltMessageCode22, body |-> one] : one \in CheckedSecuritiesGroupOrderAcceptanceHaltMessage }
        \cup { [tag |-> SecuritiesGroupOrderAcceptanceHaltMessageCode23, body |-> one] : one \in CheckedSecuritiesGroupOrderAcceptanceHaltMessage }
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
        \cup { [tag |-> SecuritiesElwBatchDataMessageCode, body |-> one] : one \in CheckedSecuritiesElwBatchDataMessage }
        \cup { [tag |-> SecuritiesEtnBatchDataMessageCode, body |-> one] : one \in CheckedSecuritiesEtnBatchDataMessage }
        \cup { [tag |-> SecuritiesEtnEarlyRedemptionMessageCode, body |-> one] : one \in CheckedSecuritiesEtnEarlyRedemptionMessage }
        \cup { [tag |-> SecuritiesEtpConstituentsMessageCode, body |-> one] : one \in CheckedSecuritiesEtpConstituentsMessage }
        \cup { [tag |-> SecuritiesKnockOutElwMessageCode, body |-> one] : one \in CheckedSecuritiesKnockOutElwMessage }
        \cup { [tag |-> SecuritiesKnockOutUnderlyingMessageCode, body |-> one] : one \in CheckedSecuritiesKnockOutUnderlyingMessage }
        \cup { [tag |-> SecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessageCode, body |-> one] : one \in CheckedSecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage }
        \cup { [tag |-> SecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessageCode2, body |-> one] : one \in CheckedSecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage }
        \cup { [tag |-> SecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessageCode3, body |-> one] : one \in CheckedSecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage }
        \cup { [tag |-> SecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessageCode4, body |-> one] : one \in CheckedSecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage }
        \cup { [tag |-> SecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessageCode5, body |-> one] : one \in CheckedSecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage }
        \cup { [tag |-> SecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessageCode6, body |-> one] : one \in CheckedSecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage }
        \cup { [tag |-> SecuritiesABloxTradeQuotesMessageCode, body |-> one] : one \in CheckedSecuritiesABloxTradeQuotesMessage }
        \cup { [tag |-> SecuritiesABloxTradeQuotesMessageCode2, body |-> one] : one \in CheckedSecuritiesABloxTradeQuotesMessage }
        \cup { [tag |-> SecuritiesABloxTradeQuotesMessageCode3, body |-> one] : one \in CheckedSecuritiesABloxTradeQuotesMessage }
        \cup { [tag |-> SecuritiesABloxTradeQuotesMessageCode4, body |-> one] : one \in CheckedSecuritiesABloxTradeQuotesMessage }
        \cup { [tag |-> SecuritiesABloxTradeQuotesMessageCode5, body |-> one] : one \in CheckedSecuritiesABloxTradeQuotesMessage }
        \cup { [tag |-> SecuritiesEtnProfitStructureMessageCode, body |-> one] : one \in CheckedSecuritiesEtnProfitStructureMessage }
        \cup { [tag |-> SecuritiesTopFiveTradersActivitiesMessageCode, body |-> one] : one \in CheckedSecuritiesTopFiveTradersActivitiesMessage }
        \cup { [tag |-> SecuritiesTopFiveTradersActivitiesMessageCode2, body |-> one] : one \in CheckedSecuritiesTopFiveTradersActivitiesMessage }
        \cup { [tag |-> SecuritiesTopFiveTradersActivitiesMessageCode3, body |-> one] : one \in CheckedSecuritiesTopFiveTradersActivitiesMessage }
        \cup { [tag |-> SecuritiesTopFiveTradersActivitiesMessageCode4, body |-> one] : one \in CheckedSecuritiesTopFiveTradersActivitiesMessage }
        \cup { [tag |-> SecuritiesTopFiveTradersActivitiesMessageCode5, body |-> one] : one \in CheckedSecuritiesTopFiveTradersActivitiesMessage }
        \cup { [tag |-> SecuritiesTopFiveTradersActivitiesMessageCode6, body |-> one] : one \in CheckedSecuritiesTopFiveTradersActivitiesMessage }
        \cup { [tag |-> SecuritiesTopFiveTradersActivitiesMessageCode7, body |-> one] : one \in CheckedSecuritiesTopFiveTradersActivitiesMessage }
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
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesQuoteMmLpExcludedMessageCode, body |-> ZeroSecuritiesQuoteMmLpExcludedMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesQuoteMmLpExcludedMessageCode2, body |-> ZeroSecuritiesQuoteMmLpExcludedMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesQuoteMmLpExcludedMessageCode3, body |-> ZeroSecuritiesQuoteMmLpExcludedMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesQuoteMmLpIncludedMessageCode, body |-> ZeroSecuritiesQuoteMmLpIncludedMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesQuoteMmLpIncludedMessageCode2, body |-> ZeroSecuritiesQuoteMmLpIncludedMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesQuoteMmLpIncludedMessageCode3, body |-> ZeroSecuritiesQuoteMmLpIncludedMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesQuoteMmLpIncludedMessageCode4, body |-> ZeroSecuritiesQuoteMmLpIncludedMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesSnapshotMmLpExcludedMessageCode, body |-> ZeroSecuritiesSnapshotMmLpExcludedMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesSnapshotMmLpExcludedMessageCode2, body |-> ZeroSecuritiesSnapshotMmLpExcludedMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesSnapshotMmLpIncludedMessageCode, body |-> ZeroSecuritiesSnapshotMmLpIncludedMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesSnapshotMmLpIncludedMessageCode2, body |-> ZeroSecuritiesSnapshotMmLpIncludedMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesSnapshotMmLpIncludedMessageCode3, body |-> ZeroSecuritiesSnapshotMmLpIncludedMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesSnapshotMmLpIncludedMessageCode4, body |-> ZeroSecuritiesSnapshotMmLpIncludedMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesOrderFilledMessageCode, body |-> ZeroSecuritiesOrderFilledMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesOrderFilledMessageCode2, body |-> ZeroSecuritiesOrderFilledMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesOrderFilledMessageCode3, body |-> ZeroSecuritiesOrderFilledMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesOrderFilledMessageCode4, body |-> ZeroSecuritiesOrderFilledMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesOrderFilledMessageCode5, body |-> ZeroSecuritiesOrderFilledMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesOrderFilledMessageCode6, body |-> ZeroSecuritiesOrderFilledMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesOrderFilledMessageCode7, body |-> ZeroSecuritiesOrderFilledMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesNegotiatedTradeMessageCode, body |-> ZeroSecuritiesNegotiatedTradeMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesNegotiatedTradeMessageCode2, body |-> ZeroSecuritiesNegotiatedTradeMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesNegotiatedTradeMessageCode3, body |-> ZeroSecuritiesNegotiatedTradeMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesNegotiatedTradeMessageCode4, body |-> ZeroSecuritiesNegotiatedTradeMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesNegotiatedTradeMessageCode5, body |-> ZeroSecuritiesNegotiatedTradeMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesNegotiatedTradeMessageCode6, body |-> ZeroSecuritiesNegotiatedTradeMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesNegotiatedTradeMessageCode7, body |-> ZeroSecuritiesNegotiatedTradeMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationTsMessageCode, body |-> ZeroSecuritiesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationTsMessageCode2, body |-> ZeroSecuritiesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationTsMessageCode3, body |-> ZeroSecuritiesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationTsMessageCode4, body |-> ZeroSecuritiesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationTsMessageCode5, body |-> ZeroSecuritiesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationTsMessageCode6, body |-> ZeroSecuritiesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationTsMessageCode7, body |-> ZeroSecuritiesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationTsMessageCode8, body |-> ZeroSecuritiesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationTsMessageCode9, body |-> ZeroSecuritiesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationTsMessageCode10, body |-> ZeroSecuritiesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationTsMessageCode11, body |-> ZeroSecuritiesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationTsMessageCode12, body |-> ZeroSecuritiesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationTsMessageCode13, body |-> ZeroSecuritiesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationTsMessageCode14, body |-> ZeroSecuritiesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationTsMessageCode15, body |-> ZeroSecuritiesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationTsMessageCode16, body |-> ZeroSecuritiesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationTsMessageCode17, body |-> ZeroSecuritiesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationTsMessageCode18, body |-> ZeroSecuritiesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationTsMessageCode19, body |-> ZeroSecuritiesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationTsMessageCode20, body |-> ZeroSecuritiesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationTsMessageCode21, body |-> ZeroSecuritiesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationTsMessageCode22, body |-> ZeroSecuritiesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationTsMessageCode23, body |-> ZeroSecuritiesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationTsMessageCode24, body |-> ZeroSecuritiesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationTsMessageCode25, body |-> ZeroSecuritiesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationTsMessageCode26, body |-> ZeroSecuritiesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationTsMessageCode27, body |-> ZeroSecuritiesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationTsMessageCode28, body |-> ZeroSecuritiesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationTsMessageCode29, body |-> ZeroSecuritiesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationTsMessageCode30, body |-> ZeroSecuritiesMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesDeterminationOfBasePriceMessageCode, body |-> ZeroSecuritiesDeterminationOfBasePriceMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesDeterminationOfBasePriceMessageCode2, body |-> ZeroSecuritiesDeterminationOfBasePriceMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesDeterminationOfBasePriceMessageCode3, body |-> ZeroSecuritiesDeterminationOfBasePriceMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesDeterminationOfBasePriceMessageCode4, body |-> ZeroSecuritiesDeterminationOfBasePriceMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesDeterminationOfBasePriceMessageCode5, body |-> ZeroSecuritiesDeterminationOfBasePriceMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesDeterminationOfBasePriceMessageCode6, body |-> ZeroSecuritiesDeterminationOfBasePriceMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesIssueClosingMessageCode, body |-> ZeroSecuritiesIssueClosingMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesIssueClosingMessageCode2, body |-> ZeroSecuritiesIssueClosingMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesIssueClosingMessageCode3, body |-> ZeroSecuritiesIssueClosingMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesIssueClosingMessageCode4, body |-> ZeroSecuritiesIssueClosingMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesIssueClosingMessageCode5, body |-> ZeroSecuritiesIssueClosingMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesIssueClosingMessageCode6, body |-> ZeroSecuritiesIssueClosingMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesIssueClosingMessageCode7, body |-> ZeroSecuritiesIssueClosingMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesIssueClosingMessageCode8, body |-> ZeroSecuritiesIssueClosingMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesIssueClosingMessageCode9, body |-> ZeroSecuritiesIssueClosingMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationScheduleMessageCode, body |-> ZeroSecuritiesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationScheduleMessageCode2, body |-> ZeroSecuritiesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationScheduleMessageCode3, body |-> ZeroSecuritiesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationScheduleMessageCode4, body |-> ZeroSecuritiesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationScheduleMessageCode5, body |-> ZeroSecuritiesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationScheduleMessageCode6, body |-> ZeroSecuritiesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationScheduleMessageCode7, body |-> ZeroSecuritiesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationScheduleMessageCode8, body |-> ZeroSecuritiesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationScheduleMessageCode9, body |-> ZeroSecuritiesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationScheduleMessageCode10, body |-> ZeroSecuritiesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationScheduleMessageCode11, body |-> ZeroSecuritiesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationScheduleMessageCode12, body |-> ZeroSecuritiesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationScheduleMessageCode13, body |-> ZeroSecuritiesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationScheduleMessageCode14, body |-> ZeroSecuritiesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationScheduleMessageCode15, body |-> ZeroSecuritiesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationScheduleMessageCode16, body |-> ZeroSecuritiesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationScheduleMessageCode17, body |-> ZeroSecuritiesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationScheduleMessageCode18, body |-> ZeroSecuritiesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationScheduleMessageCode19, body |-> ZeroSecuritiesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationScheduleMessageCode20, body |-> ZeroSecuritiesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationScheduleMessageCode21, body |-> ZeroSecuritiesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationScheduleMessageCode22, body |-> ZeroSecuritiesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationScheduleMessageCode23, body |-> ZeroSecuritiesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationScheduleMessageCode24, body |-> ZeroSecuritiesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationScheduleMessageCode25, body |-> ZeroSecuritiesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationScheduleMessageCode26, body |-> ZeroSecuritiesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationScheduleMessageCode27, body |-> ZeroSecuritiesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationScheduleMessageCode28, body |-> ZeroSecuritiesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationScheduleMessageCode29, body |-> ZeroSecuritiesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMarketOperationScheduleMessageCode30, body |-> ZeroSecuritiesMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesRandomEndMessageCode, body |-> ZeroSecuritiesRandomEndMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesRandomEndMessageCode2, body |-> ZeroSecuritiesRandomEndMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesTriggeringViMessageCode, body |-> ZeroSecuritiesTriggeringViMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesTriggeringViMessageCode2, body |-> ZeroSecuritiesTriggeringViMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesTriggeringViMessageCode3, body |-> ZeroSecuritiesTriggeringViMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesTriggeringViMessageCode4, body |-> ZeroSecuritiesTriggeringViMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesTriggeringViMessageCode5, body |-> ZeroSecuritiesTriggeringViMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesQuantityAllocationMessageCode, body |-> ZeroSecuritiesQuantityAllocationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesQuantityAllocationMessageCode2, body |-> ZeroSecuritiesQuantityAllocationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesQuantityAllocationMessageCode3, body |-> ZeroSecuritiesQuantityAllocationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesQuantityAllocationMessageCode4, body |-> ZeroSecuritiesQuantityAllocationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesQuantityAllocationMessageCode5, body |-> ZeroSecuritiesQuantityAllocationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesQuantityAllocationMessageCode6, body |-> ZeroSecuritiesQuantityAllocationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesQuantityAllocationMessageCode7, body |-> ZeroSecuritiesQuantityAllocationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesQuantityAllocationMessageCode8, body |-> ZeroSecuritiesQuantityAllocationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesQuantityAllocationMessageCode9, body |-> ZeroSecuritiesQuantityAllocationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesQuantityAllocationMessageCode10, body |-> ZeroSecuritiesQuantityAllocationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesQuantityAllocationMessageCode11, body |-> ZeroSecuritiesQuantityAllocationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesQuantityAllocationMessageCode12, body |-> ZeroSecuritiesQuantityAllocationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesQuantityAllocationMessageCode13, body |-> ZeroSecuritiesQuantityAllocationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesQuantityAllocationMessageCode14, body |-> ZeroSecuritiesQuantityAllocationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesQuantityAllocationMessageCode15, body |-> ZeroSecuritiesQuantityAllocationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesQuantityAllocationMessageCode16, body |-> ZeroSecuritiesQuantityAllocationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesQuantityAllocationMessageCode17, body |-> ZeroSecuritiesQuantityAllocationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesQuantityAllocationMessageCode18, body |-> ZeroSecuritiesQuantityAllocationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesQuantityAllocationMessageCode19, body |-> ZeroSecuritiesQuantityAllocationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesQuantityAllocationMessageCode20, body |-> ZeroSecuritiesQuantityAllocationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesQuantityAllocationMessageCode21, body |-> ZeroSecuritiesQuantityAllocationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesQuantityAllocationMessageCode22, body |-> ZeroSecuritiesQuantityAllocationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesQuantityAllocationMessageCode23, body |-> ZeroSecuritiesQuantityAllocationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMemberFirmSanctionsMessageCode, body |-> ZeroSecuritiesMemberFirmSanctionsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMemberFirmSanctionsMessageCode2, body |-> ZeroSecuritiesMemberFirmSanctionsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMemberFirmSanctionsMessageCode3, body |-> ZeroSecuritiesMemberFirmSanctionsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMemberFirmSanctionsMessageCode4, body |-> ZeroSecuritiesMemberFirmSanctionsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMemberFirmSanctionsMessageCode5, body |-> ZeroSecuritiesMemberFirmSanctionsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMemberFirmSanctionsMessageCode6, body |-> ZeroSecuritiesMemberFirmSanctionsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMemberFirmSanctionsMessageCode7, body |-> ZeroSecuritiesMemberFirmSanctionsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMemberFirmSanctionsMessageCode8, body |-> ZeroSecuritiesMemberFirmSanctionsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMemberFirmSanctionsMessageCode9, body |-> ZeroSecuritiesMemberFirmSanctionsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMemberFirmSanctionsMessageCode10, body |-> ZeroSecuritiesMemberFirmSanctionsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesMemberFirmSanctionsMessageCode11, body |-> ZeroSecuritiesMemberFirmSanctionsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesEquitiesChangesOfBatchDataMessageCode, body |-> ZeroSecuritiesEquitiesChangesOfBatchDataMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesEquitiesChangesOfBatchDataMessageCode2, body |-> ZeroSecuritiesEquitiesChangesOfBatchDataMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesEquitiesChangesOfBatchDataMessageCode3, body |-> ZeroSecuritiesEquitiesChangesOfBatchDataMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesEquitiesChangesOfBatchDataMessageCode4, body |-> ZeroSecuritiesEquitiesChangesOfBatchDataMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesEquitiesChangesOfBatchDataMessageCode5, body |-> ZeroSecuritiesEquitiesChangesOfBatchDataMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesEquitiesChangesOfBatchDataMessageCode6, body |-> ZeroSecuritiesEquitiesChangesOfBatchDataMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesEquitiesChangesOfBatchDataMessageCode7, body |-> ZeroSecuritiesEquitiesChangesOfBatchDataMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesGroupOrderAcceptanceHaltMessageCode, body |-> ZeroSecuritiesGroupOrderAcceptanceHaltMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesGroupOrderAcceptanceHaltMessageCode2, body |-> ZeroSecuritiesGroupOrderAcceptanceHaltMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesGroupOrderAcceptanceHaltMessageCode3, body |-> ZeroSecuritiesGroupOrderAcceptanceHaltMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesGroupOrderAcceptanceHaltMessageCode4, body |-> ZeroSecuritiesGroupOrderAcceptanceHaltMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesGroupOrderAcceptanceHaltMessageCode5, body |-> ZeroSecuritiesGroupOrderAcceptanceHaltMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesGroupOrderAcceptanceHaltMessageCode6, body |-> ZeroSecuritiesGroupOrderAcceptanceHaltMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesGroupOrderAcceptanceHaltMessageCode7, body |-> ZeroSecuritiesGroupOrderAcceptanceHaltMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesGroupOrderAcceptanceHaltMessageCode8, body |-> ZeroSecuritiesGroupOrderAcceptanceHaltMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesGroupOrderAcceptanceHaltMessageCode9, body |-> ZeroSecuritiesGroupOrderAcceptanceHaltMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesGroupOrderAcceptanceHaltMessageCode10, body |-> ZeroSecuritiesGroupOrderAcceptanceHaltMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesGroupOrderAcceptanceHaltMessageCode11, body |-> ZeroSecuritiesGroupOrderAcceptanceHaltMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesGroupOrderAcceptanceHaltMessageCode12, body |-> ZeroSecuritiesGroupOrderAcceptanceHaltMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesGroupOrderAcceptanceHaltMessageCode13, body |-> ZeroSecuritiesGroupOrderAcceptanceHaltMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesGroupOrderAcceptanceHaltMessageCode14, body |-> ZeroSecuritiesGroupOrderAcceptanceHaltMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesGroupOrderAcceptanceHaltMessageCode15, body |-> ZeroSecuritiesGroupOrderAcceptanceHaltMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesGroupOrderAcceptanceHaltMessageCode16, body |-> ZeroSecuritiesGroupOrderAcceptanceHaltMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesGroupOrderAcceptanceHaltMessageCode17, body |-> ZeroSecuritiesGroupOrderAcceptanceHaltMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesGroupOrderAcceptanceHaltMessageCode18, body |-> ZeroSecuritiesGroupOrderAcceptanceHaltMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesGroupOrderAcceptanceHaltMessageCode19, body |-> ZeroSecuritiesGroupOrderAcceptanceHaltMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesGroupOrderAcceptanceHaltMessageCode20, body |-> ZeroSecuritiesGroupOrderAcceptanceHaltMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesGroupOrderAcceptanceHaltMessageCode21, body |-> ZeroSecuritiesGroupOrderAcceptanceHaltMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesGroupOrderAcceptanceHaltMessageCode22, body |-> ZeroSecuritiesGroupOrderAcceptanceHaltMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesGroupOrderAcceptanceHaltMessageCode23, body |-> ZeroSecuritiesGroupOrderAcceptanceHaltMessage]],
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
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesBuyInVolumeMessageCode6, body |-> ZeroSecuritiesBuyInVolumeMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesElwBatchDataMessageCode, body |-> ZeroSecuritiesElwBatchDataMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesEtnBatchDataMessageCode, body |-> ZeroSecuritiesEtnBatchDataMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesEtnEarlyRedemptionMessageCode, body |-> ZeroSecuritiesEtnEarlyRedemptionMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesEtpConstituentsMessageCode, body |-> ZeroSecuritiesEtpConstituentsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesKnockOutElwMessageCode, body |-> ZeroSecuritiesKnockOutElwMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesKnockOutUnderlyingMessageCode, body |-> ZeroSecuritiesKnockOutUnderlyingMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessageCode, body |-> ZeroSecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessageCode2, body |-> ZeroSecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessageCode3, body |-> ZeroSecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessageCode4, body |-> ZeroSecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessageCode5, body |-> ZeroSecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessageCode6, body |-> ZeroSecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesABloxTradeQuotesMessageCode, body |-> ZeroSecuritiesABloxTradeQuotesMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesABloxTradeQuotesMessageCode2, body |-> ZeroSecuritiesABloxTradeQuotesMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesABloxTradeQuotesMessageCode3, body |-> ZeroSecuritiesABloxTradeQuotesMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesABloxTradeQuotesMessageCode4, body |-> ZeroSecuritiesABloxTradeQuotesMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesABloxTradeQuotesMessageCode5, body |-> ZeroSecuritiesABloxTradeQuotesMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesEtnProfitStructureMessageCode, body |-> ZeroSecuritiesEtnProfitStructureMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesTopFiveTradersActivitiesMessageCode, body |-> ZeroSecuritiesTopFiveTradersActivitiesMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesTopFiveTradersActivitiesMessageCode2, body |-> ZeroSecuritiesTopFiveTradersActivitiesMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesTopFiveTradersActivitiesMessageCode3, body |-> ZeroSecuritiesTopFiveTradersActivitiesMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesTopFiveTradersActivitiesMessageCode4, body |-> ZeroSecuritiesTopFiveTradersActivitiesMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesTopFiveTradersActivitiesMessageCode5, body |-> ZeroSecuritiesTopFiveTradersActivitiesMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesTopFiveTradersActivitiesMessageCode6, body |-> ZeroSecuritiesTopFiveTradersActivitiesMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SecuritiesTopFiveTradersActivitiesMessageCode7, body |-> ZeroSecuritiesTopFiveTradersActivitiesMessage]],
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

(* Every Securities Quote Mm Lp Excluded Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecuritiesQuoteMmLpExcludedMessage ==
    \A message \in CheckedSecuritiesQuoteMmLpExcludedMessage :
        LET read == DecodeSecuritiesQuoteMmLpExcludedMessage(EncodeSecuritiesQuoteMmLpExcludedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Securities Quote Mm Lp Included Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecuritiesQuoteMmLpIncludedMessage ==
    \A message \in CheckedSecuritiesQuoteMmLpIncludedMessage :
        LET read == DecodeSecuritiesQuoteMmLpIncludedMessage(EncodeSecuritiesQuoteMmLpIncludedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Securities Snapshot Mm Lp Excluded Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecuritiesSnapshotMmLpExcludedMessage ==
    \A message \in CheckedSecuritiesSnapshotMmLpExcludedMessage :
        LET read == DecodeSecuritiesSnapshotMmLpExcludedMessage(EncodeSecuritiesSnapshotMmLpExcludedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Securities Snapshot Mm Lp Included Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecuritiesSnapshotMmLpIncludedMessage ==
    \A message \in CheckedSecuritiesSnapshotMmLpIncludedMessage :
        LET read == DecodeSecuritiesSnapshotMmLpIncludedMessage(EncodeSecuritiesSnapshotMmLpIncludedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Securities Order Filled Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecuritiesOrderFilledMessage ==
    \A message \in CheckedSecuritiesOrderFilledMessage :
        LET read == DecodeSecuritiesOrderFilledMessage(EncodeSecuritiesOrderFilledMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Securities Negotiated Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecuritiesNegotiatedTradeMessage ==
    \A message \in CheckedSecuritiesNegotiatedTradeMessage :
        LET read == DecodeSecuritiesNegotiatedTradeMessage(EncodeSecuritiesNegotiatedTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Securities Market Operation Ts Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecuritiesMarketOperationTsMessage ==
    \A message \in CheckedSecuritiesMarketOperationTsMessage :
        LET read == DecodeSecuritiesMarketOperationTsMessage(EncodeSecuritiesMarketOperationTsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Securities Determination Of Base Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecuritiesDeterminationOfBasePriceMessage ==
    \A message \in CheckedSecuritiesDeterminationOfBasePriceMessage :
        LET read == DecodeSecuritiesDeterminationOfBasePriceMessage(EncodeSecuritiesDeterminationOfBasePriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Securities Issue Closing Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecuritiesIssueClosingMessage ==
    \A message \in CheckedSecuritiesIssueClosingMessage :
        LET read == DecodeSecuritiesIssueClosingMessage(EncodeSecuritiesIssueClosingMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Securities Market Operation Schedule Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecuritiesMarketOperationScheduleMessage ==
    \A message \in CheckedSecuritiesMarketOperationScheduleMessage :
        LET read == DecodeSecuritiesMarketOperationScheduleMessage(EncodeSecuritiesMarketOperationScheduleMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Securities Random End Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecuritiesRandomEndMessage ==
    \A message \in CheckedSecuritiesRandomEndMessage :
        LET read == DecodeSecuritiesRandomEndMessage(EncodeSecuritiesRandomEndMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Securities Triggering Vi Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecuritiesTriggeringViMessage ==
    \A message \in CheckedSecuritiesTriggeringViMessage :
        LET read == DecodeSecuritiesTriggeringViMessage(EncodeSecuritiesTriggeringViMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Securities Quantity Allocation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecuritiesQuantityAllocationMessage ==
    \A message \in CheckedSecuritiesQuantityAllocationMessage :
        LET read == DecodeSecuritiesQuantityAllocationMessage(EncodeSecuritiesQuantityAllocationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Securities Member Firm Sanctions Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecuritiesMemberFirmSanctionsMessage ==
    \A message \in CheckedSecuritiesMemberFirmSanctionsMessage :
        LET read == DecodeSecuritiesMemberFirmSanctionsMessage(EncodeSecuritiesMemberFirmSanctionsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Securities Equities Changes Of Batch Data Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecuritiesEquitiesChangesOfBatchDataMessage ==
    \A message \in CheckedSecuritiesEquitiesChangesOfBatchDataMessage :
        LET read == DecodeSecuritiesEquitiesChangesOfBatchDataMessage(EncodeSecuritiesEquitiesChangesOfBatchDataMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Securities Group Order Acceptance Halt Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecuritiesGroupOrderAcceptanceHaltMessage ==
    \A message \in CheckedSecuritiesGroupOrderAcceptanceHaltMessage :
        LET read == DecodeSecuritiesGroupOrderAcceptanceHaltMessage(EncodeSecuritiesGroupOrderAcceptanceHaltMessage(message))
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

(* Every Securities Elw Batch Data Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecuritiesElwBatchDataMessage ==
    \A message \in CheckedSecuritiesElwBatchDataMessage :
        LET read == DecodeSecuritiesElwBatchDataMessage(EncodeSecuritiesElwBatchDataMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Securities Etn Batch Data Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecuritiesEtnBatchDataMessage ==
    \A message \in CheckedSecuritiesEtnBatchDataMessage :
        LET read == DecodeSecuritiesEtnBatchDataMessage(EncodeSecuritiesEtnBatchDataMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Securities Etn Early Redemption Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecuritiesEtnEarlyRedemptionMessage ==
    \A message \in CheckedSecuritiesEtnEarlyRedemptionMessage :
        LET read == DecodeSecuritiesEtnEarlyRedemptionMessage(EncodeSecuritiesEtnEarlyRedemptionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Securities Etp Constituents Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecuritiesEtpConstituentsMessage ==
    \A message \in CheckedSecuritiesEtpConstituentsMessage :
        LET read == DecodeSecuritiesEtpConstituentsMessage(EncodeSecuritiesEtpConstituentsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Securities Knock Out Elw Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecuritiesKnockOutElwMessage ==
    \A message \in CheckedSecuritiesKnockOutElwMessage :
        LET read == DecodeSecuritiesKnockOutElwMessage(EncodeSecuritiesKnockOutElwMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Securities Knock Out Underlying Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecuritiesKnockOutUnderlyingMessage ==
    \A message \in CheckedSecuritiesKnockOutUnderlyingMessage :
        LET read == DecodeSecuritiesKnockOutUnderlyingMessage(EncodeSecuritiesKnockOutUnderlyingMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Securities Closing Price Trade Remaining Quantity On Quotes Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage ==
    \A message \in CheckedSecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage :
        LET read == DecodeSecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage(EncodeSecuritiesClosingPriceTradeRemainingQuantityOnQuotesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Securities A Blox Trade Quotes Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecuritiesABloxTradeQuotesMessage ==
    \A message \in CheckedSecuritiesABloxTradeQuotesMessage :
        LET read == DecodeSecuritiesABloxTradeQuotesMessage(EncodeSecuritiesABloxTradeQuotesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Securities Etn Profit Structure Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecuritiesEtnProfitStructureMessage ==
    \A message \in CheckedSecuritiesEtnProfitStructureMessage :
        LET read == DecodeSecuritiesEtnProfitStructureMessage(EncodeSecuritiesEtnProfitStructureMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Securities Top Five Traders Activities Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecuritiesTopFiveTradersActivitiesMessage ==
    \A message \in CheckedSecuritiesTopFiveTradersActivitiesMessage :
        LET read == DecodeSecuritiesTopFiveTradersActivitiesMessage(EncodeSecuritiesTopFiveTradersActivitiesMessage(message))
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
