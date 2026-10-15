------------- MODULE CxaEquities_BinaryOrderEntry_v1_0_20_Firm -------------
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
(* New Order Au Equities V 1: 160 bytes                                    *)
(***************************************************************************)

NewOrderAuEquitiesV1 ==
    [ account                    : Sample(10),
      tradingParticipantId       : Sample(2),
      clOrdId                    : Sample(20),
      execInst                   : Sample(1),
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
      brokerPreferencing         : Sample(1) ]

EncodeNewOrderAuEquitiesV1(message) ==
    message.account
        \o message.tradingParticipantId
        \o message.clOrdId
        \o message.execInst
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

DecodeNewOrderAuEquitiesV1(bytes) ==
    LET account == ReadBytes(bytes, 10) IN IF ~account.ok THEN Fail ELSE
    LET tradingParticipantId == ReadBytes(account.rest, 2) IN IF ~tradingParticipantId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(tradingParticipantId.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET execInst == ReadBytes(clOrdId.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET orderQty == ReadBytes(execInst.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
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
    Ok([ account                    |-> account.value,
         tradingParticipantId       |-> tradingParticipantId.value,
         clOrdId                    |-> clOrdId.value,
         execInst                   |-> execInst.value,
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
         brokerPreferencing         |-> brokerPreferencing.value ], brokerPreferencing.rest)

ZeroNewOrderAuEquitiesV1 ==
    [ account                    |-> [i \in 1 .. 10 |-> 0],
      tradingParticipantId       |-> [i \in 1 .. 2 |-> 0],
      clOrdId                    |-> [i \in 1 .. 20 |-> 0],
      execInst                   |-> [i \in 1 .. 1 |-> 0],
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
      brokerPreferencing         |-> [i \in 1 .. 1 |-> 0] ]

(* New Order Au Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderAuEquitiesV1 ==
    { ZeroNewOrderAuEquitiesV1 }
        \cup { [ZeroNewOrderAuEquitiesV1 EXCEPT !.account = one] : one \in Sample(10) }
        \cup { [ZeroNewOrderAuEquitiesV1 EXCEPT !.tradingParticipantId = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderAuEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderAuEquitiesV1 EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAuEquitiesV1 EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderAuEquitiesV1 EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAuEquitiesV1 EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderAuEquitiesV1 EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAuEquitiesV1 EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAuEquitiesV1 EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroNewOrderAuEquitiesV1 EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAuEquitiesV1 EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderAuEquitiesV1 EXCEPT !.maxFloor = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderAuEquitiesV1 EXCEPT !.expireTime = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderAuEquitiesV1 EXCEPT !.clearingParticipantId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderAuEquitiesV1 EXCEPT !.clearingAccount = one] : one \in Sample(10) }
        \cup { [ZeroNewOrderAuEquitiesV1 EXCEPT !.undisclosed = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAuEquitiesV1 EXCEPT !.clientCrossRef = one] : one \in Sample(15) }
        \cup { [ZeroNewOrderAuEquitiesV1 EXCEPT !.shortSellNakedQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderAuEquitiesV1 EXCEPT !.shortSellCoveredQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderAuEquitiesV1 EXCEPT !.shortSellLongQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderAuEquitiesV1 EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderAuEquitiesV1 EXCEPT !.noTradeFeat = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAuEquitiesV1 EXCEPT !.noTradeKey = one] : one \in Sample(10) }
        \cup { [ZeroNewOrderAuEquitiesV1 EXCEPT !.meqse = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAuEquitiesV1 EXCEPT !.originOfTrans = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderAuEquitiesV1 EXCEPT !.intermediaryId = one] : one \in Sample(10) }
        \cup { [ZeroNewOrderAuEquitiesV1 EXCEPT !.directedWholesaleIndicator = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAuEquitiesV1 EXCEPT !.removeCrossingFromClearing = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAuEquitiesV1 EXCEPT !.brokerPreferencing = one] : one \in Sample(1) }

(***************************************************************************)
(* New Order Au Equities V 2: 166 bytes                                    *)
(***************************************************************************)

NewOrderAuEquitiesV2 ==
    [ account                    : Sample(10),
      tradingParticipantId       : Sample(2),
      clOrdId                    : Sample(20),
      execInst                   : Sample(1),
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

EncodeNewOrderAuEquitiesV2(message) ==
    message.account
        \o message.tradingParticipantId
        \o message.clOrdId
        \o message.execInst
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

DecodeNewOrderAuEquitiesV2(bytes) ==
    LET account == ReadBytes(bytes, 10) IN IF ~account.ok THEN Fail ELSE
    LET tradingParticipantId == ReadBytes(account.rest, 2) IN IF ~tradingParticipantId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(tradingParticipantId.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET execInst == ReadBytes(clOrdId.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET orderQty == ReadBytes(execInst.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
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
    Ok([ account                    |-> account.value,
         tradingParticipantId       |-> tradingParticipantId.value,
         clOrdId                    |-> clOrdId.value,
         execInst                   |-> execInst.value,
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

ZeroNewOrderAuEquitiesV2 ==
    [ account                    |-> [i \in 1 .. 10 |-> 0],
      tradingParticipantId       |-> [i \in 1 .. 2 |-> 0],
      clOrdId                    |-> [i \in 1 .. 20 |-> 0],
      execInst                   |-> [i \in 1 .. 1 |-> 0],
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

(* New Order Au Equities V 2 at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderAuEquitiesV2 ==
    { ZeroNewOrderAuEquitiesV2 }
        \cup { [ZeroNewOrderAuEquitiesV2 EXCEPT !.account = one] : one \in Sample(10) }
        \cup { [ZeroNewOrderAuEquitiesV2 EXCEPT !.tradingParticipantId = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderAuEquitiesV2 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderAuEquitiesV2 EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAuEquitiesV2 EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderAuEquitiesV2 EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAuEquitiesV2 EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderAuEquitiesV2 EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAuEquitiesV2 EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAuEquitiesV2 EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroNewOrderAuEquitiesV2 EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAuEquitiesV2 EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderAuEquitiesV2 EXCEPT !.maxFloor = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderAuEquitiesV2 EXCEPT !.expireTime = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderAuEquitiesV2 EXCEPT !.clearingParticipantId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderAuEquitiesV2 EXCEPT !.clearingAccount = one] : one \in Sample(10) }
        \cup { [ZeroNewOrderAuEquitiesV2 EXCEPT !.undisclosed = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAuEquitiesV2 EXCEPT !.clientCrossRef = one] : one \in Sample(15) }
        \cup { [ZeroNewOrderAuEquitiesV2 EXCEPT !.shortSellNakedQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderAuEquitiesV2 EXCEPT !.shortSellCoveredQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderAuEquitiesV2 EXCEPT !.shortSellLongQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderAuEquitiesV2 EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderAuEquitiesV2 EXCEPT !.noTradeFeat = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAuEquitiesV2 EXCEPT !.noTradeKey = one] : one \in Sample(10) }
        \cup { [ZeroNewOrderAuEquitiesV2 EXCEPT !.meqse = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAuEquitiesV2 EXCEPT !.originOfTrans = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderAuEquitiesV2 EXCEPT !.intermediaryId = one] : one \in Sample(10) }
        \cup { [ZeroNewOrderAuEquitiesV2 EXCEPT !.directedWholesaleIndicator = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAuEquitiesV2 EXCEPT !.removeCrossingFromClearing = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAuEquitiesV2 EXCEPT !.brokerPreferencing = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAuEquitiesV2 EXCEPT !.routingInst = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAuEquitiesV2 EXCEPT !.displayIndicator = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAuEquitiesV2 EXCEPT !.expireDate = one] : one \in Sample(4) }

(***************************************************************************)
(* Modify Order Au Equities V 1: 76 bytes                                  *)
(***************************************************************************)

ModifyOrderAuEquitiesV1 ==
    [ tradingParticipantId : Sample(2),
      clOrdId              : Sample(20),
      execInst             : Sample(1),
      orderQty             : Sample(4),
      origClOrdId          : Sample(20),
      price                : Sample(8),
      minQty               : Sample(4),
      maxFloor             : Sample(4),
      shortSellNakedQty    : Sample(4),
      shortSellCoveredQty  : Sample(4),
      shortSellLongQty     : Sample(4),
      cancelOrigOnReject   : Sample(1) ]

EncodeModifyOrderAuEquitiesV1(message) ==
    message.tradingParticipantId
        \o message.clOrdId
        \o message.execInst
        \o message.orderQty
        \o message.origClOrdId
        \o message.price
        \o message.minQty
        \o message.maxFloor
        \o message.shortSellNakedQty
        \o message.shortSellCoveredQty
        \o message.shortSellLongQty
        \o message.cancelOrigOnReject

DecodeModifyOrderAuEquitiesV1(bytes) ==
    LET tradingParticipantId == ReadBytes(bytes, 2) IN IF ~tradingParticipantId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(tradingParticipantId.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET execInst == ReadBytes(clOrdId.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET orderQty == ReadBytes(execInst.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(orderQty.rest, 20) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET price == ReadBytes(origClOrdId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET minQty == ReadBytes(price.rest, 4) IN IF ~minQty.ok THEN Fail ELSE
    LET maxFloor == ReadBytes(minQty.rest, 4) IN IF ~maxFloor.ok THEN Fail ELSE
    LET shortSellNakedQty == ReadBytes(maxFloor.rest, 4) IN IF ~shortSellNakedQty.ok THEN Fail ELSE
    LET shortSellCoveredQty == ReadBytes(shortSellNakedQty.rest, 4) IN IF ~shortSellCoveredQty.ok THEN Fail ELSE
    LET shortSellLongQty == ReadBytes(shortSellCoveredQty.rest, 4) IN IF ~shortSellLongQty.ok THEN Fail ELSE
    LET cancelOrigOnReject == ReadBytes(shortSellLongQty.rest, 1) IN IF ~cancelOrigOnReject.ok THEN Fail ELSE
    Ok([ tradingParticipantId |-> tradingParticipantId.value,
         clOrdId              |-> clOrdId.value,
         execInst             |-> execInst.value,
         orderQty             |-> orderQty.value,
         origClOrdId          |-> origClOrdId.value,
         price                |-> price.value,
         minQty               |-> minQty.value,
         maxFloor             |-> maxFloor.value,
         shortSellNakedQty    |-> shortSellNakedQty.value,
         shortSellCoveredQty  |-> shortSellCoveredQty.value,
         shortSellLongQty     |-> shortSellLongQty.value,
         cancelOrigOnReject   |-> cancelOrigOnReject.value ], cancelOrigOnReject.rest)

ZeroModifyOrderAuEquitiesV1 ==
    [ tradingParticipantId |-> [i \in 1 .. 2 |-> 0],
      clOrdId              |-> [i \in 1 .. 20 |-> 0],
      execInst             |-> [i \in 1 .. 1 |-> 0],
      orderQty             |-> [i \in 1 .. 4 |-> 0],
      origClOrdId          |-> [i \in 1 .. 20 |-> 0],
      price                |-> [i \in 1 .. 8 |-> 0],
      minQty               |-> [i \in 1 .. 4 |-> 0],
      maxFloor             |-> [i \in 1 .. 4 |-> 0],
      shortSellNakedQty    |-> [i \in 1 .. 4 |-> 0],
      shortSellCoveredQty  |-> [i \in 1 .. 4 |-> 0],
      shortSellLongQty     |-> [i \in 1 .. 4 |-> 0],
      cancelOrigOnReject   |-> [i \in 1 .. 1 |-> 0] ]

(* Modify Order Au Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderAuEquitiesV1 ==
    { ZeroModifyOrderAuEquitiesV1 }
        \cup { [ZeroModifyOrderAuEquitiesV1 EXCEPT !.tradingParticipantId = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderAuEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroModifyOrderAuEquitiesV1 EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderAuEquitiesV1 EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderAuEquitiesV1 EXCEPT !.origClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroModifyOrderAuEquitiesV1 EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderAuEquitiesV1 EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderAuEquitiesV1 EXCEPT !.maxFloor = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderAuEquitiesV1 EXCEPT !.shortSellNakedQty = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderAuEquitiesV1 EXCEPT !.shortSellCoveredQty = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderAuEquitiesV1 EXCEPT !.shortSellLongQty = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderAuEquitiesV1 EXCEPT !.cancelOrigOnReject = one] : one \in Sample(1) }

(***************************************************************************)
(* Modify Order Au Equities V 2: 80 bytes                                  *)
(***************************************************************************)

ModifyOrderAuEquitiesV2 ==
    [ tradingParticipantId : Sample(2),
      clOrdId              : Sample(20),
      execInst             : Sample(1),
      orderQty             : Sample(4),
      origClOrdId          : Sample(20),
      price                : Sample(8),
      minQty               : Sample(4),
      maxFloor             : Sample(4),
      shortSellNakedQty    : Sample(4),
      shortSellCoveredQty  : Sample(4),
      shortSellLongQty     : Sample(4),
      cancelOrigOnReject   : Sample(1),
      expireDate           : Sample(4) ]

EncodeModifyOrderAuEquitiesV2(message) ==
    message.tradingParticipantId
        \o message.clOrdId
        \o message.execInst
        \o message.orderQty
        \o message.origClOrdId
        \o message.price
        \o message.minQty
        \o message.maxFloor
        \o message.shortSellNakedQty
        \o message.shortSellCoveredQty
        \o message.shortSellLongQty
        \o message.cancelOrigOnReject
        \o message.expireDate

DecodeModifyOrderAuEquitiesV2(bytes) ==
    LET tradingParticipantId == ReadBytes(bytes, 2) IN IF ~tradingParticipantId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(tradingParticipantId.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET execInst == ReadBytes(clOrdId.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET orderQty == ReadBytes(execInst.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(orderQty.rest, 20) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET price == ReadBytes(origClOrdId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET minQty == ReadBytes(price.rest, 4) IN IF ~minQty.ok THEN Fail ELSE
    LET maxFloor == ReadBytes(minQty.rest, 4) IN IF ~maxFloor.ok THEN Fail ELSE
    LET shortSellNakedQty == ReadBytes(maxFloor.rest, 4) IN IF ~shortSellNakedQty.ok THEN Fail ELSE
    LET shortSellCoveredQty == ReadBytes(shortSellNakedQty.rest, 4) IN IF ~shortSellCoveredQty.ok THEN Fail ELSE
    LET shortSellLongQty == ReadBytes(shortSellCoveredQty.rest, 4) IN IF ~shortSellLongQty.ok THEN Fail ELSE
    LET cancelOrigOnReject == ReadBytes(shortSellLongQty.rest, 1) IN IF ~cancelOrigOnReject.ok THEN Fail ELSE
    LET expireDate == ReadBytes(cancelOrigOnReject.rest, 4) IN IF ~expireDate.ok THEN Fail ELSE
    Ok([ tradingParticipantId |-> tradingParticipantId.value,
         clOrdId              |-> clOrdId.value,
         execInst             |-> execInst.value,
         orderQty             |-> orderQty.value,
         origClOrdId          |-> origClOrdId.value,
         price                |-> price.value,
         minQty               |-> minQty.value,
         maxFloor             |-> maxFloor.value,
         shortSellNakedQty    |-> shortSellNakedQty.value,
         shortSellCoveredQty  |-> shortSellCoveredQty.value,
         shortSellLongQty     |-> shortSellLongQty.value,
         cancelOrigOnReject   |-> cancelOrigOnReject.value,
         expireDate           |-> expireDate.value ], expireDate.rest)

ZeroModifyOrderAuEquitiesV2 ==
    [ tradingParticipantId |-> [i \in 1 .. 2 |-> 0],
      clOrdId              |-> [i \in 1 .. 20 |-> 0],
      execInst             |-> [i \in 1 .. 1 |-> 0],
      orderQty             |-> [i \in 1 .. 4 |-> 0],
      origClOrdId          |-> [i \in 1 .. 20 |-> 0],
      price                |-> [i \in 1 .. 8 |-> 0],
      minQty               |-> [i \in 1 .. 4 |-> 0],
      maxFloor             |-> [i \in 1 .. 4 |-> 0],
      shortSellNakedQty    |-> [i \in 1 .. 4 |-> 0],
      shortSellCoveredQty  |-> [i \in 1 .. 4 |-> 0],
      shortSellLongQty     |-> [i \in 1 .. 4 |-> 0],
      cancelOrigOnReject   |-> [i \in 1 .. 1 |-> 0],
      expireDate           |-> [i \in 1 .. 4 |-> 0] ]

(* Modify Order Au Equities V 2 at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderAuEquitiesV2 ==
    { ZeroModifyOrderAuEquitiesV2 }
        \cup { [ZeroModifyOrderAuEquitiesV2 EXCEPT !.tradingParticipantId = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderAuEquitiesV2 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroModifyOrderAuEquitiesV2 EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderAuEquitiesV2 EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderAuEquitiesV2 EXCEPT !.origClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroModifyOrderAuEquitiesV2 EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderAuEquitiesV2 EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderAuEquitiesV2 EXCEPT !.maxFloor = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderAuEquitiesV2 EXCEPT !.shortSellNakedQty = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderAuEquitiesV2 EXCEPT !.shortSellCoveredQty = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderAuEquitiesV2 EXCEPT !.shortSellLongQty = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderAuEquitiesV2 EXCEPT !.cancelOrigOnReject = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderAuEquitiesV2 EXCEPT !.expireDate = one] : one \in Sample(4) }

(***************************************************************************)
(* Cancel Order Au Equities V 1: 22 bytes                                  *)
(***************************************************************************)

CancelOrderAuEquitiesV1 ==
    [ tradingParticipantId : Sample(2),
      origClOrdId          : Sample(20) ]

EncodeCancelOrderAuEquitiesV1(message) ==
    message.tradingParticipantId
        \o message.origClOrdId

DecodeCancelOrderAuEquitiesV1(bytes) ==
    LET tradingParticipantId == ReadBytes(bytes, 2) IN IF ~tradingParticipantId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(tradingParticipantId.rest, 20) IN IF ~origClOrdId.ok THEN Fail ELSE
    Ok([ tradingParticipantId |-> tradingParticipantId.value,
         origClOrdId          |-> origClOrdId.value ], origClOrdId.rest)

ZeroCancelOrderAuEquitiesV1 ==
    [ tradingParticipantId |-> [i \in 1 .. 2 |-> 0],
      origClOrdId          |-> [i \in 1 .. 20 |-> 0] ]

(* Cancel Order Au Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedCancelOrderAuEquitiesV1 ==
    { ZeroCancelOrderAuEquitiesV1 }
        \cup { [ZeroCancelOrderAuEquitiesV1 EXCEPT !.tradingParticipantId = one] : one \in Sample(2) }
        \cup { [ZeroCancelOrderAuEquitiesV1 EXCEPT !.origClOrdId = one] : one \in Sample(20) }

(***************************************************************************)
(* Purge Orders Au Equities V 1: 48 bytes                                  *)
(***************************************************************************)

PurgeOrdersAuEquitiesV1 ==
    [ tradingParticipantId : Sample(2),
      massCancelInst       : Sample(16),
      massCancelId         : Sample(20),
      symbol               : Sample(6),
      targetMatchingUnit   : Sample(1),
      riskGroupIdCnt       : 0 .. 255,
      riskGroupId          : Sample(2) ]

EncodePurgeOrdersAuEquitiesV1(message) ==
    message.tradingParticipantId
        \o message.massCancelInst
        \o message.massCancelId
        \o message.symbol
        \o message.targetMatchingUnit
        \o EncodeUIntLE(message.riskGroupIdCnt, 1)
        \o message.riskGroupId

DecodePurgeOrdersAuEquitiesV1(bytes) ==
    LET tradingParticipantId == ReadBytes(bytes, 2) IN IF ~tradingParticipantId.ok THEN Fail ELSE
    LET massCancelInst == ReadBytes(tradingParticipantId.rest, 16) IN IF ~massCancelInst.ok THEN Fail ELSE
    LET massCancelId == ReadBytes(massCancelInst.rest, 20) IN IF ~massCancelId.ok THEN Fail ELSE
    LET symbol == ReadBytes(massCancelId.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET targetMatchingUnit == ReadBytes(symbol.rest, 1) IN IF ~targetMatchingUnit.ok THEN Fail ELSE
    LET riskGroupIdCnt == ReadUIntLE(targetMatchingUnit.rest, 1) IN IF ~riskGroupIdCnt.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(riskGroupIdCnt.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    Ok([ tradingParticipantId |-> tradingParticipantId.value,
         massCancelInst       |-> massCancelInst.value,
         massCancelId         |-> massCancelId.value,
         symbol               |-> symbol.value,
         targetMatchingUnit   |-> targetMatchingUnit.value,
         riskGroupIdCnt       |-> riskGroupIdCnt.value,
         riskGroupId          |-> riskGroupId.value ], riskGroupId.rest)

ZeroPurgeOrdersAuEquitiesV1 ==
    [ tradingParticipantId |-> [i \in 1 .. 2 |-> 0],
      massCancelInst       |-> [i \in 1 .. 16 |-> 0],
      massCancelId         |-> [i \in 1 .. 20 |-> 0],
      symbol               |-> [i \in 1 .. 6 |-> 0],
      targetMatchingUnit   |-> [i \in 1 .. 1 |-> 0],
      riskGroupIdCnt       |-> 0,
      riskGroupId          |-> [i \in 1 .. 2 |-> 0] ]

(* Purge Orders Au Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedPurgeOrdersAuEquitiesV1 ==
    { ZeroPurgeOrdersAuEquitiesV1 }
        \cup { [ZeroPurgeOrdersAuEquitiesV1 EXCEPT !.tradingParticipantId = one] : one \in Sample(2) }
        \cup { [ZeroPurgeOrdersAuEquitiesV1 EXCEPT !.massCancelInst = one] : one \in Sample(16) }
        \cup { [ZeroPurgeOrdersAuEquitiesV1 EXCEPT !.massCancelId = one] : one \in Sample(20) }
        \cup { [ZeroPurgeOrdersAuEquitiesV1 EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroPurgeOrdersAuEquitiesV1 EXCEPT !.targetMatchingUnit = one] : one \in Sample(1) }
        \cup { [ZeroPurgeOrdersAuEquitiesV1 EXCEPT !.riskGroupIdCnt = one] : one \in {0, 1, 255} }
        \cup { [ZeroPurgeOrdersAuEquitiesV1 EXCEPT !.riskGroupId = one] : one \in Sample(2) }

(***************************************************************************)
(* Firm Message, selected by Firm Message Type                             *)
(***************************************************************************)

LoginRequestMessageCode == 1  \* 0x01
LogoutRequestCode == 2  \* 0x02
ClientHeartbeatCode == 3  \* 0x03
NewOrderAuEquitiesV1Code == 3001  \* 0xbb9
NewOrderAuEquitiesV2Code == 3005  \* 0xbbd
ModifyOrderAuEquitiesV1Code == 3002  \* 0xbba
ModifyOrderAuEquitiesV2Code == 3006  \* 0xbbe
CancelOrderAuEquitiesV1Code == 3003  \* 0xbbb
PurgeOrdersAuEquitiesV1Code == 3004  \* 0xbbc

FirmMessage ==
    [ tag : {LoginRequestMessageCode}, body : LoginRequestMessage ]
        \cup [ tag : {LogoutRequestCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ClientHeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {NewOrderAuEquitiesV1Code}, body : NewOrderAuEquitiesV1 ]
        \cup [ tag : {NewOrderAuEquitiesV2Code}, body : NewOrderAuEquitiesV2 ]
        \cup [ tag : {ModifyOrderAuEquitiesV1Code}, body : ModifyOrderAuEquitiesV1 ]
        \cup [ tag : {ModifyOrderAuEquitiesV2Code}, body : ModifyOrderAuEquitiesV2 ]
        \cup [ tag : {CancelOrderAuEquitiesV1Code}, body : CancelOrderAuEquitiesV1 ]
        \cup [ tag : {PurgeOrdersAuEquitiesV1Code}, body : PurgeOrdersAuEquitiesV1 ]

EncodeFirmMessage(message) ==
    CASE message.tag = LoginRequestMessageCode -> EncodeLoginRequestMessage(message.body)
      [] message.tag = LogoutRequestCode -> << >>
      [] message.tag = ClientHeartbeatCode -> << >>
      [] message.tag = NewOrderAuEquitiesV1Code -> EncodeNewOrderAuEquitiesV1(message.body)
      [] message.tag = NewOrderAuEquitiesV2Code -> EncodeNewOrderAuEquitiesV2(message.body)
      [] message.tag = ModifyOrderAuEquitiesV1Code -> EncodeModifyOrderAuEquitiesV1(message.body)
      [] message.tag = ModifyOrderAuEquitiesV2Code -> EncodeModifyOrderAuEquitiesV2(message.body)
      [] message.tag = CancelOrderAuEquitiesV1Code -> EncodeCancelOrderAuEquitiesV1(message.body)
      [] message.tag = PurgeOrdersAuEquitiesV1Code -> EncodePurgeOrdersAuEquitiesV1(message.body)

DecodeFirmMessage(tag, bytes) ==
    LET read ==
            CASE tag = LoginRequestMessageCode -> DecodeLoginRequestMessage(bytes)
              [] tag = LogoutRequestCode -> Ok([empty |-> 0], bytes)
              [] tag = ClientHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = NewOrderAuEquitiesV1Code -> DecodeNewOrderAuEquitiesV1(bytes)
              [] tag = NewOrderAuEquitiesV2Code -> DecodeNewOrderAuEquitiesV2(bytes)
              [] tag = ModifyOrderAuEquitiesV1Code -> DecodeModifyOrderAuEquitiesV1(bytes)
              [] tag = ModifyOrderAuEquitiesV2Code -> DecodeModifyOrderAuEquitiesV2(bytes)
              [] tag = CancelOrderAuEquitiesV1Code -> DecodeCancelOrderAuEquitiesV1(bytes)
              [] tag = PurgeOrdersAuEquitiesV1Code -> DecodePurgeOrdersAuEquitiesV1(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroFirmMessage == [tag |-> LoginRequestMessageCode, body |-> ZeroLoginRequestMessage]

(* Each Firm Message in turn, at the values the message it names is checked at *)
CheckedFirmMessage ==
    { [tag |-> LoginRequestMessageCode, body |-> one] : one \in CheckedLoginRequestMessage }
        \cup { [tag |-> LogoutRequestCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> ClientHeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> NewOrderAuEquitiesV1Code, body |-> one] : one \in CheckedNewOrderAuEquitiesV1 }
        \cup { [tag |-> NewOrderAuEquitiesV2Code, body |-> one] : one \in CheckedNewOrderAuEquitiesV2 }
        \cup { [tag |-> ModifyOrderAuEquitiesV1Code, body |-> one] : one \in CheckedModifyOrderAuEquitiesV1 }
        \cup { [tag |-> ModifyOrderAuEquitiesV2Code, body |-> one] : one \in CheckedModifyOrderAuEquitiesV2 }
        \cup { [tag |-> CancelOrderAuEquitiesV1Code, body |-> one] : one \in CheckedCancelOrderAuEquitiesV1 }
        \cup { [tag |-> PurgeOrdersAuEquitiesV1Code, body |-> one] : one \in CheckedPurgeOrdersAuEquitiesV1 }

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

(* Every New Order Au Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderAuEquitiesV1 ==
    \A message \in CheckedNewOrderAuEquitiesV1 :
        LET read == DecodeNewOrderAuEquitiesV1(EncodeNewOrderAuEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Au Equities V 2 decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderAuEquitiesV2 ==
    \A message \in CheckedNewOrderAuEquitiesV2 :
        LET read == DecodeNewOrderAuEquitiesV2(EncodeNewOrderAuEquitiesV2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Order Au Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyOrderAuEquitiesV1 ==
    \A message \in CheckedModifyOrderAuEquitiesV1 :
        LET read == DecodeModifyOrderAuEquitiesV1(EncodeModifyOrderAuEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Order Au Equities V 2 decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyOrderAuEquitiesV2 ==
    \A message \in CheckedModifyOrderAuEquitiesV2 :
        LET read == DecodeModifyOrderAuEquitiesV2(EncodeModifyOrderAuEquitiesV2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Order Au Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelOrderAuEquitiesV1 ==
    \A message \in CheckedCancelOrderAuEquitiesV1 :
        LET read == DecodeCancelOrderAuEquitiesV1(EncodeCancelOrderAuEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Purge Orders Au Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripPurgeOrdersAuEquitiesV1 ==
    \A message \in CheckedPurgeOrdersAuEquitiesV1 :
        LET read == DecodePurgeOrdersAuEquitiesV1(EncodePurgeOrdersAuEquitiesV1(message))
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
