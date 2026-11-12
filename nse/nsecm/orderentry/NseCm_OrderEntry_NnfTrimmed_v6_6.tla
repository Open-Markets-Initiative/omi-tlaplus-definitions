----------------- MODULE NseCm_OrderEntry_NnfTrimmed_v6_6 ------------------
(***************************************************************************)
(* National Stock Exchange of India Ltd Order Entry v6.6                   *)
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
(* Note: Message is of no one width: each is read by its own fields, and   *)
(* since every reading of it takes at least 24 bytes off the reader the    *)
(* run ends where the data does.                                           *)
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
(* Sec Info: 12 bytes                                                      *)
(***************************************************************************)

SecInfo ==
    [ symbol : Sample(10),
      series : Sample(2) ]

EncodeSecInfo(message) ==
    message.symbol
        \o message.series

DecodeSecInfo(bytes) ==
    LET symbol == ReadBytes(bytes, 10) IN IF ~symbol.ok THEN Fail ELSE
    LET series == ReadBytes(symbol.rest, 2) IN IF ~series.ok THEN Fail ELSE
    Ok([ symbol |-> symbol.value,
         series |-> series.value ], series.rest)

ZeroSecInfo ==
    [ symbol |-> [i \in 1 .. 10 |-> 0],
      series |-> [i \in 1 .. 2 |-> 0] ]

(* Sec Info at zero, then each field in turn at the values it is checked at *)
CheckedSecInfo ==
    { ZeroSecInfo }
        \cup { [ZeroSecInfo EXCEPT !.symbol = one] : one \in Sample(10) }
        \cup { [ZeroSecInfo EXCEPT !.series = one] : one \in Sample(2) }

(***************************************************************************)
(* Order Entry Request Trimmed Message: 136 bytes                          *)
(***************************************************************************)

OrderEntryRequestTrimmedMessage ==
    [ transcode     : Sample(2),
      traderId      : Sample(4),
      secInfo       : SecInfo,
      accountNumber : Sample(10),
      bookType      : Sample(2),
      buySell       : Sample(2),
      disclosedVol  : Sample(4),
      volume        : Sample(4),
      price         : Sample(4),
      goodTillDate  : Sample(4),
      stOrderFlags  : Sample(2),
      branchId      : Sample(2),
      userId        : Sample(4),
      brokerId      : Sample(5),
      suspended     : Sample(1),
      settlor       : Sample(12),
      proClient     : Sample(2),
      nnfField      : Sample(8),
      transactionId : Sample(4),
      pan           : Sample(10),
      algoId        : Sample(4),
      reserved2     : Sample(2),
      reserved32    : Sample(32) ]

EncodeOrderEntryRequestTrimmedMessage(message) ==
    message.transcode
        \o message.traderId
        \o EncodeSecInfo(message.secInfo)
        \o message.accountNumber
        \o message.bookType
        \o message.buySell
        \o message.disclosedVol
        \o message.volume
        \o message.price
        \o message.goodTillDate
        \o message.stOrderFlags
        \o message.branchId
        \o message.userId
        \o message.brokerId
        \o message.suspended
        \o message.settlor
        \o message.proClient
        \o message.nnfField
        \o message.transactionId
        \o message.pan
        \o message.algoId
        \o message.reserved2
        \o message.reserved32

DecodeOrderEntryRequestTrimmedMessage(bytes) ==
    LET transcode == ReadBytes(bytes, 2) IN IF ~transcode.ok THEN Fail ELSE
    LET traderId == ReadBytes(transcode.rest, 4) IN IF ~traderId.ok THEN Fail ELSE
    LET secInfo == DecodeSecInfo(traderId.rest) IN IF ~secInfo.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(secInfo.rest, 10) IN IF ~accountNumber.ok THEN Fail ELSE
    LET bookType == ReadBytes(accountNumber.rest, 2) IN IF ~bookType.ok THEN Fail ELSE
    LET buySell == ReadBytes(bookType.rest, 2) IN IF ~buySell.ok THEN Fail ELSE
    LET disclosedVol == ReadBytes(buySell.rest, 4) IN IF ~disclosedVol.ok THEN Fail ELSE
    LET volume == ReadBytes(disclosedVol.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET price == ReadBytes(volume.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET goodTillDate == ReadBytes(price.rest, 4) IN IF ~goodTillDate.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(goodTillDate.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET branchId == ReadBytes(stOrderFlags.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET userId == ReadBytes(branchId.rest, 4) IN IF ~userId.ok THEN Fail ELSE
    LET brokerId == ReadBytes(userId.rest, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET suspended == ReadBytes(brokerId.rest, 1) IN IF ~suspended.ok THEN Fail ELSE
    LET settlor == ReadBytes(suspended.rest, 12) IN IF ~settlor.ok THEN Fail ELSE
    LET proClient == ReadBytes(settlor.rest, 2) IN IF ~proClient.ok THEN Fail ELSE
    LET nnfField == ReadBytes(proClient.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET transactionId == ReadBytes(nnfField.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET pan == ReadBytes(transactionId.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET algoId == ReadBytes(pan.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(algoId.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET reserved32 == ReadBytes(reserved2.rest, 32) IN IF ~reserved32.ok THEN Fail ELSE
    Ok([ transcode     |-> transcode.value,
         traderId      |-> traderId.value,
         secInfo       |-> secInfo.value,
         accountNumber |-> accountNumber.value,
         bookType      |-> bookType.value,
         buySell       |-> buySell.value,
         disclosedVol  |-> disclosedVol.value,
         volume        |-> volume.value,
         price         |-> price.value,
         goodTillDate  |-> goodTillDate.value,
         stOrderFlags  |-> stOrderFlags.value,
         branchId      |-> branchId.value,
         userId        |-> userId.value,
         brokerId      |-> brokerId.value,
         suspended     |-> suspended.value,
         settlor       |-> settlor.value,
         proClient     |-> proClient.value,
         nnfField      |-> nnfField.value,
         transactionId |-> transactionId.value,
         pan           |-> pan.value,
         algoId        |-> algoId.value,
         reserved2     |-> reserved2.value,
         reserved32    |-> reserved32.value ], reserved32.rest)

ZeroOrderEntryRequestTrimmedMessage ==
    [ transcode     |-> [i \in 1 .. 2 |-> 0],
      traderId      |-> [i \in 1 .. 4 |-> 0],
      secInfo       |-> ZeroSecInfo,
      accountNumber |-> [i \in 1 .. 10 |-> 0],
      bookType      |-> [i \in 1 .. 2 |-> 0],
      buySell       |-> [i \in 1 .. 2 |-> 0],
      disclosedVol  |-> [i \in 1 .. 4 |-> 0],
      volume        |-> [i \in 1 .. 4 |-> 0],
      price         |-> [i \in 1 .. 4 |-> 0],
      goodTillDate  |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags  |-> [i \in 1 .. 2 |-> 0],
      branchId      |-> [i \in 1 .. 2 |-> 0],
      userId        |-> [i \in 1 .. 4 |-> 0],
      brokerId      |-> [i \in 1 .. 5 |-> 0],
      suspended     |-> [i \in 1 .. 1 |-> 0],
      settlor       |-> [i \in 1 .. 12 |-> 0],
      proClient     |-> [i \in 1 .. 2 |-> 0],
      nnfField      |-> [i \in 1 .. 8 |-> 0],
      transactionId |-> [i \in 1 .. 4 |-> 0],
      pan           |-> [i \in 1 .. 10 |-> 0],
      algoId        |-> [i \in 1 .. 4 |-> 0],
      reserved2     |-> [i \in 1 .. 2 |-> 0],
      reserved32    |-> [i \in 1 .. 32 |-> 0] ]

(* Order Entry Request Trimmed Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderEntryRequestTrimmedMessage ==
    { ZeroOrderEntryRequestTrimmedMessage }
        \cup { [ZeroOrderEntryRequestTrimmedMessage EXCEPT !.transcode = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryRequestTrimmedMessage EXCEPT !.traderId = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryRequestTrimmedMessage EXCEPT !.secInfo = one] : one \in CheckedSecInfo }
        \cup { [ZeroOrderEntryRequestTrimmedMessage EXCEPT !.accountNumber = one] : one \in Sample(10) }
        \cup { [ZeroOrderEntryRequestTrimmedMessage EXCEPT !.bookType = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryRequestTrimmedMessage EXCEPT !.buySell = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryRequestTrimmedMessage EXCEPT !.disclosedVol = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryRequestTrimmedMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryRequestTrimmedMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryRequestTrimmedMessage EXCEPT !.goodTillDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryRequestTrimmedMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryRequestTrimmedMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryRequestTrimmedMessage EXCEPT !.userId = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryRequestTrimmedMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroOrderEntryRequestTrimmedMessage EXCEPT !.suspended = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryRequestTrimmedMessage EXCEPT !.settlor = one] : one \in Sample(12) }
        \cup { [ZeroOrderEntryRequestTrimmedMessage EXCEPT !.proClient = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryRequestTrimmedMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroOrderEntryRequestTrimmedMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryRequestTrimmedMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroOrderEntryRequestTrimmedMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryRequestTrimmedMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryRequestTrimmedMessage EXCEPT !.reserved32 = one] : one \in Sample(32) }

(***************************************************************************)
(* Sec Info: 12 bytes                                                      *)
(***************************************************************************)

SecInfo2 ==
    [ symbol : Sample(10),
      series : Sample(2) ]

EncodeSecInfo2(message) ==
    message.symbol
        \o message.series

DecodeSecInfo2(bytes) ==
    LET symbol == ReadBytes(bytes, 10) IN IF ~symbol.ok THEN Fail ELSE
    LET series == ReadBytes(symbol.rest, 2) IN IF ~series.ok THEN Fail ELSE
    Ok([ symbol |-> symbol.value,
         series |-> series.value ], series.rest)

ZeroSecInfo2 ==
    [ symbol |-> [i \in 1 .. 10 |-> 0],
      series |-> [i \in 1 .. 2 |-> 0] ]

(* Sec Info at zero, then each field in turn at the values it is checked at *)
CheckedSecInfo2 ==
    { ZeroSecInfo2 }
        \cup { [ZeroSecInfo2 EXCEPT !.symbol = one] : one \in Sample(10) }
        \cup { [ZeroSecInfo2 EXCEPT !.series = one] : one \in Sample(2) }

(***************************************************************************)
(* Order Modify Cancel Request Trimmed Message: 180 bytes                  *)
(***************************************************************************)

OrderModifyCancelRequestTrimmedMessage ==
    [ transactionCode       : Sample(2),
      logTime               : Sample(4),
      userId                : Sample(4),
      errorCode             : Sample(2),
      timeStamp1LongLong8   : Sample(8),
      timeStamp2            : Sample(1),
      modifiedCancelledBy   : Sample(1),
      reasonCode            : Sample(2),
      secInfo               : SecInfo2,
      orderNumber           : Sample(8),
      accountNumber         : Sample(10),
      bookType              : Sample(2),
      buySell               : Sample(2),
      disclosedVol          : Sample(4),
      disclosedVolRemaining : Sample(4),
      totalVolRemaining     : Sample(4),
      volume                : Sample(4),
      volumeFilledToday     : Sample(4),
      price                 : Sample(4),
      entryDateTime         : Sample(4),
      lastModified          : Sample(4),
      stOrderFlags          : Sample(2),
      branchId              : Sample(2),
      secondUserId          : Sample(4),
      brokerId              : Sample(5),
      suspended             : Sample(1),
      settlor               : Sample(12),
      proClient             : Sample(2),
      settlementType        : Sample(2),
      nnfField              : Sample(8),
      transactionId         : Sample(4),
      pan                   : Sample(10),
      algoId                : Sample(4),
      reserved2             : Sample(2),
      lastActivityReference : Sample(8),
      reserved24            : Sample(24) ]

EncodeOrderModifyCancelRequestTrimmedMessage(message) ==
    message.transactionCode
        \o message.logTime
        \o message.userId
        \o message.errorCode
        \o message.timeStamp1LongLong8
        \o message.timeStamp2
        \o message.modifiedCancelledBy
        \o message.reasonCode
        \o EncodeSecInfo2(message.secInfo)
        \o message.orderNumber
        \o message.accountNumber
        \o message.bookType
        \o message.buySell
        \o message.disclosedVol
        \o message.disclosedVolRemaining
        \o message.totalVolRemaining
        \o message.volume
        \o message.volumeFilledToday
        \o message.price
        \o message.entryDateTime
        \o message.lastModified
        \o message.stOrderFlags
        \o message.branchId
        \o message.secondUserId
        \o message.brokerId
        \o message.suspended
        \o message.settlor
        \o message.proClient
        \o message.settlementType
        \o message.nnfField
        \o message.transactionId
        \o message.pan
        \o message.algoId
        \o message.reserved2
        \o message.lastActivityReference
        \o message.reserved24

DecodeOrderModifyCancelRequestTrimmedMessage(bytes) ==
    LET transactionCode == ReadBytes(bytes, 2) IN IF ~transactionCode.ok THEN Fail ELSE
    LET logTime == ReadBytes(transactionCode.rest, 4) IN IF ~logTime.ok THEN Fail ELSE
    LET userId == ReadBytes(logTime.rest, 4) IN IF ~userId.ok THEN Fail ELSE
    LET errorCode == ReadBytes(userId.rest, 2) IN IF ~errorCode.ok THEN Fail ELSE
    LET timeStamp1LongLong8 == ReadBytes(errorCode.rest, 8) IN IF ~timeStamp1LongLong8.ok THEN Fail ELSE
    LET timeStamp2 == ReadBytes(timeStamp1LongLong8.rest, 1) IN IF ~timeStamp2.ok THEN Fail ELSE
    LET modifiedCancelledBy == ReadBytes(timeStamp2.rest, 1) IN IF ~modifiedCancelledBy.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(modifiedCancelledBy.rest, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET secInfo == DecodeSecInfo2(reasonCode.rest) IN IF ~secInfo.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(secInfo.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(orderNumber.rest, 10) IN IF ~accountNumber.ok THEN Fail ELSE
    LET bookType == ReadBytes(accountNumber.rest, 2) IN IF ~bookType.ok THEN Fail ELSE
    LET buySell == ReadBytes(bookType.rest, 2) IN IF ~buySell.ok THEN Fail ELSE
    LET disclosedVol == ReadBytes(buySell.rest, 4) IN IF ~disclosedVol.ok THEN Fail ELSE
    LET disclosedVolRemaining == ReadBytes(disclosedVol.rest, 4) IN IF ~disclosedVolRemaining.ok THEN Fail ELSE
    LET totalVolRemaining == ReadBytes(disclosedVolRemaining.rest, 4) IN IF ~totalVolRemaining.ok THEN Fail ELSE
    LET volume == ReadBytes(totalVolRemaining.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET volumeFilledToday == ReadBytes(volume.rest, 4) IN IF ~volumeFilledToday.ok THEN Fail ELSE
    LET price == ReadBytes(volumeFilledToday.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET entryDateTime == ReadBytes(price.rest, 4) IN IF ~entryDateTime.ok THEN Fail ELSE
    LET lastModified == ReadBytes(entryDateTime.rest, 4) IN IF ~lastModified.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(lastModified.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET branchId == ReadBytes(stOrderFlags.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET secondUserId == ReadBytes(branchId.rest, 4) IN IF ~secondUserId.ok THEN Fail ELSE
    LET brokerId == ReadBytes(secondUserId.rest, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET suspended == ReadBytes(brokerId.rest, 1) IN IF ~suspended.ok THEN Fail ELSE
    LET settlor == ReadBytes(suspended.rest, 12) IN IF ~settlor.ok THEN Fail ELSE
    LET proClient == ReadBytes(settlor.rest, 2) IN IF ~proClient.ok THEN Fail ELSE
    LET settlementType == ReadBytes(proClient.rest, 2) IN IF ~settlementType.ok THEN Fail ELSE
    LET nnfField == ReadBytes(settlementType.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET transactionId == ReadBytes(nnfField.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET pan == ReadBytes(transactionId.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET algoId == ReadBytes(pan.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(algoId.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET lastActivityReference == ReadBytes(reserved2.rest, 8) IN IF ~lastActivityReference.ok THEN Fail ELSE
    LET reserved24 == ReadBytes(lastActivityReference.rest, 24) IN IF ~reserved24.ok THEN Fail ELSE
    Ok([ transactionCode       |-> transactionCode.value,
         logTime               |-> logTime.value,
         userId                |-> userId.value,
         errorCode             |-> errorCode.value,
         timeStamp1LongLong8   |-> timeStamp1LongLong8.value,
         timeStamp2            |-> timeStamp2.value,
         modifiedCancelledBy   |-> modifiedCancelledBy.value,
         reasonCode            |-> reasonCode.value,
         secInfo               |-> secInfo.value,
         orderNumber           |-> orderNumber.value,
         accountNumber         |-> accountNumber.value,
         bookType              |-> bookType.value,
         buySell               |-> buySell.value,
         disclosedVol          |-> disclosedVol.value,
         disclosedVolRemaining |-> disclosedVolRemaining.value,
         totalVolRemaining     |-> totalVolRemaining.value,
         volume                |-> volume.value,
         volumeFilledToday     |-> volumeFilledToday.value,
         price                 |-> price.value,
         entryDateTime         |-> entryDateTime.value,
         lastModified          |-> lastModified.value,
         stOrderFlags          |-> stOrderFlags.value,
         branchId              |-> branchId.value,
         secondUserId          |-> secondUserId.value,
         brokerId              |-> brokerId.value,
         suspended             |-> suspended.value,
         settlor               |-> settlor.value,
         proClient             |-> proClient.value,
         settlementType        |-> settlementType.value,
         nnfField              |-> nnfField.value,
         transactionId         |-> transactionId.value,
         pan                   |-> pan.value,
         algoId                |-> algoId.value,
         reserved2             |-> reserved2.value,
         lastActivityReference |-> lastActivityReference.value,
         reserved24            |-> reserved24.value ], reserved24.rest)

ZeroOrderModifyCancelRequestTrimmedMessage ==
    [ transactionCode       |-> [i \in 1 .. 2 |-> 0],
      logTime               |-> [i \in 1 .. 4 |-> 0],
      userId                |-> [i \in 1 .. 4 |-> 0],
      errorCode             |-> [i \in 1 .. 2 |-> 0],
      timeStamp1LongLong8   |-> [i \in 1 .. 8 |-> 0],
      timeStamp2            |-> [i \in 1 .. 1 |-> 0],
      modifiedCancelledBy   |-> [i \in 1 .. 1 |-> 0],
      reasonCode            |-> [i \in 1 .. 2 |-> 0],
      secInfo               |-> ZeroSecInfo2,
      orderNumber           |-> [i \in 1 .. 8 |-> 0],
      accountNumber         |-> [i \in 1 .. 10 |-> 0],
      bookType              |-> [i \in 1 .. 2 |-> 0],
      buySell               |-> [i \in 1 .. 2 |-> 0],
      disclosedVol          |-> [i \in 1 .. 4 |-> 0],
      disclosedVolRemaining |-> [i \in 1 .. 4 |-> 0],
      totalVolRemaining     |-> [i \in 1 .. 4 |-> 0],
      volume                |-> [i \in 1 .. 4 |-> 0],
      volumeFilledToday     |-> [i \in 1 .. 4 |-> 0],
      price                 |-> [i \in 1 .. 4 |-> 0],
      entryDateTime         |-> [i \in 1 .. 4 |-> 0],
      lastModified          |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags          |-> [i \in 1 .. 2 |-> 0],
      branchId              |-> [i \in 1 .. 2 |-> 0],
      secondUserId          |-> [i \in 1 .. 4 |-> 0],
      brokerId              |-> [i \in 1 .. 5 |-> 0],
      suspended             |-> [i \in 1 .. 1 |-> 0],
      settlor               |-> [i \in 1 .. 12 |-> 0],
      proClient             |-> [i \in 1 .. 2 |-> 0],
      settlementType        |-> [i \in 1 .. 2 |-> 0],
      nnfField              |-> [i \in 1 .. 8 |-> 0],
      transactionId         |-> [i \in 1 .. 4 |-> 0],
      pan                   |-> [i \in 1 .. 10 |-> 0],
      algoId                |-> [i \in 1 .. 4 |-> 0],
      reserved2             |-> [i \in 1 .. 2 |-> 0],
      lastActivityReference |-> [i \in 1 .. 8 |-> 0],
      reserved24            |-> [i \in 1 .. 24 |-> 0] ]

(* Order Modify Cancel Request Trimmed Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderModifyCancelRequestTrimmedMessage ==
    { ZeroOrderModifyCancelRequestTrimmedMessage }
        \cup { [ZeroOrderModifyCancelRequestTrimmedMessage EXCEPT !.transactionCode = one] : one \in Sample(2) }
        \cup { [ZeroOrderModifyCancelRequestTrimmedMessage EXCEPT !.logTime = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyCancelRequestTrimmedMessage EXCEPT !.userId = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyCancelRequestTrimmedMessage EXCEPT !.errorCode = one] : one \in Sample(2) }
        \cup { [ZeroOrderModifyCancelRequestTrimmedMessage EXCEPT !.timeStamp1LongLong8 = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyCancelRequestTrimmedMessage EXCEPT !.timeStamp2 = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifyCancelRequestTrimmedMessage EXCEPT !.modifiedCancelledBy = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifyCancelRequestTrimmedMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroOrderModifyCancelRequestTrimmedMessage EXCEPT !.secInfo = one] : one \in CheckedSecInfo2 }
        \cup { [ZeroOrderModifyCancelRequestTrimmedMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyCancelRequestTrimmedMessage EXCEPT !.accountNumber = one] : one \in Sample(10) }
        \cup { [ZeroOrderModifyCancelRequestTrimmedMessage EXCEPT !.bookType = one] : one \in Sample(2) }
        \cup { [ZeroOrderModifyCancelRequestTrimmedMessage EXCEPT !.buySell = one] : one \in Sample(2) }
        \cup { [ZeroOrderModifyCancelRequestTrimmedMessage EXCEPT !.disclosedVol = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyCancelRequestTrimmedMessage EXCEPT !.disclosedVolRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyCancelRequestTrimmedMessage EXCEPT !.totalVolRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyCancelRequestTrimmedMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyCancelRequestTrimmedMessage EXCEPT !.volumeFilledToday = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyCancelRequestTrimmedMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyCancelRequestTrimmedMessage EXCEPT !.entryDateTime = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyCancelRequestTrimmedMessage EXCEPT !.lastModified = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyCancelRequestTrimmedMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroOrderModifyCancelRequestTrimmedMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroOrderModifyCancelRequestTrimmedMessage EXCEPT !.secondUserId = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyCancelRequestTrimmedMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroOrderModifyCancelRequestTrimmedMessage EXCEPT !.suspended = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifyCancelRequestTrimmedMessage EXCEPT !.settlor = one] : one \in Sample(12) }
        \cup { [ZeroOrderModifyCancelRequestTrimmedMessage EXCEPT !.proClient = one] : one \in Sample(2) }
        \cup { [ZeroOrderModifyCancelRequestTrimmedMessage EXCEPT !.settlementType = one] : one \in Sample(2) }
        \cup { [ZeroOrderModifyCancelRequestTrimmedMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyCancelRequestTrimmedMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyCancelRequestTrimmedMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroOrderModifyCancelRequestTrimmedMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyCancelRequestTrimmedMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderModifyCancelRequestTrimmedMessage EXCEPT !.lastActivityReference = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyCancelRequestTrimmedMessage EXCEPT !.reserved24 = one] : one \in Sample(24) }

(***************************************************************************)
(* Sec Info: 12 bytes                                                      *)
(***************************************************************************)

SecInfo3 ==
    [ symbol : Sample(10),
      series : Sample(2) ]

EncodeSecInfo3(message) ==
    message.symbol
        \o message.series

DecodeSecInfo3(bytes) ==
    LET symbol == ReadBytes(bytes, 10) IN IF ~symbol.ok THEN Fail ELSE
    LET series == ReadBytes(symbol.rest, 2) IN IF ~series.ok THEN Fail ELSE
    Ok([ symbol |-> symbol.value,
         series |-> series.value ], series.rest)

ZeroSecInfo3 ==
    [ symbol |-> [i \in 1 .. 10 |-> 0],
      series |-> [i \in 1 .. 2 |-> 0] ]

(* Sec Info at zero, then each field in turn at the values it is checked at *)
CheckedSecInfo3 ==
    { ZeroSecInfo3 }
        \cup { [ZeroSecInfo3 EXCEPT !.symbol = one] : one \in Sample(10) }
        \cup { [ZeroSecInfo3 EXCEPT !.series = one] : one \in Sample(2) }

(***************************************************************************)
(* Order Modify Cancel Response Trimmed Message: 216 bytes                 *)
(***************************************************************************)

OrderModifyCancelResponseTrimmedMessage ==
    [ transactionCode       : Sample(2),
      logTime               : Sample(4),
      userId                : Sample(4),
      errorCode             : Sample(2),
      timeStamp1LongLong8   : Sample(8),
      timeStamp2            : Sample(1),
      modifiedCancelledBy   : Sample(1),
      reasonCode            : Sample(2),
      secInfo               : SecInfo3,
      orderNumber           : Sample(8),
      accountNumber         : Sample(10),
      bookType              : Sample(2),
      buySell               : Sample(2),
      disclosedVol          : Sample(4),
      disclosedVolRemaining : Sample(4),
      totalVolRemaining     : Sample(4),
      volume                : Sample(4),
      volumeFilledToday     : Sample(4),
      price                 : Sample(4),
      entryDateTime         : Sample(4),
      lastModified          : Sample(4),
      stOrderFlags          : Sample(2),
      branchId              : Sample(2),
      secondUserId          : Sample(4),
      brokerId              : Sample(5),
      suspended             : Sample(1),
      settlor               : Sample(12),
      proClient             : Sample(2),
      settlementType        : Sample(2),
      nnfField              : Sample(8),
      transactionId         : Sample(4),
      timestamp             : Sample(8),
      pan                   : Sample(10),
      algoId                : Sample(4),
      reserved2             : Sample(2),
      lastActivityReference : Sample(8),
      reserved52            : Sample(52) ]

EncodeOrderModifyCancelResponseTrimmedMessage(message) ==
    message.transactionCode
        \o message.logTime
        \o message.userId
        \o message.errorCode
        \o message.timeStamp1LongLong8
        \o message.timeStamp2
        \o message.modifiedCancelledBy
        \o message.reasonCode
        \o EncodeSecInfo3(message.secInfo)
        \o message.orderNumber
        \o message.accountNumber
        \o message.bookType
        \o message.buySell
        \o message.disclosedVol
        \o message.disclosedVolRemaining
        \o message.totalVolRemaining
        \o message.volume
        \o message.volumeFilledToday
        \o message.price
        \o message.entryDateTime
        \o message.lastModified
        \o message.stOrderFlags
        \o message.branchId
        \o message.secondUserId
        \o message.brokerId
        \o message.suspended
        \o message.settlor
        \o message.proClient
        \o message.settlementType
        \o message.nnfField
        \o message.transactionId
        \o message.timestamp
        \o message.pan
        \o message.algoId
        \o message.reserved2
        \o message.lastActivityReference
        \o message.reserved52

DecodeOrderModifyCancelResponseTrimmedMessage(bytes) ==
    LET transactionCode == ReadBytes(bytes, 2) IN IF ~transactionCode.ok THEN Fail ELSE
    LET logTime == ReadBytes(transactionCode.rest, 4) IN IF ~logTime.ok THEN Fail ELSE
    LET userId == ReadBytes(logTime.rest, 4) IN IF ~userId.ok THEN Fail ELSE
    LET errorCode == ReadBytes(userId.rest, 2) IN IF ~errorCode.ok THEN Fail ELSE
    LET timeStamp1LongLong8 == ReadBytes(errorCode.rest, 8) IN IF ~timeStamp1LongLong8.ok THEN Fail ELSE
    LET timeStamp2 == ReadBytes(timeStamp1LongLong8.rest, 1) IN IF ~timeStamp2.ok THEN Fail ELSE
    LET modifiedCancelledBy == ReadBytes(timeStamp2.rest, 1) IN IF ~modifiedCancelledBy.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(modifiedCancelledBy.rest, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET secInfo == DecodeSecInfo3(reasonCode.rest) IN IF ~secInfo.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(secInfo.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(orderNumber.rest, 10) IN IF ~accountNumber.ok THEN Fail ELSE
    LET bookType == ReadBytes(accountNumber.rest, 2) IN IF ~bookType.ok THEN Fail ELSE
    LET buySell == ReadBytes(bookType.rest, 2) IN IF ~buySell.ok THEN Fail ELSE
    LET disclosedVol == ReadBytes(buySell.rest, 4) IN IF ~disclosedVol.ok THEN Fail ELSE
    LET disclosedVolRemaining == ReadBytes(disclosedVol.rest, 4) IN IF ~disclosedVolRemaining.ok THEN Fail ELSE
    LET totalVolRemaining == ReadBytes(disclosedVolRemaining.rest, 4) IN IF ~totalVolRemaining.ok THEN Fail ELSE
    LET volume == ReadBytes(totalVolRemaining.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET volumeFilledToday == ReadBytes(volume.rest, 4) IN IF ~volumeFilledToday.ok THEN Fail ELSE
    LET price == ReadBytes(volumeFilledToday.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET entryDateTime == ReadBytes(price.rest, 4) IN IF ~entryDateTime.ok THEN Fail ELSE
    LET lastModified == ReadBytes(entryDateTime.rest, 4) IN IF ~lastModified.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(lastModified.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET branchId == ReadBytes(stOrderFlags.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET secondUserId == ReadBytes(branchId.rest, 4) IN IF ~secondUserId.ok THEN Fail ELSE
    LET brokerId == ReadBytes(secondUserId.rest, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET suspended == ReadBytes(brokerId.rest, 1) IN IF ~suspended.ok THEN Fail ELSE
    LET settlor == ReadBytes(suspended.rest, 12) IN IF ~settlor.ok THEN Fail ELSE
    LET proClient == ReadBytes(settlor.rest, 2) IN IF ~proClient.ok THEN Fail ELSE
    LET settlementType == ReadBytes(proClient.rest, 2) IN IF ~settlementType.ok THEN Fail ELSE
    LET nnfField == ReadBytes(settlementType.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET transactionId == ReadBytes(nnfField.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET timestamp == ReadBytes(transactionId.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET pan == ReadBytes(timestamp.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET algoId == ReadBytes(pan.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(algoId.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET lastActivityReference == ReadBytes(reserved2.rest, 8) IN IF ~lastActivityReference.ok THEN Fail ELSE
    LET reserved52 == ReadBytes(lastActivityReference.rest, 52) IN IF ~reserved52.ok THEN Fail ELSE
    Ok([ transactionCode       |-> transactionCode.value,
         logTime               |-> logTime.value,
         userId                |-> userId.value,
         errorCode             |-> errorCode.value,
         timeStamp1LongLong8   |-> timeStamp1LongLong8.value,
         timeStamp2            |-> timeStamp2.value,
         modifiedCancelledBy   |-> modifiedCancelledBy.value,
         reasonCode            |-> reasonCode.value,
         secInfo               |-> secInfo.value,
         orderNumber           |-> orderNumber.value,
         accountNumber         |-> accountNumber.value,
         bookType              |-> bookType.value,
         buySell               |-> buySell.value,
         disclosedVol          |-> disclosedVol.value,
         disclosedVolRemaining |-> disclosedVolRemaining.value,
         totalVolRemaining     |-> totalVolRemaining.value,
         volume                |-> volume.value,
         volumeFilledToday     |-> volumeFilledToday.value,
         price                 |-> price.value,
         entryDateTime         |-> entryDateTime.value,
         lastModified          |-> lastModified.value,
         stOrderFlags          |-> stOrderFlags.value,
         branchId              |-> branchId.value,
         secondUserId          |-> secondUserId.value,
         brokerId              |-> brokerId.value,
         suspended             |-> suspended.value,
         settlor               |-> settlor.value,
         proClient             |-> proClient.value,
         settlementType        |-> settlementType.value,
         nnfField              |-> nnfField.value,
         transactionId         |-> transactionId.value,
         timestamp             |-> timestamp.value,
         pan                   |-> pan.value,
         algoId                |-> algoId.value,
         reserved2             |-> reserved2.value,
         lastActivityReference |-> lastActivityReference.value,
         reserved52            |-> reserved52.value ], reserved52.rest)

ZeroOrderModifyCancelResponseTrimmedMessage ==
    [ transactionCode       |-> [i \in 1 .. 2 |-> 0],
      logTime               |-> [i \in 1 .. 4 |-> 0],
      userId                |-> [i \in 1 .. 4 |-> 0],
      errorCode             |-> [i \in 1 .. 2 |-> 0],
      timeStamp1LongLong8   |-> [i \in 1 .. 8 |-> 0],
      timeStamp2            |-> [i \in 1 .. 1 |-> 0],
      modifiedCancelledBy   |-> [i \in 1 .. 1 |-> 0],
      reasonCode            |-> [i \in 1 .. 2 |-> 0],
      secInfo               |-> ZeroSecInfo3,
      orderNumber           |-> [i \in 1 .. 8 |-> 0],
      accountNumber         |-> [i \in 1 .. 10 |-> 0],
      bookType              |-> [i \in 1 .. 2 |-> 0],
      buySell               |-> [i \in 1 .. 2 |-> 0],
      disclosedVol          |-> [i \in 1 .. 4 |-> 0],
      disclosedVolRemaining |-> [i \in 1 .. 4 |-> 0],
      totalVolRemaining     |-> [i \in 1 .. 4 |-> 0],
      volume                |-> [i \in 1 .. 4 |-> 0],
      volumeFilledToday     |-> [i \in 1 .. 4 |-> 0],
      price                 |-> [i \in 1 .. 4 |-> 0],
      entryDateTime         |-> [i \in 1 .. 4 |-> 0],
      lastModified          |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags          |-> [i \in 1 .. 2 |-> 0],
      branchId              |-> [i \in 1 .. 2 |-> 0],
      secondUserId          |-> [i \in 1 .. 4 |-> 0],
      brokerId              |-> [i \in 1 .. 5 |-> 0],
      suspended             |-> [i \in 1 .. 1 |-> 0],
      settlor               |-> [i \in 1 .. 12 |-> 0],
      proClient             |-> [i \in 1 .. 2 |-> 0],
      settlementType        |-> [i \in 1 .. 2 |-> 0],
      nnfField              |-> [i \in 1 .. 8 |-> 0],
      transactionId         |-> [i \in 1 .. 4 |-> 0],
      timestamp             |-> [i \in 1 .. 8 |-> 0],
      pan                   |-> [i \in 1 .. 10 |-> 0],
      algoId                |-> [i \in 1 .. 4 |-> 0],
      reserved2             |-> [i \in 1 .. 2 |-> 0],
      lastActivityReference |-> [i \in 1 .. 8 |-> 0],
      reserved52            |-> [i \in 1 .. 52 |-> 0] ]

(* Order Modify Cancel Response Trimmed Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderModifyCancelResponseTrimmedMessage ==
    { ZeroOrderModifyCancelResponseTrimmedMessage }
        \cup { [ZeroOrderModifyCancelResponseTrimmedMessage EXCEPT !.transactionCode = one] : one \in Sample(2) }
        \cup { [ZeroOrderModifyCancelResponseTrimmedMessage EXCEPT !.logTime = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyCancelResponseTrimmedMessage EXCEPT !.userId = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyCancelResponseTrimmedMessage EXCEPT !.errorCode = one] : one \in Sample(2) }
        \cup { [ZeroOrderModifyCancelResponseTrimmedMessage EXCEPT !.timeStamp1LongLong8 = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyCancelResponseTrimmedMessage EXCEPT !.timeStamp2 = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifyCancelResponseTrimmedMessage EXCEPT !.modifiedCancelledBy = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifyCancelResponseTrimmedMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroOrderModifyCancelResponseTrimmedMessage EXCEPT !.secInfo = one] : one \in CheckedSecInfo3 }
        \cup { [ZeroOrderModifyCancelResponseTrimmedMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyCancelResponseTrimmedMessage EXCEPT !.accountNumber = one] : one \in Sample(10) }
        \cup { [ZeroOrderModifyCancelResponseTrimmedMessage EXCEPT !.bookType = one] : one \in Sample(2) }
        \cup { [ZeroOrderModifyCancelResponseTrimmedMessage EXCEPT !.buySell = one] : one \in Sample(2) }
        \cup { [ZeroOrderModifyCancelResponseTrimmedMessage EXCEPT !.disclosedVol = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyCancelResponseTrimmedMessage EXCEPT !.disclosedVolRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyCancelResponseTrimmedMessage EXCEPT !.totalVolRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyCancelResponseTrimmedMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyCancelResponseTrimmedMessage EXCEPT !.volumeFilledToday = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyCancelResponseTrimmedMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyCancelResponseTrimmedMessage EXCEPT !.entryDateTime = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyCancelResponseTrimmedMessage EXCEPT !.lastModified = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyCancelResponseTrimmedMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroOrderModifyCancelResponseTrimmedMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroOrderModifyCancelResponseTrimmedMessage EXCEPT !.secondUserId = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyCancelResponseTrimmedMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroOrderModifyCancelResponseTrimmedMessage EXCEPT !.suspended = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifyCancelResponseTrimmedMessage EXCEPT !.settlor = one] : one \in Sample(12) }
        \cup { [ZeroOrderModifyCancelResponseTrimmedMessage EXCEPT !.proClient = one] : one \in Sample(2) }
        \cup { [ZeroOrderModifyCancelResponseTrimmedMessage EXCEPT !.settlementType = one] : one \in Sample(2) }
        \cup { [ZeroOrderModifyCancelResponseTrimmedMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyCancelResponseTrimmedMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyCancelResponseTrimmedMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyCancelResponseTrimmedMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroOrderModifyCancelResponseTrimmedMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyCancelResponseTrimmedMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderModifyCancelResponseTrimmedMessage EXCEPT !.lastActivityReference = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyCancelResponseTrimmedMessage EXCEPT !.reserved52 = one] : one \in Sample(52) }

(***************************************************************************)
(* Sec Info: 12 bytes                                                      *)
(***************************************************************************)

SecInfo4 ==
    [ symbol : Sample(10),
      series : Sample(2) ]

EncodeSecInfo4(message) ==
    message.symbol
        \o message.series

DecodeSecInfo4(bytes) ==
    LET symbol == ReadBytes(bytes, 10) IN IF ~symbol.ok THEN Fail ELSE
    LET series == ReadBytes(symbol.rest, 2) IN IF ~series.ok THEN Fail ELSE
    Ok([ symbol |-> symbol.value,
         series |-> series.value ], series.rest)

ZeroSecInfo4 ==
    [ symbol |-> [i \in 1 .. 10 |-> 0],
      series |-> [i \in 1 .. 2 |-> 0] ]

(* Sec Info at zero, then each field in turn at the values it is checked at *)
CheckedSecInfo4 ==
    { ZeroSecInfo4 }
        \cup { [ZeroSecInfo4 EXCEPT !.symbol = one] : one \in Sample(10) }
        \cup { [ZeroSecInfo4 EXCEPT !.series = one] : one \in Sample(2) }

(***************************************************************************)
(* Trade Confirmation Trimmed Message: 192 bytes                           *)
(***************************************************************************)

TradeConfirmationTrimmedMessage ==
    [ transactionCode       : Sample(2),
      logTime               : Sample(4),
      userId                : Sample(4),
      timestamp             : Sample(8),
      timeStamp1Char8       : Sample(8),
      responseOrderNumber   : Sample(8),
      timeStamp2            : Sample(1),
      brokerId              : Sample(5),
      traderNum             : Sample(4),
      buySell               : Sample(2),
      accountNum            : Sample(10),
      originalVol           : Sample(4),
      disclosedVol          : Sample(4),
      remainingVol          : Sample(4),
      disclosedVolRemaining : Sample(4),
      price                 : Sample(4),
      stOrderFlags          : Sample(2),
      fillNumber            : Sample(4),
      fillQty               : Sample(4),
      fillPrice             : Sample(4),
      volFilledToday        : Sample(4),
      activityType          : Sample(2),
      activityTime          : Sample(4),
      secInfo               : SecInfo4,
      bookType              : Sample(2),
      proClient             : Sample(2),
      pan                   : Sample(10),
      algoId                : Sample(4),
      reserved2             : Sample(2),
      lastActivityReference : Sample(8),
      reserved52            : Sample(52) ]

EncodeTradeConfirmationTrimmedMessage(message) ==
    message.transactionCode
        \o message.logTime
        \o message.userId
        \o message.timestamp
        \o message.timeStamp1Char8
        \o message.responseOrderNumber
        \o message.timeStamp2
        \o message.brokerId
        \o message.traderNum
        \o message.buySell
        \o message.accountNum
        \o message.originalVol
        \o message.disclosedVol
        \o message.remainingVol
        \o message.disclosedVolRemaining
        \o message.price
        \o message.stOrderFlags
        \o message.fillNumber
        \o message.fillQty
        \o message.fillPrice
        \o message.volFilledToday
        \o message.activityType
        \o message.activityTime
        \o EncodeSecInfo4(message.secInfo)
        \o message.bookType
        \o message.proClient
        \o message.pan
        \o message.algoId
        \o message.reserved2
        \o message.lastActivityReference
        \o message.reserved52

DecodeTradeConfirmationTrimmedMessage(bytes) ==
    LET transactionCode == ReadBytes(bytes, 2) IN IF ~transactionCode.ok THEN Fail ELSE
    LET logTime == ReadBytes(transactionCode.rest, 4) IN IF ~logTime.ok THEN Fail ELSE
    LET userId == ReadBytes(logTime.rest, 4) IN IF ~userId.ok THEN Fail ELSE
    LET timestamp == ReadBytes(userId.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET timeStamp1Char8 == ReadBytes(timestamp.rest, 8) IN IF ~timeStamp1Char8.ok THEN Fail ELSE
    LET responseOrderNumber == ReadBytes(timeStamp1Char8.rest, 8) IN IF ~responseOrderNumber.ok THEN Fail ELSE
    LET timeStamp2 == ReadBytes(responseOrderNumber.rest, 1) IN IF ~timeStamp2.ok THEN Fail ELSE
    LET brokerId == ReadBytes(timeStamp2.rest, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET traderNum == ReadBytes(brokerId.rest, 4) IN IF ~traderNum.ok THEN Fail ELSE
    LET buySell == ReadBytes(traderNum.rest, 2) IN IF ~buySell.ok THEN Fail ELSE
    LET accountNum == ReadBytes(buySell.rest, 10) IN IF ~accountNum.ok THEN Fail ELSE
    LET originalVol == ReadBytes(accountNum.rest, 4) IN IF ~originalVol.ok THEN Fail ELSE
    LET disclosedVol == ReadBytes(originalVol.rest, 4) IN IF ~disclosedVol.ok THEN Fail ELSE
    LET remainingVol == ReadBytes(disclosedVol.rest, 4) IN IF ~remainingVol.ok THEN Fail ELSE
    LET disclosedVolRemaining == ReadBytes(remainingVol.rest, 4) IN IF ~disclosedVolRemaining.ok THEN Fail ELSE
    LET price == ReadBytes(disclosedVolRemaining.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(price.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET fillNumber == ReadBytes(stOrderFlags.rest, 4) IN IF ~fillNumber.ok THEN Fail ELSE
    LET fillQty == ReadBytes(fillNumber.rest, 4) IN IF ~fillQty.ok THEN Fail ELSE
    LET fillPrice == ReadBytes(fillQty.rest, 4) IN IF ~fillPrice.ok THEN Fail ELSE
    LET volFilledToday == ReadBytes(fillPrice.rest, 4) IN IF ~volFilledToday.ok THEN Fail ELSE
    LET activityType == ReadBytes(volFilledToday.rest, 2) IN IF ~activityType.ok THEN Fail ELSE
    LET activityTime == ReadBytes(activityType.rest, 4) IN IF ~activityTime.ok THEN Fail ELSE
    LET secInfo == DecodeSecInfo4(activityTime.rest) IN IF ~secInfo.ok THEN Fail ELSE
    LET bookType == ReadBytes(secInfo.rest, 2) IN IF ~bookType.ok THEN Fail ELSE
    LET proClient == ReadBytes(bookType.rest, 2) IN IF ~proClient.ok THEN Fail ELSE
    LET pan == ReadBytes(proClient.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET algoId == ReadBytes(pan.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(algoId.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET lastActivityReference == ReadBytes(reserved2.rest, 8) IN IF ~lastActivityReference.ok THEN Fail ELSE
    LET reserved52 == ReadBytes(lastActivityReference.rest, 52) IN IF ~reserved52.ok THEN Fail ELSE
    Ok([ transactionCode       |-> transactionCode.value,
         logTime               |-> logTime.value,
         userId                |-> userId.value,
         timestamp             |-> timestamp.value,
         timeStamp1Char8       |-> timeStamp1Char8.value,
         responseOrderNumber   |-> responseOrderNumber.value,
         timeStamp2            |-> timeStamp2.value,
         brokerId              |-> brokerId.value,
         traderNum             |-> traderNum.value,
         buySell               |-> buySell.value,
         accountNum            |-> accountNum.value,
         originalVol           |-> originalVol.value,
         disclosedVol          |-> disclosedVol.value,
         remainingVol          |-> remainingVol.value,
         disclosedVolRemaining |-> disclosedVolRemaining.value,
         price                 |-> price.value,
         stOrderFlags          |-> stOrderFlags.value,
         fillNumber            |-> fillNumber.value,
         fillQty               |-> fillQty.value,
         fillPrice             |-> fillPrice.value,
         volFilledToday        |-> volFilledToday.value,
         activityType          |-> activityType.value,
         activityTime          |-> activityTime.value,
         secInfo               |-> secInfo.value,
         bookType              |-> bookType.value,
         proClient             |-> proClient.value,
         pan                   |-> pan.value,
         algoId                |-> algoId.value,
         reserved2             |-> reserved2.value,
         lastActivityReference |-> lastActivityReference.value,
         reserved52            |-> reserved52.value ], reserved52.rest)

ZeroTradeConfirmationTrimmedMessage ==
    [ transactionCode       |-> [i \in 1 .. 2 |-> 0],
      logTime               |-> [i \in 1 .. 4 |-> 0],
      userId                |-> [i \in 1 .. 4 |-> 0],
      timestamp             |-> [i \in 1 .. 8 |-> 0],
      timeStamp1Char8       |-> [i \in 1 .. 8 |-> 0],
      responseOrderNumber   |-> [i \in 1 .. 8 |-> 0],
      timeStamp2            |-> [i \in 1 .. 1 |-> 0],
      brokerId              |-> [i \in 1 .. 5 |-> 0],
      traderNum             |-> [i \in 1 .. 4 |-> 0],
      buySell               |-> [i \in 1 .. 2 |-> 0],
      accountNum            |-> [i \in 1 .. 10 |-> 0],
      originalVol           |-> [i \in 1 .. 4 |-> 0],
      disclosedVol          |-> [i \in 1 .. 4 |-> 0],
      remainingVol          |-> [i \in 1 .. 4 |-> 0],
      disclosedVolRemaining |-> [i \in 1 .. 4 |-> 0],
      price                 |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags          |-> [i \in 1 .. 2 |-> 0],
      fillNumber            |-> [i \in 1 .. 4 |-> 0],
      fillQty               |-> [i \in 1 .. 4 |-> 0],
      fillPrice             |-> [i \in 1 .. 4 |-> 0],
      volFilledToday        |-> [i \in 1 .. 4 |-> 0],
      activityType          |-> [i \in 1 .. 2 |-> 0],
      activityTime          |-> [i \in 1 .. 4 |-> 0],
      secInfo               |-> ZeroSecInfo4,
      bookType              |-> [i \in 1 .. 2 |-> 0],
      proClient             |-> [i \in 1 .. 2 |-> 0],
      pan                   |-> [i \in 1 .. 10 |-> 0],
      algoId                |-> [i \in 1 .. 4 |-> 0],
      reserved2             |-> [i \in 1 .. 2 |-> 0],
      lastActivityReference |-> [i \in 1 .. 8 |-> 0],
      reserved52            |-> [i \in 1 .. 52 |-> 0] ]

(* Trade Confirmation Trimmed Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeConfirmationTrimmedMessage ==
    { ZeroTradeConfirmationTrimmedMessage }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.transactionCode = one] : one \in Sample(2) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.logTime = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.userId = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.timeStamp1Char8 = one] : one \in Sample(8) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.responseOrderNumber = one] : one \in Sample(8) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.timeStamp2 = one] : one \in Sample(1) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.traderNum = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.buySell = one] : one \in Sample(2) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.accountNum = one] : one \in Sample(10) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.originalVol = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.disclosedVol = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.remainingVol = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.disclosedVolRemaining = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.fillNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.fillQty = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.fillPrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.volFilledToday = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.activityType = one] : one \in Sample(2) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.activityTime = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.secInfo = one] : one \in CheckedSecInfo4 }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.bookType = one] : one \in Sample(2) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.proClient = one] : one \in Sample(2) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.lastActivityReference = one] : one \in Sample(8) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.reserved52 = one] : one \in Sample(52) }

(***************************************************************************)
(* Quick Acknowledgement Message: 22 bytes                                 *)
(***************************************************************************)

QuickAcknowledgementMessage ==
    [ transactionCode : Sample(2),
      traderId        : Sample(4),
      timestamp       : Sample(8),
      reference       : Sample(4),
      errorCode       : Sample(2),
      messageLength   : Sample(2) ]

EncodeQuickAcknowledgementMessage(message) ==
    message.transactionCode
        \o message.traderId
        \o message.timestamp
        \o message.reference
        \o message.errorCode
        \o message.messageLength

DecodeQuickAcknowledgementMessage(bytes) ==
    LET transactionCode == ReadBytes(bytes, 2) IN IF ~transactionCode.ok THEN Fail ELSE
    LET traderId == ReadBytes(transactionCode.rest, 4) IN IF ~traderId.ok THEN Fail ELSE
    LET timestamp == ReadBytes(traderId.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET reference == ReadBytes(timestamp.rest, 4) IN IF ~reference.ok THEN Fail ELSE
    LET errorCode == ReadBytes(reference.rest, 2) IN IF ~errorCode.ok THEN Fail ELSE
    LET messageLength == ReadBytes(errorCode.rest, 2) IN IF ~messageLength.ok THEN Fail ELSE
    Ok([ transactionCode |-> transactionCode.value,
         traderId        |-> traderId.value,
         timestamp       |-> timestamp.value,
         reference       |-> reference.value,
         errorCode       |-> errorCode.value,
         messageLength   |-> messageLength.value ], messageLength.rest)

ZeroQuickAcknowledgementMessage ==
    [ transactionCode |-> [i \in 1 .. 2 |-> 0],
      traderId        |-> [i \in 1 .. 4 |-> 0],
      timestamp       |-> [i \in 1 .. 8 |-> 0],
      reference       |-> [i \in 1 .. 4 |-> 0],
      errorCode       |-> [i \in 1 .. 2 |-> 0],
      messageLength   |-> [i \in 1 .. 2 |-> 0] ]

(* Quick Acknowledgement Message at zero, then each field in turn at the values it is checked at *)
CheckedQuickAcknowledgementMessage ==
    { ZeroQuickAcknowledgementMessage }
        \cup { [ZeroQuickAcknowledgementMessage EXCEPT !.transactionCode = one] : one \in Sample(2) }
        \cup { [ZeroQuickAcknowledgementMessage EXCEPT !.traderId = one] : one \in Sample(4) }
        \cup { [ZeroQuickAcknowledgementMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroQuickAcknowledgementMessage EXCEPT !.reference = one] : one \in Sample(4) }
        \cup { [ZeroQuickAcknowledgementMessage EXCEPT !.errorCode = one] : one \in Sample(2) }
        \cup { [ZeroQuickAcknowledgementMessage EXCEPT !.messageLength = one] : one \in Sample(2) }

(***************************************************************************)
(* Message Payload, selected by Transaction Code                           *)
(***************************************************************************)

OrderEntryRequestTrimmedMessageCode == 20000  \* 0x4e20
OrderEntryRequestTrimmedMessageCode2 == 20400  \* 0x4fb0
OrderModifyCancelRequestTrimmedMessageCode == 20040  \* 0x4e48
OrderModifyCancelRequestTrimmedMessageCode2 == 20070  \* 0x4e66
OrderModifyCancelRequestTrimmedMessageCode3 == 20402  \* 0x4fb2
OrderModifyCancelRequestTrimmedMessageCode4 == 20404  \* 0x4fb4
OrderModifyCancelResponseTrimmedMessageCode == 20012  \* 0x4e2c
OrderModifyCancelResponseTrimmedMessageCode2 == 20042  \* 0x4e4a
OrderModifyCancelResponseTrimmedMessageCode3 == 20072  \* 0x4e68
OrderModifyCancelResponseTrimmedMessageCode4 == 20073  \* 0x4e69
OrderModifyCancelResponseTrimmedMessageCode5 == 20074  \* 0x4e6a
OrderModifyCancelResponseTrimmedMessageCode6 == 20075  \* 0x4e6b
OrderModifyCancelResponseTrimmedMessageCode7 == 20231  \* 0x4f07
TradeConfirmationTrimmedMessageCode == 20222  \* 0x4efe
QuickAcknowledgementMessageCode == 20401  \* 0x4fb1
QuickAcknowledgementMessageCode2 == 20403  \* 0x4fb3
QuickAcknowledgementMessageCode3 == 20405  \* 0x4fb5

MessagePayload ==
    [ tag : {OrderEntryRequestTrimmedMessageCode}, body : OrderEntryRequestTrimmedMessage ]
        \cup [ tag : {OrderEntryRequestTrimmedMessageCode2}, body : OrderEntryRequestTrimmedMessage ]
        \cup [ tag : {OrderModifyCancelRequestTrimmedMessageCode}, body : OrderModifyCancelRequestTrimmedMessage ]
        \cup [ tag : {OrderModifyCancelRequestTrimmedMessageCode2}, body : OrderModifyCancelRequestTrimmedMessage ]
        \cup [ tag : {OrderModifyCancelRequestTrimmedMessageCode3}, body : OrderModifyCancelRequestTrimmedMessage ]
        \cup [ tag : {OrderModifyCancelRequestTrimmedMessageCode4}, body : OrderModifyCancelRequestTrimmedMessage ]
        \cup [ tag : {OrderModifyCancelResponseTrimmedMessageCode}, body : OrderModifyCancelResponseTrimmedMessage ]
        \cup [ tag : {OrderModifyCancelResponseTrimmedMessageCode2}, body : OrderModifyCancelResponseTrimmedMessage ]
        \cup [ tag : {OrderModifyCancelResponseTrimmedMessageCode3}, body : OrderModifyCancelResponseTrimmedMessage ]
        \cup [ tag : {OrderModifyCancelResponseTrimmedMessageCode4}, body : OrderModifyCancelResponseTrimmedMessage ]
        \cup [ tag : {OrderModifyCancelResponseTrimmedMessageCode5}, body : OrderModifyCancelResponseTrimmedMessage ]
        \cup [ tag : {OrderModifyCancelResponseTrimmedMessageCode6}, body : OrderModifyCancelResponseTrimmedMessage ]
        \cup [ tag : {OrderModifyCancelResponseTrimmedMessageCode7}, body : OrderModifyCancelResponseTrimmedMessage ]
        \cup [ tag : {TradeConfirmationTrimmedMessageCode}, body : TradeConfirmationTrimmedMessage ]
        \cup [ tag : {QuickAcknowledgementMessageCode}, body : QuickAcknowledgementMessage ]
        \cup [ tag : {QuickAcknowledgementMessageCode2}, body : QuickAcknowledgementMessage ]
        \cup [ tag : {QuickAcknowledgementMessageCode3}, body : QuickAcknowledgementMessage ]

EncodeMessagePayload(message) ==
    CASE message.tag = OrderEntryRequestTrimmedMessageCode -> EncodeOrderEntryRequestTrimmedMessage(message.body)
      [] message.tag = OrderEntryRequestTrimmedMessageCode2 -> EncodeOrderEntryRequestTrimmedMessage(message.body)
      [] message.tag = OrderModifyCancelRequestTrimmedMessageCode -> EncodeOrderModifyCancelRequestTrimmedMessage(message.body)
      [] message.tag = OrderModifyCancelRequestTrimmedMessageCode2 -> EncodeOrderModifyCancelRequestTrimmedMessage(message.body)
      [] message.tag = OrderModifyCancelRequestTrimmedMessageCode3 -> EncodeOrderModifyCancelRequestTrimmedMessage(message.body)
      [] message.tag = OrderModifyCancelRequestTrimmedMessageCode4 -> EncodeOrderModifyCancelRequestTrimmedMessage(message.body)
      [] message.tag = OrderModifyCancelResponseTrimmedMessageCode -> EncodeOrderModifyCancelResponseTrimmedMessage(message.body)
      [] message.tag = OrderModifyCancelResponseTrimmedMessageCode2 -> EncodeOrderModifyCancelResponseTrimmedMessage(message.body)
      [] message.tag = OrderModifyCancelResponseTrimmedMessageCode3 -> EncodeOrderModifyCancelResponseTrimmedMessage(message.body)
      [] message.tag = OrderModifyCancelResponseTrimmedMessageCode4 -> EncodeOrderModifyCancelResponseTrimmedMessage(message.body)
      [] message.tag = OrderModifyCancelResponseTrimmedMessageCode5 -> EncodeOrderModifyCancelResponseTrimmedMessage(message.body)
      [] message.tag = OrderModifyCancelResponseTrimmedMessageCode6 -> EncodeOrderModifyCancelResponseTrimmedMessage(message.body)
      [] message.tag = OrderModifyCancelResponseTrimmedMessageCode7 -> EncodeOrderModifyCancelResponseTrimmedMessage(message.body)
      [] message.tag = TradeConfirmationTrimmedMessageCode -> EncodeTradeConfirmationTrimmedMessage(message.body)
      [] message.tag = QuickAcknowledgementMessageCode -> EncodeQuickAcknowledgementMessage(message.body)
      [] message.tag = QuickAcknowledgementMessageCode2 -> EncodeQuickAcknowledgementMessage(message.body)
      [] message.tag = QuickAcknowledgementMessageCode3 -> EncodeQuickAcknowledgementMessage(message.body)

DecodeMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = OrderEntryRequestTrimmedMessageCode -> DecodeOrderEntryRequestTrimmedMessage(bytes)
              [] tag = OrderEntryRequestTrimmedMessageCode2 -> DecodeOrderEntryRequestTrimmedMessage(bytes)
              [] tag = OrderModifyCancelRequestTrimmedMessageCode -> DecodeOrderModifyCancelRequestTrimmedMessage(bytes)
              [] tag = OrderModifyCancelRequestTrimmedMessageCode2 -> DecodeOrderModifyCancelRequestTrimmedMessage(bytes)
              [] tag = OrderModifyCancelRequestTrimmedMessageCode3 -> DecodeOrderModifyCancelRequestTrimmedMessage(bytes)
              [] tag = OrderModifyCancelRequestTrimmedMessageCode4 -> DecodeOrderModifyCancelRequestTrimmedMessage(bytes)
              [] tag = OrderModifyCancelResponseTrimmedMessageCode -> DecodeOrderModifyCancelResponseTrimmedMessage(bytes)
              [] tag = OrderModifyCancelResponseTrimmedMessageCode2 -> DecodeOrderModifyCancelResponseTrimmedMessage(bytes)
              [] tag = OrderModifyCancelResponseTrimmedMessageCode3 -> DecodeOrderModifyCancelResponseTrimmedMessage(bytes)
              [] tag = OrderModifyCancelResponseTrimmedMessageCode4 -> DecodeOrderModifyCancelResponseTrimmedMessage(bytes)
              [] tag = OrderModifyCancelResponseTrimmedMessageCode5 -> DecodeOrderModifyCancelResponseTrimmedMessage(bytes)
              [] tag = OrderModifyCancelResponseTrimmedMessageCode6 -> DecodeOrderModifyCancelResponseTrimmedMessage(bytes)
              [] tag = OrderModifyCancelResponseTrimmedMessageCode7 -> DecodeOrderModifyCancelResponseTrimmedMessage(bytes)
              [] tag = TradeConfirmationTrimmedMessageCode -> DecodeTradeConfirmationTrimmedMessage(bytes)
              [] tag = QuickAcknowledgementMessageCode -> DecodeQuickAcknowledgementMessage(bytes)
              [] tag = QuickAcknowledgementMessageCode2 -> DecodeQuickAcknowledgementMessage(bytes)
              [] tag = QuickAcknowledgementMessageCode3 -> DecodeQuickAcknowledgementMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroMessagePayload == [tag |-> OrderEntryRequestTrimmedMessageCode, body |-> ZeroOrderEntryRequestTrimmedMessage]

(* Each Message Payload in turn, at the values the message it names is checked at *)
CheckedMessagePayload ==
    { [tag |-> OrderEntryRequestTrimmedMessageCode, body |-> one] : one \in CheckedOrderEntryRequestTrimmedMessage }
        \cup { [tag |-> OrderEntryRequestTrimmedMessageCode2, body |-> one] : one \in CheckedOrderEntryRequestTrimmedMessage }
        \cup { [tag |-> OrderModifyCancelRequestTrimmedMessageCode, body |-> one] : one \in CheckedOrderModifyCancelRequestTrimmedMessage }
        \cup { [tag |-> OrderModifyCancelRequestTrimmedMessageCode2, body |-> one] : one \in CheckedOrderModifyCancelRequestTrimmedMessage }
        \cup { [tag |-> OrderModifyCancelRequestTrimmedMessageCode3, body |-> one] : one \in CheckedOrderModifyCancelRequestTrimmedMessage }
        \cup { [tag |-> OrderModifyCancelRequestTrimmedMessageCode4, body |-> one] : one \in CheckedOrderModifyCancelRequestTrimmedMessage }
        \cup { [tag |-> OrderModifyCancelResponseTrimmedMessageCode, body |-> one] : one \in CheckedOrderModifyCancelResponseTrimmedMessage }
        \cup { [tag |-> OrderModifyCancelResponseTrimmedMessageCode2, body |-> one] : one \in CheckedOrderModifyCancelResponseTrimmedMessage }
        \cup { [tag |-> OrderModifyCancelResponseTrimmedMessageCode3, body |-> one] : one \in CheckedOrderModifyCancelResponseTrimmedMessage }
        \cup { [tag |-> OrderModifyCancelResponseTrimmedMessageCode4, body |-> one] : one \in CheckedOrderModifyCancelResponseTrimmedMessage }
        \cup { [tag |-> OrderModifyCancelResponseTrimmedMessageCode5, body |-> one] : one \in CheckedOrderModifyCancelResponseTrimmedMessage }
        \cup { [tag |-> OrderModifyCancelResponseTrimmedMessageCode6, body |-> one] : one \in CheckedOrderModifyCancelResponseTrimmedMessage }
        \cup { [tag |-> OrderModifyCancelResponseTrimmedMessageCode7, body |-> one] : one \in CheckedOrderModifyCancelResponseTrimmedMessage }
        \cup { [tag |-> TradeConfirmationTrimmedMessageCode, body |-> one] : one \in CheckedTradeConfirmationTrimmedMessage }
        \cup { [tag |-> QuickAcknowledgementMessageCode, body |-> one] : one \in CheckedQuickAcknowledgementMessage }
        \cup { [tag |-> QuickAcknowledgementMessageCode2, body |-> one] : one \in CheckedQuickAcknowledgementMessage }
        \cup { [tag |-> QuickAcknowledgementMessageCode3, body |-> one] : one \in CheckedQuickAcknowledgementMessage }

(***************************************************************************)
(* Message                                                                 *)
(***************************************************************************)

Message ==
    [ messagePayload : MessagePayload ]

EncodeMessage(message) ==
    EncodeUIntBE(message.messagePayload.tag, 2)
        \o EncodeMessagePayload(message.messagePayload)

DecodeMessage(bytes) ==
    LET transactionCode == ReadUIntBE(bytes, 2) IN IF ~transactionCode.ok THEN Fail ELSE
    LET messagePayload == DecodeMessagePayload(transactionCode.value, transactionCode.rest) IN IF ~messagePayload.ok THEN Fail ELSE
    Ok([ messagePayload |-> messagePayload.value ], messagePayload.rest)

ZeroMessage ==
    [ messagePayload |-> ZeroMessagePayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.messagePayload = one] : one \in CheckedMessagePayload }

(* A run of Message, written one after another *)
RECURSIVE EncodeMessageList(_)
EncodeMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMessage(Head(messages)) \o EncodeMessageList(Tail(messages))

(* As many Message as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadMessageAll(_)
ReadMessageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMessageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Message of each kind, for the lists that carry them *)
OneMessage ==
    { [ZeroMessage EXCEPT !.messagePayload = [tag |-> OrderEntryRequestTrimmedMessageCode, body |-> ZeroOrderEntryRequestTrimmedMessage]],
      [ZeroMessage EXCEPT !.messagePayload = [tag |-> OrderEntryRequestTrimmedMessageCode2, body |-> ZeroOrderEntryRequestTrimmedMessage]],
      [ZeroMessage EXCEPT !.messagePayload = [tag |-> OrderModifyCancelRequestTrimmedMessageCode, body |-> ZeroOrderModifyCancelRequestTrimmedMessage]],
      [ZeroMessage EXCEPT !.messagePayload = [tag |-> OrderModifyCancelRequestTrimmedMessageCode2, body |-> ZeroOrderModifyCancelRequestTrimmedMessage]],
      [ZeroMessage EXCEPT !.messagePayload = [tag |-> OrderModifyCancelRequestTrimmedMessageCode3, body |-> ZeroOrderModifyCancelRequestTrimmedMessage]],
      [ZeroMessage EXCEPT !.messagePayload = [tag |-> OrderModifyCancelRequestTrimmedMessageCode4, body |-> ZeroOrderModifyCancelRequestTrimmedMessage]],
      [ZeroMessage EXCEPT !.messagePayload = [tag |-> OrderModifyCancelResponseTrimmedMessageCode, body |-> ZeroOrderModifyCancelResponseTrimmedMessage]],
      [ZeroMessage EXCEPT !.messagePayload = [tag |-> OrderModifyCancelResponseTrimmedMessageCode2, body |-> ZeroOrderModifyCancelResponseTrimmedMessage]],
      [ZeroMessage EXCEPT !.messagePayload = [tag |-> OrderModifyCancelResponseTrimmedMessageCode3, body |-> ZeroOrderModifyCancelResponseTrimmedMessage]],
      [ZeroMessage EXCEPT !.messagePayload = [tag |-> OrderModifyCancelResponseTrimmedMessageCode4, body |-> ZeroOrderModifyCancelResponseTrimmedMessage]],
      [ZeroMessage EXCEPT !.messagePayload = [tag |-> OrderModifyCancelResponseTrimmedMessageCode5, body |-> ZeroOrderModifyCancelResponseTrimmedMessage]],
      [ZeroMessage EXCEPT !.messagePayload = [tag |-> OrderModifyCancelResponseTrimmedMessageCode6, body |-> ZeroOrderModifyCancelResponseTrimmedMessage]],
      [ZeroMessage EXCEPT !.messagePayload = [tag |-> OrderModifyCancelResponseTrimmedMessageCode7, body |-> ZeroOrderModifyCancelResponseTrimmedMessage]],
      [ZeroMessage EXCEPT !.messagePayload = [tag |-> TradeConfirmationTrimmedMessageCode, body |-> ZeroTradeConfirmationTrimmedMessage]],
      [ZeroMessage EXCEPT !.messagePayload = [tag |-> QuickAcknowledgementMessageCode, body |-> ZeroQuickAcknowledgementMessage]],
      [ZeroMessage EXCEPT !.messagePayload = [tag |-> QuickAcknowledgementMessageCode2, body |-> ZeroQuickAcknowledgementMessage]],
      [ZeroMessage EXCEPT !.messagePayload = [tag |-> QuickAcknowledgementMessageCode3, body |-> ZeroQuickAcknowledgementMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ message : SampleLists(OneMessage) ]

EncodePacket(message) ==
    EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET message == ReadMessageAll(bytes) IN IF ~message.ok THEN Fail ELSE
    Ok([ message |-> message.value ], message.rest)

ZeroPacket ==
    [ message |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.message = one] : one \in SampleLists(OneMessage) }

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

(* Every Sec Info decodes back to what was encoded, and leaves nothing over *)
RoundTripSecInfo ==
    \A message \in CheckedSecInfo :
        LET read == DecodeSecInfo(EncodeSecInfo(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Entry Request Trimmed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderEntryRequestTrimmedMessage ==
    \A message \in CheckedOrderEntryRequestTrimmedMessage :
        LET read == DecodeOrderEntryRequestTrimmedMessage(EncodeOrderEntryRequestTrimmedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sec Info decodes back to what was encoded, and leaves nothing over *)
RoundTripSecInfo2 ==
    \A message \in CheckedSecInfo2 :
        LET read == DecodeSecInfo2(EncodeSecInfo2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Modify Cancel Request Trimmed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderModifyCancelRequestTrimmedMessage ==
    \A message \in CheckedOrderModifyCancelRequestTrimmedMessage :
        LET read == DecodeOrderModifyCancelRequestTrimmedMessage(EncodeOrderModifyCancelRequestTrimmedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sec Info decodes back to what was encoded, and leaves nothing over *)
RoundTripSecInfo3 ==
    \A message \in CheckedSecInfo3 :
        LET read == DecodeSecInfo3(EncodeSecInfo3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Modify Cancel Response Trimmed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderModifyCancelResponseTrimmedMessage ==
    \A message \in CheckedOrderModifyCancelResponseTrimmedMessage :
        LET read == DecodeOrderModifyCancelResponseTrimmedMessage(EncodeOrderModifyCancelResponseTrimmedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sec Info decodes back to what was encoded, and leaves nothing over *)
RoundTripSecInfo4 ==
    \A message \in CheckedSecInfo4 :
        LET read == DecodeSecInfo4(EncodeSecInfo4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Confirmation Trimmed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeConfirmationTrimmedMessage ==
    \A message \in CheckedTradeConfirmationTrimmedMessage :
        LET read == DecodeTradeConfirmationTrimmedMessage(EncodeTradeConfirmationTrimmedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quick Acknowledgement Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuickAcknowledgementMessage ==
    \A message \in CheckedQuickAcknowledgementMessage :
        LET read == DecodeQuickAcknowledgementMessage(EncodeQuickAcknowledgementMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMessage ==
    \A message \in CheckedMessage :
        LET read == DecodeMessage(EncodeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripPacket ==
    \A message \in CheckedPacket :
        LET read == DecodePacket(EncodePacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Message Payload is selected by the Transaction Code it is written under *)
SelectsMessagePayload ==
    \A message \in CheckedMessagePayload :
        LET sent == EncodeMessagePayload(message)
            read == DecodeMessagePayload(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
