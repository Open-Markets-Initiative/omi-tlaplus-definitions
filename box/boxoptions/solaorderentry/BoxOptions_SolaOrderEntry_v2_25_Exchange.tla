------------- MODULE BoxOptions_SolaOrderEntry_v2_25_Exchange --------------
(***************************************************************************)
(* Box Options Market Sola Order Entry v2.25                               *)
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
(* Heartbeat Question: 20 bytes                                            *)
(***************************************************************************)

HeartbeatQuestion ==
    [ firstUserSequenceId                    : Sample(8),
      lastExchangeMessageIdSentToParticipant : Sample(6),
      timeLocal                              : Sample(6) ]

EncodeHeartbeatQuestion(message) ==
    message.firstUserSequenceId
        \o message.lastExchangeMessageIdSentToParticipant
        \o message.timeLocal

DecodeHeartbeatQuestion(bytes) ==
    LET firstUserSequenceId == ReadBytes(bytes, 8) IN IF ~firstUserSequenceId.ok THEN Fail ELSE
    LET lastExchangeMessageIdSentToParticipant == ReadBytes(firstUserSequenceId.rest, 6) IN IF ~lastExchangeMessageIdSentToParticipant.ok THEN Fail ELSE
    LET timeLocal == ReadBytes(lastExchangeMessageIdSentToParticipant.rest, 6) IN IF ~timeLocal.ok THEN Fail ELSE
    Ok([ firstUserSequenceId                    |-> firstUserSequenceId.value,
         lastExchangeMessageIdSentToParticipant |-> lastExchangeMessageIdSentToParticipant.value,
         timeLocal                              |-> timeLocal.value ], timeLocal.rest)

ZeroHeartbeatQuestion ==
    [ firstUserSequenceId                    |-> [i \in 1 .. 8 |-> 0],
      lastExchangeMessageIdSentToParticipant |-> [i \in 1 .. 6 |-> 0],
      timeLocal                              |-> [i \in 1 .. 6 |-> 0] ]

(* Heartbeat Question at zero, then each field in turn at the values it is checked at *)
CheckedHeartbeatQuestion ==
    { ZeroHeartbeatQuestion }
        \cup { [ZeroHeartbeatQuestion EXCEPT !.firstUserSequenceId = one] : one \in Sample(8) }
        \cup { [ZeroHeartbeatQuestion EXCEPT !.lastExchangeMessageIdSentToParticipant = one] : one \in Sample(6) }
        \cup { [ZeroHeartbeatQuestion EXCEPT !.timeLocal = one] : one \in Sample(6) }

(***************************************************************************)
(* Out Of Sequence: 22 bytes                                               *)
(***************************************************************************)

OutOfSequence ==
    [ receivedUserSequenceId     : Sample(8),
      expectedLastUserSequenceId : Sample(8),
      messageTimeLocal           : Sample(6) ]

EncodeOutOfSequence(message) ==
    message.receivedUserSequenceId
        \o message.expectedLastUserSequenceId
        \o message.messageTimeLocal

DecodeOutOfSequence(bytes) ==
    LET receivedUserSequenceId == ReadBytes(bytes, 8) IN IF ~receivedUserSequenceId.ok THEN Fail ELSE
    LET expectedLastUserSequenceId == ReadBytes(receivedUserSequenceId.rest, 8) IN IF ~expectedLastUserSequenceId.ok THEN Fail ELSE
    LET messageTimeLocal == ReadBytes(expectedLastUserSequenceId.rest, 6) IN IF ~messageTimeLocal.ok THEN Fail ELSE
    Ok([ receivedUserSequenceId     |-> receivedUserSequenceId.value,
         expectedLastUserSequenceId |-> expectedLastUserSequenceId.value,
         messageTimeLocal           |-> messageTimeLocal.value ], messageTimeLocal.rest)

ZeroOutOfSequence ==
    [ receivedUserSequenceId     |-> [i \in 1 .. 8 |-> 0],
      expectedLastUserSequenceId |-> [i \in 1 .. 8 |-> 0],
      messageTimeLocal           |-> [i \in 1 .. 6 |-> 0] ]

(* Out Of Sequence at zero, then each field in turn at the values it is checked at *)
CheckedOutOfSequence ==
    { ZeroOutOfSequence }
        \cup { [ZeroOutOfSequence EXCEPT !.receivedUserSequenceId = one] : one \in Sample(8) }
        \cup { [ZeroOutOfSequence EXCEPT !.expectedLastUserSequenceId = one] : one \in Sample(8) }
        \cup { [ZeroOutOfSequence EXCEPT !.messageTimeLocal = one] : one \in Sample(6) }

(***************************************************************************)
(* Technical Error Notice: 218 bytes                                       *)
(***************************************************************************)

TechnicalErrorNotice ==
    [ receivedMessageType             : Sample(2),
      precedingUserSequenceIdReceived : Sample(8),
      errorCode                       : Sample(4),
      errorPosition                   : Sample(4),
      errorMessage                    : Sample(100),
      startOfMessageInError           : Sample(100) ]

EncodeTechnicalErrorNotice(message) ==
    message.receivedMessageType
        \o message.precedingUserSequenceIdReceived
        \o message.errorCode
        \o message.errorPosition
        \o message.errorMessage
        \o message.startOfMessageInError

DecodeTechnicalErrorNotice(bytes) ==
    LET receivedMessageType == ReadBytes(bytes, 2) IN IF ~receivedMessageType.ok THEN Fail ELSE
    LET precedingUserSequenceIdReceived == ReadBytes(receivedMessageType.rest, 8) IN IF ~precedingUserSequenceIdReceived.ok THEN Fail ELSE
    LET errorCode == ReadBytes(precedingUserSequenceIdReceived.rest, 4) IN IF ~errorCode.ok THEN Fail ELSE
    LET errorPosition == ReadBytes(errorCode.rest, 4) IN IF ~errorPosition.ok THEN Fail ELSE
    LET errorMessage == ReadBytes(errorPosition.rest, 100) IN IF ~errorMessage.ok THEN Fail ELSE
    LET startOfMessageInError == ReadBytes(errorMessage.rest, 100) IN IF ~startOfMessageInError.ok THEN Fail ELSE
    Ok([ receivedMessageType             |-> receivedMessageType.value,
         precedingUserSequenceIdReceived |-> precedingUserSequenceIdReceived.value,
         errorCode                       |-> errorCode.value,
         errorPosition                   |-> errorPosition.value,
         errorMessage                    |-> errorMessage.value,
         startOfMessageInError           |-> startOfMessageInError.value ], startOfMessageInError.rest)

ZeroTechnicalErrorNotice ==
    [ receivedMessageType             |-> [i \in 1 .. 2 |-> 0],
      precedingUserSequenceIdReceived |-> [i \in 1 .. 8 |-> 0],
      errorCode                       |-> [i \in 1 .. 4 |-> 0],
      errorPosition                   |-> [i \in 1 .. 4 |-> 0],
      errorMessage                    |-> [i \in 1 .. 100 |-> 0],
      startOfMessageInError           |-> [i \in 1 .. 100 |-> 0] ]

(* Technical Error Notice at zero, then each field in turn at the values it is checked at *)
CheckedTechnicalErrorNotice ==
    { ZeroTechnicalErrorNotice }
        \cup { [ZeroTechnicalErrorNotice EXCEPT !.receivedMessageType = one] : one \in Sample(2) }
        \cup { [ZeroTechnicalErrorNotice EXCEPT !.precedingUserSequenceIdReceived = one] : one \in Sample(8) }
        \cup { [ZeroTechnicalErrorNotice EXCEPT !.errorCode = one] : one \in Sample(4) }
        \cup { [ZeroTechnicalErrorNotice EXCEPT !.errorPosition = one] : one \in Sample(4) }
        \cup { [ZeroTechnicalErrorNotice EXCEPT !.errorMessage = one] : one \in Sample(100) }
        \cup { [ZeroTechnicalErrorNotice EXCEPT !.startOfMessageInError = one] : one \in Sample(100) }

(***************************************************************************)
(* Disconnection Instruction Acknowledgement: 12 bytes                     *)
(***************************************************************************)

DisconnectionInstructionAcknowledgement ==
    [ currentSessionId           : Sample(4),
      lastUserSequenceIdReceived : Sample(8) ]

EncodeDisconnectionInstructionAcknowledgement(message) ==
    message.currentSessionId
        \o message.lastUserSequenceIdReceived

DecodeDisconnectionInstructionAcknowledgement(bytes) ==
    LET currentSessionId == ReadBytes(bytes, 4) IN IF ~currentSessionId.ok THEN Fail ELSE
    LET lastUserSequenceIdReceived == ReadBytes(currentSessionId.rest, 8) IN IF ~lastUserSequenceIdReceived.ok THEN Fail ELSE
    Ok([ currentSessionId           |-> currentSessionId.value,
         lastUserSequenceIdReceived |-> lastUserSequenceIdReceived.value ], lastUserSequenceIdReceived.rest)

ZeroDisconnectionInstructionAcknowledgement ==
    [ currentSessionId           |-> [i \in 1 .. 4 |-> 0],
      lastUserSequenceIdReceived |-> [i \in 1 .. 8 |-> 0] ]

(* Disconnection Instruction Acknowledgement at zero, then each field in turn at the values it is checked at *)
CheckedDisconnectionInstructionAcknowledgement ==
    { ZeroDisconnectionInstructionAcknowledgement }
        \cup { [ZeroDisconnectionInstructionAcknowledgement EXCEPT !.currentSessionId = one] : one \in Sample(4) }
        \cup { [ZeroDisconnectionInstructionAcknowledgement EXCEPT !.lastUserSequenceIdReceived = one] : one \in Sample(8) }

(***************************************************************************)
(* Connection Acknowledgement: 12 bytes                                    *)
(***************************************************************************)

ConnectionAcknowledgement ==
    [ currentSessionId           : Sample(4),
      lastUserSequenceIdReceived : Sample(8) ]

EncodeConnectionAcknowledgement(message) ==
    message.currentSessionId
        \o message.lastUserSequenceIdReceived

DecodeConnectionAcknowledgement(bytes) ==
    LET currentSessionId == ReadBytes(bytes, 4) IN IF ~currentSessionId.ok THEN Fail ELSE
    LET lastUserSequenceIdReceived == ReadBytes(currentSessionId.rest, 8) IN IF ~lastUserSequenceIdReceived.ok THEN Fail ELSE
    Ok([ currentSessionId           |-> currentSessionId.value,
         lastUserSequenceIdReceived |-> lastUserSequenceIdReceived.value ], lastUserSequenceIdReceived.rest)

ZeroConnectionAcknowledgement ==
    [ currentSessionId           |-> [i \in 1 .. 4 |-> 0],
      lastUserSequenceIdReceived |-> [i \in 1 .. 8 |-> 0] ]

(* Connection Acknowledgement at zero, then each field in turn at the values it is checked at *)
CheckedConnectionAcknowledgement ==
    { ZeroConnectionAcknowledgement }
        \cup { [ZeroConnectionAcknowledgement EXCEPT !.currentSessionId = one] : one \in Sample(4) }
        \cup { [ZeroConnectionAcknowledgement EXCEPT !.lastUserSequenceIdReceived = one] : one \in Sample(8) }

(***************************************************************************)
(* Disconnection Acknowledgement: 12 bytes                                 *)
(***************************************************************************)

DisconnectionAcknowledgement ==
    [ currentSessionId           : Sample(4),
      lastUserSequenceIdReceived : Sample(8) ]

EncodeDisconnectionAcknowledgement(message) ==
    message.currentSessionId
        \o message.lastUserSequenceIdReceived

DecodeDisconnectionAcknowledgement(bytes) ==
    LET currentSessionId == ReadBytes(bytes, 4) IN IF ~currentSessionId.ok THEN Fail ELSE
    LET lastUserSequenceIdReceived == ReadBytes(currentSessionId.rest, 8) IN IF ~lastUserSequenceIdReceived.ok THEN Fail ELSE
    Ok([ currentSessionId           |-> currentSessionId.value,
         lastUserSequenceIdReceived |-> lastUserSequenceIdReceived.value ], lastUserSequenceIdReceived.rest)

ZeroDisconnectionAcknowledgement ==
    [ currentSessionId           |-> [i \in 1 .. 4 |-> 0],
      lastUserSequenceIdReceived |-> [i \in 1 .. 8 |-> 0] ]

(* Disconnection Acknowledgement at zero, then each field in turn at the values it is checked at *)
CheckedDisconnectionAcknowledgement ==
    { ZeroDisconnectionAcknowledgement }
        \cup { [ZeroDisconnectionAcknowledgement EXCEPT !.currentSessionId = one] : one \in Sample(4) }
        \cup { [ZeroDisconnectionAcknowledgement EXCEPT !.lastUserSequenceIdReceived = one] : one \in Sample(8) }

(***************************************************************************)
(* End Of Transmission: 18 bytes                                           *)
(***************************************************************************)

EndOfTransmission ==
    [ endedSessionId             : Sample(4),
      lastUserSequenceIdReceived : Sample(8),
      time                       : Sample(6) ]

EncodeEndOfTransmission(message) ==
    message.endedSessionId
        \o message.lastUserSequenceIdReceived
        \o message.time

DecodeEndOfTransmission(bytes) ==
    LET endedSessionId == ReadBytes(bytes, 4) IN IF ~endedSessionId.ok THEN Fail ELSE
    LET lastUserSequenceIdReceived == ReadBytes(endedSessionId.rest, 8) IN IF ~lastUserSequenceIdReceived.ok THEN Fail ELSE
    LET time == ReadBytes(lastUserSequenceIdReceived.rest, 6) IN IF ~time.ok THEN Fail ELSE
    Ok([ endedSessionId             |-> endedSessionId.value,
         lastUserSequenceIdReceived |-> lastUserSequenceIdReceived.value,
         time                       |-> time.value ], time.rest)

ZeroEndOfTransmission ==
    [ endedSessionId             |-> [i \in 1 .. 4 |-> 0],
      lastUserSequenceIdReceived |-> [i \in 1 .. 8 |-> 0],
      time                       |-> [i \in 1 .. 6 |-> 0] ]

(* End Of Transmission at zero, then each field in turn at the values it is checked at *)
CheckedEndOfTransmission ==
    { ZeroEndOfTransmission }
        \cup { [ZeroEndOfTransmission EXCEPT !.endedSessionId = one] : one \in Sample(4) }
        \cup { [ZeroEndOfTransmission EXCEPT !.lastUserSequenceIdReceived = one] : one \in Sample(8) }
        \cup { [ZeroEndOfTransmission EXCEPT !.time = one] : one \in Sample(6) }

(***************************************************************************)
(* Error Notice: 358 bytes                                                 *)
(***************************************************************************)

ErrorNotice ==
    [ errorCode           : Sample(4),
      errorDescription    : Sample(100),
      group               : Sample(2),
      instrumentOptional  : Sample(4),
      orderIdErrorNotice  : Sample(20),
      auctionIdOptional   : Sample(6),
      originalMessageType : Sample(2),
      errorDetail         : Sample(200),
      clientOrderId       : Sample(20) ]

EncodeErrorNotice(message) ==
    message.errorCode
        \o message.errorDescription
        \o message.group
        \o message.instrumentOptional
        \o message.orderIdErrorNotice
        \o message.auctionIdOptional
        \o message.originalMessageType
        \o message.errorDetail
        \o message.clientOrderId

DecodeErrorNotice(bytes) ==
    LET errorCode == ReadBytes(bytes, 4) IN IF ~errorCode.ok THEN Fail ELSE
    LET errorDescription == ReadBytes(errorCode.rest, 100) IN IF ~errorDescription.ok THEN Fail ELSE
    LET group == ReadBytes(errorDescription.rest, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrumentOptional == ReadBytes(group.rest, 4) IN IF ~instrumentOptional.ok THEN Fail ELSE
    LET orderIdErrorNotice == ReadBytes(instrumentOptional.rest, 20) IN IF ~orderIdErrorNotice.ok THEN Fail ELSE
    LET auctionIdOptional == ReadBytes(orderIdErrorNotice.rest, 6) IN IF ~auctionIdOptional.ok THEN Fail ELSE
    LET originalMessageType == ReadBytes(auctionIdOptional.rest, 2) IN IF ~originalMessageType.ok THEN Fail ELSE
    LET errorDetail == ReadBytes(originalMessageType.rest, 200) IN IF ~errorDetail.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(errorDetail.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    Ok([ errorCode           |-> errorCode.value,
         errorDescription    |-> errorDescription.value,
         group               |-> group.value,
         instrumentOptional  |-> instrumentOptional.value,
         orderIdErrorNotice  |-> orderIdErrorNotice.value,
         auctionIdOptional   |-> auctionIdOptional.value,
         originalMessageType |-> originalMessageType.value,
         errorDetail         |-> errorDetail.value,
         clientOrderId       |-> clientOrderId.value ], clientOrderId.rest)

ZeroErrorNotice ==
    [ errorCode           |-> [i \in 1 .. 4 |-> 0],
      errorDescription    |-> [i \in 1 .. 100 |-> 0],
      group               |-> [i \in 1 .. 2 |-> 0],
      instrumentOptional  |-> [i \in 1 .. 4 |-> 0],
      orderIdErrorNotice  |-> [i \in 1 .. 20 |-> 0],
      auctionIdOptional   |-> [i \in 1 .. 6 |-> 0],
      originalMessageType |-> [i \in 1 .. 2 |-> 0],
      errorDetail         |-> [i \in 1 .. 200 |-> 0],
      clientOrderId       |-> [i \in 1 .. 20 |-> 0] ]

(* Error Notice at zero, then each field in turn at the values it is checked at *)
CheckedErrorNotice ==
    { ZeroErrorNotice }
        \cup { [ZeroErrorNotice EXCEPT !.errorCode = one] : one \in Sample(4) }
        \cup { [ZeroErrorNotice EXCEPT !.errorDescription = one] : one \in Sample(100) }
        \cup { [ZeroErrorNotice EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroErrorNotice EXCEPT !.instrumentOptional = one] : one \in Sample(4) }
        \cup { [ZeroErrorNotice EXCEPT !.orderIdErrorNotice = one] : one \in Sample(20) }
        \cup { [ZeroErrorNotice EXCEPT !.auctionIdOptional = one] : one \in Sample(6) }
        \cup { [ZeroErrorNotice EXCEPT !.originalMessageType = one] : one \in Sample(2) }
        \cup { [ZeroErrorNotice EXCEPT !.errorDetail = one] : one \in Sample(200) }
        \cup { [ZeroErrorNotice EXCEPT !.clientOrderId = one] : one \in Sample(20) }

(***************************************************************************)
(* Bulk Quote Data Acknowledgement: 18 bytes                               *)
(***************************************************************************)

BulkQuoteDataAcknowledgement ==
    [ group    : Sample(2),
      traderId : Sample(8),
      quoteId  : Sample(8) ]

EncodeBulkQuoteDataAcknowledgement(message) ==
    message.group
        \o message.traderId
        \o message.quoteId

DecodeBulkQuoteDataAcknowledgement(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET traderId == ReadBytes(group.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET quoteId == ReadBytes(traderId.rest, 8) IN IF ~quoteId.ok THEN Fail ELSE
    Ok([ group    |-> group.value,
         traderId |-> traderId.value,
         quoteId  |-> quoteId.value ], quoteId.rest)

ZeroBulkQuoteDataAcknowledgement ==
    [ group    |-> [i \in 1 .. 2 |-> 0],
      traderId |-> [i \in 1 .. 8 |-> 0],
      quoteId  |-> [i \in 1 .. 8 |-> 0] ]

(* Bulk Quote Data Acknowledgement at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuoteDataAcknowledgement ==
    { ZeroBulkQuoteDataAcknowledgement }
        \cup { [ZeroBulkQuoteDataAcknowledgement EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuoteDataAcknowledgement EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuoteDataAcknowledgement EXCEPT !.quoteId = one] : one \in Sample(8) }

(***************************************************************************)
(* Clearing Data: 20 bytes                                                 *)
(***************************************************************************)

ClearingData ==
    [ clearingInstruction   : Sample(12),
      accountType           : Sample(1),
      openClose             : Sample(1),
      hedgeSpec             : Sample(1),
      clearingOperationMode : Sample(1),
      clearingDestination   : Sample(4) ]

EncodeClearingData(message) ==
    message.clearingInstruction
        \o message.accountType
        \o message.openClose
        \o message.hedgeSpec
        \o message.clearingOperationMode
        \o message.clearingDestination

DecodeClearingData(bytes) ==
    LET clearingInstruction == ReadBytes(bytes, 12) IN IF ~clearingInstruction.ok THEN Fail ELSE
    LET accountType == ReadBytes(clearingInstruction.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET openClose == ReadBytes(accountType.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET hedgeSpec == ReadBytes(openClose.rest, 1) IN IF ~hedgeSpec.ok THEN Fail ELSE
    LET clearingOperationMode == ReadBytes(hedgeSpec.rest, 1) IN IF ~clearingOperationMode.ok THEN Fail ELSE
    LET clearingDestination == ReadBytes(clearingOperationMode.rest, 4) IN IF ~clearingDestination.ok THEN Fail ELSE
    Ok([ clearingInstruction   |-> clearingInstruction.value,
         accountType           |-> accountType.value,
         openClose             |-> openClose.value,
         hedgeSpec             |-> hedgeSpec.value,
         clearingOperationMode |-> clearingOperationMode.value,
         clearingDestination   |-> clearingDestination.value ], clearingDestination.rest)

ZeroClearingData ==
    [ clearingInstruction   |-> [i \in 1 .. 12 |-> 0],
      accountType           |-> [i \in 1 .. 1 |-> 0],
      openClose             |-> [i \in 1 .. 1 |-> 0],
      hedgeSpec             |-> [i \in 1 .. 1 |-> 0],
      clearingOperationMode |-> [i \in 1 .. 1 |-> 0],
      clearingDestination   |-> [i \in 1 .. 4 |-> 0] ]

(* Clearing Data at zero, then each field in turn at the values it is checked at *)
CheckedClearingData ==
    { ZeroClearingData }
        \cup { [ZeroClearingData EXCEPT !.clearingInstruction = one] : one \in Sample(12) }
        \cup { [ZeroClearingData EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroClearingData EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroClearingData EXCEPT !.hedgeSpec = one] : one \in Sample(1) }
        \cup { [ZeroClearingData EXCEPT !.clearingOperationMode = one] : one \in Sample(1) }
        \cup { [ZeroClearingData EXCEPT !.clearingDestination = one] : one \in Sample(4) }

(***************************************************************************)
(* Owner Data: 71 bytes                                                    *)
(***************************************************************************)

OwnerData ==
    [ clientOrderId : Sample(20),
      poundSign     : Sample(1),
      memo          : Sample(50) ]

EncodeOwnerData(message) ==
    message.clientOrderId
        \o message.poundSign
        \o message.memo

DecodeOwnerData(bytes) ==
    LET clientOrderId == ReadBytes(bytes, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET poundSign == ReadBytes(clientOrderId.rest, 1) IN IF ~poundSign.ok THEN Fail ELSE
    LET memo == ReadBytes(poundSign.rest, 50) IN IF ~memo.ok THEN Fail ELSE
    Ok([ clientOrderId |-> clientOrderId.value,
         poundSign     |-> poundSign.value,
         memo          |-> memo.value ], memo.rest)

ZeroOwnerData ==
    [ clientOrderId |-> [i \in 1 .. 20 |-> 0],
      poundSign     |-> [i \in 1 .. 1 |-> 0],
      memo          |-> [i \in 1 .. 50 |-> 0] ]

(* Owner Data at zero, then each field in turn at the values it is checked at *)
CheckedOwnerData ==
    { ZeroOwnerData }
        \cup { [ZeroOwnerData EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroOwnerData EXCEPT !.poundSign = one] : one \in Sample(1) }
        \cup { [ZeroOwnerData EXCEPT !.memo = one] : one \in Sample(50) }

(***************************************************************************)
(* Order Acknowledgement: 167 bytes                                        *)
(***************************************************************************)

OrderAcknowledgement ==
    [ group                : Sample(2),
      instrumentOptional   : Sample(4),
      traderId             : Sample(8),
      orderId              : Sample(8),
      status               : Sample(1),
      verbSide             : Sample(1),
      quantity             : Sample(8),
      assignedPrice        : Sample(10),
      clearingData         : ClearingData,
      ownerData            : OwnerData,
      originalOrderId      : Sample(8),
      reserved6            : Sample(6),
      additionalClientMemo : Sample(16),
      reserved4            : Sample(4) ]

EncodeOrderAcknowledgement(message) ==
    message.group
        \o message.instrumentOptional
        \o message.traderId
        \o message.orderId
        \o message.status
        \o message.verbSide
        \o message.quantity
        \o message.assignedPrice
        \o EncodeClearingData(message.clearingData)
        \o EncodeOwnerData(message.ownerData)
        \o message.originalOrderId
        \o message.reserved6
        \o message.additionalClientMemo
        \o message.reserved4

DecodeOrderAcknowledgement(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrumentOptional == ReadBytes(group.rest, 4) IN IF ~instrumentOptional.ok THEN Fail ELSE
    LET traderId == ReadBytes(instrumentOptional.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET orderId == ReadBytes(traderId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET status == ReadBytes(orderId.rest, 1) IN IF ~status.ok THEN Fail ELSE
    LET verbSide == ReadBytes(status.rest, 1) IN IF ~verbSide.ok THEN Fail ELSE
    LET quantity == ReadBytes(verbSide.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET assignedPrice == ReadBytes(quantity.rest, 10) IN IF ~assignedPrice.ok THEN Fail ELSE
    LET clearingData == DecodeClearingData(assignedPrice.rest) IN IF ~clearingData.ok THEN Fail ELSE
    LET ownerData == DecodeOwnerData(clearingData.rest) IN IF ~ownerData.ok THEN Fail ELSE
    LET originalOrderId == ReadBytes(ownerData.rest, 8) IN IF ~originalOrderId.ok THEN Fail ELSE
    LET reserved6 == ReadBytes(originalOrderId.rest, 6) IN IF ~reserved6.ok THEN Fail ELSE
    LET additionalClientMemo == ReadBytes(reserved6.rest, 16) IN IF ~additionalClientMemo.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(additionalClientMemo.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    Ok([ group                |-> group.value,
         instrumentOptional   |-> instrumentOptional.value,
         traderId             |-> traderId.value,
         orderId              |-> orderId.value,
         status               |-> status.value,
         verbSide             |-> verbSide.value,
         quantity             |-> quantity.value,
         assignedPrice        |-> assignedPrice.value,
         clearingData         |-> clearingData.value,
         ownerData            |-> ownerData.value,
         originalOrderId      |-> originalOrderId.value,
         reserved6            |-> reserved6.value,
         additionalClientMemo |-> additionalClientMemo.value,
         reserved4            |-> reserved4.value ], reserved4.rest)

ZeroOrderAcknowledgement ==
    [ group                |-> [i \in 1 .. 2 |-> 0],
      instrumentOptional   |-> [i \in 1 .. 4 |-> 0],
      traderId             |-> [i \in 1 .. 8 |-> 0],
      orderId              |-> [i \in 1 .. 8 |-> 0],
      status               |-> [i \in 1 .. 1 |-> 0],
      verbSide             |-> [i \in 1 .. 1 |-> 0],
      quantity             |-> [i \in 1 .. 8 |-> 0],
      assignedPrice        |-> [i \in 1 .. 10 |-> 0],
      clearingData         |-> ZeroClearingData,
      ownerData            |-> ZeroOwnerData,
      originalOrderId      |-> [i \in 1 .. 8 |-> 0],
      reserved6            |-> [i \in 1 .. 6 |-> 0],
      additionalClientMemo |-> [i \in 1 .. 16 |-> 0],
      reserved4            |-> [i \in 1 .. 4 |-> 0] ]

(* Order Acknowledgement at zero, then each field in turn at the values it is checked at *)
CheckedOrderAcknowledgement ==
    { ZeroOrderAcknowledgement }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.instrumentOptional = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.status = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.verbSide = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.assignedPrice = one] : one \in Sample(10) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.clearingData = one] : one \in CheckedClearingData }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.ownerData = one] : one \in CheckedOwnerData }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.originalOrderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.reserved6 = one] : one \in Sample(6) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.additionalClientMemo = one] : one \in Sample(16) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.reserved4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Global Cancellation Confirmation: 11 bytes                              *)
(***************************************************************************)

GlobalCancellationConfirmation ==
    [ group              : Sample(2),
      traderId           : Sample(8),
      typeOfCancellation : Sample(1) ]

EncodeGlobalCancellationConfirmation(message) ==
    message.group
        \o message.traderId
        \o message.typeOfCancellation

DecodeGlobalCancellationConfirmation(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET traderId == ReadBytes(group.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET typeOfCancellation == ReadBytes(traderId.rest, 1) IN IF ~typeOfCancellation.ok THEN Fail ELSE
    Ok([ group              |-> group.value,
         traderId           |-> traderId.value,
         typeOfCancellation |-> typeOfCancellation.value ], typeOfCancellation.rest)

ZeroGlobalCancellationConfirmation ==
    [ group              |-> [i \in 1 .. 2 |-> 0],
      traderId           |-> [i \in 1 .. 8 |-> 0],
      typeOfCancellation |-> [i \in 1 .. 1 |-> 0] ]

(* Global Cancellation Confirmation at zero, then each field in turn at the values it is checked at *)
CheckedGlobalCancellationConfirmation ==
    { ZeroGlobalCancellationConfirmation }
        \cup { [ZeroGlobalCancellationConfirmation EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroGlobalCancellationConfirmation EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroGlobalCancellationConfirmation EXCEPT !.typeOfCancellation = one] : one \in Sample(1) }

(***************************************************************************)
(* Clearing Data: 20 bytes                                                 *)
(***************************************************************************)

ClearingData2 ==
    [ clearingInstruction   : Sample(12),
      accountType           : Sample(1),
      openClose             : Sample(1),
      hedgeSpec             : Sample(1),
      clearingOperationMode : Sample(1),
      clearingDestination   : Sample(4) ]

EncodeClearingData2(message) ==
    message.clearingInstruction
        \o message.accountType
        \o message.openClose
        \o message.hedgeSpec
        \o message.clearingOperationMode
        \o message.clearingDestination

DecodeClearingData2(bytes) ==
    LET clearingInstruction == ReadBytes(bytes, 12) IN IF ~clearingInstruction.ok THEN Fail ELSE
    LET accountType == ReadBytes(clearingInstruction.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET openClose == ReadBytes(accountType.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET hedgeSpec == ReadBytes(openClose.rest, 1) IN IF ~hedgeSpec.ok THEN Fail ELSE
    LET clearingOperationMode == ReadBytes(hedgeSpec.rest, 1) IN IF ~clearingOperationMode.ok THEN Fail ELSE
    LET clearingDestination == ReadBytes(clearingOperationMode.rest, 4) IN IF ~clearingDestination.ok THEN Fail ELSE
    Ok([ clearingInstruction   |-> clearingInstruction.value,
         accountType           |-> accountType.value,
         openClose             |-> openClose.value,
         hedgeSpec             |-> hedgeSpec.value,
         clearingOperationMode |-> clearingOperationMode.value,
         clearingDestination   |-> clearingDestination.value ], clearingDestination.rest)

ZeroClearingData2 ==
    [ clearingInstruction   |-> [i \in 1 .. 12 |-> 0],
      accountType           |-> [i \in 1 .. 1 |-> 0],
      openClose             |-> [i \in 1 .. 1 |-> 0],
      hedgeSpec             |-> [i \in 1 .. 1 |-> 0],
      clearingOperationMode |-> [i \in 1 .. 1 |-> 0],
      clearingDestination   |-> [i \in 1 .. 4 |-> 0] ]

(* Clearing Data at zero, then each field in turn at the values it is checked at *)
CheckedClearingData2 ==
    { ZeroClearingData2 }
        \cup { [ZeroClearingData2 EXCEPT !.clearingInstruction = one] : one \in Sample(12) }
        \cup { [ZeroClearingData2 EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroClearingData2 EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroClearingData2 EXCEPT !.hedgeSpec = one] : one \in Sample(1) }
        \cup { [ZeroClearingData2 EXCEPT !.clearingOperationMode = one] : one \in Sample(1) }
        \cup { [ZeroClearingData2 EXCEPT !.clearingDestination = one] : one \in Sample(4) }

(***************************************************************************)
(* Owner Data: 71 bytes                                                    *)
(***************************************************************************)

OwnerData2 ==
    [ clientOrderId : Sample(20),
      poundSign     : Sample(1),
      memo          : Sample(50) ]

EncodeOwnerData2(message) ==
    message.clientOrderId
        \o message.poundSign
        \o message.memo

DecodeOwnerData2(bytes) ==
    LET clientOrderId == ReadBytes(bytes, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET poundSign == ReadBytes(clientOrderId.rest, 1) IN IF ~poundSign.ok THEN Fail ELSE
    LET memo == ReadBytes(poundSign.rest, 50) IN IF ~memo.ok THEN Fail ELSE
    Ok([ clientOrderId |-> clientOrderId.value,
         poundSign     |-> poundSign.value,
         memo          |-> memo.value ], memo.rest)

ZeroOwnerData2 ==
    [ clientOrderId |-> [i \in 1 .. 20 |-> 0],
      poundSign     |-> [i \in 1 .. 1 |-> 0],
      memo          |-> [i \in 1 .. 50 |-> 0] ]

(* Owner Data at zero, then each field in turn at the values it is checked at *)
CheckedOwnerData2 ==
    { ZeroOwnerData2 }
        \cup { [ZeroOwnerData2 EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroOwnerData2 EXCEPT !.poundSign = one] : one \in Sample(1) }
        \cup { [ZeroOwnerData2 EXCEPT !.memo = one] : one \in Sample(50) }

(***************************************************************************)
(* Improvement Order Acknowlegment: 167 bytes                              *)
(***************************************************************************)

ImprovementOrderAcknowlegment ==
    [ group                : Sample(2),
      instrumentOptional   : Sample(4),
      traderId             : Sample(8),
      orderId              : Sample(8),
      status               : Sample(1),
      verbSide             : Sample(1),
      quantity             : Sample(8),
      assignedPrice        : Sample(10),
      clearingData         : ClearingData2,
      ownerData            : OwnerData2,
      originalOrderId      : Sample(8),
      auctionId            : Sample(6),
      additionalClientMemo : Sample(16),
      reserved4            : Sample(4) ]

EncodeImprovementOrderAcknowlegment(message) ==
    message.group
        \o message.instrumentOptional
        \o message.traderId
        \o message.orderId
        \o message.status
        \o message.verbSide
        \o message.quantity
        \o message.assignedPrice
        \o EncodeClearingData2(message.clearingData)
        \o EncodeOwnerData2(message.ownerData)
        \o message.originalOrderId
        \o message.auctionId
        \o message.additionalClientMemo
        \o message.reserved4

DecodeImprovementOrderAcknowlegment(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrumentOptional == ReadBytes(group.rest, 4) IN IF ~instrumentOptional.ok THEN Fail ELSE
    LET traderId == ReadBytes(instrumentOptional.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET orderId == ReadBytes(traderId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET status == ReadBytes(orderId.rest, 1) IN IF ~status.ok THEN Fail ELSE
    LET verbSide == ReadBytes(status.rest, 1) IN IF ~verbSide.ok THEN Fail ELSE
    LET quantity == ReadBytes(verbSide.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET assignedPrice == ReadBytes(quantity.rest, 10) IN IF ~assignedPrice.ok THEN Fail ELSE
    LET clearingData == DecodeClearingData2(assignedPrice.rest) IN IF ~clearingData.ok THEN Fail ELSE
    LET ownerData == DecodeOwnerData2(clearingData.rest) IN IF ~ownerData.ok THEN Fail ELSE
    LET originalOrderId == ReadBytes(ownerData.rest, 8) IN IF ~originalOrderId.ok THEN Fail ELSE
    LET auctionId == ReadBytes(originalOrderId.rest, 6) IN IF ~auctionId.ok THEN Fail ELSE
    LET additionalClientMemo == ReadBytes(auctionId.rest, 16) IN IF ~additionalClientMemo.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(additionalClientMemo.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    Ok([ group                |-> group.value,
         instrumentOptional   |-> instrumentOptional.value,
         traderId             |-> traderId.value,
         orderId              |-> orderId.value,
         status               |-> status.value,
         verbSide             |-> verbSide.value,
         quantity             |-> quantity.value,
         assignedPrice        |-> assignedPrice.value,
         clearingData         |-> clearingData.value,
         ownerData            |-> ownerData.value,
         originalOrderId      |-> originalOrderId.value,
         auctionId            |-> auctionId.value,
         additionalClientMemo |-> additionalClientMemo.value,
         reserved4            |-> reserved4.value ], reserved4.rest)

ZeroImprovementOrderAcknowlegment ==
    [ group                |-> [i \in 1 .. 2 |-> 0],
      instrumentOptional   |-> [i \in 1 .. 4 |-> 0],
      traderId             |-> [i \in 1 .. 8 |-> 0],
      orderId              |-> [i \in 1 .. 8 |-> 0],
      status               |-> [i \in 1 .. 1 |-> 0],
      verbSide             |-> [i \in 1 .. 1 |-> 0],
      quantity             |-> [i \in 1 .. 8 |-> 0],
      assignedPrice        |-> [i \in 1 .. 10 |-> 0],
      clearingData         |-> ZeroClearingData2,
      ownerData            |-> ZeroOwnerData2,
      originalOrderId      |-> [i \in 1 .. 8 |-> 0],
      auctionId            |-> [i \in 1 .. 6 |-> 0],
      additionalClientMemo |-> [i \in 1 .. 16 |-> 0],
      reserved4            |-> [i \in 1 .. 4 |-> 0] ]

(* Improvement Order Acknowlegment at zero, then each field in turn at the values it is checked at *)
CheckedImprovementOrderAcknowlegment ==
    { ZeroImprovementOrderAcknowlegment }
        \cup { [ZeroImprovementOrderAcknowlegment EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroImprovementOrderAcknowlegment EXCEPT !.instrumentOptional = one] : one \in Sample(4) }
        \cup { [ZeroImprovementOrderAcknowlegment EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroImprovementOrderAcknowlegment EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroImprovementOrderAcknowlegment EXCEPT !.status = one] : one \in Sample(1) }
        \cup { [ZeroImprovementOrderAcknowlegment EXCEPT !.verbSide = one] : one \in Sample(1) }
        \cup { [ZeroImprovementOrderAcknowlegment EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroImprovementOrderAcknowlegment EXCEPT !.assignedPrice = one] : one \in Sample(10) }
        \cup { [ZeroImprovementOrderAcknowlegment EXCEPT !.clearingData = one] : one \in CheckedClearingData2 }
        \cup { [ZeroImprovementOrderAcknowlegment EXCEPT !.ownerData = one] : one \in CheckedOwnerData2 }
        \cup { [ZeroImprovementOrderAcknowlegment EXCEPT !.originalOrderId = one] : one \in Sample(8) }
        \cup { [ZeroImprovementOrderAcknowlegment EXCEPT !.auctionId = one] : one \in Sample(6) }
        \cup { [ZeroImprovementOrderAcknowlegment EXCEPT !.additionalClientMemo = one] : one \in Sample(16) }
        \cup { [ZeroImprovementOrderAcknowlegment EXCEPT !.reserved4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Clearing Data: 20 bytes                                                 *)
(***************************************************************************)

ClearingData3 ==
    [ clearingInstruction   : Sample(12),
      accountType           : Sample(1),
      openClose             : Sample(1),
      hedgeSpec             : Sample(1),
      clearingOperationMode : Sample(1),
      clearingDestination   : Sample(4) ]

EncodeClearingData3(message) ==
    message.clearingInstruction
        \o message.accountType
        \o message.openClose
        \o message.hedgeSpec
        \o message.clearingOperationMode
        \o message.clearingDestination

DecodeClearingData3(bytes) ==
    LET clearingInstruction == ReadBytes(bytes, 12) IN IF ~clearingInstruction.ok THEN Fail ELSE
    LET accountType == ReadBytes(clearingInstruction.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET openClose == ReadBytes(accountType.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET hedgeSpec == ReadBytes(openClose.rest, 1) IN IF ~hedgeSpec.ok THEN Fail ELSE
    LET clearingOperationMode == ReadBytes(hedgeSpec.rest, 1) IN IF ~clearingOperationMode.ok THEN Fail ELSE
    LET clearingDestination == ReadBytes(clearingOperationMode.rest, 4) IN IF ~clearingDestination.ok THEN Fail ELSE
    Ok([ clearingInstruction   |-> clearingInstruction.value,
         accountType           |-> accountType.value,
         openClose             |-> openClose.value,
         hedgeSpec             |-> hedgeSpec.value,
         clearingOperationMode |-> clearingOperationMode.value,
         clearingDestination   |-> clearingDestination.value ], clearingDestination.rest)

ZeroClearingData3 ==
    [ clearingInstruction   |-> [i \in 1 .. 12 |-> 0],
      accountType           |-> [i \in 1 .. 1 |-> 0],
      openClose             |-> [i \in 1 .. 1 |-> 0],
      hedgeSpec             |-> [i \in 1 .. 1 |-> 0],
      clearingOperationMode |-> [i \in 1 .. 1 |-> 0],
      clearingDestination   |-> [i \in 1 .. 4 |-> 0] ]

(* Clearing Data at zero, then each field in turn at the values it is checked at *)
CheckedClearingData3 ==
    { ZeroClearingData3 }
        \cup { [ZeroClearingData3 EXCEPT !.clearingInstruction = one] : one \in Sample(12) }
        \cup { [ZeroClearingData3 EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroClearingData3 EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroClearingData3 EXCEPT !.hedgeSpec = one] : one \in Sample(1) }
        \cup { [ZeroClearingData3 EXCEPT !.clearingOperationMode = one] : one \in Sample(1) }
        \cup { [ZeroClearingData3 EXCEPT !.clearingDestination = one] : one \in Sample(4) }

(***************************************************************************)
(* Owner Data: 71 bytes                                                    *)
(***************************************************************************)

OwnerData3 ==
    [ clientOrderId : Sample(20),
      poundSign     : Sample(1),
      memo          : Sample(50) ]

EncodeOwnerData3(message) ==
    message.clientOrderId
        \o message.poundSign
        \o message.memo

DecodeOwnerData3(bytes) ==
    LET clientOrderId == ReadBytes(bytes, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET poundSign == ReadBytes(clientOrderId.rest, 1) IN IF ~poundSign.ok THEN Fail ELSE
    LET memo == ReadBytes(poundSign.rest, 50) IN IF ~memo.ok THEN Fail ELSE
    Ok([ clientOrderId |-> clientOrderId.value,
         poundSign     |-> poundSign.value,
         memo          |-> memo.value ], memo.rest)

ZeroOwnerData3 ==
    [ clientOrderId |-> [i \in 1 .. 20 |-> 0],
      poundSign     |-> [i \in 1 .. 1 |-> 0],
      memo          |-> [i \in 1 .. 50 |-> 0] ]

(* Owner Data at zero, then each field in turn at the values it is checked at *)
CheckedOwnerData3 ==
    { ZeroOwnerData3 }
        \cup { [ZeroOwnerData3 EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroOwnerData3 EXCEPT !.poundSign = one] : one \in Sample(1) }
        \cup { [ZeroOwnerData3 EXCEPT !.memo = one] : one \in Sample(50) }

(***************************************************************************)
(* Order Modification Acknowledgement: 167 bytes                           *)
(***************************************************************************)

OrderModificationAcknowledgement ==
    [ group                : Sample(2),
      instrumentOptional   : Sample(4),
      traderId             : Sample(8),
      orderId              : Sample(8),
      status               : Sample(1),
      verbSide             : Sample(1),
      quantity             : Sample(8),
      assignedPrice        : Sample(10),
      clearingData         : ClearingData3,
      ownerData            : OwnerData3,
      originalOrderId      : Sample(8),
      reserved6            : Sample(6),
      additionalClientMemo : Sample(16),
      reserved4            : Sample(4) ]

EncodeOrderModificationAcknowledgement(message) ==
    message.group
        \o message.instrumentOptional
        \o message.traderId
        \o message.orderId
        \o message.status
        \o message.verbSide
        \o message.quantity
        \o message.assignedPrice
        \o EncodeClearingData3(message.clearingData)
        \o EncodeOwnerData3(message.ownerData)
        \o message.originalOrderId
        \o message.reserved6
        \o message.additionalClientMemo
        \o message.reserved4

DecodeOrderModificationAcknowledgement(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrumentOptional == ReadBytes(group.rest, 4) IN IF ~instrumentOptional.ok THEN Fail ELSE
    LET traderId == ReadBytes(instrumentOptional.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET orderId == ReadBytes(traderId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET status == ReadBytes(orderId.rest, 1) IN IF ~status.ok THEN Fail ELSE
    LET verbSide == ReadBytes(status.rest, 1) IN IF ~verbSide.ok THEN Fail ELSE
    LET quantity == ReadBytes(verbSide.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET assignedPrice == ReadBytes(quantity.rest, 10) IN IF ~assignedPrice.ok THEN Fail ELSE
    LET clearingData == DecodeClearingData3(assignedPrice.rest) IN IF ~clearingData.ok THEN Fail ELSE
    LET ownerData == DecodeOwnerData3(clearingData.rest) IN IF ~ownerData.ok THEN Fail ELSE
    LET originalOrderId == ReadBytes(ownerData.rest, 8) IN IF ~originalOrderId.ok THEN Fail ELSE
    LET reserved6 == ReadBytes(originalOrderId.rest, 6) IN IF ~reserved6.ok THEN Fail ELSE
    LET additionalClientMemo == ReadBytes(reserved6.rest, 16) IN IF ~additionalClientMemo.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(additionalClientMemo.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    Ok([ group                |-> group.value,
         instrumentOptional   |-> instrumentOptional.value,
         traderId             |-> traderId.value,
         orderId              |-> orderId.value,
         status               |-> status.value,
         verbSide             |-> verbSide.value,
         quantity             |-> quantity.value,
         assignedPrice        |-> assignedPrice.value,
         clearingData         |-> clearingData.value,
         ownerData            |-> ownerData.value,
         originalOrderId      |-> originalOrderId.value,
         reserved6            |-> reserved6.value,
         additionalClientMemo |-> additionalClientMemo.value,
         reserved4            |-> reserved4.value ], reserved4.rest)

ZeroOrderModificationAcknowledgement ==
    [ group                |-> [i \in 1 .. 2 |-> 0],
      instrumentOptional   |-> [i \in 1 .. 4 |-> 0],
      traderId             |-> [i \in 1 .. 8 |-> 0],
      orderId              |-> [i \in 1 .. 8 |-> 0],
      status               |-> [i \in 1 .. 1 |-> 0],
      verbSide             |-> [i \in 1 .. 1 |-> 0],
      quantity             |-> [i \in 1 .. 8 |-> 0],
      assignedPrice        |-> [i \in 1 .. 10 |-> 0],
      clearingData         |-> ZeroClearingData3,
      ownerData            |-> ZeroOwnerData3,
      originalOrderId      |-> [i \in 1 .. 8 |-> 0],
      reserved6            |-> [i \in 1 .. 6 |-> 0],
      additionalClientMemo |-> [i \in 1 .. 16 |-> 0],
      reserved4            |-> [i \in 1 .. 4 |-> 0] ]

(* Order Modification Acknowledgement at zero, then each field in turn at the values it is checked at *)
CheckedOrderModificationAcknowledgement ==
    { ZeroOrderModificationAcknowledgement }
        \cup { [ZeroOrderModificationAcknowledgement EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroOrderModificationAcknowledgement EXCEPT !.instrumentOptional = one] : one \in Sample(4) }
        \cup { [ZeroOrderModificationAcknowledgement EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderModificationAcknowledgement EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderModificationAcknowledgement EXCEPT !.status = one] : one \in Sample(1) }
        \cup { [ZeroOrderModificationAcknowledgement EXCEPT !.verbSide = one] : one \in Sample(1) }
        \cup { [ZeroOrderModificationAcknowledgement EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroOrderModificationAcknowledgement EXCEPT !.assignedPrice = one] : one \in Sample(10) }
        \cup { [ZeroOrderModificationAcknowledgement EXCEPT !.clearingData = one] : one \in CheckedClearingData3 }
        \cup { [ZeroOrderModificationAcknowledgement EXCEPT !.ownerData = one] : one \in CheckedOwnerData3 }
        \cup { [ZeroOrderModificationAcknowledgement EXCEPT !.originalOrderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderModificationAcknowledgement EXCEPT !.reserved6 = one] : one \in Sample(6) }
        \cup { [ZeroOrderModificationAcknowledgement EXCEPT !.additionalClientMemo = one] : one \in Sample(16) }
        \cup { [ZeroOrderModificationAcknowledgement EXCEPT !.reserved4 = one] : one \in Sample(4) }

(***************************************************************************)
(* New Complex Order Instrument Acknowledgement Occurrence: 16 bytes       *)
(***************************************************************************)

NewComplexOrderInstrumentAcknowledgementOccurrence ==
    [ legGroup         : Sample(2),
      legInstrumentId  : Sample(4),
      legVerb          : Sample(1),
      reserved1        : Sample(1),
      legQuantityRatio : Sample(8) ]

EncodeNewComplexOrderInstrumentAcknowledgementOccurrence(message) ==
    message.legGroup
        \o message.legInstrumentId
        \o message.legVerb
        \o message.reserved1
        \o message.legQuantityRatio

DecodeNewComplexOrderInstrumentAcknowledgementOccurrence(bytes) ==
    LET legGroup == ReadBytes(bytes, 2) IN IF ~legGroup.ok THEN Fail ELSE
    LET legInstrumentId == ReadBytes(legGroup.rest, 4) IN IF ~legInstrumentId.ok THEN Fail ELSE
    LET legVerb == ReadBytes(legInstrumentId.rest, 1) IN IF ~legVerb.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(legVerb.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET legQuantityRatio == ReadBytes(reserved1.rest, 8) IN IF ~legQuantityRatio.ok THEN Fail ELSE
    Ok([ legGroup         |-> legGroup.value,
         legInstrumentId  |-> legInstrumentId.value,
         legVerb          |-> legVerb.value,
         reserved1        |-> reserved1.value,
         legQuantityRatio |-> legQuantityRatio.value ], legQuantityRatio.rest)

ZeroNewComplexOrderInstrumentAcknowledgementOccurrence ==
    [ legGroup         |-> [i \in 1 .. 2 |-> 0],
      legInstrumentId  |-> [i \in 1 .. 4 |-> 0],
      legVerb          |-> [i \in 1 .. 1 |-> 0],
      reserved1        |-> [i \in 1 .. 1 |-> 0],
      legQuantityRatio |-> [i \in 1 .. 8 |-> 0] ]

(* New Complex Order Instrument Acknowledgement Occurrence at zero, then each field in turn at the values it is checked at *)
CheckedNewComplexOrderInstrumentAcknowledgementOccurrence ==
    { ZeroNewComplexOrderInstrumentAcknowledgementOccurrence }
        \cup { [ZeroNewComplexOrderInstrumentAcknowledgementOccurrence EXCEPT !.legGroup = one] : one \in Sample(2) }
        \cup { [ZeroNewComplexOrderInstrumentAcknowledgementOccurrence EXCEPT !.legInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexOrderInstrumentAcknowledgementOccurrence EXCEPT !.legVerb = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderInstrumentAcknowledgementOccurrence EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderInstrumentAcknowledgementOccurrence EXCEPT !.legQuantityRatio = one] : one \in Sample(8) }

(* A run of New Complex Order Instrument Acknowledgement Occurrence, written one after another *)
RECURSIVE EncodeNewComplexOrderInstrumentAcknowledgementOccurrenceList(_)
EncodeNewComplexOrderInstrumentAcknowledgementOccurrenceList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeNewComplexOrderInstrumentAcknowledgementOccurrence(Head(messages)) \o EncodeNewComplexOrderInstrumentAcknowledgementOccurrenceList(Tail(messages))

(* As many New Complex Order Instrument Acknowledgement Occurrence as the field that counts them says *)
RECURSIVE ReadNewComplexOrderInstrumentAcknowledgementOccurrenceList(_, _)
ReadNewComplexOrderInstrumentAcknowledgementOccurrenceList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeNewComplexOrderInstrumentAcknowledgementOccurrence(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadNewComplexOrderInstrumentAcknowledgementOccurrenceList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One New Complex Order Instrument Acknowledgement Occurrence of each kind, for the lists that carry them *)
OneNewComplexOrderInstrumentAcknowledgementOccurrence == { ZeroNewComplexOrderInstrumentAcknowledgementOccurrence }

(***************************************************************************)
(* New Complex Order Instrument Acknowledgement                            *)
(***************************************************************************)

NewComplexOrderInstrumentAcknowledgement ==
    [ strategyGroup                                      : Sample(2),
      strategyInstrumentId                               : Sample(4),
      creationStatus                                     : Sample(1),
      newComplexOrderInstrumentAcknowledgementOccurrence : SampleLists(OneNewComplexOrderInstrumentAcknowledgementOccurrence) ]

EncodeNewComplexOrderInstrumentAcknowledgement(message) ==
    message.strategyGroup
        \o message.strategyInstrumentId
        \o message.creationStatus
        \o EncodeUIntBE(Len(message.newComplexOrderInstrumentAcknowledgementOccurrence), 2)
        \o EncodeNewComplexOrderInstrumentAcknowledgementOccurrenceList(message.newComplexOrderInstrumentAcknowledgementOccurrence)

DecodeNewComplexOrderInstrumentAcknowledgement(bytes) ==
    LET strategyGroup == ReadBytes(bytes, 2) IN IF ~strategyGroup.ok THEN Fail ELSE
    LET strategyInstrumentId == ReadBytes(strategyGroup.rest, 4) IN IF ~strategyInstrumentId.ok THEN Fail ELSE
    LET creationStatus == ReadBytes(strategyInstrumentId.rest, 1) IN IF ~creationStatus.ok THEN Fail ELSE
    LET numberOfLegs == ReadUIntBE(creationStatus.rest, 2) IN IF ~numberOfLegs.ok THEN Fail ELSE
    LET newComplexOrderInstrumentAcknowledgementOccurrence == ReadNewComplexOrderInstrumentAcknowledgementOccurrenceList(numberOfLegs.rest, numberOfLegs.value) IN IF ~newComplexOrderInstrumentAcknowledgementOccurrence.ok THEN Fail ELSE
    Ok([ strategyGroup                                      |-> strategyGroup.value,
         strategyInstrumentId                               |-> strategyInstrumentId.value,
         creationStatus                                     |-> creationStatus.value,
         newComplexOrderInstrumentAcknowledgementOccurrence |-> newComplexOrderInstrumentAcknowledgementOccurrence.value ], newComplexOrderInstrumentAcknowledgementOccurrence.rest)

ZeroNewComplexOrderInstrumentAcknowledgement ==
    [ strategyGroup                                      |-> [i \in 1 .. 2 |-> 0],
      strategyInstrumentId                               |-> [i \in 1 .. 4 |-> 0],
      creationStatus                                     |-> [i \in 1 .. 1 |-> 0],
      newComplexOrderInstrumentAcknowledgementOccurrence |-> << >> ]

(* New Complex Order Instrument Acknowledgement at zero, then each field in turn at the values it is checked at *)
CheckedNewComplexOrderInstrumentAcknowledgement ==
    { ZeroNewComplexOrderInstrumentAcknowledgement }
        \cup { [ZeroNewComplexOrderInstrumentAcknowledgement EXCEPT !.strategyGroup = one] : one \in Sample(2) }
        \cup { [ZeroNewComplexOrderInstrumentAcknowledgement EXCEPT !.strategyInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexOrderInstrumentAcknowledgement EXCEPT !.creationStatus = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderInstrumentAcknowledgement EXCEPT !.newComplexOrderInstrumentAcknowledgementOccurrence = one] : one \in SampleLists(OneNewComplexOrderInstrumentAcknowledgementOccurrence) }

(***************************************************************************)
(* Standard Acknowledgement: 10 bytes                                      *)
(***************************************************************************)

StandardAcknowledgement ==
    [ traderId            : Sample(8),
      originalMessageType : Sample(2) ]

EncodeStandardAcknowledgement(message) ==
    message.traderId
        \o message.originalMessageType

DecodeStandardAcknowledgement(bytes) ==
    LET traderId == ReadBytes(bytes, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET originalMessageType == ReadBytes(traderId.rest, 2) IN IF ~originalMessageType.ok THEN Fail ELSE
    Ok([ traderId            |-> traderId.value,
         originalMessageType |-> originalMessageType.value ], originalMessageType.rest)

ZeroStandardAcknowledgement ==
    [ traderId            |-> [i \in 1 .. 8 |-> 0],
      originalMessageType |-> [i \in 1 .. 2 |-> 0] ]

(* Standard Acknowledgement at zero, then each field in turn at the values it is checked at *)
CheckedStandardAcknowledgement ==
    { ZeroStandardAcknowledgement }
        \cup { [ZeroStandardAcknowledgement EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroStandardAcknowledgement EXCEPT !.originalMessageType = one] : one \in Sample(2) }

(***************************************************************************)
(* Clearing Data: 20 bytes                                                 *)
(***************************************************************************)

ClearingData4 ==
    [ clearingInstruction   : Sample(12),
      accountType           : Sample(1),
      openClose             : Sample(1),
      hedgeSpec             : Sample(1),
      clearingOperationMode : Sample(1),
      clearingDestination   : Sample(4) ]

EncodeClearingData4(message) ==
    message.clearingInstruction
        \o message.accountType
        \o message.openClose
        \o message.hedgeSpec
        \o message.clearingOperationMode
        \o message.clearingDestination

DecodeClearingData4(bytes) ==
    LET clearingInstruction == ReadBytes(bytes, 12) IN IF ~clearingInstruction.ok THEN Fail ELSE
    LET accountType == ReadBytes(clearingInstruction.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET openClose == ReadBytes(accountType.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET hedgeSpec == ReadBytes(openClose.rest, 1) IN IF ~hedgeSpec.ok THEN Fail ELSE
    LET clearingOperationMode == ReadBytes(hedgeSpec.rest, 1) IN IF ~clearingOperationMode.ok THEN Fail ELSE
    LET clearingDestination == ReadBytes(clearingOperationMode.rest, 4) IN IF ~clearingDestination.ok THEN Fail ELSE
    Ok([ clearingInstruction   |-> clearingInstruction.value,
         accountType           |-> accountType.value,
         openClose             |-> openClose.value,
         hedgeSpec             |-> hedgeSpec.value,
         clearingOperationMode |-> clearingOperationMode.value,
         clearingDestination   |-> clearingDestination.value ], clearingDestination.rest)

ZeroClearingData4 ==
    [ clearingInstruction   |-> [i \in 1 .. 12 |-> 0],
      accountType           |-> [i \in 1 .. 1 |-> 0],
      openClose             |-> [i \in 1 .. 1 |-> 0],
      hedgeSpec             |-> [i \in 1 .. 1 |-> 0],
      clearingOperationMode |-> [i \in 1 .. 1 |-> 0],
      clearingDestination   |-> [i \in 1 .. 4 |-> 0] ]

(* Clearing Data at zero, then each field in turn at the values it is checked at *)
CheckedClearingData4 ==
    { ZeroClearingData4 }
        \cup { [ZeroClearingData4 EXCEPT !.clearingInstruction = one] : one \in Sample(12) }
        \cup { [ZeroClearingData4 EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroClearingData4 EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroClearingData4 EXCEPT !.hedgeSpec = one] : one \in Sample(1) }
        \cup { [ZeroClearingData4 EXCEPT !.clearingOperationMode = one] : one \in Sample(1) }
        \cup { [ZeroClearingData4 EXCEPT !.clearingDestination = one] : one \in Sample(4) }

(***************************************************************************)
(* Owner Data: 71 bytes                                                    *)
(***************************************************************************)

OwnerData4 ==
    [ clientOrderId : Sample(20),
      poundSign     : Sample(1),
      memo          : Sample(50) ]

EncodeOwnerData4(message) ==
    message.clientOrderId
        \o message.poundSign
        \o message.memo

DecodeOwnerData4(bytes) ==
    LET clientOrderId == ReadBytes(bytes, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET poundSign == ReadBytes(clientOrderId.rest, 1) IN IF ~poundSign.ok THEN Fail ELSE
    LET memo == ReadBytes(poundSign.rest, 50) IN IF ~memo.ok THEN Fail ELSE
    Ok([ clientOrderId |-> clientOrderId.value,
         poundSign     |-> poundSign.value,
         memo          |-> memo.value ], memo.rest)

ZeroOwnerData4 ==
    [ clientOrderId |-> [i \in 1 .. 20 |-> 0],
      poundSign     |-> [i \in 1 .. 1 |-> 0],
      memo          |-> [i \in 1 .. 50 |-> 0] ]

(* Owner Data at zero, then each field in turn at the values it is checked at *)
CheckedOwnerData4 ==
    { ZeroOwnerData4 }
        \cup { [ZeroOwnerData4 EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroOwnerData4 EXCEPT !.poundSign = one] : one \in Sample(1) }
        \cup { [ZeroOwnerData4 EXCEPT !.memo = one] : one \in Sample(50) }

(***************************************************************************)
(* Complex Order Auction Acknowledgement: 167 bytes                        *)
(***************************************************************************)

ComplexOrderAuctionAcknowledgement ==
    [ group                : Sample(2),
      instrumentOptional   : Sample(4),
      traderId             : Sample(8),
      orderId              : Sample(8),
      status               : Sample(1),
      verbSide             : Sample(1),
      quantity             : Sample(8),
      assignedPrice        : Sample(10),
      clearingData         : ClearingData4,
      ownerData            : OwnerData4,
      originalOrderId      : Sample(8),
      auctionIdOptional    : Sample(6),
      additionalClientMemo : Sample(16),
      reserved4            : Sample(4) ]

EncodeComplexOrderAuctionAcknowledgement(message) ==
    message.group
        \o message.instrumentOptional
        \o message.traderId
        \o message.orderId
        \o message.status
        \o message.verbSide
        \o message.quantity
        \o message.assignedPrice
        \o EncodeClearingData4(message.clearingData)
        \o EncodeOwnerData4(message.ownerData)
        \o message.originalOrderId
        \o message.auctionIdOptional
        \o message.additionalClientMemo
        \o message.reserved4

DecodeComplexOrderAuctionAcknowledgement(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrumentOptional == ReadBytes(group.rest, 4) IN IF ~instrumentOptional.ok THEN Fail ELSE
    LET traderId == ReadBytes(instrumentOptional.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET orderId == ReadBytes(traderId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET status == ReadBytes(orderId.rest, 1) IN IF ~status.ok THEN Fail ELSE
    LET verbSide == ReadBytes(status.rest, 1) IN IF ~verbSide.ok THEN Fail ELSE
    LET quantity == ReadBytes(verbSide.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET assignedPrice == ReadBytes(quantity.rest, 10) IN IF ~assignedPrice.ok THEN Fail ELSE
    LET clearingData == DecodeClearingData4(assignedPrice.rest) IN IF ~clearingData.ok THEN Fail ELSE
    LET ownerData == DecodeOwnerData4(clearingData.rest) IN IF ~ownerData.ok THEN Fail ELSE
    LET originalOrderId == ReadBytes(ownerData.rest, 8) IN IF ~originalOrderId.ok THEN Fail ELSE
    LET auctionIdOptional == ReadBytes(originalOrderId.rest, 6) IN IF ~auctionIdOptional.ok THEN Fail ELSE
    LET additionalClientMemo == ReadBytes(auctionIdOptional.rest, 16) IN IF ~additionalClientMemo.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(additionalClientMemo.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    Ok([ group                |-> group.value,
         instrumentOptional   |-> instrumentOptional.value,
         traderId             |-> traderId.value,
         orderId              |-> orderId.value,
         status               |-> status.value,
         verbSide             |-> verbSide.value,
         quantity             |-> quantity.value,
         assignedPrice        |-> assignedPrice.value,
         clearingData         |-> clearingData.value,
         ownerData            |-> ownerData.value,
         originalOrderId      |-> originalOrderId.value,
         auctionIdOptional    |-> auctionIdOptional.value,
         additionalClientMemo |-> additionalClientMemo.value,
         reserved4            |-> reserved4.value ], reserved4.rest)

ZeroComplexOrderAuctionAcknowledgement ==
    [ group                |-> [i \in 1 .. 2 |-> 0],
      instrumentOptional   |-> [i \in 1 .. 4 |-> 0],
      traderId             |-> [i \in 1 .. 8 |-> 0],
      orderId              |-> [i \in 1 .. 8 |-> 0],
      status               |-> [i \in 1 .. 1 |-> 0],
      verbSide             |-> [i \in 1 .. 1 |-> 0],
      quantity             |-> [i \in 1 .. 8 |-> 0],
      assignedPrice        |-> [i \in 1 .. 10 |-> 0],
      clearingData         |-> ZeroClearingData4,
      ownerData            |-> ZeroOwnerData4,
      originalOrderId      |-> [i \in 1 .. 8 |-> 0],
      auctionIdOptional    |-> [i \in 1 .. 6 |-> 0],
      additionalClientMemo |-> [i \in 1 .. 16 |-> 0],
      reserved4            |-> [i \in 1 .. 4 |-> 0] ]

(* Complex Order Auction Acknowledgement at zero, then each field in turn at the values it is checked at *)
CheckedComplexOrderAuctionAcknowledgement ==
    { ZeroComplexOrderAuctionAcknowledgement }
        \cup { [ZeroComplexOrderAuctionAcknowledgement EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroComplexOrderAuctionAcknowledgement EXCEPT !.instrumentOptional = one] : one \in Sample(4) }
        \cup { [ZeroComplexOrderAuctionAcknowledgement EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroComplexOrderAuctionAcknowledgement EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroComplexOrderAuctionAcknowledgement EXCEPT !.status = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderAuctionAcknowledgement EXCEPT !.verbSide = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderAuctionAcknowledgement EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroComplexOrderAuctionAcknowledgement EXCEPT !.assignedPrice = one] : one \in Sample(10) }
        \cup { [ZeroComplexOrderAuctionAcknowledgement EXCEPT !.clearingData = one] : one \in CheckedClearingData4 }
        \cup { [ZeroComplexOrderAuctionAcknowledgement EXCEPT !.ownerData = one] : one \in CheckedOwnerData4 }
        \cup { [ZeroComplexOrderAuctionAcknowledgement EXCEPT !.originalOrderId = one] : one \in Sample(8) }
        \cup { [ZeroComplexOrderAuctionAcknowledgement EXCEPT !.auctionIdOptional = one] : one \in Sample(6) }
        \cup { [ZeroComplexOrderAuctionAcknowledgement EXCEPT !.additionalClientMemo = one] : one \in Sample(16) }
        \cup { [ZeroComplexOrderAuctionAcknowledgement EXCEPT !.reserved4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Clearing Data: 20 bytes                                                 *)
(***************************************************************************)

ClearingData5 ==
    [ clearingInstruction   : Sample(12),
      accountType           : Sample(1),
      openClose             : Sample(1),
      hedgeSpec             : Sample(1),
      clearingOperationMode : Sample(1),
      clearingDestination   : Sample(4) ]

EncodeClearingData5(message) ==
    message.clearingInstruction
        \o message.accountType
        \o message.openClose
        \o message.hedgeSpec
        \o message.clearingOperationMode
        \o message.clearingDestination

DecodeClearingData5(bytes) ==
    LET clearingInstruction == ReadBytes(bytes, 12) IN IF ~clearingInstruction.ok THEN Fail ELSE
    LET accountType == ReadBytes(clearingInstruction.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET openClose == ReadBytes(accountType.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET hedgeSpec == ReadBytes(openClose.rest, 1) IN IF ~hedgeSpec.ok THEN Fail ELSE
    LET clearingOperationMode == ReadBytes(hedgeSpec.rest, 1) IN IF ~clearingOperationMode.ok THEN Fail ELSE
    LET clearingDestination == ReadBytes(clearingOperationMode.rest, 4) IN IF ~clearingDestination.ok THEN Fail ELSE
    Ok([ clearingInstruction   |-> clearingInstruction.value,
         accountType           |-> accountType.value,
         openClose             |-> openClose.value,
         hedgeSpec             |-> hedgeSpec.value,
         clearingOperationMode |-> clearingOperationMode.value,
         clearingDestination   |-> clearingDestination.value ], clearingDestination.rest)

ZeroClearingData5 ==
    [ clearingInstruction   |-> [i \in 1 .. 12 |-> 0],
      accountType           |-> [i \in 1 .. 1 |-> 0],
      openClose             |-> [i \in 1 .. 1 |-> 0],
      hedgeSpec             |-> [i \in 1 .. 1 |-> 0],
      clearingOperationMode |-> [i \in 1 .. 1 |-> 0],
      clearingDestination   |-> [i \in 1 .. 4 |-> 0] ]

(* Clearing Data at zero, then each field in turn at the values it is checked at *)
CheckedClearingData5 ==
    { ZeroClearingData5 }
        \cup { [ZeroClearingData5 EXCEPT !.clearingInstruction = one] : one \in Sample(12) }
        \cup { [ZeroClearingData5 EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroClearingData5 EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroClearingData5 EXCEPT !.hedgeSpec = one] : one \in Sample(1) }
        \cup { [ZeroClearingData5 EXCEPT !.clearingOperationMode = one] : one \in Sample(1) }
        \cup { [ZeroClearingData5 EXCEPT !.clearingDestination = one] : one \in Sample(4) }

(***************************************************************************)
(* Owner Data: 71 bytes                                                    *)
(***************************************************************************)

OwnerData5 ==
    [ clientOrderId : Sample(20),
      poundSign     : Sample(1),
      memo          : Sample(50) ]

EncodeOwnerData5(message) ==
    message.clientOrderId
        \o message.poundSign
        \o message.memo

DecodeOwnerData5(bytes) ==
    LET clientOrderId == ReadBytes(bytes, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET poundSign == ReadBytes(clientOrderId.rest, 1) IN IF ~poundSign.ok THEN Fail ELSE
    LET memo == ReadBytes(poundSign.rest, 50) IN IF ~memo.ok THEN Fail ELSE
    Ok([ clientOrderId |-> clientOrderId.value,
         poundSign     |-> poundSign.value,
         memo          |-> memo.value ], memo.rest)

ZeroOwnerData5 ==
    [ clientOrderId |-> [i \in 1 .. 20 |-> 0],
      poundSign     |-> [i \in 1 .. 1 |-> 0],
      memo          |-> [i \in 1 .. 50 |-> 0] ]

(* Owner Data at zero, then each field in turn at the values it is checked at *)
CheckedOwnerData5 ==
    { ZeroOwnerData5 }
        \cup { [ZeroOwnerData5 EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroOwnerData5 EXCEPT !.poundSign = one] : one \in Sample(1) }
        \cup { [ZeroOwnerData5 EXCEPT !.memo = one] : one \in Sample(50) }

(***************************************************************************)
(* Auction Or Improvement Cancellation Acknowledgement: 147 bytes          *)
(***************************************************************************)

AuctionOrImprovementCancellationAcknowledgement ==
    [ group              : Sample(2),
      instrumentOptional : Sample(4),
      traderId           : Sample(8),
      orderId            : Sample(8),
      status             : Sample(1),
      verbSide           : Sample(1),
      quantity           : Sample(8),
      assignedPrice      : Sample(10),
      clearingData       : ClearingData5,
      ownerData          : OwnerData5,
      originalOrderId    : Sample(8),
      auctionId          : Sample(6) ]

EncodeAuctionOrImprovementCancellationAcknowledgement(message) ==
    message.group
        \o message.instrumentOptional
        \o message.traderId
        \o message.orderId
        \o message.status
        \o message.verbSide
        \o message.quantity
        \o message.assignedPrice
        \o EncodeClearingData5(message.clearingData)
        \o EncodeOwnerData5(message.ownerData)
        \o message.originalOrderId
        \o message.auctionId

DecodeAuctionOrImprovementCancellationAcknowledgement(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrumentOptional == ReadBytes(group.rest, 4) IN IF ~instrumentOptional.ok THEN Fail ELSE
    LET traderId == ReadBytes(instrumentOptional.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET orderId == ReadBytes(traderId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET status == ReadBytes(orderId.rest, 1) IN IF ~status.ok THEN Fail ELSE
    LET verbSide == ReadBytes(status.rest, 1) IN IF ~verbSide.ok THEN Fail ELSE
    LET quantity == ReadBytes(verbSide.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET assignedPrice == ReadBytes(quantity.rest, 10) IN IF ~assignedPrice.ok THEN Fail ELSE
    LET clearingData == DecodeClearingData5(assignedPrice.rest) IN IF ~clearingData.ok THEN Fail ELSE
    LET ownerData == DecodeOwnerData5(clearingData.rest) IN IF ~ownerData.ok THEN Fail ELSE
    LET originalOrderId == ReadBytes(ownerData.rest, 8) IN IF ~originalOrderId.ok THEN Fail ELSE
    LET auctionId == ReadBytes(originalOrderId.rest, 6) IN IF ~auctionId.ok THEN Fail ELSE
    Ok([ group              |-> group.value,
         instrumentOptional |-> instrumentOptional.value,
         traderId           |-> traderId.value,
         orderId            |-> orderId.value,
         status             |-> status.value,
         verbSide           |-> verbSide.value,
         quantity           |-> quantity.value,
         assignedPrice      |-> assignedPrice.value,
         clearingData       |-> clearingData.value,
         ownerData          |-> ownerData.value,
         originalOrderId    |-> originalOrderId.value,
         auctionId          |-> auctionId.value ], auctionId.rest)

ZeroAuctionOrImprovementCancellationAcknowledgement ==
    [ group              |-> [i \in 1 .. 2 |-> 0],
      instrumentOptional |-> [i \in 1 .. 4 |-> 0],
      traderId           |-> [i \in 1 .. 8 |-> 0],
      orderId            |-> [i \in 1 .. 8 |-> 0],
      status             |-> [i \in 1 .. 1 |-> 0],
      verbSide           |-> [i \in 1 .. 1 |-> 0],
      quantity           |-> [i \in 1 .. 8 |-> 0],
      assignedPrice      |-> [i \in 1 .. 10 |-> 0],
      clearingData       |-> ZeroClearingData5,
      ownerData          |-> ZeroOwnerData5,
      originalOrderId    |-> [i \in 1 .. 8 |-> 0],
      auctionId          |-> [i \in 1 .. 6 |-> 0] ]

(* Auction Or Improvement Cancellation Acknowledgement at zero, then each field in turn at the values it is checked at *)
CheckedAuctionOrImprovementCancellationAcknowledgement ==
    { ZeroAuctionOrImprovementCancellationAcknowledgement }
        \cup { [ZeroAuctionOrImprovementCancellationAcknowledgement EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroAuctionOrImprovementCancellationAcknowledgement EXCEPT !.instrumentOptional = one] : one \in Sample(4) }
        \cup { [ZeroAuctionOrImprovementCancellationAcknowledgement EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroAuctionOrImprovementCancellationAcknowledgement EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAuctionOrImprovementCancellationAcknowledgement EXCEPT !.status = one] : one \in Sample(1) }
        \cup { [ZeroAuctionOrImprovementCancellationAcknowledgement EXCEPT !.verbSide = one] : one \in Sample(1) }
        \cup { [ZeroAuctionOrImprovementCancellationAcknowledgement EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroAuctionOrImprovementCancellationAcknowledgement EXCEPT !.assignedPrice = one] : one \in Sample(10) }
        \cup { [ZeroAuctionOrImprovementCancellationAcknowledgement EXCEPT !.clearingData = one] : one \in CheckedClearingData5 }
        \cup { [ZeroAuctionOrImprovementCancellationAcknowledgement EXCEPT !.ownerData = one] : one \in CheckedOwnerData5 }
        \cup { [ZeroAuctionOrImprovementCancellationAcknowledgement EXCEPT !.originalOrderId = one] : one \in Sample(8) }
        \cup { [ZeroAuctionOrImprovementCancellationAcknowledgement EXCEPT !.auctionId = one] : one \in Sample(6) }

(***************************************************************************)
(* Clearing Data: 20 bytes                                                 *)
(***************************************************************************)

ClearingData6 ==
    [ clearingInstruction   : Sample(12),
      accountType           : Sample(1),
      openClose             : Sample(1),
      hedgeSpec             : Sample(1),
      clearingOperationMode : Sample(1),
      clearingDestination   : Sample(4) ]

EncodeClearingData6(message) ==
    message.clearingInstruction
        \o message.accountType
        \o message.openClose
        \o message.hedgeSpec
        \o message.clearingOperationMode
        \o message.clearingDestination

DecodeClearingData6(bytes) ==
    LET clearingInstruction == ReadBytes(bytes, 12) IN IF ~clearingInstruction.ok THEN Fail ELSE
    LET accountType == ReadBytes(clearingInstruction.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET openClose == ReadBytes(accountType.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET hedgeSpec == ReadBytes(openClose.rest, 1) IN IF ~hedgeSpec.ok THEN Fail ELSE
    LET clearingOperationMode == ReadBytes(hedgeSpec.rest, 1) IN IF ~clearingOperationMode.ok THEN Fail ELSE
    LET clearingDestination == ReadBytes(clearingOperationMode.rest, 4) IN IF ~clearingDestination.ok THEN Fail ELSE
    Ok([ clearingInstruction   |-> clearingInstruction.value,
         accountType           |-> accountType.value,
         openClose             |-> openClose.value,
         hedgeSpec             |-> hedgeSpec.value,
         clearingOperationMode |-> clearingOperationMode.value,
         clearingDestination   |-> clearingDestination.value ], clearingDestination.rest)

ZeroClearingData6 ==
    [ clearingInstruction   |-> [i \in 1 .. 12 |-> 0],
      accountType           |-> [i \in 1 .. 1 |-> 0],
      openClose             |-> [i \in 1 .. 1 |-> 0],
      hedgeSpec             |-> [i \in 1 .. 1 |-> 0],
      clearingOperationMode |-> [i \in 1 .. 1 |-> 0],
      clearingDestination   |-> [i \in 1 .. 4 |-> 0] ]

(* Clearing Data at zero, then each field in turn at the values it is checked at *)
CheckedClearingData6 ==
    { ZeroClearingData6 }
        \cup { [ZeroClearingData6 EXCEPT !.clearingInstruction = one] : one \in Sample(12) }
        \cup { [ZeroClearingData6 EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroClearingData6 EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroClearingData6 EXCEPT !.hedgeSpec = one] : one \in Sample(1) }
        \cup { [ZeroClearingData6 EXCEPT !.clearingOperationMode = one] : one \in Sample(1) }
        \cup { [ZeroClearingData6 EXCEPT !.clearingDestination = one] : one \in Sample(4) }

(***************************************************************************)
(* Owner Data: 71 bytes                                                    *)
(***************************************************************************)

OwnerData6 ==
    [ clientOrderId : Sample(20),
      poundSign     : Sample(1),
      memo          : Sample(50) ]

EncodeOwnerData6(message) ==
    message.clientOrderId
        \o message.poundSign
        \o message.memo

DecodeOwnerData6(bytes) ==
    LET clientOrderId == ReadBytes(bytes, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET poundSign == ReadBytes(clientOrderId.rest, 1) IN IF ~poundSign.ok THEN Fail ELSE
    LET memo == ReadBytes(poundSign.rest, 50) IN IF ~memo.ok THEN Fail ELSE
    Ok([ clientOrderId |-> clientOrderId.value,
         poundSign     |-> poundSign.value,
         memo          |-> memo.value ], memo.rest)

ZeroOwnerData6 ==
    [ clientOrderId |-> [i \in 1 .. 20 |-> 0],
      poundSign     |-> [i \in 1 .. 1 |-> 0],
      memo          |-> [i \in 1 .. 50 |-> 0] ]

(* Owner Data at zero, then each field in turn at the values it is checked at *)
CheckedOwnerData6 ==
    { ZeroOwnerData6 }
        \cup { [ZeroOwnerData6 EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroOwnerData6 EXCEPT !.poundSign = one] : one \in Sample(1) }
        \cup { [ZeroOwnerData6 EXCEPT !.memo = one] : one \in Sample(50) }

(***************************************************************************)
(* Order Cancellation Acknowledgement: 167 bytes                           *)
(***************************************************************************)

OrderCancellationAcknowledgement ==
    [ group                : Sample(2),
      instrumentOptional   : Sample(4),
      traderId             : Sample(8),
      orderId              : Sample(8),
      status               : Sample(1),
      verbSide             : Sample(1),
      quantity             : Sample(8),
      assignedPrice        : Sample(10),
      clearingData         : ClearingData6,
      ownerData            : OwnerData6,
      originalOrderId      : Sample(8),
      auctionId            : Sample(6),
      additionalClientMemo : Sample(16),
      reserved4            : Sample(4) ]

EncodeOrderCancellationAcknowledgement(message) ==
    message.group
        \o message.instrumentOptional
        \o message.traderId
        \o message.orderId
        \o message.status
        \o message.verbSide
        \o message.quantity
        \o message.assignedPrice
        \o EncodeClearingData6(message.clearingData)
        \o EncodeOwnerData6(message.ownerData)
        \o message.originalOrderId
        \o message.auctionId
        \o message.additionalClientMemo
        \o message.reserved4

DecodeOrderCancellationAcknowledgement(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrumentOptional == ReadBytes(group.rest, 4) IN IF ~instrumentOptional.ok THEN Fail ELSE
    LET traderId == ReadBytes(instrumentOptional.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET orderId == ReadBytes(traderId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET status == ReadBytes(orderId.rest, 1) IN IF ~status.ok THEN Fail ELSE
    LET verbSide == ReadBytes(status.rest, 1) IN IF ~verbSide.ok THEN Fail ELSE
    LET quantity == ReadBytes(verbSide.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET assignedPrice == ReadBytes(quantity.rest, 10) IN IF ~assignedPrice.ok THEN Fail ELSE
    LET clearingData == DecodeClearingData6(assignedPrice.rest) IN IF ~clearingData.ok THEN Fail ELSE
    LET ownerData == DecodeOwnerData6(clearingData.rest) IN IF ~ownerData.ok THEN Fail ELSE
    LET originalOrderId == ReadBytes(ownerData.rest, 8) IN IF ~originalOrderId.ok THEN Fail ELSE
    LET auctionId == ReadBytes(originalOrderId.rest, 6) IN IF ~auctionId.ok THEN Fail ELSE
    LET additionalClientMemo == ReadBytes(auctionId.rest, 16) IN IF ~additionalClientMemo.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(additionalClientMemo.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    Ok([ group                |-> group.value,
         instrumentOptional   |-> instrumentOptional.value,
         traderId             |-> traderId.value,
         orderId              |-> orderId.value,
         status               |-> status.value,
         verbSide             |-> verbSide.value,
         quantity             |-> quantity.value,
         assignedPrice        |-> assignedPrice.value,
         clearingData         |-> clearingData.value,
         ownerData            |-> ownerData.value,
         originalOrderId      |-> originalOrderId.value,
         auctionId            |-> auctionId.value,
         additionalClientMemo |-> additionalClientMemo.value,
         reserved4            |-> reserved4.value ], reserved4.rest)

ZeroOrderCancellationAcknowledgement ==
    [ group                |-> [i \in 1 .. 2 |-> 0],
      instrumentOptional   |-> [i \in 1 .. 4 |-> 0],
      traderId             |-> [i \in 1 .. 8 |-> 0],
      orderId              |-> [i \in 1 .. 8 |-> 0],
      status               |-> [i \in 1 .. 1 |-> 0],
      verbSide             |-> [i \in 1 .. 1 |-> 0],
      quantity             |-> [i \in 1 .. 8 |-> 0],
      assignedPrice        |-> [i \in 1 .. 10 |-> 0],
      clearingData         |-> ZeroClearingData6,
      ownerData            |-> ZeroOwnerData6,
      originalOrderId      |-> [i \in 1 .. 8 |-> 0],
      auctionId            |-> [i \in 1 .. 6 |-> 0],
      additionalClientMemo |-> [i \in 1 .. 16 |-> 0],
      reserved4            |-> [i \in 1 .. 4 |-> 0] ]

(* Order Cancellation Acknowledgement at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancellationAcknowledgement ==
    { ZeroOrderCancellationAcknowledgement }
        \cup { [ZeroOrderCancellationAcknowledgement EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancellationAcknowledgement EXCEPT !.instrumentOptional = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancellationAcknowledgement EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancellationAcknowledgement EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancellationAcknowledgement EXCEPT !.status = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancellationAcknowledgement EXCEPT !.verbSide = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancellationAcknowledgement EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancellationAcknowledgement EXCEPT !.assignedPrice = one] : one \in Sample(10) }
        \cup { [ZeroOrderCancellationAcknowledgement EXCEPT !.clearingData = one] : one \in CheckedClearingData6 }
        \cup { [ZeroOrderCancellationAcknowledgement EXCEPT !.ownerData = one] : one \in CheckedOwnerData6 }
        \cup { [ZeroOrderCancellationAcknowledgement EXCEPT !.originalOrderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancellationAcknowledgement EXCEPT !.auctionId = one] : one \in Sample(6) }
        \cup { [ZeroOrderCancellationAcknowledgement EXCEPT !.additionalClientMemo = one] : one \in Sample(16) }
        \cup { [ZeroOrderCancellationAcknowledgement EXCEPT !.reserved4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Bulk Quote Acknowledgement Occurrence: 7 bytes                          *)
(***************************************************************************)

BulkQuoteAcknowledgementOccurrence ==
    [ quoteNumber : Sample(3),
      errorCode   : Sample(4) ]

EncodeBulkQuoteAcknowledgementOccurrence(message) ==
    message.quoteNumber
        \o message.errorCode

DecodeBulkQuoteAcknowledgementOccurrence(bytes) ==
    LET quoteNumber == ReadBytes(bytes, 3) IN IF ~quoteNumber.ok THEN Fail ELSE
    LET errorCode == ReadBytes(quoteNumber.rest, 4) IN IF ~errorCode.ok THEN Fail ELSE
    Ok([ quoteNumber |-> quoteNumber.value,
         errorCode   |-> errorCode.value ], errorCode.rest)

ZeroBulkQuoteAcknowledgementOccurrence ==
    [ quoteNumber |-> [i \in 1 .. 3 |-> 0],
      errorCode   |-> [i \in 1 .. 4 |-> 0] ]

(* Bulk Quote Acknowledgement Occurrence at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuoteAcknowledgementOccurrence ==
    { ZeroBulkQuoteAcknowledgementOccurrence }
        \cup { [ZeroBulkQuoteAcknowledgementOccurrence EXCEPT !.quoteNumber = one] : one \in Sample(3) }
        \cup { [ZeroBulkQuoteAcknowledgementOccurrence EXCEPT !.errorCode = one] : one \in Sample(4) }

(* A run of Bulk Quote Acknowledgement Occurrence, written one after another *)
RECURSIVE EncodeBulkQuoteAcknowledgementOccurrenceList(_)
EncodeBulkQuoteAcknowledgementOccurrenceList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeBulkQuoteAcknowledgementOccurrence(Head(messages)) \o EncodeBulkQuoteAcknowledgementOccurrenceList(Tail(messages))

(* As many Bulk Quote Acknowledgement Occurrence as the field that counts them says *)
RECURSIVE ReadBulkQuoteAcknowledgementOccurrenceList(_, _)
ReadBulkQuoteAcknowledgementOccurrenceList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeBulkQuoteAcknowledgementOccurrence(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadBulkQuoteAcknowledgementOccurrenceList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Bulk Quote Acknowledgement Occurrence of each kind, for the lists that carry them *)
OneBulkQuoteAcknowledgementOccurrence == { ZeroBulkQuoteAcknowledgementOccurrence }

(***************************************************************************)
(* Bulk Quote Acknowledgement                                              *)
(***************************************************************************)

BulkQuoteAcknowledgement ==
    [ group                              : Sample(2),
      quoteId                            : Sample(8),
      bulkQuoteAcknowledgementOccurrence : SampleLists(OneBulkQuoteAcknowledgementOccurrence) ]

EncodeBulkQuoteAcknowledgement(message) ==
    message.group
        \o message.quoteId
        \o EncodeUIntBE(Len(message.bulkQuoteAcknowledgementOccurrence), 3)
        \o EncodeBulkQuoteAcknowledgementOccurrenceList(message.bulkQuoteAcknowledgementOccurrence)

DecodeBulkQuoteAcknowledgement(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET quoteId == ReadBytes(group.rest, 8) IN IF ~quoteId.ok THEN Fail ELSE
    LET numberOfQuotesInError == ReadUIntBE(quoteId.rest, 3) IN IF ~numberOfQuotesInError.ok THEN Fail ELSE
    LET bulkQuoteAcknowledgementOccurrence == ReadBulkQuoteAcknowledgementOccurrenceList(numberOfQuotesInError.rest, numberOfQuotesInError.value) IN IF ~bulkQuoteAcknowledgementOccurrence.ok THEN Fail ELSE
    Ok([ group                              |-> group.value,
         quoteId                            |-> quoteId.value,
         bulkQuoteAcknowledgementOccurrence |-> bulkQuoteAcknowledgementOccurrence.value ], bulkQuoteAcknowledgementOccurrence.rest)

ZeroBulkQuoteAcknowledgement ==
    [ group                              |-> [i \in 1 .. 2 |-> 0],
      quoteId                            |-> [i \in 1 .. 8 |-> 0],
      bulkQuoteAcknowledgementOccurrence |-> << >> ]

(* Bulk Quote Acknowledgement at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuoteAcknowledgement ==
    { ZeroBulkQuoteAcknowledgement }
        \cup { [ZeroBulkQuoteAcknowledgement EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuoteAcknowledgement EXCEPT !.quoteId = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuoteAcknowledgement EXCEPT !.bulkQuoteAcknowledgementOccurrence = one] : one \in SampleLists(OneBulkQuoteAcknowledgementOccurrence) }

(***************************************************************************)
(* Trader Status: 10 bytes                                                 *)
(***************************************************************************)

TraderStatus ==
    [ traderId        : Sample(8),
      traderLockOut   : Sample(1),
      riskTeamLockOut : Sample(1) ]

EncodeTraderStatus(message) ==
    message.traderId
        \o message.traderLockOut
        \o message.riskTeamLockOut

DecodeTraderStatus(bytes) ==
    LET traderId == ReadBytes(bytes, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET traderLockOut == ReadBytes(traderId.rest, 1) IN IF ~traderLockOut.ok THEN Fail ELSE
    LET riskTeamLockOut == ReadBytes(traderLockOut.rest, 1) IN IF ~riskTeamLockOut.ok THEN Fail ELSE
    Ok([ traderId        |-> traderId.value,
         traderLockOut   |-> traderLockOut.value,
         riskTeamLockOut |-> riskTeamLockOut.value ], riskTeamLockOut.rest)

ZeroTraderStatus ==
    [ traderId        |-> [i \in 1 .. 8 |-> 0],
      traderLockOut   |-> [i \in 1 .. 1 |-> 0],
      riskTeamLockOut |-> [i \in 1 .. 1 |-> 0] ]

(* Trader Status at zero, then each field in turn at the values it is checked at *)
CheckedTraderStatus ==
    { ZeroTraderStatus }
        \cup { [ZeroTraderStatus EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroTraderStatus EXCEPT !.traderLockOut = one] : one \in Sample(1) }
        \cup { [ZeroTraderStatus EXCEPT !.riskTeamLockOut = one] : one \in Sample(1) }

(***************************************************************************)
(* Directed Order Cancellation Notice: 41 bytes                            *)
(***************************************************************************)

DirectedOrderCancellationNotice ==
    [ group              : Sample(2),
      instrumentOptional : Sample(4),
      traderId           : Sample(8),
      verbSide           : Sample(1),
      quantity           : Sample(8),
      price              : Sample(10),
      referencedOrderId  : Sample(8) ]

EncodeDirectedOrderCancellationNotice(message) ==
    message.group
        \o message.instrumentOptional
        \o message.traderId
        \o message.verbSide
        \o message.quantity
        \o message.price
        \o message.referencedOrderId

DecodeDirectedOrderCancellationNotice(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrumentOptional == ReadBytes(group.rest, 4) IN IF ~instrumentOptional.ok THEN Fail ELSE
    LET traderId == ReadBytes(instrumentOptional.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET verbSide == ReadBytes(traderId.rest, 1) IN IF ~verbSide.ok THEN Fail ELSE
    LET quantity == ReadBytes(verbSide.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 10) IN IF ~price.ok THEN Fail ELSE
    LET referencedOrderId == ReadBytes(price.rest, 8) IN IF ~referencedOrderId.ok THEN Fail ELSE
    Ok([ group              |-> group.value,
         instrumentOptional |-> instrumentOptional.value,
         traderId           |-> traderId.value,
         verbSide           |-> verbSide.value,
         quantity           |-> quantity.value,
         price              |-> price.value,
         referencedOrderId  |-> referencedOrderId.value ], referencedOrderId.rest)

ZeroDirectedOrderCancellationNotice ==
    [ group              |-> [i \in 1 .. 2 |-> 0],
      instrumentOptional |-> [i \in 1 .. 4 |-> 0],
      traderId           |-> [i \in 1 .. 8 |-> 0],
      verbSide           |-> [i \in 1 .. 1 |-> 0],
      quantity           |-> [i \in 1 .. 8 |-> 0],
      price              |-> [i \in 1 .. 10 |-> 0],
      referencedOrderId  |-> [i \in 1 .. 8 |-> 0] ]

(* Directed Order Cancellation Notice at zero, then each field in turn at the values it is checked at *)
CheckedDirectedOrderCancellationNotice ==
    { ZeroDirectedOrderCancellationNotice }
        \cup { [ZeroDirectedOrderCancellationNotice EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroDirectedOrderCancellationNotice EXCEPT !.instrumentOptional = one] : one \in Sample(4) }
        \cup { [ZeroDirectedOrderCancellationNotice EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroDirectedOrderCancellationNotice EXCEPT !.verbSide = one] : one \in Sample(1) }
        \cup { [ZeroDirectedOrderCancellationNotice EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroDirectedOrderCancellationNotice EXCEPT !.price = one] : one \in Sample(10) }
        \cup { [ZeroDirectedOrderCancellationNotice EXCEPT !.referencedOrderId = one] : one \in Sample(8) }

(***************************************************************************)
(* Directed Order Notice: 41 bytes                                         *)
(***************************************************************************)

DirectedOrderNotice ==
    [ group              : Sample(2),
      instrumentOptional : Sample(4),
      traderId           : Sample(8),
      verbSide           : Sample(1),
      quantity           : Sample(8),
      price              : Sample(10),
      referencedOrderId  : Sample(8) ]

EncodeDirectedOrderNotice(message) ==
    message.group
        \o message.instrumentOptional
        \o message.traderId
        \o message.verbSide
        \o message.quantity
        \o message.price
        \o message.referencedOrderId

DecodeDirectedOrderNotice(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrumentOptional == ReadBytes(group.rest, 4) IN IF ~instrumentOptional.ok THEN Fail ELSE
    LET traderId == ReadBytes(instrumentOptional.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET verbSide == ReadBytes(traderId.rest, 1) IN IF ~verbSide.ok THEN Fail ELSE
    LET quantity == ReadBytes(verbSide.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 10) IN IF ~price.ok THEN Fail ELSE
    LET referencedOrderId == ReadBytes(price.rest, 8) IN IF ~referencedOrderId.ok THEN Fail ELSE
    Ok([ group              |-> group.value,
         instrumentOptional |-> instrumentOptional.value,
         traderId           |-> traderId.value,
         verbSide           |-> verbSide.value,
         quantity           |-> quantity.value,
         price              |-> price.value,
         referencedOrderId  |-> referencedOrderId.value ], referencedOrderId.rest)

ZeroDirectedOrderNotice ==
    [ group              |-> [i \in 1 .. 2 |-> 0],
      instrumentOptional |-> [i \in 1 .. 4 |-> 0],
      traderId           |-> [i \in 1 .. 8 |-> 0],
      verbSide           |-> [i \in 1 .. 1 |-> 0],
      quantity           |-> [i \in 1 .. 8 |-> 0],
      price              |-> [i \in 1 .. 10 |-> 0],
      referencedOrderId  |-> [i \in 1 .. 8 |-> 0] ]

(* Directed Order Notice at zero, then each field in turn at the values it is checked at *)
CheckedDirectedOrderNotice ==
    { ZeroDirectedOrderNotice }
        \cup { [ZeroDirectedOrderNotice EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroDirectedOrderNotice EXCEPT !.instrumentOptional = one] : one \in Sample(4) }
        \cup { [ZeroDirectedOrderNotice EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroDirectedOrderNotice EXCEPT !.verbSide = one] : one \in Sample(1) }
        \cup { [ZeroDirectedOrderNotice EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroDirectedOrderNotice EXCEPT !.price = one] : one \in Sample(10) }
        \cup { [ZeroDirectedOrderNotice EXCEPT !.referencedOrderId = one] : one \in Sample(8) }

(***************************************************************************)
(* Excluded Instrument Notice: 22 bytes                                    *)
(***************************************************************************)

ExcludedInstrumentNotice ==
    [ group           : Sample(2),
      reserved2       : Sample(2),
      traderId        : Sample(8),
      secondReserved2 : Sample(2),
      nbOfInstruments : Sample(4),
      instrument      : Sample(4) ]

EncodeExcludedInstrumentNotice(message) ==
    message.group
        \o message.reserved2
        \o message.traderId
        \o message.secondReserved2
        \o message.nbOfInstruments
        \o message.instrument

DecodeExcludedInstrumentNotice(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(group.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET traderId == ReadBytes(reserved2.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET secondReserved2 == ReadBytes(traderId.rest, 2) IN IF ~secondReserved2.ok THEN Fail ELSE
    LET nbOfInstruments == ReadBytes(secondReserved2.rest, 4) IN IF ~nbOfInstruments.ok THEN Fail ELSE
    LET instrument == ReadBytes(nbOfInstruments.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    Ok([ group           |-> group.value,
         reserved2       |-> reserved2.value,
         traderId        |-> traderId.value,
         secondReserved2 |-> secondReserved2.value,
         nbOfInstruments |-> nbOfInstruments.value,
         instrument      |-> instrument.value ], instrument.rest)

ZeroExcludedInstrumentNotice ==
    [ group           |-> [i \in 1 .. 2 |-> 0],
      reserved2       |-> [i \in 1 .. 2 |-> 0],
      traderId        |-> [i \in 1 .. 8 |-> 0],
      secondReserved2 |-> [i \in 1 .. 2 |-> 0],
      nbOfInstruments |-> [i \in 1 .. 4 |-> 0],
      instrument      |-> [i \in 1 .. 4 |-> 0] ]

(* Excluded Instrument Notice at zero, then each field in turn at the values it is checked at *)
CheckedExcludedInstrumentNotice ==
    { ZeroExcludedInstrumentNotice }
        \cup { [ZeroExcludedInstrumentNotice EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroExcludedInstrumentNotice EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroExcludedInstrumentNotice EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroExcludedInstrumentNotice EXCEPT !.secondReserved2 = one] : one \in Sample(2) }
        \cup { [ZeroExcludedInstrumentNotice EXCEPT !.nbOfInstruments = one] : one \in Sample(4) }
        \cup { [ZeroExcludedInstrumentNotice EXCEPT !.instrument = one] : one \in Sample(4) }

(***************************************************************************)
(* Group State Change: 3 bytes                                             *)
(***************************************************************************)

GroupStateChange ==
    [ group      : Sample(2),
      groupState : Sample(1) ]

EncodeGroupStateChange(message) ==
    message.group
        \o message.groupState

DecodeGroupStateChange(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET groupState == ReadBytes(group.rest, 1) IN IF ~groupState.ok THEN Fail ELSE
    Ok([ group      |-> group.value,
         groupState |-> groupState.value ], groupState.rest)

ZeroGroupStateChange ==
    [ group      |-> [i \in 1 .. 2 |-> 0],
      groupState |-> [i \in 1 .. 1 |-> 0] ]

(* Group State Change at zero, then each field in turn at the values it is checked at *)
CheckedGroupStateChange ==
    { ZeroGroupStateChange }
        \cup { [ZeroGroupStateChange EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroGroupStateChange EXCEPT !.groupState = one] : one \in Sample(1) }

(***************************************************************************)
(* Clearing Data: 20 bytes                                                 *)
(***************************************************************************)

ClearingData7 ==
    [ clearingInstruction   : Sample(12),
      accountType           : Sample(1),
      openClose             : Sample(1),
      hedgeSpec             : Sample(1),
      clearingOperationMode : Sample(1),
      clearingDestination   : Sample(4) ]

EncodeClearingData7(message) ==
    message.clearingInstruction
        \o message.accountType
        \o message.openClose
        \o message.hedgeSpec
        \o message.clearingOperationMode
        \o message.clearingDestination

DecodeClearingData7(bytes) ==
    LET clearingInstruction == ReadBytes(bytes, 12) IN IF ~clearingInstruction.ok THEN Fail ELSE
    LET accountType == ReadBytes(clearingInstruction.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET openClose == ReadBytes(accountType.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET hedgeSpec == ReadBytes(openClose.rest, 1) IN IF ~hedgeSpec.ok THEN Fail ELSE
    LET clearingOperationMode == ReadBytes(hedgeSpec.rest, 1) IN IF ~clearingOperationMode.ok THEN Fail ELSE
    LET clearingDestination == ReadBytes(clearingOperationMode.rest, 4) IN IF ~clearingDestination.ok THEN Fail ELSE
    Ok([ clearingInstruction   |-> clearingInstruction.value,
         accountType           |-> accountType.value,
         openClose             |-> openClose.value,
         hedgeSpec             |-> hedgeSpec.value,
         clearingOperationMode |-> clearingOperationMode.value,
         clearingDestination   |-> clearingDestination.value ], clearingDestination.rest)

ZeroClearingData7 ==
    [ clearingInstruction   |-> [i \in 1 .. 12 |-> 0],
      accountType           |-> [i \in 1 .. 1 |-> 0],
      openClose             |-> [i \in 1 .. 1 |-> 0],
      hedgeSpec             |-> [i \in 1 .. 1 |-> 0],
      clearingOperationMode |-> [i \in 1 .. 1 |-> 0],
      clearingDestination   |-> [i \in 1 .. 4 |-> 0] ]

(* Clearing Data at zero, then each field in turn at the values it is checked at *)
CheckedClearingData7 ==
    { ZeroClearingData7 }
        \cup { [ZeroClearingData7 EXCEPT !.clearingInstruction = one] : one \in Sample(12) }
        \cup { [ZeroClearingData7 EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroClearingData7 EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroClearingData7 EXCEPT !.hedgeSpec = one] : one \in Sample(1) }
        \cup { [ZeroClearingData7 EXCEPT !.clearingOperationMode = one] : one \in Sample(1) }
        \cup { [ZeroClearingData7 EXCEPT !.clearingDestination = one] : one \in Sample(4) }

(***************************************************************************)
(* Owner Data: 71 bytes                                                    *)
(***************************************************************************)

OwnerData7 ==
    [ clientOrderId : Sample(20),
      poundSign     : Sample(1),
      memo          : Sample(50) ]

EncodeOwnerData7(message) ==
    message.clientOrderId
        \o message.poundSign
        \o message.memo

DecodeOwnerData7(bytes) ==
    LET clientOrderId == ReadBytes(bytes, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET poundSign == ReadBytes(clientOrderId.rest, 1) IN IF ~poundSign.ok THEN Fail ELSE
    LET memo == ReadBytes(poundSign.rest, 50) IN IF ~memo.ok THEN Fail ELSE
    Ok([ clientOrderId |-> clientOrderId.value,
         poundSign     |-> poundSign.value,
         memo          |-> memo.value ], memo.rest)

ZeroOwnerData7 ==
    [ clientOrderId |-> [i \in 1 .. 20 |-> 0],
      poundSign     |-> [i \in 1 .. 1 |-> 0],
      memo          |-> [i \in 1 .. 50 |-> 0] ]

(* Owner Data at zero, then each field in turn at the values it is checked at *)
CheckedOwnerData7 ==
    { ZeroOwnerData7 }
        \cup { [ZeroOwnerData7 EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroOwnerData7 EXCEPT !.poundSign = one] : one \in Sample(1) }
        \cup { [ZeroOwnerData7 EXCEPT !.memo = one] : one \in Sample(50) }

(***************************************************************************)
(* Leg Execution Notice: 257 bytes                                         *)
(***************************************************************************)

LegExecutionNotice ==
    [ group                              : Sample(2),
      instrumentOptional                 : Sample(4),
      traderId                           : Sample(8),
      referenceId                        : Sample(8),
      verbSide                           : Sample(1),
      quantityTraded                     : Sample(8),
      tradePrice                         : Sample(10),
      timeTradeHhmmss                    : Sample(6),
      clearingData                       : ClearingData7,
      ownerData                          : OwnerData7,
      specialTradeIndicator              : Sample(1),
      priceType                          : Sample(1),
      tradeType                          : Sample(1),
      auctionIdOptional                  : Sample(6),
      tradeNumber                        : Sample(8),
      tradeMemo                          : Sample(50),
      originalReferenceId                : Sample(8),
      idCodeForTheCounterpartParticipant : Sample(4),
      liquidityStatus                    : Sample(1),
      strategyGroup                      : Sample(2),
      strategyInstrumentId               : Sample(4),
      strategyVerbSide                   : Sample(1),
      strategyTradeNumber                : Sample(8),
      legNumber                          : Sample(2),
      counterpartAccountType             : Sample(1),
      additionalClientMemo               : Sample(16),
      reserved1                          : Sample(1),
      reserved4                          : Sample(4) ]

EncodeLegExecutionNotice(message) ==
    message.group
        \o message.instrumentOptional
        \o message.traderId
        \o message.referenceId
        \o message.verbSide
        \o message.quantityTraded
        \o message.tradePrice
        \o message.timeTradeHhmmss
        \o EncodeClearingData7(message.clearingData)
        \o EncodeOwnerData7(message.ownerData)
        \o message.specialTradeIndicator
        \o message.priceType
        \o message.tradeType
        \o message.auctionIdOptional
        \o message.tradeNumber
        \o message.tradeMemo
        \o message.originalReferenceId
        \o message.idCodeForTheCounterpartParticipant
        \o message.liquidityStatus
        \o message.strategyGroup
        \o message.strategyInstrumentId
        \o message.strategyVerbSide
        \o message.strategyTradeNumber
        \o message.legNumber
        \o message.counterpartAccountType
        \o message.additionalClientMemo
        \o message.reserved1
        \o message.reserved4

DecodeLegExecutionNotice(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrumentOptional == ReadBytes(group.rest, 4) IN IF ~instrumentOptional.ok THEN Fail ELSE
    LET traderId == ReadBytes(instrumentOptional.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET referenceId == ReadBytes(traderId.rest, 8) IN IF ~referenceId.ok THEN Fail ELSE
    LET verbSide == ReadBytes(referenceId.rest, 1) IN IF ~verbSide.ok THEN Fail ELSE
    LET quantityTraded == ReadBytes(verbSide.rest, 8) IN IF ~quantityTraded.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(quantityTraded.rest, 10) IN IF ~tradePrice.ok THEN Fail ELSE
    LET timeTradeHhmmss == ReadBytes(tradePrice.rest, 6) IN IF ~timeTradeHhmmss.ok THEN Fail ELSE
    LET clearingData == DecodeClearingData7(timeTradeHhmmss.rest) IN IF ~clearingData.ok THEN Fail ELSE
    LET ownerData == DecodeOwnerData7(clearingData.rest) IN IF ~ownerData.ok THEN Fail ELSE
    LET specialTradeIndicator == ReadBytes(ownerData.rest, 1) IN IF ~specialTradeIndicator.ok THEN Fail ELSE
    LET priceType == ReadBytes(specialTradeIndicator.rest, 1) IN IF ~priceType.ok THEN Fail ELSE
    LET tradeType == ReadBytes(priceType.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET auctionIdOptional == ReadBytes(tradeType.rest, 6) IN IF ~auctionIdOptional.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(auctionIdOptional.rest, 8) IN IF ~tradeNumber.ok THEN Fail ELSE
    LET tradeMemo == ReadBytes(tradeNumber.rest, 50) IN IF ~tradeMemo.ok THEN Fail ELSE
    LET originalReferenceId == ReadBytes(tradeMemo.rest, 8) IN IF ~originalReferenceId.ok THEN Fail ELSE
    LET idCodeForTheCounterpartParticipant == ReadBytes(originalReferenceId.rest, 4) IN IF ~idCodeForTheCounterpartParticipant.ok THEN Fail ELSE
    LET liquidityStatus == ReadBytes(idCodeForTheCounterpartParticipant.rest, 1) IN IF ~liquidityStatus.ok THEN Fail ELSE
    LET strategyGroup == ReadBytes(liquidityStatus.rest, 2) IN IF ~strategyGroup.ok THEN Fail ELSE
    LET strategyInstrumentId == ReadBytes(strategyGroup.rest, 4) IN IF ~strategyInstrumentId.ok THEN Fail ELSE
    LET strategyVerbSide == ReadBytes(strategyInstrumentId.rest, 1) IN IF ~strategyVerbSide.ok THEN Fail ELSE
    LET strategyTradeNumber == ReadBytes(strategyVerbSide.rest, 8) IN IF ~strategyTradeNumber.ok THEN Fail ELSE
    LET legNumber == ReadBytes(strategyTradeNumber.rest, 2) IN IF ~legNumber.ok THEN Fail ELSE
    LET counterpartAccountType == ReadBytes(legNumber.rest, 1) IN IF ~counterpartAccountType.ok THEN Fail ELSE
    LET additionalClientMemo == ReadBytes(counterpartAccountType.rest, 16) IN IF ~additionalClientMemo.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(additionalClientMemo.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(reserved1.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    Ok([ group                              |-> group.value,
         instrumentOptional                 |-> instrumentOptional.value,
         traderId                           |-> traderId.value,
         referenceId                        |-> referenceId.value,
         verbSide                           |-> verbSide.value,
         quantityTraded                     |-> quantityTraded.value,
         tradePrice                         |-> tradePrice.value,
         timeTradeHhmmss                    |-> timeTradeHhmmss.value,
         clearingData                       |-> clearingData.value,
         ownerData                          |-> ownerData.value,
         specialTradeIndicator              |-> specialTradeIndicator.value,
         priceType                          |-> priceType.value,
         tradeType                          |-> tradeType.value,
         auctionIdOptional                  |-> auctionIdOptional.value,
         tradeNumber                        |-> tradeNumber.value,
         tradeMemo                          |-> tradeMemo.value,
         originalReferenceId                |-> originalReferenceId.value,
         idCodeForTheCounterpartParticipant |-> idCodeForTheCounterpartParticipant.value,
         liquidityStatus                    |-> liquidityStatus.value,
         strategyGroup                      |-> strategyGroup.value,
         strategyInstrumentId               |-> strategyInstrumentId.value,
         strategyVerbSide                   |-> strategyVerbSide.value,
         strategyTradeNumber                |-> strategyTradeNumber.value,
         legNumber                          |-> legNumber.value,
         counterpartAccountType             |-> counterpartAccountType.value,
         additionalClientMemo               |-> additionalClientMemo.value,
         reserved1                          |-> reserved1.value,
         reserved4                          |-> reserved4.value ], reserved4.rest)

ZeroLegExecutionNotice ==
    [ group                              |-> [i \in 1 .. 2 |-> 0],
      instrumentOptional                 |-> [i \in 1 .. 4 |-> 0],
      traderId                           |-> [i \in 1 .. 8 |-> 0],
      referenceId                        |-> [i \in 1 .. 8 |-> 0],
      verbSide                           |-> [i \in 1 .. 1 |-> 0],
      quantityTraded                     |-> [i \in 1 .. 8 |-> 0],
      tradePrice                         |-> [i \in 1 .. 10 |-> 0],
      timeTradeHhmmss                    |-> [i \in 1 .. 6 |-> 0],
      clearingData                       |-> ZeroClearingData7,
      ownerData                          |-> ZeroOwnerData7,
      specialTradeIndicator              |-> [i \in 1 .. 1 |-> 0],
      priceType                          |-> [i \in 1 .. 1 |-> 0],
      tradeType                          |-> [i \in 1 .. 1 |-> 0],
      auctionIdOptional                  |-> [i \in 1 .. 6 |-> 0],
      tradeNumber                        |-> [i \in 1 .. 8 |-> 0],
      tradeMemo                          |-> [i \in 1 .. 50 |-> 0],
      originalReferenceId                |-> [i \in 1 .. 8 |-> 0],
      idCodeForTheCounterpartParticipant |-> [i \in 1 .. 4 |-> 0],
      liquidityStatus                    |-> [i \in 1 .. 1 |-> 0],
      strategyGroup                      |-> [i \in 1 .. 2 |-> 0],
      strategyInstrumentId               |-> [i \in 1 .. 4 |-> 0],
      strategyVerbSide                   |-> [i \in 1 .. 1 |-> 0],
      strategyTradeNumber                |-> [i \in 1 .. 8 |-> 0],
      legNumber                          |-> [i \in 1 .. 2 |-> 0],
      counterpartAccountType             |-> [i \in 1 .. 1 |-> 0],
      additionalClientMemo               |-> [i \in 1 .. 16 |-> 0],
      reserved1                          |-> [i \in 1 .. 1 |-> 0],
      reserved4                          |-> [i \in 1 .. 4 |-> 0] ]

(* Leg Execution Notice at zero, then each field in turn at the values it is checked at *)
CheckedLegExecutionNotice ==
    { ZeroLegExecutionNotice }
        \cup { [ZeroLegExecutionNotice EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroLegExecutionNotice EXCEPT !.instrumentOptional = one] : one \in Sample(4) }
        \cup { [ZeroLegExecutionNotice EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroLegExecutionNotice EXCEPT !.referenceId = one] : one \in Sample(8) }
        \cup { [ZeroLegExecutionNotice EXCEPT !.verbSide = one] : one \in Sample(1) }
        \cup { [ZeroLegExecutionNotice EXCEPT !.quantityTraded = one] : one \in Sample(8) }
        \cup { [ZeroLegExecutionNotice EXCEPT !.tradePrice = one] : one \in Sample(10) }
        \cup { [ZeroLegExecutionNotice EXCEPT !.timeTradeHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroLegExecutionNotice EXCEPT !.clearingData = one] : one \in CheckedClearingData7 }
        \cup { [ZeroLegExecutionNotice EXCEPT !.ownerData = one] : one \in CheckedOwnerData7 }
        \cup { [ZeroLegExecutionNotice EXCEPT !.specialTradeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroLegExecutionNotice EXCEPT !.priceType = one] : one \in Sample(1) }
        \cup { [ZeroLegExecutionNotice EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroLegExecutionNotice EXCEPT !.auctionIdOptional = one] : one \in Sample(6) }
        \cup { [ZeroLegExecutionNotice EXCEPT !.tradeNumber = one] : one \in Sample(8) }
        \cup { [ZeroLegExecutionNotice EXCEPT !.tradeMemo = one] : one \in Sample(50) }
        \cup { [ZeroLegExecutionNotice EXCEPT !.originalReferenceId = one] : one \in Sample(8) }
        \cup { [ZeroLegExecutionNotice EXCEPT !.idCodeForTheCounterpartParticipant = one] : one \in Sample(4) }
        \cup { [ZeroLegExecutionNotice EXCEPT !.liquidityStatus = one] : one \in Sample(1) }
        \cup { [ZeroLegExecutionNotice EXCEPT !.strategyGroup = one] : one \in Sample(2) }
        \cup { [ZeroLegExecutionNotice EXCEPT !.strategyInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroLegExecutionNotice EXCEPT !.strategyVerbSide = one] : one \in Sample(1) }
        \cup { [ZeroLegExecutionNotice EXCEPT !.strategyTradeNumber = one] : one \in Sample(8) }
        \cup { [ZeroLegExecutionNotice EXCEPT !.legNumber = one] : one \in Sample(2) }
        \cup { [ZeroLegExecutionNotice EXCEPT !.counterpartAccountType = one] : one \in Sample(1) }
        \cup { [ZeroLegExecutionNotice EXCEPT !.additionalClientMemo = one] : one \in Sample(16) }
        \cup { [ZeroLegExecutionNotice EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroLegExecutionNotice EXCEPT !.reserved4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Cancellation Of All Quotes Notices: 15 bytes                            *)
(***************************************************************************)

CancellationOfAllQuotesNotices ==
    [ group              : Sample(2),
      instrumentOptional : Sample(4),
      traderId           : Sample(8),
      quoteCancelReason  : Sample(1) ]

EncodeCancellationOfAllQuotesNotices(message) ==
    message.group
        \o message.instrumentOptional
        \o message.traderId
        \o message.quoteCancelReason

DecodeCancellationOfAllQuotesNotices(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrumentOptional == ReadBytes(group.rest, 4) IN IF ~instrumentOptional.ok THEN Fail ELSE
    LET traderId == ReadBytes(instrumentOptional.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET quoteCancelReason == ReadBytes(traderId.rest, 1) IN IF ~quoteCancelReason.ok THEN Fail ELSE
    Ok([ group              |-> group.value,
         instrumentOptional |-> instrumentOptional.value,
         traderId           |-> traderId.value,
         quoteCancelReason  |-> quoteCancelReason.value ], quoteCancelReason.rest)

ZeroCancellationOfAllQuotesNotices ==
    [ group              |-> [i \in 1 .. 2 |-> 0],
      instrumentOptional |-> [i \in 1 .. 4 |-> 0],
      traderId           |-> [i \in 1 .. 8 |-> 0],
      quoteCancelReason  |-> [i \in 1 .. 1 |-> 0] ]

(* Cancellation Of All Quotes Notices at zero, then each field in turn at the values it is checked at *)
CheckedCancellationOfAllQuotesNotices ==
    { ZeroCancellationOfAllQuotesNotices }
        \cup { [ZeroCancellationOfAllQuotesNotices EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroCancellationOfAllQuotesNotices EXCEPT !.instrumentOptional = one] : one \in Sample(4) }
        \cup { [ZeroCancellationOfAllQuotesNotices EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroCancellationOfAllQuotesNotices EXCEPT !.quoteCancelReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Quality Market Maker Notification: 65 bytes                             *)
(***************************************************************************)

QualityMarketMakerNotification ==
    [ group              : Sample(2),
      instrumentOptional : Sample(4),
      traderId           : Sample(8),
      auctionIdOptional  : Sample(6),
      verb               : Sample(1),
      auctionQuantity    : Sample(8),
      auctionPrice       : Sample(10),
      quoteQuantity      : Sample(8),
      quotePrice         : Sample(10),
      qualifiedQuantity  : Sample(8) ]

EncodeQualityMarketMakerNotification(message) ==
    message.group
        \o message.instrumentOptional
        \o message.traderId
        \o message.auctionIdOptional
        \o message.verb
        \o message.auctionQuantity
        \o message.auctionPrice
        \o message.quoteQuantity
        \o message.quotePrice
        \o message.qualifiedQuantity

DecodeQualityMarketMakerNotification(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrumentOptional == ReadBytes(group.rest, 4) IN IF ~instrumentOptional.ok THEN Fail ELSE
    LET traderId == ReadBytes(instrumentOptional.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET auctionIdOptional == ReadBytes(traderId.rest, 6) IN IF ~auctionIdOptional.ok THEN Fail ELSE
    LET verb == ReadBytes(auctionIdOptional.rest, 1) IN IF ~verb.ok THEN Fail ELSE
    LET auctionQuantity == ReadBytes(verb.rest, 8) IN IF ~auctionQuantity.ok THEN Fail ELSE
    LET auctionPrice == ReadBytes(auctionQuantity.rest, 10) IN IF ~auctionPrice.ok THEN Fail ELSE
    LET quoteQuantity == ReadBytes(auctionPrice.rest, 8) IN IF ~quoteQuantity.ok THEN Fail ELSE
    LET quotePrice == ReadBytes(quoteQuantity.rest, 10) IN IF ~quotePrice.ok THEN Fail ELSE
    LET qualifiedQuantity == ReadBytes(quotePrice.rest, 8) IN IF ~qualifiedQuantity.ok THEN Fail ELSE
    Ok([ group              |-> group.value,
         instrumentOptional |-> instrumentOptional.value,
         traderId           |-> traderId.value,
         auctionIdOptional  |-> auctionIdOptional.value,
         verb               |-> verb.value,
         auctionQuantity    |-> auctionQuantity.value,
         auctionPrice       |-> auctionPrice.value,
         quoteQuantity      |-> quoteQuantity.value,
         quotePrice         |-> quotePrice.value,
         qualifiedQuantity  |-> qualifiedQuantity.value ], qualifiedQuantity.rest)

ZeroQualityMarketMakerNotification ==
    [ group              |-> [i \in 1 .. 2 |-> 0],
      instrumentOptional |-> [i \in 1 .. 4 |-> 0],
      traderId           |-> [i \in 1 .. 8 |-> 0],
      auctionIdOptional  |-> [i \in 1 .. 6 |-> 0],
      verb               |-> [i \in 1 .. 1 |-> 0],
      auctionQuantity    |-> [i \in 1 .. 8 |-> 0],
      auctionPrice       |-> [i \in 1 .. 10 |-> 0],
      quoteQuantity      |-> [i \in 1 .. 8 |-> 0],
      quotePrice         |-> [i \in 1 .. 10 |-> 0],
      qualifiedQuantity  |-> [i \in 1 .. 8 |-> 0] ]

(* Quality Market Maker Notification at zero, then each field in turn at the values it is checked at *)
CheckedQualityMarketMakerNotification ==
    { ZeroQualityMarketMakerNotification }
        \cup { [ZeroQualityMarketMakerNotification EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroQualityMarketMakerNotification EXCEPT !.instrumentOptional = one] : one \in Sample(4) }
        \cup { [ZeroQualityMarketMakerNotification EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroQualityMarketMakerNotification EXCEPT !.auctionIdOptional = one] : one \in Sample(6) }
        \cup { [ZeroQualityMarketMakerNotification EXCEPT !.verb = one] : one \in Sample(1) }
        \cup { [ZeroQualityMarketMakerNotification EXCEPT !.auctionQuantity = one] : one \in Sample(8) }
        \cup { [ZeroQualityMarketMakerNotification EXCEPT !.auctionPrice = one] : one \in Sample(10) }
        \cup { [ZeroQualityMarketMakerNotification EXCEPT !.quoteQuantity = one] : one \in Sample(8) }
        \cup { [ZeroQualityMarketMakerNotification EXCEPT !.quotePrice = one] : one \in Sample(10) }
        \cup { [ZeroQualityMarketMakerNotification EXCEPT !.qualifiedQuantity = one] : one \in Sample(8) }

(***************************************************************************)
(* Clearing Data: 20 bytes                                                 *)
(***************************************************************************)

ClearingData8 ==
    [ clearingInstruction   : Sample(12),
      accountType           : Sample(1),
      openClose             : Sample(1),
      hedgeSpec             : Sample(1),
      clearingOperationMode : Sample(1),
      clearingDestination   : Sample(4) ]

EncodeClearingData8(message) ==
    message.clearingInstruction
        \o message.accountType
        \o message.openClose
        \o message.hedgeSpec
        \o message.clearingOperationMode
        \o message.clearingDestination

DecodeClearingData8(bytes) ==
    LET clearingInstruction == ReadBytes(bytes, 12) IN IF ~clearingInstruction.ok THEN Fail ELSE
    LET accountType == ReadBytes(clearingInstruction.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET openClose == ReadBytes(accountType.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET hedgeSpec == ReadBytes(openClose.rest, 1) IN IF ~hedgeSpec.ok THEN Fail ELSE
    LET clearingOperationMode == ReadBytes(hedgeSpec.rest, 1) IN IF ~clearingOperationMode.ok THEN Fail ELSE
    LET clearingDestination == ReadBytes(clearingOperationMode.rest, 4) IN IF ~clearingDestination.ok THEN Fail ELSE
    Ok([ clearingInstruction   |-> clearingInstruction.value,
         accountType           |-> accountType.value,
         openClose             |-> openClose.value,
         hedgeSpec             |-> hedgeSpec.value,
         clearingOperationMode |-> clearingOperationMode.value,
         clearingDestination   |-> clearingDestination.value ], clearingDestination.rest)

ZeroClearingData8 ==
    [ clearingInstruction   |-> [i \in 1 .. 12 |-> 0],
      accountType           |-> [i \in 1 .. 1 |-> 0],
      openClose             |-> [i \in 1 .. 1 |-> 0],
      hedgeSpec             |-> [i \in 1 .. 1 |-> 0],
      clearingOperationMode |-> [i \in 1 .. 1 |-> 0],
      clearingDestination   |-> [i \in 1 .. 4 |-> 0] ]

(* Clearing Data at zero, then each field in turn at the values it is checked at *)
CheckedClearingData8 ==
    { ZeroClearingData8 }
        \cup { [ZeroClearingData8 EXCEPT !.clearingInstruction = one] : one \in Sample(12) }
        \cup { [ZeroClearingData8 EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroClearingData8 EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroClearingData8 EXCEPT !.hedgeSpec = one] : one \in Sample(1) }
        \cup { [ZeroClearingData8 EXCEPT !.clearingOperationMode = one] : one \in Sample(1) }
        \cup { [ZeroClearingData8 EXCEPT !.clearingDestination = one] : one \in Sample(4) }

(***************************************************************************)
(* Owner Data: 71 bytes                                                    *)
(***************************************************************************)

OwnerData8 ==
    [ clientOrderId : Sample(20),
      poundSign     : Sample(1),
      memo          : Sample(50) ]

EncodeOwnerData8(message) ==
    message.clientOrderId
        \o message.poundSign
        \o message.memo

DecodeOwnerData8(bytes) ==
    LET clientOrderId == ReadBytes(bytes, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET poundSign == ReadBytes(clientOrderId.rest, 1) IN IF ~poundSign.ok THEN Fail ELSE
    LET memo == ReadBytes(poundSign.rest, 50) IN IF ~memo.ok THEN Fail ELSE
    Ok([ clientOrderId |-> clientOrderId.value,
         poundSign     |-> poundSign.value,
         memo          |-> memo.value ], memo.rest)

ZeroOwnerData8 ==
    [ clientOrderId |-> [i \in 1 .. 20 |-> 0],
      poundSign     |-> [i \in 1 .. 1 |-> 0],
      memo          |-> [i \in 1 .. 50 |-> 0] ]

(* Owner Data at zero, then each field in turn at the values it is checked at *)
CheckedOwnerData8 ==
    { ZeroOwnerData8 }
        \cup { [ZeroOwnerData8 EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroOwnerData8 EXCEPT !.poundSign = one] : one \in Sample(1) }
        \cup { [ZeroOwnerData8 EXCEPT !.memo = one] : one \in Sample(50) }

(***************************************************************************)
(* Execution Notice: 240 bytes                                             *)
(***************************************************************************)

ExecutionNotice ==
    [ group                              : Sample(2),
      instrumentOptional                 : Sample(4),
      traderId                           : Sample(8),
      referenceId                        : Sample(8),
      verbSide                           : Sample(1),
      quantityTraded                     : Sample(8),
      tradePrice                         : Sample(10),
      timeOfTheTradeHhmmss               : Sample(6),
      clearingData                       : ClearingData8,
      ownerData                          : OwnerData8,
      specialTradeIndicator              : Sample(1),
      priceType                          : Sample(1),
      tradeType                          : Sample(1),
      auctionIdOptional                  : Sample(6),
      tradeNumber                        : Sample(8),
      tradeMemo                          : Sample(50),
      originalReferenceId                : Sample(8),
      idCodeForTheCounterpartParticipant : Sample(4),
      liquidityStatus                    : Sample(1),
      counterpartAccountType             : Sample(1),
      additionalClientMemo               : Sample(16),
      reserved1                          : Sample(1),
      reserved4                          : Sample(4) ]

EncodeExecutionNotice(message) ==
    message.group
        \o message.instrumentOptional
        \o message.traderId
        \o message.referenceId
        \o message.verbSide
        \o message.quantityTraded
        \o message.tradePrice
        \o message.timeOfTheTradeHhmmss
        \o EncodeClearingData8(message.clearingData)
        \o EncodeOwnerData8(message.ownerData)
        \o message.specialTradeIndicator
        \o message.priceType
        \o message.tradeType
        \o message.auctionIdOptional
        \o message.tradeNumber
        \o message.tradeMemo
        \o message.originalReferenceId
        \o message.idCodeForTheCounterpartParticipant
        \o message.liquidityStatus
        \o message.counterpartAccountType
        \o message.additionalClientMemo
        \o message.reserved1
        \o message.reserved4

DecodeExecutionNotice(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrumentOptional == ReadBytes(group.rest, 4) IN IF ~instrumentOptional.ok THEN Fail ELSE
    LET traderId == ReadBytes(instrumentOptional.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET referenceId == ReadBytes(traderId.rest, 8) IN IF ~referenceId.ok THEN Fail ELSE
    LET verbSide == ReadBytes(referenceId.rest, 1) IN IF ~verbSide.ok THEN Fail ELSE
    LET quantityTraded == ReadBytes(verbSide.rest, 8) IN IF ~quantityTraded.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(quantityTraded.rest, 10) IN IF ~tradePrice.ok THEN Fail ELSE
    LET timeOfTheTradeHhmmss == ReadBytes(tradePrice.rest, 6) IN IF ~timeOfTheTradeHhmmss.ok THEN Fail ELSE
    LET clearingData == DecodeClearingData8(timeOfTheTradeHhmmss.rest) IN IF ~clearingData.ok THEN Fail ELSE
    LET ownerData == DecodeOwnerData8(clearingData.rest) IN IF ~ownerData.ok THEN Fail ELSE
    LET specialTradeIndicator == ReadBytes(ownerData.rest, 1) IN IF ~specialTradeIndicator.ok THEN Fail ELSE
    LET priceType == ReadBytes(specialTradeIndicator.rest, 1) IN IF ~priceType.ok THEN Fail ELSE
    LET tradeType == ReadBytes(priceType.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET auctionIdOptional == ReadBytes(tradeType.rest, 6) IN IF ~auctionIdOptional.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(auctionIdOptional.rest, 8) IN IF ~tradeNumber.ok THEN Fail ELSE
    LET tradeMemo == ReadBytes(tradeNumber.rest, 50) IN IF ~tradeMemo.ok THEN Fail ELSE
    LET originalReferenceId == ReadBytes(tradeMemo.rest, 8) IN IF ~originalReferenceId.ok THEN Fail ELSE
    LET idCodeForTheCounterpartParticipant == ReadBytes(originalReferenceId.rest, 4) IN IF ~idCodeForTheCounterpartParticipant.ok THEN Fail ELSE
    LET liquidityStatus == ReadBytes(idCodeForTheCounterpartParticipant.rest, 1) IN IF ~liquidityStatus.ok THEN Fail ELSE
    LET counterpartAccountType == ReadBytes(liquidityStatus.rest, 1) IN IF ~counterpartAccountType.ok THEN Fail ELSE
    LET additionalClientMemo == ReadBytes(counterpartAccountType.rest, 16) IN IF ~additionalClientMemo.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(additionalClientMemo.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(reserved1.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    Ok([ group                              |-> group.value,
         instrumentOptional                 |-> instrumentOptional.value,
         traderId                           |-> traderId.value,
         referenceId                        |-> referenceId.value,
         verbSide                           |-> verbSide.value,
         quantityTraded                     |-> quantityTraded.value,
         tradePrice                         |-> tradePrice.value,
         timeOfTheTradeHhmmss               |-> timeOfTheTradeHhmmss.value,
         clearingData                       |-> clearingData.value,
         ownerData                          |-> ownerData.value,
         specialTradeIndicator              |-> specialTradeIndicator.value,
         priceType                          |-> priceType.value,
         tradeType                          |-> tradeType.value,
         auctionIdOptional                  |-> auctionIdOptional.value,
         tradeNumber                        |-> tradeNumber.value,
         tradeMemo                          |-> tradeMemo.value,
         originalReferenceId                |-> originalReferenceId.value,
         idCodeForTheCounterpartParticipant |-> idCodeForTheCounterpartParticipant.value,
         liquidityStatus                    |-> liquidityStatus.value,
         counterpartAccountType             |-> counterpartAccountType.value,
         additionalClientMemo               |-> additionalClientMemo.value,
         reserved1                          |-> reserved1.value,
         reserved4                          |-> reserved4.value ], reserved4.rest)

ZeroExecutionNotice ==
    [ group                              |-> [i \in 1 .. 2 |-> 0],
      instrumentOptional                 |-> [i \in 1 .. 4 |-> 0],
      traderId                           |-> [i \in 1 .. 8 |-> 0],
      referenceId                        |-> [i \in 1 .. 8 |-> 0],
      verbSide                           |-> [i \in 1 .. 1 |-> 0],
      quantityTraded                     |-> [i \in 1 .. 8 |-> 0],
      tradePrice                         |-> [i \in 1 .. 10 |-> 0],
      timeOfTheTradeHhmmss               |-> [i \in 1 .. 6 |-> 0],
      clearingData                       |-> ZeroClearingData8,
      ownerData                          |-> ZeroOwnerData8,
      specialTradeIndicator              |-> [i \in 1 .. 1 |-> 0],
      priceType                          |-> [i \in 1 .. 1 |-> 0],
      tradeType                          |-> [i \in 1 .. 1 |-> 0],
      auctionIdOptional                  |-> [i \in 1 .. 6 |-> 0],
      tradeNumber                        |-> [i \in 1 .. 8 |-> 0],
      tradeMemo                          |-> [i \in 1 .. 50 |-> 0],
      originalReferenceId                |-> [i \in 1 .. 8 |-> 0],
      idCodeForTheCounterpartParticipant |-> [i \in 1 .. 4 |-> 0],
      liquidityStatus                    |-> [i \in 1 .. 1 |-> 0],
      counterpartAccountType             |-> [i \in 1 .. 1 |-> 0],
      additionalClientMemo               |-> [i \in 1 .. 16 |-> 0],
      reserved1                          |-> [i \in 1 .. 1 |-> 0],
      reserved4                          |-> [i \in 1 .. 4 |-> 0] ]

(* Execution Notice at zero, then each field in turn at the values it is checked at *)
CheckedExecutionNotice ==
    { ZeroExecutionNotice }
        \cup { [ZeroExecutionNotice EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroExecutionNotice EXCEPT !.instrumentOptional = one] : one \in Sample(4) }
        \cup { [ZeroExecutionNotice EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionNotice EXCEPT !.referenceId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionNotice EXCEPT !.verbSide = one] : one \in Sample(1) }
        \cup { [ZeroExecutionNotice EXCEPT !.quantityTraded = one] : one \in Sample(8) }
        \cup { [ZeroExecutionNotice EXCEPT !.tradePrice = one] : one \in Sample(10) }
        \cup { [ZeroExecutionNotice EXCEPT !.timeOfTheTradeHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroExecutionNotice EXCEPT !.clearingData = one] : one \in CheckedClearingData8 }
        \cup { [ZeroExecutionNotice EXCEPT !.ownerData = one] : one \in CheckedOwnerData8 }
        \cup { [ZeroExecutionNotice EXCEPT !.specialTradeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExecutionNotice EXCEPT !.priceType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionNotice EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionNotice EXCEPT !.auctionIdOptional = one] : one \in Sample(6) }
        \cup { [ZeroExecutionNotice EXCEPT !.tradeNumber = one] : one \in Sample(8) }
        \cup { [ZeroExecutionNotice EXCEPT !.tradeMemo = one] : one \in Sample(50) }
        \cup { [ZeroExecutionNotice EXCEPT !.originalReferenceId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionNotice EXCEPT !.idCodeForTheCounterpartParticipant = one] : one \in Sample(4) }
        \cup { [ZeroExecutionNotice EXCEPT !.liquidityStatus = one] : one \in Sample(1) }
        \cup { [ZeroExecutionNotice EXCEPT !.counterpartAccountType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionNotice EXCEPT !.additionalClientMemo = one] : one \in Sample(16) }
        \cup { [ZeroExecutionNotice EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroExecutionNotice EXCEPT !.reserved4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Quote Notice: 75 bytes                                                  *)
(***************************************************************************)

QuoteNotice ==
    [ group                             : Sample(2),
      instrumentOptional                : Sample(4),
      traderId                          : Sample(8),
      referenceIdQuote                  : Sample(8),
      verbSide                          : Sample(1),
      orderType                         : Sample(1),
      action                            : Sample(1),
      newQuantity                       : Sample(8),
      newPrice                          : Sample(10),
      previousQuantity                  : Sample(8),
      previousPrice                     : Sample(10),
      auctionIdOptional                 : Sample(6),
      originalReferenceIdQuoteOrOrderId : Sample(8) ]

EncodeQuoteNotice(message) ==
    message.group
        \o message.instrumentOptional
        \o message.traderId
        \o message.referenceIdQuote
        \o message.verbSide
        \o message.orderType
        \o message.action
        \o message.newQuantity
        \o message.newPrice
        \o message.previousQuantity
        \o message.previousPrice
        \o message.auctionIdOptional
        \o message.originalReferenceIdQuoteOrOrderId

DecodeQuoteNotice(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrumentOptional == ReadBytes(group.rest, 4) IN IF ~instrumentOptional.ok THEN Fail ELSE
    LET traderId == ReadBytes(instrumentOptional.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET referenceIdQuote == ReadBytes(traderId.rest, 8) IN IF ~referenceIdQuote.ok THEN Fail ELSE
    LET verbSide == ReadBytes(referenceIdQuote.rest, 1) IN IF ~verbSide.ok THEN Fail ELSE
    LET orderType == ReadBytes(verbSide.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET action == ReadBytes(orderType.rest, 1) IN IF ~action.ok THEN Fail ELSE
    LET newQuantity == ReadBytes(action.rest, 8) IN IF ~newQuantity.ok THEN Fail ELSE
    LET newPrice == ReadBytes(newQuantity.rest, 10) IN IF ~newPrice.ok THEN Fail ELSE
    LET previousQuantity == ReadBytes(newPrice.rest, 8) IN IF ~previousQuantity.ok THEN Fail ELSE
    LET previousPrice == ReadBytes(previousQuantity.rest, 10) IN IF ~previousPrice.ok THEN Fail ELSE
    LET auctionIdOptional == ReadBytes(previousPrice.rest, 6) IN IF ~auctionIdOptional.ok THEN Fail ELSE
    LET originalReferenceIdQuoteOrOrderId == ReadBytes(auctionIdOptional.rest, 8) IN IF ~originalReferenceIdQuoteOrOrderId.ok THEN Fail ELSE
    Ok([ group                             |-> group.value,
         instrumentOptional                |-> instrumentOptional.value,
         traderId                          |-> traderId.value,
         referenceIdQuote                  |-> referenceIdQuote.value,
         verbSide                          |-> verbSide.value,
         orderType                         |-> orderType.value,
         action                            |-> action.value,
         newQuantity                       |-> newQuantity.value,
         newPrice                          |-> newPrice.value,
         previousQuantity                  |-> previousQuantity.value,
         previousPrice                     |-> previousPrice.value,
         auctionIdOptional                 |-> auctionIdOptional.value,
         originalReferenceIdQuoteOrOrderId |-> originalReferenceIdQuoteOrOrderId.value ], originalReferenceIdQuoteOrOrderId.rest)

ZeroQuoteNotice ==
    [ group                             |-> [i \in 1 .. 2 |-> 0],
      instrumentOptional                |-> [i \in 1 .. 4 |-> 0],
      traderId                          |-> [i \in 1 .. 8 |-> 0],
      referenceIdQuote                  |-> [i \in 1 .. 8 |-> 0],
      verbSide                          |-> [i \in 1 .. 1 |-> 0],
      orderType                         |-> [i \in 1 .. 1 |-> 0],
      action                            |-> [i \in 1 .. 1 |-> 0],
      newQuantity                       |-> [i \in 1 .. 8 |-> 0],
      newPrice                          |-> [i \in 1 .. 10 |-> 0],
      previousQuantity                  |-> [i \in 1 .. 8 |-> 0],
      previousPrice                     |-> [i \in 1 .. 10 |-> 0],
      auctionIdOptional                 |-> [i \in 1 .. 6 |-> 0],
      originalReferenceIdQuoteOrOrderId |-> [i \in 1 .. 8 |-> 0] ]

(* Quote Notice at zero, then each field in turn at the values it is checked at *)
CheckedQuoteNotice ==
    { ZeroQuoteNotice }
        \cup { [ZeroQuoteNotice EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroQuoteNotice EXCEPT !.instrumentOptional = one] : one \in Sample(4) }
        \cup { [ZeroQuoteNotice EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteNotice EXCEPT !.referenceIdQuote = one] : one \in Sample(8) }
        \cup { [ZeroQuoteNotice EXCEPT !.verbSide = one] : one \in Sample(1) }
        \cup { [ZeroQuoteNotice EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroQuoteNotice EXCEPT !.action = one] : one \in Sample(1) }
        \cup { [ZeroQuoteNotice EXCEPT !.newQuantity = one] : one \in Sample(8) }
        \cup { [ZeroQuoteNotice EXCEPT !.newPrice = one] : one \in Sample(10) }
        \cup { [ZeroQuoteNotice EXCEPT !.previousQuantity = one] : one \in Sample(8) }
        \cup { [ZeroQuoteNotice EXCEPT !.previousPrice = one] : one \in Sample(10) }
        \cup { [ZeroQuoteNotice EXCEPT !.auctionIdOptional = one] : one \in Sample(6) }
        \cup { [ZeroQuoteNotice EXCEPT !.originalReferenceIdQuoteOrOrderId = one] : one \in Sample(8) }

(***************************************************************************)
(* Clearing Data: 20 bytes                                                 *)
(***************************************************************************)

ClearingData9 ==
    [ clearingInstruction   : Sample(12),
      accountType           : Sample(1),
      openClose             : Sample(1),
      hedgeSpec             : Sample(1),
      clearingOperationMode : Sample(1),
      clearingDestination   : Sample(4) ]

EncodeClearingData9(message) ==
    message.clearingInstruction
        \o message.accountType
        \o message.openClose
        \o message.hedgeSpec
        \o message.clearingOperationMode
        \o message.clearingDestination

DecodeClearingData9(bytes) ==
    LET clearingInstruction == ReadBytes(bytes, 12) IN IF ~clearingInstruction.ok THEN Fail ELSE
    LET accountType == ReadBytes(clearingInstruction.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET openClose == ReadBytes(accountType.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET hedgeSpec == ReadBytes(openClose.rest, 1) IN IF ~hedgeSpec.ok THEN Fail ELSE
    LET clearingOperationMode == ReadBytes(hedgeSpec.rest, 1) IN IF ~clearingOperationMode.ok THEN Fail ELSE
    LET clearingDestination == ReadBytes(clearingOperationMode.rest, 4) IN IF ~clearingDestination.ok THEN Fail ELSE
    Ok([ clearingInstruction   |-> clearingInstruction.value,
         accountType           |-> accountType.value,
         openClose             |-> openClose.value,
         hedgeSpec             |-> hedgeSpec.value,
         clearingOperationMode |-> clearingOperationMode.value,
         clearingDestination   |-> clearingDestination.value ], clearingDestination.rest)

ZeroClearingData9 ==
    [ clearingInstruction   |-> [i \in 1 .. 12 |-> 0],
      accountType           |-> [i \in 1 .. 1 |-> 0],
      openClose             |-> [i \in 1 .. 1 |-> 0],
      hedgeSpec             |-> [i \in 1 .. 1 |-> 0],
      clearingOperationMode |-> [i \in 1 .. 1 |-> 0],
      clearingDestination   |-> [i \in 1 .. 4 |-> 0] ]

(* Clearing Data at zero, then each field in turn at the values it is checked at *)
CheckedClearingData9 ==
    { ZeroClearingData9 }
        \cup { [ZeroClearingData9 EXCEPT !.clearingInstruction = one] : one \in Sample(12) }
        \cup { [ZeroClearingData9 EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroClearingData9 EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroClearingData9 EXCEPT !.hedgeSpec = one] : one \in Sample(1) }
        \cup { [ZeroClearingData9 EXCEPT !.clearingOperationMode = one] : one \in Sample(1) }
        \cup { [ZeroClearingData9 EXCEPT !.clearingDestination = one] : one \in Sample(4) }

(***************************************************************************)
(* Owner Data: 71 bytes                                                    *)
(***************************************************************************)

OwnerData9 ==
    [ clientOrderId : Sample(20),
      poundSign     : Sample(1),
      memo          : Sample(50) ]

EncodeOwnerData9(message) ==
    message.clientOrderId
        \o message.poundSign
        \o message.memo

DecodeOwnerData9(bytes) ==
    LET clientOrderId == ReadBytes(bytes, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET poundSign == ReadBytes(clientOrderId.rest, 1) IN IF ~poundSign.ok THEN Fail ELSE
    LET memo == ReadBytes(poundSign.rest, 50) IN IF ~memo.ok THEN Fail ELSE
    Ok([ clientOrderId |-> clientOrderId.value,
         poundSign     |-> poundSign.value,
         memo          |-> memo.value ], memo.rest)

ZeroOwnerData9 ==
    [ clientOrderId |-> [i \in 1 .. 20 |-> 0],
      poundSign     |-> [i \in 1 .. 1 |-> 0],
      memo          |-> [i \in 1 .. 50 |-> 0] ]

(* Owner Data at zero, then each field in turn at the values it is checked at *)
CheckedOwnerData9 ==
    { ZeroOwnerData9 }
        \cup { [ZeroOwnerData9 EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroOwnerData9 EXCEPT !.poundSign = one] : one \in Sample(1) }
        \cup { [ZeroOwnerData9 EXCEPT !.memo = one] : one \in Sample(50) }

(***************************************************************************)
(* Execution Cancellation Notice: 240 bytes                                *)
(***************************************************************************)

ExecutionCancellationNotice ==
    [ group                              : Sample(2),
      instrumentOptional                 : Sample(4),
      traderId                           : Sample(8),
      referenceId                        : Sample(8),
      verbSide                           : Sample(1),
      quantityTraded                     : Sample(8),
      tradePrice                         : Sample(10),
      timeOfTheTradeHhmmss               : Sample(6),
      clearingData                       : ClearingData9,
      ownerData                          : OwnerData9,
      specialTradeIndicator              : Sample(1),
      priceType                          : Sample(1),
      tradeType                          : Sample(1),
      auctionIdOptional                  : Sample(6),
      tradeNumber                        : Sample(8),
      tradeMemo                          : Sample(50),
      originalReferenceId                : Sample(8),
      idCodeForTheCounterpartParticipant : Sample(4),
      liquidityStatus                    : Sample(1),
      counterpartAccountType             : Sample(1),
      additionalClientMemo               : Sample(16),
      reserved1                          : Sample(1),
      reserved4                          : Sample(4) ]

EncodeExecutionCancellationNotice(message) ==
    message.group
        \o message.instrumentOptional
        \o message.traderId
        \o message.referenceId
        \o message.verbSide
        \o message.quantityTraded
        \o message.tradePrice
        \o message.timeOfTheTradeHhmmss
        \o EncodeClearingData9(message.clearingData)
        \o EncodeOwnerData9(message.ownerData)
        \o message.specialTradeIndicator
        \o message.priceType
        \o message.tradeType
        \o message.auctionIdOptional
        \o message.tradeNumber
        \o message.tradeMemo
        \o message.originalReferenceId
        \o message.idCodeForTheCounterpartParticipant
        \o message.liquidityStatus
        \o message.counterpartAccountType
        \o message.additionalClientMemo
        \o message.reserved1
        \o message.reserved4

DecodeExecutionCancellationNotice(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrumentOptional == ReadBytes(group.rest, 4) IN IF ~instrumentOptional.ok THEN Fail ELSE
    LET traderId == ReadBytes(instrumentOptional.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET referenceId == ReadBytes(traderId.rest, 8) IN IF ~referenceId.ok THEN Fail ELSE
    LET verbSide == ReadBytes(referenceId.rest, 1) IN IF ~verbSide.ok THEN Fail ELSE
    LET quantityTraded == ReadBytes(verbSide.rest, 8) IN IF ~quantityTraded.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(quantityTraded.rest, 10) IN IF ~tradePrice.ok THEN Fail ELSE
    LET timeOfTheTradeHhmmss == ReadBytes(tradePrice.rest, 6) IN IF ~timeOfTheTradeHhmmss.ok THEN Fail ELSE
    LET clearingData == DecodeClearingData9(timeOfTheTradeHhmmss.rest) IN IF ~clearingData.ok THEN Fail ELSE
    LET ownerData == DecodeOwnerData9(clearingData.rest) IN IF ~ownerData.ok THEN Fail ELSE
    LET specialTradeIndicator == ReadBytes(ownerData.rest, 1) IN IF ~specialTradeIndicator.ok THEN Fail ELSE
    LET priceType == ReadBytes(specialTradeIndicator.rest, 1) IN IF ~priceType.ok THEN Fail ELSE
    LET tradeType == ReadBytes(priceType.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET auctionIdOptional == ReadBytes(tradeType.rest, 6) IN IF ~auctionIdOptional.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(auctionIdOptional.rest, 8) IN IF ~tradeNumber.ok THEN Fail ELSE
    LET tradeMemo == ReadBytes(tradeNumber.rest, 50) IN IF ~tradeMemo.ok THEN Fail ELSE
    LET originalReferenceId == ReadBytes(tradeMemo.rest, 8) IN IF ~originalReferenceId.ok THEN Fail ELSE
    LET idCodeForTheCounterpartParticipant == ReadBytes(originalReferenceId.rest, 4) IN IF ~idCodeForTheCounterpartParticipant.ok THEN Fail ELSE
    LET liquidityStatus == ReadBytes(idCodeForTheCounterpartParticipant.rest, 1) IN IF ~liquidityStatus.ok THEN Fail ELSE
    LET counterpartAccountType == ReadBytes(liquidityStatus.rest, 1) IN IF ~counterpartAccountType.ok THEN Fail ELSE
    LET additionalClientMemo == ReadBytes(counterpartAccountType.rest, 16) IN IF ~additionalClientMemo.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(additionalClientMemo.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(reserved1.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    Ok([ group                              |-> group.value,
         instrumentOptional                 |-> instrumentOptional.value,
         traderId                           |-> traderId.value,
         referenceId                        |-> referenceId.value,
         verbSide                           |-> verbSide.value,
         quantityTraded                     |-> quantityTraded.value,
         tradePrice                         |-> tradePrice.value,
         timeOfTheTradeHhmmss               |-> timeOfTheTradeHhmmss.value,
         clearingData                       |-> clearingData.value,
         ownerData                          |-> ownerData.value,
         specialTradeIndicator              |-> specialTradeIndicator.value,
         priceType                          |-> priceType.value,
         tradeType                          |-> tradeType.value,
         auctionIdOptional                  |-> auctionIdOptional.value,
         tradeNumber                        |-> tradeNumber.value,
         tradeMemo                          |-> tradeMemo.value,
         originalReferenceId                |-> originalReferenceId.value,
         idCodeForTheCounterpartParticipant |-> idCodeForTheCounterpartParticipant.value,
         liquidityStatus                    |-> liquidityStatus.value,
         counterpartAccountType             |-> counterpartAccountType.value,
         additionalClientMemo               |-> additionalClientMemo.value,
         reserved1                          |-> reserved1.value,
         reserved4                          |-> reserved4.value ], reserved4.rest)

ZeroExecutionCancellationNotice ==
    [ group                              |-> [i \in 1 .. 2 |-> 0],
      instrumentOptional                 |-> [i \in 1 .. 4 |-> 0],
      traderId                           |-> [i \in 1 .. 8 |-> 0],
      referenceId                        |-> [i \in 1 .. 8 |-> 0],
      verbSide                           |-> [i \in 1 .. 1 |-> 0],
      quantityTraded                     |-> [i \in 1 .. 8 |-> 0],
      tradePrice                         |-> [i \in 1 .. 10 |-> 0],
      timeOfTheTradeHhmmss               |-> [i \in 1 .. 6 |-> 0],
      clearingData                       |-> ZeroClearingData9,
      ownerData                          |-> ZeroOwnerData9,
      specialTradeIndicator              |-> [i \in 1 .. 1 |-> 0],
      priceType                          |-> [i \in 1 .. 1 |-> 0],
      tradeType                          |-> [i \in 1 .. 1 |-> 0],
      auctionIdOptional                  |-> [i \in 1 .. 6 |-> 0],
      tradeNumber                        |-> [i \in 1 .. 8 |-> 0],
      tradeMemo                          |-> [i \in 1 .. 50 |-> 0],
      originalReferenceId                |-> [i \in 1 .. 8 |-> 0],
      idCodeForTheCounterpartParticipant |-> [i \in 1 .. 4 |-> 0],
      liquidityStatus                    |-> [i \in 1 .. 1 |-> 0],
      counterpartAccountType             |-> [i \in 1 .. 1 |-> 0],
      additionalClientMemo               |-> [i \in 1 .. 16 |-> 0],
      reserved1                          |-> [i \in 1 .. 1 |-> 0],
      reserved4                          |-> [i \in 1 .. 4 |-> 0] ]

(* Execution Cancellation Notice at zero, then each field in turn at the values it is checked at *)
CheckedExecutionCancellationNotice ==
    { ZeroExecutionCancellationNotice }
        \cup { [ZeroExecutionCancellationNotice EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroExecutionCancellationNotice EXCEPT !.instrumentOptional = one] : one \in Sample(4) }
        \cup { [ZeroExecutionCancellationNotice EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionCancellationNotice EXCEPT !.referenceId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionCancellationNotice EXCEPT !.verbSide = one] : one \in Sample(1) }
        \cup { [ZeroExecutionCancellationNotice EXCEPT !.quantityTraded = one] : one \in Sample(8) }
        \cup { [ZeroExecutionCancellationNotice EXCEPT !.tradePrice = one] : one \in Sample(10) }
        \cup { [ZeroExecutionCancellationNotice EXCEPT !.timeOfTheTradeHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroExecutionCancellationNotice EXCEPT !.clearingData = one] : one \in CheckedClearingData9 }
        \cup { [ZeroExecutionCancellationNotice EXCEPT !.ownerData = one] : one \in CheckedOwnerData9 }
        \cup { [ZeroExecutionCancellationNotice EXCEPT !.specialTradeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExecutionCancellationNotice EXCEPT !.priceType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionCancellationNotice EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionCancellationNotice EXCEPT !.auctionIdOptional = one] : one \in Sample(6) }
        \cup { [ZeroExecutionCancellationNotice EXCEPT !.tradeNumber = one] : one \in Sample(8) }
        \cup { [ZeroExecutionCancellationNotice EXCEPT !.tradeMemo = one] : one \in Sample(50) }
        \cup { [ZeroExecutionCancellationNotice EXCEPT !.originalReferenceId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionCancellationNotice EXCEPT !.idCodeForTheCounterpartParticipant = one] : one \in Sample(4) }
        \cup { [ZeroExecutionCancellationNotice EXCEPT !.liquidityStatus = one] : one \in Sample(1) }
        \cup { [ZeroExecutionCancellationNotice EXCEPT !.counterpartAccountType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionCancellationNotice EXCEPT !.additionalClientMemo = one] : one \in Sample(16) }
        \cup { [ZeroExecutionCancellationNotice EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroExecutionCancellationNotice EXCEPT !.reserved4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Clearing Data: 20 bytes                                                 *)
(***************************************************************************)

ClearingData10 ==
    [ clearingInstruction   : Sample(12),
      accountType           : Sample(1),
      openClose             : Sample(1),
      hedgeSpec             : Sample(1),
      clearingOperationMode : Sample(1),
      clearingDestination   : Sample(4) ]

EncodeClearingData10(message) ==
    message.clearingInstruction
        \o message.accountType
        \o message.openClose
        \o message.hedgeSpec
        \o message.clearingOperationMode
        \o message.clearingDestination

DecodeClearingData10(bytes) ==
    LET clearingInstruction == ReadBytes(bytes, 12) IN IF ~clearingInstruction.ok THEN Fail ELSE
    LET accountType == ReadBytes(clearingInstruction.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET openClose == ReadBytes(accountType.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET hedgeSpec == ReadBytes(openClose.rest, 1) IN IF ~hedgeSpec.ok THEN Fail ELSE
    LET clearingOperationMode == ReadBytes(hedgeSpec.rest, 1) IN IF ~clearingOperationMode.ok THEN Fail ELSE
    LET clearingDestination == ReadBytes(clearingOperationMode.rest, 4) IN IF ~clearingDestination.ok THEN Fail ELSE
    Ok([ clearingInstruction   |-> clearingInstruction.value,
         accountType           |-> accountType.value,
         openClose             |-> openClose.value,
         hedgeSpec             |-> hedgeSpec.value,
         clearingOperationMode |-> clearingOperationMode.value,
         clearingDestination   |-> clearingDestination.value ], clearingDestination.rest)

ZeroClearingData10 ==
    [ clearingInstruction   |-> [i \in 1 .. 12 |-> 0],
      accountType           |-> [i \in 1 .. 1 |-> 0],
      openClose             |-> [i \in 1 .. 1 |-> 0],
      hedgeSpec             |-> [i \in 1 .. 1 |-> 0],
      clearingOperationMode |-> [i \in 1 .. 1 |-> 0],
      clearingDestination   |-> [i \in 1 .. 4 |-> 0] ]

(* Clearing Data at zero, then each field in turn at the values it is checked at *)
CheckedClearingData10 ==
    { ZeroClearingData10 }
        \cup { [ZeroClearingData10 EXCEPT !.clearingInstruction = one] : one \in Sample(12) }
        \cup { [ZeroClearingData10 EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroClearingData10 EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroClearingData10 EXCEPT !.hedgeSpec = one] : one \in Sample(1) }
        \cup { [ZeroClearingData10 EXCEPT !.clearingOperationMode = one] : one \in Sample(1) }
        \cup { [ZeroClearingData10 EXCEPT !.clearingDestination = one] : one \in Sample(4) }

(***************************************************************************)
(* Owner Data: 71 bytes                                                    *)
(***************************************************************************)

OwnerData10 ==
    [ clientOrderId : Sample(20),
      poundSign     : Sample(1),
      memo          : Sample(50) ]

EncodeOwnerData10(message) ==
    message.clientOrderId
        \o message.poundSign
        \o message.memo

DecodeOwnerData10(bytes) ==
    LET clientOrderId == ReadBytes(bytes, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET poundSign == ReadBytes(clientOrderId.rest, 1) IN IF ~poundSign.ok THEN Fail ELSE
    LET memo == ReadBytes(poundSign.rest, 50) IN IF ~memo.ok THEN Fail ELSE
    Ok([ clientOrderId |-> clientOrderId.value,
         poundSign     |-> poundSign.value,
         memo          |-> memo.value ], memo.rest)

ZeroOwnerData10 ==
    [ clientOrderId |-> [i \in 1 .. 20 |-> 0],
      poundSign     |-> [i \in 1 .. 1 |-> 0],
      memo          |-> [i \in 1 .. 50 |-> 0] ]

(* Owner Data at zero, then each field in turn at the values it is checked at *)
CheckedOwnerData10 ==
    { ZeroOwnerData10 }
        \cup { [ZeroOwnerData10 EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroOwnerData10 EXCEPT !.poundSign = one] : one \in Sample(1) }
        \cup { [ZeroOwnerData10 EXCEPT !.memo = one] : one \in Sample(50) }

(***************************************************************************)
(* Leg Execution Cancellation Notice: 257 bytes                            *)
(***************************************************************************)

LegExecutionCancellationNotice ==
    [ group                              : Sample(2),
      instrumentOptional                 : Sample(4),
      traderId                           : Sample(8),
      referenceId                        : Sample(8),
      verbSide                           : Sample(1),
      quantityTraded                     : Sample(8),
      tradePrice                         : Sample(10),
      timeTradeHhmmss                    : Sample(6),
      clearingData                       : ClearingData10,
      ownerData                          : OwnerData10,
      specialTradeIndicator              : Sample(1),
      priceType                          : Sample(1),
      tradeType                          : Sample(1),
      auctionIdOptional                  : Sample(6),
      tradeNumber                        : Sample(8),
      tradeMemo                          : Sample(50),
      originalReferenceId                : Sample(8),
      idCodeForTheCounterpartParticipant : Sample(4),
      liquidityStatus                    : Sample(1),
      strategyGroup                      : Sample(2),
      strategyInstrumentId               : Sample(4),
      strategyVerbSide                   : Sample(1),
      strategyTradeNumber                : Sample(8),
      legNumber                          : Sample(2),
      counterpartAccountType             : Sample(1),
      additionalClientMemo               : Sample(16),
      reserved1                          : Sample(1),
      reserved4                          : Sample(4) ]

EncodeLegExecutionCancellationNotice(message) ==
    message.group
        \o message.instrumentOptional
        \o message.traderId
        \o message.referenceId
        \o message.verbSide
        \o message.quantityTraded
        \o message.tradePrice
        \o message.timeTradeHhmmss
        \o EncodeClearingData10(message.clearingData)
        \o EncodeOwnerData10(message.ownerData)
        \o message.specialTradeIndicator
        \o message.priceType
        \o message.tradeType
        \o message.auctionIdOptional
        \o message.tradeNumber
        \o message.tradeMemo
        \o message.originalReferenceId
        \o message.idCodeForTheCounterpartParticipant
        \o message.liquidityStatus
        \o message.strategyGroup
        \o message.strategyInstrumentId
        \o message.strategyVerbSide
        \o message.strategyTradeNumber
        \o message.legNumber
        \o message.counterpartAccountType
        \o message.additionalClientMemo
        \o message.reserved1
        \o message.reserved4

DecodeLegExecutionCancellationNotice(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrumentOptional == ReadBytes(group.rest, 4) IN IF ~instrumentOptional.ok THEN Fail ELSE
    LET traderId == ReadBytes(instrumentOptional.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET referenceId == ReadBytes(traderId.rest, 8) IN IF ~referenceId.ok THEN Fail ELSE
    LET verbSide == ReadBytes(referenceId.rest, 1) IN IF ~verbSide.ok THEN Fail ELSE
    LET quantityTraded == ReadBytes(verbSide.rest, 8) IN IF ~quantityTraded.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(quantityTraded.rest, 10) IN IF ~tradePrice.ok THEN Fail ELSE
    LET timeTradeHhmmss == ReadBytes(tradePrice.rest, 6) IN IF ~timeTradeHhmmss.ok THEN Fail ELSE
    LET clearingData == DecodeClearingData10(timeTradeHhmmss.rest) IN IF ~clearingData.ok THEN Fail ELSE
    LET ownerData == DecodeOwnerData10(clearingData.rest) IN IF ~ownerData.ok THEN Fail ELSE
    LET specialTradeIndicator == ReadBytes(ownerData.rest, 1) IN IF ~specialTradeIndicator.ok THEN Fail ELSE
    LET priceType == ReadBytes(specialTradeIndicator.rest, 1) IN IF ~priceType.ok THEN Fail ELSE
    LET tradeType == ReadBytes(priceType.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET auctionIdOptional == ReadBytes(tradeType.rest, 6) IN IF ~auctionIdOptional.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(auctionIdOptional.rest, 8) IN IF ~tradeNumber.ok THEN Fail ELSE
    LET tradeMemo == ReadBytes(tradeNumber.rest, 50) IN IF ~tradeMemo.ok THEN Fail ELSE
    LET originalReferenceId == ReadBytes(tradeMemo.rest, 8) IN IF ~originalReferenceId.ok THEN Fail ELSE
    LET idCodeForTheCounterpartParticipant == ReadBytes(originalReferenceId.rest, 4) IN IF ~idCodeForTheCounterpartParticipant.ok THEN Fail ELSE
    LET liquidityStatus == ReadBytes(idCodeForTheCounterpartParticipant.rest, 1) IN IF ~liquidityStatus.ok THEN Fail ELSE
    LET strategyGroup == ReadBytes(liquidityStatus.rest, 2) IN IF ~strategyGroup.ok THEN Fail ELSE
    LET strategyInstrumentId == ReadBytes(strategyGroup.rest, 4) IN IF ~strategyInstrumentId.ok THEN Fail ELSE
    LET strategyVerbSide == ReadBytes(strategyInstrumentId.rest, 1) IN IF ~strategyVerbSide.ok THEN Fail ELSE
    LET strategyTradeNumber == ReadBytes(strategyVerbSide.rest, 8) IN IF ~strategyTradeNumber.ok THEN Fail ELSE
    LET legNumber == ReadBytes(strategyTradeNumber.rest, 2) IN IF ~legNumber.ok THEN Fail ELSE
    LET counterpartAccountType == ReadBytes(legNumber.rest, 1) IN IF ~counterpartAccountType.ok THEN Fail ELSE
    LET additionalClientMemo == ReadBytes(counterpartAccountType.rest, 16) IN IF ~additionalClientMemo.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(additionalClientMemo.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(reserved1.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    Ok([ group                              |-> group.value,
         instrumentOptional                 |-> instrumentOptional.value,
         traderId                           |-> traderId.value,
         referenceId                        |-> referenceId.value,
         verbSide                           |-> verbSide.value,
         quantityTraded                     |-> quantityTraded.value,
         tradePrice                         |-> tradePrice.value,
         timeTradeHhmmss                    |-> timeTradeHhmmss.value,
         clearingData                       |-> clearingData.value,
         ownerData                          |-> ownerData.value,
         specialTradeIndicator              |-> specialTradeIndicator.value,
         priceType                          |-> priceType.value,
         tradeType                          |-> tradeType.value,
         auctionIdOptional                  |-> auctionIdOptional.value,
         tradeNumber                        |-> tradeNumber.value,
         tradeMemo                          |-> tradeMemo.value,
         originalReferenceId                |-> originalReferenceId.value,
         idCodeForTheCounterpartParticipant |-> idCodeForTheCounterpartParticipant.value,
         liquidityStatus                    |-> liquidityStatus.value,
         strategyGroup                      |-> strategyGroup.value,
         strategyInstrumentId               |-> strategyInstrumentId.value,
         strategyVerbSide                   |-> strategyVerbSide.value,
         strategyTradeNumber                |-> strategyTradeNumber.value,
         legNumber                          |-> legNumber.value,
         counterpartAccountType             |-> counterpartAccountType.value,
         additionalClientMemo               |-> additionalClientMemo.value,
         reserved1                          |-> reserved1.value,
         reserved4                          |-> reserved4.value ], reserved4.rest)

ZeroLegExecutionCancellationNotice ==
    [ group                              |-> [i \in 1 .. 2 |-> 0],
      instrumentOptional                 |-> [i \in 1 .. 4 |-> 0],
      traderId                           |-> [i \in 1 .. 8 |-> 0],
      referenceId                        |-> [i \in 1 .. 8 |-> 0],
      verbSide                           |-> [i \in 1 .. 1 |-> 0],
      quantityTraded                     |-> [i \in 1 .. 8 |-> 0],
      tradePrice                         |-> [i \in 1 .. 10 |-> 0],
      timeTradeHhmmss                    |-> [i \in 1 .. 6 |-> 0],
      clearingData                       |-> ZeroClearingData10,
      ownerData                          |-> ZeroOwnerData10,
      specialTradeIndicator              |-> [i \in 1 .. 1 |-> 0],
      priceType                          |-> [i \in 1 .. 1 |-> 0],
      tradeType                          |-> [i \in 1 .. 1 |-> 0],
      auctionIdOptional                  |-> [i \in 1 .. 6 |-> 0],
      tradeNumber                        |-> [i \in 1 .. 8 |-> 0],
      tradeMemo                          |-> [i \in 1 .. 50 |-> 0],
      originalReferenceId                |-> [i \in 1 .. 8 |-> 0],
      idCodeForTheCounterpartParticipant |-> [i \in 1 .. 4 |-> 0],
      liquidityStatus                    |-> [i \in 1 .. 1 |-> 0],
      strategyGroup                      |-> [i \in 1 .. 2 |-> 0],
      strategyInstrumentId               |-> [i \in 1 .. 4 |-> 0],
      strategyVerbSide                   |-> [i \in 1 .. 1 |-> 0],
      strategyTradeNumber                |-> [i \in 1 .. 8 |-> 0],
      legNumber                          |-> [i \in 1 .. 2 |-> 0],
      counterpartAccountType             |-> [i \in 1 .. 1 |-> 0],
      additionalClientMemo               |-> [i \in 1 .. 16 |-> 0],
      reserved1                          |-> [i \in 1 .. 1 |-> 0],
      reserved4                          |-> [i \in 1 .. 4 |-> 0] ]

(* Leg Execution Cancellation Notice at zero, then each field in turn at the values it is checked at *)
CheckedLegExecutionCancellationNotice ==
    { ZeroLegExecutionCancellationNotice }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.instrumentOptional = one] : one \in Sample(4) }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.referenceId = one] : one \in Sample(8) }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.verbSide = one] : one \in Sample(1) }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.quantityTraded = one] : one \in Sample(8) }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.tradePrice = one] : one \in Sample(10) }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.timeTradeHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.clearingData = one] : one \in CheckedClearingData10 }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.ownerData = one] : one \in CheckedOwnerData10 }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.specialTradeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.priceType = one] : one \in Sample(1) }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.auctionIdOptional = one] : one \in Sample(6) }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.tradeNumber = one] : one \in Sample(8) }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.tradeMemo = one] : one \in Sample(50) }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.originalReferenceId = one] : one \in Sample(8) }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.idCodeForTheCounterpartParticipant = one] : one \in Sample(4) }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.liquidityStatus = one] : one \in Sample(1) }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.strategyGroup = one] : one \in Sample(2) }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.strategyInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.strategyVerbSide = one] : one \in Sample(1) }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.strategyTradeNumber = one] : one \in Sample(8) }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.legNumber = one] : one \in Sample(2) }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.counterpartAccountType = one] : one \in Sample(1) }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.additionalClientMemo = one] : one \in Sample(16) }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.reserved4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Clearing Data: 20 bytes                                                 *)
(***************************************************************************)

ClearingData11 ==
    [ clearingInstruction   : Sample(12),
      accountType           : Sample(1),
      openClose             : Sample(1),
      hedgeSpec             : Sample(1),
      clearingOperationMode : Sample(1),
      clearingDestination   : Sample(4) ]

EncodeClearingData11(message) ==
    message.clearingInstruction
        \o message.accountType
        \o message.openClose
        \o message.hedgeSpec
        \o message.clearingOperationMode
        \o message.clearingDestination

DecodeClearingData11(bytes) ==
    LET clearingInstruction == ReadBytes(bytes, 12) IN IF ~clearingInstruction.ok THEN Fail ELSE
    LET accountType == ReadBytes(clearingInstruction.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET openClose == ReadBytes(accountType.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET hedgeSpec == ReadBytes(openClose.rest, 1) IN IF ~hedgeSpec.ok THEN Fail ELSE
    LET clearingOperationMode == ReadBytes(hedgeSpec.rest, 1) IN IF ~clearingOperationMode.ok THEN Fail ELSE
    LET clearingDestination == ReadBytes(clearingOperationMode.rest, 4) IN IF ~clearingDestination.ok THEN Fail ELSE
    Ok([ clearingInstruction   |-> clearingInstruction.value,
         accountType           |-> accountType.value,
         openClose             |-> openClose.value,
         hedgeSpec             |-> hedgeSpec.value,
         clearingOperationMode |-> clearingOperationMode.value,
         clearingDestination   |-> clearingDestination.value ], clearingDestination.rest)

ZeroClearingData11 ==
    [ clearingInstruction   |-> [i \in 1 .. 12 |-> 0],
      accountType           |-> [i \in 1 .. 1 |-> 0],
      openClose             |-> [i \in 1 .. 1 |-> 0],
      hedgeSpec             |-> [i \in 1 .. 1 |-> 0],
      clearingOperationMode |-> [i \in 1 .. 1 |-> 0],
      clearingDestination   |-> [i \in 1 .. 4 |-> 0] ]

(* Clearing Data at zero, then each field in turn at the values it is checked at *)
CheckedClearingData11 ==
    { ZeroClearingData11 }
        \cup { [ZeroClearingData11 EXCEPT !.clearingInstruction = one] : one \in Sample(12) }
        \cup { [ZeroClearingData11 EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroClearingData11 EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroClearingData11 EXCEPT !.hedgeSpec = one] : one \in Sample(1) }
        \cup { [ZeroClearingData11 EXCEPT !.clearingOperationMode = one] : one \in Sample(1) }
        \cup { [ZeroClearingData11 EXCEPT !.clearingDestination = one] : one \in Sample(4) }

(***************************************************************************)
(* Owner Data: 71 bytes                                                    *)
(***************************************************************************)

OwnerData11 ==
    [ clientOrderId : Sample(20),
      poundSign     : Sample(1),
      memo          : Sample(50) ]

EncodeOwnerData11(message) ==
    message.clientOrderId
        \o message.poundSign
        \o message.memo

DecodeOwnerData11(bytes) ==
    LET clientOrderId == ReadBytes(bytes, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET poundSign == ReadBytes(clientOrderId.rest, 1) IN IF ~poundSign.ok THEN Fail ELSE
    LET memo == ReadBytes(poundSign.rest, 50) IN IF ~memo.ok THEN Fail ELSE
    Ok([ clientOrderId |-> clientOrderId.value,
         poundSign     |-> poundSign.value,
         memo          |-> memo.value ], memo.rest)

ZeroOwnerData11 ==
    [ clientOrderId |-> [i \in 1 .. 20 |-> 0],
      poundSign     |-> [i \in 1 .. 1 |-> 0],
      memo          |-> [i \in 1 .. 50 |-> 0] ]

(* Owner Data at zero, then each field in turn at the values it is checked at *)
CheckedOwnerData11 ==
    { ZeroOwnerData11 }
        \cup { [ZeroOwnerData11 EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroOwnerData11 EXCEPT !.poundSign = one] : one \in Sample(1) }
        \cup { [ZeroOwnerData11 EXCEPT !.memo = one] : one \in Sample(50) }

(***************************************************************************)
(* Order Cancellation Notice By System: 167 bytes                          *)
(***************************************************************************)

OrderCancellationNoticeBySystem ==
    [ group                : Sample(2),
      instrumentOptional   : Sample(4),
      traderId             : Sample(8),
      orderId              : Sample(8),
      status               : Sample(1),
      verbSide             : Sample(1),
      quantity             : Sample(8),
      assignedPrice        : Sample(10),
      clearingData         : ClearingData11,
      ownerData            : OwnerData11,
      originalOrderId      : Sample(8),
      auctionId            : Sample(6),
      additionalClientMemo : Sample(16),
      reserved4            : Sample(4) ]

EncodeOrderCancellationNoticeBySystem(message) ==
    message.group
        \o message.instrumentOptional
        \o message.traderId
        \o message.orderId
        \o message.status
        \o message.verbSide
        \o message.quantity
        \o message.assignedPrice
        \o EncodeClearingData11(message.clearingData)
        \o EncodeOwnerData11(message.ownerData)
        \o message.originalOrderId
        \o message.auctionId
        \o message.additionalClientMemo
        \o message.reserved4

DecodeOrderCancellationNoticeBySystem(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrumentOptional == ReadBytes(group.rest, 4) IN IF ~instrumentOptional.ok THEN Fail ELSE
    LET traderId == ReadBytes(instrumentOptional.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET orderId == ReadBytes(traderId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET status == ReadBytes(orderId.rest, 1) IN IF ~status.ok THEN Fail ELSE
    LET verbSide == ReadBytes(status.rest, 1) IN IF ~verbSide.ok THEN Fail ELSE
    LET quantity == ReadBytes(verbSide.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET assignedPrice == ReadBytes(quantity.rest, 10) IN IF ~assignedPrice.ok THEN Fail ELSE
    LET clearingData == DecodeClearingData11(assignedPrice.rest) IN IF ~clearingData.ok THEN Fail ELSE
    LET ownerData == DecodeOwnerData11(clearingData.rest) IN IF ~ownerData.ok THEN Fail ELSE
    LET originalOrderId == ReadBytes(ownerData.rest, 8) IN IF ~originalOrderId.ok THEN Fail ELSE
    LET auctionId == ReadBytes(originalOrderId.rest, 6) IN IF ~auctionId.ok THEN Fail ELSE
    LET additionalClientMemo == ReadBytes(auctionId.rest, 16) IN IF ~additionalClientMemo.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(additionalClientMemo.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    Ok([ group                |-> group.value,
         instrumentOptional   |-> instrumentOptional.value,
         traderId             |-> traderId.value,
         orderId              |-> orderId.value,
         status               |-> status.value,
         verbSide             |-> verbSide.value,
         quantity             |-> quantity.value,
         assignedPrice        |-> assignedPrice.value,
         clearingData         |-> clearingData.value,
         ownerData            |-> ownerData.value,
         originalOrderId      |-> originalOrderId.value,
         auctionId            |-> auctionId.value,
         additionalClientMemo |-> additionalClientMemo.value,
         reserved4            |-> reserved4.value ], reserved4.rest)

ZeroOrderCancellationNoticeBySystem ==
    [ group                |-> [i \in 1 .. 2 |-> 0],
      instrumentOptional   |-> [i \in 1 .. 4 |-> 0],
      traderId             |-> [i \in 1 .. 8 |-> 0],
      orderId              |-> [i \in 1 .. 8 |-> 0],
      status               |-> [i \in 1 .. 1 |-> 0],
      verbSide             |-> [i \in 1 .. 1 |-> 0],
      quantity             |-> [i \in 1 .. 8 |-> 0],
      assignedPrice        |-> [i \in 1 .. 10 |-> 0],
      clearingData         |-> ZeroClearingData11,
      ownerData            |-> ZeroOwnerData11,
      originalOrderId      |-> [i \in 1 .. 8 |-> 0],
      auctionId            |-> [i \in 1 .. 6 |-> 0],
      additionalClientMemo |-> [i \in 1 .. 16 |-> 0],
      reserved4            |-> [i \in 1 .. 4 |-> 0] ]

(* Order Cancellation Notice By System at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancellationNoticeBySystem ==
    { ZeroOrderCancellationNoticeBySystem }
        \cup { [ZeroOrderCancellationNoticeBySystem EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancellationNoticeBySystem EXCEPT !.instrumentOptional = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancellationNoticeBySystem EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancellationNoticeBySystem EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancellationNoticeBySystem EXCEPT !.status = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancellationNoticeBySystem EXCEPT !.verbSide = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancellationNoticeBySystem EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancellationNoticeBySystem EXCEPT !.assignedPrice = one] : one \in Sample(10) }
        \cup { [ZeroOrderCancellationNoticeBySystem EXCEPT !.clearingData = one] : one \in CheckedClearingData11 }
        \cup { [ZeroOrderCancellationNoticeBySystem EXCEPT !.ownerData = one] : one \in CheckedOwnerData11 }
        \cup { [ZeroOrderCancellationNoticeBySystem EXCEPT !.originalOrderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancellationNoticeBySystem EXCEPT !.auctionId = one] : one \in Sample(6) }
        \cup { [ZeroOrderCancellationNoticeBySystem EXCEPT !.additionalClientMemo = one] : one \in Sample(16) }
        \cup { [ZeroOrderCancellationNoticeBySystem EXCEPT !.reserved4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Exchange Message, selected by Message Type                              *)
(***************************************************************************)

HeartbeatQuestionCode == 21576  \* "TH"
OutOfSequenceCode == 21583  \* "TO"
TechnicalErrorNoticeCode == 21573  \* "TE"
DisconnectionInstructionAcknowledgementCode == 21581  \* "TM"
ConnectionAcknowledgementCode == 21579  \* "TK"
DisconnectionAcknowledgementCode == 21580  \* "TL"
EndOfTransmissionCode == 21588  \* "TT"
ErrorNoticeCode == 17746  \* "ER"
BulkQuoteDataAcknowledgementCode == 19268  \* "KD"
OrderAcknowledgementCode == 19269  \* "KE"
GlobalCancellationConfirmationCode == 19271  \* "KG"
ImprovementOrderAcknowlegmentCode == 19273  \* "KI"
OrderModificationAcknowledgementCode == 19277  \* "KM"
NewComplexOrderInstrumentAcknowledgementCode == 19278  \* "KN"
StandardAcknowledgementCode == 19279  \* "KO"
ComplexOrderAuctionAcknowledgementCode == 19284  \* "KT"
AuctionOrImprovementCancellationAcknowledgementCode == 19289  \* "KY"
OrderCancellationAcknowledgementCode == 19290  \* "KZ"
BulkQuoteAcknowledgementCode == 19521  \* "LA"
TraderStatusCode == 19797  \* "MU"
DirectedOrderCancellationNoticeCode == 20035  \* "NC"
DirectedOrderNoticeCode == 20036  \* "ND"
ExcludedInstrumentNoticeCode == 20037  \* "NE"
GroupStateChangeCode == 20039  \* "NG"
LegExecutionNoticeCode == 20044  \* "NL"
CancellationOfAllQuotesNoticesCode == 20048  \* "NP"
QualityMarketMakerNotificationCode == 20049  \* "NQ"
ExecutionNoticeCode == 20052  \* "NT"
QuoteNoticeCode == 20053  \* "NU"
ExecutionCancellationNoticeCode == 20056  \* "NX"
LegExecutionCancellationNoticeCode == 20057  \* "NY"
OrderCancellationNoticeBySystemCode == 20058  \* "NZ"

ExchangeMessage ==
    [ tag : {HeartbeatQuestionCode}, body : HeartbeatQuestion ]
        \cup [ tag : {OutOfSequenceCode}, body : OutOfSequence ]
        \cup [ tag : {TechnicalErrorNoticeCode}, body : TechnicalErrorNotice ]
        \cup [ tag : {DisconnectionInstructionAcknowledgementCode}, body : DisconnectionInstructionAcknowledgement ]
        \cup [ tag : {ConnectionAcknowledgementCode}, body : ConnectionAcknowledgement ]
        \cup [ tag : {DisconnectionAcknowledgementCode}, body : DisconnectionAcknowledgement ]
        \cup [ tag : {EndOfTransmissionCode}, body : EndOfTransmission ]
        \cup [ tag : {ErrorNoticeCode}, body : ErrorNotice ]
        \cup [ tag : {BulkQuoteDataAcknowledgementCode}, body : BulkQuoteDataAcknowledgement ]
        \cup [ tag : {OrderAcknowledgementCode}, body : OrderAcknowledgement ]
        \cup [ tag : {GlobalCancellationConfirmationCode}, body : GlobalCancellationConfirmation ]
        \cup [ tag : {ImprovementOrderAcknowlegmentCode}, body : ImprovementOrderAcknowlegment ]
        \cup [ tag : {OrderModificationAcknowledgementCode}, body : OrderModificationAcknowledgement ]
        \cup [ tag : {NewComplexOrderInstrumentAcknowledgementCode}, body : NewComplexOrderInstrumentAcknowledgement ]
        \cup [ tag : {StandardAcknowledgementCode}, body : StandardAcknowledgement ]
        \cup [ tag : {ComplexOrderAuctionAcknowledgementCode}, body : ComplexOrderAuctionAcknowledgement ]
        \cup [ tag : {AuctionOrImprovementCancellationAcknowledgementCode}, body : AuctionOrImprovementCancellationAcknowledgement ]
        \cup [ tag : {OrderCancellationAcknowledgementCode}, body : OrderCancellationAcknowledgement ]
        \cup [ tag : {BulkQuoteAcknowledgementCode}, body : BulkQuoteAcknowledgement ]
        \cup [ tag : {TraderStatusCode}, body : TraderStatus ]
        \cup [ tag : {DirectedOrderCancellationNoticeCode}, body : DirectedOrderCancellationNotice ]
        \cup [ tag : {DirectedOrderNoticeCode}, body : DirectedOrderNotice ]
        \cup [ tag : {ExcludedInstrumentNoticeCode}, body : ExcludedInstrumentNotice ]
        \cup [ tag : {GroupStateChangeCode}, body : GroupStateChange ]
        \cup [ tag : {LegExecutionNoticeCode}, body : LegExecutionNotice ]
        \cup [ tag : {CancellationOfAllQuotesNoticesCode}, body : CancellationOfAllQuotesNotices ]
        \cup [ tag : {QualityMarketMakerNotificationCode}, body : QualityMarketMakerNotification ]
        \cup [ tag : {ExecutionNoticeCode}, body : ExecutionNotice ]
        \cup [ tag : {QuoteNoticeCode}, body : QuoteNotice ]
        \cup [ tag : {ExecutionCancellationNoticeCode}, body : ExecutionCancellationNotice ]
        \cup [ tag : {LegExecutionCancellationNoticeCode}, body : LegExecutionCancellationNotice ]
        \cup [ tag : {OrderCancellationNoticeBySystemCode}, body : OrderCancellationNoticeBySystem ]

EncodeExchangeMessage(message) ==
    CASE message.tag = HeartbeatQuestionCode -> EncodeHeartbeatQuestion(message.body)
      [] message.tag = OutOfSequenceCode -> EncodeOutOfSequence(message.body)
      [] message.tag = TechnicalErrorNoticeCode -> EncodeTechnicalErrorNotice(message.body)
      [] message.tag = DisconnectionInstructionAcknowledgementCode -> EncodeDisconnectionInstructionAcknowledgement(message.body)
      [] message.tag = ConnectionAcknowledgementCode -> EncodeConnectionAcknowledgement(message.body)
      [] message.tag = DisconnectionAcknowledgementCode -> EncodeDisconnectionAcknowledgement(message.body)
      [] message.tag = EndOfTransmissionCode -> EncodeEndOfTransmission(message.body)
      [] message.tag = ErrorNoticeCode -> EncodeErrorNotice(message.body)
      [] message.tag = BulkQuoteDataAcknowledgementCode -> EncodeBulkQuoteDataAcknowledgement(message.body)
      [] message.tag = OrderAcknowledgementCode -> EncodeOrderAcknowledgement(message.body)
      [] message.tag = GlobalCancellationConfirmationCode -> EncodeGlobalCancellationConfirmation(message.body)
      [] message.tag = ImprovementOrderAcknowlegmentCode -> EncodeImprovementOrderAcknowlegment(message.body)
      [] message.tag = OrderModificationAcknowledgementCode -> EncodeOrderModificationAcknowledgement(message.body)
      [] message.tag = NewComplexOrderInstrumentAcknowledgementCode -> EncodeNewComplexOrderInstrumentAcknowledgement(message.body)
      [] message.tag = StandardAcknowledgementCode -> EncodeStandardAcknowledgement(message.body)
      [] message.tag = ComplexOrderAuctionAcknowledgementCode -> EncodeComplexOrderAuctionAcknowledgement(message.body)
      [] message.tag = AuctionOrImprovementCancellationAcknowledgementCode -> EncodeAuctionOrImprovementCancellationAcknowledgement(message.body)
      [] message.tag = OrderCancellationAcknowledgementCode -> EncodeOrderCancellationAcknowledgement(message.body)
      [] message.tag = BulkQuoteAcknowledgementCode -> EncodeBulkQuoteAcknowledgement(message.body)
      [] message.tag = TraderStatusCode -> EncodeTraderStatus(message.body)
      [] message.tag = DirectedOrderCancellationNoticeCode -> EncodeDirectedOrderCancellationNotice(message.body)
      [] message.tag = DirectedOrderNoticeCode -> EncodeDirectedOrderNotice(message.body)
      [] message.tag = ExcludedInstrumentNoticeCode -> EncodeExcludedInstrumentNotice(message.body)
      [] message.tag = GroupStateChangeCode -> EncodeGroupStateChange(message.body)
      [] message.tag = LegExecutionNoticeCode -> EncodeLegExecutionNotice(message.body)
      [] message.tag = CancellationOfAllQuotesNoticesCode -> EncodeCancellationOfAllQuotesNotices(message.body)
      [] message.tag = QualityMarketMakerNotificationCode -> EncodeQualityMarketMakerNotification(message.body)
      [] message.tag = ExecutionNoticeCode -> EncodeExecutionNotice(message.body)
      [] message.tag = QuoteNoticeCode -> EncodeQuoteNotice(message.body)
      [] message.tag = ExecutionCancellationNoticeCode -> EncodeExecutionCancellationNotice(message.body)
      [] message.tag = LegExecutionCancellationNoticeCode -> EncodeLegExecutionCancellationNotice(message.body)
      [] message.tag = OrderCancellationNoticeBySystemCode -> EncodeOrderCancellationNoticeBySystem(message.body)

DecodeExchangeMessage(tag, bytes) ==
    LET read ==
            CASE tag = HeartbeatQuestionCode -> DecodeHeartbeatQuestion(bytes)
              [] tag = OutOfSequenceCode -> DecodeOutOfSequence(bytes)
              [] tag = TechnicalErrorNoticeCode -> DecodeTechnicalErrorNotice(bytes)
              [] tag = DisconnectionInstructionAcknowledgementCode -> DecodeDisconnectionInstructionAcknowledgement(bytes)
              [] tag = ConnectionAcknowledgementCode -> DecodeConnectionAcknowledgement(bytes)
              [] tag = DisconnectionAcknowledgementCode -> DecodeDisconnectionAcknowledgement(bytes)
              [] tag = EndOfTransmissionCode -> DecodeEndOfTransmission(bytes)
              [] tag = ErrorNoticeCode -> DecodeErrorNotice(bytes)
              [] tag = BulkQuoteDataAcknowledgementCode -> DecodeBulkQuoteDataAcknowledgement(bytes)
              [] tag = OrderAcknowledgementCode -> DecodeOrderAcknowledgement(bytes)
              [] tag = GlobalCancellationConfirmationCode -> DecodeGlobalCancellationConfirmation(bytes)
              [] tag = ImprovementOrderAcknowlegmentCode -> DecodeImprovementOrderAcknowlegment(bytes)
              [] tag = OrderModificationAcknowledgementCode -> DecodeOrderModificationAcknowledgement(bytes)
              [] tag = NewComplexOrderInstrumentAcknowledgementCode -> DecodeNewComplexOrderInstrumentAcknowledgement(bytes)
              [] tag = StandardAcknowledgementCode -> DecodeStandardAcknowledgement(bytes)
              [] tag = ComplexOrderAuctionAcknowledgementCode -> DecodeComplexOrderAuctionAcknowledgement(bytes)
              [] tag = AuctionOrImprovementCancellationAcknowledgementCode -> DecodeAuctionOrImprovementCancellationAcknowledgement(bytes)
              [] tag = OrderCancellationAcknowledgementCode -> DecodeOrderCancellationAcknowledgement(bytes)
              [] tag = BulkQuoteAcknowledgementCode -> DecodeBulkQuoteAcknowledgement(bytes)
              [] tag = TraderStatusCode -> DecodeTraderStatus(bytes)
              [] tag = DirectedOrderCancellationNoticeCode -> DecodeDirectedOrderCancellationNotice(bytes)
              [] tag = DirectedOrderNoticeCode -> DecodeDirectedOrderNotice(bytes)
              [] tag = ExcludedInstrumentNoticeCode -> DecodeExcludedInstrumentNotice(bytes)
              [] tag = GroupStateChangeCode -> DecodeGroupStateChange(bytes)
              [] tag = LegExecutionNoticeCode -> DecodeLegExecutionNotice(bytes)
              [] tag = CancellationOfAllQuotesNoticesCode -> DecodeCancellationOfAllQuotesNotices(bytes)
              [] tag = QualityMarketMakerNotificationCode -> DecodeQualityMarketMakerNotification(bytes)
              [] tag = ExecutionNoticeCode -> DecodeExecutionNotice(bytes)
              [] tag = QuoteNoticeCode -> DecodeQuoteNotice(bytes)
              [] tag = ExecutionCancellationNoticeCode -> DecodeExecutionCancellationNotice(bytes)
              [] tag = LegExecutionCancellationNoticeCode -> DecodeLegExecutionCancellationNotice(bytes)
              [] tag = OrderCancellationNoticeBySystemCode -> DecodeOrderCancellationNoticeBySystem(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroExchangeMessage == [tag |-> HeartbeatQuestionCode, body |-> ZeroHeartbeatQuestion]

(* Each Exchange Message in turn, at the values the message it names is checked at *)
CheckedExchangeMessage ==
    { [tag |-> HeartbeatQuestionCode, body |-> one] : one \in CheckedHeartbeatQuestion }
        \cup { [tag |-> OutOfSequenceCode, body |-> one] : one \in CheckedOutOfSequence }
        \cup { [tag |-> TechnicalErrorNoticeCode, body |-> one] : one \in CheckedTechnicalErrorNotice }
        \cup { [tag |-> DisconnectionInstructionAcknowledgementCode, body |-> one] : one \in CheckedDisconnectionInstructionAcknowledgement }
        \cup { [tag |-> ConnectionAcknowledgementCode, body |-> one] : one \in CheckedConnectionAcknowledgement }
        \cup { [tag |-> DisconnectionAcknowledgementCode, body |-> one] : one \in CheckedDisconnectionAcknowledgement }
        \cup { [tag |-> EndOfTransmissionCode, body |-> one] : one \in CheckedEndOfTransmission }
        \cup { [tag |-> ErrorNoticeCode, body |-> one] : one \in CheckedErrorNotice }
        \cup { [tag |-> BulkQuoteDataAcknowledgementCode, body |-> one] : one \in CheckedBulkQuoteDataAcknowledgement }
        \cup { [tag |-> OrderAcknowledgementCode, body |-> one] : one \in CheckedOrderAcknowledgement }
        \cup { [tag |-> GlobalCancellationConfirmationCode, body |-> one] : one \in CheckedGlobalCancellationConfirmation }
        \cup { [tag |-> ImprovementOrderAcknowlegmentCode, body |-> one] : one \in CheckedImprovementOrderAcknowlegment }
        \cup { [tag |-> OrderModificationAcknowledgementCode, body |-> one] : one \in CheckedOrderModificationAcknowledgement }
        \cup { [tag |-> NewComplexOrderInstrumentAcknowledgementCode, body |-> one] : one \in CheckedNewComplexOrderInstrumentAcknowledgement }
        \cup { [tag |-> StandardAcknowledgementCode, body |-> one] : one \in CheckedStandardAcknowledgement }
        \cup { [tag |-> ComplexOrderAuctionAcknowledgementCode, body |-> one] : one \in CheckedComplexOrderAuctionAcknowledgement }
        \cup { [tag |-> AuctionOrImprovementCancellationAcknowledgementCode, body |-> one] : one \in CheckedAuctionOrImprovementCancellationAcknowledgement }
        \cup { [tag |-> OrderCancellationAcknowledgementCode, body |-> one] : one \in CheckedOrderCancellationAcknowledgement }
        \cup { [tag |-> BulkQuoteAcknowledgementCode, body |-> one] : one \in CheckedBulkQuoteAcknowledgement }
        \cup { [tag |-> TraderStatusCode, body |-> one] : one \in CheckedTraderStatus }
        \cup { [tag |-> DirectedOrderCancellationNoticeCode, body |-> one] : one \in CheckedDirectedOrderCancellationNotice }
        \cup { [tag |-> DirectedOrderNoticeCode, body |-> one] : one \in CheckedDirectedOrderNotice }
        \cup { [tag |-> ExcludedInstrumentNoticeCode, body |-> one] : one \in CheckedExcludedInstrumentNotice }
        \cup { [tag |-> GroupStateChangeCode, body |-> one] : one \in CheckedGroupStateChange }
        \cup { [tag |-> LegExecutionNoticeCode, body |-> one] : one \in CheckedLegExecutionNotice }
        \cup { [tag |-> CancellationOfAllQuotesNoticesCode, body |-> one] : one \in CheckedCancellationOfAllQuotesNotices }
        \cup { [tag |-> QualityMarketMakerNotificationCode, body |-> one] : one \in CheckedQualityMarketMakerNotification }
        \cup { [tag |-> ExecutionNoticeCode, body |-> one] : one \in CheckedExecutionNotice }
        \cup { [tag |-> QuoteNoticeCode, body |-> one] : one \in CheckedQuoteNotice }
        \cup { [tag |-> ExecutionCancellationNoticeCode, body |-> one] : one \in CheckedExecutionCancellationNotice }
        \cup { [tag |-> LegExecutionCancellationNoticeCode, body |-> one] : one \in CheckedLegExecutionCancellationNotice }
        \cup { [tag |-> OrderCancellationNoticeBySystemCode, body |-> one] : one \in CheckedOrderCancellationNoticeBySystem }

(***************************************************************************)
(* Exchange Packet                                                         *)
(***************************************************************************)

ExchangePacket ==
    [ messageLength     : 0 .. 255,
      messageTimestamp  : Sample(6),
      userSequenceId    : Sample(8),
      exchangeMessageId : Sample(6),
      gapSequenceId     : Sample(2),
      systemSequenceId  : Sample(6),
      exchangeMessage   : ExchangeMessage,
      endOfText         : Sample(1) ]

EncodeExchangePacket(message) ==
    EncodeUIntLE(message.messageLength, 4)
        \o EncodeUIntBE(message.exchangeMessage.tag, 2)
        \o message.messageTimestamp
        \o message.userSequenceId
        \o message.exchangeMessageId
        \o message.gapSequenceId
        \o message.systemSequenceId
        \o EncodeExchangeMessage(message.exchangeMessage)
        \o message.endOfText

DecodeExchangePacket(bytes) ==
    LET messageLength == ReadUIntLE(bytes, 4) IN IF ~messageLength.ok THEN Fail ELSE
    LET messageType == ReadUIntBE(messageLength.rest, 2) IN IF ~messageType.ok THEN Fail ELSE
    LET messageTimestamp == ReadBytes(messageType.rest, 6) IN IF ~messageTimestamp.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(messageTimestamp.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    LET exchangeMessageId == ReadBytes(userSequenceId.rest, 6) IN IF ~exchangeMessageId.ok THEN Fail ELSE
    LET gapSequenceId == ReadBytes(exchangeMessageId.rest, 2) IN IF ~gapSequenceId.ok THEN Fail ELSE
    LET systemSequenceId == ReadBytes(gapSequenceId.rest, 6) IN IF ~systemSequenceId.ok THEN Fail ELSE
    LET exchangeMessage == DecodeExchangeMessage(messageType.value, systemSequenceId.rest) IN IF ~exchangeMessage.ok THEN Fail ELSE
    LET endOfText == ReadBytes(exchangeMessage.rest, 1) IN IF ~endOfText.ok THEN Fail ELSE
    Ok([ messageLength     |-> messageLength.value,
         messageTimestamp  |-> messageTimestamp.value,
         userSequenceId    |-> userSequenceId.value,
         exchangeMessageId |-> exchangeMessageId.value,
         gapSequenceId     |-> gapSequenceId.value,
         systemSequenceId  |-> systemSequenceId.value,
         exchangeMessage   |-> exchangeMessage.value,
         endOfText         |-> endOfText.value ], endOfText.rest)

ZeroExchangePacket ==
    [ messageLength     |-> 0,
      messageTimestamp  |-> [i \in 1 .. 6 |-> 0],
      userSequenceId    |-> [i \in 1 .. 8 |-> 0],
      exchangeMessageId |-> [i \in 1 .. 6 |-> 0],
      gapSequenceId     |-> [i \in 1 .. 2 |-> 0],
      systemSequenceId  |-> [i \in 1 .. 6 |-> 0],
      exchangeMessage   |-> ZeroExchangeMessage,
      endOfText         |-> [i \in 1 .. 1 |-> 0] ]

(* Exchange Packet at zero, then each field in turn at the values it is checked at *)
CheckedExchangePacket ==
    { ZeroExchangePacket }
        \cup { [ZeroExchangePacket EXCEPT !.messageLength = one] : one \in {0, 1, 255} }
        \cup { [ZeroExchangePacket EXCEPT !.messageTimestamp = one] : one \in Sample(6) }
        \cup { [ZeroExchangePacket EXCEPT !.userSequenceId = one] : one \in Sample(8) }
        \cup { [ZeroExchangePacket EXCEPT !.exchangeMessageId = one] : one \in Sample(6) }
        \cup { [ZeroExchangePacket EXCEPT !.gapSequenceId = one] : one \in Sample(2) }
        \cup { [ZeroExchangePacket EXCEPT !.systemSequenceId = one] : one \in Sample(6) }
        \cup { [ZeroExchangePacket EXCEPT !.exchangeMessage = one] : one \in CheckedExchangeMessage }
        \cup { [ZeroExchangePacket EXCEPT !.endOfText = one] : one \in Sample(1) }

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

(* Every Heartbeat Question decodes back to what was encoded, and leaves nothing over *)
RoundTripHeartbeatQuestion ==
    \A message \in CheckedHeartbeatQuestion :
        LET read == DecodeHeartbeatQuestion(EncodeHeartbeatQuestion(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Out Of Sequence decodes back to what was encoded, and leaves nothing over *)
RoundTripOutOfSequence ==
    \A message \in CheckedOutOfSequence :
        LET read == DecodeOutOfSequence(EncodeOutOfSequence(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Technical Error Notice decodes back to what was encoded, and leaves nothing over *)
RoundTripTechnicalErrorNotice ==
    \A message \in CheckedTechnicalErrorNotice :
        LET read == DecodeTechnicalErrorNotice(EncodeTechnicalErrorNotice(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Disconnection Instruction Acknowledgement decodes back to what was encoded, and leaves nothing over *)
RoundTripDisconnectionInstructionAcknowledgement ==
    \A message \in CheckedDisconnectionInstructionAcknowledgement :
        LET read == DecodeDisconnectionInstructionAcknowledgement(EncodeDisconnectionInstructionAcknowledgement(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Connection Acknowledgement decodes back to what was encoded, and leaves nothing over *)
RoundTripConnectionAcknowledgement ==
    \A message \in CheckedConnectionAcknowledgement :
        LET read == DecodeConnectionAcknowledgement(EncodeConnectionAcknowledgement(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Disconnection Acknowledgement decodes back to what was encoded, and leaves nothing over *)
RoundTripDisconnectionAcknowledgement ==
    \A message \in CheckedDisconnectionAcknowledgement :
        LET read == DecodeDisconnectionAcknowledgement(EncodeDisconnectionAcknowledgement(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Transmission decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfTransmission ==
    \A message \in CheckedEndOfTransmission :
        LET read == DecodeEndOfTransmission(EncodeEndOfTransmission(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Error Notice decodes back to what was encoded, and leaves nothing over *)
RoundTripErrorNotice ==
    \A message \in CheckedErrorNotice :
        LET read == DecodeErrorNotice(EncodeErrorNotice(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulk Quote Data Acknowledgement decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkQuoteDataAcknowledgement ==
    \A message \in CheckedBulkQuoteDataAcknowledgement :
        LET read == DecodeBulkQuoteDataAcknowledgement(EncodeBulkQuoteDataAcknowledgement(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Clearing Data decodes back to what was encoded, and leaves nothing over *)
RoundTripClearingData ==
    \A message \in CheckedClearingData :
        LET read == DecodeClearingData(EncodeClearingData(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Owner Data decodes back to what was encoded, and leaves nothing over *)
RoundTripOwnerData ==
    \A message \in CheckedOwnerData :
        LET read == DecodeOwnerData(EncodeOwnerData(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Acknowledgement decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderAcknowledgement ==
    \A message \in CheckedOrderAcknowledgement :
        LET read == DecodeOrderAcknowledgement(EncodeOrderAcknowledgement(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Global Cancellation Confirmation decodes back to what was encoded, and leaves nothing over *)
RoundTripGlobalCancellationConfirmation ==
    \A message \in CheckedGlobalCancellationConfirmation :
        LET read == DecodeGlobalCancellationConfirmation(EncodeGlobalCancellationConfirmation(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Clearing Data decodes back to what was encoded, and leaves nothing over *)
RoundTripClearingData2 ==
    \A message \in CheckedClearingData2 :
        LET read == DecodeClearingData2(EncodeClearingData2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Owner Data decodes back to what was encoded, and leaves nothing over *)
RoundTripOwnerData2 ==
    \A message \in CheckedOwnerData2 :
        LET read == DecodeOwnerData2(EncodeOwnerData2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Improvement Order Acknowlegment decodes back to what was encoded, and leaves nothing over *)
RoundTripImprovementOrderAcknowlegment ==
    \A message \in CheckedImprovementOrderAcknowlegment :
        LET read == DecodeImprovementOrderAcknowlegment(EncodeImprovementOrderAcknowlegment(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Clearing Data decodes back to what was encoded, and leaves nothing over *)
RoundTripClearingData3 ==
    \A message \in CheckedClearingData3 :
        LET read == DecodeClearingData3(EncodeClearingData3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Owner Data decodes back to what was encoded, and leaves nothing over *)
RoundTripOwnerData3 ==
    \A message \in CheckedOwnerData3 :
        LET read == DecodeOwnerData3(EncodeOwnerData3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Modification Acknowledgement decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderModificationAcknowledgement ==
    \A message \in CheckedOrderModificationAcknowledgement :
        LET read == DecodeOrderModificationAcknowledgement(EncodeOrderModificationAcknowledgement(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Complex Order Instrument Acknowledgement Occurrence decodes back to what was encoded, and leaves nothing over *)
RoundTripNewComplexOrderInstrumentAcknowledgementOccurrence ==
    \A message \in CheckedNewComplexOrderInstrumentAcknowledgementOccurrence :
        LET read == DecodeNewComplexOrderInstrumentAcknowledgementOccurrence(EncodeNewComplexOrderInstrumentAcknowledgementOccurrence(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Complex Order Instrument Acknowledgement decodes back to what was encoded, and leaves nothing over *)
RoundTripNewComplexOrderInstrumentAcknowledgement ==
    \A message \in CheckedNewComplexOrderInstrumentAcknowledgement :
        LET read == DecodeNewComplexOrderInstrumentAcknowledgement(EncodeNewComplexOrderInstrumentAcknowledgement(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Standard Acknowledgement decodes back to what was encoded, and leaves nothing over *)
RoundTripStandardAcknowledgement ==
    \A message \in CheckedStandardAcknowledgement :
        LET read == DecodeStandardAcknowledgement(EncodeStandardAcknowledgement(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Clearing Data decodes back to what was encoded, and leaves nothing over *)
RoundTripClearingData4 ==
    \A message \in CheckedClearingData4 :
        LET read == DecodeClearingData4(EncodeClearingData4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Owner Data decodes back to what was encoded, and leaves nothing over *)
RoundTripOwnerData4 ==
    \A message \in CheckedOwnerData4 :
        LET read == DecodeOwnerData4(EncodeOwnerData4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Order Auction Acknowledgement decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexOrderAuctionAcknowledgement ==
    \A message \in CheckedComplexOrderAuctionAcknowledgement :
        LET read == DecodeComplexOrderAuctionAcknowledgement(EncodeComplexOrderAuctionAcknowledgement(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Clearing Data decodes back to what was encoded, and leaves nothing over *)
RoundTripClearingData5 ==
    \A message \in CheckedClearingData5 :
        LET read == DecodeClearingData5(EncodeClearingData5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Owner Data decodes back to what was encoded, and leaves nothing over *)
RoundTripOwnerData5 ==
    \A message \in CheckedOwnerData5 :
        LET read == DecodeOwnerData5(EncodeOwnerData5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Or Improvement Cancellation Acknowledgement decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionOrImprovementCancellationAcknowledgement ==
    \A message \in CheckedAuctionOrImprovementCancellationAcknowledgement :
        LET read == DecodeAuctionOrImprovementCancellationAcknowledgement(EncodeAuctionOrImprovementCancellationAcknowledgement(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Clearing Data decodes back to what was encoded, and leaves nothing over *)
RoundTripClearingData6 ==
    \A message \in CheckedClearingData6 :
        LET read == DecodeClearingData6(EncodeClearingData6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Owner Data decodes back to what was encoded, and leaves nothing over *)
RoundTripOwnerData6 ==
    \A message \in CheckedOwnerData6 :
        LET read == DecodeOwnerData6(EncodeOwnerData6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancellation Acknowledgement decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancellationAcknowledgement ==
    \A message \in CheckedOrderCancellationAcknowledgement :
        LET read == DecodeOrderCancellationAcknowledgement(EncodeOrderCancellationAcknowledgement(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulk Quote Acknowledgement Occurrence decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkQuoteAcknowledgementOccurrence ==
    \A message \in CheckedBulkQuoteAcknowledgementOccurrence :
        LET read == DecodeBulkQuoteAcknowledgementOccurrence(EncodeBulkQuoteAcknowledgementOccurrence(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulk Quote Acknowledgement decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkQuoteAcknowledgement ==
    \A message \in CheckedBulkQuoteAcknowledgement :
        LET read == DecodeBulkQuoteAcknowledgement(EncodeBulkQuoteAcknowledgement(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trader Status decodes back to what was encoded, and leaves nothing over *)
RoundTripTraderStatus ==
    \A message \in CheckedTraderStatus :
        LET read == DecodeTraderStatus(EncodeTraderStatus(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Directed Order Cancellation Notice decodes back to what was encoded, and leaves nothing over *)
RoundTripDirectedOrderCancellationNotice ==
    \A message \in CheckedDirectedOrderCancellationNotice :
        LET read == DecodeDirectedOrderCancellationNotice(EncodeDirectedOrderCancellationNotice(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Directed Order Notice decodes back to what was encoded, and leaves nothing over *)
RoundTripDirectedOrderNotice ==
    \A message \in CheckedDirectedOrderNotice :
        LET read == DecodeDirectedOrderNotice(EncodeDirectedOrderNotice(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Excluded Instrument Notice decodes back to what was encoded, and leaves nothing over *)
RoundTripExcludedInstrumentNotice ==
    \A message \in CheckedExcludedInstrumentNotice :
        LET read == DecodeExcludedInstrumentNotice(EncodeExcludedInstrumentNotice(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Group State Change decodes back to what was encoded, and leaves nothing over *)
RoundTripGroupStateChange ==
    \A message \in CheckedGroupStateChange :
        LET read == DecodeGroupStateChange(EncodeGroupStateChange(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Clearing Data decodes back to what was encoded, and leaves nothing over *)
RoundTripClearingData7 ==
    \A message \in CheckedClearingData7 :
        LET read == DecodeClearingData7(EncodeClearingData7(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Owner Data decodes back to what was encoded, and leaves nothing over *)
RoundTripOwnerData7 ==
    \A message \in CheckedOwnerData7 :
        LET read == DecodeOwnerData7(EncodeOwnerData7(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Leg Execution Notice decodes back to what was encoded, and leaves nothing over *)
RoundTripLegExecutionNotice ==
    \A message \in CheckedLegExecutionNotice :
        LET read == DecodeLegExecutionNotice(EncodeLegExecutionNotice(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancellation Of All Quotes Notices decodes back to what was encoded, and leaves nothing over *)
RoundTripCancellationOfAllQuotesNotices ==
    \A message \in CheckedCancellationOfAllQuotesNotices :
        LET read == DecodeCancellationOfAllQuotesNotices(EncodeCancellationOfAllQuotesNotices(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quality Market Maker Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripQualityMarketMakerNotification ==
    \A message \in CheckedQualityMarketMakerNotification :
        LET read == DecodeQualityMarketMakerNotification(EncodeQualityMarketMakerNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Clearing Data decodes back to what was encoded, and leaves nothing over *)
RoundTripClearingData8 ==
    \A message \in CheckedClearingData8 :
        LET read == DecodeClearingData8(EncodeClearingData8(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Owner Data decodes back to what was encoded, and leaves nothing over *)
RoundTripOwnerData8 ==
    \A message \in CheckedOwnerData8 :
        LET read == DecodeOwnerData8(EncodeOwnerData8(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Notice decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionNotice ==
    \A message \in CheckedExecutionNotice :
        LET read == DecodeExecutionNotice(EncodeExecutionNotice(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Notice decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteNotice ==
    \A message \in CheckedQuoteNotice :
        LET read == DecodeQuoteNotice(EncodeQuoteNotice(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Clearing Data decodes back to what was encoded, and leaves nothing over *)
RoundTripClearingData9 ==
    \A message \in CheckedClearingData9 :
        LET read == DecodeClearingData9(EncodeClearingData9(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Owner Data decodes back to what was encoded, and leaves nothing over *)
RoundTripOwnerData9 ==
    \A message \in CheckedOwnerData9 :
        LET read == DecodeOwnerData9(EncodeOwnerData9(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Cancellation Notice decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionCancellationNotice ==
    \A message \in CheckedExecutionCancellationNotice :
        LET read == DecodeExecutionCancellationNotice(EncodeExecutionCancellationNotice(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Clearing Data decodes back to what was encoded, and leaves nothing over *)
RoundTripClearingData10 ==
    \A message \in CheckedClearingData10 :
        LET read == DecodeClearingData10(EncodeClearingData10(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Owner Data decodes back to what was encoded, and leaves nothing over *)
RoundTripOwnerData10 ==
    \A message \in CheckedOwnerData10 :
        LET read == DecodeOwnerData10(EncodeOwnerData10(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Leg Execution Cancellation Notice decodes back to what was encoded, and leaves nothing over *)
RoundTripLegExecutionCancellationNotice ==
    \A message \in CheckedLegExecutionCancellationNotice :
        LET read == DecodeLegExecutionCancellationNotice(EncodeLegExecutionCancellationNotice(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Clearing Data decodes back to what was encoded, and leaves nothing over *)
RoundTripClearingData11 ==
    \A message \in CheckedClearingData11 :
        LET read == DecodeClearingData11(EncodeClearingData11(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Owner Data decodes back to what was encoded, and leaves nothing over *)
RoundTripOwnerData11 ==
    \A message \in CheckedOwnerData11 :
        LET read == DecodeOwnerData11(EncodeOwnerData11(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancellation Notice By System decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancellationNoticeBySystem ==
    \A message \in CheckedOrderCancellationNoticeBySystem :
        LET read == DecodeOrderCancellationNoticeBySystem(EncodeOrderCancellationNoticeBySystem(message))
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

(* A Exchange Message is selected by the Message Type it is written under *)
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
