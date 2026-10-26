------------------- MODULE Mx_SolaOrderEntry_v1_21_Firm --------------------
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
    [ protocolId                      : Sample(2),
      userId                          : Sample(8),
      passwordMd5Encryption           : Sample(8),
      sessionId                       : Sample(4),
      userMessageTimestampLocalHhmmss : Sample(6),
      exchangeMessageId               : Sample(6),
      inactivityInterval              : Sample(2),
      userConnectionOccurrence        : SampleLists(OneUserConnectionOccurrence) ]

EncodeUserConnection(message) ==
    message.protocolId
        \o message.userId
        \o message.passwordMd5Encryption
        \o message.sessionId
        \o message.userMessageTimestampLocalHhmmss
        \o message.exchangeMessageId
        \o message.inactivityInterval
        \o EncodeDigits(Len(message.userConnectionOccurrence), 2)
        \o EncodeUserConnectionOccurrenceList(message.userConnectionOccurrence)

DecodeUserConnection(bytes) ==
    LET protocolId == ReadBytes(bytes, 2) IN IF ~protocolId.ok THEN Fail ELSE
    LET userId == ReadBytes(protocolId.rest, 8) IN IF ~userId.ok THEN Fail ELSE
    LET passwordMd5Encryption == ReadBytes(userId.rest, 8) IN IF ~passwordMd5Encryption.ok THEN Fail ELSE
    LET sessionId == ReadBytes(passwordMd5Encryption.rest, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET userMessageTimestampLocalHhmmss == ReadBytes(sessionId.rest, 6) IN IF ~userMessageTimestampLocalHhmmss.ok THEN Fail ELSE
    LET exchangeMessageId == ReadBytes(userMessageTimestampLocalHhmmss.rest, 6) IN IF ~exchangeMessageId.ok THEN Fail ELSE
    LET inactivityInterval == ReadBytes(exchangeMessageId.rest, 2) IN IF ~inactivityInterval.ok THEN Fail ELSE
    LET numberOfMessageTypesToBeReceived == ReadDigits(inactivityInterval.rest, 2) IN IF ~numberOfMessageTypesToBeReceived.ok THEN Fail ELSE
    LET userConnectionOccurrence == ReadUserConnectionOccurrenceList(numberOfMessageTypesToBeReceived.rest, numberOfMessageTypesToBeReceived.value) IN IF ~userConnectionOccurrence.ok THEN Fail ELSE
    Ok([ protocolId                      |-> protocolId.value,
         userId                          |-> userId.value,
         passwordMd5Encryption           |-> passwordMd5Encryption.value,
         sessionId                       |-> sessionId.value,
         userMessageTimestampLocalHhmmss |-> userMessageTimestampLocalHhmmss.value,
         exchangeMessageId               |-> exchangeMessageId.value,
         inactivityInterval              |-> inactivityInterval.value,
         userConnectionOccurrence        |-> userConnectionOccurrence.value ], userConnectionOccurrence.rest)

ZeroUserConnection ==
    [ protocolId                      |-> [i \in 1 .. 2 |-> 0],
      userId                          |-> [i \in 1 .. 8 |-> 0],
      passwordMd5Encryption           |-> [i \in 1 .. 8 |-> 0],
      sessionId                       |-> [i \in 1 .. 4 |-> 0],
      userMessageTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      exchangeMessageId               |-> [i \in 1 .. 6 |-> 0],
      inactivityInterval              |-> [i \in 1 .. 2 |-> 0],
      userConnectionOccurrence        |-> << >> ]

(* User Connection at zero, then each field in turn at the values it is checked at *)
CheckedUserConnection ==
    { ZeroUserConnection }
        \cup { [ZeroUserConnection EXCEPT !.protocolId = one] : one \in Sample(2) }
        \cup { [ZeroUserConnection EXCEPT !.userId = one] : one \in Sample(8) }
        \cup { [ZeroUserConnection EXCEPT !.passwordMd5Encryption = one] : one \in Sample(8) }
        \cup { [ZeroUserConnection EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroUserConnection EXCEPT !.userMessageTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroUserConnection EXCEPT !.exchangeMessageId = one] : one \in Sample(6) }
        \cup { [ZeroUserConnection EXCEPT !.inactivityInterval = one] : one \in Sample(2) }
        \cup { [ZeroUserConnection EXCEPT !.userConnectionOccurrence = one] : one \in SampleLists(OneUserConnectionOccurrence) }

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
    [ userSequenceIdFirstUserSequenceIdForNextcurrentHeartbeatPeriod : Sample(8),
      lastExchangeMessageIdSentToParticipant                         : Sample(6),
      userMessageTimestampLocalHhmmss                                : Sample(6) ]

EncodeHeartbeatResponse(message) ==
    message.userSequenceIdFirstUserSequenceIdForNextcurrentHeartbeatPeriod
        \o message.lastExchangeMessageIdSentToParticipant
        \o message.userMessageTimestampLocalHhmmss

DecodeHeartbeatResponse(bytes) ==
    LET userSequenceIdFirstUserSequenceIdForNextcurrentHeartbeatPeriod == ReadBytes(bytes, 8) IN IF ~userSequenceIdFirstUserSequenceIdForNextcurrentHeartbeatPeriod.ok THEN Fail ELSE
    LET lastExchangeMessageIdSentToParticipant == ReadBytes(userSequenceIdFirstUserSequenceIdForNextcurrentHeartbeatPeriod.rest, 6) IN IF ~lastExchangeMessageIdSentToParticipant.ok THEN Fail ELSE
    LET userMessageTimestampLocalHhmmss == ReadBytes(lastExchangeMessageIdSentToParticipant.rest, 6) IN IF ~userMessageTimestampLocalHhmmss.ok THEN Fail ELSE
    Ok([ userSequenceIdFirstUserSequenceIdForNextcurrentHeartbeatPeriod |-> userSequenceIdFirstUserSequenceIdForNextcurrentHeartbeatPeriod.value,
         lastExchangeMessageIdSentToParticipant                         |-> lastExchangeMessageIdSentToParticipant.value,
         userMessageTimestampLocalHhmmss                                |-> userMessageTimestampLocalHhmmss.value ], userMessageTimestampLocalHhmmss.rest)

ZeroHeartbeatResponse ==
    [ userSequenceIdFirstUserSequenceIdForNextcurrentHeartbeatPeriod |-> [i \in 1 .. 8 |-> 0],
      lastExchangeMessageIdSentToParticipant                         |-> [i \in 1 .. 6 |-> 0],
      userMessageTimestampLocalHhmmss                                |-> [i \in 1 .. 6 |-> 0] ]

(* Heartbeat Response at zero, then each field in turn at the values it is checked at *)
CheckedHeartbeatResponse ==
    { ZeroHeartbeatResponse }
        \cup { [ZeroHeartbeatResponse EXCEPT !.userSequenceIdFirstUserSequenceIdForNextcurrentHeartbeatPeriod = one] : one \in Sample(8) }
        \cup { [ZeroHeartbeatResponse EXCEPT !.lastExchangeMessageIdSentToParticipant = one] : one \in Sample(6) }
        \cup { [ZeroHeartbeatResponse EXCEPT !.userMessageTimestampLocalHhmmss = one] : one \in Sample(6) }

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
(* Incoming Messages Header: 22 bytes                                      *)
(***************************************************************************)

IncomingMessagesHeader ==
    [ userTimestampLocalHhmmss : Sample(6),
      traderId                 : Sample(8),
      userSequenceId           : Sample(8) ]

EncodeIncomingMessagesHeader(message) ==
    message.userTimestampLocalHhmmss
        \o message.traderId
        \o message.userSequenceId

DecodeIncomingMessagesHeader(bytes) ==
    LET userTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~userTimestampLocalHhmmss.ok THEN Fail ELSE
    LET traderId == ReadBytes(userTimestampLocalHhmmss.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(traderId.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    Ok([ userTimestampLocalHhmmss |-> userTimestampLocalHhmmss.value,
         traderId                 |-> traderId.value,
         userSequenceId           |-> userSequenceId.value ], userSequenceId.rest)

ZeroIncomingMessagesHeader ==
    [ userTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      traderId                 |-> [i \in 1 .. 8 |-> 0],
      userSequenceId           |-> [i \in 1 .. 8 |-> 0] ]

(* Incoming Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedIncomingMessagesHeader ==
    { ZeroIncomingMessagesHeader }
        \cup { [ZeroIncomingMessagesHeader EXCEPT !.userTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroIncomingMessagesHeader EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroIncomingMessagesHeader EXCEPT !.userSequenceId = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Request: 22 bytes                                                 *)
(***************************************************************************)

OrderRequest ==
    [ incomingMessagesHeader : IncomingMessagesHeader ]

EncodeOrderRequest(message) ==
    EncodeIncomingMessagesHeader(message.incomingMessagesHeader)

DecodeOrderRequest(bytes) ==
    LET incomingMessagesHeader == DecodeIncomingMessagesHeader(bytes) IN IF ~incomingMessagesHeader.ok THEN Fail ELSE
    Ok([ incomingMessagesHeader |-> incomingMessagesHeader.value ], incomingMessagesHeader.rest)

ZeroOrderRequest ==
    [ incomingMessagesHeader |-> ZeroIncomingMessagesHeader ]

(* Order Request at zero, then each field in turn at the values it is checked at *)
CheckedOrderRequest ==
    { ZeroOrderRequest }
        \cup { [ZeroOrderRequest EXCEPT !.incomingMessagesHeader = one] : one \in CheckedIncomingMessagesHeader }

(***************************************************************************)
(* Incoming Messages Header: 22 bytes                                      *)
(***************************************************************************)

IncomingMessagesHeader2 ==
    [ userTimestampLocalHhmmss : Sample(6),
      traderId                 : Sample(8),
      userSequenceId           : Sample(8) ]

EncodeIncomingMessagesHeader2(message) ==
    message.userTimestampLocalHhmmss
        \o message.traderId
        \o message.userSequenceId

DecodeIncomingMessagesHeader2(bytes) ==
    LET userTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~userTimestampLocalHhmmss.ok THEN Fail ELSE
    LET traderId == ReadBytes(userTimestampLocalHhmmss.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(traderId.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    Ok([ userTimestampLocalHhmmss |-> userTimestampLocalHhmmss.value,
         traderId                 |-> traderId.value,
         userSequenceId           |-> userSequenceId.value ], userSequenceId.rest)

ZeroIncomingMessagesHeader2 ==
    [ userTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      traderId                 |-> [i \in 1 .. 8 |-> 0],
      userSequenceId           |-> [i \in 1 .. 8 |-> 0] ]

(* Incoming Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedIncomingMessagesHeader2 ==
    { ZeroIncomingMessagesHeader2 }
        \cup { [ZeroIncomingMessagesHeader2 EXCEPT !.userTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroIncomingMessagesHeader2 EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroIncomingMessagesHeader2 EXCEPT !.userSequenceId = one] : one \in Sample(8) }

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
(* Bulk Quote Data: 174 bytes                                              *)
(***************************************************************************)

BulkQuoteData ==
    [ incomingMessagesHeader  : IncomingMessagesHeader2,
      group                   : Sample(2),
      clearingData            : ClearingData,
      ownerData               : OwnerData,
      maximumNumberTrades     : Sample(2),
      minimumVolume           : Sample(8),
      filler2                 : Sample(2),
      calculationTimeInterval : Sample(8),
      maximumTotalVolume      : Sample(8),
      maximumTotalValue       : Sample(8),
      deltaMaximumVolume      : Sample(8),
      deltaMaximumValue       : Sample(8),
      antiWashId              : Sample(8),
      filler20                : Sample(20) ]

EncodeBulkQuoteData(message) ==
    EncodeIncomingMessagesHeader2(message.incomingMessagesHeader)
        \o message.group
        \o EncodeClearingData(message.clearingData)
        \o EncodeOwnerData(message.ownerData)
        \o message.maximumNumberTrades
        \o message.minimumVolume
        \o message.filler2
        \o message.calculationTimeInterval
        \o message.maximumTotalVolume
        \o message.maximumTotalValue
        \o message.deltaMaximumVolume
        \o message.deltaMaximumValue
        \o message.antiWashId
        \o message.filler20

DecodeBulkQuoteData(bytes) ==
    LET incomingMessagesHeader == DecodeIncomingMessagesHeader2(bytes) IN IF ~incomingMessagesHeader.ok THEN Fail ELSE
    LET group == ReadBytes(incomingMessagesHeader.rest, 2) IN IF ~group.ok THEN Fail ELSE
    LET clearingData == DecodeClearingData(group.rest) IN IF ~clearingData.ok THEN Fail ELSE
    LET ownerData == DecodeOwnerData(clearingData.rest) IN IF ~ownerData.ok THEN Fail ELSE
    LET maximumNumberTrades == ReadBytes(ownerData.rest, 2) IN IF ~maximumNumberTrades.ok THEN Fail ELSE
    LET minimumVolume == ReadBytes(maximumNumberTrades.rest, 8) IN IF ~minimumVolume.ok THEN Fail ELSE
    LET filler2 == ReadBytes(minimumVolume.rest, 2) IN IF ~filler2.ok THEN Fail ELSE
    LET calculationTimeInterval == ReadBytes(filler2.rest, 8) IN IF ~calculationTimeInterval.ok THEN Fail ELSE
    LET maximumTotalVolume == ReadBytes(calculationTimeInterval.rest, 8) IN IF ~maximumTotalVolume.ok THEN Fail ELSE
    LET maximumTotalValue == ReadBytes(maximumTotalVolume.rest, 8) IN IF ~maximumTotalValue.ok THEN Fail ELSE
    LET deltaMaximumVolume == ReadBytes(maximumTotalValue.rest, 8) IN IF ~deltaMaximumVolume.ok THEN Fail ELSE
    LET deltaMaximumValue == ReadBytes(deltaMaximumVolume.rest, 8) IN IF ~deltaMaximumValue.ok THEN Fail ELSE
    LET antiWashId == ReadBytes(deltaMaximumValue.rest, 8) IN IF ~antiWashId.ok THEN Fail ELSE
    LET filler20 == ReadBytes(antiWashId.rest, 20) IN IF ~filler20.ok THEN Fail ELSE
    Ok([ incomingMessagesHeader  |-> incomingMessagesHeader.value,
         group                   |-> group.value,
         clearingData            |-> clearingData.value,
         ownerData               |-> ownerData.value,
         maximumNumberTrades     |-> maximumNumberTrades.value,
         minimumVolume           |-> minimumVolume.value,
         filler2                 |-> filler2.value,
         calculationTimeInterval |-> calculationTimeInterval.value,
         maximumTotalVolume      |-> maximumTotalVolume.value,
         maximumTotalValue       |-> maximumTotalValue.value,
         deltaMaximumVolume      |-> deltaMaximumVolume.value,
         deltaMaximumValue       |-> deltaMaximumValue.value,
         antiWashId              |-> antiWashId.value,
         filler20                |-> filler20.value ], filler20.rest)

ZeroBulkQuoteData ==
    [ incomingMessagesHeader  |-> ZeroIncomingMessagesHeader2,
      group                   |-> [i \in 1 .. 2 |-> 0],
      clearingData            |-> ZeroClearingData,
      ownerData               |-> ZeroOwnerData,
      maximumNumberTrades     |-> [i \in 1 .. 2 |-> 0],
      minimumVolume           |-> [i \in 1 .. 8 |-> 0],
      filler2                 |-> [i \in 1 .. 2 |-> 0],
      calculationTimeInterval |-> [i \in 1 .. 8 |-> 0],
      maximumTotalVolume      |-> [i \in 1 .. 8 |-> 0],
      maximumTotalValue       |-> [i \in 1 .. 8 |-> 0],
      deltaMaximumVolume      |-> [i \in 1 .. 8 |-> 0],
      deltaMaximumValue       |-> [i \in 1 .. 8 |-> 0],
      antiWashId              |-> [i \in 1 .. 8 |-> 0],
      filler20                |-> [i \in 1 .. 20 |-> 0] ]

(* Bulk Quote Data at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuoteData ==
    { ZeroBulkQuoteData }
        \cup { [ZeroBulkQuoteData EXCEPT !.incomingMessagesHeader = one] : one \in CheckedIncomingMessagesHeader2 }
        \cup { [ZeroBulkQuoteData EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuoteData EXCEPT !.clearingData = one] : one \in CheckedClearingData }
        \cup { [ZeroBulkQuoteData EXCEPT !.ownerData = one] : one \in CheckedOwnerData }
        \cup { [ZeroBulkQuoteData EXCEPT !.maximumNumberTrades = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuoteData EXCEPT !.minimumVolume = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuoteData EXCEPT !.filler2 = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuoteData EXCEPT !.calculationTimeInterval = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuoteData EXCEPT !.maximumTotalVolume = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuoteData EXCEPT !.maximumTotalValue = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuoteData EXCEPT !.deltaMaximumVolume = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuoteData EXCEPT !.deltaMaximumValue = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuoteData EXCEPT !.antiWashId = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuoteData EXCEPT !.filler20 = one] : one \in Sample(20) }

(***************************************************************************)
(* Incoming Messages Header: 22 bytes                                      *)
(***************************************************************************)

IncomingMessagesHeader3 ==
    [ userTimestampLocalHhmmss : Sample(6),
      traderId                 : Sample(8),
      userSequenceId           : Sample(8) ]

EncodeIncomingMessagesHeader3(message) ==
    message.userTimestampLocalHhmmss
        \o message.traderId
        \o message.userSequenceId

DecodeIncomingMessagesHeader3(bytes) ==
    LET userTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~userTimestampLocalHhmmss.ok THEN Fail ELSE
    LET traderId == ReadBytes(userTimestampLocalHhmmss.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(traderId.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    Ok([ userTimestampLocalHhmmss |-> userTimestampLocalHhmmss.value,
         traderId                 |-> traderId.value,
         userSequenceId           |-> userSequenceId.value ], userSequenceId.rest)

ZeroIncomingMessagesHeader3 ==
    [ userTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      traderId                 |-> [i \in 1 .. 8 |-> 0],
      userSequenceId           |-> [i \in 1 .. 8 |-> 0] ]

(* Incoming Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedIncomingMessagesHeader3 ==
    { ZeroIncomingMessagesHeader3 }
        \cup { [ZeroIncomingMessagesHeader3 EXCEPT !.userTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroIncomingMessagesHeader3 EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroIncomingMessagesHeader3 EXCEPT !.userSequenceId = one] : one \in Sample(8) }

(***************************************************************************)
(* Firm Risk Config Trader Team Trader: 4 bytes                            *)
(***************************************************************************)

FirmRiskConfigTraderTeamTrader ==
    [ trader : Sample(4) ]

EncodeFirmRiskConfigTraderTeamTrader(message) ==
    message.trader

DecodeFirmRiskConfigTraderTeamTrader(bytes) ==
    LET trader == ReadBytes(bytes, 4) IN IF ~trader.ok THEN Fail ELSE
    Ok([ trader |-> trader.value ], trader.rest)

ZeroFirmRiskConfigTraderTeamTrader ==
    [ trader |-> [i \in 1 .. 4 |-> 0] ]

(* Firm Risk Config Trader Team Trader at zero, then each field in turn at the values it is checked at *)
CheckedFirmRiskConfigTraderTeamTrader ==
    { ZeroFirmRiskConfigTraderTeamTrader }
        \cup { [ZeroFirmRiskConfigTraderTeamTrader EXCEPT !.trader = one] : one \in Sample(4) }

(* A run of Firm Risk Config Trader Team Trader, written one after another *)
RECURSIVE EncodeFirmRiskConfigTraderTeamTraderList(_)
EncodeFirmRiskConfigTraderTeamTraderList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeFirmRiskConfigTraderTeamTrader(Head(messages)) \o EncodeFirmRiskConfigTraderTeamTraderList(Tail(messages))

(* As many Firm Risk Config Trader Team Trader as the field that counts them says *)
RECURSIVE ReadFirmRiskConfigTraderTeamTraderList(_, _)
ReadFirmRiskConfigTraderTeamTraderList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeFirmRiskConfigTraderTeamTrader(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadFirmRiskConfigTraderTeamTraderList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Firm Risk Config Trader Team Trader of each kind, for the lists that carry them *)
OneFirmRiskConfigTraderTeamTrader == { ZeroFirmRiskConfigTraderTeamTrader }

(***************************************************************************)
(* Firm Risk Config Trader Team                                            *)
(***************************************************************************)

FirmRiskConfigTraderTeam ==
    [ teamLevelRiskOption            : Sample(1),
      firmRiskConfigTraderTeamTrader : SampleLists(OneFirmRiskConfigTraderTeamTrader) ]

EncodeFirmRiskConfigTraderTeam(message) ==
    message.teamLevelRiskOption
        \o EncodeDigits(Len(message.firmRiskConfigTraderTeamTrader), 3)
        \o EncodeFirmRiskConfigTraderTeamTraderList(message.firmRiskConfigTraderTeamTrader)

DecodeFirmRiskConfigTraderTeam(bytes) ==
    LET teamLevelRiskOption == ReadBytes(bytes, 1) IN IF ~teamLevelRiskOption.ok THEN Fail ELSE
    LET numberOfTradersInTeam == ReadDigits(teamLevelRiskOption.rest, 3) IN IF ~numberOfTradersInTeam.ok THEN Fail ELSE
    LET firmRiskConfigTraderTeamTrader == ReadFirmRiskConfigTraderTeamTraderList(numberOfTradersInTeam.rest, numberOfTradersInTeam.value) IN IF ~firmRiskConfigTraderTeamTrader.ok THEN Fail ELSE
    Ok([ teamLevelRiskOption            |-> teamLevelRiskOption.value,
         firmRiskConfigTraderTeamTrader |-> firmRiskConfigTraderTeamTrader.value ], firmRiskConfigTraderTeamTrader.rest)

ZeroFirmRiskConfigTraderTeam ==
    [ teamLevelRiskOption            |-> [i \in 1 .. 1 |-> 0],
      firmRiskConfigTraderTeamTrader |-> << >> ]

(* Firm Risk Config Trader Team at zero, then each field in turn at the values it is checked at *)
CheckedFirmRiskConfigTraderTeam ==
    { ZeroFirmRiskConfigTraderTeam }
        \cup { [ZeroFirmRiskConfigTraderTeam EXCEPT !.teamLevelRiskOption = one] : one \in Sample(1) }
        \cup { [ZeroFirmRiskConfigTraderTeam EXCEPT !.firmRiskConfigTraderTeamTrader = one] : one \in SampleLists(OneFirmRiskConfigTraderTeamTrader) }

(* A run of Firm Risk Config Trader Team, written one after another *)
RECURSIVE EncodeFirmRiskConfigTraderTeamList(_)
EncodeFirmRiskConfigTraderTeamList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeFirmRiskConfigTraderTeam(Head(messages)) \o EncodeFirmRiskConfigTraderTeamList(Tail(messages))

(* As many Firm Risk Config Trader Team as the field that counts them says *)
RECURSIVE ReadFirmRiskConfigTraderTeamList(_, _)
ReadFirmRiskConfigTraderTeamList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeFirmRiskConfigTraderTeam(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadFirmRiskConfigTraderTeamList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Firm Risk Config Trader Team of each kind, for the lists that carry them *)
OneFirmRiskConfigTraderTeam == { ZeroFirmRiskConfigTraderTeam }

(***************************************************************************)
(* Firm Risk Config                                                        *)
(***************************************************************************)

FirmRiskConfig ==
    [ incomingMessagesHeader   : IncomingMessagesHeader3,
      firmLevelRiskOption      : Sample(1),
      firmRiskConfigTraderTeam : SampleLists(OneFirmRiskConfigTraderTeam) ]

EncodeFirmRiskConfig(message) ==
    EncodeIncomingMessagesHeader3(message.incomingMessagesHeader)
        \o message.firmLevelRiskOption
        \o EncodeDigits(Len(message.firmRiskConfigTraderTeam), 3)
        \o EncodeFirmRiskConfigTraderTeamList(message.firmRiskConfigTraderTeam)

DecodeFirmRiskConfig(bytes) ==
    LET incomingMessagesHeader == DecodeIncomingMessagesHeader3(bytes) IN IF ~incomingMessagesHeader.ok THEN Fail ELSE
    LET firmLevelRiskOption == ReadBytes(incomingMessagesHeader.rest, 1) IN IF ~firmLevelRiskOption.ok THEN Fail ELSE
    LET numberOfTraderTeams == ReadDigits(firmLevelRiskOption.rest, 3) IN IF ~numberOfTraderTeams.ok THEN Fail ELSE
    LET firmRiskConfigTraderTeam == ReadFirmRiskConfigTraderTeamList(numberOfTraderTeams.rest, numberOfTraderTeams.value) IN IF ~firmRiskConfigTraderTeam.ok THEN Fail ELSE
    Ok([ incomingMessagesHeader   |-> incomingMessagesHeader.value,
         firmLevelRiskOption      |-> firmLevelRiskOption.value,
         firmRiskConfigTraderTeam |-> firmRiskConfigTraderTeam.value ], firmRiskConfigTraderTeam.rest)

ZeroFirmRiskConfig ==
    [ incomingMessagesHeader   |-> ZeroIncomingMessagesHeader3,
      firmLevelRiskOption      |-> [i \in 1 .. 1 |-> 0],
      firmRiskConfigTraderTeam |-> << >> ]

(* Firm Risk Config at zero, then each field in turn at the values it is checked at *)
CheckedFirmRiskConfig ==
    { ZeroFirmRiskConfig }
        \cup { [ZeroFirmRiskConfig EXCEPT !.incomingMessagesHeader = one] : one \in CheckedIncomingMessagesHeader3 }
        \cup { [ZeroFirmRiskConfig EXCEPT !.firmLevelRiskOption = one] : one \in Sample(1) }
        \cup { [ZeroFirmRiskConfig EXCEPT !.firmRiskConfigTraderTeam = one] : one \in SampleLists(OneFirmRiskConfigTraderTeam) }

(***************************************************************************)
(* Incoming Messages Header: 22 bytes                                      *)
(***************************************************************************)

IncomingMessagesHeader4 ==
    [ userTimestampLocalHhmmss : Sample(6),
      traderId                 : Sample(8),
      userSequenceId           : Sample(8) ]

EncodeIncomingMessagesHeader4(message) ==
    message.userTimestampLocalHhmmss
        \o message.traderId
        \o message.userSequenceId

DecodeIncomingMessagesHeader4(bytes) ==
    LET userTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~userTimestampLocalHhmmss.ok THEN Fail ELSE
    LET traderId == ReadBytes(userTimestampLocalHhmmss.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(traderId.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    Ok([ userTimestampLocalHhmmss |-> userTimestampLocalHhmmss.value,
         traderId                 |-> traderId.value,
         userSequenceId           |-> userSequenceId.value ], userSequenceId.rest)

ZeroIncomingMessagesHeader4 ==
    [ userTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      traderId                 |-> [i \in 1 .. 8 |-> 0],
      userSequenceId           |-> [i \in 1 .. 8 |-> 0] ]

(* Incoming Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedIncomingMessagesHeader4 ==
    { ZeroIncomingMessagesHeader4 }
        \cup { [ZeroIncomingMessagesHeader4 EXCEPT !.userTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroIncomingMessagesHeader4 EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroIncomingMessagesHeader4 EXCEPT !.userSequenceId = one] : one \in Sample(8) }

(***************************************************************************)
(* Global Cancellation: 25 bytes                                           *)
(***************************************************************************)

GlobalCancellation ==
    [ incomingMessagesHeader        : IncomingMessagesHeader4,
      group                         : Sample(2),
      typeOfCancellationQQuotesOnly : Sample(1) ]

EncodeGlobalCancellation(message) ==
    EncodeIncomingMessagesHeader4(message.incomingMessagesHeader)
        \o message.group
        \o message.typeOfCancellationQQuotesOnly

DecodeGlobalCancellation(bytes) ==
    LET incomingMessagesHeader == DecodeIncomingMessagesHeader4(bytes) IN IF ~incomingMessagesHeader.ok THEN Fail ELSE
    LET group == ReadBytes(incomingMessagesHeader.rest, 2) IN IF ~group.ok THEN Fail ELSE
    LET typeOfCancellationQQuotesOnly == ReadBytes(group.rest, 1) IN IF ~typeOfCancellationQQuotesOnly.ok THEN Fail ELSE
    Ok([ incomingMessagesHeader        |-> incomingMessagesHeader.value,
         group                         |-> group.value,
         typeOfCancellationQQuotesOnly |-> typeOfCancellationQQuotesOnly.value ], typeOfCancellationQQuotesOnly.rest)

ZeroGlobalCancellation ==
    [ incomingMessagesHeader        |-> ZeroIncomingMessagesHeader4,
      group                         |-> [i \in 1 .. 2 |-> 0],
      typeOfCancellationQQuotesOnly |-> [i \in 1 .. 1 |-> 0] ]

(* Global Cancellation at zero, then each field in turn at the values it is checked at *)
CheckedGlobalCancellation ==
    { ZeroGlobalCancellation }
        \cup { [ZeroGlobalCancellation EXCEPT !.incomingMessagesHeader = one] : one \in CheckedIncomingMessagesHeader4 }
        \cup { [ZeroGlobalCancellation EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroGlobalCancellation EXCEPT !.typeOfCancellationQQuotesOnly = one] : one \in Sample(1) }

(***************************************************************************)
(* Incoming Messages Header: 22 bytes                                      *)
(***************************************************************************)

IncomingMessagesHeader5 ==
    [ userTimestampLocalHhmmss : Sample(6),
      traderId                 : Sample(8),
      userSequenceId           : Sample(8) ]

EncodeIncomingMessagesHeader5(message) ==
    message.userTimestampLocalHhmmss
        \o message.traderId
        \o message.userSequenceId

DecodeIncomingMessagesHeader5(bytes) ==
    LET userTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~userTimestampLocalHhmmss.ok THEN Fail ELSE
    LET traderId == ReadBytes(userTimestampLocalHhmmss.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(traderId.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    Ok([ userTimestampLocalHhmmss |-> userTimestampLocalHhmmss.value,
         traderId                 |-> traderId.value,
         userSequenceId           |-> userSequenceId.value ], userSequenceId.rest)

ZeroIncomingMessagesHeader5 ==
    [ userTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      traderId                 |-> [i \in 1 .. 8 |-> 0],
      userSequenceId           |-> [i \in 1 .. 8 |-> 0] ]

(* Incoming Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedIncomingMessagesHeader5 ==
    { ZeroIncomingMessagesHeader5 }
        \cup { [ZeroIncomingMessagesHeader5 EXCEPT !.userTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroIncomingMessagesHeader5 EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroIncomingMessagesHeader5 EXCEPT !.userSequenceId = one] : one \in Sample(8) }

(***************************************************************************)
(* User Global Cancellation: 37 bytes                                      *)
(***************************************************************************)

UserGlobalCancellation ==
    [ incomingMessagesHeader : IncomingMessagesHeader5,
      groupFilter            : Sample(2),
      instrumentFilter       : Sample(4),
      typeOfCancellation     : Sample(1),
      accountTypeFilter      : Sample(8) ]

EncodeUserGlobalCancellation(message) ==
    EncodeIncomingMessagesHeader5(message.incomingMessagesHeader)
        \o message.groupFilter
        \o message.instrumentFilter
        \o message.typeOfCancellation
        \o message.accountTypeFilter

DecodeUserGlobalCancellation(bytes) ==
    LET incomingMessagesHeader == DecodeIncomingMessagesHeader5(bytes) IN IF ~incomingMessagesHeader.ok THEN Fail ELSE
    LET groupFilter == ReadBytes(incomingMessagesHeader.rest, 2) IN IF ~groupFilter.ok THEN Fail ELSE
    LET instrumentFilter == ReadBytes(groupFilter.rest, 4) IN IF ~instrumentFilter.ok THEN Fail ELSE
    LET typeOfCancellation == ReadBytes(instrumentFilter.rest, 1) IN IF ~typeOfCancellation.ok THEN Fail ELSE
    LET accountTypeFilter == ReadBytes(typeOfCancellation.rest, 8) IN IF ~accountTypeFilter.ok THEN Fail ELSE
    Ok([ incomingMessagesHeader |-> incomingMessagesHeader.value,
         groupFilter            |-> groupFilter.value,
         instrumentFilter       |-> instrumentFilter.value,
         typeOfCancellation     |-> typeOfCancellation.value,
         accountTypeFilter      |-> accountTypeFilter.value ], accountTypeFilter.rest)

ZeroUserGlobalCancellation ==
    [ incomingMessagesHeader |-> ZeroIncomingMessagesHeader5,
      groupFilter            |-> [i \in 1 .. 2 |-> 0],
      instrumentFilter       |-> [i \in 1 .. 4 |-> 0],
      typeOfCancellation     |-> [i \in 1 .. 1 |-> 0],
      accountTypeFilter      |-> [i \in 1 .. 8 |-> 0] ]

(* User Global Cancellation at zero, then each field in turn at the values it is checked at *)
CheckedUserGlobalCancellation ==
    { ZeroUserGlobalCancellation }
        \cup { [ZeroUserGlobalCancellation EXCEPT !.incomingMessagesHeader = one] : one \in CheckedIncomingMessagesHeader5 }
        \cup { [ZeroUserGlobalCancellation EXCEPT !.groupFilter = one] : one \in Sample(2) }
        \cup { [ZeroUserGlobalCancellation EXCEPT !.instrumentFilter = one] : one \in Sample(4) }
        \cup { [ZeroUserGlobalCancellation EXCEPT !.typeOfCancellation = one] : one \in Sample(1) }
        \cup { [ZeroUserGlobalCancellation EXCEPT !.accountTypeFilter = one] : one \in Sample(8) }

(***************************************************************************)
(* Incoming Messages Header: 22 bytes                                      *)
(***************************************************************************)

IncomingMessagesHeader6 ==
    [ userTimestampLocalHhmmss : Sample(6),
      traderId                 : Sample(8),
      userSequenceId           : Sample(8) ]

EncodeIncomingMessagesHeader6(message) ==
    message.userTimestampLocalHhmmss
        \o message.traderId
        \o message.userSequenceId

DecodeIncomingMessagesHeader6(bytes) ==
    LET userTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~userTimestampLocalHhmmss.ok THEN Fail ELSE
    LET traderId == ReadBytes(userTimestampLocalHhmmss.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(traderId.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    Ok([ userTimestampLocalHhmmss |-> userTimestampLocalHhmmss.value,
         traderId                 |-> traderId.value,
         userSequenceId           |-> userSequenceId.value ], userSequenceId.rest)

ZeroIncomingMessagesHeader6 ==
    [ userTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      traderId                 |-> [i \in 1 .. 8 |-> 0],
      userSequenceId           |-> [i \in 1 .. 8 |-> 0] ]

(* Incoming Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedIncomingMessagesHeader6 ==
    { ZeroIncomingMessagesHeader6 }
        \cup { [ZeroIncomingMessagesHeader6 EXCEPT !.userTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroIncomingMessagesHeader6 EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroIncomingMessagesHeader6 EXCEPT !.userSequenceId = one] : one \in Sample(8) }

(***************************************************************************)
(* Set Group Risk Limits Occurrence: 76 bytes                              *)
(***************************************************************************)

SetGroupRiskLimitsOccurrence ==
    [ trader               : Sample(4),
      group                : Sample(2),
      netExposureAction    : Sample(1),
      longExposureAction   : Sample(1),
      shortExposureAction  : Sample(1),
      netPositionAction    : Sample(1),
      longPositionAction   : Sample(1),
      shortPositionAction  : Sample(1),
      maximumOrderQuantity : Sample(8),
      netPositionLimit     : Sample(8),
      longPositionLimit    : Sample(8),
      shortPositionLimit   : Sample(8),
      netExposureLimit     : Sample(10),
      longExposureLimit    : Sample(10),
      shortExposureLimit   : Sample(10),
      filler2              : Sample(2) ]

EncodeSetGroupRiskLimitsOccurrence(message) ==
    message.trader
        \o message.group
        \o message.netExposureAction
        \o message.longExposureAction
        \o message.shortExposureAction
        \o message.netPositionAction
        \o message.longPositionAction
        \o message.shortPositionAction
        \o message.maximumOrderQuantity
        \o message.netPositionLimit
        \o message.longPositionLimit
        \o message.shortPositionLimit
        \o message.netExposureLimit
        \o message.longExposureLimit
        \o message.shortExposureLimit
        \o message.filler2

DecodeSetGroupRiskLimitsOccurrence(bytes) ==
    LET trader == ReadBytes(bytes, 4) IN IF ~trader.ok THEN Fail ELSE
    LET group == ReadBytes(trader.rest, 2) IN IF ~group.ok THEN Fail ELSE
    LET netExposureAction == ReadBytes(group.rest, 1) IN IF ~netExposureAction.ok THEN Fail ELSE
    LET longExposureAction == ReadBytes(netExposureAction.rest, 1) IN IF ~longExposureAction.ok THEN Fail ELSE
    LET shortExposureAction == ReadBytes(longExposureAction.rest, 1) IN IF ~shortExposureAction.ok THEN Fail ELSE
    LET netPositionAction == ReadBytes(shortExposureAction.rest, 1) IN IF ~netPositionAction.ok THEN Fail ELSE
    LET longPositionAction == ReadBytes(netPositionAction.rest, 1) IN IF ~longPositionAction.ok THEN Fail ELSE
    LET shortPositionAction == ReadBytes(longPositionAction.rest, 1) IN IF ~shortPositionAction.ok THEN Fail ELSE
    LET maximumOrderQuantity == ReadBytes(shortPositionAction.rest, 8) IN IF ~maximumOrderQuantity.ok THEN Fail ELSE
    LET netPositionLimit == ReadBytes(maximumOrderQuantity.rest, 8) IN IF ~netPositionLimit.ok THEN Fail ELSE
    LET longPositionLimit == ReadBytes(netPositionLimit.rest, 8) IN IF ~longPositionLimit.ok THEN Fail ELSE
    LET shortPositionLimit == ReadBytes(longPositionLimit.rest, 8) IN IF ~shortPositionLimit.ok THEN Fail ELSE
    LET netExposureLimit == ReadBytes(shortPositionLimit.rest, 10) IN IF ~netExposureLimit.ok THEN Fail ELSE
    LET longExposureLimit == ReadBytes(netExposureLimit.rest, 10) IN IF ~longExposureLimit.ok THEN Fail ELSE
    LET shortExposureLimit == ReadBytes(longExposureLimit.rest, 10) IN IF ~shortExposureLimit.ok THEN Fail ELSE
    LET filler2 == ReadBytes(shortExposureLimit.rest, 2) IN IF ~filler2.ok THEN Fail ELSE
    Ok([ trader               |-> trader.value,
         group                |-> group.value,
         netExposureAction    |-> netExposureAction.value,
         longExposureAction   |-> longExposureAction.value,
         shortExposureAction  |-> shortExposureAction.value,
         netPositionAction    |-> netPositionAction.value,
         longPositionAction   |-> longPositionAction.value,
         shortPositionAction  |-> shortPositionAction.value,
         maximumOrderQuantity |-> maximumOrderQuantity.value,
         netPositionLimit     |-> netPositionLimit.value,
         longPositionLimit    |-> longPositionLimit.value,
         shortPositionLimit   |-> shortPositionLimit.value,
         netExposureLimit     |-> netExposureLimit.value,
         longExposureLimit    |-> longExposureLimit.value,
         shortExposureLimit   |-> shortExposureLimit.value,
         filler2              |-> filler2.value ], filler2.rest)

ZeroSetGroupRiskLimitsOccurrence ==
    [ trader               |-> [i \in 1 .. 4 |-> 0],
      group                |-> [i \in 1 .. 2 |-> 0],
      netExposureAction    |-> [i \in 1 .. 1 |-> 0],
      longExposureAction   |-> [i \in 1 .. 1 |-> 0],
      shortExposureAction  |-> [i \in 1 .. 1 |-> 0],
      netPositionAction    |-> [i \in 1 .. 1 |-> 0],
      longPositionAction   |-> [i \in 1 .. 1 |-> 0],
      shortPositionAction  |-> [i \in 1 .. 1 |-> 0],
      maximumOrderQuantity |-> [i \in 1 .. 8 |-> 0],
      netPositionLimit     |-> [i \in 1 .. 8 |-> 0],
      longPositionLimit    |-> [i \in 1 .. 8 |-> 0],
      shortPositionLimit   |-> [i \in 1 .. 8 |-> 0],
      netExposureLimit     |-> [i \in 1 .. 10 |-> 0],
      longExposureLimit    |-> [i \in 1 .. 10 |-> 0],
      shortExposureLimit   |-> [i \in 1 .. 10 |-> 0],
      filler2              |-> [i \in 1 .. 2 |-> 0] ]

(* Set Group Risk Limits Occurrence at zero, then each field in turn at the values it is checked at *)
CheckedSetGroupRiskLimitsOccurrence ==
    { ZeroSetGroupRiskLimitsOccurrence }
        \cup { [ZeroSetGroupRiskLimitsOccurrence EXCEPT !.trader = one] : one \in Sample(4) }
        \cup { [ZeroSetGroupRiskLimitsOccurrence EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroSetGroupRiskLimitsOccurrence EXCEPT !.netExposureAction = one] : one \in Sample(1) }
        \cup { [ZeroSetGroupRiskLimitsOccurrence EXCEPT !.longExposureAction = one] : one \in Sample(1) }
        \cup { [ZeroSetGroupRiskLimitsOccurrence EXCEPT !.shortExposureAction = one] : one \in Sample(1) }
        \cup { [ZeroSetGroupRiskLimitsOccurrence EXCEPT !.netPositionAction = one] : one \in Sample(1) }
        \cup { [ZeroSetGroupRiskLimitsOccurrence EXCEPT !.longPositionAction = one] : one \in Sample(1) }
        \cup { [ZeroSetGroupRiskLimitsOccurrence EXCEPT !.shortPositionAction = one] : one \in Sample(1) }
        \cup { [ZeroSetGroupRiskLimitsOccurrence EXCEPT !.maximumOrderQuantity = one] : one \in Sample(8) }
        \cup { [ZeroSetGroupRiskLimitsOccurrence EXCEPT !.netPositionLimit = one] : one \in Sample(8) }
        \cup { [ZeroSetGroupRiskLimitsOccurrence EXCEPT !.longPositionLimit = one] : one \in Sample(8) }
        \cup { [ZeroSetGroupRiskLimitsOccurrence EXCEPT !.shortPositionLimit = one] : one \in Sample(8) }
        \cup { [ZeroSetGroupRiskLimitsOccurrence EXCEPT !.netExposureLimit = one] : one \in Sample(10) }
        \cup { [ZeroSetGroupRiskLimitsOccurrence EXCEPT !.longExposureLimit = one] : one \in Sample(10) }
        \cup { [ZeroSetGroupRiskLimitsOccurrence EXCEPT !.shortExposureLimit = one] : one \in Sample(10) }
        \cup { [ZeroSetGroupRiskLimitsOccurrence EXCEPT !.filler2 = one] : one \in Sample(2) }

(* A run of Set Group Risk Limits Occurrence, written one after another *)
RECURSIVE EncodeSetGroupRiskLimitsOccurrenceList(_)
EncodeSetGroupRiskLimitsOccurrenceList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSetGroupRiskLimitsOccurrence(Head(messages)) \o EncodeSetGroupRiskLimitsOccurrenceList(Tail(messages))

(* As many Set Group Risk Limits Occurrence as the field that counts them says *)
RECURSIVE ReadSetGroupRiskLimitsOccurrenceList(_, _)
ReadSetGroupRiskLimitsOccurrenceList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSetGroupRiskLimitsOccurrence(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSetGroupRiskLimitsOccurrenceList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Set Group Risk Limits Occurrence of each kind, for the lists that carry them *)
OneSetGroupRiskLimitsOccurrence == { ZeroSetGroupRiskLimitsOccurrence }

(***************************************************************************)
(* Set Group Risk Limits                                                   *)
(***************************************************************************)

SetGroupRiskLimits ==
    [ incomingMessagesHeader       : IncomingMessagesHeader6,
      resetAllGroups               : Sample(1),
      setGroupRiskLimitsOccurrence : SampleLists(OneSetGroupRiskLimitsOccurrence) ]

EncodeSetGroupRiskLimits(message) ==
    EncodeIncomingMessagesHeader6(message.incomingMessagesHeader)
        \o message.resetAllGroups
        \o EncodeDigits(Len(message.setGroupRiskLimitsOccurrence), 3)
        \o EncodeSetGroupRiskLimitsOccurrenceList(message.setGroupRiskLimitsOccurrence)

DecodeSetGroupRiskLimits(bytes) ==
    LET incomingMessagesHeader == DecodeIncomingMessagesHeader6(bytes) IN IF ~incomingMessagesHeader.ok THEN Fail ELSE
    LET resetAllGroups == ReadBytes(incomingMessagesHeader.rest, 1) IN IF ~resetAllGroups.ok THEN Fail ELSE
    LET numberOfGroupLimits == ReadDigits(resetAllGroups.rest, 3) IN IF ~numberOfGroupLimits.ok THEN Fail ELSE
    LET setGroupRiskLimitsOccurrence == ReadSetGroupRiskLimitsOccurrenceList(numberOfGroupLimits.rest, numberOfGroupLimits.value) IN IF ~setGroupRiskLimitsOccurrence.ok THEN Fail ELSE
    Ok([ incomingMessagesHeader       |-> incomingMessagesHeader.value,
         resetAllGroups               |-> resetAllGroups.value,
         setGroupRiskLimitsOccurrence |-> setGroupRiskLimitsOccurrence.value ], setGroupRiskLimitsOccurrence.rest)

ZeroSetGroupRiskLimits ==
    [ incomingMessagesHeader       |-> ZeroIncomingMessagesHeader6,
      resetAllGroups               |-> [i \in 1 .. 1 |-> 0],
      setGroupRiskLimitsOccurrence |-> << >> ]

(* Set Group Risk Limits at zero, then each field in turn at the values it is checked at *)
CheckedSetGroupRiskLimits ==
    { ZeroSetGroupRiskLimits }
        \cup { [ZeroSetGroupRiskLimits EXCEPT !.incomingMessagesHeader = one] : one \in CheckedIncomingMessagesHeader6 }
        \cup { [ZeroSetGroupRiskLimits EXCEPT !.resetAllGroups = one] : one \in Sample(1) }
        \cup { [ZeroSetGroupRiskLimits EXCEPT !.setGroupRiskLimitsOccurrence = one] : one \in SampleLists(OneSetGroupRiskLimitsOccurrence) }

(***************************************************************************)
(* Incoming Messages Header: 22 bytes                                      *)
(***************************************************************************)

IncomingMessagesHeader7 ==
    [ userTimestampLocalHhmmss : Sample(6),
      traderId                 : Sample(8),
      userSequenceId           : Sample(8) ]

EncodeIncomingMessagesHeader7(message) ==
    message.userTimestampLocalHhmmss
        \o message.traderId
        \o message.userSequenceId

DecodeIncomingMessagesHeader7(bytes) ==
    LET userTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~userTimestampLocalHhmmss.ok THEN Fail ELSE
    LET traderId == ReadBytes(userTimestampLocalHhmmss.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(traderId.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    Ok([ userTimestampLocalHhmmss |-> userTimestampLocalHhmmss.value,
         traderId                 |-> traderId.value,
         userSequenceId           |-> userSequenceId.value ], userSequenceId.rest)

ZeroIncomingMessagesHeader7 ==
    [ userTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      traderId                 |-> [i \in 1 .. 8 |-> 0],
      userSequenceId           |-> [i \in 1 .. 8 |-> 0] ]

(* Incoming Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedIncomingMessagesHeader7 ==
    { ZeroIncomingMessagesHeader7 }
        \cup { [ZeroIncomingMessagesHeader7 EXCEPT !.userTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroIncomingMessagesHeader7 EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroIncomingMessagesHeader7 EXCEPT !.userSequenceId = one] : one \in Sample(8) }

(***************************************************************************)
(* Set Global Risk Limits: 101 bytes                                       *)
(***************************************************************************)

SetGlobalRiskLimits ==
    [ incomingMessagesHeader      : IncomingMessagesHeader7,
      globalNetExposureAction     : Sample(1),
      defaultNetExposureAction    : Sample(1),
      defaultLongExposureAction   : Sample(1),
      defaultShortExposureAction  : Sample(1),
      defaultNetPositionAction    : Sample(1),
      defaultLongPositionAction   : Sample(1),
      defaultShortPositionAction  : Sample(1),
      globalNetExposureLimit      : Sample(10),
      defaultMaximumOrderQuantity : Sample(8),
      defaultNetExposureLimit     : Sample(10),
      defaultLongExposureLimit    : Sample(10),
      defaultShortExposureLimit   : Sample(10),
      defaultNetPositionLimit     : Sample(8),
      defaultLongPositionLimit    : Sample(8),
      defaultShortPositionLimit   : Sample(8) ]

EncodeSetGlobalRiskLimits(message) ==
    EncodeIncomingMessagesHeader7(message.incomingMessagesHeader)
        \o message.globalNetExposureAction
        \o message.defaultNetExposureAction
        \o message.defaultLongExposureAction
        \o message.defaultShortExposureAction
        \o message.defaultNetPositionAction
        \o message.defaultLongPositionAction
        \o message.defaultShortPositionAction
        \o message.globalNetExposureLimit
        \o message.defaultMaximumOrderQuantity
        \o message.defaultNetExposureLimit
        \o message.defaultLongExposureLimit
        \o message.defaultShortExposureLimit
        \o message.defaultNetPositionLimit
        \o message.defaultLongPositionLimit
        \o message.defaultShortPositionLimit

DecodeSetGlobalRiskLimits(bytes) ==
    LET incomingMessagesHeader == DecodeIncomingMessagesHeader7(bytes) IN IF ~incomingMessagesHeader.ok THEN Fail ELSE
    LET globalNetExposureAction == ReadBytes(incomingMessagesHeader.rest, 1) IN IF ~globalNetExposureAction.ok THEN Fail ELSE
    LET defaultNetExposureAction == ReadBytes(globalNetExposureAction.rest, 1) IN IF ~defaultNetExposureAction.ok THEN Fail ELSE
    LET defaultLongExposureAction == ReadBytes(defaultNetExposureAction.rest, 1) IN IF ~defaultLongExposureAction.ok THEN Fail ELSE
    LET defaultShortExposureAction == ReadBytes(defaultLongExposureAction.rest, 1) IN IF ~defaultShortExposureAction.ok THEN Fail ELSE
    LET defaultNetPositionAction == ReadBytes(defaultShortExposureAction.rest, 1) IN IF ~defaultNetPositionAction.ok THEN Fail ELSE
    LET defaultLongPositionAction == ReadBytes(defaultNetPositionAction.rest, 1) IN IF ~defaultLongPositionAction.ok THEN Fail ELSE
    LET defaultShortPositionAction == ReadBytes(defaultLongPositionAction.rest, 1) IN IF ~defaultShortPositionAction.ok THEN Fail ELSE
    LET globalNetExposureLimit == ReadBytes(defaultShortPositionAction.rest, 10) IN IF ~globalNetExposureLimit.ok THEN Fail ELSE
    LET defaultMaximumOrderQuantity == ReadBytes(globalNetExposureLimit.rest, 8) IN IF ~defaultMaximumOrderQuantity.ok THEN Fail ELSE
    LET defaultNetExposureLimit == ReadBytes(defaultMaximumOrderQuantity.rest, 10) IN IF ~defaultNetExposureLimit.ok THEN Fail ELSE
    LET defaultLongExposureLimit == ReadBytes(defaultNetExposureLimit.rest, 10) IN IF ~defaultLongExposureLimit.ok THEN Fail ELSE
    LET defaultShortExposureLimit == ReadBytes(defaultLongExposureLimit.rest, 10) IN IF ~defaultShortExposureLimit.ok THEN Fail ELSE
    LET defaultNetPositionLimit == ReadBytes(defaultShortExposureLimit.rest, 8) IN IF ~defaultNetPositionLimit.ok THEN Fail ELSE
    LET defaultLongPositionLimit == ReadBytes(defaultNetPositionLimit.rest, 8) IN IF ~defaultLongPositionLimit.ok THEN Fail ELSE
    LET defaultShortPositionLimit == ReadBytes(defaultLongPositionLimit.rest, 8) IN IF ~defaultShortPositionLimit.ok THEN Fail ELSE
    Ok([ incomingMessagesHeader      |-> incomingMessagesHeader.value,
         globalNetExposureAction     |-> globalNetExposureAction.value,
         defaultNetExposureAction    |-> defaultNetExposureAction.value,
         defaultLongExposureAction   |-> defaultLongExposureAction.value,
         defaultShortExposureAction  |-> defaultShortExposureAction.value,
         defaultNetPositionAction    |-> defaultNetPositionAction.value,
         defaultLongPositionAction   |-> defaultLongPositionAction.value,
         defaultShortPositionAction  |-> defaultShortPositionAction.value,
         globalNetExposureLimit      |-> globalNetExposureLimit.value,
         defaultMaximumOrderQuantity |-> defaultMaximumOrderQuantity.value,
         defaultNetExposureLimit     |-> defaultNetExposureLimit.value,
         defaultLongExposureLimit    |-> defaultLongExposureLimit.value,
         defaultShortExposureLimit   |-> defaultShortExposureLimit.value,
         defaultNetPositionLimit     |-> defaultNetPositionLimit.value,
         defaultLongPositionLimit    |-> defaultLongPositionLimit.value,
         defaultShortPositionLimit   |-> defaultShortPositionLimit.value ], defaultShortPositionLimit.rest)

ZeroSetGlobalRiskLimits ==
    [ incomingMessagesHeader      |-> ZeroIncomingMessagesHeader7,
      globalNetExposureAction     |-> [i \in 1 .. 1 |-> 0],
      defaultNetExposureAction    |-> [i \in 1 .. 1 |-> 0],
      defaultLongExposureAction   |-> [i \in 1 .. 1 |-> 0],
      defaultShortExposureAction  |-> [i \in 1 .. 1 |-> 0],
      defaultNetPositionAction    |-> [i \in 1 .. 1 |-> 0],
      defaultLongPositionAction   |-> [i \in 1 .. 1 |-> 0],
      defaultShortPositionAction  |-> [i \in 1 .. 1 |-> 0],
      globalNetExposureLimit      |-> [i \in 1 .. 10 |-> 0],
      defaultMaximumOrderQuantity |-> [i \in 1 .. 8 |-> 0],
      defaultNetExposureLimit     |-> [i \in 1 .. 10 |-> 0],
      defaultLongExposureLimit    |-> [i \in 1 .. 10 |-> 0],
      defaultShortExposureLimit   |-> [i \in 1 .. 10 |-> 0],
      defaultNetPositionLimit     |-> [i \in 1 .. 8 |-> 0],
      defaultLongPositionLimit    |-> [i \in 1 .. 8 |-> 0],
      defaultShortPositionLimit   |-> [i \in 1 .. 8 |-> 0] ]

(* Set Global Risk Limits at zero, then each field in turn at the values it is checked at *)
CheckedSetGlobalRiskLimits ==
    { ZeroSetGlobalRiskLimits }
        \cup { [ZeroSetGlobalRiskLimits EXCEPT !.incomingMessagesHeader = one] : one \in CheckedIncomingMessagesHeader7 }
        \cup { [ZeroSetGlobalRiskLimits EXCEPT !.globalNetExposureAction = one] : one \in Sample(1) }
        \cup { [ZeroSetGlobalRiskLimits EXCEPT !.defaultNetExposureAction = one] : one \in Sample(1) }
        \cup { [ZeroSetGlobalRiskLimits EXCEPT !.defaultLongExposureAction = one] : one \in Sample(1) }
        \cup { [ZeroSetGlobalRiskLimits EXCEPT !.defaultShortExposureAction = one] : one \in Sample(1) }
        \cup { [ZeroSetGlobalRiskLimits EXCEPT !.defaultNetPositionAction = one] : one \in Sample(1) }
        \cup { [ZeroSetGlobalRiskLimits EXCEPT !.defaultLongPositionAction = one] : one \in Sample(1) }
        \cup { [ZeroSetGlobalRiskLimits EXCEPT !.defaultShortPositionAction = one] : one \in Sample(1) }
        \cup { [ZeroSetGlobalRiskLimits EXCEPT !.globalNetExposureLimit = one] : one \in Sample(10) }
        \cup { [ZeroSetGlobalRiskLimits EXCEPT !.defaultMaximumOrderQuantity = one] : one \in Sample(8) }
        \cup { [ZeroSetGlobalRiskLimits EXCEPT !.defaultNetExposureLimit = one] : one \in Sample(10) }
        \cup { [ZeroSetGlobalRiskLimits EXCEPT !.defaultLongExposureLimit = one] : one \in Sample(10) }
        \cup { [ZeroSetGlobalRiskLimits EXCEPT !.defaultShortExposureLimit = one] : one \in Sample(10) }
        \cup { [ZeroSetGlobalRiskLimits EXCEPT !.defaultNetPositionLimit = one] : one \in Sample(8) }
        \cup { [ZeroSetGlobalRiskLimits EXCEPT !.defaultLongPositionLimit = one] : one \in Sample(8) }
        \cup { [ZeroSetGlobalRiskLimits EXCEPT !.defaultShortPositionLimit = one] : one \in Sample(8) }

(***************************************************************************)
(* Incoming Messages Header: 22 bytes                                      *)
(***************************************************************************)

IncomingMessagesHeader8 ==
    [ userTimestampLocalHhmmss : Sample(6),
      traderId                 : Sample(8),
      userSequenceId           : Sample(8) ]

EncodeIncomingMessagesHeader8(message) ==
    message.userTimestampLocalHhmmss
        \o message.traderId
        \o message.userSequenceId

DecodeIncomingMessagesHeader8(bytes) ==
    LET userTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~userTimestampLocalHhmmss.ok THEN Fail ELSE
    LET traderId == ReadBytes(userTimestampLocalHhmmss.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(traderId.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    Ok([ userTimestampLocalHhmmss |-> userTimestampLocalHhmmss.value,
         traderId                 |-> traderId.value,
         userSequenceId           |-> userSequenceId.value ], userSequenceId.rest)

ZeroIncomingMessagesHeader8 ==
    [ userTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      traderId                 |-> [i \in 1 .. 8 |-> 0],
      userSequenceId           |-> [i \in 1 .. 8 |-> 0] ]

(* Incoming Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedIncomingMessagesHeader8 ==
    { ZeroIncomingMessagesHeader8 }
        \cup { [ZeroIncomingMessagesHeader8 EXCEPT !.userTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroIncomingMessagesHeader8 EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroIncomingMessagesHeader8 EXCEPT !.userSequenceId = one] : one \in Sample(8) }

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
(* Order Entry: 181 bytes                                                  *)
(***************************************************************************)

OrderEntry ==
    [ incomingMessagesHeader : IncomingMessagesHeader8,
      group                  : Sample(2),
      instrument             : Sample(4),
      priceType              : Sample(1),
      verbSide               : Sample(1),
      quantity               : Sample(8),
      price                  : Sample(10),
      specialPriceTerm       : Sample(1),
      additionalPrice        : Sample(10),
      quantityTerm           : Sample(1),
      additionalQuantity     : Sample(8),
      durationType           : Sample(1),
      gtdDate                : Sample(8),
      executingParticipant   : Sample(4),
      filler1                : Sample(1),
      clearingData           : ClearingData2,
      ownerData              : OwnerData2,
      antiWashId             : Sample(8),
      antiWashInstruction    : Sample(1),
      filler20               : Sample(20) ]

EncodeOrderEntry(message) ==
    EncodeIncomingMessagesHeader8(message.incomingMessagesHeader)
        \o message.group
        \o message.instrument
        \o message.priceType
        \o message.verbSide
        \o message.quantity
        \o message.price
        \o message.specialPriceTerm
        \o message.additionalPrice
        \o message.quantityTerm
        \o message.additionalQuantity
        \o message.durationType
        \o message.gtdDate
        \o message.executingParticipant
        \o message.filler1
        \o EncodeClearingData2(message.clearingData)
        \o EncodeOwnerData2(message.ownerData)
        \o message.antiWashId
        \o message.antiWashInstruction
        \o message.filler20

DecodeOrderEntry(bytes) ==
    LET incomingMessagesHeader == DecodeIncomingMessagesHeader8(bytes) IN IF ~incomingMessagesHeader.ok THEN Fail ELSE
    LET group == ReadBytes(incomingMessagesHeader.rest, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrument == ReadBytes(group.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET priceType == ReadBytes(instrument.rest, 1) IN IF ~priceType.ok THEN Fail ELSE
    LET verbSide == ReadBytes(priceType.rest, 1) IN IF ~verbSide.ok THEN Fail ELSE
    LET quantity == ReadBytes(verbSide.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 10) IN IF ~price.ok THEN Fail ELSE
    LET specialPriceTerm == ReadBytes(price.rest, 1) IN IF ~specialPriceTerm.ok THEN Fail ELSE
    LET additionalPrice == ReadBytes(specialPriceTerm.rest, 10) IN IF ~additionalPrice.ok THEN Fail ELSE
    LET quantityTerm == ReadBytes(additionalPrice.rest, 1) IN IF ~quantityTerm.ok THEN Fail ELSE
    LET additionalQuantity == ReadBytes(quantityTerm.rest, 8) IN IF ~additionalQuantity.ok THEN Fail ELSE
    LET durationType == ReadBytes(additionalQuantity.rest, 1) IN IF ~durationType.ok THEN Fail ELSE
    LET gtdDate == ReadBytes(durationType.rest, 8) IN IF ~gtdDate.ok THEN Fail ELSE
    LET executingParticipant == ReadBytes(gtdDate.rest, 4) IN IF ~executingParticipant.ok THEN Fail ELSE
    LET filler1 == ReadBytes(executingParticipant.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET clearingData == DecodeClearingData2(filler1.rest) IN IF ~clearingData.ok THEN Fail ELSE
    LET ownerData == DecodeOwnerData2(clearingData.rest) IN IF ~ownerData.ok THEN Fail ELSE
    LET antiWashId == ReadBytes(ownerData.rest, 8) IN IF ~antiWashId.ok THEN Fail ELSE
    LET antiWashInstruction == ReadBytes(antiWashId.rest, 1) IN IF ~antiWashInstruction.ok THEN Fail ELSE
    LET filler20 == ReadBytes(antiWashInstruction.rest, 20) IN IF ~filler20.ok THEN Fail ELSE
    Ok([ incomingMessagesHeader |-> incomingMessagesHeader.value,
         group                  |-> group.value,
         instrument             |-> instrument.value,
         priceType              |-> priceType.value,
         verbSide               |-> verbSide.value,
         quantity               |-> quantity.value,
         price                  |-> price.value,
         specialPriceTerm       |-> specialPriceTerm.value,
         additionalPrice        |-> additionalPrice.value,
         quantityTerm           |-> quantityTerm.value,
         additionalQuantity     |-> additionalQuantity.value,
         durationType           |-> durationType.value,
         gtdDate                |-> gtdDate.value,
         executingParticipant   |-> executingParticipant.value,
         filler1                |-> filler1.value,
         clearingData           |-> clearingData.value,
         ownerData              |-> ownerData.value,
         antiWashId             |-> antiWashId.value,
         antiWashInstruction    |-> antiWashInstruction.value,
         filler20               |-> filler20.value ], filler20.rest)

ZeroOrderEntry ==
    [ incomingMessagesHeader |-> ZeroIncomingMessagesHeader8,
      group                  |-> [i \in 1 .. 2 |-> 0],
      instrument             |-> [i \in 1 .. 4 |-> 0],
      priceType              |-> [i \in 1 .. 1 |-> 0],
      verbSide               |-> [i \in 1 .. 1 |-> 0],
      quantity               |-> [i \in 1 .. 8 |-> 0],
      price                  |-> [i \in 1 .. 10 |-> 0],
      specialPriceTerm       |-> [i \in 1 .. 1 |-> 0],
      additionalPrice        |-> [i \in 1 .. 10 |-> 0],
      quantityTerm           |-> [i \in 1 .. 1 |-> 0],
      additionalQuantity     |-> [i \in 1 .. 8 |-> 0],
      durationType           |-> [i \in 1 .. 1 |-> 0],
      gtdDate                |-> [i \in 1 .. 8 |-> 0],
      executingParticipant   |-> [i \in 1 .. 4 |-> 0],
      filler1                |-> [i \in 1 .. 1 |-> 0],
      clearingData           |-> ZeroClearingData2,
      ownerData              |-> ZeroOwnerData2,
      antiWashId             |-> [i \in 1 .. 8 |-> 0],
      antiWashInstruction    |-> [i \in 1 .. 1 |-> 0],
      filler20               |-> [i \in 1 .. 20 |-> 0] ]

(* Order Entry at zero, then each field in turn at the values it is checked at *)
CheckedOrderEntry ==
    { ZeroOrderEntry }
        \cup { [ZeroOrderEntry EXCEPT !.incomingMessagesHeader = one] : one \in CheckedIncomingMessagesHeader8 }
        \cup { [ZeroOrderEntry EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntry EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntry EXCEPT !.priceType = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntry EXCEPT !.verbSide = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntry EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroOrderEntry EXCEPT !.price = one] : one \in Sample(10) }
        \cup { [ZeroOrderEntry EXCEPT !.specialPriceTerm = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntry EXCEPT !.additionalPrice = one] : one \in Sample(10) }
        \cup { [ZeroOrderEntry EXCEPT !.quantityTerm = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntry EXCEPT !.additionalQuantity = one] : one \in Sample(8) }
        \cup { [ZeroOrderEntry EXCEPT !.durationType = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntry EXCEPT !.gtdDate = one] : one \in Sample(8) }
        \cup { [ZeroOrderEntry EXCEPT !.executingParticipant = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntry EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntry EXCEPT !.clearingData = one] : one \in CheckedClearingData2 }
        \cup { [ZeroOrderEntry EXCEPT !.ownerData = one] : one \in CheckedOwnerData2 }
        \cup { [ZeroOrderEntry EXCEPT !.antiWashId = one] : one \in Sample(8) }
        \cup { [ZeroOrderEntry EXCEPT !.antiWashInstruction = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntry EXCEPT !.filler20 = one] : one \in Sample(20) }

(***************************************************************************)
(* Incoming Messages Header: 22 bytes                                      *)
(***************************************************************************)

IncomingMessagesHeader9 ==
    [ userTimestampLocalHhmmss : Sample(6),
      traderId                 : Sample(8),
      userSequenceId           : Sample(8) ]

EncodeIncomingMessagesHeader9(message) ==
    message.userTimestampLocalHhmmss
        \o message.traderId
        \o message.userSequenceId

DecodeIncomingMessagesHeader9(bytes) ==
    LET userTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~userTimestampLocalHhmmss.ok THEN Fail ELSE
    LET traderId == ReadBytes(userTimestampLocalHhmmss.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(traderId.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    Ok([ userTimestampLocalHhmmss |-> userTimestampLocalHhmmss.value,
         traderId                 |-> traderId.value,
         userSequenceId           |-> userSequenceId.value ], userSequenceId.rest)

ZeroIncomingMessagesHeader9 ==
    [ userTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      traderId                 |-> [i \in 1 .. 8 |-> 0],
      userSequenceId           |-> [i \in 1 .. 8 |-> 0] ]

(* Incoming Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedIncomingMessagesHeader9 ==
    { ZeroIncomingMessagesHeader9 }
        \cup { [ZeroIncomingMessagesHeader9 EXCEPT !.userTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroIncomingMessagesHeader9 EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroIncomingMessagesHeader9 EXCEPT !.userSequenceId = one] : one \in Sample(8) }

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
(* Order Modification: 190 bytes                                           *)
(***************************************************************************)

OrderModification ==
    [ incomingMessagesHeader : IncomingMessagesHeader9,
      group                  : Sample(2),
      instrument             : Sample(4),
      priceType              : Sample(1),
      verbSide               : Sample(1),
      quantitySign           : Sample(1),
      quantity               : Sample(8),
      price                  : Sample(10),
      specialPriceTerm       : Sample(1),
      additionalPrice        : Sample(10),
      quantityTerm           : Sample(1),
      additionalQuantity     : Sample(8),
      durationType           : Sample(1),
      gtdDate                : Sample(8),
      filler4                : Sample(4),
      filler1                : Sample(1),
      modifiedOrderId        : Sample(8),
      clearingData           : ClearingData3,
      ownerData              : OwnerData3,
      antiWashId             : Sample(8),
      antiWashInstruction    : Sample(1),
      filler20               : Sample(20) ]

EncodeOrderModification(message) ==
    EncodeIncomingMessagesHeader9(message.incomingMessagesHeader)
        \o message.group
        \o message.instrument
        \o message.priceType
        \o message.verbSide
        \o message.quantitySign
        \o message.quantity
        \o message.price
        \o message.specialPriceTerm
        \o message.additionalPrice
        \o message.quantityTerm
        \o message.additionalQuantity
        \o message.durationType
        \o message.gtdDate
        \o message.filler4
        \o message.filler1
        \o message.modifiedOrderId
        \o EncodeClearingData3(message.clearingData)
        \o EncodeOwnerData3(message.ownerData)
        \o message.antiWashId
        \o message.antiWashInstruction
        \o message.filler20

DecodeOrderModification(bytes) ==
    LET incomingMessagesHeader == DecodeIncomingMessagesHeader9(bytes) IN IF ~incomingMessagesHeader.ok THEN Fail ELSE
    LET group == ReadBytes(incomingMessagesHeader.rest, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrument == ReadBytes(group.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET priceType == ReadBytes(instrument.rest, 1) IN IF ~priceType.ok THEN Fail ELSE
    LET verbSide == ReadBytes(priceType.rest, 1) IN IF ~verbSide.ok THEN Fail ELSE
    LET quantitySign == ReadBytes(verbSide.rest, 1) IN IF ~quantitySign.ok THEN Fail ELSE
    LET quantity == ReadBytes(quantitySign.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 10) IN IF ~price.ok THEN Fail ELSE
    LET specialPriceTerm == ReadBytes(price.rest, 1) IN IF ~specialPriceTerm.ok THEN Fail ELSE
    LET additionalPrice == ReadBytes(specialPriceTerm.rest, 10) IN IF ~additionalPrice.ok THEN Fail ELSE
    LET quantityTerm == ReadBytes(additionalPrice.rest, 1) IN IF ~quantityTerm.ok THEN Fail ELSE
    LET additionalQuantity == ReadBytes(quantityTerm.rest, 8) IN IF ~additionalQuantity.ok THEN Fail ELSE
    LET durationType == ReadBytes(additionalQuantity.rest, 1) IN IF ~durationType.ok THEN Fail ELSE
    LET gtdDate == ReadBytes(durationType.rest, 8) IN IF ~gtdDate.ok THEN Fail ELSE
    LET filler4 == ReadBytes(gtdDate.rest, 4) IN IF ~filler4.ok THEN Fail ELSE
    LET filler1 == ReadBytes(filler4.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET modifiedOrderId == ReadBytes(filler1.rest, 8) IN IF ~modifiedOrderId.ok THEN Fail ELSE
    LET clearingData == DecodeClearingData3(modifiedOrderId.rest) IN IF ~clearingData.ok THEN Fail ELSE
    LET ownerData == DecodeOwnerData3(clearingData.rest) IN IF ~ownerData.ok THEN Fail ELSE
    LET antiWashId == ReadBytes(ownerData.rest, 8) IN IF ~antiWashId.ok THEN Fail ELSE
    LET antiWashInstruction == ReadBytes(antiWashId.rest, 1) IN IF ~antiWashInstruction.ok THEN Fail ELSE
    LET filler20 == ReadBytes(antiWashInstruction.rest, 20) IN IF ~filler20.ok THEN Fail ELSE
    Ok([ incomingMessagesHeader |-> incomingMessagesHeader.value,
         group                  |-> group.value,
         instrument             |-> instrument.value,
         priceType              |-> priceType.value,
         verbSide               |-> verbSide.value,
         quantitySign           |-> quantitySign.value,
         quantity               |-> quantity.value,
         price                  |-> price.value,
         specialPriceTerm       |-> specialPriceTerm.value,
         additionalPrice        |-> additionalPrice.value,
         quantityTerm           |-> quantityTerm.value,
         additionalQuantity     |-> additionalQuantity.value,
         durationType           |-> durationType.value,
         gtdDate                |-> gtdDate.value,
         filler4                |-> filler4.value,
         filler1                |-> filler1.value,
         modifiedOrderId        |-> modifiedOrderId.value,
         clearingData           |-> clearingData.value,
         ownerData              |-> ownerData.value,
         antiWashId             |-> antiWashId.value,
         antiWashInstruction    |-> antiWashInstruction.value,
         filler20               |-> filler20.value ], filler20.rest)

ZeroOrderModification ==
    [ incomingMessagesHeader |-> ZeroIncomingMessagesHeader9,
      group                  |-> [i \in 1 .. 2 |-> 0],
      instrument             |-> [i \in 1 .. 4 |-> 0],
      priceType              |-> [i \in 1 .. 1 |-> 0],
      verbSide               |-> [i \in 1 .. 1 |-> 0],
      quantitySign           |-> [i \in 1 .. 1 |-> 0],
      quantity               |-> [i \in 1 .. 8 |-> 0],
      price                  |-> [i \in 1 .. 10 |-> 0],
      specialPriceTerm       |-> [i \in 1 .. 1 |-> 0],
      additionalPrice        |-> [i \in 1 .. 10 |-> 0],
      quantityTerm           |-> [i \in 1 .. 1 |-> 0],
      additionalQuantity     |-> [i \in 1 .. 8 |-> 0],
      durationType           |-> [i \in 1 .. 1 |-> 0],
      gtdDate                |-> [i \in 1 .. 8 |-> 0],
      filler4                |-> [i \in 1 .. 4 |-> 0],
      filler1                |-> [i \in 1 .. 1 |-> 0],
      modifiedOrderId        |-> [i \in 1 .. 8 |-> 0],
      clearingData           |-> ZeroClearingData3,
      ownerData              |-> ZeroOwnerData3,
      antiWashId             |-> [i \in 1 .. 8 |-> 0],
      antiWashInstruction    |-> [i \in 1 .. 1 |-> 0],
      filler20               |-> [i \in 1 .. 20 |-> 0] ]

(* Order Modification at zero, then each field in turn at the values it is checked at *)
CheckedOrderModification ==
    { ZeroOrderModification }
        \cup { [ZeroOrderModification EXCEPT !.incomingMessagesHeader = one] : one \in CheckedIncomingMessagesHeader9 }
        \cup { [ZeroOrderModification EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroOrderModification EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroOrderModification EXCEPT !.priceType = one] : one \in Sample(1) }
        \cup { [ZeroOrderModification EXCEPT !.verbSide = one] : one \in Sample(1) }
        \cup { [ZeroOrderModification EXCEPT !.quantitySign = one] : one \in Sample(1) }
        \cup { [ZeroOrderModification EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroOrderModification EXCEPT !.price = one] : one \in Sample(10) }
        \cup { [ZeroOrderModification EXCEPT !.specialPriceTerm = one] : one \in Sample(1) }
        \cup { [ZeroOrderModification EXCEPT !.additionalPrice = one] : one \in Sample(10) }
        \cup { [ZeroOrderModification EXCEPT !.quantityTerm = one] : one \in Sample(1) }
        \cup { [ZeroOrderModification EXCEPT !.additionalQuantity = one] : one \in Sample(8) }
        \cup { [ZeroOrderModification EXCEPT !.durationType = one] : one \in Sample(1) }
        \cup { [ZeroOrderModification EXCEPT !.gtdDate = one] : one \in Sample(8) }
        \cup { [ZeroOrderModification EXCEPT !.filler4 = one] : one \in Sample(4) }
        \cup { [ZeroOrderModification EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderModification EXCEPT !.modifiedOrderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderModification EXCEPT !.clearingData = one] : one \in CheckedClearingData3 }
        \cup { [ZeroOrderModification EXCEPT !.ownerData = one] : one \in CheckedOwnerData3 }
        \cup { [ZeroOrderModification EXCEPT !.antiWashId = one] : one \in Sample(8) }
        \cup { [ZeroOrderModification EXCEPT !.antiWashInstruction = one] : one \in Sample(1) }
        \cup { [ZeroOrderModification EXCEPT !.filler20 = one] : one \in Sample(20) }

(***************************************************************************)
(* Incoming Messages Header: 22 bytes                                      *)
(***************************************************************************)

IncomingMessagesHeader10 ==
    [ userTimestampLocalHhmmss : Sample(6),
      traderId                 : Sample(8),
      userSequenceId           : Sample(8) ]

EncodeIncomingMessagesHeader10(message) ==
    message.userTimestampLocalHhmmss
        \o message.traderId
        \o message.userSequenceId

DecodeIncomingMessagesHeader10(bytes) ==
    LET userTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~userTimestampLocalHhmmss.ok THEN Fail ELSE
    LET traderId == ReadBytes(userTimestampLocalHhmmss.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(traderId.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    Ok([ userTimestampLocalHhmmss |-> userTimestampLocalHhmmss.value,
         traderId                 |-> traderId.value,
         userSequenceId           |-> userSequenceId.value ], userSequenceId.rest)

ZeroIncomingMessagesHeader10 ==
    [ userTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      traderId                 |-> [i \in 1 .. 8 |-> 0],
      userSequenceId           |-> [i \in 1 .. 8 |-> 0] ]

(* Incoming Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedIncomingMessagesHeader10 ==
    { ZeroIncomingMessagesHeader10 }
        \cup { [ZeroIncomingMessagesHeader10 EXCEPT !.userTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroIncomingMessagesHeader10 EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroIncomingMessagesHeader10 EXCEPT !.userSequenceId = one] : one \in Sample(8) }

(***************************************************************************)
(* New Strategy Instrument Leg Definition Repeating Block: 16 bytes        *)
(***************************************************************************)

NewStrategyInstrumentLegDefinitionRepeatingBlock ==
    [ legGroup         : Sample(2),
      legInstrument    : Sample(4),
      legVerb          : Sample(1),
      filler1          : Sample(1),
      legQuantityRatio : Sample(8) ]

EncodeNewStrategyInstrumentLegDefinitionRepeatingBlock(message) ==
    message.legGroup
        \o message.legInstrument
        \o message.legVerb
        \o message.filler1
        \o message.legQuantityRatio

DecodeNewStrategyInstrumentLegDefinitionRepeatingBlock(bytes) ==
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

ZeroNewStrategyInstrumentLegDefinitionRepeatingBlock ==
    [ legGroup         |-> [i \in 1 .. 2 |-> 0],
      legInstrument    |-> [i \in 1 .. 4 |-> 0],
      legVerb          |-> [i \in 1 .. 1 |-> 0],
      filler1          |-> [i \in 1 .. 1 |-> 0],
      legQuantityRatio |-> [i \in 1 .. 8 |-> 0] ]

(* New Strategy Instrument Leg Definition Repeating Block at zero, then each field in turn at the values it is checked at *)
CheckedNewStrategyInstrumentLegDefinitionRepeatingBlock ==
    { ZeroNewStrategyInstrumentLegDefinitionRepeatingBlock }
        \cup { [ZeroNewStrategyInstrumentLegDefinitionRepeatingBlock EXCEPT !.legGroup = one] : one \in Sample(2) }
        \cup { [ZeroNewStrategyInstrumentLegDefinitionRepeatingBlock EXCEPT !.legInstrument = one] : one \in Sample(4) }
        \cup { [ZeroNewStrategyInstrumentLegDefinitionRepeatingBlock EXCEPT !.legVerb = one] : one \in Sample(1) }
        \cup { [ZeroNewStrategyInstrumentLegDefinitionRepeatingBlock EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroNewStrategyInstrumentLegDefinitionRepeatingBlock EXCEPT !.legQuantityRatio = one] : one \in Sample(8) }

(* A run of New Strategy Instrument Leg Definition Repeating Block, written one after another *)
RECURSIVE EncodeNewStrategyInstrumentLegDefinitionRepeatingBlockList(_)
EncodeNewStrategyInstrumentLegDefinitionRepeatingBlockList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeNewStrategyInstrumentLegDefinitionRepeatingBlock(Head(messages)) \o EncodeNewStrategyInstrumentLegDefinitionRepeatingBlockList(Tail(messages))

(* As many New Strategy Instrument Leg Definition Repeating Block as the field that counts them says *)
RECURSIVE ReadNewStrategyInstrumentLegDefinitionRepeatingBlockList(_, _)
ReadNewStrategyInstrumentLegDefinitionRepeatingBlockList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeNewStrategyInstrumentLegDefinitionRepeatingBlock(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadNewStrategyInstrumentLegDefinitionRepeatingBlockList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One New Strategy Instrument Leg Definition Repeating Block of each kind, for the lists that carry them *)
OneNewStrategyInstrumentLegDefinitionRepeatingBlock == { ZeroNewStrategyInstrumentLegDefinitionRepeatingBlock }

(***************************************************************************)
(* New Strategy Instrument                                                 *)
(***************************************************************************)

NewStrategyInstrument ==
    [ incomingMessagesHeader                           : IncomingMessagesHeader10,
      newStrategyInstrumentLegDefinitionRepeatingBlock : SampleLists(OneNewStrategyInstrumentLegDefinitionRepeatingBlock) ]

EncodeNewStrategyInstrument(message) ==
    EncodeIncomingMessagesHeader10(message.incomingMessagesHeader)
        \o EncodeDigits(Len(message.newStrategyInstrumentLegDefinitionRepeatingBlock), 2)
        \o EncodeNewStrategyInstrumentLegDefinitionRepeatingBlockList(message.newStrategyInstrumentLegDefinitionRepeatingBlock)

DecodeNewStrategyInstrument(bytes) ==
    LET incomingMessagesHeader == DecodeIncomingMessagesHeader10(bytes) IN IF ~incomingMessagesHeader.ok THEN Fail ELSE
    LET numberOfLegs == ReadDigits(incomingMessagesHeader.rest, 2) IN IF ~numberOfLegs.ok THEN Fail ELSE
    LET newStrategyInstrumentLegDefinitionRepeatingBlock == ReadNewStrategyInstrumentLegDefinitionRepeatingBlockList(numberOfLegs.rest, numberOfLegs.value) IN IF ~newStrategyInstrumentLegDefinitionRepeatingBlock.ok THEN Fail ELSE
    Ok([ incomingMessagesHeader                           |-> incomingMessagesHeader.value,
         newStrategyInstrumentLegDefinitionRepeatingBlock |-> newStrategyInstrumentLegDefinitionRepeatingBlock.value ], newStrategyInstrumentLegDefinitionRepeatingBlock.rest)

ZeroNewStrategyInstrument ==
    [ incomingMessagesHeader                           |-> ZeroIncomingMessagesHeader10,
      newStrategyInstrumentLegDefinitionRepeatingBlock |-> << >> ]

(* New Strategy Instrument at zero, then each field in turn at the values it is checked at *)
CheckedNewStrategyInstrument ==
    { ZeroNewStrategyInstrument }
        \cup { [ZeroNewStrategyInstrument EXCEPT !.incomingMessagesHeader = one] : one \in CheckedIncomingMessagesHeader10 }
        \cup { [ZeroNewStrategyInstrument EXCEPT !.newStrategyInstrumentLegDefinitionRepeatingBlock = one] : one \in SampleLists(OneNewStrategyInstrumentLegDefinitionRepeatingBlock) }

(***************************************************************************)
(* Incoming Messages Header: 22 bytes                                      *)
(***************************************************************************)

IncomingMessagesHeader11 ==
    [ userTimestampLocalHhmmss : Sample(6),
      traderId                 : Sample(8),
      userSequenceId           : Sample(8) ]

EncodeIncomingMessagesHeader11(message) ==
    message.userTimestampLocalHhmmss
        \o message.traderId
        \o message.userSequenceId

DecodeIncomingMessagesHeader11(bytes) ==
    LET userTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~userTimestampLocalHhmmss.ok THEN Fail ELSE
    LET traderId == ReadBytes(userTimestampLocalHhmmss.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(traderId.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    Ok([ userTimestampLocalHhmmss |-> userTimestampLocalHhmmss.value,
         traderId                 |-> traderId.value,
         userSequenceId           |-> userSequenceId.value ], userSequenceId.rest)

ZeroIncomingMessagesHeader11 ==
    [ userTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      traderId                 |-> [i \in 1 .. 8 |-> 0],
      userSequenceId           |-> [i \in 1 .. 8 |-> 0] ]

(* Incoming Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedIncomingMessagesHeader11 ==
    { ZeroIncomingMessagesHeader11 }
        \cup { [ZeroIncomingMessagesHeader11 EXCEPT !.userTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroIncomingMessagesHeader11 EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroIncomingMessagesHeader11 EXCEPT !.userSequenceId = one] : one \in Sample(8) }

(***************************************************************************)
(* Buying Clearing Data: 20 bytes                                          *)
(***************************************************************************)

BuyingClearingData ==
    [ clearingInstruction : Sample(12),
      accountType         : Sample(1),
      openClose           : Sample(1),
      hedgeSpec           : Sample(1),
      filler5             : Sample(5) ]

EncodeBuyingClearingData(message) ==
    message.clearingInstruction
        \o message.accountType
        \o message.openClose
        \o message.hedgeSpec
        \o message.filler5

DecodeBuyingClearingData(bytes) ==
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

ZeroBuyingClearingData ==
    [ clearingInstruction |-> [i \in 1 .. 12 |-> 0],
      accountType         |-> [i \in 1 .. 1 |-> 0],
      openClose           |-> [i \in 1 .. 1 |-> 0],
      hedgeSpec           |-> [i \in 1 .. 1 |-> 0],
      filler5             |-> [i \in 1 .. 5 |-> 0] ]

(* Buying Clearing Data at zero, then each field in turn at the values it is checked at *)
CheckedBuyingClearingData ==
    { ZeroBuyingClearingData }
        \cup { [ZeroBuyingClearingData EXCEPT !.clearingInstruction = one] : one \in Sample(12) }
        \cup { [ZeroBuyingClearingData EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroBuyingClearingData EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroBuyingClearingData EXCEPT !.hedgeSpec = one] : one \in Sample(1) }
        \cup { [ZeroBuyingClearingData EXCEPT !.filler5 = one] : one \in Sample(5) }

(***************************************************************************)
(* Selling Clearing Data: 20 bytes                                         *)
(***************************************************************************)

SellingClearingData ==
    [ clearingInstruction : Sample(12),
      accountType         : Sample(1),
      openClose           : Sample(1),
      hedgeSpec           : Sample(1),
      filler5             : Sample(5) ]

EncodeSellingClearingData(message) ==
    message.clearingInstruction
        \o message.accountType
        \o message.openClose
        \o message.hedgeSpec
        \o message.filler5

DecodeSellingClearingData(bytes) ==
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

ZeroSellingClearingData ==
    [ clearingInstruction |-> [i \in 1 .. 12 |-> 0],
      accountType         |-> [i \in 1 .. 1 |-> 0],
      openClose           |-> [i \in 1 .. 1 |-> 0],
      hedgeSpec           |-> [i \in 1 .. 1 |-> 0],
      filler5             |-> [i \in 1 .. 5 |-> 0] ]

(* Selling Clearing Data at zero, then each field in turn at the values it is checked at *)
CheckedSellingClearingData ==
    { ZeroSellingClearingData }
        \cup { [ZeroSellingClearingData EXCEPT !.clearingInstruction = one] : one \in Sample(12) }
        \cup { [ZeroSellingClearingData EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroSellingClearingData EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroSellingClearingData EXCEPT !.hedgeSpec = one] : one \in Sample(1) }
        \cup { [ZeroSellingClearingData EXCEPT !.filler5 = one] : one \in Sample(5) }

(***************************************************************************)
(* Buying Owner Data: 50 bytes                                             *)
(***************************************************************************)

BuyingOwnerData ==
    [ memo : Sample(50) ]

EncodeBuyingOwnerData(message) ==
    message.memo

DecodeBuyingOwnerData(bytes) ==
    LET memo == ReadBytes(bytes, 50) IN IF ~memo.ok THEN Fail ELSE
    Ok([ memo |-> memo.value ], memo.rest)

ZeroBuyingOwnerData ==
    [ memo |-> [i \in 1 .. 50 |-> 0] ]

(* Buying Owner Data at zero, then each field in turn at the values it is checked at *)
CheckedBuyingOwnerData ==
    { ZeroBuyingOwnerData }
        \cup { [ZeroBuyingOwnerData EXCEPT !.memo = one] : one \in Sample(50) }

(***************************************************************************)
(* Selling Owner Data: 50 bytes                                            *)
(***************************************************************************)

SellingOwnerData ==
    [ memo : Sample(50) ]

EncodeSellingOwnerData(message) ==
    message.memo

DecodeSellingOwnerData(bytes) ==
    LET memo == ReadBytes(bytes, 50) IN IF ~memo.ok THEN Fail ELSE
    Ok([ memo |-> memo.value ], memo.rest)

ZeroSellingOwnerData ==
    [ memo |-> [i \in 1 .. 50 |-> 0] ]

(* Selling Owner Data at zero, then each field in turn at the values it is checked at *)
CheckedSellingOwnerData ==
    { ZeroSellingOwnerData }
        \cup { [ZeroSellingOwnerData EXCEPT !.memo = one] : one \in Sample(50) }

(***************************************************************************)
(* Cross Entry: 207 bytes                                                  *)
(***************************************************************************)

CrossEntry ==
    [ incomingMessagesHeader : IncomingMessagesHeader11,
      group                  : Sample(2),
      instrument             : Sample(4),
      filler1                : Sample(1),
      quantity               : Sample(8),
      price                  : Sample(10),
      buyingClearingData     : BuyingClearingData,
      sellingClearingData    : SellingClearingData,
      buyingOwnerData        : BuyingOwnerData,
      sellingOwnerData       : SellingOwnerData,
      filler20               : Sample(20) ]

EncodeCrossEntry(message) ==
    EncodeIncomingMessagesHeader11(message.incomingMessagesHeader)
        \o message.group
        \o message.instrument
        \o message.filler1
        \o message.quantity
        \o message.price
        \o EncodeBuyingClearingData(message.buyingClearingData)
        \o EncodeSellingClearingData(message.sellingClearingData)
        \o EncodeBuyingOwnerData(message.buyingOwnerData)
        \o EncodeSellingOwnerData(message.sellingOwnerData)
        \o message.filler20

DecodeCrossEntry(bytes) ==
    LET incomingMessagesHeader == DecodeIncomingMessagesHeader11(bytes) IN IF ~incomingMessagesHeader.ok THEN Fail ELSE
    LET group == ReadBytes(incomingMessagesHeader.rest, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrument == ReadBytes(group.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET filler1 == ReadBytes(instrument.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET quantity == ReadBytes(filler1.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 10) IN IF ~price.ok THEN Fail ELSE
    LET buyingClearingData == DecodeBuyingClearingData(price.rest) IN IF ~buyingClearingData.ok THEN Fail ELSE
    LET sellingClearingData == DecodeSellingClearingData(buyingClearingData.rest) IN IF ~sellingClearingData.ok THEN Fail ELSE
    LET buyingOwnerData == DecodeBuyingOwnerData(sellingClearingData.rest) IN IF ~buyingOwnerData.ok THEN Fail ELSE
    LET sellingOwnerData == DecodeSellingOwnerData(buyingOwnerData.rest) IN IF ~sellingOwnerData.ok THEN Fail ELSE
    LET filler20 == ReadBytes(sellingOwnerData.rest, 20) IN IF ~filler20.ok THEN Fail ELSE
    Ok([ incomingMessagesHeader |-> incomingMessagesHeader.value,
         group                  |-> group.value,
         instrument             |-> instrument.value,
         filler1                |-> filler1.value,
         quantity               |-> quantity.value,
         price                  |-> price.value,
         buyingClearingData     |-> buyingClearingData.value,
         sellingClearingData    |-> sellingClearingData.value,
         buyingOwnerData        |-> buyingOwnerData.value,
         sellingOwnerData       |-> sellingOwnerData.value,
         filler20               |-> filler20.value ], filler20.rest)

ZeroCrossEntry ==
    [ incomingMessagesHeader |-> ZeroIncomingMessagesHeader11,
      group                  |-> [i \in 1 .. 2 |-> 0],
      instrument             |-> [i \in 1 .. 4 |-> 0],
      filler1                |-> [i \in 1 .. 1 |-> 0],
      quantity               |-> [i \in 1 .. 8 |-> 0],
      price                  |-> [i \in 1 .. 10 |-> 0],
      buyingClearingData     |-> ZeroBuyingClearingData,
      sellingClearingData    |-> ZeroSellingClearingData,
      buyingOwnerData        |-> ZeroBuyingOwnerData,
      sellingOwnerData       |-> ZeroSellingOwnerData,
      filler20               |-> [i \in 1 .. 20 |-> 0] ]

(* Cross Entry at zero, then each field in turn at the values it is checked at *)
CheckedCrossEntry ==
    { ZeroCrossEntry }
        \cup { [ZeroCrossEntry EXCEPT !.incomingMessagesHeader = one] : one \in CheckedIncomingMessagesHeader11 }
        \cup { [ZeroCrossEntry EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroCrossEntry EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroCrossEntry EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroCrossEntry EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroCrossEntry EXCEPT !.price = one] : one \in Sample(10) }
        \cup { [ZeroCrossEntry EXCEPT !.buyingClearingData = one] : one \in CheckedBuyingClearingData }
        \cup { [ZeroCrossEntry EXCEPT !.sellingClearingData = one] : one \in CheckedSellingClearingData }
        \cup { [ZeroCrossEntry EXCEPT !.buyingOwnerData = one] : one \in CheckedBuyingOwnerData }
        \cup { [ZeroCrossEntry EXCEPT !.sellingOwnerData = one] : one \in CheckedSellingOwnerData }
        \cup { [ZeroCrossEntry EXCEPT !.filler20 = one] : one \in Sample(20) }

(***************************************************************************)
(* Incoming Messages Header: 22 bytes                                      *)
(***************************************************************************)

IncomingMessagesHeader12 ==
    [ userTimestampLocalHhmmss : Sample(6),
      traderId                 : Sample(8),
      userSequenceId           : Sample(8) ]

EncodeIncomingMessagesHeader12(message) ==
    message.userTimestampLocalHhmmss
        \o message.traderId
        \o message.userSequenceId

DecodeIncomingMessagesHeader12(bytes) ==
    LET userTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~userTimestampLocalHhmmss.ok THEN Fail ELSE
    LET traderId == ReadBytes(userTimestampLocalHhmmss.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(traderId.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    Ok([ userTimestampLocalHhmmss |-> userTimestampLocalHhmmss.value,
         traderId                 |-> traderId.value,
         userSequenceId           |-> userSequenceId.value ], userSequenceId.rest)

ZeroIncomingMessagesHeader12 ==
    [ userTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      traderId                 |-> [i \in 1 .. 8 |-> 0],
      userSequenceId           |-> [i \in 1 .. 8 |-> 0] ]

(* Incoming Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedIncomingMessagesHeader12 ==
    { ZeroIncomingMessagesHeader12 }
        \cup { [ZeroIncomingMessagesHeader12 EXCEPT !.userTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroIncomingMessagesHeader12 EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroIncomingMessagesHeader12 EXCEPT !.userSequenceId = one] : one \in Sample(8) }

(***************************************************************************)
(* Bulk Quote Price 4 Quantity 2 Occurrence: 14 bytes                      *)
(***************************************************************************)

BulkQuotePrice4Quantity2Occurrence ==
    [ group          : Sample(2),
      instrument     : Sample(4),
      verbSide       : Sample(1),
      quantitySignOr : Sample(1),
      quantity2      : Sample(2),
      price4         : Sample(4) ]

EncodeBulkQuotePrice4Quantity2Occurrence(message) ==
    message.group
        \o message.instrument
        \o message.verbSide
        \o message.quantitySignOr
        \o message.quantity2
        \o message.price4

DecodeBulkQuotePrice4Quantity2Occurrence(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrument == ReadBytes(group.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET verbSide == ReadBytes(instrument.rest, 1) IN IF ~verbSide.ok THEN Fail ELSE
    LET quantitySignOr == ReadBytes(verbSide.rest, 1) IN IF ~quantitySignOr.ok THEN Fail ELSE
    LET quantity2 == ReadBytes(quantitySignOr.rest, 2) IN IF ~quantity2.ok THEN Fail ELSE
    LET price4 == ReadBytes(quantity2.rest, 4) IN IF ~price4.ok THEN Fail ELSE
    Ok([ group          |-> group.value,
         instrument     |-> instrument.value,
         verbSide       |-> verbSide.value,
         quantitySignOr |-> quantitySignOr.value,
         quantity2      |-> quantity2.value,
         price4         |-> price4.value ], price4.rest)

ZeroBulkQuotePrice4Quantity2Occurrence ==
    [ group          |-> [i \in 1 .. 2 |-> 0],
      instrument     |-> [i \in 1 .. 4 |-> 0],
      verbSide       |-> [i \in 1 .. 1 |-> 0],
      quantitySignOr |-> [i \in 1 .. 1 |-> 0],
      quantity2      |-> [i \in 1 .. 2 |-> 0],
      price4         |-> [i \in 1 .. 4 |-> 0] ]

(* Bulk Quote Price 4 Quantity 2 Occurrence at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuotePrice4Quantity2Occurrence ==
    { ZeroBulkQuotePrice4Quantity2Occurrence }
        \cup { [ZeroBulkQuotePrice4Quantity2Occurrence EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuotePrice4Quantity2Occurrence EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroBulkQuotePrice4Quantity2Occurrence EXCEPT !.verbSide = one] : one \in Sample(1) }
        \cup { [ZeroBulkQuotePrice4Quantity2Occurrence EXCEPT !.quantitySignOr = one] : one \in Sample(1) }
        \cup { [ZeroBulkQuotePrice4Quantity2Occurrence EXCEPT !.quantity2 = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuotePrice4Quantity2Occurrence EXCEPT !.price4 = one] : one \in Sample(4) }

(* A run of Bulk Quote Price 4 Quantity 2 Occurrence, written one after another *)
RECURSIVE EncodeBulkQuotePrice4Quantity2OccurrenceList(_)
EncodeBulkQuotePrice4Quantity2OccurrenceList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeBulkQuotePrice4Quantity2Occurrence(Head(messages)) \o EncodeBulkQuotePrice4Quantity2OccurrenceList(Tail(messages))

(* As many Bulk Quote Price 4 Quantity 2 Occurrence as the field that counts them says *)
RECURSIVE ReadBulkQuotePrice4Quantity2OccurrenceList(_, _)
ReadBulkQuotePrice4Quantity2OccurrenceList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeBulkQuotePrice4Quantity2Occurrence(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadBulkQuotePrice4Quantity2OccurrenceList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Bulk Quote Price 4 Quantity 2 Occurrence of each kind, for the lists that carry them *)
OneBulkQuotePrice4Quantity2Occurrence == { ZeroBulkQuotePrice4Quantity2Occurrence }

(***************************************************************************)
(* Bulk Quote Price 4 Quantity 2                                           *)
(***************************************************************************)

BulkQuotePrice4Quantity2 ==
    [ incomingMessagesHeader             : IncomingMessagesHeader12,
      group                              : Sample(2),
      quoteIdentifierOnThisGroup         : Sample(8),
      bulkQuotePrice4Quantity2Occurrence : SampleLists(OneBulkQuotePrice4Quantity2Occurrence) ]

EncodeBulkQuotePrice4Quantity2(message) ==
    EncodeIncomingMessagesHeader12(message.incomingMessagesHeader)
        \o message.group
        \o message.quoteIdentifierOnThisGroup
        \o EncodeDigits(Len(message.bulkQuotePrice4Quantity2Occurrence), 3)
        \o EncodeBulkQuotePrice4Quantity2OccurrenceList(message.bulkQuotePrice4Quantity2Occurrence)

DecodeBulkQuotePrice4Quantity2(bytes) ==
    LET incomingMessagesHeader == DecodeIncomingMessagesHeader12(bytes) IN IF ~incomingMessagesHeader.ok THEN Fail ELSE
    LET group == ReadBytes(incomingMessagesHeader.rest, 2) IN IF ~group.ok THEN Fail ELSE
    LET quoteIdentifierOnThisGroup == ReadBytes(group.rest, 8) IN IF ~quoteIdentifierOnThisGroup.ok THEN Fail ELSE
    LET numberOfQuotes == ReadDigits(quoteIdentifierOnThisGroup.rest, 3) IN IF ~numberOfQuotes.ok THEN Fail ELSE
    LET bulkQuotePrice4Quantity2Occurrence == ReadBulkQuotePrice4Quantity2OccurrenceList(numberOfQuotes.rest, numberOfQuotes.value) IN IF ~bulkQuotePrice4Quantity2Occurrence.ok THEN Fail ELSE
    Ok([ incomingMessagesHeader             |-> incomingMessagesHeader.value,
         group                              |-> group.value,
         quoteIdentifierOnThisGroup         |-> quoteIdentifierOnThisGroup.value,
         bulkQuotePrice4Quantity2Occurrence |-> bulkQuotePrice4Quantity2Occurrence.value ], bulkQuotePrice4Quantity2Occurrence.rest)

ZeroBulkQuotePrice4Quantity2 ==
    [ incomingMessagesHeader             |-> ZeroIncomingMessagesHeader12,
      group                              |-> [i \in 1 .. 2 |-> 0],
      quoteIdentifierOnThisGroup         |-> [i \in 1 .. 8 |-> 0],
      bulkQuotePrice4Quantity2Occurrence |-> << >> ]

(* Bulk Quote Price 4 Quantity 2 at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuotePrice4Quantity2 ==
    { ZeroBulkQuotePrice4Quantity2 }
        \cup { [ZeroBulkQuotePrice4Quantity2 EXCEPT !.incomingMessagesHeader = one] : one \in CheckedIncomingMessagesHeader12 }
        \cup { [ZeroBulkQuotePrice4Quantity2 EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuotePrice4Quantity2 EXCEPT !.quoteIdentifierOnThisGroup = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuotePrice4Quantity2 EXCEPT !.bulkQuotePrice4Quantity2Occurrence = one] : one \in SampleLists(OneBulkQuotePrice4Quantity2Occurrence) }

(***************************************************************************)
(* Incoming Messages Header: 22 bytes                                      *)
(***************************************************************************)

IncomingMessagesHeader13 ==
    [ userTimestampLocalHhmmss : Sample(6),
      traderId                 : Sample(8),
      userSequenceId           : Sample(8) ]

EncodeIncomingMessagesHeader13(message) ==
    message.userTimestampLocalHhmmss
        \o message.traderId
        \o message.userSequenceId

DecodeIncomingMessagesHeader13(bytes) ==
    LET userTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~userTimestampLocalHhmmss.ok THEN Fail ELSE
    LET traderId == ReadBytes(userTimestampLocalHhmmss.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(traderId.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    Ok([ userTimestampLocalHhmmss |-> userTimestampLocalHhmmss.value,
         traderId                 |-> traderId.value,
         userSequenceId           |-> userSequenceId.value ], userSequenceId.rest)

ZeroIncomingMessagesHeader13 ==
    [ userTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      traderId                 |-> [i \in 1 .. 8 |-> 0],
      userSequenceId           |-> [i \in 1 .. 8 |-> 0] ]

(* Incoming Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedIncomingMessagesHeader13 ==
    { ZeroIncomingMessagesHeader13 }
        \cup { [ZeroIncomingMessagesHeader13 EXCEPT !.userTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroIncomingMessagesHeader13 EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroIncomingMessagesHeader13 EXCEPT !.userSequenceId = one] : one \in Sample(8) }

(***************************************************************************)
(* Bulk Quote Price 6 Quantity 2 Occurrence: 16 bytes                      *)
(***************************************************************************)

BulkQuotePrice6Quantity2Occurrence ==
    [ group          : Sample(2),
      instrument     : Sample(4),
      verbSide       : Sample(1),
      quantitySignOr : Sample(1),
      quantity2      : Sample(2),
      price6         : Sample(6) ]

EncodeBulkQuotePrice6Quantity2Occurrence(message) ==
    message.group
        \o message.instrument
        \o message.verbSide
        \o message.quantitySignOr
        \o message.quantity2
        \o message.price6

DecodeBulkQuotePrice6Quantity2Occurrence(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrument == ReadBytes(group.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET verbSide == ReadBytes(instrument.rest, 1) IN IF ~verbSide.ok THEN Fail ELSE
    LET quantitySignOr == ReadBytes(verbSide.rest, 1) IN IF ~quantitySignOr.ok THEN Fail ELSE
    LET quantity2 == ReadBytes(quantitySignOr.rest, 2) IN IF ~quantity2.ok THEN Fail ELSE
    LET price6 == ReadBytes(quantity2.rest, 6) IN IF ~price6.ok THEN Fail ELSE
    Ok([ group          |-> group.value,
         instrument     |-> instrument.value,
         verbSide       |-> verbSide.value,
         quantitySignOr |-> quantitySignOr.value,
         quantity2      |-> quantity2.value,
         price6         |-> price6.value ], price6.rest)

ZeroBulkQuotePrice6Quantity2Occurrence ==
    [ group          |-> [i \in 1 .. 2 |-> 0],
      instrument     |-> [i \in 1 .. 4 |-> 0],
      verbSide       |-> [i \in 1 .. 1 |-> 0],
      quantitySignOr |-> [i \in 1 .. 1 |-> 0],
      quantity2      |-> [i \in 1 .. 2 |-> 0],
      price6         |-> [i \in 1 .. 6 |-> 0] ]

(* Bulk Quote Price 6 Quantity 2 Occurrence at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuotePrice6Quantity2Occurrence ==
    { ZeroBulkQuotePrice6Quantity2Occurrence }
        \cup { [ZeroBulkQuotePrice6Quantity2Occurrence EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuotePrice6Quantity2Occurrence EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroBulkQuotePrice6Quantity2Occurrence EXCEPT !.verbSide = one] : one \in Sample(1) }
        \cup { [ZeroBulkQuotePrice6Quantity2Occurrence EXCEPT !.quantitySignOr = one] : one \in Sample(1) }
        \cup { [ZeroBulkQuotePrice6Quantity2Occurrence EXCEPT !.quantity2 = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuotePrice6Quantity2Occurrence EXCEPT !.price6 = one] : one \in Sample(6) }

(* A run of Bulk Quote Price 6 Quantity 2 Occurrence, written one after another *)
RECURSIVE EncodeBulkQuotePrice6Quantity2OccurrenceList(_)
EncodeBulkQuotePrice6Quantity2OccurrenceList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeBulkQuotePrice6Quantity2Occurrence(Head(messages)) \o EncodeBulkQuotePrice6Quantity2OccurrenceList(Tail(messages))

(* As many Bulk Quote Price 6 Quantity 2 Occurrence as the field that counts them says *)
RECURSIVE ReadBulkQuotePrice6Quantity2OccurrenceList(_, _)
ReadBulkQuotePrice6Quantity2OccurrenceList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeBulkQuotePrice6Quantity2Occurrence(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadBulkQuotePrice6Quantity2OccurrenceList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Bulk Quote Price 6 Quantity 2 Occurrence of each kind, for the lists that carry them *)
OneBulkQuotePrice6Quantity2Occurrence == { ZeroBulkQuotePrice6Quantity2Occurrence }

(***************************************************************************)
(* Bulk Quote Price 6 Quantity 2                                           *)
(***************************************************************************)

BulkQuotePrice6Quantity2 ==
    [ incomingMessagesHeader             : IncomingMessagesHeader13,
      group                              : Sample(2),
      quoteIdentifierOnThisGroup         : Sample(8),
      bulkQuotePrice6Quantity2Occurrence : SampleLists(OneBulkQuotePrice6Quantity2Occurrence) ]

EncodeBulkQuotePrice6Quantity2(message) ==
    EncodeIncomingMessagesHeader13(message.incomingMessagesHeader)
        \o message.group
        \o message.quoteIdentifierOnThisGroup
        \o EncodeDigits(Len(message.bulkQuotePrice6Quantity2Occurrence), 3)
        \o EncodeBulkQuotePrice6Quantity2OccurrenceList(message.bulkQuotePrice6Quantity2Occurrence)

DecodeBulkQuotePrice6Quantity2(bytes) ==
    LET incomingMessagesHeader == DecodeIncomingMessagesHeader13(bytes) IN IF ~incomingMessagesHeader.ok THEN Fail ELSE
    LET group == ReadBytes(incomingMessagesHeader.rest, 2) IN IF ~group.ok THEN Fail ELSE
    LET quoteIdentifierOnThisGroup == ReadBytes(group.rest, 8) IN IF ~quoteIdentifierOnThisGroup.ok THEN Fail ELSE
    LET numberOfQuotes == ReadDigits(quoteIdentifierOnThisGroup.rest, 3) IN IF ~numberOfQuotes.ok THEN Fail ELSE
    LET bulkQuotePrice6Quantity2Occurrence == ReadBulkQuotePrice6Quantity2OccurrenceList(numberOfQuotes.rest, numberOfQuotes.value) IN IF ~bulkQuotePrice6Quantity2Occurrence.ok THEN Fail ELSE
    Ok([ incomingMessagesHeader             |-> incomingMessagesHeader.value,
         group                              |-> group.value,
         quoteIdentifierOnThisGroup         |-> quoteIdentifierOnThisGroup.value,
         bulkQuotePrice6Quantity2Occurrence |-> bulkQuotePrice6Quantity2Occurrence.value ], bulkQuotePrice6Quantity2Occurrence.rest)

ZeroBulkQuotePrice6Quantity2 ==
    [ incomingMessagesHeader             |-> ZeroIncomingMessagesHeader13,
      group                              |-> [i \in 1 .. 2 |-> 0],
      quoteIdentifierOnThisGroup         |-> [i \in 1 .. 8 |-> 0],
      bulkQuotePrice6Quantity2Occurrence |-> << >> ]

(* Bulk Quote Price 6 Quantity 2 at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuotePrice6Quantity2 ==
    { ZeroBulkQuotePrice6Quantity2 }
        \cup { [ZeroBulkQuotePrice6Quantity2 EXCEPT !.incomingMessagesHeader = one] : one \in CheckedIncomingMessagesHeader13 }
        \cup { [ZeroBulkQuotePrice6Quantity2 EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuotePrice6Quantity2 EXCEPT !.quoteIdentifierOnThisGroup = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuotePrice6Quantity2 EXCEPT !.bulkQuotePrice6Quantity2Occurrence = one] : one \in SampleLists(OneBulkQuotePrice6Quantity2Occurrence) }

(***************************************************************************)
(* Incoming Messages Header: 22 bytes                                      *)
(***************************************************************************)

IncomingMessagesHeader14 ==
    [ userTimestampLocalHhmmss : Sample(6),
      traderId                 : Sample(8),
      userSequenceId           : Sample(8) ]

EncodeIncomingMessagesHeader14(message) ==
    message.userTimestampLocalHhmmss
        \o message.traderId
        \o message.userSequenceId

DecodeIncomingMessagesHeader14(bytes) ==
    LET userTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~userTimestampLocalHhmmss.ok THEN Fail ELSE
    LET traderId == ReadBytes(userTimestampLocalHhmmss.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(traderId.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    Ok([ userTimestampLocalHhmmss |-> userTimestampLocalHhmmss.value,
         traderId                 |-> traderId.value,
         userSequenceId           |-> userSequenceId.value ], userSequenceId.rest)

ZeroIncomingMessagesHeader14 ==
    [ userTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      traderId                 |-> [i \in 1 .. 8 |-> 0],
      userSequenceId           |-> [i \in 1 .. 8 |-> 0] ]

(* Incoming Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedIncomingMessagesHeader14 ==
    { ZeroIncomingMessagesHeader14 }
        \cup { [ZeroIncomingMessagesHeader14 EXCEPT !.userTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroIncomingMessagesHeader14 EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroIncomingMessagesHeader14 EXCEPT !.userSequenceId = one] : one \in Sample(8) }

(***************************************************************************)
(* Bulk Quote Price 8 Quantity 2 Occurrence: 18 bytes                      *)
(***************************************************************************)

BulkQuotePrice8Quantity2Occurrence ==
    [ group          : Sample(2),
      instrument     : Sample(4),
      verbSide       : Sample(1),
      quantitySignOr : Sample(1),
      quantity2      : Sample(2),
      price8         : Sample(8) ]

EncodeBulkQuotePrice8Quantity2Occurrence(message) ==
    message.group
        \o message.instrument
        \o message.verbSide
        \o message.quantitySignOr
        \o message.quantity2
        \o message.price8

DecodeBulkQuotePrice8Quantity2Occurrence(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrument == ReadBytes(group.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET verbSide == ReadBytes(instrument.rest, 1) IN IF ~verbSide.ok THEN Fail ELSE
    LET quantitySignOr == ReadBytes(verbSide.rest, 1) IN IF ~quantitySignOr.ok THEN Fail ELSE
    LET quantity2 == ReadBytes(quantitySignOr.rest, 2) IN IF ~quantity2.ok THEN Fail ELSE
    LET price8 == ReadBytes(quantity2.rest, 8) IN IF ~price8.ok THEN Fail ELSE
    Ok([ group          |-> group.value,
         instrument     |-> instrument.value,
         verbSide       |-> verbSide.value,
         quantitySignOr |-> quantitySignOr.value,
         quantity2      |-> quantity2.value,
         price8         |-> price8.value ], price8.rest)

ZeroBulkQuotePrice8Quantity2Occurrence ==
    [ group          |-> [i \in 1 .. 2 |-> 0],
      instrument     |-> [i \in 1 .. 4 |-> 0],
      verbSide       |-> [i \in 1 .. 1 |-> 0],
      quantitySignOr |-> [i \in 1 .. 1 |-> 0],
      quantity2      |-> [i \in 1 .. 2 |-> 0],
      price8         |-> [i \in 1 .. 8 |-> 0] ]

(* Bulk Quote Price 8 Quantity 2 Occurrence at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuotePrice8Quantity2Occurrence ==
    { ZeroBulkQuotePrice8Quantity2Occurrence }
        \cup { [ZeroBulkQuotePrice8Quantity2Occurrence EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuotePrice8Quantity2Occurrence EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroBulkQuotePrice8Quantity2Occurrence EXCEPT !.verbSide = one] : one \in Sample(1) }
        \cup { [ZeroBulkQuotePrice8Quantity2Occurrence EXCEPT !.quantitySignOr = one] : one \in Sample(1) }
        \cup { [ZeroBulkQuotePrice8Quantity2Occurrence EXCEPT !.quantity2 = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuotePrice8Quantity2Occurrence EXCEPT !.price8 = one] : one \in Sample(8) }

(* A run of Bulk Quote Price 8 Quantity 2 Occurrence, written one after another *)
RECURSIVE EncodeBulkQuotePrice8Quantity2OccurrenceList(_)
EncodeBulkQuotePrice8Quantity2OccurrenceList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeBulkQuotePrice8Quantity2Occurrence(Head(messages)) \o EncodeBulkQuotePrice8Quantity2OccurrenceList(Tail(messages))

(* As many Bulk Quote Price 8 Quantity 2 Occurrence as the field that counts them says *)
RECURSIVE ReadBulkQuotePrice8Quantity2OccurrenceList(_, _)
ReadBulkQuotePrice8Quantity2OccurrenceList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeBulkQuotePrice8Quantity2Occurrence(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadBulkQuotePrice8Quantity2OccurrenceList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Bulk Quote Price 8 Quantity 2 Occurrence of each kind, for the lists that carry them *)
OneBulkQuotePrice8Quantity2Occurrence == { ZeroBulkQuotePrice8Quantity2Occurrence }

(***************************************************************************)
(* Bulk Quote Price 8 Quantity 2                                           *)
(***************************************************************************)

BulkQuotePrice8Quantity2 ==
    [ incomingMessagesHeader             : IncomingMessagesHeader14,
      group                              : Sample(2),
      quoteIdentifierOnThisGroup         : Sample(8),
      bulkQuotePrice8Quantity2Occurrence : SampleLists(OneBulkQuotePrice8Quantity2Occurrence) ]

EncodeBulkQuotePrice8Quantity2(message) ==
    EncodeIncomingMessagesHeader14(message.incomingMessagesHeader)
        \o message.group
        \o message.quoteIdentifierOnThisGroup
        \o EncodeDigits(Len(message.bulkQuotePrice8Quantity2Occurrence), 3)
        \o EncodeBulkQuotePrice8Quantity2OccurrenceList(message.bulkQuotePrice8Quantity2Occurrence)

DecodeBulkQuotePrice8Quantity2(bytes) ==
    LET incomingMessagesHeader == DecodeIncomingMessagesHeader14(bytes) IN IF ~incomingMessagesHeader.ok THEN Fail ELSE
    LET group == ReadBytes(incomingMessagesHeader.rest, 2) IN IF ~group.ok THEN Fail ELSE
    LET quoteIdentifierOnThisGroup == ReadBytes(group.rest, 8) IN IF ~quoteIdentifierOnThisGroup.ok THEN Fail ELSE
    LET numberOfQuotes == ReadDigits(quoteIdentifierOnThisGroup.rest, 3) IN IF ~numberOfQuotes.ok THEN Fail ELSE
    LET bulkQuotePrice8Quantity2Occurrence == ReadBulkQuotePrice8Quantity2OccurrenceList(numberOfQuotes.rest, numberOfQuotes.value) IN IF ~bulkQuotePrice8Quantity2Occurrence.ok THEN Fail ELSE
    Ok([ incomingMessagesHeader             |-> incomingMessagesHeader.value,
         group                              |-> group.value,
         quoteIdentifierOnThisGroup         |-> quoteIdentifierOnThisGroup.value,
         bulkQuotePrice8Quantity2Occurrence |-> bulkQuotePrice8Quantity2Occurrence.value ], bulkQuotePrice8Quantity2Occurrence.rest)

ZeroBulkQuotePrice8Quantity2 ==
    [ incomingMessagesHeader             |-> ZeroIncomingMessagesHeader14,
      group                              |-> [i \in 1 .. 2 |-> 0],
      quoteIdentifierOnThisGroup         |-> [i \in 1 .. 8 |-> 0],
      bulkQuotePrice8Quantity2Occurrence |-> << >> ]

(* Bulk Quote Price 8 Quantity 2 at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuotePrice8Quantity2 ==
    { ZeroBulkQuotePrice8Quantity2 }
        \cup { [ZeroBulkQuotePrice8Quantity2 EXCEPT !.incomingMessagesHeader = one] : one \in CheckedIncomingMessagesHeader14 }
        \cup { [ZeroBulkQuotePrice8Quantity2 EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuotePrice8Quantity2 EXCEPT !.quoteIdentifierOnThisGroup = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuotePrice8Quantity2 EXCEPT !.bulkQuotePrice8Quantity2Occurrence = one] : one \in SampleLists(OneBulkQuotePrice8Quantity2Occurrence) }

(***************************************************************************)
(* Incoming Messages Header: 22 bytes                                      *)
(***************************************************************************)

IncomingMessagesHeader15 ==
    [ userTimestampLocalHhmmss : Sample(6),
      traderId                 : Sample(8),
      userSequenceId           : Sample(8) ]

EncodeIncomingMessagesHeader15(message) ==
    message.userTimestampLocalHhmmss
        \o message.traderId
        \o message.userSequenceId

DecodeIncomingMessagesHeader15(bytes) ==
    LET userTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~userTimestampLocalHhmmss.ok THEN Fail ELSE
    LET traderId == ReadBytes(userTimestampLocalHhmmss.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(traderId.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    Ok([ userTimestampLocalHhmmss |-> userTimestampLocalHhmmss.value,
         traderId                 |-> traderId.value,
         userSequenceId           |-> userSequenceId.value ], userSequenceId.rest)

ZeroIncomingMessagesHeader15 ==
    [ userTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      traderId                 |-> [i \in 1 .. 8 |-> 0],
      userSequenceId           |-> [i \in 1 .. 8 |-> 0] ]

(* Incoming Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedIncomingMessagesHeader15 ==
    { ZeroIncomingMessagesHeader15 }
        \cup { [ZeroIncomingMessagesHeader15 EXCEPT !.userTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroIncomingMessagesHeader15 EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroIncomingMessagesHeader15 EXCEPT !.userSequenceId = one] : one \in Sample(8) }

(***************************************************************************)
(* Bulk Quote Price 10 Quantity 2 Occurrence: 20 bytes                     *)
(***************************************************************************)

BulkQuotePrice10Quantity2Occurrence ==
    [ group          : Sample(2),
      instrument     : Sample(4),
      verbSide       : Sample(1),
      quantitySignOr : Sample(1),
      quantity2      : Sample(2),
      price          : Sample(10) ]

EncodeBulkQuotePrice10Quantity2Occurrence(message) ==
    message.group
        \o message.instrument
        \o message.verbSide
        \o message.quantitySignOr
        \o message.quantity2
        \o message.price

DecodeBulkQuotePrice10Quantity2Occurrence(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrument == ReadBytes(group.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET verbSide == ReadBytes(instrument.rest, 1) IN IF ~verbSide.ok THEN Fail ELSE
    LET quantitySignOr == ReadBytes(verbSide.rest, 1) IN IF ~quantitySignOr.ok THEN Fail ELSE
    LET quantity2 == ReadBytes(quantitySignOr.rest, 2) IN IF ~quantity2.ok THEN Fail ELSE
    LET price == ReadBytes(quantity2.rest, 10) IN IF ~price.ok THEN Fail ELSE
    Ok([ group          |-> group.value,
         instrument     |-> instrument.value,
         verbSide       |-> verbSide.value,
         quantitySignOr |-> quantitySignOr.value,
         quantity2      |-> quantity2.value,
         price          |-> price.value ], price.rest)

ZeroBulkQuotePrice10Quantity2Occurrence ==
    [ group          |-> [i \in 1 .. 2 |-> 0],
      instrument     |-> [i \in 1 .. 4 |-> 0],
      verbSide       |-> [i \in 1 .. 1 |-> 0],
      quantitySignOr |-> [i \in 1 .. 1 |-> 0],
      quantity2      |-> [i \in 1 .. 2 |-> 0],
      price          |-> [i \in 1 .. 10 |-> 0] ]

(* Bulk Quote Price 10 Quantity 2 Occurrence at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuotePrice10Quantity2Occurrence ==
    { ZeroBulkQuotePrice10Quantity2Occurrence }
        \cup { [ZeroBulkQuotePrice10Quantity2Occurrence EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuotePrice10Quantity2Occurrence EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroBulkQuotePrice10Quantity2Occurrence EXCEPT !.verbSide = one] : one \in Sample(1) }
        \cup { [ZeroBulkQuotePrice10Quantity2Occurrence EXCEPT !.quantitySignOr = one] : one \in Sample(1) }
        \cup { [ZeroBulkQuotePrice10Quantity2Occurrence EXCEPT !.quantity2 = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuotePrice10Quantity2Occurrence EXCEPT !.price = one] : one \in Sample(10) }

(* A run of Bulk Quote Price 10 Quantity 2 Occurrence, written one after another *)
RECURSIVE EncodeBulkQuotePrice10Quantity2OccurrenceList(_)
EncodeBulkQuotePrice10Quantity2OccurrenceList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeBulkQuotePrice10Quantity2Occurrence(Head(messages)) \o EncodeBulkQuotePrice10Quantity2OccurrenceList(Tail(messages))

(* As many Bulk Quote Price 10 Quantity 2 Occurrence as the field that counts them says *)
RECURSIVE ReadBulkQuotePrice10Quantity2OccurrenceList(_, _)
ReadBulkQuotePrice10Quantity2OccurrenceList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeBulkQuotePrice10Quantity2Occurrence(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadBulkQuotePrice10Quantity2OccurrenceList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Bulk Quote Price 10 Quantity 2 Occurrence of each kind, for the lists that carry them *)
OneBulkQuotePrice10Quantity2Occurrence == { ZeroBulkQuotePrice10Quantity2Occurrence }

(***************************************************************************)
(* Bulk Quote Price 10 Quantity 2                                          *)
(***************************************************************************)

BulkQuotePrice10Quantity2 ==
    [ incomingMessagesHeader              : IncomingMessagesHeader15,
      group                               : Sample(2),
      quoteIdentifierOnThisGroup          : Sample(8),
      bulkQuotePrice10Quantity2Occurrence : SampleLists(OneBulkQuotePrice10Quantity2Occurrence) ]

EncodeBulkQuotePrice10Quantity2(message) ==
    EncodeIncomingMessagesHeader15(message.incomingMessagesHeader)
        \o message.group
        \o message.quoteIdentifierOnThisGroup
        \o EncodeDigits(Len(message.bulkQuotePrice10Quantity2Occurrence), 3)
        \o EncodeBulkQuotePrice10Quantity2OccurrenceList(message.bulkQuotePrice10Quantity2Occurrence)

DecodeBulkQuotePrice10Quantity2(bytes) ==
    LET incomingMessagesHeader == DecodeIncomingMessagesHeader15(bytes) IN IF ~incomingMessagesHeader.ok THEN Fail ELSE
    LET group == ReadBytes(incomingMessagesHeader.rest, 2) IN IF ~group.ok THEN Fail ELSE
    LET quoteIdentifierOnThisGroup == ReadBytes(group.rest, 8) IN IF ~quoteIdentifierOnThisGroup.ok THEN Fail ELSE
    LET numberOfQuotes == ReadDigits(quoteIdentifierOnThisGroup.rest, 3) IN IF ~numberOfQuotes.ok THEN Fail ELSE
    LET bulkQuotePrice10Quantity2Occurrence == ReadBulkQuotePrice10Quantity2OccurrenceList(numberOfQuotes.rest, numberOfQuotes.value) IN IF ~bulkQuotePrice10Quantity2Occurrence.ok THEN Fail ELSE
    Ok([ incomingMessagesHeader              |-> incomingMessagesHeader.value,
         group                               |-> group.value,
         quoteIdentifierOnThisGroup          |-> quoteIdentifierOnThisGroup.value,
         bulkQuotePrice10Quantity2Occurrence |-> bulkQuotePrice10Quantity2Occurrence.value ], bulkQuotePrice10Quantity2Occurrence.rest)

ZeroBulkQuotePrice10Quantity2 ==
    [ incomingMessagesHeader              |-> ZeroIncomingMessagesHeader15,
      group                               |-> [i \in 1 .. 2 |-> 0],
      quoteIdentifierOnThisGroup          |-> [i \in 1 .. 8 |-> 0],
      bulkQuotePrice10Quantity2Occurrence |-> << >> ]

(* Bulk Quote Price 10 Quantity 2 at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuotePrice10Quantity2 ==
    { ZeroBulkQuotePrice10Quantity2 }
        \cup { [ZeroBulkQuotePrice10Quantity2 EXCEPT !.incomingMessagesHeader = one] : one \in CheckedIncomingMessagesHeader15 }
        \cup { [ZeroBulkQuotePrice10Quantity2 EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuotePrice10Quantity2 EXCEPT !.quoteIdentifierOnThisGroup = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuotePrice10Quantity2 EXCEPT !.bulkQuotePrice10Quantity2Occurrence = one] : one \in SampleLists(OneBulkQuotePrice10Quantity2Occurrence) }

(***************************************************************************)
(* Incoming Messages Header: 22 bytes                                      *)
(***************************************************************************)

IncomingMessagesHeader16 ==
    [ userTimestampLocalHhmmss : Sample(6),
      traderId                 : Sample(8),
      userSequenceId           : Sample(8) ]

EncodeIncomingMessagesHeader16(message) ==
    message.userTimestampLocalHhmmss
        \o message.traderId
        \o message.userSequenceId

DecodeIncomingMessagesHeader16(bytes) ==
    LET userTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~userTimestampLocalHhmmss.ok THEN Fail ELSE
    LET traderId == ReadBytes(userTimestampLocalHhmmss.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(traderId.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    Ok([ userTimestampLocalHhmmss |-> userTimestampLocalHhmmss.value,
         traderId                 |-> traderId.value,
         userSequenceId           |-> userSequenceId.value ], userSequenceId.rest)

ZeroIncomingMessagesHeader16 ==
    [ userTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      traderId                 |-> [i \in 1 .. 8 |-> 0],
      userSequenceId           |-> [i \in 1 .. 8 |-> 0] ]

(* Incoming Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedIncomingMessagesHeader16 ==
    { ZeroIncomingMessagesHeader16 }
        \cup { [ZeroIncomingMessagesHeader16 EXCEPT !.userTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroIncomingMessagesHeader16 EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroIncomingMessagesHeader16 EXCEPT !.userSequenceId = one] : one \in Sample(8) }

(***************************************************************************)
(* Bulk Quote Price 4 Quantity 4 Occurrence: 16 bytes                      *)
(***************************************************************************)

BulkQuotePrice4Quantity4Occurrence ==
    [ group          : Sample(2),
      instrument     : Sample(4),
      verbSide       : Sample(1),
      quantitySignOr : Sample(1),
      quantity4      : Sample(4),
      price4         : Sample(4) ]

EncodeBulkQuotePrice4Quantity4Occurrence(message) ==
    message.group
        \o message.instrument
        \o message.verbSide
        \o message.quantitySignOr
        \o message.quantity4
        \o message.price4

DecodeBulkQuotePrice4Quantity4Occurrence(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrument == ReadBytes(group.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET verbSide == ReadBytes(instrument.rest, 1) IN IF ~verbSide.ok THEN Fail ELSE
    LET quantitySignOr == ReadBytes(verbSide.rest, 1) IN IF ~quantitySignOr.ok THEN Fail ELSE
    LET quantity4 == ReadBytes(quantitySignOr.rest, 4) IN IF ~quantity4.ok THEN Fail ELSE
    LET price4 == ReadBytes(quantity4.rest, 4) IN IF ~price4.ok THEN Fail ELSE
    Ok([ group          |-> group.value,
         instrument     |-> instrument.value,
         verbSide       |-> verbSide.value,
         quantitySignOr |-> quantitySignOr.value,
         quantity4      |-> quantity4.value,
         price4         |-> price4.value ], price4.rest)

ZeroBulkQuotePrice4Quantity4Occurrence ==
    [ group          |-> [i \in 1 .. 2 |-> 0],
      instrument     |-> [i \in 1 .. 4 |-> 0],
      verbSide       |-> [i \in 1 .. 1 |-> 0],
      quantitySignOr |-> [i \in 1 .. 1 |-> 0],
      quantity4      |-> [i \in 1 .. 4 |-> 0],
      price4         |-> [i \in 1 .. 4 |-> 0] ]

(* Bulk Quote Price 4 Quantity 4 Occurrence at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuotePrice4Quantity4Occurrence ==
    { ZeroBulkQuotePrice4Quantity4Occurrence }
        \cup { [ZeroBulkQuotePrice4Quantity4Occurrence EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuotePrice4Quantity4Occurrence EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroBulkQuotePrice4Quantity4Occurrence EXCEPT !.verbSide = one] : one \in Sample(1) }
        \cup { [ZeroBulkQuotePrice4Quantity4Occurrence EXCEPT !.quantitySignOr = one] : one \in Sample(1) }
        \cup { [ZeroBulkQuotePrice4Quantity4Occurrence EXCEPT !.quantity4 = one] : one \in Sample(4) }
        \cup { [ZeroBulkQuotePrice4Quantity4Occurrence EXCEPT !.price4 = one] : one \in Sample(4) }

(* A run of Bulk Quote Price 4 Quantity 4 Occurrence, written one after another *)
RECURSIVE EncodeBulkQuotePrice4Quantity4OccurrenceList(_)
EncodeBulkQuotePrice4Quantity4OccurrenceList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeBulkQuotePrice4Quantity4Occurrence(Head(messages)) \o EncodeBulkQuotePrice4Quantity4OccurrenceList(Tail(messages))

(* As many Bulk Quote Price 4 Quantity 4 Occurrence as the field that counts them says *)
RECURSIVE ReadBulkQuotePrice4Quantity4OccurrenceList(_, _)
ReadBulkQuotePrice4Quantity4OccurrenceList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeBulkQuotePrice4Quantity4Occurrence(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadBulkQuotePrice4Quantity4OccurrenceList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Bulk Quote Price 4 Quantity 4 Occurrence of each kind, for the lists that carry them *)
OneBulkQuotePrice4Quantity4Occurrence == { ZeroBulkQuotePrice4Quantity4Occurrence }

(***************************************************************************)
(* Bulk Quote Price 4 Quantity 4                                           *)
(***************************************************************************)

BulkQuotePrice4Quantity4 ==
    [ incomingMessagesHeader             : IncomingMessagesHeader16,
      group                              : Sample(2),
      quoteIdentifierOnThisGroup         : Sample(8),
      bulkQuotePrice4Quantity4Occurrence : SampleLists(OneBulkQuotePrice4Quantity4Occurrence) ]

EncodeBulkQuotePrice4Quantity4(message) ==
    EncodeIncomingMessagesHeader16(message.incomingMessagesHeader)
        \o message.group
        \o message.quoteIdentifierOnThisGroup
        \o EncodeDigits(Len(message.bulkQuotePrice4Quantity4Occurrence), 3)
        \o EncodeBulkQuotePrice4Quantity4OccurrenceList(message.bulkQuotePrice4Quantity4Occurrence)

DecodeBulkQuotePrice4Quantity4(bytes) ==
    LET incomingMessagesHeader == DecodeIncomingMessagesHeader16(bytes) IN IF ~incomingMessagesHeader.ok THEN Fail ELSE
    LET group == ReadBytes(incomingMessagesHeader.rest, 2) IN IF ~group.ok THEN Fail ELSE
    LET quoteIdentifierOnThisGroup == ReadBytes(group.rest, 8) IN IF ~quoteIdentifierOnThisGroup.ok THEN Fail ELSE
    LET numberOfQuotes == ReadDigits(quoteIdentifierOnThisGroup.rest, 3) IN IF ~numberOfQuotes.ok THEN Fail ELSE
    LET bulkQuotePrice4Quantity4Occurrence == ReadBulkQuotePrice4Quantity4OccurrenceList(numberOfQuotes.rest, numberOfQuotes.value) IN IF ~bulkQuotePrice4Quantity4Occurrence.ok THEN Fail ELSE
    Ok([ incomingMessagesHeader             |-> incomingMessagesHeader.value,
         group                              |-> group.value,
         quoteIdentifierOnThisGroup         |-> quoteIdentifierOnThisGroup.value,
         bulkQuotePrice4Quantity4Occurrence |-> bulkQuotePrice4Quantity4Occurrence.value ], bulkQuotePrice4Quantity4Occurrence.rest)

ZeroBulkQuotePrice4Quantity4 ==
    [ incomingMessagesHeader             |-> ZeroIncomingMessagesHeader16,
      group                              |-> [i \in 1 .. 2 |-> 0],
      quoteIdentifierOnThisGroup         |-> [i \in 1 .. 8 |-> 0],
      bulkQuotePrice4Quantity4Occurrence |-> << >> ]

(* Bulk Quote Price 4 Quantity 4 at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuotePrice4Quantity4 ==
    { ZeroBulkQuotePrice4Quantity4 }
        \cup { [ZeroBulkQuotePrice4Quantity4 EXCEPT !.incomingMessagesHeader = one] : one \in CheckedIncomingMessagesHeader16 }
        \cup { [ZeroBulkQuotePrice4Quantity4 EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuotePrice4Quantity4 EXCEPT !.quoteIdentifierOnThisGroup = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuotePrice4Quantity4 EXCEPT !.bulkQuotePrice4Quantity4Occurrence = one] : one \in SampleLists(OneBulkQuotePrice4Quantity4Occurrence) }

(***************************************************************************)
(* Incoming Messages Header: 22 bytes                                      *)
(***************************************************************************)

IncomingMessagesHeader17 ==
    [ userTimestampLocalHhmmss : Sample(6),
      traderId                 : Sample(8),
      userSequenceId           : Sample(8) ]

EncodeIncomingMessagesHeader17(message) ==
    message.userTimestampLocalHhmmss
        \o message.traderId
        \o message.userSequenceId

DecodeIncomingMessagesHeader17(bytes) ==
    LET userTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~userTimestampLocalHhmmss.ok THEN Fail ELSE
    LET traderId == ReadBytes(userTimestampLocalHhmmss.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(traderId.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    Ok([ userTimestampLocalHhmmss |-> userTimestampLocalHhmmss.value,
         traderId                 |-> traderId.value,
         userSequenceId           |-> userSequenceId.value ], userSequenceId.rest)

ZeroIncomingMessagesHeader17 ==
    [ userTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      traderId                 |-> [i \in 1 .. 8 |-> 0],
      userSequenceId           |-> [i \in 1 .. 8 |-> 0] ]

(* Incoming Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedIncomingMessagesHeader17 ==
    { ZeroIncomingMessagesHeader17 }
        \cup { [ZeroIncomingMessagesHeader17 EXCEPT !.userTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroIncomingMessagesHeader17 EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroIncomingMessagesHeader17 EXCEPT !.userSequenceId = one] : one \in Sample(8) }

(***************************************************************************)
(* Bulk Quote Price 6 Quantity 4 Occurrence: 18 bytes                      *)
(***************************************************************************)

BulkQuotePrice6Quantity4Occurrence ==
    [ group          : Sample(2),
      instrument     : Sample(4),
      verbSide       : Sample(1),
      quantitySignOr : Sample(1),
      quantity4      : Sample(4),
      price6         : Sample(6) ]

EncodeBulkQuotePrice6Quantity4Occurrence(message) ==
    message.group
        \o message.instrument
        \o message.verbSide
        \o message.quantitySignOr
        \o message.quantity4
        \o message.price6

DecodeBulkQuotePrice6Quantity4Occurrence(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrument == ReadBytes(group.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET verbSide == ReadBytes(instrument.rest, 1) IN IF ~verbSide.ok THEN Fail ELSE
    LET quantitySignOr == ReadBytes(verbSide.rest, 1) IN IF ~quantitySignOr.ok THEN Fail ELSE
    LET quantity4 == ReadBytes(quantitySignOr.rest, 4) IN IF ~quantity4.ok THEN Fail ELSE
    LET price6 == ReadBytes(quantity4.rest, 6) IN IF ~price6.ok THEN Fail ELSE
    Ok([ group          |-> group.value,
         instrument     |-> instrument.value,
         verbSide       |-> verbSide.value,
         quantitySignOr |-> quantitySignOr.value,
         quantity4      |-> quantity4.value,
         price6         |-> price6.value ], price6.rest)

ZeroBulkQuotePrice6Quantity4Occurrence ==
    [ group          |-> [i \in 1 .. 2 |-> 0],
      instrument     |-> [i \in 1 .. 4 |-> 0],
      verbSide       |-> [i \in 1 .. 1 |-> 0],
      quantitySignOr |-> [i \in 1 .. 1 |-> 0],
      quantity4      |-> [i \in 1 .. 4 |-> 0],
      price6         |-> [i \in 1 .. 6 |-> 0] ]

(* Bulk Quote Price 6 Quantity 4 Occurrence at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuotePrice6Quantity4Occurrence ==
    { ZeroBulkQuotePrice6Quantity4Occurrence }
        \cup { [ZeroBulkQuotePrice6Quantity4Occurrence EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuotePrice6Quantity4Occurrence EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroBulkQuotePrice6Quantity4Occurrence EXCEPT !.verbSide = one] : one \in Sample(1) }
        \cup { [ZeroBulkQuotePrice6Quantity4Occurrence EXCEPT !.quantitySignOr = one] : one \in Sample(1) }
        \cup { [ZeroBulkQuotePrice6Quantity4Occurrence EXCEPT !.quantity4 = one] : one \in Sample(4) }
        \cup { [ZeroBulkQuotePrice6Quantity4Occurrence EXCEPT !.price6 = one] : one \in Sample(6) }

(* A run of Bulk Quote Price 6 Quantity 4 Occurrence, written one after another *)
RECURSIVE EncodeBulkQuotePrice6Quantity4OccurrenceList(_)
EncodeBulkQuotePrice6Quantity4OccurrenceList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeBulkQuotePrice6Quantity4Occurrence(Head(messages)) \o EncodeBulkQuotePrice6Quantity4OccurrenceList(Tail(messages))

(* As many Bulk Quote Price 6 Quantity 4 Occurrence as the field that counts them says *)
RECURSIVE ReadBulkQuotePrice6Quantity4OccurrenceList(_, _)
ReadBulkQuotePrice6Quantity4OccurrenceList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeBulkQuotePrice6Quantity4Occurrence(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadBulkQuotePrice6Quantity4OccurrenceList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Bulk Quote Price 6 Quantity 4 Occurrence of each kind, for the lists that carry them *)
OneBulkQuotePrice6Quantity4Occurrence == { ZeroBulkQuotePrice6Quantity4Occurrence }

(***************************************************************************)
(* Bulk Quote Price 6 Quantity 4                                           *)
(***************************************************************************)

BulkQuotePrice6Quantity4 ==
    [ incomingMessagesHeader             : IncomingMessagesHeader17,
      group                              : Sample(2),
      quoteIdentifierOnThisGroup         : Sample(8),
      bulkQuotePrice6Quantity4Occurrence : SampleLists(OneBulkQuotePrice6Quantity4Occurrence) ]

EncodeBulkQuotePrice6Quantity4(message) ==
    EncodeIncomingMessagesHeader17(message.incomingMessagesHeader)
        \o message.group
        \o message.quoteIdentifierOnThisGroup
        \o EncodeDigits(Len(message.bulkQuotePrice6Quantity4Occurrence), 3)
        \o EncodeBulkQuotePrice6Quantity4OccurrenceList(message.bulkQuotePrice6Quantity4Occurrence)

DecodeBulkQuotePrice6Quantity4(bytes) ==
    LET incomingMessagesHeader == DecodeIncomingMessagesHeader17(bytes) IN IF ~incomingMessagesHeader.ok THEN Fail ELSE
    LET group == ReadBytes(incomingMessagesHeader.rest, 2) IN IF ~group.ok THEN Fail ELSE
    LET quoteIdentifierOnThisGroup == ReadBytes(group.rest, 8) IN IF ~quoteIdentifierOnThisGroup.ok THEN Fail ELSE
    LET numberOfQuotes == ReadDigits(quoteIdentifierOnThisGroup.rest, 3) IN IF ~numberOfQuotes.ok THEN Fail ELSE
    LET bulkQuotePrice6Quantity4Occurrence == ReadBulkQuotePrice6Quantity4OccurrenceList(numberOfQuotes.rest, numberOfQuotes.value) IN IF ~bulkQuotePrice6Quantity4Occurrence.ok THEN Fail ELSE
    Ok([ incomingMessagesHeader             |-> incomingMessagesHeader.value,
         group                              |-> group.value,
         quoteIdentifierOnThisGroup         |-> quoteIdentifierOnThisGroup.value,
         bulkQuotePrice6Quantity4Occurrence |-> bulkQuotePrice6Quantity4Occurrence.value ], bulkQuotePrice6Quantity4Occurrence.rest)

ZeroBulkQuotePrice6Quantity4 ==
    [ incomingMessagesHeader             |-> ZeroIncomingMessagesHeader17,
      group                              |-> [i \in 1 .. 2 |-> 0],
      quoteIdentifierOnThisGroup         |-> [i \in 1 .. 8 |-> 0],
      bulkQuotePrice6Quantity4Occurrence |-> << >> ]

(* Bulk Quote Price 6 Quantity 4 at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuotePrice6Quantity4 ==
    { ZeroBulkQuotePrice6Quantity4 }
        \cup { [ZeroBulkQuotePrice6Quantity4 EXCEPT !.incomingMessagesHeader = one] : one \in CheckedIncomingMessagesHeader17 }
        \cup { [ZeroBulkQuotePrice6Quantity4 EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuotePrice6Quantity4 EXCEPT !.quoteIdentifierOnThisGroup = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuotePrice6Quantity4 EXCEPT !.bulkQuotePrice6Quantity4Occurrence = one] : one \in SampleLists(OneBulkQuotePrice6Quantity4Occurrence) }

(***************************************************************************)
(* Incoming Messages Header: 22 bytes                                      *)
(***************************************************************************)

IncomingMessagesHeader18 ==
    [ userTimestampLocalHhmmss : Sample(6),
      traderId                 : Sample(8),
      userSequenceId           : Sample(8) ]

EncodeIncomingMessagesHeader18(message) ==
    message.userTimestampLocalHhmmss
        \o message.traderId
        \o message.userSequenceId

DecodeIncomingMessagesHeader18(bytes) ==
    LET userTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~userTimestampLocalHhmmss.ok THEN Fail ELSE
    LET traderId == ReadBytes(userTimestampLocalHhmmss.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(traderId.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    Ok([ userTimestampLocalHhmmss |-> userTimestampLocalHhmmss.value,
         traderId                 |-> traderId.value,
         userSequenceId           |-> userSequenceId.value ], userSequenceId.rest)

ZeroIncomingMessagesHeader18 ==
    [ userTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      traderId                 |-> [i \in 1 .. 8 |-> 0],
      userSequenceId           |-> [i \in 1 .. 8 |-> 0] ]

(* Incoming Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedIncomingMessagesHeader18 ==
    { ZeroIncomingMessagesHeader18 }
        \cup { [ZeroIncomingMessagesHeader18 EXCEPT !.userTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroIncomingMessagesHeader18 EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroIncomingMessagesHeader18 EXCEPT !.userSequenceId = one] : one \in Sample(8) }

(***************************************************************************)
(* Bulk Quote Price 8 Quantity 4 Occurrence: 20 bytes                      *)
(***************************************************************************)

BulkQuotePrice8Quantity4Occurrence ==
    [ group          : Sample(2),
      instrument     : Sample(4),
      verbSide       : Sample(1),
      quantitySignOr : Sample(1),
      quantity4      : Sample(4),
      price8         : Sample(8) ]

EncodeBulkQuotePrice8Quantity4Occurrence(message) ==
    message.group
        \o message.instrument
        \o message.verbSide
        \o message.quantitySignOr
        \o message.quantity4
        \o message.price8

DecodeBulkQuotePrice8Quantity4Occurrence(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrument == ReadBytes(group.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET verbSide == ReadBytes(instrument.rest, 1) IN IF ~verbSide.ok THEN Fail ELSE
    LET quantitySignOr == ReadBytes(verbSide.rest, 1) IN IF ~quantitySignOr.ok THEN Fail ELSE
    LET quantity4 == ReadBytes(quantitySignOr.rest, 4) IN IF ~quantity4.ok THEN Fail ELSE
    LET price8 == ReadBytes(quantity4.rest, 8) IN IF ~price8.ok THEN Fail ELSE
    Ok([ group          |-> group.value,
         instrument     |-> instrument.value,
         verbSide       |-> verbSide.value,
         quantitySignOr |-> quantitySignOr.value,
         quantity4      |-> quantity4.value,
         price8         |-> price8.value ], price8.rest)

ZeroBulkQuotePrice8Quantity4Occurrence ==
    [ group          |-> [i \in 1 .. 2 |-> 0],
      instrument     |-> [i \in 1 .. 4 |-> 0],
      verbSide       |-> [i \in 1 .. 1 |-> 0],
      quantitySignOr |-> [i \in 1 .. 1 |-> 0],
      quantity4      |-> [i \in 1 .. 4 |-> 0],
      price8         |-> [i \in 1 .. 8 |-> 0] ]

(* Bulk Quote Price 8 Quantity 4 Occurrence at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuotePrice8Quantity4Occurrence ==
    { ZeroBulkQuotePrice8Quantity4Occurrence }
        \cup { [ZeroBulkQuotePrice8Quantity4Occurrence EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuotePrice8Quantity4Occurrence EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroBulkQuotePrice8Quantity4Occurrence EXCEPT !.verbSide = one] : one \in Sample(1) }
        \cup { [ZeroBulkQuotePrice8Quantity4Occurrence EXCEPT !.quantitySignOr = one] : one \in Sample(1) }
        \cup { [ZeroBulkQuotePrice8Quantity4Occurrence EXCEPT !.quantity4 = one] : one \in Sample(4) }
        \cup { [ZeroBulkQuotePrice8Quantity4Occurrence EXCEPT !.price8 = one] : one \in Sample(8) }

(* A run of Bulk Quote Price 8 Quantity 4 Occurrence, written one after another *)
RECURSIVE EncodeBulkQuotePrice8Quantity4OccurrenceList(_)
EncodeBulkQuotePrice8Quantity4OccurrenceList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeBulkQuotePrice8Quantity4Occurrence(Head(messages)) \o EncodeBulkQuotePrice8Quantity4OccurrenceList(Tail(messages))

(* As many Bulk Quote Price 8 Quantity 4 Occurrence as the field that counts them says *)
RECURSIVE ReadBulkQuotePrice8Quantity4OccurrenceList(_, _)
ReadBulkQuotePrice8Quantity4OccurrenceList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeBulkQuotePrice8Quantity4Occurrence(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadBulkQuotePrice8Quantity4OccurrenceList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Bulk Quote Price 8 Quantity 4 Occurrence of each kind, for the lists that carry them *)
OneBulkQuotePrice8Quantity4Occurrence == { ZeroBulkQuotePrice8Quantity4Occurrence }

(***************************************************************************)
(* Bulk Quote Price 8 Quantity 4                                           *)
(***************************************************************************)

BulkQuotePrice8Quantity4 ==
    [ incomingMessagesHeader             : IncomingMessagesHeader18,
      group                              : Sample(2),
      quoteIdentifierOnThisGroup         : Sample(8),
      bulkQuotePrice8Quantity4Occurrence : SampleLists(OneBulkQuotePrice8Quantity4Occurrence) ]

EncodeBulkQuotePrice8Quantity4(message) ==
    EncodeIncomingMessagesHeader18(message.incomingMessagesHeader)
        \o message.group
        \o message.quoteIdentifierOnThisGroup
        \o EncodeDigits(Len(message.bulkQuotePrice8Quantity4Occurrence), 3)
        \o EncodeBulkQuotePrice8Quantity4OccurrenceList(message.bulkQuotePrice8Quantity4Occurrence)

DecodeBulkQuotePrice8Quantity4(bytes) ==
    LET incomingMessagesHeader == DecodeIncomingMessagesHeader18(bytes) IN IF ~incomingMessagesHeader.ok THEN Fail ELSE
    LET group == ReadBytes(incomingMessagesHeader.rest, 2) IN IF ~group.ok THEN Fail ELSE
    LET quoteIdentifierOnThisGroup == ReadBytes(group.rest, 8) IN IF ~quoteIdentifierOnThisGroup.ok THEN Fail ELSE
    LET numberOfQuotes == ReadDigits(quoteIdentifierOnThisGroup.rest, 3) IN IF ~numberOfQuotes.ok THEN Fail ELSE
    LET bulkQuotePrice8Quantity4Occurrence == ReadBulkQuotePrice8Quantity4OccurrenceList(numberOfQuotes.rest, numberOfQuotes.value) IN IF ~bulkQuotePrice8Quantity4Occurrence.ok THEN Fail ELSE
    Ok([ incomingMessagesHeader             |-> incomingMessagesHeader.value,
         group                              |-> group.value,
         quoteIdentifierOnThisGroup         |-> quoteIdentifierOnThisGroup.value,
         bulkQuotePrice8Quantity4Occurrence |-> bulkQuotePrice8Quantity4Occurrence.value ], bulkQuotePrice8Quantity4Occurrence.rest)

ZeroBulkQuotePrice8Quantity4 ==
    [ incomingMessagesHeader             |-> ZeroIncomingMessagesHeader18,
      group                              |-> [i \in 1 .. 2 |-> 0],
      quoteIdentifierOnThisGroup         |-> [i \in 1 .. 8 |-> 0],
      bulkQuotePrice8Quantity4Occurrence |-> << >> ]

(* Bulk Quote Price 8 Quantity 4 at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuotePrice8Quantity4 ==
    { ZeroBulkQuotePrice8Quantity4 }
        \cup { [ZeroBulkQuotePrice8Quantity4 EXCEPT !.incomingMessagesHeader = one] : one \in CheckedIncomingMessagesHeader18 }
        \cup { [ZeroBulkQuotePrice8Quantity4 EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuotePrice8Quantity4 EXCEPT !.quoteIdentifierOnThisGroup = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuotePrice8Quantity4 EXCEPT !.bulkQuotePrice8Quantity4Occurrence = one] : one \in SampleLists(OneBulkQuotePrice8Quantity4Occurrence) }

(***************************************************************************)
(* Incoming Messages Header: 22 bytes                                      *)
(***************************************************************************)

IncomingMessagesHeader19 ==
    [ userTimestampLocalHhmmss : Sample(6),
      traderId                 : Sample(8),
      userSequenceId           : Sample(8) ]

EncodeIncomingMessagesHeader19(message) ==
    message.userTimestampLocalHhmmss
        \o message.traderId
        \o message.userSequenceId

DecodeIncomingMessagesHeader19(bytes) ==
    LET userTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~userTimestampLocalHhmmss.ok THEN Fail ELSE
    LET traderId == ReadBytes(userTimestampLocalHhmmss.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(traderId.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    Ok([ userTimestampLocalHhmmss |-> userTimestampLocalHhmmss.value,
         traderId                 |-> traderId.value,
         userSequenceId           |-> userSequenceId.value ], userSequenceId.rest)

ZeroIncomingMessagesHeader19 ==
    [ userTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      traderId                 |-> [i \in 1 .. 8 |-> 0],
      userSequenceId           |-> [i \in 1 .. 8 |-> 0] ]

(* Incoming Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedIncomingMessagesHeader19 ==
    { ZeroIncomingMessagesHeader19 }
        \cup { [ZeroIncomingMessagesHeader19 EXCEPT !.userTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroIncomingMessagesHeader19 EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroIncomingMessagesHeader19 EXCEPT !.userSequenceId = one] : one \in Sample(8) }

(***************************************************************************)
(* Bulk Quote Price 10 Quantity 4 Occurrence: 22 bytes                     *)
(***************************************************************************)

BulkQuotePrice10Quantity4Occurrence ==
    [ group          : Sample(2),
      instrument     : Sample(4),
      verbSide       : Sample(1),
      quantitySignOr : Sample(1),
      quantity4      : Sample(4),
      price          : Sample(10) ]

EncodeBulkQuotePrice10Quantity4Occurrence(message) ==
    message.group
        \o message.instrument
        \o message.verbSide
        \o message.quantitySignOr
        \o message.quantity4
        \o message.price

DecodeBulkQuotePrice10Quantity4Occurrence(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrument == ReadBytes(group.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET verbSide == ReadBytes(instrument.rest, 1) IN IF ~verbSide.ok THEN Fail ELSE
    LET quantitySignOr == ReadBytes(verbSide.rest, 1) IN IF ~quantitySignOr.ok THEN Fail ELSE
    LET quantity4 == ReadBytes(quantitySignOr.rest, 4) IN IF ~quantity4.ok THEN Fail ELSE
    LET price == ReadBytes(quantity4.rest, 10) IN IF ~price.ok THEN Fail ELSE
    Ok([ group          |-> group.value,
         instrument     |-> instrument.value,
         verbSide       |-> verbSide.value,
         quantitySignOr |-> quantitySignOr.value,
         quantity4      |-> quantity4.value,
         price          |-> price.value ], price.rest)

ZeroBulkQuotePrice10Quantity4Occurrence ==
    [ group          |-> [i \in 1 .. 2 |-> 0],
      instrument     |-> [i \in 1 .. 4 |-> 0],
      verbSide       |-> [i \in 1 .. 1 |-> 0],
      quantitySignOr |-> [i \in 1 .. 1 |-> 0],
      quantity4      |-> [i \in 1 .. 4 |-> 0],
      price          |-> [i \in 1 .. 10 |-> 0] ]

(* Bulk Quote Price 10 Quantity 4 Occurrence at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuotePrice10Quantity4Occurrence ==
    { ZeroBulkQuotePrice10Quantity4Occurrence }
        \cup { [ZeroBulkQuotePrice10Quantity4Occurrence EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuotePrice10Quantity4Occurrence EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroBulkQuotePrice10Quantity4Occurrence EXCEPT !.verbSide = one] : one \in Sample(1) }
        \cup { [ZeroBulkQuotePrice10Quantity4Occurrence EXCEPT !.quantitySignOr = one] : one \in Sample(1) }
        \cup { [ZeroBulkQuotePrice10Quantity4Occurrence EXCEPT !.quantity4 = one] : one \in Sample(4) }
        \cup { [ZeroBulkQuotePrice10Quantity4Occurrence EXCEPT !.price = one] : one \in Sample(10) }

(* A run of Bulk Quote Price 10 Quantity 4 Occurrence, written one after another *)
RECURSIVE EncodeBulkQuotePrice10Quantity4OccurrenceList(_)
EncodeBulkQuotePrice10Quantity4OccurrenceList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeBulkQuotePrice10Quantity4Occurrence(Head(messages)) \o EncodeBulkQuotePrice10Quantity4OccurrenceList(Tail(messages))

(* As many Bulk Quote Price 10 Quantity 4 Occurrence as the field that counts them says *)
RECURSIVE ReadBulkQuotePrice10Quantity4OccurrenceList(_, _)
ReadBulkQuotePrice10Quantity4OccurrenceList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeBulkQuotePrice10Quantity4Occurrence(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadBulkQuotePrice10Quantity4OccurrenceList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Bulk Quote Price 10 Quantity 4 Occurrence of each kind, for the lists that carry them *)
OneBulkQuotePrice10Quantity4Occurrence == { ZeroBulkQuotePrice10Quantity4Occurrence }

(***************************************************************************)
(* Bulk Quote Price 10 Quantity 4                                          *)
(***************************************************************************)

BulkQuotePrice10Quantity4 ==
    [ incomingMessagesHeader              : IncomingMessagesHeader19,
      group                               : Sample(2),
      quoteIdentifierOnThisGroup          : Sample(8),
      bulkQuotePrice10Quantity4Occurrence : SampleLists(OneBulkQuotePrice10Quantity4Occurrence) ]

EncodeBulkQuotePrice10Quantity4(message) ==
    EncodeIncomingMessagesHeader19(message.incomingMessagesHeader)
        \o message.group
        \o message.quoteIdentifierOnThisGroup
        \o EncodeDigits(Len(message.bulkQuotePrice10Quantity4Occurrence), 3)
        \o EncodeBulkQuotePrice10Quantity4OccurrenceList(message.bulkQuotePrice10Quantity4Occurrence)

DecodeBulkQuotePrice10Quantity4(bytes) ==
    LET incomingMessagesHeader == DecodeIncomingMessagesHeader19(bytes) IN IF ~incomingMessagesHeader.ok THEN Fail ELSE
    LET group == ReadBytes(incomingMessagesHeader.rest, 2) IN IF ~group.ok THEN Fail ELSE
    LET quoteIdentifierOnThisGroup == ReadBytes(group.rest, 8) IN IF ~quoteIdentifierOnThisGroup.ok THEN Fail ELSE
    LET numberOfQuotes == ReadDigits(quoteIdentifierOnThisGroup.rest, 3) IN IF ~numberOfQuotes.ok THEN Fail ELSE
    LET bulkQuotePrice10Quantity4Occurrence == ReadBulkQuotePrice10Quantity4OccurrenceList(numberOfQuotes.rest, numberOfQuotes.value) IN IF ~bulkQuotePrice10Quantity4Occurrence.ok THEN Fail ELSE
    Ok([ incomingMessagesHeader              |-> incomingMessagesHeader.value,
         group                               |-> group.value,
         quoteIdentifierOnThisGroup          |-> quoteIdentifierOnThisGroup.value,
         bulkQuotePrice10Quantity4Occurrence |-> bulkQuotePrice10Quantity4Occurrence.value ], bulkQuotePrice10Quantity4Occurrence.rest)

ZeroBulkQuotePrice10Quantity4 ==
    [ incomingMessagesHeader              |-> ZeroIncomingMessagesHeader19,
      group                               |-> [i \in 1 .. 2 |-> 0],
      quoteIdentifierOnThisGroup          |-> [i \in 1 .. 8 |-> 0],
      bulkQuotePrice10Quantity4Occurrence |-> << >> ]

(* Bulk Quote Price 10 Quantity 4 at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuotePrice10Quantity4 ==
    { ZeroBulkQuotePrice10Quantity4 }
        \cup { [ZeroBulkQuotePrice10Quantity4 EXCEPT !.incomingMessagesHeader = one] : one \in CheckedIncomingMessagesHeader19 }
        \cup { [ZeroBulkQuotePrice10Quantity4 EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuotePrice10Quantity4 EXCEPT !.quoteIdentifierOnThisGroup = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuotePrice10Quantity4 EXCEPT !.bulkQuotePrice10Quantity4Occurrence = one] : one \in SampleLists(OneBulkQuotePrice10Quantity4Occurrence) }

(***************************************************************************)
(* Incoming Messages Header: 22 bytes                                      *)
(***************************************************************************)

IncomingMessagesHeader20 ==
    [ userTimestampLocalHhmmss : Sample(6),
      traderId                 : Sample(8),
      userSequenceId           : Sample(8) ]

EncodeIncomingMessagesHeader20(message) ==
    message.userTimestampLocalHhmmss
        \o message.traderId
        \o message.userSequenceId

DecodeIncomingMessagesHeader20(bytes) ==
    LET userTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~userTimestampLocalHhmmss.ok THEN Fail ELSE
    LET traderId == ReadBytes(userTimestampLocalHhmmss.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(traderId.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    Ok([ userTimestampLocalHhmmss |-> userTimestampLocalHhmmss.value,
         traderId                 |-> traderId.value,
         userSequenceId           |-> userSequenceId.value ], userSequenceId.rest)

ZeroIncomingMessagesHeader20 ==
    [ userTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      traderId                 |-> [i \in 1 .. 8 |-> 0],
      userSequenceId           |-> [i \in 1 .. 8 |-> 0] ]

(* Incoming Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedIncomingMessagesHeader20 ==
    { ZeroIncomingMessagesHeader20 }
        \cup { [ZeroIncomingMessagesHeader20 EXCEPT !.userTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroIncomingMessagesHeader20 EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroIncomingMessagesHeader20 EXCEPT !.userSequenceId = one] : one \in Sample(8) }

(***************************************************************************)
(* Bulk Quote Price 4 Quantity 6 Occurrence: 18 bytes                      *)
(***************************************************************************)

BulkQuotePrice4Quantity6Occurrence ==
    [ group          : Sample(2),
      instrument     : Sample(4),
      verbSide       : Sample(1),
      quantitySignOr : Sample(1),
      quantity6      : Sample(6),
      price4         : Sample(4) ]

EncodeBulkQuotePrice4Quantity6Occurrence(message) ==
    message.group
        \o message.instrument
        \o message.verbSide
        \o message.quantitySignOr
        \o message.quantity6
        \o message.price4

DecodeBulkQuotePrice4Quantity6Occurrence(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrument == ReadBytes(group.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET verbSide == ReadBytes(instrument.rest, 1) IN IF ~verbSide.ok THEN Fail ELSE
    LET quantitySignOr == ReadBytes(verbSide.rest, 1) IN IF ~quantitySignOr.ok THEN Fail ELSE
    LET quantity6 == ReadBytes(quantitySignOr.rest, 6) IN IF ~quantity6.ok THEN Fail ELSE
    LET price4 == ReadBytes(quantity6.rest, 4) IN IF ~price4.ok THEN Fail ELSE
    Ok([ group          |-> group.value,
         instrument     |-> instrument.value,
         verbSide       |-> verbSide.value,
         quantitySignOr |-> quantitySignOr.value,
         quantity6      |-> quantity6.value,
         price4         |-> price4.value ], price4.rest)

ZeroBulkQuotePrice4Quantity6Occurrence ==
    [ group          |-> [i \in 1 .. 2 |-> 0],
      instrument     |-> [i \in 1 .. 4 |-> 0],
      verbSide       |-> [i \in 1 .. 1 |-> 0],
      quantitySignOr |-> [i \in 1 .. 1 |-> 0],
      quantity6      |-> [i \in 1 .. 6 |-> 0],
      price4         |-> [i \in 1 .. 4 |-> 0] ]

(* Bulk Quote Price 4 Quantity 6 Occurrence at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuotePrice4Quantity6Occurrence ==
    { ZeroBulkQuotePrice4Quantity6Occurrence }
        \cup { [ZeroBulkQuotePrice4Quantity6Occurrence EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuotePrice4Quantity6Occurrence EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroBulkQuotePrice4Quantity6Occurrence EXCEPT !.verbSide = one] : one \in Sample(1) }
        \cup { [ZeroBulkQuotePrice4Quantity6Occurrence EXCEPT !.quantitySignOr = one] : one \in Sample(1) }
        \cup { [ZeroBulkQuotePrice4Quantity6Occurrence EXCEPT !.quantity6 = one] : one \in Sample(6) }
        \cup { [ZeroBulkQuotePrice4Quantity6Occurrence EXCEPT !.price4 = one] : one \in Sample(4) }

(* A run of Bulk Quote Price 4 Quantity 6 Occurrence, written one after another *)
RECURSIVE EncodeBulkQuotePrice4Quantity6OccurrenceList(_)
EncodeBulkQuotePrice4Quantity6OccurrenceList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeBulkQuotePrice4Quantity6Occurrence(Head(messages)) \o EncodeBulkQuotePrice4Quantity6OccurrenceList(Tail(messages))

(* As many Bulk Quote Price 4 Quantity 6 Occurrence as the field that counts them says *)
RECURSIVE ReadBulkQuotePrice4Quantity6OccurrenceList(_, _)
ReadBulkQuotePrice4Quantity6OccurrenceList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeBulkQuotePrice4Quantity6Occurrence(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadBulkQuotePrice4Quantity6OccurrenceList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Bulk Quote Price 4 Quantity 6 Occurrence of each kind, for the lists that carry them *)
OneBulkQuotePrice4Quantity6Occurrence == { ZeroBulkQuotePrice4Quantity6Occurrence }

(***************************************************************************)
(* Bulk Quote Price 4 Quantity 6                                           *)
(***************************************************************************)

BulkQuotePrice4Quantity6 ==
    [ incomingMessagesHeader             : IncomingMessagesHeader20,
      group                              : Sample(2),
      quoteIdentifierOnThisGroup         : Sample(8),
      bulkQuotePrice4Quantity6Occurrence : SampleLists(OneBulkQuotePrice4Quantity6Occurrence) ]

EncodeBulkQuotePrice4Quantity6(message) ==
    EncodeIncomingMessagesHeader20(message.incomingMessagesHeader)
        \o message.group
        \o message.quoteIdentifierOnThisGroup
        \o EncodeDigits(Len(message.bulkQuotePrice4Quantity6Occurrence), 3)
        \o EncodeBulkQuotePrice4Quantity6OccurrenceList(message.bulkQuotePrice4Quantity6Occurrence)

DecodeBulkQuotePrice4Quantity6(bytes) ==
    LET incomingMessagesHeader == DecodeIncomingMessagesHeader20(bytes) IN IF ~incomingMessagesHeader.ok THEN Fail ELSE
    LET group == ReadBytes(incomingMessagesHeader.rest, 2) IN IF ~group.ok THEN Fail ELSE
    LET quoteIdentifierOnThisGroup == ReadBytes(group.rest, 8) IN IF ~quoteIdentifierOnThisGroup.ok THEN Fail ELSE
    LET numberOfQuotes == ReadDigits(quoteIdentifierOnThisGroup.rest, 3) IN IF ~numberOfQuotes.ok THEN Fail ELSE
    LET bulkQuotePrice4Quantity6Occurrence == ReadBulkQuotePrice4Quantity6OccurrenceList(numberOfQuotes.rest, numberOfQuotes.value) IN IF ~bulkQuotePrice4Quantity6Occurrence.ok THEN Fail ELSE
    Ok([ incomingMessagesHeader             |-> incomingMessagesHeader.value,
         group                              |-> group.value,
         quoteIdentifierOnThisGroup         |-> quoteIdentifierOnThisGroup.value,
         bulkQuotePrice4Quantity6Occurrence |-> bulkQuotePrice4Quantity6Occurrence.value ], bulkQuotePrice4Quantity6Occurrence.rest)

ZeroBulkQuotePrice4Quantity6 ==
    [ incomingMessagesHeader             |-> ZeroIncomingMessagesHeader20,
      group                              |-> [i \in 1 .. 2 |-> 0],
      quoteIdentifierOnThisGroup         |-> [i \in 1 .. 8 |-> 0],
      bulkQuotePrice4Quantity6Occurrence |-> << >> ]

(* Bulk Quote Price 4 Quantity 6 at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuotePrice4Quantity6 ==
    { ZeroBulkQuotePrice4Quantity6 }
        \cup { [ZeroBulkQuotePrice4Quantity6 EXCEPT !.incomingMessagesHeader = one] : one \in CheckedIncomingMessagesHeader20 }
        \cup { [ZeroBulkQuotePrice4Quantity6 EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuotePrice4Quantity6 EXCEPT !.quoteIdentifierOnThisGroup = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuotePrice4Quantity6 EXCEPT !.bulkQuotePrice4Quantity6Occurrence = one] : one \in SampleLists(OneBulkQuotePrice4Quantity6Occurrence) }

(***************************************************************************)
(* Incoming Messages Header: 22 bytes                                      *)
(***************************************************************************)

IncomingMessagesHeader21 ==
    [ userTimestampLocalHhmmss : Sample(6),
      traderId                 : Sample(8),
      userSequenceId           : Sample(8) ]

EncodeIncomingMessagesHeader21(message) ==
    message.userTimestampLocalHhmmss
        \o message.traderId
        \o message.userSequenceId

DecodeIncomingMessagesHeader21(bytes) ==
    LET userTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~userTimestampLocalHhmmss.ok THEN Fail ELSE
    LET traderId == ReadBytes(userTimestampLocalHhmmss.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(traderId.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    Ok([ userTimestampLocalHhmmss |-> userTimestampLocalHhmmss.value,
         traderId                 |-> traderId.value,
         userSequenceId           |-> userSequenceId.value ], userSequenceId.rest)

ZeroIncomingMessagesHeader21 ==
    [ userTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      traderId                 |-> [i \in 1 .. 8 |-> 0],
      userSequenceId           |-> [i \in 1 .. 8 |-> 0] ]

(* Incoming Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedIncomingMessagesHeader21 ==
    { ZeroIncomingMessagesHeader21 }
        \cup { [ZeroIncomingMessagesHeader21 EXCEPT !.userTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroIncomingMessagesHeader21 EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroIncomingMessagesHeader21 EXCEPT !.userSequenceId = one] : one \in Sample(8) }

(***************************************************************************)
(* Bulk Quote Price 6 Quantity 6 Occurrence: 20 bytes                      *)
(***************************************************************************)

BulkQuotePrice6Quantity6Occurrence ==
    [ group          : Sample(2),
      instrument     : Sample(4),
      verbSide       : Sample(1),
      quantitySignOr : Sample(1),
      quantity6      : Sample(6),
      price6         : Sample(6) ]

EncodeBulkQuotePrice6Quantity6Occurrence(message) ==
    message.group
        \o message.instrument
        \o message.verbSide
        \o message.quantitySignOr
        \o message.quantity6
        \o message.price6

DecodeBulkQuotePrice6Quantity6Occurrence(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrument == ReadBytes(group.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET verbSide == ReadBytes(instrument.rest, 1) IN IF ~verbSide.ok THEN Fail ELSE
    LET quantitySignOr == ReadBytes(verbSide.rest, 1) IN IF ~quantitySignOr.ok THEN Fail ELSE
    LET quantity6 == ReadBytes(quantitySignOr.rest, 6) IN IF ~quantity6.ok THEN Fail ELSE
    LET price6 == ReadBytes(quantity6.rest, 6) IN IF ~price6.ok THEN Fail ELSE
    Ok([ group          |-> group.value,
         instrument     |-> instrument.value,
         verbSide       |-> verbSide.value,
         quantitySignOr |-> quantitySignOr.value,
         quantity6      |-> quantity6.value,
         price6         |-> price6.value ], price6.rest)

ZeroBulkQuotePrice6Quantity6Occurrence ==
    [ group          |-> [i \in 1 .. 2 |-> 0],
      instrument     |-> [i \in 1 .. 4 |-> 0],
      verbSide       |-> [i \in 1 .. 1 |-> 0],
      quantitySignOr |-> [i \in 1 .. 1 |-> 0],
      quantity6      |-> [i \in 1 .. 6 |-> 0],
      price6         |-> [i \in 1 .. 6 |-> 0] ]

(* Bulk Quote Price 6 Quantity 6 Occurrence at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuotePrice6Quantity6Occurrence ==
    { ZeroBulkQuotePrice6Quantity6Occurrence }
        \cup { [ZeroBulkQuotePrice6Quantity6Occurrence EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuotePrice6Quantity6Occurrence EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroBulkQuotePrice6Quantity6Occurrence EXCEPT !.verbSide = one] : one \in Sample(1) }
        \cup { [ZeroBulkQuotePrice6Quantity6Occurrence EXCEPT !.quantitySignOr = one] : one \in Sample(1) }
        \cup { [ZeroBulkQuotePrice6Quantity6Occurrence EXCEPT !.quantity6 = one] : one \in Sample(6) }
        \cup { [ZeroBulkQuotePrice6Quantity6Occurrence EXCEPT !.price6 = one] : one \in Sample(6) }

(* A run of Bulk Quote Price 6 Quantity 6 Occurrence, written one after another *)
RECURSIVE EncodeBulkQuotePrice6Quantity6OccurrenceList(_)
EncodeBulkQuotePrice6Quantity6OccurrenceList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeBulkQuotePrice6Quantity6Occurrence(Head(messages)) \o EncodeBulkQuotePrice6Quantity6OccurrenceList(Tail(messages))

(* As many Bulk Quote Price 6 Quantity 6 Occurrence as the field that counts them says *)
RECURSIVE ReadBulkQuotePrice6Quantity6OccurrenceList(_, _)
ReadBulkQuotePrice6Quantity6OccurrenceList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeBulkQuotePrice6Quantity6Occurrence(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadBulkQuotePrice6Quantity6OccurrenceList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Bulk Quote Price 6 Quantity 6 Occurrence of each kind, for the lists that carry them *)
OneBulkQuotePrice6Quantity6Occurrence == { ZeroBulkQuotePrice6Quantity6Occurrence }

(***************************************************************************)
(* Bulk Quote Price 6 Quantity 6                                           *)
(***************************************************************************)

BulkQuotePrice6Quantity6 ==
    [ incomingMessagesHeader             : IncomingMessagesHeader21,
      group                              : Sample(2),
      quoteIdentifierOnThisGroup         : Sample(8),
      bulkQuotePrice6Quantity6Occurrence : SampleLists(OneBulkQuotePrice6Quantity6Occurrence) ]

EncodeBulkQuotePrice6Quantity6(message) ==
    EncodeIncomingMessagesHeader21(message.incomingMessagesHeader)
        \o message.group
        \o message.quoteIdentifierOnThisGroup
        \o EncodeDigits(Len(message.bulkQuotePrice6Quantity6Occurrence), 3)
        \o EncodeBulkQuotePrice6Quantity6OccurrenceList(message.bulkQuotePrice6Quantity6Occurrence)

DecodeBulkQuotePrice6Quantity6(bytes) ==
    LET incomingMessagesHeader == DecodeIncomingMessagesHeader21(bytes) IN IF ~incomingMessagesHeader.ok THEN Fail ELSE
    LET group == ReadBytes(incomingMessagesHeader.rest, 2) IN IF ~group.ok THEN Fail ELSE
    LET quoteIdentifierOnThisGroup == ReadBytes(group.rest, 8) IN IF ~quoteIdentifierOnThisGroup.ok THEN Fail ELSE
    LET numberOfQuotes == ReadDigits(quoteIdentifierOnThisGroup.rest, 3) IN IF ~numberOfQuotes.ok THEN Fail ELSE
    LET bulkQuotePrice6Quantity6Occurrence == ReadBulkQuotePrice6Quantity6OccurrenceList(numberOfQuotes.rest, numberOfQuotes.value) IN IF ~bulkQuotePrice6Quantity6Occurrence.ok THEN Fail ELSE
    Ok([ incomingMessagesHeader             |-> incomingMessagesHeader.value,
         group                              |-> group.value,
         quoteIdentifierOnThisGroup         |-> quoteIdentifierOnThisGroup.value,
         bulkQuotePrice6Quantity6Occurrence |-> bulkQuotePrice6Quantity6Occurrence.value ], bulkQuotePrice6Quantity6Occurrence.rest)

ZeroBulkQuotePrice6Quantity6 ==
    [ incomingMessagesHeader             |-> ZeroIncomingMessagesHeader21,
      group                              |-> [i \in 1 .. 2 |-> 0],
      quoteIdentifierOnThisGroup         |-> [i \in 1 .. 8 |-> 0],
      bulkQuotePrice6Quantity6Occurrence |-> << >> ]

(* Bulk Quote Price 6 Quantity 6 at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuotePrice6Quantity6 ==
    { ZeroBulkQuotePrice6Quantity6 }
        \cup { [ZeroBulkQuotePrice6Quantity6 EXCEPT !.incomingMessagesHeader = one] : one \in CheckedIncomingMessagesHeader21 }
        \cup { [ZeroBulkQuotePrice6Quantity6 EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuotePrice6Quantity6 EXCEPT !.quoteIdentifierOnThisGroup = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuotePrice6Quantity6 EXCEPT !.bulkQuotePrice6Quantity6Occurrence = one] : one \in SampleLists(OneBulkQuotePrice6Quantity6Occurrence) }

(***************************************************************************)
(* Incoming Messages Header: 22 bytes                                      *)
(***************************************************************************)

IncomingMessagesHeader22 ==
    [ userTimestampLocalHhmmss : Sample(6),
      traderId                 : Sample(8),
      userSequenceId           : Sample(8) ]

EncodeIncomingMessagesHeader22(message) ==
    message.userTimestampLocalHhmmss
        \o message.traderId
        \o message.userSequenceId

DecodeIncomingMessagesHeader22(bytes) ==
    LET userTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~userTimestampLocalHhmmss.ok THEN Fail ELSE
    LET traderId == ReadBytes(userTimestampLocalHhmmss.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(traderId.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    Ok([ userTimestampLocalHhmmss |-> userTimestampLocalHhmmss.value,
         traderId                 |-> traderId.value,
         userSequenceId           |-> userSequenceId.value ], userSequenceId.rest)

ZeroIncomingMessagesHeader22 ==
    [ userTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      traderId                 |-> [i \in 1 .. 8 |-> 0],
      userSequenceId           |-> [i \in 1 .. 8 |-> 0] ]

(* Incoming Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedIncomingMessagesHeader22 ==
    { ZeroIncomingMessagesHeader22 }
        \cup { [ZeroIncomingMessagesHeader22 EXCEPT !.userTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroIncomingMessagesHeader22 EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroIncomingMessagesHeader22 EXCEPT !.userSequenceId = one] : one \in Sample(8) }

(***************************************************************************)
(* Bulk Quote Price 8 Quantity 6 Occurrence: 22 bytes                      *)
(***************************************************************************)

BulkQuotePrice8Quantity6Occurrence ==
    [ group          : Sample(2),
      instrument     : Sample(4),
      verbSide       : Sample(1),
      quantitySignOr : Sample(1),
      quantity6      : Sample(6),
      price8         : Sample(8) ]

EncodeBulkQuotePrice8Quantity6Occurrence(message) ==
    message.group
        \o message.instrument
        \o message.verbSide
        \o message.quantitySignOr
        \o message.quantity6
        \o message.price8

DecodeBulkQuotePrice8Quantity6Occurrence(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrument == ReadBytes(group.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET verbSide == ReadBytes(instrument.rest, 1) IN IF ~verbSide.ok THEN Fail ELSE
    LET quantitySignOr == ReadBytes(verbSide.rest, 1) IN IF ~quantitySignOr.ok THEN Fail ELSE
    LET quantity6 == ReadBytes(quantitySignOr.rest, 6) IN IF ~quantity6.ok THEN Fail ELSE
    LET price8 == ReadBytes(quantity6.rest, 8) IN IF ~price8.ok THEN Fail ELSE
    Ok([ group          |-> group.value,
         instrument     |-> instrument.value,
         verbSide       |-> verbSide.value,
         quantitySignOr |-> quantitySignOr.value,
         quantity6      |-> quantity6.value,
         price8         |-> price8.value ], price8.rest)

ZeroBulkQuotePrice8Quantity6Occurrence ==
    [ group          |-> [i \in 1 .. 2 |-> 0],
      instrument     |-> [i \in 1 .. 4 |-> 0],
      verbSide       |-> [i \in 1 .. 1 |-> 0],
      quantitySignOr |-> [i \in 1 .. 1 |-> 0],
      quantity6      |-> [i \in 1 .. 6 |-> 0],
      price8         |-> [i \in 1 .. 8 |-> 0] ]

(* Bulk Quote Price 8 Quantity 6 Occurrence at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuotePrice8Quantity6Occurrence ==
    { ZeroBulkQuotePrice8Quantity6Occurrence }
        \cup { [ZeroBulkQuotePrice8Quantity6Occurrence EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuotePrice8Quantity6Occurrence EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroBulkQuotePrice8Quantity6Occurrence EXCEPT !.verbSide = one] : one \in Sample(1) }
        \cup { [ZeroBulkQuotePrice8Quantity6Occurrence EXCEPT !.quantitySignOr = one] : one \in Sample(1) }
        \cup { [ZeroBulkQuotePrice8Quantity6Occurrence EXCEPT !.quantity6 = one] : one \in Sample(6) }
        \cup { [ZeroBulkQuotePrice8Quantity6Occurrence EXCEPT !.price8 = one] : one \in Sample(8) }

(* A run of Bulk Quote Price 8 Quantity 6 Occurrence, written one after another *)
RECURSIVE EncodeBulkQuotePrice8Quantity6OccurrenceList(_)
EncodeBulkQuotePrice8Quantity6OccurrenceList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeBulkQuotePrice8Quantity6Occurrence(Head(messages)) \o EncodeBulkQuotePrice8Quantity6OccurrenceList(Tail(messages))

(* As many Bulk Quote Price 8 Quantity 6 Occurrence as the field that counts them says *)
RECURSIVE ReadBulkQuotePrice8Quantity6OccurrenceList(_, _)
ReadBulkQuotePrice8Quantity6OccurrenceList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeBulkQuotePrice8Quantity6Occurrence(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadBulkQuotePrice8Quantity6OccurrenceList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Bulk Quote Price 8 Quantity 6 Occurrence of each kind, for the lists that carry them *)
OneBulkQuotePrice8Quantity6Occurrence == { ZeroBulkQuotePrice8Quantity6Occurrence }

(***************************************************************************)
(* Bulk Quote Price 8 Quantity 6                                           *)
(***************************************************************************)

BulkQuotePrice8Quantity6 ==
    [ incomingMessagesHeader             : IncomingMessagesHeader22,
      group                              : Sample(2),
      quoteIdentifierOnThisGroup         : Sample(8),
      bulkQuotePrice8Quantity6Occurrence : SampleLists(OneBulkQuotePrice8Quantity6Occurrence) ]

EncodeBulkQuotePrice8Quantity6(message) ==
    EncodeIncomingMessagesHeader22(message.incomingMessagesHeader)
        \o message.group
        \o message.quoteIdentifierOnThisGroup
        \o EncodeDigits(Len(message.bulkQuotePrice8Quantity6Occurrence), 3)
        \o EncodeBulkQuotePrice8Quantity6OccurrenceList(message.bulkQuotePrice8Quantity6Occurrence)

DecodeBulkQuotePrice8Quantity6(bytes) ==
    LET incomingMessagesHeader == DecodeIncomingMessagesHeader22(bytes) IN IF ~incomingMessagesHeader.ok THEN Fail ELSE
    LET group == ReadBytes(incomingMessagesHeader.rest, 2) IN IF ~group.ok THEN Fail ELSE
    LET quoteIdentifierOnThisGroup == ReadBytes(group.rest, 8) IN IF ~quoteIdentifierOnThisGroup.ok THEN Fail ELSE
    LET numberOfQuotes == ReadDigits(quoteIdentifierOnThisGroup.rest, 3) IN IF ~numberOfQuotes.ok THEN Fail ELSE
    LET bulkQuotePrice8Quantity6Occurrence == ReadBulkQuotePrice8Quantity6OccurrenceList(numberOfQuotes.rest, numberOfQuotes.value) IN IF ~bulkQuotePrice8Quantity6Occurrence.ok THEN Fail ELSE
    Ok([ incomingMessagesHeader             |-> incomingMessagesHeader.value,
         group                              |-> group.value,
         quoteIdentifierOnThisGroup         |-> quoteIdentifierOnThisGroup.value,
         bulkQuotePrice8Quantity6Occurrence |-> bulkQuotePrice8Quantity6Occurrence.value ], bulkQuotePrice8Quantity6Occurrence.rest)

ZeroBulkQuotePrice8Quantity6 ==
    [ incomingMessagesHeader             |-> ZeroIncomingMessagesHeader22,
      group                              |-> [i \in 1 .. 2 |-> 0],
      quoteIdentifierOnThisGroup         |-> [i \in 1 .. 8 |-> 0],
      bulkQuotePrice8Quantity6Occurrence |-> << >> ]

(* Bulk Quote Price 8 Quantity 6 at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuotePrice8Quantity6 ==
    { ZeroBulkQuotePrice8Quantity6 }
        \cup { [ZeroBulkQuotePrice8Quantity6 EXCEPT !.incomingMessagesHeader = one] : one \in CheckedIncomingMessagesHeader22 }
        \cup { [ZeroBulkQuotePrice8Quantity6 EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuotePrice8Quantity6 EXCEPT !.quoteIdentifierOnThisGroup = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuotePrice8Quantity6 EXCEPT !.bulkQuotePrice8Quantity6Occurrence = one] : one \in SampleLists(OneBulkQuotePrice8Quantity6Occurrence) }

(***************************************************************************)
(* Incoming Messages Header: 22 bytes                                      *)
(***************************************************************************)

IncomingMessagesHeader23 ==
    [ userTimestampLocalHhmmss : Sample(6),
      traderId                 : Sample(8),
      userSequenceId           : Sample(8) ]

EncodeIncomingMessagesHeader23(message) ==
    message.userTimestampLocalHhmmss
        \o message.traderId
        \o message.userSequenceId

DecodeIncomingMessagesHeader23(bytes) ==
    LET userTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~userTimestampLocalHhmmss.ok THEN Fail ELSE
    LET traderId == ReadBytes(userTimestampLocalHhmmss.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(traderId.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    Ok([ userTimestampLocalHhmmss |-> userTimestampLocalHhmmss.value,
         traderId                 |-> traderId.value,
         userSequenceId           |-> userSequenceId.value ], userSequenceId.rest)

ZeroIncomingMessagesHeader23 ==
    [ userTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      traderId                 |-> [i \in 1 .. 8 |-> 0],
      userSequenceId           |-> [i \in 1 .. 8 |-> 0] ]

(* Incoming Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedIncomingMessagesHeader23 ==
    { ZeroIncomingMessagesHeader23 }
        \cup { [ZeroIncomingMessagesHeader23 EXCEPT !.userTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroIncomingMessagesHeader23 EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroIncomingMessagesHeader23 EXCEPT !.userSequenceId = one] : one \in Sample(8) }

(***************************************************************************)
(* Bulk Quote Price 10 Quantity 6 Occurrence: 24 bytes                     *)
(***************************************************************************)

BulkQuotePrice10Quantity6Occurrence ==
    [ group          : Sample(2),
      instrument     : Sample(4),
      verbSide       : Sample(1),
      quantitySignOr : Sample(1),
      quantity6      : Sample(6),
      price          : Sample(10) ]

EncodeBulkQuotePrice10Quantity6Occurrence(message) ==
    message.group
        \o message.instrument
        \o message.verbSide
        \o message.quantitySignOr
        \o message.quantity6
        \o message.price

DecodeBulkQuotePrice10Quantity6Occurrence(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrument == ReadBytes(group.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET verbSide == ReadBytes(instrument.rest, 1) IN IF ~verbSide.ok THEN Fail ELSE
    LET quantitySignOr == ReadBytes(verbSide.rest, 1) IN IF ~quantitySignOr.ok THEN Fail ELSE
    LET quantity6 == ReadBytes(quantitySignOr.rest, 6) IN IF ~quantity6.ok THEN Fail ELSE
    LET price == ReadBytes(quantity6.rest, 10) IN IF ~price.ok THEN Fail ELSE
    Ok([ group          |-> group.value,
         instrument     |-> instrument.value,
         verbSide       |-> verbSide.value,
         quantitySignOr |-> quantitySignOr.value,
         quantity6      |-> quantity6.value,
         price          |-> price.value ], price.rest)

ZeroBulkQuotePrice10Quantity6Occurrence ==
    [ group          |-> [i \in 1 .. 2 |-> 0],
      instrument     |-> [i \in 1 .. 4 |-> 0],
      verbSide       |-> [i \in 1 .. 1 |-> 0],
      quantitySignOr |-> [i \in 1 .. 1 |-> 0],
      quantity6      |-> [i \in 1 .. 6 |-> 0],
      price          |-> [i \in 1 .. 10 |-> 0] ]

(* Bulk Quote Price 10 Quantity 6 Occurrence at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuotePrice10Quantity6Occurrence ==
    { ZeroBulkQuotePrice10Quantity6Occurrence }
        \cup { [ZeroBulkQuotePrice10Quantity6Occurrence EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuotePrice10Quantity6Occurrence EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroBulkQuotePrice10Quantity6Occurrence EXCEPT !.verbSide = one] : one \in Sample(1) }
        \cup { [ZeroBulkQuotePrice10Quantity6Occurrence EXCEPT !.quantitySignOr = one] : one \in Sample(1) }
        \cup { [ZeroBulkQuotePrice10Quantity6Occurrence EXCEPT !.quantity6 = one] : one \in Sample(6) }
        \cup { [ZeroBulkQuotePrice10Quantity6Occurrence EXCEPT !.price = one] : one \in Sample(10) }

(* A run of Bulk Quote Price 10 Quantity 6 Occurrence, written one after another *)
RECURSIVE EncodeBulkQuotePrice10Quantity6OccurrenceList(_)
EncodeBulkQuotePrice10Quantity6OccurrenceList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeBulkQuotePrice10Quantity6Occurrence(Head(messages)) \o EncodeBulkQuotePrice10Quantity6OccurrenceList(Tail(messages))

(* As many Bulk Quote Price 10 Quantity 6 Occurrence as the field that counts them says *)
RECURSIVE ReadBulkQuotePrice10Quantity6OccurrenceList(_, _)
ReadBulkQuotePrice10Quantity6OccurrenceList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeBulkQuotePrice10Quantity6Occurrence(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadBulkQuotePrice10Quantity6OccurrenceList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Bulk Quote Price 10 Quantity 6 Occurrence of each kind, for the lists that carry them *)
OneBulkQuotePrice10Quantity6Occurrence == { ZeroBulkQuotePrice10Quantity6Occurrence }

(***************************************************************************)
(* Bulk Quote Price 10 Quantity 6                                          *)
(***************************************************************************)

BulkQuotePrice10Quantity6 ==
    [ incomingMessagesHeader              : IncomingMessagesHeader23,
      group                               : Sample(2),
      quoteIdentifierOnThisGroup          : Sample(8),
      bulkQuotePrice10Quantity6Occurrence : SampleLists(OneBulkQuotePrice10Quantity6Occurrence) ]

EncodeBulkQuotePrice10Quantity6(message) ==
    EncodeIncomingMessagesHeader23(message.incomingMessagesHeader)
        \o message.group
        \o message.quoteIdentifierOnThisGroup
        \o EncodeDigits(Len(message.bulkQuotePrice10Quantity6Occurrence), 3)
        \o EncodeBulkQuotePrice10Quantity6OccurrenceList(message.bulkQuotePrice10Quantity6Occurrence)

DecodeBulkQuotePrice10Quantity6(bytes) ==
    LET incomingMessagesHeader == DecodeIncomingMessagesHeader23(bytes) IN IF ~incomingMessagesHeader.ok THEN Fail ELSE
    LET group == ReadBytes(incomingMessagesHeader.rest, 2) IN IF ~group.ok THEN Fail ELSE
    LET quoteIdentifierOnThisGroup == ReadBytes(group.rest, 8) IN IF ~quoteIdentifierOnThisGroup.ok THEN Fail ELSE
    LET numberOfQuotes == ReadDigits(quoteIdentifierOnThisGroup.rest, 3) IN IF ~numberOfQuotes.ok THEN Fail ELSE
    LET bulkQuotePrice10Quantity6Occurrence == ReadBulkQuotePrice10Quantity6OccurrenceList(numberOfQuotes.rest, numberOfQuotes.value) IN IF ~bulkQuotePrice10Quantity6Occurrence.ok THEN Fail ELSE
    Ok([ incomingMessagesHeader              |-> incomingMessagesHeader.value,
         group                               |-> group.value,
         quoteIdentifierOnThisGroup          |-> quoteIdentifierOnThisGroup.value,
         bulkQuotePrice10Quantity6Occurrence |-> bulkQuotePrice10Quantity6Occurrence.value ], bulkQuotePrice10Quantity6Occurrence.rest)

ZeroBulkQuotePrice10Quantity6 ==
    [ incomingMessagesHeader              |-> ZeroIncomingMessagesHeader23,
      group                               |-> [i \in 1 .. 2 |-> 0],
      quoteIdentifierOnThisGroup          |-> [i \in 1 .. 8 |-> 0],
      bulkQuotePrice10Quantity6Occurrence |-> << >> ]

(* Bulk Quote Price 10 Quantity 6 at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuotePrice10Quantity6 ==
    { ZeroBulkQuotePrice10Quantity6 }
        \cup { [ZeroBulkQuotePrice10Quantity6 EXCEPT !.incomingMessagesHeader = one] : one \in CheckedIncomingMessagesHeader23 }
        \cup { [ZeroBulkQuotePrice10Quantity6 EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuotePrice10Quantity6 EXCEPT !.quoteIdentifierOnThisGroup = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuotePrice10Quantity6 EXCEPT !.bulkQuotePrice10Quantity6Occurrence = one] : one \in SampleLists(OneBulkQuotePrice10Quantity6Occurrence) }

(***************************************************************************)
(* Incoming Messages Header: 22 bytes                                      *)
(***************************************************************************)

IncomingMessagesHeader24 ==
    [ userTimestampLocalHhmmss : Sample(6),
      traderId                 : Sample(8),
      userSequenceId           : Sample(8) ]

EncodeIncomingMessagesHeader24(message) ==
    message.userTimestampLocalHhmmss
        \o message.traderId
        \o message.userSequenceId

DecodeIncomingMessagesHeader24(bytes) ==
    LET userTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~userTimestampLocalHhmmss.ok THEN Fail ELSE
    LET traderId == ReadBytes(userTimestampLocalHhmmss.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(traderId.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    Ok([ userTimestampLocalHhmmss |-> userTimestampLocalHhmmss.value,
         traderId                 |-> traderId.value,
         userSequenceId           |-> userSequenceId.value ], userSequenceId.rest)

ZeroIncomingMessagesHeader24 ==
    [ userTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      traderId                 |-> [i \in 1 .. 8 |-> 0],
      userSequenceId           |-> [i \in 1 .. 8 |-> 0] ]

(* Incoming Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedIncomingMessagesHeader24 ==
    { ZeroIncomingMessagesHeader24 }
        \cup { [ZeroIncomingMessagesHeader24 EXCEPT !.userTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroIncomingMessagesHeader24 EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroIncomingMessagesHeader24 EXCEPT !.userSequenceId = one] : one \in Sample(8) }

(***************************************************************************)
(* Bulk Quote Price 4 Quantity 8 Occurrence: 20 bytes                      *)
(***************************************************************************)

BulkQuotePrice4Quantity8Occurrence ==
    [ group          : Sample(2),
      instrument     : Sample(4),
      verbSide       : Sample(1),
      quantitySignOr : Sample(1),
      quantity       : Sample(8),
      price4         : Sample(4) ]

EncodeBulkQuotePrice4Quantity8Occurrence(message) ==
    message.group
        \o message.instrument
        \o message.verbSide
        \o message.quantitySignOr
        \o message.quantity
        \o message.price4

DecodeBulkQuotePrice4Quantity8Occurrence(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrument == ReadBytes(group.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET verbSide == ReadBytes(instrument.rest, 1) IN IF ~verbSide.ok THEN Fail ELSE
    LET quantitySignOr == ReadBytes(verbSide.rest, 1) IN IF ~quantitySignOr.ok THEN Fail ELSE
    LET quantity == ReadBytes(quantitySignOr.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET price4 == ReadBytes(quantity.rest, 4) IN IF ~price4.ok THEN Fail ELSE
    Ok([ group          |-> group.value,
         instrument     |-> instrument.value,
         verbSide       |-> verbSide.value,
         quantitySignOr |-> quantitySignOr.value,
         quantity       |-> quantity.value,
         price4         |-> price4.value ], price4.rest)

ZeroBulkQuotePrice4Quantity8Occurrence ==
    [ group          |-> [i \in 1 .. 2 |-> 0],
      instrument     |-> [i \in 1 .. 4 |-> 0],
      verbSide       |-> [i \in 1 .. 1 |-> 0],
      quantitySignOr |-> [i \in 1 .. 1 |-> 0],
      quantity       |-> [i \in 1 .. 8 |-> 0],
      price4         |-> [i \in 1 .. 4 |-> 0] ]

(* Bulk Quote Price 4 Quantity 8 Occurrence at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuotePrice4Quantity8Occurrence ==
    { ZeroBulkQuotePrice4Quantity8Occurrence }
        \cup { [ZeroBulkQuotePrice4Quantity8Occurrence EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuotePrice4Quantity8Occurrence EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroBulkQuotePrice4Quantity8Occurrence EXCEPT !.verbSide = one] : one \in Sample(1) }
        \cup { [ZeroBulkQuotePrice4Quantity8Occurrence EXCEPT !.quantitySignOr = one] : one \in Sample(1) }
        \cup { [ZeroBulkQuotePrice4Quantity8Occurrence EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuotePrice4Quantity8Occurrence EXCEPT !.price4 = one] : one \in Sample(4) }

(* A run of Bulk Quote Price 4 Quantity 8 Occurrence, written one after another *)
RECURSIVE EncodeBulkQuotePrice4Quantity8OccurrenceList(_)
EncodeBulkQuotePrice4Quantity8OccurrenceList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeBulkQuotePrice4Quantity8Occurrence(Head(messages)) \o EncodeBulkQuotePrice4Quantity8OccurrenceList(Tail(messages))

(* As many Bulk Quote Price 4 Quantity 8 Occurrence as the field that counts them says *)
RECURSIVE ReadBulkQuotePrice4Quantity8OccurrenceList(_, _)
ReadBulkQuotePrice4Quantity8OccurrenceList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeBulkQuotePrice4Quantity8Occurrence(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadBulkQuotePrice4Quantity8OccurrenceList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Bulk Quote Price 4 Quantity 8 Occurrence of each kind, for the lists that carry them *)
OneBulkQuotePrice4Quantity8Occurrence == { ZeroBulkQuotePrice4Quantity8Occurrence }

(***************************************************************************)
(* Bulk Quote Price 4 Quantity 8                                           *)
(***************************************************************************)

BulkQuotePrice4Quantity8 ==
    [ incomingMessagesHeader             : IncomingMessagesHeader24,
      group                              : Sample(2),
      quoteIdentifierOnThisGroup         : Sample(8),
      bulkQuotePrice4Quantity8Occurrence : SampleLists(OneBulkQuotePrice4Quantity8Occurrence) ]

EncodeBulkQuotePrice4Quantity8(message) ==
    EncodeIncomingMessagesHeader24(message.incomingMessagesHeader)
        \o message.group
        \o message.quoteIdentifierOnThisGroup
        \o EncodeDigits(Len(message.bulkQuotePrice4Quantity8Occurrence), 3)
        \o EncodeBulkQuotePrice4Quantity8OccurrenceList(message.bulkQuotePrice4Quantity8Occurrence)

DecodeBulkQuotePrice4Quantity8(bytes) ==
    LET incomingMessagesHeader == DecodeIncomingMessagesHeader24(bytes) IN IF ~incomingMessagesHeader.ok THEN Fail ELSE
    LET group == ReadBytes(incomingMessagesHeader.rest, 2) IN IF ~group.ok THEN Fail ELSE
    LET quoteIdentifierOnThisGroup == ReadBytes(group.rest, 8) IN IF ~quoteIdentifierOnThisGroup.ok THEN Fail ELSE
    LET numberOfQuotes == ReadDigits(quoteIdentifierOnThisGroup.rest, 3) IN IF ~numberOfQuotes.ok THEN Fail ELSE
    LET bulkQuotePrice4Quantity8Occurrence == ReadBulkQuotePrice4Quantity8OccurrenceList(numberOfQuotes.rest, numberOfQuotes.value) IN IF ~bulkQuotePrice4Quantity8Occurrence.ok THEN Fail ELSE
    Ok([ incomingMessagesHeader             |-> incomingMessagesHeader.value,
         group                              |-> group.value,
         quoteIdentifierOnThisGroup         |-> quoteIdentifierOnThisGroup.value,
         bulkQuotePrice4Quantity8Occurrence |-> bulkQuotePrice4Quantity8Occurrence.value ], bulkQuotePrice4Quantity8Occurrence.rest)

ZeroBulkQuotePrice4Quantity8 ==
    [ incomingMessagesHeader             |-> ZeroIncomingMessagesHeader24,
      group                              |-> [i \in 1 .. 2 |-> 0],
      quoteIdentifierOnThisGroup         |-> [i \in 1 .. 8 |-> 0],
      bulkQuotePrice4Quantity8Occurrence |-> << >> ]

(* Bulk Quote Price 4 Quantity 8 at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuotePrice4Quantity8 ==
    { ZeroBulkQuotePrice4Quantity8 }
        \cup { [ZeroBulkQuotePrice4Quantity8 EXCEPT !.incomingMessagesHeader = one] : one \in CheckedIncomingMessagesHeader24 }
        \cup { [ZeroBulkQuotePrice4Quantity8 EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuotePrice4Quantity8 EXCEPT !.quoteIdentifierOnThisGroup = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuotePrice4Quantity8 EXCEPT !.bulkQuotePrice4Quantity8Occurrence = one] : one \in SampleLists(OneBulkQuotePrice4Quantity8Occurrence) }

(***************************************************************************)
(* Incoming Messages Header: 22 bytes                                      *)
(***************************************************************************)

IncomingMessagesHeader25 ==
    [ userTimestampLocalHhmmss : Sample(6),
      traderId                 : Sample(8),
      userSequenceId           : Sample(8) ]

EncodeIncomingMessagesHeader25(message) ==
    message.userTimestampLocalHhmmss
        \o message.traderId
        \o message.userSequenceId

DecodeIncomingMessagesHeader25(bytes) ==
    LET userTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~userTimestampLocalHhmmss.ok THEN Fail ELSE
    LET traderId == ReadBytes(userTimestampLocalHhmmss.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(traderId.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    Ok([ userTimestampLocalHhmmss |-> userTimestampLocalHhmmss.value,
         traderId                 |-> traderId.value,
         userSequenceId           |-> userSequenceId.value ], userSequenceId.rest)

ZeroIncomingMessagesHeader25 ==
    [ userTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      traderId                 |-> [i \in 1 .. 8 |-> 0],
      userSequenceId           |-> [i \in 1 .. 8 |-> 0] ]

(* Incoming Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedIncomingMessagesHeader25 ==
    { ZeroIncomingMessagesHeader25 }
        \cup { [ZeroIncomingMessagesHeader25 EXCEPT !.userTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroIncomingMessagesHeader25 EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroIncomingMessagesHeader25 EXCEPT !.userSequenceId = one] : one \in Sample(8) }

(***************************************************************************)
(* Bulk Quote Price 6 Quantity 8 Occurrence: 22 bytes                      *)
(***************************************************************************)

BulkQuotePrice6Quantity8Occurrence ==
    [ group          : Sample(2),
      instrument     : Sample(4),
      verbSide       : Sample(1),
      quantitySignOr : Sample(1),
      quantity       : Sample(8),
      price6         : Sample(6) ]

EncodeBulkQuotePrice6Quantity8Occurrence(message) ==
    message.group
        \o message.instrument
        \o message.verbSide
        \o message.quantitySignOr
        \o message.quantity
        \o message.price6

DecodeBulkQuotePrice6Quantity8Occurrence(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrument == ReadBytes(group.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET verbSide == ReadBytes(instrument.rest, 1) IN IF ~verbSide.ok THEN Fail ELSE
    LET quantitySignOr == ReadBytes(verbSide.rest, 1) IN IF ~quantitySignOr.ok THEN Fail ELSE
    LET quantity == ReadBytes(quantitySignOr.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET price6 == ReadBytes(quantity.rest, 6) IN IF ~price6.ok THEN Fail ELSE
    Ok([ group          |-> group.value,
         instrument     |-> instrument.value,
         verbSide       |-> verbSide.value,
         quantitySignOr |-> quantitySignOr.value,
         quantity       |-> quantity.value,
         price6         |-> price6.value ], price6.rest)

ZeroBulkQuotePrice6Quantity8Occurrence ==
    [ group          |-> [i \in 1 .. 2 |-> 0],
      instrument     |-> [i \in 1 .. 4 |-> 0],
      verbSide       |-> [i \in 1 .. 1 |-> 0],
      quantitySignOr |-> [i \in 1 .. 1 |-> 0],
      quantity       |-> [i \in 1 .. 8 |-> 0],
      price6         |-> [i \in 1 .. 6 |-> 0] ]

(* Bulk Quote Price 6 Quantity 8 Occurrence at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuotePrice6Quantity8Occurrence ==
    { ZeroBulkQuotePrice6Quantity8Occurrence }
        \cup { [ZeroBulkQuotePrice6Quantity8Occurrence EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuotePrice6Quantity8Occurrence EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroBulkQuotePrice6Quantity8Occurrence EXCEPT !.verbSide = one] : one \in Sample(1) }
        \cup { [ZeroBulkQuotePrice6Quantity8Occurrence EXCEPT !.quantitySignOr = one] : one \in Sample(1) }
        \cup { [ZeroBulkQuotePrice6Quantity8Occurrence EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuotePrice6Quantity8Occurrence EXCEPT !.price6 = one] : one \in Sample(6) }

(* A run of Bulk Quote Price 6 Quantity 8 Occurrence, written one after another *)
RECURSIVE EncodeBulkQuotePrice6Quantity8OccurrenceList(_)
EncodeBulkQuotePrice6Quantity8OccurrenceList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeBulkQuotePrice6Quantity8Occurrence(Head(messages)) \o EncodeBulkQuotePrice6Quantity8OccurrenceList(Tail(messages))

(* As many Bulk Quote Price 6 Quantity 8 Occurrence as the field that counts them says *)
RECURSIVE ReadBulkQuotePrice6Quantity8OccurrenceList(_, _)
ReadBulkQuotePrice6Quantity8OccurrenceList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeBulkQuotePrice6Quantity8Occurrence(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadBulkQuotePrice6Quantity8OccurrenceList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Bulk Quote Price 6 Quantity 8 Occurrence of each kind, for the lists that carry them *)
OneBulkQuotePrice6Quantity8Occurrence == { ZeroBulkQuotePrice6Quantity8Occurrence }

(***************************************************************************)
(* Bulk Quote Price 6 Quantity 8                                           *)
(***************************************************************************)

BulkQuotePrice6Quantity8 ==
    [ incomingMessagesHeader             : IncomingMessagesHeader25,
      group                              : Sample(2),
      quoteIdentifierOnThisGroup         : Sample(8),
      bulkQuotePrice6Quantity8Occurrence : SampleLists(OneBulkQuotePrice6Quantity8Occurrence) ]

EncodeBulkQuotePrice6Quantity8(message) ==
    EncodeIncomingMessagesHeader25(message.incomingMessagesHeader)
        \o message.group
        \o message.quoteIdentifierOnThisGroup
        \o EncodeDigits(Len(message.bulkQuotePrice6Quantity8Occurrence), 3)
        \o EncodeBulkQuotePrice6Quantity8OccurrenceList(message.bulkQuotePrice6Quantity8Occurrence)

DecodeBulkQuotePrice6Quantity8(bytes) ==
    LET incomingMessagesHeader == DecodeIncomingMessagesHeader25(bytes) IN IF ~incomingMessagesHeader.ok THEN Fail ELSE
    LET group == ReadBytes(incomingMessagesHeader.rest, 2) IN IF ~group.ok THEN Fail ELSE
    LET quoteIdentifierOnThisGroup == ReadBytes(group.rest, 8) IN IF ~quoteIdentifierOnThisGroup.ok THEN Fail ELSE
    LET numberOfQuotes == ReadDigits(quoteIdentifierOnThisGroup.rest, 3) IN IF ~numberOfQuotes.ok THEN Fail ELSE
    LET bulkQuotePrice6Quantity8Occurrence == ReadBulkQuotePrice6Quantity8OccurrenceList(numberOfQuotes.rest, numberOfQuotes.value) IN IF ~bulkQuotePrice6Quantity8Occurrence.ok THEN Fail ELSE
    Ok([ incomingMessagesHeader             |-> incomingMessagesHeader.value,
         group                              |-> group.value,
         quoteIdentifierOnThisGroup         |-> quoteIdentifierOnThisGroup.value,
         bulkQuotePrice6Quantity8Occurrence |-> bulkQuotePrice6Quantity8Occurrence.value ], bulkQuotePrice6Quantity8Occurrence.rest)

ZeroBulkQuotePrice6Quantity8 ==
    [ incomingMessagesHeader             |-> ZeroIncomingMessagesHeader25,
      group                              |-> [i \in 1 .. 2 |-> 0],
      quoteIdentifierOnThisGroup         |-> [i \in 1 .. 8 |-> 0],
      bulkQuotePrice6Quantity8Occurrence |-> << >> ]

(* Bulk Quote Price 6 Quantity 8 at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuotePrice6Quantity8 ==
    { ZeroBulkQuotePrice6Quantity8 }
        \cup { [ZeroBulkQuotePrice6Quantity8 EXCEPT !.incomingMessagesHeader = one] : one \in CheckedIncomingMessagesHeader25 }
        \cup { [ZeroBulkQuotePrice6Quantity8 EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuotePrice6Quantity8 EXCEPT !.quoteIdentifierOnThisGroup = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuotePrice6Quantity8 EXCEPT !.bulkQuotePrice6Quantity8Occurrence = one] : one \in SampleLists(OneBulkQuotePrice6Quantity8Occurrence) }

(***************************************************************************)
(* Incoming Messages Header: 22 bytes                                      *)
(***************************************************************************)

IncomingMessagesHeader26 ==
    [ userTimestampLocalHhmmss : Sample(6),
      traderId                 : Sample(8),
      userSequenceId           : Sample(8) ]

EncodeIncomingMessagesHeader26(message) ==
    message.userTimestampLocalHhmmss
        \o message.traderId
        \o message.userSequenceId

DecodeIncomingMessagesHeader26(bytes) ==
    LET userTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~userTimestampLocalHhmmss.ok THEN Fail ELSE
    LET traderId == ReadBytes(userTimestampLocalHhmmss.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(traderId.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    Ok([ userTimestampLocalHhmmss |-> userTimestampLocalHhmmss.value,
         traderId                 |-> traderId.value,
         userSequenceId           |-> userSequenceId.value ], userSequenceId.rest)

ZeroIncomingMessagesHeader26 ==
    [ userTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      traderId                 |-> [i \in 1 .. 8 |-> 0],
      userSequenceId           |-> [i \in 1 .. 8 |-> 0] ]

(* Incoming Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedIncomingMessagesHeader26 ==
    { ZeroIncomingMessagesHeader26 }
        \cup { [ZeroIncomingMessagesHeader26 EXCEPT !.userTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroIncomingMessagesHeader26 EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroIncomingMessagesHeader26 EXCEPT !.userSequenceId = one] : one \in Sample(8) }

(***************************************************************************)
(* Bulk Quote Price 8 Quantity 8 Occurrence: 24 bytes                      *)
(***************************************************************************)

BulkQuotePrice8Quantity8Occurrence ==
    [ group          : Sample(2),
      instrument     : Sample(4),
      verbSide       : Sample(1),
      quantitySignOr : Sample(1),
      quantity       : Sample(8),
      price8         : Sample(8) ]

EncodeBulkQuotePrice8Quantity8Occurrence(message) ==
    message.group
        \o message.instrument
        \o message.verbSide
        \o message.quantitySignOr
        \o message.quantity
        \o message.price8

DecodeBulkQuotePrice8Quantity8Occurrence(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrument == ReadBytes(group.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET verbSide == ReadBytes(instrument.rest, 1) IN IF ~verbSide.ok THEN Fail ELSE
    LET quantitySignOr == ReadBytes(verbSide.rest, 1) IN IF ~quantitySignOr.ok THEN Fail ELSE
    LET quantity == ReadBytes(quantitySignOr.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET price8 == ReadBytes(quantity.rest, 8) IN IF ~price8.ok THEN Fail ELSE
    Ok([ group          |-> group.value,
         instrument     |-> instrument.value,
         verbSide       |-> verbSide.value,
         quantitySignOr |-> quantitySignOr.value,
         quantity       |-> quantity.value,
         price8         |-> price8.value ], price8.rest)

ZeroBulkQuotePrice8Quantity8Occurrence ==
    [ group          |-> [i \in 1 .. 2 |-> 0],
      instrument     |-> [i \in 1 .. 4 |-> 0],
      verbSide       |-> [i \in 1 .. 1 |-> 0],
      quantitySignOr |-> [i \in 1 .. 1 |-> 0],
      quantity       |-> [i \in 1 .. 8 |-> 0],
      price8         |-> [i \in 1 .. 8 |-> 0] ]

(* Bulk Quote Price 8 Quantity 8 Occurrence at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuotePrice8Quantity8Occurrence ==
    { ZeroBulkQuotePrice8Quantity8Occurrence }
        \cup { [ZeroBulkQuotePrice8Quantity8Occurrence EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuotePrice8Quantity8Occurrence EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroBulkQuotePrice8Quantity8Occurrence EXCEPT !.verbSide = one] : one \in Sample(1) }
        \cup { [ZeroBulkQuotePrice8Quantity8Occurrence EXCEPT !.quantitySignOr = one] : one \in Sample(1) }
        \cup { [ZeroBulkQuotePrice8Quantity8Occurrence EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuotePrice8Quantity8Occurrence EXCEPT !.price8 = one] : one \in Sample(8) }

(* A run of Bulk Quote Price 8 Quantity 8 Occurrence, written one after another *)
RECURSIVE EncodeBulkQuotePrice8Quantity8OccurrenceList(_)
EncodeBulkQuotePrice8Quantity8OccurrenceList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeBulkQuotePrice8Quantity8Occurrence(Head(messages)) \o EncodeBulkQuotePrice8Quantity8OccurrenceList(Tail(messages))

(* As many Bulk Quote Price 8 Quantity 8 Occurrence as the field that counts them says *)
RECURSIVE ReadBulkQuotePrice8Quantity8OccurrenceList(_, _)
ReadBulkQuotePrice8Quantity8OccurrenceList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeBulkQuotePrice8Quantity8Occurrence(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadBulkQuotePrice8Quantity8OccurrenceList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Bulk Quote Price 8 Quantity 8 Occurrence of each kind, for the lists that carry them *)
OneBulkQuotePrice8Quantity8Occurrence == { ZeroBulkQuotePrice8Quantity8Occurrence }

(***************************************************************************)
(* Bulk Quote Price 8 Quantity 8                                           *)
(***************************************************************************)

BulkQuotePrice8Quantity8 ==
    [ incomingMessagesHeader             : IncomingMessagesHeader26,
      group                              : Sample(2),
      quoteIdentifierOnThisGroup         : Sample(8),
      bulkQuotePrice8Quantity8Occurrence : SampleLists(OneBulkQuotePrice8Quantity8Occurrence) ]

EncodeBulkQuotePrice8Quantity8(message) ==
    EncodeIncomingMessagesHeader26(message.incomingMessagesHeader)
        \o message.group
        \o message.quoteIdentifierOnThisGroup
        \o EncodeDigits(Len(message.bulkQuotePrice8Quantity8Occurrence), 3)
        \o EncodeBulkQuotePrice8Quantity8OccurrenceList(message.bulkQuotePrice8Quantity8Occurrence)

DecodeBulkQuotePrice8Quantity8(bytes) ==
    LET incomingMessagesHeader == DecodeIncomingMessagesHeader26(bytes) IN IF ~incomingMessagesHeader.ok THEN Fail ELSE
    LET group == ReadBytes(incomingMessagesHeader.rest, 2) IN IF ~group.ok THEN Fail ELSE
    LET quoteIdentifierOnThisGroup == ReadBytes(group.rest, 8) IN IF ~quoteIdentifierOnThisGroup.ok THEN Fail ELSE
    LET numberOfQuotes == ReadDigits(quoteIdentifierOnThisGroup.rest, 3) IN IF ~numberOfQuotes.ok THEN Fail ELSE
    LET bulkQuotePrice8Quantity8Occurrence == ReadBulkQuotePrice8Quantity8OccurrenceList(numberOfQuotes.rest, numberOfQuotes.value) IN IF ~bulkQuotePrice8Quantity8Occurrence.ok THEN Fail ELSE
    Ok([ incomingMessagesHeader             |-> incomingMessagesHeader.value,
         group                              |-> group.value,
         quoteIdentifierOnThisGroup         |-> quoteIdentifierOnThisGroup.value,
         bulkQuotePrice8Quantity8Occurrence |-> bulkQuotePrice8Quantity8Occurrence.value ], bulkQuotePrice8Quantity8Occurrence.rest)

ZeroBulkQuotePrice8Quantity8 ==
    [ incomingMessagesHeader             |-> ZeroIncomingMessagesHeader26,
      group                              |-> [i \in 1 .. 2 |-> 0],
      quoteIdentifierOnThisGroup         |-> [i \in 1 .. 8 |-> 0],
      bulkQuotePrice8Quantity8Occurrence |-> << >> ]

(* Bulk Quote Price 8 Quantity 8 at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuotePrice8Quantity8 ==
    { ZeroBulkQuotePrice8Quantity8 }
        \cup { [ZeroBulkQuotePrice8Quantity8 EXCEPT !.incomingMessagesHeader = one] : one \in CheckedIncomingMessagesHeader26 }
        \cup { [ZeroBulkQuotePrice8Quantity8 EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuotePrice8Quantity8 EXCEPT !.quoteIdentifierOnThisGroup = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuotePrice8Quantity8 EXCEPT !.bulkQuotePrice8Quantity8Occurrence = one] : one \in SampleLists(OneBulkQuotePrice8Quantity8Occurrence) }

(***************************************************************************)
(* Incoming Messages Header: 22 bytes                                      *)
(***************************************************************************)

IncomingMessagesHeader27 ==
    [ userTimestampLocalHhmmss : Sample(6),
      traderId                 : Sample(8),
      userSequenceId           : Sample(8) ]

EncodeIncomingMessagesHeader27(message) ==
    message.userTimestampLocalHhmmss
        \o message.traderId
        \o message.userSequenceId

DecodeIncomingMessagesHeader27(bytes) ==
    LET userTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~userTimestampLocalHhmmss.ok THEN Fail ELSE
    LET traderId == ReadBytes(userTimestampLocalHhmmss.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(traderId.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    Ok([ userTimestampLocalHhmmss |-> userTimestampLocalHhmmss.value,
         traderId                 |-> traderId.value,
         userSequenceId           |-> userSequenceId.value ], userSequenceId.rest)

ZeroIncomingMessagesHeader27 ==
    [ userTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      traderId                 |-> [i \in 1 .. 8 |-> 0],
      userSequenceId           |-> [i \in 1 .. 8 |-> 0] ]

(* Incoming Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedIncomingMessagesHeader27 ==
    { ZeroIncomingMessagesHeader27 }
        \cup { [ZeroIncomingMessagesHeader27 EXCEPT !.userTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroIncomingMessagesHeader27 EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroIncomingMessagesHeader27 EXCEPT !.userSequenceId = one] : one \in Sample(8) }

(***************************************************************************)
(* Bulk Quote Occurrence: 26 bytes                                         *)
(***************************************************************************)

BulkQuoteOccurrence ==
    [ group          : Sample(2),
      instrument     : Sample(4),
      verbSide       : Sample(1),
      quantitySignOr : Sample(1),
      quantity       : Sample(8),
      price          : Sample(10) ]

EncodeBulkQuoteOccurrence(message) ==
    message.group
        \o message.instrument
        \o message.verbSide
        \o message.quantitySignOr
        \o message.quantity
        \o message.price

DecodeBulkQuoteOccurrence(bytes) ==
    LET group == ReadBytes(bytes, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrument == ReadBytes(group.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET verbSide == ReadBytes(instrument.rest, 1) IN IF ~verbSide.ok THEN Fail ELSE
    LET quantitySignOr == ReadBytes(verbSide.rest, 1) IN IF ~quantitySignOr.ok THEN Fail ELSE
    LET quantity == ReadBytes(quantitySignOr.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 10) IN IF ~price.ok THEN Fail ELSE
    Ok([ group          |-> group.value,
         instrument     |-> instrument.value,
         verbSide       |-> verbSide.value,
         quantitySignOr |-> quantitySignOr.value,
         quantity       |-> quantity.value,
         price          |-> price.value ], price.rest)

ZeroBulkQuoteOccurrence ==
    [ group          |-> [i \in 1 .. 2 |-> 0],
      instrument     |-> [i \in 1 .. 4 |-> 0],
      verbSide       |-> [i \in 1 .. 1 |-> 0],
      quantitySignOr |-> [i \in 1 .. 1 |-> 0],
      quantity       |-> [i \in 1 .. 8 |-> 0],
      price          |-> [i \in 1 .. 10 |-> 0] ]

(* Bulk Quote Occurrence at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuoteOccurrence ==
    { ZeroBulkQuoteOccurrence }
        \cup { [ZeroBulkQuoteOccurrence EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuoteOccurrence EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroBulkQuoteOccurrence EXCEPT !.verbSide = one] : one \in Sample(1) }
        \cup { [ZeroBulkQuoteOccurrence EXCEPT !.quantitySignOr = one] : one \in Sample(1) }
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
    [ incomingMessagesHeader     : IncomingMessagesHeader27,
      group                      : Sample(2),
      quoteIdentifierOnThisGroup : Sample(8),
      bulkQuoteOccurrence        : SampleLists(OneBulkQuoteOccurrence) ]

EncodeBulkQuote(message) ==
    EncodeIncomingMessagesHeader27(message.incomingMessagesHeader)
        \o message.group
        \o message.quoteIdentifierOnThisGroup
        \o EncodeDigits(Len(message.bulkQuoteOccurrence), 3)
        \o EncodeBulkQuoteOccurrenceList(message.bulkQuoteOccurrence)

DecodeBulkQuote(bytes) ==
    LET incomingMessagesHeader == DecodeIncomingMessagesHeader27(bytes) IN IF ~incomingMessagesHeader.ok THEN Fail ELSE
    LET group == ReadBytes(incomingMessagesHeader.rest, 2) IN IF ~group.ok THEN Fail ELSE
    LET quoteIdentifierOnThisGroup == ReadBytes(group.rest, 8) IN IF ~quoteIdentifierOnThisGroup.ok THEN Fail ELSE
    LET numberOfQuotes == ReadDigits(quoteIdentifierOnThisGroup.rest, 3) IN IF ~numberOfQuotes.ok THEN Fail ELSE
    LET bulkQuoteOccurrence == ReadBulkQuoteOccurrenceList(numberOfQuotes.rest, numberOfQuotes.value) IN IF ~bulkQuoteOccurrence.ok THEN Fail ELSE
    Ok([ incomingMessagesHeader     |-> incomingMessagesHeader.value,
         group                      |-> group.value,
         quoteIdentifierOnThisGroup |-> quoteIdentifierOnThisGroup.value,
         bulkQuoteOccurrence        |-> bulkQuoteOccurrence.value ], bulkQuoteOccurrence.rest)

ZeroBulkQuote ==
    [ incomingMessagesHeader     |-> ZeroIncomingMessagesHeader27,
      group                      |-> [i \in 1 .. 2 |-> 0],
      quoteIdentifierOnThisGroup |-> [i \in 1 .. 8 |-> 0],
      bulkQuoteOccurrence        |-> << >> ]

(* Bulk Quote at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuote ==
    { ZeroBulkQuote }
        \cup { [ZeroBulkQuote EXCEPT !.incomingMessagesHeader = one] : one \in CheckedIncomingMessagesHeader27 }
        \cup { [ZeroBulkQuote EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuote EXCEPT !.quoteIdentifierOnThisGroup = one] : one \in Sample(8) }
        \cup { [ZeroBulkQuote EXCEPT !.bulkQuoteOccurrence = one] : one \in SampleLists(OneBulkQuoteOccurrence) }

(***************************************************************************)
(* Incoming Messages Header: 22 bytes                                      *)
(***************************************************************************)

IncomingMessagesHeader28 ==
    [ userTimestampLocalHhmmss : Sample(6),
      traderId                 : Sample(8),
      userSequenceId           : Sample(8) ]

EncodeIncomingMessagesHeader28(message) ==
    message.userTimestampLocalHhmmss
        \o message.traderId
        \o message.userSequenceId

DecodeIncomingMessagesHeader28(bytes) ==
    LET userTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~userTimestampLocalHhmmss.ok THEN Fail ELSE
    LET traderId == ReadBytes(userTimestampLocalHhmmss.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(traderId.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    Ok([ userTimestampLocalHhmmss |-> userTimestampLocalHhmmss.value,
         traderId                 |-> traderId.value,
         userSequenceId           |-> userSequenceId.value ], userSequenceId.rest)

ZeroIncomingMessagesHeader28 ==
    [ userTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      traderId                 |-> [i \in 1 .. 8 |-> 0],
      userSequenceId           |-> [i \in 1 .. 8 |-> 0] ]

(* Incoming Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedIncomingMessagesHeader28 ==
    { ZeroIncomingMessagesHeader28 }
        \cup { [ZeroIncomingMessagesHeader28 EXCEPT !.userTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroIncomingMessagesHeader28 EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroIncomingMessagesHeader28 EXCEPT !.userSequenceId = one] : one \in Sample(8) }

(***************************************************************************)
(* Sail Request For Quote With Side: 37 bytes                              *)
(***************************************************************************)

SailRequestForQuoteWithSide ==
    [ incomingMessagesHeader : IncomingMessagesHeader28,
      group                  : Sample(2),
      instrument             : Sample(4),
      quantity               : Sample(8),
      marketSide             : Sample(1) ]

EncodeSailRequestForQuoteWithSide(message) ==
    EncodeIncomingMessagesHeader28(message.incomingMessagesHeader)
        \o message.group
        \o message.instrument
        \o message.quantity
        \o message.marketSide

DecodeSailRequestForQuoteWithSide(bytes) ==
    LET incomingMessagesHeader == DecodeIncomingMessagesHeader28(bytes) IN IF ~incomingMessagesHeader.ok THEN Fail ELSE
    LET group == ReadBytes(incomingMessagesHeader.rest, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrument == ReadBytes(group.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET quantity == ReadBytes(instrument.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET marketSide == ReadBytes(quantity.rest, 1) IN IF ~marketSide.ok THEN Fail ELSE
    Ok([ incomingMessagesHeader |-> incomingMessagesHeader.value,
         group                  |-> group.value,
         instrument             |-> instrument.value,
         quantity               |-> quantity.value,
         marketSide             |-> marketSide.value ], marketSide.rest)

ZeroSailRequestForQuoteWithSide ==
    [ incomingMessagesHeader |-> ZeroIncomingMessagesHeader28,
      group                  |-> [i \in 1 .. 2 |-> 0],
      instrument             |-> [i \in 1 .. 4 |-> 0],
      quantity               |-> [i \in 1 .. 8 |-> 0],
      marketSide             |-> [i \in 1 .. 1 |-> 0] ]

(* Sail Request For Quote With Side at zero, then each field in turn at the values it is checked at *)
CheckedSailRequestForQuoteWithSide ==
    { ZeroSailRequestForQuoteWithSide }
        \cup { [ZeroSailRequestForQuoteWithSide EXCEPT !.incomingMessagesHeader = one] : one \in CheckedIncomingMessagesHeader28 }
        \cup { [ZeroSailRequestForQuoteWithSide EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroSailRequestForQuoteWithSide EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroSailRequestForQuoteWithSide EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroSailRequestForQuoteWithSide EXCEPT !.marketSide = one] : one \in Sample(1) }

(***************************************************************************)
(* Incoming Messages Header: 22 bytes                                      *)
(***************************************************************************)

IncomingMessagesHeader29 ==
    [ userTimestampLocalHhmmss : Sample(6),
      traderId                 : Sample(8),
      userSequenceId           : Sample(8) ]

EncodeIncomingMessagesHeader29(message) ==
    message.userTimestampLocalHhmmss
        \o message.traderId
        \o message.userSequenceId

DecodeIncomingMessagesHeader29(bytes) ==
    LET userTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~userTimestampLocalHhmmss.ok THEN Fail ELSE
    LET traderId == ReadBytes(userTimestampLocalHhmmss.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(traderId.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    Ok([ userTimestampLocalHhmmss |-> userTimestampLocalHhmmss.value,
         traderId                 |-> traderId.value,
         userSequenceId           |-> userSequenceId.value ], userSequenceId.rest)

ZeroIncomingMessagesHeader29 ==
    [ userTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      traderId                 |-> [i \in 1 .. 8 |-> 0],
      userSequenceId           |-> [i \in 1 .. 8 |-> 0] ]

(* Incoming Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedIncomingMessagesHeader29 ==
    { ZeroIncomingMessagesHeader29 }
        \cup { [ZeroIncomingMessagesHeader29 EXCEPT !.userTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroIncomingMessagesHeader29 EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroIncomingMessagesHeader29 EXCEPT !.userSequenceId = one] : one \in Sample(8) }

(***************************************************************************)
(* Bulk Quote Participant Bqp Protection Subscription: 25 bytes            *)
(***************************************************************************)

BulkQuoteParticipantBqpProtectionSubscription ==
    [ incomingMessagesHeader                                     : IncomingMessagesHeader29,
      group                                                      : Sample(2),
      protectionTypeAdvancedProtectionAdvancedProtectionDisabled : Sample(1) ]

EncodeBulkQuoteParticipantBqpProtectionSubscription(message) ==
    EncodeIncomingMessagesHeader29(message.incomingMessagesHeader)
        \o message.group
        \o message.protectionTypeAdvancedProtectionAdvancedProtectionDisabled

DecodeBulkQuoteParticipantBqpProtectionSubscription(bytes) ==
    LET incomingMessagesHeader == DecodeIncomingMessagesHeader29(bytes) IN IF ~incomingMessagesHeader.ok THEN Fail ELSE
    LET group == ReadBytes(incomingMessagesHeader.rest, 2) IN IF ~group.ok THEN Fail ELSE
    LET protectionTypeAdvancedProtectionAdvancedProtectionDisabled == ReadBytes(group.rest, 1) IN IF ~protectionTypeAdvancedProtectionAdvancedProtectionDisabled.ok THEN Fail ELSE
    Ok([ incomingMessagesHeader                                     |-> incomingMessagesHeader.value,
         group                                                      |-> group.value,
         protectionTypeAdvancedProtectionAdvancedProtectionDisabled |-> protectionTypeAdvancedProtectionAdvancedProtectionDisabled.value ], protectionTypeAdvancedProtectionAdvancedProtectionDisabled.rest)

ZeroBulkQuoteParticipantBqpProtectionSubscription ==
    [ incomingMessagesHeader                                     |-> ZeroIncomingMessagesHeader29,
      group                                                      |-> [i \in 1 .. 2 |-> 0],
      protectionTypeAdvancedProtectionAdvancedProtectionDisabled |-> [i \in 1 .. 1 |-> 0] ]

(* Bulk Quote Participant Bqp Protection Subscription at zero, then each field in turn at the values it is checked at *)
CheckedBulkQuoteParticipantBqpProtectionSubscription ==
    { ZeroBulkQuoteParticipantBqpProtectionSubscription }
        \cup { [ZeroBulkQuoteParticipantBqpProtectionSubscription EXCEPT !.incomingMessagesHeader = one] : one \in CheckedIncomingMessagesHeader29 }
        \cup { [ZeroBulkQuoteParticipantBqpProtectionSubscription EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroBulkQuoteParticipantBqpProtectionSubscription EXCEPT !.protectionTypeAdvancedProtectionAdvancedProtectionDisabled = one] : one \in Sample(1) }

(***************************************************************************)
(* Incoming Messages Header: 22 bytes                                      *)
(***************************************************************************)

IncomingMessagesHeader30 ==
    [ userTimestampLocalHhmmss : Sample(6),
      traderId                 : Sample(8),
      userSequenceId           : Sample(8) ]

EncodeIncomingMessagesHeader30(message) ==
    message.userTimestampLocalHhmmss
        \o message.traderId
        \o message.userSequenceId

DecodeIncomingMessagesHeader30(bytes) ==
    LET userTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~userTimestampLocalHhmmss.ok THEN Fail ELSE
    LET traderId == ReadBytes(userTimestampLocalHhmmss.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(traderId.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    Ok([ userTimestampLocalHhmmss |-> userTimestampLocalHhmmss.value,
         traderId                 |-> traderId.value,
         userSequenceId           |-> userSequenceId.value ], userSequenceId.rest)

ZeroIncomingMessagesHeader30 ==
    [ userTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      traderId                 |-> [i \in 1 .. 8 |-> 0],
      userSequenceId           |-> [i \in 1 .. 8 |-> 0] ]

(* Incoming Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedIncomingMessagesHeader30 ==
    { ZeroIncomingMessagesHeader30 }
        \cup { [ZeroIncomingMessagesHeader30 EXCEPT !.userTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroIncomingMessagesHeader30 EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroIncomingMessagesHeader30 EXCEPT !.userSequenceId = one] : one \in Sample(8) }

(***************************************************************************)
(* Request For Quote: 36 bytes                                             *)
(***************************************************************************)

RequestForQuote ==
    [ incomingMessagesHeader : IncomingMessagesHeader30,
      group                  : Sample(2),
      instrument             : Sample(4),
      quantity               : Sample(8) ]

EncodeRequestForQuote(message) ==
    EncodeIncomingMessagesHeader30(message.incomingMessagesHeader)
        \o message.group
        \o message.instrument
        \o message.quantity

DecodeRequestForQuote(bytes) ==
    LET incomingMessagesHeader == DecodeIncomingMessagesHeader30(bytes) IN IF ~incomingMessagesHeader.ok THEN Fail ELSE
    LET group == ReadBytes(incomingMessagesHeader.rest, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrument == ReadBytes(group.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET quantity == ReadBytes(instrument.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    Ok([ incomingMessagesHeader |-> incomingMessagesHeader.value,
         group                  |-> group.value,
         instrument             |-> instrument.value,
         quantity               |-> quantity.value ], quantity.rest)

ZeroRequestForQuote ==
    [ incomingMessagesHeader |-> ZeroIncomingMessagesHeader30,
      group                  |-> [i \in 1 .. 2 |-> 0],
      instrument             |-> [i \in 1 .. 4 |-> 0],
      quantity               |-> [i \in 1 .. 8 |-> 0] ]

(* Request For Quote at zero, then each field in turn at the values it is checked at *)
CheckedRequestForQuote ==
    { ZeroRequestForQuote }
        \cup { [ZeroRequestForQuote EXCEPT !.incomingMessagesHeader = one] : one \in CheckedIncomingMessagesHeader30 }
        \cup { [ZeroRequestForQuote EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroRequestForQuote EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroRequestForQuote EXCEPT !.quantity = one] : one \in Sample(8) }

(***************************************************************************)
(* Incoming Messages Header: 22 bytes                                      *)
(***************************************************************************)

IncomingMessagesHeader31 ==
    [ userTimestampLocalHhmmss : Sample(6),
      traderId                 : Sample(8),
      userSequenceId           : Sample(8) ]

EncodeIncomingMessagesHeader31(message) ==
    message.userTimestampLocalHhmmss
        \o message.traderId
        \o message.userSequenceId

DecodeIncomingMessagesHeader31(bytes) ==
    LET userTimestampLocalHhmmss == ReadBytes(bytes, 6) IN IF ~userTimestampLocalHhmmss.ok THEN Fail ELSE
    LET traderId == ReadBytes(userTimestampLocalHhmmss.rest, 8) IN IF ~traderId.ok THEN Fail ELSE
    LET userSequenceId == ReadBytes(traderId.rest, 8) IN IF ~userSequenceId.ok THEN Fail ELSE
    Ok([ userTimestampLocalHhmmss |-> userTimestampLocalHhmmss.value,
         traderId                 |-> traderId.value,
         userSequenceId           |-> userSequenceId.value ], userSequenceId.rest)

ZeroIncomingMessagesHeader31 ==
    [ userTimestampLocalHhmmss |-> [i \in 1 .. 6 |-> 0],
      traderId                 |-> [i \in 1 .. 8 |-> 0],
      userSequenceId           |-> [i \in 1 .. 8 |-> 0] ]

(* Incoming Messages Header at zero, then each field in turn at the values it is checked at *)
CheckedIncomingMessagesHeader31 ==
    { ZeroIncomingMessagesHeader31 }
        \cup { [ZeroIncomingMessagesHeader31 EXCEPT !.userTimestampLocalHhmmss = one] : one \in Sample(6) }
        \cup { [ZeroIncomingMessagesHeader31 EXCEPT !.traderId = one] : one \in Sample(8) }
        \cup { [ZeroIncomingMessagesHeader31 EXCEPT !.userSequenceId = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Cancellation: 36 bytes                                            *)
(***************************************************************************)

OrderCancellation ==
    [ incomingMessagesHeader : IncomingMessagesHeader31,
      group                  : Sample(2),
      instrument             : Sample(4),
      cancelledOrderId       : Sample(8) ]

EncodeOrderCancellation(message) ==
    EncodeIncomingMessagesHeader31(message.incomingMessagesHeader)
        \o message.group
        \o message.instrument
        \o message.cancelledOrderId

DecodeOrderCancellation(bytes) ==
    LET incomingMessagesHeader == DecodeIncomingMessagesHeader31(bytes) IN IF ~incomingMessagesHeader.ok THEN Fail ELSE
    LET group == ReadBytes(incomingMessagesHeader.rest, 2) IN IF ~group.ok THEN Fail ELSE
    LET instrument == ReadBytes(group.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET cancelledOrderId == ReadBytes(instrument.rest, 8) IN IF ~cancelledOrderId.ok THEN Fail ELSE
    Ok([ incomingMessagesHeader |-> incomingMessagesHeader.value,
         group                  |-> group.value,
         instrument             |-> instrument.value,
         cancelledOrderId       |-> cancelledOrderId.value ], cancelledOrderId.rest)

ZeroOrderCancellation ==
    [ incomingMessagesHeader |-> ZeroIncomingMessagesHeader31,
      group                  |-> [i \in 1 .. 2 |-> 0],
      instrument             |-> [i \in 1 .. 4 |-> 0],
      cancelledOrderId       |-> [i \in 1 .. 8 |-> 0] ]

(* Order Cancellation at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancellation ==
    { ZeroOrderCancellation }
        \cup { [ZeroOrderCancellation EXCEPT !.incomingMessagesHeader = one] : one \in CheckedIncomingMessagesHeader31 }
        \cup { [ZeroOrderCancellation EXCEPT !.group = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancellation EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancellation EXCEPT !.cancelledOrderId = one] : one \in Sample(8) }

(***************************************************************************)
(* Firm Message, selected by Message Type                                  *)
(***************************************************************************)

UserConnectionCode == 21571  \* "TC"
DisconnectionInstructionCode == 21569  \* "TA"
HeartbeatResponseCode == 21577  \* "TI"
UserDisconnectionCode == 21572  \* "TD"
OrderRequestCode == 16710  \* "AF"
BulkQuoteDataCode == 16964  \* "BD"
FirmRiskConfigCode == 17234  \* "CR"
GlobalCancellationCode == 18243  \* "GC"
UserGlobalCancellationCode == 18266  \* "GZ"
SetGroupRiskLimitsCode == 19787  \* "MK"
SetGlobalRiskLimitsCode == 19788  \* "ML"
OrderEntryCode == 20293  \* "OE"
OrderModificationCode == 20301  \* "OM"
NewStrategyInstrumentCode == 20302  \* "ON"
CrossEntryCode == 20312  \* "OX"
BulkQuotePrice4Quantity2Code == 20801  \* "QA"
BulkQuotePrice6Quantity2Code == 20802  \* "QB"
BulkQuotePrice8Quantity2Code == 20803  \* "QC"
BulkQuotePrice10Quantity2Code == 20804  \* "QD"
BulkQuotePrice4Quantity4Code == 20805  \* "QE"
BulkQuotePrice6Quantity4Code == 20806  \* "QF"
BulkQuotePrice8Quantity4Code == 20807  \* "QG"
BulkQuotePrice10Quantity4Code == 20808  \* "QH"
BulkQuotePrice4Quantity6Code == 20809  \* "QI"
BulkQuotePrice6Quantity6Code == 20810  \* "QJ"
BulkQuotePrice8Quantity6Code == 20811  \* "QK"
BulkQuotePrice10Quantity6Code == 20812  \* "QL"
BulkQuotePrice4Quantity8Code == 20813  \* "QM"
BulkQuotePrice6Quantity8Code == 20814  \* "QN"
BulkQuotePrice8Quantity8Code == 20815  \* "QO"
BulkQuoteCode == 20816  \* "QP"
SailRequestForQuoteWithSideCode == 20819  \* "QS"
BulkQuoteParticipantBqpProtectionSubscriptionCode == 21072  \* "RP"
RequestForQuoteCode == 21073  \* "RQ"
OrderCancellationCode == 22597  \* "XE"

FirmMessage ==
    [ tag : {UserConnectionCode}, body : UserConnection ]
        \cup [ tag : {DisconnectionInstructionCode}, body : DisconnectionInstruction ]
        \cup [ tag : {HeartbeatResponseCode}, body : HeartbeatResponse ]
        \cup [ tag : {UserDisconnectionCode}, body : UserDisconnection ]
        \cup [ tag : {OrderRequestCode}, body : OrderRequest ]
        \cup [ tag : {BulkQuoteDataCode}, body : BulkQuoteData ]
        \cup [ tag : {FirmRiskConfigCode}, body : FirmRiskConfig ]
        \cup [ tag : {GlobalCancellationCode}, body : GlobalCancellation ]
        \cup [ tag : {UserGlobalCancellationCode}, body : UserGlobalCancellation ]
        \cup [ tag : {SetGroupRiskLimitsCode}, body : SetGroupRiskLimits ]
        \cup [ tag : {SetGlobalRiskLimitsCode}, body : SetGlobalRiskLimits ]
        \cup [ tag : {OrderEntryCode}, body : OrderEntry ]
        \cup [ tag : {OrderModificationCode}, body : OrderModification ]
        \cup [ tag : {NewStrategyInstrumentCode}, body : NewStrategyInstrument ]
        \cup [ tag : {CrossEntryCode}, body : CrossEntry ]
        \cup [ tag : {BulkQuotePrice4Quantity2Code}, body : BulkQuotePrice4Quantity2 ]
        \cup [ tag : {BulkQuotePrice6Quantity2Code}, body : BulkQuotePrice6Quantity2 ]
        \cup [ tag : {BulkQuotePrice8Quantity2Code}, body : BulkQuotePrice8Quantity2 ]
        \cup [ tag : {BulkQuotePrice10Quantity2Code}, body : BulkQuotePrice10Quantity2 ]
        \cup [ tag : {BulkQuotePrice4Quantity4Code}, body : BulkQuotePrice4Quantity4 ]
        \cup [ tag : {BulkQuotePrice6Quantity4Code}, body : BulkQuotePrice6Quantity4 ]
        \cup [ tag : {BulkQuotePrice8Quantity4Code}, body : BulkQuotePrice8Quantity4 ]
        \cup [ tag : {BulkQuotePrice10Quantity4Code}, body : BulkQuotePrice10Quantity4 ]
        \cup [ tag : {BulkQuotePrice4Quantity6Code}, body : BulkQuotePrice4Quantity6 ]
        \cup [ tag : {BulkQuotePrice6Quantity6Code}, body : BulkQuotePrice6Quantity6 ]
        \cup [ tag : {BulkQuotePrice8Quantity6Code}, body : BulkQuotePrice8Quantity6 ]
        \cup [ tag : {BulkQuotePrice10Quantity6Code}, body : BulkQuotePrice10Quantity6 ]
        \cup [ tag : {BulkQuotePrice4Quantity8Code}, body : BulkQuotePrice4Quantity8 ]
        \cup [ tag : {BulkQuotePrice6Quantity8Code}, body : BulkQuotePrice6Quantity8 ]
        \cup [ tag : {BulkQuotePrice8Quantity8Code}, body : BulkQuotePrice8Quantity8 ]
        \cup [ tag : {BulkQuoteCode}, body : BulkQuote ]
        \cup [ tag : {SailRequestForQuoteWithSideCode}, body : SailRequestForQuoteWithSide ]
        \cup [ tag : {BulkQuoteParticipantBqpProtectionSubscriptionCode}, body : BulkQuoteParticipantBqpProtectionSubscription ]
        \cup [ tag : {RequestForQuoteCode}, body : RequestForQuote ]
        \cup [ tag : {OrderCancellationCode}, body : OrderCancellation ]

EncodeFirmMessage(message) ==
    CASE message.tag = UserConnectionCode -> EncodeUserConnection(message.body)
      [] message.tag = DisconnectionInstructionCode -> EncodeDisconnectionInstruction(message.body)
      [] message.tag = HeartbeatResponseCode -> EncodeHeartbeatResponse(message.body)
      [] message.tag = UserDisconnectionCode -> EncodeUserDisconnection(message.body)
      [] message.tag = OrderRequestCode -> EncodeOrderRequest(message.body)
      [] message.tag = BulkQuoteDataCode -> EncodeBulkQuoteData(message.body)
      [] message.tag = FirmRiskConfigCode -> EncodeFirmRiskConfig(message.body)
      [] message.tag = GlobalCancellationCode -> EncodeGlobalCancellation(message.body)
      [] message.tag = UserGlobalCancellationCode -> EncodeUserGlobalCancellation(message.body)
      [] message.tag = SetGroupRiskLimitsCode -> EncodeSetGroupRiskLimits(message.body)
      [] message.tag = SetGlobalRiskLimitsCode -> EncodeSetGlobalRiskLimits(message.body)
      [] message.tag = OrderEntryCode -> EncodeOrderEntry(message.body)
      [] message.tag = OrderModificationCode -> EncodeOrderModification(message.body)
      [] message.tag = NewStrategyInstrumentCode -> EncodeNewStrategyInstrument(message.body)
      [] message.tag = CrossEntryCode -> EncodeCrossEntry(message.body)
      [] message.tag = BulkQuotePrice4Quantity2Code -> EncodeBulkQuotePrice4Quantity2(message.body)
      [] message.tag = BulkQuotePrice6Quantity2Code -> EncodeBulkQuotePrice6Quantity2(message.body)
      [] message.tag = BulkQuotePrice8Quantity2Code -> EncodeBulkQuotePrice8Quantity2(message.body)
      [] message.tag = BulkQuotePrice10Quantity2Code -> EncodeBulkQuotePrice10Quantity2(message.body)
      [] message.tag = BulkQuotePrice4Quantity4Code -> EncodeBulkQuotePrice4Quantity4(message.body)
      [] message.tag = BulkQuotePrice6Quantity4Code -> EncodeBulkQuotePrice6Quantity4(message.body)
      [] message.tag = BulkQuotePrice8Quantity4Code -> EncodeBulkQuotePrice8Quantity4(message.body)
      [] message.tag = BulkQuotePrice10Quantity4Code -> EncodeBulkQuotePrice10Quantity4(message.body)
      [] message.tag = BulkQuotePrice4Quantity6Code -> EncodeBulkQuotePrice4Quantity6(message.body)
      [] message.tag = BulkQuotePrice6Quantity6Code -> EncodeBulkQuotePrice6Quantity6(message.body)
      [] message.tag = BulkQuotePrice8Quantity6Code -> EncodeBulkQuotePrice8Quantity6(message.body)
      [] message.tag = BulkQuotePrice10Quantity6Code -> EncodeBulkQuotePrice10Quantity6(message.body)
      [] message.tag = BulkQuotePrice4Quantity8Code -> EncodeBulkQuotePrice4Quantity8(message.body)
      [] message.tag = BulkQuotePrice6Quantity8Code -> EncodeBulkQuotePrice6Quantity8(message.body)
      [] message.tag = BulkQuotePrice8Quantity8Code -> EncodeBulkQuotePrice8Quantity8(message.body)
      [] message.tag = BulkQuoteCode -> EncodeBulkQuote(message.body)
      [] message.tag = SailRequestForQuoteWithSideCode -> EncodeSailRequestForQuoteWithSide(message.body)
      [] message.tag = BulkQuoteParticipantBqpProtectionSubscriptionCode -> EncodeBulkQuoteParticipantBqpProtectionSubscription(message.body)
      [] message.tag = RequestForQuoteCode -> EncodeRequestForQuote(message.body)
      [] message.tag = OrderCancellationCode -> EncodeOrderCancellation(message.body)

DecodeFirmMessage(tag, bytes) ==
    LET read ==
            CASE tag = UserConnectionCode -> DecodeUserConnection(bytes)
              [] tag = DisconnectionInstructionCode -> DecodeDisconnectionInstruction(bytes)
              [] tag = HeartbeatResponseCode -> DecodeHeartbeatResponse(bytes)
              [] tag = UserDisconnectionCode -> DecodeUserDisconnection(bytes)
              [] tag = OrderRequestCode -> DecodeOrderRequest(bytes)
              [] tag = BulkQuoteDataCode -> DecodeBulkQuoteData(bytes)
              [] tag = FirmRiskConfigCode -> DecodeFirmRiskConfig(bytes)
              [] tag = GlobalCancellationCode -> DecodeGlobalCancellation(bytes)
              [] tag = UserGlobalCancellationCode -> DecodeUserGlobalCancellation(bytes)
              [] tag = SetGroupRiskLimitsCode -> DecodeSetGroupRiskLimits(bytes)
              [] tag = SetGlobalRiskLimitsCode -> DecodeSetGlobalRiskLimits(bytes)
              [] tag = OrderEntryCode -> DecodeOrderEntry(bytes)
              [] tag = OrderModificationCode -> DecodeOrderModification(bytes)
              [] tag = NewStrategyInstrumentCode -> DecodeNewStrategyInstrument(bytes)
              [] tag = CrossEntryCode -> DecodeCrossEntry(bytes)
              [] tag = BulkQuotePrice4Quantity2Code -> DecodeBulkQuotePrice4Quantity2(bytes)
              [] tag = BulkQuotePrice6Quantity2Code -> DecodeBulkQuotePrice6Quantity2(bytes)
              [] tag = BulkQuotePrice8Quantity2Code -> DecodeBulkQuotePrice8Quantity2(bytes)
              [] tag = BulkQuotePrice10Quantity2Code -> DecodeBulkQuotePrice10Quantity2(bytes)
              [] tag = BulkQuotePrice4Quantity4Code -> DecodeBulkQuotePrice4Quantity4(bytes)
              [] tag = BulkQuotePrice6Quantity4Code -> DecodeBulkQuotePrice6Quantity4(bytes)
              [] tag = BulkQuotePrice8Quantity4Code -> DecodeBulkQuotePrice8Quantity4(bytes)
              [] tag = BulkQuotePrice10Quantity4Code -> DecodeBulkQuotePrice10Quantity4(bytes)
              [] tag = BulkQuotePrice4Quantity6Code -> DecodeBulkQuotePrice4Quantity6(bytes)
              [] tag = BulkQuotePrice6Quantity6Code -> DecodeBulkQuotePrice6Quantity6(bytes)
              [] tag = BulkQuotePrice8Quantity6Code -> DecodeBulkQuotePrice8Quantity6(bytes)
              [] tag = BulkQuotePrice10Quantity6Code -> DecodeBulkQuotePrice10Quantity6(bytes)
              [] tag = BulkQuotePrice4Quantity8Code -> DecodeBulkQuotePrice4Quantity8(bytes)
              [] tag = BulkQuotePrice6Quantity8Code -> DecodeBulkQuotePrice6Quantity8(bytes)
              [] tag = BulkQuotePrice8Quantity8Code -> DecodeBulkQuotePrice8Quantity8(bytes)
              [] tag = BulkQuoteCode -> DecodeBulkQuote(bytes)
              [] tag = SailRequestForQuoteWithSideCode -> DecodeSailRequestForQuoteWithSide(bytes)
              [] tag = BulkQuoteParticipantBqpProtectionSubscriptionCode -> DecodeBulkQuoteParticipantBqpProtectionSubscription(bytes)
              [] tag = RequestForQuoteCode -> DecodeRequestForQuote(bytes)
              [] tag = OrderCancellationCode -> DecodeOrderCancellation(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroFirmMessage == [tag |-> UserConnectionCode, body |-> ZeroUserConnection]

(* Each Firm Message in turn, at the values the message it names is checked at *)
CheckedFirmMessage ==
    { [tag |-> UserConnectionCode, body |-> one] : one \in CheckedUserConnection }
        \cup { [tag |-> DisconnectionInstructionCode, body |-> one] : one \in CheckedDisconnectionInstruction }
        \cup { [tag |-> HeartbeatResponseCode, body |-> one] : one \in CheckedHeartbeatResponse }
        \cup { [tag |-> UserDisconnectionCode, body |-> one] : one \in CheckedUserDisconnection }
        \cup { [tag |-> OrderRequestCode, body |-> one] : one \in CheckedOrderRequest }
        \cup { [tag |-> BulkQuoteDataCode, body |-> one] : one \in CheckedBulkQuoteData }
        \cup { [tag |-> FirmRiskConfigCode, body |-> one] : one \in CheckedFirmRiskConfig }
        \cup { [tag |-> GlobalCancellationCode, body |-> one] : one \in CheckedGlobalCancellation }
        \cup { [tag |-> UserGlobalCancellationCode, body |-> one] : one \in CheckedUserGlobalCancellation }
        \cup { [tag |-> SetGroupRiskLimitsCode, body |-> one] : one \in CheckedSetGroupRiskLimits }
        \cup { [tag |-> SetGlobalRiskLimitsCode, body |-> one] : one \in CheckedSetGlobalRiskLimits }
        \cup { [tag |-> OrderEntryCode, body |-> one] : one \in CheckedOrderEntry }
        \cup { [tag |-> OrderModificationCode, body |-> one] : one \in CheckedOrderModification }
        \cup { [tag |-> NewStrategyInstrumentCode, body |-> one] : one \in CheckedNewStrategyInstrument }
        \cup { [tag |-> CrossEntryCode, body |-> one] : one \in CheckedCrossEntry }
        \cup { [tag |-> BulkQuotePrice4Quantity2Code, body |-> one] : one \in CheckedBulkQuotePrice4Quantity2 }
        \cup { [tag |-> BulkQuotePrice6Quantity2Code, body |-> one] : one \in CheckedBulkQuotePrice6Quantity2 }
        \cup { [tag |-> BulkQuotePrice8Quantity2Code, body |-> one] : one \in CheckedBulkQuotePrice8Quantity2 }
        \cup { [tag |-> BulkQuotePrice10Quantity2Code, body |-> one] : one \in CheckedBulkQuotePrice10Quantity2 }
        \cup { [tag |-> BulkQuotePrice4Quantity4Code, body |-> one] : one \in CheckedBulkQuotePrice4Quantity4 }
        \cup { [tag |-> BulkQuotePrice6Quantity4Code, body |-> one] : one \in CheckedBulkQuotePrice6Quantity4 }
        \cup { [tag |-> BulkQuotePrice8Quantity4Code, body |-> one] : one \in CheckedBulkQuotePrice8Quantity4 }
        \cup { [tag |-> BulkQuotePrice10Quantity4Code, body |-> one] : one \in CheckedBulkQuotePrice10Quantity4 }
        \cup { [tag |-> BulkQuotePrice4Quantity6Code, body |-> one] : one \in CheckedBulkQuotePrice4Quantity6 }
        \cup { [tag |-> BulkQuotePrice6Quantity6Code, body |-> one] : one \in CheckedBulkQuotePrice6Quantity6 }
        \cup { [tag |-> BulkQuotePrice8Quantity6Code, body |-> one] : one \in CheckedBulkQuotePrice8Quantity6 }
        \cup { [tag |-> BulkQuotePrice10Quantity6Code, body |-> one] : one \in CheckedBulkQuotePrice10Quantity6 }
        \cup { [tag |-> BulkQuotePrice4Quantity8Code, body |-> one] : one \in CheckedBulkQuotePrice4Quantity8 }
        \cup { [tag |-> BulkQuotePrice6Quantity8Code, body |-> one] : one \in CheckedBulkQuotePrice6Quantity8 }
        \cup { [tag |-> BulkQuotePrice8Quantity8Code, body |-> one] : one \in CheckedBulkQuotePrice8Quantity8 }
        \cup { [tag |-> BulkQuoteCode, body |-> one] : one \in CheckedBulkQuote }
        \cup { [tag |-> SailRequestForQuoteWithSideCode, body |-> one] : one \in CheckedSailRequestForQuoteWithSide }
        \cup { [tag |-> BulkQuoteParticipantBqpProtectionSubscriptionCode, body |-> one] : one \in CheckedBulkQuoteParticipantBqpProtectionSubscription }
        \cup { [tag |-> RequestForQuoteCode, body |-> one] : one \in CheckedRequestForQuote }
        \cup { [tag |-> OrderCancellationCode, body |-> one] : one \in CheckedOrderCancellation }

(***************************************************************************)
(* Firm Packet                                                             *)
(***************************************************************************)

FirmPacket ==
    [ messageLength    : 0 .. 255,
      firmMessage      : FirmMessage,
      endOfText        : Sample(1),
      alignmentPadding : SampleBytes ]

EncodeFirmPacket(message) ==
    EncodeUIntLE(message.messageLength, 4)
        \o EncodeUIntBE(message.firmMessage.tag, 2)
        \o EncodeFirmMessage(message.firmMessage)
        \o message.endOfText
        \o message.alignmentPadding

DecodeFirmPacket(bytes) ==
    LET messageLength == ReadUIntLE(bytes, 4) IN IF ~messageLength.ok THEN Fail ELSE
    LET messageType == ReadUIntBE(messageLength.rest, 2) IN IF ~messageType.ok THEN Fail ELSE
    LET firmMessage == DecodeFirmMessage(messageType.value, messageType.rest) IN IF ~firmMessage.ok THEN Fail ELSE
    LET endOfText == ReadBytes(firmMessage.rest, 1) IN IF ~endOfText.ok THEN Fail ELSE
    LET alignmentPadding == Ok(endOfText.rest, << >>) IN IF ~alignmentPadding.ok THEN Fail ELSE
    Ok([ messageLength    |-> messageLength.value,
         firmMessage      |-> firmMessage.value,
         endOfText        |-> endOfText.value,
         alignmentPadding |-> alignmentPadding.value ], alignmentPadding.rest)

ZeroFirmPacket ==
    [ messageLength    |-> 0,
      firmMessage      |-> ZeroFirmMessage,
      endOfText        |-> [i \in 1 .. 1 |-> 0],
      alignmentPadding |-> << >> ]

(* Firm Packet at zero, then each field in turn at the values it is checked at *)
CheckedFirmPacket ==
    { ZeroFirmPacket }
        \cup { [ZeroFirmPacket EXCEPT !.messageLength = one] : one \in {0, 1, 255} }
        \cup { [ZeroFirmPacket EXCEPT !.firmMessage = one] : one \in CheckedFirmMessage }
        \cup { [ZeroFirmPacket EXCEPT !.endOfText = one] : one \in Sample(1) }
        \cup { [ZeroFirmPacket EXCEPT !.alignmentPadding = one] : one \in SampleBytes }

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

(* Every User Disconnection decodes back to what was encoded, and leaves nothing over *)
RoundTripUserDisconnection ==
    \A message \in CheckedUserDisconnection :
        LET read == DecodeUserDisconnection(EncodeUserDisconnection(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incoming Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripIncomingMessagesHeader ==
    \A message \in CheckedIncomingMessagesHeader :
        LET read == DecodeIncomingMessagesHeader(EncodeIncomingMessagesHeader(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Request decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderRequest ==
    \A message \in CheckedOrderRequest :
        LET read == DecodeOrderRequest(EncodeOrderRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incoming Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripIncomingMessagesHeader2 ==
    \A message \in CheckedIncomingMessagesHeader2 :
        LET read == DecodeIncomingMessagesHeader2(EncodeIncomingMessagesHeader2(message))
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

(* Every Incoming Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripIncomingMessagesHeader3 ==
    \A message \in CheckedIncomingMessagesHeader3 :
        LET read == DecodeIncomingMessagesHeader3(EncodeIncomingMessagesHeader3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Firm Risk Config Trader Team Trader decodes back to what was encoded, and leaves nothing over *)
RoundTripFirmRiskConfigTraderTeamTrader ==
    \A message \in CheckedFirmRiskConfigTraderTeamTrader :
        LET read == DecodeFirmRiskConfigTraderTeamTrader(EncodeFirmRiskConfigTraderTeamTrader(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Firm Risk Config Trader Team decodes back to what was encoded, and leaves nothing over *)
RoundTripFirmRiskConfigTraderTeam ==
    \A message \in CheckedFirmRiskConfigTraderTeam :
        LET read == DecodeFirmRiskConfigTraderTeam(EncodeFirmRiskConfigTraderTeam(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Firm Risk Config decodes back to what was encoded, and leaves nothing over *)
RoundTripFirmRiskConfig ==
    \A message \in CheckedFirmRiskConfig :
        LET read == DecodeFirmRiskConfig(EncodeFirmRiskConfig(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incoming Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripIncomingMessagesHeader4 ==
    \A message \in CheckedIncomingMessagesHeader4 :
        LET read == DecodeIncomingMessagesHeader4(EncodeIncomingMessagesHeader4(message))
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

(* Every Incoming Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripIncomingMessagesHeader5 ==
    \A message \in CheckedIncomingMessagesHeader5 :
        LET read == DecodeIncomingMessagesHeader5(EncodeIncomingMessagesHeader5(message))
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

(* Every Incoming Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripIncomingMessagesHeader6 ==
    \A message \in CheckedIncomingMessagesHeader6 :
        LET read == DecodeIncomingMessagesHeader6(EncodeIncomingMessagesHeader6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Set Group Risk Limits Occurrence decodes back to what was encoded, and leaves nothing over *)
RoundTripSetGroupRiskLimitsOccurrence ==
    \A message \in CheckedSetGroupRiskLimitsOccurrence :
        LET read == DecodeSetGroupRiskLimitsOccurrence(EncodeSetGroupRiskLimitsOccurrence(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Set Group Risk Limits decodes back to what was encoded, and leaves nothing over *)
RoundTripSetGroupRiskLimits ==
    \A message \in CheckedSetGroupRiskLimits :
        LET read == DecodeSetGroupRiskLimits(EncodeSetGroupRiskLimits(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incoming Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripIncomingMessagesHeader7 ==
    \A message \in CheckedIncomingMessagesHeader7 :
        LET read == DecodeIncomingMessagesHeader7(EncodeIncomingMessagesHeader7(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Set Global Risk Limits decodes back to what was encoded, and leaves nothing over *)
RoundTripSetGlobalRiskLimits ==
    \A message \in CheckedSetGlobalRiskLimits :
        LET read == DecodeSetGlobalRiskLimits(EncodeSetGlobalRiskLimits(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incoming Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripIncomingMessagesHeader8 ==
    \A message \in CheckedIncomingMessagesHeader8 :
        LET read == DecodeIncomingMessagesHeader8(EncodeIncomingMessagesHeader8(message))
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

(* Every Incoming Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripIncomingMessagesHeader9 ==
    \A message \in CheckedIncomingMessagesHeader9 :
        LET read == DecodeIncomingMessagesHeader9(EncodeIncomingMessagesHeader9(message))
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

(* Every Order Modification decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderModification ==
    \A message \in CheckedOrderModification :
        LET read == DecodeOrderModification(EncodeOrderModification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incoming Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripIncomingMessagesHeader10 ==
    \A message \in CheckedIncomingMessagesHeader10 :
        LET read == DecodeIncomingMessagesHeader10(EncodeIncomingMessagesHeader10(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Strategy Instrument Leg Definition Repeating Block decodes back to what was encoded, and leaves nothing over *)
RoundTripNewStrategyInstrumentLegDefinitionRepeatingBlock ==
    \A message \in CheckedNewStrategyInstrumentLegDefinitionRepeatingBlock :
        LET read == DecodeNewStrategyInstrumentLegDefinitionRepeatingBlock(EncodeNewStrategyInstrumentLegDefinitionRepeatingBlock(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Strategy Instrument decodes back to what was encoded, and leaves nothing over *)
RoundTripNewStrategyInstrument ==
    \A message \in CheckedNewStrategyInstrument :
        LET read == DecodeNewStrategyInstrument(EncodeNewStrategyInstrument(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incoming Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripIncomingMessagesHeader11 ==
    \A message \in CheckedIncomingMessagesHeader11 :
        LET read == DecodeIncomingMessagesHeader11(EncodeIncomingMessagesHeader11(message))
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

(* Every Cross Entry decodes back to what was encoded, and leaves nothing over *)
RoundTripCrossEntry ==
    \A message \in CheckedCrossEntry :
        LET read == DecodeCrossEntry(EncodeCrossEntry(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incoming Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripIncomingMessagesHeader12 ==
    \A message \in CheckedIncomingMessagesHeader12 :
        LET read == DecodeIncomingMessagesHeader12(EncodeIncomingMessagesHeader12(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulk Quote Price 4 Quantity 2 Occurrence decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkQuotePrice4Quantity2Occurrence ==
    \A message \in CheckedBulkQuotePrice4Quantity2Occurrence :
        LET read == DecodeBulkQuotePrice4Quantity2Occurrence(EncodeBulkQuotePrice4Quantity2Occurrence(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulk Quote Price 4 Quantity 2 decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkQuotePrice4Quantity2 ==
    \A message \in CheckedBulkQuotePrice4Quantity2 :
        LET read == DecodeBulkQuotePrice4Quantity2(EncodeBulkQuotePrice4Quantity2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incoming Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripIncomingMessagesHeader13 ==
    \A message \in CheckedIncomingMessagesHeader13 :
        LET read == DecodeIncomingMessagesHeader13(EncodeIncomingMessagesHeader13(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulk Quote Price 6 Quantity 2 Occurrence decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkQuotePrice6Quantity2Occurrence ==
    \A message \in CheckedBulkQuotePrice6Quantity2Occurrence :
        LET read == DecodeBulkQuotePrice6Quantity2Occurrence(EncodeBulkQuotePrice6Quantity2Occurrence(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulk Quote Price 6 Quantity 2 decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkQuotePrice6Quantity2 ==
    \A message \in CheckedBulkQuotePrice6Quantity2 :
        LET read == DecodeBulkQuotePrice6Quantity2(EncodeBulkQuotePrice6Quantity2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incoming Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripIncomingMessagesHeader14 ==
    \A message \in CheckedIncomingMessagesHeader14 :
        LET read == DecodeIncomingMessagesHeader14(EncodeIncomingMessagesHeader14(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulk Quote Price 8 Quantity 2 Occurrence decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkQuotePrice8Quantity2Occurrence ==
    \A message \in CheckedBulkQuotePrice8Quantity2Occurrence :
        LET read == DecodeBulkQuotePrice8Quantity2Occurrence(EncodeBulkQuotePrice8Quantity2Occurrence(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulk Quote Price 8 Quantity 2 decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkQuotePrice8Quantity2 ==
    \A message \in CheckedBulkQuotePrice8Quantity2 :
        LET read == DecodeBulkQuotePrice8Quantity2(EncodeBulkQuotePrice8Quantity2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incoming Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripIncomingMessagesHeader15 ==
    \A message \in CheckedIncomingMessagesHeader15 :
        LET read == DecodeIncomingMessagesHeader15(EncodeIncomingMessagesHeader15(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulk Quote Price 10 Quantity 2 Occurrence decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkQuotePrice10Quantity2Occurrence ==
    \A message \in CheckedBulkQuotePrice10Quantity2Occurrence :
        LET read == DecodeBulkQuotePrice10Quantity2Occurrence(EncodeBulkQuotePrice10Quantity2Occurrence(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulk Quote Price 10 Quantity 2 decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkQuotePrice10Quantity2 ==
    \A message \in CheckedBulkQuotePrice10Quantity2 :
        LET read == DecodeBulkQuotePrice10Quantity2(EncodeBulkQuotePrice10Quantity2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incoming Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripIncomingMessagesHeader16 ==
    \A message \in CheckedIncomingMessagesHeader16 :
        LET read == DecodeIncomingMessagesHeader16(EncodeIncomingMessagesHeader16(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulk Quote Price 4 Quantity 4 Occurrence decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkQuotePrice4Quantity4Occurrence ==
    \A message \in CheckedBulkQuotePrice4Quantity4Occurrence :
        LET read == DecodeBulkQuotePrice4Quantity4Occurrence(EncodeBulkQuotePrice4Quantity4Occurrence(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulk Quote Price 4 Quantity 4 decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkQuotePrice4Quantity4 ==
    \A message \in CheckedBulkQuotePrice4Quantity4 :
        LET read == DecodeBulkQuotePrice4Quantity4(EncodeBulkQuotePrice4Quantity4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incoming Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripIncomingMessagesHeader17 ==
    \A message \in CheckedIncomingMessagesHeader17 :
        LET read == DecodeIncomingMessagesHeader17(EncodeIncomingMessagesHeader17(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulk Quote Price 6 Quantity 4 Occurrence decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkQuotePrice6Quantity4Occurrence ==
    \A message \in CheckedBulkQuotePrice6Quantity4Occurrence :
        LET read == DecodeBulkQuotePrice6Quantity4Occurrence(EncodeBulkQuotePrice6Quantity4Occurrence(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulk Quote Price 6 Quantity 4 decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkQuotePrice6Quantity4 ==
    \A message \in CheckedBulkQuotePrice6Quantity4 :
        LET read == DecodeBulkQuotePrice6Quantity4(EncodeBulkQuotePrice6Quantity4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incoming Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripIncomingMessagesHeader18 ==
    \A message \in CheckedIncomingMessagesHeader18 :
        LET read == DecodeIncomingMessagesHeader18(EncodeIncomingMessagesHeader18(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulk Quote Price 8 Quantity 4 Occurrence decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkQuotePrice8Quantity4Occurrence ==
    \A message \in CheckedBulkQuotePrice8Quantity4Occurrence :
        LET read == DecodeBulkQuotePrice8Quantity4Occurrence(EncodeBulkQuotePrice8Quantity4Occurrence(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulk Quote Price 8 Quantity 4 decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkQuotePrice8Quantity4 ==
    \A message \in CheckedBulkQuotePrice8Quantity4 :
        LET read == DecodeBulkQuotePrice8Quantity4(EncodeBulkQuotePrice8Quantity4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incoming Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripIncomingMessagesHeader19 ==
    \A message \in CheckedIncomingMessagesHeader19 :
        LET read == DecodeIncomingMessagesHeader19(EncodeIncomingMessagesHeader19(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulk Quote Price 10 Quantity 4 Occurrence decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkQuotePrice10Quantity4Occurrence ==
    \A message \in CheckedBulkQuotePrice10Quantity4Occurrence :
        LET read == DecodeBulkQuotePrice10Quantity4Occurrence(EncodeBulkQuotePrice10Quantity4Occurrence(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulk Quote Price 10 Quantity 4 decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkQuotePrice10Quantity4 ==
    \A message \in CheckedBulkQuotePrice10Quantity4 :
        LET read == DecodeBulkQuotePrice10Quantity4(EncodeBulkQuotePrice10Quantity4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incoming Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripIncomingMessagesHeader20 ==
    \A message \in CheckedIncomingMessagesHeader20 :
        LET read == DecodeIncomingMessagesHeader20(EncodeIncomingMessagesHeader20(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulk Quote Price 4 Quantity 6 Occurrence decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkQuotePrice4Quantity6Occurrence ==
    \A message \in CheckedBulkQuotePrice4Quantity6Occurrence :
        LET read == DecodeBulkQuotePrice4Quantity6Occurrence(EncodeBulkQuotePrice4Quantity6Occurrence(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulk Quote Price 4 Quantity 6 decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkQuotePrice4Quantity6 ==
    \A message \in CheckedBulkQuotePrice4Quantity6 :
        LET read == DecodeBulkQuotePrice4Quantity6(EncodeBulkQuotePrice4Quantity6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incoming Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripIncomingMessagesHeader21 ==
    \A message \in CheckedIncomingMessagesHeader21 :
        LET read == DecodeIncomingMessagesHeader21(EncodeIncomingMessagesHeader21(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulk Quote Price 6 Quantity 6 Occurrence decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkQuotePrice6Quantity6Occurrence ==
    \A message \in CheckedBulkQuotePrice6Quantity6Occurrence :
        LET read == DecodeBulkQuotePrice6Quantity6Occurrence(EncodeBulkQuotePrice6Quantity6Occurrence(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulk Quote Price 6 Quantity 6 decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkQuotePrice6Quantity6 ==
    \A message \in CheckedBulkQuotePrice6Quantity6 :
        LET read == DecodeBulkQuotePrice6Quantity6(EncodeBulkQuotePrice6Quantity6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incoming Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripIncomingMessagesHeader22 ==
    \A message \in CheckedIncomingMessagesHeader22 :
        LET read == DecodeIncomingMessagesHeader22(EncodeIncomingMessagesHeader22(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulk Quote Price 8 Quantity 6 Occurrence decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkQuotePrice8Quantity6Occurrence ==
    \A message \in CheckedBulkQuotePrice8Quantity6Occurrence :
        LET read == DecodeBulkQuotePrice8Quantity6Occurrence(EncodeBulkQuotePrice8Quantity6Occurrence(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulk Quote Price 8 Quantity 6 decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkQuotePrice8Quantity6 ==
    \A message \in CheckedBulkQuotePrice8Quantity6 :
        LET read == DecodeBulkQuotePrice8Quantity6(EncodeBulkQuotePrice8Quantity6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incoming Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripIncomingMessagesHeader23 ==
    \A message \in CheckedIncomingMessagesHeader23 :
        LET read == DecodeIncomingMessagesHeader23(EncodeIncomingMessagesHeader23(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulk Quote Price 10 Quantity 6 Occurrence decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkQuotePrice10Quantity6Occurrence ==
    \A message \in CheckedBulkQuotePrice10Quantity6Occurrence :
        LET read == DecodeBulkQuotePrice10Quantity6Occurrence(EncodeBulkQuotePrice10Quantity6Occurrence(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulk Quote Price 10 Quantity 6 decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkQuotePrice10Quantity6 ==
    \A message \in CheckedBulkQuotePrice10Quantity6 :
        LET read == DecodeBulkQuotePrice10Quantity6(EncodeBulkQuotePrice10Quantity6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incoming Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripIncomingMessagesHeader24 ==
    \A message \in CheckedIncomingMessagesHeader24 :
        LET read == DecodeIncomingMessagesHeader24(EncodeIncomingMessagesHeader24(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulk Quote Price 4 Quantity 8 Occurrence decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkQuotePrice4Quantity8Occurrence ==
    \A message \in CheckedBulkQuotePrice4Quantity8Occurrence :
        LET read == DecodeBulkQuotePrice4Quantity8Occurrence(EncodeBulkQuotePrice4Quantity8Occurrence(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulk Quote Price 4 Quantity 8 decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkQuotePrice4Quantity8 ==
    \A message \in CheckedBulkQuotePrice4Quantity8 :
        LET read == DecodeBulkQuotePrice4Quantity8(EncodeBulkQuotePrice4Quantity8(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incoming Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripIncomingMessagesHeader25 ==
    \A message \in CheckedIncomingMessagesHeader25 :
        LET read == DecodeIncomingMessagesHeader25(EncodeIncomingMessagesHeader25(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulk Quote Price 6 Quantity 8 Occurrence decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkQuotePrice6Quantity8Occurrence ==
    \A message \in CheckedBulkQuotePrice6Quantity8Occurrence :
        LET read == DecodeBulkQuotePrice6Quantity8Occurrence(EncodeBulkQuotePrice6Quantity8Occurrence(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulk Quote Price 6 Quantity 8 decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkQuotePrice6Quantity8 ==
    \A message \in CheckedBulkQuotePrice6Quantity8 :
        LET read == DecodeBulkQuotePrice6Quantity8(EncodeBulkQuotePrice6Quantity8(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incoming Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripIncomingMessagesHeader26 ==
    \A message \in CheckedIncomingMessagesHeader26 :
        LET read == DecodeIncomingMessagesHeader26(EncodeIncomingMessagesHeader26(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulk Quote Price 8 Quantity 8 Occurrence decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkQuotePrice8Quantity8Occurrence ==
    \A message \in CheckedBulkQuotePrice8Quantity8Occurrence :
        LET read == DecodeBulkQuotePrice8Quantity8Occurrence(EncodeBulkQuotePrice8Quantity8Occurrence(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulk Quote Price 8 Quantity 8 decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkQuotePrice8Quantity8 ==
    \A message \in CheckedBulkQuotePrice8Quantity8 :
        LET read == DecodeBulkQuotePrice8Quantity8(EncodeBulkQuotePrice8Quantity8(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incoming Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripIncomingMessagesHeader27 ==
    \A message \in CheckedIncomingMessagesHeader27 :
        LET read == DecodeIncomingMessagesHeader27(EncodeIncomingMessagesHeader27(message))
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

(* Every Incoming Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripIncomingMessagesHeader28 ==
    \A message \in CheckedIncomingMessagesHeader28 :
        LET read == DecodeIncomingMessagesHeader28(EncodeIncomingMessagesHeader28(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sail Request For Quote With Side decodes back to what was encoded, and leaves nothing over *)
RoundTripSailRequestForQuoteWithSide ==
    \A message \in CheckedSailRequestForQuoteWithSide :
        LET read == DecodeSailRequestForQuoteWithSide(EncodeSailRequestForQuoteWithSide(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incoming Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripIncomingMessagesHeader29 ==
    \A message \in CheckedIncomingMessagesHeader29 :
        LET read == DecodeIncomingMessagesHeader29(EncodeIncomingMessagesHeader29(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulk Quote Participant Bqp Protection Subscription decodes back to what was encoded, and leaves nothing over *)
RoundTripBulkQuoteParticipantBqpProtectionSubscription ==
    \A message \in CheckedBulkQuoteParticipantBqpProtectionSubscription :
        LET read == DecodeBulkQuoteParticipantBqpProtectionSubscription(EncodeBulkQuoteParticipantBqpProtectionSubscription(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incoming Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripIncomingMessagesHeader30 ==
    \A message \in CheckedIncomingMessagesHeader30 :
        LET read == DecodeIncomingMessagesHeader30(EncodeIncomingMessagesHeader30(message))
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

(* Every Incoming Messages Header decodes back to what was encoded, and leaves nothing over *)
RoundTripIncomingMessagesHeader31 ==
    \A message \in CheckedIncomingMessagesHeader31 :
        LET read == DecodeIncomingMessagesHeader31(EncodeIncomingMessagesHeader31(message))
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
