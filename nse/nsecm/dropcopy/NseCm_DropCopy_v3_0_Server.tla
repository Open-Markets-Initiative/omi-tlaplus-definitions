-------------------- MODULE NseCm_DropCopy_v3_0_Server ---------------------
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
(* Gr Response Message: 86 bytes                                           *)
(***************************************************************************)

GrResponseMessage ==
    [ messageIndicator       : Sample(2),
      partitionCount         : Sample(2),
      ipDetailsPartitionWise : IpDetailsPartitionWise,
      sessionKey             : Sample(8),
      cryptographicKey       : Sample(32),
      cryptographicIv        : Sample(16) ]

EncodeGrResponseMessage(message) ==
    message.messageIndicator
        \o message.partitionCount
        \o EncodeIpDetailsPartitionWise(message.ipDetailsPartitionWise)
        \o message.sessionKey
        \o message.cryptographicKey
        \o message.cryptographicIv

DecodeGrResponseMessage(bytes) ==
    LET messageIndicator == ReadBytes(bytes, 2) IN IF ~messageIndicator.ok THEN Fail ELSE
    LET partitionCount == ReadBytes(messageIndicator.rest, 2) IN IF ~partitionCount.ok THEN Fail ELSE
    LET ipDetailsPartitionWise == DecodeIpDetailsPartitionWise(partitionCount.rest) IN IF ~ipDetailsPartitionWise.ok THEN Fail ELSE
    LET sessionKey == ReadBytes(ipDetailsPartitionWise.rest, 8) IN IF ~sessionKey.ok THEN Fail ELSE
    LET cryptographicKey == ReadBytes(sessionKey.rest, 32) IN IF ~cryptographicKey.ok THEN Fail ELSE
    LET cryptographicIv == ReadBytes(cryptographicKey.rest, 16) IN IF ~cryptographicIv.ok THEN Fail ELSE
    Ok([ messageIndicator       |-> messageIndicator.value,
         partitionCount         |-> partitionCount.value,
         ipDetailsPartitionWise |-> ipDetailsPartitionWise.value,
         sessionKey             |-> sessionKey.value,
         cryptographicKey       |-> cryptographicKey.value,
         cryptographicIv        |-> cryptographicIv.value ], cryptographicIv.rest)

ZeroGrResponseMessage ==
    [ messageIndicator       |-> [i \in 1 .. 2 |-> 0],
      partitionCount         |-> [i \in 1 .. 2 |-> 0],
      ipDetailsPartitionWise |-> ZeroIpDetailsPartitionWise,
      sessionKey             |-> [i \in 1 .. 8 |-> 0],
      cryptographicKey       |-> [i \in 1 .. 32 |-> 0],
      cryptographicIv        |-> [i \in 1 .. 16 |-> 0] ]

(* Gr Response Message at zero, then each field in turn at the values it is checked at *)
CheckedGrResponseMessage ==
    { ZeroGrResponseMessage }
        \cup { [ZeroGrResponseMessage EXCEPT !.messageIndicator = one] : one \in Sample(2) }
        \cup { [ZeroGrResponseMessage EXCEPT !.partitionCount = one] : one \in Sample(2) }
        \cup { [ZeroGrResponseMessage EXCEPT !.ipDetailsPartitionWise = one] : one \in CheckedIpDetailsPartitionWise }
        \cup { [ZeroGrResponseMessage EXCEPT !.sessionKey = one] : one \in Sample(8) }
        \cup { [ZeroGrResponseMessage EXCEPT !.cryptographicKey = one] : one \in Sample(32) }
        \cup { [ZeroGrResponseMessage EXCEPT !.cryptographicIv = one] : one \in Sample(16) }

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
(* Trade Confirmation Message: 116 bytes                                   *)
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
      settlor               : Sample(12) ]

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
         settlor               |-> settlor.value ], settlor.rest)

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
      settlor               |-> [i \in 1 .. 12 |-> 0] ]

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

(***************************************************************************)
(* Trade Cancel Confirm Message: 116 bytes                                 *)
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
      settlor               : Sample(12) ]

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
         settlor               |-> settlor.value ], settlor.rest)

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
      settlor               |-> [i \in 1 .. 12 |-> 0] ]

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

(***************************************************************************)
(* Trade Cancel Reject Message: 116 bytes                                  *)
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
      settlor               : Sample(12) ]

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
         settlor               |-> settlor.value ], settlor.rest)

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
      settlor               |-> [i \in 1 .. 12 |-> 0] ]

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

(***************************************************************************)
(* Trade Modify Confirm Message: 116 bytes                                 *)
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
      settlor               : Sample(12) ]

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
         settlor               |-> settlor.value ], settlor.rest)

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
      settlor               |-> [i \in 1 .. 12 |-> 0] ]

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

(***************************************************************************)
(* Price Confirmation Message: 112 bytes                                   *)
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
      competitorPeriod      : Sample(2),
      solicitorPeriod       : Sample(2),
      auctionNumber         : Sample(2),
      suspended             : Sample(1),
      filler                : Sample(1),
      pan                   : Sample(10),
      segmentChar1          : Sample(1),
      participantType       : Sample(1),
      accountNumber         : Sample(10),
      proClientChar1        : Sample(1),
      settlementType        : Sample(1),
      settlor               : Sample(12) ]

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
        \o message.competitorPeriod
        \o message.solicitorPeriod
        \o message.auctionNumber
        \o message.suspended
        \o message.filler
        \o message.pan
        \o message.segmentChar1
        \o message.participantType
        \o message.accountNumber
        \o message.proClientChar1
        \o message.settlementType
        \o message.settlor

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
    LET competitorPeriod == ReadBytes(activityTimeInNanos.rest, 2) IN IF ~competitorPeriod.ok THEN Fail ELSE
    LET solicitorPeriod == ReadBytes(competitorPeriod.rest, 2) IN IF ~solicitorPeriod.ok THEN Fail ELSE
    LET auctionNumber == ReadBytes(solicitorPeriod.rest, 2) IN IF ~auctionNumber.ok THEN Fail ELSE
    LET suspended == ReadBytes(auctionNumber.rest, 1) IN IF ~suspended.ok THEN Fail ELSE
    LET filler == ReadBytes(suspended.rest, 1) IN IF ~filler.ok THEN Fail ELSE
    LET pan == ReadBytes(filler.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET segmentChar1 == ReadBytes(pan.rest, 1) IN IF ~segmentChar1.ok THEN Fail ELSE
    LET participantType == ReadBytes(segmentChar1.rest, 1) IN IF ~participantType.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(participantType.rest, 10) IN IF ~accountNumber.ok THEN Fail ELSE
    LET proClientChar1 == ReadBytes(accountNumber.rest, 1) IN IF ~proClientChar1.ok THEN Fail ELSE
    LET settlementType == ReadBytes(proClientChar1.rest, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET settlor == ReadBytes(settlementType.rest, 12) IN IF ~settlor.ok THEN Fail ELSE
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
         competitorPeriod      |-> competitorPeriod.value,
         solicitorPeriod       |-> solicitorPeriod.value,
         auctionNumber         |-> auctionNumber.value,
         suspended             |-> suspended.value,
         filler                |-> filler.value,
         pan                   |-> pan.value,
         segmentChar1          |-> segmentChar1.value,
         participantType       |-> participantType.value,
         accountNumber         |-> accountNumber.value,
         proClientChar1        |-> proClientChar1.value,
         settlementType        |-> settlementType.value,
         settlor               |-> settlor.value ], settlor.rest)

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
      competitorPeriod      |-> [i \in 1 .. 2 |-> 0],
      solicitorPeriod       |-> [i \in 1 .. 2 |-> 0],
      auctionNumber         |-> [i \in 1 .. 2 |-> 0],
      suspended             |-> [i \in 1 .. 1 |-> 0],
      filler                |-> [i \in 1 .. 1 |-> 0],
      pan                   |-> [i \in 1 .. 10 |-> 0],
      segmentChar1          |-> [i \in 1 .. 1 |-> 0],
      participantType       |-> [i \in 1 .. 1 |-> 0],
      accountNumber         |-> [i \in 1 .. 10 |-> 0],
      proClientChar1        |-> [i \in 1 .. 1 |-> 0],
      settlementType        |-> [i \in 1 .. 1 |-> 0],
      settlor               |-> [i \in 1 .. 12 |-> 0] ]

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
        \cup { [ZeroPriceConfirmationMessage EXCEPT !.competitorPeriod = one] : one \in Sample(2) }
        \cup { [ZeroPriceConfirmationMessage EXCEPT !.solicitorPeriod = one] : one \in Sample(2) }
        \cup { [ZeroPriceConfirmationMessage EXCEPT !.auctionNumber = one] : one \in Sample(2) }
        \cup { [ZeroPriceConfirmationMessage EXCEPT !.suspended = one] : one \in Sample(1) }
        \cup { [ZeroPriceConfirmationMessage EXCEPT !.filler = one] : one \in Sample(1) }
        \cup { [ZeroPriceConfirmationMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroPriceConfirmationMessage EXCEPT !.segmentChar1 = one] : one \in Sample(1) }
        \cup { [ZeroPriceConfirmationMessage EXCEPT !.participantType = one] : one \in Sample(1) }
        \cup { [ZeroPriceConfirmationMessage EXCEPT !.accountNumber = one] : one \in Sample(10) }
        \cup { [ZeroPriceConfirmationMessage EXCEPT !.proClientChar1 = one] : one \in Sample(1) }
        \cup { [ZeroPriceConfirmationMessage EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroPriceConfirmationMessage EXCEPT !.settlor = one] : one \in Sample(12) }

(***************************************************************************)
(* Order Mod Reject Message: 112 bytes                                     *)
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
      competitorPeriod      : Sample(2),
      solicitorPeriod       : Sample(2),
      auctionNumber         : Sample(2),
      suspended             : Sample(1),
      filler                : Sample(1),
      pan                   : Sample(10),
      segmentChar1          : Sample(1),
      participantType       : Sample(1),
      accountNumber         : Sample(10),
      proClientChar1        : Sample(1),
      settlementType        : Sample(1),
      settlor               : Sample(12) ]

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
        \o message.competitorPeriod
        \o message.solicitorPeriod
        \o message.auctionNumber
        \o message.suspended
        \o message.filler
        \o message.pan
        \o message.segmentChar1
        \o message.participantType
        \o message.accountNumber
        \o message.proClientChar1
        \o message.settlementType
        \o message.settlor

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
    LET competitorPeriod == ReadBytes(activityTimeInNanos.rest, 2) IN IF ~competitorPeriod.ok THEN Fail ELSE
    LET solicitorPeriod == ReadBytes(competitorPeriod.rest, 2) IN IF ~solicitorPeriod.ok THEN Fail ELSE
    LET auctionNumber == ReadBytes(solicitorPeriod.rest, 2) IN IF ~auctionNumber.ok THEN Fail ELSE
    LET suspended == ReadBytes(auctionNumber.rest, 1) IN IF ~suspended.ok THEN Fail ELSE
    LET filler == ReadBytes(suspended.rest, 1) IN IF ~filler.ok THEN Fail ELSE
    LET pan == ReadBytes(filler.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET segmentChar1 == ReadBytes(pan.rest, 1) IN IF ~segmentChar1.ok THEN Fail ELSE
    LET participantType == ReadBytes(segmentChar1.rest, 1) IN IF ~participantType.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(participantType.rest, 10) IN IF ~accountNumber.ok THEN Fail ELSE
    LET proClientChar1 == ReadBytes(accountNumber.rest, 1) IN IF ~proClientChar1.ok THEN Fail ELSE
    LET settlementType == ReadBytes(proClientChar1.rest, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET settlor == ReadBytes(settlementType.rest, 12) IN IF ~settlor.ok THEN Fail ELSE
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
         competitorPeriod      |-> competitorPeriod.value,
         solicitorPeriod       |-> solicitorPeriod.value,
         auctionNumber         |-> auctionNumber.value,
         suspended             |-> suspended.value,
         filler                |-> filler.value,
         pan                   |-> pan.value,
         segmentChar1          |-> segmentChar1.value,
         participantType       |-> participantType.value,
         accountNumber         |-> accountNumber.value,
         proClientChar1        |-> proClientChar1.value,
         settlementType        |-> settlementType.value,
         settlor               |-> settlor.value ], settlor.rest)

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
      competitorPeriod      |-> [i \in 1 .. 2 |-> 0],
      solicitorPeriod       |-> [i \in 1 .. 2 |-> 0],
      auctionNumber         |-> [i \in 1 .. 2 |-> 0],
      suspended             |-> [i \in 1 .. 1 |-> 0],
      filler                |-> [i \in 1 .. 1 |-> 0],
      pan                   |-> [i \in 1 .. 10 |-> 0],
      segmentChar1          |-> [i \in 1 .. 1 |-> 0],
      participantType       |-> [i \in 1 .. 1 |-> 0],
      accountNumber         |-> [i \in 1 .. 10 |-> 0],
      proClientChar1        |-> [i \in 1 .. 1 |-> 0],
      settlementType        |-> [i \in 1 .. 1 |-> 0],
      settlor               |-> [i \in 1 .. 12 |-> 0] ]

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
        \cup { [ZeroOrderModRejectMessage EXCEPT !.competitorPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOrderModRejectMessage EXCEPT !.solicitorPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOrderModRejectMessage EXCEPT !.auctionNumber = one] : one \in Sample(2) }
        \cup { [ZeroOrderModRejectMessage EXCEPT !.suspended = one] : one \in Sample(1) }
        \cup { [ZeroOrderModRejectMessage EXCEPT !.filler = one] : one \in Sample(1) }
        \cup { [ZeroOrderModRejectMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroOrderModRejectMessage EXCEPT !.segmentChar1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderModRejectMessage EXCEPT !.participantType = one] : one \in Sample(1) }
        \cup { [ZeroOrderModRejectMessage EXCEPT !.accountNumber = one] : one \in Sample(10) }
        \cup { [ZeroOrderModRejectMessage EXCEPT !.proClientChar1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderModRejectMessage EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroOrderModRejectMessage EXCEPT !.settlor = one] : one \in Sample(12) }

(***************************************************************************)
(* Order Cancel Reject Message: 112 bytes                                  *)
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
      competitorPeriod      : Sample(2),
      solicitorPeriod       : Sample(2),
      auctionNumber         : Sample(2),
      suspended             : Sample(1),
      filler                : Sample(1),
      pan                   : Sample(10),
      segmentChar1          : Sample(1),
      participantType       : Sample(1),
      accountNumber         : Sample(10),
      proClientChar1        : Sample(1),
      settlementType        : Sample(1),
      settlor               : Sample(12) ]

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
        \o message.competitorPeriod
        \o message.solicitorPeriod
        \o message.auctionNumber
        \o message.suspended
        \o message.filler
        \o message.pan
        \o message.segmentChar1
        \o message.participantType
        \o message.accountNumber
        \o message.proClientChar1
        \o message.settlementType
        \o message.settlor

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
    LET competitorPeriod == ReadBytes(activityTimeInNanos.rest, 2) IN IF ~competitorPeriod.ok THEN Fail ELSE
    LET solicitorPeriod == ReadBytes(competitorPeriod.rest, 2) IN IF ~solicitorPeriod.ok THEN Fail ELSE
    LET auctionNumber == ReadBytes(solicitorPeriod.rest, 2) IN IF ~auctionNumber.ok THEN Fail ELSE
    LET suspended == ReadBytes(auctionNumber.rest, 1) IN IF ~suspended.ok THEN Fail ELSE
    LET filler == ReadBytes(suspended.rest, 1) IN IF ~filler.ok THEN Fail ELSE
    LET pan == ReadBytes(filler.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET segmentChar1 == ReadBytes(pan.rest, 1) IN IF ~segmentChar1.ok THEN Fail ELSE
    LET participantType == ReadBytes(segmentChar1.rest, 1) IN IF ~participantType.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(participantType.rest, 10) IN IF ~accountNumber.ok THEN Fail ELSE
    LET proClientChar1 == ReadBytes(accountNumber.rest, 1) IN IF ~proClientChar1.ok THEN Fail ELSE
    LET settlementType == ReadBytes(proClientChar1.rest, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET settlor == ReadBytes(settlementType.rest, 12) IN IF ~settlor.ok THEN Fail ELSE
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
         competitorPeriod      |-> competitorPeriod.value,
         solicitorPeriod       |-> solicitorPeriod.value,
         auctionNumber         |-> auctionNumber.value,
         suspended             |-> suspended.value,
         filler                |-> filler.value,
         pan                   |-> pan.value,
         segmentChar1          |-> segmentChar1.value,
         participantType       |-> participantType.value,
         accountNumber         |-> accountNumber.value,
         proClientChar1        |-> proClientChar1.value,
         settlementType        |-> settlementType.value,
         settlor               |-> settlor.value ], settlor.rest)

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
      competitorPeriod      |-> [i \in 1 .. 2 |-> 0],
      solicitorPeriod       |-> [i \in 1 .. 2 |-> 0],
      auctionNumber         |-> [i \in 1 .. 2 |-> 0],
      suspended             |-> [i \in 1 .. 1 |-> 0],
      filler                |-> [i \in 1 .. 1 |-> 0],
      pan                   |-> [i \in 1 .. 10 |-> 0],
      segmentChar1          |-> [i \in 1 .. 1 |-> 0],
      participantType       |-> [i \in 1 .. 1 |-> 0],
      accountNumber         |-> [i \in 1 .. 10 |-> 0],
      proClientChar1        |-> [i \in 1 .. 1 |-> 0],
      settlementType        |-> [i \in 1 .. 1 |-> 0],
      settlor               |-> [i \in 1 .. 12 |-> 0] ]

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
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.competitorPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.solicitorPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.auctionNumber = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.suspended = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.filler = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.segmentChar1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.participantType = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.accountNumber = one] : one \in Sample(10) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.proClientChar1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.settlor = one] : one \in Sample(12) }

(***************************************************************************)
(* Order Confirmation Message: 112 bytes                                   *)
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
      competitorPeriod      : Sample(2),
      solicitorPeriod       : Sample(2),
      auctionNumber         : Sample(2),
      suspended             : Sample(1),
      filler                : Sample(1),
      pan                   : Sample(10),
      segmentChar1          : Sample(1),
      participantType       : Sample(1),
      accountNumber         : Sample(10),
      proClientChar1        : Sample(1),
      settlementType        : Sample(1),
      settlor               : Sample(12) ]

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
        \o message.competitorPeriod
        \o message.solicitorPeriod
        \o message.auctionNumber
        \o message.suspended
        \o message.filler
        \o message.pan
        \o message.segmentChar1
        \o message.participantType
        \o message.accountNumber
        \o message.proClientChar1
        \o message.settlementType
        \o message.settlor

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
    LET competitorPeriod == ReadBytes(activityTimeInNanos.rest, 2) IN IF ~competitorPeriod.ok THEN Fail ELSE
    LET solicitorPeriod == ReadBytes(competitorPeriod.rest, 2) IN IF ~solicitorPeriod.ok THEN Fail ELSE
    LET auctionNumber == ReadBytes(solicitorPeriod.rest, 2) IN IF ~auctionNumber.ok THEN Fail ELSE
    LET suspended == ReadBytes(auctionNumber.rest, 1) IN IF ~suspended.ok THEN Fail ELSE
    LET filler == ReadBytes(suspended.rest, 1) IN IF ~filler.ok THEN Fail ELSE
    LET pan == ReadBytes(filler.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET segmentChar1 == ReadBytes(pan.rest, 1) IN IF ~segmentChar1.ok THEN Fail ELSE
    LET participantType == ReadBytes(segmentChar1.rest, 1) IN IF ~participantType.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(participantType.rest, 10) IN IF ~accountNumber.ok THEN Fail ELSE
    LET proClientChar1 == ReadBytes(accountNumber.rest, 1) IN IF ~proClientChar1.ok THEN Fail ELSE
    LET settlementType == ReadBytes(proClientChar1.rest, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET settlor == ReadBytes(settlementType.rest, 12) IN IF ~settlor.ok THEN Fail ELSE
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
         competitorPeriod      |-> competitorPeriod.value,
         solicitorPeriod       |-> solicitorPeriod.value,
         auctionNumber         |-> auctionNumber.value,
         suspended             |-> suspended.value,
         filler                |-> filler.value,
         pan                   |-> pan.value,
         segmentChar1          |-> segmentChar1.value,
         participantType       |-> participantType.value,
         accountNumber         |-> accountNumber.value,
         proClientChar1        |-> proClientChar1.value,
         settlementType        |-> settlementType.value,
         settlor               |-> settlor.value ], settlor.rest)

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
      competitorPeriod      |-> [i \in 1 .. 2 |-> 0],
      solicitorPeriod       |-> [i \in 1 .. 2 |-> 0],
      auctionNumber         |-> [i \in 1 .. 2 |-> 0],
      suspended             |-> [i \in 1 .. 1 |-> 0],
      filler                |-> [i \in 1 .. 1 |-> 0],
      pan                   |-> [i \in 1 .. 10 |-> 0],
      segmentChar1          |-> [i \in 1 .. 1 |-> 0],
      participantType       |-> [i \in 1 .. 1 |-> 0],
      accountNumber         |-> [i \in 1 .. 10 |-> 0],
      proClientChar1        |-> [i \in 1 .. 1 |-> 0],
      settlementType        |-> [i \in 1 .. 1 |-> 0],
      settlor               |-> [i \in 1 .. 12 |-> 0] ]

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
        \cup { [ZeroOrderConfirmationMessage EXCEPT !.competitorPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOrderConfirmationMessage EXCEPT !.solicitorPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOrderConfirmationMessage EXCEPT !.auctionNumber = one] : one \in Sample(2) }
        \cup { [ZeroOrderConfirmationMessage EXCEPT !.suspended = one] : one \in Sample(1) }
        \cup { [ZeroOrderConfirmationMessage EXCEPT !.filler = one] : one \in Sample(1) }
        \cup { [ZeroOrderConfirmationMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroOrderConfirmationMessage EXCEPT !.segmentChar1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderConfirmationMessage EXCEPT !.participantType = one] : one \in Sample(1) }
        \cup { [ZeroOrderConfirmationMessage EXCEPT !.accountNumber = one] : one \in Sample(10) }
        \cup { [ZeroOrderConfirmationMessage EXCEPT !.proClientChar1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderConfirmationMessage EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroOrderConfirmationMessage EXCEPT !.settlor = one] : one \in Sample(12) }

(***************************************************************************)
(* Order Mod Confirmation Message: 112 bytes                               *)
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
      competitorPeriod      : Sample(2),
      solicitorPeriod       : Sample(2),
      auctionNumber         : Sample(2),
      suspended             : Sample(1),
      filler                : Sample(1),
      pan                   : Sample(10),
      segmentChar1          : Sample(1),
      participantType       : Sample(1),
      accountNumber         : Sample(10),
      proClientChar1        : Sample(1),
      settlementType        : Sample(1),
      settlor               : Sample(12) ]

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
        \o message.competitorPeriod
        \o message.solicitorPeriod
        \o message.auctionNumber
        \o message.suspended
        \o message.filler
        \o message.pan
        \o message.segmentChar1
        \o message.participantType
        \o message.accountNumber
        \o message.proClientChar1
        \o message.settlementType
        \o message.settlor

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
    LET competitorPeriod == ReadBytes(activityTimeInNanos.rest, 2) IN IF ~competitorPeriod.ok THEN Fail ELSE
    LET solicitorPeriod == ReadBytes(competitorPeriod.rest, 2) IN IF ~solicitorPeriod.ok THEN Fail ELSE
    LET auctionNumber == ReadBytes(solicitorPeriod.rest, 2) IN IF ~auctionNumber.ok THEN Fail ELSE
    LET suspended == ReadBytes(auctionNumber.rest, 1) IN IF ~suspended.ok THEN Fail ELSE
    LET filler == ReadBytes(suspended.rest, 1) IN IF ~filler.ok THEN Fail ELSE
    LET pan == ReadBytes(filler.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET segmentChar1 == ReadBytes(pan.rest, 1) IN IF ~segmentChar1.ok THEN Fail ELSE
    LET participantType == ReadBytes(segmentChar1.rest, 1) IN IF ~participantType.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(participantType.rest, 10) IN IF ~accountNumber.ok THEN Fail ELSE
    LET proClientChar1 == ReadBytes(accountNumber.rest, 1) IN IF ~proClientChar1.ok THEN Fail ELSE
    LET settlementType == ReadBytes(proClientChar1.rest, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET settlor == ReadBytes(settlementType.rest, 12) IN IF ~settlor.ok THEN Fail ELSE
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
         competitorPeriod      |-> competitorPeriod.value,
         solicitorPeriod       |-> solicitorPeriod.value,
         auctionNumber         |-> auctionNumber.value,
         suspended             |-> suspended.value,
         filler                |-> filler.value,
         pan                   |-> pan.value,
         segmentChar1          |-> segmentChar1.value,
         participantType       |-> participantType.value,
         accountNumber         |-> accountNumber.value,
         proClientChar1        |-> proClientChar1.value,
         settlementType        |-> settlementType.value,
         settlor               |-> settlor.value ], settlor.rest)

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
      competitorPeriod      |-> [i \in 1 .. 2 |-> 0],
      solicitorPeriod       |-> [i \in 1 .. 2 |-> 0],
      auctionNumber         |-> [i \in 1 .. 2 |-> 0],
      suspended             |-> [i \in 1 .. 1 |-> 0],
      filler                |-> [i \in 1 .. 1 |-> 0],
      pan                   |-> [i \in 1 .. 10 |-> 0],
      segmentChar1          |-> [i \in 1 .. 1 |-> 0],
      participantType       |-> [i \in 1 .. 1 |-> 0],
      accountNumber         |-> [i \in 1 .. 10 |-> 0],
      proClientChar1        |-> [i \in 1 .. 1 |-> 0],
      settlementType        |-> [i \in 1 .. 1 |-> 0],
      settlor               |-> [i \in 1 .. 12 |-> 0] ]

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
        \cup { [ZeroOrderModConfirmationMessage EXCEPT !.competitorPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOrderModConfirmationMessage EXCEPT !.solicitorPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOrderModConfirmationMessage EXCEPT !.auctionNumber = one] : one \in Sample(2) }
        \cup { [ZeroOrderModConfirmationMessage EXCEPT !.suspended = one] : one \in Sample(1) }
        \cup { [ZeroOrderModConfirmationMessage EXCEPT !.filler = one] : one \in Sample(1) }
        \cup { [ZeroOrderModConfirmationMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroOrderModConfirmationMessage EXCEPT !.segmentChar1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderModConfirmationMessage EXCEPT !.participantType = one] : one \in Sample(1) }
        \cup { [ZeroOrderModConfirmationMessage EXCEPT !.accountNumber = one] : one \in Sample(10) }
        \cup { [ZeroOrderModConfirmationMessage EXCEPT !.proClientChar1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderModConfirmationMessage EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroOrderModConfirmationMessage EXCEPT !.settlor = one] : one \in Sample(12) }

(***************************************************************************)
(* Order Cancel Confirmation Message: 112 bytes                            *)
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
      competitorPeriod      : Sample(2),
      solicitorPeriod       : Sample(2),
      auctionNumber         : Sample(2),
      suspended             : Sample(1),
      filler                : Sample(1),
      pan                   : Sample(10),
      segmentChar1          : Sample(1),
      participantType       : Sample(1),
      accountNumber         : Sample(10),
      proClientChar1        : Sample(1),
      settlementType        : Sample(1),
      settlor               : Sample(12) ]

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
        \o message.competitorPeriod
        \o message.solicitorPeriod
        \o message.auctionNumber
        \o message.suspended
        \o message.filler
        \o message.pan
        \o message.segmentChar1
        \o message.participantType
        \o message.accountNumber
        \o message.proClientChar1
        \o message.settlementType
        \o message.settlor

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
    LET competitorPeriod == ReadBytes(activityTimeInNanos.rest, 2) IN IF ~competitorPeriod.ok THEN Fail ELSE
    LET solicitorPeriod == ReadBytes(competitorPeriod.rest, 2) IN IF ~solicitorPeriod.ok THEN Fail ELSE
    LET auctionNumber == ReadBytes(solicitorPeriod.rest, 2) IN IF ~auctionNumber.ok THEN Fail ELSE
    LET suspended == ReadBytes(auctionNumber.rest, 1) IN IF ~suspended.ok THEN Fail ELSE
    LET filler == ReadBytes(suspended.rest, 1) IN IF ~filler.ok THEN Fail ELSE
    LET pan == ReadBytes(filler.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET segmentChar1 == ReadBytes(pan.rest, 1) IN IF ~segmentChar1.ok THEN Fail ELSE
    LET participantType == ReadBytes(segmentChar1.rest, 1) IN IF ~participantType.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(participantType.rest, 10) IN IF ~accountNumber.ok THEN Fail ELSE
    LET proClientChar1 == ReadBytes(accountNumber.rest, 1) IN IF ~proClientChar1.ok THEN Fail ELSE
    LET settlementType == ReadBytes(proClientChar1.rest, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET settlor == ReadBytes(settlementType.rest, 12) IN IF ~settlor.ok THEN Fail ELSE
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
         competitorPeriod      |-> competitorPeriod.value,
         solicitorPeriod       |-> solicitorPeriod.value,
         auctionNumber         |-> auctionNumber.value,
         suspended             |-> suspended.value,
         filler                |-> filler.value,
         pan                   |-> pan.value,
         segmentChar1          |-> segmentChar1.value,
         participantType       |-> participantType.value,
         accountNumber         |-> accountNumber.value,
         proClientChar1        |-> proClientChar1.value,
         settlementType        |-> settlementType.value,
         settlor               |-> settlor.value ], settlor.rest)

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
      competitorPeriod      |-> [i \in 1 .. 2 |-> 0],
      solicitorPeriod       |-> [i \in 1 .. 2 |-> 0],
      auctionNumber         |-> [i \in 1 .. 2 |-> 0],
      suspended             |-> [i \in 1 .. 1 |-> 0],
      filler                |-> [i \in 1 .. 1 |-> 0],
      pan                   |-> [i \in 1 .. 10 |-> 0],
      segmentChar1          |-> [i \in 1 .. 1 |-> 0],
      participantType       |-> [i \in 1 .. 1 |-> 0],
      accountNumber         |-> [i \in 1 .. 10 |-> 0],
      proClientChar1        |-> [i \in 1 .. 1 |-> 0],
      settlementType        |-> [i \in 1 .. 1 |-> 0],
      settlor               |-> [i \in 1 .. 12 |-> 0] ]

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
        \cup { [ZeroOrderCancelConfirmationMessage EXCEPT !.competitorPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelConfirmationMessage EXCEPT !.solicitorPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelConfirmationMessage EXCEPT !.auctionNumber = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelConfirmationMessage EXCEPT !.suspended = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelConfirmationMessage EXCEPT !.filler = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelConfirmationMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroOrderCancelConfirmationMessage EXCEPT !.segmentChar1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelConfirmationMessage EXCEPT !.participantType = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelConfirmationMessage EXCEPT !.accountNumber = one] : one \in Sample(10) }
        \cup { [ZeroOrderCancelConfirmationMessage EXCEPT !.proClientChar1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelConfirmationMessage EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelConfirmationMessage EXCEPT !.settlor = one] : one \in Sample(12) }

(***************************************************************************)
(* Freeze To Control Message: 112 bytes                                    *)
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
      competitorPeriod      : Sample(2),
      solicitorPeriod       : Sample(2),
      auctionNumber         : Sample(2),
      suspended             : Sample(1),
      filler                : Sample(1),
      pan                   : Sample(10),
      segmentChar1          : Sample(1),
      participantType       : Sample(1),
      accountNumber         : Sample(10),
      proClientChar1        : Sample(1),
      settlementType        : Sample(1),
      settlor               : Sample(12) ]

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
        \o message.competitorPeriod
        \o message.solicitorPeriod
        \o message.auctionNumber
        \o message.suspended
        \o message.filler
        \o message.pan
        \o message.segmentChar1
        \o message.participantType
        \o message.accountNumber
        \o message.proClientChar1
        \o message.settlementType
        \o message.settlor

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
    LET competitorPeriod == ReadBytes(activityTimeInNanos.rest, 2) IN IF ~competitorPeriod.ok THEN Fail ELSE
    LET solicitorPeriod == ReadBytes(competitorPeriod.rest, 2) IN IF ~solicitorPeriod.ok THEN Fail ELSE
    LET auctionNumber == ReadBytes(solicitorPeriod.rest, 2) IN IF ~auctionNumber.ok THEN Fail ELSE
    LET suspended == ReadBytes(auctionNumber.rest, 1) IN IF ~suspended.ok THEN Fail ELSE
    LET filler == ReadBytes(suspended.rest, 1) IN IF ~filler.ok THEN Fail ELSE
    LET pan == ReadBytes(filler.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET segmentChar1 == ReadBytes(pan.rest, 1) IN IF ~segmentChar1.ok THEN Fail ELSE
    LET participantType == ReadBytes(segmentChar1.rest, 1) IN IF ~participantType.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(participantType.rest, 10) IN IF ~accountNumber.ok THEN Fail ELSE
    LET proClientChar1 == ReadBytes(accountNumber.rest, 1) IN IF ~proClientChar1.ok THEN Fail ELSE
    LET settlementType == ReadBytes(proClientChar1.rest, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET settlor == ReadBytes(settlementType.rest, 12) IN IF ~settlor.ok THEN Fail ELSE
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
         competitorPeriod      |-> competitorPeriod.value,
         solicitorPeriod       |-> solicitorPeriod.value,
         auctionNumber         |-> auctionNumber.value,
         suspended             |-> suspended.value,
         filler                |-> filler.value,
         pan                   |-> pan.value,
         segmentChar1          |-> segmentChar1.value,
         participantType       |-> participantType.value,
         accountNumber         |-> accountNumber.value,
         proClientChar1        |-> proClientChar1.value,
         settlementType        |-> settlementType.value,
         settlor               |-> settlor.value ], settlor.rest)

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
      competitorPeriod      |-> [i \in 1 .. 2 |-> 0],
      solicitorPeriod       |-> [i \in 1 .. 2 |-> 0],
      auctionNumber         |-> [i \in 1 .. 2 |-> 0],
      suspended             |-> [i \in 1 .. 1 |-> 0],
      filler                |-> [i \in 1 .. 1 |-> 0],
      pan                   |-> [i \in 1 .. 10 |-> 0],
      segmentChar1          |-> [i \in 1 .. 1 |-> 0],
      participantType       |-> [i \in 1 .. 1 |-> 0],
      accountNumber         |-> [i \in 1 .. 10 |-> 0],
      proClientChar1        |-> [i \in 1 .. 1 |-> 0],
      settlementType        |-> [i \in 1 .. 1 |-> 0],
      settlor               |-> [i \in 1 .. 12 |-> 0] ]

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
        \cup { [ZeroFreezeToControlMessage EXCEPT !.competitorPeriod = one] : one \in Sample(2) }
        \cup { [ZeroFreezeToControlMessage EXCEPT !.solicitorPeriod = one] : one \in Sample(2) }
        \cup { [ZeroFreezeToControlMessage EXCEPT !.auctionNumber = one] : one \in Sample(2) }
        \cup { [ZeroFreezeToControlMessage EXCEPT !.suspended = one] : one \in Sample(1) }
        \cup { [ZeroFreezeToControlMessage EXCEPT !.filler = one] : one \in Sample(1) }
        \cup { [ZeroFreezeToControlMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroFreezeToControlMessage EXCEPT !.segmentChar1 = one] : one \in Sample(1) }
        \cup { [ZeroFreezeToControlMessage EXCEPT !.participantType = one] : one \in Sample(1) }
        \cup { [ZeroFreezeToControlMessage EXCEPT !.accountNumber = one] : one \in Sample(10) }
        \cup { [ZeroFreezeToControlMessage EXCEPT !.proClientChar1 = one] : one \in Sample(1) }
        \cup { [ZeroFreezeToControlMessage EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroFreezeToControlMessage EXCEPT !.settlor = one] : one \in Sample(12) }

(***************************************************************************)
(* On Stop Notification Message: 112 bytes                                 *)
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
      competitorPeriod      : Sample(2),
      solicitorPeriod       : Sample(2),
      auctionNumber         : Sample(2),
      suspended             : Sample(1),
      filler                : Sample(1),
      pan                   : Sample(10),
      segmentChar1          : Sample(1),
      participantType       : Sample(1),
      accountNumber         : Sample(10),
      proClientChar1        : Sample(1),
      settlementType        : Sample(1),
      settlor               : Sample(12) ]

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
        \o message.competitorPeriod
        \o message.solicitorPeriod
        \o message.auctionNumber
        \o message.suspended
        \o message.filler
        \o message.pan
        \o message.segmentChar1
        \o message.participantType
        \o message.accountNumber
        \o message.proClientChar1
        \o message.settlementType
        \o message.settlor

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
    LET competitorPeriod == ReadBytes(activityTimeInNanos.rest, 2) IN IF ~competitorPeriod.ok THEN Fail ELSE
    LET solicitorPeriod == ReadBytes(competitorPeriod.rest, 2) IN IF ~solicitorPeriod.ok THEN Fail ELSE
    LET auctionNumber == ReadBytes(solicitorPeriod.rest, 2) IN IF ~auctionNumber.ok THEN Fail ELSE
    LET suspended == ReadBytes(auctionNumber.rest, 1) IN IF ~suspended.ok THEN Fail ELSE
    LET filler == ReadBytes(suspended.rest, 1) IN IF ~filler.ok THEN Fail ELSE
    LET pan == ReadBytes(filler.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET segmentChar1 == ReadBytes(pan.rest, 1) IN IF ~segmentChar1.ok THEN Fail ELSE
    LET participantType == ReadBytes(segmentChar1.rest, 1) IN IF ~participantType.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(participantType.rest, 10) IN IF ~accountNumber.ok THEN Fail ELSE
    LET proClientChar1 == ReadBytes(accountNumber.rest, 1) IN IF ~proClientChar1.ok THEN Fail ELSE
    LET settlementType == ReadBytes(proClientChar1.rest, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET settlor == ReadBytes(settlementType.rest, 12) IN IF ~settlor.ok THEN Fail ELSE
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
         competitorPeriod      |-> competitorPeriod.value,
         solicitorPeriod       |-> solicitorPeriod.value,
         auctionNumber         |-> auctionNumber.value,
         suspended             |-> suspended.value,
         filler                |-> filler.value,
         pan                   |-> pan.value,
         segmentChar1          |-> segmentChar1.value,
         participantType       |-> participantType.value,
         accountNumber         |-> accountNumber.value,
         proClientChar1        |-> proClientChar1.value,
         settlementType        |-> settlementType.value,
         settlor               |-> settlor.value ], settlor.rest)

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
      competitorPeriod      |-> [i \in 1 .. 2 |-> 0],
      solicitorPeriod       |-> [i \in 1 .. 2 |-> 0],
      auctionNumber         |-> [i \in 1 .. 2 |-> 0],
      suspended             |-> [i \in 1 .. 1 |-> 0],
      filler                |-> [i \in 1 .. 1 |-> 0],
      pan                   |-> [i \in 1 .. 10 |-> 0],
      segmentChar1          |-> [i \in 1 .. 1 |-> 0],
      participantType       |-> [i \in 1 .. 1 |-> 0],
      accountNumber         |-> [i \in 1 .. 10 |-> 0],
      proClientChar1        |-> [i \in 1 .. 1 |-> 0],
      settlementType        |-> [i \in 1 .. 1 |-> 0],
      settlor               |-> [i \in 1 .. 12 |-> 0] ]

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
        \cup { [ZeroOnStopNotificationMessage EXCEPT !.competitorPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOnStopNotificationMessage EXCEPT !.solicitorPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOnStopNotificationMessage EXCEPT !.auctionNumber = one] : one \in Sample(2) }
        \cup { [ZeroOnStopNotificationMessage EXCEPT !.suspended = one] : one \in Sample(1) }
        \cup { [ZeroOnStopNotificationMessage EXCEPT !.filler = one] : one \in Sample(1) }
        \cup { [ZeroOnStopNotificationMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroOnStopNotificationMessage EXCEPT !.segmentChar1 = one] : one \in Sample(1) }
        \cup { [ZeroOnStopNotificationMessage EXCEPT !.participantType = one] : one \in Sample(1) }
        \cup { [ZeroOnStopNotificationMessage EXCEPT !.accountNumber = one] : one \in Sample(10) }
        \cup { [ZeroOnStopNotificationMessage EXCEPT !.proClientChar1 = one] : one \in Sample(1) }
        \cup { [ZeroOnStopNotificationMessage EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroOnStopNotificationMessage EXCEPT !.settlor = one] : one \in Sample(12) }

(***************************************************************************)
(* Order Error Message: 112 bytes                                          *)
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
      competitorPeriod      : Sample(2),
      solicitorPeriod       : Sample(2),
      auctionNumber         : Sample(2),
      suspended             : Sample(1),
      filler                : Sample(1),
      pan                   : Sample(10),
      segmentChar1          : Sample(1),
      participantType       : Sample(1),
      accountNumber         : Sample(10),
      proClientChar1        : Sample(1),
      settlementType        : Sample(1),
      settlor               : Sample(12) ]

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
        \o message.competitorPeriod
        \o message.solicitorPeriod
        \o message.auctionNumber
        \o message.suspended
        \o message.filler
        \o message.pan
        \o message.segmentChar1
        \o message.participantType
        \o message.accountNumber
        \o message.proClientChar1
        \o message.settlementType
        \o message.settlor

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
    LET competitorPeriod == ReadBytes(activityTimeInNanos.rest, 2) IN IF ~competitorPeriod.ok THEN Fail ELSE
    LET solicitorPeriod == ReadBytes(competitorPeriod.rest, 2) IN IF ~solicitorPeriod.ok THEN Fail ELSE
    LET auctionNumber == ReadBytes(solicitorPeriod.rest, 2) IN IF ~auctionNumber.ok THEN Fail ELSE
    LET suspended == ReadBytes(auctionNumber.rest, 1) IN IF ~suspended.ok THEN Fail ELSE
    LET filler == ReadBytes(suspended.rest, 1) IN IF ~filler.ok THEN Fail ELSE
    LET pan == ReadBytes(filler.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET segmentChar1 == ReadBytes(pan.rest, 1) IN IF ~segmentChar1.ok THEN Fail ELSE
    LET participantType == ReadBytes(segmentChar1.rest, 1) IN IF ~participantType.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(participantType.rest, 10) IN IF ~accountNumber.ok THEN Fail ELSE
    LET proClientChar1 == ReadBytes(accountNumber.rest, 1) IN IF ~proClientChar1.ok THEN Fail ELSE
    LET settlementType == ReadBytes(proClientChar1.rest, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET settlor == ReadBytes(settlementType.rest, 12) IN IF ~settlor.ok THEN Fail ELSE
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
         competitorPeriod      |-> competitorPeriod.value,
         solicitorPeriod       |-> solicitorPeriod.value,
         auctionNumber         |-> auctionNumber.value,
         suspended             |-> suspended.value,
         filler                |-> filler.value,
         pan                   |-> pan.value,
         segmentChar1          |-> segmentChar1.value,
         participantType       |-> participantType.value,
         accountNumber         |-> accountNumber.value,
         proClientChar1        |-> proClientChar1.value,
         settlementType        |-> settlementType.value,
         settlor               |-> settlor.value ], settlor.rest)

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
      competitorPeriod      |-> [i \in 1 .. 2 |-> 0],
      solicitorPeriod       |-> [i \in 1 .. 2 |-> 0],
      auctionNumber         |-> [i \in 1 .. 2 |-> 0],
      suspended             |-> [i \in 1 .. 1 |-> 0],
      filler                |-> [i \in 1 .. 1 |-> 0],
      pan                   |-> [i \in 1 .. 10 |-> 0],
      segmentChar1          |-> [i \in 1 .. 1 |-> 0],
      participantType       |-> [i \in 1 .. 1 |-> 0],
      accountNumber         |-> [i \in 1 .. 10 |-> 0],
      proClientChar1        |-> [i \in 1 .. 1 |-> 0],
      settlementType        |-> [i \in 1 .. 1 |-> 0],
      settlor               |-> [i \in 1 .. 12 |-> 0] ]

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
        \cup { [ZeroOrderErrorMessage EXCEPT !.competitorPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOrderErrorMessage EXCEPT !.solicitorPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOrderErrorMessage EXCEPT !.auctionNumber = one] : one \in Sample(2) }
        \cup { [ZeroOrderErrorMessage EXCEPT !.suspended = one] : one \in Sample(1) }
        \cup { [ZeroOrderErrorMessage EXCEPT !.filler = one] : one \in Sample(1) }
        \cup { [ZeroOrderErrorMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroOrderErrorMessage EXCEPT !.segmentChar1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderErrorMessage EXCEPT !.participantType = one] : one \in Sample(1) }
        \cup { [ZeroOrderErrorMessage EXCEPT !.accountNumber = one] : one \in Sample(10) }
        \cup { [ZeroOrderErrorMessage EXCEPT !.proClientChar1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderErrorMessage EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroOrderErrorMessage EXCEPT !.settlor = one] : one \in Sample(12) }

(***************************************************************************)
(* Batch Order Cancel Message: 112 bytes                                   *)
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
      competitorPeriod      : Sample(2),
      solicitorPeriod       : Sample(2),
      auctionNumber         : Sample(2),
      suspended             : Sample(1),
      filler                : Sample(1),
      pan                   : Sample(10),
      segmentChar1          : Sample(1),
      participantType       : Sample(1),
      accountNumber         : Sample(10),
      proClientChar1        : Sample(1),
      settlementType        : Sample(1),
      settlor               : Sample(12) ]

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
        \o message.competitorPeriod
        \o message.solicitorPeriod
        \o message.auctionNumber
        \o message.suspended
        \o message.filler
        \o message.pan
        \o message.segmentChar1
        \o message.participantType
        \o message.accountNumber
        \o message.proClientChar1
        \o message.settlementType
        \o message.settlor

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
    LET competitorPeriod == ReadBytes(activityTimeInNanos.rest, 2) IN IF ~competitorPeriod.ok THEN Fail ELSE
    LET solicitorPeriod == ReadBytes(competitorPeriod.rest, 2) IN IF ~solicitorPeriod.ok THEN Fail ELSE
    LET auctionNumber == ReadBytes(solicitorPeriod.rest, 2) IN IF ~auctionNumber.ok THEN Fail ELSE
    LET suspended == ReadBytes(auctionNumber.rest, 1) IN IF ~suspended.ok THEN Fail ELSE
    LET filler == ReadBytes(suspended.rest, 1) IN IF ~filler.ok THEN Fail ELSE
    LET pan == ReadBytes(filler.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET segmentChar1 == ReadBytes(pan.rest, 1) IN IF ~segmentChar1.ok THEN Fail ELSE
    LET participantType == ReadBytes(segmentChar1.rest, 1) IN IF ~participantType.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(participantType.rest, 10) IN IF ~accountNumber.ok THEN Fail ELSE
    LET proClientChar1 == ReadBytes(accountNumber.rest, 1) IN IF ~proClientChar1.ok THEN Fail ELSE
    LET settlementType == ReadBytes(proClientChar1.rest, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET settlor == ReadBytes(settlementType.rest, 12) IN IF ~settlor.ok THEN Fail ELSE
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
         competitorPeriod      |-> competitorPeriod.value,
         solicitorPeriod       |-> solicitorPeriod.value,
         auctionNumber         |-> auctionNumber.value,
         suspended             |-> suspended.value,
         filler                |-> filler.value,
         pan                   |-> pan.value,
         segmentChar1          |-> segmentChar1.value,
         participantType       |-> participantType.value,
         accountNumber         |-> accountNumber.value,
         proClientChar1        |-> proClientChar1.value,
         settlementType        |-> settlementType.value,
         settlor               |-> settlor.value ], settlor.rest)

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
      competitorPeriod      |-> [i \in 1 .. 2 |-> 0],
      solicitorPeriod       |-> [i \in 1 .. 2 |-> 0],
      auctionNumber         |-> [i \in 1 .. 2 |-> 0],
      suspended             |-> [i \in 1 .. 1 |-> 0],
      filler                |-> [i \in 1 .. 1 |-> 0],
      pan                   |-> [i \in 1 .. 10 |-> 0],
      segmentChar1          |-> [i \in 1 .. 1 |-> 0],
      participantType       |-> [i \in 1 .. 1 |-> 0],
      accountNumber         |-> [i \in 1 .. 10 |-> 0],
      proClientChar1        |-> [i \in 1 .. 1 |-> 0],
      settlementType        |-> [i \in 1 .. 1 |-> 0],
      settlor               |-> [i \in 1 .. 12 |-> 0] ]

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
        \cup { [ZeroBatchOrderCancelMessage EXCEPT !.competitorPeriod = one] : one \in Sample(2) }
        \cup { [ZeroBatchOrderCancelMessage EXCEPT !.solicitorPeriod = one] : one \in Sample(2) }
        \cup { [ZeroBatchOrderCancelMessage EXCEPT !.auctionNumber = one] : one \in Sample(2) }
        \cup { [ZeroBatchOrderCancelMessage EXCEPT !.suspended = one] : one \in Sample(1) }
        \cup { [ZeroBatchOrderCancelMessage EXCEPT !.filler = one] : one \in Sample(1) }
        \cup { [ZeroBatchOrderCancelMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroBatchOrderCancelMessage EXCEPT !.segmentChar1 = one] : one \in Sample(1) }
        \cup { [ZeroBatchOrderCancelMessage EXCEPT !.participantType = one] : one \in Sample(1) }
        \cup { [ZeroBatchOrderCancelMessage EXCEPT !.accountNumber = one] : one \in Sample(10) }
        \cup { [ZeroBatchOrderCancelMessage EXCEPT !.proClientChar1 = one] : one \in Sample(1) }
        \cup { [ZeroBatchOrderCancelMessage EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroBatchOrderCancelMessage EXCEPT !.settlor = one] : one \in Sample(12) }

(***************************************************************************)
(* Server Message Payload, selected by Transaction Code                    *)
(***************************************************************************)

GrResponseMessageCode == 2401  \* 0x961
GrSecureUserRegistrationResponseMessageCode == 23009  \* 0x59e1
DcSignonOutMessageCode == 2501  \* 0x9c5
DcErrorResponseTradeMessageCode == 8006  \* 0x1f46
DcErrorResponseOrderMessageCode == 9006  \* 0x232e
TradeConfirmationMessageCode == 2222  \* 0x8ae
TradeCancelConfirmMessageCode == 2282  \* 0x8ea
TradeCancelRejectMessageCode == 2286  \* 0x8ee
TradeModifyConfirmMessageCode == 2287  \* 0x8ef
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

ServerMessagePayload ==
    [ tag : {GrResponseMessageCode}, body : GrResponseMessage ]
        \cup [ tag : {GrSecureUserRegistrationResponseMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {DcSignonOutMessageCode}, body : DcSignonOutMessage ]
        \cup [ tag : {DcErrorResponseTradeMessageCode}, body : DcErrorResponseTradeMessage ]
        \cup [ tag : {DcErrorResponseOrderMessageCode}, body : DcErrorResponseOrderMessage ]
        \cup [ tag : {TradeConfirmationMessageCode}, body : TradeConfirmationMessage ]
        \cup [ tag : {TradeCancelConfirmMessageCode}, body : TradeCancelConfirmMessage ]
        \cup [ tag : {TradeCancelRejectMessageCode}, body : TradeCancelRejectMessage ]
        \cup [ tag : {TradeModifyConfirmMessageCode}, body : TradeModifyConfirmMessage ]
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

EncodeServerMessagePayload(message) ==
    CASE message.tag = GrResponseMessageCode -> EncodeGrResponseMessage(message.body)
      [] message.tag = GrSecureUserRegistrationResponseMessageCode -> << >>
      [] message.tag = DcSignonOutMessageCode -> EncodeDcSignonOutMessage(message.body)
      [] message.tag = DcErrorResponseTradeMessageCode -> EncodeDcErrorResponseTradeMessage(message.body)
      [] message.tag = DcErrorResponseOrderMessageCode -> EncodeDcErrorResponseOrderMessage(message.body)
      [] message.tag = TradeConfirmationMessageCode -> EncodeTradeConfirmationMessage(message.body)
      [] message.tag = TradeCancelConfirmMessageCode -> EncodeTradeCancelConfirmMessage(message.body)
      [] message.tag = TradeCancelRejectMessageCode -> EncodeTradeCancelRejectMessage(message.body)
      [] message.tag = TradeModifyConfirmMessageCode -> EncodeTradeModifyConfirmMessage(message.body)
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

DecodeServerMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = GrResponseMessageCode -> DecodeGrResponseMessage(bytes)
              [] tag = GrSecureUserRegistrationResponseMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = DcSignonOutMessageCode -> DecodeDcSignonOutMessage(bytes)
              [] tag = DcErrorResponseTradeMessageCode -> DecodeDcErrorResponseTradeMessage(bytes)
              [] tag = DcErrorResponseOrderMessageCode -> DecodeDcErrorResponseOrderMessage(bytes)
              [] tag = TradeConfirmationMessageCode -> DecodeTradeConfirmationMessage(bytes)
              [] tag = TradeCancelConfirmMessageCode -> DecodeTradeCancelConfirmMessage(bytes)
              [] tag = TradeCancelRejectMessageCode -> DecodeTradeCancelRejectMessage(bytes)
              [] tag = TradeModifyConfirmMessageCode -> DecodeTradeModifyConfirmMessage(bytes)
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
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroServerMessagePayload == [tag |-> GrResponseMessageCode, body |-> ZeroGrResponseMessage]

(* Each Server Message Payload in turn, at the values the message it names is checked at *)
CheckedServerMessagePayload ==
    { [tag |-> GrResponseMessageCode, body |-> one] : one \in CheckedGrResponseMessage }
        \cup { [tag |-> GrSecureUserRegistrationResponseMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> DcSignonOutMessageCode, body |-> one] : one \in CheckedDcSignonOutMessage }
        \cup { [tag |-> DcErrorResponseTradeMessageCode, body |-> one] : one \in CheckedDcErrorResponseTradeMessage }
        \cup { [tag |-> DcErrorResponseOrderMessageCode, body |-> one] : one \in CheckedDcErrorResponseOrderMessage }
        \cup { [tag |-> TradeConfirmationMessageCode, body |-> one] : one \in CheckedTradeConfirmationMessage }
        \cup { [tag |-> TradeCancelConfirmMessageCode, body |-> one] : one \in CheckedTradeCancelConfirmMessage }
        \cup { [tag |-> TradeCancelRejectMessageCode, body |-> one] : one \in CheckedTradeCancelRejectMessage }
        \cup { [tag |-> TradeModifyConfirmMessageCode, body |-> one] : one \in CheckedTradeModifyConfirmMessage }
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
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> DcErrorResponseTradeMessageCode, body |-> ZeroDcErrorResponseTradeMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> DcErrorResponseOrderMessageCode, body |-> ZeroDcErrorResponseOrderMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> TradeConfirmationMessageCode, body |-> ZeroTradeConfirmationMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> TradeCancelConfirmMessageCode, body |-> ZeroTradeCancelConfirmMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> TradeCancelRejectMessageCode, body |-> ZeroTradeCancelRejectMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> TradeModifyConfirmMessageCode, body |-> ZeroTradeModifyConfirmMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> PriceConfirmationMessageCode, body |-> ZeroPriceConfirmationMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> OrderModRejectMessageCode, body |-> ZeroOrderModRejectMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> OrderCancelRejectMessageCode, body |-> ZeroOrderCancelRejectMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> OrderConfirmationMessageCode, body |-> ZeroOrderConfirmationMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> OrderModConfirmationMessageCode, body |-> ZeroOrderModConfirmationMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> OrderCancelConfirmationMessageCode, body |-> ZeroOrderCancelConfirmationMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> FreezeToControlMessageCode, body |-> ZeroFreezeToControlMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> OnStopNotificationMessageCode, body |-> ZeroOnStopNotificationMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> OrderErrorMessageCode, body |-> ZeroOrderErrorMessage]],
      [ZeroServerMessage EXCEPT !.serverMessagePayload = [tag |-> BatchOrderCancelMessageCode, body |-> ZeroBatchOrderCancelMessage]] }

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
