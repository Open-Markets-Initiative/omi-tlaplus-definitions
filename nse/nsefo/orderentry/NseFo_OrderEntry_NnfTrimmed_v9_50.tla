----------------- MODULE NseFo_OrderEntry_NnfTrimmed_v9_50 -----------------
(***************************************************************************)
(* National Stock Exchange of India Ltd Order Entry v9.50                  *)
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
(* since every reading of it takes at least 22 bytes off the reader the    *)
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
(* Contract Desc Tr: 26 bytes                                              *)
(***************************************************************************)

ContractDescTr ==
    [ instrumentName : Sample(6),
      symbol         : Sample(10),
      expiryDate     : Sample(4),
      strikePrice    : Sample(4),
      optionType     : Sample(2) ]

EncodeContractDescTr(message) ==
    message.instrumentName
        \o message.symbol
        \o message.expiryDate
        \o message.strikePrice
        \o message.optionType

DecodeContractDescTr(bytes) ==
    LET instrumentName == ReadBytes(bytes, 6) IN IF ~instrumentName.ok THEN Fail ELSE
    LET symbol == ReadBytes(instrumentName.rest, 10) IN IF ~symbol.ok THEN Fail ELSE
    LET expiryDate == ReadBytes(symbol.rest, 4) IN IF ~expiryDate.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(expiryDate.rest, 4) IN IF ~strikePrice.ok THEN Fail ELSE
    LET optionType == ReadBytes(strikePrice.rest, 2) IN IF ~optionType.ok THEN Fail ELSE
    Ok([ instrumentName |-> instrumentName.value,
         symbol         |-> symbol.value,
         expiryDate     |-> expiryDate.value,
         strikePrice    |-> strikePrice.value,
         optionType     |-> optionType.value ], optionType.rest)

ZeroContractDescTr ==
    [ instrumentName |-> [i \in 1 .. 6 |-> 0],
      symbol         |-> [i \in 1 .. 10 |-> 0],
      expiryDate     |-> [i \in 1 .. 4 |-> 0],
      strikePrice    |-> [i \in 1 .. 4 |-> 0],
      optionType     |-> [i \in 1 .. 2 |-> 0] ]

(* Contract Desc Tr at zero, then each field in turn at the values it is checked at *)
CheckedContractDescTr ==
    { ZeroContractDescTr }
        \cup { [ZeroContractDescTr EXCEPT !.instrumentName = one] : one \in Sample(6) }
        \cup { [ZeroContractDescTr EXCEPT !.symbol = one] : one \in Sample(10) }
        \cup { [ZeroContractDescTr EXCEPT !.expiryDate = one] : one \in Sample(4) }
        \cup { [ZeroContractDescTr EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroContractDescTr EXCEPT !.optionType = one] : one \in Sample(2) }

(***************************************************************************)
(* Board Lot In Trimmed Message: 156 bytes                                 *)
(***************************************************************************)

BoardLotInTrimmedMessage ==
    [ userId               : Sample(4),
      reasonCode           : Sample(2),
      tokenNo              : Sample(4),
      contractDescTr       : ContractDescTr,
      accountNumber        : Sample(10),
      bookType             : Sample(2),
      buySellIndicator     : Sample(2),
      disclosedVolume      : Sample(4),
      volume               : Sample(4),
      price                : Sample(4),
      goodTillDate         : Sample(4),
      stOrderFlags         : Sample(2),
      branchId             : Sample(2),
      traderId             : Sample(4),
      brokerId             : Sample(5),
      openClose            : Sample(1),
      settlor              : Sample(12),
      proClientIndicator   : Sample(2),
      additionalOrderFlags : Sample(1),
      reserved1            : Sample(1),
      filler               : Sample(4),
      nnfField             : Sample(8),
      pan                  : Sample(10),
      algoId               : Sample(4),
      reserved2            : Sample(2),
      reserved32           : Sample(32) ]

EncodeBoardLotInTrimmedMessage(message) ==
    message.userId
        \o message.reasonCode
        \o message.tokenNo
        \o EncodeContractDescTr(message.contractDescTr)
        \o message.accountNumber
        \o message.bookType
        \o message.buySellIndicator
        \o message.disclosedVolume
        \o message.volume
        \o message.price
        \o message.goodTillDate
        \o message.stOrderFlags
        \o message.branchId
        \o message.traderId
        \o message.brokerId
        \o message.openClose
        \o message.settlor
        \o message.proClientIndicator
        \o message.additionalOrderFlags
        \o message.reserved1
        \o message.filler
        \o message.nnfField
        \o message.pan
        \o message.algoId
        \o message.reserved2
        \o message.reserved32

DecodeBoardLotInTrimmedMessage(bytes) ==
    LET userId == ReadBytes(bytes, 4) IN IF ~userId.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(userId.rest, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET tokenNo == ReadBytes(reasonCode.rest, 4) IN IF ~tokenNo.ok THEN Fail ELSE
    LET contractDescTr == DecodeContractDescTr(tokenNo.rest) IN IF ~contractDescTr.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(contractDescTr.rest, 10) IN IF ~accountNumber.ok THEN Fail ELSE
    LET bookType == ReadBytes(accountNumber.rest, 2) IN IF ~bookType.ok THEN Fail ELSE
    LET buySellIndicator == ReadBytes(bookType.rest, 2) IN IF ~buySellIndicator.ok THEN Fail ELSE
    LET disclosedVolume == ReadBytes(buySellIndicator.rest, 4) IN IF ~disclosedVolume.ok THEN Fail ELSE
    LET volume == ReadBytes(disclosedVolume.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET price == ReadBytes(volume.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET goodTillDate == ReadBytes(price.rest, 4) IN IF ~goodTillDate.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(goodTillDate.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET branchId == ReadBytes(stOrderFlags.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET traderId == ReadBytes(branchId.rest, 4) IN IF ~traderId.ok THEN Fail ELSE
    LET brokerId == ReadBytes(traderId.rest, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET openClose == ReadBytes(brokerId.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET settlor == ReadBytes(openClose.rest, 12) IN IF ~settlor.ok THEN Fail ELSE
    LET proClientIndicator == ReadBytes(settlor.rest, 2) IN IF ~proClientIndicator.ok THEN Fail ELSE
    LET additionalOrderFlags == ReadBytes(proClientIndicator.rest, 1) IN IF ~additionalOrderFlags.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(additionalOrderFlags.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET filler == ReadBytes(reserved1.rest, 4) IN IF ~filler.ok THEN Fail ELSE
    LET nnfField == ReadBytes(filler.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET pan == ReadBytes(nnfField.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET algoId == ReadBytes(pan.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(algoId.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET reserved32 == ReadBytes(reserved2.rest, 32) IN IF ~reserved32.ok THEN Fail ELSE
    Ok([ userId               |-> userId.value,
         reasonCode           |-> reasonCode.value,
         tokenNo              |-> tokenNo.value,
         contractDescTr       |-> contractDescTr.value,
         accountNumber        |-> accountNumber.value,
         bookType             |-> bookType.value,
         buySellIndicator     |-> buySellIndicator.value,
         disclosedVolume      |-> disclosedVolume.value,
         volume               |-> volume.value,
         price                |-> price.value,
         goodTillDate         |-> goodTillDate.value,
         stOrderFlags         |-> stOrderFlags.value,
         branchId             |-> branchId.value,
         traderId             |-> traderId.value,
         brokerId             |-> brokerId.value,
         openClose            |-> openClose.value,
         settlor              |-> settlor.value,
         proClientIndicator   |-> proClientIndicator.value,
         additionalOrderFlags |-> additionalOrderFlags.value,
         reserved1            |-> reserved1.value,
         filler               |-> filler.value,
         nnfField             |-> nnfField.value,
         pan                  |-> pan.value,
         algoId               |-> algoId.value,
         reserved2            |-> reserved2.value,
         reserved32           |-> reserved32.value ], reserved32.rest)

ZeroBoardLotInTrimmedMessage ==
    [ userId               |-> [i \in 1 .. 4 |-> 0],
      reasonCode           |-> [i \in 1 .. 2 |-> 0],
      tokenNo              |-> [i \in 1 .. 4 |-> 0],
      contractDescTr       |-> ZeroContractDescTr,
      accountNumber        |-> [i \in 1 .. 10 |-> 0],
      bookType             |-> [i \in 1 .. 2 |-> 0],
      buySellIndicator     |-> [i \in 1 .. 2 |-> 0],
      disclosedVolume      |-> [i \in 1 .. 4 |-> 0],
      volume               |-> [i \in 1 .. 4 |-> 0],
      price                |-> [i \in 1 .. 4 |-> 0],
      goodTillDate         |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags         |-> [i \in 1 .. 2 |-> 0],
      branchId             |-> [i \in 1 .. 2 |-> 0],
      traderId             |-> [i \in 1 .. 4 |-> 0],
      brokerId             |-> [i \in 1 .. 5 |-> 0],
      openClose            |-> [i \in 1 .. 1 |-> 0],
      settlor              |-> [i \in 1 .. 12 |-> 0],
      proClientIndicator   |-> [i \in 1 .. 2 |-> 0],
      additionalOrderFlags |-> [i \in 1 .. 1 |-> 0],
      reserved1            |-> [i \in 1 .. 1 |-> 0],
      filler               |-> [i \in 1 .. 4 |-> 0],
      nnfField             |-> [i \in 1 .. 8 |-> 0],
      pan                  |-> [i \in 1 .. 10 |-> 0],
      algoId               |-> [i \in 1 .. 4 |-> 0],
      reserved2            |-> [i \in 1 .. 2 |-> 0],
      reserved32           |-> [i \in 1 .. 32 |-> 0] ]

(* Board Lot In Trimmed Message at zero, then each field in turn at the values it is checked at *)
CheckedBoardLotInTrimmedMessage ==
    { ZeroBoardLotInTrimmedMessage }
        \cup { [ZeroBoardLotInTrimmedMessage EXCEPT !.userId = one] : one \in Sample(4) }
        \cup { [ZeroBoardLotInTrimmedMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroBoardLotInTrimmedMessage EXCEPT !.tokenNo = one] : one \in Sample(4) }
        \cup { [ZeroBoardLotInTrimmedMessage EXCEPT !.contractDescTr = one] : one \in CheckedContractDescTr }
        \cup { [ZeroBoardLotInTrimmedMessage EXCEPT !.accountNumber = one] : one \in Sample(10) }
        \cup { [ZeroBoardLotInTrimmedMessage EXCEPT !.bookType = one] : one \in Sample(2) }
        \cup { [ZeroBoardLotInTrimmedMessage EXCEPT !.buySellIndicator = one] : one \in Sample(2) }
        \cup { [ZeroBoardLotInTrimmedMessage EXCEPT !.disclosedVolume = one] : one \in Sample(4) }
        \cup { [ZeroBoardLotInTrimmedMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroBoardLotInTrimmedMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroBoardLotInTrimmedMessage EXCEPT !.goodTillDate = one] : one \in Sample(4) }
        \cup { [ZeroBoardLotInTrimmedMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroBoardLotInTrimmedMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroBoardLotInTrimmedMessage EXCEPT !.traderId = one] : one \in Sample(4) }
        \cup { [ZeroBoardLotInTrimmedMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroBoardLotInTrimmedMessage EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroBoardLotInTrimmedMessage EXCEPT !.settlor = one] : one \in Sample(12) }
        \cup { [ZeroBoardLotInTrimmedMessage EXCEPT !.proClientIndicator = one] : one \in Sample(2) }
        \cup { [ZeroBoardLotInTrimmedMessage EXCEPT !.additionalOrderFlags = one] : one \in Sample(1) }
        \cup { [ZeroBoardLotInTrimmedMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroBoardLotInTrimmedMessage EXCEPT !.filler = one] : one \in Sample(4) }
        \cup { [ZeroBoardLotInTrimmedMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroBoardLotInTrimmedMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroBoardLotInTrimmedMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroBoardLotInTrimmedMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroBoardLotInTrimmedMessage EXCEPT !.reserved32 = one] : one \in Sample(32) }

(***************************************************************************)
(* Contract Desc Tr: 26 bytes                                              *)
(***************************************************************************)

ContractDescTr2 ==
    [ instrumentName : Sample(6),
      symbol         : Sample(10),
      expiryDate     : Sample(4),
      strikePrice    : Sample(4),
      optionType     : Sample(2) ]

EncodeContractDescTr2(message) ==
    message.instrumentName
        \o message.symbol
        \o message.expiryDate
        \o message.strikePrice
        \o message.optionType

DecodeContractDescTr2(bytes) ==
    LET instrumentName == ReadBytes(bytes, 6) IN IF ~instrumentName.ok THEN Fail ELSE
    LET symbol == ReadBytes(instrumentName.rest, 10) IN IF ~symbol.ok THEN Fail ELSE
    LET expiryDate == ReadBytes(symbol.rest, 4) IN IF ~expiryDate.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(expiryDate.rest, 4) IN IF ~strikePrice.ok THEN Fail ELSE
    LET optionType == ReadBytes(strikePrice.rest, 2) IN IF ~optionType.ok THEN Fail ELSE
    Ok([ instrumentName |-> instrumentName.value,
         symbol         |-> symbol.value,
         expiryDate     |-> expiryDate.value,
         strikePrice    |-> strikePrice.value,
         optionType     |-> optionType.value ], optionType.rest)

ZeroContractDescTr2 ==
    [ instrumentName |-> [i \in 1 .. 6 |-> 0],
      symbol         |-> [i \in 1 .. 10 |-> 0],
      expiryDate     |-> [i \in 1 .. 4 |-> 0],
      strikePrice    |-> [i \in 1 .. 4 |-> 0],
      optionType     |-> [i \in 1 .. 2 |-> 0] ]

(* Contract Desc Tr at zero, then each field in turn at the values it is checked at *)
CheckedContractDescTr2 ==
    { ZeroContractDescTr2 }
        \cup { [ZeroContractDescTr2 EXCEPT !.instrumentName = one] : one \in Sample(6) }
        \cup { [ZeroContractDescTr2 EXCEPT !.symbol = one] : one \in Sample(10) }
        \cup { [ZeroContractDescTr2 EXCEPT !.expiryDate = one] : one \in Sample(4) }
        \cup { [ZeroContractDescTr2 EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroContractDescTr2 EXCEPT !.optionType = one] : one \in Sample(2) }

(***************************************************************************)
(* Order Modify Cancel Trimmed Message: 184 bytes                          *)
(***************************************************************************)

OrderModifyCancelTrimmedMessage ==
    [ userId                   : Sample(4),
      modifiedCancelledBy      : Sample(1),
      reserved1                : Sample(1),
      tokenNo                  : Sample(4),
      contractDescTr           : ContractDescTr2,
      orderNumber              : Sample(8),
      accountNumber            : Sample(10),
      bookType                 : Sample(2),
      buySellIndicator         : Sample(2),
      disclosedVolume          : Sample(4),
      disclosedVolumeRemaining : Sample(4),
      totalVolumeRemaining     : Sample(4),
      volume                   : Sample(4),
      volumeFilledToday        : Sample(4),
      price                    : Sample(4),
      goodTillDate             : Sample(4),
      entryDateTime            : Sample(4),
      lastModified             : Sample(4),
      stOrderFlags             : Sample(2),
      branchId                 : Sample(2),
      traderId                 : Sample(4),
      brokerId                 : Sample(5),
      openClose                : Sample(1),
      settlor                  : Sample(12),
      proClientIndicator       : Sample(2),
      additionalOrderFlags     : Sample(1),
      secondReserved1          : Sample(1),
      filler                   : Sample(4),
      nnfField                 : Sample(8),
      pan                      : Sample(10),
      algoId                   : Sample(4),
      reserved2                : Sample(2),
      lastActivityReference    : Sample(8),
      reserved24               : Sample(24) ]

EncodeOrderModifyCancelTrimmedMessage(message) ==
    message.userId
        \o message.modifiedCancelledBy
        \o message.reserved1
        \o message.tokenNo
        \o EncodeContractDescTr2(message.contractDescTr)
        \o message.orderNumber
        \o message.accountNumber
        \o message.bookType
        \o message.buySellIndicator
        \o message.disclosedVolume
        \o message.disclosedVolumeRemaining
        \o message.totalVolumeRemaining
        \o message.volume
        \o message.volumeFilledToday
        \o message.price
        \o message.goodTillDate
        \o message.entryDateTime
        \o message.lastModified
        \o message.stOrderFlags
        \o message.branchId
        \o message.traderId
        \o message.brokerId
        \o message.openClose
        \o message.settlor
        \o message.proClientIndicator
        \o message.additionalOrderFlags
        \o message.secondReserved1
        \o message.filler
        \o message.nnfField
        \o message.pan
        \o message.algoId
        \o message.reserved2
        \o message.lastActivityReference
        \o message.reserved24

DecodeOrderModifyCancelTrimmedMessage(bytes) ==
    LET userId == ReadBytes(bytes, 4) IN IF ~userId.ok THEN Fail ELSE
    LET modifiedCancelledBy == ReadBytes(userId.rest, 1) IN IF ~modifiedCancelledBy.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(modifiedCancelledBy.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET tokenNo == ReadBytes(reserved1.rest, 4) IN IF ~tokenNo.ok THEN Fail ELSE
    LET contractDescTr == DecodeContractDescTr2(tokenNo.rest) IN IF ~contractDescTr.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(contractDescTr.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(orderNumber.rest, 10) IN IF ~accountNumber.ok THEN Fail ELSE
    LET bookType == ReadBytes(accountNumber.rest, 2) IN IF ~bookType.ok THEN Fail ELSE
    LET buySellIndicator == ReadBytes(bookType.rest, 2) IN IF ~buySellIndicator.ok THEN Fail ELSE
    LET disclosedVolume == ReadBytes(buySellIndicator.rest, 4) IN IF ~disclosedVolume.ok THEN Fail ELSE
    LET disclosedVolumeRemaining == ReadBytes(disclosedVolume.rest, 4) IN IF ~disclosedVolumeRemaining.ok THEN Fail ELSE
    LET totalVolumeRemaining == ReadBytes(disclosedVolumeRemaining.rest, 4) IN IF ~totalVolumeRemaining.ok THEN Fail ELSE
    LET volume == ReadBytes(totalVolumeRemaining.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET volumeFilledToday == ReadBytes(volume.rest, 4) IN IF ~volumeFilledToday.ok THEN Fail ELSE
    LET price == ReadBytes(volumeFilledToday.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET goodTillDate == ReadBytes(price.rest, 4) IN IF ~goodTillDate.ok THEN Fail ELSE
    LET entryDateTime == ReadBytes(goodTillDate.rest, 4) IN IF ~entryDateTime.ok THEN Fail ELSE
    LET lastModified == ReadBytes(entryDateTime.rest, 4) IN IF ~lastModified.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(lastModified.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET branchId == ReadBytes(stOrderFlags.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET traderId == ReadBytes(branchId.rest, 4) IN IF ~traderId.ok THEN Fail ELSE
    LET brokerId == ReadBytes(traderId.rest, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET openClose == ReadBytes(brokerId.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET settlor == ReadBytes(openClose.rest, 12) IN IF ~settlor.ok THEN Fail ELSE
    LET proClientIndicator == ReadBytes(settlor.rest, 2) IN IF ~proClientIndicator.ok THEN Fail ELSE
    LET additionalOrderFlags == ReadBytes(proClientIndicator.rest, 1) IN IF ~additionalOrderFlags.ok THEN Fail ELSE
    LET secondReserved1 == ReadBytes(additionalOrderFlags.rest, 1) IN IF ~secondReserved1.ok THEN Fail ELSE
    LET filler == ReadBytes(secondReserved1.rest, 4) IN IF ~filler.ok THEN Fail ELSE
    LET nnfField == ReadBytes(filler.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET pan == ReadBytes(nnfField.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET algoId == ReadBytes(pan.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(algoId.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET lastActivityReference == ReadBytes(reserved2.rest, 8) IN IF ~lastActivityReference.ok THEN Fail ELSE
    LET reserved24 == ReadBytes(lastActivityReference.rest, 24) IN IF ~reserved24.ok THEN Fail ELSE
    Ok([ userId                   |-> userId.value,
         modifiedCancelledBy      |-> modifiedCancelledBy.value,
         reserved1                |-> reserved1.value,
         tokenNo                  |-> tokenNo.value,
         contractDescTr           |-> contractDescTr.value,
         orderNumber              |-> orderNumber.value,
         accountNumber            |-> accountNumber.value,
         bookType                 |-> bookType.value,
         buySellIndicator         |-> buySellIndicator.value,
         disclosedVolume          |-> disclosedVolume.value,
         disclosedVolumeRemaining |-> disclosedVolumeRemaining.value,
         totalVolumeRemaining     |-> totalVolumeRemaining.value,
         volume                   |-> volume.value,
         volumeFilledToday        |-> volumeFilledToday.value,
         price                    |-> price.value,
         goodTillDate             |-> goodTillDate.value,
         entryDateTime            |-> entryDateTime.value,
         lastModified             |-> lastModified.value,
         stOrderFlags             |-> stOrderFlags.value,
         branchId                 |-> branchId.value,
         traderId                 |-> traderId.value,
         brokerId                 |-> brokerId.value,
         openClose                |-> openClose.value,
         settlor                  |-> settlor.value,
         proClientIndicator       |-> proClientIndicator.value,
         additionalOrderFlags     |-> additionalOrderFlags.value,
         secondReserved1          |-> secondReserved1.value,
         filler                   |-> filler.value,
         nnfField                 |-> nnfField.value,
         pan                      |-> pan.value,
         algoId                   |-> algoId.value,
         reserved2                |-> reserved2.value,
         lastActivityReference    |-> lastActivityReference.value,
         reserved24               |-> reserved24.value ], reserved24.rest)

ZeroOrderModifyCancelTrimmedMessage ==
    [ userId                   |-> [i \in 1 .. 4 |-> 0],
      modifiedCancelledBy      |-> [i \in 1 .. 1 |-> 0],
      reserved1                |-> [i \in 1 .. 1 |-> 0],
      tokenNo                  |-> [i \in 1 .. 4 |-> 0],
      contractDescTr           |-> ZeroContractDescTr2,
      orderNumber              |-> [i \in 1 .. 8 |-> 0],
      accountNumber            |-> [i \in 1 .. 10 |-> 0],
      bookType                 |-> [i \in 1 .. 2 |-> 0],
      buySellIndicator         |-> [i \in 1 .. 2 |-> 0],
      disclosedVolume          |-> [i \in 1 .. 4 |-> 0],
      disclosedVolumeRemaining |-> [i \in 1 .. 4 |-> 0],
      totalVolumeRemaining     |-> [i \in 1 .. 4 |-> 0],
      volume                   |-> [i \in 1 .. 4 |-> 0],
      volumeFilledToday        |-> [i \in 1 .. 4 |-> 0],
      price                    |-> [i \in 1 .. 4 |-> 0],
      goodTillDate             |-> [i \in 1 .. 4 |-> 0],
      entryDateTime            |-> [i \in 1 .. 4 |-> 0],
      lastModified             |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags             |-> [i \in 1 .. 2 |-> 0],
      branchId                 |-> [i \in 1 .. 2 |-> 0],
      traderId                 |-> [i \in 1 .. 4 |-> 0],
      brokerId                 |-> [i \in 1 .. 5 |-> 0],
      openClose                |-> [i \in 1 .. 1 |-> 0],
      settlor                  |-> [i \in 1 .. 12 |-> 0],
      proClientIndicator       |-> [i \in 1 .. 2 |-> 0],
      additionalOrderFlags     |-> [i \in 1 .. 1 |-> 0],
      secondReserved1          |-> [i \in 1 .. 1 |-> 0],
      filler                   |-> [i \in 1 .. 4 |-> 0],
      nnfField                 |-> [i \in 1 .. 8 |-> 0],
      pan                      |-> [i \in 1 .. 10 |-> 0],
      algoId                   |-> [i \in 1 .. 4 |-> 0],
      reserved2                |-> [i \in 1 .. 2 |-> 0],
      lastActivityReference    |-> [i \in 1 .. 8 |-> 0],
      reserved24               |-> [i \in 1 .. 24 |-> 0] ]

(* Order Modify Cancel Trimmed Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderModifyCancelTrimmedMessage ==
    { ZeroOrderModifyCancelTrimmedMessage }
        \cup { [ZeroOrderModifyCancelTrimmedMessage EXCEPT !.userId = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyCancelTrimmedMessage EXCEPT !.modifiedCancelledBy = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifyCancelTrimmedMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifyCancelTrimmedMessage EXCEPT !.tokenNo = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyCancelTrimmedMessage EXCEPT !.contractDescTr = one] : one \in CheckedContractDescTr2 }
        \cup { [ZeroOrderModifyCancelTrimmedMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyCancelTrimmedMessage EXCEPT !.accountNumber = one] : one \in Sample(10) }
        \cup { [ZeroOrderModifyCancelTrimmedMessage EXCEPT !.bookType = one] : one \in Sample(2) }
        \cup { [ZeroOrderModifyCancelTrimmedMessage EXCEPT !.buySellIndicator = one] : one \in Sample(2) }
        \cup { [ZeroOrderModifyCancelTrimmedMessage EXCEPT !.disclosedVolume = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyCancelTrimmedMessage EXCEPT !.disclosedVolumeRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyCancelTrimmedMessage EXCEPT !.totalVolumeRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyCancelTrimmedMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyCancelTrimmedMessage EXCEPT !.volumeFilledToday = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyCancelTrimmedMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyCancelTrimmedMessage EXCEPT !.goodTillDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyCancelTrimmedMessage EXCEPT !.entryDateTime = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyCancelTrimmedMessage EXCEPT !.lastModified = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyCancelTrimmedMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroOrderModifyCancelTrimmedMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroOrderModifyCancelTrimmedMessage EXCEPT !.traderId = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyCancelTrimmedMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroOrderModifyCancelTrimmedMessage EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifyCancelTrimmedMessage EXCEPT !.settlor = one] : one \in Sample(12) }
        \cup { [ZeroOrderModifyCancelTrimmedMessage EXCEPT !.proClientIndicator = one] : one \in Sample(2) }
        \cup { [ZeroOrderModifyCancelTrimmedMessage EXCEPT !.additionalOrderFlags = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifyCancelTrimmedMessage EXCEPT !.secondReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifyCancelTrimmedMessage EXCEPT !.filler = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyCancelTrimmedMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyCancelTrimmedMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroOrderModifyCancelTrimmedMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyCancelTrimmedMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderModifyCancelTrimmedMessage EXCEPT !.lastActivityReference = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyCancelTrimmedMessage EXCEPT !.reserved24 = one] : one \in Sample(24) }

(***************************************************************************)
(* Contract Desc Tr: 26 bytes                                              *)
(***************************************************************************)

ContractDescTr3 ==
    [ instrumentName : Sample(6),
      symbol         : Sample(10),
      expiryDate     : Sample(4),
      strikePrice    : Sample(4),
      optionType     : Sample(2) ]

EncodeContractDescTr3(message) ==
    message.instrumentName
        \o message.symbol
        \o message.expiryDate
        \o message.strikePrice
        \o message.optionType

DecodeContractDescTr3(bytes) ==
    LET instrumentName == ReadBytes(bytes, 6) IN IF ~instrumentName.ok THEN Fail ELSE
    LET symbol == ReadBytes(instrumentName.rest, 10) IN IF ~symbol.ok THEN Fail ELSE
    LET expiryDate == ReadBytes(symbol.rest, 4) IN IF ~expiryDate.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(expiryDate.rest, 4) IN IF ~strikePrice.ok THEN Fail ELSE
    LET optionType == ReadBytes(strikePrice.rest, 2) IN IF ~optionType.ok THEN Fail ELSE
    Ok([ instrumentName |-> instrumentName.value,
         symbol         |-> symbol.value,
         expiryDate     |-> expiryDate.value,
         strikePrice    |-> strikePrice.value,
         optionType     |-> optionType.value ], optionType.rest)

ZeroContractDescTr3 ==
    [ instrumentName |-> [i \in 1 .. 6 |-> 0],
      symbol         |-> [i \in 1 .. 10 |-> 0],
      expiryDate     |-> [i \in 1 .. 4 |-> 0],
      strikePrice    |-> [i \in 1 .. 4 |-> 0],
      optionType     |-> [i \in 1 .. 2 |-> 0] ]

(* Contract Desc Tr at zero, then each field in turn at the values it is checked at *)
CheckedContractDescTr3 ==
    { ZeroContractDescTr3 }
        \cup { [ZeroContractDescTr3 EXCEPT !.instrumentName = one] : one \in Sample(6) }
        \cup { [ZeroContractDescTr3 EXCEPT !.symbol = one] : one \in Sample(10) }
        \cup { [ZeroContractDescTr3 EXCEPT !.expiryDate = one] : one \in Sample(4) }
        \cup { [ZeroContractDescTr3 EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroContractDescTr3 EXCEPT !.optionType = one] : one \in Sample(2) }

(***************************************************************************)
(* Order Confirmation Trimmed Message: 238 bytes                           *)
(***************************************************************************)

OrderConfirmationTrimmedMessage ==
    [ logTime                  : Sample(4),
      userId                   : Sample(4),
      errorCode                : Sample(2),
      timestamp1LongLong       : Sample(8),
      timestamp2Char           : Sample(1),
      modifiedCancelledBy      : Sample(1),
      reasonCode               : Sample(2),
      tokenNo                  : Sample(4),
      contractDescTr           : ContractDescTr3,
      closeoutFlag             : Sample(1),
      reserved1                : Sample(1),
      orderNumber              : Sample(8),
      accountNumber            : Sample(10),
      bookType                 : Sample(2),
      buySellIndicator         : Sample(2),
      disclosedVolume          : Sample(4),
      disclosedVolumeRemaining : Sample(4),
      totalVolumeRemaining     : Sample(4),
      volume                   : Sample(4),
      volumeFilledToday        : Sample(4),
      price                    : Sample(4),
      goodTillDate             : Sample(4),
      entryDateTime            : Sample(4),
      lastModified             : Sample(4),
      stOrderFlags             : Sample(2),
      branchId                 : Sample(2),
      traderId                 : Sample(4),
      brokerId                 : Sample(5),
      openClose                : Sample(1),
      settlor                  : Sample(12),
      proClientIndicator       : Sample(2),
      additionalOrderFlags     : Sample(1),
      secondReserved1          : Sample(1),
      filler                   : Sample(4),
      nnfField                 : Sample(8),
      timeStamp                : Sample(8),
      pan                      : Sample(10),
      algoId                   : Sample(4),
      reserved2                : Sample(2),
      lastActivityReference    : Sample(8),
      reserved52               : Sample(52) ]

EncodeOrderConfirmationTrimmedMessage(message) ==
    message.logTime
        \o message.userId
        \o message.errorCode
        \o message.timestamp1LongLong
        \o message.timestamp2Char
        \o message.modifiedCancelledBy
        \o message.reasonCode
        \o message.tokenNo
        \o EncodeContractDescTr3(message.contractDescTr)
        \o message.closeoutFlag
        \o message.reserved1
        \o message.orderNumber
        \o message.accountNumber
        \o message.bookType
        \o message.buySellIndicator
        \o message.disclosedVolume
        \o message.disclosedVolumeRemaining
        \o message.totalVolumeRemaining
        \o message.volume
        \o message.volumeFilledToday
        \o message.price
        \o message.goodTillDate
        \o message.entryDateTime
        \o message.lastModified
        \o message.stOrderFlags
        \o message.branchId
        \o message.traderId
        \o message.brokerId
        \o message.openClose
        \o message.settlor
        \o message.proClientIndicator
        \o message.additionalOrderFlags
        \o message.secondReserved1
        \o message.filler
        \o message.nnfField
        \o message.timeStamp
        \o message.pan
        \o message.algoId
        \o message.reserved2
        \o message.lastActivityReference
        \o message.reserved52

DecodeOrderConfirmationTrimmedMessage(bytes) ==
    LET logTime == ReadBytes(bytes, 4) IN IF ~logTime.ok THEN Fail ELSE
    LET userId == ReadBytes(logTime.rest, 4) IN IF ~userId.ok THEN Fail ELSE
    LET errorCode == ReadBytes(userId.rest, 2) IN IF ~errorCode.ok THEN Fail ELSE
    LET timestamp1LongLong == ReadBytes(errorCode.rest, 8) IN IF ~timestamp1LongLong.ok THEN Fail ELSE
    LET timestamp2Char == ReadBytes(timestamp1LongLong.rest, 1) IN IF ~timestamp2Char.ok THEN Fail ELSE
    LET modifiedCancelledBy == ReadBytes(timestamp2Char.rest, 1) IN IF ~modifiedCancelledBy.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(modifiedCancelledBy.rest, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET tokenNo == ReadBytes(reasonCode.rest, 4) IN IF ~tokenNo.ok THEN Fail ELSE
    LET contractDescTr == DecodeContractDescTr3(tokenNo.rest) IN IF ~contractDescTr.ok THEN Fail ELSE
    LET closeoutFlag == ReadBytes(contractDescTr.rest, 1) IN IF ~closeoutFlag.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(closeoutFlag.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(reserved1.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(orderNumber.rest, 10) IN IF ~accountNumber.ok THEN Fail ELSE
    LET bookType == ReadBytes(accountNumber.rest, 2) IN IF ~bookType.ok THEN Fail ELSE
    LET buySellIndicator == ReadBytes(bookType.rest, 2) IN IF ~buySellIndicator.ok THEN Fail ELSE
    LET disclosedVolume == ReadBytes(buySellIndicator.rest, 4) IN IF ~disclosedVolume.ok THEN Fail ELSE
    LET disclosedVolumeRemaining == ReadBytes(disclosedVolume.rest, 4) IN IF ~disclosedVolumeRemaining.ok THEN Fail ELSE
    LET totalVolumeRemaining == ReadBytes(disclosedVolumeRemaining.rest, 4) IN IF ~totalVolumeRemaining.ok THEN Fail ELSE
    LET volume == ReadBytes(totalVolumeRemaining.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET volumeFilledToday == ReadBytes(volume.rest, 4) IN IF ~volumeFilledToday.ok THEN Fail ELSE
    LET price == ReadBytes(volumeFilledToday.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET goodTillDate == ReadBytes(price.rest, 4) IN IF ~goodTillDate.ok THEN Fail ELSE
    LET entryDateTime == ReadBytes(goodTillDate.rest, 4) IN IF ~entryDateTime.ok THEN Fail ELSE
    LET lastModified == ReadBytes(entryDateTime.rest, 4) IN IF ~lastModified.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(lastModified.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET branchId == ReadBytes(stOrderFlags.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET traderId == ReadBytes(branchId.rest, 4) IN IF ~traderId.ok THEN Fail ELSE
    LET brokerId == ReadBytes(traderId.rest, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET openClose == ReadBytes(brokerId.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET settlor == ReadBytes(openClose.rest, 12) IN IF ~settlor.ok THEN Fail ELSE
    LET proClientIndicator == ReadBytes(settlor.rest, 2) IN IF ~proClientIndicator.ok THEN Fail ELSE
    LET additionalOrderFlags == ReadBytes(proClientIndicator.rest, 1) IN IF ~additionalOrderFlags.ok THEN Fail ELSE
    LET secondReserved1 == ReadBytes(additionalOrderFlags.rest, 1) IN IF ~secondReserved1.ok THEN Fail ELSE
    LET filler == ReadBytes(secondReserved1.rest, 4) IN IF ~filler.ok THEN Fail ELSE
    LET nnfField == ReadBytes(filler.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET timeStamp == ReadBytes(nnfField.rest, 8) IN IF ~timeStamp.ok THEN Fail ELSE
    LET pan == ReadBytes(timeStamp.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET algoId == ReadBytes(pan.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(algoId.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET lastActivityReference == ReadBytes(reserved2.rest, 8) IN IF ~lastActivityReference.ok THEN Fail ELSE
    LET reserved52 == ReadBytes(lastActivityReference.rest, 52) IN IF ~reserved52.ok THEN Fail ELSE
    Ok([ logTime                  |-> logTime.value,
         userId                   |-> userId.value,
         errorCode                |-> errorCode.value,
         timestamp1LongLong       |-> timestamp1LongLong.value,
         timestamp2Char           |-> timestamp2Char.value,
         modifiedCancelledBy      |-> modifiedCancelledBy.value,
         reasonCode               |-> reasonCode.value,
         tokenNo                  |-> tokenNo.value,
         contractDescTr           |-> contractDescTr.value,
         closeoutFlag             |-> closeoutFlag.value,
         reserved1                |-> reserved1.value,
         orderNumber              |-> orderNumber.value,
         accountNumber            |-> accountNumber.value,
         bookType                 |-> bookType.value,
         buySellIndicator         |-> buySellIndicator.value,
         disclosedVolume          |-> disclosedVolume.value,
         disclosedVolumeRemaining |-> disclosedVolumeRemaining.value,
         totalVolumeRemaining     |-> totalVolumeRemaining.value,
         volume                   |-> volume.value,
         volumeFilledToday        |-> volumeFilledToday.value,
         price                    |-> price.value,
         goodTillDate             |-> goodTillDate.value,
         entryDateTime            |-> entryDateTime.value,
         lastModified             |-> lastModified.value,
         stOrderFlags             |-> stOrderFlags.value,
         branchId                 |-> branchId.value,
         traderId                 |-> traderId.value,
         brokerId                 |-> brokerId.value,
         openClose                |-> openClose.value,
         settlor                  |-> settlor.value,
         proClientIndicator       |-> proClientIndicator.value,
         additionalOrderFlags     |-> additionalOrderFlags.value,
         secondReserved1          |-> secondReserved1.value,
         filler                   |-> filler.value,
         nnfField                 |-> nnfField.value,
         timeStamp                |-> timeStamp.value,
         pan                      |-> pan.value,
         algoId                   |-> algoId.value,
         reserved2                |-> reserved2.value,
         lastActivityReference    |-> lastActivityReference.value,
         reserved52               |-> reserved52.value ], reserved52.rest)

ZeroOrderConfirmationTrimmedMessage ==
    [ logTime                  |-> [i \in 1 .. 4 |-> 0],
      userId                   |-> [i \in 1 .. 4 |-> 0],
      errorCode                |-> [i \in 1 .. 2 |-> 0],
      timestamp1LongLong       |-> [i \in 1 .. 8 |-> 0],
      timestamp2Char           |-> [i \in 1 .. 1 |-> 0],
      modifiedCancelledBy      |-> [i \in 1 .. 1 |-> 0],
      reasonCode               |-> [i \in 1 .. 2 |-> 0],
      tokenNo                  |-> [i \in 1 .. 4 |-> 0],
      contractDescTr           |-> ZeroContractDescTr3,
      closeoutFlag             |-> [i \in 1 .. 1 |-> 0],
      reserved1                |-> [i \in 1 .. 1 |-> 0],
      orderNumber              |-> [i \in 1 .. 8 |-> 0],
      accountNumber            |-> [i \in 1 .. 10 |-> 0],
      bookType                 |-> [i \in 1 .. 2 |-> 0],
      buySellIndicator         |-> [i \in 1 .. 2 |-> 0],
      disclosedVolume          |-> [i \in 1 .. 4 |-> 0],
      disclosedVolumeRemaining |-> [i \in 1 .. 4 |-> 0],
      totalVolumeRemaining     |-> [i \in 1 .. 4 |-> 0],
      volume                   |-> [i \in 1 .. 4 |-> 0],
      volumeFilledToday        |-> [i \in 1 .. 4 |-> 0],
      price                    |-> [i \in 1 .. 4 |-> 0],
      goodTillDate             |-> [i \in 1 .. 4 |-> 0],
      entryDateTime            |-> [i \in 1 .. 4 |-> 0],
      lastModified             |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags             |-> [i \in 1 .. 2 |-> 0],
      branchId                 |-> [i \in 1 .. 2 |-> 0],
      traderId                 |-> [i \in 1 .. 4 |-> 0],
      brokerId                 |-> [i \in 1 .. 5 |-> 0],
      openClose                |-> [i \in 1 .. 1 |-> 0],
      settlor                  |-> [i \in 1 .. 12 |-> 0],
      proClientIndicator       |-> [i \in 1 .. 2 |-> 0],
      additionalOrderFlags     |-> [i \in 1 .. 1 |-> 0],
      secondReserved1          |-> [i \in 1 .. 1 |-> 0],
      filler                   |-> [i \in 1 .. 4 |-> 0],
      nnfField                 |-> [i \in 1 .. 8 |-> 0],
      timeStamp                |-> [i \in 1 .. 8 |-> 0],
      pan                      |-> [i \in 1 .. 10 |-> 0],
      algoId                   |-> [i \in 1 .. 4 |-> 0],
      reserved2                |-> [i \in 1 .. 2 |-> 0],
      lastActivityReference    |-> [i \in 1 .. 8 |-> 0],
      reserved52               |-> [i \in 1 .. 52 |-> 0] ]

(* Order Confirmation Trimmed Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderConfirmationTrimmedMessage ==
    { ZeroOrderConfirmationTrimmedMessage }
        \cup { [ZeroOrderConfirmationTrimmedMessage EXCEPT !.logTime = one] : one \in Sample(4) }
        \cup { [ZeroOrderConfirmationTrimmedMessage EXCEPT !.userId = one] : one \in Sample(4) }
        \cup { [ZeroOrderConfirmationTrimmedMessage EXCEPT !.errorCode = one] : one \in Sample(2) }
        \cup { [ZeroOrderConfirmationTrimmedMessage EXCEPT !.timestamp1LongLong = one] : one \in Sample(8) }
        \cup { [ZeroOrderConfirmationTrimmedMessage EXCEPT !.timestamp2Char = one] : one \in Sample(1) }
        \cup { [ZeroOrderConfirmationTrimmedMessage EXCEPT !.modifiedCancelledBy = one] : one \in Sample(1) }
        \cup { [ZeroOrderConfirmationTrimmedMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroOrderConfirmationTrimmedMessage EXCEPT !.tokenNo = one] : one \in Sample(4) }
        \cup { [ZeroOrderConfirmationTrimmedMessage EXCEPT !.contractDescTr = one] : one \in CheckedContractDescTr3 }
        \cup { [ZeroOrderConfirmationTrimmedMessage EXCEPT !.closeoutFlag = one] : one \in Sample(1) }
        \cup { [ZeroOrderConfirmationTrimmedMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderConfirmationTrimmedMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderConfirmationTrimmedMessage EXCEPT !.accountNumber = one] : one \in Sample(10) }
        \cup { [ZeroOrderConfirmationTrimmedMessage EXCEPT !.bookType = one] : one \in Sample(2) }
        \cup { [ZeroOrderConfirmationTrimmedMessage EXCEPT !.buySellIndicator = one] : one \in Sample(2) }
        \cup { [ZeroOrderConfirmationTrimmedMessage EXCEPT !.disclosedVolume = one] : one \in Sample(4) }
        \cup { [ZeroOrderConfirmationTrimmedMessage EXCEPT !.disclosedVolumeRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderConfirmationTrimmedMessage EXCEPT !.totalVolumeRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderConfirmationTrimmedMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroOrderConfirmationTrimmedMessage EXCEPT !.volumeFilledToday = one] : one \in Sample(4) }
        \cup { [ZeroOrderConfirmationTrimmedMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderConfirmationTrimmedMessage EXCEPT !.goodTillDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderConfirmationTrimmedMessage EXCEPT !.entryDateTime = one] : one \in Sample(4) }
        \cup { [ZeroOrderConfirmationTrimmedMessage EXCEPT !.lastModified = one] : one \in Sample(4) }
        \cup { [ZeroOrderConfirmationTrimmedMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroOrderConfirmationTrimmedMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroOrderConfirmationTrimmedMessage EXCEPT !.traderId = one] : one \in Sample(4) }
        \cup { [ZeroOrderConfirmationTrimmedMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroOrderConfirmationTrimmedMessage EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroOrderConfirmationTrimmedMessage EXCEPT !.settlor = one] : one \in Sample(12) }
        \cup { [ZeroOrderConfirmationTrimmedMessage EXCEPT !.proClientIndicator = one] : one \in Sample(2) }
        \cup { [ZeroOrderConfirmationTrimmedMessage EXCEPT !.additionalOrderFlags = one] : one \in Sample(1) }
        \cup { [ZeroOrderConfirmationTrimmedMessage EXCEPT !.secondReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderConfirmationTrimmedMessage EXCEPT !.filler = one] : one \in Sample(4) }
        \cup { [ZeroOrderConfirmationTrimmedMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroOrderConfirmationTrimmedMessage EXCEPT !.timeStamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderConfirmationTrimmedMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroOrderConfirmationTrimmedMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroOrderConfirmationTrimmedMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderConfirmationTrimmedMessage EXCEPT !.lastActivityReference = one] : one \in Sample(8) }
        \cup { [ZeroOrderConfirmationTrimmedMessage EXCEPT !.reserved52 = one] : one \in Sample(52) }

(***************************************************************************)
(* Contract Desc Tr: 26 bytes                                              *)
(***************************************************************************)

ContractDescTr4 ==
    [ instrumentName : Sample(6),
      symbol         : Sample(10),
      expiryDate     : Sample(4),
      strikePrice    : Sample(4),
      optionType     : Sample(2) ]

EncodeContractDescTr4(message) ==
    message.instrumentName
        \o message.symbol
        \o message.expiryDate
        \o message.strikePrice
        \o message.optionType

DecodeContractDescTr4(bytes) ==
    LET instrumentName == ReadBytes(bytes, 6) IN IF ~instrumentName.ok THEN Fail ELSE
    LET symbol == ReadBytes(instrumentName.rest, 10) IN IF ~symbol.ok THEN Fail ELSE
    LET expiryDate == ReadBytes(symbol.rest, 4) IN IF ~expiryDate.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(expiryDate.rest, 4) IN IF ~strikePrice.ok THEN Fail ELSE
    LET optionType == ReadBytes(strikePrice.rest, 2) IN IF ~optionType.ok THEN Fail ELSE
    Ok([ instrumentName |-> instrumentName.value,
         symbol         |-> symbol.value,
         expiryDate     |-> expiryDate.value,
         strikePrice    |-> strikePrice.value,
         optionType     |-> optionType.value ], optionType.rest)

ZeroContractDescTr4 ==
    [ instrumentName |-> [i \in 1 .. 6 |-> 0],
      symbol         |-> [i \in 1 .. 10 |-> 0],
      expiryDate     |-> [i \in 1 .. 4 |-> 0],
      strikePrice    |-> [i \in 1 .. 4 |-> 0],
      optionType     |-> [i \in 1 .. 2 |-> 0] ]

(* Contract Desc Tr at zero, then each field in turn at the values it is checked at *)
CheckedContractDescTr4 ==
    { ZeroContractDescTr4 }
        \cup { [ZeroContractDescTr4 EXCEPT !.instrumentName = one] : one \in Sample(6) }
        \cup { [ZeroContractDescTr4 EXCEPT !.symbol = one] : one \in Sample(10) }
        \cup { [ZeroContractDescTr4 EXCEPT !.expiryDate = one] : one \in Sample(4) }
        \cup { [ZeroContractDescTr4 EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroContractDescTr4 EXCEPT !.optionType = one] : one \in Sample(2) }

(***************************************************************************)
(* Trade Confirmation Trimmed Message: 228 bytes                           *)
(***************************************************************************)

TradeConfirmationTrimmedMessage ==
    [ logTime                  : Sample(4),
      traderId                 : Sample(4),
      timeStamp                : Sample(8),
      timestamp1Double         : Sample(8),
      timestamp2Double         : Sample(8),
      responseOrderNumber      : Sample(8),
      brokerId                 : Sample(5),
      reserved1                : Sample(1),
      accountNumber            : Sample(10),
      buySellIndicator         : Sample(2),
      originalVolume           : Sample(4),
      disclosedVolume          : Sample(4),
      remainingVolume          : Sample(4),
      disclosedVolumeRemaining : Sample(4),
      price                    : Sample(4),
      stOrderFlags             : Sample(2),
      goodTillDate             : Sample(4),
      fillNumber               : Sample(4),
      fillQuantity             : Sample(4),
      fillPrice                : Sample(4),
      volumeFilledToday        : Sample(4),
      activityType             : Sample(2),
      activityTime             : Sample(4),
      token                    : Sample(4),
      contractDescTr           : ContractDescTr4,
      openClose                : Sample(1),
      tradeBookType            : Sample(1),
      participant              : Sample(12),
      additionalOrderFlags     : Sample(1),
      pan                      : Sample(10),
      secondReserved1          : Sample(1),
      algoId                   : Sample(4),
      reserved2                : Sample(2),
      lastActivityReference    : Sample(8),
      reserved52               : Sample(52) ]

EncodeTradeConfirmationTrimmedMessage(message) ==
    message.logTime
        \o message.traderId
        \o message.timeStamp
        \o message.timestamp1Double
        \o message.timestamp2Double
        \o message.responseOrderNumber
        \o message.brokerId
        \o message.reserved1
        \o message.accountNumber
        \o message.buySellIndicator
        \o message.originalVolume
        \o message.disclosedVolume
        \o message.remainingVolume
        \o message.disclosedVolumeRemaining
        \o message.price
        \o message.stOrderFlags
        \o message.goodTillDate
        \o message.fillNumber
        \o message.fillQuantity
        \o message.fillPrice
        \o message.volumeFilledToday
        \o message.activityType
        \o message.activityTime
        \o message.token
        \o EncodeContractDescTr4(message.contractDescTr)
        \o message.openClose
        \o message.tradeBookType
        \o message.participant
        \o message.additionalOrderFlags
        \o message.pan
        \o message.secondReserved1
        \o message.algoId
        \o message.reserved2
        \o message.lastActivityReference
        \o message.reserved52

DecodeTradeConfirmationTrimmedMessage(bytes) ==
    LET logTime == ReadBytes(bytes, 4) IN IF ~logTime.ok THEN Fail ELSE
    LET traderId == ReadBytes(logTime.rest, 4) IN IF ~traderId.ok THEN Fail ELSE
    LET timeStamp == ReadBytes(traderId.rest, 8) IN IF ~timeStamp.ok THEN Fail ELSE
    LET timestamp1Double == ReadBytes(timeStamp.rest, 8) IN IF ~timestamp1Double.ok THEN Fail ELSE
    LET timestamp2Double == ReadBytes(timestamp1Double.rest, 8) IN IF ~timestamp2Double.ok THEN Fail ELSE
    LET responseOrderNumber == ReadBytes(timestamp2Double.rest, 8) IN IF ~responseOrderNumber.ok THEN Fail ELSE
    LET brokerId == ReadBytes(responseOrderNumber.rest, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(brokerId.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(reserved1.rest, 10) IN IF ~accountNumber.ok THEN Fail ELSE
    LET buySellIndicator == ReadBytes(accountNumber.rest, 2) IN IF ~buySellIndicator.ok THEN Fail ELSE
    LET originalVolume == ReadBytes(buySellIndicator.rest, 4) IN IF ~originalVolume.ok THEN Fail ELSE
    LET disclosedVolume == ReadBytes(originalVolume.rest, 4) IN IF ~disclosedVolume.ok THEN Fail ELSE
    LET remainingVolume == ReadBytes(disclosedVolume.rest, 4) IN IF ~remainingVolume.ok THEN Fail ELSE
    LET disclosedVolumeRemaining == ReadBytes(remainingVolume.rest, 4) IN IF ~disclosedVolumeRemaining.ok THEN Fail ELSE
    LET price == ReadBytes(disclosedVolumeRemaining.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(price.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET goodTillDate == ReadBytes(stOrderFlags.rest, 4) IN IF ~goodTillDate.ok THEN Fail ELSE
    LET fillNumber == ReadBytes(goodTillDate.rest, 4) IN IF ~fillNumber.ok THEN Fail ELSE
    LET fillQuantity == ReadBytes(fillNumber.rest, 4) IN IF ~fillQuantity.ok THEN Fail ELSE
    LET fillPrice == ReadBytes(fillQuantity.rest, 4) IN IF ~fillPrice.ok THEN Fail ELSE
    LET volumeFilledToday == ReadBytes(fillPrice.rest, 4) IN IF ~volumeFilledToday.ok THEN Fail ELSE
    LET activityType == ReadBytes(volumeFilledToday.rest, 2) IN IF ~activityType.ok THEN Fail ELSE
    LET activityTime == ReadBytes(activityType.rest, 4) IN IF ~activityTime.ok THEN Fail ELSE
    LET token == ReadBytes(activityTime.rest, 4) IN IF ~token.ok THEN Fail ELSE
    LET contractDescTr == DecodeContractDescTr4(token.rest) IN IF ~contractDescTr.ok THEN Fail ELSE
    LET openClose == ReadBytes(contractDescTr.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET tradeBookType == ReadBytes(openClose.rest, 1) IN IF ~tradeBookType.ok THEN Fail ELSE
    LET participant == ReadBytes(tradeBookType.rest, 12) IN IF ~participant.ok THEN Fail ELSE
    LET additionalOrderFlags == ReadBytes(participant.rest, 1) IN IF ~additionalOrderFlags.ok THEN Fail ELSE
    LET pan == ReadBytes(additionalOrderFlags.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET secondReserved1 == ReadBytes(pan.rest, 1) IN IF ~secondReserved1.ok THEN Fail ELSE
    LET algoId == ReadBytes(secondReserved1.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(algoId.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET lastActivityReference == ReadBytes(reserved2.rest, 8) IN IF ~lastActivityReference.ok THEN Fail ELSE
    LET reserved52 == ReadBytes(lastActivityReference.rest, 52) IN IF ~reserved52.ok THEN Fail ELSE
    Ok([ logTime                  |-> logTime.value,
         traderId                 |-> traderId.value,
         timeStamp                |-> timeStamp.value,
         timestamp1Double         |-> timestamp1Double.value,
         timestamp2Double         |-> timestamp2Double.value,
         responseOrderNumber      |-> responseOrderNumber.value,
         brokerId                 |-> brokerId.value,
         reserved1                |-> reserved1.value,
         accountNumber            |-> accountNumber.value,
         buySellIndicator         |-> buySellIndicator.value,
         originalVolume           |-> originalVolume.value,
         disclosedVolume          |-> disclosedVolume.value,
         remainingVolume          |-> remainingVolume.value,
         disclosedVolumeRemaining |-> disclosedVolumeRemaining.value,
         price                    |-> price.value,
         stOrderFlags             |-> stOrderFlags.value,
         goodTillDate             |-> goodTillDate.value,
         fillNumber               |-> fillNumber.value,
         fillQuantity             |-> fillQuantity.value,
         fillPrice                |-> fillPrice.value,
         volumeFilledToday        |-> volumeFilledToday.value,
         activityType             |-> activityType.value,
         activityTime             |-> activityTime.value,
         token                    |-> token.value,
         contractDescTr           |-> contractDescTr.value,
         openClose                |-> openClose.value,
         tradeBookType            |-> tradeBookType.value,
         participant              |-> participant.value,
         additionalOrderFlags     |-> additionalOrderFlags.value,
         pan                      |-> pan.value,
         secondReserved1          |-> secondReserved1.value,
         algoId                   |-> algoId.value,
         reserved2                |-> reserved2.value,
         lastActivityReference    |-> lastActivityReference.value,
         reserved52               |-> reserved52.value ], reserved52.rest)

ZeroTradeConfirmationTrimmedMessage ==
    [ logTime                  |-> [i \in 1 .. 4 |-> 0],
      traderId                 |-> [i \in 1 .. 4 |-> 0],
      timeStamp                |-> [i \in 1 .. 8 |-> 0],
      timestamp1Double         |-> [i \in 1 .. 8 |-> 0],
      timestamp2Double         |-> [i \in 1 .. 8 |-> 0],
      responseOrderNumber      |-> [i \in 1 .. 8 |-> 0],
      brokerId                 |-> [i \in 1 .. 5 |-> 0],
      reserved1                |-> [i \in 1 .. 1 |-> 0],
      accountNumber            |-> [i \in 1 .. 10 |-> 0],
      buySellIndicator         |-> [i \in 1 .. 2 |-> 0],
      originalVolume           |-> [i \in 1 .. 4 |-> 0],
      disclosedVolume          |-> [i \in 1 .. 4 |-> 0],
      remainingVolume          |-> [i \in 1 .. 4 |-> 0],
      disclosedVolumeRemaining |-> [i \in 1 .. 4 |-> 0],
      price                    |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags             |-> [i \in 1 .. 2 |-> 0],
      goodTillDate             |-> [i \in 1 .. 4 |-> 0],
      fillNumber               |-> [i \in 1 .. 4 |-> 0],
      fillQuantity             |-> [i \in 1 .. 4 |-> 0],
      fillPrice                |-> [i \in 1 .. 4 |-> 0],
      volumeFilledToday        |-> [i \in 1 .. 4 |-> 0],
      activityType             |-> [i \in 1 .. 2 |-> 0],
      activityTime             |-> [i \in 1 .. 4 |-> 0],
      token                    |-> [i \in 1 .. 4 |-> 0],
      contractDescTr           |-> ZeroContractDescTr4,
      openClose                |-> [i \in 1 .. 1 |-> 0],
      tradeBookType            |-> [i \in 1 .. 1 |-> 0],
      participant              |-> [i \in 1 .. 12 |-> 0],
      additionalOrderFlags     |-> [i \in 1 .. 1 |-> 0],
      pan                      |-> [i \in 1 .. 10 |-> 0],
      secondReserved1          |-> [i \in 1 .. 1 |-> 0],
      algoId                   |-> [i \in 1 .. 4 |-> 0],
      reserved2                |-> [i \in 1 .. 2 |-> 0],
      lastActivityReference    |-> [i \in 1 .. 8 |-> 0],
      reserved52               |-> [i \in 1 .. 52 |-> 0] ]

(* Trade Confirmation Trimmed Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeConfirmationTrimmedMessage ==
    { ZeroTradeConfirmationTrimmedMessage }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.logTime = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.traderId = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.timeStamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.timestamp1Double = one] : one \in Sample(8) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.timestamp2Double = one] : one \in Sample(8) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.responseOrderNumber = one] : one \in Sample(8) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.accountNumber = one] : one \in Sample(10) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.buySellIndicator = one] : one \in Sample(2) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.originalVolume = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.disclosedVolume = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.remainingVolume = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.disclosedVolumeRemaining = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.goodTillDate = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.fillNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.fillQuantity = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.fillPrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.volumeFilledToday = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.activityType = one] : one \in Sample(2) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.activityTime = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.token = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.contractDescTr = one] : one \in CheckedContractDescTr4 }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.tradeBookType = one] : one \in Sample(1) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.participant = one] : one \in Sample(12) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.additionalOrderFlags = one] : one \in Sample(1) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.secondReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.lastActivityReference = one] : one \in Sample(8) }
        \cup { [ZeroTradeConfirmationTrimmedMessage EXCEPT !.reserved52 = one] : one \in Sample(52) }

(***************************************************************************)
(* Quick Acknowledgement Message: 20 bytes                                 *)
(***************************************************************************)

QuickAcknowledgementMessage ==
    [ traderId      : Sample(4),
      timeStamp     : Sample(8),
      reference     : Sample(4),
      errorCode     : Sample(2),
      messageLength : Sample(2) ]

EncodeQuickAcknowledgementMessage(message) ==
    message.traderId
        \o message.timeStamp
        \o message.reference
        \o message.errorCode
        \o message.messageLength

DecodeQuickAcknowledgementMessage(bytes) ==
    LET traderId == ReadBytes(bytes, 4) IN IF ~traderId.ok THEN Fail ELSE
    LET timeStamp == ReadBytes(traderId.rest, 8) IN IF ~timeStamp.ok THEN Fail ELSE
    LET reference == ReadBytes(timeStamp.rest, 4) IN IF ~reference.ok THEN Fail ELSE
    LET errorCode == ReadBytes(reference.rest, 2) IN IF ~errorCode.ok THEN Fail ELSE
    LET messageLength == ReadBytes(errorCode.rest, 2) IN IF ~messageLength.ok THEN Fail ELSE
    Ok([ traderId      |-> traderId.value,
         timeStamp     |-> timeStamp.value,
         reference     |-> reference.value,
         errorCode     |-> errorCode.value,
         messageLength |-> messageLength.value ], messageLength.rest)

ZeroQuickAcknowledgementMessage ==
    [ traderId      |-> [i \in 1 .. 4 |-> 0],
      timeStamp     |-> [i \in 1 .. 8 |-> 0],
      reference     |-> [i \in 1 .. 4 |-> 0],
      errorCode     |-> [i \in 1 .. 2 |-> 0],
      messageLength |-> [i \in 1 .. 2 |-> 0] ]

(* Quick Acknowledgement Message at zero, then each field in turn at the values it is checked at *)
CheckedQuickAcknowledgementMessage ==
    { ZeroQuickAcknowledgementMessage }
        \cup { [ZeroQuickAcknowledgementMessage EXCEPT !.traderId = one] : one \in Sample(4) }
        \cup { [ZeroQuickAcknowledgementMessage EXCEPT !.timeStamp = one] : one \in Sample(8) }
        \cup { [ZeroQuickAcknowledgementMessage EXCEPT !.reference = one] : one \in Sample(4) }
        \cup { [ZeroQuickAcknowledgementMessage EXCEPT !.errorCode = one] : one \in Sample(2) }
        \cup { [ZeroQuickAcknowledgementMessage EXCEPT !.messageLength = one] : one \in Sample(2) }

(***************************************************************************)
(* Message Payload, selected by Transaction Code                           *)
(***************************************************************************)

BoardLotInTrimmedMessageCode == 20000  \* 0x4e20
BoardLotInTrimmedMessageCode2 == 20400  \* 0x4fb0
OrderModifyCancelTrimmedMessageCode == 20040  \* 0x4e48
OrderModifyCancelTrimmedMessageCode2 == 20060  \* 0x4e5c
OrderModifyCancelTrimmedMessageCode3 == 20070  \* 0x4e66
OrderModifyCancelTrimmedMessageCode4 == 20402  \* 0x4fb2
OrderModifyCancelTrimmedMessageCode5 == 20404  \* 0x4fb4
OrderConfirmationTrimmedMessageCode == 20073  \* 0x4e69
OrderConfirmationTrimmedMessageCode2 == 20074  \* 0x4e6a
OrderConfirmationTrimmedMessageCode3 == 20075  \* 0x4e6b
TradeConfirmationTrimmedMessageCode == 20222  \* 0x4efe
QuickAcknowledgementMessageCode == 20401  \* 0x4fb1
QuickAcknowledgementMessageCode2 == 20403  \* 0x4fb3
QuickAcknowledgementMessageCode3 == 20405  \* 0x4fb5
QuickAcknowledgementMessageCode4 == 20407  \* 0x4fb7
QuickAcknowledgementMessageCode5 == 20409  \* 0x4fb9
QuickAcknowledgementMessageCode6 == 20411  \* 0x4fbb
QuickAcknowledgementMessageCode7 == 20413  \* 0x4fbd
QuickAcknowledgementMessageCode8 == 20415  \* 0x4fbf
QuickAcknowledgementMessageCode9 == 20417  \* 0x4fc1

MessagePayload ==
    [ tag : {BoardLotInTrimmedMessageCode}, body : BoardLotInTrimmedMessage ]
        \cup [ tag : {BoardLotInTrimmedMessageCode2}, body : BoardLotInTrimmedMessage ]
        \cup [ tag : {OrderModifyCancelTrimmedMessageCode}, body : OrderModifyCancelTrimmedMessage ]
        \cup [ tag : {OrderModifyCancelTrimmedMessageCode2}, body : OrderModifyCancelTrimmedMessage ]
        \cup [ tag : {OrderModifyCancelTrimmedMessageCode3}, body : OrderModifyCancelTrimmedMessage ]
        \cup [ tag : {OrderModifyCancelTrimmedMessageCode4}, body : OrderModifyCancelTrimmedMessage ]
        \cup [ tag : {OrderModifyCancelTrimmedMessageCode5}, body : OrderModifyCancelTrimmedMessage ]
        \cup [ tag : {OrderConfirmationTrimmedMessageCode}, body : OrderConfirmationTrimmedMessage ]
        \cup [ tag : {OrderConfirmationTrimmedMessageCode2}, body : OrderConfirmationTrimmedMessage ]
        \cup [ tag : {OrderConfirmationTrimmedMessageCode3}, body : OrderConfirmationTrimmedMessage ]
        \cup [ tag : {TradeConfirmationTrimmedMessageCode}, body : TradeConfirmationTrimmedMessage ]
        \cup [ tag : {QuickAcknowledgementMessageCode}, body : QuickAcknowledgementMessage ]
        \cup [ tag : {QuickAcknowledgementMessageCode2}, body : QuickAcknowledgementMessage ]
        \cup [ tag : {QuickAcknowledgementMessageCode3}, body : QuickAcknowledgementMessage ]
        \cup [ tag : {QuickAcknowledgementMessageCode4}, body : QuickAcknowledgementMessage ]
        \cup [ tag : {QuickAcknowledgementMessageCode5}, body : QuickAcknowledgementMessage ]
        \cup [ tag : {QuickAcknowledgementMessageCode6}, body : QuickAcknowledgementMessage ]
        \cup [ tag : {QuickAcknowledgementMessageCode7}, body : QuickAcknowledgementMessage ]
        \cup [ tag : {QuickAcknowledgementMessageCode8}, body : QuickAcknowledgementMessage ]
        \cup [ tag : {QuickAcknowledgementMessageCode9}, body : QuickAcknowledgementMessage ]

EncodeMessagePayload(message) ==
    CASE message.tag = BoardLotInTrimmedMessageCode -> EncodeBoardLotInTrimmedMessage(message.body)
      [] message.tag = BoardLotInTrimmedMessageCode2 -> EncodeBoardLotInTrimmedMessage(message.body)
      [] message.tag = OrderModifyCancelTrimmedMessageCode -> EncodeOrderModifyCancelTrimmedMessage(message.body)
      [] message.tag = OrderModifyCancelTrimmedMessageCode2 -> EncodeOrderModifyCancelTrimmedMessage(message.body)
      [] message.tag = OrderModifyCancelTrimmedMessageCode3 -> EncodeOrderModifyCancelTrimmedMessage(message.body)
      [] message.tag = OrderModifyCancelTrimmedMessageCode4 -> EncodeOrderModifyCancelTrimmedMessage(message.body)
      [] message.tag = OrderModifyCancelTrimmedMessageCode5 -> EncodeOrderModifyCancelTrimmedMessage(message.body)
      [] message.tag = OrderConfirmationTrimmedMessageCode -> EncodeOrderConfirmationTrimmedMessage(message.body)
      [] message.tag = OrderConfirmationTrimmedMessageCode2 -> EncodeOrderConfirmationTrimmedMessage(message.body)
      [] message.tag = OrderConfirmationTrimmedMessageCode3 -> EncodeOrderConfirmationTrimmedMessage(message.body)
      [] message.tag = TradeConfirmationTrimmedMessageCode -> EncodeTradeConfirmationTrimmedMessage(message.body)
      [] message.tag = QuickAcknowledgementMessageCode -> EncodeQuickAcknowledgementMessage(message.body)
      [] message.tag = QuickAcknowledgementMessageCode2 -> EncodeQuickAcknowledgementMessage(message.body)
      [] message.tag = QuickAcknowledgementMessageCode3 -> EncodeQuickAcknowledgementMessage(message.body)
      [] message.tag = QuickAcknowledgementMessageCode4 -> EncodeQuickAcknowledgementMessage(message.body)
      [] message.tag = QuickAcknowledgementMessageCode5 -> EncodeQuickAcknowledgementMessage(message.body)
      [] message.tag = QuickAcknowledgementMessageCode6 -> EncodeQuickAcknowledgementMessage(message.body)
      [] message.tag = QuickAcknowledgementMessageCode7 -> EncodeQuickAcknowledgementMessage(message.body)
      [] message.tag = QuickAcknowledgementMessageCode8 -> EncodeQuickAcknowledgementMessage(message.body)
      [] message.tag = QuickAcknowledgementMessageCode9 -> EncodeQuickAcknowledgementMessage(message.body)

DecodeMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = BoardLotInTrimmedMessageCode -> DecodeBoardLotInTrimmedMessage(bytes)
              [] tag = BoardLotInTrimmedMessageCode2 -> DecodeBoardLotInTrimmedMessage(bytes)
              [] tag = OrderModifyCancelTrimmedMessageCode -> DecodeOrderModifyCancelTrimmedMessage(bytes)
              [] tag = OrderModifyCancelTrimmedMessageCode2 -> DecodeOrderModifyCancelTrimmedMessage(bytes)
              [] tag = OrderModifyCancelTrimmedMessageCode3 -> DecodeOrderModifyCancelTrimmedMessage(bytes)
              [] tag = OrderModifyCancelTrimmedMessageCode4 -> DecodeOrderModifyCancelTrimmedMessage(bytes)
              [] tag = OrderModifyCancelTrimmedMessageCode5 -> DecodeOrderModifyCancelTrimmedMessage(bytes)
              [] tag = OrderConfirmationTrimmedMessageCode -> DecodeOrderConfirmationTrimmedMessage(bytes)
              [] tag = OrderConfirmationTrimmedMessageCode2 -> DecodeOrderConfirmationTrimmedMessage(bytes)
              [] tag = OrderConfirmationTrimmedMessageCode3 -> DecodeOrderConfirmationTrimmedMessage(bytes)
              [] tag = TradeConfirmationTrimmedMessageCode -> DecodeTradeConfirmationTrimmedMessage(bytes)
              [] tag = QuickAcknowledgementMessageCode -> DecodeQuickAcknowledgementMessage(bytes)
              [] tag = QuickAcknowledgementMessageCode2 -> DecodeQuickAcknowledgementMessage(bytes)
              [] tag = QuickAcknowledgementMessageCode3 -> DecodeQuickAcknowledgementMessage(bytes)
              [] tag = QuickAcknowledgementMessageCode4 -> DecodeQuickAcknowledgementMessage(bytes)
              [] tag = QuickAcknowledgementMessageCode5 -> DecodeQuickAcknowledgementMessage(bytes)
              [] tag = QuickAcknowledgementMessageCode6 -> DecodeQuickAcknowledgementMessage(bytes)
              [] tag = QuickAcknowledgementMessageCode7 -> DecodeQuickAcknowledgementMessage(bytes)
              [] tag = QuickAcknowledgementMessageCode8 -> DecodeQuickAcknowledgementMessage(bytes)
              [] tag = QuickAcknowledgementMessageCode9 -> DecodeQuickAcknowledgementMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroMessagePayload == [tag |-> BoardLotInTrimmedMessageCode, body |-> ZeroBoardLotInTrimmedMessage]

(* Each Message Payload in turn, at the values the message it names is checked at *)
CheckedMessagePayload ==
    { [tag |-> BoardLotInTrimmedMessageCode, body |-> one] : one \in CheckedBoardLotInTrimmedMessage }
        \cup { [tag |-> BoardLotInTrimmedMessageCode2, body |-> one] : one \in CheckedBoardLotInTrimmedMessage }
        \cup { [tag |-> OrderModifyCancelTrimmedMessageCode, body |-> one] : one \in CheckedOrderModifyCancelTrimmedMessage }
        \cup { [tag |-> OrderModifyCancelTrimmedMessageCode2, body |-> one] : one \in CheckedOrderModifyCancelTrimmedMessage }
        \cup { [tag |-> OrderModifyCancelTrimmedMessageCode3, body |-> one] : one \in CheckedOrderModifyCancelTrimmedMessage }
        \cup { [tag |-> OrderModifyCancelTrimmedMessageCode4, body |-> one] : one \in CheckedOrderModifyCancelTrimmedMessage }
        \cup { [tag |-> OrderModifyCancelTrimmedMessageCode5, body |-> one] : one \in CheckedOrderModifyCancelTrimmedMessage }
        \cup { [tag |-> OrderConfirmationTrimmedMessageCode, body |-> one] : one \in CheckedOrderConfirmationTrimmedMessage }
        \cup { [tag |-> OrderConfirmationTrimmedMessageCode2, body |-> one] : one \in CheckedOrderConfirmationTrimmedMessage }
        \cup { [tag |-> OrderConfirmationTrimmedMessageCode3, body |-> one] : one \in CheckedOrderConfirmationTrimmedMessage }
        \cup { [tag |-> TradeConfirmationTrimmedMessageCode, body |-> one] : one \in CheckedTradeConfirmationTrimmedMessage }
        \cup { [tag |-> QuickAcknowledgementMessageCode, body |-> one] : one \in CheckedQuickAcknowledgementMessage }
        \cup { [tag |-> QuickAcknowledgementMessageCode2, body |-> one] : one \in CheckedQuickAcknowledgementMessage }
        \cup { [tag |-> QuickAcknowledgementMessageCode3, body |-> one] : one \in CheckedQuickAcknowledgementMessage }
        \cup { [tag |-> QuickAcknowledgementMessageCode4, body |-> one] : one \in CheckedQuickAcknowledgementMessage }
        \cup { [tag |-> QuickAcknowledgementMessageCode5, body |-> one] : one \in CheckedQuickAcknowledgementMessage }
        \cup { [tag |-> QuickAcknowledgementMessageCode6, body |-> one] : one \in CheckedQuickAcknowledgementMessage }
        \cup { [tag |-> QuickAcknowledgementMessageCode7, body |-> one] : one \in CheckedQuickAcknowledgementMessage }
        \cup { [tag |-> QuickAcknowledgementMessageCode8, body |-> one] : one \in CheckedQuickAcknowledgementMessage }
        \cup { [tag |-> QuickAcknowledgementMessageCode9, body |-> one] : one \in CheckedQuickAcknowledgementMessage }

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
    { [ZeroMessage EXCEPT !.messagePayload = [tag |-> BoardLotInTrimmedMessageCode, body |-> ZeroBoardLotInTrimmedMessage]],
      [ZeroMessage EXCEPT !.messagePayload = [tag |-> BoardLotInTrimmedMessageCode2, body |-> ZeroBoardLotInTrimmedMessage]],
      [ZeroMessage EXCEPT !.messagePayload = [tag |-> OrderModifyCancelTrimmedMessageCode, body |-> ZeroOrderModifyCancelTrimmedMessage]],
      [ZeroMessage EXCEPT !.messagePayload = [tag |-> OrderModifyCancelTrimmedMessageCode2, body |-> ZeroOrderModifyCancelTrimmedMessage]],
      [ZeroMessage EXCEPT !.messagePayload = [tag |-> OrderModifyCancelTrimmedMessageCode3, body |-> ZeroOrderModifyCancelTrimmedMessage]],
      [ZeroMessage EXCEPT !.messagePayload = [tag |-> OrderModifyCancelTrimmedMessageCode4, body |-> ZeroOrderModifyCancelTrimmedMessage]],
      [ZeroMessage EXCEPT !.messagePayload = [tag |-> OrderModifyCancelTrimmedMessageCode5, body |-> ZeroOrderModifyCancelTrimmedMessage]],
      [ZeroMessage EXCEPT !.messagePayload = [tag |-> OrderConfirmationTrimmedMessageCode, body |-> ZeroOrderConfirmationTrimmedMessage]],
      [ZeroMessage EXCEPT !.messagePayload = [tag |-> OrderConfirmationTrimmedMessageCode2, body |-> ZeroOrderConfirmationTrimmedMessage]],
      [ZeroMessage EXCEPT !.messagePayload = [tag |-> OrderConfirmationTrimmedMessageCode3, body |-> ZeroOrderConfirmationTrimmedMessage]],
      [ZeroMessage EXCEPT !.messagePayload = [tag |-> TradeConfirmationTrimmedMessageCode, body |-> ZeroTradeConfirmationTrimmedMessage]],
      [ZeroMessage EXCEPT !.messagePayload = [tag |-> QuickAcknowledgementMessageCode, body |-> ZeroQuickAcknowledgementMessage]],
      [ZeroMessage EXCEPT !.messagePayload = [tag |-> QuickAcknowledgementMessageCode2, body |-> ZeroQuickAcknowledgementMessage]],
      [ZeroMessage EXCEPT !.messagePayload = [tag |-> QuickAcknowledgementMessageCode3, body |-> ZeroQuickAcknowledgementMessage]],
      [ZeroMessage EXCEPT !.messagePayload = [tag |-> QuickAcknowledgementMessageCode4, body |-> ZeroQuickAcknowledgementMessage]],
      [ZeroMessage EXCEPT !.messagePayload = [tag |-> QuickAcknowledgementMessageCode5, body |-> ZeroQuickAcknowledgementMessage]],
      [ZeroMessage EXCEPT !.messagePayload = [tag |-> QuickAcknowledgementMessageCode6, body |-> ZeroQuickAcknowledgementMessage]],
      [ZeroMessage EXCEPT !.messagePayload = [tag |-> QuickAcknowledgementMessageCode7, body |-> ZeroQuickAcknowledgementMessage]],
      [ZeroMessage EXCEPT !.messagePayload = [tag |-> QuickAcknowledgementMessageCode8, body |-> ZeroQuickAcknowledgementMessage]],
      [ZeroMessage EXCEPT !.messagePayload = [tag |-> QuickAcknowledgementMessageCode9, body |-> ZeroQuickAcknowledgementMessage]] }

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

(* Every Contract Desc Tr decodes back to what was encoded, and leaves nothing over *)
RoundTripContractDescTr ==
    \A message \in CheckedContractDescTr :
        LET read == DecodeContractDescTr(EncodeContractDescTr(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Board Lot In Trimmed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBoardLotInTrimmedMessage ==
    \A message \in CheckedBoardLotInTrimmedMessage :
        LET read == DecodeBoardLotInTrimmedMessage(EncodeBoardLotInTrimmedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Contract Desc Tr decodes back to what was encoded, and leaves nothing over *)
RoundTripContractDescTr2 ==
    \A message \in CheckedContractDescTr2 :
        LET read == DecodeContractDescTr2(EncodeContractDescTr2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Modify Cancel Trimmed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderModifyCancelTrimmedMessage ==
    \A message \in CheckedOrderModifyCancelTrimmedMessage :
        LET read == DecodeOrderModifyCancelTrimmedMessage(EncodeOrderModifyCancelTrimmedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Contract Desc Tr decodes back to what was encoded, and leaves nothing over *)
RoundTripContractDescTr3 ==
    \A message \in CheckedContractDescTr3 :
        LET read == DecodeContractDescTr3(EncodeContractDescTr3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Confirmation Trimmed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderConfirmationTrimmedMessage ==
    \A message \in CheckedOrderConfirmationTrimmedMessage :
        LET read == DecodeOrderConfirmationTrimmedMessage(EncodeOrderConfirmationTrimmedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Contract Desc Tr decodes back to what was encoded, and leaves nothing over *)
RoundTripContractDescTr4 ==
    \A message \in CheckedContractDescTr4 :
        LET read == DecodeContractDescTr4(EncodeContractDescTr4(message))
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
