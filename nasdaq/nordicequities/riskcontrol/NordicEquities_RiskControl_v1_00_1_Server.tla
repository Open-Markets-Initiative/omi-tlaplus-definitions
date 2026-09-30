------------- MODULE NordicEquities_RiskControl_v1_00_1_Server -------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Nordic Pre-Trade Risk Management v1.00.1                       *)
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
(* Note: Sequenced Data Packet fills what is left of the frame Packet      *)
(* Length states, which is what it is read from.                           *)
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
(* Debug Packet: 1 bytes                                                   *)
(***************************************************************************)

DebugPacket ==
    [ debugText : Sample(1) ]

EncodeDebugPacket(message) ==
    message.debugText

DecodeDebugPacket(bytes) ==
    LET debugText == ReadBytes(bytes, 1) IN IF ~debugText.ok THEN Fail ELSE
    Ok([ debugText |-> debugText.value ], debugText.rest)

ZeroDebugPacket ==
    [ debugText |-> [i \in 1 .. 1 |-> 0] ]

(* Debug Packet at zero, then each field in turn at the values it is checked at *)
CheckedDebugPacket ==
    { ZeroDebugPacket }
        \cup { [ZeroDebugPacket EXCEPT !.debugText = one] : one \in Sample(1) }

(***************************************************************************)
(* Login Accepted Packet: 30 bytes                                         *)
(***************************************************************************)

LoginAcceptedPacket ==
    [ acceptedSession        : Sample(10),
      acceptedSequenceNumber : Sample(20) ]

EncodeLoginAcceptedPacket(message) ==
    message.acceptedSession
        \o message.acceptedSequenceNumber

DecodeLoginAcceptedPacket(bytes) ==
    LET acceptedSession == ReadBytes(bytes, 10) IN IF ~acceptedSession.ok THEN Fail ELSE
    LET acceptedSequenceNumber == ReadBytes(acceptedSession.rest, 20) IN IF ~acceptedSequenceNumber.ok THEN Fail ELSE
    Ok([ acceptedSession        |-> acceptedSession.value,
         acceptedSequenceNumber |-> acceptedSequenceNumber.value ], acceptedSequenceNumber.rest)

ZeroLoginAcceptedPacket ==
    [ acceptedSession        |-> [i \in 1 .. 10 |-> 0],
      acceptedSequenceNumber |-> [i \in 1 .. 20 |-> 0] ]

(* Login Accepted Packet at zero, then each field in turn at the values it is checked at *)
CheckedLoginAcceptedPacket ==
    { ZeroLoginAcceptedPacket }
        \cup { [ZeroLoginAcceptedPacket EXCEPT !.acceptedSession = one] : one \in Sample(10) }
        \cup { [ZeroLoginAcceptedPacket EXCEPT !.acceptedSequenceNumber = one] : one \in Sample(20) }

(***************************************************************************)
(* Login Rejected Packet: 1 bytes                                          *)
(***************************************************************************)

LoginRejectedPacket ==
    [ rejectReasonCode : Sample(1) ]

EncodeLoginRejectedPacket(message) ==
    message.rejectReasonCode

DecodeLoginRejectedPacket(bytes) ==
    LET rejectReasonCode == ReadBytes(bytes, 1) IN IF ~rejectReasonCode.ok THEN Fail ELSE
    Ok([ rejectReasonCode |-> rejectReasonCode.value ], rejectReasonCode.rest)

ZeroLoginRejectedPacket ==
    [ rejectReasonCode |-> [i \in 1 .. 1 |-> 0] ]

(* Login Rejected Packet at zero, then each field in turn at the values it is checked at *)
CheckedLoginRejectedPacket ==
    { ZeroLoginRejectedPacket }
        \cup { [ZeroLoginRejectedPacket EXCEPT !.rejectReasonCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Account Query Response Message: 4 bytes                                 *)
(***************************************************************************)

AccountQueryResponseMessage ==
    [ userRefNum : Sample(4) ]

EncodeAccountQueryResponseMessage(message) ==
    message.userRefNum

DecodeAccountQueryResponseMessage(bytes) ==
    LET userRefNum == ReadBytes(bytes, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    Ok([ userRefNum |-> userRefNum.value ], userRefNum.rest)

ZeroAccountQueryResponseMessage ==
    [ userRefNum |-> [i \in 1 .. 4 |-> 0] ]

(* Account Query Response Message at zero, then each field in turn at the values it is checked at *)
CheckedAccountQueryResponseMessage ==
    { ZeroAccountQueryResponseMessage }
        \cup { [ZeroAccountQueryResponseMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }

(***************************************************************************)
(* Account Settings Response Message: 19 bytes                             *)
(***************************************************************************)

AccountSettingsResponseMessage ==
    [ userRefNum                                     : Sample(4),
      prmAccount                                     : Sample(6),
      repeatedOrderGeneration                        : Sample(4),
      triggerRestrictSymbolOnRepeatedOrderGeneration : Sample(1),
      inAuctionMarketOrderPrevention                 : Sample(1),
      inAuctionFatFingerProtection                   : Sample(1),
      inAuctionMarketOrderProtection                 : Sample(1),
      blockAndCancel                                 : Sample(1) ]

EncodeAccountSettingsResponseMessage(message) ==
    message.userRefNum
        \o message.prmAccount
        \o message.repeatedOrderGeneration
        \o message.triggerRestrictSymbolOnRepeatedOrderGeneration
        \o message.inAuctionMarketOrderPrevention
        \o message.inAuctionFatFingerProtection
        \o message.inAuctionMarketOrderProtection
        \o message.blockAndCancel

DecodeAccountSettingsResponseMessage(bytes) ==
    LET userRefNum == ReadBytes(bytes, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET prmAccount == ReadBytes(userRefNum.rest, 6) IN IF ~prmAccount.ok THEN Fail ELSE
    LET repeatedOrderGeneration == ReadBytes(prmAccount.rest, 4) IN IF ~repeatedOrderGeneration.ok THEN Fail ELSE
    LET triggerRestrictSymbolOnRepeatedOrderGeneration == ReadBytes(repeatedOrderGeneration.rest, 1) IN IF ~triggerRestrictSymbolOnRepeatedOrderGeneration.ok THEN Fail ELSE
    LET inAuctionMarketOrderPrevention == ReadBytes(triggerRestrictSymbolOnRepeatedOrderGeneration.rest, 1) IN IF ~inAuctionMarketOrderPrevention.ok THEN Fail ELSE
    LET inAuctionFatFingerProtection == ReadBytes(inAuctionMarketOrderPrevention.rest, 1) IN IF ~inAuctionFatFingerProtection.ok THEN Fail ELSE
    LET inAuctionMarketOrderProtection == ReadBytes(inAuctionFatFingerProtection.rest, 1) IN IF ~inAuctionMarketOrderProtection.ok THEN Fail ELSE
    LET blockAndCancel == ReadBytes(inAuctionMarketOrderProtection.rest, 1) IN IF ~blockAndCancel.ok THEN Fail ELSE
    Ok([ userRefNum                                     |-> userRefNum.value,
         prmAccount                                     |-> prmAccount.value,
         repeatedOrderGeneration                        |-> repeatedOrderGeneration.value,
         triggerRestrictSymbolOnRepeatedOrderGeneration |-> triggerRestrictSymbolOnRepeatedOrderGeneration.value,
         inAuctionMarketOrderPrevention                 |-> inAuctionMarketOrderPrevention.value,
         inAuctionFatFingerProtection                   |-> inAuctionFatFingerProtection.value,
         inAuctionMarketOrderProtection                 |-> inAuctionMarketOrderProtection.value,
         blockAndCancel                                 |-> blockAndCancel.value ], blockAndCancel.rest)

ZeroAccountSettingsResponseMessage ==
    [ userRefNum                                     |-> [i \in 1 .. 4 |-> 0],
      prmAccount                                     |-> [i \in 1 .. 6 |-> 0],
      repeatedOrderGeneration                        |-> [i \in 1 .. 4 |-> 0],
      triggerRestrictSymbolOnRepeatedOrderGeneration |-> [i \in 1 .. 1 |-> 0],
      inAuctionMarketOrderPrevention                 |-> [i \in 1 .. 1 |-> 0],
      inAuctionFatFingerProtection                   |-> [i \in 1 .. 1 |-> 0],
      inAuctionMarketOrderProtection                 |-> [i \in 1 .. 1 |-> 0],
      blockAndCancel                                 |-> [i \in 1 .. 1 |-> 0] ]

(* Account Settings Response Message at zero, then each field in turn at the values it is checked at *)
CheckedAccountSettingsResponseMessage ==
    { ZeroAccountSettingsResponseMessage }
        \cup { [ZeroAccountSettingsResponseMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroAccountSettingsResponseMessage EXCEPT !.prmAccount = one] : one \in Sample(6) }
        \cup { [ZeroAccountSettingsResponseMessage EXCEPT !.repeatedOrderGeneration = one] : one \in Sample(4) }
        \cup { [ZeroAccountSettingsResponseMessage EXCEPT !.triggerRestrictSymbolOnRepeatedOrderGeneration = one] : one \in Sample(1) }
        \cup { [ZeroAccountSettingsResponseMessage EXCEPT !.inAuctionMarketOrderPrevention = one] : one \in Sample(1) }
        \cup { [ZeroAccountSettingsResponseMessage EXCEPT !.inAuctionFatFingerProtection = one] : one \in Sample(1) }
        \cup { [ZeroAccountSettingsResponseMessage EXCEPT !.inAuctionMarketOrderProtection = one] : one \in Sample(1) }
        \cup { [ZeroAccountSettingsResponseMessage EXCEPT !.blockAndCancel = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Book Restriction Response Message: 23 bytes                       *)
(***************************************************************************)

OrderBookRestrictionResponseMessage ==
    [ userRefNum : Sample(4),
      timestamp  : Sample(8),
      prmAccount : Sample(6),
      orderBook  : Sample(4),
      state      : Sample(1) ]

EncodeOrderBookRestrictionResponseMessage(message) ==
    message.userRefNum
        \o message.timestamp
        \o message.prmAccount
        \o message.orderBook
        \o message.state

DecodeOrderBookRestrictionResponseMessage(bytes) ==
    LET userRefNum == ReadBytes(bytes, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET timestamp == ReadBytes(userRefNum.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET prmAccount == ReadBytes(timestamp.rest, 6) IN IF ~prmAccount.ok THEN Fail ELSE
    LET orderBook == ReadBytes(prmAccount.rest, 4) IN IF ~orderBook.ok THEN Fail ELSE
    LET state == ReadBytes(orderBook.rest, 1) IN IF ~state.ok THEN Fail ELSE
    Ok([ userRefNum |-> userRefNum.value,
         timestamp  |-> timestamp.value,
         prmAccount |-> prmAccount.value,
         orderBook  |-> orderBook.value,
         state      |-> state.value ], state.rest)

ZeroOrderBookRestrictionResponseMessage ==
    [ userRefNum |-> [i \in 1 .. 4 |-> 0],
      timestamp  |-> [i \in 1 .. 8 |-> 0],
      prmAccount |-> [i \in 1 .. 6 |-> 0],
      orderBook  |-> [i \in 1 .. 4 |-> 0],
      state      |-> [i \in 1 .. 1 |-> 0] ]

(* Order Book Restriction Response Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderBookRestrictionResponseMessage ==
    { ZeroOrderBookRestrictionResponseMessage }
        \cup { [ZeroOrderBookRestrictionResponseMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookRestrictionResponseMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderBookRestrictionResponseMessage EXCEPT !.prmAccount = one] : one \in Sample(6) }
        \cup { [ZeroOrderBookRestrictionResponseMessage EXCEPT !.orderBook = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookRestrictionResponseMessage EXCEPT !.state = one] : one \in Sample(1) }

(***************************************************************************)
(* Market Segment Restriction Response Message: 21 bytes                   *)
(***************************************************************************)

MarketSegmentRestrictionResponseMessage ==
    [ userRefNum    : Sample(4),
      timestamp     : Sample(8),
      prmAccount    : Sample(6),
      marketSegment : Sample(2),
      state         : Sample(1) ]

EncodeMarketSegmentRestrictionResponseMessage(message) ==
    message.userRefNum
        \o message.timestamp
        \o message.prmAccount
        \o message.marketSegment
        \o message.state

DecodeMarketSegmentRestrictionResponseMessage(bytes) ==
    LET userRefNum == ReadBytes(bytes, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET timestamp == ReadBytes(userRefNum.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET prmAccount == ReadBytes(timestamp.rest, 6) IN IF ~prmAccount.ok THEN Fail ELSE
    LET marketSegment == ReadBytes(prmAccount.rest, 2) IN IF ~marketSegment.ok THEN Fail ELSE
    LET state == ReadBytes(marketSegment.rest, 1) IN IF ~state.ok THEN Fail ELSE
    Ok([ userRefNum    |-> userRefNum.value,
         timestamp     |-> timestamp.value,
         prmAccount    |-> prmAccount.value,
         marketSegment |-> marketSegment.value,
         state         |-> state.value ], state.rest)

ZeroMarketSegmentRestrictionResponseMessage ==
    [ userRefNum    |-> [i \in 1 .. 4 |-> 0],
      timestamp     |-> [i \in 1 .. 8 |-> 0],
      prmAccount    |-> [i \in 1 .. 6 |-> 0],
      marketSegment |-> [i \in 1 .. 2 |-> 0],
      state         |-> [i \in 1 .. 1 |-> 0] ]

(* Market Segment Restriction Response Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketSegmentRestrictionResponseMessage ==
    { ZeroMarketSegmentRestrictionResponseMessage }
        \cup { [ZeroMarketSegmentRestrictionResponseMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroMarketSegmentRestrictionResponseMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroMarketSegmentRestrictionResponseMessage EXCEPT !.prmAccount = one] : one \in Sample(6) }
        \cup { [ZeroMarketSegmentRestrictionResponseMessage EXCEPT !.marketSegment = one] : one \in Sample(2) }
        \cup { [ZeroMarketSegmentRestrictionResponseMessage EXCEPT !.state = one] : one \in Sample(1) }

(***************************************************************************)
(* Limit Settings Response Message: 109 bytes                              *)
(***************************************************************************)

LimitSettingsResponseMessage ==
    [ userRefNum         : Sample(4),
      prmAccount         : Sample(6),
      currency           : Sample(3),
      maxQuantity        : Sample(8),
      maxValue           : Sample(8),
      unused             : Sample(8),
      totalRiskValue     : Sample(8),
      tradeBuyValue      : Sample(8),
      tradeSellValue     : Sample(8),
      tradeNetValue      : Sample(8),
      openOrderBuyValue  : Sample(8),
      openOrderSellValue : Sample(8),
      openOrderNetValue  : Sample(8),
      maxQuantityAuction : Sample(8),
      maxValueAuction    : Sample(8) ]

EncodeLimitSettingsResponseMessage(message) ==
    message.userRefNum
        \o message.prmAccount
        \o message.currency
        \o message.maxQuantity
        \o message.maxValue
        \o message.unused
        \o message.totalRiskValue
        \o message.tradeBuyValue
        \o message.tradeSellValue
        \o message.tradeNetValue
        \o message.openOrderBuyValue
        \o message.openOrderSellValue
        \o message.openOrderNetValue
        \o message.maxQuantityAuction
        \o message.maxValueAuction

DecodeLimitSettingsResponseMessage(bytes) ==
    LET userRefNum == ReadBytes(bytes, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET prmAccount == ReadBytes(userRefNum.rest, 6) IN IF ~prmAccount.ok THEN Fail ELSE
    LET currency == ReadBytes(prmAccount.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET maxQuantity == ReadBytes(currency.rest, 8) IN IF ~maxQuantity.ok THEN Fail ELSE
    LET maxValue == ReadBytes(maxQuantity.rest, 8) IN IF ~maxValue.ok THEN Fail ELSE
    LET unused == ReadBytes(maxValue.rest, 8) IN IF ~unused.ok THEN Fail ELSE
    LET totalRiskValue == ReadBytes(unused.rest, 8) IN IF ~totalRiskValue.ok THEN Fail ELSE
    LET tradeBuyValue == ReadBytes(totalRiskValue.rest, 8) IN IF ~tradeBuyValue.ok THEN Fail ELSE
    LET tradeSellValue == ReadBytes(tradeBuyValue.rest, 8) IN IF ~tradeSellValue.ok THEN Fail ELSE
    LET tradeNetValue == ReadBytes(tradeSellValue.rest, 8) IN IF ~tradeNetValue.ok THEN Fail ELSE
    LET openOrderBuyValue == ReadBytes(tradeNetValue.rest, 8) IN IF ~openOrderBuyValue.ok THEN Fail ELSE
    LET openOrderSellValue == ReadBytes(openOrderBuyValue.rest, 8) IN IF ~openOrderSellValue.ok THEN Fail ELSE
    LET openOrderNetValue == ReadBytes(openOrderSellValue.rest, 8) IN IF ~openOrderNetValue.ok THEN Fail ELSE
    LET maxQuantityAuction == ReadBytes(openOrderNetValue.rest, 8) IN IF ~maxQuantityAuction.ok THEN Fail ELSE
    LET maxValueAuction == ReadBytes(maxQuantityAuction.rest, 8) IN IF ~maxValueAuction.ok THEN Fail ELSE
    Ok([ userRefNum         |-> userRefNum.value,
         prmAccount         |-> prmAccount.value,
         currency           |-> currency.value,
         maxQuantity        |-> maxQuantity.value,
         maxValue           |-> maxValue.value,
         unused             |-> unused.value,
         totalRiskValue     |-> totalRiskValue.value,
         tradeBuyValue      |-> tradeBuyValue.value,
         tradeSellValue     |-> tradeSellValue.value,
         tradeNetValue      |-> tradeNetValue.value,
         openOrderBuyValue  |-> openOrderBuyValue.value,
         openOrderSellValue |-> openOrderSellValue.value,
         openOrderNetValue  |-> openOrderNetValue.value,
         maxQuantityAuction |-> maxQuantityAuction.value,
         maxValueAuction    |-> maxValueAuction.value ], maxValueAuction.rest)

ZeroLimitSettingsResponseMessage ==
    [ userRefNum         |-> [i \in 1 .. 4 |-> 0],
      prmAccount         |-> [i \in 1 .. 6 |-> 0],
      currency           |-> [i \in 1 .. 3 |-> 0],
      maxQuantity        |-> [i \in 1 .. 8 |-> 0],
      maxValue           |-> [i \in 1 .. 8 |-> 0],
      unused             |-> [i \in 1 .. 8 |-> 0],
      totalRiskValue     |-> [i \in 1 .. 8 |-> 0],
      tradeBuyValue      |-> [i \in 1 .. 8 |-> 0],
      tradeSellValue     |-> [i \in 1 .. 8 |-> 0],
      tradeNetValue      |-> [i \in 1 .. 8 |-> 0],
      openOrderBuyValue  |-> [i \in 1 .. 8 |-> 0],
      openOrderSellValue |-> [i \in 1 .. 8 |-> 0],
      openOrderNetValue  |-> [i \in 1 .. 8 |-> 0],
      maxQuantityAuction |-> [i \in 1 .. 8 |-> 0],
      maxValueAuction    |-> [i \in 1 .. 8 |-> 0] ]

(* Limit Settings Response Message at zero, then each field in turn at the values it is checked at *)
CheckedLimitSettingsResponseMessage ==
    { ZeroLimitSettingsResponseMessage }
        \cup { [ZeroLimitSettingsResponseMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroLimitSettingsResponseMessage EXCEPT !.prmAccount = one] : one \in Sample(6) }
        \cup { [ZeroLimitSettingsResponseMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroLimitSettingsResponseMessage EXCEPT !.maxQuantity = one] : one \in Sample(8) }
        \cup { [ZeroLimitSettingsResponseMessage EXCEPT !.maxValue = one] : one \in Sample(8) }
        \cup { [ZeroLimitSettingsResponseMessage EXCEPT !.unused = one] : one \in Sample(8) }
        \cup { [ZeroLimitSettingsResponseMessage EXCEPT !.totalRiskValue = one] : one \in Sample(8) }
        \cup { [ZeroLimitSettingsResponseMessage EXCEPT !.tradeBuyValue = one] : one \in Sample(8) }
        \cup { [ZeroLimitSettingsResponseMessage EXCEPT !.tradeSellValue = one] : one \in Sample(8) }
        \cup { [ZeroLimitSettingsResponseMessage EXCEPT !.tradeNetValue = one] : one \in Sample(8) }
        \cup { [ZeroLimitSettingsResponseMessage EXCEPT !.openOrderBuyValue = one] : one \in Sample(8) }
        \cup { [ZeroLimitSettingsResponseMessage EXCEPT !.openOrderSellValue = one] : one \in Sample(8) }
        \cup { [ZeroLimitSettingsResponseMessage EXCEPT !.openOrderNetValue = one] : one \in Sample(8) }
        \cup { [ZeroLimitSettingsResponseMessage EXCEPT !.maxQuantityAuction = one] : one \in Sample(8) }
        \cup { [ZeroLimitSettingsResponseMessage EXCEPT !.maxValueAuction = one] : one \in Sample(8) }

(***************************************************************************)
(* Account Currency Setting Response Message: 15 bytes                     *)
(***************************************************************************)

AccountCurrencySettingResponseMessage ==
    [ userRefNum            : Sample(4),
      prmAccount            : Sample(6),
      currency              : Sample(3),
      rejectAllFlag         : Sample(1),
      blowThroughProtection : Sample(1) ]

EncodeAccountCurrencySettingResponseMessage(message) ==
    message.userRefNum
        \o message.prmAccount
        \o message.currency
        \o message.rejectAllFlag
        \o message.blowThroughProtection

DecodeAccountCurrencySettingResponseMessage(bytes) ==
    LET userRefNum == ReadBytes(bytes, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET prmAccount == ReadBytes(userRefNum.rest, 6) IN IF ~prmAccount.ok THEN Fail ELSE
    LET currency == ReadBytes(prmAccount.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET rejectAllFlag == ReadBytes(currency.rest, 1) IN IF ~rejectAllFlag.ok THEN Fail ELSE
    LET blowThroughProtection == ReadBytes(rejectAllFlag.rest, 1) IN IF ~blowThroughProtection.ok THEN Fail ELSE
    Ok([ userRefNum            |-> userRefNum.value,
         prmAccount            |-> prmAccount.value,
         currency              |-> currency.value,
         rejectAllFlag         |-> rejectAllFlag.value,
         blowThroughProtection |-> blowThroughProtection.value ], blowThroughProtection.rest)

ZeroAccountCurrencySettingResponseMessage ==
    [ userRefNum            |-> [i \in 1 .. 4 |-> 0],
      prmAccount            |-> [i \in 1 .. 6 |-> 0],
      currency              |-> [i \in 1 .. 3 |-> 0],
      rejectAllFlag         |-> [i \in 1 .. 1 |-> 0],
      blowThroughProtection |-> [i \in 1 .. 1 |-> 0] ]

(* Account Currency Setting Response Message at zero, then each field in turn at the values it is checked at *)
CheckedAccountCurrencySettingResponseMessage ==
    { ZeroAccountCurrencySettingResponseMessage }
        \cup { [ZeroAccountCurrencySettingResponseMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroAccountCurrencySettingResponseMessage EXCEPT !.prmAccount = one] : one \in Sample(6) }
        \cup { [ZeroAccountCurrencySettingResponseMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroAccountCurrencySettingResponseMessage EXCEPT !.rejectAllFlag = one] : one \in Sample(1) }
        \cup { [ZeroAccountCurrencySettingResponseMessage EXCEPT !.blowThroughProtection = one] : one \in Sample(1) }

(***************************************************************************)
(* Reject Message: 5 bytes                                                 *)
(***************************************************************************)

RejectMessage ==
    [ userRefNum : Sample(4),
      reason     : Sample(1) ]

EncodeRejectMessage(message) ==
    message.userRefNum
        \o message.reason

DecodeRejectMessage(bytes) ==
    LET userRefNum == ReadBytes(bytes, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET reason == ReadBytes(userRefNum.rest, 1) IN IF ~reason.ok THEN Fail ELSE
    Ok([ userRefNum |-> userRefNum.value,
         reason     |-> reason.value ], reason.rest)

ZeroRejectMessage ==
    [ userRefNum |-> [i \in 1 .. 4 |-> 0],
      reason     |-> [i \in 1 .. 1 |-> 0] ]

(* Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedRejectMessage ==
    { ZeroRejectMessage }
        \cup { [ZeroRejectMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroRejectMessage EXCEPT !.reason = one] : one \in Sample(1) }

(***************************************************************************)
(* Api Port Rate Breach Message: 8 bytes                                   *)
(***************************************************************************)

ApiPortRateBreachMessage ==
    [ timestamp : Sample(8) ]

EncodeApiPortRateBreachMessage(message) ==
    message.timestamp

DecodeApiPortRateBreachMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    Ok([ timestamp |-> timestamp.value ], timestamp.rest)

ZeroApiPortRateBreachMessage ==
    [ timestamp |-> [i \in 1 .. 8 |-> 0] ]

(* Api Port Rate Breach Message at zero, then each field in turn at the values it is checked at *)
CheckedApiPortRateBreachMessage ==
    { ZeroApiPortRateBreachMessage }
        \cup { [ZeroApiPortRateBreachMessage EXCEPT !.timestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Account Rate Breach Message: 15 bytes                                   *)
(***************************************************************************)

AccountRateBreachMessage ==
    [ timestamp  : Sample(8),
      state      : Sample(1),
      prmAccount : Sample(6) ]

EncodeAccountRateBreachMessage(message) ==
    message.timestamp
        \o message.state
        \o message.prmAccount

DecodeAccountRateBreachMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET state == ReadBytes(timestamp.rest, 1) IN IF ~state.ok THEN Fail ELSE
    LET prmAccount == ReadBytes(state.rest, 6) IN IF ~prmAccount.ok THEN Fail ELSE
    Ok([ timestamp  |-> timestamp.value,
         state      |-> state.value,
         prmAccount |-> prmAccount.value ], prmAccount.rest)

ZeroAccountRateBreachMessage ==
    [ timestamp  |-> [i \in 1 .. 8 |-> 0],
      state      |-> [i \in 1 .. 1 |-> 0],
      prmAccount |-> [i \in 1 .. 6 |-> 0] ]

(* Account Rate Breach Message at zero, then each field in turn at the values it is checked at *)
CheckedAccountRateBreachMessage ==
    { ZeroAccountRateBreachMessage }
        \cup { [ZeroAccountRateBreachMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAccountRateBreachMessage EXCEPT !.state = one] : one \in Sample(1) }
        \cup { [ZeroAccountRateBreachMessage EXCEPT !.prmAccount = one] : one \in Sample(6) }

(***************************************************************************)
(* Accumulated Values Message: 73 bytes                                    *)
(***************************************************************************)

AccumulatedValuesMessage ==
    [ prmAccount       : Sample(6),
      currency         : Sample(3),
      lastUpdateTime   : Sample(8),
      riskTotalValue   : Sample(8),
      tradesBuyValue   : Sample(8),
      tradesSellValue  : Sample(8),
      tradesTotalValue : Sample(8),
      ordersBuyValue   : Sample(8),
      ordersSellValue  : Sample(8),
      ordersTotalValue : Sample(8) ]

EncodeAccumulatedValuesMessage(message) ==
    message.prmAccount
        \o message.currency
        \o message.lastUpdateTime
        \o message.riskTotalValue
        \o message.tradesBuyValue
        \o message.tradesSellValue
        \o message.tradesTotalValue
        \o message.ordersBuyValue
        \o message.ordersSellValue
        \o message.ordersTotalValue

DecodeAccumulatedValuesMessage(bytes) ==
    LET prmAccount == ReadBytes(bytes, 6) IN IF ~prmAccount.ok THEN Fail ELSE
    LET currency == ReadBytes(prmAccount.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET lastUpdateTime == ReadBytes(currency.rest, 8) IN IF ~lastUpdateTime.ok THEN Fail ELSE
    LET riskTotalValue == ReadBytes(lastUpdateTime.rest, 8) IN IF ~riskTotalValue.ok THEN Fail ELSE
    LET tradesBuyValue == ReadBytes(riskTotalValue.rest, 8) IN IF ~tradesBuyValue.ok THEN Fail ELSE
    LET tradesSellValue == ReadBytes(tradesBuyValue.rest, 8) IN IF ~tradesSellValue.ok THEN Fail ELSE
    LET tradesTotalValue == ReadBytes(tradesSellValue.rest, 8) IN IF ~tradesTotalValue.ok THEN Fail ELSE
    LET ordersBuyValue == ReadBytes(tradesTotalValue.rest, 8) IN IF ~ordersBuyValue.ok THEN Fail ELSE
    LET ordersSellValue == ReadBytes(ordersBuyValue.rest, 8) IN IF ~ordersSellValue.ok THEN Fail ELSE
    LET ordersTotalValue == ReadBytes(ordersSellValue.rest, 8) IN IF ~ordersTotalValue.ok THEN Fail ELSE
    Ok([ prmAccount       |-> prmAccount.value,
         currency         |-> currency.value,
         lastUpdateTime   |-> lastUpdateTime.value,
         riskTotalValue   |-> riskTotalValue.value,
         tradesBuyValue   |-> tradesBuyValue.value,
         tradesSellValue  |-> tradesSellValue.value,
         tradesTotalValue |-> tradesTotalValue.value,
         ordersBuyValue   |-> ordersBuyValue.value,
         ordersSellValue  |-> ordersSellValue.value,
         ordersTotalValue |-> ordersTotalValue.value ], ordersTotalValue.rest)

ZeroAccumulatedValuesMessage ==
    [ prmAccount       |-> [i \in 1 .. 6 |-> 0],
      currency         |-> [i \in 1 .. 3 |-> 0],
      lastUpdateTime   |-> [i \in 1 .. 8 |-> 0],
      riskTotalValue   |-> [i \in 1 .. 8 |-> 0],
      tradesBuyValue   |-> [i \in 1 .. 8 |-> 0],
      tradesSellValue  |-> [i \in 1 .. 8 |-> 0],
      tradesTotalValue |-> [i \in 1 .. 8 |-> 0],
      ordersBuyValue   |-> [i \in 1 .. 8 |-> 0],
      ordersSellValue  |-> [i \in 1 .. 8 |-> 0],
      ordersTotalValue |-> [i \in 1 .. 8 |-> 0] ]

(* Accumulated Values Message at zero, then each field in turn at the values it is checked at *)
CheckedAccumulatedValuesMessage ==
    { ZeroAccumulatedValuesMessage }
        \cup { [ZeroAccumulatedValuesMessage EXCEPT !.prmAccount = one] : one \in Sample(6) }
        \cup { [ZeroAccumulatedValuesMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroAccumulatedValuesMessage EXCEPT !.lastUpdateTime = one] : one \in Sample(8) }
        \cup { [ZeroAccumulatedValuesMessage EXCEPT !.riskTotalValue = one] : one \in Sample(8) }
        \cup { [ZeroAccumulatedValuesMessage EXCEPT !.tradesBuyValue = one] : one \in Sample(8) }
        \cup { [ZeroAccumulatedValuesMessage EXCEPT !.tradesSellValue = one] : one \in Sample(8) }
        \cup { [ZeroAccumulatedValuesMessage EXCEPT !.tradesTotalValue = one] : one \in Sample(8) }
        \cup { [ZeroAccumulatedValuesMessage EXCEPT !.ordersBuyValue = one] : one \in Sample(8) }
        \cup { [ZeroAccumulatedValuesMessage EXCEPT !.ordersSellValue = one] : one \in Sample(8) }
        \cup { [ZeroAccumulatedValuesMessage EXCEPT !.ordersTotalValue = one] : one \in Sample(8) }

(***************************************************************************)
(* Sequenced Message, selected by Sequenced Message Type                   *)
(***************************************************************************)

AccountQueryResponseMessageCode == 81  \* "Q"
AccountSettingsResponseMessageCode == 67  \* "C"
OrderBookRestrictionResponseMessageCode == 82  \* "R"
MarketSegmentRestrictionResponseMessageCode == 83  \* "S"
LimitSettingsResponseMessageCode == 76  \* "L"
AccountCurrencySettingResponseMessageCode == 70  \* "F"
RejectMessageCode == 74  \* "J"
ApiPortRateBreachMessageCode == 80  \* "P"
AccountRateBreachMessageCode == 66  \* "B"
AccumulatedValuesMessageCode == 86  \* "V"

SequencedMessage ==
    [ tag : {AccountQueryResponseMessageCode}, body : AccountQueryResponseMessage ]
        \cup [ tag : {AccountSettingsResponseMessageCode}, body : AccountSettingsResponseMessage ]
        \cup [ tag : {OrderBookRestrictionResponseMessageCode}, body : OrderBookRestrictionResponseMessage ]
        \cup [ tag : {MarketSegmentRestrictionResponseMessageCode}, body : MarketSegmentRestrictionResponseMessage ]
        \cup [ tag : {LimitSettingsResponseMessageCode}, body : LimitSettingsResponseMessage ]
        \cup [ tag : {AccountCurrencySettingResponseMessageCode}, body : AccountCurrencySettingResponseMessage ]
        \cup [ tag : {RejectMessageCode}, body : RejectMessage ]
        \cup [ tag : {ApiPortRateBreachMessageCode}, body : ApiPortRateBreachMessage ]
        \cup [ tag : {AccountRateBreachMessageCode}, body : AccountRateBreachMessage ]
        \cup [ tag : {AccumulatedValuesMessageCode}, body : AccumulatedValuesMessage ]

EncodeSequencedMessage(message) ==
    CASE message.tag = AccountQueryResponseMessageCode -> EncodeAccountQueryResponseMessage(message.body)
      [] message.tag = AccountSettingsResponseMessageCode -> EncodeAccountSettingsResponseMessage(message.body)
      [] message.tag = OrderBookRestrictionResponseMessageCode -> EncodeOrderBookRestrictionResponseMessage(message.body)
      [] message.tag = MarketSegmentRestrictionResponseMessageCode -> EncodeMarketSegmentRestrictionResponseMessage(message.body)
      [] message.tag = LimitSettingsResponseMessageCode -> EncodeLimitSettingsResponseMessage(message.body)
      [] message.tag = AccountCurrencySettingResponseMessageCode -> EncodeAccountCurrencySettingResponseMessage(message.body)
      [] message.tag = RejectMessageCode -> EncodeRejectMessage(message.body)
      [] message.tag = ApiPortRateBreachMessageCode -> EncodeApiPortRateBreachMessage(message.body)
      [] message.tag = AccountRateBreachMessageCode -> EncodeAccountRateBreachMessage(message.body)
      [] message.tag = AccumulatedValuesMessageCode -> EncodeAccumulatedValuesMessage(message.body)

DecodeSequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = AccountQueryResponseMessageCode -> DecodeAccountQueryResponseMessage(bytes)
              [] tag = AccountSettingsResponseMessageCode -> DecodeAccountSettingsResponseMessage(bytes)
              [] tag = OrderBookRestrictionResponseMessageCode -> DecodeOrderBookRestrictionResponseMessage(bytes)
              [] tag = MarketSegmentRestrictionResponseMessageCode -> DecodeMarketSegmentRestrictionResponseMessage(bytes)
              [] tag = LimitSettingsResponseMessageCode -> DecodeLimitSettingsResponseMessage(bytes)
              [] tag = AccountCurrencySettingResponseMessageCode -> DecodeAccountCurrencySettingResponseMessage(bytes)
              [] tag = RejectMessageCode -> DecodeRejectMessage(bytes)
              [] tag = ApiPortRateBreachMessageCode -> DecodeApiPortRateBreachMessage(bytes)
              [] tag = AccountRateBreachMessageCode -> DecodeAccountRateBreachMessage(bytes)
              [] tag = AccumulatedValuesMessageCode -> DecodeAccumulatedValuesMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSequencedMessage == [tag |-> AccountQueryResponseMessageCode, body |-> ZeroAccountQueryResponseMessage]

(* Each Sequenced Message in turn, at the values the message it names is checked at *)
CheckedSequencedMessage ==
    { [tag |-> AccountQueryResponseMessageCode, body |-> one] : one \in CheckedAccountQueryResponseMessage }
        \cup { [tag |-> AccountSettingsResponseMessageCode, body |-> one] : one \in CheckedAccountSettingsResponseMessage }
        \cup { [tag |-> OrderBookRestrictionResponseMessageCode, body |-> one] : one \in CheckedOrderBookRestrictionResponseMessage }
        \cup { [tag |-> MarketSegmentRestrictionResponseMessageCode, body |-> one] : one \in CheckedMarketSegmentRestrictionResponseMessage }
        \cup { [tag |-> LimitSettingsResponseMessageCode, body |-> one] : one \in CheckedLimitSettingsResponseMessage }
        \cup { [tag |-> AccountCurrencySettingResponseMessageCode, body |-> one] : one \in CheckedAccountCurrencySettingResponseMessage }
        \cup { [tag |-> RejectMessageCode, body |-> one] : one \in CheckedRejectMessage }
        \cup { [tag |-> ApiPortRateBreachMessageCode, body |-> one] : one \in CheckedApiPortRateBreachMessage }
        \cup { [tag |-> AccountRateBreachMessageCode, body |-> one] : one \in CheckedAccountRateBreachMessage }
        \cup { [tag |-> AccumulatedValuesMessageCode, body |-> one] : one \in CheckedAccumulatedValuesMessage }

(***************************************************************************)
(* Sequenced Data Packet                                                   *)
(***************************************************************************)

SequencedDataPacket ==
    [ sequencedMessage : SequencedMessage ]

EncodeSequencedDataPacket(message) ==
    EncodeUIntBE(message.sequencedMessage.tag, 1)
        \o EncodeSequencedMessage(message.sequencedMessage)

DecodeSequencedDataPacket(bytes) ==
    LET sequencedMessageType == ReadUIntBE(bytes, 1) IN IF ~sequencedMessageType.ok THEN Fail ELSE
    LET sequencedMessage == DecodeSequencedMessage(sequencedMessageType.value, sequencedMessageType.rest) IN IF ~sequencedMessage.ok THEN Fail ELSE
    Ok([ sequencedMessage |-> sequencedMessage.value ], sequencedMessage.rest)

ZeroSequencedDataPacket ==
    [ sequencedMessage |-> ZeroSequencedMessage ]

(* Sequenced Data Packet at zero, then each field in turn at the values it is checked at *)
CheckedSequencedDataPacket ==
    { ZeroSequencedDataPacket }
        \cup { [ZeroSequencedDataPacket EXCEPT !.sequencedMessage = one] : one \in CheckedSequencedMessage }

(***************************************************************************)
(* Server Payload, selected by Server Packet Type                          *)
(***************************************************************************)

DebugPacketCode == 43  \* "+"
LoginAcceptedPacketCode == 65  \* "A"
LoginRejectedPacketCode == 74  \* "J"
SequencedDataPacketCode == 83  \* "S"
ServerHeartbeatCode == 72  \* "H"
EndOfSessionCode == 90  \* "Z"

ServerPayload ==
    [ tag : {DebugPacketCode}, body : DebugPacket ]
        \cup [ tag : {LoginAcceptedPacketCode}, body : LoginAcceptedPacket ]
        \cup [ tag : {LoginRejectedPacketCode}, body : LoginRejectedPacket ]
        \cup [ tag : {SequencedDataPacketCode}, body : SequencedDataPacket ]
        \cup [ tag : {ServerHeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {EndOfSessionCode}, body : {[empty |-> 0]} ]

EncodeServerPayload(message) ==
    CASE message.tag = DebugPacketCode -> EncodeDebugPacket(message.body)
      [] message.tag = LoginAcceptedPacketCode -> EncodeLoginAcceptedPacket(message.body)
      [] message.tag = LoginRejectedPacketCode -> EncodeLoginRejectedPacket(message.body)
      [] message.tag = SequencedDataPacketCode -> EncodeSequencedDataPacket(message.body)
      [] message.tag = ServerHeartbeatCode -> << >>
      [] message.tag = EndOfSessionCode -> << >>

DecodeServerPayload(tag, bytes) ==
    LET read ==
            CASE tag = DebugPacketCode -> DecodeDebugPacket(bytes)
              [] tag = LoginAcceptedPacketCode -> DecodeLoginAcceptedPacket(bytes)
              [] tag = LoginRejectedPacketCode -> DecodeLoginRejectedPacket(bytes)
              [] tag = SequencedDataPacketCode -> DecodeSequencedDataPacket(bytes)
              [] tag = ServerHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = EndOfSessionCode -> Ok([empty |-> 0], bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroServerPayload == [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]

(* Each Server Payload in turn, at the values the message it names is checked at *)
CheckedServerPayload ==
    { [tag |-> DebugPacketCode, body |-> one] : one \in CheckedDebugPacket }
        \cup { [tag |-> LoginAcceptedPacketCode, body |-> one] : one \in CheckedLoginAcceptedPacket }
        \cup { [tag |-> LoginRejectedPacketCode, body |-> one] : one \in CheckedLoginRejectedPacket }
        \cup { [tag |-> SequencedDataPacketCode, body |-> one] : one \in CheckedSequencedDataPacket }
        \cup { [tag |-> ServerHeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> EndOfSessionCode, body |-> [empty |-> 0]] }

(***************************************************************************)
(* Server Soup Bin Tcp Packet, framed by Packet Length                     *)
(***************************************************************************)

ServerSoupBinTcpPacket ==
    [ serverPayload : ServerPayload ]

EncodeServerSoupBinTcpPacketBody(message) ==
    EncodeUIntBE(message.serverPayload.tag, 1)
        \o EncodeServerPayload(message.serverPayload)

(* Packet Length counts the bytes it frames, so it is written from them *)
EncodeServerSoupBinTcpPacket(message) ==
    LET body == EncodeServerSoupBinTcpPacketBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeServerSoupBinTcpPacketBody(bytes) ==
    LET serverPacketType == ReadUIntBE(bytes, 1) IN IF ~serverPacketType.ok THEN Fail ELSE
    LET serverPayload == DecodeServerPayload(serverPacketType.value, serverPacketType.rest) IN IF ~serverPayload.ok THEN Fail ELSE
    Ok([ serverPayload |-> serverPayload.value ], serverPayload.rest)

DecodeServerSoupBinTcpPacket(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeServerSoupBinTcpPacketBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroServerSoupBinTcpPacket ==
    [ serverPayload |-> ZeroServerPayload ]

(* Server Soup Bin Tcp Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerSoupBinTcpPacket ==
    { ZeroServerSoupBinTcpPacket }
        \cup { [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = one] : one \in CheckedServerPayload }

(* A run of Server Soup Bin Tcp Packet, written one after another *)
RECURSIVE EncodeServerSoupBinTcpPacketList(_)
EncodeServerSoupBinTcpPacketList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeServerSoupBinTcpPacket(Head(messages)) \o EncodeServerSoupBinTcpPacketList(Tail(messages))

(* As many Server Soup Bin Tcp Packet as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadServerSoupBinTcpPacketAll(_)
ReadServerSoupBinTcpPacketAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeServerSoupBinTcpPacket(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadServerSoupBinTcpPacketAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Server Soup Bin Tcp Packet of each kind, for the lists that carry them *)
OneServerSoupBinTcpPacket ==
    { [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> LoginAcceptedPacketCode, body |-> ZeroLoginAcceptedPacket]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> LoginRejectedPacketCode, body |-> ZeroLoginRejectedPacket]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> SequencedDataPacketCode, body |-> ZeroSequencedDataPacket]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> ServerHeartbeatCode, body |-> [empty |-> 0]]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> EndOfSessionCode, body |-> [empty |-> 0]]] }

(***************************************************************************)
(* Server Packet                                                           *)
(***************************************************************************)

ServerPacket ==
    [ serverSoupBinTcpPacket : SampleLists(OneServerSoupBinTcpPacket) ]

EncodeServerPacket(message) ==
    EncodeServerSoupBinTcpPacketList(message.serverSoupBinTcpPacket)

DecodeServerPacket(bytes) ==
    LET serverSoupBinTcpPacket == ReadServerSoupBinTcpPacketAll(bytes) IN IF ~serverSoupBinTcpPacket.ok THEN Fail ELSE
    Ok([ serverSoupBinTcpPacket |-> serverSoupBinTcpPacket.value ], serverSoupBinTcpPacket.rest)

ZeroServerPacket ==
    [ serverSoupBinTcpPacket |-> << >> ]

(* Server Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerPacket ==
    { ZeroServerPacket }
        \cup { [ZeroServerPacket EXCEPT !.serverSoupBinTcpPacket = one] : one \in SampleLists(OneServerSoupBinTcpPacket) }

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

(* Every Debug Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripDebugPacket ==
    \A message \in CheckedDebugPacket :
        LET read == DecodeDebugPacket(EncodeDebugPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Accepted Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginAcceptedPacket ==
    \A message \in CheckedLoginAcceptedPacket :
        LET read == DecodeLoginAcceptedPacket(EncodeLoginAcceptedPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Rejected Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRejectedPacket ==
    \A message \in CheckedLoginRejectedPacket :
        LET read == DecodeLoginRejectedPacket(EncodeLoginRejectedPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Account Query Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAccountQueryResponseMessage ==
    \A message \in CheckedAccountQueryResponseMessage :
        LET read == DecodeAccountQueryResponseMessage(EncodeAccountQueryResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Account Settings Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAccountSettingsResponseMessage ==
    \A message \in CheckedAccountSettingsResponseMessage :
        LET read == DecodeAccountSettingsResponseMessage(EncodeAccountSettingsResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Book Restriction Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderBookRestrictionResponseMessage ==
    \A message \in CheckedOrderBookRestrictionResponseMessage :
        LET read == DecodeOrderBookRestrictionResponseMessage(EncodeOrderBookRestrictionResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Segment Restriction Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketSegmentRestrictionResponseMessage ==
    \A message \in CheckedMarketSegmentRestrictionResponseMessage :
        LET read == DecodeMarketSegmentRestrictionResponseMessage(EncodeMarketSegmentRestrictionResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Limit Settings Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLimitSettingsResponseMessage ==
    \A message \in CheckedLimitSettingsResponseMessage :
        LET read == DecodeLimitSettingsResponseMessage(EncodeLimitSettingsResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Account Currency Setting Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAccountCurrencySettingResponseMessage ==
    \A message \in CheckedAccountCurrencySettingResponseMessage :
        LET read == DecodeAccountCurrencySettingResponseMessage(EncodeAccountCurrencySettingResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRejectMessage ==
    \A message \in CheckedRejectMessage :
        LET read == DecodeRejectMessage(EncodeRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Api Port Rate Breach Message decodes back to what was encoded, and leaves nothing over *)
RoundTripApiPortRateBreachMessage ==
    \A message \in CheckedApiPortRateBreachMessage :
        LET read == DecodeApiPortRateBreachMessage(EncodeApiPortRateBreachMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Account Rate Breach Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAccountRateBreachMessage ==
    \A message \in CheckedAccountRateBreachMessage :
        LET read == DecodeAccountRateBreachMessage(EncodeAccountRateBreachMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Accumulated Values Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAccumulatedValuesMessage ==
    \A message \in CheckedAccumulatedValuesMessage :
        LET read == DecodeAccumulatedValuesMessage(EncodeAccumulatedValuesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sequenced Data Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripSequencedDataPacket ==
    \A message \in CheckedSequencedDataPacket :
        LET read == DecodeSequencedDataPacket(EncodeSequencedDataPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Server Soup Bin Tcp Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripServerSoupBinTcpPacket ==
    \A message \in CheckedServerSoupBinTcpPacket :
        LET read == DecodeServerSoupBinTcpPacket(EncodeServerSoupBinTcpPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Server Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripServerPacket ==
    \A message \in CheckedServerPacket :
        LET read == DecodeServerPacket(EncodeServerPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Sequenced Message is selected by the Sequenced Message Type it is written under *)
SelectsSequencedMessage ==
    \A message \in CheckedSequencedMessage :
        LET read == DecodeSequencedMessage(message.tag, EncodeSequencedMessage(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Server Payload is selected by the Server Packet Type it is written under *)
SelectsServerPayload ==
    \A message \in CheckedServerPayload :
        LET read == DecodeServerPayload(message.tag, EncodeServerPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Packet Length is written from the bytes it frames *)
FramesServerSoupBinTcpPacket ==
    \A message \in CheckedServerSoupBinTcpPacket :
        LET bytes == EncodeServerSoupBinTcpPacket(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
