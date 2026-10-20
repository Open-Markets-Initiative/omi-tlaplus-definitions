----------------- MODULE Mx_SolaOrderEntry_v1_21_Exchange ------------------
(***************************************************************************)
(* TMX Group Sola Order Entry v1.21                                        *)
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
(* Note: Alignment Padding pads to a 4 byte boundary: it is read as the    *)
(* bytes left to the end of the frame, and the frame's length is trusted   *)
(* to keep that boundary.                                                  *)
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

(* The integer a text protocol writes as the characters of itself: a count of one is *)
(* the character "1", which is the byte 49. Read by its digits, and written back *)
(* zero filled to the width the field states, which is how such a field is filled. *)
Digit == 48 .. 57

RECURSIVE DecodeDigits(_)
DecodeDigits(bytes) ==
    IF bytes = << >>
    THEN 0
    ELSE DecodeDigits(SubSeq(bytes, 1, Len(bytes) - 1)) * 10 + (bytes[Len(bytes)] - 48)

RECURSIVE EncodeDigits(_, _)
EncodeDigits(value, width) ==
    IF width = 0
    THEN << >>
    ELSE EncodeDigits(value \div 10, width - 1) \o <<48 + (value % 10)>>

(* A field written as digits that holds anything else is no number, so it is not read: *)
(* the value would not be what the bytes say, and would not write back as them. *)
ReadDigits(bytes, width) ==
    IF Len(bytes) < width \/ \E i \in 1 .. width : bytes[i] \notin Digit
    THEN Fail
    ELSE Ok(DecodeDigits(SubSeq(bytes, 1, width)), SubSeq(bytes, width + 1, Len(bytes)))

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
(* Heartbeat Question: 20 bytes                                            *)
(***************************************************************************)

HeartbeatQuestion ==
    [ userSequenceIdFirstUserSequenceIdForNextcurrentHeartbeatPeriod : Sample(8),
      lastExchangeMessageIdSentToParticipant                         : Sample(6),
      tradingEngineTimestampLocalHhmmss                              : Sample(6) ]

EncodeHeartbeatQuestion(message) ==
    message.userSequenceIdFirstUserSequenceIdForNextcurrentHeartbeatPeriod
        \o message.lastExchangeMessageIdSentToParticipant
        \o message.tradingEngineTimestampLocalHhmmss

DecodeHeartbeatQuestion(bytes) ==
    LET userSequenceIdFirstUserSequenceIdForNextcurrentHeartbeatPeriod == ReadBytes(bytes, 8) IN IF ~userSequenceIdFirstUserSequenceIdForNextcurrentHeartbeatPeriod.ok THEN Fail ELSE
    LET lastExchangeMessageIdSentToParticipant == ReadBytes(userSequenceIdFirstUserSequenceIdForNextcurrentHeartbeatPeriod.rest, 6) IN IF ~lastExchangeMessageIdSentToParticipant.ok THEN Fail ELSE
    LET tradingEngineTimestampLocalHhmmss == ReadBytes(lastExchangeMessageIdSentToParticipant.rest, 6) IN IF ~tradingEngineTimestampLocalHhmmss.ok THEN Fail ELSE
    Ok([ userSequenceIdFirstUserSequenceIdForNextcurrentHeartbeatPeriod |-> userSequenceIdFirstUserSequenceIdForNextcurrentHeartbeatPeriod.value,
         lastExchangeMessageIdSentToParticipant                         |-> lastExchangeMessageIdSentToParticipant.value,
         tradingEngineTimestampLocalHhmmss                              |-> tradingEngineTimestampLocalHhmmss.value ], tradingEngineTimestampLocalHhmmss.rest)

ZeroHeartbeatQuestion ==
    [ userSequenceIdFirstUserSequenceIdForNextcurrentHeartbeatPeriod |-> [i \in 1 .. 8 |-> 0],
      lastExchangeMessageIdSentToParticipant                         |-> [i \in 1 .. 6 |-> 0],
      tradingEngineTimestampLocalHhmmss                              |-> [i \in 1 .. 6 |-> 0] ]

(* Heartbeat Question at zero, then each field in turn at the values it is checked at *)
CheckedHeartbeatQuestion ==
    { ZeroHeartbeatQuestion }
        \cup { [ZeroHeartbeatQuestion EXCEPT !.userSequenceIdFirstUserSequenceIdForNextcurrentHeartbeatPeriod = one] : one \in Sample(8) }
        \cup { [ZeroHeartbeatQuestion EXCEPT !.lastExchangeMessageIdSentToParticipant = one] : one \in Sample(6) }
        \cup { [ZeroHeartbeatQuestion EXCEPT !.tradingEngineTimestampLocalHhmmss = one] : one \in Sample(6) }

(***************************************************************************)
(* Out Of Sequence: 22 bytes                                               *)
(***************************************************************************)

OutOfSequence ==
    [ receivedUserSequenceId          : Sample(8),
      expectedLastUserSequenceId      : Sample(8),
      userMessageTimestampLocalHhmmss : Sample(6) ]

EncodeOutOfSequence(message) ==
    message.receivedUserSequenceId
        \o message.expectedLastUserSequenceId
        \o message.userMessageTimestampLocalHhmmss

DecodeOutOfSequence(bytes) ==
    LET receivedUserSequenceId == ReadBytes(bytes, 8) IN IF ~receivedUserSequenceId.ok THEN Fail ELSE
    LET expectedLastUserSequenceId == ReadBytes(receivedUserSequenceId.rest, 8) IN IF ~expectedLastUserSequenceId.ok THEN Fail ELSE
    LET userMessageTimestampLocalHhmmss == ReadBytes(expectedLastUserSequenceId.rest, 6) IN IF ~userMessageTimestampLocalHhmmss.ok THEN Fail ELSE
    Ok([ receivedUserSequenceId          |-> receivedUserSequenceId.value,
         expectedLastUserSequenceId      |-> expectedLastUserSequenceId.value,
         userMessageTimestampLocalHhmmss |-> userMessageTimestampLocalHhmmss.value ], userMessageTimestampLocalHhmmss.rest)

ZeroOutOfSequence ==
    [ receivedUserSequenceId          |-> [i \in 1 .. 8 |-> 0],
      expectedLastUserSequenceId      |-> [i \in 1 .. 8 |-> 0],
      userMessageTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0] ]

(* Out Of Sequence at zero, then each field in turn at the values it is checked at *)
CheckedOutOfSequence ==
    { ZeroOutOfSequence }
        \cup { [ZeroOutOfSequence EXCEPT !.receivedUserSequenceId = one] : one \in Sample(8) }
        \cup { [ZeroOutOfSequence EXCEPT !.expectedLastUserSequenceId = one] : one \in Sample(8) }
        \cup { [ZeroOutOfSequence EXCEPT !.userMessageTimestampLocalHhmmss = one] : one \in Sample(6) }

(***************************************************************************)
(* Technical Error Notice: 218 bytes                                       *)
(***************************************************************************)

TechnicalErrorNotice ==
    [ receivedMessageType                         : Sample(2),
      precedingUserSequenceIdReceivedZeroesIfNone : Sample(8),
      errorCode                                   : Sample(4),
      errorPosition                               : Sample(4),
      errorMessage                                : Sample(100),
      startOfMessageInError                       : Sample(100) ]

EncodeTechnicalErrorNotice(message) ==
    message.receivedMessageType
        \o message.precedingUserSequenceIdReceivedZeroesIfNone
        \o message.errorCode
        \o message.errorPosition
        \o message.errorMessage
        \o message.startOfMessageInError

DecodeTechnicalErrorNotice(bytes) ==
    LET receivedMessageType == ReadBytes(bytes, 2) IN IF ~receivedMessageType.ok THEN Fail ELSE
    LET precedingUserSequenceIdReceivedZeroesIfNone == ReadBytes(receivedMessageType.rest, 8) IN IF ~precedingUserSequenceIdReceivedZeroesIfNone.ok THEN Fail ELSE
    LET errorCode == ReadBytes(precedingUserSequenceIdReceivedZeroesIfNone.rest, 4) IN IF ~errorCode.ok THEN Fail ELSE
    LET errorPosition == ReadBytes(errorCode.rest, 4) IN IF ~errorPosition.ok THEN Fail ELSE
    LET errorMessage == ReadBytes(errorPosition.rest, 100) IN IF ~errorMessage.ok THEN Fail ELSE
    LET startOfMessageInError == ReadBytes(errorMessage.rest, 100) IN IF ~startOfMessageInError.ok THEN Fail ELSE
    Ok([ receivedMessageType                         |-> receivedMessageType.value,
         precedingUserSequenceIdReceivedZeroesIfNone |-> precedingUserSequenceIdReceivedZeroesIfNone.value,
         errorCode                                   |-> errorCode.value,
         errorPosition                               |-> errorPosition.value,
         errorMessage                                |-> errorMessage.value,
         startOfMessageInError                       |-> startOfMessageInError.value ], startOfMessageInError.rest)

ZeroTechnicalErrorNotice ==
    [ receivedMessageType                         |-> [i \in 1 .. 2 |-> 0],
      precedingUserSequenceIdReceivedZeroesIfNone |-> [i \in 1 .. 8 |-> 0],
      errorCode                                   |-> [i \in 1 .. 4 |-> 0],
      errorPosition                               |-> [i \in 1 .. 4 |-> 0],
      errorMessage                                |-> [i \in 1 .. 100 |-> 0],
      startOfMessageInError                       |-> [i \in 1 .. 100 |-> 0] ]

(* Technical Error Notice at zero, then each field in turn at the values it is checked at *)
CheckedTechnicalErrorNotice ==
    { ZeroTechnicalErrorNotice }
        \cup { [ZeroTechnicalErrorNotice EXCEPT !.receivedMessageType = one] : one \in Sample(2) }
        \cup { [ZeroTechnicalErrorNotice EXCEPT !.precedingUserSequenceIdReceivedZeroesIfNone = one] : one \in Sample(8) }
        \cup { [ZeroTechnicalErrorNotice EXCEPT !.errorCode = one] : one \in Sample(4) }
        \cup { [ZeroTechnicalErrorNotice EXCEPT !.errorPosition = one] : one \in Sample(4) }
        \cup { [ZeroTechnicalErrorNotice EXCEPT !.errorMessage = one] : one \in Sample(100) }
        \cup { [ZeroTechnicalErrorNotice EXCEPT !.startOfMessageInError = one] : one \in Sample(100) }

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
    [ endedSessionId                                                                                       : Sample(4),
      lastUserSequenceIdReceivedIfNoBusinessMessageHasBeenReceivedOnThisConnectionThisFieldIsEqualToZeroes : Sample(8),
      tradingEngineTimestampLocalHhmmss                                                                    : Sample(6) ]

EncodeEndOfTransmission(message) ==
    message.endedSessionId
        \o message.lastUserSequenceIdReceivedIfNoBusinessMessageHasBeenReceivedOnThisConnectionThisFieldIsEqualToZeroes
        \o message.tradingEngineTimestampLocalHhmmss

DecodeEndOfTransmission(bytes) ==
    LET endedSessionId == ReadBytes(bytes, 4) IN IF ~endedSessionId.ok THEN Fail ELSE
    LET lastUserSequenceIdReceivedIfNoBusinessMessageHasBeenReceivedOnThisConnectionThisFieldIsEqualToZeroes == ReadBytes(endedSessionId.rest, 8) IN IF ~lastUserSequenceIdReceivedIfNoBusinessMessageHasBeenReceivedOnThisConnectionThisFieldIsEqualToZeroes.ok THEN Fail ELSE
    LET tradingEngineTimestampLocalHhmmss == ReadBytes(lastUserSequenceIdReceivedIfNoBusinessMessageHasBeenReceivedOnThisConnectionThisFieldIsEqualToZeroes.rest, 6) IN IF ~tradingEngineTimestampLocalHhmmss.ok THEN Fail ELSE
    Ok([ endedSessionId                                                                                       |-> endedSessionId.value,
         lastUserSequenceIdReceivedIfNoBusinessMessageHasBeenReceivedOnThisConnectionThisFieldIsEqualToZeroes |-> lastUserSequenceIdReceivedIfNoBusinessMessageHasBeenReceivedOnThisConnectionThisFieldIsEqualToZeroes.value,
         tradingEngineTimestampLocalHhmmss                                                                    |-> tradingEngineTimestampLocalHhmmss.value ], tradingEngineTimestampLocalHhmmss.rest)

ZeroEndOfTransmission ==
    [ endedSessionId                                                                                       |-> [i \in 1 .. 4 |-> 0],
      lastUserSequenceIdReceivedIfNoBusinessMessageHasBeenReceivedOnThisConnectionThisFieldIsEqualToZeroes |-> [i \in 1 .. 8 |-> 0],
      tradingEngineTimestampLocalHhmmss                                                                    |-> [i \in 1 .. 6 |-> 0] ]

(* End Of Transmission at zero, then each field in turn at the values it is checked at *)
CheckedEndOfTransmission ==
    { ZeroEndOfTransmission }
        \cup { [ZeroEndOfTransmission EXCEPT !.endedSessionId = one] : one \in Sample(4) }
        \cup { [ZeroEndOfTransmission EXCEPT !.lastUserSequenceIdReceivedIfNoBusinessMessageHasBeenReceivedOnThisConnectionThisFieldIsEqualToZeroes = one] : one \in Sample(8) }
        \cup { [ZeroEndOfTransmission EXCEPT !.tradingEngineTimestampLocalHhmmss = one] : one \in Sample(6) }

(***************************************************************************)
(* Outgoing Messages Header: 22 bytes                                      *)
(***************************************************************************)

OutgoingMessagesHeader ==
    [ tradingEngineTimestampLocalHhmmss : Sample(6),
      userSequenceId                    : Sample(8),
      exchangeMessageId                 : Sample(6),
      gapSequenceId                     : Sample(2) ]

EncodeOutgoingMessagesHeader(message) ==
    message.tradingEngineTimestampLocalHhmmss
        \o message.userSequenceId
        \o message.exchangeMessageId
        \o message.gapSequenceId

DecodeOutgoingMessagesHeader(bytes) ==
    LET tradingEngineTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~tradingEngineTimestampLocalHhmmss.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(tradingEngineTimestampLocalHhmmss.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    LET exchangeMessageId == ReadBytes(userSequenceId.rest, 6) IN IF ~exchangeMessageId.ok THEN Fail ELSE
    LET gapSequenceId == ReadBytes(exchangeMessageId.rest, 2) IN IF ~gapSequenceId.ok THEN Fail ELSE
    Ok([ tradingEngineTimestampLocalHhmmss |-> tradingEngineTimestampLocalHhmmss.value,
         userSequenceId                    |-> userSequenceId.value,
         exchangeMessageId                 |-> exchangeMessageId.value,
         gapSequenceId                     |-> gapSequenceId.value ], gapSequenceId.rest)

ZeroOutgoingMessagesHeader ==
    [ tradingEngineTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      userSequenceId                    |-> [i \in 1 .. 8 |-> 0],
      exchangeMessageId                 |-> [i \in 1 .. 6 |-> 0],
      gapSequenceId                     |-> [i \in 1 .. 2 |-> 0] ]

(* Outgoing Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedOutgoingMessagesHeader ==
    { ZeroOutgoingMessagesHeader }
        \cup { [ZeroOutgoingMessagesHeader EXCEPT !.tradingEngineTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroOutgoingMessagesHeader EXCEPT !.userSequenceId = one] : one \in Sample(8) }
        \cup { [ZeroOutgoingMessagesHeader EXCEPT !.exchangeMessageId = one] : one \in Sample(6) }
        \cup { [ZeroOutgoingMessagesHeader EXCEPT !.gapSequenceId = one] : one \in Sample(2) }

(***************************************************************************)
(* Clearing Data: 20 bytes                                                 *)
(***************************************************************************)

ClearingData ==
    [ clearingInstruction : Sample(12),
      accountType         : Sample(1),
      openClose           : Sample(1),
      hedgeSpec           : Sample(1),
      filler5             : Sample(5) ]

EncodeClearingData(message) ==
    message.clearingInstruction
        \o message.accountType
        \o message.openClose
        \o message.hedgeSpec
        \o message.filler5

DecodeClearingData(bytes) ==
    LET clearingInstruction == ReadBytes(bytes, 12) IN IF ~clearingInstruction.ok THEN Fail ELSE
    LET accountType == ReadBytes(clearingInstruction.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET openClose == ReadBytes(accountType.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET hedgeSpec == ReadBytes(openClose.rest, 1) IN IF ~hedgeSpec.ok THEN Fail ELSE
    LET filler5 == ReadBytes(hedgeSpec.rest, 5) IN IF ~filler5.ok THEN Fail ELSE
    Ok([ clearingInstruction |-> clearingInstruction.value,
         accountType         |-> accountType.value,
         openClose           |-> openClose.value,
         hedgeSpec           |-> hedgeSpec.value,
         filler5             |-> filler5.value ], filler5.rest)

ZeroClearingData ==
    [ clearingInstruction |-> [i \in 1 .. 12 |-> 0],
      accountType         |-> [i \in 1 .. 1 |-> 0],
      openClose           |-> [i \in 1 .. 1 |-> 0],
      hedgeSpec           |-> [i \in 1 .. 1 |-> 0],
      filler5             |-> [i \in 1 .. 5 |-> 0] ]

(* Clearing Data at zero, then each field in turn at the values it is checked at *)
CheckedClearingData ==
    { ZeroClearingData }
        \cup { [ZeroClearingData EXCEPT !.clearingInstruction = one] : one \in Sample(12) }
        \cup { [ZeroClearingData EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroClearingData EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroClearingData EXCEPT !.hedgeSpec = one] : one \in Sample(1) }
        \cup { [ZeroClearingData EXCEPT !.filler5 = one] : one \in Sample(5) }

(***************************************************************************)
(* Owner Data: 50 bytes                                                    *)
(***************************************************************************)

OwnerData ==
    [ memo : Sample(50) ]

EncodeOwnerData(message) ==
    message.memo

DecodeOwnerData(bytes) ==
    LET memo == ReadBytes(bytes, 50) IN IF ~memo.ok THEN Fail ELSE
    Ok([ memo |-> memo.value ], memo.rest)

ZeroOwnerData ==
    [ memo |-> [i \in 1 .. 50 |-> 0] ]

(* Owner Data at zero, then each field in turn at the values it is checked at *)
CheckedOwnerData ==
    { ZeroOwnerData }
        \cup { [ZeroOwnerData EXCEPT !.memo = one] : one \in Sample(50) }

(***************************************************************************)
(* Order Reply: 134 bytes                                                  *)
(***************************************************************************)

OrderReply ==
    [ outgoingMessagesHeader : OutgoingMessagesHeader,
      group                  : Sample(2),
      instrument             : Sample(4),
      traderId               : Sample(8),
      orderId                : Sample(8),
      status                 : Sample(1),
      verbSide               : Sample(1),
      quantityRemaining      : Sample(8),
      assignedPrice          : Sample(10),
      clearingData           : ClearingData,
      ownerData              : OwnerData ]

EncodeOrderReply(message) ==
    EncodeOutgoingMessagesHeader(message.outgoingMessagesHeader)
        \o message.group
        \o message.instrument
        \o message.traderId
        \o message.orderId
        \o message.status
        \o message.verbSide
        \o message.quantityRemaining
        \o message.assignedPrice
        \o EncodeClearingData(message.clearingData)
        \o EncodeOwnerData(message.ownerData)

DecodeOrderReply(bytes) ==
    LET outgoingMessagesHeader == DecodeOutgoingMessagesHeader(bytes) IN IF ~outgoingMessagesHeader.ok THEN Fail ELSE
    LET group == ReadBytes(outgoingMessagesHeader.rest, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrument == ReadBytes(group.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET traderId == ReadBytes(instrument.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET orderId == ReadBytes(traderId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET status == ReadBytes(orderId.rest, 1) IN IF ~status.ok THEN Fail ELSE
    LET verbSide == ReadBytes(status.rest, 1) IN IF ~verbSide.ok THEN Fail ELSE
    LET quantityRemaining == ReadBytes(verbSide.rest, 8) IN IF ~quantityRemaining.ok THEN Fail ELSE
    LET assignedPrice == ReadBytes(quantityRemaining.rest, 10) IN IF ~assignedPrice.ok THEN Fail ELSE
    LET clearingData == DecodeClearingData(assignedPrice.rest) IN IF ~clearingData.ok THEN Fail ELSE
    LET ownerData == DecodeOwnerData(clearingData.rest) IN IF ~ownerData.ok THEN Fail ELSE
    Ok([ outgoingMessagesHeader |-> outgoingMessagesHeader.value,
         group                  |-> group.value,
         instrument             |-> instrument.value,
         traderId               |-> traderId.value,
         orderId                |-> orderId.value,
         status                 |-> status.value,
         verbSide               |-> verbSide.value,
         quantityRemaining      |-> quantityRemaining.value,
         assignedPrice          |-> assignedPrice.value,
         clearingData           |-> clearingData.value,
         ownerData              |-> ownerData.value ], ownerData.rest)

ZeroOrderReply ==
    [ outgoingMessagesHeader |-> ZeroOutgoingMessagesHeader,
      group                  |-> [i \in 1 .. 2 |-> 0],
      instrument             |-> [i \in 1 .. 4 |-> 0],
      traderId               |-> [i \in 1 .. 8 |-> 0],
      orderId                |-> [i \in 1 .. 8 |-> 0],
      status                 |-> [i \in 1 .. 1 |-> 0],
      verbSide               |-> [i \in 1 .. 1 |-> 0],
      quantityRemaining      |-> [i \in 1 .. 8 |-> 0],
      assignedPrice          |-> [i \in 1 .. 10 |-> 0],
      clearingData           |-> ZeroClearingData,
      ownerData              |-> ZeroOwnerData ]

(* Order Reply at zero, then each field in turn at the values it is checked at *)
CheckedOrderReply ==
    { ZeroOrderReply }
        \cup { [ZeroOrderReply EXCEPT !.outgoingMessagesHeader = one] : one \in CheckedOutgoingMessagesHeader }
        \cup { [ZeroOrderReply EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroOrderReply EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroOrderReply EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderReply EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderReply EXCEPT !.status = one] : one \in Sample(1) }
        \cup { [ZeroOrderReply EXCEPT !.verbSide = one] : one \in Sample(1) }
        \cup { [ZeroOrderReply EXCEPT !.quantityRemaining = one] : one \in Sample(8) }
        \cup { [ZeroOrderReply EXCEPT !.assignedPrice = one] : one \in Sample(10) }
        \cup { [ZeroOrderReply EXCEPT !.clearingData = one] : one \in CheckedClearingData }
        \cup { [ZeroOrderReply EXCEPT !.ownerData = one] : one \in CheckedOwnerData }

(***************************************************************************)
(* Outgoing Messages Header: 22 bytes                                      *)
(***************************************************************************)

OutgoingMessagesHeader2 ==
    [ tradingEngineTimestampLocalHhmmss : Sample(6),
      userSequenceId                    : Sample(8),
      exchangeMessageId                 : Sample(6),
      gapSequenceId                     : Sample(2) ]

EncodeOutgoingMessagesHeader2(message) ==
    message.tradingEngineTimestampLocalHhmmss
        \o message.userSequenceId
        \o message.exchangeMessageId
        \o message.gapSequenceId

DecodeOutgoingMessagesHeader2(bytes) ==
    LET tradingEngineTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~tradingEngineTimestampLocalHhmmss.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(tradingEngineTimestampLocalHhmmss.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    LET exchangeMessageId == ReadBytes(userSequenceId.rest, 6) IN IF ~exchangeMessageId.ok THEN Fail ELSE
    LET gapSequenceId == ReadBytes(exchangeMessageId.rest, 2) IN IF ~gapSequenceId.ok THEN Fail ELSE
    Ok([ tradingEngineTimestampLocalHhmmss |-> tradingEngineTimestampLocalHhmmss.value,
         userSequenceId                    |-> userSequenceId.value,
         exchangeMessageId                 |-> exchangeMessageId.value,
         gapSequenceId                     |-> gapSequenceId.value ], gapSequenceId.rest)

ZeroOutgoingMessagesHeader2 ==
    [ tradingEngineTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      userSequenceId                    |-> [i \in 1 .. 8 |-> 0],
      exchangeMessageId                 |-> [i \in 1 .. 6 |-> 0],
      gapSequenceId                     |-> [i \in 1 .. 2 |-> 0] ]

(* Outgoing Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedOutgoingMessagesHeader2 ==
    { ZeroOutgoingMessagesHeader2 }
        \cup { [ZeroOutgoingMessagesHeader2 EXCEPT !.tradingEngineTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroOutgoingMessagesHeader2 EXCEPT !.userSequenceId = one] : one \in Sample(8) }
        \cup { [ZeroOutgoingMessagesHeader2 EXCEPT !.exchangeMessageId = one] : one \in Sample(6) }
        \cup { [ZeroOutgoingMessagesHeader2 EXCEPT !.gapSequenceId = one] : one \in Sample(2) }

(***************************************************************************)
(* Error Notice: 126 bytes                                                 *)
(***************************************************************************)

ErrorNotice ==
    [ outgoingMessagesHeader : OutgoingMessagesHeader2,
      errorCode              : Sample(4),
      errorDescription       : Sample(100) ]

EncodeErrorNotice(message) ==
    EncodeOutgoingMessagesHeader2(message.outgoingMessagesHeader)
        \o message.errorCode
        \o message.errorDescription

DecodeErrorNotice(bytes) ==
    LET outgoingMessagesHeader == DecodeOutgoingMessagesHeader2(bytes) IN IF ~outgoingMessagesHeader.ok THEN Fail ELSE
    LET errorCode == ReadBytes(outgoingMessagesHeader.rest, 4) IN IF ~errorCode.ok THEN Fail ELSE
    LET errorDescription == ReadBytes(errorCode.rest, 100) IN IF ~errorDescription.ok THEN Fail ELSE
    Ok([ outgoingMessagesHeader |-> outgoingMessagesHeader.value,
         errorCode              |-> errorCode.value,
         errorDescription       |-> errorDescription.value ], errorDescription.rest)

ZeroErrorNotice ==
    [ outgoingMessagesHeader |-> ZeroOutgoingMessagesHeader2,
      errorCode              |-> [i \in 1 .. 4 |-> 0],
      errorDescription       |-> [i \in 1 .. 100 |-> 0] ]

(* Error Notice at zero, then each field in turn at the values it is checked at *)
CheckedErrorNotice ==
    { ZeroErrorNotice }
        \cup { [ZeroErrorNotice EXCEPT !.outgoingMessagesHeader = one] : one \in CheckedOutgoingMessagesHeader2 }
        \cup { [ZeroErrorNotice EXCEPT !.errorCode = one] : one \in Sample(4) }
        \cup { [ZeroErrorNotice EXCEPT !.errorDescription = one] : one \in Sample(100) }

(***************************************************************************)
(* Outgoing Messages Header: 22 bytes                                      *)
(***************************************************************************)

OutgoingMessagesHeader3 ==
    [ tradingEngineTimestampLocalHhmmss : Sample(6),
      userSequenceId                    : Sample(8),
      exchangeMessageId                 : Sample(6),
      gapSequenceId                     : Sample(2) ]

EncodeOutgoingMessagesHeader3(message) ==
    message.tradingEngineTimestampLocalHhmmss
        \o message.userSequenceId
        \o message.exchangeMessageId
        \o message.gapSequenceId

DecodeOutgoingMessagesHeader3(bytes) ==
    LET tradingEngineTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~tradingEngineTimestampLocalHhmmss.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(tradingEngineTimestampLocalHhmmss.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    LET exchangeMessageId == ReadBytes(userSequenceId.rest, 6) IN IF ~exchangeMessageId.ok THEN Fail ELSE
    LET gapSequenceId == ReadBytes(exchangeMessageId.rest, 2) IN IF ~gapSequenceId.ok THEN Fail ELSE
    Ok([ tradingEngineTimestampLocalHhmmss |-> tradingEngineTimestampLocalHhmmss.value,
         userSequenceId                    |-> userSequenceId.value,
         exchangeMessageId                 |-> exchangeMessageId.value,
         gapSequenceId                     |-> gapSequenceId.value ], gapSequenceId.rest)

ZeroOutgoingMessagesHeader3 ==
    [ tradingEngineTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      userSequenceId                    |-> [i \in 1 .. 8 |-> 0],
      exchangeMessageId                 |-> [i \in 1 .. 6 |-> 0],
      gapSequenceId                     |-> [i \in 1 .. 2 |-> 0] ]

(* Outgoing Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedOutgoingMessagesHeader3 ==
    { ZeroOutgoingMessagesHeader3 }
        \cup { [ZeroOutgoingMessagesHeader3 EXCEPT !.tradingEngineTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroOutgoingMessagesHeader3 EXCEPT !.userSequenceId = one] : one \in Sample(8) }
        \cup { [ZeroOutgoingMessagesHeader3 EXCEPT !.exchangeMessageId = one] : one \in Sample(6) }
        \cup { [ZeroOutgoingMessagesHeader3 EXCEPT !.gapSequenceId = one] : one \in Sample(2) }

(***************************************************************************)
(* Bulk Quote Data Acknowledgement: 40 bytes                               *)
(***************************************************************************)

BulkQuoteDataAcknowledgement ==
    [ outgoingMessagesHeader                   : OutgoingMessagesHeader3,
      group                                    : Sample(2),
      traderId                                 : Sample(8),
      quoteIdIdentifiesTradersQuoteOnThisGroup : Sample(8) ]

EncodeBulkQuoteDataAcknowledgement(message) ==
    EncodeOutgoingMessagesHeader3(message.outgoingMessagesHeader)
        \o message.group
        \o message.traderId
        \o message.quoteIdIdentifiesTradersQuoteOnThisGroup

DecodeBulkQuoteDataAcknowledgement(bytes) ==
    LET outgoingMessagesHeader == DecodeOutgoingMessagesHeader3(bytes) IN IF ~outgoingMessagesHeader.ok THEN Fail ELSE
    LET group == ReadBytes(outgoingMessagesHeader.rest, 2) IN IF ~group.ok THEN Fail ELSE
    LET traderId == ReadBytes(group.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET quoteIdIdentifiesTradersQuoteOnThisGroup == ReadBytes(traderId.rest, 8) IN IF ~quoteIdIdentifiesTradersQuoteOnThisGroup.ok THEN Fail ELSE
    Ok([ outgoingMessagesHeader                   |-> outgoingMessagesHeader.value,
         group                                    |-> group.value,
         traderId                                 |-> traderId.value,
         quoteIdIdentifiesTradersQuoteOnThisGroup |-> quoteIdIdentifiesTradersQuoteOnThisGroup.value ], quoteIdIdentifiesTradersQuoteOnThisGroup.rest)

ZeroBulkQuoteDataAcknowledgement ==
    [ outgoingMessagesHeader                   |-> ZeroOutgoingMessagesHeader3,
      group                                    |-> [i \in 1 .. 2 |-> 0],
      traderId                                 |-> [i \in 1 .. 8 |-> 0],
      quoteIdIdentifiesTradersQuoteOnThisGroup |-> [i \in 1 .. 8 |-> 0] ]

(* Bulk Quote Data Acknowledgement at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuoteDataAcknowledgement ==
    { ZeroBulkQuoteDataAcknowledgement }
        \cup { [ZeroBulkQuoteDataAcknowledgement EXCEPT !.outgoingMessagesHeader = one] : one \in CheckedOutgoingMessagesHeader3 }
        \cup { [ZeroBulkQuoteDataAcknowledgement EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuoteDataAcknowledgement EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuoteDataAcknowledgement EXCEPT !.quoteIdIdentifiesTradersQuoteOnThisGroup = one] : one \in Sample(8) }

(***************************************************************************)
(* Outgoing Messages Header: 22 bytes                                      *)
(***************************************************************************)

OutgoingMessagesHeader4 ==
    [ tradingEngineTimestampLocalHhmmss : Sample(6),
      userSequenceId                    : Sample(8),
      exchangeMessageId                 : Sample(6),
      gapSequenceId                     : Sample(2) ]

EncodeOutgoingMessagesHeader4(message) ==
    message.tradingEngineTimestampLocalHhmmss
        \o message.userSequenceId
        \o message.exchangeMessageId
        \o message.gapSequenceId

DecodeOutgoingMessagesHeader4(bytes) ==
    LET tradingEngineTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~tradingEngineTimestampLocalHhmmss.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(tradingEngineTimestampLocalHhmmss.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    LET exchangeMessageId == ReadBytes(userSequenceId.rest, 6) IN IF ~exchangeMessageId.ok THEN Fail ELSE
    LET gapSequenceId == ReadBytes(exchangeMessageId.rest, 2) IN IF ~gapSequenceId.ok THEN Fail ELSE
    Ok([ tradingEngineTimestampLocalHhmmss |-> tradingEngineTimestampLocalHhmmss.value,
         userSequenceId                    |-> userSequenceId.value,
         exchangeMessageId                 |-> exchangeMessageId.value,
         gapSequenceId                     |-> gapSequenceId.value ], gapSequenceId.rest)

ZeroOutgoingMessagesHeader4 ==
    [ tradingEngineTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      userSequenceId                    |-> [i \in 1 .. 8 |-> 0],
      exchangeMessageId                 |-> [i \in 1 .. 6 |-> 0],
      gapSequenceId                     |-> [i \in 1 .. 2 |-> 0] ]

(* Outgoing Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedOutgoingMessagesHeader4 ==
    { ZeroOutgoingMessagesHeader4 }
        \cup { [ZeroOutgoingMessagesHeader4 EXCEPT !.tradingEngineTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroOutgoingMessagesHeader4 EXCEPT !.userSequenceId = one] : one \in Sample(8) }
        \cup { [ZeroOutgoingMessagesHeader4 EXCEPT !.exchangeMessageId = one] : one \in Sample(6) }
        \cup { [ZeroOutgoingMessagesHeader4 EXCEPT !.gapSequenceId = one] : one \in Sample(2) }

(***************************************************************************)
(* Clearing Data: 20 bytes                                                 *)
(***************************************************************************)

ClearingData2 ==
    [ clearingInstruction : Sample(12),
      accountType         : Sample(1),
      openClose           : Sample(1),
      hedgeSpec           : Sample(1),
      filler5             : Sample(5) ]

EncodeClearingData2(message) ==
    message.clearingInstruction
        \o message.accountType
        \o message.openClose
        \o message.hedgeSpec
        \o message.filler5

DecodeClearingData2(bytes) ==
    LET clearingInstruction == ReadBytes(bytes, 12) IN IF ~clearingInstruction.ok THEN Fail ELSE
    LET accountType == ReadBytes(clearingInstruction.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET openClose == ReadBytes(accountType.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET hedgeSpec == ReadBytes(openClose.rest, 1) IN IF ~hedgeSpec.ok THEN Fail ELSE
    LET filler5 == ReadBytes(hedgeSpec.rest, 5) IN IF ~filler5.ok THEN Fail ELSE
    Ok([ clearingInstruction |-> clearingInstruction.value,
         accountType         |-> accountType.value,
         openClose           |-> openClose.value,
         hedgeSpec           |-> hedgeSpec.value,
         filler5             |-> filler5.value ], filler5.rest)

ZeroClearingData2 ==
    [ clearingInstruction |-> [i \in 1 .. 12 |-> 0],
      accountType         |-> [i \in 1 .. 1 |-> 0],
      openClose           |-> [i \in 1 .. 1 |-> 0],
      hedgeSpec           |-> [i \in 1 .. 1 |-> 0],
      filler5             |-> [i \in 1 .. 5 |-> 0] ]

(* Clearing Data at zero, then each field in turn at the values it is checked at *)
CheckedClearingData2 ==
    { ZeroClearingData2 }
        \cup { [ZeroClearingData2 EXCEPT !.clearingInstruction = one] : one \in Sample(12) }
        \cup { [ZeroClearingData2 EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroClearingData2 EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroClearingData2 EXCEPT !.hedgeSpec = one] : one \in Sample(1) }
        \cup { [ZeroClearingData2 EXCEPT !.filler5 = one] : one \in Sample(5) }

(***************************************************************************)
(* Owner Data: 50 bytes                                                    *)
(***************************************************************************)

OwnerData2 ==
    [ memo : Sample(50) ]

EncodeOwnerData2(message) ==
    message.memo

DecodeOwnerData2(bytes) ==
    LET memo == ReadBytes(bytes, 50) IN IF ~memo.ok THEN Fail ELSE
    Ok([ memo |-> memo.value ], memo.rest)

ZeroOwnerData2 ==
    [ memo |-> [i \in 1 .. 50 |-> 0] ]

(* Owner Data at zero, then each field in turn at the values it is checked at *)
CheckedOwnerData2 ==
    { ZeroOwnerData2 }
        \cup { [ZeroOwnerData2 EXCEPT !.memo = one] : one \in Sample(50) }

(***************************************************************************)
(* Order Acknowledgement: 148 bytes                                        *)
(***************************************************************************)

OrderAcknowledgement ==
    [ outgoingMessagesHeader : OutgoingMessagesHeader4,
      group                  : Sample(2),
      instrument             : Sample(4),
      traderId               : Sample(8),
      orderId                : Sample(8),
      status                 : Sample(1),
      verbSide               : Sample(1),
      quantity               : Sample(8),
      assignedPrice          : Sample(10),
      clearingData           : ClearingData2,
      ownerData              : OwnerData2,
      originalOrderId        : Sample(8),
      filler6                : Sample(6) ]

EncodeOrderAcknowledgement(message) ==
    EncodeOutgoingMessagesHeader4(message.outgoingMessagesHeader)
        \o message.group
        \o message.instrument
        \o message.traderId
        \o message.orderId
        \o message.status
        \o message.verbSide
        \o message.quantity
        \o message.assignedPrice
        \o EncodeClearingData2(message.clearingData)
        \o EncodeOwnerData2(message.ownerData)
        \o message.originalOrderId
        \o message.filler6

DecodeOrderAcknowledgement(bytes) ==
    LET outgoingMessagesHeader == DecodeOutgoingMessagesHeader4(bytes) IN IF ~outgoingMessagesHeader.ok THEN Fail ELSE
    LET group == ReadBytes(outgoingMessagesHeader.rest, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrument == ReadBytes(group.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET traderId == ReadBytes(instrument.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET orderId == ReadBytes(traderId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET status == ReadBytes(orderId.rest, 1) IN IF ~status.ok THEN Fail ELSE
    LET verbSide == ReadBytes(status.rest, 1) IN IF ~verbSide.ok THEN Fail ELSE
    LET quantity == ReadBytes(verbSide.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET assignedPrice == ReadBytes(quantity.rest, 10) IN IF ~assignedPrice.ok THEN Fail ELSE
    LET clearingData == DecodeClearingData2(assignedPrice.rest) IN IF ~clearingData.ok THEN Fail ELSE
    LET ownerData == DecodeOwnerData2(clearingData.rest) IN IF ~ownerData.ok THEN Fail ELSE
    LET originalOrderId == ReadBytes(ownerData.rest, 8) IN IF ~originalOrderId.ok THEN Fail ELSE
    LET filler6 == ReadBytes(originalOrderId.rest, 6) IN IF ~filler6.ok THEN Fail ELSE
    Ok([ outgoingMessagesHeader |-> outgoingMessagesHeader.value,
         group                  |-> group.value,
         instrument             |-> instrument.value,
         traderId               |-> traderId.value,
         orderId                |-> orderId.value,
         status                 |-> status.value,
         verbSide               |-> verbSide.value,
         quantity               |-> quantity.value,
         assignedPrice          |-> assignedPrice.value,
         clearingData           |-> clearingData.value,
         ownerData              |-> ownerData.value,
         originalOrderId        |-> originalOrderId.value,
         filler6                |-> filler6.value ], filler6.rest)

ZeroOrderAcknowledgement ==
    [ outgoingMessagesHeader |-> ZeroOutgoingMessagesHeader4,
      group                  |-> [i \in 1 .. 2 |-> 0],
      instrument             |-> [i \in 1 .. 4 |-> 0],
      traderId               |-> [i \in 1 .. 8 |-> 0],
      orderId                |-> [i \in 1 .. 8 |-> 0],
      status                 |-> [i \in 1 .. 1 |-> 0],
      verbSide               |-> [i \in 1 .. 1 |-> 0],
      quantity               |-> [i \in 1 .. 8 |-> 0],
      assignedPrice          |-> [i \in 1 .. 10 |-> 0],
      clearingData           |-> ZeroClearingData2,
      ownerData              |-> ZeroOwnerData2,
      originalOrderId        |-> [i \in 1 .. 8 |-> 0],
      filler6                |-> [i \in 1 .. 6 |-> 0] ]

(* Order Acknowledgement at zero, then each field in turn at the values it is checked at *)
CheckedOrderAcknowledgement ==
    { ZeroOrderAcknowledgement }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.outgoingMessagesHeader = one] : one \in CheckedOutgoingMessagesHeader4 }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.status = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.verbSide = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.assignedPrice = one] : one \in Sample(10) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.clearingData = one] : one \in CheckedClearingData2 }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.ownerData = one] : one \in CheckedOwnerData2 }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.originalOrderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgement EXCEPT !.filler6 = one] : one \in Sample(6) }

(***************************************************************************)
(* Outgoing Messages Header: 22 bytes                                      *)
(***************************************************************************)

OutgoingMessagesHeader5 ==
    [ tradingEngineTimestampLocalHhmmss : Sample(6),
      userSequenceId                    : Sample(8),
      exchangeMessageId                 : Sample(6),
      gapSequenceId                     : Sample(2) ]

EncodeOutgoingMessagesHeader5(message) ==
    message.tradingEngineTimestampLocalHhmmss
        \o message.userSequenceId
        \o message.exchangeMessageId
        \o message.gapSequenceId

DecodeOutgoingMessagesHeader5(bytes) ==
    LET tradingEngineTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~tradingEngineTimestampLocalHhmmss.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(tradingEngineTimestampLocalHhmmss.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    LET exchangeMessageId == ReadBytes(userSequenceId.rest, 6) IN IF ~exchangeMessageId.ok THEN Fail ELSE
    LET gapSequenceId == ReadBytes(exchangeMessageId.rest, 2) IN IF ~gapSequenceId.ok THEN Fail ELSE
    Ok([ tradingEngineTimestampLocalHhmmss |-> tradingEngineTimestampLocalHhmmss.value,
         userSequenceId                    |-> userSequenceId.value,
         exchangeMessageId                 |-> exchangeMessageId.value,
         gapSequenceId                     |-> gapSequenceId.value ], gapSequenceId.rest)

ZeroOutgoingMessagesHeader5 ==
    [ tradingEngineTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      userSequenceId                    |-> [i \in 1 .. 8 |-> 0],
      exchangeMessageId                 |-> [i \in 1 .. 6 |-> 0],
      gapSequenceId                     |-> [i \in 1 .. 2 |-> 0] ]

(* Outgoing Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedOutgoingMessagesHeader5 ==
    { ZeroOutgoingMessagesHeader5 }
        \cup { [ZeroOutgoingMessagesHeader5 EXCEPT !.tradingEngineTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroOutgoingMessagesHeader5 EXCEPT !.userSequenceId = one] : one \in Sample(8) }
        \cup { [ZeroOutgoingMessagesHeader5 EXCEPT !.exchangeMessageId = one] : one \in Sample(6) }
        \cup { [ZeroOutgoingMessagesHeader5 EXCEPT !.gapSequenceId = one] : one \in Sample(2) }

(***************************************************************************)
(* Global Cancellation Confirmation: 33 bytes                              *)
(***************************************************************************)

GlobalCancellationConfirmation ==
    [ outgoingMessagesHeader                         : OutgoingMessagesHeader5,
      group                                          : Sample(2),
      traderId                                       : Sample(8),
      typeOfCancellationOnlyQQuotesOnlyCanBeReturned : Sample(1) ]

EncodeGlobalCancellationConfirmation(message) ==
    EncodeOutgoingMessagesHeader5(message.outgoingMessagesHeader)
        \o message.group
        \o message.traderId
        \o message.typeOfCancellationOnlyQQuotesOnlyCanBeReturned

DecodeGlobalCancellationConfirmation(bytes) ==
    LET outgoingMessagesHeader == DecodeOutgoingMessagesHeader5(bytes) IN IF ~outgoingMessagesHeader.ok THEN Fail ELSE
    LET group == ReadBytes(outgoingMessagesHeader.rest, 2) IN IF ~group.ok THEN Fail ELSE
    LET traderId == ReadBytes(group.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET typeOfCancellationOnlyQQuotesOnlyCanBeReturned == ReadBytes(traderId.rest, 1) IN IF ~typeOfCancellationOnlyQQuotesOnlyCanBeReturned.ok THEN Fail ELSE
    Ok([ outgoingMessagesHeader                         |-> outgoingMessagesHeader.value,
         group                                          |-> group.value,
         traderId                                       |-> traderId.value,
         typeOfCancellationOnlyQQuotesOnlyCanBeReturned |-> typeOfCancellationOnlyQQuotesOnlyCanBeReturned.value ], typeOfCancellationOnlyQQuotesOnlyCanBeReturned.rest)

ZeroGlobalCancellationConfirmation ==
    [ outgoingMessagesHeader                         |-> ZeroOutgoingMessagesHeader5,
      group                                          |-> [i \in 1 .. 2 |-> 0],
      traderId                                       |-> [i \in 1 .. 8 |-> 0],
      typeOfCancellationOnlyQQuotesOnlyCanBeReturned |-> [i \in 1 .. 1 |-> 0] ]

(* Global Cancellation Confirmation at zero, then each field in turn at the values it is checked at *)
CheckedGlobalCancellationConfirmation ==
    { ZeroGlobalCancellationConfirmation }
        \cup { [ZeroGlobalCancellationConfirmation EXCEPT !.outgoingMessagesHeader = one] : one \in CheckedOutgoingMessagesHeader5 }
        \cup { [ZeroGlobalCancellationConfirmation EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroGlobalCancellationConfirmation EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroGlobalCancellationConfirmation EXCEPT !.typeOfCancellationOnlyQQuotesOnlyCanBeReturned = one] : one \in Sample(1) }

(***************************************************************************)
(* Clearing Data: 20 bytes                                                 *)
(***************************************************************************)

ClearingData3 ==
    [ clearingInstruction : Sample(12),
      accountType         : Sample(1),
      openClose           : Sample(1),
      hedgeSpec           : Sample(1),
      filler5             : Sample(5) ]

EncodeClearingData3(message) ==
    message.clearingInstruction
        \o message.accountType
        \o message.openClose
        \o message.hedgeSpec
        \o message.filler5

DecodeClearingData3(bytes) ==
    LET clearingInstruction == ReadBytes(bytes, 12) IN IF ~clearingInstruction.ok THEN Fail ELSE
    LET accountType == ReadBytes(clearingInstruction.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET openClose == ReadBytes(accountType.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET hedgeSpec == ReadBytes(openClose.rest, 1) IN IF ~hedgeSpec.ok THEN Fail ELSE
    LET filler5 == ReadBytes(hedgeSpec.rest, 5) IN IF ~filler5.ok THEN Fail ELSE
    Ok([ clearingInstruction |-> clearingInstruction.value,
         accountType         |-> accountType.value,
         openClose           |-> openClose.value,
         hedgeSpec           |-> hedgeSpec.value,
         filler5             |-> filler5.value ], filler5.rest)

ZeroClearingData3 ==
    [ clearingInstruction |-> [i \in 1 .. 12 |-> 0],
      accountType         |-> [i \in 1 .. 1 |-> 0],
      openClose           |-> [i \in 1 .. 1 |-> 0],
      hedgeSpec           |-> [i \in 1 .. 1 |-> 0],
      filler5             |-> [i \in 1 .. 5 |-> 0] ]

(* Clearing Data at zero, then each field in turn at the values it is checked at *)
CheckedClearingData3 ==
    { ZeroClearingData3 }
        \cup { [ZeroClearingData3 EXCEPT !.clearingInstruction = one] : one \in Sample(12) }
        \cup { [ZeroClearingData3 EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroClearingData3 EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroClearingData3 EXCEPT !.hedgeSpec = one] : one \in Sample(1) }
        \cup { [ZeroClearingData3 EXCEPT !.filler5 = one] : one \in Sample(5) }

(***************************************************************************)
(* Owner Data: 50 bytes                                                    *)
(***************************************************************************)

OwnerData3 ==
    [ memo : Sample(50) ]

EncodeOwnerData3(message) ==
    message.memo

DecodeOwnerData3(bytes) ==
    LET memo == ReadBytes(bytes, 50) IN IF ~memo.ok THEN Fail ELSE
    Ok([ memo |-> memo.value ], memo.rest)

ZeroOwnerData3 ==
    [ memo |-> [i \in 1 .. 50 |-> 0] ]

(* Owner Data at zero, then each field in turn at the values it is checked at *)
CheckedOwnerData3 ==
    { ZeroOwnerData3 }
        \cup { [ZeroOwnerData3 EXCEPT !.memo = one] : one \in Sample(50) }

(***************************************************************************)
(* Order Modification Acknowledgement: 126 bytes                           *)
(***************************************************************************)

OrderModificationAcknowledgement ==
    [ group           : Sample(2),
      instrument      : Sample(4),
      traderId        : Sample(8),
      orderId         : Sample(8),
      status          : Sample(1),
      verbSide        : Sample(1),
      quantity        : Sample(8),
      assignedPrice   : Sample(10),
      clearingData    : ClearingData3,
      ownerData       : OwnerData3,
      originalOrderId : Sample(8),
      filler6         : Sample(6) ]

EncodeOrderModificationAcknowledgement(message) ==
    message.group
        \o message.instrument
        \o message.traderId
        \o message.orderId
        \o message.status
        \o message.verbSide
        \o message.quantity
        \o message.assignedPrice
        \o EncodeClearingData3(message.clearingData)
        \o EncodeOwnerData3(message.ownerData)
        \o message.originalOrderId
        \o message.filler6

DecodeOrderModificationAcknowledgement(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrument == ReadBytes(group.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET traderId == ReadBytes(instrument.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET orderId == ReadBytes(traderId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET status == ReadBytes(orderId.rest, 1) IN IF ~status.ok THEN Fail ELSE
    LET verbSide == ReadBytes(status.rest, 1) IN IF ~verbSide.ok THEN Fail ELSE
    LET quantity == ReadBytes(verbSide.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET assignedPrice == ReadBytes(quantity.rest, 10) IN IF ~assignedPrice.ok THEN Fail ELSE
    LET clearingData == DecodeClearingData3(assignedPrice.rest) IN IF ~clearingData.ok THEN Fail ELSE
    LET ownerData == DecodeOwnerData3(clearingData.rest) IN IF ~ownerData.ok THEN Fail ELSE
    LET originalOrderId == ReadBytes(ownerData.rest, 8) IN IF ~originalOrderId.ok THEN Fail ELSE
    LET filler6 == ReadBytes(originalOrderId.rest, 6) IN IF ~filler6.ok THEN Fail ELSE
    Ok([ group           |-> group.value,
         instrument      |-> instrument.value,
         traderId        |-> traderId.value,
         orderId         |-> orderId.value,
         status          |-> status.value,
         verbSide        |-> verbSide.value,
         quantity        |-> quantity.value,
         assignedPrice   |-> assignedPrice.value,
         clearingData    |-> clearingData.value,
         ownerData       |-> ownerData.value,
         originalOrderId |-> originalOrderId.value,
         filler6         |-> filler6.value ], filler6.rest)

ZeroOrderModificationAcknowledgement ==
    [ group           |-> [i \in 1 .. 2 |-> 0],
      instrument      |-> [i \in 1 .. 4 |-> 0],
      traderId        |-> [i \in 1 .. 8 |-> 0],
      orderId         |-> [i \in 1 .. 8 |-> 0],
      status          |-> [i \in 1 .. 1 |-> 0],
      verbSide        |-> [i \in 1 .. 1 |-> 0],
      quantity        |-> [i \in 1 .. 8 |-> 0],
      assignedPrice   |-> [i \in 1 .. 10 |-> 0],
      clearingData    |-> ZeroClearingData3,
      ownerData       |-> ZeroOwnerData3,
      originalOrderId |-> [i \in 1 .. 8 |-> 0],
      filler6         |-> [i \in 1 .. 6 |-> 0] ]

(* Order Modification Acknowledgement at zero, then each field in turn at the values it is checked at *)
CheckedOrderModificationAcknowledgement ==
    { ZeroOrderModificationAcknowledgement }
        \cup { [ZeroOrderModificationAcknowledgement EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroOrderModificationAcknowledgement EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroOrderModificationAcknowledgement EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderModificationAcknowledgement EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderModificationAcknowledgement EXCEPT !.status = one] : one \in Sample(1) }
        \cup { [ZeroOrderModificationAcknowledgement EXCEPT !.verbSide = one] : one \in Sample(1) }
        \cup { [ZeroOrderModificationAcknowledgement EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroOrderModificationAcknowledgement EXCEPT !.assignedPrice = one] : one \in Sample(10) }
        \cup { [ZeroOrderModificationAcknowledgement EXCEPT !.clearingData = one] : one \in CheckedClearingData3 }
        \cup { [ZeroOrderModificationAcknowledgement EXCEPT !.ownerData = one] : one \in CheckedOwnerData3 }
        \cup { [ZeroOrderModificationAcknowledgement EXCEPT !.originalOrderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderModificationAcknowledgement EXCEPT !.filler6 = one] : one \in Sample(6) }

(***************************************************************************)
(* Outgoing Messages Header: 22 bytes                                      *)
(***************************************************************************)

OutgoingMessagesHeader6 ==
    [ tradingEngineTimestampLocalHhmmss : Sample(6),
      userSequenceId                    : Sample(8),
      exchangeMessageId                 : Sample(6),
      gapSequenceId                     : Sample(2) ]

EncodeOutgoingMessagesHeader6(message) ==
    message.tradingEngineTimestampLocalHhmmss
        \o message.userSequenceId
        \o message.exchangeMessageId
        \o message.gapSequenceId

DecodeOutgoingMessagesHeader6(bytes) ==
    LET tradingEngineTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~tradingEngineTimestampLocalHhmmss.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(tradingEngineTimestampLocalHhmmss.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    LET exchangeMessageId == ReadBytes(userSequenceId.rest, 6) IN IF ~exchangeMessageId.ok THEN Fail ELSE
    LET gapSequenceId == ReadBytes(exchangeMessageId.rest, 2) IN IF ~gapSequenceId.ok THEN Fail ELSE
    Ok([ tradingEngineTimestampLocalHhmmss |-> tradingEngineTimestampLocalHhmmss.value,
         userSequenceId                    |-> userSequenceId.value,
         exchangeMessageId                 |-> exchangeMessageId.value,
         gapSequenceId                     |-> gapSequenceId.value ], gapSequenceId.rest)

ZeroOutgoingMessagesHeader6 ==
    [ tradingEngineTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      userSequenceId                    |-> [i \in 1 .. 8 |-> 0],
      exchangeMessageId                 |-> [i \in 1 .. 6 |-> 0],
      gapSequenceId                     |-> [i \in 1 .. 2 |-> 0] ]

(* Outgoing Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedOutgoingMessagesHeader6 ==
    { ZeroOutgoingMessagesHeader6 }
        \cup { [ZeroOutgoingMessagesHeader6 EXCEPT !.tradingEngineTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroOutgoingMessagesHeader6 EXCEPT !.userSequenceId = one] : one \in Sample(8) }
        \cup { [ZeroOutgoingMessagesHeader6 EXCEPT !.exchangeMessageId = one] : one \in Sample(6) }
        \cup { [ZeroOutgoingMessagesHeader6 EXCEPT !.gapSequenceId = one] : one \in Sample(2) }

(***************************************************************************)
(* New Strategy Instrument Acknowledgement Leg Definition Repeating Block: *)
(* 16 bytes                                                                *)
(***************************************************************************)

NewStrategyInstrumentAcknowledgementLegDefinitionRepeatingBlock ==
    [ legGroup         : Sample(2),
      legInstrument    : Sample(4),
      legVerb          : Sample(1),
      filler1          : Sample(1),
      legQuantityRatio : Sample(8) ]

EncodeNewStrategyInstrumentAcknowledgementLegDefinitionRepeatingBlock(message) ==
    message.legGroup
        \o message.legInstrument
        \o message.legVerb
        \o message.filler1
        \o message.legQuantityRatio

DecodeNewStrategyInstrumentAcknowledgementLegDefinitionRepeatingBlock(bytes) ==
    LET legGroup == ReadBytes(bytes, 2) IN IF ~legGroup.ok THEN Fail ELSE
    LET legInstrument == ReadBytes(legGroup.rest, 4) IN IF ~legInstrument.ok THEN Fail ELSE
    LET legVerb == ReadBytes(legInstrument.rest, 1) IN IF ~legVerb.ok THEN Fail ELSE
    LET filler1 == ReadBytes(legVerb.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET legQuantityRatio == ReadBytes(filler1.rest, 8) IN IF ~legQuantityRatio.ok THEN Fail ELSE
    Ok([ legGroup         |-> legGroup.value,
         legInstrument    |-> legInstrument.value,
         legVerb          |-> legVerb.value,
         filler1          |-> filler1.value,
         legQuantityRatio |-> legQuantityRatio.value ], legQuantityRatio.rest)

ZeroNewStrategyInstrumentAcknowledgementLegDefinitionRepeatingBlock ==
    [ legGroup         |-> [i \in 1 .. 2 |-> 0],
      legInstrument    |-> [i \in 1 .. 4 |-> 0],
      legVerb          |-> [i \in 1 .. 1 |-> 0],
      filler1          |-> [i \in 1 .. 1 |-> 0],
      legQuantityRatio |-> [i \in 1 .. 8 |-> 0] ]

(* New Strategy Instrument Acknowledgement Leg Definition Repeating Block at zero, then each field in turn at the values it is checked at *)
CheckedNewStrategyInstrumentAcknowledgementLegDefinitionRepeatingBlock ==
    { ZeroNewStrategyInstrumentAcknowledgementLegDefinitionRepeatingBlock }
        \cup { [ZeroNewStrategyInstrumentAcknowledgementLegDefinitionRepeatingBlock EXCEPT !.legGroup = one] : one \in Sample(2) }
        \cup { [ZeroNewStrategyInstrumentAcknowledgementLegDefinitionRepeatingBlock EXCEPT !.legInstrument = one] : one \in Sample(4) }
        \cup { [ZeroNewStrategyInstrumentAcknowledgementLegDefinitionRepeatingBlock EXCEPT !.legVerb = one] : one \in Sample(1) }
        \cup { [ZeroNewStrategyInstrumentAcknowledgementLegDefinitionRepeatingBlock EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroNewStrategyInstrumentAcknowledgementLegDefinitionRepeatingBlock EXCEPT !.legQuantityRatio = one] : one \in Sample(8) }

(* A run of New Strategy Instrument Acknowledgement Leg Definition Repeating Block, written one after another *)
RECURSIVE EncodeNewStrategyInstrumentAcknowledgementLegDefinitionRepeatingBlockList(_)
EncodeNewStrategyInstrumentAcknowledgementLegDefinitionRepeatingBlockList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeNewStrategyInstrumentAcknowledgementLegDefinitionRepeatingBlock(Head(messages)) \o EncodeNewStrategyInstrumentAcknowledgementLegDefinitionRepeatingBlockList(Tail(messages))

(* As many New Strategy Instrument Acknowledgement Leg Definition Repeating Block as the field that counts them says *)
RECURSIVE ReadNewStrategyInstrumentAcknowledgementLegDefinitionRepeatingBlockList(_, _)
ReadNewStrategyInstrumentAcknowledgementLegDefinitionRepeatingBlockList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeNewStrategyInstrumentAcknowledgementLegDefinitionRepeatingBlock(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadNewStrategyInstrumentAcknowledgementLegDefinitionRepeatingBlockList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One New Strategy Instrument Acknowledgement Leg Definition Repeating Block of each kind, for the lists that carry them *)
OneNewStrategyInstrumentAcknowledgementLegDefinitionRepeatingBlock == { ZeroNewStrategyInstrumentAcknowledgementLegDefinitionRepeatingBlock }

(***************************************************************************)
(* New Strategy Instrument Acknowledgement                                 *)
(***************************************************************************)

NewStrategyInstrumentAcknowledgement ==
    [ outgoingMessagesHeader                                          : OutgoingMessagesHeader6,
      strategyGroup                                                   : Sample(2),
      strategyInstrument                                              : Sample(4),
      creationStatus                                                  : Sample(1),
      newStrategyInstrumentAcknowledgementLegDefinitionRepeatingBlock : SampleLists(OneNewStrategyInstrumentAcknowledgementLegDefinitionRepeatingBlock) ]

EncodeNewStrategyInstrumentAcknowledgement(message) ==
    EncodeOutgoingMessagesHeader6(message.outgoingMessagesHeader)
        \o message.strategyGroup
        \o message.strategyInstrument
        \o message.creationStatus
        \o EncodeDigits(Len(message.newStrategyInstrumentAcknowledgementLegDefinitionRepeatingBlock), 2)
        \o EncodeNewStrategyInstrumentAcknowledgementLegDefinitionRepeatingBlockList(message.newStrategyInstrumentAcknowledgementLegDefinitionRepeatingBlock)

DecodeNewStrategyInstrumentAcknowledgement(bytes) ==
    LET outgoingMessagesHeader == DecodeOutgoingMessagesHeader6(bytes) IN IF ~outgoingMessagesHeader.ok THEN Fail ELSE
    LET strategyGroup == ReadBytes(outgoingMessagesHeader.rest, 2) IN IF ~strategyGroup.ok THEN Fail ELSE
    LET strategyInstrument == ReadBytes(strategyGroup.rest, 4) IN IF ~strategyInstrument.ok THEN Fail ELSE
    LET creationStatus == ReadBytes(strategyInstrument.rest, 1) IN IF ~creationStatus.ok THEN Fail ELSE
    LET numberOfLegs == ReadDigits(creationStatus.rest, 2) IN IF ~numberOfLegs.ok THEN Fail ELSE
    LET newStrategyInstrumentAcknowledgementLegDefinitionRepeatingBlock == ReadNewStrategyInstrumentAcknowledgementLegDefinitionRepeatingBlockList(numberOfLegs.rest, numberOfLegs.value) IN IF ~newStrategyInstrumentAcknowledgementLegDefinitionRepeatingBlock.ok THEN Fail ELSE
    Ok([ outgoingMessagesHeader                                          |-> outgoingMessagesHeader.value,
         strategyGroup                                                   |-> strategyGroup.value,
         strategyInstrument                                              |-> strategyInstrument.value,
         creationStatus                                                  |-> creationStatus.value,
         newStrategyInstrumentAcknowledgementLegDefinitionRepeatingBlock |-> newStrategyInstrumentAcknowledgementLegDefinitionRepeatingBlock.value ], newStrategyInstrumentAcknowledgementLegDefinitionRepeatingBlock.rest)

ZeroNewStrategyInstrumentAcknowledgement ==
    [ outgoingMessagesHeader                                          |-> ZeroOutgoingMessagesHeader6,
      strategyGroup                                                   |-> [i \in 1 .. 2 |-> 0],
      strategyInstrument                                              |-> [i \in 1 .. 4 |-> 0],
      creationStatus                                                  |-> [i \in 1 .. 1 |-> 0],
      newStrategyInstrumentAcknowledgementLegDefinitionRepeatingBlock |-> << >> ]

(* New Strategy Instrument Acknowledgement at zero, then each field in turn at the values it is checked at *)
CheckedNewStrategyInstrumentAcknowledgement ==
    { ZeroNewStrategyInstrumentAcknowledgement }
        \cup { [ZeroNewStrategyInstrumentAcknowledgement EXCEPT !.outgoingMessagesHeader = one] : one \in CheckedOutgoingMessagesHeader6 }
        \cup { [ZeroNewStrategyInstrumentAcknowledgement EXCEPT !.strategyGroup = one] : one \in Sample(2) }
        \cup { [ZeroNewStrategyInstrumentAcknowledgement EXCEPT !.strategyInstrument = one] : one \in Sample(4) }
        \cup { [ZeroNewStrategyInstrumentAcknowledgement EXCEPT !.creationStatus = one] : one \in Sample(1) }
        \cup { [ZeroNewStrategyInstrumentAcknowledgement EXCEPT !.newStrategyInstrumentAcknowledgementLegDefinitionRepeatingBlock = one] : one \in SampleLists(OneNewStrategyInstrumentAcknowledgementLegDefinitionRepeatingBlock) }

(***************************************************************************)
(* Outgoing Messages Header: 22 bytes                                      *)
(***************************************************************************)

OutgoingMessagesHeader7 ==
    [ tradingEngineTimestampLocalHhmmss : Sample(6),
      userSequenceId                    : Sample(8),
      exchangeMessageId                 : Sample(6),
      gapSequenceId                     : Sample(2) ]

EncodeOutgoingMessagesHeader7(message) ==
    message.tradingEngineTimestampLocalHhmmss
        \o message.userSequenceId
        \o message.exchangeMessageId
        \o message.gapSequenceId

DecodeOutgoingMessagesHeader7(bytes) ==
    LET tradingEngineTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~tradingEngineTimestampLocalHhmmss.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(tradingEngineTimestampLocalHhmmss.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    LET exchangeMessageId == ReadBytes(userSequenceId.rest, 6) IN IF ~exchangeMessageId.ok THEN Fail ELSE
    LET gapSequenceId == ReadBytes(exchangeMessageId.rest, 2) IN IF ~gapSequenceId.ok THEN Fail ELSE
    Ok([ tradingEngineTimestampLocalHhmmss |-> tradingEngineTimestampLocalHhmmss.value,
         userSequenceId                    |-> userSequenceId.value,
         exchangeMessageId                 |-> exchangeMessageId.value,
         gapSequenceId                     |-> gapSequenceId.value ], gapSequenceId.rest)

ZeroOutgoingMessagesHeader7 ==
    [ tradingEngineTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      userSequenceId                    |-> [i \in 1 .. 8 |-> 0],
      exchangeMessageId                 |-> [i \in 1 .. 6 |-> 0],
      gapSequenceId                     |-> [i \in 1 .. 2 |-> 0] ]

(* Outgoing Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedOutgoingMessagesHeader7 ==
    { ZeroOutgoingMessagesHeader7 }
        \cup { [ZeroOutgoingMessagesHeader7 EXCEPT !.tradingEngineTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroOutgoingMessagesHeader7 EXCEPT !.userSequenceId = one] : one \in Sample(8) }
        \cup { [ZeroOutgoingMessagesHeader7 EXCEPT !.exchangeMessageId = one] : one \in Sample(6) }
        \cup { [ZeroOutgoingMessagesHeader7 EXCEPT !.gapSequenceId = one] : one \in Sample(2) }

(***************************************************************************)
(* Standard Acknowledgement: 32 bytes                                      *)
(***************************************************************************)

StandardAcknowledgement ==
    [ outgoingMessagesHeader          : OutgoingMessagesHeader7,
      traderId                        : Sample(8),
      originalMessageTypeAfGzMlOxOrRq : Sample(2) ]

EncodeStandardAcknowledgement(message) ==
    EncodeOutgoingMessagesHeader7(message.outgoingMessagesHeader)
        \o message.traderId
        \o message.originalMessageTypeAfGzMlOxOrRq

DecodeStandardAcknowledgement(bytes) ==
    LET outgoingMessagesHeader == DecodeOutgoingMessagesHeader7(bytes) IN IF ~outgoingMessagesHeader.ok THEN Fail ELSE
    LET traderId == ReadBytes(outgoingMessagesHeader.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET originalMessageTypeAfGzMlOxOrRq == ReadBytes(traderId.rest, 2) IN IF ~originalMessageTypeAfGzMlOxOrRq.ok THEN Fail ELSE
    Ok([ outgoingMessagesHeader          |-> outgoingMessagesHeader.value,
         traderId                        |-> traderId.value,
         originalMessageTypeAfGzMlOxOrRq |-> originalMessageTypeAfGzMlOxOrRq.value ], originalMessageTypeAfGzMlOxOrRq.rest)

ZeroStandardAcknowledgement ==
    [ outgoingMessagesHeader          |-> ZeroOutgoingMessagesHeader7,
      traderId                        |-> [i \in 1 .. 8 |-> 0],
      originalMessageTypeAfGzMlOxOrRq |-> [i \in 1 .. 2 |-> 0] ]

(* Standard Acknowledgement at zero, then each field in turn at the values it is checked at *)
CheckedStandardAcknowledgement ==
    { ZeroStandardAcknowledgement }
        \cup { [ZeroStandardAcknowledgement EXCEPT !.outgoingMessagesHeader = one] : one \in CheckedOutgoingMessagesHeader7 }
        \cup { [ZeroStandardAcknowledgement EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroStandardAcknowledgement EXCEPT !.originalMessageTypeAfGzMlOxOrRq = one] : one \in Sample(2) }

(***************************************************************************)
(* Clearing Data: 20 bytes                                                 *)
(***************************************************************************)

ClearingData4 ==
    [ clearingInstruction : Sample(12),
      accountType         : Sample(1),
      openClose           : Sample(1),
      hedgeSpec           : Sample(1),
      filler5             : Sample(5) ]

EncodeClearingData4(message) ==
    message.clearingInstruction
        \o message.accountType
        \o message.openClose
        \o message.hedgeSpec
        \o message.filler5

DecodeClearingData4(bytes) ==
    LET clearingInstruction == ReadBytes(bytes, 12) IN IF ~clearingInstruction.ok THEN Fail ELSE
    LET accountType == ReadBytes(clearingInstruction.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET openClose == ReadBytes(accountType.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET hedgeSpec == ReadBytes(openClose.rest, 1) IN IF ~hedgeSpec.ok THEN Fail ELSE
    LET filler5 == ReadBytes(hedgeSpec.rest, 5) IN IF ~filler5.ok THEN Fail ELSE
    Ok([ clearingInstruction |-> clearingInstruction.value,
         accountType         |-> accountType.value,
         openClose           |-> openClose.value,
         hedgeSpec           |-> hedgeSpec.value,
         filler5             |-> filler5.value ], filler5.rest)

ZeroClearingData4 ==
    [ clearingInstruction |-> [i \in 1 .. 12 |-> 0],
      accountType         |-> [i \in 1 .. 1 |-> 0],
      openClose           |-> [i \in 1 .. 1 |-> 0],
      hedgeSpec           |-> [i \in 1 .. 1 |-> 0],
      filler5             |-> [i \in 1 .. 5 |-> 0] ]

(* Clearing Data at zero, then each field in turn at the values it is checked at *)
CheckedClearingData4 ==
    { ZeroClearingData4 }
        \cup { [ZeroClearingData4 EXCEPT !.clearingInstruction = one] : one \in Sample(12) }
        \cup { [ZeroClearingData4 EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroClearingData4 EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroClearingData4 EXCEPT !.hedgeSpec = one] : one \in Sample(1) }
        \cup { [ZeroClearingData4 EXCEPT !.filler5 = one] : one \in Sample(5) }

(***************************************************************************)
(* Owner Data: 50 bytes                                                    *)
(***************************************************************************)

OwnerData4 ==
    [ memo : Sample(50) ]

EncodeOwnerData4(message) ==
    message.memo

DecodeOwnerData4(bytes) ==
    LET memo == ReadBytes(bytes, 50) IN IF ~memo.ok THEN Fail ELSE
    Ok([ memo |-> memo.value ], memo.rest)

ZeroOwnerData4 ==
    [ memo |-> [i \in 1 .. 50 |-> 0] ]

(* Owner Data at zero, then each field in turn at the values it is checked at *)
CheckedOwnerData4 ==
    { ZeroOwnerData4 }
        \cup { [ZeroOwnerData4 EXCEPT !.memo = one] : one \in Sample(50) }

(***************************************************************************)
(* Order Cancellation Acknowledgement: 126 bytes                           *)
(***************************************************************************)

OrderCancellationAcknowledgement ==
    [ group           : Sample(2),
      instrument      : Sample(4),
      traderId        : Sample(8),
      orderId         : Sample(8),
      status          : Sample(1),
      verbSide        : Sample(1),
      quantity        : Sample(8),
      assignedPrice   : Sample(10),
      clearingData    : ClearingData4,
      ownerData       : OwnerData4,
      originalOrderId : Sample(8),
      filler6         : Sample(6) ]

EncodeOrderCancellationAcknowledgement(message) ==
    message.group
        \o message.instrument
        \o message.traderId
        \o message.orderId
        \o message.status
        \o message.verbSide
        \o message.quantity
        \o message.assignedPrice
        \o EncodeClearingData4(message.clearingData)
        \o EncodeOwnerData4(message.ownerData)
        \o message.originalOrderId
        \o message.filler6

DecodeOrderCancellationAcknowledgement(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrument == ReadBytes(group.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET traderId == ReadBytes(instrument.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET orderId == ReadBytes(traderId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET status == ReadBytes(orderId.rest, 1) IN IF ~status.ok THEN Fail ELSE
    LET verbSide == ReadBytes(status.rest, 1) IN IF ~verbSide.ok THEN Fail ELSE
    LET quantity == ReadBytes(verbSide.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET assignedPrice == ReadBytes(quantity.rest, 10) IN IF ~assignedPrice.ok THEN Fail ELSE
    LET clearingData == DecodeClearingData4(assignedPrice.rest) IN IF ~clearingData.ok THEN Fail ELSE
    LET ownerData == DecodeOwnerData4(clearingData.rest) IN IF ~ownerData.ok THEN Fail ELSE
    LET originalOrderId == ReadBytes(ownerData.rest, 8) IN IF ~originalOrderId.ok THEN Fail ELSE
    LET filler6 == ReadBytes(originalOrderId.rest, 6) IN IF ~filler6.ok THEN Fail ELSE
    Ok([ group           |-> group.value,
         instrument      |-> instrument.value,
         traderId        |-> traderId.value,
         orderId         |-> orderId.value,
         status          |-> status.value,
         verbSide        |-> verbSide.value,
         quantity        |-> quantity.value,
         assignedPrice   |-> assignedPrice.value,
         clearingData    |-> clearingData.value,
         ownerData       |-> ownerData.value,
         originalOrderId |-> originalOrderId.value,
         filler6         |-> filler6.value ], filler6.rest)

ZeroOrderCancellationAcknowledgement ==
    [ group           |-> [i \in 1 .. 2 |-> 0],
      instrument      |-> [i \in 1 .. 4 |-> 0],
      traderId        |-> [i \in 1 .. 8 |-> 0],
      orderId         |-> [i \in 1 .. 8 |-> 0],
      status          |-> [i \in 1 .. 1 |-> 0],
      verbSide        |-> [i \in 1 .. 1 |-> 0],
      quantity        |-> [i \in 1 .. 8 |-> 0],
      assignedPrice   |-> [i \in 1 .. 10 |-> 0],
      clearingData    |-> ZeroClearingData4,
      ownerData       |-> ZeroOwnerData4,
      originalOrderId |-> [i \in 1 .. 8 |-> 0],
      filler6         |-> [i \in 1 .. 6 |-> 0] ]

(* Order Cancellation Acknowledgement at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancellationAcknowledgement ==
    { ZeroOrderCancellationAcknowledgement }
        \cup { [ZeroOrderCancellationAcknowledgement EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancellationAcknowledgement EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancellationAcknowledgement EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancellationAcknowledgement EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancellationAcknowledgement EXCEPT !.status = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancellationAcknowledgement EXCEPT !.verbSide = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancellationAcknowledgement EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancellationAcknowledgement EXCEPT !.assignedPrice = one] : one \in Sample(10) }
        \cup { [ZeroOrderCancellationAcknowledgement EXCEPT !.clearingData = one] : one \in CheckedClearingData4 }
        \cup { [ZeroOrderCancellationAcknowledgement EXCEPT !.ownerData = one] : one \in CheckedOwnerData4 }
        \cup { [ZeroOrderCancellationAcknowledgement EXCEPT !.originalOrderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancellationAcknowledgement EXCEPT !.filler6 = one] : one \in Sample(6) }

(***************************************************************************)
(* Outgoing Messages Header: 22 bytes                                      *)
(***************************************************************************)

OutgoingMessagesHeader8 ==
    [ tradingEngineTimestampLocalHhmmss : Sample(6),
      userSequenceId                    : Sample(8),
      exchangeMessageId                 : Sample(6),
      gapSequenceId                     : Sample(2) ]

EncodeOutgoingMessagesHeader8(message) ==
    message.tradingEngineTimestampLocalHhmmss
        \o message.userSequenceId
        \o message.exchangeMessageId
        \o message.gapSequenceId

DecodeOutgoingMessagesHeader8(bytes) ==
    LET tradingEngineTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~tradingEngineTimestampLocalHhmmss.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(tradingEngineTimestampLocalHhmmss.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    LET exchangeMessageId == ReadBytes(userSequenceId.rest, 6) IN IF ~exchangeMessageId.ok THEN Fail ELSE
    LET gapSequenceId == ReadBytes(exchangeMessageId.rest, 2) IN IF ~gapSequenceId.ok THEN Fail ELSE
    Ok([ tradingEngineTimestampLocalHhmmss |-> tradingEngineTimestampLocalHhmmss.value,
         userSequenceId                    |-> userSequenceId.value,
         exchangeMessageId                 |-> exchangeMessageId.value,
         gapSequenceId                     |-> gapSequenceId.value ], gapSequenceId.rest)

ZeroOutgoingMessagesHeader8 ==
    [ tradingEngineTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      userSequenceId                    |-> [i \in 1 .. 8 |-> 0],
      exchangeMessageId                 |-> [i \in 1 .. 6 |-> 0],
      gapSequenceId                     |-> [i \in 1 .. 2 |-> 0] ]

(* Outgoing Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedOutgoingMessagesHeader8 ==
    { ZeroOutgoingMessagesHeader8 }
        \cup { [ZeroOutgoingMessagesHeader8 EXCEPT !.tradingEngineTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroOutgoingMessagesHeader8 EXCEPT !.userSequenceId = one] : one \in Sample(8) }
        \cup { [ZeroOutgoingMessagesHeader8 EXCEPT !.exchangeMessageId = one] : one \in Sample(6) }
        \cup { [ZeroOutgoingMessagesHeader8 EXCEPT !.gapSequenceId = one] : one \in Sample(2) }

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
    [ outgoingMessagesHeader             : OutgoingMessagesHeader8,
      group                              : Sample(2),
      quoteIdentifierOnThisGroup         : Sample(8),
      bulkQuoteAcknowledgementOccurrence : SampleLists(OneBulkQuoteAcknowledgementOccurrence) ]

EncodeBulkQuoteAcknowledgement(message) ==
    EncodeOutgoingMessagesHeader8(message.outgoingMessagesHeader)
        \o message.group
        \o message.quoteIdentifierOnThisGroup
        \o EncodeDigits(Len(message.bulkQuoteAcknowledgementOccurrence), 3)
        \o EncodeBulkQuoteAcknowledgementOccurrenceList(message.bulkQuoteAcknowledgementOccurrence)

DecodeBulkQuoteAcknowledgement(bytes) ==
    LET outgoingMessagesHeader == DecodeOutgoingMessagesHeader8(bytes) IN IF ~outgoingMessagesHeader.ok THEN Fail ELSE
    LET group == ReadBytes(outgoingMessagesHeader.rest, 2) IN IF ~group.ok THEN Fail ELSE
    LET quoteIdentifierOnThisGroup == ReadBytes(group.rest, 8) IN IF ~quoteIdentifierOnThisGroup.ok THEN Fail ELSE
    LET numberOfQuotesInError == ReadDigits(quoteIdentifierOnThisGroup.rest, 3) IN IF ~numberOfQuotesInError.ok THEN Fail ELSE
    LET bulkQuoteAcknowledgementOccurrence == ReadBulkQuoteAcknowledgementOccurrenceList(numberOfQuotesInError.rest, numberOfQuotesInError.value) IN IF ~bulkQuoteAcknowledgementOccurrence.ok THEN Fail ELSE
    Ok([ outgoingMessagesHeader             |-> outgoingMessagesHeader.value,
         group                              |-> group.value,
         quoteIdentifierOnThisGroup         |-> quoteIdentifierOnThisGroup.value,
         bulkQuoteAcknowledgementOccurrence |-> bulkQuoteAcknowledgementOccurrence.value ], bulkQuoteAcknowledgementOccurrence.rest)

ZeroBulkQuoteAcknowledgement ==
    [ outgoingMessagesHeader             |-> ZeroOutgoingMessagesHeader8,
      group                              |-> [i \in 1 .. 2 |-> 0],
      quoteIdentifierOnThisGroup         |-> [i \in 1 .. 8 |-> 0],
      bulkQuoteAcknowledgementOccurrence |-> << >> ]

(* Bulk Quote Acknowledgement at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuoteAcknowledgement ==
    { ZeroBulkQuoteAcknowledgement }
        \cup { [ZeroBulkQuoteAcknowledgement EXCEPT !.outgoingMessagesHeader = one] : one \in CheckedOutgoingMessagesHeader8 }
        \cup { [ZeroBulkQuoteAcknowledgement EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuoteAcknowledgement EXCEPT !.quoteIdentifierOnThisGroup = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuoteAcknowledgement EXCEPT !.bulkQuoteAcknowledgementOccurrence = one] : one \in SampleLists(OneBulkQuoteAcknowledgementOccurrence) }

(***************************************************************************)
(* Outgoing Messages Header: 22 bytes                                      *)
(***************************************************************************)

OutgoingMessagesHeader9 ==
    [ tradingEngineTimestampLocalHhmmss : Sample(6),
      userSequenceId                    : Sample(8),
      exchangeMessageId                 : Sample(6),
      gapSequenceId                     : Sample(2) ]

EncodeOutgoingMessagesHeader9(message) ==
    message.tradingEngineTimestampLocalHhmmss
        \o message.userSequenceId
        \o message.exchangeMessageId
        \o message.gapSequenceId

DecodeOutgoingMessagesHeader9(bytes) ==
    LET tradingEngineTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~tradingEngineTimestampLocalHhmmss.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(tradingEngineTimestampLocalHhmmss.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    LET exchangeMessageId == ReadBytes(userSequenceId.rest, 6) IN IF ~exchangeMessageId.ok THEN Fail ELSE
    LET gapSequenceId == ReadBytes(exchangeMessageId.rest, 2) IN IF ~gapSequenceId.ok THEN Fail ELSE
    Ok([ tradingEngineTimestampLocalHhmmss |-> tradingEngineTimestampLocalHhmmss.value,
         userSequenceId                    |-> userSequenceId.value,
         exchangeMessageId                 |-> exchangeMessageId.value,
         gapSequenceId                     |-> gapSequenceId.value ], gapSequenceId.rest)

ZeroOutgoingMessagesHeader9 ==
    [ tradingEngineTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      userSequenceId                    |-> [i \in 1 .. 8 |-> 0],
      exchangeMessageId                 |-> [i \in 1 .. 6 |-> 0],
      gapSequenceId                     |-> [i \in 1 .. 2 |-> 0] ]

(* Outgoing Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedOutgoingMessagesHeader9 ==
    { ZeroOutgoingMessagesHeader9 }
        \cup { [ZeroOutgoingMessagesHeader9 EXCEPT !.tradingEngineTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroOutgoingMessagesHeader9 EXCEPT !.userSequenceId = one] : one \in Sample(8) }
        \cup { [ZeroOutgoingMessagesHeader9 EXCEPT !.exchangeMessageId = one] : one \in Sample(6) }
        \cup { [ZeroOutgoingMessagesHeader9 EXCEPT !.gapSequenceId = one] : one \in Sample(2) }

(***************************************************************************)
(* Bulk Command Acknowledgement Occurrence: 8 bytes                        *)
(***************************************************************************)

BulkCommandAcknowledgementOccurrence ==
    [ commandNumber : Sample(4),
      errorCode     : Sample(4) ]

EncodeBulkCommandAcknowledgementOccurrence(message) ==
    message.commandNumber
        \o message.errorCode

DecodeBulkCommandAcknowledgementOccurrence(bytes) ==
    LET commandNumber == ReadBytes(bytes, 4) IN IF ~commandNumber.ok THEN Fail ELSE
    LET errorCode == ReadBytes(commandNumber.rest, 4) IN IF ~errorCode.ok THEN Fail ELSE
    Ok([ commandNumber |-> commandNumber.value,
         errorCode     |-> errorCode.value ], errorCode.rest)

ZeroBulkCommandAcknowledgementOccurrence ==
    [ commandNumber |-> [i \in 1 .. 4 |-> 0],
      errorCode     |-> [i \in 1 .. 4 |-> 0] ]

(* Bulk Command Acknowledgement Occurrence at zero, then each field in turn at the values it is checked at *)
CheckedBulkCommandAcknowledgementOccurrence ==
    { ZeroBulkCommandAcknowledgementOccurrence }
        \cup { [ZeroBulkCommandAcknowledgementOccurrence EXCEPT !.commandNumber = one] : one \in Sample(4) }
        \cup { [ZeroBulkCommandAcknowledgementOccurrence EXCEPT !.errorCode = one] : one \in Sample(4) }

(* A run of Bulk Command Acknowledgement Occurrence, written one after another *)
RECURSIVE EncodeBulkCommandAcknowledgementOccurrenceList(_)
EncodeBulkCommandAcknowledgementOccurrenceList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeBulkCommandAcknowledgementOccurrence(Head(messages)) \o EncodeBulkCommandAcknowledgementOccurrenceList(Tail(messages))

(* As many Bulk Command Acknowledgement Occurrence as the field that counts them says *)
RECURSIVE ReadBulkCommandAcknowledgementOccurrenceList(_, _)
ReadBulkCommandAcknowledgementOccurrenceList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeBulkCommandAcknowledgementOccurrence(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadBulkCommandAcknowledgementOccurrenceList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Bulk Command Acknowledgement Occurrence of each kind, for the lists that carry them *)
OneBulkCommandAcknowledgementOccurrence == { ZeroBulkCommandAcknowledgementOccurrence }

(***************************************************************************)
(* Bulk Command Acknowledgement                                            *)
(***************************************************************************)

BulkCommandAcknowledgement ==
    [ outgoingMessagesHeader               : OutgoingMessagesHeader9,
      bulkCommandAcknowledgementOccurrence : SampleLists(OneBulkCommandAcknowledgementOccurrence) ]

EncodeBulkCommandAcknowledgement(message) ==
    EncodeOutgoingMessagesHeader9(message.outgoingMessagesHeader)
        \o EncodeDigits(Len(message.bulkCommandAcknowledgementOccurrence), 4)
        \o EncodeBulkCommandAcknowledgementOccurrenceList(message.bulkCommandAcknowledgementOccurrence)

DecodeBulkCommandAcknowledgement(bytes) ==
    LET outgoingMessagesHeader == DecodeOutgoingMessagesHeader9(bytes) IN IF ~outgoingMessagesHeader.ok THEN Fail ELSE
    LET numberOfCommands == ReadDigits(outgoingMessagesHeader.rest, 4) IN IF ~numberOfCommands.ok THEN Fail ELSE
    LET bulkCommandAcknowledgementOccurrence == ReadBulkCommandAcknowledgementOccurrenceList(numberOfCommands.rest, numberOfCommands.value) IN IF ~bulkCommandAcknowledgementOccurrence.ok THEN Fail ELSE
    Ok([ outgoingMessagesHeader               |-> outgoingMessagesHeader.value,
         bulkCommandAcknowledgementOccurrence |-> bulkCommandAcknowledgementOccurrence.value ], bulkCommandAcknowledgementOccurrence.rest)

ZeroBulkCommandAcknowledgement ==
    [ outgoingMessagesHeader               |-> ZeroOutgoingMessagesHeader9,
      bulkCommandAcknowledgementOccurrence |-> << >> ]

(* Bulk Command Acknowledgement at zero, then each field in turn at the values it is checked at *)
CheckedBulkCommandAcknowledgement ==
    { ZeroBulkCommandAcknowledgement }
        \cup { [ZeroBulkCommandAcknowledgement EXCEPT !.outgoingMessagesHeader = one] : one \in CheckedOutgoingMessagesHeader9 }
        \cup { [ZeroBulkCommandAcknowledgement EXCEPT !.bulkCommandAcknowledgementOccurrence = one] : one \in SampleLists(OneBulkCommandAcknowledgementOccurrence) }

(***************************************************************************)
(* Outgoing Messages Header: 22 bytes                                      *)
(***************************************************************************)

OutgoingMessagesHeader10 ==
    [ tradingEngineTimestampLocalHhmmss : Sample(6),
      userSequenceId                    : Sample(8),
      exchangeMessageId                 : Sample(6),
      gapSequenceId                     : Sample(2) ]

EncodeOutgoingMessagesHeader10(message) ==
    message.tradingEngineTimestampLocalHhmmss
        \o message.userSequenceId
        \o message.exchangeMessageId
        \o message.gapSequenceId

DecodeOutgoingMessagesHeader10(bytes) ==
    LET tradingEngineTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~tradingEngineTimestampLocalHhmmss.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(tradingEngineTimestampLocalHhmmss.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    LET exchangeMessageId == ReadBytes(userSequenceId.rest, 6) IN IF ~exchangeMessageId.ok THEN Fail ELSE
    LET gapSequenceId == ReadBytes(exchangeMessageId.rest, 2) IN IF ~gapSequenceId.ok THEN Fail ELSE
    Ok([ tradingEngineTimestampLocalHhmmss |-> tradingEngineTimestampLocalHhmmss.value,
         userSequenceId                    |-> userSequenceId.value,
         exchangeMessageId                 |-> exchangeMessageId.value,
         gapSequenceId                     |-> gapSequenceId.value ], gapSequenceId.rest)

ZeroOutgoingMessagesHeader10 ==
    [ tradingEngineTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      userSequenceId                    |-> [i \in 1 .. 8 |-> 0],
      exchangeMessageId                 |-> [i \in 1 .. 6 |-> 0],
      gapSequenceId                     |-> [i \in 1 .. 2 |-> 0] ]

(* Outgoing Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedOutgoingMessagesHeader10 ==
    { ZeroOutgoingMessagesHeader10 }
        \cup { [ZeroOutgoingMessagesHeader10 EXCEPT !.tradingEngineTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroOutgoingMessagesHeader10 EXCEPT !.userSequenceId = one] : one \in Sample(8) }
        \cup { [ZeroOutgoingMessagesHeader10 EXCEPT !.exchangeMessageId = one] : one \in Sample(6) }
        \cup { [ZeroOutgoingMessagesHeader10 EXCEPT !.gapSequenceId = one] : one \in Sample(2) }

(***************************************************************************)
(* Risk Limits Usage Occurrence: 28 bytes                                  *)
(***************************************************************************)

RiskLimitsUsageOccurrence ==
    [ trader       : Sample(4),
      group        : Sample(2),
      usageStatus  : Sample(1),
      limitType    : Sample(1),
      currentUsage : Sample(10),
      limitValue   : Sample(10) ]

EncodeRiskLimitsUsageOccurrence(message) ==
    message.trader
        \o message.group
        \o message.usageStatus
        \o message.limitType
        \o message.currentUsage
        \o message.limitValue

DecodeRiskLimitsUsageOccurrence(bytes) ==
    LET trader == ReadBytes(bytes, 4) IN IF ~trader.ok THEN Fail ELSE
    LET group == ReadBytes(trader.rest, 2) IN IF ~group.ok THEN Fail ELSE
    LET usageStatus == ReadBytes(group.rest, 1) IN IF ~usageStatus.ok THEN Fail ELSE
    LET limitType == ReadBytes(usageStatus.rest, 1) IN IF ~limitType.ok THEN Fail ELSE
    LET currentUsage == ReadBytes(limitType.rest, 10) IN IF ~currentUsage.ok THEN Fail ELSE
    LET limitValue == ReadBytes(currentUsage.rest, 10) IN IF ~limitValue.ok THEN Fail ELSE
    Ok([ trader       |-> trader.value,
         group        |-> group.value,
         usageStatus  |-> usageStatus.value,
         limitType    |-> limitType.value,
         currentUsage |-> currentUsage.value,
         limitValue   |-> limitValue.value ], limitValue.rest)

ZeroRiskLimitsUsageOccurrence ==
    [ trader       |-> [i \in 1 .. 4 |-> 0],
      group        |-> [i \in 1 .. 2 |-> 0],
      usageStatus  |-> [i \in 1 .. 1 |-> 0],
      limitType    |-> [i \in 1 .. 1 |-> 0],
      currentUsage |-> [i \in 1 .. 10 |-> 0],
      limitValue   |-> [i \in 1 .. 10 |-> 0] ]

(* Risk Limits Usage Occurrence at zero, then each field in turn at the values it is checked at *)
CheckedRiskLimitsUsageOccurrence ==
    { ZeroRiskLimitsUsageOccurrence }
        \cup { [ZeroRiskLimitsUsageOccurrence EXCEPT !.trader = one] : one \in Sample(4) }
        \cup { [ZeroRiskLimitsUsageOccurrence EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroRiskLimitsUsageOccurrence EXCEPT !.usageStatus = one] : one \in Sample(1) }
        \cup { [ZeroRiskLimitsUsageOccurrence EXCEPT !.limitType = one] : one \in Sample(1) }
        \cup { [ZeroRiskLimitsUsageOccurrence EXCEPT !.currentUsage = one] : one \in Sample(10) }
        \cup { [ZeroRiskLimitsUsageOccurrence EXCEPT !.limitValue = one] : one \in Sample(10) }

(* A run of Risk Limits Usage Occurrence, written one after another *)
RECURSIVE EncodeRiskLimitsUsageOccurrenceList(_)
EncodeRiskLimitsUsageOccurrenceList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeRiskLimitsUsageOccurrence(Head(messages)) \o EncodeRiskLimitsUsageOccurrenceList(Tail(messages))

(* As many Risk Limits Usage Occurrence as the field that counts them says *)
RECURSIVE ReadRiskLimitsUsageOccurrenceList(_, _)
ReadRiskLimitsUsageOccurrenceList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeRiskLimitsUsageOccurrence(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadRiskLimitsUsageOccurrenceList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Risk Limits Usage Occurrence of each kind, for the lists that carry them *)
OneRiskLimitsUsageOccurrence == { ZeroRiskLimitsUsageOccurrence }

(***************************************************************************)
(* Risk Limits Usage                                                       *)
(***************************************************************************)

RiskLimitsUsage ==
    [ outgoingMessagesHeader    : OutgoingMessagesHeader10,
      riskLimitsUsageOccurrence : SampleLists(OneRiskLimitsUsageOccurrence) ]

EncodeRiskLimitsUsage(message) ==
    EncodeOutgoingMessagesHeader10(message.outgoingMessagesHeader)
        \o EncodeDigits(Len(message.riskLimitsUsageOccurrence), 4)
        \o EncodeRiskLimitsUsageOccurrenceList(message.riskLimitsUsageOccurrence)

DecodeRiskLimitsUsage(bytes) ==
    LET outgoingMessagesHeader == DecodeOutgoingMessagesHeader10(bytes) IN IF ~outgoingMessagesHeader.ok THEN Fail ELSE
    LET numberOfUsageBlocks == ReadDigits(outgoingMessagesHeader.rest, 4) IN IF ~numberOfUsageBlocks.ok THEN Fail ELSE
    LET riskLimitsUsageOccurrence == ReadRiskLimitsUsageOccurrenceList(numberOfUsageBlocks.rest, numberOfUsageBlocks.value) IN IF ~riskLimitsUsageOccurrence.ok THEN Fail ELSE
    Ok([ outgoingMessagesHeader    |-> outgoingMessagesHeader.value,
         riskLimitsUsageOccurrence |-> riskLimitsUsageOccurrence.value ], riskLimitsUsageOccurrence.rest)

ZeroRiskLimitsUsage ==
    [ outgoingMessagesHeader    |-> ZeroOutgoingMessagesHeader10,
      riskLimitsUsageOccurrence |-> << >> ]

(* Risk Limits Usage at zero, then each field in turn at the values it is checked at *)
CheckedRiskLimitsUsage ==
    { ZeroRiskLimitsUsage }
        \cup { [ZeroRiskLimitsUsage EXCEPT !.outgoingMessagesHeader = one] : one \in CheckedOutgoingMessagesHeader10 }
        \cup { [ZeroRiskLimitsUsage EXCEPT !.riskLimitsUsageOccurrence = one] : one \in SampleLists(OneRiskLimitsUsageOccurrence) }

(***************************************************************************)
(* Outgoing Messages Header: 22 bytes                                      *)
(***************************************************************************)

OutgoingMessagesHeader11 ==
    [ tradingEngineTimestampLocalHhmmss : Sample(6),
      userSequenceId                    : Sample(8),
      exchangeMessageId                 : Sample(6),
      gapSequenceId                     : Sample(2) ]

EncodeOutgoingMessagesHeader11(message) ==
    message.tradingEngineTimestampLocalHhmmss
        \o message.userSequenceId
        \o message.exchangeMessageId
        \o message.gapSequenceId

DecodeOutgoingMessagesHeader11(bytes) ==
    LET tradingEngineTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~tradingEngineTimestampLocalHhmmss.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(tradingEngineTimestampLocalHhmmss.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    LET exchangeMessageId == ReadBytes(userSequenceId.rest, 6) IN IF ~exchangeMessageId.ok THEN Fail ELSE
    LET gapSequenceId == ReadBytes(exchangeMessageId.rest, 2) IN IF ~gapSequenceId.ok THEN Fail ELSE
    Ok([ tradingEngineTimestampLocalHhmmss |-> tradingEngineTimestampLocalHhmmss.value,
         userSequenceId                    |-> userSequenceId.value,
         exchangeMessageId                 |-> exchangeMessageId.value,
         gapSequenceId                     |-> gapSequenceId.value ], gapSequenceId.rest)

ZeroOutgoingMessagesHeader11 ==
    [ tradingEngineTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      userSequenceId                    |-> [i \in 1 .. 8 |-> 0],
      exchangeMessageId                 |-> [i \in 1 .. 6 |-> 0],
      gapSequenceId                     |-> [i \in 1 .. 2 |-> 0] ]

(* Outgoing Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedOutgoingMessagesHeader11 ==
    { ZeroOutgoingMessagesHeader11 }
        \cup { [ZeroOutgoingMessagesHeader11 EXCEPT !.tradingEngineTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroOutgoingMessagesHeader11 EXCEPT !.userSequenceId = one] : one \in Sample(8) }
        \cup { [ZeroOutgoingMessagesHeader11 EXCEPT !.exchangeMessageId = one] : one \in Sample(6) }
        \cup { [ZeroOutgoingMessagesHeader11 EXCEPT !.gapSequenceId = one] : one \in Sample(2) }

(***************************************************************************)
(* Excluded Instrument Notice Occurrence: 4 bytes                          *)
(***************************************************************************)

ExcludedInstrumentNoticeOccurrence ==
    [ instrument : Sample(4) ]

EncodeExcludedInstrumentNoticeOccurrence(message) ==
    message.instrument

DecodeExcludedInstrumentNoticeOccurrence(bytes) ==
    LET instrument == ReadBytes(bytes, 4) IN IF ~instrument.ok THEN Fail ELSE
    Ok([ instrument |-> instrument.value ], instrument.rest)

ZeroExcludedInstrumentNoticeOccurrence ==
    [ instrument |-> [i \in 1 .. 4 |-> 0] ]

(* Excluded Instrument Notice Occurrence at zero, then each field in turn at the values it is checked at *)
CheckedExcludedInstrumentNoticeOccurrence ==
    { ZeroExcludedInstrumentNoticeOccurrence }
        \cup { [ZeroExcludedInstrumentNoticeOccurrence EXCEPT !.instrument = one] : one \in Sample(4) }

(* A run of Excluded Instrument Notice Occurrence, written one after another *)
RECURSIVE EncodeExcludedInstrumentNoticeOccurrenceList(_)
EncodeExcludedInstrumentNoticeOccurrenceList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeExcludedInstrumentNoticeOccurrence(Head(messages)) \o EncodeExcludedInstrumentNoticeOccurrenceList(Tail(messages))

(* As many Excluded Instrument Notice Occurrence as the field that counts them says *)
RECURSIVE ReadExcludedInstrumentNoticeOccurrenceList(_, _)
ReadExcludedInstrumentNoticeOccurrenceList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeExcludedInstrumentNoticeOccurrence(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadExcludedInstrumentNoticeOccurrenceList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Excluded Instrument Notice Occurrence of each kind, for the lists that carry them *)
OneExcludedInstrumentNoticeOccurrence == { ZeroExcludedInstrumentNoticeOccurrence }

(***************************************************************************)
(* Excluded Instrument Notice                                              *)
(***************************************************************************)

ExcludedInstrumentNotice ==
    [ outgoingMessagesHeader             : OutgoingMessagesHeader11,
      group                              : Sample(2),
      filler2                            : Sample(2),
      traderId                           : Sample(8),
      filler4                            : Sample(4),
      excludedInstrumentNoticeOccurrence : SampleLists(OneExcludedInstrumentNoticeOccurrence) ]

EncodeExcludedInstrumentNotice(message) ==
    EncodeOutgoingMessagesHeader11(message.outgoingMessagesHeader)
        \o message.group
        \o message.filler2
        \o message.traderId
        \o message.filler4
        \o EncodeDigits(Len(message.excludedInstrumentNoticeOccurrence), 4)
        \o EncodeExcludedInstrumentNoticeOccurrenceList(message.excludedInstrumentNoticeOccurrence)

DecodeExcludedInstrumentNotice(bytes) ==
    LET outgoingMessagesHeader == DecodeOutgoingMessagesHeader11(bytes) IN IF ~outgoingMessagesHeader.ok THEN Fail ELSE
    LET group == ReadBytes(outgoingMessagesHeader.rest, 2) IN IF ~group.ok THEN Fail ELSE
    LET filler2 == ReadBytes(group.rest, 2) IN IF ~filler2.ok THEN Fail ELSE
    LET traderId == ReadBytes(filler2.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET filler4 == ReadBytes(traderId.rest, 4) IN IF ~filler4.ok THEN Fail ELSE
    LET nbOfInstruments == ReadDigits(filler4.rest, 4) IN IF ~nbOfInstruments.ok THEN Fail ELSE
    LET excludedInstrumentNoticeOccurrence == ReadExcludedInstrumentNoticeOccurrenceList(nbOfInstruments.rest, nbOfInstruments.value) IN IF ~excludedInstrumentNoticeOccurrence.ok THEN Fail ELSE
    Ok([ outgoingMessagesHeader             |-> outgoingMessagesHeader.value,
         group                              |-> group.value,
         filler2                            |-> filler2.value,
         traderId                           |-> traderId.value,
         filler4                            |-> filler4.value,
         excludedInstrumentNoticeOccurrence |-> excludedInstrumentNoticeOccurrence.value ], excludedInstrumentNoticeOccurrence.rest)

ZeroExcludedInstrumentNotice ==
    [ outgoingMessagesHeader             |-> ZeroOutgoingMessagesHeader11,
      group                              |-> [i \in 1 .. 2 |-> 0],
      filler2                            |-> [i \in 1 .. 2 |-> 0],
      traderId                           |-> [i \in 1 .. 8 |-> 0],
      filler4                            |-> [i \in 1 .. 4 |-> 0],
      excludedInstrumentNoticeOccurrence |-> << >> ]

(* Excluded Instrument Notice at zero, then each field in turn at the values it is checked at *)
CheckedExcludedInstrumentNotice ==
    { ZeroExcludedInstrumentNotice }
        \cup { [ZeroExcludedInstrumentNotice EXCEPT !.outgoingMessagesHeader = one] : one \in CheckedOutgoingMessagesHeader11 }
        \cup { [ZeroExcludedInstrumentNotice EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroExcludedInstrumentNotice EXCEPT !.filler2 = one] : one \in Sample(2) }
        \cup { [ZeroExcludedInstrumentNotice EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroExcludedInstrumentNotice EXCEPT !.filler4 = one] : one \in Sample(4) }
        \cup { [ZeroExcludedInstrumentNotice EXCEPT !.excludedInstrumentNoticeOccurrence = one] : one \in SampleLists(OneExcludedInstrumentNoticeOccurrence) }

(***************************************************************************)
(* Outgoing Messages Header: 22 bytes                                      *)
(***************************************************************************)

OutgoingMessagesHeader12 ==
    [ tradingEngineTimestampLocalHhmmss : Sample(6),
      userSequenceId                    : Sample(8),
      exchangeMessageId                 : Sample(6),
      gapSequenceId                     : Sample(2) ]

EncodeOutgoingMessagesHeader12(message) ==
    message.tradingEngineTimestampLocalHhmmss
        \o message.userSequenceId
        \o message.exchangeMessageId
        \o message.gapSequenceId

DecodeOutgoingMessagesHeader12(bytes) ==
    LET tradingEngineTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~tradingEngineTimestampLocalHhmmss.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(tradingEngineTimestampLocalHhmmss.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    LET exchangeMessageId == ReadBytes(userSequenceId.rest, 6) IN IF ~exchangeMessageId.ok THEN Fail ELSE
    LET gapSequenceId == ReadBytes(exchangeMessageId.rest, 2) IN IF ~gapSequenceId.ok THEN Fail ELSE
    Ok([ tradingEngineTimestampLocalHhmmss |-> tradingEngineTimestampLocalHhmmss.value,
         userSequenceId                    |-> userSequenceId.value,
         exchangeMessageId                 |-> exchangeMessageId.value,
         gapSequenceId                     |-> gapSequenceId.value ], gapSequenceId.rest)

ZeroOutgoingMessagesHeader12 ==
    [ tradingEngineTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      userSequenceId                    |-> [i \in 1 .. 8 |-> 0],
      exchangeMessageId                 |-> [i \in 1 .. 6 |-> 0],
      gapSequenceId                     |-> [i \in 1 .. 2 |-> 0] ]

(* Outgoing Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedOutgoingMessagesHeader12 ==
    { ZeroOutgoingMessagesHeader12 }
        \cup { [ZeroOutgoingMessagesHeader12 EXCEPT !.tradingEngineTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroOutgoingMessagesHeader12 EXCEPT !.userSequenceId = one] : one \in Sample(8) }
        \cup { [ZeroOutgoingMessagesHeader12 EXCEPT !.exchangeMessageId = one] : one \in Sample(6) }
        \cup { [ZeroOutgoingMessagesHeader12 EXCEPT !.gapSequenceId = one] : one \in Sample(2) }

(***************************************************************************)
(* Group State Change: 25 bytes                                            *)
(***************************************************************************)

GroupStateChange ==
    [ outgoingMessagesHeader : OutgoingMessagesHeader12,
      group                  : Sample(2),
      groupState             : Sample(1) ]

EncodeGroupStateChange(message) ==
    EncodeOutgoingMessagesHeader12(message.outgoingMessagesHeader)
        \o message.group
        \o message.groupState

DecodeGroupStateChange(bytes) ==
    LET outgoingMessagesHeader == DecodeOutgoingMessagesHeader12(bytes) IN IF ~outgoingMessagesHeader.ok THEN Fail ELSE
    LET group == ReadBytes(outgoingMessagesHeader.rest, 2) IN IF ~group.ok THEN Fail ELSE
    LET groupState == ReadBytes(group.rest, 1) IN IF ~groupState.ok THEN Fail ELSE
    Ok([ outgoingMessagesHeader |-> outgoingMessagesHeader.value,
         group                  |-> group.value,
         groupState             |-> groupState.value ], groupState.rest)

ZeroGroupStateChange ==
    [ outgoingMessagesHeader |-> ZeroOutgoingMessagesHeader12,
      group                  |-> [i \in 1 .. 2 |-> 0],
      groupState             |-> [i \in 1 .. 1 |-> 0] ]

(* Group State Change at zero, then each field in turn at the values it is checked at *)
CheckedGroupStateChange ==
    { ZeroGroupStateChange }
        \cup { [ZeroGroupStateChange EXCEPT !.outgoingMessagesHeader = one] : one \in CheckedOutgoingMessagesHeader12 }
        \cup { [ZeroGroupStateChange EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroGroupStateChange EXCEPT !.groupState = one] : one \in Sample(1) }

(***************************************************************************)
(* Outgoing Messages Header: 22 bytes                                      *)
(***************************************************************************)

OutgoingMessagesHeader13 ==
    [ tradingEngineTimestampLocalHhmmss : Sample(6),
      userSequenceId                    : Sample(8),
      exchangeMessageId                 : Sample(6),
      gapSequenceId                     : Sample(2) ]

EncodeOutgoingMessagesHeader13(message) ==
    message.tradingEngineTimestampLocalHhmmss
        \o message.userSequenceId
        \o message.exchangeMessageId
        \o message.gapSequenceId

DecodeOutgoingMessagesHeader13(bytes) ==
    LET tradingEngineTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~tradingEngineTimestampLocalHhmmss.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(tradingEngineTimestampLocalHhmmss.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    LET exchangeMessageId == ReadBytes(userSequenceId.rest, 6) IN IF ~exchangeMessageId.ok THEN Fail ELSE
    LET gapSequenceId == ReadBytes(exchangeMessageId.rest, 2) IN IF ~gapSequenceId.ok THEN Fail ELSE
    Ok([ tradingEngineTimestampLocalHhmmss |-> tradingEngineTimestampLocalHhmmss.value,
         userSequenceId                    |-> userSequenceId.value,
         exchangeMessageId                 |-> exchangeMessageId.value,
         gapSequenceId                     |-> gapSequenceId.value ], gapSequenceId.rest)

ZeroOutgoingMessagesHeader13 ==
    [ tradingEngineTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      userSequenceId                    |-> [i \in 1 .. 8 |-> 0],
      exchangeMessageId                 |-> [i \in 1 .. 6 |-> 0],
      gapSequenceId                     |-> [i \in 1 .. 2 |-> 0] ]

(* Outgoing Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedOutgoingMessagesHeader13 ==
    { ZeroOutgoingMessagesHeader13 }
        \cup { [ZeroOutgoingMessagesHeader13 EXCEPT !.tradingEngineTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroOutgoingMessagesHeader13 EXCEPT !.userSequenceId = one] : one \in Sample(8) }
        \cup { [ZeroOutgoingMessagesHeader13 EXCEPT !.exchangeMessageId = one] : one \in Sample(6) }
        \cup { [ZeroOutgoingMessagesHeader13 EXCEPT !.gapSequenceId = one] : one \in Sample(2) }

(***************************************************************************)
(* Instrument State Change: 29 bytes                                       *)
(***************************************************************************)

InstrumentStateChange ==
    [ outgoingMessagesHeader : OutgoingMessagesHeader13,
      group                  : Sample(2),
      instrument             : Sample(4),
      instrumentState        : Sample(1) ]

EncodeInstrumentStateChange(message) ==
    EncodeOutgoingMessagesHeader13(message.outgoingMessagesHeader)
        \o message.group
        \o message.instrument
        \o message.instrumentState

DecodeInstrumentStateChange(bytes) ==
    LET outgoingMessagesHeader == DecodeOutgoingMessagesHeader13(bytes) IN IF ~outgoingMessagesHeader.ok THEN Fail ELSE
    LET group == ReadBytes(outgoingMessagesHeader.rest, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrument == ReadBytes(group.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET instrumentState == ReadBytes(instrument.rest, 1) IN IF ~instrumentState.ok THEN Fail ELSE
    Ok([ outgoingMessagesHeader |-> outgoingMessagesHeader.value,
         group                  |-> group.value,
         instrument             |-> instrument.value,
         instrumentState        |-> instrumentState.value ], instrumentState.rest)

ZeroInstrumentStateChange ==
    [ outgoingMessagesHeader |-> ZeroOutgoingMessagesHeader13,
      group                  |-> [i \in 1 .. 2 |-> 0],
      instrument             |-> [i \in 1 .. 4 |-> 0],
      instrumentState        |-> [i \in 1 .. 1 |-> 0] ]

(* Instrument State Change at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentStateChange ==
    { ZeroInstrumentStateChange }
        \cup { [ZeroInstrumentStateChange EXCEPT !.outgoingMessagesHeader = one] : one \in CheckedOutgoingMessagesHeader13 }
        \cup { [ZeroInstrumentStateChange EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentStateChange EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentStateChange EXCEPT !.instrumentState = one] : one \in Sample(1) }

(***************************************************************************)
(* Outgoing Messages Header: 22 bytes                                      *)
(***************************************************************************)

OutgoingMessagesHeader14 ==
    [ tradingEngineTimestampLocalHhmmss : Sample(6),
      userSequenceId                    : Sample(8),
      exchangeMessageId                 : Sample(6),
      gapSequenceId                     : Sample(2) ]

EncodeOutgoingMessagesHeader14(message) ==
    message.tradingEngineTimestampLocalHhmmss
        \o message.userSequenceId
        \o message.exchangeMessageId
        \o message.gapSequenceId

DecodeOutgoingMessagesHeader14(bytes) ==
    LET tradingEngineTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~tradingEngineTimestampLocalHhmmss.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(tradingEngineTimestampLocalHhmmss.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    LET exchangeMessageId == ReadBytes(userSequenceId.rest, 6) IN IF ~exchangeMessageId.ok THEN Fail ELSE
    LET gapSequenceId == ReadBytes(exchangeMessageId.rest, 2) IN IF ~gapSequenceId.ok THEN Fail ELSE
    Ok([ tradingEngineTimestampLocalHhmmss |-> tradingEngineTimestampLocalHhmmss.value,
         userSequenceId                    |-> userSequenceId.value,
         exchangeMessageId                 |-> exchangeMessageId.value,
         gapSequenceId                     |-> gapSequenceId.value ], gapSequenceId.rest)

ZeroOutgoingMessagesHeader14 ==
    [ tradingEngineTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      userSequenceId                    |-> [i \in 1 .. 8 |-> 0],
      exchangeMessageId                 |-> [i \in 1 .. 6 |-> 0],
      gapSequenceId                     |-> [i \in 1 .. 2 |-> 0] ]

(* Outgoing Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedOutgoingMessagesHeader14 ==
    { ZeroOutgoingMessagesHeader14 }
        \cup { [ZeroOutgoingMessagesHeader14 EXCEPT !.tradingEngineTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroOutgoingMessagesHeader14 EXCEPT !.userSequenceId = one] : one \in Sample(8) }
        \cup { [ZeroOutgoingMessagesHeader14 EXCEPT !.exchangeMessageId = one] : one \in Sample(6) }
        \cup { [ZeroOutgoingMessagesHeader14 EXCEPT !.gapSequenceId = one] : one \in Sample(2) }

(***************************************************************************)
(* Clearing Data: 20 bytes                                                 *)
(***************************************************************************)

ClearingData5 ==
    [ clearingInstruction : Sample(12),
      accountType         : Sample(1),
      openClose           : Sample(1),
      hedgeSpec           : Sample(1),
      filler5             : Sample(5) ]

EncodeClearingData5(message) ==
    message.clearingInstruction
        \o message.accountType
        \o message.openClose
        \o message.hedgeSpec
        \o message.filler5

DecodeClearingData5(bytes) ==
    LET clearingInstruction == ReadBytes(bytes, 12) IN IF ~clearingInstruction.ok THEN Fail ELSE
    LET accountType == ReadBytes(clearingInstruction.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET openClose == ReadBytes(accountType.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET hedgeSpec == ReadBytes(openClose.rest, 1) IN IF ~hedgeSpec.ok THEN Fail ELSE
    LET filler5 == ReadBytes(hedgeSpec.rest, 5) IN IF ~filler5.ok THEN Fail ELSE
    Ok([ clearingInstruction |-> clearingInstruction.value,
         accountType         |-> accountType.value,
         openClose           |-> openClose.value,
         hedgeSpec           |-> hedgeSpec.value,
         filler5             |-> filler5.value ], filler5.rest)

ZeroClearingData5 ==
    [ clearingInstruction |-> [i \in 1 .. 12 |-> 0],
      accountType         |-> [i \in 1 .. 1 |-> 0],
      openClose           |-> [i \in 1 .. 1 |-> 0],
      hedgeSpec           |-> [i \in 1 .. 1 |-> 0],
      filler5             |-> [i \in 1 .. 5 |-> 0] ]

(* Clearing Data at zero, then each field in turn at the values it is checked at *)
CheckedClearingData5 ==
    { ZeroClearingData5 }
        \cup { [ZeroClearingData5 EXCEPT !.clearingInstruction = one] : one \in Sample(12) }
        \cup { [ZeroClearingData5 EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroClearingData5 EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroClearingData5 EXCEPT !.hedgeSpec = one] : one \in Sample(1) }
        \cup { [ZeroClearingData5 EXCEPT !.filler5 = one] : one \in Sample(5) }

(***************************************************************************)
(* Owner Data: 50 bytes                                                    *)
(***************************************************************************)

OwnerData5 ==
    [ memo : Sample(50) ]

EncodeOwnerData5(message) ==
    message.memo

DecodeOwnerData5(bytes) ==
    LET memo == ReadBytes(bytes, 50) IN IF ~memo.ok THEN Fail ELSE
    Ok([ memo |-> memo.value ], memo.rest)

ZeroOwnerData5 ==
    [ memo |-> [i \in 1 .. 50 |-> 0] ]

(* Owner Data at zero, then each field in turn at the values it is checked at *)
CheckedOwnerData5 ==
    { ZeroOwnerData5 }
        \cup { [ZeroOwnerData5 EXCEPT !.memo = one] : one \in Sample(50) }

(***************************************************************************)
(* Leg Execution Notice: 235 bytes                                         *)
(***************************************************************************)

LegExecutionNotice ==
    [ outgoingMessagesHeader                      : OutgoingMessagesHeader14,
      group                                       : Sample(2),
      instrument                                  : Sample(4),
      traderId                                    : Sample(8),
      referenceIdOrderIdOrQuoteId                 : Sample(8),
      verbSide                                    : Sample(1),
      quantityTraded                              : Sample(8),
      tradePrice                                  : Sample(10),
      tradingEngineTimestampOfTheTradeLocalHhmmss : Sample(6),
      clearingData                                : ClearingData5,
      ownerData                                   : OwnerData5,
      specialTradeIndicator                       : Sample(1),
      priceType                                   : Sample(1),
      tradeType                                   : Sample(1),
      filler6                                     : Sample(6),
      tradeNumber                                 : Sample(8),
      tradeMemo                                   : Sample(50),
      originalReferenceId                         : Sample(8),
      idCodeForTheCounterpartParticipant          : Sample(4),
      strategyGroup                               : Sample(2),
      strategyInstrumentId                        : Sample(4),
      strategyVerbSide                            : Sample(1),
      strategyTradeNumber                         : Sample(8),
      legNumber                                   : Sample(2) ]

EncodeLegExecutionNotice(message) ==
    EncodeOutgoingMessagesHeader14(message.outgoingMessagesHeader)
        \o message.group
        \o message.instrument
        \o message.traderId
        \o message.referenceIdOrderIdOrQuoteId
        \o message.verbSide
        \o message.quantityTraded
        \o message.tradePrice
        \o message.tradingEngineTimestampOfTheTradeLocalHhmmss
        \o EncodeClearingData5(message.clearingData)
        \o EncodeOwnerData5(message.ownerData)
        \o message.specialTradeIndicator
        \o message.priceType
        \o message.tradeType
        \o message.filler6
        \o message.tradeNumber
        \o message.tradeMemo
        \o message.originalReferenceId
        \o message.idCodeForTheCounterpartParticipant
        \o message.strategyGroup
        \o message.strategyInstrumentId
        \o message.strategyVerbSide
        \o message.strategyTradeNumber
        \o message.legNumber

DecodeLegExecutionNotice(bytes) ==
    LET outgoingMessagesHeader == DecodeOutgoingMessagesHeader14(bytes) IN IF ~outgoingMessagesHeader.ok THEN Fail ELSE
    LET group == ReadBytes(outgoingMessagesHeader.rest, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrument == ReadBytes(group.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET traderId == ReadBytes(instrument.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET referenceIdOrderIdOrQuoteId == ReadBytes(traderId.rest, 8) IN IF ~referenceIdOrderIdOrQuoteId.ok THEN Fail ELSE
    LET verbSide == ReadBytes(referenceIdOrderIdOrQuoteId.rest, 1) IN IF ~verbSide.ok THEN Fail ELSE
    LET quantityTraded == ReadBytes(verbSide.rest, 8) IN IF ~quantityTraded.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(quantityTraded.rest, 10) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradingEngineTimestampOfTheTradeLocalHhmmss == ReadBytes(tradePrice.rest, 6) IN IF ~tradingEngineTimestampOfTheTradeLocalHhmmss.ok THEN Fail ELSE
    LET clearingData == DecodeClearingData5(tradingEngineTimestampOfTheTradeLocalHhmmss.rest) IN IF ~clearingData.ok THEN Fail ELSE
    LET ownerData == DecodeOwnerData5(clearingData.rest) IN IF ~ownerData.ok THEN Fail ELSE
    LET specialTradeIndicator == ReadBytes(ownerData.rest, 1) IN IF ~specialTradeIndicator.ok THEN Fail ELSE
    LET priceType == ReadBytes(specialTradeIndicator.rest, 1) IN IF ~priceType.ok THEN Fail ELSE
    LET tradeType == ReadBytes(priceType.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET filler6 == ReadBytes(tradeType.rest, 6) IN IF ~filler6.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(filler6.rest, 8) IN IF ~tradeNumber.ok THEN Fail ELSE
    LET tradeMemo == ReadBytes(tradeNumber.rest, 50) IN IF ~tradeMemo.ok THEN Fail ELSE
    LET originalReferenceId == ReadBytes(tradeMemo.rest, 8) IN IF ~originalReferenceId.ok THEN Fail ELSE
    LET idCodeForTheCounterpartParticipant == ReadBytes(originalReferenceId.rest, 4) IN IF ~idCodeForTheCounterpartParticipant.ok THEN Fail ELSE
    LET strategyGroup == ReadBytes(idCodeForTheCounterpartParticipant.rest, 2) IN IF ~strategyGroup.ok THEN Fail ELSE
    LET strategyInstrumentId == ReadBytes(strategyGroup.rest, 4) IN IF ~strategyInstrumentId.ok THEN Fail ELSE
    LET strategyVerbSide == ReadBytes(strategyInstrumentId.rest, 1) IN IF ~strategyVerbSide.ok THEN Fail ELSE
    LET strategyTradeNumber == ReadBytes(strategyVerbSide.rest, 8) IN IF ~strategyTradeNumber.ok THEN Fail ELSE
    LET legNumber == ReadBytes(strategyTradeNumber.rest, 2) IN IF ~legNumber.ok THEN Fail ELSE
    Ok([ outgoingMessagesHeader                      |-> outgoingMessagesHeader.value,
         group                                       |-> group.value,
         instrument                                  |-> instrument.value,
         traderId                                    |-> traderId.value,
         referenceIdOrderIdOrQuoteId                 |-> referenceIdOrderIdOrQuoteId.value,
         verbSide                                    |-> verbSide.value,
         quantityTraded                              |-> quantityTraded.value,
         tradePrice                                  |-> tradePrice.value,
         tradingEngineTimestampOfTheTradeLocalHhmmss |-> tradingEngineTimestampOfTheTradeLocalHhmmss.value,
         clearingData                                |-> clearingData.value,
         ownerData                                   |-> ownerData.value,
         specialTradeIndicator                       |-> specialTradeIndicator.value,
         priceType                                   |-> priceType.value,
         tradeType                                   |-> tradeType.value,
         filler6                                     |-> filler6.value,
         tradeNumber                                 |-> tradeNumber.value,
         tradeMemo                                   |-> tradeMemo.value,
         originalReferenceId                         |-> originalReferenceId.value,
         idCodeForTheCounterpartParticipant          |-> idCodeForTheCounterpartParticipant.value,
         strategyGroup                               |-> strategyGroup.value,
         strategyInstrumentId                        |-> strategyInstrumentId.value,
         strategyVerbSide                            |-> strategyVerbSide.value,
         strategyTradeNumber                         |-> strategyTradeNumber.value,
         legNumber                                   |-> legNumber.value ], legNumber.rest)

ZeroLegExecutionNotice ==
    [ outgoingMessagesHeader                      |-> ZeroOutgoingMessagesHeader14,
      group                                       |-> [i \in 1 .. 2 |-> 0],
      instrument                                  |-> [i \in 1 .. 4 |-> 0],
      traderId                                    |-> [i \in 1 .. 8 |-> 0],
      referenceIdOrderIdOrQuoteId                 |-> [i \in 1 .. 8 |-> 0],
      verbSide                                    |-> [i \in 1 .. 1 |-> 0],
      quantityTraded                              |-> [i \in 1 .. 8 |-> 0],
      tradePrice                                  |-> [i \in 1 .. 10 |-> 0],
      tradingEngineTimestampOfTheTradeLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      clearingData                                |-> ZeroClearingData5,
      ownerData                                   |-> ZeroOwnerData5,
      specialTradeIndicator                       |-> [i \in 1 .. 1 |-> 0],
      priceType                                   |-> [i \in 1 .. 1 |-> 0],
      tradeType                                   |-> [i \in 1 .. 1 |-> 0],
      filler6                                     |-> [i \in 1 .. 6 |-> 0],
      tradeNumber                                 |-> [i \in 1 .. 8 |-> 0],
      tradeMemo                                   |-> [i \in 1 .. 50 |-> 0],
      originalReferenceId                         |-> [i \in 1 .. 8 |-> 0],
      idCodeForTheCounterpartParticipant          |-> [i \in 1 .. 4 |-> 0],
      strategyGroup                               |-> [i \in 1 .. 2 |-> 0],
      strategyInstrumentId                        |-> [i \in 1 .. 4 |-> 0],
      strategyVerbSide                            |-> [i \in 1 .. 1 |-> 0],
      strategyTradeNumber                         |-> [i \in 1 .. 8 |-> 0],
      legNumber                                   |-> [i \in 1 .. 2 |-> 0] ]

(* Leg Execution Notice at zero, then each field in turn at the values it is checked at *)
CheckedLegExecutionNotice ==
    { ZeroLegExecutionNotice }
        \cup { [ZeroLegExecutionNotice EXCEPT !.outgoingMessagesHeader = one] : one \in CheckedOutgoingMessagesHeader14 }
        \cup { [ZeroLegExecutionNotice EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroLegExecutionNotice EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroLegExecutionNotice EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroLegExecutionNotice EXCEPT !.referenceIdOrderIdOrQuoteId = one] : one \in Sample(8) }
        \cup { [ZeroLegExecutionNotice EXCEPT !.verbSide = one] : one \in Sample(1) }
        \cup { [ZeroLegExecutionNotice EXCEPT !.quantityTraded = one] : one \in Sample(8) }
        \cup { [ZeroLegExecutionNotice EXCEPT !.tradePrice = one] : one \in Sample(10) }
        \cup { [ZeroLegExecutionNotice EXCEPT !.tradingEngineTimestampOfTheTradeLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroLegExecutionNotice EXCEPT !.clearingData = one] : one \in CheckedClearingData5 }
        \cup { [ZeroLegExecutionNotice EXCEPT !.ownerData = one] : one \in CheckedOwnerData5 }
        \cup { [ZeroLegExecutionNotice EXCEPT !.specialTradeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroLegExecutionNotice EXCEPT !.priceType = one] : one \in Sample(1) }
        \cup { [ZeroLegExecutionNotice EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroLegExecutionNotice EXCEPT !.filler6 = one] : one \in Sample(6) }
        \cup { [ZeroLegExecutionNotice EXCEPT !.tradeNumber = one] : one \in Sample(8) }
        \cup { [ZeroLegExecutionNotice EXCEPT !.tradeMemo = one] : one \in Sample(50) }
        \cup { [ZeroLegExecutionNotice EXCEPT !.originalReferenceId = one] : one \in Sample(8) }
        \cup { [ZeroLegExecutionNotice EXCEPT !.idCodeForTheCounterpartParticipant = one] : one \in Sample(4) }
        \cup { [ZeroLegExecutionNotice EXCEPT !.strategyGroup = one] : one \in Sample(2) }
        \cup { [ZeroLegExecutionNotice EXCEPT !.strategyInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroLegExecutionNotice EXCEPT !.strategyVerbSide = one] : one \in Sample(1) }
        \cup { [ZeroLegExecutionNotice EXCEPT !.strategyTradeNumber = one] : one \in Sample(8) }
        \cup { [ZeroLegExecutionNotice EXCEPT !.legNumber = one] : one \in Sample(2) }

(***************************************************************************)
(* Outgoing Messages Header: 22 bytes                                      *)
(***************************************************************************)

OutgoingMessagesHeader15 ==
    [ tradingEngineTimestampLocalHhmmss : Sample(6),
      userSequenceId                    : Sample(8),
      exchangeMessageId                 : Sample(6),
      gapSequenceId                     : Sample(2) ]

EncodeOutgoingMessagesHeader15(message) ==
    message.tradingEngineTimestampLocalHhmmss
        \o message.userSequenceId
        \o message.exchangeMessageId
        \o message.gapSequenceId

DecodeOutgoingMessagesHeader15(bytes) ==
    LET tradingEngineTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~tradingEngineTimestampLocalHhmmss.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(tradingEngineTimestampLocalHhmmss.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    LET exchangeMessageId == ReadBytes(userSequenceId.rest, 6) IN IF ~exchangeMessageId.ok THEN Fail ELSE
    LET gapSequenceId == ReadBytes(exchangeMessageId.rest, 2) IN IF ~gapSequenceId.ok THEN Fail ELSE
    Ok([ tradingEngineTimestampLocalHhmmss |-> tradingEngineTimestampLocalHhmmss.value,
         userSequenceId                    |-> userSequenceId.value,
         exchangeMessageId                 |-> exchangeMessageId.value,
         gapSequenceId                     |-> gapSequenceId.value ], gapSequenceId.rest)

ZeroOutgoingMessagesHeader15 ==
    [ tradingEngineTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      userSequenceId                    |-> [i \in 1 .. 8 |-> 0],
      exchangeMessageId                 |-> [i \in 1 .. 6 |-> 0],
      gapSequenceId                     |-> [i \in 1 .. 2 |-> 0] ]

(* Outgoing Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedOutgoingMessagesHeader15 ==
    { ZeroOutgoingMessagesHeader15 }
        \cup { [ZeroOutgoingMessagesHeader15 EXCEPT !.tradingEngineTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroOutgoingMessagesHeader15 EXCEPT !.userSequenceId = one] : one \in Sample(8) }
        \cup { [ZeroOutgoingMessagesHeader15 EXCEPT !.exchangeMessageId = one] : one \in Sample(6) }
        \cup { [ZeroOutgoingMessagesHeader15 EXCEPT !.gapSequenceId = one] : one \in Sample(2) }

(***************************************************************************)
(* Counterpart Owner Data: 50 bytes                                        *)
(***************************************************************************)

CounterpartOwnerData ==
    [ memo : Sample(50) ]

EncodeCounterpartOwnerData(message) ==
    message.memo

DecodeCounterpartOwnerData(bytes) ==
    LET memo == ReadBytes(bytes, 50) IN IF ~memo.ok THEN Fail ELSE
    Ok([ memo |-> memo.value ], memo.rest)

ZeroCounterpartOwnerData ==
    [ memo |-> [i \in 1 .. 50 |-> 0] ]

(* Counterpart Owner Data at zero, then each field in turn at the values it is checked at *)
CheckedCounterpartOwnerData ==
    { ZeroCounterpartOwnerData }
        \cup { [ZeroCounterpartOwnerData EXCEPT !.memo = one] : one \in Sample(50) }

(***************************************************************************)
(* Overstepped Order Or Quote Notice: 112 bytes                            *)
(***************************************************************************)

OversteppedOrderOrQuoteNotice ==
    [ outgoingMessagesHeader : OutgoingMessagesHeader15,
      group                  : Sample(2),
      instrument             : Sample(4),
      verb                   : Sample(1),
      orderType              : Sample(1),
      traderId               : Sample(8),
      orderId                : Sample(8),
      counterpartTraderId    : Sample(8),
      counterpartOrderId     : Sample(8),
      counterpartOwnerData   : CounterpartOwnerData ]

EncodeOversteppedOrderOrQuoteNotice(message) ==
    EncodeOutgoingMessagesHeader15(message.outgoingMessagesHeader)
        \o message.group
        \o message.instrument
        \o message.verb
        \o message.orderType
        \o message.traderId
        \o message.orderId
        \o message.counterpartTraderId
        \o message.counterpartOrderId
        \o EncodeCounterpartOwnerData(message.counterpartOwnerData)

DecodeOversteppedOrderOrQuoteNotice(bytes) ==
    LET outgoingMessagesHeader == DecodeOutgoingMessagesHeader15(bytes) IN IF ~outgoingMessagesHeader.ok THEN Fail ELSE
    LET group == ReadBytes(outgoingMessagesHeader.rest, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrument == ReadBytes(group.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET verb == ReadBytes(instrument.rest, 1) IN IF ~verb.ok THEN Fail ELSE
    LET orderType == ReadBytes(verb.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET traderId == ReadBytes(orderType.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET orderId == ReadBytes(traderId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET counterpartTraderId == ReadBytes(orderId.rest, 8) IN IF ~counterpartTraderId.ok THEN Fail ELSE
    LET counterpartOrderId == ReadBytes(counterpartTraderId.rest, 8) IN IF ~counterpartOrderId.ok THEN Fail ELSE
    LET counterpartOwnerData == DecodeCounterpartOwnerData(counterpartOrderId.rest) IN IF ~counterpartOwnerData.ok THEN Fail ELSE
    Ok([ outgoingMessagesHeader |-> outgoingMessagesHeader.value,
         group                  |-> group.value,
         instrument             |-> instrument.value,
         verb                   |-> verb.value,
         orderType              |-> orderType.value,
         traderId               |-> traderId.value,
         orderId                |-> orderId.value,
         counterpartTraderId    |-> counterpartTraderId.value,
         counterpartOrderId     |-> counterpartOrderId.value,
         counterpartOwnerData   |-> counterpartOwnerData.value ], counterpartOwnerData.rest)

ZeroOversteppedOrderOrQuoteNotice ==
    [ outgoingMessagesHeader |-> ZeroOutgoingMessagesHeader15,
      group                  |-> [i \in 1 .. 2 |-> 0],
      instrument             |-> [i \in 1 .. 4 |-> 0],
      verb                   |-> [i \in 1 .. 1 |-> 0],
      orderType              |-> [i \in 1 .. 1 |-> 0],
      traderId               |-> [i \in 1 .. 8 |-> 0],
      orderId                |-> [i \in 1 .. 8 |-> 0],
      counterpartTraderId    |-> [i \in 1 .. 8 |-> 0],
      counterpartOrderId     |-> [i \in 1 .. 8 |-> 0],
      counterpartOwnerData   |-> ZeroCounterpartOwnerData ]

(* Overstepped Order Or Quote Notice at zero, then each field in turn at the values it is checked at *)
CheckedOversteppedOrderOrQuoteNotice ==
    { ZeroOversteppedOrderOrQuoteNotice }
        \cup { [ZeroOversteppedOrderOrQuoteNotice EXCEPT !.outgoingMessagesHeader = one] : one \in CheckedOutgoingMessagesHeader15 }
        \cup { [ZeroOversteppedOrderOrQuoteNotice EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroOversteppedOrderOrQuoteNotice EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroOversteppedOrderOrQuoteNotice EXCEPT !.verb = one] : one \in Sample(1) }
        \cup { [ZeroOversteppedOrderOrQuoteNotice EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroOversteppedOrderOrQuoteNotice EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroOversteppedOrderOrQuoteNotice EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOversteppedOrderOrQuoteNotice EXCEPT !.counterpartTraderId = one] : one \in Sample(8) }
        \cup { [ZeroOversteppedOrderOrQuoteNotice EXCEPT !.counterpartOrderId = one] : one \in Sample(8) }
        \cup { [ZeroOversteppedOrderOrQuoteNotice EXCEPT !.counterpartOwnerData = one] : one \in CheckedCounterpartOwnerData }

(***************************************************************************)
(* Outgoing Messages Header: 22 bytes                                      *)
(***************************************************************************)

OutgoingMessagesHeader16 ==
    [ tradingEngineTimestampLocalHhmmss : Sample(6),
      userSequenceId                    : Sample(8),
      exchangeMessageId                 : Sample(6),
      gapSequenceId                     : Sample(2) ]

EncodeOutgoingMessagesHeader16(message) ==
    message.tradingEngineTimestampLocalHhmmss
        \o message.userSequenceId
        \o message.exchangeMessageId
        \o message.gapSequenceId

DecodeOutgoingMessagesHeader16(bytes) ==
    LET tradingEngineTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~tradingEngineTimestampLocalHhmmss.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(tradingEngineTimestampLocalHhmmss.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    LET exchangeMessageId == ReadBytes(userSequenceId.rest, 6) IN IF ~exchangeMessageId.ok THEN Fail ELSE
    LET gapSequenceId == ReadBytes(exchangeMessageId.rest, 2) IN IF ~gapSequenceId.ok THEN Fail ELSE
    Ok([ tradingEngineTimestampLocalHhmmss |-> tradingEngineTimestampLocalHhmmss.value,
         userSequenceId                    |-> userSequenceId.value,
         exchangeMessageId                 |-> exchangeMessageId.value,
         gapSequenceId                     |-> gapSequenceId.value ], gapSequenceId.rest)

ZeroOutgoingMessagesHeader16 ==
    [ tradingEngineTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      userSequenceId                    |-> [i \in 1 .. 8 |-> 0],
      exchangeMessageId                 |-> [i \in 1 .. 6 |-> 0],
      gapSequenceId                     |-> [i \in 1 .. 2 |-> 0] ]

(* Outgoing Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedOutgoingMessagesHeader16 ==
    { ZeroOutgoingMessagesHeader16 }
        \cup { [ZeroOutgoingMessagesHeader16 EXCEPT !.tradingEngineTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroOutgoingMessagesHeader16 EXCEPT !.userSequenceId = one] : one \in Sample(8) }
        \cup { [ZeroOutgoingMessagesHeader16 EXCEPT !.exchangeMessageId = one] : one \in Sample(6) }
        \cup { [ZeroOutgoingMessagesHeader16 EXCEPT !.gapSequenceId = one] : one \in Sample(2) }

(***************************************************************************)
(* Cancellation Of All Quotes Notice: 37 bytes                             *)
(***************************************************************************)

CancellationOfAllQuotesNotice ==
    [ outgoingMessagesHeader : OutgoingMessagesHeader16,
      group                  : Sample(2),
      instrument             : Sample(4),
      traderId               : Sample(8),
      cancelReason           : Sample(1) ]

EncodeCancellationOfAllQuotesNotice(message) ==
    EncodeOutgoingMessagesHeader16(message.outgoingMessagesHeader)
        \o message.group
        \o message.instrument
        \o message.traderId
        \o message.cancelReason

DecodeCancellationOfAllQuotesNotice(bytes) ==
    LET outgoingMessagesHeader == DecodeOutgoingMessagesHeader16(bytes) IN IF ~outgoingMessagesHeader.ok THEN Fail ELSE
    LET group == ReadBytes(outgoingMessagesHeader.rest, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrument == ReadBytes(group.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET traderId == ReadBytes(instrument.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET cancelReason == ReadBytes(traderId.rest, 1) IN IF ~cancelReason.ok THEN Fail ELSE
    Ok([ outgoingMessagesHeader |-> outgoingMessagesHeader.value,
         group                  |-> group.value,
         instrument             |-> instrument.value,
         traderId               |-> traderId.value,
         cancelReason           |-> cancelReason.value ], cancelReason.rest)

ZeroCancellationOfAllQuotesNotice ==
    [ outgoingMessagesHeader |-> ZeroOutgoingMessagesHeader16,
      group                  |-> [i \in 1 .. 2 |-> 0],
      instrument             |-> [i \in 1 .. 4 |-> 0],
      traderId               |-> [i \in 1 .. 8 |-> 0],
      cancelReason           |-> [i \in 1 .. 1 |-> 0] ]

(* Cancellation Of All Quotes Notice at zero, then each field in turn at the values it is checked at *)
CheckedCancellationOfAllQuotesNotice ==
    { ZeroCancellationOfAllQuotesNotice }
        \cup { [ZeroCancellationOfAllQuotesNotice EXCEPT !.outgoingMessagesHeader = one] : one \in CheckedOutgoingMessagesHeader16 }
        \cup { [ZeroCancellationOfAllQuotesNotice EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroCancellationOfAllQuotesNotice EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroCancellationOfAllQuotesNotice EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroCancellationOfAllQuotesNotice EXCEPT !.cancelReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Outgoing Messages Header: 22 bytes                                      *)
(***************************************************************************)

OutgoingMessagesHeader17 ==
    [ tradingEngineTimestampLocalHhmmss : Sample(6),
      userSequenceId                    : Sample(8),
      exchangeMessageId                 : Sample(6),
      gapSequenceId                     : Sample(2) ]

EncodeOutgoingMessagesHeader17(message) ==
    message.tradingEngineTimestampLocalHhmmss
        \o message.userSequenceId
        \o message.exchangeMessageId
        \o message.gapSequenceId

DecodeOutgoingMessagesHeader17(bytes) ==
    LET tradingEngineTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~tradingEngineTimestampLocalHhmmss.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(tradingEngineTimestampLocalHhmmss.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    LET exchangeMessageId == ReadBytes(userSequenceId.rest, 6) IN IF ~exchangeMessageId.ok THEN Fail ELSE
    LET gapSequenceId == ReadBytes(exchangeMessageId.rest, 2) IN IF ~gapSequenceId.ok THEN Fail ELSE
    Ok([ tradingEngineTimestampLocalHhmmss |-> tradingEngineTimestampLocalHhmmss.value,
         userSequenceId                    |-> userSequenceId.value,
         exchangeMessageId                 |-> exchangeMessageId.value,
         gapSequenceId                     |-> gapSequenceId.value ], gapSequenceId.rest)

ZeroOutgoingMessagesHeader17 ==
    [ tradingEngineTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      userSequenceId                    |-> [i \in 1 .. 8 |-> 0],
      exchangeMessageId                 |-> [i \in 1 .. 6 |-> 0],
      gapSequenceId                     |-> [i \in 1 .. 2 |-> 0] ]

(* Outgoing Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedOutgoingMessagesHeader17 ==
    { ZeroOutgoingMessagesHeader17 }
        \cup { [ZeroOutgoingMessagesHeader17 EXCEPT !.tradingEngineTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroOutgoingMessagesHeader17 EXCEPT !.userSequenceId = one] : one \in Sample(8) }
        \cup { [ZeroOutgoingMessagesHeader17 EXCEPT !.exchangeMessageId = one] : one \in Sample(6) }
        \cup { [ZeroOutgoingMessagesHeader17 EXCEPT !.gapSequenceId = one] : one \in Sample(2) }

(***************************************************************************)
(* Clearing Data: 20 bytes                                                 *)
(***************************************************************************)

ClearingData6 ==
    [ clearingInstruction : Sample(12),
      accountType         : Sample(1),
      openClose           : Sample(1),
      hedgeSpec           : Sample(1),
      filler5             : Sample(5) ]

EncodeClearingData6(message) ==
    message.clearingInstruction
        \o message.accountType
        \o message.openClose
        \o message.hedgeSpec
        \o message.filler5

DecodeClearingData6(bytes) ==
    LET clearingInstruction == ReadBytes(bytes, 12) IN IF ~clearingInstruction.ok THEN Fail ELSE
    LET accountType == ReadBytes(clearingInstruction.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET openClose == ReadBytes(accountType.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET hedgeSpec == ReadBytes(openClose.rest, 1) IN IF ~hedgeSpec.ok THEN Fail ELSE
    LET filler5 == ReadBytes(hedgeSpec.rest, 5) IN IF ~filler5.ok THEN Fail ELSE
    Ok([ clearingInstruction |-> clearingInstruction.value,
         accountType         |-> accountType.value,
         openClose           |-> openClose.value,
         hedgeSpec           |-> hedgeSpec.value,
         filler5             |-> filler5.value ], filler5.rest)

ZeroClearingData6 ==
    [ clearingInstruction |-> [i \in 1 .. 12 |-> 0],
      accountType         |-> [i \in 1 .. 1 |-> 0],
      openClose           |-> [i \in 1 .. 1 |-> 0],
      hedgeSpec           |-> [i \in 1 .. 1 |-> 0],
      filler5             |-> [i \in 1 .. 5 |-> 0] ]

(* Clearing Data at zero, then each field in turn at the values it is checked at *)
CheckedClearingData6 ==
    { ZeroClearingData6 }
        \cup { [ZeroClearingData6 EXCEPT !.clearingInstruction = one] : one \in Sample(12) }
        \cup { [ZeroClearingData6 EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroClearingData6 EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroClearingData6 EXCEPT !.hedgeSpec = one] : one \in Sample(1) }
        \cup { [ZeroClearingData6 EXCEPT !.filler5 = one] : one \in Sample(5) }

(***************************************************************************)
(* Owner Data: 50 bytes                                                    *)
(***************************************************************************)

OwnerData6 ==
    [ memo : Sample(50) ]

EncodeOwnerData6(message) ==
    message.memo

DecodeOwnerData6(bytes) ==
    LET memo == ReadBytes(bytes, 50) IN IF ~memo.ok THEN Fail ELSE
    Ok([ memo |-> memo.value ], memo.rest)

ZeroOwnerData6 ==
    [ memo |-> [i \in 1 .. 50 |-> 0] ]

(* Owner Data at zero, then each field in turn at the values it is checked at *)
CheckedOwnerData6 ==
    { ZeroOwnerData6 }
        \cup { [ZeroOwnerData6 EXCEPT !.memo = one] : one \in Sample(50) }

(***************************************************************************)
(* Execution Notice: 218 bytes                                             *)
(***************************************************************************)

ExecutionNotice ==
    [ outgoingMessagesHeader                      : OutgoingMessagesHeader17,
      group                                       : Sample(2),
      instrument                                  : Sample(4),
      traderId                                    : Sample(8),
      referenceIdOrderIdOrQuoteId                 : Sample(8),
      verbSide                                    : Sample(1),
      quantityTraded                              : Sample(8),
      tradePrice                                  : Sample(10),
      tradingEngineTimestampOfTheTradeLocalHhmmss : Sample(6),
      clearingData                                : ClearingData6,
      ownerData                                   : OwnerData6,
      specialTradeIndicator                       : Sample(1),
      priceType                                   : Sample(1),
      tradeType                                   : Sample(1),
      filler6                                     : Sample(6),
      tradeNumber                                 : Sample(8),
      tradeMemo                                   : Sample(50),
      originalReferenceId                         : Sample(8),
      idCodeForTheCounterpartParticipant          : Sample(4) ]

EncodeExecutionNotice(message) ==
    EncodeOutgoingMessagesHeader17(message.outgoingMessagesHeader)
        \o message.group
        \o message.instrument
        \o message.traderId
        \o message.referenceIdOrderIdOrQuoteId
        \o message.verbSide
        \o message.quantityTraded
        \o message.tradePrice
        \o message.tradingEngineTimestampOfTheTradeLocalHhmmss
        \o EncodeClearingData6(message.clearingData)
        \o EncodeOwnerData6(message.ownerData)
        \o message.specialTradeIndicator
        \o message.priceType
        \o message.tradeType
        \o message.filler6
        \o message.tradeNumber
        \o message.tradeMemo
        \o message.originalReferenceId
        \o message.idCodeForTheCounterpartParticipant

DecodeExecutionNotice(bytes) ==
    LET outgoingMessagesHeader == DecodeOutgoingMessagesHeader17(bytes) IN IF ~outgoingMessagesHeader.ok THEN Fail ELSE
    LET group == ReadBytes(outgoingMessagesHeader.rest, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrument == ReadBytes(group.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET traderId == ReadBytes(instrument.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET referenceIdOrderIdOrQuoteId == ReadBytes(traderId.rest, 8) IN IF ~referenceIdOrderIdOrQuoteId.ok THEN Fail ELSE
    LET verbSide == ReadBytes(referenceIdOrderIdOrQuoteId.rest, 1) IN IF ~verbSide.ok THEN Fail ELSE
    LET quantityTraded == ReadBytes(verbSide.rest, 8) IN IF ~quantityTraded.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(quantityTraded.rest, 10) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradingEngineTimestampOfTheTradeLocalHhmmss == ReadBytes(tradePrice.rest, 6) IN IF ~tradingEngineTimestampOfTheTradeLocalHhmmss.ok THEN Fail ELSE
    LET clearingData == DecodeClearingData6(tradingEngineTimestampOfTheTradeLocalHhmmss.rest) IN IF ~clearingData.ok THEN Fail ELSE
    LET ownerData == DecodeOwnerData6(clearingData.rest) IN IF ~ownerData.ok THEN Fail ELSE
    LET specialTradeIndicator == ReadBytes(ownerData.rest, 1) IN IF ~specialTradeIndicator.ok THEN Fail ELSE
    LET priceType == ReadBytes(specialTradeIndicator.rest, 1) IN IF ~priceType.ok THEN Fail ELSE
    LET tradeType == ReadBytes(priceType.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET filler6 == ReadBytes(tradeType.rest, 6) IN IF ~filler6.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(filler6.rest, 8) IN IF ~tradeNumber.ok THEN Fail ELSE
    LET tradeMemo == ReadBytes(tradeNumber.rest, 50) IN IF ~tradeMemo.ok THEN Fail ELSE
    LET originalReferenceId == ReadBytes(tradeMemo.rest, 8) IN IF ~originalReferenceId.ok THEN Fail ELSE
    LET idCodeForTheCounterpartParticipant == ReadBytes(originalReferenceId.rest, 4) IN IF ~idCodeForTheCounterpartParticipant.ok THEN Fail ELSE
    Ok([ outgoingMessagesHeader                      |-> outgoingMessagesHeader.value,
         group                                       |-> group.value,
         instrument                                  |-> instrument.value,
         traderId                                    |-> traderId.value,
         referenceIdOrderIdOrQuoteId                 |-> referenceIdOrderIdOrQuoteId.value,
         verbSide                                    |-> verbSide.value,
         quantityTraded                              |-> quantityTraded.value,
         tradePrice                                  |-> tradePrice.value,
         tradingEngineTimestampOfTheTradeLocalHhmmss |-> tradingEngineTimestampOfTheTradeLocalHhmmss.value,
         clearingData                                |-> clearingData.value,
         ownerData                                   |-> ownerData.value,
         specialTradeIndicator                       |-> specialTradeIndicator.value,
         priceType                                   |-> priceType.value,
         tradeType                                   |-> tradeType.value,
         filler6                                     |-> filler6.value,
         tradeNumber                                 |-> tradeNumber.value,
         tradeMemo                                   |-> tradeMemo.value,
         originalReferenceId                         |-> originalReferenceId.value,
         idCodeForTheCounterpartParticipant          |-> idCodeForTheCounterpartParticipant.value ], idCodeForTheCounterpartParticipant.rest)

ZeroExecutionNotice ==
    [ outgoingMessagesHeader                      |-> ZeroOutgoingMessagesHeader17,
      group                                       |-> [i \in 1 .. 2 |-> 0],
      instrument                                  |-> [i \in 1 .. 4 |-> 0],
      traderId                                    |-> [i \in 1 .. 8 |-> 0],
      referenceIdOrderIdOrQuoteId                 |-> [i \in 1 .. 8 |-> 0],
      verbSide                                    |-> [i \in 1 .. 1 |-> 0],
      quantityTraded                              |-> [i \in 1 .. 8 |-> 0],
      tradePrice                                  |-> [i \in 1 .. 10 |-> 0],
      tradingEngineTimestampOfTheTradeLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      clearingData                                |-> ZeroClearingData6,
      ownerData                                   |-> ZeroOwnerData6,
      specialTradeIndicator                       |-> [i \in 1 .. 1 |-> 0],
      priceType                                   |-> [i \in 1 .. 1 |-> 0],
      tradeType                                   |-> [i \in 1 .. 1 |-> 0],
      filler6                                     |-> [i \in 1 .. 6 |-> 0],
      tradeNumber                                 |-> [i \in 1 .. 8 |-> 0],
      tradeMemo                                   |-> [i \in 1 .. 50 |-> 0],
      originalReferenceId                         |-> [i \in 1 .. 8 |-> 0],
      idCodeForTheCounterpartParticipant          |-> [i \in 1 .. 4 |-> 0] ]

(* Execution Notice at zero, then each field in turn at the values it is checked at *)
CheckedExecutionNotice ==
    { ZeroExecutionNotice }
        \cup { [ZeroExecutionNotice EXCEPT !.outgoingMessagesHeader = one] : one \in CheckedOutgoingMessagesHeader17 }
        \cup { [ZeroExecutionNotice EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroExecutionNotice EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroExecutionNotice EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionNotice EXCEPT !.referenceIdOrderIdOrQuoteId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionNotice EXCEPT !.verbSide = one] : one \in Sample(1) }
        \cup { [ZeroExecutionNotice EXCEPT !.quantityTraded = one] : one \in Sample(8) }
        \cup { [ZeroExecutionNotice EXCEPT !.tradePrice = one] : one \in Sample(10) }
        \cup { [ZeroExecutionNotice EXCEPT !.tradingEngineTimestampOfTheTradeLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroExecutionNotice EXCEPT !.clearingData = one] : one \in CheckedClearingData6 }
        \cup { [ZeroExecutionNotice EXCEPT !.ownerData = one] : one \in CheckedOwnerData6 }
        \cup { [ZeroExecutionNotice EXCEPT !.specialTradeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExecutionNotice EXCEPT !.priceType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionNotice EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionNotice EXCEPT !.filler6 = one] : one \in Sample(6) }
        \cup { [ZeroExecutionNotice EXCEPT !.tradeNumber = one] : one \in Sample(8) }
        \cup { [ZeroExecutionNotice EXCEPT !.tradeMemo = one] : one \in Sample(50) }
        \cup { [ZeroExecutionNotice EXCEPT !.originalReferenceId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionNotice EXCEPT !.idCodeForTheCounterpartParticipant = one] : one \in Sample(4) }

(***************************************************************************)
(* Clearing Data: 20 bytes                                                 *)
(***************************************************************************)

ClearingData7 ==
    [ clearingInstruction : Sample(12),
      accountType         : Sample(1),
      openClose           : Sample(1),
      hedgeSpec           : Sample(1),
      filler5             : Sample(5) ]

EncodeClearingData7(message) ==
    message.clearingInstruction
        \o message.accountType
        \o message.openClose
        \o message.hedgeSpec
        \o message.filler5

DecodeClearingData7(bytes) ==
    LET clearingInstruction == ReadBytes(bytes, 12) IN IF ~clearingInstruction.ok THEN Fail ELSE
    LET accountType == ReadBytes(clearingInstruction.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET openClose == ReadBytes(accountType.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET hedgeSpec == ReadBytes(openClose.rest, 1) IN IF ~hedgeSpec.ok THEN Fail ELSE
    LET filler5 == ReadBytes(hedgeSpec.rest, 5) IN IF ~filler5.ok THEN Fail ELSE
    Ok([ clearingInstruction |-> clearingInstruction.value,
         accountType         |-> accountType.value,
         openClose           |-> openClose.value,
         hedgeSpec           |-> hedgeSpec.value,
         filler5             |-> filler5.value ], filler5.rest)

ZeroClearingData7 ==
    [ clearingInstruction |-> [i \in 1 .. 12 |-> 0],
      accountType         |-> [i \in 1 .. 1 |-> 0],
      openClose           |-> [i \in 1 .. 1 |-> 0],
      hedgeSpec           |-> [i \in 1 .. 1 |-> 0],
      filler5             |-> [i \in 1 .. 5 |-> 0] ]

(* Clearing Data at zero, then each field in turn at the values it is checked at *)
CheckedClearingData7 ==
    { ZeroClearingData7 }
        \cup { [ZeroClearingData7 EXCEPT !.clearingInstruction = one] : one \in Sample(12) }
        \cup { [ZeroClearingData7 EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroClearingData7 EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroClearingData7 EXCEPT !.hedgeSpec = one] : one \in Sample(1) }
        \cup { [ZeroClearingData7 EXCEPT !.filler5 = one] : one \in Sample(5) }

(***************************************************************************)
(* Owner Data: 50 bytes                                                    *)
(***************************************************************************)

OwnerData7 ==
    [ memo : Sample(50) ]

EncodeOwnerData7(message) ==
    message.memo

DecodeOwnerData7(bytes) ==
    LET memo == ReadBytes(bytes, 50) IN IF ~memo.ok THEN Fail ELSE
    Ok([ memo |-> memo.value ], memo.rest)

ZeroOwnerData7 ==
    [ memo |-> [i \in 1 .. 50 |-> 0] ]

(* Owner Data at zero, then each field in turn at the values it is checked at *)
CheckedOwnerData7 ==
    { ZeroOwnerData7 }
        \cup { [ZeroOwnerData7 EXCEPT !.memo = one] : one \in Sample(50) }

(***************************************************************************)
(* Execution Cancellation Notice: 196 bytes                                *)
(***************************************************************************)

ExecutionCancellationNotice ==
    [ group                                       : Sample(2),
      instrument                                  : Sample(4),
      traderId                                    : Sample(8),
      referenceIdOrderIdOrQuoteId                 : Sample(8),
      verbSide                                    : Sample(1),
      quantityTraded                              : Sample(8),
      tradePrice                                  : Sample(10),
      tradingEngineTimestampOfTheTradeLocalHhmmss : Sample(6),
      clearingData                                : ClearingData7,
      ownerData                                   : OwnerData7,
      specialTradeIndicator                       : Sample(1),
      priceType                                   : Sample(1),
      tradeType                                   : Sample(1),
      filler6                                     : Sample(6),
      tradeNumber                                 : Sample(8),
      tradeMemo                                   : Sample(50),
      originalReferenceId                         : Sample(8),
      idCodeForTheCounterpartParticipant          : Sample(4) ]

EncodeExecutionCancellationNotice(message) ==
    message.group
        \o message.instrument
        \o message.traderId
        \o message.referenceIdOrderIdOrQuoteId
        \o message.verbSide
        \o message.quantityTraded
        \o message.tradePrice
        \o message.tradingEngineTimestampOfTheTradeLocalHhmmss
        \o EncodeClearingData7(message.clearingData)
        \o EncodeOwnerData7(message.ownerData)
        \o message.specialTradeIndicator
        \o message.priceType
        \o message.tradeType
        \o message.filler6
        \o message.tradeNumber
        \o message.tradeMemo
        \o message.originalReferenceId
        \o message.idCodeForTheCounterpartParticipant

DecodeExecutionCancellationNotice(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrument == ReadBytes(group.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET traderId == ReadBytes(instrument.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET referenceIdOrderIdOrQuoteId == ReadBytes(traderId.rest, 8) IN IF ~referenceIdOrderIdOrQuoteId.ok THEN Fail ELSE
    LET verbSide == ReadBytes(referenceIdOrderIdOrQuoteId.rest, 1) IN IF ~verbSide.ok THEN Fail ELSE
    LET quantityTraded == ReadBytes(verbSide.rest, 8) IN IF ~quantityTraded.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(quantityTraded.rest, 10) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradingEngineTimestampOfTheTradeLocalHhmmss == ReadBytes(tradePrice.rest, 6) IN IF ~tradingEngineTimestampOfTheTradeLocalHhmmss.ok THEN Fail ELSE
    LET clearingData == DecodeClearingData7(tradingEngineTimestampOfTheTradeLocalHhmmss.rest) IN IF ~clearingData.ok THEN Fail ELSE
    LET ownerData == DecodeOwnerData7(clearingData.rest) IN IF ~ownerData.ok THEN Fail ELSE
    LET specialTradeIndicator == ReadBytes(ownerData.rest, 1) IN IF ~specialTradeIndicator.ok THEN Fail ELSE
    LET priceType == ReadBytes(specialTradeIndicator.rest, 1) IN IF ~priceType.ok THEN Fail ELSE
    LET tradeType == ReadBytes(priceType.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET filler6 == ReadBytes(tradeType.rest, 6) IN IF ~filler6.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(filler6.rest, 8) IN IF ~tradeNumber.ok THEN Fail ELSE
    LET tradeMemo == ReadBytes(tradeNumber.rest, 50) IN IF ~tradeMemo.ok THEN Fail ELSE
    LET originalReferenceId == ReadBytes(tradeMemo.rest, 8) IN IF ~originalReferenceId.ok THEN Fail ELSE
    LET idCodeForTheCounterpartParticipant == ReadBytes(originalReferenceId.rest, 4) IN IF ~idCodeForTheCounterpartParticipant.ok THEN Fail ELSE
    Ok([ group                                       |-> group.value,
         instrument                                  |-> instrument.value,
         traderId                                    |-> traderId.value,
         referenceIdOrderIdOrQuoteId                 |-> referenceIdOrderIdOrQuoteId.value,
         verbSide                                    |-> verbSide.value,
         quantityTraded                              |-> quantityTraded.value,
         tradePrice                                  |-> tradePrice.value,
         tradingEngineTimestampOfTheTradeLocalHhmmss |-> tradingEngineTimestampOfTheTradeLocalHhmmss.value,
         clearingData                                |-> clearingData.value,
         ownerData                                   |-> ownerData.value,
         specialTradeIndicator                       |-> specialTradeIndicator.value,
         priceType                                   |-> priceType.value,
         tradeType                                   |-> tradeType.value,
         filler6                                     |-> filler6.value,
         tradeNumber                                 |-> tradeNumber.value,
         tradeMemo                                   |-> tradeMemo.value,
         originalReferenceId                         |-> originalReferenceId.value,
         idCodeForTheCounterpartParticipant          |-> idCodeForTheCounterpartParticipant.value ], idCodeForTheCounterpartParticipant.rest)

ZeroExecutionCancellationNotice ==
    [ group                                       |-> [i \in 1 .. 2 |-> 0],
      instrument                                  |-> [i \in 1 .. 4 |-> 0],
      traderId                                    |-> [i \in 1 .. 8 |-> 0],
      referenceIdOrderIdOrQuoteId                 |-> [i \in 1 .. 8 |-> 0],
      verbSide                                    |-> [i \in 1 .. 1 |-> 0],
      quantityTraded                              |-> [i \in 1 .. 8 |-> 0],
      tradePrice                                  |-> [i \in 1 .. 10 |-> 0],
      tradingEngineTimestampOfTheTradeLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      clearingData                                |-> ZeroClearingData7,
      ownerData                                   |-> ZeroOwnerData7,
      specialTradeIndicator                       |-> [i \in 1 .. 1 |-> 0],
      priceType                                   |-> [i \in 1 .. 1 |-> 0],
      tradeType                                   |-> [i \in 1 .. 1 |-> 0],
      filler6                                     |-> [i \in 1 .. 6 |-> 0],
      tradeNumber                                 |-> [i \in 1 .. 8 |-> 0],
      tradeMemo                                   |-> [i \in 1 .. 50 |-> 0],
      originalReferenceId                         |-> [i \in 1 .. 8 |-> 0],
      idCodeForTheCounterpartParticipant          |-> [i \in 1 .. 4 |-> 0] ]

(* Execution Cancellation Notice at zero, then each field in turn at the values it is checked at *)
CheckedExecutionCancellationNotice ==
    { ZeroExecutionCancellationNotice }
        \cup { [ZeroExecutionCancellationNotice EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroExecutionCancellationNotice EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroExecutionCancellationNotice EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionCancellationNotice EXCEPT !.referenceIdOrderIdOrQuoteId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionCancellationNotice EXCEPT !.verbSide = one] : one \in Sample(1) }
        \cup { [ZeroExecutionCancellationNotice EXCEPT !.quantityTraded = one] : one \in Sample(8) }
        \cup { [ZeroExecutionCancellationNotice EXCEPT !.tradePrice = one] : one \in Sample(10) }
        \cup { [ZeroExecutionCancellationNotice EXCEPT !.tradingEngineTimestampOfTheTradeLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroExecutionCancellationNotice EXCEPT !.clearingData = one] : one \in CheckedClearingData7 }
        \cup { [ZeroExecutionCancellationNotice EXCEPT !.ownerData = one] : one \in CheckedOwnerData7 }
        \cup { [ZeroExecutionCancellationNotice EXCEPT !.specialTradeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExecutionCancellationNotice EXCEPT !.priceType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionCancellationNotice EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionCancellationNotice EXCEPT !.filler6 = one] : one \in Sample(6) }
        \cup { [ZeroExecutionCancellationNotice EXCEPT !.tradeNumber = one] : one \in Sample(8) }
        \cup { [ZeroExecutionCancellationNotice EXCEPT !.tradeMemo = one] : one \in Sample(50) }
        \cup { [ZeroExecutionCancellationNotice EXCEPT !.originalReferenceId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionCancellationNotice EXCEPT !.idCodeForTheCounterpartParticipant = one] : one \in Sample(4) }

(***************************************************************************)
(* Clearing Data: 20 bytes                                                 *)
(***************************************************************************)

ClearingData8 ==
    [ clearingInstruction : Sample(12),
      accountType         : Sample(1),
      openClose           : Sample(1),
      hedgeSpec           : Sample(1),
      filler5             : Sample(5) ]

EncodeClearingData8(message) ==
    message.clearingInstruction
        \o message.accountType
        \o message.openClose
        \o message.hedgeSpec
        \o message.filler5

DecodeClearingData8(bytes) ==
    LET clearingInstruction == ReadBytes(bytes, 12) IN IF ~clearingInstruction.ok THEN Fail ELSE
    LET accountType == ReadBytes(clearingInstruction.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET openClose == ReadBytes(accountType.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET hedgeSpec == ReadBytes(openClose.rest, 1) IN IF ~hedgeSpec.ok THEN Fail ELSE
    LET filler5 == ReadBytes(hedgeSpec.rest, 5) IN IF ~filler5.ok THEN Fail ELSE
    Ok([ clearingInstruction |-> clearingInstruction.value,
         accountType         |-> accountType.value,
         openClose           |-> openClose.value,
         hedgeSpec           |-> hedgeSpec.value,
         filler5             |-> filler5.value ], filler5.rest)

ZeroClearingData8 ==
    [ clearingInstruction |-> [i \in 1 .. 12 |-> 0],
      accountType         |-> [i \in 1 .. 1 |-> 0],
      openClose           |-> [i \in 1 .. 1 |-> 0],
      hedgeSpec           |-> [i \in 1 .. 1 |-> 0],
      filler5             |-> [i \in 1 .. 5 |-> 0] ]

(* Clearing Data at zero, then each field in turn at the values it is checked at *)
CheckedClearingData8 ==
    { ZeroClearingData8 }
        \cup { [ZeroClearingData8 EXCEPT !.clearingInstruction = one] : one \in Sample(12) }
        \cup { [ZeroClearingData8 EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroClearingData8 EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroClearingData8 EXCEPT !.hedgeSpec = one] : one \in Sample(1) }
        \cup { [ZeroClearingData8 EXCEPT !.filler5 = one] : one \in Sample(5) }

(***************************************************************************)
(* Owner Data: 50 bytes                                                    *)
(***************************************************************************)

OwnerData8 ==
    [ memo : Sample(50) ]

EncodeOwnerData8(message) ==
    message.memo

DecodeOwnerData8(bytes) ==
    LET memo == ReadBytes(bytes, 50) IN IF ~memo.ok THEN Fail ELSE
    Ok([ memo |-> memo.value ], memo.rest)

ZeroOwnerData8 ==
    [ memo |-> [i \in 1 .. 50 |-> 0] ]

(* Owner Data at zero, then each field in turn at the values it is checked at *)
CheckedOwnerData8 ==
    { ZeroOwnerData8 }
        \cup { [ZeroOwnerData8 EXCEPT !.memo = one] : one \in Sample(50) }

(***************************************************************************)
(* Leg Execution Cancellation Notice: 213 bytes                            *)
(***************************************************************************)

LegExecutionCancellationNotice ==
    [ group                                       : Sample(2),
      instrument                                  : Sample(4),
      traderId                                    : Sample(8),
      referenceIdOrderIdOrQuoteId                 : Sample(8),
      verbSide                                    : Sample(1),
      quantityTraded                              : Sample(8),
      tradePrice                                  : Sample(10),
      tradingEngineTimestampOfTheTradeLocalHhmmss : Sample(6),
      clearingData                                : ClearingData8,
      ownerData                                   : OwnerData8,
      specialTradeIndicator                       : Sample(1),
      priceType                                   : Sample(1),
      tradeType                                   : Sample(1),
      filler6                                     : Sample(6),
      tradeNumber                                 : Sample(8),
      tradeMemo                                   : Sample(50),
      originalReferenceId                         : Sample(8),
      idCodeForTheCounterpartParticipant          : Sample(4),
      strategyGroup                               : Sample(2),
      strategyInstrumentId                        : Sample(4),
      strategyVerbSide                            : Sample(1),
      strategyTradeNumber                         : Sample(8),
      legNumber                                   : Sample(2) ]

EncodeLegExecutionCancellationNotice(message) ==
    message.group
        \o message.instrument
        \o message.traderId
        \o message.referenceIdOrderIdOrQuoteId
        \o message.verbSide
        \o message.quantityTraded
        \o message.tradePrice
        \o message.tradingEngineTimestampOfTheTradeLocalHhmmss
        \o EncodeClearingData8(message.clearingData)
        \o EncodeOwnerData8(message.ownerData)
        \o message.specialTradeIndicator
        \o message.priceType
        \o message.tradeType
        \o message.filler6
        \o message.tradeNumber
        \o message.tradeMemo
        \o message.originalReferenceId
        \o message.idCodeForTheCounterpartParticipant
        \o message.strategyGroup
        \o message.strategyInstrumentId
        \o message.strategyVerbSide
        \o message.strategyTradeNumber
        \o message.legNumber

DecodeLegExecutionCancellationNotice(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrument == ReadBytes(group.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET traderId == ReadBytes(instrument.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET referenceIdOrderIdOrQuoteId == ReadBytes(traderId.rest, 8) IN IF ~referenceIdOrderIdOrQuoteId.ok THEN Fail ELSE
    LET verbSide == ReadBytes(referenceIdOrderIdOrQuoteId.rest, 1) IN IF ~verbSide.ok THEN Fail ELSE
    LET quantityTraded == ReadBytes(verbSide.rest, 8) IN IF ~quantityTraded.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(quantityTraded.rest, 10) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradingEngineTimestampOfTheTradeLocalHhmmss == ReadBytes(tradePrice.rest, 6) IN IF ~tradingEngineTimestampOfTheTradeLocalHhmmss.ok THEN Fail ELSE
    LET clearingData == DecodeClearingData8(tradingEngineTimestampOfTheTradeLocalHhmmss.rest) IN IF ~clearingData.ok THEN Fail ELSE
    LET ownerData == DecodeOwnerData8(clearingData.rest) IN IF ~ownerData.ok THEN Fail ELSE
    LET specialTradeIndicator == ReadBytes(ownerData.rest, 1) IN IF ~specialTradeIndicator.ok THEN Fail ELSE
    LET priceType == ReadBytes(specialTradeIndicator.rest, 1) IN IF ~priceType.ok THEN Fail ELSE
    LET tradeType == ReadBytes(priceType.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET filler6 == ReadBytes(tradeType.rest, 6) IN IF ~filler6.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(filler6.rest, 8) IN IF ~tradeNumber.ok THEN Fail ELSE
    LET tradeMemo == ReadBytes(tradeNumber.rest, 50) IN IF ~tradeMemo.ok THEN Fail ELSE
    LET originalReferenceId == ReadBytes(tradeMemo.rest, 8) IN IF ~originalReferenceId.ok THEN Fail ELSE
    LET idCodeForTheCounterpartParticipant == ReadBytes(originalReferenceId.rest, 4) IN IF ~idCodeForTheCounterpartParticipant.ok THEN Fail ELSE
    LET strategyGroup == ReadBytes(idCodeForTheCounterpartParticipant.rest, 2) IN IF ~strategyGroup.ok THEN Fail ELSE
    LET strategyInstrumentId == ReadBytes(strategyGroup.rest, 4) IN IF ~strategyInstrumentId.ok THEN Fail ELSE
    LET strategyVerbSide == ReadBytes(strategyInstrumentId.rest, 1) IN IF ~strategyVerbSide.ok THEN Fail ELSE
    LET strategyTradeNumber == ReadBytes(strategyVerbSide.rest, 8) IN IF ~strategyTradeNumber.ok THEN Fail ELSE
    LET legNumber == ReadBytes(strategyTradeNumber.rest, 2) IN IF ~legNumber.ok THEN Fail ELSE
    Ok([ group                                       |-> group.value,
         instrument                                  |-> instrument.value,
         traderId                                    |-> traderId.value,
         referenceIdOrderIdOrQuoteId                 |-> referenceIdOrderIdOrQuoteId.value,
         verbSide                                    |-> verbSide.value,
         quantityTraded                              |-> quantityTraded.value,
         tradePrice                                  |-> tradePrice.value,
         tradingEngineTimestampOfTheTradeLocalHhmmss |-> tradingEngineTimestampOfTheTradeLocalHhmmss.value,
         clearingData                                |-> clearingData.value,
         ownerData                                   |-> ownerData.value,
         specialTradeIndicator                       |-> specialTradeIndicator.value,
         priceType                                   |-> priceType.value,
         tradeType                                   |-> tradeType.value,
         filler6                                     |-> filler6.value,
         tradeNumber                                 |-> tradeNumber.value,
         tradeMemo                                   |-> tradeMemo.value,
         originalReferenceId                         |-> originalReferenceId.value,
         idCodeForTheCounterpartParticipant          |-> idCodeForTheCounterpartParticipant.value,
         strategyGroup                               |-> strategyGroup.value,
         strategyInstrumentId                        |-> strategyInstrumentId.value,
         strategyVerbSide                            |-> strategyVerbSide.value,
         strategyTradeNumber                         |-> strategyTradeNumber.value,
         legNumber                                   |-> legNumber.value ], legNumber.rest)

ZeroLegExecutionCancellationNotice ==
    [ group                                       |-> [i \in 1 .. 2 |-> 0],
      instrument                                  |-> [i \in 1 .. 4 |-> 0],
      traderId                                    |-> [i \in 1 .. 8 |-> 0],
      referenceIdOrderIdOrQuoteId                 |-> [i \in 1 .. 8 |-> 0],
      verbSide                                    |-> [i \in 1 .. 1 |-> 0],
      quantityTraded                              |-> [i \in 1 .. 8 |-> 0],
      tradePrice                                  |-> [i \in 1 .. 10 |-> 0],
      tradingEngineTimestampOfTheTradeLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      clearingData                                |-> ZeroClearingData8,
      ownerData                                   |-> ZeroOwnerData8,
      specialTradeIndicator                       |-> [i \in 1 .. 1 |-> 0],
      priceType                                   |-> [i \in 1 .. 1 |-> 0],
      tradeType                                   |-> [i \in 1 .. 1 |-> 0],
      filler6                                     |-> [i \in 1 .. 6 |-> 0],
      tradeNumber                                 |-> [i \in 1 .. 8 |-> 0],
      tradeMemo                                   |-> [i \in 1 .. 50 |-> 0],
      originalReferenceId                         |-> [i \in 1 .. 8 |-> 0],
      idCodeForTheCounterpartParticipant          |-> [i \in 1 .. 4 |-> 0],
      strategyGroup                               |-> [i \in 1 .. 2 |-> 0],
      strategyInstrumentId                        |-> [i \in 1 .. 4 |-> 0],
      strategyVerbSide                            |-> [i \in 1 .. 1 |-> 0],
      strategyTradeNumber                         |-> [i \in 1 .. 8 |-> 0],
      legNumber                                   |-> [i \in 1 .. 2 |-> 0] ]

(* Leg Execution Cancellation Notice at zero, then each field in turn at the values it is checked at *)
CheckedLegExecutionCancellationNotice ==
    { ZeroLegExecutionCancellationNotice }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.referenceIdOrderIdOrQuoteId = one] : one \in Sample(8) }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.verbSide = one] : one \in Sample(1) }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.quantityTraded = one] : one \in Sample(8) }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.tradePrice = one] : one \in Sample(10) }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.tradingEngineTimestampOfTheTradeLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.clearingData = one] : one \in CheckedClearingData8 }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.ownerData = one] : one \in CheckedOwnerData8 }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.specialTradeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.priceType = one] : one \in Sample(1) }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.filler6 = one] : one \in Sample(6) }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.tradeNumber = one] : one \in Sample(8) }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.tradeMemo = one] : one \in Sample(50) }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.originalReferenceId = one] : one \in Sample(8) }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.idCodeForTheCounterpartParticipant = one] : one \in Sample(4) }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.strategyGroup = one] : one \in Sample(2) }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.strategyInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.strategyVerbSide = one] : one \in Sample(1) }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.strategyTradeNumber = one] : one \in Sample(8) }
        \cup { [ZeroLegExecutionCancellationNotice EXCEPT !.legNumber = one] : one \in Sample(2) }

(***************************************************************************)
(* Clearing Data: 20 bytes                                                 *)
(***************************************************************************)

ClearingData9 ==
    [ clearingInstruction : Sample(12),
      accountType         : Sample(1),
      openClose           : Sample(1),
      hedgeSpec           : Sample(1),
      filler5             : Sample(5) ]

EncodeClearingData9(message) ==
    message.clearingInstruction
        \o message.accountType
        \o message.openClose
        \o message.hedgeSpec
        \o message.filler5

DecodeClearingData9(bytes) ==
    LET clearingInstruction == ReadBytes(bytes, 12) IN IF ~clearingInstruction.ok THEN Fail ELSE
    LET accountType == ReadBytes(clearingInstruction.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET openClose == ReadBytes(accountType.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET hedgeSpec == ReadBytes(openClose.rest, 1) IN IF ~hedgeSpec.ok THEN Fail ELSE
    LET filler5 == ReadBytes(hedgeSpec.rest, 5) IN IF ~filler5.ok THEN Fail ELSE
    Ok([ clearingInstruction |-> clearingInstruction.value,
         accountType         |-> accountType.value,
         openClose           |-> openClose.value,
         hedgeSpec           |-> hedgeSpec.value,
         filler5             |-> filler5.value ], filler5.rest)

ZeroClearingData9 ==
    [ clearingInstruction |-> [i \in 1 .. 12 |-> 0],
      accountType         |-> [i \in 1 .. 1 |-> 0],
      openClose           |-> [i \in 1 .. 1 |-> 0],
      hedgeSpec           |-> [i \in 1 .. 1 |-> 0],
      filler5             |-> [i \in 1 .. 5 |-> 0] ]

(* Clearing Data at zero, then each field in turn at the values it is checked at *)
CheckedClearingData9 ==
    { ZeroClearingData9 }
        \cup { [ZeroClearingData9 EXCEPT !.clearingInstruction = one] : one \in Sample(12) }
        \cup { [ZeroClearingData9 EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroClearingData9 EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroClearingData9 EXCEPT !.hedgeSpec = one] : one \in Sample(1) }
        \cup { [ZeroClearingData9 EXCEPT !.filler5 = one] : one \in Sample(5) }

(***************************************************************************)
(* Owner Data: 50 bytes                                                    *)
(***************************************************************************)

OwnerData9 ==
    [ memo : Sample(50) ]

EncodeOwnerData9(message) ==
    message.memo

DecodeOwnerData9(bytes) ==
    LET memo == ReadBytes(bytes, 50) IN IF ~memo.ok THEN Fail ELSE
    Ok([ memo |-> memo.value ], memo.rest)

ZeroOwnerData9 ==
    [ memo |-> [i \in 1 .. 50 |-> 0] ]

(* Owner Data at zero, then each field in turn at the values it is checked at *)
CheckedOwnerData9 ==
    { ZeroOwnerData9 }
        \cup { [ZeroOwnerData9 EXCEPT !.memo = one] : one \in Sample(50) }

(***************************************************************************)
(* Order Cancellation Notice By Mod Or System: 126 bytes                   *)
(***************************************************************************)

OrderCancellationNoticeByModOrSystem ==
    [ group           : Sample(2),
      instrument      : Sample(4),
      traderId        : Sample(8),
      orderId         : Sample(8),
      status          : Sample(1),
      verbSide        : Sample(1),
      quantity        : Sample(8),
      assignedPrice   : Sample(10),
      clearingData    : ClearingData9,
      ownerData       : OwnerData9,
      originalOrderId : Sample(8),
      filler6         : Sample(6) ]

EncodeOrderCancellationNoticeByModOrSystem(message) ==
    message.group
        \o message.instrument
        \o message.traderId
        \o message.orderId
        \o message.status
        \o message.verbSide
        \o message.quantity
        \o message.assignedPrice
        \o EncodeClearingData9(message.clearingData)
        \o EncodeOwnerData9(message.ownerData)
        \o message.originalOrderId
        \o message.filler6

DecodeOrderCancellationNoticeByModOrSystem(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrument == ReadBytes(group.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET traderId == ReadBytes(instrument.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET orderId == ReadBytes(traderId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET status == ReadBytes(orderId.rest, 1) IN IF ~status.ok THEN Fail ELSE
    LET verbSide == ReadBytes(status.rest, 1) IN IF ~verbSide.ok THEN Fail ELSE
    LET quantity == ReadBytes(verbSide.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET assignedPrice == ReadBytes(quantity.rest, 10) IN IF ~assignedPrice.ok THEN Fail ELSE
    LET clearingData == DecodeClearingData9(assignedPrice.rest) IN IF ~clearingData.ok THEN Fail ELSE
    LET ownerData == DecodeOwnerData9(clearingData.rest) IN IF ~ownerData.ok THEN Fail ELSE
    LET originalOrderId == ReadBytes(ownerData.rest, 8) IN IF ~originalOrderId.ok THEN Fail ELSE
    LET filler6 == ReadBytes(originalOrderId.rest, 6) IN IF ~filler6.ok THEN Fail ELSE
    Ok([ group           |-> group.value,
         instrument      |-> instrument.value,
         traderId        |-> traderId.value,
         orderId         |-> orderId.value,
         status          |-> status.value,
         verbSide        |-> verbSide.value,
         quantity        |-> quantity.value,
         assignedPrice   |-> assignedPrice.value,
         clearingData    |-> clearingData.value,
         ownerData       |-> ownerData.value,
         originalOrderId |-> originalOrderId.value,
         filler6         |-> filler6.value ], filler6.rest)

ZeroOrderCancellationNoticeByModOrSystem ==
    [ group           |-> [i \in 1 .. 2 |-> 0],
      instrument      |-> [i \in 1 .. 4 |-> 0],
      traderId        |-> [i \in 1 .. 8 |-> 0],
      orderId         |-> [i \in 1 .. 8 |-> 0],
      status          |-> [i \in 1 .. 1 |-> 0],
      verbSide        |-> [i \in 1 .. 1 |-> 0],
      quantity        |-> [i \in 1 .. 8 |-> 0],
      assignedPrice   |-> [i \in 1 .. 10 |-> 0],
      clearingData    |-> ZeroClearingData9,
      ownerData       |-> ZeroOwnerData9,
      originalOrderId |-> [i \in 1 .. 8 |-> 0],
      filler6         |-> [i \in 1 .. 6 |-> 0] ]

(* Order Cancellation Notice By Mod Or System at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancellationNoticeByModOrSystem ==
    { ZeroOrderCancellationNoticeByModOrSystem }
        \cup { [ZeroOrderCancellationNoticeByModOrSystem EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancellationNoticeByModOrSystem EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancellationNoticeByModOrSystem EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancellationNoticeByModOrSystem EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancellationNoticeByModOrSystem EXCEPT !.status = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancellationNoticeByModOrSystem EXCEPT !.verbSide = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancellationNoticeByModOrSystem EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancellationNoticeByModOrSystem EXCEPT !.assignedPrice = one] : one \in Sample(10) }
        \cup { [ZeroOrderCancellationNoticeByModOrSystem EXCEPT !.clearingData = one] : one \in CheckedClearingData9 }
        \cup { [ZeroOrderCancellationNoticeByModOrSystem EXCEPT !.ownerData = one] : one \in CheckedOwnerData9 }
        \cup { [ZeroOrderCancellationNoticeByModOrSystem EXCEPT !.originalOrderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancellationNoticeByModOrSystem EXCEPT !.filler6 = one] : one \in Sample(6) }

(***************************************************************************)
(* Outgoing Messages Header: 22 bytes                                      *)
(***************************************************************************)

OutgoingMessagesHeader18 ==
    [ tradingEngineTimestampLocalHhmmss : Sample(6),
      userSequenceId                    : Sample(8),
      exchangeMessageId                 : Sample(6),
      gapSequenceId                     : Sample(2) ]

EncodeOutgoingMessagesHeader18(message) ==
    message.tradingEngineTimestampLocalHhmmss
        \o message.userSequenceId
        \o message.exchangeMessageId
        \o message.gapSequenceId

DecodeOutgoingMessagesHeader18(bytes) ==
    LET tradingEngineTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~tradingEngineTimestampLocalHhmmss.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(tradingEngineTimestampLocalHhmmss.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    LET exchangeMessageId == ReadBytes(userSequenceId.rest, 6) IN IF ~exchangeMessageId.ok THEN Fail ELSE
    LET gapSequenceId == ReadBytes(exchangeMessageId.rest, 2) IN IF ~gapSequenceId.ok THEN Fail ELSE
    Ok([ tradingEngineTimestampLocalHhmmss |-> tradingEngineTimestampLocalHhmmss.value,
         userSequenceId                    |-> userSequenceId.value,
         exchangeMessageId                 |-> exchangeMessageId.value,
         gapSequenceId                     |-> gapSequenceId.value ], gapSequenceId.rest)

ZeroOutgoingMessagesHeader18 ==
    [ tradingEngineTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      userSequenceId                    |-> [i \in 1 .. 8 |-> 0],
      exchangeMessageId                 |-> [i \in 1 .. 6 |-> 0],
      gapSequenceId                     |-> [i \in 1 .. 2 |-> 0] ]

(* Outgoing Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedOutgoingMessagesHeader18 ==
    { ZeroOutgoingMessagesHeader18 }
        \cup { [ZeroOutgoingMessagesHeader18 EXCEPT !.tradingEngineTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroOutgoingMessagesHeader18 EXCEPT !.userSequenceId = one] : one \in Sample(8) }
        \cup { [ZeroOutgoingMessagesHeader18 EXCEPT !.exchangeMessageId = one] : one \in Sample(6) }
        \cup { [ZeroOutgoingMessagesHeader18 EXCEPT !.gapSequenceId = one] : one \in Sample(2) }

(***************************************************************************)
(* Request For Quote With Side Acknowledgement: 37 bytes                   *)
(***************************************************************************)

RequestForQuoteWithSideAcknowledgement ==
    [ outgoingMessagesHeader : OutgoingMessagesHeader18,
      group                  : Sample(2),
      instrument             : Sample(4),
      quantity               : Sample(8),
      marketSide             : Sample(1) ]

EncodeRequestForQuoteWithSideAcknowledgement(message) ==
    EncodeOutgoingMessagesHeader18(message.outgoingMessagesHeader)
        \o message.group
        \o message.instrument
        \o message.quantity
        \o message.marketSide

DecodeRequestForQuoteWithSideAcknowledgement(bytes) ==
    LET outgoingMessagesHeader == DecodeOutgoingMessagesHeader18(bytes) IN IF ~outgoingMessagesHeader.ok THEN Fail ELSE
    LET group == ReadBytes(outgoingMessagesHeader.rest, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrument == ReadBytes(group.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET quantity == ReadBytes(instrument.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET marketSide == ReadBytes(quantity.rest, 1) IN IF ~marketSide.ok THEN Fail ELSE
    Ok([ outgoingMessagesHeader |-> outgoingMessagesHeader.value,
         group                  |-> group.value,
         instrument             |-> instrument.value,
         quantity               |-> quantity.value,
         marketSide             |-> marketSide.value ], marketSide.rest)

ZeroRequestForQuoteWithSideAcknowledgement ==
    [ outgoingMessagesHeader |-> ZeroOutgoingMessagesHeader18,
      group                  |-> [i \in 1 .. 2 |-> 0],
      instrument             |-> [i \in 1 .. 4 |-> 0],
      quantity               |-> [i \in 1 .. 8 |-> 0],
      marketSide             |-> [i \in 1 .. 1 |-> 0] ]

(* Request For Quote With Side Acknowledgement at zero, then each field in turn at the values it is checked at *)
CheckedRequestForQuoteWithSideAcknowledgement ==
    { ZeroRequestForQuoteWithSideAcknowledgement }
        \cup { [ZeroRequestForQuoteWithSideAcknowledgement EXCEPT !.outgoingMessagesHeader = one] : one \in CheckedOutgoingMessagesHeader18 }
        \cup { [ZeroRequestForQuoteWithSideAcknowledgement EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroRequestForQuoteWithSideAcknowledgement EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroRequestForQuoteWithSideAcknowledgement EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroRequestForQuoteWithSideAcknowledgement EXCEPT !.marketSide = one] : one \in Sample(1) }

(***************************************************************************)
(* Exchange Message, selected by Message Type                              *)
(***************************************************************************)

ConnectionAcknowledgementCode == 21579  \* "TK"
DisconnectionInstructionAcknowledgementCode == 21581  \* "TM"
HeartbeatQuestionCode == 21576  \* "TH"
OutOfSequenceCode == 21583  \* "TO"
TechnicalErrorNoticeCode == 21573  \* "TE"
DisconnectionAcknowledgementCode == 21580  \* "TL"
EndOfTransmissionCode == 21588  \* "TT"
OrderReplyCode == 16709  \* "AE"
ErrorNoticeCode == 17746  \* "ER"
BulkQuoteDataAcknowledgementCode == 19268  \* "KD"
OrderAcknowledgementCode == 19269  \* "KE"
GlobalCancellationConfirmationCode == 19271  \* "KG"
OrderModificationAcknowledgementCode == 19277  \* "KM"
NewStrategyInstrumentAcknowledgementCode == 19278  \* "KN"
StandardAcknowledgementCode == 19279  \* "KO"
OrderCancellationAcknowledgementCode == 19290  \* "KZ"
BulkQuoteAcknowledgementCode == 19521  \* "LA"
BulkCommandAcknowledgementCode == 19522  \* "LB"
RiskLimitsUsageCode == 19790  \* "MN"
ExcludedInstrumentNoticeCode == 20037  \* "NE"
GroupStateChangeCode == 20039  \* "NG"
InstrumentStateChangeCode == 20041  \* "NI"
LegExecutionNoticeCode == 20044  \* "NL"
OversteppedOrderOrQuoteNoticeCode == 20047  \* "NO"
CancellationOfAllQuotesNoticeCode == 20048  \* "NP"
ExecutionNoticeCode == 20052  \* "NT"
ExecutionCancellationNoticeCode == 20056  \* "NX"
LegExecutionCancellationNoticeCode == 20057  \* "NY"
OrderCancellationNoticeByModOrSystemCode == 20058  \* "NZ"
RequestForQuoteWithSideAcknowledgementCode == 20823  \* "QW"

ExchangeMessage ==
    [ tag : {ConnectionAcknowledgementCode}, body : ConnectionAcknowledgement ]
        \cup [ tag : {DisconnectionInstructionAcknowledgementCode}, body : DisconnectionInstructionAcknowledgement ]
        \cup [ tag : {HeartbeatQuestionCode}, body : HeartbeatQuestion ]
        \cup [ tag : {OutOfSequenceCode}, body : OutOfSequence ]
        \cup [ tag : {TechnicalErrorNoticeCode}, body : TechnicalErrorNotice ]
        \cup [ tag : {DisconnectionAcknowledgementCode}, body : DisconnectionAcknowledgement ]
        \cup [ tag : {EndOfTransmissionCode}, body : EndOfTransmission ]
        \cup [ tag : {OrderReplyCode}, body : OrderReply ]
        \cup [ tag : {ErrorNoticeCode}, body : ErrorNotice ]
        \cup [ tag : {BulkQuoteDataAcknowledgementCode}, body : BulkQuoteDataAcknowledgement ]
        \cup [ tag : {OrderAcknowledgementCode}, body : OrderAcknowledgement ]
        \cup [ tag : {GlobalCancellationConfirmationCode}, body : GlobalCancellationConfirmation ]
        \cup [ tag : {OrderModificationAcknowledgementCode}, body : OrderModificationAcknowledgement ]
        \cup [ tag : {NewStrategyInstrumentAcknowledgementCode}, body : NewStrategyInstrumentAcknowledgement ]
        \cup [ tag : {StandardAcknowledgementCode}, body : StandardAcknowledgement ]
        \cup [ tag : {OrderCancellationAcknowledgementCode}, body : OrderCancellationAcknowledgement ]
        \cup [ tag : {BulkQuoteAcknowledgementCode}, body : BulkQuoteAcknowledgement ]
        \cup [ tag : {BulkCommandAcknowledgementCode}, body : BulkCommandAcknowledgement ]
        \cup [ tag : {RiskLimitsUsageCode}, body : RiskLimitsUsage ]
        \cup [ tag : {ExcludedInstrumentNoticeCode}, body : ExcludedInstrumentNotice ]
        \cup [ tag : {GroupStateChangeCode}, body : GroupStateChange ]
        \cup [ tag : {InstrumentStateChangeCode}, body : InstrumentStateChange ]
        \cup [ tag : {LegExecutionNoticeCode}, body : LegExecutionNotice ]
        \cup [ tag : {OversteppedOrderOrQuoteNoticeCode}, body : OversteppedOrderOrQuoteNotice ]
        \cup [ tag : {CancellationOfAllQuotesNoticeCode}, body : CancellationOfAllQuotesNotice ]
        \cup [ tag : {ExecutionNoticeCode}, body : ExecutionNotice ]
        \cup [ tag : {ExecutionCancellationNoticeCode}, body : ExecutionCancellationNotice ]
        \cup [ tag : {LegExecutionCancellationNoticeCode}, body : LegExecutionCancellationNotice ]
        \cup [ tag : {OrderCancellationNoticeByModOrSystemCode}, body : OrderCancellationNoticeByModOrSystem ]
        \cup [ tag : {RequestForQuoteWithSideAcknowledgementCode}, body : RequestForQuoteWithSideAcknowledgement ]

EncodeExchangeMessage(message) ==
    CASE message.tag = ConnectionAcknowledgementCode -> EncodeConnectionAcknowledgement(message.body)
      [] message.tag = DisconnectionInstructionAcknowledgementCode -> EncodeDisconnectionInstructionAcknowledgement(message.body)
      [] message.tag = HeartbeatQuestionCode -> EncodeHeartbeatQuestion(message.body)
      [] message.tag = OutOfSequenceCode -> EncodeOutOfSequence(message.body)
      [] message.tag = TechnicalErrorNoticeCode -> EncodeTechnicalErrorNotice(message.body)
      [] message.tag = DisconnectionAcknowledgementCode -> EncodeDisconnectionAcknowledgement(message.body)
      [] message.tag = EndOfTransmissionCode -> EncodeEndOfTransmission(message.body)
      [] message.tag = OrderReplyCode -> EncodeOrderReply(message.body)
      [] message.tag = ErrorNoticeCode -> EncodeErrorNotice(message.body)
      [] message.tag = BulkQuoteDataAcknowledgementCode -> EncodeBulkQuoteDataAcknowledgement(message.body)
      [] message.tag = OrderAcknowledgementCode -> EncodeOrderAcknowledgement(message.body)
      [] message.tag = GlobalCancellationConfirmationCode -> EncodeGlobalCancellationConfirmation(message.body)
      [] message.tag = OrderModificationAcknowledgementCode -> EncodeOrderModificationAcknowledgement(message.body)
      [] message.tag = NewStrategyInstrumentAcknowledgementCode -> EncodeNewStrategyInstrumentAcknowledgement(message.body)
      [] message.tag = StandardAcknowledgementCode -> EncodeStandardAcknowledgement(message.body)
      [] message.tag = OrderCancellationAcknowledgementCode -> EncodeOrderCancellationAcknowledgement(message.body)
      [] message.tag = BulkQuoteAcknowledgementCode -> EncodeBulkQuoteAcknowledgement(message.body)
      [] message.tag = BulkCommandAcknowledgementCode -> EncodeBulkCommandAcknowledgement(message.body)
      [] message.tag = RiskLimitsUsageCode -> EncodeRiskLimitsUsage(message.body)
      [] message.tag = ExcludedInstrumentNoticeCode -> EncodeExcludedInstrumentNotice(message.body)
      [] message.tag = GroupStateChangeCode -> EncodeGroupStateChange(message.body)
      [] message.tag = InstrumentStateChangeCode -> EncodeInstrumentStateChange(message.body)
      [] message.tag = LegExecutionNoticeCode -> EncodeLegExecutionNotice(message.body)
      [] message.tag = OversteppedOrderOrQuoteNoticeCode -> EncodeOversteppedOrderOrQuoteNotice(message.body)
      [] message.tag = CancellationOfAllQuotesNoticeCode -> EncodeCancellationOfAllQuotesNotice(message.body)
      [] message.tag = ExecutionNoticeCode -> EncodeExecutionNotice(message.body)
      [] message.tag = ExecutionCancellationNoticeCode -> EncodeExecutionCancellationNotice(message.body)
      [] message.tag = LegExecutionCancellationNoticeCode -> EncodeLegExecutionCancellationNotice(message.body)
      [] message.tag = OrderCancellationNoticeByModOrSystemCode -> EncodeOrderCancellationNoticeByModOrSystem(message.body)
      [] message.tag = RequestForQuoteWithSideAcknowledgementCode -> EncodeRequestForQuoteWithSideAcknowledgement(message.body)

DecodeExchangeMessage(tag, bytes) ==
    LET read ==
            CASE tag = ConnectionAcknowledgementCode -> DecodeConnectionAcknowledgement(bytes)
              [] tag = DisconnectionInstructionAcknowledgementCode -> DecodeDisconnectionInstructionAcknowledgement(bytes)
              [] tag = HeartbeatQuestionCode -> DecodeHeartbeatQuestion(bytes)
              [] tag = OutOfSequenceCode -> DecodeOutOfSequence(bytes)
              [] tag = TechnicalErrorNoticeCode -> DecodeTechnicalErrorNotice(bytes)
              [] tag = DisconnectionAcknowledgementCode -> DecodeDisconnectionAcknowledgement(bytes)
              [] tag = EndOfTransmissionCode -> DecodeEndOfTransmission(bytes)
              [] tag = OrderReplyCode -> DecodeOrderReply(bytes)
              [] tag = ErrorNoticeCode -> DecodeErrorNotice(bytes)
              [] tag = BulkQuoteDataAcknowledgementCode -> DecodeBulkQuoteDataAcknowledgement(bytes)
              [] tag = OrderAcknowledgementCode -> DecodeOrderAcknowledgement(bytes)
              [] tag = GlobalCancellationConfirmationCode -> DecodeGlobalCancellationConfirmation(bytes)
              [] tag = OrderModificationAcknowledgementCode -> DecodeOrderModificationAcknowledgement(bytes)
              [] tag = NewStrategyInstrumentAcknowledgementCode -> DecodeNewStrategyInstrumentAcknowledgement(bytes)
              [] tag = StandardAcknowledgementCode -> DecodeStandardAcknowledgement(bytes)
              [] tag = OrderCancellationAcknowledgementCode -> DecodeOrderCancellationAcknowledgement(bytes)
              [] tag = BulkQuoteAcknowledgementCode -> DecodeBulkQuoteAcknowledgement(bytes)
              [] tag = BulkCommandAcknowledgementCode -> DecodeBulkCommandAcknowledgement(bytes)
              [] tag = RiskLimitsUsageCode -> DecodeRiskLimitsUsage(bytes)
              [] tag = ExcludedInstrumentNoticeCode -> DecodeExcludedInstrumentNotice(bytes)
              [] tag = GroupStateChangeCode -> DecodeGroupStateChange(bytes)
              [] tag = InstrumentStateChangeCode -> DecodeInstrumentStateChange(bytes)
              [] tag = LegExecutionNoticeCode -> DecodeLegExecutionNotice(bytes)
              [] tag = OversteppedOrderOrQuoteNoticeCode -> DecodeOversteppedOrderOrQuoteNotice(bytes)
              [] tag = CancellationOfAllQuotesNoticeCode -> DecodeCancellationOfAllQuotesNotice(bytes)
              [] tag = ExecutionNoticeCode -> DecodeExecutionNotice(bytes)
              [] tag = ExecutionCancellationNoticeCode -> DecodeExecutionCancellationNotice(bytes)
              [] tag = LegExecutionCancellationNoticeCode -> DecodeLegExecutionCancellationNotice(bytes)
              [] tag = OrderCancellationNoticeByModOrSystemCode -> DecodeOrderCancellationNoticeByModOrSystem(bytes)
              [] tag = RequestForQuoteWithSideAcknowledgementCode -> DecodeRequestForQuoteWithSideAcknowledgement(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroExchangeMessage == [tag |-> ConnectionAcknowledgementCode, body |-> ZeroConnectionAcknowledgement]

(* Each Exchange Message in turn, at the values the message it names is checked at *)
CheckedExchangeMessage ==
    { [tag |-> ConnectionAcknowledgementCode, body |-> one] : one \in CheckedConnectionAcknowledgement }
        \cup { [tag |-> DisconnectionInstructionAcknowledgementCode, body |-> one] : one \in CheckedDisconnectionInstructionAcknowledgement }
        \cup { [tag |-> HeartbeatQuestionCode, body |-> one] : one \in CheckedHeartbeatQuestion }
        \cup { [tag |-> OutOfSequenceCode, body |-> one] : one \in CheckedOutOfSequence }
        \cup { [tag |-> TechnicalErrorNoticeCode, body |-> one] : one \in CheckedTechnicalErrorNotice }
        \cup { [tag |-> DisconnectionAcknowledgementCode, body |-> one] : one \in CheckedDisconnectionAcknowledgement }
        \cup { [tag |-> EndOfTransmissionCode, body |-> one] : one \in CheckedEndOfTransmission }
        \cup { [tag |-> OrderReplyCode, body |-> one] : one \in CheckedOrderReply }
        \cup { [tag |-> ErrorNoticeCode, body |-> one] : one \in CheckedErrorNotice }
        \cup { [tag |-> BulkQuoteDataAcknowledgementCode, body |-> one] : one \in CheckedBulkQuoteDataAcknowledgement }
        \cup { [tag |-> OrderAcknowledgementCode, body |-> one] : one \in CheckedOrderAcknowledgement }
        \cup { [tag |-> GlobalCancellationConfirmationCode, body |-> one] : one \in CheckedGlobalCancellationConfirmation }
        \cup { [tag |-> OrderModificationAcknowledgementCode, body |-> one] : one \in CheckedOrderModificationAcknowledgement }
        \cup { [tag |-> NewStrategyInstrumentAcknowledgementCode, body |-> one] : one \in CheckedNewStrategyInstrumentAcknowledgement }
        \cup { [tag |-> StandardAcknowledgementCode, body |-> one] : one \in CheckedStandardAcknowledgement }
        \cup { [tag |-> OrderCancellationAcknowledgementCode, body |-> one] : one \in CheckedOrderCancellationAcknowledgement }
        \cup { [tag |-> BulkQuoteAcknowledgementCode, body |-> one] : one \in CheckedBulkQuoteAcknowledgement }
        \cup { [tag |-> BulkCommandAcknowledgementCode, body |-> one] : one \in CheckedBulkCommandAcknowledgement }
        \cup { [tag |-> RiskLimitsUsageCode, body |-> one] : one \in CheckedRiskLimitsUsage }
        \cup { [tag |-> ExcludedInstrumentNoticeCode, body |-> one] : one \in CheckedExcludedInstrumentNotice }
        \cup { [tag |-> GroupStateChangeCode, body |-> one] : one \in CheckedGroupStateChange }
        \cup { [tag |-> InstrumentStateChangeCode, body |-> one] : one \in CheckedInstrumentStateChange }
        \cup { [tag |-> LegExecutionNoticeCode, body |-> one] : one \in CheckedLegExecutionNotice }
        \cup { [tag |-> OversteppedOrderOrQuoteNoticeCode, body |-> one] : one \in CheckedOversteppedOrderOrQuoteNotice }
        \cup { [tag |-> CancellationOfAllQuotesNoticeCode, body |-> one] : one \in CheckedCancellationOfAllQuotesNotice }
        \cup { [tag |-> ExecutionNoticeCode, body |-> one] : one \in CheckedExecutionNotice }
        \cup { [tag |-> ExecutionCancellationNoticeCode, body |-> one] : one \in CheckedExecutionCancellationNotice }
        \cup { [tag |-> LegExecutionCancellationNoticeCode, body |-> one] : one \in CheckedLegExecutionCancellationNotice }
        \cup { [tag |-> OrderCancellationNoticeByModOrSystemCode, body |-> one] : one \in CheckedOrderCancellationNoticeByModOrSystem }
        \cup { [tag |-> RequestForQuoteWithSideAcknowledgementCode, body |-> one] : one \in CheckedRequestForQuoteWithSideAcknowledgement }

(***************************************************************************)
(* Exchange Packet                                                         *)
(***************************************************************************)

ExchangePacket ==
    [ messageLength    : 0 .. 255,
      exchangeMessage  : ExchangeMessage,
      endOfText        : Sample(1),
      alignmentPadding : SampleBytes ]

EncodeExchangePacket(message) ==
    EncodeUIntLE(message.messageLength, 4)
        \o EncodeUIntBE(message.exchangeMessage.tag, 2)
        \o EncodeExchangeMessage(message.exchangeMessage)
        \o message.endOfText
        \o message.alignmentPadding

DecodeExchangePacket(bytes) ==
    LET messageLength == ReadUIntLE(bytes, 4) IN IF ~messageLength.ok THEN Fail ELSE
    LET messageType == ReadUIntBE(messageLength.rest, 2) IN IF ~messageType.ok THEN Fail ELSE
    LET exchangeMessage == DecodeExchangeMessage(messageType.value, messageType.rest) IN IF ~exchangeMessage.ok THEN Fail ELSE
    LET endOfText == ReadBytes(exchangeMessage.rest, 1) IN IF ~endOfText.ok THEN Fail ELSE
    LET alignmentPadding == Ok(endOfText.rest, << >>) IN IF ~alignmentPadding.ok THEN Fail ELSE
    Ok([ messageLength    |-> messageLength.value,
         exchangeMessage  |-> exchangeMessage.value,
         endOfText        |-> endOfText.value,
         alignmentPadding |-> alignmentPadding.value ], alignmentPadding.rest)

ZeroExchangePacket ==
    [ messageLength    |-> 0,
      exchangeMessage  |-> ZeroExchangeMessage,
      endOfText        |-> [i \in 1 .. 1 |-> 0],
      alignmentPadding |-> << >> ]

(* Exchange Packet at zero, then each field in turn at the values it is checked at *)
CheckedExchangePacket ==
    { ZeroExchangePacket }
        \cup { [ZeroExchangePacket EXCEPT !.messageLength = one] : one \in {0, 1, 255} }
        \cup { [ZeroExchangePacket EXCEPT !.exchangeMessage = one] : one \in CheckedExchangeMessage }
        \cup { [ZeroExchangePacket EXCEPT !.endOfText = one] : one \in Sample(1) }
        \cup { [ZeroExchangePacket EXCEPT !.alignmentPadding = one] : one \in SampleBytes }

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

(* Every Connection Acknowledgement decodes back to what was encoded, and leaves nothing over *)
RoundTripConnectionAcknowledgement ==
    \A message \in CheckedConnectionAcknowledgement :
        LET read == DecodeConnectionAcknowledgement(EncodeConnectionAcknowledgement(message))
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

(* Every Outgoing Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripOutgoingMessagesHeader ==
    \A message \in CheckedOutgoingMessagesHeader :
        LET read == DecodeOutgoingMessagesHeader(EncodeOutgoingMessagesHeader(message))
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

(* Every Order Reply decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderReply ==
    \A message \in CheckedOrderReply :
        LET read == DecodeOrderReply(EncodeOrderReply(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Outgoing Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripOutgoingMessagesHeader2 ==
    \A message \in CheckedOutgoingMessagesHeader2 :
        LET read == DecodeOutgoingMessagesHeader2(EncodeOutgoingMessagesHeader2(message))
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

(* Every Outgoing Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripOutgoingMessagesHeader3 ==
    \A message \in CheckedOutgoingMessagesHeader3 :
        LET read == DecodeOutgoingMessagesHeader3(EncodeOutgoingMessagesHeader3(message))
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

(* Every Outgoing Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripOutgoingMessagesHeader4 ==
    \A message \in CheckedOutgoingMessagesHeader4 :
        LET read == DecodeOutgoingMessagesHeader4(EncodeOutgoingMessagesHeader4(message))
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

(* Every Order Acknowledgement decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderAcknowledgement ==
    \A message \in CheckedOrderAcknowledgement :
        LET read == DecodeOrderAcknowledgement(EncodeOrderAcknowledgement(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Outgoing Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripOutgoingMessagesHeader5 ==
    \A message \in CheckedOutgoingMessagesHeader5 :
        LET read == DecodeOutgoingMessagesHeader5(EncodeOutgoingMessagesHeader5(message))
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

(* Every Outgoing Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripOutgoingMessagesHeader6 ==
    \A message \in CheckedOutgoingMessagesHeader6 :
        LET read == DecodeOutgoingMessagesHeader6(EncodeOutgoingMessagesHeader6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Strategy Instrument Acknowledgement Leg Definition Repeating Block decodes back to what was encoded, and leaves nothing over *)
RoundTripNewStrategyInstrumentAcknowledgementLegDefinitionRepeatingBlock ==
    \A message \in CheckedNewStrategyInstrumentAcknowledgementLegDefinitionRepeatingBlock :
        LET read == DecodeNewStrategyInstrumentAcknowledgementLegDefinitionRepeatingBlock(EncodeNewStrategyInstrumentAcknowledgementLegDefinitionRepeatingBlock(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Strategy Instrument Acknowledgement decodes back to what was encoded, and leaves nothing over *)
RoundTripNewStrategyInstrumentAcknowledgement ==
    \A message \in CheckedNewStrategyInstrumentAcknowledgement :
        LET read == DecodeNewStrategyInstrumentAcknowledgement(EncodeNewStrategyInstrumentAcknowledgement(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Outgoing Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripOutgoingMessagesHeader7 ==
    \A message \in CheckedOutgoingMessagesHeader7 :
        LET read == DecodeOutgoingMessagesHeader7(EncodeOutgoingMessagesHeader7(message))
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

(* Every Order Cancellation Acknowledgement decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancellationAcknowledgement ==
    \A message \in CheckedOrderCancellationAcknowledgement :
        LET read == DecodeOrderCancellationAcknowledgement(EncodeOrderCancellationAcknowledgement(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Outgoing Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripOutgoingMessagesHeader8 ==
    \A message \in CheckedOutgoingMessagesHeader8 :
        LET read == DecodeOutgoingMessagesHeader8(EncodeOutgoingMessagesHeader8(message))
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

(* Every Outgoing Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripOutgoingMessagesHeader9 ==
    \A message \in CheckedOutgoingMessagesHeader9 :
        LET read == DecodeOutgoingMessagesHeader9(EncodeOutgoingMessagesHeader9(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulk Command Acknowledgement Occurrence decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkCommandAcknowledgementOccurrence ==
    \A message \in CheckedBulkCommandAcknowledgementOccurrence :
        LET read == DecodeBulkCommandAcknowledgementOccurrence(EncodeBulkCommandAcknowledgementOccurrence(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulk Command Acknowledgement decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkCommandAcknowledgement ==
    \A message \in CheckedBulkCommandAcknowledgement :
        LET read == DecodeBulkCommandAcknowledgement(EncodeBulkCommandAcknowledgement(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Outgoing Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripOutgoingMessagesHeader10 ==
    \A message \in CheckedOutgoingMessagesHeader10 :
        LET read == DecodeOutgoingMessagesHeader10(EncodeOutgoingMessagesHeader10(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Risk Limits Usage Occurrence decodes back to what was encoded, and leaves nothing over *)
RoundTripRiskLimitsUsageOccurrence ==
    \A message \in CheckedRiskLimitsUsageOccurrence :
        LET read == DecodeRiskLimitsUsageOccurrence(EncodeRiskLimitsUsageOccurrence(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Risk Limits Usage decodes back to what was encoded, and leaves nothing over *)
RoundTripRiskLimitsUsage ==
    \A message \in CheckedRiskLimitsUsage :
        LET read == DecodeRiskLimitsUsage(EncodeRiskLimitsUsage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Outgoing Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripOutgoingMessagesHeader11 ==
    \A message \in CheckedOutgoingMessagesHeader11 :
        LET read == DecodeOutgoingMessagesHeader11(EncodeOutgoingMessagesHeader11(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Excluded Instrument Notice Occurrence decodes back to what was encoded, and leaves nothing over *)
RoundTripExcludedInstrumentNoticeOccurrence ==
    \A message \in CheckedExcludedInstrumentNoticeOccurrence :
        LET read == DecodeExcludedInstrumentNoticeOccurrence(EncodeExcludedInstrumentNoticeOccurrence(message))
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

(* Every Outgoing Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripOutgoingMessagesHeader12 ==
    \A message \in CheckedOutgoingMessagesHeader12 :
        LET read == DecodeOutgoingMessagesHeader12(EncodeOutgoingMessagesHeader12(message))
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

(* Every Outgoing Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripOutgoingMessagesHeader13 ==
    \A message \in CheckedOutgoingMessagesHeader13 :
        LET read == DecodeOutgoingMessagesHeader13(EncodeOutgoingMessagesHeader13(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument State Change decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentStateChange ==
    \A message \in CheckedInstrumentStateChange :
        LET read == DecodeInstrumentStateChange(EncodeInstrumentStateChange(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Outgoing Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripOutgoingMessagesHeader14 ==
    \A message \in CheckedOutgoingMessagesHeader14 :
        LET read == DecodeOutgoingMessagesHeader14(EncodeOutgoingMessagesHeader14(message))
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

(* Every Leg Execution Notice decodes back to what was encoded, and leaves nothing over *)
RoundTripLegExecutionNotice ==
    \A message \in CheckedLegExecutionNotice :
        LET read == DecodeLegExecutionNotice(EncodeLegExecutionNotice(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Outgoing Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripOutgoingMessagesHeader15 ==
    \A message \in CheckedOutgoingMessagesHeader15 :
        LET read == DecodeOutgoingMessagesHeader15(EncodeOutgoingMessagesHeader15(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Counterpart Owner Data decodes back to what was encoded, and leaves nothing over *)
RoundTripCounterpartOwnerData ==
    \A message \in CheckedCounterpartOwnerData :
        LET read == DecodeCounterpartOwnerData(EncodeCounterpartOwnerData(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Overstepped Order Or Quote Notice decodes back to what was encoded, and leaves nothing over *)
RoundTripOversteppedOrderOrQuoteNotice ==
    \A message \in CheckedOversteppedOrderOrQuoteNotice :
        LET read == DecodeOversteppedOrderOrQuoteNotice(EncodeOversteppedOrderOrQuoteNotice(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Outgoing Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripOutgoingMessagesHeader16 ==
    \A message \in CheckedOutgoingMessagesHeader16 :
        LET read == DecodeOutgoingMessagesHeader16(EncodeOutgoingMessagesHeader16(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancellation Of All Quotes Notice decodes back to what was encoded, and leaves nothing over *)
RoundTripCancellationOfAllQuotesNotice ==
    \A message \in CheckedCancellationOfAllQuotesNotice :
        LET read == DecodeCancellationOfAllQuotesNotice(EncodeCancellationOfAllQuotesNotice(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Outgoing Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripOutgoingMessagesHeader17 ==
    \A message \in CheckedOutgoingMessagesHeader17 :
        LET read == DecodeOutgoingMessagesHeader17(EncodeOutgoingMessagesHeader17(message))
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

(* Every Execution Notice decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionNotice ==
    \A message \in CheckedExecutionNotice :
        LET read == DecodeExecutionNotice(EncodeExecutionNotice(message))
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

(* Every Execution Cancellation Notice decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionCancellationNotice ==
    \A message \in CheckedExecutionCancellationNotice :
        LET read == DecodeExecutionCancellationNotice(EncodeExecutionCancellationNotice(message))
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

(* Every Leg Execution Cancellation Notice decodes back to what was encoded, and leaves nothing over *)
RoundTripLegExecutionCancellationNotice ==
    \A message \in CheckedLegExecutionCancellationNotice :
        LET read == DecodeLegExecutionCancellationNotice(EncodeLegExecutionCancellationNotice(message))
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

(* Every Order Cancellation Notice By Mod Or System decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancellationNoticeByModOrSystem ==
    \A message \in CheckedOrderCancellationNoticeByModOrSystem :
        LET read == DecodeOrderCancellationNoticeByModOrSystem(EncodeOrderCancellationNoticeByModOrSystem(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Outgoing Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripOutgoingMessagesHeader18 ==
    \A message \in CheckedOutgoingMessagesHeader18 :
        LET read == DecodeOutgoingMessagesHeader18(EncodeOutgoingMessagesHeader18(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request For Quote With Side Acknowledgement decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestForQuoteWithSideAcknowledgement ==
    \A message \in CheckedRequestForQuoteWithSideAcknowledgement :
        LET read == DecodeRequestForQuoteWithSideAcknowledgement(EncodeRequestForQuoteWithSideAcknowledgement(message))
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
