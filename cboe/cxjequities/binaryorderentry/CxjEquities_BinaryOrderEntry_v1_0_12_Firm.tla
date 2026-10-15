------------- MODULE CxjEquities_BinaryOrderEntry_v1_0_12_Firm -------------
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
(* New Order Jp Equities V 1: 87 bytes                                     *)
(***************************************************************************)

NewOrderJpEquitiesV1 ==
    [ account               : Sample(10),
      tradingFirm           : Sample(4),
      clOrdId               : Sample(20),
      orderQty              : Sample(4),
      ordType               : Sample(1),
      price                 : Sample(8),
      capacity              : Sample(1),
      side                  : Sample(1),
      symbol                : Sample(8),
      timeInForce           : Sample(1),
      expireTime            : Sample(8),
      cashMargin            : Sample(1),
      riskGroupId           : Sample(2),
      noTradeFeat           : Sample(1),
      noTradeKey            : Sample(10),
      postingInstruction    : Sample(1),
      orderClassification   : Sample(1),
      marginTransactionType : Sample(1),
      companyId             : Sample(4) ]

EncodeNewOrderJpEquitiesV1(message) ==
    message.account
        \o message.tradingFirm
        \o message.clOrdId
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
        \o message.companyId

DecodeNewOrderJpEquitiesV1(bytes) ==
    LET account == ReadBytes(bytes, 10) IN IF ~account.ok THEN Fail ELSE
    LET tradingFirm == ReadBytes(account.rest, 4) IN IF ~tradingFirm.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(tradingFirm.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(clOrdId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
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
    LET companyId == ReadBytes(marginTransactionType.rest, 4) IN IF ~companyId.ok THEN Fail ELSE
    Ok([ account               |-> account.value,
         tradingFirm           |-> tradingFirm.value,
         clOrdId               |-> clOrdId.value,
         orderQty              |-> orderQty.value,
         ordType               |-> ordType.value,
         price                 |-> price.value,
         capacity              |-> capacity.value,
         side                  |-> side.value,
         symbol                |-> symbol.value,
         timeInForce           |-> timeInForce.value,
         expireTime            |-> expireTime.value,
         cashMargin            |-> cashMargin.value,
         riskGroupId           |-> riskGroupId.value,
         noTradeFeat           |-> noTradeFeat.value,
         noTradeKey            |-> noTradeKey.value,
         postingInstruction    |-> postingInstruction.value,
         orderClassification   |-> orderClassification.value,
         marginTransactionType |-> marginTransactionType.value,
         companyId             |-> companyId.value ], companyId.rest)

ZeroNewOrderJpEquitiesV1 ==
    [ account               |-> [i \in 1 .. 10 |-> 0],
      tradingFirm           |-> [i \in 1 .. 4 |-> 0],
      clOrdId               |-> [i \in 1 .. 20 |-> 0],
      orderQty              |-> [i \in 1 .. 4 |-> 0],
      ordType               |-> [i \in 1 .. 1 |-> 0],
      price                 |-> [i \in 1 .. 8 |-> 0],
      capacity              |-> [i \in 1 .. 1 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      symbol                |-> [i \in 1 .. 8 |-> 0],
      timeInForce           |-> [i \in 1 .. 1 |-> 0],
      expireTime            |-> [i \in 1 .. 8 |-> 0],
      cashMargin            |-> [i \in 1 .. 1 |-> 0],
      riskGroupId           |-> [i \in 1 .. 2 |-> 0],
      noTradeFeat           |-> [i \in 1 .. 1 |-> 0],
      noTradeKey            |-> [i \in 1 .. 10 |-> 0],
      postingInstruction    |-> [i \in 1 .. 1 |-> 0],
      orderClassification   |-> [i \in 1 .. 1 |-> 0],
      marginTransactionType |-> [i \in 1 .. 1 |-> 0],
      companyId             |-> [i \in 1 .. 4 |-> 0] ]

(* New Order Jp Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderJpEquitiesV1 ==
    { ZeroNewOrderJpEquitiesV1 }
        \cup { [ZeroNewOrderJpEquitiesV1 EXCEPT !.account = one] : one \in Sample(10) }
        \cup { [ZeroNewOrderJpEquitiesV1 EXCEPT !.tradingFirm = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderJpEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderJpEquitiesV1 EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderJpEquitiesV1 EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderJpEquitiesV1 EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderJpEquitiesV1 EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderJpEquitiesV1 EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderJpEquitiesV1 EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderJpEquitiesV1 EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderJpEquitiesV1 EXCEPT !.expireTime = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderJpEquitiesV1 EXCEPT !.cashMargin = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderJpEquitiesV1 EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderJpEquitiesV1 EXCEPT !.noTradeFeat = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderJpEquitiesV1 EXCEPT !.noTradeKey = one] : one \in Sample(10) }
        \cup { [ZeroNewOrderJpEquitiesV1 EXCEPT !.postingInstruction = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderJpEquitiesV1 EXCEPT !.orderClassification = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderJpEquitiesV1 EXCEPT !.marginTransactionType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderJpEquitiesV1 EXCEPT !.companyId = one] : one \in Sample(4) }

(***************************************************************************)
(* Modify Order Jp Equities V 1: 57 bytes                                  *)
(***************************************************************************)

ModifyOrderJpEquitiesV1 ==
    [ tradingFirm        : Sample(4),
      clOrdId            : Sample(20),
      orderQty           : Sample(4),
      origClOrdId        : Sample(20),
      price              : Sample(8),
      cancelOrigOnReject : Sample(1) ]

EncodeModifyOrderJpEquitiesV1(message) ==
    message.tradingFirm
        \o message.clOrdId
        \o message.orderQty
        \o message.origClOrdId
        \o message.price
        \o message.cancelOrigOnReject

DecodeModifyOrderJpEquitiesV1(bytes) ==
    LET tradingFirm == ReadBytes(bytes, 4) IN IF ~tradingFirm.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(tradingFirm.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(clOrdId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(orderQty.rest, 20) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET price == ReadBytes(origClOrdId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET cancelOrigOnReject == ReadBytes(price.rest, 1) IN IF ~cancelOrigOnReject.ok THEN Fail ELSE
    Ok([ tradingFirm        |-> tradingFirm.value,
         clOrdId            |-> clOrdId.value,
         orderQty           |-> orderQty.value,
         origClOrdId        |-> origClOrdId.value,
         price              |-> price.value,
         cancelOrigOnReject |-> cancelOrigOnReject.value ], cancelOrigOnReject.rest)

ZeroModifyOrderJpEquitiesV1 ==
    [ tradingFirm        |-> [i \in 1 .. 4 |-> 0],
      clOrdId            |-> [i \in 1 .. 20 |-> 0],
      orderQty           |-> [i \in 1 .. 4 |-> 0],
      origClOrdId        |-> [i \in 1 .. 20 |-> 0],
      price              |-> [i \in 1 .. 8 |-> 0],
      cancelOrigOnReject |-> [i \in 1 .. 1 |-> 0] ]

(* Modify Order Jp Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderJpEquitiesV1 ==
    { ZeroModifyOrderJpEquitiesV1 }
        \cup { [ZeroModifyOrderJpEquitiesV1 EXCEPT !.tradingFirm = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderJpEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroModifyOrderJpEquitiesV1 EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderJpEquitiesV1 EXCEPT !.origClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroModifyOrderJpEquitiesV1 EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderJpEquitiesV1 EXCEPT !.cancelOrigOnReject = one] : one \in Sample(1) }

(***************************************************************************)
(* Cancel Order Jp Equities V 1: 24 bytes                                  *)
(***************************************************************************)

CancelOrderJpEquitiesV1 ==
    [ tradingFirm : Sample(4),
      origClOrdId : Sample(20) ]

EncodeCancelOrderJpEquitiesV1(message) ==
    message.tradingFirm
        \o message.origClOrdId

DecodeCancelOrderJpEquitiesV1(bytes) ==
    LET tradingFirm == ReadBytes(bytes, 4) IN IF ~tradingFirm.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(tradingFirm.rest, 20) IN IF ~origClOrdId.ok THEN Fail ELSE
    Ok([ tradingFirm |-> tradingFirm.value,
         origClOrdId |-> origClOrdId.value ], origClOrdId.rest)

ZeroCancelOrderJpEquitiesV1 ==
    [ tradingFirm |-> [i \in 1 .. 4 |-> 0],
      origClOrdId |-> [i \in 1 .. 20 |-> 0] ]

(* Cancel Order Jp Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedCancelOrderJpEquitiesV1 ==
    { ZeroCancelOrderJpEquitiesV1 }
        \cup { [ZeroCancelOrderJpEquitiesV1 EXCEPT !.tradingFirm = one] : one \in Sample(4) }
        \cup { [ZeroCancelOrderJpEquitiesV1 EXCEPT !.origClOrdId = one] : one \in Sample(20) }

(***************************************************************************)
(* Purge Orders Jp Equities V 1: 51 bytes                                  *)
(***************************************************************************)

PurgeOrdersJpEquitiesV1 ==
    [ tradingFirm    : Sample(4),
      massCancelInst : Sample(16),
      massCancelId   : Sample(20),
      symbol         : Sample(8),
      riskGroupIdCnt : 0 .. 255,
      riskGroupId    : Sample(2) ]

EncodePurgeOrdersJpEquitiesV1(message) ==
    message.tradingFirm
        \o message.massCancelInst
        \o message.massCancelId
        \o message.symbol
        \o EncodeUIntLE(message.riskGroupIdCnt, 1)
        \o message.riskGroupId

DecodePurgeOrdersJpEquitiesV1(bytes) ==
    LET tradingFirm == ReadBytes(bytes, 4) IN IF ~tradingFirm.ok THEN Fail ELSE
    LET massCancelInst == ReadBytes(tradingFirm.rest, 16) IN IF ~massCancelInst.ok THEN Fail ELSE
    LET massCancelId == ReadBytes(massCancelInst.rest, 20) IN IF ~massCancelId.ok THEN Fail ELSE
    LET symbol == ReadBytes(massCancelId.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET riskGroupIdCnt == ReadUIntLE(symbol.rest, 1) IN IF ~riskGroupIdCnt.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(riskGroupIdCnt.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    Ok([ tradingFirm    |-> tradingFirm.value,
         massCancelInst |-> massCancelInst.value,
         massCancelId   |-> massCancelId.value,
         symbol         |-> symbol.value,
         riskGroupIdCnt |-> riskGroupIdCnt.value,
         riskGroupId    |-> riskGroupId.value ], riskGroupId.rest)

ZeroPurgeOrdersJpEquitiesV1 ==
    [ tradingFirm    |-> [i \in 1 .. 4 |-> 0],
      massCancelInst |-> [i \in 1 .. 16 |-> 0],
      massCancelId   |-> [i \in 1 .. 20 |-> 0],
      symbol         |-> [i \in 1 .. 8 |-> 0],
      riskGroupIdCnt |-> 0,
      riskGroupId    |-> [i \in 1 .. 2 |-> 0] ]

(* Purge Orders Jp Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedPurgeOrdersJpEquitiesV1 ==
    { ZeroPurgeOrdersJpEquitiesV1 }
        \cup { [ZeroPurgeOrdersJpEquitiesV1 EXCEPT !.tradingFirm = one] : one \in Sample(4) }
        \cup { [ZeroPurgeOrdersJpEquitiesV1 EXCEPT !.massCancelInst = one] : one \in Sample(16) }
        \cup { [ZeroPurgeOrdersJpEquitiesV1 EXCEPT !.massCancelId = one] : one \in Sample(20) }
        \cup { [ZeroPurgeOrdersJpEquitiesV1 EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroPurgeOrdersJpEquitiesV1 EXCEPT !.riskGroupIdCnt = one] : one \in {0, 1, 255} }
        \cup { [ZeroPurgeOrdersJpEquitiesV1 EXCEPT !.riskGroupId = one] : one \in Sample(2) }

(***************************************************************************)
(* Firm Message, selected by Firm Message Type                             *)
(***************************************************************************)

LoginRequestMessageCode == 1  \* 0x01
LogoutRequestCode == 2  \* 0x02
ClientHeartbeatCode == 3  \* 0x03
NewOrderJpEquitiesV1Code == 5001  \* 0x1389
ModifyOrderJpEquitiesV1Code == 5002  \* 0x138a
CancelOrderJpEquitiesV1Code == 5003  \* 0x138b
PurgeOrdersJpEquitiesV1Code == 5004  \* 0x138c

FirmMessage ==
    [ tag : {LoginRequestMessageCode}, body : LoginRequestMessage ]
        \cup [ tag : {LogoutRequestCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ClientHeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {NewOrderJpEquitiesV1Code}, body : NewOrderJpEquitiesV1 ]
        \cup [ tag : {ModifyOrderJpEquitiesV1Code}, body : ModifyOrderJpEquitiesV1 ]
        \cup [ tag : {CancelOrderJpEquitiesV1Code}, body : CancelOrderJpEquitiesV1 ]
        \cup [ tag : {PurgeOrdersJpEquitiesV1Code}, body : PurgeOrdersJpEquitiesV1 ]

EncodeFirmMessage(message) ==
    CASE message.tag = LoginRequestMessageCode -> EncodeLoginRequestMessage(message.body)
      [] message.tag = LogoutRequestCode -> << >>
      [] message.tag = ClientHeartbeatCode -> << >>
      [] message.tag = NewOrderJpEquitiesV1Code -> EncodeNewOrderJpEquitiesV1(message.body)
      [] message.tag = ModifyOrderJpEquitiesV1Code -> EncodeModifyOrderJpEquitiesV1(message.body)
      [] message.tag = CancelOrderJpEquitiesV1Code -> EncodeCancelOrderJpEquitiesV1(message.body)
      [] message.tag = PurgeOrdersJpEquitiesV1Code -> EncodePurgeOrdersJpEquitiesV1(message.body)

DecodeFirmMessage(tag, bytes) ==
    LET read ==
            CASE tag = LoginRequestMessageCode -> DecodeLoginRequestMessage(bytes)
              [] tag = LogoutRequestCode -> Ok([empty |-> 0], bytes)
              [] tag = ClientHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = NewOrderJpEquitiesV1Code -> DecodeNewOrderJpEquitiesV1(bytes)
              [] tag = ModifyOrderJpEquitiesV1Code -> DecodeModifyOrderJpEquitiesV1(bytes)
              [] tag = CancelOrderJpEquitiesV1Code -> DecodeCancelOrderJpEquitiesV1(bytes)
              [] tag = PurgeOrdersJpEquitiesV1Code -> DecodePurgeOrdersJpEquitiesV1(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroFirmMessage == [tag |-> LoginRequestMessageCode, body |-> ZeroLoginRequestMessage]

(* Each Firm Message in turn, at the values the message it names is checked at *)
CheckedFirmMessage ==
    { [tag |-> LoginRequestMessageCode, body |-> one] : one \in CheckedLoginRequestMessage }
        \cup { [tag |-> LogoutRequestCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> ClientHeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> NewOrderJpEquitiesV1Code, body |-> one] : one \in CheckedNewOrderJpEquitiesV1 }
        \cup { [tag |-> ModifyOrderJpEquitiesV1Code, body |-> one] : one \in CheckedModifyOrderJpEquitiesV1 }
        \cup { [tag |-> CancelOrderJpEquitiesV1Code, body |-> one] : one \in CheckedCancelOrderJpEquitiesV1 }
        \cup { [tag |-> PurgeOrdersJpEquitiesV1Code, body |-> one] : one \in CheckedPurgeOrdersJpEquitiesV1 }

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

(* Every New Order Jp Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderJpEquitiesV1 ==
    \A message \in CheckedNewOrderJpEquitiesV1 :
        LET read == DecodeNewOrderJpEquitiesV1(EncodeNewOrderJpEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Order Jp Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyOrderJpEquitiesV1 ==
    \A message \in CheckedModifyOrderJpEquitiesV1 :
        LET read == DecodeModifyOrderJpEquitiesV1(EncodeModifyOrderJpEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Order Jp Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelOrderJpEquitiesV1 ==
    \A message \in CheckedCancelOrderJpEquitiesV1 :
        LET read == DecodeCancelOrderJpEquitiesV1(EncodeCancelOrderJpEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Purge Orders Jp Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripPurgeOrdersJpEquitiesV1 ==
    \A message \in CheckedPurgeOrdersJpEquitiesV1 :
        LET read == DecodePurgeOrdersJpEquitiesV1(EncodePurgeOrdersJpEquitiesV1(message))
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
