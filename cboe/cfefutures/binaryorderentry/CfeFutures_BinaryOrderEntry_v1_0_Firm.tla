--------------- MODULE CfeFutures_BinaryOrderEntry_v1_0_Firm ---------------
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
(* New Order Message: 129 bytes                                            *)
(***************************************************************************)

NewOrderMessage ==
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
      custOrderHandlingInst : Sample(1) ]

EncodeNewOrderMessage(message) ==
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

DecodeNewOrderMessage(bytes) ==
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
         custOrderHandlingInst |-> custOrderHandlingInst.value ], custOrderHandlingInst.rest)

ZeroNewOrderMessage ==
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
      custOrderHandlingInst |-> [i \in 1 .. 1 |-> 0] ]

(* New Order Message at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderMessage ==
    { ZeroNewOrderMessage }
        \cup { [ZeroNewOrderMessage EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderMessage EXCEPT !.clearingAccount = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderMessage EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.account = one] : one \in Sample(16) }
        \cup { [ZeroNewOrderMessage EXCEPT !.preventMatch = one] : one \in CheckedPreventMatch }
        \cup { [ZeroNewOrderMessage EXCEPT !.expireTime = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderMessage EXCEPT !.maturityDate = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderMessage EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.cmtaNumber = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderMessage EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderMessage EXCEPT !.customGroupId = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderMessage EXCEPT !.ctiCode = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.oeoId = one] : one \in Sample(18) }
        \cup { [ZeroNewOrderMessage EXCEPT !.frequentTraderId = one] : one \in Sample(6) }
        \cup { [ZeroNewOrderMessage EXCEPT !.custOrderHandlingInst = one] : one \in Sample(1) }

(***************************************************************************)
(* Modify Order Message: 92 bytes                                          *)
(***************************************************************************)

ModifyOrderMessage ==
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

EncodeModifyOrderMessage(message) ==
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

DecodeModifyOrderMessage(bytes) ==
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

ZeroModifyOrderMessage ==
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

(* Modify Order Message at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderMessage ==
    { ZeroModifyOrderMessage }
        \cup { [ZeroModifyOrderMessage EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.origClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.cancelOrigOnReject = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.oeoId = one] : one \in Sample(18) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.frequentTraderId = one] : one \in Sample(6) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.custOrderHandlingInst = one] : one \in Sample(1) }

(***************************************************************************)
(* Cancel Order Message: 43 bytes                                          *)
(***************************************************************************)

CancelOrderMessage ==
    [ origClOrdId          : Sample(20),
      clearingFirm         : Sample(4),
      manualOrderIndicator : Sample(1),
      oeoId                : Sample(18) ]

EncodeCancelOrderMessage(message) ==
    message.origClOrdId
        \o message.clearingFirm
        \o message.manualOrderIndicator
        \o message.oeoId

DecodeCancelOrderMessage(bytes) ==
    LET origClOrdId == ReadBytes(bytes, 20) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(origClOrdId.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadBytes(clearingFirm.rest, 1) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET oeoId == ReadBytes(manualOrderIndicator.rest, 18) IN IF ~oeoId.ok THEN Fail ELSE
    Ok([ origClOrdId          |-> origClOrdId.value,
         clearingFirm         |-> clearingFirm.value,
         manualOrderIndicator |-> manualOrderIndicator.value,
         oeoId                |-> oeoId.value ], oeoId.rest)

ZeroCancelOrderMessage ==
    [ origClOrdId          |-> [i \in 1 .. 20 |-> 0],
      clearingFirm         |-> [i \in 1 .. 4 |-> 0],
      manualOrderIndicator |-> [i \in 1 .. 1 |-> 0],
      oeoId                |-> [i \in 1 .. 18 |-> 0] ]

(* Cancel Order Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelOrderMessage ==
    { ZeroCancelOrderMessage }
        \cup { [ZeroCancelOrderMessage EXCEPT !.origClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroCancelOrderMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroCancelOrderMessage EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroCancelOrderMessage EXCEPT !.oeoId = one] : one \in Sample(18) }

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
(* Mass Cancel Order Message: 65 bytes                                     *)
(***************************************************************************)

MassCancelOrderMessage ==
    [ massCancelId         : Sample(20),
      clearingFirm         : Sample(4),
      productName          : Sample(6),
      massCancelInst       : MassCancelInst,
      manualOrderIndicator : Sample(1),
      oeoId                : Sample(18) ]

EncodeMassCancelOrderMessage(message) ==
    message.massCancelId
        \o message.clearingFirm
        \o message.productName
        \o EncodeMassCancelInst(message.massCancelInst)
        \o message.manualOrderIndicator
        \o message.oeoId

DecodeMassCancelOrderMessage(bytes) ==
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

ZeroMassCancelOrderMessage ==
    [ massCancelId         |-> [i \in 1 .. 20 |-> 0],
      clearingFirm         |-> [i \in 1 .. 4 |-> 0],
      productName          |-> [i \in 1 .. 6 |-> 0],
      massCancelInst       |-> ZeroMassCancelInst,
      manualOrderIndicator |-> [i \in 1 .. 1 |-> 0],
      oeoId                |-> [i \in 1 .. 18 |-> 0] ]

(* Mass Cancel Order Message at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelOrderMessage ==
    { ZeroMassCancelOrderMessage }
        \cup { [ZeroMassCancelOrderMessage EXCEPT !.massCancelId = one] : one \in Sample(20) }
        \cup { [ZeroMassCancelOrderMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroMassCancelOrderMessage EXCEPT !.productName = one] : one \in Sample(6) }
        \cup { [ZeroMassCancelOrderMessage EXCEPT !.massCancelInst = one] : one \in CheckedMassCancelInst }
        \cup { [ZeroMassCancelOrderMessage EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelOrderMessage EXCEPT !.oeoId = one] : one \in Sample(18) }

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
(* Purge Orders Message: 68 bytes                                          *)
(***************************************************************************)

PurgeOrdersMessage ==
    [ massCancelId         : Sample(20),
      clearingFirm         : Sample(4),
      productName          : Sample(6),
      massCancelInst       : MassCancelInst2,
      manualOrderIndicator : Sample(1),
      oeoId                : Sample(18),
      customGroupIdCnt     : 0 .. 255,
      customGroupId        : Sample(2) ]

EncodePurgeOrdersMessage(message) ==
    message.massCancelId
        \o message.clearingFirm
        \o message.productName
        \o EncodeMassCancelInst2(message.massCancelInst)
        \o message.manualOrderIndicator
        \o message.oeoId
        \o EncodeUIntLE(message.customGroupIdCnt, 1)
        \o message.customGroupId

DecodePurgeOrdersMessage(bytes) ==
    LET massCancelId == ReadBytes(bytes, 20) IN IF ~massCancelId.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(massCancelId.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET productName == ReadBytes(clearingFirm.rest, 6) IN IF ~productName.ok THEN Fail ELSE
    LET massCancelInst == DecodeMassCancelInst2(productName.rest) IN IF ~massCancelInst.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadBytes(massCancelInst.rest, 1) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET oeoId == ReadBytes(manualOrderIndicator.rest, 18) IN IF ~oeoId.ok THEN Fail ELSE
    LET customGroupIdCnt == ReadUIntLE(oeoId.rest, 1) IN IF ~customGroupIdCnt.ok THEN Fail ELSE
    LET customGroupId == ReadBytes(customGroupIdCnt.rest, 2) IN IF ~customGroupId.ok THEN Fail ELSE
    Ok([ massCancelId         |-> massCancelId.value,
         clearingFirm         |-> clearingFirm.value,
         productName          |-> productName.value,
         massCancelInst       |-> massCancelInst.value,
         manualOrderIndicator |-> manualOrderIndicator.value,
         oeoId                |-> oeoId.value,
         customGroupIdCnt     |-> customGroupIdCnt.value,
         customGroupId        |-> customGroupId.value ], customGroupId.rest)

ZeroPurgeOrdersMessage ==
    [ massCancelId         |-> [i \in 1 .. 20 |-> 0],
      clearingFirm         |-> [i \in 1 .. 4 |-> 0],
      productName          |-> [i \in 1 .. 6 |-> 0],
      massCancelInst       |-> ZeroMassCancelInst2,
      manualOrderIndicator |-> [i \in 1 .. 1 |-> 0],
      oeoId                |-> [i \in 1 .. 18 |-> 0],
      customGroupIdCnt     |-> 0,
      customGroupId        |-> [i \in 1 .. 2 |-> 0] ]

(* Purge Orders Message at zero, then each field in turn at the values it is checked at *)
CheckedPurgeOrdersMessage ==
    { ZeroPurgeOrdersMessage }
        \cup { [ZeroPurgeOrdersMessage EXCEPT !.massCancelId = one] : one \in Sample(20) }
        \cup { [ZeroPurgeOrdersMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroPurgeOrdersMessage EXCEPT !.productName = one] : one \in Sample(6) }
        \cup { [ZeroPurgeOrdersMessage EXCEPT !.massCancelInst = one] : one \in CheckedMassCancelInst2 }
        \cup { [ZeroPurgeOrdersMessage EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPurgeOrdersMessage EXCEPT !.oeoId = one] : one \in Sample(18) }
        \cup { [ZeroPurgeOrdersMessage EXCEPT !.customGroupIdCnt = one] : one \in {0, 1, 255} }
        \cup { [ZeroPurgeOrdersMessage EXCEPT !.customGroupId = one] : one \in Sample(2) }

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
(* Quote Update Message                                                    *)
(***************************************************************************)

QuoteUpdateMessage ==
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

EncodeQuoteUpdateMessage(message) ==
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

DecodeQuoteUpdateMessage(bytes) ==
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

ZeroQuoteUpdateMessage ==
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

(* Quote Update Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteUpdateMessage ==
    { ZeroQuoteUpdateMessage }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.quoteUpdateId = one] : one \in Sample(16) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.clearingAccount = one] : one \in Sample(4) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.cmtaNumber = one] : one \in Sample(4) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.account = one] : one \in Sample(16) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.customGroupId = one] : one \in Sample(2) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.ctiCode = one] : one \in Sample(1) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.oeoId = one] : one \in Sample(18) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.sizeModifier = one] : one \in Sample(1) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.quoteUpdateGroup = one] : one \in SampleLists(OneQuoteUpdateGroup) }

(***************************************************************************)
(* Reset Risk Message: 36 bytes                                            *)
(***************************************************************************)

ResetRiskMessage ==
    [ riskStatusId  : Sample(16),
      riskReset     : Sample(8),
      clearingFirm  : Sample(4),
      productName   : Sample(6),
      customGroupId : Sample(2) ]

EncodeResetRiskMessage(message) ==
    message.riskStatusId
        \o message.riskReset
        \o message.clearingFirm
        \o message.productName
        \o message.customGroupId

DecodeResetRiskMessage(bytes) ==
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

ZeroResetRiskMessage ==
    [ riskStatusId  |-> [i \in 1 .. 16 |-> 0],
      riskReset     |-> [i \in 1 .. 8 |-> 0],
      clearingFirm  |-> [i \in 1 .. 4 |-> 0],
      productName   |-> [i \in 1 .. 6 |-> 0],
      customGroupId |-> [i \in 1 .. 2 |-> 0] ]

(* Reset Risk Message at zero, then each field in turn at the values it is checked at *)
CheckedResetRiskMessage ==
    { ZeroResetRiskMessage }
        \cup { [ZeroResetRiskMessage EXCEPT !.riskStatusId = one] : one \in Sample(16) }
        \cup { [ZeroResetRiskMessage EXCEPT !.riskReset = one] : one \in Sample(8) }
        \cup { [ZeroResetRiskMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroResetRiskMessage EXCEPT !.productName = one] : one \in Sample(6) }
        \cup { [ZeroResetRiskMessage EXCEPT !.customGroupId = one] : one \in Sample(2) }

(***************************************************************************)
(* Firm Message, selected by Firm Message Type                             *)
(***************************************************************************)

LoginRequestMessageCode == 1  \* 0x01
LogoutRequestCode == 2  \* 0x02
ClientHeartbeatCode == 3  \* 0x03
NewOrderMessageCode == 1001  \* 0x3e9
ModifyOrderMessageCode == 1002  \* 0x3ea
CancelOrderMessageCode == 1003  \* 0x3eb
MassCancelOrderMessageCode == 1004  \* 0x3ec
PurgeOrdersMessageCode == 1005  \* 0x3ed
QuoteUpdateMessageCode == 1006  \* 0x3ee
ResetRiskMessageCode == 1007  \* 0x3ef

FirmMessage ==
    [ tag : {LoginRequestMessageCode}, body : LoginRequestMessage ]
        \cup [ tag : {LogoutRequestCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ClientHeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {NewOrderMessageCode}, body : NewOrderMessage ]
        \cup [ tag : {ModifyOrderMessageCode}, body : ModifyOrderMessage ]
        \cup [ tag : {CancelOrderMessageCode}, body : CancelOrderMessage ]
        \cup [ tag : {MassCancelOrderMessageCode}, body : MassCancelOrderMessage ]
        \cup [ tag : {PurgeOrdersMessageCode}, body : PurgeOrdersMessage ]
        \cup [ tag : {QuoteUpdateMessageCode}, body : QuoteUpdateMessage ]
        \cup [ tag : {ResetRiskMessageCode}, body : ResetRiskMessage ]

EncodeFirmMessage(message) ==
    CASE message.tag = LoginRequestMessageCode -> EncodeLoginRequestMessage(message.body)
      [] message.tag = LogoutRequestCode -> << >>
      [] message.tag = ClientHeartbeatCode -> << >>
      [] message.tag = NewOrderMessageCode -> EncodeNewOrderMessage(message.body)
      [] message.tag = ModifyOrderMessageCode -> EncodeModifyOrderMessage(message.body)
      [] message.tag = CancelOrderMessageCode -> EncodeCancelOrderMessage(message.body)
      [] message.tag = MassCancelOrderMessageCode -> EncodeMassCancelOrderMessage(message.body)
      [] message.tag = PurgeOrdersMessageCode -> EncodePurgeOrdersMessage(message.body)
      [] message.tag = QuoteUpdateMessageCode -> EncodeQuoteUpdateMessage(message.body)
      [] message.tag = ResetRiskMessageCode -> EncodeResetRiskMessage(message.body)

DecodeFirmMessage(tag, bytes) ==
    LET read ==
            CASE tag = LoginRequestMessageCode -> DecodeLoginRequestMessage(bytes)
              [] tag = LogoutRequestCode -> Ok([empty |-> 0], bytes)
              [] tag = ClientHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = NewOrderMessageCode -> DecodeNewOrderMessage(bytes)
              [] tag = ModifyOrderMessageCode -> DecodeModifyOrderMessage(bytes)
              [] tag = CancelOrderMessageCode -> DecodeCancelOrderMessage(bytes)
              [] tag = MassCancelOrderMessageCode -> DecodeMassCancelOrderMessage(bytes)
              [] tag = PurgeOrdersMessageCode -> DecodePurgeOrdersMessage(bytes)
              [] tag = QuoteUpdateMessageCode -> DecodeQuoteUpdateMessage(bytes)
              [] tag = ResetRiskMessageCode -> DecodeResetRiskMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroFirmMessage == [tag |-> LoginRequestMessageCode, body |-> ZeroLoginRequestMessage]

(* Each Firm Message in turn, at the values the message it names is checked at *)
CheckedFirmMessage ==
    { [tag |-> LoginRequestMessageCode, body |-> one] : one \in CheckedLoginRequestMessage }
        \cup { [tag |-> LogoutRequestCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> ClientHeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> NewOrderMessageCode, body |-> one] : one \in CheckedNewOrderMessage }
        \cup { [tag |-> ModifyOrderMessageCode, body |-> one] : one \in CheckedModifyOrderMessage }
        \cup { [tag |-> CancelOrderMessageCode, body |-> one] : one \in CheckedCancelOrderMessage }
        \cup { [tag |-> MassCancelOrderMessageCode, body |-> one] : one \in CheckedMassCancelOrderMessage }
        \cup { [tag |-> PurgeOrdersMessageCode, body |-> one] : one \in CheckedPurgeOrdersMessage }
        \cup { [tag |-> QuoteUpdateMessageCode, body |-> one] : one \in CheckedQuoteUpdateMessage }
        \cup { [tag |-> ResetRiskMessageCode, body |-> one] : one \in CheckedResetRiskMessage }

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

(* Every New Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderMessage ==
    \A message \in CheckedNewOrderMessage :
        LET read == DecodeNewOrderMessage(EncodeNewOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyOrderMessage ==
    \A message \in CheckedModifyOrderMessage :
        LET read == DecodeModifyOrderMessage(EncodeModifyOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelOrderMessage ==
    \A message \in CheckedCancelOrderMessage :
        LET read == DecodeCancelOrderMessage(EncodeCancelOrderMessage(message))
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

(* Every Mass Cancel Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMassCancelOrderMessage ==
    \A message \in CheckedMassCancelOrderMessage :
        LET read == DecodeMassCancelOrderMessage(EncodeMassCancelOrderMessage(message))
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

(* Every Purge Orders Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPurgeOrdersMessage ==
    \A message \in CheckedPurgeOrdersMessage :
        LET read == DecodePurgeOrdersMessage(EncodePurgeOrdersMessage(message))
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

(* Every Quote Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteUpdateMessage ==
    \A message \in CheckedQuoteUpdateMessage :
        LET read == DecodeQuoteUpdateMessage(EncodeQuoteUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reset Risk Message decodes back to what was encoded, and leaves nothing over *)
RoundTripResetRiskMessage ==
    \A message \in CheckedResetRiskMessage :
        LET read == DecodeResetRiskMessage(EncodeResetRiskMessage(message))
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
