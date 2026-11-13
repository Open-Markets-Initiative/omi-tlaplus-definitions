----------------- MODULE Koscom_MdcsRealtime_BondA_v2_020 ------------------
(***************************************************************************)
(* Koscom Co., Ltd. MDCS Realtime Bond A v2.020                            *)
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
      calculationTimeShort                 : Sample(6),
      index                                : Sample(9),
      indexChangeSignAgainstThePreviousDay : Sample(1),
      indexChangeAgainstThePreviousDay     : Sample(9),
      accumulatedTradingVolumeShort        : Sample(12),
      accumulatedTradingValueShort         : Sample(12),
      filler4                              : Sample(4),
      endKeyword                           : Sample(1) ]

EncodeKrxIndexMessage(message) ==
    message.indexId
        \o message.isinCode
        \o message.calculationTimeShort
        \o message.index
        \o message.indexChangeSignAgainstThePreviousDay
        \o message.indexChangeAgainstThePreviousDay
        \o message.accumulatedTradingVolumeShort
        \o message.accumulatedTradingValueShort
        \o message.filler4
        \o message.endKeyword

DecodeKrxIndexMessage(bytes) ==
    LET indexId == ReadBytes(bytes, 6) IN IF ~indexId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(indexId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET calculationTimeShort == ReadBytes(isinCode.rest, 6) IN IF ~calculationTimeShort.ok THEN Fail ELSE
    LET index == ReadBytes(calculationTimeShort.rest, 9) IN IF ~index.ok THEN Fail ELSE
    LET indexChangeSignAgainstThePreviousDay == ReadBytes(index.rest, 1) IN IF ~indexChangeSignAgainstThePreviousDay.ok THEN Fail ELSE
    LET indexChangeAgainstThePreviousDay == ReadBytes(indexChangeSignAgainstThePreviousDay.rest, 9) IN IF ~indexChangeAgainstThePreviousDay.ok THEN Fail ELSE
    LET accumulatedTradingVolumeShort == ReadBytes(indexChangeAgainstThePreviousDay.rest, 12) IN IF ~accumulatedTradingVolumeShort.ok THEN Fail ELSE
    LET accumulatedTradingValueShort == ReadBytes(accumulatedTradingVolumeShort.rest, 12) IN IF ~accumulatedTradingValueShort.ok THEN Fail ELSE
    LET filler4 == ReadBytes(accumulatedTradingValueShort.rest, 4) IN IF ~filler4.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler4.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ indexId                              |-> indexId.value,
         isinCode                             |-> isinCode.value,
         calculationTimeShort                 |-> calculationTimeShort.value,
         index                                |-> index.value,
         indexChangeSignAgainstThePreviousDay |-> indexChangeSignAgainstThePreviousDay.value,
         indexChangeAgainstThePreviousDay     |-> indexChangeAgainstThePreviousDay.value,
         accumulatedTradingVolumeShort        |-> accumulatedTradingVolumeShort.value,
         accumulatedTradingValueShort         |-> accumulatedTradingValueShort.value,
         filler4                              |-> filler4.value,
         endKeyword                           |-> endKeyword.value ], endKeyword.rest)

ZeroKrxIndexMessage ==
    [ indexId                              |-> [i \in 1 .. 6 |-> 0],
      isinCode                             |-> [i \in 1 .. 12 |-> 0],
      calculationTimeShort                 |-> [i \in 1 .. 6 |-> 0],
      index                                |-> [i \in 1 .. 9 |-> 0],
      indexChangeSignAgainstThePreviousDay |-> [i \in 1 .. 1 |-> 0],
      indexChangeAgainstThePreviousDay     |-> [i \in 1 .. 9 |-> 0],
      accumulatedTradingVolumeShort        |-> [i \in 1 .. 12 |-> 0],
      accumulatedTradingValueShort         |-> [i \in 1 .. 12 |-> 0],
      filler4                              |-> [i \in 1 .. 4 |-> 0],
      endKeyword                           |-> [i \in 1 .. 1 |-> 0] ]

(* Krx Index Message at zero, then each field in turn at the values it is checked at *)
CheckedKrxIndexMessage ==
    { ZeroKrxIndexMessage }
        \cup { [ZeroKrxIndexMessage EXCEPT !.indexId = one] : one \in Sample(6) }
        \cup { [ZeroKrxIndexMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroKrxIndexMessage EXCEPT !.calculationTimeShort = one] : one \in Sample(6) }
        \cup { [ZeroKrxIndexMessage EXCEPT !.index = one] : one \in Sample(9) }
        \cup { [ZeroKrxIndexMessage EXCEPT !.indexChangeSignAgainstThePreviousDay = one] : one \in Sample(1) }
        \cup { [ZeroKrxIndexMessage EXCEPT !.indexChangeAgainstThePreviousDay = one] : one \in Sample(9) }
        \cup { [ZeroKrxIndexMessage EXCEPT !.accumulatedTradingVolumeShort = one] : one \in Sample(12) }
        \cup { [ZeroKrxIndexMessage EXCEPT !.accumulatedTradingValueShort = one] : one \in Sample(12) }
        \cup { [ZeroKrxIndexMessage EXCEPT !.filler4 = one] : one \in Sample(4) }
        \cup { [ZeroKrxIndexMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Krx Estimated Index Message: 72 bytes                                   *)
(***************************************************************************)

KrxEstimatedIndexMessage ==
    [ indexId                              : Sample(6),
      isinCode                             : Sample(12),
      calculationTimeShort                 : Sample(6),
      index                                : Sample(9),
      indexChangeSignAgainstThePreviousDay : Sample(1),
      indexChangeAgainstThePreviousDay     : Sample(9),
      accumulatedTradingVolumeShort        : Sample(12),
      accumulatedTradingValueShort         : Sample(12),
      filler4                              : Sample(4),
      endKeyword                           : Sample(1) ]

EncodeKrxEstimatedIndexMessage(message) ==
    message.indexId
        \o message.isinCode
        \o message.calculationTimeShort
        \o message.index
        \o message.indexChangeSignAgainstThePreviousDay
        \o message.indexChangeAgainstThePreviousDay
        \o message.accumulatedTradingVolumeShort
        \o message.accumulatedTradingValueShort
        \o message.filler4
        \o message.endKeyword

DecodeKrxEstimatedIndexMessage(bytes) ==
    LET indexId == ReadBytes(bytes, 6) IN IF ~indexId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(indexId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET calculationTimeShort == ReadBytes(isinCode.rest, 6) IN IF ~calculationTimeShort.ok THEN Fail ELSE
    LET index == ReadBytes(calculationTimeShort.rest, 9) IN IF ~index.ok THEN Fail ELSE
    LET indexChangeSignAgainstThePreviousDay == ReadBytes(index.rest, 1) IN IF ~indexChangeSignAgainstThePreviousDay.ok THEN Fail ELSE
    LET indexChangeAgainstThePreviousDay == ReadBytes(indexChangeSignAgainstThePreviousDay.rest, 9) IN IF ~indexChangeAgainstThePreviousDay.ok THEN Fail ELSE
    LET accumulatedTradingVolumeShort == ReadBytes(indexChangeAgainstThePreviousDay.rest, 12) IN IF ~accumulatedTradingVolumeShort.ok THEN Fail ELSE
    LET accumulatedTradingValueShort == ReadBytes(accumulatedTradingVolumeShort.rest, 12) IN IF ~accumulatedTradingValueShort.ok THEN Fail ELSE
    LET filler4 == ReadBytes(accumulatedTradingValueShort.rest, 4) IN IF ~filler4.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler4.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ indexId                              |-> indexId.value,
         isinCode                             |-> isinCode.value,
         calculationTimeShort                 |-> calculationTimeShort.value,
         index                                |-> index.value,
         indexChangeSignAgainstThePreviousDay |-> indexChangeSignAgainstThePreviousDay.value,
         indexChangeAgainstThePreviousDay     |-> indexChangeAgainstThePreviousDay.value,
         accumulatedTradingVolumeShort        |-> accumulatedTradingVolumeShort.value,
         accumulatedTradingValueShort         |-> accumulatedTradingValueShort.value,
         filler4                              |-> filler4.value,
         endKeyword                           |-> endKeyword.value ], endKeyword.rest)

ZeroKrxEstimatedIndexMessage ==
    [ indexId                              |-> [i \in 1 .. 6 |-> 0],
      isinCode                             |-> [i \in 1 .. 12 |-> 0],
      calculationTimeShort                 |-> [i \in 1 .. 6 |-> 0],
      index                                |-> [i \in 1 .. 9 |-> 0],
      indexChangeSignAgainstThePreviousDay |-> [i \in 1 .. 1 |-> 0],
      indexChangeAgainstThePreviousDay     |-> [i \in 1 .. 9 |-> 0],
      accumulatedTradingVolumeShort        |-> [i \in 1 .. 12 |-> 0],
      accumulatedTradingValueShort         |-> [i \in 1 .. 12 |-> 0],
      filler4                              |-> [i \in 1 .. 4 |-> 0],
      endKeyword                           |-> [i \in 1 .. 1 |-> 0] ]

(* Krx Estimated Index Message at zero, then each field in turn at the values it is checked at *)
CheckedKrxEstimatedIndexMessage ==
    { ZeroKrxEstimatedIndexMessage }
        \cup { [ZeroKrxEstimatedIndexMessage EXCEPT !.indexId = one] : one \in Sample(6) }
        \cup { [ZeroKrxEstimatedIndexMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroKrxEstimatedIndexMessage EXCEPT !.calculationTimeShort = one] : one \in Sample(6) }
        \cup { [ZeroKrxEstimatedIndexMessage EXCEPT !.index = one] : one \in Sample(9) }
        \cup { [ZeroKrxEstimatedIndexMessage EXCEPT !.indexChangeSignAgainstThePreviousDay = one] : one \in Sample(1) }
        \cup { [ZeroKrxEstimatedIndexMessage EXCEPT !.indexChangeAgainstThePreviousDay = one] : one \in Sample(9) }
        \cup { [ZeroKrxEstimatedIndexMessage EXCEPT !.accumulatedTradingVolumeShort = one] : one \in Sample(12) }
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
      calculationTimeShort                 : Sample(6),
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
        \o message.calculationTimeShort
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
    LET calculationTimeShort == ReadBytes(businessDate.rest, 6) IN IF ~calculationTimeShort.ok THEN Fail ELSE
    LET index == ReadBytes(calculationTimeShort.rest, 9) IN IF ~index.ok THEN Fail ELSE
    LET indexChangeSignAgainstThePreviousDay == ReadBytes(index.rest, 1) IN IF ~indexChangeSignAgainstThePreviousDay.ok THEN Fail ELSE
    LET indexChangeAgainstThePreviousDay == ReadBytes(indexChangeSignAgainstThePreviousDay.rest, 9) IN IF ~indexChangeAgainstThePreviousDay.ok THEN Fail ELSE
    LET currencyCode == ReadBytes(indexChangeAgainstThePreviousDay.rest, 3) IN IF ~currencyCode.ok THEN Fail ELSE
    LET filler4 == ReadBytes(currencyCode.rest, 4) IN IF ~filler4.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler4.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ indexId                              |-> indexId.value,
         isinCode                             |-> isinCode.value,
         businessDate                         |-> businessDate.value,
         calculationTimeShort                 |-> calculationTimeShort.value,
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
      calculationTimeShort                 |-> [i \in 1 .. 6 |-> 0],
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
        \cup { [ZeroGlobalIndexMessage EXCEPT !.calculationTimeShort = one] : one \in Sample(6) }
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
      transmissionTimeShort                          : Sample(8),
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
        \o message.transmissionTimeShort
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
    LET transmissionTimeShort == ReadBytes(averageYld.rest, 8) IN IF ~transmissionTimeShort.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(transmissionTimeShort.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
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
         transmissionTimeShort                          |-> transmissionTimeShort.value,
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
      transmissionTimeShort                          |-> [i \in 1 .. 8 |-> 0],
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
        \cup { [ZeroBondPrimeIndexMessage EXCEPT !.transmissionTimeShort = one] : one \in Sample(8) }
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
(* Market Operation Ts Message: 63 bytes                                   *)
(***************************************************************************)

MarketOperationTsMessage ==
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

EncodeMarketOperationTsMessage(message) ==
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

DecodeMarketOperationTsMessage(bytes) ==
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

ZeroMarketOperationTsMessage ==
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

(* Market Operation Ts Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketOperationTsMessage ==
    { ZeroMarketOperationTsMessage }
        \cup { [ZeroMarketOperationTsMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroMarketOperationTsMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroMarketOperationTsMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroMarketOperationTsMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroMarketOperationTsMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroMarketOperationTsMessage EXCEPT !.processingTimeOfTradingSystem = one] : one \in Sample(12) }
        \cup { [ZeroMarketOperationTsMessage EXCEPT !.boardEventId = one] : one \in Sample(3) }
        \cup { [ZeroMarketOperationTsMessage EXCEPT !.startTimeOfABoardEvent = one] : one \in Sample(9) }
        \cup { [ZeroMarketOperationTsMessage EXCEPT !.boardEventGroupCode = one] : one \in Sample(5) }
        \cup { [ZeroMarketOperationTsMessage EXCEPT !.tradingHaltReasonCode = one] : one \in Sample(3) }
        \cup { [ZeroMarketOperationTsMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Market Operation Schedule Message: 78 bytes                             *)
(***************************************************************************)

MarketOperationScheduleMessage ==
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

EncodeMarketOperationScheduleMessage(message) ==
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

DecodeMarketOperationScheduleMessage(bytes) ==
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

ZeroMarketOperationScheduleMessage ==
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

(* Market Operation Schedule Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketOperationScheduleMessage ==
    { ZeroMarketOperationScheduleMessage }
        \cup { [ZeroMarketOperationScheduleMessage EXCEPT !.marketOperationProductId = one] : one \in Sample(3) }
        \cup { [ZeroMarketOperationScheduleMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroMarketOperationScheduleMessage EXCEPT !.boardEventId = one] : one \in Sample(3) }
        \cup { [ZeroMarketOperationScheduleMessage EXCEPT !.startTimeOfABoardEvent = one] : one \in Sample(9) }
        \cup { [ZeroMarketOperationScheduleMessage EXCEPT !.boardEventGroupCode = one] : one \in Sample(5) }
        \cup { [ZeroMarketOperationScheduleMessage EXCEPT !.sessionStartEndCode = one] : one \in Sample(2) }
        \cup { [ZeroMarketOperationScheduleMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroMarketOperationScheduleMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroMarketOperationScheduleMessage EXCEPT !.isinCodeOfACommonStock = one] : one \in Sample(12) }
        \cup { [ZeroMarketOperationScheduleMessage EXCEPT !.productId = one] : one \in Sample(11) }
        \cup { [ZeroMarketOperationScheduleMessage EXCEPT !.tradingHaltReasonCode = one] : one \in Sample(3) }
        \cup { [ZeroMarketOperationScheduleMessage EXCEPT !.tradingHaltTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroMarketOperationScheduleMessage EXCEPT !.stepApplied = one] : one \in Sample(2) }
        \cup { [ZeroMarketOperationScheduleMessage EXCEPT !.priceLimitRangeExpansionForBaseIssueTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroMarketOperationScheduleMessage EXCEPT !.expectedTimeOfExpandingPriceLimitRange = one] : one \in Sample(9) }
        \cup { [ZeroMarketOperationScheduleMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Issue Closing Message: 52 bytes                                         *)
(***************************************************************************)

IssueClosingMessage ==
    [ messageSequenceNumber : Sample(8),
      boardId               : Sample(2),
      isinCode              : Sample(12),
      durationOfTermRepo    : Sample(4),
      closingPrice          : Sample(11),
      closingPriceYield     : Sample(13),
      closingPriceTypeCode  : Sample(1),
      endKeyword            : Sample(1) ]

EncodeIssueClosingMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.isinCode
        \o message.durationOfTermRepo
        \o message.closingPrice
        \o message.closingPriceYield
        \o message.closingPriceTypeCode
        \o message.endKeyword

DecodeIssueClosingMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(boardId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET durationOfTermRepo == ReadBytes(isinCode.rest, 4) IN IF ~durationOfTermRepo.ok THEN Fail ELSE
    LET closingPrice == ReadBytes(durationOfTermRepo.rest, 11) IN IF ~closingPrice.ok THEN Fail ELSE
    LET closingPriceYield == ReadBytes(closingPrice.rest, 13) IN IF ~closingPriceYield.ok THEN Fail ELSE
    LET closingPriceTypeCode == ReadBytes(closingPriceYield.rest, 1) IN IF ~closingPriceTypeCode.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(closingPriceTypeCode.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber |-> messageSequenceNumber.value,
         boardId               |-> boardId.value,
         isinCode              |-> isinCode.value,
         durationOfTermRepo    |-> durationOfTermRepo.value,
         closingPrice          |-> closingPrice.value,
         closingPriceYield     |-> closingPriceYield.value,
         closingPriceTypeCode  |-> closingPriceTypeCode.value,
         endKeyword            |-> endKeyword.value ], endKeyword.rest)

ZeroIssueClosingMessage ==
    [ messageSequenceNumber |-> [i \in 1 .. 8 |-> 0],
      boardId               |-> [i \in 1 .. 2 |-> 0],
      isinCode              |-> [i \in 1 .. 12 |-> 0],
      durationOfTermRepo    |-> [i \in 1 .. 4 |-> 0],
      closingPrice          |-> [i \in 1 .. 11 |-> 0],
      closingPriceYield     |-> [i \in 1 .. 13 |-> 0],
      closingPriceTypeCode  |-> [i \in 1 .. 1 |-> 0],
      endKeyword            |-> [i \in 1 .. 1 |-> 0] ]

(* Issue Closing Message at zero, then each field in turn at the values it is checked at *)
CheckedIssueClosingMessage ==
    { ZeroIssueClosingMessage }
        \cup { [ZeroIssueClosingMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroIssueClosingMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroIssueClosingMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroIssueClosingMessage EXCEPT !.durationOfTermRepo = one] : one \in Sample(4) }
        \cup { [ZeroIssueClosingMessage EXCEPT !.closingPrice = one] : one \in Sample(11) }
        \cup { [ZeroIssueClosingMessage EXCEPT !.closingPriceYield = one] : one \in Sample(13) }
        \cup { [ZeroIssueClosingMessage EXCEPT !.closingPriceTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroIssueClosingMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Member Firm Sanctions Message: 41 bytes                                 *)
(***************************************************************************)

MemberFirmSanctionsMessage ==
    [ isinCode                         : Sample(12),
      aDesignatedNumberForAnIssue      : Sample(6),
      disclosingDataTypeCode           : Sample(3),
      disclosureTime                   : Sample(9),
      memberNumber                     : Sample(5),
      memberFirmTrustPrincipalTypeCode : Sample(5),
      endKeyword                       : Sample(1) ]

EncodeMemberFirmSanctionsMessage(message) ==
    message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.disclosingDataTypeCode
        \o message.disclosureTime
        \o message.memberNumber
        \o message.memberFirmTrustPrincipalTypeCode
        \o message.endKeyword

DecodeMemberFirmSanctionsMessage(bytes) ==
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

ZeroMemberFirmSanctionsMessage ==
    [ isinCode                         |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue      |-> [i \in 1 .. 6 |-> 0],
      disclosingDataTypeCode           |-> [i \in 1 .. 3 |-> 0],
      disclosureTime                   |-> [i \in 1 .. 9 |-> 0],
      memberNumber                     |-> [i \in 1 .. 5 |-> 0],
      memberFirmTrustPrincipalTypeCode |-> [i \in 1 .. 5 |-> 0],
      endKeyword                       |-> [i \in 1 .. 1 |-> 0] ]

(* Member Firm Sanctions Message at zero, then each field in turn at the values it is checked at *)
CheckedMemberFirmSanctionsMessage ==
    { ZeroMemberFirmSanctionsMessage }
        \cup { [ZeroMemberFirmSanctionsMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroMemberFirmSanctionsMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroMemberFirmSanctionsMessage EXCEPT !.disclosingDataTypeCode = one] : one \in Sample(3) }
        \cup { [ZeroMemberFirmSanctionsMessage EXCEPT !.disclosureTime = one] : one \in Sample(9) }
        \cup { [ZeroMemberFirmSanctionsMessage EXCEPT !.memberNumber = one] : one \in Sample(5) }
        \cup { [ZeroMemberFirmSanctionsMessage EXCEPT !.memberFirmTrustPrincipalTypeCode = one] : one \in Sample(5) }
        \cup { [ZeroMemberFirmSanctionsMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Regular Bonds Ktb Quote Message: 457 bytes                              *)
(***************************************************************************)

RegularBondsKtbQuoteMessage ==
    [ messageSequenceNumber         : Sample(8),
      boardId                       : Sample(2),
      sessionId                     : Sample(2),
      isinCode                      : Sample(12),
      processingTimeOfTradingSystem : Sample(12),
      askLevel1Price                : Sample(11),
      bidLevel1Price                : Sample(11),
      askLevel1RemainingQuantity    : Sample(15),
      bidLevel1RemainingQuantity    : Sample(15),
      askLevel1Yield                : Sample(13),
      bidLevel1Yield                : Sample(13),
      askLevel2Price                : Sample(11),
      bidLevel2Price                : Sample(11),
      askLevel2RemainingQuantity    : Sample(15),
      bidLevel2RemainingQuantity    : Sample(15),
      askLevel2Yield                : Sample(13),
      bidLevel2Yield                : Sample(13),
      askLevel3Price                : Sample(11),
      bidLevel3Price                : Sample(11),
      askLevel3RemainingQuantity    : Sample(15),
      bidLevel3RemainingQuantity    : Sample(15),
      askLevel3Yield                : Sample(13),
      bidLevel3Yield                : Sample(13),
      askLevel4Price                : Sample(11),
      bidLevel4Price                : Sample(11),
      askLevel4RemainingQuantity    : Sample(15),
      bidLevel4RemainingQuantity    : Sample(15),
      askLevel4Yield                : Sample(13),
      bidLevel4Yield                : Sample(13),
      askLevel5Price                : Sample(11),
      bidLevel5Price                : Sample(11),
      askLevel5RemainingQuantity    : Sample(15),
      bidLevel5RemainingQuantity    : Sample(15),
      askLevel5Yield                : Sample(13),
      bidLevel5Yield                : Sample(13),
      askTotalRemainingQuantity     : Sample(15),
      bidTotalRemainingQuantity     : Sample(15),
      endKeyword                    : Sample(1) ]

EncodeRegularBondsKtbQuoteMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.sessionId
        \o message.isinCode
        \o message.processingTimeOfTradingSystem
        \o message.askLevel1Price
        \o message.bidLevel1Price
        \o message.askLevel1RemainingQuantity
        \o message.bidLevel1RemainingQuantity
        \o message.askLevel1Yield
        \o message.bidLevel1Yield
        \o message.askLevel2Price
        \o message.bidLevel2Price
        \o message.askLevel2RemainingQuantity
        \o message.bidLevel2RemainingQuantity
        \o message.askLevel2Yield
        \o message.bidLevel2Yield
        \o message.askLevel3Price
        \o message.bidLevel3Price
        \o message.askLevel3RemainingQuantity
        \o message.bidLevel3RemainingQuantity
        \o message.askLevel3Yield
        \o message.bidLevel3Yield
        \o message.askLevel4Price
        \o message.bidLevel4Price
        \o message.askLevel4RemainingQuantity
        \o message.bidLevel4RemainingQuantity
        \o message.askLevel4Yield
        \o message.bidLevel4Yield
        \o message.askLevel5Price
        \o message.bidLevel5Price
        \o message.askLevel5RemainingQuantity
        \o message.bidLevel5RemainingQuantity
        \o message.askLevel5Yield
        \o message.bidLevel5Yield
        \o message.askTotalRemainingQuantity
        \o message.bidTotalRemainingQuantity
        \o message.endKeyword

DecodeRegularBondsKtbQuoteMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(boardId.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(sessionId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET processingTimeOfTradingSystem == ReadBytes(isinCode.rest, 12) IN IF ~processingTimeOfTradingSystem.ok THEN Fail ELSE
    LET askLevel1Price == ReadBytes(processingTimeOfTradingSystem.rest, 11) IN IF ~askLevel1Price.ok THEN Fail ELSE
    LET bidLevel1Price == ReadBytes(askLevel1Price.rest, 11) IN IF ~bidLevel1Price.ok THEN Fail ELSE
    LET askLevel1RemainingQuantity == ReadBytes(bidLevel1Price.rest, 15) IN IF ~askLevel1RemainingQuantity.ok THEN Fail ELSE
    LET bidLevel1RemainingQuantity == ReadBytes(askLevel1RemainingQuantity.rest, 15) IN IF ~bidLevel1RemainingQuantity.ok THEN Fail ELSE
    LET askLevel1Yield == ReadBytes(bidLevel1RemainingQuantity.rest, 13) IN IF ~askLevel1Yield.ok THEN Fail ELSE
    LET bidLevel1Yield == ReadBytes(askLevel1Yield.rest, 13) IN IF ~bidLevel1Yield.ok THEN Fail ELSE
    LET askLevel2Price == ReadBytes(bidLevel1Yield.rest, 11) IN IF ~askLevel2Price.ok THEN Fail ELSE
    LET bidLevel2Price == ReadBytes(askLevel2Price.rest, 11) IN IF ~bidLevel2Price.ok THEN Fail ELSE
    LET askLevel2RemainingQuantity == ReadBytes(bidLevel2Price.rest, 15) IN IF ~askLevel2RemainingQuantity.ok THEN Fail ELSE
    LET bidLevel2RemainingQuantity == ReadBytes(askLevel2RemainingQuantity.rest, 15) IN IF ~bidLevel2RemainingQuantity.ok THEN Fail ELSE
    LET askLevel2Yield == ReadBytes(bidLevel2RemainingQuantity.rest, 13) IN IF ~askLevel2Yield.ok THEN Fail ELSE
    LET bidLevel2Yield == ReadBytes(askLevel2Yield.rest, 13) IN IF ~bidLevel2Yield.ok THEN Fail ELSE
    LET askLevel3Price == ReadBytes(bidLevel2Yield.rest, 11) IN IF ~askLevel3Price.ok THEN Fail ELSE
    LET bidLevel3Price == ReadBytes(askLevel3Price.rest, 11) IN IF ~bidLevel3Price.ok THEN Fail ELSE
    LET askLevel3RemainingQuantity == ReadBytes(bidLevel3Price.rest, 15) IN IF ~askLevel3RemainingQuantity.ok THEN Fail ELSE
    LET bidLevel3RemainingQuantity == ReadBytes(askLevel3RemainingQuantity.rest, 15) IN IF ~bidLevel3RemainingQuantity.ok THEN Fail ELSE
    LET askLevel3Yield == ReadBytes(bidLevel3RemainingQuantity.rest, 13) IN IF ~askLevel3Yield.ok THEN Fail ELSE
    LET bidLevel3Yield == ReadBytes(askLevel3Yield.rest, 13) IN IF ~bidLevel3Yield.ok THEN Fail ELSE
    LET askLevel4Price == ReadBytes(bidLevel3Yield.rest, 11) IN IF ~askLevel4Price.ok THEN Fail ELSE
    LET bidLevel4Price == ReadBytes(askLevel4Price.rest, 11) IN IF ~bidLevel4Price.ok THEN Fail ELSE
    LET askLevel4RemainingQuantity == ReadBytes(bidLevel4Price.rest, 15) IN IF ~askLevel4RemainingQuantity.ok THEN Fail ELSE
    LET bidLevel4RemainingQuantity == ReadBytes(askLevel4RemainingQuantity.rest, 15) IN IF ~bidLevel4RemainingQuantity.ok THEN Fail ELSE
    LET askLevel4Yield == ReadBytes(bidLevel4RemainingQuantity.rest, 13) IN IF ~askLevel4Yield.ok THEN Fail ELSE
    LET bidLevel4Yield == ReadBytes(askLevel4Yield.rest, 13) IN IF ~bidLevel4Yield.ok THEN Fail ELSE
    LET askLevel5Price == ReadBytes(bidLevel4Yield.rest, 11) IN IF ~askLevel5Price.ok THEN Fail ELSE
    LET bidLevel5Price == ReadBytes(askLevel5Price.rest, 11) IN IF ~bidLevel5Price.ok THEN Fail ELSE
    LET askLevel5RemainingQuantity == ReadBytes(bidLevel5Price.rest, 15) IN IF ~askLevel5RemainingQuantity.ok THEN Fail ELSE
    LET bidLevel5RemainingQuantity == ReadBytes(askLevel5RemainingQuantity.rest, 15) IN IF ~bidLevel5RemainingQuantity.ok THEN Fail ELSE
    LET askLevel5Yield == ReadBytes(bidLevel5RemainingQuantity.rest, 13) IN IF ~askLevel5Yield.ok THEN Fail ELSE
    LET bidLevel5Yield == ReadBytes(askLevel5Yield.rest, 13) IN IF ~bidLevel5Yield.ok THEN Fail ELSE
    LET askTotalRemainingQuantity == ReadBytes(bidLevel5Yield.rest, 15) IN IF ~askTotalRemainingQuantity.ok THEN Fail ELSE
    LET bidTotalRemainingQuantity == ReadBytes(askTotalRemainingQuantity.rest, 15) IN IF ~bidTotalRemainingQuantity.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(bidTotalRemainingQuantity.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber         |-> messageSequenceNumber.value,
         boardId                       |-> boardId.value,
         sessionId                     |-> sessionId.value,
         isinCode                      |-> isinCode.value,
         processingTimeOfTradingSystem |-> processingTimeOfTradingSystem.value,
         askLevel1Price                |-> askLevel1Price.value,
         bidLevel1Price                |-> bidLevel1Price.value,
         askLevel1RemainingQuantity    |-> askLevel1RemainingQuantity.value,
         bidLevel1RemainingQuantity    |-> bidLevel1RemainingQuantity.value,
         askLevel1Yield                |-> askLevel1Yield.value,
         bidLevel1Yield                |-> bidLevel1Yield.value,
         askLevel2Price                |-> askLevel2Price.value,
         bidLevel2Price                |-> bidLevel2Price.value,
         askLevel2RemainingQuantity    |-> askLevel2RemainingQuantity.value,
         bidLevel2RemainingQuantity    |-> bidLevel2RemainingQuantity.value,
         askLevel2Yield                |-> askLevel2Yield.value,
         bidLevel2Yield                |-> bidLevel2Yield.value,
         askLevel3Price                |-> askLevel3Price.value,
         bidLevel3Price                |-> bidLevel3Price.value,
         askLevel3RemainingQuantity    |-> askLevel3RemainingQuantity.value,
         bidLevel3RemainingQuantity    |-> bidLevel3RemainingQuantity.value,
         askLevel3Yield                |-> askLevel3Yield.value,
         bidLevel3Yield                |-> bidLevel3Yield.value,
         askLevel4Price                |-> askLevel4Price.value,
         bidLevel4Price                |-> bidLevel4Price.value,
         askLevel4RemainingQuantity    |-> askLevel4RemainingQuantity.value,
         bidLevel4RemainingQuantity    |-> bidLevel4RemainingQuantity.value,
         askLevel4Yield                |-> askLevel4Yield.value,
         bidLevel4Yield                |-> bidLevel4Yield.value,
         askLevel5Price                |-> askLevel5Price.value,
         bidLevel5Price                |-> bidLevel5Price.value,
         askLevel5RemainingQuantity    |-> askLevel5RemainingQuantity.value,
         bidLevel5RemainingQuantity    |-> bidLevel5RemainingQuantity.value,
         askLevel5Yield                |-> askLevel5Yield.value,
         bidLevel5Yield                |-> bidLevel5Yield.value,
         askTotalRemainingQuantity     |-> askTotalRemainingQuantity.value,
         bidTotalRemainingQuantity     |-> bidTotalRemainingQuantity.value,
         endKeyword                    |-> endKeyword.value ], endKeyword.rest)

ZeroRegularBondsKtbQuoteMessage ==
    [ messageSequenceNumber         |-> [i \in 1 .. 8 |-> 0],
      boardId                       |-> [i \in 1 .. 2 |-> 0],
      sessionId                     |-> [i \in 1 .. 2 |-> 0],
      isinCode                      |-> [i \in 1 .. 12 |-> 0],
      processingTimeOfTradingSystem |-> [i \in 1 .. 12 |-> 0],
      askLevel1Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel1Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel1RemainingQuantity    |-> [i \in 1 .. 15 |-> 0],
      bidLevel1RemainingQuantity    |-> [i \in 1 .. 15 |-> 0],
      askLevel1Yield                |-> [i \in 1 .. 13 |-> 0],
      bidLevel1Yield                |-> [i \in 1 .. 13 |-> 0],
      askLevel2Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel2Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel2RemainingQuantity    |-> [i \in 1 .. 15 |-> 0],
      bidLevel2RemainingQuantity    |-> [i \in 1 .. 15 |-> 0],
      askLevel2Yield                |-> [i \in 1 .. 13 |-> 0],
      bidLevel2Yield                |-> [i \in 1 .. 13 |-> 0],
      askLevel3Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel3Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel3RemainingQuantity    |-> [i \in 1 .. 15 |-> 0],
      bidLevel3RemainingQuantity    |-> [i \in 1 .. 15 |-> 0],
      askLevel3Yield                |-> [i \in 1 .. 13 |-> 0],
      bidLevel3Yield                |-> [i \in 1 .. 13 |-> 0],
      askLevel4Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel4Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel4RemainingQuantity    |-> [i \in 1 .. 15 |-> 0],
      bidLevel4RemainingQuantity    |-> [i \in 1 .. 15 |-> 0],
      askLevel4Yield                |-> [i \in 1 .. 13 |-> 0],
      bidLevel4Yield                |-> [i \in 1 .. 13 |-> 0],
      askLevel5Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel5Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel5RemainingQuantity    |-> [i \in 1 .. 15 |-> 0],
      bidLevel5RemainingQuantity    |-> [i \in 1 .. 15 |-> 0],
      askLevel5Yield                |-> [i \in 1 .. 13 |-> 0],
      bidLevel5Yield                |-> [i \in 1 .. 13 |-> 0],
      askTotalRemainingQuantity     |-> [i \in 1 .. 15 |-> 0],
      bidTotalRemainingQuantity     |-> [i \in 1 .. 15 |-> 0],
      endKeyword                    |-> [i \in 1 .. 1 |-> 0] ]

(* Regular Bonds Ktb Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedRegularBondsKtbQuoteMessage ==
    { ZeroRegularBondsKtbQuoteMessage }
        \cup { [ZeroRegularBondsKtbQuoteMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroRegularBondsKtbQuoteMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroRegularBondsKtbQuoteMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroRegularBondsKtbQuoteMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroRegularBondsKtbQuoteMessage EXCEPT !.processingTimeOfTradingSystem = one] : one \in Sample(12) }
        \cup { [ZeroRegularBondsKtbQuoteMessage EXCEPT !.askLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroRegularBondsKtbQuoteMessage EXCEPT !.bidLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroRegularBondsKtbQuoteMessage EXCEPT !.askLevel1RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRegularBondsKtbQuoteMessage EXCEPT !.bidLevel1RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRegularBondsKtbQuoteMessage EXCEPT !.askLevel1Yield = one] : one \in Sample(13) }
        \cup { [ZeroRegularBondsKtbQuoteMessage EXCEPT !.bidLevel1Yield = one] : one \in Sample(13) }
        \cup { [ZeroRegularBondsKtbQuoteMessage EXCEPT !.askLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroRegularBondsKtbQuoteMessage EXCEPT !.bidLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroRegularBondsKtbQuoteMessage EXCEPT !.askLevel2RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRegularBondsKtbQuoteMessage EXCEPT !.bidLevel2RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRegularBondsKtbQuoteMessage EXCEPT !.askLevel2Yield = one] : one \in Sample(13) }
        \cup { [ZeroRegularBondsKtbQuoteMessage EXCEPT !.bidLevel2Yield = one] : one \in Sample(13) }
        \cup { [ZeroRegularBondsKtbQuoteMessage EXCEPT !.askLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroRegularBondsKtbQuoteMessage EXCEPT !.bidLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroRegularBondsKtbQuoteMessage EXCEPT !.askLevel3RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRegularBondsKtbQuoteMessage EXCEPT !.bidLevel3RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRegularBondsKtbQuoteMessage EXCEPT !.askLevel3Yield = one] : one \in Sample(13) }
        \cup { [ZeroRegularBondsKtbQuoteMessage EXCEPT !.bidLevel3Yield = one] : one \in Sample(13) }
        \cup { [ZeroRegularBondsKtbQuoteMessage EXCEPT !.askLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroRegularBondsKtbQuoteMessage EXCEPT !.bidLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroRegularBondsKtbQuoteMessage EXCEPT !.askLevel4RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRegularBondsKtbQuoteMessage EXCEPT !.bidLevel4RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRegularBondsKtbQuoteMessage EXCEPT !.askLevel4Yield = one] : one \in Sample(13) }
        \cup { [ZeroRegularBondsKtbQuoteMessage EXCEPT !.bidLevel4Yield = one] : one \in Sample(13) }
        \cup { [ZeroRegularBondsKtbQuoteMessage EXCEPT !.askLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroRegularBondsKtbQuoteMessage EXCEPT !.bidLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroRegularBondsKtbQuoteMessage EXCEPT !.askLevel5RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRegularBondsKtbQuoteMessage EXCEPT !.bidLevel5RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRegularBondsKtbQuoteMessage EXCEPT !.askLevel5Yield = one] : one \in Sample(13) }
        \cup { [ZeroRegularBondsKtbQuoteMessage EXCEPT !.bidLevel5Yield = one] : one \in Sample(13) }
        \cup { [ZeroRegularBondsKtbQuoteMessage EXCEPT !.askTotalRemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRegularBondsKtbQuoteMessage EXCEPT !.bidTotalRemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRegularBondsKtbQuoteMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Bonds Order Filled Message: 218 bytes                                   *)
(***************************************************************************)

BondsOrderFilledMessage ==
    [ messageSequenceNumber         : Sample(8),
      boardId                       : Sample(2),
      sessionId                     : Sample(2),
      isinCode                      : Sample(12),
      processingTimeOfTradingSystem : Sample(12),
      tradingPrice                  : Sample(11),
      tradingVolume                 : Sample(10),
      tradingDate                   : Sample(8),
      tradingValue                  : Sample(22),
      bondYield                     : Sample(13),
      openingPrice                  : Sample(11),
      todaysHigh                    : Sample(11),
      todaysLow                     : Sample(11),
      yieldOpeningPrice             : Sample(13),
      yieldTodaysHigh               : Sample(13),
      yieldTodaysLow                : Sample(13),
      accumulatedTradingVolumeLong  : Sample(15),
      accumulatedTradingValueLong   : Sample(22),
      settlementDate                : Sample(8),
      endKeyword                    : Sample(1) ]

EncodeBondsOrderFilledMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.sessionId
        \o message.isinCode
        \o message.processingTimeOfTradingSystem
        \o message.tradingPrice
        \o message.tradingVolume
        \o message.tradingDate
        \o message.tradingValue
        \o message.bondYield
        \o message.openingPrice
        \o message.todaysHigh
        \o message.todaysLow
        \o message.yieldOpeningPrice
        \o message.yieldTodaysHigh
        \o message.yieldTodaysLow
        \o message.accumulatedTradingVolumeLong
        \o message.accumulatedTradingValueLong
        \o message.settlementDate
        \o message.endKeyword

DecodeBondsOrderFilledMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(boardId.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(sessionId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET processingTimeOfTradingSystem == ReadBytes(isinCode.rest, 12) IN IF ~processingTimeOfTradingSystem.ok THEN Fail ELSE
    LET tradingPrice == ReadBytes(processingTimeOfTradingSystem.rest, 11) IN IF ~tradingPrice.ok THEN Fail ELSE
    LET tradingVolume == ReadBytes(tradingPrice.rest, 10) IN IF ~tradingVolume.ok THEN Fail ELSE
    LET tradingDate == ReadBytes(tradingVolume.rest, 8) IN IF ~tradingDate.ok THEN Fail ELSE
    LET tradingValue == ReadBytes(tradingDate.rest, 22) IN IF ~tradingValue.ok THEN Fail ELSE
    LET bondYield == ReadBytes(tradingValue.rest, 13) IN IF ~bondYield.ok THEN Fail ELSE
    LET openingPrice == ReadBytes(bondYield.rest, 11) IN IF ~openingPrice.ok THEN Fail ELSE
    LET todaysHigh == ReadBytes(openingPrice.rest, 11) IN IF ~todaysHigh.ok THEN Fail ELSE
    LET todaysLow == ReadBytes(todaysHigh.rest, 11) IN IF ~todaysLow.ok THEN Fail ELSE
    LET yieldOpeningPrice == ReadBytes(todaysLow.rest, 13) IN IF ~yieldOpeningPrice.ok THEN Fail ELSE
    LET yieldTodaysHigh == ReadBytes(yieldOpeningPrice.rest, 13) IN IF ~yieldTodaysHigh.ok THEN Fail ELSE
    LET yieldTodaysLow == ReadBytes(yieldTodaysHigh.rest, 13) IN IF ~yieldTodaysLow.ok THEN Fail ELSE
    LET accumulatedTradingVolumeLong == ReadBytes(yieldTodaysLow.rest, 15) IN IF ~accumulatedTradingVolumeLong.ok THEN Fail ELSE
    LET accumulatedTradingValueLong == ReadBytes(accumulatedTradingVolumeLong.rest, 22) IN IF ~accumulatedTradingValueLong.ok THEN Fail ELSE
    LET settlementDate == ReadBytes(accumulatedTradingValueLong.rest, 8) IN IF ~settlementDate.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(settlementDate.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber         |-> messageSequenceNumber.value,
         boardId                       |-> boardId.value,
         sessionId                     |-> sessionId.value,
         isinCode                      |-> isinCode.value,
         processingTimeOfTradingSystem |-> processingTimeOfTradingSystem.value,
         tradingPrice                  |-> tradingPrice.value,
         tradingVolume                 |-> tradingVolume.value,
         tradingDate                   |-> tradingDate.value,
         tradingValue                  |-> tradingValue.value,
         bondYield                     |-> bondYield.value,
         openingPrice                  |-> openingPrice.value,
         todaysHigh                    |-> todaysHigh.value,
         todaysLow                     |-> todaysLow.value,
         yieldOpeningPrice             |-> yieldOpeningPrice.value,
         yieldTodaysHigh               |-> yieldTodaysHigh.value,
         yieldTodaysLow                |-> yieldTodaysLow.value,
         accumulatedTradingVolumeLong  |-> accumulatedTradingVolumeLong.value,
         accumulatedTradingValueLong   |-> accumulatedTradingValueLong.value,
         settlementDate                |-> settlementDate.value,
         endKeyword                    |-> endKeyword.value ], endKeyword.rest)

ZeroBondsOrderFilledMessage ==
    [ messageSequenceNumber         |-> [i \in 1 .. 8 |-> 0],
      boardId                       |-> [i \in 1 .. 2 |-> 0],
      sessionId                     |-> [i \in 1 .. 2 |-> 0],
      isinCode                      |-> [i \in 1 .. 12 |-> 0],
      processingTimeOfTradingSystem |-> [i \in 1 .. 12 |-> 0],
      tradingPrice                  |-> [i \in 1 .. 11 |-> 0],
      tradingVolume                 |-> [i \in 1 .. 10 |-> 0],
      tradingDate                   |-> [i \in 1 .. 8 |-> 0],
      tradingValue                  |-> [i \in 1 .. 22 |-> 0],
      bondYield                     |-> [i \in 1 .. 13 |-> 0],
      openingPrice                  |-> [i \in 1 .. 11 |-> 0],
      todaysHigh                    |-> [i \in 1 .. 11 |-> 0],
      todaysLow                     |-> [i \in 1 .. 11 |-> 0],
      yieldOpeningPrice             |-> [i \in 1 .. 13 |-> 0],
      yieldTodaysHigh               |-> [i \in 1 .. 13 |-> 0],
      yieldTodaysLow                |-> [i \in 1 .. 13 |-> 0],
      accumulatedTradingVolumeLong  |-> [i \in 1 .. 15 |-> 0],
      accumulatedTradingValueLong   |-> [i \in 1 .. 22 |-> 0],
      settlementDate                |-> [i \in 1 .. 8 |-> 0],
      endKeyword                    |-> [i \in 1 .. 1 |-> 0] ]

(* Bonds Order Filled Message at zero, then each field in turn at the values it is checked at *)
CheckedBondsOrderFilledMessage ==
    { ZeroBondsOrderFilledMessage }
        \cup { [ZeroBondsOrderFilledMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroBondsOrderFilledMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroBondsOrderFilledMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroBondsOrderFilledMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroBondsOrderFilledMessage EXCEPT !.processingTimeOfTradingSystem = one] : one \in Sample(12) }
        \cup { [ZeroBondsOrderFilledMessage EXCEPT !.tradingPrice = one] : one \in Sample(11) }
        \cup { [ZeroBondsOrderFilledMessage EXCEPT !.tradingVolume = one] : one \in Sample(10) }
        \cup { [ZeroBondsOrderFilledMessage EXCEPT !.tradingDate = one] : one \in Sample(8) }
        \cup { [ZeroBondsOrderFilledMessage EXCEPT !.tradingValue = one] : one \in Sample(22) }
        \cup { [ZeroBondsOrderFilledMessage EXCEPT !.bondYield = one] : one \in Sample(13) }
        \cup { [ZeroBondsOrderFilledMessage EXCEPT !.openingPrice = one] : one \in Sample(11) }
        \cup { [ZeroBondsOrderFilledMessage EXCEPT !.todaysHigh = one] : one \in Sample(11) }
        \cup { [ZeroBondsOrderFilledMessage EXCEPT !.todaysLow = one] : one \in Sample(11) }
        \cup { [ZeroBondsOrderFilledMessage EXCEPT !.yieldOpeningPrice = one] : one \in Sample(13) }
        \cup { [ZeroBondsOrderFilledMessage EXCEPT !.yieldTodaysHigh = one] : one \in Sample(13) }
        \cup { [ZeroBondsOrderFilledMessage EXCEPT !.yieldTodaysLow = one] : one \in Sample(13) }
        \cup { [ZeroBondsOrderFilledMessage EXCEPT !.accumulatedTradingVolumeLong = one] : one \in Sample(15) }
        \cup { [ZeroBondsOrderFilledMessage EXCEPT !.accumulatedTradingValueLong = one] : one \in Sample(22) }
        \cup { [ZeroBondsOrderFilledMessage EXCEPT !.settlementDate = one] : one \in Sample(8) }
        \cup { [ZeroBondsOrderFilledMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* General Bonds Ktb Order Filled Plus Quote Message: 638 bytes            *)
(***************************************************************************)

GeneralBondsKtbOrderFilledPlusQuoteMessage ==
    [ messageSequenceNumber         : Sample(8),
      boardId                       : Sample(2),
      sessionId                     : Sample(2),
      isinCode                      : Sample(12),
      processingTimeOfTradingSystem : Sample(12),
      tradingPrice                  : Sample(11),
      tradingVolume                 : Sample(10),
      tradingDate                   : Sample(8),
      tradingValue                  : Sample(22),
      bondYield                     : Sample(13),
      openingPrice                  : Sample(11),
      todaysHigh                    : Sample(11),
      todaysLow                     : Sample(11),
      yieldOpeningPrice             : Sample(13),
      yieldTodaysHigh               : Sample(13),
      yieldTodaysLow                : Sample(13),
      accumulatedTradingVolumeLong  : Sample(15),
      accumulatedTradingValueLong   : Sample(22),
      settlementDate                : Sample(8),
      askLevel1Price                : Sample(11),
      bidLevel1Price                : Sample(11),
      askLevel1RemainingQuantity    : Sample(15),
      bidLevel1RemainingQuantity    : Sample(15),
      askLevel1Yield                : Sample(13),
      bidLevel1Yield                : Sample(13),
      askLevel2Price                : Sample(11),
      bidLevel2Price                : Sample(11),
      askLevel2RemainingQuantity    : Sample(15),
      bidLevel2RemainingQuantity    : Sample(15),
      askLevel2Yield                : Sample(13),
      bidLevel2Yield                : Sample(13),
      askLevel3Price                : Sample(11),
      bidLevel3Price                : Sample(11),
      askLevel3RemainingQuantity    : Sample(15),
      bidLevel3RemainingQuantity    : Sample(15),
      askLevel3Yield                : Sample(13),
      bidLevel3Yield                : Sample(13),
      askLevel4Price                : Sample(11),
      bidLevel4Price                : Sample(11),
      askLevel4RemainingQuantity    : Sample(15),
      bidLevel4RemainingQuantity    : Sample(15),
      askLevel4Yield                : Sample(13),
      bidLevel4Yield                : Sample(13),
      askLevel5Price                : Sample(11),
      bidLevel5Price                : Sample(11),
      askLevel5RemainingQuantity    : Sample(15),
      bidLevel5RemainingQuantity    : Sample(15),
      askLevel5Yield                : Sample(13),
      bidLevel5Yield                : Sample(13),
      askTotalRemainingQuantity     : Sample(15),
      bidTotalRemainingQuantity     : Sample(15),
      endKeyword                    : Sample(1) ]

EncodeGeneralBondsKtbOrderFilledPlusQuoteMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.sessionId
        \o message.isinCode
        \o message.processingTimeOfTradingSystem
        \o message.tradingPrice
        \o message.tradingVolume
        \o message.tradingDate
        \o message.tradingValue
        \o message.bondYield
        \o message.openingPrice
        \o message.todaysHigh
        \o message.todaysLow
        \o message.yieldOpeningPrice
        \o message.yieldTodaysHigh
        \o message.yieldTodaysLow
        \o message.accumulatedTradingVolumeLong
        \o message.accumulatedTradingValueLong
        \o message.settlementDate
        \o message.askLevel1Price
        \o message.bidLevel1Price
        \o message.askLevel1RemainingQuantity
        \o message.bidLevel1RemainingQuantity
        \o message.askLevel1Yield
        \o message.bidLevel1Yield
        \o message.askLevel2Price
        \o message.bidLevel2Price
        \o message.askLevel2RemainingQuantity
        \o message.bidLevel2RemainingQuantity
        \o message.askLevel2Yield
        \o message.bidLevel2Yield
        \o message.askLevel3Price
        \o message.bidLevel3Price
        \o message.askLevel3RemainingQuantity
        \o message.bidLevel3RemainingQuantity
        \o message.askLevel3Yield
        \o message.bidLevel3Yield
        \o message.askLevel4Price
        \o message.bidLevel4Price
        \o message.askLevel4RemainingQuantity
        \o message.bidLevel4RemainingQuantity
        \o message.askLevel4Yield
        \o message.bidLevel4Yield
        \o message.askLevel5Price
        \o message.bidLevel5Price
        \o message.askLevel5RemainingQuantity
        \o message.bidLevel5RemainingQuantity
        \o message.askLevel5Yield
        \o message.bidLevel5Yield
        \o message.askTotalRemainingQuantity
        \o message.bidTotalRemainingQuantity
        \o message.endKeyword

DecodeGeneralBondsKtbOrderFilledPlusQuoteMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(boardId.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(sessionId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET processingTimeOfTradingSystem == ReadBytes(isinCode.rest, 12) IN IF ~processingTimeOfTradingSystem.ok THEN Fail ELSE
    LET tradingPrice == ReadBytes(processingTimeOfTradingSystem.rest, 11) IN IF ~tradingPrice.ok THEN Fail ELSE
    LET tradingVolume == ReadBytes(tradingPrice.rest, 10) IN IF ~tradingVolume.ok THEN Fail ELSE
    LET tradingDate == ReadBytes(tradingVolume.rest, 8) IN IF ~tradingDate.ok THEN Fail ELSE
    LET tradingValue == ReadBytes(tradingDate.rest, 22) IN IF ~tradingValue.ok THEN Fail ELSE
    LET bondYield == ReadBytes(tradingValue.rest, 13) IN IF ~bondYield.ok THEN Fail ELSE
    LET openingPrice == ReadBytes(bondYield.rest, 11) IN IF ~openingPrice.ok THEN Fail ELSE
    LET todaysHigh == ReadBytes(openingPrice.rest, 11) IN IF ~todaysHigh.ok THEN Fail ELSE
    LET todaysLow == ReadBytes(todaysHigh.rest, 11) IN IF ~todaysLow.ok THEN Fail ELSE
    LET yieldOpeningPrice == ReadBytes(todaysLow.rest, 13) IN IF ~yieldOpeningPrice.ok THEN Fail ELSE
    LET yieldTodaysHigh == ReadBytes(yieldOpeningPrice.rest, 13) IN IF ~yieldTodaysHigh.ok THEN Fail ELSE
    LET yieldTodaysLow == ReadBytes(yieldTodaysHigh.rest, 13) IN IF ~yieldTodaysLow.ok THEN Fail ELSE
    LET accumulatedTradingVolumeLong == ReadBytes(yieldTodaysLow.rest, 15) IN IF ~accumulatedTradingVolumeLong.ok THEN Fail ELSE
    LET accumulatedTradingValueLong == ReadBytes(accumulatedTradingVolumeLong.rest, 22) IN IF ~accumulatedTradingValueLong.ok THEN Fail ELSE
    LET settlementDate == ReadBytes(accumulatedTradingValueLong.rest, 8) IN IF ~settlementDate.ok THEN Fail ELSE
    LET askLevel1Price == ReadBytes(settlementDate.rest, 11) IN IF ~askLevel1Price.ok THEN Fail ELSE
    LET bidLevel1Price == ReadBytes(askLevel1Price.rest, 11) IN IF ~bidLevel1Price.ok THEN Fail ELSE
    LET askLevel1RemainingQuantity == ReadBytes(bidLevel1Price.rest, 15) IN IF ~askLevel1RemainingQuantity.ok THEN Fail ELSE
    LET bidLevel1RemainingQuantity == ReadBytes(askLevel1RemainingQuantity.rest, 15) IN IF ~bidLevel1RemainingQuantity.ok THEN Fail ELSE
    LET askLevel1Yield == ReadBytes(bidLevel1RemainingQuantity.rest, 13) IN IF ~askLevel1Yield.ok THEN Fail ELSE
    LET bidLevel1Yield == ReadBytes(askLevel1Yield.rest, 13) IN IF ~bidLevel1Yield.ok THEN Fail ELSE
    LET askLevel2Price == ReadBytes(bidLevel1Yield.rest, 11) IN IF ~askLevel2Price.ok THEN Fail ELSE
    LET bidLevel2Price == ReadBytes(askLevel2Price.rest, 11) IN IF ~bidLevel2Price.ok THEN Fail ELSE
    LET askLevel2RemainingQuantity == ReadBytes(bidLevel2Price.rest, 15) IN IF ~askLevel2RemainingQuantity.ok THEN Fail ELSE
    LET bidLevel2RemainingQuantity == ReadBytes(askLevel2RemainingQuantity.rest, 15) IN IF ~bidLevel2RemainingQuantity.ok THEN Fail ELSE
    LET askLevel2Yield == ReadBytes(bidLevel2RemainingQuantity.rest, 13) IN IF ~askLevel2Yield.ok THEN Fail ELSE
    LET bidLevel2Yield == ReadBytes(askLevel2Yield.rest, 13) IN IF ~bidLevel2Yield.ok THEN Fail ELSE
    LET askLevel3Price == ReadBytes(bidLevel2Yield.rest, 11) IN IF ~askLevel3Price.ok THEN Fail ELSE
    LET bidLevel3Price == ReadBytes(askLevel3Price.rest, 11) IN IF ~bidLevel3Price.ok THEN Fail ELSE
    LET askLevel3RemainingQuantity == ReadBytes(bidLevel3Price.rest, 15) IN IF ~askLevel3RemainingQuantity.ok THEN Fail ELSE
    LET bidLevel3RemainingQuantity == ReadBytes(askLevel3RemainingQuantity.rest, 15) IN IF ~bidLevel3RemainingQuantity.ok THEN Fail ELSE
    LET askLevel3Yield == ReadBytes(bidLevel3RemainingQuantity.rest, 13) IN IF ~askLevel3Yield.ok THEN Fail ELSE
    LET bidLevel3Yield == ReadBytes(askLevel3Yield.rest, 13) IN IF ~bidLevel3Yield.ok THEN Fail ELSE
    LET askLevel4Price == ReadBytes(bidLevel3Yield.rest, 11) IN IF ~askLevel4Price.ok THEN Fail ELSE
    LET bidLevel4Price == ReadBytes(askLevel4Price.rest, 11) IN IF ~bidLevel4Price.ok THEN Fail ELSE
    LET askLevel4RemainingQuantity == ReadBytes(bidLevel4Price.rest, 15) IN IF ~askLevel4RemainingQuantity.ok THEN Fail ELSE
    LET bidLevel4RemainingQuantity == ReadBytes(askLevel4RemainingQuantity.rest, 15) IN IF ~bidLevel4RemainingQuantity.ok THEN Fail ELSE
    LET askLevel4Yield == ReadBytes(bidLevel4RemainingQuantity.rest, 13) IN IF ~askLevel4Yield.ok THEN Fail ELSE
    LET bidLevel4Yield == ReadBytes(askLevel4Yield.rest, 13) IN IF ~bidLevel4Yield.ok THEN Fail ELSE
    LET askLevel5Price == ReadBytes(bidLevel4Yield.rest, 11) IN IF ~askLevel5Price.ok THEN Fail ELSE
    LET bidLevel5Price == ReadBytes(askLevel5Price.rest, 11) IN IF ~bidLevel5Price.ok THEN Fail ELSE
    LET askLevel5RemainingQuantity == ReadBytes(bidLevel5Price.rest, 15) IN IF ~askLevel5RemainingQuantity.ok THEN Fail ELSE
    LET bidLevel5RemainingQuantity == ReadBytes(askLevel5RemainingQuantity.rest, 15) IN IF ~bidLevel5RemainingQuantity.ok THEN Fail ELSE
    LET askLevel5Yield == ReadBytes(bidLevel5RemainingQuantity.rest, 13) IN IF ~askLevel5Yield.ok THEN Fail ELSE
    LET bidLevel5Yield == ReadBytes(askLevel5Yield.rest, 13) IN IF ~bidLevel5Yield.ok THEN Fail ELSE
    LET askTotalRemainingQuantity == ReadBytes(bidLevel5Yield.rest, 15) IN IF ~askTotalRemainingQuantity.ok THEN Fail ELSE
    LET bidTotalRemainingQuantity == ReadBytes(askTotalRemainingQuantity.rest, 15) IN IF ~bidTotalRemainingQuantity.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(bidTotalRemainingQuantity.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber         |-> messageSequenceNumber.value,
         boardId                       |-> boardId.value,
         sessionId                     |-> sessionId.value,
         isinCode                      |-> isinCode.value,
         processingTimeOfTradingSystem |-> processingTimeOfTradingSystem.value,
         tradingPrice                  |-> tradingPrice.value,
         tradingVolume                 |-> tradingVolume.value,
         tradingDate                   |-> tradingDate.value,
         tradingValue                  |-> tradingValue.value,
         bondYield                     |-> bondYield.value,
         openingPrice                  |-> openingPrice.value,
         todaysHigh                    |-> todaysHigh.value,
         todaysLow                     |-> todaysLow.value,
         yieldOpeningPrice             |-> yieldOpeningPrice.value,
         yieldTodaysHigh               |-> yieldTodaysHigh.value,
         yieldTodaysLow                |-> yieldTodaysLow.value,
         accumulatedTradingVolumeLong  |-> accumulatedTradingVolumeLong.value,
         accumulatedTradingValueLong   |-> accumulatedTradingValueLong.value,
         settlementDate                |-> settlementDate.value,
         askLevel1Price                |-> askLevel1Price.value,
         bidLevel1Price                |-> bidLevel1Price.value,
         askLevel1RemainingQuantity    |-> askLevel1RemainingQuantity.value,
         bidLevel1RemainingQuantity    |-> bidLevel1RemainingQuantity.value,
         askLevel1Yield                |-> askLevel1Yield.value,
         bidLevel1Yield                |-> bidLevel1Yield.value,
         askLevel2Price                |-> askLevel2Price.value,
         bidLevel2Price                |-> bidLevel2Price.value,
         askLevel2RemainingQuantity    |-> askLevel2RemainingQuantity.value,
         bidLevel2RemainingQuantity    |-> bidLevel2RemainingQuantity.value,
         askLevel2Yield                |-> askLevel2Yield.value,
         bidLevel2Yield                |-> bidLevel2Yield.value,
         askLevel3Price                |-> askLevel3Price.value,
         bidLevel3Price                |-> bidLevel3Price.value,
         askLevel3RemainingQuantity    |-> askLevel3RemainingQuantity.value,
         bidLevel3RemainingQuantity    |-> bidLevel3RemainingQuantity.value,
         askLevel3Yield                |-> askLevel3Yield.value,
         bidLevel3Yield                |-> bidLevel3Yield.value,
         askLevel4Price                |-> askLevel4Price.value,
         bidLevel4Price                |-> bidLevel4Price.value,
         askLevel4RemainingQuantity    |-> askLevel4RemainingQuantity.value,
         bidLevel4RemainingQuantity    |-> bidLevel4RemainingQuantity.value,
         askLevel4Yield                |-> askLevel4Yield.value,
         bidLevel4Yield                |-> bidLevel4Yield.value,
         askLevel5Price                |-> askLevel5Price.value,
         bidLevel5Price                |-> bidLevel5Price.value,
         askLevel5RemainingQuantity    |-> askLevel5RemainingQuantity.value,
         bidLevel5RemainingQuantity    |-> bidLevel5RemainingQuantity.value,
         askLevel5Yield                |-> askLevel5Yield.value,
         bidLevel5Yield                |-> bidLevel5Yield.value,
         askTotalRemainingQuantity     |-> askTotalRemainingQuantity.value,
         bidTotalRemainingQuantity     |-> bidTotalRemainingQuantity.value,
         endKeyword                    |-> endKeyword.value ], endKeyword.rest)

ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage ==
    [ messageSequenceNumber         |-> [i \in 1 .. 8 |-> 0],
      boardId                       |-> [i \in 1 .. 2 |-> 0],
      sessionId                     |-> [i \in 1 .. 2 |-> 0],
      isinCode                      |-> [i \in 1 .. 12 |-> 0],
      processingTimeOfTradingSystem |-> [i \in 1 .. 12 |-> 0],
      tradingPrice                  |-> [i \in 1 .. 11 |-> 0],
      tradingVolume                 |-> [i \in 1 .. 10 |-> 0],
      tradingDate                   |-> [i \in 1 .. 8 |-> 0],
      tradingValue                  |-> [i \in 1 .. 22 |-> 0],
      bondYield                     |-> [i \in 1 .. 13 |-> 0],
      openingPrice                  |-> [i \in 1 .. 11 |-> 0],
      todaysHigh                    |-> [i \in 1 .. 11 |-> 0],
      todaysLow                     |-> [i \in 1 .. 11 |-> 0],
      yieldOpeningPrice             |-> [i \in 1 .. 13 |-> 0],
      yieldTodaysHigh               |-> [i \in 1 .. 13 |-> 0],
      yieldTodaysLow                |-> [i \in 1 .. 13 |-> 0],
      accumulatedTradingVolumeLong  |-> [i \in 1 .. 15 |-> 0],
      accumulatedTradingValueLong   |-> [i \in 1 .. 22 |-> 0],
      settlementDate                |-> [i \in 1 .. 8 |-> 0],
      askLevel1Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel1Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel1RemainingQuantity    |-> [i \in 1 .. 15 |-> 0],
      bidLevel1RemainingQuantity    |-> [i \in 1 .. 15 |-> 0],
      askLevel1Yield                |-> [i \in 1 .. 13 |-> 0],
      bidLevel1Yield                |-> [i \in 1 .. 13 |-> 0],
      askLevel2Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel2Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel2RemainingQuantity    |-> [i \in 1 .. 15 |-> 0],
      bidLevel2RemainingQuantity    |-> [i \in 1 .. 15 |-> 0],
      askLevel2Yield                |-> [i \in 1 .. 13 |-> 0],
      bidLevel2Yield                |-> [i \in 1 .. 13 |-> 0],
      askLevel3Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel3Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel3RemainingQuantity    |-> [i \in 1 .. 15 |-> 0],
      bidLevel3RemainingQuantity    |-> [i \in 1 .. 15 |-> 0],
      askLevel3Yield                |-> [i \in 1 .. 13 |-> 0],
      bidLevel3Yield                |-> [i \in 1 .. 13 |-> 0],
      askLevel4Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel4Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel4RemainingQuantity    |-> [i \in 1 .. 15 |-> 0],
      bidLevel4RemainingQuantity    |-> [i \in 1 .. 15 |-> 0],
      askLevel4Yield                |-> [i \in 1 .. 13 |-> 0],
      bidLevel4Yield                |-> [i \in 1 .. 13 |-> 0],
      askLevel5Price                |-> [i \in 1 .. 11 |-> 0],
      bidLevel5Price                |-> [i \in 1 .. 11 |-> 0],
      askLevel5RemainingQuantity    |-> [i \in 1 .. 15 |-> 0],
      bidLevel5RemainingQuantity    |-> [i \in 1 .. 15 |-> 0],
      askLevel5Yield                |-> [i \in 1 .. 13 |-> 0],
      bidLevel5Yield                |-> [i \in 1 .. 13 |-> 0],
      askTotalRemainingQuantity     |-> [i \in 1 .. 15 |-> 0],
      bidTotalRemainingQuantity     |-> [i \in 1 .. 15 |-> 0],
      endKeyword                    |-> [i \in 1 .. 1 |-> 0] ]

(* General Bonds Ktb Order Filled Plus Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedGeneralBondsKtbOrderFilledPlusQuoteMessage ==
    { ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.processingTimeOfTradingSystem = one] : one \in Sample(12) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.tradingPrice = one] : one \in Sample(11) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.tradingVolume = one] : one \in Sample(10) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.tradingDate = one] : one \in Sample(8) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.tradingValue = one] : one \in Sample(22) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.bondYield = one] : one \in Sample(13) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.openingPrice = one] : one \in Sample(11) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.todaysHigh = one] : one \in Sample(11) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.todaysLow = one] : one \in Sample(11) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.yieldOpeningPrice = one] : one \in Sample(13) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.yieldTodaysHigh = one] : one \in Sample(13) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.yieldTodaysLow = one] : one \in Sample(13) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.accumulatedTradingVolumeLong = one] : one \in Sample(15) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.accumulatedTradingValueLong = one] : one \in Sample(22) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.settlementDate = one] : one \in Sample(8) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.askLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.bidLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.askLevel1RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.bidLevel1RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.askLevel1Yield = one] : one \in Sample(13) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.bidLevel1Yield = one] : one \in Sample(13) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.askLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.bidLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.askLevel2RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.bidLevel2RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.askLevel2Yield = one] : one \in Sample(13) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.bidLevel2Yield = one] : one \in Sample(13) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.askLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.bidLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.askLevel3RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.bidLevel3RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.askLevel3Yield = one] : one \in Sample(13) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.bidLevel3Yield = one] : one \in Sample(13) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.askLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.bidLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.askLevel4RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.bidLevel4RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.askLevel4Yield = one] : one \in Sample(13) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.bidLevel4Yield = one] : one \in Sample(13) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.askLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.bidLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.askLevel5RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.bidLevel5RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.askLevel5Yield = one] : one \in Sample(13) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.bidLevel5Yield = one] : one \in Sample(13) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.askTotalRemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.bidTotalRemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Bonds Negotiated Trade Data Message: 36 bytes                           *)
(***************************************************************************)

BondsNegotiatedTradeDataMessage ==
    [ boardId                      : Sample(2),
      isinCode                     : Sample(12),
      aDesignatedNumberForAnIssue  : Sample(6),
      accumulatedTradingVolumeLong : Sample(15),
      endKeyword                   : Sample(1) ]

EncodeBondsNegotiatedTradeDataMessage(message) ==
    message.boardId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.accumulatedTradingVolumeLong
        \o message.endKeyword

DecodeBondsNegotiatedTradeDataMessage(bytes) ==
    LET boardId == ReadBytes(bytes, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(boardId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET accumulatedTradingVolumeLong == ReadBytes(aDesignatedNumberForAnIssue.rest, 15) IN IF ~accumulatedTradingVolumeLong.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(accumulatedTradingVolumeLong.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ boardId                      |-> boardId.value,
         isinCode                     |-> isinCode.value,
         aDesignatedNumberForAnIssue  |-> aDesignatedNumberForAnIssue.value,
         accumulatedTradingVolumeLong |-> accumulatedTradingVolumeLong.value,
         endKeyword                   |-> endKeyword.value ], endKeyword.rest)

ZeroBondsNegotiatedTradeDataMessage ==
    [ boardId                      |-> [i \in 1 .. 2 |-> 0],
      isinCode                     |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue  |-> [i \in 1 .. 6 |-> 0],
      accumulatedTradingVolumeLong |-> [i \in 1 .. 15 |-> 0],
      endKeyword                   |-> [i \in 1 .. 1 |-> 0] ]

(* Bonds Negotiated Trade Data Message at zero, then each field in turn at the values it is checked at *)
CheckedBondsNegotiatedTradeDataMessage ==
    { ZeroBondsNegotiatedTradeDataMessage }
        \cup { [ZeroBondsNegotiatedTradeDataMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroBondsNegotiatedTradeDataMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroBondsNegotiatedTradeDataMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroBondsNegotiatedTradeDataMessage EXCEPT !.accumulatedTradingVolumeLong = one] : one \in Sample(15) }
        \cup { [ZeroBondsNegotiatedTradeDataMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Repo Negotiated Trade Data Message: 50 bytes                            *)
(***************************************************************************)

RepoNegotiatedTradeDataMessage ==
    [ isinCode                        : Sample(12),
      rfqAccumulatedTradingValue      : Sample(22),
      reportTradingTotalTradingVolume : Sample(15),
      endKeyword                      : Sample(1) ]

EncodeRepoNegotiatedTradeDataMessage(message) ==
    message.isinCode
        \o message.rfqAccumulatedTradingValue
        \o message.reportTradingTotalTradingVolume
        \o message.endKeyword

DecodeRepoNegotiatedTradeDataMessage(bytes) ==
    LET isinCode == ReadBytes(bytes, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET rfqAccumulatedTradingValue == ReadBytes(isinCode.rest, 22) IN IF ~rfqAccumulatedTradingValue.ok THEN Fail ELSE
    LET reportTradingTotalTradingVolume == ReadBytes(rfqAccumulatedTradingValue.rest, 15) IN IF ~reportTradingTotalTradingVolume.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(reportTradingTotalTradingVolume.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ isinCode                        |-> isinCode.value,
         rfqAccumulatedTradingValue      |-> rfqAccumulatedTradingValue.value,
         reportTradingTotalTradingVolume |-> reportTradingTotalTradingVolume.value,
         endKeyword                      |-> endKeyword.value ], endKeyword.rest)

ZeroRepoNegotiatedTradeDataMessage ==
    [ isinCode                        |-> [i \in 1 .. 12 |-> 0],
      rfqAccumulatedTradingValue      |-> [i \in 1 .. 22 |-> 0],
      reportTradingTotalTradingVolume |-> [i \in 1 .. 15 |-> 0],
      endKeyword                      |-> [i \in 1 .. 1 |-> 0] ]

(* Repo Negotiated Trade Data Message at zero, then each field in turn at the values it is checked at *)
CheckedRepoNegotiatedTradeDataMessage ==
    { ZeroRepoNegotiatedTradeDataMessage }
        \cup { [ZeroRepoNegotiatedTradeDataMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroRepoNegotiatedTradeDataMessage EXCEPT !.rfqAccumulatedTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroRepoNegotiatedTradeDataMessage EXCEPT !.reportTradingTotalTradingVolume = one] : one \in Sample(15) }
        \cup { [ZeroRepoNegotiatedTradeDataMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

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
(* Baby Bonds Reporting Market Yield Message: 68 bytes                     *)
(***************************************************************************)

BabyBondsReportingMarketYieldMessage ==
    [ messageSequenceNumber       : Sample(8),
      businessDate                : Sample(8),
      babyBondsTypeCode           : Sample(3),
      reportMarketYieldRate       : Sample(13),
      reportMarketAPriceWithYield : Sample(11),
      closingPriceYieldRate       : Sample(13),
      closingPriceWithYield       : Sample(11),
      endKeyword                  : Sample(1) ]

EncodeBabyBondsReportingMarketYieldMessage(message) ==
    message.messageSequenceNumber
        \o message.businessDate
        \o message.babyBondsTypeCode
        \o message.reportMarketYieldRate
        \o message.reportMarketAPriceWithYield
        \o message.closingPriceYieldRate
        \o message.closingPriceWithYield
        \o message.endKeyword

DecodeBabyBondsReportingMarketYieldMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET businessDate == ReadBytes(messageSequenceNumber.rest, 8) IN IF ~businessDate.ok THEN Fail ELSE
    LET babyBondsTypeCode == ReadBytes(businessDate.rest, 3) IN IF ~babyBondsTypeCode.ok THEN Fail ELSE
    LET reportMarketYieldRate == ReadBytes(babyBondsTypeCode.rest, 13) IN IF ~reportMarketYieldRate.ok THEN Fail ELSE
    LET reportMarketAPriceWithYield == ReadBytes(reportMarketYieldRate.rest, 11) IN IF ~reportMarketAPriceWithYield.ok THEN Fail ELSE
    LET closingPriceYieldRate == ReadBytes(reportMarketAPriceWithYield.rest, 13) IN IF ~closingPriceYieldRate.ok THEN Fail ELSE
    LET closingPriceWithYield == ReadBytes(closingPriceYieldRate.rest, 11) IN IF ~closingPriceWithYield.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(closingPriceWithYield.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber       |-> messageSequenceNumber.value,
         businessDate                |-> businessDate.value,
         babyBondsTypeCode           |-> babyBondsTypeCode.value,
         reportMarketYieldRate       |-> reportMarketYieldRate.value,
         reportMarketAPriceWithYield |-> reportMarketAPriceWithYield.value,
         closingPriceYieldRate       |-> closingPriceYieldRate.value,
         closingPriceWithYield       |-> closingPriceWithYield.value,
         endKeyword                  |-> endKeyword.value ], endKeyword.rest)

ZeroBabyBondsReportingMarketYieldMessage ==
    [ messageSequenceNumber       |-> [i \in 1 .. 8 |-> 0],
      businessDate                |-> [i \in 1 .. 8 |-> 0],
      babyBondsTypeCode           |-> [i \in 1 .. 3 |-> 0],
      reportMarketYieldRate       |-> [i \in 1 .. 13 |-> 0],
      reportMarketAPriceWithYield |-> [i \in 1 .. 11 |-> 0],
      closingPriceYieldRate       |-> [i \in 1 .. 13 |-> 0],
      closingPriceWithYield       |-> [i \in 1 .. 11 |-> 0],
      endKeyword                  |-> [i \in 1 .. 1 |-> 0] ]

(* Baby Bonds Reporting Market Yield Message at zero, then each field in turn at the values it is checked at *)
CheckedBabyBondsReportingMarketYieldMessage ==
    { ZeroBabyBondsReportingMarketYieldMessage }
        \cup { [ZeroBabyBondsReportingMarketYieldMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroBabyBondsReportingMarketYieldMessage EXCEPT !.businessDate = one] : one \in Sample(8) }
        \cup { [ZeroBabyBondsReportingMarketYieldMessage EXCEPT !.babyBondsTypeCode = one] : one \in Sample(3) }
        \cup { [ZeroBabyBondsReportingMarketYieldMessage EXCEPT !.reportMarketYieldRate = one] : one \in Sample(13) }
        \cup { [ZeroBabyBondsReportingMarketYieldMessage EXCEPT !.reportMarketAPriceWithYield = one] : one \in Sample(11) }
        \cup { [ZeroBabyBondsReportingMarketYieldMessage EXCEPT !.closingPriceYieldRate = one] : one \in Sample(13) }
        \cup { [ZeroBabyBondsReportingMarketYieldMessage EXCEPT !.closingPriceWithYield = one] : one \in Sample(11) }
        \cup { [ZeroBabyBondsReportingMarketYieldMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Ktb Confirmed Info For Wit Message: 67 bytes                            *)
(***************************************************************************)

KtbConfirmedInfoForWitMessage ==
    [ isinCode                     : Sample(12),
      tradingDate                  : Sample(8),
      bidClosingDate               : Sample(8),
      accumulatedTradingVolumeLong : Sample(15),
      accumulatedTradingValueLong  : Sample(22),
      cancellation                 : Sample(1),
      endKeyword                   : Sample(1) ]

EncodeKtbConfirmedInfoForWitMessage(message) ==
    message.isinCode
        \o message.tradingDate
        \o message.bidClosingDate
        \o message.accumulatedTradingVolumeLong
        \o message.accumulatedTradingValueLong
        \o message.cancellation
        \o message.endKeyword

DecodeKtbConfirmedInfoForWitMessage(bytes) ==
    LET isinCode == ReadBytes(bytes, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET tradingDate == ReadBytes(isinCode.rest, 8) IN IF ~tradingDate.ok THEN Fail ELSE
    LET bidClosingDate == ReadBytes(tradingDate.rest, 8) IN IF ~bidClosingDate.ok THEN Fail ELSE
    LET accumulatedTradingVolumeLong == ReadBytes(bidClosingDate.rest, 15) IN IF ~accumulatedTradingVolumeLong.ok THEN Fail ELSE
    LET accumulatedTradingValueLong == ReadBytes(accumulatedTradingVolumeLong.rest, 22) IN IF ~accumulatedTradingValueLong.ok THEN Fail ELSE
    LET cancellation == ReadBytes(accumulatedTradingValueLong.rest, 1) IN IF ~cancellation.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(cancellation.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ isinCode                     |-> isinCode.value,
         tradingDate                  |-> tradingDate.value,
         bidClosingDate               |-> bidClosingDate.value,
         accumulatedTradingVolumeLong |-> accumulatedTradingVolumeLong.value,
         accumulatedTradingValueLong  |-> accumulatedTradingValueLong.value,
         cancellation                 |-> cancellation.value,
         endKeyword                   |-> endKeyword.value ], endKeyword.rest)

ZeroKtbConfirmedInfoForWitMessage ==
    [ isinCode                     |-> [i \in 1 .. 12 |-> 0],
      tradingDate                  |-> [i \in 1 .. 8 |-> 0],
      bidClosingDate               |-> [i \in 1 .. 8 |-> 0],
      accumulatedTradingVolumeLong |-> [i \in 1 .. 15 |-> 0],
      accumulatedTradingValueLong  |-> [i \in 1 .. 22 |-> 0],
      cancellation                 |-> [i \in 1 .. 1 |-> 0],
      endKeyword                   |-> [i \in 1 .. 1 |-> 0] ]

(* Ktb Confirmed Info For Wit Message at zero, then each field in turn at the values it is checked at *)
CheckedKtbConfirmedInfoForWitMessage ==
    { ZeroKtbConfirmedInfoForWitMessage }
        \cup { [ZeroKtbConfirmedInfoForWitMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroKtbConfirmedInfoForWitMessage EXCEPT !.tradingDate = one] : one \in Sample(8) }
        \cup { [ZeroKtbConfirmedInfoForWitMessage EXCEPT !.bidClosingDate = one] : one \in Sample(8) }
        \cup { [ZeroKtbConfirmedInfoForWitMessage EXCEPT !.accumulatedTradingVolumeLong = one] : one \in Sample(15) }
        \cup { [ZeroKtbConfirmedInfoForWitMessage EXCEPT !.accumulatedTradingValueLong = one] : one \in Sample(22) }
        \cup { [ZeroKtbConfirmedInfoForWitMessage EXCEPT !.cancellation = one] : one \in Sample(1) }
        \cup { [ZeroKtbConfirmedInfoForWitMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Ktb Short Term Yield Message: 32 bytes                                  *)
(***************************************************************************)

KtbShortTermYieldMessage ==
    [ transmissionDate               : Sample(8),
      calculationTimeLong            : Sample(9),
      shortTermInterestRatesTypeCode : Sample(1),
      shortTermYield                 : Sample(13),
      endKeyword                     : Sample(1) ]

EncodeKtbShortTermYieldMessage(message) ==
    message.transmissionDate
        \o message.calculationTimeLong
        \o message.shortTermInterestRatesTypeCode
        \o message.shortTermYield
        \o message.endKeyword

DecodeKtbShortTermYieldMessage(bytes) ==
    LET transmissionDate == ReadBytes(bytes, 8) IN IF ~transmissionDate.ok THEN Fail ELSE
    LET calculationTimeLong == ReadBytes(transmissionDate.rest, 9) IN IF ~calculationTimeLong.ok THEN Fail ELSE
    LET shortTermInterestRatesTypeCode == ReadBytes(calculationTimeLong.rest, 1) IN IF ~shortTermInterestRatesTypeCode.ok THEN Fail ELSE
    LET shortTermYield == ReadBytes(shortTermInterestRatesTypeCode.rest, 13) IN IF ~shortTermYield.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(shortTermYield.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ transmissionDate               |-> transmissionDate.value,
         calculationTimeLong            |-> calculationTimeLong.value,
         shortTermInterestRatesTypeCode |-> shortTermInterestRatesTypeCode.value,
         shortTermYield                 |-> shortTermYield.value,
         endKeyword                     |-> endKeyword.value ], endKeyword.rest)

ZeroKtbShortTermYieldMessage ==
    [ transmissionDate               |-> [i \in 1 .. 8 |-> 0],
      calculationTimeLong            |-> [i \in 1 .. 9 |-> 0],
      shortTermInterestRatesTypeCode |-> [i \in 1 .. 1 |-> 0],
      shortTermYield                 |-> [i \in 1 .. 13 |-> 0],
      endKeyword                     |-> [i \in 1 .. 1 |-> 0] ]

(* Ktb Short Term Yield Message at zero, then each field in turn at the values it is checked at *)
CheckedKtbShortTermYieldMessage ==
    { ZeroKtbShortTermYieldMessage }
        \cup { [ZeroKtbShortTermYieldMessage EXCEPT !.transmissionDate = one] : one \in Sample(8) }
        \cup { [ZeroKtbShortTermYieldMessage EXCEPT !.calculationTimeLong = one] : one \in Sample(9) }
        \cup { [ZeroKtbShortTermYieldMessage EXCEPT !.shortTermInterestRatesTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroKtbShortTermYieldMessage EXCEPT !.shortTermYield = one] : one \in Sample(13) }
        \cup { [ZeroKtbShortTermYieldMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Ktb Average Yield Message: 32 bytes                                     *)
(***************************************************************************)

KtbAverageYieldMessage ==
    [ transmissionDate               : Sample(8),
      calculationTimeLong            : Sample(9),
      shortTermInterestRatesTypeCode : Sample(1),
      averageYield                   : Sample(13),
      endKeyword                     : Sample(1) ]

EncodeKtbAverageYieldMessage(message) ==
    message.transmissionDate
        \o message.calculationTimeLong
        \o message.shortTermInterestRatesTypeCode
        \o message.averageYield
        \o message.endKeyword

DecodeKtbAverageYieldMessage(bytes) ==
    LET transmissionDate == ReadBytes(bytes, 8) IN IF ~transmissionDate.ok THEN Fail ELSE
    LET calculationTimeLong == ReadBytes(transmissionDate.rest, 9) IN IF ~calculationTimeLong.ok THEN Fail ELSE
    LET shortTermInterestRatesTypeCode == ReadBytes(calculationTimeLong.rest, 1) IN IF ~shortTermInterestRatesTypeCode.ok THEN Fail ELSE
    LET averageYield == ReadBytes(shortTermInterestRatesTypeCode.rest, 13) IN IF ~averageYield.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(averageYield.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ transmissionDate               |-> transmissionDate.value,
         calculationTimeLong            |-> calculationTimeLong.value,
         shortTermInterestRatesTypeCode |-> shortTermInterestRatesTypeCode.value,
         averageYield                   |-> averageYield.value,
         endKeyword                     |-> endKeyword.value ], endKeyword.rest)

ZeroKtbAverageYieldMessage ==
    [ transmissionDate               |-> [i \in 1 .. 8 |-> 0],
      calculationTimeLong            |-> [i \in 1 .. 9 |-> 0],
      shortTermInterestRatesTypeCode |-> [i \in 1 .. 1 |-> 0],
      averageYield                   |-> [i \in 1 .. 13 |-> 0],
      endKeyword                     |-> [i \in 1 .. 1 |-> 0] ]

(* Ktb Average Yield Message at zero, then each field in turn at the values it is checked at *)
CheckedKtbAverageYieldMessage ==
    { ZeroKtbAverageYieldMessage }
        \cup { [ZeroKtbAverageYieldMessage EXCEPT !.transmissionDate = one] : one \in Sample(8) }
        \cup { [ZeroKtbAverageYieldMessage EXCEPT !.calculationTimeLong = one] : one \in Sample(9) }
        \cup { [ZeroKtbAverageYieldMessage EXCEPT !.shortTermInterestRatesTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroKtbAverageYieldMessage EXCEPT !.averageYield = one] : one \in Sample(13) }
        \cup { [ZeroKtbAverageYieldMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Bonds Credit Rating Information Message: 65 bytes                       *)
(***************************************************************************)

BondsCreditRatingInformationMessage ==
    [ messageSequenceNumber        : Sample(8),
      isinCode                     : Sample(12),
      transmissionDate             : Sample(8),
      creditRatingAgencyCodeNo1    : Sample(4),
      creditRatingPerAgencyCodeNo1 : Sample(4),
      sfRatings1                   : Sample(1),
      creditRatingAgencyCodeNo2    : Sample(4),
      creditRatingPerAgencyCodeNo2 : Sample(4),
      sfRatings2                   : Sample(1),
      creditRatingAgencyCodeNo3    : Sample(4),
      creditRatingPerAgencyCodeNo3 : Sample(4),
      sfRatings3                   : Sample(1),
      creditRatingAgencyCodeNo4    : Sample(4),
      creditRatingPerAgencyCodeNo4 : Sample(4),
      sfRatings4                   : Sample(1),
      endKeyword                   : Sample(1) ]

EncodeBondsCreditRatingInformationMessage(message) ==
    message.messageSequenceNumber
        \o message.isinCode
        \o message.transmissionDate
        \o message.creditRatingAgencyCodeNo1
        \o message.creditRatingPerAgencyCodeNo1
        \o message.sfRatings1
        \o message.creditRatingAgencyCodeNo2
        \o message.creditRatingPerAgencyCodeNo2
        \o message.sfRatings2
        \o message.creditRatingAgencyCodeNo3
        \o message.creditRatingPerAgencyCodeNo3
        \o message.sfRatings3
        \o message.creditRatingAgencyCodeNo4
        \o message.creditRatingPerAgencyCodeNo4
        \o message.sfRatings4
        \o message.endKeyword

DecodeBondsCreditRatingInformationMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET isinCode == ReadBytes(messageSequenceNumber.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET transmissionDate == ReadBytes(isinCode.rest, 8) IN IF ~transmissionDate.ok THEN Fail ELSE
    LET creditRatingAgencyCodeNo1 == ReadBytes(transmissionDate.rest, 4) IN IF ~creditRatingAgencyCodeNo1.ok THEN Fail ELSE
    LET creditRatingPerAgencyCodeNo1 == ReadBytes(creditRatingAgencyCodeNo1.rest, 4) IN IF ~creditRatingPerAgencyCodeNo1.ok THEN Fail ELSE
    LET sfRatings1 == ReadBytes(creditRatingPerAgencyCodeNo1.rest, 1) IN IF ~sfRatings1.ok THEN Fail ELSE
    LET creditRatingAgencyCodeNo2 == ReadBytes(sfRatings1.rest, 4) IN IF ~creditRatingAgencyCodeNo2.ok THEN Fail ELSE
    LET creditRatingPerAgencyCodeNo2 == ReadBytes(creditRatingAgencyCodeNo2.rest, 4) IN IF ~creditRatingPerAgencyCodeNo2.ok THEN Fail ELSE
    LET sfRatings2 == ReadBytes(creditRatingPerAgencyCodeNo2.rest, 1) IN IF ~sfRatings2.ok THEN Fail ELSE
    LET creditRatingAgencyCodeNo3 == ReadBytes(sfRatings2.rest, 4) IN IF ~creditRatingAgencyCodeNo3.ok THEN Fail ELSE
    LET creditRatingPerAgencyCodeNo3 == ReadBytes(creditRatingAgencyCodeNo3.rest, 4) IN IF ~creditRatingPerAgencyCodeNo3.ok THEN Fail ELSE
    LET sfRatings3 == ReadBytes(creditRatingPerAgencyCodeNo3.rest, 1) IN IF ~sfRatings3.ok THEN Fail ELSE
    LET creditRatingAgencyCodeNo4 == ReadBytes(sfRatings3.rest, 4) IN IF ~creditRatingAgencyCodeNo4.ok THEN Fail ELSE
    LET creditRatingPerAgencyCodeNo4 == ReadBytes(creditRatingAgencyCodeNo4.rest, 4) IN IF ~creditRatingPerAgencyCodeNo4.ok THEN Fail ELSE
    LET sfRatings4 == ReadBytes(creditRatingPerAgencyCodeNo4.rest, 1) IN IF ~sfRatings4.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(sfRatings4.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber        |-> messageSequenceNumber.value,
         isinCode                     |-> isinCode.value,
         transmissionDate             |-> transmissionDate.value,
         creditRatingAgencyCodeNo1    |-> creditRatingAgencyCodeNo1.value,
         creditRatingPerAgencyCodeNo1 |-> creditRatingPerAgencyCodeNo1.value,
         sfRatings1                   |-> sfRatings1.value,
         creditRatingAgencyCodeNo2    |-> creditRatingAgencyCodeNo2.value,
         creditRatingPerAgencyCodeNo2 |-> creditRatingPerAgencyCodeNo2.value,
         sfRatings2                   |-> sfRatings2.value,
         creditRatingAgencyCodeNo3    |-> creditRatingAgencyCodeNo3.value,
         creditRatingPerAgencyCodeNo3 |-> creditRatingPerAgencyCodeNo3.value,
         sfRatings3                   |-> sfRatings3.value,
         creditRatingAgencyCodeNo4    |-> creditRatingAgencyCodeNo4.value,
         creditRatingPerAgencyCodeNo4 |-> creditRatingPerAgencyCodeNo4.value,
         sfRatings4                   |-> sfRatings4.value,
         endKeyword                   |-> endKeyword.value ], endKeyword.rest)

ZeroBondsCreditRatingInformationMessage ==
    [ messageSequenceNumber        |-> [i \in 1 .. 8 |-> 0],
      isinCode                     |-> [i \in 1 .. 12 |-> 0],
      transmissionDate             |-> [i \in 1 .. 8 |-> 0],
      creditRatingAgencyCodeNo1    |-> [i \in 1 .. 4 |-> 0],
      creditRatingPerAgencyCodeNo1 |-> [i \in 1 .. 4 |-> 0],
      sfRatings1                   |-> [i \in 1 .. 1 |-> 0],
      creditRatingAgencyCodeNo2    |-> [i \in 1 .. 4 |-> 0],
      creditRatingPerAgencyCodeNo2 |-> [i \in 1 .. 4 |-> 0],
      sfRatings2                   |-> [i \in 1 .. 1 |-> 0],
      creditRatingAgencyCodeNo3    |-> [i \in 1 .. 4 |-> 0],
      creditRatingPerAgencyCodeNo3 |-> [i \in 1 .. 4 |-> 0],
      sfRatings3                   |-> [i \in 1 .. 1 |-> 0],
      creditRatingAgencyCodeNo4    |-> [i \in 1 .. 4 |-> 0],
      creditRatingPerAgencyCodeNo4 |-> [i \in 1 .. 4 |-> 0],
      sfRatings4                   |-> [i \in 1 .. 1 |-> 0],
      endKeyword                   |-> [i \in 1 .. 1 |-> 0] ]

(* Bonds Credit Rating Information Message at zero, then each field in turn at the values it is checked at *)
CheckedBondsCreditRatingInformationMessage ==
    { ZeroBondsCreditRatingInformationMessage }
        \cup { [ZeroBondsCreditRatingInformationMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroBondsCreditRatingInformationMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroBondsCreditRatingInformationMessage EXCEPT !.transmissionDate = one] : one \in Sample(8) }
        \cup { [ZeroBondsCreditRatingInformationMessage EXCEPT !.creditRatingAgencyCodeNo1 = one] : one \in Sample(4) }
        \cup { [ZeroBondsCreditRatingInformationMessage EXCEPT !.creditRatingPerAgencyCodeNo1 = one] : one \in Sample(4) }
        \cup { [ZeroBondsCreditRatingInformationMessage EXCEPT !.sfRatings1 = one] : one \in Sample(1) }
        \cup { [ZeroBondsCreditRatingInformationMessage EXCEPT !.creditRatingAgencyCodeNo2 = one] : one \in Sample(4) }
        \cup { [ZeroBondsCreditRatingInformationMessage EXCEPT !.creditRatingPerAgencyCodeNo2 = one] : one \in Sample(4) }
        \cup { [ZeroBondsCreditRatingInformationMessage EXCEPT !.sfRatings2 = one] : one \in Sample(1) }
        \cup { [ZeroBondsCreditRatingInformationMessage EXCEPT !.creditRatingAgencyCodeNo3 = one] : one \in Sample(4) }
        \cup { [ZeroBondsCreditRatingInformationMessage EXCEPT !.creditRatingPerAgencyCodeNo3 = one] : one \in Sample(4) }
        \cup { [ZeroBondsCreditRatingInformationMessage EXCEPT !.sfRatings3 = one] : one \in Sample(1) }
        \cup { [ZeroBondsCreditRatingInformationMessage EXCEPT !.creditRatingAgencyCodeNo4 = one] : one \in Sample(4) }
        \cup { [ZeroBondsCreditRatingInformationMessage EXCEPT !.creditRatingPerAgencyCodeNo4 = one] : one \in Sample(4) }
        \cup { [ZeroBondsCreditRatingInformationMessage EXCEPT !.sfRatings4 = one] : one \in Sample(1) }
        \cup { [ZeroBondsCreditRatingInformationMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Regular Bonds Disclosure Basic Exchange Rate Message: 27 bytes          *)
(***************************************************************************)

RegularBondsDisclosureBasicExchangeRateMessage ==
    [ disclosingDataTypeCode : Sample(3),
      disclosureTime         : Sample(9),
      appliedExchangeRate    : Sample(13),
      currencyTypeCode       : Sample(1),
      endKeyword             : Sample(1) ]

EncodeRegularBondsDisclosureBasicExchangeRateMessage(message) ==
    message.disclosingDataTypeCode
        \o message.disclosureTime
        \o message.appliedExchangeRate
        \o message.currencyTypeCode
        \o message.endKeyword

DecodeRegularBondsDisclosureBasicExchangeRateMessage(bytes) ==
    LET disclosingDataTypeCode == ReadBytes(bytes, 3) IN IF ~disclosingDataTypeCode.ok THEN Fail ELSE
    LET disclosureTime == ReadBytes(disclosingDataTypeCode.rest, 9) IN IF ~disclosureTime.ok THEN Fail ELSE
    LET appliedExchangeRate == ReadBytes(disclosureTime.rest, 13) IN IF ~appliedExchangeRate.ok THEN Fail ELSE
    LET currencyTypeCode == ReadBytes(appliedExchangeRate.rest, 1) IN IF ~currencyTypeCode.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(currencyTypeCode.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ disclosingDataTypeCode |-> disclosingDataTypeCode.value,
         disclosureTime         |-> disclosureTime.value,
         appliedExchangeRate    |-> appliedExchangeRate.value,
         currencyTypeCode       |-> currencyTypeCode.value,
         endKeyword             |-> endKeyword.value ], endKeyword.rest)

ZeroRegularBondsDisclosureBasicExchangeRateMessage ==
    [ disclosingDataTypeCode |-> [i \in 1 .. 3 |-> 0],
      disclosureTime         |-> [i \in 1 .. 9 |-> 0],
      appliedExchangeRate    |-> [i \in 1 .. 13 |-> 0],
      currencyTypeCode       |-> [i \in 1 .. 1 |-> 0],
      endKeyword             |-> [i \in 1 .. 1 |-> 0] ]

(* Regular Bonds Disclosure Basic Exchange Rate Message at zero, then each field in turn at the values it is checked at *)
CheckedRegularBondsDisclosureBasicExchangeRateMessage ==
    { ZeroRegularBondsDisclosureBasicExchangeRateMessage }
        \cup { [ZeroRegularBondsDisclosureBasicExchangeRateMessage EXCEPT !.disclosingDataTypeCode = one] : one \in Sample(3) }
        \cup { [ZeroRegularBondsDisclosureBasicExchangeRateMessage EXCEPT !.disclosureTime = one] : one \in Sample(9) }
        \cup { [ZeroRegularBondsDisclosureBasicExchangeRateMessage EXCEPT !.appliedExchangeRate = one] : one \in Sample(13) }
        \cup { [ZeroRegularBondsDisclosureBasicExchangeRateMessage EXCEPT !.currencyTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroRegularBondsDisclosureBasicExchangeRateMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Investor Activities Per Bond Types Message: 85 bytes                    *)
(***************************************************************************)

InvestorActivitiesPerBondTypesMessage ==
    [ investorCode                : Sample(4),
      bondCategoryCode            : Sample(6),
      accumulatedAskTradingVolume : Sample(15),
      accumulatedAskTradingValue  : Sample(22),
      accumulatedBidTradingVolume : Sample(15),
      accumulatedBidTradingValue  : Sample(22),
      endKeyword                  : Sample(1) ]

EncodeInvestorActivitiesPerBondTypesMessage(message) ==
    message.investorCode
        \o message.bondCategoryCode
        \o message.accumulatedAskTradingVolume
        \o message.accumulatedAskTradingValue
        \o message.accumulatedBidTradingVolume
        \o message.accumulatedBidTradingValue
        \o message.endKeyword

DecodeInvestorActivitiesPerBondTypesMessage(bytes) ==
    LET investorCode == ReadBytes(bytes, 4) IN IF ~investorCode.ok THEN Fail ELSE
    LET bondCategoryCode == ReadBytes(investorCode.rest, 6) IN IF ~bondCategoryCode.ok THEN Fail ELSE
    LET accumulatedAskTradingVolume == ReadBytes(bondCategoryCode.rest, 15) IN IF ~accumulatedAskTradingVolume.ok THEN Fail ELSE
    LET accumulatedAskTradingValue == ReadBytes(accumulatedAskTradingVolume.rest, 22) IN IF ~accumulatedAskTradingValue.ok THEN Fail ELSE
    LET accumulatedBidTradingVolume == ReadBytes(accumulatedAskTradingValue.rest, 15) IN IF ~accumulatedBidTradingVolume.ok THEN Fail ELSE
    LET accumulatedBidTradingValue == ReadBytes(accumulatedBidTradingVolume.rest, 22) IN IF ~accumulatedBidTradingValue.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(accumulatedBidTradingValue.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ investorCode                |-> investorCode.value,
         bondCategoryCode            |-> bondCategoryCode.value,
         accumulatedAskTradingVolume |-> accumulatedAskTradingVolume.value,
         accumulatedAskTradingValue  |-> accumulatedAskTradingValue.value,
         accumulatedBidTradingVolume |-> accumulatedBidTradingVolume.value,
         accumulatedBidTradingValue  |-> accumulatedBidTradingValue.value,
         endKeyword                  |-> endKeyword.value ], endKeyword.rest)

ZeroInvestorActivitiesPerBondTypesMessage ==
    [ investorCode                |-> [i \in 1 .. 4 |-> 0],
      bondCategoryCode            |-> [i \in 1 .. 6 |-> 0],
      accumulatedAskTradingVolume |-> [i \in 1 .. 15 |-> 0],
      accumulatedAskTradingValue  |-> [i \in 1 .. 22 |-> 0],
      accumulatedBidTradingVolume |-> [i \in 1 .. 15 |-> 0],
      accumulatedBidTradingValue  |-> [i \in 1 .. 22 |-> 0],
      endKeyword                  |-> [i \in 1 .. 1 |-> 0] ]

(* Investor Activities Per Bond Types Message at zero, then each field in turn at the values it is checked at *)
CheckedInvestorActivitiesPerBondTypesMessage ==
    { ZeroInvestorActivitiesPerBondTypesMessage }
        \cup { [ZeroInvestorActivitiesPerBondTypesMessage EXCEPT !.investorCode = one] : one \in Sample(4) }
        \cup { [ZeroInvestorActivitiesPerBondTypesMessage EXCEPT !.bondCategoryCode = one] : one \in Sample(6) }
        \cup { [ZeroInvestorActivitiesPerBondTypesMessage EXCEPT !.accumulatedAskTradingVolume = one] : one \in Sample(15) }
        \cup { [ZeroInvestorActivitiesPerBondTypesMessage EXCEPT !.accumulatedAskTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroInvestorActivitiesPerBondTypesMessage EXCEPT !.accumulatedBidTradingVolume = one] : one \in Sample(15) }
        \cup { [ZeroInvestorActivitiesPerBondTypesMessage EXCEPT !.accumulatedBidTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroInvestorActivitiesPerBondTypesMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Bonds Isin Issue Information Message: 898 bytes                         *)
(***************************************************************************)

BondsIsinIssueInformationMessage ==
    [ messageSequenceNumber                              : Sample(8),
      isinCode                                           : Sample(12),
      transmissionDate                                   : Sample(8),
      transmissionTimeLong                               : Sample(9),
      recordProcessCategory                              : Sample(1),
      abbreviatedIssueName                               : Sample(40),
      abbreviatedIssueNameInEn                           : Sample(40),
      issuerCode                                         : Sample(5),
      bondListingTypeCode                                : Sample(1),
      bondCategoryCode                                   : Sample(6),
      bondTypeCode                                       : Sample(2),
      specialBondIssueCode                               : Sample(3),
      mbTypeCode                                         : Sample(1),
      bondGuaranteedTypeCode                             : Sample(1),
      guaranteedRateForPayment                           : Sample(13),
      otherTypesOfBond                                   : Sample(1),
      optionEmbeddedTypeCode                             : Sample(1),
      couponPaymentTypeCode                              : Sample(2),
      riskBondRedemptionTypeCode                         : Sample(1),
      bondIssuanceTypeCode                               : Sample(3),
      securitizationTypeCode                             : Sample(2),
      redemptionPriorityTypeCode                         : Sample(1),
      listingDate                                        : Sample(8),
      issueDate                                          : Sample(8),
      redemptionDate                                     : Sample(8),
      saleDate                                           : Sample(8),
      the1StCouponPaymentDate                            : Sample(8),
      bondIssuanceRate                                   : Sample(13),
      couponRate                                         : Sample(14),
      monthlyCycleOfCouponPayment                        : Sample(4),
      couponPaymentTimingCode                            : Sample(1),
      interestPayment                                    : Sample(1),
      couponPaymentDateTypeCode                          : Sample(1),
      decimalPointOfCouponTypeCode                       : Sample(1),
      numberOfMonthsToPayInterest                        : Sample(4),
      bondSaleTypeCode                                   : Sample(1),
      preIssueSaleCouponPaymentTypeCode                  : Sample(1),
      issuingAmount                                      : Sample(22),
      listedAmount                                       : Sample(22),
      confirmationOfLumpSumPayment                       : Sample(1),
      currencyTypeCode                                   : Sample(1),
      redemptionRatioAtMaturity                          : Sample(13),
      yieldToMaturity                                    : Sample(13),
      guaranteedYieldEffectiveDate                       : Sample(8),
      additionalYield                                    : Sample(13),
      additionalYieldEffectiveDate                       : Sample(8),
      facilityFund                                       : Sample(22),
      maintenanceFund                                    : Sample(22),
      loanFund                                           : Sample(22),
      otherFunds                                         : Sample(22),
      inscriptionTypeOfBond                              : Sample(1),
      taxation                                           : Sample(1),
      bondLeadManagerCompanyCode                         : Sample(4),
      paymentGuarantorCode                               : Sample(4),
      trusteeCode                                        : Sample(4),
      registerInstituteCode                              : Sample(4),
      paymentAgentCode                                   : Sample(4),
      abbreviatedIssueCode                               : Sample(9),
      bondDelistingReasonCode                            : Sample(2),
      bondDelistedDate                                   : Sample(8),
      equityLinkedBondRightsTypeCode                     : Sample(2),
      isin                                               : Sample(12),
      issueNameShort                                     : Sample(60),
      equityLinkedBondExercisePrice                      : Sample(11),
      exerciseRatio                                      : Sample(7),
      dateToStartExercising                              : Sample(8),
      dateToEndExercising                                : Sample(8),
      institutionCode                                    : Sample(4),
      recordDateOfDividendPayout                         : Sample(1),
      profitParticipatingAccumStatus                     : Sample(1),
      issueCodeOfPostExercise                            : Sample(12),
      amortizationTypeCode                               : Sample(1),
      levelPaymentAmount                                 : Sample(22),
      numberOfMonthsForGrace                             : Sample(4),
      interestTypeCodeDuringAmortization                 : Sample(1),
      numberOfAmortization                               : Sample(5),
      interestRateDecisionOtherBaseRateName              : Sample(20),
      spread                                             : Sample(10),
      timingOfInterestRateDecisionTypeCode               : Sample(1),
      upperLimitCouponRate                               : Sample(14),
      lowerLimitCouponRate                               : Sample(14),
      theDateToDecideInterestRate                        : Sample(8),
      firstCallExerciseStartDate                         : Sample(8),
      firstCallExerciseEndDate                           : Sample(8),
      secondCallExerciseStartDate                        : Sample(8),
      secondCallExerciseEndDate                          : Sample(8),
      firstPutExerciseStartDate                          : Sample(8),
      firstPutExerciseEndDate                            : Sample(8),
      secondPutExerciseStartDate                         : Sample(8),
      secondPutExerciseEndDate                           : Sample(8),
      couponPaymentDecisionCodeForBankHolidays           : Sample(1),
      hybridBond                                         : Sample(1),
      coCosTypeCode                                      : Sample(1),
      couponRateConfirmation                             : Sample(1),
      principalGuranteedRate                             : Sample(13),
      participatingRate                                  : Sample(11),
      maximumYield                                       : Sample(11),
      stripBondTypeCode                                  : Sample(1),
      originalBondTypeCodeSubjecToStrip                  : Sample(12),
      unstrippedBalance                                  : Sample(22),
      inflationIndexedCategory                           : Sample(1),
      referenceIndexForIssueDate                         : Sample(11),
      couponRateDecisionBaseRateTypeCode                 : Sample(2),
      bondOddLotDaysBaseInterestTypeCode                 : Sample(1),
      baseInterestRateOnBankHolidaysTypeCode             : Sample(1),
      accruedInterestRateOnBankHolidaysTypeCode          : Sample(14),
      principalPaymentMethodsOnBankHolidaysTypeCode      : Sample(1),
      principalBaseRateOnBankHolidaysTypeCode            : Sample(1),
      principalAccruedInterestRateOnBankHolidaysTypeCode : Sample(14),
      stopOutRate                                        : Sample(14),
      crowdfunding                                       : Sample(1),
      endKeyword                                         : Sample(1) ]

EncodeBondsIsinIssueInformationMessage(message) ==
    message.messageSequenceNumber
        \o message.isinCode
        \o message.transmissionDate
        \o message.transmissionTimeLong
        \o message.recordProcessCategory
        \o message.abbreviatedIssueName
        \o message.abbreviatedIssueNameInEn
        \o message.issuerCode
        \o message.bondListingTypeCode
        \o message.bondCategoryCode
        \o message.bondTypeCode
        \o message.specialBondIssueCode
        \o message.mbTypeCode
        \o message.bondGuaranteedTypeCode
        \o message.guaranteedRateForPayment
        \o message.otherTypesOfBond
        \o message.optionEmbeddedTypeCode
        \o message.couponPaymentTypeCode
        \o message.riskBondRedemptionTypeCode
        \o message.bondIssuanceTypeCode
        \o message.securitizationTypeCode
        \o message.redemptionPriorityTypeCode
        \o message.listingDate
        \o message.issueDate
        \o message.redemptionDate
        \o message.saleDate
        \o message.the1StCouponPaymentDate
        \o message.bondIssuanceRate
        \o message.couponRate
        \o message.monthlyCycleOfCouponPayment
        \o message.couponPaymentTimingCode
        \o message.interestPayment
        \o message.couponPaymentDateTypeCode
        \o message.decimalPointOfCouponTypeCode
        \o message.numberOfMonthsToPayInterest
        \o message.bondSaleTypeCode
        \o message.preIssueSaleCouponPaymentTypeCode
        \o message.issuingAmount
        \o message.listedAmount
        \o message.confirmationOfLumpSumPayment
        \o message.currencyTypeCode
        \o message.redemptionRatioAtMaturity
        \o message.yieldToMaturity
        \o message.guaranteedYieldEffectiveDate
        \o message.additionalYield
        \o message.additionalYieldEffectiveDate
        \o message.facilityFund
        \o message.maintenanceFund
        \o message.loanFund
        \o message.otherFunds
        \o message.inscriptionTypeOfBond
        \o message.taxation
        \o message.bondLeadManagerCompanyCode
        \o message.paymentGuarantorCode
        \o message.trusteeCode
        \o message.registerInstituteCode
        \o message.paymentAgentCode
        \o message.abbreviatedIssueCode
        \o message.bondDelistingReasonCode
        \o message.bondDelistedDate
        \o message.equityLinkedBondRightsTypeCode
        \o message.isin
        \o message.issueNameShort
        \o message.equityLinkedBondExercisePrice
        \o message.exerciseRatio
        \o message.dateToStartExercising
        \o message.dateToEndExercising
        \o message.institutionCode
        \o message.recordDateOfDividendPayout
        \o message.profitParticipatingAccumStatus
        \o message.issueCodeOfPostExercise
        \o message.amortizationTypeCode
        \o message.levelPaymentAmount
        \o message.numberOfMonthsForGrace
        \o message.interestTypeCodeDuringAmortization
        \o message.numberOfAmortization
        \o message.interestRateDecisionOtherBaseRateName
        \o message.spread
        \o message.timingOfInterestRateDecisionTypeCode
        \o message.upperLimitCouponRate
        \o message.lowerLimitCouponRate
        \o message.theDateToDecideInterestRate
        \o message.firstCallExerciseStartDate
        \o message.firstCallExerciseEndDate
        \o message.secondCallExerciseStartDate
        \o message.secondCallExerciseEndDate
        \o message.firstPutExerciseStartDate
        \o message.firstPutExerciseEndDate
        \o message.secondPutExerciseStartDate
        \o message.secondPutExerciseEndDate
        \o message.couponPaymentDecisionCodeForBankHolidays
        \o message.hybridBond
        \o message.coCosTypeCode
        \o message.couponRateConfirmation
        \o message.principalGuranteedRate
        \o message.participatingRate
        \o message.maximumYield
        \o message.stripBondTypeCode
        \o message.originalBondTypeCodeSubjecToStrip
        \o message.unstrippedBalance
        \o message.inflationIndexedCategory
        \o message.referenceIndexForIssueDate
        \o message.couponRateDecisionBaseRateTypeCode
        \o message.bondOddLotDaysBaseInterestTypeCode
        \o message.baseInterestRateOnBankHolidaysTypeCode
        \o message.accruedInterestRateOnBankHolidaysTypeCode
        \o message.principalPaymentMethodsOnBankHolidaysTypeCode
        \o message.principalBaseRateOnBankHolidaysTypeCode
        \o message.principalAccruedInterestRateOnBankHolidaysTypeCode
        \o message.stopOutRate
        \o message.crowdfunding
        \o message.endKeyword

DecodeBondsIsinIssueInformationMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET isinCode == ReadBytes(messageSequenceNumber.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET transmissionDate == ReadBytes(isinCode.rest, 8) IN IF ~transmissionDate.ok THEN Fail ELSE
    LET transmissionTimeLong == ReadBytes(transmissionDate.rest, 9) IN IF ~transmissionTimeLong.ok THEN Fail ELSE
    LET recordProcessCategory == ReadBytes(transmissionTimeLong.rest, 1) IN IF ~recordProcessCategory.ok THEN Fail ELSE
    LET abbreviatedIssueName == ReadBytes(recordProcessCategory.rest, 40) IN IF ~abbreviatedIssueName.ok THEN Fail ELSE
    LET abbreviatedIssueNameInEn == ReadBytes(abbreviatedIssueName.rest, 40) IN IF ~abbreviatedIssueNameInEn.ok THEN Fail ELSE
    LET issuerCode == ReadBytes(abbreviatedIssueNameInEn.rest, 5) IN IF ~issuerCode.ok THEN Fail ELSE
    LET bondListingTypeCode == ReadBytes(issuerCode.rest, 1) IN IF ~bondListingTypeCode.ok THEN Fail ELSE
    LET bondCategoryCode == ReadBytes(bondListingTypeCode.rest, 6) IN IF ~bondCategoryCode.ok THEN Fail ELSE
    LET bondTypeCode == ReadBytes(bondCategoryCode.rest, 2) IN IF ~bondTypeCode.ok THEN Fail ELSE
    LET specialBondIssueCode == ReadBytes(bondTypeCode.rest, 3) IN IF ~specialBondIssueCode.ok THEN Fail ELSE
    LET mbTypeCode == ReadBytes(specialBondIssueCode.rest, 1) IN IF ~mbTypeCode.ok THEN Fail ELSE
    LET bondGuaranteedTypeCode == ReadBytes(mbTypeCode.rest, 1) IN IF ~bondGuaranteedTypeCode.ok THEN Fail ELSE
    LET guaranteedRateForPayment == ReadBytes(bondGuaranteedTypeCode.rest, 13) IN IF ~guaranteedRateForPayment.ok THEN Fail ELSE
    LET otherTypesOfBond == ReadBytes(guaranteedRateForPayment.rest, 1) IN IF ~otherTypesOfBond.ok THEN Fail ELSE
    LET optionEmbeddedTypeCode == ReadBytes(otherTypesOfBond.rest, 1) IN IF ~optionEmbeddedTypeCode.ok THEN Fail ELSE
    LET couponPaymentTypeCode == ReadBytes(optionEmbeddedTypeCode.rest, 2) IN IF ~couponPaymentTypeCode.ok THEN Fail ELSE
    LET riskBondRedemptionTypeCode == ReadBytes(couponPaymentTypeCode.rest, 1) IN IF ~riskBondRedemptionTypeCode.ok THEN Fail ELSE
    LET bondIssuanceTypeCode == ReadBytes(riskBondRedemptionTypeCode.rest, 3) IN IF ~bondIssuanceTypeCode.ok THEN Fail ELSE
    LET securitizationTypeCode == ReadBytes(bondIssuanceTypeCode.rest, 2) IN IF ~securitizationTypeCode.ok THEN Fail ELSE
    LET redemptionPriorityTypeCode == ReadBytes(securitizationTypeCode.rest, 1) IN IF ~redemptionPriorityTypeCode.ok THEN Fail ELSE
    LET listingDate == ReadBytes(redemptionPriorityTypeCode.rest, 8) IN IF ~listingDate.ok THEN Fail ELSE
    LET issueDate == ReadBytes(listingDate.rest, 8) IN IF ~issueDate.ok THEN Fail ELSE
    LET redemptionDate == ReadBytes(issueDate.rest, 8) IN IF ~redemptionDate.ok THEN Fail ELSE
    LET saleDate == ReadBytes(redemptionDate.rest, 8) IN IF ~saleDate.ok THEN Fail ELSE
    LET the1StCouponPaymentDate == ReadBytes(saleDate.rest, 8) IN IF ~the1StCouponPaymentDate.ok THEN Fail ELSE
    LET bondIssuanceRate == ReadBytes(the1StCouponPaymentDate.rest, 13) IN IF ~bondIssuanceRate.ok THEN Fail ELSE
    LET couponRate == ReadBytes(bondIssuanceRate.rest, 14) IN IF ~couponRate.ok THEN Fail ELSE
    LET monthlyCycleOfCouponPayment == ReadBytes(couponRate.rest, 4) IN IF ~monthlyCycleOfCouponPayment.ok THEN Fail ELSE
    LET couponPaymentTimingCode == ReadBytes(monthlyCycleOfCouponPayment.rest, 1) IN IF ~couponPaymentTimingCode.ok THEN Fail ELSE
    LET interestPayment == ReadBytes(couponPaymentTimingCode.rest, 1) IN IF ~interestPayment.ok THEN Fail ELSE
    LET couponPaymentDateTypeCode == ReadBytes(interestPayment.rest, 1) IN IF ~couponPaymentDateTypeCode.ok THEN Fail ELSE
    LET decimalPointOfCouponTypeCode == ReadBytes(couponPaymentDateTypeCode.rest, 1) IN IF ~decimalPointOfCouponTypeCode.ok THEN Fail ELSE
    LET numberOfMonthsToPayInterest == ReadBytes(decimalPointOfCouponTypeCode.rest, 4) IN IF ~numberOfMonthsToPayInterest.ok THEN Fail ELSE
    LET bondSaleTypeCode == ReadBytes(numberOfMonthsToPayInterest.rest, 1) IN IF ~bondSaleTypeCode.ok THEN Fail ELSE
    LET preIssueSaleCouponPaymentTypeCode == ReadBytes(bondSaleTypeCode.rest, 1) IN IF ~preIssueSaleCouponPaymentTypeCode.ok THEN Fail ELSE
    LET issuingAmount == ReadBytes(preIssueSaleCouponPaymentTypeCode.rest, 22) IN IF ~issuingAmount.ok THEN Fail ELSE
    LET listedAmount == ReadBytes(issuingAmount.rest, 22) IN IF ~listedAmount.ok THEN Fail ELSE
    LET confirmationOfLumpSumPayment == ReadBytes(listedAmount.rest, 1) IN IF ~confirmationOfLumpSumPayment.ok THEN Fail ELSE
    LET currencyTypeCode == ReadBytes(confirmationOfLumpSumPayment.rest, 1) IN IF ~currencyTypeCode.ok THEN Fail ELSE
    LET redemptionRatioAtMaturity == ReadBytes(currencyTypeCode.rest, 13) IN IF ~redemptionRatioAtMaturity.ok THEN Fail ELSE
    LET yieldToMaturity == ReadBytes(redemptionRatioAtMaturity.rest, 13) IN IF ~yieldToMaturity.ok THEN Fail ELSE
    LET guaranteedYieldEffectiveDate == ReadBytes(yieldToMaturity.rest, 8) IN IF ~guaranteedYieldEffectiveDate.ok THEN Fail ELSE
    LET additionalYield == ReadBytes(guaranteedYieldEffectiveDate.rest, 13) IN IF ~additionalYield.ok THEN Fail ELSE
    LET additionalYieldEffectiveDate == ReadBytes(additionalYield.rest, 8) IN IF ~additionalYieldEffectiveDate.ok THEN Fail ELSE
    LET facilityFund == ReadBytes(additionalYieldEffectiveDate.rest, 22) IN IF ~facilityFund.ok THEN Fail ELSE
    LET maintenanceFund == ReadBytes(facilityFund.rest, 22) IN IF ~maintenanceFund.ok THEN Fail ELSE
    LET loanFund == ReadBytes(maintenanceFund.rest, 22) IN IF ~loanFund.ok THEN Fail ELSE
    LET otherFunds == ReadBytes(loanFund.rest, 22) IN IF ~otherFunds.ok THEN Fail ELSE
    LET inscriptionTypeOfBond == ReadBytes(otherFunds.rest, 1) IN IF ~inscriptionTypeOfBond.ok THEN Fail ELSE
    LET taxation == ReadBytes(inscriptionTypeOfBond.rest, 1) IN IF ~taxation.ok THEN Fail ELSE
    LET bondLeadManagerCompanyCode == ReadBytes(taxation.rest, 4) IN IF ~bondLeadManagerCompanyCode.ok THEN Fail ELSE
    LET paymentGuarantorCode == ReadBytes(bondLeadManagerCompanyCode.rest, 4) IN IF ~paymentGuarantorCode.ok THEN Fail ELSE
    LET trusteeCode == ReadBytes(paymentGuarantorCode.rest, 4) IN IF ~trusteeCode.ok THEN Fail ELSE
    LET registerInstituteCode == ReadBytes(trusteeCode.rest, 4) IN IF ~registerInstituteCode.ok THEN Fail ELSE
    LET paymentAgentCode == ReadBytes(registerInstituteCode.rest, 4) IN IF ~paymentAgentCode.ok THEN Fail ELSE
    LET abbreviatedIssueCode == ReadBytes(paymentAgentCode.rest, 9) IN IF ~abbreviatedIssueCode.ok THEN Fail ELSE
    LET bondDelistingReasonCode == ReadBytes(abbreviatedIssueCode.rest, 2) IN IF ~bondDelistingReasonCode.ok THEN Fail ELSE
    LET bondDelistedDate == ReadBytes(bondDelistingReasonCode.rest, 8) IN IF ~bondDelistedDate.ok THEN Fail ELSE
    LET equityLinkedBondRightsTypeCode == ReadBytes(bondDelistedDate.rest, 2) IN IF ~equityLinkedBondRightsTypeCode.ok THEN Fail ELSE
    LET isin == ReadBytes(equityLinkedBondRightsTypeCode.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET issueNameShort == ReadBytes(isin.rest, 60) IN IF ~issueNameShort.ok THEN Fail ELSE
    LET equityLinkedBondExercisePrice == ReadBytes(issueNameShort.rest, 11) IN IF ~equityLinkedBondExercisePrice.ok THEN Fail ELSE
    LET exerciseRatio == ReadBytes(equityLinkedBondExercisePrice.rest, 7) IN IF ~exerciseRatio.ok THEN Fail ELSE
    LET dateToStartExercising == ReadBytes(exerciseRatio.rest, 8) IN IF ~dateToStartExercising.ok THEN Fail ELSE
    LET dateToEndExercising == ReadBytes(dateToStartExercising.rest, 8) IN IF ~dateToEndExercising.ok THEN Fail ELSE
    LET institutionCode == ReadBytes(dateToEndExercising.rest, 4) IN IF ~institutionCode.ok THEN Fail ELSE
    LET recordDateOfDividendPayout == ReadBytes(institutionCode.rest, 1) IN IF ~recordDateOfDividendPayout.ok THEN Fail ELSE
    LET profitParticipatingAccumStatus == ReadBytes(recordDateOfDividendPayout.rest, 1) IN IF ~profitParticipatingAccumStatus.ok THEN Fail ELSE
    LET issueCodeOfPostExercise == ReadBytes(profitParticipatingAccumStatus.rest, 12) IN IF ~issueCodeOfPostExercise.ok THEN Fail ELSE
    LET amortizationTypeCode == ReadBytes(issueCodeOfPostExercise.rest, 1) IN IF ~amortizationTypeCode.ok THEN Fail ELSE
    LET levelPaymentAmount == ReadBytes(amortizationTypeCode.rest, 22) IN IF ~levelPaymentAmount.ok THEN Fail ELSE
    LET numberOfMonthsForGrace == ReadBytes(levelPaymentAmount.rest, 4) IN IF ~numberOfMonthsForGrace.ok THEN Fail ELSE
    LET interestTypeCodeDuringAmortization == ReadBytes(numberOfMonthsForGrace.rest, 1) IN IF ~interestTypeCodeDuringAmortization.ok THEN Fail ELSE
    LET numberOfAmortization == ReadBytes(interestTypeCodeDuringAmortization.rest, 5) IN IF ~numberOfAmortization.ok THEN Fail ELSE
    LET interestRateDecisionOtherBaseRateName == ReadBytes(numberOfAmortization.rest, 20) IN IF ~interestRateDecisionOtherBaseRateName.ok THEN Fail ELSE
    LET spread == ReadBytes(interestRateDecisionOtherBaseRateName.rest, 10) IN IF ~spread.ok THEN Fail ELSE
    LET timingOfInterestRateDecisionTypeCode == ReadBytes(spread.rest, 1) IN IF ~timingOfInterestRateDecisionTypeCode.ok THEN Fail ELSE
    LET upperLimitCouponRate == ReadBytes(timingOfInterestRateDecisionTypeCode.rest, 14) IN IF ~upperLimitCouponRate.ok THEN Fail ELSE
    LET lowerLimitCouponRate == ReadBytes(upperLimitCouponRate.rest, 14) IN IF ~lowerLimitCouponRate.ok THEN Fail ELSE
    LET theDateToDecideInterestRate == ReadBytes(lowerLimitCouponRate.rest, 8) IN IF ~theDateToDecideInterestRate.ok THEN Fail ELSE
    LET firstCallExerciseStartDate == ReadBytes(theDateToDecideInterestRate.rest, 8) IN IF ~firstCallExerciseStartDate.ok THEN Fail ELSE
    LET firstCallExerciseEndDate == ReadBytes(firstCallExerciseStartDate.rest, 8) IN IF ~firstCallExerciseEndDate.ok THEN Fail ELSE
    LET secondCallExerciseStartDate == ReadBytes(firstCallExerciseEndDate.rest, 8) IN IF ~secondCallExerciseStartDate.ok THEN Fail ELSE
    LET secondCallExerciseEndDate == ReadBytes(secondCallExerciseStartDate.rest, 8) IN IF ~secondCallExerciseEndDate.ok THEN Fail ELSE
    LET firstPutExerciseStartDate == ReadBytes(secondCallExerciseEndDate.rest, 8) IN IF ~firstPutExerciseStartDate.ok THEN Fail ELSE
    LET firstPutExerciseEndDate == ReadBytes(firstPutExerciseStartDate.rest, 8) IN IF ~firstPutExerciseEndDate.ok THEN Fail ELSE
    LET secondPutExerciseStartDate == ReadBytes(firstPutExerciseEndDate.rest, 8) IN IF ~secondPutExerciseStartDate.ok THEN Fail ELSE
    LET secondPutExerciseEndDate == ReadBytes(secondPutExerciseStartDate.rest, 8) IN IF ~secondPutExerciseEndDate.ok THEN Fail ELSE
    LET couponPaymentDecisionCodeForBankHolidays == ReadBytes(secondPutExerciseEndDate.rest, 1) IN IF ~couponPaymentDecisionCodeForBankHolidays.ok THEN Fail ELSE
    LET hybridBond == ReadBytes(couponPaymentDecisionCodeForBankHolidays.rest, 1) IN IF ~hybridBond.ok THEN Fail ELSE
    LET coCosTypeCode == ReadBytes(hybridBond.rest, 1) IN IF ~coCosTypeCode.ok THEN Fail ELSE
    LET couponRateConfirmation == ReadBytes(coCosTypeCode.rest, 1) IN IF ~couponRateConfirmation.ok THEN Fail ELSE
    LET principalGuranteedRate == ReadBytes(couponRateConfirmation.rest, 13) IN IF ~principalGuranteedRate.ok THEN Fail ELSE
    LET participatingRate == ReadBytes(principalGuranteedRate.rest, 11) IN IF ~participatingRate.ok THEN Fail ELSE
    LET maximumYield == ReadBytes(participatingRate.rest, 11) IN IF ~maximumYield.ok THEN Fail ELSE
    LET stripBondTypeCode == ReadBytes(maximumYield.rest, 1) IN IF ~stripBondTypeCode.ok THEN Fail ELSE
    LET originalBondTypeCodeSubjecToStrip == ReadBytes(stripBondTypeCode.rest, 12) IN IF ~originalBondTypeCodeSubjecToStrip.ok THEN Fail ELSE
    LET unstrippedBalance == ReadBytes(originalBondTypeCodeSubjecToStrip.rest, 22) IN IF ~unstrippedBalance.ok THEN Fail ELSE
    LET inflationIndexedCategory == ReadBytes(unstrippedBalance.rest, 1) IN IF ~inflationIndexedCategory.ok THEN Fail ELSE
    LET referenceIndexForIssueDate == ReadBytes(inflationIndexedCategory.rest, 11) IN IF ~referenceIndexForIssueDate.ok THEN Fail ELSE
    LET couponRateDecisionBaseRateTypeCode == ReadBytes(referenceIndexForIssueDate.rest, 2) IN IF ~couponRateDecisionBaseRateTypeCode.ok THEN Fail ELSE
    LET bondOddLotDaysBaseInterestTypeCode == ReadBytes(couponRateDecisionBaseRateTypeCode.rest, 1) IN IF ~bondOddLotDaysBaseInterestTypeCode.ok THEN Fail ELSE
    LET baseInterestRateOnBankHolidaysTypeCode == ReadBytes(bondOddLotDaysBaseInterestTypeCode.rest, 1) IN IF ~baseInterestRateOnBankHolidaysTypeCode.ok THEN Fail ELSE
    LET accruedInterestRateOnBankHolidaysTypeCode == ReadBytes(baseInterestRateOnBankHolidaysTypeCode.rest, 14) IN IF ~accruedInterestRateOnBankHolidaysTypeCode.ok THEN Fail ELSE
    LET principalPaymentMethodsOnBankHolidaysTypeCode == ReadBytes(accruedInterestRateOnBankHolidaysTypeCode.rest, 1) IN IF ~principalPaymentMethodsOnBankHolidaysTypeCode.ok THEN Fail ELSE
    LET principalBaseRateOnBankHolidaysTypeCode == ReadBytes(principalPaymentMethodsOnBankHolidaysTypeCode.rest, 1) IN IF ~principalBaseRateOnBankHolidaysTypeCode.ok THEN Fail ELSE
    LET principalAccruedInterestRateOnBankHolidaysTypeCode == ReadBytes(principalBaseRateOnBankHolidaysTypeCode.rest, 14) IN IF ~principalAccruedInterestRateOnBankHolidaysTypeCode.ok THEN Fail ELSE
    LET stopOutRate == ReadBytes(principalAccruedInterestRateOnBankHolidaysTypeCode.rest, 14) IN IF ~stopOutRate.ok THEN Fail ELSE
    LET crowdfunding == ReadBytes(stopOutRate.rest, 1) IN IF ~crowdfunding.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(crowdfunding.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber                              |-> messageSequenceNumber.value,
         isinCode                                           |-> isinCode.value,
         transmissionDate                                   |-> transmissionDate.value,
         transmissionTimeLong                               |-> transmissionTimeLong.value,
         recordProcessCategory                              |-> recordProcessCategory.value,
         abbreviatedIssueName                               |-> abbreviatedIssueName.value,
         abbreviatedIssueNameInEn                           |-> abbreviatedIssueNameInEn.value,
         issuerCode                                         |-> issuerCode.value,
         bondListingTypeCode                                |-> bondListingTypeCode.value,
         bondCategoryCode                                   |-> bondCategoryCode.value,
         bondTypeCode                                       |-> bondTypeCode.value,
         specialBondIssueCode                               |-> specialBondIssueCode.value,
         mbTypeCode                                         |-> mbTypeCode.value,
         bondGuaranteedTypeCode                             |-> bondGuaranteedTypeCode.value,
         guaranteedRateForPayment                           |-> guaranteedRateForPayment.value,
         otherTypesOfBond                                   |-> otherTypesOfBond.value,
         optionEmbeddedTypeCode                             |-> optionEmbeddedTypeCode.value,
         couponPaymentTypeCode                              |-> couponPaymentTypeCode.value,
         riskBondRedemptionTypeCode                         |-> riskBondRedemptionTypeCode.value,
         bondIssuanceTypeCode                               |-> bondIssuanceTypeCode.value,
         securitizationTypeCode                             |-> securitizationTypeCode.value,
         redemptionPriorityTypeCode                         |-> redemptionPriorityTypeCode.value,
         listingDate                                        |-> listingDate.value,
         issueDate                                          |-> issueDate.value,
         redemptionDate                                     |-> redemptionDate.value,
         saleDate                                           |-> saleDate.value,
         the1StCouponPaymentDate                            |-> the1StCouponPaymentDate.value,
         bondIssuanceRate                                   |-> bondIssuanceRate.value,
         couponRate                                         |-> couponRate.value,
         monthlyCycleOfCouponPayment                        |-> monthlyCycleOfCouponPayment.value,
         couponPaymentTimingCode                            |-> couponPaymentTimingCode.value,
         interestPayment                                    |-> interestPayment.value,
         couponPaymentDateTypeCode                          |-> couponPaymentDateTypeCode.value,
         decimalPointOfCouponTypeCode                       |-> decimalPointOfCouponTypeCode.value,
         numberOfMonthsToPayInterest                        |-> numberOfMonthsToPayInterest.value,
         bondSaleTypeCode                                   |-> bondSaleTypeCode.value,
         preIssueSaleCouponPaymentTypeCode                  |-> preIssueSaleCouponPaymentTypeCode.value,
         issuingAmount                                      |-> issuingAmount.value,
         listedAmount                                       |-> listedAmount.value,
         confirmationOfLumpSumPayment                       |-> confirmationOfLumpSumPayment.value,
         currencyTypeCode                                   |-> currencyTypeCode.value,
         redemptionRatioAtMaturity                          |-> redemptionRatioAtMaturity.value,
         yieldToMaturity                                    |-> yieldToMaturity.value,
         guaranteedYieldEffectiveDate                       |-> guaranteedYieldEffectiveDate.value,
         additionalYield                                    |-> additionalYield.value,
         additionalYieldEffectiveDate                       |-> additionalYieldEffectiveDate.value,
         facilityFund                                       |-> facilityFund.value,
         maintenanceFund                                    |-> maintenanceFund.value,
         loanFund                                           |-> loanFund.value,
         otherFunds                                         |-> otherFunds.value,
         inscriptionTypeOfBond                              |-> inscriptionTypeOfBond.value,
         taxation                                           |-> taxation.value,
         bondLeadManagerCompanyCode                         |-> bondLeadManagerCompanyCode.value,
         paymentGuarantorCode                               |-> paymentGuarantorCode.value,
         trusteeCode                                        |-> trusteeCode.value,
         registerInstituteCode                              |-> registerInstituteCode.value,
         paymentAgentCode                                   |-> paymentAgentCode.value,
         abbreviatedIssueCode                               |-> abbreviatedIssueCode.value,
         bondDelistingReasonCode                            |-> bondDelistingReasonCode.value,
         bondDelistedDate                                   |-> bondDelistedDate.value,
         equityLinkedBondRightsTypeCode                     |-> equityLinkedBondRightsTypeCode.value,
         isin                                               |-> isin.value,
         issueNameShort                                     |-> issueNameShort.value,
         equityLinkedBondExercisePrice                      |-> equityLinkedBondExercisePrice.value,
         exerciseRatio                                      |-> exerciseRatio.value,
         dateToStartExercising                              |-> dateToStartExercising.value,
         dateToEndExercising                                |-> dateToEndExercising.value,
         institutionCode                                    |-> institutionCode.value,
         recordDateOfDividendPayout                         |-> recordDateOfDividendPayout.value,
         profitParticipatingAccumStatus                     |-> profitParticipatingAccumStatus.value,
         issueCodeOfPostExercise                            |-> issueCodeOfPostExercise.value,
         amortizationTypeCode                               |-> amortizationTypeCode.value,
         levelPaymentAmount                                 |-> levelPaymentAmount.value,
         numberOfMonthsForGrace                             |-> numberOfMonthsForGrace.value,
         interestTypeCodeDuringAmortization                 |-> interestTypeCodeDuringAmortization.value,
         numberOfAmortization                               |-> numberOfAmortization.value,
         interestRateDecisionOtherBaseRateName              |-> interestRateDecisionOtherBaseRateName.value,
         spread                                             |-> spread.value,
         timingOfInterestRateDecisionTypeCode               |-> timingOfInterestRateDecisionTypeCode.value,
         upperLimitCouponRate                               |-> upperLimitCouponRate.value,
         lowerLimitCouponRate                               |-> lowerLimitCouponRate.value,
         theDateToDecideInterestRate                        |-> theDateToDecideInterestRate.value,
         firstCallExerciseStartDate                         |-> firstCallExerciseStartDate.value,
         firstCallExerciseEndDate                           |-> firstCallExerciseEndDate.value,
         secondCallExerciseStartDate                        |-> secondCallExerciseStartDate.value,
         secondCallExerciseEndDate                          |-> secondCallExerciseEndDate.value,
         firstPutExerciseStartDate                          |-> firstPutExerciseStartDate.value,
         firstPutExerciseEndDate                            |-> firstPutExerciseEndDate.value,
         secondPutExerciseStartDate                         |-> secondPutExerciseStartDate.value,
         secondPutExerciseEndDate                           |-> secondPutExerciseEndDate.value,
         couponPaymentDecisionCodeForBankHolidays           |-> couponPaymentDecisionCodeForBankHolidays.value,
         hybridBond                                         |-> hybridBond.value,
         coCosTypeCode                                      |-> coCosTypeCode.value,
         couponRateConfirmation                             |-> couponRateConfirmation.value,
         principalGuranteedRate                             |-> principalGuranteedRate.value,
         participatingRate                                  |-> participatingRate.value,
         maximumYield                                       |-> maximumYield.value,
         stripBondTypeCode                                  |-> stripBondTypeCode.value,
         originalBondTypeCodeSubjecToStrip                  |-> originalBondTypeCodeSubjecToStrip.value,
         unstrippedBalance                                  |-> unstrippedBalance.value,
         inflationIndexedCategory                           |-> inflationIndexedCategory.value,
         referenceIndexForIssueDate                         |-> referenceIndexForIssueDate.value,
         couponRateDecisionBaseRateTypeCode                 |-> couponRateDecisionBaseRateTypeCode.value,
         bondOddLotDaysBaseInterestTypeCode                 |-> bondOddLotDaysBaseInterestTypeCode.value,
         baseInterestRateOnBankHolidaysTypeCode             |-> baseInterestRateOnBankHolidaysTypeCode.value,
         accruedInterestRateOnBankHolidaysTypeCode          |-> accruedInterestRateOnBankHolidaysTypeCode.value,
         principalPaymentMethodsOnBankHolidaysTypeCode      |-> principalPaymentMethodsOnBankHolidaysTypeCode.value,
         principalBaseRateOnBankHolidaysTypeCode            |-> principalBaseRateOnBankHolidaysTypeCode.value,
         principalAccruedInterestRateOnBankHolidaysTypeCode |-> principalAccruedInterestRateOnBankHolidaysTypeCode.value,
         stopOutRate                                        |-> stopOutRate.value,
         crowdfunding                                       |-> crowdfunding.value,
         endKeyword                                         |-> endKeyword.value ], endKeyword.rest)

ZeroBondsIsinIssueInformationMessage ==
    [ messageSequenceNumber                              |-> [i \in 1 .. 8 |-> 0],
      isinCode                                           |-> [i \in 1 .. 12 |-> 0],
      transmissionDate                                   |-> [i \in 1 .. 8 |-> 0],
      transmissionTimeLong                               |-> [i \in 1 .. 9 |-> 0],
      recordProcessCategory                              |-> [i \in 1 .. 1 |-> 0],
      abbreviatedIssueName                               |-> [i \in 1 .. 40 |-> 0],
      abbreviatedIssueNameInEn                           |-> [i \in 1 .. 40 |-> 0],
      issuerCode                                         |-> [i \in 1 .. 5 |-> 0],
      bondListingTypeCode                                |-> [i \in 1 .. 1 |-> 0],
      bondCategoryCode                                   |-> [i \in 1 .. 6 |-> 0],
      bondTypeCode                                       |-> [i \in 1 .. 2 |-> 0],
      specialBondIssueCode                               |-> [i \in 1 .. 3 |-> 0],
      mbTypeCode                                         |-> [i \in 1 .. 1 |-> 0],
      bondGuaranteedTypeCode                             |-> [i \in 1 .. 1 |-> 0],
      guaranteedRateForPayment                           |-> [i \in 1 .. 13 |-> 0],
      otherTypesOfBond                                   |-> [i \in 1 .. 1 |-> 0],
      optionEmbeddedTypeCode                             |-> [i \in 1 .. 1 |-> 0],
      couponPaymentTypeCode                              |-> [i \in 1 .. 2 |-> 0],
      riskBondRedemptionTypeCode                         |-> [i \in 1 .. 1 |-> 0],
      bondIssuanceTypeCode                               |-> [i \in 1 .. 3 |-> 0],
      securitizationTypeCode                             |-> [i \in 1 .. 2 |-> 0],
      redemptionPriorityTypeCode                         |-> [i \in 1 .. 1 |-> 0],
      listingDate                                        |-> [i \in 1 .. 8 |-> 0],
      issueDate                                          |-> [i \in 1 .. 8 |-> 0],
      redemptionDate                                     |-> [i \in 1 .. 8 |-> 0],
      saleDate                                           |-> [i \in 1 .. 8 |-> 0],
      the1StCouponPaymentDate                            |-> [i \in 1 .. 8 |-> 0],
      bondIssuanceRate                                   |-> [i \in 1 .. 13 |-> 0],
      couponRate                                         |-> [i \in 1 .. 14 |-> 0],
      monthlyCycleOfCouponPayment                        |-> [i \in 1 .. 4 |-> 0],
      couponPaymentTimingCode                            |-> [i \in 1 .. 1 |-> 0],
      interestPayment                                    |-> [i \in 1 .. 1 |-> 0],
      couponPaymentDateTypeCode                          |-> [i \in 1 .. 1 |-> 0],
      decimalPointOfCouponTypeCode                       |-> [i \in 1 .. 1 |-> 0],
      numberOfMonthsToPayInterest                        |-> [i \in 1 .. 4 |-> 0],
      bondSaleTypeCode                                   |-> [i \in 1 .. 1 |-> 0],
      preIssueSaleCouponPaymentTypeCode                  |-> [i \in 1 .. 1 |-> 0],
      issuingAmount                                      |-> [i \in 1 .. 22 |-> 0],
      listedAmount                                       |-> [i \in 1 .. 22 |-> 0],
      confirmationOfLumpSumPayment                       |-> [i \in 1 .. 1 |-> 0],
      currencyTypeCode                                   |-> [i \in 1 .. 1 |-> 0],
      redemptionRatioAtMaturity                          |-> [i \in 1 .. 13 |-> 0],
      yieldToMaturity                                    |-> [i \in 1 .. 13 |-> 0],
      guaranteedYieldEffectiveDate                       |-> [i \in 1 .. 8 |-> 0],
      additionalYield                                    |-> [i \in 1 .. 13 |-> 0],
      additionalYieldEffectiveDate                       |-> [i \in 1 .. 8 |-> 0],
      facilityFund                                       |-> [i \in 1 .. 22 |-> 0],
      maintenanceFund                                    |-> [i \in 1 .. 22 |-> 0],
      loanFund                                           |-> [i \in 1 .. 22 |-> 0],
      otherFunds                                         |-> [i \in 1 .. 22 |-> 0],
      inscriptionTypeOfBond                              |-> [i \in 1 .. 1 |-> 0],
      taxation                                           |-> [i \in 1 .. 1 |-> 0],
      bondLeadManagerCompanyCode                         |-> [i \in 1 .. 4 |-> 0],
      paymentGuarantorCode                               |-> [i \in 1 .. 4 |-> 0],
      trusteeCode                                        |-> [i \in 1 .. 4 |-> 0],
      registerInstituteCode                              |-> [i \in 1 .. 4 |-> 0],
      paymentAgentCode                                   |-> [i \in 1 .. 4 |-> 0],
      abbreviatedIssueCode                               |-> [i \in 1 .. 9 |-> 0],
      bondDelistingReasonCode                            |-> [i \in 1 .. 2 |-> 0],
      bondDelistedDate                                   |-> [i \in 1 .. 8 |-> 0],
      equityLinkedBondRightsTypeCode                     |-> [i \in 1 .. 2 |-> 0],
      isin                                               |-> [i \in 1 .. 12 |-> 0],
      issueNameShort                                     |-> [i \in 1 .. 60 |-> 0],
      equityLinkedBondExercisePrice                      |-> [i \in 1 .. 11 |-> 0],
      exerciseRatio                                      |-> [i \in 1 .. 7 |-> 0],
      dateToStartExercising                              |-> [i \in 1 .. 8 |-> 0],
      dateToEndExercising                                |-> [i \in 1 .. 8 |-> 0],
      institutionCode                                    |-> [i \in 1 .. 4 |-> 0],
      recordDateOfDividendPayout                         |-> [i \in 1 .. 1 |-> 0],
      profitParticipatingAccumStatus                     |-> [i \in 1 .. 1 |-> 0],
      issueCodeOfPostExercise                            |-> [i \in 1 .. 12 |-> 0],
      amortizationTypeCode                               |-> [i \in 1 .. 1 |-> 0],
      levelPaymentAmount                                 |-> [i \in 1 .. 22 |-> 0],
      numberOfMonthsForGrace                             |-> [i \in 1 .. 4 |-> 0],
      interestTypeCodeDuringAmortization                 |-> [i \in 1 .. 1 |-> 0],
      numberOfAmortization                               |-> [i \in 1 .. 5 |-> 0],
      interestRateDecisionOtherBaseRateName              |-> [i \in 1 .. 20 |-> 0],
      spread                                             |-> [i \in 1 .. 10 |-> 0],
      timingOfInterestRateDecisionTypeCode               |-> [i \in 1 .. 1 |-> 0],
      upperLimitCouponRate                               |-> [i \in 1 .. 14 |-> 0],
      lowerLimitCouponRate                               |-> [i \in 1 .. 14 |-> 0],
      theDateToDecideInterestRate                        |-> [i \in 1 .. 8 |-> 0],
      firstCallExerciseStartDate                         |-> [i \in 1 .. 8 |-> 0],
      firstCallExerciseEndDate                           |-> [i \in 1 .. 8 |-> 0],
      secondCallExerciseStartDate                        |-> [i \in 1 .. 8 |-> 0],
      secondCallExerciseEndDate                          |-> [i \in 1 .. 8 |-> 0],
      firstPutExerciseStartDate                          |-> [i \in 1 .. 8 |-> 0],
      firstPutExerciseEndDate                            |-> [i \in 1 .. 8 |-> 0],
      secondPutExerciseStartDate                         |-> [i \in 1 .. 8 |-> 0],
      secondPutExerciseEndDate                           |-> [i \in 1 .. 8 |-> 0],
      couponPaymentDecisionCodeForBankHolidays           |-> [i \in 1 .. 1 |-> 0],
      hybridBond                                         |-> [i \in 1 .. 1 |-> 0],
      coCosTypeCode                                      |-> [i \in 1 .. 1 |-> 0],
      couponRateConfirmation                             |-> [i \in 1 .. 1 |-> 0],
      principalGuranteedRate                             |-> [i \in 1 .. 13 |-> 0],
      participatingRate                                  |-> [i \in 1 .. 11 |-> 0],
      maximumYield                                       |-> [i \in 1 .. 11 |-> 0],
      stripBondTypeCode                                  |-> [i \in 1 .. 1 |-> 0],
      originalBondTypeCodeSubjecToStrip                  |-> [i \in 1 .. 12 |-> 0],
      unstrippedBalance                                  |-> [i \in 1 .. 22 |-> 0],
      inflationIndexedCategory                           |-> [i \in 1 .. 1 |-> 0],
      referenceIndexForIssueDate                         |-> [i \in 1 .. 11 |-> 0],
      couponRateDecisionBaseRateTypeCode                 |-> [i \in 1 .. 2 |-> 0],
      bondOddLotDaysBaseInterestTypeCode                 |-> [i \in 1 .. 1 |-> 0],
      baseInterestRateOnBankHolidaysTypeCode             |-> [i \in 1 .. 1 |-> 0],
      accruedInterestRateOnBankHolidaysTypeCode          |-> [i \in 1 .. 14 |-> 0],
      principalPaymentMethodsOnBankHolidaysTypeCode      |-> [i \in 1 .. 1 |-> 0],
      principalBaseRateOnBankHolidaysTypeCode            |-> [i \in 1 .. 1 |-> 0],
      principalAccruedInterestRateOnBankHolidaysTypeCode |-> [i \in 1 .. 14 |-> 0],
      stopOutRate                                        |-> [i \in 1 .. 14 |-> 0],
      crowdfunding                                       |-> [i \in 1 .. 1 |-> 0],
      endKeyword                                         |-> [i \in 1 .. 1 |-> 0] ]

(* Bonds Isin Issue Information Message at zero, then each field in turn at the values it is checked at *)
CheckedBondsIsinIssueInformationMessage ==
    { ZeroBondsIsinIssueInformationMessage }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.transmissionDate = one] : one \in Sample(8) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.transmissionTimeLong = one] : one \in Sample(9) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.recordProcessCategory = one] : one \in Sample(1) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.abbreviatedIssueName = one] : one \in Sample(40) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.abbreviatedIssueNameInEn = one] : one \in Sample(40) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.issuerCode = one] : one \in Sample(5) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.bondListingTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.bondCategoryCode = one] : one \in Sample(6) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.bondTypeCode = one] : one \in Sample(2) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.specialBondIssueCode = one] : one \in Sample(3) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.mbTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.bondGuaranteedTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.guaranteedRateForPayment = one] : one \in Sample(13) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.otherTypesOfBond = one] : one \in Sample(1) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.optionEmbeddedTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.couponPaymentTypeCode = one] : one \in Sample(2) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.riskBondRedemptionTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.bondIssuanceTypeCode = one] : one \in Sample(3) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.securitizationTypeCode = one] : one \in Sample(2) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.redemptionPriorityTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.listingDate = one] : one \in Sample(8) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.issueDate = one] : one \in Sample(8) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.redemptionDate = one] : one \in Sample(8) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.saleDate = one] : one \in Sample(8) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.the1StCouponPaymentDate = one] : one \in Sample(8) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.bondIssuanceRate = one] : one \in Sample(13) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.couponRate = one] : one \in Sample(14) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.monthlyCycleOfCouponPayment = one] : one \in Sample(4) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.couponPaymentTimingCode = one] : one \in Sample(1) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.interestPayment = one] : one \in Sample(1) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.couponPaymentDateTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.decimalPointOfCouponTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.numberOfMonthsToPayInterest = one] : one \in Sample(4) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.bondSaleTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.preIssueSaleCouponPaymentTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.issuingAmount = one] : one \in Sample(22) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.listedAmount = one] : one \in Sample(22) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.confirmationOfLumpSumPayment = one] : one \in Sample(1) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.currencyTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.redemptionRatioAtMaturity = one] : one \in Sample(13) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.yieldToMaturity = one] : one \in Sample(13) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.guaranteedYieldEffectiveDate = one] : one \in Sample(8) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.additionalYield = one] : one \in Sample(13) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.additionalYieldEffectiveDate = one] : one \in Sample(8) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.facilityFund = one] : one \in Sample(22) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.maintenanceFund = one] : one \in Sample(22) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.loanFund = one] : one \in Sample(22) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.otherFunds = one] : one \in Sample(22) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.inscriptionTypeOfBond = one] : one \in Sample(1) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.taxation = one] : one \in Sample(1) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.bondLeadManagerCompanyCode = one] : one \in Sample(4) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.paymentGuarantorCode = one] : one \in Sample(4) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.trusteeCode = one] : one \in Sample(4) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.registerInstituteCode = one] : one \in Sample(4) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.paymentAgentCode = one] : one \in Sample(4) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.abbreviatedIssueCode = one] : one \in Sample(9) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.bondDelistingReasonCode = one] : one \in Sample(2) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.bondDelistedDate = one] : one \in Sample(8) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.equityLinkedBondRightsTypeCode = one] : one \in Sample(2) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.issueNameShort = one] : one \in Sample(60) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.equityLinkedBondExercisePrice = one] : one \in Sample(11) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.exerciseRatio = one] : one \in Sample(7) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.dateToStartExercising = one] : one \in Sample(8) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.dateToEndExercising = one] : one \in Sample(8) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.institutionCode = one] : one \in Sample(4) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.recordDateOfDividendPayout = one] : one \in Sample(1) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.profitParticipatingAccumStatus = one] : one \in Sample(1) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.issueCodeOfPostExercise = one] : one \in Sample(12) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.amortizationTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.levelPaymentAmount = one] : one \in Sample(22) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.numberOfMonthsForGrace = one] : one \in Sample(4) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.interestTypeCodeDuringAmortization = one] : one \in Sample(1) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.numberOfAmortization = one] : one \in Sample(5) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.interestRateDecisionOtherBaseRateName = one] : one \in Sample(20) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.spread = one] : one \in Sample(10) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.timingOfInterestRateDecisionTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.upperLimitCouponRate = one] : one \in Sample(14) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.lowerLimitCouponRate = one] : one \in Sample(14) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.theDateToDecideInterestRate = one] : one \in Sample(8) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.firstCallExerciseStartDate = one] : one \in Sample(8) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.firstCallExerciseEndDate = one] : one \in Sample(8) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.secondCallExerciseStartDate = one] : one \in Sample(8) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.secondCallExerciseEndDate = one] : one \in Sample(8) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.firstPutExerciseStartDate = one] : one \in Sample(8) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.firstPutExerciseEndDate = one] : one \in Sample(8) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.secondPutExerciseStartDate = one] : one \in Sample(8) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.secondPutExerciseEndDate = one] : one \in Sample(8) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.couponPaymentDecisionCodeForBankHolidays = one] : one \in Sample(1) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.hybridBond = one] : one \in Sample(1) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.coCosTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.couponRateConfirmation = one] : one \in Sample(1) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.principalGuranteedRate = one] : one \in Sample(13) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.participatingRate = one] : one \in Sample(11) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.maximumYield = one] : one \in Sample(11) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.stripBondTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.originalBondTypeCodeSubjecToStrip = one] : one \in Sample(12) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.unstrippedBalance = one] : one \in Sample(22) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.inflationIndexedCategory = one] : one \in Sample(1) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.referenceIndexForIssueDate = one] : one \in Sample(11) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.couponRateDecisionBaseRateTypeCode = one] : one \in Sample(2) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.bondOddLotDaysBaseInterestTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.baseInterestRateOnBankHolidaysTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.accruedInterestRateOnBankHolidaysTypeCode = one] : one \in Sample(14) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.principalPaymentMethodsOnBankHolidaysTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.principalBaseRateOnBankHolidaysTypeCode = one] : one \in Sample(1) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.principalAccruedInterestRateOnBankHolidaysTypeCode = one] : one \in Sample(14) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.stopOutRate = one] : one \in Sample(14) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.crowdfunding = one] : one \in Sample(1) }
        \cup { [ZeroBondsIsinIssueInformationMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Bonds Isin Information Text Message: 649 bytes                          *)
(***************************************************************************)

BondsIsinInformationTextMessage ==
    [ messageSequenceNumber     : Sample(8),
      isinCode                  : Sample(12),
      transmissionDate          : Sample(8),
      issueNameLong             : Sample(80),
      englishIssueName          : Sample(80),
      unusualIssuanceCondition  : Sample(60),
      reasonForExercisingACall  : Sample(50),
      reasonForExercisingAPut   : Sample(50),
      contentsOfUnderlyingAsset : Sample(100),
      elsCondition1             : Sample(100),
      elsCondition2             : Sample(100),
      endKeyword                : Sample(1) ]

EncodeBondsIsinInformationTextMessage(message) ==
    message.messageSequenceNumber
        \o message.isinCode
        \o message.transmissionDate
        \o message.issueNameLong
        \o message.englishIssueName
        \o message.unusualIssuanceCondition
        \o message.reasonForExercisingACall
        \o message.reasonForExercisingAPut
        \o message.contentsOfUnderlyingAsset
        \o message.elsCondition1
        \o message.elsCondition2
        \o message.endKeyword

DecodeBondsIsinInformationTextMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET isinCode == ReadBytes(messageSequenceNumber.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET transmissionDate == ReadBytes(isinCode.rest, 8) IN IF ~transmissionDate.ok THEN Fail ELSE
    LET issueNameLong == ReadBytes(transmissionDate.rest, 80) IN IF ~issueNameLong.ok THEN Fail ELSE
    LET englishIssueName == ReadBytes(issueNameLong.rest, 80) IN IF ~englishIssueName.ok THEN Fail ELSE
    LET unusualIssuanceCondition == ReadBytes(englishIssueName.rest, 60) IN IF ~unusualIssuanceCondition.ok THEN Fail ELSE
    LET reasonForExercisingACall == ReadBytes(unusualIssuanceCondition.rest, 50) IN IF ~reasonForExercisingACall.ok THEN Fail ELSE
    LET reasonForExercisingAPut == ReadBytes(reasonForExercisingACall.rest, 50) IN IF ~reasonForExercisingAPut.ok THEN Fail ELSE
    LET contentsOfUnderlyingAsset == ReadBytes(reasonForExercisingAPut.rest, 100) IN IF ~contentsOfUnderlyingAsset.ok THEN Fail ELSE
    LET elsCondition1 == ReadBytes(contentsOfUnderlyingAsset.rest, 100) IN IF ~elsCondition1.ok THEN Fail ELSE
    LET elsCondition2 == ReadBytes(elsCondition1.rest, 100) IN IF ~elsCondition2.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(elsCondition2.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber     |-> messageSequenceNumber.value,
         isinCode                  |-> isinCode.value,
         transmissionDate          |-> transmissionDate.value,
         issueNameLong             |-> issueNameLong.value,
         englishIssueName          |-> englishIssueName.value,
         unusualIssuanceCondition  |-> unusualIssuanceCondition.value,
         reasonForExercisingACall  |-> reasonForExercisingACall.value,
         reasonForExercisingAPut   |-> reasonForExercisingAPut.value,
         contentsOfUnderlyingAsset |-> contentsOfUnderlyingAsset.value,
         elsCondition1             |-> elsCondition1.value,
         elsCondition2             |-> elsCondition2.value,
         endKeyword                |-> endKeyword.value ], endKeyword.rest)

ZeroBondsIsinInformationTextMessage ==
    [ messageSequenceNumber     |-> [i \in 1 .. 8 |-> 0],
      isinCode                  |-> [i \in 1 .. 12 |-> 0],
      transmissionDate          |-> [i \in 1 .. 8 |-> 0],
      issueNameLong             |-> [i \in 1 .. 80 |-> 0],
      englishIssueName          |-> [i \in 1 .. 80 |-> 0],
      unusualIssuanceCondition  |-> [i \in 1 .. 60 |-> 0],
      reasonForExercisingACall  |-> [i \in 1 .. 50 |-> 0],
      reasonForExercisingAPut   |-> [i \in 1 .. 50 |-> 0],
      contentsOfUnderlyingAsset |-> [i \in 1 .. 100 |-> 0],
      elsCondition1             |-> [i \in 1 .. 100 |-> 0],
      elsCondition2             |-> [i \in 1 .. 100 |-> 0],
      endKeyword                |-> [i \in 1 .. 1 |-> 0] ]

(* Bonds Isin Information Text Message at zero, then each field in turn at the values it is checked at *)
CheckedBondsIsinInformationTextMessage ==
    { ZeroBondsIsinInformationTextMessage }
        \cup { [ZeroBondsIsinInformationTextMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroBondsIsinInformationTextMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroBondsIsinInformationTextMessage EXCEPT !.transmissionDate = one] : one \in Sample(8) }
        \cup { [ZeroBondsIsinInformationTextMessage EXCEPT !.issueNameLong = one] : one \in Sample(80) }
        \cup { [ZeroBondsIsinInformationTextMessage EXCEPT !.englishIssueName = one] : one \in Sample(80) }
        \cup { [ZeroBondsIsinInformationTextMessage EXCEPT !.unusualIssuanceCondition = one] : one \in Sample(60) }
        \cup { [ZeroBondsIsinInformationTextMessage EXCEPT !.reasonForExercisingACall = one] : one \in Sample(50) }
        \cup { [ZeroBondsIsinInformationTextMessage EXCEPT !.reasonForExercisingAPut = one] : one \in Sample(50) }
        \cup { [ZeroBondsIsinInformationTextMessage EXCEPT !.contentsOfUnderlyingAsset = one] : one \in Sample(100) }
        \cup { [ZeroBondsIsinInformationTextMessage EXCEPT !.elsCondition1 = one] : one \in Sample(100) }
        \cup { [ZeroBondsIsinInformationTextMessage EXCEPT !.elsCondition2 = one] : one \in Sample(100) }
        \cup { [ZeroBondsIsinInformationTextMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Baby Bonds Quote Message: 877 bytes                                     *)
(***************************************************************************)

BabyBondsQuoteMessage ==
    [ messageSequenceNumber             : Sample(8),
      boardId                           : Sample(2),
      sessionId                         : Sample(2),
      isinCode                          : Sample(12),
      processingTimeOfTradingSystem     : Sample(12),
      askLevel1Price                    : Sample(11),
      bidLevel1Price                    : Sample(11),
      askLevel1RemainingQuantity        : Sample(15),
      bidLevel1RemainingQuantity        : Sample(15),
      askLevel1Yield                    : Sample(13),
      bidLevel1Yield                    : Sample(13),
      askPerTypeLevel1Price             : Sample(11),
      bidPerTypeLevel1Price             : Sample(11),
      askPerTypeLevel1RemainingQuantity : Sample(15),
      bidPerTypeLevel1RemainingQuantity : Sample(15),
      askPerTypeLevel1Yield             : Sample(13),
      bidPerTypeLevel1Yield             : Sample(13),
      askLevel2Price                    : Sample(11),
      bidLevel2Price                    : Sample(11),
      askLevel2RemainingQuantity        : Sample(15),
      bidLevel2RemainingQuantity        : Sample(15),
      askLevel2Yield                    : Sample(13),
      bidLevel2Yield                    : Sample(13),
      askPerTypeLevel2Price             : Sample(11),
      bidPerTypeLevel2Price             : Sample(11),
      askPerTypeLevel2RemainingQuantity : Sample(15),
      bidPerTypeLevel2RemainingQuantity : Sample(15),
      askPerTypeLevel2Yield             : Sample(13),
      bidPerTypeLevel2Yield             : Sample(13),
      askLevel3Price                    : Sample(11),
      bidLevel3Price                    : Sample(11),
      askLevel3RemainingQuantity        : Sample(15),
      bidLevel3RemainingQuantity        : Sample(15),
      askLevel3Yield                    : Sample(13),
      bidLevel3Yield                    : Sample(13),
      askPerTypeLevel3Price             : Sample(11),
      bidPerTypeLevel3Price             : Sample(11),
      askPerTypeLevel3RemainingQuantity : Sample(15),
      bidPerTypeLevel3RemainingQuantity : Sample(15),
      askPerTypeLevel3Yield             : Sample(13),
      bidPerTypeLevel3Yield             : Sample(13),
      askLevel4Price                    : Sample(11),
      bidLevel4Price                    : Sample(11),
      askLevel4RemainingQuantity        : Sample(15),
      bidLevel4RemainingQuantity        : Sample(15),
      askLevel4Yield                    : Sample(13),
      bidLevel4Yield                    : Sample(13),
      askPerTypeLevel4Price             : Sample(11),
      bidPerTypeLevel4Price             : Sample(11),
      askPerTypeLevel4RemainingQuantity : Sample(15),
      bidPerTypeLevel4RemainingQuantity : Sample(15),
      askPerTypeLevel4Yield             : Sample(13),
      bidPerTypeLevel4Yield             : Sample(13),
      askLevel5Price                    : Sample(11),
      bidLevel5Price                    : Sample(11),
      askLevel5RemainingQuantity        : Sample(15),
      bidLevel5RemainingQuantity        : Sample(15),
      askLevel5Yield                    : Sample(13),
      bidLevel5Yield                    : Sample(13),
      askPerTypeLevel5Price             : Sample(11),
      bidPerTypeLevel5Price             : Sample(11),
      askPerTypeLevel5RemainingQuantity : Sample(15),
      bidPerTypeLevel5RemainingQuantity : Sample(15),
      askPerTypeLevel5Yield             : Sample(13),
      bidPerTypeLevel5Yield             : Sample(13),
      askTotalRemainingQuantity         : Sample(15),
      bidTotalRemainingQuantity         : Sample(15),
      askPerTypeTotalRemainingQuantity  : Sample(15),
      bidPerTypeTotalRemainingQuantity  : Sample(15),
      endKeyword                        : Sample(1) ]

EncodeBabyBondsQuoteMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.sessionId
        \o message.isinCode
        \o message.processingTimeOfTradingSystem
        \o message.askLevel1Price
        \o message.bidLevel1Price
        \o message.askLevel1RemainingQuantity
        \o message.bidLevel1RemainingQuantity
        \o message.askLevel1Yield
        \o message.bidLevel1Yield
        \o message.askPerTypeLevel1Price
        \o message.bidPerTypeLevel1Price
        \o message.askPerTypeLevel1RemainingQuantity
        \o message.bidPerTypeLevel1RemainingQuantity
        \o message.askPerTypeLevel1Yield
        \o message.bidPerTypeLevel1Yield
        \o message.askLevel2Price
        \o message.bidLevel2Price
        \o message.askLevel2RemainingQuantity
        \o message.bidLevel2RemainingQuantity
        \o message.askLevel2Yield
        \o message.bidLevel2Yield
        \o message.askPerTypeLevel2Price
        \o message.bidPerTypeLevel2Price
        \o message.askPerTypeLevel2RemainingQuantity
        \o message.bidPerTypeLevel2RemainingQuantity
        \o message.askPerTypeLevel2Yield
        \o message.bidPerTypeLevel2Yield
        \o message.askLevel3Price
        \o message.bidLevel3Price
        \o message.askLevel3RemainingQuantity
        \o message.bidLevel3RemainingQuantity
        \o message.askLevel3Yield
        \o message.bidLevel3Yield
        \o message.askPerTypeLevel3Price
        \o message.bidPerTypeLevel3Price
        \o message.askPerTypeLevel3RemainingQuantity
        \o message.bidPerTypeLevel3RemainingQuantity
        \o message.askPerTypeLevel3Yield
        \o message.bidPerTypeLevel3Yield
        \o message.askLevel4Price
        \o message.bidLevel4Price
        \o message.askLevel4RemainingQuantity
        \o message.bidLevel4RemainingQuantity
        \o message.askLevel4Yield
        \o message.bidLevel4Yield
        \o message.askPerTypeLevel4Price
        \o message.bidPerTypeLevel4Price
        \o message.askPerTypeLevel4RemainingQuantity
        \o message.bidPerTypeLevel4RemainingQuantity
        \o message.askPerTypeLevel4Yield
        \o message.bidPerTypeLevel4Yield
        \o message.askLevel5Price
        \o message.bidLevel5Price
        \o message.askLevel5RemainingQuantity
        \o message.bidLevel5RemainingQuantity
        \o message.askLevel5Yield
        \o message.bidLevel5Yield
        \o message.askPerTypeLevel5Price
        \o message.bidPerTypeLevel5Price
        \o message.askPerTypeLevel5RemainingQuantity
        \o message.bidPerTypeLevel5RemainingQuantity
        \o message.askPerTypeLevel5Yield
        \o message.bidPerTypeLevel5Yield
        \o message.askTotalRemainingQuantity
        \o message.bidTotalRemainingQuantity
        \o message.askPerTypeTotalRemainingQuantity
        \o message.bidPerTypeTotalRemainingQuantity
        \o message.endKeyword

DecodeBabyBondsQuoteMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(boardId.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(sessionId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET processingTimeOfTradingSystem == ReadBytes(isinCode.rest, 12) IN IF ~processingTimeOfTradingSystem.ok THEN Fail ELSE
    LET askLevel1Price == ReadBytes(processingTimeOfTradingSystem.rest, 11) IN IF ~askLevel1Price.ok THEN Fail ELSE
    LET bidLevel1Price == ReadBytes(askLevel1Price.rest, 11) IN IF ~bidLevel1Price.ok THEN Fail ELSE
    LET askLevel1RemainingQuantity == ReadBytes(bidLevel1Price.rest, 15) IN IF ~askLevel1RemainingQuantity.ok THEN Fail ELSE
    LET bidLevel1RemainingQuantity == ReadBytes(askLevel1RemainingQuantity.rest, 15) IN IF ~bidLevel1RemainingQuantity.ok THEN Fail ELSE
    LET askLevel1Yield == ReadBytes(bidLevel1RemainingQuantity.rest, 13) IN IF ~askLevel1Yield.ok THEN Fail ELSE
    LET bidLevel1Yield == ReadBytes(askLevel1Yield.rest, 13) IN IF ~bidLevel1Yield.ok THEN Fail ELSE
    LET askPerTypeLevel1Price == ReadBytes(bidLevel1Yield.rest, 11) IN IF ~askPerTypeLevel1Price.ok THEN Fail ELSE
    LET bidPerTypeLevel1Price == ReadBytes(askPerTypeLevel1Price.rest, 11) IN IF ~bidPerTypeLevel1Price.ok THEN Fail ELSE
    LET askPerTypeLevel1RemainingQuantity == ReadBytes(bidPerTypeLevel1Price.rest, 15) IN IF ~askPerTypeLevel1RemainingQuantity.ok THEN Fail ELSE
    LET bidPerTypeLevel1RemainingQuantity == ReadBytes(askPerTypeLevel1RemainingQuantity.rest, 15) IN IF ~bidPerTypeLevel1RemainingQuantity.ok THEN Fail ELSE
    LET askPerTypeLevel1Yield == ReadBytes(bidPerTypeLevel1RemainingQuantity.rest, 13) IN IF ~askPerTypeLevel1Yield.ok THEN Fail ELSE
    LET bidPerTypeLevel1Yield == ReadBytes(askPerTypeLevel1Yield.rest, 13) IN IF ~bidPerTypeLevel1Yield.ok THEN Fail ELSE
    LET askLevel2Price == ReadBytes(bidPerTypeLevel1Yield.rest, 11) IN IF ~askLevel2Price.ok THEN Fail ELSE
    LET bidLevel2Price == ReadBytes(askLevel2Price.rest, 11) IN IF ~bidLevel2Price.ok THEN Fail ELSE
    LET askLevel2RemainingQuantity == ReadBytes(bidLevel2Price.rest, 15) IN IF ~askLevel2RemainingQuantity.ok THEN Fail ELSE
    LET bidLevel2RemainingQuantity == ReadBytes(askLevel2RemainingQuantity.rest, 15) IN IF ~bidLevel2RemainingQuantity.ok THEN Fail ELSE
    LET askLevel2Yield == ReadBytes(bidLevel2RemainingQuantity.rest, 13) IN IF ~askLevel2Yield.ok THEN Fail ELSE
    LET bidLevel2Yield == ReadBytes(askLevel2Yield.rest, 13) IN IF ~bidLevel2Yield.ok THEN Fail ELSE
    LET askPerTypeLevel2Price == ReadBytes(bidLevel2Yield.rest, 11) IN IF ~askPerTypeLevel2Price.ok THEN Fail ELSE
    LET bidPerTypeLevel2Price == ReadBytes(askPerTypeLevel2Price.rest, 11) IN IF ~bidPerTypeLevel2Price.ok THEN Fail ELSE
    LET askPerTypeLevel2RemainingQuantity == ReadBytes(bidPerTypeLevel2Price.rest, 15) IN IF ~askPerTypeLevel2RemainingQuantity.ok THEN Fail ELSE
    LET bidPerTypeLevel2RemainingQuantity == ReadBytes(askPerTypeLevel2RemainingQuantity.rest, 15) IN IF ~bidPerTypeLevel2RemainingQuantity.ok THEN Fail ELSE
    LET askPerTypeLevel2Yield == ReadBytes(bidPerTypeLevel2RemainingQuantity.rest, 13) IN IF ~askPerTypeLevel2Yield.ok THEN Fail ELSE
    LET bidPerTypeLevel2Yield == ReadBytes(askPerTypeLevel2Yield.rest, 13) IN IF ~bidPerTypeLevel2Yield.ok THEN Fail ELSE
    LET askLevel3Price == ReadBytes(bidPerTypeLevel2Yield.rest, 11) IN IF ~askLevel3Price.ok THEN Fail ELSE
    LET bidLevel3Price == ReadBytes(askLevel3Price.rest, 11) IN IF ~bidLevel3Price.ok THEN Fail ELSE
    LET askLevel3RemainingQuantity == ReadBytes(bidLevel3Price.rest, 15) IN IF ~askLevel3RemainingQuantity.ok THEN Fail ELSE
    LET bidLevel3RemainingQuantity == ReadBytes(askLevel3RemainingQuantity.rest, 15) IN IF ~bidLevel3RemainingQuantity.ok THEN Fail ELSE
    LET askLevel3Yield == ReadBytes(bidLevel3RemainingQuantity.rest, 13) IN IF ~askLevel3Yield.ok THEN Fail ELSE
    LET bidLevel3Yield == ReadBytes(askLevel3Yield.rest, 13) IN IF ~bidLevel3Yield.ok THEN Fail ELSE
    LET askPerTypeLevel3Price == ReadBytes(bidLevel3Yield.rest, 11) IN IF ~askPerTypeLevel3Price.ok THEN Fail ELSE
    LET bidPerTypeLevel3Price == ReadBytes(askPerTypeLevel3Price.rest, 11) IN IF ~bidPerTypeLevel3Price.ok THEN Fail ELSE
    LET askPerTypeLevel3RemainingQuantity == ReadBytes(bidPerTypeLevel3Price.rest, 15) IN IF ~askPerTypeLevel3RemainingQuantity.ok THEN Fail ELSE
    LET bidPerTypeLevel3RemainingQuantity == ReadBytes(askPerTypeLevel3RemainingQuantity.rest, 15) IN IF ~bidPerTypeLevel3RemainingQuantity.ok THEN Fail ELSE
    LET askPerTypeLevel3Yield == ReadBytes(bidPerTypeLevel3RemainingQuantity.rest, 13) IN IF ~askPerTypeLevel3Yield.ok THEN Fail ELSE
    LET bidPerTypeLevel3Yield == ReadBytes(askPerTypeLevel3Yield.rest, 13) IN IF ~bidPerTypeLevel3Yield.ok THEN Fail ELSE
    LET askLevel4Price == ReadBytes(bidPerTypeLevel3Yield.rest, 11) IN IF ~askLevel4Price.ok THEN Fail ELSE
    LET bidLevel4Price == ReadBytes(askLevel4Price.rest, 11) IN IF ~bidLevel4Price.ok THEN Fail ELSE
    LET askLevel4RemainingQuantity == ReadBytes(bidLevel4Price.rest, 15) IN IF ~askLevel4RemainingQuantity.ok THEN Fail ELSE
    LET bidLevel4RemainingQuantity == ReadBytes(askLevel4RemainingQuantity.rest, 15) IN IF ~bidLevel4RemainingQuantity.ok THEN Fail ELSE
    LET askLevel4Yield == ReadBytes(bidLevel4RemainingQuantity.rest, 13) IN IF ~askLevel4Yield.ok THEN Fail ELSE
    LET bidLevel4Yield == ReadBytes(askLevel4Yield.rest, 13) IN IF ~bidLevel4Yield.ok THEN Fail ELSE
    LET askPerTypeLevel4Price == ReadBytes(bidLevel4Yield.rest, 11) IN IF ~askPerTypeLevel4Price.ok THEN Fail ELSE
    LET bidPerTypeLevel4Price == ReadBytes(askPerTypeLevel4Price.rest, 11) IN IF ~bidPerTypeLevel4Price.ok THEN Fail ELSE
    LET askPerTypeLevel4RemainingQuantity == ReadBytes(bidPerTypeLevel4Price.rest, 15) IN IF ~askPerTypeLevel4RemainingQuantity.ok THEN Fail ELSE
    LET bidPerTypeLevel4RemainingQuantity == ReadBytes(askPerTypeLevel4RemainingQuantity.rest, 15) IN IF ~bidPerTypeLevel4RemainingQuantity.ok THEN Fail ELSE
    LET askPerTypeLevel4Yield == ReadBytes(bidPerTypeLevel4RemainingQuantity.rest, 13) IN IF ~askPerTypeLevel4Yield.ok THEN Fail ELSE
    LET bidPerTypeLevel4Yield == ReadBytes(askPerTypeLevel4Yield.rest, 13) IN IF ~bidPerTypeLevel4Yield.ok THEN Fail ELSE
    LET askLevel5Price == ReadBytes(bidPerTypeLevel4Yield.rest, 11) IN IF ~askLevel5Price.ok THEN Fail ELSE
    LET bidLevel5Price == ReadBytes(askLevel5Price.rest, 11) IN IF ~bidLevel5Price.ok THEN Fail ELSE
    LET askLevel5RemainingQuantity == ReadBytes(bidLevel5Price.rest, 15) IN IF ~askLevel5RemainingQuantity.ok THEN Fail ELSE
    LET bidLevel5RemainingQuantity == ReadBytes(askLevel5RemainingQuantity.rest, 15) IN IF ~bidLevel5RemainingQuantity.ok THEN Fail ELSE
    LET askLevel5Yield == ReadBytes(bidLevel5RemainingQuantity.rest, 13) IN IF ~askLevel5Yield.ok THEN Fail ELSE
    LET bidLevel5Yield == ReadBytes(askLevel5Yield.rest, 13) IN IF ~bidLevel5Yield.ok THEN Fail ELSE
    LET askPerTypeLevel5Price == ReadBytes(bidLevel5Yield.rest, 11) IN IF ~askPerTypeLevel5Price.ok THEN Fail ELSE
    LET bidPerTypeLevel5Price == ReadBytes(askPerTypeLevel5Price.rest, 11) IN IF ~bidPerTypeLevel5Price.ok THEN Fail ELSE
    LET askPerTypeLevel5RemainingQuantity == ReadBytes(bidPerTypeLevel5Price.rest, 15) IN IF ~askPerTypeLevel5RemainingQuantity.ok THEN Fail ELSE
    LET bidPerTypeLevel5RemainingQuantity == ReadBytes(askPerTypeLevel5RemainingQuantity.rest, 15) IN IF ~bidPerTypeLevel5RemainingQuantity.ok THEN Fail ELSE
    LET askPerTypeLevel5Yield == ReadBytes(bidPerTypeLevel5RemainingQuantity.rest, 13) IN IF ~askPerTypeLevel5Yield.ok THEN Fail ELSE
    LET bidPerTypeLevel5Yield == ReadBytes(askPerTypeLevel5Yield.rest, 13) IN IF ~bidPerTypeLevel5Yield.ok THEN Fail ELSE
    LET askTotalRemainingQuantity == ReadBytes(bidPerTypeLevel5Yield.rest, 15) IN IF ~askTotalRemainingQuantity.ok THEN Fail ELSE
    LET bidTotalRemainingQuantity == ReadBytes(askTotalRemainingQuantity.rest, 15) IN IF ~bidTotalRemainingQuantity.ok THEN Fail ELSE
    LET askPerTypeTotalRemainingQuantity == ReadBytes(bidTotalRemainingQuantity.rest, 15) IN IF ~askPerTypeTotalRemainingQuantity.ok THEN Fail ELSE
    LET bidPerTypeTotalRemainingQuantity == ReadBytes(askPerTypeTotalRemainingQuantity.rest, 15) IN IF ~bidPerTypeTotalRemainingQuantity.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(bidPerTypeTotalRemainingQuantity.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber             |-> messageSequenceNumber.value,
         boardId                           |-> boardId.value,
         sessionId                         |-> sessionId.value,
         isinCode                          |-> isinCode.value,
         processingTimeOfTradingSystem     |-> processingTimeOfTradingSystem.value,
         askLevel1Price                    |-> askLevel1Price.value,
         bidLevel1Price                    |-> bidLevel1Price.value,
         askLevel1RemainingQuantity        |-> askLevel1RemainingQuantity.value,
         bidLevel1RemainingQuantity        |-> bidLevel1RemainingQuantity.value,
         askLevel1Yield                    |-> askLevel1Yield.value,
         bidLevel1Yield                    |-> bidLevel1Yield.value,
         askPerTypeLevel1Price             |-> askPerTypeLevel1Price.value,
         bidPerTypeLevel1Price             |-> bidPerTypeLevel1Price.value,
         askPerTypeLevel1RemainingQuantity |-> askPerTypeLevel1RemainingQuantity.value,
         bidPerTypeLevel1RemainingQuantity |-> bidPerTypeLevel1RemainingQuantity.value,
         askPerTypeLevel1Yield             |-> askPerTypeLevel1Yield.value,
         bidPerTypeLevel1Yield             |-> bidPerTypeLevel1Yield.value,
         askLevel2Price                    |-> askLevel2Price.value,
         bidLevel2Price                    |-> bidLevel2Price.value,
         askLevel2RemainingQuantity        |-> askLevel2RemainingQuantity.value,
         bidLevel2RemainingQuantity        |-> bidLevel2RemainingQuantity.value,
         askLevel2Yield                    |-> askLevel2Yield.value,
         bidLevel2Yield                    |-> bidLevel2Yield.value,
         askPerTypeLevel2Price             |-> askPerTypeLevel2Price.value,
         bidPerTypeLevel2Price             |-> bidPerTypeLevel2Price.value,
         askPerTypeLevel2RemainingQuantity |-> askPerTypeLevel2RemainingQuantity.value,
         bidPerTypeLevel2RemainingQuantity |-> bidPerTypeLevel2RemainingQuantity.value,
         askPerTypeLevel2Yield             |-> askPerTypeLevel2Yield.value,
         bidPerTypeLevel2Yield             |-> bidPerTypeLevel2Yield.value,
         askLevel3Price                    |-> askLevel3Price.value,
         bidLevel3Price                    |-> bidLevel3Price.value,
         askLevel3RemainingQuantity        |-> askLevel3RemainingQuantity.value,
         bidLevel3RemainingQuantity        |-> bidLevel3RemainingQuantity.value,
         askLevel3Yield                    |-> askLevel3Yield.value,
         bidLevel3Yield                    |-> bidLevel3Yield.value,
         askPerTypeLevel3Price             |-> askPerTypeLevel3Price.value,
         bidPerTypeLevel3Price             |-> bidPerTypeLevel3Price.value,
         askPerTypeLevel3RemainingQuantity |-> askPerTypeLevel3RemainingQuantity.value,
         bidPerTypeLevel3RemainingQuantity |-> bidPerTypeLevel3RemainingQuantity.value,
         askPerTypeLevel3Yield             |-> askPerTypeLevel3Yield.value,
         bidPerTypeLevel3Yield             |-> bidPerTypeLevel3Yield.value,
         askLevel4Price                    |-> askLevel4Price.value,
         bidLevel4Price                    |-> bidLevel4Price.value,
         askLevel4RemainingQuantity        |-> askLevel4RemainingQuantity.value,
         bidLevel4RemainingQuantity        |-> bidLevel4RemainingQuantity.value,
         askLevel4Yield                    |-> askLevel4Yield.value,
         bidLevel4Yield                    |-> bidLevel4Yield.value,
         askPerTypeLevel4Price             |-> askPerTypeLevel4Price.value,
         bidPerTypeLevel4Price             |-> bidPerTypeLevel4Price.value,
         askPerTypeLevel4RemainingQuantity |-> askPerTypeLevel4RemainingQuantity.value,
         bidPerTypeLevel4RemainingQuantity |-> bidPerTypeLevel4RemainingQuantity.value,
         askPerTypeLevel4Yield             |-> askPerTypeLevel4Yield.value,
         bidPerTypeLevel4Yield             |-> bidPerTypeLevel4Yield.value,
         askLevel5Price                    |-> askLevel5Price.value,
         bidLevel5Price                    |-> bidLevel5Price.value,
         askLevel5RemainingQuantity        |-> askLevel5RemainingQuantity.value,
         bidLevel5RemainingQuantity        |-> bidLevel5RemainingQuantity.value,
         askLevel5Yield                    |-> askLevel5Yield.value,
         bidLevel5Yield                    |-> bidLevel5Yield.value,
         askPerTypeLevel5Price             |-> askPerTypeLevel5Price.value,
         bidPerTypeLevel5Price             |-> bidPerTypeLevel5Price.value,
         askPerTypeLevel5RemainingQuantity |-> askPerTypeLevel5RemainingQuantity.value,
         bidPerTypeLevel5RemainingQuantity |-> bidPerTypeLevel5RemainingQuantity.value,
         askPerTypeLevel5Yield             |-> askPerTypeLevel5Yield.value,
         bidPerTypeLevel5Yield             |-> bidPerTypeLevel5Yield.value,
         askTotalRemainingQuantity         |-> askTotalRemainingQuantity.value,
         bidTotalRemainingQuantity         |-> bidTotalRemainingQuantity.value,
         askPerTypeTotalRemainingQuantity  |-> askPerTypeTotalRemainingQuantity.value,
         bidPerTypeTotalRemainingQuantity  |-> bidPerTypeTotalRemainingQuantity.value,
         endKeyword                        |-> endKeyword.value ], endKeyword.rest)

ZeroBabyBondsQuoteMessage ==
    [ messageSequenceNumber             |-> [i \in 1 .. 8 |-> 0],
      boardId                           |-> [i \in 1 .. 2 |-> 0],
      sessionId                         |-> [i \in 1 .. 2 |-> 0],
      isinCode                          |-> [i \in 1 .. 12 |-> 0],
      processingTimeOfTradingSystem     |-> [i \in 1 .. 12 |-> 0],
      askLevel1Price                    |-> [i \in 1 .. 11 |-> 0],
      bidLevel1Price                    |-> [i \in 1 .. 11 |-> 0],
      askLevel1RemainingQuantity        |-> [i \in 1 .. 15 |-> 0],
      bidLevel1RemainingQuantity        |-> [i \in 1 .. 15 |-> 0],
      askLevel1Yield                    |-> [i \in 1 .. 13 |-> 0],
      bidLevel1Yield                    |-> [i \in 1 .. 13 |-> 0],
      askPerTypeLevel1Price             |-> [i \in 1 .. 11 |-> 0],
      bidPerTypeLevel1Price             |-> [i \in 1 .. 11 |-> 0],
      askPerTypeLevel1RemainingQuantity |-> [i \in 1 .. 15 |-> 0],
      bidPerTypeLevel1RemainingQuantity |-> [i \in 1 .. 15 |-> 0],
      askPerTypeLevel1Yield             |-> [i \in 1 .. 13 |-> 0],
      bidPerTypeLevel1Yield             |-> [i \in 1 .. 13 |-> 0],
      askLevel2Price                    |-> [i \in 1 .. 11 |-> 0],
      bidLevel2Price                    |-> [i \in 1 .. 11 |-> 0],
      askLevel2RemainingQuantity        |-> [i \in 1 .. 15 |-> 0],
      bidLevel2RemainingQuantity        |-> [i \in 1 .. 15 |-> 0],
      askLevel2Yield                    |-> [i \in 1 .. 13 |-> 0],
      bidLevel2Yield                    |-> [i \in 1 .. 13 |-> 0],
      askPerTypeLevel2Price             |-> [i \in 1 .. 11 |-> 0],
      bidPerTypeLevel2Price             |-> [i \in 1 .. 11 |-> 0],
      askPerTypeLevel2RemainingQuantity |-> [i \in 1 .. 15 |-> 0],
      bidPerTypeLevel2RemainingQuantity |-> [i \in 1 .. 15 |-> 0],
      askPerTypeLevel2Yield             |-> [i \in 1 .. 13 |-> 0],
      bidPerTypeLevel2Yield             |-> [i \in 1 .. 13 |-> 0],
      askLevel3Price                    |-> [i \in 1 .. 11 |-> 0],
      bidLevel3Price                    |-> [i \in 1 .. 11 |-> 0],
      askLevel3RemainingQuantity        |-> [i \in 1 .. 15 |-> 0],
      bidLevel3RemainingQuantity        |-> [i \in 1 .. 15 |-> 0],
      askLevel3Yield                    |-> [i \in 1 .. 13 |-> 0],
      bidLevel3Yield                    |-> [i \in 1 .. 13 |-> 0],
      askPerTypeLevel3Price             |-> [i \in 1 .. 11 |-> 0],
      bidPerTypeLevel3Price             |-> [i \in 1 .. 11 |-> 0],
      askPerTypeLevel3RemainingQuantity |-> [i \in 1 .. 15 |-> 0],
      bidPerTypeLevel3RemainingQuantity |-> [i \in 1 .. 15 |-> 0],
      askPerTypeLevel3Yield             |-> [i \in 1 .. 13 |-> 0],
      bidPerTypeLevel3Yield             |-> [i \in 1 .. 13 |-> 0],
      askLevel4Price                    |-> [i \in 1 .. 11 |-> 0],
      bidLevel4Price                    |-> [i \in 1 .. 11 |-> 0],
      askLevel4RemainingQuantity        |-> [i \in 1 .. 15 |-> 0],
      bidLevel4RemainingQuantity        |-> [i \in 1 .. 15 |-> 0],
      askLevel4Yield                    |-> [i \in 1 .. 13 |-> 0],
      bidLevel4Yield                    |-> [i \in 1 .. 13 |-> 0],
      askPerTypeLevel4Price             |-> [i \in 1 .. 11 |-> 0],
      bidPerTypeLevel4Price             |-> [i \in 1 .. 11 |-> 0],
      askPerTypeLevel4RemainingQuantity |-> [i \in 1 .. 15 |-> 0],
      bidPerTypeLevel4RemainingQuantity |-> [i \in 1 .. 15 |-> 0],
      askPerTypeLevel4Yield             |-> [i \in 1 .. 13 |-> 0],
      bidPerTypeLevel4Yield             |-> [i \in 1 .. 13 |-> 0],
      askLevel5Price                    |-> [i \in 1 .. 11 |-> 0],
      bidLevel5Price                    |-> [i \in 1 .. 11 |-> 0],
      askLevel5RemainingQuantity        |-> [i \in 1 .. 15 |-> 0],
      bidLevel5RemainingQuantity        |-> [i \in 1 .. 15 |-> 0],
      askLevel5Yield                    |-> [i \in 1 .. 13 |-> 0],
      bidLevel5Yield                    |-> [i \in 1 .. 13 |-> 0],
      askPerTypeLevel5Price             |-> [i \in 1 .. 11 |-> 0],
      bidPerTypeLevel5Price             |-> [i \in 1 .. 11 |-> 0],
      askPerTypeLevel5RemainingQuantity |-> [i \in 1 .. 15 |-> 0],
      bidPerTypeLevel5RemainingQuantity |-> [i \in 1 .. 15 |-> 0],
      askPerTypeLevel5Yield             |-> [i \in 1 .. 13 |-> 0],
      bidPerTypeLevel5Yield             |-> [i \in 1 .. 13 |-> 0],
      askTotalRemainingQuantity         |-> [i \in 1 .. 15 |-> 0],
      bidTotalRemainingQuantity         |-> [i \in 1 .. 15 |-> 0],
      askPerTypeTotalRemainingQuantity  |-> [i \in 1 .. 15 |-> 0],
      bidPerTypeTotalRemainingQuantity  |-> [i \in 1 .. 15 |-> 0],
      endKeyword                        |-> [i \in 1 .. 1 |-> 0] ]

(* Baby Bonds Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedBabyBondsQuoteMessage ==
    { ZeroBabyBondsQuoteMessage }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.processingTimeOfTradingSystem = one] : one \in Sample(12) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.askLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.bidLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.askLevel1RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.bidLevel1RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.askLevel1Yield = one] : one \in Sample(13) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.bidLevel1Yield = one] : one \in Sample(13) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.askPerTypeLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.bidPerTypeLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.askPerTypeLevel1RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.bidPerTypeLevel1RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.askPerTypeLevel1Yield = one] : one \in Sample(13) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.bidPerTypeLevel1Yield = one] : one \in Sample(13) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.askLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.bidLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.askLevel2RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.bidLevel2RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.askLevel2Yield = one] : one \in Sample(13) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.bidLevel2Yield = one] : one \in Sample(13) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.askPerTypeLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.bidPerTypeLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.askPerTypeLevel2RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.bidPerTypeLevel2RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.askPerTypeLevel2Yield = one] : one \in Sample(13) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.bidPerTypeLevel2Yield = one] : one \in Sample(13) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.askLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.bidLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.askLevel3RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.bidLevel3RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.askLevel3Yield = one] : one \in Sample(13) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.bidLevel3Yield = one] : one \in Sample(13) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.askPerTypeLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.bidPerTypeLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.askPerTypeLevel3RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.bidPerTypeLevel3RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.askPerTypeLevel3Yield = one] : one \in Sample(13) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.bidPerTypeLevel3Yield = one] : one \in Sample(13) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.askLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.bidLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.askLevel4RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.bidLevel4RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.askLevel4Yield = one] : one \in Sample(13) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.bidLevel4Yield = one] : one \in Sample(13) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.askPerTypeLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.bidPerTypeLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.askPerTypeLevel4RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.bidPerTypeLevel4RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.askPerTypeLevel4Yield = one] : one \in Sample(13) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.bidPerTypeLevel4Yield = one] : one \in Sample(13) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.askLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.bidLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.askLevel5RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.bidLevel5RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.askLevel5Yield = one] : one \in Sample(13) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.bidLevel5Yield = one] : one \in Sample(13) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.askPerTypeLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.bidPerTypeLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.askPerTypeLevel5RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.bidPerTypeLevel5RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.askPerTypeLevel5Yield = one] : one \in Sample(13) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.bidPerTypeLevel5Yield = one] : one \in Sample(13) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.askTotalRemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.bidTotalRemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.askPerTypeTotalRemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.bidPerTypeTotalRemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsQuoteMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Repo Quote Message: 1382 bytes                                          *)
(***************************************************************************)

RepoQuoteMessage ==
    [ messageSequenceNumber                     : Sample(8),
      boardId                                   : Sample(2),
      sessionId                                 : Sample(2),
      isinCode                                  : Sample(12),
      processingTimeOfTradingSystem             : Sample(12),
      durationOfTermRepo                        : Sample(4),
      askLevel1Price                            : Sample(11),
      bidLevel1Price                            : Sample(11),
      askLevel1RemainingQuantity                : Sample(15),
      bidLevel1RemainingQuantity                : Sample(15),
      askLevel1TradingAmount                    : Sample(22),
      totalBidLevel1Price                       : Sample(11),
      totalBidLevel1RemainingQuantity           : Sample(15),
      bidLevel1IncludingGc                      : Sample(1),
      askPerTypeLevel1Price                     : Sample(11),
      bidPerTypeLevel1Price                     : Sample(11),
      askPerTypeLevel1RemainingQuantity         : Sample(15),
      bidPerTypeLevel1RemainingQuantity         : Sample(15),
      askPerTypeLevel1TradingAmount             : Sample(22),
      askLevel2Price                            : Sample(11),
      bidLevel2Price                            : Sample(11),
      askLevel2RemainingQuantity                : Sample(15),
      bidLevel2RemainingQuantity                : Sample(15),
      askLevel2TradingAmount                    : Sample(22),
      totalBidLevel2Price                       : Sample(11),
      totalBidLevel2RemainingQuantity           : Sample(15),
      bidLevel2IncludingGc                      : Sample(1),
      askPerTypeLevel2Price                     : Sample(11),
      bidPerTypeLevel2Price                     : Sample(11),
      askPerTypeLevel2RemainingQuantity         : Sample(15),
      bidPerTypeLevel2RemainingQuantity         : Sample(15),
      askPerTypeLevel2TradingAmount             : Sample(22),
      askLevel3Price                            : Sample(11),
      bidLevel3Price                            : Sample(11),
      askLevel3RemainingQuantity                : Sample(15),
      bidLevel3RemainingQuantity                : Sample(15),
      askLevel3TradingAmount                    : Sample(22),
      totalBidLevel3Price                       : Sample(11),
      totalBidLevel3RemainingQuantity           : Sample(15),
      bidLevel3IncludingGc                      : Sample(1),
      askPerTypeLevel3Price                     : Sample(11),
      bidPerTypeLevel3Price                     : Sample(11),
      askPerTypeLevel3RemainingQuantity         : Sample(15),
      bidPerTypeLevel3RemainingQuantity         : Sample(15),
      askPerTypeLevel3TradingAmount             : Sample(22),
      askLevel4Price                            : Sample(11),
      bidLevel4Price                            : Sample(11),
      askLevel4RemainingQuantity                : Sample(15),
      bidLevel4RemainingQuantity                : Sample(15),
      askLevel4TradingAmount                    : Sample(22),
      totalBidLevel4Price                       : Sample(11),
      totalBidLevel4RemainingQuantity           : Sample(15),
      bidLevel4IncludingGc                      : Sample(1),
      askPerTypeLevel4Price                     : Sample(11),
      bidPerTypeLevel4Price                     : Sample(11),
      askPerTypeLevel4RemainingQuantity         : Sample(15),
      bidPerTypeLevel4RemainingQuantity         : Sample(15),
      askPerTypeLevel4TradingAmount             : Sample(22),
      askLevel5Price                            : Sample(11),
      bidLevel5Price                            : Sample(11),
      askLevel5RemainingQuantity                : Sample(15),
      bidLevel5RemainingQuantity                : Sample(15),
      askLevel5TradingAmount                    : Sample(22),
      totalBidLevel5Price                       : Sample(11),
      totalBidLevel5RemainingQuantity           : Sample(15),
      bidLevel5IncludingGc                      : Sample(1),
      askPerTypeLevel5Price                     : Sample(11),
      bidPerTypeLevel5Price                     : Sample(11),
      askPerTypeLevel5RemainingQuantity         : Sample(15),
      bidPerTypeLevel5RemainingQuantity         : Sample(15),
      askPerTypeLevel5TradingAmount             : Sample(22),
      askTotalRemainingQuantity                 : Sample(15),
      bidTotalRemainingQuantity                 : Sample(15),
      askPerTypeTotalRemainingQuantity          : Sample(15),
      bidPerTypeTotalRemainingQuantity          : Sample(15),
      designatedBidLevel1Price                  : Sample(11),
      designatedBidLevel1RepoRemainingQuantity  : Sample(15),
      designatedBidLevel1Isin                   : Sample(12),
      designatedBidLevel2Price                  : Sample(11),
      designatedBidLevel2RepoRemainingQuantity  : Sample(15),
      designatedBidLevel2Isin                   : Sample(12),
      designatedBidLevel3Price                  : Sample(11),
      designatedBidLevel3RepoRemainingQuantity  : Sample(15),
      designatedBidLevel3Isin                   : Sample(12),
      designatedBidLevel4Price                  : Sample(11),
      designatedBidLevel4RepoRemainingQuantity  : Sample(15),
      designatedBidLevel4Isin                   : Sample(12),
      designatedBidLevel5Price                  : Sample(11),
      designatedBidLevel5RepoRemainingQuantity  : Sample(15),
      designatedBidLevel5Isin                   : Sample(12),
      designatedBidLevel6Price                  : Sample(11),
      designatedBidLevel6RepoRemainingQuantity  : Sample(15),
      designatedBidLevel6Isin                   : Sample(12),
      designatedBidLevel7Price                  : Sample(11),
      designatedBidLevel7RepoRemainingQuantity  : Sample(15),
      designatedBidLevel7Isin                   : Sample(12),
      designatedBidLevel8Price                  : Sample(11),
      designatedBidLevel8RepoRemainingQuantity  : Sample(15),
      designatedBidLevel8Isin                   : Sample(12),
      designatedBidLevel9Price                  : Sample(11),
      designatedBidLevel9RepoRemainingQuantity  : Sample(15),
      designatedBidLevel9Isin                   : Sample(12),
      designatedBidLevel10Price                 : Sample(11),
      designatedBidLevel10RepoRemainingQuantity : Sample(15),
      designatedBidLevel10Isin                  : Sample(12),
      designatedBestBidPrice                    : Sample(11),
      netBidPerTypeTotalRemainingQuantity       : Sample(15),
      endKeyword                                : Sample(1) ]

EncodeRepoQuoteMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.sessionId
        \o message.isinCode
        \o message.processingTimeOfTradingSystem
        \o message.durationOfTermRepo
        \o message.askLevel1Price
        \o message.bidLevel1Price
        \o message.askLevel1RemainingQuantity
        \o message.bidLevel1RemainingQuantity
        \o message.askLevel1TradingAmount
        \o message.totalBidLevel1Price
        \o message.totalBidLevel1RemainingQuantity
        \o message.bidLevel1IncludingGc
        \o message.askPerTypeLevel1Price
        \o message.bidPerTypeLevel1Price
        \o message.askPerTypeLevel1RemainingQuantity
        \o message.bidPerTypeLevel1RemainingQuantity
        \o message.askPerTypeLevel1TradingAmount
        \o message.askLevel2Price
        \o message.bidLevel2Price
        \o message.askLevel2RemainingQuantity
        \o message.bidLevel2RemainingQuantity
        \o message.askLevel2TradingAmount
        \o message.totalBidLevel2Price
        \o message.totalBidLevel2RemainingQuantity
        \o message.bidLevel2IncludingGc
        \o message.askPerTypeLevel2Price
        \o message.bidPerTypeLevel2Price
        \o message.askPerTypeLevel2RemainingQuantity
        \o message.bidPerTypeLevel2RemainingQuantity
        \o message.askPerTypeLevel2TradingAmount
        \o message.askLevel3Price
        \o message.bidLevel3Price
        \o message.askLevel3RemainingQuantity
        \o message.bidLevel3RemainingQuantity
        \o message.askLevel3TradingAmount
        \o message.totalBidLevel3Price
        \o message.totalBidLevel3RemainingQuantity
        \o message.bidLevel3IncludingGc
        \o message.askPerTypeLevel3Price
        \o message.bidPerTypeLevel3Price
        \o message.askPerTypeLevel3RemainingQuantity
        \o message.bidPerTypeLevel3RemainingQuantity
        \o message.askPerTypeLevel3TradingAmount
        \o message.askLevel4Price
        \o message.bidLevel4Price
        \o message.askLevel4RemainingQuantity
        \o message.bidLevel4RemainingQuantity
        \o message.askLevel4TradingAmount
        \o message.totalBidLevel4Price
        \o message.totalBidLevel4RemainingQuantity
        \o message.bidLevel4IncludingGc
        \o message.askPerTypeLevel4Price
        \o message.bidPerTypeLevel4Price
        \o message.askPerTypeLevel4RemainingQuantity
        \o message.bidPerTypeLevel4RemainingQuantity
        \o message.askPerTypeLevel4TradingAmount
        \o message.askLevel5Price
        \o message.bidLevel5Price
        \o message.askLevel5RemainingQuantity
        \o message.bidLevel5RemainingQuantity
        \o message.askLevel5TradingAmount
        \o message.totalBidLevel5Price
        \o message.totalBidLevel5RemainingQuantity
        \o message.bidLevel5IncludingGc
        \o message.askPerTypeLevel5Price
        \o message.bidPerTypeLevel5Price
        \o message.askPerTypeLevel5RemainingQuantity
        \o message.bidPerTypeLevel5RemainingQuantity
        \o message.askPerTypeLevel5TradingAmount
        \o message.askTotalRemainingQuantity
        \o message.bidTotalRemainingQuantity
        \o message.askPerTypeTotalRemainingQuantity
        \o message.bidPerTypeTotalRemainingQuantity
        \o message.designatedBidLevel1Price
        \o message.designatedBidLevel1RepoRemainingQuantity
        \o message.designatedBidLevel1Isin
        \o message.designatedBidLevel2Price
        \o message.designatedBidLevel2RepoRemainingQuantity
        \o message.designatedBidLevel2Isin
        \o message.designatedBidLevel3Price
        \o message.designatedBidLevel3RepoRemainingQuantity
        \o message.designatedBidLevel3Isin
        \o message.designatedBidLevel4Price
        \o message.designatedBidLevel4RepoRemainingQuantity
        \o message.designatedBidLevel4Isin
        \o message.designatedBidLevel5Price
        \o message.designatedBidLevel5RepoRemainingQuantity
        \o message.designatedBidLevel5Isin
        \o message.designatedBidLevel6Price
        \o message.designatedBidLevel6RepoRemainingQuantity
        \o message.designatedBidLevel6Isin
        \o message.designatedBidLevel7Price
        \o message.designatedBidLevel7RepoRemainingQuantity
        \o message.designatedBidLevel7Isin
        \o message.designatedBidLevel8Price
        \o message.designatedBidLevel8RepoRemainingQuantity
        \o message.designatedBidLevel8Isin
        \o message.designatedBidLevel9Price
        \o message.designatedBidLevel9RepoRemainingQuantity
        \o message.designatedBidLevel9Isin
        \o message.designatedBidLevel10Price
        \o message.designatedBidLevel10RepoRemainingQuantity
        \o message.designatedBidLevel10Isin
        \o message.designatedBestBidPrice
        \o message.netBidPerTypeTotalRemainingQuantity
        \o message.endKeyword

DecodeRepoQuoteMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(boardId.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(sessionId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET processingTimeOfTradingSystem == ReadBytes(isinCode.rest, 12) IN IF ~processingTimeOfTradingSystem.ok THEN Fail ELSE
    LET durationOfTermRepo == ReadBytes(processingTimeOfTradingSystem.rest, 4) IN IF ~durationOfTermRepo.ok THEN Fail ELSE
    LET askLevel1Price == ReadBytes(durationOfTermRepo.rest, 11) IN IF ~askLevel1Price.ok THEN Fail ELSE
    LET bidLevel1Price == ReadBytes(askLevel1Price.rest, 11) IN IF ~bidLevel1Price.ok THEN Fail ELSE
    LET askLevel1RemainingQuantity == ReadBytes(bidLevel1Price.rest, 15) IN IF ~askLevel1RemainingQuantity.ok THEN Fail ELSE
    LET bidLevel1RemainingQuantity == ReadBytes(askLevel1RemainingQuantity.rest, 15) IN IF ~bidLevel1RemainingQuantity.ok THEN Fail ELSE
    LET askLevel1TradingAmount == ReadBytes(bidLevel1RemainingQuantity.rest, 22) IN IF ~askLevel1TradingAmount.ok THEN Fail ELSE
    LET totalBidLevel1Price == ReadBytes(askLevel1TradingAmount.rest, 11) IN IF ~totalBidLevel1Price.ok THEN Fail ELSE
    LET totalBidLevel1RemainingQuantity == ReadBytes(totalBidLevel1Price.rest, 15) IN IF ~totalBidLevel1RemainingQuantity.ok THEN Fail ELSE
    LET bidLevel1IncludingGc == ReadBytes(totalBidLevel1RemainingQuantity.rest, 1) IN IF ~bidLevel1IncludingGc.ok THEN Fail ELSE
    LET askPerTypeLevel1Price == ReadBytes(bidLevel1IncludingGc.rest, 11) IN IF ~askPerTypeLevel1Price.ok THEN Fail ELSE
    LET bidPerTypeLevel1Price == ReadBytes(askPerTypeLevel1Price.rest, 11) IN IF ~bidPerTypeLevel1Price.ok THEN Fail ELSE
    LET askPerTypeLevel1RemainingQuantity == ReadBytes(bidPerTypeLevel1Price.rest, 15) IN IF ~askPerTypeLevel1RemainingQuantity.ok THEN Fail ELSE
    LET bidPerTypeLevel1RemainingQuantity == ReadBytes(askPerTypeLevel1RemainingQuantity.rest, 15) IN IF ~bidPerTypeLevel1RemainingQuantity.ok THEN Fail ELSE
    LET askPerTypeLevel1TradingAmount == ReadBytes(bidPerTypeLevel1RemainingQuantity.rest, 22) IN IF ~askPerTypeLevel1TradingAmount.ok THEN Fail ELSE
    LET askLevel2Price == ReadBytes(askPerTypeLevel1TradingAmount.rest, 11) IN IF ~askLevel2Price.ok THEN Fail ELSE
    LET bidLevel2Price == ReadBytes(askLevel2Price.rest, 11) IN IF ~bidLevel2Price.ok THEN Fail ELSE
    LET askLevel2RemainingQuantity == ReadBytes(bidLevel2Price.rest, 15) IN IF ~askLevel2RemainingQuantity.ok THEN Fail ELSE
    LET bidLevel2RemainingQuantity == ReadBytes(askLevel2RemainingQuantity.rest, 15) IN IF ~bidLevel2RemainingQuantity.ok THEN Fail ELSE
    LET askLevel2TradingAmount == ReadBytes(bidLevel2RemainingQuantity.rest, 22) IN IF ~askLevel2TradingAmount.ok THEN Fail ELSE
    LET totalBidLevel2Price == ReadBytes(askLevel2TradingAmount.rest, 11) IN IF ~totalBidLevel2Price.ok THEN Fail ELSE
    LET totalBidLevel2RemainingQuantity == ReadBytes(totalBidLevel2Price.rest, 15) IN IF ~totalBidLevel2RemainingQuantity.ok THEN Fail ELSE
    LET bidLevel2IncludingGc == ReadBytes(totalBidLevel2RemainingQuantity.rest, 1) IN IF ~bidLevel2IncludingGc.ok THEN Fail ELSE
    LET askPerTypeLevel2Price == ReadBytes(bidLevel2IncludingGc.rest, 11) IN IF ~askPerTypeLevel2Price.ok THEN Fail ELSE
    LET bidPerTypeLevel2Price == ReadBytes(askPerTypeLevel2Price.rest, 11) IN IF ~bidPerTypeLevel2Price.ok THEN Fail ELSE
    LET askPerTypeLevel2RemainingQuantity == ReadBytes(bidPerTypeLevel2Price.rest, 15) IN IF ~askPerTypeLevel2RemainingQuantity.ok THEN Fail ELSE
    LET bidPerTypeLevel2RemainingQuantity == ReadBytes(askPerTypeLevel2RemainingQuantity.rest, 15) IN IF ~bidPerTypeLevel2RemainingQuantity.ok THEN Fail ELSE
    LET askPerTypeLevel2TradingAmount == ReadBytes(bidPerTypeLevel2RemainingQuantity.rest, 22) IN IF ~askPerTypeLevel2TradingAmount.ok THEN Fail ELSE
    LET askLevel3Price == ReadBytes(askPerTypeLevel2TradingAmount.rest, 11) IN IF ~askLevel3Price.ok THEN Fail ELSE
    LET bidLevel3Price == ReadBytes(askLevel3Price.rest, 11) IN IF ~bidLevel3Price.ok THEN Fail ELSE
    LET askLevel3RemainingQuantity == ReadBytes(bidLevel3Price.rest, 15) IN IF ~askLevel3RemainingQuantity.ok THEN Fail ELSE
    LET bidLevel3RemainingQuantity == ReadBytes(askLevel3RemainingQuantity.rest, 15) IN IF ~bidLevel3RemainingQuantity.ok THEN Fail ELSE
    LET askLevel3TradingAmount == ReadBytes(bidLevel3RemainingQuantity.rest, 22) IN IF ~askLevel3TradingAmount.ok THEN Fail ELSE
    LET totalBidLevel3Price == ReadBytes(askLevel3TradingAmount.rest, 11) IN IF ~totalBidLevel3Price.ok THEN Fail ELSE
    LET totalBidLevel3RemainingQuantity == ReadBytes(totalBidLevel3Price.rest, 15) IN IF ~totalBidLevel3RemainingQuantity.ok THEN Fail ELSE
    LET bidLevel3IncludingGc == ReadBytes(totalBidLevel3RemainingQuantity.rest, 1) IN IF ~bidLevel3IncludingGc.ok THEN Fail ELSE
    LET askPerTypeLevel3Price == ReadBytes(bidLevel3IncludingGc.rest, 11) IN IF ~askPerTypeLevel3Price.ok THEN Fail ELSE
    LET bidPerTypeLevel3Price == ReadBytes(askPerTypeLevel3Price.rest, 11) IN IF ~bidPerTypeLevel3Price.ok THEN Fail ELSE
    LET askPerTypeLevel3RemainingQuantity == ReadBytes(bidPerTypeLevel3Price.rest, 15) IN IF ~askPerTypeLevel3RemainingQuantity.ok THEN Fail ELSE
    LET bidPerTypeLevel3RemainingQuantity == ReadBytes(askPerTypeLevel3RemainingQuantity.rest, 15) IN IF ~bidPerTypeLevel3RemainingQuantity.ok THEN Fail ELSE
    LET askPerTypeLevel3TradingAmount == ReadBytes(bidPerTypeLevel3RemainingQuantity.rest, 22) IN IF ~askPerTypeLevel3TradingAmount.ok THEN Fail ELSE
    LET askLevel4Price == ReadBytes(askPerTypeLevel3TradingAmount.rest, 11) IN IF ~askLevel4Price.ok THEN Fail ELSE
    LET bidLevel4Price == ReadBytes(askLevel4Price.rest, 11) IN IF ~bidLevel4Price.ok THEN Fail ELSE
    LET askLevel4RemainingQuantity == ReadBytes(bidLevel4Price.rest, 15) IN IF ~askLevel4RemainingQuantity.ok THEN Fail ELSE
    LET bidLevel4RemainingQuantity == ReadBytes(askLevel4RemainingQuantity.rest, 15) IN IF ~bidLevel4RemainingQuantity.ok THEN Fail ELSE
    LET askLevel4TradingAmount == ReadBytes(bidLevel4RemainingQuantity.rest, 22) IN IF ~askLevel4TradingAmount.ok THEN Fail ELSE
    LET totalBidLevel4Price == ReadBytes(askLevel4TradingAmount.rest, 11) IN IF ~totalBidLevel4Price.ok THEN Fail ELSE
    LET totalBidLevel4RemainingQuantity == ReadBytes(totalBidLevel4Price.rest, 15) IN IF ~totalBidLevel4RemainingQuantity.ok THEN Fail ELSE
    LET bidLevel4IncludingGc == ReadBytes(totalBidLevel4RemainingQuantity.rest, 1) IN IF ~bidLevel4IncludingGc.ok THEN Fail ELSE
    LET askPerTypeLevel4Price == ReadBytes(bidLevel4IncludingGc.rest, 11) IN IF ~askPerTypeLevel4Price.ok THEN Fail ELSE
    LET bidPerTypeLevel4Price == ReadBytes(askPerTypeLevel4Price.rest, 11) IN IF ~bidPerTypeLevel4Price.ok THEN Fail ELSE
    LET askPerTypeLevel4RemainingQuantity == ReadBytes(bidPerTypeLevel4Price.rest, 15) IN IF ~askPerTypeLevel4RemainingQuantity.ok THEN Fail ELSE
    LET bidPerTypeLevel4RemainingQuantity == ReadBytes(askPerTypeLevel4RemainingQuantity.rest, 15) IN IF ~bidPerTypeLevel4RemainingQuantity.ok THEN Fail ELSE
    LET askPerTypeLevel4TradingAmount == ReadBytes(bidPerTypeLevel4RemainingQuantity.rest, 22) IN IF ~askPerTypeLevel4TradingAmount.ok THEN Fail ELSE
    LET askLevel5Price == ReadBytes(askPerTypeLevel4TradingAmount.rest, 11) IN IF ~askLevel5Price.ok THEN Fail ELSE
    LET bidLevel5Price == ReadBytes(askLevel5Price.rest, 11) IN IF ~bidLevel5Price.ok THEN Fail ELSE
    LET askLevel5RemainingQuantity == ReadBytes(bidLevel5Price.rest, 15) IN IF ~askLevel5RemainingQuantity.ok THEN Fail ELSE
    LET bidLevel5RemainingQuantity == ReadBytes(askLevel5RemainingQuantity.rest, 15) IN IF ~bidLevel5RemainingQuantity.ok THEN Fail ELSE
    LET askLevel5TradingAmount == ReadBytes(bidLevel5RemainingQuantity.rest, 22) IN IF ~askLevel5TradingAmount.ok THEN Fail ELSE
    LET totalBidLevel5Price == ReadBytes(askLevel5TradingAmount.rest, 11) IN IF ~totalBidLevel5Price.ok THEN Fail ELSE
    LET totalBidLevel5RemainingQuantity == ReadBytes(totalBidLevel5Price.rest, 15) IN IF ~totalBidLevel5RemainingQuantity.ok THEN Fail ELSE
    LET bidLevel5IncludingGc == ReadBytes(totalBidLevel5RemainingQuantity.rest, 1) IN IF ~bidLevel5IncludingGc.ok THEN Fail ELSE
    LET askPerTypeLevel5Price == ReadBytes(bidLevel5IncludingGc.rest, 11) IN IF ~askPerTypeLevel5Price.ok THEN Fail ELSE
    LET bidPerTypeLevel5Price == ReadBytes(askPerTypeLevel5Price.rest, 11) IN IF ~bidPerTypeLevel5Price.ok THEN Fail ELSE
    LET askPerTypeLevel5RemainingQuantity == ReadBytes(bidPerTypeLevel5Price.rest, 15) IN IF ~askPerTypeLevel5RemainingQuantity.ok THEN Fail ELSE
    LET bidPerTypeLevel5RemainingQuantity == ReadBytes(askPerTypeLevel5RemainingQuantity.rest, 15) IN IF ~bidPerTypeLevel5RemainingQuantity.ok THEN Fail ELSE
    LET askPerTypeLevel5TradingAmount == ReadBytes(bidPerTypeLevel5RemainingQuantity.rest, 22) IN IF ~askPerTypeLevel5TradingAmount.ok THEN Fail ELSE
    LET askTotalRemainingQuantity == ReadBytes(askPerTypeLevel5TradingAmount.rest, 15) IN IF ~askTotalRemainingQuantity.ok THEN Fail ELSE
    LET bidTotalRemainingQuantity == ReadBytes(askTotalRemainingQuantity.rest, 15) IN IF ~bidTotalRemainingQuantity.ok THEN Fail ELSE
    LET askPerTypeTotalRemainingQuantity == ReadBytes(bidTotalRemainingQuantity.rest, 15) IN IF ~askPerTypeTotalRemainingQuantity.ok THEN Fail ELSE
    LET bidPerTypeTotalRemainingQuantity == ReadBytes(askPerTypeTotalRemainingQuantity.rest, 15) IN IF ~bidPerTypeTotalRemainingQuantity.ok THEN Fail ELSE
    LET designatedBidLevel1Price == ReadBytes(bidPerTypeTotalRemainingQuantity.rest, 11) IN IF ~designatedBidLevel1Price.ok THEN Fail ELSE
    LET designatedBidLevel1RepoRemainingQuantity == ReadBytes(designatedBidLevel1Price.rest, 15) IN IF ~designatedBidLevel1RepoRemainingQuantity.ok THEN Fail ELSE
    LET designatedBidLevel1Isin == ReadBytes(designatedBidLevel1RepoRemainingQuantity.rest, 12) IN IF ~designatedBidLevel1Isin.ok THEN Fail ELSE
    LET designatedBidLevel2Price == ReadBytes(designatedBidLevel1Isin.rest, 11) IN IF ~designatedBidLevel2Price.ok THEN Fail ELSE
    LET designatedBidLevel2RepoRemainingQuantity == ReadBytes(designatedBidLevel2Price.rest, 15) IN IF ~designatedBidLevel2RepoRemainingQuantity.ok THEN Fail ELSE
    LET designatedBidLevel2Isin == ReadBytes(designatedBidLevel2RepoRemainingQuantity.rest, 12) IN IF ~designatedBidLevel2Isin.ok THEN Fail ELSE
    LET designatedBidLevel3Price == ReadBytes(designatedBidLevel2Isin.rest, 11) IN IF ~designatedBidLevel3Price.ok THEN Fail ELSE
    LET designatedBidLevel3RepoRemainingQuantity == ReadBytes(designatedBidLevel3Price.rest, 15) IN IF ~designatedBidLevel3RepoRemainingQuantity.ok THEN Fail ELSE
    LET designatedBidLevel3Isin == ReadBytes(designatedBidLevel3RepoRemainingQuantity.rest, 12) IN IF ~designatedBidLevel3Isin.ok THEN Fail ELSE
    LET designatedBidLevel4Price == ReadBytes(designatedBidLevel3Isin.rest, 11) IN IF ~designatedBidLevel4Price.ok THEN Fail ELSE
    LET designatedBidLevel4RepoRemainingQuantity == ReadBytes(designatedBidLevel4Price.rest, 15) IN IF ~designatedBidLevel4RepoRemainingQuantity.ok THEN Fail ELSE
    LET designatedBidLevel4Isin == ReadBytes(designatedBidLevel4RepoRemainingQuantity.rest, 12) IN IF ~designatedBidLevel4Isin.ok THEN Fail ELSE
    LET designatedBidLevel5Price == ReadBytes(designatedBidLevel4Isin.rest, 11) IN IF ~designatedBidLevel5Price.ok THEN Fail ELSE
    LET designatedBidLevel5RepoRemainingQuantity == ReadBytes(designatedBidLevel5Price.rest, 15) IN IF ~designatedBidLevel5RepoRemainingQuantity.ok THEN Fail ELSE
    LET designatedBidLevel5Isin == ReadBytes(designatedBidLevel5RepoRemainingQuantity.rest, 12) IN IF ~designatedBidLevel5Isin.ok THEN Fail ELSE
    LET designatedBidLevel6Price == ReadBytes(designatedBidLevel5Isin.rest, 11) IN IF ~designatedBidLevel6Price.ok THEN Fail ELSE
    LET designatedBidLevel6RepoRemainingQuantity == ReadBytes(designatedBidLevel6Price.rest, 15) IN IF ~designatedBidLevel6RepoRemainingQuantity.ok THEN Fail ELSE
    LET designatedBidLevel6Isin == ReadBytes(designatedBidLevel6RepoRemainingQuantity.rest, 12) IN IF ~designatedBidLevel6Isin.ok THEN Fail ELSE
    LET designatedBidLevel7Price == ReadBytes(designatedBidLevel6Isin.rest, 11) IN IF ~designatedBidLevel7Price.ok THEN Fail ELSE
    LET designatedBidLevel7RepoRemainingQuantity == ReadBytes(designatedBidLevel7Price.rest, 15) IN IF ~designatedBidLevel7RepoRemainingQuantity.ok THEN Fail ELSE
    LET designatedBidLevel7Isin == ReadBytes(designatedBidLevel7RepoRemainingQuantity.rest, 12) IN IF ~designatedBidLevel7Isin.ok THEN Fail ELSE
    LET designatedBidLevel8Price == ReadBytes(designatedBidLevel7Isin.rest, 11) IN IF ~designatedBidLevel8Price.ok THEN Fail ELSE
    LET designatedBidLevel8RepoRemainingQuantity == ReadBytes(designatedBidLevel8Price.rest, 15) IN IF ~designatedBidLevel8RepoRemainingQuantity.ok THEN Fail ELSE
    LET designatedBidLevel8Isin == ReadBytes(designatedBidLevel8RepoRemainingQuantity.rest, 12) IN IF ~designatedBidLevel8Isin.ok THEN Fail ELSE
    LET designatedBidLevel9Price == ReadBytes(designatedBidLevel8Isin.rest, 11) IN IF ~designatedBidLevel9Price.ok THEN Fail ELSE
    LET designatedBidLevel9RepoRemainingQuantity == ReadBytes(designatedBidLevel9Price.rest, 15) IN IF ~designatedBidLevel9RepoRemainingQuantity.ok THEN Fail ELSE
    LET designatedBidLevel9Isin == ReadBytes(designatedBidLevel9RepoRemainingQuantity.rest, 12) IN IF ~designatedBidLevel9Isin.ok THEN Fail ELSE
    LET designatedBidLevel10Price == ReadBytes(designatedBidLevel9Isin.rest, 11) IN IF ~designatedBidLevel10Price.ok THEN Fail ELSE
    LET designatedBidLevel10RepoRemainingQuantity == ReadBytes(designatedBidLevel10Price.rest, 15) IN IF ~designatedBidLevel10RepoRemainingQuantity.ok THEN Fail ELSE
    LET designatedBidLevel10Isin == ReadBytes(designatedBidLevel10RepoRemainingQuantity.rest, 12) IN IF ~designatedBidLevel10Isin.ok THEN Fail ELSE
    LET designatedBestBidPrice == ReadBytes(designatedBidLevel10Isin.rest, 11) IN IF ~designatedBestBidPrice.ok THEN Fail ELSE
    LET netBidPerTypeTotalRemainingQuantity == ReadBytes(designatedBestBidPrice.rest, 15) IN IF ~netBidPerTypeTotalRemainingQuantity.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(netBidPerTypeTotalRemainingQuantity.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber                     |-> messageSequenceNumber.value,
         boardId                                   |-> boardId.value,
         sessionId                                 |-> sessionId.value,
         isinCode                                  |-> isinCode.value,
         processingTimeOfTradingSystem             |-> processingTimeOfTradingSystem.value,
         durationOfTermRepo                        |-> durationOfTermRepo.value,
         askLevel1Price                            |-> askLevel1Price.value,
         bidLevel1Price                            |-> bidLevel1Price.value,
         askLevel1RemainingQuantity                |-> askLevel1RemainingQuantity.value,
         bidLevel1RemainingQuantity                |-> bidLevel1RemainingQuantity.value,
         askLevel1TradingAmount                    |-> askLevel1TradingAmount.value,
         totalBidLevel1Price                       |-> totalBidLevel1Price.value,
         totalBidLevel1RemainingQuantity           |-> totalBidLevel1RemainingQuantity.value,
         bidLevel1IncludingGc                      |-> bidLevel1IncludingGc.value,
         askPerTypeLevel1Price                     |-> askPerTypeLevel1Price.value,
         bidPerTypeLevel1Price                     |-> bidPerTypeLevel1Price.value,
         askPerTypeLevel1RemainingQuantity         |-> askPerTypeLevel1RemainingQuantity.value,
         bidPerTypeLevel1RemainingQuantity         |-> bidPerTypeLevel1RemainingQuantity.value,
         askPerTypeLevel1TradingAmount             |-> askPerTypeLevel1TradingAmount.value,
         askLevel2Price                            |-> askLevel2Price.value,
         bidLevel2Price                            |-> bidLevel2Price.value,
         askLevel2RemainingQuantity                |-> askLevel2RemainingQuantity.value,
         bidLevel2RemainingQuantity                |-> bidLevel2RemainingQuantity.value,
         askLevel2TradingAmount                    |-> askLevel2TradingAmount.value,
         totalBidLevel2Price                       |-> totalBidLevel2Price.value,
         totalBidLevel2RemainingQuantity           |-> totalBidLevel2RemainingQuantity.value,
         bidLevel2IncludingGc                      |-> bidLevel2IncludingGc.value,
         askPerTypeLevel2Price                     |-> askPerTypeLevel2Price.value,
         bidPerTypeLevel2Price                     |-> bidPerTypeLevel2Price.value,
         askPerTypeLevel2RemainingQuantity         |-> askPerTypeLevel2RemainingQuantity.value,
         bidPerTypeLevel2RemainingQuantity         |-> bidPerTypeLevel2RemainingQuantity.value,
         askPerTypeLevel2TradingAmount             |-> askPerTypeLevel2TradingAmount.value,
         askLevel3Price                            |-> askLevel3Price.value,
         bidLevel3Price                            |-> bidLevel3Price.value,
         askLevel3RemainingQuantity                |-> askLevel3RemainingQuantity.value,
         bidLevel3RemainingQuantity                |-> bidLevel3RemainingQuantity.value,
         askLevel3TradingAmount                    |-> askLevel3TradingAmount.value,
         totalBidLevel3Price                       |-> totalBidLevel3Price.value,
         totalBidLevel3RemainingQuantity           |-> totalBidLevel3RemainingQuantity.value,
         bidLevel3IncludingGc                      |-> bidLevel3IncludingGc.value,
         askPerTypeLevel3Price                     |-> askPerTypeLevel3Price.value,
         bidPerTypeLevel3Price                     |-> bidPerTypeLevel3Price.value,
         askPerTypeLevel3RemainingQuantity         |-> askPerTypeLevel3RemainingQuantity.value,
         bidPerTypeLevel3RemainingQuantity         |-> bidPerTypeLevel3RemainingQuantity.value,
         askPerTypeLevel3TradingAmount             |-> askPerTypeLevel3TradingAmount.value,
         askLevel4Price                            |-> askLevel4Price.value,
         bidLevel4Price                            |-> bidLevel4Price.value,
         askLevel4RemainingQuantity                |-> askLevel4RemainingQuantity.value,
         bidLevel4RemainingQuantity                |-> bidLevel4RemainingQuantity.value,
         askLevel4TradingAmount                    |-> askLevel4TradingAmount.value,
         totalBidLevel4Price                       |-> totalBidLevel4Price.value,
         totalBidLevel4RemainingQuantity           |-> totalBidLevel4RemainingQuantity.value,
         bidLevel4IncludingGc                      |-> bidLevel4IncludingGc.value,
         askPerTypeLevel4Price                     |-> askPerTypeLevel4Price.value,
         bidPerTypeLevel4Price                     |-> bidPerTypeLevel4Price.value,
         askPerTypeLevel4RemainingQuantity         |-> askPerTypeLevel4RemainingQuantity.value,
         bidPerTypeLevel4RemainingQuantity         |-> bidPerTypeLevel4RemainingQuantity.value,
         askPerTypeLevel4TradingAmount             |-> askPerTypeLevel4TradingAmount.value,
         askLevel5Price                            |-> askLevel5Price.value,
         bidLevel5Price                            |-> bidLevel5Price.value,
         askLevel5RemainingQuantity                |-> askLevel5RemainingQuantity.value,
         bidLevel5RemainingQuantity                |-> bidLevel5RemainingQuantity.value,
         askLevel5TradingAmount                    |-> askLevel5TradingAmount.value,
         totalBidLevel5Price                       |-> totalBidLevel5Price.value,
         totalBidLevel5RemainingQuantity           |-> totalBidLevel5RemainingQuantity.value,
         bidLevel5IncludingGc                      |-> bidLevel5IncludingGc.value,
         askPerTypeLevel5Price                     |-> askPerTypeLevel5Price.value,
         bidPerTypeLevel5Price                     |-> bidPerTypeLevel5Price.value,
         askPerTypeLevel5RemainingQuantity         |-> askPerTypeLevel5RemainingQuantity.value,
         bidPerTypeLevel5RemainingQuantity         |-> bidPerTypeLevel5RemainingQuantity.value,
         askPerTypeLevel5TradingAmount             |-> askPerTypeLevel5TradingAmount.value,
         askTotalRemainingQuantity                 |-> askTotalRemainingQuantity.value,
         bidTotalRemainingQuantity                 |-> bidTotalRemainingQuantity.value,
         askPerTypeTotalRemainingQuantity          |-> askPerTypeTotalRemainingQuantity.value,
         bidPerTypeTotalRemainingQuantity          |-> bidPerTypeTotalRemainingQuantity.value,
         designatedBidLevel1Price                  |-> designatedBidLevel1Price.value,
         designatedBidLevel1RepoRemainingQuantity  |-> designatedBidLevel1RepoRemainingQuantity.value,
         designatedBidLevel1Isin                   |-> designatedBidLevel1Isin.value,
         designatedBidLevel2Price                  |-> designatedBidLevel2Price.value,
         designatedBidLevel2RepoRemainingQuantity  |-> designatedBidLevel2RepoRemainingQuantity.value,
         designatedBidLevel2Isin                   |-> designatedBidLevel2Isin.value,
         designatedBidLevel3Price                  |-> designatedBidLevel3Price.value,
         designatedBidLevel3RepoRemainingQuantity  |-> designatedBidLevel3RepoRemainingQuantity.value,
         designatedBidLevel3Isin                   |-> designatedBidLevel3Isin.value,
         designatedBidLevel4Price                  |-> designatedBidLevel4Price.value,
         designatedBidLevel4RepoRemainingQuantity  |-> designatedBidLevel4RepoRemainingQuantity.value,
         designatedBidLevel4Isin                   |-> designatedBidLevel4Isin.value,
         designatedBidLevel5Price                  |-> designatedBidLevel5Price.value,
         designatedBidLevel5RepoRemainingQuantity  |-> designatedBidLevel5RepoRemainingQuantity.value,
         designatedBidLevel5Isin                   |-> designatedBidLevel5Isin.value,
         designatedBidLevel6Price                  |-> designatedBidLevel6Price.value,
         designatedBidLevel6RepoRemainingQuantity  |-> designatedBidLevel6RepoRemainingQuantity.value,
         designatedBidLevel6Isin                   |-> designatedBidLevel6Isin.value,
         designatedBidLevel7Price                  |-> designatedBidLevel7Price.value,
         designatedBidLevel7RepoRemainingQuantity  |-> designatedBidLevel7RepoRemainingQuantity.value,
         designatedBidLevel7Isin                   |-> designatedBidLevel7Isin.value,
         designatedBidLevel8Price                  |-> designatedBidLevel8Price.value,
         designatedBidLevel8RepoRemainingQuantity  |-> designatedBidLevel8RepoRemainingQuantity.value,
         designatedBidLevel8Isin                   |-> designatedBidLevel8Isin.value,
         designatedBidLevel9Price                  |-> designatedBidLevel9Price.value,
         designatedBidLevel9RepoRemainingQuantity  |-> designatedBidLevel9RepoRemainingQuantity.value,
         designatedBidLevel9Isin                   |-> designatedBidLevel9Isin.value,
         designatedBidLevel10Price                 |-> designatedBidLevel10Price.value,
         designatedBidLevel10RepoRemainingQuantity |-> designatedBidLevel10RepoRemainingQuantity.value,
         designatedBidLevel10Isin                  |-> designatedBidLevel10Isin.value,
         designatedBestBidPrice                    |-> designatedBestBidPrice.value,
         netBidPerTypeTotalRemainingQuantity       |-> netBidPerTypeTotalRemainingQuantity.value,
         endKeyword                                |-> endKeyword.value ], endKeyword.rest)

ZeroRepoQuoteMessage ==
    [ messageSequenceNumber                     |-> [i \in 1 .. 8 |-> 0],
      boardId                                   |-> [i \in 1 .. 2 |-> 0],
      sessionId                                 |-> [i \in 1 .. 2 |-> 0],
      isinCode                                  |-> [i \in 1 .. 12 |-> 0],
      processingTimeOfTradingSystem             |-> [i \in 1 .. 12 |-> 0],
      durationOfTermRepo                        |-> [i \in 1 .. 4 |-> 0],
      askLevel1Price                            |-> [i \in 1 .. 11 |-> 0],
      bidLevel1Price                            |-> [i \in 1 .. 11 |-> 0],
      askLevel1RemainingQuantity                |-> [i \in 1 .. 15 |-> 0],
      bidLevel1RemainingQuantity                |-> [i \in 1 .. 15 |-> 0],
      askLevel1TradingAmount                    |-> [i \in 1 .. 22 |-> 0],
      totalBidLevel1Price                       |-> [i \in 1 .. 11 |-> 0],
      totalBidLevel1RemainingQuantity           |-> [i \in 1 .. 15 |-> 0],
      bidLevel1IncludingGc                      |-> [i \in 1 .. 1 |-> 0],
      askPerTypeLevel1Price                     |-> [i \in 1 .. 11 |-> 0],
      bidPerTypeLevel1Price                     |-> [i \in 1 .. 11 |-> 0],
      askPerTypeLevel1RemainingQuantity         |-> [i \in 1 .. 15 |-> 0],
      bidPerTypeLevel1RemainingQuantity         |-> [i \in 1 .. 15 |-> 0],
      askPerTypeLevel1TradingAmount             |-> [i \in 1 .. 22 |-> 0],
      askLevel2Price                            |-> [i \in 1 .. 11 |-> 0],
      bidLevel2Price                            |-> [i \in 1 .. 11 |-> 0],
      askLevel2RemainingQuantity                |-> [i \in 1 .. 15 |-> 0],
      bidLevel2RemainingQuantity                |-> [i \in 1 .. 15 |-> 0],
      askLevel2TradingAmount                    |-> [i \in 1 .. 22 |-> 0],
      totalBidLevel2Price                       |-> [i \in 1 .. 11 |-> 0],
      totalBidLevel2RemainingQuantity           |-> [i \in 1 .. 15 |-> 0],
      bidLevel2IncludingGc                      |-> [i \in 1 .. 1 |-> 0],
      askPerTypeLevel2Price                     |-> [i \in 1 .. 11 |-> 0],
      bidPerTypeLevel2Price                     |-> [i \in 1 .. 11 |-> 0],
      askPerTypeLevel2RemainingQuantity         |-> [i \in 1 .. 15 |-> 0],
      bidPerTypeLevel2RemainingQuantity         |-> [i \in 1 .. 15 |-> 0],
      askPerTypeLevel2TradingAmount             |-> [i \in 1 .. 22 |-> 0],
      askLevel3Price                            |-> [i \in 1 .. 11 |-> 0],
      bidLevel3Price                            |-> [i \in 1 .. 11 |-> 0],
      askLevel3RemainingQuantity                |-> [i \in 1 .. 15 |-> 0],
      bidLevel3RemainingQuantity                |-> [i \in 1 .. 15 |-> 0],
      askLevel3TradingAmount                    |-> [i \in 1 .. 22 |-> 0],
      totalBidLevel3Price                       |-> [i \in 1 .. 11 |-> 0],
      totalBidLevel3RemainingQuantity           |-> [i \in 1 .. 15 |-> 0],
      bidLevel3IncludingGc                      |-> [i \in 1 .. 1 |-> 0],
      askPerTypeLevel3Price                     |-> [i \in 1 .. 11 |-> 0],
      bidPerTypeLevel3Price                     |-> [i \in 1 .. 11 |-> 0],
      askPerTypeLevel3RemainingQuantity         |-> [i \in 1 .. 15 |-> 0],
      bidPerTypeLevel3RemainingQuantity         |-> [i \in 1 .. 15 |-> 0],
      askPerTypeLevel3TradingAmount             |-> [i \in 1 .. 22 |-> 0],
      askLevel4Price                            |-> [i \in 1 .. 11 |-> 0],
      bidLevel4Price                            |-> [i \in 1 .. 11 |-> 0],
      askLevel4RemainingQuantity                |-> [i \in 1 .. 15 |-> 0],
      bidLevel4RemainingQuantity                |-> [i \in 1 .. 15 |-> 0],
      askLevel4TradingAmount                    |-> [i \in 1 .. 22 |-> 0],
      totalBidLevel4Price                       |-> [i \in 1 .. 11 |-> 0],
      totalBidLevel4RemainingQuantity           |-> [i \in 1 .. 15 |-> 0],
      bidLevel4IncludingGc                      |-> [i \in 1 .. 1 |-> 0],
      askPerTypeLevel4Price                     |-> [i \in 1 .. 11 |-> 0],
      bidPerTypeLevel4Price                     |-> [i \in 1 .. 11 |-> 0],
      askPerTypeLevel4RemainingQuantity         |-> [i \in 1 .. 15 |-> 0],
      bidPerTypeLevel4RemainingQuantity         |-> [i \in 1 .. 15 |-> 0],
      askPerTypeLevel4TradingAmount             |-> [i \in 1 .. 22 |-> 0],
      askLevel5Price                            |-> [i \in 1 .. 11 |-> 0],
      bidLevel5Price                            |-> [i \in 1 .. 11 |-> 0],
      askLevel5RemainingQuantity                |-> [i \in 1 .. 15 |-> 0],
      bidLevel5RemainingQuantity                |-> [i \in 1 .. 15 |-> 0],
      askLevel5TradingAmount                    |-> [i \in 1 .. 22 |-> 0],
      totalBidLevel5Price                       |-> [i \in 1 .. 11 |-> 0],
      totalBidLevel5RemainingQuantity           |-> [i \in 1 .. 15 |-> 0],
      bidLevel5IncludingGc                      |-> [i \in 1 .. 1 |-> 0],
      askPerTypeLevel5Price                     |-> [i \in 1 .. 11 |-> 0],
      bidPerTypeLevel5Price                     |-> [i \in 1 .. 11 |-> 0],
      askPerTypeLevel5RemainingQuantity         |-> [i \in 1 .. 15 |-> 0],
      bidPerTypeLevel5RemainingQuantity         |-> [i \in 1 .. 15 |-> 0],
      askPerTypeLevel5TradingAmount             |-> [i \in 1 .. 22 |-> 0],
      askTotalRemainingQuantity                 |-> [i \in 1 .. 15 |-> 0],
      bidTotalRemainingQuantity                 |-> [i \in 1 .. 15 |-> 0],
      askPerTypeTotalRemainingQuantity          |-> [i \in 1 .. 15 |-> 0],
      bidPerTypeTotalRemainingQuantity          |-> [i \in 1 .. 15 |-> 0],
      designatedBidLevel1Price                  |-> [i \in 1 .. 11 |-> 0],
      designatedBidLevel1RepoRemainingQuantity  |-> [i \in 1 .. 15 |-> 0],
      designatedBidLevel1Isin                   |-> [i \in 1 .. 12 |-> 0],
      designatedBidLevel2Price                  |-> [i \in 1 .. 11 |-> 0],
      designatedBidLevel2RepoRemainingQuantity  |-> [i \in 1 .. 15 |-> 0],
      designatedBidLevel2Isin                   |-> [i \in 1 .. 12 |-> 0],
      designatedBidLevel3Price                  |-> [i \in 1 .. 11 |-> 0],
      designatedBidLevel3RepoRemainingQuantity  |-> [i \in 1 .. 15 |-> 0],
      designatedBidLevel3Isin                   |-> [i \in 1 .. 12 |-> 0],
      designatedBidLevel4Price                  |-> [i \in 1 .. 11 |-> 0],
      designatedBidLevel4RepoRemainingQuantity  |-> [i \in 1 .. 15 |-> 0],
      designatedBidLevel4Isin                   |-> [i \in 1 .. 12 |-> 0],
      designatedBidLevel5Price                  |-> [i \in 1 .. 11 |-> 0],
      designatedBidLevel5RepoRemainingQuantity  |-> [i \in 1 .. 15 |-> 0],
      designatedBidLevel5Isin                   |-> [i \in 1 .. 12 |-> 0],
      designatedBidLevel6Price                  |-> [i \in 1 .. 11 |-> 0],
      designatedBidLevel6RepoRemainingQuantity  |-> [i \in 1 .. 15 |-> 0],
      designatedBidLevel6Isin                   |-> [i \in 1 .. 12 |-> 0],
      designatedBidLevel7Price                  |-> [i \in 1 .. 11 |-> 0],
      designatedBidLevel7RepoRemainingQuantity  |-> [i \in 1 .. 15 |-> 0],
      designatedBidLevel7Isin                   |-> [i \in 1 .. 12 |-> 0],
      designatedBidLevel8Price                  |-> [i \in 1 .. 11 |-> 0],
      designatedBidLevel8RepoRemainingQuantity  |-> [i \in 1 .. 15 |-> 0],
      designatedBidLevel8Isin                   |-> [i \in 1 .. 12 |-> 0],
      designatedBidLevel9Price                  |-> [i \in 1 .. 11 |-> 0],
      designatedBidLevel9RepoRemainingQuantity  |-> [i \in 1 .. 15 |-> 0],
      designatedBidLevel9Isin                   |-> [i \in 1 .. 12 |-> 0],
      designatedBidLevel10Price                 |-> [i \in 1 .. 11 |-> 0],
      designatedBidLevel10RepoRemainingQuantity |-> [i \in 1 .. 15 |-> 0],
      designatedBidLevel10Isin                  |-> [i \in 1 .. 12 |-> 0],
      designatedBestBidPrice                    |-> [i \in 1 .. 11 |-> 0],
      netBidPerTypeTotalRemainingQuantity       |-> [i \in 1 .. 15 |-> 0],
      endKeyword                                |-> [i \in 1 .. 1 |-> 0] ]

(* Repo Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedRepoQuoteMessage ==
    { ZeroRepoQuoteMessage }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.processingTimeOfTradingSystem = one] : one \in Sample(12) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.durationOfTermRepo = one] : one \in Sample(4) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.askLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.bidLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.askLevel1RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.bidLevel1RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.askLevel1TradingAmount = one] : one \in Sample(22) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.totalBidLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.totalBidLevel1RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.bidLevel1IncludingGc = one] : one \in Sample(1) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.askPerTypeLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.bidPerTypeLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.askPerTypeLevel1RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.bidPerTypeLevel1RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.askPerTypeLevel1TradingAmount = one] : one \in Sample(22) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.askLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.bidLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.askLevel2RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.bidLevel2RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.askLevel2TradingAmount = one] : one \in Sample(22) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.totalBidLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.totalBidLevel2RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.bidLevel2IncludingGc = one] : one \in Sample(1) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.askPerTypeLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.bidPerTypeLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.askPerTypeLevel2RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.bidPerTypeLevel2RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.askPerTypeLevel2TradingAmount = one] : one \in Sample(22) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.askLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.bidLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.askLevel3RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.bidLevel3RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.askLevel3TradingAmount = one] : one \in Sample(22) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.totalBidLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.totalBidLevel3RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.bidLevel3IncludingGc = one] : one \in Sample(1) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.askPerTypeLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.bidPerTypeLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.askPerTypeLevel3RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.bidPerTypeLevel3RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.askPerTypeLevel3TradingAmount = one] : one \in Sample(22) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.askLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.bidLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.askLevel4RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.bidLevel4RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.askLevel4TradingAmount = one] : one \in Sample(22) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.totalBidLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.totalBidLevel4RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.bidLevel4IncludingGc = one] : one \in Sample(1) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.askPerTypeLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.bidPerTypeLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.askPerTypeLevel4RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.bidPerTypeLevel4RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.askPerTypeLevel4TradingAmount = one] : one \in Sample(22) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.askLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.bidLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.askLevel5RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.bidLevel5RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.askLevel5TradingAmount = one] : one \in Sample(22) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.totalBidLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.totalBidLevel5RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.bidLevel5IncludingGc = one] : one \in Sample(1) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.askPerTypeLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.bidPerTypeLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.askPerTypeLevel5RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.bidPerTypeLevel5RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.askPerTypeLevel5TradingAmount = one] : one \in Sample(22) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.askTotalRemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.bidTotalRemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.askPerTypeTotalRemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.bidPerTypeTotalRemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.designatedBidLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.designatedBidLevel1RepoRemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.designatedBidLevel1Isin = one] : one \in Sample(12) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.designatedBidLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.designatedBidLevel2RepoRemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.designatedBidLevel2Isin = one] : one \in Sample(12) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.designatedBidLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.designatedBidLevel3RepoRemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.designatedBidLevel3Isin = one] : one \in Sample(12) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.designatedBidLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.designatedBidLevel4RepoRemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.designatedBidLevel4Isin = one] : one \in Sample(12) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.designatedBidLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.designatedBidLevel5RepoRemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.designatedBidLevel5Isin = one] : one \in Sample(12) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.designatedBidLevel6Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.designatedBidLevel6RepoRemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.designatedBidLevel6Isin = one] : one \in Sample(12) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.designatedBidLevel7Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.designatedBidLevel7RepoRemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.designatedBidLevel7Isin = one] : one \in Sample(12) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.designatedBidLevel8Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.designatedBidLevel8RepoRemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.designatedBidLevel8Isin = one] : one \in Sample(12) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.designatedBidLevel9Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.designatedBidLevel9RepoRemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.designatedBidLevel9Isin = one] : one \in Sample(12) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.designatedBidLevel10Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.designatedBidLevel10RepoRemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.designatedBidLevel10Isin = one] : one \in Sample(12) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.designatedBestBidPrice = one] : one \in Sample(11) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.netBidPerTypeTotalRemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoQuoteMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Bonds Total Remaining Volume On Quotes Message: 101 bytes               *)
(***************************************************************************)

BondsTotalRemainingVolumeOnQuotesMessage ==
    [ messageSequenceNumber            : Sample(8),
      boardId                          : Sample(2),
      isinCode                         : Sample(12),
      aDesignatedNumberForAnIssue      : Sample(6),
      processingTimeOfTradingSystem    : Sample(12),
      askTotalRemainingQuantity        : Sample(15),
      bidTotalRemainingQuantity        : Sample(15),
      askPerTypeTotalRemainingQuantity : Sample(15),
      bidPerTypeTotalRemainingQuantity : Sample(15),
      endKeyword                       : Sample(1) ]

EncodeBondsTotalRemainingVolumeOnQuotesMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.isinCode
        \o message.aDesignatedNumberForAnIssue
        \o message.processingTimeOfTradingSystem
        \o message.askTotalRemainingQuantity
        \o message.bidTotalRemainingQuantity
        \o message.askPerTypeTotalRemainingQuantity
        \o message.bidPerTypeTotalRemainingQuantity
        \o message.endKeyword

DecodeBondsTotalRemainingVolumeOnQuotesMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(boardId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET aDesignatedNumberForAnIssue == ReadBytes(isinCode.rest, 6) IN IF ~aDesignatedNumberForAnIssue.ok THEN Fail ELSE
    LET processingTimeOfTradingSystem == ReadBytes(aDesignatedNumberForAnIssue.rest, 12) IN IF ~processingTimeOfTradingSystem.ok THEN Fail ELSE
    LET askTotalRemainingQuantity == ReadBytes(processingTimeOfTradingSystem.rest, 15) IN IF ~askTotalRemainingQuantity.ok THEN Fail ELSE
    LET bidTotalRemainingQuantity == ReadBytes(askTotalRemainingQuantity.rest, 15) IN IF ~bidTotalRemainingQuantity.ok THEN Fail ELSE
    LET askPerTypeTotalRemainingQuantity == ReadBytes(bidTotalRemainingQuantity.rest, 15) IN IF ~askPerTypeTotalRemainingQuantity.ok THEN Fail ELSE
    LET bidPerTypeTotalRemainingQuantity == ReadBytes(askPerTypeTotalRemainingQuantity.rest, 15) IN IF ~bidPerTypeTotalRemainingQuantity.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(bidPerTypeTotalRemainingQuantity.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber            |-> messageSequenceNumber.value,
         boardId                          |-> boardId.value,
         isinCode                         |-> isinCode.value,
         aDesignatedNumberForAnIssue      |-> aDesignatedNumberForAnIssue.value,
         processingTimeOfTradingSystem    |-> processingTimeOfTradingSystem.value,
         askTotalRemainingQuantity        |-> askTotalRemainingQuantity.value,
         bidTotalRemainingQuantity        |-> bidTotalRemainingQuantity.value,
         askPerTypeTotalRemainingQuantity |-> askPerTypeTotalRemainingQuantity.value,
         bidPerTypeTotalRemainingQuantity |-> bidPerTypeTotalRemainingQuantity.value,
         endKeyword                       |-> endKeyword.value ], endKeyword.rest)

ZeroBondsTotalRemainingVolumeOnQuotesMessage ==
    [ messageSequenceNumber            |-> [i \in 1 .. 8 |-> 0],
      boardId                          |-> [i \in 1 .. 2 |-> 0],
      isinCode                         |-> [i \in 1 .. 12 |-> 0],
      aDesignatedNumberForAnIssue      |-> [i \in 1 .. 6 |-> 0],
      processingTimeOfTradingSystem    |-> [i \in 1 .. 12 |-> 0],
      askTotalRemainingQuantity        |-> [i \in 1 .. 15 |-> 0],
      bidTotalRemainingQuantity        |-> [i \in 1 .. 15 |-> 0],
      askPerTypeTotalRemainingQuantity |-> [i \in 1 .. 15 |-> 0],
      bidPerTypeTotalRemainingQuantity |-> [i \in 1 .. 15 |-> 0],
      endKeyword                       |-> [i \in 1 .. 1 |-> 0] ]

(* Bonds Total Remaining Volume On Quotes Message at zero, then each field in turn at the values it is checked at *)
CheckedBondsTotalRemainingVolumeOnQuotesMessage ==
    { ZeroBondsTotalRemainingVolumeOnQuotesMessage }
        \cup { [ZeroBondsTotalRemainingVolumeOnQuotesMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroBondsTotalRemainingVolumeOnQuotesMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroBondsTotalRemainingVolumeOnQuotesMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroBondsTotalRemainingVolumeOnQuotesMessage EXCEPT !.aDesignatedNumberForAnIssue = one] : one \in Sample(6) }
        \cup { [ZeroBondsTotalRemainingVolumeOnQuotesMessage EXCEPT !.processingTimeOfTradingSystem = one] : one \in Sample(12) }
        \cup { [ZeroBondsTotalRemainingVolumeOnQuotesMessage EXCEPT !.askTotalRemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBondsTotalRemainingVolumeOnQuotesMessage EXCEPT !.bidTotalRemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBondsTotalRemainingVolumeOnQuotesMessage EXCEPT !.askPerTypeTotalRemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBondsTotalRemainingVolumeOnQuotesMessage EXCEPT !.bidPerTypeTotalRemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBondsTotalRemainingVolumeOnQuotesMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Baby Bonds Order Filled Plus Quote Message: 1058 bytes                  *)
(***************************************************************************)

BabyBondsOrderFilledPlusQuoteMessage ==
    [ messageSequenceNumber             : Sample(8),
      boardId                           : Sample(2),
      sessionId                         : Sample(2),
      isinCode                          : Sample(12),
      processingTimeOfTradingSystem     : Sample(12),
      tradingPrice                      : Sample(11),
      tradingVolume                     : Sample(10),
      tradingDate                       : Sample(8),
      tradingValue                      : Sample(22),
      bondYield                         : Sample(13),
      openingPrice                      : Sample(11),
      todaysHigh                        : Sample(11),
      todaysLow                         : Sample(11),
      yieldOpeningPrice                 : Sample(13),
      yieldTodaysHigh                   : Sample(13),
      yieldTodaysLow                    : Sample(13),
      accumulatedTradingVolumeLong      : Sample(15),
      accumulatedTradingValueLong       : Sample(22),
      settlementDate                    : Sample(8),
      askLevel1Price                    : Sample(11),
      bidLevel1Price                    : Sample(11),
      askLevel1RemainingQuantity        : Sample(15),
      bidLevel1RemainingQuantity        : Sample(15),
      askLevel1Yield                    : Sample(13),
      bidLevel1Yield                    : Sample(13),
      askPerTypeLevel1Price             : Sample(11),
      bidPerTypeLevel1Price             : Sample(11),
      askPerTypeLevel1RemainingQuantity : Sample(15),
      bidPerTypeLevel1RemainingQuantity : Sample(15),
      askPerTypeLevel1Yield             : Sample(13),
      bidPerTypeLevel1Yield             : Sample(13),
      askLevel2Price                    : Sample(11),
      bidLevel2Price                    : Sample(11),
      askLevel2RemainingQuantity        : Sample(15),
      bidLevel2RemainingQuantity        : Sample(15),
      askLevel2Yield                    : Sample(13),
      bidLevel2Yield                    : Sample(13),
      askPerTypeLevel2Price             : Sample(11),
      bidPerTypeLevel2Price             : Sample(11),
      askPerTypeLevel2RemainingQuantity : Sample(15),
      bidPerTypeLevel2RemainingQuantity : Sample(15),
      askPerTypeLevel2Yield             : Sample(13),
      bidPerTypeLevel2Yield             : Sample(13),
      askLevel3Price                    : Sample(11),
      bidLevel3Price                    : Sample(11),
      askLevel3RemainingQuantity        : Sample(15),
      bidLevel3RemainingQuantity        : Sample(15),
      askLevel3Yield                    : Sample(13),
      bidLevel3Yield                    : Sample(13),
      askPerTypeLevel3Price             : Sample(11),
      bidPerTypeLevel3Price             : Sample(11),
      askPerTypeLevel3RemainingQuantity : Sample(15),
      bidPerTypeLevel3RemainingQuantity : Sample(15),
      askPerTypeLevel3Yield             : Sample(13),
      bidPerTypeLevel3Yield             : Sample(13),
      askLevel4Price                    : Sample(11),
      bidLevel4Price                    : Sample(11),
      askLevel4RemainingQuantity        : Sample(15),
      bidLevel4RemainingQuantity        : Sample(15),
      askLevel4Yield                    : Sample(13),
      bidLevel4Yield                    : Sample(13),
      askPerTypeLevel4Price             : Sample(11),
      bidPerTypeLevel4Price             : Sample(11),
      askPerTypeLevel4RemainingQuantity : Sample(15),
      bidPerTypeLevel4RemainingQuantity : Sample(15),
      askPerTypeLevel4Yield             : Sample(13),
      bidPerTypeLevel4Yield             : Sample(13),
      askLevel5Price                    : Sample(11),
      bidLevel5Price                    : Sample(11),
      askLevel5RemainingQuantity        : Sample(15),
      bidLevel5RemainingQuantity        : Sample(15),
      askLevel5Yield                    : Sample(13),
      bidLevel5Yield                    : Sample(13),
      askPerTypeLevel5Price             : Sample(11),
      bidPerTypeLevel5Price             : Sample(11),
      askPerTypeLevel5RemainingQuantity : Sample(15),
      bidPerTypeLevel5RemainingQuantity : Sample(15),
      askPerTypeLevel5Yield             : Sample(13),
      bidPerTypeLevel5Yield             : Sample(13),
      askTotalRemainingQuantity         : Sample(15),
      bidTotalRemainingQuantity         : Sample(15),
      askPerTypeTotalRemainingQuantity  : Sample(15),
      bidPerTypeTotalRemainingQuantity  : Sample(15),
      endKeyword                        : Sample(1) ]

EncodeBabyBondsOrderFilledPlusQuoteMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.sessionId
        \o message.isinCode
        \o message.processingTimeOfTradingSystem
        \o message.tradingPrice
        \o message.tradingVolume
        \o message.tradingDate
        \o message.tradingValue
        \o message.bondYield
        \o message.openingPrice
        \o message.todaysHigh
        \o message.todaysLow
        \o message.yieldOpeningPrice
        \o message.yieldTodaysHigh
        \o message.yieldTodaysLow
        \o message.accumulatedTradingVolumeLong
        \o message.accumulatedTradingValueLong
        \o message.settlementDate
        \o message.askLevel1Price
        \o message.bidLevel1Price
        \o message.askLevel1RemainingQuantity
        \o message.bidLevel1RemainingQuantity
        \o message.askLevel1Yield
        \o message.bidLevel1Yield
        \o message.askPerTypeLevel1Price
        \o message.bidPerTypeLevel1Price
        \o message.askPerTypeLevel1RemainingQuantity
        \o message.bidPerTypeLevel1RemainingQuantity
        \o message.askPerTypeLevel1Yield
        \o message.bidPerTypeLevel1Yield
        \o message.askLevel2Price
        \o message.bidLevel2Price
        \o message.askLevel2RemainingQuantity
        \o message.bidLevel2RemainingQuantity
        \o message.askLevel2Yield
        \o message.bidLevel2Yield
        \o message.askPerTypeLevel2Price
        \o message.bidPerTypeLevel2Price
        \o message.askPerTypeLevel2RemainingQuantity
        \o message.bidPerTypeLevel2RemainingQuantity
        \o message.askPerTypeLevel2Yield
        \o message.bidPerTypeLevel2Yield
        \o message.askLevel3Price
        \o message.bidLevel3Price
        \o message.askLevel3RemainingQuantity
        \o message.bidLevel3RemainingQuantity
        \o message.askLevel3Yield
        \o message.bidLevel3Yield
        \o message.askPerTypeLevel3Price
        \o message.bidPerTypeLevel3Price
        \o message.askPerTypeLevel3RemainingQuantity
        \o message.bidPerTypeLevel3RemainingQuantity
        \o message.askPerTypeLevel3Yield
        \o message.bidPerTypeLevel3Yield
        \o message.askLevel4Price
        \o message.bidLevel4Price
        \o message.askLevel4RemainingQuantity
        \o message.bidLevel4RemainingQuantity
        \o message.askLevel4Yield
        \o message.bidLevel4Yield
        \o message.askPerTypeLevel4Price
        \o message.bidPerTypeLevel4Price
        \o message.askPerTypeLevel4RemainingQuantity
        \o message.bidPerTypeLevel4RemainingQuantity
        \o message.askPerTypeLevel4Yield
        \o message.bidPerTypeLevel4Yield
        \o message.askLevel5Price
        \o message.bidLevel5Price
        \o message.askLevel5RemainingQuantity
        \o message.bidLevel5RemainingQuantity
        \o message.askLevel5Yield
        \o message.bidLevel5Yield
        \o message.askPerTypeLevel5Price
        \o message.bidPerTypeLevel5Price
        \o message.askPerTypeLevel5RemainingQuantity
        \o message.bidPerTypeLevel5RemainingQuantity
        \o message.askPerTypeLevel5Yield
        \o message.bidPerTypeLevel5Yield
        \o message.askTotalRemainingQuantity
        \o message.bidTotalRemainingQuantity
        \o message.askPerTypeTotalRemainingQuantity
        \o message.bidPerTypeTotalRemainingQuantity
        \o message.endKeyword

DecodeBabyBondsOrderFilledPlusQuoteMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(boardId.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(sessionId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET processingTimeOfTradingSystem == ReadBytes(isinCode.rest, 12) IN IF ~processingTimeOfTradingSystem.ok THEN Fail ELSE
    LET tradingPrice == ReadBytes(processingTimeOfTradingSystem.rest, 11) IN IF ~tradingPrice.ok THEN Fail ELSE
    LET tradingVolume == ReadBytes(tradingPrice.rest, 10) IN IF ~tradingVolume.ok THEN Fail ELSE
    LET tradingDate == ReadBytes(tradingVolume.rest, 8) IN IF ~tradingDate.ok THEN Fail ELSE
    LET tradingValue == ReadBytes(tradingDate.rest, 22) IN IF ~tradingValue.ok THEN Fail ELSE
    LET bondYield == ReadBytes(tradingValue.rest, 13) IN IF ~bondYield.ok THEN Fail ELSE
    LET openingPrice == ReadBytes(bondYield.rest, 11) IN IF ~openingPrice.ok THEN Fail ELSE
    LET todaysHigh == ReadBytes(openingPrice.rest, 11) IN IF ~todaysHigh.ok THEN Fail ELSE
    LET todaysLow == ReadBytes(todaysHigh.rest, 11) IN IF ~todaysLow.ok THEN Fail ELSE
    LET yieldOpeningPrice == ReadBytes(todaysLow.rest, 13) IN IF ~yieldOpeningPrice.ok THEN Fail ELSE
    LET yieldTodaysHigh == ReadBytes(yieldOpeningPrice.rest, 13) IN IF ~yieldTodaysHigh.ok THEN Fail ELSE
    LET yieldTodaysLow == ReadBytes(yieldTodaysHigh.rest, 13) IN IF ~yieldTodaysLow.ok THEN Fail ELSE
    LET accumulatedTradingVolumeLong == ReadBytes(yieldTodaysLow.rest, 15) IN IF ~accumulatedTradingVolumeLong.ok THEN Fail ELSE
    LET accumulatedTradingValueLong == ReadBytes(accumulatedTradingVolumeLong.rest, 22) IN IF ~accumulatedTradingValueLong.ok THEN Fail ELSE
    LET settlementDate == ReadBytes(accumulatedTradingValueLong.rest, 8) IN IF ~settlementDate.ok THEN Fail ELSE
    LET askLevel1Price == ReadBytes(settlementDate.rest, 11) IN IF ~askLevel1Price.ok THEN Fail ELSE
    LET bidLevel1Price == ReadBytes(askLevel1Price.rest, 11) IN IF ~bidLevel1Price.ok THEN Fail ELSE
    LET askLevel1RemainingQuantity == ReadBytes(bidLevel1Price.rest, 15) IN IF ~askLevel1RemainingQuantity.ok THEN Fail ELSE
    LET bidLevel1RemainingQuantity == ReadBytes(askLevel1RemainingQuantity.rest, 15) IN IF ~bidLevel1RemainingQuantity.ok THEN Fail ELSE
    LET askLevel1Yield == ReadBytes(bidLevel1RemainingQuantity.rest, 13) IN IF ~askLevel1Yield.ok THEN Fail ELSE
    LET bidLevel1Yield == ReadBytes(askLevel1Yield.rest, 13) IN IF ~bidLevel1Yield.ok THEN Fail ELSE
    LET askPerTypeLevel1Price == ReadBytes(bidLevel1Yield.rest, 11) IN IF ~askPerTypeLevel1Price.ok THEN Fail ELSE
    LET bidPerTypeLevel1Price == ReadBytes(askPerTypeLevel1Price.rest, 11) IN IF ~bidPerTypeLevel1Price.ok THEN Fail ELSE
    LET askPerTypeLevel1RemainingQuantity == ReadBytes(bidPerTypeLevel1Price.rest, 15) IN IF ~askPerTypeLevel1RemainingQuantity.ok THEN Fail ELSE
    LET bidPerTypeLevel1RemainingQuantity == ReadBytes(askPerTypeLevel1RemainingQuantity.rest, 15) IN IF ~bidPerTypeLevel1RemainingQuantity.ok THEN Fail ELSE
    LET askPerTypeLevel1Yield == ReadBytes(bidPerTypeLevel1RemainingQuantity.rest, 13) IN IF ~askPerTypeLevel1Yield.ok THEN Fail ELSE
    LET bidPerTypeLevel1Yield == ReadBytes(askPerTypeLevel1Yield.rest, 13) IN IF ~bidPerTypeLevel1Yield.ok THEN Fail ELSE
    LET askLevel2Price == ReadBytes(bidPerTypeLevel1Yield.rest, 11) IN IF ~askLevel2Price.ok THEN Fail ELSE
    LET bidLevel2Price == ReadBytes(askLevel2Price.rest, 11) IN IF ~bidLevel2Price.ok THEN Fail ELSE
    LET askLevel2RemainingQuantity == ReadBytes(bidLevel2Price.rest, 15) IN IF ~askLevel2RemainingQuantity.ok THEN Fail ELSE
    LET bidLevel2RemainingQuantity == ReadBytes(askLevel2RemainingQuantity.rest, 15) IN IF ~bidLevel2RemainingQuantity.ok THEN Fail ELSE
    LET askLevel2Yield == ReadBytes(bidLevel2RemainingQuantity.rest, 13) IN IF ~askLevel2Yield.ok THEN Fail ELSE
    LET bidLevel2Yield == ReadBytes(askLevel2Yield.rest, 13) IN IF ~bidLevel2Yield.ok THEN Fail ELSE
    LET askPerTypeLevel2Price == ReadBytes(bidLevel2Yield.rest, 11) IN IF ~askPerTypeLevel2Price.ok THEN Fail ELSE
    LET bidPerTypeLevel2Price == ReadBytes(askPerTypeLevel2Price.rest, 11) IN IF ~bidPerTypeLevel2Price.ok THEN Fail ELSE
    LET askPerTypeLevel2RemainingQuantity == ReadBytes(bidPerTypeLevel2Price.rest, 15) IN IF ~askPerTypeLevel2RemainingQuantity.ok THEN Fail ELSE
    LET bidPerTypeLevel2RemainingQuantity == ReadBytes(askPerTypeLevel2RemainingQuantity.rest, 15) IN IF ~bidPerTypeLevel2RemainingQuantity.ok THEN Fail ELSE
    LET askPerTypeLevel2Yield == ReadBytes(bidPerTypeLevel2RemainingQuantity.rest, 13) IN IF ~askPerTypeLevel2Yield.ok THEN Fail ELSE
    LET bidPerTypeLevel2Yield == ReadBytes(askPerTypeLevel2Yield.rest, 13) IN IF ~bidPerTypeLevel2Yield.ok THEN Fail ELSE
    LET askLevel3Price == ReadBytes(bidPerTypeLevel2Yield.rest, 11) IN IF ~askLevel3Price.ok THEN Fail ELSE
    LET bidLevel3Price == ReadBytes(askLevel3Price.rest, 11) IN IF ~bidLevel3Price.ok THEN Fail ELSE
    LET askLevel3RemainingQuantity == ReadBytes(bidLevel3Price.rest, 15) IN IF ~askLevel3RemainingQuantity.ok THEN Fail ELSE
    LET bidLevel3RemainingQuantity == ReadBytes(askLevel3RemainingQuantity.rest, 15) IN IF ~bidLevel3RemainingQuantity.ok THEN Fail ELSE
    LET askLevel3Yield == ReadBytes(bidLevel3RemainingQuantity.rest, 13) IN IF ~askLevel3Yield.ok THEN Fail ELSE
    LET bidLevel3Yield == ReadBytes(askLevel3Yield.rest, 13) IN IF ~bidLevel3Yield.ok THEN Fail ELSE
    LET askPerTypeLevel3Price == ReadBytes(bidLevel3Yield.rest, 11) IN IF ~askPerTypeLevel3Price.ok THEN Fail ELSE
    LET bidPerTypeLevel3Price == ReadBytes(askPerTypeLevel3Price.rest, 11) IN IF ~bidPerTypeLevel3Price.ok THEN Fail ELSE
    LET askPerTypeLevel3RemainingQuantity == ReadBytes(bidPerTypeLevel3Price.rest, 15) IN IF ~askPerTypeLevel3RemainingQuantity.ok THEN Fail ELSE
    LET bidPerTypeLevel3RemainingQuantity == ReadBytes(askPerTypeLevel3RemainingQuantity.rest, 15) IN IF ~bidPerTypeLevel3RemainingQuantity.ok THEN Fail ELSE
    LET askPerTypeLevel3Yield == ReadBytes(bidPerTypeLevel3RemainingQuantity.rest, 13) IN IF ~askPerTypeLevel3Yield.ok THEN Fail ELSE
    LET bidPerTypeLevel3Yield == ReadBytes(askPerTypeLevel3Yield.rest, 13) IN IF ~bidPerTypeLevel3Yield.ok THEN Fail ELSE
    LET askLevel4Price == ReadBytes(bidPerTypeLevel3Yield.rest, 11) IN IF ~askLevel4Price.ok THEN Fail ELSE
    LET bidLevel4Price == ReadBytes(askLevel4Price.rest, 11) IN IF ~bidLevel4Price.ok THEN Fail ELSE
    LET askLevel4RemainingQuantity == ReadBytes(bidLevel4Price.rest, 15) IN IF ~askLevel4RemainingQuantity.ok THEN Fail ELSE
    LET bidLevel4RemainingQuantity == ReadBytes(askLevel4RemainingQuantity.rest, 15) IN IF ~bidLevel4RemainingQuantity.ok THEN Fail ELSE
    LET askLevel4Yield == ReadBytes(bidLevel4RemainingQuantity.rest, 13) IN IF ~askLevel4Yield.ok THEN Fail ELSE
    LET bidLevel4Yield == ReadBytes(askLevel4Yield.rest, 13) IN IF ~bidLevel4Yield.ok THEN Fail ELSE
    LET askPerTypeLevel4Price == ReadBytes(bidLevel4Yield.rest, 11) IN IF ~askPerTypeLevel4Price.ok THEN Fail ELSE
    LET bidPerTypeLevel4Price == ReadBytes(askPerTypeLevel4Price.rest, 11) IN IF ~bidPerTypeLevel4Price.ok THEN Fail ELSE
    LET askPerTypeLevel4RemainingQuantity == ReadBytes(bidPerTypeLevel4Price.rest, 15) IN IF ~askPerTypeLevel4RemainingQuantity.ok THEN Fail ELSE
    LET bidPerTypeLevel4RemainingQuantity == ReadBytes(askPerTypeLevel4RemainingQuantity.rest, 15) IN IF ~bidPerTypeLevel4RemainingQuantity.ok THEN Fail ELSE
    LET askPerTypeLevel4Yield == ReadBytes(bidPerTypeLevel4RemainingQuantity.rest, 13) IN IF ~askPerTypeLevel4Yield.ok THEN Fail ELSE
    LET bidPerTypeLevel4Yield == ReadBytes(askPerTypeLevel4Yield.rest, 13) IN IF ~bidPerTypeLevel4Yield.ok THEN Fail ELSE
    LET askLevel5Price == ReadBytes(bidPerTypeLevel4Yield.rest, 11) IN IF ~askLevel5Price.ok THEN Fail ELSE
    LET bidLevel5Price == ReadBytes(askLevel5Price.rest, 11) IN IF ~bidLevel5Price.ok THEN Fail ELSE
    LET askLevel5RemainingQuantity == ReadBytes(bidLevel5Price.rest, 15) IN IF ~askLevel5RemainingQuantity.ok THEN Fail ELSE
    LET bidLevel5RemainingQuantity == ReadBytes(askLevel5RemainingQuantity.rest, 15) IN IF ~bidLevel5RemainingQuantity.ok THEN Fail ELSE
    LET askLevel5Yield == ReadBytes(bidLevel5RemainingQuantity.rest, 13) IN IF ~askLevel5Yield.ok THEN Fail ELSE
    LET bidLevel5Yield == ReadBytes(askLevel5Yield.rest, 13) IN IF ~bidLevel5Yield.ok THEN Fail ELSE
    LET askPerTypeLevel5Price == ReadBytes(bidLevel5Yield.rest, 11) IN IF ~askPerTypeLevel5Price.ok THEN Fail ELSE
    LET bidPerTypeLevel5Price == ReadBytes(askPerTypeLevel5Price.rest, 11) IN IF ~bidPerTypeLevel5Price.ok THEN Fail ELSE
    LET askPerTypeLevel5RemainingQuantity == ReadBytes(bidPerTypeLevel5Price.rest, 15) IN IF ~askPerTypeLevel5RemainingQuantity.ok THEN Fail ELSE
    LET bidPerTypeLevel5RemainingQuantity == ReadBytes(askPerTypeLevel5RemainingQuantity.rest, 15) IN IF ~bidPerTypeLevel5RemainingQuantity.ok THEN Fail ELSE
    LET askPerTypeLevel5Yield == ReadBytes(bidPerTypeLevel5RemainingQuantity.rest, 13) IN IF ~askPerTypeLevel5Yield.ok THEN Fail ELSE
    LET bidPerTypeLevel5Yield == ReadBytes(askPerTypeLevel5Yield.rest, 13) IN IF ~bidPerTypeLevel5Yield.ok THEN Fail ELSE
    LET askTotalRemainingQuantity == ReadBytes(bidPerTypeLevel5Yield.rest, 15) IN IF ~askTotalRemainingQuantity.ok THEN Fail ELSE
    LET bidTotalRemainingQuantity == ReadBytes(askTotalRemainingQuantity.rest, 15) IN IF ~bidTotalRemainingQuantity.ok THEN Fail ELSE
    LET askPerTypeTotalRemainingQuantity == ReadBytes(bidTotalRemainingQuantity.rest, 15) IN IF ~askPerTypeTotalRemainingQuantity.ok THEN Fail ELSE
    LET bidPerTypeTotalRemainingQuantity == ReadBytes(askPerTypeTotalRemainingQuantity.rest, 15) IN IF ~bidPerTypeTotalRemainingQuantity.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(bidPerTypeTotalRemainingQuantity.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber             |-> messageSequenceNumber.value,
         boardId                           |-> boardId.value,
         sessionId                         |-> sessionId.value,
         isinCode                          |-> isinCode.value,
         processingTimeOfTradingSystem     |-> processingTimeOfTradingSystem.value,
         tradingPrice                      |-> tradingPrice.value,
         tradingVolume                     |-> tradingVolume.value,
         tradingDate                       |-> tradingDate.value,
         tradingValue                      |-> tradingValue.value,
         bondYield                         |-> bondYield.value,
         openingPrice                      |-> openingPrice.value,
         todaysHigh                        |-> todaysHigh.value,
         todaysLow                         |-> todaysLow.value,
         yieldOpeningPrice                 |-> yieldOpeningPrice.value,
         yieldTodaysHigh                   |-> yieldTodaysHigh.value,
         yieldTodaysLow                    |-> yieldTodaysLow.value,
         accumulatedTradingVolumeLong      |-> accumulatedTradingVolumeLong.value,
         accumulatedTradingValueLong       |-> accumulatedTradingValueLong.value,
         settlementDate                    |-> settlementDate.value,
         askLevel1Price                    |-> askLevel1Price.value,
         bidLevel1Price                    |-> bidLevel1Price.value,
         askLevel1RemainingQuantity        |-> askLevel1RemainingQuantity.value,
         bidLevel1RemainingQuantity        |-> bidLevel1RemainingQuantity.value,
         askLevel1Yield                    |-> askLevel1Yield.value,
         bidLevel1Yield                    |-> bidLevel1Yield.value,
         askPerTypeLevel1Price             |-> askPerTypeLevel1Price.value,
         bidPerTypeLevel1Price             |-> bidPerTypeLevel1Price.value,
         askPerTypeLevel1RemainingQuantity |-> askPerTypeLevel1RemainingQuantity.value,
         bidPerTypeLevel1RemainingQuantity |-> bidPerTypeLevel1RemainingQuantity.value,
         askPerTypeLevel1Yield             |-> askPerTypeLevel1Yield.value,
         bidPerTypeLevel1Yield             |-> bidPerTypeLevel1Yield.value,
         askLevel2Price                    |-> askLevel2Price.value,
         bidLevel2Price                    |-> bidLevel2Price.value,
         askLevel2RemainingQuantity        |-> askLevel2RemainingQuantity.value,
         bidLevel2RemainingQuantity        |-> bidLevel2RemainingQuantity.value,
         askLevel2Yield                    |-> askLevel2Yield.value,
         bidLevel2Yield                    |-> bidLevel2Yield.value,
         askPerTypeLevel2Price             |-> askPerTypeLevel2Price.value,
         bidPerTypeLevel2Price             |-> bidPerTypeLevel2Price.value,
         askPerTypeLevel2RemainingQuantity |-> askPerTypeLevel2RemainingQuantity.value,
         bidPerTypeLevel2RemainingQuantity |-> bidPerTypeLevel2RemainingQuantity.value,
         askPerTypeLevel2Yield             |-> askPerTypeLevel2Yield.value,
         bidPerTypeLevel2Yield             |-> bidPerTypeLevel2Yield.value,
         askLevel3Price                    |-> askLevel3Price.value,
         bidLevel3Price                    |-> bidLevel3Price.value,
         askLevel3RemainingQuantity        |-> askLevel3RemainingQuantity.value,
         bidLevel3RemainingQuantity        |-> bidLevel3RemainingQuantity.value,
         askLevel3Yield                    |-> askLevel3Yield.value,
         bidLevel3Yield                    |-> bidLevel3Yield.value,
         askPerTypeLevel3Price             |-> askPerTypeLevel3Price.value,
         bidPerTypeLevel3Price             |-> bidPerTypeLevel3Price.value,
         askPerTypeLevel3RemainingQuantity |-> askPerTypeLevel3RemainingQuantity.value,
         bidPerTypeLevel3RemainingQuantity |-> bidPerTypeLevel3RemainingQuantity.value,
         askPerTypeLevel3Yield             |-> askPerTypeLevel3Yield.value,
         bidPerTypeLevel3Yield             |-> bidPerTypeLevel3Yield.value,
         askLevel4Price                    |-> askLevel4Price.value,
         bidLevel4Price                    |-> bidLevel4Price.value,
         askLevel4RemainingQuantity        |-> askLevel4RemainingQuantity.value,
         bidLevel4RemainingQuantity        |-> bidLevel4RemainingQuantity.value,
         askLevel4Yield                    |-> askLevel4Yield.value,
         bidLevel4Yield                    |-> bidLevel4Yield.value,
         askPerTypeLevel4Price             |-> askPerTypeLevel4Price.value,
         bidPerTypeLevel4Price             |-> bidPerTypeLevel4Price.value,
         askPerTypeLevel4RemainingQuantity |-> askPerTypeLevel4RemainingQuantity.value,
         bidPerTypeLevel4RemainingQuantity |-> bidPerTypeLevel4RemainingQuantity.value,
         askPerTypeLevel4Yield             |-> askPerTypeLevel4Yield.value,
         bidPerTypeLevel4Yield             |-> bidPerTypeLevel4Yield.value,
         askLevel5Price                    |-> askLevel5Price.value,
         bidLevel5Price                    |-> bidLevel5Price.value,
         askLevel5RemainingQuantity        |-> askLevel5RemainingQuantity.value,
         bidLevel5RemainingQuantity        |-> bidLevel5RemainingQuantity.value,
         askLevel5Yield                    |-> askLevel5Yield.value,
         bidLevel5Yield                    |-> bidLevel5Yield.value,
         askPerTypeLevel5Price             |-> askPerTypeLevel5Price.value,
         bidPerTypeLevel5Price             |-> bidPerTypeLevel5Price.value,
         askPerTypeLevel5RemainingQuantity |-> askPerTypeLevel5RemainingQuantity.value,
         bidPerTypeLevel5RemainingQuantity |-> bidPerTypeLevel5RemainingQuantity.value,
         askPerTypeLevel5Yield             |-> askPerTypeLevel5Yield.value,
         bidPerTypeLevel5Yield             |-> bidPerTypeLevel5Yield.value,
         askTotalRemainingQuantity         |-> askTotalRemainingQuantity.value,
         bidTotalRemainingQuantity         |-> bidTotalRemainingQuantity.value,
         askPerTypeTotalRemainingQuantity  |-> askPerTypeTotalRemainingQuantity.value,
         bidPerTypeTotalRemainingQuantity  |-> bidPerTypeTotalRemainingQuantity.value,
         endKeyword                        |-> endKeyword.value ], endKeyword.rest)

ZeroBabyBondsOrderFilledPlusQuoteMessage ==
    [ messageSequenceNumber             |-> [i \in 1 .. 8 |-> 0],
      boardId                           |-> [i \in 1 .. 2 |-> 0],
      sessionId                         |-> [i \in 1 .. 2 |-> 0],
      isinCode                          |-> [i \in 1 .. 12 |-> 0],
      processingTimeOfTradingSystem     |-> [i \in 1 .. 12 |-> 0],
      tradingPrice                      |-> [i \in 1 .. 11 |-> 0],
      tradingVolume                     |-> [i \in 1 .. 10 |-> 0],
      tradingDate                       |-> [i \in 1 .. 8 |-> 0],
      tradingValue                      |-> [i \in 1 .. 22 |-> 0],
      bondYield                         |-> [i \in 1 .. 13 |-> 0],
      openingPrice                      |-> [i \in 1 .. 11 |-> 0],
      todaysHigh                        |-> [i \in 1 .. 11 |-> 0],
      todaysLow                         |-> [i \in 1 .. 11 |-> 0],
      yieldOpeningPrice                 |-> [i \in 1 .. 13 |-> 0],
      yieldTodaysHigh                   |-> [i \in 1 .. 13 |-> 0],
      yieldTodaysLow                    |-> [i \in 1 .. 13 |-> 0],
      accumulatedTradingVolumeLong      |-> [i \in 1 .. 15 |-> 0],
      accumulatedTradingValueLong       |-> [i \in 1 .. 22 |-> 0],
      settlementDate                    |-> [i \in 1 .. 8 |-> 0],
      askLevel1Price                    |-> [i \in 1 .. 11 |-> 0],
      bidLevel1Price                    |-> [i \in 1 .. 11 |-> 0],
      askLevel1RemainingQuantity        |-> [i \in 1 .. 15 |-> 0],
      bidLevel1RemainingQuantity        |-> [i \in 1 .. 15 |-> 0],
      askLevel1Yield                    |-> [i \in 1 .. 13 |-> 0],
      bidLevel1Yield                    |-> [i \in 1 .. 13 |-> 0],
      askPerTypeLevel1Price             |-> [i \in 1 .. 11 |-> 0],
      bidPerTypeLevel1Price             |-> [i \in 1 .. 11 |-> 0],
      askPerTypeLevel1RemainingQuantity |-> [i \in 1 .. 15 |-> 0],
      bidPerTypeLevel1RemainingQuantity |-> [i \in 1 .. 15 |-> 0],
      askPerTypeLevel1Yield             |-> [i \in 1 .. 13 |-> 0],
      bidPerTypeLevel1Yield             |-> [i \in 1 .. 13 |-> 0],
      askLevel2Price                    |-> [i \in 1 .. 11 |-> 0],
      bidLevel2Price                    |-> [i \in 1 .. 11 |-> 0],
      askLevel2RemainingQuantity        |-> [i \in 1 .. 15 |-> 0],
      bidLevel2RemainingQuantity        |-> [i \in 1 .. 15 |-> 0],
      askLevel2Yield                    |-> [i \in 1 .. 13 |-> 0],
      bidLevel2Yield                    |-> [i \in 1 .. 13 |-> 0],
      askPerTypeLevel2Price             |-> [i \in 1 .. 11 |-> 0],
      bidPerTypeLevel2Price             |-> [i \in 1 .. 11 |-> 0],
      askPerTypeLevel2RemainingQuantity |-> [i \in 1 .. 15 |-> 0],
      bidPerTypeLevel2RemainingQuantity |-> [i \in 1 .. 15 |-> 0],
      askPerTypeLevel2Yield             |-> [i \in 1 .. 13 |-> 0],
      bidPerTypeLevel2Yield             |-> [i \in 1 .. 13 |-> 0],
      askLevel3Price                    |-> [i \in 1 .. 11 |-> 0],
      bidLevel3Price                    |-> [i \in 1 .. 11 |-> 0],
      askLevel3RemainingQuantity        |-> [i \in 1 .. 15 |-> 0],
      bidLevel3RemainingQuantity        |-> [i \in 1 .. 15 |-> 0],
      askLevel3Yield                    |-> [i \in 1 .. 13 |-> 0],
      bidLevel3Yield                    |-> [i \in 1 .. 13 |-> 0],
      askPerTypeLevel3Price             |-> [i \in 1 .. 11 |-> 0],
      bidPerTypeLevel3Price             |-> [i \in 1 .. 11 |-> 0],
      askPerTypeLevel3RemainingQuantity |-> [i \in 1 .. 15 |-> 0],
      bidPerTypeLevel3RemainingQuantity |-> [i \in 1 .. 15 |-> 0],
      askPerTypeLevel3Yield             |-> [i \in 1 .. 13 |-> 0],
      bidPerTypeLevel3Yield             |-> [i \in 1 .. 13 |-> 0],
      askLevel4Price                    |-> [i \in 1 .. 11 |-> 0],
      bidLevel4Price                    |-> [i \in 1 .. 11 |-> 0],
      askLevel4RemainingQuantity        |-> [i \in 1 .. 15 |-> 0],
      bidLevel4RemainingQuantity        |-> [i \in 1 .. 15 |-> 0],
      askLevel4Yield                    |-> [i \in 1 .. 13 |-> 0],
      bidLevel4Yield                    |-> [i \in 1 .. 13 |-> 0],
      askPerTypeLevel4Price             |-> [i \in 1 .. 11 |-> 0],
      bidPerTypeLevel4Price             |-> [i \in 1 .. 11 |-> 0],
      askPerTypeLevel4RemainingQuantity |-> [i \in 1 .. 15 |-> 0],
      bidPerTypeLevel4RemainingQuantity |-> [i \in 1 .. 15 |-> 0],
      askPerTypeLevel4Yield             |-> [i \in 1 .. 13 |-> 0],
      bidPerTypeLevel4Yield             |-> [i \in 1 .. 13 |-> 0],
      askLevel5Price                    |-> [i \in 1 .. 11 |-> 0],
      bidLevel5Price                    |-> [i \in 1 .. 11 |-> 0],
      askLevel5RemainingQuantity        |-> [i \in 1 .. 15 |-> 0],
      bidLevel5RemainingQuantity        |-> [i \in 1 .. 15 |-> 0],
      askLevel5Yield                    |-> [i \in 1 .. 13 |-> 0],
      bidLevel5Yield                    |-> [i \in 1 .. 13 |-> 0],
      askPerTypeLevel5Price             |-> [i \in 1 .. 11 |-> 0],
      bidPerTypeLevel5Price             |-> [i \in 1 .. 11 |-> 0],
      askPerTypeLevel5RemainingQuantity |-> [i \in 1 .. 15 |-> 0],
      bidPerTypeLevel5RemainingQuantity |-> [i \in 1 .. 15 |-> 0],
      askPerTypeLevel5Yield             |-> [i \in 1 .. 13 |-> 0],
      bidPerTypeLevel5Yield             |-> [i \in 1 .. 13 |-> 0],
      askTotalRemainingQuantity         |-> [i \in 1 .. 15 |-> 0],
      bidTotalRemainingQuantity         |-> [i \in 1 .. 15 |-> 0],
      askPerTypeTotalRemainingQuantity  |-> [i \in 1 .. 15 |-> 0],
      bidPerTypeTotalRemainingQuantity  |-> [i \in 1 .. 15 |-> 0],
      endKeyword                        |-> [i \in 1 .. 1 |-> 0] ]

(* Baby Bonds Order Filled Plus Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedBabyBondsOrderFilledPlusQuoteMessage ==
    { ZeroBabyBondsOrderFilledPlusQuoteMessage }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.processingTimeOfTradingSystem = one] : one \in Sample(12) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.tradingPrice = one] : one \in Sample(11) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.tradingVolume = one] : one \in Sample(10) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.tradingDate = one] : one \in Sample(8) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.tradingValue = one] : one \in Sample(22) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.bondYield = one] : one \in Sample(13) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.openingPrice = one] : one \in Sample(11) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.todaysHigh = one] : one \in Sample(11) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.todaysLow = one] : one \in Sample(11) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.yieldOpeningPrice = one] : one \in Sample(13) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.yieldTodaysHigh = one] : one \in Sample(13) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.yieldTodaysLow = one] : one \in Sample(13) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.accumulatedTradingVolumeLong = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.accumulatedTradingValueLong = one] : one \in Sample(22) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.settlementDate = one] : one \in Sample(8) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.askLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.bidLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.askLevel1RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.bidLevel1RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.askLevel1Yield = one] : one \in Sample(13) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.bidLevel1Yield = one] : one \in Sample(13) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.askPerTypeLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.bidPerTypeLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.askPerTypeLevel1RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.bidPerTypeLevel1RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.askPerTypeLevel1Yield = one] : one \in Sample(13) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.bidPerTypeLevel1Yield = one] : one \in Sample(13) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.askLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.bidLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.askLevel2RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.bidLevel2RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.askLevel2Yield = one] : one \in Sample(13) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.bidLevel2Yield = one] : one \in Sample(13) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.askPerTypeLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.bidPerTypeLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.askPerTypeLevel2RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.bidPerTypeLevel2RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.askPerTypeLevel2Yield = one] : one \in Sample(13) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.bidPerTypeLevel2Yield = one] : one \in Sample(13) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.askLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.bidLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.askLevel3RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.bidLevel3RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.askLevel3Yield = one] : one \in Sample(13) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.bidLevel3Yield = one] : one \in Sample(13) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.askPerTypeLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.bidPerTypeLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.askPerTypeLevel3RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.bidPerTypeLevel3RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.askPerTypeLevel3Yield = one] : one \in Sample(13) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.bidPerTypeLevel3Yield = one] : one \in Sample(13) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.askLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.bidLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.askLevel4RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.bidLevel4RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.askLevel4Yield = one] : one \in Sample(13) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.bidLevel4Yield = one] : one \in Sample(13) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.askPerTypeLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.bidPerTypeLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.askPerTypeLevel4RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.bidPerTypeLevel4RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.askPerTypeLevel4Yield = one] : one \in Sample(13) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.bidPerTypeLevel4Yield = one] : one \in Sample(13) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.askLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.bidLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.askLevel5RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.bidLevel5RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.askLevel5Yield = one] : one \in Sample(13) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.bidLevel5Yield = one] : one \in Sample(13) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.askPerTypeLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.bidPerTypeLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.askPerTypeLevel5RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.bidPerTypeLevel5RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.askPerTypeLevel5Yield = one] : one \in Sample(13) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.bidPerTypeLevel5Yield = one] : one \in Sample(13) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.askTotalRemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.bidTotalRemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.askPerTypeTotalRemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.bidPerTypeTotalRemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroBabyBondsOrderFilledPlusQuoteMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Repo Order Filled Plus Quote Message: 1581 bytes                        *)
(***************************************************************************)

RepoOrderFilledPlusQuoteMessage ==
    [ messageSequenceNumber                     : Sample(8),
      boardId                                   : Sample(2),
      sessionId                                 : Sample(2),
      isinCode                                  : Sample(12),
      processingTimeOfTradingSystem             : Sample(12),
      tradingPrice                              : Sample(11),
      tradingVolume                             : Sample(10),
      tradingDate                               : Sample(8),
      tradingValue                              : Sample(22),
      askRepoTypeCode                           : Sample(2),
      askDurationOfTermRepo                     : Sample(4),
      bidRepoTypeCode                           : Sample(2),
      bidDurationOfTermRepo                     : Sample(4),
      openingPrice                              : Sample(11),
      todaysHigh                                : Sample(11),
      todaysLow                                 : Sample(11),
      categoryOpeningPrice                      : Sample(11),
      categoryTodaysHigh                        : Sample(11),
      categoryTodaysLow                         : Sample(11),
      accumulatedTradingVolumeLong              : Sample(15),
      accumulatedTradingValueLong               : Sample(22),
      categoryAccumulatedTradingVolume          : Sample(15),
      categoryAccumulatedTradingValue           : Sample(22),
      askLevel1Price                            : Sample(11),
      bidLevel1Price                            : Sample(11),
      askLevel1RemainingQuantity                : Sample(15),
      bidLevel1RemainingQuantity                : Sample(15),
      askLevel1TradingAmount                    : Sample(22),
      totalBidLevel1Price                       : Sample(11),
      totalBidLevel1RemainingQuantity           : Sample(15),
      bidLevel1IncludingGc                      : Sample(1),
      askPerTypeLevel1Price                     : Sample(11),
      bidPerTypeLevel1Price                     : Sample(11),
      askPerTypeLevel1RemainingQuantity         : Sample(15),
      bidPerTypeLevel1RemainingQuantity         : Sample(15),
      askPerTypeLevel1TradingAmount             : Sample(22),
      askLevel2Price                            : Sample(11),
      bidLevel2Price                            : Sample(11),
      askLevel2RemainingQuantity                : Sample(15),
      bidLevel2RemainingQuantity                : Sample(15),
      askLevel2TradingAmount                    : Sample(22),
      totalBidLevel2Price                       : Sample(11),
      totalBidLevel2RemainingQuantity           : Sample(15),
      bidLevel2IncludingGc                      : Sample(1),
      askPerTypeLevel2Price                     : Sample(11),
      bidPerTypeLevel2Price                     : Sample(11),
      askPerTypeLevel2RemainingQuantity         : Sample(15),
      bidPerTypeLevel2RemainingQuantity         : Sample(15),
      askPerTypeLevel2TradingAmount             : Sample(22),
      askLevel3Price                            : Sample(11),
      bidLevel3Price                            : Sample(11),
      askLevel3RemainingQuantity                : Sample(15),
      bidLevel3RemainingQuantity                : Sample(15),
      askLevel3TradingAmount                    : Sample(22),
      totalBidLevel3Price                       : Sample(11),
      totalBidLevel3RemainingQuantity           : Sample(15),
      bidLevel3IncludingGc                      : Sample(1),
      askPerTypeLevel3Price                     : Sample(11),
      bidPerTypeLevel3Price                     : Sample(11),
      askPerTypeLevel3RemainingQuantity         : Sample(15),
      bidPerTypeLevel3RemainingQuantity         : Sample(15),
      askPerTypeLevel3TradingAmount             : Sample(22),
      askLevel4Price                            : Sample(11),
      bidLevel4Price                            : Sample(11),
      askLevel4RemainingQuantity                : Sample(15),
      bidLevel4RemainingQuantity                : Sample(15),
      askLevel4TradingAmount                    : Sample(22),
      totalBidLevel4Price                       : Sample(11),
      totalBidLevel4RemainingQuantity           : Sample(15),
      bidLevel4IncludingGc                      : Sample(1),
      askPerTypeLevel4Price                     : Sample(11),
      bidPerTypeLevel4Price                     : Sample(11),
      askPerTypeLevel4RemainingQuantity         : Sample(15),
      bidPerTypeLevel4RemainingQuantity         : Sample(15),
      askPerTypeLevel4TradingAmount             : Sample(22),
      askLevel5Price                            : Sample(11),
      bidLevel5Price                            : Sample(11),
      askLevel5RemainingQuantity                : Sample(15),
      bidLevel5RemainingQuantity                : Sample(15),
      askLevel5TradingAmount                    : Sample(22),
      totalBidLevel5Price                       : Sample(11),
      totalBidLevel5RemainingQuantity           : Sample(15),
      bidLevel5IncludingGc                      : Sample(1),
      askPerTypeLevel5Price                     : Sample(11),
      bidPerTypeLevel5Price                     : Sample(11),
      askPerTypeLevel5RemainingQuantity         : Sample(15),
      bidPerTypeLevel5RemainingQuantity         : Sample(15),
      askPerTypeLevel5TradingAmount             : Sample(22),
      askTotalRemainingQuantity                 : Sample(15),
      bidTotalRemainingQuantity                 : Sample(15),
      askPerTypeTotalRemainingQuantity          : Sample(15),
      bidPerTypeTotalRemainingQuantity          : Sample(15),
      designatedBidLevel1Price                  : Sample(11),
      designatedBidLevel1RepoRemainingQuantity  : Sample(15),
      designatedBidLevel1Isin                   : Sample(12),
      designatedBidLevel2Price                  : Sample(11),
      designatedBidLevel2RepoRemainingQuantity  : Sample(15),
      designatedBidLevel2Isin                   : Sample(12),
      designatedBidLevel3Price                  : Sample(11),
      designatedBidLevel3RepoRemainingQuantity  : Sample(15),
      designatedBidLevel3Isin                   : Sample(12),
      designatedBidLevel4Price                  : Sample(11),
      designatedBidLevel4RepoRemainingQuantity  : Sample(15),
      designatedBidLevel4Isin                   : Sample(12),
      designatedBidLevel5Price                  : Sample(11),
      designatedBidLevel5RepoRemainingQuantity  : Sample(15),
      designatedBidLevel5Isin                   : Sample(12),
      designatedBidLevel6Price                  : Sample(11),
      designatedBidLevel6RepoRemainingQuantity  : Sample(15),
      designatedBidLevel6Isin                   : Sample(12),
      designatedBidLevel7Price                  : Sample(11),
      designatedBidLevel7RepoRemainingQuantity  : Sample(15),
      designatedBidLevel7Isin                   : Sample(12),
      designatedBidLevel8Price                  : Sample(11),
      designatedBidLevel8RepoRemainingQuantity  : Sample(15),
      designatedBidLevel8Isin                   : Sample(12),
      designatedBidLevel9Price                  : Sample(11),
      designatedBidLevel9RepoRemainingQuantity  : Sample(15),
      designatedBidLevel9Isin                   : Sample(12),
      designatedBidLevel10Price                 : Sample(11),
      designatedBidLevel10RepoRemainingQuantity : Sample(15),
      designatedBidLevel10Isin                  : Sample(12),
      designatedBestBidPrice                    : Sample(11),
      netBidPerTypeTotalRemainingQuantity       : Sample(15),
      endKeyword                                : Sample(1) ]

EncodeRepoOrderFilledPlusQuoteMessage(message) ==
    message.messageSequenceNumber
        \o message.boardId
        \o message.sessionId
        \o message.isinCode
        \o message.processingTimeOfTradingSystem
        \o message.tradingPrice
        \o message.tradingVolume
        \o message.tradingDate
        \o message.tradingValue
        \o message.askRepoTypeCode
        \o message.askDurationOfTermRepo
        \o message.bidRepoTypeCode
        \o message.bidDurationOfTermRepo
        \o message.openingPrice
        \o message.todaysHigh
        \o message.todaysLow
        \o message.categoryOpeningPrice
        \o message.categoryTodaysHigh
        \o message.categoryTodaysLow
        \o message.accumulatedTradingVolumeLong
        \o message.accumulatedTradingValueLong
        \o message.categoryAccumulatedTradingVolume
        \o message.categoryAccumulatedTradingValue
        \o message.askLevel1Price
        \o message.bidLevel1Price
        \o message.askLevel1RemainingQuantity
        \o message.bidLevel1RemainingQuantity
        \o message.askLevel1TradingAmount
        \o message.totalBidLevel1Price
        \o message.totalBidLevel1RemainingQuantity
        \o message.bidLevel1IncludingGc
        \o message.askPerTypeLevel1Price
        \o message.bidPerTypeLevel1Price
        \o message.askPerTypeLevel1RemainingQuantity
        \o message.bidPerTypeLevel1RemainingQuantity
        \o message.askPerTypeLevel1TradingAmount
        \o message.askLevel2Price
        \o message.bidLevel2Price
        \o message.askLevel2RemainingQuantity
        \o message.bidLevel2RemainingQuantity
        \o message.askLevel2TradingAmount
        \o message.totalBidLevel2Price
        \o message.totalBidLevel2RemainingQuantity
        \o message.bidLevel2IncludingGc
        \o message.askPerTypeLevel2Price
        \o message.bidPerTypeLevel2Price
        \o message.askPerTypeLevel2RemainingQuantity
        \o message.bidPerTypeLevel2RemainingQuantity
        \o message.askPerTypeLevel2TradingAmount
        \o message.askLevel3Price
        \o message.bidLevel3Price
        \o message.askLevel3RemainingQuantity
        \o message.bidLevel3RemainingQuantity
        \o message.askLevel3TradingAmount
        \o message.totalBidLevel3Price
        \o message.totalBidLevel3RemainingQuantity
        \o message.bidLevel3IncludingGc
        \o message.askPerTypeLevel3Price
        \o message.bidPerTypeLevel3Price
        \o message.askPerTypeLevel3RemainingQuantity
        \o message.bidPerTypeLevel3RemainingQuantity
        \o message.askPerTypeLevel3TradingAmount
        \o message.askLevel4Price
        \o message.bidLevel4Price
        \o message.askLevel4RemainingQuantity
        \o message.bidLevel4RemainingQuantity
        \o message.askLevel4TradingAmount
        \o message.totalBidLevel4Price
        \o message.totalBidLevel4RemainingQuantity
        \o message.bidLevel4IncludingGc
        \o message.askPerTypeLevel4Price
        \o message.bidPerTypeLevel4Price
        \o message.askPerTypeLevel4RemainingQuantity
        \o message.bidPerTypeLevel4RemainingQuantity
        \o message.askPerTypeLevel4TradingAmount
        \o message.askLevel5Price
        \o message.bidLevel5Price
        \o message.askLevel5RemainingQuantity
        \o message.bidLevel5RemainingQuantity
        \o message.askLevel5TradingAmount
        \o message.totalBidLevel5Price
        \o message.totalBidLevel5RemainingQuantity
        \o message.bidLevel5IncludingGc
        \o message.askPerTypeLevel5Price
        \o message.bidPerTypeLevel5Price
        \o message.askPerTypeLevel5RemainingQuantity
        \o message.bidPerTypeLevel5RemainingQuantity
        \o message.askPerTypeLevel5TradingAmount
        \o message.askTotalRemainingQuantity
        \o message.bidTotalRemainingQuantity
        \o message.askPerTypeTotalRemainingQuantity
        \o message.bidPerTypeTotalRemainingQuantity
        \o message.designatedBidLevel1Price
        \o message.designatedBidLevel1RepoRemainingQuantity
        \o message.designatedBidLevel1Isin
        \o message.designatedBidLevel2Price
        \o message.designatedBidLevel2RepoRemainingQuantity
        \o message.designatedBidLevel2Isin
        \o message.designatedBidLevel3Price
        \o message.designatedBidLevel3RepoRemainingQuantity
        \o message.designatedBidLevel3Isin
        \o message.designatedBidLevel4Price
        \o message.designatedBidLevel4RepoRemainingQuantity
        \o message.designatedBidLevel4Isin
        \o message.designatedBidLevel5Price
        \o message.designatedBidLevel5RepoRemainingQuantity
        \o message.designatedBidLevel5Isin
        \o message.designatedBidLevel6Price
        \o message.designatedBidLevel6RepoRemainingQuantity
        \o message.designatedBidLevel6Isin
        \o message.designatedBidLevel7Price
        \o message.designatedBidLevel7RepoRemainingQuantity
        \o message.designatedBidLevel7Isin
        \o message.designatedBidLevel8Price
        \o message.designatedBidLevel8RepoRemainingQuantity
        \o message.designatedBidLevel8Isin
        \o message.designatedBidLevel9Price
        \o message.designatedBidLevel9RepoRemainingQuantity
        \o message.designatedBidLevel9Isin
        \o message.designatedBidLevel10Price
        \o message.designatedBidLevel10RepoRemainingQuantity
        \o message.designatedBidLevel10Isin
        \o message.designatedBestBidPrice
        \o message.netBidPerTypeTotalRemainingQuantity
        \o message.endKeyword

DecodeRepoOrderFilledPlusQuoteMessage(bytes) ==
    LET messageSequenceNumber == ReadBytes(bytes, 8) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET boardId == ReadBytes(messageSequenceNumber.rest, 2) IN IF ~boardId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(boardId.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET isinCode == ReadBytes(sessionId.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET processingTimeOfTradingSystem == ReadBytes(isinCode.rest, 12) IN IF ~processingTimeOfTradingSystem.ok THEN Fail ELSE
    LET tradingPrice == ReadBytes(processingTimeOfTradingSystem.rest, 11) IN IF ~tradingPrice.ok THEN Fail ELSE
    LET tradingVolume == ReadBytes(tradingPrice.rest, 10) IN IF ~tradingVolume.ok THEN Fail ELSE
    LET tradingDate == ReadBytes(tradingVolume.rest, 8) IN IF ~tradingDate.ok THEN Fail ELSE
    LET tradingValue == ReadBytes(tradingDate.rest, 22) IN IF ~tradingValue.ok THEN Fail ELSE
    LET askRepoTypeCode == ReadBytes(tradingValue.rest, 2) IN IF ~askRepoTypeCode.ok THEN Fail ELSE
    LET askDurationOfTermRepo == ReadBytes(askRepoTypeCode.rest, 4) IN IF ~askDurationOfTermRepo.ok THEN Fail ELSE
    LET bidRepoTypeCode == ReadBytes(askDurationOfTermRepo.rest, 2) IN IF ~bidRepoTypeCode.ok THEN Fail ELSE
    LET bidDurationOfTermRepo == ReadBytes(bidRepoTypeCode.rest, 4) IN IF ~bidDurationOfTermRepo.ok THEN Fail ELSE
    LET openingPrice == ReadBytes(bidDurationOfTermRepo.rest, 11) IN IF ~openingPrice.ok THEN Fail ELSE
    LET todaysHigh == ReadBytes(openingPrice.rest, 11) IN IF ~todaysHigh.ok THEN Fail ELSE
    LET todaysLow == ReadBytes(todaysHigh.rest, 11) IN IF ~todaysLow.ok THEN Fail ELSE
    LET categoryOpeningPrice == ReadBytes(todaysLow.rest, 11) IN IF ~categoryOpeningPrice.ok THEN Fail ELSE
    LET categoryTodaysHigh == ReadBytes(categoryOpeningPrice.rest, 11) IN IF ~categoryTodaysHigh.ok THEN Fail ELSE
    LET categoryTodaysLow == ReadBytes(categoryTodaysHigh.rest, 11) IN IF ~categoryTodaysLow.ok THEN Fail ELSE
    LET accumulatedTradingVolumeLong == ReadBytes(categoryTodaysLow.rest, 15) IN IF ~accumulatedTradingVolumeLong.ok THEN Fail ELSE
    LET accumulatedTradingValueLong == ReadBytes(accumulatedTradingVolumeLong.rest, 22) IN IF ~accumulatedTradingValueLong.ok THEN Fail ELSE
    LET categoryAccumulatedTradingVolume == ReadBytes(accumulatedTradingValueLong.rest, 15) IN IF ~categoryAccumulatedTradingVolume.ok THEN Fail ELSE
    LET categoryAccumulatedTradingValue == ReadBytes(categoryAccumulatedTradingVolume.rest, 22) IN IF ~categoryAccumulatedTradingValue.ok THEN Fail ELSE
    LET askLevel1Price == ReadBytes(categoryAccumulatedTradingValue.rest, 11) IN IF ~askLevel1Price.ok THEN Fail ELSE
    LET bidLevel1Price == ReadBytes(askLevel1Price.rest, 11) IN IF ~bidLevel1Price.ok THEN Fail ELSE
    LET askLevel1RemainingQuantity == ReadBytes(bidLevel1Price.rest, 15) IN IF ~askLevel1RemainingQuantity.ok THEN Fail ELSE
    LET bidLevel1RemainingQuantity == ReadBytes(askLevel1RemainingQuantity.rest, 15) IN IF ~bidLevel1RemainingQuantity.ok THEN Fail ELSE
    LET askLevel1TradingAmount == ReadBytes(bidLevel1RemainingQuantity.rest, 22) IN IF ~askLevel1TradingAmount.ok THEN Fail ELSE
    LET totalBidLevel1Price == ReadBytes(askLevel1TradingAmount.rest, 11) IN IF ~totalBidLevel1Price.ok THEN Fail ELSE
    LET totalBidLevel1RemainingQuantity == ReadBytes(totalBidLevel1Price.rest, 15) IN IF ~totalBidLevel1RemainingQuantity.ok THEN Fail ELSE
    LET bidLevel1IncludingGc == ReadBytes(totalBidLevel1RemainingQuantity.rest, 1) IN IF ~bidLevel1IncludingGc.ok THEN Fail ELSE
    LET askPerTypeLevel1Price == ReadBytes(bidLevel1IncludingGc.rest, 11) IN IF ~askPerTypeLevel1Price.ok THEN Fail ELSE
    LET bidPerTypeLevel1Price == ReadBytes(askPerTypeLevel1Price.rest, 11) IN IF ~bidPerTypeLevel1Price.ok THEN Fail ELSE
    LET askPerTypeLevel1RemainingQuantity == ReadBytes(bidPerTypeLevel1Price.rest, 15) IN IF ~askPerTypeLevel1RemainingQuantity.ok THEN Fail ELSE
    LET bidPerTypeLevel1RemainingQuantity == ReadBytes(askPerTypeLevel1RemainingQuantity.rest, 15) IN IF ~bidPerTypeLevel1RemainingQuantity.ok THEN Fail ELSE
    LET askPerTypeLevel1TradingAmount == ReadBytes(bidPerTypeLevel1RemainingQuantity.rest, 22) IN IF ~askPerTypeLevel1TradingAmount.ok THEN Fail ELSE
    LET askLevel2Price == ReadBytes(askPerTypeLevel1TradingAmount.rest, 11) IN IF ~askLevel2Price.ok THEN Fail ELSE
    LET bidLevel2Price == ReadBytes(askLevel2Price.rest, 11) IN IF ~bidLevel2Price.ok THEN Fail ELSE
    LET askLevel2RemainingQuantity == ReadBytes(bidLevel2Price.rest, 15) IN IF ~askLevel2RemainingQuantity.ok THEN Fail ELSE
    LET bidLevel2RemainingQuantity == ReadBytes(askLevel2RemainingQuantity.rest, 15) IN IF ~bidLevel2RemainingQuantity.ok THEN Fail ELSE
    LET askLevel2TradingAmount == ReadBytes(bidLevel2RemainingQuantity.rest, 22) IN IF ~askLevel2TradingAmount.ok THEN Fail ELSE
    LET totalBidLevel2Price == ReadBytes(askLevel2TradingAmount.rest, 11) IN IF ~totalBidLevel2Price.ok THEN Fail ELSE
    LET totalBidLevel2RemainingQuantity == ReadBytes(totalBidLevel2Price.rest, 15) IN IF ~totalBidLevel2RemainingQuantity.ok THEN Fail ELSE
    LET bidLevel2IncludingGc == ReadBytes(totalBidLevel2RemainingQuantity.rest, 1) IN IF ~bidLevel2IncludingGc.ok THEN Fail ELSE
    LET askPerTypeLevel2Price == ReadBytes(bidLevel2IncludingGc.rest, 11) IN IF ~askPerTypeLevel2Price.ok THEN Fail ELSE
    LET bidPerTypeLevel2Price == ReadBytes(askPerTypeLevel2Price.rest, 11) IN IF ~bidPerTypeLevel2Price.ok THEN Fail ELSE
    LET askPerTypeLevel2RemainingQuantity == ReadBytes(bidPerTypeLevel2Price.rest, 15) IN IF ~askPerTypeLevel2RemainingQuantity.ok THEN Fail ELSE
    LET bidPerTypeLevel2RemainingQuantity == ReadBytes(askPerTypeLevel2RemainingQuantity.rest, 15) IN IF ~bidPerTypeLevel2RemainingQuantity.ok THEN Fail ELSE
    LET askPerTypeLevel2TradingAmount == ReadBytes(bidPerTypeLevel2RemainingQuantity.rest, 22) IN IF ~askPerTypeLevel2TradingAmount.ok THEN Fail ELSE
    LET askLevel3Price == ReadBytes(askPerTypeLevel2TradingAmount.rest, 11) IN IF ~askLevel3Price.ok THEN Fail ELSE
    LET bidLevel3Price == ReadBytes(askLevel3Price.rest, 11) IN IF ~bidLevel3Price.ok THEN Fail ELSE
    LET askLevel3RemainingQuantity == ReadBytes(bidLevel3Price.rest, 15) IN IF ~askLevel3RemainingQuantity.ok THEN Fail ELSE
    LET bidLevel3RemainingQuantity == ReadBytes(askLevel3RemainingQuantity.rest, 15) IN IF ~bidLevel3RemainingQuantity.ok THEN Fail ELSE
    LET askLevel3TradingAmount == ReadBytes(bidLevel3RemainingQuantity.rest, 22) IN IF ~askLevel3TradingAmount.ok THEN Fail ELSE
    LET totalBidLevel3Price == ReadBytes(askLevel3TradingAmount.rest, 11) IN IF ~totalBidLevel3Price.ok THEN Fail ELSE
    LET totalBidLevel3RemainingQuantity == ReadBytes(totalBidLevel3Price.rest, 15) IN IF ~totalBidLevel3RemainingQuantity.ok THEN Fail ELSE
    LET bidLevel3IncludingGc == ReadBytes(totalBidLevel3RemainingQuantity.rest, 1) IN IF ~bidLevel3IncludingGc.ok THEN Fail ELSE
    LET askPerTypeLevel3Price == ReadBytes(bidLevel3IncludingGc.rest, 11) IN IF ~askPerTypeLevel3Price.ok THEN Fail ELSE
    LET bidPerTypeLevel3Price == ReadBytes(askPerTypeLevel3Price.rest, 11) IN IF ~bidPerTypeLevel3Price.ok THEN Fail ELSE
    LET askPerTypeLevel3RemainingQuantity == ReadBytes(bidPerTypeLevel3Price.rest, 15) IN IF ~askPerTypeLevel3RemainingQuantity.ok THEN Fail ELSE
    LET bidPerTypeLevel3RemainingQuantity == ReadBytes(askPerTypeLevel3RemainingQuantity.rest, 15) IN IF ~bidPerTypeLevel3RemainingQuantity.ok THEN Fail ELSE
    LET askPerTypeLevel3TradingAmount == ReadBytes(bidPerTypeLevel3RemainingQuantity.rest, 22) IN IF ~askPerTypeLevel3TradingAmount.ok THEN Fail ELSE
    LET askLevel4Price == ReadBytes(askPerTypeLevel3TradingAmount.rest, 11) IN IF ~askLevel4Price.ok THEN Fail ELSE
    LET bidLevel4Price == ReadBytes(askLevel4Price.rest, 11) IN IF ~bidLevel4Price.ok THEN Fail ELSE
    LET askLevel4RemainingQuantity == ReadBytes(bidLevel4Price.rest, 15) IN IF ~askLevel4RemainingQuantity.ok THEN Fail ELSE
    LET bidLevel4RemainingQuantity == ReadBytes(askLevel4RemainingQuantity.rest, 15) IN IF ~bidLevel4RemainingQuantity.ok THEN Fail ELSE
    LET askLevel4TradingAmount == ReadBytes(bidLevel4RemainingQuantity.rest, 22) IN IF ~askLevel4TradingAmount.ok THEN Fail ELSE
    LET totalBidLevel4Price == ReadBytes(askLevel4TradingAmount.rest, 11) IN IF ~totalBidLevel4Price.ok THEN Fail ELSE
    LET totalBidLevel4RemainingQuantity == ReadBytes(totalBidLevel4Price.rest, 15) IN IF ~totalBidLevel4RemainingQuantity.ok THEN Fail ELSE
    LET bidLevel4IncludingGc == ReadBytes(totalBidLevel4RemainingQuantity.rest, 1) IN IF ~bidLevel4IncludingGc.ok THEN Fail ELSE
    LET askPerTypeLevel4Price == ReadBytes(bidLevel4IncludingGc.rest, 11) IN IF ~askPerTypeLevel4Price.ok THEN Fail ELSE
    LET bidPerTypeLevel4Price == ReadBytes(askPerTypeLevel4Price.rest, 11) IN IF ~bidPerTypeLevel4Price.ok THEN Fail ELSE
    LET askPerTypeLevel4RemainingQuantity == ReadBytes(bidPerTypeLevel4Price.rest, 15) IN IF ~askPerTypeLevel4RemainingQuantity.ok THEN Fail ELSE
    LET bidPerTypeLevel4RemainingQuantity == ReadBytes(askPerTypeLevel4RemainingQuantity.rest, 15) IN IF ~bidPerTypeLevel4RemainingQuantity.ok THEN Fail ELSE
    LET askPerTypeLevel4TradingAmount == ReadBytes(bidPerTypeLevel4RemainingQuantity.rest, 22) IN IF ~askPerTypeLevel4TradingAmount.ok THEN Fail ELSE
    LET askLevel5Price == ReadBytes(askPerTypeLevel4TradingAmount.rest, 11) IN IF ~askLevel5Price.ok THEN Fail ELSE
    LET bidLevel5Price == ReadBytes(askLevel5Price.rest, 11) IN IF ~bidLevel5Price.ok THEN Fail ELSE
    LET askLevel5RemainingQuantity == ReadBytes(bidLevel5Price.rest, 15) IN IF ~askLevel5RemainingQuantity.ok THEN Fail ELSE
    LET bidLevel5RemainingQuantity == ReadBytes(askLevel5RemainingQuantity.rest, 15) IN IF ~bidLevel5RemainingQuantity.ok THEN Fail ELSE
    LET askLevel5TradingAmount == ReadBytes(bidLevel5RemainingQuantity.rest, 22) IN IF ~askLevel5TradingAmount.ok THEN Fail ELSE
    LET totalBidLevel5Price == ReadBytes(askLevel5TradingAmount.rest, 11) IN IF ~totalBidLevel5Price.ok THEN Fail ELSE
    LET totalBidLevel5RemainingQuantity == ReadBytes(totalBidLevel5Price.rest, 15) IN IF ~totalBidLevel5RemainingQuantity.ok THEN Fail ELSE
    LET bidLevel5IncludingGc == ReadBytes(totalBidLevel5RemainingQuantity.rest, 1) IN IF ~bidLevel5IncludingGc.ok THEN Fail ELSE
    LET askPerTypeLevel5Price == ReadBytes(bidLevel5IncludingGc.rest, 11) IN IF ~askPerTypeLevel5Price.ok THEN Fail ELSE
    LET bidPerTypeLevel5Price == ReadBytes(askPerTypeLevel5Price.rest, 11) IN IF ~bidPerTypeLevel5Price.ok THEN Fail ELSE
    LET askPerTypeLevel5RemainingQuantity == ReadBytes(bidPerTypeLevel5Price.rest, 15) IN IF ~askPerTypeLevel5RemainingQuantity.ok THEN Fail ELSE
    LET bidPerTypeLevel5RemainingQuantity == ReadBytes(askPerTypeLevel5RemainingQuantity.rest, 15) IN IF ~bidPerTypeLevel5RemainingQuantity.ok THEN Fail ELSE
    LET askPerTypeLevel5TradingAmount == ReadBytes(bidPerTypeLevel5RemainingQuantity.rest, 22) IN IF ~askPerTypeLevel5TradingAmount.ok THEN Fail ELSE
    LET askTotalRemainingQuantity == ReadBytes(askPerTypeLevel5TradingAmount.rest, 15) IN IF ~askTotalRemainingQuantity.ok THEN Fail ELSE
    LET bidTotalRemainingQuantity == ReadBytes(askTotalRemainingQuantity.rest, 15) IN IF ~bidTotalRemainingQuantity.ok THEN Fail ELSE
    LET askPerTypeTotalRemainingQuantity == ReadBytes(bidTotalRemainingQuantity.rest, 15) IN IF ~askPerTypeTotalRemainingQuantity.ok THEN Fail ELSE
    LET bidPerTypeTotalRemainingQuantity == ReadBytes(askPerTypeTotalRemainingQuantity.rest, 15) IN IF ~bidPerTypeTotalRemainingQuantity.ok THEN Fail ELSE
    LET designatedBidLevel1Price == ReadBytes(bidPerTypeTotalRemainingQuantity.rest, 11) IN IF ~designatedBidLevel1Price.ok THEN Fail ELSE
    LET designatedBidLevel1RepoRemainingQuantity == ReadBytes(designatedBidLevel1Price.rest, 15) IN IF ~designatedBidLevel1RepoRemainingQuantity.ok THEN Fail ELSE
    LET designatedBidLevel1Isin == ReadBytes(designatedBidLevel1RepoRemainingQuantity.rest, 12) IN IF ~designatedBidLevel1Isin.ok THEN Fail ELSE
    LET designatedBidLevel2Price == ReadBytes(designatedBidLevel1Isin.rest, 11) IN IF ~designatedBidLevel2Price.ok THEN Fail ELSE
    LET designatedBidLevel2RepoRemainingQuantity == ReadBytes(designatedBidLevel2Price.rest, 15) IN IF ~designatedBidLevel2RepoRemainingQuantity.ok THEN Fail ELSE
    LET designatedBidLevel2Isin == ReadBytes(designatedBidLevel2RepoRemainingQuantity.rest, 12) IN IF ~designatedBidLevel2Isin.ok THEN Fail ELSE
    LET designatedBidLevel3Price == ReadBytes(designatedBidLevel2Isin.rest, 11) IN IF ~designatedBidLevel3Price.ok THEN Fail ELSE
    LET designatedBidLevel3RepoRemainingQuantity == ReadBytes(designatedBidLevel3Price.rest, 15) IN IF ~designatedBidLevel3RepoRemainingQuantity.ok THEN Fail ELSE
    LET designatedBidLevel3Isin == ReadBytes(designatedBidLevel3RepoRemainingQuantity.rest, 12) IN IF ~designatedBidLevel3Isin.ok THEN Fail ELSE
    LET designatedBidLevel4Price == ReadBytes(designatedBidLevel3Isin.rest, 11) IN IF ~designatedBidLevel4Price.ok THEN Fail ELSE
    LET designatedBidLevel4RepoRemainingQuantity == ReadBytes(designatedBidLevel4Price.rest, 15) IN IF ~designatedBidLevel4RepoRemainingQuantity.ok THEN Fail ELSE
    LET designatedBidLevel4Isin == ReadBytes(designatedBidLevel4RepoRemainingQuantity.rest, 12) IN IF ~designatedBidLevel4Isin.ok THEN Fail ELSE
    LET designatedBidLevel5Price == ReadBytes(designatedBidLevel4Isin.rest, 11) IN IF ~designatedBidLevel5Price.ok THEN Fail ELSE
    LET designatedBidLevel5RepoRemainingQuantity == ReadBytes(designatedBidLevel5Price.rest, 15) IN IF ~designatedBidLevel5RepoRemainingQuantity.ok THEN Fail ELSE
    LET designatedBidLevel5Isin == ReadBytes(designatedBidLevel5RepoRemainingQuantity.rest, 12) IN IF ~designatedBidLevel5Isin.ok THEN Fail ELSE
    LET designatedBidLevel6Price == ReadBytes(designatedBidLevel5Isin.rest, 11) IN IF ~designatedBidLevel6Price.ok THEN Fail ELSE
    LET designatedBidLevel6RepoRemainingQuantity == ReadBytes(designatedBidLevel6Price.rest, 15) IN IF ~designatedBidLevel6RepoRemainingQuantity.ok THEN Fail ELSE
    LET designatedBidLevel6Isin == ReadBytes(designatedBidLevel6RepoRemainingQuantity.rest, 12) IN IF ~designatedBidLevel6Isin.ok THEN Fail ELSE
    LET designatedBidLevel7Price == ReadBytes(designatedBidLevel6Isin.rest, 11) IN IF ~designatedBidLevel7Price.ok THEN Fail ELSE
    LET designatedBidLevel7RepoRemainingQuantity == ReadBytes(designatedBidLevel7Price.rest, 15) IN IF ~designatedBidLevel7RepoRemainingQuantity.ok THEN Fail ELSE
    LET designatedBidLevel7Isin == ReadBytes(designatedBidLevel7RepoRemainingQuantity.rest, 12) IN IF ~designatedBidLevel7Isin.ok THEN Fail ELSE
    LET designatedBidLevel8Price == ReadBytes(designatedBidLevel7Isin.rest, 11) IN IF ~designatedBidLevel8Price.ok THEN Fail ELSE
    LET designatedBidLevel8RepoRemainingQuantity == ReadBytes(designatedBidLevel8Price.rest, 15) IN IF ~designatedBidLevel8RepoRemainingQuantity.ok THEN Fail ELSE
    LET designatedBidLevel8Isin == ReadBytes(designatedBidLevel8RepoRemainingQuantity.rest, 12) IN IF ~designatedBidLevel8Isin.ok THEN Fail ELSE
    LET designatedBidLevel9Price == ReadBytes(designatedBidLevel8Isin.rest, 11) IN IF ~designatedBidLevel9Price.ok THEN Fail ELSE
    LET designatedBidLevel9RepoRemainingQuantity == ReadBytes(designatedBidLevel9Price.rest, 15) IN IF ~designatedBidLevel9RepoRemainingQuantity.ok THEN Fail ELSE
    LET designatedBidLevel9Isin == ReadBytes(designatedBidLevel9RepoRemainingQuantity.rest, 12) IN IF ~designatedBidLevel9Isin.ok THEN Fail ELSE
    LET designatedBidLevel10Price == ReadBytes(designatedBidLevel9Isin.rest, 11) IN IF ~designatedBidLevel10Price.ok THEN Fail ELSE
    LET designatedBidLevel10RepoRemainingQuantity == ReadBytes(designatedBidLevel10Price.rest, 15) IN IF ~designatedBidLevel10RepoRemainingQuantity.ok THEN Fail ELSE
    LET designatedBidLevel10Isin == ReadBytes(designatedBidLevel10RepoRemainingQuantity.rest, 12) IN IF ~designatedBidLevel10Isin.ok THEN Fail ELSE
    LET designatedBestBidPrice == ReadBytes(designatedBidLevel10Isin.rest, 11) IN IF ~designatedBestBidPrice.ok THEN Fail ELSE
    LET netBidPerTypeTotalRemainingQuantity == ReadBytes(designatedBestBidPrice.rest, 15) IN IF ~netBidPerTypeTotalRemainingQuantity.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(netBidPerTypeTotalRemainingQuantity.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ messageSequenceNumber                     |-> messageSequenceNumber.value,
         boardId                                   |-> boardId.value,
         sessionId                                 |-> sessionId.value,
         isinCode                                  |-> isinCode.value,
         processingTimeOfTradingSystem             |-> processingTimeOfTradingSystem.value,
         tradingPrice                              |-> tradingPrice.value,
         tradingVolume                             |-> tradingVolume.value,
         tradingDate                               |-> tradingDate.value,
         tradingValue                              |-> tradingValue.value,
         askRepoTypeCode                           |-> askRepoTypeCode.value,
         askDurationOfTermRepo                     |-> askDurationOfTermRepo.value,
         bidRepoTypeCode                           |-> bidRepoTypeCode.value,
         bidDurationOfTermRepo                     |-> bidDurationOfTermRepo.value,
         openingPrice                              |-> openingPrice.value,
         todaysHigh                                |-> todaysHigh.value,
         todaysLow                                 |-> todaysLow.value,
         categoryOpeningPrice                      |-> categoryOpeningPrice.value,
         categoryTodaysHigh                        |-> categoryTodaysHigh.value,
         categoryTodaysLow                         |-> categoryTodaysLow.value,
         accumulatedTradingVolumeLong              |-> accumulatedTradingVolumeLong.value,
         accumulatedTradingValueLong               |-> accumulatedTradingValueLong.value,
         categoryAccumulatedTradingVolume          |-> categoryAccumulatedTradingVolume.value,
         categoryAccumulatedTradingValue           |-> categoryAccumulatedTradingValue.value,
         askLevel1Price                            |-> askLevel1Price.value,
         bidLevel1Price                            |-> bidLevel1Price.value,
         askLevel1RemainingQuantity                |-> askLevel1RemainingQuantity.value,
         bidLevel1RemainingQuantity                |-> bidLevel1RemainingQuantity.value,
         askLevel1TradingAmount                    |-> askLevel1TradingAmount.value,
         totalBidLevel1Price                       |-> totalBidLevel1Price.value,
         totalBidLevel1RemainingQuantity           |-> totalBidLevel1RemainingQuantity.value,
         bidLevel1IncludingGc                      |-> bidLevel1IncludingGc.value,
         askPerTypeLevel1Price                     |-> askPerTypeLevel1Price.value,
         bidPerTypeLevel1Price                     |-> bidPerTypeLevel1Price.value,
         askPerTypeLevel1RemainingQuantity         |-> askPerTypeLevel1RemainingQuantity.value,
         bidPerTypeLevel1RemainingQuantity         |-> bidPerTypeLevel1RemainingQuantity.value,
         askPerTypeLevel1TradingAmount             |-> askPerTypeLevel1TradingAmount.value,
         askLevel2Price                            |-> askLevel2Price.value,
         bidLevel2Price                            |-> bidLevel2Price.value,
         askLevel2RemainingQuantity                |-> askLevel2RemainingQuantity.value,
         bidLevel2RemainingQuantity                |-> bidLevel2RemainingQuantity.value,
         askLevel2TradingAmount                    |-> askLevel2TradingAmount.value,
         totalBidLevel2Price                       |-> totalBidLevel2Price.value,
         totalBidLevel2RemainingQuantity           |-> totalBidLevel2RemainingQuantity.value,
         bidLevel2IncludingGc                      |-> bidLevel2IncludingGc.value,
         askPerTypeLevel2Price                     |-> askPerTypeLevel2Price.value,
         bidPerTypeLevel2Price                     |-> bidPerTypeLevel2Price.value,
         askPerTypeLevel2RemainingQuantity         |-> askPerTypeLevel2RemainingQuantity.value,
         bidPerTypeLevel2RemainingQuantity         |-> bidPerTypeLevel2RemainingQuantity.value,
         askPerTypeLevel2TradingAmount             |-> askPerTypeLevel2TradingAmount.value,
         askLevel3Price                            |-> askLevel3Price.value,
         bidLevel3Price                            |-> bidLevel3Price.value,
         askLevel3RemainingQuantity                |-> askLevel3RemainingQuantity.value,
         bidLevel3RemainingQuantity                |-> bidLevel3RemainingQuantity.value,
         askLevel3TradingAmount                    |-> askLevel3TradingAmount.value,
         totalBidLevel3Price                       |-> totalBidLevel3Price.value,
         totalBidLevel3RemainingQuantity           |-> totalBidLevel3RemainingQuantity.value,
         bidLevel3IncludingGc                      |-> bidLevel3IncludingGc.value,
         askPerTypeLevel3Price                     |-> askPerTypeLevel3Price.value,
         bidPerTypeLevel3Price                     |-> bidPerTypeLevel3Price.value,
         askPerTypeLevel3RemainingQuantity         |-> askPerTypeLevel3RemainingQuantity.value,
         bidPerTypeLevel3RemainingQuantity         |-> bidPerTypeLevel3RemainingQuantity.value,
         askPerTypeLevel3TradingAmount             |-> askPerTypeLevel3TradingAmount.value,
         askLevel4Price                            |-> askLevel4Price.value,
         bidLevel4Price                            |-> bidLevel4Price.value,
         askLevel4RemainingQuantity                |-> askLevel4RemainingQuantity.value,
         bidLevel4RemainingQuantity                |-> bidLevel4RemainingQuantity.value,
         askLevel4TradingAmount                    |-> askLevel4TradingAmount.value,
         totalBidLevel4Price                       |-> totalBidLevel4Price.value,
         totalBidLevel4RemainingQuantity           |-> totalBidLevel4RemainingQuantity.value,
         bidLevel4IncludingGc                      |-> bidLevel4IncludingGc.value,
         askPerTypeLevel4Price                     |-> askPerTypeLevel4Price.value,
         bidPerTypeLevel4Price                     |-> bidPerTypeLevel4Price.value,
         askPerTypeLevel4RemainingQuantity         |-> askPerTypeLevel4RemainingQuantity.value,
         bidPerTypeLevel4RemainingQuantity         |-> bidPerTypeLevel4RemainingQuantity.value,
         askPerTypeLevel4TradingAmount             |-> askPerTypeLevel4TradingAmount.value,
         askLevel5Price                            |-> askLevel5Price.value,
         bidLevel5Price                            |-> bidLevel5Price.value,
         askLevel5RemainingQuantity                |-> askLevel5RemainingQuantity.value,
         bidLevel5RemainingQuantity                |-> bidLevel5RemainingQuantity.value,
         askLevel5TradingAmount                    |-> askLevel5TradingAmount.value,
         totalBidLevel5Price                       |-> totalBidLevel5Price.value,
         totalBidLevel5RemainingQuantity           |-> totalBidLevel5RemainingQuantity.value,
         bidLevel5IncludingGc                      |-> bidLevel5IncludingGc.value,
         askPerTypeLevel5Price                     |-> askPerTypeLevel5Price.value,
         bidPerTypeLevel5Price                     |-> bidPerTypeLevel5Price.value,
         askPerTypeLevel5RemainingQuantity         |-> askPerTypeLevel5RemainingQuantity.value,
         bidPerTypeLevel5RemainingQuantity         |-> bidPerTypeLevel5RemainingQuantity.value,
         askPerTypeLevel5TradingAmount             |-> askPerTypeLevel5TradingAmount.value,
         askTotalRemainingQuantity                 |-> askTotalRemainingQuantity.value,
         bidTotalRemainingQuantity                 |-> bidTotalRemainingQuantity.value,
         askPerTypeTotalRemainingQuantity          |-> askPerTypeTotalRemainingQuantity.value,
         bidPerTypeTotalRemainingQuantity          |-> bidPerTypeTotalRemainingQuantity.value,
         designatedBidLevel1Price                  |-> designatedBidLevel1Price.value,
         designatedBidLevel1RepoRemainingQuantity  |-> designatedBidLevel1RepoRemainingQuantity.value,
         designatedBidLevel1Isin                   |-> designatedBidLevel1Isin.value,
         designatedBidLevel2Price                  |-> designatedBidLevel2Price.value,
         designatedBidLevel2RepoRemainingQuantity  |-> designatedBidLevel2RepoRemainingQuantity.value,
         designatedBidLevel2Isin                   |-> designatedBidLevel2Isin.value,
         designatedBidLevel3Price                  |-> designatedBidLevel3Price.value,
         designatedBidLevel3RepoRemainingQuantity  |-> designatedBidLevel3RepoRemainingQuantity.value,
         designatedBidLevel3Isin                   |-> designatedBidLevel3Isin.value,
         designatedBidLevel4Price                  |-> designatedBidLevel4Price.value,
         designatedBidLevel4RepoRemainingQuantity  |-> designatedBidLevel4RepoRemainingQuantity.value,
         designatedBidLevel4Isin                   |-> designatedBidLevel4Isin.value,
         designatedBidLevel5Price                  |-> designatedBidLevel5Price.value,
         designatedBidLevel5RepoRemainingQuantity  |-> designatedBidLevel5RepoRemainingQuantity.value,
         designatedBidLevel5Isin                   |-> designatedBidLevel5Isin.value,
         designatedBidLevel6Price                  |-> designatedBidLevel6Price.value,
         designatedBidLevel6RepoRemainingQuantity  |-> designatedBidLevel6RepoRemainingQuantity.value,
         designatedBidLevel6Isin                   |-> designatedBidLevel6Isin.value,
         designatedBidLevel7Price                  |-> designatedBidLevel7Price.value,
         designatedBidLevel7RepoRemainingQuantity  |-> designatedBidLevel7RepoRemainingQuantity.value,
         designatedBidLevel7Isin                   |-> designatedBidLevel7Isin.value,
         designatedBidLevel8Price                  |-> designatedBidLevel8Price.value,
         designatedBidLevel8RepoRemainingQuantity  |-> designatedBidLevel8RepoRemainingQuantity.value,
         designatedBidLevel8Isin                   |-> designatedBidLevel8Isin.value,
         designatedBidLevel9Price                  |-> designatedBidLevel9Price.value,
         designatedBidLevel9RepoRemainingQuantity  |-> designatedBidLevel9RepoRemainingQuantity.value,
         designatedBidLevel9Isin                   |-> designatedBidLevel9Isin.value,
         designatedBidLevel10Price                 |-> designatedBidLevel10Price.value,
         designatedBidLevel10RepoRemainingQuantity |-> designatedBidLevel10RepoRemainingQuantity.value,
         designatedBidLevel10Isin                  |-> designatedBidLevel10Isin.value,
         designatedBestBidPrice                    |-> designatedBestBidPrice.value,
         netBidPerTypeTotalRemainingQuantity       |-> netBidPerTypeTotalRemainingQuantity.value,
         endKeyword                                |-> endKeyword.value ], endKeyword.rest)

ZeroRepoOrderFilledPlusQuoteMessage ==
    [ messageSequenceNumber                     |-> [i \in 1 .. 8 |-> 0],
      boardId                                   |-> [i \in 1 .. 2 |-> 0],
      sessionId                                 |-> [i \in 1 .. 2 |-> 0],
      isinCode                                  |-> [i \in 1 .. 12 |-> 0],
      processingTimeOfTradingSystem             |-> [i \in 1 .. 12 |-> 0],
      tradingPrice                              |-> [i \in 1 .. 11 |-> 0],
      tradingVolume                             |-> [i \in 1 .. 10 |-> 0],
      tradingDate                               |-> [i \in 1 .. 8 |-> 0],
      tradingValue                              |-> [i \in 1 .. 22 |-> 0],
      askRepoTypeCode                           |-> [i \in 1 .. 2 |-> 0],
      askDurationOfTermRepo                     |-> [i \in 1 .. 4 |-> 0],
      bidRepoTypeCode                           |-> [i \in 1 .. 2 |-> 0],
      bidDurationOfTermRepo                     |-> [i \in 1 .. 4 |-> 0],
      openingPrice                              |-> [i \in 1 .. 11 |-> 0],
      todaysHigh                                |-> [i \in 1 .. 11 |-> 0],
      todaysLow                                 |-> [i \in 1 .. 11 |-> 0],
      categoryOpeningPrice                      |-> [i \in 1 .. 11 |-> 0],
      categoryTodaysHigh                        |-> [i \in 1 .. 11 |-> 0],
      categoryTodaysLow                         |-> [i \in 1 .. 11 |-> 0],
      accumulatedTradingVolumeLong              |-> [i \in 1 .. 15 |-> 0],
      accumulatedTradingValueLong               |-> [i \in 1 .. 22 |-> 0],
      categoryAccumulatedTradingVolume          |-> [i \in 1 .. 15 |-> 0],
      categoryAccumulatedTradingValue           |-> [i \in 1 .. 22 |-> 0],
      askLevel1Price                            |-> [i \in 1 .. 11 |-> 0],
      bidLevel1Price                            |-> [i \in 1 .. 11 |-> 0],
      askLevel1RemainingQuantity                |-> [i \in 1 .. 15 |-> 0],
      bidLevel1RemainingQuantity                |-> [i \in 1 .. 15 |-> 0],
      askLevel1TradingAmount                    |-> [i \in 1 .. 22 |-> 0],
      totalBidLevel1Price                       |-> [i \in 1 .. 11 |-> 0],
      totalBidLevel1RemainingQuantity           |-> [i \in 1 .. 15 |-> 0],
      bidLevel1IncludingGc                      |-> [i \in 1 .. 1 |-> 0],
      askPerTypeLevel1Price                     |-> [i \in 1 .. 11 |-> 0],
      bidPerTypeLevel1Price                     |-> [i \in 1 .. 11 |-> 0],
      askPerTypeLevel1RemainingQuantity         |-> [i \in 1 .. 15 |-> 0],
      bidPerTypeLevel1RemainingQuantity         |-> [i \in 1 .. 15 |-> 0],
      askPerTypeLevel1TradingAmount             |-> [i \in 1 .. 22 |-> 0],
      askLevel2Price                            |-> [i \in 1 .. 11 |-> 0],
      bidLevel2Price                            |-> [i \in 1 .. 11 |-> 0],
      askLevel2RemainingQuantity                |-> [i \in 1 .. 15 |-> 0],
      bidLevel2RemainingQuantity                |-> [i \in 1 .. 15 |-> 0],
      askLevel2TradingAmount                    |-> [i \in 1 .. 22 |-> 0],
      totalBidLevel2Price                       |-> [i \in 1 .. 11 |-> 0],
      totalBidLevel2RemainingQuantity           |-> [i \in 1 .. 15 |-> 0],
      bidLevel2IncludingGc                      |-> [i \in 1 .. 1 |-> 0],
      askPerTypeLevel2Price                     |-> [i \in 1 .. 11 |-> 0],
      bidPerTypeLevel2Price                     |-> [i \in 1 .. 11 |-> 0],
      askPerTypeLevel2RemainingQuantity         |-> [i \in 1 .. 15 |-> 0],
      bidPerTypeLevel2RemainingQuantity         |-> [i \in 1 .. 15 |-> 0],
      askPerTypeLevel2TradingAmount             |-> [i \in 1 .. 22 |-> 0],
      askLevel3Price                            |-> [i \in 1 .. 11 |-> 0],
      bidLevel3Price                            |-> [i \in 1 .. 11 |-> 0],
      askLevel3RemainingQuantity                |-> [i \in 1 .. 15 |-> 0],
      bidLevel3RemainingQuantity                |-> [i \in 1 .. 15 |-> 0],
      askLevel3TradingAmount                    |-> [i \in 1 .. 22 |-> 0],
      totalBidLevel3Price                       |-> [i \in 1 .. 11 |-> 0],
      totalBidLevel3RemainingQuantity           |-> [i \in 1 .. 15 |-> 0],
      bidLevel3IncludingGc                      |-> [i \in 1 .. 1 |-> 0],
      askPerTypeLevel3Price                     |-> [i \in 1 .. 11 |-> 0],
      bidPerTypeLevel3Price                     |-> [i \in 1 .. 11 |-> 0],
      askPerTypeLevel3RemainingQuantity         |-> [i \in 1 .. 15 |-> 0],
      bidPerTypeLevel3RemainingQuantity         |-> [i \in 1 .. 15 |-> 0],
      askPerTypeLevel3TradingAmount             |-> [i \in 1 .. 22 |-> 0],
      askLevel4Price                            |-> [i \in 1 .. 11 |-> 0],
      bidLevel4Price                            |-> [i \in 1 .. 11 |-> 0],
      askLevel4RemainingQuantity                |-> [i \in 1 .. 15 |-> 0],
      bidLevel4RemainingQuantity                |-> [i \in 1 .. 15 |-> 0],
      askLevel4TradingAmount                    |-> [i \in 1 .. 22 |-> 0],
      totalBidLevel4Price                       |-> [i \in 1 .. 11 |-> 0],
      totalBidLevel4RemainingQuantity           |-> [i \in 1 .. 15 |-> 0],
      bidLevel4IncludingGc                      |-> [i \in 1 .. 1 |-> 0],
      askPerTypeLevel4Price                     |-> [i \in 1 .. 11 |-> 0],
      bidPerTypeLevel4Price                     |-> [i \in 1 .. 11 |-> 0],
      askPerTypeLevel4RemainingQuantity         |-> [i \in 1 .. 15 |-> 0],
      bidPerTypeLevel4RemainingQuantity         |-> [i \in 1 .. 15 |-> 0],
      askPerTypeLevel4TradingAmount             |-> [i \in 1 .. 22 |-> 0],
      askLevel5Price                            |-> [i \in 1 .. 11 |-> 0],
      bidLevel5Price                            |-> [i \in 1 .. 11 |-> 0],
      askLevel5RemainingQuantity                |-> [i \in 1 .. 15 |-> 0],
      bidLevel5RemainingQuantity                |-> [i \in 1 .. 15 |-> 0],
      askLevel5TradingAmount                    |-> [i \in 1 .. 22 |-> 0],
      totalBidLevel5Price                       |-> [i \in 1 .. 11 |-> 0],
      totalBidLevel5RemainingQuantity           |-> [i \in 1 .. 15 |-> 0],
      bidLevel5IncludingGc                      |-> [i \in 1 .. 1 |-> 0],
      askPerTypeLevel5Price                     |-> [i \in 1 .. 11 |-> 0],
      bidPerTypeLevel5Price                     |-> [i \in 1 .. 11 |-> 0],
      askPerTypeLevel5RemainingQuantity         |-> [i \in 1 .. 15 |-> 0],
      bidPerTypeLevel5RemainingQuantity         |-> [i \in 1 .. 15 |-> 0],
      askPerTypeLevel5TradingAmount             |-> [i \in 1 .. 22 |-> 0],
      askTotalRemainingQuantity                 |-> [i \in 1 .. 15 |-> 0],
      bidTotalRemainingQuantity                 |-> [i \in 1 .. 15 |-> 0],
      askPerTypeTotalRemainingQuantity          |-> [i \in 1 .. 15 |-> 0],
      bidPerTypeTotalRemainingQuantity          |-> [i \in 1 .. 15 |-> 0],
      designatedBidLevel1Price                  |-> [i \in 1 .. 11 |-> 0],
      designatedBidLevel1RepoRemainingQuantity  |-> [i \in 1 .. 15 |-> 0],
      designatedBidLevel1Isin                   |-> [i \in 1 .. 12 |-> 0],
      designatedBidLevel2Price                  |-> [i \in 1 .. 11 |-> 0],
      designatedBidLevel2RepoRemainingQuantity  |-> [i \in 1 .. 15 |-> 0],
      designatedBidLevel2Isin                   |-> [i \in 1 .. 12 |-> 0],
      designatedBidLevel3Price                  |-> [i \in 1 .. 11 |-> 0],
      designatedBidLevel3RepoRemainingQuantity  |-> [i \in 1 .. 15 |-> 0],
      designatedBidLevel3Isin                   |-> [i \in 1 .. 12 |-> 0],
      designatedBidLevel4Price                  |-> [i \in 1 .. 11 |-> 0],
      designatedBidLevel4RepoRemainingQuantity  |-> [i \in 1 .. 15 |-> 0],
      designatedBidLevel4Isin                   |-> [i \in 1 .. 12 |-> 0],
      designatedBidLevel5Price                  |-> [i \in 1 .. 11 |-> 0],
      designatedBidLevel5RepoRemainingQuantity  |-> [i \in 1 .. 15 |-> 0],
      designatedBidLevel5Isin                   |-> [i \in 1 .. 12 |-> 0],
      designatedBidLevel6Price                  |-> [i \in 1 .. 11 |-> 0],
      designatedBidLevel6RepoRemainingQuantity  |-> [i \in 1 .. 15 |-> 0],
      designatedBidLevel6Isin                   |-> [i \in 1 .. 12 |-> 0],
      designatedBidLevel7Price                  |-> [i \in 1 .. 11 |-> 0],
      designatedBidLevel7RepoRemainingQuantity  |-> [i \in 1 .. 15 |-> 0],
      designatedBidLevel7Isin                   |-> [i \in 1 .. 12 |-> 0],
      designatedBidLevel8Price                  |-> [i \in 1 .. 11 |-> 0],
      designatedBidLevel8RepoRemainingQuantity  |-> [i \in 1 .. 15 |-> 0],
      designatedBidLevel8Isin                   |-> [i \in 1 .. 12 |-> 0],
      designatedBidLevel9Price                  |-> [i \in 1 .. 11 |-> 0],
      designatedBidLevel9RepoRemainingQuantity  |-> [i \in 1 .. 15 |-> 0],
      designatedBidLevel9Isin                   |-> [i \in 1 .. 12 |-> 0],
      designatedBidLevel10Price                 |-> [i \in 1 .. 11 |-> 0],
      designatedBidLevel10RepoRemainingQuantity |-> [i \in 1 .. 15 |-> 0],
      designatedBidLevel10Isin                  |-> [i \in 1 .. 12 |-> 0],
      designatedBestBidPrice                    |-> [i \in 1 .. 11 |-> 0],
      netBidPerTypeTotalRemainingQuantity       |-> [i \in 1 .. 15 |-> 0],
      endKeyword                                |-> [i \in 1 .. 1 |-> 0] ]

(* Repo Order Filled Plus Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedRepoOrderFilledPlusQuoteMessage ==
    { ZeroRepoOrderFilledPlusQuoteMessage }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.messageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.boardId = one] : one \in Sample(2) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.processingTimeOfTradingSystem = one] : one \in Sample(12) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.tradingPrice = one] : one \in Sample(11) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.tradingVolume = one] : one \in Sample(10) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.tradingDate = one] : one \in Sample(8) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.tradingValue = one] : one \in Sample(22) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.askRepoTypeCode = one] : one \in Sample(2) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.askDurationOfTermRepo = one] : one \in Sample(4) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.bidRepoTypeCode = one] : one \in Sample(2) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.bidDurationOfTermRepo = one] : one \in Sample(4) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.openingPrice = one] : one \in Sample(11) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.todaysHigh = one] : one \in Sample(11) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.todaysLow = one] : one \in Sample(11) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.categoryOpeningPrice = one] : one \in Sample(11) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.categoryTodaysHigh = one] : one \in Sample(11) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.categoryTodaysLow = one] : one \in Sample(11) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.accumulatedTradingVolumeLong = one] : one \in Sample(15) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.accumulatedTradingValueLong = one] : one \in Sample(22) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.categoryAccumulatedTradingVolume = one] : one \in Sample(15) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.categoryAccumulatedTradingValue = one] : one \in Sample(22) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.askLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.bidLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.askLevel1RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.bidLevel1RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.askLevel1TradingAmount = one] : one \in Sample(22) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.totalBidLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.totalBidLevel1RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.bidLevel1IncludingGc = one] : one \in Sample(1) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.askPerTypeLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.bidPerTypeLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.askPerTypeLevel1RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.bidPerTypeLevel1RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.askPerTypeLevel1TradingAmount = one] : one \in Sample(22) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.askLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.bidLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.askLevel2RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.bidLevel2RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.askLevel2TradingAmount = one] : one \in Sample(22) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.totalBidLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.totalBidLevel2RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.bidLevel2IncludingGc = one] : one \in Sample(1) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.askPerTypeLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.bidPerTypeLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.askPerTypeLevel2RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.bidPerTypeLevel2RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.askPerTypeLevel2TradingAmount = one] : one \in Sample(22) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.askLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.bidLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.askLevel3RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.bidLevel3RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.askLevel3TradingAmount = one] : one \in Sample(22) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.totalBidLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.totalBidLevel3RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.bidLevel3IncludingGc = one] : one \in Sample(1) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.askPerTypeLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.bidPerTypeLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.askPerTypeLevel3RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.bidPerTypeLevel3RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.askPerTypeLevel3TradingAmount = one] : one \in Sample(22) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.askLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.bidLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.askLevel4RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.bidLevel4RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.askLevel4TradingAmount = one] : one \in Sample(22) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.totalBidLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.totalBidLevel4RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.bidLevel4IncludingGc = one] : one \in Sample(1) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.askPerTypeLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.bidPerTypeLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.askPerTypeLevel4RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.bidPerTypeLevel4RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.askPerTypeLevel4TradingAmount = one] : one \in Sample(22) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.askLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.bidLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.askLevel5RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.bidLevel5RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.askLevel5TradingAmount = one] : one \in Sample(22) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.totalBidLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.totalBidLevel5RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.bidLevel5IncludingGc = one] : one \in Sample(1) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.askPerTypeLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.bidPerTypeLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.askPerTypeLevel5RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.bidPerTypeLevel5RemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.askPerTypeLevel5TradingAmount = one] : one \in Sample(22) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.askTotalRemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.bidTotalRemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.askPerTypeTotalRemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.bidPerTypeTotalRemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.designatedBidLevel1Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.designatedBidLevel1RepoRemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.designatedBidLevel1Isin = one] : one \in Sample(12) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.designatedBidLevel2Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.designatedBidLevel2RepoRemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.designatedBidLevel2Isin = one] : one \in Sample(12) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.designatedBidLevel3Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.designatedBidLevel3RepoRemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.designatedBidLevel3Isin = one] : one \in Sample(12) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.designatedBidLevel4Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.designatedBidLevel4RepoRemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.designatedBidLevel4Isin = one] : one \in Sample(12) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.designatedBidLevel5Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.designatedBidLevel5RepoRemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.designatedBidLevel5Isin = one] : one \in Sample(12) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.designatedBidLevel6Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.designatedBidLevel6RepoRemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.designatedBidLevel6Isin = one] : one \in Sample(12) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.designatedBidLevel7Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.designatedBidLevel7RepoRemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.designatedBidLevel7Isin = one] : one \in Sample(12) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.designatedBidLevel8Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.designatedBidLevel8RepoRemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.designatedBidLevel8Isin = one] : one \in Sample(12) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.designatedBidLevel9Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.designatedBidLevel9RepoRemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.designatedBidLevel9Isin = one] : one \in Sample(12) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.designatedBidLevel10Price = one] : one \in Sample(11) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.designatedBidLevel10RepoRemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.designatedBidLevel10Isin = one] : one \in Sample(12) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.designatedBestBidPrice = one] : one \in Sample(11) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.netBidPerTypeTotalRemainingQuantity = one] : one \in Sample(15) }
        \cup { [ZeroRepoOrderFilledPlusQuoteMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

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
MarketOperationTsMessageCode == <<65, 55, 48, 49, 83>>  \* "A701S"
MarketOperationTsMessageCode2 == <<65, 55, 48, 50, 83>>  \* "A702S"
MarketOperationTsMessageCode3 == <<65, 55, 48, 51, 83>>  \* "A703S"
MarketOperationTsMessageCode4 == <<65, 55, 48, 52, 83>>  \* "A704S"
MarketOperationTsMessageCode5 == <<65, 55, 48, 53, 83>>  \* "A705S"
MarketOperationTsMessageCode6 == <<65, 55, 48, 49, 81>>  \* "A701Q"
MarketOperationTsMessageCode7 == <<65, 55, 48, 49, 88>>  \* "A701X"
MarketOperationTsMessageCode8 == <<65, 55, 48, 49, 66>>  \* "A701B"
MarketOperationTsMessageCode9 == <<65, 55, 48, 49, 77>>  \* "A701M"
MarketOperationTsMessageCode10 == <<65, 55, 48, 49, 75>>  \* "A701K"
MarketOperationTsMessageCode11 == <<65, 55, 48, 49, 82>>  \* "A701R"
MarketOperationTsMessageCode12 == <<65, 55, 48, 49, 70>>  \* "A701F"
MarketOperationTsMessageCode13 == <<65, 55, 48, 50, 70>>  \* "A702F"
MarketOperationTsMessageCode14 == <<65, 55, 48, 51, 70>>  \* "A703F"
MarketOperationTsMessageCode15 == <<65, 55, 48, 52, 70>>  \* "A704F"
MarketOperationTsMessageCode16 == <<65, 55, 48, 53, 70>>  \* "A705F"
MarketOperationTsMessageCode17 == <<65, 55, 48, 54, 70>>  \* "A706F"
MarketOperationTsMessageCode18 == <<65, 55, 48, 55, 70>>  \* "A707F"
MarketOperationTsMessageCode19 == <<65, 55, 48, 56, 70>>  \* "A708F"
MarketOperationTsMessageCode20 == <<65, 55, 48, 57, 70>>  \* "A709F"
MarketOperationTsMessageCode21 == <<65, 55, 49, 48, 70>>  \* "A710F"
MarketOperationTsMessageCode22 == <<65, 55, 49, 49, 70>>  \* "A711F"
MarketOperationTsMessageCode23 == <<65, 55, 49, 50, 70>>  \* "A712F"
MarketOperationTsMessageCode24 == <<65, 55, 49, 51, 70>>  \* "A713F"
MarketOperationTsMessageCode25 == <<65, 55, 49, 53, 70>>  \* "A715F"
MarketOperationTsMessageCode26 == <<65, 55, 49, 54, 70>>  \* "A716F"
MarketOperationTsMessageCode27 == <<65, 55, 49, 55, 70>>  \* "A717F"
MarketOperationTsMessageCode28 == <<65, 55, 49, 56, 70>>  \* "A718F"
MarketOperationTsMessageCode29 == <<65, 55, 48, 49, 71>>  \* "A701G"
MarketOperationTsMessageCode30 == <<65, 55, 48, 49, 69>>  \* "A701E"
MarketOperationScheduleMessageCode == <<77, 52, 48, 49, 83>>  \* "M401S"
MarketOperationScheduleMessageCode2 == <<77, 52, 48, 50, 83>>  \* "M402S"
MarketOperationScheduleMessageCode3 == <<77, 52, 48, 51, 83>>  \* "M403S"
MarketOperationScheduleMessageCode4 == <<77, 52, 48, 52, 83>>  \* "M404S"
MarketOperationScheduleMessageCode5 == <<77, 52, 48, 53, 83>>  \* "M405S"
MarketOperationScheduleMessageCode6 == <<77, 52, 48, 49, 81>>  \* "M401Q"
MarketOperationScheduleMessageCode7 == <<77, 52, 48, 49, 88>>  \* "M401X"
MarketOperationScheduleMessageCode8 == <<77, 52, 48, 49, 66>>  \* "M401B"
MarketOperationScheduleMessageCode9 == <<77, 52, 48, 49, 77>>  \* "M401M"
MarketOperationScheduleMessageCode10 == <<77, 52, 48, 49, 75>>  \* "M401K"
MarketOperationScheduleMessageCode11 == <<77, 52, 48, 49, 82>>  \* "M401R"
MarketOperationScheduleMessageCode12 == <<77, 52, 48, 49, 70>>  \* "M401F"
MarketOperationScheduleMessageCode13 == <<77, 52, 48, 50, 70>>  \* "M402F"
MarketOperationScheduleMessageCode14 == <<77, 52, 48, 51, 70>>  \* "M403F"
MarketOperationScheduleMessageCode15 == <<77, 52, 48, 52, 70>>  \* "M404F"
MarketOperationScheduleMessageCode16 == <<77, 52, 48, 53, 70>>  \* "M405F"
MarketOperationScheduleMessageCode17 == <<77, 52, 48, 54, 70>>  \* "M406F"
MarketOperationScheduleMessageCode18 == <<77, 52, 48, 55, 70>>  \* "M407F"
MarketOperationScheduleMessageCode19 == <<77, 52, 48, 56, 70>>  \* "M408F"
MarketOperationScheduleMessageCode20 == <<77, 52, 48, 57, 70>>  \* "M409F"
MarketOperationScheduleMessageCode21 == <<77, 52, 49, 48, 70>>  \* "M410F"
MarketOperationScheduleMessageCode22 == <<77, 52, 49, 49, 70>>  \* "M411F"
MarketOperationScheduleMessageCode23 == <<77, 52, 49, 50, 70>>  \* "M412F"
MarketOperationScheduleMessageCode24 == <<77, 52, 49, 51, 70>>  \* "M413F"
MarketOperationScheduleMessageCode25 == <<77, 52, 49, 53, 70>>  \* "M415F"
MarketOperationScheduleMessageCode26 == <<77, 52, 49, 54, 70>>  \* "M416F"
MarketOperationScheduleMessageCode27 == <<77, 52, 49, 55, 70>>  \* "M417F"
MarketOperationScheduleMessageCode28 == <<77, 52, 49, 56, 70>>  \* "M418F"
MarketOperationScheduleMessageCode29 == <<77, 52, 48, 49, 71>>  \* "M401G"
MarketOperationScheduleMessageCode30 == <<77, 52, 48, 49, 69>>  \* "M401E"
IssueClosingMessageCode == <<65, 54, 48, 49, 66>>  \* "A601B"
IssueClosingMessageCode2 == <<65, 54, 48, 49, 77>>  \* "A601M"
IssueClosingMessageCode3 == <<65, 54, 48, 49, 75>>  \* "A601K"
IssueClosingMessageCode4 == <<65, 54, 48, 49, 82>>  \* "A601R"
MemberFirmSanctionsMessageCode == <<82, 51, 48, 49, 83>>  \* "R301S"
MemberFirmSanctionsMessageCode2 == <<82, 51, 48, 50, 83>>  \* "R302S"
MemberFirmSanctionsMessageCode3 == <<82, 51, 48, 51, 83>>  \* "R303S"
MemberFirmSanctionsMessageCode4 == <<82, 51, 48, 52, 83>>  \* "R304S"
MemberFirmSanctionsMessageCode5 == <<82, 51, 48, 53, 83>>  \* "R305S"
MemberFirmSanctionsMessageCode6 == <<82, 51, 48, 49, 81>>  \* "R301Q"
MemberFirmSanctionsMessageCode7 == <<82, 51, 48, 49, 88>>  \* "R301X"
MemberFirmSanctionsMessageCode8 == <<82, 51, 48, 49, 66>>  \* "R301B"
MemberFirmSanctionsMessageCode9 == <<82, 51, 48, 49, 77>>  \* "R301M"
MemberFirmSanctionsMessageCode10 == <<82, 51, 48, 49, 75>>  \* "R301K"
MemberFirmSanctionsMessageCode11 == <<82, 51, 48, 49, 82>>  \* "R301R"
RegularBondsKtbQuoteMessageCode == <<66, 54, 48, 49, 66>>  \* "B601B"
RegularBondsKtbQuoteMessageCode2 == <<66, 54, 48, 49, 75>>  \* "B601K"
BondsOrderFilledMessageCode == <<65, 51, 48, 49, 66>>  \* "A301B"
BondsOrderFilledMessageCode2 == <<65, 51, 48, 49, 77>>  \* "A301M"
BondsOrderFilledMessageCode3 == <<65, 51, 48, 49, 75>>  \* "A301K"
GeneralBondsKtbOrderFilledPlusQuoteMessageCode == <<71, 55, 48, 49, 66>>  \* "G701B"
GeneralBondsKtbOrderFilledPlusQuoteMessageCode2 == <<71, 55, 48, 49, 75>>  \* "G701K"
BondsNegotiatedTradeDataMessageCode == <<67, 52, 48, 49, 66>>  \* "C401B"
BondsNegotiatedTradeDataMessageCode2 == <<67, 52, 48, 49, 75>>  \* "C401K"
RepoNegotiatedTradeDataMessageCode == <<67, 52, 48, 49, 82>>  \* "C401R"
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
BabyBondsReportingMarketYieldMessageCode == <<71, 48, 48, 49, 77>>  \* "G001M"
KtbConfirmedInfoForWitMessageCode == <<80, 65, 48, 49, 75>>  \* "PA01K"
KtbShortTermYieldMessageCode == <<80, 66, 48, 49, 75>>  \* "PB01K"
KtbAverageYieldMessageCode == <<80, 67, 48, 49, 75>>  \* "PC01K"
BondsCreditRatingInformationMessageCode == <<74, 65, 48, 55, 55>>  \* "JA077"
RegularBondsDisclosureBasicExchangeRateMessageCode == <<82, 52, 48, 49, 66>>  \* "R401B"
InvestorActivitiesPerBondTypesMessageCode == <<80, 52, 48, 49, 66>>  \* "P401B"
InvestorActivitiesPerBondTypesMessageCode2 == <<80, 52, 48, 49, 77>>  \* "P401M"
InvestorActivitiesPerBondTypesMessageCode3 == <<80, 52, 48, 49, 75>>  \* "P401K"
BondsIsinIssueInformationMessageCode == <<74, 57, 48, 55, 55>>  \* "J9077"
BondsIsinInformationTextMessageCode == <<74, 66, 48, 55, 55>>  \* "JB077"
BabyBondsQuoteMessageCode == <<66, 54, 48, 49, 77>>  \* "B601M"
RepoQuoteMessageCode == <<66, 54, 48, 49, 82>>  \* "B601R"
BondsTotalRemainingVolumeOnQuotesMessageCode == <<79, 65, 48, 49, 66>>  \* "OA01B"
BondsTotalRemainingVolumeOnQuotesMessageCode2 == <<79, 65, 48, 49, 77>>  \* "OA01M"
BabyBondsOrderFilledPlusQuoteMessageCode == <<71, 55, 48, 49, 77>>  \* "G701M"
RepoOrderFilledPlusQuoteMessageCode == <<71, 55, 48, 49, 82>>  \* "G701R"

Payload ==
    [ tag : {PollingDataMessageCode}, body : PollingDataMessage ]
        \cup [ tag : {KrxIndexMessageCode}, body : KrxIndexMessage ]
        \cup [ tag : {KrxEstimatedIndexMessageCode}, body : KrxEstimatedIndexMessage ]
        \cup [ tag : {GlobalIndexMessageCode}, body : GlobalIndexMessage ]
        \cup [ tag : {BondPrimeIndexMessageCode}, body : BondPrimeIndexMessage ]
        \cup [ tag : {BondKtbIndexMessageCode}, body : BondKtbIndexMessage ]
        \cup [ tag : {BondKtbIndexTermStructureMessageCode}, body : BondKtbIndexTermStructureMessage ]
        \cup [ tag : {BondIndexKrxMessageCode}, body : BondIndexKrxMessage ]
        \cup [ tag : {MarketOperationTsMessageCode}, body : MarketOperationTsMessage ]
        \cup [ tag : {MarketOperationTsMessageCode2}, body : MarketOperationTsMessage ]
        \cup [ tag : {MarketOperationTsMessageCode3}, body : MarketOperationTsMessage ]
        \cup [ tag : {MarketOperationTsMessageCode4}, body : MarketOperationTsMessage ]
        \cup [ tag : {MarketOperationTsMessageCode5}, body : MarketOperationTsMessage ]
        \cup [ tag : {MarketOperationTsMessageCode6}, body : MarketOperationTsMessage ]
        \cup [ tag : {MarketOperationTsMessageCode7}, body : MarketOperationTsMessage ]
        \cup [ tag : {MarketOperationTsMessageCode8}, body : MarketOperationTsMessage ]
        \cup [ tag : {MarketOperationTsMessageCode9}, body : MarketOperationTsMessage ]
        \cup [ tag : {MarketOperationTsMessageCode10}, body : MarketOperationTsMessage ]
        \cup [ tag : {MarketOperationTsMessageCode11}, body : MarketOperationTsMessage ]
        \cup [ tag : {MarketOperationTsMessageCode12}, body : MarketOperationTsMessage ]
        \cup [ tag : {MarketOperationTsMessageCode13}, body : MarketOperationTsMessage ]
        \cup [ tag : {MarketOperationTsMessageCode14}, body : MarketOperationTsMessage ]
        \cup [ tag : {MarketOperationTsMessageCode15}, body : MarketOperationTsMessage ]
        \cup [ tag : {MarketOperationTsMessageCode16}, body : MarketOperationTsMessage ]
        \cup [ tag : {MarketOperationTsMessageCode17}, body : MarketOperationTsMessage ]
        \cup [ tag : {MarketOperationTsMessageCode18}, body : MarketOperationTsMessage ]
        \cup [ tag : {MarketOperationTsMessageCode19}, body : MarketOperationTsMessage ]
        \cup [ tag : {MarketOperationTsMessageCode20}, body : MarketOperationTsMessage ]
        \cup [ tag : {MarketOperationTsMessageCode21}, body : MarketOperationTsMessage ]
        \cup [ tag : {MarketOperationTsMessageCode22}, body : MarketOperationTsMessage ]
        \cup [ tag : {MarketOperationTsMessageCode23}, body : MarketOperationTsMessage ]
        \cup [ tag : {MarketOperationTsMessageCode24}, body : MarketOperationTsMessage ]
        \cup [ tag : {MarketOperationTsMessageCode25}, body : MarketOperationTsMessage ]
        \cup [ tag : {MarketOperationTsMessageCode26}, body : MarketOperationTsMessage ]
        \cup [ tag : {MarketOperationTsMessageCode27}, body : MarketOperationTsMessage ]
        \cup [ tag : {MarketOperationTsMessageCode28}, body : MarketOperationTsMessage ]
        \cup [ tag : {MarketOperationTsMessageCode29}, body : MarketOperationTsMessage ]
        \cup [ tag : {MarketOperationTsMessageCode30}, body : MarketOperationTsMessage ]
        \cup [ tag : {MarketOperationScheduleMessageCode}, body : MarketOperationScheduleMessage ]
        \cup [ tag : {MarketOperationScheduleMessageCode2}, body : MarketOperationScheduleMessage ]
        \cup [ tag : {MarketOperationScheduleMessageCode3}, body : MarketOperationScheduleMessage ]
        \cup [ tag : {MarketOperationScheduleMessageCode4}, body : MarketOperationScheduleMessage ]
        \cup [ tag : {MarketOperationScheduleMessageCode5}, body : MarketOperationScheduleMessage ]
        \cup [ tag : {MarketOperationScheduleMessageCode6}, body : MarketOperationScheduleMessage ]
        \cup [ tag : {MarketOperationScheduleMessageCode7}, body : MarketOperationScheduleMessage ]
        \cup [ tag : {MarketOperationScheduleMessageCode8}, body : MarketOperationScheduleMessage ]
        \cup [ tag : {MarketOperationScheduleMessageCode9}, body : MarketOperationScheduleMessage ]
        \cup [ tag : {MarketOperationScheduleMessageCode10}, body : MarketOperationScheduleMessage ]
        \cup [ tag : {MarketOperationScheduleMessageCode11}, body : MarketOperationScheduleMessage ]
        \cup [ tag : {MarketOperationScheduleMessageCode12}, body : MarketOperationScheduleMessage ]
        \cup [ tag : {MarketOperationScheduleMessageCode13}, body : MarketOperationScheduleMessage ]
        \cup [ tag : {MarketOperationScheduleMessageCode14}, body : MarketOperationScheduleMessage ]
        \cup [ tag : {MarketOperationScheduleMessageCode15}, body : MarketOperationScheduleMessage ]
        \cup [ tag : {MarketOperationScheduleMessageCode16}, body : MarketOperationScheduleMessage ]
        \cup [ tag : {MarketOperationScheduleMessageCode17}, body : MarketOperationScheduleMessage ]
        \cup [ tag : {MarketOperationScheduleMessageCode18}, body : MarketOperationScheduleMessage ]
        \cup [ tag : {MarketOperationScheduleMessageCode19}, body : MarketOperationScheduleMessage ]
        \cup [ tag : {MarketOperationScheduleMessageCode20}, body : MarketOperationScheduleMessage ]
        \cup [ tag : {MarketOperationScheduleMessageCode21}, body : MarketOperationScheduleMessage ]
        \cup [ tag : {MarketOperationScheduleMessageCode22}, body : MarketOperationScheduleMessage ]
        \cup [ tag : {MarketOperationScheduleMessageCode23}, body : MarketOperationScheduleMessage ]
        \cup [ tag : {MarketOperationScheduleMessageCode24}, body : MarketOperationScheduleMessage ]
        \cup [ tag : {MarketOperationScheduleMessageCode25}, body : MarketOperationScheduleMessage ]
        \cup [ tag : {MarketOperationScheduleMessageCode26}, body : MarketOperationScheduleMessage ]
        \cup [ tag : {MarketOperationScheduleMessageCode27}, body : MarketOperationScheduleMessage ]
        \cup [ tag : {MarketOperationScheduleMessageCode28}, body : MarketOperationScheduleMessage ]
        \cup [ tag : {MarketOperationScheduleMessageCode29}, body : MarketOperationScheduleMessage ]
        \cup [ tag : {MarketOperationScheduleMessageCode30}, body : MarketOperationScheduleMessage ]
        \cup [ tag : {IssueClosingMessageCode}, body : IssueClosingMessage ]
        \cup [ tag : {IssueClosingMessageCode2}, body : IssueClosingMessage ]
        \cup [ tag : {IssueClosingMessageCode3}, body : IssueClosingMessage ]
        \cup [ tag : {IssueClosingMessageCode4}, body : IssueClosingMessage ]
        \cup [ tag : {MemberFirmSanctionsMessageCode}, body : MemberFirmSanctionsMessage ]
        \cup [ tag : {MemberFirmSanctionsMessageCode2}, body : MemberFirmSanctionsMessage ]
        \cup [ tag : {MemberFirmSanctionsMessageCode3}, body : MemberFirmSanctionsMessage ]
        \cup [ tag : {MemberFirmSanctionsMessageCode4}, body : MemberFirmSanctionsMessage ]
        \cup [ tag : {MemberFirmSanctionsMessageCode5}, body : MemberFirmSanctionsMessage ]
        \cup [ tag : {MemberFirmSanctionsMessageCode6}, body : MemberFirmSanctionsMessage ]
        \cup [ tag : {MemberFirmSanctionsMessageCode7}, body : MemberFirmSanctionsMessage ]
        \cup [ tag : {MemberFirmSanctionsMessageCode8}, body : MemberFirmSanctionsMessage ]
        \cup [ tag : {MemberFirmSanctionsMessageCode9}, body : MemberFirmSanctionsMessage ]
        \cup [ tag : {MemberFirmSanctionsMessageCode10}, body : MemberFirmSanctionsMessage ]
        \cup [ tag : {MemberFirmSanctionsMessageCode11}, body : MemberFirmSanctionsMessage ]
        \cup [ tag : {RegularBondsKtbQuoteMessageCode}, body : RegularBondsKtbQuoteMessage ]
        \cup [ tag : {RegularBondsKtbQuoteMessageCode2}, body : RegularBondsKtbQuoteMessage ]
        \cup [ tag : {BondsOrderFilledMessageCode}, body : BondsOrderFilledMessage ]
        \cup [ tag : {BondsOrderFilledMessageCode2}, body : BondsOrderFilledMessage ]
        \cup [ tag : {BondsOrderFilledMessageCode3}, body : BondsOrderFilledMessage ]
        \cup [ tag : {GeneralBondsKtbOrderFilledPlusQuoteMessageCode}, body : GeneralBondsKtbOrderFilledPlusQuoteMessage ]
        \cup [ tag : {GeneralBondsKtbOrderFilledPlusQuoteMessageCode2}, body : GeneralBondsKtbOrderFilledPlusQuoteMessage ]
        \cup [ tag : {BondsNegotiatedTradeDataMessageCode}, body : BondsNegotiatedTradeDataMessage ]
        \cup [ tag : {BondsNegotiatedTradeDataMessageCode2}, body : BondsNegotiatedTradeDataMessage ]
        \cup [ tag : {RepoNegotiatedTradeDataMessageCode}, body : RepoNegotiatedTradeDataMessage ]
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
        \cup [ tag : {BabyBondsReportingMarketYieldMessageCode}, body : BabyBondsReportingMarketYieldMessage ]
        \cup [ tag : {KtbConfirmedInfoForWitMessageCode}, body : KtbConfirmedInfoForWitMessage ]
        \cup [ tag : {KtbShortTermYieldMessageCode}, body : KtbShortTermYieldMessage ]
        \cup [ tag : {KtbAverageYieldMessageCode}, body : KtbAverageYieldMessage ]
        \cup [ tag : {BondsCreditRatingInformationMessageCode}, body : BondsCreditRatingInformationMessage ]
        \cup [ tag : {RegularBondsDisclosureBasicExchangeRateMessageCode}, body : RegularBondsDisclosureBasicExchangeRateMessage ]
        \cup [ tag : {InvestorActivitiesPerBondTypesMessageCode}, body : InvestorActivitiesPerBondTypesMessage ]
        \cup [ tag : {InvestorActivitiesPerBondTypesMessageCode2}, body : InvestorActivitiesPerBondTypesMessage ]
        \cup [ tag : {InvestorActivitiesPerBondTypesMessageCode3}, body : InvestorActivitiesPerBondTypesMessage ]
        \cup [ tag : {BondsIsinIssueInformationMessageCode}, body : BondsIsinIssueInformationMessage ]
        \cup [ tag : {BondsIsinInformationTextMessageCode}, body : BondsIsinInformationTextMessage ]
        \cup [ tag : {BabyBondsQuoteMessageCode}, body : BabyBondsQuoteMessage ]
        \cup [ tag : {RepoQuoteMessageCode}, body : RepoQuoteMessage ]
        \cup [ tag : {BondsTotalRemainingVolumeOnQuotesMessageCode}, body : BondsTotalRemainingVolumeOnQuotesMessage ]
        \cup [ tag : {BondsTotalRemainingVolumeOnQuotesMessageCode2}, body : BondsTotalRemainingVolumeOnQuotesMessage ]
        \cup [ tag : {BabyBondsOrderFilledPlusQuoteMessageCode}, body : BabyBondsOrderFilledPlusQuoteMessage ]
        \cup [ tag : {RepoOrderFilledPlusQuoteMessageCode}, body : RepoOrderFilledPlusQuoteMessage ]

EncodePayload(message) ==
    CASE message.tag = PollingDataMessageCode -> EncodePollingDataMessage(message.body)
      [] message.tag = KrxIndexMessageCode -> EncodeKrxIndexMessage(message.body)
      [] message.tag = KrxEstimatedIndexMessageCode -> EncodeKrxEstimatedIndexMessage(message.body)
      [] message.tag = GlobalIndexMessageCode -> EncodeGlobalIndexMessage(message.body)
      [] message.tag = BondPrimeIndexMessageCode -> EncodeBondPrimeIndexMessage(message.body)
      [] message.tag = BondKtbIndexMessageCode -> EncodeBondKtbIndexMessage(message.body)
      [] message.tag = BondKtbIndexTermStructureMessageCode -> EncodeBondKtbIndexTermStructureMessage(message.body)
      [] message.tag = BondIndexKrxMessageCode -> EncodeBondIndexKrxMessage(message.body)
      [] message.tag = MarketOperationTsMessageCode -> EncodeMarketOperationTsMessage(message.body)
      [] message.tag = MarketOperationTsMessageCode2 -> EncodeMarketOperationTsMessage(message.body)
      [] message.tag = MarketOperationTsMessageCode3 -> EncodeMarketOperationTsMessage(message.body)
      [] message.tag = MarketOperationTsMessageCode4 -> EncodeMarketOperationTsMessage(message.body)
      [] message.tag = MarketOperationTsMessageCode5 -> EncodeMarketOperationTsMessage(message.body)
      [] message.tag = MarketOperationTsMessageCode6 -> EncodeMarketOperationTsMessage(message.body)
      [] message.tag = MarketOperationTsMessageCode7 -> EncodeMarketOperationTsMessage(message.body)
      [] message.tag = MarketOperationTsMessageCode8 -> EncodeMarketOperationTsMessage(message.body)
      [] message.tag = MarketOperationTsMessageCode9 -> EncodeMarketOperationTsMessage(message.body)
      [] message.tag = MarketOperationTsMessageCode10 -> EncodeMarketOperationTsMessage(message.body)
      [] message.tag = MarketOperationTsMessageCode11 -> EncodeMarketOperationTsMessage(message.body)
      [] message.tag = MarketOperationTsMessageCode12 -> EncodeMarketOperationTsMessage(message.body)
      [] message.tag = MarketOperationTsMessageCode13 -> EncodeMarketOperationTsMessage(message.body)
      [] message.tag = MarketOperationTsMessageCode14 -> EncodeMarketOperationTsMessage(message.body)
      [] message.tag = MarketOperationTsMessageCode15 -> EncodeMarketOperationTsMessage(message.body)
      [] message.tag = MarketOperationTsMessageCode16 -> EncodeMarketOperationTsMessage(message.body)
      [] message.tag = MarketOperationTsMessageCode17 -> EncodeMarketOperationTsMessage(message.body)
      [] message.tag = MarketOperationTsMessageCode18 -> EncodeMarketOperationTsMessage(message.body)
      [] message.tag = MarketOperationTsMessageCode19 -> EncodeMarketOperationTsMessage(message.body)
      [] message.tag = MarketOperationTsMessageCode20 -> EncodeMarketOperationTsMessage(message.body)
      [] message.tag = MarketOperationTsMessageCode21 -> EncodeMarketOperationTsMessage(message.body)
      [] message.tag = MarketOperationTsMessageCode22 -> EncodeMarketOperationTsMessage(message.body)
      [] message.tag = MarketOperationTsMessageCode23 -> EncodeMarketOperationTsMessage(message.body)
      [] message.tag = MarketOperationTsMessageCode24 -> EncodeMarketOperationTsMessage(message.body)
      [] message.tag = MarketOperationTsMessageCode25 -> EncodeMarketOperationTsMessage(message.body)
      [] message.tag = MarketOperationTsMessageCode26 -> EncodeMarketOperationTsMessage(message.body)
      [] message.tag = MarketOperationTsMessageCode27 -> EncodeMarketOperationTsMessage(message.body)
      [] message.tag = MarketOperationTsMessageCode28 -> EncodeMarketOperationTsMessage(message.body)
      [] message.tag = MarketOperationTsMessageCode29 -> EncodeMarketOperationTsMessage(message.body)
      [] message.tag = MarketOperationTsMessageCode30 -> EncodeMarketOperationTsMessage(message.body)
      [] message.tag = MarketOperationScheduleMessageCode -> EncodeMarketOperationScheduleMessage(message.body)
      [] message.tag = MarketOperationScheduleMessageCode2 -> EncodeMarketOperationScheduleMessage(message.body)
      [] message.tag = MarketOperationScheduleMessageCode3 -> EncodeMarketOperationScheduleMessage(message.body)
      [] message.tag = MarketOperationScheduleMessageCode4 -> EncodeMarketOperationScheduleMessage(message.body)
      [] message.tag = MarketOperationScheduleMessageCode5 -> EncodeMarketOperationScheduleMessage(message.body)
      [] message.tag = MarketOperationScheduleMessageCode6 -> EncodeMarketOperationScheduleMessage(message.body)
      [] message.tag = MarketOperationScheduleMessageCode7 -> EncodeMarketOperationScheduleMessage(message.body)
      [] message.tag = MarketOperationScheduleMessageCode8 -> EncodeMarketOperationScheduleMessage(message.body)
      [] message.tag = MarketOperationScheduleMessageCode9 -> EncodeMarketOperationScheduleMessage(message.body)
      [] message.tag = MarketOperationScheduleMessageCode10 -> EncodeMarketOperationScheduleMessage(message.body)
      [] message.tag = MarketOperationScheduleMessageCode11 -> EncodeMarketOperationScheduleMessage(message.body)
      [] message.tag = MarketOperationScheduleMessageCode12 -> EncodeMarketOperationScheduleMessage(message.body)
      [] message.tag = MarketOperationScheduleMessageCode13 -> EncodeMarketOperationScheduleMessage(message.body)
      [] message.tag = MarketOperationScheduleMessageCode14 -> EncodeMarketOperationScheduleMessage(message.body)
      [] message.tag = MarketOperationScheduleMessageCode15 -> EncodeMarketOperationScheduleMessage(message.body)
      [] message.tag = MarketOperationScheduleMessageCode16 -> EncodeMarketOperationScheduleMessage(message.body)
      [] message.tag = MarketOperationScheduleMessageCode17 -> EncodeMarketOperationScheduleMessage(message.body)
      [] message.tag = MarketOperationScheduleMessageCode18 -> EncodeMarketOperationScheduleMessage(message.body)
      [] message.tag = MarketOperationScheduleMessageCode19 -> EncodeMarketOperationScheduleMessage(message.body)
      [] message.tag = MarketOperationScheduleMessageCode20 -> EncodeMarketOperationScheduleMessage(message.body)
      [] message.tag = MarketOperationScheduleMessageCode21 -> EncodeMarketOperationScheduleMessage(message.body)
      [] message.tag = MarketOperationScheduleMessageCode22 -> EncodeMarketOperationScheduleMessage(message.body)
      [] message.tag = MarketOperationScheduleMessageCode23 -> EncodeMarketOperationScheduleMessage(message.body)
      [] message.tag = MarketOperationScheduleMessageCode24 -> EncodeMarketOperationScheduleMessage(message.body)
      [] message.tag = MarketOperationScheduleMessageCode25 -> EncodeMarketOperationScheduleMessage(message.body)
      [] message.tag = MarketOperationScheduleMessageCode26 -> EncodeMarketOperationScheduleMessage(message.body)
      [] message.tag = MarketOperationScheduleMessageCode27 -> EncodeMarketOperationScheduleMessage(message.body)
      [] message.tag = MarketOperationScheduleMessageCode28 -> EncodeMarketOperationScheduleMessage(message.body)
      [] message.tag = MarketOperationScheduleMessageCode29 -> EncodeMarketOperationScheduleMessage(message.body)
      [] message.tag = MarketOperationScheduleMessageCode30 -> EncodeMarketOperationScheduleMessage(message.body)
      [] message.tag = IssueClosingMessageCode -> EncodeIssueClosingMessage(message.body)
      [] message.tag = IssueClosingMessageCode2 -> EncodeIssueClosingMessage(message.body)
      [] message.tag = IssueClosingMessageCode3 -> EncodeIssueClosingMessage(message.body)
      [] message.tag = IssueClosingMessageCode4 -> EncodeIssueClosingMessage(message.body)
      [] message.tag = MemberFirmSanctionsMessageCode -> EncodeMemberFirmSanctionsMessage(message.body)
      [] message.tag = MemberFirmSanctionsMessageCode2 -> EncodeMemberFirmSanctionsMessage(message.body)
      [] message.tag = MemberFirmSanctionsMessageCode3 -> EncodeMemberFirmSanctionsMessage(message.body)
      [] message.tag = MemberFirmSanctionsMessageCode4 -> EncodeMemberFirmSanctionsMessage(message.body)
      [] message.tag = MemberFirmSanctionsMessageCode5 -> EncodeMemberFirmSanctionsMessage(message.body)
      [] message.tag = MemberFirmSanctionsMessageCode6 -> EncodeMemberFirmSanctionsMessage(message.body)
      [] message.tag = MemberFirmSanctionsMessageCode7 -> EncodeMemberFirmSanctionsMessage(message.body)
      [] message.tag = MemberFirmSanctionsMessageCode8 -> EncodeMemberFirmSanctionsMessage(message.body)
      [] message.tag = MemberFirmSanctionsMessageCode9 -> EncodeMemberFirmSanctionsMessage(message.body)
      [] message.tag = MemberFirmSanctionsMessageCode10 -> EncodeMemberFirmSanctionsMessage(message.body)
      [] message.tag = MemberFirmSanctionsMessageCode11 -> EncodeMemberFirmSanctionsMessage(message.body)
      [] message.tag = RegularBondsKtbQuoteMessageCode -> EncodeRegularBondsKtbQuoteMessage(message.body)
      [] message.tag = RegularBondsKtbQuoteMessageCode2 -> EncodeRegularBondsKtbQuoteMessage(message.body)
      [] message.tag = BondsOrderFilledMessageCode -> EncodeBondsOrderFilledMessage(message.body)
      [] message.tag = BondsOrderFilledMessageCode2 -> EncodeBondsOrderFilledMessage(message.body)
      [] message.tag = BondsOrderFilledMessageCode3 -> EncodeBondsOrderFilledMessage(message.body)
      [] message.tag = GeneralBondsKtbOrderFilledPlusQuoteMessageCode -> EncodeGeneralBondsKtbOrderFilledPlusQuoteMessage(message.body)
      [] message.tag = GeneralBondsKtbOrderFilledPlusQuoteMessageCode2 -> EncodeGeneralBondsKtbOrderFilledPlusQuoteMessage(message.body)
      [] message.tag = BondsNegotiatedTradeDataMessageCode -> EncodeBondsNegotiatedTradeDataMessage(message.body)
      [] message.tag = BondsNegotiatedTradeDataMessageCode2 -> EncodeBondsNegotiatedTradeDataMessage(message.body)
      [] message.tag = RepoNegotiatedTradeDataMessageCode -> EncodeRepoNegotiatedTradeDataMessage(message.body)
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
      [] message.tag = BabyBondsReportingMarketYieldMessageCode -> EncodeBabyBondsReportingMarketYieldMessage(message.body)
      [] message.tag = KtbConfirmedInfoForWitMessageCode -> EncodeKtbConfirmedInfoForWitMessage(message.body)
      [] message.tag = KtbShortTermYieldMessageCode -> EncodeKtbShortTermYieldMessage(message.body)
      [] message.tag = KtbAverageYieldMessageCode -> EncodeKtbAverageYieldMessage(message.body)
      [] message.tag = BondsCreditRatingInformationMessageCode -> EncodeBondsCreditRatingInformationMessage(message.body)
      [] message.tag = RegularBondsDisclosureBasicExchangeRateMessageCode -> EncodeRegularBondsDisclosureBasicExchangeRateMessage(message.body)
      [] message.tag = InvestorActivitiesPerBondTypesMessageCode -> EncodeInvestorActivitiesPerBondTypesMessage(message.body)
      [] message.tag = InvestorActivitiesPerBondTypesMessageCode2 -> EncodeInvestorActivitiesPerBondTypesMessage(message.body)
      [] message.tag = InvestorActivitiesPerBondTypesMessageCode3 -> EncodeInvestorActivitiesPerBondTypesMessage(message.body)
      [] message.tag = BondsIsinIssueInformationMessageCode -> EncodeBondsIsinIssueInformationMessage(message.body)
      [] message.tag = BondsIsinInformationTextMessageCode -> EncodeBondsIsinInformationTextMessage(message.body)
      [] message.tag = BabyBondsQuoteMessageCode -> EncodeBabyBondsQuoteMessage(message.body)
      [] message.tag = RepoQuoteMessageCode -> EncodeRepoQuoteMessage(message.body)
      [] message.tag = BondsTotalRemainingVolumeOnQuotesMessageCode -> EncodeBondsTotalRemainingVolumeOnQuotesMessage(message.body)
      [] message.tag = BondsTotalRemainingVolumeOnQuotesMessageCode2 -> EncodeBondsTotalRemainingVolumeOnQuotesMessage(message.body)
      [] message.tag = BabyBondsOrderFilledPlusQuoteMessageCode -> EncodeBabyBondsOrderFilledPlusQuoteMessage(message.body)
      [] message.tag = RepoOrderFilledPlusQuoteMessageCode -> EncodeRepoOrderFilledPlusQuoteMessage(message.body)

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
              [] tag = MarketOperationTsMessageCode -> DecodeMarketOperationTsMessage(bytes)
              [] tag = MarketOperationTsMessageCode2 -> DecodeMarketOperationTsMessage(bytes)
              [] tag = MarketOperationTsMessageCode3 -> DecodeMarketOperationTsMessage(bytes)
              [] tag = MarketOperationTsMessageCode4 -> DecodeMarketOperationTsMessage(bytes)
              [] tag = MarketOperationTsMessageCode5 -> DecodeMarketOperationTsMessage(bytes)
              [] tag = MarketOperationTsMessageCode6 -> DecodeMarketOperationTsMessage(bytes)
              [] tag = MarketOperationTsMessageCode7 -> DecodeMarketOperationTsMessage(bytes)
              [] tag = MarketOperationTsMessageCode8 -> DecodeMarketOperationTsMessage(bytes)
              [] tag = MarketOperationTsMessageCode9 -> DecodeMarketOperationTsMessage(bytes)
              [] tag = MarketOperationTsMessageCode10 -> DecodeMarketOperationTsMessage(bytes)
              [] tag = MarketOperationTsMessageCode11 -> DecodeMarketOperationTsMessage(bytes)
              [] tag = MarketOperationTsMessageCode12 -> DecodeMarketOperationTsMessage(bytes)
              [] tag = MarketOperationTsMessageCode13 -> DecodeMarketOperationTsMessage(bytes)
              [] tag = MarketOperationTsMessageCode14 -> DecodeMarketOperationTsMessage(bytes)
              [] tag = MarketOperationTsMessageCode15 -> DecodeMarketOperationTsMessage(bytes)
              [] tag = MarketOperationTsMessageCode16 -> DecodeMarketOperationTsMessage(bytes)
              [] tag = MarketOperationTsMessageCode17 -> DecodeMarketOperationTsMessage(bytes)
              [] tag = MarketOperationTsMessageCode18 -> DecodeMarketOperationTsMessage(bytes)
              [] tag = MarketOperationTsMessageCode19 -> DecodeMarketOperationTsMessage(bytes)
              [] tag = MarketOperationTsMessageCode20 -> DecodeMarketOperationTsMessage(bytes)
              [] tag = MarketOperationTsMessageCode21 -> DecodeMarketOperationTsMessage(bytes)
              [] tag = MarketOperationTsMessageCode22 -> DecodeMarketOperationTsMessage(bytes)
              [] tag = MarketOperationTsMessageCode23 -> DecodeMarketOperationTsMessage(bytes)
              [] tag = MarketOperationTsMessageCode24 -> DecodeMarketOperationTsMessage(bytes)
              [] tag = MarketOperationTsMessageCode25 -> DecodeMarketOperationTsMessage(bytes)
              [] tag = MarketOperationTsMessageCode26 -> DecodeMarketOperationTsMessage(bytes)
              [] tag = MarketOperationTsMessageCode27 -> DecodeMarketOperationTsMessage(bytes)
              [] tag = MarketOperationTsMessageCode28 -> DecodeMarketOperationTsMessage(bytes)
              [] tag = MarketOperationTsMessageCode29 -> DecodeMarketOperationTsMessage(bytes)
              [] tag = MarketOperationTsMessageCode30 -> DecodeMarketOperationTsMessage(bytes)
              [] tag = MarketOperationScheduleMessageCode -> DecodeMarketOperationScheduleMessage(bytes)
              [] tag = MarketOperationScheduleMessageCode2 -> DecodeMarketOperationScheduleMessage(bytes)
              [] tag = MarketOperationScheduleMessageCode3 -> DecodeMarketOperationScheduleMessage(bytes)
              [] tag = MarketOperationScheduleMessageCode4 -> DecodeMarketOperationScheduleMessage(bytes)
              [] tag = MarketOperationScheduleMessageCode5 -> DecodeMarketOperationScheduleMessage(bytes)
              [] tag = MarketOperationScheduleMessageCode6 -> DecodeMarketOperationScheduleMessage(bytes)
              [] tag = MarketOperationScheduleMessageCode7 -> DecodeMarketOperationScheduleMessage(bytes)
              [] tag = MarketOperationScheduleMessageCode8 -> DecodeMarketOperationScheduleMessage(bytes)
              [] tag = MarketOperationScheduleMessageCode9 -> DecodeMarketOperationScheduleMessage(bytes)
              [] tag = MarketOperationScheduleMessageCode10 -> DecodeMarketOperationScheduleMessage(bytes)
              [] tag = MarketOperationScheduleMessageCode11 -> DecodeMarketOperationScheduleMessage(bytes)
              [] tag = MarketOperationScheduleMessageCode12 -> DecodeMarketOperationScheduleMessage(bytes)
              [] tag = MarketOperationScheduleMessageCode13 -> DecodeMarketOperationScheduleMessage(bytes)
              [] tag = MarketOperationScheduleMessageCode14 -> DecodeMarketOperationScheduleMessage(bytes)
              [] tag = MarketOperationScheduleMessageCode15 -> DecodeMarketOperationScheduleMessage(bytes)
              [] tag = MarketOperationScheduleMessageCode16 -> DecodeMarketOperationScheduleMessage(bytes)
              [] tag = MarketOperationScheduleMessageCode17 -> DecodeMarketOperationScheduleMessage(bytes)
              [] tag = MarketOperationScheduleMessageCode18 -> DecodeMarketOperationScheduleMessage(bytes)
              [] tag = MarketOperationScheduleMessageCode19 -> DecodeMarketOperationScheduleMessage(bytes)
              [] tag = MarketOperationScheduleMessageCode20 -> DecodeMarketOperationScheduleMessage(bytes)
              [] tag = MarketOperationScheduleMessageCode21 -> DecodeMarketOperationScheduleMessage(bytes)
              [] tag = MarketOperationScheduleMessageCode22 -> DecodeMarketOperationScheduleMessage(bytes)
              [] tag = MarketOperationScheduleMessageCode23 -> DecodeMarketOperationScheduleMessage(bytes)
              [] tag = MarketOperationScheduleMessageCode24 -> DecodeMarketOperationScheduleMessage(bytes)
              [] tag = MarketOperationScheduleMessageCode25 -> DecodeMarketOperationScheduleMessage(bytes)
              [] tag = MarketOperationScheduleMessageCode26 -> DecodeMarketOperationScheduleMessage(bytes)
              [] tag = MarketOperationScheduleMessageCode27 -> DecodeMarketOperationScheduleMessage(bytes)
              [] tag = MarketOperationScheduleMessageCode28 -> DecodeMarketOperationScheduleMessage(bytes)
              [] tag = MarketOperationScheduleMessageCode29 -> DecodeMarketOperationScheduleMessage(bytes)
              [] tag = MarketOperationScheduleMessageCode30 -> DecodeMarketOperationScheduleMessage(bytes)
              [] tag = IssueClosingMessageCode -> DecodeIssueClosingMessage(bytes)
              [] tag = IssueClosingMessageCode2 -> DecodeIssueClosingMessage(bytes)
              [] tag = IssueClosingMessageCode3 -> DecodeIssueClosingMessage(bytes)
              [] tag = IssueClosingMessageCode4 -> DecodeIssueClosingMessage(bytes)
              [] tag = MemberFirmSanctionsMessageCode -> DecodeMemberFirmSanctionsMessage(bytes)
              [] tag = MemberFirmSanctionsMessageCode2 -> DecodeMemberFirmSanctionsMessage(bytes)
              [] tag = MemberFirmSanctionsMessageCode3 -> DecodeMemberFirmSanctionsMessage(bytes)
              [] tag = MemberFirmSanctionsMessageCode4 -> DecodeMemberFirmSanctionsMessage(bytes)
              [] tag = MemberFirmSanctionsMessageCode5 -> DecodeMemberFirmSanctionsMessage(bytes)
              [] tag = MemberFirmSanctionsMessageCode6 -> DecodeMemberFirmSanctionsMessage(bytes)
              [] tag = MemberFirmSanctionsMessageCode7 -> DecodeMemberFirmSanctionsMessage(bytes)
              [] tag = MemberFirmSanctionsMessageCode8 -> DecodeMemberFirmSanctionsMessage(bytes)
              [] tag = MemberFirmSanctionsMessageCode9 -> DecodeMemberFirmSanctionsMessage(bytes)
              [] tag = MemberFirmSanctionsMessageCode10 -> DecodeMemberFirmSanctionsMessage(bytes)
              [] tag = MemberFirmSanctionsMessageCode11 -> DecodeMemberFirmSanctionsMessage(bytes)
              [] tag = RegularBondsKtbQuoteMessageCode -> DecodeRegularBondsKtbQuoteMessage(bytes)
              [] tag = RegularBondsKtbQuoteMessageCode2 -> DecodeRegularBondsKtbQuoteMessage(bytes)
              [] tag = BondsOrderFilledMessageCode -> DecodeBondsOrderFilledMessage(bytes)
              [] tag = BondsOrderFilledMessageCode2 -> DecodeBondsOrderFilledMessage(bytes)
              [] tag = BondsOrderFilledMessageCode3 -> DecodeBondsOrderFilledMessage(bytes)
              [] tag = GeneralBondsKtbOrderFilledPlusQuoteMessageCode -> DecodeGeneralBondsKtbOrderFilledPlusQuoteMessage(bytes)
              [] tag = GeneralBondsKtbOrderFilledPlusQuoteMessageCode2 -> DecodeGeneralBondsKtbOrderFilledPlusQuoteMessage(bytes)
              [] tag = BondsNegotiatedTradeDataMessageCode -> DecodeBondsNegotiatedTradeDataMessage(bytes)
              [] tag = BondsNegotiatedTradeDataMessageCode2 -> DecodeBondsNegotiatedTradeDataMessage(bytes)
              [] tag = RepoNegotiatedTradeDataMessageCode -> DecodeRepoNegotiatedTradeDataMessage(bytes)
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
              [] tag = BabyBondsReportingMarketYieldMessageCode -> DecodeBabyBondsReportingMarketYieldMessage(bytes)
              [] tag = KtbConfirmedInfoForWitMessageCode -> DecodeKtbConfirmedInfoForWitMessage(bytes)
              [] tag = KtbShortTermYieldMessageCode -> DecodeKtbShortTermYieldMessage(bytes)
              [] tag = KtbAverageYieldMessageCode -> DecodeKtbAverageYieldMessage(bytes)
              [] tag = BondsCreditRatingInformationMessageCode -> DecodeBondsCreditRatingInformationMessage(bytes)
              [] tag = RegularBondsDisclosureBasicExchangeRateMessageCode -> DecodeRegularBondsDisclosureBasicExchangeRateMessage(bytes)
              [] tag = InvestorActivitiesPerBondTypesMessageCode -> DecodeInvestorActivitiesPerBondTypesMessage(bytes)
              [] tag = InvestorActivitiesPerBondTypesMessageCode2 -> DecodeInvestorActivitiesPerBondTypesMessage(bytes)
              [] tag = InvestorActivitiesPerBondTypesMessageCode3 -> DecodeInvestorActivitiesPerBondTypesMessage(bytes)
              [] tag = BondsIsinIssueInformationMessageCode -> DecodeBondsIsinIssueInformationMessage(bytes)
              [] tag = BondsIsinInformationTextMessageCode -> DecodeBondsIsinInformationTextMessage(bytes)
              [] tag = BabyBondsQuoteMessageCode -> DecodeBabyBondsQuoteMessage(bytes)
              [] tag = RepoQuoteMessageCode -> DecodeRepoQuoteMessage(bytes)
              [] tag = BondsTotalRemainingVolumeOnQuotesMessageCode -> DecodeBondsTotalRemainingVolumeOnQuotesMessage(bytes)
              [] tag = BondsTotalRemainingVolumeOnQuotesMessageCode2 -> DecodeBondsTotalRemainingVolumeOnQuotesMessage(bytes)
              [] tag = BabyBondsOrderFilledPlusQuoteMessageCode -> DecodeBabyBondsOrderFilledPlusQuoteMessage(bytes)
              [] tag = RepoOrderFilledPlusQuoteMessageCode -> DecodeRepoOrderFilledPlusQuoteMessage(bytes)
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
        \cup { [tag |-> MarketOperationTsMessageCode, body |-> one] : one \in CheckedMarketOperationTsMessage }
        \cup { [tag |-> MarketOperationTsMessageCode2, body |-> one] : one \in CheckedMarketOperationTsMessage }
        \cup { [tag |-> MarketOperationTsMessageCode3, body |-> one] : one \in CheckedMarketOperationTsMessage }
        \cup { [tag |-> MarketOperationTsMessageCode4, body |-> one] : one \in CheckedMarketOperationTsMessage }
        \cup { [tag |-> MarketOperationTsMessageCode5, body |-> one] : one \in CheckedMarketOperationTsMessage }
        \cup { [tag |-> MarketOperationTsMessageCode6, body |-> one] : one \in CheckedMarketOperationTsMessage }
        \cup { [tag |-> MarketOperationTsMessageCode7, body |-> one] : one \in CheckedMarketOperationTsMessage }
        \cup { [tag |-> MarketOperationTsMessageCode8, body |-> one] : one \in CheckedMarketOperationTsMessage }
        \cup { [tag |-> MarketOperationTsMessageCode9, body |-> one] : one \in CheckedMarketOperationTsMessage }
        \cup { [tag |-> MarketOperationTsMessageCode10, body |-> one] : one \in CheckedMarketOperationTsMessage }
        \cup { [tag |-> MarketOperationTsMessageCode11, body |-> one] : one \in CheckedMarketOperationTsMessage }
        \cup { [tag |-> MarketOperationTsMessageCode12, body |-> one] : one \in CheckedMarketOperationTsMessage }
        \cup { [tag |-> MarketOperationTsMessageCode13, body |-> one] : one \in CheckedMarketOperationTsMessage }
        \cup { [tag |-> MarketOperationTsMessageCode14, body |-> one] : one \in CheckedMarketOperationTsMessage }
        \cup { [tag |-> MarketOperationTsMessageCode15, body |-> one] : one \in CheckedMarketOperationTsMessage }
        \cup { [tag |-> MarketOperationTsMessageCode16, body |-> one] : one \in CheckedMarketOperationTsMessage }
        \cup { [tag |-> MarketOperationTsMessageCode17, body |-> one] : one \in CheckedMarketOperationTsMessage }
        \cup { [tag |-> MarketOperationTsMessageCode18, body |-> one] : one \in CheckedMarketOperationTsMessage }
        \cup { [tag |-> MarketOperationTsMessageCode19, body |-> one] : one \in CheckedMarketOperationTsMessage }
        \cup { [tag |-> MarketOperationTsMessageCode20, body |-> one] : one \in CheckedMarketOperationTsMessage }
        \cup { [tag |-> MarketOperationTsMessageCode21, body |-> one] : one \in CheckedMarketOperationTsMessage }
        \cup { [tag |-> MarketOperationTsMessageCode22, body |-> one] : one \in CheckedMarketOperationTsMessage }
        \cup { [tag |-> MarketOperationTsMessageCode23, body |-> one] : one \in CheckedMarketOperationTsMessage }
        \cup { [tag |-> MarketOperationTsMessageCode24, body |-> one] : one \in CheckedMarketOperationTsMessage }
        \cup { [tag |-> MarketOperationTsMessageCode25, body |-> one] : one \in CheckedMarketOperationTsMessage }
        \cup { [tag |-> MarketOperationTsMessageCode26, body |-> one] : one \in CheckedMarketOperationTsMessage }
        \cup { [tag |-> MarketOperationTsMessageCode27, body |-> one] : one \in CheckedMarketOperationTsMessage }
        \cup { [tag |-> MarketOperationTsMessageCode28, body |-> one] : one \in CheckedMarketOperationTsMessage }
        \cup { [tag |-> MarketOperationTsMessageCode29, body |-> one] : one \in CheckedMarketOperationTsMessage }
        \cup { [tag |-> MarketOperationTsMessageCode30, body |-> one] : one \in CheckedMarketOperationTsMessage }
        \cup { [tag |-> MarketOperationScheduleMessageCode, body |-> one] : one \in CheckedMarketOperationScheduleMessage }
        \cup { [tag |-> MarketOperationScheduleMessageCode2, body |-> one] : one \in CheckedMarketOperationScheduleMessage }
        \cup { [tag |-> MarketOperationScheduleMessageCode3, body |-> one] : one \in CheckedMarketOperationScheduleMessage }
        \cup { [tag |-> MarketOperationScheduleMessageCode4, body |-> one] : one \in CheckedMarketOperationScheduleMessage }
        \cup { [tag |-> MarketOperationScheduleMessageCode5, body |-> one] : one \in CheckedMarketOperationScheduleMessage }
        \cup { [tag |-> MarketOperationScheduleMessageCode6, body |-> one] : one \in CheckedMarketOperationScheduleMessage }
        \cup { [tag |-> MarketOperationScheduleMessageCode7, body |-> one] : one \in CheckedMarketOperationScheduleMessage }
        \cup { [tag |-> MarketOperationScheduleMessageCode8, body |-> one] : one \in CheckedMarketOperationScheduleMessage }
        \cup { [tag |-> MarketOperationScheduleMessageCode9, body |-> one] : one \in CheckedMarketOperationScheduleMessage }
        \cup { [tag |-> MarketOperationScheduleMessageCode10, body |-> one] : one \in CheckedMarketOperationScheduleMessage }
        \cup { [tag |-> MarketOperationScheduleMessageCode11, body |-> one] : one \in CheckedMarketOperationScheduleMessage }
        \cup { [tag |-> MarketOperationScheduleMessageCode12, body |-> one] : one \in CheckedMarketOperationScheduleMessage }
        \cup { [tag |-> MarketOperationScheduleMessageCode13, body |-> one] : one \in CheckedMarketOperationScheduleMessage }
        \cup { [tag |-> MarketOperationScheduleMessageCode14, body |-> one] : one \in CheckedMarketOperationScheduleMessage }
        \cup { [tag |-> MarketOperationScheduleMessageCode15, body |-> one] : one \in CheckedMarketOperationScheduleMessage }
        \cup { [tag |-> MarketOperationScheduleMessageCode16, body |-> one] : one \in CheckedMarketOperationScheduleMessage }
        \cup { [tag |-> MarketOperationScheduleMessageCode17, body |-> one] : one \in CheckedMarketOperationScheduleMessage }
        \cup { [tag |-> MarketOperationScheduleMessageCode18, body |-> one] : one \in CheckedMarketOperationScheduleMessage }
        \cup { [tag |-> MarketOperationScheduleMessageCode19, body |-> one] : one \in CheckedMarketOperationScheduleMessage }
        \cup { [tag |-> MarketOperationScheduleMessageCode20, body |-> one] : one \in CheckedMarketOperationScheduleMessage }
        \cup { [tag |-> MarketOperationScheduleMessageCode21, body |-> one] : one \in CheckedMarketOperationScheduleMessage }
        \cup { [tag |-> MarketOperationScheduleMessageCode22, body |-> one] : one \in CheckedMarketOperationScheduleMessage }
        \cup { [tag |-> MarketOperationScheduleMessageCode23, body |-> one] : one \in CheckedMarketOperationScheduleMessage }
        \cup { [tag |-> MarketOperationScheduleMessageCode24, body |-> one] : one \in CheckedMarketOperationScheduleMessage }
        \cup { [tag |-> MarketOperationScheduleMessageCode25, body |-> one] : one \in CheckedMarketOperationScheduleMessage }
        \cup { [tag |-> MarketOperationScheduleMessageCode26, body |-> one] : one \in CheckedMarketOperationScheduleMessage }
        \cup { [tag |-> MarketOperationScheduleMessageCode27, body |-> one] : one \in CheckedMarketOperationScheduleMessage }
        \cup { [tag |-> MarketOperationScheduleMessageCode28, body |-> one] : one \in CheckedMarketOperationScheduleMessage }
        \cup { [tag |-> MarketOperationScheduleMessageCode29, body |-> one] : one \in CheckedMarketOperationScheduleMessage }
        \cup { [tag |-> MarketOperationScheduleMessageCode30, body |-> one] : one \in CheckedMarketOperationScheduleMessage }
        \cup { [tag |-> IssueClosingMessageCode, body |-> one] : one \in CheckedIssueClosingMessage }
        \cup { [tag |-> IssueClosingMessageCode2, body |-> one] : one \in CheckedIssueClosingMessage }
        \cup { [tag |-> IssueClosingMessageCode3, body |-> one] : one \in CheckedIssueClosingMessage }
        \cup { [tag |-> IssueClosingMessageCode4, body |-> one] : one \in CheckedIssueClosingMessage }
        \cup { [tag |-> MemberFirmSanctionsMessageCode, body |-> one] : one \in CheckedMemberFirmSanctionsMessage }
        \cup { [tag |-> MemberFirmSanctionsMessageCode2, body |-> one] : one \in CheckedMemberFirmSanctionsMessage }
        \cup { [tag |-> MemberFirmSanctionsMessageCode3, body |-> one] : one \in CheckedMemberFirmSanctionsMessage }
        \cup { [tag |-> MemberFirmSanctionsMessageCode4, body |-> one] : one \in CheckedMemberFirmSanctionsMessage }
        \cup { [tag |-> MemberFirmSanctionsMessageCode5, body |-> one] : one \in CheckedMemberFirmSanctionsMessage }
        \cup { [tag |-> MemberFirmSanctionsMessageCode6, body |-> one] : one \in CheckedMemberFirmSanctionsMessage }
        \cup { [tag |-> MemberFirmSanctionsMessageCode7, body |-> one] : one \in CheckedMemberFirmSanctionsMessage }
        \cup { [tag |-> MemberFirmSanctionsMessageCode8, body |-> one] : one \in CheckedMemberFirmSanctionsMessage }
        \cup { [tag |-> MemberFirmSanctionsMessageCode9, body |-> one] : one \in CheckedMemberFirmSanctionsMessage }
        \cup { [tag |-> MemberFirmSanctionsMessageCode10, body |-> one] : one \in CheckedMemberFirmSanctionsMessage }
        \cup { [tag |-> MemberFirmSanctionsMessageCode11, body |-> one] : one \in CheckedMemberFirmSanctionsMessage }
        \cup { [tag |-> RegularBondsKtbQuoteMessageCode, body |-> one] : one \in CheckedRegularBondsKtbQuoteMessage }
        \cup { [tag |-> RegularBondsKtbQuoteMessageCode2, body |-> one] : one \in CheckedRegularBondsKtbQuoteMessage }
        \cup { [tag |-> BondsOrderFilledMessageCode, body |-> one] : one \in CheckedBondsOrderFilledMessage }
        \cup { [tag |-> BondsOrderFilledMessageCode2, body |-> one] : one \in CheckedBondsOrderFilledMessage }
        \cup { [tag |-> BondsOrderFilledMessageCode3, body |-> one] : one \in CheckedBondsOrderFilledMessage }
        \cup { [tag |-> GeneralBondsKtbOrderFilledPlusQuoteMessageCode, body |-> one] : one \in CheckedGeneralBondsKtbOrderFilledPlusQuoteMessage }
        \cup { [tag |-> GeneralBondsKtbOrderFilledPlusQuoteMessageCode2, body |-> one] : one \in CheckedGeneralBondsKtbOrderFilledPlusQuoteMessage }
        \cup { [tag |-> BondsNegotiatedTradeDataMessageCode, body |-> one] : one \in CheckedBondsNegotiatedTradeDataMessage }
        \cup { [tag |-> BondsNegotiatedTradeDataMessageCode2, body |-> one] : one \in CheckedBondsNegotiatedTradeDataMessage }
        \cup { [tag |-> RepoNegotiatedTradeDataMessageCode, body |-> one] : one \in CheckedRepoNegotiatedTradeDataMessage }
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
        \cup { [tag |-> BabyBondsReportingMarketYieldMessageCode, body |-> one] : one \in CheckedBabyBondsReportingMarketYieldMessage }
        \cup { [tag |-> KtbConfirmedInfoForWitMessageCode, body |-> one] : one \in CheckedKtbConfirmedInfoForWitMessage }
        \cup { [tag |-> KtbShortTermYieldMessageCode, body |-> one] : one \in CheckedKtbShortTermYieldMessage }
        \cup { [tag |-> KtbAverageYieldMessageCode, body |-> one] : one \in CheckedKtbAverageYieldMessage }
        \cup { [tag |-> BondsCreditRatingInformationMessageCode, body |-> one] : one \in CheckedBondsCreditRatingInformationMessage }
        \cup { [tag |-> RegularBondsDisclosureBasicExchangeRateMessageCode, body |-> one] : one \in CheckedRegularBondsDisclosureBasicExchangeRateMessage }
        \cup { [tag |-> InvestorActivitiesPerBondTypesMessageCode, body |-> one] : one \in CheckedInvestorActivitiesPerBondTypesMessage }
        \cup { [tag |-> InvestorActivitiesPerBondTypesMessageCode2, body |-> one] : one \in CheckedInvestorActivitiesPerBondTypesMessage }
        \cup { [tag |-> InvestorActivitiesPerBondTypesMessageCode3, body |-> one] : one \in CheckedInvestorActivitiesPerBondTypesMessage }
        \cup { [tag |-> BondsIsinIssueInformationMessageCode, body |-> one] : one \in CheckedBondsIsinIssueInformationMessage }
        \cup { [tag |-> BondsIsinInformationTextMessageCode, body |-> one] : one \in CheckedBondsIsinInformationTextMessage }
        \cup { [tag |-> BabyBondsQuoteMessageCode, body |-> one] : one \in CheckedBabyBondsQuoteMessage }
        \cup { [tag |-> RepoQuoteMessageCode, body |-> one] : one \in CheckedRepoQuoteMessage }
        \cup { [tag |-> BondsTotalRemainingVolumeOnQuotesMessageCode, body |-> one] : one \in CheckedBondsTotalRemainingVolumeOnQuotesMessage }
        \cup { [tag |-> BondsTotalRemainingVolumeOnQuotesMessageCode2, body |-> one] : one \in CheckedBondsTotalRemainingVolumeOnQuotesMessage }
        \cup { [tag |-> BabyBondsOrderFilledPlusQuoteMessageCode, body |-> one] : one \in CheckedBabyBondsOrderFilledPlusQuoteMessage }
        \cup { [tag |-> RepoOrderFilledPlusQuoteMessageCode, body |-> one] : one \in CheckedRepoOrderFilledPlusQuoteMessage }

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
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationTsMessageCode, body |-> ZeroMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationTsMessageCode2, body |-> ZeroMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationTsMessageCode3, body |-> ZeroMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationTsMessageCode4, body |-> ZeroMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationTsMessageCode5, body |-> ZeroMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationTsMessageCode6, body |-> ZeroMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationTsMessageCode7, body |-> ZeroMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationTsMessageCode8, body |-> ZeroMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationTsMessageCode9, body |-> ZeroMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationTsMessageCode10, body |-> ZeroMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationTsMessageCode11, body |-> ZeroMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationTsMessageCode12, body |-> ZeroMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationTsMessageCode13, body |-> ZeroMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationTsMessageCode14, body |-> ZeroMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationTsMessageCode15, body |-> ZeroMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationTsMessageCode16, body |-> ZeroMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationTsMessageCode17, body |-> ZeroMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationTsMessageCode18, body |-> ZeroMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationTsMessageCode19, body |-> ZeroMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationTsMessageCode20, body |-> ZeroMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationTsMessageCode21, body |-> ZeroMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationTsMessageCode22, body |-> ZeroMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationTsMessageCode23, body |-> ZeroMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationTsMessageCode24, body |-> ZeroMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationTsMessageCode25, body |-> ZeroMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationTsMessageCode26, body |-> ZeroMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationTsMessageCode27, body |-> ZeroMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationTsMessageCode28, body |-> ZeroMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationTsMessageCode29, body |-> ZeroMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationTsMessageCode30, body |-> ZeroMarketOperationTsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationScheduleMessageCode, body |-> ZeroMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationScheduleMessageCode2, body |-> ZeroMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationScheduleMessageCode3, body |-> ZeroMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationScheduleMessageCode4, body |-> ZeroMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationScheduleMessageCode5, body |-> ZeroMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationScheduleMessageCode6, body |-> ZeroMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationScheduleMessageCode7, body |-> ZeroMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationScheduleMessageCode8, body |-> ZeroMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationScheduleMessageCode9, body |-> ZeroMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationScheduleMessageCode10, body |-> ZeroMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationScheduleMessageCode11, body |-> ZeroMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationScheduleMessageCode12, body |-> ZeroMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationScheduleMessageCode13, body |-> ZeroMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationScheduleMessageCode14, body |-> ZeroMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationScheduleMessageCode15, body |-> ZeroMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationScheduleMessageCode16, body |-> ZeroMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationScheduleMessageCode17, body |-> ZeroMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationScheduleMessageCode18, body |-> ZeroMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationScheduleMessageCode19, body |-> ZeroMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationScheduleMessageCode20, body |-> ZeroMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationScheduleMessageCode21, body |-> ZeroMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationScheduleMessageCode22, body |-> ZeroMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationScheduleMessageCode23, body |-> ZeroMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationScheduleMessageCode24, body |-> ZeroMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationScheduleMessageCode25, body |-> ZeroMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationScheduleMessageCode26, body |-> ZeroMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationScheduleMessageCode27, body |-> ZeroMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationScheduleMessageCode28, body |-> ZeroMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationScheduleMessageCode29, body |-> ZeroMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MarketOperationScheduleMessageCode30, body |-> ZeroMarketOperationScheduleMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> IssueClosingMessageCode, body |-> ZeroIssueClosingMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> IssueClosingMessageCode2, body |-> ZeroIssueClosingMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> IssueClosingMessageCode3, body |-> ZeroIssueClosingMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> IssueClosingMessageCode4, body |-> ZeroIssueClosingMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MemberFirmSanctionsMessageCode, body |-> ZeroMemberFirmSanctionsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MemberFirmSanctionsMessageCode2, body |-> ZeroMemberFirmSanctionsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MemberFirmSanctionsMessageCode3, body |-> ZeroMemberFirmSanctionsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MemberFirmSanctionsMessageCode4, body |-> ZeroMemberFirmSanctionsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MemberFirmSanctionsMessageCode5, body |-> ZeroMemberFirmSanctionsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MemberFirmSanctionsMessageCode6, body |-> ZeroMemberFirmSanctionsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MemberFirmSanctionsMessageCode7, body |-> ZeroMemberFirmSanctionsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MemberFirmSanctionsMessageCode8, body |-> ZeroMemberFirmSanctionsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MemberFirmSanctionsMessageCode9, body |-> ZeroMemberFirmSanctionsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MemberFirmSanctionsMessageCode10, body |-> ZeroMemberFirmSanctionsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MemberFirmSanctionsMessageCode11, body |-> ZeroMemberFirmSanctionsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> RegularBondsKtbQuoteMessageCode, body |-> ZeroRegularBondsKtbQuoteMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> RegularBondsKtbQuoteMessageCode2, body |-> ZeroRegularBondsKtbQuoteMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> BondsOrderFilledMessageCode, body |-> ZeroBondsOrderFilledMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> BondsOrderFilledMessageCode2, body |-> ZeroBondsOrderFilledMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> BondsOrderFilledMessageCode3, body |-> ZeroBondsOrderFilledMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> GeneralBondsKtbOrderFilledPlusQuoteMessageCode, body |-> ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> GeneralBondsKtbOrderFilledPlusQuoteMessageCode2, body |-> ZeroGeneralBondsKtbOrderFilledPlusQuoteMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> BondsNegotiatedTradeDataMessageCode, body |-> ZeroBondsNegotiatedTradeDataMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> BondsNegotiatedTradeDataMessageCode2, body |-> ZeroBondsNegotiatedTradeDataMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> RepoNegotiatedTradeDataMessageCode, body |-> ZeroRepoNegotiatedTradeDataMessage]],
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
      [ZeroPacket EXCEPT !.payload = [tag |-> RetailBondsTypeCodeMessageCode, body |-> ZeroRetailBondsTypeCodeMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> BabyBondsReportingMarketYieldMessageCode, body |-> ZeroBabyBondsReportingMarketYieldMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> KtbConfirmedInfoForWitMessageCode, body |-> ZeroKtbConfirmedInfoForWitMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> KtbShortTermYieldMessageCode, body |-> ZeroKtbShortTermYieldMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> KtbAverageYieldMessageCode, body |-> ZeroKtbAverageYieldMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> BondsCreditRatingInformationMessageCode, body |-> ZeroBondsCreditRatingInformationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> RegularBondsDisclosureBasicExchangeRateMessageCode, body |-> ZeroRegularBondsDisclosureBasicExchangeRateMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> InvestorActivitiesPerBondTypesMessageCode, body |-> ZeroInvestorActivitiesPerBondTypesMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> InvestorActivitiesPerBondTypesMessageCode2, body |-> ZeroInvestorActivitiesPerBondTypesMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> InvestorActivitiesPerBondTypesMessageCode3, body |-> ZeroInvestorActivitiesPerBondTypesMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> BondsIsinIssueInformationMessageCode, body |-> ZeroBondsIsinIssueInformationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> BondsIsinInformationTextMessageCode, body |-> ZeroBondsIsinInformationTextMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> BabyBondsQuoteMessageCode, body |-> ZeroBabyBondsQuoteMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> RepoQuoteMessageCode, body |-> ZeroRepoQuoteMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> BondsTotalRemainingVolumeOnQuotesMessageCode, body |-> ZeroBondsTotalRemainingVolumeOnQuotesMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> BondsTotalRemainingVolumeOnQuotesMessageCode2, body |-> ZeroBondsTotalRemainingVolumeOnQuotesMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> BabyBondsOrderFilledPlusQuoteMessageCode, body |-> ZeroBabyBondsOrderFilledPlusQuoteMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> RepoOrderFilledPlusQuoteMessageCode, body |-> ZeroRepoOrderFilledPlusQuoteMessage]] }

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

(* Every Market Operation Ts Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketOperationTsMessage ==
    \A message \in CheckedMarketOperationTsMessage :
        LET read == DecodeMarketOperationTsMessage(EncodeMarketOperationTsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Operation Schedule Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketOperationScheduleMessage ==
    \A message \in CheckedMarketOperationScheduleMessage :
        LET read == DecodeMarketOperationScheduleMessage(EncodeMarketOperationScheduleMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Issue Closing Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIssueClosingMessage ==
    \A message \in CheckedIssueClosingMessage :
        LET read == DecodeIssueClosingMessage(EncodeIssueClosingMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Member Firm Sanctions Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMemberFirmSanctionsMessage ==
    \A message \in CheckedMemberFirmSanctionsMessage :
        LET read == DecodeMemberFirmSanctionsMessage(EncodeMemberFirmSanctionsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Regular Bonds Ktb Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRegularBondsKtbQuoteMessage ==
    \A message \in CheckedRegularBondsKtbQuoteMessage :
        LET read == DecodeRegularBondsKtbQuoteMessage(EncodeRegularBondsKtbQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bonds Order Filled Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBondsOrderFilledMessage ==
    \A message \in CheckedBondsOrderFilledMessage :
        LET read == DecodeBondsOrderFilledMessage(EncodeBondsOrderFilledMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every General Bonds Ktb Order Filled Plus Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripGeneralBondsKtbOrderFilledPlusQuoteMessage ==
    \A message \in CheckedGeneralBondsKtbOrderFilledPlusQuoteMessage :
        LET read == DecodeGeneralBondsKtbOrderFilledPlusQuoteMessage(EncodeGeneralBondsKtbOrderFilledPlusQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bonds Negotiated Trade Data Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBondsNegotiatedTradeDataMessage ==
    \A message \in CheckedBondsNegotiatedTradeDataMessage :
        LET read == DecodeBondsNegotiatedTradeDataMessage(EncodeBondsNegotiatedTradeDataMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Repo Negotiated Trade Data Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRepoNegotiatedTradeDataMessage ==
    \A message \in CheckedRepoNegotiatedTradeDataMessage :
        LET read == DecodeRepoNegotiatedTradeDataMessage(EncodeRepoNegotiatedTradeDataMessage(message))
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

(* Every Baby Bonds Reporting Market Yield Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBabyBondsReportingMarketYieldMessage ==
    \A message \in CheckedBabyBondsReportingMarketYieldMessage :
        LET read == DecodeBabyBondsReportingMarketYieldMessage(EncodeBabyBondsReportingMarketYieldMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ktb Confirmed Info For Wit Message decodes back to what was encoded, and leaves nothing over *)
RoundTripKtbConfirmedInfoForWitMessage ==
    \A message \in CheckedKtbConfirmedInfoForWitMessage :
        LET read == DecodeKtbConfirmedInfoForWitMessage(EncodeKtbConfirmedInfoForWitMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ktb Short Term Yield Message decodes back to what was encoded, and leaves nothing over *)
RoundTripKtbShortTermYieldMessage ==
    \A message \in CheckedKtbShortTermYieldMessage :
        LET read == DecodeKtbShortTermYieldMessage(EncodeKtbShortTermYieldMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ktb Average Yield Message decodes back to what was encoded, and leaves nothing over *)
RoundTripKtbAverageYieldMessage ==
    \A message \in CheckedKtbAverageYieldMessage :
        LET read == DecodeKtbAverageYieldMessage(EncodeKtbAverageYieldMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bonds Credit Rating Information Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBondsCreditRatingInformationMessage ==
    \A message \in CheckedBondsCreditRatingInformationMessage :
        LET read == DecodeBondsCreditRatingInformationMessage(EncodeBondsCreditRatingInformationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Regular Bonds Disclosure Basic Exchange Rate Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRegularBondsDisclosureBasicExchangeRateMessage ==
    \A message \in CheckedRegularBondsDisclosureBasicExchangeRateMessage :
        LET read == DecodeRegularBondsDisclosureBasicExchangeRateMessage(EncodeRegularBondsDisclosureBasicExchangeRateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Investor Activities Per Bond Types Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInvestorActivitiesPerBondTypesMessage ==
    \A message \in CheckedInvestorActivitiesPerBondTypesMessage :
        LET read == DecodeInvestorActivitiesPerBondTypesMessage(EncodeInvestorActivitiesPerBondTypesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bonds Isin Issue Information Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBondsIsinIssueInformationMessage ==
    \A message \in CheckedBondsIsinIssueInformationMessage :
        LET read == DecodeBondsIsinIssueInformationMessage(EncodeBondsIsinIssueInformationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bonds Isin Information Text Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBondsIsinInformationTextMessage ==
    \A message \in CheckedBondsIsinInformationTextMessage :
        LET read == DecodeBondsIsinInformationTextMessage(EncodeBondsIsinInformationTextMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Baby Bonds Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBabyBondsQuoteMessage ==
    \A message \in CheckedBabyBondsQuoteMessage :
        LET read == DecodeBabyBondsQuoteMessage(EncodeBabyBondsQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Repo Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRepoQuoteMessage ==
    \A message \in CheckedRepoQuoteMessage :
        LET read == DecodeRepoQuoteMessage(EncodeRepoQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bonds Total Remaining Volume On Quotes Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBondsTotalRemainingVolumeOnQuotesMessage ==
    \A message \in CheckedBondsTotalRemainingVolumeOnQuotesMessage :
        LET read == DecodeBondsTotalRemainingVolumeOnQuotesMessage(EncodeBondsTotalRemainingVolumeOnQuotesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Baby Bonds Order Filled Plus Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBabyBondsOrderFilledPlusQuoteMessage ==
    \A message \in CheckedBabyBondsOrderFilledPlusQuoteMessage :
        LET read == DecodeBabyBondsOrderFilledPlusQuoteMessage(EncodeBabyBondsOrderFilledPlusQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Repo Order Filled Plus Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRepoOrderFilledPlusQuoteMessage ==
    \A message \in CheckedRepoOrderFilledPlusQuoteMessage :
        LET read == DecodeRepoOrderFilledPlusQuoteMessage(EncodeRepoOrderFilledPlusQuoteMessage(message))
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
