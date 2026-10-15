------------------ MODULE MemxOptions_Memo_v1_6_a_Client -------------------
(***************************************************************************)
(* The Members Exchange Members Orders v1.6.a                              *)
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
(*                                                                         *)
(* Note: Exec Inst is a bit field set, checked as its 2 bytes rather than  *)
(* bit by bit.                                                             *)
(*                                                                         *)
(* Note: Mass Cancel Inst is a bit field set, checked as its 1 byte rather *)
(* than bit by bit.                                                        *)
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
(* Login Request Message: 2 bytes                                          *)
(***************************************************************************)

LoginRequestMessage ==
    [ tokenType : Sample(1),
      token     : Sample(1) ]

EncodeLoginRequestMessage(message) ==
    message.tokenType
        \o message.token

DecodeLoginRequestMessage(bytes) ==
    LET tokenType == ReadBytes(bytes, 1) IN IF ~tokenType.ok THEN Fail ELSE
    LET token == ReadBytes(tokenType.rest, 1) IN IF ~token.ok THEN Fail ELSE
    Ok([ tokenType |-> tokenType.value,
         token     |-> token.value ], token.rest)

ZeroLoginRequestMessage ==
    [ tokenType |-> [i \in 1 .. 1 |-> 0],
      token     |-> [i \in 1 .. 1 |-> 0] ]

(* Login Request Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginRequestMessage ==
    { ZeroLoginRequestMessage }
        \cup { [ZeroLoginRequestMessage EXCEPT !.tokenType = one] : one \in Sample(1) }
        \cup { [ZeroLoginRequestMessage EXCEPT !.token = one] : one \in Sample(1) }

(***************************************************************************)
(* Replay Request Message: 20 bytes                                        *)
(***************************************************************************)

ReplayRequestMessage ==
    [ sessionId          : Sample(8),
      nextSequenceNumber : Sample(8),
      count              : Sample(4) ]

EncodeReplayRequestMessage(message) ==
    message.sessionId
        \o message.nextSequenceNumber
        \o message.count

DecodeReplayRequestMessage(bytes) ==
    LET sessionId == ReadBytes(bytes, 8) IN IF ~sessionId.ok THEN Fail ELSE
    LET nextSequenceNumber == ReadBytes(sessionId.rest, 8) IN IF ~nextSequenceNumber.ok THEN Fail ELSE
    LET count == ReadBytes(nextSequenceNumber.rest, 4) IN IF ~count.ok THEN Fail ELSE
    Ok([ sessionId          |-> sessionId.value,
         nextSequenceNumber |-> nextSequenceNumber.value,
         count              |-> count.value ], count.rest)

ZeroReplayRequestMessage ==
    [ sessionId          |-> [i \in 1 .. 8 |-> 0],
      nextSequenceNumber |-> [i \in 1 .. 8 |-> 0],
      count              |-> [i \in 1 .. 4 |-> 0] ]

(* Replay Request Message at zero, then each field in turn at the values it is checked at *)
CheckedReplayRequestMessage ==
    { ZeroReplayRequestMessage }
        \cup { [ZeroReplayRequestMessage EXCEPT !.sessionId = one] : one \in Sample(8) }
        \cup { [ZeroReplayRequestMessage EXCEPT !.nextSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroReplayRequestMessage EXCEPT !.count = one] : one \in Sample(4) }

(***************************************************************************)
(* Replay All Request Message: 8 bytes                                     *)
(***************************************************************************)

ReplayAllRequestMessage ==
    [ sessionId : Sample(8) ]

EncodeReplayAllRequestMessage(message) ==
    message.sessionId

DecodeReplayAllRequestMessage(bytes) ==
    LET sessionId == ReadBytes(bytes, 8) IN IF ~sessionId.ok THEN Fail ELSE
    Ok([ sessionId |-> sessionId.value ], sessionId.rest)

ZeroReplayAllRequestMessage ==
    [ sessionId |-> [i \in 1 .. 8 |-> 0] ]

(* Replay All Request Message at zero, then each field in turn at the values it is checked at *)
CheckedReplayAllRequestMessage ==
    { ZeroReplayAllRequestMessage }
        \cup { [ZeroReplayAllRequestMessage EXCEPT !.sessionId = one] : one \in Sample(8) }

(***************************************************************************)
(* Stream Request Message: 16 bytes                                        *)
(***************************************************************************)

StreamRequestMessage ==
    [ sessionId          : Sample(8),
      nextSequenceNumber : Sample(8) ]

EncodeStreamRequestMessage(message) ==
    message.sessionId
        \o message.nextSequenceNumber

DecodeStreamRequestMessage(bytes) ==
    LET sessionId == ReadBytes(bytes, 8) IN IF ~sessionId.ok THEN Fail ELSE
    LET nextSequenceNumber == ReadBytes(sessionId.rest, 8) IN IF ~nextSequenceNumber.ok THEN Fail ELSE
    Ok([ sessionId          |-> sessionId.value,
         nextSequenceNumber |-> nextSequenceNumber.value ], nextSequenceNumber.rest)

ZeroStreamRequestMessage ==
    [ sessionId          |-> [i \in 1 .. 8 |-> 0],
      nextSequenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Stream Request Message at zero, then each field in turn at the values it is checked at *)
CheckedStreamRequestMessage ==
    { ZeroStreamRequestMessage }
        \cup { [ZeroStreamRequestMessage EXCEPT !.sessionId = one] : one \in Sample(8) }
        \cup { [ZeroStreamRequestMessage EXCEPT !.nextSequenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Parties Group: 18 bytes                                                 *)
(***************************************************************************)

PartiesGroup ==
    [ partyId       : Sample(16),
      partyIdSource : Sample(1),
      partyRole     : Sample(1) ]

EncodePartiesGroup(message) ==
    message.partyId
        \o message.partyIdSource
        \o message.partyRole

DecodePartiesGroup(bytes) ==
    LET partyId == ReadBytes(bytes, 16) IN IF ~partyId.ok THEN Fail ELSE
    LET partyIdSource == ReadBytes(partyId.rest, 1) IN IF ~partyIdSource.ok THEN Fail ELSE
    LET partyRole == ReadBytes(partyIdSource.rest, 1) IN IF ~partyRole.ok THEN Fail ELSE
    Ok([ partyId       |-> partyId.value,
         partyIdSource |-> partyIdSource.value,
         partyRole     |-> partyRole.value ], partyRole.rest)

ZeroPartiesGroup ==
    [ partyId       |-> [i \in 1 .. 16 |-> 0],
      partyIdSource |-> [i \in 1 .. 1 |-> 0],
      partyRole     |-> [i \in 1 .. 1 |-> 0] ]

(* Parties Group at zero, then each field in turn at the values it is checked at *)
CheckedPartiesGroup ==
    { ZeroPartiesGroup }
        \cup { [ZeroPartiesGroup EXCEPT !.partyId = one] : one \in Sample(16) }
        \cup { [ZeroPartiesGroup EXCEPT !.partyIdSource = one] : one \in Sample(1) }
        \cup { [ZeroPartiesGroup EXCEPT !.partyRole = one] : one \in Sample(1) }

(* A run of Parties Group, written one after another *)
RECURSIVE EncodePartiesGroupList(_)
EncodePartiesGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodePartiesGroup(Head(messages)) \o EncodePartiesGroupList(Tail(messages))

(* As many Parties Group as the field that counts them says *)
RECURSIVE ReadPartiesGroupList(_, _)
ReadPartiesGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodePartiesGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadPartiesGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Parties Group of each kind, for the lists that carry them *)
OnePartiesGroup == { ZeroPartiesGroup }

(***************************************************************************)
(* Parties Groups                                                          *)
(***************************************************************************)

PartiesGroups ==
    [ blockLengthShort : Sample(1),
      partiesGroup     : SampleLists(OnePartiesGroup) ]

EncodePartiesGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.partiesGroup), 1)
        \o EncodePartiesGroupList(message.partiesGroup)

DecodePartiesGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET partiesGroup == ReadPartiesGroupList(numInGroup.rest, numInGroup.value) IN IF ~partiesGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort |-> blockLengthShort.value,
         partiesGroup     |-> partiesGroup.value ], partiesGroup.rest)

ZeroPartiesGroups ==
    [ blockLengthShort |-> [i \in 1 .. 1 |-> 0],
      partiesGroup     |-> << >> ]

(* Parties Groups at zero, then each field in turn at the values it is checked at *)
CheckedPartiesGroups ==
    { ZeroPartiesGroups }
        \cup { [ZeroPartiesGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroPartiesGroups EXCEPT !.partiesGroup = one] : one \in SampleLists(OnePartiesGroup) }

(***************************************************************************)
(* New Order Single Message                                                *)
(***************************************************************************)

NewOrderSingleMessage ==
    [ sendingTime            : Sample(8),
      clordid                : Sample(20),
      securityId             : Sample(8),
      side                   : Sample(1),
      orderQty               : Sample(4),
      ordType                : Sample(1),
      priceOptional          : Sample(8),
      timeInForce            : Sample(1),
      positionEffectOptional : Sample(1),
      execInst               : Sample(2),
      tradingCapacity        : Sample(1),
      repriceFrequency       : Sample(1),
      repriceBehavior        : Sample(1),
      mtpGroupId             : Sample(2),
      matchTradePrevention   : Sample(1),
      cancelGroupId          : Sample(2),
      riskGroupId            : Sample(2),
      partiesGroups          : PartiesGroups ]

EncodeNewOrderSingleMessage(message) ==
    message.sendingTime
        \o message.clordid
        \o message.securityId
        \o message.side
        \o message.orderQty
        \o message.ordType
        \o message.priceOptional
        \o message.timeInForce
        \o message.positionEffectOptional
        \o message.execInst
        \o message.tradingCapacity
        \o message.repriceFrequency
        \o message.repriceBehavior
        \o message.mtpGroupId
        \o message.matchTradePrevention
        \o message.cancelGroupId
        \o message.riskGroupId
        \o EncodePartiesGroups(message.partiesGroups)

DecodeNewOrderSingleMessage(bytes) ==
    LET sendingTime == ReadBytes(bytes, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET clordid == ReadBytes(sendingTime.rest, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET securityId == ReadBytes(clordid.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET side == ReadBytes(securityId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderQty == ReadBytes(side.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET ordType == ReadBytes(orderQty.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET priceOptional == ReadBytes(ordType.rest, 8) IN IF ~priceOptional.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(priceOptional.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET positionEffectOptional == ReadBytes(timeInForce.rest, 1) IN IF ~positionEffectOptional.ok THEN Fail ELSE
    LET execInst == ReadBytes(positionEffectOptional.rest, 2) IN IF ~execInst.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(execInst.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET repriceFrequency == ReadBytes(tradingCapacity.rest, 1) IN IF ~repriceFrequency.ok THEN Fail ELSE
    LET repriceBehavior == ReadBytes(repriceFrequency.rest, 1) IN IF ~repriceBehavior.ok THEN Fail ELSE
    LET mtpGroupId == ReadBytes(repriceBehavior.rest, 2) IN IF ~mtpGroupId.ok THEN Fail ELSE
    LET matchTradePrevention == ReadBytes(mtpGroupId.rest, 1) IN IF ~matchTradePrevention.ok THEN Fail ELSE
    LET cancelGroupId == ReadBytes(matchTradePrevention.rest, 2) IN IF ~cancelGroupId.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(cancelGroupId.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET partiesGroups == DecodePartiesGroups(riskGroupId.rest) IN IF ~partiesGroups.ok THEN Fail ELSE
    Ok([ sendingTime            |-> sendingTime.value,
         clordid                |-> clordid.value,
         securityId             |-> securityId.value,
         side                   |-> side.value,
         orderQty               |-> orderQty.value,
         ordType                |-> ordType.value,
         priceOptional          |-> priceOptional.value,
         timeInForce            |-> timeInForce.value,
         positionEffectOptional |-> positionEffectOptional.value,
         execInst               |-> execInst.value,
         tradingCapacity        |-> tradingCapacity.value,
         repriceFrequency       |-> repriceFrequency.value,
         repriceBehavior        |-> repriceBehavior.value,
         mtpGroupId             |-> mtpGroupId.value,
         matchTradePrevention   |-> matchTradePrevention.value,
         cancelGroupId          |-> cancelGroupId.value,
         riskGroupId            |-> riskGroupId.value,
         partiesGroups          |-> partiesGroups.value ], partiesGroups.rest)

ZeroNewOrderSingleMessage ==
    [ sendingTime            |-> [i \in 1 .. 8 |-> 0],
      clordid                |-> [i \in 1 .. 20 |-> 0],
      securityId             |-> [i \in 1 .. 8 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      orderQty               |-> [i \in 1 .. 4 |-> 0],
      ordType                |-> [i \in 1 .. 1 |-> 0],
      priceOptional          |-> [i \in 1 .. 8 |-> 0],
      timeInForce            |-> [i \in 1 .. 1 |-> 0],
      positionEffectOptional |-> [i \in 1 .. 1 |-> 0],
      execInst               |-> [i \in 1 .. 2 |-> 0],
      tradingCapacity        |-> [i \in 1 .. 1 |-> 0],
      repriceFrequency       |-> [i \in 1 .. 1 |-> 0],
      repriceBehavior        |-> [i \in 1 .. 1 |-> 0],
      mtpGroupId             |-> [i \in 1 .. 2 |-> 0],
      matchTradePrevention   |-> [i \in 1 .. 1 |-> 0],
      cancelGroupId          |-> [i \in 1 .. 2 |-> 0],
      riskGroupId            |-> [i \in 1 .. 2 |-> 0],
      partiesGroups          |-> ZeroPartiesGroups ]

(* New Order Single Message at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderSingleMessage ==
    { ZeroNewOrderSingleMessage }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.priceOptional = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.positionEffectOptional = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.execInst = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.repriceFrequency = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.repriceBehavior = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.mtpGroupId = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.matchTradePrevention = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.cancelGroupId = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.partiesGroups = one] : one \in CheckedPartiesGroups }

(***************************************************************************)
(* Parties Group: 18 bytes                                                 *)
(***************************************************************************)

PartiesGroup2 ==
    [ partyId       : Sample(16),
      partyIdSource : Sample(1),
      partyRole     : Sample(1) ]

EncodePartiesGroup2(message) ==
    message.partyId
        \o message.partyIdSource
        \o message.partyRole

DecodePartiesGroup2(bytes) ==
    LET partyId == ReadBytes(bytes, 16) IN IF ~partyId.ok THEN Fail ELSE
    LET partyIdSource == ReadBytes(partyId.rest, 1) IN IF ~partyIdSource.ok THEN Fail ELSE
    LET partyRole == ReadBytes(partyIdSource.rest, 1) IN IF ~partyRole.ok THEN Fail ELSE
    Ok([ partyId       |-> partyId.value,
         partyIdSource |-> partyIdSource.value,
         partyRole     |-> partyRole.value ], partyRole.rest)

ZeroPartiesGroup2 ==
    [ partyId       |-> [i \in 1 .. 16 |-> 0],
      partyIdSource |-> [i \in 1 .. 1 |-> 0],
      partyRole     |-> [i \in 1 .. 1 |-> 0] ]

(* Parties Group at zero, then each field in turn at the values it is checked at *)
CheckedPartiesGroup2 ==
    { ZeroPartiesGroup2 }
        \cup { [ZeroPartiesGroup2 EXCEPT !.partyId = one] : one \in Sample(16) }
        \cup { [ZeroPartiesGroup2 EXCEPT !.partyIdSource = one] : one \in Sample(1) }
        \cup { [ZeroPartiesGroup2 EXCEPT !.partyRole = one] : one \in Sample(1) }

(* A run of Parties Group, written one after another *)
RECURSIVE EncodePartiesGroup2List(_)
EncodePartiesGroup2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodePartiesGroup2(Head(messages)) \o EncodePartiesGroup2List(Tail(messages))

(* As many Parties Group as the field that counts them says *)
RECURSIVE ReadPartiesGroup2List(_, _)
ReadPartiesGroup2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodePartiesGroup2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadPartiesGroup2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Parties Group of each kind, for the lists that carry them *)
OnePartiesGroup2 == { ZeroPartiesGroup2 }

(***************************************************************************)
(* Parties Groups                                                          *)
(***************************************************************************)

PartiesGroups2 ==
    [ blockLengthShort : Sample(1),
      partiesGroup     : SampleLists(OnePartiesGroup2) ]

EncodePartiesGroups2(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.partiesGroup), 1)
        \o EncodePartiesGroup2List(message.partiesGroup)

DecodePartiesGroups2(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET partiesGroup == ReadPartiesGroup2List(numInGroup.rest, numInGroup.value) IN IF ~partiesGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort |-> blockLengthShort.value,
         partiesGroup     |-> partiesGroup.value ], partiesGroup.rest)

ZeroPartiesGroups2 ==
    [ blockLengthShort |-> [i \in 1 .. 1 |-> 0],
      partiesGroup     |-> << >> ]

(* Parties Groups at zero, then each field in turn at the values it is checked at *)
CheckedPartiesGroups2 ==
    { ZeroPartiesGroups2 }
        \cup { [ZeroPartiesGroups2 EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroPartiesGroups2 EXCEPT !.partiesGroup = one] : one \in SampleLists(OnePartiesGroup2) }

(***************************************************************************)
(* Two Sided Quotes Group: 17 bytes                                        *)
(***************************************************************************)

TwoSidedQuotesGroup ==
    [ listSeqNo  : Sample(1),
      securityId : Sample(8),
      bidSize    : Sample(2),
      bidPx      : Sample(2),
      offerSize  : Sample(2),
      offerPx    : Sample(2) ]

EncodeTwoSidedQuotesGroup(message) ==
    message.listSeqNo
        \o message.securityId
        \o message.bidSize
        \o message.bidPx
        \o message.offerSize
        \o message.offerPx

DecodeTwoSidedQuotesGroup(bytes) ==
    LET listSeqNo == ReadBytes(bytes, 1) IN IF ~listSeqNo.ok THEN Fail ELSE
    LET securityId == ReadBytes(listSeqNo.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET bidSize == ReadBytes(securityId.rest, 2) IN IF ~bidSize.ok THEN Fail ELSE
    LET bidPx == ReadBytes(bidSize.rest, 2) IN IF ~bidPx.ok THEN Fail ELSE
    LET offerSize == ReadBytes(bidPx.rest, 2) IN IF ~offerSize.ok THEN Fail ELSE
    LET offerPx == ReadBytes(offerSize.rest, 2) IN IF ~offerPx.ok THEN Fail ELSE
    Ok([ listSeqNo  |-> listSeqNo.value,
         securityId |-> securityId.value,
         bidSize    |-> bidSize.value,
         bidPx      |-> bidPx.value,
         offerSize  |-> offerSize.value,
         offerPx    |-> offerPx.value ], offerPx.rest)

ZeroTwoSidedQuotesGroup ==
    [ listSeqNo  |-> [i \in 1 .. 1 |-> 0],
      securityId |-> [i \in 1 .. 8 |-> 0],
      bidSize    |-> [i \in 1 .. 2 |-> 0],
      bidPx      |-> [i \in 1 .. 2 |-> 0],
      offerSize  |-> [i \in 1 .. 2 |-> 0],
      offerPx    |-> [i \in 1 .. 2 |-> 0] ]

(* Two Sided Quotes Group at zero, then each field in turn at the values it is checked at *)
CheckedTwoSidedQuotesGroup ==
    { ZeroTwoSidedQuotesGroup }
        \cup { [ZeroTwoSidedQuotesGroup EXCEPT !.listSeqNo = one] : one \in Sample(1) }
        \cup { [ZeroTwoSidedQuotesGroup EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroTwoSidedQuotesGroup EXCEPT !.bidSize = one] : one \in Sample(2) }
        \cup { [ZeroTwoSidedQuotesGroup EXCEPT !.bidPx = one] : one \in Sample(2) }
        \cup { [ZeroTwoSidedQuotesGroup EXCEPT !.offerSize = one] : one \in Sample(2) }
        \cup { [ZeroTwoSidedQuotesGroup EXCEPT !.offerPx = one] : one \in Sample(2) }

(* A run of Two Sided Quotes Group, written one after another *)
RECURSIVE EncodeTwoSidedQuotesGroupList(_)
EncodeTwoSidedQuotesGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTwoSidedQuotesGroup(Head(messages)) \o EncodeTwoSidedQuotesGroupList(Tail(messages))

(* As many Two Sided Quotes Group as the field that counts them says *)
RECURSIVE ReadTwoSidedQuotesGroupList(_, _)
ReadTwoSidedQuotesGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeTwoSidedQuotesGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTwoSidedQuotesGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Two Sided Quotes Group of each kind, for the lists that carry them *)
OneTwoSidedQuotesGroup == { ZeroTwoSidedQuotesGroup }

(***************************************************************************)
(* Two Sided Quotes Groups                                                 *)
(***************************************************************************)

TwoSidedQuotesGroups ==
    [ blockLengthShort    : Sample(1),
      twoSidedQuotesGroup : SampleLists(OneTwoSidedQuotesGroup) ]

EncodeTwoSidedQuotesGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.twoSidedQuotesGroup), 1)
        \o EncodeTwoSidedQuotesGroupList(message.twoSidedQuotesGroup)

DecodeTwoSidedQuotesGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET twoSidedQuotesGroup == ReadTwoSidedQuotesGroupList(numInGroup.rest, numInGroup.value) IN IF ~twoSidedQuotesGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort    |-> blockLengthShort.value,
         twoSidedQuotesGroup |-> twoSidedQuotesGroup.value ], twoSidedQuotesGroup.rest)

ZeroTwoSidedQuotesGroups ==
    [ blockLengthShort    |-> [i \in 1 .. 1 |-> 0],
      twoSidedQuotesGroup |-> << >> ]

(* Two Sided Quotes Groups at zero, then each field in turn at the values it is checked at *)
CheckedTwoSidedQuotesGroups ==
    { ZeroTwoSidedQuotesGroups }
        \cup { [ZeroTwoSidedQuotesGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroTwoSidedQuotesGroups EXCEPT !.twoSidedQuotesGroup = one] : one \in SampleLists(OneTwoSidedQuotesGroup) }

(***************************************************************************)
(* Short Two Sided Bulk Quote Message                                      *)
(***************************************************************************)

ShortTwoSidedBulkQuoteMessage ==
    [ sendingTime          : Sample(8),
      clordid              : Sample(20),
      timeInForce          : Sample(1),
      execInst             : Sample(2),
      tradingCapacity      : Sample(1),
      mtpGroupId           : Sample(2),
      matchTradePrevention : Sample(1),
      cancelGroupId        : Sample(2),
      riskGroupId          : Sample(2),
      partiesGroups        : PartiesGroups2,
      twoSidedQuotesGroups : TwoSidedQuotesGroups ]

EncodeShortTwoSidedBulkQuoteMessage(message) ==
    message.sendingTime
        \o message.clordid
        \o message.timeInForce
        \o message.execInst
        \o message.tradingCapacity
        \o message.mtpGroupId
        \o message.matchTradePrevention
        \o message.cancelGroupId
        \o message.riskGroupId
        \o EncodePartiesGroups2(message.partiesGroups)
        \o EncodeTwoSidedQuotesGroups(message.twoSidedQuotesGroups)

DecodeShortTwoSidedBulkQuoteMessage(bytes) ==
    LET sendingTime == ReadBytes(bytes, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET clordid == ReadBytes(sendingTime.rest, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(clordid.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET execInst == ReadBytes(timeInForce.rest, 2) IN IF ~execInst.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(execInst.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET mtpGroupId == ReadBytes(tradingCapacity.rest, 2) IN IF ~mtpGroupId.ok THEN Fail ELSE
    LET matchTradePrevention == ReadBytes(mtpGroupId.rest, 1) IN IF ~matchTradePrevention.ok THEN Fail ELSE
    LET cancelGroupId == ReadBytes(matchTradePrevention.rest, 2) IN IF ~cancelGroupId.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(cancelGroupId.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET partiesGroups == DecodePartiesGroups2(riskGroupId.rest) IN IF ~partiesGroups.ok THEN Fail ELSE
    LET twoSidedQuotesGroups == DecodeTwoSidedQuotesGroups(partiesGroups.rest) IN IF ~twoSidedQuotesGroups.ok THEN Fail ELSE
    Ok([ sendingTime          |-> sendingTime.value,
         clordid              |-> clordid.value,
         timeInForce          |-> timeInForce.value,
         execInst             |-> execInst.value,
         tradingCapacity      |-> tradingCapacity.value,
         mtpGroupId           |-> mtpGroupId.value,
         matchTradePrevention |-> matchTradePrevention.value,
         cancelGroupId        |-> cancelGroupId.value,
         riskGroupId          |-> riskGroupId.value,
         partiesGroups        |-> partiesGroups.value,
         twoSidedQuotesGroups |-> twoSidedQuotesGroups.value ], twoSidedQuotesGroups.rest)

ZeroShortTwoSidedBulkQuoteMessage ==
    [ sendingTime          |-> [i \in 1 .. 8 |-> 0],
      clordid              |-> [i \in 1 .. 20 |-> 0],
      timeInForce          |-> [i \in 1 .. 1 |-> 0],
      execInst             |-> [i \in 1 .. 2 |-> 0],
      tradingCapacity      |-> [i \in 1 .. 1 |-> 0],
      mtpGroupId           |-> [i \in 1 .. 2 |-> 0],
      matchTradePrevention |-> [i \in 1 .. 1 |-> 0],
      cancelGroupId        |-> [i \in 1 .. 2 |-> 0],
      riskGroupId          |-> [i \in 1 .. 2 |-> 0],
      partiesGroups        |-> ZeroPartiesGroups2,
      twoSidedQuotesGroups |-> ZeroTwoSidedQuotesGroups ]

(* Short Two Sided Bulk Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedShortTwoSidedBulkQuoteMessage ==
    { ZeroShortTwoSidedBulkQuoteMessage }
        \cup { [ZeroShortTwoSidedBulkQuoteMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroShortTwoSidedBulkQuoteMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroShortTwoSidedBulkQuoteMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroShortTwoSidedBulkQuoteMessage EXCEPT !.execInst = one] : one \in Sample(2) }
        \cup { [ZeroShortTwoSidedBulkQuoteMessage EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroShortTwoSidedBulkQuoteMessage EXCEPT !.mtpGroupId = one] : one \in Sample(2) }
        \cup { [ZeroShortTwoSidedBulkQuoteMessage EXCEPT !.matchTradePrevention = one] : one \in Sample(1) }
        \cup { [ZeroShortTwoSidedBulkQuoteMessage EXCEPT !.cancelGroupId = one] : one \in Sample(2) }
        \cup { [ZeroShortTwoSidedBulkQuoteMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroShortTwoSidedBulkQuoteMessage EXCEPT !.partiesGroups = one] : one \in CheckedPartiesGroups2 }
        \cup { [ZeroShortTwoSidedBulkQuoteMessage EXCEPT !.twoSidedQuotesGroups = one] : one \in CheckedTwoSidedQuotesGroups }

(***************************************************************************)
(* Parties Group: 18 bytes                                                 *)
(***************************************************************************)

PartiesGroup3 ==
    [ partyId       : Sample(16),
      partyIdSource : Sample(1),
      partyRole     : Sample(1) ]

EncodePartiesGroup3(message) ==
    message.partyId
        \o message.partyIdSource
        \o message.partyRole

DecodePartiesGroup3(bytes) ==
    LET partyId == ReadBytes(bytes, 16) IN IF ~partyId.ok THEN Fail ELSE
    LET partyIdSource == ReadBytes(partyId.rest, 1) IN IF ~partyIdSource.ok THEN Fail ELSE
    LET partyRole == ReadBytes(partyIdSource.rest, 1) IN IF ~partyRole.ok THEN Fail ELSE
    Ok([ partyId       |-> partyId.value,
         partyIdSource |-> partyIdSource.value,
         partyRole     |-> partyRole.value ], partyRole.rest)

ZeroPartiesGroup3 ==
    [ partyId       |-> [i \in 1 .. 16 |-> 0],
      partyIdSource |-> [i \in 1 .. 1 |-> 0],
      partyRole     |-> [i \in 1 .. 1 |-> 0] ]

(* Parties Group at zero, then each field in turn at the values it is checked at *)
CheckedPartiesGroup3 ==
    { ZeroPartiesGroup3 }
        \cup { [ZeroPartiesGroup3 EXCEPT !.partyId = one] : one \in Sample(16) }
        \cup { [ZeroPartiesGroup3 EXCEPT !.partyIdSource = one] : one \in Sample(1) }
        \cup { [ZeroPartiesGroup3 EXCEPT !.partyRole = one] : one \in Sample(1) }

(* A run of Parties Group, written one after another *)
RECURSIVE EncodePartiesGroup3List(_)
EncodePartiesGroup3List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodePartiesGroup3(Head(messages)) \o EncodePartiesGroup3List(Tail(messages))

(* As many Parties Group as the field that counts them says *)
RECURSIVE ReadPartiesGroup3List(_, _)
ReadPartiesGroup3List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodePartiesGroup3(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadPartiesGroup3List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Parties Group of each kind, for the lists that carry them *)
OnePartiesGroup3 == { ZeroPartiesGroup3 }

(***************************************************************************)
(* Parties Groups                                                          *)
(***************************************************************************)

PartiesGroups3 ==
    [ blockLengthShort : Sample(1),
      partiesGroup     : SampleLists(OnePartiesGroup3) ]

EncodePartiesGroups3(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.partiesGroup), 1)
        \o EncodePartiesGroup3List(message.partiesGroup)

DecodePartiesGroups3(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET partiesGroup == ReadPartiesGroup3List(numInGroup.rest, numInGroup.value) IN IF ~partiesGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort |-> blockLengthShort.value,
         partiesGroup     |-> partiesGroup.value ], partiesGroup.rest)

ZeroPartiesGroups3 ==
    [ blockLengthShort |-> [i \in 1 .. 1 |-> 0],
      partiesGroup     |-> << >> ]

(* Parties Groups at zero, then each field in turn at the values it is checked at *)
CheckedPartiesGroups3 ==
    { ZeroPartiesGroups3 }
        \cup { [ZeroPartiesGroups3 EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroPartiesGroups3 EXCEPT !.partiesGroup = one] : one \in SampleLists(OnePartiesGroup3) }

(***************************************************************************)
(* Two Sided Quotes Group: 17 bytes                                        *)
(***************************************************************************)

TwoSidedQuotesGroup2 ==
    [ listSeqNo  : Sample(1),
      securityId : Sample(8),
      bidSize    : Sample(2),
      bidPx      : Sample(2),
      offerSize  : Sample(2),
      offerPx    : Sample(2) ]

EncodeTwoSidedQuotesGroup2(message) ==
    message.listSeqNo
        \o message.securityId
        \o message.bidSize
        \o message.bidPx
        \o message.offerSize
        \o message.offerPx

DecodeTwoSidedQuotesGroup2(bytes) ==
    LET listSeqNo == ReadBytes(bytes, 1) IN IF ~listSeqNo.ok THEN Fail ELSE
    LET securityId == ReadBytes(listSeqNo.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET bidSize == ReadBytes(securityId.rest, 2) IN IF ~bidSize.ok THEN Fail ELSE
    LET bidPx == ReadBytes(bidSize.rest, 2) IN IF ~bidPx.ok THEN Fail ELSE
    LET offerSize == ReadBytes(bidPx.rest, 2) IN IF ~offerSize.ok THEN Fail ELSE
    LET offerPx == ReadBytes(offerSize.rest, 2) IN IF ~offerPx.ok THEN Fail ELSE
    Ok([ listSeqNo  |-> listSeqNo.value,
         securityId |-> securityId.value,
         bidSize    |-> bidSize.value,
         bidPx      |-> bidPx.value,
         offerSize  |-> offerSize.value,
         offerPx    |-> offerPx.value ], offerPx.rest)

ZeroTwoSidedQuotesGroup2 ==
    [ listSeqNo  |-> [i \in 1 .. 1 |-> 0],
      securityId |-> [i \in 1 .. 8 |-> 0],
      bidSize    |-> [i \in 1 .. 2 |-> 0],
      bidPx      |-> [i \in 1 .. 2 |-> 0],
      offerSize  |-> [i \in 1 .. 2 |-> 0],
      offerPx    |-> [i \in 1 .. 2 |-> 0] ]

(* Two Sided Quotes Group at zero, then each field in turn at the values it is checked at *)
CheckedTwoSidedQuotesGroup2 ==
    { ZeroTwoSidedQuotesGroup2 }
        \cup { [ZeroTwoSidedQuotesGroup2 EXCEPT !.listSeqNo = one] : one \in Sample(1) }
        \cup { [ZeroTwoSidedQuotesGroup2 EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroTwoSidedQuotesGroup2 EXCEPT !.bidSize = one] : one \in Sample(2) }
        \cup { [ZeroTwoSidedQuotesGroup2 EXCEPT !.bidPx = one] : one \in Sample(2) }
        \cup { [ZeroTwoSidedQuotesGroup2 EXCEPT !.offerSize = one] : one \in Sample(2) }
        \cup { [ZeroTwoSidedQuotesGroup2 EXCEPT !.offerPx = one] : one \in Sample(2) }

(* A run of Two Sided Quotes Group, written one after another *)
RECURSIVE EncodeTwoSidedQuotesGroup2List(_)
EncodeTwoSidedQuotesGroup2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTwoSidedQuotesGroup2(Head(messages)) \o EncodeTwoSidedQuotesGroup2List(Tail(messages))

(* As many Two Sided Quotes Group as the field that counts them says *)
RECURSIVE ReadTwoSidedQuotesGroup2List(_, _)
ReadTwoSidedQuotesGroup2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeTwoSidedQuotesGroup2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTwoSidedQuotesGroup2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Two Sided Quotes Group of each kind, for the lists that carry them *)
OneTwoSidedQuotesGroup2 == { ZeroTwoSidedQuotesGroup2 }

(***************************************************************************)
(* Two Sided Quotes Groups                                                 *)
(***************************************************************************)

TwoSidedQuotesGroups2 ==
    [ blockLengthShort    : Sample(1),
      twoSidedQuotesGroup : SampleLists(OneTwoSidedQuotesGroup2) ]

EncodeTwoSidedQuotesGroups2(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.twoSidedQuotesGroup), 1)
        \o EncodeTwoSidedQuotesGroup2List(message.twoSidedQuotesGroup)

DecodeTwoSidedQuotesGroups2(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET twoSidedQuotesGroup == ReadTwoSidedQuotesGroup2List(numInGroup.rest, numInGroup.value) IN IF ~twoSidedQuotesGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort    |-> blockLengthShort.value,
         twoSidedQuotesGroup |-> twoSidedQuotesGroup.value ], twoSidedQuotesGroup.rest)

ZeroTwoSidedQuotesGroups2 ==
    [ blockLengthShort    |-> [i \in 1 .. 1 |-> 0],
      twoSidedQuotesGroup |-> << >> ]

(* Two Sided Quotes Groups at zero, then each field in turn at the values it is checked at *)
CheckedTwoSidedQuotesGroups2 ==
    { ZeroTwoSidedQuotesGroups2 }
        \cup { [ZeroTwoSidedQuotesGroups2 EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroTwoSidedQuotesGroups2 EXCEPT !.twoSidedQuotesGroup = one] : one \in SampleLists(OneTwoSidedQuotesGroup2) }

(***************************************************************************)
(* Long Two Sided Bulk Quote Message                                       *)
(***************************************************************************)

LongTwoSidedBulkQuoteMessage ==
    [ sendingTime          : Sample(8),
      clordid              : Sample(20),
      timeInForce          : Sample(1),
      execInst             : Sample(2),
      tradingCapacity      : Sample(1),
      mtpGroupId           : Sample(2),
      matchTradePrevention : Sample(1),
      cancelGroupId        : Sample(2),
      riskGroupId          : Sample(2),
      partiesGroups        : PartiesGroups3,
      twoSidedQuotesGroups : TwoSidedQuotesGroups2 ]

EncodeLongTwoSidedBulkQuoteMessage(message) ==
    message.sendingTime
        \o message.clordid
        \o message.timeInForce
        \o message.execInst
        \o message.tradingCapacity
        \o message.mtpGroupId
        \o message.matchTradePrevention
        \o message.cancelGroupId
        \o message.riskGroupId
        \o EncodePartiesGroups3(message.partiesGroups)
        \o EncodeTwoSidedQuotesGroups2(message.twoSidedQuotesGroups)

DecodeLongTwoSidedBulkQuoteMessage(bytes) ==
    LET sendingTime == ReadBytes(bytes, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET clordid == ReadBytes(sendingTime.rest, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(clordid.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET execInst == ReadBytes(timeInForce.rest, 2) IN IF ~execInst.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(execInst.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET mtpGroupId == ReadBytes(tradingCapacity.rest, 2) IN IF ~mtpGroupId.ok THEN Fail ELSE
    LET matchTradePrevention == ReadBytes(mtpGroupId.rest, 1) IN IF ~matchTradePrevention.ok THEN Fail ELSE
    LET cancelGroupId == ReadBytes(matchTradePrevention.rest, 2) IN IF ~cancelGroupId.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(cancelGroupId.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET partiesGroups == DecodePartiesGroups3(riskGroupId.rest) IN IF ~partiesGroups.ok THEN Fail ELSE
    LET twoSidedQuotesGroups == DecodeTwoSidedQuotesGroups2(partiesGroups.rest) IN IF ~twoSidedQuotesGroups.ok THEN Fail ELSE
    Ok([ sendingTime          |-> sendingTime.value,
         clordid              |-> clordid.value,
         timeInForce          |-> timeInForce.value,
         execInst             |-> execInst.value,
         tradingCapacity      |-> tradingCapacity.value,
         mtpGroupId           |-> mtpGroupId.value,
         matchTradePrevention |-> matchTradePrevention.value,
         cancelGroupId        |-> cancelGroupId.value,
         riskGroupId          |-> riskGroupId.value,
         partiesGroups        |-> partiesGroups.value,
         twoSidedQuotesGroups |-> twoSidedQuotesGroups.value ], twoSidedQuotesGroups.rest)

ZeroLongTwoSidedBulkQuoteMessage ==
    [ sendingTime          |-> [i \in 1 .. 8 |-> 0],
      clordid              |-> [i \in 1 .. 20 |-> 0],
      timeInForce          |-> [i \in 1 .. 1 |-> 0],
      execInst             |-> [i \in 1 .. 2 |-> 0],
      tradingCapacity      |-> [i \in 1 .. 1 |-> 0],
      mtpGroupId           |-> [i \in 1 .. 2 |-> 0],
      matchTradePrevention |-> [i \in 1 .. 1 |-> 0],
      cancelGroupId        |-> [i \in 1 .. 2 |-> 0],
      riskGroupId          |-> [i \in 1 .. 2 |-> 0],
      partiesGroups        |-> ZeroPartiesGroups3,
      twoSidedQuotesGroups |-> ZeroTwoSidedQuotesGroups2 ]

(* Long Two Sided Bulk Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedLongTwoSidedBulkQuoteMessage ==
    { ZeroLongTwoSidedBulkQuoteMessage }
        \cup { [ZeroLongTwoSidedBulkQuoteMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroLongTwoSidedBulkQuoteMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroLongTwoSidedBulkQuoteMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroLongTwoSidedBulkQuoteMessage EXCEPT !.execInst = one] : one \in Sample(2) }
        \cup { [ZeroLongTwoSidedBulkQuoteMessage EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroLongTwoSidedBulkQuoteMessage EXCEPT !.mtpGroupId = one] : one \in Sample(2) }
        \cup { [ZeroLongTwoSidedBulkQuoteMessage EXCEPT !.matchTradePrevention = one] : one \in Sample(1) }
        \cup { [ZeroLongTwoSidedBulkQuoteMessage EXCEPT !.cancelGroupId = one] : one \in Sample(2) }
        \cup { [ZeroLongTwoSidedBulkQuoteMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroLongTwoSidedBulkQuoteMessage EXCEPT !.partiesGroups = one] : one \in CheckedPartiesGroups3 }
        \cup { [ZeroLongTwoSidedBulkQuoteMessage EXCEPT !.twoSidedQuotesGroups = one] : one \in CheckedTwoSidedQuotesGroups2 }

(***************************************************************************)
(* Parties Group: 18 bytes                                                 *)
(***************************************************************************)

PartiesGroup4 ==
    [ partyId       : Sample(16),
      partyIdSource : Sample(1),
      partyRole     : Sample(1) ]

EncodePartiesGroup4(message) ==
    message.partyId
        \o message.partyIdSource
        \o message.partyRole

DecodePartiesGroup4(bytes) ==
    LET partyId == ReadBytes(bytes, 16) IN IF ~partyId.ok THEN Fail ELSE
    LET partyIdSource == ReadBytes(partyId.rest, 1) IN IF ~partyIdSource.ok THEN Fail ELSE
    LET partyRole == ReadBytes(partyIdSource.rest, 1) IN IF ~partyRole.ok THEN Fail ELSE
    Ok([ partyId       |-> partyId.value,
         partyIdSource |-> partyIdSource.value,
         partyRole     |-> partyRole.value ], partyRole.rest)

ZeroPartiesGroup4 ==
    [ partyId       |-> [i \in 1 .. 16 |-> 0],
      partyIdSource |-> [i \in 1 .. 1 |-> 0],
      partyRole     |-> [i \in 1 .. 1 |-> 0] ]

(* Parties Group at zero, then each field in turn at the values it is checked at *)
CheckedPartiesGroup4 ==
    { ZeroPartiesGroup4 }
        \cup { [ZeroPartiesGroup4 EXCEPT !.partyId = one] : one \in Sample(16) }
        \cup { [ZeroPartiesGroup4 EXCEPT !.partyIdSource = one] : one \in Sample(1) }
        \cup { [ZeroPartiesGroup4 EXCEPT !.partyRole = one] : one \in Sample(1) }

(* A run of Parties Group, written one after another *)
RECURSIVE EncodePartiesGroup4List(_)
EncodePartiesGroup4List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodePartiesGroup4(Head(messages)) \o EncodePartiesGroup4List(Tail(messages))

(* As many Parties Group as the field that counts them says *)
RECURSIVE ReadPartiesGroup4List(_, _)
ReadPartiesGroup4List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodePartiesGroup4(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadPartiesGroup4List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Parties Group of each kind, for the lists that carry them *)
OnePartiesGroup4 == { ZeroPartiesGroup4 }

(***************************************************************************)
(* Parties Groups                                                          *)
(***************************************************************************)

PartiesGroups4 ==
    [ blockLengthShort : Sample(1),
      partiesGroup     : SampleLists(OnePartiesGroup4) ]

EncodePartiesGroups4(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.partiesGroup), 1)
        \o EncodePartiesGroup4List(message.partiesGroup)

DecodePartiesGroups4(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET partiesGroup == ReadPartiesGroup4List(numInGroup.rest, numInGroup.value) IN IF ~partiesGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort |-> blockLengthShort.value,
         partiesGroup     |-> partiesGroup.value ], partiesGroup.rest)

ZeroPartiesGroups4 ==
    [ blockLengthShort |-> [i \in 1 .. 1 |-> 0],
      partiesGroup     |-> << >> ]

(* Parties Groups at zero, then each field in turn at the values it is checked at *)
CheckedPartiesGroups4 ==
    { ZeroPartiesGroups4 }
        \cup { [ZeroPartiesGroups4 EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroPartiesGroups4 EXCEPT !.partiesGroup = one] : one \in SampleLists(OnePartiesGroup4) }

(***************************************************************************)
(* One Sided Quotes Group: 14 bytes                                        *)
(***************************************************************************)

OneSidedQuotesGroup ==
    [ listSeqNo  : Sample(1),
      securityId : Sample(8),
      side       : Sample(1),
      quantity   : Sample(2),
      priceShort : Sample(2) ]

EncodeOneSidedQuotesGroup(message) ==
    message.listSeqNo
        \o message.securityId
        \o message.side
        \o message.quantity
        \o message.priceShort

DecodeOneSidedQuotesGroup(bytes) ==
    LET listSeqNo == ReadBytes(bytes, 1) IN IF ~listSeqNo.ok THEN Fail ELSE
    LET securityId == ReadBytes(listSeqNo.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET side == ReadBytes(securityId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET quantity == ReadBytes(side.rest, 2) IN IF ~quantity.ok THEN Fail ELSE
    LET priceShort == ReadBytes(quantity.rest, 2) IN IF ~priceShort.ok THEN Fail ELSE
    Ok([ listSeqNo  |-> listSeqNo.value,
         securityId |-> securityId.value,
         side       |-> side.value,
         quantity   |-> quantity.value,
         priceShort |-> priceShort.value ], priceShort.rest)

ZeroOneSidedQuotesGroup ==
    [ listSeqNo  |-> [i \in 1 .. 1 |-> 0],
      securityId |-> [i \in 1 .. 8 |-> 0],
      side       |-> [i \in 1 .. 1 |-> 0],
      quantity   |-> [i \in 1 .. 2 |-> 0],
      priceShort |-> [i \in 1 .. 2 |-> 0] ]

(* One Sided Quotes Group at zero, then each field in turn at the values it is checked at *)
CheckedOneSidedQuotesGroup ==
    { ZeroOneSidedQuotesGroup }
        \cup { [ZeroOneSidedQuotesGroup EXCEPT !.listSeqNo = one] : one \in Sample(1) }
        \cup { [ZeroOneSidedQuotesGroup EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroOneSidedQuotesGroup EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOneSidedQuotesGroup EXCEPT !.quantity = one] : one \in Sample(2) }
        \cup { [ZeroOneSidedQuotesGroup EXCEPT !.priceShort = one] : one \in Sample(2) }

(* A run of One Sided Quotes Group, written one after another *)
RECURSIVE EncodeOneSidedQuotesGroupList(_)
EncodeOneSidedQuotesGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOneSidedQuotesGroup(Head(messages)) \o EncodeOneSidedQuotesGroupList(Tail(messages))

(* As many One Sided Quotes Group as the field that counts them says *)
RECURSIVE ReadOneSidedQuotesGroupList(_, _)
ReadOneSidedQuotesGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOneSidedQuotesGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOneSidedQuotesGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One One Sided Quotes Group of each kind, for the lists that carry them *)
OneOneSidedQuotesGroup == { ZeroOneSidedQuotesGroup }

(***************************************************************************)
(* One Sided Quotes Groups                                                 *)
(***************************************************************************)

OneSidedQuotesGroups ==
    [ blockLengthShort    : Sample(1),
      oneSidedQuotesGroup : SampleLists(OneOneSidedQuotesGroup) ]

EncodeOneSidedQuotesGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.oneSidedQuotesGroup), 1)
        \o EncodeOneSidedQuotesGroupList(message.oneSidedQuotesGroup)

DecodeOneSidedQuotesGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET oneSidedQuotesGroup == ReadOneSidedQuotesGroupList(numInGroup.rest, numInGroup.value) IN IF ~oneSidedQuotesGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort    |-> blockLengthShort.value,
         oneSidedQuotesGroup |-> oneSidedQuotesGroup.value ], oneSidedQuotesGroup.rest)

ZeroOneSidedQuotesGroups ==
    [ blockLengthShort    |-> [i \in 1 .. 1 |-> 0],
      oneSidedQuotesGroup |-> << >> ]

(* One Sided Quotes Groups at zero, then each field in turn at the values it is checked at *)
CheckedOneSidedQuotesGroups ==
    { ZeroOneSidedQuotesGroups }
        \cup { [ZeroOneSidedQuotesGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroOneSidedQuotesGroups EXCEPT !.oneSidedQuotesGroup = one] : one \in SampleLists(OneOneSidedQuotesGroup) }

(***************************************************************************)
(* Short One Sided Bulk Quote Message                                      *)
(***************************************************************************)

ShortOneSidedBulkQuoteMessage ==
    [ sendingTime          : Sample(8),
      clordid              : Sample(20),
      timeInForce          : Sample(1),
      execInst             : Sample(2),
      tradingCapacity      : Sample(1),
      mtpGroupId           : Sample(2),
      matchTradePrevention : Sample(1),
      cancelGroupId        : Sample(2),
      riskGroupId          : Sample(2),
      partiesGroups        : PartiesGroups4,
      oneSidedQuotesGroups : OneSidedQuotesGroups ]

EncodeShortOneSidedBulkQuoteMessage(message) ==
    message.sendingTime
        \o message.clordid
        \o message.timeInForce
        \o message.execInst
        \o message.tradingCapacity
        \o message.mtpGroupId
        \o message.matchTradePrevention
        \o message.cancelGroupId
        \o message.riskGroupId
        \o EncodePartiesGroups4(message.partiesGroups)
        \o EncodeOneSidedQuotesGroups(message.oneSidedQuotesGroups)

DecodeShortOneSidedBulkQuoteMessage(bytes) ==
    LET sendingTime == ReadBytes(bytes, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET clordid == ReadBytes(sendingTime.rest, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(clordid.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET execInst == ReadBytes(timeInForce.rest, 2) IN IF ~execInst.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(execInst.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET mtpGroupId == ReadBytes(tradingCapacity.rest, 2) IN IF ~mtpGroupId.ok THEN Fail ELSE
    LET matchTradePrevention == ReadBytes(mtpGroupId.rest, 1) IN IF ~matchTradePrevention.ok THEN Fail ELSE
    LET cancelGroupId == ReadBytes(matchTradePrevention.rest, 2) IN IF ~cancelGroupId.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(cancelGroupId.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET partiesGroups == DecodePartiesGroups4(riskGroupId.rest) IN IF ~partiesGroups.ok THEN Fail ELSE
    LET oneSidedQuotesGroups == DecodeOneSidedQuotesGroups(partiesGroups.rest) IN IF ~oneSidedQuotesGroups.ok THEN Fail ELSE
    Ok([ sendingTime          |-> sendingTime.value,
         clordid              |-> clordid.value,
         timeInForce          |-> timeInForce.value,
         execInst             |-> execInst.value,
         tradingCapacity      |-> tradingCapacity.value,
         mtpGroupId           |-> mtpGroupId.value,
         matchTradePrevention |-> matchTradePrevention.value,
         cancelGroupId        |-> cancelGroupId.value,
         riskGroupId          |-> riskGroupId.value,
         partiesGroups        |-> partiesGroups.value,
         oneSidedQuotesGroups |-> oneSidedQuotesGroups.value ], oneSidedQuotesGroups.rest)

ZeroShortOneSidedBulkQuoteMessage ==
    [ sendingTime          |-> [i \in 1 .. 8 |-> 0],
      clordid              |-> [i \in 1 .. 20 |-> 0],
      timeInForce          |-> [i \in 1 .. 1 |-> 0],
      execInst             |-> [i \in 1 .. 2 |-> 0],
      tradingCapacity      |-> [i \in 1 .. 1 |-> 0],
      mtpGroupId           |-> [i \in 1 .. 2 |-> 0],
      matchTradePrevention |-> [i \in 1 .. 1 |-> 0],
      cancelGroupId        |-> [i \in 1 .. 2 |-> 0],
      riskGroupId          |-> [i \in 1 .. 2 |-> 0],
      partiesGroups        |-> ZeroPartiesGroups4,
      oneSidedQuotesGroups |-> ZeroOneSidedQuotesGroups ]

(* Short One Sided Bulk Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedShortOneSidedBulkQuoteMessage ==
    { ZeroShortOneSidedBulkQuoteMessage }
        \cup { [ZeroShortOneSidedBulkQuoteMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroShortOneSidedBulkQuoteMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroShortOneSidedBulkQuoteMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroShortOneSidedBulkQuoteMessage EXCEPT !.execInst = one] : one \in Sample(2) }
        \cup { [ZeroShortOneSidedBulkQuoteMessage EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroShortOneSidedBulkQuoteMessage EXCEPT !.mtpGroupId = one] : one \in Sample(2) }
        \cup { [ZeroShortOneSidedBulkQuoteMessage EXCEPT !.matchTradePrevention = one] : one \in Sample(1) }
        \cup { [ZeroShortOneSidedBulkQuoteMessage EXCEPT !.cancelGroupId = one] : one \in Sample(2) }
        \cup { [ZeroShortOneSidedBulkQuoteMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroShortOneSidedBulkQuoteMessage EXCEPT !.partiesGroups = one] : one \in CheckedPartiesGroups4 }
        \cup { [ZeroShortOneSidedBulkQuoteMessage EXCEPT !.oneSidedQuotesGroups = one] : one \in CheckedOneSidedQuotesGroups }

(***************************************************************************)
(* Parties Group: 18 bytes                                                 *)
(***************************************************************************)

PartiesGroup5 ==
    [ partyId       : Sample(16),
      partyIdSource : Sample(1),
      partyRole     : Sample(1) ]

EncodePartiesGroup5(message) ==
    message.partyId
        \o message.partyIdSource
        \o message.partyRole

DecodePartiesGroup5(bytes) ==
    LET partyId == ReadBytes(bytes, 16) IN IF ~partyId.ok THEN Fail ELSE
    LET partyIdSource == ReadBytes(partyId.rest, 1) IN IF ~partyIdSource.ok THEN Fail ELSE
    LET partyRole == ReadBytes(partyIdSource.rest, 1) IN IF ~partyRole.ok THEN Fail ELSE
    Ok([ partyId       |-> partyId.value,
         partyIdSource |-> partyIdSource.value,
         partyRole     |-> partyRole.value ], partyRole.rest)

ZeroPartiesGroup5 ==
    [ partyId       |-> [i \in 1 .. 16 |-> 0],
      partyIdSource |-> [i \in 1 .. 1 |-> 0],
      partyRole     |-> [i \in 1 .. 1 |-> 0] ]

(* Parties Group at zero, then each field in turn at the values it is checked at *)
CheckedPartiesGroup5 ==
    { ZeroPartiesGroup5 }
        \cup { [ZeroPartiesGroup5 EXCEPT !.partyId = one] : one \in Sample(16) }
        \cup { [ZeroPartiesGroup5 EXCEPT !.partyIdSource = one] : one \in Sample(1) }
        \cup { [ZeroPartiesGroup5 EXCEPT !.partyRole = one] : one \in Sample(1) }

(* A run of Parties Group, written one after another *)
RECURSIVE EncodePartiesGroup5List(_)
EncodePartiesGroup5List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodePartiesGroup5(Head(messages)) \o EncodePartiesGroup5List(Tail(messages))

(* As many Parties Group as the field that counts them says *)
RECURSIVE ReadPartiesGroup5List(_, _)
ReadPartiesGroup5List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodePartiesGroup5(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadPartiesGroup5List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Parties Group of each kind, for the lists that carry them *)
OnePartiesGroup5 == { ZeroPartiesGroup5 }

(***************************************************************************)
(* Parties Groups                                                          *)
(***************************************************************************)

PartiesGroups5 ==
    [ blockLengthShort : Sample(1),
      partiesGroup     : SampleLists(OnePartiesGroup5) ]

EncodePartiesGroups5(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.partiesGroup), 1)
        \o EncodePartiesGroup5List(message.partiesGroup)

DecodePartiesGroups5(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET partiesGroup == ReadPartiesGroup5List(numInGroup.rest, numInGroup.value) IN IF ~partiesGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort |-> blockLengthShort.value,
         partiesGroup     |-> partiesGroup.value ], partiesGroup.rest)

ZeroPartiesGroups5 ==
    [ blockLengthShort |-> [i \in 1 .. 1 |-> 0],
      partiesGroup     |-> << >> ]

(* Parties Groups at zero, then each field in turn at the values it is checked at *)
CheckedPartiesGroups5 ==
    { ZeroPartiesGroups5 }
        \cup { [ZeroPartiesGroups5 EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroPartiesGroups5 EXCEPT !.partiesGroup = one] : one \in SampleLists(OnePartiesGroup5) }

(***************************************************************************)
(* One Sided Quotes Group: 14 bytes                                        *)
(***************************************************************************)

OneSidedQuotesGroup2 ==
    [ listSeqNo  : Sample(1),
      securityId : Sample(8),
      side       : Sample(1),
      quantity   : Sample(2),
      priceShort : Sample(2) ]

EncodeOneSidedQuotesGroup2(message) ==
    message.listSeqNo
        \o message.securityId
        \o message.side
        \o message.quantity
        \o message.priceShort

DecodeOneSidedQuotesGroup2(bytes) ==
    LET listSeqNo == ReadBytes(bytes, 1) IN IF ~listSeqNo.ok THEN Fail ELSE
    LET securityId == ReadBytes(listSeqNo.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET side == ReadBytes(securityId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET quantity == ReadBytes(side.rest, 2) IN IF ~quantity.ok THEN Fail ELSE
    LET priceShort == ReadBytes(quantity.rest, 2) IN IF ~priceShort.ok THEN Fail ELSE
    Ok([ listSeqNo  |-> listSeqNo.value,
         securityId |-> securityId.value,
         side       |-> side.value,
         quantity   |-> quantity.value,
         priceShort |-> priceShort.value ], priceShort.rest)

ZeroOneSidedQuotesGroup2 ==
    [ listSeqNo  |-> [i \in 1 .. 1 |-> 0],
      securityId |-> [i \in 1 .. 8 |-> 0],
      side       |-> [i \in 1 .. 1 |-> 0],
      quantity   |-> [i \in 1 .. 2 |-> 0],
      priceShort |-> [i \in 1 .. 2 |-> 0] ]

(* One Sided Quotes Group at zero, then each field in turn at the values it is checked at *)
CheckedOneSidedQuotesGroup2 ==
    { ZeroOneSidedQuotesGroup2 }
        \cup { [ZeroOneSidedQuotesGroup2 EXCEPT !.listSeqNo = one] : one \in Sample(1) }
        \cup { [ZeroOneSidedQuotesGroup2 EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroOneSidedQuotesGroup2 EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOneSidedQuotesGroup2 EXCEPT !.quantity = one] : one \in Sample(2) }
        \cup { [ZeroOneSidedQuotesGroup2 EXCEPT !.priceShort = one] : one \in Sample(2) }

(* A run of One Sided Quotes Group, written one after another *)
RECURSIVE EncodeOneSidedQuotesGroup2List(_)
EncodeOneSidedQuotesGroup2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOneSidedQuotesGroup2(Head(messages)) \o EncodeOneSidedQuotesGroup2List(Tail(messages))

(* As many One Sided Quotes Group as the field that counts them says *)
RECURSIVE ReadOneSidedQuotesGroup2List(_, _)
ReadOneSidedQuotesGroup2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOneSidedQuotesGroup2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOneSidedQuotesGroup2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One One Sided Quotes Group of each kind, for the lists that carry them *)
OneOneSidedQuotesGroup2 == { ZeroOneSidedQuotesGroup2 }

(***************************************************************************)
(* One Sided Quotes Groups                                                 *)
(***************************************************************************)

OneSidedQuotesGroups2 ==
    [ blockLengthShort    : Sample(1),
      oneSidedQuotesGroup : SampleLists(OneOneSidedQuotesGroup2) ]

EncodeOneSidedQuotesGroups2(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.oneSidedQuotesGroup), 1)
        \o EncodeOneSidedQuotesGroup2List(message.oneSidedQuotesGroup)

DecodeOneSidedQuotesGroups2(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET oneSidedQuotesGroup == ReadOneSidedQuotesGroup2List(numInGroup.rest, numInGroup.value) IN IF ~oneSidedQuotesGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort    |-> blockLengthShort.value,
         oneSidedQuotesGroup |-> oneSidedQuotesGroup.value ], oneSidedQuotesGroup.rest)

ZeroOneSidedQuotesGroups2 ==
    [ blockLengthShort    |-> [i \in 1 .. 1 |-> 0],
      oneSidedQuotesGroup |-> << >> ]

(* One Sided Quotes Groups at zero, then each field in turn at the values it is checked at *)
CheckedOneSidedQuotesGroups2 ==
    { ZeroOneSidedQuotesGroups2 }
        \cup { [ZeroOneSidedQuotesGroups2 EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroOneSidedQuotesGroups2 EXCEPT !.oneSidedQuotesGroup = one] : one \in SampleLists(OneOneSidedQuotesGroup2) }

(***************************************************************************)
(* Long One Sided Bulk Quote Message                                       *)
(***************************************************************************)

LongOneSidedBulkQuoteMessage ==
    [ sendingTime          : Sample(8),
      clordid              : Sample(20),
      timeInForce          : Sample(1),
      execInst             : Sample(2),
      tradingCapacity      : Sample(1),
      mtpGroupId           : Sample(2),
      matchTradePrevention : Sample(1),
      cancelGroupId        : Sample(2),
      riskGroupId          : Sample(2),
      partiesGroups        : PartiesGroups5,
      oneSidedQuotesGroups : OneSidedQuotesGroups2 ]

EncodeLongOneSidedBulkQuoteMessage(message) ==
    message.sendingTime
        \o message.clordid
        \o message.timeInForce
        \o message.execInst
        \o message.tradingCapacity
        \o message.mtpGroupId
        \o message.matchTradePrevention
        \o message.cancelGroupId
        \o message.riskGroupId
        \o EncodePartiesGroups5(message.partiesGroups)
        \o EncodeOneSidedQuotesGroups2(message.oneSidedQuotesGroups)

DecodeLongOneSidedBulkQuoteMessage(bytes) ==
    LET sendingTime == ReadBytes(bytes, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET clordid == ReadBytes(sendingTime.rest, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(clordid.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET execInst == ReadBytes(timeInForce.rest, 2) IN IF ~execInst.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(execInst.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET mtpGroupId == ReadBytes(tradingCapacity.rest, 2) IN IF ~mtpGroupId.ok THEN Fail ELSE
    LET matchTradePrevention == ReadBytes(mtpGroupId.rest, 1) IN IF ~matchTradePrevention.ok THEN Fail ELSE
    LET cancelGroupId == ReadBytes(matchTradePrevention.rest, 2) IN IF ~cancelGroupId.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(cancelGroupId.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET partiesGroups == DecodePartiesGroups5(riskGroupId.rest) IN IF ~partiesGroups.ok THEN Fail ELSE
    LET oneSidedQuotesGroups == DecodeOneSidedQuotesGroups2(partiesGroups.rest) IN IF ~oneSidedQuotesGroups.ok THEN Fail ELSE
    Ok([ sendingTime          |-> sendingTime.value,
         clordid              |-> clordid.value,
         timeInForce          |-> timeInForce.value,
         execInst             |-> execInst.value,
         tradingCapacity      |-> tradingCapacity.value,
         mtpGroupId           |-> mtpGroupId.value,
         matchTradePrevention |-> matchTradePrevention.value,
         cancelGroupId        |-> cancelGroupId.value,
         riskGroupId          |-> riskGroupId.value,
         partiesGroups        |-> partiesGroups.value,
         oneSidedQuotesGroups |-> oneSidedQuotesGroups.value ], oneSidedQuotesGroups.rest)

ZeroLongOneSidedBulkQuoteMessage ==
    [ sendingTime          |-> [i \in 1 .. 8 |-> 0],
      clordid              |-> [i \in 1 .. 20 |-> 0],
      timeInForce          |-> [i \in 1 .. 1 |-> 0],
      execInst             |-> [i \in 1 .. 2 |-> 0],
      tradingCapacity      |-> [i \in 1 .. 1 |-> 0],
      mtpGroupId           |-> [i \in 1 .. 2 |-> 0],
      matchTradePrevention |-> [i \in 1 .. 1 |-> 0],
      cancelGroupId        |-> [i \in 1 .. 2 |-> 0],
      riskGroupId          |-> [i \in 1 .. 2 |-> 0],
      partiesGroups        |-> ZeroPartiesGroups5,
      oneSidedQuotesGroups |-> ZeroOneSidedQuotesGroups2 ]

(* Long One Sided Bulk Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedLongOneSidedBulkQuoteMessage ==
    { ZeroLongOneSidedBulkQuoteMessage }
        \cup { [ZeroLongOneSidedBulkQuoteMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroLongOneSidedBulkQuoteMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroLongOneSidedBulkQuoteMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroLongOneSidedBulkQuoteMessage EXCEPT !.execInst = one] : one \in Sample(2) }
        \cup { [ZeroLongOneSidedBulkQuoteMessage EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroLongOneSidedBulkQuoteMessage EXCEPT !.mtpGroupId = one] : one \in Sample(2) }
        \cup { [ZeroLongOneSidedBulkQuoteMessage EXCEPT !.matchTradePrevention = one] : one \in Sample(1) }
        \cup { [ZeroLongOneSidedBulkQuoteMessage EXCEPT !.cancelGroupId = one] : one \in Sample(2) }
        \cup { [ZeroLongOneSidedBulkQuoteMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroLongOneSidedBulkQuoteMessage EXCEPT !.partiesGroups = one] : one \in CheckedPartiesGroups5 }
        \cup { [ZeroLongOneSidedBulkQuoteMessage EXCEPT !.oneSidedQuotesGroups = one] : one \in CheckedOneSidedQuotesGroups2 }

(***************************************************************************)
(* Order Cancel Replace Request Message: 79 bytes                          *)
(***************************************************************************)

OrderCancelReplaceRequestMessage ==
    [ sendingTime     : Sample(8),
      orderIdOptional : Sample(8),
      clordid         : Sample(20),
      listSeqNo       : Sample(1),
      origclordid     : Sample(20),
      securityId      : Sample(8),
      side            : Sample(1),
      orderQty        : Sample(4),
      ordType         : Sample(1),
      priceOptional   : Sample(8) ]

EncodeOrderCancelReplaceRequestMessage(message) ==
    message.sendingTime
        \o message.orderIdOptional
        \o message.clordid
        \o message.listSeqNo
        \o message.origclordid
        \o message.securityId
        \o message.side
        \o message.orderQty
        \o message.ordType
        \o message.priceOptional

DecodeOrderCancelReplaceRequestMessage(bytes) ==
    LET sendingTime == ReadBytes(bytes, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET orderIdOptional == ReadBytes(sendingTime.rest, 8) IN IF ~orderIdOptional.ok THEN Fail ELSE
    LET clordid == ReadBytes(orderIdOptional.rest, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET listSeqNo == ReadBytes(clordid.rest, 1) IN IF ~listSeqNo.ok THEN Fail ELSE
    LET origclordid == ReadBytes(listSeqNo.rest, 20) IN IF ~origclordid.ok THEN Fail ELSE
    LET securityId == ReadBytes(origclordid.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET side == ReadBytes(securityId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderQty == ReadBytes(side.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET ordType == ReadBytes(orderQty.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET priceOptional == ReadBytes(ordType.rest, 8) IN IF ~priceOptional.ok THEN Fail ELSE
    Ok([ sendingTime     |-> sendingTime.value,
         orderIdOptional |-> orderIdOptional.value,
         clordid         |-> clordid.value,
         listSeqNo       |-> listSeqNo.value,
         origclordid     |-> origclordid.value,
         securityId      |-> securityId.value,
         side            |-> side.value,
         orderQty        |-> orderQty.value,
         ordType         |-> ordType.value,
         priceOptional   |-> priceOptional.value ], priceOptional.rest)

ZeroOrderCancelReplaceRequestMessage ==
    [ sendingTime     |-> [i \in 1 .. 8 |-> 0],
      orderIdOptional |-> [i \in 1 .. 8 |-> 0],
      clordid         |-> [i \in 1 .. 20 |-> 0],
      listSeqNo       |-> [i \in 1 .. 1 |-> 0],
      origclordid     |-> [i \in 1 .. 20 |-> 0],
      securityId      |-> [i \in 1 .. 8 |-> 0],
      side            |-> [i \in 1 .. 1 |-> 0],
      orderQty        |-> [i \in 1 .. 4 |-> 0],
      ordType         |-> [i \in 1 .. 1 |-> 0],
      priceOptional   |-> [i \in 1 .. 8 |-> 0] ]

(* Order Cancel Replace Request Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelReplaceRequestMessage ==
    { ZeroOrderCancelReplaceRequestMessage }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.orderIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.listSeqNo = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.origclordid = one] : one \in Sample(20) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.priceOptional = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Cancel Request Message: 66 bytes                                  *)
(***************************************************************************)

OrderCancelRequestMessage ==
    [ sendingTime         : Sample(8),
      orderIdOptional     : Sample(8),
      clordid             : Sample(20),
      listSeqNo           : Sample(1),
      origclordidOptional : Sample(20),
      securityId          : Sample(8),
      sideOptional        : Sample(1) ]

EncodeOrderCancelRequestMessage(message) ==
    message.sendingTime
        \o message.orderIdOptional
        \o message.clordid
        \o message.listSeqNo
        \o message.origclordidOptional
        \o message.securityId
        \o message.sideOptional

DecodeOrderCancelRequestMessage(bytes) ==
    LET sendingTime == ReadBytes(bytes, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET orderIdOptional == ReadBytes(sendingTime.rest, 8) IN IF ~orderIdOptional.ok THEN Fail ELSE
    LET clordid == ReadBytes(orderIdOptional.rest, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET listSeqNo == ReadBytes(clordid.rest, 1) IN IF ~listSeqNo.ok THEN Fail ELSE
    LET origclordidOptional == ReadBytes(listSeqNo.rest, 20) IN IF ~origclordidOptional.ok THEN Fail ELSE
    LET securityId == ReadBytes(origclordidOptional.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET sideOptional == ReadBytes(securityId.rest, 1) IN IF ~sideOptional.ok THEN Fail ELSE
    Ok([ sendingTime         |-> sendingTime.value,
         orderIdOptional     |-> orderIdOptional.value,
         clordid             |-> clordid.value,
         listSeqNo           |-> listSeqNo.value,
         origclordidOptional |-> origclordidOptional.value,
         securityId          |-> securityId.value,
         sideOptional        |-> sideOptional.value ], sideOptional.rest)

ZeroOrderCancelRequestMessage ==
    [ sendingTime         |-> [i \in 1 .. 8 |-> 0],
      orderIdOptional     |-> [i \in 1 .. 8 |-> 0],
      clordid             |-> [i \in 1 .. 20 |-> 0],
      listSeqNo           |-> [i \in 1 .. 1 |-> 0],
      origclordidOptional |-> [i \in 1 .. 20 |-> 0],
      securityId          |-> [i \in 1 .. 8 |-> 0],
      sideOptional        |-> [i \in 1 .. 1 |-> 0] ]

(* Order Cancel Request Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelRequestMessage ==
    { ZeroOrderCancelRequestMessage }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.orderIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.listSeqNo = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.origclordidOptional = one] : one \in Sample(20) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.sideOptional = one] : one \in Sample(1) }

(***************************************************************************)
(* Mass Cancel Request Message: 50 bytes                                   *)
(***************************************************************************)

MassCancelRequestMessage ==
    [ sendingTime               : Sample(8),
      clordid                   : Sample(20),
      efidOptional              : Sample(4),
      underlyingOrSeries        : Sample(1),
      underlierOptional         : Sample(6),
      optionsSecurityIdOptional : Sample(8),
      cancelGroupId             : Sample(2),
      massCancelInst            : Sample(1) ]

EncodeMassCancelRequestMessage(message) ==
    message.sendingTime
        \o message.clordid
        \o message.efidOptional
        \o message.underlyingOrSeries
        \o message.underlierOptional
        \o message.optionsSecurityIdOptional
        \o message.cancelGroupId
        \o message.massCancelInst

DecodeMassCancelRequestMessage(bytes) ==
    LET sendingTime == ReadBytes(bytes, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET clordid == ReadBytes(sendingTime.rest, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET efidOptional == ReadBytes(clordid.rest, 4) IN IF ~efidOptional.ok THEN Fail ELSE
    LET underlyingOrSeries == ReadBytes(efidOptional.rest, 1) IN IF ~underlyingOrSeries.ok THEN Fail ELSE
    LET underlierOptional == ReadBytes(underlyingOrSeries.rest, 6) IN IF ~underlierOptional.ok THEN Fail ELSE
    LET optionsSecurityIdOptional == ReadBytes(underlierOptional.rest, 8) IN IF ~optionsSecurityIdOptional.ok THEN Fail ELSE
    LET cancelGroupId == ReadBytes(optionsSecurityIdOptional.rest, 2) IN IF ~cancelGroupId.ok THEN Fail ELSE
    LET massCancelInst == ReadBytes(cancelGroupId.rest, 1) IN IF ~massCancelInst.ok THEN Fail ELSE
    Ok([ sendingTime               |-> sendingTime.value,
         clordid                   |-> clordid.value,
         efidOptional              |-> efidOptional.value,
         underlyingOrSeries        |-> underlyingOrSeries.value,
         underlierOptional         |-> underlierOptional.value,
         optionsSecurityIdOptional |-> optionsSecurityIdOptional.value,
         cancelGroupId             |-> cancelGroupId.value,
         massCancelInst            |-> massCancelInst.value ], massCancelInst.rest)

ZeroMassCancelRequestMessage ==
    [ sendingTime               |-> [i \in 1 .. 8 |-> 0],
      clordid                   |-> [i \in 1 .. 20 |-> 0],
      efidOptional              |-> [i \in 1 .. 4 |-> 0],
      underlyingOrSeries        |-> [i \in 1 .. 1 |-> 0],
      underlierOptional         |-> [i \in 1 .. 6 |-> 0],
      optionsSecurityIdOptional |-> [i \in 1 .. 8 |-> 0],
      cancelGroupId             |-> [i \in 1 .. 2 |-> 0],
      massCancelInst            |-> [i \in 1 .. 1 |-> 0] ]

(* Mass Cancel Request Message at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelRequestMessage ==
    { ZeroMassCancelRequestMessage }
        \cup { [ZeroMassCancelRequestMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelRequestMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroMassCancelRequestMessage EXCEPT !.efidOptional = one] : one \in Sample(4) }
        \cup { [ZeroMassCancelRequestMessage EXCEPT !.underlyingOrSeries = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelRequestMessage EXCEPT !.underlierOptional = one] : one \in Sample(6) }
        \cup { [ZeroMassCancelRequestMessage EXCEPT !.optionsSecurityIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelRequestMessage EXCEPT !.cancelGroupId = one] : one \in Sample(2) }
        \cup { [ZeroMassCancelRequestMessage EXCEPT !.massCancelInst = one] : one \in Sample(1) }

(***************************************************************************)
(* Mass Cancel Clear Lockout Request Message: 36 bytes                     *)
(***************************************************************************)

MassCancelClearLockoutRequestMessage ==
    [ sendingTime : Sample(8),
      clordid     : Sample(20),
      lockoutId   : Sample(8) ]

EncodeMassCancelClearLockoutRequestMessage(message) ==
    message.sendingTime
        \o message.clordid
        \o message.lockoutId

DecodeMassCancelClearLockoutRequestMessage(bytes) ==
    LET sendingTime == ReadBytes(bytes, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET clordid == ReadBytes(sendingTime.rest, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET lockoutId == ReadBytes(clordid.rest, 8) IN IF ~lockoutId.ok THEN Fail ELSE
    Ok([ sendingTime |-> sendingTime.value,
         clordid     |-> clordid.value,
         lockoutId   |-> lockoutId.value ], lockoutId.rest)

ZeroMassCancelClearLockoutRequestMessage ==
    [ sendingTime |-> [i \in 1 .. 8 |-> 0],
      clordid     |-> [i \in 1 .. 20 |-> 0],
      lockoutId   |-> [i \in 1 .. 8 |-> 0] ]

(* Mass Cancel Clear Lockout Request Message at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelClearLockoutRequestMessage ==
    { ZeroMassCancelClearLockoutRequestMessage }
        \cup { [ZeroMassCancelClearLockoutRequestMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelClearLockoutRequestMessage EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroMassCancelClearLockoutRequestMessage EXCEPT !.lockoutId = one] : one \in Sample(8) }

(***************************************************************************)
(* Execution Allocations Group: 20 bytes                                   *)
(***************************************************************************)

ExecutionAllocationsGroup ==
    [ tradeId : Sample(8),
      lastQty : Sample(4),
      lastPx  : Sample(8) ]

EncodeExecutionAllocationsGroup(message) ==
    message.tradeId
        \o message.lastQty
        \o message.lastPx

DecodeExecutionAllocationsGroup(bytes) ==
    LET tradeId == ReadBytes(bytes, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET lastQty == ReadBytes(tradeId.rest, 4) IN IF ~lastQty.ok THEN Fail ELSE
    LET lastPx == ReadBytes(lastQty.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    Ok([ tradeId |-> tradeId.value,
         lastQty |-> lastQty.value,
         lastPx  |-> lastPx.value ], lastPx.rest)

ZeroExecutionAllocationsGroup ==
    [ tradeId |-> [i \in 1 .. 8 |-> 0],
      lastQty |-> [i \in 1 .. 4 |-> 0],
      lastPx  |-> [i \in 1 .. 8 |-> 0] ]

(* Execution Allocations Group at zero, then each field in turn at the values it is checked at *)
CheckedExecutionAllocationsGroup ==
    { ZeroExecutionAllocationsGroup }
        \cup { [ZeroExecutionAllocationsGroup EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionAllocationsGroup EXCEPT !.lastQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionAllocationsGroup EXCEPT !.lastPx = one] : one \in Sample(8) }

(* A run of Execution Allocations Group, written one after another *)
RECURSIVE EncodeExecutionAllocationsGroupList(_)
EncodeExecutionAllocationsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeExecutionAllocationsGroup(Head(messages)) \o EncodeExecutionAllocationsGroupList(Tail(messages))

(* As many Execution Allocations Group as the field that counts them says *)
RECURSIVE ReadExecutionAllocationsGroupList(_, _)
ReadExecutionAllocationsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeExecutionAllocationsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadExecutionAllocationsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Execution Allocations Group of each kind, for the lists that carry them *)
OneExecutionAllocationsGroup == { ZeroExecutionAllocationsGroup }

(***************************************************************************)
(* Execution Allocations Groups                                            *)
(***************************************************************************)

ExecutionAllocationsGroups ==
    [ blockLengthShort          : Sample(1),
      executionAllocationsGroup : SampleLists(OneExecutionAllocationsGroup) ]

EncodeExecutionAllocationsGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.executionAllocationsGroup), 1)
        \o EncodeExecutionAllocationsGroupList(message.executionAllocationsGroup)

DecodeExecutionAllocationsGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET executionAllocationsGroup == ReadExecutionAllocationsGroupList(numInGroup.rest, numInGroup.value) IN IF ~executionAllocationsGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort          |-> blockLengthShort.value,
         executionAllocationsGroup |-> executionAllocationsGroup.value ], executionAllocationsGroup.rest)

ZeroExecutionAllocationsGroups ==
    [ blockLengthShort          |-> [i \in 1 .. 1 |-> 0],
      executionAllocationsGroup |-> << >> ]

(* Execution Allocations Groups at zero, then each field in turn at the values it is checked at *)
CheckedExecutionAllocationsGroups ==
    { ZeroExecutionAllocationsGroups }
        \cup { [ZeroExecutionAllocationsGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroExecutionAllocationsGroups EXCEPT !.executionAllocationsGroup = one] : one \in SampleLists(OneExecutionAllocationsGroup) }

(***************************************************************************)
(* Nested Parties Group: 18 bytes                                          *)
(***************************************************************************)

NestedPartiesGroup ==
    [ nestedPartyId       : Sample(16),
      nestedPartyIdSource : Sample(1),
      nestedPartyRole     : Sample(1) ]

EncodeNestedPartiesGroup(message) ==
    message.nestedPartyId
        \o message.nestedPartyIdSource
        \o message.nestedPartyRole

DecodeNestedPartiesGroup(bytes) ==
    LET nestedPartyId == ReadBytes(bytes, 16) IN IF ~nestedPartyId.ok THEN Fail ELSE
    LET nestedPartyIdSource == ReadBytes(nestedPartyId.rest, 1) IN IF ~nestedPartyIdSource.ok THEN Fail ELSE
    LET nestedPartyRole == ReadBytes(nestedPartyIdSource.rest, 1) IN IF ~nestedPartyRole.ok THEN Fail ELSE
    Ok([ nestedPartyId       |-> nestedPartyId.value,
         nestedPartyIdSource |-> nestedPartyIdSource.value,
         nestedPartyRole     |-> nestedPartyRole.value ], nestedPartyRole.rest)

ZeroNestedPartiesGroup ==
    [ nestedPartyId       |-> [i \in 1 .. 16 |-> 0],
      nestedPartyIdSource |-> [i \in 1 .. 1 |-> 0],
      nestedPartyRole     |-> [i \in 1 .. 1 |-> 0] ]

(* Nested Parties Group at zero, then each field in turn at the values it is checked at *)
CheckedNestedPartiesGroup ==
    { ZeroNestedPartiesGroup }
        \cup { [ZeroNestedPartiesGroup EXCEPT !.nestedPartyId = one] : one \in Sample(16) }
        \cup { [ZeroNestedPartiesGroup EXCEPT !.nestedPartyIdSource = one] : one \in Sample(1) }
        \cup { [ZeroNestedPartiesGroup EXCEPT !.nestedPartyRole = one] : one \in Sample(1) }

(* A run of Nested Parties Group, written one after another *)
RECURSIVE EncodeNestedPartiesGroupList(_)
EncodeNestedPartiesGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeNestedPartiesGroup(Head(messages)) \o EncodeNestedPartiesGroupList(Tail(messages))

(* As many Nested Parties Group as the field that counts them says *)
RECURSIVE ReadNestedPartiesGroupList(_, _)
ReadNestedPartiesGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeNestedPartiesGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadNestedPartiesGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Nested Parties Group of each kind, for the lists that carry them *)
OneNestedPartiesGroup == { ZeroNestedPartiesGroup }

(***************************************************************************)
(* Nested Parties Groups                                                   *)
(***************************************************************************)

NestedPartiesGroups ==
    [ blockLengthShort   : Sample(1),
      nestedPartiesGroup : SampleLists(OneNestedPartiesGroup) ]

EncodeNestedPartiesGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.nestedPartiesGroup), 1)
        \o EncodeNestedPartiesGroupList(message.nestedPartiesGroup)

DecodeNestedPartiesGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET nestedPartiesGroup == ReadNestedPartiesGroupList(numInGroup.rest, numInGroup.value) IN IF ~nestedPartiesGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort   |-> blockLengthShort.value,
         nestedPartiesGroup |-> nestedPartiesGroup.value ], nestedPartiesGroup.rest)

ZeroNestedPartiesGroups ==
    [ blockLengthShort   |-> [i \in 1 .. 1 |-> 0],
      nestedPartiesGroup |-> << >> ]

(* Nested Parties Groups at zero, then each field in turn at the values it is checked at *)
CheckedNestedPartiesGroups ==
    { ZeroNestedPartiesGroups }
        \cup { [ZeroNestedPartiesGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroNestedPartiesGroups EXCEPT !.nestedPartiesGroup = one] : one \in SampleLists(OneNestedPartiesGroup) }

(***************************************************************************)
(* Requested Allocations Group                                             *)
(***************************************************************************)

RequestedAllocationsGroup ==
    [ allocQty            : Sample(4),
      allocPositionEffect : Sample(1),
      nestedPartiesGroups : NestedPartiesGroups ]

EncodeRequestedAllocationsGroup(message) ==
    message.allocQty
        \o message.allocPositionEffect
        \o EncodeNestedPartiesGroups(message.nestedPartiesGroups)

DecodeRequestedAllocationsGroup(bytes) ==
    LET allocQty == ReadBytes(bytes, 4) IN IF ~allocQty.ok THEN Fail ELSE
    LET allocPositionEffect == ReadBytes(allocQty.rest, 1) IN IF ~allocPositionEffect.ok THEN Fail ELSE
    LET nestedPartiesGroups == DecodeNestedPartiesGroups(allocPositionEffect.rest) IN IF ~nestedPartiesGroups.ok THEN Fail ELSE
    Ok([ allocQty            |-> allocQty.value,
         allocPositionEffect |-> allocPositionEffect.value,
         nestedPartiesGroups |-> nestedPartiesGroups.value ], nestedPartiesGroups.rest)

ZeroRequestedAllocationsGroup ==
    [ allocQty            |-> [i \in 1 .. 4 |-> 0],
      allocPositionEffect |-> [i \in 1 .. 1 |-> 0],
      nestedPartiesGroups |-> ZeroNestedPartiesGroups ]

(* Requested Allocations Group at zero, then each field in turn at the values it is checked at *)
CheckedRequestedAllocationsGroup ==
    { ZeroRequestedAllocationsGroup }
        \cup { [ZeroRequestedAllocationsGroup EXCEPT !.allocQty = one] : one \in Sample(4) }
        \cup { [ZeroRequestedAllocationsGroup EXCEPT !.allocPositionEffect = one] : one \in Sample(1) }
        \cup { [ZeroRequestedAllocationsGroup EXCEPT !.nestedPartiesGroups = one] : one \in CheckedNestedPartiesGroups }

(* A run of Requested Allocations Group, written one after another *)
RECURSIVE EncodeRequestedAllocationsGroupList(_)
EncodeRequestedAllocationsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeRequestedAllocationsGroup(Head(messages)) \o EncodeRequestedAllocationsGroupList(Tail(messages))

(* As many Requested Allocations Group as the field that counts them says *)
RECURSIVE ReadRequestedAllocationsGroupList(_, _)
ReadRequestedAllocationsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeRequestedAllocationsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadRequestedAllocationsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Requested Allocations Group of each kind, for the lists that carry them *)
OneRequestedAllocationsGroup == { ZeroRequestedAllocationsGroup }

(***************************************************************************)
(* Requested Allocations Groups                                            *)
(***************************************************************************)

RequestedAllocationsGroups ==
    [ blockLengthShort          : Sample(1),
      requestedAllocationsGroup : SampleLists(OneRequestedAllocationsGroup) ]

EncodeRequestedAllocationsGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.requestedAllocationsGroup), 1)
        \o EncodeRequestedAllocationsGroupList(message.requestedAllocationsGroup)

DecodeRequestedAllocationsGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET requestedAllocationsGroup == ReadRequestedAllocationsGroupList(numInGroup.rest, numInGroup.value) IN IF ~requestedAllocationsGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort          |-> blockLengthShort.value,
         requestedAllocationsGroup |-> requestedAllocationsGroup.value ], requestedAllocationsGroup.rest)

ZeroRequestedAllocationsGroups ==
    [ blockLengthShort          |-> [i \in 1 .. 1 |-> 0],
      requestedAllocationsGroup |-> << >> ]

(* Requested Allocations Groups at zero, then each field in turn at the values it is checked at *)
CheckedRequestedAllocationsGroups ==
    { ZeroRequestedAllocationsGroups }
        \cup { [ZeroRequestedAllocationsGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroRequestedAllocationsGroups EXCEPT !.requestedAllocationsGroup = one] : one \in SampleLists(OneRequestedAllocationsGroup) }

(***************************************************************************)
(* Allocation Instruction Message                                          *)
(***************************************************************************)

AllocationInstructionMessage ==
    [ sendingTime                : Sample(8),
      allocId                    : Sample(20),
      allocType                  : Sample(1),
      allocTransType             : Sample(1),
      refAllocIdOptional         : Sample(20),
      securityId                 : Sample(8),
      side                       : Sample(1),
      executionAllocationsGroups : ExecutionAllocationsGroups,
      requestedAllocationsGroups : RequestedAllocationsGroups ]

EncodeAllocationInstructionMessage(message) ==
    message.sendingTime
        \o message.allocId
        \o message.allocType
        \o message.allocTransType
        \o message.refAllocIdOptional
        \o message.securityId
        \o message.side
        \o EncodeExecutionAllocationsGroups(message.executionAllocationsGroups)
        \o EncodeRequestedAllocationsGroups(message.requestedAllocationsGroups)

DecodeAllocationInstructionMessage(bytes) ==
    LET sendingTime == ReadBytes(bytes, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET allocId == ReadBytes(sendingTime.rest, 20) IN IF ~allocId.ok THEN Fail ELSE
    LET allocType == ReadBytes(allocId.rest, 1) IN IF ~allocType.ok THEN Fail ELSE
    LET allocTransType == ReadBytes(allocType.rest, 1) IN IF ~allocTransType.ok THEN Fail ELSE
    LET refAllocIdOptional == ReadBytes(allocTransType.rest, 20) IN IF ~refAllocIdOptional.ok THEN Fail ELSE
    LET securityId == ReadBytes(refAllocIdOptional.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET side == ReadBytes(securityId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET executionAllocationsGroups == DecodeExecutionAllocationsGroups(side.rest) IN IF ~executionAllocationsGroups.ok THEN Fail ELSE
    LET requestedAllocationsGroups == DecodeRequestedAllocationsGroups(executionAllocationsGroups.rest) IN IF ~requestedAllocationsGroups.ok THEN Fail ELSE
    Ok([ sendingTime                |-> sendingTime.value,
         allocId                    |-> allocId.value,
         allocType                  |-> allocType.value,
         allocTransType             |-> allocTransType.value,
         refAllocIdOptional         |-> refAllocIdOptional.value,
         securityId                 |-> securityId.value,
         side                       |-> side.value,
         executionAllocationsGroups |-> executionAllocationsGroups.value,
         requestedAllocationsGroups |-> requestedAllocationsGroups.value ], requestedAllocationsGroups.rest)

ZeroAllocationInstructionMessage ==
    [ sendingTime                |-> [i \in 1 .. 8 |-> 0],
      allocId                    |-> [i \in 1 .. 20 |-> 0],
      allocType                  |-> [i \in 1 .. 1 |-> 0],
      allocTransType             |-> [i \in 1 .. 1 |-> 0],
      refAllocIdOptional         |-> [i \in 1 .. 20 |-> 0],
      securityId                 |-> [i \in 1 .. 8 |-> 0],
      side                       |-> [i \in 1 .. 1 |-> 0],
      executionAllocationsGroups |-> ZeroExecutionAllocationsGroups,
      requestedAllocationsGroups |-> ZeroRequestedAllocationsGroups ]

(* Allocation Instruction Message at zero, then each field in turn at the values it is checked at *)
CheckedAllocationInstructionMessage ==
    { ZeroAllocationInstructionMessage }
        \cup { [ZeroAllocationInstructionMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroAllocationInstructionMessage EXCEPT !.allocId = one] : one \in Sample(20) }
        \cup { [ZeroAllocationInstructionMessage EXCEPT !.allocType = one] : one \in Sample(1) }
        \cup { [ZeroAllocationInstructionMessage EXCEPT !.allocTransType = one] : one \in Sample(1) }
        \cup { [ZeroAllocationInstructionMessage EXCEPT !.refAllocIdOptional = one] : one \in Sample(20) }
        \cup { [ZeroAllocationInstructionMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroAllocationInstructionMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAllocationInstructionMessage EXCEPT !.executionAllocationsGroups = one] : one \in CheckedExecutionAllocationsGroups }
        \cup { [ZeroAllocationInstructionMessage EXCEPT !.requestedAllocationsGroups = one] : one \in CheckedRequestedAllocationsGroups }

(***************************************************************************)
(* Client Payload, selected by Template Id                                 *)
(***************************************************************************)

NewOrderSingleMessageCode == 1  \* 0x01
ShortTwoSidedBulkQuoteMessageCode == 2  \* 0x02
LongTwoSidedBulkQuoteMessageCode == 3  \* 0x03
ShortOneSidedBulkQuoteMessageCode == 4  \* 0x04
LongOneSidedBulkQuoteMessageCode == 5  \* 0x05
OrderCancelReplaceRequestMessageCode == 6  \* 0x06
OrderCancelRequestMessageCode == 7  \* 0x07
MassCancelRequestMessageCode == 8  \* 0x08
MassCancelClearLockoutRequestMessageCode == 9  \* 0x09
AllocationInstructionMessageCode == 10  \* 0x0a

ClientPayload ==
    [ tag : {NewOrderSingleMessageCode}, body : NewOrderSingleMessage ]
        \cup [ tag : {ShortTwoSidedBulkQuoteMessageCode}, body : ShortTwoSidedBulkQuoteMessage ]
        \cup [ tag : {LongTwoSidedBulkQuoteMessageCode}, body : LongTwoSidedBulkQuoteMessage ]
        \cup [ tag : {ShortOneSidedBulkQuoteMessageCode}, body : ShortOneSidedBulkQuoteMessage ]
        \cup [ tag : {LongOneSidedBulkQuoteMessageCode}, body : LongOneSidedBulkQuoteMessage ]
        \cup [ tag : {OrderCancelReplaceRequestMessageCode}, body : OrderCancelReplaceRequestMessage ]
        \cup [ tag : {OrderCancelRequestMessageCode}, body : OrderCancelRequestMessage ]
        \cup [ tag : {MassCancelRequestMessageCode}, body : MassCancelRequestMessage ]
        \cup [ tag : {MassCancelClearLockoutRequestMessageCode}, body : MassCancelClearLockoutRequestMessage ]
        \cup [ tag : {AllocationInstructionMessageCode}, body : AllocationInstructionMessage ]

EncodeClientPayload(message) ==
    CASE message.tag = NewOrderSingleMessageCode -> EncodeNewOrderSingleMessage(message.body)
      [] message.tag = ShortTwoSidedBulkQuoteMessageCode -> EncodeShortTwoSidedBulkQuoteMessage(message.body)
      [] message.tag = LongTwoSidedBulkQuoteMessageCode -> EncodeLongTwoSidedBulkQuoteMessage(message.body)
      [] message.tag = ShortOneSidedBulkQuoteMessageCode -> EncodeShortOneSidedBulkQuoteMessage(message.body)
      [] message.tag = LongOneSidedBulkQuoteMessageCode -> EncodeLongOneSidedBulkQuoteMessage(message.body)
      [] message.tag = OrderCancelReplaceRequestMessageCode -> EncodeOrderCancelReplaceRequestMessage(message.body)
      [] message.tag = OrderCancelRequestMessageCode -> EncodeOrderCancelRequestMessage(message.body)
      [] message.tag = MassCancelRequestMessageCode -> EncodeMassCancelRequestMessage(message.body)
      [] message.tag = MassCancelClearLockoutRequestMessageCode -> EncodeMassCancelClearLockoutRequestMessage(message.body)
      [] message.tag = AllocationInstructionMessageCode -> EncodeAllocationInstructionMessage(message.body)

DecodeClientPayload(tag, bytes) ==
    LET read ==
            CASE tag = NewOrderSingleMessageCode -> DecodeNewOrderSingleMessage(bytes)
              [] tag = ShortTwoSidedBulkQuoteMessageCode -> DecodeShortTwoSidedBulkQuoteMessage(bytes)
              [] tag = LongTwoSidedBulkQuoteMessageCode -> DecodeLongTwoSidedBulkQuoteMessage(bytes)
              [] tag = ShortOneSidedBulkQuoteMessageCode -> DecodeShortOneSidedBulkQuoteMessage(bytes)
              [] tag = LongOneSidedBulkQuoteMessageCode -> DecodeLongOneSidedBulkQuoteMessage(bytes)
              [] tag = OrderCancelReplaceRequestMessageCode -> DecodeOrderCancelReplaceRequestMessage(bytes)
              [] tag = OrderCancelRequestMessageCode -> DecodeOrderCancelRequestMessage(bytes)
              [] tag = MassCancelRequestMessageCode -> DecodeMassCancelRequestMessage(bytes)
              [] tag = MassCancelClearLockoutRequestMessageCode -> DecodeMassCancelClearLockoutRequestMessage(bytes)
              [] tag = AllocationInstructionMessageCode -> DecodeAllocationInstructionMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroClientPayload == [tag |-> NewOrderSingleMessageCode, body |-> ZeroNewOrderSingleMessage]

(* Each Client Payload in turn, at the values the message it names is checked at *)
CheckedClientPayload ==
    { [tag |-> NewOrderSingleMessageCode, body |-> one] : one \in CheckedNewOrderSingleMessage }
        \cup { [tag |-> ShortTwoSidedBulkQuoteMessageCode, body |-> one] : one \in CheckedShortTwoSidedBulkQuoteMessage }
        \cup { [tag |-> LongTwoSidedBulkQuoteMessageCode, body |-> one] : one \in CheckedLongTwoSidedBulkQuoteMessage }
        \cup { [tag |-> ShortOneSidedBulkQuoteMessageCode, body |-> one] : one \in CheckedShortOneSidedBulkQuoteMessage }
        \cup { [tag |-> LongOneSidedBulkQuoteMessageCode, body |-> one] : one \in CheckedLongOneSidedBulkQuoteMessage }
        \cup { [tag |-> OrderCancelReplaceRequestMessageCode, body |-> one] : one \in CheckedOrderCancelReplaceRequestMessage }
        \cup { [tag |-> OrderCancelRequestMessageCode, body |-> one] : one \in CheckedOrderCancelRequestMessage }
        \cup { [tag |-> MassCancelRequestMessageCode, body |-> one] : one \in CheckedMassCancelRequestMessage }
        \cup { [tag |-> MassCancelClearLockoutRequestMessageCode, body |-> one] : one \in CheckedMassCancelClearLockoutRequestMessage }
        \cup { [tag |-> AllocationInstructionMessageCode, body |-> one] : one \in CheckedAllocationInstructionMessage }

(***************************************************************************)
(* Client Sbe Message                                                      *)
(***************************************************************************)

ClientSbeMessage ==
    [ blockLength   : Sample(2),
      schemaId      : Sample(1),
      version       : Sample(2),
      numGroups     : Sample(1),
      clientPayload : ClientPayload ]

EncodeClientSbeMessage(message) ==
    message.blockLength
        \o EncodeUIntBE(message.clientPayload.tag, 1)
        \o message.schemaId
        \o message.version
        \o message.numGroups
        \o EncodeClientPayload(message.clientPayload)

DecodeClientSbeMessage(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET templateId == ReadUIntBE(blockLength.rest, 1) IN IF ~templateId.ok THEN Fail ELSE
    LET schemaId == ReadBytes(templateId.rest, 1) IN IF ~schemaId.ok THEN Fail ELSE
    LET version == ReadBytes(schemaId.rest, 2) IN IF ~version.ok THEN Fail ELSE
    LET numGroups == ReadBytes(version.rest, 1) IN IF ~numGroups.ok THEN Fail ELSE
    LET clientPayload == DecodeClientPayload(templateId.value, numGroups.rest) IN IF ~clientPayload.ok THEN Fail ELSE
    Ok([ blockLength   |-> blockLength.value,
         schemaId      |-> schemaId.value,
         version       |-> version.value,
         numGroups     |-> numGroups.value,
         clientPayload |-> clientPayload.value ], clientPayload.rest)

ZeroClientSbeMessage ==
    [ blockLength   |-> [i \in 1 .. 2 |-> 0],
      schemaId      |-> [i \in 1 .. 1 |-> 0],
      version       |-> [i \in 1 .. 2 |-> 0],
      numGroups     |-> [i \in 1 .. 1 |-> 0],
      clientPayload |-> ZeroClientPayload ]

(* Client Sbe Message at zero, then each field in turn at the values it is checked at *)
CheckedClientSbeMessage ==
    { ZeroClientSbeMessage }
        \cup { [ZeroClientSbeMessage EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroClientSbeMessage EXCEPT !.schemaId = one] : one \in Sample(1) }
        \cup { [ZeroClientSbeMessage EXCEPT !.version = one] : one \in Sample(2) }
        \cup { [ZeroClientSbeMessage EXCEPT !.numGroups = one] : one \in Sample(1) }
        \cup { [ZeroClientSbeMessage EXCEPT !.clientPayload = one] : one \in CheckedClientPayload }

(***************************************************************************)
(* Unsequenced Message                                                     *)
(***************************************************************************)

UnsequencedMessage ==
    [ clientSbeMessage : ClientSbeMessage ]

EncodeUnsequencedMessage(message) ==
    EncodeClientSbeMessage(message.clientSbeMessage)

DecodeUnsequencedMessage(bytes) ==
    LET clientSbeMessage == DecodeClientSbeMessage(bytes) IN IF ~clientSbeMessage.ok THEN Fail ELSE
    Ok([ clientSbeMessage |-> clientSbeMessage.value ], clientSbeMessage.rest)

ZeroUnsequencedMessage ==
    [ clientSbeMessage |-> ZeroClientSbeMessage ]

(* Unsequenced Message at zero, then each field in turn at the values it is checked at *)
CheckedUnsequencedMessage ==
    { ZeroUnsequencedMessage }
        \cup { [ZeroUnsequencedMessage EXCEPT !.clientSbeMessage = one] : one \in CheckedClientSbeMessage }

(***************************************************************************)
(* Client Data, selected by Message Type                                   *)
(***************************************************************************)

LoginRequestMessageCode == 100  \* 0x64
ReplayRequestMessageCode == 101  \* 0x65
ReplayAllRequestMessageCode == 102  \* 0x66
StreamRequestMessageCode == 103  \* 0x67
UnsequencedMessageCode == 104  \* 0x68

ClientData ==
    [ tag : {LoginRequestMessageCode}, body : LoginRequestMessage ]
        \cup [ tag : {ReplayRequestMessageCode}, body : ReplayRequestMessage ]
        \cup [ tag : {ReplayAllRequestMessageCode}, body : ReplayAllRequestMessage ]
        \cup [ tag : {StreamRequestMessageCode}, body : StreamRequestMessage ]
        \cup [ tag : {UnsequencedMessageCode}, body : UnsequencedMessage ]

EncodeClientData(message) ==
    CASE message.tag = LoginRequestMessageCode -> EncodeLoginRequestMessage(message.body)
      [] message.tag = ReplayRequestMessageCode -> EncodeReplayRequestMessage(message.body)
      [] message.tag = ReplayAllRequestMessageCode -> EncodeReplayAllRequestMessage(message.body)
      [] message.tag = StreamRequestMessageCode -> EncodeStreamRequestMessage(message.body)
      [] message.tag = UnsequencedMessageCode -> EncodeUnsequencedMessage(message.body)

DecodeClientData(tag, bytes) ==
    LET read ==
            CASE tag = LoginRequestMessageCode -> DecodeLoginRequestMessage(bytes)
              [] tag = ReplayRequestMessageCode -> DecodeReplayRequestMessage(bytes)
              [] tag = ReplayAllRequestMessageCode -> DecodeReplayAllRequestMessage(bytes)
              [] tag = StreamRequestMessageCode -> DecodeStreamRequestMessage(bytes)
              [] tag = UnsequencedMessageCode -> DecodeUnsequencedMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroClientData == [tag |-> LoginRequestMessageCode, body |-> ZeroLoginRequestMessage]

(* Each Client Data in turn, at the values the message it names is checked at *)
CheckedClientData ==
    { [tag |-> LoginRequestMessageCode, body |-> one] : one \in CheckedLoginRequestMessage }
        \cup { [tag |-> ReplayRequestMessageCode, body |-> one] : one \in CheckedReplayRequestMessage }
        \cup { [tag |-> ReplayAllRequestMessageCode, body |-> one] : one \in CheckedReplayAllRequestMessage }
        \cup { [tag |-> StreamRequestMessageCode, body |-> one] : one \in CheckedStreamRequestMessage }
        \cup { [tag |-> UnsequencedMessageCode, body |-> one] : one \in CheckedUnsequencedMessage }

(***************************************************************************)
(* Client Packet                                                           *)
(***************************************************************************)

ClientPacket ==
    [ messageLength : 0 .. 255,
      clientData    : ClientData ]

EncodeClientPacket(message) ==
    EncodeUIntBE(message.clientData.tag, 1)
        \o EncodeUIntBE(message.messageLength, 2)
        \o EncodeClientData(message.clientData)

DecodeClientPacket(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET messageLength == ReadUIntBE(messageType.rest, 2) IN IF ~messageLength.ok THEN Fail ELSE
    LET clientData == DecodeClientData(messageType.value, messageLength.rest) IN IF ~clientData.ok THEN Fail ELSE
    Ok([ messageLength |-> messageLength.value,
         clientData    |-> clientData.value ], clientData.rest)

ZeroClientPacket ==
    [ messageLength |-> 0,
      clientData    |-> ZeroClientData ]

(* Client Packet at zero, then each field in turn at the values it is checked at *)
CheckedClientPacket ==
    { ZeroClientPacket }
        \cup { [ZeroClientPacket EXCEPT !.messageLength = one] : one \in {0, 1, 255} }
        \cup { [ZeroClientPacket EXCEPT !.clientData = one] : one \in CheckedClientData }

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

(* Every Login Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRequestMessage ==
    \A message \in CheckedLoginRequestMessage :
        LET read == DecodeLoginRequestMessage(EncodeLoginRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Replay Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReplayRequestMessage ==
    \A message \in CheckedReplayRequestMessage :
        LET read == DecodeReplayRequestMessage(EncodeReplayRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Replay All Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReplayAllRequestMessage ==
    \A message \in CheckedReplayAllRequestMessage :
        LET read == DecodeReplayAllRequestMessage(EncodeReplayAllRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stream Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStreamRequestMessage ==
    \A message \in CheckedStreamRequestMessage :
        LET read == DecodeStreamRequestMessage(EncodeStreamRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Parties Group decodes back to what was encoded, and leaves nothing over *)
RoundTripPartiesGroup ==
    \A message \in CheckedPartiesGroup :
        LET read == DecodePartiesGroup(EncodePartiesGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Parties Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripPartiesGroups ==
    \A message \in CheckedPartiesGroups :
        LET read == DecodePartiesGroups(EncodePartiesGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Single Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderSingleMessage ==
    \A message \in CheckedNewOrderSingleMessage :
        LET read == DecodeNewOrderSingleMessage(EncodeNewOrderSingleMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Parties Group decodes back to what was encoded, and leaves nothing over *)
RoundTripPartiesGroup2 ==
    \A message \in CheckedPartiesGroup2 :
        LET read == DecodePartiesGroup2(EncodePartiesGroup2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Parties Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripPartiesGroups2 ==
    \A message \in CheckedPartiesGroups2 :
        LET read == DecodePartiesGroups2(EncodePartiesGroups2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Two Sided Quotes Group decodes back to what was encoded, and leaves nothing over *)
RoundTripTwoSidedQuotesGroup ==
    \A message \in CheckedTwoSidedQuotesGroup :
        LET read == DecodeTwoSidedQuotesGroup(EncodeTwoSidedQuotesGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Two Sided Quotes Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripTwoSidedQuotesGroups ==
    \A message \in CheckedTwoSidedQuotesGroups :
        LET read == DecodeTwoSidedQuotesGroups(EncodeTwoSidedQuotesGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Short Two Sided Bulk Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripShortTwoSidedBulkQuoteMessage ==
    \A message \in CheckedShortTwoSidedBulkQuoteMessage :
        LET read == DecodeShortTwoSidedBulkQuoteMessage(EncodeShortTwoSidedBulkQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Parties Group decodes back to what was encoded, and leaves nothing over *)
RoundTripPartiesGroup3 ==
    \A message \in CheckedPartiesGroup3 :
        LET read == DecodePartiesGroup3(EncodePartiesGroup3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Parties Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripPartiesGroups3 ==
    \A message \in CheckedPartiesGroups3 :
        LET read == DecodePartiesGroups3(EncodePartiesGroups3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Two Sided Quotes Group decodes back to what was encoded, and leaves nothing over *)
RoundTripTwoSidedQuotesGroup2 ==
    \A message \in CheckedTwoSidedQuotesGroup2 :
        LET read == DecodeTwoSidedQuotesGroup2(EncodeTwoSidedQuotesGroup2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Two Sided Quotes Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripTwoSidedQuotesGroups2 ==
    \A message \in CheckedTwoSidedQuotesGroups2 :
        LET read == DecodeTwoSidedQuotesGroups2(EncodeTwoSidedQuotesGroups2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Two Sided Bulk Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLongTwoSidedBulkQuoteMessage ==
    \A message \in CheckedLongTwoSidedBulkQuoteMessage :
        LET read == DecodeLongTwoSidedBulkQuoteMessage(EncodeLongTwoSidedBulkQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Parties Group decodes back to what was encoded, and leaves nothing over *)
RoundTripPartiesGroup4 ==
    \A message \in CheckedPartiesGroup4 :
        LET read == DecodePartiesGroup4(EncodePartiesGroup4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Parties Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripPartiesGroups4 ==
    \A message \in CheckedPartiesGroups4 :
        LET read == DecodePartiesGroups4(EncodePartiesGroups4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every One Sided Quotes Group decodes back to what was encoded, and leaves nothing over *)
RoundTripOneSidedQuotesGroup ==
    \A message \in CheckedOneSidedQuotesGroup :
        LET read == DecodeOneSidedQuotesGroup(EncodeOneSidedQuotesGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every One Sided Quotes Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripOneSidedQuotesGroups ==
    \A message \in CheckedOneSidedQuotesGroups :
        LET read == DecodeOneSidedQuotesGroups(EncodeOneSidedQuotesGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Short One Sided Bulk Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripShortOneSidedBulkQuoteMessage ==
    \A message \in CheckedShortOneSidedBulkQuoteMessage :
        LET read == DecodeShortOneSidedBulkQuoteMessage(EncodeShortOneSidedBulkQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Parties Group decodes back to what was encoded, and leaves nothing over *)
RoundTripPartiesGroup5 ==
    \A message \in CheckedPartiesGroup5 :
        LET read == DecodePartiesGroup5(EncodePartiesGroup5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Parties Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripPartiesGroups5 ==
    \A message \in CheckedPartiesGroups5 :
        LET read == DecodePartiesGroups5(EncodePartiesGroups5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every One Sided Quotes Group decodes back to what was encoded, and leaves nothing over *)
RoundTripOneSidedQuotesGroup2 ==
    \A message \in CheckedOneSidedQuotesGroup2 :
        LET read == DecodeOneSidedQuotesGroup2(EncodeOneSidedQuotesGroup2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every One Sided Quotes Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripOneSidedQuotesGroups2 ==
    \A message \in CheckedOneSidedQuotesGroups2 :
        LET read == DecodeOneSidedQuotesGroups2(EncodeOneSidedQuotesGroups2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long One Sided Bulk Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLongOneSidedBulkQuoteMessage ==
    \A message \in CheckedLongOneSidedBulkQuoteMessage :
        LET read == DecodeLongOneSidedBulkQuoteMessage(EncodeLongOneSidedBulkQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancel Replace Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelReplaceRequestMessage ==
    \A message \in CheckedOrderCancelReplaceRequestMessage :
        LET read == DecodeOrderCancelReplaceRequestMessage(EncodeOrderCancelReplaceRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancel Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelRequestMessage ==
    \A message \in CheckedOrderCancelRequestMessage :
        LET read == DecodeOrderCancelRequestMessage(EncodeOrderCancelRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Cancel Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMassCancelRequestMessage ==
    \A message \in CheckedMassCancelRequestMessage :
        LET read == DecodeMassCancelRequestMessage(EncodeMassCancelRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Cancel Clear Lockout Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMassCancelClearLockoutRequestMessage ==
    \A message \in CheckedMassCancelClearLockoutRequestMessage :
        LET read == DecodeMassCancelClearLockoutRequestMessage(EncodeMassCancelClearLockoutRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Allocations Group decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionAllocationsGroup ==
    \A message \in CheckedExecutionAllocationsGroup :
        LET read == DecodeExecutionAllocationsGroup(EncodeExecutionAllocationsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Allocations Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionAllocationsGroups ==
    \A message \in CheckedExecutionAllocationsGroups :
        LET read == DecodeExecutionAllocationsGroups(EncodeExecutionAllocationsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Nested Parties Group decodes back to what was encoded, and leaves nothing over *)
RoundTripNestedPartiesGroup ==
    \A message \in CheckedNestedPartiesGroup :
        LET read == DecodeNestedPartiesGroup(EncodeNestedPartiesGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Nested Parties Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripNestedPartiesGroups ==
    \A message \in CheckedNestedPartiesGroups :
        LET read == DecodeNestedPartiesGroups(EncodeNestedPartiesGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Requested Allocations Group decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestedAllocationsGroup ==
    \A message \in CheckedRequestedAllocationsGroup :
        LET read == DecodeRequestedAllocationsGroup(EncodeRequestedAllocationsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Requested Allocations Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestedAllocationsGroups ==
    \A message \in CheckedRequestedAllocationsGroups :
        LET read == DecodeRequestedAllocationsGroups(EncodeRequestedAllocationsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Allocation Instruction Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAllocationInstructionMessage ==
    \A message \in CheckedAllocationInstructionMessage :
        LET read == DecodeAllocationInstructionMessage(EncodeAllocationInstructionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client Sbe Message decodes back to what was encoded, and leaves nothing over *)
RoundTripClientSbeMessage ==
    \A message \in CheckedClientSbeMessage :
        LET read == DecodeClientSbeMessage(EncodeClientSbeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Unsequenced Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUnsequencedMessage ==
    \A message \in CheckedUnsequencedMessage :
        LET read == DecodeUnsequencedMessage(EncodeUnsequencedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripClientPacket ==
    \A message \in CheckedClientPacket :
        LET read == DecodeClientPacket(EncodeClientPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Client Payload is selected by the Template Id it is written under *)
SelectsClientPayload ==
    \A message \in CheckedClientPayload :
        LET read == DecodeClientPayload(message.tag, EncodeClientPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Client Data is selected by the Message Type it is written under *)
SelectsClientData ==
    \A message \in CheckedClientData :
        LET read == DecodeClientData(message.tag, EncodeClientData(message))
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
