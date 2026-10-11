-------------- MODULE NeoEquities_OrderEntry_v1_0_19_Exchange --------------
(***************************************************************************)
(* Chicago Board Options Exchange Order Entry v1.0.19                      *)
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
(* Order Acknowledgement Ca Equities V 1: 130 bytes                        *)
(***************************************************************************)

OrderAcknowledgementCaEquitiesV1 ==
    [ transactionTime        : Sample(8),
      account                : Sample(16),
      clOrdId                : Sample(20),
      brokerId               : Sample(2),
      orderId                : Sample(8),
      execInst               : Sample(1),
      orderQty               : Sample(4),
      ordType                : Sample(1),
      price                  : Sample(8),
      stopPx                 : Sample(8),
      workingPrice           : Sample(8),
      side                   : Sample(1),
      shortMarkingExempt     : Sample(1),
      symbol                 : Sample(14),
      timeInForce            : Sample(1),
      maxFloor               : Sample(4),
      expireTime             : Sample(8),
      exDestination          : Sample(1),
      noTradeFeat            : Sample(1),
      noTradeKey             : Sample(6),
      baseLiquidityIndicator : Sample(1),
      trueMinQty             : Sample(4),
      expireDate             : Sample(4) ]

EncodeOrderAcknowledgementCaEquitiesV1(message) ==
    message.transactionTime
        \o message.account
        \o message.clOrdId
        \o message.brokerId
        \o message.orderId
        \o message.execInst
        \o message.orderQty
        \o message.ordType
        \o message.price
        \o message.stopPx
        \o message.workingPrice
        \o message.side
        \o message.shortMarkingExempt
        \o message.symbol
        \o message.timeInForce
        \o message.maxFloor
        \o message.expireTime
        \o message.exDestination
        \o message.noTradeFeat
        \o message.noTradeKey
        \o message.baseLiquidityIndicator
        \o message.trueMinQty
        \o message.expireDate

DecodeOrderAcknowledgementCaEquitiesV1(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET account == ReadBytes(transactionTime.rest, 16) IN IF ~account.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(account.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET brokerId == ReadBytes(clOrdId.rest, 2) IN IF ~brokerId.ok THEN Fail ELSE
    LET orderId == ReadBytes(brokerId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET execInst == ReadBytes(orderId.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET orderQty == ReadBytes(execInst.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET ordType == ReadBytes(orderQty.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET price == ReadBytes(ordType.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET stopPx == ReadBytes(price.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET workingPrice == ReadBytes(stopPx.rest, 8) IN IF ~workingPrice.ok THEN Fail ELSE
    LET side == ReadBytes(workingPrice.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET shortMarkingExempt == ReadBytes(side.rest, 1) IN IF ~shortMarkingExempt.ok THEN Fail ELSE
    LET symbol == ReadBytes(shortMarkingExempt.rest, 14) IN IF ~symbol.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(symbol.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET maxFloor == ReadBytes(timeInForce.rest, 4) IN IF ~maxFloor.ok THEN Fail ELSE
    LET expireTime == ReadBytes(maxFloor.rest, 8) IN IF ~expireTime.ok THEN Fail ELSE
    LET exDestination == ReadBytes(expireTime.rest, 1) IN IF ~exDestination.ok THEN Fail ELSE
    LET noTradeFeat == ReadBytes(exDestination.rest, 1) IN IF ~noTradeFeat.ok THEN Fail ELSE
    LET noTradeKey == ReadBytes(noTradeFeat.rest, 6) IN IF ~noTradeKey.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadBytes(noTradeKey.rest, 1) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET trueMinQty == ReadBytes(baseLiquidityIndicator.rest, 4) IN IF ~trueMinQty.ok THEN Fail ELSE
    LET expireDate == ReadBytes(trueMinQty.rest, 4) IN IF ~expireDate.ok THEN Fail ELSE
    Ok([ transactionTime        |-> transactionTime.value,
         account                |-> account.value,
         clOrdId                |-> clOrdId.value,
         brokerId               |-> brokerId.value,
         orderId                |-> orderId.value,
         execInst               |-> execInst.value,
         orderQty               |-> orderQty.value,
         ordType                |-> ordType.value,
         price                  |-> price.value,
         stopPx                 |-> stopPx.value,
         workingPrice           |-> workingPrice.value,
         side                   |-> side.value,
         shortMarkingExempt     |-> shortMarkingExempt.value,
         symbol                 |-> symbol.value,
         timeInForce            |-> timeInForce.value,
         maxFloor               |-> maxFloor.value,
         expireTime             |-> expireTime.value,
         exDestination          |-> exDestination.value,
         noTradeFeat            |-> noTradeFeat.value,
         noTradeKey             |-> noTradeKey.value,
         baseLiquidityIndicator |-> baseLiquidityIndicator.value,
         trueMinQty             |-> trueMinQty.value,
         expireDate             |-> expireDate.value ], expireDate.rest)

ZeroOrderAcknowledgementCaEquitiesV1 ==
    [ transactionTime        |-> [i \in 1 .. 8 |-> 0],
      account                |-> [i \in 1 .. 16 |-> 0],
      clOrdId                |-> [i \in 1 .. 20 |-> 0],
      brokerId               |-> [i \in 1 .. 2 |-> 0],
      orderId                |-> [i \in 1 .. 8 |-> 0],
      execInst               |-> [i \in 1 .. 1 |-> 0],
      orderQty               |-> [i \in 1 .. 4 |-> 0],
      ordType                |-> [i \in 1 .. 1 |-> 0],
      price                  |-> [i \in 1 .. 8 |-> 0],
      stopPx                 |-> [i \in 1 .. 8 |-> 0],
      workingPrice           |-> [i \in 1 .. 8 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      shortMarkingExempt     |-> [i \in 1 .. 1 |-> 0],
      symbol                 |-> [i \in 1 .. 14 |-> 0],
      timeInForce            |-> [i \in 1 .. 1 |-> 0],
      maxFloor               |-> [i \in 1 .. 4 |-> 0],
      expireTime             |-> [i \in 1 .. 8 |-> 0],
      exDestination          |-> [i \in 1 .. 1 |-> 0],
      noTradeFeat            |-> [i \in 1 .. 1 |-> 0],
      noTradeKey             |-> [i \in 1 .. 6 |-> 0],
      baseLiquidityIndicator |-> [i \in 1 .. 1 |-> 0],
      trueMinQty             |-> [i \in 1 .. 4 |-> 0],
      expireDate             |-> [i \in 1 .. 4 |-> 0] ]

(* Order Acknowledgement Ca Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedOrderAcknowledgementCaEquitiesV1 ==
    { ZeroOrderAcknowledgementCaEquitiesV1 }
        \cup { [ZeroOrderAcknowledgementCaEquitiesV1 EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgementCaEquitiesV1 EXCEPT !.account = one] : one \in Sample(16) }
        \cup { [ZeroOrderAcknowledgementCaEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderAcknowledgementCaEquitiesV1 EXCEPT !.brokerId = one] : one \in Sample(2) }
        \cup { [ZeroOrderAcknowledgementCaEquitiesV1 EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgementCaEquitiesV1 EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementCaEquitiesV1 EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcknowledgementCaEquitiesV1 EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementCaEquitiesV1 EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgementCaEquitiesV1 EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgementCaEquitiesV1 EXCEPT !.workingPrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgementCaEquitiesV1 EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementCaEquitiesV1 EXCEPT !.shortMarkingExempt = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementCaEquitiesV1 EXCEPT !.symbol = one] : one \in Sample(14) }
        \cup { [ZeroOrderAcknowledgementCaEquitiesV1 EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementCaEquitiesV1 EXCEPT !.maxFloor = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcknowledgementCaEquitiesV1 EXCEPT !.expireTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgementCaEquitiesV1 EXCEPT !.exDestination = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementCaEquitiesV1 EXCEPT !.noTradeFeat = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementCaEquitiesV1 EXCEPT !.noTradeKey = one] : one \in Sample(6) }
        \cup { [ZeroOrderAcknowledgementCaEquitiesV1 EXCEPT !.baseLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementCaEquitiesV1 EXCEPT !.trueMinQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcknowledgementCaEquitiesV1 EXCEPT !.expireDate = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Rejected Ca Equities V 1: 91 bytes                                *)
(***************************************************************************)

OrderRejectedCaEquitiesV1 ==
    [ transactionTime   : Sample(8),
      clOrdId           : Sample(20),
      brokerId          : Sample(2),
      orderRejectReason : Sample(1),
      text              : Sample(60) ]

EncodeOrderRejectedCaEquitiesV1(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.brokerId
        \o message.orderRejectReason
        \o message.text

DecodeOrderRejectedCaEquitiesV1(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET brokerId == ReadBytes(clOrdId.rest, 2) IN IF ~brokerId.ok THEN Fail ELSE
    LET orderRejectReason == ReadBytes(brokerId.rest, 1) IN IF ~orderRejectReason.ok THEN Fail ELSE
    LET text == ReadBytes(orderRejectReason.rest, 60) IN IF ~text.ok THEN Fail ELSE
    Ok([ transactionTime   |-> transactionTime.value,
         clOrdId           |-> clOrdId.value,
         brokerId          |-> brokerId.value,
         orderRejectReason |-> orderRejectReason.value,
         text              |-> text.value ], text.rest)

ZeroOrderRejectedCaEquitiesV1 ==
    [ transactionTime   |-> [i \in 1 .. 8 |-> 0],
      clOrdId           |-> [i \in 1 .. 20 |-> 0],
      brokerId          |-> [i \in 1 .. 2 |-> 0],
      orderRejectReason |-> [i \in 1 .. 1 |-> 0],
      text              |-> [i \in 1 .. 60 |-> 0] ]

(* Order Rejected Ca Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedOrderRejectedCaEquitiesV1 ==
    { ZeroOrderRejectedCaEquitiesV1 }
        \cup { [ZeroOrderRejectedCaEquitiesV1 EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderRejectedCaEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderRejectedCaEquitiesV1 EXCEPT !.brokerId = one] : one \in Sample(2) }
        \cup { [ZeroOrderRejectedCaEquitiesV1 EXCEPT !.orderRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroOrderRejectedCaEquitiesV1 EXCEPT !.text = one] : one \in Sample(60) }

(***************************************************************************)
(* Order Modified Ca Equities V 1: 242 bytes                               *)
(***************************************************************************)

OrderModifiedCaEquitiesV1 ==
    [ transactionTime                : Sample(8),
      clOrdId                        : Sample(20),
      brokerId                       : Sample(2),
      orderId                        : Sample(8),
      account                        : Sample(16),
      timeInForce                    : Sample(1),
      maxFloor                       : Sample(4),
      expireDate                     : Sample(4),
      leiOrderOrigin                 : Sample(1),
      leiRoutingArrangementIndicator : Sample(1),
      umirAccountType                : Sample(1),
      leiCustomerAccount             : Sample(20),
      leiAlgorithmId                 : Sample(20),
      customerLei                    : Sample(52),
      brokerLei                      : Sample(20),
      orderQty                       : Sample(4),
      origClOrdId                    : Sample(20),
      leavesQty                      : Sample(4),
      price                          : Sample(8),
      stopPx                         : Sample(8),
      trueMinQty                     : Sample(4),
      secondaryOrderId               : Sample(8),
      expireTime                     : Sample(8) ]

EncodeOrderModifiedCaEquitiesV1(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.brokerId
        \o message.orderId
        \o message.account
        \o message.timeInForce
        \o message.maxFloor
        \o message.expireDate
        \o message.leiOrderOrigin
        \o message.leiRoutingArrangementIndicator
        \o message.umirAccountType
        \o message.leiCustomerAccount
        \o message.leiAlgorithmId
        \o message.customerLei
        \o message.brokerLei
        \o message.orderQty
        \o message.origClOrdId
        \o message.leavesQty
        \o message.price
        \o message.stopPx
        \o message.trueMinQty
        \o message.secondaryOrderId
        \o message.expireTime

DecodeOrderModifiedCaEquitiesV1(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET brokerId == ReadBytes(clOrdId.rest, 2) IN IF ~brokerId.ok THEN Fail ELSE
    LET orderId == ReadBytes(brokerId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET account == ReadBytes(orderId.rest, 16) IN IF ~account.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(account.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET maxFloor == ReadBytes(timeInForce.rest, 4) IN IF ~maxFloor.ok THEN Fail ELSE
    LET expireDate == ReadBytes(maxFloor.rest, 4) IN IF ~expireDate.ok THEN Fail ELSE
    LET leiOrderOrigin == ReadBytes(expireDate.rest, 1) IN IF ~leiOrderOrigin.ok THEN Fail ELSE
    LET leiRoutingArrangementIndicator == ReadBytes(leiOrderOrigin.rest, 1) IN IF ~leiRoutingArrangementIndicator.ok THEN Fail ELSE
    LET umirAccountType == ReadBytes(leiRoutingArrangementIndicator.rest, 1) IN IF ~umirAccountType.ok THEN Fail ELSE
    LET leiCustomerAccount == ReadBytes(umirAccountType.rest, 20) IN IF ~leiCustomerAccount.ok THEN Fail ELSE
    LET leiAlgorithmId == ReadBytes(leiCustomerAccount.rest, 20) IN IF ~leiAlgorithmId.ok THEN Fail ELSE
    LET customerLei == ReadBytes(leiAlgorithmId.rest, 52) IN IF ~customerLei.ok THEN Fail ELSE
    LET brokerLei == ReadBytes(customerLei.rest, 20) IN IF ~brokerLei.ok THEN Fail ELSE
    LET orderQty == ReadBytes(brokerLei.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(orderQty.rest, 20) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(origClOrdId.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET price == ReadBytes(leavesQty.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET stopPx == ReadBytes(price.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET trueMinQty == ReadBytes(stopPx.rest, 4) IN IF ~trueMinQty.ok THEN Fail ELSE
    LET secondaryOrderId == ReadBytes(trueMinQty.rest, 8) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET expireTime == ReadBytes(secondaryOrderId.rest, 8) IN IF ~expireTime.ok THEN Fail ELSE
    Ok([ transactionTime                |-> transactionTime.value,
         clOrdId                        |-> clOrdId.value,
         brokerId                       |-> brokerId.value,
         orderId                        |-> orderId.value,
         account                        |-> account.value,
         timeInForce                    |-> timeInForce.value,
         maxFloor                       |-> maxFloor.value,
         expireDate                     |-> expireDate.value,
         leiOrderOrigin                 |-> leiOrderOrigin.value,
         leiRoutingArrangementIndicator |-> leiRoutingArrangementIndicator.value,
         umirAccountType                |-> umirAccountType.value,
         leiCustomerAccount             |-> leiCustomerAccount.value,
         leiAlgorithmId                 |-> leiAlgorithmId.value,
         customerLei                    |-> customerLei.value,
         brokerLei                      |-> brokerLei.value,
         orderQty                       |-> orderQty.value,
         origClOrdId                    |-> origClOrdId.value,
         leavesQty                      |-> leavesQty.value,
         price                          |-> price.value,
         stopPx                         |-> stopPx.value,
         trueMinQty                     |-> trueMinQty.value,
         secondaryOrderId               |-> secondaryOrderId.value,
         expireTime                     |-> expireTime.value ], expireTime.rest)

ZeroOrderModifiedCaEquitiesV1 ==
    [ transactionTime                |-> [i \in 1 .. 8 |-> 0],
      clOrdId                        |-> [i \in 1 .. 20 |-> 0],
      brokerId                       |-> [i \in 1 .. 2 |-> 0],
      orderId                        |-> [i \in 1 .. 8 |-> 0],
      account                        |-> [i \in 1 .. 16 |-> 0],
      timeInForce                    |-> [i \in 1 .. 1 |-> 0],
      maxFloor                       |-> [i \in 1 .. 4 |-> 0],
      expireDate                     |-> [i \in 1 .. 4 |-> 0],
      leiOrderOrigin                 |-> [i \in 1 .. 1 |-> 0],
      leiRoutingArrangementIndicator |-> [i \in 1 .. 1 |-> 0],
      umirAccountType                |-> [i \in 1 .. 1 |-> 0],
      leiCustomerAccount             |-> [i \in 1 .. 20 |-> 0],
      leiAlgorithmId                 |-> [i \in 1 .. 20 |-> 0],
      customerLei                    |-> [i \in 1 .. 52 |-> 0],
      brokerLei                      |-> [i \in 1 .. 20 |-> 0],
      orderQty                       |-> [i \in 1 .. 4 |-> 0],
      origClOrdId                    |-> [i \in 1 .. 20 |-> 0],
      leavesQty                      |-> [i \in 1 .. 4 |-> 0],
      price                          |-> [i \in 1 .. 8 |-> 0],
      stopPx                         |-> [i \in 1 .. 8 |-> 0],
      trueMinQty                     |-> [i \in 1 .. 4 |-> 0],
      secondaryOrderId               |-> [i \in 1 .. 8 |-> 0],
      expireTime                     |-> [i \in 1 .. 8 |-> 0] ]

(* Order Modified Ca Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedOrderModifiedCaEquitiesV1 ==
    { ZeroOrderModifiedCaEquitiesV1 }
        \cup { [ZeroOrderModifiedCaEquitiesV1 EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifiedCaEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderModifiedCaEquitiesV1 EXCEPT !.brokerId = one] : one \in Sample(2) }
        \cup { [ZeroOrderModifiedCaEquitiesV1 EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifiedCaEquitiesV1 EXCEPT !.account = one] : one \in Sample(16) }
        \cup { [ZeroOrderModifiedCaEquitiesV1 EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifiedCaEquitiesV1 EXCEPT !.maxFloor = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifiedCaEquitiesV1 EXCEPT !.expireDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifiedCaEquitiesV1 EXCEPT !.leiOrderOrigin = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifiedCaEquitiesV1 EXCEPT !.leiRoutingArrangementIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifiedCaEquitiesV1 EXCEPT !.umirAccountType = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifiedCaEquitiesV1 EXCEPT !.leiCustomerAccount = one] : one \in Sample(20) }
        \cup { [ZeroOrderModifiedCaEquitiesV1 EXCEPT !.leiAlgorithmId = one] : one \in Sample(20) }
        \cup { [ZeroOrderModifiedCaEquitiesV1 EXCEPT !.customerLei = one] : one \in Sample(52) }
        \cup { [ZeroOrderModifiedCaEquitiesV1 EXCEPT !.brokerLei = one] : one \in Sample(20) }
        \cup { [ZeroOrderModifiedCaEquitiesV1 EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifiedCaEquitiesV1 EXCEPT !.origClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderModifiedCaEquitiesV1 EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifiedCaEquitiesV1 EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifiedCaEquitiesV1 EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifiedCaEquitiesV1 EXCEPT !.trueMinQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifiedCaEquitiesV1 EXCEPT !.secondaryOrderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifiedCaEquitiesV1 EXCEPT !.expireTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Modify Rejected Ca Equities V 1: 111 bytes                              *)
(***************************************************************************)

ModifyRejectedCaEquitiesV1 ==
    [ transactionTime    : Sample(8),
      clOrdId            : Sample(20),
      brokerId           : Sample(2),
      origClOrdId        : Sample(20),
      text               : Sample(60),
      modifyRejectReason : Sample(1) ]

EncodeModifyRejectedCaEquitiesV1(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.brokerId
        \o message.origClOrdId
        \o message.text
        \o message.modifyRejectReason

DecodeModifyRejectedCaEquitiesV1(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET brokerId == ReadBytes(clOrdId.rest, 2) IN IF ~brokerId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(brokerId.rest, 20) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET text == ReadBytes(origClOrdId.rest, 60) IN IF ~text.ok THEN Fail ELSE
    LET modifyRejectReason == ReadBytes(text.rest, 1) IN IF ~modifyRejectReason.ok THEN Fail ELSE
    Ok([ transactionTime    |-> transactionTime.value,
         clOrdId            |-> clOrdId.value,
         brokerId           |-> brokerId.value,
         origClOrdId        |-> origClOrdId.value,
         text               |-> text.value,
         modifyRejectReason |-> modifyRejectReason.value ], modifyRejectReason.rest)

ZeroModifyRejectedCaEquitiesV1 ==
    [ transactionTime    |-> [i \in 1 .. 8 |-> 0],
      clOrdId            |-> [i \in 1 .. 20 |-> 0],
      brokerId           |-> [i \in 1 .. 2 |-> 0],
      origClOrdId        |-> [i \in 1 .. 20 |-> 0],
      text               |-> [i \in 1 .. 60 |-> 0],
      modifyRejectReason |-> [i \in 1 .. 1 |-> 0] ]

(* Modify Rejected Ca Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedModifyRejectedCaEquitiesV1 ==
    { ZeroModifyRejectedCaEquitiesV1 }
        \cup { [ZeroModifyRejectedCaEquitiesV1 EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroModifyRejectedCaEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroModifyRejectedCaEquitiesV1 EXCEPT !.brokerId = one] : one \in Sample(2) }
        \cup { [ZeroModifyRejectedCaEquitiesV1 EXCEPT !.origClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroModifyRejectedCaEquitiesV1 EXCEPT !.text = one] : one \in Sample(60) }
        \cup { [ZeroModifyRejectedCaEquitiesV1 EXCEPT !.modifyRejectReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Restated Ca Equities V 1: 80 bytes                                *)
(***************************************************************************)

OrderRestatedCaEquitiesV1 ==
    [ transactionTime        : Sample(8),
      clOrdId                : Sample(20),
      brokerId               : Sample(2),
      orderId                : Sample(8),
      orderQty               : Sample(4),
      leavesQty              : Sample(4),
      secondaryOrderId       : Sample(8),
      lastPx                 : Sample(8),
      lastShares             : Sample(4),
      baseLiquidityIndicator : Sample(1),
      price                  : Sample(8),
      trueMinQty             : Sample(4),
      restatementReason      : Sample(1) ]

EncodeOrderRestatedCaEquitiesV1(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.brokerId
        \o message.orderId
        \o message.orderQty
        \o message.leavesQty
        \o message.secondaryOrderId
        \o message.lastPx
        \o message.lastShares
        \o message.baseLiquidityIndicator
        \o message.price
        \o message.trueMinQty
        \o message.restatementReason

DecodeOrderRestatedCaEquitiesV1(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET brokerId == ReadBytes(clOrdId.rest, 2) IN IF ~brokerId.ok THEN Fail ELSE
    LET orderId == ReadBytes(brokerId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(orderId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(orderQty.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET secondaryOrderId == ReadBytes(leavesQty.rest, 8) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET lastPx == ReadBytes(secondaryOrderId.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastShares == ReadBytes(lastPx.rest, 4) IN IF ~lastShares.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadBytes(lastShares.rest, 1) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET price == ReadBytes(baseLiquidityIndicator.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET trueMinQty == ReadBytes(price.rest, 4) IN IF ~trueMinQty.ok THEN Fail ELSE
    LET restatementReason == ReadBytes(trueMinQty.rest, 1) IN IF ~restatementReason.ok THEN Fail ELSE
    Ok([ transactionTime        |-> transactionTime.value,
         clOrdId                |-> clOrdId.value,
         brokerId               |-> brokerId.value,
         orderId                |-> orderId.value,
         orderQty               |-> orderQty.value,
         leavesQty              |-> leavesQty.value,
         secondaryOrderId       |-> secondaryOrderId.value,
         lastPx                 |-> lastPx.value,
         lastShares             |-> lastShares.value,
         baseLiquidityIndicator |-> baseLiquidityIndicator.value,
         price                  |-> price.value,
         trueMinQty             |-> trueMinQty.value,
         restatementReason      |-> restatementReason.value ], restatementReason.rest)

ZeroOrderRestatedCaEquitiesV1 ==
    [ transactionTime        |-> [i \in 1 .. 8 |-> 0],
      clOrdId                |-> [i \in 1 .. 20 |-> 0],
      brokerId               |-> [i \in 1 .. 2 |-> 0],
      orderId                |-> [i \in 1 .. 8 |-> 0],
      orderQty               |-> [i \in 1 .. 4 |-> 0],
      leavesQty              |-> [i \in 1 .. 4 |-> 0],
      secondaryOrderId       |-> [i \in 1 .. 8 |-> 0],
      lastPx                 |-> [i \in 1 .. 8 |-> 0],
      lastShares             |-> [i \in 1 .. 4 |-> 0],
      baseLiquidityIndicator |-> [i \in 1 .. 1 |-> 0],
      price                  |-> [i \in 1 .. 8 |-> 0],
      trueMinQty             |-> [i \in 1 .. 4 |-> 0],
      restatementReason      |-> [i \in 1 .. 1 |-> 0] ]

(* Order Restated Ca Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedOrderRestatedCaEquitiesV1 ==
    { ZeroOrderRestatedCaEquitiesV1 }
        \cup { [ZeroOrderRestatedCaEquitiesV1 EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderRestatedCaEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderRestatedCaEquitiesV1 EXCEPT !.brokerId = one] : one \in Sample(2) }
        \cup { [ZeroOrderRestatedCaEquitiesV1 EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderRestatedCaEquitiesV1 EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderRestatedCaEquitiesV1 EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderRestatedCaEquitiesV1 EXCEPT !.secondaryOrderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderRestatedCaEquitiesV1 EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroOrderRestatedCaEquitiesV1 EXCEPT !.lastShares = one] : one \in Sample(4) }
        \cup { [ZeroOrderRestatedCaEquitiesV1 EXCEPT !.baseLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderRestatedCaEquitiesV1 EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderRestatedCaEquitiesV1 EXCEPT !.trueMinQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderRestatedCaEquitiesV1 EXCEPT !.restatementReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Execution Ca Equities V 1: 99 bytes                               *)
(***************************************************************************)

OrderExecutionCaEquitiesV1 ==
    [ transactionTime        : Sample(8),
      clOrdId                : Sample(20),
      execId                 : Sample(8),
      lastPx                 : Sample(8),
      lastShares             : Sample(4),
      orderId                : Sample(8),
      side                   : Sample(1),
      symbol                 : Sample(14),
      tradeDate              : Sample(4),
      leavesQty              : Sample(4),
      contraBroker           : Sample(2),
      baseLiquidityIndicator : Sample(1),
      brokerId               : Sample(2),
      principalTrade         : Sample(1),
      washTrade              : Sample(1),
      noTradeFeat            : Sample(1),
      noTradeKey             : Sample(6),
      shortMarkingExempt     : Sample(1),
      matchingPriority       : Sample(1),
      isSelfTrade            : Sample(1),
      feeCode                : Sample(2),
      exDestination          : Sample(1) ]

EncodeOrderExecutionCaEquitiesV1(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.execId
        \o message.lastPx
        \o message.lastShares
        \o message.orderId
        \o message.side
        \o message.symbol
        \o message.tradeDate
        \o message.leavesQty
        \o message.contraBroker
        \o message.baseLiquidityIndicator
        \o message.brokerId
        \o message.principalTrade
        \o message.washTrade
        \o message.noTradeFeat
        \o message.noTradeKey
        \o message.shortMarkingExempt
        \o message.matchingPriority
        \o message.isSelfTrade
        \o message.feeCode
        \o message.exDestination

DecodeOrderExecutionCaEquitiesV1(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET execId == ReadBytes(clOrdId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET lastPx == ReadBytes(execId.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastShares == ReadBytes(lastPx.rest, 4) IN IF ~lastShares.ok THEN Fail ELSE
    LET orderId == ReadBytes(lastShares.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET side == ReadBytes(orderId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET symbol == ReadBytes(side.rest, 14) IN IF ~symbol.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(symbol.rest, 4) IN IF ~tradeDate.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(tradeDate.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET contraBroker == ReadBytes(leavesQty.rest, 2) IN IF ~contraBroker.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadBytes(contraBroker.rest, 1) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET brokerId == ReadBytes(baseLiquidityIndicator.rest, 2) IN IF ~brokerId.ok THEN Fail ELSE
    LET principalTrade == ReadBytes(brokerId.rest, 1) IN IF ~principalTrade.ok THEN Fail ELSE
    LET washTrade == ReadBytes(principalTrade.rest, 1) IN IF ~washTrade.ok THEN Fail ELSE
    LET noTradeFeat == ReadBytes(washTrade.rest, 1) IN IF ~noTradeFeat.ok THEN Fail ELSE
    LET noTradeKey == ReadBytes(noTradeFeat.rest, 6) IN IF ~noTradeKey.ok THEN Fail ELSE
    LET shortMarkingExempt == ReadBytes(noTradeKey.rest, 1) IN IF ~shortMarkingExempt.ok THEN Fail ELSE
    LET matchingPriority == ReadBytes(shortMarkingExempt.rest, 1) IN IF ~matchingPriority.ok THEN Fail ELSE
    LET isSelfTrade == ReadBytes(matchingPriority.rest, 1) IN IF ~isSelfTrade.ok THEN Fail ELSE
    LET feeCode == ReadBytes(isSelfTrade.rest, 2) IN IF ~feeCode.ok THEN Fail ELSE
    LET exDestination == ReadBytes(feeCode.rest, 1) IN IF ~exDestination.ok THEN Fail ELSE
    Ok([ transactionTime        |-> transactionTime.value,
         clOrdId                |-> clOrdId.value,
         execId                 |-> execId.value,
         lastPx                 |-> lastPx.value,
         lastShares             |-> lastShares.value,
         orderId                |-> orderId.value,
         side                   |-> side.value,
         symbol                 |-> symbol.value,
         tradeDate              |-> tradeDate.value,
         leavesQty              |-> leavesQty.value,
         contraBroker           |-> contraBroker.value,
         baseLiquidityIndicator |-> baseLiquidityIndicator.value,
         brokerId               |-> brokerId.value,
         principalTrade         |-> principalTrade.value,
         washTrade              |-> washTrade.value,
         noTradeFeat            |-> noTradeFeat.value,
         noTradeKey             |-> noTradeKey.value,
         shortMarkingExempt     |-> shortMarkingExempt.value,
         matchingPriority       |-> matchingPriority.value,
         isSelfTrade            |-> isSelfTrade.value,
         feeCode                |-> feeCode.value,
         exDestination          |-> exDestination.value ], exDestination.rest)

ZeroOrderExecutionCaEquitiesV1 ==
    [ transactionTime        |-> [i \in 1 .. 8 |-> 0],
      clOrdId                |-> [i \in 1 .. 20 |-> 0],
      execId                 |-> [i \in 1 .. 8 |-> 0],
      lastPx                 |-> [i \in 1 .. 8 |-> 0],
      lastShares             |-> [i \in 1 .. 4 |-> 0],
      orderId                |-> [i \in 1 .. 8 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      symbol                 |-> [i \in 1 .. 14 |-> 0],
      tradeDate              |-> [i \in 1 .. 4 |-> 0],
      leavesQty              |-> [i \in 1 .. 4 |-> 0],
      contraBroker           |-> [i \in 1 .. 2 |-> 0],
      baseLiquidityIndicator |-> [i \in 1 .. 1 |-> 0],
      brokerId               |-> [i \in 1 .. 2 |-> 0],
      principalTrade         |-> [i \in 1 .. 1 |-> 0],
      washTrade              |-> [i \in 1 .. 1 |-> 0],
      noTradeFeat            |-> [i \in 1 .. 1 |-> 0],
      noTradeKey             |-> [i \in 1 .. 6 |-> 0],
      shortMarkingExempt     |-> [i \in 1 .. 1 |-> 0],
      matchingPriority       |-> [i \in 1 .. 1 |-> 0],
      isSelfTrade            |-> [i \in 1 .. 1 |-> 0],
      feeCode                |-> [i \in 1 .. 2 |-> 0],
      exDestination          |-> [i \in 1 .. 1 |-> 0] ]

(* Order Execution Ca Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutionCaEquitiesV1 ==
    { ZeroOrderExecutionCaEquitiesV1 }
        \cup { [ZeroOrderExecutionCaEquitiesV1 EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionCaEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderExecutionCaEquitiesV1 EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionCaEquitiesV1 EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionCaEquitiesV1 EXCEPT !.lastShares = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionCaEquitiesV1 EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionCaEquitiesV1 EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionCaEquitiesV1 EXCEPT !.symbol = one] : one \in Sample(14) }
        \cup { [ZeroOrderExecutionCaEquitiesV1 EXCEPT !.tradeDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionCaEquitiesV1 EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionCaEquitiesV1 EXCEPT !.contraBroker = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecutionCaEquitiesV1 EXCEPT !.baseLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionCaEquitiesV1 EXCEPT !.brokerId = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecutionCaEquitiesV1 EXCEPT !.principalTrade = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionCaEquitiesV1 EXCEPT !.washTrade = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionCaEquitiesV1 EXCEPT !.noTradeFeat = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionCaEquitiesV1 EXCEPT !.noTradeKey = one] : one \in Sample(6) }
        \cup { [ZeroOrderExecutionCaEquitiesV1 EXCEPT !.shortMarkingExempt = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionCaEquitiesV1 EXCEPT !.matchingPriority = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionCaEquitiesV1 EXCEPT !.isSelfTrade = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionCaEquitiesV1 EXCEPT !.feeCode = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecutionCaEquitiesV1 EXCEPT !.exDestination = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Cancelled Ca Equities V 1: 31 bytes                               *)
(***************************************************************************)

OrderCancelledCaEquitiesV1 ==
    [ transactionTime : Sample(8),
      clOrdId         : Sample(20),
      brokerId        : Sample(2),
      cancelReason    : Sample(1) ]

EncodeOrderCancelledCaEquitiesV1(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.brokerId
        \o message.cancelReason

DecodeOrderCancelledCaEquitiesV1(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET brokerId == ReadBytes(clOrdId.rest, 2) IN IF ~brokerId.ok THEN Fail ELSE
    LET cancelReason == ReadBytes(brokerId.rest, 1) IN IF ~cancelReason.ok THEN Fail ELSE
    Ok([ transactionTime |-> transactionTime.value,
         clOrdId         |-> clOrdId.value,
         brokerId        |-> brokerId.value,
         cancelReason    |-> cancelReason.value ], cancelReason.rest)

ZeroOrderCancelledCaEquitiesV1 ==
    [ transactionTime |-> [i \in 1 .. 8 |-> 0],
      clOrdId         |-> [i \in 1 .. 20 |-> 0],
      brokerId        |-> [i \in 1 .. 2 |-> 0],
      cancelReason    |-> [i \in 1 .. 1 |-> 0] ]

(* Order Cancelled Ca Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelledCaEquitiesV1 ==
    { ZeroOrderCancelledCaEquitiesV1 }
        \cup { [ZeroOrderCancelledCaEquitiesV1 EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelledCaEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderCancelledCaEquitiesV1 EXCEPT !.brokerId = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelledCaEquitiesV1 EXCEPT !.cancelReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Cancel Rejected Ca Equities V 1: 91 bytes                               *)
(***************************************************************************)

CancelRejectedCaEquitiesV1 ==
    [ transactionTime    : Sample(8),
      clOrdId            : Sample(20),
      brokerId           : Sample(2),
      text               : Sample(60),
      cancelRejectReason : Sample(1) ]

EncodeCancelRejectedCaEquitiesV1(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.brokerId
        \o message.text
        \o message.cancelRejectReason

DecodeCancelRejectedCaEquitiesV1(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET brokerId == ReadBytes(clOrdId.rest, 2) IN IF ~brokerId.ok THEN Fail ELSE
    LET text == ReadBytes(brokerId.rest, 60) IN IF ~text.ok THEN Fail ELSE
    LET cancelRejectReason == ReadBytes(text.rest, 1) IN IF ~cancelRejectReason.ok THEN Fail ELSE
    Ok([ transactionTime    |-> transactionTime.value,
         clOrdId            |-> clOrdId.value,
         brokerId           |-> brokerId.value,
         text               |-> text.value,
         cancelRejectReason |-> cancelRejectReason.value ], cancelRejectReason.rest)

ZeroCancelRejectedCaEquitiesV1 ==
    [ transactionTime    |-> [i \in 1 .. 8 |-> 0],
      clOrdId            |-> [i \in 1 .. 20 |-> 0],
      brokerId           |-> [i \in 1 .. 2 |-> 0],
      text               |-> [i \in 1 .. 60 |-> 0],
      cancelRejectReason |-> [i \in 1 .. 1 |-> 0] ]

(* Cancel Rejected Ca Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedCancelRejectedCaEquitiesV1 ==
    { ZeroCancelRejectedCaEquitiesV1 }
        \cup { [ZeroCancelRejectedCaEquitiesV1 EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroCancelRejectedCaEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroCancelRejectedCaEquitiesV1 EXCEPT !.brokerId = one] : one \in Sample(2) }
        \cup { [ZeroCancelRejectedCaEquitiesV1 EXCEPT !.text = one] : one \in Sample(60) }
        \cup { [ZeroCancelRejectedCaEquitiesV1 EXCEPT !.cancelRejectReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Carried Restatement Ca Equities V 1: 262 bytes                          *)
(***************************************************************************)

CarriedRestatementCaEquitiesV1 ==
    [ transactionTime                : Sample(8),
      orderId                        : Sample(8),
      account                        : Sample(16),
      clOrdId                        : Sample(20),
      brokerId                       : Sample(2),
      execInst                       : Sample(1),
      handlingInst                   : Sample(1),
      orderQty                       : Sample(4),
      cumQty                         : Sample(4),
      leavesQty                      : Sample(4),
      ordType                        : Sample(1),
      price                          : Sample(8),
      stopPx                         : Sample(8),
      side                           : Sample(1),
      symbol                         : Sample(14),
      timeInForce                    : Sample(1),
      settlementType                 : Sample(1),
      futSettlDate                   : Sample(4),
      exDestination                  : Sample(1),
      maxFloor                       : Sample(4),
      expireDate                     : Sample(4),
      leiOrderOrigin                 : Sample(1),
      leiRoutingArrangementIndicator : Sample(1),
      umirAccountType                : Sample(1),
      umirUserId                     : Sample(12),
      basketTrade                    : Sample(4),
      programTrade                   : Sample(1),
      jitney                         : Sample(2),
      anonymous                      : Sample(1),
      umirRegulationId               : Sample(1),
      nonResident                    : Sample(1),
      bypass                         : Sample(1),
      ncib                           : Sample(1),
      shortMarkingExempt             : Sample(1),
      leiCustomerAccount             : Sample(20),
      leiAlgorithmId                 : Sample(20),
      customerLei                    : Sample(52),
      brokerLei                      : Sample(20),
      routingInst                    : Sample(1),
      displayIndicator               : Sample(1),
      matchingStateParticipation     : Sample(1),
      trueMinQty                     : Sample(4) ]

EncodeCarriedRestatementCaEquitiesV1(message) ==
    message.transactionTime
        \o message.orderId
        \o message.account
        \o message.clOrdId
        \o message.brokerId
        \o message.execInst
        \o message.handlingInst
        \o message.orderQty
        \o message.cumQty
        \o message.leavesQty
        \o message.ordType
        \o message.price
        \o message.stopPx
        \o message.side
        \o message.symbol
        \o message.timeInForce
        \o message.settlementType
        \o message.futSettlDate
        \o message.exDestination
        \o message.maxFloor
        \o message.expireDate
        \o message.leiOrderOrigin
        \o message.leiRoutingArrangementIndicator
        \o message.umirAccountType
        \o message.umirUserId
        \o message.basketTrade
        \o message.programTrade
        \o message.jitney
        \o message.anonymous
        \o message.umirRegulationId
        \o message.nonResident
        \o message.bypass
        \o message.ncib
        \o message.shortMarkingExempt
        \o message.leiCustomerAccount
        \o message.leiAlgorithmId
        \o message.customerLei
        \o message.brokerLei
        \o message.routingInst
        \o message.displayIndicator
        \o message.matchingStateParticipation
        \o message.trueMinQty

DecodeCarriedRestatementCaEquitiesV1(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET orderId == ReadBytes(transactionTime.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET account == ReadBytes(orderId.rest, 16) IN IF ~account.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(account.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET brokerId == ReadBytes(clOrdId.rest, 2) IN IF ~brokerId.ok THEN Fail ELSE
    LET execInst == ReadBytes(brokerId.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET handlingInst == ReadBytes(execInst.rest, 1) IN IF ~handlingInst.ok THEN Fail ELSE
    LET orderQty == ReadBytes(handlingInst.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(orderQty.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(cumQty.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET ordType == ReadBytes(leavesQty.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET price == ReadBytes(ordType.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET stopPx == ReadBytes(price.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET side == ReadBytes(stopPx.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET symbol == ReadBytes(side.rest, 14) IN IF ~symbol.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(symbol.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET settlementType == ReadBytes(timeInForce.rest, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET futSettlDate == ReadBytes(settlementType.rest, 4) IN IF ~futSettlDate.ok THEN Fail ELSE
    LET exDestination == ReadBytes(futSettlDate.rest, 1) IN IF ~exDestination.ok THEN Fail ELSE
    LET maxFloor == ReadBytes(exDestination.rest, 4) IN IF ~maxFloor.ok THEN Fail ELSE
    LET expireDate == ReadBytes(maxFloor.rest, 4) IN IF ~expireDate.ok THEN Fail ELSE
    LET leiOrderOrigin == ReadBytes(expireDate.rest, 1) IN IF ~leiOrderOrigin.ok THEN Fail ELSE
    LET leiRoutingArrangementIndicator == ReadBytes(leiOrderOrigin.rest, 1) IN IF ~leiRoutingArrangementIndicator.ok THEN Fail ELSE
    LET umirAccountType == ReadBytes(leiRoutingArrangementIndicator.rest, 1) IN IF ~umirAccountType.ok THEN Fail ELSE
    LET umirUserId == ReadBytes(umirAccountType.rest, 12) IN IF ~umirUserId.ok THEN Fail ELSE
    LET basketTrade == ReadBytes(umirUserId.rest, 4) IN IF ~basketTrade.ok THEN Fail ELSE
    LET programTrade == ReadBytes(basketTrade.rest, 1) IN IF ~programTrade.ok THEN Fail ELSE
    LET jitney == ReadBytes(programTrade.rest, 2) IN IF ~jitney.ok THEN Fail ELSE
    LET anonymous == ReadBytes(jitney.rest, 1) IN IF ~anonymous.ok THEN Fail ELSE
    LET umirRegulationId == ReadBytes(anonymous.rest, 1) IN IF ~umirRegulationId.ok THEN Fail ELSE
    LET nonResident == ReadBytes(umirRegulationId.rest, 1) IN IF ~nonResident.ok THEN Fail ELSE
    LET bypass == ReadBytes(nonResident.rest, 1) IN IF ~bypass.ok THEN Fail ELSE
    LET ncib == ReadBytes(bypass.rest, 1) IN IF ~ncib.ok THEN Fail ELSE
    LET shortMarkingExempt == ReadBytes(ncib.rest, 1) IN IF ~shortMarkingExempt.ok THEN Fail ELSE
    LET leiCustomerAccount == ReadBytes(shortMarkingExempt.rest, 20) IN IF ~leiCustomerAccount.ok THEN Fail ELSE
    LET leiAlgorithmId == ReadBytes(leiCustomerAccount.rest, 20) IN IF ~leiAlgorithmId.ok THEN Fail ELSE
    LET customerLei == ReadBytes(leiAlgorithmId.rest, 52) IN IF ~customerLei.ok THEN Fail ELSE
    LET brokerLei == ReadBytes(customerLei.rest, 20) IN IF ~brokerLei.ok THEN Fail ELSE
    LET routingInst == ReadBytes(brokerLei.rest, 1) IN IF ~routingInst.ok THEN Fail ELSE
    LET displayIndicator == ReadBytes(routingInst.rest, 1) IN IF ~displayIndicator.ok THEN Fail ELSE
    LET matchingStateParticipation == ReadBytes(displayIndicator.rest, 1) IN IF ~matchingStateParticipation.ok THEN Fail ELSE
    LET trueMinQty == ReadBytes(matchingStateParticipation.rest, 4) IN IF ~trueMinQty.ok THEN Fail ELSE
    Ok([ transactionTime                |-> transactionTime.value,
         orderId                        |-> orderId.value,
         account                        |-> account.value,
         clOrdId                        |-> clOrdId.value,
         brokerId                       |-> brokerId.value,
         execInst                       |-> execInst.value,
         handlingInst                   |-> handlingInst.value,
         orderQty                       |-> orderQty.value,
         cumQty                         |-> cumQty.value,
         leavesQty                      |-> leavesQty.value,
         ordType                        |-> ordType.value,
         price                          |-> price.value,
         stopPx                         |-> stopPx.value,
         side                           |-> side.value,
         symbol                         |-> symbol.value,
         timeInForce                    |-> timeInForce.value,
         settlementType                 |-> settlementType.value,
         futSettlDate                   |-> futSettlDate.value,
         exDestination                  |-> exDestination.value,
         maxFloor                       |-> maxFloor.value,
         expireDate                     |-> expireDate.value,
         leiOrderOrigin                 |-> leiOrderOrigin.value,
         leiRoutingArrangementIndicator |-> leiRoutingArrangementIndicator.value,
         umirAccountType                |-> umirAccountType.value,
         umirUserId                     |-> umirUserId.value,
         basketTrade                    |-> basketTrade.value,
         programTrade                   |-> programTrade.value,
         jitney                         |-> jitney.value,
         anonymous                      |-> anonymous.value,
         umirRegulationId               |-> umirRegulationId.value,
         nonResident                    |-> nonResident.value,
         bypass                         |-> bypass.value,
         ncib                           |-> ncib.value,
         shortMarkingExempt             |-> shortMarkingExempt.value,
         leiCustomerAccount             |-> leiCustomerAccount.value,
         leiAlgorithmId                 |-> leiAlgorithmId.value,
         customerLei                    |-> customerLei.value,
         brokerLei                      |-> brokerLei.value,
         routingInst                    |-> routingInst.value,
         displayIndicator               |-> displayIndicator.value,
         matchingStateParticipation     |-> matchingStateParticipation.value,
         trueMinQty                     |-> trueMinQty.value ], trueMinQty.rest)

ZeroCarriedRestatementCaEquitiesV1 ==
    [ transactionTime                |-> [i \in 1 .. 8 |-> 0],
      orderId                        |-> [i \in 1 .. 8 |-> 0],
      account                        |-> [i \in 1 .. 16 |-> 0],
      clOrdId                        |-> [i \in 1 .. 20 |-> 0],
      brokerId                       |-> [i \in 1 .. 2 |-> 0],
      execInst                       |-> [i \in 1 .. 1 |-> 0],
      handlingInst                   |-> [i \in 1 .. 1 |-> 0],
      orderQty                       |-> [i \in 1 .. 4 |-> 0],
      cumQty                         |-> [i \in 1 .. 4 |-> 0],
      leavesQty                      |-> [i \in 1 .. 4 |-> 0],
      ordType                        |-> [i \in 1 .. 1 |-> 0],
      price                          |-> [i \in 1 .. 8 |-> 0],
      stopPx                         |-> [i \in 1 .. 8 |-> 0],
      side                           |-> [i \in 1 .. 1 |-> 0],
      symbol                         |-> [i \in 1 .. 14 |-> 0],
      timeInForce                    |-> [i \in 1 .. 1 |-> 0],
      settlementType                 |-> [i \in 1 .. 1 |-> 0],
      futSettlDate                   |-> [i \in 1 .. 4 |-> 0],
      exDestination                  |-> [i \in 1 .. 1 |-> 0],
      maxFloor                       |-> [i \in 1 .. 4 |-> 0],
      expireDate                     |-> [i \in 1 .. 4 |-> 0],
      leiOrderOrigin                 |-> [i \in 1 .. 1 |-> 0],
      leiRoutingArrangementIndicator |-> [i \in 1 .. 1 |-> 0],
      umirAccountType                |-> [i \in 1 .. 1 |-> 0],
      umirUserId                     |-> [i \in 1 .. 12 |-> 0],
      basketTrade                    |-> [i \in 1 .. 4 |-> 0],
      programTrade                   |-> [i \in 1 .. 1 |-> 0],
      jitney                         |-> [i \in 1 .. 2 |-> 0],
      anonymous                      |-> [i \in 1 .. 1 |-> 0],
      umirRegulationId               |-> [i \in 1 .. 1 |-> 0],
      nonResident                    |-> [i \in 1 .. 1 |-> 0],
      bypass                         |-> [i \in 1 .. 1 |-> 0],
      ncib                           |-> [i \in 1 .. 1 |-> 0],
      shortMarkingExempt             |-> [i \in 1 .. 1 |-> 0],
      leiCustomerAccount             |-> [i \in 1 .. 20 |-> 0],
      leiAlgorithmId                 |-> [i \in 1 .. 20 |-> 0],
      customerLei                    |-> [i \in 1 .. 52 |-> 0],
      brokerLei                      |-> [i \in 1 .. 20 |-> 0],
      routingInst                    |-> [i \in 1 .. 1 |-> 0],
      displayIndicator               |-> [i \in 1 .. 1 |-> 0],
      matchingStateParticipation     |-> [i \in 1 .. 1 |-> 0],
      trueMinQty                     |-> [i \in 1 .. 4 |-> 0] ]

(* Carried Restatement Ca Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedCarriedRestatementCaEquitiesV1 ==
    { ZeroCarriedRestatementCaEquitiesV1 }
        \cup { [ZeroCarriedRestatementCaEquitiesV1 EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroCarriedRestatementCaEquitiesV1 EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroCarriedRestatementCaEquitiesV1 EXCEPT !.account = one] : one \in Sample(16) }
        \cup { [ZeroCarriedRestatementCaEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroCarriedRestatementCaEquitiesV1 EXCEPT !.brokerId = one] : one \in Sample(2) }
        \cup { [ZeroCarriedRestatementCaEquitiesV1 EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementCaEquitiesV1 EXCEPT !.handlingInst = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementCaEquitiesV1 EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroCarriedRestatementCaEquitiesV1 EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroCarriedRestatementCaEquitiesV1 EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroCarriedRestatementCaEquitiesV1 EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementCaEquitiesV1 EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroCarriedRestatementCaEquitiesV1 EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroCarriedRestatementCaEquitiesV1 EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementCaEquitiesV1 EXCEPT !.symbol = one] : one \in Sample(14) }
        \cup { [ZeroCarriedRestatementCaEquitiesV1 EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementCaEquitiesV1 EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementCaEquitiesV1 EXCEPT !.futSettlDate = one] : one \in Sample(4) }
        \cup { [ZeroCarriedRestatementCaEquitiesV1 EXCEPT !.exDestination = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementCaEquitiesV1 EXCEPT !.maxFloor = one] : one \in Sample(4) }
        \cup { [ZeroCarriedRestatementCaEquitiesV1 EXCEPT !.expireDate = one] : one \in Sample(4) }
        \cup { [ZeroCarriedRestatementCaEquitiesV1 EXCEPT !.leiOrderOrigin = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementCaEquitiesV1 EXCEPT !.leiRoutingArrangementIndicator = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementCaEquitiesV1 EXCEPT !.umirAccountType = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementCaEquitiesV1 EXCEPT !.umirUserId = one] : one \in Sample(12) }
        \cup { [ZeroCarriedRestatementCaEquitiesV1 EXCEPT !.basketTrade = one] : one \in Sample(4) }
        \cup { [ZeroCarriedRestatementCaEquitiesV1 EXCEPT !.programTrade = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementCaEquitiesV1 EXCEPT !.jitney = one] : one \in Sample(2) }
        \cup { [ZeroCarriedRestatementCaEquitiesV1 EXCEPT !.anonymous = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementCaEquitiesV1 EXCEPT !.umirRegulationId = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementCaEquitiesV1 EXCEPT !.nonResident = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementCaEquitiesV1 EXCEPT !.bypass = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementCaEquitiesV1 EXCEPT !.ncib = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementCaEquitiesV1 EXCEPT !.shortMarkingExempt = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementCaEquitiesV1 EXCEPT !.leiCustomerAccount = one] : one \in Sample(20) }
        \cup { [ZeroCarriedRestatementCaEquitiesV1 EXCEPT !.leiAlgorithmId = one] : one \in Sample(20) }
        \cup { [ZeroCarriedRestatementCaEquitiesV1 EXCEPT !.customerLei = one] : one \in Sample(52) }
        \cup { [ZeroCarriedRestatementCaEquitiesV1 EXCEPT !.brokerLei = one] : one \in Sample(20) }
        \cup { [ZeroCarriedRestatementCaEquitiesV1 EXCEPT !.routingInst = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementCaEquitiesV1 EXCEPT !.displayIndicator = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementCaEquitiesV1 EXCEPT !.matchingStateParticipation = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementCaEquitiesV1 EXCEPT !.trueMinQty = one] : one \in Sample(4) }

(***************************************************************************)
(* Done For Day Ca Equities V 1: 44 bytes                                  *)
(***************************************************************************)

DoneForDayCaEquitiesV1 ==
    [ transactionTime : Sample(8),
      clOrdId         : Sample(20),
      brokerId        : Sample(2),
      symbol          : Sample(14) ]

EncodeDoneForDayCaEquitiesV1(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.brokerId
        \o message.symbol

DecodeDoneForDayCaEquitiesV1(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET brokerId == ReadBytes(clOrdId.rest, 2) IN IF ~brokerId.ok THEN Fail ELSE
    LET symbol == ReadBytes(brokerId.rest, 14) IN IF ~symbol.ok THEN Fail ELSE
    Ok([ transactionTime |-> transactionTime.value,
         clOrdId         |-> clOrdId.value,
         brokerId        |-> brokerId.value,
         symbol          |-> symbol.value ], symbol.rest)

ZeroDoneForDayCaEquitiesV1 ==
    [ transactionTime |-> [i \in 1 .. 8 |-> 0],
      clOrdId         |-> [i \in 1 .. 20 |-> 0],
      brokerId        |-> [i \in 1 .. 2 |-> 0],
      symbol          |-> [i \in 1 .. 14 |-> 0] ]

(* Done For Day Ca Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedDoneForDayCaEquitiesV1 ==
    { ZeroDoneForDayCaEquitiesV1 }
        \cup { [ZeroDoneForDayCaEquitiesV1 EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroDoneForDayCaEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroDoneForDayCaEquitiesV1 EXCEPT !.brokerId = one] : one \in Sample(2) }
        \cup { [ZeroDoneForDayCaEquitiesV1 EXCEPT !.symbol = one] : one \in Sample(14) }

(***************************************************************************)
(* Trade Cancel Correct Ca Equities V 1: 119 bytes                         *)
(***************************************************************************)

TradeCancelCorrectCaEquitiesV1 ==
    [ transactionTime        : Sample(8),
      account                : Sample(16),
      clOrdId                : Sample(20),
      execId                 : Sample(8),
      execRefId              : Sample(8),
      lastPx                 : Sample(8),
      lastShares             : Sample(4),
      side                   : Sample(1),
      symbol                 : Sample(14),
      baseLiquidityIndicator : Sample(1),
      correctedSize          : Sample(4),
      umirUserId             : Sample(12),
      correctedPrice         : Sample(8),
      feeCode                : Sample(2),
      settlementType         : Sample(1),
      futSettlDate           : Sample(4) ]

EncodeTradeCancelCorrectCaEquitiesV1(message) ==
    message.transactionTime
        \o message.account
        \o message.clOrdId
        \o message.execId
        \o message.execRefId
        \o message.lastPx
        \o message.lastShares
        \o message.side
        \o message.symbol
        \o message.baseLiquidityIndicator
        \o message.correctedSize
        \o message.umirUserId
        \o message.correctedPrice
        \o message.feeCode
        \o message.settlementType
        \o message.futSettlDate

DecodeTradeCancelCorrectCaEquitiesV1(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET account == ReadBytes(transactionTime.rest, 16) IN IF ~account.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(account.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET execId == ReadBytes(clOrdId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET execRefId == ReadBytes(execId.rest, 8) IN IF ~execRefId.ok THEN Fail ELSE
    LET lastPx == ReadBytes(execRefId.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastShares == ReadBytes(lastPx.rest, 4) IN IF ~lastShares.ok THEN Fail ELSE
    LET side == ReadBytes(lastShares.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET symbol == ReadBytes(side.rest, 14) IN IF ~symbol.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadBytes(symbol.rest, 1) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET correctedSize == ReadBytes(baseLiquidityIndicator.rest, 4) IN IF ~correctedSize.ok THEN Fail ELSE
    LET umirUserId == ReadBytes(correctedSize.rest, 12) IN IF ~umirUserId.ok THEN Fail ELSE
    LET correctedPrice == ReadBytes(umirUserId.rest, 8) IN IF ~correctedPrice.ok THEN Fail ELSE
    LET feeCode == ReadBytes(correctedPrice.rest, 2) IN IF ~feeCode.ok THEN Fail ELSE
    LET settlementType == ReadBytes(feeCode.rest, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET futSettlDate == ReadBytes(settlementType.rest, 4) IN IF ~futSettlDate.ok THEN Fail ELSE
    Ok([ transactionTime        |-> transactionTime.value,
         account                |-> account.value,
         clOrdId                |-> clOrdId.value,
         execId                 |-> execId.value,
         execRefId              |-> execRefId.value,
         lastPx                 |-> lastPx.value,
         lastShares             |-> lastShares.value,
         side                   |-> side.value,
         symbol                 |-> symbol.value,
         baseLiquidityIndicator |-> baseLiquidityIndicator.value,
         correctedSize          |-> correctedSize.value,
         umirUserId             |-> umirUserId.value,
         correctedPrice         |-> correctedPrice.value,
         feeCode                |-> feeCode.value,
         settlementType         |-> settlementType.value,
         futSettlDate           |-> futSettlDate.value ], futSettlDate.rest)

ZeroTradeCancelCorrectCaEquitiesV1 ==
    [ transactionTime        |-> [i \in 1 .. 8 |-> 0],
      account                |-> [i \in 1 .. 16 |-> 0],
      clOrdId                |-> [i \in 1 .. 20 |-> 0],
      execId                 |-> [i \in 1 .. 8 |-> 0],
      execRefId              |-> [i \in 1 .. 8 |-> 0],
      lastPx                 |-> [i \in 1 .. 8 |-> 0],
      lastShares             |-> [i \in 1 .. 4 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      symbol                 |-> [i \in 1 .. 14 |-> 0],
      baseLiquidityIndicator |-> [i \in 1 .. 1 |-> 0],
      correctedSize          |-> [i \in 1 .. 4 |-> 0],
      umirUserId             |-> [i \in 1 .. 12 |-> 0],
      correctedPrice         |-> [i \in 1 .. 8 |-> 0],
      feeCode                |-> [i \in 1 .. 2 |-> 0],
      settlementType         |-> [i \in 1 .. 1 |-> 0],
      futSettlDate           |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Cancel Correct Ca Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedTradeCancelCorrectCaEquitiesV1 ==
    { ZeroTradeCancelCorrectCaEquitiesV1 }
        \cup { [ZeroTradeCancelCorrectCaEquitiesV1 EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelCorrectCaEquitiesV1 EXCEPT !.account = one] : one \in Sample(16) }
        \cup { [ZeroTradeCancelCorrectCaEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroTradeCancelCorrectCaEquitiesV1 EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelCorrectCaEquitiesV1 EXCEPT !.execRefId = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelCorrectCaEquitiesV1 EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelCorrectCaEquitiesV1 EXCEPT !.lastShares = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelCorrectCaEquitiesV1 EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelCorrectCaEquitiesV1 EXCEPT !.symbol = one] : one \in Sample(14) }
        \cup { [ZeroTradeCancelCorrectCaEquitiesV1 EXCEPT !.baseLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelCorrectCaEquitiesV1 EXCEPT !.correctedSize = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelCorrectCaEquitiesV1 EXCEPT !.umirUserId = one] : one \in Sample(12) }
        \cup { [ZeroTradeCancelCorrectCaEquitiesV1 EXCEPT !.correctedPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelCorrectCaEquitiesV1 EXCEPT !.feeCode = one] : one \in Sample(2) }
        \cup { [ZeroTradeCancelCorrectCaEquitiesV1 EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelCorrectCaEquitiesV1 EXCEPT !.futSettlDate = one] : one \in Sample(4) }

(***************************************************************************)
(* Exchange Message, selected by Exchange Message Type                     *)
(***************************************************************************)

LoginResponseMessageCode == 501  \* 0x1f5
ReplayCompleteCode == 502  \* 0x1f6
LogoutResponseMessageCode == 503  \* 0x1f7
ServerHeartbeatCode == 504  \* 0x1f8
OrderAcknowledgementCaEquitiesV1Code == 6501  \* 0x1965
OrderRejectedCaEquitiesV1Code == 6502  \* 0x1966
OrderModifiedCaEquitiesV1Code == 6503  \* 0x1967
ModifyRejectedCaEquitiesV1Code == 6504  \* 0x1968
OrderRestatedCaEquitiesV1Code == 6505  \* 0x1969
OrderExecutionCaEquitiesV1Code == 6506  \* 0x196a
OrderCancelledCaEquitiesV1Code == 6507  \* 0x196b
CancelRejectedCaEquitiesV1Code == 6508  \* 0x196c
CarriedRestatementCaEquitiesV1Code == 6510  \* 0x196e
DoneForDayCaEquitiesV1Code == 6511  \* 0x196f
TradeCancelCorrectCaEquitiesV1Code == 6512  \* 0x1970

ExchangeMessage ==
    [ tag : {LoginResponseMessageCode}, body : LoginResponseMessage ]
        \cup [ tag : {ReplayCompleteCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {LogoutResponseMessageCode}, body : LogoutResponseMessage ]
        \cup [ tag : {ServerHeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {OrderAcknowledgementCaEquitiesV1Code}, body : OrderAcknowledgementCaEquitiesV1 ]
        \cup [ tag : {OrderRejectedCaEquitiesV1Code}, body : OrderRejectedCaEquitiesV1 ]
        \cup [ tag : {OrderModifiedCaEquitiesV1Code}, body : OrderModifiedCaEquitiesV1 ]
        \cup [ tag : {ModifyRejectedCaEquitiesV1Code}, body : ModifyRejectedCaEquitiesV1 ]
        \cup [ tag : {OrderRestatedCaEquitiesV1Code}, body : OrderRestatedCaEquitiesV1 ]
        \cup [ tag : {OrderExecutionCaEquitiesV1Code}, body : OrderExecutionCaEquitiesV1 ]
        \cup [ tag : {OrderCancelledCaEquitiesV1Code}, body : OrderCancelledCaEquitiesV1 ]
        \cup [ tag : {CancelRejectedCaEquitiesV1Code}, body : CancelRejectedCaEquitiesV1 ]
        \cup [ tag : {CarriedRestatementCaEquitiesV1Code}, body : CarriedRestatementCaEquitiesV1 ]
        \cup [ tag : {DoneForDayCaEquitiesV1Code}, body : DoneForDayCaEquitiesV1 ]
        \cup [ tag : {TradeCancelCorrectCaEquitiesV1Code}, body : TradeCancelCorrectCaEquitiesV1 ]

EncodeExchangeMessage(message) ==
    CASE message.tag = LoginResponseMessageCode -> EncodeLoginResponseMessage(message.body)
      [] message.tag = ReplayCompleteCode -> << >>
      [] message.tag = LogoutResponseMessageCode -> EncodeLogoutResponseMessage(message.body)
      [] message.tag = ServerHeartbeatCode -> << >>
      [] message.tag = OrderAcknowledgementCaEquitiesV1Code -> EncodeOrderAcknowledgementCaEquitiesV1(message.body)
      [] message.tag = OrderRejectedCaEquitiesV1Code -> EncodeOrderRejectedCaEquitiesV1(message.body)
      [] message.tag = OrderModifiedCaEquitiesV1Code -> EncodeOrderModifiedCaEquitiesV1(message.body)
      [] message.tag = ModifyRejectedCaEquitiesV1Code -> EncodeModifyRejectedCaEquitiesV1(message.body)
      [] message.tag = OrderRestatedCaEquitiesV1Code -> EncodeOrderRestatedCaEquitiesV1(message.body)
      [] message.tag = OrderExecutionCaEquitiesV1Code -> EncodeOrderExecutionCaEquitiesV1(message.body)
      [] message.tag = OrderCancelledCaEquitiesV1Code -> EncodeOrderCancelledCaEquitiesV1(message.body)
      [] message.tag = CancelRejectedCaEquitiesV1Code -> EncodeCancelRejectedCaEquitiesV1(message.body)
      [] message.tag = CarriedRestatementCaEquitiesV1Code -> EncodeCarriedRestatementCaEquitiesV1(message.body)
      [] message.tag = DoneForDayCaEquitiesV1Code -> EncodeDoneForDayCaEquitiesV1(message.body)
      [] message.tag = TradeCancelCorrectCaEquitiesV1Code -> EncodeTradeCancelCorrectCaEquitiesV1(message.body)

DecodeExchangeMessage(tag, bytes) ==
    LET read ==
            CASE tag = LoginResponseMessageCode -> DecodeLoginResponseMessage(bytes)
              [] tag = ReplayCompleteCode -> Ok([empty |-> 0], bytes)
              [] tag = LogoutResponseMessageCode -> DecodeLogoutResponseMessage(bytes)
              [] tag = ServerHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = OrderAcknowledgementCaEquitiesV1Code -> DecodeOrderAcknowledgementCaEquitiesV1(bytes)
              [] tag = OrderRejectedCaEquitiesV1Code -> DecodeOrderRejectedCaEquitiesV1(bytes)
              [] tag = OrderModifiedCaEquitiesV1Code -> DecodeOrderModifiedCaEquitiesV1(bytes)
              [] tag = ModifyRejectedCaEquitiesV1Code -> DecodeModifyRejectedCaEquitiesV1(bytes)
              [] tag = OrderRestatedCaEquitiesV1Code -> DecodeOrderRestatedCaEquitiesV1(bytes)
              [] tag = OrderExecutionCaEquitiesV1Code -> DecodeOrderExecutionCaEquitiesV1(bytes)
              [] tag = OrderCancelledCaEquitiesV1Code -> DecodeOrderCancelledCaEquitiesV1(bytes)
              [] tag = CancelRejectedCaEquitiesV1Code -> DecodeCancelRejectedCaEquitiesV1(bytes)
              [] tag = CarriedRestatementCaEquitiesV1Code -> DecodeCarriedRestatementCaEquitiesV1(bytes)
              [] tag = DoneForDayCaEquitiesV1Code -> DecodeDoneForDayCaEquitiesV1(bytes)
              [] tag = TradeCancelCorrectCaEquitiesV1Code -> DecodeTradeCancelCorrectCaEquitiesV1(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroExchangeMessage == [tag |-> LoginResponseMessageCode, body |-> ZeroLoginResponseMessage]

(* Each Exchange Message in turn, at the values the message it names is checked at *)
CheckedExchangeMessage ==
    { [tag |-> LoginResponseMessageCode, body |-> one] : one \in CheckedLoginResponseMessage }
        \cup { [tag |-> ReplayCompleteCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> LogoutResponseMessageCode, body |-> one] : one \in CheckedLogoutResponseMessage }
        \cup { [tag |-> ServerHeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> OrderAcknowledgementCaEquitiesV1Code, body |-> one] : one \in CheckedOrderAcknowledgementCaEquitiesV1 }
        \cup { [tag |-> OrderRejectedCaEquitiesV1Code, body |-> one] : one \in CheckedOrderRejectedCaEquitiesV1 }
        \cup { [tag |-> OrderModifiedCaEquitiesV1Code, body |-> one] : one \in CheckedOrderModifiedCaEquitiesV1 }
        \cup { [tag |-> ModifyRejectedCaEquitiesV1Code, body |-> one] : one \in CheckedModifyRejectedCaEquitiesV1 }
        \cup { [tag |-> OrderRestatedCaEquitiesV1Code, body |-> one] : one \in CheckedOrderRestatedCaEquitiesV1 }
        \cup { [tag |-> OrderExecutionCaEquitiesV1Code, body |-> one] : one \in CheckedOrderExecutionCaEquitiesV1 }
        \cup { [tag |-> OrderCancelledCaEquitiesV1Code, body |-> one] : one \in CheckedOrderCancelledCaEquitiesV1 }
        \cup { [tag |-> CancelRejectedCaEquitiesV1Code, body |-> one] : one \in CheckedCancelRejectedCaEquitiesV1 }
        \cup { [tag |-> CarriedRestatementCaEquitiesV1Code, body |-> one] : one \in CheckedCarriedRestatementCaEquitiesV1 }
        \cup { [tag |-> DoneForDayCaEquitiesV1Code, body |-> one] : one \in CheckedDoneForDayCaEquitiesV1 }
        \cup { [tag |-> TradeCancelCorrectCaEquitiesV1Code, body |-> one] : one \in CheckedTradeCancelCorrectCaEquitiesV1 }

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

(* Every Order Acknowledgement Ca Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderAcknowledgementCaEquitiesV1 ==
    \A message \in CheckedOrderAcknowledgementCaEquitiesV1 :
        LET read == DecodeOrderAcknowledgementCaEquitiesV1(EncodeOrderAcknowledgementCaEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Rejected Ca Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderRejectedCaEquitiesV1 ==
    \A message \in CheckedOrderRejectedCaEquitiesV1 :
        LET read == DecodeOrderRejectedCaEquitiesV1(EncodeOrderRejectedCaEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Modified Ca Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderModifiedCaEquitiesV1 ==
    \A message \in CheckedOrderModifiedCaEquitiesV1 :
        LET read == DecodeOrderModifiedCaEquitiesV1(EncodeOrderModifiedCaEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Rejected Ca Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyRejectedCaEquitiesV1 ==
    \A message \in CheckedModifyRejectedCaEquitiesV1 :
        LET read == DecodeModifyRejectedCaEquitiesV1(EncodeModifyRejectedCaEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Restated Ca Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderRestatedCaEquitiesV1 ==
    \A message \in CheckedOrderRestatedCaEquitiesV1 :
        LET read == DecodeOrderRestatedCaEquitiesV1(EncodeOrderRestatedCaEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Execution Ca Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutionCaEquitiesV1 ==
    \A message \in CheckedOrderExecutionCaEquitiesV1 :
        LET read == DecodeOrderExecutionCaEquitiesV1(EncodeOrderExecutionCaEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancelled Ca Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelledCaEquitiesV1 ==
    \A message \in CheckedOrderCancelledCaEquitiesV1 :
        LET read == DecodeOrderCancelledCaEquitiesV1(EncodeOrderCancelledCaEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Rejected Ca Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelRejectedCaEquitiesV1 ==
    \A message \in CheckedCancelRejectedCaEquitiesV1 :
        LET read == DecodeCancelRejectedCaEquitiesV1(EncodeCancelRejectedCaEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Carried Restatement Ca Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripCarriedRestatementCaEquitiesV1 ==
    \A message \in CheckedCarriedRestatementCaEquitiesV1 :
        LET read == DecodeCarriedRestatementCaEquitiesV1(EncodeCarriedRestatementCaEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Done For Day Ca Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripDoneForDayCaEquitiesV1 ==
    \A message \in CheckedDoneForDayCaEquitiesV1 :
        LET read == DecodeDoneForDayCaEquitiesV1(EncodeDoneForDayCaEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Cancel Correct Ca Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCancelCorrectCaEquitiesV1 ==
    \A message \in CheckedTradeCancelCorrectCaEquitiesV1 :
        LET read == DecodeTradeCancelCorrectCaEquitiesV1(EncodeTradeCancelCorrectCaEquitiesV1(message))
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
