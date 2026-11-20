------------ MODULE NairobiDerivatives_MarketData_v2_14_Client -------------
(***************************************************************************)
(* Nairobi Securities Exchange Nairobi Derivatives Market Data v2.14       *)
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
(* Note: Contracts To Unsubscribe is written as 40 slots, however many of  *)
(* them the count beside it says are in use.                               *)
(*                                                                         *)
(* Note: Contracts Requested For Display is written as 40 slots, however   *)
(* many of them the count beside it says are in use.                       *)
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
(* User Name: 16 bytes                                                     *)
(***************************************************************************)

UserName ==
    [ userNameLengthByte : Sample(1),
      userNameCharacters : Sample(15) ]

EncodeUserName(message) ==
    message.userNameLengthByte
        \o message.userNameCharacters

DecodeUserName(bytes) ==
    LET userNameLengthByte == ReadBytes(bytes, 1) IN IF ~userNameLengthByte.ok THEN Fail ELSE
    LET userNameCharacters == ReadBytes(userNameLengthByte.rest, 15) IN IF ~userNameCharacters.ok THEN Fail ELSE
    Ok([ userNameLengthByte |-> userNameLengthByte.value,
         userNameCharacters |-> userNameCharacters.value ], userNameCharacters.rest)

ZeroUserName ==
    [ userNameLengthByte |-> [i \in 1 .. 1 |-> 0],
      userNameCharacters |-> [i \in 1 .. 15 |-> 0] ]

(* User Name at zero, then each field in turn at the values it is checked at *)
CheckedUserName ==
    { ZeroUserName }
        \cup { [ZeroUserName EXCEPT !.userNameLengthByte = one] : one \in Sample(1) }
        \cup { [ZeroUserName EXCEPT !.userNameCharacters = one] : one \in Sample(15) }

(***************************************************************************)
(* Time: 4 bytes                                                           *)
(***************************************************************************)

Time ==
    [ hours   : Sample(1),
      minutes : Sample(1),
      seconds : Sample(1),
      unused1 : Sample(1) ]

EncodeTime(message) ==
    message.hours
        \o message.minutes
        \o message.seconds
        \o message.unused1

DecodeTime(bytes) ==
    LET hours == ReadBytes(bytes, 1) IN IF ~hours.ok THEN Fail ELSE
    LET minutes == ReadBytes(hours.rest, 1) IN IF ~minutes.ok THEN Fail ELSE
    LET seconds == ReadBytes(minutes.rest, 1) IN IF ~seconds.ok THEN Fail ELSE
    LET unused1 == ReadBytes(seconds.rest, 1) IN IF ~unused1.ok THEN Fail ELSE
    Ok([ hours   |-> hours.value,
         minutes |-> minutes.value,
         seconds |-> seconds.value,
         unused1 |-> unused1.value ], unused1.rest)

ZeroTime ==
    [ hours   |-> [i \in 1 .. 1 |-> 0],
      minutes |-> [i \in 1 .. 1 |-> 0],
      seconds |-> [i \in 1 .. 1 |-> 0],
      unused1 |-> [i \in 1 .. 1 |-> 0] ]

(* Time at zero, then each field in turn at the values it is checked at *)
CheckedTime ==
    { ZeroTime }
        \cup { [ZeroTime EXCEPT !.hours = one] : one \in Sample(1) }
        \cup { [ZeroTime EXCEPT !.minutes = one] : one \in Sample(1) }
        \cup { [ZeroTime EXCEPT !.seconds = one] : one \in Sample(1) }
        \cup { [ZeroTime EXCEPT !.unused1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Log In Message: 624 bytes                                               *)
(***************************************************************************)

LogInMessage ==
    [ encryptedPassword : Sample(312),
      newPassword       : Sample(312) ]

EncodeLogInMessage(message) ==
    message.encryptedPassword
        \o message.newPassword

DecodeLogInMessage(bytes) ==
    LET encryptedPassword == ReadBytes(bytes, 312) IN IF ~encryptedPassword.ok THEN Fail ELSE
    LET newPassword == ReadBytes(encryptedPassword.rest, 312) IN IF ~newPassword.ok THEN Fail ELSE
    Ok([ encryptedPassword |-> encryptedPassword.value,
         newPassword       |-> newPassword.value ], newPassword.rest)

ZeroLogInMessage ==
    [ encryptedPassword |-> [i \in 1 .. 312 |-> 0],
      newPassword       |-> [i \in 1 .. 312 |-> 0] ]

(* Log In Message at zero, then each field in turn at the values it is checked at *)
CheckedLogInMessage ==
    { ZeroLogInMessage }
        \cup { [ZeroLogInMessage EXCEPT !.encryptedPassword = one] : one \in Sample(312) }
        \cup { [ZeroLogInMessage EXCEPT !.newPassword = one] : one \in Sample(312) }

(***************************************************************************)
(* Re Request Message: 12 bytes                                            *)
(***************************************************************************)

ReRequestMessage ==
    [ fromSequence        : Sample(4),
      toSequence          : Sample(4),
      marketShardNumberI4 : Sample(4) ]

EncodeReRequestMessage(message) ==
    message.fromSequence
        \o message.toSequence
        \o message.marketShardNumberI4

DecodeReRequestMessage(bytes) ==
    LET fromSequence == ReadBytes(bytes, 4) IN IF ~fromSequence.ok THEN Fail ELSE
    LET toSequence == ReadBytes(fromSequence.rest, 4) IN IF ~toSequence.ok THEN Fail ELSE
    LET marketShardNumberI4 == ReadBytes(toSequence.rest, 4) IN IF ~marketShardNumberI4.ok THEN Fail ELSE
    Ok([ fromSequence        |-> fromSequence.value,
         toSequence          |-> toSequence.value,
         marketShardNumberI4 |-> marketShardNumberI4.value ], marketShardNumberI4.rest)

ZeroReRequestMessage ==
    [ fromSequence        |-> [i \in 1 .. 4 |-> 0],
      toSequence          |-> [i \in 1 .. 4 |-> 0],
      marketShardNumberI4 |-> [i \in 1 .. 4 |-> 0] ]

(* Re Request Message at zero, then each field in turn at the values it is checked at *)
CheckedReRequestMessage ==
    { ZeroReRequestMessage }
        \cup { [ZeroReRequestMessage EXCEPT !.fromSequence = one] : one \in Sample(4) }
        \cup { [ZeroReRequestMessage EXCEPT !.toSequence = one] : one \in Sample(4) }
        \cup { [ZeroReRequestMessage EXCEPT !.marketShardNumberI4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Download Date: 12 bytes                                                 *)
(***************************************************************************)

DownloadDate ==
    [ year  : Sample(4),
      month : Sample(4),
      day   : Sample(4) ]

EncodeDownloadDate(message) ==
    message.year
        \o message.month
        \o message.day

DecodeDownloadDate(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 4) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 4) IN IF ~day.ok THEN Fail ELSE
    Ok([ year  |-> year.value,
         month |-> month.value,
         day   |-> day.value ], day.rest)

ZeroDownloadDate ==
    [ year  |-> [i \in 1 .. 4 |-> 0],
      month |-> [i \in 1 .. 4 |-> 0],
      day   |-> [i \in 1 .. 4 |-> 0] ]

(* Download Date at zero, then each field in turn at the values it is checked at *)
CheckedDownloadDate ==
    { ZeroDownloadDate }
        \cup { [ZeroDownloadDate EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroDownloadDate EXCEPT !.month = one] : one \in Sample(4) }
        \cup { [ZeroDownloadDate EXCEPT !.day = one] : one \in Sample(4) }

(***************************************************************************)
(* Request Data Retrieval Message: 24 bytes                                *)
(***************************************************************************)

RequestDataRetrievalMessage ==
    [ dataType         : Sample(1),
      unused1          : Sample(1),
      lastPieceOfChunk : Sample(1),
      reRequest        : Sample(1),
      action           : Sample(4),
      specificRecord   : Sample(4),
      downloadDate     : DownloadDate ]

EncodeRequestDataRetrievalMessage(message) ==
    message.dataType
        \o message.unused1
        \o message.lastPieceOfChunk
        \o message.reRequest
        \o message.action
        \o message.specificRecord
        \o EncodeDownloadDate(message.downloadDate)

DecodeRequestDataRetrievalMessage(bytes) ==
    LET dataType == ReadBytes(bytes, 1) IN IF ~dataType.ok THEN Fail ELSE
    LET unused1 == ReadBytes(dataType.rest, 1) IN IF ~unused1.ok THEN Fail ELSE
    LET lastPieceOfChunk == ReadBytes(unused1.rest, 1) IN IF ~lastPieceOfChunk.ok THEN Fail ELSE
    LET reRequest == ReadBytes(lastPieceOfChunk.rest, 1) IN IF ~reRequest.ok THEN Fail ELSE
    LET action == ReadBytes(reRequest.rest, 4) IN IF ~action.ok THEN Fail ELSE
    LET specificRecord == ReadBytes(action.rest, 4) IN IF ~specificRecord.ok THEN Fail ELSE
    LET downloadDate == DecodeDownloadDate(specificRecord.rest) IN IF ~downloadDate.ok THEN Fail ELSE
    Ok([ dataType         |-> dataType.value,
         unused1          |-> unused1.value,
         lastPieceOfChunk |-> lastPieceOfChunk.value,
         reRequest        |-> reRequest.value,
         action           |-> action.value,
         specificRecord   |-> specificRecord.value,
         downloadDate     |-> downloadDate.value ], downloadDate.rest)

ZeroRequestDataRetrievalMessage ==
    [ dataType         |-> [i \in 1 .. 1 |-> 0],
      unused1          |-> [i \in 1 .. 1 |-> 0],
      lastPieceOfChunk |-> [i \in 1 .. 1 |-> 0],
      reRequest        |-> [i \in 1 .. 1 |-> 0],
      action           |-> [i \in 1 .. 4 |-> 0],
      specificRecord   |-> [i \in 1 .. 4 |-> 0],
      downloadDate     |-> ZeroDownloadDate ]

(* Request Data Retrieval Message at zero, then each field in turn at the values it is checked at *)
CheckedRequestDataRetrievalMessage ==
    { ZeroRequestDataRetrievalMessage }
        \cup { [ZeroRequestDataRetrievalMessage EXCEPT !.dataType = one] : one \in Sample(1) }
        \cup { [ZeroRequestDataRetrievalMessage EXCEPT !.unused1 = one] : one \in Sample(1) }
        \cup { [ZeroRequestDataRetrievalMessage EXCEPT !.lastPieceOfChunk = one] : one \in Sample(1) }
        \cup { [ZeroRequestDataRetrievalMessage EXCEPT !.reRequest = one] : one \in Sample(1) }
        \cup { [ZeroRequestDataRetrievalMessage EXCEPT !.action = one] : one \in Sample(4) }
        \cup { [ZeroRequestDataRetrievalMessage EXCEPT !.specificRecord = one] : one \in Sample(4) }
        \cup { [ZeroRequestDataRetrievalMessage EXCEPT !.downloadDate = one] : one \in CheckedDownloadDate }

(***************************************************************************)
(* Date: 12 bytes                                                          *)
(***************************************************************************)

Date ==
    [ year  : Sample(4),
      month : Sample(4),
      day   : Sample(4) ]

EncodeDate(message) ==
    message.year
        \o message.month
        \o message.day

DecodeDate(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 4) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 4) IN IF ~day.ok THEN Fail ELSE
    Ok([ year  |-> year.value,
         month |-> month.value,
         day   |-> day.value ], day.rest)

ZeroDate ==
    [ year  |-> [i \in 1 .. 4 |-> 0],
      month |-> [i \in 1 .. 4 |-> 0],
      day   |-> [i \in 1 .. 4 |-> 0] ]

(* Date at zero, then each field in turn at the values it is checked at *)
CheckedDate ==
    { ZeroDate }
        \cup { [ZeroDate EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroDate EXCEPT !.month = one] : one \in Sample(4) }
        \cup { [ZeroDate EXCEPT !.day = one] : one \in Sample(4) }

(***************************************************************************)
(* Instrument Name P 5: 5 bytes                                            *)
(***************************************************************************)

InstrumentNameP5 ==
    [ instrumentNameP5LengthByte : Sample(1),
      instrumentNameP5Characters : Sample(4) ]

EncodeInstrumentNameP5(message) ==
    message.instrumentNameP5LengthByte
        \o message.instrumentNameP5Characters

DecodeInstrumentNameP5(bytes) ==
    LET instrumentNameP5LengthByte == ReadBytes(bytes, 1) IN IF ~instrumentNameP5LengthByte.ok THEN Fail ELSE
    LET instrumentNameP5Characters == ReadBytes(instrumentNameP5LengthByte.rest, 4) IN IF ~instrumentNameP5Characters.ok THEN Fail ELSE
    Ok([ instrumentNameP5LengthByte |-> instrumentNameP5LengthByte.value,
         instrumentNameP5Characters |-> instrumentNameP5Characters.value ], instrumentNameP5Characters.rest)

ZeroInstrumentNameP5 ==
    [ instrumentNameP5LengthByte |-> [i \in 1 .. 1 |-> 0],
      instrumentNameP5Characters |-> [i \in 1 .. 4 |-> 0] ]

(* Instrument Name P 5 at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentNameP5 ==
    { ZeroInstrumentNameP5 }
        \cup { [ZeroInstrumentNameP5 EXCEPT !.instrumentNameP5LengthByte = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentNameP5 EXCEPT !.instrumentNameP5Characters = one] : one \in Sample(4) }

(***************************************************************************)
(* Secondary Date: 12 bytes                                                *)
(***************************************************************************)

SecondaryDate ==
    [ year  : Sample(4),
      month : Sample(4),
      day   : Sample(4) ]

EncodeSecondaryDate(message) ==
    message.year
        \o message.month
        \o message.day

DecodeSecondaryDate(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 4) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 4) IN IF ~day.ok THEN Fail ELSE
    Ok([ year  |-> year.value,
         month |-> month.value,
         day   |-> day.value ], day.rest)

ZeroSecondaryDate ==
    [ year  |-> [i \in 1 .. 4 |-> 0],
      month |-> [i \in 1 .. 4 |-> 0],
      day   |-> [i \in 1 .. 4 |-> 0] ]

(* Secondary Date at zero, then each field in turn at the values it is checked at *)
CheckedSecondaryDate ==
    { ZeroSecondaryDate }
        \cup { [ZeroSecondaryDate EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroSecondaryDate EXCEPT !.month = one] : one \in Sample(4) }
        \cup { [ZeroSecondaryDate EXCEPT !.day = one] : one \in Sample(4) }

(***************************************************************************)
(* Secondary Instrument Name P 5: 5 bytes                                  *)
(***************************************************************************)

SecondaryInstrumentNameP5 ==
    [ secondaryInstrumentNameP5LengthByte : Sample(1),
      secondaryInstrumentNameP5Characters : Sample(4) ]

EncodeSecondaryInstrumentNameP5(message) ==
    message.secondaryInstrumentNameP5LengthByte
        \o message.secondaryInstrumentNameP5Characters

DecodeSecondaryInstrumentNameP5(bytes) ==
    LET secondaryInstrumentNameP5LengthByte == ReadBytes(bytes, 1) IN IF ~secondaryInstrumentNameP5LengthByte.ok THEN Fail ELSE
    LET secondaryInstrumentNameP5Characters == ReadBytes(secondaryInstrumentNameP5LengthByte.rest, 4) IN IF ~secondaryInstrumentNameP5Characters.ok THEN Fail ELSE
    Ok([ secondaryInstrumentNameP5LengthByte |-> secondaryInstrumentNameP5LengthByte.value,
         secondaryInstrumentNameP5Characters |-> secondaryInstrumentNameP5Characters.value ], secondaryInstrumentNameP5Characters.rest)

ZeroSecondaryInstrumentNameP5 ==
    [ secondaryInstrumentNameP5LengthByte |-> [i \in 1 .. 1 |-> 0],
      secondaryInstrumentNameP5Characters |-> [i \in 1 .. 4 |-> 0] ]

(* Secondary Instrument Name P 5 at zero, then each field in turn at the values it is checked at *)
CheckedSecondaryInstrumentNameP5 ==
    { ZeroSecondaryInstrumentNameP5 }
        \cup { [ZeroSecondaryInstrumentNameP5 EXCEPT !.secondaryInstrumentNameP5LengthByte = one] : one \in Sample(1) }
        \cup { [ZeroSecondaryInstrumentNameP5 EXCEPT !.secondaryInstrumentNameP5Characters = one] : one \in Sample(4) }

(***************************************************************************)
(* Contract: 48 bytes                                                      *)
(***************************************************************************)

Contract ==
    [ identifierPrefixI4        : Sample(4),
      date                      : Date,
      instrumentNameP5          : InstrumentNameP5,
      strike                    : Sample(8),
      callPutC1                 : Sample(1),
      secondaryDate             : SecondaryDate,
      secondaryInstrumentNameP5 : SecondaryInstrumentNameP5,
      isDeltaOption             : Sample(1) ]

EncodeContract(message) ==
    message.identifierPrefixI4
        \o EncodeDate(message.date)
        \o EncodeInstrumentNameP5(message.instrumentNameP5)
        \o message.strike
        \o message.callPutC1
        \o EncodeSecondaryDate(message.secondaryDate)
        \o EncodeSecondaryInstrumentNameP5(message.secondaryInstrumentNameP5)
        \o message.isDeltaOption

DecodeContract(bytes) ==
    LET identifierPrefixI4 == ReadBytes(bytes, 4) IN IF ~identifierPrefixI4.ok THEN Fail ELSE
    LET date == DecodeDate(identifierPrefixI4.rest) IN IF ~date.ok THEN Fail ELSE
    LET instrumentNameP5 == DecodeInstrumentNameP5(date.rest) IN IF ~instrumentNameP5.ok THEN Fail ELSE
    LET strike == ReadBytes(instrumentNameP5.rest, 8) IN IF ~strike.ok THEN Fail ELSE
    LET callPutC1 == ReadBytes(strike.rest, 1) IN IF ~callPutC1.ok THEN Fail ELSE
    LET secondaryDate == DecodeSecondaryDate(callPutC1.rest) IN IF ~secondaryDate.ok THEN Fail ELSE
    LET secondaryInstrumentNameP5 == DecodeSecondaryInstrumentNameP5(secondaryDate.rest) IN IF ~secondaryInstrumentNameP5.ok THEN Fail ELSE
    LET isDeltaOption == ReadBytes(secondaryInstrumentNameP5.rest, 1) IN IF ~isDeltaOption.ok THEN Fail ELSE
    Ok([ identifierPrefixI4        |-> identifierPrefixI4.value,
         date                      |-> date.value,
         instrumentNameP5          |-> instrumentNameP5.value,
         strike                    |-> strike.value,
         callPutC1                 |-> callPutC1.value,
         secondaryDate             |-> secondaryDate.value,
         secondaryInstrumentNameP5 |-> secondaryInstrumentNameP5.value,
         isDeltaOption             |-> isDeltaOption.value ], isDeltaOption.rest)

ZeroContract ==
    [ identifierPrefixI4        |-> [i \in 1 .. 4 |-> 0],
      date                      |-> ZeroDate,
      instrumentNameP5          |-> ZeroInstrumentNameP5,
      strike                    |-> [i \in 1 .. 8 |-> 0],
      callPutC1                 |-> [i \in 1 .. 1 |-> 0],
      secondaryDate             |-> ZeroSecondaryDate,
      secondaryInstrumentNameP5 |-> ZeroSecondaryInstrumentNameP5,
      isDeltaOption             |-> [i \in 1 .. 1 |-> 0] ]

(* Contract at zero, then each field in turn at the values it is checked at *)
CheckedContract ==
    { ZeroContract }
        \cup { [ZeroContract EXCEPT !.identifierPrefixI4 = one] : one \in Sample(4) }
        \cup { [ZeroContract EXCEPT !.date = one] : one \in CheckedDate }
        \cup { [ZeroContract EXCEPT !.instrumentNameP5 = one] : one \in CheckedInstrumentNameP5 }
        \cup { [ZeroContract EXCEPT !.strike = one] : one \in Sample(8) }
        \cup { [ZeroContract EXCEPT !.callPutC1 = one] : one \in Sample(1) }
        \cup { [ZeroContract EXCEPT !.secondaryDate = one] : one \in CheckedSecondaryDate }
        \cup { [ZeroContract EXCEPT !.secondaryInstrumentNameP5 = one] : one \in CheckedSecondaryInstrumentNameP5 }
        \cup { [ZeroContract EXCEPT !.isDeltaOption = one] : one \in Sample(1) }

(***************************************************************************)
(* Contracts To Unsubscribe: 48 bytes                                      *)
(***************************************************************************)

ContractsToUnsubscribe ==
    [ contract : Contract ]

EncodeContractsToUnsubscribe(message) ==
    EncodeContract(message.contract)

DecodeContractsToUnsubscribe(bytes) ==
    LET contract == DecodeContract(bytes) IN IF ~contract.ok THEN Fail ELSE
    Ok([ contract |-> contract.value ], contract.rest)

ZeroContractsToUnsubscribe ==
    [ contract |-> ZeroContract ]

(* Contracts To Unsubscribe at zero, then each field in turn at the values it is checked at *)
CheckedContractsToUnsubscribe ==
    { ZeroContractsToUnsubscribe }
        \cup { [ZeroContractsToUnsubscribe EXCEPT !.contract = one] : one \in CheckedContract }

(* A run of Contracts To Unsubscribe, written one after another *)
RECURSIVE EncodeContractsToUnsubscribeList(_)
EncodeContractsToUnsubscribeList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeContractsToUnsubscribe(Head(messages)) \o EncodeContractsToUnsubscribeList(Tail(messages))

(* As many Contracts To Unsubscribe as the field that counts them says *)
RECURSIVE ReadContractsToUnsubscribeList(_, _)
ReadContractsToUnsubscribeList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeContractsToUnsubscribe(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadContractsToUnsubscribeList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Contracts To Unsubscribe of each kind, for the lists that carry them *)
OneContractsToUnsubscribe == { ZeroContractsToUnsubscribe }

(* The 40 slots a run of Contracts To Unsubscribe is written as, whatever the field beside it says are in use *)
SlotsContractsToUnsubscribe == { [i \in 1 .. 40 |-> one] : one \in OneContractsToUnsubscribe }

(***************************************************************************)
(* Unsubscribe Contract Message                                            *)
(***************************************************************************)

UnsubscribeContractMessage ==
    [ quantityI2             : Sample(2),
      contractsToUnsubscribe : SlotsContractsToUnsubscribe ]

EncodeUnsubscribeContractMessage(message) ==
    message.quantityI2
        \o EncodeContractsToUnsubscribeList(message.contractsToUnsubscribe)

DecodeUnsubscribeContractMessage(bytes) ==
    LET quantityI2 == ReadBytes(bytes, 2) IN IF ~quantityI2.ok THEN Fail ELSE
    LET contractsToUnsubscribe == ReadContractsToUnsubscribeList(quantityI2.rest, 40) IN IF ~contractsToUnsubscribe.ok THEN Fail ELSE
    Ok([ quantityI2             |-> quantityI2.value,
         contractsToUnsubscribe |-> contractsToUnsubscribe.value ], contractsToUnsubscribe.rest)

ZeroUnsubscribeContractMessage ==
    [ quantityI2             |-> [i \in 1 .. 2 |-> 0],
      contractsToUnsubscribe |-> [i \in 1 .. 40 |-> ZeroContractsToUnsubscribe] ]

(* Unsubscribe Contract Message at zero, then each field in turn at the values it is checked at *)
CheckedUnsubscribeContractMessage ==
    { ZeroUnsubscribeContractMessage }
        \cup { [ZeroUnsubscribeContractMessage EXCEPT !.quantityI2 = one] : one \in Sample(2) }
        \cup { [ZeroUnsubscribeContractMessage EXCEPT !.contractsToUnsubscribe = one] : one \in SlotsContractsToUnsubscribe }

(***************************************************************************)
(* Date: 12 bytes                                                          *)
(***************************************************************************)

Date2 ==
    [ year  : Sample(4),
      month : Sample(4),
      day   : Sample(4) ]

EncodeDate2(message) ==
    message.year
        \o message.month
        \o message.day

DecodeDate2(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 4) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 4) IN IF ~day.ok THEN Fail ELSE
    Ok([ year  |-> year.value,
         month |-> month.value,
         day   |-> day.value ], day.rest)

ZeroDate2 ==
    [ year  |-> [i \in 1 .. 4 |-> 0],
      month |-> [i \in 1 .. 4 |-> 0],
      day   |-> [i \in 1 .. 4 |-> 0] ]

(* Date at zero, then each field in turn at the values it is checked at *)
CheckedDate2 ==
    { ZeroDate2 }
        \cup { [ZeroDate2 EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroDate2 EXCEPT !.month = one] : one \in Sample(4) }
        \cup { [ZeroDate2 EXCEPT !.day = one] : one \in Sample(4) }

(***************************************************************************)
(* Instrument Name P 5: 5 bytes                                            *)
(***************************************************************************)

InstrumentNameP52 ==
    [ instrumentNameP5LengthByte : Sample(1),
      instrumentNameP5Characters : Sample(4) ]

EncodeInstrumentNameP52(message) ==
    message.instrumentNameP5LengthByte
        \o message.instrumentNameP5Characters

DecodeInstrumentNameP52(bytes) ==
    LET instrumentNameP5LengthByte == ReadBytes(bytes, 1) IN IF ~instrumentNameP5LengthByte.ok THEN Fail ELSE
    LET instrumentNameP5Characters == ReadBytes(instrumentNameP5LengthByte.rest, 4) IN IF ~instrumentNameP5Characters.ok THEN Fail ELSE
    Ok([ instrumentNameP5LengthByte |-> instrumentNameP5LengthByte.value,
         instrumentNameP5Characters |-> instrumentNameP5Characters.value ], instrumentNameP5Characters.rest)

ZeroInstrumentNameP52 ==
    [ instrumentNameP5LengthByte |-> [i \in 1 .. 1 |-> 0],
      instrumentNameP5Characters |-> [i \in 1 .. 4 |-> 0] ]

(* Instrument Name P 5 at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentNameP52 ==
    { ZeroInstrumentNameP52 }
        \cup { [ZeroInstrumentNameP52 EXCEPT !.instrumentNameP5LengthByte = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentNameP52 EXCEPT !.instrumentNameP5Characters = one] : one \in Sample(4) }

(***************************************************************************)
(* Secondary Date: 12 bytes                                                *)
(***************************************************************************)

SecondaryDate2 ==
    [ year  : Sample(4),
      month : Sample(4),
      day   : Sample(4) ]

EncodeSecondaryDate2(message) ==
    message.year
        \o message.month
        \o message.day

DecodeSecondaryDate2(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 4) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 4) IN IF ~day.ok THEN Fail ELSE
    Ok([ year  |-> year.value,
         month |-> month.value,
         day   |-> day.value ], day.rest)

ZeroSecondaryDate2 ==
    [ year  |-> [i \in 1 .. 4 |-> 0],
      month |-> [i \in 1 .. 4 |-> 0],
      day   |-> [i \in 1 .. 4 |-> 0] ]

(* Secondary Date at zero, then each field in turn at the values it is checked at *)
CheckedSecondaryDate2 ==
    { ZeroSecondaryDate2 }
        \cup { [ZeroSecondaryDate2 EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroSecondaryDate2 EXCEPT !.month = one] : one \in Sample(4) }
        \cup { [ZeroSecondaryDate2 EXCEPT !.day = one] : one \in Sample(4) }

(***************************************************************************)
(* Secondary Instrument Name P 5: 5 bytes                                  *)
(***************************************************************************)

SecondaryInstrumentNameP52 ==
    [ secondaryInstrumentNameP5LengthByte : Sample(1),
      secondaryInstrumentNameP5Characters : Sample(4) ]

EncodeSecondaryInstrumentNameP52(message) ==
    message.secondaryInstrumentNameP5LengthByte
        \o message.secondaryInstrumentNameP5Characters

DecodeSecondaryInstrumentNameP52(bytes) ==
    LET secondaryInstrumentNameP5LengthByte == ReadBytes(bytes, 1) IN IF ~secondaryInstrumentNameP5LengthByte.ok THEN Fail ELSE
    LET secondaryInstrumentNameP5Characters == ReadBytes(secondaryInstrumentNameP5LengthByte.rest, 4) IN IF ~secondaryInstrumentNameP5Characters.ok THEN Fail ELSE
    Ok([ secondaryInstrumentNameP5LengthByte |-> secondaryInstrumentNameP5LengthByte.value,
         secondaryInstrumentNameP5Characters |-> secondaryInstrumentNameP5Characters.value ], secondaryInstrumentNameP5Characters.rest)

ZeroSecondaryInstrumentNameP52 ==
    [ secondaryInstrumentNameP5LengthByte |-> [i \in 1 .. 1 |-> 0],
      secondaryInstrumentNameP5Characters |-> [i \in 1 .. 4 |-> 0] ]

(* Secondary Instrument Name P 5 at zero, then each field in turn at the values it is checked at *)
CheckedSecondaryInstrumentNameP52 ==
    { ZeroSecondaryInstrumentNameP52 }
        \cup { [ZeroSecondaryInstrumentNameP52 EXCEPT !.secondaryInstrumentNameP5LengthByte = one] : one \in Sample(1) }
        \cup { [ZeroSecondaryInstrumentNameP52 EXCEPT !.secondaryInstrumentNameP5Characters = one] : one \in Sample(4) }

(***************************************************************************)
(* Contract Name: 48 bytes                                                 *)
(***************************************************************************)

ContractName ==
    [ identifierPrefixI4        : Sample(4),
      date                      : Date2,
      instrumentNameP5          : InstrumentNameP52,
      strike                    : Sample(8),
      callPutC1                 : Sample(1),
      secondaryDate             : SecondaryDate2,
      secondaryInstrumentNameP5 : SecondaryInstrumentNameP52,
      isDeltaOption             : Sample(1) ]

EncodeContractName(message) ==
    message.identifierPrefixI4
        \o EncodeDate2(message.date)
        \o EncodeInstrumentNameP52(message.instrumentNameP5)
        \o message.strike
        \o message.callPutC1
        \o EncodeSecondaryDate2(message.secondaryDate)
        \o EncodeSecondaryInstrumentNameP52(message.secondaryInstrumentNameP5)
        \o message.isDeltaOption

DecodeContractName(bytes) ==
    LET identifierPrefixI4 == ReadBytes(bytes, 4) IN IF ~identifierPrefixI4.ok THEN Fail ELSE
    LET date == DecodeDate2(identifierPrefixI4.rest) IN IF ~date.ok THEN Fail ELSE
    LET instrumentNameP5 == DecodeInstrumentNameP52(date.rest) IN IF ~instrumentNameP5.ok THEN Fail ELSE
    LET strike == ReadBytes(instrumentNameP5.rest, 8) IN IF ~strike.ok THEN Fail ELSE
    LET callPutC1 == ReadBytes(strike.rest, 1) IN IF ~callPutC1.ok THEN Fail ELSE
    LET secondaryDate == DecodeSecondaryDate2(callPutC1.rest) IN IF ~secondaryDate.ok THEN Fail ELSE
    LET secondaryInstrumentNameP5 == DecodeSecondaryInstrumentNameP52(secondaryDate.rest) IN IF ~secondaryInstrumentNameP5.ok THEN Fail ELSE
    LET isDeltaOption == ReadBytes(secondaryInstrumentNameP5.rest, 1) IN IF ~isDeltaOption.ok THEN Fail ELSE
    Ok([ identifierPrefixI4        |-> identifierPrefixI4.value,
         date                      |-> date.value,
         instrumentNameP5          |-> instrumentNameP5.value,
         strike                    |-> strike.value,
         callPutC1                 |-> callPutC1.value,
         secondaryDate             |-> secondaryDate.value,
         secondaryInstrumentNameP5 |-> secondaryInstrumentNameP5.value,
         isDeltaOption             |-> isDeltaOption.value ], isDeltaOption.rest)

ZeroContractName ==
    [ identifierPrefixI4        |-> [i \in 1 .. 4 |-> 0],
      date                      |-> ZeroDate2,
      instrumentNameP5          |-> ZeroInstrumentNameP52,
      strike                    |-> [i \in 1 .. 8 |-> 0],
      callPutC1                 |-> [i \in 1 .. 1 |-> 0],
      secondaryDate             |-> ZeroSecondaryDate2,
      secondaryInstrumentNameP5 |-> ZeroSecondaryInstrumentNameP52,
      isDeltaOption             |-> [i \in 1 .. 1 |-> 0] ]

(* Contract Name at zero, then each field in turn at the values it is checked at *)
CheckedContractName ==
    { ZeroContractName }
        \cup { [ZeroContractName EXCEPT !.identifierPrefixI4 = one] : one \in Sample(4) }
        \cup { [ZeroContractName EXCEPT !.date = one] : one \in CheckedDate2 }
        \cup { [ZeroContractName EXCEPT !.instrumentNameP5 = one] : one \in CheckedInstrumentNameP52 }
        \cup { [ZeroContractName EXCEPT !.strike = one] : one \in Sample(8) }
        \cup { [ZeroContractName EXCEPT !.callPutC1 = one] : one \in Sample(1) }
        \cup { [ZeroContractName EXCEPT !.secondaryDate = one] : one \in CheckedSecondaryDate2 }
        \cup { [ZeroContractName EXCEPT !.secondaryInstrumentNameP5 = one] : one \in CheckedSecondaryInstrumentNameP52 }
        \cup { [ZeroContractName EXCEPT !.isDeltaOption = one] : one \in Sample(1) }

(***************************************************************************)
(* Request Daily Trend Message: 48 bytes                                   *)
(***************************************************************************)

RequestDailyTrendMessage ==
    [ contractName : ContractName ]

EncodeRequestDailyTrendMessage(message) ==
    EncodeContractName(message.contractName)

DecodeRequestDailyTrendMessage(bytes) ==
    LET contractName == DecodeContractName(bytes) IN IF ~contractName.ok THEN Fail ELSE
    Ok([ contractName |-> contractName.value ], contractName.rest)

ZeroRequestDailyTrendMessage ==
    [ contractName |-> ZeroContractName ]

(* Request Daily Trend Message at zero, then each field in turn at the values it is checked at *)
CheckedRequestDailyTrendMessage ==
    { ZeroRequestDailyTrendMessage }
        \cup { [ZeroRequestDailyTrendMessage EXCEPT !.contractName = one] : one \in CheckedContractName }

(***************************************************************************)
(* Date: 12 bytes                                                          *)
(***************************************************************************)

Date3 ==
    [ year  : Sample(4),
      month : Sample(4),
      day   : Sample(4) ]

EncodeDate3(message) ==
    message.year
        \o message.month
        \o message.day

DecodeDate3(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 4) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 4) IN IF ~day.ok THEN Fail ELSE
    Ok([ year  |-> year.value,
         month |-> month.value,
         day   |-> day.value ], day.rest)

ZeroDate3 ==
    [ year  |-> [i \in 1 .. 4 |-> 0],
      month |-> [i \in 1 .. 4 |-> 0],
      day   |-> [i \in 1 .. 4 |-> 0] ]

(* Date at zero, then each field in turn at the values it is checked at *)
CheckedDate3 ==
    { ZeroDate3 }
        \cup { [ZeroDate3 EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroDate3 EXCEPT !.month = one] : one \in Sample(4) }
        \cup { [ZeroDate3 EXCEPT !.day = one] : one \in Sample(4) }

(***************************************************************************)
(* Instrument Name P 5: 5 bytes                                            *)
(***************************************************************************)

InstrumentNameP53 ==
    [ instrumentNameP5LengthByte : Sample(1),
      instrumentNameP5Characters : Sample(4) ]

EncodeInstrumentNameP53(message) ==
    message.instrumentNameP5LengthByte
        \o message.instrumentNameP5Characters

DecodeInstrumentNameP53(bytes) ==
    LET instrumentNameP5LengthByte == ReadBytes(bytes, 1) IN IF ~instrumentNameP5LengthByte.ok THEN Fail ELSE
    LET instrumentNameP5Characters == ReadBytes(instrumentNameP5LengthByte.rest, 4) IN IF ~instrumentNameP5Characters.ok THEN Fail ELSE
    Ok([ instrumentNameP5LengthByte |-> instrumentNameP5LengthByte.value,
         instrumentNameP5Characters |-> instrumentNameP5Characters.value ], instrumentNameP5Characters.rest)

ZeroInstrumentNameP53 ==
    [ instrumentNameP5LengthByte |-> [i \in 1 .. 1 |-> 0],
      instrumentNameP5Characters |-> [i \in 1 .. 4 |-> 0] ]

(* Instrument Name P 5 at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentNameP53 ==
    { ZeroInstrumentNameP53 }
        \cup { [ZeroInstrumentNameP53 EXCEPT !.instrumentNameP5LengthByte = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentNameP53 EXCEPT !.instrumentNameP5Characters = one] : one \in Sample(4) }

(***************************************************************************)
(* Secondary Date: 12 bytes                                                *)
(***************************************************************************)

SecondaryDate3 ==
    [ year  : Sample(4),
      month : Sample(4),
      day   : Sample(4) ]

EncodeSecondaryDate3(message) ==
    message.year
        \o message.month
        \o message.day

DecodeSecondaryDate3(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 4) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 4) IN IF ~day.ok THEN Fail ELSE
    Ok([ year  |-> year.value,
         month |-> month.value,
         day   |-> day.value ], day.rest)

ZeroSecondaryDate3 ==
    [ year  |-> [i \in 1 .. 4 |-> 0],
      month |-> [i \in 1 .. 4 |-> 0],
      day   |-> [i \in 1 .. 4 |-> 0] ]

(* Secondary Date at zero, then each field in turn at the values it is checked at *)
CheckedSecondaryDate3 ==
    { ZeroSecondaryDate3 }
        \cup { [ZeroSecondaryDate3 EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroSecondaryDate3 EXCEPT !.month = one] : one \in Sample(4) }
        \cup { [ZeroSecondaryDate3 EXCEPT !.day = one] : one \in Sample(4) }

(***************************************************************************)
(* Secondary Instrument Name P 5: 5 bytes                                  *)
(***************************************************************************)

SecondaryInstrumentNameP53 ==
    [ secondaryInstrumentNameP5LengthByte : Sample(1),
      secondaryInstrumentNameP5Characters : Sample(4) ]

EncodeSecondaryInstrumentNameP53(message) ==
    message.secondaryInstrumentNameP5LengthByte
        \o message.secondaryInstrumentNameP5Characters

DecodeSecondaryInstrumentNameP53(bytes) ==
    LET secondaryInstrumentNameP5LengthByte == ReadBytes(bytes, 1) IN IF ~secondaryInstrumentNameP5LengthByte.ok THEN Fail ELSE
    LET secondaryInstrumentNameP5Characters == ReadBytes(secondaryInstrumentNameP5LengthByte.rest, 4) IN IF ~secondaryInstrumentNameP5Characters.ok THEN Fail ELSE
    Ok([ secondaryInstrumentNameP5LengthByte |-> secondaryInstrumentNameP5LengthByte.value,
         secondaryInstrumentNameP5Characters |-> secondaryInstrumentNameP5Characters.value ], secondaryInstrumentNameP5Characters.rest)

ZeroSecondaryInstrumentNameP53 ==
    [ secondaryInstrumentNameP5LengthByte |-> [i \in 1 .. 1 |-> 0],
      secondaryInstrumentNameP5Characters |-> [i \in 1 .. 4 |-> 0] ]

(* Secondary Instrument Name P 5 at zero, then each field in turn at the values it is checked at *)
CheckedSecondaryInstrumentNameP53 ==
    { ZeroSecondaryInstrumentNameP53 }
        \cup { [ZeroSecondaryInstrumentNameP53 EXCEPT !.secondaryInstrumentNameP5LengthByte = one] : one \in Sample(1) }
        \cup { [ZeroSecondaryInstrumentNameP53 EXCEPT !.secondaryInstrumentNameP5Characters = one] : one \in Sample(4) }

(***************************************************************************)
(* Contract Name: 48 bytes                                                 *)
(***************************************************************************)

ContractName2 ==
    [ identifierPrefixI4        : Sample(4),
      date                      : Date3,
      instrumentNameP5          : InstrumentNameP53,
      strike                    : Sample(8),
      callPutC1                 : Sample(1),
      secondaryDate             : SecondaryDate3,
      secondaryInstrumentNameP5 : SecondaryInstrumentNameP53,
      isDeltaOption             : Sample(1) ]

EncodeContractName2(message) ==
    message.identifierPrefixI4
        \o EncodeDate3(message.date)
        \o EncodeInstrumentNameP53(message.instrumentNameP5)
        \o message.strike
        \o message.callPutC1
        \o EncodeSecondaryDate3(message.secondaryDate)
        \o EncodeSecondaryInstrumentNameP53(message.secondaryInstrumentNameP5)
        \o message.isDeltaOption

DecodeContractName2(bytes) ==
    LET identifierPrefixI4 == ReadBytes(bytes, 4) IN IF ~identifierPrefixI4.ok THEN Fail ELSE
    LET date == DecodeDate3(identifierPrefixI4.rest) IN IF ~date.ok THEN Fail ELSE
    LET instrumentNameP5 == DecodeInstrumentNameP53(date.rest) IN IF ~instrumentNameP5.ok THEN Fail ELSE
    LET strike == ReadBytes(instrumentNameP5.rest, 8) IN IF ~strike.ok THEN Fail ELSE
    LET callPutC1 == ReadBytes(strike.rest, 1) IN IF ~callPutC1.ok THEN Fail ELSE
    LET secondaryDate == DecodeSecondaryDate3(callPutC1.rest) IN IF ~secondaryDate.ok THEN Fail ELSE
    LET secondaryInstrumentNameP5 == DecodeSecondaryInstrumentNameP53(secondaryDate.rest) IN IF ~secondaryInstrumentNameP5.ok THEN Fail ELSE
    LET isDeltaOption == ReadBytes(secondaryInstrumentNameP5.rest, 1) IN IF ~isDeltaOption.ok THEN Fail ELSE
    Ok([ identifierPrefixI4        |-> identifierPrefixI4.value,
         date                      |-> date.value,
         instrumentNameP5          |-> instrumentNameP5.value,
         strike                    |-> strike.value,
         callPutC1                 |-> callPutC1.value,
         secondaryDate             |-> secondaryDate.value,
         secondaryInstrumentNameP5 |-> secondaryInstrumentNameP5.value,
         isDeltaOption             |-> isDeltaOption.value ], isDeltaOption.rest)

ZeroContractName2 ==
    [ identifierPrefixI4        |-> [i \in 1 .. 4 |-> 0],
      date                      |-> ZeroDate3,
      instrumentNameP5          |-> ZeroInstrumentNameP53,
      strike                    |-> [i \in 1 .. 8 |-> 0],
      callPutC1                 |-> [i \in 1 .. 1 |-> 0],
      secondaryDate             |-> ZeroSecondaryDate3,
      secondaryInstrumentNameP5 |-> ZeroSecondaryInstrumentNameP53,
      isDeltaOption             |-> [i \in 1 .. 1 |-> 0] ]

(* Contract Name at zero, then each field in turn at the values it is checked at *)
CheckedContractName2 ==
    { ZeroContractName2 }
        \cup { [ZeroContractName2 EXCEPT !.identifierPrefixI4 = one] : one \in Sample(4) }
        \cup { [ZeroContractName2 EXCEPT !.date = one] : one \in CheckedDate3 }
        \cup { [ZeroContractName2 EXCEPT !.instrumentNameP5 = one] : one \in CheckedInstrumentNameP53 }
        \cup { [ZeroContractName2 EXCEPT !.strike = one] : one \in Sample(8) }
        \cup { [ZeroContractName2 EXCEPT !.callPutC1 = one] : one \in Sample(1) }
        \cup { [ZeroContractName2 EXCEPT !.secondaryDate = one] : one \in CheckedSecondaryDate3 }
        \cup { [ZeroContractName2 EXCEPT !.secondaryInstrumentNameP5 = one] : one \in CheckedSecondaryInstrumentNameP53 }
        \cup { [ZeroContractName2 EXCEPT !.isDeltaOption = one] : one \in Sample(1) }

(***************************************************************************)
(* Option Contract Subscription Message: 48 bytes                          *)
(***************************************************************************)

OptionContractSubscriptionMessage ==
    [ contractName : ContractName2 ]

EncodeOptionContractSubscriptionMessage(message) ==
    EncodeContractName2(message.contractName)

DecodeOptionContractSubscriptionMessage(bytes) ==
    LET contractName == DecodeContractName2(bytes) IN IF ~contractName.ok THEN Fail ELSE
    Ok([ contractName |-> contractName.value ], contractName.rest)

ZeroOptionContractSubscriptionMessage ==
    [ contractName |-> ZeroContractName2 ]

(* Option Contract Subscription Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionContractSubscriptionMessage ==
    { ZeroOptionContractSubscriptionMessage }
        \cup { [ZeroOptionContractSubscriptionMessage EXCEPT !.contractName = one] : one \in CheckedContractName2 }

(***************************************************************************)
(* Subscribing To Indices Service Message: 1 bytes                         *)
(***************************************************************************)

SubscribingToIndicesServiceMessage ==
    [ subscribe : Sample(1) ]

EncodeSubscribingToIndicesServiceMessage(message) ==
    message.subscribe

DecodeSubscribingToIndicesServiceMessage(bytes) ==
    LET subscribe == ReadBytes(bytes, 1) IN IF ~subscribe.ok THEN Fail ELSE
    Ok([ subscribe |-> subscribe.value ], subscribe.rest)

ZeroSubscribingToIndicesServiceMessage ==
    [ subscribe |-> [i \in 1 .. 1 |-> 0] ]

(* Subscribing To Indices Service Message at zero, then each field in turn at the values it is checked at *)
CheckedSubscribingToIndicesServiceMessage ==
    { ZeroSubscribingToIndicesServiceMessage }
        \cup { [ZeroSubscribingToIndicesServiceMessage EXCEPT !.subscribe = one] : one \in Sample(1) }

(***************************************************************************)
(* Date: 12 bytes                                                          *)
(***************************************************************************)

Date4 ==
    [ year  : Sample(4),
      month : Sample(4),
      day   : Sample(4) ]

EncodeDate4(message) ==
    message.year
        \o message.month
        \o message.day

DecodeDate4(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 4) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 4) IN IF ~day.ok THEN Fail ELSE
    Ok([ year  |-> year.value,
         month |-> month.value,
         day   |-> day.value ], day.rest)

ZeroDate4 ==
    [ year  |-> [i \in 1 .. 4 |-> 0],
      month |-> [i \in 1 .. 4 |-> 0],
      day   |-> [i \in 1 .. 4 |-> 0] ]

(* Date at zero, then each field in turn at the values it is checked at *)
CheckedDate4 ==
    { ZeroDate4 }
        \cup { [ZeroDate4 EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroDate4 EXCEPT !.month = one] : one \in Sample(4) }
        \cup { [ZeroDate4 EXCEPT !.day = one] : one \in Sample(4) }

(***************************************************************************)
(* Instrument Name P 5: 5 bytes                                            *)
(***************************************************************************)

InstrumentNameP54 ==
    [ instrumentNameP5LengthByte : Sample(1),
      instrumentNameP5Characters : Sample(4) ]

EncodeInstrumentNameP54(message) ==
    message.instrumentNameP5LengthByte
        \o message.instrumentNameP5Characters

DecodeInstrumentNameP54(bytes) ==
    LET instrumentNameP5LengthByte == ReadBytes(bytes, 1) IN IF ~instrumentNameP5LengthByte.ok THEN Fail ELSE
    LET instrumentNameP5Characters == ReadBytes(instrumentNameP5LengthByte.rest, 4) IN IF ~instrumentNameP5Characters.ok THEN Fail ELSE
    Ok([ instrumentNameP5LengthByte |-> instrumentNameP5LengthByte.value,
         instrumentNameP5Characters |-> instrumentNameP5Characters.value ], instrumentNameP5Characters.rest)

ZeroInstrumentNameP54 ==
    [ instrumentNameP5LengthByte |-> [i \in 1 .. 1 |-> 0],
      instrumentNameP5Characters |-> [i \in 1 .. 4 |-> 0] ]

(* Instrument Name P 5 at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentNameP54 ==
    { ZeroInstrumentNameP54 }
        \cup { [ZeroInstrumentNameP54 EXCEPT !.instrumentNameP5LengthByte = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentNameP54 EXCEPT !.instrumentNameP5Characters = one] : one \in Sample(4) }

(***************************************************************************)
(* Secondary Date: 12 bytes                                                *)
(***************************************************************************)

SecondaryDate4 ==
    [ year  : Sample(4),
      month : Sample(4),
      day   : Sample(4) ]

EncodeSecondaryDate4(message) ==
    message.year
        \o message.month
        \o message.day

DecodeSecondaryDate4(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 4) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 4) IN IF ~day.ok THEN Fail ELSE
    Ok([ year  |-> year.value,
         month |-> month.value,
         day   |-> day.value ], day.rest)

ZeroSecondaryDate4 ==
    [ year  |-> [i \in 1 .. 4 |-> 0],
      month |-> [i \in 1 .. 4 |-> 0],
      day   |-> [i \in 1 .. 4 |-> 0] ]

(* Secondary Date at zero, then each field in turn at the values it is checked at *)
CheckedSecondaryDate4 ==
    { ZeroSecondaryDate4 }
        \cup { [ZeroSecondaryDate4 EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroSecondaryDate4 EXCEPT !.month = one] : one \in Sample(4) }
        \cup { [ZeroSecondaryDate4 EXCEPT !.day = one] : one \in Sample(4) }

(***************************************************************************)
(* Secondary Instrument Name P 5: 5 bytes                                  *)
(***************************************************************************)

SecondaryInstrumentNameP54 ==
    [ secondaryInstrumentNameP5LengthByte : Sample(1),
      secondaryInstrumentNameP5Characters : Sample(4) ]

EncodeSecondaryInstrumentNameP54(message) ==
    message.secondaryInstrumentNameP5LengthByte
        \o message.secondaryInstrumentNameP5Characters

DecodeSecondaryInstrumentNameP54(bytes) ==
    LET secondaryInstrumentNameP5LengthByte == ReadBytes(bytes, 1) IN IF ~secondaryInstrumentNameP5LengthByte.ok THEN Fail ELSE
    LET secondaryInstrumentNameP5Characters == ReadBytes(secondaryInstrumentNameP5LengthByte.rest, 4) IN IF ~secondaryInstrumentNameP5Characters.ok THEN Fail ELSE
    Ok([ secondaryInstrumentNameP5LengthByte |-> secondaryInstrumentNameP5LengthByte.value,
         secondaryInstrumentNameP5Characters |-> secondaryInstrumentNameP5Characters.value ], secondaryInstrumentNameP5Characters.rest)

ZeroSecondaryInstrumentNameP54 ==
    [ secondaryInstrumentNameP5LengthByte |-> [i \in 1 .. 1 |-> 0],
      secondaryInstrumentNameP5Characters |-> [i \in 1 .. 4 |-> 0] ]

(* Secondary Instrument Name P 5 at zero, then each field in turn at the values it is checked at *)
CheckedSecondaryInstrumentNameP54 ==
    { ZeroSecondaryInstrumentNameP54 }
        \cup { [ZeroSecondaryInstrumentNameP54 EXCEPT !.secondaryInstrumentNameP5LengthByte = one] : one \in Sample(1) }
        \cup { [ZeroSecondaryInstrumentNameP54 EXCEPT !.secondaryInstrumentNameP5Characters = one] : one \in Sample(4) }

(***************************************************************************)
(* Contract: 48 bytes                                                      *)
(***************************************************************************)

Contract2 ==
    [ identifierPrefixI4        : Sample(4),
      date                      : Date4,
      instrumentNameP5          : InstrumentNameP54,
      strike                    : Sample(8),
      callPutC1                 : Sample(1),
      secondaryDate             : SecondaryDate4,
      secondaryInstrumentNameP5 : SecondaryInstrumentNameP54,
      isDeltaOption             : Sample(1) ]

EncodeContract2(message) ==
    message.identifierPrefixI4
        \o EncodeDate4(message.date)
        \o EncodeInstrumentNameP54(message.instrumentNameP5)
        \o message.strike
        \o message.callPutC1
        \o EncodeSecondaryDate4(message.secondaryDate)
        \o EncodeSecondaryInstrumentNameP54(message.secondaryInstrumentNameP5)
        \o message.isDeltaOption

DecodeContract2(bytes) ==
    LET identifierPrefixI4 == ReadBytes(bytes, 4) IN IF ~identifierPrefixI4.ok THEN Fail ELSE
    LET date == DecodeDate4(identifierPrefixI4.rest) IN IF ~date.ok THEN Fail ELSE
    LET instrumentNameP5 == DecodeInstrumentNameP54(date.rest) IN IF ~instrumentNameP5.ok THEN Fail ELSE
    LET strike == ReadBytes(instrumentNameP5.rest, 8) IN IF ~strike.ok THEN Fail ELSE
    LET callPutC1 == ReadBytes(strike.rest, 1) IN IF ~callPutC1.ok THEN Fail ELSE
    LET secondaryDate == DecodeSecondaryDate4(callPutC1.rest) IN IF ~secondaryDate.ok THEN Fail ELSE
    LET secondaryInstrumentNameP5 == DecodeSecondaryInstrumentNameP54(secondaryDate.rest) IN IF ~secondaryInstrumentNameP5.ok THEN Fail ELSE
    LET isDeltaOption == ReadBytes(secondaryInstrumentNameP5.rest, 1) IN IF ~isDeltaOption.ok THEN Fail ELSE
    Ok([ identifierPrefixI4        |-> identifierPrefixI4.value,
         date                      |-> date.value,
         instrumentNameP5          |-> instrumentNameP5.value,
         strike                    |-> strike.value,
         callPutC1                 |-> callPutC1.value,
         secondaryDate             |-> secondaryDate.value,
         secondaryInstrumentNameP5 |-> secondaryInstrumentNameP5.value,
         isDeltaOption             |-> isDeltaOption.value ], isDeltaOption.rest)

ZeroContract2 ==
    [ identifierPrefixI4        |-> [i \in 1 .. 4 |-> 0],
      date                      |-> ZeroDate4,
      instrumentNameP5          |-> ZeroInstrumentNameP54,
      strike                    |-> [i \in 1 .. 8 |-> 0],
      callPutC1                 |-> [i \in 1 .. 1 |-> 0],
      secondaryDate             |-> ZeroSecondaryDate4,
      secondaryInstrumentNameP5 |-> ZeroSecondaryInstrumentNameP54,
      isDeltaOption             |-> [i \in 1 .. 1 |-> 0] ]

(* Contract at zero, then each field in turn at the values it is checked at *)
CheckedContract2 ==
    { ZeroContract2 }
        \cup { [ZeroContract2 EXCEPT !.identifierPrefixI4 = one] : one \in Sample(4) }
        \cup { [ZeroContract2 EXCEPT !.date = one] : one \in CheckedDate4 }
        \cup { [ZeroContract2 EXCEPT !.instrumentNameP5 = one] : one \in CheckedInstrumentNameP54 }
        \cup { [ZeroContract2 EXCEPT !.strike = one] : one \in Sample(8) }
        \cup { [ZeroContract2 EXCEPT !.callPutC1 = one] : one \in Sample(1) }
        \cup { [ZeroContract2 EXCEPT !.secondaryDate = one] : one \in CheckedSecondaryDate4 }
        \cup { [ZeroContract2 EXCEPT !.secondaryInstrumentNameP5 = one] : one \in CheckedSecondaryInstrumentNameP54 }
        \cup { [ZeroContract2 EXCEPT !.isDeltaOption = one] : one \in Sample(1) }

(***************************************************************************)
(* Contracts Requested For Display: 48 bytes                               *)
(***************************************************************************)

ContractsRequestedForDisplay ==
    [ contract : Contract2 ]

EncodeContractsRequestedForDisplay(message) ==
    EncodeContract2(message.contract)

DecodeContractsRequestedForDisplay(bytes) ==
    LET contract == DecodeContract2(bytes) IN IF ~contract.ok THEN Fail ELSE
    Ok([ contract |-> contract.value ], contract.rest)

ZeroContractsRequestedForDisplay ==
    [ contract |-> ZeroContract2 ]

(* Contracts Requested For Display at zero, then each field in turn at the values it is checked at *)
CheckedContractsRequestedForDisplay ==
    { ZeroContractsRequestedForDisplay }
        \cup { [ZeroContractsRequestedForDisplay EXCEPT !.contract = one] : one \in CheckedContract2 }

(* A run of Contracts Requested For Display, written one after another *)
RECURSIVE EncodeContractsRequestedForDisplayList(_)
EncodeContractsRequestedForDisplayList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeContractsRequestedForDisplay(Head(messages)) \o EncodeContractsRequestedForDisplayList(Tail(messages))

(* As many Contracts Requested For Display as the field that counts them says *)
RECURSIVE ReadContractsRequestedForDisplayList(_, _)
ReadContractsRequestedForDisplayList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeContractsRequestedForDisplay(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadContractsRequestedForDisplayList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Contracts Requested For Display of each kind, for the lists that carry them *)
OneContractsRequestedForDisplay == { ZeroContractsRequestedForDisplay }

(* The 40 slots a run of Contracts Requested For Display is written as, whatever the field beside it says are in use *)
SlotsContractsRequestedForDisplay == { [i \in 1 .. 40 |-> one] : one \in OneContractsRequestedForDisplay }

(***************************************************************************)
(* Future Contract Subscription Message                                    *)
(***************************************************************************)

FutureContractSubscriptionMessage ==
    [ quantityI2                   : Sample(2),
      contractsRequestedForDisplay : SlotsContractsRequestedForDisplay ]

EncodeFutureContractSubscriptionMessage(message) ==
    message.quantityI2
        \o EncodeContractsRequestedForDisplayList(message.contractsRequestedForDisplay)

DecodeFutureContractSubscriptionMessage(bytes) ==
    LET quantityI2 == ReadBytes(bytes, 2) IN IF ~quantityI2.ok THEN Fail ELSE
    LET contractsRequestedForDisplay == ReadContractsRequestedForDisplayList(quantityI2.rest, 40) IN IF ~contractsRequestedForDisplay.ok THEN Fail ELSE
    Ok([ quantityI2                   |-> quantityI2.value,
         contractsRequestedForDisplay |-> contractsRequestedForDisplay.value ], contractsRequestedForDisplay.rest)

ZeroFutureContractSubscriptionMessage ==
    [ quantityI2                   |-> [i \in 1 .. 2 |-> 0],
      contractsRequestedForDisplay |-> [i \in 1 .. 40 |-> ZeroContractsRequestedForDisplay] ]

(* Future Contract Subscription Message at zero, then each field in turn at the values it is checked at *)
CheckedFutureContractSubscriptionMessage ==
    { ZeroFutureContractSubscriptionMessage }
        \cup { [ZeroFutureContractSubscriptionMessage EXCEPT !.quantityI2 = one] : one \in Sample(2) }
        \cup { [ZeroFutureContractSubscriptionMessage EXCEPT !.contractsRequestedForDisplay = one] : one \in SlotsContractsRequestedForDisplay }

(***************************************************************************)
(* Date: 12 bytes                                                          *)
(***************************************************************************)

Date5 ==
    [ year  : Sample(4),
      month : Sample(4),
      day   : Sample(4) ]

EncodeDate5(message) ==
    message.year
        \o message.month
        \o message.day

DecodeDate5(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 4) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 4) IN IF ~day.ok THEN Fail ELSE
    Ok([ year  |-> year.value,
         month |-> month.value,
         day   |-> day.value ], day.rest)

ZeroDate5 ==
    [ year  |-> [i \in 1 .. 4 |-> 0],
      month |-> [i \in 1 .. 4 |-> 0],
      day   |-> [i \in 1 .. 4 |-> 0] ]

(* Date at zero, then each field in turn at the values it is checked at *)
CheckedDate5 ==
    { ZeroDate5 }
        \cup { [ZeroDate5 EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroDate5 EXCEPT !.month = one] : one \in Sample(4) }
        \cup { [ZeroDate5 EXCEPT !.day = one] : one \in Sample(4) }

(***************************************************************************)
(* Instrument Name P 5: 5 bytes                                            *)
(***************************************************************************)

InstrumentNameP55 ==
    [ instrumentNameP5LengthByte : Sample(1),
      instrumentNameP5Characters : Sample(4) ]

EncodeInstrumentNameP55(message) ==
    message.instrumentNameP5LengthByte
        \o message.instrumentNameP5Characters

DecodeInstrumentNameP55(bytes) ==
    LET instrumentNameP5LengthByte == ReadBytes(bytes, 1) IN IF ~instrumentNameP5LengthByte.ok THEN Fail ELSE
    LET instrumentNameP5Characters == ReadBytes(instrumentNameP5LengthByte.rest, 4) IN IF ~instrumentNameP5Characters.ok THEN Fail ELSE
    Ok([ instrumentNameP5LengthByte |-> instrumentNameP5LengthByte.value,
         instrumentNameP5Characters |-> instrumentNameP5Characters.value ], instrumentNameP5Characters.rest)

ZeroInstrumentNameP55 ==
    [ instrumentNameP5LengthByte |-> [i \in 1 .. 1 |-> 0],
      instrumentNameP5Characters |-> [i \in 1 .. 4 |-> 0] ]

(* Instrument Name P 5 at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentNameP55 ==
    { ZeroInstrumentNameP55 }
        \cup { [ZeroInstrumentNameP55 EXCEPT !.instrumentNameP5LengthByte = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentNameP55 EXCEPT !.instrumentNameP5Characters = one] : one \in Sample(4) }

(***************************************************************************)
(* Secondary Date: 12 bytes                                                *)
(***************************************************************************)

SecondaryDate5 ==
    [ year  : Sample(4),
      month : Sample(4),
      day   : Sample(4) ]

EncodeSecondaryDate5(message) ==
    message.year
        \o message.month
        \o message.day

DecodeSecondaryDate5(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 4) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 4) IN IF ~day.ok THEN Fail ELSE
    Ok([ year  |-> year.value,
         month |-> month.value,
         day   |-> day.value ], day.rest)

ZeroSecondaryDate5 ==
    [ year  |-> [i \in 1 .. 4 |-> 0],
      month |-> [i \in 1 .. 4 |-> 0],
      day   |-> [i \in 1 .. 4 |-> 0] ]

(* Secondary Date at zero, then each field in turn at the values it is checked at *)
CheckedSecondaryDate5 ==
    { ZeroSecondaryDate5 }
        \cup { [ZeroSecondaryDate5 EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroSecondaryDate5 EXCEPT !.month = one] : one \in Sample(4) }
        \cup { [ZeroSecondaryDate5 EXCEPT !.day = one] : one \in Sample(4) }

(***************************************************************************)
(* Secondary Instrument Name P 5: 5 bytes                                  *)
(***************************************************************************)

SecondaryInstrumentNameP55 ==
    [ secondaryInstrumentNameP5LengthByte : Sample(1),
      secondaryInstrumentNameP5Characters : Sample(4) ]

EncodeSecondaryInstrumentNameP55(message) ==
    message.secondaryInstrumentNameP5LengthByte
        \o message.secondaryInstrumentNameP5Characters

DecodeSecondaryInstrumentNameP55(bytes) ==
    LET secondaryInstrumentNameP5LengthByte == ReadBytes(bytes, 1) IN IF ~secondaryInstrumentNameP5LengthByte.ok THEN Fail ELSE
    LET secondaryInstrumentNameP5Characters == ReadBytes(secondaryInstrumentNameP5LengthByte.rest, 4) IN IF ~secondaryInstrumentNameP5Characters.ok THEN Fail ELSE
    Ok([ secondaryInstrumentNameP5LengthByte |-> secondaryInstrumentNameP5LengthByte.value,
         secondaryInstrumentNameP5Characters |-> secondaryInstrumentNameP5Characters.value ], secondaryInstrumentNameP5Characters.rest)

ZeroSecondaryInstrumentNameP55 ==
    [ secondaryInstrumentNameP5LengthByte |-> [i \in 1 .. 1 |-> 0],
      secondaryInstrumentNameP5Characters |-> [i \in 1 .. 4 |-> 0] ]

(* Secondary Instrument Name P 5 at zero, then each field in turn at the values it is checked at *)
CheckedSecondaryInstrumentNameP55 ==
    { ZeroSecondaryInstrumentNameP55 }
        \cup { [ZeroSecondaryInstrumentNameP55 EXCEPT !.secondaryInstrumentNameP5LengthByte = one] : one \in Sample(1) }
        \cup { [ZeroSecondaryInstrumentNameP55 EXCEPT !.secondaryInstrumentNameP5Characters = one] : one \in Sample(4) }

(***************************************************************************)
(* Contract Name: 48 bytes                                                 *)
(***************************************************************************)

ContractName3 ==
    [ identifierPrefixI4        : Sample(4),
      date                      : Date5,
      instrumentNameP5          : InstrumentNameP55,
      strike                    : Sample(8),
      callPutC1                 : Sample(1),
      secondaryDate             : SecondaryDate5,
      secondaryInstrumentNameP5 : SecondaryInstrumentNameP55,
      isDeltaOption             : Sample(1) ]

EncodeContractName3(message) ==
    message.identifierPrefixI4
        \o EncodeDate5(message.date)
        \o EncodeInstrumentNameP55(message.instrumentNameP5)
        \o message.strike
        \o message.callPutC1
        \o EncodeSecondaryDate5(message.secondaryDate)
        \o EncodeSecondaryInstrumentNameP55(message.secondaryInstrumentNameP5)
        \o message.isDeltaOption

DecodeContractName3(bytes) ==
    LET identifierPrefixI4 == ReadBytes(bytes, 4) IN IF ~identifierPrefixI4.ok THEN Fail ELSE
    LET date == DecodeDate5(identifierPrefixI4.rest) IN IF ~date.ok THEN Fail ELSE
    LET instrumentNameP5 == DecodeInstrumentNameP55(date.rest) IN IF ~instrumentNameP5.ok THEN Fail ELSE
    LET strike == ReadBytes(instrumentNameP5.rest, 8) IN IF ~strike.ok THEN Fail ELSE
    LET callPutC1 == ReadBytes(strike.rest, 1) IN IF ~callPutC1.ok THEN Fail ELSE
    LET secondaryDate == DecodeSecondaryDate5(callPutC1.rest) IN IF ~secondaryDate.ok THEN Fail ELSE
    LET secondaryInstrumentNameP5 == DecodeSecondaryInstrumentNameP55(secondaryDate.rest) IN IF ~secondaryInstrumentNameP5.ok THEN Fail ELSE
    LET isDeltaOption == ReadBytes(secondaryInstrumentNameP5.rest, 1) IN IF ~isDeltaOption.ok THEN Fail ELSE
    Ok([ identifierPrefixI4        |-> identifierPrefixI4.value,
         date                      |-> date.value,
         instrumentNameP5          |-> instrumentNameP5.value,
         strike                    |-> strike.value,
         callPutC1                 |-> callPutC1.value,
         secondaryDate             |-> secondaryDate.value,
         secondaryInstrumentNameP5 |-> secondaryInstrumentNameP5.value,
         isDeltaOption             |-> isDeltaOption.value ], isDeltaOption.rest)

ZeroContractName3 ==
    [ identifierPrefixI4        |-> [i \in 1 .. 4 |-> 0],
      date                      |-> ZeroDate5,
      instrumentNameP5          |-> ZeroInstrumentNameP55,
      strike                    |-> [i \in 1 .. 8 |-> 0],
      callPutC1                 |-> [i \in 1 .. 1 |-> 0],
      secondaryDate             |-> ZeroSecondaryDate5,
      secondaryInstrumentNameP5 |-> ZeroSecondaryInstrumentNameP55,
      isDeltaOption             |-> [i \in 1 .. 1 |-> 0] ]

(* Contract Name at zero, then each field in turn at the values it is checked at *)
CheckedContractName3 ==
    { ZeroContractName3 }
        \cup { [ZeroContractName3 EXCEPT !.identifierPrefixI4 = one] : one \in Sample(4) }
        \cup { [ZeroContractName3 EXCEPT !.date = one] : one \in CheckedDate5 }
        \cup { [ZeroContractName3 EXCEPT !.instrumentNameP5 = one] : one \in CheckedInstrumentNameP55 }
        \cup { [ZeroContractName3 EXCEPT !.strike = one] : one \in Sample(8) }
        \cup { [ZeroContractName3 EXCEPT !.callPutC1 = one] : one \in Sample(1) }
        \cup { [ZeroContractName3 EXCEPT !.secondaryDate = one] : one \in CheckedSecondaryDate5 }
        \cup { [ZeroContractName3 EXCEPT !.secondaryInstrumentNameP5 = one] : one \in CheckedSecondaryInstrumentNameP55 }
        \cup { [ZeroContractName3 EXCEPT !.isDeltaOption = one] : one \in Sample(1) }

(***************************************************************************)
(* Option Statistics Request Message: 48 bytes                             *)
(***************************************************************************)

OptionStatisticsRequestMessage ==
    [ contractName : ContractName3 ]

EncodeOptionStatisticsRequestMessage(message) ==
    EncodeContractName3(message.contractName)

DecodeOptionStatisticsRequestMessage(bytes) ==
    LET contractName == DecodeContractName3(bytes) IN IF ~contractName.ok THEN Fail ELSE
    Ok([ contractName |-> contractName.value ], contractName.rest)

ZeroOptionStatisticsRequestMessage ==
    [ contractName |-> ZeroContractName3 ]

(* Option Statistics Request Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionStatisticsRequestMessage ==
    { ZeroOptionStatisticsRequestMessage }
        \cup { [ZeroOptionStatisticsRequestMessage EXCEPT !.contractName = one] : one \in CheckedContractName3 }

(***************************************************************************)
(* Client Message Payload, selected by Client Message Type                 *)
(***************************************************************************)

LogInMessageCode == 0  \* 0x00
ReRequestMessageCode == 3  \* 0x03
LogOutMessageCode == 4  \* 0x04
RequestDataRetrievalMessageCode == 36  \* 0x24
RequestDataRetrievalMessageCode2 == 37  \* 0x25
UnsubscribeContractMessageCode == 42  \* 0x2a
RequestDailyTrendMessageCode == 61  \* 0x3d
OptionContractSubscriptionMessageCode == 67  \* 0x43
HeartBeatsMessageCode == 84  \* 0x54
SubscribingToIndicesServiceMessageCode == 98  \* 0x62
FutureContractSubscriptionMessageCode == 99  \* 0x63
OptionStatisticsRequestMessageCode == 135  \* 0x87

ClientMessagePayload ==
    [ tag : {LogInMessageCode}, body : LogInMessage ]
        \cup [ tag : {ReRequestMessageCode}, body : ReRequestMessage ]
        \cup [ tag : {LogOutMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {RequestDataRetrievalMessageCode}, body : RequestDataRetrievalMessage ]
        \cup [ tag : {RequestDataRetrievalMessageCode2}, body : RequestDataRetrievalMessage ]
        \cup [ tag : {UnsubscribeContractMessageCode}, body : UnsubscribeContractMessage ]
        \cup [ tag : {RequestDailyTrendMessageCode}, body : RequestDailyTrendMessage ]
        \cup [ tag : {OptionContractSubscriptionMessageCode}, body : OptionContractSubscriptionMessage ]
        \cup [ tag : {HeartBeatsMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {SubscribingToIndicesServiceMessageCode}, body : SubscribingToIndicesServiceMessage ]
        \cup [ tag : {FutureContractSubscriptionMessageCode}, body : FutureContractSubscriptionMessage ]
        \cup [ tag : {OptionStatisticsRequestMessageCode}, body : OptionStatisticsRequestMessage ]

EncodeClientMessagePayload(message) ==
    CASE message.tag = LogInMessageCode -> EncodeLogInMessage(message.body)
      [] message.tag = ReRequestMessageCode -> EncodeReRequestMessage(message.body)
      [] message.tag = LogOutMessageCode -> << >>
      [] message.tag = RequestDataRetrievalMessageCode -> EncodeRequestDataRetrievalMessage(message.body)
      [] message.tag = RequestDataRetrievalMessageCode2 -> EncodeRequestDataRetrievalMessage(message.body)
      [] message.tag = UnsubscribeContractMessageCode -> EncodeUnsubscribeContractMessage(message.body)
      [] message.tag = RequestDailyTrendMessageCode -> EncodeRequestDailyTrendMessage(message.body)
      [] message.tag = OptionContractSubscriptionMessageCode -> EncodeOptionContractSubscriptionMessage(message.body)
      [] message.tag = HeartBeatsMessageCode -> << >>
      [] message.tag = SubscribingToIndicesServiceMessageCode -> EncodeSubscribingToIndicesServiceMessage(message.body)
      [] message.tag = FutureContractSubscriptionMessageCode -> EncodeFutureContractSubscriptionMessage(message.body)
      [] message.tag = OptionStatisticsRequestMessageCode -> EncodeOptionStatisticsRequestMessage(message.body)

DecodeClientMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = LogInMessageCode -> DecodeLogInMessage(bytes)
              [] tag = ReRequestMessageCode -> DecodeReRequestMessage(bytes)
              [] tag = LogOutMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = RequestDataRetrievalMessageCode -> DecodeRequestDataRetrievalMessage(bytes)
              [] tag = RequestDataRetrievalMessageCode2 -> DecodeRequestDataRetrievalMessage(bytes)
              [] tag = UnsubscribeContractMessageCode -> DecodeUnsubscribeContractMessage(bytes)
              [] tag = RequestDailyTrendMessageCode -> DecodeRequestDailyTrendMessage(bytes)
              [] tag = OptionContractSubscriptionMessageCode -> DecodeOptionContractSubscriptionMessage(bytes)
              [] tag = HeartBeatsMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = SubscribingToIndicesServiceMessageCode -> DecodeSubscribingToIndicesServiceMessage(bytes)
              [] tag = FutureContractSubscriptionMessageCode -> DecodeFutureContractSubscriptionMessage(bytes)
              [] tag = OptionStatisticsRequestMessageCode -> DecodeOptionStatisticsRequestMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroClientMessagePayload == [tag |-> LogInMessageCode, body |-> ZeroLogInMessage]

(* Each Client Message Payload in turn, at the values the message it names is checked at *)
CheckedClientMessagePayload ==
    { [tag |-> LogInMessageCode, body |-> one] : one \in CheckedLogInMessage }
        \cup { [tag |-> ReRequestMessageCode, body |-> one] : one \in CheckedReRequestMessage }
        \cup { [tag |-> LogOutMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> RequestDataRetrievalMessageCode, body |-> one] : one \in CheckedRequestDataRetrievalMessage }
        \cup { [tag |-> RequestDataRetrievalMessageCode2, body |-> one] : one \in CheckedRequestDataRetrievalMessage }
        \cup { [tag |-> UnsubscribeContractMessageCode, body |-> one] : one \in CheckedUnsubscribeContractMessage }
        \cup { [tag |-> RequestDailyTrendMessageCode, body |-> one] : one \in CheckedRequestDailyTrendMessage }
        \cup { [tag |-> OptionContractSubscriptionMessageCode, body |-> one] : one \in CheckedOptionContractSubscriptionMessage }
        \cup { [tag |-> HeartBeatsMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> SubscribingToIndicesServiceMessageCode, body |-> one] : one \in CheckedSubscribingToIndicesServiceMessage }
        \cup { [tag |-> FutureContractSubscriptionMessageCode, body |-> one] : one \in CheckedFutureContractSubscriptionMessage }
        \cup { [tag |-> OptionStatisticsRequestMessageCode, body |-> one] : one \in CheckedOptionStatisticsRequestMessage }

(***************************************************************************)
(* Client Message, framed by Message Length                                *)
(***************************************************************************)

ClientMessage ==
    [ startByte            : Sample(1),
      lengthCheck          : Sample(1),
      sequenceNumber       : Sample(4),
      userName             : UserName,
      userNumber           : Sample(4),
      time                 : Time,
      clientMessagePayload : ClientMessagePayload ]

EncodeClientMessageBody(message) ==
    message.lengthCheck
        \o message.sequenceNumber
        \o EncodeUserName(message.userName)
        \o message.userNumber
        \o EncodeTime(message.time)
        \o EncodeUIntBE(message.clientMessagePayload.tag, 1)
        \o EncodeClientMessagePayload(message.clientMessagePayload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeClientMessage(message) ==
    LET body == EncodeClientMessageBody(message)
    IN  message.startByte \o EncodeUIntLE(Len(body) - 1, 2) \o body

DecodeClientMessage(bytes) ==
    LET startByte == ReadBytes(bytes, 1) IN IF ~startByte.ok THEN Fail ELSE
    LET length == ReadUIntLE(startByte.rest, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value + 1 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
    IN
    LET lengthCheck == ReadBytes(framed, 1) IN IF ~lengthCheck.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(lengthCheck.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET userName == DecodeUserName(sequenceNumber.rest) IN IF ~userName.ok THEN Fail ELSE
    LET userNumber == ReadBytes(userName.rest, 4) IN IF ~userNumber.ok THEN Fail ELSE
    LET time == DecodeTime(userNumber.rest) IN IF ~time.ok THEN Fail ELSE
    LET clientMessageType == ReadUIntBE(time.rest, 1) IN IF ~clientMessageType.ok THEN Fail ELSE
    LET clientMessagePayload == DecodeClientMessagePayload(clientMessageType.value, clientMessageType.rest) IN IF ~clientMessagePayload.ok THEN Fail ELSE
    IF clientMessagePayload.rest # << >> THEN Fail ELSE
    Ok([ startByte            |-> startByte.value,
         lengthCheck          |-> lengthCheck.value,
         sequenceNumber       |-> sequenceNumber.value,
         userName             |-> userName.value,
         userNumber           |-> userNumber.value,
         time                 |-> time.value,
         clientMessagePayload |-> clientMessagePayload.value ], beyond)

ZeroClientMessage ==
    [ startByte            |-> [i \in 1 .. 1 |-> 0],
      lengthCheck          |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber       |-> [i \in 1 .. 4 |-> 0],
      userName             |-> ZeroUserName,
      userNumber           |-> [i \in 1 .. 4 |-> 0],
      time                 |-> ZeroTime,
      clientMessagePayload |-> ZeroClientMessagePayload ]

(* Client Message at zero, then each field in turn at the values it is checked at *)
CheckedClientMessage ==
    { ZeroClientMessage }
        \cup { [ZeroClientMessage EXCEPT !.startByte = one] : one \in Sample(1) }
        \cup { [ZeroClientMessage EXCEPT !.lengthCheck = one] : one \in Sample(1) }
        \cup { [ZeroClientMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroClientMessage EXCEPT !.userName = one] : one \in CheckedUserName }
        \cup { [ZeroClientMessage EXCEPT !.userNumber = one] : one \in Sample(4) }
        \cup { [ZeroClientMessage EXCEPT !.time = one] : one \in CheckedTime }
        \cup { [ZeroClientMessage EXCEPT !.clientMessagePayload = one] : one \in CheckedClientMessagePayload }

(* A run of Client Message, written one after another *)
RECURSIVE EncodeClientMessageList(_)
EncodeClientMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeClientMessage(Head(messages)) \o EncodeClientMessageList(Tail(messages))

(* As many Client Message as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadClientMessageAll(_)
ReadClientMessageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeClientMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadClientMessageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Client Message of each kind, for the lists that carry them *)
OneClientMessage ==
    { [ZeroClientMessage EXCEPT !.clientMessagePayload = [tag |-> LogInMessageCode, body |-> ZeroLogInMessage]],
      [ZeroClientMessage EXCEPT !.clientMessagePayload = [tag |-> ReRequestMessageCode, body |-> ZeroReRequestMessage]],
      [ZeroClientMessage EXCEPT !.clientMessagePayload = [tag |-> LogOutMessageCode, body |-> [empty |-> 0]]],
      [ZeroClientMessage EXCEPT !.clientMessagePayload = [tag |-> RequestDataRetrievalMessageCode, body |-> ZeroRequestDataRetrievalMessage]],
      [ZeroClientMessage EXCEPT !.clientMessagePayload = [tag |-> RequestDataRetrievalMessageCode2, body |-> ZeroRequestDataRetrievalMessage]],
      [ZeroClientMessage EXCEPT !.clientMessagePayload = [tag |-> UnsubscribeContractMessageCode, body |-> ZeroUnsubscribeContractMessage]],
      [ZeroClientMessage EXCEPT !.clientMessagePayload = [tag |-> RequestDailyTrendMessageCode, body |-> ZeroRequestDailyTrendMessage]],
      [ZeroClientMessage EXCEPT !.clientMessagePayload = [tag |-> OptionContractSubscriptionMessageCode, body |-> ZeroOptionContractSubscriptionMessage]],
      [ZeroClientMessage EXCEPT !.clientMessagePayload = [tag |-> HeartBeatsMessageCode, body |-> [empty |-> 0]]],
      [ZeroClientMessage EXCEPT !.clientMessagePayload = [tag |-> SubscribingToIndicesServiceMessageCode, body |-> ZeroSubscribingToIndicesServiceMessage]],
      [ZeroClientMessage EXCEPT !.clientMessagePayload = [tag |-> FutureContractSubscriptionMessageCode, body |-> ZeroFutureContractSubscriptionMessage]],
      [ZeroClientMessage EXCEPT !.clientMessagePayload = [tag |-> OptionStatisticsRequestMessageCode, body |-> ZeroOptionStatisticsRequestMessage]] }

(***************************************************************************)
(* Client Packet                                                           *)
(***************************************************************************)

ClientPacket ==
    [ clientMessage : SampleLists(OneClientMessage) ]

EncodeClientPacket(message) ==
    EncodeClientMessageList(message.clientMessage)

DecodeClientPacket(bytes) ==
    LET clientMessage == ReadClientMessageAll(bytes) IN IF ~clientMessage.ok THEN Fail ELSE
    Ok([ clientMessage |-> clientMessage.value ], clientMessage.rest)

ZeroClientPacket ==
    [ clientMessage |-> << >> ]

(* Client Packet at zero, then each field in turn at the values it is checked at *)
CheckedClientPacket ==
    { ZeroClientPacket }
        \cup { [ZeroClientPacket EXCEPT !.clientMessage = one] : one \in SampleLists(OneClientMessage) }

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

(* Every User Name decodes back to what was encoded, and leaves nothing over *)
RoundTripUserName ==
    \A message \in CheckedUserName :
        LET read == DecodeUserName(EncodeUserName(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Time decodes back to what was encoded, and leaves nothing over *)
RoundTripTime ==
    \A message \in CheckedTime :
        LET read == DecodeTime(EncodeTime(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Log In Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogInMessage ==
    \A message \in CheckedLogInMessage :
        LET read == DecodeLogInMessage(EncodeLogInMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Re Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReRequestMessage ==
    \A message \in CheckedReRequestMessage :
        LET read == DecodeReRequestMessage(EncodeReRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Download Date decodes back to what was encoded, and leaves nothing over *)
RoundTripDownloadDate ==
    \A message \in CheckedDownloadDate :
        LET read == DecodeDownloadDate(EncodeDownloadDate(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Data Retrieval Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestDataRetrievalMessage ==
    \A message \in CheckedRequestDataRetrievalMessage :
        LET read == DecodeRequestDataRetrievalMessage(EncodeRequestDataRetrievalMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Date decodes back to what was encoded, and leaves nothing over *)
RoundTripDate ==
    \A message \in CheckedDate :
        LET read == DecodeDate(EncodeDate(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Name P 5 decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentNameP5 ==
    \A message \in CheckedInstrumentNameP5 :
        LET read == DecodeInstrumentNameP5(EncodeInstrumentNameP5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Secondary Date decodes back to what was encoded, and leaves nothing over *)
RoundTripSecondaryDate ==
    \A message \in CheckedSecondaryDate :
        LET read == DecodeSecondaryDate(EncodeSecondaryDate(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Secondary Instrument Name P 5 decodes back to what was encoded, and leaves nothing over *)
RoundTripSecondaryInstrumentNameP5 ==
    \A message \in CheckedSecondaryInstrumentNameP5 :
        LET read == DecodeSecondaryInstrumentNameP5(EncodeSecondaryInstrumentNameP5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Contract decodes back to what was encoded, and leaves nothing over *)
RoundTripContract ==
    \A message \in CheckedContract :
        LET read == DecodeContract(EncodeContract(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Contracts To Unsubscribe decodes back to what was encoded, and leaves nothing over *)
RoundTripContractsToUnsubscribe ==
    \A message \in CheckedContractsToUnsubscribe :
        LET read == DecodeContractsToUnsubscribe(EncodeContractsToUnsubscribe(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Unsubscribe Contract Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUnsubscribeContractMessage ==
    \A message \in CheckedUnsubscribeContractMessage :
        LET read == DecodeUnsubscribeContractMessage(EncodeUnsubscribeContractMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Date decodes back to what was encoded, and leaves nothing over *)
RoundTripDate2 ==
    \A message \in CheckedDate2 :
        LET read == DecodeDate2(EncodeDate2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Name P 5 decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentNameP52 ==
    \A message \in CheckedInstrumentNameP52 :
        LET read == DecodeInstrumentNameP52(EncodeInstrumentNameP52(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Secondary Date decodes back to what was encoded, and leaves nothing over *)
RoundTripSecondaryDate2 ==
    \A message \in CheckedSecondaryDate2 :
        LET read == DecodeSecondaryDate2(EncodeSecondaryDate2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Secondary Instrument Name P 5 decodes back to what was encoded, and leaves nothing over *)
RoundTripSecondaryInstrumentNameP52 ==
    \A message \in CheckedSecondaryInstrumentNameP52 :
        LET read == DecodeSecondaryInstrumentNameP52(EncodeSecondaryInstrumentNameP52(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Contract Name decodes back to what was encoded, and leaves nothing over *)
RoundTripContractName ==
    \A message \in CheckedContractName :
        LET read == DecodeContractName(EncodeContractName(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Daily Trend Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestDailyTrendMessage ==
    \A message \in CheckedRequestDailyTrendMessage :
        LET read == DecodeRequestDailyTrendMessage(EncodeRequestDailyTrendMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Date decodes back to what was encoded, and leaves nothing over *)
RoundTripDate3 ==
    \A message \in CheckedDate3 :
        LET read == DecodeDate3(EncodeDate3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Name P 5 decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentNameP53 ==
    \A message \in CheckedInstrumentNameP53 :
        LET read == DecodeInstrumentNameP53(EncodeInstrumentNameP53(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Secondary Date decodes back to what was encoded, and leaves nothing over *)
RoundTripSecondaryDate3 ==
    \A message \in CheckedSecondaryDate3 :
        LET read == DecodeSecondaryDate3(EncodeSecondaryDate3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Secondary Instrument Name P 5 decodes back to what was encoded, and leaves nothing over *)
RoundTripSecondaryInstrumentNameP53 ==
    \A message \in CheckedSecondaryInstrumentNameP53 :
        LET read == DecodeSecondaryInstrumentNameP53(EncodeSecondaryInstrumentNameP53(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Contract Name decodes back to what was encoded, and leaves nothing over *)
RoundTripContractName2 ==
    \A message \in CheckedContractName2 :
        LET read == DecodeContractName2(EncodeContractName2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Contract Subscription Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionContractSubscriptionMessage ==
    \A message \in CheckedOptionContractSubscriptionMessage :
        LET read == DecodeOptionContractSubscriptionMessage(EncodeOptionContractSubscriptionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Subscribing To Indices Service Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSubscribingToIndicesServiceMessage ==
    \A message \in CheckedSubscribingToIndicesServiceMessage :
        LET read == DecodeSubscribingToIndicesServiceMessage(EncodeSubscribingToIndicesServiceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Date decodes back to what was encoded, and leaves nothing over *)
RoundTripDate4 ==
    \A message \in CheckedDate4 :
        LET read == DecodeDate4(EncodeDate4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Name P 5 decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentNameP54 ==
    \A message \in CheckedInstrumentNameP54 :
        LET read == DecodeInstrumentNameP54(EncodeInstrumentNameP54(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Secondary Date decodes back to what was encoded, and leaves nothing over *)
RoundTripSecondaryDate4 ==
    \A message \in CheckedSecondaryDate4 :
        LET read == DecodeSecondaryDate4(EncodeSecondaryDate4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Secondary Instrument Name P 5 decodes back to what was encoded, and leaves nothing over *)
RoundTripSecondaryInstrumentNameP54 ==
    \A message \in CheckedSecondaryInstrumentNameP54 :
        LET read == DecodeSecondaryInstrumentNameP54(EncodeSecondaryInstrumentNameP54(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Contract decodes back to what was encoded, and leaves nothing over *)
RoundTripContract2 ==
    \A message \in CheckedContract2 :
        LET read == DecodeContract2(EncodeContract2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Contracts Requested For Display decodes back to what was encoded, and leaves nothing over *)
RoundTripContractsRequestedForDisplay ==
    \A message \in CheckedContractsRequestedForDisplay :
        LET read == DecodeContractsRequestedForDisplay(EncodeContractsRequestedForDisplay(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Contract Subscription Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureContractSubscriptionMessage ==
    \A message \in CheckedFutureContractSubscriptionMessage :
        LET read == DecodeFutureContractSubscriptionMessage(EncodeFutureContractSubscriptionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Date decodes back to what was encoded, and leaves nothing over *)
RoundTripDate5 ==
    \A message \in CheckedDate5 :
        LET read == DecodeDate5(EncodeDate5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Name P 5 decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentNameP55 ==
    \A message \in CheckedInstrumentNameP55 :
        LET read == DecodeInstrumentNameP55(EncodeInstrumentNameP55(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Secondary Date decodes back to what was encoded, and leaves nothing over *)
RoundTripSecondaryDate5 ==
    \A message \in CheckedSecondaryDate5 :
        LET read == DecodeSecondaryDate5(EncodeSecondaryDate5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Secondary Instrument Name P 5 decodes back to what was encoded, and leaves nothing over *)
RoundTripSecondaryInstrumentNameP55 ==
    \A message \in CheckedSecondaryInstrumentNameP55 :
        LET read == DecodeSecondaryInstrumentNameP55(EncodeSecondaryInstrumentNameP55(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Contract Name decodes back to what was encoded, and leaves nothing over *)
RoundTripContractName3 ==
    \A message \in CheckedContractName3 :
        LET read == DecodeContractName3(EncodeContractName3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Statistics Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionStatisticsRequestMessage ==
    \A message \in CheckedOptionStatisticsRequestMessage :
        LET read == DecodeOptionStatisticsRequestMessage(EncodeOptionStatisticsRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client Message decodes back to what was encoded, and leaves nothing over *)
RoundTripClientMessage ==
    \A message \in CheckedClientMessage :
        LET read == DecodeClientMessage(EncodeClientMessage(message))
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

(* A Client Message Payload is selected by the Client Message Type it is written under *)
SelectsClientMessagePayload ==
    \A message \in CheckedClientMessagePayload :
        LET sent == EncodeClientMessagePayload(message)
            read == DecodeClientMessagePayload(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* Message Length is written from the bytes it frames *)
FramesClientMessage ==
    \A message \in CheckedClientMessage :
        LET bytes == EncodeClientMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 2, 3)) = Len(bytes) - 4

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
