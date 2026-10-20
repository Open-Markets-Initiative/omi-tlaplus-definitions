----------------------- MODULE Siac_Cqs_Input_v2_9_b -----------------------
(***************************************************************************)
(* The Securities Industry Automation Corporation  v2.9.b                  *)
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
(* Note: a Odd Lot Quote Appendage Type of any value but 83 or 83 or 76 or *)
(* 76 or 69 or 69 carries none of them.                                    *)
(*                                                                         *)
(* Note: Block Pad Byte pads to a 2 byte boundary: it is read as the bytes *)
(* left to the end of the frame, and the frame's length is trusted to keep *)
(* that boundary.                                                          *)
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
(* Timestamp 1: 8 bytes                                                    *)
(***************************************************************************)

Timestamp1 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp1(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp1(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp1 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 1 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp1 ==
    { ZeroTimestamp1 }
        \cup { [ZeroTimestamp1 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp1 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Rejection Message: 14 bytes                                             *)
(***************************************************************************)

RejectionMessage ==
    [ errorCode                  : Sample(1),
      blockSequenceNumber        : Sample(4),
      participantReferenceNumber : Sample(8),
      messageId                  : Sample(1) ]

EncodeRejectionMessage(message) ==
    message.errorCode
        \o message.blockSequenceNumber
        \o message.participantReferenceNumber
        \o message.messageId

DecodeRejectionMessage(bytes) ==
    LET errorCode == ReadBytes(bytes, 1) IN IF ~errorCode.ok THEN Fail ELSE
    LET blockSequenceNumber == ReadBytes(errorCode.rest, 4) IN IF ~blockSequenceNumber.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(blockSequenceNumber.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET messageId == ReadBytes(participantReferenceNumber.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    Ok([ errorCode                  |-> errorCode.value,
         blockSequenceNumber        |-> blockSequenceNumber.value,
         participantReferenceNumber |-> participantReferenceNumber.value,
         messageId                  |-> messageId.value ], messageId.rest)

ZeroRejectionMessage ==
    [ errorCode                  |-> [i \in 1 .. 1 |-> 0],
      blockSequenceNumber        |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      messageId                  |-> [i \in 1 .. 1 |-> 0] ]

(* Rejection Message at zero, then each field in turn at the values it is checked at *)
CheckedRejectionMessage ==
    { ZeroRejectionMessage }
        \cup { [ZeroRejectionMessage EXCEPT !.errorCode = one] : one \in Sample(1) }
        \cup { [ZeroRejectionMessage EXCEPT !.blockSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroRejectionMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroRejectionMessage EXCEPT !.messageId = one] : one \in Sample(1) }

(***************************************************************************)
(* Partial Reject Odd Lot Bid Short Quote Appendage: 3 bytes               *)
(***************************************************************************)

PartialRejectOddLotBidShortQuoteAppendage ==
    [ oddLotQuotePrice2 : Sample(2),
      oddLotQuoteSize   : Sample(1) ]

EncodePartialRejectOddLotBidShortQuoteAppendage(message) ==
    message.oddLotQuotePrice2
        \o message.oddLotQuoteSize

DecodePartialRejectOddLotBidShortQuoteAppendage(bytes) ==
    LET oddLotQuotePrice2 == ReadBytes(bytes, 2) IN IF ~oddLotQuotePrice2.ok THEN Fail ELSE
    LET oddLotQuoteSize == ReadBytes(oddLotQuotePrice2.rest, 1) IN IF ~oddLotQuoteSize.ok THEN Fail ELSE
    Ok([ oddLotQuotePrice2 |-> oddLotQuotePrice2.value,
         oddLotQuoteSize   |-> oddLotQuoteSize.value ], oddLotQuoteSize.rest)

ZeroPartialRejectOddLotBidShortQuoteAppendage ==
    [ oddLotQuotePrice2 |-> [i \in 1 .. 2 |-> 0],
      oddLotQuoteSize   |-> [i \in 1 .. 1 |-> 0] ]

(* Partial Reject Odd Lot Bid Short Quote Appendage at zero, then each field in turn at the values it is checked at *)
CheckedPartialRejectOddLotBidShortQuoteAppendage ==
    { ZeroPartialRejectOddLotBidShortQuoteAppendage }
        \cup { [ZeroPartialRejectOddLotBidShortQuoteAppendage EXCEPT !.oddLotQuotePrice2 = one] : one \in Sample(2) }
        \cup { [ZeroPartialRejectOddLotBidShortQuoteAppendage EXCEPT !.oddLotQuoteSize = one] : one \in Sample(1) }

(***************************************************************************)
(* Partial Reject Odd Lot Offer Short Quote Appendage: 3 bytes             *)
(***************************************************************************)

PartialRejectOddLotOfferShortQuoteAppendage ==
    [ oddLotQuotePrice2 : Sample(2),
      oddLotQuoteSize   : Sample(1) ]

EncodePartialRejectOddLotOfferShortQuoteAppendage(message) ==
    message.oddLotQuotePrice2
        \o message.oddLotQuoteSize

DecodePartialRejectOddLotOfferShortQuoteAppendage(bytes) ==
    LET oddLotQuotePrice2 == ReadBytes(bytes, 2) IN IF ~oddLotQuotePrice2.ok THEN Fail ELSE
    LET oddLotQuoteSize == ReadBytes(oddLotQuotePrice2.rest, 1) IN IF ~oddLotQuoteSize.ok THEN Fail ELSE
    Ok([ oddLotQuotePrice2 |-> oddLotQuotePrice2.value,
         oddLotQuoteSize   |-> oddLotQuoteSize.value ], oddLotQuoteSize.rest)

ZeroPartialRejectOddLotOfferShortQuoteAppendage ==
    [ oddLotQuotePrice2 |-> [i \in 1 .. 2 |-> 0],
      oddLotQuoteSize   |-> [i \in 1 .. 1 |-> 0] ]

(* Partial Reject Odd Lot Offer Short Quote Appendage at zero, then each field in turn at the values it is checked at *)
CheckedPartialRejectOddLotOfferShortQuoteAppendage ==
    { ZeroPartialRejectOddLotOfferShortQuoteAppendage }
        \cup { [ZeroPartialRejectOddLotOfferShortQuoteAppendage EXCEPT !.oddLotQuotePrice2 = one] : one \in Sample(2) }
        \cup { [ZeroPartialRejectOddLotOfferShortQuoteAppendage EXCEPT !.oddLotQuoteSize = one] : one \in Sample(1) }

(***************************************************************************)
(* Odd Lot Quote Appendage Type: 6 bytes                                   *)
(***************************************************************************)

PartialRejectOddLotBidShortQuoteAppendagePartialRejectOddLotOfferShortQuoteAppendage ==
    [ partialRejectOddLotBidShortQuoteAppendage   : PartialRejectOddLotBidShortQuoteAppendage,
      partialRejectOddLotOfferShortQuoteAppendage : PartialRejectOddLotOfferShortQuoteAppendage ]

EncodePartialRejectOddLotBidShortQuoteAppendagePartialRejectOddLotOfferShortQuoteAppendage(message) ==
    EncodePartialRejectOddLotBidShortQuoteAppendage(message.partialRejectOddLotBidShortQuoteAppendage)
        \o EncodePartialRejectOddLotOfferShortQuoteAppendage(message.partialRejectOddLotOfferShortQuoteAppendage)

DecodePartialRejectOddLotBidShortQuoteAppendagePartialRejectOddLotOfferShortQuoteAppendage(bytes) ==
    LET partialRejectOddLotBidShortQuoteAppendage == DecodePartialRejectOddLotBidShortQuoteAppendage(bytes) IN IF ~partialRejectOddLotBidShortQuoteAppendage.ok THEN Fail ELSE
    LET partialRejectOddLotOfferShortQuoteAppendage == DecodePartialRejectOddLotOfferShortQuoteAppendage(partialRejectOddLotBidShortQuoteAppendage.rest) IN IF ~partialRejectOddLotOfferShortQuoteAppendage.ok THEN Fail ELSE
    Ok([ partialRejectOddLotBidShortQuoteAppendage   |-> partialRejectOddLotBidShortQuoteAppendage.value,
         partialRejectOddLotOfferShortQuoteAppendage |-> partialRejectOddLotOfferShortQuoteAppendage.value ], partialRejectOddLotOfferShortQuoteAppendage.rest)

ZeroPartialRejectOddLotBidShortQuoteAppendagePartialRejectOddLotOfferShortQuoteAppendage ==
    [ partialRejectOddLotBidShortQuoteAppendage   |-> ZeroPartialRejectOddLotBidShortQuoteAppendage,
      partialRejectOddLotOfferShortQuoteAppendage |-> ZeroPartialRejectOddLotOfferShortQuoteAppendage ]

(* Odd Lot Quote Appendage Type at zero, then each field in turn at the values it is checked at *)
CheckedPartialRejectOddLotBidShortQuoteAppendagePartialRejectOddLotOfferShortQuoteAppendage ==
    { ZeroPartialRejectOddLotBidShortQuoteAppendagePartialRejectOddLotOfferShortQuoteAppendage }
        \cup { [ZeroPartialRejectOddLotBidShortQuoteAppendagePartialRejectOddLotOfferShortQuoteAppendage EXCEPT !.partialRejectOddLotBidShortQuoteAppendage = one] : one \in CheckedPartialRejectOddLotBidShortQuoteAppendage }
        \cup { [ZeroPartialRejectOddLotBidShortQuoteAppendagePartialRejectOddLotOfferShortQuoteAppendage EXCEPT !.partialRejectOddLotOfferShortQuoteAppendage = one] : one \in CheckedPartialRejectOddLotOfferShortQuoteAppendage }

(***************************************************************************)
(* Partial Reject Odd Lot Bid Long Quote Appendage: 9 bytes                *)
(***************************************************************************)

PartialRejectOddLotBidLongQuoteAppendage ==
    [ oddLotQuotePrice : Sample(8),
      oddLotQuoteSize  : Sample(1) ]

EncodePartialRejectOddLotBidLongQuoteAppendage(message) ==
    message.oddLotQuotePrice
        \o message.oddLotQuoteSize

DecodePartialRejectOddLotBidLongQuoteAppendage(bytes) ==
    LET oddLotQuotePrice == ReadBytes(bytes, 8) IN IF ~oddLotQuotePrice.ok THEN Fail ELSE
    LET oddLotQuoteSize == ReadBytes(oddLotQuotePrice.rest, 1) IN IF ~oddLotQuoteSize.ok THEN Fail ELSE
    Ok([ oddLotQuotePrice |-> oddLotQuotePrice.value,
         oddLotQuoteSize  |-> oddLotQuoteSize.value ], oddLotQuoteSize.rest)

ZeroPartialRejectOddLotBidLongQuoteAppendage ==
    [ oddLotQuotePrice |-> [i \in 1 .. 8 |-> 0],
      oddLotQuoteSize  |-> [i \in 1 .. 1 |-> 0] ]

(* Partial Reject Odd Lot Bid Long Quote Appendage at zero, then each field in turn at the values it is checked at *)
CheckedPartialRejectOddLotBidLongQuoteAppendage ==
    { ZeroPartialRejectOddLotBidLongQuoteAppendage }
        \cup { [ZeroPartialRejectOddLotBidLongQuoteAppendage EXCEPT !.oddLotQuotePrice = one] : one \in Sample(8) }
        \cup { [ZeroPartialRejectOddLotBidLongQuoteAppendage EXCEPT !.oddLotQuoteSize = one] : one \in Sample(1) }

(***************************************************************************)
(* Partial Reject Odd Lot Offer Long Quote Appendage: 9 bytes              *)
(***************************************************************************)

PartialRejectOddLotOfferLongQuoteAppendage ==
    [ oddLotQuotePrice : Sample(8),
      oddLotQuoteSize  : Sample(1) ]

EncodePartialRejectOddLotOfferLongQuoteAppendage(message) ==
    message.oddLotQuotePrice
        \o message.oddLotQuoteSize

DecodePartialRejectOddLotOfferLongQuoteAppendage(bytes) ==
    LET oddLotQuotePrice == ReadBytes(bytes, 8) IN IF ~oddLotQuotePrice.ok THEN Fail ELSE
    LET oddLotQuoteSize == ReadBytes(oddLotQuotePrice.rest, 1) IN IF ~oddLotQuoteSize.ok THEN Fail ELSE
    Ok([ oddLotQuotePrice |-> oddLotQuotePrice.value,
         oddLotQuoteSize  |-> oddLotQuoteSize.value ], oddLotQuoteSize.rest)

ZeroPartialRejectOddLotOfferLongQuoteAppendage ==
    [ oddLotQuotePrice |-> [i \in 1 .. 8 |-> 0],
      oddLotQuoteSize  |-> [i \in 1 .. 1 |-> 0] ]

(* Partial Reject Odd Lot Offer Long Quote Appendage at zero, then each field in turn at the values it is checked at *)
CheckedPartialRejectOddLotOfferLongQuoteAppendage ==
    { ZeroPartialRejectOddLotOfferLongQuoteAppendage }
        \cup { [ZeroPartialRejectOddLotOfferLongQuoteAppendage EXCEPT !.oddLotQuotePrice = one] : one \in Sample(8) }
        \cup { [ZeroPartialRejectOddLotOfferLongQuoteAppendage EXCEPT !.oddLotQuoteSize = one] : one \in Sample(1) }

(***************************************************************************)
(* Odd Lot Quote Appendage Type: 18 bytes                                  *)
(***************************************************************************)

PartialRejectOddLotBidLongQuoteAppendagePartialRejectOddLotOfferLongQuoteAppendage ==
    [ partialRejectOddLotBidLongQuoteAppendage   : PartialRejectOddLotBidLongQuoteAppendage,
      partialRejectOddLotOfferLongQuoteAppendage : PartialRejectOddLotOfferLongQuoteAppendage ]

EncodePartialRejectOddLotBidLongQuoteAppendagePartialRejectOddLotOfferLongQuoteAppendage(message) ==
    EncodePartialRejectOddLotBidLongQuoteAppendage(message.partialRejectOddLotBidLongQuoteAppendage)
        \o EncodePartialRejectOddLotOfferLongQuoteAppendage(message.partialRejectOddLotOfferLongQuoteAppendage)

DecodePartialRejectOddLotBidLongQuoteAppendagePartialRejectOddLotOfferLongQuoteAppendage(bytes) ==
    LET partialRejectOddLotBidLongQuoteAppendage == DecodePartialRejectOddLotBidLongQuoteAppendage(bytes) IN IF ~partialRejectOddLotBidLongQuoteAppendage.ok THEN Fail ELSE
    LET partialRejectOddLotOfferLongQuoteAppendage == DecodePartialRejectOddLotOfferLongQuoteAppendage(partialRejectOddLotBidLongQuoteAppendage.rest) IN IF ~partialRejectOddLotOfferLongQuoteAppendage.ok THEN Fail ELSE
    Ok([ partialRejectOddLotBidLongQuoteAppendage   |-> partialRejectOddLotBidLongQuoteAppendage.value,
         partialRejectOddLotOfferLongQuoteAppendage |-> partialRejectOddLotOfferLongQuoteAppendage.value ], partialRejectOddLotOfferLongQuoteAppendage.rest)

ZeroPartialRejectOddLotBidLongQuoteAppendagePartialRejectOddLotOfferLongQuoteAppendage ==
    [ partialRejectOddLotBidLongQuoteAppendage   |-> ZeroPartialRejectOddLotBidLongQuoteAppendage,
      partialRejectOddLotOfferLongQuoteAppendage |-> ZeroPartialRejectOddLotOfferLongQuoteAppendage ]

(* Odd Lot Quote Appendage Type at zero, then each field in turn at the values it is checked at *)
CheckedPartialRejectOddLotBidLongQuoteAppendagePartialRejectOddLotOfferLongQuoteAppendage ==
    { ZeroPartialRejectOddLotBidLongQuoteAppendagePartialRejectOddLotOfferLongQuoteAppendage }
        \cup { [ZeroPartialRejectOddLotBidLongQuoteAppendagePartialRejectOddLotOfferLongQuoteAppendage EXCEPT !.partialRejectOddLotBidLongQuoteAppendage = one] : one \in CheckedPartialRejectOddLotBidLongQuoteAppendage }
        \cup { [ZeroPartialRejectOddLotBidLongQuoteAppendagePartialRejectOddLotOfferLongQuoteAppendage EXCEPT !.partialRejectOddLotOfferLongQuoteAppendage = one] : one \in CheckedPartialRejectOddLotOfferLongQuoteAppendage }

(***************************************************************************)
(* Partial Reject Odd Lot Bid Extended Quote Appendage: 13 bytes           *)
(***************************************************************************)

PartialRejectOddLotBidExtendedQuoteAppendage ==
    [ oddLotQuotePrice         : Sample(8),
      oddLotQuoteSize          : Sample(1),
      oddLotFinraMarketMakerId : Sample(4) ]

EncodePartialRejectOddLotBidExtendedQuoteAppendage(message) ==
    message.oddLotQuotePrice
        \o message.oddLotQuoteSize
        \o message.oddLotFinraMarketMakerId

DecodePartialRejectOddLotBidExtendedQuoteAppendage(bytes) ==
    LET oddLotQuotePrice == ReadBytes(bytes, 8) IN IF ~oddLotQuotePrice.ok THEN Fail ELSE
    LET oddLotQuoteSize == ReadBytes(oddLotQuotePrice.rest, 1) IN IF ~oddLotQuoteSize.ok THEN Fail ELSE
    LET oddLotFinraMarketMakerId == ReadBytes(oddLotQuoteSize.rest, 4) IN IF ~oddLotFinraMarketMakerId.ok THEN Fail ELSE
    Ok([ oddLotQuotePrice         |-> oddLotQuotePrice.value,
         oddLotQuoteSize          |-> oddLotQuoteSize.value,
         oddLotFinraMarketMakerId |-> oddLotFinraMarketMakerId.value ], oddLotFinraMarketMakerId.rest)

ZeroPartialRejectOddLotBidExtendedQuoteAppendage ==
    [ oddLotQuotePrice         |-> [i \in 1 .. 8 |-> 0],
      oddLotQuoteSize          |-> [i \in 1 .. 1 |-> 0],
      oddLotFinraMarketMakerId |-> [i \in 1 .. 4 |-> 0] ]

(* Partial Reject Odd Lot Bid Extended Quote Appendage at zero, then each field in turn at the values it is checked at *)
CheckedPartialRejectOddLotBidExtendedQuoteAppendage ==
    { ZeroPartialRejectOddLotBidExtendedQuoteAppendage }
        \cup { [ZeroPartialRejectOddLotBidExtendedQuoteAppendage EXCEPT !.oddLotQuotePrice = one] : one \in Sample(8) }
        \cup { [ZeroPartialRejectOddLotBidExtendedQuoteAppendage EXCEPT !.oddLotQuoteSize = one] : one \in Sample(1) }
        \cup { [ZeroPartialRejectOddLotBidExtendedQuoteAppendage EXCEPT !.oddLotFinraMarketMakerId = one] : one \in Sample(4) }

(***************************************************************************)
(* Partial Reject Odd Lot Offer Extended Quote Appendage: 13 bytes         *)
(***************************************************************************)

PartialRejectOddLotOfferExtendedQuoteAppendage ==
    [ oddLotQuotePrice         : Sample(8),
      oddLotQuoteSize          : Sample(1),
      oddLotFinraMarketMakerId : Sample(4) ]

EncodePartialRejectOddLotOfferExtendedQuoteAppendage(message) ==
    message.oddLotQuotePrice
        \o message.oddLotQuoteSize
        \o message.oddLotFinraMarketMakerId

DecodePartialRejectOddLotOfferExtendedQuoteAppendage(bytes) ==
    LET oddLotQuotePrice == ReadBytes(bytes, 8) IN IF ~oddLotQuotePrice.ok THEN Fail ELSE
    LET oddLotQuoteSize == ReadBytes(oddLotQuotePrice.rest, 1) IN IF ~oddLotQuoteSize.ok THEN Fail ELSE
    LET oddLotFinraMarketMakerId == ReadBytes(oddLotQuoteSize.rest, 4) IN IF ~oddLotFinraMarketMakerId.ok THEN Fail ELSE
    Ok([ oddLotQuotePrice         |-> oddLotQuotePrice.value,
         oddLotQuoteSize          |-> oddLotQuoteSize.value,
         oddLotFinraMarketMakerId |-> oddLotFinraMarketMakerId.value ], oddLotFinraMarketMakerId.rest)

ZeroPartialRejectOddLotOfferExtendedQuoteAppendage ==
    [ oddLotQuotePrice         |-> [i \in 1 .. 8 |-> 0],
      oddLotQuoteSize          |-> [i \in 1 .. 1 |-> 0],
      oddLotFinraMarketMakerId |-> [i \in 1 .. 4 |-> 0] ]

(* Partial Reject Odd Lot Offer Extended Quote Appendage at zero, then each field in turn at the values it is checked at *)
CheckedPartialRejectOddLotOfferExtendedQuoteAppendage ==
    { ZeroPartialRejectOddLotOfferExtendedQuoteAppendage }
        \cup { [ZeroPartialRejectOddLotOfferExtendedQuoteAppendage EXCEPT !.oddLotQuotePrice = one] : one \in Sample(8) }
        \cup { [ZeroPartialRejectOddLotOfferExtendedQuoteAppendage EXCEPT !.oddLotQuoteSize = one] : one \in Sample(1) }
        \cup { [ZeroPartialRejectOddLotOfferExtendedQuoteAppendage EXCEPT !.oddLotFinraMarketMakerId = one] : one \in Sample(4) }

(***************************************************************************)
(* Odd Lot Quote Appendage Type: 26 bytes                                  *)
(***************************************************************************)

PartialRejectOddLotBidExtendedQuoteAppendagePartialRejectOddLotOfferExtendedQuoteAppendage ==
    [ partialRejectOddLotBidExtendedQuoteAppendage   : PartialRejectOddLotBidExtendedQuoteAppendage,
      partialRejectOddLotOfferExtendedQuoteAppendage : PartialRejectOddLotOfferExtendedQuoteAppendage ]

EncodePartialRejectOddLotBidExtendedQuoteAppendagePartialRejectOddLotOfferExtendedQuoteAppendage(message) ==
    EncodePartialRejectOddLotBidExtendedQuoteAppendage(message.partialRejectOddLotBidExtendedQuoteAppendage)
        \o EncodePartialRejectOddLotOfferExtendedQuoteAppendage(message.partialRejectOddLotOfferExtendedQuoteAppendage)

DecodePartialRejectOddLotBidExtendedQuoteAppendagePartialRejectOddLotOfferExtendedQuoteAppendage(bytes) ==
    LET partialRejectOddLotBidExtendedQuoteAppendage == DecodePartialRejectOddLotBidExtendedQuoteAppendage(bytes) IN IF ~partialRejectOddLotBidExtendedQuoteAppendage.ok THEN Fail ELSE
    LET partialRejectOddLotOfferExtendedQuoteAppendage == DecodePartialRejectOddLotOfferExtendedQuoteAppendage(partialRejectOddLotBidExtendedQuoteAppendage.rest) IN IF ~partialRejectOddLotOfferExtendedQuoteAppendage.ok THEN Fail ELSE
    Ok([ partialRejectOddLotBidExtendedQuoteAppendage   |-> partialRejectOddLotBidExtendedQuoteAppendage.value,
         partialRejectOddLotOfferExtendedQuoteAppendage |-> partialRejectOddLotOfferExtendedQuoteAppendage.value ], partialRejectOddLotOfferExtendedQuoteAppendage.rest)

ZeroPartialRejectOddLotBidExtendedQuoteAppendagePartialRejectOddLotOfferExtendedQuoteAppendage ==
    [ partialRejectOddLotBidExtendedQuoteAppendage   |-> ZeroPartialRejectOddLotBidExtendedQuoteAppendage,
      partialRejectOddLotOfferExtendedQuoteAppendage |-> ZeroPartialRejectOddLotOfferExtendedQuoteAppendage ]

(* Odd Lot Quote Appendage Type at zero, then each field in turn at the values it is checked at *)
CheckedPartialRejectOddLotBidExtendedQuoteAppendagePartialRejectOddLotOfferExtendedQuoteAppendage ==
    { ZeroPartialRejectOddLotBidExtendedQuoteAppendagePartialRejectOddLotOfferExtendedQuoteAppendage }
        \cup { [ZeroPartialRejectOddLotBidExtendedQuoteAppendagePartialRejectOddLotOfferExtendedQuoteAppendage EXCEPT !.partialRejectOddLotBidExtendedQuoteAppendage = one] : one \in CheckedPartialRejectOddLotBidExtendedQuoteAppendage }
        \cup { [ZeroPartialRejectOddLotBidExtendedQuoteAppendagePartialRejectOddLotOfferExtendedQuoteAppendage EXCEPT !.partialRejectOddLotOfferExtendedQuoteAppendage = one] : one \in CheckedPartialRejectOddLotOfferExtendedQuoteAppendage }

(***************************************************************************)
(* What Odd Lot Quote Appendage Type decides is present                    *)
(***************************************************************************)

PartialRejectOddLotBidShortQuoteAppendageCode == 83  \* "S"
PartialRejectOddLotBidLongQuoteAppendageCode == 76  \* "L"
PartialRejectOddLotBidExtendedQuoteAppendageCode == 69  \* "E"
OddLotQuoteAppendageTypeNoneCode == 0  \* 

OddLotQuoteAppendageTypeChoice ==
    [ tag : {PartialRejectOddLotBidShortQuoteAppendageCode}, body : PartialRejectOddLotBidShortQuoteAppendagePartialRejectOddLotOfferShortQuoteAppendage ]
        \cup [ tag : {PartialRejectOddLotBidLongQuoteAppendageCode}, body : PartialRejectOddLotBidLongQuoteAppendagePartialRejectOddLotOfferLongQuoteAppendage ]
        \cup [ tag : {PartialRejectOddLotBidExtendedQuoteAppendageCode}, body : PartialRejectOddLotBidExtendedQuoteAppendagePartialRejectOddLotOfferExtendedQuoteAppendage ]
        \cup [ tag : {OddLotQuoteAppendageTypeNoneCode}, body : {[empty |-> 0]} ]

EncodeOddLotQuoteAppendageTypeChoice(message) ==
    CASE message.tag = PartialRejectOddLotBidShortQuoteAppendageCode -> EncodePartialRejectOddLotBidShortQuoteAppendagePartialRejectOddLotOfferShortQuoteAppendage(message.body)
      [] message.tag = PartialRejectOddLotBidLongQuoteAppendageCode -> EncodePartialRejectOddLotBidLongQuoteAppendagePartialRejectOddLotOfferLongQuoteAppendage(message.body)
      [] message.tag = PartialRejectOddLotBidExtendedQuoteAppendageCode -> EncodePartialRejectOddLotBidExtendedQuoteAppendagePartialRejectOddLotOfferExtendedQuoteAppendage(message.body)
      [] OTHER -> << >>

DecodeOddLotQuoteAppendageTypeChoice(tag, bytes) ==
    LET read ==
            CASE tag = PartialRejectOddLotBidShortQuoteAppendageCode -> DecodePartialRejectOddLotBidShortQuoteAppendagePartialRejectOddLotOfferShortQuoteAppendage(bytes)
              [] tag = PartialRejectOddLotBidLongQuoteAppendageCode -> DecodePartialRejectOddLotBidLongQuoteAppendagePartialRejectOddLotOfferLongQuoteAppendage(bytes)
              [] tag = PartialRejectOddLotBidExtendedQuoteAppendageCode -> DecodePartialRejectOddLotBidExtendedQuoteAppendagePartialRejectOddLotOfferExtendedQuoteAppendage(bytes)
              [] OTHER -> Ok([empty |-> 0], bytes)
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroOddLotQuoteAppendageTypeChoice == [tag |-> PartialRejectOddLotBidShortQuoteAppendageCode, body |-> ZeroPartialRejectOddLotBidShortQuoteAppendagePartialRejectOddLotOfferShortQuoteAppendage]

(* Each Odd Lot Quote Appendage Type in turn, at the values the message it names is checked at *)
CheckedOddLotQuoteAppendageTypeChoice ==
    { [tag |-> PartialRejectOddLotBidShortQuoteAppendageCode, body |-> one] : one \in CheckedPartialRejectOddLotBidShortQuoteAppendagePartialRejectOddLotOfferShortQuoteAppendage }
        \cup { [tag |-> PartialRejectOddLotBidLongQuoteAppendageCode, body |-> one] : one \in CheckedPartialRejectOddLotBidLongQuoteAppendagePartialRejectOddLotOfferLongQuoteAppendage }
        \cup { [tag |-> PartialRejectOddLotBidExtendedQuoteAppendageCode, body |-> one] : one \in CheckedPartialRejectOddLotBidExtendedQuoteAppendagePartialRejectOddLotOfferExtendedQuoteAppendage }
        \cup { [tag |-> OddLotQuoteAppendageTypeNoneCode, body |-> [empty |-> 0]] }

(***************************************************************************)
(* Partial Rejection Message                                               *)
(***************************************************************************)

PartialRejectionMessage ==
    [ errorCode                      : Sample(1),
      blockSequenceNumber            : Sample(4),
      participantReferenceNumber     : Sample(8),
      messageId                      : Sample(1),
      countOfOddLotBidAppendages     : 0 .. 255,
      countOfOddLotOfferAppendages   : 0 .. 255,
      oddLotQuoteAppendageTypeChoice : OddLotQuoteAppendageTypeChoice ]

EncodePartialRejectionMessage(message) ==
    message.errorCode
        \o message.blockSequenceNumber
        \o message.participantReferenceNumber
        \o message.messageId
        \o EncodeUIntBE(message.oddLotQuoteAppendageTypeChoice.tag, 1)
        \o EncodeUIntBE(message.countOfOddLotBidAppendages, 1)
        \o EncodeUIntBE(message.countOfOddLotOfferAppendages, 1)
        \o EncodeOddLotQuoteAppendageTypeChoice(message.oddLotQuoteAppendageTypeChoice)

DecodePartialRejectionMessage(bytes) ==
    LET errorCode == ReadBytes(bytes, 1) IN IF ~errorCode.ok THEN Fail ELSE
    LET blockSequenceNumber == ReadBytes(errorCode.rest, 4) IN IF ~blockSequenceNumber.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(blockSequenceNumber.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET messageId == ReadBytes(participantReferenceNumber.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET oddLotQuoteAppendageType == ReadUIntBE(messageId.rest, 1) IN IF ~oddLotQuoteAppendageType.ok THEN Fail ELSE
    LET countOfOddLotBidAppendages == ReadUIntBE(oddLotQuoteAppendageType.rest, 1) IN IF ~countOfOddLotBidAppendages.ok THEN Fail ELSE
    LET countOfOddLotOfferAppendages == ReadUIntBE(countOfOddLotBidAppendages.rest, 1) IN IF ~countOfOddLotOfferAppendages.ok THEN Fail ELSE
    LET oddLotQuoteAppendageTypeChoice == DecodeOddLotQuoteAppendageTypeChoice(oddLotQuoteAppendageType.value, countOfOddLotOfferAppendages.rest) IN IF ~oddLotQuoteAppendageTypeChoice.ok THEN Fail ELSE
    Ok([ errorCode                      |-> errorCode.value,
         blockSequenceNumber            |-> blockSequenceNumber.value,
         participantReferenceNumber     |-> participantReferenceNumber.value,
         messageId                      |-> messageId.value,
         countOfOddLotBidAppendages     |-> countOfOddLotBidAppendages.value,
         countOfOddLotOfferAppendages   |-> countOfOddLotOfferAppendages.value,
         oddLotQuoteAppendageTypeChoice |-> oddLotQuoteAppendageTypeChoice.value ], oddLotQuoteAppendageTypeChoice.rest)

ZeroPartialRejectionMessage ==
    [ errorCode                      |-> [i \in 1 .. 1 |-> 0],
      blockSequenceNumber            |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber     |-> [i \in 1 .. 8 |-> 0],
      messageId                      |-> [i \in 1 .. 1 |-> 0],
      countOfOddLotBidAppendages     |-> 0,
      countOfOddLotOfferAppendages   |-> 0,
      oddLotQuoteAppendageTypeChoice |-> ZeroOddLotQuoteAppendageTypeChoice ]

(* Partial Rejection Message at zero, then each field in turn at the values it is checked at *)
CheckedPartialRejectionMessage ==
    { ZeroPartialRejectionMessage }
        \cup { [ZeroPartialRejectionMessage EXCEPT !.errorCode = one] : one \in Sample(1) }
        \cup { [ZeroPartialRejectionMessage EXCEPT !.blockSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroPartialRejectionMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroPartialRejectionMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroPartialRejectionMessage EXCEPT !.countOfOddLotBidAppendages = one] : one \in {0, 1, 255} }
        \cup { [ZeroPartialRejectionMessage EXCEPT !.countOfOddLotOfferAppendages = one] : one \in {0, 1, 255} }
        \cup { [ZeroPartialRejectionMessage EXCEPT !.oddLotQuoteAppendageTypeChoice = one] : one \in CheckedOddLotQuoteAppendageTypeChoice }

(***************************************************************************)
(* Warning Message: 12 bytes                                               *)
(***************************************************************************)

WarningMessage ==
    [ previousBlockSequenceNumber        : Sample(4),
      previousParticipantReferenceNumber : Sample(8) ]

EncodeWarningMessage(message) ==
    message.previousBlockSequenceNumber
        \o message.previousParticipantReferenceNumber

DecodeWarningMessage(bytes) ==
    LET previousBlockSequenceNumber == ReadBytes(bytes, 4) IN IF ~previousBlockSequenceNumber.ok THEN Fail ELSE
    LET previousParticipantReferenceNumber == ReadBytes(previousBlockSequenceNumber.rest, 8) IN IF ~previousParticipantReferenceNumber.ok THEN Fail ELSE
    Ok([ previousBlockSequenceNumber        |-> previousBlockSequenceNumber.value,
         previousParticipantReferenceNumber |-> previousParticipantReferenceNumber.value ], previousParticipantReferenceNumber.rest)

ZeroWarningMessage ==
    [ previousBlockSequenceNumber        |-> [i \in 1 .. 4 |-> 0],
      previousParticipantReferenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Warning Message at zero, then each field in turn at the values it is checked at *)
CheckedWarningMessage ==
    { ZeroWarningMessage }
        \cup { [ZeroWarningMessage EXCEPT !.previousBlockSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroWarningMessage EXCEPT !.previousParticipantReferenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Administrative Message Payload, selected by Administrative Message Type *)
(***************************************************************************)

RejectionMessageCode == 82  \* "R"
PartialRejectionMessageCode == 80  \* "P"
WarningMessageCode == 87  \* "W"

AdministrativeMessagePayload ==
    [ tag : {RejectionMessageCode}, body : RejectionMessage ]
        \cup [ tag : {PartialRejectionMessageCode}, body : PartialRejectionMessage ]
        \cup [ tag : {WarningMessageCode}, body : WarningMessage ]

EncodeAdministrativeMessagePayload(message) ==
    CASE message.tag = RejectionMessageCode -> EncodeRejectionMessage(message.body)
      [] message.tag = PartialRejectionMessageCode -> EncodePartialRejectionMessage(message.body)
      [] message.tag = WarningMessageCode -> EncodeWarningMessage(message.body)

DecodeAdministrativeMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = RejectionMessageCode -> DecodeRejectionMessage(bytes)
              [] tag = PartialRejectionMessageCode -> DecodePartialRejectionMessage(bytes)
              [] tag = WarningMessageCode -> DecodeWarningMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroAdministrativeMessagePayload == [tag |-> RejectionMessageCode, body |-> ZeroRejectionMessage]

(* Each Administrative Message Payload in turn, at the values the message it names is checked at *)
CheckedAdministrativeMessagePayload ==
    { [tag |-> RejectionMessageCode, body |-> one] : one \in CheckedRejectionMessage }
        \cup { [tag |-> PartialRejectionMessageCode, body |-> one] : one \in CheckedPartialRejectionMessage }
        \cup { [tag |-> WarningMessageCode, body |-> one] : one \in CheckedWarningMessage }

(***************************************************************************)
(* Administrative Message                                                  *)
(***************************************************************************)

AdministrativeMessage ==
    [ administrativeMessagePayload : AdministrativeMessagePayload ]

EncodeAdministrativeMessage(message) ==
    EncodeUIntBE(message.administrativeMessagePayload.tag, 1)
        \o EncodeAdministrativeMessagePayload(message.administrativeMessagePayload)

DecodeAdministrativeMessage(bytes) ==
    LET administrativeMessageType == ReadUIntBE(bytes, 1) IN IF ~administrativeMessageType.ok THEN Fail ELSE
    LET administrativeMessagePayload == DecodeAdministrativeMessagePayload(administrativeMessageType.value, administrativeMessageType.rest) IN IF ~administrativeMessagePayload.ok THEN Fail ELSE
    Ok([ administrativeMessagePayload |-> administrativeMessagePayload.value ], administrativeMessagePayload.rest)

ZeroAdministrativeMessage ==
    [ administrativeMessagePayload |-> ZeroAdministrativeMessagePayload ]

(* Administrative Message at zero, then each field in turn at the values it is checked at *)
CheckedAdministrativeMessage ==
    { ZeroAdministrativeMessage }
        \cup { [ZeroAdministrativeMessage EXCEPT !.administrativeMessagePayload = one] : one \in CheckedAdministrativeMessagePayload }

(***************************************************************************)
(* Sequence Information And Message Count Response Message: 20 bytes       *)
(***************************************************************************)

SequenceInformationAndMessageCountResponseMessage ==
    [ currentBlockSequenceNumber     : Sample(4),
      lastParticipantReferenceNumber : Sample(8),
      messageCount                   : Sample(8) ]

EncodeSequenceInformationAndMessageCountResponseMessage(message) ==
    message.currentBlockSequenceNumber
        \o message.lastParticipantReferenceNumber
        \o message.messageCount

DecodeSequenceInformationAndMessageCountResponseMessage(bytes) ==
    LET currentBlockSequenceNumber == ReadBytes(bytes, 4) IN IF ~currentBlockSequenceNumber.ok THEN Fail ELSE
    LET lastParticipantReferenceNumber == ReadBytes(currentBlockSequenceNumber.rest, 8) IN IF ~lastParticipantReferenceNumber.ok THEN Fail ELSE
    LET messageCount == ReadBytes(lastParticipantReferenceNumber.rest, 8) IN IF ~messageCount.ok THEN Fail ELSE
    Ok([ currentBlockSequenceNumber     |-> currentBlockSequenceNumber.value,
         lastParticipantReferenceNumber |-> lastParticipantReferenceNumber.value,
         messageCount                   |-> messageCount.value ], messageCount.rest)

ZeroSequenceInformationAndMessageCountResponseMessage ==
    [ currentBlockSequenceNumber     |-> [i \in 1 .. 4 |-> 0],
      lastParticipantReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      messageCount                   |-> [i \in 1 .. 8 |-> 0] ]

(* Sequence Information And Message Count Response Message at zero, then each field in turn at the values it is checked at *)
CheckedSequenceInformationAndMessageCountResponseMessage ==
    { ZeroSequenceInformationAndMessageCountResponseMessage }
        \cup { [ZeroSequenceInformationAndMessageCountResponseMessage EXCEPT !.currentBlockSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroSequenceInformationAndMessageCountResponseMessage EXCEPT !.lastParticipantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSequenceInformationAndMessageCountResponseMessage EXCEPT !.messageCount = one] : one \in Sample(8) }

(***************************************************************************)
(* Odd Lot Refresh Request Message: 30 bytes                               *)
(***************************************************************************)

OddLotRefreshRequestMessage ==
    [ securitySymbolBeginRange : Sample(11),
      securitySymbolEndRange   : Sample(11),
      reserved8                : Sample(8) ]

EncodeOddLotRefreshRequestMessage(message) ==
    message.securitySymbolBeginRange
        \o message.securitySymbolEndRange
        \o message.reserved8

DecodeOddLotRefreshRequestMessage(bytes) ==
    LET securitySymbolBeginRange == ReadBytes(bytes, 11) IN IF ~securitySymbolBeginRange.ok THEN Fail ELSE
    LET securitySymbolEndRange == ReadBytes(securitySymbolBeginRange.rest, 11) IN IF ~securitySymbolEndRange.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(securitySymbolEndRange.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    Ok([ securitySymbolBeginRange |-> securitySymbolBeginRange.value,
         securitySymbolEndRange   |-> securitySymbolEndRange.value,
         reserved8                |-> reserved8.value ], reserved8.rest)

ZeroOddLotRefreshRequestMessage ==
    [ securitySymbolBeginRange |-> [i \in 1 .. 11 |-> 0],
      securitySymbolEndRange   |-> [i \in 1 .. 11 |-> 0],
      reserved8                |-> [i \in 1 .. 8 |-> 0] ]

(* Odd Lot Refresh Request Message at zero, then each field in turn at the values it is checked at *)
CheckedOddLotRefreshRequestMessage ==
    { ZeroOddLotRefreshRequestMessage }
        \cup { [ZeroOddLotRefreshRequestMessage EXCEPT !.securitySymbolBeginRange = one] : one \in Sample(11) }
        \cup { [ZeroOddLotRefreshRequestMessage EXCEPT !.securitySymbolEndRange = one] : one \in Sample(11) }
        \cup { [ZeroOddLotRefreshRequestMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }

(***************************************************************************)
(* Test Message: 256 bytes                                                 *)
(***************************************************************************)

TestMessage ==
    [ data : Sample(256) ]

EncodeTestMessage(message) ==
    message.data

DecodeTestMessage(bytes) ==
    LET data == ReadBytes(bytes, 256) IN IF ~data.ok THEN Fail ELSE
    Ok([ data |-> data.value ], data.rest)

ZeroTestMessage ==
    [ data |-> [i \in 1 .. 256 |-> 0] ]

(* Test Message at zero, then each field in turn at the values it is checked at *)
CheckedTestMessage ==
    { ZeroTestMessage }
        \cup { [ZeroTestMessage EXCEPT !.data = one] : one \in Sample(256) }

(***************************************************************************)
(* Control Message Payload, selected by Control Message Type               *)
(***************************************************************************)

StartOfDayMessageCode == 65  \* "A"
FinraCloseMessageCode == 67  \* "C"
SequenceInformationAndMessageCountInquiryMessageCode == 73  \* "I"
SequenceInformationAndMessageCountResponseMessageCode == 78  \* "N"
FinraOpenMessageCode == 79  \* "O"
OddLotRefreshRequestMessageCode == 82  \* "R"
LineIntegrityMessageCode == 84  \* "T"
EndOfDayMessageCode == 90  \* "Z"
TestMessageCode == 53  \* "5"

ControlMessagePayload ==
    [ tag : {StartOfDayMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {FinraCloseMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {SequenceInformationAndMessageCountInquiryMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {SequenceInformationAndMessageCountResponseMessageCode}, body : SequenceInformationAndMessageCountResponseMessage ]
        \cup [ tag : {FinraOpenMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {OddLotRefreshRequestMessageCode}, body : OddLotRefreshRequestMessage ]
        \cup [ tag : {LineIntegrityMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {EndOfDayMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {TestMessageCode}, body : TestMessage ]

EncodeControlMessagePayload(message) ==
    CASE message.tag = StartOfDayMessageCode -> << >>
      [] message.tag = FinraCloseMessageCode -> << >>
      [] message.tag = SequenceInformationAndMessageCountInquiryMessageCode -> << >>
      [] message.tag = SequenceInformationAndMessageCountResponseMessageCode -> EncodeSequenceInformationAndMessageCountResponseMessage(message.body)
      [] message.tag = FinraOpenMessageCode -> << >>
      [] message.tag = OddLotRefreshRequestMessageCode -> EncodeOddLotRefreshRequestMessage(message.body)
      [] message.tag = LineIntegrityMessageCode -> << >>
      [] message.tag = EndOfDayMessageCode -> << >>
      [] message.tag = TestMessageCode -> EncodeTestMessage(message.body)

DecodeControlMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = StartOfDayMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = FinraCloseMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = SequenceInformationAndMessageCountInquiryMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = SequenceInformationAndMessageCountResponseMessageCode -> DecodeSequenceInformationAndMessageCountResponseMessage(bytes)
              [] tag = FinraOpenMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = OddLotRefreshRequestMessageCode -> DecodeOddLotRefreshRequestMessage(bytes)
              [] tag = LineIntegrityMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = EndOfDayMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = TestMessageCode -> DecodeTestMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroControlMessagePayload == [tag |-> StartOfDayMessageCode, body |-> [empty |-> 0]]

(* Each Control Message Payload in turn, at the values the message it names is checked at *)
CheckedControlMessagePayload ==
    { [tag |-> StartOfDayMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> FinraCloseMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> SequenceInformationAndMessageCountInquiryMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> SequenceInformationAndMessageCountResponseMessageCode, body |-> one] : one \in CheckedSequenceInformationAndMessageCountResponseMessage }
        \cup { [tag |-> FinraOpenMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> OddLotRefreshRequestMessageCode, body |-> one] : one \in CheckedOddLotRefreshRequestMessage }
        \cup { [tag |-> LineIntegrityMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> EndOfDayMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> TestMessageCode, body |-> one] : one \in CheckedTestMessage }

(***************************************************************************)
(* Control Message                                                         *)
(***************************************************************************)

ControlMessage ==
    [ controlMessagePayload : ControlMessagePayload ]

EncodeControlMessage(message) ==
    EncodeUIntBE(message.controlMessagePayload.tag, 1)
        \o EncodeControlMessagePayload(message.controlMessagePayload)

DecodeControlMessage(bytes) ==
    LET controlMessageType == ReadUIntBE(bytes, 1) IN IF ~controlMessageType.ok THEN Fail ELSE
    LET controlMessagePayload == DecodeControlMessagePayload(controlMessageType.value, controlMessageType.rest) IN IF ~controlMessagePayload.ok THEN Fail ELSE
    Ok([ controlMessagePayload |-> controlMessagePayload.value ], controlMessagePayload.rest)

ZeroControlMessage ==
    [ controlMessagePayload |-> ZeroControlMessagePayload ]

(* Control Message at zero, then each field in turn at the values it is checked at *)
CheckedControlMessage ==
    { ZeroControlMessage }
        \cup { [ZeroControlMessage EXCEPT !.controlMessagePayload = one] : one \in CheckedControlMessagePayload }

(***************************************************************************)
(* Auction Status Message: 99 bytes                                        *)
(***************************************************************************)

AuctionStatusMessage ==
    [ securitySymbol                   : Sample(11),
      instrumentType                   : Sample(1),
      auctionCollarReferencePrice      : Sample(8),
      auctionCollarUpperThresholdPrice : Sample(8),
      auctionCollarLowerThresholdPrice : Sample(8),
      numberOfExtensions               : Sample(1),
      reserved62                       : Sample(62) ]

EncodeAuctionStatusMessage(message) ==
    message.securitySymbol
        \o message.instrumentType
        \o message.auctionCollarReferencePrice
        \o message.auctionCollarUpperThresholdPrice
        \o message.auctionCollarLowerThresholdPrice
        \o message.numberOfExtensions
        \o message.reserved62

DecodeAuctionStatusMessage(bytes) ==
    LET securitySymbol == ReadBytes(bytes, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET auctionCollarReferencePrice == ReadBytes(instrumentType.rest, 8) IN IF ~auctionCollarReferencePrice.ok THEN Fail ELSE
    LET auctionCollarUpperThresholdPrice == ReadBytes(auctionCollarReferencePrice.rest, 8) IN IF ~auctionCollarUpperThresholdPrice.ok THEN Fail ELSE
    LET auctionCollarLowerThresholdPrice == ReadBytes(auctionCollarUpperThresholdPrice.rest, 8) IN IF ~auctionCollarLowerThresholdPrice.ok THEN Fail ELSE
    LET numberOfExtensions == ReadBytes(auctionCollarLowerThresholdPrice.rest, 1) IN IF ~numberOfExtensions.ok THEN Fail ELSE
    LET reserved62 == ReadBytes(numberOfExtensions.rest, 62) IN IF ~reserved62.ok THEN Fail ELSE
    Ok([ securitySymbol                   |-> securitySymbol.value,
         instrumentType                   |-> instrumentType.value,
         auctionCollarReferencePrice      |-> auctionCollarReferencePrice.value,
         auctionCollarUpperThresholdPrice |-> auctionCollarUpperThresholdPrice.value,
         auctionCollarLowerThresholdPrice |-> auctionCollarLowerThresholdPrice.value,
         numberOfExtensions               |-> numberOfExtensions.value,
         reserved62                       |-> reserved62.value ], reserved62.rest)

ZeroAuctionStatusMessage ==
    [ securitySymbol                   |-> [i \in 1 .. 11 |-> 0],
      instrumentType                   |-> [i \in 1 .. 1 |-> 0],
      auctionCollarReferencePrice      |-> [i \in 1 .. 8 |-> 0],
      auctionCollarUpperThresholdPrice |-> [i \in 1 .. 8 |-> 0],
      auctionCollarLowerThresholdPrice |-> [i \in 1 .. 8 |-> 0],
      numberOfExtensions               |-> [i \in 1 .. 1 |-> 0],
      reserved62                       |-> [i \in 1 .. 62 |-> 0] ]

(* Auction Status Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionStatusMessage ==
    { ZeroAuctionStatusMessage }
        \cup { [ZeroAuctionStatusMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroAuctionStatusMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionStatusMessage EXCEPT !.auctionCollarReferencePrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionStatusMessage EXCEPT !.auctionCollarUpperThresholdPrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionStatusMessage EXCEPT !.auctionCollarLowerThresholdPrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionStatusMessage EXCEPT !.numberOfExtensions = one] : one \in Sample(1) }
        \cup { [ZeroAuctionStatusMessage EXCEPT !.reserved62 = one] : one \in Sample(62) }

(***************************************************************************)
(* Short Quote Message: 15 bytes                                           *)
(***************************************************************************)

ShortQuoteMessage ==
    [ securitySymbolShort : Sample(5),
      bidPriceShort       : Sample(2),
      bidSizeShort        : Sample(2),
      offerPriceShort     : Sample(2),
      offerSizeShort      : Sample(2),
      reserved2           : Sample(2) ]

EncodeShortQuoteMessage(message) ==
    message.securitySymbolShort
        \o message.bidPriceShort
        \o message.bidSizeShort
        \o message.offerPriceShort
        \o message.offerSizeShort
        \o message.reserved2

DecodeShortQuoteMessage(bytes) ==
    LET securitySymbolShort == ReadBytes(bytes, 5) IN IF ~securitySymbolShort.ok THEN Fail ELSE
    LET bidPriceShort == ReadBytes(securitySymbolShort.rest, 2) IN IF ~bidPriceShort.ok THEN Fail ELSE
    LET bidSizeShort == ReadBytes(bidPriceShort.rest, 2) IN IF ~bidSizeShort.ok THEN Fail ELSE
    LET offerPriceShort == ReadBytes(bidSizeShort.rest, 2) IN IF ~offerPriceShort.ok THEN Fail ELSE
    LET offerSizeShort == ReadBytes(offerPriceShort.rest, 2) IN IF ~offerSizeShort.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(offerSizeShort.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    Ok([ securitySymbolShort |-> securitySymbolShort.value,
         bidPriceShort       |-> bidPriceShort.value,
         bidSizeShort        |-> bidSizeShort.value,
         offerPriceShort     |-> offerPriceShort.value,
         offerSizeShort      |-> offerSizeShort.value,
         reserved2           |-> reserved2.value ], reserved2.rest)

ZeroShortQuoteMessage ==
    [ securitySymbolShort |-> [i \in 1 .. 5 |-> 0],
      bidPriceShort       |-> [i \in 1 .. 2 |-> 0],
      bidSizeShort        |-> [i \in 1 .. 2 |-> 0],
      offerPriceShort     |-> [i \in 1 .. 2 |-> 0],
      offerSizeShort      |-> [i \in 1 .. 2 |-> 0],
      reserved2           |-> [i \in 1 .. 2 |-> 0] ]

(* Short Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedShortQuoteMessage ==
    { ZeroShortQuoteMessage }
        \cup { [ZeroShortQuoteMessage EXCEPT !.securitySymbolShort = one] : one \in Sample(5) }
        \cup { [ZeroShortQuoteMessage EXCEPT !.bidPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroShortQuoteMessage EXCEPT !.bidSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroShortQuoteMessage EXCEPT !.offerPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroShortQuoteMessage EXCEPT !.offerSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroShortQuoteMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Timestamp 2: 8 bytes                                                    *)
(***************************************************************************)

Timestamp2 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp2(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp2(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp2 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 2 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp2 ==
    { ZeroTimestamp2 }
        \cup { [ZeroTimestamp2 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp2 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Long Quote Message: 55 bytes                                            *)
(***************************************************************************)

LongQuoteMessage ==
    [ securitySymbol                : Sample(11),
      instrumentType                : Sample(1),
      quoteCondition                : Sample(1),
      securityStatusIndicator       : Sample(1),
      bidPrice                      : Sample(8),
      bidSize                       : Sample(4),
      offerPrice                    : Sample(8),
      offerSize                     : Sample(4),
      retailInterestIndicator       : Sample(1),
      settlementCondition           : Sample(1),
      marketCondition               : Sample(1),
      finraMarketMakerId            : Sample(4),
      finraBboIndicator             : Sample(1),
      timestamp2                    : Timestamp2,
      shortSaleRestrictionIndicator : Sample(1) ]

EncodeLongQuoteMessage(message) ==
    message.securitySymbol
        \o message.instrumentType
        \o message.quoteCondition
        \o message.securityStatusIndicator
        \o message.bidPrice
        \o message.bidSize
        \o message.offerPrice
        \o message.offerSize
        \o message.retailInterestIndicator
        \o message.settlementCondition
        \o message.marketCondition
        \o message.finraMarketMakerId
        \o message.finraBboIndicator
        \o EncodeTimestamp2(message.timestamp2)
        \o message.shortSaleRestrictionIndicator

DecodeLongQuoteMessage(bytes) ==
    LET securitySymbol == ReadBytes(bytes, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(instrumentType.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET securityStatusIndicator == ReadBytes(quoteCondition.rest, 1) IN IF ~securityStatusIndicator.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(securityStatusIndicator.rest, 8) IN IF ~bidPrice.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPrice.rest, 4) IN IF ~bidSize.ok THEN Fail ELSE
    LET offerPrice == ReadBytes(bidSize.rest, 8) IN IF ~offerPrice.ok THEN Fail ELSE
    LET offerSize == ReadBytes(offerPrice.rest, 4) IN IF ~offerSize.ok THEN Fail ELSE
    LET retailInterestIndicator == ReadBytes(offerSize.rest, 1) IN IF ~retailInterestIndicator.ok THEN Fail ELSE
    LET settlementCondition == ReadBytes(retailInterestIndicator.rest, 1) IN IF ~settlementCondition.ok THEN Fail ELSE
    LET marketCondition == ReadBytes(settlementCondition.rest, 1) IN IF ~marketCondition.ok THEN Fail ELSE
    LET finraMarketMakerId == ReadBytes(marketCondition.rest, 4) IN IF ~finraMarketMakerId.ok THEN Fail ELSE
    LET finraBboIndicator == ReadBytes(finraMarketMakerId.rest, 1) IN IF ~finraBboIndicator.ok THEN Fail ELSE
    LET timestamp2 == DecodeTimestamp2(finraBboIndicator.rest) IN IF ~timestamp2.ok THEN Fail ELSE
    LET shortSaleRestrictionIndicator == ReadBytes(timestamp2.rest, 1) IN IF ~shortSaleRestrictionIndicator.ok THEN Fail ELSE
    Ok([ securitySymbol                |-> securitySymbol.value,
         instrumentType                |-> instrumentType.value,
         quoteCondition                |-> quoteCondition.value,
         securityStatusIndicator       |-> securityStatusIndicator.value,
         bidPrice                      |-> bidPrice.value,
         bidSize                       |-> bidSize.value,
         offerPrice                    |-> offerPrice.value,
         offerSize                     |-> offerSize.value,
         retailInterestIndicator       |-> retailInterestIndicator.value,
         settlementCondition           |-> settlementCondition.value,
         marketCondition               |-> marketCondition.value,
         finraMarketMakerId            |-> finraMarketMakerId.value,
         finraBboIndicator             |-> finraBboIndicator.value,
         timestamp2                    |-> timestamp2.value,
         shortSaleRestrictionIndicator |-> shortSaleRestrictionIndicator.value ], shortSaleRestrictionIndicator.rest)

ZeroLongQuoteMessage ==
    [ securitySymbol                |-> [i \in 1 .. 11 |-> 0],
      instrumentType                |-> [i \in 1 .. 1 |-> 0],
      quoteCondition                |-> [i \in 1 .. 1 |-> 0],
      securityStatusIndicator       |-> [i \in 1 .. 1 |-> 0],
      bidPrice                      |-> [i \in 1 .. 8 |-> 0],
      bidSize                       |-> [i \in 1 .. 4 |-> 0],
      offerPrice                    |-> [i \in 1 .. 8 |-> 0],
      offerSize                     |-> [i \in 1 .. 4 |-> 0],
      retailInterestIndicator       |-> [i \in 1 .. 1 |-> 0],
      settlementCondition           |-> [i \in 1 .. 1 |-> 0],
      marketCondition               |-> [i \in 1 .. 1 |-> 0],
      finraMarketMakerId            |-> [i \in 1 .. 4 |-> 0],
      finraBboIndicator             |-> [i \in 1 .. 1 |-> 0],
      timestamp2                    |-> ZeroTimestamp2,
      shortSaleRestrictionIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Long Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedLongQuoteMessage ==
    { ZeroLongQuoteMessage }
        \cup { [ZeroLongQuoteMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroLongQuoteMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroLongQuoteMessage EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroLongQuoteMessage EXCEPT !.securityStatusIndicator = one] : one \in Sample(1) }
        \cup { [ZeroLongQuoteMessage EXCEPT !.bidPrice = one] : one \in Sample(8) }
        \cup { [ZeroLongQuoteMessage EXCEPT !.bidSize = one] : one \in Sample(4) }
        \cup { [ZeroLongQuoteMessage EXCEPT !.offerPrice = one] : one \in Sample(8) }
        \cup { [ZeroLongQuoteMessage EXCEPT !.offerSize = one] : one \in Sample(4) }
        \cup { [ZeroLongQuoteMessage EXCEPT !.retailInterestIndicator = one] : one \in Sample(1) }
        \cup { [ZeroLongQuoteMessage EXCEPT !.settlementCondition = one] : one \in Sample(1) }
        \cup { [ZeroLongQuoteMessage EXCEPT !.marketCondition = one] : one \in Sample(1) }
        \cup { [ZeroLongQuoteMessage EXCEPT !.finraMarketMakerId = one] : one \in Sample(4) }
        \cup { [ZeroLongQuoteMessage EXCEPT !.finraBboIndicator = one] : one \in Sample(1) }
        \cup { [ZeroLongQuoteMessage EXCEPT !.timestamp2 = one] : one \in CheckedTimestamp2 }
        \cup { [ZeroLongQuoteMessage EXCEPT !.shortSaleRestrictionIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Timestamp 2: 8 bytes                                                    *)
(***************************************************************************)

Timestamp22 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp22(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp22(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp22 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 2 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp22 ==
    { ZeroTimestamp22 }
        \cup { [ZeroTimestamp22 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp22 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Special Long Quote Message: 88 bytes                                    *)
(***************************************************************************)

SpecialLongQuoteMessage ==
    [ securitySymbol                : Sample(11),
      instrumentType                : Sample(1),
      quoteCondition                : Sample(1),
      securityStatusIndicator       : Sample(1),
      bidPrice                      : Sample(8),
      bidSize                       : Sample(4),
      offerPrice                    : Sample(8),
      offerSize                     : Sample(4),
      retailInterestIndicator       : Sample(1),
      settlementCondition           : Sample(1),
      marketCondition               : Sample(1),
      finraMarketMakerId            : Sample(4),
      finraBestBidQuoteCondition    : Sample(1),
      finraBestBidPrice             : Sample(8),
      finraBestBidSize              : Sample(4),
      finraBestBidMarketMakerId     : Sample(4),
      finraBestOfferQuoteCondition  : Sample(1),
      finraBestOfferPrice           : Sample(8),
      finraBestOfferSize            : Sample(4),
      finraBestOfferMarketMakerId   : Sample(4),
      timestamp2                    : Timestamp22,
      shortSaleRestrictionIndicator : Sample(1) ]

EncodeSpecialLongQuoteMessage(message) ==
    message.securitySymbol
        \o message.instrumentType
        \o message.quoteCondition
        \o message.securityStatusIndicator
        \o message.bidPrice
        \o message.bidSize
        \o message.offerPrice
        \o message.offerSize
        \o message.retailInterestIndicator
        \o message.settlementCondition
        \o message.marketCondition
        \o message.finraMarketMakerId
        \o message.finraBestBidQuoteCondition
        \o message.finraBestBidPrice
        \o message.finraBestBidSize
        \o message.finraBestBidMarketMakerId
        \o message.finraBestOfferQuoteCondition
        \o message.finraBestOfferPrice
        \o message.finraBestOfferSize
        \o message.finraBestOfferMarketMakerId
        \o EncodeTimestamp22(message.timestamp2)
        \o message.shortSaleRestrictionIndicator

DecodeSpecialLongQuoteMessage(bytes) ==
    LET securitySymbol == ReadBytes(bytes, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(instrumentType.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET securityStatusIndicator == ReadBytes(quoteCondition.rest, 1) IN IF ~securityStatusIndicator.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(securityStatusIndicator.rest, 8) IN IF ~bidPrice.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPrice.rest, 4) IN IF ~bidSize.ok THEN Fail ELSE
    LET offerPrice == ReadBytes(bidSize.rest, 8) IN IF ~offerPrice.ok THEN Fail ELSE
    LET offerSize == ReadBytes(offerPrice.rest, 4) IN IF ~offerSize.ok THEN Fail ELSE
    LET retailInterestIndicator == ReadBytes(offerSize.rest, 1) IN IF ~retailInterestIndicator.ok THEN Fail ELSE
    LET settlementCondition == ReadBytes(retailInterestIndicator.rest, 1) IN IF ~settlementCondition.ok THEN Fail ELSE
    LET marketCondition == ReadBytes(settlementCondition.rest, 1) IN IF ~marketCondition.ok THEN Fail ELSE
    LET finraMarketMakerId == ReadBytes(marketCondition.rest, 4) IN IF ~finraMarketMakerId.ok THEN Fail ELSE
    LET finraBestBidQuoteCondition == ReadBytes(finraMarketMakerId.rest, 1) IN IF ~finraBestBidQuoteCondition.ok THEN Fail ELSE
    LET finraBestBidPrice == ReadBytes(finraBestBidQuoteCondition.rest, 8) IN IF ~finraBestBidPrice.ok THEN Fail ELSE
    LET finraBestBidSize == ReadBytes(finraBestBidPrice.rest, 4) IN IF ~finraBestBidSize.ok THEN Fail ELSE
    LET finraBestBidMarketMakerId == ReadBytes(finraBestBidSize.rest, 4) IN IF ~finraBestBidMarketMakerId.ok THEN Fail ELSE
    LET finraBestOfferQuoteCondition == ReadBytes(finraBestBidMarketMakerId.rest, 1) IN IF ~finraBestOfferQuoteCondition.ok THEN Fail ELSE
    LET finraBestOfferPrice == ReadBytes(finraBestOfferQuoteCondition.rest, 8) IN IF ~finraBestOfferPrice.ok THEN Fail ELSE
    LET finraBestOfferSize == ReadBytes(finraBestOfferPrice.rest, 4) IN IF ~finraBestOfferSize.ok THEN Fail ELSE
    LET finraBestOfferMarketMakerId == ReadBytes(finraBestOfferSize.rest, 4) IN IF ~finraBestOfferMarketMakerId.ok THEN Fail ELSE
    LET timestamp2 == DecodeTimestamp22(finraBestOfferMarketMakerId.rest) IN IF ~timestamp2.ok THEN Fail ELSE
    LET shortSaleRestrictionIndicator == ReadBytes(timestamp2.rest, 1) IN IF ~shortSaleRestrictionIndicator.ok THEN Fail ELSE
    Ok([ securitySymbol                |-> securitySymbol.value,
         instrumentType                |-> instrumentType.value,
         quoteCondition                |-> quoteCondition.value,
         securityStatusIndicator       |-> securityStatusIndicator.value,
         bidPrice                      |-> bidPrice.value,
         bidSize                       |-> bidSize.value,
         offerPrice                    |-> offerPrice.value,
         offerSize                     |-> offerSize.value,
         retailInterestIndicator       |-> retailInterestIndicator.value,
         settlementCondition           |-> settlementCondition.value,
         marketCondition               |-> marketCondition.value,
         finraMarketMakerId            |-> finraMarketMakerId.value,
         finraBestBidQuoteCondition    |-> finraBestBidQuoteCondition.value,
         finraBestBidPrice             |-> finraBestBidPrice.value,
         finraBestBidSize              |-> finraBestBidSize.value,
         finraBestBidMarketMakerId     |-> finraBestBidMarketMakerId.value,
         finraBestOfferQuoteCondition  |-> finraBestOfferQuoteCondition.value,
         finraBestOfferPrice           |-> finraBestOfferPrice.value,
         finraBestOfferSize            |-> finraBestOfferSize.value,
         finraBestOfferMarketMakerId   |-> finraBestOfferMarketMakerId.value,
         timestamp2                    |-> timestamp2.value,
         shortSaleRestrictionIndicator |-> shortSaleRestrictionIndicator.value ], shortSaleRestrictionIndicator.rest)

ZeroSpecialLongQuoteMessage ==
    [ securitySymbol                |-> [i \in 1 .. 11 |-> 0],
      instrumentType                |-> [i \in 1 .. 1 |-> 0],
      quoteCondition                |-> [i \in 1 .. 1 |-> 0],
      securityStatusIndicator       |-> [i \in 1 .. 1 |-> 0],
      bidPrice                      |-> [i \in 1 .. 8 |-> 0],
      bidSize                       |-> [i \in 1 .. 4 |-> 0],
      offerPrice                    |-> [i \in 1 .. 8 |-> 0],
      offerSize                     |-> [i \in 1 .. 4 |-> 0],
      retailInterestIndicator       |-> [i \in 1 .. 1 |-> 0],
      settlementCondition           |-> [i \in 1 .. 1 |-> 0],
      marketCondition               |-> [i \in 1 .. 1 |-> 0],
      finraMarketMakerId            |-> [i \in 1 .. 4 |-> 0],
      finraBestBidQuoteCondition    |-> [i \in 1 .. 1 |-> 0],
      finraBestBidPrice             |-> [i \in 1 .. 8 |-> 0],
      finraBestBidSize              |-> [i \in 1 .. 4 |-> 0],
      finraBestBidMarketMakerId     |-> [i \in 1 .. 4 |-> 0],
      finraBestOfferQuoteCondition  |-> [i \in 1 .. 1 |-> 0],
      finraBestOfferPrice           |-> [i \in 1 .. 8 |-> 0],
      finraBestOfferSize            |-> [i \in 1 .. 4 |-> 0],
      finraBestOfferMarketMakerId   |-> [i \in 1 .. 4 |-> 0],
      timestamp2                    |-> ZeroTimestamp22,
      shortSaleRestrictionIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Special Long Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedSpecialLongQuoteMessage ==
    { ZeroSpecialLongQuoteMessage }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.securityStatusIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.bidPrice = one] : one \in Sample(8) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.bidSize = one] : one \in Sample(4) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.offerPrice = one] : one \in Sample(8) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.offerSize = one] : one \in Sample(4) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.retailInterestIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.settlementCondition = one] : one \in Sample(1) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.marketCondition = one] : one \in Sample(1) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.finraMarketMakerId = one] : one \in Sample(4) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.finraBestBidQuoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.finraBestBidPrice = one] : one \in Sample(8) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.finraBestBidSize = one] : one \in Sample(4) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.finraBestBidMarketMakerId = one] : one \in Sample(4) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.finraBestOfferQuoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.finraBestOfferPrice = one] : one \in Sample(8) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.finraBestOfferSize = one] : one \in Sample(4) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.finraBestOfferMarketMakerId = one] : one \in Sample(4) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.timestamp2 = one] : one \in CheckedTimestamp22 }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.shortSaleRestrictionIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Odd Lot Bid Short Quote Appendage: 3 bytes                              *)
(***************************************************************************)

OddLotBidShortQuoteAppendage ==
    [ oddLotQuotePrice2 : Sample(2),
      oddLotQuoteSize   : Sample(1) ]

EncodeOddLotBidShortQuoteAppendage(message) ==
    message.oddLotQuotePrice2
        \o message.oddLotQuoteSize

DecodeOddLotBidShortQuoteAppendage(bytes) ==
    LET oddLotQuotePrice2 == ReadBytes(bytes, 2) IN IF ~oddLotQuotePrice2.ok THEN Fail ELSE
    LET oddLotQuoteSize == ReadBytes(oddLotQuotePrice2.rest, 1) IN IF ~oddLotQuoteSize.ok THEN Fail ELSE
    Ok([ oddLotQuotePrice2 |-> oddLotQuotePrice2.value,
         oddLotQuoteSize   |-> oddLotQuoteSize.value ], oddLotQuoteSize.rest)

ZeroOddLotBidShortQuoteAppendage ==
    [ oddLotQuotePrice2 |-> [i \in 1 .. 2 |-> 0],
      oddLotQuoteSize   |-> [i \in 1 .. 1 |-> 0] ]

(* Odd Lot Bid Short Quote Appendage at zero, then each field in turn at the values it is checked at *)
CheckedOddLotBidShortQuoteAppendage ==
    { ZeroOddLotBidShortQuoteAppendage }
        \cup { [ZeroOddLotBidShortQuoteAppendage EXCEPT !.oddLotQuotePrice2 = one] : one \in Sample(2) }
        \cup { [ZeroOddLotBidShortQuoteAppendage EXCEPT !.oddLotQuoteSize = one] : one \in Sample(1) }

(* A run of Odd Lot Bid Short Quote Appendage, written one after another *)
RECURSIVE EncodeOddLotBidShortQuoteAppendageList(_)
EncodeOddLotBidShortQuoteAppendageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOddLotBidShortQuoteAppendage(Head(messages)) \o EncodeOddLotBidShortQuoteAppendageList(Tail(messages))

(* As many Odd Lot Bid Short Quote Appendage as the field that counts them says *)
RECURSIVE ReadOddLotBidShortQuoteAppendageList(_, _)
ReadOddLotBidShortQuoteAppendageList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOddLotBidShortQuoteAppendage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOddLotBidShortQuoteAppendageList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Odd Lot Bid Short Quote Appendage of each kind, for the lists that carry them *)
OneOddLotBidShortQuoteAppendage == { ZeroOddLotBidShortQuoteAppendage }

(***************************************************************************)
(* Odd Lot Offer Short Quote Appendage: 3 bytes                            *)
(***************************************************************************)

OddLotOfferShortQuoteAppendage ==
    [ oddLotQuotePrice2 : Sample(2),
      oddLotQuoteSize   : Sample(1) ]

EncodeOddLotOfferShortQuoteAppendage(message) ==
    message.oddLotQuotePrice2
        \o message.oddLotQuoteSize

DecodeOddLotOfferShortQuoteAppendage(bytes) ==
    LET oddLotQuotePrice2 == ReadBytes(bytes, 2) IN IF ~oddLotQuotePrice2.ok THEN Fail ELSE
    LET oddLotQuoteSize == ReadBytes(oddLotQuotePrice2.rest, 1) IN IF ~oddLotQuoteSize.ok THEN Fail ELSE
    Ok([ oddLotQuotePrice2 |-> oddLotQuotePrice2.value,
         oddLotQuoteSize   |-> oddLotQuoteSize.value ], oddLotQuoteSize.rest)

ZeroOddLotOfferShortQuoteAppendage ==
    [ oddLotQuotePrice2 |-> [i \in 1 .. 2 |-> 0],
      oddLotQuoteSize   |-> [i \in 1 .. 1 |-> 0] ]

(* Odd Lot Offer Short Quote Appendage at zero, then each field in turn at the values it is checked at *)
CheckedOddLotOfferShortQuoteAppendage ==
    { ZeroOddLotOfferShortQuoteAppendage }
        \cup { [ZeroOddLotOfferShortQuoteAppendage EXCEPT !.oddLotQuotePrice2 = one] : one \in Sample(2) }
        \cup { [ZeroOddLotOfferShortQuoteAppendage EXCEPT !.oddLotQuoteSize = one] : one \in Sample(1) }

(* A run of Odd Lot Offer Short Quote Appendage, written one after another *)
RECURSIVE EncodeOddLotOfferShortQuoteAppendageList(_)
EncodeOddLotOfferShortQuoteAppendageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOddLotOfferShortQuoteAppendage(Head(messages)) \o EncodeOddLotOfferShortQuoteAppendageList(Tail(messages))

(* As many Odd Lot Offer Short Quote Appendage as the field that counts them says *)
RECURSIVE ReadOddLotOfferShortQuoteAppendageList(_, _)
ReadOddLotOfferShortQuoteAppendageList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOddLotOfferShortQuoteAppendage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOddLotOfferShortQuoteAppendageList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Odd Lot Offer Short Quote Appendage of each kind, for the lists that carry them *)
OneOddLotOfferShortQuoteAppendage == { ZeroOddLotOfferShortQuoteAppendage }

(***************************************************************************)
(* Round Lot Short Quote Message                                           *)
(***************************************************************************)

RoundLotShortQuoteMessage ==
    [ securitySymbolShort            : Sample(5),
      roundLotBidPriceShort          : Sample(2),
      roundLotBidSizeShort           : Sample(2),
      roundLotOfferPriceShort        : Sample(2),
      roundLotOfferSizeShort         : Sample(2),
      clearPriorOddLotQuotes         : Sample(1),
      oddLotBidShortQuoteAppendage   : SampleLists(OneOddLotBidShortQuoteAppendage),
      oddLotOfferShortQuoteAppendage : SampleLists(OneOddLotOfferShortQuoteAppendage) ]

EncodeRoundLotShortQuoteMessage(message) ==
    message.securitySymbolShort
        \o message.roundLotBidPriceShort
        \o message.roundLotBidSizeShort
        \o message.roundLotOfferPriceShort
        \o message.roundLotOfferSizeShort
        \o message.clearPriorOddLotQuotes
        \o EncodeUIntBE(Len(message.oddLotBidShortQuoteAppendage), 1)
        \o EncodeUIntBE(Len(message.oddLotOfferShortQuoteAppendage), 1)
        \o EncodeOddLotBidShortQuoteAppendageList(message.oddLotBidShortQuoteAppendage)
        \o EncodeOddLotOfferShortQuoteAppendageList(message.oddLotOfferShortQuoteAppendage)

DecodeRoundLotShortQuoteMessage(bytes) ==
    LET securitySymbolShort == ReadBytes(bytes, 5) IN IF ~securitySymbolShort.ok THEN Fail ELSE
    LET roundLotBidPriceShort == ReadBytes(securitySymbolShort.rest, 2) IN IF ~roundLotBidPriceShort.ok THEN Fail ELSE
    LET roundLotBidSizeShort == ReadBytes(roundLotBidPriceShort.rest, 2) IN IF ~roundLotBidSizeShort.ok THEN Fail ELSE
    LET roundLotOfferPriceShort == ReadBytes(roundLotBidSizeShort.rest, 2) IN IF ~roundLotOfferPriceShort.ok THEN Fail ELSE
    LET roundLotOfferSizeShort == ReadBytes(roundLotOfferPriceShort.rest, 2) IN IF ~roundLotOfferSizeShort.ok THEN Fail ELSE
    LET clearPriorOddLotQuotes == ReadBytes(roundLotOfferSizeShort.rest, 1) IN IF ~clearPriorOddLotQuotes.ok THEN Fail ELSE
    LET countOfOddLotBidAppendages == ReadUIntBE(clearPriorOddLotQuotes.rest, 1) IN IF ~countOfOddLotBidAppendages.ok THEN Fail ELSE
    LET countOfOddLotOfferAppendages == ReadUIntBE(countOfOddLotBidAppendages.rest, 1) IN IF ~countOfOddLotOfferAppendages.ok THEN Fail ELSE
    LET oddLotBidShortQuoteAppendage == ReadOddLotBidShortQuoteAppendageList(countOfOddLotOfferAppendages.rest, countOfOddLotBidAppendages.value) IN IF ~oddLotBidShortQuoteAppendage.ok THEN Fail ELSE
    LET oddLotOfferShortQuoteAppendage == ReadOddLotOfferShortQuoteAppendageList(oddLotBidShortQuoteAppendage.rest, countOfOddLotOfferAppendages.value) IN IF ~oddLotOfferShortQuoteAppendage.ok THEN Fail ELSE
    Ok([ securitySymbolShort            |-> securitySymbolShort.value,
         roundLotBidPriceShort          |-> roundLotBidPriceShort.value,
         roundLotBidSizeShort           |-> roundLotBidSizeShort.value,
         roundLotOfferPriceShort        |-> roundLotOfferPriceShort.value,
         roundLotOfferSizeShort         |-> roundLotOfferSizeShort.value,
         clearPriorOddLotQuotes         |-> clearPriorOddLotQuotes.value,
         oddLotBidShortQuoteAppendage   |-> oddLotBidShortQuoteAppendage.value,
         oddLotOfferShortQuoteAppendage |-> oddLotOfferShortQuoteAppendage.value ], oddLotOfferShortQuoteAppendage.rest)

ZeroRoundLotShortQuoteMessage ==
    [ securitySymbolShort            |-> [i \in 1 .. 5 |-> 0],
      roundLotBidPriceShort          |-> [i \in 1 .. 2 |-> 0],
      roundLotBidSizeShort           |-> [i \in 1 .. 2 |-> 0],
      roundLotOfferPriceShort        |-> [i \in 1 .. 2 |-> 0],
      roundLotOfferSizeShort         |-> [i \in 1 .. 2 |-> 0],
      clearPriorOddLotQuotes         |-> [i \in 1 .. 1 |-> 0],
      oddLotBidShortQuoteAppendage   |-> << >>,
      oddLotOfferShortQuoteAppendage |-> << >> ]

(* Round Lot Short Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedRoundLotShortQuoteMessage ==
    { ZeroRoundLotShortQuoteMessage }
        \cup { [ZeroRoundLotShortQuoteMessage EXCEPT !.securitySymbolShort = one] : one \in Sample(5) }
        \cup { [ZeroRoundLotShortQuoteMessage EXCEPT !.roundLotBidPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroRoundLotShortQuoteMessage EXCEPT !.roundLotBidSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroRoundLotShortQuoteMessage EXCEPT !.roundLotOfferPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroRoundLotShortQuoteMessage EXCEPT !.roundLotOfferSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroRoundLotShortQuoteMessage EXCEPT !.clearPriorOddLotQuotes = one] : one \in Sample(1) }
        \cup { [ZeroRoundLotShortQuoteMessage EXCEPT !.oddLotBidShortQuoteAppendage = one] : one \in SampleLists(OneOddLotBidShortQuoteAppendage) }
        \cup { [ZeroRoundLotShortQuoteMessage EXCEPT !.oddLotOfferShortQuoteAppendage = one] : one \in SampleLists(OneOddLotOfferShortQuoteAppendage) }

(***************************************************************************)
(* Timestamp 2: 8 bytes                                                    *)
(***************************************************************************)

Timestamp23 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp23(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp23(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp23 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 2 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp23 ==
    { ZeroTimestamp23 }
        \cup { [ZeroTimestamp23 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp23 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Odd Lot Bid Long Quote Appendage: 9 bytes                               *)
(***************************************************************************)

OddLotBidLongQuoteAppendage ==
    [ oddLotQuotePrice : Sample(8),
      oddLotQuoteSize  : Sample(1) ]

EncodeOddLotBidLongQuoteAppendage(message) ==
    message.oddLotQuotePrice
        \o message.oddLotQuoteSize

DecodeOddLotBidLongQuoteAppendage(bytes) ==
    LET oddLotQuotePrice == ReadBytes(bytes, 8) IN IF ~oddLotQuotePrice.ok THEN Fail ELSE
    LET oddLotQuoteSize == ReadBytes(oddLotQuotePrice.rest, 1) IN IF ~oddLotQuoteSize.ok THEN Fail ELSE
    Ok([ oddLotQuotePrice |-> oddLotQuotePrice.value,
         oddLotQuoteSize  |-> oddLotQuoteSize.value ], oddLotQuoteSize.rest)

ZeroOddLotBidLongQuoteAppendage ==
    [ oddLotQuotePrice |-> [i \in 1 .. 8 |-> 0],
      oddLotQuoteSize  |-> [i \in 1 .. 1 |-> 0] ]

(* Odd Lot Bid Long Quote Appendage at zero, then each field in turn at the values it is checked at *)
CheckedOddLotBidLongQuoteAppendage ==
    { ZeroOddLotBidLongQuoteAppendage }
        \cup { [ZeroOddLotBidLongQuoteAppendage EXCEPT !.oddLotQuotePrice = one] : one \in Sample(8) }
        \cup { [ZeroOddLotBidLongQuoteAppendage EXCEPT !.oddLotQuoteSize = one] : one \in Sample(1) }

(* A run of Odd Lot Bid Long Quote Appendage, written one after another *)
RECURSIVE EncodeOddLotBidLongQuoteAppendageList(_)
EncodeOddLotBidLongQuoteAppendageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOddLotBidLongQuoteAppendage(Head(messages)) \o EncodeOddLotBidLongQuoteAppendageList(Tail(messages))

(* As many Odd Lot Bid Long Quote Appendage as the field that counts them says *)
RECURSIVE ReadOddLotBidLongQuoteAppendageList(_, _)
ReadOddLotBidLongQuoteAppendageList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOddLotBidLongQuoteAppendage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOddLotBidLongQuoteAppendageList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Odd Lot Bid Long Quote Appendage of each kind, for the lists that carry them *)
OneOddLotBidLongQuoteAppendage == { ZeroOddLotBidLongQuoteAppendage }

(***************************************************************************)
(* Odd Lot Offer Long Quote Appendage: 9 bytes                             *)
(***************************************************************************)

OddLotOfferLongQuoteAppendage ==
    [ oddLotQuotePrice : Sample(8),
      oddLotQuoteSize  : Sample(1) ]

EncodeOddLotOfferLongQuoteAppendage(message) ==
    message.oddLotQuotePrice
        \o message.oddLotQuoteSize

DecodeOddLotOfferLongQuoteAppendage(bytes) ==
    LET oddLotQuotePrice == ReadBytes(bytes, 8) IN IF ~oddLotQuotePrice.ok THEN Fail ELSE
    LET oddLotQuoteSize == ReadBytes(oddLotQuotePrice.rest, 1) IN IF ~oddLotQuoteSize.ok THEN Fail ELSE
    Ok([ oddLotQuotePrice |-> oddLotQuotePrice.value,
         oddLotQuoteSize  |-> oddLotQuoteSize.value ], oddLotQuoteSize.rest)

ZeroOddLotOfferLongQuoteAppendage ==
    [ oddLotQuotePrice |-> [i \in 1 .. 8 |-> 0],
      oddLotQuoteSize  |-> [i \in 1 .. 1 |-> 0] ]

(* Odd Lot Offer Long Quote Appendage at zero, then each field in turn at the values it is checked at *)
CheckedOddLotOfferLongQuoteAppendage ==
    { ZeroOddLotOfferLongQuoteAppendage }
        \cup { [ZeroOddLotOfferLongQuoteAppendage EXCEPT !.oddLotQuotePrice = one] : one \in Sample(8) }
        \cup { [ZeroOddLotOfferLongQuoteAppendage EXCEPT !.oddLotQuoteSize = one] : one \in Sample(1) }

(* A run of Odd Lot Offer Long Quote Appendage, written one after another *)
RECURSIVE EncodeOddLotOfferLongQuoteAppendageList(_)
EncodeOddLotOfferLongQuoteAppendageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOddLotOfferLongQuoteAppendage(Head(messages)) \o EncodeOddLotOfferLongQuoteAppendageList(Tail(messages))

(* As many Odd Lot Offer Long Quote Appendage as the field that counts them says *)
RECURSIVE ReadOddLotOfferLongQuoteAppendageList(_, _)
ReadOddLotOfferLongQuoteAppendageList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOddLotOfferLongQuoteAppendage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOddLotOfferLongQuoteAppendageList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Odd Lot Offer Long Quote Appendage of each kind, for the lists that carry them *)
OneOddLotOfferLongQuoteAppendage == { ZeroOddLotOfferLongQuoteAppendage }

(***************************************************************************)
(* Round Lot Long Quote Message                                            *)
(***************************************************************************)

RoundLotLongQuoteMessage ==
    [ securitySymbol                : Sample(11),
      quoteCondition                : Sample(1),
      roundLotBidPrice              : Sample(8),
      roundLotBidSize               : Sample(4),
      roundLotOfferPrice            : Sample(8),
      roundLotOfferSize             : Sample(4),
      retailInterestIndicator       : Sample(1),
      settlementCondition           : Sample(1),
      marketCondition               : Sample(1),
      finraMarketMakerId            : Sample(4),
      finraBboIndicator             : Sample(1),
      timestamp2                    : Timestamp23,
      clearPriorOddLotQuotes        : Sample(1),
      oddLotBidLongQuoteAppendage   : SampleLists(OneOddLotBidLongQuoteAppendage),
      oddLotOfferLongQuoteAppendage : SampleLists(OneOddLotOfferLongQuoteAppendage) ]

EncodeRoundLotLongQuoteMessage(message) ==
    message.securitySymbol
        \o message.quoteCondition
        \o message.roundLotBidPrice
        \o message.roundLotBidSize
        \o message.roundLotOfferPrice
        \o message.roundLotOfferSize
        \o message.retailInterestIndicator
        \o message.settlementCondition
        \o message.marketCondition
        \o message.finraMarketMakerId
        \o message.finraBboIndicator
        \o EncodeTimestamp23(message.timestamp2)
        \o message.clearPriorOddLotQuotes
        \o EncodeUIntBE(Len(message.oddLotBidLongQuoteAppendage), 1)
        \o EncodeUIntBE(Len(message.oddLotOfferLongQuoteAppendage), 1)
        \o EncodeOddLotBidLongQuoteAppendageList(message.oddLotBidLongQuoteAppendage)
        \o EncodeOddLotOfferLongQuoteAppendageList(message.oddLotOfferLongQuoteAppendage)

DecodeRoundLotLongQuoteMessage(bytes) ==
    LET securitySymbol == ReadBytes(bytes, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(securitySymbol.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET roundLotBidPrice == ReadBytes(quoteCondition.rest, 8) IN IF ~roundLotBidPrice.ok THEN Fail ELSE
    LET roundLotBidSize == ReadBytes(roundLotBidPrice.rest, 4) IN IF ~roundLotBidSize.ok THEN Fail ELSE
    LET roundLotOfferPrice == ReadBytes(roundLotBidSize.rest, 8) IN IF ~roundLotOfferPrice.ok THEN Fail ELSE
    LET roundLotOfferSize == ReadBytes(roundLotOfferPrice.rest, 4) IN IF ~roundLotOfferSize.ok THEN Fail ELSE
    LET retailInterestIndicator == ReadBytes(roundLotOfferSize.rest, 1) IN IF ~retailInterestIndicator.ok THEN Fail ELSE
    LET settlementCondition == ReadBytes(retailInterestIndicator.rest, 1) IN IF ~settlementCondition.ok THEN Fail ELSE
    LET marketCondition == ReadBytes(settlementCondition.rest, 1) IN IF ~marketCondition.ok THEN Fail ELSE
    LET finraMarketMakerId == ReadBytes(marketCondition.rest, 4) IN IF ~finraMarketMakerId.ok THEN Fail ELSE
    LET finraBboIndicator == ReadBytes(finraMarketMakerId.rest, 1) IN IF ~finraBboIndicator.ok THEN Fail ELSE
    LET timestamp2 == DecodeTimestamp23(finraBboIndicator.rest) IN IF ~timestamp2.ok THEN Fail ELSE
    LET clearPriorOddLotQuotes == ReadBytes(timestamp2.rest, 1) IN IF ~clearPriorOddLotQuotes.ok THEN Fail ELSE
    LET countOfOddLotBidAppendages == ReadUIntBE(clearPriorOddLotQuotes.rest, 1) IN IF ~countOfOddLotBidAppendages.ok THEN Fail ELSE
    LET countOfOddLotOfferAppendages == ReadUIntBE(countOfOddLotBidAppendages.rest, 1) IN IF ~countOfOddLotOfferAppendages.ok THEN Fail ELSE
    LET oddLotBidLongQuoteAppendage == ReadOddLotBidLongQuoteAppendageList(countOfOddLotOfferAppendages.rest, countOfOddLotBidAppendages.value) IN IF ~oddLotBidLongQuoteAppendage.ok THEN Fail ELSE
    LET oddLotOfferLongQuoteAppendage == ReadOddLotOfferLongQuoteAppendageList(oddLotBidLongQuoteAppendage.rest, countOfOddLotOfferAppendages.value) IN IF ~oddLotOfferLongQuoteAppendage.ok THEN Fail ELSE
    Ok([ securitySymbol                |-> securitySymbol.value,
         quoteCondition                |-> quoteCondition.value,
         roundLotBidPrice              |-> roundLotBidPrice.value,
         roundLotBidSize               |-> roundLotBidSize.value,
         roundLotOfferPrice            |-> roundLotOfferPrice.value,
         roundLotOfferSize             |-> roundLotOfferSize.value,
         retailInterestIndicator       |-> retailInterestIndicator.value,
         settlementCondition           |-> settlementCondition.value,
         marketCondition               |-> marketCondition.value,
         finraMarketMakerId            |-> finraMarketMakerId.value,
         finraBboIndicator             |-> finraBboIndicator.value,
         timestamp2                    |-> timestamp2.value,
         clearPriorOddLotQuotes        |-> clearPriorOddLotQuotes.value,
         oddLotBidLongQuoteAppendage   |-> oddLotBidLongQuoteAppendage.value,
         oddLotOfferLongQuoteAppendage |-> oddLotOfferLongQuoteAppendage.value ], oddLotOfferLongQuoteAppendage.rest)

ZeroRoundLotLongQuoteMessage ==
    [ securitySymbol                |-> [i \in 1 .. 11 |-> 0],
      quoteCondition                |-> [i \in 1 .. 1 |-> 0],
      roundLotBidPrice              |-> [i \in 1 .. 8 |-> 0],
      roundLotBidSize               |-> [i \in 1 .. 4 |-> 0],
      roundLotOfferPrice            |-> [i \in 1 .. 8 |-> 0],
      roundLotOfferSize             |-> [i \in 1 .. 4 |-> 0],
      retailInterestIndicator       |-> [i \in 1 .. 1 |-> 0],
      settlementCondition           |-> [i \in 1 .. 1 |-> 0],
      marketCondition               |-> [i \in 1 .. 1 |-> 0],
      finraMarketMakerId            |-> [i \in 1 .. 4 |-> 0],
      finraBboIndicator             |-> [i \in 1 .. 1 |-> 0],
      timestamp2                    |-> ZeroTimestamp23,
      clearPriorOddLotQuotes        |-> [i \in 1 .. 1 |-> 0],
      oddLotBidLongQuoteAppendage   |-> << >>,
      oddLotOfferLongQuoteAppendage |-> << >> ]

(* Round Lot Long Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedRoundLotLongQuoteMessage ==
    { ZeroRoundLotLongQuoteMessage }
        \cup { [ZeroRoundLotLongQuoteMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroRoundLotLongQuoteMessage EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroRoundLotLongQuoteMessage EXCEPT !.roundLotBidPrice = one] : one \in Sample(8) }
        \cup { [ZeroRoundLotLongQuoteMessage EXCEPT !.roundLotBidSize = one] : one \in Sample(4) }
        \cup { [ZeroRoundLotLongQuoteMessage EXCEPT !.roundLotOfferPrice = one] : one \in Sample(8) }
        \cup { [ZeroRoundLotLongQuoteMessage EXCEPT !.roundLotOfferSize = one] : one \in Sample(4) }
        \cup { [ZeroRoundLotLongQuoteMessage EXCEPT !.retailInterestIndicator = one] : one \in Sample(1) }
        \cup { [ZeroRoundLotLongQuoteMessage EXCEPT !.settlementCondition = one] : one \in Sample(1) }
        \cup { [ZeroRoundLotLongQuoteMessage EXCEPT !.marketCondition = one] : one \in Sample(1) }
        \cup { [ZeroRoundLotLongQuoteMessage EXCEPT !.finraMarketMakerId = one] : one \in Sample(4) }
        \cup { [ZeroRoundLotLongQuoteMessage EXCEPT !.finraBboIndicator = one] : one \in Sample(1) }
        \cup { [ZeroRoundLotLongQuoteMessage EXCEPT !.timestamp2 = one] : one \in CheckedTimestamp23 }
        \cup { [ZeroRoundLotLongQuoteMessage EXCEPT !.clearPriorOddLotQuotes = one] : one \in Sample(1) }
        \cup { [ZeroRoundLotLongQuoteMessage EXCEPT !.oddLotBidLongQuoteAppendage = one] : one \in SampleLists(OneOddLotBidLongQuoteAppendage) }
        \cup { [ZeroRoundLotLongQuoteMessage EXCEPT !.oddLotOfferLongQuoteAppendage = one] : one \in SampleLists(OneOddLotOfferLongQuoteAppendage) }

(***************************************************************************)
(* Timestamp 2: 8 bytes                                                    *)
(***************************************************************************)

Timestamp24 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp24(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp24(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp24 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 2 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp24 ==
    { ZeroTimestamp24 }
        \cup { [ZeroTimestamp24 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp24 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Odd Lot Bid Extended Quote Appendage: 13 bytes                          *)
(***************************************************************************)

OddLotBidExtendedQuoteAppendage ==
    [ oddLotQuotePrice         : Sample(8),
      oddLotQuoteSize          : Sample(1),
      oddLotFinraMarketMakerId : Sample(4) ]

EncodeOddLotBidExtendedQuoteAppendage(message) ==
    message.oddLotQuotePrice
        \o message.oddLotQuoteSize
        \o message.oddLotFinraMarketMakerId

DecodeOddLotBidExtendedQuoteAppendage(bytes) ==
    LET oddLotQuotePrice == ReadBytes(bytes, 8) IN IF ~oddLotQuotePrice.ok THEN Fail ELSE
    LET oddLotQuoteSize == ReadBytes(oddLotQuotePrice.rest, 1) IN IF ~oddLotQuoteSize.ok THEN Fail ELSE
    LET oddLotFinraMarketMakerId == ReadBytes(oddLotQuoteSize.rest, 4) IN IF ~oddLotFinraMarketMakerId.ok THEN Fail ELSE
    Ok([ oddLotQuotePrice         |-> oddLotQuotePrice.value,
         oddLotQuoteSize          |-> oddLotQuoteSize.value,
         oddLotFinraMarketMakerId |-> oddLotFinraMarketMakerId.value ], oddLotFinraMarketMakerId.rest)

ZeroOddLotBidExtendedQuoteAppendage ==
    [ oddLotQuotePrice         |-> [i \in 1 .. 8 |-> 0],
      oddLotQuoteSize          |-> [i \in 1 .. 1 |-> 0],
      oddLotFinraMarketMakerId |-> [i \in 1 .. 4 |-> 0] ]

(* Odd Lot Bid Extended Quote Appendage at zero, then each field in turn at the values it is checked at *)
CheckedOddLotBidExtendedQuoteAppendage ==
    { ZeroOddLotBidExtendedQuoteAppendage }
        \cup { [ZeroOddLotBidExtendedQuoteAppendage EXCEPT !.oddLotQuotePrice = one] : one \in Sample(8) }
        \cup { [ZeroOddLotBidExtendedQuoteAppendage EXCEPT !.oddLotQuoteSize = one] : one \in Sample(1) }
        \cup { [ZeroOddLotBidExtendedQuoteAppendage EXCEPT !.oddLotFinraMarketMakerId = one] : one \in Sample(4) }

(* A run of Odd Lot Bid Extended Quote Appendage, written one after another *)
RECURSIVE EncodeOddLotBidExtendedQuoteAppendageList(_)
EncodeOddLotBidExtendedQuoteAppendageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOddLotBidExtendedQuoteAppendage(Head(messages)) \o EncodeOddLotBidExtendedQuoteAppendageList(Tail(messages))

(* As many Odd Lot Bid Extended Quote Appendage as the field that counts them says *)
RECURSIVE ReadOddLotBidExtendedQuoteAppendageList(_, _)
ReadOddLotBidExtendedQuoteAppendageList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOddLotBidExtendedQuoteAppendage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOddLotBidExtendedQuoteAppendageList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Odd Lot Bid Extended Quote Appendage of each kind, for the lists that carry them *)
OneOddLotBidExtendedQuoteAppendage == { ZeroOddLotBidExtendedQuoteAppendage }

(***************************************************************************)
(* Odd Lot Offer Extended Quote Appendage: 13 bytes                        *)
(***************************************************************************)

OddLotOfferExtendedQuoteAppendage ==
    [ oddLotQuotePrice         : Sample(8),
      oddLotQuoteSize          : Sample(1),
      oddLotFinraMarketMakerId : Sample(4) ]

EncodeOddLotOfferExtendedQuoteAppendage(message) ==
    message.oddLotQuotePrice
        \o message.oddLotQuoteSize
        \o message.oddLotFinraMarketMakerId

DecodeOddLotOfferExtendedQuoteAppendage(bytes) ==
    LET oddLotQuotePrice == ReadBytes(bytes, 8) IN IF ~oddLotQuotePrice.ok THEN Fail ELSE
    LET oddLotQuoteSize == ReadBytes(oddLotQuotePrice.rest, 1) IN IF ~oddLotQuoteSize.ok THEN Fail ELSE
    LET oddLotFinraMarketMakerId == ReadBytes(oddLotQuoteSize.rest, 4) IN IF ~oddLotFinraMarketMakerId.ok THEN Fail ELSE
    Ok([ oddLotQuotePrice         |-> oddLotQuotePrice.value,
         oddLotQuoteSize          |-> oddLotQuoteSize.value,
         oddLotFinraMarketMakerId |-> oddLotFinraMarketMakerId.value ], oddLotFinraMarketMakerId.rest)

ZeroOddLotOfferExtendedQuoteAppendage ==
    [ oddLotQuotePrice         |-> [i \in 1 .. 8 |-> 0],
      oddLotQuoteSize          |-> [i \in 1 .. 1 |-> 0],
      oddLotFinraMarketMakerId |-> [i \in 1 .. 4 |-> 0] ]

(* Odd Lot Offer Extended Quote Appendage at zero, then each field in turn at the values it is checked at *)
CheckedOddLotOfferExtendedQuoteAppendage ==
    { ZeroOddLotOfferExtendedQuoteAppendage }
        \cup { [ZeroOddLotOfferExtendedQuoteAppendage EXCEPT !.oddLotQuotePrice = one] : one \in Sample(8) }
        \cup { [ZeroOddLotOfferExtendedQuoteAppendage EXCEPT !.oddLotQuoteSize = one] : one \in Sample(1) }
        \cup { [ZeroOddLotOfferExtendedQuoteAppendage EXCEPT !.oddLotFinraMarketMakerId = one] : one \in Sample(4) }

(* A run of Odd Lot Offer Extended Quote Appendage, written one after another *)
RECURSIVE EncodeOddLotOfferExtendedQuoteAppendageList(_)
EncodeOddLotOfferExtendedQuoteAppendageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOddLotOfferExtendedQuoteAppendage(Head(messages)) \o EncodeOddLotOfferExtendedQuoteAppendageList(Tail(messages))

(* As many Odd Lot Offer Extended Quote Appendage as the field that counts them says *)
RECURSIVE ReadOddLotOfferExtendedQuoteAppendageList(_, _)
ReadOddLotOfferExtendedQuoteAppendageList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOddLotOfferExtendedQuoteAppendage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOddLotOfferExtendedQuoteAppendageList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Odd Lot Offer Extended Quote Appendage of each kind, for the lists that carry them *)
OneOddLotOfferExtendedQuoteAppendage == { ZeroOddLotOfferExtendedQuoteAppendage }

(***************************************************************************)
(* Round Lot Finra Adf Quote Message                                       *)
(***************************************************************************)

RoundLotFinraAdfQuoteMessage ==
    [ securitySymbol                    : Sample(11),
      quoteCondition                    : Sample(1),
      roundLotBidPrice                  : Sample(8),
      roundLotBidSize                   : Sample(4),
      roundLotOfferPrice                : Sample(8),
      roundLotOfferSize                 : Sample(4),
      retailInterestIndicator           : Sample(1),
      settlementCondition               : Sample(1),
      marketCondition                   : Sample(1),
      finraMarketMakerId                : Sample(4),
      finraBestBidQuoteCondition        : Sample(1),
      finraBestBidPrice                 : Sample(8),
      finraBestBidSize                  : Sample(4),
      finraBestBidMarketMakerId         : Sample(4),
      finraBestOfferQuoteCondition      : Sample(1),
      finraBestOfferPrice               : Sample(8),
      finraBestOfferSize                : Sample(4),
      finraBestOfferMarketMakerId       : Sample(4),
      timestamp2                        : Timestamp24,
      clearPriorOddLotQuotes            : Sample(1),
      oddLotBidExtendedQuoteAppendage   : SampleLists(OneOddLotBidExtendedQuoteAppendage),
      oddLotOfferExtendedQuoteAppendage : SampleLists(OneOddLotOfferExtendedQuoteAppendage) ]

EncodeRoundLotFinraAdfQuoteMessage(message) ==
    message.securitySymbol
        \o message.quoteCondition
        \o message.roundLotBidPrice
        \o message.roundLotBidSize
        \o message.roundLotOfferPrice
        \o message.roundLotOfferSize
        \o message.retailInterestIndicator
        \o message.settlementCondition
        \o message.marketCondition
        \o message.finraMarketMakerId
        \o message.finraBestBidQuoteCondition
        \o message.finraBestBidPrice
        \o message.finraBestBidSize
        \o message.finraBestBidMarketMakerId
        \o message.finraBestOfferQuoteCondition
        \o message.finraBestOfferPrice
        \o message.finraBestOfferSize
        \o message.finraBestOfferMarketMakerId
        \o EncodeTimestamp24(message.timestamp2)
        \o message.clearPriorOddLotQuotes
        \o EncodeUIntBE(Len(message.oddLotBidExtendedQuoteAppendage), 1)
        \o EncodeUIntBE(Len(message.oddLotOfferExtendedQuoteAppendage), 1)
        \o EncodeOddLotBidExtendedQuoteAppendageList(message.oddLotBidExtendedQuoteAppendage)
        \o EncodeOddLotOfferExtendedQuoteAppendageList(message.oddLotOfferExtendedQuoteAppendage)

DecodeRoundLotFinraAdfQuoteMessage(bytes) ==
    LET securitySymbol == ReadBytes(bytes, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(securitySymbol.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET roundLotBidPrice == ReadBytes(quoteCondition.rest, 8) IN IF ~roundLotBidPrice.ok THEN Fail ELSE
    LET roundLotBidSize == ReadBytes(roundLotBidPrice.rest, 4) IN IF ~roundLotBidSize.ok THEN Fail ELSE
    LET roundLotOfferPrice == ReadBytes(roundLotBidSize.rest, 8) IN IF ~roundLotOfferPrice.ok THEN Fail ELSE
    LET roundLotOfferSize == ReadBytes(roundLotOfferPrice.rest, 4) IN IF ~roundLotOfferSize.ok THEN Fail ELSE
    LET retailInterestIndicator == ReadBytes(roundLotOfferSize.rest, 1) IN IF ~retailInterestIndicator.ok THEN Fail ELSE
    LET settlementCondition == ReadBytes(retailInterestIndicator.rest, 1) IN IF ~settlementCondition.ok THEN Fail ELSE
    LET marketCondition == ReadBytes(settlementCondition.rest, 1) IN IF ~marketCondition.ok THEN Fail ELSE
    LET finraMarketMakerId == ReadBytes(marketCondition.rest, 4) IN IF ~finraMarketMakerId.ok THEN Fail ELSE
    LET finraBestBidQuoteCondition == ReadBytes(finraMarketMakerId.rest, 1) IN IF ~finraBestBidQuoteCondition.ok THEN Fail ELSE
    LET finraBestBidPrice == ReadBytes(finraBestBidQuoteCondition.rest, 8) IN IF ~finraBestBidPrice.ok THEN Fail ELSE
    LET finraBestBidSize == ReadBytes(finraBestBidPrice.rest, 4) IN IF ~finraBestBidSize.ok THEN Fail ELSE
    LET finraBestBidMarketMakerId == ReadBytes(finraBestBidSize.rest, 4) IN IF ~finraBestBidMarketMakerId.ok THEN Fail ELSE
    LET finraBestOfferQuoteCondition == ReadBytes(finraBestBidMarketMakerId.rest, 1) IN IF ~finraBestOfferQuoteCondition.ok THEN Fail ELSE
    LET finraBestOfferPrice == ReadBytes(finraBestOfferQuoteCondition.rest, 8) IN IF ~finraBestOfferPrice.ok THEN Fail ELSE
    LET finraBestOfferSize == ReadBytes(finraBestOfferPrice.rest, 4) IN IF ~finraBestOfferSize.ok THEN Fail ELSE
    LET finraBestOfferMarketMakerId == ReadBytes(finraBestOfferSize.rest, 4) IN IF ~finraBestOfferMarketMakerId.ok THEN Fail ELSE
    LET timestamp2 == DecodeTimestamp24(finraBestOfferMarketMakerId.rest) IN IF ~timestamp2.ok THEN Fail ELSE
    LET clearPriorOddLotQuotes == ReadBytes(timestamp2.rest, 1) IN IF ~clearPriorOddLotQuotes.ok THEN Fail ELSE
    LET countOfOddLotBidAppendages == ReadUIntBE(clearPriorOddLotQuotes.rest, 1) IN IF ~countOfOddLotBidAppendages.ok THEN Fail ELSE
    LET countOfOddLotOfferAppendages == ReadUIntBE(countOfOddLotBidAppendages.rest, 1) IN IF ~countOfOddLotOfferAppendages.ok THEN Fail ELSE
    LET oddLotBidExtendedQuoteAppendage == ReadOddLotBidExtendedQuoteAppendageList(countOfOddLotOfferAppendages.rest, countOfOddLotBidAppendages.value) IN IF ~oddLotBidExtendedQuoteAppendage.ok THEN Fail ELSE
    LET oddLotOfferExtendedQuoteAppendage == ReadOddLotOfferExtendedQuoteAppendageList(oddLotBidExtendedQuoteAppendage.rest, countOfOddLotOfferAppendages.value) IN IF ~oddLotOfferExtendedQuoteAppendage.ok THEN Fail ELSE
    Ok([ securitySymbol                    |-> securitySymbol.value,
         quoteCondition                    |-> quoteCondition.value,
         roundLotBidPrice                  |-> roundLotBidPrice.value,
         roundLotBidSize                   |-> roundLotBidSize.value,
         roundLotOfferPrice                |-> roundLotOfferPrice.value,
         roundLotOfferSize                 |-> roundLotOfferSize.value,
         retailInterestIndicator           |-> retailInterestIndicator.value,
         settlementCondition               |-> settlementCondition.value,
         marketCondition                   |-> marketCondition.value,
         finraMarketMakerId                |-> finraMarketMakerId.value,
         finraBestBidQuoteCondition        |-> finraBestBidQuoteCondition.value,
         finraBestBidPrice                 |-> finraBestBidPrice.value,
         finraBestBidSize                  |-> finraBestBidSize.value,
         finraBestBidMarketMakerId         |-> finraBestBidMarketMakerId.value,
         finraBestOfferQuoteCondition      |-> finraBestOfferQuoteCondition.value,
         finraBestOfferPrice               |-> finraBestOfferPrice.value,
         finraBestOfferSize                |-> finraBestOfferSize.value,
         finraBestOfferMarketMakerId       |-> finraBestOfferMarketMakerId.value,
         timestamp2                        |-> timestamp2.value,
         clearPriorOddLotQuotes            |-> clearPriorOddLotQuotes.value,
         oddLotBidExtendedQuoteAppendage   |-> oddLotBidExtendedQuoteAppendage.value,
         oddLotOfferExtendedQuoteAppendage |-> oddLotOfferExtendedQuoteAppendage.value ], oddLotOfferExtendedQuoteAppendage.rest)

ZeroRoundLotFinraAdfQuoteMessage ==
    [ securitySymbol                    |-> [i \in 1 .. 11 |-> 0],
      quoteCondition                    |-> [i \in 1 .. 1 |-> 0],
      roundLotBidPrice                  |-> [i \in 1 .. 8 |-> 0],
      roundLotBidSize                   |-> [i \in 1 .. 4 |-> 0],
      roundLotOfferPrice                |-> [i \in 1 .. 8 |-> 0],
      roundLotOfferSize                 |-> [i \in 1 .. 4 |-> 0],
      retailInterestIndicator           |-> [i \in 1 .. 1 |-> 0],
      settlementCondition               |-> [i \in 1 .. 1 |-> 0],
      marketCondition                   |-> [i \in 1 .. 1 |-> 0],
      finraMarketMakerId                |-> [i \in 1 .. 4 |-> 0],
      finraBestBidQuoteCondition        |-> [i \in 1 .. 1 |-> 0],
      finraBestBidPrice                 |-> [i \in 1 .. 8 |-> 0],
      finraBestBidSize                  |-> [i \in 1 .. 4 |-> 0],
      finraBestBidMarketMakerId         |-> [i \in 1 .. 4 |-> 0],
      finraBestOfferQuoteCondition      |-> [i \in 1 .. 1 |-> 0],
      finraBestOfferPrice               |-> [i \in 1 .. 8 |-> 0],
      finraBestOfferSize                |-> [i \in 1 .. 4 |-> 0],
      finraBestOfferMarketMakerId       |-> [i \in 1 .. 4 |-> 0],
      timestamp2                        |-> ZeroTimestamp24,
      clearPriorOddLotQuotes            |-> [i \in 1 .. 1 |-> 0],
      oddLotBidExtendedQuoteAppendage   |-> << >>,
      oddLotOfferExtendedQuoteAppendage |-> << >> ]

(* Round Lot Finra Adf Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedRoundLotFinraAdfQuoteMessage ==
    { ZeroRoundLotFinraAdfQuoteMessage }
        \cup { [ZeroRoundLotFinraAdfQuoteMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroRoundLotFinraAdfQuoteMessage EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroRoundLotFinraAdfQuoteMessage EXCEPT !.roundLotBidPrice = one] : one \in Sample(8) }
        \cup { [ZeroRoundLotFinraAdfQuoteMessage EXCEPT !.roundLotBidSize = one] : one \in Sample(4) }
        \cup { [ZeroRoundLotFinraAdfQuoteMessage EXCEPT !.roundLotOfferPrice = one] : one \in Sample(8) }
        \cup { [ZeroRoundLotFinraAdfQuoteMessage EXCEPT !.roundLotOfferSize = one] : one \in Sample(4) }
        \cup { [ZeroRoundLotFinraAdfQuoteMessage EXCEPT !.retailInterestIndicator = one] : one \in Sample(1) }
        \cup { [ZeroRoundLotFinraAdfQuoteMessage EXCEPT !.settlementCondition = one] : one \in Sample(1) }
        \cup { [ZeroRoundLotFinraAdfQuoteMessage EXCEPT !.marketCondition = one] : one \in Sample(1) }
        \cup { [ZeroRoundLotFinraAdfQuoteMessage EXCEPT !.finraMarketMakerId = one] : one \in Sample(4) }
        \cup { [ZeroRoundLotFinraAdfQuoteMessage EXCEPT !.finraBestBidQuoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroRoundLotFinraAdfQuoteMessage EXCEPT !.finraBestBidPrice = one] : one \in Sample(8) }
        \cup { [ZeroRoundLotFinraAdfQuoteMessage EXCEPT !.finraBestBidSize = one] : one \in Sample(4) }
        \cup { [ZeroRoundLotFinraAdfQuoteMessage EXCEPT !.finraBestBidMarketMakerId = one] : one \in Sample(4) }
        \cup { [ZeroRoundLotFinraAdfQuoteMessage EXCEPT !.finraBestOfferQuoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroRoundLotFinraAdfQuoteMessage EXCEPT !.finraBestOfferPrice = one] : one \in Sample(8) }
        \cup { [ZeroRoundLotFinraAdfQuoteMessage EXCEPT !.finraBestOfferSize = one] : one \in Sample(4) }
        \cup { [ZeroRoundLotFinraAdfQuoteMessage EXCEPT !.finraBestOfferMarketMakerId = one] : one \in Sample(4) }
        \cup { [ZeroRoundLotFinraAdfQuoteMessage EXCEPT !.timestamp2 = one] : one \in CheckedTimestamp24 }
        \cup { [ZeroRoundLotFinraAdfQuoteMessage EXCEPT !.clearPriorOddLotQuotes = one] : one \in Sample(1) }
        \cup { [ZeroRoundLotFinraAdfQuoteMessage EXCEPT !.oddLotBidExtendedQuoteAppendage = one] : one \in SampleLists(OneOddLotBidExtendedQuoteAppendage) }
        \cup { [ZeroRoundLotFinraAdfQuoteMessage EXCEPT !.oddLotOfferExtendedQuoteAppendage = one] : one \in SampleLists(OneOddLotOfferExtendedQuoteAppendage) }

(***************************************************************************)
(* Odd Lot Bid Short Quote Appendage: 3 bytes                              *)
(***************************************************************************)

OddLotBidShortQuoteAppendage2 ==
    [ oddLotQuotePrice2 : Sample(2),
      oddLotQuoteSize   : Sample(1) ]

EncodeOddLotBidShortQuoteAppendage2(message) ==
    message.oddLotQuotePrice2
        \o message.oddLotQuoteSize

DecodeOddLotBidShortQuoteAppendage2(bytes) ==
    LET oddLotQuotePrice2 == ReadBytes(bytes, 2) IN IF ~oddLotQuotePrice2.ok THEN Fail ELSE
    LET oddLotQuoteSize == ReadBytes(oddLotQuotePrice2.rest, 1) IN IF ~oddLotQuoteSize.ok THEN Fail ELSE
    Ok([ oddLotQuotePrice2 |-> oddLotQuotePrice2.value,
         oddLotQuoteSize   |-> oddLotQuoteSize.value ], oddLotQuoteSize.rest)

ZeroOddLotBidShortQuoteAppendage2 ==
    [ oddLotQuotePrice2 |-> [i \in 1 .. 2 |-> 0],
      oddLotQuoteSize   |-> [i \in 1 .. 1 |-> 0] ]

(* Odd Lot Bid Short Quote Appendage at zero, then each field in turn at the values it is checked at *)
CheckedOddLotBidShortQuoteAppendage2 ==
    { ZeroOddLotBidShortQuoteAppendage2 }
        \cup { [ZeroOddLotBidShortQuoteAppendage2 EXCEPT !.oddLotQuotePrice2 = one] : one \in Sample(2) }
        \cup { [ZeroOddLotBidShortQuoteAppendage2 EXCEPT !.oddLotQuoteSize = one] : one \in Sample(1) }

(* A run of Odd Lot Bid Short Quote Appendage, written one after another *)
RECURSIVE EncodeOddLotBidShortQuoteAppendage2List(_)
EncodeOddLotBidShortQuoteAppendage2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOddLotBidShortQuoteAppendage2(Head(messages)) \o EncodeOddLotBidShortQuoteAppendage2List(Tail(messages))

(* As many Odd Lot Bid Short Quote Appendage as the field that counts them says *)
RECURSIVE ReadOddLotBidShortQuoteAppendage2List(_, _)
ReadOddLotBidShortQuoteAppendage2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOddLotBidShortQuoteAppendage2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOddLotBidShortQuoteAppendage2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Odd Lot Bid Short Quote Appendage of each kind, for the lists that carry them *)
OneOddLotBidShortQuoteAppendage2 == { ZeroOddLotBidShortQuoteAppendage2 }

(***************************************************************************)
(* Odd Lot Offer Short Quote Appendage: 3 bytes                            *)
(***************************************************************************)

OddLotOfferShortQuoteAppendage2 ==
    [ oddLotQuotePrice2 : Sample(2),
      oddLotQuoteSize   : Sample(1) ]

EncodeOddLotOfferShortQuoteAppendage2(message) ==
    message.oddLotQuotePrice2
        \o message.oddLotQuoteSize

DecodeOddLotOfferShortQuoteAppendage2(bytes) ==
    LET oddLotQuotePrice2 == ReadBytes(bytes, 2) IN IF ~oddLotQuotePrice2.ok THEN Fail ELSE
    LET oddLotQuoteSize == ReadBytes(oddLotQuotePrice2.rest, 1) IN IF ~oddLotQuoteSize.ok THEN Fail ELSE
    Ok([ oddLotQuotePrice2 |-> oddLotQuotePrice2.value,
         oddLotQuoteSize   |-> oddLotQuoteSize.value ], oddLotQuoteSize.rest)

ZeroOddLotOfferShortQuoteAppendage2 ==
    [ oddLotQuotePrice2 |-> [i \in 1 .. 2 |-> 0],
      oddLotQuoteSize   |-> [i \in 1 .. 1 |-> 0] ]

(* Odd Lot Offer Short Quote Appendage at zero, then each field in turn at the values it is checked at *)
CheckedOddLotOfferShortQuoteAppendage2 ==
    { ZeroOddLotOfferShortQuoteAppendage2 }
        \cup { [ZeroOddLotOfferShortQuoteAppendage2 EXCEPT !.oddLotQuotePrice2 = one] : one \in Sample(2) }
        \cup { [ZeroOddLotOfferShortQuoteAppendage2 EXCEPT !.oddLotQuoteSize = one] : one \in Sample(1) }

(* A run of Odd Lot Offer Short Quote Appendage, written one after another *)
RECURSIVE EncodeOddLotOfferShortQuoteAppendage2List(_)
EncodeOddLotOfferShortQuoteAppendage2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOddLotOfferShortQuoteAppendage2(Head(messages)) \o EncodeOddLotOfferShortQuoteAppendage2List(Tail(messages))

(* As many Odd Lot Offer Short Quote Appendage as the field that counts them says *)
RECURSIVE ReadOddLotOfferShortQuoteAppendage2List(_, _)
ReadOddLotOfferShortQuoteAppendage2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOddLotOfferShortQuoteAppendage2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOddLotOfferShortQuoteAppendage2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Odd Lot Offer Short Quote Appendage of each kind, for the lists that carry them *)
OneOddLotOfferShortQuoteAppendage2 == { ZeroOddLotOfferShortQuoteAppendage2 }

(***************************************************************************)
(* Odd Lot Short Quote Message                                             *)
(***************************************************************************)

OddLotShortQuoteMessage ==
    [ securitySymbolShort            : Sample(5),
      clearPriorOddLotQuotes         : Sample(1),
      oddLotBidShortQuoteAppendage   : SampleLists(OneOddLotBidShortQuoteAppendage2),
      oddLotOfferShortQuoteAppendage : SampleLists(OneOddLotOfferShortQuoteAppendage2) ]

EncodeOddLotShortQuoteMessage(message) ==
    message.securitySymbolShort
        \o message.clearPriorOddLotQuotes
        \o EncodeUIntBE(Len(message.oddLotBidShortQuoteAppendage), 1)
        \o EncodeUIntBE(Len(message.oddLotOfferShortQuoteAppendage), 1)
        \o EncodeOddLotBidShortQuoteAppendage2List(message.oddLotBidShortQuoteAppendage)
        \o EncodeOddLotOfferShortQuoteAppendage2List(message.oddLotOfferShortQuoteAppendage)

DecodeOddLotShortQuoteMessage(bytes) ==
    LET securitySymbolShort == ReadBytes(bytes, 5) IN IF ~securitySymbolShort.ok THEN Fail ELSE
    LET clearPriorOddLotQuotes == ReadBytes(securitySymbolShort.rest, 1) IN IF ~clearPriorOddLotQuotes.ok THEN Fail ELSE
    LET countOfOddLotBidAppendages == ReadUIntBE(clearPriorOddLotQuotes.rest, 1) IN IF ~countOfOddLotBidAppendages.ok THEN Fail ELSE
    LET countOfOddLotOfferAppendages == ReadUIntBE(countOfOddLotBidAppendages.rest, 1) IN IF ~countOfOddLotOfferAppendages.ok THEN Fail ELSE
    LET oddLotBidShortQuoteAppendage == ReadOddLotBidShortQuoteAppendage2List(countOfOddLotOfferAppendages.rest, countOfOddLotBidAppendages.value) IN IF ~oddLotBidShortQuoteAppendage.ok THEN Fail ELSE
    LET oddLotOfferShortQuoteAppendage == ReadOddLotOfferShortQuoteAppendage2List(oddLotBidShortQuoteAppendage.rest, countOfOddLotOfferAppendages.value) IN IF ~oddLotOfferShortQuoteAppendage.ok THEN Fail ELSE
    Ok([ securitySymbolShort            |-> securitySymbolShort.value,
         clearPriorOddLotQuotes         |-> clearPriorOddLotQuotes.value,
         oddLotBidShortQuoteAppendage   |-> oddLotBidShortQuoteAppendage.value,
         oddLotOfferShortQuoteAppendage |-> oddLotOfferShortQuoteAppendage.value ], oddLotOfferShortQuoteAppendage.rest)

ZeroOddLotShortQuoteMessage ==
    [ securitySymbolShort            |-> [i \in 1 .. 5 |-> 0],
      clearPriorOddLotQuotes         |-> [i \in 1 .. 1 |-> 0],
      oddLotBidShortQuoteAppendage   |-> << >>,
      oddLotOfferShortQuoteAppendage |-> << >> ]

(* Odd Lot Short Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedOddLotShortQuoteMessage ==
    { ZeroOddLotShortQuoteMessage }
        \cup { [ZeroOddLotShortQuoteMessage EXCEPT !.securitySymbolShort = one] : one \in Sample(5) }
        \cup { [ZeroOddLotShortQuoteMessage EXCEPT !.clearPriorOddLotQuotes = one] : one \in Sample(1) }
        \cup { [ZeroOddLotShortQuoteMessage EXCEPT !.oddLotBidShortQuoteAppendage = one] : one \in SampleLists(OneOddLotBidShortQuoteAppendage2) }
        \cup { [ZeroOddLotShortQuoteMessage EXCEPT !.oddLotOfferShortQuoteAppendage = one] : one \in SampleLists(OneOddLotOfferShortQuoteAppendage2) }

(***************************************************************************)
(* Odd Lot Bid Long Quote Appendage: 9 bytes                               *)
(***************************************************************************)

OddLotBidLongQuoteAppendage2 ==
    [ oddLotQuotePrice : Sample(8),
      oddLotQuoteSize  : Sample(1) ]

EncodeOddLotBidLongQuoteAppendage2(message) ==
    message.oddLotQuotePrice
        \o message.oddLotQuoteSize

DecodeOddLotBidLongQuoteAppendage2(bytes) ==
    LET oddLotQuotePrice == ReadBytes(bytes, 8) IN IF ~oddLotQuotePrice.ok THEN Fail ELSE
    LET oddLotQuoteSize == ReadBytes(oddLotQuotePrice.rest, 1) IN IF ~oddLotQuoteSize.ok THEN Fail ELSE
    Ok([ oddLotQuotePrice |-> oddLotQuotePrice.value,
         oddLotQuoteSize  |-> oddLotQuoteSize.value ], oddLotQuoteSize.rest)

ZeroOddLotBidLongQuoteAppendage2 ==
    [ oddLotQuotePrice |-> [i \in 1 .. 8 |-> 0],
      oddLotQuoteSize  |-> [i \in 1 .. 1 |-> 0] ]

(* Odd Lot Bid Long Quote Appendage at zero, then each field in turn at the values it is checked at *)
CheckedOddLotBidLongQuoteAppendage2 ==
    { ZeroOddLotBidLongQuoteAppendage2 }
        \cup { [ZeroOddLotBidLongQuoteAppendage2 EXCEPT !.oddLotQuotePrice = one] : one \in Sample(8) }
        \cup { [ZeroOddLotBidLongQuoteAppendage2 EXCEPT !.oddLotQuoteSize = one] : one \in Sample(1) }

(* A run of Odd Lot Bid Long Quote Appendage, written one after another *)
RECURSIVE EncodeOddLotBidLongQuoteAppendage2List(_)
EncodeOddLotBidLongQuoteAppendage2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOddLotBidLongQuoteAppendage2(Head(messages)) \o EncodeOddLotBidLongQuoteAppendage2List(Tail(messages))

(* As many Odd Lot Bid Long Quote Appendage as the field that counts them says *)
RECURSIVE ReadOddLotBidLongQuoteAppendage2List(_, _)
ReadOddLotBidLongQuoteAppendage2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOddLotBidLongQuoteAppendage2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOddLotBidLongQuoteAppendage2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Odd Lot Bid Long Quote Appendage of each kind, for the lists that carry them *)
OneOddLotBidLongQuoteAppendage2 == { ZeroOddLotBidLongQuoteAppendage2 }

(***************************************************************************)
(* Odd Lot Offer Long Quote Appendage: 9 bytes                             *)
(***************************************************************************)

OddLotOfferLongQuoteAppendage2 ==
    [ oddLotQuotePrice : Sample(8),
      oddLotQuoteSize  : Sample(1) ]

EncodeOddLotOfferLongQuoteAppendage2(message) ==
    message.oddLotQuotePrice
        \o message.oddLotQuoteSize

DecodeOddLotOfferLongQuoteAppendage2(bytes) ==
    LET oddLotQuotePrice == ReadBytes(bytes, 8) IN IF ~oddLotQuotePrice.ok THEN Fail ELSE
    LET oddLotQuoteSize == ReadBytes(oddLotQuotePrice.rest, 1) IN IF ~oddLotQuoteSize.ok THEN Fail ELSE
    Ok([ oddLotQuotePrice |-> oddLotQuotePrice.value,
         oddLotQuoteSize  |-> oddLotQuoteSize.value ], oddLotQuoteSize.rest)

ZeroOddLotOfferLongQuoteAppendage2 ==
    [ oddLotQuotePrice |-> [i \in 1 .. 8 |-> 0],
      oddLotQuoteSize  |-> [i \in 1 .. 1 |-> 0] ]

(* Odd Lot Offer Long Quote Appendage at zero, then each field in turn at the values it is checked at *)
CheckedOddLotOfferLongQuoteAppendage2 ==
    { ZeroOddLotOfferLongQuoteAppendage2 }
        \cup { [ZeroOddLotOfferLongQuoteAppendage2 EXCEPT !.oddLotQuotePrice = one] : one \in Sample(8) }
        \cup { [ZeroOddLotOfferLongQuoteAppendage2 EXCEPT !.oddLotQuoteSize = one] : one \in Sample(1) }

(* A run of Odd Lot Offer Long Quote Appendage, written one after another *)
RECURSIVE EncodeOddLotOfferLongQuoteAppendage2List(_)
EncodeOddLotOfferLongQuoteAppendage2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOddLotOfferLongQuoteAppendage2(Head(messages)) \o EncodeOddLotOfferLongQuoteAppendage2List(Tail(messages))

(* As many Odd Lot Offer Long Quote Appendage as the field that counts them says *)
RECURSIVE ReadOddLotOfferLongQuoteAppendage2List(_, _)
ReadOddLotOfferLongQuoteAppendage2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOddLotOfferLongQuoteAppendage2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOddLotOfferLongQuoteAppendage2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Odd Lot Offer Long Quote Appendage of each kind, for the lists that carry them *)
OneOddLotOfferLongQuoteAppendage2 == { ZeroOddLotOfferLongQuoteAppendage2 }

(***************************************************************************)
(* Odd Lot Long Quote Message                                              *)
(***************************************************************************)

OddLotLongQuoteMessage ==
    [ securitySymbol                : Sample(11),
      clearPriorOddLotQuotes        : Sample(1),
      oddLotBidLongQuoteAppendage   : SampleLists(OneOddLotBidLongQuoteAppendage2),
      oddLotOfferLongQuoteAppendage : SampleLists(OneOddLotOfferLongQuoteAppendage2) ]

EncodeOddLotLongQuoteMessage(message) ==
    message.securitySymbol
        \o message.clearPriorOddLotQuotes
        \o EncodeUIntBE(Len(message.oddLotBidLongQuoteAppendage), 1)
        \o EncodeUIntBE(Len(message.oddLotOfferLongQuoteAppendage), 1)
        \o EncodeOddLotBidLongQuoteAppendage2List(message.oddLotBidLongQuoteAppendage)
        \o EncodeOddLotOfferLongQuoteAppendage2List(message.oddLotOfferLongQuoteAppendage)

DecodeOddLotLongQuoteMessage(bytes) ==
    LET securitySymbol == ReadBytes(bytes, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET clearPriorOddLotQuotes == ReadBytes(securitySymbol.rest, 1) IN IF ~clearPriorOddLotQuotes.ok THEN Fail ELSE
    LET countOfOddLotBidAppendages == ReadUIntBE(clearPriorOddLotQuotes.rest, 1) IN IF ~countOfOddLotBidAppendages.ok THEN Fail ELSE
    LET countOfOddLotOfferAppendages == ReadUIntBE(countOfOddLotBidAppendages.rest, 1) IN IF ~countOfOddLotOfferAppendages.ok THEN Fail ELSE
    LET oddLotBidLongQuoteAppendage == ReadOddLotBidLongQuoteAppendage2List(countOfOddLotOfferAppendages.rest, countOfOddLotBidAppendages.value) IN IF ~oddLotBidLongQuoteAppendage.ok THEN Fail ELSE
    LET oddLotOfferLongQuoteAppendage == ReadOddLotOfferLongQuoteAppendage2List(oddLotBidLongQuoteAppendage.rest, countOfOddLotOfferAppendages.value) IN IF ~oddLotOfferLongQuoteAppendage.ok THEN Fail ELSE
    Ok([ securitySymbol                |-> securitySymbol.value,
         clearPriorOddLotQuotes        |-> clearPriorOddLotQuotes.value,
         oddLotBidLongQuoteAppendage   |-> oddLotBidLongQuoteAppendage.value,
         oddLotOfferLongQuoteAppendage |-> oddLotOfferLongQuoteAppendage.value ], oddLotOfferLongQuoteAppendage.rest)

ZeroOddLotLongQuoteMessage ==
    [ securitySymbol                |-> [i \in 1 .. 11 |-> 0],
      clearPriorOddLotQuotes        |-> [i \in 1 .. 1 |-> 0],
      oddLotBidLongQuoteAppendage   |-> << >>,
      oddLotOfferLongQuoteAppendage |-> << >> ]

(* Odd Lot Long Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedOddLotLongQuoteMessage ==
    { ZeroOddLotLongQuoteMessage }
        \cup { [ZeroOddLotLongQuoteMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroOddLotLongQuoteMessage EXCEPT !.clearPriorOddLotQuotes = one] : one \in Sample(1) }
        \cup { [ZeroOddLotLongQuoteMessage EXCEPT !.oddLotBidLongQuoteAppendage = one] : one \in SampleLists(OneOddLotBidLongQuoteAppendage2) }
        \cup { [ZeroOddLotLongQuoteMessage EXCEPT !.oddLotOfferLongQuoteAppendage = one] : one \in SampleLists(OneOddLotOfferLongQuoteAppendage2) }

(***************************************************************************)
(* Odd Lot Bid Extended Quote Appendage: 13 bytes                          *)
(***************************************************************************)

OddLotBidExtendedQuoteAppendage2 ==
    [ oddLotQuotePrice         : Sample(8),
      oddLotQuoteSize          : Sample(1),
      oddLotFinraMarketMakerId : Sample(4) ]

EncodeOddLotBidExtendedQuoteAppendage2(message) ==
    message.oddLotQuotePrice
        \o message.oddLotQuoteSize
        \o message.oddLotFinraMarketMakerId

DecodeOddLotBidExtendedQuoteAppendage2(bytes) ==
    LET oddLotQuotePrice == ReadBytes(bytes, 8) IN IF ~oddLotQuotePrice.ok THEN Fail ELSE
    LET oddLotQuoteSize == ReadBytes(oddLotQuotePrice.rest, 1) IN IF ~oddLotQuoteSize.ok THEN Fail ELSE
    LET oddLotFinraMarketMakerId == ReadBytes(oddLotQuoteSize.rest, 4) IN IF ~oddLotFinraMarketMakerId.ok THEN Fail ELSE
    Ok([ oddLotQuotePrice         |-> oddLotQuotePrice.value,
         oddLotQuoteSize          |-> oddLotQuoteSize.value,
         oddLotFinraMarketMakerId |-> oddLotFinraMarketMakerId.value ], oddLotFinraMarketMakerId.rest)

ZeroOddLotBidExtendedQuoteAppendage2 ==
    [ oddLotQuotePrice         |-> [i \in 1 .. 8 |-> 0],
      oddLotQuoteSize          |-> [i \in 1 .. 1 |-> 0],
      oddLotFinraMarketMakerId |-> [i \in 1 .. 4 |-> 0] ]

(* Odd Lot Bid Extended Quote Appendage at zero, then each field in turn at the values it is checked at *)
CheckedOddLotBidExtendedQuoteAppendage2 ==
    { ZeroOddLotBidExtendedQuoteAppendage2 }
        \cup { [ZeroOddLotBidExtendedQuoteAppendage2 EXCEPT !.oddLotQuotePrice = one] : one \in Sample(8) }
        \cup { [ZeroOddLotBidExtendedQuoteAppendage2 EXCEPT !.oddLotQuoteSize = one] : one \in Sample(1) }
        \cup { [ZeroOddLotBidExtendedQuoteAppendage2 EXCEPT !.oddLotFinraMarketMakerId = one] : one \in Sample(4) }

(* A run of Odd Lot Bid Extended Quote Appendage, written one after another *)
RECURSIVE EncodeOddLotBidExtendedQuoteAppendage2List(_)
EncodeOddLotBidExtendedQuoteAppendage2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOddLotBidExtendedQuoteAppendage2(Head(messages)) \o EncodeOddLotBidExtendedQuoteAppendage2List(Tail(messages))

(* As many Odd Lot Bid Extended Quote Appendage as the field that counts them says *)
RECURSIVE ReadOddLotBidExtendedQuoteAppendage2List(_, _)
ReadOddLotBidExtendedQuoteAppendage2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOddLotBidExtendedQuoteAppendage2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOddLotBidExtendedQuoteAppendage2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Odd Lot Bid Extended Quote Appendage of each kind, for the lists that carry them *)
OneOddLotBidExtendedQuoteAppendage2 == { ZeroOddLotBidExtendedQuoteAppendage2 }

(***************************************************************************)
(* Odd Lot Offer Extended Quote Appendage: 13 bytes                        *)
(***************************************************************************)

OddLotOfferExtendedQuoteAppendage2 ==
    [ oddLotQuotePrice         : Sample(8),
      oddLotQuoteSize          : Sample(1),
      oddLotFinraMarketMakerId : Sample(4) ]

EncodeOddLotOfferExtendedQuoteAppendage2(message) ==
    message.oddLotQuotePrice
        \o message.oddLotQuoteSize
        \o message.oddLotFinraMarketMakerId

DecodeOddLotOfferExtendedQuoteAppendage2(bytes) ==
    LET oddLotQuotePrice == ReadBytes(bytes, 8) IN IF ~oddLotQuotePrice.ok THEN Fail ELSE
    LET oddLotQuoteSize == ReadBytes(oddLotQuotePrice.rest, 1) IN IF ~oddLotQuoteSize.ok THEN Fail ELSE
    LET oddLotFinraMarketMakerId == ReadBytes(oddLotQuoteSize.rest, 4) IN IF ~oddLotFinraMarketMakerId.ok THEN Fail ELSE
    Ok([ oddLotQuotePrice         |-> oddLotQuotePrice.value,
         oddLotQuoteSize          |-> oddLotQuoteSize.value,
         oddLotFinraMarketMakerId |-> oddLotFinraMarketMakerId.value ], oddLotFinraMarketMakerId.rest)

ZeroOddLotOfferExtendedQuoteAppendage2 ==
    [ oddLotQuotePrice         |-> [i \in 1 .. 8 |-> 0],
      oddLotQuoteSize          |-> [i \in 1 .. 1 |-> 0],
      oddLotFinraMarketMakerId |-> [i \in 1 .. 4 |-> 0] ]

(* Odd Lot Offer Extended Quote Appendage at zero, then each field in turn at the values it is checked at *)
CheckedOddLotOfferExtendedQuoteAppendage2 ==
    { ZeroOddLotOfferExtendedQuoteAppendage2 }
        \cup { [ZeroOddLotOfferExtendedQuoteAppendage2 EXCEPT !.oddLotQuotePrice = one] : one \in Sample(8) }
        \cup { [ZeroOddLotOfferExtendedQuoteAppendage2 EXCEPT !.oddLotQuoteSize = one] : one \in Sample(1) }
        \cup { [ZeroOddLotOfferExtendedQuoteAppendage2 EXCEPT !.oddLotFinraMarketMakerId = one] : one \in Sample(4) }

(* A run of Odd Lot Offer Extended Quote Appendage, written one after another *)
RECURSIVE EncodeOddLotOfferExtendedQuoteAppendage2List(_)
EncodeOddLotOfferExtendedQuoteAppendage2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOddLotOfferExtendedQuoteAppendage2(Head(messages)) \o EncodeOddLotOfferExtendedQuoteAppendage2List(Tail(messages))

(* As many Odd Lot Offer Extended Quote Appendage as the field that counts them says *)
RECURSIVE ReadOddLotOfferExtendedQuoteAppendage2List(_, _)
ReadOddLotOfferExtendedQuoteAppendage2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOddLotOfferExtendedQuoteAppendage2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOddLotOfferExtendedQuoteAppendage2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Odd Lot Offer Extended Quote Appendage of each kind, for the lists that carry them *)
OneOddLotOfferExtendedQuoteAppendage2 == { ZeroOddLotOfferExtendedQuoteAppendage2 }

(***************************************************************************)
(* Odd Lot Finra Adf Quote Message                                         *)
(***************************************************************************)

OddLotFinraAdfQuoteMessage ==
    [ securitySymbol                    : Sample(11),
      clearPriorOddLotQuotes            : Sample(1),
      oddLotBidExtendedQuoteAppendage   : SampleLists(OneOddLotBidExtendedQuoteAppendage2),
      oddLotOfferExtendedQuoteAppendage : SampleLists(OneOddLotOfferExtendedQuoteAppendage2) ]

EncodeOddLotFinraAdfQuoteMessage(message) ==
    message.securitySymbol
        \o message.clearPriorOddLotQuotes
        \o EncodeUIntBE(Len(message.oddLotBidExtendedQuoteAppendage), 1)
        \o EncodeUIntBE(Len(message.oddLotOfferExtendedQuoteAppendage), 1)
        \o EncodeOddLotBidExtendedQuoteAppendage2List(message.oddLotBidExtendedQuoteAppendage)
        \o EncodeOddLotOfferExtendedQuoteAppendage2List(message.oddLotOfferExtendedQuoteAppendage)

DecodeOddLotFinraAdfQuoteMessage(bytes) ==
    LET securitySymbol == ReadBytes(bytes, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET clearPriorOddLotQuotes == ReadBytes(securitySymbol.rest, 1) IN IF ~clearPriorOddLotQuotes.ok THEN Fail ELSE
    LET countOfOddLotBidAppendages == ReadUIntBE(clearPriorOddLotQuotes.rest, 1) IN IF ~countOfOddLotBidAppendages.ok THEN Fail ELSE
    LET countOfOddLotOfferAppendages == ReadUIntBE(countOfOddLotBidAppendages.rest, 1) IN IF ~countOfOddLotOfferAppendages.ok THEN Fail ELSE
    LET oddLotBidExtendedQuoteAppendage == ReadOddLotBidExtendedQuoteAppendage2List(countOfOddLotOfferAppendages.rest, countOfOddLotBidAppendages.value) IN IF ~oddLotBidExtendedQuoteAppendage.ok THEN Fail ELSE
    LET oddLotOfferExtendedQuoteAppendage == ReadOddLotOfferExtendedQuoteAppendage2List(oddLotBidExtendedQuoteAppendage.rest, countOfOddLotOfferAppendages.value) IN IF ~oddLotOfferExtendedQuoteAppendage.ok THEN Fail ELSE
    Ok([ securitySymbol                    |-> securitySymbol.value,
         clearPriorOddLotQuotes            |-> clearPriorOddLotQuotes.value,
         oddLotBidExtendedQuoteAppendage   |-> oddLotBidExtendedQuoteAppendage.value,
         oddLotOfferExtendedQuoteAppendage |-> oddLotOfferExtendedQuoteAppendage.value ], oddLotOfferExtendedQuoteAppendage.rest)

ZeroOddLotFinraAdfQuoteMessage ==
    [ securitySymbol                    |-> [i \in 1 .. 11 |-> 0],
      clearPriorOddLotQuotes            |-> [i \in 1 .. 1 |-> 0],
      oddLotBidExtendedQuoteAppendage   |-> << >>,
      oddLotOfferExtendedQuoteAppendage |-> << >> ]

(* Odd Lot Finra Adf Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedOddLotFinraAdfQuoteMessage ==
    { ZeroOddLotFinraAdfQuoteMessage }
        \cup { [ZeroOddLotFinraAdfQuoteMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroOddLotFinraAdfQuoteMessage EXCEPT !.clearPriorOddLotQuotes = one] : one \in Sample(1) }
        \cup { [ZeroOddLotFinraAdfQuoteMessage EXCEPT !.oddLotBidExtendedQuoteAppendage = one] : one \in SampleLists(OneOddLotBidExtendedQuoteAppendage2) }
        \cup { [ZeroOddLotFinraAdfQuoteMessage EXCEPT !.oddLotOfferExtendedQuoteAppendage = one] : one \in SampleLists(OneOddLotOfferExtendedQuoteAppendage2) }

(***************************************************************************)
(* Quote Message Payload, selected by Quote Message Type                   *)
(***************************************************************************)

AuctionStatusMessageCode == 65  \* "A"
ShortQuoteMessageCode == 81  \* "Q"
LongQuoteMessageCode == 76  \* "L"
SpecialLongQuoteMessageCode == 83  \* "S"
RoundLotShortQuoteMessageCode == 80  \* "P"
RoundLotLongQuoteMessageCode == 75  \* "K"
RoundLotFinraAdfQuoteMessageCode == 85  \* "U"
OddLotShortQuoteMessageCode == 82  \* "R"
OddLotLongQuoteMessageCode == 77  \* "M"
OddLotFinraAdfQuoteMessageCode == 84  \* "T"

QuoteMessagePayload ==
    [ tag : {AuctionStatusMessageCode}, body : AuctionStatusMessage ]
        \cup [ tag : {ShortQuoteMessageCode}, body : ShortQuoteMessage ]
        \cup [ tag : {LongQuoteMessageCode}, body : LongQuoteMessage ]
        \cup [ tag : {SpecialLongQuoteMessageCode}, body : SpecialLongQuoteMessage ]
        \cup [ tag : {RoundLotShortQuoteMessageCode}, body : RoundLotShortQuoteMessage ]
        \cup [ tag : {RoundLotLongQuoteMessageCode}, body : RoundLotLongQuoteMessage ]
        \cup [ tag : {RoundLotFinraAdfQuoteMessageCode}, body : RoundLotFinraAdfQuoteMessage ]
        \cup [ tag : {OddLotShortQuoteMessageCode}, body : OddLotShortQuoteMessage ]
        \cup [ tag : {OddLotLongQuoteMessageCode}, body : OddLotLongQuoteMessage ]
        \cup [ tag : {OddLotFinraAdfQuoteMessageCode}, body : OddLotFinraAdfQuoteMessage ]

EncodeQuoteMessagePayload(message) ==
    CASE message.tag = AuctionStatusMessageCode -> EncodeAuctionStatusMessage(message.body)
      [] message.tag = ShortQuoteMessageCode -> EncodeShortQuoteMessage(message.body)
      [] message.tag = LongQuoteMessageCode -> EncodeLongQuoteMessage(message.body)
      [] message.tag = SpecialLongQuoteMessageCode -> EncodeSpecialLongQuoteMessage(message.body)
      [] message.tag = RoundLotShortQuoteMessageCode -> EncodeRoundLotShortQuoteMessage(message.body)
      [] message.tag = RoundLotLongQuoteMessageCode -> EncodeRoundLotLongQuoteMessage(message.body)
      [] message.tag = RoundLotFinraAdfQuoteMessageCode -> EncodeRoundLotFinraAdfQuoteMessage(message.body)
      [] message.tag = OddLotShortQuoteMessageCode -> EncodeOddLotShortQuoteMessage(message.body)
      [] message.tag = OddLotLongQuoteMessageCode -> EncodeOddLotLongQuoteMessage(message.body)
      [] message.tag = OddLotFinraAdfQuoteMessageCode -> EncodeOddLotFinraAdfQuoteMessage(message.body)

DecodeQuoteMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = AuctionStatusMessageCode -> DecodeAuctionStatusMessage(bytes)
              [] tag = ShortQuoteMessageCode -> DecodeShortQuoteMessage(bytes)
              [] tag = LongQuoteMessageCode -> DecodeLongQuoteMessage(bytes)
              [] tag = SpecialLongQuoteMessageCode -> DecodeSpecialLongQuoteMessage(bytes)
              [] tag = RoundLotShortQuoteMessageCode -> DecodeRoundLotShortQuoteMessage(bytes)
              [] tag = RoundLotLongQuoteMessageCode -> DecodeRoundLotLongQuoteMessage(bytes)
              [] tag = RoundLotFinraAdfQuoteMessageCode -> DecodeRoundLotFinraAdfQuoteMessage(bytes)
              [] tag = OddLotShortQuoteMessageCode -> DecodeOddLotShortQuoteMessage(bytes)
              [] tag = OddLotLongQuoteMessageCode -> DecodeOddLotLongQuoteMessage(bytes)
              [] tag = OddLotFinraAdfQuoteMessageCode -> DecodeOddLotFinraAdfQuoteMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroQuoteMessagePayload == [tag |-> AuctionStatusMessageCode, body |-> ZeroAuctionStatusMessage]

(* Each Quote Message Payload in turn, at the values the message it names is checked at *)
CheckedQuoteMessagePayload ==
    { [tag |-> AuctionStatusMessageCode, body |-> one] : one \in CheckedAuctionStatusMessage }
        \cup { [tag |-> ShortQuoteMessageCode, body |-> one] : one \in CheckedShortQuoteMessage }
        \cup { [tag |-> LongQuoteMessageCode, body |-> one] : one \in CheckedLongQuoteMessage }
        \cup { [tag |-> SpecialLongQuoteMessageCode, body |-> one] : one \in CheckedSpecialLongQuoteMessage }
        \cup { [tag |-> RoundLotShortQuoteMessageCode, body |-> one] : one \in CheckedRoundLotShortQuoteMessage }
        \cup { [tag |-> RoundLotLongQuoteMessageCode, body |-> one] : one \in CheckedRoundLotLongQuoteMessage }
        \cup { [tag |-> RoundLotFinraAdfQuoteMessageCode, body |-> one] : one \in CheckedRoundLotFinraAdfQuoteMessage }
        \cup { [tag |-> OddLotShortQuoteMessageCode, body |-> one] : one \in CheckedOddLotShortQuoteMessage }
        \cup { [tag |-> OddLotLongQuoteMessageCode, body |-> one] : one \in CheckedOddLotLongQuoteMessage }
        \cup { [tag |-> OddLotFinraAdfQuoteMessageCode, body |-> one] : one \in CheckedOddLotFinraAdfQuoteMessage }

(***************************************************************************)
(* Quote Message                                                           *)
(***************************************************************************)

QuoteMessage ==
    [ quoteMessagePayload : QuoteMessagePayload ]

EncodeQuoteMessage(message) ==
    EncodeUIntBE(message.quoteMessagePayload.tag, 1)
        \o EncodeQuoteMessagePayload(message.quoteMessagePayload)

DecodeQuoteMessage(bytes) ==
    LET quoteMessageType == ReadUIntBE(bytes, 1) IN IF ~quoteMessageType.ok THEN Fail ELSE
    LET quoteMessagePayload == DecodeQuoteMessagePayload(quoteMessageType.value, quoteMessageType.rest) IN IF ~quoteMessagePayload.ok THEN Fail ELSE
    Ok([ quoteMessagePayload |-> quoteMessagePayload.value ], quoteMessagePayload.rest)

ZeroQuoteMessage ==
    [ quoteMessagePayload |-> ZeroQuoteMessagePayload ]

(* Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteMessage ==
    { ZeroQuoteMessage }
        \cup { [ZeroQuoteMessage EXCEPT !.quoteMessagePayload = one] : one \in CheckedQuoteMessagePayload }

(***************************************************************************)
(* Trading Status Message: 51 bytes                                        *)
(***************************************************************************)

TradingStatusMessage ==
    [ securitySymbol                              : Sample(11),
      instrumentType                              : Sample(1),
      lastPriceOpeningReopeningLuldReferencePrice : Sample(8),
      highIndicationPriceUpperLimitPriceBand      : Sample(8),
      lowIndicationPriceLowerLimitPriceBand       : Sample(8),
      buyVolume                                   : Sample(4),
      sellVolume                                  : Sample(4),
      securityStatus                              : Sample(1),
      haltReason                                  : Sample(1),
      shortSaleRestrictionIndicator               : Sample(1),
      tradingStatusId                             : Sample(4) ]

EncodeTradingStatusMessage(message) ==
    message.securitySymbol
        \o message.instrumentType
        \o message.lastPriceOpeningReopeningLuldReferencePrice
        \o message.highIndicationPriceUpperLimitPriceBand
        \o message.lowIndicationPriceLowerLimitPriceBand
        \o message.buyVolume
        \o message.sellVolume
        \o message.securityStatus
        \o message.haltReason
        \o message.shortSaleRestrictionIndicator
        \o message.tradingStatusId

DecodeTradingStatusMessage(bytes) ==
    LET securitySymbol == ReadBytes(bytes, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET lastPriceOpeningReopeningLuldReferencePrice == ReadBytes(instrumentType.rest, 8) IN IF ~lastPriceOpeningReopeningLuldReferencePrice.ok THEN Fail ELSE
    LET highIndicationPriceUpperLimitPriceBand == ReadBytes(lastPriceOpeningReopeningLuldReferencePrice.rest, 8) IN IF ~highIndicationPriceUpperLimitPriceBand.ok THEN Fail ELSE
    LET lowIndicationPriceLowerLimitPriceBand == ReadBytes(highIndicationPriceUpperLimitPriceBand.rest, 8) IN IF ~lowIndicationPriceLowerLimitPriceBand.ok THEN Fail ELSE
    LET buyVolume == ReadBytes(lowIndicationPriceLowerLimitPriceBand.rest, 4) IN IF ~buyVolume.ok THEN Fail ELSE
    LET sellVolume == ReadBytes(buyVolume.rest, 4) IN IF ~sellVolume.ok THEN Fail ELSE
    LET securityStatus == ReadBytes(sellVolume.rest, 1) IN IF ~securityStatus.ok THEN Fail ELSE
    LET haltReason == ReadBytes(securityStatus.rest, 1) IN IF ~haltReason.ok THEN Fail ELSE
    LET shortSaleRestrictionIndicator == ReadBytes(haltReason.rest, 1) IN IF ~shortSaleRestrictionIndicator.ok THEN Fail ELSE
    LET tradingStatusId == ReadBytes(shortSaleRestrictionIndicator.rest, 4) IN IF ~tradingStatusId.ok THEN Fail ELSE
    Ok([ securitySymbol                              |-> securitySymbol.value,
         instrumentType                              |-> instrumentType.value,
         lastPriceOpeningReopeningLuldReferencePrice |-> lastPriceOpeningReopeningLuldReferencePrice.value,
         highIndicationPriceUpperLimitPriceBand      |-> highIndicationPriceUpperLimitPriceBand.value,
         lowIndicationPriceLowerLimitPriceBand       |-> lowIndicationPriceLowerLimitPriceBand.value,
         buyVolume                                   |-> buyVolume.value,
         sellVolume                                  |-> sellVolume.value,
         securityStatus                              |-> securityStatus.value,
         haltReason                                  |-> haltReason.value,
         shortSaleRestrictionIndicator               |-> shortSaleRestrictionIndicator.value,
         tradingStatusId                             |-> tradingStatusId.value ], tradingStatusId.rest)

ZeroTradingStatusMessage ==
    [ securitySymbol                              |-> [i \in 1 .. 11 |-> 0],
      instrumentType                              |-> [i \in 1 .. 1 |-> 0],
      lastPriceOpeningReopeningLuldReferencePrice |-> [i \in 1 .. 8 |-> 0],
      highIndicationPriceUpperLimitPriceBand      |-> [i \in 1 .. 8 |-> 0],
      lowIndicationPriceLowerLimitPriceBand       |-> [i \in 1 .. 8 |-> 0],
      buyVolume                                   |-> [i \in 1 .. 4 |-> 0],
      sellVolume                                  |-> [i \in 1 .. 4 |-> 0],
      securityStatus                              |-> [i \in 1 .. 1 |-> 0],
      haltReason                                  |-> [i \in 1 .. 1 |-> 0],
      shortSaleRestrictionIndicator               |-> [i \in 1 .. 1 |-> 0],
      tradingStatusId                             |-> [i \in 1 .. 4 |-> 0] ]

(* Trading Status Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingStatusMessage ==
    { ZeroTradingStatusMessage }
        \cup { [ZeroTradingStatusMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.lastPriceOpeningReopeningLuldReferencePrice = one] : one \in Sample(8) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.highIndicationPriceUpperLimitPriceBand = one] : one \in Sample(8) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.lowIndicationPriceLowerLimitPriceBand = one] : one \in Sample(8) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.buyVolume = one] : one \in Sample(4) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.sellVolume = one] : one \in Sample(4) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.securityStatus = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.haltReason = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.shortSaleRestrictionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.tradingStatusId = one] : one \in Sample(4) }

(***************************************************************************)
(* Trade Message Payload, selected by Trade Message Type                   *)
(***************************************************************************)

TradingStatusMessageCode == 83  \* "S"

TradeMessagePayload ==
    [ tag : {TradingStatusMessageCode}, body : TradingStatusMessage ]

EncodeTradeMessagePayload(message) ==
    CASE message.tag = TradingStatusMessageCode -> EncodeTradingStatusMessage(message.body)

DecodeTradeMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = TradingStatusMessageCode -> DecodeTradingStatusMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroTradeMessagePayload == [tag |-> TradingStatusMessageCode, body |-> ZeroTradingStatusMessage]

(* Each Trade Message Payload in turn, at the values the message it names is checked at *)
CheckedTradeMessagePayload ==
    { [tag |-> TradingStatusMessageCode, body |-> one] : one \in CheckedTradingStatusMessage }

(***************************************************************************)
(* Trade Message                                                           *)
(***************************************************************************)

TradeMessage ==
    [ tradeMessagePayload : TradeMessagePayload ]

EncodeTradeMessage(message) ==
    EncodeUIntBE(message.tradeMessagePayload.tag, 1)
        \o EncodeTradeMessagePayload(message.tradeMessagePayload)

DecodeTradeMessage(bytes) ==
    LET tradeMessageType == ReadUIntBE(bytes, 1) IN IF ~tradeMessageType.ok THEN Fail ELSE
    LET tradeMessagePayload == DecodeTradeMessagePayload(tradeMessageType.value, tradeMessageType.rest) IN IF ~tradeMessagePayload.ok THEN Fail ELSE
    Ok([ tradeMessagePayload |-> tradeMessagePayload.value ], tradeMessagePayload.rest)

ZeroTradeMessage ==
    [ tradeMessagePayload |-> ZeroTradeMessagePayload ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.tradeMessagePayload = one] : one \in CheckedTradeMessagePayload }

(***************************************************************************)
(* Category Payload, selected by Message Category                          *)
(***************************************************************************)

AdministrativeMessageCode == 65  \* "A"
ControlMessageCode == 67  \* "C"
QuoteMessageCode == 81  \* "Q"
TradeMessageCode == 84  \* "T"

CategoryPayload ==
    [ tag : {AdministrativeMessageCode}, body : AdministrativeMessage ]
        \cup [ tag : {ControlMessageCode}, body : ControlMessage ]
        \cup [ tag : {QuoteMessageCode}, body : QuoteMessage ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]

EncodeCategoryPayload(message) ==
    CASE message.tag = AdministrativeMessageCode -> EncodeAdministrativeMessage(message.body)
      [] message.tag = ControlMessageCode -> EncodeControlMessage(message.body)
      [] message.tag = QuoteMessageCode -> EncodeQuoteMessage(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)

DecodeCategoryPayload(tag, bytes) ==
    LET read ==
            CASE tag = AdministrativeMessageCode -> DecodeAdministrativeMessage(bytes)
              [] tag = ControlMessageCode -> DecodeControlMessage(bytes)
              [] tag = QuoteMessageCode -> DecodeQuoteMessage(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroCategoryPayload == [tag |-> AdministrativeMessageCode, body |-> ZeroAdministrativeMessage]

(* Each Category Payload in turn, at the values the message it names is checked at *)
CheckedCategoryPayload ==
    { [tag |-> AdministrativeMessageCode, body |-> one] : one \in CheckedAdministrativeMessage }
        \cup { [tag |-> ControlMessageCode, body |-> one] : one \in CheckedControlMessage }
        \cup { [tag |-> QuoteMessageCode, body |-> one] : one \in CheckedQuoteMessage }
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }

(***************************************************************************)
(* Message                                                                 *)
(***************************************************************************)

Message ==
    [ messageLength              : 0 .. 255,
      messageType                : Sample(1),
      participantId              : Sample(1),
      timestamp1                 : Timestamp1,
      messageId                  : Sample(1),
      reserved                   : Sample(4),
      participantReferenceNumber : Sample(8),
      categoryPayload            : CategoryPayload ]

EncodeMessage(message) ==
    EncodeUIntBE(message.messageLength, 2)
        \o EncodeUIntBE(message.categoryPayload.tag, 1)
        \o message.messageType
        \o message.participantId
        \o EncodeTimestamp1(message.timestamp1)
        \o message.messageId
        \o message.reserved
        \o message.participantReferenceNumber
        \o EncodeCategoryPayload(message.categoryPayload)

DecodeMessage(bytes) ==
    LET messageLength == ReadUIntBE(bytes, 2) IN IF ~messageLength.ok THEN Fail ELSE
    LET messageCategory == ReadUIntBE(messageLength.rest, 1) IN IF ~messageCategory.ok THEN Fail ELSE
    LET messageType == ReadBytes(messageCategory.rest, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET participantId == ReadBytes(messageType.rest, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp1(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET reserved == ReadBytes(messageId.rest, 4) IN IF ~reserved.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(reserved.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET categoryPayload == DecodeCategoryPayload(messageCategory.value, participantReferenceNumber.rest) IN IF ~categoryPayload.ok THEN Fail ELSE
    Ok([ messageLength              |-> messageLength.value,
         messageType                |-> messageType.value,
         participantId              |-> participantId.value,
         timestamp1                 |-> timestamp1.value,
         messageId                  |-> messageId.value,
         reserved                   |-> reserved.value,
         participantReferenceNumber |-> participantReferenceNumber.value,
         categoryPayload            |-> categoryPayload.value ], categoryPayload.rest)

ZeroMessage ==
    [ messageLength              |-> 0,
      messageType                |-> [i \in 1 .. 1 |-> 0],
      participantId              |-> [i \in 1 .. 1 |-> 0],
      timestamp1                 |-> ZeroTimestamp1,
      messageId                  |-> [i \in 1 .. 1 |-> 0],
      reserved                   |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      categoryPayload            |-> ZeroCategoryPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.messageLength = one] : one \in {0, 1, 255} }
        \cup { [ZeroMessage EXCEPT !.messageType = one] : one \in Sample(1) }
        \cup { [ZeroMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp1 }
        \cup { [ZeroMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroMessage EXCEPT !.reserved = one] : one \in Sample(4) }
        \cup { [ZeroMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroMessage EXCEPT !.categoryPayload = one] : one \in CheckedCategoryPayload }

(* A run of Message, written one after another *)
RECURSIVE EncodeMessageList(_)
EncodeMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMessage(Head(messages)) \o EncodeMessageList(Tail(messages))

(* As many Message as the field that counts them says *)
RECURSIVE ReadMessageList(_, _)
ReadMessageList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMessageList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Message of each kind, for the lists that carry them *)
OneMessage ==
    { [ZeroMessage EXCEPT !.categoryPayload = [tag |-> AdministrativeMessageCode, body |-> ZeroAdministrativeMessage]],
      [ZeroMessage EXCEPT !.categoryPayload = [tag |-> ControlMessageCode, body |-> ZeroControlMessage]],
      [ZeroMessage EXCEPT !.categoryPayload = [tag |-> QuoteMessageCode, body |-> ZeroQuoteMessage]],
      [ZeroMessage EXCEPT !.categoryPayload = [tag |-> TradeMessageCode, body |-> ZeroTradeMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ blockSeparator      : Sample(2),
      version             : Sample(1),
      blockSize           : Sample(2),
      blockSequenceNumber : Sample(4),
      blockChecksum       : Sample(2),
      message             : SampleLists(OneMessage),
      blockPadByte        : SampleBytes ]

EncodePacket(message) ==
    message.blockSeparator
        \o message.version
        \o message.blockSize
        \o message.blockSequenceNumber
        \o EncodeUIntBE(Len(message.message), 1)
        \o message.blockChecksum
        \o EncodeMessageList(message.message)
        \o message.blockPadByte

DecodePacket(bytes) ==
    LET blockSeparator == ReadBytes(bytes, 2) IN IF ~blockSeparator.ok THEN Fail ELSE
    LET version == ReadBytes(blockSeparator.rest, 1) IN IF ~version.ok THEN Fail ELSE
    LET blockSize == ReadBytes(version.rest, 2) IN IF ~blockSize.ok THEN Fail ELSE
    LET blockSequenceNumber == ReadBytes(blockSize.rest, 4) IN IF ~blockSequenceNumber.ok THEN Fail ELSE
    LET messagesInBlock == ReadUIntBE(blockSequenceNumber.rest, 1) IN IF ~messagesInBlock.ok THEN Fail ELSE
    LET blockChecksum == ReadBytes(messagesInBlock.rest, 2) IN IF ~blockChecksum.ok THEN Fail ELSE
    LET message == ReadMessageList(blockChecksum.rest, messagesInBlock.value) IN IF ~message.ok THEN Fail ELSE
    LET blockPadByte == Ok(message.rest, << >>) IN IF ~blockPadByte.ok THEN Fail ELSE
    Ok([ blockSeparator      |-> blockSeparator.value,
         version             |-> version.value,
         blockSize           |-> blockSize.value,
         blockSequenceNumber |-> blockSequenceNumber.value,
         blockChecksum       |-> blockChecksum.value,
         message             |-> message.value,
         blockPadByte        |-> blockPadByte.value ], blockPadByte.rest)

ZeroPacket ==
    [ blockSeparator      |-> [i \in 1 .. 2 |-> 0],
      version             |-> [i \in 1 .. 1 |-> 0],
      blockSize           |-> [i \in 1 .. 2 |-> 0],
      blockSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      blockChecksum       |-> [i \in 1 .. 2 |-> 0],
      message             |-> << >>,
      blockPadByte        |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.blockSeparator = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.version = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.blockSize = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.blockSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.blockChecksum = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.message = one] : one \in SampleLists(OneMessage) }
        \cup { [ZeroPacket EXCEPT !.blockPadByte = one] : one \in SampleBytes }

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

(* Every Timestamp 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp1 ==
    \A message \in CheckedTimestamp1 :
        LET read == DecodeTimestamp1(EncodeTimestamp1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rejection Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRejectionMessage ==
    \A message \in CheckedRejectionMessage :
        LET read == DecodeRejectionMessage(EncodeRejectionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Partial Reject Odd Lot Bid Short Quote Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripPartialRejectOddLotBidShortQuoteAppendage ==
    \A message \in CheckedPartialRejectOddLotBidShortQuoteAppendage :
        LET read == DecodePartialRejectOddLotBidShortQuoteAppendage(EncodePartialRejectOddLotBidShortQuoteAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Partial Reject Odd Lot Offer Short Quote Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripPartialRejectOddLotOfferShortQuoteAppendage ==
    \A message \in CheckedPartialRejectOddLotOfferShortQuoteAppendage :
        LET read == DecodePartialRejectOddLotOfferShortQuoteAppendage(EncodePartialRejectOddLotOfferShortQuoteAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Odd Lot Quote Appendage Type decodes back to what was encoded, and leaves nothing over *)
RoundTripPartialRejectOddLotBidShortQuoteAppendagePartialRejectOddLotOfferShortQuoteAppendage ==
    \A message \in CheckedPartialRejectOddLotBidShortQuoteAppendagePartialRejectOddLotOfferShortQuoteAppendage :
        LET read == DecodePartialRejectOddLotBidShortQuoteAppendagePartialRejectOddLotOfferShortQuoteAppendage(EncodePartialRejectOddLotBidShortQuoteAppendagePartialRejectOddLotOfferShortQuoteAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Partial Reject Odd Lot Bid Long Quote Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripPartialRejectOddLotBidLongQuoteAppendage ==
    \A message \in CheckedPartialRejectOddLotBidLongQuoteAppendage :
        LET read == DecodePartialRejectOddLotBidLongQuoteAppendage(EncodePartialRejectOddLotBidLongQuoteAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Partial Reject Odd Lot Offer Long Quote Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripPartialRejectOddLotOfferLongQuoteAppendage ==
    \A message \in CheckedPartialRejectOddLotOfferLongQuoteAppendage :
        LET read == DecodePartialRejectOddLotOfferLongQuoteAppendage(EncodePartialRejectOddLotOfferLongQuoteAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Odd Lot Quote Appendage Type decodes back to what was encoded, and leaves nothing over *)
RoundTripPartialRejectOddLotBidLongQuoteAppendagePartialRejectOddLotOfferLongQuoteAppendage ==
    \A message \in CheckedPartialRejectOddLotBidLongQuoteAppendagePartialRejectOddLotOfferLongQuoteAppendage :
        LET read == DecodePartialRejectOddLotBidLongQuoteAppendagePartialRejectOddLotOfferLongQuoteAppendage(EncodePartialRejectOddLotBidLongQuoteAppendagePartialRejectOddLotOfferLongQuoteAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Partial Reject Odd Lot Bid Extended Quote Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripPartialRejectOddLotBidExtendedQuoteAppendage ==
    \A message \in CheckedPartialRejectOddLotBidExtendedQuoteAppendage :
        LET read == DecodePartialRejectOddLotBidExtendedQuoteAppendage(EncodePartialRejectOddLotBidExtendedQuoteAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Partial Reject Odd Lot Offer Extended Quote Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripPartialRejectOddLotOfferExtendedQuoteAppendage ==
    \A message \in CheckedPartialRejectOddLotOfferExtendedQuoteAppendage :
        LET read == DecodePartialRejectOddLotOfferExtendedQuoteAppendage(EncodePartialRejectOddLotOfferExtendedQuoteAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Odd Lot Quote Appendage Type decodes back to what was encoded, and leaves nothing over *)
RoundTripPartialRejectOddLotBidExtendedQuoteAppendagePartialRejectOddLotOfferExtendedQuoteAppendage ==
    \A message \in CheckedPartialRejectOddLotBidExtendedQuoteAppendagePartialRejectOddLotOfferExtendedQuoteAppendage :
        LET read == DecodePartialRejectOddLotBidExtendedQuoteAppendagePartialRejectOddLotOfferExtendedQuoteAppendage(EncodePartialRejectOddLotBidExtendedQuoteAppendagePartialRejectOddLotOfferExtendedQuoteAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Partial Rejection Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPartialRejectionMessage ==
    \A message \in CheckedPartialRejectionMessage :
        LET read == DecodePartialRejectionMessage(EncodePartialRejectionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Warning Message decodes back to what was encoded, and leaves nothing over *)
RoundTripWarningMessage ==
    \A message \in CheckedWarningMessage :
        LET read == DecodeWarningMessage(EncodeWarningMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Administrative Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAdministrativeMessage ==
    \A message \in CheckedAdministrativeMessage :
        LET read == DecodeAdministrativeMessage(EncodeAdministrativeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sequence Information And Message Count Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSequenceInformationAndMessageCountResponseMessage ==
    \A message \in CheckedSequenceInformationAndMessageCountResponseMessage :
        LET read == DecodeSequenceInformationAndMessageCountResponseMessage(EncodeSequenceInformationAndMessageCountResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Odd Lot Refresh Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOddLotRefreshRequestMessage ==
    \A message \in CheckedOddLotRefreshRequestMessage :
        LET read == DecodeOddLotRefreshRequestMessage(EncodeOddLotRefreshRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Test Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTestMessage ==
    \A message \in CheckedTestMessage :
        LET read == DecodeTestMessage(EncodeTestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Control Message decodes back to what was encoded, and leaves nothing over *)
RoundTripControlMessage ==
    \A message \in CheckedControlMessage :
        LET read == DecodeControlMessage(EncodeControlMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionStatusMessage ==
    \A message \in CheckedAuctionStatusMessage :
        LET read == DecodeAuctionStatusMessage(EncodeAuctionStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Short Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripShortQuoteMessage ==
    \A message \in CheckedShortQuoteMessage :
        LET read == DecodeShortQuoteMessage(EncodeShortQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 2 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp2 ==
    \A message \in CheckedTimestamp2 :
        LET read == DecodeTimestamp2(EncodeTimestamp2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLongQuoteMessage ==
    \A message \in CheckedLongQuoteMessage :
        LET read == DecodeLongQuoteMessage(EncodeLongQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 2 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp22 ==
    \A message \in CheckedTimestamp22 :
        LET read == DecodeTimestamp22(EncodeTimestamp22(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Special Long Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSpecialLongQuoteMessage ==
    \A message \in CheckedSpecialLongQuoteMessage :
        LET read == DecodeSpecialLongQuoteMessage(EncodeSpecialLongQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Odd Lot Bid Short Quote Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripOddLotBidShortQuoteAppendage ==
    \A message \in CheckedOddLotBidShortQuoteAppendage :
        LET read == DecodeOddLotBidShortQuoteAppendage(EncodeOddLotBidShortQuoteAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Odd Lot Offer Short Quote Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripOddLotOfferShortQuoteAppendage ==
    \A message \in CheckedOddLotOfferShortQuoteAppendage :
        LET read == DecodeOddLotOfferShortQuoteAppendage(EncodeOddLotOfferShortQuoteAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Round Lot Short Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRoundLotShortQuoteMessage ==
    \A message \in CheckedRoundLotShortQuoteMessage :
        LET read == DecodeRoundLotShortQuoteMessage(EncodeRoundLotShortQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 2 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp23 ==
    \A message \in CheckedTimestamp23 :
        LET read == DecodeTimestamp23(EncodeTimestamp23(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Odd Lot Bid Long Quote Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripOddLotBidLongQuoteAppendage ==
    \A message \in CheckedOddLotBidLongQuoteAppendage :
        LET read == DecodeOddLotBidLongQuoteAppendage(EncodeOddLotBidLongQuoteAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Odd Lot Offer Long Quote Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripOddLotOfferLongQuoteAppendage ==
    \A message \in CheckedOddLotOfferLongQuoteAppendage :
        LET read == DecodeOddLotOfferLongQuoteAppendage(EncodeOddLotOfferLongQuoteAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Round Lot Long Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRoundLotLongQuoteMessage ==
    \A message \in CheckedRoundLotLongQuoteMessage :
        LET read == DecodeRoundLotLongQuoteMessage(EncodeRoundLotLongQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 2 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp24 ==
    \A message \in CheckedTimestamp24 :
        LET read == DecodeTimestamp24(EncodeTimestamp24(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Odd Lot Bid Extended Quote Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripOddLotBidExtendedQuoteAppendage ==
    \A message \in CheckedOddLotBidExtendedQuoteAppendage :
        LET read == DecodeOddLotBidExtendedQuoteAppendage(EncodeOddLotBidExtendedQuoteAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Odd Lot Offer Extended Quote Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripOddLotOfferExtendedQuoteAppendage ==
    \A message \in CheckedOddLotOfferExtendedQuoteAppendage :
        LET read == DecodeOddLotOfferExtendedQuoteAppendage(EncodeOddLotOfferExtendedQuoteAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Round Lot Finra Adf Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRoundLotFinraAdfQuoteMessage ==
    \A message \in CheckedRoundLotFinraAdfQuoteMessage :
        LET read == DecodeRoundLotFinraAdfQuoteMessage(EncodeRoundLotFinraAdfQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Odd Lot Bid Short Quote Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripOddLotBidShortQuoteAppendage2 ==
    \A message \in CheckedOddLotBidShortQuoteAppendage2 :
        LET read == DecodeOddLotBidShortQuoteAppendage2(EncodeOddLotBidShortQuoteAppendage2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Odd Lot Offer Short Quote Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripOddLotOfferShortQuoteAppendage2 ==
    \A message \in CheckedOddLotOfferShortQuoteAppendage2 :
        LET read == DecodeOddLotOfferShortQuoteAppendage2(EncodeOddLotOfferShortQuoteAppendage2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Odd Lot Short Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOddLotShortQuoteMessage ==
    \A message \in CheckedOddLotShortQuoteMessage :
        LET read == DecodeOddLotShortQuoteMessage(EncodeOddLotShortQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Odd Lot Bid Long Quote Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripOddLotBidLongQuoteAppendage2 ==
    \A message \in CheckedOddLotBidLongQuoteAppendage2 :
        LET read == DecodeOddLotBidLongQuoteAppendage2(EncodeOddLotBidLongQuoteAppendage2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Odd Lot Offer Long Quote Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripOddLotOfferLongQuoteAppendage2 ==
    \A message \in CheckedOddLotOfferLongQuoteAppendage2 :
        LET read == DecodeOddLotOfferLongQuoteAppendage2(EncodeOddLotOfferLongQuoteAppendage2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Odd Lot Long Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOddLotLongQuoteMessage ==
    \A message \in CheckedOddLotLongQuoteMessage :
        LET read == DecodeOddLotLongQuoteMessage(EncodeOddLotLongQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Odd Lot Bid Extended Quote Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripOddLotBidExtendedQuoteAppendage2 ==
    \A message \in CheckedOddLotBidExtendedQuoteAppendage2 :
        LET read == DecodeOddLotBidExtendedQuoteAppendage2(EncodeOddLotBidExtendedQuoteAppendage2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Odd Lot Offer Extended Quote Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripOddLotOfferExtendedQuoteAppendage2 ==
    \A message \in CheckedOddLotOfferExtendedQuoteAppendage2 :
        LET read == DecodeOddLotOfferExtendedQuoteAppendage2(EncodeOddLotOfferExtendedQuoteAppendage2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Odd Lot Finra Adf Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOddLotFinraAdfQuoteMessage ==
    \A message \in CheckedOddLotFinraAdfQuoteMessage :
        LET read == DecodeOddLotFinraAdfQuoteMessage(EncodeOddLotFinraAdfQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteMessage ==
    \A message \in CheckedQuoteMessage :
        LET read == DecodeQuoteMessage(EncodeQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trading Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingStatusMessage ==
    \A message \in CheckedTradingStatusMessage :
        LET read == DecodeTradingStatusMessage(EncodeTradingStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeMessage ==
    \A message \in CheckedTradeMessage :
        LET read == DecodeTradeMessage(EncodeTradeMessage(message))
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

(* A Odd Lot Quote Appendage Type is selected by the Odd Lot Quote Appendage Type it is written under *)
SelectsOddLotQuoteAppendageTypeChoice ==
    \A message \in CheckedOddLotQuoteAppendageTypeChoice :
        LET read == DecodeOddLotQuoteAppendageTypeChoice(message.tag, EncodeOddLotQuoteAppendageTypeChoice(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Administrative Message Payload is selected by the Administrative Message Type it is written under *)
SelectsAdministrativeMessagePayload ==
    \A message \in CheckedAdministrativeMessagePayload :
        LET read == DecodeAdministrativeMessagePayload(message.tag, EncodeAdministrativeMessagePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Control Message Payload is selected by the Control Message Type it is written under *)
SelectsControlMessagePayload ==
    \A message \in CheckedControlMessagePayload :
        LET read == DecodeControlMessagePayload(message.tag, EncodeControlMessagePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Quote Message Payload is selected by the Quote Message Type it is written under *)
SelectsQuoteMessagePayload ==
    \A message \in CheckedQuoteMessagePayload :
        LET read == DecodeQuoteMessagePayload(message.tag, EncodeQuoteMessagePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Trade Message Payload is selected by the Trade Message Type it is written under *)
SelectsTradeMessagePayload ==
    \A message \in CheckedTradeMessagePayload :
        LET read == DecodeTradeMessagePayload(message.tag, EncodeTradeMessagePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Category Payload is selected by the Message Category it is written under *)
SelectsCategoryPayload ==
    \A message \in CheckedCategoryPayload :
        LET read == DecodeCategoryPayload(message.tag, EncodeCategoryPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
