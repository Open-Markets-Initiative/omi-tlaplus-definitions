-------------------- MODULE NseCom_DropCopy_v1_5_Server --------------------
(***************************************************************************)
(* National Stock Exchange of India Ltd Drop Copy v1.5                     *)
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
(* Note: St Order Flags is a bit field set, checked as its 2 bytes rather  *)
(* than bit by bit.                                                        *)
(*                                                                         *)
(* Note: Additional Order Flags is a bit field set, checked as its 1 byte  *)
(* rather than bit by bit.                                                 *)
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
(* Sign On Out Message: 238 bytes                                          *)
(***************************************************************************)

SignOnOutMessage ==
    [ userId           : Sample(4),
      reserved8        : Sample(8),
      password         : Sample(8),
      secondReserved8  : Sample(8),
      reserved38       : Sample(38),
      brokerId         : Sample(5),
      reserved119      : Sample(119),
      reserved16       : Sample(16),
      secondReserved16 : Sample(16),
      thirdReserved16  : Sample(16) ]

EncodeSignOnOutMessage(message) ==
    message.userId
        \o message.reserved8
        \o message.password
        \o message.secondReserved8
        \o message.reserved38
        \o message.brokerId
        \o message.reserved119
        \o message.reserved16
        \o message.secondReserved16
        \o message.thirdReserved16

DecodeSignOnOutMessage(bytes) ==
    LET userId == ReadBytes(bytes, 4) IN IF ~userId.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(userId.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    LET password == ReadBytes(reserved8.rest, 8) IN IF ~password.ok THEN Fail ELSE
    LET secondReserved8 == ReadBytes(password.rest, 8) IN IF ~secondReserved8.ok THEN Fail ELSE
    LET reserved38 == ReadBytes(secondReserved8.rest, 38) IN IF ~reserved38.ok THEN Fail ELSE
    LET brokerId == ReadBytes(reserved38.rest, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET reserved119 == ReadBytes(brokerId.rest, 119) IN IF ~reserved119.ok THEN Fail ELSE
    LET reserved16 == ReadBytes(reserved119.rest, 16) IN IF ~reserved16.ok THEN Fail ELSE
    LET secondReserved16 == ReadBytes(reserved16.rest, 16) IN IF ~secondReserved16.ok THEN Fail ELSE
    LET thirdReserved16 == ReadBytes(secondReserved16.rest, 16) IN IF ~thirdReserved16.ok THEN Fail ELSE
    Ok([ userId           |-> userId.value,
         reserved8        |-> reserved8.value,
         password         |-> password.value,
         secondReserved8  |-> secondReserved8.value,
         reserved38       |-> reserved38.value,
         brokerId         |-> brokerId.value,
         reserved119      |-> reserved119.value,
         reserved16       |-> reserved16.value,
         secondReserved16 |-> secondReserved16.value,
         thirdReserved16  |-> thirdReserved16.value ], thirdReserved16.rest)

ZeroSignOnOutMessage ==
    [ userId           |-> [i \in 1 .. 4 |-> 0],
      reserved8        |-> [i \in 1 .. 8 |-> 0],
      password         |-> [i \in 1 .. 8 |-> 0],
      secondReserved8  |-> [i \in 1 .. 8 |-> 0],
      reserved38       |-> [i \in 1 .. 38 |-> 0],
      brokerId         |-> [i \in 1 .. 5 |-> 0],
      reserved119      |-> [i \in 1 .. 119 |-> 0],
      reserved16       |-> [i \in 1 .. 16 |-> 0],
      secondReserved16 |-> [i \in 1 .. 16 |-> 0],
      thirdReserved16  |-> [i \in 1 .. 16 |-> 0] ]

(* Sign On Out Message at zero, then each field in turn at the values it is checked at *)
CheckedSignOnOutMessage ==
    { ZeroSignOnOutMessage }
        \cup { [ZeroSignOnOutMessage EXCEPT !.userId = one] : one \in Sample(4) }
        \cup { [ZeroSignOnOutMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }
        \cup { [ZeroSignOnOutMessage EXCEPT !.password = one] : one \in Sample(8) }
        \cup { [ZeroSignOnOutMessage EXCEPT !.secondReserved8 = one] : one \in Sample(8) }
        \cup { [ZeroSignOnOutMessage EXCEPT !.reserved38 = one] : one \in Sample(38) }
        \cup { [ZeroSignOnOutMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroSignOnOutMessage EXCEPT !.reserved119 = one] : one \in Sample(119) }
        \cup { [ZeroSignOnOutMessage EXCEPT !.reserved16 = one] : one \in Sample(16) }
        \cup { [ZeroSignOnOutMessage EXCEPT !.secondReserved16 = one] : one \in Sample(16) }
        \cup { [ZeroSignOnOutMessage EXCEPT !.thirdReserved16 = one] : one \in Sample(16) }

(***************************************************************************)
(* Contract Desc: 28 bytes                                                 *)
(***************************************************************************)

ContractDesc ==
    [ instrumentName : Sample(6),
      symbol         : Sample(10),
      expiryDate     : Sample(4),
      strikePrice    : Sample(4),
      optionType     : Sample(2),
      caLevel        : Sample(2) ]

EncodeContractDesc(message) ==
    message.instrumentName
        \o message.symbol
        \o message.expiryDate
        \o message.strikePrice
        \o message.optionType
        \o message.caLevel

DecodeContractDesc(bytes) ==
    LET instrumentName == ReadBytes(bytes, 6) IN IF ~instrumentName.ok THEN Fail ELSE
    LET symbol == ReadBytes(instrumentName.rest, 10) IN IF ~symbol.ok THEN Fail ELSE
    LET expiryDate == ReadBytes(symbol.rest, 4) IN IF ~expiryDate.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(expiryDate.rest, 4) IN IF ~strikePrice.ok THEN Fail ELSE
    LET optionType == ReadBytes(strikePrice.rest, 2) IN IF ~optionType.ok THEN Fail ELSE
    LET caLevel == ReadBytes(optionType.rest, 2) IN IF ~caLevel.ok THEN Fail ELSE
    Ok([ instrumentName |-> instrumentName.value,
         symbol         |-> symbol.value,
         expiryDate     |-> expiryDate.value,
         strikePrice    |-> strikePrice.value,
         optionType     |-> optionType.value,
         caLevel        |-> caLevel.value ], caLevel.rest)

ZeroContractDesc ==
    [ instrumentName |-> [i \in 1 .. 6 |-> 0],
      symbol         |-> [i \in 1 .. 10 |-> 0],
      expiryDate     |-> [i \in 1 .. 4 |-> 0],
      strikePrice    |-> [i \in 1 .. 4 |-> 0],
      optionType     |-> [i \in 1 .. 2 |-> 0],
      caLevel        |-> [i \in 1 .. 2 |-> 0] ]

(* Contract Desc at zero, then each field in turn at the values it is checked at *)
CheckedContractDesc ==
    { ZeroContractDesc }
        \cup { [ZeroContractDesc EXCEPT !.instrumentName = one] : one \in Sample(6) }
        \cup { [ZeroContractDesc EXCEPT !.symbol = one] : one \in Sample(10) }
        \cup { [ZeroContractDesc EXCEPT !.expiryDate = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc EXCEPT !.optionType = one] : one \in Sample(2) }
        \cup { [ZeroContractDesc EXCEPT !.caLevel = one] : one \in Sample(2) }

(***************************************************************************)
(* Trade Confirmation Message: 256 bytes                                   *)
(***************************************************************************)

TradeConfirmationMessage ==
    [ responseOrderNumber   : Sample(8),
      brokerId              : Sample(5),
      reserved1             : Sample(1),
      traderNum             : Sample(4),
      accountNum            : Sample(10),
      buySell               : Sample(2),
      originalVol           : Sample(4),
      disclosedVol          : Sample(4),
      remainingVol          : Sample(4),
      disclosedVolRemaining : Sample(4),
      price                 : Sample(4),
      stOrderFlags          : Sample(2),
      gtd                   : Sample(4),
      fillNumber            : Sample(4),
      fillQty               : Sample(4),
      fillPrice             : Sample(4),
      volFilledToday        : Sample(4),
      activityType          : Sample(2),
      activityTime          : Sample(4),
      opOrderNumber         : Sample(8),
      opBrokerId            : Sample(5),
      secondReserved1       : Sample(1),
      token                 : Sample(4),
      contractDesc          : ContractDesc,
      openClose             : Sample(1),
      oldOpenClose          : Sample(1),
      bookTypeChar1         : Sample(1),
      thirdReserved1        : Sample(1),
      newVolume             : Sample(4),
      oldAccountNumber      : Sample(10),
      participant           : Sample(12),
      oldParticipant        : Sample(12),
      additionalOrderFlags  : Sample(1),
      fourthReserved1       : Sample(1),
      giveUpTrade           : Sample(1),
      fifthReserved1        : Sample(1),
      pan                   : Sample(10),
      oldPan                : Sample(10),
      algoId                : Sample(4),
      reserved2             : Sample(2),
      lastActivityReference : Sample(8),
      nnfField              : Sample(8),
      reserved44            : Sample(44) ]

EncodeTradeConfirmationMessage(message) ==
    message.responseOrderNumber
        \o message.brokerId
        \o message.reserved1
        \o message.traderNum
        \o message.accountNum
        \o message.buySell
        \o message.originalVol
        \o message.disclosedVol
        \o message.remainingVol
        \o message.disclosedVolRemaining
        \o message.price
        \o message.stOrderFlags
        \o message.gtd
        \o message.fillNumber
        \o message.fillQty
        \o message.fillPrice
        \o message.volFilledToday
        \o message.activityType
        \o message.activityTime
        \o message.opOrderNumber
        \o message.opBrokerId
        \o message.secondReserved1
        \o message.token
        \o EncodeContractDesc(message.contractDesc)
        \o message.openClose
        \o message.oldOpenClose
        \o message.bookTypeChar1
        \o message.thirdReserved1
        \o message.newVolume
        \o message.oldAccountNumber
        \o message.participant
        \o message.oldParticipant
        \o message.additionalOrderFlags
        \o message.fourthReserved1
        \o message.giveUpTrade
        \o message.fifthReserved1
        \o message.pan
        \o message.oldPan
        \o message.algoId
        \o message.reserved2
        \o message.lastActivityReference
        \o message.nnfField
        \o message.reserved44

DecodeTradeConfirmationMessage(bytes) ==
    LET responseOrderNumber == ReadBytes(bytes, 8) IN IF ~responseOrderNumber.ok THEN Fail ELSE
    LET brokerId == ReadBytes(responseOrderNumber.rest, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(brokerId.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET traderNum == ReadBytes(reserved1.rest, 4) IN IF ~traderNum.ok THEN Fail ELSE
    LET accountNum == ReadBytes(traderNum.rest, 10) IN IF ~accountNum.ok THEN Fail ELSE
    LET buySell == ReadBytes(accountNum.rest, 2) IN IF ~buySell.ok THEN Fail ELSE
    LET originalVol == ReadBytes(buySell.rest, 4) IN IF ~originalVol.ok THEN Fail ELSE
    LET disclosedVol == ReadBytes(originalVol.rest, 4) IN IF ~disclosedVol.ok THEN Fail ELSE
    LET remainingVol == ReadBytes(disclosedVol.rest, 4) IN IF ~remainingVol.ok THEN Fail ELSE
    LET disclosedVolRemaining == ReadBytes(remainingVol.rest, 4) IN IF ~disclosedVolRemaining.ok THEN Fail ELSE
    LET price == ReadBytes(disclosedVolRemaining.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(price.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET gtd == ReadBytes(stOrderFlags.rest, 4) IN IF ~gtd.ok THEN Fail ELSE
    LET fillNumber == ReadBytes(gtd.rest, 4) IN IF ~fillNumber.ok THEN Fail ELSE
    LET fillQty == ReadBytes(fillNumber.rest, 4) IN IF ~fillQty.ok THEN Fail ELSE
    LET fillPrice == ReadBytes(fillQty.rest, 4) IN IF ~fillPrice.ok THEN Fail ELSE
    LET volFilledToday == ReadBytes(fillPrice.rest, 4) IN IF ~volFilledToday.ok THEN Fail ELSE
    LET activityType == ReadBytes(volFilledToday.rest, 2) IN IF ~activityType.ok THEN Fail ELSE
    LET activityTime == ReadBytes(activityType.rest, 4) IN IF ~activityTime.ok THEN Fail ELSE
    LET opOrderNumber == ReadBytes(activityTime.rest, 8) IN IF ~opOrderNumber.ok THEN Fail ELSE
    LET opBrokerId == ReadBytes(opOrderNumber.rest, 5) IN IF ~opBrokerId.ok THEN Fail ELSE
    LET secondReserved1 == ReadBytes(opBrokerId.rest, 1) IN IF ~secondReserved1.ok THEN Fail ELSE
    LET token == ReadBytes(secondReserved1.rest, 4) IN IF ~token.ok THEN Fail ELSE
    LET contractDesc == DecodeContractDesc(token.rest) IN IF ~contractDesc.ok THEN Fail ELSE
    LET openClose == ReadBytes(contractDesc.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET oldOpenClose == ReadBytes(openClose.rest, 1) IN IF ~oldOpenClose.ok THEN Fail ELSE
    LET bookTypeChar1 == ReadBytes(oldOpenClose.rest, 1) IN IF ~bookTypeChar1.ok THEN Fail ELSE
    LET thirdReserved1 == ReadBytes(bookTypeChar1.rest, 1) IN IF ~thirdReserved1.ok THEN Fail ELSE
    LET newVolume == ReadBytes(thirdReserved1.rest, 4) IN IF ~newVolume.ok THEN Fail ELSE
    LET oldAccountNumber == ReadBytes(newVolume.rest, 10) IN IF ~oldAccountNumber.ok THEN Fail ELSE
    LET participant == ReadBytes(oldAccountNumber.rest, 12) IN IF ~participant.ok THEN Fail ELSE
    LET oldParticipant == ReadBytes(participant.rest, 12) IN IF ~oldParticipant.ok THEN Fail ELSE
    LET additionalOrderFlags == ReadBytes(oldParticipant.rest, 1) IN IF ~additionalOrderFlags.ok THEN Fail ELSE
    LET fourthReserved1 == ReadBytes(additionalOrderFlags.rest, 1) IN IF ~fourthReserved1.ok THEN Fail ELSE
    LET giveUpTrade == ReadBytes(fourthReserved1.rest, 1) IN IF ~giveUpTrade.ok THEN Fail ELSE
    LET fifthReserved1 == ReadBytes(giveUpTrade.rest, 1) IN IF ~fifthReserved1.ok THEN Fail ELSE
    LET pan == ReadBytes(fifthReserved1.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET oldPan == ReadBytes(pan.rest, 10) IN IF ~oldPan.ok THEN Fail ELSE
    LET algoId == ReadBytes(oldPan.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(algoId.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET lastActivityReference == ReadBytes(reserved2.rest, 8) IN IF ~lastActivityReference.ok THEN Fail ELSE
    LET nnfField == ReadBytes(lastActivityReference.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET reserved44 == ReadBytes(nnfField.rest, 44) IN IF ~reserved44.ok THEN Fail ELSE
    Ok([ responseOrderNumber   |-> responseOrderNumber.value,
         brokerId              |-> brokerId.value,
         reserved1             |-> reserved1.value,
         traderNum             |-> traderNum.value,
         accountNum            |-> accountNum.value,
         buySell               |-> buySell.value,
         originalVol           |-> originalVol.value,
         disclosedVol          |-> disclosedVol.value,
         remainingVol          |-> remainingVol.value,
         disclosedVolRemaining |-> disclosedVolRemaining.value,
         price                 |-> price.value,
         stOrderFlags          |-> stOrderFlags.value,
         gtd                   |-> gtd.value,
         fillNumber            |-> fillNumber.value,
         fillQty               |-> fillQty.value,
         fillPrice             |-> fillPrice.value,
         volFilledToday        |-> volFilledToday.value,
         activityType          |-> activityType.value,
         activityTime          |-> activityTime.value,
         opOrderNumber         |-> opOrderNumber.value,
         opBrokerId            |-> opBrokerId.value,
         secondReserved1       |-> secondReserved1.value,
         token                 |-> token.value,
         contractDesc          |-> contractDesc.value,
         openClose             |-> openClose.value,
         oldOpenClose          |-> oldOpenClose.value,
         bookTypeChar1         |-> bookTypeChar1.value,
         thirdReserved1        |-> thirdReserved1.value,
         newVolume             |-> newVolume.value,
         oldAccountNumber      |-> oldAccountNumber.value,
         participant           |-> participant.value,
         oldParticipant        |-> oldParticipant.value,
         additionalOrderFlags  |-> additionalOrderFlags.value,
         fourthReserved1       |-> fourthReserved1.value,
         giveUpTrade           |-> giveUpTrade.value,
         fifthReserved1        |-> fifthReserved1.value,
         pan                   |-> pan.value,
         oldPan                |-> oldPan.value,
         algoId                |-> algoId.value,
         reserved2             |-> reserved2.value,
         lastActivityReference |-> lastActivityReference.value,
         nnfField              |-> nnfField.value,
         reserved44            |-> reserved44.value ], reserved44.rest)

ZeroTradeConfirmationMessage ==
    [ responseOrderNumber   |-> [i \in 1 .. 8 |-> 0],
      brokerId              |-> [i \in 1 .. 5 |-> 0],
      reserved1             |-> [i \in 1 .. 1 |-> 0],
      traderNum             |-> [i \in 1 .. 4 |-> 0],
      accountNum            |-> [i \in 1 .. 10 |-> 0],
      buySell               |-> [i \in 1 .. 2 |-> 0],
      originalVol           |-> [i \in 1 .. 4 |-> 0],
      disclosedVol          |-> [i \in 1 .. 4 |-> 0],
      remainingVol          |-> [i \in 1 .. 4 |-> 0],
      disclosedVolRemaining |-> [i \in 1 .. 4 |-> 0],
      price                 |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags          |-> [i \in 1 .. 2 |-> 0],
      gtd                   |-> [i \in 1 .. 4 |-> 0],
      fillNumber            |-> [i \in 1 .. 4 |-> 0],
      fillQty               |-> [i \in 1 .. 4 |-> 0],
      fillPrice             |-> [i \in 1 .. 4 |-> 0],
      volFilledToday        |-> [i \in 1 .. 4 |-> 0],
      activityType          |-> [i \in 1 .. 2 |-> 0],
      activityTime          |-> [i \in 1 .. 4 |-> 0],
      opOrderNumber         |-> [i \in 1 .. 8 |-> 0],
      opBrokerId            |-> [i \in 1 .. 5 |-> 0],
      secondReserved1       |-> [i \in 1 .. 1 |-> 0],
      token                 |-> [i \in 1 .. 4 |-> 0],
      contractDesc          |-> ZeroContractDesc,
      openClose             |-> [i \in 1 .. 1 |-> 0],
      oldOpenClose          |-> [i \in 1 .. 1 |-> 0],
      bookTypeChar1         |-> [i \in 1 .. 1 |-> 0],
      thirdReserved1        |-> [i \in 1 .. 1 |-> 0],
      newVolume             |-> [i \in 1 .. 4 |-> 0],
      oldAccountNumber      |-> [i \in 1 .. 10 |-> 0],
      participant           |-> [i \in 1 .. 12 |-> 0],
      oldParticipant        |-> [i \in 1 .. 12 |-> 0],
      additionalOrderFlags  |-> [i \in 1 .. 1 |-> 0],
      fourthReserved1       |-> [i \in 1 .. 1 |-> 0],
      giveUpTrade           |-> [i \in 1 .. 1 |-> 0],
      fifthReserved1        |-> [i \in 1 .. 1 |-> 0],
      pan                   |-> [i \in 1 .. 10 |-> 0],
      oldPan                |-> [i \in 1 .. 10 |-> 0],
      algoId                |-> [i \in 1 .. 4 |-> 0],
      reserved2             |-> [i \in 1 .. 2 |-> 0],
      lastActivityReference |-> [i \in 1 .. 8 |-> 0],
      nnfField              |-> [i \in 1 .. 8 |-> 0],
      reserved44            |-> [i \in 1 .. 44 |-> 0] ]

(* Trade Confirmation Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeConfirmationMessage ==
    { ZeroTradeConfirmationMessage }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.responseOrderNumber = one] : one \in Sample(8) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.traderNum = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.accountNum = one] : one \in Sample(10) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.buySell = one] : one \in Sample(2) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.originalVol = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.disclosedVol = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.remainingVol = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.disclosedVolRemaining = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.gtd = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.fillNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.fillQty = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.fillPrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.volFilledToday = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.activityType = one] : one \in Sample(2) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.activityTime = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.opOrderNumber = one] : one \in Sample(8) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.opBrokerId = one] : one \in Sample(5) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.secondReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.token = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.contractDesc = one] : one \in CheckedContractDesc }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.oldOpenClose = one] : one \in Sample(1) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.bookTypeChar1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.thirdReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.newVolume = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.oldAccountNumber = one] : one \in Sample(10) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.participant = one] : one \in Sample(12) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.oldParticipant = one] : one \in Sample(12) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.additionalOrderFlags = one] : one \in Sample(1) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.fourthReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.giveUpTrade = one] : one \in Sample(1) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.fifthReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.oldPan = one] : one \in Sample(10) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.lastActivityReference = one] : one \in Sample(8) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.reserved44 = one] : one \in Sample(44) }

(***************************************************************************)
(* Contract Desc: 28 bytes                                                 *)
(***************************************************************************)

ContractDesc2 ==
    [ instrumentName : Sample(6),
      symbol         : Sample(10),
      expiryDate     : Sample(4),
      strikePrice    : Sample(4),
      optionType     : Sample(2),
      caLevel        : Sample(2) ]

EncodeContractDesc2(message) ==
    message.instrumentName
        \o message.symbol
        \o message.expiryDate
        \o message.strikePrice
        \o message.optionType
        \o message.caLevel

DecodeContractDesc2(bytes) ==
    LET instrumentName == ReadBytes(bytes, 6) IN IF ~instrumentName.ok THEN Fail ELSE
    LET symbol == ReadBytes(instrumentName.rest, 10) IN IF ~symbol.ok THEN Fail ELSE
    LET expiryDate == ReadBytes(symbol.rest, 4) IN IF ~expiryDate.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(expiryDate.rest, 4) IN IF ~strikePrice.ok THEN Fail ELSE
    LET optionType == ReadBytes(strikePrice.rest, 2) IN IF ~optionType.ok THEN Fail ELSE
    LET caLevel == ReadBytes(optionType.rest, 2) IN IF ~caLevel.ok THEN Fail ELSE
    Ok([ instrumentName |-> instrumentName.value,
         symbol         |-> symbol.value,
         expiryDate     |-> expiryDate.value,
         strikePrice    |-> strikePrice.value,
         optionType     |-> optionType.value,
         caLevel        |-> caLevel.value ], caLevel.rest)

ZeroContractDesc2 ==
    [ instrumentName |-> [i \in 1 .. 6 |-> 0],
      symbol         |-> [i \in 1 .. 10 |-> 0],
      expiryDate     |-> [i \in 1 .. 4 |-> 0],
      strikePrice    |-> [i \in 1 .. 4 |-> 0],
      optionType     |-> [i \in 1 .. 2 |-> 0],
      caLevel        |-> [i \in 1 .. 2 |-> 0] ]

(* Contract Desc at zero, then each field in turn at the values it is checked at *)
CheckedContractDesc2 ==
    { ZeroContractDesc2 }
        \cup { [ZeroContractDesc2 EXCEPT !.instrumentName = one] : one \in Sample(6) }
        \cup { [ZeroContractDesc2 EXCEPT !.symbol = one] : one \in Sample(10) }
        \cup { [ZeroContractDesc2 EXCEPT !.expiryDate = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc2 EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc2 EXCEPT !.optionType = one] : one \in Sample(2) }
        \cup { [ZeroContractDesc2 EXCEPT !.caLevel = one] : one \in Sample(2) }

(***************************************************************************)
(* Trade Cancel Confirm Message: 256 bytes                                 *)
(***************************************************************************)

TradeCancelConfirmMessage ==
    [ responseOrderNumber   : Sample(8),
      brokerId              : Sample(5),
      reserved1             : Sample(1),
      traderNum             : Sample(4),
      accountNum            : Sample(10),
      buySell               : Sample(2),
      originalVol           : Sample(4),
      disclosedVol          : Sample(4),
      remainingVol          : Sample(4),
      disclosedVolRemaining : Sample(4),
      price                 : Sample(4),
      stOrderFlags          : Sample(2),
      gtd                   : Sample(4),
      fillNumber            : Sample(4),
      fillQty               : Sample(4),
      fillPrice             : Sample(4),
      volFilledToday        : Sample(4),
      activityType          : Sample(2),
      activityTime          : Sample(4),
      opOrderNumber         : Sample(8),
      opBrokerId            : Sample(5),
      secondReserved1       : Sample(1),
      token                 : Sample(4),
      contractDesc          : ContractDesc2,
      openClose             : Sample(1),
      oldOpenClose          : Sample(1),
      bookTypeChar1         : Sample(1),
      thirdReserved1        : Sample(1),
      newVolume             : Sample(4),
      oldAccountNumber      : Sample(10),
      participant           : Sample(12),
      oldParticipant        : Sample(12),
      additionalOrderFlags  : Sample(1),
      fourthReserved1       : Sample(1),
      giveUpTrade           : Sample(1),
      fifthReserved1        : Sample(1),
      pan                   : Sample(10),
      oldPan                : Sample(10),
      algoId                : Sample(4),
      reserved2             : Sample(2),
      lastActivityReference : Sample(8),
      nnfField              : Sample(8),
      reserved44            : Sample(44) ]

EncodeTradeCancelConfirmMessage(message) ==
    message.responseOrderNumber
        \o message.brokerId
        \o message.reserved1
        \o message.traderNum
        \o message.accountNum
        \o message.buySell
        \o message.originalVol
        \o message.disclosedVol
        \o message.remainingVol
        \o message.disclosedVolRemaining
        \o message.price
        \o message.stOrderFlags
        \o message.gtd
        \o message.fillNumber
        \o message.fillQty
        \o message.fillPrice
        \o message.volFilledToday
        \o message.activityType
        \o message.activityTime
        \o message.opOrderNumber
        \o message.opBrokerId
        \o message.secondReserved1
        \o message.token
        \o EncodeContractDesc2(message.contractDesc)
        \o message.openClose
        \o message.oldOpenClose
        \o message.bookTypeChar1
        \o message.thirdReserved1
        \o message.newVolume
        \o message.oldAccountNumber
        \o message.participant
        \o message.oldParticipant
        \o message.additionalOrderFlags
        \o message.fourthReserved1
        \o message.giveUpTrade
        \o message.fifthReserved1
        \o message.pan
        \o message.oldPan
        \o message.algoId
        \o message.reserved2
        \o message.lastActivityReference
        \o message.nnfField
        \o message.reserved44

DecodeTradeCancelConfirmMessage(bytes) ==
    LET responseOrderNumber == ReadBytes(bytes, 8) IN IF ~responseOrderNumber.ok THEN Fail ELSE
    LET brokerId == ReadBytes(responseOrderNumber.rest, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(brokerId.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET traderNum == ReadBytes(reserved1.rest, 4) IN IF ~traderNum.ok THEN Fail ELSE
    LET accountNum == ReadBytes(traderNum.rest, 10) IN IF ~accountNum.ok THEN Fail ELSE
    LET buySell == ReadBytes(accountNum.rest, 2) IN IF ~buySell.ok THEN Fail ELSE
    LET originalVol == ReadBytes(buySell.rest, 4) IN IF ~originalVol.ok THEN Fail ELSE
    LET disclosedVol == ReadBytes(originalVol.rest, 4) IN IF ~disclosedVol.ok THEN Fail ELSE
    LET remainingVol == ReadBytes(disclosedVol.rest, 4) IN IF ~remainingVol.ok THEN Fail ELSE
    LET disclosedVolRemaining == ReadBytes(remainingVol.rest, 4) IN IF ~disclosedVolRemaining.ok THEN Fail ELSE
    LET price == ReadBytes(disclosedVolRemaining.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(price.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET gtd == ReadBytes(stOrderFlags.rest, 4) IN IF ~gtd.ok THEN Fail ELSE
    LET fillNumber == ReadBytes(gtd.rest, 4) IN IF ~fillNumber.ok THEN Fail ELSE
    LET fillQty == ReadBytes(fillNumber.rest, 4) IN IF ~fillQty.ok THEN Fail ELSE
    LET fillPrice == ReadBytes(fillQty.rest, 4) IN IF ~fillPrice.ok THEN Fail ELSE
    LET volFilledToday == ReadBytes(fillPrice.rest, 4) IN IF ~volFilledToday.ok THEN Fail ELSE
    LET activityType == ReadBytes(volFilledToday.rest, 2) IN IF ~activityType.ok THEN Fail ELSE
    LET activityTime == ReadBytes(activityType.rest, 4) IN IF ~activityTime.ok THEN Fail ELSE
    LET opOrderNumber == ReadBytes(activityTime.rest, 8) IN IF ~opOrderNumber.ok THEN Fail ELSE
    LET opBrokerId == ReadBytes(opOrderNumber.rest, 5) IN IF ~opBrokerId.ok THEN Fail ELSE
    LET secondReserved1 == ReadBytes(opBrokerId.rest, 1) IN IF ~secondReserved1.ok THEN Fail ELSE
    LET token == ReadBytes(secondReserved1.rest, 4) IN IF ~token.ok THEN Fail ELSE
    LET contractDesc == DecodeContractDesc2(token.rest) IN IF ~contractDesc.ok THEN Fail ELSE
    LET openClose == ReadBytes(contractDesc.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET oldOpenClose == ReadBytes(openClose.rest, 1) IN IF ~oldOpenClose.ok THEN Fail ELSE
    LET bookTypeChar1 == ReadBytes(oldOpenClose.rest, 1) IN IF ~bookTypeChar1.ok THEN Fail ELSE
    LET thirdReserved1 == ReadBytes(bookTypeChar1.rest, 1) IN IF ~thirdReserved1.ok THEN Fail ELSE
    LET newVolume == ReadBytes(thirdReserved1.rest, 4) IN IF ~newVolume.ok THEN Fail ELSE
    LET oldAccountNumber == ReadBytes(newVolume.rest, 10) IN IF ~oldAccountNumber.ok THEN Fail ELSE
    LET participant == ReadBytes(oldAccountNumber.rest, 12) IN IF ~participant.ok THEN Fail ELSE
    LET oldParticipant == ReadBytes(participant.rest, 12) IN IF ~oldParticipant.ok THEN Fail ELSE
    LET additionalOrderFlags == ReadBytes(oldParticipant.rest, 1) IN IF ~additionalOrderFlags.ok THEN Fail ELSE
    LET fourthReserved1 == ReadBytes(additionalOrderFlags.rest, 1) IN IF ~fourthReserved1.ok THEN Fail ELSE
    LET giveUpTrade == ReadBytes(fourthReserved1.rest, 1) IN IF ~giveUpTrade.ok THEN Fail ELSE
    LET fifthReserved1 == ReadBytes(giveUpTrade.rest, 1) IN IF ~fifthReserved1.ok THEN Fail ELSE
    LET pan == ReadBytes(fifthReserved1.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET oldPan == ReadBytes(pan.rest, 10) IN IF ~oldPan.ok THEN Fail ELSE
    LET algoId == ReadBytes(oldPan.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(algoId.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET lastActivityReference == ReadBytes(reserved2.rest, 8) IN IF ~lastActivityReference.ok THEN Fail ELSE
    LET nnfField == ReadBytes(lastActivityReference.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET reserved44 == ReadBytes(nnfField.rest, 44) IN IF ~reserved44.ok THEN Fail ELSE
    Ok([ responseOrderNumber   |-> responseOrderNumber.value,
         brokerId              |-> brokerId.value,
         reserved1             |-> reserved1.value,
         traderNum             |-> traderNum.value,
         accountNum            |-> accountNum.value,
         buySell               |-> buySell.value,
         originalVol           |-> originalVol.value,
         disclosedVol          |-> disclosedVol.value,
         remainingVol          |-> remainingVol.value,
         disclosedVolRemaining |-> disclosedVolRemaining.value,
         price                 |-> price.value,
         stOrderFlags          |-> stOrderFlags.value,
         gtd                   |-> gtd.value,
         fillNumber            |-> fillNumber.value,
         fillQty               |-> fillQty.value,
         fillPrice             |-> fillPrice.value,
         volFilledToday        |-> volFilledToday.value,
         activityType          |-> activityType.value,
         activityTime          |-> activityTime.value,
         opOrderNumber         |-> opOrderNumber.value,
         opBrokerId            |-> opBrokerId.value,
         secondReserved1       |-> secondReserved1.value,
         token                 |-> token.value,
         contractDesc          |-> contractDesc.value,
         openClose             |-> openClose.value,
         oldOpenClose          |-> oldOpenClose.value,
         bookTypeChar1         |-> bookTypeChar1.value,
         thirdReserved1        |-> thirdReserved1.value,
         newVolume             |-> newVolume.value,
         oldAccountNumber      |-> oldAccountNumber.value,
         participant           |-> participant.value,
         oldParticipant        |-> oldParticipant.value,
         additionalOrderFlags  |-> additionalOrderFlags.value,
         fourthReserved1       |-> fourthReserved1.value,
         giveUpTrade           |-> giveUpTrade.value,
         fifthReserved1        |-> fifthReserved1.value,
         pan                   |-> pan.value,
         oldPan                |-> oldPan.value,
         algoId                |-> algoId.value,
         reserved2             |-> reserved2.value,
         lastActivityReference |-> lastActivityReference.value,
         nnfField              |-> nnfField.value,
         reserved44            |-> reserved44.value ], reserved44.rest)

ZeroTradeCancelConfirmMessage ==
    [ responseOrderNumber   |-> [i \in 1 .. 8 |-> 0],
      brokerId              |-> [i \in 1 .. 5 |-> 0],
      reserved1             |-> [i \in 1 .. 1 |-> 0],
      traderNum             |-> [i \in 1 .. 4 |-> 0],
      accountNum            |-> [i \in 1 .. 10 |-> 0],
      buySell               |-> [i \in 1 .. 2 |-> 0],
      originalVol           |-> [i \in 1 .. 4 |-> 0],
      disclosedVol          |-> [i \in 1 .. 4 |-> 0],
      remainingVol          |-> [i \in 1 .. 4 |-> 0],
      disclosedVolRemaining |-> [i \in 1 .. 4 |-> 0],
      price                 |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags          |-> [i \in 1 .. 2 |-> 0],
      gtd                   |-> [i \in 1 .. 4 |-> 0],
      fillNumber            |-> [i \in 1 .. 4 |-> 0],
      fillQty               |-> [i \in 1 .. 4 |-> 0],
      fillPrice             |-> [i \in 1 .. 4 |-> 0],
      volFilledToday        |-> [i \in 1 .. 4 |-> 0],
      activityType          |-> [i \in 1 .. 2 |-> 0],
      activityTime          |-> [i \in 1 .. 4 |-> 0],
      opOrderNumber         |-> [i \in 1 .. 8 |-> 0],
      opBrokerId            |-> [i \in 1 .. 5 |-> 0],
      secondReserved1       |-> [i \in 1 .. 1 |-> 0],
      token                 |-> [i \in 1 .. 4 |-> 0],
      contractDesc          |-> ZeroContractDesc2,
      openClose             |-> [i \in 1 .. 1 |-> 0],
      oldOpenClose          |-> [i \in 1 .. 1 |-> 0],
      bookTypeChar1         |-> [i \in 1 .. 1 |-> 0],
      thirdReserved1        |-> [i \in 1 .. 1 |-> 0],
      newVolume             |-> [i \in 1 .. 4 |-> 0],
      oldAccountNumber      |-> [i \in 1 .. 10 |-> 0],
      participant           |-> [i \in 1 .. 12 |-> 0],
      oldParticipant        |-> [i \in 1 .. 12 |-> 0],
      additionalOrderFlags  |-> [i \in 1 .. 1 |-> 0],
      fourthReserved1       |-> [i \in 1 .. 1 |-> 0],
      giveUpTrade           |-> [i \in 1 .. 1 |-> 0],
      fifthReserved1        |-> [i \in 1 .. 1 |-> 0],
      pan                   |-> [i \in 1 .. 10 |-> 0],
      oldPan                |-> [i \in 1 .. 10 |-> 0],
      algoId                |-> [i \in 1 .. 4 |-> 0],
      reserved2             |-> [i \in 1 .. 2 |-> 0],
      lastActivityReference |-> [i \in 1 .. 8 |-> 0],
      nnfField              |-> [i \in 1 .. 8 |-> 0],
      reserved44            |-> [i \in 1 .. 44 |-> 0] ]

(* Trade Cancel Confirm Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCancelConfirmMessage ==
    { ZeroTradeCancelConfirmMessage }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.responseOrderNumber = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.traderNum = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.accountNum = one] : one \in Sample(10) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.buySell = one] : one \in Sample(2) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.originalVol = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.disclosedVol = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.remainingVol = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.disclosedVolRemaining = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.gtd = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.fillNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.fillQty = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.fillPrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.volFilledToday = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.activityType = one] : one \in Sample(2) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.activityTime = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.opOrderNumber = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.opBrokerId = one] : one \in Sample(5) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.secondReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.token = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.contractDesc = one] : one \in CheckedContractDesc2 }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.oldOpenClose = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.bookTypeChar1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.thirdReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.newVolume = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.oldAccountNumber = one] : one \in Sample(10) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.participant = one] : one \in Sample(12) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.oldParticipant = one] : one \in Sample(12) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.additionalOrderFlags = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.fourthReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.giveUpTrade = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.fifthReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.oldPan = one] : one \in Sample(10) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.lastActivityReference = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.reserved44 = one] : one \in Sample(44) }

(***************************************************************************)
(* Contract Desc: 28 bytes                                                 *)
(***************************************************************************)

ContractDesc3 ==
    [ instrumentName : Sample(6),
      symbol         : Sample(10),
      expiryDate     : Sample(4),
      strikePrice    : Sample(4),
      optionType     : Sample(2),
      caLevel        : Sample(2) ]

EncodeContractDesc3(message) ==
    message.instrumentName
        \o message.symbol
        \o message.expiryDate
        \o message.strikePrice
        \o message.optionType
        \o message.caLevel

DecodeContractDesc3(bytes) ==
    LET instrumentName == ReadBytes(bytes, 6) IN IF ~instrumentName.ok THEN Fail ELSE
    LET symbol == ReadBytes(instrumentName.rest, 10) IN IF ~symbol.ok THEN Fail ELSE
    LET expiryDate == ReadBytes(symbol.rest, 4) IN IF ~expiryDate.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(expiryDate.rest, 4) IN IF ~strikePrice.ok THEN Fail ELSE
    LET optionType == ReadBytes(strikePrice.rest, 2) IN IF ~optionType.ok THEN Fail ELSE
    LET caLevel == ReadBytes(optionType.rest, 2) IN IF ~caLevel.ok THEN Fail ELSE
    Ok([ instrumentName |-> instrumentName.value,
         symbol         |-> symbol.value,
         expiryDate     |-> expiryDate.value,
         strikePrice    |-> strikePrice.value,
         optionType     |-> optionType.value,
         caLevel        |-> caLevel.value ], caLevel.rest)

ZeroContractDesc3 ==
    [ instrumentName |-> [i \in 1 .. 6 |-> 0],
      symbol         |-> [i \in 1 .. 10 |-> 0],
      expiryDate     |-> [i \in 1 .. 4 |-> 0],
      strikePrice    |-> [i \in 1 .. 4 |-> 0],
      optionType     |-> [i \in 1 .. 2 |-> 0],
      caLevel        |-> [i \in 1 .. 2 |-> 0] ]

(* Contract Desc at zero, then each field in turn at the values it is checked at *)
CheckedContractDesc3 ==
    { ZeroContractDesc3 }
        \cup { [ZeroContractDesc3 EXCEPT !.instrumentName = one] : one \in Sample(6) }
        \cup { [ZeroContractDesc3 EXCEPT !.symbol = one] : one \in Sample(10) }
        \cup { [ZeroContractDesc3 EXCEPT !.expiryDate = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc3 EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc3 EXCEPT !.optionType = one] : one \in Sample(2) }
        \cup { [ZeroContractDesc3 EXCEPT !.caLevel = one] : one \in Sample(2) }

(***************************************************************************)
(* Trade Cancel Reject Message: 256 bytes                                  *)
(***************************************************************************)

TradeCancelRejectMessage ==
    [ responseOrderNumber   : Sample(8),
      brokerId              : Sample(5),
      reserved1             : Sample(1),
      traderNum             : Sample(4),
      accountNum            : Sample(10),
      buySell               : Sample(2),
      originalVol           : Sample(4),
      disclosedVol          : Sample(4),
      remainingVol          : Sample(4),
      disclosedVolRemaining : Sample(4),
      price                 : Sample(4),
      stOrderFlags          : Sample(2),
      gtd                   : Sample(4),
      fillNumber            : Sample(4),
      fillQty               : Sample(4),
      fillPrice             : Sample(4),
      volFilledToday        : Sample(4),
      activityType          : Sample(2),
      activityTime          : Sample(4),
      opOrderNumber         : Sample(8),
      opBrokerId            : Sample(5),
      secondReserved1       : Sample(1),
      token                 : Sample(4),
      contractDesc          : ContractDesc3,
      openClose             : Sample(1),
      oldOpenClose          : Sample(1),
      bookTypeChar1         : Sample(1),
      thirdReserved1        : Sample(1),
      newVolume             : Sample(4),
      oldAccountNumber      : Sample(10),
      participant           : Sample(12),
      oldParticipant        : Sample(12),
      additionalOrderFlags  : Sample(1),
      fourthReserved1       : Sample(1),
      giveUpTrade           : Sample(1),
      fifthReserved1        : Sample(1),
      pan                   : Sample(10),
      oldPan                : Sample(10),
      algoId                : Sample(4),
      reserved2             : Sample(2),
      lastActivityReference : Sample(8),
      nnfField              : Sample(8),
      reserved44            : Sample(44) ]

EncodeTradeCancelRejectMessage(message) ==
    message.responseOrderNumber
        \o message.brokerId
        \o message.reserved1
        \o message.traderNum
        \o message.accountNum
        \o message.buySell
        \o message.originalVol
        \o message.disclosedVol
        \o message.remainingVol
        \o message.disclosedVolRemaining
        \o message.price
        \o message.stOrderFlags
        \o message.gtd
        \o message.fillNumber
        \o message.fillQty
        \o message.fillPrice
        \o message.volFilledToday
        \o message.activityType
        \o message.activityTime
        \o message.opOrderNumber
        \o message.opBrokerId
        \o message.secondReserved1
        \o message.token
        \o EncodeContractDesc3(message.contractDesc)
        \o message.openClose
        \o message.oldOpenClose
        \o message.bookTypeChar1
        \o message.thirdReserved1
        \o message.newVolume
        \o message.oldAccountNumber
        \o message.participant
        \o message.oldParticipant
        \o message.additionalOrderFlags
        \o message.fourthReserved1
        \o message.giveUpTrade
        \o message.fifthReserved1
        \o message.pan
        \o message.oldPan
        \o message.algoId
        \o message.reserved2
        \o message.lastActivityReference
        \o message.nnfField
        \o message.reserved44

DecodeTradeCancelRejectMessage(bytes) ==
    LET responseOrderNumber == ReadBytes(bytes, 8) IN IF ~responseOrderNumber.ok THEN Fail ELSE
    LET brokerId == ReadBytes(responseOrderNumber.rest, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(brokerId.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET traderNum == ReadBytes(reserved1.rest, 4) IN IF ~traderNum.ok THEN Fail ELSE
    LET accountNum == ReadBytes(traderNum.rest, 10) IN IF ~accountNum.ok THEN Fail ELSE
    LET buySell == ReadBytes(accountNum.rest, 2) IN IF ~buySell.ok THEN Fail ELSE
    LET originalVol == ReadBytes(buySell.rest, 4) IN IF ~originalVol.ok THEN Fail ELSE
    LET disclosedVol == ReadBytes(originalVol.rest, 4) IN IF ~disclosedVol.ok THEN Fail ELSE
    LET remainingVol == ReadBytes(disclosedVol.rest, 4) IN IF ~remainingVol.ok THEN Fail ELSE
    LET disclosedVolRemaining == ReadBytes(remainingVol.rest, 4) IN IF ~disclosedVolRemaining.ok THEN Fail ELSE
    LET price == ReadBytes(disclosedVolRemaining.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(price.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET gtd == ReadBytes(stOrderFlags.rest, 4) IN IF ~gtd.ok THEN Fail ELSE
    LET fillNumber == ReadBytes(gtd.rest, 4) IN IF ~fillNumber.ok THEN Fail ELSE
    LET fillQty == ReadBytes(fillNumber.rest, 4) IN IF ~fillQty.ok THEN Fail ELSE
    LET fillPrice == ReadBytes(fillQty.rest, 4) IN IF ~fillPrice.ok THEN Fail ELSE
    LET volFilledToday == ReadBytes(fillPrice.rest, 4) IN IF ~volFilledToday.ok THEN Fail ELSE
    LET activityType == ReadBytes(volFilledToday.rest, 2) IN IF ~activityType.ok THEN Fail ELSE
    LET activityTime == ReadBytes(activityType.rest, 4) IN IF ~activityTime.ok THEN Fail ELSE
    LET opOrderNumber == ReadBytes(activityTime.rest, 8) IN IF ~opOrderNumber.ok THEN Fail ELSE
    LET opBrokerId == ReadBytes(opOrderNumber.rest, 5) IN IF ~opBrokerId.ok THEN Fail ELSE
    LET secondReserved1 == ReadBytes(opBrokerId.rest, 1) IN IF ~secondReserved1.ok THEN Fail ELSE
    LET token == ReadBytes(secondReserved1.rest, 4) IN IF ~token.ok THEN Fail ELSE
    LET contractDesc == DecodeContractDesc3(token.rest) IN IF ~contractDesc.ok THEN Fail ELSE
    LET openClose == ReadBytes(contractDesc.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET oldOpenClose == ReadBytes(openClose.rest, 1) IN IF ~oldOpenClose.ok THEN Fail ELSE
    LET bookTypeChar1 == ReadBytes(oldOpenClose.rest, 1) IN IF ~bookTypeChar1.ok THEN Fail ELSE
    LET thirdReserved1 == ReadBytes(bookTypeChar1.rest, 1) IN IF ~thirdReserved1.ok THEN Fail ELSE
    LET newVolume == ReadBytes(thirdReserved1.rest, 4) IN IF ~newVolume.ok THEN Fail ELSE
    LET oldAccountNumber == ReadBytes(newVolume.rest, 10) IN IF ~oldAccountNumber.ok THEN Fail ELSE
    LET participant == ReadBytes(oldAccountNumber.rest, 12) IN IF ~participant.ok THEN Fail ELSE
    LET oldParticipant == ReadBytes(participant.rest, 12) IN IF ~oldParticipant.ok THEN Fail ELSE
    LET additionalOrderFlags == ReadBytes(oldParticipant.rest, 1) IN IF ~additionalOrderFlags.ok THEN Fail ELSE
    LET fourthReserved1 == ReadBytes(additionalOrderFlags.rest, 1) IN IF ~fourthReserved1.ok THEN Fail ELSE
    LET giveUpTrade == ReadBytes(fourthReserved1.rest, 1) IN IF ~giveUpTrade.ok THEN Fail ELSE
    LET fifthReserved1 == ReadBytes(giveUpTrade.rest, 1) IN IF ~fifthReserved1.ok THEN Fail ELSE
    LET pan == ReadBytes(fifthReserved1.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET oldPan == ReadBytes(pan.rest, 10) IN IF ~oldPan.ok THEN Fail ELSE
    LET algoId == ReadBytes(oldPan.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(algoId.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET lastActivityReference == ReadBytes(reserved2.rest, 8) IN IF ~lastActivityReference.ok THEN Fail ELSE
    LET nnfField == ReadBytes(lastActivityReference.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET reserved44 == ReadBytes(nnfField.rest, 44) IN IF ~reserved44.ok THEN Fail ELSE
    Ok([ responseOrderNumber   |-> responseOrderNumber.value,
         brokerId              |-> brokerId.value,
         reserved1             |-> reserved1.value,
         traderNum             |-> traderNum.value,
         accountNum            |-> accountNum.value,
         buySell               |-> buySell.value,
         originalVol           |-> originalVol.value,
         disclosedVol          |-> disclosedVol.value,
         remainingVol          |-> remainingVol.value,
         disclosedVolRemaining |-> disclosedVolRemaining.value,
         price                 |-> price.value,
         stOrderFlags          |-> stOrderFlags.value,
         gtd                   |-> gtd.value,
         fillNumber            |-> fillNumber.value,
         fillQty               |-> fillQty.value,
         fillPrice             |-> fillPrice.value,
         volFilledToday        |-> volFilledToday.value,
         activityType          |-> activityType.value,
         activityTime          |-> activityTime.value,
         opOrderNumber         |-> opOrderNumber.value,
         opBrokerId            |-> opBrokerId.value,
         secondReserved1       |-> secondReserved1.value,
         token                 |-> token.value,
         contractDesc          |-> contractDesc.value,
         openClose             |-> openClose.value,
         oldOpenClose          |-> oldOpenClose.value,
         bookTypeChar1         |-> bookTypeChar1.value,
         thirdReserved1        |-> thirdReserved1.value,
         newVolume             |-> newVolume.value,
         oldAccountNumber      |-> oldAccountNumber.value,
         participant           |-> participant.value,
         oldParticipant        |-> oldParticipant.value,
         additionalOrderFlags  |-> additionalOrderFlags.value,
         fourthReserved1       |-> fourthReserved1.value,
         giveUpTrade           |-> giveUpTrade.value,
         fifthReserved1        |-> fifthReserved1.value,
         pan                   |-> pan.value,
         oldPan                |-> oldPan.value,
         algoId                |-> algoId.value,
         reserved2             |-> reserved2.value,
         lastActivityReference |-> lastActivityReference.value,
         nnfField              |-> nnfField.value,
         reserved44            |-> reserved44.value ], reserved44.rest)

ZeroTradeCancelRejectMessage ==
    [ responseOrderNumber   |-> [i \in 1 .. 8 |-> 0],
      brokerId              |-> [i \in 1 .. 5 |-> 0],
      reserved1             |-> [i \in 1 .. 1 |-> 0],
      traderNum             |-> [i \in 1 .. 4 |-> 0],
      accountNum            |-> [i \in 1 .. 10 |-> 0],
      buySell               |-> [i \in 1 .. 2 |-> 0],
      originalVol           |-> [i \in 1 .. 4 |-> 0],
      disclosedVol          |-> [i \in 1 .. 4 |-> 0],
      remainingVol          |-> [i \in 1 .. 4 |-> 0],
      disclosedVolRemaining |-> [i \in 1 .. 4 |-> 0],
      price                 |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags          |-> [i \in 1 .. 2 |-> 0],
      gtd                   |-> [i \in 1 .. 4 |-> 0],
      fillNumber            |-> [i \in 1 .. 4 |-> 0],
      fillQty               |-> [i \in 1 .. 4 |-> 0],
      fillPrice             |-> [i \in 1 .. 4 |-> 0],
      volFilledToday        |-> [i \in 1 .. 4 |-> 0],
      activityType          |-> [i \in 1 .. 2 |-> 0],
      activityTime          |-> [i \in 1 .. 4 |-> 0],
      opOrderNumber         |-> [i \in 1 .. 8 |-> 0],
      opBrokerId            |-> [i \in 1 .. 5 |-> 0],
      secondReserved1       |-> [i \in 1 .. 1 |-> 0],
      token                 |-> [i \in 1 .. 4 |-> 0],
      contractDesc          |-> ZeroContractDesc3,
      openClose             |-> [i \in 1 .. 1 |-> 0],
      oldOpenClose          |-> [i \in 1 .. 1 |-> 0],
      bookTypeChar1         |-> [i \in 1 .. 1 |-> 0],
      thirdReserved1        |-> [i \in 1 .. 1 |-> 0],
      newVolume             |-> [i \in 1 .. 4 |-> 0],
      oldAccountNumber      |-> [i \in 1 .. 10 |-> 0],
      participant           |-> [i \in 1 .. 12 |-> 0],
      oldParticipant        |-> [i \in 1 .. 12 |-> 0],
      additionalOrderFlags  |-> [i \in 1 .. 1 |-> 0],
      fourthReserved1       |-> [i \in 1 .. 1 |-> 0],
      giveUpTrade           |-> [i \in 1 .. 1 |-> 0],
      fifthReserved1        |-> [i \in 1 .. 1 |-> 0],
      pan                   |-> [i \in 1 .. 10 |-> 0],
      oldPan                |-> [i \in 1 .. 10 |-> 0],
      algoId                |-> [i \in 1 .. 4 |-> 0],
      reserved2             |-> [i \in 1 .. 2 |-> 0],
      lastActivityReference |-> [i \in 1 .. 8 |-> 0],
      nnfField              |-> [i \in 1 .. 8 |-> 0],
      reserved44            |-> [i \in 1 .. 44 |-> 0] ]

(* Trade Cancel Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCancelRejectMessage ==
    { ZeroTradeCancelRejectMessage }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.responseOrderNumber = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.traderNum = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.accountNum = one] : one \in Sample(10) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.buySell = one] : one \in Sample(2) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.originalVol = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.disclosedVol = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.remainingVol = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.disclosedVolRemaining = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.gtd = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.fillNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.fillQty = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.fillPrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.volFilledToday = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.activityType = one] : one \in Sample(2) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.activityTime = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.opOrderNumber = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.opBrokerId = one] : one \in Sample(5) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.secondReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.token = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.contractDesc = one] : one \in CheckedContractDesc3 }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.oldOpenClose = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.bookTypeChar1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.thirdReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.newVolume = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.oldAccountNumber = one] : one \in Sample(10) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.participant = one] : one \in Sample(12) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.oldParticipant = one] : one \in Sample(12) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.additionalOrderFlags = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.fourthReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.giveUpTrade = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.fifthReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.oldPan = one] : one \in Sample(10) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.lastActivityReference = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.reserved44 = one] : one \in Sample(44) }

(***************************************************************************)
(* Contract Desc: 28 bytes                                                 *)
(***************************************************************************)

ContractDesc4 ==
    [ instrumentName : Sample(6),
      symbol         : Sample(10),
      expiryDate     : Sample(4),
      strikePrice    : Sample(4),
      optionType     : Sample(2),
      caLevel        : Sample(2) ]

EncodeContractDesc4(message) ==
    message.instrumentName
        \o message.symbol
        \o message.expiryDate
        \o message.strikePrice
        \o message.optionType
        \o message.caLevel

DecodeContractDesc4(bytes) ==
    LET instrumentName == ReadBytes(bytes, 6) IN IF ~instrumentName.ok THEN Fail ELSE
    LET symbol == ReadBytes(instrumentName.rest, 10) IN IF ~symbol.ok THEN Fail ELSE
    LET expiryDate == ReadBytes(symbol.rest, 4) IN IF ~expiryDate.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(expiryDate.rest, 4) IN IF ~strikePrice.ok THEN Fail ELSE
    LET optionType == ReadBytes(strikePrice.rest, 2) IN IF ~optionType.ok THEN Fail ELSE
    LET caLevel == ReadBytes(optionType.rest, 2) IN IF ~caLevel.ok THEN Fail ELSE
    Ok([ instrumentName |-> instrumentName.value,
         symbol         |-> symbol.value,
         expiryDate     |-> expiryDate.value,
         strikePrice    |-> strikePrice.value,
         optionType     |-> optionType.value,
         caLevel        |-> caLevel.value ], caLevel.rest)

ZeroContractDesc4 ==
    [ instrumentName |-> [i \in 1 .. 6 |-> 0],
      symbol         |-> [i \in 1 .. 10 |-> 0],
      expiryDate     |-> [i \in 1 .. 4 |-> 0],
      strikePrice    |-> [i \in 1 .. 4 |-> 0],
      optionType     |-> [i \in 1 .. 2 |-> 0],
      caLevel        |-> [i \in 1 .. 2 |-> 0] ]

(* Contract Desc at zero, then each field in turn at the values it is checked at *)
CheckedContractDesc4 ==
    { ZeroContractDesc4 }
        \cup { [ZeroContractDesc4 EXCEPT !.instrumentName = one] : one \in Sample(6) }
        \cup { [ZeroContractDesc4 EXCEPT !.symbol = one] : one \in Sample(10) }
        \cup { [ZeroContractDesc4 EXCEPT !.expiryDate = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc4 EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc4 EXCEPT !.optionType = one] : one \in Sample(2) }
        \cup { [ZeroContractDesc4 EXCEPT !.caLevel = one] : one \in Sample(2) }

(***************************************************************************)
(* Trade Modify Confirm Message: 256 bytes                                 *)
(***************************************************************************)

TradeModifyConfirmMessage ==
    [ responseOrderNumber   : Sample(8),
      brokerId              : Sample(5),
      reserved1             : Sample(1),
      traderNum             : Sample(4),
      accountNum            : Sample(10),
      buySell               : Sample(2),
      originalVol           : Sample(4),
      disclosedVol          : Sample(4),
      remainingVol          : Sample(4),
      disclosedVolRemaining : Sample(4),
      price                 : Sample(4),
      stOrderFlags          : Sample(2),
      gtd                   : Sample(4),
      fillNumber            : Sample(4),
      fillQty               : Sample(4),
      fillPrice             : Sample(4),
      volFilledToday        : Sample(4),
      activityType          : Sample(2),
      activityTime          : Sample(4),
      opOrderNumber         : Sample(8),
      opBrokerId            : Sample(5),
      secondReserved1       : Sample(1),
      token                 : Sample(4),
      contractDesc          : ContractDesc4,
      openClose             : Sample(1),
      oldOpenClose          : Sample(1),
      bookTypeChar1         : Sample(1),
      thirdReserved1        : Sample(1),
      newVolume             : Sample(4),
      oldAccountNumber      : Sample(10),
      participant           : Sample(12),
      oldParticipant        : Sample(12),
      additionalOrderFlags  : Sample(1),
      fourthReserved1       : Sample(1),
      giveUpTrade           : Sample(1),
      fifthReserved1        : Sample(1),
      pan                   : Sample(10),
      oldPan                : Sample(10),
      algoId                : Sample(4),
      reserved2             : Sample(2),
      lastActivityReference : Sample(8),
      nnfField              : Sample(8),
      reserved44            : Sample(44) ]

EncodeTradeModifyConfirmMessage(message) ==
    message.responseOrderNumber
        \o message.brokerId
        \o message.reserved1
        \o message.traderNum
        \o message.accountNum
        \o message.buySell
        \o message.originalVol
        \o message.disclosedVol
        \o message.remainingVol
        \o message.disclosedVolRemaining
        \o message.price
        \o message.stOrderFlags
        \o message.gtd
        \o message.fillNumber
        \o message.fillQty
        \o message.fillPrice
        \o message.volFilledToday
        \o message.activityType
        \o message.activityTime
        \o message.opOrderNumber
        \o message.opBrokerId
        \o message.secondReserved1
        \o message.token
        \o EncodeContractDesc4(message.contractDesc)
        \o message.openClose
        \o message.oldOpenClose
        \o message.bookTypeChar1
        \o message.thirdReserved1
        \o message.newVolume
        \o message.oldAccountNumber
        \o message.participant
        \o message.oldParticipant
        \o message.additionalOrderFlags
        \o message.fourthReserved1
        \o message.giveUpTrade
        \o message.fifthReserved1
        \o message.pan
        \o message.oldPan
        \o message.algoId
        \o message.reserved2
        \o message.lastActivityReference
        \o message.nnfField
        \o message.reserved44

DecodeTradeModifyConfirmMessage(bytes) ==
    LET responseOrderNumber == ReadBytes(bytes, 8) IN IF ~responseOrderNumber.ok THEN Fail ELSE
    LET brokerId == ReadBytes(responseOrderNumber.rest, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(brokerId.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET traderNum == ReadBytes(reserved1.rest, 4) IN IF ~traderNum.ok THEN Fail ELSE
    LET accountNum == ReadBytes(traderNum.rest, 10) IN IF ~accountNum.ok THEN Fail ELSE
    LET buySell == ReadBytes(accountNum.rest, 2) IN IF ~buySell.ok THEN Fail ELSE
    LET originalVol == ReadBytes(buySell.rest, 4) IN IF ~originalVol.ok THEN Fail ELSE
    LET disclosedVol == ReadBytes(originalVol.rest, 4) IN IF ~disclosedVol.ok THEN Fail ELSE
    LET remainingVol == ReadBytes(disclosedVol.rest, 4) IN IF ~remainingVol.ok THEN Fail ELSE
    LET disclosedVolRemaining == ReadBytes(remainingVol.rest, 4) IN IF ~disclosedVolRemaining.ok THEN Fail ELSE
    LET price == ReadBytes(disclosedVolRemaining.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(price.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET gtd == ReadBytes(stOrderFlags.rest, 4) IN IF ~gtd.ok THEN Fail ELSE
    LET fillNumber == ReadBytes(gtd.rest, 4) IN IF ~fillNumber.ok THEN Fail ELSE
    LET fillQty == ReadBytes(fillNumber.rest, 4) IN IF ~fillQty.ok THEN Fail ELSE
    LET fillPrice == ReadBytes(fillQty.rest, 4) IN IF ~fillPrice.ok THEN Fail ELSE
    LET volFilledToday == ReadBytes(fillPrice.rest, 4) IN IF ~volFilledToday.ok THEN Fail ELSE
    LET activityType == ReadBytes(volFilledToday.rest, 2) IN IF ~activityType.ok THEN Fail ELSE
    LET activityTime == ReadBytes(activityType.rest, 4) IN IF ~activityTime.ok THEN Fail ELSE
    LET opOrderNumber == ReadBytes(activityTime.rest, 8) IN IF ~opOrderNumber.ok THEN Fail ELSE
    LET opBrokerId == ReadBytes(opOrderNumber.rest, 5) IN IF ~opBrokerId.ok THEN Fail ELSE
    LET secondReserved1 == ReadBytes(opBrokerId.rest, 1) IN IF ~secondReserved1.ok THEN Fail ELSE
    LET token == ReadBytes(secondReserved1.rest, 4) IN IF ~token.ok THEN Fail ELSE
    LET contractDesc == DecodeContractDesc4(token.rest) IN IF ~contractDesc.ok THEN Fail ELSE
    LET openClose == ReadBytes(contractDesc.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET oldOpenClose == ReadBytes(openClose.rest, 1) IN IF ~oldOpenClose.ok THEN Fail ELSE
    LET bookTypeChar1 == ReadBytes(oldOpenClose.rest, 1) IN IF ~bookTypeChar1.ok THEN Fail ELSE
    LET thirdReserved1 == ReadBytes(bookTypeChar1.rest, 1) IN IF ~thirdReserved1.ok THEN Fail ELSE
    LET newVolume == ReadBytes(thirdReserved1.rest, 4) IN IF ~newVolume.ok THEN Fail ELSE
    LET oldAccountNumber == ReadBytes(newVolume.rest, 10) IN IF ~oldAccountNumber.ok THEN Fail ELSE
    LET participant == ReadBytes(oldAccountNumber.rest, 12) IN IF ~participant.ok THEN Fail ELSE
    LET oldParticipant == ReadBytes(participant.rest, 12) IN IF ~oldParticipant.ok THEN Fail ELSE
    LET additionalOrderFlags == ReadBytes(oldParticipant.rest, 1) IN IF ~additionalOrderFlags.ok THEN Fail ELSE
    LET fourthReserved1 == ReadBytes(additionalOrderFlags.rest, 1) IN IF ~fourthReserved1.ok THEN Fail ELSE
    LET giveUpTrade == ReadBytes(fourthReserved1.rest, 1) IN IF ~giveUpTrade.ok THEN Fail ELSE
    LET fifthReserved1 == ReadBytes(giveUpTrade.rest, 1) IN IF ~fifthReserved1.ok THEN Fail ELSE
    LET pan == ReadBytes(fifthReserved1.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET oldPan == ReadBytes(pan.rest, 10) IN IF ~oldPan.ok THEN Fail ELSE
    LET algoId == ReadBytes(oldPan.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(algoId.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET lastActivityReference == ReadBytes(reserved2.rest, 8) IN IF ~lastActivityReference.ok THEN Fail ELSE
    LET nnfField == ReadBytes(lastActivityReference.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET reserved44 == ReadBytes(nnfField.rest, 44) IN IF ~reserved44.ok THEN Fail ELSE
    Ok([ responseOrderNumber   |-> responseOrderNumber.value,
         brokerId              |-> brokerId.value,
         reserved1             |-> reserved1.value,
         traderNum             |-> traderNum.value,
         accountNum            |-> accountNum.value,
         buySell               |-> buySell.value,
         originalVol           |-> originalVol.value,
         disclosedVol          |-> disclosedVol.value,
         remainingVol          |-> remainingVol.value,
         disclosedVolRemaining |-> disclosedVolRemaining.value,
         price                 |-> price.value,
         stOrderFlags          |-> stOrderFlags.value,
         gtd                   |-> gtd.value,
         fillNumber            |-> fillNumber.value,
         fillQty               |-> fillQty.value,
         fillPrice             |-> fillPrice.value,
         volFilledToday        |-> volFilledToday.value,
         activityType          |-> activityType.value,
         activityTime          |-> activityTime.value,
         opOrderNumber         |-> opOrderNumber.value,
         opBrokerId            |-> opBrokerId.value,
         secondReserved1       |-> secondReserved1.value,
         token                 |-> token.value,
         contractDesc          |-> contractDesc.value,
         openClose             |-> openClose.value,
         oldOpenClose          |-> oldOpenClose.value,
         bookTypeChar1         |-> bookTypeChar1.value,
         thirdReserved1        |-> thirdReserved1.value,
         newVolume             |-> newVolume.value,
         oldAccountNumber      |-> oldAccountNumber.value,
         participant           |-> participant.value,
         oldParticipant        |-> oldParticipant.value,
         additionalOrderFlags  |-> additionalOrderFlags.value,
         fourthReserved1       |-> fourthReserved1.value,
         giveUpTrade           |-> giveUpTrade.value,
         fifthReserved1        |-> fifthReserved1.value,
         pan                   |-> pan.value,
         oldPan                |-> oldPan.value,
         algoId                |-> algoId.value,
         reserved2             |-> reserved2.value,
         lastActivityReference |-> lastActivityReference.value,
         nnfField              |-> nnfField.value,
         reserved44            |-> reserved44.value ], reserved44.rest)

ZeroTradeModifyConfirmMessage ==
    [ responseOrderNumber   |-> [i \in 1 .. 8 |-> 0],
      brokerId              |-> [i \in 1 .. 5 |-> 0],
      reserved1             |-> [i \in 1 .. 1 |-> 0],
      traderNum             |-> [i \in 1 .. 4 |-> 0],
      accountNum            |-> [i \in 1 .. 10 |-> 0],
      buySell               |-> [i \in 1 .. 2 |-> 0],
      originalVol           |-> [i \in 1 .. 4 |-> 0],
      disclosedVol          |-> [i \in 1 .. 4 |-> 0],
      remainingVol          |-> [i \in 1 .. 4 |-> 0],
      disclosedVolRemaining |-> [i \in 1 .. 4 |-> 0],
      price                 |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags          |-> [i \in 1 .. 2 |-> 0],
      gtd                   |-> [i \in 1 .. 4 |-> 0],
      fillNumber            |-> [i \in 1 .. 4 |-> 0],
      fillQty               |-> [i \in 1 .. 4 |-> 0],
      fillPrice             |-> [i \in 1 .. 4 |-> 0],
      volFilledToday        |-> [i \in 1 .. 4 |-> 0],
      activityType          |-> [i \in 1 .. 2 |-> 0],
      activityTime          |-> [i \in 1 .. 4 |-> 0],
      opOrderNumber         |-> [i \in 1 .. 8 |-> 0],
      opBrokerId            |-> [i \in 1 .. 5 |-> 0],
      secondReserved1       |-> [i \in 1 .. 1 |-> 0],
      token                 |-> [i \in 1 .. 4 |-> 0],
      contractDesc          |-> ZeroContractDesc4,
      openClose             |-> [i \in 1 .. 1 |-> 0],
      oldOpenClose          |-> [i \in 1 .. 1 |-> 0],
      bookTypeChar1         |-> [i \in 1 .. 1 |-> 0],
      thirdReserved1        |-> [i \in 1 .. 1 |-> 0],
      newVolume             |-> [i \in 1 .. 4 |-> 0],
      oldAccountNumber      |-> [i \in 1 .. 10 |-> 0],
      participant           |-> [i \in 1 .. 12 |-> 0],
      oldParticipant        |-> [i \in 1 .. 12 |-> 0],
      additionalOrderFlags  |-> [i \in 1 .. 1 |-> 0],
      fourthReserved1       |-> [i \in 1 .. 1 |-> 0],
      giveUpTrade           |-> [i \in 1 .. 1 |-> 0],
      fifthReserved1        |-> [i \in 1 .. 1 |-> 0],
      pan                   |-> [i \in 1 .. 10 |-> 0],
      oldPan                |-> [i \in 1 .. 10 |-> 0],
      algoId                |-> [i \in 1 .. 4 |-> 0],
      reserved2             |-> [i \in 1 .. 2 |-> 0],
      lastActivityReference |-> [i \in 1 .. 8 |-> 0],
      nnfField              |-> [i \in 1 .. 8 |-> 0],
      reserved44            |-> [i \in 1 .. 44 |-> 0] ]

(* Trade Modify Confirm Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeModifyConfirmMessage ==
    { ZeroTradeModifyConfirmMessage }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.responseOrderNumber = one] : one \in Sample(8) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.traderNum = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.accountNum = one] : one \in Sample(10) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.buySell = one] : one \in Sample(2) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.originalVol = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.disclosedVol = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.remainingVol = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.disclosedVolRemaining = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.gtd = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.fillNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.fillQty = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.fillPrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.volFilledToday = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.activityType = one] : one \in Sample(2) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.activityTime = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.opOrderNumber = one] : one \in Sample(8) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.opBrokerId = one] : one \in Sample(5) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.secondReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.token = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.contractDesc = one] : one \in CheckedContractDesc4 }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.oldOpenClose = one] : one \in Sample(1) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.bookTypeChar1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.thirdReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.newVolume = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.oldAccountNumber = one] : one \in Sample(10) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.participant = one] : one \in Sample(12) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.oldParticipant = one] : one \in Sample(12) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.additionalOrderFlags = one] : one \in Sample(1) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.fourthReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.giveUpTrade = one] : one \in Sample(1) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.fifthReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.oldPan = one] : one \in Sample(10) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.lastActivityReference = one] : one \in Sample(8) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.reserved44 = one] : one \in Sample(44) }

(***************************************************************************)
(* Contract Desc: 28 bytes                                                 *)
(***************************************************************************)

ContractDesc5 ==
    [ instrumentName : Sample(6),
      symbol         : Sample(10),
      expiryDate     : Sample(4),
      strikePrice    : Sample(4),
      optionType     : Sample(2),
      caLevel        : Sample(2) ]

EncodeContractDesc5(message) ==
    message.instrumentName
        \o message.symbol
        \o message.expiryDate
        \o message.strikePrice
        \o message.optionType
        \o message.caLevel

DecodeContractDesc5(bytes) ==
    LET instrumentName == ReadBytes(bytes, 6) IN IF ~instrumentName.ok THEN Fail ELSE
    LET symbol == ReadBytes(instrumentName.rest, 10) IN IF ~symbol.ok THEN Fail ELSE
    LET expiryDate == ReadBytes(symbol.rest, 4) IN IF ~expiryDate.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(expiryDate.rest, 4) IN IF ~strikePrice.ok THEN Fail ELSE
    LET optionType == ReadBytes(strikePrice.rest, 2) IN IF ~optionType.ok THEN Fail ELSE
    LET caLevel == ReadBytes(optionType.rest, 2) IN IF ~caLevel.ok THEN Fail ELSE
    Ok([ instrumentName |-> instrumentName.value,
         symbol         |-> symbol.value,
         expiryDate     |-> expiryDate.value,
         strikePrice    |-> strikePrice.value,
         optionType     |-> optionType.value,
         caLevel        |-> caLevel.value ], caLevel.rest)

ZeroContractDesc5 ==
    [ instrumentName |-> [i \in 1 .. 6 |-> 0],
      symbol         |-> [i \in 1 .. 10 |-> 0],
      expiryDate     |-> [i \in 1 .. 4 |-> 0],
      strikePrice    |-> [i \in 1 .. 4 |-> 0],
      optionType     |-> [i \in 1 .. 2 |-> 0],
      caLevel        |-> [i \in 1 .. 2 |-> 0] ]

(* Contract Desc at zero, then each field in turn at the values it is checked at *)
CheckedContractDesc5 ==
    { ZeroContractDesc5 }
        \cup { [ZeroContractDesc5 EXCEPT !.instrumentName = one] : one \in Sample(6) }
        \cup { [ZeroContractDesc5 EXCEPT !.symbol = one] : one \in Sample(10) }
        \cup { [ZeroContractDesc5 EXCEPT !.expiryDate = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc5 EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc5 EXCEPT !.optionType = one] : one \in Sample(2) }
        \cup { [ZeroContractDesc5 EXCEPT !.caLevel = one] : one \in Sample(2) }

(***************************************************************************)
(* Trade Modify Reject Message: 256 bytes                                  *)
(***************************************************************************)

TradeModifyRejectMessage ==
    [ responseOrderNumber   : Sample(8),
      brokerId              : Sample(5),
      reserved1             : Sample(1),
      traderNum             : Sample(4),
      accountNum            : Sample(10),
      buySell               : Sample(2),
      originalVol           : Sample(4),
      disclosedVol          : Sample(4),
      remainingVol          : Sample(4),
      disclosedVolRemaining : Sample(4),
      price                 : Sample(4),
      stOrderFlags          : Sample(2),
      gtd                   : Sample(4),
      fillNumber            : Sample(4),
      fillQty               : Sample(4),
      fillPrice             : Sample(4),
      volFilledToday        : Sample(4),
      activityType          : Sample(2),
      activityTime          : Sample(4),
      opOrderNumber         : Sample(8),
      opBrokerId            : Sample(5),
      secondReserved1       : Sample(1),
      token                 : Sample(4),
      contractDesc          : ContractDesc5,
      openClose             : Sample(1),
      oldOpenClose          : Sample(1),
      bookTypeChar1         : Sample(1),
      thirdReserved1        : Sample(1),
      newVolume             : Sample(4),
      oldAccountNumber      : Sample(10),
      participant           : Sample(12),
      oldParticipant        : Sample(12),
      additionalOrderFlags  : Sample(1),
      fourthReserved1       : Sample(1),
      giveUpTrade           : Sample(1),
      fifthReserved1        : Sample(1),
      pan                   : Sample(10),
      oldPan                : Sample(10),
      algoId                : Sample(4),
      reserved2             : Sample(2),
      lastActivityReference : Sample(8),
      nnfField              : Sample(8),
      reserved44            : Sample(44) ]

EncodeTradeModifyRejectMessage(message) ==
    message.responseOrderNumber
        \o message.brokerId
        \o message.reserved1
        \o message.traderNum
        \o message.accountNum
        \o message.buySell
        \o message.originalVol
        \o message.disclosedVol
        \o message.remainingVol
        \o message.disclosedVolRemaining
        \o message.price
        \o message.stOrderFlags
        \o message.gtd
        \o message.fillNumber
        \o message.fillQty
        \o message.fillPrice
        \o message.volFilledToday
        \o message.activityType
        \o message.activityTime
        \o message.opOrderNumber
        \o message.opBrokerId
        \o message.secondReserved1
        \o message.token
        \o EncodeContractDesc5(message.contractDesc)
        \o message.openClose
        \o message.oldOpenClose
        \o message.bookTypeChar1
        \o message.thirdReserved1
        \o message.newVolume
        \o message.oldAccountNumber
        \o message.participant
        \o message.oldParticipant
        \o message.additionalOrderFlags
        \o message.fourthReserved1
        \o message.giveUpTrade
        \o message.fifthReserved1
        \o message.pan
        \o message.oldPan
        \o message.algoId
        \o message.reserved2
        \o message.lastActivityReference
        \o message.nnfField
        \o message.reserved44

DecodeTradeModifyRejectMessage(bytes) ==
    LET responseOrderNumber == ReadBytes(bytes, 8) IN IF ~responseOrderNumber.ok THEN Fail ELSE
    LET brokerId == ReadBytes(responseOrderNumber.rest, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(brokerId.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET traderNum == ReadBytes(reserved1.rest, 4) IN IF ~traderNum.ok THEN Fail ELSE
    LET accountNum == ReadBytes(traderNum.rest, 10) IN IF ~accountNum.ok THEN Fail ELSE
    LET buySell == ReadBytes(accountNum.rest, 2) IN IF ~buySell.ok THEN Fail ELSE
    LET originalVol == ReadBytes(buySell.rest, 4) IN IF ~originalVol.ok THEN Fail ELSE
    LET disclosedVol == ReadBytes(originalVol.rest, 4) IN IF ~disclosedVol.ok THEN Fail ELSE
    LET remainingVol == ReadBytes(disclosedVol.rest, 4) IN IF ~remainingVol.ok THEN Fail ELSE
    LET disclosedVolRemaining == ReadBytes(remainingVol.rest, 4) IN IF ~disclosedVolRemaining.ok THEN Fail ELSE
    LET price == ReadBytes(disclosedVolRemaining.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(price.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET gtd == ReadBytes(stOrderFlags.rest, 4) IN IF ~gtd.ok THEN Fail ELSE
    LET fillNumber == ReadBytes(gtd.rest, 4) IN IF ~fillNumber.ok THEN Fail ELSE
    LET fillQty == ReadBytes(fillNumber.rest, 4) IN IF ~fillQty.ok THEN Fail ELSE
    LET fillPrice == ReadBytes(fillQty.rest, 4) IN IF ~fillPrice.ok THEN Fail ELSE
    LET volFilledToday == ReadBytes(fillPrice.rest, 4) IN IF ~volFilledToday.ok THEN Fail ELSE
    LET activityType == ReadBytes(volFilledToday.rest, 2) IN IF ~activityType.ok THEN Fail ELSE
    LET activityTime == ReadBytes(activityType.rest, 4) IN IF ~activityTime.ok THEN Fail ELSE
    LET opOrderNumber == ReadBytes(activityTime.rest, 8) IN IF ~opOrderNumber.ok THEN Fail ELSE
    LET opBrokerId == ReadBytes(opOrderNumber.rest, 5) IN IF ~opBrokerId.ok THEN Fail ELSE
    LET secondReserved1 == ReadBytes(opBrokerId.rest, 1) IN IF ~secondReserved1.ok THEN Fail ELSE
    LET token == ReadBytes(secondReserved1.rest, 4) IN IF ~token.ok THEN Fail ELSE
    LET contractDesc == DecodeContractDesc5(token.rest) IN IF ~contractDesc.ok THEN Fail ELSE
    LET openClose == ReadBytes(contractDesc.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET oldOpenClose == ReadBytes(openClose.rest, 1) IN IF ~oldOpenClose.ok THEN Fail ELSE
    LET bookTypeChar1 == ReadBytes(oldOpenClose.rest, 1) IN IF ~bookTypeChar1.ok THEN Fail ELSE
    LET thirdReserved1 == ReadBytes(bookTypeChar1.rest, 1) IN IF ~thirdReserved1.ok THEN Fail ELSE
    LET newVolume == ReadBytes(thirdReserved1.rest, 4) IN IF ~newVolume.ok THEN Fail ELSE
    LET oldAccountNumber == ReadBytes(newVolume.rest, 10) IN IF ~oldAccountNumber.ok THEN Fail ELSE
    LET participant == ReadBytes(oldAccountNumber.rest, 12) IN IF ~participant.ok THEN Fail ELSE
    LET oldParticipant == ReadBytes(participant.rest, 12) IN IF ~oldParticipant.ok THEN Fail ELSE
    LET additionalOrderFlags == ReadBytes(oldParticipant.rest, 1) IN IF ~additionalOrderFlags.ok THEN Fail ELSE
    LET fourthReserved1 == ReadBytes(additionalOrderFlags.rest, 1) IN IF ~fourthReserved1.ok THEN Fail ELSE
    LET giveUpTrade == ReadBytes(fourthReserved1.rest, 1) IN IF ~giveUpTrade.ok THEN Fail ELSE
    LET fifthReserved1 == ReadBytes(giveUpTrade.rest, 1) IN IF ~fifthReserved1.ok THEN Fail ELSE
    LET pan == ReadBytes(fifthReserved1.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET oldPan == ReadBytes(pan.rest, 10) IN IF ~oldPan.ok THEN Fail ELSE
    LET algoId == ReadBytes(oldPan.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(algoId.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET lastActivityReference == ReadBytes(reserved2.rest, 8) IN IF ~lastActivityReference.ok THEN Fail ELSE
    LET nnfField == ReadBytes(lastActivityReference.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET reserved44 == ReadBytes(nnfField.rest, 44) IN IF ~reserved44.ok THEN Fail ELSE
    Ok([ responseOrderNumber   |-> responseOrderNumber.value,
         brokerId              |-> brokerId.value,
         reserved1             |-> reserved1.value,
         traderNum             |-> traderNum.value,
         accountNum            |-> accountNum.value,
         buySell               |-> buySell.value,
         originalVol           |-> originalVol.value,
         disclosedVol          |-> disclosedVol.value,
         remainingVol          |-> remainingVol.value,
         disclosedVolRemaining |-> disclosedVolRemaining.value,
         price                 |-> price.value,
         stOrderFlags          |-> stOrderFlags.value,
         gtd                   |-> gtd.value,
         fillNumber            |-> fillNumber.value,
         fillQty               |-> fillQty.value,
         fillPrice             |-> fillPrice.value,
         volFilledToday        |-> volFilledToday.value,
         activityType          |-> activityType.value,
         activityTime          |-> activityTime.value,
         opOrderNumber         |-> opOrderNumber.value,
         opBrokerId            |-> opBrokerId.value,
         secondReserved1       |-> secondReserved1.value,
         token                 |-> token.value,
         contractDesc          |-> contractDesc.value,
         openClose             |-> openClose.value,
         oldOpenClose          |-> oldOpenClose.value,
         bookTypeChar1         |-> bookTypeChar1.value,
         thirdReserved1        |-> thirdReserved1.value,
         newVolume             |-> newVolume.value,
         oldAccountNumber      |-> oldAccountNumber.value,
         participant           |-> participant.value,
         oldParticipant        |-> oldParticipant.value,
         additionalOrderFlags  |-> additionalOrderFlags.value,
         fourthReserved1       |-> fourthReserved1.value,
         giveUpTrade           |-> giveUpTrade.value,
         fifthReserved1        |-> fifthReserved1.value,
         pan                   |-> pan.value,
         oldPan                |-> oldPan.value,
         algoId                |-> algoId.value,
         reserved2             |-> reserved2.value,
         lastActivityReference |-> lastActivityReference.value,
         nnfField              |-> nnfField.value,
         reserved44            |-> reserved44.value ], reserved44.rest)

ZeroTradeModifyRejectMessage ==
    [ responseOrderNumber   |-> [i \in 1 .. 8 |-> 0],
      brokerId              |-> [i \in 1 .. 5 |-> 0],
      reserved1             |-> [i \in 1 .. 1 |-> 0],
      traderNum             |-> [i \in 1 .. 4 |-> 0],
      accountNum            |-> [i \in 1 .. 10 |-> 0],
      buySell               |-> [i \in 1 .. 2 |-> 0],
      originalVol           |-> [i \in 1 .. 4 |-> 0],
      disclosedVol          |-> [i \in 1 .. 4 |-> 0],
      remainingVol          |-> [i \in 1 .. 4 |-> 0],
      disclosedVolRemaining |-> [i \in 1 .. 4 |-> 0],
      price                 |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags          |-> [i \in 1 .. 2 |-> 0],
      gtd                   |-> [i \in 1 .. 4 |-> 0],
      fillNumber            |-> [i \in 1 .. 4 |-> 0],
      fillQty               |-> [i \in 1 .. 4 |-> 0],
      fillPrice             |-> [i \in 1 .. 4 |-> 0],
      volFilledToday        |-> [i \in 1 .. 4 |-> 0],
      activityType          |-> [i \in 1 .. 2 |-> 0],
      activityTime          |-> [i \in 1 .. 4 |-> 0],
      opOrderNumber         |-> [i \in 1 .. 8 |-> 0],
      opBrokerId            |-> [i \in 1 .. 5 |-> 0],
      secondReserved1       |-> [i \in 1 .. 1 |-> 0],
      token                 |-> [i \in 1 .. 4 |-> 0],
      contractDesc          |-> ZeroContractDesc5,
      openClose             |-> [i \in 1 .. 1 |-> 0],
      oldOpenClose          |-> [i \in 1 .. 1 |-> 0],
      bookTypeChar1         |-> [i \in 1 .. 1 |-> 0],
      thirdReserved1        |-> [i \in 1 .. 1 |-> 0],
      newVolume             |-> [i \in 1 .. 4 |-> 0],
      oldAccountNumber      |-> [i \in 1 .. 10 |-> 0],
      participant           |-> [i \in 1 .. 12 |-> 0],
      oldParticipant        |-> [i \in 1 .. 12 |-> 0],
      additionalOrderFlags  |-> [i \in 1 .. 1 |-> 0],
      fourthReserved1       |-> [i \in 1 .. 1 |-> 0],
      giveUpTrade           |-> [i \in 1 .. 1 |-> 0],
      fifthReserved1        |-> [i \in 1 .. 1 |-> 0],
      pan                   |-> [i \in 1 .. 10 |-> 0],
      oldPan                |-> [i \in 1 .. 10 |-> 0],
      algoId                |-> [i \in 1 .. 4 |-> 0],
      reserved2             |-> [i \in 1 .. 2 |-> 0],
      lastActivityReference |-> [i \in 1 .. 8 |-> 0],
      nnfField              |-> [i \in 1 .. 8 |-> 0],
      reserved44            |-> [i \in 1 .. 44 |-> 0] ]

(* Trade Modify Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeModifyRejectMessage ==
    { ZeroTradeModifyRejectMessage }
        \cup { [ZeroTradeModifyRejectMessage EXCEPT !.responseOrderNumber = one] : one \in Sample(8) }
        \cup { [ZeroTradeModifyRejectMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroTradeModifyRejectMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeModifyRejectMessage EXCEPT !.traderNum = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyRejectMessage EXCEPT !.accountNum = one] : one \in Sample(10) }
        \cup { [ZeroTradeModifyRejectMessage EXCEPT !.buySell = one] : one \in Sample(2) }
        \cup { [ZeroTradeModifyRejectMessage EXCEPT !.originalVol = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyRejectMessage EXCEPT !.disclosedVol = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyRejectMessage EXCEPT !.remainingVol = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyRejectMessage EXCEPT !.disclosedVolRemaining = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyRejectMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyRejectMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroTradeModifyRejectMessage EXCEPT !.gtd = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyRejectMessage EXCEPT !.fillNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyRejectMessage EXCEPT !.fillQty = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyRejectMessage EXCEPT !.fillPrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyRejectMessage EXCEPT !.volFilledToday = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyRejectMessage EXCEPT !.activityType = one] : one \in Sample(2) }
        \cup { [ZeroTradeModifyRejectMessage EXCEPT !.activityTime = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyRejectMessage EXCEPT !.opOrderNumber = one] : one \in Sample(8) }
        \cup { [ZeroTradeModifyRejectMessage EXCEPT !.opBrokerId = one] : one \in Sample(5) }
        \cup { [ZeroTradeModifyRejectMessage EXCEPT !.secondReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeModifyRejectMessage EXCEPT !.token = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyRejectMessage EXCEPT !.contractDesc = one] : one \in CheckedContractDesc5 }
        \cup { [ZeroTradeModifyRejectMessage EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroTradeModifyRejectMessage EXCEPT !.oldOpenClose = one] : one \in Sample(1) }
        \cup { [ZeroTradeModifyRejectMessage EXCEPT !.bookTypeChar1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeModifyRejectMessage EXCEPT !.thirdReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeModifyRejectMessage EXCEPT !.newVolume = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyRejectMessage EXCEPT !.oldAccountNumber = one] : one \in Sample(10) }
        \cup { [ZeroTradeModifyRejectMessage EXCEPT !.participant = one] : one \in Sample(12) }
        \cup { [ZeroTradeModifyRejectMessage EXCEPT !.oldParticipant = one] : one \in Sample(12) }
        \cup { [ZeroTradeModifyRejectMessage EXCEPT !.additionalOrderFlags = one] : one \in Sample(1) }
        \cup { [ZeroTradeModifyRejectMessage EXCEPT !.fourthReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeModifyRejectMessage EXCEPT !.giveUpTrade = one] : one \in Sample(1) }
        \cup { [ZeroTradeModifyRejectMessage EXCEPT !.fifthReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeModifyRejectMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroTradeModifyRejectMessage EXCEPT !.oldPan = one] : one \in Sample(10) }
        \cup { [ZeroTradeModifyRejectMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyRejectMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroTradeModifyRejectMessage EXCEPT !.lastActivityReference = one] : one \in Sample(8) }
        \cup { [ZeroTradeModifyRejectMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroTradeModifyRejectMessage EXCEPT !.reserved44 = one] : one \in Sample(44) }

(***************************************************************************)
(* Giveup App Confirm Tm Message: 82 bytes                                 *)
(***************************************************************************)

GiveupAppConfirmTmMessage ==
    [ reasonCode           : Sample(2),
      orderNumber          : Sample(8),
      fillNumber           : Sample(4),
      instrumentName       : Sample(6),
      symbol               : Sample(10),
      expiryDate           : Sample(4),
      strikePrice          : Sample(4),
      optionType           : Sample(2),
      caLevel              : Sample(2),
      fillVolume           : Sample(4),
      fillPrice            : Sample(4),
      brokerId             : Sample(5),
      filler               : Sample(1),
      buySell              : Sample(2),
      bookTypeShort2       : Sample(2),
      lastModifiedDateTime : Sample(4),
      initiatedByControl   : Sample(1),
      openClose            : Sample(1),
      reserved1            : Sample(1),
      participant          : Sample(12),
      giveupFlag           : Sample(1),
      deleted              : Sample(1),
      secondReserved1      : Sample(1) ]

EncodeGiveupAppConfirmTmMessage(message) ==
    message.reasonCode
        \o message.orderNumber
        \o message.fillNumber
        \o message.instrumentName
        \o message.symbol
        \o message.expiryDate
        \o message.strikePrice
        \o message.optionType
        \o message.caLevel
        \o message.fillVolume
        \o message.fillPrice
        \o message.brokerId
        \o message.filler
        \o message.buySell
        \o message.bookTypeShort2
        \o message.lastModifiedDateTime
        \o message.initiatedByControl
        \o message.openClose
        \o message.reserved1
        \o message.participant
        \o message.giveupFlag
        \o message.deleted
        \o message.secondReserved1

DecodeGiveupAppConfirmTmMessage(bytes) ==
    LET reasonCode == ReadBytes(bytes, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(reasonCode.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET fillNumber == ReadBytes(orderNumber.rest, 4) IN IF ~fillNumber.ok THEN Fail ELSE
    LET instrumentName == ReadBytes(fillNumber.rest, 6) IN IF ~instrumentName.ok THEN Fail ELSE
    LET symbol == ReadBytes(instrumentName.rest, 10) IN IF ~symbol.ok THEN Fail ELSE
    LET expiryDate == ReadBytes(symbol.rest, 4) IN IF ~expiryDate.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(expiryDate.rest, 4) IN IF ~strikePrice.ok THEN Fail ELSE
    LET optionType == ReadBytes(strikePrice.rest, 2) IN IF ~optionType.ok THEN Fail ELSE
    LET caLevel == ReadBytes(optionType.rest, 2) IN IF ~caLevel.ok THEN Fail ELSE
    LET fillVolume == ReadBytes(caLevel.rest, 4) IN IF ~fillVolume.ok THEN Fail ELSE
    LET fillPrice == ReadBytes(fillVolume.rest, 4) IN IF ~fillPrice.ok THEN Fail ELSE
    LET brokerId == ReadBytes(fillPrice.rest, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET filler == ReadBytes(brokerId.rest, 1) IN IF ~filler.ok THEN Fail ELSE
    LET buySell == ReadBytes(filler.rest, 2) IN IF ~buySell.ok THEN Fail ELSE
    LET bookTypeShort2 == ReadBytes(buySell.rest, 2) IN IF ~bookTypeShort2.ok THEN Fail ELSE
    LET lastModifiedDateTime == ReadBytes(bookTypeShort2.rest, 4) IN IF ~lastModifiedDateTime.ok THEN Fail ELSE
    LET initiatedByControl == ReadBytes(lastModifiedDateTime.rest, 1) IN IF ~initiatedByControl.ok THEN Fail ELSE
    LET openClose == ReadBytes(initiatedByControl.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(openClose.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET participant == ReadBytes(reserved1.rest, 12) IN IF ~participant.ok THEN Fail ELSE
    LET giveupFlag == ReadBytes(participant.rest, 1) IN IF ~giveupFlag.ok THEN Fail ELSE
    LET deleted == ReadBytes(giveupFlag.rest, 1) IN IF ~deleted.ok THEN Fail ELSE
    LET secondReserved1 == ReadBytes(deleted.rest, 1) IN IF ~secondReserved1.ok THEN Fail ELSE
    Ok([ reasonCode           |-> reasonCode.value,
         orderNumber          |-> orderNumber.value,
         fillNumber           |-> fillNumber.value,
         instrumentName       |-> instrumentName.value,
         symbol               |-> symbol.value,
         expiryDate           |-> expiryDate.value,
         strikePrice          |-> strikePrice.value,
         optionType           |-> optionType.value,
         caLevel              |-> caLevel.value,
         fillVolume           |-> fillVolume.value,
         fillPrice            |-> fillPrice.value,
         brokerId             |-> brokerId.value,
         filler               |-> filler.value,
         buySell              |-> buySell.value,
         bookTypeShort2       |-> bookTypeShort2.value,
         lastModifiedDateTime |-> lastModifiedDateTime.value,
         initiatedByControl   |-> initiatedByControl.value,
         openClose            |-> openClose.value,
         reserved1            |-> reserved1.value,
         participant          |-> participant.value,
         giveupFlag           |-> giveupFlag.value,
         deleted              |-> deleted.value,
         secondReserved1      |-> secondReserved1.value ], secondReserved1.rest)

ZeroGiveupAppConfirmTmMessage ==
    [ reasonCode           |-> [i \in 1 .. 2 |-> 0],
      orderNumber          |-> [i \in 1 .. 8 |-> 0],
      fillNumber           |-> [i \in 1 .. 4 |-> 0],
      instrumentName       |-> [i \in 1 .. 6 |-> 0],
      symbol               |-> [i \in 1 .. 10 |-> 0],
      expiryDate           |-> [i \in 1 .. 4 |-> 0],
      strikePrice          |-> [i \in 1 .. 4 |-> 0],
      optionType           |-> [i \in 1 .. 2 |-> 0],
      caLevel              |-> [i \in 1 .. 2 |-> 0],
      fillVolume           |-> [i \in 1 .. 4 |-> 0],
      fillPrice            |-> [i \in 1 .. 4 |-> 0],
      brokerId             |-> [i \in 1 .. 5 |-> 0],
      filler               |-> [i \in 1 .. 1 |-> 0],
      buySell              |-> [i \in 1 .. 2 |-> 0],
      bookTypeShort2       |-> [i \in 1 .. 2 |-> 0],
      lastModifiedDateTime |-> [i \in 1 .. 4 |-> 0],
      initiatedByControl   |-> [i \in 1 .. 1 |-> 0],
      openClose            |-> [i \in 1 .. 1 |-> 0],
      reserved1            |-> [i \in 1 .. 1 |-> 0],
      participant          |-> [i \in 1 .. 12 |-> 0],
      giveupFlag           |-> [i \in 1 .. 1 |-> 0],
      deleted              |-> [i \in 1 .. 1 |-> 0],
      secondReserved1      |-> [i \in 1 .. 1 |-> 0] ]

(* Giveup App Confirm Tm Message at zero, then each field in turn at the values it is checked at *)
CheckedGiveupAppConfirmTmMessage ==
    { ZeroGiveupAppConfirmTmMessage }
        \cup { [ZeroGiveupAppConfirmTmMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroGiveupAppConfirmTmMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroGiveupAppConfirmTmMessage EXCEPT !.fillNumber = one] : one \in Sample(4) }
        \cup { [ZeroGiveupAppConfirmTmMessage EXCEPT !.instrumentName = one] : one \in Sample(6) }
        \cup { [ZeroGiveupAppConfirmTmMessage EXCEPT !.symbol = one] : one \in Sample(10) }
        \cup { [ZeroGiveupAppConfirmTmMessage EXCEPT !.expiryDate = one] : one \in Sample(4) }
        \cup { [ZeroGiveupAppConfirmTmMessage EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroGiveupAppConfirmTmMessage EXCEPT !.optionType = one] : one \in Sample(2) }
        \cup { [ZeroGiveupAppConfirmTmMessage EXCEPT !.caLevel = one] : one \in Sample(2) }
        \cup { [ZeroGiveupAppConfirmTmMessage EXCEPT !.fillVolume = one] : one \in Sample(4) }
        \cup { [ZeroGiveupAppConfirmTmMessage EXCEPT !.fillPrice = one] : one \in Sample(4) }
        \cup { [ZeroGiveupAppConfirmTmMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroGiveupAppConfirmTmMessage EXCEPT !.filler = one] : one \in Sample(1) }
        \cup { [ZeroGiveupAppConfirmTmMessage EXCEPT !.buySell = one] : one \in Sample(2) }
        \cup { [ZeroGiveupAppConfirmTmMessage EXCEPT !.bookTypeShort2 = one] : one \in Sample(2) }
        \cup { [ZeroGiveupAppConfirmTmMessage EXCEPT !.lastModifiedDateTime = one] : one \in Sample(4) }
        \cup { [ZeroGiveupAppConfirmTmMessage EXCEPT !.initiatedByControl = one] : one \in Sample(1) }
        \cup { [ZeroGiveupAppConfirmTmMessage EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroGiveupAppConfirmTmMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroGiveupAppConfirmTmMessage EXCEPT !.participant = one] : one \in Sample(12) }
        \cup { [ZeroGiveupAppConfirmTmMessage EXCEPT !.giveupFlag = one] : one \in Sample(1) }
        \cup { [ZeroGiveupAppConfirmTmMessage EXCEPT !.deleted = one] : one \in Sample(1) }
        \cup { [ZeroGiveupAppConfirmTmMessage EXCEPT !.secondReserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Giveup Rej Confirm Tm Message: 82 bytes                                 *)
(***************************************************************************)

GiveupRejConfirmTmMessage ==
    [ reasonCode           : Sample(2),
      orderNumber          : Sample(8),
      fillNumber           : Sample(4),
      instrumentName       : Sample(6),
      symbol               : Sample(10),
      expiryDate           : Sample(4),
      strikePrice          : Sample(4),
      optionType           : Sample(2),
      caLevel              : Sample(2),
      fillVolume           : Sample(4),
      fillPrice            : Sample(4),
      brokerId             : Sample(5),
      filler               : Sample(1),
      buySell              : Sample(2),
      bookTypeShort2       : Sample(2),
      lastModifiedDateTime : Sample(4),
      initiatedByControl   : Sample(1),
      openClose            : Sample(1),
      reserved1            : Sample(1),
      participant          : Sample(12),
      giveupFlag           : Sample(1),
      deleted              : Sample(1),
      secondReserved1      : Sample(1) ]

EncodeGiveupRejConfirmTmMessage(message) ==
    message.reasonCode
        \o message.orderNumber
        \o message.fillNumber
        \o message.instrumentName
        \o message.symbol
        \o message.expiryDate
        \o message.strikePrice
        \o message.optionType
        \o message.caLevel
        \o message.fillVolume
        \o message.fillPrice
        \o message.brokerId
        \o message.filler
        \o message.buySell
        \o message.bookTypeShort2
        \o message.lastModifiedDateTime
        \o message.initiatedByControl
        \o message.openClose
        \o message.reserved1
        \o message.participant
        \o message.giveupFlag
        \o message.deleted
        \o message.secondReserved1

DecodeGiveupRejConfirmTmMessage(bytes) ==
    LET reasonCode == ReadBytes(bytes, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(reasonCode.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET fillNumber == ReadBytes(orderNumber.rest, 4) IN IF ~fillNumber.ok THEN Fail ELSE
    LET instrumentName == ReadBytes(fillNumber.rest, 6) IN IF ~instrumentName.ok THEN Fail ELSE
    LET symbol == ReadBytes(instrumentName.rest, 10) IN IF ~symbol.ok THEN Fail ELSE
    LET expiryDate == ReadBytes(symbol.rest, 4) IN IF ~expiryDate.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(expiryDate.rest, 4) IN IF ~strikePrice.ok THEN Fail ELSE
    LET optionType == ReadBytes(strikePrice.rest, 2) IN IF ~optionType.ok THEN Fail ELSE
    LET caLevel == ReadBytes(optionType.rest, 2) IN IF ~caLevel.ok THEN Fail ELSE
    LET fillVolume == ReadBytes(caLevel.rest, 4) IN IF ~fillVolume.ok THEN Fail ELSE
    LET fillPrice == ReadBytes(fillVolume.rest, 4) IN IF ~fillPrice.ok THEN Fail ELSE
    LET brokerId == ReadBytes(fillPrice.rest, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET filler == ReadBytes(brokerId.rest, 1) IN IF ~filler.ok THEN Fail ELSE
    LET buySell == ReadBytes(filler.rest, 2) IN IF ~buySell.ok THEN Fail ELSE
    LET bookTypeShort2 == ReadBytes(buySell.rest, 2) IN IF ~bookTypeShort2.ok THEN Fail ELSE
    LET lastModifiedDateTime == ReadBytes(bookTypeShort2.rest, 4) IN IF ~lastModifiedDateTime.ok THEN Fail ELSE
    LET initiatedByControl == ReadBytes(lastModifiedDateTime.rest, 1) IN IF ~initiatedByControl.ok THEN Fail ELSE
    LET openClose == ReadBytes(initiatedByControl.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(openClose.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET participant == ReadBytes(reserved1.rest, 12) IN IF ~participant.ok THEN Fail ELSE
    LET giveupFlag == ReadBytes(participant.rest, 1) IN IF ~giveupFlag.ok THEN Fail ELSE
    LET deleted == ReadBytes(giveupFlag.rest, 1) IN IF ~deleted.ok THEN Fail ELSE
    LET secondReserved1 == ReadBytes(deleted.rest, 1) IN IF ~secondReserved1.ok THEN Fail ELSE
    Ok([ reasonCode           |-> reasonCode.value,
         orderNumber          |-> orderNumber.value,
         fillNumber           |-> fillNumber.value,
         instrumentName       |-> instrumentName.value,
         symbol               |-> symbol.value,
         expiryDate           |-> expiryDate.value,
         strikePrice          |-> strikePrice.value,
         optionType           |-> optionType.value,
         caLevel              |-> caLevel.value,
         fillVolume           |-> fillVolume.value,
         fillPrice            |-> fillPrice.value,
         brokerId             |-> brokerId.value,
         filler               |-> filler.value,
         buySell              |-> buySell.value,
         bookTypeShort2       |-> bookTypeShort2.value,
         lastModifiedDateTime |-> lastModifiedDateTime.value,
         initiatedByControl   |-> initiatedByControl.value,
         openClose            |-> openClose.value,
         reserved1            |-> reserved1.value,
         participant          |-> participant.value,
         giveupFlag           |-> giveupFlag.value,
         deleted              |-> deleted.value,
         secondReserved1      |-> secondReserved1.value ], secondReserved1.rest)

ZeroGiveupRejConfirmTmMessage ==
    [ reasonCode           |-> [i \in 1 .. 2 |-> 0],
      orderNumber          |-> [i \in 1 .. 8 |-> 0],
      fillNumber           |-> [i \in 1 .. 4 |-> 0],
      instrumentName       |-> [i \in 1 .. 6 |-> 0],
      symbol               |-> [i \in 1 .. 10 |-> 0],
      expiryDate           |-> [i \in 1 .. 4 |-> 0],
      strikePrice          |-> [i \in 1 .. 4 |-> 0],
      optionType           |-> [i \in 1 .. 2 |-> 0],
      caLevel              |-> [i \in 1 .. 2 |-> 0],
      fillVolume           |-> [i \in 1 .. 4 |-> 0],
      fillPrice            |-> [i \in 1 .. 4 |-> 0],
      brokerId             |-> [i \in 1 .. 5 |-> 0],
      filler               |-> [i \in 1 .. 1 |-> 0],
      buySell              |-> [i \in 1 .. 2 |-> 0],
      bookTypeShort2       |-> [i \in 1 .. 2 |-> 0],
      lastModifiedDateTime |-> [i \in 1 .. 4 |-> 0],
      initiatedByControl   |-> [i \in 1 .. 1 |-> 0],
      openClose            |-> [i \in 1 .. 1 |-> 0],
      reserved1            |-> [i \in 1 .. 1 |-> 0],
      participant          |-> [i \in 1 .. 12 |-> 0],
      giveupFlag           |-> [i \in 1 .. 1 |-> 0],
      deleted              |-> [i \in 1 .. 1 |-> 0],
      secondReserved1      |-> [i \in 1 .. 1 |-> 0] ]

(* Giveup Rej Confirm Tm Message at zero, then each field in turn at the values it is checked at *)
CheckedGiveupRejConfirmTmMessage ==
    { ZeroGiveupRejConfirmTmMessage }
        \cup { [ZeroGiveupRejConfirmTmMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroGiveupRejConfirmTmMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroGiveupRejConfirmTmMessage EXCEPT !.fillNumber = one] : one \in Sample(4) }
        \cup { [ZeroGiveupRejConfirmTmMessage EXCEPT !.instrumentName = one] : one \in Sample(6) }
        \cup { [ZeroGiveupRejConfirmTmMessage EXCEPT !.symbol = one] : one \in Sample(10) }
        \cup { [ZeroGiveupRejConfirmTmMessage EXCEPT !.expiryDate = one] : one \in Sample(4) }
        \cup { [ZeroGiveupRejConfirmTmMessage EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroGiveupRejConfirmTmMessage EXCEPT !.optionType = one] : one \in Sample(2) }
        \cup { [ZeroGiveupRejConfirmTmMessage EXCEPT !.caLevel = one] : one \in Sample(2) }
        \cup { [ZeroGiveupRejConfirmTmMessage EXCEPT !.fillVolume = one] : one \in Sample(4) }
        \cup { [ZeroGiveupRejConfirmTmMessage EXCEPT !.fillPrice = one] : one \in Sample(4) }
        \cup { [ZeroGiveupRejConfirmTmMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroGiveupRejConfirmTmMessage EXCEPT !.filler = one] : one \in Sample(1) }
        \cup { [ZeroGiveupRejConfirmTmMessage EXCEPT !.buySell = one] : one \in Sample(2) }
        \cup { [ZeroGiveupRejConfirmTmMessage EXCEPT !.bookTypeShort2 = one] : one \in Sample(2) }
        \cup { [ZeroGiveupRejConfirmTmMessage EXCEPT !.lastModifiedDateTime = one] : one \in Sample(4) }
        \cup { [ZeroGiveupRejConfirmTmMessage EXCEPT !.initiatedByControl = one] : one \in Sample(1) }
        \cup { [ZeroGiveupRejConfirmTmMessage EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroGiveupRejConfirmTmMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroGiveupRejConfirmTmMessage EXCEPT !.participant = one] : one \in Sample(12) }
        \cup { [ZeroGiveupRejConfirmTmMessage EXCEPT !.giveupFlag = one] : one \in Sample(1) }
        \cup { [ZeroGiveupRejConfirmTmMessage EXCEPT !.deleted = one] : one \in Sample(1) }
        \cup { [ZeroGiveupRejConfirmTmMessage EXCEPT !.secondReserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Server Message Payload, selected by Transaction Code                    *)
(***************************************************************************)

SignOnOutMessageCode == 2301  \* 0x8fd
TradeConfirmationMessageCode == 2222  \* 0x8ae
TradeCancelConfirmMessageCode == 2282  \* 0x8ea
TradeCancelRejectMessageCode == 2286  \* 0x8ee
TradeModifyConfirmMessageCode == 2287  \* 0x8ef
TradeModifyRejectMessageCode == 2288  \* 0x8f0
GiveupAppConfirmTmMessageCode == 4506  \* 0x119a
GiveupRejConfirmTmMessageCode == 4507  \* 0x119b

ServerMessagePayload ==
    [ tag : {SignOnOutMessageCode}, body : SignOnOutMessage ]
        \cup [ tag : {TradeConfirmationMessageCode}, body : TradeConfirmationMessage ]
        \cup [ tag : {TradeCancelConfirmMessageCode}, body : TradeCancelConfirmMessage ]
        \cup [ tag : {TradeCancelRejectMessageCode}, body : TradeCancelRejectMessage ]
        \cup [ tag : {TradeModifyConfirmMessageCode}, body : TradeModifyConfirmMessage ]
        \cup [ tag : {TradeModifyRejectMessageCode}, body : TradeModifyRejectMessage ]
        \cup [ tag : {GiveupAppConfirmTmMessageCode}, body : GiveupAppConfirmTmMessage ]
        \cup [ tag : {GiveupRejConfirmTmMessageCode}, body : GiveupRejConfirmTmMessage ]

EncodeServerMessagePayload(message) ==
    CASE message.tag = SignOnOutMessageCode -> EncodeSignOnOutMessage(message.body)
      [] message.tag = TradeConfirmationMessageCode -> EncodeTradeConfirmationMessage(message.body)
      [] message.tag = TradeCancelConfirmMessageCode -> EncodeTradeCancelConfirmMessage(message.body)
      [] message.tag = TradeCancelRejectMessageCode -> EncodeTradeCancelRejectMessage(message.body)
      [] message.tag = TradeModifyConfirmMessageCode -> EncodeTradeModifyConfirmMessage(message.body)
      [] message.tag = TradeModifyRejectMessageCode -> EncodeTradeModifyRejectMessage(message.body)
      [] message.tag = GiveupAppConfirmTmMessageCode -> EncodeGiveupAppConfirmTmMessage(message.body)
      [] message.tag = GiveupRejConfirmTmMessageCode -> EncodeGiveupRejConfirmTmMessage(message.body)

DecodeServerMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = SignOnOutMessageCode -> DecodeSignOnOutMessage(bytes)
              [] tag = TradeConfirmationMessageCode -> DecodeTradeConfirmationMessage(bytes)
              [] tag = TradeCancelConfirmMessageCode -> DecodeTradeCancelConfirmMessage(bytes)
              [] tag = TradeCancelRejectMessageCode -> DecodeTradeCancelRejectMessage(bytes)
              [] tag = TradeModifyConfirmMessageCode -> DecodeTradeModifyConfirmMessage(bytes)
              [] tag = TradeModifyRejectMessageCode -> DecodeTradeModifyRejectMessage(bytes)
              [] tag = GiveupAppConfirmTmMessageCode -> DecodeGiveupAppConfirmTmMessage(bytes)
              [] tag = GiveupRejConfirmTmMessageCode -> DecodeGiveupRejConfirmTmMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroServerMessagePayload == [tag |-> SignOnOutMessageCode, body |-> ZeroSignOnOutMessage]

(* Each Server Message Payload in turn, at the values the message it names is checked at *)
CheckedServerMessagePayload ==
    { [tag |-> SignOnOutMessageCode, body |-> one] : one \in CheckedSignOnOutMessage }
        \cup { [tag |-> TradeConfirmationMessageCode, body |-> one] : one \in CheckedTradeConfirmationMessage }
        \cup { [tag |-> TradeCancelConfirmMessageCode, body |-> one] : one \in CheckedTradeCancelConfirmMessage }
        \cup { [tag |-> TradeCancelRejectMessageCode, body |-> one] : one \in CheckedTradeCancelRejectMessage }
        \cup { [tag |-> TradeModifyConfirmMessageCode, body |-> one] : one \in CheckedTradeModifyConfirmMessage }
        \cup { [tag |-> TradeModifyRejectMessageCode, body |-> one] : one \in CheckedTradeModifyRejectMessage }
        \cup { [tag |-> GiveupAppConfirmTmMessageCode, body |-> one] : one \in CheckedGiveupAppConfirmTmMessage }
        \cup { [tag |-> GiveupRejConfirmTmMessageCode, body |-> one] : one \in CheckedGiveupRejConfirmTmMessage }

(***************************************************************************)
(* Server Direct Packet, framed by Packet Length                           *)
(***************************************************************************)

ServerDirectPacket ==
    [ packetSequenceNumber : Sample(4),
      checksum             : Sample(16),
      logTime              : Sample(4),
      alphaChar            : Sample(2),
      traderId             : Sample(4),
      errorCode            : Sample(2),
      headerTimestamp      : Sample(8),
      timeStamp1           : Sample(8),
      timeStamp2           : Sample(8),
      messageLength        : Sample(2),
      serverMessagePayload : ServerMessagePayload ]

EncodeServerDirectPacketBody(message) ==
    message.packetSequenceNumber
        \o message.checksum
        \o EncodeUIntBE(message.serverMessagePayload.tag, 2)
        \o message.logTime
        \o message.alphaChar
        \o message.traderId
        \o message.errorCode
        \o message.headerTimestamp
        \o message.timeStamp1
        \o message.timeStamp2
        \o message.messageLength
        \o EncodeServerMessagePayload(message.serverMessagePayload)

(* Packet Length counts the bytes it frames, so it is written from them *)
EncodeServerDirectPacket(message) ==
    LET body == EncodeServerDirectPacketBody(message)
    IN  EncodeUIntBE(Len(body) + 2, 2) \o body

DecodeServerDirectPacketBody(bytes) ==
    LET packetSequenceNumber == ReadBytes(bytes, 4) IN IF ~packetSequenceNumber.ok THEN Fail ELSE
    LET checksum == ReadBytes(packetSequenceNumber.rest, 16) IN IF ~checksum.ok THEN Fail ELSE
    LET transactionCode == ReadUIntBE(checksum.rest, 2) IN IF ~transactionCode.ok THEN Fail ELSE
    LET logTime == ReadBytes(transactionCode.rest, 4) IN IF ~logTime.ok THEN Fail ELSE
    LET alphaChar == ReadBytes(logTime.rest, 2) IN IF ~alphaChar.ok THEN Fail ELSE
    LET traderId == ReadBytes(alphaChar.rest, 4) IN IF ~traderId.ok THEN Fail ELSE
    LET errorCode == ReadBytes(traderId.rest, 2) IN IF ~errorCode.ok THEN Fail ELSE
    LET headerTimestamp == ReadBytes(errorCode.rest, 8) IN IF ~headerTimestamp.ok THEN Fail ELSE
    LET timeStamp1 == ReadBytes(headerTimestamp.rest, 8) IN IF ~timeStamp1.ok THEN Fail ELSE
    LET timeStamp2 == ReadBytes(timeStamp1.rest, 8) IN IF ~timeStamp2.ok THEN Fail ELSE
    LET messageLength == ReadBytes(timeStamp2.rest, 2) IN IF ~messageLength.ok THEN Fail ELSE
    LET serverMessagePayload == DecodeServerMessagePayload(transactionCode.value, messageLength.rest) IN IF ~serverMessagePayload.ok THEN Fail ELSE
    Ok([ packetSequenceNumber |-> packetSequenceNumber.value,
         checksum             |-> checksum.value,
         logTime              |-> logTime.value,
         alphaChar            |-> alphaChar.value,
         traderId             |-> traderId.value,
         errorCode            |-> errorCode.value,
         headerTimestamp      |-> headerTimestamp.value,
         timeStamp1           |-> timeStamp1.value,
         timeStamp2           |-> timeStamp2.value,
         messageLength        |-> messageLength.value,
         serverMessagePayload |-> serverMessagePayload.value ], serverMessagePayload.rest)

DecodeServerDirectPacket(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeServerDirectPacketBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroServerDirectPacket ==
    [ packetSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      checksum             |-> [i \in 1 .. 16 |-> 0],
      logTime              |-> [i \in 1 .. 4 |-> 0],
      alphaChar            |-> [i \in 1 .. 2 |-> 0],
      traderId             |-> [i \in 1 .. 4 |-> 0],
      errorCode            |-> [i \in 1 .. 2 |-> 0],
      headerTimestamp      |-> [i \in 1 .. 8 |-> 0],
      timeStamp1           |-> [i \in 1 .. 8 |-> 0],
      timeStamp2           |-> [i \in 1 .. 8 |-> 0],
      messageLength        |-> [i \in 1 .. 2 |-> 0],
      serverMessagePayload |-> ZeroServerMessagePayload ]

(* Server Direct Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerDirectPacket ==
    { ZeroServerDirectPacket }
        \cup { [ZeroServerDirectPacket EXCEPT !.packetSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroServerDirectPacket EXCEPT !.checksum = one] : one \in Sample(16) }
        \cup { [ZeroServerDirectPacket EXCEPT !.logTime = one] : one \in Sample(4) }
        \cup { [ZeroServerDirectPacket EXCEPT !.alphaChar = one] : one \in Sample(2) }
        \cup { [ZeroServerDirectPacket EXCEPT !.traderId = one] : one \in Sample(4) }
        \cup { [ZeroServerDirectPacket EXCEPT !.errorCode = one] : one \in Sample(2) }
        \cup { [ZeroServerDirectPacket EXCEPT !.headerTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroServerDirectPacket EXCEPT !.timeStamp1 = one] : one \in Sample(8) }
        \cup { [ZeroServerDirectPacket EXCEPT !.timeStamp2 = one] : one \in Sample(8) }
        \cup { [ZeroServerDirectPacket EXCEPT !.messageLength = one] : one \in Sample(2) }
        \cup { [ZeroServerDirectPacket EXCEPT !.serverMessagePayload = one] : one \in CheckedServerMessagePayload }

(* A run of Server Direct Packet, written one after another *)
RECURSIVE EncodeServerDirectPacketList(_)
EncodeServerDirectPacketList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeServerDirectPacket(Head(messages)) \o EncodeServerDirectPacketList(Tail(messages))

(* As many Server Direct Packet as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadServerDirectPacketAll(_)
ReadServerDirectPacketAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeServerDirectPacket(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadServerDirectPacketAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Server Direct Packet of each kind, for the lists that carry them *)
OneServerDirectPacket ==
    { [ZeroServerDirectPacket EXCEPT !.serverMessagePayload = [tag |-> SignOnOutMessageCode, body |-> ZeroSignOnOutMessage]],
      [ZeroServerDirectPacket EXCEPT !.serverMessagePayload = [tag |-> TradeConfirmationMessageCode, body |-> ZeroTradeConfirmationMessage]],
      [ZeroServerDirectPacket EXCEPT !.serverMessagePayload = [tag |-> TradeCancelConfirmMessageCode, body |-> ZeroTradeCancelConfirmMessage]],
      [ZeroServerDirectPacket EXCEPT !.serverMessagePayload = [tag |-> TradeCancelRejectMessageCode, body |-> ZeroTradeCancelRejectMessage]],
      [ZeroServerDirectPacket EXCEPT !.serverMessagePayload = [tag |-> TradeModifyConfirmMessageCode, body |-> ZeroTradeModifyConfirmMessage]],
      [ZeroServerDirectPacket EXCEPT !.serverMessagePayload = [tag |-> TradeModifyRejectMessageCode, body |-> ZeroTradeModifyRejectMessage]],
      [ZeroServerDirectPacket EXCEPT !.serverMessagePayload = [tag |-> GiveupAppConfirmTmMessageCode, body |-> ZeroGiveupAppConfirmTmMessage]],
      [ZeroServerDirectPacket EXCEPT !.serverMessagePayload = [tag |-> GiveupRejConfirmTmMessageCode, body |-> ZeroGiveupRejConfirmTmMessage]] }

(***************************************************************************)
(* Server Packet                                                           *)
(***************************************************************************)

ServerPacket ==
    [ serverDirectPacket : SampleLists(OneServerDirectPacket) ]

EncodeServerPacket(message) ==
    EncodeServerDirectPacketList(message.serverDirectPacket)

DecodeServerPacket(bytes) ==
    LET serverDirectPacket == ReadServerDirectPacketAll(bytes) IN IF ~serverDirectPacket.ok THEN Fail ELSE
    Ok([ serverDirectPacket |-> serverDirectPacket.value ], serverDirectPacket.rest)

ZeroServerPacket ==
    [ serverDirectPacket |-> << >> ]

(* Server Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerPacket ==
    { ZeroServerPacket }
        \cup { [ZeroServerPacket EXCEPT !.serverDirectPacket = one] : one \in SampleLists(OneServerDirectPacket) }

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

(* Every Sign On Out Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSignOnOutMessage ==
    \A message \in CheckedSignOnOutMessage :
        LET read == DecodeSignOnOutMessage(EncodeSignOnOutMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Contract Desc decodes back to what was encoded, and leaves nothing over *)
RoundTripContractDesc ==
    \A message \in CheckedContractDesc :
        LET read == DecodeContractDesc(EncodeContractDesc(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Confirmation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeConfirmationMessage ==
    \A message \in CheckedTradeConfirmationMessage :
        LET read == DecodeTradeConfirmationMessage(EncodeTradeConfirmationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Contract Desc decodes back to what was encoded, and leaves nothing over *)
RoundTripContractDesc2 ==
    \A message \in CheckedContractDesc2 :
        LET read == DecodeContractDesc2(EncodeContractDesc2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Cancel Confirm Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCancelConfirmMessage ==
    \A message \in CheckedTradeCancelConfirmMessage :
        LET read == DecodeTradeCancelConfirmMessage(EncodeTradeCancelConfirmMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Contract Desc decodes back to what was encoded, and leaves nothing over *)
RoundTripContractDesc3 ==
    \A message \in CheckedContractDesc3 :
        LET read == DecodeContractDesc3(EncodeContractDesc3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Cancel Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCancelRejectMessage ==
    \A message \in CheckedTradeCancelRejectMessage :
        LET read == DecodeTradeCancelRejectMessage(EncodeTradeCancelRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Contract Desc decodes back to what was encoded, and leaves nothing over *)
RoundTripContractDesc4 ==
    \A message \in CheckedContractDesc4 :
        LET read == DecodeContractDesc4(EncodeContractDesc4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Modify Confirm Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeModifyConfirmMessage ==
    \A message \in CheckedTradeModifyConfirmMessage :
        LET read == DecodeTradeModifyConfirmMessage(EncodeTradeModifyConfirmMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Contract Desc decodes back to what was encoded, and leaves nothing over *)
RoundTripContractDesc5 ==
    \A message \in CheckedContractDesc5 :
        LET read == DecodeContractDesc5(EncodeContractDesc5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Modify Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeModifyRejectMessage ==
    \A message \in CheckedTradeModifyRejectMessage :
        LET read == DecodeTradeModifyRejectMessage(EncodeTradeModifyRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Giveup App Confirm Tm Message decodes back to what was encoded, and leaves nothing over *)
RoundTripGiveupAppConfirmTmMessage ==
    \A message \in CheckedGiveupAppConfirmTmMessage :
        LET read == DecodeGiveupAppConfirmTmMessage(EncodeGiveupAppConfirmTmMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Giveup Rej Confirm Tm Message decodes back to what was encoded, and leaves nothing over *)
RoundTripGiveupRejConfirmTmMessage ==
    \A message \in CheckedGiveupRejConfirmTmMessage :
        LET read == DecodeGiveupRejConfirmTmMessage(EncodeGiveupRejConfirmTmMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Server Direct Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripServerDirectPacket ==
    \A message \in CheckedServerDirectPacket :
        LET read == DecodeServerDirectPacket(EncodeServerDirectPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Server Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripServerPacket ==
    \A message \in CheckedServerPacket :
        LET read == DecodeServerPacket(EncodeServerPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Server Message Payload is selected by the Transaction Code it is written under *)
SelectsServerMessagePayload ==
    \A message \in CheckedServerMessagePayload :
        LET read == DecodeServerMessagePayload(message.tag, EncodeServerMessagePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Packet Length is written from the bytes it frames *)
FramesServerDirectPacket ==
    \A message \in CheckedServerDirectPacket :
        LET bytes == EncodeServerDirectPacket(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
