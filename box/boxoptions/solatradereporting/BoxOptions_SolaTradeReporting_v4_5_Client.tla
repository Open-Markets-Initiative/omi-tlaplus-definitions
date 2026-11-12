------------- MODULE BoxOptions_SolaTradeReporting_v4_5_Client -------------
(***************************************************************************)
(* Box Options Market Sola Trade Reporting v4.5                            *)
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
(* License: MIT No Attribution                                             *)
(*                                                                         *)
(* Note: Client Sola Frame is of no one width: each is read by its own     *)
(* fields, and since every reading of it takes at least 29 bytes off the   *)
(* reader the run ends where the data does.                                *)
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
(* Restart Request: 8 bytes                                                *)
(***************************************************************************)

RestartRequest ==
    [ sequenceNumber : Sample(8) ]

EncodeRestartRequest(message) ==
    message.sequenceNumber

DecodeRestartRequest(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    Ok([ sequenceNumber |-> sequenceNumber.value ], sequenceNumber.rest)

ZeroRestartRequest ==
    [ sequenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Restart Request at zero, then each field in turn at the values it is checked at *)
CheckedRestartRequest ==
    { ZeroRestartRequest }
        \cup { [ZeroRestartRequest EXCEPT !.sequenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Client Signon: 36 bytes                                                 *)
(***************************************************************************)

ClientSignon ==
    [ memberNumber          : Sample(4),
      initialSequenceNumber : Sample(8),
      protocolVersion       : Sample(2),
      time                  : Sample(6),
      username              : Sample(8),
      passwordMd5Encryption : Sample(8) ]

EncodeClientSignon(message) ==
    message.memberNumber
        \o message.initialSequenceNumber
        \o message.protocolVersion
        \o message.time
        \o message.username
        \o message.passwordMd5Encryption

DecodeClientSignon(bytes) ==
    LET memberNumber == ReadBytes(bytes, 4) IN IF ~memberNumber.ok THEN Fail ELSE
    LET initialSequenceNumber == ReadBytes(memberNumber.rest, 8) IN IF ~initialSequenceNumber.ok THEN Fail ELSE
    LET protocolVersion == ReadBytes(initialSequenceNumber.rest, 2) IN IF ~protocolVersion.ok THEN Fail ELSE
    LET time == ReadBytes(protocolVersion.rest, 6) IN IF ~time.ok THEN Fail ELSE
    LET username == ReadBytes(time.rest, 8) IN IF ~username.ok THEN Fail ELSE
    LET passwordMd5Encryption == ReadBytes(username.rest, 8) IN IF ~passwordMd5Encryption.ok THEN Fail ELSE
    Ok([ memberNumber          |-> memberNumber.value,
         initialSequenceNumber |-> initialSequenceNumber.value,
         protocolVersion       |-> protocolVersion.value,
         time                  |-> time.value,
         username              |-> username.value,
         passwordMd5Encryption |-> passwordMd5Encryption.value ], passwordMd5Encryption.rest)

ZeroClientSignon ==
    [ memberNumber          |-> [i \in 1 .. 4 |-> 0],
      initialSequenceNumber |-> [i \in 1 .. 8 |-> 0],
      protocolVersion       |-> [i \in 1 .. 2 |-> 0],
      time                  |-> [i \in 1 .. 6 |-> 0],
      username              |-> [i \in 1 .. 8 |-> 0],
      passwordMd5Encryption |-> [i \in 1 .. 8 |-> 0] ]

(* Client Signon at zero, then each field in turn at the values it is checked at *)
CheckedClientSignon ==
    { ZeroClientSignon }
        \cup { [ZeroClientSignon EXCEPT !.memberNumber = one] : one \in Sample(4) }
        \cup { [ZeroClientSignon EXCEPT !.initialSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroClientSignon EXCEPT !.protocolVersion = one] : one \in Sample(2) }
        \cup { [ZeroClientSignon EXCEPT !.time = one] : one \in Sample(6) }
        \cup { [ZeroClientSignon EXCEPT !.username = one] : one \in Sample(8) }
        \cup { [ZeroClientSignon EXCEPT !.passwordMd5Encryption = one] : one \in Sample(8) }

(***************************************************************************)
(* New Allocation: 94 bytes                                                *)
(***************************************************************************)

NewAllocation ==
    [ referenceTransactionId : Sample(10),
      referenceTradeNumber   : Sample(15),
      giveUpFirm             : Sample(4),
      volume                 : Sample(8),
      accountType            : Sample(1),
      openClose              : Sample(1),
      clientAccountNumber    : Sample(12),
      subTraderId            : Sample(3),
      cmtaBroker             : Sample(4),
      clientMemo             : Sample(16),
      additionalFirm         : Sample(4),
      additionalClientMemo   : Sample(16) ]

EncodeNewAllocation(message) ==
    message.referenceTransactionId
        \o message.referenceTradeNumber
        \o message.giveUpFirm
        \o message.volume
        \o message.accountType
        \o message.openClose
        \o message.clientAccountNumber
        \o message.subTraderId
        \o message.cmtaBroker
        \o message.clientMemo
        \o message.additionalFirm
        \o message.additionalClientMemo

DecodeNewAllocation(bytes) ==
    LET referenceTransactionId == ReadBytes(bytes, 10) IN IF ~referenceTransactionId.ok THEN Fail ELSE
    LET referenceTradeNumber == ReadBytes(referenceTransactionId.rest, 15) IN IF ~referenceTradeNumber.ok THEN Fail ELSE
    LET giveUpFirm == ReadBytes(referenceTradeNumber.rest, 4) IN IF ~giveUpFirm.ok THEN Fail ELSE
    LET volume == ReadBytes(giveUpFirm.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET accountType == ReadBytes(volume.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET openClose == ReadBytes(accountType.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET clientAccountNumber == ReadBytes(openClose.rest, 12) IN IF ~clientAccountNumber.ok THEN Fail ELSE
    LET subTraderId == ReadBytes(clientAccountNumber.rest, 3) IN IF ~subTraderId.ok THEN Fail ELSE
    LET cmtaBroker == ReadBytes(subTraderId.rest, 4) IN IF ~cmtaBroker.ok THEN Fail ELSE
    LET clientMemo == ReadBytes(cmtaBroker.rest, 16) IN IF ~clientMemo.ok THEN Fail ELSE
    LET additionalFirm == ReadBytes(clientMemo.rest, 4) IN IF ~additionalFirm.ok THEN Fail ELSE
    LET additionalClientMemo == ReadBytes(additionalFirm.rest, 16) IN IF ~additionalClientMemo.ok THEN Fail ELSE
    Ok([ referenceTransactionId |-> referenceTransactionId.value,
         referenceTradeNumber   |-> referenceTradeNumber.value,
         giveUpFirm             |-> giveUpFirm.value,
         volume                 |-> volume.value,
         accountType            |-> accountType.value,
         openClose              |-> openClose.value,
         clientAccountNumber    |-> clientAccountNumber.value,
         subTraderId            |-> subTraderId.value,
         cmtaBroker             |-> cmtaBroker.value,
         clientMemo             |-> clientMemo.value,
         additionalFirm         |-> additionalFirm.value,
         additionalClientMemo   |-> additionalClientMemo.value ], additionalClientMemo.rest)

ZeroNewAllocation ==
    [ referenceTransactionId |-> [i \in 1 .. 10 |-> 0],
      referenceTradeNumber   |-> [i \in 1 .. 15 |-> 0],
      giveUpFirm             |-> [i \in 1 .. 4 |-> 0],
      volume                 |-> [i \in 1 .. 8 |-> 0],
      accountType            |-> [i \in 1 .. 1 |-> 0],
      openClose              |-> [i \in 1 .. 1 |-> 0],
      clientAccountNumber    |-> [i \in 1 .. 12 |-> 0],
      subTraderId            |-> [i \in 1 .. 3 |-> 0],
      cmtaBroker             |-> [i \in 1 .. 4 |-> 0],
      clientMemo             |-> [i \in 1 .. 16 |-> 0],
      additionalFirm         |-> [i \in 1 .. 4 |-> 0],
      additionalClientMemo   |-> [i \in 1 .. 16 |-> 0] ]

(* New Allocation at zero, then each field in turn at the values it is checked at *)
CheckedNewAllocation ==
    { ZeroNewAllocation }
        \cup { [ZeroNewAllocation EXCEPT !.referenceTransactionId = one] : one \in Sample(10) }
        \cup { [ZeroNewAllocation EXCEPT !.referenceTradeNumber = one] : one \in Sample(15) }
        \cup { [ZeroNewAllocation EXCEPT !.giveUpFirm = one] : one \in Sample(4) }
        \cup { [ZeroNewAllocation EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroNewAllocation EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroNewAllocation EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroNewAllocation EXCEPT !.clientAccountNumber = one] : one \in Sample(12) }
        \cup { [ZeroNewAllocation EXCEPT !.subTraderId = one] : one \in Sample(3) }
        \cup { [ZeroNewAllocation EXCEPT !.cmtaBroker = one] : one \in Sample(4) }
        \cup { [ZeroNewAllocation EXCEPT !.clientMemo = one] : one \in Sample(16) }
        \cup { [ZeroNewAllocation EXCEPT !.additionalFirm = one] : one \in Sample(4) }
        \cup { [ZeroNewAllocation EXCEPT !.additionalClientMemo = one] : one \in Sample(16) }

(***************************************************************************)
(* Modify Allocation: 94 bytes                                             *)
(***************************************************************************)

ModifyAllocation ==
    [ referenceTransactionId : Sample(10),
      referenceTradeNumber   : Sample(15),
      giveUpFirm             : Sample(4),
      volume                 : Sample(8),
      accountType            : Sample(1),
      openClose              : Sample(1),
      clientAccountNumber    : Sample(12),
      subTraderId            : Sample(3),
      cmtaBroker             : Sample(4),
      clientMemo             : Sample(16),
      additionalFirm         : Sample(4),
      additionalClientMemo   : Sample(16) ]

EncodeModifyAllocation(message) ==
    message.referenceTransactionId
        \o message.referenceTradeNumber
        \o message.giveUpFirm
        \o message.volume
        \o message.accountType
        \o message.openClose
        \o message.clientAccountNumber
        \o message.subTraderId
        \o message.cmtaBroker
        \o message.clientMemo
        \o message.additionalFirm
        \o message.additionalClientMemo

DecodeModifyAllocation(bytes) ==
    LET referenceTransactionId == ReadBytes(bytes, 10) IN IF ~referenceTransactionId.ok THEN Fail ELSE
    LET referenceTradeNumber == ReadBytes(referenceTransactionId.rest, 15) IN IF ~referenceTradeNumber.ok THEN Fail ELSE
    LET giveUpFirm == ReadBytes(referenceTradeNumber.rest, 4) IN IF ~giveUpFirm.ok THEN Fail ELSE
    LET volume == ReadBytes(giveUpFirm.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET accountType == ReadBytes(volume.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET openClose == ReadBytes(accountType.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET clientAccountNumber == ReadBytes(openClose.rest, 12) IN IF ~clientAccountNumber.ok THEN Fail ELSE
    LET subTraderId == ReadBytes(clientAccountNumber.rest, 3) IN IF ~subTraderId.ok THEN Fail ELSE
    LET cmtaBroker == ReadBytes(subTraderId.rest, 4) IN IF ~cmtaBroker.ok THEN Fail ELSE
    LET clientMemo == ReadBytes(cmtaBroker.rest, 16) IN IF ~clientMemo.ok THEN Fail ELSE
    LET additionalFirm == ReadBytes(clientMemo.rest, 4) IN IF ~additionalFirm.ok THEN Fail ELSE
    LET additionalClientMemo == ReadBytes(additionalFirm.rest, 16) IN IF ~additionalClientMemo.ok THEN Fail ELSE
    Ok([ referenceTransactionId |-> referenceTransactionId.value,
         referenceTradeNumber   |-> referenceTradeNumber.value,
         giveUpFirm             |-> giveUpFirm.value,
         volume                 |-> volume.value,
         accountType            |-> accountType.value,
         openClose              |-> openClose.value,
         clientAccountNumber    |-> clientAccountNumber.value,
         subTraderId            |-> subTraderId.value,
         cmtaBroker             |-> cmtaBroker.value,
         clientMemo             |-> clientMemo.value,
         additionalFirm         |-> additionalFirm.value,
         additionalClientMemo   |-> additionalClientMemo.value ], additionalClientMemo.rest)

ZeroModifyAllocation ==
    [ referenceTransactionId |-> [i \in 1 .. 10 |-> 0],
      referenceTradeNumber   |-> [i \in 1 .. 15 |-> 0],
      giveUpFirm             |-> [i \in 1 .. 4 |-> 0],
      volume                 |-> [i \in 1 .. 8 |-> 0],
      accountType            |-> [i \in 1 .. 1 |-> 0],
      openClose              |-> [i \in 1 .. 1 |-> 0],
      clientAccountNumber    |-> [i \in 1 .. 12 |-> 0],
      subTraderId            |-> [i \in 1 .. 3 |-> 0],
      cmtaBroker             |-> [i \in 1 .. 4 |-> 0],
      clientMemo             |-> [i \in 1 .. 16 |-> 0],
      additionalFirm         |-> [i \in 1 .. 4 |-> 0],
      additionalClientMemo   |-> [i \in 1 .. 16 |-> 0] ]

(* Modify Allocation at zero, then each field in turn at the values it is checked at *)
CheckedModifyAllocation ==
    { ZeroModifyAllocation }
        \cup { [ZeroModifyAllocation EXCEPT !.referenceTransactionId = one] : one \in Sample(10) }
        \cup { [ZeroModifyAllocation EXCEPT !.referenceTradeNumber = one] : one \in Sample(15) }
        \cup { [ZeroModifyAllocation EXCEPT !.giveUpFirm = one] : one \in Sample(4) }
        \cup { [ZeroModifyAllocation EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroModifyAllocation EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroModifyAllocation EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroModifyAllocation EXCEPT !.clientAccountNumber = one] : one \in Sample(12) }
        \cup { [ZeroModifyAllocation EXCEPT !.subTraderId = one] : one \in Sample(3) }
        \cup { [ZeroModifyAllocation EXCEPT !.cmtaBroker = one] : one \in Sample(4) }
        \cup { [ZeroModifyAllocation EXCEPT !.clientMemo = one] : one \in Sample(16) }
        \cup { [ZeroModifyAllocation EXCEPT !.additionalFirm = one] : one \in Sample(4) }
        \cup { [ZeroModifyAllocation EXCEPT !.additionalClientMemo = one] : one \in Sample(16) }

(***************************************************************************)
(* Delete Allocation: 25 bytes                                             *)
(***************************************************************************)

DeleteAllocation ==
    [ referenceTransactionId : Sample(10),
      referenceTradeNumber   : Sample(15) ]

EncodeDeleteAllocation(message) ==
    message.referenceTransactionId
        \o message.referenceTradeNumber

DecodeDeleteAllocation(bytes) ==
    LET referenceTransactionId == ReadBytes(bytes, 10) IN IF ~referenceTransactionId.ok THEN Fail ELSE
    LET referenceTradeNumber == ReadBytes(referenceTransactionId.rest, 15) IN IF ~referenceTradeNumber.ok THEN Fail ELSE
    Ok([ referenceTransactionId |-> referenceTransactionId.value,
         referenceTradeNumber   |-> referenceTradeNumber.value ], referenceTradeNumber.rest)

ZeroDeleteAllocation ==
    [ referenceTransactionId |-> [i \in 1 .. 10 |-> 0],
      referenceTradeNumber   |-> [i \in 1 .. 15 |-> 0] ]

(* Delete Allocation at zero, then each field in turn at the values it is checked at *)
CheckedDeleteAllocation ==
    { ZeroDeleteAllocation }
        \cup { [ZeroDeleteAllocation EXCEPT !.referenceTransactionId = one] : one \in Sample(10) }
        \cup { [ZeroDeleteAllocation EXCEPT !.referenceTradeNumber = one] : one \in Sample(15) }

(***************************************************************************)
(* New Give Up: 94 bytes                                                   *)
(***************************************************************************)

NewGiveUp ==
    [ referenceTransactionId : Sample(10),
      referenceTradeNumber   : Sample(15),
      giveUpFirm             : Sample(4),
      volume                 : Sample(8),
      accountType            : Sample(1),
      openClose              : Sample(1),
      clientAccountNumber    : Sample(12),
      subTraderId            : Sample(3),
      cmtaBroker             : Sample(4),
      clientMemo             : Sample(16),
      additionalFirm         : Sample(4),
      additionalClientMemo   : Sample(16) ]

EncodeNewGiveUp(message) ==
    message.referenceTransactionId
        \o message.referenceTradeNumber
        \o message.giveUpFirm
        \o message.volume
        \o message.accountType
        \o message.openClose
        \o message.clientAccountNumber
        \o message.subTraderId
        \o message.cmtaBroker
        \o message.clientMemo
        \o message.additionalFirm
        \o message.additionalClientMemo

DecodeNewGiveUp(bytes) ==
    LET referenceTransactionId == ReadBytes(bytes, 10) IN IF ~referenceTransactionId.ok THEN Fail ELSE
    LET referenceTradeNumber == ReadBytes(referenceTransactionId.rest, 15) IN IF ~referenceTradeNumber.ok THEN Fail ELSE
    LET giveUpFirm == ReadBytes(referenceTradeNumber.rest, 4) IN IF ~giveUpFirm.ok THEN Fail ELSE
    LET volume == ReadBytes(giveUpFirm.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET accountType == ReadBytes(volume.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET openClose == ReadBytes(accountType.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET clientAccountNumber == ReadBytes(openClose.rest, 12) IN IF ~clientAccountNumber.ok THEN Fail ELSE
    LET subTraderId == ReadBytes(clientAccountNumber.rest, 3) IN IF ~subTraderId.ok THEN Fail ELSE
    LET cmtaBroker == ReadBytes(subTraderId.rest, 4) IN IF ~cmtaBroker.ok THEN Fail ELSE
    LET clientMemo == ReadBytes(cmtaBroker.rest, 16) IN IF ~clientMemo.ok THEN Fail ELSE
    LET additionalFirm == ReadBytes(clientMemo.rest, 4) IN IF ~additionalFirm.ok THEN Fail ELSE
    LET additionalClientMemo == ReadBytes(additionalFirm.rest, 16) IN IF ~additionalClientMemo.ok THEN Fail ELSE
    Ok([ referenceTransactionId |-> referenceTransactionId.value,
         referenceTradeNumber   |-> referenceTradeNumber.value,
         giveUpFirm             |-> giveUpFirm.value,
         volume                 |-> volume.value,
         accountType            |-> accountType.value,
         openClose              |-> openClose.value,
         clientAccountNumber    |-> clientAccountNumber.value,
         subTraderId            |-> subTraderId.value,
         cmtaBroker             |-> cmtaBroker.value,
         clientMemo             |-> clientMemo.value,
         additionalFirm         |-> additionalFirm.value,
         additionalClientMemo   |-> additionalClientMemo.value ], additionalClientMemo.rest)

ZeroNewGiveUp ==
    [ referenceTransactionId |-> [i \in 1 .. 10 |-> 0],
      referenceTradeNumber   |-> [i \in 1 .. 15 |-> 0],
      giveUpFirm             |-> [i \in 1 .. 4 |-> 0],
      volume                 |-> [i \in 1 .. 8 |-> 0],
      accountType            |-> [i \in 1 .. 1 |-> 0],
      openClose              |-> [i \in 1 .. 1 |-> 0],
      clientAccountNumber    |-> [i \in 1 .. 12 |-> 0],
      subTraderId            |-> [i \in 1 .. 3 |-> 0],
      cmtaBroker             |-> [i \in 1 .. 4 |-> 0],
      clientMemo             |-> [i \in 1 .. 16 |-> 0],
      additionalFirm         |-> [i \in 1 .. 4 |-> 0],
      additionalClientMemo   |-> [i \in 1 .. 16 |-> 0] ]

(* New Give Up at zero, then each field in turn at the values it is checked at *)
CheckedNewGiveUp ==
    { ZeroNewGiveUp }
        \cup { [ZeroNewGiveUp EXCEPT !.referenceTransactionId = one] : one \in Sample(10) }
        \cup { [ZeroNewGiveUp EXCEPT !.referenceTradeNumber = one] : one \in Sample(15) }
        \cup { [ZeroNewGiveUp EXCEPT !.giveUpFirm = one] : one \in Sample(4) }
        \cup { [ZeroNewGiveUp EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroNewGiveUp EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroNewGiveUp EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroNewGiveUp EXCEPT !.clientAccountNumber = one] : one \in Sample(12) }
        \cup { [ZeroNewGiveUp EXCEPT !.subTraderId = one] : one \in Sample(3) }
        \cup { [ZeroNewGiveUp EXCEPT !.cmtaBroker = one] : one \in Sample(4) }
        \cup { [ZeroNewGiveUp EXCEPT !.clientMemo = one] : one \in Sample(16) }
        \cup { [ZeroNewGiveUp EXCEPT !.additionalFirm = one] : one \in Sample(4) }
        \cup { [ZeroNewGiveUp EXCEPT !.additionalClientMemo = one] : one \in Sample(16) }

(***************************************************************************)
(* Modify Give Up: 94 bytes                                                *)
(***************************************************************************)

ModifyGiveUp ==
    [ referenceTransactionId : Sample(10),
      referenceTradeNumber   : Sample(15),
      giveUpFirm             : Sample(4),
      volume                 : Sample(8),
      accountType            : Sample(1),
      openClose              : Sample(1),
      clientAccountNumber    : Sample(12),
      subTraderId            : Sample(3),
      cmtaBroker             : Sample(4),
      clientMemo             : Sample(16),
      additionalFirm         : Sample(4),
      additionalClientMemo   : Sample(16) ]

EncodeModifyGiveUp(message) ==
    message.referenceTransactionId
        \o message.referenceTradeNumber
        \o message.giveUpFirm
        \o message.volume
        \o message.accountType
        \o message.openClose
        \o message.clientAccountNumber
        \o message.subTraderId
        \o message.cmtaBroker
        \o message.clientMemo
        \o message.additionalFirm
        \o message.additionalClientMemo

DecodeModifyGiveUp(bytes) ==
    LET referenceTransactionId == ReadBytes(bytes, 10) IN IF ~referenceTransactionId.ok THEN Fail ELSE
    LET referenceTradeNumber == ReadBytes(referenceTransactionId.rest, 15) IN IF ~referenceTradeNumber.ok THEN Fail ELSE
    LET giveUpFirm == ReadBytes(referenceTradeNumber.rest, 4) IN IF ~giveUpFirm.ok THEN Fail ELSE
    LET volume == ReadBytes(giveUpFirm.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET accountType == ReadBytes(volume.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET openClose == ReadBytes(accountType.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET clientAccountNumber == ReadBytes(openClose.rest, 12) IN IF ~clientAccountNumber.ok THEN Fail ELSE
    LET subTraderId == ReadBytes(clientAccountNumber.rest, 3) IN IF ~subTraderId.ok THEN Fail ELSE
    LET cmtaBroker == ReadBytes(subTraderId.rest, 4) IN IF ~cmtaBroker.ok THEN Fail ELSE
    LET clientMemo == ReadBytes(cmtaBroker.rest, 16) IN IF ~clientMemo.ok THEN Fail ELSE
    LET additionalFirm == ReadBytes(clientMemo.rest, 4) IN IF ~additionalFirm.ok THEN Fail ELSE
    LET additionalClientMemo == ReadBytes(additionalFirm.rest, 16) IN IF ~additionalClientMemo.ok THEN Fail ELSE
    Ok([ referenceTransactionId |-> referenceTransactionId.value,
         referenceTradeNumber   |-> referenceTradeNumber.value,
         giveUpFirm             |-> giveUpFirm.value,
         volume                 |-> volume.value,
         accountType            |-> accountType.value,
         openClose              |-> openClose.value,
         clientAccountNumber    |-> clientAccountNumber.value,
         subTraderId            |-> subTraderId.value,
         cmtaBroker             |-> cmtaBroker.value,
         clientMemo             |-> clientMemo.value,
         additionalFirm         |-> additionalFirm.value,
         additionalClientMemo   |-> additionalClientMemo.value ], additionalClientMemo.rest)

ZeroModifyGiveUp ==
    [ referenceTransactionId |-> [i \in 1 .. 10 |-> 0],
      referenceTradeNumber   |-> [i \in 1 .. 15 |-> 0],
      giveUpFirm             |-> [i \in 1 .. 4 |-> 0],
      volume                 |-> [i \in 1 .. 8 |-> 0],
      accountType            |-> [i \in 1 .. 1 |-> 0],
      openClose              |-> [i \in 1 .. 1 |-> 0],
      clientAccountNumber    |-> [i \in 1 .. 12 |-> 0],
      subTraderId            |-> [i \in 1 .. 3 |-> 0],
      cmtaBroker             |-> [i \in 1 .. 4 |-> 0],
      clientMemo             |-> [i \in 1 .. 16 |-> 0],
      additionalFirm         |-> [i \in 1 .. 4 |-> 0],
      additionalClientMemo   |-> [i \in 1 .. 16 |-> 0] ]

(* Modify Give Up at zero, then each field in turn at the values it is checked at *)
CheckedModifyGiveUp ==
    { ZeroModifyGiveUp }
        \cup { [ZeroModifyGiveUp EXCEPT !.referenceTransactionId = one] : one \in Sample(10) }
        \cup { [ZeroModifyGiveUp EXCEPT !.referenceTradeNumber = one] : one \in Sample(15) }
        \cup { [ZeroModifyGiveUp EXCEPT !.giveUpFirm = one] : one \in Sample(4) }
        \cup { [ZeroModifyGiveUp EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroModifyGiveUp EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroModifyGiveUp EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroModifyGiveUp EXCEPT !.clientAccountNumber = one] : one \in Sample(12) }
        \cup { [ZeroModifyGiveUp EXCEPT !.subTraderId = one] : one \in Sample(3) }
        \cup { [ZeroModifyGiveUp EXCEPT !.cmtaBroker = one] : one \in Sample(4) }
        \cup { [ZeroModifyGiveUp EXCEPT !.clientMemo = one] : one \in Sample(16) }
        \cup { [ZeroModifyGiveUp EXCEPT !.additionalFirm = one] : one \in Sample(4) }
        \cup { [ZeroModifyGiveUp EXCEPT !.additionalClientMemo = one] : one \in Sample(16) }

(***************************************************************************)
(* Delete Give Up: 25 bytes                                                *)
(***************************************************************************)

DeleteGiveUp ==
    [ referenceTransactionId : Sample(10),
      referenceTradeNumber   : Sample(15) ]

EncodeDeleteGiveUp(message) ==
    message.referenceTransactionId
        \o message.referenceTradeNumber

DecodeDeleteGiveUp(bytes) ==
    LET referenceTransactionId == ReadBytes(bytes, 10) IN IF ~referenceTransactionId.ok THEN Fail ELSE
    LET referenceTradeNumber == ReadBytes(referenceTransactionId.rest, 15) IN IF ~referenceTradeNumber.ok THEN Fail ELSE
    Ok([ referenceTransactionId |-> referenceTransactionId.value,
         referenceTradeNumber   |-> referenceTradeNumber.value ], referenceTradeNumber.rest)

ZeroDeleteGiveUp ==
    [ referenceTransactionId |-> [i \in 1 .. 10 |-> 0],
      referenceTradeNumber   |-> [i \in 1 .. 15 |-> 0] ]

(* Delete Give Up at zero, then each field in turn at the values it is checked at *)
CheckedDeleteGiveUp ==
    { ZeroDeleteGiveUp }
        \cup { [ZeroDeleteGiveUp EXCEPT !.referenceTransactionId = one] : one \in Sample(10) }
        \cup { [ZeroDeleteGiveUp EXCEPT !.referenceTradeNumber = one] : one \in Sample(15) }

(***************************************************************************)
(* Client Message, selected by Message Type                                *)
(***************************************************************************)

StartOfDayAcknowledgementCode == 12337  \* "01"
CircuitResponseCode == 12339  \* "03"
RestartRequestCode == 12340  \* "04"
ClientSignonCode == 12345  \* "09"
NewAllocationCode == 13362  \* "42"
ModifyAllocationCode == 13363  \* "43"
DeleteAllocationCode == 13364  \* "44"
NewGiveUpCode == 13618  \* "52"
ModifyGiveUpCode == 13619  \* "53"
DeleteGiveUpCode == 13620  \* "54"

ClientMessage ==
    [ tag : {StartOfDayAcknowledgementCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {CircuitResponseCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {RestartRequestCode}, body : RestartRequest ]
        \cup [ tag : {ClientSignonCode}, body : ClientSignon ]
        \cup [ tag : {NewAllocationCode}, body : NewAllocation ]
        \cup [ tag : {ModifyAllocationCode}, body : ModifyAllocation ]
        \cup [ tag : {DeleteAllocationCode}, body : DeleteAllocation ]
        \cup [ tag : {NewGiveUpCode}, body : NewGiveUp ]
        \cup [ tag : {ModifyGiveUpCode}, body : ModifyGiveUp ]
        \cup [ tag : {DeleteGiveUpCode}, body : DeleteGiveUp ]

EncodeClientMessage(message) ==
    CASE message.tag = StartOfDayAcknowledgementCode -> << >>
      [] message.tag = CircuitResponseCode -> << >>
      [] message.tag = RestartRequestCode -> EncodeRestartRequest(message.body)
      [] message.tag = ClientSignonCode -> EncodeClientSignon(message.body)
      [] message.tag = NewAllocationCode -> EncodeNewAllocation(message.body)
      [] message.tag = ModifyAllocationCode -> EncodeModifyAllocation(message.body)
      [] message.tag = DeleteAllocationCode -> EncodeDeleteAllocation(message.body)
      [] message.tag = NewGiveUpCode -> EncodeNewGiveUp(message.body)
      [] message.tag = ModifyGiveUpCode -> EncodeModifyGiveUp(message.body)
      [] message.tag = DeleteGiveUpCode -> EncodeDeleteGiveUp(message.body)

DecodeClientMessage(tag, bytes) ==
    LET read ==
            CASE tag = StartOfDayAcknowledgementCode -> Ok([empty |-> 0], bytes)
              [] tag = CircuitResponseCode -> Ok([empty |-> 0], bytes)
              [] tag = RestartRequestCode -> DecodeRestartRequest(bytes)
              [] tag = ClientSignonCode -> DecodeClientSignon(bytes)
              [] tag = NewAllocationCode -> DecodeNewAllocation(bytes)
              [] tag = ModifyAllocationCode -> DecodeModifyAllocation(bytes)
              [] tag = DeleteAllocationCode -> DecodeDeleteAllocation(bytes)
              [] tag = NewGiveUpCode -> DecodeNewGiveUp(bytes)
              [] tag = ModifyGiveUpCode -> DecodeModifyGiveUp(bytes)
              [] tag = DeleteGiveUpCode -> DecodeDeleteGiveUp(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroClientMessage == [tag |-> StartOfDayAcknowledgementCode, body |-> [empty |-> 0]]

(* Each Client Message in turn, at the values the message it names is checked at *)
CheckedClientMessage ==
    { [tag |-> StartOfDayAcknowledgementCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> CircuitResponseCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> RestartRequestCode, body |-> one] : one \in CheckedRestartRequest }
        \cup { [tag |-> ClientSignonCode, body |-> one] : one \in CheckedClientSignon }
        \cup { [tag |-> NewAllocationCode, body |-> one] : one \in CheckedNewAllocation }
        \cup { [tag |-> ModifyAllocationCode, body |-> one] : one \in CheckedModifyAllocation }
        \cup { [tag |-> DeleteAllocationCode, body |-> one] : one \in CheckedDeleteAllocation }
        \cup { [tag |-> NewGiveUpCode, body |-> one] : one \in CheckedNewGiveUp }
        \cup { [tag |-> ModifyGiveUpCode, body |-> one] : one \in CheckedModifyGiveUp }
        \cup { [tag |-> DeleteGiveUpCode, body |-> one] : one \in CheckedDeleteGiveUp }

(***************************************************************************)
(* Client Sola Frame                                                       *)
(***************************************************************************)

ClientSolaFrame ==
    [ source                        : Sample(4),
      destination                   : Sample(4),
      messageFlag                   : Sample(1),
      controlByte                   : Sample(1),
      sequenceNumber                : Sample(8),
      acknowledgementSequenceNumber : Sample(8),
      clientMessage                 : ClientMessage,
      solaMessageEnd                : Sample(1) ]

EncodeClientSolaFrame(message) ==
    message.source
        \o message.destination
        \o EncodeUIntBE(message.clientMessage.tag, 2)
        \o message.messageFlag
        \o message.controlByte
        \o message.sequenceNumber
        \o message.acknowledgementSequenceNumber
        \o EncodeClientMessage(message.clientMessage)
        \o message.solaMessageEnd

DecodeClientSolaFrame(bytes) ==
    LET source == ReadBytes(bytes, 4) IN IF ~source.ok THEN Fail ELSE
    LET destination == ReadBytes(source.rest, 4) IN IF ~destination.ok THEN Fail ELSE
    LET messageType == ReadUIntBE(destination.rest, 2) IN IF ~messageType.ok THEN Fail ELSE
    LET messageFlag == ReadBytes(messageType.rest, 1) IN IF ~messageFlag.ok THEN Fail ELSE
    LET controlByte == ReadBytes(messageFlag.rest, 1) IN IF ~controlByte.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(controlByte.rest, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET acknowledgementSequenceNumber == ReadBytes(sequenceNumber.rest, 8) IN IF ~acknowledgementSequenceNumber.ok THEN Fail ELSE
    LET clientMessage == DecodeClientMessage(messageType.value, acknowledgementSequenceNumber.rest) IN IF ~clientMessage.ok THEN Fail ELSE
    LET solaMessageEnd == ReadBytes(clientMessage.rest, 1) IN IF ~solaMessageEnd.ok THEN Fail ELSE
    Ok([ source                        |-> source.value,
         destination                   |-> destination.value,
         messageFlag                   |-> messageFlag.value,
         controlByte                   |-> controlByte.value,
         sequenceNumber                |-> sequenceNumber.value,
         acknowledgementSequenceNumber |-> acknowledgementSequenceNumber.value,
         clientMessage                 |-> clientMessage.value,
         solaMessageEnd                |-> solaMessageEnd.value ], solaMessageEnd.rest)

ZeroClientSolaFrame ==
    [ source                        |-> [i \in 1 .. 4 |-> 0],
      destination                   |-> [i \in 1 .. 4 |-> 0],
      messageFlag                   |-> [i \in 1 .. 1 |-> 0],
      controlByte                   |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber                |-> [i \in 1 .. 8 |-> 0],
      acknowledgementSequenceNumber |-> [i \in 1 .. 8 |-> 0],
      clientMessage                 |-> ZeroClientMessage,
      solaMessageEnd                |-> [i \in 1 .. 1 |-> 0] ]

(* Client Sola Frame at zero, then each field in turn at the values it is checked at *)
CheckedClientSolaFrame ==
    { ZeroClientSolaFrame }
        \cup { [ZeroClientSolaFrame EXCEPT !.source = one] : one \in Sample(4) }
        \cup { [ZeroClientSolaFrame EXCEPT !.destination = one] : one \in Sample(4) }
        \cup { [ZeroClientSolaFrame EXCEPT !.messageFlag = one] : one \in Sample(1) }
        \cup { [ZeroClientSolaFrame EXCEPT !.controlByte = one] : one \in Sample(1) }
        \cup { [ZeroClientSolaFrame EXCEPT !.sequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroClientSolaFrame EXCEPT !.acknowledgementSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroClientSolaFrame EXCEPT !.clientMessage = one] : one \in CheckedClientMessage }
        \cup { [ZeroClientSolaFrame EXCEPT !.solaMessageEnd = one] : one \in Sample(1) }

(* A run of Client Sola Frame, written one after another *)
RECURSIVE EncodeClientSolaFrameList(_)
EncodeClientSolaFrameList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeClientSolaFrame(Head(messages)) \o EncodeClientSolaFrameList(Tail(messages))

(* As many Client Sola Frame as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadClientSolaFrameAll(_)
ReadClientSolaFrameAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeClientSolaFrame(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadClientSolaFrameAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Client Sola Frame of each kind, for the lists that carry them *)
OneClientSolaFrame ==
    { [ZeroClientSolaFrame EXCEPT !.clientMessage = [tag |-> StartOfDayAcknowledgementCode, body |-> [empty |-> 0]]],
      [ZeroClientSolaFrame EXCEPT !.clientMessage = [tag |-> CircuitResponseCode, body |-> [empty |-> 0]]],
      [ZeroClientSolaFrame EXCEPT !.clientMessage = [tag |-> RestartRequestCode, body |-> ZeroRestartRequest]],
      [ZeroClientSolaFrame EXCEPT !.clientMessage = [tag |-> ClientSignonCode, body |-> ZeroClientSignon]],
      [ZeroClientSolaFrame EXCEPT !.clientMessage = [tag |-> NewAllocationCode, body |-> ZeroNewAllocation]],
      [ZeroClientSolaFrame EXCEPT !.clientMessage = [tag |-> ModifyAllocationCode, body |-> ZeroModifyAllocation]],
      [ZeroClientSolaFrame EXCEPT !.clientMessage = [tag |-> DeleteAllocationCode, body |-> ZeroDeleteAllocation]],
      [ZeroClientSolaFrame EXCEPT !.clientMessage = [tag |-> NewGiveUpCode, body |-> ZeroNewGiveUp]],
      [ZeroClientSolaFrame EXCEPT !.clientMessage = [tag |-> ModifyGiveUpCode, body |-> ZeroModifyGiveUp]],
      [ZeroClientSolaFrame EXCEPT !.clientMessage = [tag |-> DeleteGiveUpCode, body |-> ZeroDeleteGiveUp]] }

(***************************************************************************)
(* Client Packet                                                           *)
(***************************************************************************)

ClientPacket ==
    [ clientSolaFrame : SampleLists(OneClientSolaFrame) ]

EncodeClientPacket(message) ==
    EncodeClientSolaFrameList(message.clientSolaFrame)

DecodeClientPacket(bytes) ==
    LET clientSolaFrame == ReadClientSolaFrameAll(bytes) IN IF ~clientSolaFrame.ok THEN Fail ELSE
    Ok([ clientSolaFrame |-> clientSolaFrame.value ], clientSolaFrame.rest)

ZeroClientPacket ==
    [ clientSolaFrame |-> << >> ]

(* Client Packet at zero, then each field in turn at the values it is checked at *)
CheckedClientPacket ==
    { ZeroClientPacket }
        \cup { [ZeroClientPacket EXCEPT !.clientSolaFrame = one] : one \in SampleLists(OneClientSolaFrame) }

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

(* Every Restart Request decodes back to what was encoded, and leaves nothing over *)
RoundTripRestartRequest ==
    \A message \in CheckedRestartRequest :
        LET read == DecodeRestartRequest(EncodeRestartRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client Signon decodes back to what was encoded, and leaves nothing over *)
RoundTripClientSignon ==
    \A message \in CheckedClientSignon :
        LET read == DecodeClientSignon(EncodeClientSignon(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Allocation decodes back to what was encoded, and leaves nothing over *)
RoundTripNewAllocation ==
    \A message \in CheckedNewAllocation :
        LET read == DecodeNewAllocation(EncodeNewAllocation(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Allocation decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyAllocation ==
    \A message \in CheckedModifyAllocation :
        LET read == DecodeModifyAllocation(EncodeModifyAllocation(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Delete Allocation decodes back to what was encoded, and leaves nothing over *)
RoundTripDeleteAllocation ==
    \A message \in CheckedDeleteAllocation :
        LET read == DecodeDeleteAllocation(EncodeDeleteAllocation(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Give Up decodes back to what was encoded, and leaves nothing over *)
RoundTripNewGiveUp ==
    \A message \in CheckedNewGiveUp :
        LET read == DecodeNewGiveUp(EncodeNewGiveUp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Give Up decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyGiveUp ==
    \A message \in CheckedModifyGiveUp :
        LET read == DecodeModifyGiveUp(EncodeModifyGiveUp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Delete Give Up decodes back to what was encoded, and leaves nothing over *)
RoundTripDeleteGiveUp ==
    \A message \in CheckedDeleteGiveUp :
        LET read == DecodeDeleteGiveUp(EncodeDeleteGiveUp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client Sola Frame decodes back to what was encoded, and leaves nothing over *)
RoundTripClientSolaFrame ==
    \A message \in CheckedClientSolaFrame :
        LET read == DecodeClientSolaFrame(EncodeClientSolaFrame(message))
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

(* A Client Message is selected by the Message Type it is written under *)
SelectsClientMessage ==
    \A message \in CheckedClientMessage :
        LET sent == EncodeClientMessage(message)
            read == DecodeClientMessage(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
