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
(* Client Payload, selected by Schema Id and Template Id                   *)
(***************************************************************************)

LoginRequestMessageCode == <<20000, 1>>  \* 0x4e20, 0x01
ClientHeartbeatMessageCode == <<20000, 4>>  \* 0x4e20, 0x04
LogoutRequestMessageCode == <<20000, 5>>  \* 0x4e20, 0x05
SequencedMessageHeaderMessageCode == <<20000, 7>>  \* 0x4e20, 0x07
SubsessionJoinMessageCode == <<20000, 8>>  \* 0x4e20, 0x08
SubsessionLeaveMessageCode == <<20000, 10>>  \* 0x4e20, 0x0a
NewOrderSingleMessageCode == <<20001, 1>>  \* 0x4e21, 0x01
OrderCancelReplaceRequestMessageCode == <<20001, 2>>  \* 0x4e21, 0x02
OrderCancelRequestMessageCode == <<20001, 3>>  \* 0x4e21, 0x03
NewBulkQuoteMessageCode == <<20001, 4>>  \* 0x4e21, 0x04
MassCancelRequestMessageCode == <<20001, 5>>  \* 0x4e21, 0x05
PurgeRequestMessageCode == <<20001, 6>>  \* 0x4e21, 0x06
RiskLimitUpdateRequestMessageCode == <<20001, 51>>  \* 0x4e21, 0x33
RiskActionRequestMessageCode == <<20001, 52>>  \* 0x4e21, 0x34

ClientPayload ==
    [ tag : {LoginRequestMessageCode}, body : LoginRequestMessage ]
        \cup [ tag : {ClientHeartbeatMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {LogoutRequestMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {SequencedMessageHeaderMessageCode}, body : SequencedMessageHeaderMessage ]
        \cup [ tag : {SubsessionJoinMessageCode}, body : SubsessionJoinMessage ]
        \cup [ tag : {SubsessionLeaveMessageCode}, body : SubsessionLeaveMessage ]
        \cup [ tag : {NewOrderSingleMessageCode}, body : NewOrderSingleMessage ]
        \cup [ tag : {OrderCancelReplaceRequestMessageCode}, body : OrderCancelReplaceRequestMessage ]
        \cup [ tag : {OrderCancelRequestMessageCode}, body : OrderCancelRequestMessage ]
        \cup [ tag : {NewBulkQuoteMessageCode}, body : NewBulkQuoteMessage ]
        \cup [ tag : {MassCancelRequestMessageCode}, body : MassCancelRequestMessage ]
        \cup [ tag : {PurgeRequestMessageCode}, body : PurgeRequestMessage ]
        \cup [ tag : {RiskLimitUpdateRequestMessageCode}, body : RiskLimitUpdateRequestMessage ]
        \cup [ tag : {RiskActionRequestMessageCode}, body : RiskActionRequestMessage ]

EncodeClientPayload(message) ==
    CASE message.tag = LoginRequestMessageCode -> EncodeLoginRequestMessage(message.body)
      [] message.tag = ClientHeartbeatMessageCode -> << >>
      [] message.tag = LogoutRequestMessageCode -> << >>
      [] message.tag = SequencedMessageHeaderMessageCode -> EncodeSequencedMessageHeaderMessage(message.body)
      [] message.tag = SubsessionJoinMessageCode -> EncodeSubsessionJoinMessage(message.body)
      [] message.tag = SubsessionLeaveMessageCode -> EncodeSubsessionLeaveMessage(message.body)
      [] message.tag = NewOrderSingleMessageCode -> EncodeNewOrderSingleMessage(message.body)
      [] message.tag = OrderCancelReplaceRequestMessageCode -> EncodeOrderCancelReplaceRequestMessage(message.body)
      [] message.tag = OrderCancelRequestMessageCode -> EncodeOrderCancelRequestMessage(message.body)
      [] message.tag = NewBulkQuoteMessageCode -> EncodeNewBulkQuoteMessage(message.body)
      [] message.tag = MassCancelRequestMessageCode -> EncodeMassCancelRequestMessage(message.body)
      [] message.tag = PurgeRequestMessageCode -> EncodePurgeRequestMessage(message.body)
      [] message.tag = RiskLimitUpdateRequestMessageCode -> EncodeRiskLimitUpdateRequestMessage(message.body)
      [] message.tag = RiskActionRequestMessageCode -> EncodeRiskActionRequestMessage(message.body)

DecodeClientPayload(schemaId, templateId, bytes) ==
    LET read ==
            CASE <<schemaId, templateId>> = LoginRequestMessageCode -> DecodeLoginRequestMessage(bytes)
              [] <<schemaId, templateId>> = ClientHeartbeatMessageCode -> Ok([empty |-> 0], bytes)
              [] <<schemaId, templateId>> = LogoutRequestMessageCode -> Ok([empty |-> 0], bytes)
              [] <<schemaId, templateId>> = SequencedMessageHeaderMessageCode -> DecodeSequencedMessageHeaderMessage(bytes)
              [] <<schemaId, templateId>> = SubsessionJoinMessageCode -> DecodeSubsessionJoinMessage(bytes)
              [] <<schemaId, templateId>> = SubsessionLeaveMessageCode -> DecodeSubsessionLeaveMessage(bytes)
              [] <<schemaId, templateId>> = NewOrderSingleMessageCode -> DecodeNewOrderSingleMessage(bytes)
              [] <<schemaId, templateId>> = OrderCancelReplaceRequestMessageCode -> DecodeOrderCancelReplaceRequestMessage(bytes)
              [] <<schemaId, templateId>> = OrderCancelRequestMessageCode -> DecodeOrderCancelRequestMessage(bytes)
              [] <<schemaId, templateId>> = NewBulkQuoteMessageCode -> DecodeNewBulkQuoteMessage(bytes)
              [] <<schemaId, templateId>> = MassCancelRequestMessageCode -> DecodeMassCancelRequestMessage(bytes)
              [] <<schemaId, templateId>> = PurgeRequestMessageCode -> DecodePurgeRequestMessage(bytes)
              [] <<schemaId, templateId>> = RiskLimitUpdateRequestMessageCode -> DecodeRiskLimitUpdateRequestMessage(bytes)
              [] <<schemaId, templateId>> = RiskActionRequestMessageCode -> DecodeRiskActionRequestMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> <<schemaId, templateId>>, body |-> read.value], read.rest)

ZeroClientPayload == [tag |-> LoginRequestMessageCode, body |-> ZeroLoginRequestMessage]

(* Each Client Payload in turn, at the values the message it names is checked at *)
CheckedClientPayload ==
    { [tag |-> LoginRequestMessageCode, body |-> one] : one \in CheckedLoginRequestMessage }
        \cup { [tag |-> ClientHeartbeatMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> LogoutRequestMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> SequencedMessageHeaderMessageCode, body |-> one] : one \in CheckedSequencedMessageHeaderMessage }
        \cup { [tag |-> SubsessionJoinMessageCode, body |-> one] : one \in CheckedSubsessionJoinMessage }
        \cup { [tag |-> SubsessionLeaveMessageCode, body |-> one] : one \in CheckedSubsessionLeaveMessage }
        \cup { [tag |-> NewOrderSingleMessageCode, body |-> one] : one \in CheckedNewOrderSingleMessage }
        \cup { [tag |-> OrderCancelReplaceRequestMessageCode, body |-> one] : one \in CheckedOrderCancelReplaceRequestMessage }
        \cup { [tag |-> OrderCancelRequestMessageCode, body |-> one] : one \in CheckedOrderCancelRequestMessage }
        \cup { [tag |-> NewBulkQuoteMessageCode, body |-> one] : one \in CheckedNewBulkQuoteMessage }
        \cup { [tag |-> MassCancelRequestMessageCode, body |-> one] : one \in CheckedMassCancelRequestMessage }
        \cup { [tag |-> PurgeRequestMessageCode, body |-> one] : one \in CheckedPurgeRequestMessage }
        \cup { [tag |-> RiskLimitUpdateRequestMessageCode, body |-> one] : one \in CheckedRiskLimitUpdateRequestMessage }
        \cup { [tag |-> RiskActionRequestMessageCode, body |-> one] : one \in CheckedRiskActionRequestMessage }

(***************************************************************************)
(* Client Sbe Message, framed by Packet Length                             *)
(***************************************************************************)

ClientSbeMessage ==
    [ blockLength   : Sample(2),
      version       : Sample(2),
      clientPayload : ClientPayload ]

EncodeClientSbeMessageBody(message) ==
    message.blockLength
        \o EncodeUIntLE(message.clientPayload.tag[2], 2)
        \o EncodeUIntLE(message.clientPayload.tag[1], 2)
        \o message.version
        \o EncodeClientPayload(message.clientPayload)

(* Packet Length counts the bytes it frames, so it is written from them *)
EncodeClientSbeMessage(message) ==
    LET body == EncodeClientSbeMessageBody(message)
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeClientSbeMessageBody(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET templateId == ReadUIntLE(blockLength.rest, 2) IN IF ~templateId.ok THEN Fail ELSE
    LET schemaId == ReadUIntLE(templateId.rest, 2) IN IF ~schemaId.ok THEN Fail ELSE
    LET version == ReadBytes(schemaId.rest, 2) IN IF ~version.ok THEN Fail ELSE
    LET clientPayload == DecodeClientPayload(schemaId.value, templateId.value, version.rest) IN IF ~clientPayload.ok THEN Fail ELSE
    Ok([ blockLength   |-> blockLength.value,
         version       |-> version.value,
         clientPayload |-> clientPayload.value ], clientPayload.rest)

DecodeClientSbeMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeClientSbeMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroClientSbeMessage ==
    [ blockLength   |-> [i \in 1 .. 2 |-> 0],
      version       |-> [i \in 1 .. 2 |-> 0],
      clientPayload |-> ZeroClientPayload ]

(* Client Sbe Message at zero, then each field in turn at the values it is checked at *)
CheckedClientSbeMessage ==
    { ZeroClientSbeMessage }
        \cup { [ZeroClientSbeMessage EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroClientSbeMessage EXCEPT !.version = one] : one \in Sample(2) }
        \cup { [ZeroClientSbeMessage EXCEPT !.clientPayload = one] : one \in CheckedClientPayload }

(* A run of Client Sbe Message, written one after another *)
RECURSIVE EncodeClientSbeMessageList(_)
EncodeClientSbeMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeClientSbeMessage(Head(messages)) \o EncodeClientSbeMessageList(Tail(messages))

(* As many Client Sbe Message as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadClientSbeMessageAll(_)
ReadClientSbeMessageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeClientSbeMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadClientSbeMessageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Client Sbe Message of each kind, for the lists that carry them *)
OneClientSbeMessage ==
    { [ZeroClientSbeMessage EXCEPT !.clientPayload = [tag |-> LoginRequestMessageCode, body |-> ZeroLoginRequestMessage]],
      [ZeroClientSbeMessage EXCEPT !.clientPayload = [tag |-> ClientHeartbeatMessageCode, body |-> [empty |-> 0]]],
      [ZeroClientSbeMessage EXCEPT !.clientPayload = [tag |-> LogoutRequestMessageCode, body |-> [empty |-> 0]]],
      [ZeroClientSbeMessage EXCEPT !.clientPayload = [tag |-> SequencedMessageHeaderMessageCode, body |-> ZeroSequencedMessageHeaderMessage]],
      [ZeroClientSbeMessage EXCEPT !.clientPayload = [tag |-> SubsessionJoinMessageCode, body |-> ZeroSubsessionJoinMessage]],
      [ZeroClientSbeMessage EXCEPT !.clientPayload = [tag |-> SubsessionLeaveMessageCode, body |-> ZeroSubsessionLeaveMessage]],
      [ZeroClientSbeMessage EXCEPT !.clientPayload = [tag |-> NewOrderSingleMessageCode, body |-> ZeroNewOrderSingleMessage]],
      [ZeroClientSbeMessage EXCEPT !.clientPayload = [tag |-> OrderCancelReplaceRequestMessageCode, body |-> ZeroOrderCancelReplaceRequestMessage]],
      [ZeroClientSbeMessage EXCEPT !.clientPayload = [tag |-> OrderCancelRequestMessageCode, body |-> ZeroOrderCancelRequestMessage]],
      [ZeroClientSbeMessage EXCEPT !.clientPayload = [tag |-> NewBulkQuoteMessageCode, body |-> ZeroNewBulkQuoteMessage]],
      [ZeroClientSbeMessage EXCEPT !.clientPayload = [tag |-> MassCancelRequestMessageCode, body |-> ZeroMassCancelRequestMessage]],
      [ZeroClientSbeMessage EXCEPT !.clientPayload = [tag |-> PurgeRequestMessageCode, body |-> ZeroPurgeRequestMessage]],
      [ZeroClientSbeMessage EXCEPT !.clientPayload = [tag |-> RiskLimitUpdateRequestMessageCode, body |-> ZeroRiskLimitUpdateRequestMessage]],
      [ZeroClientSbeMessage EXCEPT !.clientPayload = [tag |-> RiskActionRequestMessageCode, body |-> ZeroRiskActionRequestMessage]] }

(***************************************************************************)
(* Client Packet                                                           *)
(***************************************************************************)

ClientPacket ==
    [ clientSbeMessage : SampleLists(OneClientSbeMessage) ]

EncodeClientPacket(message) ==
    EncodeClientSbeMessageList(message.clientSbeMessage)

DecodeClientPacket(bytes) ==
    LET clientSbeMessage == ReadClientSbeMessageAll(bytes) IN IF ~clientSbeMessage.ok THEN Fail ELSE
    Ok([ clientSbeMessage |-> clientSbeMessage.value ], clientSbeMessage.rest)

ZeroClientPacket ==
    [ clientSbeMessage |-> << >> ]

(* Client Packet at zero, then each field in turn at the values it is checked at *)
CheckedClientPacket ==
    { ZeroClientPacket }
        \cup { [ZeroClientPacket EXCEPT !.clientSbeMessage = one] : one \in SampleLists(OneClientSbeMessage) }

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

(* Every Subsession Leave Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSubsessionLeaveMessage ==
    \A message \in CheckedSubsessionLeaveMessage :
        LET read == DecodeSubsessionLeaveMessage(EncodeSubsessionLeaveMessage(message))
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

(* Every Client Sbe Message decodes back to what was encoded, and leaves nothing over *)
RoundTripClientSbeMessage ==
    \A message \in CheckedClientSbeMessage :
        LET read == DecodeClientSbeMessage(EncodeClientSbeMessage(message))
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

(* A Client Payload is selected by the Schema Id it is written under *)
SelectsClientPayload ==
    \A message \in CheckedClientPayload :
        LET read == DecodeClientPayload(message.tag[1], message.tag[2], EncodeClientPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Packet Length is written from the bytes it frames *)
FramesClientSbeMessage ==
    \A message \in CheckedClientSbeMessage :
        LET bytes == EncodeClientSbeMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
