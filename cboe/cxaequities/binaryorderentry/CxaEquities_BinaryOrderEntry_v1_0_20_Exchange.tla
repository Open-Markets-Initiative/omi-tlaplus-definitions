----------- MODULE CxaEquities_BinaryOrderEntry_v1_0_20_Exchange -----------
(***************************************************************************)
(* Chicago Board Options Exchange Binary Order Entry v1.0.20               *)
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
(* Order Acknowledgement Au Equities V 1: 192 bytes                        *)
(***************************************************************************)

OrderAcknowledgementAuEquitiesV1 ==
    [ transactionTime            : Sample(8),
      account                    : Sample(10),
      tradingParticipantId       : Sample(2),
      clOrdId                    : Sample(20),
      execInst                   : Sample(1),
      orderId                    : Sample(8),
      orderQty                   : Sample(4),
      ordType                    : Sample(1),
      price                      : Sample(8),
      capacity                   : Sample(1),
      side                       : Sample(1),
      symbol                     : Sample(6),
      timeInForce                : Sample(1),
      minQty                     : Sample(4),
      maxFloor                   : Sample(4),
      expireTime                 : Sample(8),
      clearingParticipantId      : Sample(4),
      clearingAccount            : Sample(10),
      undisclosed                : Sample(1),
      clientCrossRef             : Sample(15),
      shortSellNakedQty          : Sample(4),
      shortSellCoveredQty        : Sample(4),
      shortSellLongQty           : Sample(4),
      riskGroupId                : Sample(2),
      noTradeFeat                : Sample(1),
      noTradeKey                 : Sample(10),
      meqse                      : Sample(1),
      originOfTrans              : Sample(20),
      intermediaryId             : Sample(10),
      directedWholesaleIndicator : Sample(1),
      removeCrossingFromClearing : Sample(1),
      brokerPreferencing         : Sample(1),
      workingPrice               : Sample(8),
      baseLiquidityIndicator     : Sample(1),
      subLiquidityIndicator      : Sample(1),
      routingInst                : Sample(1),
      displayIndicator           : Sample(1),
      expireDate                 : Sample(4) ]

EncodeOrderAcknowledgementAuEquitiesV1(message) ==
    message.transactionTime
        \o message.account
        \o message.tradingParticipantId
        \o message.clOrdId
        \o message.execInst
        \o message.orderId
        \o message.orderQty
        \o message.ordType
        \o message.price
        \o message.capacity
        \o message.side
        \o message.symbol
        \o message.timeInForce
        \o message.minQty
        \o message.maxFloor
        \o message.expireTime
        \o message.clearingParticipantId
        \o message.clearingAccount
        \o message.undisclosed
        \o message.clientCrossRef
        \o message.shortSellNakedQty
        \o message.shortSellCoveredQty
        \o message.shortSellLongQty
        \o message.riskGroupId
        \o message.noTradeFeat
        \o message.noTradeKey
        \o message.meqse
        \o message.originOfTrans
        \o message.intermediaryId
        \o message.directedWholesaleIndicator
        \o message.removeCrossingFromClearing
        \o message.brokerPreferencing
        \o message.workingPrice
        \o message.baseLiquidityIndicator
        \o message.subLiquidityIndicator
        \o message.routingInst
        \o message.displayIndicator
        \o message.expireDate

DecodeOrderAcknowledgementAuEquitiesV1(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET account == ReadBytes(transactionTime.rest, 10) IN IF ~account.ok THEN Fail ELSE
    LET tradingParticipantId == ReadBytes(account.rest, 2) IN IF ~tradingParticipantId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(tradingParticipantId.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET execInst == ReadBytes(clOrdId.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET orderId == ReadBytes(execInst.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(orderId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET ordType == ReadBytes(orderQty.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET price == ReadBytes(ordType.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET capacity == ReadBytes(price.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET side == ReadBytes(capacity.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET symbol == ReadBytes(side.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(symbol.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadBytes(timeInForce.rest, 4) IN IF ~minQty.ok THEN Fail ELSE
    LET maxFloor == ReadBytes(minQty.rest, 4) IN IF ~maxFloor.ok THEN Fail ELSE
    LET expireTime == ReadBytes(maxFloor.rest, 8) IN IF ~expireTime.ok THEN Fail ELSE
    LET clearingParticipantId == ReadBytes(expireTime.rest, 4) IN IF ~clearingParticipantId.ok THEN Fail ELSE
    LET clearingAccount == ReadBytes(clearingParticipantId.rest, 10) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET undisclosed == ReadBytes(clearingAccount.rest, 1) IN IF ~undisclosed.ok THEN Fail ELSE
    LET clientCrossRef == ReadBytes(undisclosed.rest, 15) IN IF ~clientCrossRef.ok THEN Fail ELSE
    LET shortSellNakedQty == ReadBytes(clientCrossRef.rest, 4) IN IF ~shortSellNakedQty.ok THEN Fail ELSE
    LET shortSellCoveredQty == ReadBytes(shortSellNakedQty.rest, 4) IN IF ~shortSellCoveredQty.ok THEN Fail ELSE
    LET shortSellLongQty == ReadBytes(shortSellCoveredQty.rest, 4) IN IF ~shortSellLongQty.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(shortSellLongQty.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET noTradeFeat == ReadBytes(riskGroupId.rest, 1) IN IF ~noTradeFeat.ok THEN Fail ELSE
    LET noTradeKey == ReadBytes(noTradeFeat.rest, 10) IN IF ~noTradeKey.ok THEN Fail ELSE
    LET meqse == ReadBytes(noTradeKey.rest, 1) IN IF ~meqse.ok THEN Fail ELSE
    LET originOfTrans == ReadBytes(meqse.rest, 20) IN IF ~originOfTrans.ok THEN Fail ELSE
    LET intermediaryId == ReadBytes(originOfTrans.rest, 10) IN IF ~intermediaryId.ok THEN Fail ELSE
    LET directedWholesaleIndicator == ReadBytes(intermediaryId.rest, 1) IN IF ~directedWholesaleIndicator.ok THEN Fail ELSE
    LET removeCrossingFromClearing == ReadBytes(directedWholesaleIndicator.rest, 1) IN IF ~removeCrossingFromClearing.ok THEN Fail ELSE
    LET brokerPreferencing == ReadBytes(removeCrossingFromClearing.rest, 1) IN IF ~brokerPreferencing.ok THEN Fail ELSE
    LET workingPrice == ReadBytes(brokerPreferencing.rest, 8) IN IF ~workingPrice.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadBytes(workingPrice.rest, 1) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET subLiquidityIndicator == ReadBytes(baseLiquidityIndicator.rest, 1) IN IF ~subLiquidityIndicator.ok THEN Fail ELSE
    LET routingInst == ReadBytes(subLiquidityIndicator.rest, 1) IN IF ~routingInst.ok THEN Fail ELSE
    LET displayIndicator == ReadBytes(routingInst.rest, 1) IN IF ~displayIndicator.ok THEN Fail ELSE
    LET expireDate == ReadBytes(displayIndicator.rest, 4) IN IF ~expireDate.ok THEN Fail ELSE
    Ok([ transactionTime            |-> transactionTime.value,
         account                    |-> account.value,
         tradingParticipantId       |-> tradingParticipantId.value,
         clOrdId                    |-> clOrdId.value,
         execInst                   |-> execInst.value,
         orderId                    |-> orderId.value,
         orderQty                   |-> orderQty.value,
         ordType                    |-> ordType.value,
         price                      |-> price.value,
         capacity                   |-> capacity.value,
         side                       |-> side.value,
         symbol                     |-> symbol.value,
         timeInForce                |-> timeInForce.value,
         minQty                     |-> minQty.value,
         maxFloor                   |-> maxFloor.value,
         expireTime                 |-> expireTime.value,
         clearingParticipantId      |-> clearingParticipantId.value,
         clearingAccount            |-> clearingAccount.value,
         undisclosed                |-> undisclosed.value,
         clientCrossRef             |-> clientCrossRef.value,
         shortSellNakedQty          |-> shortSellNakedQty.value,
         shortSellCoveredQty        |-> shortSellCoveredQty.value,
         shortSellLongQty           |-> shortSellLongQty.value,
         riskGroupId                |-> riskGroupId.value,
         noTradeFeat                |-> noTradeFeat.value,
         noTradeKey                 |-> noTradeKey.value,
         meqse                      |-> meqse.value,
         originOfTrans              |-> originOfTrans.value,
         intermediaryId             |-> intermediaryId.value,
         directedWholesaleIndicator |-> directedWholesaleIndicator.value,
         removeCrossingFromClearing |-> removeCrossingFromClearing.value,
         brokerPreferencing         |-> brokerPreferencing.value,
         workingPrice               |-> workingPrice.value,
         baseLiquidityIndicator     |-> baseLiquidityIndicator.value,
         subLiquidityIndicator      |-> subLiquidityIndicator.value,
         routingInst                |-> routingInst.value,
         displayIndicator           |-> displayIndicator.value,
         expireDate                 |-> expireDate.value ], expireDate.rest)

ZeroOrderAcknowledgementAuEquitiesV1 ==
    [ transactionTime            |-> [i \in 1 .. 8 |-> 0],
      account                    |-> [i \in 1 .. 10 |-> 0],
      tradingParticipantId       |-> [i \in 1 .. 2 |-> 0],
      clOrdId                    |-> [i \in 1 .. 20 |-> 0],
      execInst                   |-> [i \in 1 .. 1 |-> 0],
      orderId                    |-> [i \in 1 .. 8 |-> 0],
      orderQty                   |-> [i \in 1 .. 4 |-> 0],
      ordType                    |-> [i \in 1 .. 1 |-> 0],
      price                      |-> [i \in 1 .. 8 |-> 0],
      capacity                   |-> [i \in 1 .. 1 |-> 0],
      side                       |-> [i \in 1 .. 1 |-> 0],
      symbol                     |-> [i \in 1 .. 6 |-> 0],
      timeInForce                |-> [i \in 1 .. 1 |-> 0],
      minQty                     |-> [i \in 1 .. 4 |-> 0],
      maxFloor                   |-> [i \in 1 .. 4 |-> 0],
      expireTime                 |-> [i \in 1 .. 8 |-> 0],
      clearingParticipantId      |-> [i \in 1 .. 4 |-> 0],
      clearingAccount            |-> [i \in 1 .. 10 |-> 0],
      undisclosed                |-> [i \in 1 .. 1 |-> 0],
      clientCrossRef             |-> [i \in 1 .. 15 |-> 0],
      shortSellNakedQty          |-> [i \in 1 .. 4 |-> 0],
      shortSellCoveredQty        |-> [i \in 1 .. 4 |-> 0],
      shortSellLongQty           |-> [i \in 1 .. 4 |-> 0],
      riskGroupId                |-> [i \in 1 .. 2 |-> 0],
      noTradeFeat                |-> [i \in 1 .. 1 |-> 0],
      noTradeKey                 |-> [i \in 1 .. 10 |-> 0],
      meqse                      |-> [i \in 1 .. 1 |-> 0],
      originOfTrans              |-> [i \in 1 .. 20 |-> 0],
      intermediaryId             |-> [i \in 1 .. 10 |-> 0],
      directedWholesaleIndicator |-> [i \in 1 .. 1 |-> 0],
      removeCrossingFromClearing |-> [i \in 1 .. 1 |-> 0],
      brokerPreferencing         |-> [i \in 1 .. 1 |-> 0],
      workingPrice               |-> [i \in 1 .. 8 |-> 0],
      baseLiquidityIndicator     |-> [i \in 1 .. 1 |-> 0],
      subLiquidityIndicator      |-> [i \in 1 .. 1 |-> 0],
      routingInst                |-> [i \in 1 .. 1 |-> 0],
      displayIndicator           |-> [i \in 1 .. 1 |-> 0],
      expireDate                 |-> [i \in 1 .. 4 |-> 0] ]

(* Order Acknowledgement Au Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedOrderAcknowledgementAuEquitiesV1 ==
    { ZeroOrderAcknowledgementAuEquitiesV1 }
        \cup { [ZeroOrderAcknowledgementAuEquitiesV1 EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgementAuEquitiesV1 EXCEPT !.account = one] : one \in Sample(10) }
        \cup { [ZeroOrderAcknowledgementAuEquitiesV1 EXCEPT !.tradingParticipantId = one] : one \in Sample(2) }
        \cup { [ZeroOrderAcknowledgementAuEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderAcknowledgementAuEquitiesV1 EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementAuEquitiesV1 EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgementAuEquitiesV1 EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcknowledgementAuEquitiesV1 EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementAuEquitiesV1 EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgementAuEquitiesV1 EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementAuEquitiesV1 EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementAuEquitiesV1 EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroOrderAcknowledgementAuEquitiesV1 EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementAuEquitiesV1 EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcknowledgementAuEquitiesV1 EXCEPT !.maxFloor = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcknowledgementAuEquitiesV1 EXCEPT !.expireTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgementAuEquitiesV1 EXCEPT !.clearingParticipantId = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcknowledgementAuEquitiesV1 EXCEPT !.clearingAccount = one] : one \in Sample(10) }
        \cup { [ZeroOrderAcknowledgementAuEquitiesV1 EXCEPT !.undisclosed = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementAuEquitiesV1 EXCEPT !.clientCrossRef = one] : one \in Sample(15) }
        \cup { [ZeroOrderAcknowledgementAuEquitiesV1 EXCEPT !.shortSellNakedQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcknowledgementAuEquitiesV1 EXCEPT !.shortSellCoveredQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcknowledgementAuEquitiesV1 EXCEPT !.shortSellLongQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcknowledgementAuEquitiesV1 EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroOrderAcknowledgementAuEquitiesV1 EXCEPT !.noTradeFeat = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementAuEquitiesV1 EXCEPT !.noTradeKey = one] : one \in Sample(10) }
        \cup { [ZeroOrderAcknowledgementAuEquitiesV1 EXCEPT !.meqse = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementAuEquitiesV1 EXCEPT !.originOfTrans = one] : one \in Sample(20) }
        \cup { [ZeroOrderAcknowledgementAuEquitiesV1 EXCEPT !.intermediaryId = one] : one \in Sample(10) }
        \cup { [ZeroOrderAcknowledgementAuEquitiesV1 EXCEPT !.directedWholesaleIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementAuEquitiesV1 EXCEPT !.removeCrossingFromClearing = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementAuEquitiesV1 EXCEPT !.brokerPreferencing = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementAuEquitiesV1 EXCEPT !.workingPrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgementAuEquitiesV1 EXCEPT !.baseLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementAuEquitiesV1 EXCEPT !.subLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementAuEquitiesV1 EXCEPT !.routingInst = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementAuEquitiesV1 EXCEPT !.displayIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementAuEquitiesV1 EXCEPT !.expireDate = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Rejected Au Equities V 1: 91 bytes                                *)
(***************************************************************************)

OrderRejectedAuEquitiesV1 ==
    [ transactionTime      : Sample(8),
      tradingParticipantId : Sample(2),
      clOrdId              : Sample(20),
      orderRejectReason    : Sample(1),
      text                 : Sample(60) ]

EncodeOrderRejectedAuEquitiesV1(message) ==
    message.transactionTime
        \o message.tradingParticipantId
        \o message.clOrdId
        \o message.orderRejectReason
        \o message.text

DecodeOrderRejectedAuEquitiesV1(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET tradingParticipantId == ReadBytes(transactionTime.rest, 2) IN IF ~tradingParticipantId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(tradingParticipantId.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET orderRejectReason == ReadBytes(clOrdId.rest, 1) IN IF ~orderRejectReason.ok THEN Fail ELSE
    LET text == ReadBytes(orderRejectReason.rest, 60) IN IF ~text.ok THEN Fail ELSE
    Ok([ transactionTime      |-> transactionTime.value,
         tradingParticipantId |-> tradingParticipantId.value,
         clOrdId              |-> clOrdId.value,
         orderRejectReason    |-> orderRejectReason.value,
         text                 |-> text.value ], text.rest)

ZeroOrderRejectedAuEquitiesV1 ==
    [ transactionTime      |-> [i \in 1 .. 8 |-> 0],
      tradingParticipantId |-> [i \in 1 .. 2 |-> 0],
      clOrdId              |-> [i \in 1 .. 20 |-> 0],
      orderRejectReason    |-> [i \in 1 .. 1 |-> 0],
      text                 |-> [i \in 1 .. 60 |-> 0] ]

(* Order Rejected Au Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedOrderRejectedAuEquitiesV1 ==
    { ZeroOrderRejectedAuEquitiesV1 }
        \cup { [ZeroOrderRejectedAuEquitiesV1 EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderRejectedAuEquitiesV1 EXCEPT !.tradingParticipantId = one] : one \in Sample(2) }
        \cup { [ZeroOrderRejectedAuEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderRejectedAuEquitiesV1 EXCEPT !.orderRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroOrderRejectedAuEquitiesV1 EXCEPT !.text = one] : one \in Sample(60) }

(***************************************************************************)
(* Order Modified Au Equities V 1: 105 bytes                               *)
(***************************************************************************)

OrderModifiedAuEquitiesV1 ==
    [ transactionTime        : Sample(8),
      tradingParticipantId   : Sample(2),
      clOrdId                : Sample(20),
      execInst               : Sample(1),
      orderQty               : Sample(4),
      origClOrdId            : Sample(20),
      price                  : Sample(8),
      minQty                 : Sample(4),
      maxFloor               : Sample(4),
      leavesQty              : Sample(4),
      secondaryOrderId       : Sample(8),
      shortSellNakedQty      : Sample(4),
      shortSellCoveredQty    : Sample(4),
      shortSellLongQty       : Sample(4),
      workingPrice           : Sample(8),
      baseLiquidityIndicator : Sample(1),
      subLiquidityIndicator  : Sample(1) ]

EncodeOrderModifiedAuEquitiesV1(message) ==
    message.transactionTime
        \o message.tradingParticipantId
        \o message.clOrdId
        \o message.execInst
        \o message.orderQty
        \o message.origClOrdId
        \o message.price
        \o message.minQty
        \o message.maxFloor
        \o message.leavesQty
        \o message.secondaryOrderId
        \o message.shortSellNakedQty
        \o message.shortSellCoveredQty
        \o message.shortSellLongQty
        \o message.workingPrice
        \o message.baseLiquidityIndicator
        \o message.subLiquidityIndicator

DecodeOrderModifiedAuEquitiesV1(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET tradingParticipantId == ReadBytes(transactionTime.rest, 2) IN IF ~tradingParticipantId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(tradingParticipantId.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET execInst == ReadBytes(clOrdId.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET orderQty == ReadBytes(execInst.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(orderQty.rest, 20) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET price == ReadBytes(origClOrdId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET minQty == ReadBytes(price.rest, 4) IN IF ~minQty.ok THEN Fail ELSE
    LET maxFloor == ReadBytes(minQty.rest, 4) IN IF ~maxFloor.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(maxFloor.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET secondaryOrderId == ReadBytes(leavesQty.rest, 8) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET shortSellNakedQty == ReadBytes(secondaryOrderId.rest, 4) IN IF ~shortSellNakedQty.ok THEN Fail ELSE
    LET shortSellCoveredQty == ReadBytes(shortSellNakedQty.rest, 4) IN IF ~shortSellCoveredQty.ok THEN Fail ELSE
    LET shortSellLongQty == ReadBytes(shortSellCoveredQty.rest, 4) IN IF ~shortSellLongQty.ok THEN Fail ELSE
    LET workingPrice == ReadBytes(shortSellLongQty.rest, 8) IN IF ~workingPrice.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadBytes(workingPrice.rest, 1) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET subLiquidityIndicator == ReadBytes(baseLiquidityIndicator.rest, 1) IN IF ~subLiquidityIndicator.ok THEN Fail ELSE
    Ok([ transactionTime        |-> transactionTime.value,
         tradingParticipantId   |-> tradingParticipantId.value,
         clOrdId                |-> clOrdId.value,
         execInst               |-> execInst.value,
         orderQty               |-> orderQty.value,
         origClOrdId            |-> origClOrdId.value,
         price                  |-> price.value,
         minQty                 |-> minQty.value,
         maxFloor               |-> maxFloor.value,
         leavesQty              |-> leavesQty.value,
         secondaryOrderId       |-> secondaryOrderId.value,
         shortSellNakedQty      |-> shortSellNakedQty.value,
         shortSellCoveredQty    |-> shortSellCoveredQty.value,
         shortSellLongQty       |-> shortSellLongQty.value,
         workingPrice           |-> workingPrice.value,
         baseLiquidityIndicator |-> baseLiquidityIndicator.value,
         subLiquidityIndicator  |-> subLiquidityIndicator.value ], subLiquidityIndicator.rest)

ZeroOrderModifiedAuEquitiesV1 ==
    [ transactionTime        |-> [i \in 1 .. 8 |-> 0],
      tradingParticipantId   |-> [i \in 1 .. 2 |-> 0],
      clOrdId                |-> [i \in 1 .. 20 |-> 0],
      execInst               |-> [i \in 1 .. 1 |-> 0],
      orderQty               |-> [i \in 1 .. 4 |-> 0],
      origClOrdId            |-> [i \in 1 .. 20 |-> 0],
      price                  |-> [i \in 1 .. 8 |-> 0],
      minQty                 |-> [i \in 1 .. 4 |-> 0],
      maxFloor               |-> [i \in 1 .. 4 |-> 0],
      leavesQty              |-> [i \in 1 .. 4 |-> 0],
      secondaryOrderId       |-> [i \in 1 .. 8 |-> 0],
      shortSellNakedQty      |-> [i \in 1 .. 4 |-> 0],
      shortSellCoveredQty    |-> [i \in 1 .. 4 |-> 0],
      shortSellLongQty       |-> [i \in 1 .. 4 |-> 0],
      workingPrice           |-> [i \in 1 .. 8 |-> 0],
      baseLiquidityIndicator |-> [i \in 1 .. 1 |-> 0],
      subLiquidityIndicator  |-> [i \in 1 .. 1 |-> 0] ]

(* Order Modified Au Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedOrderModifiedAuEquitiesV1 ==
    { ZeroOrderModifiedAuEquitiesV1 }
        \cup { [ZeroOrderModifiedAuEquitiesV1 EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifiedAuEquitiesV1 EXCEPT !.tradingParticipantId = one] : one \in Sample(2) }
        \cup { [ZeroOrderModifiedAuEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderModifiedAuEquitiesV1 EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifiedAuEquitiesV1 EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifiedAuEquitiesV1 EXCEPT !.origClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderModifiedAuEquitiesV1 EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifiedAuEquitiesV1 EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifiedAuEquitiesV1 EXCEPT !.maxFloor = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifiedAuEquitiesV1 EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifiedAuEquitiesV1 EXCEPT !.secondaryOrderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifiedAuEquitiesV1 EXCEPT !.shortSellNakedQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifiedAuEquitiesV1 EXCEPT !.shortSellCoveredQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifiedAuEquitiesV1 EXCEPT !.shortSellLongQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifiedAuEquitiesV1 EXCEPT !.workingPrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifiedAuEquitiesV1 EXCEPT !.baseLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifiedAuEquitiesV1 EXCEPT !.subLiquidityIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Modify Rejected Au Equities V 1: 111 bytes                              *)
(***************************************************************************)

ModifyRejectedAuEquitiesV1 ==
    [ transactionTime      : Sample(8),
      tradingParticipantId : Sample(2),
      clOrdId              : Sample(20),
      origClOrdId          : Sample(20),
      modifyRejectReason   : Sample(1),
      text                 : Sample(60) ]

EncodeModifyRejectedAuEquitiesV1(message) ==
    message.transactionTime
        \o message.tradingParticipantId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.modifyRejectReason
        \o message.text

DecodeModifyRejectedAuEquitiesV1(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET tradingParticipantId == ReadBytes(transactionTime.rest, 2) IN IF ~tradingParticipantId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(tradingParticipantId.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 20) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET modifyRejectReason == ReadBytes(origClOrdId.rest, 1) IN IF ~modifyRejectReason.ok THEN Fail ELSE
    LET text == ReadBytes(modifyRejectReason.rest, 60) IN IF ~text.ok THEN Fail ELSE
    Ok([ transactionTime      |-> transactionTime.value,
         tradingParticipantId |-> tradingParticipantId.value,
         clOrdId              |-> clOrdId.value,
         origClOrdId          |-> origClOrdId.value,
         modifyRejectReason   |-> modifyRejectReason.value,
         text                 |-> text.value ], text.rest)

ZeroModifyRejectedAuEquitiesV1 ==
    [ transactionTime      |-> [i \in 1 .. 8 |-> 0],
      tradingParticipantId |-> [i \in 1 .. 2 |-> 0],
      clOrdId              |-> [i \in 1 .. 20 |-> 0],
      origClOrdId          |-> [i \in 1 .. 20 |-> 0],
      modifyRejectReason   |-> [i \in 1 .. 1 |-> 0],
      text                 |-> [i \in 1 .. 60 |-> 0] ]

(* Modify Rejected Au Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedModifyRejectedAuEquitiesV1 ==
    { ZeroModifyRejectedAuEquitiesV1 }
        \cup { [ZeroModifyRejectedAuEquitiesV1 EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroModifyRejectedAuEquitiesV1 EXCEPT !.tradingParticipantId = one] : one \in Sample(2) }
        \cup { [ZeroModifyRejectedAuEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroModifyRejectedAuEquitiesV1 EXCEPT !.origClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroModifyRejectedAuEquitiesV1 EXCEPT !.modifyRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroModifyRejectedAuEquitiesV1 EXCEPT !.text = one] : one \in Sample(60) }

(***************************************************************************)
(* Order Restated Au Equities V 1: 76 bytes                                *)
(***************************************************************************)

OrderRestatedAuEquitiesV1 ==
    [ transactionTime        : Sample(8),
      tradingParticipantId   : Sample(2),
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

EncodeOrderRestatedAuEquitiesV1(message) ==
    message.transactionTime
        \o message.tradingParticipantId
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

DecodeOrderRestatedAuEquitiesV1(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET tradingParticipantId == ReadBytes(transactionTime.rest, 2) IN IF ~tradingParticipantId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(tradingParticipantId.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
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
         tradingParticipantId   |-> tradingParticipantId.value,
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

ZeroOrderRestatedAuEquitiesV1 ==
    [ transactionTime        |-> [i \in 1 .. 8 |-> 0],
      tradingParticipantId   |-> [i \in 1 .. 2 |-> 0],
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

(* Order Restated Au Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedOrderRestatedAuEquitiesV1 ==
    { ZeroOrderRestatedAuEquitiesV1 }
        \cup { [ZeroOrderRestatedAuEquitiesV1 EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderRestatedAuEquitiesV1 EXCEPT !.tradingParticipantId = one] : one \in Sample(2) }
        \cup { [ZeroOrderRestatedAuEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderRestatedAuEquitiesV1 EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderRestatedAuEquitiesV1 EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderRestatedAuEquitiesV1 EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderRestatedAuEquitiesV1 EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderRestatedAuEquitiesV1 EXCEPT !.secondaryOrderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderRestatedAuEquitiesV1 EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroOrderRestatedAuEquitiesV1 EXCEPT !.lastShares = one] : one \in Sample(4) }
        \cup { [ZeroOrderRestatedAuEquitiesV1 EXCEPT !.baseLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderRestatedAuEquitiesV1 EXCEPT !.restatementReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Execution Au Equities V 1: 104 bytes                              *)
(***************************************************************************)

OrderExecutionAuEquitiesV1 ==
    [ transactionTime        : Sample(8),
      tradingParticipantId   : Sample(2),
      clOrdId                : Sample(20),
      execId                 : Sample(8),
      lastCapacity           : Sample(1),
      lastMkt                : Sample(4),
      lastPx                 : Sample(8),
      lastShares             : Sample(4),
      side                   : Sample(1),
      symbol                 : Sample(6),
      leavesQty              : Sample(4),
      secondaryOrderId       : Sample(8),
      clearingParticipantId  : Sample(4),
      priceImprovement       : Sample(8),
      transactId             : Sample(10),
      onMarketCrossType      : Sample(1),
      tradeReportType        : Sample(1),
      baseLiquidityIndicator : Sample(1),
      subLiquidityIndicator  : Sample(1),
      contraParticipantId    : Sample(2),
      feeCode                : Sample(2) ]

EncodeOrderExecutionAuEquitiesV1(message) ==
    message.transactionTime
        \o message.tradingParticipantId
        \o message.clOrdId
        \o message.execId
        \o message.lastCapacity
        \o message.lastMkt
        \o message.lastPx
        \o message.lastShares
        \o message.side
        \o message.symbol
        \o message.leavesQty
        \o message.secondaryOrderId
        \o message.clearingParticipantId
        \o message.priceImprovement
        \o message.transactId
        \o message.onMarketCrossType
        \o message.tradeReportType
        \o message.baseLiquidityIndicator
        \o message.subLiquidityIndicator
        \o message.contraParticipantId
        \o message.feeCode

DecodeOrderExecutionAuEquitiesV1(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET tradingParticipantId == ReadBytes(transactionTime.rest, 2) IN IF ~tradingParticipantId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(tradingParticipantId.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET execId == ReadBytes(clOrdId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET lastCapacity == ReadBytes(execId.rest, 1) IN IF ~lastCapacity.ok THEN Fail ELSE
    LET lastMkt == ReadBytes(lastCapacity.rest, 4) IN IF ~lastMkt.ok THEN Fail ELSE
    LET lastPx == ReadBytes(lastMkt.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastShares == ReadBytes(lastPx.rest, 4) IN IF ~lastShares.ok THEN Fail ELSE
    LET side == ReadBytes(lastShares.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET symbol == ReadBytes(side.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(symbol.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET secondaryOrderId == ReadBytes(leavesQty.rest, 8) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET clearingParticipantId == ReadBytes(secondaryOrderId.rest, 4) IN IF ~clearingParticipantId.ok THEN Fail ELSE
    LET priceImprovement == ReadBytes(clearingParticipantId.rest, 8) IN IF ~priceImprovement.ok THEN Fail ELSE
    LET transactId == ReadBytes(priceImprovement.rest, 10) IN IF ~transactId.ok THEN Fail ELSE
    LET onMarketCrossType == ReadBytes(transactId.rest, 1) IN IF ~onMarketCrossType.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(onMarketCrossType.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadBytes(tradeReportType.rest, 1) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET subLiquidityIndicator == ReadBytes(baseLiquidityIndicator.rest, 1) IN IF ~subLiquidityIndicator.ok THEN Fail ELSE
    LET contraParticipantId == ReadBytes(subLiquidityIndicator.rest, 2) IN IF ~contraParticipantId.ok THEN Fail ELSE
    LET feeCode == ReadBytes(contraParticipantId.rest, 2) IN IF ~feeCode.ok THEN Fail ELSE
    Ok([ transactionTime        |-> transactionTime.value,
         tradingParticipantId   |-> tradingParticipantId.value,
         clOrdId                |-> clOrdId.value,
         execId                 |-> execId.value,
         lastCapacity           |-> lastCapacity.value,
         lastMkt                |-> lastMkt.value,
         lastPx                 |-> lastPx.value,
         lastShares             |-> lastShares.value,
         side                   |-> side.value,
         symbol                 |-> symbol.value,
         leavesQty              |-> leavesQty.value,
         secondaryOrderId       |-> secondaryOrderId.value,
         clearingParticipantId  |-> clearingParticipantId.value,
         priceImprovement       |-> priceImprovement.value,
         transactId             |-> transactId.value,
         onMarketCrossType      |-> onMarketCrossType.value,
         tradeReportType        |-> tradeReportType.value,
         baseLiquidityIndicator |-> baseLiquidityIndicator.value,
         subLiquidityIndicator  |-> subLiquidityIndicator.value,
         contraParticipantId    |-> contraParticipantId.value,
         feeCode                |-> feeCode.value ], feeCode.rest)

ZeroOrderExecutionAuEquitiesV1 ==
    [ transactionTime        |-> [i \in 1 .. 8 |-> 0],
      tradingParticipantId   |-> [i \in 1 .. 2 |-> 0],
      clOrdId                |-> [i \in 1 .. 20 |-> 0],
      execId                 |-> [i \in 1 .. 8 |-> 0],
      lastCapacity           |-> [i \in 1 .. 1 |-> 0],
      lastMkt                |-> [i \in 1 .. 4 |-> 0],
      lastPx                 |-> [i \in 1 .. 8 |-> 0],
      lastShares             |-> [i \in 1 .. 4 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      symbol                 |-> [i \in 1 .. 6 |-> 0],
      leavesQty              |-> [i \in 1 .. 4 |-> 0],
      secondaryOrderId       |-> [i \in 1 .. 8 |-> 0],
      clearingParticipantId  |-> [i \in 1 .. 4 |-> 0],
      priceImprovement       |-> [i \in 1 .. 8 |-> 0],
      transactId             |-> [i \in 1 .. 10 |-> 0],
      onMarketCrossType      |-> [i \in 1 .. 1 |-> 0],
      tradeReportType        |-> [i \in 1 .. 1 |-> 0],
      baseLiquidityIndicator |-> [i \in 1 .. 1 |-> 0],
      subLiquidityIndicator  |-> [i \in 1 .. 1 |-> 0],
      contraParticipantId    |-> [i \in 1 .. 2 |-> 0],
      feeCode                |-> [i \in 1 .. 2 |-> 0] ]

(* Order Execution Au Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutionAuEquitiesV1 ==
    { ZeroOrderExecutionAuEquitiesV1 }
        \cup { [ZeroOrderExecutionAuEquitiesV1 EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionAuEquitiesV1 EXCEPT !.tradingParticipantId = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecutionAuEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderExecutionAuEquitiesV1 EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionAuEquitiesV1 EXCEPT !.lastCapacity = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionAuEquitiesV1 EXCEPT !.lastMkt = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionAuEquitiesV1 EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionAuEquitiesV1 EXCEPT !.lastShares = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionAuEquitiesV1 EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionAuEquitiesV1 EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroOrderExecutionAuEquitiesV1 EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionAuEquitiesV1 EXCEPT !.secondaryOrderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionAuEquitiesV1 EXCEPT !.clearingParticipantId = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionAuEquitiesV1 EXCEPT !.priceImprovement = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionAuEquitiesV1 EXCEPT !.transactId = one] : one \in Sample(10) }
        \cup { [ZeroOrderExecutionAuEquitiesV1 EXCEPT !.onMarketCrossType = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionAuEquitiesV1 EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionAuEquitiesV1 EXCEPT !.baseLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionAuEquitiesV1 EXCEPT !.subLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionAuEquitiesV1 EXCEPT !.contraParticipantId = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecutionAuEquitiesV1 EXCEPT !.feeCode = one] : one \in Sample(2) }

(***************************************************************************)
(* Order Cancelled Au Equities V 1: 31 bytes                               *)
(***************************************************************************)

OrderCancelledAuEquitiesV1 ==
    [ transactionTime      : Sample(8),
      tradingParticipantId : Sample(2),
      clOrdId              : Sample(20),
      cancelReason         : Sample(1) ]

EncodeOrderCancelledAuEquitiesV1(message) ==
    message.transactionTime
        \o message.tradingParticipantId
        \o message.clOrdId
        \o message.cancelReason

DecodeOrderCancelledAuEquitiesV1(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET tradingParticipantId == ReadBytes(transactionTime.rest, 2) IN IF ~tradingParticipantId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(tradingParticipantId.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET cancelReason == ReadBytes(clOrdId.rest, 1) IN IF ~cancelReason.ok THEN Fail ELSE
    Ok([ transactionTime      |-> transactionTime.value,
         tradingParticipantId |-> tradingParticipantId.value,
         clOrdId              |-> clOrdId.value,
         cancelReason         |-> cancelReason.value ], cancelReason.rest)

ZeroOrderCancelledAuEquitiesV1 ==
    [ transactionTime      |-> [i \in 1 .. 8 |-> 0],
      tradingParticipantId |-> [i \in 1 .. 2 |-> 0],
      clOrdId              |-> [i \in 1 .. 20 |-> 0],
      cancelReason         |-> [i \in 1 .. 1 |-> 0] ]

(* Order Cancelled Au Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelledAuEquitiesV1 ==
    { ZeroOrderCancelledAuEquitiesV1 }
        \cup { [ZeroOrderCancelledAuEquitiesV1 EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelledAuEquitiesV1 EXCEPT !.tradingParticipantId = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelledAuEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderCancelledAuEquitiesV1 EXCEPT !.cancelReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Cancel Rejected Au Equities V 1: 91 bytes                               *)
(***************************************************************************)

CancelRejectedAuEquitiesV1 ==
    [ transactionTime      : Sample(8),
      tradingParticipantId : Sample(2),
      clOrdId              : Sample(20),
      cancelRejectReason   : Sample(1),
      text                 : Sample(60) ]

EncodeCancelRejectedAuEquitiesV1(message) ==
    message.transactionTime
        \o message.tradingParticipantId
        \o message.clOrdId
        \o message.cancelRejectReason
        \o message.text

DecodeCancelRejectedAuEquitiesV1(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET tradingParticipantId == ReadBytes(transactionTime.rest, 2) IN IF ~tradingParticipantId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(tradingParticipantId.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET cancelRejectReason == ReadBytes(clOrdId.rest, 1) IN IF ~cancelRejectReason.ok THEN Fail ELSE
    LET text == ReadBytes(cancelRejectReason.rest, 60) IN IF ~text.ok THEN Fail ELSE
    Ok([ transactionTime      |-> transactionTime.value,
         tradingParticipantId |-> tradingParticipantId.value,
         clOrdId              |-> clOrdId.value,
         cancelRejectReason   |-> cancelRejectReason.value,
         text                 |-> text.value ], text.rest)

ZeroCancelRejectedAuEquitiesV1 ==
    [ transactionTime      |-> [i \in 1 .. 8 |-> 0],
      tradingParticipantId |-> [i \in 1 .. 2 |-> 0],
      clOrdId              |-> [i \in 1 .. 20 |-> 0],
      cancelRejectReason   |-> [i \in 1 .. 1 |-> 0],
      text                 |-> [i \in 1 .. 60 |-> 0] ]

(* Cancel Rejected Au Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedCancelRejectedAuEquitiesV1 ==
    { ZeroCancelRejectedAuEquitiesV1 }
        \cup { [ZeroCancelRejectedAuEquitiesV1 EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroCancelRejectedAuEquitiesV1 EXCEPT !.tradingParticipantId = one] : one \in Sample(2) }
        \cup { [ZeroCancelRejectedAuEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroCancelRejectedAuEquitiesV1 EXCEPT !.cancelRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroCancelRejectedAuEquitiesV1 EXCEPT !.text = one] : one \in Sample(60) }

(***************************************************************************)
(* Execution Restatement Au Equities V 1: 73 bytes                         *)
(***************************************************************************)

ExecutionRestatementAuEquitiesV1 ==
    [ transactionTime        : Sample(8),
      tradingParticipantId   : Sample(2),
      clOrdId                : Sample(20),
      execId                 : Sample(8),
      lastPx                 : Sample(8),
      lastShares             : Sample(4),
      side                   : Sample(1),
      symbol                 : Sample(6),
      transactId             : Sample(10),
      baseLiquidityIndicator : Sample(1),
      contraParticipantId    : Sample(2),
      feeCode                : Sample(2),
      execRestatementReason  : Sample(1) ]

EncodeExecutionRestatementAuEquitiesV1(message) ==
    message.transactionTime
        \o message.tradingParticipantId
        \o message.clOrdId
        \o message.execId
        \o message.lastPx
        \o message.lastShares
        \o message.side
        \o message.symbol
        \o message.transactId
        \o message.baseLiquidityIndicator
        \o message.contraParticipantId
        \o message.feeCode
        \o message.execRestatementReason

DecodeExecutionRestatementAuEquitiesV1(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET tradingParticipantId == ReadBytes(transactionTime.rest, 2) IN IF ~tradingParticipantId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(tradingParticipantId.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET execId == ReadBytes(clOrdId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET lastPx == ReadBytes(execId.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastShares == ReadBytes(lastPx.rest, 4) IN IF ~lastShares.ok THEN Fail ELSE
    LET side == ReadBytes(lastShares.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET symbol == ReadBytes(side.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET transactId == ReadBytes(symbol.rest, 10) IN IF ~transactId.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadBytes(transactId.rest, 1) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET contraParticipantId == ReadBytes(baseLiquidityIndicator.rest, 2) IN IF ~contraParticipantId.ok THEN Fail ELSE
    LET feeCode == ReadBytes(contraParticipantId.rest, 2) IN IF ~feeCode.ok THEN Fail ELSE
    LET execRestatementReason == ReadBytes(feeCode.rest, 1) IN IF ~execRestatementReason.ok THEN Fail ELSE
    Ok([ transactionTime        |-> transactionTime.value,
         tradingParticipantId   |-> tradingParticipantId.value,
         clOrdId                |-> clOrdId.value,
         execId                 |-> execId.value,
         lastPx                 |-> lastPx.value,
         lastShares             |-> lastShares.value,
         side                   |-> side.value,
         symbol                 |-> symbol.value,
         transactId             |-> transactId.value,
         baseLiquidityIndicator |-> baseLiquidityIndicator.value,
         contraParticipantId    |-> contraParticipantId.value,
         feeCode                |-> feeCode.value,
         execRestatementReason  |-> execRestatementReason.value ], execRestatementReason.rest)

ZeroExecutionRestatementAuEquitiesV1 ==
    [ transactionTime        |-> [i \in 1 .. 8 |-> 0],
      tradingParticipantId   |-> [i \in 1 .. 2 |-> 0],
      clOrdId                |-> [i \in 1 .. 20 |-> 0],
      execId                 |-> [i \in 1 .. 8 |-> 0],
      lastPx                 |-> [i \in 1 .. 8 |-> 0],
      lastShares             |-> [i \in 1 .. 4 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      symbol                 |-> [i \in 1 .. 6 |-> 0],
      transactId             |-> [i \in 1 .. 10 |-> 0],
      baseLiquidityIndicator |-> [i \in 1 .. 1 |-> 0],
      contraParticipantId    |-> [i \in 1 .. 2 |-> 0],
      feeCode                |-> [i \in 1 .. 2 |-> 0],
      execRestatementReason  |-> [i \in 1 .. 1 |-> 0] ]

(* Execution Restatement Au Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedExecutionRestatementAuEquitiesV1 ==
    { ZeroExecutionRestatementAuEquitiesV1 }
        \cup { [ZeroExecutionRestatementAuEquitiesV1 EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionRestatementAuEquitiesV1 EXCEPT !.tradingParticipantId = one] : one \in Sample(2) }
        \cup { [ZeroExecutionRestatementAuEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroExecutionRestatementAuEquitiesV1 EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionRestatementAuEquitiesV1 EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroExecutionRestatementAuEquitiesV1 EXCEPT !.lastShares = one] : one \in Sample(4) }
        \cup { [ZeroExecutionRestatementAuEquitiesV1 EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroExecutionRestatementAuEquitiesV1 EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroExecutionRestatementAuEquitiesV1 EXCEPT !.transactId = one] : one \in Sample(10) }
        \cup { [ZeroExecutionRestatementAuEquitiesV1 EXCEPT !.baseLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExecutionRestatementAuEquitiesV1 EXCEPT !.contraParticipantId = one] : one \in Sample(2) }
        \cup { [ZeroExecutionRestatementAuEquitiesV1 EXCEPT !.feeCode = one] : one \in Sample(2) }
        \cup { [ZeroExecutionRestatementAuEquitiesV1 EXCEPT !.execRestatementReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Purge Acknowledgement Au Equities V 1: 32 bytes                         *)
(***************************************************************************)

PurgeAcknowledgementAuEquitiesV1 ==
    [ transactionTime     : Sample(8),
      massCancelId        : Sample(20),
      cancelledOrderCount : Sample(4) ]

EncodePurgeAcknowledgementAuEquitiesV1(message) ==
    message.transactionTime
        \o message.massCancelId
        \o message.cancelledOrderCount

DecodePurgeAcknowledgementAuEquitiesV1(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET massCancelId == ReadBytes(transactionTime.rest, 20) IN IF ~massCancelId.ok THEN Fail ELSE
    LET cancelledOrderCount == ReadBytes(massCancelId.rest, 4) IN IF ~cancelledOrderCount.ok THEN Fail ELSE
    Ok([ transactionTime     |-> transactionTime.value,
         massCancelId        |-> massCancelId.value,
         cancelledOrderCount |-> cancelledOrderCount.value ], cancelledOrderCount.rest)

ZeroPurgeAcknowledgementAuEquitiesV1 ==
    [ transactionTime     |-> [i \in 1 .. 8 |-> 0],
      massCancelId        |-> [i \in 1 .. 20 |-> 0],
      cancelledOrderCount |-> [i \in 1 .. 4 |-> 0] ]

(* Purge Acknowledgement Au Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedPurgeAcknowledgementAuEquitiesV1 ==
    { ZeroPurgeAcknowledgementAuEquitiesV1 }
        \cup { [ZeroPurgeAcknowledgementAuEquitiesV1 EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroPurgeAcknowledgementAuEquitiesV1 EXCEPT !.massCancelId = one] : one \in Sample(20) }
        \cup { [ZeroPurgeAcknowledgementAuEquitiesV1 EXCEPT !.cancelledOrderCount = one] : one \in Sample(4) }

(***************************************************************************)
(* Purge Rejected Au Equities V 1: 89 bytes                                *)
(***************************************************************************)

PurgeRejectedAuEquitiesV1 ==
    [ transactionTime   : Sample(8),
      massCancelId      : Sample(20),
      purgeRejectReason : Sample(1),
      text              : Sample(60) ]

EncodePurgeRejectedAuEquitiesV1(message) ==
    message.transactionTime
        \o message.massCancelId
        \o message.purgeRejectReason
        \o message.text

DecodePurgeRejectedAuEquitiesV1(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET massCancelId == ReadBytes(transactionTime.rest, 20) IN IF ~massCancelId.ok THEN Fail ELSE
    LET purgeRejectReason == ReadBytes(massCancelId.rest, 1) IN IF ~purgeRejectReason.ok THEN Fail ELSE
    LET text == ReadBytes(purgeRejectReason.rest, 60) IN IF ~text.ok THEN Fail ELSE
    Ok([ transactionTime   |-> transactionTime.value,
         massCancelId      |-> massCancelId.value,
         purgeRejectReason |-> purgeRejectReason.value,
         text              |-> text.value ], text.rest)

ZeroPurgeRejectedAuEquitiesV1 ==
    [ transactionTime   |-> [i \in 1 .. 8 |-> 0],
      massCancelId      |-> [i \in 1 .. 20 |-> 0],
      purgeRejectReason |-> [i \in 1 .. 1 |-> 0],
      text              |-> [i \in 1 .. 60 |-> 0] ]

(* Purge Rejected Au Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedPurgeRejectedAuEquitiesV1 ==
    { ZeroPurgeRejectedAuEquitiesV1 }
        \cup { [ZeroPurgeRejectedAuEquitiesV1 EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroPurgeRejectedAuEquitiesV1 EXCEPT !.massCancelId = one] : one \in Sample(20) }
        \cup { [ZeroPurgeRejectedAuEquitiesV1 EXCEPT !.purgeRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroPurgeRejectedAuEquitiesV1 EXCEPT !.text = one] : one \in Sample(60) }

(***************************************************************************)
(* Trade Cancel Correct Au Equities V 1: 88 bytes                          *)
(***************************************************************************)

TradeCancelCorrectAuEquitiesV1 ==
    [ transactionTime        : Sample(8),
      tradingParticipantId   : Sample(2),
      clOrdId                : Sample(20),
      execRefId              : Sample(8),
      lastPx                 : Sample(8),
      lastShares             : Sample(4),
      origTime               : Sample(8),
      side                   : Sample(1),
      symbol                 : Sample(6),
      clearingParticipantId  : Sample(4),
      transactId             : Sample(10),
      correctedPrice         : Sample(8),
      baseLiquidityIndicator : Sample(1) ]

EncodeTradeCancelCorrectAuEquitiesV1(message) ==
    message.transactionTime
        \o message.tradingParticipantId
        \o message.clOrdId
        \o message.execRefId
        \o message.lastPx
        \o message.lastShares
        \o message.origTime
        \o message.side
        \o message.symbol
        \o message.clearingParticipantId
        \o message.transactId
        \o message.correctedPrice
        \o message.baseLiquidityIndicator

DecodeTradeCancelCorrectAuEquitiesV1(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET tradingParticipantId == ReadBytes(transactionTime.rest, 2) IN IF ~tradingParticipantId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(tradingParticipantId.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET execRefId == ReadBytes(clOrdId.rest, 8) IN IF ~execRefId.ok THEN Fail ELSE
    LET lastPx == ReadBytes(execRefId.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastShares == ReadBytes(lastPx.rest, 4) IN IF ~lastShares.ok THEN Fail ELSE
    LET origTime == ReadBytes(lastShares.rest, 8) IN IF ~origTime.ok THEN Fail ELSE
    LET side == ReadBytes(origTime.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET symbol == ReadBytes(side.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET clearingParticipantId == ReadBytes(symbol.rest, 4) IN IF ~clearingParticipantId.ok THEN Fail ELSE
    LET transactId == ReadBytes(clearingParticipantId.rest, 10) IN IF ~transactId.ok THEN Fail ELSE
    LET correctedPrice == ReadBytes(transactId.rest, 8) IN IF ~correctedPrice.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadBytes(correctedPrice.rest, 1) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    Ok([ transactionTime        |-> transactionTime.value,
         tradingParticipantId   |-> tradingParticipantId.value,
         clOrdId                |-> clOrdId.value,
         execRefId              |-> execRefId.value,
         lastPx                 |-> lastPx.value,
         lastShares             |-> lastShares.value,
         origTime               |-> origTime.value,
         side                   |-> side.value,
         symbol                 |-> symbol.value,
         clearingParticipantId  |-> clearingParticipantId.value,
         transactId             |-> transactId.value,
         correctedPrice         |-> correctedPrice.value,
         baseLiquidityIndicator |-> baseLiquidityIndicator.value ], baseLiquidityIndicator.rest)

ZeroTradeCancelCorrectAuEquitiesV1 ==
    [ transactionTime        |-> [i \in 1 .. 8 |-> 0],
      tradingParticipantId   |-> [i \in 1 .. 2 |-> 0],
      clOrdId                |-> [i \in 1 .. 20 |-> 0],
      execRefId              |-> [i \in 1 .. 8 |-> 0],
      lastPx                 |-> [i \in 1 .. 8 |-> 0],
      lastShares             |-> [i \in 1 .. 4 |-> 0],
      origTime               |-> [i \in 1 .. 8 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      symbol                 |-> [i \in 1 .. 6 |-> 0],
      clearingParticipantId  |-> [i \in 1 .. 4 |-> 0],
      transactId             |-> [i \in 1 .. 10 |-> 0],
      correctedPrice         |-> [i \in 1 .. 8 |-> 0],
      baseLiquidityIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Cancel Correct Au Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedTradeCancelCorrectAuEquitiesV1 ==
    { ZeroTradeCancelCorrectAuEquitiesV1 }
        \cup { [ZeroTradeCancelCorrectAuEquitiesV1 EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelCorrectAuEquitiesV1 EXCEPT !.tradingParticipantId = one] : one \in Sample(2) }
        \cup { [ZeroTradeCancelCorrectAuEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroTradeCancelCorrectAuEquitiesV1 EXCEPT !.execRefId = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelCorrectAuEquitiesV1 EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelCorrectAuEquitiesV1 EXCEPT !.lastShares = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelCorrectAuEquitiesV1 EXCEPT !.origTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelCorrectAuEquitiesV1 EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelCorrectAuEquitiesV1 EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroTradeCancelCorrectAuEquitiesV1 EXCEPT !.clearingParticipantId = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelCorrectAuEquitiesV1 EXCEPT !.transactId = one] : one \in Sample(10) }
        \cup { [ZeroTradeCancelCorrectAuEquitiesV1 EXCEPT !.correctedPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelCorrectAuEquitiesV1 EXCEPT !.baseLiquidityIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Modified Au Equities V 2: 109 bytes                               *)
(***************************************************************************)

OrderModifiedAuEquitiesV2 ==
    [ transactionTime        : Sample(8),
      tradingParticipantId   : Sample(2),
      clOrdId                : Sample(20),
      execInst               : Sample(1),
      orderQty               : Sample(4),
      origClOrdId            : Sample(20),
      price                  : Sample(8),
      minQty                 : Sample(4),
      maxFloor               : Sample(4),
      leavesQty              : Sample(4),
      secondaryOrderId       : Sample(8),
      shortSellNakedQty      : Sample(4),
      shortSellCoveredQty    : Sample(4),
      shortSellLongQty       : Sample(4),
      workingPrice           : Sample(8),
      baseLiquidityIndicator : Sample(1),
      subLiquidityIndicator  : Sample(1),
      expireDate             : Sample(4) ]

EncodeOrderModifiedAuEquitiesV2(message) ==
    message.transactionTime
        \o message.tradingParticipantId
        \o message.clOrdId
        \o message.execInst
        \o message.orderQty
        \o message.origClOrdId
        \o message.price
        \o message.minQty
        \o message.maxFloor
        \o message.leavesQty
        \o message.secondaryOrderId
        \o message.shortSellNakedQty
        \o message.shortSellCoveredQty
        \o message.shortSellLongQty
        \o message.workingPrice
        \o message.baseLiquidityIndicator
        \o message.subLiquidityIndicator
        \o message.expireDate

DecodeOrderModifiedAuEquitiesV2(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET tradingParticipantId == ReadBytes(transactionTime.rest, 2) IN IF ~tradingParticipantId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(tradingParticipantId.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET execInst == ReadBytes(clOrdId.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET orderQty == ReadBytes(execInst.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(orderQty.rest, 20) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET price == ReadBytes(origClOrdId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET minQty == ReadBytes(price.rest, 4) IN IF ~minQty.ok THEN Fail ELSE
    LET maxFloor == ReadBytes(minQty.rest, 4) IN IF ~maxFloor.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(maxFloor.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET secondaryOrderId == ReadBytes(leavesQty.rest, 8) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET shortSellNakedQty == ReadBytes(secondaryOrderId.rest, 4) IN IF ~shortSellNakedQty.ok THEN Fail ELSE
    LET shortSellCoveredQty == ReadBytes(shortSellNakedQty.rest, 4) IN IF ~shortSellCoveredQty.ok THEN Fail ELSE
    LET shortSellLongQty == ReadBytes(shortSellCoveredQty.rest, 4) IN IF ~shortSellLongQty.ok THEN Fail ELSE
    LET workingPrice == ReadBytes(shortSellLongQty.rest, 8) IN IF ~workingPrice.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadBytes(workingPrice.rest, 1) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET subLiquidityIndicator == ReadBytes(baseLiquidityIndicator.rest, 1) IN IF ~subLiquidityIndicator.ok THEN Fail ELSE
    LET expireDate == ReadBytes(subLiquidityIndicator.rest, 4) IN IF ~expireDate.ok THEN Fail ELSE
    Ok([ transactionTime        |-> transactionTime.value,
         tradingParticipantId   |-> tradingParticipantId.value,
         clOrdId                |-> clOrdId.value,
         execInst               |-> execInst.value,
         orderQty               |-> orderQty.value,
         origClOrdId            |-> origClOrdId.value,
         price                  |-> price.value,
         minQty                 |-> minQty.value,
         maxFloor               |-> maxFloor.value,
         leavesQty              |-> leavesQty.value,
         secondaryOrderId       |-> secondaryOrderId.value,
         shortSellNakedQty      |-> shortSellNakedQty.value,
         shortSellCoveredQty    |-> shortSellCoveredQty.value,
         shortSellLongQty       |-> shortSellLongQty.value,
         workingPrice           |-> workingPrice.value,
         baseLiquidityIndicator |-> baseLiquidityIndicator.value,
         subLiquidityIndicator  |-> subLiquidityIndicator.value,
         expireDate             |-> expireDate.value ], expireDate.rest)

ZeroOrderModifiedAuEquitiesV2 ==
    [ transactionTime        |-> [i \in 1 .. 8 |-> 0],
      tradingParticipantId   |-> [i \in 1 .. 2 |-> 0],
      clOrdId                |-> [i \in 1 .. 20 |-> 0],
      execInst               |-> [i \in 1 .. 1 |-> 0],
      orderQty               |-> [i \in 1 .. 4 |-> 0],
      origClOrdId            |-> [i \in 1 .. 20 |-> 0],
      price                  |-> [i \in 1 .. 8 |-> 0],
      minQty                 |-> [i \in 1 .. 4 |-> 0],
      maxFloor               |-> [i \in 1 .. 4 |-> 0],
      leavesQty              |-> [i \in 1 .. 4 |-> 0],
      secondaryOrderId       |-> [i \in 1 .. 8 |-> 0],
      shortSellNakedQty      |-> [i \in 1 .. 4 |-> 0],
      shortSellCoveredQty    |-> [i \in 1 .. 4 |-> 0],
      shortSellLongQty       |-> [i \in 1 .. 4 |-> 0],
      workingPrice           |-> [i \in 1 .. 8 |-> 0],
      baseLiquidityIndicator |-> [i \in 1 .. 1 |-> 0],
      subLiquidityIndicator  |-> [i \in 1 .. 1 |-> 0],
      expireDate             |-> [i \in 1 .. 4 |-> 0] ]

(* Order Modified Au Equities V 2 at zero, then each field in turn at the values it is checked at *)
CheckedOrderModifiedAuEquitiesV2 ==
    { ZeroOrderModifiedAuEquitiesV2 }
        \cup { [ZeroOrderModifiedAuEquitiesV2 EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifiedAuEquitiesV2 EXCEPT !.tradingParticipantId = one] : one \in Sample(2) }
        \cup { [ZeroOrderModifiedAuEquitiesV2 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderModifiedAuEquitiesV2 EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifiedAuEquitiesV2 EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifiedAuEquitiesV2 EXCEPT !.origClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderModifiedAuEquitiesV2 EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifiedAuEquitiesV2 EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifiedAuEquitiesV2 EXCEPT !.maxFloor = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifiedAuEquitiesV2 EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifiedAuEquitiesV2 EXCEPT !.secondaryOrderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifiedAuEquitiesV2 EXCEPT !.shortSellNakedQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifiedAuEquitiesV2 EXCEPT !.shortSellCoveredQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifiedAuEquitiesV2 EXCEPT !.shortSellLongQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifiedAuEquitiesV2 EXCEPT !.workingPrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifiedAuEquitiesV2 EXCEPT !.baseLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifiedAuEquitiesV2 EXCEPT !.subLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifiedAuEquitiesV2 EXCEPT !.expireDate = one] : one \in Sample(4) }

(***************************************************************************)
(* Carried Restatement Au Equities V 1: 182 bytes                          *)
(***************************************************************************)

CarriedRestatementAuEquitiesV1 ==
    [ transactionTime            : Sample(8),
      account                    : Sample(10),
      tradingParticipantId       : Sample(2),
      clOrdId                    : Sample(20),
      execInst                   : Sample(1),
      orderId                    : Sample(8),
      orderQty                   : Sample(4),
      ordType                    : Sample(1),
      price                      : Sample(8),
      capacity                   : Sample(1),
      side                       : Sample(1),
      symbol                     : Sample(6),
      timeInForce                : Sample(1),
      minQty                     : Sample(4),
      maxFloor                   : Sample(4),
      expireTime                 : Sample(8),
      clearingParticipantId      : Sample(4),
      clearingAccount            : Sample(10),
      undisclosed                : Sample(1),
      clientCrossRef             : Sample(15),
      shortSellNakedQty          : Sample(4),
      shortSellCoveredQty        : Sample(4),
      shortSellLongQty           : Sample(4),
      riskGroupId                : Sample(2),
      noTradeFeat                : Sample(1),
      noTradeKey                 : Sample(10),
      meqse                      : Sample(1),
      originOfTrans              : Sample(20),
      intermediaryId             : Sample(10),
      directedWholesaleIndicator : Sample(1),
      removeCrossingFromClearing : Sample(1),
      brokerPreferencing         : Sample(1),
      routingInst                : Sample(1),
      displayIndicator           : Sample(1),
      expireDate                 : Sample(4) ]

EncodeCarriedRestatementAuEquitiesV1(message) ==
    message.transactionTime
        \o message.account
        \o message.tradingParticipantId
        \o message.clOrdId
        \o message.execInst
        \o message.orderId
        \o message.orderQty
        \o message.ordType
        \o message.price
        \o message.capacity
        \o message.side
        \o message.symbol
        \o message.timeInForce
        \o message.minQty
        \o message.maxFloor
        \o message.expireTime
        \o message.clearingParticipantId
        \o message.clearingAccount
        \o message.undisclosed
        \o message.clientCrossRef
        \o message.shortSellNakedQty
        \o message.shortSellCoveredQty
        \o message.shortSellLongQty
        \o message.riskGroupId
        \o message.noTradeFeat
        \o message.noTradeKey
        \o message.meqse
        \o message.originOfTrans
        \o message.intermediaryId
        \o message.directedWholesaleIndicator
        \o message.removeCrossingFromClearing
        \o message.brokerPreferencing
        \o message.routingInst
        \o message.displayIndicator
        \o message.expireDate

DecodeCarriedRestatementAuEquitiesV1(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET account == ReadBytes(transactionTime.rest, 10) IN IF ~account.ok THEN Fail ELSE
    LET tradingParticipantId == ReadBytes(account.rest, 2) IN IF ~tradingParticipantId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(tradingParticipantId.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET execInst == ReadBytes(clOrdId.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET orderId == ReadBytes(execInst.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(orderId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET ordType == ReadBytes(orderQty.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET price == ReadBytes(ordType.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET capacity == ReadBytes(price.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET side == ReadBytes(capacity.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET symbol == ReadBytes(side.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(symbol.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadBytes(timeInForce.rest, 4) IN IF ~minQty.ok THEN Fail ELSE
    LET maxFloor == ReadBytes(minQty.rest, 4) IN IF ~maxFloor.ok THEN Fail ELSE
    LET expireTime == ReadBytes(maxFloor.rest, 8) IN IF ~expireTime.ok THEN Fail ELSE
    LET clearingParticipantId == ReadBytes(expireTime.rest, 4) IN IF ~clearingParticipantId.ok THEN Fail ELSE
    LET clearingAccount == ReadBytes(clearingParticipantId.rest, 10) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET undisclosed == ReadBytes(clearingAccount.rest, 1) IN IF ~undisclosed.ok THEN Fail ELSE
    LET clientCrossRef == ReadBytes(undisclosed.rest, 15) IN IF ~clientCrossRef.ok THEN Fail ELSE
    LET shortSellNakedQty == ReadBytes(clientCrossRef.rest, 4) IN IF ~shortSellNakedQty.ok THEN Fail ELSE
    LET shortSellCoveredQty == ReadBytes(shortSellNakedQty.rest, 4) IN IF ~shortSellCoveredQty.ok THEN Fail ELSE
    LET shortSellLongQty == ReadBytes(shortSellCoveredQty.rest, 4) IN IF ~shortSellLongQty.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(shortSellLongQty.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET noTradeFeat == ReadBytes(riskGroupId.rest, 1) IN IF ~noTradeFeat.ok THEN Fail ELSE
    LET noTradeKey == ReadBytes(noTradeFeat.rest, 10) IN IF ~noTradeKey.ok THEN Fail ELSE
    LET meqse == ReadBytes(noTradeKey.rest, 1) IN IF ~meqse.ok THEN Fail ELSE
    LET originOfTrans == ReadBytes(meqse.rest, 20) IN IF ~originOfTrans.ok THEN Fail ELSE
    LET intermediaryId == ReadBytes(originOfTrans.rest, 10) IN IF ~intermediaryId.ok THEN Fail ELSE
    LET directedWholesaleIndicator == ReadBytes(intermediaryId.rest, 1) IN IF ~directedWholesaleIndicator.ok THEN Fail ELSE
    LET removeCrossingFromClearing == ReadBytes(directedWholesaleIndicator.rest, 1) IN IF ~removeCrossingFromClearing.ok THEN Fail ELSE
    LET brokerPreferencing == ReadBytes(removeCrossingFromClearing.rest, 1) IN IF ~brokerPreferencing.ok THEN Fail ELSE
    LET routingInst == ReadBytes(brokerPreferencing.rest, 1) IN IF ~routingInst.ok THEN Fail ELSE
    LET displayIndicator == ReadBytes(routingInst.rest, 1) IN IF ~displayIndicator.ok THEN Fail ELSE
    LET expireDate == ReadBytes(displayIndicator.rest, 4) IN IF ~expireDate.ok THEN Fail ELSE
    Ok([ transactionTime            |-> transactionTime.value,
         account                    |-> account.value,
         tradingParticipantId       |-> tradingParticipantId.value,
         clOrdId                    |-> clOrdId.value,
         execInst                   |-> execInst.value,
         orderId                    |-> orderId.value,
         orderQty                   |-> orderQty.value,
         ordType                    |-> ordType.value,
         price                      |-> price.value,
         capacity                   |-> capacity.value,
         side                       |-> side.value,
         symbol                     |-> symbol.value,
         timeInForce                |-> timeInForce.value,
         minQty                     |-> minQty.value,
         maxFloor                   |-> maxFloor.value,
         expireTime                 |-> expireTime.value,
         clearingParticipantId      |-> clearingParticipantId.value,
         clearingAccount            |-> clearingAccount.value,
         undisclosed                |-> undisclosed.value,
         clientCrossRef             |-> clientCrossRef.value,
         shortSellNakedQty          |-> shortSellNakedQty.value,
         shortSellCoveredQty        |-> shortSellCoveredQty.value,
         shortSellLongQty           |-> shortSellLongQty.value,
         riskGroupId                |-> riskGroupId.value,
         noTradeFeat                |-> noTradeFeat.value,
         noTradeKey                 |-> noTradeKey.value,
         meqse                      |-> meqse.value,
         originOfTrans              |-> originOfTrans.value,
         intermediaryId             |-> intermediaryId.value,
         directedWholesaleIndicator |-> directedWholesaleIndicator.value,
         removeCrossingFromClearing |-> removeCrossingFromClearing.value,
         brokerPreferencing         |-> brokerPreferencing.value,
         routingInst                |-> routingInst.value,
         displayIndicator           |-> displayIndicator.value,
         expireDate                 |-> expireDate.value ], expireDate.rest)

ZeroCarriedRestatementAuEquitiesV1 ==
    [ transactionTime            |-> [i \in 1 .. 8 |-> 0],
      account                    |-> [i \in 1 .. 10 |-> 0],
      tradingParticipantId       |-> [i \in 1 .. 2 |-> 0],
      clOrdId                    |-> [i \in 1 .. 20 |-> 0],
      execInst                   |-> [i \in 1 .. 1 |-> 0],
      orderId                    |-> [i \in 1 .. 8 |-> 0],
      orderQty                   |-> [i \in 1 .. 4 |-> 0],
      ordType                    |-> [i \in 1 .. 1 |-> 0],
      price                      |-> [i \in 1 .. 8 |-> 0],
      capacity                   |-> [i \in 1 .. 1 |-> 0],
      side                       |-> [i \in 1 .. 1 |-> 0],
      symbol                     |-> [i \in 1 .. 6 |-> 0],
      timeInForce                |-> [i \in 1 .. 1 |-> 0],
      minQty                     |-> [i \in 1 .. 4 |-> 0],
      maxFloor                   |-> [i \in 1 .. 4 |-> 0],
      expireTime                 |-> [i \in 1 .. 8 |-> 0],
      clearingParticipantId      |-> [i \in 1 .. 4 |-> 0],
      clearingAccount            |-> [i \in 1 .. 10 |-> 0],
      undisclosed                |-> [i \in 1 .. 1 |-> 0],
      clientCrossRef             |-> [i \in 1 .. 15 |-> 0],
      shortSellNakedQty          |-> [i \in 1 .. 4 |-> 0],
      shortSellCoveredQty        |-> [i \in 1 .. 4 |-> 0],
      shortSellLongQty           |-> [i \in 1 .. 4 |-> 0],
      riskGroupId                |-> [i \in 1 .. 2 |-> 0],
      noTradeFeat                |-> [i \in 1 .. 1 |-> 0],
      noTradeKey                 |-> [i \in 1 .. 10 |-> 0],
      meqse                      |-> [i \in 1 .. 1 |-> 0],
      originOfTrans              |-> [i \in 1 .. 20 |-> 0],
      intermediaryId             |-> [i \in 1 .. 10 |-> 0],
      directedWholesaleIndicator |-> [i \in 1 .. 1 |-> 0],
      removeCrossingFromClearing |-> [i \in 1 .. 1 |-> 0],
      brokerPreferencing         |-> [i \in 1 .. 1 |-> 0],
      routingInst                |-> [i \in 1 .. 1 |-> 0],
      displayIndicator           |-> [i \in 1 .. 1 |-> 0],
      expireDate                 |-> [i \in 1 .. 4 |-> 0] ]

(* Carried Restatement Au Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedCarriedRestatementAuEquitiesV1 ==
    { ZeroCarriedRestatementAuEquitiesV1 }
        \cup { [ZeroCarriedRestatementAuEquitiesV1 EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroCarriedRestatementAuEquitiesV1 EXCEPT !.account = one] : one \in Sample(10) }
        \cup { [ZeroCarriedRestatementAuEquitiesV1 EXCEPT !.tradingParticipantId = one] : one \in Sample(2) }
        \cup { [ZeroCarriedRestatementAuEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroCarriedRestatementAuEquitiesV1 EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementAuEquitiesV1 EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroCarriedRestatementAuEquitiesV1 EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroCarriedRestatementAuEquitiesV1 EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementAuEquitiesV1 EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroCarriedRestatementAuEquitiesV1 EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementAuEquitiesV1 EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementAuEquitiesV1 EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroCarriedRestatementAuEquitiesV1 EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementAuEquitiesV1 EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroCarriedRestatementAuEquitiesV1 EXCEPT !.maxFloor = one] : one \in Sample(4) }
        \cup { [ZeroCarriedRestatementAuEquitiesV1 EXCEPT !.expireTime = one] : one \in Sample(8) }
        \cup { [ZeroCarriedRestatementAuEquitiesV1 EXCEPT !.clearingParticipantId = one] : one \in Sample(4) }
        \cup { [ZeroCarriedRestatementAuEquitiesV1 EXCEPT !.clearingAccount = one] : one \in Sample(10) }
        \cup { [ZeroCarriedRestatementAuEquitiesV1 EXCEPT !.undisclosed = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementAuEquitiesV1 EXCEPT !.clientCrossRef = one] : one \in Sample(15) }
        \cup { [ZeroCarriedRestatementAuEquitiesV1 EXCEPT !.shortSellNakedQty = one] : one \in Sample(4) }
        \cup { [ZeroCarriedRestatementAuEquitiesV1 EXCEPT !.shortSellCoveredQty = one] : one \in Sample(4) }
        \cup { [ZeroCarriedRestatementAuEquitiesV1 EXCEPT !.shortSellLongQty = one] : one \in Sample(4) }
        \cup { [ZeroCarriedRestatementAuEquitiesV1 EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroCarriedRestatementAuEquitiesV1 EXCEPT !.noTradeFeat = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementAuEquitiesV1 EXCEPT !.noTradeKey = one] : one \in Sample(10) }
        \cup { [ZeroCarriedRestatementAuEquitiesV1 EXCEPT !.meqse = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementAuEquitiesV1 EXCEPT !.originOfTrans = one] : one \in Sample(20) }
        \cup { [ZeroCarriedRestatementAuEquitiesV1 EXCEPT !.intermediaryId = one] : one \in Sample(10) }
        \cup { [ZeroCarriedRestatementAuEquitiesV1 EXCEPT !.directedWholesaleIndicator = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementAuEquitiesV1 EXCEPT !.removeCrossingFromClearing = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementAuEquitiesV1 EXCEPT !.brokerPreferencing = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementAuEquitiesV1 EXCEPT !.routingInst = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementAuEquitiesV1 EXCEPT !.displayIndicator = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementAuEquitiesV1 EXCEPT !.expireDate = one] : one \in Sample(4) }

(***************************************************************************)
(* Done For Day Au Equities V 1: 34 bytes                                  *)
(***************************************************************************)

DoneForDayAuEquitiesV1 ==
    [ transactionTime : Sample(8),
      clOrdId         : Sample(20),
      symbol          : Sample(6) ]

EncodeDoneForDayAuEquitiesV1(message) ==
    message.transactionTime
        \o message.clOrdId
        \o message.symbol

DecodeDoneForDayAuEquitiesV1(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET symbol == ReadBytes(clOrdId.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    Ok([ transactionTime |-> transactionTime.value,
         clOrdId         |-> clOrdId.value,
         symbol          |-> symbol.value ], symbol.rest)

ZeroDoneForDayAuEquitiesV1 ==
    [ transactionTime |-> [i \in 1 .. 8 |-> 0],
      clOrdId         |-> [i \in 1 .. 20 |-> 0],
      symbol          |-> [i \in 1 .. 6 |-> 0] ]

(* Done For Day Au Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedDoneForDayAuEquitiesV1 ==
    { ZeroDoneForDayAuEquitiesV1 }
        \cup { [ZeroDoneForDayAuEquitiesV1 EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroDoneForDayAuEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroDoneForDayAuEquitiesV1 EXCEPT !.symbol = one] : one \in Sample(6) }

(***************************************************************************)
(* Exchange Message, selected by Exchange Message Type                     *)
(***************************************************************************)

LoginResponseMessageCode == 501  \* 0x1f5
ReplayCompleteCode == 502  \* 0x1f6
LogoutResponseMessageCode == 503  \* 0x1f7
ServerHeartbeatCode == 504  \* 0x1f8
OrderAcknowledgementAuEquitiesV1Code == 3501  \* 0xdad
OrderRejectedAuEquitiesV1Code == 3502  \* 0xdae
OrderModifiedAuEquitiesV1Code == 3503  \* 0xdaf
ModifyRejectedAuEquitiesV1Code == 3504  \* 0xdb0
OrderRestatedAuEquitiesV1Code == 3505  \* 0xdb1
OrderExecutionAuEquitiesV1Code == 3506  \* 0xdb2
OrderCancelledAuEquitiesV1Code == 3507  \* 0xdb3
CancelRejectedAuEquitiesV1Code == 3508  \* 0xdb4
ExecutionRestatementAuEquitiesV1Code == 3509  \* 0xdb5
PurgeAcknowledgementAuEquitiesV1Code == 3510  \* 0xdb6
PurgeRejectedAuEquitiesV1Code == 3511  \* 0xdb7
TradeCancelCorrectAuEquitiesV1Code == 3512  \* 0xdb8
OrderModifiedAuEquitiesV2Code == 3513  \* 0xdb9
CarriedRestatementAuEquitiesV1Code == 3514  \* 0xdba
DoneForDayAuEquitiesV1Code == 3515  \* 0xdbb

ExchangeMessage ==
    [ tag : {LoginResponseMessageCode}, body : LoginResponseMessage ]
        \cup [ tag : {ReplayCompleteCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {LogoutResponseMessageCode}, body : LogoutResponseMessage ]
        \cup [ tag : {ServerHeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {OrderAcknowledgementAuEquitiesV1Code}, body : OrderAcknowledgementAuEquitiesV1 ]
        \cup [ tag : {OrderRejectedAuEquitiesV1Code}, body : OrderRejectedAuEquitiesV1 ]
        \cup [ tag : {OrderModifiedAuEquitiesV1Code}, body : OrderModifiedAuEquitiesV1 ]
        \cup [ tag : {ModifyRejectedAuEquitiesV1Code}, body : ModifyRejectedAuEquitiesV1 ]
        \cup [ tag : {OrderRestatedAuEquitiesV1Code}, body : OrderRestatedAuEquitiesV1 ]
        \cup [ tag : {OrderExecutionAuEquitiesV1Code}, body : OrderExecutionAuEquitiesV1 ]
        \cup [ tag : {OrderCancelledAuEquitiesV1Code}, body : OrderCancelledAuEquitiesV1 ]
        \cup [ tag : {CancelRejectedAuEquitiesV1Code}, body : CancelRejectedAuEquitiesV1 ]
        \cup [ tag : {ExecutionRestatementAuEquitiesV1Code}, body : ExecutionRestatementAuEquitiesV1 ]
        \cup [ tag : {PurgeAcknowledgementAuEquitiesV1Code}, body : PurgeAcknowledgementAuEquitiesV1 ]
        \cup [ tag : {PurgeRejectedAuEquitiesV1Code}, body : PurgeRejectedAuEquitiesV1 ]
        \cup [ tag : {TradeCancelCorrectAuEquitiesV1Code}, body : TradeCancelCorrectAuEquitiesV1 ]
        \cup [ tag : {OrderModifiedAuEquitiesV2Code}, body : OrderModifiedAuEquitiesV2 ]
        \cup [ tag : {CarriedRestatementAuEquitiesV1Code}, body : CarriedRestatementAuEquitiesV1 ]
        \cup [ tag : {DoneForDayAuEquitiesV1Code}, body : DoneForDayAuEquitiesV1 ]

EncodeExchangeMessage(message) ==
    CASE message.tag = LoginResponseMessageCode -> EncodeLoginResponseMessage(message.body)
      [] message.tag = ReplayCompleteCode -> << >>
      [] message.tag = LogoutResponseMessageCode -> EncodeLogoutResponseMessage(message.body)
      [] message.tag = ServerHeartbeatCode -> << >>
      [] message.tag = OrderAcknowledgementAuEquitiesV1Code -> EncodeOrderAcknowledgementAuEquitiesV1(message.body)
      [] message.tag = OrderRejectedAuEquitiesV1Code -> EncodeOrderRejectedAuEquitiesV1(message.body)
      [] message.tag = OrderModifiedAuEquitiesV1Code -> EncodeOrderModifiedAuEquitiesV1(message.body)
      [] message.tag = ModifyRejectedAuEquitiesV1Code -> EncodeModifyRejectedAuEquitiesV1(message.body)
      [] message.tag = OrderRestatedAuEquitiesV1Code -> EncodeOrderRestatedAuEquitiesV1(message.body)
      [] message.tag = OrderExecutionAuEquitiesV1Code -> EncodeOrderExecutionAuEquitiesV1(message.body)
      [] message.tag = OrderCancelledAuEquitiesV1Code -> EncodeOrderCancelledAuEquitiesV1(message.body)
      [] message.tag = CancelRejectedAuEquitiesV1Code -> EncodeCancelRejectedAuEquitiesV1(message.body)
      [] message.tag = ExecutionRestatementAuEquitiesV1Code -> EncodeExecutionRestatementAuEquitiesV1(message.body)
      [] message.tag = PurgeAcknowledgementAuEquitiesV1Code -> EncodePurgeAcknowledgementAuEquitiesV1(message.body)
      [] message.tag = PurgeRejectedAuEquitiesV1Code -> EncodePurgeRejectedAuEquitiesV1(message.body)
      [] message.tag = TradeCancelCorrectAuEquitiesV1Code -> EncodeTradeCancelCorrectAuEquitiesV1(message.body)
      [] message.tag = OrderModifiedAuEquitiesV2Code -> EncodeOrderModifiedAuEquitiesV2(message.body)
      [] message.tag = CarriedRestatementAuEquitiesV1Code -> EncodeCarriedRestatementAuEquitiesV1(message.body)
      [] message.tag = DoneForDayAuEquitiesV1Code -> EncodeDoneForDayAuEquitiesV1(message.body)

DecodeExchangeMessage(tag, bytes) ==
    LET read ==
            CASE tag = LoginResponseMessageCode -> DecodeLoginResponseMessage(bytes)
              [] tag = ReplayCompleteCode -> Ok([empty |-> 0], bytes)
              [] tag = LogoutResponseMessageCode -> DecodeLogoutResponseMessage(bytes)
              [] tag = ServerHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = OrderAcknowledgementAuEquitiesV1Code -> DecodeOrderAcknowledgementAuEquitiesV1(bytes)
              [] tag = OrderRejectedAuEquitiesV1Code -> DecodeOrderRejectedAuEquitiesV1(bytes)
              [] tag = OrderModifiedAuEquitiesV1Code -> DecodeOrderModifiedAuEquitiesV1(bytes)
              [] tag = ModifyRejectedAuEquitiesV1Code -> DecodeModifyRejectedAuEquitiesV1(bytes)
              [] tag = OrderRestatedAuEquitiesV1Code -> DecodeOrderRestatedAuEquitiesV1(bytes)
              [] tag = OrderExecutionAuEquitiesV1Code -> DecodeOrderExecutionAuEquitiesV1(bytes)
              [] tag = OrderCancelledAuEquitiesV1Code -> DecodeOrderCancelledAuEquitiesV1(bytes)
              [] tag = CancelRejectedAuEquitiesV1Code -> DecodeCancelRejectedAuEquitiesV1(bytes)
              [] tag = ExecutionRestatementAuEquitiesV1Code -> DecodeExecutionRestatementAuEquitiesV1(bytes)
              [] tag = PurgeAcknowledgementAuEquitiesV1Code -> DecodePurgeAcknowledgementAuEquitiesV1(bytes)
              [] tag = PurgeRejectedAuEquitiesV1Code -> DecodePurgeRejectedAuEquitiesV1(bytes)
              [] tag = TradeCancelCorrectAuEquitiesV1Code -> DecodeTradeCancelCorrectAuEquitiesV1(bytes)
              [] tag = OrderModifiedAuEquitiesV2Code -> DecodeOrderModifiedAuEquitiesV2(bytes)
              [] tag = CarriedRestatementAuEquitiesV1Code -> DecodeCarriedRestatementAuEquitiesV1(bytes)
              [] tag = DoneForDayAuEquitiesV1Code -> DecodeDoneForDayAuEquitiesV1(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroExchangeMessage == [tag |-> LoginResponseMessageCode, body |-> ZeroLoginResponseMessage]

(* Each Exchange Message in turn, at the values the message it names is checked at *)
CheckedExchangeMessage ==
    { [tag |-> LoginResponseMessageCode, body |-> one] : one \in CheckedLoginResponseMessage }
        \cup { [tag |-> ReplayCompleteCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> LogoutResponseMessageCode, body |-> one] : one \in CheckedLogoutResponseMessage }
        \cup { [tag |-> ServerHeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> OrderAcknowledgementAuEquitiesV1Code, body |-> one] : one \in CheckedOrderAcknowledgementAuEquitiesV1 }
        \cup { [tag |-> OrderRejectedAuEquitiesV1Code, body |-> one] : one \in CheckedOrderRejectedAuEquitiesV1 }
        \cup { [tag |-> OrderModifiedAuEquitiesV1Code, body |-> one] : one \in CheckedOrderModifiedAuEquitiesV1 }
        \cup { [tag |-> ModifyRejectedAuEquitiesV1Code, body |-> one] : one \in CheckedModifyRejectedAuEquitiesV1 }
        \cup { [tag |-> OrderRestatedAuEquitiesV1Code, body |-> one] : one \in CheckedOrderRestatedAuEquitiesV1 }
        \cup { [tag |-> OrderExecutionAuEquitiesV1Code, body |-> one] : one \in CheckedOrderExecutionAuEquitiesV1 }
        \cup { [tag |-> OrderCancelledAuEquitiesV1Code, body |-> one] : one \in CheckedOrderCancelledAuEquitiesV1 }
        \cup { [tag |-> CancelRejectedAuEquitiesV1Code, body |-> one] : one \in CheckedCancelRejectedAuEquitiesV1 }
        \cup { [tag |-> ExecutionRestatementAuEquitiesV1Code, body |-> one] : one \in CheckedExecutionRestatementAuEquitiesV1 }
        \cup { [tag |-> PurgeAcknowledgementAuEquitiesV1Code, body |-> one] : one \in CheckedPurgeAcknowledgementAuEquitiesV1 }
        \cup { [tag |-> PurgeRejectedAuEquitiesV1Code, body |-> one] : one \in CheckedPurgeRejectedAuEquitiesV1 }
        \cup { [tag |-> TradeCancelCorrectAuEquitiesV1Code, body |-> one] : one \in CheckedTradeCancelCorrectAuEquitiesV1 }
        \cup { [tag |-> OrderModifiedAuEquitiesV2Code, body |-> one] : one \in CheckedOrderModifiedAuEquitiesV2 }
        \cup { [tag |-> CarriedRestatementAuEquitiesV1Code, body |-> one] : one \in CheckedCarriedRestatementAuEquitiesV1 }
        \cup { [tag |-> DoneForDayAuEquitiesV1Code, body |-> one] : one \in CheckedDoneForDayAuEquitiesV1 }

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

(* Every Order Acknowledgement Au Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderAcknowledgementAuEquitiesV1 ==
    \A message \in CheckedOrderAcknowledgementAuEquitiesV1 :
        LET read == DecodeOrderAcknowledgementAuEquitiesV1(EncodeOrderAcknowledgementAuEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Rejected Au Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderRejectedAuEquitiesV1 ==
    \A message \in CheckedOrderRejectedAuEquitiesV1 :
        LET read == DecodeOrderRejectedAuEquitiesV1(EncodeOrderRejectedAuEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Modified Au Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderModifiedAuEquitiesV1 ==
    \A message \in CheckedOrderModifiedAuEquitiesV1 :
        LET read == DecodeOrderModifiedAuEquitiesV1(EncodeOrderModifiedAuEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Rejected Au Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyRejectedAuEquitiesV1 ==
    \A message \in CheckedModifyRejectedAuEquitiesV1 :
        LET read == DecodeModifyRejectedAuEquitiesV1(EncodeModifyRejectedAuEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Restated Au Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderRestatedAuEquitiesV1 ==
    \A message \in CheckedOrderRestatedAuEquitiesV1 :
        LET read == DecodeOrderRestatedAuEquitiesV1(EncodeOrderRestatedAuEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Execution Au Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutionAuEquitiesV1 ==
    \A message \in CheckedOrderExecutionAuEquitiesV1 :
        LET read == DecodeOrderExecutionAuEquitiesV1(EncodeOrderExecutionAuEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancelled Au Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelledAuEquitiesV1 ==
    \A message \in CheckedOrderCancelledAuEquitiesV1 :
        LET read == DecodeOrderCancelledAuEquitiesV1(EncodeOrderCancelledAuEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Rejected Au Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelRejectedAuEquitiesV1 ==
    \A message \in CheckedCancelRejectedAuEquitiesV1 :
        LET read == DecodeCancelRejectedAuEquitiesV1(EncodeCancelRejectedAuEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Restatement Au Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionRestatementAuEquitiesV1 ==
    \A message \in CheckedExecutionRestatementAuEquitiesV1 :
        LET read == DecodeExecutionRestatementAuEquitiesV1(EncodeExecutionRestatementAuEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Purge Acknowledgement Au Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripPurgeAcknowledgementAuEquitiesV1 ==
    \A message \in CheckedPurgeAcknowledgementAuEquitiesV1 :
        LET read == DecodePurgeAcknowledgementAuEquitiesV1(EncodePurgeAcknowledgementAuEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Purge Rejected Au Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripPurgeRejectedAuEquitiesV1 ==
    \A message \in CheckedPurgeRejectedAuEquitiesV1 :
        LET read == DecodePurgeRejectedAuEquitiesV1(EncodePurgeRejectedAuEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Cancel Correct Au Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCancelCorrectAuEquitiesV1 ==
    \A message \in CheckedTradeCancelCorrectAuEquitiesV1 :
        LET read == DecodeTradeCancelCorrectAuEquitiesV1(EncodeTradeCancelCorrectAuEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Modified Au Equities V 2 decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderModifiedAuEquitiesV2 ==
    \A message \in CheckedOrderModifiedAuEquitiesV2 :
        LET read == DecodeOrderModifiedAuEquitiesV2(EncodeOrderModifiedAuEquitiesV2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Carried Restatement Au Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripCarriedRestatementAuEquitiesV1 ==
    \A message \in CheckedCarriedRestatementAuEquitiesV1 :
        LET read == DecodeCarriedRestatementAuEquitiesV1(EncodeCarriedRestatementAuEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Done For Day Au Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripDoneForDayAuEquitiesV1 ==
    \A message \in CheckedDoneForDayAuEquitiesV1 :
        LET read == DecodeDoneForDayAuEquitiesV1(EncodeDoneForDayAuEquitiesV1(message))
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
