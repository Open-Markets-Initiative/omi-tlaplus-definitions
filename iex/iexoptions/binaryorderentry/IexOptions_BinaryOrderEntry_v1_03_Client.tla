------------- MODULE IexOptions_BinaryOrderEntry_v1_03_Client --------------
(***************************************************************************)
(* Investors Exchange Binary Order Entry v1.03                             *)
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
(* Login Request Message: 48 bytes                                         *)
(***************************************************************************)

LoginRequestMessage ==
    [ logonId : Sample(16),
      token   : Sample(32) ]

EncodeLoginRequestMessage(message) ==
    message.logonId
        \o message.token

DecodeLoginRequestMessage(bytes) ==
    LET logonId == ReadBytes(bytes, 16) IN IF ~logonId.ok THEN Fail ELSE
    LET token == ReadBytes(logonId.rest, 32) IN IF ~token.ok THEN Fail ELSE
    Ok([ logonId |-> logonId.value,
         token   |-> token.value ], token.rest)

ZeroLoginRequestMessage ==
    [ logonId |-> [i \in 1 .. 16 |-> 0],
      token   |-> [i \in 1 .. 32 |-> 0] ]

(* Login Request Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginRequestMessage ==
    { ZeroLoginRequestMessage }
        \cup { [ZeroLoginRequestMessage EXCEPT !.logonId = one] : one \in Sample(16) }
        \cup { [ZeroLoginRequestMessage EXCEPT !.token = one] : one \in Sample(32) }

(***************************************************************************)
(* Login Response Message: 17 bytes                                        *)
(***************************************************************************)

LoginResponseMessage ==
    [ logonId : Sample(16),
      status  : Sample(1) ]

EncodeLoginResponseMessage(message) ==
    message.logonId
        \o message.status

DecodeLoginResponseMessage(bytes) ==
    LET logonId == ReadBytes(bytes, 16) IN IF ~logonId.ok THEN Fail ELSE
    LET status == ReadBytes(logonId.rest, 1) IN IF ~status.ok THEN Fail ELSE
    Ok([ logonId |-> logonId.value,
         status  |-> status.value ], status.rest)

ZeroLoginResponseMessage ==
    [ logonId |-> [i \in 1 .. 16 |-> 0],
      status  |-> [i \in 1 .. 1 |-> 0] ]

(* Login Response Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginResponseMessage ==
    { ZeroLoginResponseMessage }
        \cup { [ZeroLoginResponseMessage EXCEPT !.logonId = one] : one \in Sample(16) }
        \cup { [ZeroLoginResponseMessage EXCEPT !.status = one] : one \in Sample(1) }

(***************************************************************************)
(* Sub Sessions Group: 14 bytes                                            *)
(***************************************************************************)

SubSessionsGroup ==
    [ subsessionType : Sample(1),
      subsessionId   : Sample(8),
      joined         : Sample(1),
      nextSeqNo      : Sample(4) ]

EncodeSubSessionsGroup(message) ==
    message.subsessionType
        \o message.subsessionId
        \o message.joined
        \o message.nextSeqNo

DecodeSubSessionsGroup(bytes) ==
    LET subsessionType == ReadBytes(bytes, 1) IN IF ~subsessionType.ok THEN Fail ELSE
    LET subsessionId == ReadBytes(subsessionType.rest, 8) IN IF ~subsessionId.ok THEN Fail ELSE
    LET joined == ReadBytes(subsessionId.rest, 1) IN IF ~joined.ok THEN Fail ELSE
    LET nextSeqNo == ReadBytes(joined.rest, 4) IN IF ~nextSeqNo.ok THEN Fail ELSE
    Ok([ subsessionType |-> subsessionType.value,
         subsessionId   |-> subsessionId.value,
         joined         |-> joined.value,
         nextSeqNo      |-> nextSeqNo.value ], nextSeqNo.rest)

ZeroSubSessionsGroup ==
    [ subsessionType |-> [i \in 1 .. 1 |-> 0],
      subsessionId   |-> [i \in 1 .. 8 |-> 0],
      joined         |-> [i \in 1 .. 1 |-> 0],
      nextSeqNo      |-> [i \in 1 .. 4 |-> 0] ]

(* Sub Sessions Group at zero, then each field in turn at the values it is checked at *)
CheckedSubSessionsGroup ==
    { ZeroSubSessionsGroup }
        \cup { [ZeroSubSessionsGroup EXCEPT !.subsessionType = one] : one \in Sample(1) }
        \cup { [ZeroSubSessionsGroup EXCEPT !.subsessionId = one] : one \in Sample(8) }
        \cup { [ZeroSubSessionsGroup EXCEPT !.joined = one] : one \in Sample(1) }
        \cup { [ZeroSubSessionsGroup EXCEPT !.nextSeqNo = one] : one \in Sample(4) }

(* A run of Sub Sessions Group, written one after another *)
RECURSIVE EncodeSubSessionsGroupList(_)
EncodeSubSessionsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSubSessionsGroup(Head(messages)) \o EncodeSubSessionsGroupList(Tail(messages))

(* As many Sub Sessions Group as the field that counts them says *)
RECURSIVE ReadSubSessionsGroupList(_, _)
ReadSubSessionsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSubSessionsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSubSessionsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Sub Sessions Group of each kind, for the lists that carry them *)
OneSubSessionsGroup == { ZeroSubSessionsGroup }

(***************************************************************************)
(* Sub Sessions Groups                                                     *)
(***************************************************************************)

SubSessionsGroups ==
    [ blockLengthShort : Sample(1),
      subSessionsGroup : SampleLists(OneSubSessionsGroup) ]

EncodeSubSessionsGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.subSessionsGroup), 1)
        \o EncodeSubSessionsGroupList(message.subSessionsGroup)

DecodeSubSessionsGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET subSessionsGroup == ReadSubSessionsGroupList(numInGroup.rest, numInGroup.value) IN IF ~subSessionsGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort |-> blockLengthShort.value,
         subSessionsGroup |-> subSessionsGroup.value ], subSessionsGroup.rest)

ZeroSubSessionsGroups ==
    [ blockLengthShort |-> [i \in 1 .. 1 |-> 0],
      subSessionsGroup |-> << >> ]

(* Sub Sessions Groups at zero, then each field in turn at the values it is checked at *)
CheckedSubSessionsGroups ==
    { ZeroSubSessionsGroups }
        \cup { [ZeroSubSessionsGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroSubSessionsGroups EXCEPT !.subSessionsGroup = one] : one \in SampleLists(OneSubSessionsGroup) }

(***************************************************************************)
(* Gateway Heartbeat Message                                               *)
(***************************************************************************)

GatewayHeartbeatMessage ==
    [ keepAlive         : Sample(1),
      subSessionsGroups : SubSessionsGroups ]

EncodeGatewayHeartbeatMessage(message) ==
    message.keepAlive
        \o EncodeSubSessionsGroups(message.subSessionsGroups)

DecodeGatewayHeartbeatMessage(bytes) ==
    LET keepAlive == ReadBytes(bytes, 1) IN IF ~keepAlive.ok THEN Fail ELSE
    LET subSessionsGroups == DecodeSubSessionsGroups(keepAlive.rest) IN IF ~subSessionsGroups.ok THEN Fail ELSE
    Ok([ keepAlive         |-> keepAlive.value,
         subSessionsGroups |-> subSessionsGroups.value ], subSessionsGroups.rest)

ZeroGatewayHeartbeatMessage ==
    [ keepAlive         |-> [i \in 1 .. 1 |-> 0],
      subSessionsGroups |-> ZeroSubSessionsGroups ]

(* Gateway Heartbeat Message at zero, then each field in turn at the values it is checked at *)
CheckedGatewayHeartbeatMessage ==
    { ZeroGatewayHeartbeatMessage }
        \cup { [ZeroGatewayHeartbeatMessage EXCEPT !.keepAlive = one] : one \in Sample(1) }
        \cup { [ZeroGatewayHeartbeatMessage EXCEPT !.subSessionsGroups = one] : one \in CheckedSubSessionsGroups }

(***************************************************************************)
(* Terminate Message: 1 bytes                                              *)
(***************************************************************************)

TerminateMessage ==
    [ reason : Sample(1) ]

EncodeTerminateMessage(message) ==
    message.reason

DecodeTerminateMessage(bytes) ==
    LET reason == ReadBytes(bytes, 1) IN IF ~reason.ok THEN Fail ELSE
    Ok([ reason |-> reason.value ], reason.rest)

ZeroTerminateMessage ==
    [ reason |-> [i \in 1 .. 1 |-> 0] ]

(* Terminate Message at zero, then each field in turn at the values it is checked at *)
CheckedTerminateMessage ==
    { ZeroTerminateMessage }
        \cup { [ZeroTerminateMessage EXCEPT !.reason = one] : one \in Sample(1) }

(***************************************************************************)
(* Sequenced Message Header Message: 20 bytes                              *)
(***************************************************************************)

SequencedMessageHeaderMessage ==
    [ subsessionId : Sample(8),
      sequence     : Sample(4),
      timestamp    : Sample(8) ]

EncodeSequencedMessageHeaderMessage(message) ==
    message.subsessionId
        \o message.sequence
        \o message.timestamp

DecodeSequencedMessageHeaderMessage(bytes) ==
    LET subsessionId == ReadBytes(bytes, 8) IN IF ~subsessionId.ok THEN Fail ELSE
    LET sequence == ReadBytes(subsessionId.rest, 4) IN IF ~sequence.ok THEN Fail ELSE
    LET timestamp == ReadBytes(sequence.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    Ok([ subsessionId |-> subsessionId.value,
         sequence     |-> sequence.value,
         timestamp    |-> timestamp.value ], timestamp.rest)

ZeroSequencedMessageHeaderMessage ==
    [ subsessionId |-> [i \in 1 .. 8 |-> 0],
      sequence     |-> [i \in 1 .. 4 |-> 0],
      timestamp    |-> [i \in 1 .. 8 |-> 0] ]

(* Sequenced Message Header Message at zero, then each field in turn at the values it is checked at *)
CheckedSequencedMessageHeaderMessage ==
    { ZeroSequencedMessageHeaderMessage }
        \cup { [ZeroSequencedMessageHeaderMessage EXCEPT !.subsessionId = one] : one \in Sample(8) }
        \cup { [ZeroSequencedMessageHeaderMessage EXCEPT !.sequence = one] : one \in Sample(4) }
        \cup { [ZeroSequencedMessageHeaderMessage EXCEPT !.timestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Subsession Join Message: 16 bytes                                       *)
(***************************************************************************)

SubsessionJoinMessage ==
    [ subsessionId  : Sample(8),
      startSequence : Sample(4),
      endSequence   : Sample(4) ]

EncodeSubsessionJoinMessage(message) ==
    message.subsessionId
        \o message.startSequence
        \o message.endSequence

DecodeSubsessionJoinMessage(bytes) ==
    LET subsessionId == ReadBytes(bytes, 8) IN IF ~subsessionId.ok THEN Fail ELSE
    LET startSequence == ReadBytes(subsessionId.rest, 4) IN IF ~startSequence.ok THEN Fail ELSE
    LET endSequence == ReadBytes(startSequence.rest, 4) IN IF ~endSequence.ok THEN Fail ELSE
    Ok([ subsessionId  |-> subsessionId.value,
         startSequence |-> startSequence.value,
         endSequence   |-> endSequence.value ], endSequence.rest)

ZeroSubsessionJoinMessage ==
    [ subsessionId  |-> [i \in 1 .. 8 |-> 0],
      startSequence |-> [i \in 1 .. 4 |-> 0],
      endSequence   |-> [i \in 1 .. 4 |-> 0] ]

(* Subsession Join Message at zero, then each field in turn at the values it is checked at *)
CheckedSubsessionJoinMessage ==
    { ZeroSubsessionJoinMessage }
        \cup { [ZeroSubsessionJoinMessage EXCEPT !.subsessionId = one] : one \in Sample(8) }
        \cup { [ZeroSubsessionJoinMessage EXCEPT !.startSequence = one] : one \in Sample(4) }
        \cup { [ZeroSubsessionJoinMessage EXCEPT !.endSequence = one] : one \in Sample(4) }

(***************************************************************************)
(* Subsession Join Response Message: 9 bytes                               *)
(***************************************************************************)

SubsessionJoinResponseMessage ==
    [ subsessionId : Sample(8),
      status       : Sample(1) ]

EncodeSubsessionJoinResponseMessage(message) ==
    message.subsessionId
        \o message.status

DecodeSubsessionJoinResponseMessage(bytes) ==
    LET subsessionId == ReadBytes(bytes, 8) IN IF ~subsessionId.ok THEN Fail ELSE
    LET status == ReadBytes(subsessionId.rest, 1) IN IF ~status.ok THEN Fail ELSE
    Ok([ subsessionId |-> subsessionId.value,
         status       |-> status.value ], status.rest)

ZeroSubsessionJoinResponseMessage ==
    [ subsessionId |-> [i \in 1 .. 8 |-> 0],
      status       |-> [i \in 1 .. 1 |-> 0] ]

(* Subsession Join Response Message at zero, then each field in turn at the values it is checked at *)
CheckedSubsessionJoinResponseMessage ==
    { ZeroSubsessionJoinResponseMessage }
        \cup { [ZeroSubsessionJoinResponseMessage EXCEPT !.subsessionId = one] : one \in Sample(8) }
        \cup { [ZeroSubsessionJoinResponseMessage EXCEPT !.status = one] : one \in Sample(1) }

(***************************************************************************)
(* Subsession Leave Message: 8 bytes                                       *)
(***************************************************************************)

SubsessionLeaveMessage ==
    [ subsessionId : Sample(8) ]

EncodeSubsessionLeaveMessage(message) ==
    message.subsessionId

DecodeSubsessionLeaveMessage(bytes) ==
    LET subsessionId == ReadBytes(bytes, 8) IN IF ~subsessionId.ok THEN Fail ELSE
    Ok([ subsessionId |-> subsessionId.value ], subsessionId.rest)

ZeroSubsessionLeaveMessage ==
    [ subsessionId |-> [i \in 1 .. 8 |-> 0] ]

(* Subsession Leave Message at zero, then each field in turn at the values it is checked at *)
CheckedSubsessionLeaveMessage ==
    { ZeroSubsessionLeaveMessage }
        \cup { [ZeroSubsessionLeaveMessage EXCEPT !.subsessionId = one] : one \in Sample(8) }

(***************************************************************************)
(* Subsession Leave Response Message: 9 bytes                              *)
(***************************************************************************)

SubsessionLeaveResponseMessage ==
    [ subsessionId : Sample(8),
      reason       : Sample(1) ]

EncodeSubsessionLeaveResponseMessage(message) ==
    message.subsessionId
        \o message.reason

DecodeSubsessionLeaveResponseMessage(bytes) ==
    LET subsessionId == ReadBytes(bytes, 8) IN IF ~subsessionId.ok THEN Fail ELSE
    LET reason == ReadBytes(subsessionId.rest, 1) IN IF ~reason.ok THEN Fail ELSE
    Ok([ subsessionId |-> subsessionId.value,
         reason       |-> reason.value ], reason.rest)

ZeroSubsessionLeaveResponseMessage ==
    [ subsessionId |-> [i \in 1 .. 8 |-> 0],
      reason       |-> [i \in 1 .. 1 |-> 0] ]

(* Subsession Leave Response Message at zero, then each field in turn at the values it is checked at *)
CheckedSubsessionLeaveResponseMessage ==
    { ZeroSubsessionLeaveResponseMessage }
        \cup { [ZeroSubsessionLeaveResponseMessage EXCEPT !.subsessionId = one] : one \in Sample(8) }
        \cup { [ZeroSubsessionLeaveResponseMessage EXCEPT !.reason = one] : one \in Sample(1) }

(***************************************************************************)
(* New Order Single Message: 92 bytes                                      *)
(***************************************************************************)

NewOrderSingleMessage ==
    [ accountAccountOptional       : Sample(16),
      instrumentId                 : Sample(4),
      marketParticipantIdOptional  : Sample(4),
      clOrdId                      : Sample(8),
      clearingAccountOptional      : Sample(4),
      customerOrFirm               : Sample(1),
      openClose                    : Sample(1),
      attributedQuoteOptional      : Sample(1),
      timeInForce                  : Sample(1),
      cancelInsteadOfSlideOptional : Sample(1),
      displayInst                  : Sample(1),
      execInst                     : Sample(1),
      ordType                      : Sample(1),
      targetPartyId                : Sample(4),
      auctionId                    : Sample(4),
      clearingFirm                 : Sample(4),
      optionalData                 : Sample(16),
      routingFirmId                : Sample(4),
      aiq                          : Sample(3),
      side                         : Sample(1),
      pricePrice8Optional          : Sample(8),
      orderQtyQuantityNonZero      : Sample(4) ]

EncodeNewOrderSingleMessage(message) ==
    message.accountAccountOptional
        \o message.instrumentId
        \o message.marketParticipantIdOptional
        \o message.clOrdId
        \o message.clearingAccountOptional
        \o message.customerOrFirm
        \o message.openClose
        \o message.attributedQuoteOptional
        \o message.timeInForce
        \o message.cancelInsteadOfSlideOptional
        \o message.displayInst
        \o message.execInst
        \o message.ordType
        \o message.targetPartyId
        \o message.auctionId
        \o message.clearingFirm
        \o message.optionalData
        \o message.routingFirmId
        \o message.aiq
        \o message.side
        \o message.pricePrice8Optional
        \o message.orderQtyQuantityNonZero

DecodeNewOrderSingleMessage(bytes) ==
    LET accountAccountOptional == ReadBytes(bytes, 16) IN IF ~accountAccountOptional.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(accountAccountOptional.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET marketParticipantIdOptional == ReadBytes(instrumentId.rest, 4) IN IF ~marketParticipantIdOptional.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(marketParticipantIdOptional.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET clearingAccountOptional == ReadBytes(clOrdId.rest, 4) IN IF ~clearingAccountOptional.ok THEN Fail ELSE
    LET customerOrFirm == ReadBytes(clearingAccountOptional.rest, 1) IN IF ~customerOrFirm.ok THEN Fail ELSE
    LET openClose == ReadBytes(customerOrFirm.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET attributedQuoteOptional == ReadBytes(openClose.rest, 1) IN IF ~attributedQuoteOptional.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(attributedQuoteOptional.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET cancelInsteadOfSlideOptional == ReadBytes(timeInForce.rest, 1) IN IF ~cancelInsteadOfSlideOptional.ok THEN Fail ELSE
    LET displayInst == ReadBytes(cancelInsteadOfSlideOptional.rest, 1) IN IF ~displayInst.ok THEN Fail ELSE
    LET execInst == ReadBytes(displayInst.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET ordType == ReadBytes(execInst.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET targetPartyId == ReadBytes(ordType.rest, 4) IN IF ~targetPartyId.ok THEN Fail ELSE
    LET auctionId == ReadBytes(targetPartyId.rest, 4) IN IF ~auctionId.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(auctionId.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET optionalData == ReadBytes(clearingFirm.rest, 16) IN IF ~optionalData.ok THEN Fail ELSE
    LET routingFirmId == ReadBytes(optionalData.rest, 4) IN IF ~routingFirmId.ok THEN Fail ELSE
    LET aiq == ReadBytes(routingFirmId.rest, 3) IN IF ~aiq.ok THEN Fail ELSE
    LET side == ReadBytes(aiq.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET pricePrice8Optional == ReadBytes(side.rest, 8) IN IF ~pricePrice8Optional.ok THEN Fail ELSE
    LET orderQtyQuantityNonZero == ReadBytes(pricePrice8Optional.rest, 4) IN IF ~orderQtyQuantityNonZero.ok THEN Fail ELSE
    Ok([ accountAccountOptional       |-> accountAccountOptional.value,
         instrumentId                 |-> instrumentId.value,
         marketParticipantIdOptional  |-> marketParticipantIdOptional.value,
         clOrdId                      |-> clOrdId.value,
         clearingAccountOptional      |-> clearingAccountOptional.value,
         customerOrFirm               |-> customerOrFirm.value,
         openClose                    |-> openClose.value,
         attributedQuoteOptional      |-> attributedQuoteOptional.value,
         timeInForce                  |-> timeInForce.value,
         cancelInsteadOfSlideOptional |-> cancelInsteadOfSlideOptional.value,
         displayInst                  |-> displayInst.value,
         execInst                     |-> execInst.value,
         ordType                      |-> ordType.value,
         targetPartyId                |-> targetPartyId.value,
         auctionId                    |-> auctionId.value,
         clearingFirm                 |-> clearingFirm.value,
         optionalData                 |-> optionalData.value,
         routingFirmId                |-> routingFirmId.value,
         aiq                          |-> aiq.value,
         side                         |-> side.value,
         pricePrice8Optional          |-> pricePrice8Optional.value,
         orderQtyQuantityNonZero      |-> orderQtyQuantityNonZero.value ], orderQtyQuantityNonZero.rest)

ZeroNewOrderSingleMessage ==
    [ accountAccountOptional       |-> [i \in 1 .. 16 |-> 0],
      instrumentId                 |-> [i \in 1 .. 4 |-> 0],
      marketParticipantIdOptional  |-> [i \in 1 .. 4 |-> 0],
      clOrdId                      |-> [i \in 1 .. 8 |-> 0],
      clearingAccountOptional      |-> [i \in 1 .. 4 |-> 0],
      customerOrFirm               |-> [i \in 1 .. 1 |-> 0],
      openClose                    |-> [i \in 1 .. 1 |-> 0],
      attributedQuoteOptional      |-> [i \in 1 .. 1 |-> 0],
      timeInForce                  |-> [i \in 1 .. 1 |-> 0],
      cancelInsteadOfSlideOptional |-> [i \in 1 .. 1 |-> 0],
      displayInst                  |-> [i \in 1 .. 1 |-> 0],
      execInst                     |-> [i \in 1 .. 1 |-> 0],
      ordType                      |-> [i \in 1 .. 1 |-> 0],
      targetPartyId                |-> [i \in 1 .. 4 |-> 0],
      auctionId                    |-> [i \in 1 .. 4 |-> 0],
      clearingFirm                 |-> [i \in 1 .. 4 |-> 0],
      optionalData                 |-> [i \in 1 .. 16 |-> 0],
      routingFirmId                |-> [i \in 1 .. 4 |-> 0],
      aiq                          |-> [i \in 1 .. 3 |-> 0],
      side                         |-> [i \in 1 .. 1 |-> 0],
      pricePrice8Optional          |-> [i \in 1 .. 8 |-> 0],
      orderQtyQuantityNonZero      |-> [i \in 1 .. 4 |-> 0] ]

(* New Order Single Message at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderSingleMessage ==
    { ZeroNewOrderSingleMessage }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.accountAccountOptional = one] : one \in Sample(16) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.marketParticipantIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.clearingAccountOptional = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.customerOrFirm = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.attributedQuoteOptional = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.cancelInsteadOfSlideOptional = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.displayInst = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.targetPartyId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.auctionId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.optionalData = one] : one \in Sample(16) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.routingFirmId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.aiq = one] : one \in Sample(3) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.pricePrice8Optional = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.orderQtyQuantityNonZero = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Cancel Replace Request Message: 100 bytes                         *)
(***************************************************************************)

OrderCancelReplaceRequestMessage ==
    [ accountAccountOptional       : Sample(16),
      instrumentId                 : Sample(4),
      marketParticipantIdOptional  : Sample(4),
      clOrdId                      : Sample(8),
      clearingAccountOptional      : Sample(4),
      origClOrdId                  : Sample(8),
      customerOrFirmOptional       : Sample(1),
      openCloseOptional            : Sample(1),
      attributedQuoteOptional      : Sample(1),
      timeInForceOptional          : Sample(1),
      cancelInsteadOfSlideOptional : Sample(1),
      displayInst                  : Sample(1),
      execInst                     : Sample(1),
      ordTypeOptional              : Sample(1),
      targetPartyId                : Sample(4),
      auctionId                    : Sample(4),
      clearingFirm                 : Sample(4),
      optionalData                 : Sample(16),
      routingFirmId                : Sample(4),
      aiq                          : Sample(3),
      sideOptional                 : Sample(1),
      pricePrice8Optional          : Sample(8),
      orderQtyQuantityNonZero      : Sample(4) ]

EncodeOrderCancelReplaceRequestMessage(message) ==
    message.accountAccountOptional
        \o message.instrumentId
        \o message.marketParticipantIdOptional
        \o message.clOrdId
        \o message.clearingAccountOptional
        \o message.origClOrdId
        \o message.customerOrFirmOptional
        \o message.openCloseOptional
        \o message.attributedQuoteOptional
        \o message.timeInForceOptional
        \o message.cancelInsteadOfSlideOptional
        \o message.displayInst
        \o message.execInst
        \o message.ordTypeOptional
        \o message.targetPartyId
        \o message.auctionId
        \o message.clearingFirm
        \o message.optionalData
        \o message.routingFirmId
        \o message.aiq
        \o message.sideOptional
        \o message.pricePrice8Optional
        \o message.orderQtyQuantityNonZero

DecodeOrderCancelReplaceRequestMessage(bytes) ==
    LET accountAccountOptional == ReadBytes(bytes, 16) IN IF ~accountAccountOptional.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(accountAccountOptional.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET marketParticipantIdOptional == ReadBytes(instrumentId.rest, 4) IN IF ~marketParticipantIdOptional.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(marketParticipantIdOptional.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET clearingAccountOptional == ReadBytes(clOrdId.rest, 4) IN IF ~clearingAccountOptional.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clearingAccountOptional.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET customerOrFirmOptional == ReadBytes(origClOrdId.rest, 1) IN IF ~customerOrFirmOptional.ok THEN Fail ELSE
    LET openCloseOptional == ReadBytes(customerOrFirmOptional.rest, 1) IN IF ~openCloseOptional.ok THEN Fail ELSE
    LET attributedQuoteOptional == ReadBytes(openCloseOptional.rest, 1) IN IF ~attributedQuoteOptional.ok THEN Fail ELSE
    LET timeInForceOptional == ReadBytes(attributedQuoteOptional.rest, 1) IN IF ~timeInForceOptional.ok THEN Fail ELSE
    LET cancelInsteadOfSlideOptional == ReadBytes(timeInForceOptional.rest, 1) IN IF ~cancelInsteadOfSlideOptional.ok THEN Fail ELSE
    LET displayInst == ReadBytes(cancelInsteadOfSlideOptional.rest, 1) IN IF ~displayInst.ok THEN Fail ELSE
    LET execInst == ReadBytes(displayInst.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET ordTypeOptional == ReadBytes(execInst.rest, 1) IN IF ~ordTypeOptional.ok THEN Fail ELSE
    LET targetPartyId == ReadBytes(ordTypeOptional.rest, 4) IN IF ~targetPartyId.ok THEN Fail ELSE
    LET auctionId == ReadBytes(targetPartyId.rest, 4) IN IF ~auctionId.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(auctionId.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET optionalData == ReadBytes(clearingFirm.rest, 16) IN IF ~optionalData.ok THEN Fail ELSE
    LET routingFirmId == ReadBytes(optionalData.rest, 4) IN IF ~routingFirmId.ok THEN Fail ELSE
    LET aiq == ReadBytes(routingFirmId.rest, 3) IN IF ~aiq.ok THEN Fail ELSE
    LET sideOptional == ReadBytes(aiq.rest, 1) IN IF ~sideOptional.ok THEN Fail ELSE
    LET pricePrice8Optional == ReadBytes(sideOptional.rest, 8) IN IF ~pricePrice8Optional.ok THEN Fail ELSE
    LET orderQtyQuantityNonZero == ReadBytes(pricePrice8Optional.rest, 4) IN IF ~orderQtyQuantityNonZero.ok THEN Fail ELSE
    Ok([ accountAccountOptional       |-> accountAccountOptional.value,
         instrumentId                 |-> instrumentId.value,
         marketParticipantIdOptional  |-> marketParticipantIdOptional.value,
         clOrdId                      |-> clOrdId.value,
         clearingAccountOptional      |-> clearingAccountOptional.value,
         origClOrdId                  |-> origClOrdId.value,
         customerOrFirmOptional       |-> customerOrFirmOptional.value,
         openCloseOptional            |-> openCloseOptional.value,
         attributedQuoteOptional      |-> attributedQuoteOptional.value,
         timeInForceOptional          |-> timeInForceOptional.value,
         cancelInsteadOfSlideOptional |-> cancelInsteadOfSlideOptional.value,
         displayInst                  |-> displayInst.value,
         execInst                     |-> execInst.value,
         ordTypeOptional              |-> ordTypeOptional.value,
         targetPartyId                |-> targetPartyId.value,
         auctionId                    |-> auctionId.value,
         clearingFirm                 |-> clearingFirm.value,
         optionalData                 |-> optionalData.value,
         routingFirmId                |-> routingFirmId.value,
         aiq                          |-> aiq.value,
         sideOptional                 |-> sideOptional.value,
         pricePrice8Optional          |-> pricePrice8Optional.value,
         orderQtyQuantityNonZero      |-> orderQtyQuantityNonZero.value ], orderQtyQuantityNonZero.rest)

ZeroOrderCancelReplaceRequestMessage ==
    [ accountAccountOptional       |-> [i \in 1 .. 16 |-> 0],
      instrumentId                 |-> [i \in 1 .. 4 |-> 0],
      marketParticipantIdOptional  |-> [i \in 1 .. 4 |-> 0],
      clOrdId                      |-> [i \in 1 .. 8 |-> 0],
      clearingAccountOptional      |-> [i \in 1 .. 4 |-> 0],
      origClOrdId                  |-> [i \in 1 .. 8 |-> 0],
      customerOrFirmOptional       |-> [i \in 1 .. 1 |-> 0],
      openCloseOptional            |-> [i \in 1 .. 1 |-> 0],
      attributedQuoteOptional      |-> [i \in 1 .. 1 |-> 0],
      timeInForceOptional          |-> [i \in 1 .. 1 |-> 0],
      cancelInsteadOfSlideOptional |-> [i \in 1 .. 1 |-> 0],
      displayInst                  |-> [i \in 1 .. 1 |-> 0],
      execInst                     |-> [i \in 1 .. 1 |-> 0],
      ordTypeOptional              |-> [i \in 1 .. 1 |-> 0],
      targetPartyId                |-> [i \in 1 .. 4 |-> 0],
      auctionId                    |-> [i \in 1 .. 4 |-> 0],
      clearingFirm                 |-> [i \in 1 .. 4 |-> 0],
      optionalData                 |-> [i \in 1 .. 16 |-> 0],
      routingFirmId                |-> [i \in 1 .. 4 |-> 0],
      aiq                          |-> [i \in 1 .. 3 |-> 0],
      sideOptional                 |-> [i \in 1 .. 1 |-> 0],
      pricePrice8Optional          |-> [i \in 1 .. 8 |-> 0],
      orderQtyQuantityNonZero      |-> [i \in 1 .. 4 |-> 0] ]

(* Order Cancel Replace Request Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelReplaceRequestMessage ==
    { ZeroOrderCancelReplaceRequestMessage }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.accountAccountOptional = one] : one \in Sample(16) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.marketParticipantIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.clearingAccountOptional = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.customerOrFirmOptional = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.openCloseOptional = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.attributedQuoteOptional = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.timeInForceOptional = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.cancelInsteadOfSlideOptional = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.displayInst = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.ordTypeOptional = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.targetPartyId = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.auctionId = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.optionalData = one] : one \in Sample(16) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.routingFirmId = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.aiq = one] : one \in Sample(3) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.sideOptional = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.pricePrice8Optional = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.orderQtyQuantityNonZero = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Cancel Request Message: 24 bytes                                  *)
(***************************************************************************)

OrderCancelRequestMessage ==
    [ instrumentId                : Sample(4),
      marketParticipantIdOptional : Sample(4),
      clOrdId                     : Sample(8),
      origClOrdId                 : Sample(8) ]

EncodeOrderCancelRequestMessage(message) ==
    message.instrumentId
        \o message.marketParticipantIdOptional
        \o message.clOrdId
        \o message.origClOrdId

DecodeOrderCancelRequestMessage(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET marketParticipantIdOptional == ReadBytes(instrumentId.rest, 4) IN IF ~marketParticipantIdOptional.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(marketParticipantIdOptional.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    Ok([ instrumentId                |-> instrumentId.value,
         marketParticipantIdOptional |-> marketParticipantIdOptional.value,
         clOrdId                     |-> clOrdId.value,
         origClOrdId                 |-> origClOrdId.value ], origClOrdId.rest)

ZeroOrderCancelRequestMessage ==
    [ instrumentId                |-> [i \in 1 .. 4 |-> 0],
      marketParticipantIdOptional |-> [i \in 1 .. 4 |-> 0],
      clOrdId                     |-> [i \in 1 .. 8 |-> 0],
      origClOrdId                 |-> [i \in 1 .. 8 |-> 0] ]

(* Order Cancel Request Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelRequestMessage ==
    { ZeroOrderCancelRequestMessage }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.marketParticipantIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.origClOrdId = one] : one \in Sample(8) }

(***************************************************************************)
(* New Bulk Quote Message quote Updates Group: 15 bytes                    *)
(***************************************************************************)

NewBulkQuoteMessageQuoteUpdatesGroup ==
    [ instrumentId                 : Sample(4),
      side                         : Sample(1),
      pricePrice4Optional          : Sample(4),
      orderQtyQuantityZeroOptional : Sample(4),
      quoteType                    : Sample(1),
      reserved                     : Sample(1) ]

EncodeNewBulkQuoteMessageQuoteUpdatesGroup(message) ==
    message.instrumentId
        \o message.side
        \o message.pricePrice4Optional
        \o message.orderQtyQuantityZeroOptional
        \o message.quoteType
        \o message.reserved

DecodeNewBulkQuoteMessageQuoteUpdatesGroup(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET side == ReadBytes(instrumentId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET pricePrice4Optional == ReadBytes(side.rest, 4) IN IF ~pricePrice4Optional.ok THEN Fail ELSE
    LET orderQtyQuantityZeroOptional == ReadBytes(pricePrice4Optional.rest, 4) IN IF ~orderQtyQuantityZeroOptional.ok THEN Fail ELSE
    LET quoteType == ReadBytes(orderQtyQuantityZeroOptional.rest, 1) IN IF ~quoteType.ok THEN Fail ELSE
    LET reserved == ReadBytes(quoteType.rest, 1) IN IF ~reserved.ok THEN Fail ELSE
    Ok([ instrumentId                 |-> instrumentId.value,
         side                         |-> side.value,
         pricePrice4Optional          |-> pricePrice4Optional.value,
         orderQtyQuantityZeroOptional |-> orderQtyQuantityZeroOptional.value,
         quoteType                    |-> quoteType.value,
         reserved                     |-> reserved.value ], reserved.rest)

ZeroNewBulkQuoteMessageQuoteUpdatesGroup ==
    [ instrumentId                 |-> [i \in 1 .. 4 |-> 0],
      side                         |-> [i \in 1 .. 1 |-> 0],
      pricePrice4Optional          |-> [i \in 1 .. 4 |-> 0],
      orderQtyQuantityZeroOptional |-> [i \in 1 .. 4 |-> 0],
      quoteType                    |-> [i \in 1 .. 1 |-> 0],
      reserved                     |-> [i \in 1 .. 1 |-> 0] ]

(* New Bulk Quote Message quote Updates Group at zero, then each field in turn at the values it is checked at *)
CheckedNewBulkQuoteMessageQuoteUpdatesGroup ==
    { ZeroNewBulkQuoteMessageQuoteUpdatesGroup }
        \cup { [ZeroNewBulkQuoteMessageQuoteUpdatesGroup EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroNewBulkQuoteMessageQuoteUpdatesGroup EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewBulkQuoteMessageQuoteUpdatesGroup EXCEPT !.pricePrice4Optional = one] : one \in Sample(4) }
        \cup { [ZeroNewBulkQuoteMessageQuoteUpdatesGroup EXCEPT !.orderQtyQuantityZeroOptional = one] : one \in Sample(4) }
        \cup { [ZeroNewBulkQuoteMessageQuoteUpdatesGroup EXCEPT !.quoteType = one] : one \in Sample(1) }
        \cup { [ZeroNewBulkQuoteMessageQuoteUpdatesGroup EXCEPT !.reserved = one] : one \in Sample(1) }

(* A run of New Bulk Quote Message quote Updates Group, written one after another *)
RECURSIVE EncodeNewBulkQuoteMessageQuoteUpdatesGroupList(_)
EncodeNewBulkQuoteMessageQuoteUpdatesGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeNewBulkQuoteMessageQuoteUpdatesGroup(Head(messages)) \o EncodeNewBulkQuoteMessageQuoteUpdatesGroupList(Tail(messages))

(* As many New Bulk Quote Message quote Updates Group as the field that counts them says *)
RECURSIVE ReadNewBulkQuoteMessageQuoteUpdatesGroupList(_, _)
ReadNewBulkQuoteMessageQuoteUpdatesGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeNewBulkQuoteMessageQuoteUpdatesGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadNewBulkQuoteMessageQuoteUpdatesGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One New Bulk Quote Message quote Updates Group of each kind, for the lists that carry them *)
OneNewBulkQuoteMessageQuoteUpdatesGroup == { ZeroNewBulkQuoteMessageQuoteUpdatesGroup }

(***************************************************************************)
(* New Bulk Quote Message quote Updates Groups                             *)
(***************************************************************************)

NewBulkQuoteMessageQuoteUpdatesGroups ==
    [ blockLengthShort                     : Sample(1),
      newBulkQuoteMessageQuoteUpdatesGroup : SampleLists(OneNewBulkQuoteMessageQuoteUpdatesGroup) ]

EncodeNewBulkQuoteMessageQuoteUpdatesGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.newBulkQuoteMessageQuoteUpdatesGroup), 1)
        \o EncodeNewBulkQuoteMessageQuoteUpdatesGroupList(message.newBulkQuoteMessageQuoteUpdatesGroup)

DecodeNewBulkQuoteMessageQuoteUpdatesGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET newBulkQuoteMessageQuoteUpdatesGroup == ReadNewBulkQuoteMessageQuoteUpdatesGroupList(numInGroup.rest, numInGroup.value) IN IF ~newBulkQuoteMessageQuoteUpdatesGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort                     |-> blockLengthShort.value,
         newBulkQuoteMessageQuoteUpdatesGroup |-> newBulkQuoteMessageQuoteUpdatesGroup.value ], newBulkQuoteMessageQuoteUpdatesGroup.rest)

ZeroNewBulkQuoteMessageQuoteUpdatesGroups ==
    [ blockLengthShort                     |-> [i \in 1 .. 1 |-> 0],
      newBulkQuoteMessageQuoteUpdatesGroup |-> << >> ]

(* New Bulk Quote Message quote Updates Groups at zero, then each field in turn at the values it is checked at *)
CheckedNewBulkQuoteMessageQuoteUpdatesGroups ==
    { ZeroNewBulkQuoteMessageQuoteUpdatesGroups }
        \cup { [ZeroNewBulkQuoteMessageQuoteUpdatesGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroNewBulkQuoteMessageQuoteUpdatesGroups EXCEPT !.newBulkQuoteMessageQuoteUpdatesGroup = one] : one \in SampleLists(OneNewBulkQuoteMessageQuoteUpdatesGroup) }

(***************************************************************************)
(* New Bulk Quote Message                                                  *)
(***************************************************************************)

NewBulkQuoteMessage ==
    [ marketParticipantIdOptional           : Sample(4),
      customGroupIdOptional                 : Sample(2),
      clOrdId                               : Sample(8),
      clearingAccountOptional               : Sample(4),
      cancelInsteadOfSlideOptional          : Sample(1),
      sendTime                              : Sample(8),
      aiq                                   : Sample(3),
      timeInForce                           : Sample(1),
      newBulkQuoteMessageQuoteUpdatesGroups : NewBulkQuoteMessageQuoteUpdatesGroups ]

EncodeNewBulkQuoteMessage(message) ==
    message.marketParticipantIdOptional
        \o message.customGroupIdOptional
        \o message.clOrdId
        \o message.clearingAccountOptional
        \o message.cancelInsteadOfSlideOptional
        \o message.sendTime
        \o message.aiq
        \o message.timeInForce
        \o EncodeNewBulkQuoteMessageQuoteUpdatesGroups(message.newBulkQuoteMessageQuoteUpdatesGroups)

DecodeNewBulkQuoteMessage(bytes) ==
    LET marketParticipantIdOptional == ReadBytes(bytes, 4) IN IF ~marketParticipantIdOptional.ok THEN Fail ELSE
    LET customGroupIdOptional == ReadBytes(marketParticipantIdOptional.rest, 2) IN IF ~customGroupIdOptional.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(customGroupIdOptional.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET clearingAccountOptional == ReadBytes(clOrdId.rest, 4) IN IF ~clearingAccountOptional.ok THEN Fail ELSE
    LET cancelInsteadOfSlideOptional == ReadBytes(clearingAccountOptional.rest, 1) IN IF ~cancelInsteadOfSlideOptional.ok THEN Fail ELSE
    LET sendTime == ReadBytes(cancelInsteadOfSlideOptional.rest, 8) IN IF ~sendTime.ok THEN Fail ELSE
    LET aiq == ReadBytes(sendTime.rest, 3) IN IF ~aiq.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(aiq.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET newBulkQuoteMessageQuoteUpdatesGroups == DecodeNewBulkQuoteMessageQuoteUpdatesGroups(timeInForce.rest) IN IF ~newBulkQuoteMessageQuoteUpdatesGroups.ok THEN Fail ELSE
    Ok([ marketParticipantIdOptional           |-> marketParticipantIdOptional.value,
         customGroupIdOptional                 |-> customGroupIdOptional.value,
         clOrdId                               |-> clOrdId.value,
         clearingAccountOptional               |-> clearingAccountOptional.value,
         cancelInsteadOfSlideOptional          |-> cancelInsteadOfSlideOptional.value,
         sendTime                              |-> sendTime.value,
         aiq                                   |-> aiq.value,
         timeInForce                           |-> timeInForce.value,
         newBulkQuoteMessageQuoteUpdatesGroups |-> newBulkQuoteMessageQuoteUpdatesGroups.value ], newBulkQuoteMessageQuoteUpdatesGroups.rest)

ZeroNewBulkQuoteMessage ==
    [ marketParticipantIdOptional           |-> [i \in 1 .. 4 |-> 0],
      customGroupIdOptional                 |-> [i \in 1 .. 2 |-> 0],
      clOrdId                               |-> [i \in 1 .. 8 |-> 0],
      clearingAccountOptional               |-> [i \in 1 .. 4 |-> 0],
      cancelInsteadOfSlideOptional          |-> [i \in 1 .. 1 |-> 0],
      sendTime                              |-> [i \in 1 .. 8 |-> 0],
      aiq                                   |-> [i \in 1 .. 3 |-> 0],
      timeInForce                           |-> [i \in 1 .. 1 |-> 0],
      newBulkQuoteMessageQuoteUpdatesGroups |-> ZeroNewBulkQuoteMessageQuoteUpdatesGroups ]

(* New Bulk Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedNewBulkQuoteMessage ==
    { ZeroNewBulkQuoteMessage }
        \cup { [ZeroNewBulkQuoteMessage EXCEPT !.marketParticipantIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroNewBulkQuoteMessage EXCEPT !.customGroupIdOptional = one] : one \in Sample(2) }
        \cup { [ZeroNewBulkQuoteMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroNewBulkQuoteMessage EXCEPT !.clearingAccountOptional = one] : one \in Sample(4) }
        \cup { [ZeroNewBulkQuoteMessage EXCEPT !.cancelInsteadOfSlideOptional = one] : one \in Sample(1) }
        \cup { [ZeroNewBulkQuoteMessage EXCEPT !.sendTime = one] : one \in Sample(8) }
        \cup { [ZeroNewBulkQuoteMessage EXCEPT !.aiq = one] : one \in Sample(3) }
        \cup { [ZeroNewBulkQuoteMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroNewBulkQuoteMessage EXCEPT !.newBulkQuoteMessageQuoteUpdatesGroups = one] : one \in CheckedNewBulkQuoteMessageQuoteUpdatesGroups }

(***************************************************************************)
(* Mass Cancel Request Message: 27 bytes                                   *)
(***************************************************************************)

MassCancelRequestMessage ==
    [ underlyingIdOptional        : Sample(4),
      marketParticipantIdOptional : Sample(4),
      clOrdId                     : Sample(8),
      sendTime                    : Sample(8),
      ackStyleMassCancelAckStyle  : Sample(1),
      mpidFilter                  : Sample(1),
      bulkAction                  : Sample(1) ]

EncodeMassCancelRequestMessage(message) ==
    message.underlyingIdOptional
        \o message.marketParticipantIdOptional
        \o message.clOrdId
        \o message.sendTime
        \o message.ackStyleMassCancelAckStyle
        \o message.mpidFilter
        \o message.bulkAction

DecodeMassCancelRequestMessage(bytes) ==
    LET underlyingIdOptional == ReadBytes(bytes, 4) IN IF ~underlyingIdOptional.ok THEN Fail ELSE
    LET marketParticipantIdOptional == ReadBytes(underlyingIdOptional.rest, 4) IN IF ~marketParticipantIdOptional.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(marketParticipantIdOptional.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET sendTime == ReadBytes(clOrdId.rest, 8) IN IF ~sendTime.ok THEN Fail ELSE
    LET ackStyleMassCancelAckStyle == ReadBytes(sendTime.rest, 1) IN IF ~ackStyleMassCancelAckStyle.ok THEN Fail ELSE
    LET mpidFilter == ReadBytes(ackStyleMassCancelAckStyle.rest, 1) IN IF ~mpidFilter.ok THEN Fail ELSE
    LET bulkAction == ReadBytes(mpidFilter.rest, 1) IN IF ~bulkAction.ok THEN Fail ELSE
    Ok([ underlyingIdOptional        |-> underlyingIdOptional.value,
         marketParticipantIdOptional |-> marketParticipantIdOptional.value,
         clOrdId                     |-> clOrdId.value,
         sendTime                    |-> sendTime.value,
         ackStyleMassCancelAckStyle  |-> ackStyleMassCancelAckStyle.value,
         mpidFilter                  |-> mpidFilter.value,
         bulkAction                  |-> bulkAction.value ], bulkAction.rest)

ZeroMassCancelRequestMessage ==
    [ underlyingIdOptional        |-> [i \in 1 .. 4 |-> 0],
      marketParticipantIdOptional |-> [i \in 1 .. 4 |-> 0],
      clOrdId                     |-> [i \in 1 .. 8 |-> 0],
      sendTime                    |-> [i \in 1 .. 8 |-> 0],
      ackStyleMassCancelAckStyle  |-> [i \in 1 .. 1 |-> 0],
      mpidFilter                  |-> [i \in 1 .. 1 |-> 0],
      bulkAction                  |-> [i \in 1 .. 1 |-> 0] ]

(* Mass Cancel Request Message at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelRequestMessage ==
    { ZeroMassCancelRequestMessage }
        \cup { [ZeroMassCancelRequestMessage EXCEPT !.underlyingIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroMassCancelRequestMessage EXCEPT !.marketParticipantIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroMassCancelRequestMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelRequestMessage EXCEPT !.sendTime = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelRequestMessage EXCEPT !.ackStyleMassCancelAckStyle = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelRequestMessage EXCEPT !.mpidFilter = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelRequestMessage EXCEPT !.bulkAction = one] : one \in Sample(1) }

(***************************************************************************)
(* Purge Request Message custom Group Ids Group: 2 bytes                   *)
(***************************************************************************)

PurgeRequestMessageCustomGroupIdsGroup ==
    [ customGroupId : Sample(2) ]

EncodePurgeRequestMessageCustomGroupIdsGroup(message) ==
    message.customGroupId

DecodePurgeRequestMessageCustomGroupIdsGroup(bytes) ==
    LET customGroupId == ReadBytes(bytes, 2) IN IF ~customGroupId.ok THEN Fail ELSE
    Ok([ customGroupId |-> customGroupId.value ], customGroupId.rest)

ZeroPurgeRequestMessageCustomGroupIdsGroup ==
    [ customGroupId |-> [i \in 1 .. 2 |-> 0] ]

(* Purge Request Message custom Group Ids Group at zero, then each field in turn at the values it is checked at *)
CheckedPurgeRequestMessageCustomGroupIdsGroup ==
    { ZeroPurgeRequestMessageCustomGroupIdsGroup }
        \cup { [ZeroPurgeRequestMessageCustomGroupIdsGroup EXCEPT !.customGroupId = one] : one \in Sample(2) }

(* A run of Purge Request Message custom Group Ids Group, written one after another *)
RECURSIVE EncodePurgeRequestMessageCustomGroupIdsGroupList(_)
EncodePurgeRequestMessageCustomGroupIdsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodePurgeRequestMessageCustomGroupIdsGroup(Head(messages)) \o EncodePurgeRequestMessageCustomGroupIdsGroupList(Tail(messages))

(* As many Purge Request Message custom Group Ids Group as the field that counts them says *)
RECURSIVE ReadPurgeRequestMessageCustomGroupIdsGroupList(_, _)
ReadPurgeRequestMessageCustomGroupIdsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodePurgeRequestMessageCustomGroupIdsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadPurgeRequestMessageCustomGroupIdsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Purge Request Message custom Group Ids Group of each kind, for the lists that carry them *)
OnePurgeRequestMessageCustomGroupIdsGroup == { ZeroPurgeRequestMessageCustomGroupIdsGroup }

(***************************************************************************)
(* Purge Request Message custom Group Ids Groups                           *)
(***************************************************************************)

PurgeRequestMessageCustomGroupIdsGroups ==
    [ blockLengthShort                       : Sample(1),
      purgeRequestMessageCustomGroupIdsGroup : SampleLists(OnePurgeRequestMessageCustomGroupIdsGroup) ]

EncodePurgeRequestMessageCustomGroupIdsGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.purgeRequestMessageCustomGroupIdsGroup), 1)
        \o EncodePurgeRequestMessageCustomGroupIdsGroupList(message.purgeRequestMessageCustomGroupIdsGroup)

DecodePurgeRequestMessageCustomGroupIdsGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET purgeRequestMessageCustomGroupIdsGroup == ReadPurgeRequestMessageCustomGroupIdsGroupList(numInGroup.rest, numInGroup.value) IN IF ~purgeRequestMessageCustomGroupIdsGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort                       |-> blockLengthShort.value,
         purgeRequestMessageCustomGroupIdsGroup |-> purgeRequestMessageCustomGroupIdsGroup.value ], purgeRequestMessageCustomGroupIdsGroup.rest)

ZeroPurgeRequestMessageCustomGroupIdsGroups ==
    [ blockLengthShort                       |-> [i \in 1 .. 1 |-> 0],
      purgeRequestMessageCustomGroupIdsGroup |-> << >> ]

(* Purge Request Message custom Group Ids Groups at zero, then each field in turn at the values it is checked at *)
CheckedPurgeRequestMessageCustomGroupIdsGroups ==
    { ZeroPurgeRequestMessageCustomGroupIdsGroups }
        \cup { [ZeroPurgeRequestMessageCustomGroupIdsGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroPurgeRequestMessageCustomGroupIdsGroups EXCEPT !.purgeRequestMessageCustomGroupIdsGroup = one] : one \in SampleLists(OnePurgeRequestMessageCustomGroupIdsGroup) }

(***************************************************************************)
(* Purge Request Message                                                   *)
(***************************************************************************)

PurgeRequestMessage ==
    [ underlyingIdOptional                    : Sample(4),
      marketParticipantIdOptional             : Sample(4),
      clOrdId                                 : Sample(8),
      sendTime                                : Sample(8),
      ackStylePurgeRequestAckStyle            : Sample(1),
      bulkAction                              : Sample(1),
      purgeRequestMessageCustomGroupIdsGroups : PurgeRequestMessageCustomGroupIdsGroups ]

EncodePurgeRequestMessage(message) ==
    message.underlyingIdOptional
        \o message.marketParticipantIdOptional
        \o message.clOrdId
        \o message.sendTime
        \o message.ackStylePurgeRequestAckStyle
        \o message.bulkAction
        \o EncodePurgeRequestMessageCustomGroupIdsGroups(message.purgeRequestMessageCustomGroupIdsGroups)

DecodePurgeRequestMessage(bytes) ==
    LET underlyingIdOptional == ReadBytes(bytes, 4) IN IF ~underlyingIdOptional.ok THEN Fail ELSE
    LET marketParticipantIdOptional == ReadBytes(underlyingIdOptional.rest, 4) IN IF ~marketParticipantIdOptional.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(marketParticipantIdOptional.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET sendTime == ReadBytes(clOrdId.rest, 8) IN IF ~sendTime.ok THEN Fail ELSE
    LET ackStylePurgeRequestAckStyle == ReadBytes(sendTime.rest, 1) IN IF ~ackStylePurgeRequestAckStyle.ok THEN Fail ELSE
    LET bulkAction == ReadBytes(ackStylePurgeRequestAckStyle.rest, 1) IN IF ~bulkAction.ok THEN Fail ELSE
    LET purgeRequestMessageCustomGroupIdsGroups == DecodePurgeRequestMessageCustomGroupIdsGroups(bulkAction.rest) IN IF ~purgeRequestMessageCustomGroupIdsGroups.ok THEN Fail ELSE
    Ok([ underlyingIdOptional                    |-> underlyingIdOptional.value,
         marketParticipantIdOptional             |-> marketParticipantIdOptional.value,
         clOrdId                                 |-> clOrdId.value,
         sendTime                                |-> sendTime.value,
         ackStylePurgeRequestAckStyle            |-> ackStylePurgeRequestAckStyle.value,
         bulkAction                              |-> bulkAction.value,
         purgeRequestMessageCustomGroupIdsGroups |-> purgeRequestMessageCustomGroupIdsGroups.value ], purgeRequestMessageCustomGroupIdsGroups.rest)

ZeroPurgeRequestMessage ==
    [ underlyingIdOptional                    |-> [i \in 1 .. 4 |-> 0],
      marketParticipantIdOptional             |-> [i \in 1 .. 4 |-> 0],
      clOrdId                                 |-> [i \in 1 .. 8 |-> 0],
      sendTime                                |-> [i \in 1 .. 8 |-> 0],
      ackStylePurgeRequestAckStyle            |-> [i \in 1 .. 1 |-> 0],
      bulkAction                              |-> [i \in 1 .. 1 |-> 0],
      purgeRequestMessageCustomGroupIdsGroups |-> ZeroPurgeRequestMessageCustomGroupIdsGroups ]

(* Purge Request Message at zero, then each field in turn at the values it is checked at *)
CheckedPurgeRequestMessage ==
    { ZeroPurgeRequestMessage }
        \cup { [ZeroPurgeRequestMessage EXCEPT !.underlyingIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroPurgeRequestMessage EXCEPT !.marketParticipantIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroPurgeRequestMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroPurgeRequestMessage EXCEPT !.sendTime = one] : one \in Sample(8) }
        \cup { [ZeroPurgeRequestMessage EXCEPT !.ackStylePurgeRequestAckStyle = one] : one \in Sample(1) }
        \cup { [ZeroPurgeRequestMessage EXCEPT !.bulkAction = one] : one \in Sample(1) }
        \cup { [ZeroPurgeRequestMessage EXCEPT !.purgeRequestMessageCustomGroupIdsGroups = one] : one \in CheckedPurgeRequestMessageCustomGroupIdsGroups }

(***************************************************************************)
(* Order Ack Message: 139 bytes                                            *)
(***************************************************************************)

OrderAckMessage ==
    [ accountAccountOptional  : Sample(16),
      transactTime            : Sample(8),
      instrumentId            : Sample(4),
      marketParticipantId     : Sample(4),
      clOrdId                 : Sample(8),
      clearingAccountOptional : Sample(4),
      origClOrdIdOptional     : Sample(8),
      orderId                 : Sample(8),
      customerOrFirm          : Sample(1),
      openClose               : Sample(1),
      attributedQuote         : Sample(1),
      timeInForce             : Sample(1),
      cancelInsteadOfSlide    : Sample(1),
      displayInst             : Sample(1),
      execInst                : Sample(1),
      ordType                 : Sample(1),
      targetPartyId           : Sample(4),
      auctionId               : Sample(4),
      clearingFirm            : Sample(4),
      optionalData            : Sample(16),
      routingFirmId           : Sample(4),
      aiq                     : Sample(3),
      side                    : Sample(1),
      pricePrice8Optional     : Sample(8),
      orderQtyQuantityNonZero : Sample(4),
      leavesQty               : Sample(4),
      effectiveLimitPrice     : Sample(8),
      displayPrice            : Sample(8),
      reasonCodeOptional      : Sample(1),
      ackType                 : Sample(1),
      throttleIndicator       : Sample(1) ]

EncodeOrderAckMessage(message) ==
    message.accountAccountOptional
        \o message.transactTime
        \o message.instrumentId
        \o message.marketParticipantId
        \o message.clOrdId
        \o message.clearingAccountOptional
        \o message.origClOrdIdOptional
        \o message.orderId
        \o message.customerOrFirm
        \o message.openClose
        \o message.attributedQuote
        \o message.timeInForce
        \o message.cancelInsteadOfSlide
        \o message.displayInst
        \o message.execInst
        \o message.ordType
        \o message.targetPartyId
        \o message.auctionId
        \o message.clearingFirm
        \o message.optionalData
        \o message.routingFirmId
        \o message.aiq
        \o message.side
        \o message.pricePrice8Optional
        \o message.orderQtyQuantityNonZero
        \o message.leavesQty
        \o message.effectiveLimitPrice
        \o message.displayPrice
        \o message.reasonCodeOptional
        \o message.ackType
        \o message.throttleIndicator

DecodeOrderAckMessage(bytes) ==
    LET accountAccountOptional == ReadBytes(bytes, 16) IN IF ~accountAccountOptional.ok THEN Fail ELSE
    LET transactTime == ReadBytes(accountAccountOptional.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(transactTime.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET marketParticipantId == ReadBytes(instrumentId.rest, 4) IN IF ~marketParticipantId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(marketParticipantId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET clearingAccountOptional == ReadBytes(clOrdId.rest, 4) IN IF ~clearingAccountOptional.ok THEN Fail ELSE
    LET origClOrdIdOptional == ReadBytes(clearingAccountOptional.rest, 8) IN IF ~origClOrdIdOptional.ok THEN Fail ELSE
    LET orderId == ReadBytes(origClOrdIdOptional.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET customerOrFirm == ReadBytes(orderId.rest, 1) IN IF ~customerOrFirm.ok THEN Fail ELSE
    LET openClose == ReadBytes(customerOrFirm.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET attributedQuote == ReadBytes(openClose.rest, 1) IN IF ~attributedQuote.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(attributedQuote.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET cancelInsteadOfSlide == ReadBytes(timeInForce.rest, 1) IN IF ~cancelInsteadOfSlide.ok THEN Fail ELSE
    LET displayInst == ReadBytes(cancelInsteadOfSlide.rest, 1) IN IF ~displayInst.ok THEN Fail ELSE
    LET execInst == ReadBytes(displayInst.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET ordType == ReadBytes(execInst.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET targetPartyId == ReadBytes(ordType.rest, 4) IN IF ~targetPartyId.ok THEN Fail ELSE
    LET auctionId == ReadBytes(targetPartyId.rest, 4) IN IF ~auctionId.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(auctionId.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET optionalData == ReadBytes(clearingFirm.rest, 16) IN IF ~optionalData.ok THEN Fail ELSE
    LET routingFirmId == ReadBytes(optionalData.rest, 4) IN IF ~routingFirmId.ok THEN Fail ELSE
    LET aiq == ReadBytes(routingFirmId.rest, 3) IN IF ~aiq.ok THEN Fail ELSE
    LET side == ReadBytes(aiq.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET pricePrice8Optional == ReadBytes(side.rest, 8) IN IF ~pricePrice8Optional.ok THEN Fail ELSE
    LET orderQtyQuantityNonZero == ReadBytes(pricePrice8Optional.rest, 4) IN IF ~orderQtyQuantityNonZero.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(orderQtyQuantityNonZero.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET effectiveLimitPrice == ReadBytes(leavesQty.rest, 8) IN IF ~effectiveLimitPrice.ok THEN Fail ELSE
    LET displayPrice == ReadBytes(effectiveLimitPrice.rest, 8) IN IF ~displayPrice.ok THEN Fail ELSE
    LET reasonCodeOptional == ReadBytes(displayPrice.rest, 1) IN IF ~reasonCodeOptional.ok THEN Fail ELSE
    LET ackType == ReadBytes(reasonCodeOptional.rest, 1) IN IF ~ackType.ok THEN Fail ELSE
    LET throttleIndicator == ReadBytes(ackType.rest, 1) IN IF ~throttleIndicator.ok THEN Fail ELSE
    Ok([ accountAccountOptional  |-> accountAccountOptional.value,
         transactTime            |-> transactTime.value,
         instrumentId            |-> instrumentId.value,
         marketParticipantId     |-> marketParticipantId.value,
         clOrdId                 |-> clOrdId.value,
         clearingAccountOptional |-> clearingAccountOptional.value,
         origClOrdIdOptional     |-> origClOrdIdOptional.value,
         orderId                 |-> orderId.value,
         customerOrFirm          |-> customerOrFirm.value,
         openClose               |-> openClose.value,
         attributedQuote         |-> attributedQuote.value,
         timeInForce             |-> timeInForce.value,
         cancelInsteadOfSlide    |-> cancelInsteadOfSlide.value,
         displayInst             |-> displayInst.value,
         execInst                |-> execInst.value,
         ordType                 |-> ordType.value,
         targetPartyId           |-> targetPartyId.value,
         auctionId               |-> auctionId.value,
         clearingFirm            |-> clearingFirm.value,
         optionalData            |-> optionalData.value,
         routingFirmId           |-> routingFirmId.value,
         aiq                     |-> aiq.value,
         side                    |-> side.value,
         pricePrice8Optional     |-> pricePrice8Optional.value,
         orderQtyQuantityNonZero |-> orderQtyQuantityNonZero.value,
         leavesQty               |-> leavesQty.value,
         effectiveLimitPrice     |-> effectiveLimitPrice.value,
         displayPrice            |-> displayPrice.value,
         reasonCodeOptional      |-> reasonCodeOptional.value,
         ackType                 |-> ackType.value,
         throttleIndicator       |-> throttleIndicator.value ], throttleIndicator.rest)

ZeroOrderAckMessage ==
    [ accountAccountOptional  |-> [i \in 1 .. 16 |-> 0],
      transactTime            |-> [i \in 1 .. 8 |-> 0],
      instrumentId            |-> [i \in 1 .. 4 |-> 0],
      marketParticipantId     |-> [i \in 1 .. 4 |-> 0],
      clOrdId                 |-> [i \in 1 .. 8 |-> 0],
      clearingAccountOptional |-> [i \in 1 .. 4 |-> 0],
      origClOrdIdOptional     |-> [i \in 1 .. 8 |-> 0],
      orderId                 |-> [i \in 1 .. 8 |-> 0],
      customerOrFirm          |-> [i \in 1 .. 1 |-> 0],
      openClose               |-> [i \in 1 .. 1 |-> 0],
      attributedQuote         |-> [i \in 1 .. 1 |-> 0],
      timeInForce             |-> [i \in 1 .. 1 |-> 0],
      cancelInsteadOfSlide    |-> [i \in 1 .. 1 |-> 0],
      displayInst             |-> [i \in 1 .. 1 |-> 0],
      execInst                |-> [i \in 1 .. 1 |-> 0],
      ordType                 |-> [i \in 1 .. 1 |-> 0],
      targetPartyId           |-> [i \in 1 .. 4 |-> 0],
      auctionId               |-> [i \in 1 .. 4 |-> 0],
      clearingFirm            |-> [i \in 1 .. 4 |-> 0],
      optionalData            |-> [i \in 1 .. 16 |-> 0],
      routingFirmId           |-> [i \in 1 .. 4 |-> 0],
      aiq                     |-> [i \in 1 .. 3 |-> 0],
      side                    |-> [i \in 1 .. 1 |-> 0],
      pricePrice8Optional     |-> [i \in 1 .. 8 |-> 0],
      orderQtyQuantityNonZero |-> [i \in 1 .. 4 |-> 0],
      leavesQty               |-> [i \in 1 .. 4 |-> 0],
      effectiveLimitPrice     |-> [i \in 1 .. 8 |-> 0],
      displayPrice            |-> [i \in 1 .. 8 |-> 0],
      reasonCodeOptional      |-> [i \in 1 .. 1 |-> 0],
      ackType                 |-> [i \in 1 .. 1 |-> 0],
      throttleIndicator       |-> [i \in 1 .. 1 |-> 0] ]

(* Order Ack Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderAckMessage ==
    { ZeroOrderAckMessage }
        \cup { [ZeroOrderAckMessage EXCEPT !.accountAccountOptional = one] : one \in Sample(16) }
        \cup { [ZeroOrderAckMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderAckMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderAckMessage EXCEPT !.marketParticipantId = one] : one \in Sample(4) }
        \cup { [ZeroOrderAckMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderAckMessage EXCEPT !.clearingAccountOptional = one] : one \in Sample(4) }
        \cup { [ZeroOrderAckMessage EXCEPT !.origClOrdIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroOrderAckMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderAckMessage EXCEPT !.customerOrFirm = one] : one \in Sample(1) }
        \cup { [ZeroOrderAckMessage EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroOrderAckMessage EXCEPT !.attributedQuote = one] : one \in Sample(1) }
        \cup { [ZeroOrderAckMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroOrderAckMessage EXCEPT !.cancelInsteadOfSlide = one] : one \in Sample(1) }
        \cup { [ZeroOrderAckMessage EXCEPT !.displayInst = one] : one \in Sample(1) }
        \cup { [ZeroOrderAckMessage EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroOrderAckMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroOrderAckMessage EXCEPT !.targetPartyId = one] : one \in Sample(4) }
        \cup { [ZeroOrderAckMessage EXCEPT !.auctionId = one] : one \in Sample(4) }
        \cup { [ZeroOrderAckMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroOrderAckMessage EXCEPT !.optionalData = one] : one \in Sample(16) }
        \cup { [ZeroOrderAckMessage EXCEPT !.routingFirmId = one] : one \in Sample(4) }
        \cup { [ZeroOrderAckMessage EXCEPT !.aiq = one] : one \in Sample(3) }
        \cup { [ZeroOrderAckMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderAckMessage EXCEPT !.pricePrice8Optional = one] : one \in Sample(8) }
        \cup { [ZeroOrderAckMessage EXCEPT !.orderQtyQuantityNonZero = one] : one \in Sample(4) }
        \cup { [ZeroOrderAckMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderAckMessage EXCEPT !.effectiveLimitPrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderAckMessage EXCEPT !.displayPrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderAckMessage EXCEPT !.reasonCodeOptional = one] : one \in Sample(1) }
        \cup { [ZeroOrderAckMessage EXCEPT !.ackType = one] : one \in Sample(1) }
        \cup { [ZeroOrderAckMessage EXCEPT !.throttleIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Unsolicited Modify Ack Message: 67 bytes                                *)
(***************************************************************************)

UnsolicitedModifyAckMessage ==
    [ transactTime            : Sample(8),
      instrumentId            : Sample(4),
      marketParticipantId     : Sample(4),
      origClOrdId             : Sample(8),
      orderId                 : Sample(8),
      pricePrice8             : Sample(8),
      orderQtyQuantityNonZero : Sample(4),
      leavesQty               : Sample(4),
      effectiveLimitPrice     : Sample(8),
      displayPrice            : Sample(8),
      restatementReason       : Sample(1),
      reasonCodeOptional      : Sample(1),
      ackType                 : Sample(1) ]

EncodeUnsolicitedModifyAckMessage(message) ==
    message.transactTime
        \o message.instrumentId
        \o message.marketParticipantId
        \o message.origClOrdId
        \o message.orderId
        \o message.pricePrice8
        \o message.orderQtyQuantityNonZero
        \o message.leavesQty
        \o message.effectiveLimitPrice
        \o message.displayPrice
        \o message.restatementReason
        \o message.reasonCodeOptional
        \o message.ackType

DecodeUnsolicitedModifyAckMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(transactTime.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET marketParticipantId == ReadBytes(instrumentId.rest, 4) IN IF ~marketParticipantId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(marketParticipantId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET orderId == ReadBytes(origClOrdId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET pricePrice8 == ReadBytes(orderId.rest, 8) IN IF ~pricePrice8.ok THEN Fail ELSE
    LET orderQtyQuantityNonZero == ReadBytes(pricePrice8.rest, 4) IN IF ~orderQtyQuantityNonZero.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(orderQtyQuantityNonZero.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET effectiveLimitPrice == ReadBytes(leavesQty.rest, 8) IN IF ~effectiveLimitPrice.ok THEN Fail ELSE
    LET displayPrice == ReadBytes(effectiveLimitPrice.rest, 8) IN IF ~displayPrice.ok THEN Fail ELSE
    LET restatementReason == ReadBytes(displayPrice.rest, 1) IN IF ~restatementReason.ok THEN Fail ELSE
    LET reasonCodeOptional == ReadBytes(restatementReason.rest, 1) IN IF ~reasonCodeOptional.ok THEN Fail ELSE
    LET ackType == ReadBytes(reasonCodeOptional.rest, 1) IN IF ~ackType.ok THEN Fail ELSE
    Ok([ transactTime            |-> transactTime.value,
         instrumentId            |-> instrumentId.value,
         marketParticipantId     |-> marketParticipantId.value,
         origClOrdId             |-> origClOrdId.value,
         orderId                 |-> orderId.value,
         pricePrice8             |-> pricePrice8.value,
         orderQtyQuantityNonZero |-> orderQtyQuantityNonZero.value,
         leavesQty               |-> leavesQty.value,
         effectiveLimitPrice     |-> effectiveLimitPrice.value,
         displayPrice            |-> displayPrice.value,
         restatementReason       |-> restatementReason.value,
         reasonCodeOptional      |-> reasonCodeOptional.value,
         ackType                 |-> ackType.value ], ackType.rest)

ZeroUnsolicitedModifyAckMessage ==
    [ transactTime            |-> [i \in 1 .. 8 |-> 0],
      instrumentId            |-> [i \in 1 .. 4 |-> 0],
      marketParticipantId     |-> [i \in 1 .. 4 |-> 0],
      origClOrdId             |-> [i \in 1 .. 8 |-> 0],
      orderId                 |-> [i \in 1 .. 8 |-> 0],
      pricePrice8             |-> [i \in 1 .. 8 |-> 0],
      orderQtyQuantityNonZero |-> [i \in 1 .. 4 |-> 0],
      leavesQty               |-> [i \in 1 .. 4 |-> 0],
      effectiveLimitPrice     |-> [i \in 1 .. 8 |-> 0],
      displayPrice            |-> [i \in 1 .. 8 |-> 0],
      restatementReason       |-> [i \in 1 .. 1 |-> 0],
      reasonCodeOptional      |-> [i \in 1 .. 1 |-> 0],
      ackType                 |-> [i \in 1 .. 1 |-> 0] ]

(* Unsolicited Modify Ack Message at zero, then each field in turn at the values it is checked at *)
CheckedUnsolicitedModifyAckMessage ==
    { ZeroUnsolicitedModifyAckMessage }
        \cup { [ZeroUnsolicitedModifyAckMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroUnsolicitedModifyAckMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroUnsolicitedModifyAckMessage EXCEPT !.marketParticipantId = one] : one \in Sample(4) }
        \cup { [ZeroUnsolicitedModifyAckMessage EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroUnsolicitedModifyAckMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroUnsolicitedModifyAckMessage EXCEPT !.pricePrice8 = one] : one \in Sample(8) }
        \cup { [ZeroUnsolicitedModifyAckMessage EXCEPT !.orderQtyQuantityNonZero = one] : one \in Sample(4) }
        \cup { [ZeroUnsolicitedModifyAckMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroUnsolicitedModifyAckMessage EXCEPT !.effectiveLimitPrice = one] : one \in Sample(8) }
        \cup { [ZeroUnsolicitedModifyAckMessage EXCEPT !.displayPrice = one] : one \in Sample(8) }
        \cup { [ZeroUnsolicitedModifyAckMessage EXCEPT !.restatementReason = one] : one \in Sample(1) }
        \cup { [ZeroUnsolicitedModifyAckMessage EXCEPT !.reasonCodeOptional = one] : one \in Sample(1) }
        \cup { [ZeroUnsolicitedModifyAckMessage EXCEPT !.ackType = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Cancel Ack Message: 55 bytes                                      *)
(***************************************************************************)

OrderCancelAckMessage ==
    [ transactTime        : Sample(8),
      instrumentId        : Sample(4),
      marketParticipantId : Sample(4),
      clOrdIdOptional     : Sample(8),
      origClOrdId         : Sample(8),
      orderIdOptional     : Sample(8),
      pricePrice8Optional : Sample(8),
      leavesQty           : Sample(4),
      reasonCodeOptional  : Sample(1),
      ackType             : Sample(1),
      throttleIndicator   : Sample(1) ]

EncodeOrderCancelAckMessage(message) ==
    message.transactTime
        \o message.instrumentId
        \o message.marketParticipantId
        \o message.clOrdIdOptional
        \o message.origClOrdId
        \o message.orderIdOptional
        \o message.pricePrice8Optional
        \o message.leavesQty
        \o message.reasonCodeOptional
        \o message.ackType
        \o message.throttleIndicator

DecodeOrderCancelAckMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(transactTime.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET marketParticipantId == ReadBytes(instrumentId.rest, 4) IN IF ~marketParticipantId.ok THEN Fail ELSE
    LET clOrdIdOptional == ReadBytes(marketParticipantId.rest, 8) IN IF ~clOrdIdOptional.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdIdOptional.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET orderIdOptional == ReadBytes(origClOrdId.rest, 8) IN IF ~orderIdOptional.ok THEN Fail ELSE
    LET pricePrice8Optional == ReadBytes(orderIdOptional.rest, 8) IN IF ~pricePrice8Optional.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(pricePrice8Optional.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET reasonCodeOptional == ReadBytes(leavesQty.rest, 1) IN IF ~reasonCodeOptional.ok THEN Fail ELSE
    LET ackType == ReadBytes(reasonCodeOptional.rest, 1) IN IF ~ackType.ok THEN Fail ELSE
    LET throttleIndicator == ReadBytes(ackType.rest, 1) IN IF ~throttleIndicator.ok THEN Fail ELSE
    Ok([ transactTime        |-> transactTime.value,
         instrumentId        |-> instrumentId.value,
         marketParticipantId |-> marketParticipantId.value,
         clOrdIdOptional     |-> clOrdIdOptional.value,
         origClOrdId         |-> origClOrdId.value,
         orderIdOptional     |-> orderIdOptional.value,
         pricePrice8Optional |-> pricePrice8Optional.value,
         leavesQty           |-> leavesQty.value,
         reasonCodeOptional  |-> reasonCodeOptional.value,
         ackType             |-> ackType.value,
         throttleIndicator   |-> throttleIndicator.value ], throttleIndicator.rest)

ZeroOrderCancelAckMessage ==
    [ transactTime        |-> [i \in 1 .. 8 |-> 0],
      instrumentId        |-> [i \in 1 .. 4 |-> 0],
      marketParticipantId |-> [i \in 1 .. 4 |-> 0],
      clOrdIdOptional     |-> [i \in 1 .. 8 |-> 0],
      origClOrdId         |-> [i \in 1 .. 8 |-> 0],
      orderIdOptional     |-> [i \in 1 .. 8 |-> 0],
      pricePrice8Optional |-> [i \in 1 .. 8 |-> 0],
      leavesQty           |-> [i \in 1 .. 4 |-> 0],
      reasonCodeOptional  |-> [i \in 1 .. 1 |-> 0],
      ackType             |-> [i \in 1 .. 1 |-> 0],
      throttleIndicator   |-> [i \in 1 .. 1 |-> 0] ]

(* Order Cancel Ack Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelAckMessage ==
    { ZeroOrderCancelAckMessage }
        \cup { [ZeroOrderCancelAckMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelAckMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelAckMessage EXCEPT !.marketParticipantId = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelAckMessage EXCEPT !.clOrdIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelAckMessage EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelAckMessage EXCEPT !.orderIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelAckMessage EXCEPT !.pricePrice8Optional = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelAckMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelAckMessage EXCEPT !.reasonCodeOptional = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelAckMessage EXCEPT !.ackType = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelAckMessage EXCEPT !.throttleIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Mass Cancel Ack Message: 33 bytes                                       *)
(***************************************************************************)

MassCancelAckMessage ==
    [ transactTime               : Sample(8),
      underlyingIdOptional       : Sample(4),
      marketParticipantId        : Sample(4),
      clOrdId                    : Sample(8),
      reasonCodeOptional         : Sample(1),
      ackStyleMassCancelAckStyle : Sample(1),
      mpidFilter                 : Sample(1),
      bulkAction                 : Sample(1),
      cancelCount                : Sample(4),
      throttleIndicator          : Sample(1) ]

EncodeMassCancelAckMessage(message) ==
    message.transactTime
        \o message.underlyingIdOptional
        \o message.marketParticipantId
        \o message.clOrdId
        \o message.reasonCodeOptional
        \o message.ackStyleMassCancelAckStyle
        \o message.mpidFilter
        \o message.bulkAction
        \o message.cancelCount
        \o message.throttleIndicator

DecodeMassCancelAckMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET underlyingIdOptional == ReadBytes(transactTime.rest, 4) IN IF ~underlyingIdOptional.ok THEN Fail ELSE
    LET marketParticipantId == ReadBytes(underlyingIdOptional.rest, 4) IN IF ~marketParticipantId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(marketParticipantId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET reasonCodeOptional == ReadBytes(clOrdId.rest, 1) IN IF ~reasonCodeOptional.ok THEN Fail ELSE
    LET ackStyleMassCancelAckStyle == ReadBytes(reasonCodeOptional.rest, 1) IN IF ~ackStyleMassCancelAckStyle.ok THEN Fail ELSE
    LET mpidFilter == ReadBytes(ackStyleMassCancelAckStyle.rest, 1) IN IF ~mpidFilter.ok THEN Fail ELSE
    LET bulkAction == ReadBytes(mpidFilter.rest, 1) IN IF ~bulkAction.ok THEN Fail ELSE
    LET cancelCount == ReadBytes(bulkAction.rest, 4) IN IF ~cancelCount.ok THEN Fail ELSE
    LET throttleIndicator == ReadBytes(cancelCount.rest, 1) IN IF ~throttleIndicator.ok THEN Fail ELSE
    Ok([ transactTime               |-> transactTime.value,
         underlyingIdOptional       |-> underlyingIdOptional.value,
         marketParticipantId        |-> marketParticipantId.value,
         clOrdId                    |-> clOrdId.value,
         reasonCodeOptional         |-> reasonCodeOptional.value,
         ackStyleMassCancelAckStyle |-> ackStyleMassCancelAckStyle.value,
         mpidFilter                 |-> mpidFilter.value,
         bulkAction                 |-> bulkAction.value,
         cancelCount                |-> cancelCount.value,
         throttleIndicator          |-> throttleIndicator.value ], throttleIndicator.rest)

ZeroMassCancelAckMessage ==
    [ transactTime               |-> [i \in 1 .. 8 |-> 0],
      underlyingIdOptional       |-> [i \in 1 .. 4 |-> 0],
      marketParticipantId        |-> [i \in 1 .. 4 |-> 0],
      clOrdId                    |-> [i \in 1 .. 8 |-> 0],
      reasonCodeOptional         |-> [i \in 1 .. 1 |-> 0],
      ackStyleMassCancelAckStyle |-> [i \in 1 .. 1 |-> 0],
      mpidFilter                 |-> [i \in 1 .. 1 |-> 0],
      bulkAction                 |-> [i \in 1 .. 1 |-> 0],
      cancelCount                |-> [i \in 1 .. 4 |-> 0],
      throttleIndicator          |-> [i \in 1 .. 1 |-> 0] ]

(* Mass Cancel Ack Message at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelAckMessage ==
    { ZeroMassCancelAckMessage }
        \cup { [ZeroMassCancelAckMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelAckMessage EXCEPT !.underlyingIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroMassCancelAckMessage EXCEPT !.marketParticipantId = one] : one \in Sample(4) }
        \cup { [ZeroMassCancelAckMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelAckMessage EXCEPT !.reasonCodeOptional = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelAckMessage EXCEPT !.ackStyleMassCancelAckStyle = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelAckMessage EXCEPT !.mpidFilter = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelAckMessage EXCEPT !.bulkAction = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelAckMessage EXCEPT !.cancelCount = one] : one \in Sample(4) }
        \cup { [ZeroMassCancelAckMessage EXCEPT !.throttleIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Bulk Quote Ack Message quote Acks Group: 23 bytes                       *)
(***************************************************************************)

BulkQuoteAckMessageQuoteAcksGroup ==
    [ instrumentId                 : Sample(4),
      side                         : Sample(1),
      orderIdOptional              : Sample(8),
      ackType                      : Sample(1),
      pricePrice4Optional          : Sample(4),
      orderQtyQuantityZeroOptional : Sample(4),
      reasonCodeOptional           : Sample(1) ]

EncodeBulkQuoteAckMessageQuoteAcksGroup(message) ==
    message.instrumentId
        \o message.side
        \o message.orderIdOptional
        \o message.ackType
        \o message.pricePrice4Optional
        \o message.orderQtyQuantityZeroOptional
        \o message.reasonCodeOptional

DecodeBulkQuoteAckMessageQuoteAcksGroup(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET side == ReadBytes(instrumentId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderIdOptional == ReadBytes(side.rest, 8) IN IF ~orderIdOptional.ok THEN Fail ELSE
    LET ackType == ReadBytes(orderIdOptional.rest, 1) IN IF ~ackType.ok THEN Fail ELSE
    LET pricePrice4Optional == ReadBytes(ackType.rest, 4) IN IF ~pricePrice4Optional.ok THEN Fail ELSE
    LET orderQtyQuantityZeroOptional == ReadBytes(pricePrice4Optional.rest, 4) IN IF ~orderQtyQuantityZeroOptional.ok THEN Fail ELSE
    LET reasonCodeOptional == ReadBytes(orderQtyQuantityZeroOptional.rest, 1) IN IF ~reasonCodeOptional.ok THEN Fail ELSE
    Ok([ instrumentId                 |-> instrumentId.value,
         side                         |-> side.value,
         orderIdOptional              |-> orderIdOptional.value,
         ackType                      |-> ackType.value,
         pricePrice4Optional          |-> pricePrice4Optional.value,
         orderQtyQuantityZeroOptional |-> orderQtyQuantityZeroOptional.value,
         reasonCodeOptional           |-> reasonCodeOptional.value ], reasonCodeOptional.rest)

ZeroBulkQuoteAckMessageQuoteAcksGroup ==
    [ instrumentId                 |-> [i \in 1 .. 4 |-> 0],
      side                         |-> [i \in 1 .. 1 |-> 0],
      orderIdOptional              |-> [i \in 1 .. 8 |-> 0],
      ackType                      |-> [i \in 1 .. 1 |-> 0],
      pricePrice4Optional          |-> [i \in 1 .. 4 |-> 0],
      orderQtyQuantityZeroOptional |-> [i \in 1 .. 4 |-> 0],
      reasonCodeOptional           |-> [i \in 1 .. 1 |-> 0] ]

(* Bulk Quote Ack Message quote Acks Group at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuoteAckMessageQuoteAcksGroup ==
    { ZeroBulkQuoteAckMessageQuoteAcksGroup }
        \cup { [ZeroBulkQuoteAckMessageQuoteAcksGroup EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroBulkQuoteAckMessageQuoteAcksGroup EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroBulkQuoteAckMessageQuoteAcksGroup EXCEPT !.orderIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuoteAckMessageQuoteAcksGroup EXCEPT !.ackType = one] : one \in Sample(1) }
        \cup { [ZeroBulkQuoteAckMessageQuoteAcksGroup EXCEPT !.pricePrice4Optional = one] : one \in Sample(4) }
        \cup { [ZeroBulkQuoteAckMessageQuoteAcksGroup EXCEPT !.orderQtyQuantityZeroOptional = one] : one \in Sample(4) }
        \cup { [ZeroBulkQuoteAckMessageQuoteAcksGroup EXCEPT !.reasonCodeOptional = one] : one \in Sample(1) }

(* A run of Bulk Quote Ack Message quote Acks Group, written one after another *)
RECURSIVE EncodeBulkQuoteAckMessageQuoteAcksGroupList(_)
EncodeBulkQuoteAckMessageQuoteAcksGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeBulkQuoteAckMessageQuoteAcksGroup(Head(messages)) \o EncodeBulkQuoteAckMessageQuoteAcksGroupList(Tail(messages))

(* As many Bulk Quote Ack Message quote Acks Group as the field that counts them says *)
RECURSIVE ReadBulkQuoteAckMessageQuoteAcksGroupList(_, _)
ReadBulkQuoteAckMessageQuoteAcksGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeBulkQuoteAckMessageQuoteAcksGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadBulkQuoteAckMessageQuoteAcksGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Bulk Quote Ack Message quote Acks Group of each kind, for the lists that carry them *)
OneBulkQuoteAckMessageQuoteAcksGroup == { ZeroBulkQuoteAckMessageQuoteAcksGroup }

(***************************************************************************)
(* Bulk Quote Ack Message quote Acks Groups                                *)
(***************************************************************************)

BulkQuoteAckMessageQuoteAcksGroups ==
    [ blockLengthShort                  : Sample(1),
      bulkQuoteAckMessageQuoteAcksGroup : SampleLists(OneBulkQuoteAckMessageQuoteAcksGroup) ]

EncodeBulkQuoteAckMessageQuoteAcksGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.bulkQuoteAckMessageQuoteAcksGroup), 1)
        \o EncodeBulkQuoteAckMessageQuoteAcksGroupList(message.bulkQuoteAckMessageQuoteAcksGroup)

DecodeBulkQuoteAckMessageQuoteAcksGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET bulkQuoteAckMessageQuoteAcksGroup == ReadBulkQuoteAckMessageQuoteAcksGroupList(numInGroup.rest, numInGroup.value) IN IF ~bulkQuoteAckMessageQuoteAcksGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort                  |-> blockLengthShort.value,
         bulkQuoteAckMessageQuoteAcksGroup |-> bulkQuoteAckMessageQuoteAcksGroup.value ], bulkQuoteAckMessageQuoteAcksGroup.rest)

ZeroBulkQuoteAckMessageQuoteAcksGroups ==
    [ blockLengthShort                  |-> [i \in 1 .. 1 |-> 0],
      bulkQuoteAckMessageQuoteAcksGroup |-> << >> ]

(* Bulk Quote Ack Message quote Acks Groups at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuoteAckMessageQuoteAcksGroups ==
    { ZeroBulkQuoteAckMessageQuoteAcksGroups }
        \cup { [ZeroBulkQuoteAckMessageQuoteAcksGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroBulkQuoteAckMessageQuoteAcksGroups EXCEPT !.bulkQuoteAckMessageQuoteAcksGroup = one] : one \in SampleLists(OneBulkQuoteAckMessageQuoteAcksGroup) }

(***************************************************************************)
(* Bulk Quote Ack Message                                                  *)
(***************************************************************************)

BulkQuoteAckMessage ==
    [ transactTime                       : Sample(8),
      marketParticipantId                : Sample(4),
      customGroupIdOptional              : Sample(2),
      clOrdId                            : Sample(8),
      clearingAccount                    : Sample(4),
      aiq                                : Sample(3),
      throttleIndicator                  : Sample(1),
      bulkQuoteAckMessageQuoteAcksGroups : BulkQuoteAckMessageQuoteAcksGroups ]

EncodeBulkQuoteAckMessage(message) ==
    message.transactTime
        \o message.marketParticipantId
        \o message.customGroupIdOptional
        \o message.clOrdId
        \o message.clearingAccount
        \o message.aiq
        \o message.throttleIndicator
        \o EncodeBulkQuoteAckMessageQuoteAcksGroups(message.bulkQuoteAckMessageQuoteAcksGroups)

DecodeBulkQuoteAckMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET marketParticipantId == ReadBytes(transactTime.rest, 4) IN IF ~marketParticipantId.ok THEN Fail ELSE
    LET customGroupIdOptional == ReadBytes(marketParticipantId.rest, 2) IN IF ~customGroupIdOptional.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(customGroupIdOptional.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET clearingAccount == ReadBytes(clOrdId.rest, 4) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET aiq == ReadBytes(clearingAccount.rest, 3) IN IF ~aiq.ok THEN Fail ELSE
    LET throttleIndicator == ReadBytes(aiq.rest, 1) IN IF ~throttleIndicator.ok THEN Fail ELSE
    LET bulkQuoteAckMessageQuoteAcksGroups == DecodeBulkQuoteAckMessageQuoteAcksGroups(throttleIndicator.rest) IN IF ~bulkQuoteAckMessageQuoteAcksGroups.ok THEN Fail ELSE
    Ok([ transactTime                       |-> transactTime.value,
         marketParticipantId                |-> marketParticipantId.value,
         customGroupIdOptional              |-> customGroupIdOptional.value,
         clOrdId                            |-> clOrdId.value,
         clearingAccount                    |-> clearingAccount.value,
         aiq                                |-> aiq.value,
         throttleIndicator                  |-> throttleIndicator.value,
         bulkQuoteAckMessageQuoteAcksGroups |-> bulkQuoteAckMessageQuoteAcksGroups.value ], bulkQuoteAckMessageQuoteAcksGroups.rest)

ZeroBulkQuoteAckMessage ==
    [ transactTime                       |-> [i \in 1 .. 8 |-> 0],
      marketParticipantId                |-> [i \in 1 .. 4 |-> 0],
      customGroupIdOptional              |-> [i \in 1 .. 2 |-> 0],
      clOrdId                            |-> [i \in 1 .. 8 |-> 0],
      clearingAccount                    |-> [i \in 1 .. 4 |-> 0],
      aiq                                |-> [i \in 1 .. 3 |-> 0],
      throttleIndicator                  |-> [i \in 1 .. 1 |-> 0],
      bulkQuoteAckMessageQuoteAcksGroups |-> ZeroBulkQuoteAckMessageQuoteAcksGroups ]

(* Bulk Quote Ack Message at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuoteAckMessage ==
    { ZeroBulkQuoteAckMessage }
        \cup { [ZeroBulkQuoteAckMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuoteAckMessage EXCEPT !.marketParticipantId = one] : one \in Sample(4) }
        \cup { [ZeroBulkQuoteAckMessage EXCEPT !.customGroupIdOptional = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuoteAckMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuoteAckMessage EXCEPT !.clearingAccount = one] : one \in Sample(4) }
        \cup { [ZeroBulkQuoteAckMessage EXCEPT !.aiq = one] : one \in Sample(3) }
        \cup { [ZeroBulkQuoteAckMessage EXCEPT !.throttleIndicator = one] : one \in Sample(1) }
        \cup { [ZeroBulkQuoteAckMessage EXCEPT !.bulkQuoteAckMessageQuoteAcksGroups = one] : one \in CheckedBulkQuoteAckMessageQuoteAcksGroups }

(***************************************************************************)
(* New Ioc Quote Ack Message: 51 bytes                                     *)
(***************************************************************************)

NewIocQuoteAckMessage ==
    [ transactTime            : Sample(8),
      marketParticipantId     : Sample(4),
      clOrdId                 : Sample(8),
      clearingAccount         : Sample(4),
      aiq                     : Sample(3),
      instrumentId            : Sample(4),
      side                    : Sample(1),
      orderId                 : Sample(8),
      ackType                 : Sample(1),
      pricePrice4Optional     : Sample(4),
      orderQtyQuantityNonZero : Sample(4),
      reasonCodeOptional      : Sample(1),
      throttleIndicator       : Sample(1) ]

EncodeNewIocQuoteAckMessage(message) ==
    message.transactTime
        \o message.marketParticipantId
        \o message.clOrdId
        \o message.clearingAccount
        \o message.aiq
        \o message.instrumentId
        \o message.side
        \o message.orderId
        \o message.ackType
        \o message.pricePrice4Optional
        \o message.orderQtyQuantityNonZero
        \o message.reasonCodeOptional
        \o message.throttleIndicator

DecodeNewIocQuoteAckMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET marketParticipantId == ReadBytes(transactTime.rest, 4) IN IF ~marketParticipantId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(marketParticipantId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET clearingAccount == ReadBytes(clOrdId.rest, 4) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET aiq == ReadBytes(clearingAccount.rest, 3) IN IF ~aiq.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(aiq.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET side == ReadBytes(instrumentId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderId == ReadBytes(side.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET ackType == ReadBytes(orderId.rest, 1) IN IF ~ackType.ok THEN Fail ELSE
    LET pricePrice4Optional == ReadBytes(ackType.rest, 4) IN IF ~pricePrice4Optional.ok THEN Fail ELSE
    LET orderQtyQuantityNonZero == ReadBytes(pricePrice4Optional.rest, 4) IN IF ~orderQtyQuantityNonZero.ok THEN Fail ELSE
    LET reasonCodeOptional == ReadBytes(orderQtyQuantityNonZero.rest, 1) IN IF ~reasonCodeOptional.ok THEN Fail ELSE
    LET throttleIndicator == ReadBytes(reasonCodeOptional.rest, 1) IN IF ~throttleIndicator.ok THEN Fail ELSE
    Ok([ transactTime            |-> transactTime.value,
         marketParticipantId     |-> marketParticipantId.value,
         clOrdId                 |-> clOrdId.value,
         clearingAccount         |-> clearingAccount.value,
         aiq                     |-> aiq.value,
         instrumentId            |-> instrumentId.value,
         side                    |-> side.value,
         orderId                 |-> orderId.value,
         ackType                 |-> ackType.value,
         pricePrice4Optional     |-> pricePrice4Optional.value,
         orderQtyQuantityNonZero |-> orderQtyQuantityNonZero.value,
         reasonCodeOptional      |-> reasonCodeOptional.value,
         throttleIndicator       |-> throttleIndicator.value ], throttleIndicator.rest)

ZeroNewIocQuoteAckMessage ==
    [ transactTime            |-> [i \in 1 .. 8 |-> 0],
      marketParticipantId     |-> [i \in 1 .. 4 |-> 0],
      clOrdId                 |-> [i \in 1 .. 8 |-> 0],
      clearingAccount         |-> [i \in 1 .. 4 |-> 0],
      aiq                     |-> [i \in 1 .. 3 |-> 0],
      instrumentId            |-> [i \in 1 .. 4 |-> 0],
      side                    |-> [i \in 1 .. 1 |-> 0],
      orderId                 |-> [i \in 1 .. 8 |-> 0],
      ackType                 |-> [i \in 1 .. 1 |-> 0],
      pricePrice4Optional     |-> [i \in 1 .. 4 |-> 0],
      orderQtyQuantityNonZero |-> [i \in 1 .. 4 |-> 0],
      reasonCodeOptional      |-> [i \in 1 .. 1 |-> 0],
      throttleIndicator       |-> [i \in 1 .. 1 |-> 0] ]

(* New Ioc Quote Ack Message at zero, then each field in turn at the values it is checked at *)
CheckedNewIocQuoteAckMessage ==
    { ZeroNewIocQuoteAckMessage }
        \cup { [ZeroNewIocQuoteAckMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroNewIocQuoteAckMessage EXCEPT !.marketParticipantId = one] : one \in Sample(4) }
        \cup { [ZeroNewIocQuoteAckMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroNewIocQuoteAckMessage EXCEPT !.clearingAccount = one] : one \in Sample(4) }
        \cup { [ZeroNewIocQuoteAckMessage EXCEPT !.aiq = one] : one \in Sample(3) }
        \cup { [ZeroNewIocQuoteAckMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroNewIocQuoteAckMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewIocQuoteAckMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroNewIocQuoteAckMessage EXCEPT !.ackType = one] : one \in Sample(1) }
        \cup { [ZeroNewIocQuoteAckMessage EXCEPT !.pricePrice4Optional = one] : one \in Sample(4) }
        \cup { [ZeroNewIocQuoteAckMessage EXCEPT !.orderQtyQuantityNonZero = one] : one \in Sample(4) }
        \cup { [ZeroNewIocQuoteAckMessage EXCEPT !.reasonCodeOptional = one] : one \in Sample(1) }
        \cup { [ZeroNewIocQuoteAckMessage EXCEPT !.throttleIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Quote Restated Message: 43 bytes                                        *)
(***************************************************************************)

QuoteRestatedMessage ==
    [ transactTime        : Sample(8),
      instrumentId        : Sample(4),
      marketParticipantId : Sample(4),
      clOrdId             : Sample(8),
      orderId             : Sample(8),
      side                : Sample(1),
      pricePrice4         : Sample(4),
      reasonCodeOptional  : Sample(1),
      ackType             : Sample(1),
      delta               : Sample(4) ]

EncodeQuoteRestatedMessage(message) ==
    message.transactTime
        \o message.instrumentId
        \o message.marketParticipantId
        \o message.clOrdId
        \o message.orderId
        \o message.side
        \o message.pricePrice4
        \o message.reasonCodeOptional
        \o message.ackType
        \o message.delta

DecodeQuoteRestatedMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(transactTime.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET marketParticipantId == ReadBytes(instrumentId.rest, 4) IN IF ~marketParticipantId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(marketParticipantId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clOrdId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET side == ReadBytes(orderId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET pricePrice4 == ReadBytes(side.rest, 4) IN IF ~pricePrice4.ok THEN Fail ELSE
    LET reasonCodeOptional == ReadBytes(pricePrice4.rest, 1) IN IF ~reasonCodeOptional.ok THEN Fail ELSE
    LET ackType == ReadBytes(reasonCodeOptional.rest, 1) IN IF ~ackType.ok THEN Fail ELSE
    LET delta == ReadBytes(ackType.rest, 4) IN IF ~delta.ok THEN Fail ELSE
    Ok([ transactTime        |-> transactTime.value,
         instrumentId        |-> instrumentId.value,
         marketParticipantId |-> marketParticipantId.value,
         clOrdId             |-> clOrdId.value,
         orderId             |-> orderId.value,
         side                |-> side.value,
         pricePrice4         |-> pricePrice4.value,
         reasonCodeOptional  |-> reasonCodeOptional.value,
         ackType             |-> ackType.value,
         delta               |-> delta.value ], delta.rest)

ZeroQuoteRestatedMessage ==
    [ transactTime        |-> [i \in 1 .. 8 |-> 0],
      instrumentId        |-> [i \in 1 .. 4 |-> 0],
      marketParticipantId |-> [i \in 1 .. 4 |-> 0],
      clOrdId             |-> [i \in 1 .. 8 |-> 0],
      orderId             |-> [i \in 1 .. 8 |-> 0],
      side                |-> [i \in 1 .. 1 |-> 0],
      pricePrice4         |-> [i \in 1 .. 4 |-> 0],
      reasonCodeOptional  |-> [i \in 1 .. 1 |-> 0],
      ackType             |-> [i \in 1 .. 1 |-> 0],
      delta               |-> [i \in 1 .. 4 |-> 0] ]

(* Quote Restated Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteRestatedMessage ==
    { ZeroQuoteRestatedMessage }
        \cup { [ZeroQuoteRestatedMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRestatedMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRestatedMessage EXCEPT !.marketParticipantId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRestatedMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRestatedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRestatedMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRestatedMessage EXCEPT !.pricePrice4 = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRestatedMessage EXCEPT !.reasonCodeOptional = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRestatedMessage EXCEPT !.ackType = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRestatedMessage EXCEPT !.delta = one] : one \in Sample(4) }

(***************************************************************************)
(* Quote Canceled Message: 39 bytes                                        *)
(***************************************************************************)

QuoteCanceledMessage ==
    [ transactTime        : Sample(8),
      instrumentId        : Sample(4),
      marketParticipantId : Sample(4),
      clOrdId             : Sample(8),
      orderId             : Sample(8),
      side                : Sample(1),
      reasonCode          : Sample(1),
      ackType             : Sample(1),
      delta               : Sample(4) ]

EncodeQuoteCanceledMessage(message) ==
    message.transactTime
        \o message.instrumentId
        \o message.marketParticipantId
        \o message.clOrdId
        \o message.orderId
        \o message.side
        \o message.reasonCode
        \o message.ackType
        \o message.delta

DecodeQuoteCanceledMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(transactTime.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET marketParticipantId == ReadBytes(instrumentId.rest, 4) IN IF ~marketParticipantId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(marketParticipantId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clOrdId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET side == ReadBytes(orderId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(side.rest, 1) IN IF ~reasonCode.ok THEN Fail ELSE
    LET ackType == ReadBytes(reasonCode.rest, 1) IN IF ~ackType.ok THEN Fail ELSE
    LET delta == ReadBytes(ackType.rest, 4) IN IF ~delta.ok THEN Fail ELSE
    Ok([ transactTime        |-> transactTime.value,
         instrumentId        |-> instrumentId.value,
         marketParticipantId |-> marketParticipantId.value,
         clOrdId             |-> clOrdId.value,
         orderId             |-> orderId.value,
         side                |-> side.value,
         reasonCode          |-> reasonCode.value,
         ackType             |-> ackType.value,
         delta               |-> delta.value ], delta.rest)

ZeroQuoteCanceledMessage ==
    [ transactTime        |-> [i \in 1 .. 8 |-> 0],
      instrumentId        |-> [i \in 1 .. 4 |-> 0],
      marketParticipantId |-> [i \in 1 .. 4 |-> 0],
      clOrdId             |-> [i \in 1 .. 8 |-> 0],
      orderId             |-> [i \in 1 .. 8 |-> 0],
      side                |-> [i \in 1 .. 1 |-> 0],
      reasonCode          |-> [i \in 1 .. 1 |-> 0],
      ackType             |-> [i \in 1 .. 1 |-> 0],
      delta               |-> [i \in 1 .. 4 |-> 0] ]

(* Quote Canceled Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteCanceledMessage ==
    { ZeroQuoteCanceledMessage }
        \cup { [ZeroQuoteCanceledMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroQuoteCanceledMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteCanceledMessage EXCEPT !.marketParticipantId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteCanceledMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteCanceledMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteCanceledMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroQuoteCanceledMessage EXCEPT !.reasonCode = one] : one \in Sample(1) }
        \cup { [ZeroQuoteCanceledMessage EXCEPT !.ackType = one] : one \in Sample(1) }
        \cup { [ZeroQuoteCanceledMessage EXCEPT !.delta = one] : one \in Sample(4) }

(***************************************************************************)
(* Purge Ack Message custom Group Ids Group: 2 bytes                       *)
(***************************************************************************)

PurgeAckMessageCustomGroupIdsGroup ==
    [ customGroupId : Sample(2) ]

EncodePurgeAckMessageCustomGroupIdsGroup(message) ==
    message.customGroupId

DecodePurgeAckMessageCustomGroupIdsGroup(bytes) ==
    LET customGroupId == ReadBytes(bytes, 2) IN IF ~customGroupId.ok THEN Fail ELSE
    Ok([ customGroupId |-> customGroupId.value ], customGroupId.rest)

ZeroPurgeAckMessageCustomGroupIdsGroup ==
    [ customGroupId |-> [i \in 1 .. 2 |-> 0] ]

(* Purge Ack Message custom Group Ids Group at zero, then each field in turn at the values it is checked at *)
CheckedPurgeAckMessageCustomGroupIdsGroup ==
    { ZeroPurgeAckMessageCustomGroupIdsGroup }
        \cup { [ZeroPurgeAckMessageCustomGroupIdsGroup EXCEPT !.customGroupId = one] : one \in Sample(2) }

(* A run of Purge Ack Message custom Group Ids Group, written one after another *)
RECURSIVE EncodePurgeAckMessageCustomGroupIdsGroupList(_)
EncodePurgeAckMessageCustomGroupIdsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodePurgeAckMessageCustomGroupIdsGroup(Head(messages)) \o EncodePurgeAckMessageCustomGroupIdsGroupList(Tail(messages))

(* As many Purge Ack Message custom Group Ids Group as the field that counts them says *)
RECURSIVE ReadPurgeAckMessageCustomGroupIdsGroupList(_, _)
ReadPurgeAckMessageCustomGroupIdsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodePurgeAckMessageCustomGroupIdsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadPurgeAckMessageCustomGroupIdsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Purge Ack Message custom Group Ids Group of each kind, for the lists that carry them *)
OnePurgeAckMessageCustomGroupIdsGroup == { ZeroPurgeAckMessageCustomGroupIdsGroup }

(***************************************************************************)
(* Purge Ack Message custom Group Ids Groups                               *)
(***************************************************************************)

PurgeAckMessageCustomGroupIdsGroups ==
    [ blockLengthShort                   : Sample(1),
      purgeAckMessageCustomGroupIdsGroup : SampleLists(OnePurgeAckMessageCustomGroupIdsGroup) ]

EncodePurgeAckMessageCustomGroupIdsGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.purgeAckMessageCustomGroupIdsGroup), 1)
        \o EncodePurgeAckMessageCustomGroupIdsGroupList(message.purgeAckMessageCustomGroupIdsGroup)

DecodePurgeAckMessageCustomGroupIdsGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET purgeAckMessageCustomGroupIdsGroup == ReadPurgeAckMessageCustomGroupIdsGroupList(numInGroup.rest, numInGroup.value) IN IF ~purgeAckMessageCustomGroupIdsGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort                   |-> blockLengthShort.value,
         purgeAckMessageCustomGroupIdsGroup |-> purgeAckMessageCustomGroupIdsGroup.value ], purgeAckMessageCustomGroupIdsGroup.rest)

ZeroPurgeAckMessageCustomGroupIdsGroups ==
    [ blockLengthShort                   |-> [i \in 1 .. 1 |-> 0],
      purgeAckMessageCustomGroupIdsGroup |-> << >> ]

(* Purge Ack Message custom Group Ids Groups at zero, then each field in turn at the values it is checked at *)
CheckedPurgeAckMessageCustomGroupIdsGroups ==
    { ZeroPurgeAckMessageCustomGroupIdsGroups }
        \cup { [ZeroPurgeAckMessageCustomGroupIdsGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroPurgeAckMessageCustomGroupIdsGroups EXCEPT !.purgeAckMessageCustomGroupIdsGroup = one] : one \in SampleLists(OnePurgeAckMessageCustomGroupIdsGroup) }

(***************************************************************************)
(* Purge Ack Message                                                       *)
(***************************************************************************)

PurgeAckMessage ==
    [ transactTime                        : Sample(8),
      underlyingIdOptional                : Sample(4),
      marketParticipantId                 : Sample(4),
      clOrdId                             : Sample(8),
      ackStylePurgeRequestAckStyle        : Sample(1),
      bulkAction                          : Sample(1),
      cancelCount                         : Sample(4),
      throttleIndicator                   : Sample(1),
      purgeAckMessageCustomGroupIdsGroups : PurgeAckMessageCustomGroupIdsGroups ]

EncodePurgeAckMessage(message) ==
    message.transactTime
        \o message.underlyingIdOptional
        \o message.marketParticipantId
        \o message.clOrdId
        \o message.ackStylePurgeRequestAckStyle
        \o message.bulkAction
        \o message.cancelCount
        \o message.throttleIndicator
        \o EncodePurgeAckMessageCustomGroupIdsGroups(message.purgeAckMessageCustomGroupIdsGroups)

DecodePurgeAckMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET underlyingIdOptional == ReadBytes(transactTime.rest, 4) IN IF ~underlyingIdOptional.ok THEN Fail ELSE
    LET marketParticipantId == ReadBytes(underlyingIdOptional.rest, 4) IN IF ~marketParticipantId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(marketParticipantId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET ackStylePurgeRequestAckStyle == ReadBytes(clOrdId.rest, 1) IN IF ~ackStylePurgeRequestAckStyle.ok THEN Fail ELSE
    LET bulkAction == ReadBytes(ackStylePurgeRequestAckStyle.rest, 1) IN IF ~bulkAction.ok THEN Fail ELSE
    LET cancelCount == ReadBytes(bulkAction.rest, 4) IN IF ~cancelCount.ok THEN Fail ELSE
    LET throttleIndicator == ReadBytes(cancelCount.rest, 1) IN IF ~throttleIndicator.ok THEN Fail ELSE
    LET purgeAckMessageCustomGroupIdsGroups == DecodePurgeAckMessageCustomGroupIdsGroups(throttleIndicator.rest) IN IF ~purgeAckMessageCustomGroupIdsGroups.ok THEN Fail ELSE
    Ok([ transactTime                        |-> transactTime.value,
         underlyingIdOptional                |-> underlyingIdOptional.value,
         marketParticipantId                 |-> marketParticipantId.value,
         clOrdId                             |-> clOrdId.value,
         ackStylePurgeRequestAckStyle        |-> ackStylePurgeRequestAckStyle.value,
         bulkAction                          |-> bulkAction.value,
         cancelCount                         |-> cancelCount.value,
         throttleIndicator                   |-> throttleIndicator.value,
         purgeAckMessageCustomGroupIdsGroups |-> purgeAckMessageCustomGroupIdsGroups.value ], purgeAckMessageCustomGroupIdsGroups.rest)

ZeroPurgeAckMessage ==
    [ transactTime                        |-> [i \in 1 .. 8 |-> 0],
      underlyingIdOptional                |-> [i \in 1 .. 4 |-> 0],
      marketParticipantId                 |-> [i \in 1 .. 4 |-> 0],
      clOrdId                             |-> [i \in 1 .. 8 |-> 0],
      ackStylePurgeRequestAckStyle        |-> [i \in 1 .. 1 |-> 0],
      bulkAction                          |-> [i \in 1 .. 1 |-> 0],
      cancelCount                         |-> [i \in 1 .. 4 |-> 0],
      throttleIndicator                   |-> [i \in 1 .. 1 |-> 0],
      purgeAckMessageCustomGroupIdsGroups |-> ZeroPurgeAckMessageCustomGroupIdsGroups ]

(* Purge Ack Message at zero, then each field in turn at the values it is checked at *)
CheckedPurgeAckMessage ==
    { ZeroPurgeAckMessage }
        \cup { [ZeroPurgeAckMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroPurgeAckMessage EXCEPT !.underlyingIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroPurgeAckMessage EXCEPT !.marketParticipantId = one] : one \in Sample(4) }
        \cup { [ZeroPurgeAckMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroPurgeAckMessage EXCEPT !.ackStylePurgeRequestAckStyle = one] : one \in Sample(1) }
        \cup { [ZeroPurgeAckMessage EXCEPT !.bulkAction = one] : one \in Sample(1) }
        \cup { [ZeroPurgeAckMessage EXCEPT !.cancelCount = one] : one \in Sample(4) }
        \cup { [ZeroPurgeAckMessage EXCEPT !.throttleIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPurgeAckMessage EXCEPT !.purgeAckMessageCustomGroupIdsGroups = one] : one \in CheckedPurgeAckMessageCustomGroupIdsGroups }

(***************************************************************************)
(* Execution Report Message: 154 bytes                                     *)
(***************************************************************************)

ExecutionReportMessage ==
    [ accountAccountOptional  : Sample(16),
      transactTime            : Sample(8),
      instrumentId            : Sample(4),
      marketParticipantId     : Sample(4),
      clOrdId                 : Sample(8),
      clearingAccountOptional : Sample(4),
      customerOrFirm          : Sample(1),
      orderId                 : Sample(8),
      execId                  : Sample(8),
      tradeId                 : Sample(8),
      lastPx                  : Sample(8),
      openClose               : Sample(1),
      side                    : Sample(1),
      targetPartyId           : Sample(4),
      auctionId               : Sample(4),
      clearingFirm            : Sample(4),
      optionalData            : Sample(16),
      routingFirmId           : Sample(4),
      aiq                     : Sample(3),
      leavesQty               : Sample(4),
      cumQty                  : Sample(4),
      lastQty                 : Sample(4),
      tradeLiquidityIndicator : Sample(1),
      feeCode                 : Sample(2),
      reasonCodeOptional      : Sample(1),
      occId                   : Sample(5),
      contraClearingAccount   : Sample(4),
      contraClearingFirm      : Sample(4),
      contraMpid              : Sample(4),
      contraOpenClose         : Sample(1),
      contraCustomerOrFirm    : Sample(1),
      contraOccId             : Sample(5) ]

EncodeExecutionReportMessage(message) ==
    message.accountAccountOptional
        \o message.transactTime
        \o message.instrumentId
        \o message.marketParticipantId
        \o message.clOrdId
        \o message.clearingAccountOptional
        \o message.customerOrFirm
        \o message.orderId
        \o message.execId
        \o message.tradeId
        \o message.lastPx
        \o message.openClose
        \o message.side
        \o message.targetPartyId
        \o message.auctionId
        \o message.clearingFirm
        \o message.optionalData
        \o message.routingFirmId
        \o message.aiq
        \o message.leavesQty
        \o message.cumQty
        \o message.lastQty
        \o message.tradeLiquidityIndicator
        \o message.feeCode
        \o message.reasonCodeOptional
        \o message.occId
        \o message.contraClearingAccount
        \o message.contraClearingFirm
        \o message.contraMpid
        \o message.contraOpenClose
        \o message.contraCustomerOrFirm
        \o message.contraOccId

DecodeExecutionReportMessage(bytes) ==
    LET accountAccountOptional == ReadBytes(bytes, 16) IN IF ~accountAccountOptional.ok THEN Fail ELSE
    LET transactTime == ReadBytes(accountAccountOptional.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(transactTime.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET marketParticipantId == ReadBytes(instrumentId.rest, 4) IN IF ~marketParticipantId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(marketParticipantId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET clearingAccountOptional == ReadBytes(clOrdId.rest, 4) IN IF ~clearingAccountOptional.ok THEN Fail ELSE
    LET customerOrFirm == ReadBytes(clearingAccountOptional.rest, 1) IN IF ~customerOrFirm.ok THEN Fail ELSE
    LET orderId == ReadBytes(customerOrFirm.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET execId == ReadBytes(orderId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(execId.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET lastPx == ReadBytes(tradeId.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET openClose == ReadBytes(lastPx.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET side == ReadBytes(openClose.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET targetPartyId == ReadBytes(side.rest, 4) IN IF ~targetPartyId.ok THEN Fail ELSE
    LET auctionId == ReadBytes(targetPartyId.rest, 4) IN IF ~auctionId.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(auctionId.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET optionalData == ReadBytes(clearingFirm.rest, 16) IN IF ~optionalData.ok THEN Fail ELSE
    LET routingFirmId == ReadBytes(optionalData.rest, 4) IN IF ~routingFirmId.ok THEN Fail ELSE
    LET aiq == ReadBytes(routingFirmId.rest, 3) IN IF ~aiq.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(aiq.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET lastQty == ReadBytes(cumQty.rest, 4) IN IF ~lastQty.ok THEN Fail ELSE
    LET tradeLiquidityIndicator == ReadBytes(lastQty.rest, 1) IN IF ~tradeLiquidityIndicator.ok THEN Fail ELSE
    LET feeCode == ReadBytes(tradeLiquidityIndicator.rest, 2) IN IF ~feeCode.ok THEN Fail ELSE
    LET reasonCodeOptional == ReadBytes(feeCode.rest, 1) IN IF ~reasonCodeOptional.ok THEN Fail ELSE
    LET occId == ReadBytes(reasonCodeOptional.rest, 5) IN IF ~occId.ok THEN Fail ELSE
    LET contraClearingAccount == ReadBytes(occId.rest, 4) IN IF ~contraClearingAccount.ok THEN Fail ELSE
    LET contraClearingFirm == ReadBytes(contraClearingAccount.rest, 4) IN IF ~contraClearingFirm.ok THEN Fail ELSE
    LET contraMpid == ReadBytes(contraClearingFirm.rest, 4) IN IF ~contraMpid.ok THEN Fail ELSE
    LET contraOpenClose == ReadBytes(contraMpid.rest, 1) IN IF ~contraOpenClose.ok THEN Fail ELSE
    LET contraCustomerOrFirm == ReadBytes(contraOpenClose.rest, 1) IN IF ~contraCustomerOrFirm.ok THEN Fail ELSE
    LET contraOccId == ReadBytes(contraCustomerOrFirm.rest, 5) IN IF ~contraOccId.ok THEN Fail ELSE
    Ok([ accountAccountOptional  |-> accountAccountOptional.value,
         transactTime            |-> transactTime.value,
         instrumentId            |-> instrumentId.value,
         marketParticipantId     |-> marketParticipantId.value,
         clOrdId                 |-> clOrdId.value,
         clearingAccountOptional |-> clearingAccountOptional.value,
         customerOrFirm          |-> customerOrFirm.value,
         orderId                 |-> orderId.value,
         execId                  |-> execId.value,
         tradeId                 |-> tradeId.value,
         lastPx                  |-> lastPx.value,
         openClose               |-> openClose.value,
         side                    |-> side.value,
         targetPartyId           |-> targetPartyId.value,
         auctionId               |-> auctionId.value,
         clearingFirm            |-> clearingFirm.value,
         optionalData            |-> optionalData.value,
         routingFirmId           |-> routingFirmId.value,
         aiq                     |-> aiq.value,
         leavesQty               |-> leavesQty.value,
         cumQty                  |-> cumQty.value,
         lastQty                 |-> lastQty.value,
         tradeLiquidityIndicator |-> tradeLiquidityIndicator.value,
         feeCode                 |-> feeCode.value,
         reasonCodeOptional      |-> reasonCodeOptional.value,
         occId                   |-> occId.value,
         contraClearingAccount   |-> contraClearingAccount.value,
         contraClearingFirm      |-> contraClearingFirm.value,
         contraMpid              |-> contraMpid.value,
         contraOpenClose         |-> contraOpenClose.value,
         contraCustomerOrFirm    |-> contraCustomerOrFirm.value,
         contraOccId             |-> contraOccId.value ], contraOccId.rest)

ZeroExecutionReportMessage ==
    [ accountAccountOptional  |-> [i \in 1 .. 16 |-> 0],
      transactTime            |-> [i \in 1 .. 8 |-> 0],
      instrumentId            |-> [i \in 1 .. 4 |-> 0],
      marketParticipantId     |-> [i \in 1 .. 4 |-> 0],
      clOrdId                 |-> [i \in 1 .. 8 |-> 0],
      clearingAccountOptional |-> [i \in 1 .. 4 |-> 0],
      customerOrFirm          |-> [i \in 1 .. 1 |-> 0],
      orderId                 |-> [i \in 1 .. 8 |-> 0],
      execId                  |-> [i \in 1 .. 8 |-> 0],
      tradeId                 |-> [i \in 1 .. 8 |-> 0],
      lastPx                  |-> [i \in 1 .. 8 |-> 0],
      openClose               |-> [i \in 1 .. 1 |-> 0],
      side                    |-> [i \in 1 .. 1 |-> 0],
      targetPartyId           |-> [i \in 1 .. 4 |-> 0],
      auctionId               |-> [i \in 1 .. 4 |-> 0],
      clearingFirm            |-> [i \in 1 .. 4 |-> 0],
      optionalData            |-> [i \in 1 .. 16 |-> 0],
      routingFirmId           |-> [i \in 1 .. 4 |-> 0],
      aiq                     |-> [i \in 1 .. 3 |-> 0],
      leavesQty               |-> [i \in 1 .. 4 |-> 0],
      cumQty                  |-> [i \in 1 .. 4 |-> 0],
      lastQty                 |-> [i \in 1 .. 4 |-> 0],
      tradeLiquidityIndicator |-> [i \in 1 .. 1 |-> 0],
      feeCode                 |-> [i \in 1 .. 2 |-> 0],
      reasonCodeOptional      |-> [i \in 1 .. 1 |-> 0],
      occId                   |-> [i \in 1 .. 5 |-> 0],
      contraClearingAccount   |-> [i \in 1 .. 4 |-> 0],
      contraClearingFirm      |-> [i \in 1 .. 4 |-> 0],
      contraMpid              |-> [i \in 1 .. 4 |-> 0],
      contraOpenClose         |-> [i \in 1 .. 1 |-> 0],
      contraCustomerOrFirm    |-> [i \in 1 .. 1 |-> 0],
      contraOccId             |-> [i \in 1 .. 5 |-> 0] ]

(* Execution Report Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportMessage ==
    { ZeroExecutionReportMessage }
        \cup { [ZeroExecutionReportMessage EXCEPT !.accountAccountOptional = one] : one \in Sample(16) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.marketParticipantId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.clearingAccountOptional = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.customerOrFirm = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.targetPartyId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.auctionId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.optionalData = one] : one \in Sample(16) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.routingFirmId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.aiq = one] : one \in Sample(3) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.lastQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.tradeLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.feeCode = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.reasonCodeOptional = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.occId = one] : one \in Sample(5) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.contraClearingAccount = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.contraClearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.contraMpid = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.contraOpenClose = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.contraCustomerOrFirm = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.contraOccId = one] : one \in Sample(5) }

(***************************************************************************)
(* Trade Bust Correct Message: 86 bytes                                    *)
(***************************************************************************)

TradeBustCorrectMessage ==
    [ transactTime           : Sample(8),
      instrumentId           : Sample(4),
      marketParticipantId    : Sample(4),
      clOrdId                : Sample(8),
      orderId                : Sample(8),
      execId                 : Sample(8),
      tradeIdOptional        : Sample(8),
      tradeRefId             : Sample(8),
      lastPx                 : Sample(8),
      accountAccountOptional : Sample(16),
      lastQty                : Sample(4),
      reasonCodeOptional     : Sample(1),
      bustOrCorrection       : Sample(1) ]

EncodeTradeBustCorrectMessage(message) ==
    message.transactTime
        \o message.instrumentId
        \o message.marketParticipantId
        \o message.clOrdId
        \o message.orderId
        \o message.execId
        \o message.tradeIdOptional
        \o message.tradeRefId
        \o message.lastPx
        \o message.accountAccountOptional
        \o message.lastQty
        \o message.reasonCodeOptional
        \o message.bustOrCorrection

DecodeTradeBustCorrectMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(transactTime.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET marketParticipantId == ReadBytes(instrumentId.rest, 4) IN IF ~marketParticipantId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(marketParticipantId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clOrdId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET execId == ReadBytes(orderId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET tradeIdOptional == ReadBytes(execId.rest, 8) IN IF ~tradeIdOptional.ok THEN Fail ELSE
    LET tradeRefId == ReadBytes(tradeIdOptional.rest, 8) IN IF ~tradeRefId.ok THEN Fail ELSE
    LET lastPx == ReadBytes(tradeRefId.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET accountAccountOptional == ReadBytes(lastPx.rest, 16) IN IF ~accountAccountOptional.ok THEN Fail ELSE
    LET lastQty == ReadBytes(accountAccountOptional.rest, 4) IN IF ~lastQty.ok THEN Fail ELSE
    LET reasonCodeOptional == ReadBytes(lastQty.rest, 1) IN IF ~reasonCodeOptional.ok THEN Fail ELSE
    LET bustOrCorrection == ReadBytes(reasonCodeOptional.rest, 1) IN IF ~bustOrCorrection.ok THEN Fail ELSE
    Ok([ transactTime           |-> transactTime.value,
         instrumentId           |-> instrumentId.value,
         marketParticipantId    |-> marketParticipantId.value,
         clOrdId                |-> clOrdId.value,
         orderId                |-> orderId.value,
         execId                 |-> execId.value,
         tradeIdOptional        |-> tradeIdOptional.value,
         tradeRefId             |-> tradeRefId.value,
         lastPx                 |-> lastPx.value,
         accountAccountOptional |-> accountAccountOptional.value,
         lastQty                |-> lastQty.value,
         reasonCodeOptional     |-> reasonCodeOptional.value,
         bustOrCorrection       |-> bustOrCorrection.value ], bustOrCorrection.rest)

ZeroTradeBustCorrectMessage ==
    [ transactTime           |-> [i \in 1 .. 8 |-> 0],
      instrumentId           |-> [i \in 1 .. 4 |-> 0],
      marketParticipantId    |-> [i \in 1 .. 4 |-> 0],
      clOrdId                |-> [i \in 1 .. 8 |-> 0],
      orderId                |-> [i \in 1 .. 8 |-> 0],
      execId                 |-> [i \in 1 .. 8 |-> 0],
      tradeIdOptional        |-> [i \in 1 .. 8 |-> 0],
      tradeRefId             |-> [i \in 1 .. 8 |-> 0],
      lastPx                 |-> [i \in 1 .. 8 |-> 0],
      accountAccountOptional |-> [i \in 1 .. 16 |-> 0],
      lastQty                |-> [i \in 1 .. 4 |-> 0],
      reasonCodeOptional     |-> [i \in 1 .. 1 |-> 0],
      bustOrCorrection       |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Bust Correct Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeBustCorrectMessage ==
    { ZeroTradeBustCorrectMessage }
        \cup { [ZeroTradeBustCorrectMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustCorrectMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroTradeBustCorrectMessage EXCEPT !.marketParticipantId = one] : one \in Sample(4) }
        \cup { [ZeroTradeBustCorrectMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustCorrectMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustCorrectMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustCorrectMessage EXCEPT !.tradeIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustCorrectMessage EXCEPT !.tradeRefId = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustCorrectMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustCorrectMessage EXCEPT !.accountAccountOptional = one] : one \in Sample(16) }
        \cup { [ZeroTradeBustCorrectMessage EXCEPT !.lastQty = one] : one \in Sample(4) }
        \cup { [ZeroTradeBustCorrectMessage EXCEPT !.reasonCodeOptional = one] : one \in Sample(1) }
        \cup { [ZeroTradeBustCorrectMessage EXCEPT !.bustOrCorrection = one] : one \in Sample(1) }

(***************************************************************************)
(* Application Layer Reject Message: 47 bytes                              *)
(***************************************************************************)

ApplicationLayerRejectMessage ==
    [ transactTime                     : Sample(8),
      underlyingIdOptional             : Sample(4),
      instrumentIdInstrumentIdOptional : Sample(4),
      marketParticipantId              : Sample(4),
      clOrdId                          : Sample(8),
      accountString16Optional          : Sample(16),
      reasonCodeOptional               : Sample(1),
      rejectType                       : Sample(1),
      throttleIndicatorOptional        : Sample(1) ]

EncodeApplicationLayerRejectMessage(message) ==
    message.transactTime
        \o message.underlyingIdOptional
        \o message.instrumentIdInstrumentIdOptional
        \o message.marketParticipantId
        \o message.clOrdId
        \o message.accountString16Optional
        \o message.reasonCodeOptional
        \o message.rejectType
        \o message.throttleIndicatorOptional

DecodeApplicationLayerRejectMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET underlyingIdOptional == ReadBytes(transactTime.rest, 4) IN IF ~underlyingIdOptional.ok THEN Fail ELSE
    LET instrumentIdInstrumentIdOptional == ReadBytes(underlyingIdOptional.rest, 4) IN IF ~instrumentIdInstrumentIdOptional.ok THEN Fail ELSE
    LET marketParticipantId == ReadBytes(instrumentIdInstrumentIdOptional.rest, 4) IN IF ~marketParticipantId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(marketParticipantId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET accountString16Optional == ReadBytes(clOrdId.rest, 16) IN IF ~accountString16Optional.ok THEN Fail ELSE
    LET reasonCodeOptional == ReadBytes(accountString16Optional.rest, 1) IN IF ~reasonCodeOptional.ok THEN Fail ELSE
    LET rejectType == ReadBytes(reasonCodeOptional.rest, 1) IN IF ~rejectType.ok THEN Fail ELSE
    LET throttleIndicatorOptional == ReadBytes(rejectType.rest, 1) IN IF ~throttleIndicatorOptional.ok THEN Fail ELSE
    Ok([ transactTime                     |-> transactTime.value,
         underlyingIdOptional             |-> underlyingIdOptional.value,
         instrumentIdInstrumentIdOptional |-> instrumentIdInstrumentIdOptional.value,
         marketParticipantId              |-> marketParticipantId.value,
         clOrdId                          |-> clOrdId.value,
         accountString16Optional          |-> accountString16Optional.value,
         reasonCodeOptional               |-> reasonCodeOptional.value,
         rejectType                       |-> rejectType.value,
         throttleIndicatorOptional        |-> throttleIndicatorOptional.value ], throttleIndicatorOptional.rest)

ZeroApplicationLayerRejectMessage ==
    [ transactTime                     |-> [i \in 1 .. 8 |-> 0],
      underlyingIdOptional             |-> [i \in 1 .. 4 |-> 0],
      instrumentIdInstrumentIdOptional |-> [i \in 1 .. 4 |-> 0],
      marketParticipantId              |-> [i \in 1 .. 4 |-> 0],
      clOrdId                          |-> [i \in 1 .. 8 |-> 0],
      accountString16Optional          |-> [i \in 1 .. 16 |-> 0],
      reasonCodeOptional               |-> [i \in 1 .. 1 |-> 0],
      rejectType                       |-> [i \in 1 .. 1 |-> 0],
      throttleIndicatorOptional        |-> [i \in 1 .. 1 |-> 0] ]

(* Application Layer Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedApplicationLayerRejectMessage ==
    { ZeroApplicationLayerRejectMessage }
        \cup { [ZeroApplicationLayerRejectMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroApplicationLayerRejectMessage EXCEPT !.underlyingIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroApplicationLayerRejectMessage EXCEPT !.instrumentIdInstrumentIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroApplicationLayerRejectMessage EXCEPT !.marketParticipantId = one] : one \in Sample(4) }
        \cup { [ZeroApplicationLayerRejectMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroApplicationLayerRejectMessage EXCEPT !.accountString16Optional = one] : one \in Sample(16) }
        \cup { [ZeroApplicationLayerRejectMessage EXCEPT !.reasonCodeOptional = one] : one \in Sample(1) }
        \cup { [ZeroApplicationLayerRejectMessage EXCEPT !.rejectType = one] : one \in Sample(1) }
        \cup { [ZeroApplicationLayerRejectMessage EXCEPT !.throttleIndicatorOptional = one] : one \in Sample(1) }

(***************************************************************************)
(* Risk Limit Update Request Message: 36 bytes                             *)
(***************************************************************************)

RiskLimitUpdateRequestMessage ==
    [ underlyingIdOptional        : Sample(4),
      marketParticipantIdOptional : Sample(4),
      clOrdId                     : Sample(8),
      riskControlOptional         : Sample(1),
      riskControlStatus           : Sample(1),
      timeLimit                   : Sample(8),
      percentageLimit             : Sample(4),
      countLimit                  : Sample(4),
      iocAttribution              : Sample(1),
      custCapacityWeight          : Sample(1) ]

EncodeRiskLimitUpdateRequestMessage(message) ==
    message.underlyingIdOptional
        \o message.marketParticipantIdOptional
        \o message.clOrdId
        \o message.riskControlOptional
        \o message.riskControlStatus
        \o message.timeLimit
        \o message.percentageLimit
        \o message.countLimit
        \o message.iocAttribution
        \o message.custCapacityWeight

DecodeRiskLimitUpdateRequestMessage(bytes) ==
    LET underlyingIdOptional == ReadBytes(bytes, 4) IN IF ~underlyingIdOptional.ok THEN Fail ELSE
    LET marketParticipantIdOptional == ReadBytes(underlyingIdOptional.rest, 4) IN IF ~marketParticipantIdOptional.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(marketParticipantIdOptional.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET riskControlOptional == ReadBytes(clOrdId.rest, 1) IN IF ~riskControlOptional.ok THEN Fail ELSE
    LET riskControlStatus == ReadBytes(riskControlOptional.rest, 1) IN IF ~riskControlStatus.ok THEN Fail ELSE
    LET timeLimit == ReadBytes(riskControlStatus.rest, 8) IN IF ~timeLimit.ok THEN Fail ELSE
    LET percentageLimit == ReadBytes(timeLimit.rest, 4) IN IF ~percentageLimit.ok THEN Fail ELSE
    LET countLimit == ReadBytes(percentageLimit.rest, 4) IN IF ~countLimit.ok THEN Fail ELSE
    LET iocAttribution == ReadBytes(countLimit.rest, 1) IN IF ~iocAttribution.ok THEN Fail ELSE
    LET custCapacityWeight == ReadBytes(iocAttribution.rest, 1) IN IF ~custCapacityWeight.ok THEN Fail ELSE
    Ok([ underlyingIdOptional        |-> underlyingIdOptional.value,
         marketParticipantIdOptional |-> marketParticipantIdOptional.value,
         clOrdId                     |-> clOrdId.value,
         riskControlOptional         |-> riskControlOptional.value,
         riskControlStatus           |-> riskControlStatus.value,
         timeLimit                   |-> timeLimit.value,
         percentageLimit             |-> percentageLimit.value,
         countLimit                  |-> countLimit.value,
         iocAttribution              |-> iocAttribution.value,
         custCapacityWeight          |-> custCapacityWeight.value ], custCapacityWeight.rest)

ZeroRiskLimitUpdateRequestMessage ==
    [ underlyingIdOptional        |-> [i \in 1 .. 4 |-> 0],
      marketParticipantIdOptional |-> [i \in 1 .. 4 |-> 0],
      clOrdId                     |-> [i \in 1 .. 8 |-> 0],
      riskControlOptional         |-> [i \in 1 .. 1 |-> 0],
      riskControlStatus           |-> [i \in 1 .. 1 |-> 0],
      timeLimit                   |-> [i \in 1 .. 8 |-> 0],
      percentageLimit             |-> [i \in 1 .. 4 |-> 0],
      countLimit                  |-> [i \in 1 .. 4 |-> 0],
      iocAttribution              |-> [i \in 1 .. 1 |-> 0],
      custCapacityWeight          |-> [i \in 1 .. 1 |-> 0] ]

(* Risk Limit Update Request Message at zero, then each field in turn at the values it is checked at *)
CheckedRiskLimitUpdateRequestMessage ==
    { ZeroRiskLimitUpdateRequestMessage }
        \cup { [ZeroRiskLimitUpdateRequestMessage EXCEPT !.underlyingIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroRiskLimitUpdateRequestMessage EXCEPT !.marketParticipantIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroRiskLimitUpdateRequestMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroRiskLimitUpdateRequestMessage EXCEPT !.riskControlOptional = one] : one \in Sample(1) }
        \cup { [ZeroRiskLimitUpdateRequestMessage EXCEPT !.riskControlStatus = one] : one \in Sample(1) }
        \cup { [ZeroRiskLimitUpdateRequestMessage EXCEPT !.timeLimit = one] : one \in Sample(8) }
        \cup { [ZeroRiskLimitUpdateRequestMessage EXCEPT !.percentageLimit = one] : one \in Sample(4) }
        \cup { [ZeroRiskLimitUpdateRequestMessage EXCEPT !.countLimit = one] : one \in Sample(4) }
        \cup { [ZeroRiskLimitUpdateRequestMessage EXCEPT !.iocAttribution = one] : one \in Sample(1) }
        \cup { [ZeroRiskLimitUpdateRequestMessage EXCEPT !.custCapacityWeight = one] : one \in Sample(1) }

(***************************************************************************)
(* Risk Action Request Message: 20 bytes                                   *)
(***************************************************************************)

RiskActionRequestMessage ==
    [ underlyingIdOptional        : Sample(4),
      marketParticipantIdOptional : Sample(4),
      clOrdId                     : Sample(8),
      riskControl                 : Sample(1),
      riskAction                  : Sample(1),
      customGroupIdOptional       : Sample(2) ]

EncodeRiskActionRequestMessage(message) ==
    message.underlyingIdOptional
        \o message.marketParticipantIdOptional
        \o message.clOrdId
        \o message.riskControl
        \o message.riskAction
        \o message.customGroupIdOptional

DecodeRiskActionRequestMessage(bytes) ==
    LET underlyingIdOptional == ReadBytes(bytes, 4) IN IF ~underlyingIdOptional.ok THEN Fail ELSE
    LET marketParticipantIdOptional == ReadBytes(underlyingIdOptional.rest, 4) IN IF ~marketParticipantIdOptional.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(marketParticipantIdOptional.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET riskControl == ReadBytes(clOrdId.rest, 1) IN IF ~riskControl.ok THEN Fail ELSE
    LET riskAction == ReadBytes(riskControl.rest, 1) IN IF ~riskAction.ok THEN Fail ELSE
    LET customGroupIdOptional == ReadBytes(riskAction.rest, 2) IN IF ~customGroupIdOptional.ok THEN Fail ELSE
    Ok([ underlyingIdOptional        |-> underlyingIdOptional.value,
         marketParticipantIdOptional |-> marketParticipantIdOptional.value,
         clOrdId                     |-> clOrdId.value,
         riskControl                 |-> riskControl.value,
         riskAction                  |-> riskAction.value,
         customGroupIdOptional       |-> customGroupIdOptional.value ], customGroupIdOptional.rest)

ZeroRiskActionRequestMessage ==
    [ underlyingIdOptional        |-> [i \in 1 .. 4 |-> 0],
      marketParticipantIdOptional |-> [i \in 1 .. 4 |-> 0],
      clOrdId                     |-> [i \in 1 .. 8 |-> 0],
      riskControl                 |-> [i \in 1 .. 1 |-> 0],
      riskAction                  |-> [i \in 1 .. 1 |-> 0],
      customGroupIdOptional       |-> [i \in 1 .. 2 |-> 0] ]

(* Risk Action Request Message at zero, then each field in turn at the values it is checked at *)
CheckedRiskActionRequestMessage ==
    { ZeroRiskActionRequestMessage }
        \cup { [ZeroRiskActionRequestMessage EXCEPT !.underlyingIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroRiskActionRequestMessage EXCEPT !.marketParticipantIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroRiskActionRequestMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroRiskActionRequestMessage EXCEPT !.riskControl = one] : one \in Sample(1) }
        \cup { [ZeroRiskActionRequestMessage EXCEPT !.riskAction = one] : one \in Sample(1) }
        \cup { [ZeroRiskActionRequestMessage EXCEPT !.customGroupIdOptional = one] : one \in Sample(2) }

(***************************************************************************)
(* Underlying Ref Data Message: 25 bytes                                   *)
(***************************************************************************)

UnderlyingRefDataMessage ==
    [ transactTime     : Sample(8),
      underlyingId     : Sample(4),
      underlyingSymbol : Sample(8),
      mic              : Sample(4),
      mpvGroup         : Sample(1) ]

EncodeUnderlyingRefDataMessage(message) ==
    message.transactTime
        \o message.underlyingId
        \o message.underlyingSymbol
        \o message.mic
        \o message.mpvGroup

DecodeUnderlyingRefDataMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET underlyingId == ReadBytes(transactTime.rest, 4) IN IF ~underlyingId.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(underlyingId.rest, 8) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET mic == ReadBytes(underlyingSymbol.rest, 4) IN IF ~mic.ok THEN Fail ELSE
    LET mpvGroup == ReadBytes(mic.rest, 1) IN IF ~mpvGroup.ok THEN Fail ELSE
    Ok([ transactTime     |-> transactTime.value,
         underlyingId     |-> underlyingId.value,
         underlyingSymbol |-> underlyingSymbol.value,
         mic              |-> mic.value,
         mpvGroup         |-> mpvGroup.value ], mpvGroup.rest)

ZeroUnderlyingRefDataMessage ==
    [ transactTime     |-> [i \in 1 .. 8 |-> 0],
      underlyingId     |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbol |-> [i \in 1 .. 8 |-> 0],
      mic              |-> [i \in 1 .. 4 |-> 0],
      mpvGroup         |-> [i \in 1 .. 1 |-> 0] ]

(* Underlying Ref Data Message at zero, then each field in turn at the values it is checked at *)
CheckedUnderlyingRefDataMessage ==
    { ZeroUnderlyingRefDataMessage }
        \cup { [ZeroUnderlyingRefDataMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroUnderlyingRefDataMessage EXCEPT !.underlyingId = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingRefDataMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(8) }
        \cup { [ZeroUnderlyingRefDataMessage EXCEPT !.mic = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingRefDataMessage EXCEPT !.mpvGroup = one] : one \in Sample(1) }

(***************************************************************************)
(* Instrument Ref Data Message: 59 bytes                                   *)
(***************************************************************************)

InstrumentRefDataMessage ==
    [ transactTime : Sample(8),
      instrumentId : Sample(4),
      underlyingId : Sample(4),
      osiSymbol    : Sample(21),
      maturityDate : Sample(8),
      optionType   : Sample(1),
      strikePrice  : Sample(8),
      closingOnly  : Sample(1),
      orpEnabled   : Sample(1),
      tradingRing  : Sample(1),
      matchingUnit : Sample(2) ]

EncodeInstrumentRefDataMessage(message) ==
    message.transactTime
        \o message.instrumentId
        \o message.underlyingId
        \o message.osiSymbol
        \o message.maturityDate
        \o message.optionType
        \o message.strikePrice
        \o message.closingOnly
        \o message.orpEnabled
        \o message.tradingRing
        \o message.matchingUnit

DecodeInstrumentRefDataMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(transactTime.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET underlyingId == ReadBytes(instrumentId.rest, 4) IN IF ~underlyingId.ok THEN Fail ELSE
    LET osiSymbol == ReadBytes(underlyingId.rest, 21) IN IF ~osiSymbol.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(osiSymbol.rest, 8) IN IF ~maturityDate.ok THEN Fail ELSE
    LET optionType == ReadBytes(maturityDate.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(optionType.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET closingOnly == ReadBytes(strikePrice.rest, 1) IN IF ~closingOnly.ok THEN Fail ELSE
    LET orpEnabled == ReadBytes(closingOnly.rest, 1) IN IF ~orpEnabled.ok THEN Fail ELSE
    LET tradingRing == ReadBytes(orpEnabled.rest, 1) IN IF ~tradingRing.ok THEN Fail ELSE
    LET matchingUnit == ReadBytes(tradingRing.rest, 2) IN IF ~matchingUnit.ok THEN Fail ELSE
    Ok([ transactTime |-> transactTime.value,
         instrumentId |-> instrumentId.value,
         underlyingId |-> underlyingId.value,
         osiSymbol    |-> osiSymbol.value,
         maturityDate |-> maturityDate.value,
         optionType   |-> optionType.value,
         strikePrice  |-> strikePrice.value,
         closingOnly  |-> closingOnly.value,
         orpEnabled   |-> orpEnabled.value,
         tradingRing  |-> tradingRing.value,
         matchingUnit |-> matchingUnit.value ], matchingUnit.rest)

ZeroInstrumentRefDataMessage ==
    [ transactTime |-> [i \in 1 .. 8 |-> 0],
      instrumentId |-> [i \in 1 .. 4 |-> 0],
      underlyingId |-> [i \in 1 .. 4 |-> 0],
      osiSymbol    |-> [i \in 1 .. 21 |-> 0],
      maturityDate |-> [i \in 1 .. 8 |-> 0],
      optionType   |-> [i \in 1 .. 1 |-> 0],
      strikePrice  |-> [i \in 1 .. 8 |-> 0],
      closingOnly  |-> [i \in 1 .. 1 |-> 0],
      orpEnabled   |-> [i \in 1 .. 1 |-> 0],
      tradingRing  |-> [i \in 1 .. 1 |-> 0],
      matchingUnit |-> [i \in 1 .. 2 |-> 0] ]

(* Instrument Ref Data Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentRefDataMessage ==
    { ZeroInstrumentRefDataMessage }
        \cup { [ZeroInstrumentRefDataMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentRefDataMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentRefDataMessage EXCEPT !.underlyingId = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentRefDataMessage EXCEPT !.osiSymbol = one] : one \in Sample(21) }
        \cup { [ZeroInstrumentRefDataMessage EXCEPT !.maturityDate = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentRefDataMessage EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentRefDataMessage EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentRefDataMessage EXCEPT !.closingOnly = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentRefDataMessage EXCEPT !.orpEnabled = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentRefDataMessage EXCEPT !.tradingRing = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentRefDataMessage EXCEPT !.matchingUnit = one] : one \in Sample(2) }

(***************************************************************************)
(* Mpid Configuration Acknowledgement Message: 76 bytes                    *)
(***************************************************************************)

MpidConfigurationAcknowledgementMessage ==
    [ transactTime           : Sample(8),
      marketParticipantId    : Sample(4),
      mpidStatus             : Sample(1),
      member                 : Sample(8),
      maxQty                 : Sample(4),
      maxNotional            : Sample(8),
      defaultAccount         : Sample(16),
      defaultOptionalData    : Sample(16),
      defaultClearingAccount : Sample(4),
      allowMarketOrders      : Sample(1),
      allowIsoioc            : Sample(1),
      allowIsoDay            : Sample(1),
      maxDuplicative         : Sample(4) ]

EncodeMpidConfigurationAcknowledgementMessage(message) ==
    message.transactTime
        \o message.marketParticipantId
        \o message.mpidStatus
        \o message.member
        \o message.maxQty
        \o message.maxNotional
        \o message.defaultAccount
        \o message.defaultOptionalData
        \o message.defaultClearingAccount
        \o message.allowMarketOrders
        \o message.allowIsoioc
        \o message.allowIsoDay
        \o message.maxDuplicative

DecodeMpidConfigurationAcknowledgementMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET marketParticipantId == ReadBytes(transactTime.rest, 4) IN IF ~marketParticipantId.ok THEN Fail ELSE
    LET mpidStatus == ReadBytes(marketParticipantId.rest, 1) IN IF ~mpidStatus.ok THEN Fail ELSE
    LET member == ReadBytes(mpidStatus.rest, 8) IN IF ~member.ok THEN Fail ELSE
    LET maxQty == ReadBytes(member.rest, 4) IN IF ~maxQty.ok THEN Fail ELSE
    LET maxNotional == ReadBytes(maxQty.rest, 8) IN IF ~maxNotional.ok THEN Fail ELSE
    LET defaultAccount == ReadBytes(maxNotional.rest, 16) IN IF ~defaultAccount.ok THEN Fail ELSE
    LET defaultOptionalData == ReadBytes(defaultAccount.rest, 16) IN IF ~defaultOptionalData.ok THEN Fail ELSE
    LET defaultClearingAccount == ReadBytes(defaultOptionalData.rest, 4) IN IF ~defaultClearingAccount.ok THEN Fail ELSE
    LET allowMarketOrders == ReadBytes(defaultClearingAccount.rest, 1) IN IF ~allowMarketOrders.ok THEN Fail ELSE
    LET allowIsoioc == ReadBytes(allowMarketOrders.rest, 1) IN IF ~allowIsoioc.ok THEN Fail ELSE
    LET allowIsoDay == ReadBytes(allowIsoioc.rest, 1) IN IF ~allowIsoDay.ok THEN Fail ELSE
    LET maxDuplicative == ReadBytes(allowIsoDay.rest, 4) IN IF ~maxDuplicative.ok THEN Fail ELSE
    Ok([ transactTime           |-> transactTime.value,
         marketParticipantId    |-> marketParticipantId.value,
         mpidStatus             |-> mpidStatus.value,
         member                 |-> member.value,
         maxQty                 |-> maxQty.value,
         maxNotional            |-> maxNotional.value,
         defaultAccount         |-> defaultAccount.value,
         defaultOptionalData    |-> defaultOptionalData.value,
         defaultClearingAccount |-> defaultClearingAccount.value,
         allowMarketOrders      |-> allowMarketOrders.value,
         allowIsoioc            |-> allowIsoioc.value,
         allowIsoDay            |-> allowIsoDay.value,
         maxDuplicative         |-> maxDuplicative.value ], maxDuplicative.rest)

ZeroMpidConfigurationAcknowledgementMessage ==
    [ transactTime           |-> [i \in 1 .. 8 |-> 0],
      marketParticipantId    |-> [i \in 1 .. 4 |-> 0],
      mpidStatus             |-> [i \in 1 .. 1 |-> 0],
      member                 |-> [i \in 1 .. 8 |-> 0],
      maxQty                 |-> [i \in 1 .. 4 |-> 0],
      maxNotional            |-> [i \in 1 .. 8 |-> 0],
      defaultAccount         |-> [i \in 1 .. 16 |-> 0],
      defaultOptionalData    |-> [i \in 1 .. 16 |-> 0],
      defaultClearingAccount |-> [i \in 1 .. 4 |-> 0],
      allowMarketOrders      |-> [i \in 1 .. 1 |-> 0],
      allowIsoioc            |-> [i \in 1 .. 1 |-> 0],
      allowIsoDay            |-> [i \in 1 .. 1 |-> 0],
      maxDuplicative         |-> [i \in 1 .. 4 |-> 0] ]

(* Mpid Configuration Acknowledgement Message at zero, then each field in turn at the values it is checked at *)
CheckedMpidConfigurationAcknowledgementMessage ==
    { ZeroMpidConfigurationAcknowledgementMessage }
        \cup { [ZeroMpidConfigurationAcknowledgementMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroMpidConfigurationAcknowledgementMessage EXCEPT !.marketParticipantId = one] : one \in Sample(4) }
        \cup { [ZeroMpidConfigurationAcknowledgementMessage EXCEPT !.mpidStatus = one] : one \in Sample(1) }
        \cup { [ZeroMpidConfigurationAcknowledgementMessage EXCEPT !.member = one] : one \in Sample(8) }
        \cup { [ZeroMpidConfigurationAcknowledgementMessage EXCEPT !.maxQty = one] : one \in Sample(4) }
        \cup { [ZeroMpidConfigurationAcknowledgementMessage EXCEPT !.maxNotional = one] : one \in Sample(8) }
        \cup { [ZeroMpidConfigurationAcknowledgementMessage EXCEPT !.defaultAccount = one] : one \in Sample(16) }
        \cup { [ZeroMpidConfigurationAcknowledgementMessage EXCEPT !.defaultOptionalData = one] : one \in Sample(16) }
        \cup { [ZeroMpidConfigurationAcknowledgementMessage EXCEPT !.defaultClearingAccount = one] : one \in Sample(4) }
        \cup { [ZeroMpidConfigurationAcknowledgementMessage EXCEPT !.allowMarketOrders = one] : one \in Sample(1) }
        \cup { [ZeroMpidConfigurationAcknowledgementMessage EXCEPT !.allowIsoioc = one] : one \in Sample(1) }
        \cup { [ZeroMpidConfigurationAcknowledgementMessage EXCEPT !.allowIsoDay = one] : one \in Sample(1) }
        \cup { [ZeroMpidConfigurationAcknowledgementMessage EXCEPT !.maxDuplicative = one] : one \in Sample(4) }

(***************************************************************************)
(* Market Maker Symbol Appointment Message: 26 bytes                       *)
(***************************************************************************)

MarketMakerSymbolAppointmentMessage ==
    [ transactTime        : Sample(8),
      underlyingId        : Sample(4),
      marketParticipantId : Sample(4),
      appointmentType     : Sample(1),
      appointmentStatus   : Sample(1),
      maxAllowableWidth   : Sample(4),
      quoteReliefMult     : Sample(4) ]

EncodeMarketMakerSymbolAppointmentMessage(message) ==
    message.transactTime
        \o message.underlyingId
        \o message.marketParticipantId
        \o message.appointmentType
        \o message.appointmentStatus
        \o message.maxAllowableWidth
        \o message.quoteReliefMult

DecodeMarketMakerSymbolAppointmentMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET underlyingId == ReadBytes(transactTime.rest, 4) IN IF ~underlyingId.ok THEN Fail ELSE
    LET marketParticipantId == ReadBytes(underlyingId.rest, 4) IN IF ~marketParticipantId.ok THEN Fail ELSE
    LET appointmentType == ReadBytes(marketParticipantId.rest, 1) IN IF ~appointmentType.ok THEN Fail ELSE
    LET appointmentStatus == ReadBytes(appointmentType.rest, 1) IN IF ~appointmentStatus.ok THEN Fail ELSE
    LET maxAllowableWidth == ReadBytes(appointmentStatus.rest, 4) IN IF ~maxAllowableWidth.ok THEN Fail ELSE
    LET quoteReliefMult == ReadBytes(maxAllowableWidth.rest, 4) IN IF ~quoteReliefMult.ok THEN Fail ELSE
    Ok([ transactTime        |-> transactTime.value,
         underlyingId        |-> underlyingId.value,
         marketParticipantId |-> marketParticipantId.value,
         appointmentType     |-> appointmentType.value,
         appointmentStatus   |-> appointmentStatus.value,
         maxAllowableWidth   |-> maxAllowableWidth.value,
         quoteReliefMult     |-> quoteReliefMult.value ], quoteReliefMult.rest)

ZeroMarketMakerSymbolAppointmentMessage ==
    [ transactTime        |-> [i \in 1 .. 8 |-> 0],
      underlyingId        |-> [i \in 1 .. 4 |-> 0],
      marketParticipantId |-> [i \in 1 .. 4 |-> 0],
      appointmentType     |-> [i \in 1 .. 1 |-> 0],
      appointmentStatus   |-> [i \in 1 .. 1 |-> 0],
      maxAllowableWidth   |-> [i \in 1 .. 4 |-> 0],
      quoteReliefMult     |-> [i \in 1 .. 4 |-> 0] ]

(* Market Maker Symbol Appointment Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketMakerSymbolAppointmentMessage ==
    { ZeroMarketMakerSymbolAppointmentMessage }
        \cup { [ZeroMarketMakerSymbolAppointmentMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroMarketMakerSymbolAppointmentMessage EXCEPT !.underlyingId = one] : one \in Sample(4) }
        \cup { [ZeroMarketMakerSymbolAppointmentMessage EXCEPT !.marketParticipantId = one] : one \in Sample(4) }
        \cup { [ZeroMarketMakerSymbolAppointmentMessage EXCEPT !.appointmentType = one] : one \in Sample(1) }
        \cup { [ZeroMarketMakerSymbolAppointmentMessage EXCEPT !.appointmentStatus = one] : one \in Sample(1) }
        \cup { [ZeroMarketMakerSymbolAppointmentMessage EXCEPT !.maxAllowableWidth = one] : one \in Sample(4) }
        \cup { [ZeroMarketMakerSymbolAppointmentMessage EXCEPT !.quoteReliefMult = one] : one \in Sample(4) }

(***************************************************************************)
(* Session Configuration Acknowledgement Message: 35 bytes                 *)
(***************************************************************************)

SessionConfigurationAcknowledgementMessage ==
    [ transactTime                    : Sample(8),
      userSessionType                 : Sample(1),
      userSessionStatus               : Sample(1),
      member                          : Sample(8),
      defaultMpid                     : Sample(4),
      mic                             : Sample(4),
      cancelOnDisconnect              : Sample(1),
      aiqDefault                      : Sample(3),
      orderUnsolicitedAckSubscription : Sample(1),
      quoteUnsolicitedAckSubscription : Sample(1),
      defaultAttributedQuote          : Sample(1),
      defaultCancelInsteadOfSlide     : Sample(1),
      tradingRingOptional             : Sample(1) ]

EncodeSessionConfigurationAcknowledgementMessage(message) ==
    message.transactTime
        \o message.userSessionType
        \o message.userSessionStatus
        \o message.member
        \o message.defaultMpid
        \o message.mic
        \o message.cancelOnDisconnect
        \o message.aiqDefault
        \o message.orderUnsolicitedAckSubscription
        \o message.quoteUnsolicitedAckSubscription
        \o message.defaultAttributedQuote
        \o message.defaultCancelInsteadOfSlide
        \o message.tradingRingOptional

DecodeSessionConfigurationAcknowledgementMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET userSessionType == ReadBytes(transactTime.rest, 1) IN IF ~userSessionType.ok THEN Fail ELSE
    LET userSessionStatus == ReadBytes(userSessionType.rest, 1) IN IF ~userSessionStatus.ok THEN Fail ELSE
    LET member == ReadBytes(userSessionStatus.rest, 8) IN IF ~member.ok THEN Fail ELSE
    LET defaultMpid == ReadBytes(member.rest, 4) IN IF ~defaultMpid.ok THEN Fail ELSE
    LET mic == ReadBytes(defaultMpid.rest, 4) IN IF ~mic.ok THEN Fail ELSE
    LET cancelOnDisconnect == ReadBytes(mic.rest, 1) IN IF ~cancelOnDisconnect.ok THEN Fail ELSE
    LET aiqDefault == ReadBytes(cancelOnDisconnect.rest, 3) IN IF ~aiqDefault.ok THEN Fail ELSE
    LET orderUnsolicitedAckSubscription == ReadBytes(aiqDefault.rest, 1) IN IF ~orderUnsolicitedAckSubscription.ok THEN Fail ELSE
    LET quoteUnsolicitedAckSubscription == ReadBytes(orderUnsolicitedAckSubscription.rest, 1) IN IF ~quoteUnsolicitedAckSubscription.ok THEN Fail ELSE
    LET defaultAttributedQuote == ReadBytes(quoteUnsolicitedAckSubscription.rest, 1) IN IF ~defaultAttributedQuote.ok THEN Fail ELSE
    LET defaultCancelInsteadOfSlide == ReadBytes(defaultAttributedQuote.rest, 1) IN IF ~defaultCancelInsteadOfSlide.ok THEN Fail ELSE
    LET tradingRingOptional == ReadBytes(defaultCancelInsteadOfSlide.rest, 1) IN IF ~tradingRingOptional.ok THEN Fail ELSE
    Ok([ transactTime                    |-> transactTime.value,
         userSessionType                 |-> userSessionType.value,
         userSessionStatus               |-> userSessionStatus.value,
         member                          |-> member.value,
         defaultMpid                     |-> defaultMpid.value,
         mic                             |-> mic.value,
         cancelOnDisconnect              |-> cancelOnDisconnect.value,
         aiqDefault                      |-> aiqDefault.value,
         orderUnsolicitedAckSubscription |-> orderUnsolicitedAckSubscription.value,
         quoteUnsolicitedAckSubscription |-> quoteUnsolicitedAckSubscription.value,
         defaultAttributedQuote          |-> defaultAttributedQuote.value,
         defaultCancelInsteadOfSlide     |-> defaultCancelInsteadOfSlide.value,
         tradingRingOptional             |-> tradingRingOptional.value ], tradingRingOptional.rest)

ZeroSessionConfigurationAcknowledgementMessage ==
    [ transactTime                    |-> [i \in 1 .. 8 |-> 0],
      userSessionType                 |-> [i \in 1 .. 1 |-> 0],
      userSessionStatus               |-> [i \in 1 .. 1 |-> 0],
      member                          |-> [i \in 1 .. 8 |-> 0],
      defaultMpid                     |-> [i \in 1 .. 4 |-> 0],
      mic                             |-> [i \in 1 .. 4 |-> 0],
      cancelOnDisconnect              |-> [i \in 1 .. 1 |-> 0],
      aiqDefault                      |-> [i \in 1 .. 3 |-> 0],
      orderUnsolicitedAckSubscription |-> [i \in 1 .. 1 |-> 0],
      quoteUnsolicitedAckSubscription |-> [i \in 1 .. 1 |-> 0],
      defaultAttributedQuote          |-> [i \in 1 .. 1 |-> 0],
      defaultCancelInsteadOfSlide     |-> [i \in 1 .. 1 |-> 0],
      tradingRingOptional             |-> [i \in 1 .. 1 |-> 0] ]

(* Session Configuration Acknowledgement Message at zero, then each field in turn at the values it is checked at *)
CheckedSessionConfigurationAcknowledgementMessage ==
    { ZeroSessionConfigurationAcknowledgementMessage }
        \cup { [ZeroSessionConfigurationAcknowledgementMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroSessionConfigurationAcknowledgementMessage EXCEPT !.userSessionType = one] : one \in Sample(1) }
        \cup { [ZeroSessionConfigurationAcknowledgementMessage EXCEPT !.userSessionStatus = one] : one \in Sample(1) }
        \cup { [ZeroSessionConfigurationAcknowledgementMessage EXCEPT !.member = one] : one \in Sample(8) }
        \cup { [ZeroSessionConfigurationAcknowledgementMessage EXCEPT !.defaultMpid = one] : one \in Sample(4) }
        \cup { [ZeroSessionConfigurationAcknowledgementMessage EXCEPT !.mic = one] : one \in Sample(4) }
        \cup { [ZeroSessionConfigurationAcknowledgementMessage EXCEPT !.cancelOnDisconnect = one] : one \in Sample(1) }
        \cup { [ZeroSessionConfigurationAcknowledgementMessage EXCEPT !.aiqDefault = one] : one \in Sample(3) }
        \cup { [ZeroSessionConfigurationAcknowledgementMessage EXCEPT !.orderUnsolicitedAckSubscription = one] : one \in Sample(1) }
        \cup { [ZeroSessionConfigurationAcknowledgementMessage EXCEPT !.quoteUnsolicitedAckSubscription = one] : one \in Sample(1) }
        \cup { [ZeroSessionConfigurationAcknowledgementMessage EXCEPT !.defaultAttributedQuote = one] : one \in Sample(1) }
        \cup { [ZeroSessionConfigurationAcknowledgementMessage EXCEPT !.defaultCancelInsteadOfSlide = one] : one \in Sample(1) }
        \cup { [ZeroSessionConfigurationAcknowledgementMessage EXCEPT !.tradingRingOptional = one] : one \in Sample(1) }

(***************************************************************************)
(* Risk Control Acknowledgment Message: 50 bytes                           *)
(***************************************************************************)

RiskControlAcknowledgmentMessage ==
    [ transactTime             : Sample(8),
      underlyingIdOptional     : Sample(4),
      marketParticipantId      : Sample(4),
      clOrdId                  : Sample(8),
      customGroupIdOptional    : Sample(2),
      riskAckType              : Sample(1),
      riskControlStatus        : Sample(1),
      riskControl              : Sample(1),
      riskActionOptional       : Sample(1),
      timeLimit                : Sample(8),
      percentageLimit          : Sample(4),
      countLimit               : Sample(4),
      iocAttribution           : Sample(1),
      blockedByBreachIndicator : Sample(1),
      custCapacityWeight       : Sample(1),
      throttleIndicator        : Sample(1) ]

EncodeRiskControlAcknowledgmentMessage(message) ==
    message.transactTime
        \o message.underlyingIdOptional
        \o message.marketParticipantId
        \o message.clOrdId
        \o message.customGroupIdOptional
        \o message.riskAckType
        \o message.riskControlStatus
        \o message.riskControl
        \o message.riskActionOptional
        \o message.timeLimit
        \o message.percentageLimit
        \o message.countLimit
        \o message.iocAttribution
        \o message.blockedByBreachIndicator
        \o message.custCapacityWeight
        \o message.throttleIndicator

DecodeRiskControlAcknowledgmentMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET underlyingIdOptional == ReadBytes(transactTime.rest, 4) IN IF ~underlyingIdOptional.ok THEN Fail ELSE
    LET marketParticipantId == ReadBytes(underlyingIdOptional.rest, 4) IN IF ~marketParticipantId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(marketParticipantId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET customGroupIdOptional == ReadBytes(clOrdId.rest, 2) IN IF ~customGroupIdOptional.ok THEN Fail ELSE
    LET riskAckType == ReadBytes(customGroupIdOptional.rest, 1) IN IF ~riskAckType.ok THEN Fail ELSE
    LET riskControlStatus == ReadBytes(riskAckType.rest, 1) IN IF ~riskControlStatus.ok THEN Fail ELSE
    LET riskControl == ReadBytes(riskControlStatus.rest, 1) IN IF ~riskControl.ok THEN Fail ELSE
    LET riskActionOptional == ReadBytes(riskControl.rest, 1) IN IF ~riskActionOptional.ok THEN Fail ELSE
    LET timeLimit == ReadBytes(riskActionOptional.rest, 8) IN IF ~timeLimit.ok THEN Fail ELSE
    LET percentageLimit == ReadBytes(timeLimit.rest, 4) IN IF ~percentageLimit.ok THEN Fail ELSE
    LET countLimit == ReadBytes(percentageLimit.rest, 4) IN IF ~countLimit.ok THEN Fail ELSE
    LET iocAttribution == ReadBytes(countLimit.rest, 1) IN IF ~iocAttribution.ok THEN Fail ELSE
    LET blockedByBreachIndicator == ReadBytes(iocAttribution.rest, 1) IN IF ~blockedByBreachIndicator.ok THEN Fail ELSE
    LET custCapacityWeight == ReadBytes(blockedByBreachIndicator.rest, 1) IN IF ~custCapacityWeight.ok THEN Fail ELSE
    LET throttleIndicator == ReadBytes(custCapacityWeight.rest, 1) IN IF ~throttleIndicator.ok THEN Fail ELSE
    Ok([ transactTime             |-> transactTime.value,
         underlyingIdOptional     |-> underlyingIdOptional.value,
         marketParticipantId      |-> marketParticipantId.value,
         clOrdId                  |-> clOrdId.value,
         customGroupIdOptional    |-> customGroupIdOptional.value,
         riskAckType              |-> riskAckType.value,
         riskControlStatus        |-> riskControlStatus.value,
         riskControl              |-> riskControl.value,
         riskActionOptional       |-> riskActionOptional.value,
         timeLimit                |-> timeLimit.value,
         percentageLimit          |-> percentageLimit.value,
         countLimit               |-> countLimit.value,
         iocAttribution           |-> iocAttribution.value,
         blockedByBreachIndicator |-> blockedByBreachIndicator.value,
         custCapacityWeight       |-> custCapacityWeight.value,
         throttleIndicator        |-> throttleIndicator.value ], throttleIndicator.rest)

ZeroRiskControlAcknowledgmentMessage ==
    [ transactTime             |-> [i \in 1 .. 8 |-> 0],
      underlyingIdOptional     |-> [i \in 1 .. 4 |-> 0],
      marketParticipantId      |-> [i \in 1 .. 4 |-> 0],
      clOrdId                  |-> [i \in 1 .. 8 |-> 0],
      customGroupIdOptional    |-> [i \in 1 .. 2 |-> 0],
      riskAckType              |-> [i \in 1 .. 1 |-> 0],
      riskControlStatus        |-> [i \in 1 .. 1 |-> 0],
      riskControl              |-> [i \in 1 .. 1 |-> 0],
      riskActionOptional       |-> [i \in 1 .. 1 |-> 0],
      timeLimit                |-> [i \in 1 .. 8 |-> 0],
      percentageLimit          |-> [i \in 1 .. 4 |-> 0],
      countLimit               |-> [i \in 1 .. 4 |-> 0],
      iocAttribution           |-> [i \in 1 .. 1 |-> 0],
      blockedByBreachIndicator |-> [i \in 1 .. 1 |-> 0],
      custCapacityWeight       |-> [i \in 1 .. 1 |-> 0],
      throttleIndicator        |-> [i \in 1 .. 1 |-> 0] ]

(* Risk Control Acknowledgment Message at zero, then each field in turn at the values it is checked at *)
CheckedRiskControlAcknowledgmentMessage ==
    { ZeroRiskControlAcknowledgmentMessage }
        \cup { [ZeroRiskControlAcknowledgmentMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroRiskControlAcknowledgmentMessage EXCEPT !.underlyingIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroRiskControlAcknowledgmentMessage EXCEPT !.marketParticipantId = one] : one \in Sample(4) }
        \cup { [ZeroRiskControlAcknowledgmentMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroRiskControlAcknowledgmentMessage EXCEPT !.customGroupIdOptional = one] : one \in Sample(2) }
        \cup { [ZeroRiskControlAcknowledgmentMessage EXCEPT !.riskAckType = one] : one \in Sample(1) }
        \cup { [ZeroRiskControlAcknowledgmentMessage EXCEPT !.riskControlStatus = one] : one \in Sample(1) }
        \cup { [ZeroRiskControlAcknowledgmentMessage EXCEPT !.riskControl = one] : one \in Sample(1) }
        \cup { [ZeroRiskControlAcknowledgmentMessage EXCEPT !.riskActionOptional = one] : one \in Sample(1) }
        \cup { [ZeroRiskControlAcknowledgmentMessage EXCEPT !.timeLimit = one] : one \in Sample(8) }
        \cup { [ZeroRiskControlAcknowledgmentMessage EXCEPT !.percentageLimit = one] : one \in Sample(4) }
        \cup { [ZeroRiskControlAcknowledgmentMessage EXCEPT !.countLimit = one] : one \in Sample(4) }
        \cup { [ZeroRiskControlAcknowledgmentMessage EXCEPT !.iocAttribution = one] : one \in Sample(1) }
        \cup { [ZeroRiskControlAcknowledgmentMessage EXCEPT !.blockedByBreachIndicator = one] : one \in Sample(1) }
        \cup { [ZeroRiskControlAcknowledgmentMessage EXCEPT !.custCapacityWeight = one] : one \in Sample(1) }
        \cup { [ZeroRiskControlAcknowledgmentMessage EXCEPT !.throttleIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Risk Control Alert Message: 34 bytes                                    *)
(***************************************************************************)

RiskControlAlertMessage ==
    [ transactTime         : Sample(8),
      underlyingIdOptional : Sample(4),
      marketParticipantId  : Sample(4),
      riskControl          : Sample(1),
      timeLimit            : Sample(8),
      percentageLimit      : Sample(4),
      countLimit           : Sample(4),
      notificationReason   : Sample(1) ]

EncodeRiskControlAlertMessage(message) ==
    message.transactTime
        \o message.underlyingIdOptional
        \o message.marketParticipantId
        \o message.riskControl
        \o message.timeLimit
        \o message.percentageLimit
        \o message.countLimit
        \o message.notificationReason

DecodeRiskControlAlertMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET underlyingIdOptional == ReadBytes(transactTime.rest, 4) IN IF ~underlyingIdOptional.ok THEN Fail ELSE
    LET marketParticipantId == ReadBytes(underlyingIdOptional.rest, 4) IN IF ~marketParticipantId.ok THEN Fail ELSE
    LET riskControl == ReadBytes(marketParticipantId.rest, 1) IN IF ~riskControl.ok THEN Fail ELSE
    LET timeLimit == ReadBytes(riskControl.rest, 8) IN IF ~timeLimit.ok THEN Fail ELSE
    LET percentageLimit == ReadBytes(timeLimit.rest, 4) IN IF ~percentageLimit.ok THEN Fail ELSE
    LET countLimit == ReadBytes(percentageLimit.rest, 4) IN IF ~countLimit.ok THEN Fail ELSE
    LET notificationReason == ReadBytes(countLimit.rest, 1) IN IF ~notificationReason.ok THEN Fail ELSE
    Ok([ transactTime         |-> transactTime.value,
         underlyingIdOptional |-> underlyingIdOptional.value,
         marketParticipantId  |-> marketParticipantId.value,
         riskControl          |-> riskControl.value,
         timeLimit            |-> timeLimit.value,
         percentageLimit      |-> percentageLimit.value,
         countLimit           |-> countLimit.value,
         notificationReason   |-> notificationReason.value ], notificationReason.rest)

ZeroRiskControlAlertMessage ==
    [ transactTime         |-> [i \in 1 .. 8 |-> 0],
      underlyingIdOptional |-> [i \in 1 .. 4 |-> 0],
      marketParticipantId  |-> [i \in 1 .. 4 |-> 0],
      riskControl          |-> [i \in 1 .. 1 |-> 0],
      timeLimit            |-> [i \in 1 .. 8 |-> 0],
      percentageLimit      |-> [i \in 1 .. 4 |-> 0],
      countLimit           |-> [i \in 1 .. 4 |-> 0],
      notificationReason   |-> [i \in 1 .. 1 |-> 0] ]

(* Risk Control Alert Message at zero, then each field in turn at the values it is checked at *)
CheckedRiskControlAlertMessage ==
    { ZeroRiskControlAlertMessage }
        \cup { [ZeroRiskControlAlertMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroRiskControlAlertMessage EXCEPT !.underlyingIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroRiskControlAlertMessage EXCEPT !.marketParticipantId = one] : one \in Sample(4) }
        \cup { [ZeroRiskControlAlertMessage EXCEPT !.riskControl = one] : one \in Sample(1) }
        \cup { [ZeroRiskControlAlertMessage EXCEPT !.timeLimit = one] : one \in Sample(8) }
        \cup { [ZeroRiskControlAlertMessage EXCEPT !.percentageLimit = one] : one \in Sample(4) }
        \cup { [ZeroRiskControlAlertMessage EXCEPT !.countLimit = one] : one \in Sample(4) }
        \cup { [ZeroRiskControlAlertMessage EXCEPT !.notificationReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by Schema Id and Template Id                          *)
(***************************************************************************)

LoginRequestMessageCode == <<20000, 1>>  \* 0x4e20, 0x01
LoginResponseMessageCode == <<20000, 2>>  \* 0x4e20, 0x02
GatewayHeartbeatMessageCode == <<20000, 3>>  \* 0x4e20, 0x03
ClientHeartbeatMessageCode == <<20000, 4>>  \* 0x4e20, 0x04
LogoutRequestMessageCode == <<20000, 5>>  \* 0x4e20, 0x05
TerminateMessageCode == <<20000, 6>>  \* 0x4e20, 0x06
SequencedMessageHeaderMessageCode == <<20000, 7>>  \* 0x4e20, 0x07
SubsessionJoinMessageCode == <<20000, 8>>  \* 0x4e20, 0x08
SubsessionJoinResponseMessageCode == <<20000, 9>>  \* 0x4e20, 0x09
SubsessionLeaveMessageCode == <<20000, 10>>  \* 0x4e20, 0x0a
SubsessionLeaveResponseMessageCode == <<20000, 11>>  \* 0x4e20, 0x0b
NewOrderSingleMessageCode == <<20001, 1>>  \* 0x4e21, 0x01
OrderCancelReplaceRequestMessageCode == <<20001, 2>>  \* 0x4e21, 0x02
OrderCancelRequestMessageCode == <<20001, 3>>  \* 0x4e21, 0x03
NewBulkQuoteMessageCode == <<20001, 4>>  \* 0x4e21, 0x04
MassCancelRequestMessageCode == <<20001, 5>>  \* 0x4e21, 0x05
PurgeRequestMessageCode == <<20001, 6>>  \* 0x4e21, 0x06
OrderAckMessageCode == <<20001, 101>>  \* 0x4e21, 0x65
UnsolicitedModifyAckMessageCode == <<20001, 102>>  \* 0x4e21, 0x66
OrderCancelAckMessageCode == <<20001, 103>>  \* 0x4e21, 0x67
MassCancelAckMessageCode == <<20001, 104>>  \* 0x4e21, 0x68
BulkQuoteAckMessageCode == <<20001, 105>>  \* 0x4e21, 0x69
NewIocQuoteAckMessageCode == <<20001, 106>>  \* 0x4e21, 0x6a
QuoteRestatedMessageCode == <<20001, 107>>  \* 0x4e21, 0x6b
QuoteCanceledMessageCode == <<20001, 108>>  \* 0x4e21, 0x6c
PurgeAckMessageCode == <<20001, 109>>  \* 0x4e21, 0x6d
ExecutionReportMessageCode == <<20001, 110>>  \* 0x4e21, 0x6e
TradeBustCorrectMessageCode == <<20001, 111>>  \* 0x4e21, 0x6f
ApplicationLayerRejectMessageCode == <<20001, 112>>  \* 0x4e21, 0x70
RiskLimitUpdateRequestMessageCode == <<20001, 51>>  \* 0x4e21, 0x33
RiskActionRequestMessageCode == <<20001, 52>>  \* 0x4e21, 0x34
UnderlyingRefDataMessageCode == <<20001, 151>>  \* 0x4e21, 0x97
InstrumentRefDataMessageCode == <<20001, 152>>  \* 0x4e21, 0x98
MpidConfigurationAcknowledgementMessageCode == <<20001, 153>>  \* 0x4e21, 0x99
MarketMakerSymbolAppointmentMessageCode == <<20001, 154>>  \* 0x4e21, 0x9a
SessionConfigurationAcknowledgementMessageCode == <<20001, 155>>  \* 0x4e21, 0x9b
RiskControlAcknowledgmentMessageCode == <<20001, 156>>  \* 0x4e21, 0x9c
RiskControlAlertMessageCode == <<20001, 157>>  \* 0x4e21, 0x9d

Payload ==
    [ tag : {LoginRequestMessageCode}, body : LoginRequestMessage ]
        \cup [ tag : {LoginResponseMessageCode}, body : LoginResponseMessage ]
        \cup [ tag : {GatewayHeartbeatMessageCode}, body : GatewayHeartbeatMessage ]
        \cup [ tag : {ClientHeartbeatMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {LogoutRequestMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {TerminateMessageCode}, body : TerminateMessage ]
        \cup [ tag : {SequencedMessageHeaderMessageCode}, body : SequencedMessageHeaderMessage ]
        \cup [ tag : {SubsessionJoinMessageCode}, body : SubsessionJoinMessage ]
        \cup [ tag : {SubsessionJoinResponseMessageCode}, body : SubsessionJoinResponseMessage ]
        \cup [ tag : {SubsessionLeaveMessageCode}, body : SubsessionLeaveMessage ]
        \cup [ tag : {SubsessionLeaveResponseMessageCode}, body : SubsessionLeaveResponseMessage ]
        \cup [ tag : {NewOrderSingleMessageCode}, body : NewOrderSingleMessage ]
        \cup [ tag : {OrderCancelReplaceRequestMessageCode}, body : OrderCancelReplaceRequestMessage ]
        \cup [ tag : {OrderCancelRequestMessageCode}, body : OrderCancelRequestMessage ]
        \cup [ tag : {NewBulkQuoteMessageCode}, body : NewBulkQuoteMessage ]
        \cup [ tag : {MassCancelRequestMessageCode}, body : MassCancelRequestMessage ]
        \cup [ tag : {PurgeRequestMessageCode}, body : PurgeRequestMessage ]
        \cup [ tag : {OrderAckMessageCode}, body : OrderAckMessage ]
        \cup [ tag : {UnsolicitedModifyAckMessageCode}, body : UnsolicitedModifyAckMessage ]
        \cup [ tag : {OrderCancelAckMessageCode}, body : OrderCancelAckMessage ]
        \cup [ tag : {MassCancelAckMessageCode}, body : MassCancelAckMessage ]
        \cup [ tag : {BulkQuoteAckMessageCode}, body : BulkQuoteAckMessage ]
        \cup [ tag : {NewIocQuoteAckMessageCode}, body : NewIocQuoteAckMessage ]
        \cup [ tag : {QuoteRestatedMessageCode}, body : QuoteRestatedMessage ]
        \cup [ tag : {QuoteCanceledMessageCode}, body : QuoteCanceledMessage ]
        \cup [ tag : {PurgeAckMessageCode}, body : PurgeAckMessage ]
        \cup [ tag : {ExecutionReportMessageCode}, body : ExecutionReportMessage ]
        \cup [ tag : {TradeBustCorrectMessageCode}, body : TradeBustCorrectMessage ]
        \cup [ tag : {ApplicationLayerRejectMessageCode}, body : ApplicationLayerRejectMessage ]
        \cup [ tag : {RiskLimitUpdateRequestMessageCode}, body : RiskLimitUpdateRequestMessage ]
        \cup [ tag : {RiskActionRequestMessageCode}, body : RiskActionRequestMessage ]
        \cup [ tag : {UnderlyingRefDataMessageCode}, body : UnderlyingRefDataMessage ]
        \cup [ tag : {InstrumentRefDataMessageCode}, body : InstrumentRefDataMessage ]
        \cup [ tag : {MpidConfigurationAcknowledgementMessageCode}, body : MpidConfigurationAcknowledgementMessage ]
        \cup [ tag : {MarketMakerSymbolAppointmentMessageCode}, body : MarketMakerSymbolAppointmentMessage ]
        \cup [ tag : {SessionConfigurationAcknowledgementMessageCode}, body : SessionConfigurationAcknowledgementMessage ]
        \cup [ tag : {RiskControlAcknowledgmentMessageCode}, body : RiskControlAcknowledgmentMessage ]
        \cup [ tag : {RiskControlAlertMessageCode}, body : RiskControlAlertMessage ]

EncodePayload(message) ==
    CASE message.tag = LoginRequestMessageCode -> EncodeLoginRequestMessage(message.body)
      [] message.tag = LoginResponseMessageCode -> EncodeLoginResponseMessage(message.body)
      [] message.tag = GatewayHeartbeatMessageCode -> EncodeGatewayHeartbeatMessage(message.body)
      [] message.tag = ClientHeartbeatMessageCode -> << >>
      [] message.tag = LogoutRequestMessageCode -> << >>
      [] message.tag = TerminateMessageCode -> EncodeTerminateMessage(message.body)
      [] message.tag = SequencedMessageHeaderMessageCode -> EncodeSequencedMessageHeaderMessage(message.body)
      [] message.tag = SubsessionJoinMessageCode -> EncodeSubsessionJoinMessage(message.body)
      [] message.tag = SubsessionJoinResponseMessageCode -> EncodeSubsessionJoinResponseMessage(message.body)
      [] message.tag = SubsessionLeaveMessageCode -> EncodeSubsessionLeaveMessage(message.body)
      [] message.tag = SubsessionLeaveResponseMessageCode -> EncodeSubsessionLeaveResponseMessage(message.body)
      [] message.tag = NewOrderSingleMessageCode -> EncodeNewOrderSingleMessage(message.body)
      [] message.tag = OrderCancelReplaceRequestMessageCode -> EncodeOrderCancelReplaceRequestMessage(message.body)
      [] message.tag = OrderCancelRequestMessageCode -> EncodeOrderCancelRequestMessage(message.body)
      [] message.tag = NewBulkQuoteMessageCode -> EncodeNewBulkQuoteMessage(message.body)
      [] message.tag = MassCancelRequestMessageCode -> EncodeMassCancelRequestMessage(message.body)
      [] message.tag = PurgeRequestMessageCode -> EncodePurgeRequestMessage(message.body)
      [] message.tag = OrderAckMessageCode -> EncodeOrderAckMessage(message.body)
      [] message.tag = UnsolicitedModifyAckMessageCode -> EncodeUnsolicitedModifyAckMessage(message.body)
      [] message.tag = OrderCancelAckMessageCode -> EncodeOrderCancelAckMessage(message.body)
      [] message.tag = MassCancelAckMessageCode -> EncodeMassCancelAckMessage(message.body)
      [] message.tag = BulkQuoteAckMessageCode -> EncodeBulkQuoteAckMessage(message.body)
      [] message.tag = NewIocQuoteAckMessageCode -> EncodeNewIocQuoteAckMessage(message.body)
      [] message.tag = QuoteRestatedMessageCode -> EncodeQuoteRestatedMessage(message.body)
      [] message.tag = QuoteCanceledMessageCode -> EncodeQuoteCanceledMessage(message.body)
      [] message.tag = PurgeAckMessageCode -> EncodePurgeAckMessage(message.body)
      [] message.tag = ExecutionReportMessageCode -> EncodeExecutionReportMessage(message.body)
      [] message.tag = TradeBustCorrectMessageCode -> EncodeTradeBustCorrectMessage(message.body)
      [] message.tag = ApplicationLayerRejectMessageCode -> EncodeApplicationLayerRejectMessage(message.body)
      [] message.tag = RiskLimitUpdateRequestMessageCode -> EncodeRiskLimitUpdateRequestMessage(message.body)
      [] message.tag = RiskActionRequestMessageCode -> EncodeRiskActionRequestMessage(message.body)
      [] message.tag = UnderlyingRefDataMessageCode -> EncodeUnderlyingRefDataMessage(message.body)
      [] message.tag = InstrumentRefDataMessageCode -> EncodeInstrumentRefDataMessage(message.body)
      [] message.tag = MpidConfigurationAcknowledgementMessageCode -> EncodeMpidConfigurationAcknowledgementMessage(message.body)
      [] message.tag = MarketMakerSymbolAppointmentMessageCode -> EncodeMarketMakerSymbolAppointmentMessage(message.body)
      [] message.tag = SessionConfigurationAcknowledgementMessageCode -> EncodeSessionConfigurationAcknowledgementMessage(message.body)
      [] message.tag = RiskControlAcknowledgmentMessageCode -> EncodeRiskControlAcknowledgmentMessage(message.body)
      [] message.tag = RiskControlAlertMessageCode -> EncodeRiskControlAlertMessage(message.body)

DecodePayload(schemaId, templateId, bytes) ==
    LET read ==
            CASE <<schemaId, templateId>> = LoginRequestMessageCode -> DecodeLoginRequestMessage(bytes)
              [] <<schemaId, templateId>> = LoginResponseMessageCode -> DecodeLoginResponseMessage(bytes)
              [] <<schemaId, templateId>> = GatewayHeartbeatMessageCode -> DecodeGatewayHeartbeatMessage(bytes)
              [] <<schemaId, templateId>> = ClientHeartbeatMessageCode -> Ok([empty |-> 0], bytes)
              [] <<schemaId, templateId>> = LogoutRequestMessageCode -> Ok([empty |-> 0], bytes)
              [] <<schemaId, templateId>> = TerminateMessageCode -> DecodeTerminateMessage(bytes)
              [] <<schemaId, templateId>> = SequencedMessageHeaderMessageCode -> DecodeSequencedMessageHeaderMessage(bytes)
              [] <<schemaId, templateId>> = SubsessionJoinMessageCode -> DecodeSubsessionJoinMessage(bytes)
              [] <<schemaId, templateId>> = SubsessionJoinResponseMessageCode -> DecodeSubsessionJoinResponseMessage(bytes)
              [] <<schemaId, templateId>> = SubsessionLeaveMessageCode -> DecodeSubsessionLeaveMessage(bytes)
              [] <<schemaId, templateId>> = SubsessionLeaveResponseMessageCode -> DecodeSubsessionLeaveResponseMessage(bytes)
              [] <<schemaId, templateId>> = NewOrderSingleMessageCode -> DecodeNewOrderSingleMessage(bytes)
              [] <<schemaId, templateId>> = OrderCancelReplaceRequestMessageCode -> DecodeOrderCancelReplaceRequestMessage(bytes)
              [] <<schemaId, templateId>> = OrderCancelRequestMessageCode -> DecodeOrderCancelRequestMessage(bytes)
              [] <<schemaId, templateId>> = NewBulkQuoteMessageCode -> DecodeNewBulkQuoteMessage(bytes)
              [] <<schemaId, templateId>> = MassCancelRequestMessageCode -> DecodeMassCancelRequestMessage(bytes)
              [] <<schemaId, templateId>> = PurgeRequestMessageCode -> DecodePurgeRequestMessage(bytes)
              [] <<schemaId, templateId>> = OrderAckMessageCode -> DecodeOrderAckMessage(bytes)
              [] <<schemaId, templateId>> = UnsolicitedModifyAckMessageCode -> DecodeUnsolicitedModifyAckMessage(bytes)
              [] <<schemaId, templateId>> = OrderCancelAckMessageCode -> DecodeOrderCancelAckMessage(bytes)
              [] <<schemaId, templateId>> = MassCancelAckMessageCode -> DecodeMassCancelAckMessage(bytes)
              [] <<schemaId, templateId>> = BulkQuoteAckMessageCode -> DecodeBulkQuoteAckMessage(bytes)
              [] <<schemaId, templateId>> = NewIocQuoteAckMessageCode -> DecodeNewIocQuoteAckMessage(bytes)
              [] <<schemaId, templateId>> = QuoteRestatedMessageCode -> DecodeQuoteRestatedMessage(bytes)
              [] <<schemaId, templateId>> = QuoteCanceledMessageCode -> DecodeQuoteCanceledMessage(bytes)
              [] <<schemaId, templateId>> = PurgeAckMessageCode -> DecodePurgeAckMessage(bytes)
              [] <<schemaId, templateId>> = ExecutionReportMessageCode -> DecodeExecutionReportMessage(bytes)
              [] <<schemaId, templateId>> = TradeBustCorrectMessageCode -> DecodeTradeBustCorrectMessage(bytes)
              [] <<schemaId, templateId>> = ApplicationLayerRejectMessageCode -> DecodeApplicationLayerRejectMessage(bytes)
              [] <<schemaId, templateId>> = RiskLimitUpdateRequestMessageCode -> DecodeRiskLimitUpdateRequestMessage(bytes)
              [] <<schemaId, templateId>> = RiskActionRequestMessageCode -> DecodeRiskActionRequestMessage(bytes)
              [] <<schemaId, templateId>> = UnderlyingRefDataMessageCode -> DecodeUnderlyingRefDataMessage(bytes)
              [] <<schemaId, templateId>> = InstrumentRefDataMessageCode -> DecodeInstrumentRefDataMessage(bytes)
              [] <<schemaId, templateId>> = MpidConfigurationAcknowledgementMessageCode -> DecodeMpidConfigurationAcknowledgementMessage(bytes)
              [] <<schemaId, templateId>> = MarketMakerSymbolAppointmentMessageCode -> DecodeMarketMakerSymbolAppointmentMessage(bytes)
              [] <<schemaId, templateId>> = SessionConfigurationAcknowledgementMessageCode -> DecodeSessionConfigurationAcknowledgementMessage(bytes)
              [] <<schemaId, templateId>> = RiskControlAcknowledgmentMessageCode -> DecodeRiskControlAcknowledgmentMessage(bytes)
              [] <<schemaId, templateId>> = RiskControlAlertMessageCode -> DecodeRiskControlAlertMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> <<schemaId, templateId>>, body |-> read.value], read.rest)

ZeroPayload == [tag |-> LoginRequestMessageCode, body |-> ZeroLoginRequestMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> LoginRequestMessageCode, body |-> one] : one \in CheckedLoginRequestMessage }
        \cup { [tag |-> LoginResponseMessageCode, body |-> one] : one \in CheckedLoginResponseMessage }
        \cup { [tag |-> GatewayHeartbeatMessageCode, body |-> one] : one \in CheckedGatewayHeartbeatMessage }
        \cup { [tag |-> ClientHeartbeatMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> LogoutRequestMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> TerminateMessageCode, body |-> one] : one \in CheckedTerminateMessage }
        \cup { [tag |-> SequencedMessageHeaderMessageCode, body |-> one] : one \in CheckedSequencedMessageHeaderMessage }
        \cup { [tag |-> SubsessionJoinMessageCode, body |-> one] : one \in CheckedSubsessionJoinMessage }
        \cup { [tag |-> SubsessionJoinResponseMessageCode, body |-> one] : one \in CheckedSubsessionJoinResponseMessage }
        \cup { [tag |-> SubsessionLeaveMessageCode, body |-> one] : one \in CheckedSubsessionLeaveMessage }
        \cup { [tag |-> SubsessionLeaveResponseMessageCode, body |-> one] : one \in CheckedSubsessionLeaveResponseMessage }
        \cup { [tag |-> NewOrderSingleMessageCode, body |-> one] : one \in CheckedNewOrderSingleMessage }
        \cup { [tag |-> OrderCancelReplaceRequestMessageCode, body |-> one] : one \in CheckedOrderCancelReplaceRequestMessage }
        \cup { [tag |-> OrderCancelRequestMessageCode, body |-> one] : one \in CheckedOrderCancelRequestMessage }
        \cup { [tag |-> NewBulkQuoteMessageCode, body |-> one] : one \in CheckedNewBulkQuoteMessage }
        \cup { [tag |-> MassCancelRequestMessageCode, body |-> one] : one \in CheckedMassCancelRequestMessage }
        \cup { [tag |-> PurgeRequestMessageCode, body |-> one] : one \in CheckedPurgeRequestMessage }
        \cup { [tag |-> OrderAckMessageCode, body |-> one] : one \in CheckedOrderAckMessage }
        \cup { [tag |-> UnsolicitedModifyAckMessageCode, body |-> one] : one \in CheckedUnsolicitedModifyAckMessage }
        \cup { [tag |-> OrderCancelAckMessageCode, body |-> one] : one \in CheckedOrderCancelAckMessage }
        \cup { [tag |-> MassCancelAckMessageCode, body |-> one] : one \in CheckedMassCancelAckMessage }
        \cup { [tag |-> BulkQuoteAckMessageCode, body |-> one] : one \in CheckedBulkQuoteAckMessage }
        \cup { [tag |-> NewIocQuoteAckMessageCode, body |-> one] : one \in CheckedNewIocQuoteAckMessage }
        \cup { [tag |-> QuoteRestatedMessageCode, body |-> one] : one \in CheckedQuoteRestatedMessage }
        \cup { [tag |-> QuoteCanceledMessageCode, body |-> one] : one \in CheckedQuoteCanceledMessage }
        \cup { [tag |-> PurgeAckMessageCode, body |-> one] : one \in CheckedPurgeAckMessage }
        \cup { [tag |-> ExecutionReportMessageCode, body |-> one] : one \in CheckedExecutionReportMessage }
        \cup { [tag |-> TradeBustCorrectMessageCode, body |-> one] : one \in CheckedTradeBustCorrectMessage }
        \cup { [tag |-> ApplicationLayerRejectMessageCode, body |-> one] : one \in CheckedApplicationLayerRejectMessage }
        \cup { [tag |-> RiskLimitUpdateRequestMessageCode, body |-> one] : one \in CheckedRiskLimitUpdateRequestMessage }
        \cup { [tag |-> RiskActionRequestMessageCode, body |-> one] : one \in CheckedRiskActionRequestMessage }
        \cup { [tag |-> UnderlyingRefDataMessageCode, body |-> one] : one \in CheckedUnderlyingRefDataMessage }
        \cup { [tag |-> InstrumentRefDataMessageCode, body |-> one] : one \in CheckedInstrumentRefDataMessage }
        \cup { [tag |-> MpidConfigurationAcknowledgementMessageCode, body |-> one] : one \in CheckedMpidConfigurationAcknowledgementMessage }
        \cup { [tag |-> MarketMakerSymbolAppointmentMessageCode, body |-> one] : one \in CheckedMarketMakerSymbolAppointmentMessage }
        \cup { [tag |-> SessionConfigurationAcknowledgementMessageCode, body |-> one] : one \in CheckedSessionConfigurationAcknowledgementMessage }
        \cup { [tag |-> RiskControlAcknowledgmentMessageCode, body |-> one] : one \in CheckedRiskControlAcknowledgmentMessage }
        \cup { [tag |-> RiskControlAlertMessageCode, body |-> one] : one \in CheckedRiskControlAlertMessage }

(***************************************************************************)
(* Sbe Message, framed by Packet Length                                    *)
(***************************************************************************)

SbeMessage ==
    [ blockLength : Sample(2),
      version     : Sample(2),
      payload     : Payload ]

EncodeSbeMessageBody(message) ==
    message.blockLength
        \o EncodeUIntLE(message.payload.tag[2], 2)
        \o EncodeUIntLE(message.payload.tag[1], 2)
        \o message.version
        \o EncodePayload(message.payload)

(* Packet Length counts the bytes it frames, so it is written from them *)
EncodeSbeMessage(message) ==
    LET body == EncodeSbeMessageBody(message)
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeSbeMessageBody(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET templateId == ReadUIntLE(blockLength.rest, 2) IN IF ~templateId.ok THEN Fail ELSE
    LET schemaId == ReadUIntLE(templateId.rest, 2) IN IF ~schemaId.ok THEN Fail ELSE
    LET version == ReadBytes(schemaId.rest, 2) IN IF ~version.ok THEN Fail ELSE
    LET payload == DecodePayload(schemaId.value, templateId.value, version.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ blockLength |-> blockLength.value,
         version     |-> version.value,
         payload     |-> payload.value ], payload.rest)

DecodeSbeMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeSbeMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroSbeMessage ==
    [ blockLength |-> [i \in 1 .. 2 |-> 0],
      version     |-> [i \in 1 .. 2 |-> 0],
      payload     |-> ZeroPayload ]

(* Sbe Message at zero, then each field in turn at the values it is checked at *)
CheckedSbeMessage ==
    { ZeroSbeMessage }
        \cup { [ZeroSbeMessage EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSbeMessage EXCEPT !.version = one] : one \in Sample(2) }
        \cup { [ZeroSbeMessage EXCEPT !.payload = one] : one \in CheckedPayload }

(* A run of Sbe Message, written one after another *)
RECURSIVE EncodeSbeMessageList(_)
EncodeSbeMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSbeMessage(Head(messages)) \o EncodeSbeMessageList(Tail(messages))

(* As many Sbe Message as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadSbeMessageAll(_)
ReadSbeMessageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeSbeMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSbeMessageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Sbe Message of each kind, for the lists that carry them *)
OneSbeMessage ==
    { [ZeroSbeMessage EXCEPT !.payload = [tag |-> LoginRequestMessageCode, body |-> ZeroLoginRequestMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> LoginResponseMessageCode, body |-> ZeroLoginResponseMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> GatewayHeartbeatMessageCode, body |-> ZeroGatewayHeartbeatMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> ClientHeartbeatMessageCode, body |-> [empty |-> 0]]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> LogoutRequestMessageCode, body |-> [empty |-> 0]]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> TerminateMessageCode, body |-> ZeroTerminateMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> SequencedMessageHeaderMessageCode, body |-> ZeroSequencedMessageHeaderMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> SubsessionJoinMessageCode, body |-> ZeroSubsessionJoinMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> SubsessionJoinResponseMessageCode, body |-> ZeroSubsessionJoinResponseMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> SubsessionLeaveMessageCode, body |-> ZeroSubsessionLeaveMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> SubsessionLeaveResponseMessageCode, body |-> ZeroSubsessionLeaveResponseMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> NewOrderSingleMessageCode, body |-> ZeroNewOrderSingleMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> OrderCancelReplaceRequestMessageCode, body |-> ZeroOrderCancelReplaceRequestMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> OrderCancelRequestMessageCode, body |-> ZeroOrderCancelRequestMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> NewBulkQuoteMessageCode, body |-> ZeroNewBulkQuoteMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> MassCancelRequestMessageCode, body |-> ZeroMassCancelRequestMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> PurgeRequestMessageCode, body |-> ZeroPurgeRequestMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> OrderAckMessageCode, body |-> ZeroOrderAckMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> UnsolicitedModifyAckMessageCode, body |-> ZeroUnsolicitedModifyAckMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> OrderCancelAckMessageCode, body |-> ZeroOrderCancelAckMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> MassCancelAckMessageCode, body |-> ZeroMassCancelAckMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> BulkQuoteAckMessageCode, body |-> ZeroBulkQuoteAckMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> NewIocQuoteAckMessageCode, body |-> ZeroNewIocQuoteAckMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> QuoteRestatedMessageCode, body |-> ZeroQuoteRestatedMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> QuoteCanceledMessageCode, body |-> ZeroQuoteCanceledMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> PurgeAckMessageCode, body |-> ZeroPurgeAckMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> ExecutionReportMessageCode, body |-> ZeroExecutionReportMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> TradeBustCorrectMessageCode, body |-> ZeroTradeBustCorrectMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> ApplicationLayerRejectMessageCode, body |-> ZeroApplicationLayerRejectMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> RiskLimitUpdateRequestMessageCode, body |-> ZeroRiskLimitUpdateRequestMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> RiskActionRequestMessageCode, body |-> ZeroRiskActionRequestMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> UnderlyingRefDataMessageCode, body |-> ZeroUnderlyingRefDataMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> InstrumentRefDataMessageCode, body |-> ZeroInstrumentRefDataMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> MpidConfigurationAcknowledgementMessageCode, body |-> ZeroMpidConfigurationAcknowledgementMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> MarketMakerSymbolAppointmentMessageCode, body |-> ZeroMarketMakerSymbolAppointmentMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> SessionConfigurationAcknowledgementMessageCode, body |-> ZeroSessionConfigurationAcknowledgementMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> RiskControlAcknowledgmentMessageCode, body |-> ZeroRiskControlAcknowledgmentMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> RiskControlAlertMessageCode, body |-> ZeroRiskControlAlertMessage]] }

(***************************************************************************)
(* Client Packet                                                           *)
(***************************************************************************)

ClientPacket ==
    [ sbeMessage : SampleLists(OneSbeMessage) ]

EncodeClientPacket(message) ==
    EncodeSbeMessageList(message.sbeMessage)

DecodeClientPacket(bytes) ==
    LET sbeMessage == ReadSbeMessageAll(bytes) IN IF ~sbeMessage.ok THEN Fail ELSE
    Ok([ sbeMessage |-> sbeMessage.value ], sbeMessage.rest)

ZeroClientPacket ==
    [ sbeMessage |-> << >> ]

(* Client Packet at zero, then each field in turn at the values it is checked at *)
CheckedClientPacket ==
    { ZeroClientPacket }
        \cup { [ZeroClientPacket EXCEPT !.sbeMessage = one] : one \in SampleLists(OneSbeMessage) }

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

(* Every Login Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginResponseMessage ==
    \A message \in CheckedLoginResponseMessage :
        LET read == DecodeLoginResponseMessage(EncodeLoginResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sub Sessions Group decodes back to what was encoded, and leaves nothing over *)
RoundTripSubSessionsGroup ==
    \A message \in CheckedSubSessionsGroup :
        LET read == DecodeSubSessionsGroup(EncodeSubSessionsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sub Sessions Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripSubSessionsGroups ==
    \A message \in CheckedSubSessionsGroups :
        LET read == DecodeSubSessionsGroups(EncodeSubSessionsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Gateway Heartbeat Message decodes back to what was encoded, and leaves nothing over *)
RoundTripGatewayHeartbeatMessage ==
    \A message \in CheckedGatewayHeartbeatMessage :
        LET read == DecodeGatewayHeartbeatMessage(EncodeGatewayHeartbeatMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Terminate Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTerminateMessage ==
    \A message \in CheckedTerminateMessage :
        LET read == DecodeTerminateMessage(EncodeTerminateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sequenced Message Header Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSequencedMessageHeaderMessage ==
    \A message \in CheckedSequencedMessageHeaderMessage :
        LET read == DecodeSequencedMessageHeaderMessage(EncodeSequencedMessageHeaderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Subsession Join Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSubsessionJoinMessage ==
    \A message \in CheckedSubsessionJoinMessage :
        LET read == DecodeSubsessionJoinMessage(EncodeSubsessionJoinMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Subsession Join Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSubsessionJoinResponseMessage ==
    \A message \in CheckedSubsessionJoinResponseMessage :
        LET read == DecodeSubsessionJoinResponseMessage(EncodeSubsessionJoinResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Subsession Leave Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSubsessionLeaveMessage ==
    \A message \in CheckedSubsessionLeaveMessage :
        LET read == DecodeSubsessionLeaveMessage(EncodeSubsessionLeaveMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Subsession Leave Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSubsessionLeaveResponseMessage ==
    \A message \in CheckedSubsessionLeaveResponseMessage :
        LET read == DecodeSubsessionLeaveResponseMessage(EncodeSubsessionLeaveResponseMessage(message))
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

(* Every New Bulk Quote Message quote Updates Group decodes back to what was encoded, and leaves nothing over *)
RoundTripNewBulkQuoteMessageQuoteUpdatesGroup ==
    \A message \in CheckedNewBulkQuoteMessageQuoteUpdatesGroup :
        LET read == DecodeNewBulkQuoteMessageQuoteUpdatesGroup(EncodeNewBulkQuoteMessageQuoteUpdatesGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Bulk Quote Message quote Updates Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripNewBulkQuoteMessageQuoteUpdatesGroups ==
    \A message \in CheckedNewBulkQuoteMessageQuoteUpdatesGroups :
        LET read == DecodeNewBulkQuoteMessageQuoteUpdatesGroups(EncodeNewBulkQuoteMessageQuoteUpdatesGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Bulk Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewBulkQuoteMessage ==
    \A message \in CheckedNewBulkQuoteMessage :
        LET read == DecodeNewBulkQuoteMessage(EncodeNewBulkQuoteMessage(message))
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

(* Every Purge Request Message custom Group Ids Group decodes back to what was encoded, and leaves nothing over *)
RoundTripPurgeRequestMessageCustomGroupIdsGroup ==
    \A message \in CheckedPurgeRequestMessageCustomGroupIdsGroup :
        LET read == DecodePurgeRequestMessageCustomGroupIdsGroup(EncodePurgeRequestMessageCustomGroupIdsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Purge Request Message custom Group Ids Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripPurgeRequestMessageCustomGroupIdsGroups ==
    \A message \in CheckedPurgeRequestMessageCustomGroupIdsGroups :
        LET read == DecodePurgeRequestMessageCustomGroupIdsGroups(EncodePurgeRequestMessageCustomGroupIdsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Purge Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPurgeRequestMessage ==
    \A message \in CheckedPurgeRequestMessage :
        LET read == DecodePurgeRequestMessage(EncodePurgeRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Ack Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderAckMessage ==
    \A message \in CheckedOrderAckMessage :
        LET read == DecodeOrderAckMessage(EncodeOrderAckMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Unsolicited Modify Ack Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUnsolicitedModifyAckMessage ==
    \A message \in CheckedUnsolicitedModifyAckMessage :
        LET read == DecodeUnsolicitedModifyAckMessage(EncodeUnsolicitedModifyAckMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancel Ack Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelAckMessage ==
    \A message \in CheckedOrderCancelAckMessage :
        LET read == DecodeOrderCancelAckMessage(EncodeOrderCancelAckMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Cancel Ack Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMassCancelAckMessage ==
    \A message \in CheckedMassCancelAckMessage :
        LET read == DecodeMassCancelAckMessage(EncodeMassCancelAckMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulk Quote Ack Message quote Acks Group decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkQuoteAckMessageQuoteAcksGroup ==
    \A message \in CheckedBulkQuoteAckMessageQuoteAcksGroup :
        LET read == DecodeBulkQuoteAckMessageQuoteAcksGroup(EncodeBulkQuoteAckMessageQuoteAcksGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulk Quote Ack Message quote Acks Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkQuoteAckMessageQuoteAcksGroups ==
    \A message \in CheckedBulkQuoteAckMessageQuoteAcksGroups :
        LET read == DecodeBulkQuoteAckMessageQuoteAcksGroups(EncodeBulkQuoteAckMessageQuoteAcksGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulk Quote Ack Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkQuoteAckMessage ==
    \A message \in CheckedBulkQuoteAckMessage :
        LET read == DecodeBulkQuoteAckMessage(EncodeBulkQuoteAckMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Ioc Quote Ack Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewIocQuoteAckMessage ==
    \A message \in CheckedNewIocQuoteAckMessage :
        LET read == DecodeNewIocQuoteAckMessage(EncodeNewIocQuoteAckMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Restated Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteRestatedMessage ==
    \A message \in CheckedQuoteRestatedMessage :
        LET read == DecodeQuoteRestatedMessage(EncodeQuoteRestatedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Canceled Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteCanceledMessage ==
    \A message \in CheckedQuoteCanceledMessage :
        LET read == DecodeQuoteCanceledMessage(EncodeQuoteCanceledMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Purge Ack Message custom Group Ids Group decodes back to what was encoded, and leaves nothing over *)
RoundTripPurgeAckMessageCustomGroupIdsGroup ==
    \A message \in CheckedPurgeAckMessageCustomGroupIdsGroup :
        LET read == DecodePurgeAckMessageCustomGroupIdsGroup(EncodePurgeAckMessageCustomGroupIdsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Purge Ack Message custom Group Ids Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripPurgeAckMessageCustomGroupIdsGroups ==
    \A message \in CheckedPurgeAckMessageCustomGroupIdsGroups :
        LET read == DecodePurgeAckMessageCustomGroupIdsGroups(EncodePurgeAckMessageCustomGroupIdsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Purge Ack Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPurgeAckMessage ==
    \A message \in CheckedPurgeAckMessage :
        LET read == DecodePurgeAckMessage(EncodePurgeAckMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionReportMessage ==
    \A message \in CheckedExecutionReportMessage :
        LET read == DecodeExecutionReportMessage(EncodeExecutionReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Bust Correct Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBustCorrectMessage ==
    \A message \in CheckedTradeBustCorrectMessage :
        LET read == DecodeTradeBustCorrectMessage(EncodeTradeBustCorrectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Application Layer Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripApplicationLayerRejectMessage ==
    \A message \in CheckedApplicationLayerRejectMessage :
        LET read == DecodeApplicationLayerRejectMessage(EncodeApplicationLayerRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Risk Limit Update Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRiskLimitUpdateRequestMessage ==
    \A message \in CheckedRiskLimitUpdateRequestMessage :
        LET read == DecodeRiskLimitUpdateRequestMessage(EncodeRiskLimitUpdateRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Risk Action Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRiskActionRequestMessage ==
    \A message \in CheckedRiskActionRequestMessage :
        LET read == DecodeRiskActionRequestMessage(EncodeRiskActionRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Underlying Ref Data Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUnderlyingRefDataMessage ==
    \A message \in CheckedUnderlyingRefDataMessage :
        LET read == DecodeUnderlyingRefDataMessage(EncodeUnderlyingRefDataMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Ref Data Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentRefDataMessage ==
    \A message \in CheckedInstrumentRefDataMessage :
        LET read == DecodeInstrumentRefDataMessage(EncodeInstrumentRefDataMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mpid Configuration Acknowledgement Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMpidConfigurationAcknowledgementMessage ==
    \A message \in CheckedMpidConfigurationAcknowledgementMessage :
        LET read == DecodeMpidConfigurationAcknowledgementMessage(EncodeMpidConfigurationAcknowledgementMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Maker Symbol Appointment Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketMakerSymbolAppointmentMessage ==
    \A message \in CheckedMarketMakerSymbolAppointmentMessage :
        LET read == DecodeMarketMakerSymbolAppointmentMessage(EncodeMarketMakerSymbolAppointmentMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Session Configuration Acknowledgement Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSessionConfigurationAcknowledgementMessage ==
    \A message \in CheckedSessionConfigurationAcknowledgementMessage :
        LET read == DecodeSessionConfigurationAcknowledgementMessage(EncodeSessionConfigurationAcknowledgementMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Risk Control Acknowledgment Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRiskControlAcknowledgmentMessage ==
    \A message \in CheckedRiskControlAcknowledgmentMessage :
        LET read == DecodeRiskControlAcknowledgmentMessage(EncodeRiskControlAcknowledgmentMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Risk Control Alert Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRiskControlAlertMessage ==
    \A message \in CheckedRiskControlAlertMessage :
        LET read == DecodeRiskControlAlertMessage(EncodeRiskControlAlertMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sbe Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSbeMessage ==
    \A message \in CheckedSbeMessage :
        LET read == DecodeSbeMessage(EncodeSbeMessage(message))
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

(* A Payload is selected by the Schema Id it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag[1], message.tag[2], EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Packet Length is written from the bytes it frames *)
FramesSbeMessage ==
    \A message \in CheckedSbeMessage :
        LET bytes == EncodeSbeMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
