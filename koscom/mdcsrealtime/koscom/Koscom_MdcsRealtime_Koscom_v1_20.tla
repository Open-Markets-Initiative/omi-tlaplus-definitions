----------------- MODULE Koscom_MdcsRealtime_Koscom_v1_20 ------------------
(***************************************************************************)
(* Koscom Co., Ltd. MDCS Realtime Koscom v1.20                             *)
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
(* K Otc Issue Closing Message: 35 bytes                                   *)
(***************************************************************************)

KOtcIssueClosingMessage ==
    [ isin              : Sample(12),
      dataSeqNumber     : Sample(8),
      closingPrice      : Sample(9),
      quotationCategory : Sample(1),
      filler4           : Sample(4),
      endKeyword        : Sample(1) ]

EncodeKOtcIssueClosingMessage(message) ==
    message.isin
        \o message.dataSeqNumber
        \o message.closingPrice
        \o message.quotationCategory
        \o message.filler4
        \o message.endKeyword

DecodeKOtcIssueClosingMessage(bytes) ==
    LET isin == ReadBytes(bytes, 12) IN IF ~isin.ok THEN Fail ELSE
    LET dataSeqNumber == ReadBytes(isin.rest, 8) IN IF ~dataSeqNumber.ok THEN Fail ELSE
    LET closingPrice == ReadBytes(dataSeqNumber.rest, 9) IN IF ~closingPrice.ok THEN Fail ELSE
    LET quotationCategory == ReadBytes(closingPrice.rest, 1) IN IF ~quotationCategory.ok THEN Fail ELSE
    LET filler4 == ReadBytes(quotationCategory.rest, 4) IN IF ~filler4.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler4.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ isin              |-> isin.value,
         dataSeqNumber     |-> dataSeqNumber.value,
         closingPrice      |-> closingPrice.value,
         quotationCategory |-> quotationCategory.value,
         filler4           |-> filler4.value,
         endKeyword        |-> endKeyword.value ], endKeyword.rest)

ZeroKOtcIssueClosingMessage ==
    [ isin              |-> [i \in 1 .. 12 |-> 0],
      dataSeqNumber     |-> [i \in 1 .. 8 |-> 0],
      closingPrice      |-> [i \in 1 .. 9 |-> 0],
      quotationCategory |-> [i \in 1 .. 1 |-> 0],
      filler4           |-> [i \in 1 .. 4 |-> 0],
      endKeyword        |-> [i \in 1 .. 1 |-> 0] ]

(* K Otc Issue Closing Message at zero, then each field in turn at the values it is checked at *)
CheckedKOtcIssueClosingMessage ==
    { ZeroKOtcIssueClosingMessage }
        \cup { [ZeroKOtcIssueClosingMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroKOtcIssueClosingMessage EXCEPT !.dataSeqNumber = one] : one \in Sample(8) }
        \cup { [ZeroKOtcIssueClosingMessage EXCEPT !.closingPrice = one] : one \in Sample(9) }
        \cup { [ZeroKOtcIssueClosingMessage EXCEPT !.quotationCategory = one] : one \in Sample(1) }
        \cup { [ZeroKOtcIssueClosingMessage EXCEPT !.filler4 = one] : one \in Sample(4) }
        \cup { [ZeroKOtcIssueClosingMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* K Otc Market Operation Message: 25 bytes                                *)
(***************************************************************************)

KOtcMarketOperationMessage ==
    [ isin          : Sample(12),
      dataSeqNumber : Sample(8),
      type          : Sample(1),
      reason        : Sample(2),
      filler1       : Sample(1),
      endKeyword    : Sample(1) ]

EncodeKOtcMarketOperationMessage(message) ==
    message.isin
        \o message.dataSeqNumber
        \o message.type
        \o message.reason
        \o message.filler1
        \o message.endKeyword

DecodeKOtcMarketOperationMessage(bytes) ==
    LET isin == ReadBytes(bytes, 12) IN IF ~isin.ok THEN Fail ELSE
    LET dataSeqNumber == ReadBytes(isin.rest, 8) IN IF ~dataSeqNumber.ok THEN Fail ELSE
    LET type == ReadBytes(dataSeqNumber.rest, 1) IN IF ~type.ok THEN Fail ELSE
    LET reason == ReadBytes(type.rest, 2) IN IF ~reason.ok THEN Fail ELSE
    LET filler1 == ReadBytes(reason.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler1.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ isin          |-> isin.value,
         dataSeqNumber |-> dataSeqNumber.value,
         type          |-> type.value,
         reason        |-> reason.value,
         filler1       |-> filler1.value,
         endKeyword    |-> endKeyword.value ], endKeyword.rest)

ZeroKOtcMarketOperationMessage ==
    [ isin          |-> [i \in 1 .. 12 |-> 0],
      dataSeqNumber |-> [i \in 1 .. 8 |-> 0],
      type          |-> [i \in 1 .. 1 |-> 0],
      reason        |-> [i \in 1 .. 2 |-> 0],
      filler1       |-> [i \in 1 .. 1 |-> 0],
      endKeyword    |-> [i \in 1 .. 1 |-> 0] ]

(* K Otc Market Operation Message at zero, then each field in turn at the values it is checked at *)
CheckedKOtcMarketOperationMessage ==
    { ZeroKOtcMarketOperationMessage }
        \cup { [ZeroKOtcMarketOperationMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroKOtcMarketOperationMessage EXCEPT !.dataSeqNumber = one] : one \in Sample(8) }
        \cup { [ZeroKOtcMarketOperationMessage EXCEPT !.type = one] : one \in Sample(1) }
        \cup { [ZeroKOtcMarketOperationMessage EXCEPT !.reason = one] : one \in Sample(2) }
        \cup { [ZeroKOtcMarketOperationMessage EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroKOtcMarketOperationMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* K Otc Market Action Message: 95 bytes                                   *)
(***************************************************************************)

KOtcMarketActionMessage ==
    [ isinNullable                : Sample(12),
      dataType                    : Sample(2),
      changeDate                  : Sample(8),
      changeTime                  : Sample(8),
      basisPriceBeforeAction      : Sample(9),
      upperLimitPriceBeforeAction : Sample(9),
      lowerLimitPriceBeforeAction : Sample(9),
      basisPriceAfterAction       : Sample(9),
      upperLimitPriceAfterAction  : Sample(9),
      lowerLimitPriceAfterAction  : Sample(9),
      filler10                    : Sample(10),
      endKeyword                  : Sample(1) ]

EncodeKOtcMarketActionMessage(message) ==
    message.isinNullable
        \o message.dataType
        \o message.changeDate
        \o message.changeTime
        \o message.basisPriceBeforeAction
        \o message.upperLimitPriceBeforeAction
        \o message.lowerLimitPriceBeforeAction
        \o message.basisPriceAfterAction
        \o message.upperLimitPriceAfterAction
        \o message.lowerLimitPriceAfterAction
        \o message.filler10
        \o message.endKeyword

DecodeKOtcMarketActionMessage(bytes) ==
    LET isinNullable == ReadBytes(bytes, 12) IN IF ~isinNullable.ok THEN Fail ELSE
    LET dataType == ReadBytes(isinNullable.rest, 2) IN IF ~dataType.ok THEN Fail ELSE
    LET changeDate == ReadBytes(dataType.rest, 8) IN IF ~changeDate.ok THEN Fail ELSE
    LET changeTime == ReadBytes(changeDate.rest, 8) IN IF ~changeTime.ok THEN Fail ELSE
    LET basisPriceBeforeAction == ReadBytes(changeTime.rest, 9) IN IF ~basisPriceBeforeAction.ok THEN Fail ELSE
    LET upperLimitPriceBeforeAction == ReadBytes(basisPriceBeforeAction.rest, 9) IN IF ~upperLimitPriceBeforeAction.ok THEN Fail ELSE
    LET lowerLimitPriceBeforeAction == ReadBytes(upperLimitPriceBeforeAction.rest, 9) IN IF ~lowerLimitPriceBeforeAction.ok THEN Fail ELSE
    LET basisPriceAfterAction == ReadBytes(lowerLimitPriceBeforeAction.rest, 9) IN IF ~basisPriceAfterAction.ok THEN Fail ELSE
    LET upperLimitPriceAfterAction == ReadBytes(basisPriceAfterAction.rest, 9) IN IF ~upperLimitPriceAfterAction.ok THEN Fail ELSE
    LET lowerLimitPriceAfterAction == ReadBytes(upperLimitPriceAfterAction.rest, 9) IN IF ~lowerLimitPriceAfterAction.ok THEN Fail ELSE
    LET filler10 == ReadBytes(lowerLimitPriceAfterAction.rest, 10) IN IF ~filler10.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler10.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ isinNullable                |-> isinNullable.value,
         dataType                    |-> dataType.value,
         changeDate                  |-> changeDate.value,
         changeTime                  |-> changeTime.value,
         basisPriceBeforeAction      |-> basisPriceBeforeAction.value,
         upperLimitPriceBeforeAction |-> upperLimitPriceBeforeAction.value,
         lowerLimitPriceBeforeAction |-> lowerLimitPriceBeforeAction.value,
         basisPriceAfterAction       |-> basisPriceAfterAction.value,
         upperLimitPriceAfterAction  |-> upperLimitPriceAfterAction.value,
         lowerLimitPriceAfterAction  |-> lowerLimitPriceAfterAction.value,
         filler10                    |-> filler10.value,
         endKeyword                  |-> endKeyword.value ], endKeyword.rest)

ZeroKOtcMarketActionMessage ==
    [ isinNullable                |-> [i \in 1 .. 12 |-> 0],
      dataType                    |-> [i \in 1 .. 2 |-> 0],
      changeDate                  |-> [i \in 1 .. 8 |-> 0],
      changeTime                  |-> [i \in 1 .. 8 |-> 0],
      basisPriceBeforeAction      |-> [i \in 1 .. 9 |-> 0],
      upperLimitPriceBeforeAction |-> [i \in 1 .. 9 |-> 0],
      lowerLimitPriceBeforeAction |-> [i \in 1 .. 9 |-> 0],
      basisPriceAfterAction       |-> [i \in 1 .. 9 |-> 0],
      upperLimitPriceAfterAction  |-> [i \in 1 .. 9 |-> 0],
      lowerLimitPriceAfterAction  |-> [i \in 1 .. 9 |-> 0],
      filler10                    |-> [i \in 1 .. 10 |-> 0],
      endKeyword                  |-> [i \in 1 .. 1 |-> 0] ]

(* K Otc Market Action Message at zero, then each field in turn at the values it is checked at *)
CheckedKOtcMarketActionMessage ==
    { ZeroKOtcMarketActionMessage }
        \cup { [ZeroKOtcMarketActionMessage EXCEPT !.isinNullable = one] : one \in Sample(12) }
        \cup { [ZeroKOtcMarketActionMessage EXCEPT !.dataType = one] : one \in Sample(2) }
        \cup { [ZeroKOtcMarketActionMessage EXCEPT !.changeDate = one] : one \in Sample(8) }
        \cup { [ZeroKOtcMarketActionMessage EXCEPT !.changeTime = one] : one \in Sample(8) }
        \cup { [ZeroKOtcMarketActionMessage EXCEPT !.basisPriceBeforeAction = one] : one \in Sample(9) }
        \cup { [ZeroKOtcMarketActionMessage EXCEPT !.upperLimitPriceBeforeAction = one] : one \in Sample(9) }
        \cup { [ZeroKOtcMarketActionMessage EXCEPT !.lowerLimitPriceBeforeAction = one] : one \in Sample(9) }
        \cup { [ZeroKOtcMarketActionMessage EXCEPT !.basisPriceAfterAction = one] : one \in Sample(9) }
        \cup { [ZeroKOtcMarketActionMessage EXCEPT !.upperLimitPriceAfterAction = one] : one \in Sample(9) }
        \cup { [ZeroKOtcMarketActionMessage EXCEPT !.lowerLimitPriceAfterAction = one] : one \in Sample(9) }
        \cup { [ZeroKOtcMarketActionMessage EXCEPT !.filler10 = one] : one \in Sample(10) }
        \cup { [ZeroKOtcMarketActionMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* K Otc Quote Message: 195 bytes                                          *)
(***************************************************************************)

KOtcQuoteMessage ==
    [ isin                                         : Sample(12),
      dataSeqNumber                                : Sample(8),
      processType                                  : Sample(1),
      quoteNumber                                  : Sample(6),
      originalQuoteNumber                          : Sample(6),
      originalQuotePrice                           : Sample(9),
      bidaskType                                   : Sample(1),
      price                                        : Sample(9),
      quantity                                     : Sample(10),
      subscriptionTime                             : Sample(6),
      totalRemainingQuantityOfAsk                  : Sample(10),
      totalRemainingQuantityOfBid                  : Sample(10),
      askBestOrder                                 : Sample(9),
      remainingQuantityOfAskBestOrder              : Sample(10),
      bidBestOrder                                 : Sample(9),
      remainingQuantityOfBidBestOrder              : Sample(10),
      priceCompareRemainingQuantityOfOrder         : Sample(10),
      originalPriceCompareRemainingQuantityOfOrder : Sample(10),
      securitiesCompanyNumber                      : Sample(3),
      branchName                                   : Sample(12),
      filler33                                     : Sample(33),
      endKeyword                                   : Sample(1) ]

EncodeKOtcQuoteMessage(message) ==
    message.isin
        \o message.dataSeqNumber
        \o message.processType
        \o message.quoteNumber
        \o message.originalQuoteNumber
        \o message.originalQuotePrice
        \o message.bidaskType
        \o message.price
        \o message.quantity
        \o message.subscriptionTime
        \o message.totalRemainingQuantityOfAsk
        \o message.totalRemainingQuantityOfBid
        \o message.askBestOrder
        \o message.remainingQuantityOfAskBestOrder
        \o message.bidBestOrder
        \o message.remainingQuantityOfBidBestOrder
        \o message.priceCompareRemainingQuantityOfOrder
        \o message.originalPriceCompareRemainingQuantityOfOrder
        \o message.securitiesCompanyNumber
        \o message.branchName
        \o message.filler33
        \o message.endKeyword

DecodeKOtcQuoteMessage(bytes) ==
    LET isin == ReadBytes(bytes, 12) IN IF ~isin.ok THEN Fail ELSE
    LET dataSeqNumber == ReadBytes(isin.rest, 8) IN IF ~dataSeqNumber.ok THEN Fail ELSE
    LET processType == ReadBytes(dataSeqNumber.rest, 1) IN IF ~processType.ok THEN Fail ELSE
    LET quoteNumber == ReadBytes(processType.rest, 6) IN IF ~quoteNumber.ok THEN Fail ELSE
    LET originalQuoteNumber == ReadBytes(quoteNumber.rest, 6) IN IF ~originalQuoteNumber.ok THEN Fail ELSE
    LET originalQuotePrice == ReadBytes(originalQuoteNumber.rest, 9) IN IF ~originalQuotePrice.ok THEN Fail ELSE
    LET bidaskType == ReadBytes(originalQuotePrice.rest, 1) IN IF ~bidaskType.ok THEN Fail ELSE
    LET price == ReadBytes(bidaskType.rest, 9) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 10) IN IF ~quantity.ok THEN Fail ELSE
    LET subscriptionTime == ReadBytes(quantity.rest, 6) IN IF ~subscriptionTime.ok THEN Fail ELSE
    LET totalRemainingQuantityOfAsk == ReadBytes(subscriptionTime.rest, 10) IN IF ~totalRemainingQuantityOfAsk.ok THEN Fail ELSE
    LET totalRemainingQuantityOfBid == ReadBytes(totalRemainingQuantityOfAsk.rest, 10) IN IF ~totalRemainingQuantityOfBid.ok THEN Fail ELSE
    LET askBestOrder == ReadBytes(totalRemainingQuantityOfBid.rest, 9) IN IF ~askBestOrder.ok THEN Fail ELSE
    LET remainingQuantityOfAskBestOrder == ReadBytes(askBestOrder.rest, 10) IN IF ~remainingQuantityOfAskBestOrder.ok THEN Fail ELSE
    LET bidBestOrder == ReadBytes(remainingQuantityOfAskBestOrder.rest, 9) IN IF ~bidBestOrder.ok THEN Fail ELSE
    LET remainingQuantityOfBidBestOrder == ReadBytes(bidBestOrder.rest, 10) IN IF ~remainingQuantityOfBidBestOrder.ok THEN Fail ELSE
    LET priceCompareRemainingQuantityOfOrder == ReadBytes(remainingQuantityOfBidBestOrder.rest, 10) IN IF ~priceCompareRemainingQuantityOfOrder.ok THEN Fail ELSE
    LET originalPriceCompareRemainingQuantityOfOrder == ReadBytes(priceCompareRemainingQuantityOfOrder.rest, 10) IN IF ~originalPriceCompareRemainingQuantityOfOrder.ok THEN Fail ELSE
    LET securitiesCompanyNumber == ReadBytes(originalPriceCompareRemainingQuantityOfOrder.rest, 3) IN IF ~securitiesCompanyNumber.ok THEN Fail ELSE
    LET branchName == ReadBytes(securitiesCompanyNumber.rest, 12) IN IF ~branchName.ok THEN Fail ELSE
    LET filler33 == ReadBytes(branchName.rest, 33) IN IF ~filler33.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler33.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ isin                                         |-> isin.value,
         dataSeqNumber                                |-> dataSeqNumber.value,
         processType                                  |-> processType.value,
         quoteNumber                                  |-> quoteNumber.value,
         originalQuoteNumber                          |-> originalQuoteNumber.value,
         originalQuotePrice                           |-> originalQuotePrice.value,
         bidaskType                                   |-> bidaskType.value,
         price                                        |-> price.value,
         quantity                                     |-> quantity.value,
         subscriptionTime                             |-> subscriptionTime.value,
         totalRemainingQuantityOfAsk                  |-> totalRemainingQuantityOfAsk.value,
         totalRemainingQuantityOfBid                  |-> totalRemainingQuantityOfBid.value,
         askBestOrder                                 |-> askBestOrder.value,
         remainingQuantityOfAskBestOrder              |-> remainingQuantityOfAskBestOrder.value,
         bidBestOrder                                 |-> bidBestOrder.value,
         remainingQuantityOfBidBestOrder              |-> remainingQuantityOfBidBestOrder.value,
         priceCompareRemainingQuantityOfOrder         |-> priceCompareRemainingQuantityOfOrder.value,
         originalPriceCompareRemainingQuantityOfOrder |-> originalPriceCompareRemainingQuantityOfOrder.value,
         securitiesCompanyNumber                      |-> securitiesCompanyNumber.value,
         branchName                                   |-> branchName.value,
         filler33                                     |-> filler33.value,
         endKeyword                                   |-> endKeyword.value ], endKeyword.rest)

ZeroKOtcQuoteMessage ==
    [ isin                                         |-> [i \in 1 .. 12 |-> 0],
      dataSeqNumber                                |-> [i \in 1 .. 8 |-> 0],
      processType                                  |-> [i \in 1 .. 1 |-> 0],
      quoteNumber                                  |-> [i \in 1 .. 6 |-> 0],
      originalQuoteNumber                          |-> [i \in 1 .. 6 |-> 0],
      originalQuotePrice                           |-> [i \in 1 .. 9 |-> 0],
      bidaskType                                   |-> [i \in 1 .. 1 |-> 0],
      price                                        |-> [i \in 1 .. 9 |-> 0],
      quantity                                     |-> [i \in 1 .. 10 |-> 0],
      subscriptionTime                             |-> [i \in 1 .. 6 |-> 0],
      totalRemainingQuantityOfAsk                  |-> [i \in 1 .. 10 |-> 0],
      totalRemainingQuantityOfBid                  |-> [i \in 1 .. 10 |-> 0],
      askBestOrder                                 |-> [i \in 1 .. 9 |-> 0],
      remainingQuantityOfAskBestOrder              |-> [i \in 1 .. 10 |-> 0],
      bidBestOrder                                 |-> [i \in 1 .. 9 |-> 0],
      remainingQuantityOfBidBestOrder              |-> [i \in 1 .. 10 |-> 0],
      priceCompareRemainingQuantityOfOrder         |-> [i \in 1 .. 10 |-> 0],
      originalPriceCompareRemainingQuantityOfOrder |-> [i \in 1 .. 10 |-> 0],
      securitiesCompanyNumber                      |-> [i \in 1 .. 3 |-> 0],
      branchName                                   |-> [i \in 1 .. 12 |-> 0],
      filler33                                     |-> [i \in 1 .. 33 |-> 0],
      endKeyword                                   |-> [i \in 1 .. 1 |-> 0] ]

(* K Otc Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedKOtcQuoteMessage ==
    { ZeroKOtcQuoteMessage }
        \cup { [ZeroKOtcQuoteMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroKOtcQuoteMessage EXCEPT !.dataSeqNumber = one] : one \in Sample(8) }
        \cup { [ZeroKOtcQuoteMessage EXCEPT !.processType = one] : one \in Sample(1) }
        \cup { [ZeroKOtcQuoteMessage EXCEPT !.quoteNumber = one] : one \in Sample(6) }
        \cup { [ZeroKOtcQuoteMessage EXCEPT !.originalQuoteNumber = one] : one \in Sample(6) }
        \cup { [ZeroKOtcQuoteMessage EXCEPT !.originalQuotePrice = one] : one \in Sample(9) }
        \cup { [ZeroKOtcQuoteMessage EXCEPT !.bidaskType = one] : one \in Sample(1) }
        \cup { [ZeroKOtcQuoteMessage EXCEPT !.price = one] : one \in Sample(9) }
        \cup { [ZeroKOtcQuoteMessage EXCEPT !.quantity = one] : one \in Sample(10) }
        \cup { [ZeroKOtcQuoteMessage EXCEPT !.subscriptionTime = one] : one \in Sample(6) }
        \cup { [ZeroKOtcQuoteMessage EXCEPT !.totalRemainingQuantityOfAsk = one] : one \in Sample(10) }
        \cup { [ZeroKOtcQuoteMessage EXCEPT !.totalRemainingQuantityOfBid = one] : one \in Sample(10) }
        \cup { [ZeroKOtcQuoteMessage EXCEPT !.askBestOrder = one] : one \in Sample(9) }
        \cup { [ZeroKOtcQuoteMessage EXCEPT !.remainingQuantityOfAskBestOrder = one] : one \in Sample(10) }
        \cup { [ZeroKOtcQuoteMessage EXCEPT !.bidBestOrder = one] : one \in Sample(9) }
        \cup { [ZeroKOtcQuoteMessage EXCEPT !.remainingQuantityOfBidBestOrder = one] : one \in Sample(10) }
        \cup { [ZeroKOtcQuoteMessage EXCEPT !.priceCompareRemainingQuantityOfOrder = one] : one \in Sample(10) }
        \cup { [ZeroKOtcQuoteMessage EXCEPT !.originalPriceCompareRemainingQuantityOfOrder = one] : one \in Sample(10) }
        \cup { [ZeroKOtcQuoteMessage EXCEPT !.securitiesCompanyNumber = one] : one \in Sample(3) }
        \cup { [ZeroKOtcQuoteMessage EXCEPT !.branchName = one] : one \in Sample(12) }
        \cup { [ZeroKOtcQuoteMessage EXCEPT !.filler33 = one] : one \in Sample(33) }
        \cup { [ZeroKOtcQuoteMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* K Otc Order Filled Message: 245 bytes                                   *)
(***************************************************************************)

KOtcOrderFilledMessage ==
    [ isin                                      : Sample(12),
      dataSeqNumber                             : Sample(8),
      tradingNumber                             : Sample(6),
      tradingPrice                              : Sample(9),
      tradingVolumeShort                        : Sample(10),
      tradingTime                               : Sample(6),
      askQuoteNumber                            : Sample(6),
      bidQuoteNumber                            : Sample(6),
      highPrice                                 : Sample(9),
      lowPrice                                  : Sample(9),
      weightedAverageStockPrice                 : Sample(9),
      totalTradingAccumulatedVolume             : Sample(12),
      totalTradingAccumulatedValue              : Sample(14),
      totalRemainingQuantityOfAsk               : Sample(10),
      totalRemainingQuantityOfBid               : Sample(10),
      bestAskOrder                              : Sample(9),
      remainingQuantityOfBestAskOrder           : Sample(10),
      bestBidOrder                              : Sample(9),
      remainingQuantityOfBestBidOrder           : Sample(10),
      comparedToPreviousDayType                 : Sample(1),
      comparedToPreviousDay                     : Sample(9),
      tradingPriceCompareRemainingQuantityOfAsk : Sample(10),
      tradingPriceCompareRemainingQuantityOfBid : Sample(10),
      filler40                                  : Sample(40),
      endKeyword                                : Sample(1) ]

EncodeKOtcOrderFilledMessage(message) ==
    message.isin
        \o message.dataSeqNumber
        \o message.tradingNumber
        \o message.tradingPrice
        \o message.tradingVolumeShort
        \o message.tradingTime
        \o message.askQuoteNumber
        \o message.bidQuoteNumber
        \o message.highPrice
        \o message.lowPrice
        \o message.weightedAverageStockPrice
        \o message.totalTradingAccumulatedVolume
        \o message.totalTradingAccumulatedValue
        \o message.totalRemainingQuantityOfAsk
        \o message.totalRemainingQuantityOfBid
        \o message.bestAskOrder
        \o message.remainingQuantityOfBestAskOrder
        \o message.bestBidOrder
        \o message.remainingQuantityOfBestBidOrder
        \o message.comparedToPreviousDayType
        \o message.comparedToPreviousDay
        \o message.tradingPriceCompareRemainingQuantityOfAsk
        \o message.tradingPriceCompareRemainingQuantityOfBid
        \o message.filler40
        \o message.endKeyword

DecodeKOtcOrderFilledMessage(bytes) ==
    LET isin == ReadBytes(bytes, 12) IN IF ~isin.ok THEN Fail ELSE
    LET dataSeqNumber == ReadBytes(isin.rest, 8) IN IF ~dataSeqNumber.ok THEN Fail ELSE
    LET tradingNumber == ReadBytes(dataSeqNumber.rest, 6) IN IF ~tradingNumber.ok THEN Fail ELSE
    LET tradingPrice == ReadBytes(tradingNumber.rest, 9) IN IF ~tradingPrice.ok THEN Fail ELSE
    LET tradingVolumeShort == ReadBytes(tradingPrice.rest, 10) IN IF ~tradingVolumeShort.ok THEN Fail ELSE
    LET tradingTime == ReadBytes(tradingVolumeShort.rest, 6) IN IF ~tradingTime.ok THEN Fail ELSE
    LET askQuoteNumber == ReadBytes(tradingTime.rest, 6) IN IF ~askQuoteNumber.ok THEN Fail ELSE
    LET bidQuoteNumber == ReadBytes(askQuoteNumber.rest, 6) IN IF ~bidQuoteNumber.ok THEN Fail ELSE
    LET highPrice == ReadBytes(bidQuoteNumber.rest, 9) IN IF ~highPrice.ok THEN Fail ELSE
    LET lowPrice == ReadBytes(highPrice.rest, 9) IN IF ~lowPrice.ok THEN Fail ELSE
    LET weightedAverageStockPrice == ReadBytes(lowPrice.rest, 9) IN IF ~weightedAverageStockPrice.ok THEN Fail ELSE
    LET totalTradingAccumulatedVolume == ReadBytes(weightedAverageStockPrice.rest, 12) IN IF ~totalTradingAccumulatedVolume.ok THEN Fail ELSE
    LET totalTradingAccumulatedValue == ReadBytes(totalTradingAccumulatedVolume.rest, 14) IN IF ~totalTradingAccumulatedValue.ok THEN Fail ELSE
    LET totalRemainingQuantityOfAsk == ReadBytes(totalTradingAccumulatedValue.rest, 10) IN IF ~totalRemainingQuantityOfAsk.ok THEN Fail ELSE
    LET totalRemainingQuantityOfBid == ReadBytes(totalRemainingQuantityOfAsk.rest, 10) IN IF ~totalRemainingQuantityOfBid.ok THEN Fail ELSE
    LET bestAskOrder == ReadBytes(totalRemainingQuantityOfBid.rest, 9) IN IF ~bestAskOrder.ok THEN Fail ELSE
    LET remainingQuantityOfBestAskOrder == ReadBytes(bestAskOrder.rest, 10) IN IF ~remainingQuantityOfBestAskOrder.ok THEN Fail ELSE
    LET bestBidOrder == ReadBytes(remainingQuantityOfBestAskOrder.rest, 9) IN IF ~bestBidOrder.ok THEN Fail ELSE
    LET remainingQuantityOfBestBidOrder == ReadBytes(bestBidOrder.rest, 10) IN IF ~remainingQuantityOfBestBidOrder.ok THEN Fail ELSE
    LET comparedToPreviousDayType == ReadBytes(remainingQuantityOfBestBidOrder.rest, 1) IN IF ~comparedToPreviousDayType.ok THEN Fail ELSE
    LET comparedToPreviousDay == ReadBytes(comparedToPreviousDayType.rest, 9) IN IF ~comparedToPreviousDay.ok THEN Fail ELSE
    LET tradingPriceCompareRemainingQuantityOfAsk == ReadBytes(comparedToPreviousDay.rest, 10) IN IF ~tradingPriceCompareRemainingQuantityOfAsk.ok THEN Fail ELSE
    LET tradingPriceCompareRemainingQuantityOfBid == ReadBytes(tradingPriceCompareRemainingQuantityOfAsk.rest, 10) IN IF ~tradingPriceCompareRemainingQuantityOfBid.ok THEN Fail ELSE
    LET filler40 == ReadBytes(tradingPriceCompareRemainingQuantityOfBid.rest, 40) IN IF ~filler40.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler40.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ isin                                      |-> isin.value,
         dataSeqNumber                             |-> dataSeqNumber.value,
         tradingNumber                             |-> tradingNumber.value,
         tradingPrice                              |-> tradingPrice.value,
         tradingVolumeShort                        |-> tradingVolumeShort.value,
         tradingTime                               |-> tradingTime.value,
         askQuoteNumber                            |-> askQuoteNumber.value,
         bidQuoteNumber                            |-> bidQuoteNumber.value,
         highPrice                                 |-> highPrice.value,
         lowPrice                                  |-> lowPrice.value,
         weightedAverageStockPrice                 |-> weightedAverageStockPrice.value,
         totalTradingAccumulatedVolume             |-> totalTradingAccumulatedVolume.value,
         totalTradingAccumulatedValue              |-> totalTradingAccumulatedValue.value,
         totalRemainingQuantityOfAsk               |-> totalRemainingQuantityOfAsk.value,
         totalRemainingQuantityOfBid               |-> totalRemainingQuantityOfBid.value,
         bestAskOrder                              |-> bestAskOrder.value,
         remainingQuantityOfBestAskOrder           |-> remainingQuantityOfBestAskOrder.value,
         bestBidOrder                              |-> bestBidOrder.value,
         remainingQuantityOfBestBidOrder           |-> remainingQuantityOfBestBidOrder.value,
         comparedToPreviousDayType                 |-> comparedToPreviousDayType.value,
         comparedToPreviousDay                     |-> comparedToPreviousDay.value,
         tradingPriceCompareRemainingQuantityOfAsk |-> tradingPriceCompareRemainingQuantityOfAsk.value,
         tradingPriceCompareRemainingQuantityOfBid |-> tradingPriceCompareRemainingQuantityOfBid.value,
         filler40                                  |-> filler40.value,
         endKeyword                                |-> endKeyword.value ], endKeyword.rest)

ZeroKOtcOrderFilledMessage ==
    [ isin                                      |-> [i \in 1 .. 12 |-> 0],
      dataSeqNumber                             |-> [i \in 1 .. 8 |-> 0],
      tradingNumber                             |-> [i \in 1 .. 6 |-> 0],
      tradingPrice                              |-> [i \in 1 .. 9 |-> 0],
      tradingVolumeShort                        |-> [i \in 1 .. 10 |-> 0],
      tradingTime                               |-> [i \in 1 .. 6 |-> 0],
      askQuoteNumber                            |-> [i \in 1 .. 6 |-> 0],
      bidQuoteNumber                            |-> [i \in 1 .. 6 |-> 0],
      highPrice                                 |-> [i \in 1 .. 9 |-> 0],
      lowPrice                                  |-> [i \in 1 .. 9 |-> 0],
      weightedAverageStockPrice                 |-> [i \in 1 .. 9 |-> 0],
      totalTradingAccumulatedVolume             |-> [i \in 1 .. 12 |-> 0],
      totalTradingAccumulatedValue              |-> [i \in 1 .. 14 |-> 0],
      totalRemainingQuantityOfAsk               |-> [i \in 1 .. 10 |-> 0],
      totalRemainingQuantityOfBid               |-> [i \in 1 .. 10 |-> 0],
      bestAskOrder                              |-> [i \in 1 .. 9 |-> 0],
      remainingQuantityOfBestAskOrder           |-> [i \in 1 .. 10 |-> 0],
      bestBidOrder                              |-> [i \in 1 .. 9 |-> 0],
      remainingQuantityOfBestBidOrder           |-> [i \in 1 .. 10 |-> 0],
      comparedToPreviousDayType                 |-> [i \in 1 .. 1 |-> 0],
      comparedToPreviousDay                     |-> [i \in 1 .. 9 |-> 0],
      tradingPriceCompareRemainingQuantityOfAsk |-> [i \in 1 .. 10 |-> 0],
      tradingPriceCompareRemainingQuantityOfBid |-> [i \in 1 .. 10 |-> 0],
      filler40                                  |-> [i \in 1 .. 40 |-> 0],
      endKeyword                                |-> [i \in 1 .. 1 |-> 0] ]

(* K Otc Order Filled Message at zero, then each field in turn at the values it is checked at *)
CheckedKOtcOrderFilledMessage ==
    { ZeroKOtcOrderFilledMessage }
        \cup { [ZeroKOtcOrderFilledMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroKOtcOrderFilledMessage EXCEPT !.dataSeqNumber = one] : one \in Sample(8) }
        \cup { [ZeroKOtcOrderFilledMessage EXCEPT !.tradingNumber = one] : one \in Sample(6) }
        \cup { [ZeroKOtcOrderFilledMessage EXCEPT !.tradingPrice = one] : one \in Sample(9) }
        \cup { [ZeroKOtcOrderFilledMessage EXCEPT !.tradingVolumeShort = one] : one \in Sample(10) }
        \cup { [ZeroKOtcOrderFilledMessage EXCEPT !.tradingTime = one] : one \in Sample(6) }
        \cup { [ZeroKOtcOrderFilledMessage EXCEPT !.askQuoteNumber = one] : one \in Sample(6) }
        \cup { [ZeroKOtcOrderFilledMessage EXCEPT !.bidQuoteNumber = one] : one \in Sample(6) }
        \cup { [ZeroKOtcOrderFilledMessage EXCEPT !.highPrice = one] : one \in Sample(9) }
        \cup { [ZeroKOtcOrderFilledMessage EXCEPT !.lowPrice = one] : one \in Sample(9) }
        \cup { [ZeroKOtcOrderFilledMessage EXCEPT !.weightedAverageStockPrice = one] : one \in Sample(9) }
        \cup { [ZeroKOtcOrderFilledMessage EXCEPT !.totalTradingAccumulatedVolume = one] : one \in Sample(12) }
        \cup { [ZeroKOtcOrderFilledMessage EXCEPT !.totalTradingAccumulatedValue = one] : one \in Sample(14) }
        \cup { [ZeroKOtcOrderFilledMessage EXCEPT !.totalRemainingQuantityOfAsk = one] : one \in Sample(10) }
        \cup { [ZeroKOtcOrderFilledMessage EXCEPT !.totalRemainingQuantityOfBid = one] : one \in Sample(10) }
        \cup { [ZeroKOtcOrderFilledMessage EXCEPT !.bestAskOrder = one] : one \in Sample(9) }
        \cup { [ZeroKOtcOrderFilledMessage EXCEPT !.remainingQuantityOfBestAskOrder = one] : one \in Sample(10) }
        \cup { [ZeroKOtcOrderFilledMessage EXCEPT !.bestBidOrder = one] : one \in Sample(9) }
        \cup { [ZeroKOtcOrderFilledMessage EXCEPT !.remainingQuantityOfBestBidOrder = one] : one \in Sample(10) }
        \cup { [ZeroKOtcOrderFilledMessage EXCEPT !.comparedToPreviousDayType = one] : one \in Sample(1) }
        \cup { [ZeroKOtcOrderFilledMessage EXCEPT !.comparedToPreviousDay = one] : one \in Sample(9) }
        \cup { [ZeroKOtcOrderFilledMessage EXCEPT !.tradingPriceCompareRemainingQuantityOfAsk = one] : one \in Sample(10) }
        \cup { [ZeroKOtcOrderFilledMessage EXCEPT !.tradingPriceCompareRemainingQuantityOfBid = one] : one \in Sample(10) }
        \cup { [ZeroKOtcOrderFilledMessage EXCEPT !.filler40 = one] : one \in Sample(40) }
        \cup { [ZeroKOtcOrderFilledMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Otc Bond Traded Info Message: 105 bytes                                 *)
(***************************************************************************)

OtcBondTradedInfoMessage ==
    [ isin                       : Sample(12),
      subcategory                : Sample(2),
      tradingDate                : Sample(8),
      registeredTime             : Sample(6),
      processCategory            : Sample(1),
      registeredNumber           : Sample(8),
      originallyRegisteredNumber : Sample(8),
      tradingTypeCategory        : Sample(1),
      volume                     : Sample(16),
      pretaxUnitPrice            : Sample(8),
      pretaxYield                : Sample(8),
      settlementDateOtc          : Sample(8),
      marketBaseRate             : Sample(8),
      fxCategory                 : Sample(1),
      basedFx                    : Sample(8),
      tradingCategory            : Sample(1),
      endKeyword                 : Sample(1) ]

EncodeOtcBondTradedInfoMessage(message) ==
    message.isin
        \o message.subcategory
        \o message.tradingDate
        \o message.registeredTime
        \o message.processCategory
        \o message.registeredNumber
        \o message.originallyRegisteredNumber
        \o message.tradingTypeCategory
        \o message.volume
        \o message.pretaxUnitPrice
        \o message.pretaxYield
        \o message.settlementDateOtc
        \o message.marketBaseRate
        \o message.fxCategory
        \o message.basedFx
        \o message.tradingCategory
        \o message.endKeyword

DecodeOtcBondTradedInfoMessage(bytes) ==
    LET isin == ReadBytes(bytes, 12) IN IF ~isin.ok THEN Fail ELSE
    LET subcategory == ReadBytes(isin.rest, 2) IN IF ~subcategory.ok THEN Fail ELSE
    LET tradingDate == ReadBytes(subcategory.rest, 8) IN IF ~tradingDate.ok THEN Fail ELSE
    LET registeredTime == ReadBytes(tradingDate.rest, 6) IN IF ~registeredTime.ok THEN Fail ELSE
    LET processCategory == ReadBytes(registeredTime.rest, 1) IN IF ~processCategory.ok THEN Fail ELSE
    LET registeredNumber == ReadBytes(processCategory.rest, 8) IN IF ~registeredNumber.ok THEN Fail ELSE
    LET originallyRegisteredNumber == ReadBytes(registeredNumber.rest, 8) IN IF ~originallyRegisteredNumber.ok THEN Fail ELSE
    LET tradingTypeCategory == ReadBytes(originallyRegisteredNumber.rest, 1) IN IF ~tradingTypeCategory.ok THEN Fail ELSE
    LET volume == ReadBytes(tradingTypeCategory.rest, 16) IN IF ~volume.ok THEN Fail ELSE
    LET pretaxUnitPrice == ReadBytes(volume.rest, 8) IN IF ~pretaxUnitPrice.ok THEN Fail ELSE
    LET pretaxYield == ReadBytes(pretaxUnitPrice.rest, 8) IN IF ~pretaxYield.ok THEN Fail ELSE
    LET settlementDateOtc == ReadBytes(pretaxYield.rest, 8) IN IF ~settlementDateOtc.ok THEN Fail ELSE
    LET marketBaseRate == ReadBytes(settlementDateOtc.rest, 8) IN IF ~marketBaseRate.ok THEN Fail ELSE
    LET fxCategory == ReadBytes(marketBaseRate.rest, 1) IN IF ~fxCategory.ok THEN Fail ELSE
    LET basedFx == ReadBytes(fxCategory.rest, 8) IN IF ~basedFx.ok THEN Fail ELSE
    LET tradingCategory == ReadBytes(basedFx.rest, 1) IN IF ~tradingCategory.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(tradingCategory.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ isin                       |-> isin.value,
         subcategory                |-> subcategory.value,
         tradingDate                |-> tradingDate.value,
         registeredTime             |-> registeredTime.value,
         processCategory            |-> processCategory.value,
         registeredNumber           |-> registeredNumber.value,
         originallyRegisteredNumber |-> originallyRegisteredNumber.value,
         tradingTypeCategory        |-> tradingTypeCategory.value,
         volume                     |-> volume.value,
         pretaxUnitPrice            |-> pretaxUnitPrice.value,
         pretaxYield                |-> pretaxYield.value,
         settlementDateOtc          |-> settlementDateOtc.value,
         marketBaseRate             |-> marketBaseRate.value,
         fxCategory                 |-> fxCategory.value,
         basedFx                    |-> basedFx.value,
         tradingCategory            |-> tradingCategory.value,
         endKeyword                 |-> endKeyword.value ], endKeyword.rest)

ZeroOtcBondTradedInfoMessage ==
    [ isin                       |-> [i \in 1 .. 12 |-> 0],
      subcategory                |-> [i \in 1 .. 2 |-> 0],
      tradingDate                |-> [i \in 1 .. 8 |-> 0],
      registeredTime             |-> [i \in 1 .. 6 |-> 0],
      processCategory            |-> [i \in 1 .. 1 |-> 0],
      registeredNumber           |-> [i \in 1 .. 8 |-> 0],
      originallyRegisteredNumber |-> [i \in 1 .. 8 |-> 0],
      tradingTypeCategory        |-> [i \in 1 .. 1 |-> 0],
      volume                     |-> [i \in 1 .. 16 |-> 0],
      pretaxUnitPrice            |-> [i \in 1 .. 8 |-> 0],
      pretaxYield                |-> [i \in 1 .. 8 |-> 0],
      settlementDateOtc          |-> [i \in 1 .. 8 |-> 0],
      marketBaseRate             |-> [i \in 1 .. 8 |-> 0],
      fxCategory                 |-> [i \in 1 .. 1 |-> 0],
      basedFx                    |-> [i \in 1 .. 8 |-> 0],
      tradingCategory            |-> [i \in 1 .. 1 |-> 0],
      endKeyword                 |-> [i \in 1 .. 1 |-> 0] ]

(* Otc Bond Traded Info Message at zero, then each field in turn at the values it is checked at *)
CheckedOtcBondTradedInfoMessage ==
    { ZeroOtcBondTradedInfoMessage }
        \cup { [ZeroOtcBondTradedInfoMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroOtcBondTradedInfoMessage EXCEPT !.subcategory = one] : one \in Sample(2) }
        \cup { [ZeroOtcBondTradedInfoMessage EXCEPT !.tradingDate = one] : one \in Sample(8) }
        \cup { [ZeroOtcBondTradedInfoMessage EXCEPT !.registeredTime = one] : one \in Sample(6) }
        \cup { [ZeroOtcBondTradedInfoMessage EXCEPT !.processCategory = one] : one \in Sample(1) }
        \cup { [ZeroOtcBondTradedInfoMessage EXCEPT !.registeredNumber = one] : one \in Sample(8) }
        \cup { [ZeroOtcBondTradedInfoMessage EXCEPT !.originallyRegisteredNumber = one] : one \in Sample(8) }
        \cup { [ZeroOtcBondTradedInfoMessage EXCEPT !.tradingTypeCategory = one] : one \in Sample(1) }
        \cup { [ZeroOtcBondTradedInfoMessage EXCEPT !.volume = one] : one \in Sample(16) }
        \cup { [ZeroOtcBondTradedInfoMessage EXCEPT !.pretaxUnitPrice = one] : one \in Sample(8) }
        \cup { [ZeroOtcBondTradedInfoMessage EXCEPT !.pretaxYield = one] : one \in Sample(8) }
        \cup { [ZeroOtcBondTradedInfoMessage EXCEPT !.settlementDateOtc = one] : one \in Sample(8) }
        \cup { [ZeroOtcBondTradedInfoMessage EXCEPT !.marketBaseRate = one] : one \in Sample(8) }
        \cup { [ZeroOtcBondTradedInfoMessage EXCEPT !.fxCategory = one] : one \in Sample(1) }
        \cup { [ZeroOtcBondTradedInfoMessage EXCEPT !.basedFx = one] : one \in Sample(8) }
        \cup { [ZeroOtcBondTradedInfoMessage EXCEPT !.tradingCategory = one] : one \in Sample(1) }
        \cup { [ZeroOtcBondTradedInfoMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Otc Bond Trades Per Institution Message: 105 bytes                      *)
(***************************************************************************)

OtcBondTradesPerInstitutionMessage ==
    [ dataProcessCategory         : Sample(1),
      date                        : Sample(8),
      institutionCode             : Sample(4),
      bondTypeCode                : Sample(4),
      askYieldInstitution         : Sample(8),
      askTradingVolumeInstitution : Sample(15),
      askTradingValueInstitution  : Sample(15),
      bidYieldInstitution         : Sample(8),
      bidTradingVolumeInstitution : Sample(15),
      bidTradingValueInstitution  : Sample(15),
      filler11                    : Sample(11),
      endKeyword                  : Sample(1) ]

EncodeOtcBondTradesPerInstitutionMessage(message) ==
    message.dataProcessCategory
        \o message.date
        \o message.institutionCode
        \o message.bondTypeCode
        \o message.askYieldInstitution
        \o message.askTradingVolumeInstitution
        \o message.askTradingValueInstitution
        \o message.bidYieldInstitution
        \o message.bidTradingVolumeInstitution
        \o message.bidTradingValueInstitution
        \o message.filler11
        \o message.endKeyword

DecodeOtcBondTradesPerInstitutionMessage(bytes) ==
    LET dataProcessCategory == ReadBytes(bytes, 1) IN IF ~dataProcessCategory.ok THEN Fail ELSE
    LET date == ReadBytes(dataProcessCategory.rest, 8) IN IF ~date.ok THEN Fail ELSE
    LET institutionCode == ReadBytes(date.rest, 4) IN IF ~institutionCode.ok THEN Fail ELSE
    LET bondTypeCode == ReadBytes(institutionCode.rest, 4) IN IF ~bondTypeCode.ok THEN Fail ELSE
    LET askYieldInstitution == ReadBytes(bondTypeCode.rest, 8) IN IF ~askYieldInstitution.ok THEN Fail ELSE
    LET askTradingVolumeInstitution == ReadBytes(askYieldInstitution.rest, 15) IN IF ~askTradingVolumeInstitution.ok THEN Fail ELSE
    LET askTradingValueInstitution == ReadBytes(askTradingVolumeInstitution.rest, 15) IN IF ~askTradingValueInstitution.ok THEN Fail ELSE
    LET bidYieldInstitution == ReadBytes(askTradingValueInstitution.rest, 8) IN IF ~bidYieldInstitution.ok THEN Fail ELSE
    LET bidTradingVolumeInstitution == ReadBytes(bidYieldInstitution.rest, 15) IN IF ~bidTradingVolumeInstitution.ok THEN Fail ELSE
    LET bidTradingValueInstitution == ReadBytes(bidTradingVolumeInstitution.rest, 15) IN IF ~bidTradingValueInstitution.ok THEN Fail ELSE
    LET filler11 == ReadBytes(bidTradingValueInstitution.rest, 11) IN IF ~filler11.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler11.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ dataProcessCategory         |-> dataProcessCategory.value,
         date                        |-> date.value,
         institutionCode             |-> institutionCode.value,
         bondTypeCode                |-> bondTypeCode.value,
         askYieldInstitution         |-> askYieldInstitution.value,
         askTradingVolumeInstitution |-> askTradingVolumeInstitution.value,
         askTradingValueInstitution  |-> askTradingValueInstitution.value,
         bidYieldInstitution         |-> bidYieldInstitution.value,
         bidTradingVolumeInstitution |-> bidTradingVolumeInstitution.value,
         bidTradingValueInstitution  |-> bidTradingValueInstitution.value,
         filler11                    |-> filler11.value,
         endKeyword                  |-> endKeyword.value ], endKeyword.rest)

ZeroOtcBondTradesPerInstitutionMessage ==
    [ dataProcessCategory         |-> [i \in 1 .. 1 |-> 0],
      date                        |-> [i \in 1 .. 8 |-> 0],
      institutionCode             |-> [i \in 1 .. 4 |-> 0],
      bondTypeCode                |-> [i \in 1 .. 4 |-> 0],
      askYieldInstitution         |-> [i \in 1 .. 8 |-> 0],
      askTradingVolumeInstitution |-> [i \in 1 .. 15 |-> 0],
      askTradingValueInstitution  |-> [i \in 1 .. 15 |-> 0],
      bidYieldInstitution         |-> [i \in 1 .. 8 |-> 0],
      bidTradingVolumeInstitution |-> [i \in 1 .. 15 |-> 0],
      bidTradingValueInstitution  |-> [i \in 1 .. 15 |-> 0],
      filler11                    |-> [i \in 1 .. 11 |-> 0],
      endKeyword                  |-> [i \in 1 .. 1 |-> 0] ]

(* Otc Bond Trades Per Institution Message at zero, then each field in turn at the values it is checked at *)
CheckedOtcBondTradesPerInstitutionMessage ==
    { ZeroOtcBondTradesPerInstitutionMessage }
        \cup { [ZeroOtcBondTradesPerInstitutionMessage EXCEPT !.dataProcessCategory = one] : one \in Sample(1) }
        \cup { [ZeroOtcBondTradesPerInstitutionMessage EXCEPT !.date = one] : one \in Sample(8) }
        \cup { [ZeroOtcBondTradesPerInstitutionMessage EXCEPT !.institutionCode = one] : one \in Sample(4) }
        \cup { [ZeroOtcBondTradesPerInstitutionMessage EXCEPT !.bondTypeCode = one] : one \in Sample(4) }
        \cup { [ZeroOtcBondTradesPerInstitutionMessage EXCEPT !.askYieldInstitution = one] : one \in Sample(8) }
        \cup { [ZeroOtcBondTradesPerInstitutionMessage EXCEPT !.askTradingVolumeInstitution = one] : one \in Sample(15) }
        \cup { [ZeroOtcBondTradesPerInstitutionMessage EXCEPT !.askTradingValueInstitution = one] : one \in Sample(15) }
        \cup { [ZeroOtcBondTradesPerInstitutionMessage EXCEPT !.bidYieldInstitution = one] : one \in Sample(8) }
        \cup { [ZeroOtcBondTradesPerInstitutionMessage EXCEPT !.bidTradingVolumeInstitution = one] : one \in Sample(15) }
        \cup { [ZeroOtcBondTradesPerInstitutionMessage EXCEPT !.bidTradingValueInstitution = one] : one \in Sample(15) }
        \cup { [ZeroOtcBondTradesPerInstitutionMessage EXCEPT !.filler11 = one] : one \in Sample(11) }
        \cup { [ZeroOtcBondTradesPerInstitutionMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Otc Bond Types Per Investor Message: 135 bytes                          *)
(***************************************************************************)

OtcBondTypesPerInvestorMessage ==
    [ isin                     : Sample(12),
      sequenceNumber           : Sample(8),
      tradingDate              : Sample(8),
      investorCategory         : Sample(4),
      askYieldInvestor         : Sample(10),
      bidYieldInvestor         : Sample(10),
      askTradingVolumeInvestor : Sample(20),
      bidTradingVolumeInvestor : Sample(20),
      askTradingValueInvestor  : Sample(20),
      bidTradingValueInvestor  : Sample(20),
      filler2                  : Sample(2),
      endKeyword               : Sample(1) ]

EncodeOtcBondTypesPerInvestorMessage(message) ==
    message.isin
        \o message.sequenceNumber
        \o message.tradingDate
        \o message.investorCategory
        \o message.askYieldInvestor
        \o message.bidYieldInvestor
        \o message.askTradingVolumeInvestor
        \o message.bidTradingVolumeInvestor
        \o message.askTradingValueInvestor
        \o message.bidTradingValueInvestor
        \o message.filler2
        \o message.endKeyword

DecodeOtcBondTypesPerInvestorMessage(bytes) ==
    LET isin == ReadBytes(bytes, 12) IN IF ~isin.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(isin.rest, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET tradingDate == ReadBytes(sequenceNumber.rest, 8) IN IF ~tradingDate.ok THEN Fail ELSE
    LET investorCategory == ReadBytes(tradingDate.rest, 4) IN IF ~investorCategory.ok THEN Fail ELSE
    LET askYieldInvestor == ReadBytes(investorCategory.rest, 10) IN IF ~askYieldInvestor.ok THEN Fail ELSE
    LET bidYieldInvestor == ReadBytes(askYieldInvestor.rest, 10) IN IF ~bidYieldInvestor.ok THEN Fail ELSE
    LET askTradingVolumeInvestor == ReadBytes(bidYieldInvestor.rest, 20) IN IF ~askTradingVolumeInvestor.ok THEN Fail ELSE
    LET bidTradingVolumeInvestor == ReadBytes(askTradingVolumeInvestor.rest, 20) IN IF ~bidTradingVolumeInvestor.ok THEN Fail ELSE
    LET askTradingValueInvestor == ReadBytes(bidTradingVolumeInvestor.rest, 20) IN IF ~askTradingValueInvestor.ok THEN Fail ELSE
    LET bidTradingValueInvestor == ReadBytes(askTradingValueInvestor.rest, 20) IN IF ~bidTradingValueInvestor.ok THEN Fail ELSE
    LET filler2 == ReadBytes(bidTradingValueInvestor.rest, 2) IN IF ~filler2.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler2.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ isin                     |-> isin.value,
         sequenceNumber           |-> sequenceNumber.value,
         tradingDate              |-> tradingDate.value,
         investorCategory         |-> investorCategory.value,
         askYieldInvestor         |-> askYieldInvestor.value,
         bidYieldInvestor         |-> bidYieldInvestor.value,
         askTradingVolumeInvestor |-> askTradingVolumeInvestor.value,
         bidTradingVolumeInvestor |-> bidTradingVolumeInvestor.value,
         askTradingValueInvestor  |-> askTradingValueInvestor.value,
         bidTradingValueInvestor  |-> bidTradingValueInvestor.value,
         filler2                  |-> filler2.value,
         endKeyword               |-> endKeyword.value ], endKeyword.rest)

ZeroOtcBondTypesPerInvestorMessage ==
    [ isin                     |-> [i \in 1 .. 12 |-> 0],
      sequenceNumber           |-> [i \in 1 .. 8 |-> 0],
      tradingDate              |-> [i \in 1 .. 8 |-> 0],
      investorCategory         |-> [i \in 1 .. 4 |-> 0],
      askYieldInvestor         |-> [i \in 1 .. 10 |-> 0],
      bidYieldInvestor         |-> [i \in 1 .. 10 |-> 0],
      askTradingVolumeInvestor |-> [i \in 1 .. 20 |-> 0],
      bidTradingVolumeInvestor |-> [i \in 1 .. 20 |-> 0],
      askTradingValueInvestor  |-> [i \in 1 .. 20 |-> 0],
      bidTradingValueInvestor  |-> [i \in 1 .. 20 |-> 0],
      filler2                  |-> [i \in 1 .. 2 |-> 0],
      endKeyword               |-> [i \in 1 .. 1 |-> 0] ]

(* Otc Bond Types Per Investor Message at zero, then each field in turn at the values it is checked at *)
CheckedOtcBondTypesPerInvestorMessage ==
    { ZeroOtcBondTypesPerInvestorMessage }
        \cup { [ZeroOtcBondTypesPerInvestorMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroOtcBondTypesPerInvestorMessage EXCEPT !.sequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroOtcBondTypesPerInvestorMessage EXCEPT !.tradingDate = one] : one \in Sample(8) }
        \cup { [ZeroOtcBondTypesPerInvestorMessage EXCEPT !.investorCategory = one] : one \in Sample(4) }
        \cup { [ZeroOtcBondTypesPerInvestorMessage EXCEPT !.askYieldInvestor = one] : one \in Sample(10) }
        \cup { [ZeroOtcBondTypesPerInvestorMessage EXCEPT !.bidYieldInvestor = one] : one \in Sample(10) }
        \cup { [ZeroOtcBondTypesPerInvestorMessage EXCEPT !.askTradingVolumeInvestor = one] : one \in Sample(20) }
        \cup { [ZeroOtcBondTypesPerInvestorMessage EXCEPT !.bidTradingVolumeInvestor = one] : one \in Sample(20) }
        \cup { [ZeroOtcBondTypesPerInvestorMessage EXCEPT !.askTradingValueInvestor = one] : one \in Sample(20) }
        \cup { [ZeroOtcBondTypesPerInvestorMessage EXCEPT !.bidTradingValueInvestor = one] : one \in Sample(20) }
        \cup { [ZeroOtcBondTypesPerInvestorMessage EXCEPT !.filler2 = one] : one \in Sample(2) }
        \cup { [ZeroOtcBondTypesPerInvestorMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* K Bond Message: 145 bytes                                               *)
(***************************************************************************)

KBondMessage ==
    [ isin                      : Sample(12),
      dataSmallCategory         : Sample(2),
      dataSourceType            : Sample(1),
      sequenceNumber            : Sample(8),
      originalSequenceNumber    : Sample(8),
      replacementType           : Sample(1),
      previousIsinOfReplacement : Sample(8),
      inputDate                 : Sample(8),
      quotesOfferTime           : Sample(6),
      bondTypeName              : Sample(40),
      changeCategory            : Sample(1),
      marketDataType            : Sample(1),
      profitRateQuotesTrading   : Sample(8),
      priceQuotesTrading        : Sample(8),
      contractCategory          : Sample(1),
      quotesAmount              : Sample(16),
      contractDate              : Sample(2),
      settlementDateKBond       : Sample(2),
      filler11                  : Sample(11),
      endKeyword                : Sample(1) ]

EncodeKBondMessage(message) ==
    message.isin
        \o message.dataSmallCategory
        \o message.dataSourceType
        \o message.sequenceNumber
        \o message.originalSequenceNumber
        \o message.replacementType
        \o message.previousIsinOfReplacement
        \o message.inputDate
        \o message.quotesOfferTime
        \o message.bondTypeName
        \o message.changeCategory
        \o message.marketDataType
        \o message.profitRateQuotesTrading
        \o message.priceQuotesTrading
        \o message.contractCategory
        \o message.quotesAmount
        \o message.contractDate
        \o message.settlementDateKBond
        \o message.filler11
        \o message.endKeyword

DecodeKBondMessage(bytes) ==
    LET isin == ReadBytes(bytes, 12) IN IF ~isin.ok THEN Fail ELSE
    LET dataSmallCategory == ReadBytes(isin.rest, 2) IN IF ~dataSmallCategory.ok THEN Fail ELSE
    LET dataSourceType == ReadBytes(dataSmallCategory.rest, 1) IN IF ~dataSourceType.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(dataSourceType.rest, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET originalSequenceNumber == ReadBytes(sequenceNumber.rest, 8) IN IF ~originalSequenceNumber.ok THEN Fail ELSE
    LET replacementType == ReadBytes(originalSequenceNumber.rest, 1) IN IF ~replacementType.ok THEN Fail ELSE
    LET previousIsinOfReplacement == ReadBytes(replacementType.rest, 8) IN IF ~previousIsinOfReplacement.ok THEN Fail ELSE
    LET inputDate == ReadBytes(previousIsinOfReplacement.rest, 8) IN IF ~inputDate.ok THEN Fail ELSE
    LET quotesOfferTime == ReadBytes(inputDate.rest, 6) IN IF ~quotesOfferTime.ok THEN Fail ELSE
    LET bondTypeName == ReadBytes(quotesOfferTime.rest, 40) IN IF ~bondTypeName.ok THEN Fail ELSE
    LET changeCategory == ReadBytes(bondTypeName.rest, 1) IN IF ~changeCategory.ok THEN Fail ELSE
    LET marketDataType == ReadBytes(changeCategory.rest, 1) IN IF ~marketDataType.ok THEN Fail ELSE
    LET profitRateQuotesTrading == ReadBytes(marketDataType.rest, 8) IN IF ~profitRateQuotesTrading.ok THEN Fail ELSE
    LET priceQuotesTrading == ReadBytes(profitRateQuotesTrading.rest, 8) IN IF ~priceQuotesTrading.ok THEN Fail ELSE
    LET contractCategory == ReadBytes(priceQuotesTrading.rest, 1) IN IF ~contractCategory.ok THEN Fail ELSE
    LET quotesAmount == ReadBytes(contractCategory.rest, 16) IN IF ~quotesAmount.ok THEN Fail ELSE
    LET contractDate == ReadBytes(quotesAmount.rest, 2) IN IF ~contractDate.ok THEN Fail ELSE
    LET settlementDateKBond == ReadBytes(contractDate.rest, 2) IN IF ~settlementDateKBond.ok THEN Fail ELSE
    LET filler11 == ReadBytes(settlementDateKBond.rest, 11) IN IF ~filler11.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler11.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ isin                      |-> isin.value,
         dataSmallCategory         |-> dataSmallCategory.value,
         dataSourceType            |-> dataSourceType.value,
         sequenceNumber            |-> sequenceNumber.value,
         originalSequenceNumber    |-> originalSequenceNumber.value,
         replacementType           |-> replacementType.value,
         previousIsinOfReplacement |-> previousIsinOfReplacement.value,
         inputDate                 |-> inputDate.value,
         quotesOfferTime           |-> quotesOfferTime.value,
         bondTypeName              |-> bondTypeName.value,
         changeCategory            |-> changeCategory.value,
         marketDataType            |-> marketDataType.value,
         profitRateQuotesTrading   |-> profitRateQuotesTrading.value,
         priceQuotesTrading        |-> priceQuotesTrading.value,
         contractCategory          |-> contractCategory.value,
         quotesAmount              |-> quotesAmount.value,
         contractDate              |-> contractDate.value,
         settlementDateKBond       |-> settlementDateKBond.value,
         filler11                  |-> filler11.value,
         endKeyword                |-> endKeyword.value ], endKeyword.rest)

ZeroKBondMessage ==
    [ isin                      |-> [i \in 1 .. 12 |-> 0],
      dataSmallCategory         |-> [i \in 1 .. 2 |-> 0],
      dataSourceType            |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber            |-> [i \in 1 .. 8 |-> 0],
      originalSequenceNumber    |-> [i \in 1 .. 8 |-> 0],
      replacementType           |-> [i \in 1 .. 1 |-> 0],
      previousIsinOfReplacement |-> [i \in 1 .. 8 |-> 0],
      inputDate                 |-> [i \in 1 .. 8 |-> 0],
      quotesOfferTime           |-> [i \in 1 .. 6 |-> 0],
      bondTypeName              |-> [i \in 1 .. 40 |-> 0],
      changeCategory            |-> [i \in 1 .. 1 |-> 0],
      marketDataType            |-> [i \in 1 .. 1 |-> 0],
      profitRateQuotesTrading   |-> [i \in 1 .. 8 |-> 0],
      priceQuotesTrading        |-> [i \in 1 .. 8 |-> 0],
      contractCategory          |-> [i \in 1 .. 1 |-> 0],
      quotesAmount              |-> [i \in 1 .. 16 |-> 0],
      contractDate              |-> [i \in 1 .. 2 |-> 0],
      settlementDateKBond       |-> [i \in 1 .. 2 |-> 0],
      filler11                  |-> [i \in 1 .. 11 |-> 0],
      endKeyword                |-> [i \in 1 .. 1 |-> 0] ]

(* K Bond Message at zero, then each field in turn at the values it is checked at *)
CheckedKBondMessage ==
    { ZeroKBondMessage }
        \cup { [ZeroKBondMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroKBondMessage EXCEPT !.dataSmallCategory = one] : one \in Sample(2) }
        \cup { [ZeroKBondMessage EXCEPT !.dataSourceType = one] : one \in Sample(1) }
        \cup { [ZeroKBondMessage EXCEPT !.sequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroKBondMessage EXCEPT !.originalSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroKBondMessage EXCEPT !.replacementType = one] : one \in Sample(1) }
        \cup { [ZeroKBondMessage EXCEPT !.previousIsinOfReplacement = one] : one \in Sample(8) }
        \cup { [ZeroKBondMessage EXCEPT !.inputDate = one] : one \in Sample(8) }
        \cup { [ZeroKBondMessage EXCEPT !.quotesOfferTime = one] : one \in Sample(6) }
        \cup { [ZeroKBondMessage EXCEPT !.bondTypeName = one] : one \in Sample(40) }
        \cup { [ZeroKBondMessage EXCEPT !.changeCategory = one] : one \in Sample(1) }
        \cup { [ZeroKBondMessage EXCEPT !.marketDataType = one] : one \in Sample(1) }
        \cup { [ZeroKBondMessage EXCEPT !.profitRateQuotesTrading = one] : one \in Sample(8) }
        \cup { [ZeroKBondMessage EXCEPT !.priceQuotesTrading = one] : one \in Sample(8) }
        \cup { [ZeroKBondMessage EXCEPT !.contractCategory = one] : one \in Sample(1) }
        \cup { [ZeroKBondMessage EXCEPT !.quotesAmount = one] : one \in Sample(16) }
        \cup { [ZeroKBondMessage EXCEPT !.contractDate = one] : one \in Sample(2) }
        \cup { [ZeroKBondMessage EXCEPT !.settlementDateKBond = one] : one \in Sample(2) }
        \cup { [ZeroKBondMessage EXCEPT !.filler11 = one] : one \in Sample(11) }
        \cup { [ZeroKBondMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Mkf Index Message: 72 bytes                                             *)
(***************************************************************************)

MkfIndexMessage ==
    [ indexId           : Sample(6),
      isin              : Sample(12),
      time              : Sample(6),
      index             : Sample(9),
      sign              : Sample(1),
      comparison        : Sample(9),
      tradingVolumeLong : Sample(12),
      tradingValue      : Sample(12),
      filler4           : Sample(4),
      endKeyword        : Sample(1) ]

EncodeMkfIndexMessage(message) ==
    message.indexId
        \o message.isin
        \o message.time
        \o message.index
        \o message.sign
        \o message.comparison
        \o message.tradingVolumeLong
        \o message.tradingValue
        \o message.filler4
        \o message.endKeyword

DecodeMkfIndexMessage(bytes) ==
    LET indexId == ReadBytes(bytes, 6) IN IF ~indexId.ok THEN Fail ELSE
    LET isin == ReadBytes(indexId.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET time == ReadBytes(isin.rest, 6) IN IF ~time.ok THEN Fail ELSE
    LET index == ReadBytes(time.rest, 9) IN IF ~index.ok THEN Fail ELSE
    LET sign == ReadBytes(index.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    LET comparison == ReadBytes(sign.rest, 9) IN IF ~comparison.ok THEN Fail ELSE
    LET tradingVolumeLong == ReadBytes(comparison.rest, 12) IN IF ~tradingVolumeLong.ok THEN Fail ELSE
    LET tradingValue == ReadBytes(tradingVolumeLong.rest, 12) IN IF ~tradingValue.ok THEN Fail ELSE
    LET filler4 == ReadBytes(tradingValue.rest, 4) IN IF ~filler4.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler4.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ indexId           |-> indexId.value,
         isin              |-> isin.value,
         time              |-> time.value,
         index             |-> index.value,
         sign              |-> sign.value,
         comparison        |-> comparison.value,
         tradingVolumeLong |-> tradingVolumeLong.value,
         tradingValue      |-> tradingValue.value,
         filler4           |-> filler4.value,
         endKeyword        |-> endKeyword.value ], endKeyword.rest)

ZeroMkfIndexMessage ==
    [ indexId           |-> [i \in 1 .. 6 |-> 0],
      isin              |-> [i \in 1 .. 12 |-> 0],
      time              |-> [i \in 1 .. 6 |-> 0],
      index             |-> [i \in 1 .. 9 |-> 0],
      sign              |-> [i \in 1 .. 1 |-> 0],
      comparison        |-> [i \in 1 .. 9 |-> 0],
      tradingVolumeLong |-> [i \in 1 .. 12 |-> 0],
      tradingValue      |-> [i \in 1 .. 12 |-> 0],
      filler4           |-> [i \in 1 .. 4 |-> 0],
      endKeyword        |-> [i \in 1 .. 1 |-> 0] ]

(* Mkf Index Message at zero, then each field in turn at the values it is checked at *)
CheckedMkfIndexMessage ==
    { ZeroMkfIndexMessage }
        \cup { [ZeroMkfIndexMessage EXCEPT !.indexId = one] : one \in Sample(6) }
        \cup { [ZeroMkfIndexMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroMkfIndexMessage EXCEPT !.time = one] : one \in Sample(6) }
        \cup { [ZeroMkfIndexMessage EXCEPT !.index = one] : one \in Sample(9) }
        \cup { [ZeroMkfIndexMessage EXCEPT !.sign = one] : one \in Sample(1) }
        \cup { [ZeroMkfIndexMessage EXCEPT !.comparison = one] : one \in Sample(9) }
        \cup { [ZeroMkfIndexMessage EXCEPT !.tradingVolumeLong = one] : one \in Sample(12) }
        \cup { [ZeroMkfIndexMessage EXCEPT !.tradingValue = one] : one \in Sample(12) }
        \cup { [ZeroMkfIndexMessage EXCEPT !.filler4 = one] : one \in Sample(4) }
        \cup { [ZeroMkfIndexMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Mkf Index Jpy Message: 72 bytes                                         *)
(***************************************************************************)

MkfIndexJpyMessage ==
    [ indexId           : Sample(6),
      isin              : Sample(12),
      time              : Sample(6),
      index             : Sample(9),
      sign              : Sample(1),
      comparison        : Sample(9),
      tradingVolumeLong : Sample(12),
      tradingValue      : Sample(12),
      filler4           : Sample(4),
      endKeyword        : Sample(1) ]

EncodeMkfIndexJpyMessage(message) ==
    message.indexId
        \o message.isin
        \o message.time
        \o message.index
        \o message.sign
        \o message.comparison
        \o message.tradingVolumeLong
        \o message.tradingValue
        \o message.filler4
        \o message.endKeyword

DecodeMkfIndexJpyMessage(bytes) ==
    LET indexId == ReadBytes(bytes, 6) IN IF ~indexId.ok THEN Fail ELSE
    LET isin == ReadBytes(indexId.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET time == ReadBytes(isin.rest, 6) IN IF ~time.ok THEN Fail ELSE
    LET index == ReadBytes(time.rest, 9) IN IF ~index.ok THEN Fail ELSE
    LET sign == ReadBytes(index.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    LET comparison == ReadBytes(sign.rest, 9) IN IF ~comparison.ok THEN Fail ELSE
    LET tradingVolumeLong == ReadBytes(comparison.rest, 12) IN IF ~tradingVolumeLong.ok THEN Fail ELSE
    LET tradingValue == ReadBytes(tradingVolumeLong.rest, 12) IN IF ~tradingValue.ok THEN Fail ELSE
    LET filler4 == ReadBytes(tradingValue.rest, 4) IN IF ~filler4.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler4.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ indexId           |-> indexId.value,
         isin              |-> isin.value,
         time              |-> time.value,
         index             |-> index.value,
         sign              |-> sign.value,
         comparison        |-> comparison.value,
         tradingVolumeLong |-> tradingVolumeLong.value,
         tradingValue      |-> tradingValue.value,
         filler4           |-> filler4.value,
         endKeyword        |-> endKeyword.value ], endKeyword.rest)

ZeroMkfIndexJpyMessage ==
    [ indexId           |-> [i \in 1 .. 6 |-> 0],
      isin              |-> [i \in 1 .. 12 |-> 0],
      time              |-> [i \in 1 .. 6 |-> 0],
      index             |-> [i \in 1 .. 9 |-> 0],
      sign              |-> [i \in 1 .. 1 |-> 0],
      comparison        |-> [i \in 1 .. 9 |-> 0],
      tradingVolumeLong |-> [i \in 1 .. 12 |-> 0],
      tradingValue      |-> [i \in 1 .. 12 |-> 0],
      filler4           |-> [i \in 1 .. 4 |-> 0],
      endKeyword        |-> [i \in 1 .. 1 |-> 0] ]

(* Mkf Index Jpy Message at zero, then each field in turn at the values it is checked at *)
CheckedMkfIndexJpyMessage ==
    { ZeroMkfIndexJpyMessage }
        \cup { [ZeroMkfIndexJpyMessage EXCEPT !.indexId = one] : one \in Sample(6) }
        \cup { [ZeroMkfIndexJpyMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroMkfIndexJpyMessage EXCEPT !.time = one] : one \in Sample(6) }
        \cup { [ZeroMkfIndexJpyMessage EXCEPT !.index = one] : one \in Sample(9) }
        \cup { [ZeroMkfIndexJpyMessage EXCEPT !.sign = one] : one \in Sample(1) }
        \cup { [ZeroMkfIndexJpyMessage EXCEPT !.comparison = one] : one \in Sample(9) }
        \cup { [ZeroMkfIndexJpyMessage EXCEPT !.tradingVolumeLong = one] : one \in Sample(12) }
        \cup { [ZeroMkfIndexJpyMessage EXCEPT !.tradingValue = one] : one \in Sample(12) }
        \cup { [ZeroMkfIndexJpyMessage EXCEPT !.filler4 = one] : one \in Sample(4) }
        \cup { [ZeroMkfIndexJpyMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Wisefn Index Message: 72 bytes                                          *)
(***************************************************************************)

WisefnIndexMessage ==
    [ indexId           : Sample(6),
      isin              : Sample(12),
      time              : Sample(6),
      index             : Sample(9),
      sign              : Sample(1),
      comparison        : Sample(9),
      tradingVolumeLong : Sample(12),
      tradingValue      : Sample(12),
      filler4           : Sample(4),
      endKeyword        : Sample(1) ]

EncodeWisefnIndexMessage(message) ==
    message.indexId
        \o message.isin
        \o message.time
        \o message.index
        \o message.sign
        \o message.comparison
        \o message.tradingVolumeLong
        \o message.tradingValue
        \o message.filler4
        \o message.endKeyword

DecodeWisefnIndexMessage(bytes) ==
    LET indexId == ReadBytes(bytes, 6) IN IF ~indexId.ok THEN Fail ELSE
    LET isin == ReadBytes(indexId.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET time == ReadBytes(isin.rest, 6) IN IF ~time.ok THEN Fail ELSE
    LET index == ReadBytes(time.rest, 9) IN IF ~index.ok THEN Fail ELSE
    LET sign == ReadBytes(index.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    LET comparison == ReadBytes(sign.rest, 9) IN IF ~comparison.ok THEN Fail ELSE
    LET tradingVolumeLong == ReadBytes(comparison.rest, 12) IN IF ~tradingVolumeLong.ok THEN Fail ELSE
    LET tradingValue == ReadBytes(tradingVolumeLong.rest, 12) IN IF ~tradingValue.ok THEN Fail ELSE
    LET filler4 == ReadBytes(tradingValue.rest, 4) IN IF ~filler4.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler4.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ indexId           |-> indexId.value,
         isin              |-> isin.value,
         time              |-> time.value,
         index             |-> index.value,
         sign              |-> sign.value,
         comparison        |-> comparison.value,
         tradingVolumeLong |-> tradingVolumeLong.value,
         tradingValue      |-> tradingValue.value,
         filler4           |-> filler4.value,
         endKeyword        |-> endKeyword.value ], endKeyword.rest)

ZeroWisefnIndexMessage ==
    [ indexId           |-> [i \in 1 .. 6 |-> 0],
      isin              |-> [i \in 1 .. 12 |-> 0],
      time              |-> [i \in 1 .. 6 |-> 0],
      index             |-> [i \in 1 .. 9 |-> 0],
      sign              |-> [i \in 1 .. 1 |-> 0],
      comparison        |-> [i \in 1 .. 9 |-> 0],
      tradingVolumeLong |-> [i \in 1 .. 12 |-> 0],
      tradingValue      |-> [i \in 1 .. 12 |-> 0],
      filler4           |-> [i \in 1 .. 4 |-> 0],
      endKeyword        |-> [i \in 1 .. 1 |-> 0] ]

(* Wisefn Index Message at zero, then each field in turn at the values it is checked at *)
CheckedWisefnIndexMessage ==
    { ZeroWisefnIndexMessage }
        \cup { [ZeroWisefnIndexMessage EXCEPT !.indexId = one] : one \in Sample(6) }
        \cup { [ZeroWisefnIndexMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroWisefnIndexMessage EXCEPT !.time = one] : one \in Sample(6) }
        \cup { [ZeroWisefnIndexMessage EXCEPT !.index = one] : one \in Sample(9) }
        \cup { [ZeroWisefnIndexMessage EXCEPT !.sign = one] : one \in Sample(1) }
        \cup { [ZeroWisefnIndexMessage EXCEPT !.comparison = one] : one \in Sample(9) }
        \cup { [ZeroWisefnIndexMessage EXCEPT !.tradingVolumeLong = one] : one \in Sample(12) }
        \cup { [ZeroWisefnIndexMessage EXCEPT !.tradingValue = one] : one \in Sample(12) }
        \cup { [ZeroWisefnIndexMessage EXCEPT !.filler4 = one] : one \in Sample(4) }
        \cup { [ZeroWisefnIndexMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Kis Index Message: 72 bytes                                             *)
(***************************************************************************)

KisIndexMessage ==
    [ indexId           : Sample(6),
      isin              : Sample(12),
      time              : Sample(6),
      index             : Sample(9),
      sign              : Sample(1),
      comparison        : Sample(9),
      tradingVolumeLong : Sample(12),
      tradingValue      : Sample(12),
      filler4           : Sample(4),
      endKeyword        : Sample(1) ]

EncodeKisIndexMessage(message) ==
    message.indexId
        \o message.isin
        \o message.time
        \o message.index
        \o message.sign
        \o message.comparison
        \o message.tradingVolumeLong
        \o message.tradingValue
        \o message.filler4
        \o message.endKeyword

DecodeKisIndexMessage(bytes) ==
    LET indexId == ReadBytes(bytes, 6) IN IF ~indexId.ok THEN Fail ELSE
    LET isin == ReadBytes(indexId.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET time == ReadBytes(isin.rest, 6) IN IF ~time.ok THEN Fail ELSE
    LET index == ReadBytes(time.rest, 9) IN IF ~index.ok THEN Fail ELSE
    LET sign == ReadBytes(index.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    LET comparison == ReadBytes(sign.rest, 9) IN IF ~comparison.ok THEN Fail ELSE
    LET tradingVolumeLong == ReadBytes(comparison.rest, 12) IN IF ~tradingVolumeLong.ok THEN Fail ELSE
    LET tradingValue == ReadBytes(tradingVolumeLong.rest, 12) IN IF ~tradingValue.ok THEN Fail ELSE
    LET filler4 == ReadBytes(tradingValue.rest, 4) IN IF ~filler4.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler4.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ indexId           |-> indexId.value,
         isin              |-> isin.value,
         time              |-> time.value,
         index             |-> index.value,
         sign              |-> sign.value,
         comparison        |-> comparison.value,
         tradingVolumeLong |-> tradingVolumeLong.value,
         tradingValue      |-> tradingValue.value,
         filler4           |-> filler4.value,
         endKeyword        |-> endKeyword.value ], endKeyword.rest)

ZeroKisIndexMessage ==
    [ indexId           |-> [i \in 1 .. 6 |-> 0],
      isin              |-> [i \in 1 .. 12 |-> 0],
      time              |-> [i \in 1 .. 6 |-> 0],
      index             |-> [i \in 1 .. 9 |-> 0],
      sign              |-> [i \in 1 .. 1 |-> 0],
      comparison        |-> [i \in 1 .. 9 |-> 0],
      tradingVolumeLong |-> [i \in 1 .. 12 |-> 0],
      tradingValue      |-> [i \in 1 .. 12 |-> 0],
      filler4           |-> [i \in 1 .. 4 |-> 0],
      endKeyword        |-> [i \in 1 .. 1 |-> 0] ]

(* Kis Index Message at zero, then each field in turn at the values it is checked at *)
CheckedKisIndexMessage ==
    { ZeroKisIndexMessage }
        \cup { [ZeroKisIndexMessage EXCEPT !.indexId = one] : one \in Sample(6) }
        \cup { [ZeroKisIndexMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroKisIndexMessage EXCEPT !.time = one] : one \in Sample(6) }
        \cup { [ZeroKisIndexMessage EXCEPT !.index = one] : one \in Sample(9) }
        \cup { [ZeroKisIndexMessage EXCEPT !.sign = one] : one \in Sample(1) }
        \cup { [ZeroKisIndexMessage EXCEPT !.comparison = one] : one \in Sample(9) }
        \cup { [ZeroKisIndexMessage EXCEPT !.tradingVolumeLong = one] : one \in Sample(12) }
        \cup { [ZeroKisIndexMessage EXCEPT !.tradingValue = one] : one \in Sample(12) }
        \cup { [ZeroKisIndexMessage EXCEPT !.filler4 = one] : one \in Sample(4) }
        \cup { [ZeroKisIndexMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Mkf Bond Index Message: 109 bytes                                       *)
(***************************************************************************)

MkfBondIndexMessage ==
    [ filler4                 : Sample(4),
      indexId                 : Sample(6),
      standardDate            : Sample(8),
      standardTime            : Sample(6),
      totalProfitIndex        : Sample(10),
      cleanPriceIndex         : Sample(10),
      marketPriceIndex        : Sample(10),
      callReInvestmentIndex   : Sample(10),
      zeroReInvestmentIndex   : Sample(10),
      futuresBasisPrice       : Sample(9),
      averageDurationNullable : Sample(6),
      averageConvexity        : Sample(6),
      averageYtm              : Sample(6),
      averageForwardYtm       : Sample(6),
      filler1                 : Sample(1),
      endKeyword              : Sample(1) ]

EncodeMkfBondIndexMessage(message) ==
    message.filler4
        \o message.indexId
        \o message.standardDate
        \o message.standardTime
        \o message.totalProfitIndex
        \o message.cleanPriceIndex
        \o message.marketPriceIndex
        \o message.callReInvestmentIndex
        \o message.zeroReInvestmentIndex
        \o message.futuresBasisPrice
        \o message.averageDurationNullable
        \o message.averageConvexity
        \o message.averageYtm
        \o message.averageForwardYtm
        \o message.filler1
        \o message.endKeyword

DecodeMkfBondIndexMessage(bytes) ==
    LET filler4 == ReadBytes(bytes, 4) IN IF ~filler4.ok THEN Fail ELSE
    LET indexId == ReadBytes(filler4.rest, 6) IN IF ~indexId.ok THEN Fail ELSE
    LET standardDate == ReadBytes(indexId.rest, 8) IN IF ~standardDate.ok THEN Fail ELSE
    LET standardTime == ReadBytes(standardDate.rest, 6) IN IF ~standardTime.ok THEN Fail ELSE
    LET totalProfitIndex == ReadBytes(standardTime.rest, 10) IN IF ~totalProfitIndex.ok THEN Fail ELSE
    LET cleanPriceIndex == ReadBytes(totalProfitIndex.rest, 10) IN IF ~cleanPriceIndex.ok THEN Fail ELSE
    LET marketPriceIndex == ReadBytes(cleanPriceIndex.rest, 10) IN IF ~marketPriceIndex.ok THEN Fail ELSE
    LET callReInvestmentIndex == ReadBytes(marketPriceIndex.rest, 10) IN IF ~callReInvestmentIndex.ok THEN Fail ELSE
    LET zeroReInvestmentIndex == ReadBytes(callReInvestmentIndex.rest, 10) IN IF ~zeroReInvestmentIndex.ok THEN Fail ELSE
    LET futuresBasisPrice == ReadBytes(zeroReInvestmentIndex.rest, 9) IN IF ~futuresBasisPrice.ok THEN Fail ELSE
    LET averageDurationNullable == ReadBytes(futuresBasisPrice.rest, 6) IN IF ~averageDurationNullable.ok THEN Fail ELSE
    LET averageConvexity == ReadBytes(averageDurationNullable.rest, 6) IN IF ~averageConvexity.ok THEN Fail ELSE
    LET averageYtm == ReadBytes(averageConvexity.rest, 6) IN IF ~averageYtm.ok THEN Fail ELSE
    LET averageForwardYtm == ReadBytes(averageYtm.rest, 6) IN IF ~averageForwardYtm.ok THEN Fail ELSE
    LET filler1 == ReadBytes(averageForwardYtm.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler1.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ filler4                 |-> filler4.value,
         indexId                 |-> indexId.value,
         standardDate            |-> standardDate.value,
         standardTime            |-> standardTime.value,
         totalProfitIndex        |-> totalProfitIndex.value,
         cleanPriceIndex         |-> cleanPriceIndex.value,
         marketPriceIndex        |-> marketPriceIndex.value,
         callReInvestmentIndex   |-> callReInvestmentIndex.value,
         zeroReInvestmentIndex   |-> zeroReInvestmentIndex.value,
         futuresBasisPrice       |-> futuresBasisPrice.value,
         averageDurationNullable |-> averageDurationNullable.value,
         averageConvexity        |-> averageConvexity.value,
         averageYtm              |-> averageYtm.value,
         averageForwardYtm       |-> averageForwardYtm.value,
         filler1                 |-> filler1.value,
         endKeyword              |-> endKeyword.value ], endKeyword.rest)

ZeroMkfBondIndexMessage ==
    [ filler4                 |-> [i \in 1 .. 4 |-> 0],
      indexId                 |-> [i \in 1 .. 6 |-> 0],
      standardDate            |-> [i \in 1 .. 8 |-> 0],
      standardTime            |-> [i \in 1 .. 6 |-> 0],
      totalProfitIndex        |-> [i \in 1 .. 10 |-> 0],
      cleanPriceIndex         |-> [i \in 1 .. 10 |-> 0],
      marketPriceIndex        |-> [i \in 1 .. 10 |-> 0],
      callReInvestmentIndex   |-> [i \in 1 .. 10 |-> 0],
      zeroReInvestmentIndex   |-> [i \in 1 .. 10 |-> 0],
      futuresBasisPrice       |-> [i \in 1 .. 9 |-> 0],
      averageDurationNullable |-> [i \in 1 .. 6 |-> 0],
      averageConvexity        |-> [i \in 1 .. 6 |-> 0],
      averageYtm              |-> [i \in 1 .. 6 |-> 0],
      averageForwardYtm       |-> [i \in 1 .. 6 |-> 0],
      filler1                 |-> [i \in 1 .. 1 |-> 0],
      endKeyword              |-> [i \in 1 .. 1 |-> 0] ]

(* Mkf Bond Index Message at zero, then each field in turn at the values it is checked at *)
CheckedMkfBondIndexMessage ==
    { ZeroMkfBondIndexMessage }
        \cup { [ZeroMkfBondIndexMessage EXCEPT !.filler4 = one] : one \in Sample(4) }
        \cup { [ZeroMkfBondIndexMessage EXCEPT !.indexId = one] : one \in Sample(6) }
        \cup { [ZeroMkfBondIndexMessage EXCEPT !.standardDate = one] : one \in Sample(8) }
        \cup { [ZeroMkfBondIndexMessage EXCEPT !.standardTime = one] : one \in Sample(6) }
        \cup { [ZeroMkfBondIndexMessage EXCEPT !.totalProfitIndex = one] : one \in Sample(10) }
        \cup { [ZeroMkfBondIndexMessage EXCEPT !.cleanPriceIndex = one] : one \in Sample(10) }
        \cup { [ZeroMkfBondIndexMessage EXCEPT !.marketPriceIndex = one] : one \in Sample(10) }
        \cup { [ZeroMkfBondIndexMessage EXCEPT !.callReInvestmentIndex = one] : one \in Sample(10) }
        \cup { [ZeroMkfBondIndexMessage EXCEPT !.zeroReInvestmentIndex = one] : one \in Sample(10) }
        \cup { [ZeroMkfBondIndexMessage EXCEPT !.futuresBasisPrice = one] : one \in Sample(9) }
        \cup { [ZeroMkfBondIndexMessage EXCEPT !.averageDurationNullable = one] : one \in Sample(6) }
        \cup { [ZeroMkfBondIndexMessage EXCEPT !.averageConvexity = one] : one \in Sample(6) }
        \cup { [ZeroMkfBondIndexMessage EXCEPT !.averageYtm = one] : one \in Sample(6) }
        \cup { [ZeroMkfBondIndexMessage EXCEPT !.averageForwardYtm = one] : one \in Sample(6) }
        \cup { [ZeroMkfBondIndexMessage EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroMkfBondIndexMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Kis Bond Index Message: 109 bytes                                       *)
(***************************************************************************)

KisBondIndexMessage ==
    [ filler4               : Sample(4),
      indexId               : Sample(6),
      standardDate          : Sample(8),
      standardTime          : Sample(6),
      totalProfitIndex      : Sample(10),
      cleanPriceIndex       : Sample(10),
      marketPriceIndex      : Sample(10),
      callReInvestmentIndex : Sample(10),
      zeroReInvestmentIndex : Sample(10),
      futuresBasisPrice     : Sample(9),
      averageDuration       : Sample(6),
      averageConvexity      : Sample(6),
      averageYtm            : Sample(6),
      averageForwardYtm     : Sample(6),
      filler1               : Sample(1),
      endKeyword            : Sample(1) ]

EncodeKisBondIndexMessage(message) ==
    message.filler4
        \o message.indexId
        \o message.standardDate
        \o message.standardTime
        \o message.totalProfitIndex
        \o message.cleanPriceIndex
        \o message.marketPriceIndex
        \o message.callReInvestmentIndex
        \o message.zeroReInvestmentIndex
        \o message.futuresBasisPrice
        \o message.averageDuration
        \o message.averageConvexity
        \o message.averageYtm
        \o message.averageForwardYtm
        \o message.filler1
        \o message.endKeyword

DecodeKisBondIndexMessage(bytes) ==
    LET filler4 == ReadBytes(bytes, 4) IN IF ~filler4.ok THEN Fail ELSE
    LET indexId == ReadBytes(filler4.rest, 6) IN IF ~indexId.ok THEN Fail ELSE
    LET standardDate == ReadBytes(indexId.rest, 8) IN IF ~standardDate.ok THEN Fail ELSE
    LET standardTime == ReadBytes(standardDate.rest, 6) IN IF ~standardTime.ok THEN Fail ELSE
    LET totalProfitIndex == ReadBytes(standardTime.rest, 10) IN IF ~totalProfitIndex.ok THEN Fail ELSE
    LET cleanPriceIndex == ReadBytes(totalProfitIndex.rest, 10) IN IF ~cleanPriceIndex.ok THEN Fail ELSE
    LET marketPriceIndex == ReadBytes(cleanPriceIndex.rest, 10) IN IF ~marketPriceIndex.ok THEN Fail ELSE
    LET callReInvestmentIndex == ReadBytes(marketPriceIndex.rest, 10) IN IF ~callReInvestmentIndex.ok THEN Fail ELSE
    LET zeroReInvestmentIndex == ReadBytes(callReInvestmentIndex.rest, 10) IN IF ~zeroReInvestmentIndex.ok THEN Fail ELSE
    LET futuresBasisPrice == ReadBytes(zeroReInvestmentIndex.rest, 9) IN IF ~futuresBasisPrice.ok THEN Fail ELSE
    LET averageDuration == ReadBytes(futuresBasisPrice.rest, 6) IN IF ~averageDuration.ok THEN Fail ELSE
    LET averageConvexity == ReadBytes(averageDuration.rest, 6) IN IF ~averageConvexity.ok THEN Fail ELSE
    LET averageYtm == ReadBytes(averageConvexity.rest, 6) IN IF ~averageYtm.ok THEN Fail ELSE
    LET averageForwardYtm == ReadBytes(averageYtm.rest, 6) IN IF ~averageForwardYtm.ok THEN Fail ELSE
    LET filler1 == ReadBytes(averageForwardYtm.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler1.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ filler4               |-> filler4.value,
         indexId               |-> indexId.value,
         standardDate          |-> standardDate.value,
         standardTime          |-> standardTime.value,
         totalProfitIndex      |-> totalProfitIndex.value,
         cleanPriceIndex       |-> cleanPriceIndex.value,
         marketPriceIndex      |-> marketPriceIndex.value,
         callReInvestmentIndex |-> callReInvestmentIndex.value,
         zeroReInvestmentIndex |-> zeroReInvestmentIndex.value,
         futuresBasisPrice     |-> futuresBasisPrice.value,
         averageDuration       |-> averageDuration.value,
         averageConvexity      |-> averageConvexity.value,
         averageYtm            |-> averageYtm.value,
         averageForwardYtm     |-> averageForwardYtm.value,
         filler1               |-> filler1.value,
         endKeyword            |-> endKeyword.value ], endKeyword.rest)

ZeroKisBondIndexMessage ==
    [ filler4               |-> [i \in 1 .. 4 |-> 0],
      indexId               |-> [i \in 1 .. 6 |-> 0],
      standardDate          |-> [i \in 1 .. 8 |-> 0],
      standardTime          |-> [i \in 1 .. 6 |-> 0],
      totalProfitIndex      |-> [i \in 1 .. 10 |-> 0],
      cleanPriceIndex       |-> [i \in 1 .. 10 |-> 0],
      marketPriceIndex      |-> [i \in 1 .. 10 |-> 0],
      callReInvestmentIndex |-> [i \in 1 .. 10 |-> 0],
      zeroReInvestmentIndex |-> [i \in 1 .. 10 |-> 0],
      futuresBasisPrice     |-> [i \in 1 .. 9 |-> 0],
      averageDuration       |-> [i \in 1 .. 6 |-> 0],
      averageConvexity      |-> [i \in 1 .. 6 |-> 0],
      averageYtm            |-> [i \in 1 .. 6 |-> 0],
      averageForwardYtm     |-> [i \in 1 .. 6 |-> 0],
      filler1               |-> [i \in 1 .. 1 |-> 0],
      endKeyword            |-> [i \in 1 .. 1 |-> 0] ]

(* Kis Bond Index Message at zero, then each field in turn at the values it is checked at *)
CheckedKisBondIndexMessage ==
    { ZeroKisBondIndexMessage }
        \cup { [ZeroKisBondIndexMessage EXCEPT !.filler4 = one] : one \in Sample(4) }
        \cup { [ZeroKisBondIndexMessage EXCEPT !.indexId = one] : one \in Sample(6) }
        \cup { [ZeroKisBondIndexMessage EXCEPT !.standardDate = one] : one \in Sample(8) }
        \cup { [ZeroKisBondIndexMessage EXCEPT !.standardTime = one] : one \in Sample(6) }
        \cup { [ZeroKisBondIndexMessage EXCEPT !.totalProfitIndex = one] : one \in Sample(10) }
        \cup { [ZeroKisBondIndexMessage EXCEPT !.cleanPriceIndex = one] : one \in Sample(10) }
        \cup { [ZeroKisBondIndexMessage EXCEPT !.marketPriceIndex = one] : one \in Sample(10) }
        \cup { [ZeroKisBondIndexMessage EXCEPT !.callReInvestmentIndex = one] : one \in Sample(10) }
        \cup { [ZeroKisBondIndexMessage EXCEPT !.zeroReInvestmentIndex = one] : one \in Sample(10) }
        \cup { [ZeroKisBondIndexMessage EXCEPT !.futuresBasisPrice = one] : one \in Sample(9) }
        \cup { [ZeroKisBondIndexMessage EXCEPT !.averageDuration = one] : one \in Sample(6) }
        \cup { [ZeroKisBondIndexMessage EXCEPT !.averageConvexity = one] : one \in Sample(6) }
        \cup { [ZeroKisBondIndexMessage EXCEPT !.averageYtm = one] : one \in Sample(6) }
        \cup { [ZeroKisBondIndexMessage EXCEPT !.averageForwardYtm = one] : one \in Sample(6) }
        \cup { [ZeroKisBondIndexMessage EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroKisBondIndexMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Kebi Bond Index Message: 109 bytes                                      *)
(***************************************************************************)

KebiBondIndexMessage ==
    [ filler4                 : Sample(4),
      indexId                 : Sample(6),
      standardDate            : Sample(8),
      standardTime            : Sample(6),
      totalProfitIndex        : Sample(10),
      cleanPriceIndex         : Sample(10),
      marketPriceIndex        : Sample(10),
      callReInvestmentIndex   : Sample(10),
      zeroReInvestmentIndex   : Sample(10),
      futuresBasisPrice       : Sample(9),
      averageDurationNullable : Sample(6),
      averageConvexity        : Sample(6),
      averageYtm              : Sample(6),
      averageForwardYtm       : Sample(6),
      filler1                 : Sample(1),
      endKeyword              : Sample(1) ]

EncodeKebiBondIndexMessage(message) ==
    message.filler4
        \o message.indexId
        \o message.standardDate
        \o message.standardTime
        \o message.totalProfitIndex
        \o message.cleanPriceIndex
        \o message.marketPriceIndex
        \o message.callReInvestmentIndex
        \o message.zeroReInvestmentIndex
        \o message.futuresBasisPrice
        \o message.averageDurationNullable
        \o message.averageConvexity
        \o message.averageYtm
        \o message.averageForwardYtm
        \o message.filler1
        \o message.endKeyword

DecodeKebiBondIndexMessage(bytes) ==
    LET filler4 == ReadBytes(bytes, 4) IN IF ~filler4.ok THEN Fail ELSE
    LET indexId == ReadBytes(filler4.rest, 6) IN IF ~indexId.ok THEN Fail ELSE
    LET standardDate == ReadBytes(indexId.rest, 8) IN IF ~standardDate.ok THEN Fail ELSE
    LET standardTime == ReadBytes(standardDate.rest, 6) IN IF ~standardTime.ok THEN Fail ELSE
    LET totalProfitIndex == ReadBytes(standardTime.rest, 10) IN IF ~totalProfitIndex.ok THEN Fail ELSE
    LET cleanPriceIndex == ReadBytes(totalProfitIndex.rest, 10) IN IF ~cleanPriceIndex.ok THEN Fail ELSE
    LET marketPriceIndex == ReadBytes(cleanPriceIndex.rest, 10) IN IF ~marketPriceIndex.ok THEN Fail ELSE
    LET callReInvestmentIndex == ReadBytes(marketPriceIndex.rest, 10) IN IF ~callReInvestmentIndex.ok THEN Fail ELSE
    LET zeroReInvestmentIndex == ReadBytes(callReInvestmentIndex.rest, 10) IN IF ~zeroReInvestmentIndex.ok THEN Fail ELSE
    LET futuresBasisPrice == ReadBytes(zeroReInvestmentIndex.rest, 9) IN IF ~futuresBasisPrice.ok THEN Fail ELSE
    LET averageDurationNullable == ReadBytes(futuresBasisPrice.rest, 6) IN IF ~averageDurationNullable.ok THEN Fail ELSE
    LET averageConvexity == ReadBytes(averageDurationNullable.rest, 6) IN IF ~averageConvexity.ok THEN Fail ELSE
    LET averageYtm == ReadBytes(averageConvexity.rest, 6) IN IF ~averageYtm.ok THEN Fail ELSE
    LET averageForwardYtm == ReadBytes(averageYtm.rest, 6) IN IF ~averageForwardYtm.ok THEN Fail ELSE
    LET filler1 == ReadBytes(averageForwardYtm.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler1.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ filler4                 |-> filler4.value,
         indexId                 |-> indexId.value,
         standardDate            |-> standardDate.value,
         standardTime            |-> standardTime.value,
         totalProfitIndex        |-> totalProfitIndex.value,
         cleanPriceIndex         |-> cleanPriceIndex.value,
         marketPriceIndex        |-> marketPriceIndex.value,
         callReInvestmentIndex   |-> callReInvestmentIndex.value,
         zeroReInvestmentIndex   |-> zeroReInvestmentIndex.value,
         futuresBasisPrice       |-> futuresBasisPrice.value,
         averageDurationNullable |-> averageDurationNullable.value,
         averageConvexity        |-> averageConvexity.value,
         averageYtm              |-> averageYtm.value,
         averageForwardYtm       |-> averageForwardYtm.value,
         filler1                 |-> filler1.value,
         endKeyword              |-> endKeyword.value ], endKeyword.rest)

ZeroKebiBondIndexMessage ==
    [ filler4                 |-> [i \in 1 .. 4 |-> 0],
      indexId                 |-> [i \in 1 .. 6 |-> 0],
      standardDate            |-> [i \in 1 .. 8 |-> 0],
      standardTime            |-> [i \in 1 .. 6 |-> 0],
      totalProfitIndex        |-> [i \in 1 .. 10 |-> 0],
      cleanPriceIndex         |-> [i \in 1 .. 10 |-> 0],
      marketPriceIndex        |-> [i \in 1 .. 10 |-> 0],
      callReInvestmentIndex   |-> [i \in 1 .. 10 |-> 0],
      zeroReInvestmentIndex   |-> [i \in 1 .. 10 |-> 0],
      futuresBasisPrice       |-> [i \in 1 .. 9 |-> 0],
      averageDurationNullable |-> [i \in 1 .. 6 |-> 0],
      averageConvexity        |-> [i \in 1 .. 6 |-> 0],
      averageYtm              |-> [i \in 1 .. 6 |-> 0],
      averageForwardYtm       |-> [i \in 1 .. 6 |-> 0],
      filler1                 |-> [i \in 1 .. 1 |-> 0],
      endKeyword              |-> [i \in 1 .. 1 |-> 0] ]

(* Kebi Bond Index Message at zero, then each field in turn at the values it is checked at *)
CheckedKebiBondIndexMessage ==
    { ZeroKebiBondIndexMessage }
        \cup { [ZeroKebiBondIndexMessage EXCEPT !.filler4 = one] : one \in Sample(4) }
        \cup { [ZeroKebiBondIndexMessage EXCEPT !.indexId = one] : one \in Sample(6) }
        \cup { [ZeroKebiBondIndexMessage EXCEPT !.standardDate = one] : one \in Sample(8) }
        \cup { [ZeroKebiBondIndexMessage EXCEPT !.standardTime = one] : one \in Sample(6) }
        \cup { [ZeroKebiBondIndexMessage EXCEPT !.totalProfitIndex = one] : one \in Sample(10) }
        \cup { [ZeroKebiBondIndexMessage EXCEPT !.cleanPriceIndex = one] : one \in Sample(10) }
        \cup { [ZeroKebiBondIndexMessage EXCEPT !.marketPriceIndex = one] : one \in Sample(10) }
        \cup { [ZeroKebiBondIndexMessage EXCEPT !.callReInvestmentIndex = one] : one \in Sample(10) }
        \cup { [ZeroKebiBondIndexMessage EXCEPT !.zeroReInvestmentIndex = one] : one \in Sample(10) }
        \cup { [ZeroKebiBondIndexMessage EXCEPT !.futuresBasisPrice = one] : one \in Sample(9) }
        \cup { [ZeroKebiBondIndexMessage EXCEPT !.averageDurationNullable = one] : one \in Sample(6) }
        \cup { [ZeroKebiBondIndexMessage EXCEPT !.averageConvexity = one] : one \in Sample(6) }
        \cup { [ZeroKebiBondIndexMessage EXCEPT !.averageYtm = one] : one \in Sample(6) }
        \cup { [ZeroKebiBondIndexMessage EXCEPT !.averageForwardYtm = one] : one \in Sample(6) }
        \cup { [ZeroKebiBondIndexMessage EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroKebiBondIndexMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Kabi Bond Index Message: 109 bytes                                      *)
(***************************************************************************)

KabiBondIndexMessage ==
    [ filler4                   : Sample(4),
      indexId                   : Sample(6),
      standardDate              : Sample(8),
      standardTime              : Sample(6),
      totalProfitIndex          : Sample(10),
      cleanPriceIndex           : Sample(10),
      marketPriceIndex          : Sample(10),
      callReInvestmentIndex     : Sample(10),
      zeroReInvestmentIndex     : Sample(10),
      futuresBasisPriceNullable : Sample(9),
      averageDuration           : Sample(6),
      averageConvexity          : Sample(6),
      averageYtm                : Sample(6),
      averageForwardYtmNullable : Sample(6),
      filler1                   : Sample(1),
      endKeyword                : Sample(1) ]

EncodeKabiBondIndexMessage(message) ==
    message.filler4
        \o message.indexId
        \o message.standardDate
        \o message.standardTime
        \o message.totalProfitIndex
        \o message.cleanPriceIndex
        \o message.marketPriceIndex
        \o message.callReInvestmentIndex
        \o message.zeroReInvestmentIndex
        \o message.futuresBasisPriceNullable
        \o message.averageDuration
        \o message.averageConvexity
        \o message.averageYtm
        \o message.averageForwardYtmNullable
        \o message.filler1
        \o message.endKeyword

DecodeKabiBondIndexMessage(bytes) ==
    LET filler4 == ReadBytes(bytes, 4) IN IF ~filler4.ok THEN Fail ELSE
    LET indexId == ReadBytes(filler4.rest, 6) IN IF ~indexId.ok THEN Fail ELSE
    LET standardDate == ReadBytes(indexId.rest, 8) IN IF ~standardDate.ok THEN Fail ELSE
    LET standardTime == ReadBytes(standardDate.rest, 6) IN IF ~standardTime.ok THEN Fail ELSE
    LET totalProfitIndex == ReadBytes(standardTime.rest, 10) IN IF ~totalProfitIndex.ok THEN Fail ELSE
    LET cleanPriceIndex == ReadBytes(totalProfitIndex.rest, 10) IN IF ~cleanPriceIndex.ok THEN Fail ELSE
    LET marketPriceIndex == ReadBytes(cleanPriceIndex.rest, 10) IN IF ~marketPriceIndex.ok THEN Fail ELSE
    LET callReInvestmentIndex == ReadBytes(marketPriceIndex.rest, 10) IN IF ~callReInvestmentIndex.ok THEN Fail ELSE
    LET zeroReInvestmentIndex == ReadBytes(callReInvestmentIndex.rest, 10) IN IF ~zeroReInvestmentIndex.ok THEN Fail ELSE
    LET futuresBasisPriceNullable == ReadBytes(zeroReInvestmentIndex.rest, 9) IN IF ~futuresBasisPriceNullable.ok THEN Fail ELSE
    LET averageDuration == ReadBytes(futuresBasisPriceNullable.rest, 6) IN IF ~averageDuration.ok THEN Fail ELSE
    LET averageConvexity == ReadBytes(averageDuration.rest, 6) IN IF ~averageConvexity.ok THEN Fail ELSE
    LET averageYtm == ReadBytes(averageConvexity.rest, 6) IN IF ~averageYtm.ok THEN Fail ELSE
    LET averageForwardYtmNullable == ReadBytes(averageYtm.rest, 6) IN IF ~averageForwardYtmNullable.ok THEN Fail ELSE
    LET filler1 == ReadBytes(averageForwardYtmNullable.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler1.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ filler4                   |-> filler4.value,
         indexId                   |-> indexId.value,
         standardDate              |-> standardDate.value,
         standardTime              |-> standardTime.value,
         totalProfitIndex          |-> totalProfitIndex.value,
         cleanPriceIndex           |-> cleanPriceIndex.value,
         marketPriceIndex          |-> marketPriceIndex.value,
         callReInvestmentIndex     |-> callReInvestmentIndex.value,
         zeroReInvestmentIndex     |-> zeroReInvestmentIndex.value,
         futuresBasisPriceNullable |-> futuresBasisPriceNullable.value,
         averageDuration           |-> averageDuration.value,
         averageConvexity          |-> averageConvexity.value,
         averageYtm                |-> averageYtm.value,
         averageForwardYtmNullable |-> averageForwardYtmNullable.value,
         filler1                   |-> filler1.value,
         endKeyword                |-> endKeyword.value ], endKeyword.rest)

ZeroKabiBondIndexMessage ==
    [ filler4                   |-> [i \in 1 .. 4 |-> 0],
      indexId                   |-> [i \in 1 .. 6 |-> 0],
      standardDate              |-> [i \in 1 .. 8 |-> 0],
      standardTime              |-> [i \in 1 .. 6 |-> 0],
      totalProfitIndex          |-> [i \in 1 .. 10 |-> 0],
      cleanPriceIndex           |-> [i \in 1 .. 10 |-> 0],
      marketPriceIndex          |-> [i \in 1 .. 10 |-> 0],
      callReInvestmentIndex     |-> [i \in 1 .. 10 |-> 0],
      zeroReInvestmentIndex     |-> [i \in 1 .. 10 |-> 0],
      futuresBasisPriceNullable |-> [i \in 1 .. 9 |-> 0],
      averageDuration           |-> [i \in 1 .. 6 |-> 0],
      averageConvexity          |-> [i \in 1 .. 6 |-> 0],
      averageYtm                |-> [i \in 1 .. 6 |-> 0],
      averageForwardYtmNullable |-> [i \in 1 .. 6 |-> 0],
      filler1                   |-> [i \in 1 .. 1 |-> 0],
      endKeyword                |-> [i \in 1 .. 1 |-> 0] ]

(* Kabi Bond Index Message at zero, then each field in turn at the values it is checked at *)
CheckedKabiBondIndexMessage ==
    { ZeroKabiBondIndexMessage }
        \cup { [ZeroKabiBondIndexMessage EXCEPT !.filler4 = one] : one \in Sample(4) }
        \cup { [ZeroKabiBondIndexMessage EXCEPT !.indexId = one] : one \in Sample(6) }
        \cup { [ZeroKabiBondIndexMessage EXCEPT !.standardDate = one] : one \in Sample(8) }
        \cup { [ZeroKabiBondIndexMessage EXCEPT !.standardTime = one] : one \in Sample(6) }
        \cup { [ZeroKabiBondIndexMessage EXCEPT !.totalProfitIndex = one] : one \in Sample(10) }
        \cup { [ZeroKabiBondIndexMessage EXCEPT !.cleanPriceIndex = one] : one \in Sample(10) }
        \cup { [ZeroKabiBondIndexMessage EXCEPT !.marketPriceIndex = one] : one \in Sample(10) }
        \cup { [ZeroKabiBondIndexMessage EXCEPT !.callReInvestmentIndex = one] : one \in Sample(10) }
        \cup { [ZeroKabiBondIndexMessage EXCEPT !.zeroReInvestmentIndex = one] : one \in Sample(10) }
        \cup { [ZeroKabiBondIndexMessage EXCEPT !.futuresBasisPriceNullable = one] : one \in Sample(9) }
        \cup { [ZeroKabiBondIndexMessage EXCEPT !.averageDuration = one] : one \in Sample(6) }
        \cup { [ZeroKabiBondIndexMessage EXCEPT !.averageConvexity = one] : one \in Sample(6) }
        \cup { [ZeroKabiBondIndexMessage EXCEPT !.averageYtm = one] : one \in Sample(6) }
        \cup { [ZeroKabiBondIndexMessage EXCEPT !.averageForwardYtmNullable = one] : one \in Sample(6) }
        \cup { [ZeroKabiBondIndexMessage EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroKabiBondIndexMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Nicepni Bond Index Message: 109 bytes                                   *)
(***************************************************************************)

NicepniBondIndexMessage ==
    [ filler4                 : Sample(4),
      indexId                 : Sample(6),
      standardDate            : Sample(8),
      standardTime            : Sample(6),
      totalProfitIndex        : Sample(10),
      cleanPriceIndex         : Sample(10),
      marketPriceIndex        : Sample(10),
      callReInvestmentIndex   : Sample(10),
      zeroReInvestmentIndex   : Sample(10),
      futuresBasisPrice       : Sample(9),
      averageDurationNullable : Sample(6),
      averageConvexity        : Sample(6),
      averageYtm              : Sample(6),
      averageForwardYtm       : Sample(6),
      filler1                 : Sample(1),
      endKeyword              : Sample(1) ]

EncodeNicepniBondIndexMessage(message) ==
    message.filler4
        \o message.indexId
        \o message.standardDate
        \o message.standardTime
        \o message.totalProfitIndex
        \o message.cleanPriceIndex
        \o message.marketPriceIndex
        \o message.callReInvestmentIndex
        \o message.zeroReInvestmentIndex
        \o message.futuresBasisPrice
        \o message.averageDurationNullable
        \o message.averageConvexity
        \o message.averageYtm
        \o message.averageForwardYtm
        \o message.filler1
        \o message.endKeyword

DecodeNicepniBondIndexMessage(bytes) ==
    LET filler4 == ReadBytes(bytes, 4) IN IF ~filler4.ok THEN Fail ELSE
    LET indexId == ReadBytes(filler4.rest, 6) IN IF ~indexId.ok THEN Fail ELSE
    LET standardDate == ReadBytes(indexId.rest, 8) IN IF ~standardDate.ok THEN Fail ELSE
    LET standardTime == ReadBytes(standardDate.rest, 6) IN IF ~standardTime.ok THEN Fail ELSE
    LET totalProfitIndex == ReadBytes(standardTime.rest, 10) IN IF ~totalProfitIndex.ok THEN Fail ELSE
    LET cleanPriceIndex == ReadBytes(totalProfitIndex.rest, 10) IN IF ~cleanPriceIndex.ok THEN Fail ELSE
    LET marketPriceIndex == ReadBytes(cleanPriceIndex.rest, 10) IN IF ~marketPriceIndex.ok THEN Fail ELSE
    LET callReInvestmentIndex == ReadBytes(marketPriceIndex.rest, 10) IN IF ~callReInvestmentIndex.ok THEN Fail ELSE
    LET zeroReInvestmentIndex == ReadBytes(callReInvestmentIndex.rest, 10) IN IF ~zeroReInvestmentIndex.ok THEN Fail ELSE
    LET futuresBasisPrice == ReadBytes(zeroReInvestmentIndex.rest, 9) IN IF ~futuresBasisPrice.ok THEN Fail ELSE
    LET averageDurationNullable == ReadBytes(futuresBasisPrice.rest, 6) IN IF ~averageDurationNullable.ok THEN Fail ELSE
    LET averageConvexity == ReadBytes(averageDurationNullable.rest, 6) IN IF ~averageConvexity.ok THEN Fail ELSE
    LET averageYtm == ReadBytes(averageConvexity.rest, 6) IN IF ~averageYtm.ok THEN Fail ELSE
    LET averageForwardYtm == ReadBytes(averageYtm.rest, 6) IN IF ~averageForwardYtm.ok THEN Fail ELSE
    LET filler1 == ReadBytes(averageForwardYtm.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler1.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ filler4                 |-> filler4.value,
         indexId                 |-> indexId.value,
         standardDate            |-> standardDate.value,
         standardTime            |-> standardTime.value,
         totalProfitIndex        |-> totalProfitIndex.value,
         cleanPriceIndex         |-> cleanPriceIndex.value,
         marketPriceIndex        |-> marketPriceIndex.value,
         callReInvestmentIndex   |-> callReInvestmentIndex.value,
         zeroReInvestmentIndex   |-> zeroReInvestmentIndex.value,
         futuresBasisPrice       |-> futuresBasisPrice.value,
         averageDurationNullable |-> averageDurationNullable.value,
         averageConvexity        |-> averageConvexity.value,
         averageYtm              |-> averageYtm.value,
         averageForwardYtm       |-> averageForwardYtm.value,
         filler1                 |-> filler1.value,
         endKeyword              |-> endKeyword.value ], endKeyword.rest)

ZeroNicepniBondIndexMessage ==
    [ filler4                 |-> [i \in 1 .. 4 |-> 0],
      indexId                 |-> [i \in 1 .. 6 |-> 0],
      standardDate            |-> [i \in 1 .. 8 |-> 0],
      standardTime            |-> [i \in 1 .. 6 |-> 0],
      totalProfitIndex        |-> [i \in 1 .. 10 |-> 0],
      cleanPriceIndex         |-> [i \in 1 .. 10 |-> 0],
      marketPriceIndex        |-> [i \in 1 .. 10 |-> 0],
      callReInvestmentIndex   |-> [i \in 1 .. 10 |-> 0],
      zeroReInvestmentIndex   |-> [i \in 1 .. 10 |-> 0],
      futuresBasisPrice       |-> [i \in 1 .. 9 |-> 0],
      averageDurationNullable |-> [i \in 1 .. 6 |-> 0],
      averageConvexity        |-> [i \in 1 .. 6 |-> 0],
      averageYtm              |-> [i \in 1 .. 6 |-> 0],
      averageForwardYtm       |-> [i \in 1 .. 6 |-> 0],
      filler1                 |-> [i \in 1 .. 1 |-> 0],
      endKeyword              |-> [i \in 1 .. 1 |-> 0] ]

(* Nicepni Bond Index Message at zero, then each field in turn at the values it is checked at *)
CheckedNicepniBondIndexMessage ==
    { ZeroNicepniBondIndexMessage }
        \cup { [ZeroNicepniBondIndexMessage EXCEPT !.filler4 = one] : one \in Sample(4) }
        \cup { [ZeroNicepniBondIndexMessage EXCEPT !.indexId = one] : one \in Sample(6) }
        \cup { [ZeroNicepniBondIndexMessage EXCEPT !.standardDate = one] : one \in Sample(8) }
        \cup { [ZeroNicepniBondIndexMessage EXCEPT !.standardTime = one] : one \in Sample(6) }
        \cup { [ZeroNicepniBondIndexMessage EXCEPT !.totalProfitIndex = one] : one \in Sample(10) }
        \cup { [ZeroNicepniBondIndexMessage EXCEPT !.cleanPriceIndex = one] : one \in Sample(10) }
        \cup { [ZeroNicepniBondIndexMessage EXCEPT !.marketPriceIndex = one] : one \in Sample(10) }
        \cup { [ZeroNicepniBondIndexMessage EXCEPT !.callReInvestmentIndex = one] : one \in Sample(10) }
        \cup { [ZeroNicepniBondIndexMessage EXCEPT !.zeroReInvestmentIndex = one] : one \in Sample(10) }
        \cup { [ZeroNicepniBondIndexMessage EXCEPT !.futuresBasisPrice = one] : one \in Sample(9) }
        \cup { [ZeroNicepniBondIndexMessage EXCEPT !.averageDurationNullable = one] : one \in Sample(6) }
        \cup { [ZeroNicepniBondIndexMessage EXCEPT !.averageConvexity = one] : one \in Sample(6) }
        \cup { [ZeroNicepniBondIndexMessage EXCEPT !.averageYtm = one] : one \in Sample(6) }
        \cup { [ZeroNicepniBondIndexMessage EXCEPT !.averageForwardYtm = one] : one \in Sample(6) }
        \cup { [ZeroNicepniBondIndexMessage EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroNicepniBondIndexMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Domestic Etf Inav Message: 65 bytes                                     *)
(***************************************************************************)

DomesticEtfInavMessage ==
    [ isin                 : Sample(12),
      time                 : Sample(6),
      previousNav          : Sample(9),
      duringMarketfinalNav : Sample(9),
      filler28             : Sample(28),
      endKeyword           : Sample(1) ]

EncodeDomesticEtfInavMessage(message) ==
    message.isin
        \o message.time
        \o message.previousNav
        \o message.duringMarketfinalNav
        \o message.filler28
        \o message.endKeyword

DecodeDomesticEtfInavMessage(bytes) ==
    LET isin == ReadBytes(bytes, 12) IN IF ~isin.ok THEN Fail ELSE
    LET time == ReadBytes(isin.rest, 6) IN IF ~time.ok THEN Fail ELSE
    LET previousNav == ReadBytes(time.rest, 9) IN IF ~previousNav.ok THEN Fail ELSE
    LET duringMarketfinalNav == ReadBytes(previousNav.rest, 9) IN IF ~duringMarketfinalNav.ok THEN Fail ELSE
    LET filler28 == ReadBytes(duringMarketfinalNav.rest, 28) IN IF ~filler28.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler28.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ isin                 |-> isin.value,
         time                 |-> time.value,
         previousNav          |-> previousNav.value,
         duringMarketfinalNav |-> duringMarketfinalNav.value,
         filler28             |-> filler28.value,
         endKeyword           |-> endKeyword.value ], endKeyword.rest)

ZeroDomesticEtfInavMessage ==
    [ isin                 |-> [i \in 1 .. 12 |-> 0],
      time                 |-> [i \in 1 .. 6 |-> 0],
      previousNav          |-> [i \in 1 .. 9 |-> 0],
      duringMarketfinalNav |-> [i \in 1 .. 9 |-> 0],
      filler28             |-> [i \in 1 .. 28 |-> 0],
      endKeyword           |-> [i \in 1 .. 1 |-> 0] ]

(* Domestic Etf Inav Message at zero, then each field in turn at the values it is checked at *)
CheckedDomesticEtfInavMessage ==
    { ZeroDomesticEtfInavMessage }
        \cup { [ZeroDomesticEtfInavMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroDomesticEtfInavMessage EXCEPT !.time = one] : one \in Sample(6) }
        \cup { [ZeroDomesticEtfInavMessage EXCEPT !.previousNav = one] : one \in Sample(9) }
        \cup { [ZeroDomesticEtfInavMessage EXCEPT !.duringMarketfinalNav = one] : one \in Sample(9) }
        \cup { [ZeroDomesticEtfInavMessage EXCEPT !.filler28 = one] : one \in Sample(28) }
        \cup { [ZeroDomesticEtfInavMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Domestic Etf Estimated Inav Message: 45 bytes                           *)
(***************************************************************************)

DomesticEtfEstimatedInavMessage ==
    [ isin                       : Sample(12),
      time                       : Sample(6),
      previousNav                : Sample(9),
      duringMarketfinalMarketNav : Sample(9),
      filler8                    : Sample(8),
      endKeyword                 : Sample(1) ]

EncodeDomesticEtfEstimatedInavMessage(message) ==
    message.isin
        \o message.time
        \o message.previousNav
        \o message.duringMarketfinalMarketNav
        \o message.filler8
        \o message.endKeyword

DecodeDomesticEtfEstimatedInavMessage(bytes) ==
    LET isin == ReadBytes(bytes, 12) IN IF ~isin.ok THEN Fail ELSE
    LET time == ReadBytes(isin.rest, 6) IN IF ~time.ok THEN Fail ELSE
    LET previousNav == ReadBytes(time.rest, 9) IN IF ~previousNav.ok THEN Fail ELSE
    LET duringMarketfinalMarketNav == ReadBytes(previousNav.rest, 9) IN IF ~duringMarketfinalMarketNav.ok THEN Fail ELSE
    LET filler8 == ReadBytes(duringMarketfinalMarketNav.rest, 8) IN IF ~filler8.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler8.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ isin                       |-> isin.value,
         time                       |-> time.value,
         previousNav                |-> previousNav.value,
         duringMarketfinalMarketNav |-> duringMarketfinalMarketNav.value,
         filler8                    |-> filler8.value,
         endKeyword                 |-> endKeyword.value ], endKeyword.rest)

ZeroDomesticEtfEstimatedInavMessage ==
    [ isin                       |-> [i \in 1 .. 12 |-> 0],
      time                       |-> [i \in 1 .. 6 |-> 0],
      previousNav                |-> [i \in 1 .. 9 |-> 0],
      duringMarketfinalMarketNav |-> [i \in 1 .. 9 |-> 0],
      filler8                    |-> [i \in 1 .. 8 |-> 0],
      endKeyword                 |-> [i \in 1 .. 1 |-> 0] ]

(* Domestic Etf Estimated Inav Message at zero, then each field in turn at the values it is checked at *)
CheckedDomesticEtfEstimatedInavMessage ==
    { ZeroDomesticEtfEstimatedInavMessage }
        \cup { [ZeroDomesticEtfEstimatedInavMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroDomesticEtfEstimatedInavMessage EXCEPT !.time = one] : one \in Sample(6) }
        \cup { [ZeroDomesticEtfEstimatedInavMessage EXCEPT !.previousNav = one] : one \in Sample(9) }
        \cup { [ZeroDomesticEtfEstimatedInavMessage EXCEPT !.duringMarketfinalMarketNav = one] : one \in Sample(9) }
        \cup { [ZeroDomesticEtfEstimatedInavMessage EXCEPT !.filler8 = one] : one \in Sample(8) }
        \cup { [ZeroDomesticEtfEstimatedInavMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Global Etf Inav Message: 65 bytes                                       *)
(***************************************************************************)

GlobalEtfInavMessage ==
    [ isin                 : Sample(12),
      time                 : Sample(6),
      previousNav          : Sample(9),
      duringMarketfinalNav : Sample(9),
      filler28             : Sample(28),
      endKeyword           : Sample(1) ]

EncodeGlobalEtfInavMessage(message) ==
    message.isin
        \o message.time
        \o message.previousNav
        \o message.duringMarketfinalNav
        \o message.filler28
        \o message.endKeyword

DecodeGlobalEtfInavMessage(bytes) ==
    LET isin == ReadBytes(bytes, 12) IN IF ~isin.ok THEN Fail ELSE
    LET time == ReadBytes(isin.rest, 6) IN IF ~time.ok THEN Fail ELSE
    LET previousNav == ReadBytes(time.rest, 9) IN IF ~previousNav.ok THEN Fail ELSE
    LET duringMarketfinalNav == ReadBytes(previousNav.rest, 9) IN IF ~duringMarketfinalNav.ok THEN Fail ELSE
    LET filler28 == ReadBytes(duringMarketfinalNav.rest, 28) IN IF ~filler28.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler28.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ isin                 |-> isin.value,
         time                 |-> time.value,
         previousNav          |-> previousNav.value,
         duringMarketfinalNav |-> duringMarketfinalNav.value,
         filler28             |-> filler28.value,
         endKeyword           |-> endKeyword.value ], endKeyword.rest)

ZeroGlobalEtfInavMessage ==
    [ isin                 |-> [i \in 1 .. 12 |-> 0],
      time                 |-> [i \in 1 .. 6 |-> 0],
      previousNav          |-> [i \in 1 .. 9 |-> 0],
      duringMarketfinalNav |-> [i \in 1 .. 9 |-> 0],
      filler28             |-> [i \in 1 .. 28 |-> 0],
      endKeyword           |-> [i \in 1 .. 1 |-> 0] ]

(* Global Etf Inav Message at zero, then each field in turn at the values it is checked at *)
CheckedGlobalEtfInavMessage ==
    { ZeroGlobalEtfInavMessage }
        \cup { [ZeroGlobalEtfInavMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroGlobalEtfInavMessage EXCEPT !.time = one] : one \in Sample(6) }
        \cup { [ZeroGlobalEtfInavMessage EXCEPT !.previousNav = one] : one \in Sample(9) }
        \cup { [ZeroGlobalEtfInavMessage EXCEPT !.duringMarketfinalNav = one] : one \in Sample(9) }
        \cup { [ZeroGlobalEtfInavMessage EXCEPT !.filler28 = one] : one \in Sample(28) }
        \cup { [ZeroGlobalEtfInavMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Etf Tracking Error Message: 55 bytes                                    *)
(***************************************************************************)

EtfTrackingErrorMessage ==
    [ isin               : Sample(12),
      seqNumber          : Sample(8),
      date               : Sample(8),
      trackingError      : Sample(9),
      disparateRatioSign : Sample(1),
      disparateRatio     : Sample(9),
      filler7            : Sample(7),
      endKeyword         : Sample(1) ]

EncodeEtfTrackingErrorMessage(message) ==
    message.isin
        \o message.seqNumber
        \o message.date
        \o message.trackingError
        \o message.disparateRatioSign
        \o message.disparateRatio
        \o message.filler7
        \o message.endKeyword

DecodeEtfTrackingErrorMessage(bytes) ==
    LET isin == ReadBytes(bytes, 12) IN IF ~isin.ok THEN Fail ELSE
    LET seqNumber == ReadBytes(isin.rest, 8) IN IF ~seqNumber.ok THEN Fail ELSE
    LET date == ReadBytes(seqNumber.rest, 8) IN IF ~date.ok THEN Fail ELSE
    LET trackingError == ReadBytes(date.rest, 9) IN IF ~trackingError.ok THEN Fail ELSE
    LET disparateRatioSign == ReadBytes(trackingError.rest, 1) IN IF ~disparateRatioSign.ok THEN Fail ELSE
    LET disparateRatio == ReadBytes(disparateRatioSign.rest, 9) IN IF ~disparateRatio.ok THEN Fail ELSE
    LET filler7 == ReadBytes(disparateRatio.rest, 7) IN IF ~filler7.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler7.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ isin               |-> isin.value,
         seqNumber          |-> seqNumber.value,
         date               |-> date.value,
         trackingError      |-> trackingError.value,
         disparateRatioSign |-> disparateRatioSign.value,
         disparateRatio     |-> disparateRatio.value,
         filler7            |-> filler7.value,
         endKeyword         |-> endKeyword.value ], endKeyword.rest)

ZeroEtfTrackingErrorMessage ==
    [ isin               |-> [i \in 1 .. 12 |-> 0],
      seqNumber          |-> [i \in 1 .. 8 |-> 0],
      date               |-> [i \in 1 .. 8 |-> 0],
      trackingError      |-> [i \in 1 .. 9 |-> 0],
      disparateRatioSign |-> [i \in 1 .. 1 |-> 0],
      disparateRatio     |-> [i \in 1 .. 9 |-> 0],
      filler7            |-> [i \in 1 .. 7 |-> 0],
      endKeyword         |-> [i \in 1 .. 1 |-> 0] ]

(* Etf Tracking Error Message at zero, then each field in turn at the values it is checked at *)
CheckedEtfTrackingErrorMessage ==
    { ZeroEtfTrackingErrorMessage }
        \cup { [ZeroEtfTrackingErrorMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroEtfTrackingErrorMessage EXCEPT !.seqNumber = one] : one \in Sample(8) }
        \cup { [ZeroEtfTrackingErrorMessage EXCEPT !.date = one] : one \in Sample(8) }
        \cup { [ZeroEtfTrackingErrorMessage EXCEPT !.trackingError = one] : one \in Sample(9) }
        \cup { [ZeroEtfTrackingErrorMessage EXCEPT !.disparateRatioSign = one] : one \in Sample(1) }
        \cup { [ZeroEtfTrackingErrorMessage EXCEPT !.disparateRatio = one] : one \in Sample(9) }
        \cup { [ZeroEtfTrackingErrorMessage EXCEPT !.filler7 = one] : one \in Sample(7) }
        \cup { [ZeroEtfTrackingErrorMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Global Etf Tracking Error Message: 55 bytes                             *)
(***************************************************************************)

GlobalEtfTrackingErrorMessage ==
    [ isin               : Sample(12),
      seqNumber          : Sample(8),
      date               : Sample(8),
      trackingError      : Sample(9),
      disparateRatioSign : Sample(1),
      disparateRatio     : Sample(9),
      filler7            : Sample(7),
      endKeyword         : Sample(1) ]

EncodeGlobalEtfTrackingErrorMessage(message) ==
    message.isin
        \o message.seqNumber
        \o message.date
        \o message.trackingError
        \o message.disparateRatioSign
        \o message.disparateRatio
        \o message.filler7
        \o message.endKeyword

DecodeGlobalEtfTrackingErrorMessage(bytes) ==
    LET isin == ReadBytes(bytes, 12) IN IF ~isin.ok THEN Fail ELSE
    LET seqNumber == ReadBytes(isin.rest, 8) IN IF ~seqNumber.ok THEN Fail ELSE
    LET date == ReadBytes(seqNumber.rest, 8) IN IF ~date.ok THEN Fail ELSE
    LET trackingError == ReadBytes(date.rest, 9) IN IF ~trackingError.ok THEN Fail ELSE
    LET disparateRatioSign == ReadBytes(trackingError.rest, 1) IN IF ~disparateRatioSign.ok THEN Fail ELSE
    LET disparateRatio == ReadBytes(disparateRatioSign.rest, 9) IN IF ~disparateRatio.ok THEN Fail ELSE
    LET filler7 == ReadBytes(disparateRatio.rest, 7) IN IF ~filler7.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler7.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ isin               |-> isin.value,
         seqNumber          |-> seqNumber.value,
         date               |-> date.value,
         trackingError      |-> trackingError.value,
         disparateRatioSign |-> disparateRatioSign.value,
         disparateRatio     |-> disparateRatio.value,
         filler7            |-> filler7.value,
         endKeyword         |-> endKeyword.value ], endKeyword.rest)

ZeroGlobalEtfTrackingErrorMessage ==
    [ isin               |-> [i \in 1 .. 12 |-> 0],
      seqNumber          |-> [i \in 1 .. 8 |-> 0],
      date               |-> [i \in 1 .. 8 |-> 0],
      trackingError      |-> [i \in 1 .. 9 |-> 0],
      disparateRatioSign |-> [i \in 1 .. 1 |-> 0],
      disparateRatio     |-> [i \in 1 .. 9 |-> 0],
      filler7            |-> [i \in 1 .. 7 |-> 0],
      endKeyword         |-> [i \in 1 .. 1 |-> 0] ]

(* Global Etf Tracking Error Message at zero, then each field in turn at the values it is checked at *)
CheckedGlobalEtfTrackingErrorMessage ==
    { ZeroGlobalEtfTrackingErrorMessage }
        \cup { [ZeroGlobalEtfTrackingErrorMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroGlobalEtfTrackingErrorMessage EXCEPT !.seqNumber = one] : one \in Sample(8) }
        \cup { [ZeroGlobalEtfTrackingErrorMessage EXCEPT !.date = one] : one \in Sample(8) }
        \cup { [ZeroGlobalEtfTrackingErrorMessage EXCEPT !.trackingError = one] : one \in Sample(9) }
        \cup { [ZeroGlobalEtfTrackingErrorMessage EXCEPT !.disparateRatioSign = one] : one \in Sample(1) }
        \cup { [ZeroGlobalEtfTrackingErrorMessage EXCEPT !.disparateRatio = one] : one \in Sample(9) }
        \cup { [ZeroGlobalEtfTrackingErrorMessage EXCEPT !.filler7 = one] : one \in Sample(7) }
        \cup { [ZeroGlobalEtfTrackingErrorMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Etp Pdf Message: 155 bytes                                              *)
(***************************************************************************)

EtpPdfMessage ==
    [ isin                                                        : Sample(12),
      dataSeqNumber                                               : Sample(8),
      date                                                        : Sample(8),
      officeConsignmentCompanysRegistrationNumber                 : Sample(3),
      compositionIssueNumber                                      : Sample(4),
      compositionIssueCode                                        : Sample(12),
      cuUnitSharenumberOfContractkrwCashusdCashconvertedAmountkrw : Sample(18),
      compositionIssueMarketType                                  : Sample(1),
      compositionIssueName                                        : Sample(40),
      parValueAmountCashAmountConvertedAmountKrw                  : Sample(18),
      profitDistributionBasisDate                                 : Sample(8),
      appraisedValue                                              : Sample(18),
      filler4                                                     : Sample(4),
      endKeyword                                                  : Sample(1) ]

EncodeEtpPdfMessage(message) ==
    message.isin
        \o message.dataSeqNumber
        \o message.date
        \o message.officeConsignmentCompanysRegistrationNumber
        \o message.compositionIssueNumber
        \o message.compositionIssueCode
        \o message.cuUnitSharenumberOfContractkrwCashusdCashconvertedAmountkrw
        \o message.compositionIssueMarketType
        \o message.compositionIssueName
        \o message.parValueAmountCashAmountConvertedAmountKrw
        \o message.profitDistributionBasisDate
        \o message.appraisedValue
        \o message.filler4
        \o message.endKeyword

DecodeEtpPdfMessage(bytes) ==
    LET isin == ReadBytes(bytes, 12) IN IF ~isin.ok THEN Fail ELSE
    LET dataSeqNumber == ReadBytes(isin.rest, 8) IN IF ~dataSeqNumber.ok THEN Fail ELSE
    LET date == ReadBytes(dataSeqNumber.rest, 8) IN IF ~date.ok THEN Fail ELSE
    LET officeConsignmentCompanysRegistrationNumber == ReadBytes(date.rest, 3) IN IF ~officeConsignmentCompanysRegistrationNumber.ok THEN Fail ELSE
    LET compositionIssueNumber == ReadBytes(officeConsignmentCompanysRegistrationNumber.rest, 4) IN IF ~compositionIssueNumber.ok THEN Fail ELSE
    LET compositionIssueCode == ReadBytes(compositionIssueNumber.rest, 12) IN IF ~compositionIssueCode.ok THEN Fail ELSE
    LET cuUnitSharenumberOfContractkrwCashusdCashconvertedAmountkrw == ReadBytes(compositionIssueCode.rest, 18) IN IF ~cuUnitSharenumberOfContractkrwCashusdCashconvertedAmountkrw.ok THEN Fail ELSE
    LET compositionIssueMarketType == ReadBytes(cuUnitSharenumberOfContractkrwCashusdCashconvertedAmountkrw.rest, 1) IN IF ~compositionIssueMarketType.ok THEN Fail ELSE
    LET compositionIssueName == ReadBytes(compositionIssueMarketType.rest, 40) IN IF ~compositionIssueName.ok THEN Fail ELSE
    LET parValueAmountCashAmountConvertedAmountKrw == ReadBytes(compositionIssueName.rest, 18) IN IF ~parValueAmountCashAmountConvertedAmountKrw.ok THEN Fail ELSE
    LET profitDistributionBasisDate == ReadBytes(parValueAmountCashAmountConvertedAmountKrw.rest, 8) IN IF ~profitDistributionBasisDate.ok THEN Fail ELSE
    LET appraisedValue == ReadBytes(profitDistributionBasisDate.rest, 18) IN IF ~appraisedValue.ok THEN Fail ELSE
    LET filler4 == ReadBytes(appraisedValue.rest, 4) IN IF ~filler4.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler4.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ isin                                                        |-> isin.value,
         dataSeqNumber                                               |-> dataSeqNumber.value,
         date                                                        |-> date.value,
         officeConsignmentCompanysRegistrationNumber                 |-> officeConsignmentCompanysRegistrationNumber.value,
         compositionIssueNumber                                      |-> compositionIssueNumber.value,
         compositionIssueCode                                        |-> compositionIssueCode.value,
         cuUnitSharenumberOfContractkrwCashusdCashconvertedAmountkrw |-> cuUnitSharenumberOfContractkrwCashusdCashconvertedAmountkrw.value,
         compositionIssueMarketType                                  |-> compositionIssueMarketType.value,
         compositionIssueName                                        |-> compositionIssueName.value,
         parValueAmountCashAmountConvertedAmountKrw                  |-> parValueAmountCashAmountConvertedAmountKrw.value,
         profitDistributionBasisDate                                 |-> profitDistributionBasisDate.value,
         appraisedValue                                              |-> appraisedValue.value,
         filler4                                                     |-> filler4.value,
         endKeyword                                                  |-> endKeyword.value ], endKeyword.rest)

ZeroEtpPdfMessage ==
    [ isin                                                        |-> [i \in 1 .. 12 |-> 0],
      dataSeqNumber                                               |-> [i \in 1 .. 8 |-> 0],
      date                                                        |-> [i \in 1 .. 8 |-> 0],
      officeConsignmentCompanysRegistrationNumber                 |-> [i \in 1 .. 3 |-> 0],
      compositionIssueNumber                                      |-> [i \in 1 .. 4 |-> 0],
      compositionIssueCode                                        |-> [i \in 1 .. 12 |-> 0],
      cuUnitSharenumberOfContractkrwCashusdCashconvertedAmountkrw |-> [i \in 1 .. 18 |-> 0],
      compositionIssueMarketType                                  |-> [i \in 1 .. 1 |-> 0],
      compositionIssueName                                        |-> [i \in 1 .. 40 |-> 0],
      parValueAmountCashAmountConvertedAmountKrw                  |-> [i \in 1 .. 18 |-> 0],
      profitDistributionBasisDate                                 |-> [i \in 1 .. 8 |-> 0],
      appraisedValue                                              |-> [i \in 1 .. 18 |-> 0],
      filler4                                                     |-> [i \in 1 .. 4 |-> 0],
      endKeyword                                                  |-> [i \in 1 .. 1 |-> 0] ]

(* Etp Pdf Message at zero, then each field in turn at the values it is checked at *)
CheckedEtpPdfMessage ==
    { ZeroEtpPdfMessage }
        \cup { [ZeroEtpPdfMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroEtpPdfMessage EXCEPT !.dataSeqNumber = one] : one \in Sample(8) }
        \cup { [ZeroEtpPdfMessage EXCEPT !.date = one] : one \in Sample(8) }
        \cup { [ZeroEtpPdfMessage EXCEPT !.officeConsignmentCompanysRegistrationNumber = one] : one \in Sample(3) }
        \cup { [ZeroEtpPdfMessage EXCEPT !.compositionIssueNumber = one] : one \in Sample(4) }
        \cup { [ZeroEtpPdfMessage EXCEPT !.compositionIssueCode = one] : one \in Sample(12) }
        \cup { [ZeroEtpPdfMessage EXCEPT !.cuUnitSharenumberOfContractkrwCashusdCashconvertedAmountkrw = one] : one \in Sample(18) }
        \cup { [ZeroEtpPdfMessage EXCEPT !.compositionIssueMarketType = one] : one \in Sample(1) }
        \cup { [ZeroEtpPdfMessage EXCEPT !.compositionIssueName = one] : one \in Sample(40) }
        \cup { [ZeroEtpPdfMessage EXCEPT !.parValueAmountCashAmountConvertedAmountKrw = one] : one \in Sample(18) }
        \cup { [ZeroEtpPdfMessage EXCEPT !.profitDistributionBasisDate = one] : one \in Sample(8) }
        \cup { [ZeroEtpPdfMessage EXCEPT !.appraisedValue = one] : one \in Sample(18) }
        \cup { [ZeroEtpPdfMessage EXCEPT !.filler4 = one] : one \in Sample(4) }
        \cup { [ZeroEtpPdfMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Etp Operator Information Message: 125 bytes                             *)
(***************************************************************************)

EtpOperatorInformationMessage ==
    [ isin                                        : Sample(12),
      seqNumber                                   : Sample(8),
      officeConsignmentCompanysRegistrationNumber : Sample(3),
      operatorCode                                : Sample(6),
      operatorAbbreviatedNameKorean               : Sample(50),
      operatorAbbreviatedNameEnglish              : Sample(40),
      filler5                                     : Sample(5),
      endKeyword                                  : Sample(1) ]

EncodeEtpOperatorInformationMessage(message) ==
    message.isin
        \o message.seqNumber
        \o message.officeConsignmentCompanysRegistrationNumber
        \o message.operatorCode
        \o message.operatorAbbreviatedNameKorean
        \o message.operatorAbbreviatedNameEnglish
        \o message.filler5
        \o message.endKeyword

DecodeEtpOperatorInformationMessage(bytes) ==
    LET isin == ReadBytes(bytes, 12) IN IF ~isin.ok THEN Fail ELSE
    LET seqNumber == ReadBytes(isin.rest, 8) IN IF ~seqNumber.ok THEN Fail ELSE
    LET officeConsignmentCompanysRegistrationNumber == ReadBytes(seqNumber.rest, 3) IN IF ~officeConsignmentCompanysRegistrationNumber.ok THEN Fail ELSE
    LET operatorCode == ReadBytes(officeConsignmentCompanysRegistrationNumber.rest, 6) IN IF ~operatorCode.ok THEN Fail ELSE
    LET operatorAbbreviatedNameKorean == ReadBytes(operatorCode.rest, 50) IN IF ~operatorAbbreviatedNameKorean.ok THEN Fail ELSE
    LET operatorAbbreviatedNameEnglish == ReadBytes(operatorAbbreviatedNameKorean.rest, 40) IN IF ~operatorAbbreviatedNameEnglish.ok THEN Fail ELSE
    LET filler5 == ReadBytes(operatorAbbreviatedNameEnglish.rest, 5) IN IF ~filler5.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler5.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ isin                                        |-> isin.value,
         seqNumber                                   |-> seqNumber.value,
         officeConsignmentCompanysRegistrationNumber |-> officeConsignmentCompanysRegistrationNumber.value,
         operatorCode                                |-> operatorCode.value,
         operatorAbbreviatedNameKorean               |-> operatorAbbreviatedNameKorean.value,
         operatorAbbreviatedNameEnglish              |-> operatorAbbreviatedNameEnglish.value,
         filler5                                     |-> filler5.value,
         endKeyword                                  |-> endKeyword.value ], endKeyword.rest)

ZeroEtpOperatorInformationMessage ==
    [ isin                                        |-> [i \in 1 .. 12 |-> 0],
      seqNumber                                   |-> [i \in 1 .. 8 |-> 0],
      officeConsignmentCompanysRegistrationNumber |-> [i \in 1 .. 3 |-> 0],
      operatorCode                                |-> [i \in 1 .. 6 |-> 0],
      operatorAbbreviatedNameKorean               |-> [i \in 1 .. 50 |-> 0],
      operatorAbbreviatedNameEnglish              |-> [i \in 1 .. 40 |-> 0],
      filler5                                     |-> [i \in 1 .. 5 |-> 0],
      endKeyword                                  |-> [i \in 1 .. 1 |-> 0] ]

(* Etp Operator Information Message at zero, then each field in turn at the values it is checked at *)
CheckedEtpOperatorInformationMessage ==
    { ZeroEtpOperatorInformationMessage }
        \cup { [ZeroEtpOperatorInformationMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroEtpOperatorInformationMessage EXCEPT !.seqNumber = one] : one \in Sample(8) }
        \cup { [ZeroEtpOperatorInformationMessage EXCEPT !.officeConsignmentCompanysRegistrationNumber = one] : one \in Sample(3) }
        \cup { [ZeroEtpOperatorInformationMessage EXCEPT !.operatorCode = one] : one \in Sample(6) }
        \cup { [ZeroEtpOperatorInformationMessage EXCEPT !.operatorAbbreviatedNameKorean = one] : one \in Sample(50) }
        \cup { [ZeroEtpOperatorInformationMessage EXCEPT !.operatorAbbreviatedNameEnglish = one] : one \in Sample(40) }
        \cup { [ZeroEtpOperatorInformationMessage EXCEPT !.filler5 = one] : one \in Sample(5) }
        \cup { [ZeroEtpOperatorInformationMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Etp Transfer Agent Batch Message: 245 bytes                             *)
(***************************************************************************)

EtpTransferAgentBatchMessage ==
    [ isin                                                           : Sample(12),
      dataSeqNumber                                                  : Sample(8),
      filler10                                                       : Sample(10),
      etfFlowNetAssetTotalAmount                                     : Sample(15),
      etfForeignNetAssetValueAmount                                  : Sample(15),
      etfNetAssetValueAmount                                         : Sample(9),
      etfForeignFlowNetAssetTotalAmount                              : Sample(15),
      etfForeignNetAssetTotal                                        : Sample(15),
      etfForeignFinalNetAssetValue                                   : Sample(9),
      etfCuQuantity                                                  : Sample(8),
      previousDaysTaxBaseNav                                         : Sample(9),
      previousDaysTaxBaseNavBeforeDividend                           : Sample(9),
      previousDaysCashDividendAmount                                 : Sample(12),
      taxBaseNavAsOfTheDayBeforeThePreviousDay                       : Sample(9),
      previousDaysNonTaxableBasePriceForOverseasStocks               : Sample(9),
      previousDaysNonTaxableBasePriceBeforeDividendForOverseasStocks : Sample(9),
      dayBeforePreviousDaysNonTaxableBasePriceForOverseasStocks      : Sample(9),
      numberOfFreeFloatingEtfShares                                  : Sample(16),
      filler46                                                       : Sample(46),
      endKeyword                                                     : Sample(1) ]

EncodeEtpTransferAgentBatchMessage(message) ==
    message.isin
        \o message.dataSeqNumber
        \o message.filler10
        \o message.etfFlowNetAssetTotalAmount
        \o message.etfForeignNetAssetValueAmount
        \o message.etfNetAssetValueAmount
        \o message.etfForeignFlowNetAssetTotalAmount
        \o message.etfForeignNetAssetTotal
        \o message.etfForeignFinalNetAssetValue
        \o message.etfCuQuantity
        \o message.previousDaysTaxBaseNav
        \o message.previousDaysTaxBaseNavBeforeDividend
        \o message.previousDaysCashDividendAmount
        \o message.taxBaseNavAsOfTheDayBeforeThePreviousDay
        \o message.previousDaysNonTaxableBasePriceForOverseasStocks
        \o message.previousDaysNonTaxableBasePriceBeforeDividendForOverseasStocks
        \o message.dayBeforePreviousDaysNonTaxableBasePriceForOverseasStocks
        \o message.numberOfFreeFloatingEtfShares
        \o message.filler46
        \o message.endKeyword

DecodeEtpTransferAgentBatchMessage(bytes) ==
    LET isin == ReadBytes(bytes, 12) IN IF ~isin.ok THEN Fail ELSE
    LET dataSeqNumber == ReadBytes(isin.rest, 8) IN IF ~dataSeqNumber.ok THEN Fail ELSE
    LET filler10 == ReadBytes(dataSeqNumber.rest, 10) IN IF ~filler10.ok THEN Fail ELSE
    LET etfFlowNetAssetTotalAmount == ReadBytes(filler10.rest, 15) IN IF ~etfFlowNetAssetTotalAmount.ok THEN Fail ELSE
    LET etfForeignNetAssetValueAmount == ReadBytes(etfFlowNetAssetTotalAmount.rest, 15) IN IF ~etfForeignNetAssetValueAmount.ok THEN Fail ELSE
    LET etfNetAssetValueAmount == ReadBytes(etfForeignNetAssetValueAmount.rest, 9) IN IF ~etfNetAssetValueAmount.ok THEN Fail ELSE
    LET etfForeignFlowNetAssetTotalAmount == ReadBytes(etfNetAssetValueAmount.rest, 15) IN IF ~etfForeignFlowNetAssetTotalAmount.ok THEN Fail ELSE
    LET etfForeignNetAssetTotal == ReadBytes(etfForeignFlowNetAssetTotalAmount.rest, 15) IN IF ~etfForeignNetAssetTotal.ok THEN Fail ELSE
    LET etfForeignFinalNetAssetValue == ReadBytes(etfForeignNetAssetTotal.rest, 9) IN IF ~etfForeignFinalNetAssetValue.ok THEN Fail ELSE
    LET etfCuQuantity == ReadBytes(etfForeignFinalNetAssetValue.rest, 8) IN IF ~etfCuQuantity.ok THEN Fail ELSE
    LET previousDaysTaxBaseNav == ReadBytes(etfCuQuantity.rest, 9) IN IF ~previousDaysTaxBaseNav.ok THEN Fail ELSE
    LET previousDaysTaxBaseNavBeforeDividend == ReadBytes(previousDaysTaxBaseNav.rest, 9) IN IF ~previousDaysTaxBaseNavBeforeDividend.ok THEN Fail ELSE
    LET previousDaysCashDividendAmount == ReadBytes(previousDaysTaxBaseNavBeforeDividend.rest, 12) IN IF ~previousDaysCashDividendAmount.ok THEN Fail ELSE
    LET taxBaseNavAsOfTheDayBeforeThePreviousDay == ReadBytes(previousDaysCashDividendAmount.rest, 9) IN IF ~taxBaseNavAsOfTheDayBeforeThePreviousDay.ok THEN Fail ELSE
    LET previousDaysNonTaxableBasePriceForOverseasStocks == ReadBytes(taxBaseNavAsOfTheDayBeforeThePreviousDay.rest, 9) IN IF ~previousDaysNonTaxableBasePriceForOverseasStocks.ok THEN Fail ELSE
    LET previousDaysNonTaxableBasePriceBeforeDividendForOverseasStocks == ReadBytes(previousDaysNonTaxableBasePriceForOverseasStocks.rest, 9) IN IF ~previousDaysNonTaxableBasePriceBeforeDividendForOverseasStocks.ok THEN Fail ELSE
    LET dayBeforePreviousDaysNonTaxableBasePriceForOverseasStocks == ReadBytes(previousDaysNonTaxableBasePriceBeforeDividendForOverseasStocks.rest, 9) IN IF ~dayBeforePreviousDaysNonTaxableBasePriceForOverseasStocks.ok THEN Fail ELSE
    LET numberOfFreeFloatingEtfShares == ReadBytes(dayBeforePreviousDaysNonTaxableBasePriceForOverseasStocks.rest, 16) IN IF ~numberOfFreeFloatingEtfShares.ok THEN Fail ELSE
    LET filler46 == ReadBytes(numberOfFreeFloatingEtfShares.rest, 46) IN IF ~filler46.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler46.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ isin                                                           |-> isin.value,
         dataSeqNumber                                                  |-> dataSeqNumber.value,
         filler10                                                       |-> filler10.value,
         etfFlowNetAssetTotalAmount                                     |-> etfFlowNetAssetTotalAmount.value,
         etfForeignNetAssetValueAmount                                  |-> etfForeignNetAssetValueAmount.value,
         etfNetAssetValueAmount                                         |-> etfNetAssetValueAmount.value,
         etfForeignFlowNetAssetTotalAmount                              |-> etfForeignFlowNetAssetTotalAmount.value,
         etfForeignNetAssetTotal                                        |-> etfForeignNetAssetTotal.value,
         etfForeignFinalNetAssetValue                                   |-> etfForeignFinalNetAssetValue.value,
         etfCuQuantity                                                  |-> etfCuQuantity.value,
         previousDaysTaxBaseNav                                         |-> previousDaysTaxBaseNav.value,
         previousDaysTaxBaseNavBeforeDividend                           |-> previousDaysTaxBaseNavBeforeDividend.value,
         previousDaysCashDividendAmount                                 |-> previousDaysCashDividendAmount.value,
         taxBaseNavAsOfTheDayBeforeThePreviousDay                       |-> taxBaseNavAsOfTheDayBeforeThePreviousDay.value,
         previousDaysNonTaxableBasePriceForOverseasStocks               |-> previousDaysNonTaxableBasePriceForOverseasStocks.value,
         previousDaysNonTaxableBasePriceBeforeDividendForOverseasStocks |-> previousDaysNonTaxableBasePriceBeforeDividendForOverseasStocks.value,
         dayBeforePreviousDaysNonTaxableBasePriceForOverseasStocks      |-> dayBeforePreviousDaysNonTaxableBasePriceForOverseasStocks.value,
         numberOfFreeFloatingEtfShares                                  |-> numberOfFreeFloatingEtfShares.value,
         filler46                                                       |-> filler46.value,
         endKeyword                                                     |-> endKeyword.value ], endKeyword.rest)

ZeroEtpTransferAgentBatchMessage ==
    [ isin                                                           |-> [i \in 1 .. 12 |-> 0],
      dataSeqNumber                                                  |-> [i \in 1 .. 8 |-> 0],
      filler10                                                       |-> [i \in 1 .. 10 |-> 0],
      etfFlowNetAssetTotalAmount                                     |-> [i \in 1 .. 15 |-> 0],
      etfForeignNetAssetValueAmount                                  |-> [i \in 1 .. 15 |-> 0],
      etfNetAssetValueAmount                                         |-> [i \in 1 .. 9 |-> 0],
      etfForeignFlowNetAssetTotalAmount                              |-> [i \in 1 .. 15 |-> 0],
      etfForeignNetAssetTotal                                        |-> [i \in 1 .. 15 |-> 0],
      etfForeignFinalNetAssetValue                                   |-> [i \in 1 .. 9 |-> 0],
      etfCuQuantity                                                  |-> [i \in 1 .. 8 |-> 0],
      previousDaysTaxBaseNav                                         |-> [i \in 1 .. 9 |-> 0],
      previousDaysTaxBaseNavBeforeDividend                           |-> [i \in 1 .. 9 |-> 0],
      previousDaysCashDividendAmount                                 |-> [i \in 1 .. 12 |-> 0],
      taxBaseNavAsOfTheDayBeforeThePreviousDay                       |-> [i \in 1 .. 9 |-> 0],
      previousDaysNonTaxableBasePriceForOverseasStocks               |-> [i \in 1 .. 9 |-> 0],
      previousDaysNonTaxableBasePriceBeforeDividendForOverseasStocks |-> [i \in 1 .. 9 |-> 0],
      dayBeforePreviousDaysNonTaxableBasePriceForOverseasStocks      |-> [i \in 1 .. 9 |-> 0],
      numberOfFreeFloatingEtfShares                                  |-> [i \in 1 .. 16 |-> 0],
      filler46                                                       |-> [i \in 1 .. 46 |-> 0],
      endKeyword                                                     |-> [i \in 1 .. 1 |-> 0] ]

(* Etp Transfer Agent Batch Message at zero, then each field in turn at the values it is checked at *)
CheckedEtpTransferAgentBatchMessage ==
    { ZeroEtpTransferAgentBatchMessage }
        \cup { [ZeroEtpTransferAgentBatchMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroEtpTransferAgentBatchMessage EXCEPT !.dataSeqNumber = one] : one \in Sample(8) }
        \cup { [ZeroEtpTransferAgentBatchMessage EXCEPT !.filler10 = one] : one \in Sample(10) }
        \cup { [ZeroEtpTransferAgentBatchMessage EXCEPT !.etfFlowNetAssetTotalAmount = one] : one \in Sample(15) }
        \cup { [ZeroEtpTransferAgentBatchMessage EXCEPT !.etfForeignNetAssetValueAmount = one] : one \in Sample(15) }
        \cup { [ZeroEtpTransferAgentBatchMessage EXCEPT !.etfNetAssetValueAmount = one] : one \in Sample(9) }
        \cup { [ZeroEtpTransferAgentBatchMessage EXCEPT !.etfForeignFlowNetAssetTotalAmount = one] : one \in Sample(15) }
        \cup { [ZeroEtpTransferAgentBatchMessage EXCEPT !.etfForeignNetAssetTotal = one] : one \in Sample(15) }
        \cup { [ZeroEtpTransferAgentBatchMessage EXCEPT !.etfForeignFinalNetAssetValue = one] : one \in Sample(9) }
        \cup { [ZeroEtpTransferAgentBatchMessage EXCEPT !.etfCuQuantity = one] : one \in Sample(8) }
        \cup { [ZeroEtpTransferAgentBatchMessage EXCEPT !.previousDaysTaxBaseNav = one] : one \in Sample(9) }
        \cup { [ZeroEtpTransferAgentBatchMessage EXCEPT !.previousDaysTaxBaseNavBeforeDividend = one] : one \in Sample(9) }
        \cup { [ZeroEtpTransferAgentBatchMessage EXCEPT !.previousDaysCashDividendAmount = one] : one \in Sample(12) }
        \cup { [ZeroEtpTransferAgentBatchMessage EXCEPT !.taxBaseNavAsOfTheDayBeforeThePreviousDay = one] : one \in Sample(9) }
        \cup { [ZeroEtpTransferAgentBatchMessage EXCEPT !.previousDaysNonTaxableBasePriceForOverseasStocks = one] : one \in Sample(9) }
        \cup { [ZeroEtpTransferAgentBatchMessage EXCEPT !.previousDaysNonTaxableBasePriceBeforeDividendForOverseasStocks = one] : one \in Sample(9) }
        \cup { [ZeroEtpTransferAgentBatchMessage EXCEPT !.dayBeforePreviousDaysNonTaxableBasePriceForOverseasStocks = one] : one \in Sample(9) }
        \cup { [ZeroEtpTransferAgentBatchMessage EXCEPT !.numberOfFreeFloatingEtfShares = one] : one \in Sample(16) }
        \cup { [ZeroEtpTransferAgentBatchMessage EXCEPT !.filler46 = one] : one \in Sample(46) }
        \cup { [ZeroEtpTransferAgentBatchMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Etf Risk Appraisement Message: 195 bytes                                *)
(***************************************************************************)

EtfRiskAppraisementMessage ==
    [ isin                                        : Sample(12),
      dataSeqNumber                               : Sample(8),
      date                                        : Sample(8),
      officeConsignmentCompanysRegistrationNumber : Sample(3),
      nameOfCounterparty                          : Sample(50),
      otcDerivativesType                          : Sample(1),
      netAssetsAmount                             : Sample(15),
      totalDangerExposureAmount                   : Sample(15),
      securityAppraisalAmount                     : Sample(15),
      securityRate                                : Sample(7),
      riskAppraisalAmount                         : Sample(15),
      riskAppraisalAmountRate                     : Sample(7),
      filler38                                    : Sample(38),
      endKeyword                                  : Sample(1) ]

EncodeEtfRiskAppraisementMessage(message) ==
    message.isin
        \o message.dataSeqNumber
        \o message.date
        \o message.officeConsignmentCompanysRegistrationNumber
        \o message.nameOfCounterparty
        \o message.otcDerivativesType
        \o message.netAssetsAmount
        \o message.totalDangerExposureAmount
        \o message.securityAppraisalAmount
        \o message.securityRate
        \o message.riskAppraisalAmount
        \o message.riskAppraisalAmountRate
        \o message.filler38
        \o message.endKeyword

DecodeEtfRiskAppraisementMessage(bytes) ==
    LET isin == ReadBytes(bytes, 12) IN IF ~isin.ok THEN Fail ELSE
    LET dataSeqNumber == ReadBytes(isin.rest, 8) IN IF ~dataSeqNumber.ok THEN Fail ELSE
    LET date == ReadBytes(dataSeqNumber.rest, 8) IN IF ~date.ok THEN Fail ELSE
    LET officeConsignmentCompanysRegistrationNumber == ReadBytes(date.rest, 3) IN IF ~officeConsignmentCompanysRegistrationNumber.ok THEN Fail ELSE
    LET nameOfCounterparty == ReadBytes(officeConsignmentCompanysRegistrationNumber.rest, 50) IN IF ~nameOfCounterparty.ok THEN Fail ELSE
    LET otcDerivativesType == ReadBytes(nameOfCounterparty.rest, 1) IN IF ~otcDerivativesType.ok THEN Fail ELSE
    LET netAssetsAmount == ReadBytes(otcDerivativesType.rest, 15) IN IF ~netAssetsAmount.ok THEN Fail ELSE
    LET totalDangerExposureAmount == ReadBytes(netAssetsAmount.rest, 15) IN IF ~totalDangerExposureAmount.ok THEN Fail ELSE
    LET securityAppraisalAmount == ReadBytes(totalDangerExposureAmount.rest, 15) IN IF ~securityAppraisalAmount.ok THEN Fail ELSE
    LET securityRate == ReadBytes(securityAppraisalAmount.rest, 7) IN IF ~securityRate.ok THEN Fail ELSE
    LET riskAppraisalAmount == ReadBytes(securityRate.rest, 15) IN IF ~riskAppraisalAmount.ok THEN Fail ELSE
    LET riskAppraisalAmountRate == ReadBytes(riskAppraisalAmount.rest, 7) IN IF ~riskAppraisalAmountRate.ok THEN Fail ELSE
    LET filler38 == ReadBytes(riskAppraisalAmountRate.rest, 38) IN IF ~filler38.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler38.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ isin                                        |-> isin.value,
         dataSeqNumber                               |-> dataSeqNumber.value,
         date                                        |-> date.value,
         officeConsignmentCompanysRegistrationNumber |-> officeConsignmentCompanysRegistrationNumber.value,
         nameOfCounterparty                          |-> nameOfCounterparty.value,
         otcDerivativesType                          |-> otcDerivativesType.value,
         netAssetsAmount                             |-> netAssetsAmount.value,
         totalDangerExposureAmount                   |-> totalDangerExposureAmount.value,
         securityAppraisalAmount                     |-> securityAppraisalAmount.value,
         securityRate                                |-> securityRate.value,
         riskAppraisalAmount                         |-> riskAppraisalAmount.value,
         riskAppraisalAmountRate                     |-> riskAppraisalAmountRate.value,
         filler38                                    |-> filler38.value,
         endKeyword                                  |-> endKeyword.value ], endKeyword.rest)

ZeroEtfRiskAppraisementMessage ==
    [ isin                                        |-> [i \in 1 .. 12 |-> 0],
      dataSeqNumber                               |-> [i \in 1 .. 8 |-> 0],
      date                                        |-> [i \in 1 .. 8 |-> 0],
      officeConsignmentCompanysRegistrationNumber |-> [i \in 1 .. 3 |-> 0],
      nameOfCounterparty                          |-> [i \in 1 .. 50 |-> 0],
      otcDerivativesType                          |-> [i \in 1 .. 1 |-> 0],
      netAssetsAmount                             |-> [i \in 1 .. 15 |-> 0],
      totalDangerExposureAmount                   |-> [i \in 1 .. 15 |-> 0],
      securityAppraisalAmount                     |-> [i \in 1 .. 15 |-> 0],
      securityRate                                |-> [i \in 1 .. 7 |-> 0],
      riskAppraisalAmount                         |-> [i \in 1 .. 15 |-> 0],
      riskAppraisalAmountRate                     |-> [i \in 1 .. 7 |-> 0],
      filler38                                    |-> [i \in 1 .. 38 |-> 0],
      endKeyword                                  |-> [i \in 1 .. 1 |-> 0] ]

(* Etf Risk Appraisement Message at zero, then each field in turn at the values it is checked at *)
CheckedEtfRiskAppraisementMessage ==
    { ZeroEtfRiskAppraisementMessage }
        \cup { [ZeroEtfRiskAppraisementMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroEtfRiskAppraisementMessage EXCEPT !.dataSeqNumber = one] : one \in Sample(8) }
        \cup { [ZeroEtfRiskAppraisementMessage EXCEPT !.date = one] : one \in Sample(8) }
        \cup { [ZeroEtfRiskAppraisementMessage EXCEPT !.officeConsignmentCompanysRegistrationNumber = one] : one \in Sample(3) }
        \cup { [ZeroEtfRiskAppraisementMessage EXCEPT !.nameOfCounterparty = one] : one \in Sample(50) }
        \cup { [ZeroEtfRiskAppraisementMessage EXCEPT !.otcDerivativesType = one] : one \in Sample(1) }
        \cup { [ZeroEtfRiskAppraisementMessage EXCEPT !.netAssetsAmount = one] : one \in Sample(15) }
        \cup { [ZeroEtfRiskAppraisementMessage EXCEPT !.totalDangerExposureAmount = one] : one \in Sample(15) }
        \cup { [ZeroEtfRiskAppraisementMessage EXCEPT !.securityAppraisalAmount = one] : one \in Sample(15) }
        \cup { [ZeroEtfRiskAppraisementMessage EXCEPT !.securityRate = one] : one \in Sample(7) }
        \cup { [ZeroEtfRiskAppraisementMessage EXCEPT !.riskAppraisalAmount = one] : one \in Sample(15) }
        \cup { [ZeroEtfRiskAppraisementMessage EXCEPT !.riskAppraisalAmountRate = one] : one \in Sample(7) }
        \cup { [ZeroEtfRiskAppraisementMessage EXCEPT !.filler38 = one] : one \in Sample(38) }
        \cup { [ZeroEtfRiskAppraisementMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Synthetic Etf Constituents Message: 195 bytes                           *)
(***************************************************************************)

SyntheticEtfConstituentsMessage ==
    [ isin                                        : Sample(12),
      dataSeqNumber                               : Sample(8),
      date                                        : Sample(8),
      officeConsignmentCompanysRegistrationNumber : Sample(3),
      compositionConstituentsNumber               : Sample(4),
      compositionConstituentsCode                 : Sample(12),
      compositionConstituentsName                 : Sample(80),
      compositionRatio                            : Sample(7),
      filler60                                    : Sample(60),
      endKeyword                                  : Sample(1) ]

EncodeSyntheticEtfConstituentsMessage(message) ==
    message.isin
        \o message.dataSeqNumber
        \o message.date
        \o message.officeConsignmentCompanysRegistrationNumber
        \o message.compositionConstituentsNumber
        \o message.compositionConstituentsCode
        \o message.compositionConstituentsName
        \o message.compositionRatio
        \o message.filler60
        \o message.endKeyword

DecodeSyntheticEtfConstituentsMessage(bytes) ==
    LET isin == ReadBytes(bytes, 12) IN IF ~isin.ok THEN Fail ELSE
    LET dataSeqNumber == ReadBytes(isin.rest, 8) IN IF ~dataSeqNumber.ok THEN Fail ELSE
    LET date == ReadBytes(dataSeqNumber.rest, 8) IN IF ~date.ok THEN Fail ELSE
    LET officeConsignmentCompanysRegistrationNumber == ReadBytes(date.rest, 3) IN IF ~officeConsignmentCompanysRegistrationNumber.ok THEN Fail ELSE
    LET compositionConstituentsNumber == ReadBytes(officeConsignmentCompanysRegistrationNumber.rest, 4) IN IF ~compositionConstituentsNumber.ok THEN Fail ELSE
    LET compositionConstituentsCode == ReadBytes(compositionConstituentsNumber.rest, 12) IN IF ~compositionConstituentsCode.ok THEN Fail ELSE
    LET compositionConstituentsName == ReadBytes(compositionConstituentsCode.rest, 80) IN IF ~compositionConstituentsName.ok THEN Fail ELSE
    LET compositionRatio == ReadBytes(compositionConstituentsName.rest, 7) IN IF ~compositionRatio.ok THEN Fail ELSE
    LET filler60 == ReadBytes(compositionRatio.rest, 60) IN IF ~filler60.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler60.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ isin                                        |-> isin.value,
         dataSeqNumber                               |-> dataSeqNumber.value,
         date                                        |-> date.value,
         officeConsignmentCompanysRegistrationNumber |-> officeConsignmentCompanysRegistrationNumber.value,
         compositionConstituentsNumber               |-> compositionConstituentsNumber.value,
         compositionConstituentsCode                 |-> compositionConstituentsCode.value,
         compositionConstituentsName                 |-> compositionConstituentsName.value,
         compositionRatio                            |-> compositionRatio.value,
         filler60                                    |-> filler60.value,
         endKeyword                                  |-> endKeyword.value ], endKeyword.rest)

ZeroSyntheticEtfConstituentsMessage ==
    [ isin                                        |-> [i \in 1 .. 12 |-> 0],
      dataSeqNumber                               |-> [i \in 1 .. 8 |-> 0],
      date                                        |-> [i \in 1 .. 8 |-> 0],
      officeConsignmentCompanysRegistrationNumber |-> [i \in 1 .. 3 |-> 0],
      compositionConstituentsNumber               |-> [i \in 1 .. 4 |-> 0],
      compositionConstituentsCode                 |-> [i \in 1 .. 12 |-> 0],
      compositionConstituentsName                 |-> [i \in 1 .. 80 |-> 0],
      compositionRatio                            |-> [i \in 1 .. 7 |-> 0],
      filler60                                    |-> [i \in 1 .. 60 |-> 0],
      endKeyword                                  |-> [i \in 1 .. 1 |-> 0] ]

(* Synthetic Etf Constituents Message at zero, then each field in turn at the values it is checked at *)
CheckedSyntheticEtfConstituentsMessage ==
    { ZeroSyntheticEtfConstituentsMessage }
        \cup { [ZeroSyntheticEtfConstituentsMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroSyntheticEtfConstituentsMessage EXCEPT !.dataSeqNumber = one] : one \in Sample(8) }
        \cup { [ZeroSyntheticEtfConstituentsMessage EXCEPT !.date = one] : one \in Sample(8) }
        \cup { [ZeroSyntheticEtfConstituentsMessage EXCEPT !.officeConsignmentCompanysRegistrationNumber = one] : one \in Sample(3) }
        \cup { [ZeroSyntheticEtfConstituentsMessage EXCEPT !.compositionConstituentsNumber = one] : one \in Sample(4) }
        \cup { [ZeroSyntheticEtfConstituentsMessage EXCEPT !.compositionConstituentsCode = one] : one \in Sample(12) }
        \cup { [ZeroSyntheticEtfConstituentsMessage EXCEPT !.compositionConstituentsName = one] : one \in Sample(80) }
        \cup { [ZeroSyntheticEtfConstituentsMessage EXCEPT !.compositionRatio = one] : one \in Sample(7) }
        \cup { [ZeroSyntheticEtfConstituentsMessage EXCEPT !.filler60 = one] : one \in Sample(60) }
        \cup { [ZeroSyntheticEtfConstituentsMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Elw Investment Indicator Sensitivity Message: 105 bytes                 *)
(***************************************************************************)

ElwInvestmentIndicatorSensitivityMessage ==
    [ isin                    : Sample(12),
      time                    : Sample(6),
      theoreticalWarrantPrice : Sample(10),
      sensitivityDeltaSign    : Sample(1),
      sensitivityDelta        : Sample(7),
      sensitivityGammaSign    : Sample(1),
      sensitivityGamma        : Sample(7),
      sensitivityThetaSign    : Sample(1),
      sensitivityTheta        : Sample(12),
      sensitivityVegaSign     : Sample(1),
      sensitivityVega         : Sample(12),
      sensitivityRhoSign      : Sample(1),
      sensitivityRho          : Sample(12),
      intrinsicVolatility     : Sample(5),
      prerequisiteCost        : Sample(10),
      filler6                 : Sample(6),
      endKeyword              : Sample(1) ]

EncodeElwInvestmentIndicatorSensitivityMessage(message) ==
    message.isin
        \o message.time
        \o message.theoreticalWarrantPrice
        \o message.sensitivityDeltaSign
        \o message.sensitivityDelta
        \o message.sensitivityGammaSign
        \o message.sensitivityGamma
        \o message.sensitivityThetaSign
        \o message.sensitivityTheta
        \o message.sensitivityVegaSign
        \o message.sensitivityVega
        \o message.sensitivityRhoSign
        \o message.sensitivityRho
        \o message.intrinsicVolatility
        \o message.prerequisiteCost
        \o message.filler6
        \o message.endKeyword

DecodeElwInvestmentIndicatorSensitivityMessage(bytes) ==
    LET isin == ReadBytes(bytes, 12) IN IF ~isin.ok THEN Fail ELSE
    LET time == ReadBytes(isin.rest, 6) IN IF ~time.ok THEN Fail ELSE
    LET theoreticalWarrantPrice == ReadBytes(time.rest, 10) IN IF ~theoreticalWarrantPrice.ok THEN Fail ELSE
    LET sensitivityDeltaSign == ReadBytes(theoreticalWarrantPrice.rest, 1) IN IF ~sensitivityDeltaSign.ok THEN Fail ELSE
    LET sensitivityDelta == ReadBytes(sensitivityDeltaSign.rest, 7) IN IF ~sensitivityDelta.ok THEN Fail ELSE
    LET sensitivityGammaSign == ReadBytes(sensitivityDelta.rest, 1) IN IF ~sensitivityGammaSign.ok THEN Fail ELSE
    LET sensitivityGamma == ReadBytes(sensitivityGammaSign.rest, 7) IN IF ~sensitivityGamma.ok THEN Fail ELSE
    LET sensitivityThetaSign == ReadBytes(sensitivityGamma.rest, 1) IN IF ~sensitivityThetaSign.ok THEN Fail ELSE
    LET sensitivityTheta == ReadBytes(sensitivityThetaSign.rest, 12) IN IF ~sensitivityTheta.ok THEN Fail ELSE
    LET sensitivityVegaSign == ReadBytes(sensitivityTheta.rest, 1) IN IF ~sensitivityVegaSign.ok THEN Fail ELSE
    LET sensitivityVega == ReadBytes(sensitivityVegaSign.rest, 12) IN IF ~sensitivityVega.ok THEN Fail ELSE
    LET sensitivityRhoSign == ReadBytes(sensitivityVega.rest, 1) IN IF ~sensitivityRhoSign.ok THEN Fail ELSE
    LET sensitivityRho == ReadBytes(sensitivityRhoSign.rest, 12) IN IF ~sensitivityRho.ok THEN Fail ELSE
    LET intrinsicVolatility == ReadBytes(sensitivityRho.rest, 5) IN IF ~intrinsicVolatility.ok THEN Fail ELSE
    LET prerequisiteCost == ReadBytes(intrinsicVolatility.rest, 10) IN IF ~prerequisiteCost.ok THEN Fail ELSE
    LET filler6 == ReadBytes(prerequisiteCost.rest, 6) IN IF ~filler6.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler6.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ isin                    |-> isin.value,
         time                    |-> time.value,
         theoreticalWarrantPrice |-> theoreticalWarrantPrice.value,
         sensitivityDeltaSign    |-> sensitivityDeltaSign.value,
         sensitivityDelta        |-> sensitivityDelta.value,
         sensitivityGammaSign    |-> sensitivityGammaSign.value,
         sensitivityGamma        |-> sensitivityGamma.value,
         sensitivityThetaSign    |-> sensitivityThetaSign.value,
         sensitivityTheta        |-> sensitivityTheta.value,
         sensitivityVegaSign     |-> sensitivityVegaSign.value,
         sensitivityVega         |-> sensitivityVega.value,
         sensitivityRhoSign      |-> sensitivityRhoSign.value,
         sensitivityRho          |-> sensitivityRho.value,
         intrinsicVolatility     |-> intrinsicVolatility.value,
         prerequisiteCost        |-> prerequisiteCost.value,
         filler6                 |-> filler6.value,
         endKeyword              |-> endKeyword.value ], endKeyword.rest)

ZeroElwInvestmentIndicatorSensitivityMessage ==
    [ isin                    |-> [i \in 1 .. 12 |-> 0],
      time                    |-> [i \in 1 .. 6 |-> 0],
      theoreticalWarrantPrice |-> [i \in 1 .. 10 |-> 0],
      sensitivityDeltaSign    |-> [i \in 1 .. 1 |-> 0],
      sensitivityDelta        |-> [i \in 1 .. 7 |-> 0],
      sensitivityGammaSign    |-> [i \in 1 .. 1 |-> 0],
      sensitivityGamma        |-> [i \in 1 .. 7 |-> 0],
      sensitivityThetaSign    |-> [i \in 1 .. 1 |-> 0],
      sensitivityTheta        |-> [i \in 1 .. 12 |-> 0],
      sensitivityVegaSign     |-> [i \in 1 .. 1 |-> 0],
      sensitivityVega         |-> [i \in 1 .. 12 |-> 0],
      sensitivityRhoSign      |-> [i \in 1 .. 1 |-> 0],
      sensitivityRho          |-> [i \in 1 .. 12 |-> 0],
      intrinsicVolatility     |-> [i \in 1 .. 5 |-> 0],
      prerequisiteCost        |-> [i \in 1 .. 10 |-> 0],
      filler6                 |-> [i \in 1 .. 6 |-> 0],
      endKeyword              |-> [i \in 1 .. 1 |-> 0] ]

(* Elw Investment Indicator Sensitivity Message at zero, then each field in turn at the values it is checked at *)
CheckedElwInvestmentIndicatorSensitivityMessage ==
    { ZeroElwInvestmentIndicatorSensitivityMessage }
        \cup { [ZeroElwInvestmentIndicatorSensitivityMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroElwInvestmentIndicatorSensitivityMessage EXCEPT !.time = one] : one \in Sample(6) }
        \cup { [ZeroElwInvestmentIndicatorSensitivityMessage EXCEPT !.theoreticalWarrantPrice = one] : one \in Sample(10) }
        \cup { [ZeroElwInvestmentIndicatorSensitivityMessage EXCEPT !.sensitivityDeltaSign = one] : one \in Sample(1) }
        \cup { [ZeroElwInvestmentIndicatorSensitivityMessage EXCEPT !.sensitivityDelta = one] : one \in Sample(7) }
        \cup { [ZeroElwInvestmentIndicatorSensitivityMessage EXCEPT !.sensitivityGammaSign = one] : one \in Sample(1) }
        \cup { [ZeroElwInvestmentIndicatorSensitivityMessage EXCEPT !.sensitivityGamma = one] : one \in Sample(7) }
        \cup { [ZeroElwInvestmentIndicatorSensitivityMessage EXCEPT !.sensitivityThetaSign = one] : one \in Sample(1) }
        \cup { [ZeroElwInvestmentIndicatorSensitivityMessage EXCEPT !.sensitivityTheta = one] : one \in Sample(12) }
        \cup { [ZeroElwInvestmentIndicatorSensitivityMessage EXCEPT !.sensitivityVegaSign = one] : one \in Sample(1) }
        \cup { [ZeroElwInvestmentIndicatorSensitivityMessage EXCEPT !.sensitivityVega = one] : one \in Sample(12) }
        \cup { [ZeroElwInvestmentIndicatorSensitivityMessage EXCEPT !.sensitivityRhoSign = one] : one \in Sample(1) }
        \cup { [ZeroElwInvestmentIndicatorSensitivityMessage EXCEPT !.sensitivityRho = one] : one \in Sample(12) }
        \cup { [ZeroElwInvestmentIndicatorSensitivityMessage EXCEPT !.intrinsicVolatility = one] : one \in Sample(5) }
        \cup { [ZeroElwInvestmentIndicatorSensitivityMessage EXCEPT !.prerequisiteCost = one] : one \in Sample(10) }
        \cup { [ZeroElwInvestmentIndicatorSensitivityMessage EXCEPT !.filler6 = one] : one \in Sample(6) }
        \cup { [ZeroElwInvestmentIndicatorSensitivityMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Etn Iiv Message: 65 bytes                                               *)
(***************************************************************************)

EtnIivMessage ==
    [ isin                     : Sample(12),
      hours                    : Sample(6),
      previousDaysIv           : Sample(9),
      duringMarketHoursFinalIv : Sample(9),
      filler28                 : Sample(28),
      endKeyword               : Sample(1) ]

EncodeEtnIivMessage(message) ==
    message.isin
        \o message.hours
        \o message.previousDaysIv
        \o message.duringMarketHoursFinalIv
        \o message.filler28
        \o message.endKeyword

DecodeEtnIivMessage(bytes) ==
    LET isin == ReadBytes(bytes, 12) IN IF ~isin.ok THEN Fail ELSE
    LET hours == ReadBytes(isin.rest, 6) IN IF ~hours.ok THEN Fail ELSE
    LET previousDaysIv == ReadBytes(hours.rest, 9) IN IF ~previousDaysIv.ok THEN Fail ELSE
    LET duringMarketHoursFinalIv == ReadBytes(previousDaysIv.rest, 9) IN IF ~duringMarketHoursFinalIv.ok THEN Fail ELSE
    LET filler28 == ReadBytes(duringMarketHoursFinalIv.rest, 28) IN IF ~filler28.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler28.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ isin                     |-> isin.value,
         hours                    |-> hours.value,
         previousDaysIv           |-> previousDaysIv.value,
         duringMarketHoursFinalIv |-> duringMarketHoursFinalIv.value,
         filler28                 |-> filler28.value,
         endKeyword               |-> endKeyword.value ], endKeyword.rest)

ZeroEtnIivMessage ==
    [ isin                     |-> [i \in 1 .. 12 |-> 0],
      hours                    |-> [i \in 1 .. 6 |-> 0],
      previousDaysIv           |-> [i \in 1 .. 9 |-> 0],
      duringMarketHoursFinalIv |-> [i \in 1 .. 9 |-> 0],
      filler28                 |-> [i \in 1 .. 28 |-> 0],
      endKeyword               |-> [i \in 1 .. 1 |-> 0] ]

(* Etn Iiv Message at zero, then each field in turn at the values it is checked at *)
CheckedEtnIivMessage ==
    { ZeroEtnIivMessage }
        \cup { [ZeroEtnIivMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroEtnIivMessage EXCEPT !.hours = one] : one \in Sample(6) }
        \cup { [ZeroEtnIivMessage EXCEPT !.previousDaysIv = one] : one \in Sample(9) }
        \cup { [ZeroEtnIivMessage EXCEPT !.duringMarketHoursFinalIv = one] : one \in Sample(9) }
        \cup { [ZeroEtnIivMessage EXCEPT !.filler28 = one] : one \in Sample(28) }
        \cup { [ZeroEtnIivMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Etn Disparate Ratio Message: 95 bytes                                   *)
(***************************************************************************)

EtnDisparateRatioMessage ==
    [ isin               : Sample(12),
      seqNumber          : Sample(8),
      date               : Sample(8),
      disparateRatioSign : Sample(1),
      disparateRatio     : Sample(9),
      filler56           : Sample(56),
      endKeyword         : Sample(1) ]

EncodeEtnDisparateRatioMessage(message) ==
    message.isin
        \o message.seqNumber
        \o message.date
        \o message.disparateRatioSign
        \o message.disparateRatio
        \o message.filler56
        \o message.endKeyword

DecodeEtnDisparateRatioMessage(bytes) ==
    LET isin == ReadBytes(bytes, 12) IN IF ~isin.ok THEN Fail ELSE
    LET seqNumber == ReadBytes(isin.rest, 8) IN IF ~seqNumber.ok THEN Fail ELSE
    LET date == ReadBytes(seqNumber.rest, 8) IN IF ~date.ok THEN Fail ELSE
    LET disparateRatioSign == ReadBytes(date.rest, 1) IN IF ~disparateRatioSign.ok THEN Fail ELSE
    LET disparateRatio == ReadBytes(disparateRatioSign.rest, 9) IN IF ~disparateRatio.ok THEN Fail ELSE
    LET filler56 == ReadBytes(disparateRatio.rest, 56) IN IF ~filler56.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler56.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ isin               |-> isin.value,
         seqNumber          |-> seqNumber.value,
         date               |-> date.value,
         disparateRatioSign |-> disparateRatioSign.value,
         disparateRatio     |-> disparateRatio.value,
         filler56           |-> filler56.value,
         endKeyword         |-> endKeyword.value ], endKeyword.rest)

ZeroEtnDisparateRatioMessage ==
    [ isin               |-> [i \in 1 .. 12 |-> 0],
      seqNumber          |-> [i \in 1 .. 8 |-> 0],
      date               |-> [i \in 1 .. 8 |-> 0],
      disparateRatioSign |-> [i \in 1 .. 1 |-> 0],
      disparateRatio     |-> [i \in 1 .. 9 |-> 0],
      filler56           |-> [i \in 1 .. 56 |-> 0],
      endKeyword         |-> [i \in 1 .. 1 |-> 0] ]

(* Etn Disparate Ratio Message at zero, then each field in turn at the values it is checked at *)
CheckedEtnDisparateRatioMessage ==
    { ZeroEtnDisparateRatioMessage }
        \cup { [ZeroEtnDisparateRatioMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroEtnDisparateRatioMessage EXCEPT !.seqNumber = one] : one \in Sample(8) }
        \cup { [ZeroEtnDisparateRatioMessage EXCEPT !.date = one] : one \in Sample(8) }
        \cup { [ZeroEtnDisparateRatioMessage EXCEPT !.disparateRatioSign = one] : one \in Sample(1) }
        \cup { [ZeroEtnDisparateRatioMessage EXCEPT !.disparateRatio = one] : one \in Sample(9) }
        \cup { [ZeroEtnDisparateRatioMessage EXCEPT !.filler56 = one] : one \in Sample(56) }
        \cup { [ZeroEtnDisparateRatioMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Loan Transaction Available Quantity Message: 45 bytes                   *)
(***************************************************************************)

LoanTransactionAvailableQuantityMessage ==
    [ issueCode                : Sample(12),
      businessCode             : Sample(3),
      availableLendingQuantity : Sample(10),
      filler19                 : Sample(19),
      endKeyword               : Sample(1) ]

EncodeLoanTransactionAvailableQuantityMessage(message) ==
    message.issueCode
        \o message.businessCode
        \o message.availableLendingQuantity
        \o message.filler19
        \o message.endKeyword

DecodeLoanTransactionAvailableQuantityMessage(bytes) ==
    LET issueCode == ReadBytes(bytes, 12) IN IF ~issueCode.ok THEN Fail ELSE
    LET businessCode == ReadBytes(issueCode.rest, 3) IN IF ~businessCode.ok THEN Fail ELSE
    LET availableLendingQuantity == ReadBytes(businessCode.rest, 10) IN IF ~availableLendingQuantity.ok THEN Fail ELSE
    LET filler19 == ReadBytes(availableLendingQuantity.rest, 19) IN IF ~filler19.ok THEN Fail ELSE
    LET endKeyword == ReadBytes(filler19.rest, 1) IN IF ~endKeyword.ok THEN Fail ELSE
    Ok([ issueCode                |-> issueCode.value,
         businessCode             |-> businessCode.value,
         availableLendingQuantity |-> availableLendingQuantity.value,
         filler19                 |-> filler19.value,
         endKeyword               |-> endKeyword.value ], endKeyword.rest)

ZeroLoanTransactionAvailableQuantityMessage ==
    [ issueCode                |-> [i \in 1 .. 12 |-> 0],
      businessCode             |-> [i \in 1 .. 3 |-> 0],
      availableLendingQuantity |-> [i \in 1 .. 10 |-> 0],
      filler19                 |-> [i \in 1 .. 19 |-> 0],
      endKeyword               |-> [i \in 1 .. 1 |-> 0] ]

(* Loan Transaction Available Quantity Message at zero, then each field in turn at the values it is checked at *)
CheckedLoanTransactionAvailableQuantityMessage ==
    { ZeroLoanTransactionAvailableQuantityMessage }
        \cup { [ZeroLoanTransactionAvailableQuantityMessage EXCEPT !.issueCode = one] : one \in Sample(12) }
        \cup { [ZeroLoanTransactionAvailableQuantityMessage EXCEPT !.businessCode = one] : one \in Sample(3) }
        \cup { [ZeroLoanTransactionAvailableQuantityMessage EXCEPT !.availableLendingQuantity = one] : one \in Sample(10) }
        \cup { [ZeroLoanTransactionAvailableQuantityMessage EXCEPT !.filler19 = one] : one \in Sample(19) }
        \cup { [ZeroLoanTransactionAvailableQuantityMessage EXCEPT !.endKeyword = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by Tr Code                                            *)
(***************************************************************************)

KOtcIssueClosingMessageCode == <<65, 54, 48, 49, 51>>  \* "A6013"
KOtcMarketOperationMessageCode == <<65, 55, 48, 49, 51>>  \* "A7013"
KOtcMarketActionMessageCode == <<71, 53, 48, 49, 51>>  \* "G5013"
KOtcQuoteMessageCode == <<65, 50, 48, 49, 51>>  \* "A2013"
KOtcOrderFilledMessageCode == <<65, 51, 48, 49, 51>>  \* "A3013"
OtcBondTradedInfoMessageCode == <<74, 54, 48, 55, 55>>  \* "J6077"
OtcBondTradesPerInstitutionMessageCode == <<74, 55, 48, 55, 55>>  \* "J7077"
OtcBondTypesPerInvestorMessageCode == <<67, 49, 48, 55, 55>>  \* "C1077"
KBondMessageCode == <<76, 57, 48, 55, 55>>  \* "L9077"
MkfIndexMessageCode == <<69, 50, 48, 48, 48>>  \* "E2000"
MkfIndexJpyMessageCode == <<79, 57, 48, 48, 48>>  \* "O9000"
WisefnIndexMessageCode == <<80, 51, 48, 48, 48>>  \* "P3000"
KisIndexMessageCode == <<66, 80, 48, 48, 48>>  \* "BP000"
MkfBondIndexMessageCode == <<75, 48, 48, 48, 48>>  \* "K0000"
KisBondIndexMessageCode == <<76, 54, 48, 48, 48>>  \* "L6000"
KebiBondIndexMessageCode == <<75, 54, 48, 48, 48>>  \* "K6000"
KabiBondIndexMessageCode == <<81, 54, 48, 48, 48>>  \* "Q6000"
NicepniBondIndexMessageCode == <<67, 69, 48, 48, 48>>  \* "CE000"
DomesticEtfInavMessageCode == <<66, 86, 48, 51, 83>>  \* "BV03S"
DomesticEtfEstimatedInavMessageCode == <<66, 87, 48, 51, 83>>  \* "BW03S"
GlobalEtfInavMessageCode == <<76, 53, 48, 51, 83>>  \* "L503S"
EtfTrackingErrorMessageCode == <<80, 54, 48, 51, 83>>  \* "P603S"
GlobalEtfTrackingErrorMessageCode == <<80, 55, 48, 51, 83>>  \* "P703S"
EtpPdfMessageCode == <<70, 56, 48, 51, 83>>  \* "F803S"
EtpOperatorInformationMessageCode == <<77, 56, 48, 51, 83>>  \* "M803S"
EtpOperatorInformationMessageCode2 == <<77, 56, 48, 53, 83>>  \* "M805S"
EtpOperatorInformationMessageCode3 == <<77, 56, 48, 49, 81>>  \* "M801Q"
EtpTransferAgentBatchMessageCode == <<78, 56, 48, 51, 83>>  \* "N803S"
EtpTransferAgentBatchMessageCode2 == <<78, 56, 48, 53, 83>>  \* "N805S"
EtpTransferAgentBatchMessageCode3 == <<78, 56, 48, 49, 81>>  \* "N801Q"
EtfRiskAppraisementMessageCode == <<81, 52, 48, 51, 83>>  \* "Q403S"
SyntheticEtfConstituentsMessageCode == <<81, 53, 48, 51, 83>>  \* "Q503S"
ElwInvestmentIndicatorSensitivityMessageCode == <<67, 55, 48, 50, 83>>  \* "C702S"
EtnIivMessageCode == <<83, 51, 48, 52, 83>>  \* "S304S"
EtnDisparateRatioMessageCode == <<88, 52, 48, 52, 83>>  \* "X404S"
LoanTransactionAvailableQuantityMessageCode == <<67, 67, 48, 48, 48>>  \* "CC000"

Payload ==
    [ tag : {KOtcIssueClosingMessageCode}, body : KOtcIssueClosingMessage ]
        \cup [ tag : {KOtcMarketOperationMessageCode}, body : KOtcMarketOperationMessage ]
        \cup [ tag : {KOtcMarketActionMessageCode}, body : KOtcMarketActionMessage ]
        \cup [ tag : {KOtcQuoteMessageCode}, body : KOtcQuoteMessage ]
        \cup [ tag : {KOtcOrderFilledMessageCode}, body : KOtcOrderFilledMessage ]
        \cup [ tag : {OtcBondTradedInfoMessageCode}, body : OtcBondTradedInfoMessage ]
        \cup [ tag : {OtcBondTradesPerInstitutionMessageCode}, body : OtcBondTradesPerInstitutionMessage ]
        \cup [ tag : {OtcBondTypesPerInvestorMessageCode}, body : OtcBondTypesPerInvestorMessage ]
        \cup [ tag : {KBondMessageCode}, body : KBondMessage ]
        \cup [ tag : {MkfIndexMessageCode}, body : MkfIndexMessage ]
        \cup [ tag : {MkfIndexJpyMessageCode}, body : MkfIndexJpyMessage ]
        \cup [ tag : {WisefnIndexMessageCode}, body : WisefnIndexMessage ]
        \cup [ tag : {KisIndexMessageCode}, body : KisIndexMessage ]
        \cup [ tag : {MkfBondIndexMessageCode}, body : MkfBondIndexMessage ]
        \cup [ tag : {KisBondIndexMessageCode}, body : KisBondIndexMessage ]
        \cup [ tag : {KebiBondIndexMessageCode}, body : KebiBondIndexMessage ]
        \cup [ tag : {KabiBondIndexMessageCode}, body : KabiBondIndexMessage ]
        \cup [ tag : {NicepniBondIndexMessageCode}, body : NicepniBondIndexMessage ]
        \cup [ tag : {DomesticEtfInavMessageCode}, body : DomesticEtfInavMessage ]
        \cup [ tag : {DomesticEtfEstimatedInavMessageCode}, body : DomesticEtfEstimatedInavMessage ]
        \cup [ tag : {GlobalEtfInavMessageCode}, body : GlobalEtfInavMessage ]
        \cup [ tag : {EtfTrackingErrorMessageCode}, body : EtfTrackingErrorMessage ]
        \cup [ tag : {GlobalEtfTrackingErrorMessageCode}, body : GlobalEtfTrackingErrorMessage ]
        \cup [ tag : {EtpPdfMessageCode}, body : EtpPdfMessage ]
        \cup [ tag : {EtpOperatorInformationMessageCode}, body : EtpOperatorInformationMessage ]
        \cup [ tag : {EtpOperatorInformationMessageCode2}, body : EtpOperatorInformationMessage ]
        \cup [ tag : {EtpOperatorInformationMessageCode3}, body : EtpOperatorInformationMessage ]
        \cup [ tag : {EtpTransferAgentBatchMessageCode}, body : EtpTransferAgentBatchMessage ]
        \cup [ tag : {EtpTransferAgentBatchMessageCode2}, body : EtpTransferAgentBatchMessage ]
        \cup [ tag : {EtpTransferAgentBatchMessageCode3}, body : EtpTransferAgentBatchMessage ]
        \cup [ tag : {EtfRiskAppraisementMessageCode}, body : EtfRiskAppraisementMessage ]
        \cup [ tag : {SyntheticEtfConstituentsMessageCode}, body : SyntheticEtfConstituentsMessage ]
        \cup [ tag : {ElwInvestmentIndicatorSensitivityMessageCode}, body : ElwInvestmentIndicatorSensitivityMessage ]
        \cup [ tag : {EtnIivMessageCode}, body : EtnIivMessage ]
        \cup [ tag : {EtnDisparateRatioMessageCode}, body : EtnDisparateRatioMessage ]
        \cup [ tag : {LoanTransactionAvailableQuantityMessageCode}, body : LoanTransactionAvailableQuantityMessage ]

EncodePayload(message) ==
    CASE message.tag = KOtcIssueClosingMessageCode -> EncodeKOtcIssueClosingMessage(message.body)
      [] message.tag = KOtcMarketOperationMessageCode -> EncodeKOtcMarketOperationMessage(message.body)
      [] message.tag = KOtcMarketActionMessageCode -> EncodeKOtcMarketActionMessage(message.body)
      [] message.tag = KOtcQuoteMessageCode -> EncodeKOtcQuoteMessage(message.body)
      [] message.tag = KOtcOrderFilledMessageCode -> EncodeKOtcOrderFilledMessage(message.body)
      [] message.tag = OtcBondTradedInfoMessageCode -> EncodeOtcBondTradedInfoMessage(message.body)
      [] message.tag = OtcBondTradesPerInstitutionMessageCode -> EncodeOtcBondTradesPerInstitutionMessage(message.body)
      [] message.tag = OtcBondTypesPerInvestorMessageCode -> EncodeOtcBondTypesPerInvestorMessage(message.body)
      [] message.tag = KBondMessageCode -> EncodeKBondMessage(message.body)
      [] message.tag = MkfIndexMessageCode -> EncodeMkfIndexMessage(message.body)
      [] message.tag = MkfIndexJpyMessageCode -> EncodeMkfIndexJpyMessage(message.body)
      [] message.tag = WisefnIndexMessageCode -> EncodeWisefnIndexMessage(message.body)
      [] message.tag = KisIndexMessageCode -> EncodeKisIndexMessage(message.body)
      [] message.tag = MkfBondIndexMessageCode -> EncodeMkfBondIndexMessage(message.body)
      [] message.tag = KisBondIndexMessageCode -> EncodeKisBondIndexMessage(message.body)
      [] message.tag = KebiBondIndexMessageCode -> EncodeKebiBondIndexMessage(message.body)
      [] message.tag = KabiBondIndexMessageCode -> EncodeKabiBondIndexMessage(message.body)
      [] message.tag = NicepniBondIndexMessageCode -> EncodeNicepniBondIndexMessage(message.body)
      [] message.tag = DomesticEtfInavMessageCode -> EncodeDomesticEtfInavMessage(message.body)
      [] message.tag = DomesticEtfEstimatedInavMessageCode -> EncodeDomesticEtfEstimatedInavMessage(message.body)
      [] message.tag = GlobalEtfInavMessageCode -> EncodeGlobalEtfInavMessage(message.body)
      [] message.tag = EtfTrackingErrorMessageCode -> EncodeEtfTrackingErrorMessage(message.body)
      [] message.tag = GlobalEtfTrackingErrorMessageCode -> EncodeGlobalEtfTrackingErrorMessage(message.body)
      [] message.tag = EtpPdfMessageCode -> EncodeEtpPdfMessage(message.body)
      [] message.tag = EtpOperatorInformationMessageCode -> EncodeEtpOperatorInformationMessage(message.body)
      [] message.tag = EtpOperatorInformationMessageCode2 -> EncodeEtpOperatorInformationMessage(message.body)
      [] message.tag = EtpOperatorInformationMessageCode3 -> EncodeEtpOperatorInformationMessage(message.body)
      [] message.tag = EtpTransferAgentBatchMessageCode -> EncodeEtpTransferAgentBatchMessage(message.body)
      [] message.tag = EtpTransferAgentBatchMessageCode2 -> EncodeEtpTransferAgentBatchMessage(message.body)
      [] message.tag = EtpTransferAgentBatchMessageCode3 -> EncodeEtpTransferAgentBatchMessage(message.body)
      [] message.tag = EtfRiskAppraisementMessageCode -> EncodeEtfRiskAppraisementMessage(message.body)
      [] message.tag = SyntheticEtfConstituentsMessageCode -> EncodeSyntheticEtfConstituentsMessage(message.body)
      [] message.tag = ElwInvestmentIndicatorSensitivityMessageCode -> EncodeElwInvestmentIndicatorSensitivityMessage(message.body)
      [] message.tag = EtnIivMessageCode -> EncodeEtnIivMessage(message.body)
      [] message.tag = EtnDisparateRatioMessageCode -> EncodeEtnDisparateRatioMessage(message.body)
      [] message.tag = LoanTransactionAvailableQuantityMessageCode -> EncodeLoanTransactionAvailableQuantityMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = KOtcIssueClosingMessageCode -> DecodeKOtcIssueClosingMessage(bytes)
              [] tag = KOtcMarketOperationMessageCode -> DecodeKOtcMarketOperationMessage(bytes)
              [] tag = KOtcMarketActionMessageCode -> DecodeKOtcMarketActionMessage(bytes)
              [] tag = KOtcQuoteMessageCode -> DecodeKOtcQuoteMessage(bytes)
              [] tag = KOtcOrderFilledMessageCode -> DecodeKOtcOrderFilledMessage(bytes)
              [] tag = OtcBondTradedInfoMessageCode -> DecodeOtcBondTradedInfoMessage(bytes)
              [] tag = OtcBondTradesPerInstitutionMessageCode -> DecodeOtcBondTradesPerInstitutionMessage(bytes)
              [] tag = OtcBondTypesPerInvestorMessageCode -> DecodeOtcBondTypesPerInvestorMessage(bytes)
              [] tag = KBondMessageCode -> DecodeKBondMessage(bytes)
              [] tag = MkfIndexMessageCode -> DecodeMkfIndexMessage(bytes)
              [] tag = MkfIndexJpyMessageCode -> DecodeMkfIndexJpyMessage(bytes)
              [] tag = WisefnIndexMessageCode -> DecodeWisefnIndexMessage(bytes)
              [] tag = KisIndexMessageCode -> DecodeKisIndexMessage(bytes)
              [] tag = MkfBondIndexMessageCode -> DecodeMkfBondIndexMessage(bytes)
              [] tag = KisBondIndexMessageCode -> DecodeKisBondIndexMessage(bytes)
              [] tag = KebiBondIndexMessageCode -> DecodeKebiBondIndexMessage(bytes)
              [] tag = KabiBondIndexMessageCode -> DecodeKabiBondIndexMessage(bytes)
              [] tag = NicepniBondIndexMessageCode -> DecodeNicepniBondIndexMessage(bytes)
              [] tag = DomesticEtfInavMessageCode -> DecodeDomesticEtfInavMessage(bytes)
              [] tag = DomesticEtfEstimatedInavMessageCode -> DecodeDomesticEtfEstimatedInavMessage(bytes)
              [] tag = GlobalEtfInavMessageCode -> DecodeGlobalEtfInavMessage(bytes)
              [] tag = EtfTrackingErrorMessageCode -> DecodeEtfTrackingErrorMessage(bytes)
              [] tag = GlobalEtfTrackingErrorMessageCode -> DecodeGlobalEtfTrackingErrorMessage(bytes)
              [] tag = EtpPdfMessageCode -> DecodeEtpPdfMessage(bytes)
              [] tag = EtpOperatorInformationMessageCode -> DecodeEtpOperatorInformationMessage(bytes)
              [] tag = EtpOperatorInformationMessageCode2 -> DecodeEtpOperatorInformationMessage(bytes)
              [] tag = EtpOperatorInformationMessageCode3 -> DecodeEtpOperatorInformationMessage(bytes)
              [] tag = EtpTransferAgentBatchMessageCode -> DecodeEtpTransferAgentBatchMessage(bytes)
              [] tag = EtpTransferAgentBatchMessageCode2 -> DecodeEtpTransferAgentBatchMessage(bytes)
              [] tag = EtpTransferAgentBatchMessageCode3 -> DecodeEtpTransferAgentBatchMessage(bytes)
              [] tag = EtfRiskAppraisementMessageCode -> DecodeEtfRiskAppraisementMessage(bytes)
              [] tag = SyntheticEtfConstituentsMessageCode -> DecodeSyntheticEtfConstituentsMessage(bytes)
              [] tag = ElwInvestmentIndicatorSensitivityMessageCode -> DecodeElwInvestmentIndicatorSensitivityMessage(bytes)
              [] tag = EtnIivMessageCode -> DecodeEtnIivMessage(bytes)
              [] tag = EtnDisparateRatioMessageCode -> DecodeEtnDisparateRatioMessage(bytes)
              [] tag = LoanTransactionAvailableQuantityMessageCode -> DecodeLoanTransactionAvailableQuantityMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> KOtcIssueClosingMessageCode, body |-> ZeroKOtcIssueClosingMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> KOtcIssueClosingMessageCode, body |-> one] : one \in CheckedKOtcIssueClosingMessage }
        \cup { [tag |-> KOtcMarketOperationMessageCode, body |-> one] : one \in CheckedKOtcMarketOperationMessage }
        \cup { [tag |-> KOtcMarketActionMessageCode, body |-> one] : one \in CheckedKOtcMarketActionMessage }
        \cup { [tag |-> KOtcQuoteMessageCode, body |-> one] : one \in CheckedKOtcQuoteMessage }
        \cup { [tag |-> KOtcOrderFilledMessageCode, body |-> one] : one \in CheckedKOtcOrderFilledMessage }
        \cup { [tag |-> OtcBondTradedInfoMessageCode, body |-> one] : one \in CheckedOtcBondTradedInfoMessage }
        \cup { [tag |-> OtcBondTradesPerInstitutionMessageCode, body |-> one] : one \in CheckedOtcBondTradesPerInstitutionMessage }
        \cup { [tag |-> OtcBondTypesPerInvestorMessageCode, body |-> one] : one \in CheckedOtcBondTypesPerInvestorMessage }
        \cup { [tag |-> KBondMessageCode, body |-> one] : one \in CheckedKBondMessage }
        \cup { [tag |-> MkfIndexMessageCode, body |-> one] : one \in CheckedMkfIndexMessage }
        \cup { [tag |-> MkfIndexJpyMessageCode, body |-> one] : one \in CheckedMkfIndexJpyMessage }
        \cup { [tag |-> WisefnIndexMessageCode, body |-> one] : one \in CheckedWisefnIndexMessage }
        \cup { [tag |-> KisIndexMessageCode, body |-> one] : one \in CheckedKisIndexMessage }
        \cup { [tag |-> MkfBondIndexMessageCode, body |-> one] : one \in CheckedMkfBondIndexMessage }
        \cup { [tag |-> KisBondIndexMessageCode, body |-> one] : one \in CheckedKisBondIndexMessage }
        \cup { [tag |-> KebiBondIndexMessageCode, body |-> one] : one \in CheckedKebiBondIndexMessage }
        \cup { [tag |-> KabiBondIndexMessageCode, body |-> one] : one \in CheckedKabiBondIndexMessage }
        \cup { [tag |-> NicepniBondIndexMessageCode, body |-> one] : one \in CheckedNicepniBondIndexMessage }
        \cup { [tag |-> DomesticEtfInavMessageCode, body |-> one] : one \in CheckedDomesticEtfInavMessage }
        \cup { [tag |-> DomesticEtfEstimatedInavMessageCode, body |-> one] : one \in CheckedDomesticEtfEstimatedInavMessage }
        \cup { [tag |-> GlobalEtfInavMessageCode, body |-> one] : one \in CheckedGlobalEtfInavMessage }
        \cup { [tag |-> EtfTrackingErrorMessageCode, body |-> one] : one \in CheckedEtfTrackingErrorMessage }
        \cup { [tag |-> GlobalEtfTrackingErrorMessageCode, body |-> one] : one \in CheckedGlobalEtfTrackingErrorMessage }
        \cup { [tag |-> EtpPdfMessageCode, body |-> one] : one \in CheckedEtpPdfMessage }
        \cup { [tag |-> EtpOperatorInformationMessageCode, body |-> one] : one \in CheckedEtpOperatorInformationMessage }
        \cup { [tag |-> EtpOperatorInformationMessageCode2, body |-> one] : one \in CheckedEtpOperatorInformationMessage }
        \cup { [tag |-> EtpOperatorInformationMessageCode3, body |-> one] : one \in CheckedEtpOperatorInformationMessage }
        \cup { [tag |-> EtpTransferAgentBatchMessageCode, body |-> one] : one \in CheckedEtpTransferAgentBatchMessage }
        \cup { [tag |-> EtpTransferAgentBatchMessageCode2, body |-> one] : one \in CheckedEtpTransferAgentBatchMessage }
        \cup { [tag |-> EtpTransferAgentBatchMessageCode3, body |-> one] : one \in CheckedEtpTransferAgentBatchMessage }
        \cup { [tag |-> EtfRiskAppraisementMessageCode, body |-> one] : one \in CheckedEtfRiskAppraisementMessage }
        \cup { [tag |-> SyntheticEtfConstituentsMessageCode, body |-> one] : one \in CheckedSyntheticEtfConstituentsMessage }
        \cup { [tag |-> ElwInvestmentIndicatorSensitivityMessageCode, body |-> one] : one \in CheckedElwInvestmentIndicatorSensitivityMessage }
        \cup { [tag |-> EtnIivMessageCode, body |-> one] : one \in CheckedEtnIivMessage }
        \cup { [tag |-> EtnDisparateRatioMessageCode, body |-> one] : one \in CheckedEtnDisparateRatioMessage }
        \cup { [tag |-> LoanTransactionAvailableQuantityMessageCode, body |-> one] : one \in CheckedLoanTransactionAvailableQuantityMessage }

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
    { [ZeroPacket EXCEPT !.payload = [tag |-> KOtcIssueClosingMessageCode, body |-> ZeroKOtcIssueClosingMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> KOtcMarketOperationMessageCode, body |-> ZeroKOtcMarketOperationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> KOtcMarketActionMessageCode, body |-> ZeroKOtcMarketActionMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> KOtcQuoteMessageCode, body |-> ZeroKOtcQuoteMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> KOtcOrderFilledMessageCode, body |-> ZeroKOtcOrderFilledMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> OtcBondTradedInfoMessageCode, body |-> ZeroOtcBondTradedInfoMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> OtcBondTradesPerInstitutionMessageCode, body |-> ZeroOtcBondTradesPerInstitutionMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> OtcBondTypesPerInvestorMessageCode, body |-> ZeroOtcBondTypesPerInvestorMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> KBondMessageCode, body |-> ZeroKBondMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MkfIndexMessageCode, body |-> ZeroMkfIndexMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MkfIndexJpyMessageCode, body |-> ZeroMkfIndexJpyMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> WisefnIndexMessageCode, body |-> ZeroWisefnIndexMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> KisIndexMessageCode, body |-> ZeroKisIndexMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> MkfBondIndexMessageCode, body |-> ZeroMkfBondIndexMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> KisBondIndexMessageCode, body |-> ZeroKisBondIndexMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> KebiBondIndexMessageCode, body |-> ZeroKebiBondIndexMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> KabiBondIndexMessageCode, body |-> ZeroKabiBondIndexMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> NicepniBondIndexMessageCode, body |-> ZeroNicepniBondIndexMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DomesticEtfInavMessageCode, body |-> ZeroDomesticEtfInavMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> DomesticEtfEstimatedInavMessageCode, body |-> ZeroDomesticEtfEstimatedInavMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> GlobalEtfInavMessageCode, body |-> ZeroGlobalEtfInavMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> EtfTrackingErrorMessageCode, body |-> ZeroEtfTrackingErrorMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> GlobalEtfTrackingErrorMessageCode, body |-> ZeroGlobalEtfTrackingErrorMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> EtpPdfMessageCode, body |-> ZeroEtpPdfMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> EtpOperatorInformationMessageCode, body |-> ZeroEtpOperatorInformationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> EtpOperatorInformationMessageCode2, body |-> ZeroEtpOperatorInformationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> EtpOperatorInformationMessageCode3, body |-> ZeroEtpOperatorInformationMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> EtpTransferAgentBatchMessageCode, body |-> ZeroEtpTransferAgentBatchMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> EtpTransferAgentBatchMessageCode2, body |-> ZeroEtpTransferAgentBatchMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> EtpTransferAgentBatchMessageCode3, body |-> ZeroEtpTransferAgentBatchMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> EtfRiskAppraisementMessageCode, body |-> ZeroEtfRiskAppraisementMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> SyntheticEtfConstituentsMessageCode, body |-> ZeroSyntheticEtfConstituentsMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> ElwInvestmentIndicatorSensitivityMessageCode, body |-> ZeroElwInvestmentIndicatorSensitivityMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> EtnIivMessageCode, body |-> ZeroEtnIivMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> EtnDisparateRatioMessageCode, body |-> ZeroEtnDisparateRatioMessage]],
      [ZeroPacket EXCEPT !.payload = [tag |-> LoanTransactionAvailableQuantityMessageCode, body |-> ZeroLoanTransactionAvailableQuantityMessage]] }

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

(* Every K Otc Issue Closing Message decodes back to what was encoded, and leaves nothing over *)
RoundTripKOtcIssueClosingMessage ==
    \A message \in CheckedKOtcIssueClosingMessage :
        LET read == DecodeKOtcIssueClosingMessage(EncodeKOtcIssueClosingMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every K Otc Market Operation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripKOtcMarketOperationMessage ==
    \A message \in CheckedKOtcMarketOperationMessage :
        LET read == DecodeKOtcMarketOperationMessage(EncodeKOtcMarketOperationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every K Otc Market Action Message decodes back to what was encoded, and leaves nothing over *)
RoundTripKOtcMarketActionMessage ==
    \A message \in CheckedKOtcMarketActionMessage :
        LET read == DecodeKOtcMarketActionMessage(EncodeKOtcMarketActionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every K Otc Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripKOtcQuoteMessage ==
    \A message \in CheckedKOtcQuoteMessage :
        LET read == DecodeKOtcQuoteMessage(EncodeKOtcQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every K Otc Order Filled Message decodes back to what was encoded, and leaves nothing over *)
RoundTripKOtcOrderFilledMessage ==
    \A message \in CheckedKOtcOrderFilledMessage :
        LET read == DecodeKOtcOrderFilledMessage(EncodeKOtcOrderFilledMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Otc Bond Traded Info Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOtcBondTradedInfoMessage ==
    \A message \in CheckedOtcBondTradedInfoMessage :
        LET read == DecodeOtcBondTradedInfoMessage(EncodeOtcBondTradedInfoMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Otc Bond Trades Per Institution Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOtcBondTradesPerInstitutionMessage ==
    \A message \in CheckedOtcBondTradesPerInstitutionMessage :
        LET read == DecodeOtcBondTradesPerInstitutionMessage(EncodeOtcBondTradesPerInstitutionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Otc Bond Types Per Investor Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOtcBondTypesPerInvestorMessage ==
    \A message \in CheckedOtcBondTypesPerInvestorMessage :
        LET read == DecodeOtcBondTypesPerInvestorMessage(EncodeOtcBondTypesPerInvestorMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every K Bond Message decodes back to what was encoded, and leaves nothing over *)
RoundTripKBondMessage ==
    \A message \in CheckedKBondMessage :
        LET read == DecodeKBondMessage(EncodeKBondMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mkf Index Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMkfIndexMessage ==
    \A message \in CheckedMkfIndexMessage :
        LET read == DecodeMkfIndexMessage(EncodeMkfIndexMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mkf Index Jpy Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMkfIndexJpyMessage ==
    \A message \in CheckedMkfIndexJpyMessage :
        LET read == DecodeMkfIndexJpyMessage(EncodeMkfIndexJpyMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Wisefn Index Message decodes back to what was encoded, and leaves nothing over *)
RoundTripWisefnIndexMessage ==
    \A message \in CheckedWisefnIndexMessage :
        LET read == DecodeWisefnIndexMessage(EncodeWisefnIndexMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Kis Index Message decodes back to what was encoded, and leaves nothing over *)
RoundTripKisIndexMessage ==
    \A message \in CheckedKisIndexMessage :
        LET read == DecodeKisIndexMessage(EncodeKisIndexMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mkf Bond Index Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMkfBondIndexMessage ==
    \A message \in CheckedMkfBondIndexMessage :
        LET read == DecodeMkfBondIndexMessage(EncodeMkfBondIndexMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Kis Bond Index Message decodes back to what was encoded, and leaves nothing over *)
RoundTripKisBondIndexMessage ==
    \A message \in CheckedKisBondIndexMessage :
        LET read == DecodeKisBondIndexMessage(EncodeKisBondIndexMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Kebi Bond Index Message decodes back to what was encoded, and leaves nothing over *)
RoundTripKebiBondIndexMessage ==
    \A message \in CheckedKebiBondIndexMessage :
        LET read == DecodeKebiBondIndexMessage(EncodeKebiBondIndexMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Kabi Bond Index Message decodes back to what was encoded, and leaves nothing over *)
RoundTripKabiBondIndexMessage ==
    \A message \in CheckedKabiBondIndexMessage :
        LET read == DecodeKabiBondIndexMessage(EncodeKabiBondIndexMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Nicepni Bond Index Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNicepniBondIndexMessage ==
    \A message \in CheckedNicepniBondIndexMessage :
        LET read == DecodeNicepniBondIndexMessage(EncodeNicepniBondIndexMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Domestic Etf Inav Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDomesticEtfInavMessage ==
    \A message \in CheckedDomesticEtfInavMessage :
        LET read == DecodeDomesticEtfInavMessage(EncodeDomesticEtfInavMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Domestic Etf Estimated Inav Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDomesticEtfEstimatedInavMessage ==
    \A message \in CheckedDomesticEtfEstimatedInavMessage :
        LET read == DecodeDomesticEtfEstimatedInavMessage(EncodeDomesticEtfEstimatedInavMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Global Etf Inav Message decodes back to what was encoded, and leaves nothing over *)
RoundTripGlobalEtfInavMessage ==
    \A message \in CheckedGlobalEtfInavMessage :
        LET read == DecodeGlobalEtfInavMessage(EncodeGlobalEtfInavMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Etf Tracking Error Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEtfTrackingErrorMessage ==
    \A message \in CheckedEtfTrackingErrorMessage :
        LET read == DecodeEtfTrackingErrorMessage(EncodeEtfTrackingErrorMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Global Etf Tracking Error Message decodes back to what was encoded, and leaves nothing over *)
RoundTripGlobalEtfTrackingErrorMessage ==
    \A message \in CheckedGlobalEtfTrackingErrorMessage :
        LET read == DecodeGlobalEtfTrackingErrorMessage(EncodeGlobalEtfTrackingErrorMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Etp Pdf Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEtpPdfMessage ==
    \A message \in CheckedEtpPdfMessage :
        LET read == DecodeEtpPdfMessage(EncodeEtpPdfMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Etp Operator Information Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEtpOperatorInformationMessage ==
    \A message \in CheckedEtpOperatorInformationMessage :
        LET read == DecodeEtpOperatorInformationMessage(EncodeEtpOperatorInformationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Etp Transfer Agent Batch Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEtpTransferAgentBatchMessage ==
    \A message \in CheckedEtpTransferAgentBatchMessage :
        LET read == DecodeEtpTransferAgentBatchMessage(EncodeEtpTransferAgentBatchMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Etf Risk Appraisement Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEtfRiskAppraisementMessage ==
    \A message \in CheckedEtfRiskAppraisementMessage :
        LET read == DecodeEtfRiskAppraisementMessage(EncodeEtfRiskAppraisementMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Synthetic Etf Constituents Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSyntheticEtfConstituentsMessage ==
    \A message \in CheckedSyntheticEtfConstituentsMessage :
        LET read == DecodeSyntheticEtfConstituentsMessage(EncodeSyntheticEtfConstituentsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Elw Investment Indicator Sensitivity Message decodes back to what was encoded, and leaves nothing over *)
RoundTripElwInvestmentIndicatorSensitivityMessage ==
    \A message \in CheckedElwInvestmentIndicatorSensitivityMessage :
        LET read == DecodeElwInvestmentIndicatorSensitivityMessage(EncodeElwInvestmentIndicatorSensitivityMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Etn Iiv Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEtnIivMessage ==
    \A message \in CheckedEtnIivMessage :
        LET read == DecodeEtnIivMessage(EncodeEtnIivMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Etn Disparate Ratio Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEtnDisparateRatioMessage ==
    \A message \in CheckedEtnDisparateRatioMessage :
        LET read == DecodeEtnDisparateRatioMessage(EncodeEtnDisparateRatioMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Loan Transaction Available Quantity Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoanTransactionAvailableQuantityMessage ==
    \A message \in CheckedLoanTransactionAvailableQuantityMessage :
        LET read == DecodeLoanTransactionAvailableQuantityMessage(EncodeLoanTransactionAvailableQuantityMessage(message))
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
