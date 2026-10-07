------------- MODULE NordicEquities_RiskControl_v1_00_1_Client -------------
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
(* Note: Unsequenced Data Packet fills what is left of the frame Packet    *)
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
(* Debug Packet                                                            *)
(***************************************************************************)

DebugPacket ==
    [ debugText : SampleBytes ]

EncodeDebugPacket(message) ==
    message.debugText

DecodeDebugPacket(bytes) ==
    LET debugText == Ok(bytes, << >>) IN IF ~debugText.ok THEN Fail ELSE
    Ok([ debugText |-> debugText.value ], debugText.rest)

ZeroDebugPacket ==
    [ debugText |-> << >> ]

(* Debug Packet at zero, then each field in turn at the values it is checked at *)
CheckedDebugPacket ==
    { ZeroDebugPacket }
        \cup { [ZeroDebugPacket EXCEPT !.debugText = one] : one \in SampleBytes }

(***************************************************************************)
(* Login Request Packet: 46 bytes                                          *)
(***************************************************************************)

LoginRequestPacket ==
    [ username                : Sample(6),
      password                : Sample(10),
      requestedSession        : Sample(10),
      requestedSequenceNumber : Sample(20) ]

EncodeLoginRequestPacket(message) ==
    message.username
        \o message.password
        \o message.requestedSession
        \o message.requestedSequenceNumber

DecodeLoginRequestPacket(bytes) ==
    LET username == ReadBytes(bytes, 6) IN IF ~username.ok THEN Fail ELSE
    LET password == ReadBytes(username.rest, 10) IN IF ~password.ok THEN Fail ELSE
    LET requestedSession == ReadBytes(password.rest, 10) IN IF ~requestedSession.ok THEN Fail ELSE
    LET requestedSequenceNumber == ReadBytes(requestedSession.rest, 20) IN IF ~requestedSequenceNumber.ok THEN Fail ELSE
    Ok([ username                |-> username.value,
         password                |-> password.value,
         requestedSession        |-> requestedSession.value,
         requestedSequenceNumber |-> requestedSequenceNumber.value ], requestedSequenceNumber.rest)

ZeroLoginRequestPacket ==
    [ username                |-> [i \in 1 .. 6 |-> 0],
      password                |-> [i \in 1 .. 10 |-> 0],
      requestedSession        |-> [i \in 1 .. 10 |-> 0],
      requestedSequenceNumber |-> [i \in 1 .. 20 |-> 0] ]

(* Login Request Packet at zero, then each field in turn at the values it is checked at *)
CheckedLoginRequestPacket ==
    { ZeroLoginRequestPacket }
        \cup { [ZeroLoginRequestPacket EXCEPT !.username = one] : one \in Sample(6) }
        \cup { [ZeroLoginRequestPacket EXCEPT !.password = one] : one \in Sample(10) }
        \cup { [ZeroLoginRequestPacket EXCEPT !.requestedSession = one] : one \in Sample(10) }
        \cup { [ZeroLoginRequestPacket EXCEPT !.requestedSequenceNumber = one] : one \in Sample(20) }

(***************************************************************************)
(* Modify Account Settings Message: 19 bytes                               *)
(***************************************************************************)

ModifyAccountSettingsMessage ==
    [ userRefNum                                     : Sample(4),
      prmAccount                                     : Sample(6),
      repeatedOrderGeneration                        : Sample(4),
      triggerRestrictSymbolOnRepeatedOrderGeneration : Sample(1),
      inAuctionMarketOrderPrevention                 : Sample(1),
      inAuctionFatFingerProtection                   : Sample(1),
      inAuctionMarketOrderProtection                 : Sample(1),
      blockAndCancel                                 : Sample(1) ]

EncodeModifyAccountSettingsMessage(message) ==
    message.userRefNum
        \o message.prmAccount
        \o message.repeatedOrderGeneration
        \o message.triggerRestrictSymbolOnRepeatedOrderGeneration
        \o message.inAuctionMarketOrderPrevention
        \o message.inAuctionFatFingerProtection
        \o message.inAuctionMarketOrderProtection
        \o message.blockAndCancel

DecodeModifyAccountSettingsMessage(bytes) ==
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

ZeroModifyAccountSettingsMessage ==
    [ userRefNum                                     |-> [i \in 1 .. 4 |-> 0],
      prmAccount                                     |-> [i \in 1 .. 6 |-> 0],
      repeatedOrderGeneration                        |-> [i \in 1 .. 4 |-> 0],
      triggerRestrictSymbolOnRepeatedOrderGeneration |-> [i \in 1 .. 1 |-> 0],
      inAuctionMarketOrderPrevention                 |-> [i \in 1 .. 1 |-> 0],
      inAuctionFatFingerProtection                   |-> [i \in 1 .. 1 |-> 0],
      inAuctionMarketOrderProtection                 |-> [i \in 1 .. 1 |-> 0],
      blockAndCancel                                 |-> [i \in 1 .. 1 |-> 0] ]

(* Modify Account Settings Message at zero, then each field in turn at the values it is checked at *)
CheckedModifyAccountSettingsMessage ==
    { ZeroModifyAccountSettingsMessage }
        \cup { [ZeroModifyAccountSettingsMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroModifyAccountSettingsMessage EXCEPT !.prmAccount = one] : one \in Sample(6) }
        \cup { [ZeroModifyAccountSettingsMessage EXCEPT !.repeatedOrderGeneration = one] : one \in Sample(4) }
        \cup { [ZeroModifyAccountSettingsMessage EXCEPT !.triggerRestrictSymbolOnRepeatedOrderGeneration = one] : one \in Sample(1) }
        \cup { [ZeroModifyAccountSettingsMessage EXCEPT !.inAuctionMarketOrderPrevention = one] : one \in Sample(1) }
        \cup { [ZeroModifyAccountSettingsMessage EXCEPT !.inAuctionFatFingerProtection = one] : one \in Sample(1) }
        \cup { [ZeroModifyAccountSettingsMessage EXCEPT !.inAuctionMarketOrderProtection = one] : one \in Sample(1) }
        \cup { [ZeroModifyAccountSettingsMessage EXCEPT !.blockAndCancel = one] : one \in Sample(1) }

(***************************************************************************)
(* Modify Order Book Restriction Message: 15 bytes                         *)
(***************************************************************************)

ModifyOrderBookRestrictionMessage ==
    [ userRefNum : Sample(4),
      prmAccount : Sample(6),
      orderBook  : Sample(4),
      state      : Sample(1) ]

EncodeModifyOrderBookRestrictionMessage(message) ==
    message.userRefNum
        \o message.prmAccount
        \o message.orderBook
        \o message.state

DecodeModifyOrderBookRestrictionMessage(bytes) ==
    LET userRefNum == ReadBytes(bytes, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET prmAccount == ReadBytes(userRefNum.rest, 6) IN IF ~prmAccount.ok THEN Fail ELSE
    LET orderBook == ReadBytes(prmAccount.rest, 4) IN IF ~orderBook.ok THEN Fail ELSE
    LET state == ReadBytes(orderBook.rest, 1) IN IF ~state.ok THEN Fail ELSE
    Ok([ userRefNum |-> userRefNum.value,
         prmAccount |-> prmAccount.value,
         orderBook  |-> orderBook.value,
         state      |-> state.value ], state.rest)

ZeroModifyOrderBookRestrictionMessage ==
    [ userRefNum |-> [i \in 1 .. 4 |-> 0],
      prmAccount |-> [i \in 1 .. 6 |-> 0],
      orderBook  |-> [i \in 1 .. 4 |-> 0],
      state      |-> [i \in 1 .. 1 |-> 0] ]

(* Modify Order Book Restriction Message at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderBookRestrictionMessage ==
    { ZeroModifyOrderBookRestrictionMessage }
        \cup { [ZeroModifyOrderBookRestrictionMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderBookRestrictionMessage EXCEPT !.prmAccount = one] : one \in Sample(6) }
        \cup { [ZeroModifyOrderBookRestrictionMessage EXCEPT !.orderBook = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderBookRestrictionMessage EXCEPT !.state = one] : one \in Sample(1) }

(***************************************************************************)
(* Modify Market Segment Restriction Message: 13 bytes                     *)
(***************************************************************************)

ModifyMarketSegmentRestrictionMessage ==
    [ userRefNum    : Sample(4),
      prmAccount    : Sample(6),
      marketSegment : Sample(2),
      state         : Sample(1) ]

EncodeModifyMarketSegmentRestrictionMessage(message) ==
    message.userRefNum
        \o message.prmAccount
        \o message.marketSegment
        \o message.state

DecodeModifyMarketSegmentRestrictionMessage(bytes) ==
    LET userRefNum == ReadBytes(bytes, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET prmAccount == ReadBytes(userRefNum.rest, 6) IN IF ~prmAccount.ok THEN Fail ELSE
    LET marketSegment == ReadBytes(prmAccount.rest, 2) IN IF ~marketSegment.ok THEN Fail ELSE
    LET state == ReadBytes(marketSegment.rest, 1) IN IF ~state.ok THEN Fail ELSE
    Ok([ userRefNum    |-> userRefNum.value,
         prmAccount    |-> prmAccount.value,
         marketSegment |-> marketSegment.value,
         state         |-> state.value ], state.rest)

ZeroModifyMarketSegmentRestrictionMessage ==
    [ userRefNum    |-> [i \in 1 .. 4 |-> 0],
      prmAccount    |-> [i \in 1 .. 6 |-> 0],
      marketSegment |-> [i \in 1 .. 2 |-> 0],
      state         |-> [i \in 1 .. 1 |-> 0] ]

(* Modify Market Segment Restriction Message at zero, then each field in turn at the values it is checked at *)
CheckedModifyMarketSegmentRestrictionMessage ==
    { ZeroModifyMarketSegmentRestrictionMessage }
        \cup { [ZeroModifyMarketSegmentRestrictionMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroModifyMarketSegmentRestrictionMessage EXCEPT !.prmAccount = one] : one \in Sample(6) }
        \cup { [ZeroModifyMarketSegmentRestrictionMessage EXCEPT !.marketSegment = one] : one \in Sample(2) }
        \cup { [ZeroModifyMarketSegmentRestrictionMessage EXCEPT !.state = one] : one \in Sample(1) }

(***************************************************************************)
(* Modify Limit Settings Message: 109 bytes                                *)
(***************************************************************************)

ModifyLimitSettingsMessage ==
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

EncodeModifyLimitSettingsMessage(message) ==
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

DecodeModifyLimitSettingsMessage(bytes) ==
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

ZeroModifyLimitSettingsMessage ==
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

(* Modify Limit Settings Message at zero, then each field in turn at the values it is checked at *)
CheckedModifyLimitSettingsMessage ==
    { ZeroModifyLimitSettingsMessage }
        \cup { [ZeroModifyLimitSettingsMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroModifyLimitSettingsMessage EXCEPT !.prmAccount = one] : one \in Sample(6) }
        \cup { [ZeroModifyLimitSettingsMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroModifyLimitSettingsMessage EXCEPT !.maxQuantity = one] : one \in Sample(8) }
        \cup { [ZeroModifyLimitSettingsMessage EXCEPT !.maxValue = one] : one \in Sample(8) }
        \cup { [ZeroModifyLimitSettingsMessage EXCEPT !.unused = one] : one \in Sample(8) }
        \cup { [ZeroModifyLimitSettingsMessage EXCEPT !.totalRiskValue = one] : one \in Sample(8) }
        \cup { [ZeroModifyLimitSettingsMessage EXCEPT !.tradeBuyValue = one] : one \in Sample(8) }
        \cup { [ZeroModifyLimitSettingsMessage EXCEPT !.tradeSellValue = one] : one \in Sample(8) }
        \cup { [ZeroModifyLimitSettingsMessage EXCEPT !.tradeNetValue = one] : one \in Sample(8) }
        \cup { [ZeroModifyLimitSettingsMessage EXCEPT !.openOrderBuyValue = one] : one \in Sample(8) }
        \cup { [ZeroModifyLimitSettingsMessage EXCEPT !.openOrderSellValue = one] : one \in Sample(8) }
        \cup { [ZeroModifyLimitSettingsMessage EXCEPT !.openOrderNetValue = one] : one \in Sample(8) }
        \cup { [ZeroModifyLimitSettingsMessage EXCEPT !.maxQuantityAuction = one] : one \in Sample(8) }
        \cup { [ZeroModifyLimitSettingsMessage EXCEPT !.maxValueAuction = one] : one \in Sample(8) }

(***************************************************************************)
(* Modify Account Currency Setting Message: 15 bytes                       *)
(***************************************************************************)

ModifyAccountCurrencySettingMessage ==
    [ userRefNum            : Sample(4),
      prmAccount            : Sample(6),
      currency              : Sample(3),
      rejectAllFlag         : Sample(1),
      blowThroughProtection : Sample(1) ]

EncodeModifyAccountCurrencySettingMessage(message) ==
    message.userRefNum
        \o message.prmAccount
        \o message.currency
        \o message.rejectAllFlag
        \o message.blowThroughProtection

DecodeModifyAccountCurrencySettingMessage(bytes) ==
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

ZeroModifyAccountCurrencySettingMessage ==
    [ userRefNum            |-> [i \in 1 .. 4 |-> 0],
      prmAccount            |-> [i \in 1 .. 6 |-> 0],
      currency              |-> [i \in 1 .. 3 |-> 0],
      rejectAllFlag         |-> [i \in 1 .. 1 |-> 0],
      blowThroughProtection |-> [i \in 1 .. 1 |-> 0] ]

(* Modify Account Currency Setting Message at zero, then each field in turn at the values it is checked at *)
CheckedModifyAccountCurrencySettingMessage ==
    { ZeroModifyAccountCurrencySettingMessage }
        \cup { [ZeroModifyAccountCurrencySettingMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroModifyAccountCurrencySettingMessage EXCEPT !.prmAccount = one] : one \in Sample(6) }
        \cup { [ZeroModifyAccountCurrencySettingMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroModifyAccountCurrencySettingMessage EXCEPT !.rejectAllFlag = one] : one \in Sample(1) }
        \cup { [ZeroModifyAccountCurrencySettingMessage EXCEPT !.blowThroughProtection = one] : one \in Sample(1) }

(***************************************************************************)
(* Unsequenced Message, selected by Unsequenced Message Type               *)
(***************************************************************************)

AccountQueryMessageCode == 81  \* "Q"
ModifyAccountSettingsMessageCode == 67  \* "C"
ModifyOrderBookRestrictionMessageCode == 82  \* "R"
ModifyMarketSegmentRestrictionMessageCode == 83  \* "S"
ModifyLimitSettingsMessageCode == 76  \* "L"
ModifyAccountCurrencySettingMessageCode == 70  \* "F"

UnsequencedMessage ==
    [ tag : {AccountQueryMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ModifyAccountSettingsMessageCode}, body : ModifyAccountSettingsMessage ]
        \cup [ tag : {ModifyOrderBookRestrictionMessageCode}, body : ModifyOrderBookRestrictionMessage ]
        \cup [ tag : {ModifyMarketSegmentRestrictionMessageCode}, body : ModifyMarketSegmentRestrictionMessage ]
        \cup [ tag : {ModifyLimitSettingsMessageCode}, body : ModifyLimitSettingsMessage ]
        \cup [ tag : {ModifyAccountCurrencySettingMessageCode}, body : ModifyAccountCurrencySettingMessage ]

EncodeUnsequencedMessage(message) ==
    CASE message.tag = AccountQueryMessageCode -> << >>
      [] message.tag = ModifyAccountSettingsMessageCode -> EncodeModifyAccountSettingsMessage(message.body)
      [] message.tag = ModifyOrderBookRestrictionMessageCode -> EncodeModifyOrderBookRestrictionMessage(message.body)
      [] message.tag = ModifyMarketSegmentRestrictionMessageCode -> EncodeModifyMarketSegmentRestrictionMessage(message.body)
      [] message.tag = ModifyLimitSettingsMessageCode -> EncodeModifyLimitSettingsMessage(message.body)
      [] message.tag = ModifyAccountCurrencySettingMessageCode -> EncodeModifyAccountCurrencySettingMessage(message.body)

DecodeUnsequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = AccountQueryMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = ModifyAccountSettingsMessageCode -> DecodeModifyAccountSettingsMessage(bytes)
              [] tag = ModifyOrderBookRestrictionMessageCode -> DecodeModifyOrderBookRestrictionMessage(bytes)
              [] tag = ModifyMarketSegmentRestrictionMessageCode -> DecodeModifyMarketSegmentRestrictionMessage(bytes)
              [] tag = ModifyLimitSettingsMessageCode -> DecodeModifyLimitSettingsMessage(bytes)
              [] tag = ModifyAccountCurrencySettingMessageCode -> DecodeModifyAccountCurrencySettingMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroUnsequencedMessage == [tag |-> AccountQueryMessageCode, body |-> [empty |-> 0]]

(* Each Unsequenced Message in turn, at the values the message it names is checked at *)
CheckedUnsequencedMessage ==
    { [tag |-> AccountQueryMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> ModifyAccountSettingsMessageCode, body |-> one] : one \in CheckedModifyAccountSettingsMessage }
        \cup { [tag |-> ModifyOrderBookRestrictionMessageCode, body |-> one] : one \in CheckedModifyOrderBookRestrictionMessage }
        \cup { [tag |-> ModifyMarketSegmentRestrictionMessageCode, body |-> one] : one \in CheckedModifyMarketSegmentRestrictionMessage }
        \cup { [tag |-> ModifyLimitSettingsMessageCode, body |-> one] : one \in CheckedModifyLimitSettingsMessage }
        \cup { [tag |-> ModifyAccountCurrencySettingMessageCode, body |-> one] : one \in CheckedModifyAccountCurrencySettingMessage }

(***************************************************************************)
(* Unsequenced Data Packet                                                 *)
(***************************************************************************)

UnsequencedDataPacket ==
    [ unsequencedMessage : UnsequencedMessage ]

EncodeUnsequencedDataPacket(message) ==
    EncodeUIntBE(message.unsequencedMessage.tag, 1)
        \o EncodeUnsequencedMessage(message.unsequencedMessage)

DecodeUnsequencedDataPacket(bytes) ==
    LET unsequencedMessageType == ReadUIntBE(bytes, 1) IN IF ~unsequencedMessageType.ok THEN Fail ELSE
    LET unsequencedMessage == DecodeUnsequencedMessage(unsequencedMessageType.value, unsequencedMessageType.rest) IN IF ~unsequencedMessage.ok THEN Fail ELSE
    Ok([ unsequencedMessage |-> unsequencedMessage.value ], unsequencedMessage.rest)

ZeroUnsequencedDataPacket ==
    [ unsequencedMessage |-> ZeroUnsequencedMessage ]

(* Unsequenced Data Packet at zero, then each field in turn at the values it is checked at *)
CheckedUnsequencedDataPacket ==
    { ZeroUnsequencedDataPacket }
        \cup { [ZeroUnsequencedDataPacket EXCEPT !.unsequencedMessage = one] : one \in CheckedUnsequencedMessage }

(***************************************************************************)
(* Client Payload, selected by Client Packet Type                          *)
(***************************************************************************)

DebugPacketCode == 43  \* "+"
LoginRequestPacketCode == 76  \* "L"
UnsequencedDataPacketCode == 85  \* "U"
ClientHeartbeatCode == 82  \* "R"
LogoutRequestCode == 79  \* "O"

ClientPayload ==
    [ tag : {DebugPacketCode}, body : DebugPacket ]
        \cup [ tag : {LoginRequestPacketCode}, body : LoginRequestPacket ]
        \cup [ tag : {UnsequencedDataPacketCode}, body : UnsequencedDataPacket ]
        \cup [ tag : {ClientHeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {LogoutRequestCode}, body : {[empty |-> 0]} ]

EncodeClientPayload(message) ==
    CASE message.tag = DebugPacketCode -> EncodeDebugPacket(message.body)
      [] message.tag = LoginRequestPacketCode -> EncodeLoginRequestPacket(message.body)
      [] message.tag = UnsequencedDataPacketCode -> EncodeUnsequencedDataPacket(message.body)
      [] message.tag = ClientHeartbeatCode -> << >>
      [] message.tag = LogoutRequestCode -> << >>

DecodeClientPayload(tag, bytes) ==
    LET read ==
            CASE tag = DebugPacketCode -> DecodeDebugPacket(bytes)
              [] tag = LoginRequestPacketCode -> DecodeLoginRequestPacket(bytes)
              [] tag = UnsequencedDataPacketCode -> DecodeUnsequencedDataPacket(bytes)
              [] tag = ClientHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = LogoutRequestCode -> Ok([empty |-> 0], bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroClientPayload == [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]

(* Each Client Payload in turn, at the values the message it names is checked at *)
CheckedClientPayload ==
    { [tag |-> DebugPacketCode, body |-> one] : one \in CheckedDebugPacket }
        \cup { [tag |-> LoginRequestPacketCode, body |-> one] : one \in CheckedLoginRequestPacket }
        \cup { [tag |-> UnsequencedDataPacketCode, body |-> one] : one \in CheckedUnsequencedDataPacket }
        \cup { [tag |-> ClientHeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> LogoutRequestCode, body |-> [empty |-> 0]] }

(***************************************************************************)
(* Client Soup Bin Tcp Packet, framed by Packet Length                     *)
(***************************************************************************)

ClientSoupBinTcpPacket ==
    [ clientPayload : ClientPayload ]

EncodeClientSoupBinTcpPacketBody(message) ==
    EncodeUIntBE(message.clientPayload.tag, 1)
        \o EncodeClientPayload(message.clientPayload)

(* Packet Length counts the bytes it frames, so it is written from them *)
EncodeClientSoupBinTcpPacket(message) ==
    LET body == EncodeClientSoupBinTcpPacketBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeClientSoupBinTcpPacketBody(bytes) ==
    LET clientPacketType == ReadUIntBE(bytes, 1) IN IF ~clientPacketType.ok THEN Fail ELSE
    LET clientPayload == DecodeClientPayload(clientPacketType.value, clientPacketType.rest) IN IF ~clientPayload.ok THEN Fail ELSE
    Ok([ clientPayload |-> clientPayload.value ], clientPayload.rest)

DecodeClientSoupBinTcpPacket(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeClientSoupBinTcpPacketBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroClientSoupBinTcpPacket ==
    [ clientPayload |-> ZeroClientPayload ]

(* Client Soup Bin Tcp Packet at zero, then each field in turn at the values it is checked at *)
CheckedClientSoupBinTcpPacket ==
    { ZeroClientSoupBinTcpPacket }
        \cup { [ZeroClientSoupBinTcpPacket EXCEPT !.clientPayload = one] : one \in CheckedClientPayload }

(* A run of Client Soup Bin Tcp Packet, written one after another *)
RECURSIVE EncodeClientSoupBinTcpPacketList(_)
EncodeClientSoupBinTcpPacketList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeClientSoupBinTcpPacket(Head(messages)) \o EncodeClientSoupBinTcpPacketList(Tail(messages))

(* As many Client Soup Bin Tcp Packet as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadClientSoupBinTcpPacketAll(_)
ReadClientSoupBinTcpPacketAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeClientSoupBinTcpPacket(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadClientSoupBinTcpPacketAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Client Soup Bin Tcp Packet of each kind, for the lists that carry them *)
OneClientSoupBinTcpPacket ==
    { [ZeroClientSoupBinTcpPacket EXCEPT !.clientPayload = [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]],
      [ZeroClientSoupBinTcpPacket EXCEPT !.clientPayload = [tag |-> LoginRequestPacketCode, body |-> ZeroLoginRequestPacket]],
      [ZeroClientSoupBinTcpPacket EXCEPT !.clientPayload = [tag |-> UnsequencedDataPacketCode, body |-> ZeroUnsequencedDataPacket]],
      [ZeroClientSoupBinTcpPacket EXCEPT !.clientPayload = [tag |-> ClientHeartbeatCode, body |-> [empty |-> 0]]],
      [ZeroClientSoupBinTcpPacket EXCEPT !.clientPayload = [tag |-> LogoutRequestCode, body |-> [empty |-> 0]]] }

(***************************************************************************)
(* Client Packet                                                           *)
(***************************************************************************)

ClientPacket ==
    [ clientSoupBinTcpPacket : SampleLists(OneClientSoupBinTcpPacket) ]

EncodeClientPacket(message) ==
    EncodeClientSoupBinTcpPacketList(message.clientSoupBinTcpPacket)

DecodeClientPacket(bytes) ==
    LET clientSoupBinTcpPacket == ReadClientSoupBinTcpPacketAll(bytes) IN IF ~clientSoupBinTcpPacket.ok THEN Fail ELSE
    Ok([ clientSoupBinTcpPacket |-> clientSoupBinTcpPacket.value ], clientSoupBinTcpPacket.rest)

ZeroClientPacket ==
    [ clientSoupBinTcpPacket |-> << >> ]

(* Client Packet at zero, then each field in turn at the values it is checked at *)
CheckedClientPacket ==
    { ZeroClientPacket }
        \cup { [ZeroClientPacket EXCEPT !.clientSoupBinTcpPacket = one] : one \in SampleLists(OneClientSoupBinTcpPacket) }

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

(* Every Login Request Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRequestPacket ==
    \A message \in CheckedLoginRequestPacket :
        LET read == DecodeLoginRequestPacket(EncodeLoginRequestPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Account Settings Message decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyAccountSettingsMessage ==
    \A message \in CheckedModifyAccountSettingsMessage :
        LET read == DecodeModifyAccountSettingsMessage(EncodeModifyAccountSettingsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Order Book Restriction Message decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyOrderBookRestrictionMessage ==
    \A message \in CheckedModifyOrderBookRestrictionMessage :
        LET read == DecodeModifyOrderBookRestrictionMessage(EncodeModifyOrderBookRestrictionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Market Segment Restriction Message decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyMarketSegmentRestrictionMessage ==
    \A message \in CheckedModifyMarketSegmentRestrictionMessage :
        LET read == DecodeModifyMarketSegmentRestrictionMessage(EncodeModifyMarketSegmentRestrictionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Limit Settings Message decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyLimitSettingsMessage ==
    \A message \in CheckedModifyLimitSettingsMessage :
        LET read == DecodeModifyLimitSettingsMessage(EncodeModifyLimitSettingsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Account Currency Setting Message decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyAccountCurrencySettingMessage ==
    \A message \in CheckedModifyAccountCurrencySettingMessage :
        LET read == DecodeModifyAccountCurrencySettingMessage(EncodeModifyAccountCurrencySettingMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Unsequenced Data Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripUnsequencedDataPacket ==
    \A message \in CheckedUnsequencedDataPacket :
        LET read == DecodeUnsequencedDataPacket(EncodeUnsequencedDataPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client Soup Bin Tcp Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripClientSoupBinTcpPacket ==
    \A message \in CheckedClientSoupBinTcpPacket :
        LET read == DecodeClientSoupBinTcpPacket(EncodeClientSoupBinTcpPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripClientPacket ==
    \A message \in CheckedClientPacket :
        LET read == DecodeClientPacket(EncodeClientPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Unsequenced Message is selected by the Unsequenced Message Type it is written under *)
SelectsUnsequencedMessage ==
    \A message \in CheckedUnsequencedMessage :
        LET read == DecodeUnsequencedMessage(message.tag, EncodeUnsequencedMessage(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Client Payload is selected by the Client Packet Type it is written under *)
SelectsClientPayload ==
    \A message \in CheckedClientPayload :
        LET read == DecodeClientPayload(message.tag, EncodeClientPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Packet Length is written from the bytes it frames *)
FramesClientSoupBinTcpPacket ==
    \A message \in CheckedClientSoupBinTcpPacket :
        LET bytes == EncodeClientSoupBinTcpPacket(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
