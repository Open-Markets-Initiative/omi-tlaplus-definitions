-------------------- MODULE NseFo_DropCopy_v3_0_Server ---------------------
(***************************************************************************)
(* National Stock Exchange of India Ltd Drop Copy v3.0                     *)
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
(* Note: a Compression Indicator of any value but 1 says nothing           *)
(* transformed Message Buffer, which is then read as it stands.            *)
(*                                                                         *)
(* Note: Message Buffer is not framed: its size rule does not read a       *)
(* length field.                                                           *)
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
(* Message Buffer                                                          *)
(***************************************************************************)

MessageBufferLz4 ==
    [ transformed : SampleBytes ]

EncodeMessageBufferLz4(message) ==
    message.transformed

DecodeMessageBufferLz4(bytes) ==
    LET transformed == Ok(bytes, << >>) IN IF ~transformed.ok THEN Fail ELSE
    Ok([ transformed |-> transformed.value ], transformed.rest)

ZeroMessageBufferLz4 ==
    [ transformed |-> << >> ]

(* Message Buffer at zero, then each field in turn at the values it is checked at *)
CheckedMessageBufferLz4 ==
    { ZeroMessageBufferLz4 }
        \cup { [ZeroMessageBufferLz4 EXCEPT !.transformed = one] : one \in SampleBytes }

(***************************************************************************)
(* Ip Details Partition Wise: 26 bytes                                     *)
(***************************************************************************)

IpDetailsPartitionWise ==
    [ ipAddress   : Sample(16),
      port        : Sample(4),
      partitionId : Sample(6) ]

EncodeIpDetailsPartitionWise(message) ==
    message.ipAddress
        \o message.port
        \o message.partitionId

DecodeIpDetailsPartitionWise(bytes) ==
    LET ipAddress == ReadBytes(bytes, 16) IN IF ~ipAddress.ok THEN Fail ELSE
    LET port == ReadBytes(ipAddress.rest, 4) IN IF ~port.ok THEN Fail ELSE
    LET partitionId == ReadBytes(port.rest, 6) IN IF ~partitionId.ok THEN Fail ELSE
    Ok([ ipAddress   |-> ipAddress.value,
         port        |-> port.value,
         partitionId |-> partitionId.value ], partitionId.rest)

ZeroIpDetailsPartitionWise ==
    [ ipAddress   |-> [i \in 1 .. 16 |-> 0],
      port        |-> [i \in 1 .. 4 |-> 0],
      partitionId |-> [i \in 1 .. 6 |-> 0] ]

(* Ip Details Partition Wise at zero, then each field in turn at the values it is checked at *)
CheckedIpDetailsPartitionWise ==
    { ZeroIpDetailsPartitionWise }
        \cup { [ZeroIpDetailsPartitionWise EXCEPT !.ipAddress = one] : one \in Sample(16) }
        \cup { [ZeroIpDetailsPartitionWise EXCEPT !.port = one] : one \in Sample(4) }
        \cup { [ZeroIpDetailsPartitionWise EXCEPT !.partitionId = one] : one \in Sample(6) }

(***************************************************************************)
(* Gr Response Message: 98 bytes                                           *)
(***************************************************************************)

GrResponseMessage ==
    [ messageIndicator           : Sample(2),
      partitionCount             : Sample(2),
      ipDetailsPartitionWise     : IpDetailsPartitionWise,
      sessionKey                 : Sample(8),
      cryptographicKey           : Sample(32),
      staticCryptographicIv      : Sample(8),
      dynamicCryptographicIv     : Sample(8),
      cryptographicAdditionalKey : Sample(12) ]

EncodeGrResponseMessage(message) ==
    message.messageIndicator
        \o message.partitionCount
        \o EncodeIpDetailsPartitionWise(message.ipDetailsPartitionWise)
        \o message.sessionKey
        \o message.cryptographicKey
        \o message.staticCryptographicIv
        \o message.dynamicCryptographicIv
        \o message.cryptographicAdditionalKey

DecodeGrResponseMessage(bytes) ==
    LET messageIndicator == ReadBytes(bytes, 2) IN IF ~messageIndicator.ok THEN Fail ELSE
    LET partitionCount == ReadBytes(messageIndicator.rest, 2) IN IF ~partitionCount.ok THEN Fail ELSE
    LET ipDetailsPartitionWise == DecodeIpDetailsPartitionWise(partitionCount.rest) IN IF ~ipDetailsPartitionWise.ok THEN Fail ELSE
    LET sessionKey == ReadBytes(ipDetailsPartitionWise.rest, 8) IN IF ~sessionKey.ok THEN Fail ELSE
    LET cryptographicKey == ReadBytes(sessionKey.rest, 32) IN IF ~cryptographicKey.ok THEN Fail ELSE
    LET staticCryptographicIv == ReadBytes(cryptographicKey.rest, 8) IN IF ~staticCryptographicIv.ok THEN Fail ELSE
    LET dynamicCryptographicIv == ReadBytes(staticCryptographicIv.rest, 8) IN IF ~dynamicCryptographicIv.ok THEN Fail ELSE
    LET cryptographicAdditionalKey == ReadBytes(dynamicCryptographicIv.rest, 12) IN IF ~cryptographicAdditionalKey.ok THEN Fail ELSE
    Ok([ messageIndicator           |-> messageIndicator.value,
         partitionCount             |-> partitionCount.value,
         ipDetailsPartitionWise     |-> ipDetailsPartitionWise.value,
         sessionKey                 |-> sessionKey.value,
         cryptographicKey           |-> cryptographicKey.value,
         staticCryptographicIv      |-> staticCryptographicIv.value,
         dynamicCryptographicIv     |-> dynamicCryptographicIv.value,
         cryptographicAdditionalKey |-> cryptographicAdditionalKey.value ], cryptographicAdditionalKey.rest)

ZeroGrResponseMessage ==
    [ messageIndicator           |-> [i \in 1 .. 2 |-> 0],
      partitionCount             |-> [i \in 1 .. 2 |-> 0],
      ipDetailsPartitionWise     |-> ZeroIpDetailsPartitionWise,
      sessionKey                 |-> [i \in 1 .. 8 |-> 0],
      cryptographicKey           |-> [i \in 1 .. 32 |-> 0],
      staticCryptographicIv      |-> [i \in 1 .. 8 |-> 0],
      dynamicCryptographicIv     |-> [i \in 1 .. 8 |-> 0],
      cryptographicAdditionalKey |-> [i \in 1 .. 12 |-> 0] ]

(* Gr Response Message at zero, then each field in turn at the values it is checked at *)
CheckedGrResponseMessage ==
    { ZeroGrResponseMessage }
        \cup { [ZeroGrResponseMessage EXCEPT !.messageIndicator = one] : one \in Sample(2) }
        \cup { [ZeroGrResponseMessage EXCEPT !.partitionCount = one] : one \in Sample(2) }
        \cup { [ZeroGrResponseMessage EXCEPT !.ipDetailsPartitionWise = one] : one \in CheckedIpDetailsPartitionWise }
        \cup { [ZeroGrResponseMessage EXCEPT !.sessionKey = one] : one \in Sample(8) }
        \cup { [ZeroGrResponseMessage EXCEPT !.cryptographicKey = one] : one \in Sample(32) }
        \cup { [ZeroGrResponseMessage EXCEPT !.staticCryptographicIv = one] : one \in Sample(8) }
        \cup { [ZeroGrResponseMessage EXCEPT !.dynamicCryptographicIv = one] : one \in Sample(8) }
        \cup { [ZeroGrResponseMessage EXCEPT !.cryptographicAdditionalKey = one] : one \in Sample(12) }

(***************************************************************************)
(* Dc Signon Out Message: 12 bytes                                         *)
(***************************************************************************)

DcSignonOutMessage ==
    [ userId            : Sample(4),
      partitionId       : Sample(6),
      concurrentLoginId : Sample(2) ]

EncodeDcSignonOutMessage(message) ==
    message.userId
        \o message.partitionId
        \o message.concurrentLoginId

DecodeDcSignonOutMessage(bytes) ==
    LET userId == ReadBytes(bytes, 4) IN IF ~userId.ok THEN Fail ELSE
    LET partitionId == ReadBytes(userId.rest, 6) IN IF ~partitionId.ok THEN Fail ELSE
    LET concurrentLoginId == ReadBytes(partitionId.rest, 2) IN IF ~concurrentLoginId.ok THEN Fail ELSE
    Ok([ userId            |-> userId.value,
         partitionId       |-> partitionId.value,
         concurrentLoginId |-> concurrentLoginId.value ], concurrentLoginId.rest)

ZeroDcSignonOutMessage ==
    [ userId            |-> [i \in 1 .. 4 |-> 0],
      partitionId       |-> [i \in 1 .. 6 |-> 0],
      concurrentLoginId |-> [i \in 1 .. 2 |-> 0] ]

(* Dc Signon Out Message at zero, then each field in turn at the values it is checked at *)
CheckedDcSignonOutMessage ==
    { ZeroDcSignonOutMessage }
        \cup { [ZeroDcSignonOutMessage EXCEPT !.userId = one] : one \in Sample(4) }
        \cup { [ZeroDcSignonOutMessage EXCEPT !.partitionId = one] : one \in Sample(6) }
        \cup { [ZeroDcSignonOutMessage EXCEPT !.concurrentLoginId = one] : one \in Sample(2) }

(***************************************************************************)
(* Dc Sign Off Message: 12 bytes                                           *)
(***************************************************************************)

DcSignOffMessage ==
    [ userId            : Sample(4),
      partitionId       : Sample(6),
      concurrentLoginId : Sample(2) ]

EncodeDcSignOffMessage(message) ==
    message.userId
        \o message.partitionId
        \o message.concurrentLoginId

DecodeDcSignOffMessage(bytes) ==
    LET userId == ReadBytes(bytes, 4) IN IF ~userId.ok THEN Fail ELSE
    LET partitionId == ReadBytes(userId.rest, 6) IN IF ~partitionId.ok THEN Fail ELSE
    LET concurrentLoginId == ReadBytes(partitionId.rest, 2) IN IF ~concurrentLoginId.ok THEN Fail ELSE
    Ok([ userId            |-> userId.value,
         partitionId       |-> partitionId.value,
         concurrentLoginId |-> concurrentLoginId.value ], concurrentLoginId.rest)

ZeroDcSignOffMessage ==
    [ userId            |-> [i \in 1 .. 4 |-> 0],
      partitionId       |-> [i \in 1 .. 6 |-> 0],
      concurrentLoginId |-> [i \in 1 .. 2 |-> 0] ]

(* Dc Sign Off Message at zero, then each field in turn at the values it is checked at *)
CheckedDcSignOffMessage ==
    { ZeroDcSignOffMessage }
        \cup { [ZeroDcSignOffMessage EXCEPT !.userId = one] : one \in Sample(4) }
        \cup { [ZeroDcSignOffMessage EXCEPT !.partitionId = one] : one \in Sample(6) }
        \cup { [ZeroDcSignOffMessage EXCEPT !.concurrentLoginId = one] : one \in Sample(2) }

(***************************************************************************)
(* Dc Error Response Trade Message: 128 bytes                              *)
(***************************************************************************)

DcErrorResponseTradeMessage ==
    [ errorMessage : Sample(128) ]

EncodeDcErrorResponseTradeMessage(message) ==
    message.errorMessage

DecodeDcErrorResponseTradeMessage(bytes) ==
    LET errorMessage == ReadBytes(bytes, 128) IN IF ~errorMessage.ok THEN Fail ELSE
    Ok([ errorMessage |-> errorMessage.value ], errorMessage.rest)

ZeroDcErrorResponseTradeMessage ==
    [ errorMessage |-> [i \in 1 .. 128 |-> 0] ]

(* Dc Error Response Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedDcErrorResponseTradeMessage ==
    { ZeroDcErrorResponseTradeMessage }
        \cup { [ZeroDcErrorResponseTradeMessage EXCEPT !.errorMessage = one] : one \in Sample(128) }

(***************************************************************************)
(* Dc Error Response Order Message: 128 bytes                              *)
(***************************************************************************)

DcErrorResponseOrderMessage ==
    [ errorMessage : Sample(128) ]

EncodeDcErrorResponseOrderMessage(message) ==
    message.errorMessage

DecodeDcErrorResponseOrderMessage(bytes) ==
    LET errorMessage == ReadBytes(bytes, 128) IN IF ~errorMessage.ok THEN Fail ELSE
    Ok([ errorMessage |-> errorMessage.value ], errorMessage.rest)

ZeroDcErrorResponseOrderMessage ==
    [ errorMessage |-> [i \in 1 .. 128 |-> 0] ]

(* Dc Error Response Order Message at zero, then each field in turn at the values it is checked at *)
CheckedDcErrorResponseOrderMessage ==
    { ZeroDcErrorResponseOrderMessage }
        \cup { [ZeroDcErrorResponseOrderMessage EXCEPT !.errorMessage = one] : one \in Sample(128) }

(***************************************************************************)
(* Trade Confirmation Message: 132 bytes                                   *)
(***************************************************************************)

TradeConfirmationMessage ==
    [ orderNumber           : Sample(8),
      traderNumber          : Sample(4),
      buySell               : Sample(2),
      originalVolume        : Sample(4),
      disclosedVolume       : Sample(4),
      remainingVolume       : Sample(4),
      disclosedVolRemaining : Sample(4),
      price                 : Sample(4),
      stOrderFlags          : Sample(2),
      fillNumber            : Sample(4),
      fillQty               : Sample(4),
      fillPrice             : Sample(4),
      token                 : Sample(4),
      bookType              : Sample(2),
      proClientShort2       : Sample(2),
      algoId                : Sample(4),
      activityTimeInNanos   : Sample(8),
      nnfField              : Sample(8),
      segmentShort2         : Sample(2),
      brokerId              : Sample(5),
      filler                : Sample(1),
      pan                   : Sample(10),
      accountNumber         : Sample(10),
      settlor               : Sample(12),
      giveupFlag            : Sample(1),
      openClose             : Sample(1),
      participant           : Sample(12),
      reasonCode            : Sample(2) ]

EncodeTradeConfirmationMessage(message) ==
    message.orderNumber
        \o message.traderNumber
        \o message.buySell
        \o message.originalVolume
        \o message.disclosedVolume
        \o message.remainingVolume
        \o message.disclosedVolRemaining
        \o message.price
        \o message.stOrderFlags
        \o message.fillNumber
        \o message.fillQty
        \o message.fillPrice
        \o message.token
        \o message.bookType
        \o message.proClientShort2
        \o message.algoId
        \o message.activityTimeInNanos
        \o message.nnfField
        \o message.segmentShort2
        \o message.brokerId
        \o message.filler
        \o message.pan
        \o message.accountNumber
        \o message.settlor
        \o message.giveupFlag
        \o message.openClose
        \o message.participant
        \o message.reasonCode

DecodeTradeConfirmationMessage(bytes) ==
    LET orderNumber == ReadBytes(bytes, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET traderNumber == ReadBytes(orderNumber.rest, 4) IN IF ~traderNumber.ok THEN Fail ELSE
    LET buySell == ReadBytes(traderNumber.rest, 2) IN IF ~buySell.ok THEN Fail ELSE
    LET originalVolume == ReadBytes(buySell.rest, 4) IN IF ~originalVolume.ok THEN Fail ELSE
    LET disclosedVolume == ReadBytes(originalVolume.rest, 4) IN IF ~disclosedVolume.ok THEN Fail ELSE
    LET remainingVolume == ReadBytes(disclosedVolume.rest, 4) IN IF ~remainingVolume.ok THEN Fail ELSE
    LET disclosedVolRemaining == ReadBytes(remainingVolume.rest, 4) IN IF ~disclosedVolRemaining.ok THEN Fail ELSE
    LET price == ReadBytes(disclosedVolRemaining.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(price.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET fillNumber == ReadBytes(stOrderFlags.rest, 4) IN IF ~fillNumber.ok THEN Fail ELSE
    LET fillQty == ReadBytes(fillNumber.rest, 4) IN IF ~fillQty.ok THEN Fail ELSE
    LET fillPrice == ReadBytes(fillQty.rest, 4) IN IF ~fillPrice.ok THEN Fail ELSE
    LET token == ReadBytes(fillPrice.rest, 4) IN IF ~token.ok THEN Fail ELSE
    LET bookType == ReadBytes(token.rest, 2) IN IF ~bookType.ok THEN Fail ELSE
    LET proClientShort2 == ReadBytes(bookType.rest, 2) IN IF ~proClientShort2.ok THEN Fail ELSE
    LET algoId == ReadBytes(proClientShort2.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET activityTimeInNanos == ReadBytes(algoId.rest, 8) IN IF ~activityTimeInNanos.ok THEN Fail ELSE
    LET nnfField == ReadBytes(activityTimeInNanos.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET segmentShort2 == ReadBytes(nnfField.rest, 2) IN IF ~segmentShort2.ok THEN Fail ELSE
    LET brokerId == ReadBytes(segmentShort2.rest, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET filler == ReadBytes(brokerId.rest, 1) IN IF ~filler.ok THEN Fail ELSE
    LET pan == ReadBytes(filler.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(pan.rest, 10) IN IF ~accountNumber.ok THEN Fail ELSE
    LET settlor == ReadBytes(accountNumber.rest, 12) IN IF ~settlor.ok THEN Fail ELSE
    LET giveupFlag == ReadBytes(settlor.rest, 1) IN IF ~giveupFlag.ok THEN Fail ELSE
    LET openClose == ReadBytes(giveupFlag.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET participant == ReadBytes(openClose.rest, 12) IN IF ~participant.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(participant.rest, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    Ok([ orderNumber           |-> orderNumber.value,
         traderNumber          |-> traderNumber.value,
         buySell               |-> buySell.value,
         originalVolume        |-> originalVolume.value,
         disclosedVolume       |-> disclosedVolume.value,
         remainingVolume       |-> remainingVolume.value,
         disclosedVolRemaining |-> disclosedVolRemaining.value,
         price                 |-> price.value,
         stOrderFlags          |-> stOrderFlags.value,
         fillNumber            |-> fillNumber.value,
         fillQty               |-> fillQty.value,
         fillPrice             |-> fillPrice.value,
         token                 |-> token.value,
         bookType              |-> bookType.value,
         proClientShort2       |-> proClientShort2.value,
         algoId                |-> algoId.value,
         activityTimeInNanos   |-> activityTimeInNanos.value,
         nnfField              |-> nnfField.value,
         segmentShort2         |-> segmentShort2.value,
         brokerId              |-> brokerId.value,
         filler                |-> filler.value,
         pan                   |-> pan.value,
         accountNumber         |-> accountNumber.value,
         settlor               |-> settlor.value,
         giveupFlag            |-> giveupFlag.value,
         openClose             |-> openClose.value,
         participant           |-> participant.value,
         reasonCode            |-> reasonCode.value ], reasonCode.rest)

ZeroTradeConfirmationMessage ==
    [ orderNumber           |-> [i \in 1 .. 8 |-> 0],
      traderNumber          |-> [i \in 1 .. 4 |-> 0],
      buySell               |-> [i \in 1 .. 2 |-> 0],
      originalVolume        |-> [i \in 1 .. 4 |-> 0],
      disclosedVolume       |-> [i \in 1 .. 4 |-> 0],
      remainingVolume       |-> [i \in 1 .. 4 |-> 0],
      disclosedVolRemaining |-> [i \in 1 .. 4 |-> 0],
      price                 |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags          |-> [i \in 1 .. 2 |-> 0],
      fillNumber            |-> [i \in 1 .. 4 |-> 0],
      fillQty               |-> [i \in 1 .. 4 |-> 0],
      fillPrice             |-> [i \in 1 .. 4 |-> 0],
      token                 |-> [i \in 1 .. 4 |-> 0],
      bookType              |-> [i \in 1 .. 2 |-> 0],
      proClientShort2       |-> [i \in 1 .. 2 |-> 0],
      algoId                |-> [i \in 1 .. 4 |-> 0],
      activityTimeInNanos   |-> [i \in 1 .. 8 |-> 0],
      nnfField              |-> [i \in 1 .. 8 |-> 0],
      segmentShort2         |-> [i \in 1 .. 2 |-> 0],
      brokerId              |-> [i \in 1 .. 5 |-> 0],
      filler                |-> [i \in 1 .. 1 |-> 0],
      pan                   |-> [i \in 1 .. 10 |-> 0],
      accountNumber         |-> [i \in 1 .. 10 |-> 0],
      settlor               |-> [i \in 1 .. 12 |-> 0],
      giveupFlag            |-> [i \in 1 .. 1 |-> 0],
      openClose             |-> [i \in 1 .. 1 |-> 0],
      participant           |-> [i \in 1 .. 12 |-> 0],
      reasonCode            |-> [i \in 1 .. 2 |-> 0] ]

(* Trade Confirmation Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeConfirmationMessage ==
    { ZeroTradeConfirmationMessage }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.traderNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.buySell = one] : one \in Sample(2) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.originalVolume = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.disclosedVolume = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.remainingVolume = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.disclosedVolRemaining = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.fillNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.fillQty = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.fillPrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.token = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.bookType = one] : one \in Sample(2) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.proClientShort2 = one] : one \in Sample(2) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.activityTimeInNanos = one] : one \in Sample(8) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.segmentShort2 = one] : one \in Sample(2) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.filler = one] : one \in Sample(1) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.accountNumber = one] : one \in Sample(10) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.settlor = one] : one \in Sample(12) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.giveupFlag = one] : one \in Sample(1) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.participant = one] : one \in Sample(12) }
        \cup { [ZeroTradeConfirmationMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }

(***************************************************************************)
(* Trade Cancel Confirm Message: 132 bytes                                 *)
(***************************************************************************)

TradeCancelConfirmMessage ==
    [ orderNumber           : Sample(8),
      traderNumber          : Sample(4),
      buySell               : Sample(2),
      originalVolume        : Sample(4),
      disclosedVolume       : Sample(4),
      remainingVolume       : Sample(4),
      disclosedVolRemaining : Sample(4),
      price                 : Sample(4),
      stOrderFlags          : Sample(2),
      fillNumber            : Sample(4),
      fillQty               : Sample(4),
      fillPrice             : Sample(4),
      token                 : Sample(4),
      bookType              : Sample(2),
      proClientShort2       : Sample(2),
      algoId                : Sample(4),
      activityTimeInNanos   : Sample(8),
      nnfField              : Sample(8),
      segmentShort2         : Sample(2),
      brokerId              : Sample(5),
      filler                : Sample(1),
      pan                   : Sample(10),
      accountNumber         : Sample(10),
      settlor               : Sample(12),
      giveupFlag            : Sample(1),
      openClose             : Sample(1),
      participant           : Sample(12),
      reasonCode            : Sample(2) ]

EncodeTradeCancelConfirmMessage(message) ==
    message.orderNumber
        \o message.traderNumber
        \o message.buySell
        \o message.originalVolume
        \o message.disclosedVolume
        \o message.remainingVolume
        \o message.disclosedVolRemaining
        \o message.price
        \o message.stOrderFlags
        \o message.fillNumber
        \o message.fillQty
        \o message.fillPrice
        \o message.token
        \o message.bookType
        \o message.proClientShort2
        \o message.algoId
        \o message.activityTimeInNanos
        \o message.nnfField
        \o message.segmentShort2
        \o message.brokerId
        \o message.filler
        \o message.pan
        \o message.accountNumber
        \o message.settlor
        \o message.giveupFlag
        \o message.openClose
        \o message.participant
        \o message.reasonCode

DecodeTradeCancelConfirmMessage(bytes) ==
    LET orderNumber == ReadBytes(bytes, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET traderNumber == ReadBytes(orderNumber.rest, 4) IN IF ~traderNumber.ok THEN Fail ELSE
    LET buySell == ReadBytes(traderNumber.rest, 2) IN IF ~buySell.ok THEN Fail ELSE
    LET originalVolume == ReadBytes(buySell.rest, 4) IN IF ~originalVolume.ok THEN Fail ELSE
    LET disclosedVolume == ReadBytes(originalVolume.rest, 4) IN IF ~disclosedVolume.ok THEN Fail ELSE
    LET remainingVolume == ReadBytes(disclosedVolume.rest, 4) IN IF ~remainingVolume.ok THEN Fail ELSE
    LET disclosedVolRemaining == ReadBytes(remainingVolume.rest, 4) IN IF ~disclosedVolRemaining.ok THEN Fail ELSE
    LET price == ReadBytes(disclosedVolRemaining.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(price.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET fillNumber == ReadBytes(stOrderFlags.rest, 4) IN IF ~fillNumber.ok THEN Fail ELSE
    LET fillQty == ReadBytes(fillNumber.rest, 4) IN IF ~fillQty.ok THEN Fail ELSE
    LET fillPrice == ReadBytes(fillQty.rest, 4) IN IF ~fillPrice.ok THEN Fail ELSE
    LET token == ReadBytes(fillPrice.rest, 4) IN IF ~token.ok THEN Fail ELSE
    LET bookType == ReadBytes(token.rest, 2) IN IF ~bookType.ok THEN Fail ELSE
    LET proClientShort2 == ReadBytes(bookType.rest, 2) IN IF ~proClientShort2.ok THEN Fail ELSE
    LET algoId == ReadBytes(proClientShort2.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET activityTimeInNanos == ReadBytes(algoId.rest, 8) IN IF ~activityTimeInNanos.ok THEN Fail ELSE
    LET nnfField == ReadBytes(activityTimeInNanos.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET segmentShort2 == ReadBytes(nnfField.rest, 2) IN IF ~segmentShort2.ok THEN Fail ELSE
    LET brokerId == ReadBytes(segmentShort2.rest, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET filler == ReadBytes(brokerId.rest, 1) IN IF ~filler.ok THEN Fail ELSE
    LET pan == ReadBytes(filler.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(pan.rest, 10) IN IF ~accountNumber.ok THEN Fail ELSE
    LET settlor == ReadBytes(accountNumber.rest, 12) IN IF ~settlor.ok THEN Fail ELSE
    LET giveupFlag == ReadBytes(settlor.rest, 1) IN IF ~giveupFlag.ok THEN Fail ELSE
    LET openClose == ReadBytes(giveupFlag.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET participant == ReadBytes(openClose.rest, 12) IN IF ~participant.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(participant.rest, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    Ok([ orderNumber           |-> orderNumber.value,
         traderNumber          |-> traderNumber.value,
         buySell               |-> buySell.value,
         originalVolume        |-> originalVolume.value,
         disclosedVolume       |-> disclosedVolume.value,
         remainingVolume       |-> remainingVolume.value,
         disclosedVolRemaining |-> disclosedVolRemaining.value,
         price                 |-> price.value,
         stOrderFlags          |-> stOrderFlags.value,
         fillNumber            |-> fillNumber.value,
         fillQty               |-> fillQty.value,
         fillPrice             |-> fillPrice.value,
         token                 |-> token.value,
         bookType              |-> bookType.value,
         proClientShort2       |-> proClientShort2.value,
         algoId                |-> algoId.value,
         activityTimeInNanos   |-> activityTimeInNanos.value,
         nnfField              |-> nnfField.value,
         segmentShort2         |-> segmentShort2.value,
         brokerId              |-> brokerId.value,
         filler                |-> filler.value,
         pan                   |-> pan.value,
         accountNumber         |-> accountNumber.value,
         settlor               |-> settlor.value,
         giveupFlag            |-> giveupFlag.value,
         openClose             |-> openClose.value,
         participant           |-> participant.value,
         reasonCode            |-> reasonCode.value ], reasonCode.rest)

ZeroTradeCancelConfirmMessage ==
    [ orderNumber           |-> [i \in 1 .. 8 |-> 0],
      traderNumber          |-> [i \in 1 .. 4 |-> 0],
      buySell               |-> [i \in 1 .. 2 |-> 0],
      originalVolume        |-> [i \in 1 .. 4 |-> 0],
      disclosedVolume       |-> [i \in 1 .. 4 |-> 0],
      remainingVolume       |-> [i \in 1 .. 4 |-> 0],
      disclosedVolRemaining |-> [i \in 1 .. 4 |-> 0],
      price                 |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags          |-> [i \in 1 .. 2 |-> 0],
      fillNumber            |-> [i \in 1 .. 4 |-> 0],
      fillQty               |-> [i \in 1 .. 4 |-> 0],
      fillPrice             |-> [i \in 1 .. 4 |-> 0],
      token                 |-> [i \in 1 .. 4 |-> 0],
      bookType              |-> [i \in 1 .. 2 |-> 0],
      proClientShort2       |-> [i \in 1 .. 2 |-> 0],
      algoId                |-> [i \in 1 .. 4 |-> 0],
      activityTimeInNanos   |-> [i \in 1 .. 8 |-> 0],
      nnfField              |-> [i \in 1 .. 8 |-> 0],
      segmentShort2         |-> [i \in 1 .. 2 |-> 0],
      brokerId              |-> [i \in 1 .. 5 |-> 0],
      filler                |-> [i \in 1 .. 1 |-> 0],
      pan                   |-> [i \in 1 .. 10 |-> 0],
      accountNumber         |-> [i \in 1 .. 10 |-> 0],
      settlor               |-> [i \in 1 .. 12 |-> 0],
      giveupFlag            |-> [i \in 1 .. 1 |-> 0],
      openClose             |-> [i \in 1 .. 1 |-> 0],
      participant           |-> [i \in 1 .. 12 |-> 0],
      reasonCode            |-> [i \in 1 .. 2 |-> 0] ]

(* Trade Cancel Confirm Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCancelConfirmMessage ==
    { ZeroTradeCancelConfirmMessage }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.traderNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.buySell = one] : one \in Sample(2) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.originalVolume = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.disclosedVolume = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.remainingVolume = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.disclosedVolRemaining = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.fillNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.fillQty = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.fillPrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.token = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.bookType = one] : one \in Sample(2) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.proClientShort2 = one] : one \in Sample(2) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.activityTimeInNanos = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.segmentShort2 = one] : one \in Sample(2) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.filler = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.accountNumber = one] : one \in Sample(10) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.settlor = one] : one \in Sample(12) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.giveupFlag = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.participant = one] : one \in Sample(12) }
        \cup { [ZeroTradeCancelConfirmMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }

(***************************************************************************)
(* Trade Cancel Reject Message: 132 bytes                                  *)
(***************************************************************************)

TradeCancelRejectMessage ==
    [ orderNumber           : Sample(8),
      traderNumber          : Sample(4),
      buySell               : Sample(2),
      originalVolume        : Sample(4),
      disclosedVolume       : Sample(4),
      remainingVolume       : Sample(4),
      disclosedVolRemaining : Sample(4),
      price                 : Sample(4),
      stOrderFlags          : Sample(2),
      fillNumber            : Sample(4),
      fillQty               : Sample(4),
      fillPrice             : Sample(4),
      token                 : Sample(4),
      bookType              : Sample(2),
      proClientShort2       : Sample(2),
      algoId                : Sample(4),
      activityTimeInNanos   : Sample(8),
      nnfField              : Sample(8),
      segmentShort2         : Sample(2),
      brokerId              : Sample(5),
      filler                : Sample(1),
      pan                   : Sample(10),
      accountNumber         : Sample(10),
      settlor               : Sample(12),
      giveupFlag            : Sample(1),
      openClose             : Sample(1),
      participant           : Sample(12),
      reasonCode            : Sample(2) ]

EncodeTradeCancelRejectMessage(message) ==
    message.orderNumber
        \o message.traderNumber
        \o message.buySell
        \o message.originalVolume
        \o message.disclosedVolume
        \o message.remainingVolume
        \o message.disclosedVolRemaining
        \o message.price
        \o message.stOrderFlags
        \o message.fillNumber
        \o message.fillQty
        \o message.fillPrice
        \o message.token
        \o message.bookType
        \o message.proClientShort2
        \o message.algoId
        \o message.activityTimeInNanos
        \o message.nnfField
        \o message.segmentShort2
        \o message.brokerId
        \o message.filler
        \o message.pan
        \o message.accountNumber
        \o message.settlor
        \o message.giveupFlag
        \o message.openClose
        \o message.participant
        \o message.reasonCode

DecodeTradeCancelRejectMessage(bytes) ==
    LET orderNumber == ReadBytes(bytes, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET traderNumber == ReadBytes(orderNumber.rest, 4) IN IF ~traderNumber.ok THEN Fail ELSE
    LET buySell == ReadBytes(traderNumber.rest, 2) IN IF ~buySell.ok THEN Fail ELSE
    LET originalVolume == ReadBytes(buySell.rest, 4) IN IF ~originalVolume.ok THEN Fail ELSE
    LET disclosedVolume == ReadBytes(originalVolume.rest, 4) IN IF ~disclosedVolume.ok THEN Fail ELSE
    LET remainingVolume == ReadBytes(disclosedVolume.rest, 4) IN IF ~remainingVolume.ok THEN Fail ELSE
    LET disclosedVolRemaining == ReadBytes(remainingVolume.rest, 4) IN IF ~disclosedVolRemaining.ok THEN Fail ELSE
    LET price == ReadBytes(disclosedVolRemaining.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(price.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET fillNumber == ReadBytes(stOrderFlags.rest, 4) IN IF ~fillNumber.ok THEN Fail ELSE
    LET fillQty == ReadBytes(fillNumber.rest, 4) IN IF ~fillQty.ok THEN Fail ELSE
    LET fillPrice == ReadBytes(fillQty.rest, 4) IN IF ~fillPrice.ok THEN Fail ELSE
    LET token == ReadBytes(fillPrice.rest, 4) IN IF ~token.ok THEN Fail ELSE
    LET bookType == ReadBytes(token.rest, 2) IN IF ~bookType.ok THEN Fail ELSE
    LET proClientShort2 == ReadBytes(bookType.rest, 2) IN IF ~proClientShort2.ok THEN Fail ELSE
    LET algoId == ReadBytes(proClientShort2.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET activityTimeInNanos == ReadBytes(algoId.rest, 8) IN IF ~activityTimeInNanos.ok THEN Fail ELSE
    LET nnfField == ReadBytes(activityTimeInNanos.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET segmentShort2 == ReadBytes(nnfField.rest, 2) IN IF ~segmentShort2.ok THEN Fail ELSE
    LET brokerId == ReadBytes(segmentShort2.rest, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET filler == ReadBytes(brokerId.rest, 1) IN IF ~filler.ok THEN Fail ELSE
    LET pan == ReadBytes(filler.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(pan.rest, 10) IN IF ~accountNumber.ok THEN Fail ELSE
    LET settlor == ReadBytes(accountNumber.rest, 12) IN IF ~settlor.ok THEN Fail ELSE
    LET giveupFlag == ReadBytes(settlor.rest, 1) IN IF ~giveupFlag.ok THEN Fail ELSE
    LET openClose == ReadBytes(giveupFlag.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET participant == ReadBytes(openClose.rest, 12) IN IF ~participant.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(participant.rest, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    Ok([ orderNumber           |-> orderNumber.value,
         traderNumber          |-> traderNumber.value,
         buySell               |-> buySell.value,
         originalVolume        |-> originalVolume.value,
         disclosedVolume       |-> disclosedVolume.value,
         remainingVolume       |-> remainingVolume.value,
         disclosedVolRemaining |-> disclosedVolRemaining.value,
         price                 |-> price.value,
         stOrderFlags          |-> stOrderFlags.value,
         fillNumber            |-> fillNumber.value,
         fillQty               |-> fillQty.value,
         fillPrice             |-> fillPrice.value,
         token                 |-> token.value,
         bookType              |-> bookType.value,
         proClientShort2       |-> proClientShort2.value,
         algoId                |-> algoId.value,
         activityTimeInNanos   |-> activityTimeInNanos.value,
         nnfField              |-> nnfField.value,
         segmentShort2         |-> segmentShort2.value,
         brokerId              |-> brokerId.value,
         filler                |-> filler.value,
         pan                   |-> pan.value,
         accountNumber         |-> accountNumber.value,
         settlor               |-> settlor.value,
         giveupFlag            |-> giveupFlag.value,
         openClose             |-> openClose.value,
         participant           |-> participant.value,
         reasonCode            |-> reasonCode.value ], reasonCode.rest)

ZeroTradeCancelRejectMessage ==
    [ orderNumber           |-> [i \in 1 .. 8 |-> 0],
      traderNumber          |-> [i \in 1 .. 4 |-> 0],
      buySell               |-> [i \in 1 .. 2 |-> 0],
      originalVolume        |-> [i \in 1 .. 4 |-> 0],
      disclosedVolume       |-> [i \in 1 .. 4 |-> 0],
      remainingVolume       |-> [i \in 1 .. 4 |-> 0],
      disclosedVolRemaining |-> [i \in 1 .. 4 |-> 0],
      price                 |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags          |-> [i \in 1 .. 2 |-> 0],
      fillNumber            |-> [i \in 1 .. 4 |-> 0],
      fillQty               |-> [i \in 1 .. 4 |-> 0],
      fillPrice             |-> [i \in 1 .. 4 |-> 0],
      token                 |-> [i \in 1 .. 4 |-> 0],
      bookType              |-> [i \in 1 .. 2 |-> 0],
      proClientShort2       |-> [i \in 1 .. 2 |-> 0],
      algoId                |-> [i \in 1 .. 4 |-> 0],
      activityTimeInNanos   |-> [i \in 1 .. 8 |-> 0],
      nnfField              |-> [i \in 1 .. 8 |-> 0],
      segmentShort2         |-> [i \in 1 .. 2 |-> 0],
      brokerId              |-> [i \in 1 .. 5 |-> 0],
      filler                |-> [i \in 1 .. 1 |-> 0],
      pan                   |-> [i \in 1 .. 10 |-> 0],
      accountNumber         |-> [i \in 1 .. 10 |-> 0],
      settlor               |-> [i \in 1 .. 12 |-> 0],
      giveupFlag            |-> [i \in 1 .. 1 |-> 0],
      openClose             |-> [i \in 1 .. 1 |-> 0],
      participant           |-> [i \in 1 .. 12 |-> 0],
      reasonCode            |-> [i \in 1 .. 2 |-> 0] ]

(* Trade Cancel Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCancelRejectMessage ==
    { ZeroTradeCancelRejectMessage }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.traderNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.buySell = one] : one \in Sample(2) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.originalVolume = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.disclosedVolume = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.remainingVolume = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.disclosedVolRemaining = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.fillNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.fillQty = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.fillPrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.token = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.bookType = one] : one \in Sample(2) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.proClientShort2 = one] : one \in Sample(2) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.activityTimeInNanos = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.segmentShort2 = one] : one \in Sample(2) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.filler = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.accountNumber = one] : one \in Sample(10) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.settlor = one] : one \in Sample(12) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.giveupFlag = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.participant = one] : one \in Sample(12) }
        \cup { [ZeroTradeCancelRejectMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }

(***************************************************************************)
(* Trade Modify Confirm Message: 132 bytes                                 *)
(***************************************************************************)

TradeModifyConfirmMessage ==
    [ orderNumber           : Sample(8),
      traderNumber          : Sample(4),
      buySell               : Sample(2),
      originalVolume        : Sample(4),
      disclosedVolume       : Sample(4),
      remainingVolume       : Sample(4),
      disclosedVolRemaining : Sample(4),
      price                 : Sample(4),
      stOrderFlags          : Sample(2),
      fillNumber            : Sample(4),
      fillQty               : Sample(4),
      fillPrice             : Sample(4),
      token                 : Sample(4),
      bookType              : Sample(2),
      proClientShort2       : Sample(2),
      algoId                : Sample(4),
      activityTimeInNanos   : Sample(8),
      nnfField              : Sample(8),
      segmentShort2         : Sample(2),
      brokerId              : Sample(5),
      filler                : Sample(1),
      pan                   : Sample(10),
      accountNumber         : Sample(10),
      settlor               : Sample(12),
      giveupFlag            : Sample(1),
      openClose             : Sample(1),
      participant           : Sample(12),
      reasonCode            : Sample(2) ]

EncodeTradeModifyConfirmMessage(message) ==
    message.orderNumber
        \o message.traderNumber
        \o message.buySell
        \o message.originalVolume
        \o message.disclosedVolume
        \o message.remainingVolume
        \o message.disclosedVolRemaining
        \o message.price
        \o message.stOrderFlags
        \o message.fillNumber
        \o message.fillQty
        \o message.fillPrice
        \o message.token
        \o message.bookType
        \o message.proClientShort2
        \o message.algoId
        \o message.activityTimeInNanos
        \o message.nnfField
        \o message.segmentShort2
        \o message.brokerId
        \o message.filler
        \o message.pan
        \o message.accountNumber
        \o message.settlor
        \o message.giveupFlag
        \o message.openClose
        \o message.participant
        \o message.reasonCode

DecodeTradeModifyConfirmMessage(bytes) ==
    LET orderNumber == ReadBytes(bytes, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET traderNumber == ReadBytes(orderNumber.rest, 4) IN IF ~traderNumber.ok THEN Fail ELSE
    LET buySell == ReadBytes(traderNumber.rest, 2) IN IF ~buySell.ok THEN Fail ELSE
    LET originalVolume == ReadBytes(buySell.rest, 4) IN IF ~originalVolume.ok THEN Fail ELSE
    LET disclosedVolume == ReadBytes(originalVolume.rest, 4) IN IF ~disclosedVolume.ok THEN Fail ELSE
    LET remainingVolume == ReadBytes(disclosedVolume.rest, 4) IN IF ~remainingVolume.ok THEN Fail ELSE
    LET disclosedVolRemaining == ReadBytes(remainingVolume.rest, 4) IN IF ~disclosedVolRemaining.ok THEN Fail ELSE
    LET price == ReadBytes(disclosedVolRemaining.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(price.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET fillNumber == ReadBytes(stOrderFlags.rest, 4) IN IF ~fillNumber.ok THEN Fail ELSE
    LET fillQty == ReadBytes(fillNumber.rest, 4) IN IF ~fillQty.ok THEN Fail ELSE
    LET fillPrice == ReadBytes(fillQty.rest, 4) IN IF ~fillPrice.ok THEN Fail ELSE
    LET token == ReadBytes(fillPrice.rest, 4) IN IF ~token.ok THEN Fail ELSE
    LET bookType == ReadBytes(token.rest, 2) IN IF ~bookType.ok THEN Fail ELSE
    LET proClientShort2 == ReadBytes(bookType.rest, 2) IN IF ~proClientShort2.ok THEN Fail ELSE
    LET algoId == ReadBytes(proClientShort2.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET activityTimeInNanos == ReadBytes(algoId.rest, 8) IN IF ~activityTimeInNanos.ok THEN Fail ELSE
    LET nnfField == ReadBytes(activityTimeInNanos.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET segmentShort2 == ReadBytes(nnfField.rest, 2) IN IF ~segmentShort2.ok THEN Fail ELSE
    LET brokerId == ReadBytes(segmentShort2.rest, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET filler == ReadBytes(brokerId.rest, 1) IN IF ~filler.ok THEN Fail ELSE
    LET pan == ReadBytes(filler.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(pan.rest, 10) IN IF ~accountNumber.ok THEN Fail ELSE
    LET settlor == ReadBytes(accountNumber.rest, 12) IN IF ~settlor.ok THEN Fail ELSE
    LET giveupFlag == ReadBytes(settlor.rest, 1) IN IF ~giveupFlag.ok THEN Fail ELSE
    LET openClose == ReadBytes(giveupFlag.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET participant == ReadBytes(openClose.rest, 12) IN IF ~participant.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(participant.rest, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    Ok([ orderNumber           |-> orderNumber.value,
         traderNumber          |-> traderNumber.value,
         buySell               |-> buySell.value,
         originalVolume        |-> originalVolume.value,
         disclosedVolume       |-> disclosedVolume.value,
         remainingVolume       |-> remainingVolume.value,
         disclosedVolRemaining |-> disclosedVolRemaining.value,
         price                 |-> price.value,
         stOrderFlags          |-> stOrderFlags.value,
         fillNumber            |-> fillNumber.value,
         fillQty               |-> fillQty.value,
         fillPrice             |-> fillPrice.value,
         token                 |-> token.value,
         bookType              |-> bookType.value,
         proClientShort2       |-> proClientShort2.value,
         algoId                |-> algoId.value,
         activityTimeInNanos   |-> activityTimeInNanos.value,
         nnfField              |-> nnfField.value,
         segmentShort2         |-> segmentShort2.value,
         brokerId              |-> brokerId.value,
         filler                |-> filler.value,
         pan                   |-> pan.value,
         accountNumber         |-> accountNumber.value,
         settlor               |-> settlor.value,
         giveupFlag            |-> giveupFlag.value,
         openClose             |-> openClose.value,
         participant           |-> participant.value,
         reasonCode            |-> reasonCode.value ], reasonCode.rest)

ZeroTradeModifyConfirmMessage ==
    [ orderNumber           |-> [i \in 1 .. 8 |-> 0],
      traderNumber          |-> [i \in 1 .. 4 |-> 0],
      buySell               |-> [i \in 1 .. 2 |-> 0],
      originalVolume        |-> [i \in 1 .. 4 |-> 0],
      disclosedVolume       |-> [i \in 1 .. 4 |-> 0],
      remainingVolume       |-> [i \in 1 .. 4 |-> 0],
      disclosedVolRemaining |-> [i \in 1 .. 4 |-> 0],
      price                 |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags          |-> [i \in 1 .. 2 |-> 0],
      fillNumber            |-> [i \in 1 .. 4 |-> 0],
      fillQty               |-> [i \in 1 .. 4 |-> 0],
      fillPrice             |-> [i \in 1 .. 4 |-> 0],
      token                 |-> [i \in 1 .. 4 |-> 0],
      bookType              |-> [i \in 1 .. 2 |-> 0],
      proClientShort2       |-> [i \in 1 .. 2 |-> 0],
      algoId                |-> [i \in 1 .. 4 |-> 0],
      activityTimeInNanos   |-> [i \in 1 .. 8 |-> 0],
      nnfField              |-> [i \in 1 .. 8 |-> 0],
      segmentShort2         |-> [i \in 1 .. 2 |-> 0],
      brokerId              |-> [i \in 1 .. 5 |-> 0],
      filler                |-> [i \in 1 .. 1 |-> 0],
      pan                   |-> [i \in 1 .. 10 |-> 0],
      accountNumber         |-> [i \in 1 .. 10 |-> 0],
      settlor               |-> [i \in 1 .. 12 |-> 0],
      giveupFlag            |-> [i \in 1 .. 1 |-> 0],
      openClose             |-> [i \in 1 .. 1 |-> 0],
      participant           |-> [i \in 1 .. 12 |-> 0],
      reasonCode            |-> [i \in 1 .. 2 |-> 0] ]

(* Trade Modify Confirm Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeModifyConfirmMessage ==
    { ZeroTradeModifyConfirmMessage }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.traderNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.buySell = one] : one \in Sample(2) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.originalVolume = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.disclosedVolume = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.remainingVolume = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.disclosedVolRemaining = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.fillNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.fillQty = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.fillPrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.token = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.bookType = one] : one \in Sample(2) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.proClientShort2 = one] : one \in Sample(2) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.activityTimeInNanos = one] : one \in Sample(8) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.segmentShort2 = one] : one \in Sample(2) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.filler = one] : one \in Sample(1) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.accountNumber = one] : one \in Sample(10) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.settlor = one] : one \in Sample(12) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.giveupFlag = one] : one \in Sample(1) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.participant = one] : one \in Sample(12) }
        \cup { [ZeroTradeModifyConfirmMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }

(***************************************************************************)
(* Trade Modify Rejected Message: 132 bytes                                *)
(***************************************************************************)

TradeModifyRejectedMessage ==
    [ orderNumber           : Sample(8),
      traderNumber          : Sample(4),
      buySell               : Sample(2),
      originalVolume        : Sample(4),
      disclosedVolume       : Sample(4),
      remainingVolume       : Sample(4),
      disclosedVolRemaining : Sample(4),
      price                 : Sample(4),
      stOrderFlags          : Sample(2),
      fillNumber            : Sample(4),
      fillQty               : Sample(4),
      fillPrice             : Sample(4),
      token                 : Sample(4),
      bookType              : Sample(2),
      proClientShort2       : Sample(2),
      algoId                : Sample(4),
      activityTimeInNanos   : Sample(8),
      nnfField              : Sample(8),
      segmentShort2         : Sample(2),
      brokerId              : Sample(5),
      filler                : Sample(1),
      pan                   : Sample(10),
      accountNumber         : Sample(10),
      settlor               : Sample(12),
      giveupFlag            : Sample(1),
      openClose             : Sample(1),
      participant           : Sample(12),
      reasonCode            : Sample(2) ]

EncodeTradeModifyRejectedMessage(message) ==
    message.orderNumber
        \o message.traderNumber
        \o message.buySell
        \o message.originalVolume
        \o message.disclosedVolume
        \o message.remainingVolume
        \o message.disclosedVolRemaining
        \o message.price
        \o message.stOrderFlags
        \o message.fillNumber
        \o message.fillQty
        \o message.fillPrice
        \o message.token
        \o message.bookType
        \o message.proClientShort2
        \o message.algoId
        \o message.activityTimeInNanos
        \o message.nnfField
        \o message.segmentShort2
        \o message.brokerId
        \o message.filler
        \o message.pan
        \o message.accountNumber
        \o message.settlor
        \o message.giveupFlag
        \o message.openClose
        \o message.participant
        \o message.reasonCode

DecodeTradeModifyRejectedMessage(bytes) ==
    LET orderNumber == ReadBytes(bytes, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET traderNumber == ReadBytes(orderNumber.rest, 4) IN IF ~traderNumber.ok THEN Fail ELSE
    LET buySell == ReadBytes(traderNumber.rest, 2) IN IF ~buySell.ok THEN Fail ELSE
    LET originalVolume == ReadBytes(buySell.rest, 4) IN IF ~originalVolume.ok THEN Fail ELSE
    LET disclosedVolume == ReadBytes(originalVolume.rest, 4) IN IF ~disclosedVolume.ok THEN Fail ELSE
    LET remainingVolume == ReadBytes(disclosedVolume.rest, 4) IN IF ~remainingVolume.ok THEN Fail ELSE
    LET disclosedVolRemaining == ReadBytes(remainingVolume.rest, 4) IN IF ~disclosedVolRemaining.ok THEN Fail ELSE
    LET price == ReadBytes(disclosedVolRemaining.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(price.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET fillNumber == ReadBytes(stOrderFlags.rest, 4) IN IF ~fillNumber.ok THEN Fail ELSE
    LET fillQty == ReadBytes(fillNumber.rest, 4) IN IF ~fillQty.ok THEN Fail ELSE
    LET fillPrice == ReadBytes(fillQty.rest, 4) IN IF ~fillPrice.ok THEN Fail ELSE
    LET token == ReadBytes(fillPrice.rest, 4) IN IF ~token.ok THEN Fail ELSE
    LET bookType == ReadBytes(token.rest, 2) IN IF ~bookType.ok THEN Fail ELSE
    LET proClientShort2 == ReadBytes(bookType.rest, 2) IN IF ~proClientShort2.ok THEN Fail ELSE
    LET algoId == ReadBytes(proClientShort2.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET activityTimeInNanos == ReadBytes(algoId.rest, 8) IN IF ~activityTimeInNanos.ok THEN Fail ELSE
    LET nnfField == ReadBytes(activityTimeInNanos.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET segmentShort2 == ReadBytes(nnfField.rest, 2) IN IF ~segmentShort2.ok THEN Fail ELSE
    LET brokerId == ReadBytes(segmentShort2.rest, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET filler == ReadBytes(brokerId.rest, 1) IN IF ~filler.ok THEN Fail ELSE
    LET pan == ReadBytes(filler.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(pan.rest, 10) IN IF ~accountNumber.ok THEN Fail ELSE
    LET settlor == ReadBytes(accountNumber.rest, 12) IN IF ~settlor.ok THEN Fail ELSE
    LET giveupFlag == ReadBytes(settlor.rest, 1) IN IF ~giveupFlag.ok THEN Fail ELSE
    LET openClose == ReadBytes(giveupFlag.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET participant == ReadBytes(openClose.rest, 12) IN IF ~participant.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(participant.rest, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    Ok([ orderNumber           |-> orderNumber.value,
         traderNumber          |-> traderNumber.value,
         buySell               |-> buySell.value,
         originalVolume        |-> originalVolume.value,
         disclosedVolume       |-> disclosedVolume.value,
         remainingVolume       |-> remainingVolume.value,
         disclosedVolRemaining |-> disclosedVolRemaining.value,
         price                 |-> price.value,
         stOrderFlags          |-> stOrderFlags.value,
         fillNumber            |-> fillNumber.value,
         fillQty               |-> fillQty.value,
         fillPrice             |-> fillPrice.value,
         token                 |-> token.value,
         bookType              |-> bookType.value,
         proClientShort2       |-> proClientShort2.value,
         algoId                |-> algoId.value,
         activityTimeInNanos   |-> activityTimeInNanos.value,
         nnfField              |-> nnfField.value,
         segmentShort2         |-> segmentShort2.value,
         brokerId              |-> brokerId.value,
         filler                |-> filler.value,
         pan                   |-> pan.value,
         accountNumber         |-> accountNumber.value,
         settlor               |-> settlor.value,
         giveupFlag            |-> giveupFlag.value,
         openClose             |-> openClose.value,
         participant           |-> participant.value,
         reasonCode            |-> reasonCode.value ], reasonCode.rest)

ZeroTradeModifyRejectedMessage ==
    [ orderNumber           |-> [i \in 1 .. 8 |-> 0],
      traderNumber          |-> [i \in 1 .. 4 |-> 0],
      buySell               |-> [i \in 1 .. 2 |-> 0],
      originalVolume        |-> [i \in 1 .. 4 |-> 0],
      disclosedVolume       |-> [i \in 1 .. 4 |-> 0],
      remainingVolume       |-> [i \in 1 .. 4 |-> 0],
      disclosedVolRemaining |-> [i \in 1 .. 4 |-> 0],
      price                 |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags          |-> [i \in 1 .. 2 |-> 0],
      fillNumber            |-> [i \in 1 .. 4 |-> 0],
      fillQty               |-> [i \in 1 .. 4 |-> 0],
      fillPrice             |-> [i \in 1 .. 4 |-> 0],
      token                 |-> [i \in 1 .. 4 |-> 0],
      bookType              |-> [i \in 1 .. 2 |-> 0],
      proClientShort2       |-> [i \in 1 .. 2 |-> 0],
      algoId                |-> [i \in 1 .. 4 |-> 0],
      activityTimeInNanos   |-> [i \in 1 .. 8 |-> 0],
      nnfField              |-> [i \in 1 .. 8 |-> 0],
      segmentShort2         |-> [i \in 1 .. 2 |-> 0],
      brokerId              |-> [i \in 1 .. 5 |-> 0],
      filler                |-> [i \in 1 .. 1 |-> 0],
      pan                   |-> [i \in 1 .. 10 |-> 0],
      accountNumber         |-> [i \in 1 .. 10 |-> 0],
      settlor               |-> [i \in 1 .. 12 |-> 0],
      giveupFlag            |-> [i \in 1 .. 1 |-> 0],
      openClose             |-> [i \in 1 .. 1 |-> 0],
      participant           |-> [i \in 1 .. 12 |-> 0],
      reasonCode            |-> [i \in 1 .. 2 |-> 0] ]

(* Trade Modify Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeModifyRejectedMessage ==
    { ZeroTradeModifyRejectedMessage }
        \cup { [ZeroTradeModifyRejectedMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroTradeModifyRejectedMessage EXCEPT !.traderNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyRejectedMessage EXCEPT !.buySell = one] : one \in Sample(2) }
        \cup { [ZeroTradeModifyRejectedMessage EXCEPT !.originalVolume = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyRejectedMessage EXCEPT !.disclosedVolume = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyRejectedMessage EXCEPT !.remainingVolume = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyRejectedMessage EXCEPT !.disclosedVolRemaining = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyRejectedMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyRejectedMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroTradeModifyRejectedMessage EXCEPT !.fillNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyRejectedMessage EXCEPT !.fillQty = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyRejectedMessage EXCEPT !.fillPrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyRejectedMessage EXCEPT !.token = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyRejectedMessage EXCEPT !.bookType = one] : one \in Sample(2) }
        \cup { [ZeroTradeModifyRejectedMessage EXCEPT !.proClientShort2 = one] : one \in Sample(2) }
        \cup { [ZeroTradeModifyRejectedMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroTradeModifyRejectedMessage EXCEPT !.activityTimeInNanos = one] : one \in Sample(8) }
        \cup { [ZeroTradeModifyRejectedMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroTradeModifyRejectedMessage EXCEPT !.segmentShort2 = one] : one \in Sample(2) }
        \cup { [ZeroTradeModifyRejectedMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroTradeModifyRejectedMessage EXCEPT !.filler = one] : one \in Sample(1) }
        \cup { [ZeroTradeModifyRejectedMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroTradeModifyRejectedMessage EXCEPT !.accountNumber = one] : one \in Sample(10) }
        \cup { [ZeroTradeModifyRejectedMessage EXCEPT !.settlor = one] : one \in Sample(12) }
        \cup { [ZeroTradeModifyRejectedMessage EXCEPT !.giveupFlag = one] : one \in Sample(1) }
        \cup { [ZeroTradeModifyRejectedMessage EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroTradeModifyRejectedMessage EXCEPT !.participant = one] : one \in Sample(12) }
        \cup { [ZeroTradeModifyRejectedMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }

(***************************************************************************)
(* Giveup App Confirm Message: 132 bytes                                   *)
(***************************************************************************)

GiveupAppConfirmMessage ==
    [ orderNumber           : Sample(8),
      traderNumber          : Sample(4),
      buySell               : Sample(2),
      originalVolume        : Sample(4),
      disclosedVolume       : Sample(4),
      remainingVolume       : Sample(4),
      disclosedVolRemaining : Sample(4),
      price                 : Sample(4),
      stOrderFlags          : Sample(2),
      fillNumber            : Sample(4),
      fillQty               : Sample(4),
      fillPrice             : Sample(4),
      token                 : Sample(4),
      bookType              : Sample(2),
      proClientShort2       : Sample(2),
      algoId                : Sample(4),
      activityTimeInNanos   : Sample(8),
      nnfField              : Sample(8),
      segmentShort2         : Sample(2),
      brokerId              : Sample(5),
      filler                : Sample(1),
      pan                   : Sample(10),
      accountNumber         : Sample(10),
      settlor               : Sample(12),
      giveupFlag            : Sample(1),
      openClose             : Sample(1),
      participant           : Sample(12),
      reasonCode            : Sample(2) ]

EncodeGiveupAppConfirmMessage(message) ==
    message.orderNumber
        \o message.traderNumber
        \o message.buySell
        \o message.originalVolume
        \o message.disclosedVolume
        \o message.remainingVolume
        \o message.disclosedVolRemaining
        \o message.price
        \o message.stOrderFlags
        \o message.fillNumber
        \o message.fillQty
        \o message.fillPrice
        \o message.token
        \o message.bookType
        \o message.proClientShort2
        \o message.algoId
        \o message.activityTimeInNanos
        \o message.nnfField
        \o message.segmentShort2
        \o message.brokerId
        \o message.filler
        \o message.pan
        \o message.accountNumber
        \o message.settlor
        \o message.giveupFlag
        \o message.openClose
        \o message.participant
        \o message.reasonCode

DecodeGiveupAppConfirmMessage(bytes) ==
    LET orderNumber == ReadBytes(bytes, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET traderNumber == ReadBytes(orderNumber.rest, 4) IN IF ~traderNumber.ok THEN Fail ELSE
    LET buySell == ReadBytes(traderNumber.rest, 2) IN IF ~buySell.ok THEN Fail ELSE
    LET originalVolume == ReadBytes(buySell.rest, 4) IN IF ~originalVolume.ok THEN Fail ELSE
    LET disclosedVolume == ReadBytes(originalVolume.rest, 4) IN IF ~disclosedVolume.ok THEN Fail ELSE
    LET remainingVolume == ReadBytes(disclosedVolume.rest, 4) IN IF ~remainingVolume.ok THEN Fail ELSE
    LET disclosedVolRemaining == ReadBytes(remainingVolume.rest, 4) IN IF ~disclosedVolRemaining.ok THEN Fail ELSE
    LET price == ReadBytes(disclosedVolRemaining.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(price.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET fillNumber == ReadBytes(stOrderFlags.rest, 4) IN IF ~fillNumber.ok THEN Fail ELSE
    LET fillQty == ReadBytes(fillNumber.rest, 4) IN IF ~fillQty.ok THEN Fail ELSE
    LET fillPrice == ReadBytes(fillQty.rest, 4) IN IF ~fillPrice.ok THEN Fail ELSE
    LET token == ReadBytes(fillPrice.rest, 4) IN IF ~token.ok THEN Fail ELSE
    LET bookType == ReadBytes(token.rest, 2) IN IF ~bookType.ok THEN Fail ELSE
    LET proClientShort2 == ReadBytes(bookType.rest, 2) IN IF ~proClientShort2.ok THEN Fail ELSE
    LET algoId == ReadBytes(proClientShort2.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET activityTimeInNanos == ReadBytes(algoId.rest, 8) IN IF ~activityTimeInNanos.ok THEN Fail ELSE
    LET nnfField == ReadBytes(activityTimeInNanos.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET segmentShort2 == ReadBytes(nnfField.rest, 2) IN IF ~segmentShort2.ok THEN Fail ELSE
    LET brokerId == ReadBytes(segmentShort2.rest, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET filler == ReadBytes(brokerId.rest, 1) IN IF ~filler.ok THEN Fail ELSE
    LET pan == ReadBytes(filler.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(pan.rest, 10) IN IF ~accountNumber.ok THEN Fail ELSE
    LET settlor == ReadBytes(accountNumber.rest, 12) IN IF ~settlor.ok THEN Fail ELSE
    LET giveupFlag == ReadBytes(settlor.rest, 1) IN IF ~giveupFlag.ok THEN Fail ELSE
    LET openClose == ReadBytes(giveupFlag.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET participant == ReadBytes(openClose.rest, 12) IN IF ~participant.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(participant.rest, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    Ok([ orderNumber           |-> orderNumber.value,
         traderNumber          |-> traderNumber.value,
         buySell               |-> buySell.value,
         originalVolume        |-> originalVolume.value,
         disclosedVolume       |-> disclosedVolume.value,
         remainingVolume       |-> remainingVolume.value,
         disclosedVolRemaining |-> disclosedVolRemaining.value,
         price                 |-> price.value,
         stOrderFlags          |-> stOrderFlags.value,
         fillNumber            |-> fillNumber.value,
         fillQty               |-> fillQty.value,
         fillPrice             |-> fillPrice.value,
         token                 |-> token.value,
         bookType              |-> bookType.value,
         proClientShort2       |-> proClientShort2.value,
         algoId                |-> algoId.value,
         activityTimeInNanos   |-> activityTimeInNanos.value,
         nnfField              |-> nnfField.value,
         segmentShort2         |-> segmentShort2.value,
         brokerId              |-> brokerId.value,
         filler                |-> filler.value,
         pan                   |-> pan.value,
         accountNumber         |-> accountNumber.value,
         settlor               |-> settlor.value,
         giveupFlag            |-> giveupFlag.value,
         openClose             |-> openClose.value,
         participant           |-> participant.value,
         reasonCode            |-> reasonCode.value ], reasonCode.rest)

ZeroGiveupAppConfirmMessage ==
    [ orderNumber           |-> [i \in 1 .. 8 |-> 0],
      traderNumber          |-> [i \in 1 .. 4 |-> 0],
      buySell               |-> [i \in 1 .. 2 |-> 0],
      originalVolume        |-> [i \in 1 .. 4 |-> 0],
      disclosedVolume       |-> [i \in 1 .. 4 |-> 0],
      remainingVolume       |-> [i \in 1 .. 4 |-> 0],
      disclosedVolRemaining |-> [i \in 1 .. 4 |-> 0],
      price                 |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags          |-> [i \in 1 .. 2 |-> 0],
      fillNumber            |-> [i \in 1 .. 4 |-> 0],
      fillQty               |-> [i \in 1 .. 4 |-> 0],
      fillPrice             |-> [i \in 1 .. 4 |-> 0],
      token                 |-> [i \in 1 .. 4 |-> 0],
      bookType              |-> [i \in 1 .. 2 |-> 0],
      proClientShort2       |-> [i \in 1 .. 2 |-> 0],
      algoId                |-> [i \in 1 .. 4 |-> 0],
      activityTimeInNanos   |-> [i \in 1 .. 8 |-> 0],
      nnfField              |-> [i \in 1 .. 8 |-> 0],
      segmentShort2         |-> [i \in 1 .. 2 |-> 0],
      brokerId              |-> [i \in 1 .. 5 |-> 0],
      filler                |-> [i \in 1 .. 1 |-> 0],
      pan                   |-> [i \in 1 .. 10 |-> 0],
      accountNumber         |-> [i \in 1 .. 10 |-> 0],
      settlor               |-> [i \in 1 .. 12 |-> 0],
      giveupFlag            |-> [i \in 1 .. 1 |-> 0],
      openClose             |-> [i \in 1 .. 1 |-> 0],
      participant           |-> [i \in 1 .. 12 |-> 0],
      reasonCode            |-> [i \in 1 .. 2 |-> 0] ]

(* Giveup App Confirm Message at zero, then each field in turn at the values it is checked at *)
CheckedGiveupAppConfirmMessage ==
    { ZeroGiveupAppConfirmMessage }
        \cup { [ZeroGiveupAppConfirmMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroGiveupAppConfirmMessage EXCEPT !.traderNumber = one] : one \in Sample(4) }
        \cup { [ZeroGiveupAppConfirmMessage EXCEPT !.buySell = one] : one \in Sample(2) }
        \cup { [ZeroGiveupAppConfirmMessage EXCEPT !.originalVolume = one] : one \in Sample(4) }
        \cup { [ZeroGiveupAppConfirmMessage EXCEPT !.disclosedVolume = one] : one \in Sample(4) }
        \cup { [ZeroGiveupAppConfirmMessage EXCEPT !.remainingVolume = one] : one \in Sample(4) }
        \cup { [ZeroGiveupAppConfirmMessage EXCEPT !.disclosedVolRemaining = one] : one \in Sample(4) }
        \cup { [ZeroGiveupAppConfirmMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroGiveupAppConfirmMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroGiveupAppConfirmMessage EXCEPT !.fillNumber = one] : one \in Sample(4) }
        \cup { [ZeroGiveupAppConfirmMessage EXCEPT !.fillQty = one] : one \in Sample(4) }
        \cup { [ZeroGiveupAppConfirmMessage EXCEPT !.fillPrice = one] : one \in Sample(4) }
        \cup { [ZeroGiveupAppConfirmMessage EXCEPT !.token = one] : one \in Sample(4) }
        \cup { [ZeroGiveupAppConfirmMessage EXCEPT !.bookType = one] : one \in Sample(2) }
        \cup { [ZeroGiveupAppConfirmMessage EXCEPT !.proClientShort2 = one] : one \in Sample(2) }
        \cup { [ZeroGiveupAppConfirmMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroGiveupAppConfirmMessage EXCEPT !.activityTimeInNanos = one] : one \in Sample(8) }
        \cup { [ZeroGiveupAppConfirmMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroGiveupAppConfirmMessage EXCEPT !.segmentShort2 = one] : one \in Sample(2) }
        \cup { [ZeroGiveupAppConfirmMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroGiveupAppConfirmMessage EXCEPT !.filler = one] : one \in Sample(1) }
        \cup { [ZeroGiveupAppConfirmMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroGiveupAppConfirmMessage EXCEPT !.accountNumber = one] : one \in Sample(10) }
        \cup { [ZeroGiveupAppConfirmMessage EXCEPT !.settlor = one] : one \in Sample(12) }
        \cup { [ZeroGiveupAppConfirmMessage EXCEPT !.giveupFlag = one] : one \in Sample(1) }
        \cup { [ZeroGiveupAppConfirmMessage EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroGiveupAppConfirmMessage EXCEPT !.participant = one] : one \in Sample(12) }
        \cup { [ZeroGiveupAppConfirmMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }

(***************************************************************************)
(* Giveup Rej Confirm Message: 132 bytes                                   *)
(***************************************************************************)

GiveupRejConfirmMessage ==
    [ orderNumber           : Sample(8),
      traderNumber          : Sample(4),
      buySell               : Sample(2),
      originalVolume        : Sample(4),
      disclosedVolume       : Sample(4),
      remainingVolume       : Sample(4),
      disclosedVolRemaining : Sample(4),
      price                 : Sample(4),
      stOrderFlags          : Sample(2),
      fillNumber            : Sample(4),
      fillQty               : Sample(4),
      fillPrice             : Sample(4),
      token                 : Sample(4),
      bookType              : Sample(2),
      proClientShort2       : Sample(2),
      algoId                : Sample(4),
      activityTimeInNanos   : Sample(8),
      nnfField              : Sample(8),
      segmentShort2         : Sample(2),
      brokerId              : Sample(5),
      filler                : Sample(1),
      pan                   : Sample(10),
      accountNumber         : Sample(10),
      settlor               : Sample(12),
      giveupFlag            : Sample(1),
      openClose             : Sample(1),
      participant           : Sample(12),
      reasonCode            : Sample(2) ]

EncodeGiveupRejConfirmMessage(message) ==
    message.orderNumber
        \o message.traderNumber
        \o message.buySell
        \o message.originalVolume
        \o message.disclosedVolume
        \o message.remainingVolume
        \o message.disclosedVolRemaining
        \o message.price
        \o message.stOrderFlags
        \o message.fillNumber
        \o message.fillQty
        \o message.fillPrice
        \o message.token
        \o message.bookType
        \o message.proClientShort2
        \o message.algoId
        \o message.activityTimeInNanos
        \o message.nnfField
        \o message.segmentShort2
        \o message.brokerId
        \o message.filler
        \o message.pan
        \o message.accountNumber
        \o message.settlor
        \o message.giveupFlag
        \o message.openClose
        \o message.participant
        \o message.reasonCode

DecodeGiveupRejConfirmMessage(bytes) ==
    LET orderNumber == ReadBytes(bytes, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET traderNumber == ReadBytes(orderNumber.rest, 4) IN IF ~traderNumber.ok THEN Fail ELSE
    LET buySell == ReadBytes(traderNumber.rest, 2) IN IF ~buySell.ok THEN Fail ELSE
    LET originalVolume == ReadBytes(buySell.rest, 4) IN IF ~originalVolume.ok THEN Fail ELSE
    LET disclosedVolume == ReadBytes(originalVolume.rest, 4) IN IF ~disclosedVolume.ok THEN Fail ELSE
    LET remainingVolume == ReadBytes(disclosedVolume.rest, 4) IN IF ~remainingVolume.ok THEN Fail ELSE
    LET disclosedVolRemaining == ReadBytes(remainingVolume.rest, 4) IN IF ~disclosedVolRemaining.ok THEN Fail ELSE
    LET price == ReadBytes(disclosedVolRemaining.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(price.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET fillNumber == ReadBytes(stOrderFlags.rest, 4) IN IF ~fillNumber.ok THEN Fail ELSE
    LET fillQty == ReadBytes(fillNumber.rest, 4) IN IF ~fillQty.ok THEN Fail ELSE
    LET fillPrice == ReadBytes(fillQty.rest, 4) IN IF ~fillPrice.ok THEN Fail ELSE
    LET token == ReadBytes(fillPrice.rest, 4) IN IF ~token.ok THEN Fail ELSE
    LET bookType == ReadBytes(token.rest, 2) IN IF ~bookType.ok THEN Fail ELSE
    LET proClientShort2 == ReadBytes(bookType.rest, 2) IN IF ~proClientShort2.ok THEN Fail ELSE
    LET algoId == ReadBytes(proClientShort2.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET activityTimeInNanos == ReadBytes(algoId.rest, 8) IN IF ~activityTimeInNanos.ok THEN Fail ELSE
    LET nnfField == ReadBytes(activityTimeInNanos.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET segmentShort2 == ReadBytes(nnfField.rest, 2) IN IF ~segmentShort2.ok THEN Fail ELSE
    LET brokerId == ReadBytes(segmentShort2.rest, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET filler == ReadBytes(brokerId.rest, 1) IN IF ~filler.ok THEN Fail ELSE
    LET pan == ReadBytes(filler.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(pan.rest, 10) IN IF ~accountNumber.ok THEN Fail ELSE
    LET settlor == ReadBytes(accountNumber.rest, 12) IN IF ~settlor.ok THEN Fail ELSE
    LET giveupFlag == ReadBytes(settlor.rest, 1) IN IF ~giveupFlag.ok THEN Fail ELSE
    LET openClose == ReadBytes(giveupFlag.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET participant == ReadBytes(openClose.rest, 12) IN IF ~participant.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(participant.rest, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    Ok([ orderNumber           |-> orderNumber.value,
         traderNumber          |-> traderNumber.value,
         buySell               |-> buySell.value,
         originalVolume        |-> originalVolume.value,
         disclosedVolume       |-> disclosedVolume.value,
         remainingVolume       |-> remainingVolume.value,
         disclosedVolRemaining |-> disclosedVolRemaining.value,
         price                 |-> price.value,
         stOrderFlags          |-> stOrderFlags.value,
         fillNumber            |-> fillNumber.value,
         fillQty               |-> fillQty.value,
         fillPrice             |-> fillPrice.value,
         token                 |-> token.value,
         bookType              |-> bookType.value,
         proClientShort2       |-> proClientShort2.value,
         algoId                |-> algoId.value,
         activityTimeInNanos   |-> activityTimeInNanos.value,
         nnfField              |-> nnfField.value,
         segmentShort2         |-> segmentShort2.value,
         brokerId              |-> brokerId.value,
         filler                |-> filler.value,
         pan                   |-> pan.value,
         accountNumber         |-> accountNumber.value,
         settlor               |-> settlor.value,
         giveupFlag            |-> giveupFlag.value,
         openClose             |-> openClose.value,
         participant           |-> participant.value,
         reasonCode            |-> reasonCode.value ], reasonCode.rest)

ZeroGiveupRejConfirmMessage ==
    [ orderNumber           |-> [i \in 1 .. 8 |-> 0],
      traderNumber          |-> [i \in 1 .. 4 |-> 0],
      buySell               |-> [i \in 1 .. 2 |-> 0],
      originalVolume        |-> [i \in 1 .. 4 |-> 0],
      disclosedVolume       |-> [i \in 1 .. 4 |-> 0],
      remainingVolume       |-> [i \in 1 .. 4 |-> 0],
      disclosedVolRemaining |-> [i \in 1 .. 4 |-> 0],
      price                 |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags          |-> [i \in 1 .. 2 |-> 0],
      fillNumber            |-> [i \in 1 .. 4 |-> 0],
      fillQty               |-> [i \in 1 .. 4 |-> 0],
      fillPrice             |-> [i \in 1 .. 4 |-> 0],
      token                 |-> [i \in 1 .. 4 |-> 0],
      bookType              |-> [i \in 1 .. 2 |-> 0],
      proClientShort2       |-> [i \in 1 .. 2 |-> 0],
      algoId                |-> [i \in 1 .. 4 |-> 0],
      activityTimeInNanos   |-> [i \in 1 .. 8 |-> 0],
      nnfField              |-> [i \in 1 .. 8 |-> 0],
      segmentShort2         |-> [i \in 1 .. 2 |-> 0],
      brokerId              |-> [i \in 1 .. 5 |-> 0],
      filler                |-> [i \in 1 .. 1 |-> 0],
      pan                   |-> [i \in 1 .. 10 |-> 0],
      accountNumber         |-> [i \in 1 .. 10 |-> 0],
      settlor               |-> [i \in 1 .. 12 |-> 0],
      giveupFlag            |-> [i \in 1 .. 1 |-> 0],
      openClose             |-> [i \in 1 .. 1 |-> 0],
      participant           |-> [i \in 1 .. 12 |-> 0],
      reasonCode            |-> [i \in 1 .. 2 |-> 0] ]

(* Giveup Rej Confirm Message at zero, then each field in turn at the values it is checked at *)
CheckedGiveupRejConfirmMessage ==
    { ZeroGiveupRejConfirmMessage }
        \cup { [ZeroGiveupRejConfirmMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroGiveupRejConfirmMessage EXCEPT !.traderNumber = one] : one \in Sample(4) }
        \cup { [ZeroGiveupRejConfirmMessage EXCEPT !.buySell = one] : one \in Sample(2) }
        \cup { [ZeroGiveupRejConfirmMessage EXCEPT !.originalVolume = one] : one \in Sample(4) }
        \cup { [ZeroGiveupRejConfirmMessage EXCEPT !.disclosedVolume = one] : one \in Sample(4) }
        \cup { [ZeroGiveupRejConfirmMessage EXCEPT !.remainingVolume = one] : one \in Sample(4) }
        \cup { [ZeroGiveupRejConfirmMessage EXCEPT !.disclosedVolRemaining = one] : one \in Sample(4) }
        \cup { [ZeroGiveupRejConfirmMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroGiveupRejConfirmMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroGiveupRejConfirmMessage EXCEPT !.fillNumber = one] : one \in Sample(4) }
        \cup { [ZeroGiveupRejConfirmMessage EXCEPT !.fillQty = one] : one \in Sample(4) }
        \cup { [ZeroGiveupRejConfirmMessage EXCEPT !.fillPrice = one] : one \in Sample(4) }
        \cup { [ZeroGiveupRejConfirmMessage EXCEPT !.token = one] : one \in Sample(4) }
        \cup { [ZeroGiveupRejConfirmMessage EXCEPT !.bookType = one] : one \in Sample(2) }
        \cup { [ZeroGiveupRejConfirmMessage EXCEPT !.proClientShort2 = one] : one \in Sample(2) }
        \cup { [ZeroGiveupRejConfirmMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroGiveupRejConfirmMessage EXCEPT !.activityTimeInNanos = one] : one \in Sample(8) }
        \cup { [ZeroGiveupRejConfirmMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroGiveupRejConfirmMessage EXCEPT !.segmentShort2 = one] : one \in Sample(2) }
        \cup { [ZeroGiveupRejConfirmMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroGiveupRejConfirmMessage EXCEPT !.filler = one] : one \in Sample(1) }
        \cup { [ZeroGiveupRejConfirmMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroGiveupRejConfirmMessage EXCEPT !.accountNumber = one] : one \in Sample(10) }
        \cup { [ZeroGiveupRejConfirmMessage EXCEPT !.settlor = one] : one \in Sample(12) }
        \cup { [ZeroGiveupRejConfirmMessage EXCEPT !.giveupFlag = one] : one \in Sample(1) }
        \cup { [ZeroGiveupRejConfirmMessage EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroGiveupRejConfirmMessage EXCEPT !.participant = one] : one \in Sample(12) }
        \cup { [ZeroGiveupRejConfirmMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }

(***************************************************************************)
(* Price Confirmation Message: 116 bytes                                   *)
(***************************************************************************)

PriceConfirmationMessage ==
    [ reasonCode            : Sample(2),
      token                 : Sample(4),
      orderNumber           : Sample(8),
      bookType              : Sample(2),
      buySell               : Sample(2),
      disclosedVolume       : Sample(4),
      disclosedVolRemaining : Sample(4),
      totalVolRemaining     : Sample(4),
      volume                : Sample(4),
      price                 : Sample(4),
      triggerPrice          : Sample(4),
      stOrderFlags          : Sample(2),
      traderId              : Sample(4),
      nnfField              : Sample(8),
      algoId                : Sample(4),
      activityTimeInNanos   : Sample(8),
      reserved2             : Sample(2),
      secondReserved2       : Sample(2),
      thirdReserved2        : Sample(2),
      suspended             : Sample(1),
      openClose             : Sample(1),
      pan                   : Sample(10),
      segmentChar1          : Sample(1),
      participantType       : Sample(1),
      accountNumber         : Sample(10),
      proClientChar1        : Sample(1),
      reserved1             : Sample(1),
      settlor               : Sample(12),
      referenceId           : Sample(4) ]

EncodePriceConfirmationMessage(message) ==
    message.reasonCode
        \o message.token
        \o message.orderNumber
        \o message.bookType
        \o message.buySell
        \o message.disclosedVolume
        \o message.disclosedVolRemaining
        \o message.totalVolRemaining
        \o message.volume
        \o message.price
        \o message.triggerPrice
        \o message.stOrderFlags
        \o message.traderId
        \o message.nnfField
        \o message.algoId
        \o message.activityTimeInNanos
        \o message.reserved2
        \o message.secondReserved2
        \o message.thirdReserved2
        \o message.suspended
        \o message.openClose
        \o message.pan
        \o message.segmentChar1
        \o message.participantType
        \o message.accountNumber
        \o message.proClientChar1
        \o message.reserved1
        \o message.settlor
        \o message.referenceId

DecodePriceConfirmationMessage(bytes) ==
    LET reasonCode == ReadBytes(bytes, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET token == ReadBytes(reasonCode.rest, 4) IN IF ~token.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(token.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET bookType == ReadBytes(orderNumber.rest, 2) IN IF ~bookType.ok THEN Fail ELSE
    LET buySell == ReadBytes(bookType.rest, 2) IN IF ~buySell.ok THEN Fail ELSE
    LET disclosedVolume == ReadBytes(buySell.rest, 4) IN IF ~disclosedVolume.ok THEN Fail ELSE
    LET disclosedVolRemaining == ReadBytes(disclosedVolume.rest, 4) IN IF ~disclosedVolRemaining.ok THEN Fail ELSE
    LET totalVolRemaining == ReadBytes(disclosedVolRemaining.rest, 4) IN IF ~totalVolRemaining.ok THEN Fail ELSE
    LET volume == ReadBytes(totalVolRemaining.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET price == ReadBytes(volume.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET triggerPrice == ReadBytes(price.rest, 4) IN IF ~triggerPrice.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(triggerPrice.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET traderId == ReadBytes(stOrderFlags.rest, 4) IN IF ~traderId.ok THEN Fail ELSE
    LET nnfField == ReadBytes(traderId.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET algoId == ReadBytes(nnfField.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET activityTimeInNanos == ReadBytes(algoId.rest, 8) IN IF ~activityTimeInNanos.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(activityTimeInNanos.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET secondReserved2 == ReadBytes(reserved2.rest, 2) IN IF ~secondReserved2.ok THEN Fail ELSE
    LET thirdReserved2 == ReadBytes(secondReserved2.rest, 2) IN IF ~thirdReserved2.ok THEN Fail ELSE
    LET suspended == ReadBytes(thirdReserved2.rest, 1) IN IF ~suspended.ok THEN Fail ELSE
    LET openClose == ReadBytes(suspended.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET pan == ReadBytes(openClose.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET segmentChar1 == ReadBytes(pan.rest, 1) IN IF ~segmentChar1.ok THEN Fail ELSE
    LET participantType == ReadBytes(segmentChar1.rest, 1) IN IF ~participantType.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(participantType.rest, 10) IN IF ~accountNumber.ok THEN Fail ELSE
    LET proClientChar1 == ReadBytes(accountNumber.rest, 1) IN IF ~proClientChar1.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(proClientChar1.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET settlor == ReadBytes(reserved1.rest, 12) IN IF ~settlor.ok THEN Fail ELSE
    LET referenceId == ReadBytes(settlor.rest, 4) IN IF ~referenceId.ok THEN Fail ELSE
    Ok([ reasonCode            |-> reasonCode.value,
         token                 |-> token.value,
         orderNumber           |-> orderNumber.value,
         bookType              |-> bookType.value,
         buySell               |-> buySell.value,
         disclosedVolume       |-> disclosedVolume.value,
         disclosedVolRemaining |-> disclosedVolRemaining.value,
         totalVolRemaining     |-> totalVolRemaining.value,
         volume                |-> volume.value,
         price                 |-> price.value,
         triggerPrice          |-> triggerPrice.value,
         stOrderFlags          |-> stOrderFlags.value,
         traderId              |-> traderId.value,
         nnfField              |-> nnfField.value,
         algoId                |-> algoId.value,
         activityTimeInNanos   |-> activityTimeInNanos.value,
         reserved2             |-> reserved2.value,
         secondReserved2       |-> secondReserved2.value,
         thirdReserved2        |-> thirdReserved2.value,
         suspended             |-> suspended.value,
         openClose             |-> openClose.value,
         pan                   |-> pan.value,
         segmentChar1          |-> segmentChar1.value,
         participantType       |-> participantType.value,
         accountNumber         |-> accountNumber.value,
         proClientChar1        |-> proClientChar1.value,
         reserved1             |-> reserved1.value,
         settlor               |-> settlor.value,
         referenceId           |-> referenceId.value ], referenceId.rest)

ZeroPriceConfirmationMessage ==
    [ reasonCode            |-> [i \in 1 .. 2 |-> 0],
      token                 |-> [i \in 1 .. 4 |-> 0],
      orderNumber           |-> [i \in 1 .. 8 |-> 0],
      bookType              |-> [i \in 1 .. 2 |-> 0],
      buySell               |-> [i \in 1 .. 2 |-> 0],
      disclosedVolume       |-> [i \in 1 .. 4 |-> 0],
      disclosedVolRemaining |-> [i \in 1 .. 4 |-> 0],
      totalVolRemaining     |-> [i \in 1 .. 4 |-> 0],
      volume                |-> [i \in 1 .. 4 |-> 0],
      price                 |-> [i \in 1 .. 4 |-> 0],
      triggerPrice          |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags          |-> [i \in 1 .. 2 |-> 0],
      traderId              |-> [i \in 1 .. 4 |-> 0],
      nnfField              |-> [i \in 1 .. 8 |-> 0],
      algoId                |-> [i \in 1 .. 4 |-> 0],
      activityTimeInNanos   |-> [i \in 1 .. 8 |-> 0],
      reserved2             |-> [i \in 1 .. 2 |-> 0],
      secondReserved2       |-> [i \in 1 .. 2 |-> 0],
      thirdReserved2        |-> [i \in 1 .. 2 |-> 0],
      suspended             |-> [i \in 1 .. 1 |-> 0],
      openClose             |-> [i \in 1 .. 1 |-> 0],
      pan                   |-> [i \in 1 .. 10 |-> 0],
      segmentChar1          |-> [i \in 1 .. 1 |-> 0],
      participantType       |-> [i \in 1 .. 1 |-> 0],
      accountNumber         |-> [i \in 1 .. 10 |-> 0],
      proClientChar1        |-> [i \in 1 .. 1 |-> 0],
      reserved1             |-> [i \in 1 .. 1 |-> 0],
      settlor               |-> [i \in 1 .. 12 |-> 0],
      referenceId           |-> [i \in 1 .. 4 |-> 0] ]

(* Price Confirmation Message at zero, then each field in turn at the values it is checked at *)
CheckedPriceConfirmationMessage ==
    { ZeroPriceConfirmationMessage }
        \cup { [ZeroPriceConfirmationMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroPriceConfirmationMessage EXCEPT !.token = one] : one \in Sample(4) }
        \cup { [ZeroPriceConfirmationMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroPriceConfirmationMessage EXCEPT !.bookType = one] : one \in Sample(2) }
        \cup { [ZeroPriceConfirmationMessage EXCEPT !.buySell = one] : one \in Sample(2) }
        \cup { [ZeroPriceConfirmationMessage EXCEPT !.disclosedVolume = one] : one \in Sample(4) }
        \cup { [ZeroPriceConfirmationMessage EXCEPT !.disclosedVolRemaining = one] : one \in Sample(4) }
        \cup { [ZeroPriceConfirmationMessage EXCEPT !.totalVolRemaining = one] : one \in Sample(4) }
        \cup { [ZeroPriceConfirmationMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroPriceConfirmationMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroPriceConfirmationMessage EXCEPT !.triggerPrice = one] : one \in Sample(4) }
        \cup { [ZeroPriceConfirmationMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroPriceConfirmationMessage EXCEPT !.traderId = one] : one \in Sample(4) }
        \cup { [ZeroPriceConfirmationMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroPriceConfirmationMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroPriceConfirmationMessage EXCEPT !.activityTimeInNanos = one] : one \in Sample(8) }
        \cup { [ZeroPriceConfirmationMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroPriceConfirmationMessage EXCEPT !.secondReserved2 = one] : one \in Sample(2) }
        \cup { [ZeroPriceConfirmationMessage EXCEPT !.thirdReserved2 = one] : one \in Sample(2) }
        \cup { [ZeroPriceConfirmationMessage EXCEPT !.suspended = one] : one \in Sample(1) }
        \cup { [ZeroPriceConfirmationMessage EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroPriceConfirmationMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroPriceConfirmationMessage EXCEPT !.segmentChar1 = one] : one \in Sample(1) }
        \cup { [ZeroPriceConfirmationMessage EXCEPT !.participantType = one] : one \in Sample(1) }
        \cup { [ZeroPriceConfirmationMessage EXCEPT !.accountNumber = one] : one \in Sample(10) }
        \cup { [ZeroPriceConfirmationMessage EXCEPT !.proClientChar1 = one] : one \in Sample(1) }
        \cup { [ZeroPriceConfirmationMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroPriceConfirmationMessage EXCEPT !.settlor = one] : one \in Sample(12) }
        \cup { [ZeroPriceConfirmationMessage EXCEPT !.referenceId = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Mod Reject Message: 116 bytes                                     *)
(***************************************************************************)

OrderModRejectMessage ==
    [ reasonCode            : Sample(2),
      token                 : Sample(4),
      orderNumber           : Sample(8),
      bookType              : Sample(2),
      buySell               : Sample(2),
      disclosedVolume       : Sample(4),
      disclosedVolRemaining : Sample(4),
      totalVolRemaining     : Sample(4),
      volume                : Sample(4),
      price                 : Sample(4),
      triggerPrice          : Sample(4),
      stOrderFlags          : Sample(2),
      traderId              : Sample(4),
      nnfField              : Sample(8),
      algoId                : Sample(4),
      activityTimeInNanos   : Sample(8),
      reserved2             : Sample(2),
      secondReserved2       : Sample(2),
      thirdReserved2        : Sample(2),
      suspended             : Sample(1),
      openClose             : Sample(1),
      pan                   : Sample(10),
      segmentChar1          : Sample(1),
      participantType       : Sample(1),
      accountNumber         : Sample(10),
      proClientChar1        : Sample(1),
      reserved1             : Sample(1),
      settlor               : Sample(12),
      referenceId           : Sample(4) ]

EncodeOrderModRejectMessage(message) ==
    message.reasonCode
        \o message.token
        \o message.orderNumber
        \o message.bookType
        \o message.buySell
        \o message.disclosedVolume
        \o message.disclosedVolRemaining
        \o message.totalVolRemaining
        \o message.volume
        \o message.price
        \o message.triggerPrice
        \o message.stOrderFlags
        \o message.traderId
        \o message.nnfField
        \o message.algoId
        \o message.activityTimeInNanos
        \o message.reserved2
        \o message.secondReserved2
        \o message.thirdReserved2
        \o message.suspended
        \o message.openClose
        \o message.pan
        \o message.segmentChar1
        \o message.participantType
        \o message.accountNumber
        \o message.proClientChar1
        \o message.reserved1
        \o message.settlor
        \o message.referenceId

DecodeOrderModRejectMessage(bytes) ==
    LET reasonCode == ReadBytes(bytes, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET token == ReadBytes(reasonCode.rest, 4) IN IF ~token.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(token.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET bookType == ReadBytes(orderNumber.rest, 2) IN IF ~bookType.ok THEN Fail ELSE
    LET buySell == ReadBytes(bookType.rest, 2) IN IF ~buySell.ok THEN Fail ELSE
    LET disclosedVolume == ReadBytes(buySell.rest, 4) IN IF ~disclosedVolume.ok THEN Fail ELSE
    LET disclosedVolRemaining == ReadBytes(disclosedVolume.rest, 4) IN IF ~disclosedVolRemaining.ok THEN Fail ELSE
    LET totalVolRemaining == ReadBytes(disclosedVolRemaining.rest, 4) IN IF ~totalVolRemaining.ok THEN Fail ELSE
    LET volume == ReadBytes(totalVolRemaining.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET price == ReadBytes(volume.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET triggerPrice == ReadBytes(price.rest, 4) IN IF ~triggerPrice.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(triggerPrice.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET traderId == ReadBytes(stOrderFlags.rest, 4) IN IF ~traderId.ok THEN Fail ELSE
    LET nnfField == ReadBytes(traderId.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET algoId == ReadBytes(nnfField.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET activityTimeInNanos == ReadBytes(algoId.rest, 8) IN IF ~activityTimeInNanos.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(activityTimeInNanos.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET secondReserved2 == ReadBytes(reserved2.rest, 2) IN IF ~secondReserved2.ok THEN Fail ELSE
    LET thirdReserved2 == ReadBytes(secondReserved2.rest, 2) IN IF ~thirdReserved2.ok THEN Fail ELSE
    LET suspended == ReadBytes(thirdReserved2.rest, 1) IN IF ~suspended.ok THEN Fail ELSE
    LET openClose == ReadBytes(suspended.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET pan == ReadBytes(openClose.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET segmentChar1 == ReadBytes(pan.rest, 1) IN IF ~segmentChar1.ok THEN Fail ELSE
    LET participantType == ReadBytes(segmentChar1.rest, 1) IN IF ~participantType.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(participantType.rest, 10) IN IF ~accountNumber.ok THEN Fail ELSE
    LET proClientChar1 == ReadBytes(accountNumber.rest, 1) IN IF ~proClientChar1.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(proClientChar1.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET settlor == ReadBytes(reserved1.rest, 12) IN IF ~settlor.ok THEN Fail ELSE
    LET referenceId == ReadBytes(settlor.rest, 4) IN IF ~referenceId.ok THEN Fail ELSE
    Ok([ reasonCode            |-> reasonCode.value,
         token                 |-> token.value,
         orderNumber           |-> orderNumber.value,
         bookType              |-> bookType.value,
         buySell               |-> buySell.value,
         disclosedVolume       |-> disclosedVolume.value,
         disclosedVolRemaining |-> disclosedVolRemaining.value,
         totalVolRemaining     |-> totalVolRemaining.value,
         volume                |-> volume.value,
         price                 |-> price.value,
         triggerPrice          |-> triggerPrice.value,
         stOrderFlags          |-> stOrderFlags.value,
         traderId              |-> traderId.value,
         nnfField              |-> nnfField.value,
         algoId                |-> algoId.value,
         activityTimeInNanos   |-> activityTimeInNanos.value,
         reserved2             |-> reserved2.value,
         secondReserved2       |-> secondReserved2.value,
         thirdReserved2        |-> thirdReserved2.value,
         suspended             |-> suspended.value,
         openClose             |-> openClose.value,
         pan                   |-> pan.value,
         segmentChar1          |-> segmentChar1.value,
         participantType       |-> participantType.value,
         accountNumber         |-> accountNumber.value,
         proClientChar1        |-> proClientChar1.value,
         reserved1             |-> reserved1.value,
         settlor               |-> settlor.value,
         referenceId           |-> referenceId.value ], referenceId.rest)

ZeroOrderModRejectMessage ==
    [ reasonCode            |-> [i \in 1 .. 2 |-> 0],
      token                 |-> [i \in 1 .. 4 |-> 0],
      orderNumber           |-> [i \in 1 .. 8 |-> 0],
      bookType              |-> [i \in 1 .. 2 |-> 0],
      buySell               |-> [i \in 1 .. 2 |-> 0],
      disclosedVolume       |-> [i \in 1 .. 4 |-> 0],
      disclosedVolRemaining |-> [i \in 1 .. 4 |-> 0],
      totalVolRemaining     |-> [i \in 1 .. 4 |-> 0],
      volume                |-> [i \in 1 .. 4 |-> 0],
      price                 |-> [i \in 1 .. 4 |-> 0],
      triggerPrice          |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags          |-> [i \in 1 .. 2 |-> 0],
      traderId              |-> [i \in 1 .. 4 |-> 0],
      nnfField              |-> [i \in 1 .. 8 |-> 0],
      algoId                |-> [i \in 1 .. 4 |-> 0],
      activityTimeInNanos   |-> [i \in 1 .. 8 |-> 0],
      reserved2             |-> [i \in 1 .. 2 |-> 0],
      secondReserved2       |-> [i \in 1 .. 2 |-> 0],
      thirdReserved2        |-> [i \in 1 .. 2 |-> 0],
      suspended             |-> [i \in 1 .. 1 |-> 0],
      openClose             |-> [i \in 1 .. 1 |-> 0],
      pan                   |-> [i \in 1 .. 10 |-> 0],
      segmentChar1          |-> [i \in 1 .. 1 |-> 0],
      participantType       |-> [i \in 1 .. 1 |-> 0],
      accountNumber         |-> [i \in 1 .. 10 |-> 0],
      proClientChar1        |-> [i \in 1 .. 1 |-> 0],
      reserved1             |-> [i \in 1 .. 1 |-> 0],
      settlor               |-> [i \in 1 .. 12 |-> 0],
      referenceId           |-> [i \in 1 .. 4 |-> 0] ]

(* Order Mod Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderModRejectMessage ==
    { ZeroOrderModRejectMessage }
        \cup { [ZeroOrderModRejectMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroOrderModRejectMessage EXCEPT !.token = one] : one \in Sample(4) }
        \cup { [ZeroOrderModRejectMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderModRejectMessage EXCEPT !.bookType = one] : one \in Sample(2) }
        \cup { [ZeroOrderModRejectMessage EXCEPT !.buySell = one] : one \in Sample(2) }
        \cup { [ZeroOrderModRejectMessage EXCEPT !.disclosedVolume = one] : one \in Sample(4) }
        \cup { [ZeroOrderModRejectMessage EXCEPT !.disclosedVolRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderModRejectMessage EXCEPT !.totalVolRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderModRejectMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroOrderModRejectMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderModRejectMessage EXCEPT !.triggerPrice = one] : one \in Sample(4) }
        \cup { [ZeroOrderModRejectMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroOrderModRejectMessage EXCEPT !.traderId = one] : one \in Sample(4) }
        \cup { [ZeroOrderModRejectMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroOrderModRejectMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroOrderModRejectMessage EXCEPT !.activityTimeInNanos = one] : one \in Sample(8) }
        \cup { [ZeroOrderModRejectMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderModRejectMessage EXCEPT !.secondReserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderModRejectMessage EXCEPT !.thirdReserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderModRejectMessage EXCEPT !.suspended = one] : one \in Sample(1) }
        \cup { [ZeroOrderModRejectMessage EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroOrderModRejectMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroOrderModRejectMessage EXCEPT !.segmentChar1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderModRejectMessage EXCEPT !.participantType = one] : one \in Sample(1) }
        \cup { [ZeroOrderModRejectMessage EXCEPT !.accountNumber = one] : one \in Sample(10) }
        \cup { [ZeroOrderModRejectMessage EXCEPT !.proClientChar1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderModRejectMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderModRejectMessage EXCEPT !.settlor = one] : one \in Sample(12) }
        \cup { [ZeroOrderModRejectMessage EXCEPT !.referenceId = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Cancel Reject Message: 116 bytes                                  *)
(***************************************************************************)

OrderCancelRejectMessage ==
    [ reasonCode            : Sample(2),
      token                 : Sample(4),
      orderNumber           : Sample(8),
      bookType              : Sample(2),
      buySell               : Sample(2),
      disclosedVolume       : Sample(4),
      disclosedVolRemaining : Sample(4),
      totalVolRemaining     : Sample(4),
      volume                : Sample(4),
      price                 : Sample(4),
      triggerPrice          : Sample(4),
      stOrderFlags          : Sample(2),
      traderId              : Sample(4),
      nnfField              : Sample(8),
      algoId                : Sample(4),
      activityTimeInNanos   : Sample(8),
      reserved2             : Sample(2),
      secondReserved2       : Sample(2),
      thirdReserved2        : Sample(2),
      suspended             : Sample(1),
      openClose             : Sample(1),
      pan                   : Sample(10),
      segmentChar1          : Sample(1),
      participantType       : Sample(1),
      accountNumber         : Sample(10),
      proClientChar1        : Sample(1),
      reserved1             : Sample(1),
      settlor               : Sample(12),
      referenceId           : Sample(4) ]

EncodeOrderCancelRejectMessage(message) ==
    message.reasonCode
        \o message.token
        \o message.orderNumber
        \o message.bookType
        \o message.buySell
        \o message.disclosedVolume
        \o message.disclosedVolRemaining
        \o message.totalVolRemaining
        \o message.volume
        \o message.price
        \o message.triggerPrice
        \o message.stOrderFlags
        \o message.traderId
        \o message.nnfField
        \o message.algoId
        \o message.activityTimeInNanos
        \o message.reserved2
        \o message.secondReserved2
        \o message.thirdReserved2
        \o message.suspended
        \o message.openClose
        \o message.pan
        \o message.segmentChar1
        \o message.participantType
        \o message.accountNumber
        \o message.proClientChar1
        \o message.reserved1
        \o message.settlor
        \o message.referenceId

DecodeOrderCancelRejectMessage(bytes) ==
    LET reasonCode == ReadBytes(bytes, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET token == ReadBytes(reasonCode.rest, 4) IN IF ~token.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(token.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET bookType == ReadBytes(orderNumber.rest, 2) IN IF ~bookType.ok THEN Fail ELSE
    LET buySell == ReadBytes(bookType.rest, 2) IN IF ~buySell.ok THEN Fail ELSE
    LET disclosedVolume == ReadBytes(buySell.rest, 4) IN IF ~disclosedVolume.ok THEN Fail ELSE
    LET disclosedVolRemaining == ReadBytes(disclosedVolume.rest, 4) IN IF ~disclosedVolRemaining.ok THEN Fail ELSE
    LET totalVolRemaining == ReadBytes(disclosedVolRemaining.rest, 4) IN IF ~totalVolRemaining.ok THEN Fail ELSE
    LET volume == ReadBytes(totalVolRemaining.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET price == ReadBytes(volume.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET triggerPrice == ReadBytes(price.rest, 4) IN IF ~triggerPrice.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(triggerPrice.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET traderId == ReadBytes(stOrderFlags.rest, 4) IN IF ~traderId.ok THEN Fail ELSE
    LET nnfField == ReadBytes(traderId.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET algoId == ReadBytes(nnfField.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET activityTimeInNanos == ReadBytes(algoId.rest, 8) IN IF ~activityTimeInNanos.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(activityTimeInNanos.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET secondReserved2 == ReadBytes(reserved2.rest, 2) IN IF ~secondReserved2.ok THEN Fail ELSE
    LET thirdReserved2 == ReadBytes(secondReserved2.rest, 2) IN IF ~thirdReserved2.ok THEN Fail ELSE
    LET suspended == ReadBytes(thirdReserved2.rest, 1) IN IF ~suspended.ok THEN Fail ELSE
    LET openClose == ReadBytes(suspended.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET pan == ReadBytes(openClose.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET segmentChar1 == ReadBytes(pan.rest, 1) IN IF ~segmentChar1.ok THEN Fail ELSE
    LET participantType == ReadBytes(segmentChar1.rest, 1) IN IF ~participantType.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(participantType.rest, 10) IN IF ~accountNumber.ok THEN Fail ELSE
    LET proClientChar1 == ReadBytes(accountNumber.rest, 1) IN IF ~proClientChar1.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(proClientChar1.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET settlor == ReadBytes(reserved1.rest, 12) IN IF ~settlor.ok THEN Fail ELSE
    LET referenceId == ReadBytes(settlor.rest, 4) IN IF ~referenceId.ok THEN Fail ELSE
    Ok([ reasonCode            |-> reasonCode.value,
         token                 |-> token.value,
         orderNumber           |-> orderNumber.value,
         bookType              |-> bookType.value,
         buySell               |-> buySell.value,
         disclosedVolume       |-> disclosedVolume.value,
         disclosedVolRemaining |-> disclosedVolRemaining.value,
         totalVolRemaining     |-> totalVolRemaining.value,
         volume                |-> volume.value,
         price                 |-> price.value,
         triggerPrice          |-> triggerPrice.value,
         stOrderFlags          |-> stOrderFlags.value,
         traderId              |-> traderId.value,
         nnfField              |-> nnfField.value,
         algoId                |-> algoId.value,
         activityTimeInNanos   |-> activityTimeInNanos.value,
         reserved2             |-> reserved2.value,
         secondReserved2       |-> secondReserved2.value,
         thirdReserved2        |-> thirdReserved2.value,
         suspended             |-> suspended.value,
         openClose             |-> openClose.value,
         pan                   |-> pan.value,
         segmentChar1          |-> segmentChar1.value,
         participantType       |-> participantType.value,
         accountNumber         |-> accountNumber.value,
         proClientChar1        |-> proClientChar1.value,
         reserved1             |-> reserved1.value,
         settlor               |-> settlor.value,
         referenceId           |-> referenceId.value ], referenceId.rest)

ZeroOrderCancelRejectMessage ==
    [ reasonCode            |-> [i \in 1 .. 2 |-> 0],
      token                 |-> [i \in 1 .. 4 |-> 0],
      orderNumber           |-> [i \in 1 .. 8 |-> 0],
      bookType              |-> [i \in 1 .. 2 |-> 0],
      buySell               |-> [i \in 1 .. 2 |-> 0],
      disclosedVolume       |-> [i \in 1 .. 4 |-> 0],
      disclosedVolRemaining |-> [i \in 1 .. 4 |-> 0],
      totalVolRemaining     |-> [i \in 1 .. 4 |-> 0],
      volume                |-> [i \in 1 .. 4 |-> 0],
      price                 |-> [i \in 1 .. 4 |-> 0],
      triggerPrice          |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags          |-> [i \in 1 .. 2 |-> 0],
      traderId              |-> [i \in 1 .. 4 |-> 0],
      nnfField              |-> [i \in 1 .. 8 |-> 0],
      algoId                |-> [i \in 1 .. 4 |-> 0],
      activityTimeInNanos   |-> [i \in 1 .. 8 |-> 0],
      reserved2             |-> [i \in 1 .. 2 |-> 0],
      secondReserved2       |-> [i \in 1 .. 2 |-> 0],
      thirdReserved2        |-> [i \in 1 .. 2 |-> 0],
      suspended             |-> [i \in 1 .. 1 |-> 0],
      openClose             |-> [i \in 1 .. 1 |-> 0],
      pan                   |-> [i \in 1 .. 10 |-> 0],
      segmentChar1          |-> [i \in 1 .. 1 |-> 0],
      participantType       |-> [i \in 1 .. 1 |-> 0],
      accountNumber         |-> [i \in 1 .. 10 |-> 0],
      proClientChar1        |-> [i \in 1 .. 1 |-> 0],
      reserved1             |-> [i \in 1 .. 1 |-> 0],
      settlor               |-> [i \in 1 .. 12 |-> 0],
      referenceId           |-> [i \in 1 .. 4 |-> 0] ]

(* Order Cancel Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelRejectMessage ==
    { ZeroOrderCancelRejectMessage }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.token = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.bookType = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.buySell = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.disclosedVolume = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.disclosedVolRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.totalVolRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.triggerPrice = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.traderId = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.activityTimeInNanos = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.secondReserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.thirdReserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.suspended = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.segmentChar1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.participantType = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.accountNumber = one] : one \in Sample(10) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.proClientChar1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.settlor = one] : one \in Sample(12) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.referenceId = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Confirmation Message: 116 bytes                                   *)
(***************************************************************************)

OrderConfirmationMessage ==
    [ reasonCode            : Sample(2),
      token                 : Sample(4),
      orderNumber           : Sample(8),
      bookType              : Sample(2),
      buySell               : Sample(2),
      disclosedVolume       : Sample(4),
      disclosedVolRemaining : Sample(4),
      totalVolRemaining     : Sample(4),
      volume                : Sample(4),
      price                 : Sample(4),
      triggerPrice          : Sample(4),
      stOrderFlags          : Sample(2),
      traderId              : Sample(4),
      nnfField              : Sample(8),
      algoId                : Sample(4),
      activityTimeInNanos   : Sample(8),
      reserved2             : Sample(2),
      secondReserved2       : Sample(2),
      thirdReserved2        : Sample(2),
      suspended             : Sample(1),
      openClose             : Sample(1),
      pan                   : Sample(10),
      segmentChar1          : Sample(1),
      participantType       : Sample(1),
      accountNumber         : Sample(10),
      proClientChar1        : Sample(1),
      reserved1             : Sample(1),
      settlor               : Sample(12),
      referenceId           : Sample(4) ]

EncodeOrderConfirmationMessage(message) ==
    message.reasonCode
        \o message.token
        \o message.orderNumber
        \o message.bookType
        \o message.buySell
        \o message.disclosedVolume
        \o message.disclosedVolRemaining
        \o message.totalVolRemaining
        \o message.volume
        \o message.price
        \o message.triggerPrice
        \o message.stOrderFlags
        \o message.traderId
        \o message.nnfField
        \o message.algoId
        \o message.activityTimeInNanos
        \o message.reserved2
        \o message.secondReserved2
        \o message.thirdReserved2
        \o message.suspended
        \o message.openClose
        \o message.pan
        \o message.segmentChar1
        \o message.participantType
        \o message.accountNumber
        \o message.proClientChar1
        \o message.reserved1
        \o message.settlor
        \o message.referenceId

DecodeOrderConfirmationMessage(bytes) ==
    LET reasonCode == ReadBytes(bytes, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET token == ReadBytes(reasonCode.rest, 4) IN IF ~token.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(token.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET bookType == ReadBytes(orderNumber.rest, 2) IN IF ~bookType.ok THEN Fail ELSE
    LET buySell == ReadBytes(bookType.rest, 2) IN IF ~buySell.ok THEN Fail ELSE
    LET disclosedVolume == ReadBytes(buySell.rest, 4) IN IF ~disclosedVolume.ok THEN Fail ELSE
    LET disclosedVolRemaining == ReadBytes(disclosedVolume.rest, 4) IN IF ~disclosedVolRemaining.ok THEN Fail ELSE
    LET totalVolRemaining == ReadBytes(disclosedVolRemaining.rest, 4) IN IF ~totalVolRemaining.ok THEN Fail ELSE
    LET volume == ReadBytes(totalVolRemaining.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET price == ReadBytes(volume.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET triggerPrice == ReadBytes(price.rest, 4) IN IF ~triggerPrice.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(triggerPrice.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET traderId == ReadBytes(stOrderFlags.rest, 4) IN IF ~traderId.ok THEN Fail ELSE
    LET nnfField == ReadBytes(traderId.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET algoId == ReadBytes(nnfField.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET activityTimeInNanos == ReadBytes(algoId.rest, 8) IN IF ~activityTimeInNanos.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(activityTimeInNanos.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET secondReserved2 == ReadBytes(reserved2.rest, 2) IN IF ~secondReserved2.ok THEN Fail ELSE
    LET thirdReserved2 == ReadBytes(secondReserved2.rest, 2) IN IF ~thirdReserved2.ok THEN Fail ELSE
    LET suspended == ReadBytes(thirdReserved2.rest, 1) IN IF ~suspended.ok THEN Fail ELSE
    LET openClose == ReadBytes(suspended.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET pan == ReadBytes(openClose.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET segmentChar1 == ReadBytes(pan.rest, 1) IN IF ~segmentChar1.ok THEN Fail ELSE
    LET participantType == ReadBytes(segmentChar1.rest, 1) IN IF ~participantType.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(participantType.rest, 10) IN IF ~accountNumber.ok THEN Fail ELSE
    LET proClientChar1 == ReadBytes(accountNumber.rest, 1) IN IF ~proClientChar1.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(proClientChar1.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET settlor == ReadBytes(reserved1.rest, 12) IN IF ~settlor.ok THEN Fail ELSE
    LET referenceId == ReadBytes(settlor.rest, 4) IN IF ~referenceId.ok THEN Fail ELSE
    Ok([ reasonCode            |-> reasonCode.value,
         token                 |-> token.value,
         orderNumber           |-> orderNumber.value,
         bookType              |-> bookType.value,
         buySell               |-> buySell.value,
         disclosedVolume       |-> disclosedVolume.value,
         disclosedVolRemaining |-> disclosedVolRemaining.value,
         totalVolRemaining     |-> totalVolRemaining.value,
         volume                |-> volume.value,
         price                 |-> price.value,
         triggerPrice          |-> triggerPrice.value,
         stOrderFlags          |-> stOrderFlags.value,
         traderId              |-> traderId.value,
         nnfField              |-> nnfField.value,
         algoId                |-> algoId.value,
         activityTimeInNanos   |-> activityTimeInNanos.value,
         reserved2             |-> reserved2.value,
         secondReserved2       |-> secondReserved2.value,
         thirdReserved2        |-> thirdReserved2.value,
         suspended             |-> suspended.value,
         openClose             |-> openClose.value,
         pan                   |-> pan.value,
         segmentChar1          |-> segmentChar1.value,
         participantType       |-> participantType.value,
         accountNumber         |-> accountNumber.value,
         proClientChar1        |-> proClientChar1.value,
         reserved1             |-> reserved1.value,
         settlor               |-> settlor.value,
         referenceId           |-> referenceId.value ], referenceId.rest)

ZeroOrderConfirmationMessage ==
    [ reasonCode            |-> [i \in 1 .. 2 |-> 0],
      token                 |-> [i \in 1 .. 4 |-> 0],
      orderNumber           |-> [i \in 1 .. 8 |-> 0],
      bookType              |-> [i \in 1 .. 2 |-> 0],
      buySell               |-> [i \in 1 .. 2 |-> 0],
      disclosedVolume       |-> [i \in 1 .. 4 |-> 0],
      disclosedVolRemaining |-> [i \in 1 .. 4 |-> 0],
      totalVolRemaining     |-> [i \in 1 .. 4 |-> 0],
      volume                |-> [i \in 1 .. 4 |-> 0],
      price                 |-> [i \in 1 .. 4 |-> 0],
      triggerPrice          |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags          |-> [i \in 1 .. 2 |-> 0],
      traderId              |-> [i \in 1 .. 4 |-> 0],
      nnfField              |-> [i \in 1 .. 8 |-> 0],
      algoId                |-> [i \in 1 .. 4 |-> 0],
      activityTimeInNanos   |-> [i \in 1 .. 8 |-> 0],
      reserved2             |-> [i \in 1 .. 2 |-> 0],
      secondReserved2       |-> [i \in 1 .. 2 |-> 0],
      thirdReserved2        |-> [i \in 1 .. 2 |-> 0],
      suspended             |-> [i \in 1 .. 1 |-> 0],
      openClose             |-> [i \in 1 .. 1 |-> 0],
      pan                   |-> [i \in 1 .. 10 |-> 0],
      segmentChar1          |-> [i \in 1 .. 1 |-> 0],
      participantType       |-> [i \in 1 .. 1 |-> 0],
      accountNumber         |-> [i \in 1 .. 10 |-> 0],
      proClientChar1        |-> [i \in 1 .. 1 |-> 0],
      reserved1             |-> [i \in 1 .. 1 |-> 0],
      settlor               |-> [i \in 1 .. 12 |-> 0],
      referenceId           |-> [i \in 1 .. 4 |-> 0] ]

(* Order Confirmation Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderConfirmationMessage ==
    { ZeroOrderConfirmationMessage }
        \cup { [ZeroOrderConfirmationMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroOrderConfirmationMessage EXCEPT !.token = one] : one \in Sample(4) }
        \cup { [ZeroOrderConfirmationMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderConfirmationMessage EXCEPT !.bookType = one] : one \in Sample(2) }
        \cup { [ZeroOrderConfirmationMessage EXCEPT !.buySell = one] : one \in Sample(2) }
        \cup { [ZeroOrderConfirmationMessage EXCEPT !.disclosedVolume = one] : one \in Sample(4) }
        \cup { [ZeroOrderConfirmationMessage EXCEPT !.disclosedVolRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderConfirmationMessage EXCEPT !.totalVolRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderConfirmationMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroOrderConfirmationMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderConfirmationMessage EXCEPT !.triggerPrice = one] : one \in Sample(4) }
        \cup { [ZeroOrderConfirmationMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroOrderConfirmationMessage EXCEPT !.traderId = one] : one \in Sample(4) }
        \cup { [ZeroOrderConfirmationMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroOrderConfirmationMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroOrderConfirmationMessage EXCEPT !.activityTimeInNanos = one] : one \in Sample(8) }
        \cup { [ZeroOrderConfirmationMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderConfirmationMessage EXCEPT !.secondReserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderConfirmationMessage EXCEPT !.thirdReserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderConfirmationMessage EXCEPT !.suspended = one] : one \in Sample(1) }
        \cup { [ZeroOrderConfirmationMessage EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroOrderConfirmationMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroOrderConfirmationMessage EXCEPT !.segmentChar1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderConfirmationMessage EXCEPT !.participantType = one] : one \in Sample(1) }
        \cup { [ZeroOrderConfirmationMessage EXCEPT !.accountNumber = one] : one \in Sample(10) }
        \cup { [ZeroOrderConfirmationMessage EXCEPT !.proClientChar1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderConfirmationMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderConfirmationMessage EXCEPT !.settlor = one] : one \in Sample(12) }
        \cup { [ZeroOrderConfirmationMessage EXCEPT !.referenceId = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Mod Confirmation Message: 116 bytes                               *)
(***************************************************************************)

OrderModConfirmationMessage ==
    [ reasonCode            : Sample(2),
      token                 : Sample(4),
      orderNumber           : Sample(8),
      bookType              : Sample(2),
      buySell               : Sample(2),
      disclosedVolume       : Sample(4),
      disclosedVolRemaining : Sample(4),
      totalVolRemaining     : Sample(4),
      volume                : Sample(4),
      price                 : Sample(4),
      triggerPrice          : Sample(4),
      stOrderFlags          : Sample(2),
      traderId              : Sample(4),
      nnfField              : Sample(8),
      algoId                : Sample(4),
      activityTimeInNanos   : Sample(8),
      reserved2             : Sample(2),
      secondReserved2       : Sample(2),
      thirdReserved2        : Sample(2),
      suspended             : Sample(1),
      openClose             : Sample(1),
      pan                   : Sample(10),
      segmentChar1          : Sample(1),
      participantType       : Sample(1),
      accountNumber         : Sample(10),
      proClientChar1        : Sample(1),
      reserved1             : Sample(1),
      settlor               : Sample(12),
      referenceId           : Sample(4) ]

EncodeOrderModConfirmationMessage(message) ==
    message.reasonCode
        \o message.token
        \o message.orderNumber
        \o message.bookType
        \o message.buySell
        \o message.disclosedVolume
        \o message.disclosedVolRemaining
        \o message.totalVolRemaining
        \o message.volume
        \o message.price
        \o message.triggerPrice
        \o message.stOrderFlags
        \o message.traderId
        \o message.nnfField
        \o message.algoId
        \o message.activityTimeInNanos
        \o message.reserved2
        \o message.secondReserved2
        \o message.thirdReserved2
        \o message.suspended
        \o message.openClose
        \o message.pan
        \o message.segmentChar1
        \o message.participantType
        \o message.accountNumber
        \o message.proClientChar1
        \o message.reserved1
        \o message.settlor
        \o message.referenceId

DecodeOrderModConfirmationMessage(bytes) ==
    LET reasonCode == ReadBytes(bytes, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET token == ReadBytes(reasonCode.rest, 4) IN IF ~token.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(token.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET bookType == ReadBytes(orderNumber.rest, 2) IN IF ~bookType.ok THEN Fail ELSE
    LET buySell == ReadBytes(bookType.rest, 2) IN IF ~buySell.ok THEN Fail ELSE
    LET disclosedVolume == ReadBytes(buySell.rest, 4) IN IF ~disclosedVolume.ok THEN Fail ELSE
    LET disclosedVolRemaining == ReadBytes(disclosedVolume.rest, 4) IN IF ~disclosedVolRemaining.ok THEN Fail ELSE
    LET totalVolRemaining == ReadBytes(disclosedVolRemaining.rest, 4) IN IF ~totalVolRemaining.ok THEN Fail ELSE
    LET volume == ReadBytes(totalVolRemaining.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET price == ReadBytes(volume.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET triggerPrice == ReadBytes(price.rest, 4) IN IF ~triggerPrice.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(triggerPrice.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET traderId == ReadBytes(stOrderFlags.rest, 4) IN IF ~traderId.ok THEN Fail ELSE
    LET nnfField == ReadBytes(traderId.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET algoId == ReadBytes(nnfField.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET activityTimeInNanos == ReadBytes(algoId.rest, 8) IN IF ~activityTimeInNanos.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(activityTimeInNanos.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET secondReserved2 == ReadBytes(reserved2.rest, 2) IN IF ~secondReserved2.ok THEN Fail ELSE
    LET thirdReserved2 == ReadBytes(secondReserved2.rest, 2) IN IF ~thirdReserved2.ok THEN Fail ELSE
    LET suspended == ReadBytes(thirdReserved2.rest, 1) IN IF ~suspended.ok THEN Fail ELSE
    LET openClose == ReadBytes(suspended.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET pan == ReadBytes(openClose.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET segmentChar1 == ReadBytes(pan.rest, 1) IN IF ~segmentChar1.ok THEN Fail ELSE
    LET participantType == ReadBytes(segmentChar1.rest, 1) IN IF ~participantType.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(participantType.rest, 10) IN IF ~accountNumber.ok THEN Fail ELSE
    LET proClientChar1 == ReadBytes(accountNumber.rest, 1) IN IF ~proClientChar1.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(proClientChar1.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET settlor == ReadBytes(reserved1.rest, 12) IN IF ~settlor.ok THEN Fail ELSE
    LET referenceId == ReadBytes(settlor.rest, 4) IN IF ~referenceId.ok THEN Fail ELSE
    Ok([ reasonCode            |-> reasonCode.value,
         token                 |-> token.value,
         orderNumber           |-> orderNumber.value,
         bookType              |-> bookType.value,
         buySell               |-> buySell.value,
         disclosedVolume       |-> disclosedVolume.value,
         disclosedVolRemaining |-> disclosedVolRemaining.value,
         totalVolRemaining     |-> totalVolRemaining.value,
         volume                |-> volume.value,
         price                 |-> price.value,
         triggerPrice          |-> triggerPrice.value,
         stOrderFlags          |-> stOrderFlags.value,
         traderId              |-> traderId.value,
         nnfField              |-> nnfField.value,
         algoId                |-> algoId.value,
         activityTimeInNanos   |-> activityTimeInNanos.value,
         reserved2             |-> reserved2.value,
         secondReserved2       |-> secondReserved2.value,
         thirdReserved2        |-> thirdReserved2.value,
         suspended             |-> suspended.value,
         openClose             |-> openClose.value,
         pan                   |-> pan.value,
         segmentChar1          |-> segmentChar1.value,
         participantType       |-> participantType.value,
         accountNumber         |-> accountNumber.value,
         proClientChar1        |-> proClientChar1.value,
         reserved1             |-> reserved1.value,
         settlor               |-> settlor.value,
         referenceId           |-> referenceId.value ], referenceId.rest)

ZeroOrderModConfirmationMessage ==
    [ reasonCode            |-> [i \in 1 .. 2 |-> 0],
      token                 |-> [i \in 1 .. 4 |-> 0],
      orderNumber           |-> [i \in 1 .. 8 |-> 0],
      bookType              |-> [i \in 1 .. 2 |-> 0],
      buySell               |-> [i \in 1 .. 2 |-> 0],
      disclosedVolume       |-> [i \in 1 .. 4 |-> 0],
      disclosedVolRemaining |-> [i \in 1 .. 4 |-> 0],
      totalVolRemaining     |-> [i \in 1 .. 4 |-> 0],
      volume                |-> [i \in 1 .. 4 |-> 0],
      price                 |-> [i \in 1 .. 4 |-> 0],
      triggerPrice          |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags          |-> [i \in 1 .. 2 |-> 0],
      traderId              |-> [i \in 1 .. 4 |-> 0],
      nnfField              |-> [i \in 1 .. 8 |-> 0],
      algoId                |-> [i \in 1 .. 4 |-> 0],
      activityTimeInNanos   |-> [i \in 1 .. 8 |-> 0],
      reserved2             |-> [i \in 1 .. 2 |-> 0],
      secondReserved2       |-> [i \in 1 .. 2 |-> 0],
      thirdReserved2        |-> [i \in 1 .. 2 |-> 0],
      suspended             |-> [i \in 1 .. 1 |-> 0],
      openClose             |-> [i \in 1 .. 1 |-> 0],
      pan                   |-> [i \in 1 .. 10 |-> 0],
      segmentChar1          |-> [i \in 1 .. 1 |-> 0],
      participantType       |-> [i \in 1 .. 1 |-> 0],
      accountNumber         |-> [i \in 1 .. 10 |-> 0],
      proClientChar1        |-> [i \in 1 .. 1 |-> 0],
      reserved1             |-> [i \in 1 .. 1 |-> 0],
      settlor               |-> [i \in 1 .. 12 |-> 0],
      referenceId           |-> [i \in 1 .. 4 |-> 0] ]

(* Order Mod Confirmation Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderModConfirmationMessage ==
    { ZeroOrderModConfirmationMessage }
        \cup { [ZeroOrderModConfirmationMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroOrderModConfirmationMessage EXCEPT !.token = one] : one \in Sample(4) }
        \cup { [ZeroOrderModConfirmationMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderModConfirmationMessage EXCEPT !.bookType = one] : one \in Sample(2) }
        \cup { [ZeroOrderModConfirmationMessage EXCEPT !.buySell = one] : one \in Sample(2) }
        \cup { [ZeroOrderModConfirmationMessage EXCEPT !.disclosedVolume = one] : one \in Sample(4) }
        \cup { [ZeroOrderModConfirmationMessage EXCEPT !.disclosedVolRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderModConfirmationMessage EXCEPT !.totalVolRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderModConfirmationMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroOrderModConfirmationMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderModConfirmationMessage EXCEPT !.triggerPrice = one] : one \in Sample(4) }
        \cup { [ZeroOrderModConfirmationMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroOrderModConfirmationMessage EXCEPT !.traderId = one] : one \in Sample(4) }
        \cup { [ZeroOrderModConfirmationMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroOrderModConfirmationMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroOrderModConfirmationMessage EXCEPT !.activityTimeInNanos = one] : one \in Sample(8) }
        \cup { [ZeroOrderModConfirmationMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderModConfirmationMessage EXCEPT !.secondReserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderModConfirmationMessage EXCEPT !.thirdReserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderModConfirmationMessage EXCEPT !.suspended = one] : one \in Sample(1) }
        \cup { [ZeroOrderModConfirmationMessage EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroOrderModConfirmationMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroOrderModConfirmationMessage EXCEPT !.segmentChar1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderModConfirmationMessage EXCEPT !.participantType = one] : one \in Sample(1) }
        \cup { [ZeroOrderModConfirmationMessage EXCEPT !.accountNumber = one] : one \in Sample(10) }
        \cup { [ZeroOrderModConfirmationMessage EXCEPT !.proClientChar1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderModConfirmationMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderModConfirmationMessage EXCEPT !.settlor = one] : one \in Sample(12) }
        \cup { [ZeroOrderModConfirmationMessage EXCEPT !.referenceId = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Cancel Confirmation Message: 116 bytes                            *)
(***************************************************************************)

OrderCancelConfirmationMessage ==
    [ reasonCode            : Sample(2),
      token                 : Sample(4),
      orderNumber           : Sample(8),
      bookType              : Sample(2),
      buySell               : Sample(2),
      disclosedVolume       : Sample(4),
      disclosedVolRemaining : Sample(4),
      totalVolRemaining     : Sample(4),
      volume                : Sample(4),
      price                 : Sample(4),
      triggerPrice          : Sample(4),
      stOrderFlags          : Sample(2),
      traderId              : Sample(4),
      nnfField              : Sample(8),
      algoId                : Sample(4),
      activityTimeInNanos   : Sample(8),
      reserved2             : Sample(2),
      secondReserved2       : Sample(2),
      thirdReserved2        : Sample(2),
      suspended             : Sample(1),
      openClose             : Sample(1),
      pan                   : Sample(10),
      segmentChar1          : Sample(1),
      participantType       : Sample(1),
      accountNumber         : Sample(10),
      proClientChar1        : Sample(1),
      reserved1             : Sample(1),
      settlor               : Sample(12),
      referenceId           : Sample(4) ]

EncodeOrderCancelConfirmationMessage(message) ==
    message.reasonCode
        \o message.token
        \o message.orderNumber
        \o message.bookType
        \o message.buySell
        \o message.disclosedVolume
        \o message.disclosedVolRemaining
        \o message.totalVolRemaining
        \o message.volume
        \o message.price
        \o message.triggerPrice
        \o message.stOrderFlags
        \o message.traderId
        \o message.nnfField
        \o message.algoId
        \o message.activityTimeInNanos
        \o message.reserved2
        \o message.secondReserved2
        \o message.thirdReserved2
        \o message.suspended
        \o message.openClose
        \o message.pan
        \o message.segmentChar1
        \o message.participantType
        \o message.accountNumber
        \o message.proClientChar1
        \o message.reserved1
        \o message.settlor
        \o message.referenceId

DecodeOrderCancelConfirmationMessage(bytes) ==
    LET reasonCode == ReadBytes(bytes, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET token == ReadBytes(reasonCode.rest, 4) IN IF ~token.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(token.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET bookType == ReadBytes(orderNumber.rest, 2) IN IF ~bookType.ok THEN Fail ELSE
    LET buySell == ReadBytes(bookType.rest, 2) IN IF ~buySell.ok THEN Fail ELSE
    LET disclosedVolume == ReadBytes(buySell.rest, 4) IN IF ~disclosedVolume.ok THEN Fail ELSE
    LET disclosedVolRemaining == ReadBytes(disclosedVolume.rest, 4) IN IF ~disclosedVolRemaining.ok THEN Fail ELSE
    LET totalVolRemaining == ReadBytes(disclosedVolRemaining.rest, 4) IN IF ~totalVolRemaining.ok THEN Fail ELSE
    LET volume == ReadBytes(totalVolRemaining.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET price == ReadBytes(volume.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET triggerPrice == ReadBytes(price.rest, 4) IN IF ~triggerPrice.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(triggerPrice.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET traderId == ReadBytes(stOrderFlags.rest, 4) IN IF ~traderId.ok THEN Fail ELSE
    LET nnfField == ReadBytes(traderId.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET algoId == ReadBytes(nnfField.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET activityTimeInNanos == ReadBytes(algoId.rest, 8) IN IF ~activityTimeInNanos.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(activityTimeInNanos.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET secondReserved2 == ReadBytes(reserved2.rest, 2) IN IF ~secondReserved2.ok THEN Fail ELSE
    LET thirdReserved2 == ReadBytes(secondReserved2.rest, 2) IN IF ~thirdReserved2.ok THEN Fail ELSE
    LET suspended == ReadBytes(thirdReserved2.rest, 1) IN IF ~suspended.ok THEN Fail ELSE
    LET openClose == ReadBytes(suspended.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET pan == ReadBytes(openClose.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET segmentChar1 == ReadBytes(pan.rest, 1) IN IF ~segmentChar1.ok THEN Fail ELSE
    LET participantType == ReadBytes(segmentChar1.rest, 1) IN IF ~participantType.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(participantType.rest, 10) IN IF ~accountNumber.ok THEN Fail ELSE
    LET proClientChar1 == ReadBytes(accountNumber.rest, 1) IN IF ~proClientChar1.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(proClientChar1.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET settlor == ReadBytes(reserved1.rest, 12) IN IF ~settlor.ok THEN Fail ELSE
    LET referenceId == ReadBytes(settlor.rest, 4) IN IF ~referenceId.ok THEN Fail ELSE
    Ok([ reasonCode            |-> reasonCode.value,
         token                 |-> token.value,
         orderNumber           |-> orderNumber.value,
         bookType              |-> bookType.value,
         buySell               |-> buySell.value,
         disclosedVolume       |-> disclosedVolume.value,
         disclosedVolRemaining |-> disclosedVolRemaining.value,
         totalVolRemaining     |-> totalVolRemaining.value,
         volume                |-> volume.value,
         price                 |-> price.value,
         triggerPrice          |-> triggerPrice.value,
         stOrderFlags          |-> stOrderFlags.value,
         traderId              |-> traderId.value,
         nnfField              |-> nnfField.value,
         algoId                |-> algoId.value,
         activityTimeInNanos   |-> activityTimeInNanos.value,
         reserved2             |-> reserved2.value,
         secondReserved2       |-> secondReserved2.value,
         thirdReserved2        |-> thirdReserved2.value,
         suspended             |-> suspended.value,
         openClose             |-> openClose.value,
         pan                   |-> pan.value,
         segmentChar1          |-> segmentChar1.value,
         participantType       |-> participantType.value,
         accountNumber         |-> accountNumber.value,
         proClientChar1        |-> proClientChar1.value,
         reserved1             |-> reserved1.value,
         settlor               |-> settlor.value,
         referenceId           |-> referenceId.value ], referenceId.rest)

ZeroOrderCancelConfirmationMessage ==
    [ reasonCode            |-> [i \in 1 .. 2 |-> 0],
      token                 |-> [i \in 1 .. 4 |-> 0],
      orderNumber           |-> [i \in 1 .. 8 |-> 0],
      bookType              |-> [i \in 1 .. 2 |-> 0],
      buySell               |-> [i \in 1 .. 2 |-> 0],
      disclosedVolume       |-> [i \in 1 .. 4 |-> 0],
      disclosedVolRemaining |-> [i \in 1 .. 4 |-> 0],
      totalVolRemaining     |-> [i \in 1 .. 4 |-> 0],
      volume                |-> [i \in 1 .. 4 |-> 0],
      price                 |-> [i \in 1 .. 4 |-> 0],
      triggerPrice          |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags          |-> [i \in 1 .. 2 |-> 0],
      traderId              |-> [i \in 1 .. 4 |-> 0],
      nnfField              |-> [i \in 1 .. 8 |-> 0],
      algoId                |-> [i \in 1 .. 4 |-> 0],
      activityTimeInNanos   |-> [i \in 1 .. 8 |-> 0],
      reserved2             |-> [i \in 1 .. 2 |-> 0],
      secondReserved2       |-> [i \in 1 .. 2 |-> 0],
      thirdReserved2        |-> [i \in 1 .. 2 |-> 0],
      suspended             |-> [i \in 1 .. 1 |-> 0],
      openClose             |-> [i \in 1 .. 1 |-> 0],
      pan                   |-> [i \in 1 .. 10 |-> 0],
      segmentChar1          |-> [i \in 1 .. 1 |-> 0],
      participantType       |-> [i \in 1 .. 1 |-> 0],
      accountNumber         |-> [i \in 1 .. 10 |-> 0],
      proClientChar1        |-> [i \in 1 .. 1 |-> 0],
      reserved1             |-> [i \in 1 .. 1 |-> 0],
      settlor               |-> [i \in 1 .. 12 |-> 0],
      referenceId           |-> [i \in 1 .. 4 |-> 0] ]

(* Order Cancel Confirmation Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelConfirmationMessage ==
    { ZeroOrderCancelConfirmationMessage }
        \cup { [ZeroOrderCancelConfirmationMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelConfirmationMessage EXCEPT !.token = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelConfirmationMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelConfirmationMessage EXCEPT !.bookType = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelConfirmationMessage EXCEPT !.buySell = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelConfirmationMessage EXCEPT !.disclosedVolume = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelConfirmationMessage EXCEPT !.disclosedVolRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelConfirmationMessage EXCEPT !.totalVolRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelConfirmationMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelConfirmationMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelConfirmationMessage EXCEPT !.triggerPrice = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelConfirmationMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelConfirmationMessage EXCEPT !.traderId = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelConfirmationMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelConfirmationMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelConfirmationMessage EXCEPT !.activityTimeInNanos = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelConfirmationMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelConfirmationMessage EXCEPT !.secondReserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelConfirmationMessage EXCEPT !.thirdReserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelConfirmationMessage EXCEPT !.suspended = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelConfirmationMessage EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelConfirmationMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroOrderCancelConfirmationMessage EXCEPT !.segmentChar1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelConfirmationMessage EXCEPT !.participantType = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelConfirmationMessage EXCEPT !.accountNumber = one] : one \in Sample(10) }
        \cup { [ZeroOrderCancelConfirmationMessage EXCEPT !.proClientChar1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelConfirmationMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelConfirmationMessage EXCEPT !.settlor = one] : one \in Sample(12) }
        \cup { [ZeroOrderCancelConfirmationMessage EXCEPT !.referenceId = one] : one \in Sample(4) }

(***************************************************************************)
(* Freeze To Control Message: 116 bytes                                    *)
(***************************************************************************)

FreezeToControlMessage ==
    [ reasonCode            : Sample(2),
      token                 : Sample(4),
      orderNumber           : Sample(8),
      bookType              : Sample(2),
      buySell               : Sample(2),
      disclosedVolume       : Sample(4),
      disclosedVolRemaining : Sample(4),
      totalVolRemaining     : Sample(4),
      volume                : Sample(4),
      price                 : Sample(4),
      triggerPrice          : Sample(4),
      stOrderFlags          : Sample(2),
      traderId              : Sample(4),
      nnfField              : Sample(8),
      algoId                : Sample(4),
      activityTimeInNanos   : Sample(8),
      reserved2             : Sample(2),
      secondReserved2       : Sample(2),
      thirdReserved2        : Sample(2),
      suspended             : Sample(1),
      openClose             : Sample(1),
      pan                   : Sample(10),
      segmentChar1          : Sample(1),
      participantType       : Sample(1),
      accountNumber         : Sample(10),
      proClientChar1        : Sample(1),
      reserved1             : Sample(1),
      settlor               : Sample(12),
      referenceId           : Sample(4) ]

EncodeFreezeToControlMessage(message) ==
    message.reasonCode
        \o message.token
        \o message.orderNumber
        \o message.bookType
        \o message.buySell
        \o message.disclosedVolume
        \o message.disclosedVolRemaining
        \o message.totalVolRemaining
        \o message.volume
        \o message.price
        \o message.triggerPrice
        \o message.stOrderFlags
        \o message.traderId
        \o message.nnfField
        \o message.algoId
        \o message.activityTimeInNanos
        \o message.reserved2
        \o message.secondReserved2
        \o message.thirdReserved2
        \o message.suspended
        \o message.openClose
        \o message.pan
        \o message.segmentChar1
        \o message.participantType
        \o message.accountNumber
        \o message.proClientChar1
        \o message.reserved1
        \o message.settlor
        \o message.referenceId

DecodeFreezeToControlMessage(bytes) ==
    LET reasonCode == ReadBytes(bytes, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET token == ReadBytes(reasonCode.rest, 4) IN IF ~token.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(token.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET bookType == ReadBytes(orderNumber.rest, 2) IN IF ~bookType.ok THEN Fail ELSE
    LET buySell == ReadBytes(bookType.rest, 2) IN IF ~buySell.ok THEN Fail ELSE
    LET disclosedVolume == ReadBytes(buySell.rest, 4) IN IF ~disclosedVolume.ok THEN Fail ELSE
    LET disclosedVolRemaining == ReadBytes(disclosedVolume.rest, 4) IN IF ~disclosedVolRemaining.ok THEN Fail ELSE
    LET totalVolRemaining == ReadBytes(disclosedVolRemaining.rest, 4) IN IF ~totalVolRemaining.ok THEN Fail ELSE
    LET volume == ReadBytes(totalVolRemaining.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET price == ReadBytes(volume.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET triggerPrice == ReadBytes(price.rest, 4) IN IF ~triggerPrice.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(triggerPrice.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET traderId == ReadBytes(stOrderFlags.rest, 4) IN IF ~traderId.ok THEN Fail ELSE
    LET nnfField == ReadBytes(traderId.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET algoId == ReadBytes(nnfField.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET activityTimeInNanos == ReadBytes(algoId.rest, 8) IN IF ~activityTimeInNanos.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(activityTimeInNanos.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET secondReserved2 == ReadBytes(reserved2.rest, 2) IN IF ~secondReserved2.ok THEN Fail ELSE
    LET thirdReserved2 == ReadBytes(secondReserved2.rest, 2) IN IF ~thirdReserved2.ok THEN Fail ELSE
    LET suspended == ReadBytes(thirdReserved2.rest, 1) IN IF ~suspended.ok THEN Fail ELSE
    LET openClose == ReadBytes(suspended.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET pan == ReadBytes(openClose.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET segmentChar1 == ReadBytes(pan.rest, 1) IN IF ~segmentChar1.ok THEN Fail ELSE
    LET participantType == ReadBytes(segmentChar1.rest, 1) IN IF ~participantType.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(participantType.rest, 10) IN IF ~accountNumber.ok THEN Fail ELSE
    LET proClientChar1 == ReadBytes(accountNumber.rest, 1) IN IF ~proClientChar1.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(proClientChar1.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET settlor == ReadBytes(reserved1.rest, 12) IN IF ~settlor.ok THEN Fail ELSE
    LET referenceId == ReadBytes(settlor.rest, 4) IN IF ~referenceId.ok THEN Fail ELSE
    Ok([ reasonCode            |-> reasonCode.value,
         token                 |-> token.value,
         orderNumber           |-> orderNumber.value,
         bookType              |-> bookType.value,
         buySell               |-> buySell.value,
         disclosedVolume       |-> disclosedVolume.value,
         disclosedVolRemaining |-> disclosedVolRemaining.value,
         totalVolRemaining     |-> totalVolRemaining.value,
         volume                |-> volume.value,
         price                 |-> price.value,
         triggerPrice          |-> triggerPrice.value,
         stOrderFlags          |-> stOrderFlags.value,
         traderId              |-> traderId.value,
         nnfField              |-> nnfField.value,
         algoId                |-> algoId.value,
         activityTimeInNanos   |-> activityTimeInNanos.value,
         reserved2             |-> reserved2.value,
         secondReserved2       |-> secondReserved2.value,
         thirdReserved2        |-> thirdReserved2.value,
         suspended             |-> suspended.value,
         openClose             |-> openClose.value,
         pan                   |-> pan.value,
         segmentChar1          |-> segmentChar1.value,
         participantType       |-> participantType.value,
         accountNumber         |-> accountNumber.value,
         proClientChar1        |-> proClientChar1.value,
         reserved1             |-> reserved1.value,
         settlor               |-> settlor.value,
         referenceId           |-> referenceId.value ], referenceId.rest)

ZeroFreezeToControlMessage ==
    [ reasonCode            |-> [i \in 1 .. 2 |-> 0],
      token                 |-> [i \in 1 .. 4 |-> 0],
      orderNumber           |-> [i \in 1 .. 8 |-> 0],
      bookType              |-> [i \in 1 .. 2 |-> 0],
      buySell               |-> [i \in 1 .. 2 |-> 0],
      disclosedVolume       |-> [i \in 1 .. 4 |-> 0],
      disclosedVolRemaining |-> [i \in 1 .. 4 |-> 0],
      totalVolRemaining     |-> [i \in 1 .. 4 |-> 0],
      volume                |-> [i \in 1 .. 4 |-> 0],
      price                 |-> [i \in 1 .. 4 |-> 0],
      triggerPrice          |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags          |-> [i \in 1 .. 2 |-> 0],
      traderId              |-> [i \in 1 .. 4 |-> 0],
      nnfField              |-> [i \in 1 .. 8 |-> 0],
      algoId                |-> [i \in 1 .. 4 |-> 0],
      activityTimeInNanos   |-> [i \in 1 .. 8 |-> 0],
      reserved2             |-> [i \in 1 .. 2 |-> 0],
      secondReserved2       |-> [i \in 1 .. 2 |-> 0],
      thirdReserved2        |-> [i \in 1 .. 2 |-> 0],
      suspended             |-> [i \in 1 .. 1 |-> 0],
      openClose             |-> [i \in 1 .. 1 |-> 0],
      pan                   |-> [i \in 1 .. 10 |-> 0],
      segmentChar1          |-> [i \in 1 .. 1 |-> 0],
      participantType       |-> [i \in 1 .. 1 |-> 0],
      accountNumber         |-> [i \in 1 .. 10 |-> 0],
      proClientChar1        |-> [i \in 1 .. 1 |-> 0],
      reserved1             |-> [i \in 1 .. 1 |-> 0],
      settlor               |-> [i \in 1 .. 12 |-> 0],
      referenceId           |-> [i \in 1 .. 4 |-> 0] ]

(* Freeze To Control Message at zero, then each field in turn at the values it is checked at *)
CheckedFreezeToControlMessage ==
    { ZeroFreezeToControlMessage }
        \cup { [ZeroFreezeToControlMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroFreezeToControlMessage EXCEPT !.token = one] : one \in Sample(4) }
        \cup { [ZeroFreezeToControlMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroFreezeToControlMessage EXCEPT !.bookType = one] : one \in Sample(2) }
        \cup { [ZeroFreezeToControlMessage EXCEPT !.buySell = one] : one \in Sample(2) }
        \cup { [ZeroFreezeToControlMessage EXCEPT !.disclosedVolume = one] : one \in Sample(4) }
        \cup { [ZeroFreezeToControlMessage EXCEPT !.disclosedVolRemaining = one] : one \in Sample(4) }
        \cup { [ZeroFreezeToControlMessage EXCEPT !.totalVolRemaining = one] : one \in Sample(4) }
        \cup { [ZeroFreezeToControlMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroFreezeToControlMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroFreezeToControlMessage EXCEPT !.triggerPrice = one] : one \in Sample(4) }
        \cup { [ZeroFreezeToControlMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroFreezeToControlMessage EXCEPT !.traderId = one] : one \in Sample(4) }
        \cup { [ZeroFreezeToControlMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroFreezeToControlMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroFreezeToControlMessage EXCEPT !.activityTimeInNanos = one] : one \in Sample(8) }
        \cup { [ZeroFreezeToControlMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroFreezeToControlMessage EXCEPT !.secondReserved2 = one] : one \in Sample(2) }
        \cup { [ZeroFreezeToControlMessage EXCEPT !.thirdReserved2 = one] : one \in Sample(2) }
        \cup { [ZeroFreezeToControlMessage EXCEPT !.suspended = one] : one \in Sample(1) }
        \cup { [ZeroFreezeToControlMessage EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroFreezeToControlMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroFreezeToControlMessage EXCEPT !.segmentChar1 = one] : one \in Sample(1) }
        \cup { [ZeroFreezeToControlMessage EXCEPT !.participantType = one] : one \in Sample(1) }
        \cup { [ZeroFreezeToControlMessage EXCEPT !.accountNumber = one] : one \in Sample(10) }
        \cup { [ZeroFreezeToControlMessage EXCEPT !.proClientChar1 = one] : one \in Sample(1) }
        \cup { [ZeroFreezeToControlMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroFreezeToControlMessage EXCEPT !.settlor = one] : one \in Sample(12) }
        \cup { [ZeroFreezeToControlMessage EXCEPT !.referenceId = one] : one \in Sample(4) }

(***************************************************************************)
(* On Stop Notification Message: 116 bytes                                 *)
(***************************************************************************)

OnStopNotificationMessage ==
    [ reasonCode            : Sample(2),
      token                 : Sample(4),
      orderNumber           : Sample(8),
      bookType              : Sample(2),
      buySell               : Sample(2),
      disclosedVolume       : Sample(4),
      disclosedVolRemaining : Sample(4),
      totalVolRemaining     : Sample(4),
      volume                : Sample(4),
      price                 : Sample(4),
      triggerPrice          : Sample(4),
      stOrderFlags          : Sample(2),
      traderId              : Sample(4),
      nnfField              : Sample(8),
      algoId                : Sample(4),
      activityTimeInNanos   : Sample(8),
      reserved2             : Sample(2),
      secondReserved2       : Sample(2),
      thirdReserved2        : Sample(2),
      suspended             : Sample(1),
      openClose             : Sample(1),
      pan                   : Sample(10),
      segmentChar1          : Sample(1),
      participantType       : Sample(1),
      accountNumber         : Sample(10),
      proClientChar1        : Sample(1),
      reserved1             : Sample(1),
      settlor               : Sample(12),
      referenceId           : Sample(4) ]

EncodeOnStopNotificationMessage(message) ==
    message.reasonCode
        \o message.token
        \o message.orderNumber
        \o message.bookType
        \o message.buySell
        \o message.disclosedVolume
        \o message.disclosedVolRemaining
        \o message.totalVolRemaining
        \o message.volume
        \o message.price
        \o message.triggerPrice
        \o message.stOrderFlags
        \o message.traderId
        \o message.nnfField
        \o message.algoId
        \o message.activityTimeInNanos
        \o message.reserved2
        \o message.secondReserved2
        \o message.thirdReserved2
        \o message.suspended
        \o message.openClose
        \o message.pan
        \o message.segmentChar1
        \o message.participantType
        \o message.accountNumber
        \o message.proClientChar1
        \o message.reserved1
        \o message.settlor
        \o message.referenceId

DecodeOnStopNotificationMessage(bytes) ==
    LET reasonCode == ReadBytes(bytes, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET token == ReadBytes(reasonCode.rest, 4) IN IF ~token.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(token.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET bookType == ReadBytes(orderNumber.rest, 2) IN IF ~bookType.ok THEN Fail ELSE
    LET buySell == ReadBytes(bookType.rest, 2) IN IF ~buySell.ok THEN Fail ELSE
    LET disclosedVolume == ReadBytes(buySell.rest, 4) IN IF ~disclosedVolume.ok THEN Fail ELSE
    LET disclosedVolRemaining == ReadBytes(disclosedVolume.rest, 4) IN IF ~disclosedVolRemaining.ok THEN Fail ELSE
    LET totalVolRemaining == ReadBytes(disclosedVolRemaining.rest, 4) IN IF ~totalVolRemaining.ok THEN Fail ELSE
    LET volume == ReadBytes(totalVolRemaining.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET price == ReadBytes(volume.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET triggerPrice == ReadBytes(price.rest, 4) IN IF ~triggerPrice.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(triggerPrice.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET traderId == ReadBytes(stOrderFlags.rest, 4) IN IF ~traderId.ok THEN Fail ELSE
    LET nnfField == ReadBytes(traderId.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET algoId == ReadBytes(nnfField.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET activityTimeInNanos == ReadBytes(algoId.rest, 8) IN IF ~activityTimeInNanos.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(activityTimeInNanos.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET secondReserved2 == ReadBytes(reserved2.rest, 2) IN IF ~secondReserved2.ok THEN Fail ELSE
    LET thirdReserved2 == ReadBytes(secondReserved2.rest, 2) IN IF ~thirdReserved2.ok THEN Fail ELSE
    LET suspended == ReadBytes(thirdReserved2.rest, 1) IN IF ~suspended.ok THEN Fail ELSE
    LET openClose == ReadBytes(suspended.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET pan == ReadBytes(openClose.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET segmentChar1 == ReadBytes(pan.rest, 1) IN IF ~segmentChar1.ok THEN Fail ELSE
    LET participantType == ReadBytes(segmentChar1.rest, 1) IN IF ~participantType.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(participantType.rest, 10) IN IF ~accountNumber.ok THEN Fail ELSE
    LET proClientChar1 == ReadBytes(accountNumber.rest, 1) IN IF ~proClientChar1.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(proClientChar1.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET settlor == ReadBytes(reserved1.rest, 12) IN IF ~settlor.ok THEN Fail ELSE
    LET referenceId == ReadBytes(settlor.rest, 4) IN IF ~referenceId.ok THEN Fail ELSE
    Ok([ reasonCode            |-> reasonCode.value,
         token                 |-> token.value,
         orderNumber           |-> orderNumber.value,
         bookType              |-> bookType.value,
         buySell               |-> buySell.value,
         disclosedVolume       |-> disclosedVolume.value,
         disclosedVolRemaining |-> disclosedVolRemaining.value,
         totalVolRemaining     |-> totalVolRemaining.value,
         volume                |-> volume.value,
         price                 |-> price.value,
         triggerPrice          |-> triggerPrice.value,
         stOrderFlags          |-> stOrderFlags.value,
         traderId              |-> traderId.value,
         nnfField              |-> nnfField.value,
         algoId                |-> algoId.value,
         activityTimeInNanos   |-> activityTimeInNanos.value,
         reserved2             |-> reserved2.value,
         secondReserved2       |-> secondReserved2.value,
         thirdReserved2        |-> thirdReserved2.value,
         suspended             |-> suspended.value,
         openClose             |-> openClose.value,
         pan                   |-> pan.value,
         segmentChar1          |-> segmentChar1.value,
         participantType       |-> participantType.value,
         accountNumber         |-> accountNumber.value,
         proClientChar1        |-> proClientChar1.value,
         reserved1             |-> reserved1.value,
         settlor               |-> settlor.value,
         referenceId           |-> referenceId.value ], referenceId.rest)

ZeroOnStopNotificationMessage ==
    [ reasonCode            |-> [i \in 1 .. 2 |-> 0],
      token                 |-> [i \in 1 .. 4 |-> 0],
      orderNumber           |-> [i \in 1 .. 8 |-> 0],
      bookType              |-> [i \in 1 .. 2 |-> 0],
      buySell               |-> [i \in 1 .. 2 |-> 0],
      disclosedVolume       |-> [i \in 1 .. 4 |-> 0],
      disclosedVolRemaining |-> [i \in 1 .. 4 |-> 0],
      totalVolRemaining     |-> [i \in 1 .. 4 |-> 0],
      volume                |-> [i \in 1 .. 4 |-> 0],
      price                 |-> [i \in 1 .. 4 |-> 0],
      triggerPrice          |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags          |-> [i \in 1 .. 2 |-> 0],
      traderId              |-> [i \in 1 .. 4 |-> 0],
      nnfField              |-> [i \in 1 .. 8 |-> 0],
      algoId                |-> [i \in 1 .. 4 |-> 0],
      activityTimeInNanos   |-> [i \in 1 .. 8 |-> 0],
      reserved2             |-> [i \in 1 .. 2 |-> 0],
      secondReserved2       |-> [i \in 1 .. 2 |-> 0],
      thirdReserved2        |-> [i \in 1 .. 2 |-> 0],
      suspended             |-> [i \in 1 .. 1 |-> 0],
      openClose             |-> [i \in 1 .. 1 |-> 0],
      pan                   |-> [i \in 1 .. 10 |-> 0],
      segmentChar1          |-> [i \in 1 .. 1 |-> 0],
      participantType       |-> [i \in 1 .. 1 |-> 0],
      accountNumber         |-> [i \in 1 .. 10 |-> 0],
      proClientChar1        |-> [i \in 1 .. 1 |-> 0],
      reserved1             |-> [i \in 1 .. 1 |-> 0],
      settlor               |-> [i \in 1 .. 12 |-> 0],
      referenceId           |-> [i \in 1 .. 4 |-> 0] ]

(* On Stop Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedOnStopNotificationMessage ==
    { ZeroOnStopNotificationMessage }
        \cup { [ZeroOnStopNotificationMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroOnStopNotificationMessage EXCEPT !.token = one] : one \in Sample(4) }
        \cup { [ZeroOnStopNotificationMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroOnStopNotificationMessage EXCEPT !.bookType = one] : one \in Sample(2) }
        \cup { [ZeroOnStopNotificationMessage EXCEPT !.buySell = one] : one \in Sample(2) }
        \cup { [ZeroOnStopNotificationMessage EXCEPT !.disclosedVolume = one] : one \in Sample(4) }
        \cup { [ZeroOnStopNotificationMessage EXCEPT !.disclosedVolRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOnStopNotificationMessage EXCEPT !.totalVolRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOnStopNotificationMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroOnStopNotificationMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOnStopNotificationMessage EXCEPT !.triggerPrice = one] : one \in Sample(4) }
        \cup { [ZeroOnStopNotificationMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroOnStopNotificationMessage EXCEPT !.traderId = one] : one \in Sample(4) }
        \cup { [ZeroOnStopNotificationMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroOnStopNotificationMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroOnStopNotificationMessage EXCEPT !.activityTimeInNanos = one] : one \in Sample(8) }
        \cup { [ZeroOnStopNotificationMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOnStopNotificationMessage EXCEPT !.secondReserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOnStopNotificationMessage EXCEPT !.thirdReserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOnStopNotificationMessage EXCEPT !.suspended = one] : one \in Sample(1) }
        \cup { [ZeroOnStopNotificationMessage EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroOnStopNotificationMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroOnStopNotificationMessage EXCEPT !.segmentChar1 = one] : one \in Sample(1) }
        \cup { [ZeroOnStopNotificationMessage EXCEPT !.participantType = one] : one \in Sample(1) }
        \cup { [ZeroOnStopNotificationMessage EXCEPT !.accountNumber = one] : one \in Sample(10) }
        \cup { [ZeroOnStopNotificationMessage EXCEPT !.proClientChar1 = one] : one \in Sample(1) }
        \cup { [ZeroOnStopNotificationMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOnStopNotificationMessage EXCEPT !.settlor = one] : one \in Sample(12) }
        \cup { [ZeroOnStopNotificationMessage EXCEPT !.referenceId = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Error Message: 116 bytes                                          *)
(***************************************************************************)

OrderErrorMessage ==
    [ reasonCode            : Sample(2),
      token                 : Sample(4),
      orderNumber           : Sample(8),
      bookType              : Sample(2),
      buySell               : Sample(2),
      disclosedVolume       : Sample(4),
      disclosedVolRemaining : Sample(4),
      totalVolRemaining     : Sample(4),
      volume                : Sample(4),
      price                 : Sample(4),
      triggerPrice          : Sample(4),
      stOrderFlags          : Sample(2),
      traderId              : Sample(4),
      nnfField              : Sample(8),
      algoId                : Sample(4),
      activityTimeInNanos   : Sample(8),
      reserved2             : Sample(2),
      secondReserved2       : Sample(2),
      thirdReserved2        : Sample(2),
      suspended             : Sample(1),
      openClose             : Sample(1),
      pan                   : Sample(10),
      segmentChar1          : Sample(1),
      participantType       : Sample(1),
      accountNumber         : Sample(10),
      proClientChar1        : Sample(1),
      reserved1             : Sample(1),
      settlor               : Sample(12),
      referenceId           : Sample(4) ]

EncodeOrderErrorMessage(message) ==
    message.reasonCode
        \o message.token
        \o message.orderNumber
        \o message.bookType
        \o message.buySell
        \o message.disclosedVolume
        \o message.disclosedVolRemaining
        \o message.totalVolRemaining
        \o message.volume
        \o message.price
        \o message.triggerPrice
        \o message.stOrderFlags
        \o message.traderId
        \o message.nnfField
        \o message.algoId
        \o message.activityTimeInNanos
        \o message.reserved2
        \o message.secondReserved2
        \o message.thirdReserved2
        \o message.suspended
        \o message.openClose
        \o message.pan
        \o message.segmentChar1
        \o message.participantType
        \o message.accountNumber
        \o message.proClientChar1
        \o message.reserved1
        \o message.settlor
        \o message.referenceId

DecodeOrderErrorMessage(bytes) ==
    LET reasonCode == ReadBytes(bytes, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET token == ReadBytes(reasonCode.rest, 4) IN IF ~token.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(token.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET bookType == ReadBytes(orderNumber.rest, 2) IN IF ~bookType.ok THEN Fail ELSE
    LET buySell == ReadBytes(bookType.rest, 2) IN IF ~buySell.ok THEN Fail ELSE
    LET disclosedVolume == ReadBytes(buySell.rest, 4) IN IF ~disclosedVolume.ok THEN Fail ELSE
    LET disclosedVolRemaining == ReadBytes(disclosedVolume.rest, 4) IN IF ~disclosedVolRemaining.ok THEN Fail ELSE
    LET totalVolRemaining == ReadBytes(disclosedVolRemaining.rest, 4) IN IF ~totalVolRemaining.ok THEN Fail ELSE
    LET volume == ReadBytes(totalVolRemaining.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET price == ReadBytes(volume.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET triggerPrice == ReadBytes(price.rest, 4) IN IF ~triggerPrice.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(triggerPrice.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET traderId == ReadBytes(stOrderFlags.rest, 4) IN IF ~traderId.ok THEN Fail ELSE
    LET nnfField == ReadBytes(traderId.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET algoId == ReadBytes(nnfField.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET activityTimeInNanos == ReadBytes(algoId.rest, 8) IN IF ~activityTimeInNanos.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(activityTimeInNanos.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET secondReserved2 == ReadBytes(reserved2.rest, 2) IN IF ~secondReserved2.ok THEN Fail ELSE
    LET thirdReserved2 == ReadBytes(secondReserved2.rest, 2) IN IF ~thirdReserved2.ok THEN Fail ELSE
    LET suspended == ReadBytes(thirdReserved2.rest, 1) IN IF ~suspended.ok THEN Fail ELSE
    LET openClose == ReadBytes(suspended.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET pan == ReadBytes(openClose.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET segmentChar1 == ReadBytes(pan.rest, 1) IN IF ~segmentChar1.ok THEN Fail ELSE
    LET participantType == ReadBytes(segmentChar1.rest, 1) IN IF ~participantType.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(participantType.rest, 10) IN IF ~accountNumber.ok THEN Fail ELSE
    LET proClientChar1 == ReadBytes(accountNumber.rest, 1) IN IF ~proClientChar1.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(proClientChar1.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET settlor == ReadBytes(reserved1.rest, 12) IN IF ~settlor.ok THEN Fail ELSE
    LET referenceId == ReadBytes(settlor.rest, 4) IN IF ~referenceId.ok THEN Fail ELSE
    Ok([ reasonCode            |-> reasonCode.value,
         token                 |-> token.value,
         orderNumber           |-> orderNumber.value,
         bookType              |-> bookType.value,
         buySell               |-> buySell.value,
         disclosedVolume       |-> disclosedVolume.value,
         disclosedVolRemaining |-> disclosedVolRemaining.value,
         totalVolRemaining     |-> totalVolRemaining.value,
         volume                |-> volume.value,
         price                 |-> price.value,
         triggerPrice          |-> triggerPrice.value,
         stOrderFlags          |-> stOrderFlags.value,
         traderId              |-> traderId.value,
         nnfField              |-> nnfField.value,
         algoId                |-> algoId.value,
         activityTimeInNanos   |-> activityTimeInNanos.value,
         reserved2             |-> reserved2.value,
         secondReserved2       |-> secondReserved2.value,
         thirdReserved2        |-> thirdReserved2.value,
         suspended             |-> suspended.value,
         openClose             |-> openClose.value,
         pan                   |-> pan.value,
         segmentChar1          |-> segmentChar1.value,
         participantType       |-> participantType.value,
         accountNumber         |-> accountNumber.value,
         proClientChar1        |-> proClientChar1.value,
         reserved1             |-> reserved1.value,
         settlor               |-> settlor.value,
         referenceId           |-> referenceId.value ], referenceId.rest)

ZeroOrderErrorMessage ==
    [ reasonCode            |-> [i \in 1 .. 2 |-> 0],
      token                 |-> [i \in 1 .. 4 |-> 0],
      orderNumber           |-> [i \in 1 .. 8 |-> 0],
      bookType              |-> [i \in 1 .. 2 |-> 0],
      buySell               |-> [i \in 1 .. 2 |-> 0],
      disclosedVolume       |-> [i \in 1 .. 4 |-> 0],
      disclosedVolRemaining |-> [i \in 1 .. 4 |-> 0],
      totalVolRemaining     |-> [i \in 1 .. 4 |-> 0],
      volume                |-> [i \in 1 .. 4 |-> 0],
      price                 |-> [i \in 1 .. 4 |-> 0],
      triggerPrice          |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags          |-> [i \in 1 .. 2 |-> 0],
      traderId              |-> [i \in 1 .. 4 |-> 0],
      nnfField              |-> [i \in 1 .. 8 |-> 0],
      algoId                |-> [i \in 1 .. 4 |-> 0],
      activityTimeInNanos   |-> [i \in 1 .. 8 |-> 0],
      reserved2             |-> [i \in 1 .. 2 |-> 0],
      secondReserved2       |-> [i \in 1 .. 2 |-> 0],
      thirdReserved2        |-> [i \in 1 .. 2 |-> 0],
      suspended             |-> [i \in 1 .. 1 |-> 0],
      openClose             |-> [i \in 1 .. 1 |-> 0],
      pan                   |-> [i \in 1 .. 10 |-> 0],
      segmentChar1          |-> [i \in 1 .. 1 |-> 0],
      participantType       |-> [i \in 1 .. 1 |-> 0],
      accountNumber         |-> [i \in 1 .. 10 |-> 0],
      proClientChar1        |-> [i \in 1 .. 1 |-> 0],
      reserved1             |-> [i \in 1 .. 1 |-> 0],
      settlor               |-> [i \in 1 .. 12 |-> 0],
      referenceId           |-> [i \in 1 .. 4 |-> 0] ]

(* Order Error Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderErrorMessage ==
    { ZeroOrderErrorMessage }
        \cup { [ZeroOrderErrorMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroOrderErrorMessage EXCEPT !.token = one] : one \in Sample(4) }
        \cup { [ZeroOrderErrorMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderErrorMessage EXCEPT !.bookType = one] : one \in Sample(2) }
        \cup { [ZeroOrderErrorMessage EXCEPT !.buySell = one] : one \in Sample(2) }
        \cup { [ZeroOrderErrorMessage EXCEPT !.disclosedVolume = one] : one \in Sample(4) }
        \cup { [ZeroOrderErrorMessage EXCEPT !.disclosedVolRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderErrorMessage EXCEPT !.totalVolRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderErrorMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroOrderErrorMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderErrorMessage EXCEPT !.triggerPrice = one] : one \in Sample(4) }
        \cup { [ZeroOrderErrorMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroOrderErrorMessage EXCEPT !.traderId = one] : one \in Sample(4) }
        \cup { [ZeroOrderErrorMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroOrderErrorMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroOrderErrorMessage EXCEPT !.activityTimeInNanos = one] : one \in Sample(8) }
        \cup { [ZeroOrderErrorMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderErrorMessage EXCEPT !.secondReserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderErrorMessage EXCEPT !.thirdReserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderErrorMessage EXCEPT !.suspended = one] : one \in Sample(1) }
        \cup { [ZeroOrderErrorMessage EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroOrderErrorMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroOrderErrorMessage EXCEPT !.segmentChar1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderErrorMessage EXCEPT !.participantType = one] : one \in Sample(1) }
        \cup { [ZeroOrderErrorMessage EXCEPT !.accountNumber = one] : one \in Sample(10) }
        \cup { [ZeroOrderErrorMessage EXCEPT !.proClientChar1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderErrorMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderErrorMessage EXCEPT !.settlor = one] : one \in Sample(12) }
        \cup { [ZeroOrderErrorMessage EXCEPT !.referenceId = one] : one \in Sample(4) }

(***************************************************************************)
(* Batch Order Cancel Message: 116 bytes                                   *)
(***************************************************************************)

BatchOrderCancelMessage ==
    [ reasonCode            : Sample(2),
      token                 : Sample(4),
      orderNumber           : Sample(8),
      bookType              : Sample(2),
      buySell               : Sample(2),
      disclosedVolume       : Sample(4),
      disclosedVolRemaining : Sample(4),
      totalVolRemaining     : Sample(4),
      volume                : Sample(4),
      price                 : Sample(4),
      triggerPrice          : Sample(4),
      stOrderFlags          : Sample(2),
      traderId              : Sample(4),
      nnfField              : Sample(8),
      algoId                : Sample(4),
      activityTimeInNanos   : Sample(8),
      reserved2             : Sample(2),
      secondReserved2       : Sample(2),
      thirdReserved2        : Sample(2),
      suspended             : Sample(1),
      openClose             : Sample(1),
      pan                   : Sample(10),
      segmentChar1          : Sample(1),
      participantType       : Sample(1),
      accountNumber         : Sample(10),
      proClientChar1        : Sample(1),
      reserved1             : Sample(1),
      settlor               : Sample(12),
      referenceId           : Sample(4) ]

EncodeBatchOrderCancelMessage(message) ==
    message.reasonCode
        \o message.token
        \o message.orderNumber
        \o message.bookType
        \o message.buySell
        \o message.disclosedVolume
        \o message.disclosedVolRemaining
        \o message.totalVolRemaining
        \o message.volume
        \o message.price
        \o message.triggerPrice
        \o message.stOrderFlags
        \o message.traderId
        \o message.nnfField
        \o message.algoId
        \o message.activityTimeInNanos
        \o message.reserved2
        \o message.secondReserved2
        \o message.thirdReserved2
        \o message.suspended
        \o message.openClose
        \o message.pan
        \o message.segmentChar1
        \o message.participantType
        \o message.accountNumber
        \o message.proClientChar1
        \o message.reserved1
        \o message.settlor
        \o message.referenceId

DecodeBatchOrderCancelMessage(bytes) ==
    LET reasonCode == ReadBytes(bytes, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET token == ReadBytes(reasonCode.rest, 4) IN IF ~token.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(token.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET bookType == ReadBytes(orderNumber.rest, 2) IN IF ~bookType.ok THEN Fail ELSE
    LET buySell == ReadBytes(bookType.rest, 2) IN IF ~buySell.ok THEN Fail ELSE
    LET disclosedVolume == ReadBytes(buySell.rest, 4) IN IF ~disclosedVolume.ok THEN Fail ELSE
    LET disclosedVolRemaining == ReadBytes(disclosedVolume.rest, 4) IN IF ~disclosedVolRemaining.ok THEN Fail ELSE
    LET totalVolRemaining == ReadBytes(disclosedVolRemaining.rest, 4) IN IF ~totalVolRemaining.ok THEN Fail ELSE
    LET volume == ReadBytes(totalVolRemaining.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET price == ReadBytes(volume.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET triggerPrice == ReadBytes(price.rest, 4) IN IF ~triggerPrice.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(triggerPrice.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET traderId == ReadBytes(stOrderFlags.rest, 4) IN IF ~traderId.ok THEN Fail ELSE
    LET nnfField == ReadBytes(traderId.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET algoId == ReadBytes(nnfField.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET activityTimeInNanos == ReadBytes(algoId.rest, 8) IN IF ~activityTimeInNanos.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(activityTimeInNanos.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET secondReserved2 == ReadBytes(reserved2.rest, 2) IN IF ~secondReserved2.ok THEN Fail ELSE
    LET thirdReserved2 == ReadBytes(secondReserved2.rest, 2) IN IF ~thirdReserved2.ok THEN Fail ELSE
    LET suspended == ReadBytes(thirdReserved2.rest, 1) IN IF ~suspended.ok THEN Fail ELSE
    LET openClose == ReadBytes(suspended.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET pan == ReadBytes(openClose.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET segmentChar1 == ReadBytes(pan.rest, 1) IN IF ~segmentChar1.ok THEN Fail ELSE
    LET participantType == ReadBytes(segmentChar1.rest, 1) IN IF ~participantType.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(participantType.rest, 10) IN IF ~accountNumber.ok THEN Fail ELSE
    LET proClientChar1 == ReadBytes(accountNumber.rest, 1) IN IF ~proClientChar1.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(proClientChar1.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET settlor == ReadBytes(reserved1.rest, 12) IN IF ~settlor.ok THEN Fail ELSE
    LET referenceId == ReadBytes(settlor.rest, 4) IN IF ~referenceId.ok THEN Fail ELSE
    Ok([ reasonCode            |-> reasonCode.value,
         token                 |-> token.value,
         orderNumber           |-> orderNumber.value,
         bookType              |-> bookType.value,
         buySell               |-> buySell.value,
         disclosedVolume       |-> disclosedVolume.value,
         disclosedVolRemaining |-> disclosedVolRemaining.value,
         totalVolRemaining     |-> totalVolRemaining.value,
         volume                |-> volume.value,
         price                 |-> price.value,
         triggerPrice          |-> triggerPrice.value,
         stOrderFlags          |-> stOrderFlags.value,
         traderId              |-> traderId.value,
         nnfField              |-> nnfField.value,
         algoId                |-> algoId.value,
         activityTimeInNanos   |-> activityTimeInNanos.value,
         reserved2             |-> reserved2.value,
         secondReserved2       |-> secondReserved2.value,
         thirdReserved2        |-> thirdReserved2.value,
         suspended             |-> suspended.value,
         openClose             |-> openClose.value,
         pan                   |-> pan.value,
         segmentChar1          |-> segmentChar1.value,
         participantType       |-> participantType.value,
         accountNumber         |-> accountNumber.value,
         proClientChar1        |-> proClientChar1.value,
         reserved1             |-> reserved1.value,
         settlor               |-> settlor.value,
         referenceId           |-> referenceId.value ], referenceId.rest)

ZeroBatchOrderCancelMessage ==
    [ reasonCode            |-> [i \in 1 .. 2 |-> 0],
      token                 |-> [i \in 1 .. 4 |-> 0],
      orderNumber           |-> [i \in 1 .. 8 |-> 0],
      bookType              |-> [i \in 1 .. 2 |-> 0],
      buySell               |-> [i \in 1 .. 2 |-> 0],
      disclosedVolume       |-> [i \in 1 .. 4 |-> 0],
      disclosedVolRemaining |-> [i \in 1 .. 4 |-> 0],
      totalVolRemaining     |-> [i \in 1 .. 4 |-> 0],
      volume                |-> [i \in 1 .. 4 |-> 0],
      price                 |-> [i \in 1 .. 4 |-> 0],
      triggerPrice          |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags          |-> [i \in 1 .. 2 |-> 0],
      traderId              |-> [i \in 1 .. 4 |-> 0],
      nnfField              |-> [i \in 1 .. 8 |-> 0],
      algoId                |-> [i \in 1 .. 4 |-> 0],
      activityTimeInNanos   |-> [i \in 1 .. 8 |-> 0],
      reserved2             |-> [i \in 1 .. 2 |-> 0],
      secondReserved2       |-> [i \in 1 .. 2 |-> 0],
      thirdReserved2        |-> [i \in 1 .. 2 |-> 0],
      suspended             |-> [i \in 1 .. 1 |-> 0],
      openClose             |-> [i \in 1 .. 1 |-> 0],
      pan                   |-> [i \in 1 .. 10 |-> 0],
      segmentChar1          |-> [i \in 1 .. 1 |-> 0],
      participantType       |-> [i \in 1 .. 1 |-> 0],
      accountNumber         |-> [i \in 1 .. 10 |-> 0],
      proClientChar1        |-> [i \in 1 .. 1 |-> 0],
      reserved1             |-> [i \in 1 .. 1 |-> 0],
      settlor               |-> [i \in 1 .. 12 |-> 0],
      referenceId           |-> [i \in 1 .. 4 |-> 0] ]

(* Batch Order Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedBatchOrderCancelMessage ==
    { ZeroBatchOrderCancelMessage }
        \cup { [ZeroBatchOrderCancelMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroBatchOrderCancelMessage EXCEPT !.token = one] : one \in Sample(4) }
        \cup { [ZeroBatchOrderCancelMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroBatchOrderCancelMessage EXCEPT !.bookType = one] : one \in Sample(2) }
        \cup { [ZeroBatchOrderCancelMessage EXCEPT !.buySell = one] : one \in Sample(2) }
        \cup { [ZeroBatchOrderCancelMessage EXCEPT !.disclosedVolume = one] : one \in Sample(4) }
        \cup { [ZeroBatchOrderCancelMessage EXCEPT !.disclosedVolRemaining = one] : one \in Sample(4) }
        \cup { [ZeroBatchOrderCancelMessage EXCEPT !.totalVolRemaining = one] : one \in Sample(4) }
        \cup { [ZeroBatchOrderCancelMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroBatchOrderCancelMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroBatchOrderCancelMessage EXCEPT !.triggerPrice = one] : one \in Sample(4) }
        \cup { [ZeroBatchOrderCancelMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroBatchOrderCancelMessage EXCEPT !.traderId = one] : one \in Sample(4) }
        \cup { [ZeroBatchOrderCancelMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroBatchOrderCancelMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroBatchOrderCancelMessage EXCEPT !.activityTimeInNanos = one] : one \in Sample(8) }
        \cup { [ZeroBatchOrderCancelMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroBatchOrderCancelMessage EXCEPT !.secondReserved2 = one] : one \in Sample(2) }
        \cup { [ZeroBatchOrderCancelMessage EXCEPT !.thirdReserved2 = one] : one \in Sample(2) }
        \cup { [ZeroBatchOrderCancelMessage EXCEPT !.suspended = one] : one \in Sample(1) }
        \cup { [ZeroBatchOrderCancelMessage EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroBatchOrderCancelMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroBatchOrderCancelMessage EXCEPT !.segmentChar1 = one] : one \in Sample(1) }
        \cup { [ZeroBatchOrderCancelMessage EXCEPT !.participantType = one] : one \in Sample(1) }
        \cup { [ZeroBatchOrderCancelMessage EXCEPT !.accountNumber = one] : one \in Sample(10) }
        \cup { [ZeroBatchOrderCancelMessage EXCEPT !.proClientChar1 = one] : one \in Sample(1) }
        \cup { [ZeroBatchOrderCancelMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroBatchOrderCancelMessage EXCEPT !.settlor = one] : one \in Sample(12) }
        \cup { [ZeroBatchOrderCancelMessage EXCEPT !.referenceId = one] : one \in Sample(4) }

(***************************************************************************)
(* Ms Spd Leg Info Leg 2: 18 bytes                                         *)
(***************************************************************************)

MsSpdLegInfoLeg2 ==
    [ token2             : Sample(4),
      buySell2           : Sample(2),
      totalVolRemaining2 : Sample(4),
      volume2            : Sample(4),
      stOrderFlags       : Sample(2),
      openClose2         : Sample(1),
      reserved1          : Sample(1) ]

EncodeMsSpdLegInfoLeg2(message) ==
    message.token2
        \o message.buySell2
        \o message.totalVolRemaining2
        \o message.volume2
        \o message.stOrderFlags
        \o message.openClose2
        \o message.reserved1

DecodeMsSpdLegInfoLeg2(bytes) ==
    LET token2 == ReadBytes(bytes, 4) IN IF ~token2.ok THEN Fail ELSE
    LET buySell2 == ReadBytes(token2.rest, 2) IN IF ~buySell2.ok THEN Fail ELSE
    LET totalVolRemaining2 == ReadBytes(buySell2.rest, 4) IN IF ~totalVolRemaining2.ok THEN Fail ELSE
    LET volume2 == ReadBytes(totalVolRemaining2.rest, 4) IN IF ~volume2.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(volume2.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET openClose2 == ReadBytes(stOrderFlags.rest, 1) IN IF ~openClose2.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(openClose2.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ token2             |-> token2.value,
         buySell2           |-> buySell2.value,
         totalVolRemaining2 |-> totalVolRemaining2.value,
         volume2            |-> volume2.value,
         stOrderFlags       |-> stOrderFlags.value,
         openClose2         |-> openClose2.value,
         reserved1          |-> reserved1.value ], reserved1.rest)

ZeroMsSpdLegInfoLeg2 ==
    [ token2             |-> [i \in 1 .. 4 |-> 0],
      buySell2           |-> [i \in 1 .. 2 |-> 0],
      totalVolRemaining2 |-> [i \in 1 .. 4 |-> 0],
      volume2            |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags       |-> [i \in 1 .. 2 |-> 0],
      openClose2         |-> [i \in 1 .. 1 |-> 0],
      reserved1          |-> [i \in 1 .. 1 |-> 0] ]

(* Ms Spd Leg Info Leg 2 at zero, then each field in turn at the values it is checked at *)
CheckedMsSpdLegInfoLeg2 ==
    { ZeroMsSpdLegInfoLeg2 }
        \cup { [ZeroMsSpdLegInfoLeg2 EXCEPT !.token2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg2 EXCEPT !.buySell2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg2 EXCEPT !.totalVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg2 EXCEPT !.volume2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg2 EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg2 EXCEPT !.openClose2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg2 EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Ms Spd Leg Info Leg 3: 18 bytes                                         *)
(***************************************************************************)

MsSpdLegInfoLeg3 ==
    [ token2             : Sample(4),
      buySell2           : Sample(2),
      totalVolRemaining2 : Sample(4),
      volume2            : Sample(4),
      stOrderFlags       : Sample(2),
      openClose2         : Sample(1),
      reserved1          : Sample(1) ]

EncodeMsSpdLegInfoLeg3(message) ==
    message.token2
        \o message.buySell2
        \o message.totalVolRemaining2
        \o message.volume2
        \o message.stOrderFlags
        \o message.openClose2
        \o message.reserved1

DecodeMsSpdLegInfoLeg3(bytes) ==
    LET token2 == ReadBytes(bytes, 4) IN IF ~token2.ok THEN Fail ELSE
    LET buySell2 == ReadBytes(token2.rest, 2) IN IF ~buySell2.ok THEN Fail ELSE
    LET totalVolRemaining2 == ReadBytes(buySell2.rest, 4) IN IF ~totalVolRemaining2.ok THEN Fail ELSE
    LET volume2 == ReadBytes(totalVolRemaining2.rest, 4) IN IF ~volume2.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(volume2.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET openClose2 == ReadBytes(stOrderFlags.rest, 1) IN IF ~openClose2.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(openClose2.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ token2             |-> token2.value,
         buySell2           |-> buySell2.value,
         totalVolRemaining2 |-> totalVolRemaining2.value,
         volume2            |-> volume2.value,
         stOrderFlags       |-> stOrderFlags.value,
         openClose2         |-> openClose2.value,
         reserved1          |-> reserved1.value ], reserved1.rest)

ZeroMsSpdLegInfoLeg3 ==
    [ token2             |-> [i \in 1 .. 4 |-> 0],
      buySell2           |-> [i \in 1 .. 2 |-> 0],
      totalVolRemaining2 |-> [i \in 1 .. 4 |-> 0],
      volume2            |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags       |-> [i \in 1 .. 2 |-> 0],
      openClose2         |-> [i \in 1 .. 1 |-> 0],
      reserved1          |-> [i \in 1 .. 1 |-> 0] ]

(* Ms Spd Leg Info Leg 3 at zero, then each field in turn at the values it is checked at *)
CheckedMsSpdLegInfoLeg3 ==
    { ZeroMsSpdLegInfoLeg3 }
        \cup { [ZeroMsSpdLegInfoLeg3 EXCEPT !.token2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg3 EXCEPT !.buySell2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg3 EXCEPT !.totalVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg3 EXCEPT !.volume2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg3 EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg3 EXCEPT !.openClose2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg3 EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Sp Order Confirmation Message: 132 bytes                                *)
(***************************************************************************)

SpOrderConfirmationMessage ==
    [ token1              : Sample(4),
      orderNumber1        : Sample(8),
      bookType1           : Sample(2),
      buySell1            : Sample(2),
      totalVolRemaining1  : Sample(4),
      volume1             : Sample(4),
      stOrderFlags        : Sample(2),
      traderId1           : Sample(4),
      nnfField            : Sample(8),
      algoId              : Sample(4),
      activityTimeInNanos : Sample(8),
      pan                 : Sample(10),
      accountNumber1      : Sample(10),
      proClient1          : Sample(1),
      segmentChar1        : Sample(1),
      openClose1          : Sample(1),
      reserved1           : Sample(1),
      settlor1            : Sample(12),
      priceDiff           : Sample(4),
      referenceId         : Sample(4),
      reasonCode          : Sample(2),
      msSpdLegInfoLeg2    : MsSpdLegInfoLeg2,
      msSpdLegInfoLeg3    : MsSpdLegInfoLeg3 ]

EncodeSpOrderConfirmationMessage(message) ==
    message.token1
        \o message.orderNumber1
        \o message.bookType1
        \o message.buySell1
        \o message.totalVolRemaining1
        \o message.volume1
        \o message.stOrderFlags
        \o message.traderId1
        \o message.nnfField
        \o message.algoId
        \o message.activityTimeInNanos
        \o message.pan
        \o message.accountNumber1
        \o message.proClient1
        \o message.segmentChar1
        \o message.openClose1
        \o message.reserved1
        \o message.settlor1
        \o message.priceDiff
        \o message.referenceId
        \o message.reasonCode
        \o EncodeMsSpdLegInfoLeg2(message.msSpdLegInfoLeg2)
        \o EncodeMsSpdLegInfoLeg3(message.msSpdLegInfoLeg3)

DecodeSpOrderConfirmationMessage(bytes) ==
    LET token1 == ReadBytes(bytes, 4) IN IF ~token1.ok THEN Fail ELSE
    LET orderNumber1 == ReadBytes(token1.rest, 8) IN IF ~orderNumber1.ok THEN Fail ELSE
    LET bookType1 == ReadBytes(orderNumber1.rest, 2) IN IF ~bookType1.ok THEN Fail ELSE
    LET buySell1 == ReadBytes(bookType1.rest, 2) IN IF ~buySell1.ok THEN Fail ELSE
    LET totalVolRemaining1 == ReadBytes(buySell1.rest, 4) IN IF ~totalVolRemaining1.ok THEN Fail ELSE
    LET volume1 == ReadBytes(totalVolRemaining1.rest, 4) IN IF ~volume1.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(volume1.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET traderId1 == ReadBytes(stOrderFlags.rest, 4) IN IF ~traderId1.ok THEN Fail ELSE
    LET nnfField == ReadBytes(traderId1.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET algoId == ReadBytes(nnfField.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET activityTimeInNanos == ReadBytes(algoId.rest, 8) IN IF ~activityTimeInNanos.ok THEN Fail ELSE
    LET pan == ReadBytes(activityTimeInNanos.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET accountNumber1 == ReadBytes(pan.rest, 10) IN IF ~accountNumber1.ok THEN Fail ELSE
    LET proClient1 == ReadBytes(accountNumber1.rest, 1) IN IF ~proClient1.ok THEN Fail ELSE
    LET segmentChar1 == ReadBytes(proClient1.rest, 1) IN IF ~segmentChar1.ok THEN Fail ELSE
    LET openClose1 == ReadBytes(segmentChar1.rest, 1) IN IF ~openClose1.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(openClose1.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET settlor1 == ReadBytes(reserved1.rest, 12) IN IF ~settlor1.ok THEN Fail ELSE
    LET priceDiff == ReadBytes(settlor1.rest, 4) IN IF ~priceDiff.ok THEN Fail ELSE
    LET referenceId == ReadBytes(priceDiff.rest, 4) IN IF ~referenceId.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(referenceId.rest, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET msSpdLegInfoLeg2 == DecodeMsSpdLegInfoLeg2(reasonCode.rest) IN IF ~msSpdLegInfoLeg2.ok THEN Fail ELSE
    LET msSpdLegInfoLeg3 == DecodeMsSpdLegInfoLeg3(msSpdLegInfoLeg2.rest) IN IF ~msSpdLegInfoLeg3.ok THEN Fail ELSE
    Ok([ token1              |-> token1.value,
         orderNumber1        |-> orderNumber1.value,
         bookType1           |-> bookType1.value,
         buySell1            |-> buySell1.value,
         totalVolRemaining1  |-> totalVolRemaining1.value,
         volume1             |-> volume1.value,
         stOrderFlags        |-> stOrderFlags.value,
         traderId1           |-> traderId1.value,
         nnfField            |-> nnfField.value,
         algoId              |-> algoId.value,
         activityTimeInNanos |-> activityTimeInNanos.value,
         pan                 |-> pan.value,
         accountNumber1      |-> accountNumber1.value,
         proClient1          |-> proClient1.value,
         segmentChar1        |-> segmentChar1.value,
         openClose1          |-> openClose1.value,
         reserved1           |-> reserved1.value,
         settlor1            |-> settlor1.value,
         priceDiff           |-> priceDiff.value,
         referenceId         |-> referenceId.value,
         reasonCode          |-> reasonCode.value,
         msSpdLegInfoLeg2    |-> msSpdLegInfoLeg2.value,
         msSpdLegInfoLeg3    |-> msSpdLegInfoLeg3.value ], msSpdLegInfoLeg3.rest)

ZeroSpOrderConfirmationMessage ==
    [ token1              |-> [i \in 1 .. 4 |-> 0],
      orderNumber1        |-> [i \in 1 .. 8 |-> 0],
      bookType1           |-> [i \in 1 .. 2 |-> 0],
      buySell1            |-> [i \in 1 .. 2 |-> 0],
      totalVolRemaining1  |-> [i \in 1 .. 4 |-> 0],
      volume1             |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags        |-> [i \in 1 .. 2 |-> 0],
      traderId1           |-> [i \in 1 .. 4 |-> 0],
      nnfField            |-> [i \in 1 .. 8 |-> 0],
      algoId              |-> [i \in 1 .. 4 |-> 0],
      activityTimeInNanos |-> [i \in 1 .. 8 |-> 0],
      pan                 |-> [i \in 1 .. 10 |-> 0],
      accountNumber1      |-> [i \in 1 .. 10 |-> 0],
      proClient1          |-> [i \in 1 .. 1 |-> 0],
      segmentChar1        |-> [i \in 1 .. 1 |-> 0],
      openClose1          |-> [i \in 1 .. 1 |-> 0],
      reserved1           |-> [i \in 1 .. 1 |-> 0],
      settlor1            |-> [i \in 1 .. 12 |-> 0],
      priceDiff           |-> [i \in 1 .. 4 |-> 0],
      referenceId         |-> [i \in 1 .. 4 |-> 0],
      reasonCode          |-> [i \in 1 .. 2 |-> 0],
      msSpdLegInfoLeg2    |-> ZeroMsSpdLegInfoLeg2,
      msSpdLegInfoLeg3    |-> ZeroMsSpdLegInfoLeg3 ]

(* Sp Order Confirmation Message at zero, then each field in turn at the values it is checked at *)
CheckedSpOrderConfirmationMessage ==
    { ZeroSpOrderConfirmationMessage }
        \cup { [ZeroSpOrderConfirmationMessage EXCEPT !.token1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderConfirmationMessage EXCEPT !.orderNumber1 = one] : one \in Sample(8) }
        \cup { [ZeroSpOrderConfirmationMessage EXCEPT !.bookType1 = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderConfirmationMessage EXCEPT !.buySell1 = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderConfirmationMessage EXCEPT !.totalVolRemaining1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderConfirmationMessage EXCEPT !.volume1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderConfirmationMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderConfirmationMessage EXCEPT !.traderId1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderConfirmationMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroSpOrderConfirmationMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderConfirmationMessage EXCEPT !.activityTimeInNanos = one] : one \in Sample(8) }
        \cup { [ZeroSpOrderConfirmationMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroSpOrderConfirmationMessage EXCEPT !.accountNumber1 = one] : one \in Sample(10) }
        \cup { [ZeroSpOrderConfirmationMessage EXCEPT !.proClient1 = one] : one \in Sample(1) }
        \cup { [ZeroSpOrderConfirmationMessage EXCEPT !.segmentChar1 = one] : one \in Sample(1) }
        \cup { [ZeroSpOrderConfirmationMessage EXCEPT !.openClose1 = one] : one \in Sample(1) }
        \cup { [ZeroSpOrderConfirmationMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroSpOrderConfirmationMessage EXCEPT !.settlor1 = one] : one \in Sample(12) }
        \cup { [ZeroSpOrderConfirmationMessage EXCEPT !.priceDiff = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderConfirmationMessage EXCEPT !.referenceId = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderConfirmationMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderConfirmationMessage EXCEPT !.msSpdLegInfoLeg2 = one] : one \in CheckedMsSpdLegInfoLeg2 }
        \cup { [ZeroSpOrderConfirmationMessage EXCEPT !.msSpdLegInfoLeg3 = one] : one \in CheckedMsSpdLegInfoLeg3 }

(***************************************************************************)
(* Ms Spd Leg Info Leg 2: 18 bytes                                         *)
(***************************************************************************)

MsSpdLegInfoLeg22 ==
    [ token2             : Sample(4),
      buySell2           : Sample(2),
      totalVolRemaining2 : Sample(4),
      volume2            : Sample(4),
      stOrderFlags       : Sample(2),
      openClose2         : Sample(1),
      reserved1          : Sample(1) ]

EncodeMsSpdLegInfoLeg22(message) ==
    message.token2
        \o message.buySell2
        \o message.totalVolRemaining2
        \o message.volume2
        \o message.stOrderFlags
        \o message.openClose2
        \o message.reserved1

DecodeMsSpdLegInfoLeg22(bytes) ==
    LET token2 == ReadBytes(bytes, 4) IN IF ~token2.ok THEN Fail ELSE
    LET buySell2 == ReadBytes(token2.rest, 2) IN IF ~buySell2.ok THEN Fail ELSE
    LET totalVolRemaining2 == ReadBytes(buySell2.rest, 4) IN IF ~totalVolRemaining2.ok THEN Fail ELSE
    LET volume2 == ReadBytes(totalVolRemaining2.rest, 4) IN IF ~volume2.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(volume2.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET openClose2 == ReadBytes(stOrderFlags.rest, 1) IN IF ~openClose2.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(openClose2.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ token2             |-> token2.value,
         buySell2           |-> buySell2.value,
         totalVolRemaining2 |-> totalVolRemaining2.value,
         volume2            |-> volume2.value,
         stOrderFlags       |-> stOrderFlags.value,
         openClose2         |-> openClose2.value,
         reserved1          |-> reserved1.value ], reserved1.rest)

ZeroMsSpdLegInfoLeg22 ==
    [ token2             |-> [i \in 1 .. 4 |-> 0],
      buySell2           |-> [i \in 1 .. 2 |-> 0],
      totalVolRemaining2 |-> [i \in 1 .. 4 |-> 0],
      volume2            |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags       |-> [i \in 1 .. 2 |-> 0],
      openClose2         |-> [i \in 1 .. 1 |-> 0],
      reserved1          |-> [i \in 1 .. 1 |-> 0] ]

(* Ms Spd Leg Info Leg 2 at zero, then each field in turn at the values it is checked at *)
CheckedMsSpdLegInfoLeg22 ==
    { ZeroMsSpdLegInfoLeg22 }
        \cup { [ZeroMsSpdLegInfoLeg22 EXCEPT !.token2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg22 EXCEPT !.buySell2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg22 EXCEPT !.totalVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg22 EXCEPT !.volume2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg22 EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg22 EXCEPT !.openClose2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg22 EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Ms Spd Leg Info Leg 3: 18 bytes                                         *)
(***************************************************************************)

MsSpdLegInfoLeg32 ==
    [ token2             : Sample(4),
      buySell2           : Sample(2),
      totalVolRemaining2 : Sample(4),
      volume2            : Sample(4),
      stOrderFlags       : Sample(2),
      openClose2         : Sample(1),
      reserved1          : Sample(1) ]

EncodeMsSpdLegInfoLeg32(message) ==
    message.token2
        \o message.buySell2
        \o message.totalVolRemaining2
        \o message.volume2
        \o message.stOrderFlags
        \o message.openClose2
        \o message.reserved1

DecodeMsSpdLegInfoLeg32(bytes) ==
    LET token2 == ReadBytes(bytes, 4) IN IF ~token2.ok THEN Fail ELSE
    LET buySell2 == ReadBytes(token2.rest, 2) IN IF ~buySell2.ok THEN Fail ELSE
    LET totalVolRemaining2 == ReadBytes(buySell2.rest, 4) IN IF ~totalVolRemaining2.ok THEN Fail ELSE
    LET volume2 == ReadBytes(totalVolRemaining2.rest, 4) IN IF ~volume2.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(volume2.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET openClose2 == ReadBytes(stOrderFlags.rest, 1) IN IF ~openClose2.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(openClose2.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ token2             |-> token2.value,
         buySell2           |-> buySell2.value,
         totalVolRemaining2 |-> totalVolRemaining2.value,
         volume2            |-> volume2.value,
         stOrderFlags       |-> stOrderFlags.value,
         openClose2         |-> openClose2.value,
         reserved1          |-> reserved1.value ], reserved1.rest)

ZeroMsSpdLegInfoLeg32 ==
    [ token2             |-> [i \in 1 .. 4 |-> 0],
      buySell2           |-> [i \in 1 .. 2 |-> 0],
      totalVolRemaining2 |-> [i \in 1 .. 4 |-> 0],
      volume2            |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags       |-> [i \in 1 .. 2 |-> 0],
      openClose2         |-> [i \in 1 .. 1 |-> 0],
      reserved1          |-> [i \in 1 .. 1 |-> 0] ]

(* Ms Spd Leg Info Leg 3 at zero, then each field in turn at the values it is checked at *)
CheckedMsSpdLegInfoLeg32 ==
    { ZeroMsSpdLegInfoLeg32 }
        \cup { [ZeroMsSpdLegInfoLeg32 EXCEPT !.token2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg32 EXCEPT !.buySell2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg32 EXCEPT !.totalVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg32 EXCEPT !.volume2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg32 EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg32 EXCEPT !.openClose2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg32 EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Twol Order Confirmation Message: 132 bytes                              *)
(***************************************************************************)

TwolOrderConfirmationMessage ==
    [ token1              : Sample(4),
      orderNumber1        : Sample(8),
      bookType1           : Sample(2),
      buySell1            : Sample(2),
      totalVolRemaining1  : Sample(4),
      volume1             : Sample(4),
      stOrderFlags        : Sample(2),
      traderId1           : Sample(4),
      nnfField            : Sample(8),
      algoId              : Sample(4),
      activityTimeInNanos : Sample(8),
      pan                 : Sample(10),
      accountNumber1      : Sample(10),
      proClient1          : Sample(1),
      segmentChar1        : Sample(1),
      openClose1          : Sample(1),
      reserved1           : Sample(1),
      settlor1            : Sample(12),
      priceDiff           : Sample(4),
      referenceId         : Sample(4),
      reasonCode          : Sample(2),
      msSpdLegInfoLeg2    : MsSpdLegInfoLeg22,
      msSpdLegInfoLeg3    : MsSpdLegInfoLeg32 ]

EncodeTwolOrderConfirmationMessage(message) ==
    message.token1
        \o message.orderNumber1
        \o message.bookType1
        \o message.buySell1
        \o message.totalVolRemaining1
        \o message.volume1
        \o message.stOrderFlags
        \o message.traderId1
        \o message.nnfField
        \o message.algoId
        \o message.activityTimeInNanos
        \o message.pan
        \o message.accountNumber1
        \o message.proClient1
        \o message.segmentChar1
        \o message.openClose1
        \o message.reserved1
        \o message.settlor1
        \o message.priceDiff
        \o message.referenceId
        \o message.reasonCode
        \o EncodeMsSpdLegInfoLeg22(message.msSpdLegInfoLeg2)
        \o EncodeMsSpdLegInfoLeg32(message.msSpdLegInfoLeg3)

DecodeTwolOrderConfirmationMessage(bytes) ==
    LET token1 == ReadBytes(bytes, 4) IN IF ~token1.ok THEN Fail ELSE
    LET orderNumber1 == ReadBytes(token1.rest, 8) IN IF ~orderNumber1.ok THEN Fail ELSE
    LET bookType1 == ReadBytes(orderNumber1.rest, 2) IN IF ~bookType1.ok THEN Fail ELSE
    LET buySell1 == ReadBytes(bookType1.rest, 2) IN IF ~buySell1.ok THEN Fail ELSE
    LET totalVolRemaining1 == ReadBytes(buySell1.rest, 4) IN IF ~totalVolRemaining1.ok THEN Fail ELSE
    LET volume1 == ReadBytes(totalVolRemaining1.rest, 4) IN IF ~volume1.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(volume1.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET traderId1 == ReadBytes(stOrderFlags.rest, 4) IN IF ~traderId1.ok THEN Fail ELSE
    LET nnfField == ReadBytes(traderId1.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET algoId == ReadBytes(nnfField.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET activityTimeInNanos == ReadBytes(algoId.rest, 8) IN IF ~activityTimeInNanos.ok THEN Fail ELSE
    LET pan == ReadBytes(activityTimeInNanos.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET accountNumber1 == ReadBytes(pan.rest, 10) IN IF ~accountNumber1.ok THEN Fail ELSE
    LET proClient1 == ReadBytes(accountNumber1.rest, 1) IN IF ~proClient1.ok THEN Fail ELSE
    LET segmentChar1 == ReadBytes(proClient1.rest, 1) IN IF ~segmentChar1.ok THEN Fail ELSE
    LET openClose1 == ReadBytes(segmentChar1.rest, 1) IN IF ~openClose1.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(openClose1.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET settlor1 == ReadBytes(reserved1.rest, 12) IN IF ~settlor1.ok THEN Fail ELSE
    LET priceDiff == ReadBytes(settlor1.rest, 4) IN IF ~priceDiff.ok THEN Fail ELSE
    LET referenceId == ReadBytes(priceDiff.rest, 4) IN IF ~referenceId.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(referenceId.rest, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET msSpdLegInfoLeg2 == DecodeMsSpdLegInfoLeg22(reasonCode.rest) IN IF ~msSpdLegInfoLeg2.ok THEN Fail ELSE
    LET msSpdLegInfoLeg3 == DecodeMsSpdLegInfoLeg32(msSpdLegInfoLeg2.rest) IN IF ~msSpdLegInfoLeg3.ok THEN Fail ELSE
    Ok([ token1              |-> token1.value,
         orderNumber1        |-> orderNumber1.value,
         bookType1           |-> bookType1.value,
         buySell1            |-> buySell1.value,
         totalVolRemaining1  |-> totalVolRemaining1.value,
         volume1             |-> volume1.value,
         stOrderFlags        |-> stOrderFlags.value,
         traderId1           |-> traderId1.value,
         nnfField            |-> nnfField.value,
         algoId              |-> algoId.value,
         activityTimeInNanos |-> activityTimeInNanos.value,
         pan                 |-> pan.value,
         accountNumber1      |-> accountNumber1.value,
         proClient1          |-> proClient1.value,
         segmentChar1        |-> segmentChar1.value,
         openClose1          |-> openClose1.value,
         reserved1           |-> reserved1.value,
         settlor1            |-> settlor1.value,
         priceDiff           |-> priceDiff.value,
         referenceId         |-> referenceId.value,
         reasonCode          |-> reasonCode.value,
         msSpdLegInfoLeg2    |-> msSpdLegInfoLeg2.value,
         msSpdLegInfoLeg3    |-> msSpdLegInfoLeg3.value ], msSpdLegInfoLeg3.rest)

ZeroTwolOrderConfirmationMessage ==
    [ token1              |-> [i \in 1 .. 4 |-> 0],
      orderNumber1        |-> [i \in 1 .. 8 |-> 0],
      bookType1           |-> [i \in 1 .. 2 |-> 0],
      buySell1            |-> [i \in 1 .. 2 |-> 0],
      totalVolRemaining1  |-> [i \in 1 .. 4 |-> 0],
      volume1             |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags        |-> [i \in 1 .. 2 |-> 0],
      traderId1           |-> [i \in 1 .. 4 |-> 0],
      nnfField            |-> [i \in 1 .. 8 |-> 0],
      algoId              |-> [i \in 1 .. 4 |-> 0],
      activityTimeInNanos |-> [i \in 1 .. 8 |-> 0],
      pan                 |-> [i \in 1 .. 10 |-> 0],
      accountNumber1      |-> [i \in 1 .. 10 |-> 0],
      proClient1          |-> [i \in 1 .. 1 |-> 0],
      segmentChar1        |-> [i \in 1 .. 1 |-> 0],
      openClose1          |-> [i \in 1 .. 1 |-> 0],
      reserved1           |-> [i \in 1 .. 1 |-> 0],
      settlor1            |-> [i \in 1 .. 12 |-> 0],
      priceDiff           |-> [i \in 1 .. 4 |-> 0],
      referenceId         |-> [i \in 1 .. 4 |-> 0],
      reasonCode          |-> [i \in 1 .. 2 |-> 0],
      msSpdLegInfoLeg2    |-> ZeroMsSpdLegInfoLeg22,
      msSpdLegInfoLeg3    |-> ZeroMsSpdLegInfoLeg32 ]

(* Twol Order Confirmation Message at zero, then each field in turn at the values it is checked at *)
CheckedTwolOrderConfirmationMessage ==
    { ZeroTwolOrderConfirmationMessage }
        \cup { [ZeroTwolOrderConfirmationMessage EXCEPT !.token1 = one] : one \in Sample(4) }
        \cup { [ZeroTwolOrderConfirmationMessage EXCEPT !.orderNumber1 = one] : one \in Sample(8) }
        \cup { [ZeroTwolOrderConfirmationMessage EXCEPT !.bookType1 = one] : one \in Sample(2) }
        \cup { [ZeroTwolOrderConfirmationMessage EXCEPT !.buySell1 = one] : one \in Sample(2) }
        \cup { [ZeroTwolOrderConfirmationMessage EXCEPT !.totalVolRemaining1 = one] : one \in Sample(4) }
        \cup { [ZeroTwolOrderConfirmationMessage EXCEPT !.volume1 = one] : one \in Sample(4) }
        \cup { [ZeroTwolOrderConfirmationMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroTwolOrderConfirmationMessage EXCEPT !.traderId1 = one] : one \in Sample(4) }
        \cup { [ZeroTwolOrderConfirmationMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroTwolOrderConfirmationMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroTwolOrderConfirmationMessage EXCEPT !.activityTimeInNanos = one] : one \in Sample(8) }
        \cup { [ZeroTwolOrderConfirmationMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroTwolOrderConfirmationMessage EXCEPT !.accountNumber1 = one] : one \in Sample(10) }
        \cup { [ZeroTwolOrderConfirmationMessage EXCEPT !.proClient1 = one] : one \in Sample(1) }
        \cup { [ZeroTwolOrderConfirmationMessage EXCEPT !.segmentChar1 = one] : one \in Sample(1) }
        \cup { [ZeroTwolOrderConfirmationMessage EXCEPT !.openClose1 = one] : one \in Sample(1) }
        \cup { [ZeroTwolOrderConfirmationMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTwolOrderConfirmationMessage EXCEPT !.settlor1 = one] : one \in Sample(12) }
        \cup { [ZeroTwolOrderConfirmationMessage EXCEPT !.priceDiff = one] : one \in Sample(4) }
        \cup { [ZeroTwolOrderConfirmationMessage EXCEPT !.referenceId = one] : one \in Sample(4) }
        \cup { [ZeroTwolOrderConfirmationMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroTwolOrderConfirmationMessage EXCEPT !.msSpdLegInfoLeg2 = one] : one \in CheckedMsSpdLegInfoLeg22 }
        \cup { [ZeroTwolOrderConfirmationMessage EXCEPT !.msSpdLegInfoLeg3 = one] : one \in CheckedMsSpdLegInfoLeg32 }

(***************************************************************************)
(* Ms Spd Leg Info Leg 2: 18 bytes                                         *)
(***************************************************************************)

MsSpdLegInfoLeg23 ==
    [ token2             : Sample(4),
      buySell2           : Sample(2),
      totalVolRemaining2 : Sample(4),
      volume2            : Sample(4),
      stOrderFlags       : Sample(2),
      openClose2         : Sample(1),
      reserved1          : Sample(1) ]

EncodeMsSpdLegInfoLeg23(message) ==
    message.token2
        \o message.buySell2
        \o message.totalVolRemaining2
        \o message.volume2
        \o message.stOrderFlags
        \o message.openClose2
        \o message.reserved1

DecodeMsSpdLegInfoLeg23(bytes) ==
    LET token2 == ReadBytes(bytes, 4) IN IF ~token2.ok THEN Fail ELSE
    LET buySell2 == ReadBytes(token2.rest, 2) IN IF ~buySell2.ok THEN Fail ELSE
    LET totalVolRemaining2 == ReadBytes(buySell2.rest, 4) IN IF ~totalVolRemaining2.ok THEN Fail ELSE
    LET volume2 == ReadBytes(totalVolRemaining2.rest, 4) IN IF ~volume2.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(volume2.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET openClose2 == ReadBytes(stOrderFlags.rest, 1) IN IF ~openClose2.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(openClose2.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ token2             |-> token2.value,
         buySell2           |-> buySell2.value,
         totalVolRemaining2 |-> totalVolRemaining2.value,
         volume2            |-> volume2.value,
         stOrderFlags       |-> stOrderFlags.value,
         openClose2         |-> openClose2.value,
         reserved1          |-> reserved1.value ], reserved1.rest)

ZeroMsSpdLegInfoLeg23 ==
    [ token2             |-> [i \in 1 .. 4 |-> 0],
      buySell2           |-> [i \in 1 .. 2 |-> 0],
      totalVolRemaining2 |-> [i \in 1 .. 4 |-> 0],
      volume2            |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags       |-> [i \in 1 .. 2 |-> 0],
      openClose2         |-> [i \in 1 .. 1 |-> 0],
      reserved1          |-> [i \in 1 .. 1 |-> 0] ]

(* Ms Spd Leg Info Leg 2 at zero, then each field in turn at the values it is checked at *)
CheckedMsSpdLegInfoLeg23 ==
    { ZeroMsSpdLegInfoLeg23 }
        \cup { [ZeroMsSpdLegInfoLeg23 EXCEPT !.token2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg23 EXCEPT !.buySell2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg23 EXCEPT !.totalVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg23 EXCEPT !.volume2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg23 EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg23 EXCEPT !.openClose2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg23 EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Ms Spd Leg Info Leg 3: 18 bytes                                         *)
(***************************************************************************)

MsSpdLegInfoLeg33 ==
    [ token2             : Sample(4),
      buySell2           : Sample(2),
      totalVolRemaining2 : Sample(4),
      volume2            : Sample(4),
      stOrderFlags       : Sample(2),
      openClose2         : Sample(1),
      reserved1          : Sample(1) ]

EncodeMsSpdLegInfoLeg33(message) ==
    message.token2
        \o message.buySell2
        \o message.totalVolRemaining2
        \o message.volume2
        \o message.stOrderFlags
        \o message.openClose2
        \o message.reserved1

DecodeMsSpdLegInfoLeg33(bytes) ==
    LET token2 == ReadBytes(bytes, 4) IN IF ~token2.ok THEN Fail ELSE
    LET buySell2 == ReadBytes(token2.rest, 2) IN IF ~buySell2.ok THEN Fail ELSE
    LET totalVolRemaining2 == ReadBytes(buySell2.rest, 4) IN IF ~totalVolRemaining2.ok THEN Fail ELSE
    LET volume2 == ReadBytes(totalVolRemaining2.rest, 4) IN IF ~volume2.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(volume2.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET openClose2 == ReadBytes(stOrderFlags.rest, 1) IN IF ~openClose2.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(openClose2.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ token2             |-> token2.value,
         buySell2           |-> buySell2.value,
         totalVolRemaining2 |-> totalVolRemaining2.value,
         volume2            |-> volume2.value,
         stOrderFlags       |-> stOrderFlags.value,
         openClose2         |-> openClose2.value,
         reserved1          |-> reserved1.value ], reserved1.rest)

ZeroMsSpdLegInfoLeg33 ==
    [ token2             |-> [i \in 1 .. 4 |-> 0],
      buySell2           |-> [i \in 1 .. 2 |-> 0],
      totalVolRemaining2 |-> [i \in 1 .. 4 |-> 0],
      volume2            |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags       |-> [i \in 1 .. 2 |-> 0],
      openClose2         |-> [i \in 1 .. 1 |-> 0],
      reserved1          |-> [i \in 1 .. 1 |-> 0] ]

(* Ms Spd Leg Info Leg 3 at zero, then each field in turn at the values it is checked at *)
CheckedMsSpdLegInfoLeg33 ==
    { ZeroMsSpdLegInfoLeg33 }
        \cup { [ZeroMsSpdLegInfoLeg33 EXCEPT !.token2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg33 EXCEPT !.buySell2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg33 EXCEPT !.totalVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg33 EXCEPT !.volume2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg33 EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg33 EXCEPT !.openClose2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg33 EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Thrl Order Confirmation Message: 132 bytes                              *)
(***************************************************************************)

ThrlOrderConfirmationMessage ==
    [ token1              : Sample(4),
      orderNumber1        : Sample(8),
      bookType1           : Sample(2),
      buySell1            : Sample(2),
      totalVolRemaining1  : Sample(4),
      volume1             : Sample(4),
      stOrderFlags        : Sample(2),
      traderId1           : Sample(4),
      nnfField            : Sample(8),
      algoId              : Sample(4),
      activityTimeInNanos : Sample(8),
      pan                 : Sample(10),
      accountNumber1      : Sample(10),
      proClient1          : Sample(1),
      segmentChar1        : Sample(1),
      openClose1          : Sample(1),
      reserved1           : Sample(1),
      settlor1            : Sample(12),
      priceDiff           : Sample(4),
      referenceId         : Sample(4),
      reasonCode          : Sample(2),
      msSpdLegInfoLeg2    : MsSpdLegInfoLeg23,
      msSpdLegInfoLeg3    : MsSpdLegInfoLeg33 ]

EncodeThrlOrderConfirmationMessage(message) ==
    message.token1
        \o message.orderNumber1
        \o message.bookType1
        \o message.buySell1
        \o message.totalVolRemaining1
        \o message.volume1
        \o message.stOrderFlags
        \o message.traderId1
        \o message.nnfField
        \o message.algoId
        \o message.activityTimeInNanos
        \o message.pan
        \o message.accountNumber1
        \o message.proClient1
        \o message.segmentChar1
        \o message.openClose1
        \o message.reserved1
        \o message.settlor1
        \o message.priceDiff
        \o message.referenceId
        \o message.reasonCode
        \o EncodeMsSpdLegInfoLeg23(message.msSpdLegInfoLeg2)
        \o EncodeMsSpdLegInfoLeg33(message.msSpdLegInfoLeg3)

DecodeThrlOrderConfirmationMessage(bytes) ==
    LET token1 == ReadBytes(bytes, 4) IN IF ~token1.ok THEN Fail ELSE
    LET orderNumber1 == ReadBytes(token1.rest, 8) IN IF ~orderNumber1.ok THEN Fail ELSE
    LET bookType1 == ReadBytes(orderNumber1.rest, 2) IN IF ~bookType1.ok THEN Fail ELSE
    LET buySell1 == ReadBytes(bookType1.rest, 2) IN IF ~buySell1.ok THEN Fail ELSE
    LET totalVolRemaining1 == ReadBytes(buySell1.rest, 4) IN IF ~totalVolRemaining1.ok THEN Fail ELSE
    LET volume1 == ReadBytes(totalVolRemaining1.rest, 4) IN IF ~volume1.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(volume1.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET traderId1 == ReadBytes(stOrderFlags.rest, 4) IN IF ~traderId1.ok THEN Fail ELSE
    LET nnfField == ReadBytes(traderId1.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET algoId == ReadBytes(nnfField.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET activityTimeInNanos == ReadBytes(algoId.rest, 8) IN IF ~activityTimeInNanos.ok THEN Fail ELSE
    LET pan == ReadBytes(activityTimeInNanos.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET accountNumber1 == ReadBytes(pan.rest, 10) IN IF ~accountNumber1.ok THEN Fail ELSE
    LET proClient1 == ReadBytes(accountNumber1.rest, 1) IN IF ~proClient1.ok THEN Fail ELSE
    LET segmentChar1 == ReadBytes(proClient1.rest, 1) IN IF ~segmentChar1.ok THEN Fail ELSE
    LET openClose1 == ReadBytes(segmentChar1.rest, 1) IN IF ~openClose1.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(openClose1.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET settlor1 == ReadBytes(reserved1.rest, 12) IN IF ~settlor1.ok THEN Fail ELSE
    LET priceDiff == ReadBytes(settlor1.rest, 4) IN IF ~priceDiff.ok THEN Fail ELSE
    LET referenceId == ReadBytes(priceDiff.rest, 4) IN IF ~referenceId.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(referenceId.rest, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET msSpdLegInfoLeg2 == DecodeMsSpdLegInfoLeg23(reasonCode.rest) IN IF ~msSpdLegInfoLeg2.ok THEN Fail ELSE
    LET msSpdLegInfoLeg3 == DecodeMsSpdLegInfoLeg33(msSpdLegInfoLeg2.rest) IN IF ~msSpdLegInfoLeg3.ok THEN Fail ELSE
    Ok([ token1              |-> token1.value,
         orderNumber1        |-> orderNumber1.value,
         bookType1           |-> bookType1.value,
         buySell1            |-> buySell1.value,
         totalVolRemaining1  |-> totalVolRemaining1.value,
         volume1             |-> volume1.value,
         stOrderFlags        |-> stOrderFlags.value,
         traderId1           |-> traderId1.value,
         nnfField            |-> nnfField.value,
         algoId              |-> algoId.value,
         activityTimeInNanos |-> activityTimeInNanos.value,
         pan                 |-> pan.value,
         accountNumber1      |-> accountNumber1.value,
         proClient1          |-> proClient1.value,
         segmentChar1        |-> segmentChar1.value,
         openClose1          |-> openClose1.value,
         reserved1           |-> reserved1.value,
         settlor1            |-> settlor1.value,
         priceDiff           |-> priceDiff.value,
         referenceId         |-> referenceId.value,
         reasonCode          |-> reasonCode.value,
         msSpdLegInfoLeg2    |-> msSpdLegInfoLeg2.value,
         msSpdLegInfoLeg3    |-> msSpdLegInfoLeg3.value ], msSpdLegInfoLeg3.rest)

ZeroThrlOrderConfirmationMessage ==
    [ token1              |-> [i \in 1 .. 4 |-> 0],
      orderNumber1        |-> [i \in 1 .. 8 |-> 0],
      bookType1           |-> [i \in 1 .. 2 |-> 0],
      buySell1            |-> [i \in 1 .. 2 |-> 0],
      totalVolRemaining1  |-> [i \in 1 .. 4 |-> 0],
      volume1             |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags        |-> [i \in 1 .. 2 |-> 0],
      traderId1           |-> [i \in 1 .. 4 |-> 0],
      nnfField            |-> [i \in 1 .. 8 |-> 0],
      algoId              |-> [i \in 1 .. 4 |-> 0],
      activityTimeInNanos |-> [i \in 1 .. 8 |-> 0],
      pan                 |-> [i \in 1 .. 10 |-> 0],
      accountNumber1      |-> [i \in 1 .. 10 |-> 0],
      proClient1          |-> [i \in 1 .. 1 |-> 0],
      segmentChar1        |-> [i \in 1 .. 1 |-> 0],
      openClose1          |-> [i \in 1 .. 1 |-> 0],
      reserved1           |-> [i \in 1 .. 1 |-> 0],
      settlor1            |-> [i \in 1 .. 12 |-> 0],
      priceDiff           |-> [i \in 1 .. 4 |-> 0],
      referenceId         |-> [i \in 1 .. 4 |-> 0],
      reasonCode          |-> [i \in 1 .. 2 |-> 0],
      msSpdLegInfoLeg2    |-> ZeroMsSpdLegInfoLeg23,
      msSpdLegInfoLeg3    |-> ZeroMsSpdLegInfoLeg33 ]

(* Thrl Order Confirmation Message at zero, then each field in turn at the values it is checked at *)
CheckedThrlOrderConfirmationMessage ==
    { ZeroThrlOrderConfirmationMessage }
        \cup { [ZeroThrlOrderConfirmationMessage EXCEPT !.token1 = one] : one \in Sample(4) }
        \cup { [ZeroThrlOrderConfirmationMessage EXCEPT !.orderNumber1 = one] : one \in Sample(8) }
        \cup { [ZeroThrlOrderConfirmationMessage EXCEPT !.bookType1 = one] : one \in Sample(2) }
        \cup { [ZeroThrlOrderConfirmationMessage EXCEPT !.buySell1 = one] : one \in Sample(2) }
        \cup { [ZeroThrlOrderConfirmationMessage EXCEPT !.totalVolRemaining1 = one] : one \in Sample(4) }
        \cup { [ZeroThrlOrderConfirmationMessage EXCEPT !.volume1 = one] : one \in Sample(4) }
        \cup { [ZeroThrlOrderConfirmationMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroThrlOrderConfirmationMessage EXCEPT !.traderId1 = one] : one \in Sample(4) }
        \cup { [ZeroThrlOrderConfirmationMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroThrlOrderConfirmationMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroThrlOrderConfirmationMessage EXCEPT !.activityTimeInNanos = one] : one \in Sample(8) }
        \cup { [ZeroThrlOrderConfirmationMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroThrlOrderConfirmationMessage EXCEPT !.accountNumber1 = one] : one \in Sample(10) }
        \cup { [ZeroThrlOrderConfirmationMessage EXCEPT !.proClient1 = one] : one \in Sample(1) }
        \cup { [ZeroThrlOrderConfirmationMessage EXCEPT !.segmentChar1 = one] : one \in Sample(1) }
        \cup { [ZeroThrlOrderConfirmationMessage EXCEPT !.openClose1 = one] : one \in Sample(1) }
        \cup { [ZeroThrlOrderConfirmationMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroThrlOrderConfirmationMessage EXCEPT !.settlor1 = one] : one \in Sample(12) }
        \cup { [ZeroThrlOrderConfirmationMessage EXCEPT !.priceDiff = one] : one \in Sample(4) }
        \cup { [ZeroThrlOrderConfirmationMessage EXCEPT !.referenceId = one] : one \in Sample(4) }
        \cup { [ZeroThrlOrderConfirmationMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroThrlOrderConfirmationMessage EXCEPT !.msSpdLegInfoLeg2 = one] : one \in CheckedMsSpdLegInfoLeg23 }
        \cup { [ZeroThrlOrderConfirmationMessage EXCEPT !.msSpdLegInfoLeg3 = one] : one \in CheckedMsSpdLegInfoLeg33 }

(***************************************************************************)
(* Ms Spd Leg Info Leg 2: 18 bytes                                         *)
(***************************************************************************)

MsSpdLegInfoLeg24 ==
    [ token2             : Sample(4),
      buySell2           : Sample(2),
      totalVolRemaining2 : Sample(4),
      volume2            : Sample(4),
      stOrderFlags       : Sample(2),
      openClose2         : Sample(1),
      reserved1          : Sample(1) ]

EncodeMsSpdLegInfoLeg24(message) ==
    message.token2
        \o message.buySell2
        \o message.totalVolRemaining2
        \o message.volume2
        \o message.stOrderFlags
        \o message.openClose2
        \o message.reserved1

DecodeMsSpdLegInfoLeg24(bytes) ==
    LET token2 == ReadBytes(bytes, 4) IN IF ~token2.ok THEN Fail ELSE
    LET buySell2 == ReadBytes(token2.rest, 2) IN IF ~buySell2.ok THEN Fail ELSE
    LET totalVolRemaining2 == ReadBytes(buySell2.rest, 4) IN IF ~totalVolRemaining2.ok THEN Fail ELSE
    LET volume2 == ReadBytes(totalVolRemaining2.rest, 4) IN IF ~volume2.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(volume2.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET openClose2 == ReadBytes(stOrderFlags.rest, 1) IN IF ~openClose2.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(openClose2.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ token2             |-> token2.value,
         buySell2           |-> buySell2.value,
         totalVolRemaining2 |-> totalVolRemaining2.value,
         volume2            |-> volume2.value,
         stOrderFlags       |-> stOrderFlags.value,
         openClose2         |-> openClose2.value,
         reserved1          |-> reserved1.value ], reserved1.rest)

ZeroMsSpdLegInfoLeg24 ==
    [ token2             |-> [i \in 1 .. 4 |-> 0],
      buySell2           |-> [i \in 1 .. 2 |-> 0],
      totalVolRemaining2 |-> [i \in 1 .. 4 |-> 0],
      volume2            |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags       |-> [i \in 1 .. 2 |-> 0],
      openClose2         |-> [i \in 1 .. 1 |-> 0],
      reserved1          |-> [i \in 1 .. 1 |-> 0] ]

(* Ms Spd Leg Info Leg 2 at zero, then each field in turn at the values it is checked at *)
CheckedMsSpdLegInfoLeg24 ==
    { ZeroMsSpdLegInfoLeg24 }
        \cup { [ZeroMsSpdLegInfoLeg24 EXCEPT !.token2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg24 EXCEPT !.buySell2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg24 EXCEPT !.totalVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg24 EXCEPT !.volume2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg24 EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg24 EXCEPT !.openClose2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg24 EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Ms Spd Leg Info Leg 3: 18 bytes                                         *)
(***************************************************************************)

MsSpdLegInfoLeg34 ==
    [ token2             : Sample(4),
      buySell2           : Sample(2),
      totalVolRemaining2 : Sample(4),
      volume2            : Sample(4),
      stOrderFlags       : Sample(2),
      openClose2         : Sample(1),
      reserved1          : Sample(1) ]

EncodeMsSpdLegInfoLeg34(message) ==
    message.token2
        \o message.buySell2
        \o message.totalVolRemaining2
        \o message.volume2
        \o message.stOrderFlags
        \o message.openClose2
        \o message.reserved1

DecodeMsSpdLegInfoLeg34(bytes) ==
    LET token2 == ReadBytes(bytes, 4) IN IF ~token2.ok THEN Fail ELSE
    LET buySell2 == ReadBytes(token2.rest, 2) IN IF ~buySell2.ok THEN Fail ELSE
    LET totalVolRemaining2 == ReadBytes(buySell2.rest, 4) IN IF ~totalVolRemaining2.ok THEN Fail ELSE
    LET volume2 == ReadBytes(totalVolRemaining2.rest, 4) IN IF ~volume2.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(volume2.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET openClose2 == ReadBytes(stOrderFlags.rest, 1) IN IF ~openClose2.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(openClose2.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ token2             |-> token2.value,
         buySell2           |-> buySell2.value,
         totalVolRemaining2 |-> totalVolRemaining2.value,
         volume2            |-> volume2.value,
         stOrderFlags       |-> stOrderFlags.value,
         openClose2         |-> openClose2.value,
         reserved1          |-> reserved1.value ], reserved1.rest)

ZeroMsSpdLegInfoLeg34 ==
    [ token2             |-> [i \in 1 .. 4 |-> 0],
      buySell2           |-> [i \in 1 .. 2 |-> 0],
      totalVolRemaining2 |-> [i \in 1 .. 4 |-> 0],
      volume2            |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags       |-> [i \in 1 .. 2 |-> 0],
      openClose2         |-> [i \in 1 .. 1 |-> 0],
      reserved1          |-> [i \in 1 .. 1 |-> 0] ]

(* Ms Spd Leg Info Leg 3 at zero, then each field in turn at the values it is checked at *)
CheckedMsSpdLegInfoLeg34 ==
    { ZeroMsSpdLegInfoLeg34 }
        \cup { [ZeroMsSpdLegInfoLeg34 EXCEPT !.token2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg34 EXCEPT !.buySell2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg34 EXCEPT !.totalVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg34 EXCEPT !.volume2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg34 EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg34 EXCEPT !.openClose2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg34 EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Sp Order Cxl Rejected Message: 132 bytes                                *)
(***************************************************************************)

SpOrderCxlRejectedMessage ==
    [ token1              : Sample(4),
      orderNumber1        : Sample(8),
      bookType1           : Sample(2),
      buySell1            : Sample(2),
      totalVolRemaining1  : Sample(4),
      volume1             : Sample(4),
      stOrderFlags        : Sample(2),
      traderId1           : Sample(4),
      nnfField            : Sample(8),
      algoId              : Sample(4),
      activityTimeInNanos : Sample(8),
      pan                 : Sample(10),
      accountNumber1      : Sample(10),
      proClient1          : Sample(1),
      segmentChar1        : Sample(1),
      openClose1          : Sample(1),
      reserved1           : Sample(1),
      settlor1            : Sample(12),
      priceDiff           : Sample(4),
      referenceId         : Sample(4),
      reasonCode          : Sample(2),
      msSpdLegInfoLeg2    : MsSpdLegInfoLeg24,
      msSpdLegInfoLeg3    : MsSpdLegInfoLeg34 ]

EncodeSpOrderCxlRejectedMessage(message) ==
    message.token1
        \o message.orderNumber1
        \o message.bookType1
        \o message.buySell1
        \o message.totalVolRemaining1
        \o message.volume1
        \o message.stOrderFlags
        \o message.traderId1
        \o message.nnfField
        \o message.algoId
        \o message.activityTimeInNanos
        \o message.pan
        \o message.accountNumber1
        \o message.proClient1
        \o message.segmentChar1
        \o message.openClose1
        \o message.reserved1
        \o message.settlor1
        \o message.priceDiff
        \o message.referenceId
        \o message.reasonCode
        \o EncodeMsSpdLegInfoLeg24(message.msSpdLegInfoLeg2)
        \o EncodeMsSpdLegInfoLeg34(message.msSpdLegInfoLeg3)

DecodeSpOrderCxlRejectedMessage(bytes) ==
    LET token1 == ReadBytes(bytes, 4) IN IF ~token1.ok THEN Fail ELSE
    LET orderNumber1 == ReadBytes(token1.rest, 8) IN IF ~orderNumber1.ok THEN Fail ELSE
    LET bookType1 == ReadBytes(orderNumber1.rest, 2) IN IF ~bookType1.ok THEN Fail ELSE
    LET buySell1 == ReadBytes(bookType1.rest, 2) IN IF ~buySell1.ok THEN Fail ELSE
    LET totalVolRemaining1 == ReadBytes(buySell1.rest, 4) IN IF ~totalVolRemaining1.ok THEN Fail ELSE
    LET volume1 == ReadBytes(totalVolRemaining1.rest, 4) IN IF ~volume1.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(volume1.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET traderId1 == ReadBytes(stOrderFlags.rest, 4) IN IF ~traderId1.ok THEN Fail ELSE
    LET nnfField == ReadBytes(traderId1.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET algoId == ReadBytes(nnfField.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET activityTimeInNanos == ReadBytes(algoId.rest, 8) IN IF ~activityTimeInNanos.ok THEN Fail ELSE
    LET pan == ReadBytes(activityTimeInNanos.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET accountNumber1 == ReadBytes(pan.rest, 10) IN IF ~accountNumber1.ok THEN Fail ELSE
    LET proClient1 == ReadBytes(accountNumber1.rest, 1) IN IF ~proClient1.ok THEN Fail ELSE
    LET segmentChar1 == ReadBytes(proClient1.rest, 1) IN IF ~segmentChar1.ok THEN Fail ELSE
    LET openClose1 == ReadBytes(segmentChar1.rest, 1) IN IF ~openClose1.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(openClose1.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET settlor1 == ReadBytes(reserved1.rest, 12) IN IF ~settlor1.ok THEN Fail ELSE
    LET priceDiff == ReadBytes(settlor1.rest, 4) IN IF ~priceDiff.ok THEN Fail ELSE
    LET referenceId == ReadBytes(priceDiff.rest, 4) IN IF ~referenceId.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(referenceId.rest, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET msSpdLegInfoLeg2 == DecodeMsSpdLegInfoLeg24(reasonCode.rest) IN IF ~msSpdLegInfoLeg2.ok THEN Fail ELSE
    LET msSpdLegInfoLeg3 == DecodeMsSpdLegInfoLeg34(msSpdLegInfoLeg2.rest) IN IF ~msSpdLegInfoLeg3.ok THEN Fail ELSE
    Ok([ token1              |-> token1.value,
         orderNumber1        |-> orderNumber1.value,
         bookType1           |-> bookType1.value,
         buySell1            |-> buySell1.value,
         totalVolRemaining1  |-> totalVolRemaining1.value,
         volume1             |-> volume1.value,
         stOrderFlags        |-> stOrderFlags.value,
         traderId1           |-> traderId1.value,
         nnfField            |-> nnfField.value,
         algoId              |-> algoId.value,
         activityTimeInNanos |-> activityTimeInNanos.value,
         pan                 |-> pan.value,
         accountNumber1      |-> accountNumber1.value,
         proClient1          |-> proClient1.value,
         segmentChar1        |-> segmentChar1.value,
         openClose1          |-> openClose1.value,
         reserved1           |-> reserved1.value,
         settlor1            |-> settlor1.value,
         priceDiff           |-> priceDiff.value,
         referenceId         |-> referenceId.value,
         reasonCode          |-> reasonCode.value,
         msSpdLegInfoLeg2    |-> msSpdLegInfoLeg2.value,
         msSpdLegInfoLeg3    |-> msSpdLegInfoLeg3.value ], msSpdLegInfoLeg3.rest)

ZeroSpOrderCxlRejectedMessage ==
    [ token1              |-> [i \in 1 .. 4 |-> 0],
      orderNumber1        |-> [i \in 1 .. 8 |-> 0],
      bookType1           |-> [i \in 1 .. 2 |-> 0],
      buySell1            |-> [i \in 1 .. 2 |-> 0],
      totalVolRemaining1  |-> [i \in 1 .. 4 |-> 0],
      volume1             |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags        |-> [i \in 1 .. 2 |-> 0],
      traderId1           |-> [i \in 1 .. 4 |-> 0],
      nnfField            |-> [i \in 1 .. 8 |-> 0],
      algoId              |-> [i \in 1 .. 4 |-> 0],
      activityTimeInNanos |-> [i \in 1 .. 8 |-> 0],
      pan                 |-> [i \in 1 .. 10 |-> 0],
      accountNumber1      |-> [i \in 1 .. 10 |-> 0],
      proClient1          |-> [i \in 1 .. 1 |-> 0],
      segmentChar1        |-> [i \in 1 .. 1 |-> 0],
      openClose1          |-> [i \in 1 .. 1 |-> 0],
      reserved1           |-> [i \in 1 .. 1 |-> 0],
      settlor1            |-> [i \in 1 .. 12 |-> 0],
      priceDiff           |-> [i \in 1 .. 4 |-> 0],
      referenceId         |-> [i \in 1 .. 4 |-> 0],
      reasonCode          |-> [i \in 1 .. 2 |-> 0],
      msSpdLegInfoLeg2    |-> ZeroMsSpdLegInfoLeg24,
      msSpdLegInfoLeg3    |-> ZeroMsSpdLegInfoLeg34 ]

(* Sp Order Cxl Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedSpOrderCxlRejectedMessage ==
    { ZeroSpOrderCxlRejectedMessage }
        \cup { [ZeroSpOrderCxlRejectedMessage EXCEPT !.token1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderCxlRejectedMessage EXCEPT !.orderNumber1 = one] : one \in Sample(8) }
        \cup { [ZeroSpOrderCxlRejectedMessage EXCEPT !.bookType1 = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderCxlRejectedMessage EXCEPT !.buySell1 = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderCxlRejectedMessage EXCEPT !.totalVolRemaining1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderCxlRejectedMessage EXCEPT !.volume1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderCxlRejectedMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderCxlRejectedMessage EXCEPT !.traderId1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderCxlRejectedMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroSpOrderCxlRejectedMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderCxlRejectedMessage EXCEPT !.activityTimeInNanos = one] : one \in Sample(8) }
        \cup { [ZeroSpOrderCxlRejectedMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroSpOrderCxlRejectedMessage EXCEPT !.accountNumber1 = one] : one \in Sample(10) }
        \cup { [ZeroSpOrderCxlRejectedMessage EXCEPT !.proClient1 = one] : one \in Sample(1) }
        \cup { [ZeroSpOrderCxlRejectedMessage EXCEPT !.segmentChar1 = one] : one \in Sample(1) }
        \cup { [ZeroSpOrderCxlRejectedMessage EXCEPT !.openClose1 = one] : one \in Sample(1) }
        \cup { [ZeroSpOrderCxlRejectedMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroSpOrderCxlRejectedMessage EXCEPT !.settlor1 = one] : one \in Sample(12) }
        \cup { [ZeroSpOrderCxlRejectedMessage EXCEPT !.priceDiff = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderCxlRejectedMessage EXCEPT !.referenceId = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderCxlRejectedMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderCxlRejectedMessage EXCEPT !.msSpdLegInfoLeg2 = one] : one \in CheckedMsSpdLegInfoLeg24 }
        \cup { [ZeroSpOrderCxlRejectedMessage EXCEPT !.msSpdLegInfoLeg3 = one] : one \in CheckedMsSpdLegInfoLeg34 }

(***************************************************************************)
(* Ms Spd Leg Info Leg 2: 18 bytes                                         *)
(***************************************************************************)

MsSpdLegInfoLeg25 ==
    [ token2             : Sample(4),
      buySell2           : Sample(2),
      totalVolRemaining2 : Sample(4),
      volume2            : Sample(4),
      stOrderFlags       : Sample(2),
      openClose2         : Sample(1),
      reserved1          : Sample(1) ]

EncodeMsSpdLegInfoLeg25(message) ==
    message.token2
        \o message.buySell2
        \o message.totalVolRemaining2
        \o message.volume2
        \o message.stOrderFlags
        \o message.openClose2
        \o message.reserved1

DecodeMsSpdLegInfoLeg25(bytes) ==
    LET token2 == ReadBytes(bytes, 4) IN IF ~token2.ok THEN Fail ELSE
    LET buySell2 == ReadBytes(token2.rest, 2) IN IF ~buySell2.ok THEN Fail ELSE
    LET totalVolRemaining2 == ReadBytes(buySell2.rest, 4) IN IF ~totalVolRemaining2.ok THEN Fail ELSE
    LET volume2 == ReadBytes(totalVolRemaining2.rest, 4) IN IF ~volume2.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(volume2.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET openClose2 == ReadBytes(stOrderFlags.rest, 1) IN IF ~openClose2.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(openClose2.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ token2             |-> token2.value,
         buySell2           |-> buySell2.value,
         totalVolRemaining2 |-> totalVolRemaining2.value,
         volume2            |-> volume2.value,
         stOrderFlags       |-> stOrderFlags.value,
         openClose2         |-> openClose2.value,
         reserved1          |-> reserved1.value ], reserved1.rest)

ZeroMsSpdLegInfoLeg25 ==
    [ token2             |-> [i \in 1 .. 4 |-> 0],
      buySell2           |-> [i \in 1 .. 2 |-> 0],
      totalVolRemaining2 |-> [i \in 1 .. 4 |-> 0],
      volume2            |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags       |-> [i \in 1 .. 2 |-> 0],
      openClose2         |-> [i \in 1 .. 1 |-> 0],
      reserved1          |-> [i \in 1 .. 1 |-> 0] ]

(* Ms Spd Leg Info Leg 2 at zero, then each field in turn at the values it is checked at *)
CheckedMsSpdLegInfoLeg25 ==
    { ZeroMsSpdLegInfoLeg25 }
        \cup { [ZeroMsSpdLegInfoLeg25 EXCEPT !.token2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg25 EXCEPT !.buySell2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg25 EXCEPT !.totalVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg25 EXCEPT !.volume2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg25 EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg25 EXCEPT !.openClose2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg25 EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Ms Spd Leg Info Leg 3: 18 bytes                                         *)
(***************************************************************************)

MsSpdLegInfoLeg35 ==
    [ token2             : Sample(4),
      buySell2           : Sample(2),
      totalVolRemaining2 : Sample(4),
      volume2            : Sample(4),
      stOrderFlags       : Sample(2),
      openClose2         : Sample(1),
      reserved1          : Sample(1) ]

EncodeMsSpdLegInfoLeg35(message) ==
    message.token2
        \o message.buySell2
        \o message.totalVolRemaining2
        \o message.volume2
        \o message.stOrderFlags
        \o message.openClose2
        \o message.reserved1

DecodeMsSpdLegInfoLeg35(bytes) ==
    LET token2 == ReadBytes(bytes, 4) IN IF ~token2.ok THEN Fail ELSE
    LET buySell2 == ReadBytes(token2.rest, 2) IN IF ~buySell2.ok THEN Fail ELSE
    LET totalVolRemaining2 == ReadBytes(buySell2.rest, 4) IN IF ~totalVolRemaining2.ok THEN Fail ELSE
    LET volume2 == ReadBytes(totalVolRemaining2.rest, 4) IN IF ~volume2.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(volume2.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET openClose2 == ReadBytes(stOrderFlags.rest, 1) IN IF ~openClose2.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(openClose2.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ token2             |-> token2.value,
         buySell2           |-> buySell2.value,
         totalVolRemaining2 |-> totalVolRemaining2.value,
         volume2            |-> volume2.value,
         stOrderFlags       |-> stOrderFlags.value,
         openClose2         |-> openClose2.value,
         reserved1          |-> reserved1.value ], reserved1.rest)

ZeroMsSpdLegInfoLeg35 ==
    [ token2             |-> [i \in 1 .. 4 |-> 0],
      buySell2           |-> [i \in 1 .. 2 |-> 0],
      totalVolRemaining2 |-> [i \in 1 .. 4 |-> 0],
      volume2            |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags       |-> [i \in 1 .. 2 |-> 0],
      openClose2         |-> [i \in 1 .. 1 |-> 0],
      reserved1          |-> [i \in 1 .. 1 |-> 0] ]

(* Ms Spd Leg Info Leg 3 at zero, then each field in turn at the values it is checked at *)
CheckedMsSpdLegInfoLeg35 ==
    { ZeroMsSpdLegInfoLeg35 }
        \cup { [ZeroMsSpdLegInfoLeg35 EXCEPT !.token2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg35 EXCEPT !.buySell2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg35 EXCEPT !.totalVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg35 EXCEPT !.volume2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg35 EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg35 EXCEPT !.openClose2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg35 EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Sp Order Cxl Confirmation Message: 132 bytes                            *)
(***************************************************************************)

SpOrderCxlConfirmationMessage ==
    [ token1              : Sample(4),
      orderNumber1        : Sample(8),
      bookType1           : Sample(2),
      buySell1            : Sample(2),
      totalVolRemaining1  : Sample(4),
      volume1             : Sample(4),
      stOrderFlags        : Sample(2),
      traderId1           : Sample(4),
      nnfField            : Sample(8),
      algoId              : Sample(4),
      activityTimeInNanos : Sample(8),
      pan                 : Sample(10),
      accountNumber1      : Sample(10),
      proClient1          : Sample(1),
      segmentChar1        : Sample(1),
      openClose1          : Sample(1),
      reserved1           : Sample(1),
      settlor1            : Sample(12),
      priceDiff           : Sample(4),
      referenceId         : Sample(4),
      reasonCode          : Sample(2),
      msSpdLegInfoLeg2    : MsSpdLegInfoLeg25,
      msSpdLegInfoLeg3    : MsSpdLegInfoLeg35 ]

EncodeSpOrderCxlConfirmationMessage(message) ==
    message.token1
        \o message.orderNumber1
        \o message.bookType1
        \o message.buySell1
        \o message.totalVolRemaining1
        \o message.volume1
        \o message.stOrderFlags
        \o message.traderId1
        \o message.nnfField
        \o message.algoId
        \o message.activityTimeInNanos
        \o message.pan
        \o message.accountNumber1
        \o message.proClient1
        \o message.segmentChar1
        \o message.openClose1
        \o message.reserved1
        \o message.settlor1
        \o message.priceDiff
        \o message.referenceId
        \o message.reasonCode
        \o EncodeMsSpdLegInfoLeg25(message.msSpdLegInfoLeg2)
        \o EncodeMsSpdLegInfoLeg35(message.msSpdLegInfoLeg3)

DecodeSpOrderCxlConfirmationMessage(bytes) ==
    LET token1 == ReadBytes(bytes, 4) IN IF ~token1.ok THEN Fail ELSE
    LET orderNumber1 == ReadBytes(token1.rest, 8) IN IF ~orderNumber1.ok THEN Fail ELSE
    LET bookType1 == ReadBytes(orderNumber1.rest, 2) IN IF ~bookType1.ok THEN Fail ELSE
    LET buySell1 == ReadBytes(bookType1.rest, 2) IN IF ~buySell1.ok THEN Fail ELSE
    LET totalVolRemaining1 == ReadBytes(buySell1.rest, 4) IN IF ~totalVolRemaining1.ok THEN Fail ELSE
    LET volume1 == ReadBytes(totalVolRemaining1.rest, 4) IN IF ~volume1.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(volume1.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET traderId1 == ReadBytes(stOrderFlags.rest, 4) IN IF ~traderId1.ok THEN Fail ELSE
    LET nnfField == ReadBytes(traderId1.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET algoId == ReadBytes(nnfField.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET activityTimeInNanos == ReadBytes(algoId.rest, 8) IN IF ~activityTimeInNanos.ok THEN Fail ELSE
    LET pan == ReadBytes(activityTimeInNanos.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET accountNumber1 == ReadBytes(pan.rest, 10) IN IF ~accountNumber1.ok THEN Fail ELSE
    LET proClient1 == ReadBytes(accountNumber1.rest, 1) IN IF ~proClient1.ok THEN Fail ELSE
    LET segmentChar1 == ReadBytes(proClient1.rest, 1) IN IF ~segmentChar1.ok THEN Fail ELSE
    LET openClose1 == ReadBytes(segmentChar1.rest, 1) IN IF ~openClose1.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(openClose1.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET settlor1 == ReadBytes(reserved1.rest, 12) IN IF ~settlor1.ok THEN Fail ELSE
    LET priceDiff == ReadBytes(settlor1.rest, 4) IN IF ~priceDiff.ok THEN Fail ELSE
    LET referenceId == ReadBytes(priceDiff.rest, 4) IN IF ~referenceId.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(referenceId.rest, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET msSpdLegInfoLeg2 == DecodeMsSpdLegInfoLeg25(reasonCode.rest) IN IF ~msSpdLegInfoLeg2.ok THEN Fail ELSE
    LET msSpdLegInfoLeg3 == DecodeMsSpdLegInfoLeg35(msSpdLegInfoLeg2.rest) IN IF ~msSpdLegInfoLeg3.ok THEN Fail ELSE
    Ok([ token1              |-> token1.value,
         orderNumber1        |-> orderNumber1.value,
         bookType1           |-> bookType1.value,
         buySell1            |-> buySell1.value,
         totalVolRemaining1  |-> totalVolRemaining1.value,
         volume1             |-> volume1.value,
         stOrderFlags        |-> stOrderFlags.value,
         traderId1           |-> traderId1.value,
         nnfField            |-> nnfField.value,
         algoId              |-> algoId.value,
         activityTimeInNanos |-> activityTimeInNanos.value,
         pan                 |-> pan.value,
         accountNumber1      |-> accountNumber1.value,
         proClient1          |-> proClient1.value,
         segmentChar1        |-> segmentChar1.value,
         openClose1          |-> openClose1.value,
         reserved1           |-> reserved1.value,
         settlor1            |-> settlor1.value,
         priceDiff           |-> priceDiff.value,
         referenceId         |-> referenceId.value,
         reasonCode          |-> reasonCode.value,
         msSpdLegInfoLeg2    |-> msSpdLegInfoLeg2.value,
         msSpdLegInfoLeg3    |-> msSpdLegInfoLeg3.value ], msSpdLegInfoLeg3.rest)

ZeroSpOrderCxlConfirmationMessage ==
    [ token1              |-> [i \in 1 .. 4 |-> 0],
      orderNumber1        |-> [i \in 1 .. 8 |-> 0],
      bookType1           |-> [i \in 1 .. 2 |-> 0],
      buySell1            |-> [i \in 1 .. 2 |-> 0],
      totalVolRemaining1  |-> [i \in 1 .. 4 |-> 0],
      volume1             |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags        |-> [i \in 1 .. 2 |-> 0],
      traderId1           |-> [i \in 1 .. 4 |-> 0],
      nnfField            |-> [i \in 1 .. 8 |-> 0],
      algoId              |-> [i \in 1 .. 4 |-> 0],
      activityTimeInNanos |-> [i \in 1 .. 8 |-> 0],
      pan                 |-> [i \in 1 .. 10 |-> 0],
      accountNumber1      |-> [i \in 1 .. 10 |-> 0],
      proClient1          |-> [i \in 1 .. 1 |-> 0],
      segmentChar1        |-> [i \in 1 .. 1 |-> 0],
      openClose1          |-> [i \in 1 .. 1 |-> 0],
      reserved1           |-> [i \in 1 .. 1 |-> 0],
      settlor1            |-> [i \in 1 .. 12 |-> 0],
      priceDiff           |-> [i \in 1 .. 4 |-> 0],
      referenceId         |-> [i \in 1 .. 4 |-> 0],
      reasonCode          |-> [i \in 1 .. 2 |-> 0],
      msSpdLegInfoLeg2    |-> ZeroMsSpdLegInfoLeg25,
      msSpdLegInfoLeg3    |-> ZeroMsSpdLegInfoLeg35 ]

(* Sp Order Cxl Confirmation Message at zero, then each field in turn at the values it is checked at *)
CheckedSpOrderCxlConfirmationMessage ==
    { ZeroSpOrderCxlConfirmationMessage }
        \cup { [ZeroSpOrderCxlConfirmationMessage EXCEPT !.token1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderCxlConfirmationMessage EXCEPT !.orderNumber1 = one] : one \in Sample(8) }
        \cup { [ZeroSpOrderCxlConfirmationMessage EXCEPT !.bookType1 = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderCxlConfirmationMessage EXCEPT !.buySell1 = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderCxlConfirmationMessage EXCEPT !.totalVolRemaining1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderCxlConfirmationMessage EXCEPT !.volume1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderCxlConfirmationMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderCxlConfirmationMessage EXCEPT !.traderId1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderCxlConfirmationMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroSpOrderCxlConfirmationMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderCxlConfirmationMessage EXCEPT !.activityTimeInNanos = one] : one \in Sample(8) }
        \cup { [ZeroSpOrderCxlConfirmationMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroSpOrderCxlConfirmationMessage EXCEPT !.accountNumber1 = one] : one \in Sample(10) }
        \cup { [ZeroSpOrderCxlConfirmationMessage EXCEPT !.proClient1 = one] : one \in Sample(1) }
        \cup { [ZeroSpOrderCxlConfirmationMessage EXCEPT !.segmentChar1 = one] : one \in Sample(1) }
        \cup { [ZeroSpOrderCxlConfirmationMessage EXCEPT !.openClose1 = one] : one \in Sample(1) }
        \cup { [ZeroSpOrderCxlConfirmationMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroSpOrderCxlConfirmationMessage EXCEPT !.settlor1 = one] : one \in Sample(12) }
        \cup { [ZeroSpOrderCxlConfirmationMessage EXCEPT !.priceDiff = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderCxlConfirmationMessage EXCEPT !.referenceId = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderCxlConfirmationMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderCxlConfirmationMessage EXCEPT !.msSpdLegInfoLeg2 = one] : one \in CheckedMsSpdLegInfoLeg25 }
        \cup { [ZeroSpOrderCxlConfirmationMessage EXCEPT !.msSpdLegInfoLeg3 = one] : one \in CheckedMsSpdLegInfoLeg35 }

(***************************************************************************)
(* Ms Spd Leg Info Leg 2: 18 bytes                                         *)
(***************************************************************************)

MsSpdLegInfoLeg26 ==
    [ token2             : Sample(4),
      buySell2           : Sample(2),
      totalVolRemaining2 : Sample(4),
      volume2            : Sample(4),
      stOrderFlags       : Sample(2),
      openClose2         : Sample(1),
      reserved1          : Sample(1) ]

EncodeMsSpdLegInfoLeg26(message) ==
    message.token2
        \o message.buySell2
        \o message.totalVolRemaining2
        \o message.volume2
        \o message.stOrderFlags
        \o message.openClose2
        \o message.reserved1

DecodeMsSpdLegInfoLeg26(bytes) ==
    LET token2 == ReadBytes(bytes, 4) IN IF ~token2.ok THEN Fail ELSE
    LET buySell2 == ReadBytes(token2.rest, 2) IN IF ~buySell2.ok THEN Fail ELSE
    LET totalVolRemaining2 == ReadBytes(buySell2.rest, 4) IN IF ~totalVolRemaining2.ok THEN Fail ELSE
    LET volume2 == ReadBytes(totalVolRemaining2.rest, 4) IN IF ~volume2.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(volume2.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET openClose2 == ReadBytes(stOrderFlags.rest, 1) IN IF ~openClose2.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(openClose2.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ token2             |-> token2.value,
         buySell2           |-> buySell2.value,
         totalVolRemaining2 |-> totalVolRemaining2.value,
         volume2            |-> volume2.value,
         stOrderFlags       |-> stOrderFlags.value,
         openClose2         |-> openClose2.value,
         reserved1          |-> reserved1.value ], reserved1.rest)

ZeroMsSpdLegInfoLeg26 ==
    [ token2             |-> [i \in 1 .. 4 |-> 0],
      buySell2           |-> [i \in 1 .. 2 |-> 0],
      totalVolRemaining2 |-> [i \in 1 .. 4 |-> 0],
      volume2            |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags       |-> [i \in 1 .. 2 |-> 0],
      openClose2         |-> [i \in 1 .. 1 |-> 0],
      reserved1          |-> [i \in 1 .. 1 |-> 0] ]

(* Ms Spd Leg Info Leg 2 at zero, then each field in turn at the values it is checked at *)
CheckedMsSpdLegInfoLeg26 ==
    { ZeroMsSpdLegInfoLeg26 }
        \cup { [ZeroMsSpdLegInfoLeg26 EXCEPT !.token2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg26 EXCEPT !.buySell2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg26 EXCEPT !.totalVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg26 EXCEPT !.volume2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg26 EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg26 EXCEPT !.openClose2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg26 EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Ms Spd Leg Info Leg 3: 18 bytes                                         *)
(***************************************************************************)

MsSpdLegInfoLeg36 ==
    [ token2             : Sample(4),
      buySell2           : Sample(2),
      totalVolRemaining2 : Sample(4),
      volume2            : Sample(4),
      stOrderFlags       : Sample(2),
      openClose2         : Sample(1),
      reserved1          : Sample(1) ]

EncodeMsSpdLegInfoLeg36(message) ==
    message.token2
        \o message.buySell2
        \o message.totalVolRemaining2
        \o message.volume2
        \o message.stOrderFlags
        \o message.openClose2
        \o message.reserved1

DecodeMsSpdLegInfoLeg36(bytes) ==
    LET token2 == ReadBytes(bytes, 4) IN IF ~token2.ok THEN Fail ELSE
    LET buySell2 == ReadBytes(token2.rest, 2) IN IF ~buySell2.ok THEN Fail ELSE
    LET totalVolRemaining2 == ReadBytes(buySell2.rest, 4) IN IF ~totalVolRemaining2.ok THEN Fail ELSE
    LET volume2 == ReadBytes(totalVolRemaining2.rest, 4) IN IF ~volume2.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(volume2.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET openClose2 == ReadBytes(stOrderFlags.rest, 1) IN IF ~openClose2.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(openClose2.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ token2             |-> token2.value,
         buySell2           |-> buySell2.value,
         totalVolRemaining2 |-> totalVolRemaining2.value,
         volume2            |-> volume2.value,
         stOrderFlags       |-> stOrderFlags.value,
         openClose2         |-> openClose2.value,
         reserved1          |-> reserved1.value ], reserved1.rest)

ZeroMsSpdLegInfoLeg36 ==
    [ token2             |-> [i \in 1 .. 4 |-> 0],
      buySell2           |-> [i \in 1 .. 2 |-> 0],
      totalVolRemaining2 |-> [i \in 1 .. 4 |-> 0],
      volume2            |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags       |-> [i \in 1 .. 2 |-> 0],
      openClose2         |-> [i \in 1 .. 1 |-> 0],
      reserved1          |-> [i \in 1 .. 1 |-> 0] ]

(* Ms Spd Leg Info Leg 3 at zero, then each field in turn at the values it is checked at *)
CheckedMsSpdLegInfoLeg36 ==
    { ZeroMsSpdLegInfoLeg36 }
        \cup { [ZeroMsSpdLegInfoLeg36 EXCEPT !.token2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg36 EXCEPT !.buySell2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg36 EXCEPT !.totalVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg36 EXCEPT !.volume2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg36 EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg36 EXCEPT !.openClose2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg36 EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Twol Order Cxl Confirmation Message: 132 bytes                          *)
(***************************************************************************)

TwolOrderCxlConfirmationMessage ==
    [ token1              : Sample(4),
      orderNumber1        : Sample(8),
      bookType1           : Sample(2),
      buySell1            : Sample(2),
      totalVolRemaining1  : Sample(4),
      volume1             : Sample(4),
      stOrderFlags        : Sample(2),
      traderId1           : Sample(4),
      nnfField            : Sample(8),
      algoId              : Sample(4),
      activityTimeInNanos : Sample(8),
      pan                 : Sample(10),
      accountNumber1      : Sample(10),
      proClient1          : Sample(1),
      segmentChar1        : Sample(1),
      openClose1          : Sample(1),
      reserved1           : Sample(1),
      settlor1            : Sample(12),
      priceDiff           : Sample(4),
      referenceId         : Sample(4),
      reasonCode          : Sample(2),
      msSpdLegInfoLeg2    : MsSpdLegInfoLeg26,
      msSpdLegInfoLeg3    : MsSpdLegInfoLeg36 ]

EncodeTwolOrderCxlConfirmationMessage(message) ==
    message.token1
        \o message.orderNumber1
        \o message.bookType1
        \o message.buySell1
        \o message.totalVolRemaining1
        \o message.volume1
        \o message.stOrderFlags
        \o message.traderId1
        \o message.nnfField
        \o message.algoId
        \o message.activityTimeInNanos
        \o message.pan
        \o message.accountNumber1
        \o message.proClient1
        \o message.segmentChar1
        \o message.openClose1
        \o message.reserved1
        \o message.settlor1
        \o message.priceDiff
        \o message.referenceId
        \o message.reasonCode
        \o EncodeMsSpdLegInfoLeg26(message.msSpdLegInfoLeg2)
        \o EncodeMsSpdLegInfoLeg36(message.msSpdLegInfoLeg3)

DecodeTwolOrderCxlConfirmationMessage(bytes) ==
    LET token1 == ReadBytes(bytes, 4) IN IF ~token1.ok THEN Fail ELSE
    LET orderNumber1 == ReadBytes(token1.rest, 8) IN IF ~orderNumber1.ok THEN Fail ELSE
    LET bookType1 == ReadBytes(orderNumber1.rest, 2) IN IF ~bookType1.ok THEN Fail ELSE
    LET buySell1 == ReadBytes(bookType1.rest, 2) IN IF ~buySell1.ok THEN Fail ELSE
    LET totalVolRemaining1 == ReadBytes(buySell1.rest, 4) IN IF ~totalVolRemaining1.ok THEN Fail ELSE
    LET volume1 == ReadBytes(totalVolRemaining1.rest, 4) IN IF ~volume1.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(volume1.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET traderId1 == ReadBytes(stOrderFlags.rest, 4) IN IF ~traderId1.ok THEN Fail ELSE
    LET nnfField == ReadBytes(traderId1.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET algoId == ReadBytes(nnfField.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET activityTimeInNanos == ReadBytes(algoId.rest, 8) IN IF ~activityTimeInNanos.ok THEN Fail ELSE
    LET pan == ReadBytes(activityTimeInNanos.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET accountNumber1 == ReadBytes(pan.rest, 10) IN IF ~accountNumber1.ok THEN Fail ELSE
    LET proClient1 == ReadBytes(accountNumber1.rest, 1) IN IF ~proClient1.ok THEN Fail ELSE
    LET segmentChar1 == ReadBytes(proClient1.rest, 1) IN IF ~segmentChar1.ok THEN Fail ELSE
    LET openClose1 == ReadBytes(segmentChar1.rest, 1) IN IF ~openClose1.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(openClose1.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET settlor1 == ReadBytes(reserved1.rest, 12) IN IF ~settlor1.ok THEN Fail ELSE
    LET priceDiff == ReadBytes(settlor1.rest, 4) IN IF ~priceDiff.ok THEN Fail ELSE
    LET referenceId == ReadBytes(priceDiff.rest, 4) IN IF ~referenceId.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(referenceId.rest, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET msSpdLegInfoLeg2 == DecodeMsSpdLegInfoLeg26(reasonCode.rest) IN IF ~msSpdLegInfoLeg2.ok THEN Fail ELSE
    LET msSpdLegInfoLeg3 == DecodeMsSpdLegInfoLeg36(msSpdLegInfoLeg2.rest) IN IF ~msSpdLegInfoLeg3.ok THEN Fail ELSE
    Ok([ token1              |-> token1.value,
         orderNumber1        |-> orderNumber1.value,
         bookType1           |-> bookType1.value,
         buySell1            |-> buySell1.value,
         totalVolRemaining1  |-> totalVolRemaining1.value,
         volume1             |-> volume1.value,
         stOrderFlags        |-> stOrderFlags.value,
         traderId1           |-> traderId1.value,
         nnfField            |-> nnfField.value,
         algoId              |-> algoId.value,
         activityTimeInNanos |-> activityTimeInNanos.value,
         pan                 |-> pan.value,
         accountNumber1      |-> accountNumber1.value,
         proClient1          |-> proClient1.value,
         segmentChar1        |-> segmentChar1.value,
         openClose1          |-> openClose1.value,
         reserved1           |-> reserved1.value,
         settlor1            |-> settlor1.value,
         priceDiff           |-> priceDiff.value,
         referenceId         |-> referenceId.value,
         reasonCode          |-> reasonCode.value,
         msSpdLegInfoLeg2    |-> msSpdLegInfoLeg2.value,
         msSpdLegInfoLeg3    |-> msSpdLegInfoLeg3.value ], msSpdLegInfoLeg3.rest)

ZeroTwolOrderCxlConfirmationMessage ==
    [ token1              |-> [i \in 1 .. 4 |-> 0],
      orderNumber1        |-> [i \in 1 .. 8 |-> 0],
      bookType1           |-> [i \in 1 .. 2 |-> 0],
      buySell1            |-> [i \in 1 .. 2 |-> 0],
      totalVolRemaining1  |-> [i \in 1 .. 4 |-> 0],
      volume1             |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags        |-> [i \in 1 .. 2 |-> 0],
      traderId1           |-> [i \in 1 .. 4 |-> 0],
      nnfField            |-> [i \in 1 .. 8 |-> 0],
      algoId              |-> [i \in 1 .. 4 |-> 0],
      activityTimeInNanos |-> [i \in 1 .. 8 |-> 0],
      pan                 |-> [i \in 1 .. 10 |-> 0],
      accountNumber1      |-> [i \in 1 .. 10 |-> 0],
      proClient1          |-> [i \in 1 .. 1 |-> 0],
      segmentChar1        |-> [i \in 1 .. 1 |-> 0],
      openClose1          |-> [i \in 1 .. 1 |-> 0],
      reserved1           |-> [i \in 1 .. 1 |-> 0],
      settlor1            |-> [i \in 1 .. 12 |-> 0],
      priceDiff           |-> [i \in 1 .. 4 |-> 0],
      referenceId         |-> [i \in 1 .. 4 |-> 0],
      reasonCode          |-> [i \in 1 .. 2 |-> 0],
      msSpdLegInfoLeg2    |-> ZeroMsSpdLegInfoLeg26,
      msSpdLegInfoLeg3    |-> ZeroMsSpdLegInfoLeg36 ]

(* Twol Order Cxl Confirmation Message at zero, then each field in turn at the values it is checked at *)
CheckedTwolOrderCxlConfirmationMessage ==
    { ZeroTwolOrderCxlConfirmationMessage }
        \cup { [ZeroTwolOrderCxlConfirmationMessage EXCEPT !.token1 = one] : one \in Sample(4) }
        \cup { [ZeroTwolOrderCxlConfirmationMessage EXCEPT !.orderNumber1 = one] : one \in Sample(8) }
        \cup { [ZeroTwolOrderCxlConfirmationMessage EXCEPT !.bookType1 = one] : one \in Sample(2) }
        \cup { [ZeroTwolOrderCxlConfirmationMessage EXCEPT !.buySell1 = one] : one \in Sample(2) }
        \cup { [ZeroTwolOrderCxlConfirmationMessage EXCEPT !.totalVolRemaining1 = one] : one \in Sample(4) }
        \cup { [ZeroTwolOrderCxlConfirmationMessage EXCEPT !.volume1 = one] : one \in Sample(4) }
        \cup { [ZeroTwolOrderCxlConfirmationMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroTwolOrderCxlConfirmationMessage EXCEPT !.traderId1 = one] : one \in Sample(4) }
        \cup { [ZeroTwolOrderCxlConfirmationMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroTwolOrderCxlConfirmationMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroTwolOrderCxlConfirmationMessage EXCEPT !.activityTimeInNanos = one] : one \in Sample(8) }
        \cup { [ZeroTwolOrderCxlConfirmationMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroTwolOrderCxlConfirmationMessage EXCEPT !.accountNumber1 = one] : one \in Sample(10) }
        \cup { [ZeroTwolOrderCxlConfirmationMessage EXCEPT !.proClient1 = one] : one \in Sample(1) }
        \cup { [ZeroTwolOrderCxlConfirmationMessage EXCEPT !.segmentChar1 = one] : one \in Sample(1) }
        \cup { [ZeroTwolOrderCxlConfirmationMessage EXCEPT !.openClose1 = one] : one \in Sample(1) }
        \cup { [ZeroTwolOrderCxlConfirmationMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTwolOrderCxlConfirmationMessage EXCEPT !.settlor1 = one] : one \in Sample(12) }
        \cup { [ZeroTwolOrderCxlConfirmationMessage EXCEPT !.priceDiff = one] : one \in Sample(4) }
        \cup { [ZeroTwolOrderCxlConfirmationMessage EXCEPT !.referenceId = one] : one \in Sample(4) }
        \cup { [ZeroTwolOrderCxlConfirmationMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroTwolOrderCxlConfirmationMessage EXCEPT !.msSpdLegInfoLeg2 = one] : one \in CheckedMsSpdLegInfoLeg26 }
        \cup { [ZeroTwolOrderCxlConfirmationMessage EXCEPT !.msSpdLegInfoLeg3 = one] : one \in CheckedMsSpdLegInfoLeg36 }

(***************************************************************************)
(* Ms Spd Leg Info Leg 2: 18 bytes                                         *)
(***************************************************************************)

MsSpdLegInfoLeg27 ==
    [ token2             : Sample(4),
      buySell2           : Sample(2),
      totalVolRemaining2 : Sample(4),
      volume2            : Sample(4),
      stOrderFlags       : Sample(2),
      openClose2         : Sample(1),
      reserved1          : Sample(1) ]

EncodeMsSpdLegInfoLeg27(message) ==
    message.token2
        \o message.buySell2
        \o message.totalVolRemaining2
        \o message.volume2
        \o message.stOrderFlags
        \o message.openClose2
        \o message.reserved1

DecodeMsSpdLegInfoLeg27(bytes) ==
    LET token2 == ReadBytes(bytes, 4) IN IF ~token2.ok THEN Fail ELSE
    LET buySell2 == ReadBytes(token2.rest, 2) IN IF ~buySell2.ok THEN Fail ELSE
    LET totalVolRemaining2 == ReadBytes(buySell2.rest, 4) IN IF ~totalVolRemaining2.ok THEN Fail ELSE
    LET volume2 == ReadBytes(totalVolRemaining2.rest, 4) IN IF ~volume2.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(volume2.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET openClose2 == ReadBytes(stOrderFlags.rest, 1) IN IF ~openClose2.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(openClose2.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ token2             |-> token2.value,
         buySell2           |-> buySell2.value,
         totalVolRemaining2 |-> totalVolRemaining2.value,
         volume2            |-> volume2.value,
         stOrderFlags       |-> stOrderFlags.value,
         openClose2         |-> openClose2.value,
         reserved1          |-> reserved1.value ], reserved1.rest)

ZeroMsSpdLegInfoLeg27 ==
    [ token2             |-> [i \in 1 .. 4 |-> 0],
      buySell2           |-> [i \in 1 .. 2 |-> 0],
      totalVolRemaining2 |-> [i \in 1 .. 4 |-> 0],
      volume2            |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags       |-> [i \in 1 .. 2 |-> 0],
      openClose2         |-> [i \in 1 .. 1 |-> 0],
      reserved1          |-> [i \in 1 .. 1 |-> 0] ]

(* Ms Spd Leg Info Leg 2 at zero, then each field in turn at the values it is checked at *)
CheckedMsSpdLegInfoLeg27 ==
    { ZeroMsSpdLegInfoLeg27 }
        \cup { [ZeroMsSpdLegInfoLeg27 EXCEPT !.token2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg27 EXCEPT !.buySell2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg27 EXCEPT !.totalVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg27 EXCEPT !.volume2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg27 EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg27 EXCEPT !.openClose2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg27 EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Ms Spd Leg Info Leg 3: 18 bytes                                         *)
(***************************************************************************)

MsSpdLegInfoLeg37 ==
    [ token2             : Sample(4),
      buySell2           : Sample(2),
      totalVolRemaining2 : Sample(4),
      volume2            : Sample(4),
      stOrderFlags       : Sample(2),
      openClose2         : Sample(1),
      reserved1          : Sample(1) ]

EncodeMsSpdLegInfoLeg37(message) ==
    message.token2
        \o message.buySell2
        \o message.totalVolRemaining2
        \o message.volume2
        \o message.stOrderFlags
        \o message.openClose2
        \o message.reserved1

DecodeMsSpdLegInfoLeg37(bytes) ==
    LET token2 == ReadBytes(bytes, 4) IN IF ~token2.ok THEN Fail ELSE
    LET buySell2 == ReadBytes(token2.rest, 2) IN IF ~buySell2.ok THEN Fail ELSE
    LET totalVolRemaining2 == ReadBytes(buySell2.rest, 4) IN IF ~totalVolRemaining2.ok THEN Fail ELSE
    LET volume2 == ReadBytes(totalVolRemaining2.rest, 4) IN IF ~volume2.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(volume2.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET openClose2 == ReadBytes(stOrderFlags.rest, 1) IN IF ~openClose2.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(openClose2.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ token2             |-> token2.value,
         buySell2           |-> buySell2.value,
         totalVolRemaining2 |-> totalVolRemaining2.value,
         volume2            |-> volume2.value,
         stOrderFlags       |-> stOrderFlags.value,
         openClose2         |-> openClose2.value,
         reserved1          |-> reserved1.value ], reserved1.rest)

ZeroMsSpdLegInfoLeg37 ==
    [ token2             |-> [i \in 1 .. 4 |-> 0],
      buySell2           |-> [i \in 1 .. 2 |-> 0],
      totalVolRemaining2 |-> [i \in 1 .. 4 |-> 0],
      volume2            |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags       |-> [i \in 1 .. 2 |-> 0],
      openClose2         |-> [i \in 1 .. 1 |-> 0],
      reserved1          |-> [i \in 1 .. 1 |-> 0] ]

(* Ms Spd Leg Info Leg 3 at zero, then each field in turn at the values it is checked at *)
CheckedMsSpdLegInfoLeg37 ==
    { ZeroMsSpdLegInfoLeg37 }
        \cup { [ZeroMsSpdLegInfoLeg37 EXCEPT !.token2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg37 EXCEPT !.buySell2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg37 EXCEPT !.totalVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg37 EXCEPT !.volume2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg37 EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg37 EXCEPT !.openClose2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg37 EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Thrl Order Cxl Confirmation Message: 132 bytes                          *)
(***************************************************************************)

ThrlOrderCxlConfirmationMessage ==
    [ token1              : Sample(4),
      orderNumber1        : Sample(8),
      bookType1           : Sample(2),
      buySell1            : Sample(2),
      totalVolRemaining1  : Sample(4),
      volume1             : Sample(4),
      stOrderFlags        : Sample(2),
      traderId1           : Sample(4),
      nnfField            : Sample(8),
      algoId              : Sample(4),
      activityTimeInNanos : Sample(8),
      pan                 : Sample(10),
      accountNumber1      : Sample(10),
      proClient1          : Sample(1),
      segmentChar1        : Sample(1),
      openClose1          : Sample(1),
      reserved1           : Sample(1),
      settlor1            : Sample(12),
      priceDiff           : Sample(4),
      referenceId         : Sample(4),
      reasonCode          : Sample(2),
      msSpdLegInfoLeg2    : MsSpdLegInfoLeg27,
      msSpdLegInfoLeg3    : MsSpdLegInfoLeg37 ]

EncodeThrlOrderCxlConfirmationMessage(message) ==
    message.token1
        \o message.orderNumber1
        \o message.bookType1
        \o message.buySell1
        \o message.totalVolRemaining1
        \o message.volume1
        \o message.stOrderFlags
        \o message.traderId1
        \o message.nnfField
        \o message.algoId
        \o message.activityTimeInNanos
        \o message.pan
        \o message.accountNumber1
        \o message.proClient1
        \o message.segmentChar1
        \o message.openClose1
        \o message.reserved1
        \o message.settlor1
        \o message.priceDiff
        \o message.referenceId
        \o message.reasonCode
        \o EncodeMsSpdLegInfoLeg27(message.msSpdLegInfoLeg2)
        \o EncodeMsSpdLegInfoLeg37(message.msSpdLegInfoLeg3)

DecodeThrlOrderCxlConfirmationMessage(bytes) ==
    LET token1 == ReadBytes(bytes, 4) IN IF ~token1.ok THEN Fail ELSE
    LET orderNumber1 == ReadBytes(token1.rest, 8) IN IF ~orderNumber1.ok THEN Fail ELSE
    LET bookType1 == ReadBytes(orderNumber1.rest, 2) IN IF ~bookType1.ok THEN Fail ELSE
    LET buySell1 == ReadBytes(bookType1.rest, 2) IN IF ~buySell1.ok THEN Fail ELSE
    LET totalVolRemaining1 == ReadBytes(buySell1.rest, 4) IN IF ~totalVolRemaining1.ok THEN Fail ELSE
    LET volume1 == ReadBytes(totalVolRemaining1.rest, 4) IN IF ~volume1.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(volume1.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET traderId1 == ReadBytes(stOrderFlags.rest, 4) IN IF ~traderId1.ok THEN Fail ELSE
    LET nnfField == ReadBytes(traderId1.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET algoId == ReadBytes(nnfField.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET activityTimeInNanos == ReadBytes(algoId.rest, 8) IN IF ~activityTimeInNanos.ok THEN Fail ELSE
    LET pan == ReadBytes(activityTimeInNanos.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET accountNumber1 == ReadBytes(pan.rest, 10) IN IF ~accountNumber1.ok THEN Fail ELSE
    LET proClient1 == ReadBytes(accountNumber1.rest, 1) IN IF ~proClient1.ok THEN Fail ELSE
    LET segmentChar1 == ReadBytes(proClient1.rest, 1) IN IF ~segmentChar1.ok THEN Fail ELSE
    LET openClose1 == ReadBytes(segmentChar1.rest, 1) IN IF ~openClose1.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(openClose1.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET settlor1 == ReadBytes(reserved1.rest, 12) IN IF ~settlor1.ok THEN Fail ELSE
    LET priceDiff == ReadBytes(settlor1.rest, 4) IN IF ~priceDiff.ok THEN Fail ELSE
    LET referenceId == ReadBytes(priceDiff.rest, 4) IN IF ~referenceId.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(referenceId.rest, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET msSpdLegInfoLeg2 == DecodeMsSpdLegInfoLeg27(reasonCode.rest) IN IF ~msSpdLegInfoLeg2.ok THEN Fail ELSE
    LET msSpdLegInfoLeg3 == DecodeMsSpdLegInfoLeg37(msSpdLegInfoLeg2.rest) IN IF ~msSpdLegInfoLeg3.ok THEN Fail ELSE
    Ok([ token1              |-> token1.value,
         orderNumber1        |-> orderNumber1.value,
         bookType1           |-> bookType1.value,
         buySell1            |-> buySell1.value,
         totalVolRemaining1  |-> totalVolRemaining1.value,
         volume1             |-> volume1.value,
         stOrderFlags        |-> stOrderFlags.value,
         traderId1           |-> traderId1.value,
         nnfField            |-> nnfField.value,
         algoId              |-> algoId.value,
         activityTimeInNanos |-> activityTimeInNanos.value,
         pan                 |-> pan.value,
         accountNumber1      |-> accountNumber1.value,
         proClient1          |-> proClient1.value,
         segmentChar1        |-> segmentChar1.value,
         openClose1          |-> openClose1.value,
         reserved1           |-> reserved1.value,
         settlor1            |-> settlor1.value,
         priceDiff           |-> priceDiff.value,
         referenceId         |-> referenceId.value,
         reasonCode          |-> reasonCode.value,
         msSpdLegInfoLeg2    |-> msSpdLegInfoLeg2.value,
         msSpdLegInfoLeg3    |-> msSpdLegInfoLeg3.value ], msSpdLegInfoLeg3.rest)

ZeroThrlOrderCxlConfirmationMessage ==
    [ token1              |-> [i \in 1 .. 4 |-> 0],
      orderNumber1        |-> [i \in 1 .. 8 |-> 0],
      bookType1           |-> [i \in 1 .. 2 |-> 0],
      buySell1            |-> [i \in 1 .. 2 |-> 0],
      totalVolRemaining1  |-> [i \in 1 .. 4 |-> 0],
      volume1             |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags        |-> [i \in 1 .. 2 |-> 0],
      traderId1           |-> [i \in 1 .. 4 |-> 0],
      nnfField            |-> [i \in 1 .. 8 |-> 0],
      algoId              |-> [i \in 1 .. 4 |-> 0],
      activityTimeInNanos |-> [i \in 1 .. 8 |-> 0],
      pan                 |-> [i \in 1 .. 10 |-> 0],
      accountNumber1      |-> [i \in 1 .. 10 |-> 0],
      proClient1          |-> [i \in 1 .. 1 |-> 0],
      segmentChar1        |-> [i \in 1 .. 1 |-> 0],
      openClose1          |-> [i \in 1 .. 1 |-> 0],
      reserved1           |-> [i \in 1 .. 1 |-> 0],
      settlor1            |-> [i \in 1 .. 12 |-> 0],
      priceDiff           |-> [i \in 1 .. 4 |-> 0],
      referenceId         |-> [i \in 1 .. 4 |-> 0],
      reasonCode          |-> [i \in 1 .. 2 |-> 0],
      msSpdLegInfoLeg2    |-> ZeroMsSpdLegInfoLeg27,
      msSpdLegInfoLeg3    |-> ZeroMsSpdLegInfoLeg37 ]

(* Thrl Order Cxl Confirmation Message at zero, then each field in turn at the values it is checked at *)
CheckedThrlOrderCxlConfirmationMessage ==
    { ZeroThrlOrderCxlConfirmationMessage }
        \cup { [ZeroThrlOrderCxlConfirmationMessage EXCEPT !.token1 = one] : one \in Sample(4) }
        \cup { [ZeroThrlOrderCxlConfirmationMessage EXCEPT !.orderNumber1 = one] : one \in Sample(8) }
        \cup { [ZeroThrlOrderCxlConfirmationMessage EXCEPT !.bookType1 = one] : one \in Sample(2) }
        \cup { [ZeroThrlOrderCxlConfirmationMessage EXCEPT !.buySell1 = one] : one \in Sample(2) }
        \cup { [ZeroThrlOrderCxlConfirmationMessage EXCEPT !.totalVolRemaining1 = one] : one \in Sample(4) }
        \cup { [ZeroThrlOrderCxlConfirmationMessage EXCEPT !.volume1 = one] : one \in Sample(4) }
        \cup { [ZeroThrlOrderCxlConfirmationMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroThrlOrderCxlConfirmationMessage EXCEPT !.traderId1 = one] : one \in Sample(4) }
        \cup { [ZeroThrlOrderCxlConfirmationMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroThrlOrderCxlConfirmationMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroThrlOrderCxlConfirmationMessage EXCEPT !.activityTimeInNanos = one] : one \in Sample(8) }
        \cup { [ZeroThrlOrderCxlConfirmationMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroThrlOrderCxlConfirmationMessage EXCEPT !.accountNumber1 = one] : one \in Sample(10) }
        \cup { [ZeroThrlOrderCxlConfirmationMessage EXCEPT !.proClient1 = one] : one \in Sample(1) }
        \cup { [ZeroThrlOrderCxlConfirmationMessage EXCEPT !.segmentChar1 = one] : one \in Sample(1) }
        \cup { [ZeroThrlOrderCxlConfirmationMessage EXCEPT !.openClose1 = one] : one \in Sample(1) }
        \cup { [ZeroThrlOrderCxlConfirmationMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroThrlOrderCxlConfirmationMessage EXCEPT !.settlor1 = one] : one \in Sample(12) }
        \cup { [ZeroThrlOrderCxlConfirmationMessage EXCEPT !.priceDiff = one] : one \in Sample(4) }
        \cup { [ZeroThrlOrderCxlConfirmationMessage EXCEPT !.referenceId = one] : one \in Sample(4) }
        \cup { [ZeroThrlOrderCxlConfirmationMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroThrlOrderCxlConfirmationMessage EXCEPT !.msSpdLegInfoLeg2 = one] : one \in CheckedMsSpdLegInfoLeg27 }
        \cup { [ZeroThrlOrderCxlConfirmationMessage EXCEPT !.msSpdLegInfoLeg3 = one] : one \in CheckedMsSpdLegInfoLeg37 }

(***************************************************************************)
(* Ms Spd Leg Info Leg 2: 18 bytes                                         *)
(***************************************************************************)

MsSpdLegInfoLeg28 ==
    [ token2             : Sample(4),
      buySell2           : Sample(2),
      totalVolRemaining2 : Sample(4),
      volume2            : Sample(4),
      stOrderFlags       : Sample(2),
      openClose2         : Sample(1),
      reserved1          : Sample(1) ]

EncodeMsSpdLegInfoLeg28(message) ==
    message.token2
        \o message.buySell2
        \o message.totalVolRemaining2
        \o message.volume2
        \o message.stOrderFlags
        \o message.openClose2
        \o message.reserved1

DecodeMsSpdLegInfoLeg28(bytes) ==
    LET token2 == ReadBytes(bytes, 4) IN IF ~token2.ok THEN Fail ELSE
    LET buySell2 == ReadBytes(token2.rest, 2) IN IF ~buySell2.ok THEN Fail ELSE
    LET totalVolRemaining2 == ReadBytes(buySell2.rest, 4) IN IF ~totalVolRemaining2.ok THEN Fail ELSE
    LET volume2 == ReadBytes(totalVolRemaining2.rest, 4) IN IF ~volume2.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(volume2.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET openClose2 == ReadBytes(stOrderFlags.rest, 1) IN IF ~openClose2.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(openClose2.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ token2             |-> token2.value,
         buySell2           |-> buySell2.value,
         totalVolRemaining2 |-> totalVolRemaining2.value,
         volume2            |-> volume2.value,
         stOrderFlags       |-> stOrderFlags.value,
         openClose2         |-> openClose2.value,
         reserved1          |-> reserved1.value ], reserved1.rest)

ZeroMsSpdLegInfoLeg28 ==
    [ token2             |-> [i \in 1 .. 4 |-> 0],
      buySell2           |-> [i \in 1 .. 2 |-> 0],
      totalVolRemaining2 |-> [i \in 1 .. 4 |-> 0],
      volume2            |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags       |-> [i \in 1 .. 2 |-> 0],
      openClose2         |-> [i \in 1 .. 1 |-> 0],
      reserved1          |-> [i \in 1 .. 1 |-> 0] ]

(* Ms Spd Leg Info Leg 2 at zero, then each field in turn at the values it is checked at *)
CheckedMsSpdLegInfoLeg28 ==
    { ZeroMsSpdLegInfoLeg28 }
        \cup { [ZeroMsSpdLegInfoLeg28 EXCEPT !.token2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg28 EXCEPT !.buySell2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg28 EXCEPT !.totalVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg28 EXCEPT !.volume2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg28 EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg28 EXCEPT !.openClose2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg28 EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Ms Spd Leg Info Leg 3: 18 bytes                                         *)
(***************************************************************************)

MsSpdLegInfoLeg38 ==
    [ token2             : Sample(4),
      buySell2           : Sample(2),
      totalVolRemaining2 : Sample(4),
      volume2            : Sample(4),
      stOrderFlags       : Sample(2),
      openClose2         : Sample(1),
      reserved1          : Sample(1) ]

EncodeMsSpdLegInfoLeg38(message) ==
    message.token2
        \o message.buySell2
        \o message.totalVolRemaining2
        \o message.volume2
        \o message.stOrderFlags
        \o message.openClose2
        \o message.reserved1

DecodeMsSpdLegInfoLeg38(bytes) ==
    LET token2 == ReadBytes(bytes, 4) IN IF ~token2.ok THEN Fail ELSE
    LET buySell2 == ReadBytes(token2.rest, 2) IN IF ~buySell2.ok THEN Fail ELSE
    LET totalVolRemaining2 == ReadBytes(buySell2.rest, 4) IN IF ~totalVolRemaining2.ok THEN Fail ELSE
    LET volume2 == ReadBytes(totalVolRemaining2.rest, 4) IN IF ~volume2.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(volume2.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET openClose2 == ReadBytes(stOrderFlags.rest, 1) IN IF ~openClose2.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(openClose2.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ token2             |-> token2.value,
         buySell2           |-> buySell2.value,
         totalVolRemaining2 |-> totalVolRemaining2.value,
         volume2            |-> volume2.value,
         stOrderFlags       |-> stOrderFlags.value,
         openClose2         |-> openClose2.value,
         reserved1          |-> reserved1.value ], reserved1.rest)

ZeroMsSpdLegInfoLeg38 ==
    [ token2             |-> [i \in 1 .. 4 |-> 0],
      buySell2           |-> [i \in 1 .. 2 |-> 0],
      totalVolRemaining2 |-> [i \in 1 .. 4 |-> 0],
      volume2            |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags       |-> [i \in 1 .. 2 |-> 0],
      openClose2         |-> [i \in 1 .. 1 |-> 0],
      reserved1          |-> [i \in 1 .. 1 |-> 0] ]

(* Ms Spd Leg Info Leg 3 at zero, then each field in turn at the values it is checked at *)
CheckedMsSpdLegInfoLeg38 ==
    { ZeroMsSpdLegInfoLeg38 }
        \cup { [ZeroMsSpdLegInfoLeg38 EXCEPT !.token2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg38 EXCEPT !.buySell2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg38 EXCEPT !.totalVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg38 EXCEPT !.volume2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg38 EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg38 EXCEPT !.openClose2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg38 EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Sp Order Mod Reject Message: 132 bytes                                  *)
(***************************************************************************)

SpOrderModRejectMessage ==
    [ token1              : Sample(4),
      orderNumber1        : Sample(8),
      bookType1           : Sample(2),
      buySell1            : Sample(2),
      totalVolRemaining1  : Sample(4),
      volume1             : Sample(4),
      stOrderFlags        : Sample(2),
      traderId1           : Sample(4),
      nnfField            : Sample(8),
      algoId              : Sample(4),
      activityTimeInNanos : Sample(8),
      pan                 : Sample(10),
      accountNumber1      : Sample(10),
      proClient1          : Sample(1),
      segmentChar1        : Sample(1),
      openClose1          : Sample(1),
      reserved1           : Sample(1),
      settlor1            : Sample(12),
      priceDiff           : Sample(4),
      referenceId         : Sample(4),
      reasonCode          : Sample(2),
      msSpdLegInfoLeg2    : MsSpdLegInfoLeg28,
      msSpdLegInfoLeg3    : MsSpdLegInfoLeg38 ]

EncodeSpOrderModRejectMessage(message) ==
    message.token1
        \o message.orderNumber1
        \o message.bookType1
        \o message.buySell1
        \o message.totalVolRemaining1
        \o message.volume1
        \o message.stOrderFlags
        \o message.traderId1
        \o message.nnfField
        \o message.algoId
        \o message.activityTimeInNanos
        \o message.pan
        \o message.accountNumber1
        \o message.proClient1
        \o message.segmentChar1
        \o message.openClose1
        \o message.reserved1
        \o message.settlor1
        \o message.priceDiff
        \o message.referenceId
        \o message.reasonCode
        \o EncodeMsSpdLegInfoLeg28(message.msSpdLegInfoLeg2)
        \o EncodeMsSpdLegInfoLeg38(message.msSpdLegInfoLeg3)

DecodeSpOrderModRejectMessage(bytes) ==
    LET token1 == ReadBytes(bytes, 4) IN IF ~token1.ok THEN Fail ELSE
    LET orderNumber1 == ReadBytes(token1.rest, 8) IN IF ~orderNumber1.ok THEN Fail ELSE
    LET bookType1 == ReadBytes(orderNumber1.rest, 2) IN IF ~bookType1.ok THEN Fail ELSE
    LET buySell1 == ReadBytes(bookType1.rest, 2) IN IF ~buySell1.ok THEN Fail ELSE
    LET totalVolRemaining1 == ReadBytes(buySell1.rest, 4) IN IF ~totalVolRemaining1.ok THEN Fail ELSE
    LET volume1 == ReadBytes(totalVolRemaining1.rest, 4) IN IF ~volume1.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(volume1.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET traderId1 == ReadBytes(stOrderFlags.rest, 4) IN IF ~traderId1.ok THEN Fail ELSE
    LET nnfField == ReadBytes(traderId1.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET algoId == ReadBytes(nnfField.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET activityTimeInNanos == ReadBytes(algoId.rest, 8) IN IF ~activityTimeInNanos.ok THEN Fail ELSE
    LET pan == ReadBytes(activityTimeInNanos.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET accountNumber1 == ReadBytes(pan.rest, 10) IN IF ~accountNumber1.ok THEN Fail ELSE
    LET proClient1 == ReadBytes(accountNumber1.rest, 1) IN IF ~proClient1.ok THEN Fail ELSE
    LET segmentChar1 == ReadBytes(proClient1.rest, 1) IN IF ~segmentChar1.ok THEN Fail ELSE
    LET openClose1 == ReadBytes(segmentChar1.rest, 1) IN IF ~openClose1.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(openClose1.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET settlor1 == ReadBytes(reserved1.rest, 12) IN IF ~settlor1.ok THEN Fail ELSE
    LET priceDiff == ReadBytes(settlor1.rest, 4) IN IF ~priceDiff.ok THEN Fail ELSE
    LET referenceId == ReadBytes(priceDiff.rest, 4) IN IF ~referenceId.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(referenceId.rest, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET msSpdLegInfoLeg2 == DecodeMsSpdLegInfoLeg28(reasonCode.rest) IN IF ~msSpdLegInfoLeg2.ok THEN Fail ELSE
    LET msSpdLegInfoLeg3 == DecodeMsSpdLegInfoLeg38(msSpdLegInfoLeg2.rest) IN IF ~msSpdLegInfoLeg3.ok THEN Fail ELSE
    Ok([ token1              |-> token1.value,
         orderNumber1        |-> orderNumber1.value,
         bookType1           |-> bookType1.value,
         buySell1            |-> buySell1.value,
         totalVolRemaining1  |-> totalVolRemaining1.value,
         volume1             |-> volume1.value,
         stOrderFlags        |-> stOrderFlags.value,
         traderId1           |-> traderId1.value,
         nnfField            |-> nnfField.value,
         algoId              |-> algoId.value,
         activityTimeInNanos |-> activityTimeInNanos.value,
         pan                 |-> pan.value,
         accountNumber1      |-> accountNumber1.value,
         proClient1          |-> proClient1.value,
         segmentChar1        |-> segmentChar1.value,
         openClose1          |-> openClose1.value,
         reserved1           |-> reserved1.value,
         settlor1            |-> settlor1.value,
         priceDiff           |-> priceDiff.value,
         referenceId         |-> referenceId.value,
         reasonCode          |-> reasonCode.value,
         msSpdLegInfoLeg2    |-> msSpdLegInfoLeg2.value,
         msSpdLegInfoLeg3    |-> msSpdLegInfoLeg3.value ], msSpdLegInfoLeg3.rest)

ZeroSpOrderModRejectMessage ==
    [ token1              |-> [i \in 1 .. 4 |-> 0],
      orderNumber1        |-> [i \in 1 .. 8 |-> 0],
      bookType1           |-> [i \in 1 .. 2 |-> 0],
      buySell1            |-> [i \in 1 .. 2 |-> 0],
      totalVolRemaining1  |-> [i \in 1 .. 4 |-> 0],
      volume1             |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags        |-> [i \in 1 .. 2 |-> 0],
      traderId1           |-> [i \in 1 .. 4 |-> 0],
      nnfField            |-> [i \in 1 .. 8 |-> 0],
      algoId              |-> [i \in 1 .. 4 |-> 0],
      activityTimeInNanos |-> [i \in 1 .. 8 |-> 0],
      pan                 |-> [i \in 1 .. 10 |-> 0],
      accountNumber1      |-> [i \in 1 .. 10 |-> 0],
      proClient1          |-> [i \in 1 .. 1 |-> 0],
      segmentChar1        |-> [i \in 1 .. 1 |-> 0],
      openClose1          |-> [i \in 1 .. 1 |-> 0],
      reserved1           |-> [i \in 1 .. 1 |-> 0],
      settlor1            |-> [i \in 1 .. 12 |-> 0],
      priceDiff           |-> [i \in 1 .. 4 |-> 0],
      referenceId         |-> [i \in 1 .. 4 |-> 0],
      reasonCode          |-> [i \in 1 .. 2 |-> 0],
      msSpdLegInfoLeg2    |-> ZeroMsSpdLegInfoLeg28,
      msSpdLegInfoLeg3    |-> ZeroMsSpdLegInfoLeg38 ]

(* Sp Order Mod Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedSpOrderModRejectMessage ==
    { ZeroSpOrderModRejectMessage }
        \cup { [ZeroSpOrderModRejectMessage EXCEPT !.token1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderModRejectMessage EXCEPT !.orderNumber1 = one] : one \in Sample(8) }
        \cup { [ZeroSpOrderModRejectMessage EXCEPT !.bookType1 = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderModRejectMessage EXCEPT !.buySell1 = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderModRejectMessage EXCEPT !.totalVolRemaining1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderModRejectMessage EXCEPT !.volume1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderModRejectMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderModRejectMessage EXCEPT !.traderId1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderModRejectMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroSpOrderModRejectMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderModRejectMessage EXCEPT !.activityTimeInNanos = one] : one \in Sample(8) }
        \cup { [ZeroSpOrderModRejectMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroSpOrderModRejectMessage EXCEPT !.accountNumber1 = one] : one \in Sample(10) }
        \cup { [ZeroSpOrderModRejectMessage EXCEPT !.proClient1 = one] : one \in Sample(1) }
        \cup { [ZeroSpOrderModRejectMessage EXCEPT !.segmentChar1 = one] : one \in Sample(1) }
        \cup { [ZeroSpOrderModRejectMessage EXCEPT !.openClose1 = one] : one \in Sample(1) }
        \cup { [ZeroSpOrderModRejectMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroSpOrderModRejectMessage EXCEPT !.settlor1 = one] : one \in Sample(12) }
        \cup { [ZeroSpOrderModRejectMessage EXCEPT !.priceDiff = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderModRejectMessage EXCEPT !.referenceId = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderModRejectMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderModRejectMessage EXCEPT !.msSpdLegInfoLeg2 = one] : one \in CheckedMsSpdLegInfoLeg28 }
        \cup { [ZeroSpOrderModRejectMessage EXCEPT !.msSpdLegInfoLeg3 = one] : one \in CheckedMsSpdLegInfoLeg38 }

(***************************************************************************)
(* Ms Spd Leg Info Leg 2: 18 bytes                                         *)
(***************************************************************************)

MsSpdLegInfoLeg29 ==
    [ token2             : Sample(4),
      buySell2           : Sample(2),
      totalVolRemaining2 : Sample(4),
      volume2            : Sample(4),
      stOrderFlags       : Sample(2),
      openClose2         : Sample(1),
      reserved1          : Sample(1) ]

EncodeMsSpdLegInfoLeg29(message) ==
    message.token2
        \o message.buySell2
        \o message.totalVolRemaining2
        \o message.volume2
        \o message.stOrderFlags
        \o message.openClose2
        \o message.reserved1

DecodeMsSpdLegInfoLeg29(bytes) ==
    LET token2 == ReadBytes(bytes, 4) IN IF ~token2.ok THEN Fail ELSE
    LET buySell2 == ReadBytes(token2.rest, 2) IN IF ~buySell2.ok THEN Fail ELSE
    LET totalVolRemaining2 == ReadBytes(buySell2.rest, 4) IN IF ~totalVolRemaining2.ok THEN Fail ELSE
    LET volume2 == ReadBytes(totalVolRemaining2.rest, 4) IN IF ~volume2.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(volume2.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET openClose2 == ReadBytes(stOrderFlags.rest, 1) IN IF ~openClose2.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(openClose2.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ token2             |-> token2.value,
         buySell2           |-> buySell2.value,
         totalVolRemaining2 |-> totalVolRemaining2.value,
         volume2            |-> volume2.value,
         stOrderFlags       |-> stOrderFlags.value,
         openClose2         |-> openClose2.value,
         reserved1          |-> reserved1.value ], reserved1.rest)

ZeroMsSpdLegInfoLeg29 ==
    [ token2             |-> [i \in 1 .. 4 |-> 0],
      buySell2           |-> [i \in 1 .. 2 |-> 0],
      totalVolRemaining2 |-> [i \in 1 .. 4 |-> 0],
      volume2            |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags       |-> [i \in 1 .. 2 |-> 0],
      openClose2         |-> [i \in 1 .. 1 |-> 0],
      reserved1          |-> [i \in 1 .. 1 |-> 0] ]

(* Ms Spd Leg Info Leg 2 at zero, then each field in turn at the values it is checked at *)
CheckedMsSpdLegInfoLeg29 ==
    { ZeroMsSpdLegInfoLeg29 }
        \cup { [ZeroMsSpdLegInfoLeg29 EXCEPT !.token2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg29 EXCEPT !.buySell2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg29 EXCEPT !.totalVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg29 EXCEPT !.volume2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg29 EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg29 EXCEPT !.openClose2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg29 EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Ms Spd Leg Info Leg 3: 18 bytes                                         *)
(***************************************************************************)

MsSpdLegInfoLeg39 ==
    [ token2             : Sample(4),
      buySell2           : Sample(2),
      totalVolRemaining2 : Sample(4),
      volume2            : Sample(4),
      stOrderFlags       : Sample(2),
      openClose2         : Sample(1),
      reserved1          : Sample(1) ]

EncodeMsSpdLegInfoLeg39(message) ==
    message.token2
        \o message.buySell2
        \o message.totalVolRemaining2
        \o message.volume2
        \o message.stOrderFlags
        \o message.openClose2
        \o message.reserved1

DecodeMsSpdLegInfoLeg39(bytes) ==
    LET token2 == ReadBytes(bytes, 4) IN IF ~token2.ok THEN Fail ELSE
    LET buySell2 == ReadBytes(token2.rest, 2) IN IF ~buySell2.ok THEN Fail ELSE
    LET totalVolRemaining2 == ReadBytes(buySell2.rest, 4) IN IF ~totalVolRemaining2.ok THEN Fail ELSE
    LET volume2 == ReadBytes(totalVolRemaining2.rest, 4) IN IF ~volume2.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(volume2.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET openClose2 == ReadBytes(stOrderFlags.rest, 1) IN IF ~openClose2.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(openClose2.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ token2             |-> token2.value,
         buySell2           |-> buySell2.value,
         totalVolRemaining2 |-> totalVolRemaining2.value,
         volume2            |-> volume2.value,
         stOrderFlags       |-> stOrderFlags.value,
         openClose2         |-> openClose2.value,
         reserved1          |-> reserved1.value ], reserved1.rest)

ZeroMsSpdLegInfoLeg39 ==
    [ token2             |-> [i \in 1 .. 4 |-> 0],
      buySell2           |-> [i \in 1 .. 2 |-> 0],
      totalVolRemaining2 |-> [i \in 1 .. 4 |-> 0],
      volume2            |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags       |-> [i \in 1 .. 2 |-> 0],
      openClose2         |-> [i \in 1 .. 1 |-> 0],
      reserved1          |-> [i \in 1 .. 1 |-> 0] ]

(* Ms Spd Leg Info Leg 3 at zero, then each field in turn at the values it is checked at *)
CheckedMsSpdLegInfoLeg39 ==
    { ZeroMsSpdLegInfoLeg39 }
        \cup { [ZeroMsSpdLegInfoLeg39 EXCEPT !.token2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg39 EXCEPT !.buySell2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg39 EXCEPT !.totalVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg39 EXCEPT !.volume2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg39 EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg39 EXCEPT !.openClose2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg39 EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Sp Order Mod Confirmation Message: 132 bytes                            *)
(***************************************************************************)

SpOrderModConfirmationMessage ==
    [ token1              : Sample(4),
      orderNumber1        : Sample(8),
      bookType1           : Sample(2),
      buySell1            : Sample(2),
      totalVolRemaining1  : Sample(4),
      volume1             : Sample(4),
      stOrderFlags        : Sample(2),
      traderId1           : Sample(4),
      nnfField            : Sample(8),
      algoId              : Sample(4),
      activityTimeInNanos : Sample(8),
      pan                 : Sample(10),
      accountNumber1      : Sample(10),
      proClient1          : Sample(1),
      segmentChar1        : Sample(1),
      openClose1          : Sample(1),
      reserved1           : Sample(1),
      settlor1            : Sample(12),
      priceDiff           : Sample(4),
      referenceId         : Sample(4),
      reasonCode          : Sample(2),
      msSpdLegInfoLeg2    : MsSpdLegInfoLeg29,
      msSpdLegInfoLeg3    : MsSpdLegInfoLeg39 ]

EncodeSpOrderModConfirmationMessage(message) ==
    message.token1
        \o message.orderNumber1
        \o message.bookType1
        \o message.buySell1
        \o message.totalVolRemaining1
        \o message.volume1
        \o message.stOrderFlags
        \o message.traderId1
        \o message.nnfField
        \o message.algoId
        \o message.activityTimeInNanos
        \o message.pan
        \o message.accountNumber1
        \o message.proClient1
        \o message.segmentChar1
        \o message.openClose1
        \o message.reserved1
        \o message.settlor1
        \o message.priceDiff
        \o message.referenceId
        \o message.reasonCode
        \o EncodeMsSpdLegInfoLeg29(message.msSpdLegInfoLeg2)
        \o EncodeMsSpdLegInfoLeg39(message.msSpdLegInfoLeg3)

DecodeSpOrderModConfirmationMessage(bytes) ==
    LET token1 == ReadBytes(bytes, 4) IN IF ~token1.ok THEN Fail ELSE
    LET orderNumber1 == ReadBytes(token1.rest, 8) IN IF ~orderNumber1.ok THEN Fail ELSE
    LET bookType1 == ReadBytes(orderNumber1.rest, 2) IN IF ~bookType1.ok THEN Fail ELSE
    LET buySell1 == ReadBytes(bookType1.rest, 2) IN IF ~buySell1.ok THEN Fail ELSE
    LET totalVolRemaining1 == ReadBytes(buySell1.rest, 4) IN IF ~totalVolRemaining1.ok THEN Fail ELSE
    LET volume1 == ReadBytes(totalVolRemaining1.rest, 4) IN IF ~volume1.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(volume1.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET traderId1 == ReadBytes(stOrderFlags.rest, 4) IN IF ~traderId1.ok THEN Fail ELSE
    LET nnfField == ReadBytes(traderId1.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET algoId == ReadBytes(nnfField.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET activityTimeInNanos == ReadBytes(algoId.rest, 8) IN IF ~activityTimeInNanos.ok THEN Fail ELSE
    LET pan == ReadBytes(activityTimeInNanos.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET accountNumber1 == ReadBytes(pan.rest, 10) IN IF ~accountNumber1.ok THEN Fail ELSE
    LET proClient1 == ReadBytes(accountNumber1.rest, 1) IN IF ~proClient1.ok THEN Fail ELSE
    LET segmentChar1 == ReadBytes(proClient1.rest, 1) IN IF ~segmentChar1.ok THEN Fail ELSE
    LET openClose1 == ReadBytes(segmentChar1.rest, 1) IN IF ~openClose1.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(openClose1.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET settlor1 == ReadBytes(reserved1.rest, 12) IN IF ~settlor1.ok THEN Fail ELSE
    LET priceDiff == ReadBytes(settlor1.rest, 4) IN IF ~priceDiff.ok THEN Fail ELSE
    LET referenceId == ReadBytes(priceDiff.rest, 4) IN IF ~referenceId.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(referenceId.rest, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET msSpdLegInfoLeg2 == DecodeMsSpdLegInfoLeg29(reasonCode.rest) IN IF ~msSpdLegInfoLeg2.ok THEN Fail ELSE
    LET msSpdLegInfoLeg3 == DecodeMsSpdLegInfoLeg39(msSpdLegInfoLeg2.rest) IN IF ~msSpdLegInfoLeg3.ok THEN Fail ELSE
    Ok([ token1              |-> token1.value,
         orderNumber1        |-> orderNumber1.value,
         bookType1           |-> bookType1.value,
         buySell1            |-> buySell1.value,
         totalVolRemaining1  |-> totalVolRemaining1.value,
         volume1             |-> volume1.value,
         stOrderFlags        |-> stOrderFlags.value,
         traderId1           |-> traderId1.value,
         nnfField            |-> nnfField.value,
         algoId              |-> algoId.value,
         activityTimeInNanos |-> activityTimeInNanos.value,
         pan                 |-> pan.value,
         accountNumber1      |-> accountNumber1.value,
         proClient1          |-> proClient1.value,
         segmentChar1        |-> segmentChar1.value,
         openClose1          |-> openClose1.value,
         reserved1           |-> reserved1.value,
         settlor1            |-> settlor1.value,
         priceDiff           |-> priceDiff.value,
         referenceId         |-> referenceId.value,
         reasonCode          |-> reasonCode.value,
         msSpdLegInfoLeg2    |-> msSpdLegInfoLeg2.value,
         msSpdLegInfoLeg3    |-> msSpdLegInfoLeg3.value ], msSpdLegInfoLeg3.rest)

ZeroSpOrderModConfirmationMessage ==
    [ token1              |-> [i \in 1 .. 4 |-> 0],
      orderNumber1        |-> [i \in 1 .. 8 |-> 0],
      bookType1           |-> [i \in 1 .. 2 |-> 0],
      buySell1            |-> [i \in 1 .. 2 |-> 0],
      totalVolRemaining1  |-> [i \in 1 .. 4 |-> 0],
      volume1             |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags        |-> [i \in 1 .. 2 |-> 0],
      traderId1           |-> [i \in 1 .. 4 |-> 0],
      nnfField            |-> [i \in 1 .. 8 |-> 0],
      algoId              |-> [i \in 1 .. 4 |-> 0],
      activityTimeInNanos |-> [i \in 1 .. 8 |-> 0],
      pan                 |-> [i \in 1 .. 10 |-> 0],
      accountNumber1      |-> [i \in 1 .. 10 |-> 0],
      proClient1          |-> [i \in 1 .. 1 |-> 0],
      segmentChar1        |-> [i \in 1 .. 1 |-> 0],
      openClose1          |-> [i \in 1 .. 1 |-> 0],
      reserved1           |-> [i \in 1 .. 1 |-> 0],
      settlor1            |-> [i \in 1 .. 12 |-> 0],
      priceDiff           |-> [i \in 1 .. 4 |-> 0],
      referenceId         |-> [i \in 1 .. 4 |-> 0],
      reasonCode          |-> [i \in 1 .. 2 |-> 0],
      msSpdLegInfoLeg2    |-> ZeroMsSpdLegInfoLeg29,
      msSpdLegInfoLeg3    |-> ZeroMsSpdLegInfoLeg39 ]

(* Sp Order Mod Confirmation Message at zero, then each field in turn at the values it is checked at *)
CheckedSpOrderModConfirmationMessage ==
    { ZeroSpOrderModConfirmationMessage }
        \cup { [ZeroSpOrderModConfirmationMessage EXCEPT !.token1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderModConfirmationMessage EXCEPT !.orderNumber1 = one] : one \in Sample(8) }
        \cup { [ZeroSpOrderModConfirmationMessage EXCEPT !.bookType1 = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderModConfirmationMessage EXCEPT !.buySell1 = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderModConfirmationMessage EXCEPT !.totalVolRemaining1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderModConfirmationMessage EXCEPT !.volume1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderModConfirmationMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderModConfirmationMessage EXCEPT !.traderId1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderModConfirmationMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroSpOrderModConfirmationMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderModConfirmationMessage EXCEPT !.activityTimeInNanos = one] : one \in Sample(8) }
        \cup { [ZeroSpOrderModConfirmationMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroSpOrderModConfirmationMessage EXCEPT !.accountNumber1 = one] : one \in Sample(10) }
        \cup { [ZeroSpOrderModConfirmationMessage EXCEPT !.proClient1 = one] : one \in Sample(1) }
        \cup { [ZeroSpOrderModConfirmationMessage EXCEPT !.segmentChar1 = one] : one \in Sample(1) }
        \cup { [ZeroSpOrderModConfirmationMessage EXCEPT !.openClose1 = one] : one \in Sample(1) }
        \cup { [ZeroSpOrderModConfirmationMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroSpOrderModConfirmationMessage EXCEPT !.settlor1 = one] : one \in Sample(12) }
        \cup { [ZeroSpOrderModConfirmationMessage EXCEPT !.priceDiff = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderModConfirmationMessage EXCEPT !.referenceId = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderModConfirmationMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderModConfirmationMessage EXCEPT !.msSpdLegInfoLeg2 = one] : one \in CheckedMsSpdLegInfoLeg29 }
        \cup { [ZeroSpOrderModConfirmationMessage EXCEPT !.msSpdLegInfoLeg3 = one] : one \in CheckedMsSpdLegInfoLeg39 }

(***************************************************************************)
(* Ms Spd Leg Info Leg 2: 18 bytes                                         *)
(***************************************************************************)

MsSpdLegInfoLeg210 ==
    [ token2             : Sample(4),
      buySell2           : Sample(2),
      totalVolRemaining2 : Sample(4),
      volume2            : Sample(4),
      stOrderFlags       : Sample(2),
      openClose2         : Sample(1),
      reserved1          : Sample(1) ]

EncodeMsSpdLegInfoLeg210(message) ==
    message.token2
        \o message.buySell2
        \o message.totalVolRemaining2
        \o message.volume2
        \o message.stOrderFlags
        \o message.openClose2
        \o message.reserved1

DecodeMsSpdLegInfoLeg210(bytes) ==
    LET token2 == ReadBytes(bytes, 4) IN IF ~token2.ok THEN Fail ELSE
    LET buySell2 == ReadBytes(token2.rest, 2) IN IF ~buySell2.ok THEN Fail ELSE
    LET totalVolRemaining2 == ReadBytes(buySell2.rest, 4) IN IF ~totalVolRemaining2.ok THEN Fail ELSE
    LET volume2 == ReadBytes(totalVolRemaining2.rest, 4) IN IF ~volume2.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(volume2.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET openClose2 == ReadBytes(stOrderFlags.rest, 1) IN IF ~openClose2.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(openClose2.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ token2             |-> token2.value,
         buySell2           |-> buySell2.value,
         totalVolRemaining2 |-> totalVolRemaining2.value,
         volume2            |-> volume2.value,
         stOrderFlags       |-> stOrderFlags.value,
         openClose2         |-> openClose2.value,
         reserved1          |-> reserved1.value ], reserved1.rest)

ZeroMsSpdLegInfoLeg210 ==
    [ token2             |-> [i \in 1 .. 4 |-> 0],
      buySell2           |-> [i \in 1 .. 2 |-> 0],
      totalVolRemaining2 |-> [i \in 1 .. 4 |-> 0],
      volume2            |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags       |-> [i \in 1 .. 2 |-> 0],
      openClose2         |-> [i \in 1 .. 1 |-> 0],
      reserved1          |-> [i \in 1 .. 1 |-> 0] ]

(* Ms Spd Leg Info Leg 2 at zero, then each field in turn at the values it is checked at *)
CheckedMsSpdLegInfoLeg210 ==
    { ZeroMsSpdLegInfoLeg210 }
        \cup { [ZeroMsSpdLegInfoLeg210 EXCEPT !.token2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg210 EXCEPT !.buySell2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg210 EXCEPT !.totalVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg210 EXCEPT !.volume2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg210 EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg210 EXCEPT !.openClose2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg210 EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Ms Spd Leg Info Leg 3: 18 bytes                                         *)
(***************************************************************************)

MsSpdLegInfoLeg310 ==
    [ token2             : Sample(4),
      buySell2           : Sample(2),
      totalVolRemaining2 : Sample(4),
      volume2            : Sample(4),
      stOrderFlags       : Sample(2),
      openClose2         : Sample(1),
      reserved1          : Sample(1) ]

EncodeMsSpdLegInfoLeg310(message) ==
    message.token2
        \o message.buySell2
        \o message.totalVolRemaining2
        \o message.volume2
        \o message.stOrderFlags
        \o message.openClose2
        \o message.reserved1

DecodeMsSpdLegInfoLeg310(bytes) ==
    LET token2 == ReadBytes(bytes, 4) IN IF ~token2.ok THEN Fail ELSE
    LET buySell2 == ReadBytes(token2.rest, 2) IN IF ~buySell2.ok THEN Fail ELSE
    LET totalVolRemaining2 == ReadBytes(buySell2.rest, 4) IN IF ~totalVolRemaining2.ok THEN Fail ELSE
    LET volume2 == ReadBytes(totalVolRemaining2.rest, 4) IN IF ~volume2.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(volume2.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET openClose2 == ReadBytes(stOrderFlags.rest, 1) IN IF ~openClose2.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(openClose2.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ token2             |-> token2.value,
         buySell2           |-> buySell2.value,
         totalVolRemaining2 |-> totalVolRemaining2.value,
         volume2            |-> volume2.value,
         stOrderFlags       |-> stOrderFlags.value,
         openClose2         |-> openClose2.value,
         reserved1          |-> reserved1.value ], reserved1.rest)

ZeroMsSpdLegInfoLeg310 ==
    [ token2             |-> [i \in 1 .. 4 |-> 0],
      buySell2           |-> [i \in 1 .. 2 |-> 0],
      totalVolRemaining2 |-> [i \in 1 .. 4 |-> 0],
      volume2            |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags       |-> [i \in 1 .. 2 |-> 0],
      openClose2         |-> [i \in 1 .. 1 |-> 0],
      reserved1          |-> [i \in 1 .. 1 |-> 0] ]

(* Ms Spd Leg Info Leg 3 at zero, then each field in turn at the values it is checked at *)
CheckedMsSpdLegInfoLeg310 ==
    { ZeroMsSpdLegInfoLeg310 }
        \cup { [ZeroMsSpdLegInfoLeg310 EXCEPT !.token2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg310 EXCEPT !.buySell2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg310 EXCEPT !.totalVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg310 EXCEPT !.volume2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg310 EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg310 EXCEPT !.openClose2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg310 EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Sp Order Rejected Message: 132 bytes                                    *)
(***************************************************************************)

SpOrderRejectedMessage ==
    [ token1              : Sample(4),
      orderNumber1        : Sample(8),
      bookType1           : Sample(2),
      buySell1            : Sample(2),
      totalVolRemaining1  : Sample(4),
      volume1             : Sample(4),
      stOrderFlags        : Sample(2),
      traderId1           : Sample(4),
      nnfField            : Sample(8),
      algoId              : Sample(4),
      activityTimeInNanos : Sample(8),
      pan                 : Sample(10),
      accountNumber1      : Sample(10),
      proClient1          : Sample(1),
      segmentChar1        : Sample(1),
      openClose1          : Sample(1),
      reserved1           : Sample(1),
      settlor1            : Sample(12),
      priceDiff           : Sample(4),
      referenceId         : Sample(4),
      reasonCode          : Sample(2),
      msSpdLegInfoLeg2    : MsSpdLegInfoLeg210,
      msSpdLegInfoLeg3    : MsSpdLegInfoLeg310 ]

EncodeSpOrderRejectedMessage(message) ==
    message.token1
        \o message.orderNumber1
        \o message.bookType1
        \o message.buySell1
        \o message.totalVolRemaining1
        \o message.volume1
        \o message.stOrderFlags
        \o message.traderId1
        \o message.nnfField
        \o message.algoId
        \o message.activityTimeInNanos
        \o message.pan
        \o message.accountNumber1
        \o message.proClient1
        \o message.segmentChar1
        \o message.openClose1
        \o message.reserved1
        \o message.settlor1
        \o message.priceDiff
        \o message.referenceId
        \o message.reasonCode
        \o EncodeMsSpdLegInfoLeg210(message.msSpdLegInfoLeg2)
        \o EncodeMsSpdLegInfoLeg310(message.msSpdLegInfoLeg3)

DecodeSpOrderRejectedMessage(bytes) ==
    LET token1 == ReadBytes(bytes, 4) IN IF ~token1.ok THEN Fail ELSE
    LET orderNumber1 == ReadBytes(token1.rest, 8) IN IF ~orderNumber1.ok THEN Fail ELSE
    LET bookType1 == ReadBytes(orderNumber1.rest, 2) IN IF ~bookType1.ok THEN Fail ELSE
    LET buySell1 == ReadBytes(bookType1.rest, 2) IN IF ~buySell1.ok THEN Fail ELSE
    LET totalVolRemaining1 == ReadBytes(buySell1.rest, 4) IN IF ~totalVolRemaining1.ok THEN Fail ELSE
    LET volume1 == ReadBytes(totalVolRemaining1.rest, 4) IN IF ~volume1.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(volume1.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET traderId1 == ReadBytes(stOrderFlags.rest, 4) IN IF ~traderId1.ok THEN Fail ELSE
    LET nnfField == ReadBytes(traderId1.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET algoId == ReadBytes(nnfField.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET activityTimeInNanos == ReadBytes(algoId.rest, 8) IN IF ~activityTimeInNanos.ok THEN Fail ELSE
    LET pan == ReadBytes(activityTimeInNanos.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET accountNumber1 == ReadBytes(pan.rest, 10) IN IF ~accountNumber1.ok THEN Fail ELSE
    LET proClient1 == ReadBytes(accountNumber1.rest, 1) IN IF ~proClient1.ok THEN Fail ELSE
    LET segmentChar1 == ReadBytes(proClient1.rest, 1) IN IF ~segmentChar1.ok THEN Fail ELSE
    LET openClose1 == ReadBytes(segmentChar1.rest, 1) IN IF ~openClose1.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(openClose1.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET settlor1 == ReadBytes(reserved1.rest, 12) IN IF ~settlor1.ok THEN Fail ELSE
    LET priceDiff == ReadBytes(settlor1.rest, 4) IN IF ~priceDiff.ok THEN Fail ELSE
    LET referenceId == ReadBytes(priceDiff.rest, 4) IN IF ~referenceId.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(referenceId.rest, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET msSpdLegInfoLeg2 == DecodeMsSpdLegInfoLeg210(reasonCode.rest) IN IF ~msSpdLegInfoLeg2.ok THEN Fail ELSE
    LET msSpdLegInfoLeg3 == DecodeMsSpdLegInfoLeg310(msSpdLegInfoLeg2.rest) IN IF ~msSpdLegInfoLeg3.ok THEN Fail ELSE
    Ok([ token1              |-> token1.value,
         orderNumber1        |-> orderNumber1.value,
         bookType1           |-> bookType1.value,
         buySell1            |-> buySell1.value,
         totalVolRemaining1  |-> totalVolRemaining1.value,
         volume1             |-> volume1.value,
         stOrderFlags        |-> stOrderFlags.value,
         traderId1           |-> traderId1.value,
         nnfField            |-> nnfField.value,
         algoId              |-> algoId.value,
         activityTimeInNanos |-> activityTimeInNanos.value,
         pan                 |-> pan.value,
         accountNumber1      |-> accountNumber1.value,
         proClient1          |-> proClient1.value,
         segmentChar1        |-> segmentChar1.value,
         openClose1          |-> openClose1.value,
         reserved1           |-> reserved1.value,
         settlor1            |-> settlor1.value,
         priceDiff           |-> priceDiff.value,
         referenceId         |-> referenceId.value,
         reasonCode          |-> reasonCode.value,
         msSpdLegInfoLeg2    |-> msSpdLegInfoLeg2.value,
         msSpdLegInfoLeg3    |-> msSpdLegInfoLeg3.value ], msSpdLegInfoLeg3.rest)

ZeroSpOrderRejectedMessage ==
    [ token1              |-> [i \in 1 .. 4 |-> 0],
      orderNumber1        |-> [i \in 1 .. 8 |-> 0],
      bookType1           |-> [i \in 1 .. 2 |-> 0],
      buySell1            |-> [i \in 1 .. 2 |-> 0],
      totalVolRemaining1  |-> [i \in 1 .. 4 |-> 0],
      volume1             |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags        |-> [i \in 1 .. 2 |-> 0],
      traderId1           |-> [i \in 1 .. 4 |-> 0],
      nnfField            |-> [i \in 1 .. 8 |-> 0],
      algoId              |-> [i \in 1 .. 4 |-> 0],
      activityTimeInNanos |-> [i \in 1 .. 8 |-> 0],
      pan                 |-> [i \in 1 .. 10 |-> 0],
      accountNumber1      |-> [i \in 1 .. 10 |-> 0],
      proClient1          |-> [i \in 1 .. 1 |-> 0],
      segmentChar1        |-> [i \in 1 .. 1 |-> 0],
      openClose1          |-> [i \in 1 .. 1 |-> 0],
      reserved1           |-> [i \in 1 .. 1 |-> 0],
      settlor1            |-> [i \in 1 .. 12 |-> 0],
      priceDiff           |-> [i \in 1 .. 4 |-> 0],
      referenceId         |-> [i \in 1 .. 4 |-> 0],
      reasonCode          |-> [i \in 1 .. 2 |-> 0],
      msSpdLegInfoLeg2    |-> ZeroMsSpdLegInfoLeg210,
      msSpdLegInfoLeg3    |-> ZeroMsSpdLegInfoLeg310 ]

(* Sp Order Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedSpOrderRejectedMessage ==
    { ZeroSpOrderRejectedMessage }
        \cup { [ZeroSpOrderRejectedMessage EXCEPT !.token1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderRejectedMessage EXCEPT !.orderNumber1 = one] : one \in Sample(8) }
        \cup { [ZeroSpOrderRejectedMessage EXCEPT !.bookType1 = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderRejectedMessage EXCEPT !.buySell1 = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderRejectedMessage EXCEPT !.totalVolRemaining1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderRejectedMessage EXCEPT !.volume1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderRejectedMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderRejectedMessage EXCEPT !.traderId1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderRejectedMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroSpOrderRejectedMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderRejectedMessage EXCEPT !.activityTimeInNanos = one] : one \in Sample(8) }
        \cup { [ZeroSpOrderRejectedMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroSpOrderRejectedMessage EXCEPT !.accountNumber1 = one] : one \in Sample(10) }
        \cup { [ZeroSpOrderRejectedMessage EXCEPT !.proClient1 = one] : one \in Sample(1) }
        \cup { [ZeroSpOrderRejectedMessage EXCEPT !.segmentChar1 = one] : one \in Sample(1) }
        \cup { [ZeroSpOrderRejectedMessage EXCEPT !.openClose1 = one] : one \in Sample(1) }
        \cup { [ZeroSpOrderRejectedMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroSpOrderRejectedMessage EXCEPT !.settlor1 = one] : one \in Sample(12) }
        \cup { [ZeroSpOrderRejectedMessage EXCEPT !.priceDiff = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderRejectedMessage EXCEPT !.referenceId = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderRejectedMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderRejectedMessage EXCEPT !.msSpdLegInfoLeg2 = one] : one \in CheckedMsSpdLegInfoLeg210 }
        \cup { [ZeroSpOrderRejectedMessage EXCEPT !.msSpdLegInfoLeg3 = one] : one \in CheckedMsSpdLegInfoLeg310 }

(***************************************************************************)
(* Ms Spd Leg Info Leg 2: 18 bytes                                         *)
(***************************************************************************)

MsSpdLegInfoLeg211 ==
    [ token2             : Sample(4),
      buySell2           : Sample(2),
      totalVolRemaining2 : Sample(4),
      volume2            : Sample(4),
      stOrderFlags       : Sample(2),
      openClose2         : Sample(1),
      reserved1          : Sample(1) ]

EncodeMsSpdLegInfoLeg211(message) ==
    message.token2
        \o message.buySell2
        \o message.totalVolRemaining2
        \o message.volume2
        \o message.stOrderFlags
        \o message.openClose2
        \o message.reserved1

DecodeMsSpdLegInfoLeg211(bytes) ==
    LET token2 == ReadBytes(bytes, 4) IN IF ~token2.ok THEN Fail ELSE
    LET buySell2 == ReadBytes(token2.rest, 2) IN IF ~buySell2.ok THEN Fail ELSE
    LET totalVolRemaining2 == ReadBytes(buySell2.rest, 4) IN IF ~totalVolRemaining2.ok THEN Fail ELSE
    LET volume2 == ReadBytes(totalVolRemaining2.rest, 4) IN IF ~volume2.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(volume2.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET openClose2 == ReadBytes(stOrderFlags.rest, 1) IN IF ~openClose2.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(openClose2.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ token2             |-> token2.value,
         buySell2           |-> buySell2.value,
         totalVolRemaining2 |-> totalVolRemaining2.value,
         volume2            |-> volume2.value,
         stOrderFlags       |-> stOrderFlags.value,
         openClose2         |-> openClose2.value,
         reserved1          |-> reserved1.value ], reserved1.rest)

ZeroMsSpdLegInfoLeg211 ==
    [ token2             |-> [i \in 1 .. 4 |-> 0],
      buySell2           |-> [i \in 1 .. 2 |-> 0],
      totalVolRemaining2 |-> [i \in 1 .. 4 |-> 0],
      volume2            |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags       |-> [i \in 1 .. 2 |-> 0],
      openClose2         |-> [i \in 1 .. 1 |-> 0],
      reserved1          |-> [i \in 1 .. 1 |-> 0] ]

(* Ms Spd Leg Info Leg 2 at zero, then each field in turn at the values it is checked at *)
CheckedMsSpdLegInfoLeg211 ==
    { ZeroMsSpdLegInfoLeg211 }
        \cup { [ZeroMsSpdLegInfoLeg211 EXCEPT !.token2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg211 EXCEPT !.buySell2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg211 EXCEPT !.totalVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg211 EXCEPT !.volume2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg211 EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg211 EXCEPT !.openClose2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg211 EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Ms Spd Leg Info Leg 3: 18 bytes                                         *)
(***************************************************************************)

MsSpdLegInfoLeg311 ==
    [ token2             : Sample(4),
      buySell2           : Sample(2),
      totalVolRemaining2 : Sample(4),
      volume2            : Sample(4),
      stOrderFlags       : Sample(2),
      openClose2         : Sample(1),
      reserved1          : Sample(1) ]

EncodeMsSpdLegInfoLeg311(message) ==
    message.token2
        \o message.buySell2
        \o message.totalVolRemaining2
        \o message.volume2
        \o message.stOrderFlags
        \o message.openClose2
        \o message.reserved1

DecodeMsSpdLegInfoLeg311(bytes) ==
    LET token2 == ReadBytes(bytes, 4) IN IF ~token2.ok THEN Fail ELSE
    LET buySell2 == ReadBytes(token2.rest, 2) IN IF ~buySell2.ok THEN Fail ELSE
    LET totalVolRemaining2 == ReadBytes(buySell2.rest, 4) IN IF ~totalVolRemaining2.ok THEN Fail ELSE
    LET volume2 == ReadBytes(totalVolRemaining2.rest, 4) IN IF ~volume2.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(volume2.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET openClose2 == ReadBytes(stOrderFlags.rest, 1) IN IF ~openClose2.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(openClose2.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ token2             |-> token2.value,
         buySell2           |-> buySell2.value,
         totalVolRemaining2 |-> totalVolRemaining2.value,
         volume2            |-> volume2.value,
         stOrderFlags       |-> stOrderFlags.value,
         openClose2         |-> openClose2.value,
         reserved1          |-> reserved1.value ], reserved1.rest)

ZeroMsSpdLegInfoLeg311 ==
    [ token2             |-> [i \in 1 .. 4 |-> 0],
      buySell2           |-> [i \in 1 .. 2 |-> 0],
      totalVolRemaining2 |-> [i \in 1 .. 4 |-> 0],
      volume2            |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags       |-> [i \in 1 .. 2 |-> 0],
      openClose2         |-> [i \in 1 .. 1 |-> 0],
      reserved1          |-> [i \in 1 .. 1 |-> 0] ]

(* Ms Spd Leg Info Leg 3 at zero, then each field in turn at the values it is checked at *)
CheckedMsSpdLegInfoLeg311 ==
    { ZeroMsSpdLegInfoLeg311 }
        \cup { [ZeroMsSpdLegInfoLeg311 EXCEPT !.token2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg311 EXCEPT !.buySell2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg311 EXCEPT !.totalVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg311 EXCEPT !.volume2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg311 EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg311 EXCEPT !.openClose2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg311 EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Twol Order Error Message: 132 bytes                                     *)
(***************************************************************************)

TwolOrderErrorMessage ==
    [ token1              : Sample(4),
      orderNumber1        : Sample(8),
      bookType1           : Sample(2),
      buySell1            : Sample(2),
      totalVolRemaining1  : Sample(4),
      volume1             : Sample(4),
      stOrderFlags        : Sample(2),
      traderId1           : Sample(4),
      nnfField            : Sample(8),
      algoId              : Sample(4),
      activityTimeInNanos : Sample(8),
      pan                 : Sample(10),
      accountNumber1      : Sample(10),
      proClient1          : Sample(1),
      segmentChar1        : Sample(1),
      openClose1          : Sample(1),
      reserved1           : Sample(1),
      settlor1            : Sample(12),
      priceDiff           : Sample(4),
      referenceId         : Sample(4),
      reasonCode          : Sample(2),
      msSpdLegInfoLeg2    : MsSpdLegInfoLeg211,
      msSpdLegInfoLeg3    : MsSpdLegInfoLeg311 ]

EncodeTwolOrderErrorMessage(message) ==
    message.token1
        \o message.orderNumber1
        \o message.bookType1
        \o message.buySell1
        \o message.totalVolRemaining1
        \o message.volume1
        \o message.stOrderFlags
        \o message.traderId1
        \o message.nnfField
        \o message.algoId
        \o message.activityTimeInNanos
        \o message.pan
        \o message.accountNumber1
        \o message.proClient1
        \o message.segmentChar1
        \o message.openClose1
        \o message.reserved1
        \o message.settlor1
        \o message.priceDiff
        \o message.referenceId
        \o message.reasonCode
        \o EncodeMsSpdLegInfoLeg211(message.msSpdLegInfoLeg2)
        \o EncodeMsSpdLegInfoLeg311(message.msSpdLegInfoLeg3)

DecodeTwolOrderErrorMessage(bytes) ==
    LET token1 == ReadBytes(bytes, 4) IN IF ~token1.ok THEN Fail ELSE
    LET orderNumber1 == ReadBytes(token1.rest, 8) IN IF ~orderNumber1.ok THEN Fail ELSE
    LET bookType1 == ReadBytes(orderNumber1.rest, 2) IN IF ~bookType1.ok THEN Fail ELSE
    LET buySell1 == ReadBytes(bookType1.rest, 2) IN IF ~buySell1.ok THEN Fail ELSE
    LET totalVolRemaining1 == ReadBytes(buySell1.rest, 4) IN IF ~totalVolRemaining1.ok THEN Fail ELSE
    LET volume1 == ReadBytes(totalVolRemaining1.rest, 4) IN IF ~volume1.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(volume1.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET traderId1 == ReadBytes(stOrderFlags.rest, 4) IN IF ~traderId1.ok THEN Fail ELSE
    LET nnfField == ReadBytes(traderId1.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET algoId == ReadBytes(nnfField.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET activityTimeInNanos == ReadBytes(algoId.rest, 8) IN IF ~activityTimeInNanos.ok THEN Fail ELSE
    LET pan == ReadBytes(activityTimeInNanos.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET accountNumber1 == ReadBytes(pan.rest, 10) IN IF ~accountNumber1.ok THEN Fail ELSE
    LET proClient1 == ReadBytes(accountNumber1.rest, 1) IN IF ~proClient1.ok THEN Fail ELSE
    LET segmentChar1 == ReadBytes(proClient1.rest, 1) IN IF ~segmentChar1.ok THEN Fail ELSE
    LET openClose1 == ReadBytes(segmentChar1.rest, 1) IN IF ~openClose1.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(openClose1.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET settlor1 == ReadBytes(reserved1.rest, 12) IN IF ~settlor1.ok THEN Fail ELSE
    LET priceDiff == ReadBytes(settlor1.rest, 4) IN IF ~priceDiff.ok THEN Fail ELSE
    LET referenceId == ReadBytes(priceDiff.rest, 4) IN IF ~referenceId.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(referenceId.rest, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET msSpdLegInfoLeg2 == DecodeMsSpdLegInfoLeg211(reasonCode.rest) IN IF ~msSpdLegInfoLeg2.ok THEN Fail ELSE
    LET msSpdLegInfoLeg3 == DecodeMsSpdLegInfoLeg311(msSpdLegInfoLeg2.rest) IN IF ~msSpdLegInfoLeg3.ok THEN Fail ELSE
    Ok([ token1              |-> token1.value,
         orderNumber1        |-> orderNumber1.value,
         bookType1           |-> bookType1.value,
         buySell1            |-> buySell1.value,
         totalVolRemaining1  |-> totalVolRemaining1.value,
         volume1             |-> volume1.value,
         stOrderFlags        |-> stOrderFlags.value,
         traderId1           |-> traderId1.value,
         nnfField            |-> nnfField.value,
         algoId              |-> algoId.value,
         activityTimeInNanos |-> activityTimeInNanos.value,
         pan                 |-> pan.value,
         accountNumber1      |-> accountNumber1.value,
         proClient1          |-> proClient1.value,
         segmentChar1        |-> segmentChar1.value,
         openClose1          |-> openClose1.value,
         reserved1           |-> reserved1.value,
         settlor1            |-> settlor1.value,
         priceDiff           |-> priceDiff.value,
         referenceId         |-> referenceId.value,
         reasonCode          |-> reasonCode.value,
         msSpdLegInfoLeg2    |-> msSpdLegInfoLeg2.value,
         msSpdLegInfoLeg3    |-> msSpdLegInfoLeg3.value ], msSpdLegInfoLeg3.rest)

ZeroTwolOrderErrorMessage ==
    [ token1              |-> [i \in 1 .. 4 |-> 0],
      orderNumber1        |-> [i \in 1 .. 8 |-> 0],
      bookType1           |-> [i \in 1 .. 2 |-> 0],
      buySell1            |-> [i \in 1 .. 2 |-> 0],
      totalVolRemaining1  |-> [i \in 1 .. 4 |-> 0],
      volume1             |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags        |-> [i \in 1 .. 2 |-> 0],
      traderId1           |-> [i \in 1 .. 4 |-> 0],
      nnfField            |-> [i \in 1 .. 8 |-> 0],
      algoId              |-> [i \in 1 .. 4 |-> 0],
      activityTimeInNanos |-> [i \in 1 .. 8 |-> 0],
      pan                 |-> [i \in 1 .. 10 |-> 0],
      accountNumber1      |-> [i \in 1 .. 10 |-> 0],
      proClient1          |-> [i \in 1 .. 1 |-> 0],
      segmentChar1        |-> [i \in 1 .. 1 |-> 0],
      openClose1          |-> [i \in 1 .. 1 |-> 0],
      reserved1           |-> [i \in 1 .. 1 |-> 0],
      settlor1            |-> [i \in 1 .. 12 |-> 0],
      priceDiff           |-> [i \in 1 .. 4 |-> 0],
      referenceId         |-> [i \in 1 .. 4 |-> 0],
      reasonCode          |-> [i \in 1 .. 2 |-> 0],
      msSpdLegInfoLeg2    |-> ZeroMsSpdLegInfoLeg211,
      msSpdLegInfoLeg3    |-> ZeroMsSpdLegInfoLeg311 ]

(* Twol Order Error Message at zero, then each field in turn at the values it is checked at *)
CheckedTwolOrderErrorMessage ==
    { ZeroTwolOrderErrorMessage }
        \cup { [ZeroTwolOrderErrorMessage EXCEPT !.token1 = one] : one \in Sample(4) }
        \cup { [ZeroTwolOrderErrorMessage EXCEPT !.orderNumber1 = one] : one \in Sample(8) }
        \cup { [ZeroTwolOrderErrorMessage EXCEPT !.bookType1 = one] : one \in Sample(2) }
        \cup { [ZeroTwolOrderErrorMessage EXCEPT !.buySell1 = one] : one \in Sample(2) }
        \cup { [ZeroTwolOrderErrorMessage EXCEPT !.totalVolRemaining1 = one] : one \in Sample(4) }
        \cup { [ZeroTwolOrderErrorMessage EXCEPT !.volume1 = one] : one \in Sample(4) }
        \cup { [ZeroTwolOrderErrorMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroTwolOrderErrorMessage EXCEPT !.traderId1 = one] : one \in Sample(4) }
        \cup { [ZeroTwolOrderErrorMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroTwolOrderErrorMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroTwolOrderErrorMessage EXCEPT !.activityTimeInNanos = one] : one \in Sample(8) }
        \cup { [ZeroTwolOrderErrorMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroTwolOrderErrorMessage EXCEPT !.accountNumber1 = one] : one \in Sample(10) }
        \cup { [ZeroTwolOrderErrorMessage EXCEPT !.proClient1 = one] : one \in Sample(1) }
        \cup { [ZeroTwolOrderErrorMessage EXCEPT !.segmentChar1 = one] : one \in Sample(1) }
        \cup { [ZeroTwolOrderErrorMessage EXCEPT !.openClose1 = one] : one \in Sample(1) }
        \cup { [ZeroTwolOrderErrorMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTwolOrderErrorMessage EXCEPT !.settlor1 = one] : one \in Sample(12) }
        \cup { [ZeroTwolOrderErrorMessage EXCEPT !.priceDiff = one] : one \in Sample(4) }
        \cup { [ZeroTwolOrderErrorMessage EXCEPT !.referenceId = one] : one \in Sample(4) }
        \cup { [ZeroTwolOrderErrorMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroTwolOrderErrorMessage EXCEPT !.msSpdLegInfoLeg2 = one] : one \in CheckedMsSpdLegInfoLeg211 }
        \cup { [ZeroTwolOrderErrorMessage EXCEPT !.msSpdLegInfoLeg3 = one] : one \in CheckedMsSpdLegInfoLeg311 }

(***************************************************************************)
(* Ms Spd Leg Info Leg 2: 18 bytes                                         *)
(***************************************************************************)

MsSpdLegInfoLeg212 ==
    [ token2             : Sample(4),
      buySell2           : Sample(2),
      totalVolRemaining2 : Sample(4),
      volume2            : Sample(4),
      stOrderFlags       : Sample(2),
      openClose2         : Sample(1),
      reserved1          : Sample(1) ]

EncodeMsSpdLegInfoLeg212(message) ==
    message.token2
        \o message.buySell2
        \o message.totalVolRemaining2
        \o message.volume2
        \o message.stOrderFlags
        \o message.openClose2
        \o message.reserved1

DecodeMsSpdLegInfoLeg212(bytes) ==
    LET token2 == ReadBytes(bytes, 4) IN IF ~token2.ok THEN Fail ELSE
    LET buySell2 == ReadBytes(token2.rest, 2) IN IF ~buySell2.ok THEN Fail ELSE
    LET totalVolRemaining2 == ReadBytes(buySell2.rest, 4) IN IF ~totalVolRemaining2.ok THEN Fail ELSE
    LET volume2 == ReadBytes(totalVolRemaining2.rest, 4) IN IF ~volume2.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(volume2.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET openClose2 == ReadBytes(stOrderFlags.rest, 1) IN IF ~openClose2.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(openClose2.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ token2             |-> token2.value,
         buySell2           |-> buySell2.value,
         totalVolRemaining2 |-> totalVolRemaining2.value,
         volume2            |-> volume2.value,
         stOrderFlags       |-> stOrderFlags.value,
         openClose2         |-> openClose2.value,
         reserved1          |-> reserved1.value ], reserved1.rest)

ZeroMsSpdLegInfoLeg212 ==
    [ token2             |-> [i \in 1 .. 4 |-> 0],
      buySell2           |-> [i \in 1 .. 2 |-> 0],
      totalVolRemaining2 |-> [i \in 1 .. 4 |-> 0],
      volume2            |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags       |-> [i \in 1 .. 2 |-> 0],
      openClose2         |-> [i \in 1 .. 1 |-> 0],
      reserved1          |-> [i \in 1 .. 1 |-> 0] ]

(* Ms Spd Leg Info Leg 2 at zero, then each field in turn at the values it is checked at *)
CheckedMsSpdLegInfoLeg212 ==
    { ZeroMsSpdLegInfoLeg212 }
        \cup { [ZeroMsSpdLegInfoLeg212 EXCEPT !.token2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg212 EXCEPT !.buySell2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg212 EXCEPT !.totalVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg212 EXCEPT !.volume2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg212 EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg212 EXCEPT !.openClose2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg212 EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Ms Spd Leg Info Leg 3: 18 bytes                                         *)
(***************************************************************************)

MsSpdLegInfoLeg312 ==
    [ token2             : Sample(4),
      buySell2           : Sample(2),
      totalVolRemaining2 : Sample(4),
      volume2            : Sample(4),
      stOrderFlags       : Sample(2),
      openClose2         : Sample(1),
      reserved1          : Sample(1) ]

EncodeMsSpdLegInfoLeg312(message) ==
    message.token2
        \o message.buySell2
        \o message.totalVolRemaining2
        \o message.volume2
        \o message.stOrderFlags
        \o message.openClose2
        \o message.reserved1

DecodeMsSpdLegInfoLeg312(bytes) ==
    LET token2 == ReadBytes(bytes, 4) IN IF ~token2.ok THEN Fail ELSE
    LET buySell2 == ReadBytes(token2.rest, 2) IN IF ~buySell2.ok THEN Fail ELSE
    LET totalVolRemaining2 == ReadBytes(buySell2.rest, 4) IN IF ~totalVolRemaining2.ok THEN Fail ELSE
    LET volume2 == ReadBytes(totalVolRemaining2.rest, 4) IN IF ~volume2.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(volume2.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET openClose2 == ReadBytes(stOrderFlags.rest, 1) IN IF ~openClose2.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(openClose2.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ token2             |-> token2.value,
         buySell2           |-> buySell2.value,
         totalVolRemaining2 |-> totalVolRemaining2.value,
         volume2            |-> volume2.value,
         stOrderFlags       |-> stOrderFlags.value,
         openClose2         |-> openClose2.value,
         reserved1          |-> reserved1.value ], reserved1.rest)

ZeroMsSpdLegInfoLeg312 ==
    [ token2             |-> [i \in 1 .. 4 |-> 0],
      buySell2           |-> [i \in 1 .. 2 |-> 0],
      totalVolRemaining2 |-> [i \in 1 .. 4 |-> 0],
      volume2            |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags       |-> [i \in 1 .. 2 |-> 0],
      openClose2         |-> [i \in 1 .. 1 |-> 0],
      reserved1          |-> [i \in 1 .. 1 |-> 0] ]

(* Ms Spd Leg Info Leg 3 at zero, then each field in turn at the values it is checked at *)
CheckedMsSpdLegInfoLeg312 ==
    { ZeroMsSpdLegInfoLeg312 }
        \cup { [ZeroMsSpdLegInfoLeg312 EXCEPT !.token2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg312 EXCEPT !.buySell2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg312 EXCEPT !.totalVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg312 EXCEPT !.volume2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg312 EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg312 EXCEPT !.openClose2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg312 EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Thrl Order Error Message: 132 bytes                                     *)
(***************************************************************************)

ThrlOrderErrorMessage ==
    [ token1              : Sample(4),
      orderNumber1        : Sample(8),
      bookType1           : Sample(2),
      buySell1            : Sample(2),
      totalVolRemaining1  : Sample(4),
      volume1             : Sample(4),
      stOrderFlags        : Sample(2),
      traderId1           : Sample(4),
      nnfField            : Sample(8),
      algoId              : Sample(4),
      activityTimeInNanos : Sample(8),
      pan                 : Sample(10),
      accountNumber1      : Sample(10),
      proClient1          : Sample(1),
      segmentChar1        : Sample(1),
      openClose1          : Sample(1),
      reserved1           : Sample(1),
      settlor1            : Sample(12),
      priceDiff           : Sample(4),
      referenceId         : Sample(4),
      reasonCode          : Sample(2),
      msSpdLegInfoLeg2    : MsSpdLegInfoLeg212,
      msSpdLegInfoLeg3    : MsSpdLegInfoLeg312 ]

EncodeThrlOrderErrorMessage(message) ==
    message.token1
        \o message.orderNumber1
        \o message.bookType1
        \o message.buySell1
        \o message.totalVolRemaining1
        \o message.volume1
        \o message.stOrderFlags
        \o message.traderId1
        \o message.nnfField
        \o message.algoId
        \o message.activityTimeInNanos
        \o message.pan
        \o message.accountNumber1
        \o message.proClient1
        \o message.segmentChar1
        \o message.openClose1
        \o message.reserved1
        \o message.settlor1
        \o message.priceDiff
        \o message.referenceId
        \o message.reasonCode
        \o EncodeMsSpdLegInfoLeg212(message.msSpdLegInfoLeg2)
        \o EncodeMsSpdLegInfoLeg312(message.msSpdLegInfoLeg3)

DecodeThrlOrderErrorMessage(bytes) ==
    LET token1 == ReadBytes(bytes, 4) IN IF ~token1.ok THEN Fail ELSE
    LET orderNumber1 == ReadBytes(token1.rest, 8) IN IF ~orderNumber1.ok THEN Fail ELSE
    LET bookType1 == ReadBytes(orderNumber1.rest, 2) IN IF ~bookType1.ok THEN Fail ELSE
    LET buySell1 == ReadBytes(bookType1.rest, 2) IN IF ~buySell1.ok THEN Fail ELSE
    LET totalVolRemaining1 == ReadBytes(buySell1.rest, 4) IN IF ~totalVolRemaining1.ok THEN Fail ELSE
    LET volume1 == ReadBytes(totalVolRemaining1.rest, 4) IN IF ~volume1.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(volume1.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET traderId1 == ReadBytes(stOrderFlags.rest, 4) IN IF ~traderId1.ok THEN Fail ELSE
    LET nnfField == ReadBytes(traderId1.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET algoId == ReadBytes(nnfField.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET activityTimeInNanos == ReadBytes(algoId.rest, 8) IN IF ~activityTimeInNanos.ok THEN Fail ELSE
    LET pan == ReadBytes(activityTimeInNanos.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET accountNumber1 == ReadBytes(pan.rest, 10) IN IF ~accountNumber1.ok THEN Fail ELSE
    LET proClient1 == ReadBytes(accountNumber1.rest, 1) IN IF ~proClient1.ok THEN Fail ELSE
    LET segmentChar1 == ReadBytes(proClient1.rest, 1) IN IF ~segmentChar1.ok THEN Fail ELSE
    LET openClose1 == ReadBytes(segmentChar1.rest, 1) IN IF ~openClose1.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(openClose1.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET settlor1 == ReadBytes(reserved1.rest, 12) IN IF ~settlor1.ok THEN Fail ELSE
    LET priceDiff == ReadBytes(settlor1.rest, 4) IN IF ~priceDiff.ok THEN Fail ELSE
    LET referenceId == ReadBytes(priceDiff.rest, 4) IN IF ~referenceId.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(referenceId.rest, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET msSpdLegInfoLeg2 == DecodeMsSpdLegInfoLeg212(reasonCode.rest) IN IF ~msSpdLegInfoLeg2.ok THEN Fail ELSE
    LET msSpdLegInfoLeg3 == DecodeMsSpdLegInfoLeg312(msSpdLegInfoLeg2.rest) IN IF ~msSpdLegInfoLeg3.ok THEN Fail ELSE
    Ok([ token1              |-> token1.value,
         orderNumber1        |-> orderNumber1.value,
         bookType1           |-> bookType1.value,
         buySell1            |-> buySell1.value,
         totalVolRemaining1  |-> totalVolRemaining1.value,
         volume1             |-> volume1.value,
         stOrderFlags        |-> stOrderFlags.value,
         traderId1           |-> traderId1.value,
         nnfField            |-> nnfField.value,
         algoId              |-> algoId.value,
         activityTimeInNanos |-> activityTimeInNanos.value,
         pan                 |-> pan.value,
         accountNumber1      |-> accountNumber1.value,
         proClient1          |-> proClient1.value,
         segmentChar1        |-> segmentChar1.value,
         openClose1          |-> openClose1.value,
         reserved1           |-> reserved1.value,
         settlor1            |-> settlor1.value,
         priceDiff           |-> priceDiff.value,
         referenceId         |-> referenceId.value,
         reasonCode          |-> reasonCode.value,
         msSpdLegInfoLeg2    |-> msSpdLegInfoLeg2.value,
         msSpdLegInfoLeg3    |-> msSpdLegInfoLeg3.value ], msSpdLegInfoLeg3.rest)

ZeroThrlOrderErrorMessage ==
    [ token1              |-> [i \in 1 .. 4 |-> 0],
      orderNumber1        |-> [i \in 1 .. 8 |-> 0],
      bookType1           |-> [i \in 1 .. 2 |-> 0],
      buySell1            |-> [i \in 1 .. 2 |-> 0],
      totalVolRemaining1  |-> [i \in 1 .. 4 |-> 0],
      volume1             |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags        |-> [i \in 1 .. 2 |-> 0],
      traderId1           |-> [i \in 1 .. 4 |-> 0],
      nnfField            |-> [i \in 1 .. 8 |-> 0],
      algoId              |-> [i \in 1 .. 4 |-> 0],
      activityTimeInNanos |-> [i \in 1 .. 8 |-> 0],
      pan                 |-> [i \in 1 .. 10 |-> 0],
      accountNumber1      |-> [i \in 1 .. 10 |-> 0],
      proClient1          |-> [i \in 1 .. 1 |-> 0],
      segmentChar1        |-> [i \in 1 .. 1 |-> 0],
      openClose1          |-> [i \in 1 .. 1 |-> 0],
      reserved1           |-> [i \in 1 .. 1 |-> 0],
      settlor1            |-> [i \in 1 .. 12 |-> 0],
      priceDiff           |-> [i \in 1 .. 4 |-> 0],
      referenceId         |-> [i \in 1 .. 4 |-> 0],
      reasonCode          |-> [i \in 1 .. 2 |-> 0],
      msSpdLegInfoLeg2    |-> ZeroMsSpdLegInfoLeg212,
      msSpdLegInfoLeg3    |-> ZeroMsSpdLegInfoLeg312 ]

(* Thrl Order Error Message at zero, then each field in turn at the values it is checked at *)
CheckedThrlOrderErrorMessage ==
    { ZeroThrlOrderErrorMessage }
        \cup { [ZeroThrlOrderErrorMessage EXCEPT !.token1 = one] : one \in Sample(4) }
        \cup { [ZeroThrlOrderErrorMessage EXCEPT !.orderNumber1 = one] : one \in Sample(8) }
        \cup { [ZeroThrlOrderErrorMessage EXCEPT !.bookType1 = one] : one \in Sample(2) }
        \cup { [ZeroThrlOrderErrorMessage EXCEPT !.buySell1 = one] : one \in Sample(2) }
        \cup { [ZeroThrlOrderErrorMessage EXCEPT !.totalVolRemaining1 = one] : one \in Sample(4) }
        \cup { [ZeroThrlOrderErrorMessage EXCEPT !.volume1 = one] : one \in Sample(4) }
        \cup { [ZeroThrlOrderErrorMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroThrlOrderErrorMessage EXCEPT !.traderId1 = one] : one \in Sample(4) }
        \cup { [ZeroThrlOrderErrorMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroThrlOrderErrorMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroThrlOrderErrorMessage EXCEPT !.activityTimeInNanos = one] : one \in Sample(8) }
        \cup { [ZeroThrlOrderErrorMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroThrlOrderErrorMessage EXCEPT !.accountNumber1 = one] : one \in Sample(10) }
        \cup { [ZeroThrlOrderErrorMessage EXCEPT !.proClient1 = one] : one \in Sample(1) }
        \cup { [ZeroThrlOrderErrorMessage EXCEPT !.segmentChar1 = one] : one \in Sample(1) }
        \cup { [ZeroThrlOrderErrorMessage EXCEPT !.openClose1 = one] : one \in Sample(1) }
        \cup { [ZeroThrlOrderErrorMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroThrlOrderErrorMessage EXCEPT !.settlor1 = one] : one \in Sample(12) }
        \cup { [ZeroThrlOrderErrorMessage EXCEPT !.priceDiff = one] : one \in Sample(4) }
        \cup { [ZeroThrlOrderErrorMessage EXCEPT !.referenceId = one] : one \in Sample(4) }
        \cup { [ZeroThrlOrderErrorMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroThrlOrderErrorMessage EXCEPT !.msSpdLegInfoLeg2 = one] : one \in CheckedMsSpdLegInfoLeg212 }
        \cup { [ZeroThrlOrderErrorMessage EXCEPT !.msSpdLegInfoLeg3 = one] : one \in CheckedMsSpdLegInfoLeg312 }

(***************************************************************************)
(* Ms Spd Leg Info Leg 2: 18 bytes                                         *)
(***************************************************************************)

MsSpdLegInfoLeg213 ==
    [ token2             : Sample(4),
      buySell2           : Sample(2),
      totalVolRemaining2 : Sample(4),
      volume2            : Sample(4),
      stOrderFlags       : Sample(2),
      openClose2         : Sample(1),
      reserved1          : Sample(1) ]

EncodeMsSpdLegInfoLeg213(message) ==
    message.token2
        \o message.buySell2
        \o message.totalVolRemaining2
        \o message.volume2
        \o message.stOrderFlags
        \o message.openClose2
        \o message.reserved1

DecodeMsSpdLegInfoLeg213(bytes) ==
    LET token2 == ReadBytes(bytes, 4) IN IF ~token2.ok THEN Fail ELSE
    LET buySell2 == ReadBytes(token2.rest, 2) IN IF ~buySell2.ok THEN Fail ELSE
    LET totalVolRemaining2 == ReadBytes(buySell2.rest, 4) IN IF ~totalVolRemaining2.ok THEN Fail ELSE
    LET volume2 == ReadBytes(totalVolRemaining2.rest, 4) IN IF ~volume2.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(volume2.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET openClose2 == ReadBytes(stOrderFlags.rest, 1) IN IF ~openClose2.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(openClose2.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ token2             |-> token2.value,
         buySell2           |-> buySell2.value,
         totalVolRemaining2 |-> totalVolRemaining2.value,
         volume2            |-> volume2.value,
         stOrderFlags       |-> stOrderFlags.value,
         openClose2         |-> openClose2.value,
         reserved1          |-> reserved1.value ], reserved1.rest)

ZeroMsSpdLegInfoLeg213 ==
    [ token2             |-> [i \in 1 .. 4 |-> 0],
      buySell2           |-> [i \in 1 .. 2 |-> 0],
      totalVolRemaining2 |-> [i \in 1 .. 4 |-> 0],
      volume2            |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags       |-> [i \in 1 .. 2 |-> 0],
      openClose2         |-> [i \in 1 .. 1 |-> 0],
      reserved1          |-> [i \in 1 .. 1 |-> 0] ]

(* Ms Spd Leg Info Leg 2 at zero, then each field in turn at the values it is checked at *)
CheckedMsSpdLegInfoLeg213 ==
    { ZeroMsSpdLegInfoLeg213 }
        \cup { [ZeroMsSpdLegInfoLeg213 EXCEPT !.token2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg213 EXCEPT !.buySell2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg213 EXCEPT !.totalVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg213 EXCEPT !.volume2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg213 EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg213 EXCEPT !.openClose2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg213 EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Ms Spd Leg Info Leg 3: 18 bytes                                         *)
(***************************************************************************)

MsSpdLegInfoLeg313 ==
    [ token2             : Sample(4),
      buySell2           : Sample(2),
      totalVolRemaining2 : Sample(4),
      volume2            : Sample(4),
      stOrderFlags       : Sample(2),
      openClose2         : Sample(1),
      reserved1          : Sample(1) ]

EncodeMsSpdLegInfoLeg313(message) ==
    message.token2
        \o message.buySell2
        \o message.totalVolRemaining2
        \o message.volume2
        \o message.stOrderFlags
        \o message.openClose2
        \o message.reserved1

DecodeMsSpdLegInfoLeg313(bytes) ==
    LET token2 == ReadBytes(bytes, 4) IN IF ~token2.ok THEN Fail ELSE
    LET buySell2 == ReadBytes(token2.rest, 2) IN IF ~buySell2.ok THEN Fail ELSE
    LET totalVolRemaining2 == ReadBytes(buySell2.rest, 4) IN IF ~totalVolRemaining2.ok THEN Fail ELSE
    LET volume2 == ReadBytes(totalVolRemaining2.rest, 4) IN IF ~volume2.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(volume2.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET openClose2 == ReadBytes(stOrderFlags.rest, 1) IN IF ~openClose2.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(openClose2.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ token2             |-> token2.value,
         buySell2           |-> buySell2.value,
         totalVolRemaining2 |-> totalVolRemaining2.value,
         volume2            |-> volume2.value,
         stOrderFlags       |-> stOrderFlags.value,
         openClose2         |-> openClose2.value,
         reserved1          |-> reserved1.value ], reserved1.rest)

ZeroMsSpdLegInfoLeg313 ==
    [ token2             |-> [i \in 1 .. 4 |-> 0],
      buySell2           |-> [i \in 1 .. 2 |-> 0],
      totalVolRemaining2 |-> [i \in 1 .. 4 |-> 0],
      volume2            |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags       |-> [i \in 1 .. 2 |-> 0],
      openClose2         |-> [i \in 1 .. 1 |-> 0],
      reserved1          |-> [i \in 1 .. 1 |-> 0] ]

(* Ms Spd Leg Info Leg 3 at zero, then each field in turn at the values it is checked at *)
CheckedMsSpdLegInfoLeg313 ==
    { ZeroMsSpdLegInfoLeg313 }
        \cup { [ZeroMsSpdLegInfoLeg313 EXCEPT !.token2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg313 EXCEPT !.buySell2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg313 EXCEPT !.totalVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg313 EXCEPT !.volume2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg313 EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg313 EXCEPT !.openClose2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg313 EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Batch Spread Cxl Out Message: 132 bytes                                 *)
(***************************************************************************)

BatchSpreadCxlOutMessage ==
    [ token1              : Sample(4),
      orderNumber1        : Sample(8),
      bookType1           : Sample(2),
      buySell1            : Sample(2),
      totalVolRemaining1  : Sample(4),
      volume1             : Sample(4),
      stOrderFlags        : Sample(2),
      traderId1           : Sample(4),
      nnfField            : Sample(8),
      algoId              : Sample(4),
      activityTimeInNanos : Sample(8),
      pan                 : Sample(10),
      accountNumber1      : Sample(10),
      proClient1          : Sample(1),
      segmentChar1        : Sample(1),
      openClose1          : Sample(1),
      reserved1           : Sample(1),
      settlor1            : Sample(12),
      priceDiff           : Sample(4),
      referenceId         : Sample(4),
      reasonCode          : Sample(2),
      msSpdLegInfoLeg2    : MsSpdLegInfoLeg213,
      msSpdLegInfoLeg3    : MsSpdLegInfoLeg313 ]

EncodeBatchSpreadCxlOutMessage(message) ==
    message.token1
        \o message.orderNumber1
        \o message.bookType1
        \o message.buySell1
        \o message.totalVolRemaining1
        \o message.volume1
        \o message.stOrderFlags
        \o message.traderId1
        \o message.nnfField
        \o message.algoId
        \o message.activityTimeInNanos
        \o message.pan
        \o message.accountNumber1
        \o message.proClient1
        \o message.segmentChar1
        \o message.openClose1
        \o message.reserved1
        \o message.settlor1
        \o message.priceDiff
        \o message.referenceId
        \o message.reasonCode
        \o EncodeMsSpdLegInfoLeg213(message.msSpdLegInfoLeg2)
        \o EncodeMsSpdLegInfoLeg313(message.msSpdLegInfoLeg3)

DecodeBatchSpreadCxlOutMessage(bytes) ==
    LET token1 == ReadBytes(bytes, 4) IN IF ~token1.ok THEN Fail ELSE
    LET orderNumber1 == ReadBytes(token1.rest, 8) IN IF ~orderNumber1.ok THEN Fail ELSE
    LET bookType1 == ReadBytes(orderNumber1.rest, 2) IN IF ~bookType1.ok THEN Fail ELSE
    LET buySell1 == ReadBytes(bookType1.rest, 2) IN IF ~buySell1.ok THEN Fail ELSE
    LET totalVolRemaining1 == ReadBytes(buySell1.rest, 4) IN IF ~totalVolRemaining1.ok THEN Fail ELSE
    LET volume1 == ReadBytes(totalVolRemaining1.rest, 4) IN IF ~volume1.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(volume1.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET traderId1 == ReadBytes(stOrderFlags.rest, 4) IN IF ~traderId1.ok THEN Fail ELSE
    LET nnfField == ReadBytes(traderId1.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET algoId == ReadBytes(nnfField.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET activityTimeInNanos == ReadBytes(algoId.rest, 8) IN IF ~activityTimeInNanos.ok THEN Fail ELSE
    LET pan == ReadBytes(activityTimeInNanos.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET accountNumber1 == ReadBytes(pan.rest, 10) IN IF ~accountNumber1.ok THEN Fail ELSE
    LET proClient1 == ReadBytes(accountNumber1.rest, 1) IN IF ~proClient1.ok THEN Fail ELSE
    LET segmentChar1 == ReadBytes(proClient1.rest, 1) IN IF ~segmentChar1.ok THEN Fail ELSE
    LET openClose1 == ReadBytes(segmentChar1.rest, 1) IN IF ~openClose1.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(openClose1.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET settlor1 == ReadBytes(reserved1.rest, 12) IN IF ~settlor1.ok THEN Fail ELSE
    LET priceDiff == ReadBytes(settlor1.rest, 4) IN IF ~priceDiff.ok THEN Fail ELSE
    LET referenceId == ReadBytes(priceDiff.rest, 4) IN IF ~referenceId.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(referenceId.rest, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET msSpdLegInfoLeg2 == DecodeMsSpdLegInfoLeg213(reasonCode.rest) IN IF ~msSpdLegInfoLeg2.ok THEN Fail ELSE
    LET msSpdLegInfoLeg3 == DecodeMsSpdLegInfoLeg313(msSpdLegInfoLeg2.rest) IN IF ~msSpdLegInfoLeg3.ok THEN Fail ELSE
    Ok([ token1              |-> token1.value,
         orderNumber1        |-> orderNumber1.value,
         bookType1           |-> bookType1.value,
         buySell1            |-> buySell1.value,
         totalVolRemaining1  |-> totalVolRemaining1.value,
         volume1             |-> volume1.value,
         stOrderFlags        |-> stOrderFlags.value,
         traderId1           |-> traderId1.value,
         nnfField            |-> nnfField.value,
         algoId              |-> algoId.value,
         activityTimeInNanos |-> activityTimeInNanos.value,
         pan                 |-> pan.value,
         accountNumber1      |-> accountNumber1.value,
         proClient1          |-> proClient1.value,
         segmentChar1        |-> segmentChar1.value,
         openClose1          |-> openClose1.value,
         reserved1           |-> reserved1.value,
         settlor1            |-> settlor1.value,
         priceDiff           |-> priceDiff.value,
         referenceId         |-> referenceId.value,
         reasonCode          |-> reasonCode.value,
         msSpdLegInfoLeg2    |-> msSpdLegInfoLeg2.value,
         msSpdLegInfoLeg3    |-> msSpdLegInfoLeg3.value ], msSpdLegInfoLeg3.rest)

ZeroBatchSpreadCxlOutMessage ==
    [ token1              |-> [i \in 1 .. 4 |-> 0],
      orderNumber1        |-> [i \in 1 .. 8 |-> 0],
      bookType1           |-> [i \in 1 .. 2 |-> 0],
      buySell1            |-> [i \in 1 .. 2 |-> 0],
      totalVolRemaining1  |-> [i \in 1 .. 4 |-> 0],
      volume1             |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags        |-> [i \in 1 .. 2 |-> 0],
      traderId1           |-> [i \in 1 .. 4 |-> 0],
      nnfField            |-> [i \in 1 .. 8 |-> 0],
      algoId              |-> [i \in 1 .. 4 |-> 0],
      activityTimeInNanos |-> [i \in 1 .. 8 |-> 0],
      pan                 |-> [i \in 1 .. 10 |-> 0],
      accountNumber1      |-> [i \in 1 .. 10 |-> 0],
      proClient1          |-> [i \in 1 .. 1 |-> 0],
      segmentChar1        |-> [i \in 1 .. 1 |-> 0],
      openClose1          |-> [i \in 1 .. 1 |-> 0],
      reserved1           |-> [i \in 1 .. 1 |-> 0],
      settlor1            |-> [i \in 1 .. 12 |-> 0],
      priceDiff           |-> [i \in 1 .. 4 |-> 0],
      referenceId         |-> [i \in 1 .. 4 |-> 0],
      reasonCode          |-> [i \in 1 .. 2 |-> 0],
      msSpdLegInfoLeg2    |-> ZeroMsSpdLegInfoLeg213,
      msSpdLegInfoLeg3    |-> ZeroMsSpdLegInfoLeg313 ]

(* Batch Spread Cxl Out Message at zero, then each field in turn at the values it is checked at *)
CheckedBatchSpreadCxlOutMessage ==
    { ZeroBatchSpreadCxlOutMessage }
        \cup { [ZeroBatchSpreadCxlOutMessage EXCEPT !.token1 = one] : one \in Sample(4) }
        \cup { [ZeroBatchSpreadCxlOutMessage EXCEPT !.orderNumber1 = one] : one \in Sample(8) }
        \cup { [ZeroBatchSpreadCxlOutMessage EXCEPT !.bookType1 = one] : one \in Sample(2) }
        \cup { [ZeroBatchSpreadCxlOutMessage EXCEPT !.buySell1 = one] : one \in Sample(2) }
        \cup { [ZeroBatchSpreadCxlOutMessage EXCEPT !.totalVolRemaining1 = one] : one \in Sample(4) }
        \cup { [ZeroBatchSpreadCxlOutMessage EXCEPT !.volume1 = one] : one \in Sample(4) }
        \cup { [ZeroBatchSpreadCxlOutMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroBatchSpreadCxlOutMessage EXCEPT !.traderId1 = one] : one \in Sample(4) }
        \cup { [ZeroBatchSpreadCxlOutMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroBatchSpreadCxlOutMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroBatchSpreadCxlOutMessage EXCEPT !.activityTimeInNanos = one] : one \in Sample(8) }
        \cup { [ZeroBatchSpreadCxlOutMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroBatchSpreadCxlOutMessage EXCEPT !.accountNumber1 = one] : one \in Sample(10) }
        \cup { [ZeroBatchSpreadCxlOutMessage EXCEPT !.proClient1 = one] : one \in Sample(1) }
        \cup { [ZeroBatchSpreadCxlOutMessage EXCEPT !.segmentChar1 = one] : one \in Sample(1) }
        \cup { [ZeroBatchSpreadCxlOutMessage EXCEPT !.openClose1 = one] : one \in Sample(1) }
        \cup { [ZeroBatchSpreadCxlOutMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroBatchSpreadCxlOutMessage EXCEPT !.settlor1 = one] : one \in Sample(12) }
        \cup { [ZeroBatchSpreadCxlOutMessage EXCEPT !.priceDiff = one] : one \in Sample(4) }
        \cup { [ZeroBatchSpreadCxlOutMessage EXCEPT !.referenceId = one] : one \in Sample(4) }
        \cup { [ZeroBatchSpreadCxlOutMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroBatchSpreadCxlOutMessage EXCEPT !.msSpdLegInfoLeg2 = one] : one \in CheckedMsSpdLegInfoLeg213 }
        \cup { [ZeroBatchSpreadCxlOutMessage EXCEPT !.msSpdLegInfoLeg3 = one] : one \in CheckedMsSpdLegInfoLeg313 }

(***************************************************************************)
(* Server Message Payload, selected by Transaction Code                    *)
(***************************************************************************)

GrResponseMessageCode == 2401  \* 0x961
GrSecureUserRegistrationResponseMessageCode == 23009  \* 0x59e1
DcSignonOutMessageCode == 2501  \* 0x9c5
DcSignOffMessageCode == 2320  \* 0x910
DcErrorResponseTradeMessageCode == 8006  \* 0x1f46
DcErrorResponseOrderMessageCode == 9006  \* 0x232e
TradeConfirmationMessageCode == 2222  \* 0x8ae
TradeCancelConfirmMessageCode == 2282  \* 0x8ea
TradeCancelRejectMessageCode == 2286  \* 0x8ee
TradeModifyConfirmMessageCode == 2287  \* 0x8ef
TradeModifyRejectedMessageCode == 2288  \* 0x8f0
GiveupAppConfirmMessageCode == 4506  \* 0x119a
GiveupRejConfirmMessageCode == 4507  \* 0x119b
PriceConfirmationMessageCode == 2012  \* 0x7dc
OrderModRejectMessageCode == 2042  \* 0x7fa
OrderCancelRejectMessageCode == 2072  \* 0x818
OrderConfirmationMessageCode == 2073  \* 0x819
OrderModConfirmationMessageCode == 2074  \* 0x81a
OrderCancelConfirmationMessageCode == 2075  \* 0x81b
FreezeToControlMessageCode == 2170  \* 0x87a
OnStopNotificationMessageCode == 2212  \* 0x8a4
OrderErrorMessageCode == 2231  \* 0x8b7
BatchOrderCancelMessageCode == 9002  \* 0x232a
SpOrderConfirmationMessageCode == 2124  \* 0x84c
TwolOrderConfirmationMessageCode == 2125  \* 0x84d
ThrlOrderConfirmationMessageCode == 2126  \* 0x84e
SpOrderCxlRejectedMessageCode == 2127  \* 0x84f
SpOrderCxlConfirmationMessageCode == 2130  \* 0x852
TwolOrderCxlConfirmationMessageCode == 2131  \* 0x853
ThrlOrderCxlConfirmationMessageCode == 2132  \* 0x854
SpOrderModRejectMessageCode == 2133  \* 0x855
SpOrderModConfirmationMessageCode == 2136  \* 0x858
SpOrderRejectedMessageCode == 2154  \* 0x86a
TwolOrderErrorMessageCode == 2155  \* 0x86b
ThrlOrderErrorMessageCode == 2156  \* 0x86c
BatchSpreadCxlOutMessageCode == 9004  \* 0x232c

ServerMessagePayload ==
    [ tag : {GrResponseMessageCode}, body : GrResponseMessage ]
        \cup [ tag : {GrSecureUserRegistrationResponseMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {DcSignonOutMessageCode}, body : DcSignonOutMessage ]
        \cup [ tag : {DcSignOffMessageCode}, body : DcSignOffMessage ]
        \cup [ tag : {DcErrorResponseTradeMessageCode}, body : DcErrorResponseTradeMessage ]
        \cup [ tag : {DcErrorResponseOrderMessageCode}, body : DcErrorResponseOrderMessage ]
        \cup [ tag : {TradeConfirmationMessageCode}, body : TradeConfirmationMessage ]
        \cup [ tag : {TradeCancelConfirmMessageCode}, body : TradeCancelConfirmMessage ]
        \cup [ tag : {TradeCancelRejectMessageCode}, body : TradeCancelRejectMessage ]
        \cup [ tag : {TradeModifyConfirmMessageCode}, body : TradeModifyConfirmMessage ]
        \cup [ tag : {TradeModifyRejectedMessageCode}, body : TradeModifyRejectedMessage ]
        \cup [ tag : {GiveupAppConfirmMessageCode}, body : GiveupAppConfirmMessage ]
        \cup [ tag : {GiveupRejConfirmMessageCode}, body : GiveupRejConfirmMessage ]
        \cup [ tag : {PriceConfirmationMessageCode}, body : PriceConfirmationMessage ]
        \cup [ tag : {OrderModRejectMessageCode}, body : OrderModRejectMessage ]
        \cup [ tag : {OrderCancelRejectMessageCode}, body : OrderCancelRejectMessage ]
        \cup [ tag : {OrderConfirmationMessageCode}, body : OrderConfirmationMessage ]
        \cup [ tag : {OrderModConfirmationMessageCode}, body : OrderModConfirmationMessage ]
        \cup [ tag : {OrderCancelConfirmationMessageCode}, body : OrderCancelConfirmationMessage ]
        \cup [ tag : {FreezeToControlMessageCode}, body : FreezeToControlMessage ]
        \cup [ tag : {OnStopNotificationMessageCode}, body : OnStopNotificationMessage ]
        \cup [ tag : {OrderErrorMessageCode}, body : OrderErrorMessage ]
        \cup [ tag : {BatchOrderCancelMessageCode}, body : BatchOrderCancelMessage ]
        \cup [ tag : {SpOrderConfirmationMessageCode}, body : SpOrderConfirmationMessage ]
        \cup [ tag : {TwolOrderConfirmationMessageCode}, body : TwolOrderConfirmationMessage ]
        \cup [ tag : {ThrlOrderConfirmationMessageCode}, body : ThrlOrderConfirmationMessage ]
        \cup [ tag : {SpOrderCxlRejectedMessageCode}, body : SpOrderCxlRejectedMessage ]
        \cup [ tag : {SpOrderCxlConfirmationMessageCode}, body : SpOrderCxlConfirmationMessage ]
        \cup [ tag : {TwolOrderCxlConfirmationMessageCode}, body : TwolOrderCxlConfirmationMessage ]
        \cup [ tag : {ThrlOrderCxlConfirmationMessageCode}, body : ThrlOrderCxlConfirmationMessage ]
        \cup [ tag : {SpOrderModRejectMessageCode}, body : SpOrderModRejectMessage ]
        \cup [ tag : {SpOrderModConfirmationMessageCode}, body : SpOrderModConfirmationMessage ]
        \cup [ tag : {SpOrderRejectedMessageCode}, body : SpOrderRejectedMessage ]
        \cup [ tag : {TwolOrderErrorMessageCode}, body : TwolOrderErrorMessage ]
        \cup [ tag : {ThrlOrderErrorMessageCode}, body : ThrlOrderErrorMessage ]
        \cup [ tag : {BatchSpreadCxlOutMessageCode}, body : BatchSpreadCxlOutMessage ]

EncodeServerMessagePayload(message) ==
    CASE message.tag = GrResponseMessageCode -> EncodeGrResponseMessage(message.body)
      [] message.tag = GrSecureUserRegistrationResponseMessageCode -> << >>
      [] message.tag = DcSignonOutMessageCode -> EncodeDcSignonOutMessage(message.body)
      [] message.tag = DcSignOffMessageCode -> EncodeDcSignOffMessage(message.body)
      [] message.tag = DcErrorResponseTradeMessageCode -> EncodeDcErrorResponseTradeMessage(message.body)
      [] message.tag = DcErrorResponseOrderMessageCode -> EncodeDcErrorResponseOrderMessage(message.body)
      [] message.tag = TradeConfirmationMessageCode -> EncodeTradeConfirmationMessage(message.body)
      [] message.tag = TradeCancelConfirmMessageCode -> EncodeTradeCancelConfirmMessage(message.body)
      [] message.tag = TradeCancelRejectMessageCode -> EncodeTradeCancelRejectMessage(message.body)
      [] message.tag = TradeModifyConfirmMessageCode -> EncodeTradeModifyConfirmMessage(message.body)
      [] message.tag = TradeModifyRejectedMessageCode -> EncodeTradeModifyRejectedMessage(message.body)
      [] message.tag = GiveupAppConfirmMessageCode -> EncodeGiveupAppConfirmMessage(message.body)
      [] message.tag = GiveupRejConfirmMessageCode -> EncodeGiveupRejConfirmMessage(message.body)
      [] message.tag = PriceConfirmationMessageCode -> EncodePriceConfirmationMessage(message.body)
      [] message.tag = OrderModRejectMessageCode -> EncodeOrderModRejectMessage(message.body)
      [] message.tag = OrderCancelRejectMessageCode -> EncodeOrderCancelRejectMessage(message.body)
      [] message.tag = OrderConfirmationMessageCode -> EncodeOrderConfirmationMessage(message.body)
      [] message.tag = OrderModConfirmationMessageCode -> EncodeOrderModConfirmationMessage(message.body)
      [] message.tag = OrderCancelConfirmationMessageCode -> EncodeOrderCancelConfirmationMessage(message.body)
      [] message.tag = FreezeToControlMessageCode -> EncodeFreezeToControlMessage(message.body)
      [] message.tag = OnStopNotificationMessageCode -> EncodeOnStopNotificationMessage(message.body)
      [] message.tag = OrderErrorMessageCode -> EncodeOrderErrorMessage(message.body)
      [] message.tag = BatchOrderCancelMessageCode -> EncodeBatchOrderCancelMessage(message.body)
      [] message.tag = SpOrderConfirmationMessageCode -> EncodeSpOrderConfirmationMessage(message.body)
      [] message.tag = TwolOrderConfirmationMessageCode -> EncodeTwolOrderConfirmationMessage(message.body)
      [] message.tag = ThrlOrderConfirmationMessageCode -> EncodeThrlOrderConfirmationMessage(message.body)
      [] message.tag = SpOrderCxlRejectedMessageCode -> EncodeSpOrderCxlRejectedMessage(message.body)
      [] message.tag = SpOrderCxlConfirmationMessageCode -> EncodeSpOrderCxlConfirmationMessage(message.body)
      [] message.tag = TwolOrderCxlConfirmationMessageCode -> EncodeTwolOrderCxlConfirmationMessage(message.body)
      [] message.tag = ThrlOrderCxlConfirmationMessageCode -> EncodeThrlOrderCxlConfirmationMessage(message.body)
      [] message.tag = SpOrderModRejectMessageCode -> EncodeSpOrderModRejectMessage(message.body)
      [] message.tag = SpOrderModConfirmationMessageCode -> EncodeSpOrderModConfirmationMessage(message.body)
      [] message.tag = SpOrderRejectedMessageCode -> EncodeSpOrderRejectedMessage(message.body)
      [] message.tag = TwolOrderErrorMessageCode -> EncodeTwolOrderErrorMessage(message.body)
      [] message.tag = ThrlOrderErrorMessageCode -> EncodeThrlOrderErrorMessage(message.body)
      [] message.tag = BatchSpreadCxlOutMessageCode -> EncodeBatchSpreadCxlOutMessage(message.body)

DecodeServerMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = GrResponseMessageCode -> DecodeGrResponseMessage(bytes)
              [] tag = GrSecureUserRegistrationResponseMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = DcSignonOutMessageCode -> DecodeDcSignonOutMessage(bytes)
              [] tag = DcSignOffMessageCode -> DecodeDcSignOffMessage(bytes)
              [] tag = DcErrorResponseTradeMessageCode -> DecodeDcErrorResponseTradeMessage(bytes)
              [] tag = DcErrorResponseOrderMessageCode -> DecodeDcErrorResponseOrderMessage(bytes)
              [] tag = TradeConfirmationMessageCode -> DecodeTradeConfirmationMessage(bytes)
              [] tag = TradeCancelConfirmMessageCode -> DecodeTradeCancelConfirmMessage(bytes)
              [] tag = TradeCancelRejectMessageCode -> DecodeTradeCancelRejectMessage(bytes)
              [] tag = TradeModifyConfirmMessageCode -> DecodeTradeModifyConfirmMessage(bytes)
              [] tag = TradeModifyRejectedMessageCode -> DecodeTradeModifyRejectedMessage(bytes)
              [] tag = GiveupAppConfirmMessageCode -> DecodeGiveupAppConfirmMessage(bytes)
              [] tag = GiveupRejConfirmMessageCode -> DecodeGiveupRejConfirmMessage(bytes)
              [] tag = PriceConfirmationMessageCode -> DecodePriceConfirmationMessage(bytes)
              [] tag = OrderModRejectMessageCode -> DecodeOrderModRejectMessage(bytes)
              [] tag = OrderCancelRejectMessageCode -> DecodeOrderCancelRejectMessage(bytes)
              [] tag = OrderConfirmationMessageCode -> DecodeOrderConfirmationMessage(bytes)
              [] tag = OrderModConfirmationMessageCode -> DecodeOrderModConfirmationMessage(bytes)
              [] tag = OrderCancelConfirmationMessageCode -> DecodeOrderCancelConfirmationMessage(bytes)
              [] tag = FreezeToControlMessageCode -> DecodeFreezeToControlMessage(bytes)
              [] tag = OnStopNotificationMessageCode -> DecodeOnStopNotificationMessage(bytes)
              [] tag = OrderErrorMessageCode -> DecodeOrderErrorMessage(bytes)
              [] tag = BatchOrderCancelMessageCode -> DecodeBatchOrderCancelMessage(bytes)
              [] tag = SpOrderConfirmationMessageCode -> DecodeSpOrderConfirmationMessage(bytes)
              [] tag = TwolOrderConfirmationMessageCode -> DecodeTwolOrderConfirmationMessage(bytes)
              [] tag = ThrlOrderConfirmationMessageCode -> DecodeThrlOrderConfirmationMessage(bytes)
              [] tag = SpOrderCxlRejectedMessageCode -> DecodeSpOrderCxlRejectedMessage(bytes)
              [] tag = SpOrderCxlConfirmationMessageCode -> DecodeSpOrderCxlConfirmationMessage(bytes)
              [] tag = TwolOrderCxlConfirmationMessageCode -> DecodeTwolOrderCxlConfirmationMessage(bytes)
              [] tag = ThrlOrderCxlConfirmationMessageCode -> DecodeThrlOrderCxlConfirmationMessage(bytes)
              [] tag = SpOrderModRejectMessageCode -> DecodeSpOrderModRejectMessage(bytes)
              [] tag = SpOrderModConfirmationMessageCode -> DecodeSpOrderModConfirmationMessage(bytes)
              [] tag = SpOrderRejectedMessageCode -> DecodeSpOrderRejectedMessage(bytes)
              [] tag = TwolOrderErrorMessageCode -> DecodeTwolOrderErrorMessage(bytes)
              [] tag = ThrlOrderErrorMessageCode -> DecodeThrlOrderErrorMessage(bytes)
              [] tag = BatchSpreadCxlOutMessageCode -> DecodeBatchSpreadCxlOutMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroServerMessagePayload == [tag |-> GrResponseMessageCode, body |-> ZeroGrResponseMessage]

(* Each Server Message Payload in turn, at the values the message it names is checked at *)
CheckedServerMessagePayload ==
    { [tag |-> GrResponseMessageCode, body |-> one] : one \in CheckedGrResponseMessage }
        \cup { [tag |-> GrSecureUserRegistrationResponseMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> DcSignonOutMessageCode, body |-> one] : one \in CheckedDcSignonOutMessage }
        \cup { [tag |-> DcSignOffMessageCode, body |-> one] : one \in CheckedDcSignOffMessage }
        \cup { [tag |-> DcErrorResponseTradeMessageCode, body |-> one] : one \in CheckedDcErrorResponseTradeMessage }
        \cup { [tag |-> DcErrorResponseOrderMessageCode, body |-> one] : one \in CheckedDcErrorResponseOrderMessage }
        \cup { [tag |-> TradeConfirmationMessageCode, body |-> one] : one \in CheckedTradeConfirmationMessage }
        \cup { [tag |-> TradeCancelConfirmMessageCode, body |-> one] : one \in CheckedTradeCancelConfirmMessage }
        \cup { [tag |-> TradeCancelRejectMessageCode, body |-> one] : one \in CheckedTradeCancelRejectMessage }
        \cup { [tag |-> TradeModifyConfirmMessageCode, body |-> one] : one \in CheckedTradeModifyConfirmMessage }
        \cup { [tag |-> TradeModifyRejectedMessageCode, body |-> one] : one \in CheckedTradeModifyRejectedMessage }
        \cup { [tag |-> GiveupAppConfirmMessageCode, body |-> one] : one \in CheckedGiveupAppConfirmMessage }
        \cup { [tag |-> GiveupRejConfirmMessageCode, body |-> one] : one \in CheckedGiveupRejConfirmMessage }
        \cup { [tag |-> PriceConfirmationMessageCode, body |-> one] : one \in CheckedPriceConfirmationMessage }
        \cup { [tag |-> OrderModRejectMessageCode, body |-> one] : one \in CheckedOrderModRejectMessage }
        \cup { [tag |-> OrderCancelRejectMessageCode, body |-> one] : one \in CheckedOrderCancelRejectMessage }
        \cup { [tag |-> OrderConfirmationMessageCode, body |-> one] : one \in CheckedOrderConfirmationMessage }
        \cup { [tag |-> OrderModConfirmationMessageCode, body |-> one] : one \in CheckedOrderModConfirmationMessage }
        \cup { [tag |-> OrderCancelConfirmationMessageCode, body |-> one] : one \in CheckedOrderCancelConfirmationMessage }
        \cup { [tag |-> FreezeToControlMessageCode, body |-> one] : one \in CheckedFreezeToControlMessage }
        \cup { [tag |-> OnStopNotificationMessageCode, body |-> one] : one \in CheckedOnStopNotificationMessage }
        \cup { [tag |-> OrderErrorMessageCode, body |-> one] : one \in CheckedOrderErrorMessage }
        \cup { [tag |-> BatchOrderCancelMessageCode, body |-> one] : one \in CheckedBatchOrderCancelMessage }
        \cup { [tag |-> SpOrderConfirmationMessageCode, body |-> one] : one \in CheckedSpOrderConfirmationMessage }
        \cup { [tag |-> TwolOrderConfirmationMessageCode, body |-> one] : one \in CheckedTwolOrderConfirmationMessage }
        \cup { [tag |-> ThrlOrderConfirmationMessageCode, body |-> one] : one \in CheckedThrlOrderConfirmationMessage }
        \cup { [tag |-> SpOrderCxlRejectedMessageCode, body |-> one] : one \in CheckedSpOrderCxlRejectedMessage }
        \cup { [tag |-> SpOrderCxlConfirmationMessageCode, body |-> one] : one \in CheckedSpOrderCxlConfirmationMessage }
        \cup { [tag |-> TwolOrderCxlConfirmationMessageCode, body |-> one] : one \in CheckedTwolOrderCxlConfirmationMessage }
        \cup { [tag |-> ThrlOrderCxlConfirmationMessageCode, body |-> one] : one \in CheckedThrlOrderCxlConfirmationMessage }
        \cup { [tag |-> SpOrderModRejectMessageCode, body |-> one] : one \in CheckedSpOrderModRejectMessage }
        \cup { [tag |-> SpOrderModConfirmationMessageCode, body |-> one] : one \in CheckedSpOrderModConfirmationMessage }
        \cup { [tag |-> SpOrderRejectedMessageCode, body |-> one] : one \in CheckedSpOrderRejectedMessage }
        \cup { [tag |-> TwolOrderErrorMessageCode, body |-> one] : one \in CheckedTwolOrderErrorMessage }
        \cup { [tag |-> ThrlOrderErrorMessageCode, body |-> one] : one \in CheckedThrlOrderErrorMessage }
        \cup { [tag |-> BatchSpreadCxlOutMessageCode, body |-> one] : one \in CheckedBatchSpreadCxlOutMessage }

(***************************************************************************)
(* Server Message, framed by Message Length                                *)
(***************************************************************************)

ServerMessage ==
    [ errorCode            : Sample(2),
      sequenceNumber       : Sample(8),
      serverMessagePayload : ServerMessagePayload ]

EncodeServerMessageBody(message) ==
    EncodeServerMessagePayload(message.serverMessagePayload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeServerMessage(message) ==
    LET body == EncodeServerMessageBody(message)
    IN  EncodeUIntBE(message.serverMessagePayload.tag, 2) \o message.errorCode \o message.sequenceNumber \o EncodeUIntBE(Len(body) + 14, 2) \o body

DecodeServerMessage(bytes) ==
    LET transactionCode == ReadUIntBE(bytes, 2) IN IF ~transactionCode.ok THEN Fail ELSE
    LET errorCode == ReadBytes(transactionCode.rest, 2) IN IF ~errorCode.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(errorCode.rest, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET length == ReadUIntBE(sequenceNumber.rest, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 14 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
    IN
    LET serverMessagePayload == DecodeServerMessagePayload(transactionCode.value, framed) IN IF ~serverMessagePayload.ok THEN Fail ELSE
    IF serverMessagePayload.rest # << >> THEN Fail ELSE
    Ok([ errorCode            |-> errorCode.value,
         sequenceNumber       |-> sequenceNumber.value,
         serverMessagePayload |-> serverMessagePayload.value ], beyond)

ZeroServerMessage ==
    [ errorCode            |-> [i \in 1 .. 2 |-> 0],
      sequenceNumber       |-> [i \in 1 .. 8 |-> 0],
      serverMessagePayload |-> ZeroServerMessagePayload ]

(* Server Message at zero, then each field in turn at the values it is checked at *)
CheckedServerMessage ==
    { ZeroServerMessage }
        \cup { [ZeroServerMessage EXCEPT !.errorCode = one] : one \in Sample(2) }
        \cup { [ZeroServerMessage EXCEPT !.sequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroServerMessage EXCEPT !.serverMessagePayload = one] : one \in CheckedServerMessagePayload }

(* A run of Server Message, written one after another *)
RECURSIVE EncodeServerMessageList(_)
EncodeServerMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeServerMessage(Head(messages)) \o EncodeServerMessageList(Tail(messages))

(* As many Server Message as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadServerMessageAll(_)
ReadServerMessageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeServerMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadServerMessageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Server Message of each kind, for the lists that carry them *)
OneServerMessage ==
    { [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> GrResponseMessageCode, body |-> ZeroGrResponseMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> GrSecureUserRegistrationResponseMessageCode, body |-> [empty |-> 0]]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> DcSignonOutMessageCode, body |-> ZeroDcSignonOutMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> DcSignOffMessageCode, body |-> ZeroDcSignOffMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> DcErrorResponseTradeMessageCode, body |-> ZeroDcErrorResponseTradeMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> DcErrorResponseOrderMessageCode, body |-> ZeroDcErrorResponseOrderMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> TradeConfirmationMessageCode, body |-> ZeroTradeConfirmationMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> TradeCancelConfirmMessageCode, body |-> ZeroTradeCancelConfirmMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> TradeCancelRejectMessageCode, body |-> ZeroTradeCancelRejectMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> TradeModifyConfirmMessageCode, body |-> ZeroTradeModifyConfirmMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> TradeModifyRejectedMessageCode, body |-> ZeroTradeModifyRejectedMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> GiveupAppConfirmMessageCode, body |-> ZeroGiveupAppConfirmMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> GiveupRejConfirmMessageCode, body |-> ZeroGiveupRejConfirmMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> PriceConfirmationMessageCode, body |-> ZeroPriceConfirmationMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> OrderModRejectMessageCode, body |-> ZeroOrderModRejectMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> OrderCancelRejectMessageCode, body |-> ZeroOrderCancelRejectMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> OrderConfirmationMessageCode, body |-> ZeroOrderConfirmationMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> OrderModConfirmationMessageCode, body |-> ZeroOrderModConfirmationMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> OrderCancelConfirmationMessageCode, body |-> ZeroOrderCancelConfirmationMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> FreezeToControlMessageCode, body |-> ZeroFreezeToControlMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> OnStopNotificationMessageCode, body |-> ZeroOnStopNotificationMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> OrderErrorMessageCode, body |-> ZeroOrderErrorMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> BatchOrderCancelMessageCode, body |-> ZeroBatchOrderCancelMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> SpOrderConfirmationMessageCode, body |-> ZeroSpOrderConfirmationMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> TwolOrderConfirmationMessageCode, body |-> ZeroTwolOrderConfirmationMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> ThrlOrderConfirmationMessageCode, body |-> ZeroThrlOrderConfirmationMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> SpOrderCxlRejectedMessageCode, body |-> ZeroSpOrderCxlRejectedMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> SpOrderCxlConfirmationMessageCode, body |-> ZeroSpOrderCxlConfirmationMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> TwolOrderCxlConfirmationMessageCode, body |-> ZeroTwolOrderCxlConfirmationMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> ThrlOrderCxlConfirmationMessageCode, body |-> ZeroThrlOrderCxlConfirmationMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> SpOrderModRejectMessageCode, body |-> ZeroSpOrderModRejectMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> SpOrderModConfirmationMessageCode, body |-> ZeroSpOrderModConfirmationMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> SpOrderRejectedMessageCode, body |-> ZeroSpOrderRejectedMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> TwolOrderErrorMessageCode, body |-> ZeroTwolOrderErrorMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> ThrlOrderErrorMessageCode, body |-> ZeroThrlOrderErrorMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> BatchSpreadCxlOutMessageCode, body |-> ZeroBatchSpreadCxlOutMessage]] }

(***************************************************************************)
(* Message Buffer                                                          *)
(***************************************************************************)

MessageBuffer ==
    [ serverMessage : SampleLists(OneServerMessage) ]

EncodeMessageBuffer(message) ==
    EncodeServerMessageList(message.serverMessage)

DecodeMessageBuffer(bytes) ==
    LET serverMessage == ReadServerMessageAll(bytes) IN IF ~serverMessage.ok THEN Fail ELSE
    Ok([ serverMessage |-> serverMessage.value ], serverMessage.rest)

ZeroMessageBuffer ==
    [ serverMessage |-> << >> ]

(* Message Buffer at zero, then each field in turn at the values it is checked at *)
CheckedMessageBuffer ==
    { ZeroMessageBuffer }
        \cup { [ZeroMessageBuffer EXCEPT !.serverMessage = one] : one \in SampleLists(OneServerMessage) }

(***************************************************************************)
(* Message Buffer, selected by Compression Indicator                       *)
(***************************************************************************)

MessageBufferLz4Code == 1  \* ""
MessageBufferPlainCode == 0  \* stands for every value no other case names

MessageBufferBody ==
    [ tag : {MessageBufferLz4Code}, body : MessageBufferLz4 ]
        \cup [ tag : (0 .. 255) \ {MessageBufferLz4Code}, body : MessageBuffer ]

EncodeMessageBufferBody(message) ==
    CASE message.tag = MessageBufferLz4Code -> EncodeMessageBufferLz4(message.body)
      [] OTHER -> EncodeMessageBuffer(message.body)

DecodeMessageBufferBody(tag, bytes) ==
    LET read ==
            CASE tag = MessageBufferLz4Code -> DecodeMessageBufferLz4(bytes)
              [] OTHER -> DecodeMessageBuffer(bytes)
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroMessageBufferBody == [tag |-> MessageBufferLz4Code, body |-> ZeroMessageBufferLz4]

(* Each Message Buffer in turn, at the values the message it names is checked at *)
CheckedMessageBufferBody ==
    { [tag |-> MessageBufferLz4Code, body |-> one] : one \in CheckedMessageBufferLz4 }
        \cup [ tag : {0, 1, 255} \ {MessageBufferLz4Code}, body : CheckedMessageBuffer ]

(***************************************************************************)
(* Server Drop Copy Packet, framed by Packet Length                        *)
(***************************************************************************)

ServerDropCopyPacket ==
    [ packetSequenceNumber : Sample(4),
      checksum             : Sample(16),
      environmentType      : Sample(1),
      messageBuffer        : MessageBufferBody ]

EncodeServerDropCopyPacketBody(message) ==
    message.packetSequenceNumber
        \o message.checksum
        \o message.environmentType
        \o EncodeUIntBE(message.messageBuffer.tag, 1)
        \o EncodeMessageBufferBody(message.messageBuffer)

(* Packet Length counts the bytes it frames, so it is written from them *)
EncodeServerDropCopyPacket(message) ==
    LET body == EncodeServerDropCopyPacketBody(message)
    IN  EncodeUIntBE(Len(body) + 2, 2) \o body

DecodeServerDropCopyPacketBody(bytes) ==
    LET packetSequenceNumber == ReadBytes(bytes, 4) IN IF ~packetSequenceNumber.ok THEN Fail ELSE
    LET checksum == ReadBytes(packetSequenceNumber.rest, 16) IN IF ~checksum.ok THEN Fail ELSE
    LET environmentType == ReadBytes(checksum.rest, 1) IN IF ~environmentType.ok THEN Fail ELSE
    LET compressionIndicator == ReadUIntBE(environmentType.rest, 1) IN IF ~compressionIndicator.ok THEN Fail ELSE
    LET messageBuffer == DecodeMessageBufferBody(compressionIndicator.value, compressionIndicator.rest) IN IF ~messageBuffer.ok THEN Fail ELSE
    Ok([ packetSequenceNumber |-> packetSequenceNumber.value,
         checksum             |-> checksum.value,
         environmentType      |-> environmentType.value,
         messageBuffer        |-> messageBuffer.value ], messageBuffer.rest)

DecodeServerDropCopyPacket(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeServerDropCopyPacketBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroServerDropCopyPacket ==
    [ packetSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      checksum             |-> [i \in 1 .. 16 |-> 0],
      environmentType      |-> [i \in 1 .. 1 |-> 0],
      messageBuffer        |-> ZeroMessageBufferBody ]

(* Server Drop Copy Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerDropCopyPacket ==
    { ZeroServerDropCopyPacket }
        \cup { [ZeroServerDropCopyPacket EXCEPT !.packetSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroServerDropCopyPacket EXCEPT !.checksum = one] : one \in Sample(16) }
        \cup { [ZeroServerDropCopyPacket EXCEPT !.environmentType = one] : one \in Sample(1) }
        \cup { [ZeroServerDropCopyPacket EXCEPT !.messageBuffer = one] : one \in CheckedMessageBufferBody }

(* A run of Server Drop Copy Packet, written one after another *)
RECURSIVE EncodeServerDropCopyPacketList(_)
EncodeServerDropCopyPacketList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeServerDropCopyPacket(Head(messages)) \o EncodeServerDropCopyPacketList(Tail(messages))

(* As many Server Drop Copy Packet as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadServerDropCopyPacketAll(_)
ReadServerDropCopyPacketAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeServerDropCopyPacket(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadServerDropCopyPacketAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Server Drop Copy Packet of each kind, for the lists that carry them *)
OneServerDropCopyPacket ==
    { [ZeroServerDropCopyPacket EXCEPT !.messageBuffer = [tag |-> MessageBufferLz4Code, body |-> ZeroMessageBufferLz4]],
      [ZeroServerDropCopyPacket EXCEPT !.messageBuffer = [tag |-> MessageBufferPlainCode, body |-> ZeroMessageBuffer]] }

(***************************************************************************)
(* Server Packet                                                           *)
(***************************************************************************)

ServerPacket ==
    [ serverDropCopyPacket : SampleLists(OneServerDropCopyPacket) ]

EncodeServerPacket(message) ==
    EncodeServerDropCopyPacketList(message.serverDropCopyPacket)

DecodeServerPacket(bytes) ==
    LET serverDropCopyPacket == ReadServerDropCopyPacketAll(bytes) IN IF ~serverDropCopyPacket.ok THEN Fail ELSE
    Ok([ serverDropCopyPacket |-> serverDropCopyPacket.value ], serverDropCopyPacket.rest)

ZeroServerPacket ==
    [ serverDropCopyPacket |-> << >> ]

(* Server Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerPacket ==
    { ZeroServerPacket }
        \cup { [ZeroServerPacket EXCEPT !.serverDropCopyPacket = one] : one \in SampleLists(OneServerDropCopyPacket) }

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

(* Every Message Buffer decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageBufferLz4 ==
    \A message \in CheckedMessageBufferLz4 :
        LET read == DecodeMessageBufferLz4(EncodeMessageBufferLz4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ip Details Partition Wise decodes back to what was encoded, and leaves nothing over *)
RoundTripIpDetailsPartitionWise ==
    \A message \in CheckedIpDetailsPartitionWise :
        LET read == DecodeIpDetailsPartitionWise(EncodeIpDetailsPartitionWise(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Gr Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripGrResponseMessage ==
    \A message \in CheckedGrResponseMessage :
        LET read == DecodeGrResponseMessage(EncodeGrResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Dc Signon Out Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDcSignonOutMessage ==
    \A message \in CheckedDcSignonOutMessage :
        LET read == DecodeDcSignonOutMessage(EncodeDcSignonOutMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Dc Sign Off Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDcSignOffMessage ==
    \A message \in CheckedDcSignOffMessage :
        LET read == DecodeDcSignOffMessage(EncodeDcSignOffMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Dc Error Response Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDcErrorResponseTradeMessage ==
    \A message \in CheckedDcErrorResponseTradeMessage :
        LET read == DecodeDcErrorResponseTradeMessage(EncodeDcErrorResponseTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Dc Error Response Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDcErrorResponseOrderMessage ==
    \A message \in CheckedDcErrorResponseOrderMessage :
        LET read == DecodeDcErrorResponseOrderMessage(EncodeDcErrorResponseOrderMessage(message))
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

(* Every Trade Cancel Confirm Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCancelConfirmMessage ==
    \A message \in CheckedTradeCancelConfirmMessage :
        LET read == DecodeTradeCancelConfirmMessage(EncodeTradeCancelConfirmMessage(message))
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

(* Every Trade Modify Confirm Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeModifyConfirmMessage ==
    \A message \in CheckedTradeModifyConfirmMessage :
        LET read == DecodeTradeModifyConfirmMessage(EncodeTradeModifyConfirmMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Modify Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeModifyRejectedMessage ==
    \A message \in CheckedTradeModifyRejectedMessage :
        LET read == DecodeTradeModifyRejectedMessage(EncodeTradeModifyRejectedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Giveup App Confirm Message decodes back to what was encoded, and leaves nothing over *)
RoundTripGiveupAppConfirmMessage ==
    \A message \in CheckedGiveupAppConfirmMessage :
        LET read == DecodeGiveupAppConfirmMessage(EncodeGiveupAppConfirmMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Giveup Rej Confirm Message decodes back to what was encoded, and leaves nothing over *)
RoundTripGiveupRejConfirmMessage ==
    \A message \in CheckedGiveupRejConfirmMessage :
        LET read == DecodeGiveupRejConfirmMessage(EncodeGiveupRejConfirmMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price Confirmation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPriceConfirmationMessage ==
    \A message \in CheckedPriceConfirmationMessage :
        LET read == DecodePriceConfirmationMessage(EncodePriceConfirmationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Mod Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderModRejectMessage ==
    \A message \in CheckedOrderModRejectMessage :
        LET read == DecodeOrderModRejectMessage(EncodeOrderModRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancel Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelRejectMessage ==
    \A message \in CheckedOrderCancelRejectMessage :
        LET read == DecodeOrderCancelRejectMessage(EncodeOrderCancelRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Confirmation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderConfirmationMessage ==
    \A message \in CheckedOrderConfirmationMessage :
        LET read == DecodeOrderConfirmationMessage(EncodeOrderConfirmationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Mod Confirmation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderModConfirmationMessage ==
    \A message \in CheckedOrderModConfirmationMessage :
        LET read == DecodeOrderModConfirmationMessage(EncodeOrderModConfirmationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancel Confirmation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelConfirmationMessage ==
    \A message \in CheckedOrderCancelConfirmationMessage :
        LET read == DecodeOrderCancelConfirmationMessage(EncodeOrderCancelConfirmationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Freeze To Control Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFreezeToControlMessage ==
    \A message \in CheckedFreezeToControlMessage :
        LET read == DecodeFreezeToControlMessage(EncodeFreezeToControlMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every On Stop Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOnStopNotificationMessage ==
    \A message \in CheckedOnStopNotificationMessage :
        LET read == DecodeOnStopNotificationMessage(EncodeOnStopNotificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Error Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderErrorMessage ==
    \A message \in CheckedOrderErrorMessage :
        LET read == DecodeOrderErrorMessage(EncodeOrderErrorMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Batch Order Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBatchOrderCancelMessage ==
    \A message \in CheckedBatchOrderCancelMessage :
        LET read == DecodeBatchOrderCancelMessage(EncodeBatchOrderCancelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ms Spd Leg Info Leg 2 decodes back to what was encoded, and leaves nothing over *)
RoundTripMsSpdLegInfoLeg2 ==
    \A message \in CheckedMsSpdLegInfoLeg2 :
        LET read == DecodeMsSpdLegInfoLeg2(EncodeMsSpdLegInfoLeg2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ms Spd Leg Info Leg 3 decodes back to what was encoded, and leaves nothing over *)
RoundTripMsSpdLegInfoLeg3 ==
    \A message \in CheckedMsSpdLegInfoLeg3 :
        LET read == DecodeMsSpdLegInfoLeg3(EncodeMsSpdLegInfoLeg3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sp Order Confirmation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSpOrderConfirmationMessage ==
    \A message \in CheckedSpOrderConfirmationMessage :
        LET read == DecodeSpOrderConfirmationMessage(EncodeSpOrderConfirmationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ms Spd Leg Info Leg 2 decodes back to what was encoded, and leaves nothing over *)
RoundTripMsSpdLegInfoLeg22 ==
    \A message \in CheckedMsSpdLegInfoLeg22 :
        LET read == DecodeMsSpdLegInfoLeg22(EncodeMsSpdLegInfoLeg22(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ms Spd Leg Info Leg 3 decodes back to what was encoded, and leaves nothing over *)
RoundTripMsSpdLegInfoLeg32 ==
    \A message \in CheckedMsSpdLegInfoLeg32 :
        LET read == DecodeMsSpdLegInfoLeg32(EncodeMsSpdLegInfoLeg32(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Twol Order Confirmation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTwolOrderConfirmationMessage ==
    \A message \in CheckedTwolOrderConfirmationMessage :
        LET read == DecodeTwolOrderConfirmationMessage(EncodeTwolOrderConfirmationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ms Spd Leg Info Leg 2 decodes back to what was encoded, and leaves nothing over *)
RoundTripMsSpdLegInfoLeg23 ==
    \A message \in CheckedMsSpdLegInfoLeg23 :
        LET read == DecodeMsSpdLegInfoLeg23(EncodeMsSpdLegInfoLeg23(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ms Spd Leg Info Leg 3 decodes back to what was encoded, and leaves nothing over *)
RoundTripMsSpdLegInfoLeg33 ==
    \A message \in CheckedMsSpdLegInfoLeg33 :
        LET read == DecodeMsSpdLegInfoLeg33(EncodeMsSpdLegInfoLeg33(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Thrl Order Confirmation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripThrlOrderConfirmationMessage ==
    \A message \in CheckedThrlOrderConfirmationMessage :
        LET read == DecodeThrlOrderConfirmationMessage(EncodeThrlOrderConfirmationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ms Spd Leg Info Leg 2 decodes back to what was encoded, and leaves nothing over *)
RoundTripMsSpdLegInfoLeg24 ==
    \A message \in CheckedMsSpdLegInfoLeg24 :
        LET read == DecodeMsSpdLegInfoLeg24(EncodeMsSpdLegInfoLeg24(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ms Spd Leg Info Leg 3 decodes back to what was encoded, and leaves nothing over *)
RoundTripMsSpdLegInfoLeg34 ==
    \A message \in CheckedMsSpdLegInfoLeg34 :
        LET read == DecodeMsSpdLegInfoLeg34(EncodeMsSpdLegInfoLeg34(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sp Order Cxl Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSpOrderCxlRejectedMessage ==
    \A message \in CheckedSpOrderCxlRejectedMessage :
        LET read == DecodeSpOrderCxlRejectedMessage(EncodeSpOrderCxlRejectedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ms Spd Leg Info Leg 2 decodes back to what was encoded, and leaves nothing over *)
RoundTripMsSpdLegInfoLeg25 ==
    \A message \in CheckedMsSpdLegInfoLeg25 :
        LET read == DecodeMsSpdLegInfoLeg25(EncodeMsSpdLegInfoLeg25(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ms Spd Leg Info Leg 3 decodes back to what was encoded, and leaves nothing over *)
RoundTripMsSpdLegInfoLeg35 ==
    \A message \in CheckedMsSpdLegInfoLeg35 :
        LET read == DecodeMsSpdLegInfoLeg35(EncodeMsSpdLegInfoLeg35(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sp Order Cxl Confirmation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSpOrderCxlConfirmationMessage ==
    \A message \in CheckedSpOrderCxlConfirmationMessage :
        LET read == DecodeSpOrderCxlConfirmationMessage(EncodeSpOrderCxlConfirmationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ms Spd Leg Info Leg 2 decodes back to what was encoded, and leaves nothing over *)
RoundTripMsSpdLegInfoLeg26 ==
    \A message \in CheckedMsSpdLegInfoLeg26 :
        LET read == DecodeMsSpdLegInfoLeg26(EncodeMsSpdLegInfoLeg26(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ms Spd Leg Info Leg 3 decodes back to what was encoded, and leaves nothing over *)
RoundTripMsSpdLegInfoLeg36 ==
    \A message \in CheckedMsSpdLegInfoLeg36 :
        LET read == DecodeMsSpdLegInfoLeg36(EncodeMsSpdLegInfoLeg36(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Twol Order Cxl Confirmation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTwolOrderCxlConfirmationMessage ==
    \A message \in CheckedTwolOrderCxlConfirmationMessage :
        LET read == DecodeTwolOrderCxlConfirmationMessage(EncodeTwolOrderCxlConfirmationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ms Spd Leg Info Leg 2 decodes back to what was encoded, and leaves nothing over *)
RoundTripMsSpdLegInfoLeg27 ==
    \A message \in CheckedMsSpdLegInfoLeg27 :
        LET read == DecodeMsSpdLegInfoLeg27(EncodeMsSpdLegInfoLeg27(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ms Spd Leg Info Leg 3 decodes back to what was encoded, and leaves nothing over *)
RoundTripMsSpdLegInfoLeg37 ==
    \A message \in CheckedMsSpdLegInfoLeg37 :
        LET read == DecodeMsSpdLegInfoLeg37(EncodeMsSpdLegInfoLeg37(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Thrl Order Cxl Confirmation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripThrlOrderCxlConfirmationMessage ==
    \A message \in CheckedThrlOrderCxlConfirmationMessage :
        LET read == DecodeThrlOrderCxlConfirmationMessage(EncodeThrlOrderCxlConfirmationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ms Spd Leg Info Leg 2 decodes back to what was encoded, and leaves nothing over *)
RoundTripMsSpdLegInfoLeg28 ==
    \A message \in CheckedMsSpdLegInfoLeg28 :
        LET read == DecodeMsSpdLegInfoLeg28(EncodeMsSpdLegInfoLeg28(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ms Spd Leg Info Leg 3 decodes back to what was encoded, and leaves nothing over *)
RoundTripMsSpdLegInfoLeg38 ==
    \A message \in CheckedMsSpdLegInfoLeg38 :
        LET read == DecodeMsSpdLegInfoLeg38(EncodeMsSpdLegInfoLeg38(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sp Order Mod Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSpOrderModRejectMessage ==
    \A message \in CheckedSpOrderModRejectMessage :
        LET read == DecodeSpOrderModRejectMessage(EncodeSpOrderModRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ms Spd Leg Info Leg 2 decodes back to what was encoded, and leaves nothing over *)
RoundTripMsSpdLegInfoLeg29 ==
    \A message \in CheckedMsSpdLegInfoLeg29 :
        LET read == DecodeMsSpdLegInfoLeg29(EncodeMsSpdLegInfoLeg29(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ms Spd Leg Info Leg 3 decodes back to what was encoded, and leaves nothing over *)
RoundTripMsSpdLegInfoLeg39 ==
    \A message \in CheckedMsSpdLegInfoLeg39 :
        LET read == DecodeMsSpdLegInfoLeg39(EncodeMsSpdLegInfoLeg39(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sp Order Mod Confirmation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSpOrderModConfirmationMessage ==
    \A message \in CheckedSpOrderModConfirmationMessage :
        LET read == DecodeSpOrderModConfirmationMessage(EncodeSpOrderModConfirmationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ms Spd Leg Info Leg 2 decodes back to what was encoded, and leaves nothing over *)
RoundTripMsSpdLegInfoLeg210 ==
    \A message \in CheckedMsSpdLegInfoLeg210 :
        LET read == DecodeMsSpdLegInfoLeg210(EncodeMsSpdLegInfoLeg210(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ms Spd Leg Info Leg 3 decodes back to what was encoded, and leaves nothing over *)
RoundTripMsSpdLegInfoLeg310 ==
    \A message \in CheckedMsSpdLegInfoLeg310 :
        LET read == DecodeMsSpdLegInfoLeg310(EncodeMsSpdLegInfoLeg310(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sp Order Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSpOrderRejectedMessage ==
    \A message \in CheckedSpOrderRejectedMessage :
        LET read == DecodeSpOrderRejectedMessage(EncodeSpOrderRejectedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ms Spd Leg Info Leg 2 decodes back to what was encoded, and leaves nothing over *)
RoundTripMsSpdLegInfoLeg211 ==
    \A message \in CheckedMsSpdLegInfoLeg211 :
        LET read == DecodeMsSpdLegInfoLeg211(EncodeMsSpdLegInfoLeg211(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ms Spd Leg Info Leg 3 decodes back to what was encoded, and leaves nothing over *)
RoundTripMsSpdLegInfoLeg311 ==
    \A message \in CheckedMsSpdLegInfoLeg311 :
        LET read == DecodeMsSpdLegInfoLeg311(EncodeMsSpdLegInfoLeg311(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Twol Order Error Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTwolOrderErrorMessage ==
    \A message \in CheckedTwolOrderErrorMessage :
        LET read == DecodeTwolOrderErrorMessage(EncodeTwolOrderErrorMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ms Spd Leg Info Leg 2 decodes back to what was encoded, and leaves nothing over *)
RoundTripMsSpdLegInfoLeg212 ==
    \A message \in CheckedMsSpdLegInfoLeg212 :
        LET read == DecodeMsSpdLegInfoLeg212(EncodeMsSpdLegInfoLeg212(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ms Spd Leg Info Leg 3 decodes back to what was encoded, and leaves nothing over *)
RoundTripMsSpdLegInfoLeg312 ==
    \A message \in CheckedMsSpdLegInfoLeg312 :
        LET read == DecodeMsSpdLegInfoLeg312(EncodeMsSpdLegInfoLeg312(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Thrl Order Error Message decodes back to what was encoded, and leaves nothing over *)
RoundTripThrlOrderErrorMessage ==
    \A message \in CheckedThrlOrderErrorMessage :
        LET read == DecodeThrlOrderErrorMessage(EncodeThrlOrderErrorMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ms Spd Leg Info Leg 2 decodes back to what was encoded, and leaves nothing over *)
RoundTripMsSpdLegInfoLeg213 ==
    \A message \in CheckedMsSpdLegInfoLeg213 :
        LET read == DecodeMsSpdLegInfoLeg213(EncodeMsSpdLegInfoLeg213(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ms Spd Leg Info Leg 3 decodes back to what was encoded, and leaves nothing over *)
RoundTripMsSpdLegInfoLeg313 ==
    \A message \in CheckedMsSpdLegInfoLeg313 :
        LET read == DecodeMsSpdLegInfoLeg313(EncodeMsSpdLegInfoLeg313(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Batch Spread Cxl Out Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBatchSpreadCxlOutMessage ==
    \A message \in CheckedBatchSpreadCxlOutMessage :
        LET read == DecodeBatchSpreadCxlOutMessage(EncodeBatchSpreadCxlOutMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Server Message decodes back to what was encoded, and leaves nothing over *)
RoundTripServerMessage ==
    \A message \in CheckedServerMessage :
        LET read == DecodeServerMessage(EncodeServerMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message Buffer decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageBuffer ==
    \A message \in CheckedMessageBuffer :
        LET read == DecodeMessageBuffer(EncodeMessageBuffer(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Server Drop Copy Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripServerDropCopyPacket ==
    \A message \in CheckedServerDropCopyPacket :
        LET read == DecodeServerDropCopyPacket(EncodeServerDropCopyPacket(message))
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
        LET sent == EncodeServerMessagePayload(message)
            read == DecodeServerMessagePayload(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Message Buffer is selected by the Compression Indicator it is written under *)
SelectsMessageBufferBody ==
    \A message \in CheckedMessageBufferBody :
        LET sent == EncodeMessageBufferBody(message)
            read == DecodeMessageBufferBody(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* Message Length is written from the bytes it frames *)
FramesServerMessage ==
    \A message \in CheckedServerMessage :
        LET bytes == EncodeServerMessage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 13, 14)) = Len(bytes) - 0

(* Packet Length is written from the bytes it frames *)
FramesServerDropCopyPacket ==
    \A message \in CheckedServerDropCopyPacket :
        LET bytes == EncodeServerDropCopyPacket(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
