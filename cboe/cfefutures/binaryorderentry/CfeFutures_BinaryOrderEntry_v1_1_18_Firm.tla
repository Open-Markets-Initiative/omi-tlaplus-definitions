------------- MODULE CfeFutures_BinaryOrderEntry_v1_1_18_Firm --------------
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
(* New Order: 131 bytes                                                    *)
(***************************************************************************)

NewOrder ==
    [ clOrdId               : Sample(20),
      side                  : Sample(1),
      orderQty              : Sample(4),
      clearingFirm          : Sample(4),
      clearingAccount       : Sample(4),
      price                 : Sample(8),
      ordType               : Sample(1),
      timeInForce           : Sample(1),
      minQty                : Sample(4),
      symbol                : Sample(8),
      capacity              : Sample(1),
      account               : Sample(16),
      preventMatch          : PreventMatch,
      expireTime            : Sample(8),
      maturityDate          : Sample(4),
      openClose             : Sample(1),
      cmtaNumber            : Sample(4),
      stopPx                : Sample(8),
      customGroupId         : Sample(2),
      ctiCode               : Sample(1),
      manualOrderIndicator  : Sample(1),
      oeoId                 : Sample(18),
      frequentTraderId      : Sample(6),
      custOrderHandlingInst : Sample(1),
      countryCode           : Sample(2) ]

EncodeNewOrder(message) ==
    message.clOrdId
        \o message.side
        \o message.orderQty
        \o message.clearingFirm
        \o message.clearingAccount
        \o message.price
        \o message.ordType
        \o message.timeInForce
        \o message.minQty
        \o message.symbol
        \o message.capacity
        \o message.account
        \o EncodePreventMatch(message.preventMatch)
        \o message.expireTime
        \o message.maturityDate
        \o message.openClose
        \o message.cmtaNumber
        \o message.stopPx
        \o message.customGroupId
        \o message.ctiCode
        \o message.manualOrderIndicator
        \o message.oeoId
        \o message.frequentTraderId
        \o message.custOrderHandlingInst
        \o message.countryCode

DecodeNewOrder(bytes) ==
    LET clOrdId == ReadBytes(bytes, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET side == ReadBytes(clOrdId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderQty == ReadBytes(side.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(orderQty.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadBytes(clearingFirm.rest, 4) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET price == ReadBytes(clearingAccount.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET ordType == ReadBytes(price.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(ordType.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadBytes(timeInForce.rest, 4) IN IF ~minQty.ok THEN Fail ELSE
    LET symbol == ReadBytes(minQty.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET capacity == ReadBytes(symbol.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadBytes(capacity.rest, 16) IN IF ~account.ok THEN Fail ELSE
    LET preventMatch == DecodePreventMatch(account.rest) IN IF ~preventMatch.ok THEN Fail ELSE
    LET expireTime == ReadBytes(preventMatch.rest, 8) IN IF ~expireTime.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(expireTime.rest, 4) IN IF ~maturityDate.ok THEN Fail ELSE
    LET openClose == ReadBytes(maturityDate.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET cmtaNumber == ReadBytes(openClose.rest, 4) IN IF ~cmtaNumber.ok THEN Fail ELSE
    LET stopPx == ReadBytes(cmtaNumber.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET customGroupId == ReadBytes(stopPx.rest, 2) IN IF ~customGroupId.ok THEN Fail ELSE
    LET ctiCode == ReadBytes(customGroupId.rest, 1) IN IF ~ctiCode.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadBytes(ctiCode.rest, 1) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET oeoId == ReadBytes(manualOrderIndicator.rest, 18) IN IF ~oeoId.ok THEN Fail ELSE
    LET frequentTraderId == ReadBytes(oeoId.rest, 6) IN IF ~frequentTraderId.ok THEN Fail ELSE
    LET custOrderHandlingInst == ReadBytes(frequentTraderId.rest, 1) IN IF ~custOrderHandlingInst.ok THEN Fail ELSE
    LET countryCode == ReadBytes(custOrderHandlingInst.rest, 2) IN IF ~countryCode.ok THEN Fail ELSE
    Ok([ clOrdId               |-> clOrdId.value,
         side                  |-> side.value,
         orderQty              |-> orderQty.value,
         clearingFirm          |-> clearingFirm.value,
         clearingAccount       |-> clearingAccount.value,
         price                 |-> price.value,
         ordType               |-> ordType.value,
         timeInForce           |-> timeInForce.value,
         minQty                |-> minQty.value,
         symbol                |-> symbol.value,
         capacity              |-> capacity.value,
         account               |-> account.value,
         preventMatch          |-> preventMatch.value,
         expireTime            |-> expireTime.value,
         maturityDate          |-> maturityDate.value,
         openClose             |-> openClose.value,
         cmtaNumber            |-> cmtaNumber.value,
         stopPx                |-> stopPx.value,
         customGroupId         |-> customGroupId.value,
         ctiCode               |-> ctiCode.value,
         manualOrderIndicator  |-> manualOrderIndicator.value,
         oeoId                 |-> oeoId.value,
         frequentTraderId      |-> frequentTraderId.value,
         custOrderHandlingInst |-> custOrderHandlingInst.value,
         countryCode           |-> countryCode.value ], countryCode.rest)

ZeroNewOrder ==
    [ clOrdId               |-> [i \in 1 .. 20 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      orderQty              |-> [i \in 1 .. 4 |-> 0],
      clearingFirm          |-> [i \in 1 .. 4 |-> 0],
      clearingAccount       |-> [i \in 1 .. 4 |-> 0],
      price                 |-> [i \in 1 .. 8 |-> 0],
      ordType               |-> [i \in 1 .. 1 |-> 0],
      timeInForce           |-> [i \in 1 .. 1 |-> 0],
      minQty                |-> [i \in 1 .. 4 |-> 0],
      symbol                |-> [i \in 1 .. 8 |-> 0],
      capacity              |-> [i \in 1 .. 1 |-> 0],
      account               |-> [i \in 1 .. 16 |-> 0],
      preventMatch          |-> ZeroPreventMatch,
      expireTime            |-> [i \in 1 .. 8 |-> 0],
      maturityDate          |-> [i \in 1 .. 4 |-> 0],
      openClose             |-> [i \in 1 .. 1 |-> 0],
      cmtaNumber            |-> [i \in 1 .. 4 |-> 0],
      stopPx                |-> [i \in 1 .. 8 |-> 0],
      customGroupId         |-> [i \in 1 .. 2 |-> 0],
      ctiCode               |-> [i \in 1 .. 1 |-> 0],
      manualOrderIndicator  |-> [i \in 1 .. 1 |-> 0],
      oeoId                 |-> [i \in 1 .. 18 |-> 0],
      frequentTraderId      |-> [i \in 1 .. 6 |-> 0],
      custOrderHandlingInst |-> [i \in 1 .. 1 |-> 0],
      countryCode           |-> [i \in 1 .. 2 |-> 0] ]

(* New Order at zero, then each field in turn at the values it is checked at *)
CheckedNewOrder ==
    { ZeroNewOrder }
        \cup { [ZeroNewOrder EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroNewOrder EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewOrder EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrder EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroNewOrder EXCEPT !.clearingAccount = one] : one \in Sample(4) }
        \cup { [ZeroNewOrder EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrder EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrder EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroNewOrder EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrder EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroNewOrder EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroNewOrder EXCEPT !.account = one] : one \in Sample(16) }
        \cup { [ZeroNewOrder EXCEPT !.preventMatch = one] : one \in CheckedPreventMatch }
        \cup { [ZeroNewOrder EXCEPT !.expireTime = one] : one \in Sample(8) }
        \cup { [ZeroNewOrder EXCEPT !.maturityDate = one] : one \in Sample(4) }
        \cup { [ZeroNewOrder EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroNewOrder EXCEPT !.cmtaNumber = one] : one \in Sample(4) }
        \cup { [ZeroNewOrder EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroNewOrder EXCEPT !.customGroupId = one] : one \in Sample(2) }
        \cup { [ZeroNewOrder EXCEPT !.ctiCode = one] : one \in Sample(1) }
        \cup { [ZeroNewOrder EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroNewOrder EXCEPT !.oeoId = one] : one \in Sample(18) }
        \cup { [ZeroNewOrder EXCEPT !.frequentTraderId = one] : one \in Sample(6) }
        \cup { [ZeroNewOrder EXCEPT !.custOrderHandlingInst = one] : one \in Sample(1) }
        \cup { [ZeroNewOrder EXCEPT !.countryCode = one] : one \in Sample(2) }

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
(* New Order Option: 133 bytes                                             *)
(***************************************************************************)

NewOrderOption ==
    [ clOrdId               : Sample(20),
      side                  : Sample(1),
      orderQty              : Sample(4),
      clearingFirm          : Sample(4),
      clearingAccount       : Sample(4),
      price                 : Sample(8),
      ordType               : Sample(1),
      timeInForce           : Sample(1),
      symbol                : Sample(8),
      securityDesc          : Sample(16),
      capacity              : Sample(1),
      account               : Sample(16),
      preventMatch          : PreventMatch2,
      expireTime            : Sample(8),
      openClose             : Sample(1),
      cmtaNumber            : Sample(4),
      customGroupId         : Sample(2),
      ctiCode               : Sample(1),
      manualOrderIndicator  : Sample(1),
      oeoId                 : Sample(18),
      frequentTraderId      : Sample(6),
      custOrderHandlingInst : Sample(1),
      countryCode           : Sample(2),
      legCnt                : 0 .. 255,
      legPositionEffect     : Sample(1) ]

EncodeNewOrderOption(message) ==
    message.clOrdId
        \o message.side
        \o message.orderQty
        \o message.clearingFirm
        \o message.clearingAccount
        \o message.price
        \o message.ordType
        \o message.timeInForce
        \o message.symbol
        \o message.securityDesc
        \o message.capacity
        \o message.account
        \o EncodePreventMatch2(message.preventMatch)
        \o message.expireTime
        \o message.openClose
        \o message.cmtaNumber
        \o message.customGroupId
        \o message.ctiCode
        \o message.manualOrderIndicator
        \o message.oeoId
        \o message.frequentTraderId
        \o message.custOrderHandlingInst
        \o message.countryCode
        \o EncodeUIntLE(message.legCnt, 1)
        \o message.legPositionEffect

DecodeNewOrderOption(bytes) ==
    LET clOrdId == ReadBytes(bytes, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET side == ReadBytes(clOrdId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderQty == ReadBytes(side.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(orderQty.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadBytes(clearingFirm.rest, 4) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET price == ReadBytes(clearingAccount.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET ordType == ReadBytes(price.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(ordType.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET symbol == ReadBytes(timeInForce.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET securityDesc == ReadBytes(symbol.rest, 16) IN IF ~securityDesc.ok THEN Fail ELSE
    LET capacity == ReadBytes(securityDesc.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadBytes(capacity.rest, 16) IN IF ~account.ok THEN Fail ELSE
    LET preventMatch == DecodePreventMatch2(account.rest) IN IF ~preventMatch.ok THEN Fail ELSE
    LET expireTime == ReadBytes(preventMatch.rest, 8) IN IF ~expireTime.ok THEN Fail ELSE
    LET openClose == ReadBytes(expireTime.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET cmtaNumber == ReadBytes(openClose.rest, 4) IN IF ~cmtaNumber.ok THEN Fail ELSE
    LET customGroupId == ReadBytes(cmtaNumber.rest, 2) IN IF ~customGroupId.ok THEN Fail ELSE
    LET ctiCode == ReadBytes(customGroupId.rest, 1) IN IF ~ctiCode.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadBytes(ctiCode.rest, 1) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET oeoId == ReadBytes(manualOrderIndicator.rest, 18) IN IF ~oeoId.ok THEN Fail ELSE
    LET frequentTraderId == ReadBytes(oeoId.rest, 6) IN IF ~frequentTraderId.ok THEN Fail ELSE
    LET custOrderHandlingInst == ReadBytes(frequentTraderId.rest, 1) IN IF ~custOrderHandlingInst.ok THEN Fail ELSE
    LET countryCode == ReadBytes(custOrderHandlingInst.rest, 2) IN IF ~countryCode.ok THEN Fail ELSE
    LET legCnt == ReadUIntLE(countryCode.rest, 1) IN IF ~legCnt.ok THEN Fail ELSE
    LET legPositionEffect == ReadBytes(legCnt.rest, 1) IN IF ~legPositionEffect.ok THEN Fail ELSE
    Ok([ clOrdId               |-> clOrdId.value,
         side                  |-> side.value,
         orderQty              |-> orderQty.value,
         clearingFirm          |-> clearingFirm.value,
         clearingAccount       |-> clearingAccount.value,
         price                 |-> price.value,
         ordType               |-> ordType.value,
         timeInForce           |-> timeInForce.value,
         symbol                |-> symbol.value,
         securityDesc          |-> securityDesc.value,
         capacity              |-> capacity.value,
         account               |-> account.value,
         preventMatch          |-> preventMatch.value,
         expireTime            |-> expireTime.value,
         openClose             |-> openClose.value,
         cmtaNumber            |-> cmtaNumber.value,
         customGroupId         |-> customGroupId.value,
         ctiCode               |-> ctiCode.value,
         manualOrderIndicator  |-> manualOrderIndicator.value,
         oeoId                 |-> oeoId.value,
         frequentTraderId      |-> frequentTraderId.value,
         custOrderHandlingInst |-> custOrderHandlingInst.value,
         countryCode           |-> countryCode.value,
         legCnt                |-> legCnt.value,
         legPositionEffect     |-> legPositionEffect.value ], legPositionEffect.rest)

ZeroNewOrderOption ==
    [ clOrdId               |-> [i \in 1 .. 20 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      orderQty              |-> [i \in 1 .. 4 |-> 0],
      clearingFirm          |-> [i \in 1 .. 4 |-> 0],
      clearingAccount       |-> [i \in 1 .. 4 |-> 0],
      price                 |-> [i \in 1 .. 8 |-> 0],
      ordType               |-> [i \in 1 .. 1 |-> 0],
      timeInForce           |-> [i \in 1 .. 1 |-> 0],
      symbol                |-> [i \in 1 .. 8 |-> 0],
      securityDesc          |-> [i \in 1 .. 16 |-> 0],
      capacity              |-> [i \in 1 .. 1 |-> 0],
      account               |-> [i \in 1 .. 16 |-> 0],
      preventMatch          |-> ZeroPreventMatch2,
      expireTime            |-> [i \in 1 .. 8 |-> 0],
      openClose             |-> [i \in 1 .. 1 |-> 0],
      cmtaNumber            |-> [i \in 1 .. 4 |-> 0],
      customGroupId         |-> [i \in 1 .. 2 |-> 0],
      ctiCode               |-> [i \in 1 .. 1 |-> 0],
      manualOrderIndicator  |-> [i \in 1 .. 1 |-> 0],
      oeoId                 |-> [i \in 1 .. 18 |-> 0],
      frequentTraderId      |-> [i \in 1 .. 6 |-> 0],
      custOrderHandlingInst |-> [i \in 1 .. 1 |-> 0],
      countryCode           |-> [i \in 1 .. 2 |-> 0],
      legCnt                |-> 0,
      legPositionEffect     |-> [i \in 1 .. 1 |-> 0] ]

(* New Order Option at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderOption ==
    { ZeroNewOrderOption }
        \cup { [ZeroNewOrderOption EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderOption EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderOption EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderOption EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderOption EXCEPT !.clearingAccount = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderOption EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderOption EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderOption EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderOption EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderOption EXCEPT !.securityDesc = one] : one \in Sample(16) }
        \cup { [ZeroNewOrderOption EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderOption EXCEPT !.account = one] : one \in Sample(16) }
        \cup { [ZeroNewOrderOption EXCEPT !.preventMatch = one] : one \in CheckedPreventMatch2 }
        \cup { [ZeroNewOrderOption EXCEPT !.expireTime = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderOption EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderOption EXCEPT !.cmtaNumber = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderOption EXCEPT !.customGroupId = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderOption EXCEPT !.ctiCode = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderOption EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderOption EXCEPT !.oeoId = one] : one \in Sample(18) }
        \cup { [ZeroNewOrderOption EXCEPT !.frequentTraderId = one] : one \in Sample(6) }
        \cup { [ZeroNewOrderOption EXCEPT !.custOrderHandlingInst = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderOption EXCEPT !.countryCode = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderOption EXCEPT !.legCnt = one] : one \in {0, 1, 255} }
        \cup { [ZeroNewOrderOption EXCEPT !.legPositionEffect = one] : one \in Sample(1) }

(***************************************************************************)
(* Modify Order: 92 bytes                                                  *)
(***************************************************************************)

ModifyOrder ==
    [ clOrdId               : Sample(20),
      origClOrdId           : Sample(20),
      clearingFirm          : Sample(4),
      orderQty              : Sample(4),
      price                 : Sample(8),
      ordType               : Sample(1),
      cancelOrigOnReject    : Sample(1),
      stopPx                : Sample(8),
      manualOrderIndicator  : Sample(1),
      oeoId                 : Sample(18),
      frequentTraderId      : Sample(6),
      custOrderHandlingInst : Sample(1) ]

EncodeModifyOrder(message) ==
    message.clOrdId
        \o message.origClOrdId
        \o message.clearingFirm
        \o message.orderQty
        \o message.price
        \o message.ordType
        \o message.cancelOrigOnReject
        \o message.stopPx
        \o message.manualOrderIndicator
        \o message.oeoId
        \o message.frequentTraderId
        \o message.custOrderHandlingInst

DecodeModifyOrder(bytes) ==
    LET clOrdId == ReadBytes(bytes, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 20) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(origClOrdId.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET orderQty == ReadBytes(clearingFirm.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET price == ReadBytes(orderQty.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET ordType == ReadBytes(price.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET cancelOrigOnReject == ReadBytes(ordType.rest, 1) IN IF ~cancelOrigOnReject.ok THEN Fail ELSE
    LET stopPx == ReadBytes(cancelOrigOnReject.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadBytes(stopPx.rest, 1) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET oeoId == ReadBytes(manualOrderIndicator.rest, 18) IN IF ~oeoId.ok THEN Fail ELSE
    LET frequentTraderId == ReadBytes(oeoId.rest, 6) IN IF ~frequentTraderId.ok THEN Fail ELSE
    LET custOrderHandlingInst == ReadBytes(frequentTraderId.rest, 1) IN IF ~custOrderHandlingInst.ok THEN Fail ELSE
    Ok([ clOrdId               |-> clOrdId.value,
         origClOrdId           |-> origClOrdId.value,
         clearingFirm          |-> clearingFirm.value,
         orderQty              |-> orderQty.value,
         price                 |-> price.value,
         ordType               |-> ordType.value,
         cancelOrigOnReject    |-> cancelOrigOnReject.value,
         stopPx                |-> stopPx.value,
         manualOrderIndicator  |-> manualOrderIndicator.value,
         oeoId                 |-> oeoId.value,
         frequentTraderId      |-> frequentTraderId.value,
         custOrderHandlingInst |-> custOrderHandlingInst.value ], custOrderHandlingInst.rest)

ZeroModifyOrder ==
    [ clOrdId               |-> [i \in 1 .. 20 |-> 0],
      origClOrdId           |-> [i \in 1 .. 20 |-> 0],
      clearingFirm          |-> [i \in 1 .. 4 |-> 0],
      orderQty              |-> [i \in 1 .. 4 |-> 0],
      price                 |-> [i \in 1 .. 8 |-> 0],
      ordType               |-> [i \in 1 .. 1 |-> 0],
      cancelOrigOnReject    |-> [i \in 1 .. 1 |-> 0],
      stopPx                |-> [i \in 1 .. 8 |-> 0],
      manualOrderIndicator  |-> [i \in 1 .. 1 |-> 0],
      oeoId                 |-> [i \in 1 .. 18 |-> 0],
      frequentTraderId      |-> [i \in 1 .. 6 |-> 0],
      custOrderHandlingInst |-> [i \in 1 .. 1 |-> 0] ]

(* Modify Order at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrder ==
    { ZeroModifyOrder }
        \cup { [ZeroModifyOrder EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroModifyOrder EXCEPT !.origClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroModifyOrder EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrder EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrder EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrder EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrder EXCEPT !.cancelOrigOnReject = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrder EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrder EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrder EXCEPT !.oeoId = one] : one \in Sample(18) }
        \cup { [ZeroModifyOrder EXCEPT !.frequentTraderId = one] : one \in Sample(6) }
        \cup { [ZeroModifyOrder EXCEPT !.custOrderHandlingInst = one] : one \in Sample(1) }

(***************************************************************************)
(* Cancel Order: 43 bytes                                                  *)
(***************************************************************************)

CancelOrder ==
    [ origClOrdId          : Sample(20),
      clearingFirm         : Sample(4),
      manualOrderIndicator : Sample(1),
      oeoId                : Sample(18) ]

EncodeCancelOrder(message) ==
    message.origClOrdId
        \o message.clearingFirm
        \o message.manualOrderIndicator
        \o message.oeoId

DecodeCancelOrder(bytes) ==
    LET origClOrdId == ReadBytes(bytes, 20) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(origClOrdId.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadBytes(clearingFirm.rest, 1) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET oeoId == ReadBytes(manualOrderIndicator.rest, 18) IN IF ~oeoId.ok THEN Fail ELSE
    Ok([ origClOrdId          |-> origClOrdId.value,
         clearingFirm         |-> clearingFirm.value,
         manualOrderIndicator |-> manualOrderIndicator.value,
         oeoId                |-> oeoId.value ], oeoId.rest)

ZeroCancelOrder ==
    [ origClOrdId          |-> [i \in 1 .. 20 |-> 0],
      clearingFirm         |-> [i \in 1 .. 4 |-> 0],
      manualOrderIndicator |-> [i \in 1 .. 1 |-> 0],
      oeoId                |-> [i \in 1 .. 18 |-> 0] ]

(* Cancel Order at zero, then each field in turn at the values it is checked at *)
CheckedCancelOrder ==
    { ZeroCancelOrder }
        \cup { [ZeroCancelOrder EXCEPT !.origClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroCancelOrder EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroCancelOrder EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroCancelOrder EXCEPT !.oeoId = one] : one \in Sample(18) }

(***************************************************************************)
(* Mass Cancel Inst: 16 bytes                                              *)
(***************************************************************************)

MassCancelInst ==
    [ clearingFirmFilter   : Sample(1),
      acknowledgementStyle : Sample(1),
      lockoutInstruction   : Sample(1),
      instrumentTypeFilter : Sample(1),
      gtcOrderFilter       : Sample(1),
      instructionDetails   : Sample(11) ]

EncodeMassCancelInst(message) ==
    message.clearingFirmFilter
        \o message.acknowledgementStyle
        \o message.lockoutInstruction
        \o message.instrumentTypeFilter
        \o message.gtcOrderFilter
        \o message.instructionDetails

DecodeMassCancelInst(bytes) ==
    LET clearingFirmFilter == ReadBytes(bytes, 1) IN IF ~clearingFirmFilter.ok THEN Fail ELSE
    LET acknowledgementStyle == ReadBytes(clearingFirmFilter.rest, 1) IN IF ~acknowledgementStyle.ok THEN Fail ELSE
    LET lockoutInstruction == ReadBytes(acknowledgementStyle.rest, 1) IN IF ~lockoutInstruction.ok THEN Fail ELSE
    LET instrumentTypeFilter == ReadBytes(lockoutInstruction.rest, 1) IN IF ~instrumentTypeFilter.ok THEN Fail ELSE
    LET gtcOrderFilter == ReadBytes(instrumentTypeFilter.rest, 1) IN IF ~gtcOrderFilter.ok THEN Fail ELSE
    LET instructionDetails == ReadBytes(gtcOrderFilter.rest, 11) IN IF ~instructionDetails.ok THEN Fail ELSE
    Ok([ clearingFirmFilter   |-> clearingFirmFilter.value,
         acknowledgementStyle |-> acknowledgementStyle.value,
         lockoutInstruction   |-> lockoutInstruction.value,
         instrumentTypeFilter |-> instrumentTypeFilter.value,
         gtcOrderFilter       |-> gtcOrderFilter.value,
         instructionDetails   |-> instructionDetails.value ], instructionDetails.rest)

ZeroMassCancelInst ==
    [ clearingFirmFilter   |-> [i \in 1 .. 1 |-> 0],
      acknowledgementStyle |-> [i \in 1 .. 1 |-> 0],
      lockoutInstruction   |-> [i \in 1 .. 1 |-> 0],
      instrumentTypeFilter |-> [i \in 1 .. 1 |-> 0],
      gtcOrderFilter       |-> [i \in 1 .. 1 |-> 0],
      instructionDetails   |-> [i \in 1 .. 11 |-> 0] ]

(* Mass Cancel Inst at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelInst ==
    { ZeroMassCancelInst }
        \cup { [ZeroMassCancelInst EXCEPT !.clearingFirmFilter = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelInst EXCEPT !.acknowledgementStyle = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelInst EXCEPT !.lockoutInstruction = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelInst EXCEPT !.instrumentTypeFilter = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelInst EXCEPT !.gtcOrderFilter = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelInst EXCEPT !.instructionDetails = one] : one \in Sample(11) }

(***************************************************************************)
(* Mass Cancel Order: 65 bytes                                             *)
(***************************************************************************)

MassCancelOrder ==
    [ massCancelId         : Sample(20),
      clearingFirm         : Sample(4),
      productName          : Sample(6),
      massCancelInst       : MassCancelInst,
      manualOrderIndicator : Sample(1),
      oeoId                : Sample(18) ]

EncodeMassCancelOrder(message) ==
    message.massCancelId
        \o message.clearingFirm
        \o message.productName
        \o EncodeMassCancelInst(message.massCancelInst)
        \o message.manualOrderIndicator
        \o message.oeoId

DecodeMassCancelOrder(bytes) ==
    LET massCancelId == ReadBytes(bytes, 20) IN IF ~massCancelId.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(massCancelId.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET productName == ReadBytes(clearingFirm.rest, 6) IN IF ~productName.ok THEN Fail ELSE
    LET massCancelInst == DecodeMassCancelInst(productName.rest) IN IF ~massCancelInst.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadBytes(massCancelInst.rest, 1) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET oeoId == ReadBytes(manualOrderIndicator.rest, 18) IN IF ~oeoId.ok THEN Fail ELSE
    Ok([ massCancelId         |-> massCancelId.value,
         clearingFirm         |-> clearingFirm.value,
         productName          |-> productName.value,
         massCancelInst       |-> massCancelInst.value,
         manualOrderIndicator |-> manualOrderIndicator.value,
         oeoId                |-> oeoId.value ], oeoId.rest)

ZeroMassCancelOrder ==
    [ massCancelId         |-> [i \in 1 .. 20 |-> 0],
      clearingFirm         |-> [i \in 1 .. 4 |-> 0],
      productName          |-> [i \in 1 .. 6 |-> 0],
      massCancelInst       |-> ZeroMassCancelInst,
      manualOrderIndicator |-> [i \in 1 .. 1 |-> 0],
      oeoId                |-> [i \in 1 .. 18 |-> 0] ]

(* Mass Cancel Order at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelOrder ==
    { ZeroMassCancelOrder }
        \cup { [ZeroMassCancelOrder EXCEPT !.massCancelId = one] : one \in Sample(20) }
        \cup { [ZeroMassCancelOrder EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroMassCancelOrder EXCEPT !.productName = one] : one \in Sample(6) }
        \cup { [ZeroMassCancelOrder EXCEPT !.massCancelInst = one] : one \in CheckedMassCancelInst }
        \cup { [ZeroMassCancelOrder EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelOrder EXCEPT !.oeoId = one] : one \in Sample(18) }

(***************************************************************************)
(* Mass Cancel Inst: 16 bytes                                              *)
(***************************************************************************)

MassCancelInst2 ==
    [ clearingFirmFilter   : Sample(1),
      acknowledgementStyle : Sample(1),
      lockoutInstruction   : Sample(1),
      instrumentTypeFilter : Sample(1),
      gtcOrderFilter       : Sample(1),
      instructionDetails   : Sample(11) ]

EncodeMassCancelInst2(message) ==
    message.clearingFirmFilter
        \o message.acknowledgementStyle
        \o message.lockoutInstruction
        \o message.instrumentTypeFilter
        \o message.gtcOrderFilter
        \o message.instructionDetails

DecodeMassCancelInst2(bytes) ==
    LET clearingFirmFilter == ReadBytes(bytes, 1) IN IF ~clearingFirmFilter.ok THEN Fail ELSE
    LET acknowledgementStyle == ReadBytes(clearingFirmFilter.rest, 1) IN IF ~acknowledgementStyle.ok THEN Fail ELSE
    LET lockoutInstruction == ReadBytes(acknowledgementStyle.rest, 1) IN IF ~lockoutInstruction.ok THEN Fail ELSE
    LET instrumentTypeFilter == ReadBytes(lockoutInstruction.rest, 1) IN IF ~instrumentTypeFilter.ok THEN Fail ELSE
    LET gtcOrderFilter == ReadBytes(instrumentTypeFilter.rest, 1) IN IF ~gtcOrderFilter.ok THEN Fail ELSE
    LET instructionDetails == ReadBytes(gtcOrderFilter.rest, 11) IN IF ~instructionDetails.ok THEN Fail ELSE
    Ok([ clearingFirmFilter   |-> clearingFirmFilter.value,
         acknowledgementStyle |-> acknowledgementStyle.value,
         lockoutInstruction   |-> lockoutInstruction.value,
         instrumentTypeFilter |-> instrumentTypeFilter.value,
         gtcOrderFilter       |-> gtcOrderFilter.value,
         instructionDetails   |-> instructionDetails.value ], instructionDetails.rest)

ZeroMassCancelInst2 ==
    [ clearingFirmFilter   |-> [i \in 1 .. 1 |-> 0],
      acknowledgementStyle |-> [i \in 1 .. 1 |-> 0],
      lockoutInstruction   |-> [i \in 1 .. 1 |-> 0],
      instrumentTypeFilter |-> [i \in 1 .. 1 |-> 0],
      gtcOrderFilter       |-> [i \in 1 .. 1 |-> 0],
      instructionDetails   |-> [i \in 1 .. 11 |-> 0] ]

(* Mass Cancel Inst at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelInst2 ==
    { ZeroMassCancelInst2 }
        \cup { [ZeroMassCancelInst2 EXCEPT !.clearingFirmFilter = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelInst2 EXCEPT !.acknowledgementStyle = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelInst2 EXCEPT !.lockoutInstruction = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelInst2 EXCEPT !.instrumentTypeFilter = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelInst2 EXCEPT !.gtcOrderFilter = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelInst2 EXCEPT !.instructionDetails = one] : one \in Sample(11) }

(***************************************************************************)
(* Purge Orders: 68 bytes                                                  *)
(***************************************************************************)

PurgeOrders ==
    [ massCancelId         : Sample(20),
      clearingFirm         : Sample(4),
      productName          : Sample(6),
      massCancelInst       : MassCancelInst2,
      manualOrderIndicator : Sample(1),
      oeoId                : Sample(18),
      customGroupIdCnt     : Sample(1),
      customGroupId        : Sample(2) ]

EncodePurgeOrders(message) ==
    message.massCancelId
        \o message.clearingFirm
        \o message.productName
        \o EncodeMassCancelInst2(message.massCancelInst)
        \o message.manualOrderIndicator
        \o message.oeoId
        \o message.customGroupIdCnt
        \o message.customGroupId

DecodePurgeOrders(bytes) ==
    LET massCancelId == ReadBytes(bytes, 20) IN IF ~massCancelId.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(massCancelId.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET productName == ReadBytes(clearingFirm.rest, 6) IN IF ~productName.ok THEN Fail ELSE
    LET massCancelInst == DecodeMassCancelInst2(productName.rest) IN IF ~massCancelInst.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadBytes(massCancelInst.rest, 1) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET oeoId == ReadBytes(manualOrderIndicator.rest, 18) IN IF ~oeoId.ok THEN Fail ELSE
    LET customGroupIdCnt == ReadBytes(oeoId.rest, 1) IN IF ~customGroupIdCnt.ok THEN Fail ELSE
    LET customGroupId == ReadBytes(customGroupIdCnt.rest, 2) IN IF ~customGroupId.ok THEN Fail ELSE
    Ok([ massCancelId         |-> massCancelId.value,
         clearingFirm         |-> clearingFirm.value,
         productName          |-> productName.value,
         massCancelInst       |-> massCancelInst.value,
         manualOrderIndicator |-> manualOrderIndicator.value,
         oeoId                |-> oeoId.value,
         customGroupIdCnt     |-> customGroupIdCnt.value,
         customGroupId        |-> customGroupId.value ], customGroupId.rest)

ZeroPurgeOrders ==
    [ massCancelId         |-> [i \in 1 .. 20 |-> 0],
      clearingFirm         |-> [i \in 1 .. 4 |-> 0],
      productName          |-> [i \in 1 .. 6 |-> 0],
      massCancelInst       |-> ZeroMassCancelInst2,
      manualOrderIndicator |-> [i \in 1 .. 1 |-> 0],
      oeoId                |-> [i \in 1 .. 18 |-> 0],
      customGroupIdCnt     |-> [i \in 1 .. 1 |-> 0],
      customGroupId        |-> [i \in 1 .. 2 |-> 0] ]

(* Purge Orders at zero, then each field in turn at the values it is checked at *)
CheckedPurgeOrders ==
    { ZeroPurgeOrders }
        \cup { [ZeroPurgeOrders EXCEPT !.massCancelId = one] : one \in Sample(20) }
        \cup { [ZeroPurgeOrders EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroPurgeOrders EXCEPT !.productName = one] : one \in Sample(6) }
        \cup { [ZeroPurgeOrders EXCEPT !.massCancelInst = one] : one \in CheckedMassCancelInst2 }
        \cup { [ZeroPurgeOrders EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPurgeOrders EXCEPT !.oeoId = one] : one \in Sample(18) }
        \cup { [ZeroPurgeOrders EXCEPT !.customGroupIdCnt = one] : one \in Sample(1) }
        \cup { [ZeroPurgeOrders EXCEPT !.customGroupId = one] : one \in Sample(2) }

(***************************************************************************)
(* Quote Update Group: 20 bytes                                            *)
(***************************************************************************)

QuoteUpdateGroup ==
    [ quoteSymbol : Sample(6),
      side        : Sample(1),
      openClose   : Sample(1),
      price       : Sample(8),
      orderQty    : Sample(4) ]

EncodeQuoteUpdateGroup(message) ==
    message.quoteSymbol
        \o message.side
        \o message.openClose
        \o message.price
        \o message.orderQty

DecodeQuoteUpdateGroup(bytes) ==
    LET quoteSymbol == ReadBytes(bytes, 6) IN IF ~quoteSymbol.ok THEN Fail ELSE
    LET side == ReadBytes(quoteSymbol.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET openClose == ReadBytes(side.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET price == ReadBytes(openClose.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderQty == ReadBytes(price.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    Ok([ quoteSymbol |-> quoteSymbol.value,
         side        |-> side.value,
         openClose   |-> openClose.value,
         price       |-> price.value,
         orderQty    |-> orderQty.value ], orderQty.rest)

ZeroQuoteUpdateGroup ==
    [ quoteSymbol |-> [i \in 1 .. 6 |-> 0],
      side        |-> [i \in 1 .. 1 |-> 0],
      openClose   |-> [i \in 1 .. 1 |-> 0],
      price       |-> [i \in 1 .. 8 |-> 0],
      orderQty    |-> [i \in 1 .. 4 |-> 0] ]

(* Quote Update Group at zero, then each field in turn at the values it is checked at *)
CheckedQuoteUpdateGroup ==
    { ZeroQuoteUpdateGroup }
        \cup { [ZeroQuoteUpdateGroup EXCEPT !.quoteSymbol = one] : one \in Sample(6) }
        \cup { [ZeroQuoteUpdateGroup EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroQuoteUpdateGroup EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroQuoteUpdateGroup EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroQuoteUpdateGroup EXCEPT !.orderQty = one] : one \in Sample(4) }

(* A run of Quote Update Group, written one after another *)
RECURSIVE EncodeQuoteUpdateGroupList(_)
EncodeQuoteUpdateGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeQuoteUpdateGroup(Head(messages)) \o EncodeQuoteUpdateGroupList(Tail(messages))

(* As many Quote Update Group as the field that counts them says *)
RECURSIVE ReadQuoteUpdateGroupList(_, _)
ReadQuoteUpdateGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeQuoteUpdateGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadQuoteUpdateGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Quote Update Group of each kind, for the lists that carry them *)
OneQuoteUpdateGroup == { ZeroQuoteUpdateGroup }

(***************************************************************************)
(* Quote Update                                                            *)
(***************************************************************************)

QuoteUpdate ==
    [ quoteUpdateId        : Sample(16),
      clearingFirm         : Sample(4),
      clearingAccount      : Sample(4),
      cmtaNumber           : Sample(4),
      account              : Sample(16),
      customGroupId        : Sample(2),
      capacity             : Sample(1),
      ctiCode              : Sample(1),
      manualOrderIndicator : Sample(1),
      oeoId                : Sample(18),
      sizeModifier         : Sample(1),
      quoteUpdateGroup     : SampleLists(OneQuoteUpdateGroup) ]

EncodeQuoteUpdate(message) ==
    message.quoteUpdateId
        \o message.clearingFirm
        \o message.clearingAccount
        \o message.cmtaNumber
        \o message.account
        \o message.customGroupId
        \o message.capacity
        \o message.ctiCode
        \o message.manualOrderIndicator
        \o message.oeoId
        \o message.sizeModifier
        \o EncodeUIntLE(Len(message.quoteUpdateGroup), 1)
        \o EncodeQuoteUpdateGroupList(message.quoteUpdateGroup)

DecodeQuoteUpdate(bytes) ==
    LET quoteUpdateId == ReadBytes(bytes, 16) IN IF ~quoteUpdateId.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(quoteUpdateId.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadBytes(clearingFirm.rest, 4) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET cmtaNumber == ReadBytes(clearingAccount.rest, 4) IN IF ~cmtaNumber.ok THEN Fail ELSE
    LET account == ReadBytes(cmtaNumber.rest, 16) IN IF ~account.ok THEN Fail ELSE
    LET customGroupId == ReadBytes(account.rest, 2) IN IF ~customGroupId.ok THEN Fail ELSE
    LET capacity == ReadBytes(customGroupId.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET ctiCode == ReadBytes(capacity.rest, 1) IN IF ~ctiCode.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadBytes(ctiCode.rest, 1) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET oeoId == ReadBytes(manualOrderIndicator.rest, 18) IN IF ~oeoId.ok THEN Fail ELSE
    LET sizeModifier == ReadBytes(oeoId.rest, 1) IN IF ~sizeModifier.ok THEN Fail ELSE
    LET quoteCnt == ReadUIntLE(sizeModifier.rest, 1) IN IF ~quoteCnt.ok THEN Fail ELSE
    LET quoteUpdateGroup == ReadQuoteUpdateGroupList(quoteCnt.rest, quoteCnt.value) IN IF ~quoteUpdateGroup.ok THEN Fail ELSE
    Ok([ quoteUpdateId        |-> quoteUpdateId.value,
         clearingFirm         |-> clearingFirm.value,
         clearingAccount      |-> clearingAccount.value,
         cmtaNumber           |-> cmtaNumber.value,
         account              |-> account.value,
         customGroupId        |-> customGroupId.value,
         capacity             |-> capacity.value,
         ctiCode              |-> ctiCode.value,
         manualOrderIndicator |-> manualOrderIndicator.value,
         oeoId                |-> oeoId.value,
         sizeModifier         |-> sizeModifier.value,
         quoteUpdateGroup     |-> quoteUpdateGroup.value ], quoteUpdateGroup.rest)

ZeroQuoteUpdate ==
    [ quoteUpdateId        |-> [i \in 1 .. 16 |-> 0],
      clearingFirm         |-> [i \in 1 .. 4 |-> 0],
      clearingAccount      |-> [i \in 1 .. 4 |-> 0],
      cmtaNumber           |-> [i \in 1 .. 4 |-> 0],
      account              |-> [i \in 1 .. 16 |-> 0],
      customGroupId        |-> [i \in 1 .. 2 |-> 0],
      capacity             |-> [i \in 1 .. 1 |-> 0],
      ctiCode              |-> [i \in 1 .. 1 |-> 0],
      manualOrderIndicator |-> [i \in 1 .. 1 |-> 0],
      oeoId                |-> [i \in 1 .. 18 |-> 0],
      sizeModifier         |-> [i \in 1 .. 1 |-> 0],
      quoteUpdateGroup     |-> << >> ]

(* Quote Update at zero, then each field in turn at the values it is checked at *)
CheckedQuoteUpdate ==
    { ZeroQuoteUpdate }
        \cup { [ZeroQuoteUpdate EXCEPT !.quoteUpdateId = one] : one \in Sample(16) }
        \cup { [ZeroQuoteUpdate EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroQuoteUpdate EXCEPT !.clearingAccount = one] : one \in Sample(4) }
        \cup { [ZeroQuoteUpdate EXCEPT !.cmtaNumber = one] : one \in Sample(4) }
        \cup { [ZeroQuoteUpdate EXCEPT !.account = one] : one \in Sample(16) }
        \cup { [ZeroQuoteUpdate EXCEPT !.customGroupId = one] : one \in Sample(2) }
        \cup { [ZeroQuoteUpdate EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroQuoteUpdate EXCEPT !.ctiCode = one] : one \in Sample(1) }
        \cup { [ZeroQuoteUpdate EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroQuoteUpdate EXCEPT !.oeoId = one] : one \in Sample(18) }
        \cup { [ZeroQuoteUpdate EXCEPT !.sizeModifier = one] : one \in Sample(1) }
        \cup { [ZeroQuoteUpdate EXCEPT !.quoteUpdateGroup = one] : one \in SampleLists(OneQuoteUpdateGroup) }

(***************************************************************************)
(* Quote Update Option Group: 20 bytes                                     *)
(***************************************************************************)

QuoteUpdateOptionGroup ==
    [ quoteSymbol : Sample(6),
      side        : Sample(1),
      openClose   : Sample(1),
      price       : Sample(8),
      orderQty    : Sample(4) ]

EncodeQuoteUpdateOptionGroup(message) ==
    message.quoteSymbol
        \o message.side
        \o message.openClose
        \o message.price
        \o message.orderQty

DecodeQuoteUpdateOptionGroup(bytes) ==
    LET quoteSymbol == ReadBytes(bytes, 6) IN IF ~quoteSymbol.ok THEN Fail ELSE
    LET side == ReadBytes(quoteSymbol.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET openClose == ReadBytes(side.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET price == ReadBytes(openClose.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderQty == ReadBytes(price.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    Ok([ quoteSymbol |-> quoteSymbol.value,
         side        |-> side.value,
         openClose   |-> openClose.value,
         price       |-> price.value,
         orderQty    |-> orderQty.value ], orderQty.rest)

ZeroQuoteUpdateOptionGroup ==
    [ quoteSymbol |-> [i \in 1 .. 6 |-> 0],
      side        |-> [i \in 1 .. 1 |-> 0],
      openClose   |-> [i \in 1 .. 1 |-> 0],
      price       |-> [i \in 1 .. 8 |-> 0],
      orderQty    |-> [i \in 1 .. 4 |-> 0] ]

(* Quote Update Option Group at zero, then each field in turn at the values it is checked at *)
CheckedQuoteUpdateOptionGroup ==
    { ZeroQuoteUpdateOptionGroup }
        \cup { [ZeroQuoteUpdateOptionGroup EXCEPT !.quoteSymbol = one] : one \in Sample(6) }
        \cup { [ZeroQuoteUpdateOptionGroup EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroQuoteUpdateOptionGroup EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroQuoteUpdateOptionGroup EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroQuoteUpdateOptionGroup EXCEPT !.orderQty = one] : one \in Sample(4) }

(* A run of Quote Update Option Group, written one after another *)
RECURSIVE EncodeQuoteUpdateOptionGroupList(_)
EncodeQuoteUpdateOptionGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeQuoteUpdateOptionGroup(Head(messages)) \o EncodeQuoteUpdateOptionGroupList(Tail(messages))

(* As many Quote Update Option Group as the field that counts them says *)
RECURSIVE ReadQuoteUpdateOptionGroupList(_, _)
ReadQuoteUpdateOptionGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeQuoteUpdateOptionGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadQuoteUpdateOptionGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Quote Update Option Group of each kind, for the lists that carry them *)
OneQuoteUpdateOptionGroup == { ZeroQuoteUpdateOptionGroup }

(***************************************************************************)
(* Quote Update Option                                                     *)
(***************************************************************************)

QuoteUpdateOption ==
    [ quoteUpdateId          : Sample(16),
      clearingFirm           : Sample(4),
      clearingAccount        : Sample(4),
      cmtaNumber             : Sample(4),
      account                : Sample(16),
      customGroupId          : Sample(2),
      capacity               : Sample(1),
      ctiCode                : Sample(1),
      manualOrderIndicator   : Sample(1),
      oeoId                  : Sample(18),
      sizeModifier           : Sample(1),
      quoteUpdateOptionGroup : SampleLists(OneQuoteUpdateOptionGroup) ]

EncodeQuoteUpdateOption(message) ==
    message.quoteUpdateId
        \o message.clearingFirm
        \o message.clearingAccount
        \o message.cmtaNumber
        \o message.account
        \o message.customGroupId
        \o message.capacity
        \o message.ctiCode
        \o message.manualOrderIndicator
        \o message.oeoId
        \o message.sizeModifier
        \o EncodeUIntLE(Len(message.quoteUpdateOptionGroup), 1)
        \o EncodeQuoteUpdateOptionGroupList(message.quoteUpdateOptionGroup)

DecodeQuoteUpdateOption(bytes) ==
    LET quoteUpdateId == ReadBytes(bytes, 16) IN IF ~quoteUpdateId.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(quoteUpdateId.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadBytes(clearingFirm.rest, 4) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET cmtaNumber == ReadBytes(clearingAccount.rest, 4) IN IF ~cmtaNumber.ok THEN Fail ELSE
    LET account == ReadBytes(cmtaNumber.rest, 16) IN IF ~account.ok THEN Fail ELSE
    LET customGroupId == ReadBytes(account.rest, 2) IN IF ~customGroupId.ok THEN Fail ELSE
    LET capacity == ReadBytes(customGroupId.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET ctiCode == ReadBytes(capacity.rest, 1) IN IF ~ctiCode.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadBytes(ctiCode.rest, 1) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET oeoId == ReadBytes(manualOrderIndicator.rest, 18) IN IF ~oeoId.ok THEN Fail ELSE
    LET sizeModifier == ReadBytes(oeoId.rest, 1) IN IF ~sizeModifier.ok THEN Fail ELSE
    LET quoteCnt == ReadUIntLE(sizeModifier.rest, 1) IN IF ~quoteCnt.ok THEN Fail ELSE
    LET quoteUpdateOptionGroup == ReadQuoteUpdateOptionGroupList(quoteCnt.rest, quoteCnt.value) IN IF ~quoteUpdateOptionGroup.ok THEN Fail ELSE
    Ok([ quoteUpdateId          |-> quoteUpdateId.value,
         clearingFirm           |-> clearingFirm.value,
         clearingAccount        |-> clearingAccount.value,
         cmtaNumber             |-> cmtaNumber.value,
         account                |-> account.value,
         customGroupId          |-> customGroupId.value,
         capacity               |-> capacity.value,
         ctiCode                |-> ctiCode.value,
         manualOrderIndicator   |-> manualOrderIndicator.value,
         oeoId                  |-> oeoId.value,
         sizeModifier           |-> sizeModifier.value,
         quoteUpdateOptionGroup |-> quoteUpdateOptionGroup.value ], quoteUpdateOptionGroup.rest)

ZeroQuoteUpdateOption ==
    [ quoteUpdateId          |-> [i \in 1 .. 16 |-> 0],
      clearingFirm           |-> [i \in 1 .. 4 |-> 0],
      clearingAccount        |-> [i \in 1 .. 4 |-> 0],
      cmtaNumber             |-> [i \in 1 .. 4 |-> 0],
      account                |-> [i \in 1 .. 16 |-> 0],
      customGroupId          |-> [i \in 1 .. 2 |-> 0],
      capacity               |-> [i \in 1 .. 1 |-> 0],
      ctiCode                |-> [i \in 1 .. 1 |-> 0],
      manualOrderIndicator   |-> [i \in 1 .. 1 |-> 0],
      oeoId                  |-> [i \in 1 .. 18 |-> 0],
      sizeModifier           |-> [i \in 1 .. 1 |-> 0],
      quoteUpdateOptionGroup |-> << >> ]

(* Quote Update Option at zero, then each field in turn at the values it is checked at *)
CheckedQuoteUpdateOption ==
    { ZeroQuoteUpdateOption }
        \cup { [ZeroQuoteUpdateOption EXCEPT !.quoteUpdateId = one] : one \in Sample(16) }
        \cup { [ZeroQuoteUpdateOption EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroQuoteUpdateOption EXCEPT !.clearingAccount = one] : one \in Sample(4) }
        \cup { [ZeroQuoteUpdateOption EXCEPT !.cmtaNumber = one] : one \in Sample(4) }
        \cup { [ZeroQuoteUpdateOption EXCEPT !.account = one] : one \in Sample(16) }
        \cup { [ZeroQuoteUpdateOption EXCEPT !.customGroupId = one] : one \in Sample(2) }
        \cup { [ZeroQuoteUpdateOption EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroQuoteUpdateOption EXCEPT !.ctiCode = one] : one \in Sample(1) }
        \cup { [ZeroQuoteUpdateOption EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroQuoteUpdateOption EXCEPT !.oeoId = one] : one \in Sample(18) }
        \cup { [ZeroQuoteUpdateOption EXCEPT !.sizeModifier = one] : one \in Sample(1) }
        \cup { [ZeroQuoteUpdateOption EXCEPT !.quoteUpdateOptionGroup = one] : one \in SampleLists(OneQuoteUpdateOptionGroup) }

(***************************************************************************)
(* Reset Risk: 36 bytes                                                    *)
(***************************************************************************)

ResetRisk ==
    [ riskStatusId  : Sample(16),
      riskReset     : Sample(8),
      clearingFirm  : Sample(4),
      productName   : Sample(6),
      customGroupId : Sample(2) ]

EncodeResetRisk(message) ==
    message.riskStatusId
        \o message.riskReset
        \o message.clearingFirm
        \o message.productName
        \o message.customGroupId

DecodeResetRisk(bytes) ==
    LET riskStatusId == ReadBytes(bytes, 16) IN IF ~riskStatusId.ok THEN Fail ELSE
    LET riskReset == ReadBytes(riskStatusId.rest, 8) IN IF ~riskReset.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(riskReset.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET productName == ReadBytes(clearingFirm.rest, 6) IN IF ~productName.ok THEN Fail ELSE
    LET customGroupId == ReadBytes(productName.rest, 2) IN IF ~customGroupId.ok THEN Fail ELSE
    Ok([ riskStatusId  |-> riskStatusId.value,
         riskReset     |-> riskReset.value,
         clearingFirm  |-> clearingFirm.value,
         productName   |-> productName.value,
         customGroupId |-> customGroupId.value ], customGroupId.rest)

ZeroResetRisk ==
    [ riskStatusId  |-> [i \in 1 .. 16 |-> 0],
      riskReset     |-> [i \in 1 .. 8 |-> 0],
      clearingFirm  |-> [i \in 1 .. 4 |-> 0],
      productName   |-> [i \in 1 .. 6 |-> 0],
      customGroupId |-> [i \in 1 .. 2 |-> 0] ]

(* Reset Risk at zero, then each field in turn at the values it is checked at *)
CheckedResetRisk ==
    { ZeroResetRisk }
        \cup { [ZeroResetRisk EXCEPT !.riskStatusId = one] : one \in Sample(16) }
        \cup { [ZeroResetRisk EXCEPT !.riskReset = one] : one \in Sample(8) }
        \cup { [ZeroResetRisk EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroResetRisk EXCEPT !.productName = one] : one \in Sample(6) }
        \cup { [ZeroResetRisk EXCEPT !.customGroupId = one] : one \in Sample(2) }

(***************************************************************************)
(* Option Accepted Leg: 29 bytes                                           *)
(***************************************************************************)

OptionAcceptedLeg ==
    [ legSymbol    : Sample(8),
      securityDesc : Sample(16),
      legRatioQty  : Sample(4),
      legSide      : Sample(1) ]

EncodeOptionAcceptedLeg(message) ==
    message.legSymbol
        \o message.securityDesc
        \o message.legRatioQty
        \o message.legSide

DecodeOptionAcceptedLeg(bytes) ==
    LET legSymbol == ReadBytes(bytes, 8) IN IF ~legSymbol.ok THEN Fail ELSE
    LET securityDesc == ReadBytes(legSymbol.rest, 16) IN IF ~securityDesc.ok THEN Fail ELSE
    LET legRatioQty == ReadBytes(securityDesc.rest, 4) IN IF ~legRatioQty.ok THEN Fail ELSE
    LET legSide == ReadBytes(legRatioQty.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    Ok([ legSymbol    |-> legSymbol.value,
         securityDesc |-> securityDesc.value,
         legRatioQty  |-> legRatioQty.value,
         legSide      |-> legSide.value ], legSide.rest)

ZeroOptionAcceptedLeg ==
    [ legSymbol    |-> [i \in 1 .. 8 |-> 0],
      securityDesc |-> [i \in 1 .. 16 |-> 0],
      legRatioQty  |-> [i \in 1 .. 4 |-> 0],
      legSide      |-> [i \in 1 .. 1 |-> 0] ]

(* Option Accepted Leg at zero, then each field in turn at the values it is checked at *)
CheckedOptionAcceptedLeg ==
    { ZeroOptionAcceptedLeg }
        \cup { [ZeroOptionAcceptedLeg EXCEPT !.legSymbol = one] : one \in Sample(8) }
        \cup { [ZeroOptionAcceptedLeg EXCEPT !.securityDesc = one] : one \in Sample(16) }
        \cup { [ZeroOptionAcceptedLeg EXCEPT !.legRatioQty = one] : one \in Sample(4) }
        \cup { [ZeroOptionAcceptedLeg EXCEPT !.legSide = one] : one \in Sample(1) }

(* A run of Option Accepted Leg, written one after another *)
RECURSIVE EncodeOptionAcceptedLegList(_)
EncodeOptionAcceptedLegList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOptionAcceptedLeg(Head(messages)) \o EncodeOptionAcceptedLegList(Tail(messages))

(* As many Option Accepted Leg as the field that counts them says *)
RECURSIVE ReadOptionAcceptedLegList(_, _)
ReadOptionAcceptedLegList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOptionAcceptedLeg(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOptionAcceptedLegList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Option Accepted Leg of each kind, for the lists that carry them *)
OneOptionAcceptedLeg == { ZeroOptionAcceptedLeg }

(***************************************************************************)
(* New Complex Instrument Option                                           *)
(***************************************************************************)

NewComplexInstrumentOption ==
    [ clOrdId           : Sample(20),
      clearingFirm      : Sample(4),
      optionAcceptedLeg : SampleLists(OneOptionAcceptedLeg) ]

EncodeNewComplexInstrumentOption(message) ==
    message.clOrdId
        \o message.clearingFirm
        \o EncodeUIntLE(Len(message.optionAcceptedLeg), 1)
        \o EncodeOptionAcceptedLegList(message.optionAcceptedLeg)

DecodeNewComplexInstrumentOption(bytes) ==
    LET clOrdId == ReadBytes(bytes, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(clOrdId.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET legCnt == ReadUIntLE(clearingFirm.rest, 1) IN IF ~legCnt.ok THEN Fail ELSE
    LET optionAcceptedLeg == ReadOptionAcceptedLegList(legCnt.rest, legCnt.value) IN IF ~optionAcceptedLeg.ok THEN Fail ELSE
    Ok([ clOrdId           |-> clOrdId.value,
         clearingFirm      |-> clearingFirm.value,
         optionAcceptedLeg |-> optionAcceptedLeg.value ], optionAcceptedLeg.rest)

ZeroNewComplexInstrumentOption ==
    [ clOrdId           |-> [i \in 1 .. 20 |-> 0],
      clearingFirm      |-> [i \in 1 .. 4 |-> 0],
      optionAcceptedLeg |-> << >> ]

(* New Complex Instrument Option at zero, then each field in turn at the values it is checked at *)
CheckedNewComplexInstrumentOption ==
    { ZeroNewComplexInstrumentOption }
        \cup { [ZeroNewComplexInstrumentOption EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroNewComplexInstrumentOption EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexInstrumentOption EXCEPT !.optionAcceptedLeg = one] : one \in SampleLists(OneOptionAcceptedLeg) }

(***************************************************************************)
(* Firm Message, selected by Firm Message Type                             *)
(***************************************************************************)

LoginRequestMessageCode == 1  \* 0x01
LogoutRequestCode == 2  \* 0x02
ClientHeartbeatCode == 3  \* 0x03
NewOrderCode == 1008  \* 0x3f0
NewOrderOptionCode == 1009  \* 0x3f1
ModifyOrderCode == 1002  \* 0x3ea
CancelOrderCode == 1003  \* 0x3eb
MassCancelOrderCode == 1004  \* 0x3ec
PurgeOrdersCode == 1005  \* 0x3ed
QuoteUpdateCode == 1006  \* 0x3ee
QuoteUpdateOptionCode == 1010  \* 0x3f2
ResetRiskCode == 1007  \* 0x3ef
NewComplexInstrumentOptionCode == 1011  \* 0x3f3

FirmMessage ==
    [ tag : {LoginRequestMessageCode}, body : LoginRequestMessage ]
        \cup [ tag : {LogoutRequestCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ClientHeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {NewOrderCode}, body : NewOrder ]
        \cup [ tag : {NewOrderOptionCode}, body : NewOrderOption ]
        \cup [ tag : {ModifyOrderCode}, body : ModifyOrder ]
        \cup [ tag : {CancelOrderCode}, body : CancelOrder ]
        \cup [ tag : {MassCancelOrderCode}, body : MassCancelOrder ]
        \cup [ tag : {PurgeOrdersCode}, body : PurgeOrders ]
        \cup [ tag : {QuoteUpdateCode}, body : QuoteUpdate ]
        \cup [ tag : {QuoteUpdateOptionCode}, body : QuoteUpdateOption ]
        \cup [ tag : {ResetRiskCode}, body : ResetRisk ]
        \cup [ tag : {NewComplexInstrumentOptionCode}, body : NewComplexInstrumentOption ]

EncodeFirmMessage(message) ==
    CASE message.tag = LoginRequestMessageCode -> EncodeLoginRequestMessage(message.body)
      [] message.tag = LogoutRequestCode -> << >>
      [] message.tag = ClientHeartbeatCode -> << >>
      [] message.tag = NewOrderCode -> EncodeNewOrder(message.body)
      [] message.tag = NewOrderOptionCode -> EncodeNewOrderOption(message.body)
      [] message.tag = ModifyOrderCode -> EncodeModifyOrder(message.body)
      [] message.tag = CancelOrderCode -> EncodeCancelOrder(message.body)
      [] message.tag = MassCancelOrderCode -> EncodeMassCancelOrder(message.body)
      [] message.tag = PurgeOrdersCode -> EncodePurgeOrders(message.body)
      [] message.tag = QuoteUpdateCode -> EncodeQuoteUpdate(message.body)
      [] message.tag = QuoteUpdateOptionCode -> EncodeQuoteUpdateOption(message.body)
      [] message.tag = ResetRiskCode -> EncodeResetRisk(message.body)
      [] message.tag = NewComplexInstrumentOptionCode -> EncodeNewComplexInstrumentOption(message.body)

DecodeFirmMessage(tag, bytes) ==
    LET read ==
            CASE tag = LoginRequestMessageCode -> DecodeLoginRequestMessage(bytes)
              [] tag = LogoutRequestCode -> Ok([empty |-> 0], bytes)
              [] tag = ClientHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = NewOrderCode -> DecodeNewOrder(bytes)
              [] tag = NewOrderOptionCode -> DecodeNewOrderOption(bytes)
              [] tag = ModifyOrderCode -> DecodeModifyOrder(bytes)
              [] tag = CancelOrderCode -> DecodeCancelOrder(bytes)
              [] tag = MassCancelOrderCode -> DecodeMassCancelOrder(bytes)
              [] tag = PurgeOrdersCode -> DecodePurgeOrders(bytes)
              [] tag = QuoteUpdateCode -> DecodeQuoteUpdate(bytes)
              [] tag = QuoteUpdateOptionCode -> DecodeQuoteUpdateOption(bytes)
              [] tag = ResetRiskCode -> DecodeResetRisk(bytes)
              [] tag = NewComplexInstrumentOptionCode -> DecodeNewComplexInstrumentOption(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroFirmMessage == [tag |-> LoginRequestMessageCode, body |-> ZeroLoginRequestMessage]

(* Each Firm Message in turn, at the values the message it names is checked at *)
CheckedFirmMessage ==
    { [tag |-> LoginRequestMessageCode, body |-> one] : one \in CheckedLoginRequestMessage }
        \cup { [tag |-> LogoutRequestCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> ClientHeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> NewOrderCode, body |-> one] : one \in CheckedNewOrder }
        \cup { [tag |-> NewOrderOptionCode, body |-> one] : one \in CheckedNewOrderOption }
        \cup { [tag |-> ModifyOrderCode, body |-> one] : one \in CheckedModifyOrder }
        \cup { [tag |-> CancelOrderCode, body |-> one] : one \in CheckedCancelOrder }
        \cup { [tag |-> MassCancelOrderCode, body |-> one] : one \in CheckedMassCancelOrder }
        \cup { [tag |-> PurgeOrdersCode, body |-> one] : one \in CheckedPurgeOrders }
        \cup { [tag |-> QuoteUpdateCode, body |-> one] : one \in CheckedQuoteUpdate }
        \cup { [tag |-> QuoteUpdateOptionCode, body |-> one] : one \in CheckedQuoteUpdateOption }
        \cup { [tag |-> ResetRiskCode, body |-> one] : one \in CheckedResetRisk }
        \cup { [tag |-> NewComplexInstrumentOptionCode, body |-> one] : one \in CheckedNewComplexInstrumentOption }

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

(* Every Prevent Match decodes back to what was encoded, and leaves nothing over *)
RoundTripPreventMatch ==
    \A message \in CheckedPreventMatch :
        LET read == DecodePreventMatch(EncodePreventMatch(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrder ==
    \A message \in CheckedNewOrder :
        LET read == DecodeNewOrder(EncodeNewOrder(message))
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

(* Every New Order Option decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderOption ==
    \A message \in CheckedNewOrderOption :
        LET read == DecodeNewOrderOption(EncodeNewOrderOption(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Order decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyOrder ==
    \A message \in CheckedModifyOrder :
        LET read == DecodeModifyOrder(EncodeModifyOrder(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Order decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelOrder ==
    \A message \in CheckedCancelOrder :
        LET read == DecodeCancelOrder(EncodeCancelOrder(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Cancel Inst decodes back to what was encoded, and leaves nothing over *)
RoundTripMassCancelInst ==
    \A message \in CheckedMassCancelInst :
        LET read == DecodeMassCancelInst(EncodeMassCancelInst(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Cancel Order decodes back to what was encoded, and leaves nothing over *)
RoundTripMassCancelOrder ==
    \A message \in CheckedMassCancelOrder :
        LET read == DecodeMassCancelOrder(EncodeMassCancelOrder(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Cancel Inst decodes back to what was encoded, and leaves nothing over *)
RoundTripMassCancelInst2 ==
    \A message \in CheckedMassCancelInst2 :
        LET read == DecodeMassCancelInst2(EncodeMassCancelInst2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Purge Orders decodes back to what was encoded, and leaves nothing over *)
RoundTripPurgeOrders ==
    \A message \in CheckedPurgeOrders :
        LET read == DecodePurgeOrders(EncodePurgeOrders(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Update Group decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteUpdateGroup ==
    \A message \in CheckedQuoteUpdateGroup :
        LET read == DecodeQuoteUpdateGroup(EncodeQuoteUpdateGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Update decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteUpdate ==
    \A message \in CheckedQuoteUpdate :
        LET read == DecodeQuoteUpdate(EncodeQuoteUpdate(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Update Option Group decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteUpdateOptionGroup ==
    \A message \in CheckedQuoteUpdateOptionGroup :
        LET read == DecodeQuoteUpdateOptionGroup(EncodeQuoteUpdateOptionGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Update Option decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteUpdateOption ==
    \A message \in CheckedQuoteUpdateOption :
        LET read == DecodeQuoteUpdateOption(EncodeQuoteUpdateOption(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reset Risk decodes back to what was encoded, and leaves nothing over *)
RoundTripResetRisk ==
    \A message \in CheckedResetRisk :
        LET read == DecodeResetRisk(EncodeResetRisk(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Accepted Leg decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionAcceptedLeg ==
    \A message \in CheckedOptionAcceptedLeg :
        LET read == DecodeOptionAcceptedLeg(EncodeOptionAcceptedLeg(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Complex Instrument Option decodes back to what was encoded, and leaves nothing over *)
RoundTripNewComplexInstrumentOption ==
    \A message \in CheckedNewComplexInstrumentOption :
        LET read == DecodeNewComplexInstrumentOption(EncodeNewComplexInstrumentOption(message))
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
