------------- MODULE CfeFutures_BinaryOrderEntry_v1_0_Exchange -------------
(***************************************************************************)
(* Chicago Board Options Exchange Futures Binary Order Entry v1.0          *)
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
(* Unit Sequence: 5 bytes                                                  *)
(***************************************************************************)

UnitSequence ==
    [ unitNumber     : Sample(1),
      sequenceNumber : Sample(4) ]

EncodeUnitSequence(message) ==
    message.unitNumber
        \o message.sequenceNumber

DecodeUnitSequence(bytes) ==
    LET unitNumber == ReadBytes(bytes, 1) IN IF ~unitNumber.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(unitNumber.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    Ok([ unitNumber     |-> unitNumber.value,
         sequenceNumber |-> sequenceNumber.value ], sequenceNumber.rest)

ZeroUnitSequence ==
    [ unitNumber     |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber |-> [i \in 1 .. 4 |-> 0] ]

(* Unit Sequence at zero, then each field in turn at the values it is checked at *)
CheckedUnitSequence ==
    { ZeroUnitSequence }
        \cup { [ZeroUnitSequence EXCEPT !.unitNumber = one] : one \in Sample(1) }
        \cup { [ZeroUnitSequence EXCEPT !.sequenceNumber = one] : one \in Sample(4) }

(* A run of Unit Sequence, written one after another *)
RECURSIVE EncodeUnitSequenceList(_)
EncodeUnitSequenceList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeUnitSequence(Head(messages)) \o EncodeUnitSequenceList(Tail(messages))

(* As many Unit Sequence as the field that counts them says *)
RECURSIVE ReadUnitSequenceList(_, _)
ReadUnitSequenceList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeUnitSequence(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadUnitSequenceList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Unit Sequence of each kind, for the lists that carry them *)
OneUnitSequence == { ZeroUnitSequence }

(***************************************************************************)
(* Login Response Message                                                  *)
(***************************************************************************)

LoginResponseMessage ==
    [ loginResponseStatus : Sample(1),
      loginResponseText   : Sample(60),
      clientSequence      : Sample(4),
      unitSequence        : SampleLists(OneUnitSequence) ]

EncodeLoginResponseMessage(message) ==
    message.loginResponseStatus
        \o message.loginResponseText
        \o message.clientSequence
        \o EncodeUIntLE(Len(message.unitSequence), 1)
        \o EncodeUnitSequenceList(message.unitSequence)

DecodeLoginResponseMessage(bytes) ==
    LET loginResponseStatus == ReadBytes(bytes, 1) IN IF ~loginResponseStatus.ok THEN Fail ELSE
    LET loginResponseText == ReadBytes(loginResponseStatus.rest, 60) IN IF ~loginResponseText.ok THEN Fail ELSE
    LET clientSequence == ReadBytes(loginResponseText.rest, 4) IN IF ~clientSequence.ok THEN Fail ELSE
    LET numberOfUnits == ReadUIntLE(clientSequence.rest, 1) IN IF ~numberOfUnits.ok THEN Fail ELSE
    LET unitSequence == ReadUnitSequenceList(numberOfUnits.rest, numberOfUnits.value) IN IF ~unitSequence.ok THEN Fail ELSE
    Ok([ loginResponseStatus |-> loginResponseStatus.value,
         loginResponseText   |-> loginResponseText.value,
         clientSequence      |-> clientSequence.value,
         unitSequence        |-> unitSequence.value ], unitSequence.rest)

ZeroLoginResponseMessage ==
    [ loginResponseStatus |-> [i \in 1 .. 1 |-> 0],
      loginResponseText   |-> [i \in 1 .. 60 |-> 0],
      clientSequence      |-> [i \in 1 .. 4 |-> 0],
      unitSequence        |-> << >> ]

(* Login Response Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginResponseMessage ==
    { ZeroLoginResponseMessage }
        \cup { [ZeroLoginResponseMessage EXCEPT !.loginResponseStatus = one] : one \in Sample(1) }
        \cup { [ZeroLoginResponseMessage EXCEPT !.loginResponseText = one] : one \in Sample(60) }
        \cup { [ZeroLoginResponseMessage EXCEPT !.clientSequence = one] : one \in Sample(4) }
        \cup { [ZeroLoginResponseMessage EXCEPT !.unitSequence = one] : one \in SampleLists(OneUnitSequence) }

(***************************************************************************)
(* Logout Response Message: 61 bytes                                       *)
(***************************************************************************)

LogoutResponseMessage ==
    [ logoutReason     : Sample(1),
      logoutReasonText : Sample(60) ]

EncodeLogoutResponseMessage(message) ==
    message.logoutReason
        \o message.logoutReasonText

DecodeLogoutResponseMessage(bytes) ==
    LET logoutReason == ReadBytes(bytes, 1) IN IF ~logoutReason.ok THEN Fail ELSE
    LET logoutReasonText == ReadBytes(logoutReason.rest, 60) IN IF ~logoutReasonText.ok THEN Fail ELSE
    Ok([ logoutReason     |-> logoutReason.value,
         logoutReasonText |-> logoutReasonText.value ], logoutReasonText.rest)

ZeroLogoutResponseMessage ==
    [ logoutReason     |-> [i \in 1 .. 1 |-> 0],
      logoutReasonText |-> [i \in 1 .. 60 |-> 0] ]

(* Logout Response Message at zero, then each field in turn at the values it is checked at *)
CheckedLogoutResponseMessage ==
    { ZeroLogoutResponseMessage }
        \cup { [ZeroLogoutResponseMessage EXCEPT !.logoutReason = one] : one \in Sample(1) }
        \cup { [ZeroLogoutResponseMessage EXCEPT !.logoutReasonText = one] : one \in Sample(60) }

(***************************************************************************)
(* Prevent Match: 3 bytes                                                  *)
(***************************************************************************)

PreventMatch ==
    [ mtpModifier    : Sample(1),
      uniqueIdLevel  : Sample(1),
      tradingGroupId : Sample(1) ]

EncodePreventMatch(message) ==
    message.mtpModifier
        \o message.uniqueIdLevel
        \o message.tradingGroupId

DecodePreventMatch(bytes) ==
    LET mtpModifier == ReadBytes(bytes, 1) IN IF ~mtpModifier.ok THEN Fail ELSE
    LET uniqueIdLevel == ReadBytes(mtpModifier.rest, 1) IN IF ~uniqueIdLevel.ok THEN Fail ELSE
    LET tradingGroupId == ReadBytes(uniqueIdLevel.rest, 1) IN IF ~tradingGroupId.ok THEN Fail ELSE
    Ok([ mtpModifier    |-> mtpModifier.value,
         uniqueIdLevel  |-> uniqueIdLevel.value,
         tradingGroupId |-> tradingGroupId.value ], tradingGroupId.rest)

ZeroPreventMatch ==
    [ mtpModifier    |-> [i \in 1 .. 1 |-> 0],
      uniqueIdLevel  |-> [i \in 1 .. 1 |-> 0],
      tradingGroupId |-> [i \in 1 .. 1 |-> 0] ]

(* Prevent Match at zero, then each field in turn at the values it is checked at *)
CheckedPreventMatch ==
    { ZeroPreventMatch }
        \cup { [ZeroPreventMatch EXCEPT !.mtpModifier = one] : one \in Sample(1) }
        \cup { [ZeroPreventMatch EXCEPT !.uniqueIdLevel = one] : one \in Sample(1) }
        \cup { [ZeroPreventMatch EXCEPT !.tradingGroupId = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Acknowledgement Message: 161 bytes                                *)
(***************************************************************************)

OrderAcknowledgementMessage ==
    [ transactionTime        : Sample(8),
      clOrdId                : Sample(20),
      orderId                : Sample(8),
      side                   : Sample(1),
      price                  : Sample(8),
      ordType                : Sample(1),
      timeInForce            : Sample(1),
      minQty                 : Sample(4),
      symbol                 : Sample(8),
      capacity               : Sample(1),
      account                : Sample(16),
      clearingFirm           : Sample(4),
      clearingAccount        : Sample(4),
      orderQty               : Sample(4),
      preventMatch           : PreventMatch,
      maturityDate           : Sample(4),
      openClose              : Sample(1),
      leavesQty              : Sample(4),
      baseLiquidityIndicator : Sample(1),
      expireTime             : Sample(8),
      subLiquidityIndicator  : Sample(1),
      stopPx                 : Sample(8),
      cmtaNumber             : Sample(4),
      ctiCode                : Sample(1),
      manualOrderIndicator   : Sample(1),
      oeoId                  : Sample(18),
      cumQty                 : Sample(4),
      frequentTraderId       : Sample(6),
      custOrderHandlingInst  : Sample(1),
      requestReceivedTime    : Sample(8) ]

EncodeOrderAcknowledgementMessage(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.orderId
        \o message.side
        \o message.price
        \o message.ordType
        \o message.timeInForce
        \o message.minQty
        \o message.symbol
        \o message.capacity
        \o message.account
        \o message.clearingFirm
        \o message.clearingAccount
        \o message.orderQty
        \o EncodePreventMatch(message.preventMatch)
        \o message.maturityDate
        \o message.openClose
        \o message.leavesQty
        \o message.baseLiquidityIndicator
        \o message.expireTime
        \o message.subLiquidityIndicator
        \o message.stopPx
        \o message.cmtaNumber
        \o message.ctiCode
        \o message.manualOrderIndicator
        \o message.oeoId
        \o message.cumQty
        \o message.frequentTraderId
        \o message.custOrderHandlingInst
        \o message.requestReceivedTime

DecodeOrderAcknowledgementMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clOrdId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET side == ReadBytes(orderId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadBytes(side.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET ordType == ReadBytes(price.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(ordType.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadBytes(timeInForce.rest, 4) IN IF ~minQty.ok THEN Fail ELSE
    LET symbol == ReadBytes(minQty.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET capacity == ReadBytes(symbol.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadBytes(capacity.rest, 16) IN IF ~account.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(account.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadBytes(clearingFirm.rest, 4) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET orderQty == ReadBytes(clearingAccount.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET preventMatch == DecodePreventMatch(orderQty.rest) IN IF ~preventMatch.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(preventMatch.rest, 4) IN IF ~maturityDate.ok THEN Fail ELSE
    LET openClose == ReadBytes(maturityDate.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(openClose.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadBytes(leavesQty.rest, 1) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET expireTime == ReadBytes(baseLiquidityIndicator.rest, 8) IN IF ~expireTime.ok THEN Fail ELSE
    LET subLiquidityIndicator == ReadBytes(expireTime.rest, 1) IN IF ~subLiquidityIndicator.ok THEN Fail ELSE
    LET stopPx == ReadBytes(subLiquidityIndicator.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET cmtaNumber == ReadBytes(stopPx.rest, 4) IN IF ~cmtaNumber.ok THEN Fail ELSE
    LET ctiCode == ReadBytes(cmtaNumber.rest, 1) IN IF ~ctiCode.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadBytes(ctiCode.rest, 1) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET oeoId == ReadBytes(manualOrderIndicator.rest, 18) IN IF ~oeoId.ok THEN Fail ELSE
    LET cumQty == ReadBytes(oeoId.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET frequentTraderId == ReadBytes(cumQty.rest, 6) IN IF ~frequentTraderId.ok THEN Fail ELSE
    LET custOrderHandlingInst == ReadBytes(frequentTraderId.rest, 1) IN IF ~custOrderHandlingInst.ok THEN Fail ELSE
    LET requestReceivedTime == ReadBytes(custOrderHandlingInst.rest, 8) IN IF ~requestReceivedTime.ok THEN Fail ELSE
    Ok([ transactionTime        |-> transactionTime.value,
         clOrdId                |-> clOrdId.value,
         orderId                |-> orderId.value,
         side                   |-> side.value,
         price                  |-> price.value,
         ordType                |-> ordType.value,
         timeInForce            |-> timeInForce.value,
         minQty                 |-> minQty.value,
         symbol                 |-> symbol.value,
         capacity               |-> capacity.value,
         account                |-> account.value,
         clearingFirm           |-> clearingFirm.value,
         clearingAccount        |-> clearingAccount.value,
         orderQty               |-> orderQty.value,
         preventMatch           |-> preventMatch.value,
         maturityDate           |-> maturityDate.value,
         openClose              |-> openClose.value,
         leavesQty              |-> leavesQty.value,
         baseLiquidityIndicator |-> baseLiquidityIndicator.value,
         expireTime             |-> expireTime.value,
         subLiquidityIndicator  |-> subLiquidityIndicator.value,
         stopPx                 |-> stopPx.value,
         cmtaNumber             |-> cmtaNumber.value,
         ctiCode                |-> ctiCode.value,
         manualOrderIndicator   |-> manualOrderIndicator.value,
         oeoId                  |-> oeoId.value,
         cumQty                 |-> cumQty.value,
         frequentTraderId       |-> frequentTraderId.value,
         custOrderHandlingInst  |-> custOrderHandlingInst.value,
         requestReceivedTime    |-> requestReceivedTime.value ], requestReceivedTime.rest)

ZeroOrderAcknowledgementMessage ==
    [ transactionTime        |-> [i \in 1 .. 8 |-> 0],
      clOrdId                |-> [i \in 1 .. 20 |-> 0],
      orderId                |-> [i \in 1 .. 8 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      price                  |-> [i \in 1 .. 8 |-> 0],
      ordType                |-> [i \in 1 .. 1 |-> 0],
      timeInForce            |-> [i \in 1 .. 1 |-> 0],
      minQty                 |-> [i \in 1 .. 4 |-> 0],
      symbol                 |-> [i \in 1 .. 8 |-> 0],
      capacity               |-> [i \in 1 .. 1 |-> 0],
      account                |-> [i \in 1 .. 16 |-> 0],
      clearingFirm           |-> [i \in 1 .. 4 |-> 0],
      clearingAccount        |-> [i \in 1 .. 4 |-> 0],
      orderQty               |-> [i \in 1 .. 4 |-> 0],
      preventMatch           |-> ZeroPreventMatch,
      maturityDate           |-> [i \in 1 .. 4 |-> 0],
      openClose              |-> [i \in 1 .. 1 |-> 0],
      leavesQty              |-> [i \in 1 .. 4 |-> 0],
      baseLiquidityIndicator |-> [i \in 1 .. 1 |-> 0],
      expireTime             |-> [i \in 1 .. 8 |-> 0],
      subLiquidityIndicator  |-> [i \in 1 .. 1 |-> 0],
      stopPx                 |-> [i \in 1 .. 8 |-> 0],
      cmtaNumber             |-> [i \in 1 .. 4 |-> 0],
      ctiCode                |-> [i \in 1 .. 1 |-> 0],
      manualOrderIndicator   |-> [i \in 1 .. 1 |-> 0],
      oeoId                  |-> [i \in 1 .. 18 |-> 0],
      cumQty                 |-> [i \in 1 .. 4 |-> 0],
      frequentTraderId       |-> [i \in 1 .. 6 |-> 0],
      custOrderHandlingInst  |-> [i \in 1 .. 1 |-> 0],
      requestReceivedTime    |-> [i \in 1 .. 8 |-> 0] ]

(* Order Acknowledgement Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderAcknowledgementMessage ==
    { ZeroOrderAcknowledgementMessage }
        \cup { [ZeroOrderAcknowledgementMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgementMessage EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderAcknowledgementMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgementMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgementMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementMessage EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcknowledgementMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgementMessage EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementMessage EXCEPT !.account = one] : one \in Sample(16) }
        \cup { [ZeroOrderAcknowledgementMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcknowledgementMessage EXCEPT !.clearingAccount = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcknowledgementMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcknowledgementMessage EXCEPT !.preventMatch = one] : one \in CheckedPreventMatch }
        \cup { [ZeroOrderAcknowledgementMessage EXCEPT !.maturityDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcknowledgementMessage EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcknowledgementMessage EXCEPT !.baseLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementMessage EXCEPT !.expireTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgementMessage EXCEPT !.subLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementMessage EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgementMessage EXCEPT !.cmtaNumber = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcknowledgementMessage EXCEPT !.ctiCode = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementMessage EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementMessage EXCEPT !.oeoId = one] : one \in Sample(18) }
        \cup { [ZeroOrderAcknowledgementMessage EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcknowledgementMessage EXCEPT !.frequentTraderId = one] : one \in Sample(6) }
        \cup { [ZeroOrderAcknowledgementMessage EXCEPT !.custOrderHandlingInst = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementMessage EXCEPT !.requestReceivedTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Rejected Message: 93 bytes                                        *)
(***************************************************************************)

OrderRejectedMessage ==
    [ transactionTime   : Sample(8),
      clOrdId           : Sample(20),
      clearingFirm      : Sample(4),
      orderRejectReason : Sample(1),
      text              : Sample(60) ]

EncodeOrderRejectedMessage(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.clearingFirm
        \o message.orderRejectReason
        \o message.text

DecodeOrderRejectedMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(clOrdId.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET orderRejectReason == ReadBytes(clearingFirm.rest, 1) IN IF ~orderRejectReason.ok THEN Fail ELSE
    LET text == ReadBytes(orderRejectReason.rest, 60) IN IF ~text.ok THEN Fail ELSE
    Ok([ transactionTime   |-> transactionTime.value,
         clOrdId           |-> clOrdId.value,
         clearingFirm      |-> clearingFirm.value,
         orderRejectReason |-> orderRejectReason.value,
         text              |-> text.value ], text.rest)

ZeroOrderRejectedMessage ==
    [ transactionTime   |-> [i \in 1 .. 8 |-> 0],
      clOrdId           |-> [i \in 1 .. 20 |-> 0],
      clearingFirm      |-> [i \in 1 .. 4 |-> 0],
      orderRejectReason |-> [i \in 1 .. 1 |-> 0],
      text              |-> [i \in 1 .. 60 |-> 0] ]

(* Order Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderRejectedMessage ==
    { ZeroOrderRejectedMessage }
        \cup { [ZeroOrderRejectedMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderRejectedMessage EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderRejectedMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroOrderRejectedMessage EXCEPT !.orderRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroOrderRejectedMessage EXCEPT !.text = one] : one \in Sample(60) }

(***************************************************************************)
(* Order Modified Message: 101 bytes                                       *)
(***************************************************************************)

OrderModifiedMessage ==
    [ transactionTime        : Sample(8),
      clOrdId                : Sample(20),
      origClOrdId            : Sample(20),
      orderId                : Sample(8),
      clearingFirm           : Sample(4),
      price                  : Sample(8),
      ordType                : Sample(1),
      orderQty               : Sample(4),
      leavesQty              : Sample(4),
      baseLiquidityIndicator : Sample(1),
      stopPx                 : Sample(8),
      frequentTraderId       : Sample(6),
      custOrderHandlingInst  : Sample(1),
      requestReceivedTime    : Sample(8) ]

EncodeOrderModifiedMessage(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.origClOrdId
        \o message.orderId
        \o message.clearingFirm
        \o message.price
        \o message.ordType
        \o message.orderQty
        \o message.leavesQty
        \o message.baseLiquidityIndicator
        \o message.stopPx
        \o message.frequentTraderId
        \o message.custOrderHandlingInst
        \o message.requestReceivedTime

DecodeOrderModifiedMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 20) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET orderId == ReadBytes(origClOrdId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(orderId.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET price == ReadBytes(clearingFirm.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET ordType == ReadBytes(price.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET orderQty == ReadBytes(ordType.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(orderQty.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadBytes(leavesQty.rest, 1) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET stopPx == ReadBytes(baseLiquidityIndicator.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET frequentTraderId == ReadBytes(stopPx.rest, 6) IN IF ~frequentTraderId.ok THEN Fail ELSE
    LET custOrderHandlingInst == ReadBytes(frequentTraderId.rest, 1) IN IF ~custOrderHandlingInst.ok THEN Fail ELSE
    LET requestReceivedTime == ReadBytes(custOrderHandlingInst.rest, 8) IN IF ~requestReceivedTime.ok THEN Fail ELSE
    Ok([ transactionTime        |-> transactionTime.value,
         clOrdId                |-> clOrdId.value,
         origClOrdId            |-> origClOrdId.value,
         orderId                |-> orderId.value,
         clearingFirm           |-> clearingFirm.value,
         price                  |-> price.value,
         ordType                |-> ordType.value,
         orderQty               |-> orderQty.value,
         leavesQty              |-> leavesQty.value,
         baseLiquidityIndicator |-> baseLiquidityIndicator.value,
         stopPx                 |-> stopPx.value,
         frequentTraderId       |-> frequentTraderId.value,
         custOrderHandlingInst  |-> custOrderHandlingInst.value,
         requestReceivedTime    |-> requestReceivedTime.value ], requestReceivedTime.rest)

ZeroOrderModifiedMessage ==
    [ transactionTime        |-> [i \in 1 .. 8 |-> 0],
      clOrdId                |-> [i \in 1 .. 20 |-> 0],
      origClOrdId            |-> [i \in 1 .. 20 |-> 0],
      orderId                |-> [i \in 1 .. 8 |-> 0],
      clearingFirm           |-> [i \in 1 .. 4 |-> 0],
      price                  |-> [i \in 1 .. 8 |-> 0],
      ordType                |-> [i \in 1 .. 1 |-> 0],
      orderQty               |-> [i \in 1 .. 4 |-> 0],
      leavesQty              |-> [i \in 1 .. 4 |-> 0],
      baseLiquidityIndicator |-> [i \in 1 .. 1 |-> 0],
      stopPx                 |-> [i \in 1 .. 8 |-> 0],
      frequentTraderId       |-> [i \in 1 .. 6 |-> 0],
      custOrderHandlingInst  |-> [i \in 1 .. 1 |-> 0],
      requestReceivedTime    |-> [i \in 1 .. 8 |-> 0] ]

(* Order Modified Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderModifiedMessage ==
    { ZeroOrderModifiedMessage }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.origClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.baseLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.frequentTraderId = one] : one \in Sample(6) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.custOrderHandlingInst = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.requestReceivedTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Modify Rejected Message: 113 bytes                                      *)
(***************************************************************************)

ModifyRejectedMessage ==
    [ transactionTime    : Sample(8),
      clOrdId            : Sample(20),
      origClOrdId        : Sample(20),
      clearingFirm       : Sample(4),
      modifyRejectReason : Sample(1),
      text               : Sample(60) ]

EncodeModifyRejectedMessage(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.origClOrdId
        \o message.clearingFirm
        \o message.modifyRejectReason
        \o message.text

DecodeModifyRejectedMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 20) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(origClOrdId.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET modifyRejectReason == ReadBytes(clearingFirm.rest, 1) IN IF ~modifyRejectReason.ok THEN Fail ELSE
    LET text == ReadBytes(modifyRejectReason.rest, 60) IN IF ~text.ok THEN Fail ELSE
    Ok([ transactionTime    |-> transactionTime.value,
         clOrdId            |-> clOrdId.value,
         origClOrdId        |-> origClOrdId.value,
         clearingFirm       |-> clearingFirm.value,
         modifyRejectReason |-> modifyRejectReason.value,
         text               |-> text.value ], text.rest)

ZeroModifyRejectedMessage ==
    [ transactionTime    |-> [i \in 1 .. 8 |-> 0],
      clOrdId            |-> [i \in 1 .. 20 |-> 0],
      origClOrdId        |-> [i \in 1 .. 20 |-> 0],
      clearingFirm       |-> [i \in 1 .. 4 |-> 0],
      modifyRejectReason |-> [i \in 1 .. 1 |-> 0],
      text               |-> [i \in 1 .. 60 |-> 0] ]

(* Modify Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedModifyRejectedMessage ==
    { ZeroModifyRejectedMessage }
        \cup { [ZeroModifyRejectedMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroModifyRejectedMessage EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroModifyRejectedMessage EXCEPT !.origClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroModifyRejectedMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroModifyRejectedMessage EXCEPT !.modifyRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroModifyRejectedMessage EXCEPT !.text = one] : one \in Sample(60) }

(***************************************************************************)
(* Order Execution Message: 91 bytes                                       *)
(***************************************************************************)

OrderExecutionMessage ==
    [ transactionTime        : Sample(8),
      clOrdId                : Sample(20),
      execId                 : Sample(8),
      lastShares             : Sample(4),
      lastPx                 : Sample(8),
      leavesQty              : Sample(4),
      baseLiquidityIndicator : Sample(1),
      subLiquidityIndicator  : Sample(1),
      side                   : Sample(1),
      symbol                 : Sample(8),
      clearingFirm           : Sample(4),
      maturityDate           : Sample(4),
      feeCode                : Sample(2),
      tradeDate              : Sample(4),
      clearingSize           : Sample(4),
      pendingStatus          : Sample(1),
      multilegReportingType  : Sample(1),
      secondaryExecId        : Sample(8) ]

EncodeOrderExecutionMessage(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.execId
        \o message.lastShares
        \o message.lastPx
        \o message.leavesQty
        \o message.baseLiquidityIndicator
        \o message.subLiquidityIndicator
        \o message.side
        \o message.symbol
        \o message.clearingFirm
        \o message.maturityDate
        \o message.feeCode
        \o message.tradeDate
        \o message.clearingSize
        \o message.pendingStatus
        \o message.multilegReportingType
        \o message.secondaryExecId

DecodeOrderExecutionMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET execId == ReadBytes(clOrdId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET lastShares == ReadBytes(execId.rest, 4) IN IF ~lastShares.ok THEN Fail ELSE
    LET lastPx == ReadBytes(lastShares.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(lastPx.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadBytes(leavesQty.rest, 1) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET subLiquidityIndicator == ReadBytes(baseLiquidityIndicator.rest, 1) IN IF ~subLiquidityIndicator.ok THEN Fail ELSE
    LET side == ReadBytes(subLiquidityIndicator.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET symbol == ReadBytes(side.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(symbol.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(clearingFirm.rest, 4) IN IF ~maturityDate.ok THEN Fail ELSE
    LET feeCode == ReadBytes(maturityDate.rest, 2) IN IF ~feeCode.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(feeCode.rest, 4) IN IF ~tradeDate.ok THEN Fail ELSE
    LET clearingSize == ReadBytes(tradeDate.rest, 4) IN IF ~clearingSize.ok THEN Fail ELSE
    LET pendingStatus == ReadBytes(clearingSize.rest, 1) IN IF ~pendingStatus.ok THEN Fail ELSE
    LET multilegReportingType == ReadBytes(pendingStatus.rest, 1) IN IF ~multilegReportingType.ok THEN Fail ELSE
    LET secondaryExecId == ReadBytes(multilegReportingType.rest, 8) IN IF ~secondaryExecId.ok THEN Fail ELSE
    Ok([ transactionTime        |-> transactionTime.value,
         clOrdId                |-> clOrdId.value,
         execId                 |-> execId.value,
         lastShares             |-> lastShares.value,
         lastPx                 |-> lastPx.value,
         leavesQty              |-> leavesQty.value,
         baseLiquidityIndicator |-> baseLiquidityIndicator.value,
         subLiquidityIndicator  |-> subLiquidityIndicator.value,
         side                   |-> side.value,
         symbol                 |-> symbol.value,
         clearingFirm           |-> clearingFirm.value,
         maturityDate           |-> maturityDate.value,
         feeCode                |-> feeCode.value,
         tradeDate              |-> tradeDate.value,
         clearingSize           |-> clearingSize.value,
         pendingStatus          |-> pendingStatus.value,
         multilegReportingType  |-> multilegReportingType.value,
         secondaryExecId        |-> secondaryExecId.value ], secondaryExecId.rest)

ZeroOrderExecutionMessage ==
    [ transactionTime        |-> [i \in 1 .. 8 |-> 0],
      clOrdId                |-> [i \in 1 .. 20 |-> 0],
      execId                 |-> [i \in 1 .. 8 |-> 0],
      lastShares             |-> [i \in 1 .. 4 |-> 0],
      lastPx                 |-> [i \in 1 .. 8 |-> 0],
      leavesQty              |-> [i \in 1 .. 4 |-> 0],
      baseLiquidityIndicator |-> [i \in 1 .. 1 |-> 0],
      subLiquidityIndicator  |-> [i \in 1 .. 1 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      symbol                 |-> [i \in 1 .. 8 |-> 0],
      clearingFirm           |-> [i \in 1 .. 4 |-> 0],
      maturityDate           |-> [i \in 1 .. 4 |-> 0],
      feeCode                |-> [i \in 1 .. 2 |-> 0],
      tradeDate              |-> [i \in 1 .. 4 |-> 0],
      clearingSize           |-> [i \in 1 .. 4 |-> 0],
      pendingStatus          |-> [i \in 1 .. 1 |-> 0],
      multilegReportingType  |-> [i \in 1 .. 1 |-> 0],
      secondaryExecId        |-> [i \in 1 .. 8 |-> 0] ]

(* Order Execution Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutionMessage ==
    { ZeroOrderExecutionMessage }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.lastShares = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.baseLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.subLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.maturityDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.feeCode = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.tradeDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.clearingSize = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.pendingStatus = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.multilegReportingType = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.secondaryExecId = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Cancelled Message: 41 bytes                                       *)
(***************************************************************************)

OrderCancelledMessage ==
    [ transactionTime     : Sample(8),
      clOrdId             : Sample(20),
      clearingFirm        : Sample(4),
      cancelReason        : Sample(1),
      requestReceivedTime : Sample(8) ]

EncodeOrderCancelledMessage(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.clearingFirm
        \o message.cancelReason
        \o message.requestReceivedTime

DecodeOrderCancelledMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(clOrdId.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET cancelReason == ReadBytes(clearingFirm.rest, 1) IN IF ~cancelReason.ok THEN Fail ELSE
    LET requestReceivedTime == ReadBytes(cancelReason.rest, 8) IN IF ~requestReceivedTime.ok THEN Fail ELSE
    Ok([ transactionTime     |-> transactionTime.value,
         clOrdId             |-> clOrdId.value,
         clearingFirm        |-> clearingFirm.value,
         cancelReason        |-> cancelReason.value,
         requestReceivedTime |-> requestReceivedTime.value ], requestReceivedTime.rest)

ZeroOrderCancelledMessage ==
    [ transactionTime     |-> [i \in 1 .. 8 |-> 0],
      clOrdId             |-> [i \in 1 .. 20 |-> 0],
      clearingFirm        |-> [i \in 1 .. 4 |-> 0],
      cancelReason        |-> [i \in 1 .. 1 |-> 0],
      requestReceivedTime |-> [i \in 1 .. 8 |-> 0] ]

(* Order Cancelled Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelledMessage ==
    { ZeroOrderCancelledMessage }
        \cup { [ZeroOrderCancelledMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelledMessage EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderCancelledMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelledMessage EXCEPT !.cancelReason = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelledMessage EXCEPT !.requestReceivedTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Cancel Rejected Message: 93 bytes                                       *)
(***************************************************************************)

CancelRejectedMessage ==
    [ transactionTime    : Sample(8),
      clOrdId            : Sample(20),
      clearingFirm       : Sample(4),
      cancelRejectReason : Sample(1),
      text               : Sample(60) ]

EncodeCancelRejectedMessage(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.clearingFirm
        \o message.cancelRejectReason
        \o message.text

DecodeCancelRejectedMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(clOrdId.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET cancelRejectReason == ReadBytes(clearingFirm.rest, 1) IN IF ~cancelRejectReason.ok THEN Fail ELSE
    LET text == ReadBytes(cancelRejectReason.rest, 60) IN IF ~text.ok THEN Fail ELSE
    Ok([ transactionTime    |-> transactionTime.value,
         clOrdId            |-> clOrdId.value,
         clearingFirm       |-> clearingFirm.value,
         cancelRejectReason |-> cancelRejectReason.value,
         text               |-> text.value ], text.rest)

ZeroCancelRejectedMessage ==
    [ transactionTime    |-> [i \in 1 .. 8 |-> 0],
      clOrdId            |-> [i \in 1 .. 20 |-> 0],
      clearingFirm       |-> [i \in 1 .. 4 |-> 0],
      cancelRejectReason |-> [i \in 1 .. 1 |-> 0],
      text               |-> [i \in 1 .. 60 |-> 0] ]

(* Cancel Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelRejectedMessage ==
    { ZeroCancelRejectedMessage }
        \cup { [ZeroCancelRejectedMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroCancelRejectedMessage EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroCancelRejectedMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroCancelRejectedMessage EXCEPT !.cancelRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroCancelRejectedMessage EXCEPT !.text = one] : one \in Sample(60) }

(***************************************************************************)
(* Mass Cancel Acknowledgement Message: 40 bytes                           *)
(***************************************************************************)

MassCancelAcknowledgementMessage ==
    [ transactionTime     : Sample(8),
      massCancelId        : Sample(20),
      cancelledOrderCount : Sample(4),
      requestReceivedTime : Sample(8) ]

EncodeMassCancelAcknowledgementMessage(message) ==
    message.transactionTime
        \o message.massCancelId
        \o message.cancelledOrderCount
        \o message.requestReceivedTime

DecodeMassCancelAcknowledgementMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET massCancelId == ReadBytes(transactionTime.rest, 20) IN IF ~massCancelId.ok THEN Fail ELSE
    LET cancelledOrderCount == ReadBytes(massCancelId.rest, 4) IN IF ~cancelledOrderCount.ok THEN Fail ELSE
    LET requestReceivedTime == ReadBytes(cancelledOrderCount.rest, 8) IN IF ~requestReceivedTime.ok THEN Fail ELSE
    Ok([ transactionTime     |-> transactionTime.value,
         massCancelId        |-> massCancelId.value,
         cancelledOrderCount |-> cancelledOrderCount.value,
         requestReceivedTime |-> requestReceivedTime.value ], requestReceivedTime.rest)

ZeroMassCancelAcknowledgementMessage ==
    [ transactionTime     |-> [i \in 1 .. 8 |-> 0],
      massCancelId        |-> [i \in 1 .. 20 |-> 0],
      cancelledOrderCount |-> [i \in 1 .. 4 |-> 0],
      requestReceivedTime |-> [i \in 1 .. 8 |-> 0] ]

(* Mass Cancel Acknowledgement Message at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelAcknowledgementMessage ==
    { ZeroMassCancelAcknowledgementMessage }
        \cup { [ZeroMassCancelAcknowledgementMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelAcknowledgementMessage EXCEPT !.massCancelId = one] : one \in Sample(20) }
        \cup { [ZeroMassCancelAcknowledgementMessage EXCEPT !.cancelledOrderCount = one] : one \in Sample(4) }
        \cup { [ZeroMassCancelAcknowledgementMessage EXCEPT !.requestReceivedTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Mass Cancel Rejected Message: 89 bytes                                  *)
(***************************************************************************)

MassCancelRejectedMessage ==
    [ transactionTime        : Sample(8),
      massCancelId           : Sample(20),
      massCancelRejectReason : Sample(1),
      text                   : Sample(60) ]

EncodeMassCancelRejectedMessage(message) ==
    message.transactionTime
        \o message.massCancelId
        \o message.massCancelRejectReason
        \o message.text

DecodeMassCancelRejectedMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET massCancelId == ReadBytes(transactionTime.rest, 20) IN IF ~massCancelId.ok THEN Fail ELSE
    LET massCancelRejectReason == ReadBytes(massCancelId.rest, 1) IN IF ~massCancelRejectReason.ok THEN Fail ELSE
    LET text == ReadBytes(massCancelRejectReason.rest, 60) IN IF ~text.ok THEN Fail ELSE
    Ok([ transactionTime        |-> transactionTime.value,
         massCancelId           |-> massCancelId.value,
         massCancelRejectReason |-> massCancelRejectReason.value,
         text                   |-> text.value ], text.rest)

ZeroMassCancelRejectedMessage ==
    [ transactionTime        |-> [i \in 1 .. 8 |-> 0],
      massCancelId           |-> [i \in 1 .. 20 |-> 0],
      massCancelRejectReason |-> [i \in 1 .. 1 |-> 0],
      text                   |-> [i \in 1 .. 60 |-> 0] ]

(* Mass Cancel Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelRejectedMessage ==
    { ZeroMassCancelRejectedMessage }
        \cup { [ZeroMassCancelRejectedMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelRejectedMessage EXCEPT !.massCancelId = one] : one \in Sample(20) }
        \cup { [ZeroMassCancelRejectedMessage EXCEPT !.massCancelRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelRejectedMessage EXCEPT !.text = one] : one \in Sample(60) }

(***************************************************************************)
(* Purge Acknowledgement Message: 40 bytes                                 *)
(***************************************************************************)

PurgeAcknowledgementMessage ==
    [ transactionTime     : Sample(8),
      massCancelId        : Sample(20),
      cancelledOrderCount : Sample(4),
      requestReceivedTime : Sample(8) ]

EncodePurgeAcknowledgementMessage(message) ==
    message.transactionTime
        \o message.massCancelId
        \o message.cancelledOrderCount
        \o message.requestReceivedTime

DecodePurgeAcknowledgementMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET massCancelId == ReadBytes(transactionTime.rest, 20) IN IF ~massCancelId.ok THEN Fail ELSE
    LET cancelledOrderCount == ReadBytes(massCancelId.rest, 4) IN IF ~cancelledOrderCount.ok THEN Fail ELSE
    LET requestReceivedTime == ReadBytes(cancelledOrderCount.rest, 8) IN IF ~requestReceivedTime.ok THEN Fail ELSE
    Ok([ transactionTime     |-> transactionTime.value,
         massCancelId        |-> massCancelId.value,
         cancelledOrderCount |-> cancelledOrderCount.value,
         requestReceivedTime |-> requestReceivedTime.value ], requestReceivedTime.rest)

ZeroPurgeAcknowledgementMessage ==
    [ transactionTime     |-> [i \in 1 .. 8 |-> 0],
      massCancelId        |-> [i \in 1 .. 20 |-> 0],
      cancelledOrderCount |-> [i \in 1 .. 4 |-> 0],
      requestReceivedTime |-> [i \in 1 .. 8 |-> 0] ]

(* Purge Acknowledgement Message at zero, then each field in turn at the values it is checked at *)
CheckedPurgeAcknowledgementMessage ==
    { ZeroPurgeAcknowledgementMessage }
        \cup { [ZeroPurgeAcknowledgementMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroPurgeAcknowledgementMessage EXCEPT !.massCancelId = one] : one \in Sample(20) }
        \cup { [ZeroPurgeAcknowledgementMessage EXCEPT !.cancelledOrderCount = one] : one \in Sample(4) }
        \cup { [ZeroPurgeAcknowledgementMessage EXCEPT !.requestReceivedTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Purge Rejected Message: 89 bytes                                        *)
(***************************************************************************)

PurgeRejectedMessage ==
    [ transactionTime   : Sample(8),
      massCancelId      : Sample(20),
      purgeRejectReason : Sample(1),
      text              : Sample(60) ]

EncodePurgeRejectedMessage(message) ==
    message.transactionTime
        \o message.massCancelId
        \o message.purgeRejectReason
        \o message.text

DecodePurgeRejectedMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET massCancelId == ReadBytes(transactionTime.rest, 20) IN IF ~massCancelId.ok THEN Fail ELSE
    LET purgeRejectReason == ReadBytes(massCancelId.rest, 1) IN IF ~purgeRejectReason.ok THEN Fail ELSE
    LET text == ReadBytes(purgeRejectReason.rest, 60) IN IF ~text.ok THEN Fail ELSE
    Ok([ transactionTime   |-> transactionTime.value,
         massCancelId      |-> massCancelId.value,
         purgeRejectReason |-> purgeRejectReason.value,
         text              |-> text.value ], text.rest)

ZeroPurgeRejectedMessage ==
    [ transactionTime   |-> [i \in 1 .. 8 |-> 0],
      massCancelId      |-> [i \in 1 .. 20 |-> 0],
      purgeRejectReason |-> [i \in 1 .. 1 |-> 0],
      text              |-> [i \in 1 .. 60 |-> 0] ]

(* Purge Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedPurgeRejectedMessage ==
    { ZeroPurgeRejectedMessage }
        \cup { [ZeroPurgeRejectedMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroPurgeRejectedMessage EXCEPT !.massCancelId = one] : one \in Sample(20) }
        \cup { [ZeroPurgeRejectedMessage EXCEPT !.purgeRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroPurgeRejectedMessage EXCEPT !.text = one] : one \in Sample(60) }

(***************************************************************************)
(* Trade Cancel Or Correct Message: 92 bytes                               *)
(***************************************************************************)

TradeCancelOrCorrectMessage ==
    [ transactionTime        : Sample(8),
      clOrdId                : Sample(20),
      execRefId              : Sample(8),
      side                   : Sample(1),
      baseLiquidityIndicator : Sample(1),
      clearingFirm           : Sample(4),
      clearingAccount        : Sample(4),
      lastShares             : Sample(4),
      lastPx                 : Sample(8),
      correctedPrice         : Sample(8),
      origTime               : Sample(8),
      symbol                 : Sample(8),
      capacity               : Sample(1),
      maturityDate           : Sample(4),
      openClose              : Sample(1),
      cmtaNumber             : Sample(4) ]

EncodeTradeCancelOrCorrectMessage(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.execRefId
        \o message.side
        \o message.baseLiquidityIndicator
        \o message.clearingFirm
        \o message.clearingAccount
        \o message.lastShares
        \o message.lastPx
        \o message.correctedPrice
        \o message.origTime
        \o message.symbol
        \o message.capacity
        \o message.maturityDate
        \o message.openClose
        \o message.cmtaNumber

DecodeTradeCancelOrCorrectMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET execRefId == ReadBytes(clOrdId.rest, 8) IN IF ~execRefId.ok THEN Fail ELSE
    LET side == ReadBytes(execRefId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadBytes(side.rest, 1) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(baseLiquidityIndicator.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadBytes(clearingFirm.rest, 4) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET lastShares == ReadBytes(clearingAccount.rest, 4) IN IF ~lastShares.ok THEN Fail ELSE
    LET lastPx == ReadBytes(lastShares.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET correctedPrice == ReadBytes(lastPx.rest, 8) IN IF ~correctedPrice.ok THEN Fail ELSE
    LET origTime == ReadBytes(correctedPrice.rest, 8) IN IF ~origTime.ok THEN Fail ELSE
    LET symbol == ReadBytes(origTime.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET capacity == ReadBytes(symbol.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(capacity.rest, 4) IN IF ~maturityDate.ok THEN Fail ELSE
    LET openClose == ReadBytes(maturityDate.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET cmtaNumber == ReadBytes(openClose.rest, 4) IN IF ~cmtaNumber.ok THEN Fail ELSE
    Ok([ transactionTime        |-> transactionTime.value,
         clOrdId                |-> clOrdId.value,
         execRefId              |-> execRefId.value,
         side                   |-> side.value,
         baseLiquidityIndicator |-> baseLiquidityIndicator.value,
         clearingFirm           |-> clearingFirm.value,
         clearingAccount        |-> clearingAccount.value,
         lastShares             |-> lastShares.value,
         lastPx                 |-> lastPx.value,
         correctedPrice         |-> correctedPrice.value,
         origTime               |-> origTime.value,
         symbol                 |-> symbol.value,
         capacity               |-> capacity.value,
         maturityDate           |-> maturityDate.value,
         openClose              |-> openClose.value,
         cmtaNumber             |-> cmtaNumber.value ], cmtaNumber.rest)

ZeroTradeCancelOrCorrectMessage ==
    [ transactionTime        |-> [i \in 1 .. 8 |-> 0],
      clOrdId                |-> [i \in 1 .. 20 |-> 0],
      execRefId              |-> [i \in 1 .. 8 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      baseLiquidityIndicator |-> [i \in 1 .. 1 |-> 0],
      clearingFirm           |-> [i \in 1 .. 4 |-> 0],
      clearingAccount        |-> [i \in 1 .. 4 |-> 0],
      lastShares             |-> [i \in 1 .. 4 |-> 0],
      lastPx                 |-> [i \in 1 .. 8 |-> 0],
      correctedPrice         |-> [i \in 1 .. 8 |-> 0],
      origTime               |-> [i \in 1 .. 8 |-> 0],
      symbol                 |-> [i \in 1 .. 8 |-> 0],
      capacity               |-> [i \in 1 .. 1 |-> 0],
      maturityDate           |-> [i \in 1 .. 4 |-> 0],
      openClose              |-> [i \in 1 .. 1 |-> 0],
      cmtaNumber             |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Cancel Or Correct Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCancelOrCorrectMessage ==
    { ZeroTradeCancelOrCorrectMessage }
        \cup { [ZeroTradeCancelOrCorrectMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelOrCorrectMessage EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroTradeCancelOrCorrectMessage EXCEPT !.execRefId = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelOrCorrectMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelOrCorrectMessage EXCEPT !.baseLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelOrCorrectMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelOrCorrectMessage EXCEPT !.clearingAccount = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelOrCorrectMessage EXCEPT !.lastShares = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelOrCorrectMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelOrCorrectMessage EXCEPT !.correctedPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelOrCorrectMessage EXCEPT !.origTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelOrCorrectMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelOrCorrectMessage EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelOrCorrectMessage EXCEPT !.maturityDate = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelOrCorrectMessage EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelOrCorrectMessage EXCEPT !.cmtaNumber = one] : one \in Sample(4) }

(***************************************************************************)
(* Tas Restatement Message: 104 bytes                                      *)
(***************************************************************************)

TasRestatementMessage ==
    [ transactionTime       : Sample(8),
      clOrdId               : Sample(20),
      clearingFirm          : Sample(4),
      execId                : Sample(8),
      side                  : Sample(1),
      price                 : Sample(8),
      symbol                : Sample(8),
      maturityDate          : Sample(4),
      lastShares            : Sample(4),
      lastPx                : Sample(8),
      feeCode               : Sample(2),
      tradeDate             : Sample(4),
      clearingPrice         : Sample(8),
      clearingSymbol        : Sample(8),
      multilegReportingType : Sample(1),
      secondaryExecId       : Sample(8) ]

EncodeTasRestatementMessage(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.clearingFirm
        \o message.execId
        \o message.side
        \o message.price
        \o message.symbol
        \o message.maturityDate
        \o message.lastShares
        \o message.lastPx
        \o message.feeCode
        \o message.tradeDate
        \o message.clearingPrice
        \o message.clearingSymbol
        \o message.multilegReportingType
        \o message.secondaryExecId

DecodeTasRestatementMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(clOrdId.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET execId == ReadBytes(clearingFirm.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET side == ReadBytes(execId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadBytes(side.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET symbol == ReadBytes(price.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(symbol.rest, 4) IN IF ~maturityDate.ok THEN Fail ELSE
    LET lastShares == ReadBytes(maturityDate.rest, 4) IN IF ~lastShares.ok THEN Fail ELSE
    LET lastPx == ReadBytes(lastShares.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET feeCode == ReadBytes(lastPx.rest, 2) IN IF ~feeCode.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(feeCode.rest, 4) IN IF ~tradeDate.ok THEN Fail ELSE
    LET clearingPrice == ReadBytes(tradeDate.rest, 8) IN IF ~clearingPrice.ok THEN Fail ELSE
    LET clearingSymbol == ReadBytes(clearingPrice.rest, 8) IN IF ~clearingSymbol.ok THEN Fail ELSE
    LET multilegReportingType == ReadBytes(clearingSymbol.rest, 1) IN IF ~multilegReportingType.ok THEN Fail ELSE
    LET secondaryExecId == ReadBytes(multilegReportingType.rest, 8) IN IF ~secondaryExecId.ok THEN Fail ELSE
    Ok([ transactionTime       |-> transactionTime.value,
         clOrdId               |-> clOrdId.value,
         clearingFirm          |-> clearingFirm.value,
         execId                |-> execId.value,
         side                  |-> side.value,
         price                 |-> price.value,
         symbol                |-> symbol.value,
         maturityDate          |-> maturityDate.value,
         lastShares            |-> lastShares.value,
         lastPx                |-> lastPx.value,
         feeCode               |-> feeCode.value,
         tradeDate             |-> tradeDate.value,
         clearingPrice         |-> clearingPrice.value,
         clearingSymbol        |-> clearingSymbol.value,
         multilegReportingType |-> multilegReportingType.value,
         secondaryExecId       |-> secondaryExecId.value ], secondaryExecId.rest)

ZeroTasRestatementMessage ==
    [ transactionTime       |-> [i \in 1 .. 8 |-> 0],
      clOrdId               |-> [i \in 1 .. 20 |-> 0],
      clearingFirm          |-> [i \in 1 .. 4 |-> 0],
      execId                |-> [i \in 1 .. 8 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      price                 |-> [i \in 1 .. 8 |-> 0],
      symbol                |-> [i \in 1 .. 8 |-> 0],
      maturityDate          |-> [i \in 1 .. 4 |-> 0],
      lastShares            |-> [i \in 1 .. 4 |-> 0],
      lastPx                |-> [i \in 1 .. 8 |-> 0],
      feeCode               |-> [i \in 1 .. 2 |-> 0],
      tradeDate             |-> [i \in 1 .. 4 |-> 0],
      clearingPrice         |-> [i \in 1 .. 8 |-> 0],
      clearingSymbol        |-> [i \in 1 .. 8 |-> 0],
      multilegReportingType |-> [i \in 1 .. 1 |-> 0],
      secondaryExecId       |-> [i \in 1 .. 8 |-> 0] ]

(* Tas Restatement Message at zero, then each field in turn at the values it is checked at *)
CheckedTasRestatementMessage ==
    { ZeroTasRestatementMessage }
        \cup { [ZeroTasRestatementMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroTasRestatementMessage EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroTasRestatementMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroTasRestatementMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroTasRestatementMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroTasRestatementMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTasRestatementMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroTasRestatementMessage EXCEPT !.maturityDate = one] : one \in Sample(4) }
        \cup { [ZeroTasRestatementMessage EXCEPT !.lastShares = one] : one \in Sample(4) }
        \cup { [ZeroTasRestatementMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroTasRestatementMessage EXCEPT !.feeCode = one] : one \in Sample(2) }
        \cup { [ZeroTasRestatementMessage EXCEPT !.tradeDate = one] : one \in Sample(4) }
        \cup { [ZeroTasRestatementMessage EXCEPT !.clearingPrice = one] : one \in Sample(8) }
        \cup { [ZeroTasRestatementMessage EXCEPT !.clearingSymbol = one] : one \in Sample(8) }
        \cup { [ZeroTasRestatementMessage EXCEPT !.multilegReportingType = one] : one \in Sample(1) }
        \cup { [ZeroTasRestatementMessage EXCEPT !.secondaryExecId = one] : one \in Sample(8) }

(***************************************************************************)
(* Variance Restatement Message: 108 bytes                                 *)
(***************************************************************************)

VarianceRestatementMessage ==
    [ transactionTime       : Sample(8),
      clOrdId               : Sample(20),
      clearingFirm          : Sample(4),
      execId                : Sample(8),
      side                  : Sample(1),
      price                 : Sample(8),
      symbol                : Sample(8),
      maturityDate          : Sample(4),
      lastShares            : Sample(4),
      lastPx                : Sample(8),
      feeCode               : Sample(2),
      tradeDate             : Sample(4),
      clearingPrice         : Sample(8),
      clearingSize          : Sample(4),
      clearingSymbol        : Sample(8),
      multilegReportingType : Sample(1),
      secondaryExecId       : Sample(8) ]

EncodeVarianceRestatementMessage(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.clearingFirm
        \o message.execId
        \o message.side
        \o message.price
        \o message.symbol
        \o message.maturityDate
        \o message.lastShares
        \o message.lastPx
        \o message.feeCode
        \o message.tradeDate
        \o message.clearingPrice
        \o message.clearingSize
        \o message.clearingSymbol
        \o message.multilegReportingType
        \o message.secondaryExecId

DecodeVarianceRestatementMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(clOrdId.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET execId == ReadBytes(clearingFirm.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET side == ReadBytes(execId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadBytes(side.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET symbol == ReadBytes(price.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(symbol.rest, 4) IN IF ~maturityDate.ok THEN Fail ELSE
    LET lastShares == ReadBytes(maturityDate.rest, 4) IN IF ~lastShares.ok THEN Fail ELSE
    LET lastPx == ReadBytes(lastShares.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET feeCode == ReadBytes(lastPx.rest, 2) IN IF ~feeCode.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(feeCode.rest, 4) IN IF ~tradeDate.ok THEN Fail ELSE
    LET clearingPrice == ReadBytes(tradeDate.rest, 8) IN IF ~clearingPrice.ok THEN Fail ELSE
    LET clearingSize == ReadBytes(clearingPrice.rest, 4) IN IF ~clearingSize.ok THEN Fail ELSE
    LET clearingSymbol == ReadBytes(clearingSize.rest, 8) IN IF ~clearingSymbol.ok THEN Fail ELSE
    LET multilegReportingType == ReadBytes(clearingSymbol.rest, 1) IN IF ~multilegReportingType.ok THEN Fail ELSE
    LET secondaryExecId == ReadBytes(multilegReportingType.rest, 8) IN IF ~secondaryExecId.ok THEN Fail ELSE
    Ok([ transactionTime       |-> transactionTime.value,
         clOrdId               |-> clOrdId.value,
         clearingFirm          |-> clearingFirm.value,
         execId                |-> execId.value,
         side                  |-> side.value,
         price                 |-> price.value,
         symbol                |-> symbol.value,
         maturityDate          |-> maturityDate.value,
         lastShares            |-> lastShares.value,
         lastPx                |-> lastPx.value,
         feeCode               |-> feeCode.value,
         tradeDate             |-> tradeDate.value,
         clearingPrice         |-> clearingPrice.value,
         clearingSize          |-> clearingSize.value,
         clearingSymbol        |-> clearingSymbol.value,
         multilegReportingType |-> multilegReportingType.value,
         secondaryExecId       |-> secondaryExecId.value ], secondaryExecId.rest)

ZeroVarianceRestatementMessage ==
    [ transactionTime       |-> [i \in 1 .. 8 |-> 0],
      clOrdId               |-> [i \in 1 .. 20 |-> 0],
      clearingFirm          |-> [i \in 1 .. 4 |-> 0],
      execId                |-> [i \in 1 .. 8 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      price                 |-> [i \in 1 .. 8 |-> 0],
      symbol                |-> [i \in 1 .. 8 |-> 0],
      maturityDate          |-> [i \in 1 .. 4 |-> 0],
      lastShares            |-> [i \in 1 .. 4 |-> 0],
      lastPx                |-> [i \in 1 .. 8 |-> 0],
      feeCode               |-> [i \in 1 .. 2 |-> 0],
      tradeDate             |-> [i \in 1 .. 4 |-> 0],
      clearingPrice         |-> [i \in 1 .. 8 |-> 0],
      clearingSize          |-> [i \in 1 .. 4 |-> 0],
      clearingSymbol        |-> [i \in 1 .. 8 |-> 0],
      multilegReportingType |-> [i \in 1 .. 1 |-> 0],
      secondaryExecId       |-> [i \in 1 .. 8 |-> 0] ]

(* Variance Restatement Message at zero, then each field in turn at the values it is checked at *)
CheckedVarianceRestatementMessage ==
    { ZeroVarianceRestatementMessage }
        \cup { [ZeroVarianceRestatementMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroVarianceRestatementMessage EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroVarianceRestatementMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroVarianceRestatementMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroVarianceRestatementMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroVarianceRestatementMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroVarianceRestatementMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroVarianceRestatementMessage EXCEPT !.maturityDate = one] : one \in Sample(4) }
        \cup { [ZeroVarianceRestatementMessage EXCEPT !.lastShares = one] : one \in Sample(4) }
        \cup { [ZeroVarianceRestatementMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroVarianceRestatementMessage EXCEPT !.feeCode = one] : one \in Sample(2) }
        \cup { [ZeroVarianceRestatementMessage EXCEPT !.tradeDate = one] : one \in Sample(4) }
        \cup { [ZeroVarianceRestatementMessage EXCEPT !.clearingPrice = one] : one \in Sample(8) }
        \cup { [ZeroVarianceRestatementMessage EXCEPT !.clearingSize = one] : one \in Sample(4) }
        \cup { [ZeroVarianceRestatementMessage EXCEPT !.clearingSymbol = one] : one \in Sample(8) }
        \cup { [ZeroVarianceRestatementMessage EXCEPT !.multilegReportingType = one] : one \in Sample(1) }
        \cup { [ZeroVarianceRestatementMessage EXCEPT !.secondaryExecId = one] : one \in Sample(8) }

(***************************************************************************)
(* Quote Update Acknowledgement Group: 10 bytes                            *)
(***************************************************************************)

QuoteUpdateAcknowledgementGroup ==
    [ orderId               : Sample(8),
      quoteResult           : Sample(1),
      subLiquidityIndicator : Sample(1) ]

EncodeQuoteUpdateAcknowledgementGroup(message) ==
    message.orderId
        \o message.quoteResult
        \o message.subLiquidityIndicator

DecodeQuoteUpdateAcknowledgementGroup(bytes) ==
    LET orderId == ReadBytes(bytes, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET quoteResult == ReadBytes(orderId.rest, 1) IN IF ~quoteResult.ok THEN Fail ELSE
    LET subLiquidityIndicator == ReadBytes(quoteResult.rest, 1) IN IF ~subLiquidityIndicator.ok THEN Fail ELSE
    Ok([ orderId               |-> orderId.value,
         quoteResult           |-> quoteResult.value,
         subLiquidityIndicator |-> subLiquidityIndicator.value ], subLiquidityIndicator.rest)

ZeroQuoteUpdateAcknowledgementGroup ==
    [ orderId               |-> [i \in 1 .. 8 |-> 0],
      quoteResult           |-> [i \in 1 .. 1 |-> 0],
      subLiquidityIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Update Acknowledgement Group at zero, then each field in turn at the values it is checked at *)
CheckedQuoteUpdateAcknowledgementGroup ==
    { ZeroQuoteUpdateAcknowledgementGroup }
        \cup { [ZeroQuoteUpdateAcknowledgementGroup EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteUpdateAcknowledgementGroup EXCEPT !.quoteResult = one] : one \in Sample(1) }
        \cup { [ZeroQuoteUpdateAcknowledgementGroup EXCEPT !.subLiquidityIndicator = one] : one \in Sample(1) }

(* A run of Quote Update Acknowledgement Group, written one after another *)
RECURSIVE EncodeQuoteUpdateAcknowledgementGroupList(_)
EncodeQuoteUpdateAcknowledgementGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeQuoteUpdateAcknowledgementGroup(Head(messages)) \o EncodeQuoteUpdateAcknowledgementGroupList(Tail(messages))

(* As many Quote Update Acknowledgement Group as the field that counts them says *)
RECURSIVE ReadQuoteUpdateAcknowledgementGroupList(_, _)
ReadQuoteUpdateAcknowledgementGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeQuoteUpdateAcknowledgementGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadQuoteUpdateAcknowledgementGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Quote Update Acknowledgement Group of each kind, for the lists that carry them *)
OneQuoteUpdateAcknowledgementGroup == { ZeroQuoteUpdateAcknowledgementGroup }

(***************************************************************************)
(* Quote Update Acknowledgement Message                                    *)
(***************************************************************************)

QuoteUpdateAcknowledgementMessage ==
    [ transactionTime                 : Sample(8),
      quoteUpdateId                   : Sample(16),
      requestReceivedTime             : Sample(8),
      quoteUpdateAcknowledgementGroup : SampleLists(OneQuoteUpdateAcknowledgementGroup) ]

EncodeQuoteUpdateAcknowledgementMessage(message) ==
    message.transactionTime
        \o message.quoteUpdateId
        \o message.requestReceivedTime
        \o EncodeUIntLE(Len(message.quoteUpdateAcknowledgementGroup), 1)
        \o EncodeQuoteUpdateAcknowledgementGroupList(message.quoteUpdateAcknowledgementGroup)

DecodeQuoteUpdateAcknowledgementMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET quoteUpdateId == ReadBytes(transactionTime.rest, 16) IN IF ~quoteUpdateId.ok THEN Fail ELSE
    LET requestReceivedTime == ReadBytes(quoteUpdateId.rest, 8) IN IF ~requestReceivedTime.ok THEN Fail ELSE
    LET quoteCnt == ReadUIntLE(requestReceivedTime.rest, 1) IN IF ~quoteCnt.ok THEN Fail ELSE
    LET quoteUpdateAcknowledgementGroup == ReadQuoteUpdateAcknowledgementGroupList(quoteCnt.rest, quoteCnt.value) IN IF ~quoteUpdateAcknowledgementGroup.ok THEN Fail ELSE
    Ok([ transactionTime                 |-> transactionTime.value,
         quoteUpdateId                   |-> quoteUpdateId.value,
         requestReceivedTime             |-> requestReceivedTime.value,
         quoteUpdateAcknowledgementGroup |-> quoteUpdateAcknowledgementGroup.value ], quoteUpdateAcknowledgementGroup.rest)

ZeroQuoteUpdateAcknowledgementMessage ==
    [ transactionTime                 |-> [i \in 1 .. 8 |-> 0],
      quoteUpdateId                   |-> [i \in 1 .. 16 |-> 0],
      requestReceivedTime             |-> [i \in 1 .. 8 |-> 0],
      quoteUpdateAcknowledgementGroup |-> << >> ]

(* Quote Update Acknowledgement Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteUpdateAcknowledgementMessage ==
    { ZeroQuoteUpdateAcknowledgementMessage }
        \cup { [ZeroQuoteUpdateAcknowledgementMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroQuoteUpdateAcknowledgementMessage EXCEPT !.quoteUpdateId = one] : one \in Sample(16) }
        \cup { [ZeroQuoteUpdateAcknowledgementMessage EXCEPT !.requestReceivedTime = one] : one \in Sample(8) }
        \cup { [ZeroQuoteUpdateAcknowledgementMessage EXCEPT !.quoteUpdateAcknowledgementGroup = one] : one \in SampleLists(OneQuoteUpdateAcknowledgementGroup) }

(***************************************************************************)
(* Quote Update Rejected Message: 25 bytes                                 *)
(***************************************************************************)

QuoteUpdateRejectedMessage ==
    [ transactionTime   : Sample(8),
      quoteUpdateId     : Sample(16),
      quoteRejectReason : Sample(1) ]

EncodeQuoteUpdateRejectedMessage(message) ==
    message.transactionTime
        \o message.quoteUpdateId
        \o message.quoteRejectReason

DecodeQuoteUpdateRejectedMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET quoteUpdateId == ReadBytes(transactionTime.rest, 16) IN IF ~quoteUpdateId.ok THEN Fail ELSE
    LET quoteRejectReason == ReadBytes(quoteUpdateId.rest, 1) IN IF ~quoteRejectReason.ok THEN Fail ELSE
    Ok([ transactionTime   |-> transactionTime.value,
         quoteUpdateId     |-> quoteUpdateId.value,
         quoteRejectReason |-> quoteRejectReason.value ], quoteRejectReason.rest)

ZeroQuoteUpdateRejectedMessage ==
    [ transactionTime   |-> [i \in 1 .. 8 |-> 0],
      quoteUpdateId     |-> [i \in 1 .. 16 |-> 0],
      quoteRejectReason |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Update Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteUpdateRejectedMessage ==
    { ZeroQuoteUpdateRejectedMessage }
        \cup { [ZeroQuoteUpdateRejectedMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroQuoteUpdateRejectedMessage EXCEPT !.quoteUpdateId = one] : one \in Sample(16) }
        \cup { [ZeroQuoteUpdateRejectedMessage EXCEPT !.quoteRejectReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Quote Restated Message: 52 bytes                                        *)
(***************************************************************************)

QuoteRestatedMessage ==
    [ transactionTime   : Sample(8),
      quoteUpdateId     : Sample(16),
      orderId           : Sample(8),
      leavesQty         : Sample(4),
      workingPrice      : Sample(8),
      quoteSymbol       : Sample(6),
      side              : Sample(1),
      restatementReason : Sample(1) ]

EncodeQuoteRestatedMessage(message) ==
    message.transactionTime
        \o message.quoteUpdateId
        \o message.orderId
        \o message.leavesQty
        \o message.workingPrice
        \o message.quoteSymbol
        \o message.side
        \o message.restatementReason

DecodeQuoteRestatedMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET quoteUpdateId == ReadBytes(transactionTime.rest, 16) IN IF ~quoteUpdateId.ok THEN Fail ELSE
    LET orderId == ReadBytes(quoteUpdateId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(orderId.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET workingPrice == ReadBytes(leavesQty.rest, 8) IN IF ~workingPrice.ok THEN Fail ELSE
    LET quoteSymbol == ReadBytes(workingPrice.rest, 6) IN IF ~quoteSymbol.ok THEN Fail ELSE
    LET side == ReadBytes(quoteSymbol.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET restatementReason == ReadBytes(side.rest, 1) IN IF ~restatementReason.ok THEN Fail ELSE
    Ok([ transactionTime   |-> transactionTime.value,
         quoteUpdateId     |-> quoteUpdateId.value,
         orderId           |-> orderId.value,
         leavesQty         |-> leavesQty.value,
         workingPrice      |-> workingPrice.value,
         quoteSymbol       |-> quoteSymbol.value,
         side              |-> side.value,
         restatementReason |-> restatementReason.value ], restatementReason.rest)

ZeroQuoteRestatedMessage ==
    [ transactionTime   |-> [i \in 1 .. 8 |-> 0],
      quoteUpdateId     |-> [i \in 1 .. 16 |-> 0],
      orderId           |-> [i \in 1 .. 8 |-> 0],
      leavesQty         |-> [i \in 1 .. 4 |-> 0],
      workingPrice      |-> [i \in 1 .. 8 |-> 0],
      quoteSymbol       |-> [i \in 1 .. 6 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      restatementReason |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Restated Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteRestatedMessage ==
    { ZeroQuoteRestatedMessage }
        \cup { [ZeroQuoteRestatedMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRestatedMessage EXCEPT !.quoteUpdateId = one] : one \in Sample(16) }
        \cup { [ZeroQuoteRestatedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRestatedMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRestatedMessage EXCEPT !.workingPrice = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRestatedMessage EXCEPT !.quoteSymbol = one] : one \in Sample(6) }
        \cup { [ZeroQuoteRestatedMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRestatedMessage EXCEPT !.restatementReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Quote Execution Message: 71 bytes                                       *)
(***************************************************************************)

QuoteExecutionMessage ==
    [ transactionTime        : Sample(8),
      quoteUpdateId          : Sample(16),
      orderId                : Sample(8),
      execId                 : Sample(8),
      quoteSymbol            : Sample(6),
      clearingFirm           : Sample(4),
      lastShares             : Sample(4),
      lastPx                 : Sample(8),
      leavesQty              : Sample(4),
      side                   : Sample(1),
      baseLiquidityIndicator : Sample(1),
      subLiquidityIndicator  : Sample(1),
      feeCode                : Sample(2) ]

EncodeQuoteExecutionMessage(message) ==
    message.transactionTime
        \o message.quoteUpdateId
        \o message.orderId
        \o message.execId
        \o message.quoteSymbol
        \o message.clearingFirm
        \o message.lastShares
        \o message.lastPx
        \o message.leavesQty
        \o message.side
        \o message.baseLiquidityIndicator
        \o message.subLiquidityIndicator
        \o message.feeCode

DecodeQuoteExecutionMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET quoteUpdateId == ReadBytes(transactionTime.rest, 16) IN IF ~quoteUpdateId.ok THEN Fail ELSE
    LET orderId == ReadBytes(quoteUpdateId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET execId == ReadBytes(orderId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET quoteSymbol == ReadBytes(execId.rest, 6) IN IF ~quoteSymbol.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(quoteSymbol.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET lastShares == ReadBytes(clearingFirm.rest, 4) IN IF ~lastShares.ok THEN Fail ELSE
    LET lastPx == ReadBytes(lastShares.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(lastPx.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET side == ReadBytes(leavesQty.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadBytes(side.rest, 1) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET subLiquidityIndicator == ReadBytes(baseLiquidityIndicator.rest, 1) IN IF ~subLiquidityIndicator.ok THEN Fail ELSE
    LET feeCode == ReadBytes(subLiquidityIndicator.rest, 2) IN IF ~feeCode.ok THEN Fail ELSE
    Ok([ transactionTime        |-> transactionTime.value,
         quoteUpdateId          |-> quoteUpdateId.value,
         orderId                |-> orderId.value,
         execId                 |-> execId.value,
         quoteSymbol            |-> quoteSymbol.value,
         clearingFirm           |-> clearingFirm.value,
         lastShares             |-> lastShares.value,
         lastPx                 |-> lastPx.value,
         leavesQty              |-> leavesQty.value,
         side                   |-> side.value,
         baseLiquidityIndicator |-> baseLiquidityIndicator.value,
         subLiquidityIndicator  |-> subLiquidityIndicator.value,
         feeCode                |-> feeCode.value ], feeCode.rest)

ZeroQuoteExecutionMessage ==
    [ transactionTime        |-> [i \in 1 .. 8 |-> 0],
      quoteUpdateId          |-> [i \in 1 .. 16 |-> 0],
      orderId                |-> [i \in 1 .. 8 |-> 0],
      execId                 |-> [i \in 1 .. 8 |-> 0],
      quoteSymbol            |-> [i \in 1 .. 6 |-> 0],
      clearingFirm           |-> [i \in 1 .. 4 |-> 0],
      lastShares             |-> [i \in 1 .. 4 |-> 0],
      lastPx                 |-> [i \in 1 .. 8 |-> 0],
      leavesQty              |-> [i \in 1 .. 4 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      baseLiquidityIndicator |-> [i \in 1 .. 1 |-> 0],
      subLiquidityIndicator  |-> [i \in 1 .. 1 |-> 0],
      feeCode                |-> [i \in 1 .. 2 |-> 0] ]

(* Quote Execution Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteExecutionMessage ==
    { ZeroQuoteExecutionMessage }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.quoteUpdateId = one] : one \in Sample(16) }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.quoteSymbol = one] : one \in Sample(6) }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.lastShares = one] : one \in Sample(4) }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.baseLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.subLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.feeCode = one] : one \in Sample(2) }

(***************************************************************************)
(* Quote Cancelled Message: 40 bytes                                       *)
(***************************************************************************)

QuoteCancelledMessage ==
    [ transactionTime : Sample(8),
      quoteUpdateId   : Sample(16),
      orderId         : Sample(8),
      quoteSymbol     : Sample(6),
      side            : Sample(1),
      cancelReason    : Sample(1) ]

EncodeQuoteCancelledMessage(message) ==
    message.transactionTime
        \o message.quoteUpdateId
        \o message.orderId
        \o message.quoteSymbol
        \o message.side
        \o message.cancelReason

DecodeQuoteCancelledMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET quoteUpdateId == ReadBytes(transactionTime.rest, 16) IN IF ~quoteUpdateId.ok THEN Fail ELSE
    LET orderId == ReadBytes(quoteUpdateId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET quoteSymbol == ReadBytes(orderId.rest, 6) IN IF ~quoteSymbol.ok THEN Fail ELSE
    LET side == ReadBytes(quoteSymbol.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET cancelReason == ReadBytes(side.rest, 1) IN IF ~cancelReason.ok THEN Fail ELSE
    Ok([ transactionTime |-> transactionTime.value,
         quoteUpdateId   |-> quoteUpdateId.value,
         orderId         |-> orderId.value,
         quoteSymbol     |-> quoteSymbol.value,
         side            |-> side.value,
         cancelReason    |-> cancelReason.value ], cancelReason.rest)

ZeroQuoteCancelledMessage ==
    [ transactionTime |-> [i \in 1 .. 8 |-> 0],
      quoteUpdateId   |-> [i \in 1 .. 16 |-> 0],
      orderId         |-> [i \in 1 .. 8 |-> 0],
      quoteSymbol     |-> [i \in 1 .. 6 |-> 0],
      side            |-> [i \in 1 .. 1 |-> 0],
      cancelReason    |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Cancelled Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteCancelledMessage ==
    { ZeroQuoteCancelledMessage }
        \cup { [ZeroQuoteCancelledMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroQuoteCancelledMessage EXCEPT !.quoteUpdateId = one] : one \in Sample(16) }
        \cup { [ZeroQuoteCancelledMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteCancelledMessage EXCEPT !.quoteSymbol = one] : one \in Sample(6) }
        \cup { [ZeroQuoteCancelledMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroQuoteCancelledMessage EXCEPT !.cancelReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Tas Quote Restatement Message: 54 bytes                                 *)
(***************************************************************************)

TasQuoteRestatementMessage ==
    [ transactionTime : Sample(8),
      quoteUpdateId   : Sample(16),
      execId          : Sample(8),
      quoteSymbol     : Sample(6),
      clearingSymbol  : Sample(8),
      clearingPrice   : Sample(8) ]

EncodeTasQuoteRestatementMessage(message) ==
    message.transactionTime
        \o message.quoteUpdateId
        \o message.execId
        \o message.quoteSymbol
        \o message.clearingSymbol
        \o message.clearingPrice

DecodeTasQuoteRestatementMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET quoteUpdateId == ReadBytes(transactionTime.rest, 16) IN IF ~quoteUpdateId.ok THEN Fail ELSE
    LET execId == ReadBytes(quoteUpdateId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET quoteSymbol == ReadBytes(execId.rest, 6) IN IF ~quoteSymbol.ok THEN Fail ELSE
    LET clearingSymbol == ReadBytes(quoteSymbol.rest, 8) IN IF ~clearingSymbol.ok THEN Fail ELSE
    LET clearingPrice == ReadBytes(clearingSymbol.rest, 8) IN IF ~clearingPrice.ok THEN Fail ELSE
    Ok([ transactionTime |-> transactionTime.value,
         quoteUpdateId   |-> quoteUpdateId.value,
         execId          |-> execId.value,
         quoteSymbol     |-> quoteSymbol.value,
         clearingSymbol  |-> clearingSymbol.value,
         clearingPrice   |-> clearingPrice.value ], clearingPrice.rest)

ZeroTasQuoteRestatementMessage ==
    [ transactionTime |-> [i \in 1 .. 8 |-> 0],
      quoteUpdateId   |-> [i \in 1 .. 16 |-> 0],
      execId          |-> [i \in 1 .. 8 |-> 0],
      quoteSymbol     |-> [i \in 1 .. 6 |-> 0],
      clearingSymbol  |-> [i \in 1 .. 8 |-> 0],
      clearingPrice   |-> [i \in 1 .. 8 |-> 0] ]

(* Tas Quote Restatement Message at zero, then each field in turn at the values it is checked at *)
CheckedTasQuoteRestatementMessage ==
    { ZeroTasQuoteRestatementMessage }
        \cup { [ZeroTasQuoteRestatementMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroTasQuoteRestatementMessage EXCEPT !.quoteUpdateId = one] : one \in Sample(16) }
        \cup { [ZeroTasQuoteRestatementMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroTasQuoteRestatementMessage EXCEPT !.quoteSymbol = one] : one \in Sample(6) }
        \cup { [ZeroTasQuoteRestatementMessage EXCEPT !.clearingSymbol = one] : one \in Sample(8) }
        \cup { [ZeroTasQuoteRestatementMessage EXCEPT !.clearingPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Variance Quote Restatement Message: 58 bytes                            *)
(***************************************************************************)

VarianceQuoteRestatementMessage ==
    [ transactionTime : Sample(8),
      quoteUpdateId   : Sample(16),
      execId          : Sample(8),
      quoteSymbol     : Sample(6),
      clearingSymbol  : Sample(8),
      clearingPrice   : Sample(8),
      clearingSize    : Sample(4) ]

EncodeVarianceQuoteRestatementMessage(message) ==
    message.transactionTime
        \o message.quoteUpdateId
        \o message.execId
        \o message.quoteSymbol
        \o message.clearingSymbol
        \o message.clearingPrice
        \o message.clearingSize

DecodeVarianceQuoteRestatementMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET quoteUpdateId == ReadBytes(transactionTime.rest, 16) IN IF ~quoteUpdateId.ok THEN Fail ELSE
    LET execId == ReadBytes(quoteUpdateId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET quoteSymbol == ReadBytes(execId.rest, 6) IN IF ~quoteSymbol.ok THEN Fail ELSE
    LET clearingSymbol == ReadBytes(quoteSymbol.rest, 8) IN IF ~clearingSymbol.ok THEN Fail ELSE
    LET clearingPrice == ReadBytes(clearingSymbol.rest, 8) IN IF ~clearingPrice.ok THEN Fail ELSE
    LET clearingSize == ReadBytes(clearingPrice.rest, 4) IN IF ~clearingSize.ok THEN Fail ELSE
    Ok([ transactionTime |-> transactionTime.value,
         quoteUpdateId   |-> quoteUpdateId.value,
         execId          |-> execId.value,
         quoteSymbol     |-> quoteSymbol.value,
         clearingSymbol  |-> clearingSymbol.value,
         clearingPrice   |-> clearingPrice.value,
         clearingSize    |-> clearingSize.value ], clearingSize.rest)

ZeroVarianceQuoteRestatementMessage ==
    [ transactionTime |-> [i \in 1 .. 8 |-> 0],
      quoteUpdateId   |-> [i \in 1 .. 16 |-> 0],
      execId          |-> [i \in 1 .. 8 |-> 0],
      quoteSymbol     |-> [i \in 1 .. 6 |-> 0],
      clearingSymbol  |-> [i \in 1 .. 8 |-> 0],
      clearingPrice   |-> [i \in 1 .. 8 |-> 0],
      clearingSize    |-> [i \in 1 .. 4 |-> 0] ]

(* Variance Quote Restatement Message at zero, then each field in turn at the values it is checked at *)
CheckedVarianceQuoteRestatementMessage ==
    { ZeroVarianceQuoteRestatementMessage }
        \cup { [ZeroVarianceQuoteRestatementMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroVarianceQuoteRestatementMessage EXCEPT !.quoteUpdateId = one] : one \in Sample(16) }
        \cup { [ZeroVarianceQuoteRestatementMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroVarianceQuoteRestatementMessage EXCEPT !.quoteSymbol = one] : one \in Sample(6) }
        \cup { [ZeroVarianceQuoteRestatementMessage EXCEPT !.clearingSymbol = one] : one \in Sample(8) }
        \cup { [ZeroVarianceQuoteRestatementMessage EXCEPT !.clearingPrice = one] : one \in Sample(8) }
        \cup { [ZeroVarianceQuoteRestatementMessage EXCEPT !.clearingSize = one] : one \in Sample(4) }

(***************************************************************************)
(* Reset Risk Acknowledgement Message: 25 bytes                            *)
(***************************************************************************)

ResetRiskAcknowledgementMessage ==
    [ riskStatusId        : Sample(16),
      riskResetResult     : Sample(1),
      requestReceivedTime : Sample(8) ]

EncodeResetRiskAcknowledgementMessage(message) ==
    message.riskStatusId
        \o message.riskResetResult
        \o message.requestReceivedTime

DecodeResetRiskAcknowledgementMessage(bytes) ==
    LET riskStatusId == ReadBytes(bytes, 16) IN IF ~riskStatusId.ok THEN Fail ELSE
    LET riskResetResult == ReadBytes(riskStatusId.rest, 1) IN IF ~riskResetResult.ok THEN Fail ELSE
    LET requestReceivedTime == ReadBytes(riskResetResult.rest, 8) IN IF ~requestReceivedTime.ok THEN Fail ELSE
    Ok([ riskStatusId        |-> riskStatusId.value,
         riskResetResult     |-> riskResetResult.value,
         requestReceivedTime |-> requestReceivedTime.value ], requestReceivedTime.rest)

ZeroResetRiskAcknowledgementMessage ==
    [ riskStatusId        |-> [i \in 1 .. 16 |-> 0],
      riskResetResult     |-> [i \in 1 .. 1 |-> 0],
      requestReceivedTime |-> [i \in 1 .. 8 |-> 0] ]

(* Reset Risk Acknowledgement Message at zero, then each field in turn at the values it is checked at *)
CheckedResetRiskAcknowledgementMessage ==
    { ZeroResetRiskAcknowledgementMessage }
        \cup { [ZeroResetRiskAcknowledgementMessage EXCEPT !.riskStatusId = one] : one \in Sample(16) }
        \cup { [ZeroResetRiskAcknowledgementMessage EXCEPT !.riskResetResult = one] : one \in Sample(1) }
        \cup { [ZeroResetRiskAcknowledgementMessage EXCEPT !.requestReceivedTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Exchange Message, selected by Exchange Message Type                     *)
(***************************************************************************)

LoginResponseMessageCode == 501  \* 0x1f5
ReplayCompleteCode == 502  \* 0x1f6
LogoutResponseMessageCode == 503  \* 0x1f7
ServerHeartbeatCode == 504  \* 0x1f8
OrderAcknowledgementMessageCode == 1501  \* 0x5dd
OrderRejectedMessageCode == 1502  \* 0x5de
OrderModifiedMessageCode == 1503  \* 0x5df
ModifyRejectedMessageCode == 1504  \* 0x5e0
OrderExecutionMessageCode == 1505  \* 0x5e1
OrderCancelledMessageCode == 1506  \* 0x5e2
CancelRejectedMessageCode == 1507  \* 0x5e3
MassCancelAcknowledgementMessageCode == 1508  \* 0x5e4
MassCancelRejectedMessageCode == 1509  \* 0x5e5
PurgeAcknowledgementMessageCode == 1510  \* 0x5e6
PurgeRejectedMessageCode == 1511  \* 0x5e7
TradeCancelOrCorrectMessageCode == 1512  \* 0x5e8
TasRestatementMessageCode == 1513  \* 0x5e9
VarianceRestatementMessageCode == 1514  \* 0x5ea
QuoteUpdateAcknowledgementMessageCode == 1515  \* 0x5eb
QuoteUpdateRejectedMessageCode == 1516  \* 0x5ec
QuoteRestatedMessageCode == 1517  \* 0x5ed
QuoteExecutionMessageCode == 1518  \* 0x5ee
QuoteCancelledMessageCode == 1519  \* 0x5ef
TasQuoteRestatementMessageCode == 1520  \* 0x5f0
VarianceQuoteRestatementMessageCode == 1521  \* 0x5f1
ResetRiskAcknowledgementMessageCode == 1522  \* 0x5f2

ExchangeMessage ==
    [ tag : {LoginResponseMessageCode}, body : LoginResponseMessage ]
        \cup [ tag : {ReplayCompleteCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {LogoutResponseMessageCode}, body : LogoutResponseMessage ]
        \cup [ tag : {ServerHeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {OrderAcknowledgementMessageCode}, body : OrderAcknowledgementMessage ]
        \cup [ tag : {OrderRejectedMessageCode}, body : OrderRejectedMessage ]
        \cup [ tag : {OrderModifiedMessageCode}, body : OrderModifiedMessage ]
        \cup [ tag : {ModifyRejectedMessageCode}, body : ModifyRejectedMessage ]
        \cup [ tag : {OrderExecutionMessageCode}, body : OrderExecutionMessage ]
        \cup [ tag : {OrderCancelledMessageCode}, body : OrderCancelledMessage ]
        \cup [ tag : {CancelRejectedMessageCode}, body : CancelRejectedMessage ]
        \cup [ tag : {MassCancelAcknowledgementMessageCode}, body : MassCancelAcknowledgementMessage ]
        \cup [ tag : {MassCancelRejectedMessageCode}, body : MassCancelRejectedMessage ]
        \cup [ tag : {PurgeAcknowledgementMessageCode}, body : PurgeAcknowledgementMessage ]
        \cup [ tag : {PurgeRejectedMessageCode}, body : PurgeRejectedMessage ]
        \cup [ tag : {TradeCancelOrCorrectMessageCode}, body : TradeCancelOrCorrectMessage ]
        \cup [ tag : {TasRestatementMessageCode}, body : TasRestatementMessage ]
        \cup [ tag : {VarianceRestatementMessageCode}, body : VarianceRestatementMessage ]
        \cup [ tag : {QuoteUpdateAcknowledgementMessageCode}, body : QuoteUpdateAcknowledgementMessage ]
        \cup [ tag : {QuoteUpdateRejectedMessageCode}, body : QuoteUpdateRejectedMessage ]
        \cup [ tag : {QuoteRestatedMessageCode}, body : QuoteRestatedMessage ]
        \cup [ tag : {QuoteExecutionMessageCode}, body : QuoteExecutionMessage ]
        \cup [ tag : {QuoteCancelledMessageCode}, body : QuoteCancelledMessage ]
        \cup [ tag : {TasQuoteRestatementMessageCode}, body : TasQuoteRestatementMessage ]
        \cup [ tag : {VarianceQuoteRestatementMessageCode}, body : VarianceQuoteRestatementMessage ]
        \cup [ tag : {ResetRiskAcknowledgementMessageCode}, body : ResetRiskAcknowledgementMessage ]

EncodeExchangeMessage(message) ==
    CASE message.tag = LoginResponseMessageCode -> EncodeLoginResponseMessage(message.body)
      [] message.tag = ReplayCompleteCode -> << >>
      [] message.tag = LogoutResponseMessageCode -> EncodeLogoutResponseMessage(message.body)
      [] message.tag = ServerHeartbeatCode -> << >>
      [] message.tag = OrderAcknowledgementMessageCode -> EncodeOrderAcknowledgementMessage(message.body)
      [] message.tag = OrderRejectedMessageCode -> EncodeOrderRejectedMessage(message.body)
      [] message.tag = OrderModifiedMessageCode -> EncodeOrderModifiedMessage(message.body)
      [] message.tag = ModifyRejectedMessageCode -> EncodeModifyRejectedMessage(message.body)
      [] message.tag = OrderExecutionMessageCode -> EncodeOrderExecutionMessage(message.body)
      [] message.tag = OrderCancelledMessageCode -> EncodeOrderCancelledMessage(message.body)
      [] message.tag = CancelRejectedMessageCode -> EncodeCancelRejectedMessage(message.body)
      [] message.tag = MassCancelAcknowledgementMessageCode -> EncodeMassCancelAcknowledgementMessage(message.body)
      [] message.tag = MassCancelRejectedMessageCode -> EncodeMassCancelRejectedMessage(message.body)
      [] message.tag = PurgeAcknowledgementMessageCode -> EncodePurgeAcknowledgementMessage(message.body)
      [] message.tag = PurgeRejectedMessageCode -> EncodePurgeRejectedMessage(message.body)
      [] message.tag = TradeCancelOrCorrectMessageCode -> EncodeTradeCancelOrCorrectMessage(message.body)
      [] message.tag = TasRestatementMessageCode -> EncodeTasRestatementMessage(message.body)
      [] message.tag = VarianceRestatementMessageCode -> EncodeVarianceRestatementMessage(message.body)
      [] message.tag = QuoteUpdateAcknowledgementMessageCode -> EncodeQuoteUpdateAcknowledgementMessage(message.body)
      [] message.tag = QuoteUpdateRejectedMessageCode -> EncodeQuoteUpdateRejectedMessage(message.body)
      [] message.tag = QuoteRestatedMessageCode -> EncodeQuoteRestatedMessage(message.body)
      [] message.tag = QuoteExecutionMessageCode -> EncodeQuoteExecutionMessage(message.body)
      [] message.tag = QuoteCancelledMessageCode -> EncodeQuoteCancelledMessage(message.body)
      [] message.tag = TasQuoteRestatementMessageCode -> EncodeTasQuoteRestatementMessage(message.body)
      [] message.tag = VarianceQuoteRestatementMessageCode -> EncodeVarianceQuoteRestatementMessage(message.body)
      [] message.tag = ResetRiskAcknowledgementMessageCode -> EncodeResetRiskAcknowledgementMessage(message.body)

DecodeExchangeMessage(tag, bytes) ==
    LET read ==
            CASE tag = LoginResponseMessageCode -> DecodeLoginResponseMessage(bytes)
              [] tag = ReplayCompleteCode -> Ok([empty |-> 0], bytes)
              [] tag = LogoutResponseMessageCode -> DecodeLogoutResponseMessage(bytes)
              [] tag = ServerHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = OrderAcknowledgementMessageCode -> DecodeOrderAcknowledgementMessage(bytes)
              [] tag = OrderRejectedMessageCode -> DecodeOrderRejectedMessage(bytes)
              [] tag = OrderModifiedMessageCode -> DecodeOrderModifiedMessage(bytes)
              [] tag = ModifyRejectedMessageCode -> DecodeModifyRejectedMessage(bytes)
              [] tag = OrderExecutionMessageCode -> DecodeOrderExecutionMessage(bytes)
              [] tag = OrderCancelledMessageCode -> DecodeOrderCancelledMessage(bytes)
              [] tag = CancelRejectedMessageCode -> DecodeCancelRejectedMessage(bytes)
              [] tag = MassCancelAcknowledgementMessageCode -> DecodeMassCancelAcknowledgementMessage(bytes)
              [] tag = MassCancelRejectedMessageCode -> DecodeMassCancelRejectedMessage(bytes)
              [] tag = PurgeAcknowledgementMessageCode -> DecodePurgeAcknowledgementMessage(bytes)
              [] tag = PurgeRejectedMessageCode -> DecodePurgeRejectedMessage(bytes)
              [] tag = TradeCancelOrCorrectMessageCode -> DecodeTradeCancelOrCorrectMessage(bytes)
              [] tag = TasRestatementMessageCode -> DecodeTasRestatementMessage(bytes)
              [] tag = VarianceRestatementMessageCode -> DecodeVarianceRestatementMessage(bytes)
              [] tag = QuoteUpdateAcknowledgementMessageCode -> DecodeQuoteUpdateAcknowledgementMessage(bytes)
              [] tag = QuoteUpdateRejectedMessageCode -> DecodeQuoteUpdateRejectedMessage(bytes)
              [] tag = QuoteRestatedMessageCode -> DecodeQuoteRestatedMessage(bytes)
              [] tag = QuoteExecutionMessageCode -> DecodeQuoteExecutionMessage(bytes)
              [] tag = QuoteCancelledMessageCode -> DecodeQuoteCancelledMessage(bytes)
              [] tag = TasQuoteRestatementMessageCode -> DecodeTasQuoteRestatementMessage(bytes)
              [] tag = VarianceQuoteRestatementMessageCode -> DecodeVarianceQuoteRestatementMessage(bytes)
              [] tag = ResetRiskAcknowledgementMessageCode -> DecodeResetRiskAcknowledgementMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroExchangeMessage == [tag |-> LoginResponseMessageCode, body |-> ZeroLoginResponseMessage]

(* Each Exchange Message in turn, at the values the message it names is checked at *)
CheckedExchangeMessage ==
    { [tag |-> LoginResponseMessageCode, body |-> one] : one \in CheckedLoginResponseMessage }
        \cup { [tag |-> ReplayCompleteCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> LogoutResponseMessageCode, body |-> one] : one \in CheckedLogoutResponseMessage }
        \cup { [tag |-> ServerHeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> OrderAcknowledgementMessageCode, body |-> one] : one \in CheckedOrderAcknowledgementMessage }
        \cup { [tag |-> OrderRejectedMessageCode, body |-> one] : one \in CheckedOrderRejectedMessage }
        \cup { [tag |-> OrderModifiedMessageCode, body |-> one] : one \in CheckedOrderModifiedMessage }
        \cup { [tag |-> ModifyRejectedMessageCode, body |-> one] : one \in CheckedModifyRejectedMessage }
        \cup { [tag |-> OrderExecutionMessageCode, body |-> one] : one \in CheckedOrderExecutionMessage }
        \cup { [tag |-> OrderCancelledMessageCode, body |-> one] : one \in CheckedOrderCancelledMessage }
        \cup { [tag |-> CancelRejectedMessageCode, body |-> one] : one \in CheckedCancelRejectedMessage }
        \cup { [tag |-> MassCancelAcknowledgementMessageCode, body |-> one] : one \in CheckedMassCancelAcknowledgementMessage }
        \cup { [tag |-> MassCancelRejectedMessageCode, body |-> one] : one \in CheckedMassCancelRejectedMessage }
        \cup { [tag |-> PurgeAcknowledgementMessageCode, body |-> one] : one \in CheckedPurgeAcknowledgementMessage }
        \cup { [tag |-> PurgeRejectedMessageCode, body |-> one] : one \in CheckedPurgeRejectedMessage }
        \cup { [tag |-> TradeCancelOrCorrectMessageCode, body |-> one] : one \in CheckedTradeCancelOrCorrectMessage }
        \cup { [tag |-> TasRestatementMessageCode, body |-> one] : one \in CheckedTasRestatementMessage }
        \cup { [tag |-> VarianceRestatementMessageCode, body |-> one] : one \in CheckedVarianceRestatementMessage }
        \cup { [tag |-> QuoteUpdateAcknowledgementMessageCode, body |-> one] : one \in CheckedQuoteUpdateAcknowledgementMessage }
        \cup { [tag |-> QuoteUpdateRejectedMessageCode, body |-> one] : one \in CheckedQuoteUpdateRejectedMessage }
        \cup { [tag |-> QuoteRestatedMessageCode, body |-> one] : one \in CheckedQuoteRestatedMessage }
        \cup { [tag |-> QuoteExecutionMessageCode, body |-> one] : one \in CheckedQuoteExecutionMessage }
        \cup { [tag |-> QuoteCancelledMessageCode, body |-> one] : one \in CheckedQuoteCancelledMessage }
        \cup { [tag |-> TasQuoteRestatementMessageCode, body |-> one] : one \in CheckedTasQuoteRestatementMessage }
        \cup { [tag |-> VarianceQuoteRestatementMessageCode, body |-> one] : one \in CheckedVarianceQuoteRestatementMessage }
        \cup { [tag |-> ResetRiskAcknowledgementMessageCode, body |-> one] : one \in CheckedResetRiskAcknowledgementMessage }

(***************************************************************************)
(* Exchange Packet                                                         *)
(***************************************************************************)

ExchangePacket ==
    [ startOfMessage  : Sample(2),
      messageLength   : Sample(2),
      matchingUnit    : Sample(1),
      reservedField   : Sample(1),
      sequenceNumber  : Sample(4),
      exchangeMessage : ExchangeMessage ]

EncodeExchangePacket(message) ==
    message.startOfMessage
        \o message.messageLength
        \o EncodeUIntLE(message.exchangeMessage.tag, 2)
        \o message.matchingUnit
        \o message.reservedField
        \o message.sequenceNumber
        \o EncodeExchangeMessage(message.exchangeMessage)

DecodeExchangePacket(bytes) ==
    LET startOfMessage == ReadBytes(bytes, 2) IN IF ~startOfMessage.ok THEN Fail ELSE
    LET messageLength == ReadBytes(startOfMessage.rest, 2) IN IF ~messageLength.ok THEN Fail ELSE
    LET exchangeMessageType == ReadUIntLE(messageLength.rest, 2) IN IF ~exchangeMessageType.ok THEN Fail ELSE
    LET matchingUnit == ReadBytes(exchangeMessageType.rest, 1) IN IF ~matchingUnit.ok THEN Fail ELSE
    LET reservedField == ReadBytes(matchingUnit.rest, 1) IN IF ~reservedField.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(reservedField.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET exchangeMessage == DecodeExchangeMessage(exchangeMessageType.value, sequenceNumber.rest) IN IF ~exchangeMessage.ok THEN Fail ELSE
    Ok([ startOfMessage  |-> startOfMessage.value,
         messageLength   |-> messageLength.value,
         matchingUnit    |-> matchingUnit.value,
         reservedField   |-> reservedField.value,
         sequenceNumber  |-> sequenceNumber.value,
         exchangeMessage |-> exchangeMessage.value ], exchangeMessage.rest)

ZeroExchangePacket ==
    [ startOfMessage  |-> [i \in 1 .. 2 |-> 0],
      messageLength   |-> [i \in 1 .. 2 |-> 0],
      matchingUnit    |-> [i \in 1 .. 1 |-> 0],
      reservedField   |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber  |-> [i \in 1 .. 4 |-> 0],
      exchangeMessage |-> ZeroExchangeMessage ]

(* Exchange Packet at zero, then each field in turn at the values it is checked at *)
CheckedExchangePacket ==
    { ZeroExchangePacket }
        \cup { [ZeroExchangePacket EXCEPT !.startOfMessage = one] : one \in Sample(2) }
        \cup { [ZeroExchangePacket EXCEPT !.messageLength = one] : one \in Sample(2) }
        \cup { [ZeroExchangePacket EXCEPT !.matchingUnit = one] : one \in Sample(1) }
        \cup { [ZeroExchangePacket EXCEPT !.reservedField = one] : one \in Sample(1) }
        \cup { [ZeroExchangePacket EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroExchangePacket EXCEPT !.exchangeMessage = one] : one \in CheckedExchangeMessage }

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

(* Every Unit Sequence decodes back to what was encoded, and leaves nothing over *)
RoundTripUnitSequence ==
    \A message \in CheckedUnitSequence :
        LET read == DecodeUnitSequence(EncodeUnitSequence(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginResponseMessage ==
    \A message \in CheckedLoginResponseMessage :
        LET read == DecodeLoginResponseMessage(EncodeLoginResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logout Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogoutResponseMessage ==
    \A message \in CheckedLogoutResponseMessage :
        LET read == DecodeLogoutResponseMessage(EncodeLogoutResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Prevent Match decodes back to what was encoded, and leaves nothing over *)
RoundTripPreventMatch ==
    \A message \in CheckedPreventMatch :
        LET read == DecodePreventMatch(EncodePreventMatch(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Acknowledgement Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderAcknowledgementMessage ==
    \A message \in CheckedOrderAcknowledgementMessage :
        LET read == DecodeOrderAcknowledgementMessage(EncodeOrderAcknowledgementMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderRejectedMessage ==
    \A message \in CheckedOrderRejectedMessage :
        LET read == DecodeOrderRejectedMessage(EncodeOrderRejectedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Modified Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderModifiedMessage ==
    \A message \in CheckedOrderModifiedMessage :
        LET read == DecodeOrderModifiedMessage(EncodeOrderModifiedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyRejectedMessage ==
    \A message \in CheckedModifyRejectedMessage :
        LET read == DecodeModifyRejectedMessage(EncodeModifyRejectedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Execution Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutionMessage ==
    \A message \in CheckedOrderExecutionMessage :
        LET read == DecodeOrderExecutionMessage(EncodeOrderExecutionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancelled Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelledMessage ==
    \A message \in CheckedOrderCancelledMessage :
        LET read == DecodeOrderCancelledMessage(EncodeOrderCancelledMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelRejectedMessage ==
    \A message \in CheckedCancelRejectedMessage :
        LET read == DecodeCancelRejectedMessage(EncodeCancelRejectedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Cancel Acknowledgement Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMassCancelAcknowledgementMessage ==
    \A message \in CheckedMassCancelAcknowledgementMessage :
        LET read == DecodeMassCancelAcknowledgementMessage(EncodeMassCancelAcknowledgementMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Cancel Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMassCancelRejectedMessage ==
    \A message \in CheckedMassCancelRejectedMessage :
        LET read == DecodeMassCancelRejectedMessage(EncodeMassCancelRejectedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Purge Acknowledgement Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPurgeAcknowledgementMessage ==
    \A message \in CheckedPurgeAcknowledgementMessage :
        LET read == DecodePurgeAcknowledgementMessage(EncodePurgeAcknowledgementMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Purge Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPurgeRejectedMessage ==
    \A message \in CheckedPurgeRejectedMessage :
        LET read == DecodePurgeRejectedMessage(EncodePurgeRejectedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Cancel Or Correct Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCancelOrCorrectMessage ==
    \A message \in CheckedTradeCancelOrCorrectMessage :
        LET read == DecodeTradeCancelOrCorrectMessage(EncodeTradeCancelOrCorrectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tas Restatement Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTasRestatementMessage ==
    \A message \in CheckedTasRestatementMessage :
        LET read == DecodeTasRestatementMessage(EncodeTasRestatementMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Variance Restatement Message decodes back to what was encoded, and leaves nothing over *)
RoundTripVarianceRestatementMessage ==
    \A message \in CheckedVarianceRestatementMessage :
        LET read == DecodeVarianceRestatementMessage(EncodeVarianceRestatementMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Update Acknowledgement Group decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteUpdateAcknowledgementGroup ==
    \A message \in CheckedQuoteUpdateAcknowledgementGroup :
        LET read == DecodeQuoteUpdateAcknowledgementGroup(EncodeQuoteUpdateAcknowledgementGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Update Acknowledgement Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteUpdateAcknowledgementMessage ==
    \A message \in CheckedQuoteUpdateAcknowledgementMessage :
        LET read == DecodeQuoteUpdateAcknowledgementMessage(EncodeQuoteUpdateAcknowledgementMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Update Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteUpdateRejectedMessage ==
    \A message \in CheckedQuoteUpdateRejectedMessage :
        LET read == DecodeQuoteUpdateRejectedMessage(EncodeQuoteUpdateRejectedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Restated Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteRestatedMessage ==
    \A message \in CheckedQuoteRestatedMessage :
        LET read == DecodeQuoteRestatedMessage(EncodeQuoteRestatedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Execution Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteExecutionMessage ==
    \A message \in CheckedQuoteExecutionMessage :
        LET read == DecodeQuoteExecutionMessage(EncodeQuoteExecutionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Cancelled Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteCancelledMessage ==
    \A message \in CheckedQuoteCancelledMessage :
        LET read == DecodeQuoteCancelledMessage(EncodeQuoteCancelledMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tas Quote Restatement Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTasQuoteRestatementMessage ==
    \A message \in CheckedTasQuoteRestatementMessage :
        LET read == DecodeTasQuoteRestatementMessage(EncodeTasQuoteRestatementMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Variance Quote Restatement Message decodes back to what was encoded, and leaves nothing over *)
RoundTripVarianceQuoteRestatementMessage ==
    \A message \in CheckedVarianceQuoteRestatementMessage :
        LET read == DecodeVarianceQuoteRestatementMessage(EncodeVarianceQuoteRestatementMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reset Risk Acknowledgement Message decodes back to what was encoded, and leaves nothing over *)
RoundTripResetRiskAcknowledgementMessage ==
    \A message \in CheckedResetRiskAcknowledgementMessage :
        LET read == DecodeResetRiskAcknowledgementMessage(EncodeResetRiskAcknowledgementMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Exchange Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripExchangePacket ==
    \A message \in CheckedExchangePacket :
        LET read == DecodeExchangePacket(EncodeExchangePacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Exchange Message is selected by the Exchange Message Type it is written under *)
SelectsExchangeMessage ==
    \A message \in CheckedExchangeMessage :
        LET read == DecodeExchangeMessage(message.tag, EncodeExchangeMessage(message))
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
