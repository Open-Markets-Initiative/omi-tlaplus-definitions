----------- MODULE CxjEquities_BinaryOrderEntry_v1_0_12_Exchange -----------
(***************************************************************************)
(* Chicago Board Options Exchange Binary Order Entry v1.0.12               *)
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
(* Order Acknowledgement Jp Equities V 1: 104 bytes                        *)
(***************************************************************************)

OrderAcknowledgementJpEquitiesV1 ==
    [ transactionTime        : Sample(8),
      account                : Sample(10),
      tradingFirm            : Sample(4),
      clOrdId                : Sample(20),
      orderId                : Sample(8),
      orderQty               : Sample(4),
      ordType                : Sample(1),
      price                  : Sample(8),
      capacity               : Sample(1),
      side                   : Sample(1),
      symbol                 : Sample(8),
      timeInForce            : Sample(1),
      expireTime             : Sample(8),
      cashMargin             : Sample(1),
      riskGroupId            : Sample(2),
      noTradeFeat            : Sample(1),
      noTradeKey             : Sample(10),
      postingInstruction     : Sample(1),
      orderClassification    : Sample(1),
      marginTransactionType  : Sample(1),
      baseLiquidityIndicator : Sample(1),
      companyId              : Sample(4) ]

EncodeOrderAcknowledgementJpEquitiesV1(message) ==
    message.transactionTime
        \o message.account
        \o message.tradingFirm
        \o message.clOrdId
        \o message.orderId
        \o message.orderQty
        \o message.ordType
        \o message.price
        \o message.capacity
        \o message.side
        \o message.symbol
        \o message.timeInForce
        \o message.expireTime
        \o message.cashMargin
        \o message.riskGroupId
        \o message.noTradeFeat
        \o message.noTradeKey
        \o message.postingInstruction
        \o message.orderClassification
        \o message.marginTransactionType
        \o message.baseLiquidityIndicator
        \o message.companyId

DecodeOrderAcknowledgementJpEquitiesV1(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET account == ReadBytes(transactionTime.rest, 10) IN IF ~account.ok THEN Fail ELSE
    LET tradingFirm == ReadBytes(account.rest, 4) IN IF ~tradingFirm.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(tradingFirm.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clOrdId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(orderId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET ordType == ReadBytes(orderQty.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET price == ReadBytes(ordType.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET capacity == ReadBytes(price.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET side == ReadBytes(capacity.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET symbol == ReadBytes(side.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(symbol.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET expireTime == ReadBytes(timeInForce.rest, 8) IN IF ~expireTime.ok THEN Fail ELSE
    LET cashMargin == ReadBytes(expireTime.rest, 1) IN IF ~cashMargin.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(cashMargin.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET noTradeFeat == ReadBytes(riskGroupId.rest, 1) IN IF ~noTradeFeat.ok THEN Fail ELSE
    LET noTradeKey == ReadBytes(noTradeFeat.rest, 10) IN IF ~noTradeKey.ok THEN Fail ELSE
    LET postingInstruction == ReadBytes(noTradeKey.rest, 1) IN IF ~postingInstruction.ok THEN Fail ELSE
    LET orderClassification == ReadBytes(postingInstruction.rest, 1) IN IF ~orderClassification.ok THEN Fail ELSE
    LET marginTransactionType == ReadBytes(orderClassification.rest, 1) IN IF ~marginTransactionType.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadBytes(marginTransactionType.rest, 1) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET companyId == ReadBytes(baseLiquidityIndicator.rest, 4) IN IF ~companyId.ok THEN Fail ELSE
    Ok([ transactionTime        |-> transactionTime.value,
         account                |-> account.value,
         tradingFirm            |-> tradingFirm.value,
         clOrdId                |-> clOrdId.value,
         orderId                |-> orderId.value,
         orderQty               |-> orderQty.value,
         ordType                |-> ordType.value,
         price                  |-> price.value,
         capacity               |-> capacity.value,
         side                   |-> side.value,
         symbol                 |-> symbol.value,
         timeInForce            |-> timeInForce.value,
         expireTime             |-> expireTime.value,
         cashMargin             |-> cashMargin.value,
         riskGroupId            |-> riskGroupId.value,
         noTradeFeat            |-> noTradeFeat.value,
         noTradeKey             |-> noTradeKey.value,
         postingInstruction     |-> postingInstruction.value,
         orderClassification    |-> orderClassification.value,
         marginTransactionType  |-> marginTransactionType.value,
         baseLiquidityIndicator |-> baseLiquidityIndicator.value,
         companyId              |-> companyId.value ], companyId.rest)

ZeroOrderAcknowledgementJpEquitiesV1 ==
    [ transactionTime        |-> [i \in 1 .. 8 |-> 0],
      account                |-> [i \in 1 .. 10 |-> 0],
      tradingFirm            |-> [i \in 1 .. 4 |-> 0],
      clOrdId                |-> [i \in 1 .. 20 |-> 0],
      orderId                |-> [i \in 1 .. 8 |-> 0],
      orderQty               |-> [i \in 1 .. 4 |-> 0],
      ordType                |-> [i \in 1 .. 1 |-> 0],
      price                  |-> [i \in 1 .. 8 |-> 0],
      capacity               |-> [i \in 1 .. 1 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      symbol                 |-> [i \in 1 .. 8 |-> 0],
      timeInForce            |-> [i \in 1 .. 1 |-> 0],
      expireTime             |-> [i \in 1 .. 8 |-> 0],
      cashMargin             |-> [i \in 1 .. 1 |-> 0],
      riskGroupId            |-> [i \in 1 .. 2 |-> 0],
      noTradeFeat            |-> [i \in 1 .. 1 |-> 0],
      noTradeKey             |-> [i \in 1 .. 10 |-> 0],
      postingInstruction     |-> [i \in 1 .. 1 |-> 0],
      orderClassification    |-> [i \in 1 .. 1 |-> 0],
      marginTransactionType  |-> [i \in 1 .. 1 |-> 0],
      baseLiquidityIndicator |-> [i \in 1 .. 1 |-> 0],
      companyId              |-> [i \in 1 .. 4 |-> 0] ]

(* Order Acknowledgement Jp Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedOrderAcknowledgementJpEquitiesV1 ==
    { ZeroOrderAcknowledgementJpEquitiesV1 }
        \cup { [ZeroOrderAcknowledgementJpEquitiesV1 EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgementJpEquitiesV1 EXCEPT !.account = one] : one \in Sample(10) }
        \cup { [ZeroOrderAcknowledgementJpEquitiesV1 EXCEPT !.tradingFirm = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcknowledgementJpEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderAcknowledgementJpEquitiesV1 EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgementJpEquitiesV1 EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcknowledgementJpEquitiesV1 EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementJpEquitiesV1 EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgementJpEquitiesV1 EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementJpEquitiesV1 EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementJpEquitiesV1 EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgementJpEquitiesV1 EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementJpEquitiesV1 EXCEPT !.expireTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgementJpEquitiesV1 EXCEPT !.cashMargin = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementJpEquitiesV1 EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroOrderAcknowledgementJpEquitiesV1 EXCEPT !.noTradeFeat = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementJpEquitiesV1 EXCEPT !.noTradeKey = one] : one \in Sample(10) }
        \cup { [ZeroOrderAcknowledgementJpEquitiesV1 EXCEPT !.postingInstruction = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementJpEquitiesV1 EXCEPT !.orderClassification = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementJpEquitiesV1 EXCEPT !.marginTransactionType = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementJpEquitiesV1 EXCEPT !.baseLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementJpEquitiesV1 EXCEPT !.companyId = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Rejected Jp Equities V 1: 93 bytes                                *)
(***************************************************************************)

OrderRejectedJpEquitiesV1 ==
    [ transactionTime   : Sample(8),
      tradingFirm       : Sample(4),
      clOrdId           : Sample(20),
      orderRejectReason : Sample(1),
      text              : Sample(60) ]

EncodeOrderRejectedJpEquitiesV1(message) ==
    message.transactionTime
        \o message.tradingFirm
        \o message.clOrdId
        \o message.orderRejectReason
        \o message.text

DecodeOrderRejectedJpEquitiesV1(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET tradingFirm == ReadBytes(transactionTime.rest, 4) IN IF ~tradingFirm.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(tradingFirm.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET orderRejectReason == ReadBytes(clOrdId.rest, 1) IN IF ~orderRejectReason.ok THEN Fail ELSE
    LET text == ReadBytes(orderRejectReason.rest, 60) IN IF ~text.ok THEN Fail ELSE
    Ok([ transactionTime   |-> transactionTime.value,
         tradingFirm       |-> tradingFirm.value,
         clOrdId           |-> clOrdId.value,
         orderRejectReason |-> orderRejectReason.value,
         text              |-> text.value ], text.rest)

ZeroOrderRejectedJpEquitiesV1 ==
    [ transactionTime   |-> [i \in 1 .. 8 |-> 0],
      tradingFirm       |-> [i \in 1 .. 4 |-> 0],
      clOrdId           |-> [i \in 1 .. 20 |-> 0],
      orderRejectReason |-> [i \in 1 .. 1 |-> 0],
      text              |-> [i \in 1 .. 60 |-> 0] ]

(* Order Rejected Jp Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedOrderRejectedJpEquitiesV1 ==
    { ZeroOrderRejectedJpEquitiesV1 }
        \cup { [ZeroOrderRejectedJpEquitiesV1 EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderRejectedJpEquitiesV1 EXCEPT !.tradingFirm = one] : one \in Sample(4) }
        \cup { [ZeroOrderRejectedJpEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderRejectedJpEquitiesV1 EXCEPT !.orderRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroOrderRejectedJpEquitiesV1 EXCEPT !.text = one] : one \in Sample(60) }

(***************************************************************************)
(* Order Modified Jp Equities V 1: 81 bytes                                *)
(***************************************************************************)

OrderModifiedJpEquitiesV1 ==
    [ transactionTime        : Sample(8),
      tradingFirm            : Sample(4),
      clOrdId                : Sample(20),
      orderQty               : Sample(4),
      origClOrdId            : Sample(20),
      orderId                : Sample(8),
      price                  : Sample(8),
      leavesQty              : Sample(4),
      baseLiquidityIndicator : Sample(1),
      companyId              : Sample(4) ]

EncodeOrderModifiedJpEquitiesV1(message) ==
    message.transactionTime
        \o message.tradingFirm
        \o message.clOrdId
        \o message.orderQty
        \o message.origClOrdId
        \o message.orderId
        \o message.price
        \o message.leavesQty
        \o message.baseLiquidityIndicator
        \o message.companyId

DecodeOrderModifiedJpEquitiesV1(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET tradingFirm == ReadBytes(transactionTime.rest, 4) IN IF ~tradingFirm.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(tradingFirm.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(clOrdId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(orderQty.rest, 20) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET orderId == ReadBytes(origClOrdId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET price == ReadBytes(orderId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(price.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadBytes(leavesQty.rest, 1) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET companyId == ReadBytes(baseLiquidityIndicator.rest, 4) IN IF ~companyId.ok THEN Fail ELSE
    Ok([ transactionTime        |-> transactionTime.value,
         tradingFirm            |-> tradingFirm.value,
         clOrdId                |-> clOrdId.value,
         orderQty               |-> orderQty.value,
         origClOrdId            |-> origClOrdId.value,
         orderId                |-> orderId.value,
         price                  |-> price.value,
         leavesQty              |-> leavesQty.value,
         baseLiquidityIndicator |-> baseLiquidityIndicator.value,
         companyId              |-> companyId.value ], companyId.rest)

ZeroOrderModifiedJpEquitiesV1 ==
    [ transactionTime        |-> [i \in 1 .. 8 |-> 0],
      tradingFirm            |-> [i \in 1 .. 4 |-> 0],
      clOrdId                |-> [i \in 1 .. 20 |-> 0],
      orderQty               |-> [i \in 1 .. 4 |-> 0],
      origClOrdId            |-> [i \in 1 .. 20 |-> 0],
      orderId                |-> [i \in 1 .. 8 |-> 0],
      price                  |-> [i \in 1 .. 8 |-> 0],
      leavesQty              |-> [i \in 1 .. 4 |-> 0],
      baseLiquidityIndicator |-> [i \in 1 .. 1 |-> 0],
      companyId              |-> [i \in 1 .. 4 |-> 0] ]

(* Order Modified Jp Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedOrderModifiedJpEquitiesV1 ==
    { ZeroOrderModifiedJpEquitiesV1 }
        \cup { [ZeroOrderModifiedJpEquitiesV1 EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifiedJpEquitiesV1 EXCEPT !.tradingFirm = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifiedJpEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderModifiedJpEquitiesV1 EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifiedJpEquitiesV1 EXCEPT !.origClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderModifiedJpEquitiesV1 EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifiedJpEquitiesV1 EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifiedJpEquitiesV1 EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifiedJpEquitiesV1 EXCEPT !.baseLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifiedJpEquitiesV1 EXCEPT !.companyId = one] : one \in Sample(4) }

(***************************************************************************)
(* Modify Rejected Jp Equities V 1: 113 bytes                              *)
(***************************************************************************)

ModifyRejectedJpEquitiesV1 ==
    [ transactionTime    : Sample(8),
      tradingFirm        : Sample(4),
      clOrdId            : Sample(20),
      origClOrdId        : Sample(20),
      modifyRejectReason : Sample(1),
      text               : Sample(60) ]

EncodeModifyRejectedJpEquitiesV1(message) ==
    message.transactionTime
        \o message.tradingFirm
        \o message.clOrdId
        \o message.origClOrdId
        \o message.modifyRejectReason
        \o message.text

DecodeModifyRejectedJpEquitiesV1(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET tradingFirm == ReadBytes(transactionTime.rest, 4) IN IF ~tradingFirm.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(tradingFirm.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 20) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET modifyRejectReason == ReadBytes(origClOrdId.rest, 1) IN IF ~modifyRejectReason.ok THEN Fail ELSE
    LET text == ReadBytes(modifyRejectReason.rest, 60) IN IF ~text.ok THEN Fail ELSE
    Ok([ transactionTime    |-> transactionTime.value,
         tradingFirm        |-> tradingFirm.value,
         clOrdId            |-> clOrdId.value,
         origClOrdId        |-> origClOrdId.value,
         modifyRejectReason |-> modifyRejectReason.value,
         text               |-> text.value ], text.rest)

ZeroModifyRejectedJpEquitiesV1 ==
    [ transactionTime    |-> [i \in 1 .. 8 |-> 0],
      tradingFirm        |-> [i \in 1 .. 4 |-> 0],
      clOrdId            |-> [i \in 1 .. 20 |-> 0],
      origClOrdId        |-> [i \in 1 .. 20 |-> 0],
      modifyRejectReason |-> [i \in 1 .. 1 |-> 0],
      text               |-> [i \in 1 .. 60 |-> 0] ]

(* Modify Rejected Jp Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedModifyRejectedJpEquitiesV1 ==
    { ZeroModifyRejectedJpEquitiesV1 }
        \cup { [ZeroModifyRejectedJpEquitiesV1 EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroModifyRejectedJpEquitiesV1 EXCEPT !.tradingFirm = one] : one \in Sample(4) }
        \cup { [ZeroModifyRejectedJpEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroModifyRejectedJpEquitiesV1 EXCEPT !.origClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroModifyRejectedJpEquitiesV1 EXCEPT !.modifyRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroModifyRejectedJpEquitiesV1 EXCEPT !.text = one] : one \in Sample(60) }

(***************************************************************************)
(* Order Restated Jp Equities V 1: 78 bytes                                *)
(***************************************************************************)

OrderRestatedJpEquitiesV1 ==
    [ transactionTime        : Sample(8),
      tradingFirm            : Sample(4),
      clOrdId                : Sample(20),
      orderId                : Sample(8),
      orderQty               : Sample(4),
      price                  : Sample(8),
      leavesQty              : Sample(4),
      secondaryOrderId       : Sample(8),
      lastPx                 : Sample(8),
      lastShares             : Sample(4),
      baseLiquidityIndicator : Sample(1),
      restatementReason      : Sample(1) ]

EncodeOrderRestatedJpEquitiesV1(message) ==
    message.transactionTime
        \o message.tradingFirm
        \o message.clOrdId
        \o message.orderId
        \o message.orderQty
        \o message.price
        \o message.leavesQty
        \o message.secondaryOrderId
        \o message.lastPx
        \o message.lastShares
        \o message.baseLiquidityIndicator
        \o message.restatementReason

DecodeOrderRestatedJpEquitiesV1(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET tradingFirm == ReadBytes(transactionTime.rest, 4) IN IF ~tradingFirm.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(tradingFirm.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clOrdId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(orderId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET price == ReadBytes(orderQty.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(price.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET secondaryOrderId == ReadBytes(leavesQty.rest, 8) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET lastPx == ReadBytes(secondaryOrderId.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastShares == ReadBytes(lastPx.rest, 4) IN IF ~lastShares.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadBytes(lastShares.rest, 1) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET restatementReason == ReadBytes(baseLiquidityIndicator.rest, 1) IN IF ~restatementReason.ok THEN Fail ELSE
    Ok([ transactionTime        |-> transactionTime.value,
         tradingFirm            |-> tradingFirm.value,
         clOrdId                |-> clOrdId.value,
         orderId                |-> orderId.value,
         orderQty               |-> orderQty.value,
         price                  |-> price.value,
         leavesQty              |-> leavesQty.value,
         secondaryOrderId       |-> secondaryOrderId.value,
         lastPx                 |-> lastPx.value,
         lastShares             |-> lastShares.value,
         baseLiquidityIndicator |-> baseLiquidityIndicator.value,
         restatementReason      |-> restatementReason.value ], restatementReason.rest)

ZeroOrderRestatedJpEquitiesV1 ==
    [ transactionTime        |-> [i \in 1 .. 8 |-> 0],
      tradingFirm            |-> [i \in 1 .. 4 |-> 0],
      clOrdId                |-> [i \in 1 .. 20 |-> 0],
      orderId                |-> [i \in 1 .. 8 |-> 0],
      orderQty               |-> [i \in 1 .. 4 |-> 0],
      price                  |-> [i \in 1 .. 8 |-> 0],
      leavesQty              |-> [i \in 1 .. 4 |-> 0],
      secondaryOrderId       |-> [i \in 1 .. 8 |-> 0],
      lastPx                 |-> [i \in 1 .. 8 |-> 0],
      lastShares             |-> [i \in 1 .. 4 |-> 0],
      baseLiquidityIndicator |-> [i \in 1 .. 1 |-> 0],
      restatementReason      |-> [i \in 1 .. 1 |-> 0] ]

(* Order Restated Jp Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedOrderRestatedJpEquitiesV1 ==
    { ZeroOrderRestatedJpEquitiesV1 }
        \cup { [ZeroOrderRestatedJpEquitiesV1 EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderRestatedJpEquitiesV1 EXCEPT !.tradingFirm = one] : one \in Sample(4) }
        \cup { [ZeroOrderRestatedJpEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderRestatedJpEquitiesV1 EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderRestatedJpEquitiesV1 EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderRestatedJpEquitiesV1 EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderRestatedJpEquitiesV1 EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderRestatedJpEquitiesV1 EXCEPT !.secondaryOrderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderRestatedJpEquitiesV1 EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroOrderRestatedJpEquitiesV1 EXCEPT !.lastShares = one] : one \in Sample(4) }
        \cup { [ZeroOrderRestatedJpEquitiesV1 EXCEPT !.baseLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderRestatedJpEquitiesV1 EXCEPT !.restatementReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Execution Jp Equities V 1: 67 bytes                               *)
(***************************************************************************)

OrderExecutionJpEquitiesV1 ==
    [ transactionTime        : Sample(8),
      tradingFirm            : Sample(4),
      clOrdId                : Sample(20),
      execId                 : Sample(8),
      lastCapacity           : Sample(1),
      lastPx                 : Sample(8),
      lastShares             : Sample(4),
      side                   : Sample(1),
      symbol                 : Sample(8),
      leavesQty              : Sample(4),
      baseLiquidityIndicator : Sample(1) ]

EncodeOrderExecutionJpEquitiesV1(message) ==
    message.transactionTime
        \o message.tradingFirm
        \o message.clOrdId
        \o message.execId
        \o message.lastCapacity
        \o message.lastPx
        \o message.lastShares
        \o message.side
        \o message.symbol
        \o message.leavesQty
        \o message.baseLiquidityIndicator

DecodeOrderExecutionJpEquitiesV1(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET tradingFirm == ReadBytes(transactionTime.rest, 4) IN IF ~tradingFirm.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(tradingFirm.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET execId == ReadBytes(clOrdId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET lastCapacity == ReadBytes(execId.rest, 1) IN IF ~lastCapacity.ok THEN Fail ELSE
    LET lastPx == ReadBytes(lastCapacity.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastShares == ReadBytes(lastPx.rest, 4) IN IF ~lastShares.ok THEN Fail ELSE
    LET side == ReadBytes(lastShares.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET symbol == ReadBytes(side.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(symbol.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadBytes(leavesQty.rest, 1) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    Ok([ transactionTime        |-> transactionTime.value,
         tradingFirm            |-> tradingFirm.value,
         clOrdId                |-> clOrdId.value,
         execId                 |-> execId.value,
         lastCapacity           |-> lastCapacity.value,
         lastPx                 |-> lastPx.value,
         lastShares             |-> lastShares.value,
         side                   |-> side.value,
         symbol                 |-> symbol.value,
         leavesQty              |-> leavesQty.value,
         baseLiquidityIndicator |-> baseLiquidityIndicator.value ], baseLiquidityIndicator.rest)

ZeroOrderExecutionJpEquitiesV1 ==
    [ transactionTime        |-> [i \in 1 .. 8 |-> 0],
      tradingFirm            |-> [i \in 1 .. 4 |-> 0],
      clOrdId                |-> [i \in 1 .. 20 |-> 0],
      execId                 |-> [i \in 1 .. 8 |-> 0],
      lastCapacity           |-> [i \in 1 .. 1 |-> 0],
      lastPx                 |-> [i \in 1 .. 8 |-> 0],
      lastShares             |-> [i \in 1 .. 4 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      symbol                 |-> [i \in 1 .. 8 |-> 0],
      leavesQty              |-> [i \in 1 .. 4 |-> 0],
      baseLiquidityIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Order Execution Jp Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutionJpEquitiesV1 ==
    { ZeroOrderExecutionJpEquitiesV1 }
        \cup { [ZeroOrderExecutionJpEquitiesV1 EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionJpEquitiesV1 EXCEPT !.tradingFirm = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionJpEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderExecutionJpEquitiesV1 EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionJpEquitiesV1 EXCEPT !.lastCapacity = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionJpEquitiesV1 EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionJpEquitiesV1 EXCEPT !.lastShares = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionJpEquitiesV1 EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionJpEquitiesV1 EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionJpEquitiesV1 EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionJpEquitiesV1 EXCEPT !.baseLiquidityIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Cancelled Jp Equities V 1: 33 bytes                               *)
(***************************************************************************)

OrderCancelledJpEquitiesV1 ==
    [ transactionTime : Sample(8),
      tradingFirm     : Sample(4),
      clOrdId         : Sample(20),
      cancelReason    : Sample(1) ]

EncodeOrderCancelledJpEquitiesV1(message) ==
    message.transactionTime
        \o message.tradingFirm
        \o message.clOrdId
        \o message.cancelReason

DecodeOrderCancelledJpEquitiesV1(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET tradingFirm == ReadBytes(transactionTime.rest, 4) IN IF ~tradingFirm.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(tradingFirm.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET cancelReason == ReadBytes(clOrdId.rest, 1) IN IF ~cancelReason.ok THEN Fail ELSE
    Ok([ transactionTime |-> transactionTime.value,
         tradingFirm     |-> tradingFirm.value,
         clOrdId         |-> clOrdId.value,
         cancelReason    |-> cancelReason.value ], cancelReason.rest)

ZeroOrderCancelledJpEquitiesV1 ==
    [ transactionTime |-> [i \in 1 .. 8 |-> 0],
      tradingFirm     |-> [i \in 1 .. 4 |-> 0],
      clOrdId         |-> [i \in 1 .. 20 |-> 0],
      cancelReason    |-> [i \in 1 .. 1 |-> 0] ]

(* Order Cancelled Jp Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelledJpEquitiesV1 ==
    { ZeroOrderCancelledJpEquitiesV1 }
        \cup { [ZeroOrderCancelledJpEquitiesV1 EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelledJpEquitiesV1 EXCEPT !.tradingFirm = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelledJpEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderCancelledJpEquitiesV1 EXCEPT !.cancelReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Cancel Rejected Jp Equities V 1: 93 bytes                               *)
(***************************************************************************)

CancelRejectedJpEquitiesV1 ==
    [ transactionTime    : Sample(8),
      tradingFirm        : Sample(4),
      clOrdId            : Sample(20),
      cancelRejectReason : Sample(1),
      text               : Sample(60) ]

EncodeCancelRejectedJpEquitiesV1(message) ==
    message.transactionTime
        \o message.tradingFirm
        \o message.clOrdId
        \o message.cancelRejectReason
        \o message.text

DecodeCancelRejectedJpEquitiesV1(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET tradingFirm == ReadBytes(transactionTime.rest, 4) IN IF ~tradingFirm.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(tradingFirm.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET cancelRejectReason == ReadBytes(clOrdId.rest, 1) IN IF ~cancelRejectReason.ok THEN Fail ELSE
    LET text == ReadBytes(cancelRejectReason.rest, 60) IN IF ~text.ok THEN Fail ELSE
    Ok([ transactionTime    |-> transactionTime.value,
         tradingFirm        |-> tradingFirm.value,
         clOrdId            |-> clOrdId.value,
         cancelRejectReason |-> cancelRejectReason.value,
         text               |-> text.value ], text.rest)

ZeroCancelRejectedJpEquitiesV1 ==
    [ transactionTime    |-> [i \in 1 .. 8 |-> 0],
      tradingFirm        |-> [i \in 1 .. 4 |-> 0],
      clOrdId            |-> [i \in 1 .. 20 |-> 0],
      cancelRejectReason |-> [i \in 1 .. 1 |-> 0],
      text               |-> [i \in 1 .. 60 |-> 0] ]

(* Cancel Rejected Jp Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedCancelRejectedJpEquitiesV1 ==
    { ZeroCancelRejectedJpEquitiesV1 }
        \cup { [ZeroCancelRejectedJpEquitiesV1 EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroCancelRejectedJpEquitiesV1 EXCEPT !.tradingFirm = one] : one \in Sample(4) }
        \cup { [ZeroCancelRejectedJpEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroCancelRejectedJpEquitiesV1 EXCEPT !.cancelRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroCancelRejectedJpEquitiesV1 EXCEPT !.text = one] : one \in Sample(60) }

(***************************************************************************)
(* Purge Acknowledgement Jp Equities V 1: 32 bytes                         *)
(***************************************************************************)

PurgeAcknowledgementJpEquitiesV1 ==
    [ transactionTime     : Sample(8),
      massCancelId        : Sample(20),
      cancelledOrderCount : Sample(4) ]

EncodePurgeAcknowledgementJpEquitiesV1(message) ==
    message.transactionTime
        \o message.massCancelId
        \o message.cancelledOrderCount

DecodePurgeAcknowledgementJpEquitiesV1(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET massCancelId == ReadBytes(transactionTime.rest, 20) IN IF ~massCancelId.ok THEN Fail ELSE
    LET cancelledOrderCount == ReadBytes(massCancelId.rest, 4) IN IF ~cancelledOrderCount.ok THEN Fail ELSE
    Ok([ transactionTime     |-> transactionTime.value,
         massCancelId        |-> massCancelId.value,
         cancelledOrderCount |-> cancelledOrderCount.value ], cancelledOrderCount.rest)

ZeroPurgeAcknowledgementJpEquitiesV1 ==
    [ transactionTime     |-> [i \in 1 .. 8 |-> 0],
      massCancelId        |-> [i \in 1 .. 20 |-> 0],
      cancelledOrderCount |-> [i \in 1 .. 4 |-> 0] ]

(* Purge Acknowledgement Jp Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedPurgeAcknowledgementJpEquitiesV1 ==
    { ZeroPurgeAcknowledgementJpEquitiesV1 }
        \cup { [ZeroPurgeAcknowledgementJpEquitiesV1 EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroPurgeAcknowledgementJpEquitiesV1 EXCEPT !.massCancelId = one] : one \in Sample(20) }
        \cup { [ZeroPurgeAcknowledgementJpEquitiesV1 EXCEPT !.cancelledOrderCount = one] : one \in Sample(4) }

(***************************************************************************)
(* Purge Rejected Jp Equities V 1: 89 bytes                                *)
(***************************************************************************)

PurgeRejectedJpEquitiesV1 ==
    [ transactionTime   : Sample(8),
      massCancelId      : Sample(20),
      purgeRejectReason : Sample(1),
      text              : Sample(60) ]

EncodePurgeRejectedJpEquitiesV1(message) ==
    message.transactionTime
        \o message.massCancelId
        \o message.purgeRejectReason
        \o message.text

DecodePurgeRejectedJpEquitiesV1(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET massCancelId == ReadBytes(transactionTime.rest, 20) IN IF ~massCancelId.ok THEN Fail ELSE
    LET purgeRejectReason == ReadBytes(massCancelId.rest, 1) IN IF ~purgeRejectReason.ok THEN Fail ELSE
    LET text == ReadBytes(purgeRejectReason.rest, 60) IN IF ~text.ok THEN Fail ELSE
    Ok([ transactionTime   |-> transactionTime.value,
         massCancelId      |-> massCancelId.value,
         purgeRejectReason |-> purgeRejectReason.value,
         text              |-> text.value ], text.rest)

ZeroPurgeRejectedJpEquitiesV1 ==
    [ transactionTime   |-> [i \in 1 .. 8 |-> 0],
      massCancelId      |-> [i \in 1 .. 20 |-> 0],
      purgeRejectReason |-> [i \in 1 .. 1 |-> 0],
      text              |-> [i \in 1 .. 60 |-> 0] ]

(* Purge Rejected Jp Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedPurgeRejectedJpEquitiesV1 ==
    { ZeroPurgeRejectedJpEquitiesV1 }
        \cup { [ZeroPurgeRejectedJpEquitiesV1 EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroPurgeRejectedJpEquitiesV1 EXCEPT !.massCancelId = one] : one \in Sample(20) }
        \cup { [ZeroPurgeRejectedJpEquitiesV1 EXCEPT !.purgeRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroPurgeRejectedJpEquitiesV1 EXCEPT !.text = one] : one \in Sample(60) }

(***************************************************************************)
(* Exchange Message, selected by Exchange Message Type                     *)
(***************************************************************************)

LoginResponseMessageCode == 501  \* 0x1f5
ReplayCompleteCode == 502  \* 0x1f6
LogoutResponseMessageCode == 503  \* 0x1f7
ServerHeartbeatCode == 504  \* 0x1f8
OrderAcknowledgementJpEquitiesV1Code == 5501  \* 0x157d
OrderRejectedJpEquitiesV1Code == 5502  \* 0x157e
OrderModifiedJpEquitiesV1Code == 5503  \* 0x157f
ModifyRejectedJpEquitiesV1Code == 5504  \* 0x1580
OrderRestatedJpEquitiesV1Code == 5505  \* 0x1581
OrderExecutionJpEquitiesV1Code == 5506  \* 0x1582
OrderCancelledJpEquitiesV1Code == 5507  \* 0x1583
CancelRejectedJpEquitiesV1Code == 5508  \* 0x1584
PurgeAcknowledgementJpEquitiesV1Code == 5510  \* 0x1586
PurgeRejectedJpEquitiesV1Code == 5511  \* 0x1587

ExchangeMessage ==
    [ tag : {LoginResponseMessageCode}, body : LoginResponseMessage ]
        \cup [ tag : {ReplayCompleteCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {LogoutResponseMessageCode}, body : LogoutResponseMessage ]
        \cup [ tag : {ServerHeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {OrderAcknowledgementJpEquitiesV1Code}, body : OrderAcknowledgementJpEquitiesV1 ]
        \cup [ tag : {OrderRejectedJpEquitiesV1Code}, body : OrderRejectedJpEquitiesV1 ]
        \cup [ tag : {OrderModifiedJpEquitiesV1Code}, body : OrderModifiedJpEquitiesV1 ]
        \cup [ tag : {ModifyRejectedJpEquitiesV1Code}, body : ModifyRejectedJpEquitiesV1 ]
        \cup [ tag : {OrderRestatedJpEquitiesV1Code}, body : OrderRestatedJpEquitiesV1 ]
        \cup [ tag : {OrderExecutionJpEquitiesV1Code}, body : OrderExecutionJpEquitiesV1 ]
        \cup [ tag : {OrderCancelledJpEquitiesV1Code}, body : OrderCancelledJpEquitiesV1 ]
        \cup [ tag : {CancelRejectedJpEquitiesV1Code}, body : CancelRejectedJpEquitiesV1 ]
        \cup [ tag : {PurgeAcknowledgementJpEquitiesV1Code}, body : PurgeAcknowledgementJpEquitiesV1 ]
        \cup [ tag : {PurgeRejectedJpEquitiesV1Code}, body : PurgeRejectedJpEquitiesV1 ]

EncodeExchangeMessage(message) ==
    CASE message.tag = LoginResponseMessageCode -> EncodeLoginResponseMessage(message.body)
      [] message.tag = ReplayCompleteCode -> << >>
      [] message.tag = LogoutResponseMessageCode -> EncodeLogoutResponseMessage(message.body)
      [] message.tag = ServerHeartbeatCode -> << >>
      [] message.tag = OrderAcknowledgementJpEquitiesV1Code -> EncodeOrderAcknowledgementJpEquitiesV1(message.body)
      [] message.tag = OrderRejectedJpEquitiesV1Code -> EncodeOrderRejectedJpEquitiesV1(message.body)
      [] message.tag = OrderModifiedJpEquitiesV1Code -> EncodeOrderModifiedJpEquitiesV1(message.body)
      [] message.tag = ModifyRejectedJpEquitiesV1Code -> EncodeModifyRejectedJpEquitiesV1(message.body)
      [] message.tag = OrderRestatedJpEquitiesV1Code -> EncodeOrderRestatedJpEquitiesV1(message.body)
      [] message.tag = OrderExecutionJpEquitiesV1Code -> EncodeOrderExecutionJpEquitiesV1(message.body)
      [] message.tag = OrderCancelledJpEquitiesV1Code -> EncodeOrderCancelledJpEquitiesV1(message.body)
      [] message.tag = CancelRejectedJpEquitiesV1Code -> EncodeCancelRejectedJpEquitiesV1(message.body)
      [] message.tag = PurgeAcknowledgementJpEquitiesV1Code -> EncodePurgeAcknowledgementJpEquitiesV1(message.body)
      [] message.tag = PurgeRejectedJpEquitiesV1Code -> EncodePurgeRejectedJpEquitiesV1(message.body)

DecodeExchangeMessage(tag, bytes) ==
    LET read ==
            CASE tag = LoginResponseMessageCode -> DecodeLoginResponseMessage(bytes)
              [] tag = ReplayCompleteCode -> Ok([empty |-> 0], bytes)
              [] tag = LogoutResponseMessageCode -> DecodeLogoutResponseMessage(bytes)
              [] tag = ServerHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = OrderAcknowledgementJpEquitiesV1Code -> DecodeOrderAcknowledgementJpEquitiesV1(bytes)
              [] tag = OrderRejectedJpEquitiesV1Code -> DecodeOrderRejectedJpEquitiesV1(bytes)
              [] tag = OrderModifiedJpEquitiesV1Code -> DecodeOrderModifiedJpEquitiesV1(bytes)
              [] tag = ModifyRejectedJpEquitiesV1Code -> DecodeModifyRejectedJpEquitiesV1(bytes)
              [] tag = OrderRestatedJpEquitiesV1Code -> DecodeOrderRestatedJpEquitiesV1(bytes)
              [] tag = OrderExecutionJpEquitiesV1Code -> DecodeOrderExecutionJpEquitiesV1(bytes)
              [] tag = OrderCancelledJpEquitiesV1Code -> DecodeOrderCancelledJpEquitiesV1(bytes)
              [] tag = CancelRejectedJpEquitiesV1Code -> DecodeCancelRejectedJpEquitiesV1(bytes)
              [] tag = PurgeAcknowledgementJpEquitiesV1Code -> DecodePurgeAcknowledgementJpEquitiesV1(bytes)
              [] tag = PurgeRejectedJpEquitiesV1Code -> DecodePurgeRejectedJpEquitiesV1(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroExchangeMessage == [tag |-> LoginResponseMessageCode, body |-> ZeroLoginResponseMessage]

(* Each Exchange Message in turn, at the values the message it names is checked at *)
CheckedExchangeMessage ==
    { [tag |-> LoginResponseMessageCode, body |-> one] : one \in CheckedLoginResponseMessage }
        \cup { [tag |-> ReplayCompleteCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> LogoutResponseMessageCode, body |-> one] : one \in CheckedLogoutResponseMessage }
        \cup { [tag |-> ServerHeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> OrderAcknowledgementJpEquitiesV1Code, body |-> one] : one \in CheckedOrderAcknowledgementJpEquitiesV1 }
        \cup { [tag |-> OrderRejectedJpEquitiesV1Code, body |-> one] : one \in CheckedOrderRejectedJpEquitiesV1 }
        \cup { [tag |-> OrderModifiedJpEquitiesV1Code, body |-> one] : one \in CheckedOrderModifiedJpEquitiesV1 }
        \cup { [tag |-> ModifyRejectedJpEquitiesV1Code, body |-> one] : one \in CheckedModifyRejectedJpEquitiesV1 }
        \cup { [tag |-> OrderRestatedJpEquitiesV1Code, body |-> one] : one \in CheckedOrderRestatedJpEquitiesV1 }
        \cup { [tag |-> OrderExecutionJpEquitiesV1Code, body |-> one] : one \in CheckedOrderExecutionJpEquitiesV1 }
        \cup { [tag |-> OrderCancelledJpEquitiesV1Code, body |-> one] : one \in CheckedOrderCancelledJpEquitiesV1 }
        \cup { [tag |-> CancelRejectedJpEquitiesV1Code, body |-> one] : one \in CheckedCancelRejectedJpEquitiesV1 }
        \cup { [tag |-> PurgeAcknowledgementJpEquitiesV1Code, body |-> one] : one \in CheckedPurgeAcknowledgementJpEquitiesV1 }
        \cup { [tag |-> PurgeRejectedJpEquitiesV1Code, body |-> one] : one \in CheckedPurgeRejectedJpEquitiesV1 }

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

(* Every Order Acknowledgement Jp Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderAcknowledgementJpEquitiesV1 ==
    \A message \in CheckedOrderAcknowledgementJpEquitiesV1 :
        LET read == DecodeOrderAcknowledgementJpEquitiesV1(EncodeOrderAcknowledgementJpEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Rejected Jp Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderRejectedJpEquitiesV1 ==
    \A message \in CheckedOrderRejectedJpEquitiesV1 :
        LET read == DecodeOrderRejectedJpEquitiesV1(EncodeOrderRejectedJpEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Modified Jp Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderModifiedJpEquitiesV1 ==
    \A message \in CheckedOrderModifiedJpEquitiesV1 :
        LET read == DecodeOrderModifiedJpEquitiesV1(EncodeOrderModifiedJpEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Rejected Jp Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyRejectedJpEquitiesV1 ==
    \A message \in CheckedModifyRejectedJpEquitiesV1 :
        LET read == DecodeModifyRejectedJpEquitiesV1(EncodeModifyRejectedJpEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Restated Jp Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderRestatedJpEquitiesV1 ==
    \A message \in CheckedOrderRestatedJpEquitiesV1 :
        LET read == DecodeOrderRestatedJpEquitiesV1(EncodeOrderRestatedJpEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Execution Jp Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutionJpEquitiesV1 ==
    \A message \in CheckedOrderExecutionJpEquitiesV1 :
        LET read == DecodeOrderExecutionJpEquitiesV1(EncodeOrderExecutionJpEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancelled Jp Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelledJpEquitiesV1 ==
    \A message \in CheckedOrderCancelledJpEquitiesV1 :
        LET read == DecodeOrderCancelledJpEquitiesV1(EncodeOrderCancelledJpEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Rejected Jp Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelRejectedJpEquitiesV1 ==
    \A message \in CheckedCancelRejectedJpEquitiesV1 :
        LET read == DecodeCancelRejectedJpEquitiesV1(EncodeCancelRejectedJpEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Purge Acknowledgement Jp Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripPurgeAcknowledgementJpEquitiesV1 ==
    \A message \in CheckedPurgeAcknowledgementJpEquitiesV1 :
        LET read == DecodePurgeAcknowledgementJpEquitiesV1(EncodePurgeAcknowledgementJpEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Purge Rejected Jp Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripPurgeRejectedJpEquitiesV1 ==
    \A message \in CheckedPurgeRejectedJpEquitiesV1 :
        LET read == DecodePurgeRejectedJpEquitiesV1(EncodePurgeRejectedJpEquitiesV1(message))
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
