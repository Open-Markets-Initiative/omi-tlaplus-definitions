---------------- MODULE NeoEquities_OrderEntry_v1_0_19_Firm ----------------
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
(* Login Request Message                                                   *)
(***************************************************************************)

LoginRequestMessage ==
    [ sessionId             : Sample(4),
      sessionSubId          : Sample(4),
      password              : Sample(10),
      replayUnspecifiedUnit : Sample(1),
      unitSequence          : SampleLists(OneUnitSequence) ]

EncodeLoginRequestMessage(message) ==
    message.sessionId
        \o message.sessionSubId
        \o message.password
        \o message.replayUnspecifiedUnit
        \o EncodeUIntLE(Len(message.unitSequence), 1)
        \o EncodeUnitSequenceList(message.unitSequence)

DecodeLoginRequestMessage(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET sessionSubId == ReadBytes(sessionId.rest, 4) IN IF ~sessionSubId.ok THEN Fail ELSE
    LET password == ReadBytes(sessionSubId.rest, 10) IN IF ~password.ok THEN Fail ELSE
    LET replayUnspecifiedUnit == ReadBytes(password.rest, 1) IN IF ~replayUnspecifiedUnit.ok THEN Fail ELSE
    LET numberOfUnits == ReadUIntLE(replayUnspecifiedUnit.rest, 1) IN IF ~numberOfUnits.ok THEN Fail ELSE
    LET unitSequence == ReadUnitSequenceList(numberOfUnits.rest, numberOfUnits.value) IN IF ~unitSequence.ok THEN Fail ELSE
    Ok([ sessionId             |-> sessionId.value,
         sessionSubId          |-> sessionSubId.value,
         password              |-> password.value,
         replayUnspecifiedUnit |-> replayUnspecifiedUnit.value,
         unitSequence          |-> unitSequence.value ], unitSequence.rest)

ZeroLoginRequestMessage ==
    [ sessionId             |-> [i \in 1 .. 4 |-> 0],
      sessionSubId          |-> [i \in 1 .. 4 |-> 0],
      password              |-> [i \in 1 .. 10 |-> 0],
      replayUnspecifiedUnit |-> [i \in 1 .. 1 |-> 0],
      unitSequence          |-> << >> ]

(* Login Request Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginRequestMessage ==
    { ZeroLoginRequestMessage }
        \cup { [ZeroLoginRequestMessage EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroLoginRequestMessage EXCEPT !.sessionSubId = one] : one \in Sample(4) }
        \cup { [ZeroLoginRequestMessage EXCEPT !.password = one] : one \in Sample(10) }
        \cup { [ZeroLoginRequestMessage EXCEPT !.replayUnspecifiedUnit = one] : one \in Sample(1) }
        \cup { [ZeroLoginRequestMessage EXCEPT !.unitSequence = one] : one \in SampleLists(OneUnitSequence) }

(***************************************************************************)
(* New Order Ca Equities V 1: 253 bytes                                    *)
(***************************************************************************)

NewOrderCaEquitiesV1 ==
    [ account                        : Sample(16),
      clOrdId                        : Sample(20),
      brokerId                       : Sample(2),
      execInst                       : Sample(1),
      handlingInst                   : Sample(1),
      orderQty                       : Sample(4),
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
      expireTime                     : Sample(8),
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
      noTradeFeat                    : Sample(1),
      noTradeKey                     : Sample(6),
      shortMarkingExempt             : Sample(1),
      leiCustomerAccount             : Sample(20),
      leiAlgorithmId                 : Sample(20),
      customerLei                    : Sample(52),
      brokerLei                      : Sample(20),
      routingInst                    : Sample(1),
      displayIndicator               : Sample(1),
      matchingStateParticipation     : Sample(1),
      trueMinQty                     : Sample(4) ]

EncodeNewOrderCaEquitiesV1(message) ==
    message.account
        \o message.clOrdId
        \o message.brokerId
        \o message.execInst
        \o message.handlingInst
        \o message.orderQty
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
        \o message.expireTime
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
        \o message.noTradeFeat
        \o message.noTradeKey
        \o message.shortMarkingExempt
        \o message.leiCustomerAccount
        \o message.leiAlgorithmId
        \o message.customerLei
        \o message.brokerLei
        \o message.routingInst
        \o message.displayIndicator
        \o message.matchingStateParticipation
        \o message.trueMinQty

DecodeNewOrderCaEquitiesV1(bytes) ==
    LET account == ReadBytes(bytes, 16) IN IF ~account.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(account.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET brokerId == ReadBytes(clOrdId.rest, 2) IN IF ~brokerId.ok THEN Fail ELSE
    LET execInst == ReadBytes(brokerId.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET handlingInst == ReadBytes(execInst.rest, 1) IN IF ~handlingInst.ok THEN Fail ELSE
    LET orderQty == ReadBytes(handlingInst.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET ordType == ReadBytes(orderQty.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET price == ReadBytes(ordType.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET stopPx == ReadBytes(price.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET side == ReadBytes(stopPx.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET symbol == ReadBytes(side.rest, 14) IN IF ~symbol.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(symbol.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET settlementType == ReadBytes(timeInForce.rest, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET futSettlDate == ReadBytes(settlementType.rest, 4) IN IF ~futSettlDate.ok THEN Fail ELSE
    LET exDestination == ReadBytes(futSettlDate.rest, 1) IN IF ~exDestination.ok THEN Fail ELSE
    LET maxFloor == ReadBytes(exDestination.rest, 4) IN IF ~maxFloor.ok THEN Fail ELSE
    LET expireTime == ReadBytes(maxFloor.rest, 8) IN IF ~expireTime.ok THEN Fail ELSE
    LET expireDate == ReadBytes(expireTime.rest, 4) IN IF ~expireDate.ok THEN Fail ELSE
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
    LET noTradeFeat == ReadBytes(ncib.rest, 1) IN IF ~noTradeFeat.ok THEN Fail ELSE
    LET noTradeKey == ReadBytes(noTradeFeat.rest, 6) IN IF ~noTradeKey.ok THEN Fail ELSE
    LET shortMarkingExempt == ReadBytes(noTradeKey.rest, 1) IN IF ~shortMarkingExempt.ok THEN Fail ELSE
    LET leiCustomerAccount == ReadBytes(shortMarkingExempt.rest, 20) IN IF ~leiCustomerAccount.ok THEN Fail ELSE
    LET leiAlgorithmId == ReadBytes(leiCustomerAccount.rest, 20) IN IF ~leiAlgorithmId.ok THEN Fail ELSE
    LET customerLei == ReadBytes(leiAlgorithmId.rest, 52) IN IF ~customerLei.ok THEN Fail ELSE
    LET brokerLei == ReadBytes(customerLei.rest, 20) IN IF ~brokerLei.ok THEN Fail ELSE
    LET routingInst == ReadBytes(brokerLei.rest, 1) IN IF ~routingInst.ok THEN Fail ELSE
    LET displayIndicator == ReadBytes(routingInst.rest, 1) IN IF ~displayIndicator.ok THEN Fail ELSE
    LET matchingStateParticipation == ReadBytes(displayIndicator.rest, 1) IN IF ~matchingStateParticipation.ok THEN Fail ELSE
    LET trueMinQty == ReadBytes(matchingStateParticipation.rest, 4) IN IF ~trueMinQty.ok THEN Fail ELSE
    Ok([ account                        |-> account.value,
         clOrdId                        |-> clOrdId.value,
         brokerId                       |-> brokerId.value,
         execInst                       |-> execInst.value,
         handlingInst                   |-> handlingInst.value,
         orderQty                       |-> orderQty.value,
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
         expireTime                     |-> expireTime.value,
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
         noTradeFeat                    |-> noTradeFeat.value,
         noTradeKey                     |-> noTradeKey.value,
         shortMarkingExempt             |-> shortMarkingExempt.value,
         leiCustomerAccount             |-> leiCustomerAccount.value,
         leiAlgorithmId                 |-> leiAlgorithmId.value,
         customerLei                    |-> customerLei.value,
         brokerLei                      |-> brokerLei.value,
         routingInst                    |-> routingInst.value,
         displayIndicator               |-> displayIndicator.value,
         matchingStateParticipation     |-> matchingStateParticipation.value,
         trueMinQty                     |-> trueMinQty.value ], trueMinQty.rest)

ZeroNewOrderCaEquitiesV1 ==
    [ account                        |-> [i \in 1 .. 16 |-> 0],
      clOrdId                        |-> [i \in 1 .. 20 |-> 0],
      brokerId                       |-> [i \in 1 .. 2 |-> 0],
      execInst                       |-> [i \in 1 .. 1 |-> 0],
      handlingInst                   |-> [i \in 1 .. 1 |-> 0],
      orderQty                       |-> [i \in 1 .. 4 |-> 0],
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
      expireTime                     |-> [i \in 1 .. 8 |-> 0],
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
      noTradeFeat                    |-> [i \in 1 .. 1 |-> 0],
      noTradeKey                     |-> [i \in 1 .. 6 |-> 0],
      shortMarkingExempt             |-> [i \in 1 .. 1 |-> 0],
      leiCustomerAccount             |-> [i \in 1 .. 20 |-> 0],
      leiAlgorithmId                 |-> [i \in 1 .. 20 |-> 0],
      customerLei                    |-> [i \in 1 .. 52 |-> 0],
      brokerLei                      |-> [i \in 1 .. 20 |-> 0],
      routingInst                    |-> [i \in 1 .. 1 |-> 0],
      displayIndicator               |-> [i \in 1 .. 1 |-> 0],
      matchingStateParticipation     |-> [i \in 1 .. 1 |-> 0],
      trueMinQty                     |-> [i \in 1 .. 4 |-> 0] ]

(* New Order Ca Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderCaEquitiesV1 ==
    { ZeroNewOrderCaEquitiesV1 }
        \cup { [ZeroNewOrderCaEquitiesV1 EXCEPT !.account = one] : one \in Sample(16) }
        \cup { [ZeroNewOrderCaEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderCaEquitiesV1 EXCEPT !.brokerId = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderCaEquitiesV1 EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCaEquitiesV1 EXCEPT !.handlingInst = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCaEquitiesV1 EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderCaEquitiesV1 EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCaEquitiesV1 EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderCaEquitiesV1 EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderCaEquitiesV1 EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCaEquitiesV1 EXCEPT !.symbol = one] : one \in Sample(14) }
        \cup { [ZeroNewOrderCaEquitiesV1 EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCaEquitiesV1 EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCaEquitiesV1 EXCEPT !.futSettlDate = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderCaEquitiesV1 EXCEPT !.exDestination = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCaEquitiesV1 EXCEPT !.maxFloor = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderCaEquitiesV1 EXCEPT !.expireTime = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderCaEquitiesV1 EXCEPT !.expireDate = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderCaEquitiesV1 EXCEPT !.leiOrderOrigin = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCaEquitiesV1 EXCEPT !.leiRoutingArrangementIndicator = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCaEquitiesV1 EXCEPT !.umirAccountType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCaEquitiesV1 EXCEPT !.umirUserId = one] : one \in Sample(12) }
        \cup { [ZeroNewOrderCaEquitiesV1 EXCEPT !.basketTrade = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderCaEquitiesV1 EXCEPT !.programTrade = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCaEquitiesV1 EXCEPT !.jitney = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderCaEquitiesV1 EXCEPT !.anonymous = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCaEquitiesV1 EXCEPT !.umirRegulationId = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCaEquitiesV1 EXCEPT !.nonResident = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCaEquitiesV1 EXCEPT !.bypass = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCaEquitiesV1 EXCEPT !.ncib = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCaEquitiesV1 EXCEPT !.noTradeFeat = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCaEquitiesV1 EXCEPT !.noTradeKey = one] : one \in Sample(6) }
        \cup { [ZeroNewOrderCaEquitiesV1 EXCEPT !.shortMarkingExempt = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCaEquitiesV1 EXCEPT !.leiCustomerAccount = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderCaEquitiesV1 EXCEPT !.leiAlgorithmId = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderCaEquitiesV1 EXCEPT !.customerLei = one] : one \in Sample(52) }
        \cup { [ZeroNewOrderCaEquitiesV1 EXCEPT !.brokerLei = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderCaEquitiesV1 EXCEPT !.routingInst = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCaEquitiesV1 EXCEPT !.displayIndicator = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCaEquitiesV1 EXCEPT !.matchingStateParticipation = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCaEquitiesV1 EXCEPT !.trueMinQty = one] : one \in Sample(4) }

(***************************************************************************)
(* New Order Ca Equities V 2: 261 bytes                                    *)
(***************************************************************************)

NewOrderCaEquitiesV2 ==
    [ account                        : Sample(16),
      clOrdId                        : Sample(20),
      brokerId                       : Sample(2),
      execInst                       : Sample(1),
      handlingInst                   : Sample(1),
      orderQty                       : Sample(4),
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
      expireTime                     : Sample(8),
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
      noTradeFeat                    : Sample(1),
      noTradeKey                     : Sample(6),
      shortMarkingExempt             : Sample(1),
      leiCustomerAccount             : Sample(20),
      leiAlgorithmId                 : Sample(20),
      customerLei                    : Sample(52),
      brokerLei                      : Sample(20),
      routingInst                    : Sample(1),
      displayIndicator               : Sample(1),
      matchingStateParticipation     : Sample(1),
      trueMinQty                     : Sample(4),
      pegDifference                  : Sample(8) ]

EncodeNewOrderCaEquitiesV2(message) ==
    message.account
        \o message.clOrdId
        \o message.brokerId
        \o message.execInst
        \o message.handlingInst
        \o message.orderQty
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
        \o message.expireTime
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
        \o message.noTradeFeat
        \o message.noTradeKey
        \o message.shortMarkingExempt
        \o message.leiCustomerAccount
        \o message.leiAlgorithmId
        \o message.customerLei
        \o message.brokerLei
        \o message.routingInst
        \o message.displayIndicator
        \o message.matchingStateParticipation
        \o message.trueMinQty
        \o message.pegDifference

DecodeNewOrderCaEquitiesV2(bytes) ==
    LET account == ReadBytes(bytes, 16) IN IF ~account.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(account.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET brokerId == ReadBytes(clOrdId.rest, 2) IN IF ~brokerId.ok THEN Fail ELSE
    LET execInst == ReadBytes(brokerId.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET handlingInst == ReadBytes(execInst.rest, 1) IN IF ~handlingInst.ok THEN Fail ELSE
    LET orderQty == ReadBytes(handlingInst.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET ordType == ReadBytes(orderQty.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET price == ReadBytes(ordType.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET stopPx == ReadBytes(price.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET side == ReadBytes(stopPx.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET symbol == ReadBytes(side.rest, 14) IN IF ~symbol.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(symbol.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET settlementType == ReadBytes(timeInForce.rest, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET futSettlDate == ReadBytes(settlementType.rest, 4) IN IF ~futSettlDate.ok THEN Fail ELSE
    LET exDestination == ReadBytes(futSettlDate.rest, 1) IN IF ~exDestination.ok THEN Fail ELSE
    LET maxFloor == ReadBytes(exDestination.rest, 4) IN IF ~maxFloor.ok THEN Fail ELSE
    LET expireTime == ReadBytes(maxFloor.rest, 8) IN IF ~expireTime.ok THEN Fail ELSE
    LET expireDate == ReadBytes(expireTime.rest, 4) IN IF ~expireDate.ok THEN Fail ELSE
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
    LET noTradeFeat == ReadBytes(ncib.rest, 1) IN IF ~noTradeFeat.ok THEN Fail ELSE
    LET noTradeKey == ReadBytes(noTradeFeat.rest, 6) IN IF ~noTradeKey.ok THEN Fail ELSE
    LET shortMarkingExempt == ReadBytes(noTradeKey.rest, 1) IN IF ~shortMarkingExempt.ok THEN Fail ELSE
    LET leiCustomerAccount == ReadBytes(shortMarkingExempt.rest, 20) IN IF ~leiCustomerAccount.ok THEN Fail ELSE
    LET leiAlgorithmId == ReadBytes(leiCustomerAccount.rest, 20) IN IF ~leiAlgorithmId.ok THEN Fail ELSE
    LET customerLei == ReadBytes(leiAlgorithmId.rest, 52) IN IF ~customerLei.ok THEN Fail ELSE
    LET brokerLei == ReadBytes(customerLei.rest, 20) IN IF ~brokerLei.ok THEN Fail ELSE
    LET routingInst == ReadBytes(brokerLei.rest, 1) IN IF ~routingInst.ok THEN Fail ELSE
    LET displayIndicator == ReadBytes(routingInst.rest, 1) IN IF ~displayIndicator.ok THEN Fail ELSE
    LET matchingStateParticipation == ReadBytes(displayIndicator.rest, 1) IN IF ~matchingStateParticipation.ok THEN Fail ELSE
    LET trueMinQty == ReadBytes(matchingStateParticipation.rest, 4) IN IF ~trueMinQty.ok THEN Fail ELSE
    LET pegDifference == ReadBytes(trueMinQty.rest, 8) IN IF ~pegDifference.ok THEN Fail ELSE
    Ok([ account                        |-> account.value,
         clOrdId                        |-> clOrdId.value,
         brokerId                       |-> brokerId.value,
         execInst                       |-> execInst.value,
         handlingInst                   |-> handlingInst.value,
         orderQty                       |-> orderQty.value,
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
         expireTime                     |-> expireTime.value,
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
         noTradeFeat                    |-> noTradeFeat.value,
         noTradeKey                     |-> noTradeKey.value,
         shortMarkingExempt             |-> shortMarkingExempt.value,
         leiCustomerAccount             |-> leiCustomerAccount.value,
         leiAlgorithmId                 |-> leiAlgorithmId.value,
         customerLei                    |-> customerLei.value,
         brokerLei                      |-> brokerLei.value,
         routingInst                    |-> routingInst.value,
         displayIndicator               |-> displayIndicator.value,
         matchingStateParticipation     |-> matchingStateParticipation.value,
         trueMinQty                     |-> trueMinQty.value,
         pegDifference                  |-> pegDifference.value ], pegDifference.rest)

ZeroNewOrderCaEquitiesV2 ==
    [ account                        |-> [i \in 1 .. 16 |-> 0],
      clOrdId                        |-> [i \in 1 .. 20 |-> 0],
      brokerId                       |-> [i \in 1 .. 2 |-> 0],
      execInst                       |-> [i \in 1 .. 1 |-> 0],
      handlingInst                   |-> [i \in 1 .. 1 |-> 0],
      orderQty                       |-> [i \in 1 .. 4 |-> 0],
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
      expireTime                     |-> [i \in 1 .. 8 |-> 0],
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
      noTradeFeat                    |-> [i \in 1 .. 1 |-> 0],
      noTradeKey                     |-> [i \in 1 .. 6 |-> 0],
      shortMarkingExempt             |-> [i \in 1 .. 1 |-> 0],
      leiCustomerAccount             |-> [i \in 1 .. 20 |-> 0],
      leiAlgorithmId                 |-> [i \in 1 .. 20 |-> 0],
      customerLei                    |-> [i \in 1 .. 52 |-> 0],
      brokerLei                      |-> [i \in 1 .. 20 |-> 0],
      routingInst                    |-> [i \in 1 .. 1 |-> 0],
      displayIndicator               |-> [i \in 1 .. 1 |-> 0],
      matchingStateParticipation     |-> [i \in 1 .. 1 |-> 0],
      trueMinQty                     |-> [i \in 1 .. 4 |-> 0],
      pegDifference                  |-> [i \in 1 .. 8 |-> 0] ]

(* New Order Ca Equities V 2 at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderCaEquitiesV2 ==
    { ZeroNewOrderCaEquitiesV2 }
        \cup { [ZeroNewOrderCaEquitiesV2 EXCEPT !.account = one] : one \in Sample(16) }
        \cup { [ZeroNewOrderCaEquitiesV2 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderCaEquitiesV2 EXCEPT !.brokerId = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderCaEquitiesV2 EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCaEquitiesV2 EXCEPT !.handlingInst = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCaEquitiesV2 EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderCaEquitiesV2 EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCaEquitiesV2 EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderCaEquitiesV2 EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderCaEquitiesV2 EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCaEquitiesV2 EXCEPT !.symbol = one] : one \in Sample(14) }
        \cup { [ZeroNewOrderCaEquitiesV2 EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCaEquitiesV2 EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCaEquitiesV2 EXCEPT !.futSettlDate = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderCaEquitiesV2 EXCEPT !.exDestination = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCaEquitiesV2 EXCEPT !.maxFloor = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderCaEquitiesV2 EXCEPT !.expireTime = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderCaEquitiesV2 EXCEPT !.expireDate = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderCaEquitiesV2 EXCEPT !.leiOrderOrigin = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCaEquitiesV2 EXCEPT !.leiRoutingArrangementIndicator = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCaEquitiesV2 EXCEPT !.umirAccountType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCaEquitiesV2 EXCEPT !.umirUserId = one] : one \in Sample(12) }
        \cup { [ZeroNewOrderCaEquitiesV2 EXCEPT !.basketTrade = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderCaEquitiesV2 EXCEPT !.programTrade = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCaEquitiesV2 EXCEPT !.jitney = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderCaEquitiesV2 EXCEPT !.anonymous = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCaEquitiesV2 EXCEPT !.umirRegulationId = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCaEquitiesV2 EXCEPT !.nonResident = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCaEquitiesV2 EXCEPT !.bypass = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCaEquitiesV2 EXCEPT !.ncib = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCaEquitiesV2 EXCEPT !.noTradeFeat = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCaEquitiesV2 EXCEPT !.noTradeKey = one] : one \in Sample(6) }
        \cup { [ZeroNewOrderCaEquitiesV2 EXCEPT !.shortMarkingExempt = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCaEquitiesV2 EXCEPT !.leiCustomerAccount = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderCaEquitiesV2 EXCEPT !.leiAlgorithmId = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderCaEquitiesV2 EXCEPT !.customerLei = one] : one \in Sample(52) }
        \cup { [ZeroNewOrderCaEquitiesV2 EXCEPT !.brokerLei = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderCaEquitiesV2 EXCEPT !.routingInst = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCaEquitiesV2 EXCEPT !.displayIndicator = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCaEquitiesV2 EXCEPT !.matchingStateParticipation = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCaEquitiesV2 EXCEPT !.trueMinQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderCaEquitiesV2 EXCEPT !.pegDifference = one] : one \in Sample(8) }

(***************************************************************************)
(* Modify Order Ca Equities V 1: 215 bytes                                 *)
(***************************************************************************)

ModifyOrderCaEquitiesV1 ==
    [ clOrdId                        : Sample(20),
      origClOrdId                    : Sample(20),
      brokerId                       : Sample(2),
      account                        : Sample(16),
      orderQty                       : Sample(4),
      price                          : Sample(8),
      stopPx                         : Sample(8),
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
      cancelOrigOnReject             : Sample(1),
      trueMinQty                     : Sample(4),
      expireTime                     : Sample(8) ]

EncodeModifyOrderCaEquitiesV1(message) ==
    message.clOrdId
        \o message.origClOrdId
        \o message.brokerId
        \o message.account
        \o message.orderQty
        \o message.price
        \o message.stopPx
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
        \o message.cancelOrigOnReject
        \o message.trueMinQty
        \o message.expireTime

DecodeModifyOrderCaEquitiesV1(bytes) ==
    LET clOrdId == ReadBytes(bytes, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 20) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET brokerId == ReadBytes(origClOrdId.rest, 2) IN IF ~brokerId.ok THEN Fail ELSE
    LET account == ReadBytes(brokerId.rest, 16) IN IF ~account.ok THEN Fail ELSE
    LET orderQty == ReadBytes(account.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET price == ReadBytes(orderQty.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET stopPx == ReadBytes(price.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(stopPx.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET maxFloor == ReadBytes(timeInForce.rest, 4) IN IF ~maxFloor.ok THEN Fail ELSE
    LET expireDate == ReadBytes(maxFloor.rest, 4) IN IF ~expireDate.ok THEN Fail ELSE
    LET leiOrderOrigin == ReadBytes(expireDate.rest, 1) IN IF ~leiOrderOrigin.ok THEN Fail ELSE
    LET leiRoutingArrangementIndicator == ReadBytes(leiOrderOrigin.rest, 1) IN IF ~leiRoutingArrangementIndicator.ok THEN Fail ELSE
    LET umirAccountType == ReadBytes(leiRoutingArrangementIndicator.rest, 1) IN IF ~umirAccountType.ok THEN Fail ELSE
    LET leiCustomerAccount == ReadBytes(umirAccountType.rest, 20) IN IF ~leiCustomerAccount.ok THEN Fail ELSE
    LET leiAlgorithmId == ReadBytes(leiCustomerAccount.rest, 20) IN IF ~leiAlgorithmId.ok THEN Fail ELSE
    LET customerLei == ReadBytes(leiAlgorithmId.rest, 52) IN IF ~customerLei.ok THEN Fail ELSE
    LET brokerLei == ReadBytes(customerLei.rest, 20) IN IF ~brokerLei.ok THEN Fail ELSE
    LET cancelOrigOnReject == ReadBytes(brokerLei.rest, 1) IN IF ~cancelOrigOnReject.ok THEN Fail ELSE
    LET trueMinQty == ReadBytes(cancelOrigOnReject.rest, 4) IN IF ~trueMinQty.ok THEN Fail ELSE
    LET expireTime == ReadBytes(trueMinQty.rest, 8) IN IF ~expireTime.ok THEN Fail ELSE
    Ok([ clOrdId                        |-> clOrdId.value,
         origClOrdId                    |-> origClOrdId.value,
         brokerId                       |-> brokerId.value,
         account                        |-> account.value,
         orderQty                       |-> orderQty.value,
         price                          |-> price.value,
         stopPx                         |-> stopPx.value,
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
         cancelOrigOnReject             |-> cancelOrigOnReject.value,
         trueMinQty                     |-> trueMinQty.value,
         expireTime                     |-> expireTime.value ], expireTime.rest)

ZeroModifyOrderCaEquitiesV1 ==
    [ clOrdId                        |-> [i \in 1 .. 20 |-> 0],
      origClOrdId                    |-> [i \in 1 .. 20 |-> 0],
      brokerId                       |-> [i \in 1 .. 2 |-> 0],
      account                        |-> [i \in 1 .. 16 |-> 0],
      orderQty                       |-> [i \in 1 .. 4 |-> 0],
      price                          |-> [i \in 1 .. 8 |-> 0],
      stopPx                         |-> [i \in 1 .. 8 |-> 0],
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
      cancelOrigOnReject             |-> [i \in 1 .. 1 |-> 0],
      trueMinQty                     |-> [i \in 1 .. 4 |-> 0],
      expireTime                     |-> [i \in 1 .. 8 |-> 0] ]

(* Modify Order Ca Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderCaEquitiesV1 ==
    { ZeroModifyOrderCaEquitiesV1 }
        \cup { [ZeroModifyOrderCaEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroModifyOrderCaEquitiesV1 EXCEPT !.origClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroModifyOrderCaEquitiesV1 EXCEPT !.brokerId = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderCaEquitiesV1 EXCEPT !.account = one] : one \in Sample(16) }
        \cup { [ZeroModifyOrderCaEquitiesV1 EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderCaEquitiesV1 EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderCaEquitiesV1 EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderCaEquitiesV1 EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderCaEquitiesV1 EXCEPT !.maxFloor = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderCaEquitiesV1 EXCEPT !.expireDate = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderCaEquitiesV1 EXCEPT !.leiOrderOrigin = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderCaEquitiesV1 EXCEPT !.leiRoutingArrangementIndicator = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderCaEquitiesV1 EXCEPT !.umirAccountType = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderCaEquitiesV1 EXCEPT !.leiCustomerAccount = one] : one \in Sample(20) }
        \cup { [ZeroModifyOrderCaEquitiesV1 EXCEPT !.leiAlgorithmId = one] : one \in Sample(20) }
        \cup { [ZeroModifyOrderCaEquitiesV1 EXCEPT !.customerLei = one] : one \in Sample(52) }
        \cup { [ZeroModifyOrderCaEquitiesV1 EXCEPT !.brokerLei = one] : one \in Sample(20) }
        \cup { [ZeroModifyOrderCaEquitiesV1 EXCEPT !.cancelOrigOnReject = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderCaEquitiesV1 EXCEPT !.trueMinQty = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderCaEquitiesV1 EXCEPT !.expireTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Cancel Order Ca Equities V 1: 22 bytes                                  *)
(***************************************************************************)

CancelOrderCaEquitiesV1 ==
    [ brokerId    : Sample(2),
      origClOrdId : Sample(20) ]

EncodeCancelOrderCaEquitiesV1(message) ==
    message.brokerId
        \o message.origClOrdId

DecodeCancelOrderCaEquitiesV1(bytes) ==
    LET brokerId == ReadBytes(bytes, 2) IN IF ~brokerId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(brokerId.rest, 20) IN IF ~origClOrdId.ok THEN Fail ELSE
    Ok([ brokerId    |-> brokerId.value,
         origClOrdId |-> origClOrdId.value ], origClOrdId.rest)

ZeroCancelOrderCaEquitiesV1 ==
    [ brokerId    |-> [i \in 1 .. 2 |-> 0],
      origClOrdId |-> [i \in 1 .. 20 |-> 0] ]

(* Cancel Order Ca Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedCancelOrderCaEquitiesV1 ==
    { ZeroCancelOrderCaEquitiesV1 }
        \cup { [ZeroCancelOrderCaEquitiesV1 EXCEPT !.brokerId = one] : one \in Sample(2) }
        \cup { [ZeroCancelOrderCaEquitiesV1 EXCEPT !.origClOrdId = one] : one \in Sample(20) }

(***************************************************************************)
(* New Order Cross Ca Equities V 1: 342 bytes                              *)
(***************************************************************************)

NewOrderCrossCaEquitiesV1 ==
    [ brokerId                           : Sample(2),
      crossClOrdId                       : Sample(18),
      crossType                          : Sample(1),
      price                              : Sample(8),
      orderQty                           : Sample(4),
      symbol                             : Sample(14),
      settlementType                     : Sample(1),
      futSettlDate                       : Sample(4),
      umirUserId                         : Sample(12),
      basketTrade                        : Sample(4),
      programTrade                       : Sample(1),
      nonResident                        : Sample(1),
      bypass                             : Sample(1),
      ncib                               : Sample(1),
      crossSide                          : Sample(1),
      shortMarkingExempt                 : Sample(1),
      buyUmirAccountType                 : Sample(1),
      buyAccount                         : Sample(16),
      buyUmirRegulationId                : Sample(1),
      buyJitney                          : Sample(2),
      buyLeiCustomerAccount              : Sample(20),
      buyLeiAlgorithmId                  : Sample(20),
      buyCustomerLei                     : Sample(52),
      buyBrokerLei                       : Sample(20),
      buyLeiOrderOrigin                  : Sample(1),
      buyLeiRoutingArrangemeantIndicator : Sample(1),
      sellUmirAccountType                : Sample(1),
      sellAccount                        : Sample(16),
      sellUmirRegulationId               : Sample(1),
      sellJitney                         : Sample(2),
      sellLeiCustomerAccount             : Sample(20),
      sellLeiAlgorithmId                 : Sample(20),
      sellCustomerLei                    : Sample(52),
      sellBrokerLei                      : Sample(20),
      sellLeiOrderOrigin                 : Sample(1),
      sellLeiRoutingArrangementIndicator : Sample(1) ]

EncodeNewOrderCrossCaEquitiesV1(message) ==
    message.brokerId
        \o message.crossClOrdId
        \o message.crossType
        \o message.price
        \o message.orderQty
        \o message.symbol
        \o message.settlementType
        \o message.futSettlDate
        \o message.umirUserId
        \o message.basketTrade
        \o message.programTrade
        \o message.nonResident
        \o message.bypass
        \o message.ncib
        \o message.crossSide
        \o message.shortMarkingExempt
        \o message.buyUmirAccountType
        \o message.buyAccount
        \o message.buyUmirRegulationId
        \o message.buyJitney
        \o message.buyLeiCustomerAccount
        \o message.buyLeiAlgorithmId
        \o message.buyCustomerLei
        \o message.buyBrokerLei
        \o message.buyLeiOrderOrigin
        \o message.buyLeiRoutingArrangemeantIndicator
        \o message.sellUmirAccountType
        \o message.sellAccount
        \o message.sellUmirRegulationId
        \o message.sellJitney
        \o message.sellLeiCustomerAccount
        \o message.sellLeiAlgorithmId
        \o message.sellCustomerLei
        \o message.sellBrokerLei
        \o message.sellLeiOrderOrigin
        \o message.sellLeiRoutingArrangementIndicator

DecodeNewOrderCrossCaEquitiesV1(bytes) ==
    LET brokerId == ReadBytes(bytes, 2) IN IF ~brokerId.ok THEN Fail ELSE
    LET crossClOrdId == ReadBytes(brokerId.rest, 18) IN IF ~crossClOrdId.ok THEN Fail ELSE
    LET crossType == ReadBytes(crossClOrdId.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET price == ReadBytes(crossType.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderQty == ReadBytes(price.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET symbol == ReadBytes(orderQty.rest, 14) IN IF ~symbol.ok THEN Fail ELSE
    LET settlementType == ReadBytes(symbol.rest, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET futSettlDate == ReadBytes(settlementType.rest, 4) IN IF ~futSettlDate.ok THEN Fail ELSE
    LET umirUserId == ReadBytes(futSettlDate.rest, 12) IN IF ~umirUserId.ok THEN Fail ELSE
    LET basketTrade == ReadBytes(umirUserId.rest, 4) IN IF ~basketTrade.ok THEN Fail ELSE
    LET programTrade == ReadBytes(basketTrade.rest, 1) IN IF ~programTrade.ok THEN Fail ELSE
    LET nonResident == ReadBytes(programTrade.rest, 1) IN IF ~nonResident.ok THEN Fail ELSE
    LET bypass == ReadBytes(nonResident.rest, 1) IN IF ~bypass.ok THEN Fail ELSE
    LET ncib == ReadBytes(bypass.rest, 1) IN IF ~ncib.ok THEN Fail ELSE
    LET crossSide == ReadBytes(ncib.rest, 1) IN IF ~crossSide.ok THEN Fail ELSE
    LET shortMarkingExempt == ReadBytes(crossSide.rest, 1) IN IF ~shortMarkingExempt.ok THEN Fail ELSE
    LET buyUmirAccountType == ReadBytes(shortMarkingExempt.rest, 1) IN IF ~buyUmirAccountType.ok THEN Fail ELSE
    LET buyAccount == ReadBytes(buyUmirAccountType.rest, 16) IN IF ~buyAccount.ok THEN Fail ELSE
    LET buyUmirRegulationId == ReadBytes(buyAccount.rest, 1) IN IF ~buyUmirRegulationId.ok THEN Fail ELSE
    LET buyJitney == ReadBytes(buyUmirRegulationId.rest, 2) IN IF ~buyJitney.ok THEN Fail ELSE
    LET buyLeiCustomerAccount == ReadBytes(buyJitney.rest, 20) IN IF ~buyLeiCustomerAccount.ok THEN Fail ELSE
    LET buyLeiAlgorithmId == ReadBytes(buyLeiCustomerAccount.rest, 20) IN IF ~buyLeiAlgorithmId.ok THEN Fail ELSE
    LET buyCustomerLei == ReadBytes(buyLeiAlgorithmId.rest, 52) IN IF ~buyCustomerLei.ok THEN Fail ELSE
    LET buyBrokerLei == ReadBytes(buyCustomerLei.rest, 20) IN IF ~buyBrokerLei.ok THEN Fail ELSE
    LET buyLeiOrderOrigin == ReadBytes(buyBrokerLei.rest, 1) IN IF ~buyLeiOrderOrigin.ok THEN Fail ELSE
    LET buyLeiRoutingArrangemeantIndicator == ReadBytes(buyLeiOrderOrigin.rest, 1) IN IF ~buyLeiRoutingArrangemeantIndicator.ok THEN Fail ELSE
    LET sellUmirAccountType == ReadBytes(buyLeiRoutingArrangemeantIndicator.rest, 1) IN IF ~sellUmirAccountType.ok THEN Fail ELSE
    LET sellAccount == ReadBytes(sellUmirAccountType.rest, 16) IN IF ~sellAccount.ok THEN Fail ELSE
    LET sellUmirRegulationId == ReadBytes(sellAccount.rest, 1) IN IF ~sellUmirRegulationId.ok THEN Fail ELSE
    LET sellJitney == ReadBytes(sellUmirRegulationId.rest, 2) IN IF ~sellJitney.ok THEN Fail ELSE
    LET sellLeiCustomerAccount == ReadBytes(sellJitney.rest, 20) IN IF ~sellLeiCustomerAccount.ok THEN Fail ELSE
    LET sellLeiAlgorithmId == ReadBytes(sellLeiCustomerAccount.rest, 20) IN IF ~sellLeiAlgorithmId.ok THEN Fail ELSE
    LET sellCustomerLei == ReadBytes(sellLeiAlgorithmId.rest, 52) IN IF ~sellCustomerLei.ok THEN Fail ELSE
    LET sellBrokerLei == ReadBytes(sellCustomerLei.rest, 20) IN IF ~sellBrokerLei.ok THEN Fail ELSE
    LET sellLeiOrderOrigin == ReadBytes(sellBrokerLei.rest, 1) IN IF ~sellLeiOrderOrigin.ok THEN Fail ELSE
    LET sellLeiRoutingArrangementIndicator == ReadBytes(sellLeiOrderOrigin.rest, 1) IN IF ~sellLeiRoutingArrangementIndicator.ok THEN Fail ELSE
    Ok([ brokerId                           |-> brokerId.value,
         crossClOrdId                       |-> crossClOrdId.value,
         crossType                          |-> crossType.value,
         price                              |-> price.value,
         orderQty                           |-> orderQty.value,
         symbol                             |-> symbol.value,
         settlementType                     |-> settlementType.value,
         futSettlDate                       |-> futSettlDate.value,
         umirUserId                         |-> umirUserId.value,
         basketTrade                        |-> basketTrade.value,
         programTrade                       |-> programTrade.value,
         nonResident                        |-> nonResident.value,
         bypass                             |-> bypass.value,
         ncib                               |-> ncib.value,
         crossSide                          |-> crossSide.value,
         shortMarkingExempt                 |-> shortMarkingExempt.value,
         buyUmirAccountType                 |-> buyUmirAccountType.value,
         buyAccount                         |-> buyAccount.value,
         buyUmirRegulationId                |-> buyUmirRegulationId.value,
         buyJitney                          |-> buyJitney.value,
         buyLeiCustomerAccount              |-> buyLeiCustomerAccount.value,
         buyLeiAlgorithmId                  |-> buyLeiAlgorithmId.value,
         buyCustomerLei                     |-> buyCustomerLei.value,
         buyBrokerLei                       |-> buyBrokerLei.value,
         buyLeiOrderOrigin                  |-> buyLeiOrderOrigin.value,
         buyLeiRoutingArrangemeantIndicator |-> buyLeiRoutingArrangemeantIndicator.value,
         sellUmirAccountType                |-> sellUmirAccountType.value,
         sellAccount                        |-> sellAccount.value,
         sellUmirRegulationId               |-> sellUmirRegulationId.value,
         sellJitney                         |-> sellJitney.value,
         sellLeiCustomerAccount             |-> sellLeiCustomerAccount.value,
         sellLeiAlgorithmId                 |-> sellLeiAlgorithmId.value,
         sellCustomerLei                    |-> sellCustomerLei.value,
         sellBrokerLei                      |-> sellBrokerLei.value,
         sellLeiOrderOrigin                 |-> sellLeiOrderOrigin.value,
         sellLeiRoutingArrangementIndicator |-> sellLeiRoutingArrangementIndicator.value ], sellLeiRoutingArrangementIndicator.rest)

ZeroNewOrderCrossCaEquitiesV1 ==
    [ brokerId                           |-> [i \in 1 .. 2 |-> 0],
      crossClOrdId                       |-> [i \in 1 .. 18 |-> 0],
      crossType                          |-> [i \in 1 .. 1 |-> 0],
      price                              |-> [i \in 1 .. 8 |-> 0],
      orderQty                           |-> [i \in 1 .. 4 |-> 0],
      symbol                             |-> [i \in 1 .. 14 |-> 0],
      settlementType                     |-> [i \in 1 .. 1 |-> 0],
      futSettlDate                       |-> [i \in 1 .. 4 |-> 0],
      umirUserId                         |-> [i \in 1 .. 12 |-> 0],
      basketTrade                        |-> [i \in 1 .. 4 |-> 0],
      programTrade                       |-> [i \in 1 .. 1 |-> 0],
      nonResident                        |-> [i \in 1 .. 1 |-> 0],
      bypass                             |-> [i \in 1 .. 1 |-> 0],
      ncib                               |-> [i \in 1 .. 1 |-> 0],
      crossSide                          |-> [i \in 1 .. 1 |-> 0],
      shortMarkingExempt                 |-> [i \in 1 .. 1 |-> 0],
      buyUmirAccountType                 |-> [i \in 1 .. 1 |-> 0],
      buyAccount                         |-> [i \in 1 .. 16 |-> 0],
      buyUmirRegulationId                |-> [i \in 1 .. 1 |-> 0],
      buyJitney                          |-> [i \in 1 .. 2 |-> 0],
      buyLeiCustomerAccount              |-> [i \in 1 .. 20 |-> 0],
      buyLeiAlgorithmId                  |-> [i \in 1 .. 20 |-> 0],
      buyCustomerLei                     |-> [i \in 1 .. 52 |-> 0],
      buyBrokerLei                       |-> [i \in 1 .. 20 |-> 0],
      buyLeiOrderOrigin                  |-> [i \in 1 .. 1 |-> 0],
      buyLeiRoutingArrangemeantIndicator |-> [i \in 1 .. 1 |-> 0],
      sellUmirAccountType                |-> [i \in 1 .. 1 |-> 0],
      sellAccount                        |-> [i \in 1 .. 16 |-> 0],
      sellUmirRegulationId               |-> [i \in 1 .. 1 |-> 0],
      sellJitney                         |-> [i \in 1 .. 2 |-> 0],
      sellLeiCustomerAccount             |-> [i \in 1 .. 20 |-> 0],
      sellLeiAlgorithmId                 |-> [i \in 1 .. 20 |-> 0],
      sellCustomerLei                    |-> [i \in 1 .. 52 |-> 0],
      sellBrokerLei                      |-> [i \in 1 .. 20 |-> 0],
      sellLeiOrderOrigin                 |-> [i \in 1 .. 1 |-> 0],
      sellLeiRoutingArrangementIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* New Order Cross Ca Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderCrossCaEquitiesV1 ==
    { ZeroNewOrderCrossCaEquitiesV1 }
        \cup { [ZeroNewOrderCrossCaEquitiesV1 EXCEPT !.brokerId = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderCrossCaEquitiesV1 EXCEPT !.crossClOrdId = one] : one \in Sample(18) }
        \cup { [ZeroNewOrderCrossCaEquitiesV1 EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossCaEquitiesV1 EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderCrossCaEquitiesV1 EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderCrossCaEquitiesV1 EXCEPT !.symbol = one] : one \in Sample(14) }
        \cup { [ZeroNewOrderCrossCaEquitiesV1 EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossCaEquitiesV1 EXCEPT !.futSettlDate = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderCrossCaEquitiesV1 EXCEPT !.umirUserId = one] : one \in Sample(12) }
        \cup { [ZeroNewOrderCrossCaEquitiesV1 EXCEPT !.basketTrade = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderCrossCaEquitiesV1 EXCEPT !.programTrade = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossCaEquitiesV1 EXCEPT !.nonResident = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossCaEquitiesV1 EXCEPT !.bypass = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossCaEquitiesV1 EXCEPT !.ncib = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossCaEquitiesV1 EXCEPT !.crossSide = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossCaEquitiesV1 EXCEPT !.shortMarkingExempt = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossCaEquitiesV1 EXCEPT !.buyUmirAccountType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossCaEquitiesV1 EXCEPT !.buyAccount = one] : one \in Sample(16) }
        \cup { [ZeroNewOrderCrossCaEquitiesV1 EXCEPT !.buyUmirRegulationId = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossCaEquitiesV1 EXCEPT !.buyJitney = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderCrossCaEquitiesV1 EXCEPT !.buyLeiCustomerAccount = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderCrossCaEquitiesV1 EXCEPT !.buyLeiAlgorithmId = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderCrossCaEquitiesV1 EXCEPT !.buyCustomerLei = one] : one \in Sample(52) }
        \cup { [ZeroNewOrderCrossCaEquitiesV1 EXCEPT !.buyBrokerLei = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderCrossCaEquitiesV1 EXCEPT !.buyLeiOrderOrigin = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossCaEquitiesV1 EXCEPT !.buyLeiRoutingArrangemeantIndicator = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossCaEquitiesV1 EXCEPT !.sellUmirAccountType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossCaEquitiesV1 EXCEPT !.sellAccount = one] : one \in Sample(16) }
        \cup { [ZeroNewOrderCrossCaEquitiesV1 EXCEPT !.sellUmirRegulationId = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossCaEquitiesV1 EXCEPT !.sellJitney = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderCrossCaEquitiesV1 EXCEPT !.sellLeiCustomerAccount = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderCrossCaEquitiesV1 EXCEPT !.sellLeiAlgorithmId = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderCrossCaEquitiesV1 EXCEPT !.sellCustomerLei = one] : one \in Sample(52) }
        \cup { [ZeroNewOrderCrossCaEquitiesV1 EXCEPT !.sellBrokerLei = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderCrossCaEquitiesV1 EXCEPT !.sellLeiOrderOrigin = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossCaEquitiesV1 EXCEPT !.sellLeiRoutingArrangementIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* New Order Cross Ca Equities V 2: 347 bytes                              *)
(***************************************************************************)

NewOrderCrossCaEquitiesV2 ==
    [ brokerId                           : Sample(2),
      crossClOrdId                       : Sample(18),
      crossType                          : Sample(1),
      price                              : Sample(8),
      orderQty                           : Sample(4),
      symbol                             : Sample(14),
      settlementType                     : Sample(1),
      futSettlDate                       : Sample(4),
      umirUserId                         : Sample(12),
      basketTrade                        : Sample(4),
      programTrade                       : Sample(1),
      nonResident                        : Sample(1),
      bypass                             : Sample(1),
      ncib                               : Sample(1),
      crossSide                          : Sample(1),
      shortMarkingExempt                 : Sample(1),
      buyUmirAccountType                 : Sample(1),
      buyAccount                         : Sample(16),
      buyUmirRegulationId                : Sample(1),
      buyJitney                          : Sample(2),
      buyLeiCustomerAccount              : Sample(20),
      buyLeiAlgorithmId                  : Sample(20),
      buyCustomerLei                     : Sample(52),
      buyBrokerLei                       : Sample(20),
      buyLeiOrderOrigin                  : Sample(1),
      buyLeiRoutingArrangementIndicator  : Sample(1),
      sellUmirAccountType                : Sample(1),
      sellAccount                        : Sample(16),
      sellUmirRegulationId               : Sample(1),
      sellJitney                         : Sample(2),
      sellLeiCustomerAccount             : Sample(20),
      sellLeiAlgorithmId                 : Sample(20),
      sellCustomerLei                    : Sample(52),
      sellBrokerLei                      : Sample(20),
      sellLeiOrderOrigin                 : Sample(1),
      sellLeiRoutingArrangementIndicator : Sample(1),
      anonymous                          : Sample(1),
      reserved                           : Sample(4) ]

EncodeNewOrderCrossCaEquitiesV2(message) ==
    message.brokerId
        \o message.crossClOrdId
        \o message.crossType
        \o message.price
        \o message.orderQty
        \o message.symbol
        \o message.settlementType
        \o message.futSettlDate
        \o message.umirUserId
        \o message.basketTrade
        \o message.programTrade
        \o message.nonResident
        \o message.bypass
        \o message.ncib
        \o message.crossSide
        \o message.shortMarkingExempt
        \o message.buyUmirAccountType
        \o message.buyAccount
        \o message.buyUmirRegulationId
        \o message.buyJitney
        \o message.buyLeiCustomerAccount
        \o message.buyLeiAlgorithmId
        \o message.buyCustomerLei
        \o message.buyBrokerLei
        \o message.buyLeiOrderOrigin
        \o message.buyLeiRoutingArrangementIndicator
        \o message.sellUmirAccountType
        \o message.sellAccount
        \o message.sellUmirRegulationId
        \o message.sellJitney
        \o message.sellLeiCustomerAccount
        \o message.sellLeiAlgorithmId
        \o message.sellCustomerLei
        \o message.sellBrokerLei
        \o message.sellLeiOrderOrigin
        \o message.sellLeiRoutingArrangementIndicator
        \o message.anonymous
        \o message.reserved

DecodeNewOrderCrossCaEquitiesV2(bytes) ==
    LET brokerId == ReadBytes(bytes, 2) IN IF ~brokerId.ok THEN Fail ELSE
    LET crossClOrdId == ReadBytes(brokerId.rest, 18) IN IF ~crossClOrdId.ok THEN Fail ELSE
    LET crossType == ReadBytes(crossClOrdId.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET price == ReadBytes(crossType.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderQty == ReadBytes(price.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET symbol == ReadBytes(orderQty.rest, 14) IN IF ~symbol.ok THEN Fail ELSE
    LET settlementType == ReadBytes(symbol.rest, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET futSettlDate == ReadBytes(settlementType.rest, 4) IN IF ~futSettlDate.ok THEN Fail ELSE
    LET umirUserId == ReadBytes(futSettlDate.rest, 12) IN IF ~umirUserId.ok THEN Fail ELSE
    LET basketTrade == ReadBytes(umirUserId.rest, 4) IN IF ~basketTrade.ok THEN Fail ELSE
    LET programTrade == ReadBytes(basketTrade.rest, 1) IN IF ~programTrade.ok THEN Fail ELSE
    LET nonResident == ReadBytes(programTrade.rest, 1) IN IF ~nonResident.ok THEN Fail ELSE
    LET bypass == ReadBytes(nonResident.rest, 1) IN IF ~bypass.ok THEN Fail ELSE
    LET ncib == ReadBytes(bypass.rest, 1) IN IF ~ncib.ok THEN Fail ELSE
    LET crossSide == ReadBytes(ncib.rest, 1) IN IF ~crossSide.ok THEN Fail ELSE
    LET shortMarkingExempt == ReadBytes(crossSide.rest, 1) IN IF ~shortMarkingExempt.ok THEN Fail ELSE
    LET buyUmirAccountType == ReadBytes(shortMarkingExempt.rest, 1) IN IF ~buyUmirAccountType.ok THEN Fail ELSE
    LET buyAccount == ReadBytes(buyUmirAccountType.rest, 16) IN IF ~buyAccount.ok THEN Fail ELSE
    LET buyUmirRegulationId == ReadBytes(buyAccount.rest, 1) IN IF ~buyUmirRegulationId.ok THEN Fail ELSE
    LET buyJitney == ReadBytes(buyUmirRegulationId.rest, 2) IN IF ~buyJitney.ok THEN Fail ELSE
    LET buyLeiCustomerAccount == ReadBytes(buyJitney.rest, 20) IN IF ~buyLeiCustomerAccount.ok THEN Fail ELSE
    LET buyLeiAlgorithmId == ReadBytes(buyLeiCustomerAccount.rest, 20) IN IF ~buyLeiAlgorithmId.ok THEN Fail ELSE
    LET buyCustomerLei == ReadBytes(buyLeiAlgorithmId.rest, 52) IN IF ~buyCustomerLei.ok THEN Fail ELSE
    LET buyBrokerLei == ReadBytes(buyCustomerLei.rest, 20) IN IF ~buyBrokerLei.ok THEN Fail ELSE
    LET buyLeiOrderOrigin == ReadBytes(buyBrokerLei.rest, 1) IN IF ~buyLeiOrderOrigin.ok THEN Fail ELSE
    LET buyLeiRoutingArrangementIndicator == ReadBytes(buyLeiOrderOrigin.rest, 1) IN IF ~buyLeiRoutingArrangementIndicator.ok THEN Fail ELSE
    LET sellUmirAccountType == ReadBytes(buyLeiRoutingArrangementIndicator.rest, 1) IN IF ~sellUmirAccountType.ok THEN Fail ELSE
    LET sellAccount == ReadBytes(sellUmirAccountType.rest, 16) IN IF ~sellAccount.ok THEN Fail ELSE
    LET sellUmirRegulationId == ReadBytes(sellAccount.rest, 1) IN IF ~sellUmirRegulationId.ok THEN Fail ELSE
    LET sellJitney == ReadBytes(sellUmirRegulationId.rest, 2) IN IF ~sellJitney.ok THEN Fail ELSE
    LET sellLeiCustomerAccount == ReadBytes(sellJitney.rest, 20) IN IF ~sellLeiCustomerAccount.ok THEN Fail ELSE
    LET sellLeiAlgorithmId == ReadBytes(sellLeiCustomerAccount.rest, 20) IN IF ~sellLeiAlgorithmId.ok THEN Fail ELSE
    LET sellCustomerLei == ReadBytes(sellLeiAlgorithmId.rest, 52) IN IF ~sellCustomerLei.ok THEN Fail ELSE
    LET sellBrokerLei == ReadBytes(sellCustomerLei.rest, 20) IN IF ~sellBrokerLei.ok THEN Fail ELSE
    LET sellLeiOrderOrigin == ReadBytes(sellBrokerLei.rest, 1) IN IF ~sellLeiOrderOrigin.ok THEN Fail ELSE
    LET sellLeiRoutingArrangementIndicator == ReadBytes(sellLeiOrderOrigin.rest, 1) IN IF ~sellLeiRoutingArrangementIndicator.ok THEN Fail ELSE
    LET anonymous == ReadBytes(sellLeiRoutingArrangementIndicator.rest, 1) IN IF ~anonymous.ok THEN Fail ELSE
    LET reserved == ReadBytes(anonymous.rest, 4) IN IF ~reserved.ok THEN Fail ELSE
    Ok([ brokerId                           |-> brokerId.value,
         crossClOrdId                       |-> crossClOrdId.value,
         crossType                          |-> crossType.value,
         price                              |-> price.value,
         orderQty                           |-> orderQty.value,
         symbol                             |-> symbol.value,
         settlementType                     |-> settlementType.value,
         futSettlDate                       |-> futSettlDate.value,
         umirUserId                         |-> umirUserId.value,
         basketTrade                        |-> basketTrade.value,
         programTrade                       |-> programTrade.value,
         nonResident                        |-> nonResident.value,
         bypass                             |-> bypass.value,
         ncib                               |-> ncib.value,
         crossSide                          |-> crossSide.value,
         shortMarkingExempt                 |-> shortMarkingExempt.value,
         buyUmirAccountType                 |-> buyUmirAccountType.value,
         buyAccount                         |-> buyAccount.value,
         buyUmirRegulationId                |-> buyUmirRegulationId.value,
         buyJitney                          |-> buyJitney.value,
         buyLeiCustomerAccount              |-> buyLeiCustomerAccount.value,
         buyLeiAlgorithmId                  |-> buyLeiAlgorithmId.value,
         buyCustomerLei                     |-> buyCustomerLei.value,
         buyBrokerLei                       |-> buyBrokerLei.value,
         buyLeiOrderOrigin                  |-> buyLeiOrderOrigin.value,
         buyLeiRoutingArrangementIndicator  |-> buyLeiRoutingArrangementIndicator.value,
         sellUmirAccountType                |-> sellUmirAccountType.value,
         sellAccount                        |-> sellAccount.value,
         sellUmirRegulationId               |-> sellUmirRegulationId.value,
         sellJitney                         |-> sellJitney.value,
         sellLeiCustomerAccount             |-> sellLeiCustomerAccount.value,
         sellLeiAlgorithmId                 |-> sellLeiAlgorithmId.value,
         sellCustomerLei                    |-> sellCustomerLei.value,
         sellBrokerLei                      |-> sellBrokerLei.value,
         sellLeiOrderOrigin                 |-> sellLeiOrderOrigin.value,
         sellLeiRoutingArrangementIndicator |-> sellLeiRoutingArrangementIndicator.value,
         anonymous                          |-> anonymous.value,
         reserved                           |-> reserved.value ], reserved.rest)

ZeroNewOrderCrossCaEquitiesV2 ==
    [ brokerId                           |-> [i \in 1 .. 2 |-> 0],
      crossClOrdId                       |-> [i \in 1 .. 18 |-> 0],
      crossType                          |-> [i \in 1 .. 1 |-> 0],
      price                              |-> [i \in 1 .. 8 |-> 0],
      orderQty                           |-> [i \in 1 .. 4 |-> 0],
      symbol                             |-> [i \in 1 .. 14 |-> 0],
      settlementType                     |-> [i \in 1 .. 1 |-> 0],
      futSettlDate                       |-> [i \in 1 .. 4 |-> 0],
      umirUserId                         |-> [i \in 1 .. 12 |-> 0],
      basketTrade                        |-> [i \in 1 .. 4 |-> 0],
      programTrade                       |-> [i \in 1 .. 1 |-> 0],
      nonResident                        |-> [i \in 1 .. 1 |-> 0],
      bypass                             |-> [i \in 1 .. 1 |-> 0],
      ncib                               |-> [i \in 1 .. 1 |-> 0],
      crossSide                          |-> [i \in 1 .. 1 |-> 0],
      shortMarkingExempt                 |-> [i \in 1 .. 1 |-> 0],
      buyUmirAccountType                 |-> [i \in 1 .. 1 |-> 0],
      buyAccount                         |-> [i \in 1 .. 16 |-> 0],
      buyUmirRegulationId                |-> [i \in 1 .. 1 |-> 0],
      buyJitney                          |-> [i \in 1 .. 2 |-> 0],
      buyLeiCustomerAccount              |-> [i \in 1 .. 20 |-> 0],
      buyLeiAlgorithmId                  |-> [i \in 1 .. 20 |-> 0],
      buyCustomerLei                     |-> [i \in 1 .. 52 |-> 0],
      buyBrokerLei                       |-> [i \in 1 .. 20 |-> 0],
      buyLeiOrderOrigin                  |-> [i \in 1 .. 1 |-> 0],
      buyLeiRoutingArrangementIndicator  |-> [i \in 1 .. 1 |-> 0],
      sellUmirAccountType                |-> [i \in 1 .. 1 |-> 0],
      sellAccount                        |-> [i \in 1 .. 16 |-> 0],
      sellUmirRegulationId               |-> [i \in 1 .. 1 |-> 0],
      sellJitney                         |-> [i \in 1 .. 2 |-> 0],
      sellLeiCustomerAccount             |-> [i \in 1 .. 20 |-> 0],
      sellLeiAlgorithmId                 |-> [i \in 1 .. 20 |-> 0],
      sellCustomerLei                    |-> [i \in 1 .. 52 |-> 0],
      sellBrokerLei                      |-> [i \in 1 .. 20 |-> 0],
      sellLeiOrderOrigin                 |-> [i \in 1 .. 1 |-> 0],
      sellLeiRoutingArrangementIndicator |-> [i \in 1 .. 1 |-> 0],
      anonymous                          |-> [i \in 1 .. 1 |-> 0],
      reserved                           |-> [i \in 1 .. 4 |-> 0] ]

(* New Order Cross Ca Equities V 2 at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderCrossCaEquitiesV2 ==
    { ZeroNewOrderCrossCaEquitiesV2 }
        \cup { [ZeroNewOrderCrossCaEquitiesV2 EXCEPT !.brokerId = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderCrossCaEquitiesV2 EXCEPT !.crossClOrdId = one] : one \in Sample(18) }
        \cup { [ZeroNewOrderCrossCaEquitiesV2 EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossCaEquitiesV2 EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderCrossCaEquitiesV2 EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderCrossCaEquitiesV2 EXCEPT !.symbol = one] : one \in Sample(14) }
        \cup { [ZeroNewOrderCrossCaEquitiesV2 EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossCaEquitiesV2 EXCEPT !.futSettlDate = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderCrossCaEquitiesV2 EXCEPT !.umirUserId = one] : one \in Sample(12) }
        \cup { [ZeroNewOrderCrossCaEquitiesV2 EXCEPT !.basketTrade = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderCrossCaEquitiesV2 EXCEPT !.programTrade = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossCaEquitiesV2 EXCEPT !.nonResident = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossCaEquitiesV2 EXCEPT !.bypass = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossCaEquitiesV2 EXCEPT !.ncib = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossCaEquitiesV2 EXCEPT !.crossSide = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossCaEquitiesV2 EXCEPT !.shortMarkingExempt = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossCaEquitiesV2 EXCEPT !.buyUmirAccountType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossCaEquitiesV2 EXCEPT !.buyAccount = one] : one \in Sample(16) }
        \cup { [ZeroNewOrderCrossCaEquitiesV2 EXCEPT !.buyUmirRegulationId = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossCaEquitiesV2 EXCEPT !.buyJitney = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderCrossCaEquitiesV2 EXCEPT !.buyLeiCustomerAccount = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderCrossCaEquitiesV2 EXCEPT !.buyLeiAlgorithmId = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderCrossCaEquitiesV2 EXCEPT !.buyCustomerLei = one] : one \in Sample(52) }
        \cup { [ZeroNewOrderCrossCaEquitiesV2 EXCEPT !.buyBrokerLei = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderCrossCaEquitiesV2 EXCEPT !.buyLeiOrderOrigin = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossCaEquitiesV2 EXCEPT !.buyLeiRoutingArrangementIndicator = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossCaEquitiesV2 EXCEPT !.sellUmirAccountType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossCaEquitiesV2 EXCEPT !.sellAccount = one] : one \in Sample(16) }
        \cup { [ZeroNewOrderCrossCaEquitiesV2 EXCEPT !.sellUmirRegulationId = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossCaEquitiesV2 EXCEPT !.sellJitney = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderCrossCaEquitiesV2 EXCEPT !.sellLeiCustomerAccount = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderCrossCaEquitiesV2 EXCEPT !.sellLeiAlgorithmId = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderCrossCaEquitiesV2 EXCEPT !.sellCustomerLei = one] : one \in Sample(52) }
        \cup { [ZeroNewOrderCrossCaEquitiesV2 EXCEPT !.sellBrokerLei = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderCrossCaEquitiesV2 EXCEPT !.sellLeiOrderOrigin = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossCaEquitiesV2 EXCEPT !.sellLeiRoutingArrangementIndicator = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossCaEquitiesV2 EXCEPT !.anonymous = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossCaEquitiesV2 EXCEPT !.reserved = one] : one \in Sample(4) }

(***************************************************************************)
(* Firm Message, selected by Firm Message Type                             *)
(***************************************************************************)

LoginRequestMessageCode == 1  \* 0x01
LogoutRequestCode == 2  \* 0x02
ClientHeartbeatCode == 3  \* 0x03
NewOrderCaEquitiesV1Code == 6001  \* 0x1771
NewOrderCaEquitiesV2Code == 6006  \* 0x1776
ModifyOrderCaEquitiesV1Code == 6002  \* 0x1772
CancelOrderCaEquitiesV1Code == 6003  \* 0x1773
NewOrderCrossCaEquitiesV1Code == 6004  \* 0x1774
NewOrderCrossCaEquitiesV2Code == 6005  \* 0x1775

FirmMessage ==
    [ tag : {LoginRequestMessageCode}, body : LoginRequestMessage ]
        \cup [ tag : {LogoutRequestCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ClientHeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {NewOrderCaEquitiesV1Code}, body : NewOrderCaEquitiesV1 ]
        \cup [ tag : {NewOrderCaEquitiesV2Code}, body : NewOrderCaEquitiesV2 ]
        \cup [ tag : {ModifyOrderCaEquitiesV1Code}, body : ModifyOrderCaEquitiesV1 ]
        \cup [ tag : {CancelOrderCaEquitiesV1Code}, body : CancelOrderCaEquitiesV1 ]
        \cup [ tag : {NewOrderCrossCaEquitiesV1Code}, body : NewOrderCrossCaEquitiesV1 ]
        \cup [ tag : {NewOrderCrossCaEquitiesV2Code}, body : NewOrderCrossCaEquitiesV2 ]

EncodeFirmMessage(message) ==
    CASE message.tag = LoginRequestMessageCode -> EncodeLoginRequestMessage(message.body)
      [] message.tag = LogoutRequestCode -> << >>
      [] message.tag = ClientHeartbeatCode -> << >>
      [] message.tag = NewOrderCaEquitiesV1Code -> EncodeNewOrderCaEquitiesV1(message.body)
      [] message.tag = NewOrderCaEquitiesV2Code -> EncodeNewOrderCaEquitiesV2(message.body)
      [] message.tag = ModifyOrderCaEquitiesV1Code -> EncodeModifyOrderCaEquitiesV1(message.body)
      [] message.tag = CancelOrderCaEquitiesV1Code -> EncodeCancelOrderCaEquitiesV1(message.body)
      [] message.tag = NewOrderCrossCaEquitiesV1Code -> EncodeNewOrderCrossCaEquitiesV1(message.body)
      [] message.tag = NewOrderCrossCaEquitiesV2Code -> EncodeNewOrderCrossCaEquitiesV2(message.body)

DecodeFirmMessage(tag, bytes) ==
    LET read ==
            CASE tag = LoginRequestMessageCode -> DecodeLoginRequestMessage(bytes)
              [] tag = LogoutRequestCode -> Ok([empty |-> 0], bytes)
              [] tag = ClientHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = NewOrderCaEquitiesV1Code -> DecodeNewOrderCaEquitiesV1(bytes)
              [] tag = NewOrderCaEquitiesV2Code -> DecodeNewOrderCaEquitiesV2(bytes)
              [] tag = ModifyOrderCaEquitiesV1Code -> DecodeModifyOrderCaEquitiesV1(bytes)
              [] tag = CancelOrderCaEquitiesV1Code -> DecodeCancelOrderCaEquitiesV1(bytes)
              [] tag = NewOrderCrossCaEquitiesV1Code -> DecodeNewOrderCrossCaEquitiesV1(bytes)
              [] tag = NewOrderCrossCaEquitiesV2Code -> DecodeNewOrderCrossCaEquitiesV2(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroFirmMessage == [tag |-> LoginRequestMessageCode, body |-> ZeroLoginRequestMessage]

(* Each Firm Message in turn, at the values the message it names is checked at *)
CheckedFirmMessage ==
    { [tag |-> LoginRequestMessageCode, body |-> one] : one \in CheckedLoginRequestMessage }
        \cup { [tag |-> LogoutRequestCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> ClientHeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> NewOrderCaEquitiesV1Code, body |-> one] : one \in CheckedNewOrderCaEquitiesV1 }
        \cup { [tag |-> NewOrderCaEquitiesV2Code, body |-> one] : one \in CheckedNewOrderCaEquitiesV2 }
        \cup { [tag |-> ModifyOrderCaEquitiesV1Code, body |-> one] : one \in CheckedModifyOrderCaEquitiesV1 }
        \cup { [tag |-> CancelOrderCaEquitiesV1Code, body |-> one] : one \in CheckedCancelOrderCaEquitiesV1 }
        \cup { [tag |-> NewOrderCrossCaEquitiesV1Code, body |-> one] : one \in CheckedNewOrderCrossCaEquitiesV1 }
        \cup { [tag |-> NewOrderCrossCaEquitiesV2Code, body |-> one] : one \in CheckedNewOrderCrossCaEquitiesV2 }

(***************************************************************************)
(* Firm Packet                                                             *)
(***************************************************************************)

FirmPacket ==
    [ startOfMessage : Sample(2),
      messageLength  : Sample(2),
      matchingUnit   : Sample(1),
      reservedField  : Sample(1),
      sequenceNumber : Sample(4),
      firmMessage    : FirmMessage ]

EncodeFirmPacket(message) ==
    message.startOfMessage
        \o message.messageLength
        \o EncodeUIntLE(message.firmMessage.tag, 2)
        \o message.matchingUnit
        \o message.reservedField
        \o message.sequenceNumber
        \o EncodeFirmMessage(message.firmMessage)

DecodeFirmPacket(bytes) ==
    LET startOfMessage == ReadBytes(bytes, 2) IN IF ~startOfMessage.ok THEN Fail ELSE
    LET messageLength == ReadBytes(startOfMessage.rest, 2) IN IF ~messageLength.ok THEN Fail ELSE
    LET firmMessageType == ReadUIntLE(messageLength.rest, 2) IN IF ~firmMessageType.ok THEN Fail ELSE
    LET matchingUnit == ReadBytes(firmMessageType.rest, 1) IN IF ~matchingUnit.ok THEN Fail ELSE
    LET reservedField == ReadBytes(matchingUnit.rest, 1) IN IF ~reservedField.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(reservedField.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET firmMessage == DecodeFirmMessage(firmMessageType.value, sequenceNumber.rest) IN IF ~firmMessage.ok THEN Fail ELSE
    Ok([ startOfMessage |-> startOfMessage.value,
         messageLength  |-> messageLength.value,
         matchingUnit   |-> matchingUnit.value,
         reservedField  |-> reservedField.value,
         sequenceNumber |-> sequenceNumber.value,
         firmMessage    |-> firmMessage.value ], firmMessage.rest)

ZeroFirmPacket ==
    [ startOfMessage |-> [i \in 1 .. 2 |-> 0],
      messageLength  |-> [i \in 1 .. 2 |-> 0],
      matchingUnit   |-> [i \in 1 .. 1 |-> 0],
      reservedField  |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber |-> [i \in 1 .. 4 |-> 0],
      firmMessage    |-> ZeroFirmMessage ]

(* Firm Packet at zero, then each field in turn at the values it is checked at *)
CheckedFirmPacket ==
    { ZeroFirmPacket }
        \cup { [ZeroFirmPacket EXCEPT !.startOfMessage = one] : one \in Sample(2) }
        \cup { [ZeroFirmPacket EXCEPT !.messageLength = one] : one \in Sample(2) }
        \cup { [ZeroFirmPacket EXCEPT !.matchingUnit = one] : one \in Sample(1) }
        \cup { [ZeroFirmPacket EXCEPT !.reservedField = one] : one \in Sample(1) }
        \cup { [ZeroFirmPacket EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroFirmPacket EXCEPT !.firmMessage = one] : one \in CheckedFirmMessage }

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

(* Every Login Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRequestMessage ==
    \A message \in CheckedLoginRequestMessage :
        LET read == DecodeLoginRequestMessage(EncodeLoginRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Ca Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderCaEquitiesV1 ==
    \A message \in CheckedNewOrderCaEquitiesV1 :
        LET read == DecodeNewOrderCaEquitiesV1(EncodeNewOrderCaEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Ca Equities V 2 decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderCaEquitiesV2 ==
    \A message \in CheckedNewOrderCaEquitiesV2 :
        LET read == DecodeNewOrderCaEquitiesV2(EncodeNewOrderCaEquitiesV2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Order Ca Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyOrderCaEquitiesV1 ==
    \A message \in CheckedModifyOrderCaEquitiesV1 :
        LET read == DecodeModifyOrderCaEquitiesV1(EncodeModifyOrderCaEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Order Ca Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelOrderCaEquitiesV1 ==
    \A message \in CheckedCancelOrderCaEquitiesV1 :
        LET read == DecodeCancelOrderCaEquitiesV1(EncodeCancelOrderCaEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Cross Ca Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderCrossCaEquitiesV1 ==
    \A message \in CheckedNewOrderCrossCaEquitiesV1 :
        LET read == DecodeNewOrderCrossCaEquitiesV1(EncodeNewOrderCrossCaEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Cross Ca Equities V 2 decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderCrossCaEquitiesV2 ==
    \A message \in CheckedNewOrderCrossCaEquitiesV2 :
        LET read == DecodeNewOrderCrossCaEquitiesV2(EncodeNewOrderCrossCaEquitiesV2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Firm Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripFirmPacket ==
    \A message \in CheckedFirmPacket :
        LET read == DecodeFirmPacket(EncodeFirmPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Firm Message is selected by the Firm Message Type it is written under *)
SelectsFirmMessage ==
    \A message \in CheckedFirmMessage :
        LET read == DecodeFirmMessage(message.tag, EncodeFirmMessage(message))
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
