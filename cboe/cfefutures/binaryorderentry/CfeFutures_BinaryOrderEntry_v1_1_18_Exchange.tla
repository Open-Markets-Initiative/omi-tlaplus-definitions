----------- MODULE CfeFutures_BinaryOrderEntry_v1_1_18_Exchange ------------
(***************************************************************************)
(* Chicago Board Options Exchange Futures Binary Order Entry v1.1.18       *)
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
(* Order Acknowledgement: 161 bytes                                        *)
(***************************************************************************)

OrderAcknowledgement ==
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

EncodeOrderAcknowledgement(message) ==
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

DecodeOrderAcknowledgement(bytes) ==
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

ZeroOrderAcknowledgement ==
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

(* Order Acknowledgement at zero, then each field in turn at the values it is checked at *)
CheckedOrderAcknowledgement ==
    { ZeroOrderAcknowledgement }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.account = one] : one \in Sample(16) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.clearingAccount = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.preventMatch = one] : one \in CheckedPreventMatch }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.maturityDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.baseLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.expireTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.subLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.cmtaNumber = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.ctiCode = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.oeoId = one] : one \in Sample(18) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.frequentTraderId = one] : one \in Sample(6) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.custOrderHandlingInst = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.requestReceivedTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Prevent Match: 3 bytes                                                  *)
(***************************************************************************)

PreventMatch2 ==
    [ mtpModifier    : Sample(1),
      uniqueIdLevel  : Sample(1),
      tradingGroupId : Sample(1) ]

EncodePreventMatch2(message) ==
    message.mtpModifier
        \o message.uniqueIdLevel
        \o message.tradingGroupId

DecodePreventMatch2(bytes) ==
    LET mtpModifier == ReadBytes(bytes, 1) IN IF ~mtpModifier.ok THEN Fail ELSE
    LET uniqueIdLevel == ReadBytes(mtpModifier.rest, 1) IN IF ~uniqueIdLevel.ok THEN Fail ELSE
    LET tradingGroupId == ReadBytes(uniqueIdLevel.rest, 1) IN IF ~tradingGroupId.ok THEN Fail ELSE
    Ok([ mtpModifier    |-> mtpModifier.value,
         uniqueIdLevel  |-> uniqueIdLevel.value,
         tradingGroupId |-> tradingGroupId.value ], tradingGroupId.rest)

ZeroPreventMatch2 ==
    [ mtpModifier    |-> [i \in 1 .. 1 |-> 0],
      uniqueIdLevel  |-> [i \in 1 .. 1 |-> 0],
      tradingGroupId |-> [i \in 1 .. 1 |-> 0] ]

(* Prevent Match at zero, then each field in turn at the values it is checked at *)
CheckedPreventMatch2 ==
    { ZeroPreventMatch2 }
        \cup { [ZeroPreventMatch2 EXCEPT !.mtpModifier = one] : one \in Sample(1) }
        \cup { [ZeroPreventMatch2 EXCEPT !.uniqueIdLevel = one] : one \in Sample(1) }
        \cup { [ZeroPreventMatch2 EXCEPT !.tradingGroupId = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Acknowledgement Option: 165 bytes                                 *)
(***************************************************************************)

OrderAcknowledgementOption ==
    [ transactionTime        : Sample(8),
      clOrdId                : Sample(20),
      orderId                : Sample(8),
      side                   : Sample(1),
      price                  : Sample(8),
      ordType                : Sample(1),
      timeInForce            : Sample(1),
      symbol                 : Sample(8),
      securityDesc           : Sample(16),
      capacity               : Sample(1),
      account                : Sample(16),
      clearingFirm           : Sample(4),
      clearingAccount        : Sample(4),
      orderQty               : Sample(4),
      preventMatch           : PreventMatch2,
      openClose              : Sample(1),
      leavesQty              : Sample(4),
      baseLiquidityIndicator : Sample(1),
      expireTime             : Sample(8),
      subLiquidityIndicator  : Sample(1),
      cmtaNumber             : Sample(4),
      ctiCode                : Sample(1),
      manualOrderIndicator   : Sample(1),
      oeoId                  : Sample(18),
      cumQty                 : Sample(4),
      frequentTraderId       : Sample(6),
      custOrderHandlingInst  : Sample(1),
      countryCode            : Sample(2),
      requestReceivedTime    : Sample(8),
      legCnt                 : 0 .. 255,
      legPositionEffect      : Sample(1) ]

EncodeOrderAcknowledgementOption(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.orderId
        \o message.side
        \o message.price
        \o message.ordType
        \o message.timeInForce
        \o message.symbol
        \o message.securityDesc
        \o message.capacity
        \o message.account
        \o message.clearingFirm
        \o message.clearingAccount
        \o message.orderQty
        \o EncodePreventMatch2(message.preventMatch)
        \o message.openClose
        \o message.leavesQty
        \o message.baseLiquidityIndicator
        \o message.expireTime
        \o message.subLiquidityIndicator
        \o message.cmtaNumber
        \o message.ctiCode
        \o message.manualOrderIndicator
        \o message.oeoId
        \o message.cumQty
        \o message.frequentTraderId
        \o message.custOrderHandlingInst
        \o message.countryCode
        \o message.requestReceivedTime
        \o EncodeUIntLE(message.legCnt, 1)
        \o message.legPositionEffect

DecodeOrderAcknowledgementOption(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clOrdId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET side == ReadBytes(orderId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadBytes(side.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET ordType == ReadBytes(price.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(ordType.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET symbol == ReadBytes(timeInForce.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET securityDesc == ReadBytes(symbol.rest, 16) IN IF ~securityDesc.ok THEN Fail ELSE
    LET capacity == ReadBytes(securityDesc.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadBytes(capacity.rest, 16) IN IF ~account.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(account.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadBytes(clearingFirm.rest, 4) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET orderQty == ReadBytes(clearingAccount.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET preventMatch == DecodePreventMatch2(orderQty.rest) IN IF ~preventMatch.ok THEN Fail ELSE
    LET openClose == ReadBytes(preventMatch.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(openClose.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadBytes(leavesQty.rest, 1) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET expireTime == ReadBytes(baseLiquidityIndicator.rest, 8) IN IF ~expireTime.ok THEN Fail ELSE
    LET subLiquidityIndicator == ReadBytes(expireTime.rest, 1) IN IF ~subLiquidityIndicator.ok THEN Fail ELSE
    LET cmtaNumber == ReadBytes(subLiquidityIndicator.rest, 4) IN IF ~cmtaNumber.ok THEN Fail ELSE
    LET ctiCode == ReadBytes(cmtaNumber.rest, 1) IN IF ~ctiCode.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadBytes(ctiCode.rest, 1) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET oeoId == ReadBytes(manualOrderIndicator.rest, 18) IN IF ~oeoId.ok THEN Fail ELSE
    LET cumQty == ReadBytes(oeoId.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET frequentTraderId == ReadBytes(cumQty.rest, 6) IN IF ~frequentTraderId.ok THEN Fail ELSE
    LET custOrderHandlingInst == ReadBytes(frequentTraderId.rest, 1) IN IF ~custOrderHandlingInst.ok THEN Fail ELSE
    LET countryCode == ReadBytes(custOrderHandlingInst.rest, 2) IN IF ~countryCode.ok THEN Fail ELSE
    LET requestReceivedTime == ReadBytes(countryCode.rest, 8) IN IF ~requestReceivedTime.ok THEN Fail ELSE
    LET legCnt == ReadUIntLE(requestReceivedTime.rest, 1) IN IF ~legCnt.ok THEN Fail ELSE
    LET legPositionEffect == ReadBytes(legCnt.rest, 1) IN IF ~legPositionEffect.ok THEN Fail ELSE
    Ok([ transactionTime        |-> transactionTime.value,
         clOrdId                |-> clOrdId.value,
         orderId                |-> orderId.value,
         side                   |-> side.value,
         price                  |-> price.value,
         ordType                |-> ordType.value,
         timeInForce            |-> timeInForce.value,
         symbol                 |-> symbol.value,
         securityDesc           |-> securityDesc.value,
         capacity               |-> capacity.value,
         account                |-> account.value,
         clearingFirm           |-> clearingFirm.value,
         clearingAccount        |-> clearingAccount.value,
         orderQty               |-> orderQty.value,
         preventMatch           |-> preventMatch.value,
         openClose              |-> openClose.value,
         leavesQty              |-> leavesQty.value,
         baseLiquidityIndicator |-> baseLiquidityIndicator.value,
         expireTime             |-> expireTime.value,
         subLiquidityIndicator  |-> subLiquidityIndicator.value,
         cmtaNumber             |-> cmtaNumber.value,
         ctiCode                |-> ctiCode.value,
         manualOrderIndicator   |-> manualOrderIndicator.value,
         oeoId                  |-> oeoId.value,
         cumQty                 |-> cumQty.value,
         frequentTraderId       |-> frequentTraderId.value,
         custOrderHandlingInst  |-> custOrderHandlingInst.value,
         countryCode            |-> countryCode.value,
         requestReceivedTime    |-> requestReceivedTime.value,
         legCnt                 |-> legCnt.value,
         legPositionEffect      |-> legPositionEffect.value ], legPositionEffect.rest)

ZeroOrderAcknowledgementOption ==
    [ transactionTime        |-> [i \in 1 .. 8 |-> 0],
      clOrdId                |-> [i \in 1 .. 20 |-> 0],
      orderId                |-> [i \in 1 .. 8 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      price                  |-> [i \in 1 .. 8 |-> 0],
      ordType                |-> [i \in 1 .. 1 |-> 0],
      timeInForce            |-> [i \in 1 .. 1 |-> 0],
      symbol                 |-> [i \in 1 .. 8 |-> 0],
      securityDesc           |-> [i \in 1 .. 16 |-> 0],
      capacity               |-> [i \in 1 .. 1 |-> 0],
      account                |-> [i \in 1 .. 16 |-> 0],
      clearingFirm           |-> [i \in 1 .. 4 |-> 0],
      clearingAccount        |-> [i \in 1 .. 4 |-> 0],
      orderQty               |-> [i \in 1 .. 4 |-> 0],
      preventMatch           |-> ZeroPreventMatch2,
      openClose              |-> [i \in 1 .. 1 |-> 0],
      leavesQty              |-> [i \in 1 .. 4 |-> 0],
      baseLiquidityIndicator |-> [i \in 1 .. 1 |-> 0],
      expireTime             |-> [i \in 1 .. 8 |-> 0],
      subLiquidityIndicator  |-> [i \in 1 .. 1 |-> 0],
      cmtaNumber             |-> [i \in 1 .. 4 |-> 0],
      ctiCode                |-> [i \in 1 .. 1 |-> 0],
      manualOrderIndicator   |-> [i \in 1 .. 1 |-> 0],
      oeoId                  |-> [i \in 1 .. 18 |-> 0],
      cumQty                 |-> [i \in 1 .. 4 |-> 0],
      frequentTraderId       |-> [i \in 1 .. 6 |-> 0],
      custOrderHandlingInst  |-> [i \in 1 .. 1 |-> 0],
      countryCode            |-> [i \in 1 .. 2 |-> 0],
      requestReceivedTime    |-> [i \in 1 .. 8 |-> 0],
      legCnt                 |-> 0,
      legPositionEffect      |-> [i \in 1 .. 1 |-> 0] ]

(* Order Acknowledgement Option at zero, then each field in turn at the values it is checked at *)
CheckedOrderAcknowledgementOption ==
    { ZeroOrderAcknowledgementOption }
        \cup { [ZeroOrderAcknowledgementOption EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgementOption EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderAcknowledgementOption EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgementOption EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementOption EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgementOption EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementOption EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementOption EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgementOption EXCEPT !.securityDesc = one] : one \in Sample(16) }
        \cup { [ZeroOrderAcknowledgementOption EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementOption EXCEPT !.account = one] : one \in Sample(16) }
        \cup { [ZeroOrderAcknowledgementOption EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcknowledgementOption EXCEPT !.clearingAccount = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcknowledgementOption EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcknowledgementOption EXCEPT !.preventMatch = one] : one \in CheckedPreventMatch2 }
        \cup { [ZeroOrderAcknowledgementOption EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementOption EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcknowledgementOption EXCEPT !.baseLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementOption EXCEPT !.expireTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgementOption EXCEPT !.subLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementOption EXCEPT !.cmtaNumber = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcknowledgementOption EXCEPT !.ctiCode = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementOption EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementOption EXCEPT !.oeoId = one] : one \in Sample(18) }
        \cup { [ZeroOrderAcknowledgementOption EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcknowledgementOption EXCEPT !.frequentTraderId = one] : one \in Sample(6) }
        \cup { [ZeroOrderAcknowledgementOption EXCEPT !.custOrderHandlingInst = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementOption EXCEPT !.countryCode = one] : one \in Sample(2) }
        \cup { [ZeroOrderAcknowledgementOption EXCEPT !.requestReceivedTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgementOption EXCEPT !.legCnt = one] : one \in {0, 1, 255} }
        \cup { [ZeroOrderAcknowledgementOption EXCEPT !.legPositionEffect = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Rejected: 93 bytes                                                *)
(***************************************************************************)

OrderRejected ==
    [ transactionTime   : Sample(8),
      clOrdId           : Sample(20),
      clearingFirm      : Sample(4),
      orderRejectReason : Sample(1),
      text              : Sample(60) ]

EncodeOrderRejected(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.clearingFirm
        \o message.orderRejectReason
        \o message.text

DecodeOrderRejected(bytes) ==
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

ZeroOrderRejected ==
    [ transactionTime   |-> [i \in 1 .. 8 |-> 0],
      clOrdId           |-> [i \in 1 .. 20 |-> 0],
      clearingFirm      |-> [i \in 1 .. 4 |-> 0],
      orderRejectReason |-> [i \in 1 .. 1 |-> 0],
      text              |-> [i \in 1 .. 60 |-> 0] ]

(* Order Rejected at zero, then each field in turn at the values it is checked at *)
CheckedOrderRejected ==
    { ZeroOrderRejected }
        \cup { [ZeroOrderRejected EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderRejected EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderRejected EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroOrderRejected EXCEPT !.orderRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroOrderRejected EXCEPT !.text = one] : one \in Sample(60) }

(***************************************************************************)
(* Order Modified: 101 bytes                                               *)
(***************************************************************************)

OrderModified ==
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

EncodeOrderModified(message) ==
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

DecodeOrderModified(bytes) ==
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

ZeroOrderModified ==
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

(* Order Modified at zero, then each field in turn at the values it is checked at *)
CheckedOrderModified ==
    { ZeroOrderModified }
        \cup { [ZeroOrderModified EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderModified EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderModified EXCEPT !.origClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderModified EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderModified EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroOrderModified EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderModified EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroOrderModified EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderModified EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderModified EXCEPT !.baseLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderModified EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroOrderModified EXCEPT !.frequentTraderId = one] : one \in Sample(6) }
        \cup { [ZeroOrderModified EXCEPT !.custOrderHandlingInst = one] : one \in Sample(1) }
        \cup { [ZeroOrderModified EXCEPT !.requestReceivedTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Modify Rejected: 113 bytes                                              *)
(***************************************************************************)

ModifyRejected ==
    [ transactionTime    : Sample(8),
      clOrdId            : Sample(20),
      origClOrdId        : Sample(20),
      clearingFirm       : Sample(4),
      modifyRejectReason : Sample(1),
      text               : Sample(60) ]

EncodeModifyRejected(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.origClOrdId
        \o message.clearingFirm
        \o message.modifyRejectReason
        \o message.text

DecodeModifyRejected(bytes) ==
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

ZeroModifyRejected ==
    [ transactionTime    |-> [i \in 1 .. 8 |-> 0],
      clOrdId            |-> [i \in 1 .. 20 |-> 0],
      origClOrdId        |-> [i \in 1 .. 20 |-> 0],
      clearingFirm       |-> [i \in 1 .. 4 |-> 0],
      modifyRejectReason |-> [i \in 1 .. 1 |-> 0],
      text               |-> [i \in 1 .. 60 |-> 0] ]

(* Modify Rejected at zero, then each field in turn at the values it is checked at *)
CheckedModifyRejected ==
    { ZeroModifyRejected }
        \cup { [ZeroModifyRejected EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroModifyRejected EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroModifyRejected EXCEPT !.origClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroModifyRejected EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroModifyRejected EXCEPT !.modifyRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroModifyRejected EXCEPT !.text = one] : one \in Sample(60) }

(***************************************************************************)
(* Order Execution: 91 bytes                                               *)
(***************************************************************************)

OrderExecution ==
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

EncodeOrderExecution(message) ==
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

DecodeOrderExecution(bytes) ==
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

ZeroOrderExecution ==
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

(* Order Execution at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecution ==
    { ZeroOrderExecution }
        \cup { [ZeroOrderExecution EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecution EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderExecution EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecution EXCEPT !.lastShares = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecution EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecution EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecution EXCEPT !.baseLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecution EXCEPT !.subLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecution EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecution EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecution EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecution EXCEPT !.maturityDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecution EXCEPT !.feeCode = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecution EXCEPT !.tradeDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecution EXCEPT !.clearingSize = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecution EXCEPT !.pendingStatus = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecution EXCEPT !.multilegReportingType = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecution EXCEPT !.secondaryExecId = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Execution Option: 103 bytes                                       *)
(***************************************************************************)

OrderExecutionOption ==
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
      securityDesc           : Sample(16),
      feeCode                : Sample(2),
      tradeDate              : Sample(4),
      clearingSize           : Sample(4),
      pendingStatus          : Sample(1),
      multilegReportingType  : Sample(1),
      secondaryExecId        : Sample(8) ]

EncodeOrderExecutionOption(message) ==
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
        \o message.securityDesc
        \o message.feeCode
        \o message.tradeDate
        \o message.clearingSize
        \o message.pendingStatus
        \o message.multilegReportingType
        \o message.secondaryExecId

DecodeOrderExecutionOption(bytes) ==
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
    LET securityDesc == ReadBytes(clearingFirm.rest, 16) IN IF ~securityDesc.ok THEN Fail ELSE
    LET feeCode == ReadBytes(securityDesc.rest, 2) IN IF ~feeCode.ok THEN Fail ELSE
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
         securityDesc           |-> securityDesc.value,
         feeCode                |-> feeCode.value,
         tradeDate              |-> tradeDate.value,
         clearingSize           |-> clearingSize.value,
         pendingStatus          |-> pendingStatus.value,
         multilegReportingType  |-> multilegReportingType.value,
         secondaryExecId        |-> secondaryExecId.value ], secondaryExecId.rest)

ZeroOrderExecutionOption ==
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
      securityDesc           |-> [i \in 1 .. 16 |-> 0],
      feeCode                |-> [i \in 1 .. 2 |-> 0],
      tradeDate              |-> [i \in 1 .. 4 |-> 0],
      clearingSize           |-> [i \in 1 .. 4 |-> 0],
      pendingStatus          |-> [i \in 1 .. 1 |-> 0],
      multilegReportingType  |-> [i \in 1 .. 1 |-> 0],
      secondaryExecId        |-> [i \in 1 .. 8 |-> 0] ]

(* Order Execution Option at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutionOption ==
    { ZeroOrderExecutionOption }
        \cup { [ZeroOrderExecutionOption EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionOption EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderExecutionOption EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionOption EXCEPT !.lastShares = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionOption EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionOption EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionOption EXCEPT !.baseLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionOption EXCEPT !.subLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionOption EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionOption EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionOption EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionOption EXCEPT !.securityDesc = one] : one \in Sample(16) }
        \cup { [ZeroOrderExecutionOption EXCEPT !.feeCode = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecutionOption EXCEPT !.tradeDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionOption EXCEPT !.clearingSize = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionOption EXCEPT !.pendingStatus = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionOption EXCEPT !.multilegReportingType = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionOption EXCEPT !.secondaryExecId = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Cancelled: 41 bytes                                               *)
(***************************************************************************)

OrderCancelled ==
    [ transactionTime     : Sample(8),
      clOrdId             : Sample(20),
      clearingFirm        : Sample(4),
      cancelReason        : Sample(1),
      requestReceivedTime : Sample(8) ]

EncodeOrderCancelled(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.clearingFirm
        \o message.cancelReason
        \o message.requestReceivedTime

DecodeOrderCancelled(bytes) ==
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

ZeroOrderCancelled ==
    [ transactionTime     |-> [i \in 1 .. 8 |-> 0],
      clOrdId             |-> [i \in 1 .. 20 |-> 0],
      clearingFirm        |-> [i \in 1 .. 4 |-> 0],
      cancelReason        |-> [i \in 1 .. 1 |-> 0],
      requestReceivedTime |-> [i \in 1 .. 8 |-> 0] ]

(* Order Cancelled at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelled ==
    { ZeroOrderCancelled }
        \cup { [ZeroOrderCancelled EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelled EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderCancelled EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelled EXCEPT !.cancelReason = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelled EXCEPT !.requestReceivedTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Cancel Rejected: 93 bytes                                               *)
(***************************************************************************)

CancelRejected ==
    [ transactionTime    : Sample(8),
      clOrdId            : Sample(20),
      clearingFirm       : Sample(4),
      cancelRejectReason : Sample(1),
      text               : Sample(60) ]

EncodeCancelRejected(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.clearingFirm
        \o message.cancelRejectReason
        \o message.text

DecodeCancelRejected(bytes) ==
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

ZeroCancelRejected ==
    [ transactionTime    |-> [i \in 1 .. 8 |-> 0],
      clOrdId            |-> [i \in 1 .. 20 |-> 0],
      clearingFirm       |-> [i \in 1 .. 4 |-> 0],
      cancelRejectReason |-> [i \in 1 .. 1 |-> 0],
      text               |-> [i \in 1 .. 60 |-> 0] ]

(* Cancel Rejected at zero, then each field in turn at the values it is checked at *)
CheckedCancelRejected ==
    { ZeroCancelRejected }
        \cup { [ZeroCancelRejected EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroCancelRejected EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroCancelRejected EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroCancelRejected EXCEPT !.cancelRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroCancelRejected EXCEPT !.text = one] : one \in Sample(60) }

(***************************************************************************)
(* Mass Cancel Acknowledgement: 40 bytes                                   *)
(***************************************************************************)

MassCancelAcknowledgement ==
    [ transactionTime     : Sample(8),
      massCancelId        : Sample(20),
      cancelledOrderCount : Sample(4),
      requestReceivedTime : Sample(8) ]

EncodeMassCancelAcknowledgement(message) ==
    message.transactionTime
        \o message.massCancelId
        \o message.cancelledOrderCount
        \o message.requestReceivedTime

DecodeMassCancelAcknowledgement(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET massCancelId == ReadBytes(transactionTime.rest, 20) IN IF ~massCancelId.ok THEN Fail ELSE
    LET cancelledOrderCount == ReadBytes(massCancelId.rest, 4) IN IF ~cancelledOrderCount.ok THEN Fail ELSE
    LET requestReceivedTime == ReadBytes(cancelledOrderCount.rest, 8) IN IF ~requestReceivedTime.ok THEN Fail ELSE
    Ok([ transactionTime     |-> transactionTime.value,
         massCancelId        |-> massCancelId.value,
         cancelledOrderCount |-> cancelledOrderCount.value,
         requestReceivedTime |-> requestReceivedTime.value ], requestReceivedTime.rest)

ZeroMassCancelAcknowledgement ==
    [ transactionTime     |-> [i \in 1 .. 8 |-> 0],
      massCancelId        |-> [i \in 1 .. 20 |-> 0],
      cancelledOrderCount |-> [i \in 1 .. 4 |-> 0],
      requestReceivedTime |-> [i \in 1 .. 8 |-> 0] ]

(* Mass Cancel Acknowledgement at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelAcknowledgement ==
    { ZeroMassCancelAcknowledgement }
        \cup { [ZeroMassCancelAcknowledgement EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelAcknowledgement EXCEPT !.massCancelId = one] : one \in Sample(20) }
        \cup { [ZeroMassCancelAcknowledgement EXCEPT !.cancelledOrderCount = one] : one \in Sample(4) }
        \cup { [ZeroMassCancelAcknowledgement EXCEPT !.requestReceivedTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Mass Cancel Rejected: 89 bytes                                          *)
(***************************************************************************)

MassCancelRejected ==
    [ transactionTime        : Sample(8),
      massCancelId           : Sample(20),
      massCancelRejectReason : Sample(1),
      text                   : Sample(60) ]

EncodeMassCancelRejected(message) ==
    message.transactionTime
        \o message.massCancelId
        \o message.massCancelRejectReason
        \o message.text

DecodeMassCancelRejected(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET massCancelId == ReadBytes(transactionTime.rest, 20) IN IF ~massCancelId.ok THEN Fail ELSE
    LET massCancelRejectReason == ReadBytes(massCancelId.rest, 1) IN IF ~massCancelRejectReason.ok THEN Fail ELSE
    LET text == ReadBytes(massCancelRejectReason.rest, 60) IN IF ~text.ok THEN Fail ELSE
    Ok([ transactionTime        |-> transactionTime.value,
         massCancelId           |-> massCancelId.value,
         massCancelRejectReason |-> massCancelRejectReason.value,
         text                   |-> text.value ], text.rest)

ZeroMassCancelRejected ==
    [ transactionTime        |-> [i \in 1 .. 8 |-> 0],
      massCancelId           |-> [i \in 1 .. 20 |-> 0],
      massCancelRejectReason |-> [i \in 1 .. 1 |-> 0],
      text                   |-> [i \in 1 .. 60 |-> 0] ]

(* Mass Cancel Rejected at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelRejected ==
    { ZeroMassCancelRejected }
        \cup { [ZeroMassCancelRejected EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelRejected EXCEPT !.massCancelId = one] : one \in Sample(20) }
        \cup { [ZeroMassCancelRejected EXCEPT !.massCancelRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelRejected EXCEPT !.text = one] : one \in Sample(60) }

(***************************************************************************)
(* Purge Acknowledgement: 40 bytes                                         *)
(***************************************************************************)

PurgeAcknowledgement ==
    [ transactionTime     : Sample(8),
      massCancelId        : Sample(20),
      cancelledOrderCount : Sample(4),
      requestReceivedTime : Sample(8) ]

EncodePurgeAcknowledgement(message) ==
    message.transactionTime
        \o message.massCancelId
        \o message.cancelledOrderCount
        \o message.requestReceivedTime

DecodePurgeAcknowledgement(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET massCancelId == ReadBytes(transactionTime.rest, 20) IN IF ~massCancelId.ok THEN Fail ELSE
    LET cancelledOrderCount == ReadBytes(massCancelId.rest, 4) IN IF ~cancelledOrderCount.ok THEN Fail ELSE
    LET requestReceivedTime == ReadBytes(cancelledOrderCount.rest, 8) IN IF ~requestReceivedTime.ok THEN Fail ELSE
    Ok([ transactionTime     |-> transactionTime.value,
         massCancelId        |-> massCancelId.value,
         cancelledOrderCount |-> cancelledOrderCount.value,
         requestReceivedTime |-> requestReceivedTime.value ], requestReceivedTime.rest)

ZeroPurgeAcknowledgement ==
    [ transactionTime     |-> [i \in 1 .. 8 |-> 0],
      massCancelId        |-> [i \in 1 .. 20 |-> 0],
      cancelledOrderCount |-> [i \in 1 .. 4 |-> 0],
      requestReceivedTime |-> [i \in 1 .. 8 |-> 0] ]

(* Purge Acknowledgement at zero, then each field in turn at the values it is checked at *)
CheckedPurgeAcknowledgement ==
    { ZeroPurgeAcknowledgement }
        \cup { [ZeroPurgeAcknowledgement EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroPurgeAcknowledgement EXCEPT !.massCancelId = one] : one \in Sample(20) }
        \cup { [ZeroPurgeAcknowledgement EXCEPT !.cancelledOrderCount = one] : one \in Sample(4) }
        \cup { [ZeroPurgeAcknowledgement EXCEPT !.requestReceivedTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Purge Rejected: 89 bytes                                                *)
(***************************************************************************)

PurgeRejected ==
    [ transactionTime   : Sample(8),
      massCancelId      : Sample(20),
      purgeRejectReason : Sample(1),
      text              : Sample(60) ]

EncodePurgeRejected(message) ==
    message.transactionTime
        \o message.massCancelId
        \o message.purgeRejectReason
        \o message.text

DecodePurgeRejected(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET massCancelId == ReadBytes(transactionTime.rest, 20) IN IF ~massCancelId.ok THEN Fail ELSE
    LET purgeRejectReason == ReadBytes(massCancelId.rest, 1) IN IF ~purgeRejectReason.ok THEN Fail ELSE
    LET text == ReadBytes(purgeRejectReason.rest, 60) IN IF ~text.ok THEN Fail ELSE
    Ok([ transactionTime   |-> transactionTime.value,
         massCancelId      |-> massCancelId.value,
         purgeRejectReason |-> purgeRejectReason.value,
         text              |-> text.value ], text.rest)

ZeroPurgeRejected ==
    [ transactionTime   |-> [i \in 1 .. 8 |-> 0],
      massCancelId      |-> [i \in 1 .. 20 |-> 0],
      purgeRejectReason |-> [i \in 1 .. 1 |-> 0],
      text              |-> [i \in 1 .. 60 |-> 0] ]

(* Purge Rejected at zero, then each field in turn at the values it is checked at *)
CheckedPurgeRejected ==
    { ZeroPurgeRejected }
        \cup { [ZeroPurgeRejected EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroPurgeRejected EXCEPT !.massCancelId = one] : one \in Sample(20) }
        \cup { [ZeroPurgeRejected EXCEPT !.purgeRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroPurgeRejected EXCEPT !.text = one] : one \in Sample(60) }

(***************************************************************************)
(* Trade Cancel Correct: 92 bytes                                          *)
(***************************************************************************)

TradeCancelCorrect ==
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

EncodeTradeCancelCorrect(message) ==
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

DecodeTradeCancelCorrect(bytes) ==
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

ZeroTradeCancelCorrect ==
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

(* Trade Cancel Correct at zero, then each field in turn at the values it is checked at *)
CheckedTradeCancelCorrect ==
    { ZeroTradeCancelCorrect }
        \cup { [ZeroTradeCancelCorrect EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelCorrect EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroTradeCancelCorrect EXCEPT !.execRefId = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelCorrect EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelCorrect EXCEPT !.baseLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelCorrect EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelCorrect EXCEPT !.clearingAccount = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelCorrect EXCEPT !.lastShares = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelCorrect EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelCorrect EXCEPT !.correctedPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelCorrect EXCEPT !.origTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelCorrect EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelCorrect EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelCorrect EXCEPT !.maturityDate = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelCorrect EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelCorrect EXCEPT !.cmtaNumber = one] : one \in Sample(4) }

(***************************************************************************)
(* Trade Cancel Correct Option: 104 bytes                                  *)
(***************************************************************************)

TradeCancelCorrectOption ==
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
      securityDesc           : Sample(16),
      openClose              : Sample(1),
      cmtaNumber             : Sample(4) ]

EncodeTradeCancelCorrectOption(message) ==
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
        \o message.securityDesc
        \o message.openClose
        \o message.cmtaNumber

DecodeTradeCancelCorrectOption(bytes) ==
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
    LET securityDesc == ReadBytes(capacity.rest, 16) IN IF ~securityDesc.ok THEN Fail ELSE
    LET openClose == ReadBytes(securityDesc.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
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
         securityDesc           |-> securityDesc.value,
         openClose              |-> openClose.value,
         cmtaNumber             |-> cmtaNumber.value ], cmtaNumber.rest)

ZeroTradeCancelCorrectOption ==
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
      securityDesc           |-> [i \in 1 .. 16 |-> 0],
      openClose              |-> [i \in 1 .. 1 |-> 0],
      cmtaNumber             |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Cancel Correct Option at zero, then each field in turn at the values it is checked at *)
CheckedTradeCancelCorrectOption ==
    { ZeroTradeCancelCorrectOption }
        \cup { [ZeroTradeCancelCorrectOption EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelCorrectOption EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroTradeCancelCorrectOption EXCEPT !.execRefId = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelCorrectOption EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelCorrectOption EXCEPT !.baseLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelCorrectOption EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelCorrectOption EXCEPT !.clearingAccount = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelCorrectOption EXCEPT !.lastShares = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelCorrectOption EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelCorrectOption EXCEPT !.correctedPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelCorrectOption EXCEPT !.origTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelCorrectOption EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelCorrectOption EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelCorrectOption EXCEPT !.securityDesc = one] : one \in Sample(16) }
        \cup { [ZeroTradeCancelCorrectOption EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelCorrectOption EXCEPT !.cmtaNumber = one] : one \in Sample(4) }

(***************************************************************************)
(* Tas Restatement: 104 bytes                                              *)
(***************************************************************************)

TasRestatement ==
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

EncodeTasRestatement(message) ==
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

DecodeTasRestatement(bytes) ==
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

ZeroTasRestatement ==
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

(* Tas Restatement at zero, then each field in turn at the values it is checked at *)
CheckedTasRestatement ==
    { ZeroTasRestatement }
        \cup { [ZeroTasRestatement EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroTasRestatement EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroTasRestatement EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroTasRestatement EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroTasRestatement EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroTasRestatement EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTasRestatement EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroTasRestatement EXCEPT !.maturityDate = one] : one \in Sample(4) }
        \cup { [ZeroTasRestatement EXCEPT !.lastShares = one] : one \in Sample(4) }
        \cup { [ZeroTasRestatement EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroTasRestatement EXCEPT !.feeCode = one] : one \in Sample(2) }
        \cup { [ZeroTasRestatement EXCEPT !.tradeDate = one] : one \in Sample(4) }
        \cup { [ZeroTasRestatement EXCEPT !.clearingPrice = one] : one \in Sample(8) }
        \cup { [ZeroTasRestatement EXCEPT !.clearingSymbol = one] : one \in Sample(8) }
        \cup { [ZeroTasRestatement EXCEPT !.multilegReportingType = one] : one \in Sample(1) }
        \cup { [ZeroTasRestatement EXCEPT !.secondaryExecId = one] : one \in Sample(8) }

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
(* Quote Update Acknowledgement                                            *)
(***************************************************************************)

QuoteUpdateAcknowledgement ==
    [ transactionTime                 : Sample(8),
      quoteUpdateId                   : Sample(16),
      requestReceivedTime             : Sample(8),
      quoteUpdateAcknowledgementGroup : SampleLists(OneQuoteUpdateAcknowledgementGroup) ]

EncodeQuoteUpdateAcknowledgement(message) ==
    message.transactionTime
        \o message.quoteUpdateId
        \o message.requestReceivedTime
        \o EncodeUIntLE(Len(message.quoteUpdateAcknowledgementGroup), 1)
        \o EncodeQuoteUpdateAcknowledgementGroupList(message.quoteUpdateAcknowledgementGroup)

DecodeQuoteUpdateAcknowledgement(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET quoteUpdateId == ReadBytes(transactionTime.rest, 16) IN IF ~quoteUpdateId.ok THEN Fail ELSE
    LET requestReceivedTime == ReadBytes(quoteUpdateId.rest, 8) IN IF ~requestReceivedTime.ok THEN Fail ELSE
    LET quoteCnt == ReadUIntLE(requestReceivedTime.rest, 1) IN IF ~quoteCnt.ok THEN Fail ELSE
    LET quoteUpdateAcknowledgementGroup == ReadQuoteUpdateAcknowledgementGroupList(quoteCnt.rest, quoteCnt.value) IN IF ~quoteUpdateAcknowledgementGroup.ok THEN Fail ELSE
    Ok([ transactionTime                 |-> transactionTime.value,
         quoteUpdateId                   |-> quoteUpdateId.value,
         requestReceivedTime             |-> requestReceivedTime.value,
         quoteUpdateAcknowledgementGroup |-> quoteUpdateAcknowledgementGroup.value ], quoteUpdateAcknowledgementGroup.rest)

ZeroQuoteUpdateAcknowledgement ==
    [ transactionTime                 |-> [i \in 1 .. 8 |-> 0],
      quoteUpdateId                   |-> [i \in 1 .. 16 |-> 0],
      requestReceivedTime             |-> [i \in 1 .. 8 |-> 0],
      quoteUpdateAcknowledgementGroup |-> << >> ]

(* Quote Update Acknowledgement at zero, then each field in turn at the values it is checked at *)
CheckedQuoteUpdateAcknowledgement ==
    { ZeroQuoteUpdateAcknowledgement }
        \cup { [ZeroQuoteUpdateAcknowledgement EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroQuoteUpdateAcknowledgement EXCEPT !.quoteUpdateId = one] : one \in Sample(16) }
        \cup { [ZeroQuoteUpdateAcknowledgement EXCEPT !.requestReceivedTime = one] : one \in Sample(8) }
        \cup { [ZeroQuoteUpdateAcknowledgement EXCEPT !.quoteUpdateAcknowledgementGroup = one] : one \in SampleLists(OneQuoteUpdateAcknowledgementGroup) }

(***************************************************************************)
(* Quote Update Rejected: 25 bytes                                         *)
(***************************************************************************)

QuoteUpdateRejected ==
    [ transactionTime   : Sample(8),
      quoteUpdateId     : Sample(16),
      quoteRejectReason : Sample(1) ]

EncodeQuoteUpdateRejected(message) ==
    message.transactionTime
        \o message.quoteUpdateId
        \o message.quoteRejectReason

DecodeQuoteUpdateRejected(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET quoteUpdateId == ReadBytes(transactionTime.rest, 16) IN IF ~quoteUpdateId.ok THEN Fail ELSE
    LET quoteRejectReason == ReadBytes(quoteUpdateId.rest, 1) IN IF ~quoteRejectReason.ok THEN Fail ELSE
    Ok([ transactionTime   |-> transactionTime.value,
         quoteUpdateId     |-> quoteUpdateId.value,
         quoteRejectReason |-> quoteRejectReason.value ], quoteRejectReason.rest)

ZeroQuoteUpdateRejected ==
    [ transactionTime   |-> [i \in 1 .. 8 |-> 0],
      quoteUpdateId     |-> [i \in 1 .. 16 |-> 0],
      quoteRejectReason |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Update Rejected at zero, then each field in turn at the values it is checked at *)
CheckedQuoteUpdateRejected ==
    { ZeroQuoteUpdateRejected }
        \cup { [ZeroQuoteUpdateRejected EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroQuoteUpdateRejected EXCEPT !.quoteUpdateId = one] : one \in Sample(16) }
        \cup { [ZeroQuoteUpdateRejected EXCEPT !.quoteRejectReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Quote Restated: 52 bytes                                                *)
(***************************************************************************)

QuoteRestated ==
    [ transactionTime   : Sample(8),
      quoteUpdateId     : Sample(16),
      orderId           : Sample(8),
      leavesQty         : Sample(4),
      workingPrice      : Sample(8),
      quoteSymbol       : Sample(6),
      side              : Sample(1),
      restatementReason : Sample(1) ]

EncodeQuoteRestated(message) ==
    message.transactionTime
        \o message.quoteUpdateId
        \o message.orderId
        \o message.leavesQty
        \o message.workingPrice
        \o message.quoteSymbol
        \o message.side
        \o message.restatementReason

DecodeQuoteRestated(bytes) ==
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

ZeroQuoteRestated ==
    [ transactionTime   |-> [i \in 1 .. 8 |-> 0],
      quoteUpdateId     |-> [i \in 1 .. 16 |-> 0],
      orderId           |-> [i \in 1 .. 8 |-> 0],
      leavesQty         |-> [i \in 1 .. 4 |-> 0],
      workingPrice      |-> [i \in 1 .. 8 |-> 0],
      quoteSymbol       |-> [i \in 1 .. 6 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      restatementReason |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Restated at zero, then each field in turn at the values it is checked at *)
CheckedQuoteRestated ==
    { ZeroQuoteRestated }
        \cup { [ZeroQuoteRestated EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRestated EXCEPT !.quoteUpdateId = one] : one \in Sample(16) }
        \cup { [ZeroQuoteRestated EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRestated EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRestated EXCEPT !.workingPrice = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRestated EXCEPT !.quoteSymbol = one] : one \in Sample(6) }
        \cup { [ZeroQuoteRestated EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRestated EXCEPT !.restatementReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Quote Execution: 71 bytes                                               *)
(***************************************************************************)

QuoteExecution ==
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

EncodeQuoteExecution(message) ==
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

DecodeQuoteExecution(bytes) ==
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

ZeroQuoteExecution ==
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

(* Quote Execution at zero, then each field in turn at the values it is checked at *)
CheckedQuoteExecution ==
    { ZeroQuoteExecution }
        \cup { [ZeroQuoteExecution EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroQuoteExecution EXCEPT !.quoteUpdateId = one] : one \in Sample(16) }
        \cup { [ZeroQuoteExecution EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteExecution EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteExecution EXCEPT !.quoteSymbol = one] : one \in Sample(6) }
        \cup { [ZeroQuoteExecution EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroQuoteExecution EXCEPT !.lastShares = one] : one \in Sample(4) }
        \cup { [ZeroQuoteExecution EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroQuoteExecution EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroQuoteExecution EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroQuoteExecution EXCEPT !.baseLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroQuoteExecution EXCEPT !.subLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroQuoteExecution EXCEPT !.feeCode = one] : one \in Sample(2) }

(***************************************************************************)
(* Quote Cancelled: 40 bytes                                               *)
(***************************************************************************)

QuoteCancelled ==
    [ transactionTime : Sample(8),
      quoteUpdateId   : Sample(16),
      orderId         : Sample(8),
      quoteSymbol     : Sample(6),
      side            : Sample(1),
      cancelReason    : Sample(1) ]

EncodeQuoteCancelled(message) ==
    message.transactionTime
        \o message.quoteUpdateId
        \o message.orderId
        \o message.quoteSymbol
        \o message.side
        \o message.cancelReason

DecodeQuoteCancelled(bytes) ==
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

ZeroQuoteCancelled ==
    [ transactionTime |-> [i \in 1 .. 8 |-> 0],
      quoteUpdateId   |-> [i \in 1 .. 16 |-> 0],
      orderId         |-> [i \in 1 .. 8 |-> 0],
      quoteSymbol     |-> [i \in 1 .. 6 |-> 0],
      side            |-> [i \in 1 .. 1 |-> 0],
      cancelReason    |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Cancelled at zero, then each field in turn at the values it is checked at *)
CheckedQuoteCancelled ==
    { ZeroQuoteCancelled }
        \cup { [ZeroQuoteCancelled EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroQuoteCancelled EXCEPT !.quoteUpdateId = one] : one \in Sample(16) }
        \cup { [ZeroQuoteCancelled EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteCancelled EXCEPT !.quoteSymbol = one] : one \in Sample(6) }
        \cup { [ZeroQuoteCancelled EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroQuoteCancelled EXCEPT !.cancelReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Tas Quote Restatement: 54 bytes                                         *)
(***************************************************************************)

TasQuoteRestatement ==
    [ transactionTime : Sample(8),
      quoteUpdateId   : Sample(16),
      execId          : Sample(8),
      quoteSymbol     : Sample(6),
      clearingSymbol  : Sample(8),
      clearingPrice   : Sample(8) ]

EncodeTasQuoteRestatement(message) ==
    message.transactionTime
        \o message.quoteUpdateId
        \o message.execId
        \o message.quoteSymbol
        \o message.clearingSymbol
        \o message.clearingPrice

DecodeTasQuoteRestatement(bytes) ==
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

ZeroTasQuoteRestatement ==
    [ transactionTime |-> [i \in 1 .. 8 |-> 0],
      quoteUpdateId   |-> [i \in 1 .. 16 |-> 0],
      execId          |-> [i \in 1 .. 8 |-> 0],
      quoteSymbol     |-> [i \in 1 .. 6 |-> 0],
      clearingSymbol  |-> [i \in 1 .. 8 |-> 0],
      clearingPrice   |-> [i \in 1 .. 8 |-> 0] ]

(* Tas Quote Restatement at zero, then each field in turn at the values it is checked at *)
CheckedTasQuoteRestatement ==
    { ZeroTasQuoteRestatement }
        \cup { [ZeroTasQuoteRestatement EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroTasQuoteRestatement EXCEPT !.quoteUpdateId = one] : one \in Sample(16) }
        \cup { [ZeroTasQuoteRestatement EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroTasQuoteRestatement EXCEPT !.quoteSymbol = one] : one \in Sample(6) }
        \cup { [ZeroTasQuoteRestatement EXCEPT !.clearingSymbol = one] : one \in Sample(8) }
        \cup { [ZeroTasQuoteRestatement EXCEPT !.clearingPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Reset Risk Acknowledgement: 25 bytes                                    *)
(***************************************************************************)

ResetRiskAcknowledgement ==
    [ riskStatusId        : Sample(16),
      riskResetResult     : Sample(1),
      requestReceivedTime : Sample(8) ]

EncodeResetRiskAcknowledgement(message) ==
    message.riskStatusId
        \o message.riskResetResult
        \o message.requestReceivedTime

DecodeResetRiskAcknowledgement(bytes) ==
    LET riskStatusId == ReadBytes(bytes, 16) IN IF ~riskStatusId.ok THEN Fail ELSE
    LET riskResetResult == ReadBytes(riskStatusId.rest, 1) IN IF ~riskResetResult.ok THEN Fail ELSE
    LET requestReceivedTime == ReadBytes(riskResetResult.rest, 8) IN IF ~requestReceivedTime.ok THEN Fail ELSE
    Ok([ riskStatusId        |-> riskStatusId.value,
         riskResetResult     |-> riskResetResult.value,
         requestReceivedTime |-> requestReceivedTime.value ], requestReceivedTime.rest)

ZeroResetRiskAcknowledgement ==
    [ riskStatusId        |-> [i \in 1 .. 16 |-> 0],
      riskResetResult     |-> [i \in 1 .. 1 |-> 0],
      requestReceivedTime |-> [i \in 1 .. 8 |-> 0] ]

(* Reset Risk Acknowledgement at zero, then each field in turn at the values it is checked at *)
CheckedResetRiskAcknowledgement ==
    { ZeroResetRiskAcknowledgement }
        \cup { [ZeroResetRiskAcknowledgement EXCEPT !.riskStatusId = one] : one \in Sample(16) }
        \cup { [ZeroResetRiskAcknowledgement EXCEPT !.riskResetResult = one] : one \in Sample(1) }
        \cup { [ZeroResetRiskAcknowledgement EXCEPT !.requestReceivedTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Option Leg: 13 bytes                                                    *)
(***************************************************************************)

OptionLeg ==
    [ legSymbol   : Sample(8),
      legRatioQty : Sample(4),
      legSide     : Sample(1) ]

EncodeOptionLeg(message) ==
    message.legSymbol
        \o message.legRatioQty
        \o message.legSide

DecodeOptionLeg(bytes) ==
    LET legSymbol == ReadBytes(bytes, 8) IN IF ~legSymbol.ok THEN Fail ELSE
    LET legRatioQty == ReadBytes(legSymbol.rest, 4) IN IF ~legRatioQty.ok THEN Fail ELSE
    LET legSide == ReadBytes(legRatioQty.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    Ok([ legSymbol   |-> legSymbol.value,
         legRatioQty |-> legRatioQty.value,
         legSide     |-> legSide.value ], legSide.rest)

ZeroOptionLeg ==
    [ legSymbol   |-> [i \in 1 .. 8 |-> 0],
      legRatioQty |-> [i \in 1 .. 4 |-> 0],
      legSide     |-> [i \in 1 .. 1 |-> 0] ]

(* Option Leg at zero, then each field in turn at the values it is checked at *)
CheckedOptionLeg ==
    { ZeroOptionLeg }
        \cup { [ZeroOptionLeg EXCEPT !.legSymbol = one] : one \in Sample(8) }
        \cup { [ZeroOptionLeg EXCEPT !.legRatioQty = one] : one \in Sample(4) }
        \cup { [ZeroOptionLeg EXCEPT !.legSide = one] : one \in Sample(1) }

(* A run of Option Leg, written one after another *)
RECURSIVE EncodeOptionLegList(_)
EncodeOptionLegList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOptionLeg(Head(messages)) \o EncodeOptionLegList(Tail(messages))

(* As many Option Leg as the field that counts them says *)
RECURSIVE ReadOptionLegList(_, _)
ReadOptionLegList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOptionLeg(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOptionLegList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Option Leg of each kind, for the lists that carry them *)
OneOptionLeg == { ZeroOptionLeg }

(***************************************************************************)
(* New Complex Instrument Accepted Option                                  *)
(***************************************************************************)

NewComplexInstrumentAcceptedOption ==
    [ transactionTime        : Sample(8),
      clOrdId                : Sample(20),
      symbol                 : Sample(8),
      noOfComplexInstruments : Sample(4),
      optionLeg              : SampleLists(OneOptionLeg) ]

EncodeNewComplexInstrumentAcceptedOption(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.symbol
        \o message.noOfComplexInstruments
        \o EncodeUIntLE(Len(message.optionLeg), 1)
        \o EncodeOptionLegList(message.optionLeg)

DecodeNewComplexInstrumentAcceptedOption(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET symbol == ReadBytes(clOrdId.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET noOfComplexInstruments == ReadBytes(symbol.rest, 4) IN IF ~noOfComplexInstruments.ok THEN Fail ELSE
    LET legCnt == ReadUIntLE(noOfComplexInstruments.rest, 1) IN IF ~legCnt.ok THEN Fail ELSE
    LET optionLeg == ReadOptionLegList(legCnt.rest, legCnt.value) IN IF ~optionLeg.ok THEN Fail ELSE
    Ok([ transactionTime        |-> transactionTime.value,
         clOrdId                |-> clOrdId.value,
         symbol                 |-> symbol.value,
         noOfComplexInstruments |-> noOfComplexInstruments.value,
         optionLeg              |-> optionLeg.value ], optionLeg.rest)

ZeroNewComplexInstrumentAcceptedOption ==
    [ transactionTime        |-> [i \in 1 .. 8 |-> 0],
      clOrdId                |-> [i \in 1 .. 20 |-> 0],
      symbol                 |-> [i \in 1 .. 8 |-> 0],
      noOfComplexInstruments |-> [i \in 1 .. 4 |-> 0],
      optionLeg              |-> << >> ]

(* New Complex Instrument Accepted Option at zero, then each field in turn at the values it is checked at *)
CheckedNewComplexInstrumentAcceptedOption ==
    { ZeroNewComplexInstrumentAcceptedOption }
        \cup { [ZeroNewComplexInstrumentAcceptedOption EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroNewComplexInstrumentAcceptedOption EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroNewComplexInstrumentAcceptedOption EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroNewComplexInstrumentAcceptedOption EXCEPT !.noOfComplexInstruments = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexInstrumentAcceptedOption EXCEPT !.optionLeg = one] : one \in SampleLists(OneOptionLeg) }

(***************************************************************************)
(* New Complex Instrument Rejected Option: 93 bytes                        *)
(***************************************************************************)

NewComplexInstrumentRejectedOption ==
    [ transactionTime               : Sample(8),
      clOrdId                       : Sample(20),
      clearingFirm                  : Sample(4),
      complexInstrumentRejectReason : Sample(1),
      text                          : Sample(60) ]

EncodeNewComplexInstrumentRejectedOption(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.clearingFirm
        \o message.complexInstrumentRejectReason
        \o message.text

DecodeNewComplexInstrumentRejectedOption(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(clOrdId.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET complexInstrumentRejectReason == ReadBytes(clearingFirm.rest, 1) IN IF ~complexInstrumentRejectReason.ok THEN Fail ELSE
    LET text == ReadBytes(complexInstrumentRejectReason.rest, 60) IN IF ~text.ok THEN Fail ELSE
    Ok([ transactionTime               |-> transactionTime.value,
         clOrdId                       |-> clOrdId.value,
         clearingFirm                  |-> clearingFirm.value,
         complexInstrumentRejectReason |-> complexInstrumentRejectReason.value,
         text                          |-> text.value ], text.rest)

ZeroNewComplexInstrumentRejectedOption ==
    [ transactionTime               |-> [i \in 1 .. 8 |-> 0],
      clOrdId                       |-> [i \in 1 .. 20 |-> 0],
      clearingFirm                  |-> [i \in 1 .. 4 |-> 0],
      complexInstrumentRejectReason |-> [i \in 1 .. 1 |-> 0],
      text                          |-> [i \in 1 .. 60 |-> 0] ]

(* New Complex Instrument Rejected Option at zero, then each field in turn at the values it is checked at *)
CheckedNewComplexInstrumentRejectedOption ==
    { ZeroNewComplexInstrumentRejectedOption }
        \cup { [ZeroNewComplexInstrumentRejectedOption EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroNewComplexInstrumentRejectedOption EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroNewComplexInstrumentRejectedOption EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexInstrumentRejectedOption EXCEPT !.complexInstrumentRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexInstrumentRejectedOption EXCEPT !.text = one] : one \in Sample(60) }

(***************************************************************************)
(* Exchange Message, selected by Exchange Message Type                     *)
(***************************************************************************)

LoginResponseMessageCode == 501  \* 0x1f5
ReplayCompleteCode == 502  \* 0x1f6
LogoutResponseMessageCode == 503  \* 0x1f7
ServerHeartbeatCode == 504  \* 0x1f8
OrderAcknowledgementCode == 1501  \* 0x5dd
OrderAcknowledgementOptionCode == 1523  \* 0x5f3
OrderRejectedCode == 1502  \* 0x5de
OrderModifiedCode == 1503  \* 0x5df
ModifyRejectedCode == 1504  \* 0x5e0
OrderExecutionCode == 1505  \* 0x5e1
OrderExecutionOptionCode == 1524  \* 0x5f4
OrderCancelledCode == 1506  \* 0x5e2
CancelRejectedCode == 1507  \* 0x5e3
MassCancelAcknowledgementCode == 1508  \* 0x5e4
MassCancelRejectedCode == 1509  \* 0x5e5
PurgeAcknowledgementCode == 1510  \* 0x5e6
PurgeRejectedCode == 1511  \* 0x5e7
TradeCancelCorrectCode == 1512  \* 0x5e8
TradeCancelCorrectOptionCode == 1525  \* 0x5f5
TasRestatementCode == 1513  \* 0x5e9
QuoteUpdateAcknowledgementCode == 1515  \* 0x5eb
QuoteUpdateRejectedCode == 1516  \* 0x5ec
QuoteRestatedCode == 1517  \* 0x5ed
QuoteExecutionCode == 1518  \* 0x5ee
QuoteCancelledCode == 1519  \* 0x5ef
TasQuoteRestatementCode == 1520  \* 0x5f0
ResetRiskAcknowledgementCode == 1522  \* 0x5f2
NewComplexInstrumentAcceptedOptionCode == 1526  \* 0x5f6
NewComplexInstrumentRejectedOptionCode == 1527  \* 0x5f7

ExchangeMessage ==
    [ tag : {LoginResponseMessageCode}, body : LoginResponseMessage ]
        \cup [ tag : {ReplayCompleteCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {LogoutResponseMessageCode}, body : LogoutResponseMessage ]
        \cup [ tag : {ServerHeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {OrderAcknowledgementCode}, body : OrderAcknowledgement ]
        \cup [ tag : {OrderAcknowledgementOptionCode}, body : OrderAcknowledgementOption ]
        \cup [ tag : {OrderRejectedCode}, body : OrderRejected ]
        \cup [ tag : {OrderModifiedCode}, body : OrderModified ]
        \cup [ tag : {ModifyRejectedCode}, body : ModifyRejected ]
        \cup [ tag : {OrderExecutionCode}, body : OrderExecution ]
        \cup [ tag : {OrderExecutionOptionCode}, body : OrderExecutionOption ]
        \cup [ tag : {OrderCancelledCode}, body : OrderCancelled ]
        \cup [ tag : {CancelRejectedCode}, body : CancelRejected ]
        \cup [ tag : {MassCancelAcknowledgementCode}, body : MassCancelAcknowledgement ]
        \cup [ tag : {MassCancelRejectedCode}, body : MassCancelRejected ]
        \cup [ tag : {PurgeAcknowledgementCode}, body : PurgeAcknowledgement ]
        \cup [ tag : {PurgeRejectedCode}, body : PurgeRejected ]
        \cup [ tag : {TradeCancelCorrectCode}, body : TradeCancelCorrect ]
        \cup [ tag : {TradeCancelCorrectOptionCode}, body : TradeCancelCorrectOption ]
        \cup [ tag : {TasRestatementCode}, body : TasRestatement ]
        \cup [ tag : {QuoteUpdateAcknowledgementCode}, body : QuoteUpdateAcknowledgement ]
        \cup [ tag : {QuoteUpdateRejectedCode}, body : QuoteUpdateRejected ]
        \cup [ tag : {QuoteRestatedCode}, body : QuoteRestated ]
        \cup [ tag : {QuoteExecutionCode}, body : QuoteExecution ]
        \cup [ tag : {QuoteCancelledCode}, body : QuoteCancelled ]
        \cup [ tag : {TasQuoteRestatementCode}, body : TasQuoteRestatement ]
        \cup [ tag : {ResetRiskAcknowledgementCode}, body : ResetRiskAcknowledgement ]
        \cup [ tag : {NewComplexInstrumentAcceptedOptionCode}, body : NewComplexInstrumentAcceptedOption ]
        \cup [ tag : {NewComplexInstrumentRejectedOptionCode}, body : NewComplexInstrumentRejectedOption ]

EncodeExchangeMessage(message) ==
    CASE message.tag = LoginResponseMessageCode -> EncodeLoginResponseMessage(message.body)
      [] message.tag = ReplayCompleteCode -> << >>
      [] message.tag = LogoutResponseMessageCode -> EncodeLogoutResponseMessage(message.body)
      [] message.tag = ServerHeartbeatCode -> << >>
      [] message.tag = OrderAcknowledgementCode -> EncodeOrderAcknowledgement(message.body)
      [] message.tag = OrderAcknowledgementOptionCode -> EncodeOrderAcknowledgementOption(message.body)
      [] message.tag = OrderRejectedCode -> EncodeOrderRejected(message.body)
      [] message.tag = OrderModifiedCode -> EncodeOrderModified(message.body)
      [] message.tag = ModifyRejectedCode -> EncodeModifyRejected(message.body)
      [] message.tag = OrderExecutionCode -> EncodeOrderExecution(message.body)
      [] message.tag = OrderExecutionOptionCode -> EncodeOrderExecutionOption(message.body)
      [] message.tag = OrderCancelledCode -> EncodeOrderCancelled(message.body)
      [] message.tag = CancelRejectedCode -> EncodeCancelRejected(message.body)
      [] message.tag = MassCancelAcknowledgementCode -> EncodeMassCancelAcknowledgement(message.body)
      [] message.tag = MassCancelRejectedCode -> EncodeMassCancelRejected(message.body)
      [] message.tag = PurgeAcknowledgementCode -> EncodePurgeAcknowledgement(message.body)
      [] message.tag = PurgeRejectedCode -> EncodePurgeRejected(message.body)
      [] message.tag = TradeCancelCorrectCode -> EncodeTradeCancelCorrect(message.body)
      [] message.tag = TradeCancelCorrectOptionCode -> EncodeTradeCancelCorrectOption(message.body)
      [] message.tag = TasRestatementCode -> EncodeTasRestatement(message.body)
      [] message.tag = QuoteUpdateAcknowledgementCode -> EncodeQuoteUpdateAcknowledgement(message.body)
      [] message.tag = QuoteUpdateRejectedCode -> EncodeQuoteUpdateRejected(message.body)
      [] message.tag = QuoteRestatedCode -> EncodeQuoteRestated(message.body)
      [] message.tag = QuoteExecutionCode -> EncodeQuoteExecution(message.body)
      [] message.tag = QuoteCancelledCode -> EncodeQuoteCancelled(message.body)
      [] message.tag = TasQuoteRestatementCode -> EncodeTasQuoteRestatement(message.body)
      [] message.tag = ResetRiskAcknowledgementCode -> EncodeResetRiskAcknowledgement(message.body)
      [] message.tag = NewComplexInstrumentAcceptedOptionCode -> EncodeNewComplexInstrumentAcceptedOption(message.body)
      [] message.tag = NewComplexInstrumentRejectedOptionCode -> EncodeNewComplexInstrumentRejectedOption(message.body)

DecodeExchangeMessage(tag, bytes) ==
    LET read ==
            CASE tag = LoginResponseMessageCode -> DecodeLoginResponseMessage(bytes)
              [] tag = ReplayCompleteCode -> Ok([empty |-> 0], bytes)
              [] tag = LogoutResponseMessageCode -> DecodeLogoutResponseMessage(bytes)
              [] tag = ServerHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = OrderAcknowledgementCode -> DecodeOrderAcknowledgement(bytes)
              [] tag = OrderAcknowledgementOptionCode -> DecodeOrderAcknowledgementOption(bytes)
              [] tag = OrderRejectedCode -> DecodeOrderRejected(bytes)
              [] tag = OrderModifiedCode -> DecodeOrderModified(bytes)
              [] tag = ModifyRejectedCode -> DecodeModifyRejected(bytes)
              [] tag = OrderExecutionCode -> DecodeOrderExecution(bytes)
              [] tag = OrderExecutionOptionCode -> DecodeOrderExecutionOption(bytes)
              [] tag = OrderCancelledCode -> DecodeOrderCancelled(bytes)
              [] tag = CancelRejectedCode -> DecodeCancelRejected(bytes)
              [] tag = MassCancelAcknowledgementCode -> DecodeMassCancelAcknowledgement(bytes)
              [] tag = MassCancelRejectedCode -> DecodeMassCancelRejected(bytes)
              [] tag = PurgeAcknowledgementCode -> DecodePurgeAcknowledgement(bytes)
              [] tag = PurgeRejectedCode -> DecodePurgeRejected(bytes)
              [] tag = TradeCancelCorrectCode -> DecodeTradeCancelCorrect(bytes)
              [] tag = TradeCancelCorrectOptionCode -> DecodeTradeCancelCorrectOption(bytes)
              [] tag = TasRestatementCode -> DecodeTasRestatement(bytes)
              [] tag = QuoteUpdateAcknowledgementCode -> DecodeQuoteUpdateAcknowledgement(bytes)
              [] tag = QuoteUpdateRejectedCode -> DecodeQuoteUpdateRejected(bytes)
              [] tag = QuoteRestatedCode -> DecodeQuoteRestated(bytes)
              [] tag = QuoteExecutionCode -> DecodeQuoteExecution(bytes)
              [] tag = QuoteCancelledCode -> DecodeQuoteCancelled(bytes)
              [] tag = TasQuoteRestatementCode -> DecodeTasQuoteRestatement(bytes)
              [] tag = ResetRiskAcknowledgementCode -> DecodeResetRiskAcknowledgement(bytes)
              [] tag = NewComplexInstrumentAcceptedOptionCode -> DecodeNewComplexInstrumentAcceptedOption(bytes)
              [] tag = NewComplexInstrumentRejectedOptionCode -> DecodeNewComplexInstrumentRejectedOption(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroExchangeMessage == [tag |-> LoginResponseMessageCode, body |-> ZeroLoginResponseMessage]

(* Each Exchange Message in turn, at the values the message it names is checked at *)
CheckedExchangeMessage ==
    { [tag |-> LoginResponseMessageCode, body |-> one] : one \in CheckedLoginResponseMessage }
        \cup { [tag |-> ReplayCompleteCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> LogoutResponseMessageCode, body |-> one] : one \in CheckedLogoutResponseMessage }
        \cup { [tag |-> ServerHeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> OrderAcknowledgementCode, body |-> one] : one \in CheckedOrderAcknowledgement }
        \cup { [tag |-> OrderAcknowledgementOptionCode, body |-> one] : one \in CheckedOrderAcknowledgementOption }
        \cup { [tag |-> OrderRejectedCode, body |-> one] : one \in CheckedOrderRejected }
        \cup { [tag |-> OrderModifiedCode, body |-> one] : one \in CheckedOrderModified }
        \cup { [tag |-> ModifyRejectedCode, body |-> one] : one \in CheckedModifyRejected }
        \cup { [tag |-> OrderExecutionCode, body |-> one] : one \in CheckedOrderExecution }
        \cup { [tag |-> OrderExecutionOptionCode, body |-> one] : one \in CheckedOrderExecutionOption }
        \cup { [tag |-> OrderCancelledCode, body |-> one] : one \in CheckedOrderCancelled }
        \cup { [tag |-> CancelRejectedCode, body |-> one] : one \in CheckedCancelRejected }
        \cup { [tag |-> MassCancelAcknowledgementCode, body |-> one] : one \in CheckedMassCancelAcknowledgement }
        \cup { [tag |-> MassCancelRejectedCode, body |-> one] : one \in CheckedMassCancelRejected }
        \cup { [tag |-> PurgeAcknowledgementCode, body |-> one] : one \in CheckedPurgeAcknowledgement }
        \cup { [tag |-> PurgeRejectedCode, body |-> one] : one \in CheckedPurgeRejected }
        \cup { [tag |-> TradeCancelCorrectCode, body |-> one] : one \in CheckedTradeCancelCorrect }
        \cup { [tag |-> TradeCancelCorrectOptionCode, body |-> one] : one \in CheckedTradeCancelCorrectOption }
        \cup { [tag |-> TasRestatementCode, body |-> one] : one \in CheckedTasRestatement }
        \cup { [tag |-> QuoteUpdateAcknowledgementCode, body |-> one] : one \in CheckedQuoteUpdateAcknowledgement }
        \cup { [tag |-> QuoteUpdateRejectedCode, body |-> one] : one \in CheckedQuoteUpdateRejected }
        \cup { [tag |-> QuoteRestatedCode, body |-> one] : one \in CheckedQuoteRestated }
        \cup { [tag |-> QuoteExecutionCode, body |-> one] : one \in CheckedQuoteExecution }
        \cup { [tag |-> QuoteCancelledCode, body |-> one] : one \in CheckedQuoteCancelled }
        \cup { [tag |-> TasQuoteRestatementCode, body |-> one] : one \in CheckedTasQuoteRestatement }
        \cup { [tag |-> ResetRiskAcknowledgementCode, body |-> one] : one \in CheckedResetRiskAcknowledgement }
        \cup { [tag |-> NewComplexInstrumentAcceptedOptionCode, body |-> one] : one \in CheckedNewComplexInstrumentAcceptedOption }
        \cup { [tag |-> NewComplexInstrumentRejectedOptionCode, body |-> one] : one \in CheckedNewComplexInstrumentRejectedOption }

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

(* Every Order Acknowledgement decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderAcknowledgement ==
    \A message \in CheckedOrderAcknowledgement :
        LET read == DecodeOrderAcknowledgement(EncodeOrderAcknowledgement(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Prevent Match decodes back to what was encoded, and leaves nothing over *)
RoundTripPreventMatch2 ==
    \A message \in CheckedPreventMatch2 :
        LET read == DecodePreventMatch2(EncodePreventMatch2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Acknowledgement Option decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderAcknowledgementOption ==
    \A message \in CheckedOrderAcknowledgementOption :
        LET read == DecodeOrderAcknowledgementOption(EncodeOrderAcknowledgementOption(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Rejected decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderRejected ==
    \A message \in CheckedOrderRejected :
        LET read == DecodeOrderRejected(EncodeOrderRejected(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Modified decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderModified ==
    \A message \in CheckedOrderModified :
        LET read == DecodeOrderModified(EncodeOrderModified(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Rejected decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyRejected ==
    \A message \in CheckedModifyRejected :
        LET read == DecodeModifyRejected(EncodeModifyRejected(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Execution decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecution ==
    \A message \in CheckedOrderExecution :
        LET read == DecodeOrderExecution(EncodeOrderExecution(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Execution Option decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutionOption ==
    \A message \in CheckedOrderExecutionOption :
        LET read == DecodeOrderExecutionOption(EncodeOrderExecutionOption(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancelled decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelled ==
    \A message \in CheckedOrderCancelled :
        LET read == DecodeOrderCancelled(EncodeOrderCancelled(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Rejected decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelRejected ==
    \A message \in CheckedCancelRejected :
        LET read == DecodeCancelRejected(EncodeCancelRejected(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Cancel Acknowledgement decodes back to what was encoded, and leaves nothing over *)
RoundTripMassCancelAcknowledgement ==
    \A message \in CheckedMassCancelAcknowledgement :
        LET read == DecodeMassCancelAcknowledgement(EncodeMassCancelAcknowledgement(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Cancel Rejected decodes back to what was encoded, and leaves nothing over *)
RoundTripMassCancelRejected ==
    \A message \in CheckedMassCancelRejected :
        LET read == DecodeMassCancelRejected(EncodeMassCancelRejected(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Purge Acknowledgement decodes back to what was encoded, and leaves nothing over *)
RoundTripPurgeAcknowledgement ==
    \A message \in CheckedPurgeAcknowledgement :
        LET read == DecodePurgeAcknowledgement(EncodePurgeAcknowledgement(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Purge Rejected decodes back to what was encoded, and leaves nothing over *)
RoundTripPurgeRejected ==
    \A message \in CheckedPurgeRejected :
        LET read == DecodePurgeRejected(EncodePurgeRejected(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Cancel Correct decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCancelCorrect ==
    \A message \in CheckedTradeCancelCorrect :
        LET read == DecodeTradeCancelCorrect(EncodeTradeCancelCorrect(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Cancel Correct Option decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCancelCorrectOption ==
    \A message \in CheckedTradeCancelCorrectOption :
        LET read == DecodeTradeCancelCorrectOption(EncodeTradeCancelCorrectOption(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tas Restatement decodes back to what was encoded, and leaves nothing over *)
RoundTripTasRestatement ==
    \A message \in CheckedTasRestatement :
        LET read == DecodeTasRestatement(EncodeTasRestatement(message))
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

(* Every Quote Update Acknowledgement decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteUpdateAcknowledgement ==
    \A message \in CheckedQuoteUpdateAcknowledgement :
        LET read == DecodeQuoteUpdateAcknowledgement(EncodeQuoteUpdateAcknowledgement(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Update Rejected decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteUpdateRejected ==
    \A message \in CheckedQuoteUpdateRejected :
        LET read == DecodeQuoteUpdateRejected(EncodeQuoteUpdateRejected(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Restated decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteRestated ==
    \A message \in CheckedQuoteRestated :
        LET read == DecodeQuoteRestated(EncodeQuoteRestated(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Execution decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteExecution ==
    \A message \in CheckedQuoteExecution :
        LET read == DecodeQuoteExecution(EncodeQuoteExecution(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Cancelled decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteCancelled ==
    \A message \in CheckedQuoteCancelled :
        LET read == DecodeQuoteCancelled(EncodeQuoteCancelled(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tas Quote Restatement decodes back to what was encoded, and leaves nothing over *)
RoundTripTasQuoteRestatement ==
    \A message \in CheckedTasQuoteRestatement :
        LET read == DecodeTasQuoteRestatement(EncodeTasQuoteRestatement(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reset Risk Acknowledgement decodes back to what was encoded, and leaves nothing over *)
RoundTripResetRiskAcknowledgement ==
    \A message \in CheckedResetRiskAcknowledgement :
        LET read == DecodeResetRiskAcknowledgement(EncodeResetRiskAcknowledgement(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Leg decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionLeg ==
    \A message \in CheckedOptionLeg :
        LET read == DecodeOptionLeg(EncodeOptionLeg(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Complex Instrument Accepted Option decodes back to what was encoded, and leaves nothing over *)
RoundTripNewComplexInstrumentAcceptedOption ==
    \A message \in CheckedNewComplexInstrumentAcceptedOption :
        LET read == DecodeNewComplexInstrumentAcceptedOption(EncodeNewComplexInstrumentAcceptedOption(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Complex Instrument Rejected Option decodes back to what was encoded, and leaves nothing over *)
RoundTripNewComplexInstrumentRejectedOption ==
    \A message \in CheckedNewComplexInstrumentRejectedOption :
        LET read == DecodeNewComplexInstrumentRejectedOption(EncodeNewComplexInstrumentRejectedOption(message))
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
