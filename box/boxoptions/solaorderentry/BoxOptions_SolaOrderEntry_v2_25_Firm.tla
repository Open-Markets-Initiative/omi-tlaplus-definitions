--------------- MODULE BoxOptions_SolaOrderEntry_v2_25_Firm ----------------
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
(* User Connection Occurrence: 2 bytes                                     *)
(***************************************************************************)

UserConnectionOccurrence ==
    [ messageTypesToBeReceived : Sample(2) ]

EncodeUserConnectionOccurrence(message) ==
    message.messageTypesToBeReceived

DecodeUserConnectionOccurrence(bytes) ==
    LET messageTypesToBeReceived == ReadBytes(bytes, 2) IN IF ~messageTypesToBeReceived.ok THEN Fail ELSE
    Ok([ messageTypesToBeReceived |-> messageTypesToBeReceived.value ], messageTypesToBeReceived.rest)

ZeroUserConnectionOccurrence ==
    [ messageTypesToBeReceived |-> [i \in 1 .. 2 |-> 0] ]

(* User Connection Occurrence at zero, then each field in turn at the values it is checked at *)
CheckedUserConnectionOccurrence ==
    { ZeroUserConnectionOccurrence }
        \cup { [ZeroUserConnectionOccurrence EXCEPT !.messageTypesToBeReceived = one] : one \in Sample(2) }

(* A run of User Connection Occurrence, written one after another *)
RECURSIVE EncodeUserConnectionOccurrenceList(_)
EncodeUserConnectionOccurrenceList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeUserConnectionOccurrence(Head(messages)) \o EncodeUserConnectionOccurrenceList(Tail(messages))

(* As many User Connection Occurrence as the field that counts them says *)
RECURSIVE ReadUserConnectionOccurrenceList(_, _)
ReadUserConnectionOccurrenceList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeUserConnectionOccurrence(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadUserConnectionOccurrenceList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One User Connection Occurrence of each kind, for the lists that carry them *)
OneUserConnectionOccurrence == { ZeroUserConnectionOccurrence }

(***************************************************************************)
(* User Connection                                                         *)
(***************************************************************************)

UserConnection ==
    [ protocolVersion          : Sample(2),
      userId                   : Sample(8),
      passwordMd5Encryption    : Sample(8),
      sessionId                : Sample(4),
      timeHhmmss               : Sample(6),
      exchangeMessageId        : Sample(6),
      inactivityInterval       : Sample(2),
      userConnectionOccurrence : SampleLists(OneUserConnectionOccurrence) ]

EncodeUserConnection(message) ==
    message.protocolVersion
        \o message.userId
        \o message.passwordMd5Encryption
        \o message.sessionId
        \o message.timeHhmmss
        \o message.exchangeMessageId
        \o message.inactivityInterval
        \o EncodeDigits(Len(message.userConnectionOccurrence), 2)
        \o EncodeUserConnectionOccurrenceList(message.userConnectionOccurrence)

DecodeUserConnection(bytes) ==
    LET protocolVersion == ReadBytes(bytes, 2) IN IF ~protocolVersion.ok THEN Fail ELSE
    LET userId == ReadBytes(protocolVersion.rest, 8) IN IF ~userId.ok THEN Fail ELSE
    LET passwordMd5Encryption == ReadBytes(userId.rest, 8) IN IF ~passwordMd5Encryption.ok THEN Fail ELSE
    LET sessionId == ReadBytes(passwordMd5Encryption.rest, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET timeHhmmss == ReadBytes(sessionId.rest, 6) IN IF ~timeHhmmss.ok THEN Fail ELSE
    LET exchangeMessageId == ReadBytes(timeHhmmss.rest, 6) IN IF ~exchangeMessageId.ok THEN Fail ELSE
    LET inactivityInterval == ReadBytes(exchangeMessageId.rest, 2) IN IF ~inactivityInterval.ok THEN Fail ELSE
    LET numberOfMessageTypesToBeReceived == ReadDigits(inactivityInterval.rest, 2) IN IF ~numberOfMessageTypesToBeReceived.ok THEN Fail ELSE
    LET userConnectionOccurrence == ReadUserConnectionOccurrenceList(numberOfMessageTypesToBeReceived.rest, numberOfMessageTypesToBeReceived.value) IN IF ~userConnectionOccurrence.ok THEN Fail ELSE
    Ok([ protocolVersion          |-> protocolVersion.value,
         userId                   |-> userId.value,
         passwordMd5Encryption    |-> passwordMd5Encryption.value,
         sessionId                |-> sessionId.value,
         timeHhmmss               |-> timeHhmmss.value,
         exchangeMessageId        |-> exchangeMessageId.value,
         inactivityInterval       |-> inactivityInterval.value,
         userConnectionOccurrence |-> userConnectionOccurrence.value ], userConnectionOccurrence.rest)

ZeroUserConnection ==
    [ protocolVersion          |-> [i \in 1 .. 2 |-> 0],
      userId                   |-> [i \in 1 .. 8 |-> 0],
      passwordMd5Encryption    |-> [i \in 1 .. 8 |-> 0],
      sessionId                |-> [i \in 1 .. 4 |-> 0],
      timeHhmmss               |-> [i \in 1 .. 6 |-> 0],
      exchangeMessageId        |-> [i \in 1 .. 6 |-> 0],
      inactivityInterval       |-> [i \in 1 .. 2 |-> 0],
      userConnectionOccurrence |-> << >> ]

(* User Connection at zero, then each field in turn at the values it is checked at *)
CheckedUserConnection ==
    { ZeroUserConnection }
        \cup { [ZeroUserConnection EXCEPT !.protocolVersion = one] : one \in Sample(2) }
        \cup { [ZeroUserConnection EXCEPT !.userId = one] : one \in Sample(8) }
        \cup { [ZeroUserConnection EXCEPT !.passwordMd5Encryption = one] : one \in Sample(8) }
        \cup { [ZeroUserConnection EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroUserConnection EXCEPT !.timeHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroUserConnection EXCEPT !.exchangeMessageId = one] : one \in Sample(6) }
        \cup { [ZeroUserConnection EXCEPT !.inactivityInterval = one] : one \in Sample(2) }
        \cup { [ZeroUserConnection EXCEPT !.userConnectionOccurrence = one] : one \in SampleLists(OneUserConnectionOccurrence) }

(***************************************************************************)
(* User Disconnection: 12 bytes                                            *)
(***************************************************************************)

UserDisconnection ==
    [ userId    : Sample(8),
      sessionId : Sample(4) ]

EncodeUserDisconnection(message) ==
    message.userId
        \o message.sessionId

DecodeUserDisconnection(bytes) ==
    LET userId == ReadBytes(bytes, 8) IN IF ~userId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(userId.rest, 4) IN IF ~sessionId.ok THEN Fail ELSE
    Ok([ userId    |-> userId.value,
         sessionId |-> sessionId.value ], sessionId.rest)

ZeroUserDisconnection ==
    [ userId    |-> [i \in 1 .. 8 |-> 0],
      sessionId |-> [i \in 1 .. 4 |-> 0] ]

(* User Disconnection at zero, then each field in turn at the values it is checked at *)
CheckedUserDisconnection ==
    { ZeroUserDisconnection }
        \cup { [ZeroUserDisconnection EXCEPT !.userId = one] : one \in Sample(8) }
        \cup { [ZeroUserDisconnection EXCEPT !.sessionId = one] : one \in Sample(4) }

(***************************************************************************)
(* Disconnection Instruction Occurrence: 10 bytes                          *)
(***************************************************************************)

DisconnectionInstructionOccurrence ==
    [ traderId                                                : Sample(8),
      disconnectionInstructionNoteCancelQuotesOnlyQQuotesOnly : Sample(1),
      activeYOnNOff                                           : Sample(1) ]

EncodeDisconnectionInstructionOccurrence(message) ==
    message.traderId
        \o message.disconnectionInstructionNoteCancelQuotesOnlyQQuotesOnly
        \o message.activeYOnNOff

DecodeDisconnectionInstructionOccurrence(bytes) ==
    LET traderId == ReadBytes(bytes, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET disconnectionInstructionNoteCancelQuotesOnlyQQuotesOnly == ReadBytes(traderId.rest, 1) IN IF ~disconnectionInstructionNoteCancelQuotesOnlyQQuotesOnly.ok THEN Fail ELSE
    LET activeYOnNOff == ReadBytes(disconnectionInstructionNoteCancelQuotesOnlyQQuotesOnly.rest, 1) IN IF ~activeYOnNOff.ok THEN Fail ELSE
    Ok([ traderId                                                |-> traderId.value,
         disconnectionInstructionNoteCancelQuotesOnlyQQuotesOnly |-> disconnectionInstructionNoteCancelQuotesOnlyQQuotesOnly.value,
         activeYOnNOff                                           |-> activeYOnNOff.value ], activeYOnNOff.rest)

ZeroDisconnectionInstructionOccurrence ==
    [ traderId                                                |-> [i \in 1 .. 8 |-> 0],
      disconnectionInstructionNoteCancelQuotesOnlyQQuotesOnly |-> [i \in 1 .. 1 |-> 0],
      activeYOnNOff                                           |-> [i \in 1 .. 1 |-> 0] ]

(* Disconnection Instruction Occurrence at zero, then each field in turn at the values it is checked at *)
CheckedDisconnectionInstructionOccurrence ==
    { ZeroDisconnectionInstructionOccurrence }
        \cup { [ZeroDisconnectionInstructionOccurrence EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroDisconnectionInstructionOccurrence EXCEPT !.disconnectionInstructionNoteCancelQuotesOnlyQQuotesOnly = one] : one \in Sample(1) }
        \cup { [ZeroDisconnectionInstructionOccurrence EXCEPT !.activeYOnNOff = one] : one \in Sample(1) }

(* A run of Disconnection Instruction Occurrence, written one after another *)
RECURSIVE EncodeDisconnectionInstructionOccurrenceList(_)
EncodeDisconnectionInstructionOccurrenceList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeDisconnectionInstructionOccurrence(Head(messages)) \o EncodeDisconnectionInstructionOccurrenceList(Tail(messages))

(* As many Disconnection Instruction Occurrence as the field that counts them says *)
RECURSIVE ReadDisconnectionInstructionOccurrenceList(_, _)
ReadDisconnectionInstructionOccurrenceList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeDisconnectionInstructionOccurrence(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadDisconnectionInstructionOccurrenceList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Disconnection Instruction Occurrence of each kind, for the lists that carry them *)
OneDisconnectionInstructionOccurrence == { ZeroDisconnectionInstructionOccurrence }

(***************************************************************************)
(* Disconnection Instruction                                               *)
(***************************************************************************)

DisconnectionInstruction ==
    [ disconnectionInstructionOccurrence : SampleLists(OneDisconnectionInstructionOccurrence) ]

EncodeDisconnectionInstruction(message) ==
    EncodeDigits(Len(message.disconnectionInstructionOccurrence), 2)
        \o EncodeDisconnectionInstructionOccurrenceList(message.disconnectionInstructionOccurrence)

DecodeDisconnectionInstruction(bytes) ==
    LET numberOfInstructionsPresentInTheMessage == ReadDigits(bytes, 2) IN IF ~numberOfInstructionsPresentInTheMessage.ok THEN Fail ELSE
    LET disconnectionInstructionOccurrence == ReadDisconnectionInstructionOccurrenceList(numberOfInstructionsPresentInTheMessage.rest, numberOfInstructionsPresentInTheMessage.value) IN IF ~disconnectionInstructionOccurrence.ok THEN Fail ELSE
    Ok([ disconnectionInstructionOccurrence |-> disconnectionInstructionOccurrence.value ], disconnectionInstructionOccurrence.rest)

ZeroDisconnectionInstruction ==
    [ disconnectionInstructionOccurrence |-> << >> ]

(* Disconnection Instruction at zero, then each field in turn at the values it is checked at *)
CheckedDisconnectionInstruction ==
    { ZeroDisconnectionInstruction }
        \cup { [ZeroDisconnectionInstruction EXCEPT !.disconnectionInstructionOccurrence = one] : one \in SampleLists(OneDisconnectionInstructionOccurrence) }

(***************************************************************************)
(* Heartbeat Response: 20 bytes                                            *)
(***************************************************************************)

HeartbeatResponse ==
    [ firstUserSequenceId                    : Sample(8),
      lastExchangeMessageIdSentToParticipant : Sample(6),
      timeLocal                              : Sample(6) ]

EncodeHeartbeatResponse(message) ==
    message.firstUserSequenceId
        \o message.lastExchangeMessageIdSentToParticipant
        \o message.timeLocal

DecodeHeartbeatResponse(bytes) ==
    LET firstUserSequenceId == ReadBytes(bytes, 8) IN IF ~firstUserSequenceId.ok THEN Fail ELSE
    LET lastExchangeMessageIdSentToParticipant == ReadBytes(firstUserSequenceId.rest, 6) IN IF ~lastExchangeMessageIdSentToParticipant.ok THEN Fail ELSE
    LET timeLocal == ReadBytes(lastExchangeMessageIdSentToParticipant.rest, 6) IN IF ~timeLocal.ok THEN Fail ELSE
    Ok([ firstUserSequenceId                    |-> firstUserSequenceId.value,
         lastExchangeMessageIdSentToParticipant |-> lastExchangeMessageIdSentToParticipant.value,
         timeLocal                              |-> timeLocal.value ], timeLocal.rest)

ZeroHeartbeatResponse ==
    [ firstUserSequenceId                    |-> [i \in 1 .. 8 |-> 0],
      lastExchangeMessageIdSentToParticipant |-> [i \in 1 .. 6 |-> 0],
      timeLocal                              |-> [i \in 1 .. 6 |-> 0] ]

(* Heartbeat Response at zero, then each field in turn at the values it is checked at *)
CheckedHeartbeatResponse ==
    { ZeroHeartbeatResponse }
        \cup { [ZeroHeartbeatResponse EXCEPT !.firstUserSequenceId = one] : one \in Sample(8) }
        \cup { [ZeroHeartbeatResponse EXCEPT !.lastExchangeMessageIdSentToParticipant = one] : one \in Sample(6) }
        \cup { [ZeroHeartbeatResponse EXCEPT !.timeLocal = one] : one \in Sample(6) }

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
(* Bulk Quote Data: 203 bytes                                              *)
(***************************************************************************)

BulkQuoteData ==
    [ group                   : Sample(2),
      clearingData            : ClearingData,
      ownerData               : OwnerData,
      reserved2               : Sample(2),
      reserved8               : Sample(8),
      secondReserved2         : Sample(2),
      calculationTimeInterval : Sample(8),
      maximumTotalVolume      : Sample(8),
      maximumTotalValue       : Sample(8),
      maximumDeltaVolume      : Sample(8),
      maximumDeltaValue       : Sample(8),
      percentOfQuote          : Sample(8),
      postTradingInstructions : Sample(50) ]

EncodeBulkQuoteData(message) ==
    message.group
        \o EncodeClearingData(message.clearingData)
        \o EncodeOwnerData(message.ownerData)
        \o message.reserved2
        \o message.reserved8
        \o message.secondReserved2
        \o message.calculationTimeInterval
        \o message.maximumTotalVolume
        \o message.maximumTotalValue
        \o message.maximumDeltaVolume
        \o message.maximumDeltaValue
        \o message.percentOfQuote
        \o message.postTradingInstructions

DecodeBulkQuoteData(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET clearingData == DecodeClearingData(group.rest) IN IF ~clearingData.ok THEN Fail ELSE
    LET ownerData == DecodeOwnerData(clearingData.rest) IN IF ~ownerData.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(ownerData.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(reserved2.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    LET secondReserved2 == ReadBytes(reserved8.rest, 2) IN IF ~secondReserved2.ok THEN Fail ELSE
    LET calculationTimeInterval == ReadBytes(secondReserved2.rest, 8) IN IF ~calculationTimeInterval.ok THEN Fail ELSE
    LET maximumTotalVolume == ReadBytes(calculationTimeInterval.rest, 8) IN IF ~maximumTotalVolume.ok THEN Fail ELSE
    LET maximumTotalValue == ReadBytes(maximumTotalVolume.rest, 8) IN IF ~maximumTotalValue.ok THEN Fail ELSE
    LET maximumDeltaVolume == ReadBytes(maximumTotalValue.rest, 8) IN IF ~maximumDeltaVolume.ok THEN Fail ELSE
    LET maximumDeltaValue == ReadBytes(maximumDeltaVolume.rest, 8) IN IF ~maximumDeltaValue.ok THEN Fail ELSE
    LET percentOfQuote == ReadBytes(maximumDeltaValue.rest, 8) IN IF ~percentOfQuote.ok THEN Fail ELSE
    LET postTradingInstructions == ReadBytes(percentOfQuote.rest, 50) IN IF ~postTradingInstructions.ok THEN Fail ELSE
    Ok([ group                   |-> group.value,
         clearingData            |-> clearingData.value,
         ownerData               |-> ownerData.value,
         reserved2               |-> reserved2.value,
         reserved8               |-> reserved8.value,
         secondReserved2         |-> secondReserved2.value,
         calculationTimeInterval |-> calculationTimeInterval.value,
         maximumTotalVolume      |-> maximumTotalVolume.value,
         maximumTotalValue       |-> maximumTotalValue.value,
         maximumDeltaVolume      |-> maximumDeltaVolume.value,
         maximumDeltaValue       |-> maximumDeltaValue.value,
         percentOfQuote          |-> percentOfQuote.value,
         postTradingInstructions |-> postTradingInstructions.value ], postTradingInstructions.rest)

ZeroBulkQuoteData ==
    [ group                   |-> [i \in 1 .. 2 |-> 0],
      clearingData            |-> ZeroClearingData,
      ownerData               |-> ZeroOwnerData,
      reserved2               |-> [i \in 1 .. 2 |-> 0],
      reserved8               |-> [i \in 1 .. 8 |-> 0],
      secondReserved2         |-> [i \in 1 .. 2 |-> 0],
      calculationTimeInterval |-> [i \in 1 .. 8 |-> 0],
      maximumTotalVolume      |-> [i \in 1 .. 8 |-> 0],
      maximumTotalValue       |-> [i \in 1 .. 8 |-> 0],
      maximumDeltaVolume      |-> [i \in 1 .. 8 |-> 0],
      maximumDeltaValue       |-> [i \in 1 .. 8 |-> 0],
      percentOfQuote          |-> [i \in 1 .. 8 |-> 0],
      postTradingInstructions |-> [i \in 1 .. 50 |-> 0] ]

(* Bulk Quote Data at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuoteData ==
    { ZeroBulkQuoteData }
        \cup { [ZeroBulkQuoteData EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuoteData EXCEPT !.clearingData = one] : one \in CheckedClearingData }
        \cup { [ZeroBulkQuoteData EXCEPT !.ownerData = one] : one \in CheckedOwnerData }
        \cup { [ZeroBulkQuoteData EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuoteData EXCEPT !.reserved8 = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuoteData EXCEPT !.secondReserved2 = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuoteData EXCEPT !.calculationTimeInterval = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuoteData EXCEPT !.maximumTotalVolume = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuoteData EXCEPT !.maximumTotalValue = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuoteData EXCEPT !.maximumDeltaVolume = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuoteData EXCEPT !.maximumDeltaValue = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuoteData EXCEPT !.percentOfQuote = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuoteData EXCEPT !.postTradingInstructions = one] : one \in Sample(50) }

(***************************************************************************)
(* Global Cancellation: 11 bytes                                           *)
(***************************************************************************)

GlobalCancellation ==
    [ group              : Sample(2),
      typeOfCancellation : Sample(1),
      mmCatUserTime      : Sample(8) ]

EncodeGlobalCancellation(message) ==
    message.group
        \o message.typeOfCancellation
        \o message.mmCatUserTime

DecodeGlobalCancellation(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET typeOfCancellation == ReadBytes(group.rest, 1) IN IF ~typeOfCancellation.ok THEN Fail ELSE
    LET mmCatUserTime == ReadBytes(typeOfCancellation.rest, 8) IN IF ~mmCatUserTime.ok THEN Fail ELSE
    Ok([ group              |-> group.value,
         typeOfCancellation |-> typeOfCancellation.value,
         mmCatUserTime      |-> mmCatUserTime.value ], mmCatUserTime.rest)

ZeroGlobalCancellation ==
    [ group              |-> [i \in 1 .. 2 |-> 0],
      typeOfCancellation |-> [i \in 1 .. 1 |-> 0],
      mmCatUserTime      |-> [i \in 1 .. 8 |-> 0] ]

(* Global Cancellation at zero, then each field in turn at the values it is checked at *)
CheckedGlobalCancellation ==
    { ZeroGlobalCancellation }
        \cup { [ZeroGlobalCancellation EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroGlobalCancellation EXCEPT !.typeOfCancellation = one] : one \in Sample(1) }
        \cup { [ZeroGlobalCancellation EXCEPT !.mmCatUserTime = one] : one \in Sample(8) }

(***************************************************************************)
(* User Global Cancellation: 23 bytes                                      *)
(***************************************************************************)

UserGlobalCancellation ==
    [ group              : Sample(2),
      instrumentOptional : Sample(4),
      typeOfCancellation : Sample(1),
      accountTypeFilter  : Sample(8),
      mmCatUserTime      : Sample(8) ]

EncodeUserGlobalCancellation(message) ==
    message.group
        \o message.instrumentOptional
        \o message.typeOfCancellation
        \o message.accountTypeFilter
        \o message.mmCatUserTime

DecodeUserGlobalCancellation(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrumentOptional == ReadBytes(group.rest, 4) IN IF ~instrumentOptional.ok THEN Fail ELSE
    LET typeOfCancellation == ReadBytes(instrumentOptional.rest, 1) IN IF ~typeOfCancellation.ok THEN Fail ELSE
    LET accountTypeFilter == ReadBytes(typeOfCancellation.rest, 8) IN IF ~accountTypeFilter.ok THEN Fail ELSE
    LET mmCatUserTime == ReadBytes(accountTypeFilter.rest, 8) IN IF ~mmCatUserTime.ok THEN Fail ELSE
    Ok([ group              |-> group.value,
         instrumentOptional |-> instrumentOptional.value,
         typeOfCancellation |-> typeOfCancellation.value,
         accountTypeFilter  |-> accountTypeFilter.value,
         mmCatUserTime      |-> mmCatUserTime.value ], mmCatUserTime.rest)

ZeroUserGlobalCancellation ==
    [ group              |-> [i \in 1 .. 2 |-> 0],
      instrumentOptional |-> [i \in 1 .. 4 |-> 0],
      typeOfCancellation |-> [i \in 1 .. 1 |-> 0],
      accountTypeFilter  |-> [i \in 1 .. 8 |-> 0],
      mmCatUserTime      |-> [i \in 1 .. 8 |-> 0] ]

(* User Global Cancellation at zero, then each field in turn at the values it is checked at *)
CheckedUserGlobalCancellation ==
    { ZeroUserGlobalCancellation }
        \cup { [ZeroUserGlobalCancellation EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroUserGlobalCancellation EXCEPT !.instrumentOptional = one] : one \in Sample(4) }
        \cup { [ZeroUserGlobalCancellation EXCEPT !.typeOfCancellation = one] : one \in Sample(1) }
        \cup { [ZeroUserGlobalCancellation EXCEPT !.accountTypeFilter = one] : one \in Sample(8) }
        \cup { [ZeroUserGlobalCancellation EXCEPT !.mmCatUserTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Directed Routed Order Rejection And Quote: 44 bytes                     *)
(***************************************************************************)

DirectedRoutedOrderRejectionAndQuote ==
    [ group              : Sample(2),
      instrumentOptional : Sample(4),
      traderId           : Sample(8),
      orderId            : Sample(8),
      rejectionCode      : Sample(4),
      quoteQuantity      : Sample(8),
      quotePrice         : Sample(10) ]

EncodeDirectedRoutedOrderRejectionAndQuote(message) ==
    message.group
        \o message.instrumentOptional
        \o message.traderId
        \o message.orderId
        \o message.rejectionCode
        \o message.quoteQuantity
        \o message.quotePrice

DecodeDirectedRoutedOrderRejectionAndQuote(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrumentOptional == ReadBytes(group.rest, 4) IN IF ~instrumentOptional.ok THEN Fail ELSE
    LET traderId == ReadBytes(instrumentOptional.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET orderId == ReadBytes(traderId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET rejectionCode == ReadBytes(orderId.rest, 4) IN IF ~rejectionCode.ok THEN Fail ELSE
    LET quoteQuantity == ReadBytes(rejectionCode.rest, 8) IN IF ~quoteQuantity.ok THEN Fail ELSE
    LET quotePrice == ReadBytes(quoteQuantity.rest, 10) IN IF ~quotePrice.ok THEN Fail ELSE
    Ok([ group              |-> group.value,
         instrumentOptional |-> instrumentOptional.value,
         traderId           |-> traderId.value,
         orderId            |-> orderId.value,
         rejectionCode      |-> rejectionCode.value,
         quoteQuantity      |-> quoteQuantity.value,
         quotePrice         |-> quotePrice.value ], quotePrice.rest)

ZeroDirectedRoutedOrderRejectionAndQuote ==
    [ group              |-> [i \in 1 .. 2 |-> 0],
      instrumentOptional |-> [i \in 1 .. 4 |-> 0],
      traderId           |-> [i \in 1 .. 8 |-> 0],
      orderId            |-> [i \in 1 .. 8 |-> 0],
      rejectionCode      |-> [i \in 1 .. 4 |-> 0],
      quoteQuantity      |-> [i \in 1 .. 8 |-> 0],
      quotePrice         |-> [i \in 1 .. 10 |-> 0] ]

(* Directed Routed Order Rejection And Quote at zero, then each field in turn at the values it is checked at *)
CheckedDirectedRoutedOrderRejectionAndQuote ==
    { ZeroDirectedRoutedOrderRejectionAndQuote }
        \cup { [ZeroDirectedRoutedOrderRejectionAndQuote EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroDirectedRoutedOrderRejectionAndQuote EXCEPT !.instrumentOptional = one] : one \in Sample(4) }
        \cup { [ZeroDirectedRoutedOrderRejectionAndQuote EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroDirectedRoutedOrderRejectionAndQuote EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroDirectedRoutedOrderRejectionAndQuote EXCEPT !.rejectionCode = one] : one \in Sample(4) }
        \cup { [ZeroDirectedRoutedOrderRejectionAndQuote EXCEPT !.quoteQuantity = one] : one \in Sample(8) }
        \cup { [ZeroDirectedRoutedOrderRejectionAndQuote EXCEPT !.quotePrice = one] : one \in Sample(10) }

(***************************************************************************)
(* Buying Clearing Data: 20 bytes                                          *)
(***************************************************************************)

BuyingClearingData ==
    [ clearingInstruction   : Sample(12),
      accountType           : Sample(1),
      openClose             : Sample(1),
      hedgeSpec             : Sample(1),
      clearingOperationMode : Sample(1),
      clearingDestination   : Sample(4) ]

EncodeBuyingClearingData(message) ==
    message.clearingInstruction
        \o message.accountType
        \o message.openClose
        \o message.hedgeSpec
        \o message.clearingOperationMode
        \o message.clearingDestination

DecodeBuyingClearingData(bytes) ==
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

ZeroBuyingClearingData ==
    [ clearingInstruction   |-> [i \in 1 .. 12 |-> 0],
      accountType           |-> [i \in 1 .. 1 |-> 0],
      openClose             |-> [i \in 1 .. 1 |-> 0],
      hedgeSpec             |-> [i \in 1 .. 1 |-> 0],
      clearingOperationMode |-> [i \in 1 .. 1 |-> 0],
      clearingDestination   |-> [i \in 1 .. 4 |-> 0] ]

(* Buying Clearing Data at zero, then each field in turn at the values it is checked at *)
CheckedBuyingClearingData ==
    { ZeroBuyingClearingData }
        \cup { [ZeroBuyingClearingData EXCEPT !.clearingInstruction = one] : one \in Sample(12) }
        \cup { [ZeroBuyingClearingData EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroBuyingClearingData EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroBuyingClearingData EXCEPT !.hedgeSpec = one] : one \in Sample(1) }
        \cup { [ZeroBuyingClearingData EXCEPT !.clearingOperationMode = one] : one \in Sample(1) }
        \cup { [ZeroBuyingClearingData EXCEPT !.clearingDestination = one] : one \in Sample(4) }

(***************************************************************************)
(* Selling Clearing Data: 20 bytes                                         *)
(***************************************************************************)

SellingClearingData ==
    [ clearingInstruction   : Sample(12),
      accountType           : Sample(1),
      openClose             : Sample(1),
      hedgeSpec             : Sample(1),
      clearingOperationMode : Sample(1),
      clearingDestination   : Sample(4) ]

EncodeSellingClearingData(message) ==
    message.clearingInstruction
        \o message.accountType
        \o message.openClose
        \o message.hedgeSpec
        \o message.clearingOperationMode
        \o message.clearingDestination

DecodeSellingClearingData(bytes) ==
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

ZeroSellingClearingData ==
    [ clearingInstruction   |-> [i \in 1 .. 12 |-> 0],
      accountType           |-> [i \in 1 .. 1 |-> 0],
      openClose             |-> [i \in 1 .. 1 |-> 0],
      hedgeSpec             |-> [i \in 1 .. 1 |-> 0],
      clearingOperationMode |-> [i \in 1 .. 1 |-> 0],
      clearingDestination   |-> [i \in 1 .. 4 |-> 0] ]

(* Selling Clearing Data at zero, then each field in turn at the values it is checked at *)
CheckedSellingClearingData ==
    { ZeroSellingClearingData }
        \cup { [ZeroSellingClearingData EXCEPT !.clearingInstruction = one] : one \in Sample(12) }
        \cup { [ZeroSellingClearingData EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroSellingClearingData EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroSellingClearingData EXCEPT !.hedgeSpec = one] : one \in Sample(1) }
        \cup { [ZeroSellingClearingData EXCEPT !.clearingOperationMode = one] : one \in Sample(1) }
        \cup { [ZeroSellingClearingData EXCEPT !.clearingDestination = one] : one \in Sample(4) }

(***************************************************************************)
(* Buying Owner Data: 71 bytes                                             *)
(***************************************************************************)

BuyingOwnerData ==
    [ clientOrderId : Sample(20),
      poundSign     : Sample(1),
      memo          : Sample(50) ]

EncodeBuyingOwnerData(message) ==
    message.clientOrderId
        \o message.poundSign
        \o message.memo

DecodeBuyingOwnerData(bytes) ==
    LET clientOrderId == ReadBytes(bytes, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET poundSign == ReadBytes(clientOrderId.rest, 1) IN IF ~poundSign.ok THEN Fail ELSE
    LET memo == ReadBytes(poundSign.rest, 50) IN IF ~memo.ok THEN Fail ELSE
    Ok([ clientOrderId |-> clientOrderId.value,
         poundSign     |-> poundSign.value,
         memo          |-> memo.value ], memo.rest)

ZeroBuyingOwnerData ==
    [ clientOrderId |-> [i \in 1 .. 20 |-> 0],
      poundSign     |-> [i \in 1 .. 1 |-> 0],
      memo          |-> [i \in 1 .. 50 |-> 0] ]

(* Buying Owner Data at zero, then each field in turn at the values it is checked at *)
CheckedBuyingOwnerData ==
    { ZeroBuyingOwnerData }
        \cup { [ZeroBuyingOwnerData EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroBuyingOwnerData EXCEPT !.poundSign = one] : one \in Sample(1) }
        \cup { [ZeroBuyingOwnerData EXCEPT !.memo = one] : one \in Sample(50) }

(***************************************************************************)
(* Selling Owner Data: 71 bytes                                            *)
(***************************************************************************)

SellingOwnerData ==
    [ clientOrderId : Sample(20),
      poundSign     : Sample(1),
      memo          : Sample(50) ]

EncodeSellingOwnerData(message) ==
    message.clientOrderId
        \o message.poundSign
        \o message.memo

DecodeSellingOwnerData(bytes) ==
    LET clientOrderId == ReadBytes(bytes, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET poundSign == ReadBytes(clientOrderId.rest, 1) IN IF ~poundSign.ok THEN Fail ELSE
    LET memo == ReadBytes(poundSign.rest, 50) IN IF ~memo.ok THEN Fail ELSE
    Ok([ clientOrderId |-> clientOrderId.value,
         poundSign     |-> poundSign.value,
         memo          |-> memo.value ], memo.rest)

ZeroSellingOwnerData ==
    [ clientOrderId |-> [i \in 1 .. 20 |-> 0],
      poundSign     |-> [i \in 1 .. 1 |-> 0],
      memo          |-> [i \in 1 .. 50 |-> 0] ]

(* Selling Owner Data at zero, then each field in turn at the values it is checked at *)
CheckedSellingOwnerData ==
    { ZeroSellingOwnerData }
        \cup { [ZeroSellingOwnerData EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroSellingOwnerData EXCEPT !.poundSign = one] : one \in Sample(1) }
        \cup { [ZeroSellingOwnerData EXCEPT !.memo = one] : one \in Sample(50) }

(***************************************************************************)
(* Auction Entry: 364 bytes                                                *)
(***************************************************************************)

AuctionEntry ==
    [ group                         : Sample(2),
      instrumentOptional            : Sample(4),
      verbSide                      : Sample(1),
      quantity                      : Sample(8),
      price                         : Sample(10),
      buyingClearingData            : BuyingClearingData,
      sellingClearingData           : SellingClearingData,
      buyingOwnerData               : BuyingOwnerData,
      sellingOwnerData              : SellingOwnerData,
      imlHandling                   : Sample(1),
      specialPriceTerm              : Sample(1),
      additionalPrice               : Sample(10),
      quantityTerm                  : Sample(1),
      additionalQuantity            : Sample(8),
      buyingPostTradingInstruction  : Sample(50),
      sellingPostTradingInstruction : Sample(50),
      buyingAdditionalClientMemo    : Sample(16),
      sellingAdditionalClientMemo   : Sample(16),
      reserved4                     : Sample(4) ]

EncodeAuctionEntry(message) ==
    message.group
        \o message.instrumentOptional
        \o message.verbSide
        \o message.quantity
        \o message.price
        \o EncodeBuyingClearingData(message.buyingClearingData)
        \o EncodeSellingClearingData(message.sellingClearingData)
        \o EncodeBuyingOwnerData(message.buyingOwnerData)
        \o EncodeSellingOwnerData(message.sellingOwnerData)
        \o message.imlHandling
        \o message.specialPriceTerm
        \o message.additionalPrice
        \o message.quantityTerm
        \o message.additionalQuantity
        \o message.buyingPostTradingInstruction
        \o message.sellingPostTradingInstruction
        \o message.buyingAdditionalClientMemo
        \o message.sellingAdditionalClientMemo
        \o message.reserved4

DecodeAuctionEntry(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrumentOptional == ReadBytes(group.rest, 4) IN IF ~instrumentOptional.ok THEN Fail ELSE
    LET verbSide == ReadBytes(instrumentOptional.rest, 1) IN IF ~verbSide.ok THEN Fail ELSE
    LET quantity == ReadBytes(verbSide.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 10) IN IF ~price.ok THEN Fail ELSE
    LET buyingClearingData == DecodeBuyingClearingData(price.rest) IN IF ~buyingClearingData.ok THEN Fail ELSE
    LET sellingClearingData == DecodeSellingClearingData(buyingClearingData.rest) IN IF ~sellingClearingData.ok THEN Fail ELSE
    LET buyingOwnerData == DecodeBuyingOwnerData(sellingClearingData.rest) IN IF ~buyingOwnerData.ok THEN Fail ELSE
    LET sellingOwnerData == DecodeSellingOwnerData(buyingOwnerData.rest) IN IF ~sellingOwnerData.ok THEN Fail ELSE
    LET imlHandling == ReadBytes(sellingOwnerData.rest, 1) IN IF ~imlHandling.ok THEN Fail ELSE
    LET specialPriceTerm == ReadBytes(imlHandling.rest, 1) IN IF ~specialPriceTerm.ok THEN Fail ELSE
    LET additionalPrice == ReadBytes(specialPriceTerm.rest, 10) IN IF ~additionalPrice.ok THEN Fail ELSE
    LET quantityTerm == ReadBytes(additionalPrice.rest, 1) IN IF ~quantityTerm.ok THEN Fail ELSE
    LET additionalQuantity == ReadBytes(quantityTerm.rest, 8) IN IF ~additionalQuantity.ok THEN Fail ELSE
    LET buyingPostTradingInstruction == ReadBytes(additionalQuantity.rest, 50) IN IF ~buyingPostTradingInstruction.ok THEN Fail ELSE
    LET sellingPostTradingInstruction == ReadBytes(buyingPostTradingInstruction.rest, 50) IN IF ~sellingPostTradingInstruction.ok THEN Fail ELSE
    LET buyingAdditionalClientMemo == ReadBytes(sellingPostTradingInstruction.rest, 16) IN IF ~buyingAdditionalClientMemo.ok THEN Fail ELSE
    LET sellingAdditionalClientMemo == ReadBytes(buyingAdditionalClientMemo.rest, 16) IN IF ~sellingAdditionalClientMemo.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(sellingAdditionalClientMemo.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    Ok([ group                         |-> group.value,
         instrumentOptional            |-> instrumentOptional.value,
         verbSide                      |-> verbSide.value,
         quantity                      |-> quantity.value,
         price                         |-> price.value,
         buyingClearingData            |-> buyingClearingData.value,
         sellingClearingData           |-> sellingClearingData.value,
         buyingOwnerData               |-> buyingOwnerData.value,
         sellingOwnerData              |-> sellingOwnerData.value,
         imlHandling                   |-> imlHandling.value,
         specialPriceTerm              |-> specialPriceTerm.value,
         additionalPrice               |-> additionalPrice.value,
         quantityTerm                  |-> quantityTerm.value,
         additionalQuantity            |-> additionalQuantity.value,
         buyingPostTradingInstruction  |-> buyingPostTradingInstruction.value,
         sellingPostTradingInstruction |-> sellingPostTradingInstruction.value,
         buyingAdditionalClientMemo    |-> buyingAdditionalClientMemo.value,
         sellingAdditionalClientMemo   |-> sellingAdditionalClientMemo.value,
         reserved4                     |-> reserved4.value ], reserved4.rest)

ZeroAuctionEntry ==
    [ group                         |-> [i \in 1 .. 2 |-> 0],
      instrumentOptional            |-> [i \in 1 .. 4 |-> 0],
      verbSide                      |-> [i \in 1 .. 1 |-> 0],
      quantity                      |-> [i \in 1 .. 8 |-> 0],
      price                         |-> [i \in 1 .. 10 |-> 0],
      buyingClearingData            |-> ZeroBuyingClearingData,
      sellingClearingData           |-> ZeroSellingClearingData,
      buyingOwnerData               |-> ZeroBuyingOwnerData,
      sellingOwnerData              |-> ZeroSellingOwnerData,
      imlHandling                   |-> [i \in 1 .. 1 |-> 0],
      specialPriceTerm              |-> [i \in 1 .. 1 |-> 0],
      additionalPrice               |-> [i \in 1 .. 10 |-> 0],
      quantityTerm                  |-> [i \in 1 .. 1 |-> 0],
      additionalQuantity            |-> [i \in 1 .. 8 |-> 0],
      buyingPostTradingInstruction  |-> [i \in 1 .. 50 |-> 0],
      sellingPostTradingInstruction |-> [i \in 1 .. 50 |-> 0],
      buyingAdditionalClientMemo    |-> [i \in 1 .. 16 |-> 0],
      sellingAdditionalClientMemo   |-> [i \in 1 .. 16 |-> 0],
      reserved4                     |-> [i \in 1 .. 4 |-> 0] ]

(* Auction Entry at zero, then each field in turn at the values it is checked at *)
CheckedAuctionEntry ==
    { ZeroAuctionEntry }
        \cup { [ZeroAuctionEntry EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroAuctionEntry EXCEPT !.instrumentOptional = one] : one \in Sample(4) }
        \cup { [ZeroAuctionEntry EXCEPT !.verbSide = one] : one \in Sample(1) }
        \cup { [ZeroAuctionEntry EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroAuctionEntry EXCEPT !.price = one] : one \in Sample(10) }
        \cup { [ZeroAuctionEntry EXCEPT !.buyingClearingData = one] : one \in CheckedBuyingClearingData }
        \cup { [ZeroAuctionEntry EXCEPT !.sellingClearingData = one] : one \in CheckedSellingClearingData }
        \cup { [ZeroAuctionEntry EXCEPT !.buyingOwnerData = one] : one \in CheckedBuyingOwnerData }
        \cup { [ZeroAuctionEntry EXCEPT !.sellingOwnerData = one] : one \in CheckedSellingOwnerData }
        \cup { [ZeroAuctionEntry EXCEPT !.imlHandling = one] : one \in Sample(1) }
        \cup { [ZeroAuctionEntry EXCEPT !.specialPriceTerm = one] : one \in Sample(1) }
        \cup { [ZeroAuctionEntry EXCEPT !.additionalPrice = one] : one \in Sample(10) }
        \cup { [ZeroAuctionEntry EXCEPT !.quantityTerm = one] : one \in Sample(1) }
        \cup { [ZeroAuctionEntry EXCEPT !.additionalQuantity = one] : one \in Sample(8) }
        \cup { [ZeroAuctionEntry EXCEPT !.buyingPostTradingInstruction = one] : one \in Sample(50) }
        \cup { [ZeroAuctionEntry EXCEPT !.sellingPostTradingInstruction = one] : one \in Sample(50) }
        \cup { [ZeroAuctionEntry EXCEPT !.buyingAdditionalClientMemo = one] : one \in Sample(16) }
        \cup { [ZeroAuctionEntry EXCEPT !.sellingAdditionalClientMemo = one] : one \in Sample(16) }
        \cup { [ZeroAuctionEntry EXCEPT !.reserved4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Clearing Data Dealer: 20 bytes                                          *)
(***************************************************************************)

ClearingDataDealer ==
    [ clearingInstruction   : Sample(12),
      accountType           : Sample(1),
      openClose             : Sample(1),
      hedgeSpec             : Sample(1),
      clearingOperationMode : Sample(1),
      clearingDestination   : Sample(4) ]

EncodeClearingDataDealer(message) ==
    message.clearingInstruction
        \o message.accountType
        \o message.openClose
        \o message.hedgeSpec
        \o message.clearingOperationMode
        \o message.clearingDestination

DecodeClearingDataDealer(bytes) ==
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

ZeroClearingDataDealer ==
    [ clearingInstruction   |-> [i \in 1 .. 12 |-> 0],
      accountType           |-> [i \in 1 .. 1 |-> 0],
      openClose             |-> [i \in 1 .. 1 |-> 0],
      hedgeSpec             |-> [i \in 1 .. 1 |-> 0],
      clearingOperationMode |-> [i \in 1 .. 1 |-> 0],
      clearingDestination   |-> [i \in 1 .. 4 |-> 0] ]

(* Clearing Data Dealer at zero, then each field in turn at the values it is checked at *)
CheckedClearingDataDealer ==
    { ZeroClearingDataDealer }
        \cup { [ZeroClearingDataDealer EXCEPT !.clearingInstruction = one] : one \in Sample(12) }
        \cup { [ZeroClearingDataDealer EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroClearingDataDealer EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroClearingDataDealer EXCEPT !.hedgeSpec = one] : one \in Sample(1) }
        \cup { [ZeroClearingDataDealer EXCEPT !.clearingOperationMode = one] : one \in Sample(1) }
        \cup { [ZeroClearingDataDealer EXCEPT !.clearingDestination = one] : one \in Sample(4) }

(***************************************************************************)
(* Owner Data Dealer: 71 bytes                                             *)
(***************************************************************************)

OwnerDataDealer ==
    [ clientOrderId : Sample(20),
      poundSign     : Sample(1),
      memo          : Sample(50) ]

EncodeOwnerDataDealer(message) ==
    message.clientOrderId
        \o message.poundSign
        \o message.memo

DecodeOwnerDataDealer(bytes) ==
    LET clientOrderId == ReadBytes(bytes, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET poundSign == ReadBytes(clientOrderId.rest, 1) IN IF ~poundSign.ok THEN Fail ELSE
    LET memo == ReadBytes(poundSign.rest, 50) IN IF ~memo.ok THEN Fail ELSE
    Ok([ clientOrderId |-> clientOrderId.value,
         poundSign     |-> poundSign.value,
         memo          |-> memo.value ], memo.rest)

ZeroOwnerDataDealer ==
    [ clientOrderId |-> [i \in 1 .. 20 |-> 0],
      poundSign     |-> [i \in 1 .. 1 |-> 0],
      memo          |-> [i \in 1 .. 50 |-> 0] ]

(* Owner Data Dealer at zero, then each field in turn at the values it is checked at *)
CheckedOwnerDataDealer ==
    { ZeroOwnerDataDealer }
        \cup { [ZeroOwnerDataDealer EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroOwnerDataDealer EXCEPT !.poundSign = one] : one \in Sample(1) }
        \cup { [ZeroOwnerDataDealer EXCEPT !.memo = one] : one \in Sample(50) }

(***************************************************************************)
(* Directed Order Acceptation: 200 bytes                                   *)
(***************************************************************************)

DirectedOrderAcceptation ==
    [ group                  : Sample(2),
      instrumentOptional     : Sample(4),
      referencedOrderId      : Sample(8),
      auctionStartingPrice   : Sample(10),
      clearingDataDealer     : ClearingDataDealer,
      ownerDataDealer        : OwnerDataDealer,
      additionalPrice        : Sample(10),
      quantityTerm           : Sample(1),
      postTradingInstruction : Sample(50),
      additionalQuantity     : Sample(8),
      additionalClientMemo   : Sample(16) ]

EncodeDirectedOrderAcceptation(message) ==
    message.group
        \o message.instrumentOptional
        \o message.referencedOrderId
        \o message.auctionStartingPrice
        \o EncodeClearingDataDealer(message.clearingDataDealer)
        \o EncodeOwnerDataDealer(message.ownerDataDealer)
        \o message.additionalPrice
        \o message.quantityTerm
        \o message.postTradingInstruction
        \o message.additionalQuantity
        \o message.additionalClientMemo

DecodeDirectedOrderAcceptation(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrumentOptional == ReadBytes(group.rest, 4) IN IF ~instrumentOptional.ok THEN Fail ELSE
    LET referencedOrderId == ReadBytes(instrumentOptional.rest, 8) IN IF ~referencedOrderId.ok THEN Fail ELSE
    LET auctionStartingPrice == ReadBytes(referencedOrderId.rest, 10) IN IF ~auctionStartingPrice.ok THEN Fail ELSE
    LET clearingDataDealer == DecodeClearingDataDealer(auctionStartingPrice.rest) IN IF ~clearingDataDealer.ok THEN Fail ELSE
    LET ownerDataDealer == DecodeOwnerDataDealer(clearingDataDealer.rest) IN IF ~ownerDataDealer.ok THEN Fail ELSE
    LET additionalPrice == ReadBytes(ownerDataDealer.rest, 10) IN IF ~additionalPrice.ok THEN Fail ELSE
    LET quantityTerm == ReadBytes(additionalPrice.rest, 1) IN IF ~quantityTerm.ok THEN Fail ELSE
    LET postTradingInstruction == ReadBytes(quantityTerm.rest, 50) IN IF ~postTradingInstruction.ok THEN Fail ELSE
    LET additionalQuantity == ReadBytes(postTradingInstruction.rest, 8) IN IF ~additionalQuantity.ok THEN Fail ELSE
    LET additionalClientMemo == ReadBytes(additionalQuantity.rest, 16) IN IF ~additionalClientMemo.ok THEN Fail ELSE
    Ok([ group                  |-> group.value,
         instrumentOptional     |-> instrumentOptional.value,
         referencedOrderId      |-> referencedOrderId.value,
         auctionStartingPrice   |-> auctionStartingPrice.value,
         clearingDataDealer     |-> clearingDataDealer.value,
         ownerDataDealer        |-> ownerDataDealer.value,
         additionalPrice        |-> additionalPrice.value,
         quantityTerm           |-> quantityTerm.value,
         postTradingInstruction |-> postTradingInstruction.value,
         additionalQuantity     |-> additionalQuantity.value,
         additionalClientMemo   |-> additionalClientMemo.value ], additionalClientMemo.rest)

ZeroDirectedOrderAcceptation ==
    [ group                  |-> [i \in 1 .. 2 |-> 0],
      instrumentOptional     |-> [i \in 1 .. 4 |-> 0],
      referencedOrderId      |-> [i \in 1 .. 8 |-> 0],
      auctionStartingPrice   |-> [i \in 1 .. 10 |-> 0],
      clearingDataDealer     |-> ZeroClearingDataDealer,
      ownerDataDealer        |-> ZeroOwnerDataDealer,
      additionalPrice        |-> [i \in 1 .. 10 |-> 0],
      quantityTerm           |-> [i \in 1 .. 1 |-> 0],
      postTradingInstruction |-> [i \in 1 .. 50 |-> 0],
      additionalQuantity     |-> [i \in 1 .. 8 |-> 0],
      additionalClientMemo   |-> [i \in 1 .. 16 |-> 0] ]

(* Directed Order Acceptation at zero, then each field in turn at the values it is checked at *)
CheckedDirectedOrderAcceptation ==
    { ZeroDirectedOrderAcceptation }
        \cup { [ZeroDirectedOrderAcceptation EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroDirectedOrderAcceptation EXCEPT !.instrumentOptional = one] : one \in Sample(4) }
        \cup { [ZeroDirectedOrderAcceptation EXCEPT !.referencedOrderId = one] : one \in Sample(8) }
        \cup { [ZeroDirectedOrderAcceptation EXCEPT !.auctionStartingPrice = one] : one \in Sample(10) }
        \cup { [ZeroDirectedOrderAcceptation EXCEPT !.clearingDataDealer = one] : one \in CheckedClearingDataDealer }
        \cup { [ZeroDirectedOrderAcceptation EXCEPT !.ownerDataDealer = one] : one \in CheckedOwnerDataDealer }
        \cup { [ZeroDirectedOrderAcceptation EXCEPT !.additionalPrice = one] : one \in Sample(10) }
        \cup { [ZeroDirectedOrderAcceptation EXCEPT !.quantityTerm = one] : one \in Sample(1) }
        \cup { [ZeroDirectedOrderAcceptation EXCEPT !.postTradingInstruction = one] : one \in Sample(50) }
        \cup { [ZeroDirectedOrderAcceptation EXCEPT !.additionalQuantity = one] : one \in Sample(8) }
        \cup { [ZeroDirectedOrderAcceptation EXCEPT !.additionalClientMemo = one] : one \in Sample(16) }

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
(* Order Entry: 221 bytes                                                  *)
(***************************************************************************)

OrderEntry ==
    [ group                   : Sample(2),
      instrumentOptional      : Sample(4),
      priceType               : Sample(1),
      verbSide                : Sample(1),
      quantity                : Sample(8),
      price                   : Sample(10),
      specialPriceTerm        : Sample(1),
      reserved10              : Sample(10),
      quantityTerm            : Sample(1),
      additionalQuantity      : Sample(8),
      durationType            : Sample(1),
      gtdDate                 : Sample(8),
      executingParticipant    : Sample(4),
      imlHandling             : Sample(1),
      clearingData            : ClearingData2,
      ownerData               : OwnerData2,
      postTradingInstructions : Sample(50),
      additionalClientMemo    : Sample(16),
      reserved4               : Sample(4) ]

EncodeOrderEntry(message) ==
    message.group
        \o message.instrumentOptional
        \o message.priceType
        \o message.verbSide
        \o message.quantity
        \o message.price
        \o message.specialPriceTerm
        \o message.reserved10
        \o message.quantityTerm
        \o message.additionalQuantity
        \o message.durationType
        \o message.gtdDate
        \o message.executingParticipant
        \o message.imlHandling
        \o EncodeClearingData2(message.clearingData)
        \o EncodeOwnerData2(message.ownerData)
        \o message.postTradingInstructions
        \o message.additionalClientMemo
        \o message.reserved4

DecodeOrderEntry(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrumentOptional == ReadBytes(group.rest, 4) IN IF ~instrumentOptional.ok THEN Fail ELSE
    LET priceType == ReadBytes(instrumentOptional.rest, 1) IN IF ~priceType.ok THEN Fail ELSE
    LET verbSide == ReadBytes(priceType.rest, 1) IN IF ~verbSide.ok THEN Fail ELSE
    LET quantity == ReadBytes(verbSide.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 10) IN IF ~price.ok THEN Fail ELSE
    LET specialPriceTerm == ReadBytes(price.rest, 1) IN IF ~specialPriceTerm.ok THEN Fail ELSE
    LET reserved10 == ReadBytes(specialPriceTerm.rest, 10) IN IF ~reserved10.ok THEN Fail ELSE
    LET quantityTerm == ReadBytes(reserved10.rest, 1) IN IF ~quantityTerm.ok THEN Fail ELSE
    LET additionalQuantity == ReadBytes(quantityTerm.rest, 8) IN IF ~additionalQuantity.ok THEN Fail ELSE
    LET durationType == ReadBytes(additionalQuantity.rest, 1) IN IF ~durationType.ok THEN Fail ELSE
    LET gtdDate == ReadBytes(durationType.rest, 8) IN IF ~gtdDate.ok THEN Fail ELSE
    LET executingParticipant == ReadBytes(gtdDate.rest, 4) IN IF ~executingParticipant.ok THEN Fail ELSE
    LET imlHandling == ReadBytes(executingParticipant.rest, 1) IN IF ~imlHandling.ok THEN Fail ELSE
    LET clearingData == DecodeClearingData2(imlHandling.rest) IN IF ~clearingData.ok THEN Fail ELSE
    LET ownerData == DecodeOwnerData2(clearingData.rest) IN IF ~ownerData.ok THEN Fail ELSE
    LET postTradingInstructions == ReadBytes(ownerData.rest, 50) IN IF ~postTradingInstructions.ok THEN Fail ELSE
    LET additionalClientMemo == ReadBytes(postTradingInstructions.rest, 16) IN IF ~additionalClientMemo.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(additionalClientMemo.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    Ok([ group                   |-> group.value,
         instrumentOptional      |-> instrumentOptional.value,
         priceType               |-> priceType.value,
         verbSide                |-> verbSide.value,
         quantity                |-> quantity.value,
         price                   |-> price.value,
         specialPriceTerm        |-> specialPriceTerm.value,
         reserved10              |-> reserved10.value,
         quantityTerm            |-> quantityTerm.value,
         additionalQuantity      |-> additionalQuantity.value,
         durationType            |-> durationType.value,
         gtdDate                 |-> gtdDate.value,
         executingParticipant    |-> executingParticipant.value,
         imlHandling             |-> imlHandling.value,
         clearingData            |-> clearingData.value,
         ownerData               |-> ownerData.value,
         postTradingInstructions |-> postTradingInstructions.value,
         additionalClientMemo    |-> additionalClientMemo.value,
         reserved4               |-> reserved4.value ], reserved4.rest)

ZeroOrderEntry ==
    [ group                   |-> [i \in 1 .. 2 |-> 0],
      instrumentOptional      |-> [i \in 1 .. 4 |-> 0],
      priceType               |-> [i \in 1 .. 1 |-> 0],
      verbSide                |-> [i \in 1 .. 1 |-> 0],
      quantity                |-> [i \in 1 .. 8 |-> 0],
      price                   |-> [i \in 1 .. 10 |-> 0],
      specialPriceTerm        |-> [i \in 1 .. 1 |-> 0],
      reserved10              |-> [i \in 1 .. 10 |-> 0],
      quantityTerm            |-> [i \in 1 .. 1 |-> 0],
      additionalQuantity      |-> [i \in 1 .. 8 |-> 0],
      durationType            |-> [i \in 1 .. 1 |-> 0],
      gtdDate                 |-> [i \in 1 .. 8 |-> 0],
      executingParticipant    |-> [i \in 1 .. 4 |-> 0],
      imlHandling             |-> [i \in 1 .. 1 |-> 0],
      clearingData            |-> ZeroClearingData2,
      ownerData               |-> ZeroOwnerData2,
      postTradingInstructions |-> [i \in 1 .. 50 |-> 0],
      additionalClientMemo    |-> [i \in 1 .. 16 |-> 0],
      reserved4               |-> [i \in 1 .. 4 |-> 0] ]

(* Order Entry at zero, then each field in turn at the values it is checked at *)
CheckedOrderEntry ==
    { ZeroOrderEntry }
        \cup { [ZeroOrderEntry EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntry EXCEPT !.instrumentOptional = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntry EXCEPT !.priceType = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntry EXCEPT !.verbSide = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntry EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroOrderEntry EXCEPT !.price = one] : one \in Sample(10) }
        \cup { [ZeroOrderEntry EXCEPT !.specialPriceTerm = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntry EXCEPT !.reserved10 = one] : one \in Sample(10) }
        \cup { [ZeroOrderEntry EXCEPT !.quantityTerm = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntry EXCEPT !.additionalQuantity = one] : one \in Sample(8) }
        \cup { [ZeroOrderEntry EXCEPT !.durationType = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntry EXCEPT !.gtdDate = one] : one \in Sample(8) }
        \cup { [ZeroOrderEntry EXCEPT !.executingParticipant = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntry EXCEPT !.imlHandling = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntry EXCEPT !.clearingData = one] : one \in CheckedClearingData2 }
        \cup { [ZeroOrderEntry EXCEPT !.ownerData = one] : one \in CheckedOwnerData2 }
        \cup { [ZeroOrderEntry EXCEPT !.postTradingInstructions = one] : one \in Sample(50) }
        \cup { [ZeroOrderEntry EXCEPT !.additionalClientMemo = one] : one \in Sample(16) }
        \cup { [ZeroOrderEntry EXCEPT !.reserved4 = one] : one \in Sample(4) }

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
(* Improvement Order Entry: 210 bytes                                      *)
(***************************************************************************)

ImprovementOrderEntry ==
    [ group                   : Sample(2),
      instrumentOptional      : Sample(4),
      verbSide                : Sample(1),
      quantitySign            : Sample(1),
      quantity                : Sample(8),
      price                   : Sample(10),
      auctionIdOptional       : Sample(6),
      reserved17              : Sample(17),
      clearingData            : ClearingData3,
      ownerData               : OwnerData3,
      postTradingInstructions : Sample(50),
      additionalClientMemo    : Sample(16),
      reserved4               : Sample(4) ]

EncodeImprovementOrderEntry(message) ==
    message.group
        \o message.instrumentOptional
        \o message.verbSide
        \o message.quantitySign
        \o message.quantity
        \o message.price
        \o message.auctionIdOptional
        \o message.reserved17
        \o EncodeClearingData3(message.clearingData)
        \o EncodeOwnerData3(message.ownerData)
        \o message.postTradingInstructions
        \o message.additionalClientMemo
        \o message.reserved4

DecodeImprovementOrderEntry(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrumentOptional == ReadBytes(group.rest, 4) IN IF ~instrumentOptional.ok THEN Fail ELSE
    LET verbSide == ReadBytes(instrumentOptional.rest, 1) IN IF ~verbSide.ok THEN Fail ELSE
    LET quantitySign == ReadBytes(verbSide.rest, 1) IN IF ~quantitySign.ok THEN Fail ELSE
    LET quantity == ReadBytes(quantitySign.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 10) IN IF ~price.ok THEN Fail ELSE
    LET auctionIdOptional == ReadBytes(price.rest, 6) IN IF ~auctionIdOptional.ok THEN Fail ELSE
    LET reserved17 == ReadBytes(auctionIdOptional.rest, 17) IN IF ~reserved17.ok THEN Fail ELSE
    LET clearingData == DecodeClearingData3(reserved17.rest) IN IF ~clearingData.ok THEN Fail ELSE
    LET ownerData == DecodeOwnerData3(clearingData.rest) IN IF ~ownerData.ok THEN Fail ELSE
    LET postTradingInstructions == ReadBytes(ownerData.rest, 50) IN IF ~postTradingInstructions.ok THEN Fail ELSE
    LET additionalClientMemo == ReadBytes(postTradingInstructions.rest, 16) IN IF ~additionalClientMemo.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(additionalClientMemo.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    Ok([ group                   |-> group.value,
         instrumentOptional      |-> instrumentOptional.value,
         verbSide                |-> verbSide.value,
         quantitySign            |-> quantitySign.value,
         quantity                |-> quantity.value,
         price                   |-> price.value,
         auctionIdOptional       |-> auctionIdOptional.value,
         reserved17              |-> reserved17.value,
         clearingData            |-> clearingData.value,
         ownerData               |-> ownerData.value,
         postTradingInstructions |-> postTradingInstructions.value,
         additionalClientMemo    |-> additionalClientMemo.value,
         reserved4               |-> reserved4.value ], reserved4.rest)

ZeroImprovementOrderEntry ==
    [ group                   |-> [i \in 1 .. 2 |-> 0],
      instrumentOptional      |-> [i \in 1 .. 4 |-> 0],
      verbSide                |-> [i \in 1 .. 1 |-> 0],
      quantitySign            |-> [i \in 1 .. 1 |-> 0],
      quantity                |-> [i \in 1 .. 8 |-> 0],
      price                   |-> [i \in 1 .. 10 |-> 0],
      auctionIdOptional       |-> [i \in 1 .. 6 |-> 0],
      reserved17              |-> [i \in 1 .. 17 |-> 0],
      clearingData            |-> ZeroClearingData3,
      ownerData               |-> ZeroOwnerData3,
      postTradingInstructions |-> [i \in 1 .. 50 |-> 0],
      additionalClientMemo    |-> [i \in 1 .. 16 |-> 0],
      reserved4               |-> [i \in 1 .. 4 |-> 0] ]

(* Improvement Order Entry at zero, then each field in turn at the values it is checked at *)
CheckedImprovementOrderEntry ==
    { ZeroImprovementOrderEntry }
        \cup { [ZeroImprovementOrderEntry EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroImprovementOrderEntry EXCEPT !.instrumentOptional = one] : one \in Sample(4) }
        \cup { [ZeroImprovementOrderEntry EXCEPT !.verbSide = one] : one \in Sample(1) }
        \cup { [ZeroImprovementOrderEntry EXCEPT !.quantitySign = one] : one \in Sample(1) }
        \cup { [ZeroImprovementOrderEntry EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroImprovementOrderEntry EXCEPT !.price = one] : one \in Sample(10) }
        \cup { [ZeroImprovementOrderEntry EXCEPT !.auctionIdOptional = one] : one \in Sample(6) }
        \cup { [ZeroImprovementOrderEntry EXCEPT !.reserved17 = one] : one \in Sample(17) }
        \cup { [ZeroImprovementOrderEntry EXCEPT !.clearingData = one] : one \in CheckedClearingData3 }
        \cup { [ZeroImprovementOrderEntry EXCEPT !.ownerData = one] : one \in CheckedOwnerData3 }
        \cup { [ZeroImprovementOrderEntry EXCEPT !.postTradingInstructions = one] : one \in Sample(50) }
        \cup { [ZeroImprovementOrderEntry EXCEPT !.additionalClientMemo = one] : one \in Sample(16) }
        \cup { [ZeroImprovementOrderEntry EXCEPT !.reserved4 = one] : one \in Sample(4) }

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
(* Order Modification: 230 bytes                                           *)
(***************************************************************************)

OrderModification ==
    [ group                  : Sample(2),
      instrumentOptional     : Sample(4),
      priceType              : Sample(1),
      verbSide               : Sample(1),
      quantitySign           : Sample(1),
      quantity               : Sample(8),
      price                  : Sample(10),
      specialPriceTerm       : Sample(1),
      reserved10             : Sample(10),
      reserved1              : Sample(1),
      reserved8              : Sample(8),
      durationType           : Sample(1),
      gtdDate                : Sample(8),
      firmId                 : Sample(4),
      imlHandling            : Sample(1),
      modifiedOrderId        : Sample(8),
      clearingData           : ClearingData4,
      ownerData              : OwnerData4,
      postTradingInstruction : Sample(50),
      additionalClientMemo   : Sample(16),
      reserved4              : Sample(4) ]

EncodeOrderModification(message) ==
    message.group
        \o message.instrumentOptional
        \o message.priceType
        \o message.verbSide
        \o message.quantitySign
        \o message.quantity
        \o message.price
        \o message.specialPriceTerm
        \o message.reserved10
        \o message.reserved1
        \o message.reserved8
        \o message.durationType
        \o message.gtdDate
        \o message.firmId
        \o message.imlHandling
        \o message.modifiedOrderId
        \o EncodeClearingData4(message.clearingData)
        \o EncodeOwnerData4(message.ownerData)
        \o message.postTradingInstruction
        \o message.additionalClientMemo
        \o message.reserved4

DecodeOrderModification(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrumentOptional == ReadBytes(group.rest, 4) IN IF ~instrumentOptional.ok THEN Fail ELSE
    LET priceType == ReadBytes(instrumentOptional.rest, 1) IN IF ~priceType.ok THEN Fail ELSE
    LET verbSide == ReadBytes(priceType.rest, 1) IN IF ~verbSide.ok THEN Fail ELSE
    LET quantitySign == ReadBytes(verbSide.rest, 1) IN IF ~quantitySign.ok THEN Fail ELSE
    LET quantity == ReadBytes(quantitySign.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 10) IN IF ~price.ok THEN Fail ELSE
    LET specialPriceTerm == ReadBytes(price.rest, 1) IN IF ~specialPriceTerm.ok THEN Fail ELSE
    LET reserved10 == ReadBytes(specialPriceTerm.rest, 10) IN IF ~reserved10.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(reserved10.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(reserved1.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    LET durationType == ReadBytes(reserved8.rest, 1) IN IF ~durationType.ok THEN Fail ELSE
    LET gtdDate == ReadBytes(durationType.rest, 8) IN IF ~gtdDate.ok THEN Fail ELSE
    LET firmId == ReadBytes(gtdDate.rest, 4) IN IF ~firmId.ok THEN Fail ELSE
    LET imlHandling == ReadBytes(firmId.rest, 1) IN IF ~imlHandling.ok THEN Fail ELSE
    LET modifiedOrderId == ReadBytes(imlHandling.rest, 8) IN IF ~modifiedOrderId.ok THEN Fail ELSE
    LET clearingData == DecodeClearingData4(modifiedOrderId.rest) IN IF ~clearingData.ok THEN Fail ELSE
    LET ownerData == DecodeOwnerData4(clearingData.rest) IN IF ~ownerData.ok THEN Fail ELSE
    LET postTradingInstruction == ReadBytes(ownerData.rest, 50) IN IF ~postTradingInstruction.ok THEN Fail ELSE
    LET additionalClientMemo == ReadBytes(postTradingInstruction.rest, 16) IN IF ~additionalClientMemo.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(additionalClientMemo.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    Ok([ group                  |-> group.value,
         instrumentOptional     |-> instrumentOptional.value,
         priceType              |-> priceType.value,
         verbSide               |-> verbSide.value,
         quantitySign           |-> quantitySign.value,
         quantity               |-> quantity.value,
         price                  |-> price.value,
         specialPriceTerm       |-> specialPriceTerm.value,
         reserved10             |-> reserved10.value,
         reserved1              |-> reserved1.value,
         reserved8              |-> reserved8.value,
         durationType           |-> durationType.value,
         gtdDate                |-> gtdDate.value,
         firmId                 |-> firmId.value,
         imlHandling            |-> imlHandling.value,
         modifiedOrderId        |-> modifiedOrderId.value,
         clearingData           |-> clearingData.value,
         ownerData              |-> ownerData.value,
         postTradingInstruction |-> postTradingInstruction.value,
         additionalClientMemo   |-> additionalClientMemo.value,
         reserved4              |-> reserved4.value ], reserved4.rest)

ZeroOrderModification ==
    [ group                  |-> [i \in 1 .. 2 |-> 0],
      instrumentOptional     |-> [i \in 1 .. 4 |-> 0],
      priceType              |-> [i \in 1 .. 1 |-> 0],
      verbSide               |-> [i \in 1 .. 1 |-> 0],
      quantitySign           |-> [i \in 1 .. 1 |-> 0],
      quantity               |-> [i \in 1 .. 8 |-> 0],
      price                  |-> [i \in 1 .. 10 |-> 0],
      specialPriceTerm       |-> [i \in 1 .. 1 |-> 0],
      reserved10             |-> [i \in 1 .. 10 |-> 0],
      reserved1              |-> [i \in 1 .. 1 |-> 0],
      reserved8              |-> [i \in 1 .. 8 |-> 0],
      durationType           |-> [i \in 1 .. 1 |-> 0],
      gtdDate                |-> [i \in 1 .. 8 |-> 0],
      firmId                 |-> [i \in 1 .. 4 |-> 0],
      imlHandling            |-> [i \in 1 .. 1 |-> 0],
      modifiedOrderId        |-> [i \in 1 .. 8 |-> 0],
      clearingData           |-> ZeroClearingData4,
      ownerData              |-> ZeroOwnerData4,
      postTradingInstruction |-> [i \in 1 .. 50 |-> 0],
      additionalClientMemo   |-> [i \in 1 .. 16 |-> 0],
      reserved4              |-> [i \in 1 .. 4 |-> 0] ]

(* Order Modification at zero, then each field in turn at the values it is checked at *)
CheckedOrderModification ==
    { ZeroOrderModification }
        \cup { [ZeroOrderModification EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroOrderModification EXCEPT !.instrumentOptional = one] : one \in Sample(4) }
        \cup { [ZeroOrderModification EXCEPT !.priceType = one] : one \in Sample(1) }
        \cup { [ZeroOrderModification EXCEPT !.verbSide = one] : one \in Sample(1) }
        \cup { [ZeroOrderModification EXCEPT !.quantitySign = one] : one \in Sample(1) }
        \cup { [ZeroOrderModification EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroOrderModification EXCEPT !.price = one] : one \in Sample(10) }
        \cup { [ZeroOrderModification EXCEPT !.specialPriceTerm = one] : one \in Sample(1) }
        \cup { [ZeroOrderModification EXCEPT !.reserved10 = one] : one \in Sample(10) }
        \cup { [ZeroOrderModification EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderModification EXCEPT !.reserved8 = one] : one \in Sample(8) }
        \cup { [ZeroOrderModification EXCEPT !.durationType = one] : one \in Sample(1) }
        \cup { [ZeroOrderModification EXCEPT !.gtdDate = one] : one \in Sample(8) }
        \cup { [ZeroOrderModification EXCEPT !.firmId = one] : one \in Sample(4) }
        \cup { [ZeroOrderModification EXCEPT !.imlHandling = one] : one \in Sample(1) }
        \cup { [ZeroOrderModification EXCEPT !.modifiedOrderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderModification EXCEPT !.clearingData = one] : one \in CheckedClearingData4 }
        \cup { [ZeroOrderModification EXCEPT !.ownerData = one] : one \in CheckedOwnerData4 }
        \cup { [ZeroOrderModification EXCEPT !.postTradingInstruction = one] : one \in Sample(50) }
        \cup { [ZeroOrderModification EXCEPT !.additionalClientMemo = one] : one \in Sample(16) }
        \cup { [ZeroOrderModification EXCEPT !.reserved4 = one] : one \in Sample(4) }

(***************************************************************************)
(* New Complex Order Instrument Occurrence: 16 bytes                       *)
(***************************************************************************)

NewComplexOrderInstrumentOccurrence ==
    [ legGroup         : Sample(2),
      legInstrumentId  : Sample(4),
      legVerb          : Sample(1),
      reserved1        : Sample(1),
      legQuantityRatio : Sample(8) ]

EncodeNewComplexOrderInstrumentOccurrence(message) ==
    message.legGroup
        \o message.legInstrumentId
        \o message.legVerb
        \o message.reserved1
        \o message.legQuantityRatio

DecodeNewComplexOrderInstrumentOccurrence(bytes) ==
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

ZeroNewComplexOrderInstrumentOccurrence ==
    [ legGroup         |-> [i \in 1 .. 2 |-> 0],
      legInstrumentId  |-> [i \in 1 .. 4 |-> 0],
      legVerb          |-> [i \in 1 .. 1 |-> 0],
      reserved1        |-> [i \in 1 .. 1 |-> 0],
      legQuantityRatio |-> [i \in 1 .. 8 |-> 0] ]

(* New Complex Order Instrument Occurrence at zero, then each field in turn at the values it is checked at *)
CheckedNewComplexOrderInstrumentOccurrence ==
    { ZeroNewComplexOrderInstrumentOccurrence }
        \cup { [ZeroNewComplexOrderInstrumentOccurrence EXCEPT !.legGroup = one] : one \in Sample(2) }
        \cup { [ZeroNewComplexOrderInstrumentOccurrence EXCEPT !.legInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexOrderInstrumentOccurrence EXCEPT !.legVerb = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderInstrumentOccurrence EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderInstrumentOccurrence EXCEPT !.legQuantityRatio = one] : one \in Sample(8) }

(* A run of New Complex Order Instrument Occurrence, written one after another *)
RECURSIVE EncodeNewComplexOrderInstrumentOccurrenceList(_)
EncodeNewComplexOrderInstrumentOccurrenceList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeNewComplexOrderInstrumentOccurrence(Head(messages)) \o EncodeNewComplexOrderInstrumentOccurrenceList(Tail(messages))

(* As many New Complex Order Instrument Occurrence as the field that counts them says *)
RECURSIVE ReadNewComplexOrderInstrumentOccurrenceList(_, _)
ReadNewComplexOrderInstrumentOccurrenceList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeNewComplexOrderInstrumentOccurrence(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadNewComplexOrderInstrumentOccurrenceList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One New Complex Order Instrument Occurrence of each kind, for the lists that carry them *)
OneNewComplexOrderInstrumentOccurrence == { ZeroNewComplexOrderInstrumentOccurrence }

(***************************************************************************)
(* New Complex Order Instrument                                            *)
(***************************************************************************)

NewComplexOrderInstrument ==
    [ enabledYYesNNo                      : Sample(1),
      newComplexOrderInstrumentOccurrence : SampleLists(OneNewComplexOrderInstrumentOccurrence) ]

EncodeNewComplexOrderInstrument(message) ==
    message.enabledYYesNNo
        \o EncodeDigits(Len(message.newComplexOrderInstrumentOccurrence), 2)
        \o EncodeNewComplexOrderInstrumentOccurrenceList(message.newComplexOrderInstrumentOccurrence)

DecodeNewComplexOrderInstrument(bytes) ==
    LET enabledYYesNNo == ReadBytes(bytes, 1) IN IF ~enabledYYesNNo.ok THEN Fail ELSE
    LET numberOfLegs == ReadDigits(enabledYYesNNo.rest, 2) IN IF ~numberOfLegs.ok THEN Fail ELSE
    LET newComplexOrderInstrumentOccurrence == ReadNewComplexOrderInstrumentOccurrenceList(numberOfLegs.rest, numberOfLegs.value) IN IF ~newComplexOrderInstrumentOccurrence.ok THEN Fail ELSE
    Ok([ enabledYYesNNo                      |-> enabledYYesNNo.value,
         newComplexOrderInstrumentOccurrence |-> newComplexOrderInstrumentOccurrence.value ], newComplexOrderInstrumentOccurrence.rest)

ZeroNewComplexOrderInstrument ==
    [ enabledYYesNNo                      |-> [i \in 1 .. 1 |-> 0],
      newComplexOrderInstrumentOccurrence |-> << >> ]

(* New Complex Order Instrument at zero, then each field in turn at the values it is checked at *)
CheckedNewComplexOrderInstrument ==
    { ZeroNewComplexOrderInstrument }
        \cup { [ZeroNewComplexOrderInstrument EXCEPT !.enabledYYesNNo = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderInstrument EXCEPT !.newComplexOrderInstrumentOccurrence = one] : one \in SampleLists(OneNewComplexOrderInstrumentOccurrence) }

(***************************************************************************)
(* Buying Clearing Data: 20 bytes                                          *)
(***************************************************************************)

BuyingClearingData2 ==
    [ clearingInstruction   : Sample(12),
      accountType           : Sample(1),
      openClose             : Sample(1),
      hedgeSpec             : Sample(1),
      clearingOperationMode : Sample(1),
      clearingDestination   : Sample(4) ]

EncodeBuyingClearingData2(message) ==
    message.clearingInstruction
        \o message.accountType
        \o message.openClose
        \o message.hedgeSpec
        \o message.clearingOperationMode
        \o message.clearingDestination

DecodeBuyingClearingData2(bytes) ==
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

ZeroBuyingClearingData2 ==
    [ clearingInstruction   |-> [i \in 1 .. 12 |-> 0],
      accountType           |-> [i \in 1 .. 1 |-> 0],
      openClose             |-> [i \in 1 .. 1 |-> 0],
      hedgeSpec             |-> [i \in 1 .. 1 |-> 0],
      clearingOperationMode |-> [i \in 1 .. 1 |-> 0],
      clearingDestination   |-> [i \in 1 .. 4 |-> 0] ]

(* Buying Clearing Data at zero, then each field in turn at the values it is checked at *)
CheckedBuyingClearingData2 ==
    { ZeroBuyingClearingData2 }
        \cup { [ZeroBuyingClearingData2 EXCEPT !.clearingInstruction = one] : one \in Sample(12) }
        \cup { [ZeroBuyingClearingData2 EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroBuyingClearingData2 EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroBuyingClearingData2 EXCEPT !.hedgeSpec = one] : one \in Sample(1) }
        \cup { [ZeroBuyingClearingData2 EXCEPT !.clearingOperationMode = one] : one \in Sample(1) }
        \cup { [ZeroBuyingClearingData2 EXCEPT !.clearingDestination = one] : one \in Sample(4) }

(***************************************************************************)
(* Selling Clearing Data: 20 bytes                                         *)
(***************************************************************************)

SellingClearingData2 ==
    [ clearingInstruction   : Sample(12),
      accountType           : Sample(1),
      openClose             : Sample(1),
      hedgeSpec             : Sample(1),
      clearingOperationMode : Sample(1),
      clearingDestination   : Sample(4) ]

EncodeSellingClearingData2(message) ==
    message.clearingInstruction
        \o message.accountType
        \o message.openClose
        \o message.hedgeSpec
        \o message.clearingOperationMode
        \o message.clearingDestination

DecodeSellingClearingData2(bytes) ==
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

ZeroSellingClearingData2 ==
    [ clearingInstruction   |-> [i \in 1 .. 12 |-> 0],
      accountType           |-> [i \in 1 .. 1 |-> 0],
      openClose             |-> [i \in 1 .. 1 |-> 0],
      hedgeSpec             |-> [i \in 1 .. 1 |-> 0],
      clearingOperationMode |-> [i \in 1 .. 1 |-> 0],
      clearingDestination   |-> [i \in 1 .. 4 |-> 0] ]

(* Selling Clearing Data at zero, then each field in turn at the values it is checked at *)
CheckedSellingClearingData2 ==
    { ZeroSellingClearingData2 }
        \cup { [ZeroSellingClearingData2 EXCEPT !.clearingInstruction = one] : one \in Sample(12) }
        \cup { [ZeroSellingClearingData2 EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroSellingClearingData2 EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroSellingClearingData2 EXCEPT !.hedgeSpec = one] : one \in Sample(1) }
        \cup { [ZeroSellingClearingData2 EXCEPT !.clearingOperationMode = one] : one \in Sample(1) }
        \cup { [ZeroSellingClearingData2 EXCEPT !.clearingDestination = one] : one \in Sample(4) }

(***************************************************************************)
(* Buying Owner Data: 71 bytes                                             *)
(***************************************************************************)

BuyingOwnerData2 ==
    [ clientOrderId : Sample(20),
      poundSign     : Sample(1),
      memo          : Sample(50) ]

EncodeBuyingOwnerData2(message) ==
    message.clientOrderId
        \o message.poundSign
        \o message.memo

DecodeBuyingOwnerData2(bytes) ==
    LET clientOrderId == ReadBytes(bytes, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET poundSign == ReadBytes(clientOrderId.rest, 1) IN IF ~poundSign.ok THEN Fail ELSE
    LET memo == ReadBytes(poundSign.rest, 50) IN IF ~memo.ok THEN Fail ELSE
    Ok([ clientOrderId |-> clientOrderId.value,
         poundSign     |-> poundSign.value,
         memo          |-> memo.value ], memo.rest)

ZeroBuyingOwnerData2 ==
    [ clientOrderId |-> [i \in 1 .. 20 |-> 0],
      poundSign     |-> [i \in 1 .. 1 |-> 0],
      memo          |-> [i \in 1 .. 50 |-> 0] ]

(* Buying Owner Data at zero, then each field in turn at the values it is checked at *)
CheckedBuyingOwnerData2 ==
    { ZeroBuyingOwnerData2 }
        \cup { [ZeroBuyingOwnerData2 EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroBuyingOwnerData2 EXCEPT !.poundSign = one] : one \in Sample(1) }
        \cup { [ZeroBuyingOwnerData2 EXCEPT !.memo = one] : one \in Sample(50) }

(***************************************************************************)
(* Selling Owner Data: 71 bytes                                            *)
(***************************************************************************)

SellingOwnerData2 ==
    [ clientOrderId : Sample(20),
      poundSign     : Sample(1),
      memo          : Sample(50) ]

EncodeSellingOwnerData2(message) ==
    message.clientOrderId
        \o message.poundSign
        \o message.memo

DecodeSellingOwnerData2(bytes) ==
    LET clientOrderId == ReadBytes(bytes, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET poundSign == ReadBytes(clientOrderId.rest, 1) IN IF ~poundSign.ok THEN Fail ELSE
    LET memo == ReadBytes(poundSign.rest, 50) IN IF ~memo.ok THEN Fail ELSE
    Ok([ clientOrderId |-> clientOrderId.value,
         poundSign     |-> poundSign.value,
         memo          |-> memo.value ], memo.rest)

ZeroSellingOwnerData2 ==
    [ clientOrderId |-> [i \in 1 .. 20 |-> 0],
      poundSign     |-> [i \in 1 .. 1 |-> 0],
      memo          |-> [i \in 1 .. 50 |-> 0] ]

(* Selling Owner Data at zero, then each field in turn at the values it is checked at *)
CheckedSellingOwnerData2 ==
    { ZeroSellingOwnerData2 }
        \cup { [ZeroSellingOwnerData2 EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroSellingOwnerData2 EXCEPT !.poundSign = one] : one \in Sample(1) }
        \cup { [ZeroSellingOwnerData2 EXCEPT !.memo = one] : one \in Sample(50) }

(***************************************************************************)
(* Complex Order Auction Entry Occurrence: 16 bytes                        *)
(***************************************************************************)

ComplexOrderAuctionEntryOccurrence ==
    [ legGroup      : Sample(2),
      legInstrument : Sample(4),
      tradeLegPrice : Sample(10) ]

EncodeComplexOrderAuctionEntryOccurrence(message) ==
    message.legGroup
        \o message.legInstrument
        \o message.tradeLegPrice

DecodeComplexOrderAuctionEntryOccurrence(bytes) ==
    LET legGroup == ReadBytes(bytes, 2) IN IF ~legGroup.ok THEN Fail ELSE
    LET legInstrument == ReadBytes(legGroup.rest, 4) IN IF ~legInstrument.ok THEN Fail ELSE
    LET tradeLegPrice == ReadBytes(legInstrument.rest, 10) IN IF ~tradeLegPrice.ok THEN Fail ELSE
    Ok([ legGroup      |-> legGroup.value,
         legInstrument |-> legInstrument.value,
         tradeLegPrice |-> tradeLegPrice.value ], tradeLegPrice.rest)

ZeroComplexOrderAuctionEntryOccurrence ==
    [ legGroup      |-> [i \in 1 .. 2 |-> 0],
      legInstrument |-> [i \in 1 .. 4 |-> 0],
      tradeLegPrice |-> [i \in 1 .. 10 |-> 0] ]

(* Complex Order Auction Entry Occurrence at zero, then each field in turn at the values it is checked at *)
CheckedComplexOrderAuctionEntryOccurrence ==
    { ZeroComplexOrderAuctionEntryOccurrence }
        \cup { [ZeroComplexOrderAuctionEntryOccurrence EXCEPT !.legGroup = one] : one \in Sample(2) }
        \cup { [ZeroComplexOrderAuctionEntryOccurrence EXCEPT !.legInstrument = one] : one \in Sample(4) }
        \cup { [ZeroComplexOrderAuctionEntryOccurrence EXCEPT !.tradeLegPrice = one] : one \in Sample(10) }

(* A run of Complex Order Auction Entry Occurrence, written one after another *)
RECURSIVE EncodeComplexOrderAuctionEntryOccurrenceList(_)
EncodeComplexOrderAuctionEntryOccurrenceList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeComplexOrderAuctionEntryOccurrence(Head(messages)) \o EncodeComplexOrderAuctionEntryOccurrenceList(Tail(messages))

(* As many Complex Order Auction Entry Occurrence as the field that counts them says *)
RECURSIVE ReadComplexOrderAuctionEntryOccurrenceList(_, _)
ReadComplexOrderAuctionEntryOccurrenceList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeComplexOrderAuctionEntryOccurrence(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadComplexOrderAuctionEntryOccurrenceList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Complex Order Auction Entry Occurrence of each kind, for the lists that carry them *)
OneComplexOrderAuctionEntryOccurrence == { ZeroComplexOrderAuctionEntryOccurrence }

(***************************************************************************)
(* Complex Order Auction Entry                                             *)
(***************************************************************************)

ComplexOrderAuctionEntry ==
    [ group                              : Sample(2),
      instrumentOptional                 : Sample(4),
      verbSide                           : Sample(1),
      quantity                           : Sample(8),
      price                              : Sample(10),
      buyingClearingData                 : BuyingClearingData2,
      sellingClearingData                : SellingClearingData2,
      buyingOwnerData                    : BuyingOwnerData2,
      sellingOwnerData                   : SellingOwnerData2,
      imlHandling                        : Sample(1),
      specialPriceTerm                   : Sample(1),
      additionalPrice                    : Sample(10),
      quantityTerm                       : Sample(1),
      additionalQuantity                 : Sample(8),
      buyingPostTradingInstruction       : Sample(50),
      sellingPostTradingInstruction      : Sample(50),
      buyingAdditionalClientMemo         : Sample(16),
      sellingAdditionalClientMemo        : Sample(16),
      reserved4                          : Sample(4),
      complexOrderAuctionEntryOccurrence : SampleLists(OneComplexOrderAuctionEntryOccurrence) ]

EncodeComplexOrderAuctionEntry(message) ==
    message.group
        \o message.instrumentOptional
        \o message.verbSide
        \o message.quantity
        \o message.price
        \o EncodeBuyingClearingData2(message.buyingClearingData)
        \o EncodeSellingClearingData2(message.sellingClearingData)
        \o EncodeBuyingOwnerData2(message.buyingOwnerData)
        \o EncodeSellingOwnerData2(message.sellingOwnerData)
        \o message.imlHandling
        \o message.specialPriceTerm
        \o message.additionalPrice
        \o message.quantityTerm
        \o message.additionalQuantity
        \o message.buyingPostTradingInstruction
        \o message.sellingPostTradingInstruction
        \o message.buyingAdditionalClientMemo
        \o message.sellingAdditionalClientMemo
        \o message.reserved4
        \o EncodeDigits(Len(message.complexOrderAuctionEntryOccurrence), 2)
        \o EncodeComplexOrderAuctionEntryOccurrenceList(message.complexOrderAuctionEntryOccurrence)

DecodeComplexOrderAuctionEntry(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrumentOptional == ReadBytes(group.rest, 4) IN IF ~instrumentOptional.ok THEN Fail ELSE
    LET verbSide == ReadBytes(instrumentOptional.rest, 1) IN IF ~verbSide.ok THEN Fail ELSE
    LET quantity == ReadBytes(verbSide.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 10) IN IF ~price.ok THEN Fail ELSE
    LET buyingClearingData == DecodeBuyingClearingData2(price.rest) IN IF ~buyingClearingData.ok THEN Fail ELSE
    LET sellingClearingData == DecodeSellingClearingData2(buyingClearingData.rest) IN IF ~sellingClearingData.ok THEN Fail ELSE
    LET buyingOwnerData == DecodeBuyingOwnerData2(sellingClearingData.rest) IN IF ~buyingOwnerData.ok THEN Fail ELSE
    LET sellingOwnerData == DecodeSellingOwnerData2(buyingOwnerData.rest) IN IF ~sellingOwnerData.ok THEN Fail ELSE
    LET imlHandling == ReadBytes(sellingOwnerData.rest, 1) IN IF ~imlHandling.ok THEN Fail ELSE
    LET specialPriceTerm == ReadBytes(imlHandling.rest, 1) IN IF ~specialPriceTerm.ok THEN Fail ELSE
    LET additionalPrice == ReadBytes(specialPriceTerm.rest, 10) IN IF ~additionalPrice.ok THEN Fail ELSE
    LET quantityTerm == ReadBytes(additionalPrice.rest, 1) IN IF ~quantityTerm.ok THEN Fail ELSE
    LET additionalQuantity == ReadBytes(quantityTerm.rest, 8) IN IF ~additionalQuantity.ok THEN Fail ELSE
    LET buyingPostTradingInstruction == ReadBytes(additionalQuantity.rest, 50) IN IF ~buyingPostTradingInstruction.ok THEN Fail ELSE
    LET sellingPostTradingInstruction == ReadBytes(buyingPostTradingInstruction.rest, 50) IN IF ~sellingPostTradingInstruction.ok THEN Fail ELSE
    LET buyingAdditionalClientMemo == ReadBytes(sellingPostTradingInstruction.rest, 16) IN IF ~buyingAdditionalClientMemo.ok THEN Fail ELSE
    LET sellingAdditionalClientMemo == ReadBytes(buyingAdditionalClientMemo.rest, 16) IN IF ~sellingAdditionalClientMemo.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(sellingAdditionalClientMemo.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET nbLegs == ReadDigits(reserved4.rest, 2) IN IF ~nbLegs.ok THEN Fail ELSE
    LET complexOrderAuctionEntryOccurrence == ReadComplexOrderAuctionEntryOccurrenceList(nbLegs.rest, nbLegs.value) IN IF ~complexOrderAuctionEntryOccurrence.ok THEN Fail ELSE
    Ok([ group                              |-> group.value,
         instrumentOptional                 |-> instrumentOptional.value,
         verbSide                           |-> verbSide.value,
         quantity                           |-> quantity.value,
         price                              |-> price.value,
         buyingClearingData                 |-> buyingClearingData.value,
         sellingClearingData                |-> sellingClearingData.value,
         buyingOwnerData                    |-> buyingOwnerData.value,
         sellingOwnerData                   |-> sellingOwnerData.value,
         imlHandling                        |-> imlHandling.value,
         specialPriceTerm                   |-> specialPriceTerm.value,
         additionalPrice                    |-> additionalPrice.value,
         quantityTerm                       |-> quantityTerm.value,
         additionalQuantity                 |-> additionalQuantity.value,
         buyingPostTradingInstruction       |-> buyingPostTradingInstruction.value,
         sellingPostTradingInstruction      |-> sellingPostTradingInstruction.value,
         buyingAdditionalClientMemo         |-> buyingAdditionalClientMemo.value,
         sellingAdditionalClientMemo        |-> sellingAdditionalClientMemo.value,
         reserved4                          |-> reserved4.value,
         complexOrderAuctionEntryOccurrence |-> complexOrderAuctionEntryOccurrence.value ], complexOrderAuctionEntryOccurrence.rest)

ZeroComplexOrderAuctionEntry ==
    [ group                              |-> [i \in 1 .. 2 |-> 0],
      instrumentOptional                 |-> [i \in 1 .. 4 |-> 0],
      verbSide                           |-> [i \in 1 .. 1 |-> 0],
      quantity                           |-> [i \in 1 .. 8 |-> 0],
      price                              |-> [i \in 1 .. 10 |-> 0],
      buyingClearingData                 |-> ZeroBuyingClearingData2,
      sellingClearingData                |-> ZeroSellingClearingData2,
      buyingOwnerData                    |-> ZeroBuyingOwnerData2,
      sellingOwnerData                   |-> ZeroSellingOwnerData2,
      imlHandling                        |-> [i \in 1 .. 1 |-> 0],
      specialPriceTerm                   |-> [i \in 1 .. 1 |-> 0],
      additionalPrice                    |-> [i \in 1 .. 10 |-> 0],
      quantityTerm                       |-> [i \in 1 .. 1 |-> 0],
      additionalQuantity                 |-> [i \in 1 .. 8 |-> 0],
      buyingPostTradingInstruction       |-> [i \in 1 .. 50 |-> 0],
      sellingPostTradingInstruction      |-> [i \in 1 .. 50 |-> 0],
      buyingAdditionalClientMemo         |-> [i \in 1 .. 16 |-> 0],
      sellingAdditionalClientMemo        |-> [i \in 1 .. 16 |-> 0],
      reserved4                          |-> [i \in 1 .. 4 |-> 0],
      complexOrderAuctionEntryOccurrence |-> << >> ]

(* Complex Order Auction Entry at zero, then each field in turn at the values it is checked at *)
CheckedComplexOrderAuctionEntry ==
    { ZeroComplexOrderAuctionEntry }
        \cup { [ZeroComplexOrderAuctionEntry EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroComplexOrderAuctionEntry EXCEPT !.instrumentOptional = one] : one \in Sample(4) }
        \cup { [ZeroComplexOrderAuctionEntry EXCEPT !.verbSide = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderAuctionEntry EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroComplexOrderAuctionEntry EXCEPT !.price = one] : one \in Sample(10) }
        \cup { [ZeroComplexOrderAuctionEntry EXCEPT !.buyingClearingData = one] : one \in CheckedBuyingClearingData2 }
        \cup { [ZeroComplexOrderAuctionEntry EXCEPT !.sellingClearingData = one] : one \in CheckedSellingClearingData2 }
        \cup { [ZeroComplexOrderAuctionEntry EXCEPT !.buyingOwnerData = one] : one \in CheckedBuyingOwnerData2 }
        \cup { [ZeroComplexOrderAuctionEntry EXCEPT !.sellingOwnerData = one] : one \in CheckedSellingOwnerData2 }
        \cup { [ZeroComplexOrderAuctionEntry EXCEPT !.imlHandling = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderAuctionEntry EXCEPT !.specialPriceTerm = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderAuctionEntry EXCEPT !.additionalPrice = one] : one \in Sample(10) }
        \cup { [ZeroComplexOrderAuctionEntry EXCEPT !.quantityTerm = one] : one \in Sample(1) }
        \cup { [ZeroComplexOrderAuctionEntry EXCEPT !.additionalQuantity = one] : one \in Sample(8) }
        \cup { [ZeroComplexOrderAuctionEntry EXCEPT !.buyingPostTradingInstruction = one] : one \in Sample(50) }
        \cup { [ZeroComplexOrderAuctionEntry EXCEPT !.sellingPostTradingInstruction = one] : one \in Sample(50) }
        \cup { [ZeroComplexOrderAuctionEntry EXCEPT !.buyingAdditionalClientMemo = one] : one \in Sample(16) }
        \cup { [ZeroComplexOrderAuctionEntry EXCEPT !.sellingAdditionalClientMemo = one] : one \in Sample(16) }
        \cup { [ZeroComplexOrderAuctionEntry EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroComplexOrderAuctionEntry EXCEPT !.complexOrderAuctionEntryOccurrence = one] : one \in SampleLists(OneComplexOrderAuctionEntryOccurrence) }

(***************************************************************************)
(* Bulk Quote Occurrence: 26 bytes                                         *)
(***************************************************************************)

BulkQuoteOccurrence ==
    [ group              : Sample(2),
      instrumentOptional : Sample(4),
      verbSide           : Sample(1),
      quantitySign       : Sample(1),
      quantity           : Sample(8),
      price              : Sample(10) ]

EncodeBulkQuoteOccurrence(message) ==
    message.group
        \o message.instrumentOptional
        \o message.verbSide
        \o message.quantitySign
        \o message.quantity
        \o message.price

DecodeBulkQuoteOccurrence(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrumentOptional == ReadBytes(group.rest, 4) IN IF ~instrumentOptional.ok THEN Fail ELSE
    LET verbSide == ReadBytes(instrumentOptional.rest, 1) IN IF ~verbSide.ok THEN Fail ELSE
    LET quantitySign == ReadBytes(verbSide.rest, 1) IN IF ~quantitySign.ok THEN Fail ELSE
    LET quantity == ReadBytes(quantitySign.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 10) IN IF ~price.ok THEN Fail ELSE
    Ok([ group              |-> group.value,
         instrumentOptional |-> instrumentOptional.value,
         verbSide           |-> verbSide.value,
         quantitySign       |-> quantitySign.value,
         quantity           |-> quantity.value,
         price              |-> price.value ], price.rest)

ZeroBulkQuoteOccurrence ==
    [ group              |-> [i \in 1 .. 2 |-> 0],
      instrumentOptional |-> [i \in 1 .. 4 |-> 0],
      verbSide           |-> [i \in 1 .. 1 |-> 0],
      quantitySign       |-> [i \in 1 .. 1 |-> 0],
      quantity           |-> [i \in 1 .. 8 |-> 0],
      price              |-> [i \in 1 .. 10 |-> 0] ]

(* Bulk Quote Occurrence at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuoteOccurrence ==
    { ZeroBulkQuoteOccurrence }
        \cup { [ZeroBulkQuoteOccurrence EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuoteOccurrence EXCEPT !.instrumentOptional = one] : one \in Sample(4) }
        \cup { [ZeroBulkQuoteOccurrence EXCEPT !.verbSide = one] : one \in Sample(1) }
        \cup { [ZeroBulkQuoteOccurrence EXCEPT !.quantitySign = one] : one \in Sample(1) }
        \cup { [ZeroBulkQuoteOccurrence EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuoteOccurrence EXCEPT !.price = one] : one \in Sample(10) }

(* A run of Bulk Quote Occurrence, written one after another *)
RECURSIVE EncodeBulkQuoteOccurrenceList(_)
EncodeBulkQuoteOccurrenceList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeBulkQuoteOccurrence(Head(messages)) \o EncodeBulkQuoteOccurrenceList(Tail(messages))

(* As many Bulk Quote Occurrence as the field that counts them says *)
RECURSIVE ReadBulkQuoteOccurrenceList(_, _)
ReadBulkQuoteOccurrenceList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeBulkQuoteOccurrence(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadBulkQuoteOccurrenceList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Bulk Quote Occurrence of each kind, for the lists that carry them *)
OneBulkQuoteOccurrence == { ZeroBulkQuoteOccurrence }

(***************************************************************************)
(* Bulk Quote                                                              *)
(***************************************************************************)

BulkQuote ==
    [ group               : Sample(2),
      quoteId             : Sample(8),
      mmCatUserTime       : Sample(8),
      bulkQuoteOccurrence : SampleLists(OneBulkQuoteOccurrence) ]

EncodeBulkQuote(message) ==
    message.group
        \o message.quoteId
        \o message.mmCatUserTime
        \o EncodeDigits(Len(message.bulkQuoteOccurrence), 3)
        \o EncodeBulkQuoteOccurrenceList(message.bulkQuoteOccurrence)

DecodeBulkQuote(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET quoteId == ReadBytes(group.rest, 8) IN IF ~quoteId.ok THEN Fail ELSE
    LET mmCatUserTime == ReadBytes(quoteId.rest, 8) IN IF ~mmCatUserTime.ok THEN Fail ELSE
    LET numberOfQuotes == ReadDigits(mmCatUserTime.rest, 3) IN IF ~numberOfQuotes.ok THEN Fail ELSE
    LET bulkQuoteOccurrence == ReadBulkQuoteOccurrenceList(numberOfQuotes.rest, numberOfQuotes.value) IN IF ~bulkQuoteOccurrence.ok THEN Fail ELSE
    Ok([ group               |-> group.value,
         quoteId             |-> quoteId.value,
         mmCatUserTime       |-> mmCatUserTime.value,
         bulkQuoteOccurrence |-> bulkQuoteOccurrence.value ], bulkQuoteOccurrence.rest)

ZeroBulkQuote ==
    [ group               |-> [i \in 1 .. 2 |-> 0],
      quoteId             |-> [i \in 1 .. 8 |-> 0],
      mmCatUserTime       |-> [i \in 1 .. 8 |-> 0],
      bulkQuoteOccurrence |-> << >> ]

(* Bulk Quote at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuote ==
    { ZeroBulkQuote }
        \cup { [ZeroBulkQuote EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuote EXCEPT !.quoteId = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuote EXCEPT !.mmCatUserTime = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuote EXCEPT !.bulkQuoteOccurrence = one] : one \in SampleLists(OneBulkQuoteOccurrence) }

(***************************************************************************)
(* Market Maker Protection Subscription: 3 bytes                           *)
(***************************************************************************)

MarketMakerProtectionSubscription ==
    [ group                        : Sample(2),
      protectionTypeAdvancedNormal : Sample(1) ]

EncodeMarketMakerProtectionSubscription(message) ==
    message.group
        \o message.protectionTypeAdvancedNormal

DecodeMarketMakerProtectionSubscription(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET protectionTypeAdvancedNormal == ReadBytes(group.rest, 1) IN IF ~protectionTypeAdvancedNormal.ok THEN Fail ELSE
    Ok([ group                        |-> group.value,
         protectionTypeAdvancedNormal |-> protectionTypeAdvancedNormal.value ], protectionTypeAdvancedNormal.rest)

ZeroMarketMakerProtectionSubscription ==
    [ group                        |-> [i \in 1 .. 2 |-> 0],
      protectionTypeAdvancedNormal |-> [i \in 1 .. 1 |-> 0] ]

(* Market Maker Protection Subscription at zero, then each field in turn at the values it is checked at *)
CheckedMarketMakerProtectionSubscription ==
    { ZeroMarketMakerProtectionSubscription }
        \cup { [ZeroMarketMakerProtectionSubscription EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroMarketMakerProtectionSubscription EXCEPT !.protectionTypeAdvancedNormal = one] : one \in Sample(1) }

(***************************************************************************)
(* Request For Quote: 14 bytes                                             *)
(***************************************************************************)

RequestForQuote ==
    [ group              : Sample(2),
      instrumentOptional : Sample(4),
      quantity1          : Sample(8) ]

EncodeRequestForQuote(message) ==
    message.group
        \o message.instrumentOptional
        \o message.quantity1

DecodeRequestForQuote(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrumentOptional == ReadBytes(group.rest, 4) IN IF ~instrumentOptional.ok THEN Fail ELSE
    LET quantity1 == ReadBytes(instrumentOptional.rest, 8) IN IF ~quantity1.ok THEN Fail ELSE
    Ok([ group              |-> group.value,
         instrumentOptional |-> instrumentOptional.value,
         quantity1          |-> quantity1.value ], quantity1.rest)

ZeroRequestForQuote ==
    [ group              |-> [i \in 1 .. 2 |-> 0],
      instrumentOptional |-> [i \in 1 .. 4 |-> 0],
      quantity1          |-> [i \in 1 .. 8 |-> 0] ]

(* Request For Quote at zero, then each field in turn at the values it is checked at *)
CheckedRequestForQuote ==
    { ZeroRequestForQuote }
        \cup { [ZeroRequestForQuote EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroRequestForQuote EXCEPT !.instrumentOptional = one] : one \in Sample(4) }
        \cup { [ZeroRequestForQuote EXCEPT !.quantity1 = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Cancellation: 14 bytes                                            *)
(***************************************************************************)

OrderCancellation ==
    [ group              : Sample(2),
      instrumentOptional : Sample(4),
      cancelledOrderId   : Sample(8) ]

EncodeOrderCancellation(message) ==
    message.group
        \o message.instrumentOptional
        \o message.cancelledOrderId

DecodeOrderCancellation(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrumentOptional == ReadBytes(group.rest, 4) IN IF ~instrumentOptional.ok THEN Fail ELSE
    LET cancelledOrderId == ReadBytes(instrumentOptional.rest, 8) IN IF ~cancelledOrderId.ok THEN Fail ELSE
    Ok([ group              |-> group.value,
         instrumentOptional |-> instrumentOptional.value,
         cancelledOrderId   |-> cancelledOrderId.value ], cancelledOrderId.rest)

ZeroOrderCancellation ==
    [ group              |-> [i \in 1 .. 2 |-> 0],
      instrumentOptional |-> [i \in 1 .. 4 |-> 0],
      cancelledOrderId   |-> [i \in 1 .. 8 |-> 0] ]

(* Order Cancellation at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancellation ==
    { ZeroOrderCancellation }
        \cup { [ZeroOrderCancellation EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancellation EXCEPT !.instrumentOptional = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancellation EXCEPT !.cancelledOrderId = one] : one \in Sample(8) }

(***************************************************************************)
(* Improvement Order Cancellation: 14 bytes                                *)
(***************************************************************************)

ImprovementOrderCancellation ==
    [ group              : Sample(2),
      instrumentOptional : Sample(4),
      cancelledOrderId   : Sample(8) ]

EncodeImprovementOrderCancellation(message) ==
    message.group
        \o message.instrumentOptional
        \o message.cancelledOrderId

DecodeImprovementOrderCancellation(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrumentOptional == ReadBytes(group.rest, 4) IN IF ~instrumentOptional.ok THEN Fail ELSE
    LET cancelledOrderId == ReadBytes(instrumentOptional.rest, 8) IN IF ~cancelledOrderId.ok THEN Fail ELSE
    Ok([ group              |-> group.value,
         instrumentOptional |-> instrumentOptional.value,
         cancelledOrderId   |-> cancelledOrderId.value ], cancelledOrderId.rest)

ZeroImprovementOrderCancellation ==
    [ group              |-> [i \in 1 .. 2 |-> 0],
      instrumentOptional |-> [i \in 1 .. 4 |-> 0],
      cancelledOrderId   |-> [i \in 1 .. 8 |-> 0] ]

(* Improvement Order Cancellation at zero, then each field in turn at the values it is checked at *)
CheckedImprovementOrderCancellation ==
    { ZeroImprovementOrderCancellation }
        \cup { [ZeroImprovementOrderCancellation EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroImprovementOrderCancellation EXCEPT !.instrumentOptional = one] : one \in Sample(4) }
        \cup { [ZeroImprovementOrderCancellation EXCEPT !.cancelledOrderId = one] : one \in Sample(8) }

(***************************************************************************)
(* Firm Message, selected by Message Type                                  *)
(***************************************************************************)

UserConnectionCode == 21571  \* "TC"
UserDisconnectionCode == 21572  \* "TD"
DisconnectionInstructionCode == 21569  \* "TA"
HeartbeatResponseCode == 21577  \* "TI"
BulkQuoteDataCode == 16964  \* "BD"
GlobalCancellationCode == 18243  \* "GC"
UserGlobalCancellationCode == 18266  \* "GZ"
DirectedRoutedOrderRejectionAndQuoteCode == 19281  \* "KQ"
AuctionEntryCode == 20289  \* "OA"
DirectedOrderAcceptationCode == 20292  \* "OD"
OrderEntryCode == 20293  \* "OE"
ImprovementOrderEntryCode == 20297  \* "OI"
OrderModificationCode == 20301  \* "OM"
NewComplexOrderInstrumentCode == 20302  \* "ON"
ComplexOrderAuctionEntryCode == 20308  \* "OT"
BulkQuoteCode == 20816  \* "QP"
ExecutingParticipantConnectionCode == 21061  \* "RE"
ExecutingParticipantDisconnectionCode == 21062  \* "RF"
MarketMakerProtectionSubscriptionCode == 21072  \* "RP"
RequestForQuoteCode == 21073  \* "RQ"
OrderCancellationCode == 22597  \* "XE"
ImprovementOrderCancellationCode == 22601  \* "XI"

FirmMessage ==
    [ tag : {UserConnectionCode}, body : UserConnection ]
        \cup [ tag : {UserDisconnectionCode}, body : UserDisconnection ]
        \cup [ tag : {DisconnectionInstructionCode}, body : DisconnectionInstruction ]
        \cup [ tag : {HeartbeatResponseCode}, body : HeartbeatResponse ]
        \cup [ tag : {BulkQuoteDataCode}, body : BulkQuoteData ]
        \cup [ tag : {GlobalCancellationCode}, body : GlobalCancellation ]
        \cup [ tag : {UserGlobalCancellationCode}, body : UserGlobalCancellation ]
        \cup [ tag : {DirectedRoutedOrderRejectionAndQuoteCode}, body : DirectedRoutedOrderRejectionAndQuote ]
        \cup [ tag : {AuctionEntryCode}, body : AuctionEntry ]
        \cup [ tag : {DirectedOrderAcceptationCode}, body : DirectedOrderAcceptation ]
        \cup [ tag : {OrderEntryCode}, body : OrderEntry ]
        \cup [ tag : {ImprovementOrderEntryCode}, body : ImprovementOrderEntry ]
        \cup [ tag : {OrderModificationCode}, body : OrderModification ]
        \cup [ tag : {NewComplexOrderInstrumentCode}, body : NewComplexOrderInstrument ]
        \cup [ tag : {ComplexOrderAuctionEntryCode}, body : ComplexOrderAuctionEntry ]
        \cup [ tag : {BulkQuoteCode}, body : BulkQuote ]
        \cup [ tag : {ExecutingParticipantConnectionCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ExecutingParticipantDisconnectionCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {MarketMakerProtectionSubscriptionCode}, body : MarketMakerProtectionSubscription ]
        \cup [ tag : {RequestForQuoteCode}, body : RequestForQuote ]
        \cup [ tag : {OrderCancellationCode}, body : OrderCancellation ]
        \cup [ tag : {ImprovementOrderCancellationCode}, body : ImprovementOrderCancellation ]

EncodeFirmMessage(message) ==
    CASE message.tag = UserConnectionCode -> EncodeUserConnection(message.body)
      [] message.tag = UserDisconnectionCode -> EncodeUserDisconnection(message.body)
      [] message.tag = DisconnectionInstructionCode -> EncodeDisconnectionInstruction(message.body)
      [] message.tag = HeartbeatResponseCode -> EncodeHeartbeatResponse(message.body)
      [] message.tag = BulkQuoteDataCode -> EncodeBulkQuoteData(message.body)
      [] message.tag = GlobalCancellationCode -> EncodeGlobalCancellation(message.body)
      [] message.tag = UserGlobalCancellationCode -> EncodeUserGlobalCancellation(message.body)
      [] message.tag = DirectedRoutedOrderRejectionAndQuoteCode -> EncodeDirectedRoutedOrderRejectionAndQuote(message.body)
      [] message.tag = AuctionEntryCode -> EncodeAuctionEntry(message.body)
      [] message.tag = DirectedOrderAcceptationCode -> EncodeDirectedOrderAcceptation(message.body)
      [] message.tag = OrderEntryCode -> EncodeOrderEntry(message.body)
      [] message.tag = ImprovementOrderEntryCode -> EncodeImprovementOrderEntry(message.body)
      [] message.tag = OrderModificationCode -> EncodeOrderModification(message.body)
      [] message.tag = NewComplexOrderInstrumentCode -> EncodeNewComplexOrderInstrument(message.body)
      [] message.tag = ComplexOrderAuctionEntryCode -> EncodeComplexOrderAuctionEntry(message.body)
      [] message.tag = BulkQuoteCode -> EncodeBulkQuote(message.body)
      [] message.tag = ExecutingParticipantConnectionCode -> << >>
      [] message.tag = ExecutingParticipantDisconnectionCode -> << >>
      [] message.tag = MarketMakerProtectionSubscriptionCode -> EncodeMarketMakerProtectionSubscription(message.body)
      [] message.tag = RequestForQuoteCode -> EncodeRequestForQuote(message.body)
      [] message.tag = OrderCancellationCode -> EncodeOrderCancellation(message.body)
      [] message.tag = ImprovementOrderCancellationCode -> EncodeImprovementOrderCancellation(message.body)

DecodeFirmMessage(tag, bytes) ==
    LET read ==
            CASE tag = UserConnectionCode -> DecodeUserConnection(bytes)
              [] tag = UserDisconnectionCode -> DecodeUserDisconnection(bytes)
              [] tag = DisconnectionInstructionCode -> DecodeDisconnectionInstruction(bytes)
              [] tag = HeartbeatResponseCode -> DecodeHeartbeatResponse(bytes)
              [] tag = BulkQuoteDataCode -> DecodeBulkQuoteData(bytes)
              [] tag = GlobalCancellationCode -> DecodeGlobalCancellation(bytes)
              [] tag = UserGlobalCancellationCode -> DecodeUserGlobalCancellation(bytes)
              [] tag = DirectedRoutedOrderRejectionAndQuoteCode -> DecodeDirectedRoutedOrderRejectionAndQuote(bytes)
              [] tag = AuctionEntryCode -> DecodeAuctionEntry(bytes)
              [] tag = DirectedOrderAcceptationCode -> DecodeDirectedOrderAcceptation(bytes)
              [] tag = OrderEntryCode -> DecodeOrderEntry(bytes)
              [] tag = ImprovementOrderEntryCode -> DecodeImprovementOrderEntry(bytes)
              [] tag = OrderModificationCode -> DecodeOrderModification(bytes)
              [] tag = NewComplexOrderInstrumentCode -> DecodeNewComplexOrderInstrument(bytes)
              [] tag = ComplexOrderAuctionEntryCode -> DecodeComplexOrderAuctionEntry(bytes)
              [] tag = BulkQuoteCode -> DecodeBulkQuote(bytes)
              [] tag = ExecutingParticipantConnectionCode -> Ok([empty |-> 0], bytes)
              [] tag = ExecutingParticipantDisconnectionCode -> Ok([empty |-> 0], bytes)
              [] tag = MarketMakerProtectionSubscriptionCode -> DecodeMarketMakerProtectionSubscription(bytes)
              [] tag = RequestForQuoteCode -> DecodeRequestForQuote(bytes)
              [] tag = OrderCancellationCode -> DecodeOrderCancellation(bytes)
              [] tag = ImprovementOrderCancellationCode -> DecodeImprovementOrderCancellation(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroFirmMessage == [tag |-> UserConnectionCode, body |-> ZeroUserConnection]

(* Each Firm Message in turn, at the values the message it names is checked at *)
CheckedFirmMessage ==
    { [tag |-> UserConnectionCode, body |-> one] : one \in CheckedUserConnection }
        \cup { [tag |-> UserDisconnectionCode, body |-> one] : one \in CheckedUserDisconnection }
        \cup { [tag |-> DisconnectionInstructionCode, body |-> one] : one \in CheckedDisconnectionInstruction }
        \cup { [tag |-> HeartbeatResponseCode, body |-> one] : one \in CheckedHeartbeatResponse }
        \cup { [tag |-> BulkQuoteDataCode, body |-> one] : one \in CheckedBulkQuoteData }
        \cup { [tag |-> GlobalCancellationCode, body |-> one] : one \in CheckedGlobalCancellation }
        \cup { [tag |-> UserGlobalCancellationCode, body |-> one] : one \in CheckedUserGlobalCancellation }
        \cup { [tag |-> DirectedRoutedOrderRejectionAndQuoteCode, body |-> one] : one \in CheckedDirectedRoutedOrderRejectionAndQuote }
        \cup { [tag |-> AuctionEntryCode, body |-> one] : one \in CheckedAuctionEntry }
        \cup { [tag |-> DirectedOrderAcceptationCode, body |-> one] : one \in CheckedDirectedOrderAcceptation }
        \cup { [tag |-> OrderEntryCode, body |-> one] : one \in CheckedOrderEntry }
        \cup { [tag |-> ImprovementOrderEntryCode, body |-> one] : one \in CheckedImprovementOrderEntry }
        \cup { [tag |-> OrderModificationCode, body |-> one] : one \in CheckedOrderModification }
        \cup { [tag |-> NewComplexOrderInstrumentCode, body |-> one] : one \in CheckedNewComplexOrderInstrument }
        \cup { [tag |-> ComplexOrderAuctionEntryCode, body |-> one] : one \in CheckedComplexOrderAuctionEntry }
        \cup { [tag |-> BulkQuoteCode, body |-> one] : one \in CheckedBulkQuote }
        \cup { [tag |-> ExecutingParticipantConnectionCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> ExecutingParticipantDisconnectionCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> MarketMakerProtectionSubscriptionCode, body |-> one] : one \in CheckedMarketMakerProtectionSubscription }
        \cup { [tag |-> RequestForQuoteCode, body |-> one] : one \in CheckedRequestForQuote }
        \cup { [tag |-> OrderCancellationCode, body |-> one] : one \in CheckedOrderCancellation }
        \cup { [tag |-> ImprovementOrderCancellationCode, body |-> one] : one \in CheckedImprovementOrderCancellation }

(***************************************************************************)
(* Firm Packet                                                             *)
(***************************************************************************)

FirmPacket ==
    [ messageLength  : 0 .. 255,
      userTime       : Sample(6),
      traderId       : Sample(8),
      userSequenceId : Sample(8),
      firmMessage    : FirmMessage,
      endOfText      : Sample(1) ]

EncodeFirmPacket(message) ==
    EncodeUIntLE(message.messageLength, 4)
        \o EncodeUIntBE(message.firmMessage.tag, 2)
        \o message.userTime
        \o message.traderId
        \o message.userSequenceId
        \o EncodeFirmMessage(message.firmMessage)
        \o message.endOfText

DecodeFirmPacket(bytes) ==
    LET messageLength == ReadUIntLE(bytes, 4) IN IF ~messageLength.ok THEN Fail ELSE
    LET messageType == ReadUIntBE(messageLength.rest, 2) IN IF ~messageType.ok THEN Fail ELSE
    LET userTime == ReadBytes(messageType.rest, 6) IN IF ~userTime.ok THEN Fail ELSE
    LET traderId == ReadBytes(userTime.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(traderId.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    LET firmMessage == DecodeFirmMessage(messageType.value, userSequenceId.rest) IN IF ~firmMessage.ok THEN Fail ELSE
    LET endOfText == ReadBytes(firmMessage.rest, 1) IN IF ~endOfText.ok THEN Fail ELSE
    Ok([ messageLength  |-> messageLength.value,
         userTime       |-> userTime.value,
         traderId       |-> traderId.value,
         userSequenceId |-> userSequenceId.value,
         firmMessage    |-> firmMessage.value,
         endOfText      |-> endOfText.value ], endOfText.rest)

ZeroFirmPacket ==
    [ messageLength  |-> 0,
      userTime       |-> [i \in 1 .. 6 |-> 0],
      traderId       |-> [i \in 1 .. 8 |-> 0],
      userSequenceId |-> [i \in 1 .. 8 |-> 0],
      firmMessage    |-> ZeroFirmMessage,
      endOfText      |-> [i \in 1 .. 1 |-> 0] ]

(* Firm Packet at zero, then each field in turn at the values it is checked at *)
CheckedFirmPacket ==
    { ZeroFirmPacket }
        \cup { [ZeroFirmPacket EXCEPT !.messageLength = one] : one \in {0, 1, 255} }
        \cup { [ZeroFirmPacket EXCEPT !.userTime = one] : one \in Sample(6) }
        \cup { [ZeroFirmPacket EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroFirmPacket EXCEPT !.userSequenceId = one] : one \in Sample(8) }
        \cup { [ZeroFirmPacket EXCEPT !.firmMessage = one] : one \in CheckedFirmMessage }
        \cup { [ZeroFirmPacket EXCEPT !.endOfText = one] : one \in Sample(1) }

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

(* Every User Connection Occurrence decodes back to what was encoded, and leaves nothing over *)
RoundTripUserConnectionOccurrence ==
    \A message \in CheckedUserConnectionOccurrence :
        LET read == DecodeUserConnectionOccurrence(EncodeUserConnectionOccurrence(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every User Connection decodes back to what was encoded, and leaves nothing over *)
RoundTripUserConnection ==
    \A message \in CheckedUserConnection :
        LET read == DecodeUserConnection(EncodeUserConnection(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every User Disconnection decodes back to what was encoded, and leaves nothing over *)
RoundTripUserDisconnection ==
    \A message \in CheckedUserDisconnection :
        LET read == DecodeUserDisconnection(EncodeUserDisconnection(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Disconnection Instruction Occurrence decodes back to what was encoded, and leaves nothing over *)
RoundTripDisconnectionInstructionOccurrence ==
    \A message \in CheckedDisconnectionInstructionOccurrence :
        LET read == DecodeDisconnectionInstructionOccurrence(EncodeDisconnectionInstructionOccurrence(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Disconnection Instruction decodes back to what was encoded, and leaves nothing over *)
RoundTripDisconnectionInstruction ==
    \A message \in CheckedDisconnectionInstruction :
        LET read == DecodeDisconnectionInstruction(EncodeDisconnectionInstruction(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Heartbeat Response decodes back to what was encoded, and leaves nothing over *)
RoundTripHeartbeatResponse ==
    \A message \in CheckedHeartbeatResponse :
        LET read == DecodeHeartbeatResponse(EncodeHeartbeatResponse(message))
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

(* Every Bulk Quote Data decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkQuoteData ==
    \A message \in CheckedBulkQuoteData :
        LET read == DecodeBulkQuoteData(EncodeBulkQuoteData(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Global Cancellation decodes back to what was encoded, and leaves nothing over *)
RoundTripGlobalCancellation ==
    \A message \in CheckedGlobalCancellation :
        LET read == DecodeGlobalCancellation(EncodeGlobalCancellation(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every User Global Cancellation decodes back to what was encoded, and leaves nothing over *)
RoundTripUserGlobalCancellation ==
    \A message \in CheckedUserGlobalCancellation :
        LET read == DecodeUserGlobalCancellation(EncodeUserGlobalCancellation(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Directed Routed Order Rejection And Quote decodes back to what was encoded, and leaves nothing over *)
RoundTripDirectedRoutedOrderRejectionAndQuote ==
    \A message \in CheckedDirectedRoutedOrderRejectionAndQuote :
        LET read == DecodeDirectedRoutedOrderRejectionAndQuote(EncodeDirectedRoutedOrderRejectionAndQuote(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Buying Clearing Data decodes back to what was encoded, and leaves nothing over *)
RoundTripBuyingClearingData ==
    \A message \in CheckedBuyingClearingData :
        LET read == DecodeBuyingClearingData(EncodeBuyingClearingData(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Selling Clearing Data decodes back to what was encoded, and leaves nothing over *)
RoundTripSellingClearingData ==
    \A message \in CheckedSellingClearingData :
        LET read == DecodeSellingClearingData(EncodeSellingClearingData(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Buying Owner Data decodes back to what was encoded, and leaves nothing over *)
RoundTripBuyingOwnerData ==
    \A message \in CheckedBuyingOwnerData :
        LET read == DecodeBuyingOwnerData(EncodeBuyingOwnerData(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Selling Owner Data decodes back to what was encoded, and leaves nothing over *)
RoundTripSellingOwnerData ==
    \A message \in CheckedSellingOwnerData :
        LET read == DecodeSellingOwnerData(EncodeSellingOwnerData(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Entry decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionEntry ==
    \A message \in CheckedAuctionEntry :
        LET read == DecodeAuctionEntry(EncodeAuctionEntry(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Clearing Data Dealer decodes back to what was encoded, and leaves nothing over *)
RoundTripClearingDataDealer ==
    \A message \in CheckedClearingDataDealer :
        LET read == DecodeClearingDataDealer(EncodeClearingDataDealer(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Owner Data Dealer decodes back to what was encoded, and leaves nothing over *)
RoundTripOwnerDataDealer ==
    \A message \in CheckedOwnerDataDealer :
        LET read == DecodeOwnerDataDealer(EncodeOwnerDataDealer(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Directed Order Acceptation decodes back to what was encoded, and leaves nothing over *)
RoundTripDirectedOrderAcceptation ==
    \A message \in CheckedDirectedOrderAcceptation :
        LET read == DecodeDirectedOrderAcceptation(EncodeDirectedOrderAcceptation(message))
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

(* Every Order Entry decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderEntry ==
    \A message \in CheckedOrderEntry :
        LET read == DecodeOrderEntry(EncodeOrderEntry(message))
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

(* Every Improvement Order Entry decodes back to what was encoded, and leaves nothing over *)
RoundTripImprovementOrderEntry ==
    \A message \in CheckedImprovementOrderEntry :
        LET read == DecodeImprovementOrderEntry(EncodeImprovementOrderEntry(message))
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

(* Every Order Modification decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderModification ==
    \A message \in CheckedOrderModification :
        LET read == DecodeOrderModification(EncodeOrderModification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Complex Order Instrument Occurrence decodes back to what was encoded, and leaves nothing over *)
RoundTripNewComplexOrderInstrumentOccurrence ==
    \A message \in CheckedNewComplexOrderInstrumentOccurrence :
        LET read == DecodeNewComplexOrderInstrumentOccurrence(EncodeNewComplexOrderInstrumentOccurrence(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Complex Order Instrument decodes back to what was encoded, and leaves nothing over *)
RoundTripNewComplexOrderInstrument ==
    \A message \in CheckedNewComplexOrderInstrument :
        LET read == DecodeNewComplexOrderInstrument(EncodeNewComplexOrderInstrument(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Buying Clearing Data decodes back to what was encoded, and leaves nothing over *)
RoundTripBuyingClearingData2 ==
    \A message \in CheckedBuyingClearingData2 :
        LET read == DecodeBuyingClearingData2(EncodeBuyingClearingData2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Selling Clearing Data decodes back to what was encoded, and leaves nothing over *)
RoundTripSellingClearingData2 ==
    \A message \in CheckedSellingClearingData2 :
        LET read == DecodeSellingClearingData2(EncodeSellingClearingData2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Buying Owner Data decodes back to what was encoded, and leaves nothing over *)
RoundTripBuyingOwnerData2 ==
    \A message \in CheckedBuyingOwnerData2 :
        LET read == DecodeBuyingOwnerData2(EncodeBuyingOwnerData2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Selling Owner Data decodes back to what was encoded, and leaves nothing over *)
RoundTripSellingOwnerData2 ==
    \A message \in CheckedSellingOwnerData2 :
        LET read == DecodeSellingOwnerData2(EncodeSellingOwnerData2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Order Auction Entry Occurrence decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexOrderAuctionEntryOccurrence ==
    \A message \in CheckedComplexOrderAuctionEntryOccurrence :
        LET read == DecodeComplexOrderAuctionEntryOccurrence(EncodeComplexOrderAuctionEntryOccurrence(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Order Auction Entry decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexOrderAuctionEntry ==
    \A message \in CheckedComplexOrderAuctionEntry :
        LET read == DecodeComplexOrderAuctionEntry(EncodeComplexOrderAuctionEntry(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulk Quote Occurrence decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkQuoteOccurrence ==
    \A message \in CheckedBulkQuoteOccurrence :
        LET read == DecodeBulkQuoteOccurrence(EncodeBulkQuoteOccurrence(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulk Quote decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkQuote ==
    \A message \in CheckedBulkQuote :
        LET read == DecodeBulkQuote(EncodeBulkQuote(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Maker Protection Subscription decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketMakerProtectionSubscription ==
    \A message \in CheckedMarketMakerProtectionSubscription :
        LET read == DecodeMarketMakerProtectionSubscription(EncodeMarketMakerProtectionSubscription(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request For Quote decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestForQuote ==
    \A message \in CheckedRequestForQuote :
        LET read == DecodeRequestForQuote(EncodeRequestForQuote(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancellation decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancellation ==
    \A message \in CheckedOrderCancellation :
        LET read == DecodeOrderCancellation(EncodeOrderCancellation(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Improvement Order Cancellation decodes back to what was encoded, and leaves nothing over *)
RoundTripImprovementOrderCancellation ==
    \A message \in CheckedImprovementOrderCancellation :
        LET read == DecodeImprovementOrderCancellation(EncodeImprovementOrderCancellation(message))
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

(* A Firm Message is selected by the Message Type it is written under *)
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
