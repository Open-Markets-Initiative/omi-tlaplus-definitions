------------------- MODULE Nasdaq_Utp_Input_v4_0_Server --------------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) v4.0                                                           *)
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
(* Protected Exchange Quote Message Shortform Message: 41 bytes            *)
(***************************************************************************)

ProtectedExchangeQuoteMessageShortformMessage ==
    [ orig         : Sample(2),
      timestamp1   : Sample(8),
      feedSequence : Sample(8),
      partToken    : Sample(8),
      symbolShort  : Sample(5),
      bidShort     : Sample(2),
      bidSizeShort : Sample(2),
      askShort     : Sample(2),
      askSizeShort : Sample(2),
      cond         : Sample(1),
      rii          : Sample(1) ]

EncodeProtectedExchangeQuoteMessageShortformMessage(message) ==
    message.orig
        \o message.timestamp1
        \o message.feedSequence
        \o message.partToken
        \o message.symbolShort
        \o message.bidShort
        \o message.bidSizeShort
        \o message.askShort
        \o message.askSizeShort
        \o message.cond
        \o message.rii

DecodeProtectedExchangeQuoteMessageShortformMessage(bytes) ==
    LET orig == ReadBytes(bytes, 2) IN IF ~orig.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(orig.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET feedSequence == ReadBytes(timestamp1.rest, 8) IN IF ~feedSequence.ok THEN Fail ELSE
    LET partToken == ReadBytes(feedSequence.rest, 8) IN IF ~partToken.ok THEN Fail ELSE
    LET symbolShort == ReadBytes(partToken.rest, 5) IN IF ~symbolShort.ok THEN Fail ELSE
    LET bidShort == ReadBytes(symbolShort.rest, 2) IN IF ~bidShort.ok THEN Fail ELSE
    LET bidSizeShort == ReadBytes(bidShort.rest, 2) IN IF ~bidSizeShort.ok THEN Fail ELSE
    LET askShort == ReadBytes(bidSizeShort.rest, 2) IN IF ~askShort.ok THEN Fail ELSE
    LET askSizeShort == ReadBytes(askShort.rest, 2) IN IF ~askSizeShort.ok THEN Fail ELSE
    LET cond == ReadBytes(askSizeShort.rest, 1) IN IF ~cond.ok THEN Fail ELSE
    LET rii == ReadBytes(cond.rest, 1) IN IF ~rii.ok THEN Fail ELSE
    Ok([ orig         |-> orig.value,
         timestamp1   |-> timestamp1.value,
         feedSequence |-> feedSequence.value,
         partToken    |-> partToken.value,
         symbolShort  |-> symbolShort.value,
         bidShort     |-> bidShort.value,
         bidSizeShort |-> bidSizeShort.value,
         askShort     |-> askShort.value,
         askSizeShort |-> askSizeShort.value,
         cond         |-> cond.value,
         rii          |-> rii.value ], rii.rest)

ZeroProtectedExchangeQuoteMessageShortformMessage ==
    [ orig         |-> [i \in 1 .. 2 |-> 0],
      timestamp1   |-> [i \in 1 .. 8 |-> 0],
      feedSequence |-> [i \in 1 .. 8 |-> 0],
      partToken    |-> [i \in 1 .. 8 |-> 0],
      symbolShort  |-> [i \in 1 .. 5 |-> 0],
      bidShort     |-> [i \in 1 .. 2 |-> 0],
      bidSizeShort |-> [i \in 1 .. 2 |-> 0],
      askShort     |-> [i \in 1 .. 2 |-> 0],
      askSizeShort |-> [i \in 1 .. 2 |-> 0],
      cond         |-> [i \in 1 .. 1 |-> 0],
      rii          |-> [i \in 1 .. 1 |-> 0] ]

(* Protected Exchange Quote Message Shortform Message at zero, then each field in turn at the values it is checked at *)
CheckedProtectedExchangeQuoteMessageShortformMessage ==
    { ZeroProtectedExchangeQuoteMessageShortformMessage }
        \cup { [ZeroProtectedExchangeQuoteMessageShortformMessage EXCEPT !.orig = one] : one \in Sample(2) }
        \cup { [ZeroProtectedExchangeQuoteMessageShortformMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroProtectedExchangeQuoteMessageShortformMessage EXCEPT !.feedSequence = one] : one \in Sample(8) }
        \cup { [ZeroProtectedExchangeQuoteMessageShortformMessage EXCEPT !.partToken = one] : one \in Sample(8) }
        \cup { [ZeroProtectedExchangeQuoteMessageShortformMessage EXCEPT !.symbolShort = one] : one \in Sample(5) }
        \cup { [ZeroProtectedExchangeQuoteMessageShortformMessage EXCEPT !.bidShort = one] : one \in Sample(2) }
        \cup { [ZeroProtectedExchangeQuoteMessageShortformMessage EXCEPT !.bidSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroProtectedExchangeQuoteMessageShortformMessage EXCEPT !.askShort = one] : one \in Sample(2) }
        \cup { [ZeroProtectedExchangeQuoteMessageShortformMessage EXCEPT !.askSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroProtectedExchangeQuoteMessageShortformMessage EXCEPT !.cond = one] : one \in Sample(1) }
        \cup { [ZeroProtectedExchangeQuoteMessageShortformMessage EXCEPT !.rii = one] : one \in Sample(1) }

(***************************************************************************)
(* Protected Exchange Quote Message Longform Message: 63 bytes             *)
(***************************************************************************)

ProtectedExchangeQuoteMessageLongformMessage ==
    [ orig         : Sample(2),
      timestamp1   : Sample(8),
      feedSequence : Sample(8),
      partToken    : Sample(8),
      symbolLong   : Sample(11),
      bidLong      : Sample(8),
      bidSizeLong  : Sample(4),
      askLong      : Sample(8),
      askSizeLong  : Sample(4),
      cond         : Sample(1),
      rii          : Sample(1) ]

EncodeProtectedExchangeQuoteMessageLongformMessage(message) ==
    message.orig
        \o message.timestamp1
        \o message.feedSequence
        \o message.partToken
        \o message.symbolLong
        \o message.bidLong
        \o message.bidSizeLong
        \o message.askLong
        \o message.askSizeLong
        \o message.cond
        \o message.rii

DecodeProtectedExchangeQuoteMessageLongformMessage(bytes) ==
    LET orig == ReadBytes(bytes, 2) IN IF ~orig.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(orig.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET feedSequence == ReadBytes(timestamp1.rest, 8) IN IF ~feedSequence.ok THEN Fail ELSE
    LET partToken == ReadBytes(feedSequence.rest, 8) IN IF ~partToken.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(partToken.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET bidLong == ReadBytes(symbolLong.rest, 8) IN IF ~bidLong.ok THEN Fail ELSE
    LET bidSizeLong == ReadBytes(bidLong.rest, 4) IN IF ~bidSizeLong.ok THEN Fail ELSE
    LET askLong == ReadBytes(bidSizeLong.rest, 8) IN IF ~askLong.ok THEN Fail ELSE
    LET askSizeLong == ReadBytes(askLong.rest, 4) IN IF ~askSizeLong.ok THEN Fail ELSE
    LET cond == ReadBytes(askSizeLong.rest, 1) IN IF ~cond.ok THEN Fail ELSE
    LET rii == ReadBytes(cond.rest, 1) IN IF ~rii.ok THEN Fail ELSE
    Ok([ orig         |-> orig.value,
         timestamp1   |-> timestamp1.value,
         feedSequence |-> feedSequence.value,
         partToken    |-> partToken.value,
         symbolLong   |-> symbolLong.value,
         bidLong      |-> bidLong.value,
         bidSizeLong  |-> bidSizeLong.value,
         askLong      |-> askLong.value,
         askSizeLong  |-> askSizeLong.value,
         cond         |-> cond.value,
         rii          |-> rii.value ], rii.rest)

ZeroProtectedExchangeQuoteMessageLongformMessage ==
    [ orig         |-> [i \in 1 .. 2 |-> 0],
      timestamp1   |-> [i \in 1 .. 8 |-> 0],
      feedSequence |-> [i \in 1 .. 8 |-> 0],
      partToken    |-> [i \in 1 .. 8 |-> 0],
      symbolLong   |-> [i \in 1 .. 11 |-> 0],
      bidLong      |-> [i \in 1 .. 8 |-> 0],
      bidSizeLong  |-> [i \in 1 .. 4 |-> 0],
      askLong      |-> [i \in 1 .. 8 |-> 0],
      askSizeLong  |-> [i \in 1 .. 4 |-> 0],
      cond         |-> [i \in 1 .. 1 |-> 0],
      rii          |-> [i \in 1 .. 1 |-> 0] ]

(* Protected Exchange Quote Message Longform Message at zero, then each field in turn at the values it is checked at *)
CheckedProtectedExchangeQuoteMessageLongformMessage ==
    { ZeroProtectedExchangeQuoteMessageLongformMessage }
        \cup { [ZeroProtectedExchangeQuoteMessageLongformMessage EXCEPT !.orig = one] : one \in Sample(2) }
        \cup { [ZeroProtectedExchangeQuoteMessageLongformMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroProtectedExchangeQuoteMessageLongformMessage EXCEPT !.feedSequence = one] : one \in Sample(8) }
        \cup { [ZeroProtectedExchangeQuoteMessageLongformMessage EXCEPT !.partToken = one] : one \in Sample(8) }
        \cup { [ZeroProtectedExchangeQuoteMessageLongformMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroProtectedExchangeQuoteMessageLongformMessage EXCEPT !.bidLong = one] : one \in Sample(8) }
        \cup { [ZeroProtectedExchangeQuoteMessageLongformMessage EXCEPT !.bidSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroProtectedExchangeQuoteMessageLongformMessage EXCEPT !.askLong = one] : one \in Sample(8) }
        \cup { [ZeroProtectedExchangeQuoteMessageLongformMessage EXCEPT !.askSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroProtectedExchangeQuoteMessageLongformMessage EXCEPT !.cond = one] : one \in Sample(1) }
        \cup { [ZeroProtectedExchangeQuoteMessageLongformMessage EXCEPT !.rii = one] : one \in Sample(1) }

(***************************************************************************)
(* Odd Lot Bid Short Form Attachment: 4 bytes                              *)
(***************************************************************************)

OddLotBidShortFormAttachment ==
    [ olPriceShort : Sample(2),
      olSize       : Sample(2) ]

EncodeOddLotBidShortFormAttachment(message) ==
    message.olPriceShort
        \o message.olSize

DecodeOddLotBidShortFormAttachment(bytes) ==
    LET olPriceShort == ReadBytes(bytes, 2) IN IF ~olPriceShort.ok THEN Fail ELSE
    LET olSize == ReadBytes(olPriceShort.rest, 2) IN IF ~olSize.ok THEN Fail ELSE
    Ok([ olPriceShort |-> olPriceShort.value,
         olSize       |-> olSize.value ], olSize.rest)

ZeroOddLotBidShortFormAttachment ==
    [ olPriceShort |-> [i \in 1 .. 2 |-> 0],
      olSize       |-> [i \in 1 .. 2 |-> 0] ]

(* Odd Lot Bid Short Form Attachment at zero, then each field in turn at the values it is checked at *)
CheckedOddLotBidShortFormAttachment ==
    { ZeroOddLotBidShortFormAttachment }
        \cup { [ZeroOddLotBidShortFormAttachment EXCEPT !.olPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroOddLotBidShortFormAttachment EXCEPT !.olSize = one] : one \in Sample(2) }

(* A run of Odd Lot Bid Short Form Attachment, written one after another *)
RECURSIVE EncodeOddLotBidShortFormAttachmentList(_)
EncodeOddLotBidShortFormAttachmentList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOddLotBidShortFormAttachment(Head(messages)) \o EncodeOddLotBidShortFormAttachmentList(Tail(messages))

(* As many Odd Lot Bid Short Form Attachment as the field that counts them says *)
RECURSIVE ReadOddLotBidShortFormAttachmentList(_, _)
ReadOddLotBidShortFormAttachmentList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOddLotBidShortFormAttachment(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOddLotBidShortFormAttachmentList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Odd Lot Bid Short Form Attachment of each kind, for the lists that carry them *)
OneOddLotBidShortFormAttachment == { ZeroOddLotBidShortFormAttachment }

(***************************************************************************)
(* Odd Lot Ask Short Form Attachment: 4 bytes                              *)
(***************************************************************************)

OddLotAskShortFormAttachment ==
    [ olPriceShort : Sample(2),
      olSize       : Sample(2) ]

EncodeOddLotAskShortFormAttachment(message) ==
    message.olPriceShort
        \o message.olSize

DecodeOddLotAskShortFormAttachment(bytes) ==
    LET olPriceShort == ReadBytes(bytes, 2) IN IF ~olPriceShort.ok THEN Fail ELSE
    LET olSize == ReadBytes(olPriceShort.rest, 2) IN IF ~olSize.ok THEN Fail ELSE
    Ok([ olPriceShort |-> olPriceShort.value,
         olSize       |-> olSize.value ], olSize.rest)

ZeroOddLotAskShortFormAttachment ==
    [ olPriceShort |-> [i \in 1 .. 2 |-> 0],
      olSize       |-> [i \in 1 .. 2 |-> 0] ]

(* Odd Lot Ask Short Form Attachment at zero, then each field in turn at the values it is checked at *)
CheckedOddLotAskShortFormAttachment ==
    { ZeroOddLotAskShortFormAttachment }
        \cup { [ZeroOddLotAskShortFormAttachment EXCEPT !.olPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroOddLotAskShortFormAttachment EXCEPT !.olSize = one] : one \in Sample(2) }

(* A run of Odd Lot Ask Short Form Attachment, written one after another *)
RECURSIVE EncodeOddLotAskShortFormAttachmentList(_)
EncodeOddLotAskShortFormAttachmentList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOddLotAskShortFormAttachment(Head(messages)) \o EncodeOddLotAskShortFormAttachmentList(Tail(messages))

(* As many Odd Lot Ask Short Form Attachment as the field that counts them says *)
RECURSIVE ReadOddLotAskShortFormAttachmentList(_, _)
ReadOddLotAskShortFormAttachmentList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOddLotAskShortFormAttachment(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOddLotAskShortFormAttachmentList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Odd Lot Ask Short Form Attachment of each kind, for the lists that carry them *)
OneOddLotAskShortFormAttachment == { ZeroOddLotAskShortFormAttachment }

(***************************************************************************)
(* Exchange Odd Lot Quote Message Short Form Message                       *)
(***************************************************************************)

ExchangeOddLotQuoteMessageShortFormMessage ==
    [ orig                         : Sample(2),
      timestamp1                   : Sample(8),
      feedSequence                 : Sample(8),
      partToken                    : Sample(8),
      symbolShort                  : Sample(5),
      oddLotBidShortFormAttachment : SampleLists(OneOddLotBidShortFormAttachment),
      oddLotAskShortFormAttachment : SampleLists(OneOddLotAskShortFormAttachment) ]

EncodeExchangeOddLotQuoteMessageShortFormMessage(message) ==
    message.orig
        \o message.timestamp1
        \o message.feedSequence
        \o message.partToken
        \o message.symbolShort
        \o EncodeUIntBE(Len(message.oddLotBidShortFormAttachment), 2)
        \o EncodeUIntBE(Len(message.oddLotAskShortFormAttachment), 2)
        \o EncodeOddLotBidShortFormAttachmentList(message.oddLotBidShortFormAttachment)
        \o EncodeOddLotAskShortFormAttachmentList(message.oddLotAskShortFormAttachment)

DecodeExchangeOddLotQuoteMessageShortFormMessage(bytes) ==
    LET orig == ReadBytes(bytes, 2) IN IF ~orig.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(orig.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET feedSequence == ReadBytes(timestamp1.rest, 8) IN IF ~feedSequence.ok THEN Fail ELSE
    LET partToken == ReadBytes(feedSequence.rest, 8) IN IF ~partToken.ok THEN Fail ELSE
    LET symbolShort == ReadBytes(partToken.rest, 5) IN IF ~symbolShort.ok THEN Fail ELSE
    LET olBidLevelCount == ReadUIntBE(symbolShort.rest, 2) IN IF ~olBidLevelCount.ok THEN Fail ELSE
    LET olAskLevelCount == ReadUIntBE(olBidLevelCount.rest, 2) IN IF ~olAskLevelCount.ok THEN Fail ELSE
    LET oddLotBidShortFormAttachment == ReadOddLotBidShortFormAttachmentList(olAskLevelCount.rest, olBidLevelCount.value) IN IF ~oddLotBidShortFormAttachment.ok THEN Fail ELSE
    LET oddLotAskShortFormAttachment == ReadOddLotAskShortFormAttachmentList(oddLotBidShortFormAttachment.rest, olAskLevelCount.value) IN IF ~oddLotAskShortFormAttachment.ok THEN Fail ELSE
    Ok([ orig                         |-> orig.value,
         timestamp1                   |-> timestamp1.value,
         feedSequence                 |-> feedSequence.value,
         partToken                    |-> partToken.value,
         symbolShort                  |-> symbolShort.value,
         oddLotBidShortFormAttachment |-> oddLotBidShortFormAttachment.value,
         oddLotAskShortFormAttachment |-> oddLotAskShortFormAttachment.value ], oddLotAskShortFormAttachment.rest)

ZeroExchangeOddLotQuoteMessageShortFormMessage ==
    [ orig                         |-> [i \in 1 .. 2 |-> 0],
      timestamp1                   |-> [i \in 1 .. 8 |-> 0],
      feedSequence                 |-> [i \in 1 .. 8 |-> 0],
      partToken                    |-> [i \in 1 .. 8 |-> 0],
      symbolShort                  |-> [i \in 1 .. 5 |-> 0],
      oddLotBidShortFormAttachment |-> << >>,
      oddLotAskShortFormAttachment |-> << >> ]

(* Exchange Odd Lot Quote Message Short Form Message at zero, then each field in turn at the values it is checked at *)
CheckedExchangeOddLotQuoteMessageShortFormMessage ==
    { ZeroExchangeOddLotQuoteMessageShortFormMessage }
        \cup { [ZeroExchangeOddLotQuoteMessageShortFormMessage EXCEPT !.orig = one] : one \in Sample(2) }
        \cup { [ZeroExchangeOddLotQuoteMessageShortFormMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroExchangeOddLotQuoteMessageShortFormMessage EXCEPT !.feedSequence = one] : one \in Sample(8) }
        \cup { [ZeroExchangeOddLotQuoteMessageShortFormMessage EXCEPT !.partToken = one] : one \in Sample(8) }
        \cup { [ZeroExchangeOddLotQuoteMessageShortFormMessage EXCEPT !.symbolShort = one] : one \in Sample(5) }
        \cup { [ZeroExchangeOddLotQuoteMessageShortFormMessage EXCEPT !.oddLotBidShortFormAttachment = one] : one \in SampleLists(OneOddLotBidShortFormAttachment) }
        \cup { [ZeroExchangeOddLotQuoteMessageShortFormMessage EXCEPT !.oddLotAskShortFormAttachment = one] : one \in SampleLists(OneOddLotAskShortFormAttachment) }

(***************************************************************************)
(* Odd Lot Bid Long Form Attachment: 10 bytes                              *)
(***************************************************************************)

OddLotBidLongFormAttachment ==
    [ olPriceLong : Sample(8),
      olSize      : Sample(2) ]

EncodeOddLotBidLongFormAttachment(message) ==
    message.olPriceLong
        \o message.olSize

DecodeOddLotBidLongFormAttachment(bytes) ==
    LET olPriceLong == ReadBytes(bytes, 8) IN IF ~olPriceLong.ok THEN Fail ELSE
    LET olSize == ReadBytes(olPriceLong.rest, 2) IN IF ~olSize.ok THEN Fail ELSE
    Ok([ olPriceLong |-> olPriceLong.value,
         olSize      |-> olSize.value ], olSize.rest)

ZeroOddLotBidLongFormAttachment ==
    [ olPriceLong |-> [i \in 1 .. 8 |-> 0],
      olSize      |-> [i \in 1 .. 2 |-> 0] ]

(* Odd Lot Bid Long Form Attachment at zero, then each field in turn at the values it is checked at *)
CheckedOddLotBidLongFormAttachment ==
    { ZeroOddLotBidLongFormAttachment }
        \cup { [ZeroOddLotBidLongFormAttachment EXCEPT !.olPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroOddLotBidLongFormAttachment EXCEPT !.olSize = one] : one \in Sample(2) }

(* A run of Odd Lot Bid Long Form Attachment, written one after another *)
RECURSIVE EncodeOddLotBidLongFormAttachmentList(_)
EncodeOddLotBidLongFormAttachmentList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOddLotBidLongFormAttachment(Head(messages)) \o EncodeOddLotBidLongFormAttachmentList(Tail(messages))

(* As many Odd Lot Bid Long Form Attachment as the field that counts them says *)
RECURSIVE ReadOddLotBidLongFormAttachmentList(_, _)
ReadOddLotBidLongFormAttachmentList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOddLotBidLongFormAttachment(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOddLotBidLongFormAttachmentList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Odd Lot Bid Long Form Attachment of each kind, for the lists that carry them *)
OneOddLotBidLongFormAttachment == { ZeroOddLotBidLongFormAttachment }

(***************************************************************************)
(* Odd Lot Ask Long Form Attachment: 10 bytes                              *)
(***************************************************************************)

OddLotAskLongFormAttachment ==
    [ olPriceLong : Sample(8),
      olSize      : Sample(2) ]

EncodeOddLotAskLongFormAttachment(message) ==
    message.olPriceLong
        \o message.olSize

DecodeOddLotAskLongFormAttachment(bytes) ==
    LET olPriceLong == ReadBytes(bytes, 8) IN IF ~olPriceLong.ok THEN Fail ELSE
    LET olSize == ReadBytes(olPriceLong.rest, 2) IN IF ~olSize.ok THEN Fail ELSE
    Ok([ olPriceLong |-> olPriceLong.value,
         olSize      |-> olSize.value ], olSize.rest)

ZeroOddLotAskLongFormAttachment ==
    [ olPriceLong |-> [i \in 1 .. 8 |-> 0],
      olSize      |-> [i \in 1 .. 2 |-> 0] ]

(* Odd Lot Ask Long Form Attachment at zero, then each field in turn at the values it is checked at *)
CheckedOddLotAskLongFormAttachment ==
    { ZeroOddLotAskLongFormAttachment }
        \cup { [ZeroOddLotAskLongFormAttachment EXCEPT !.olPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroOddLotAskLongFormAttachment EXCEPT !.olSize = one] : one \in Sample(2) }

(* A run of Odd Lot Ask Long Form Attachment, written one after another *)
RECURSIVE EncodeOddLotAskLongFormAttachmentList(_)
EncodeOddLotAskLongFormAttachmentList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOddLotAskLongFormAttachment(Head(messages)) \o EncodeOddLotAskLongFormAttachmentList(Tail(messages))

(* As many Odd Lot Ask Long Form Attachment as the field that counts them says *)
RECURSIVE ReadOddLotAskLongFormAttachmentList(_, _)
ReadOddLotAskLongFormAttachmentList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOddLotAskLongFormAttachment(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOddLotAskLongFormAttachmentList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Odd Lot Ask Long Form Attachment of each kind, for the lists that carry them *)
OneOddLotAskLongFormAttachment == { ZeroOddLotAskLongFormAttachment }

(***************************************************************************)
(* Exchange Odd Lot Quote Message Long Form Message                        *)
(***************************************************************************)

ExchangeOddLotQuoteMessageLongFormMessage ==
    [ orig                        : Sample(2),
      timestamp1                  : Sample(8),
      feedSequence                : Sample(8),
      partToken                   : Sample(8),
      symbolLong                  : Sample(11),
      oddLotBidLongFormAttachment : SampleLists(OneOddLotBidLongFormAttachment),
      oddLotAskLongFormAttachment : SampleLists(OneOddLotAskLongFormAttachment) ]

EncodeExchangeOddLotQuoteMessageLongFormMessage(message) ==
    message.orig
        \o message.timestamp1
        \o message.feedSequence
        \o message.partToken
        \o message.symbolLong
        \o EncodeUIntBE(Len(message.oddLotBidLongFormAttachment), 2)
        \o EncodeUIntBE(Len(message.oddLotAskLongFormAttachment), 2)
        \o EncodeOddLotBidLongFormAttachmentList(message.oddLotBidLongFormAttachment)
        \o EncodeOddLotAskLongFormAttachmentList(message.oddLotAskLongFormAttachment)

DecodeExchangeOddLotQuoteMessageLongFormMessage(bytes) ==
    LET orig == ReadBytes(bytes, 2) IN IF ~orig.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(orig.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET feedSequence == ReadBytes(timestamp1.rest, 8) IN IF ~feedSequence.ok THEN Fail ELSE
    LET partToken == ReadBytes(feedSequence.rest, 8) IN IF ~partToken.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(partToken.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET olBidLevelCount == ReadUIntBE(symbolLong.rest, 2) IN IF ~olBidLevelCount.ok THEN Fail ELSE
    LET olAskLevelCount == ReadUIntBE(olBidLevelCount.rest, 2) IN IF ~olAskLevelCount.ok THEN Fail ELSE
    LET oddLotBidLongFormAttachment == ReadOddLotBidLongFormAttachmentList(olAskLevelCount.rest, olBidLevelCount.value) IN IF ~oddLotBidLongFormAttachment.ok THEN Fail ELSE
    LET oddLotAskLongFormAttachment == ReadOddLotAskLongFormAttachmentList(oddLotBidLongFormAttachment.rest, olAskLevelCount.value) IN IF ~oddLotAskLongFormAttachment.ok THEN Fail ELSE
    Ok([ orig                        |-> orig.value,
         timestamp1                  |-> timestamp1.value,
         feedSequence                |-> feedSequence.value,
         partToken                   |-> partToken.value,
         symbolLong                  |-> symbolLong.value,
         oddLotBidLongFormAttachment |-> oddLotBidLongFormAttachment.value,
         oddLotAskLongFormAttachment |-> oddLotAskLongFormAttachment.value ], oddLotAskLongFormAttachment.rest)

ZeroExchangeOddLotQuoteMessageLongFormMessage ==
    [ orig                        |-> [i \in 1 .. 2 |-> 0],
      timestamp1                  |-> [i \in 1 .. 8 |-> 0],
      feedSequence                |-> [i \in 1 .. 8 |-> 0],
      partToken                   |-> [i \in 1 .. 8 |-> 0],
      symbolLong                  |-> [i \in 1 .. 11 |-> 0],
      oddLotBidLongFormAttachment |-> << >>,
      oddLotAskLongFormAttachment |-> << >> ]

(* Exchange Odd Lot Quote Message Long Form Message at zero, then each field in turn at the values it is checked at *)
CheckedExchangeOddLotQuoteMessageLongFormMessage ==
    { ZeroExchangeOddLotQuoteMessageLongFormMessage }
        \cup { [ZeroExchangeOddLotQuoteMessageLongFormMessage EXCEPT !.orig = one] : one \in Sample(2) }
        \cup { [ZeroExchangeOddLotQuoteMessageLongFormMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroExchangeOddLotQuoteMessageLongFormMessage EXCEPT !.feedSequence = one] : one \in Sample(8) }
        \cup { [ZeroExchangeOddLotQuoteMessageLongFormMessage EXCEPT !.partToken = one] : one \in Sample(8) }
        \cup { [ZeroExchangeOddLotQuoteMessageLongFormMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroExchangeOddLotQuoteMessageLongFormMessage EXCEPT !.oddLotBidLongFormAttachment = one] : one \in SampleLists(OneOddLotBidLongFormAttachment) }
        \cup { [ZeroExchangeOddLotQuoteMessageLongFormMessage EXCEPT !.oddLotAskLongFormAttachment = one] : one \in SampleLists(OneOddLotAskLongFormAttachment) }

(***************************************************************************)
(* Odd Lot Bid Short Form Attachment: 4 bytes                              *)
(***************************************************************************)

OddLotBidShortFormAttachment2 ==
    [ olPriceShort : Sample(2),
      olSize       : Sample(2) ]

EncodeOddLotBidShortFormAttachment2(message) ==
    message.olPriceShort
        \o message.olSize

DecodeOddLotBidShortFormAttachment2(bytes) ==
    LET olPriceShort == ReadBytes(bytes, 2) IN IF ~olPriceShort.ok THEN Fail ELSE
    LET olSize == ReadBytes(olPriceShort.rest, 2) IN IF ~olSize.ok THEN Fail ELSE
    Ok([ olPriceShort |-> olPriceShort.value,
         olSize       |-> olSize.value ], olSize.rest)

ZeroOddLotBidShortFormAttachment2 ==
    [ olPriceShort |-> [i \in 1 .. 2 |-> 0],
      olSize       |-> [i \in 1 .. 2 |-> 0] ]

(* Odd Lot Bid Short Form Attachment at zero, then each field in turn at the values it is checked at *)
CheckedOddLotBidShortFormAttachment2 ==
    { ZeroOddLotBidShortFormAttachment2 }
        \cup { [ZeroOddLotBidShortFormAttachment2 EXCEPT !.olPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroOddLotBidShortFormAttachment2 EXCEPT !.olSize = one] : one \in Sample(2) }

(* A run of Odd Lot Bid Short Form Attachment, written one after another *)
RECURSIVE EncodeOddLotBidShortFormAttachment2List(_)
EncodeOddLotBidShortFormAttachment2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOddLotBidShortFormAttachment2(Head(messages)) \o EncodeOddLotBidShortFormAttachment2List(Tail(messages))

(* As many Odd Lot Bid Short Form Attachment as the field that counts them says *)
RECURSIVE ReadOddLotBidShortFormAttachment2List(_, _)
ReadOddLotBidShortFormAttachment2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOddLotBidShortFormAttachment2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOddLotBidShortFormAttachment2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Odd Lot Bid Short Form Attachment of each kind, for the lists that carry them *)
OneOddLotBidShortFormAttachment2 == { ZeroOddLotBidShortFormAttachment2 }

(***************************************************************************)
(* Odd Lot Ask Short Form Attachment: 4 bytes                              *)
(***************************************************************************)

OddLotAskShortFormAttachment2 ==
    [ olPriceShort : Sample(2),
      olSize       : Sample(2) ]

EncodeOddLotAskShortFormAttachment2(message) ==
    message.olPriceShort
        \o message.olSize

DecodeOddLotAskShortFormAttachment2(bytes) ==
    LET olPriceShort == ReadBytes(bytes, 2) IN IF ~olPriceShort.ok THEN Fail ELSE
    LET olSize == ReadBytes(olPriceShort.rest, 2) IN IF ~olSize.ok THEN Fail ELSE
    Ok([ olPriceShort |-> olPriceShort.value,
         olSize       |-> olSize.value ], olSize.rest)

ZeroOddLotAskShortFormAttachment2 ==
    [ olPriceShort |-> [i \in 1 .. 2 |-> 0],
      olSize       |-> [i \in 1 .. 2 |-> 0] ]

(* Odd Lot Ask Short Form Attachment at zero, then each field in turn at the values it is checked at *)
CheckedOddLotAskShortFormAttachment2 ==
    { ZeroOddLotAskShortFormAttachment2 }
        \cup { [ZeroOddLotAskShortFormAttachment2 EXCEPT !.olPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroOddLotAskShortFormAttachment2 EXCEPT !.olSize = one] : one \in Sample(2) }

(* A run of Odd Lot Ask Short Form Attachment, written one after another *)
RECURSIVE EncodeOddLotAskShortFormAttachment2List(_)
EncodeOddLotAskShortFormAttachment2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOddLotAskShortFormAttachment2(Head(messages)) \o EncodeOddLotAskShortFormAttachment2List(Tail(messages))

(* As many Odd Lot Ask Short Form Attachment as the field that counts them says *)
RECURSIVE ReadOddLotAskShortFormAttachment2List(_, _)
ReadOddLotAskShortFormAttachment2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOddLotAskShortFormAttachment2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOddLotAskShortFormAttachment2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Odd Lot Ask Short Form Attachment of each kind, for the lists that carry them *)
OneOddLotAskShortFormAttachment2 == { ZeroOddLotAskShortFormAttachment2 }

(***************************************************************************)
(* Exchange Combined Quote Message Short Form Message                      *)
(***************************************************************************)

ExchangeCombinedQuoteMessageShortFormMessage ==
    [ orig                         : Sample(2),
      timestamp1                   : Sample(8),
      feedSequence                 : Sample(8),
      partToken                    : Sample(8),
      symbolShort                  : Sample(5),
      bidShort                     : Sample(2),
      bidSizeShort                 : Sample(2),
      askShort                     : Sample(2),
      askSizeShort                 : Sample(2),
      cond                         : Sample(1),
      rii                          : Sample(1),
      oddLotBidShortFormAttachment : SampleLists(OneOddLotBidShortFormAttachment2),
      oddLotAskShortFormAttachment : SampleLists(OneOddLotAskShortFormAttachment2) ]

EncodeExchangeCombinedQuoteMessageShortFormMessage(message) ==
    message.orig
        \o message.timestamp1
        \o message.feedSequence
        \o message.partToken
        \o message.symbolShort
        \o message.bidShort
        \o message.bidSizeShort
        \o message.askShort
        \o message.askSizeShort
        \o message.cond
        \o message.rii
        \o EncodeUIntBE(Len(message.oddLotBidShortFormAttachment), 2)
        \o EncodeUIntBE(Len(message.oddLotAskShortFormAttachment), 2)
        \o EncodeOddLotBidShortFormAttachment2List(message.oddLotBidShortFormAttachment)
        \o EncodeOddLotAskShortFormAttachment2List(message.oddLotAskShortFormAttachment)

DecodeExchangeCombinedQuoteMessageShortFormMessage(bytes) ==
    LET orig == ReadBytes(bytes, 2) IN IF ~orig.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(orig.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET feedSequence == ReadBytes(timestamp1.rest, 8) IN IF ~feedSequence.ok THEN Fail ELSE
    LET partToken == ReadBytes(feedSequence.rest, 8) IN IF ~partToken.ok THEN Fail ELSE
    LET symbolShort == ReadBytes(partToken.rest, 5) IN IF ~symbolShort.ok THEN Fail ELSE
    LET bidShort == ReadBytes(symbolShort.rest, 2) IN IF ~bidShort.ok THEN Fail ELSE
    LET bidSizeShort == ReadBytes(bidShort.rest, 2) IN IF ~bidSizeShort.ok THEN Fail ELSE
    LET askShort == ReadBytes(bidSizeShort.rest, 2) IN IF ~askShort.ok THEN Fail ELSE
    LET askSizeShort == ReadBytes(askShort.rest, 2) IN IF ~askSizeShort.ok THEN Fail ELSE
    LET cond == ReadBytes(askSizeShort.rest, 1) IN IF ~cond.ok THEN Fail ELSE
    LET rii == ReadBytes(cond.rest, 1) IN IF ~rii.ok THEN Fail ELSE
    LET olBidLevelCount == ReadUIntBE(rii.rest, 2) IN IF ~olBidLevelCount.ok THEN Fail ELSE
    LET olAskLevelCount == ReadUIntBE(olBidLevelCount.rest, 2) IN IF ~olAskLevelCount.ok THEN Fail ELSE
    LET oddLotBidShortFormAttachment == ReadOddLotBidShortFormAttachment2List(olAskLevelCount.rest, olBidLevelCount.value) IN IF ~oddLotBidShortFormAttachment.ok THEN Fail ELSE
    LET oddLotAskShortFormAttachment == ReadOddLotAskShortFormAttachment2List(oddLotBidShortFormAttachment.rest, olAskLevelCount.value) IN IF ~oddLotAskShortFormAttachment.ok THEN Fail ELSE
    Ok([ orig                         |-> orig.value,
         timestamp1                   |-> timestamp1.value,
         feedSequence                 |-> feedSequence.value,
         partToken                    |-> partToken.value,
         symbolShort                  |-> symbolShort.value,
         bidShort                     |-> bidShort.value,
         bidSizeShort                 |-> bidSizeShort.value,
         askShort                     |-> askShort.value,
         askSizeShort                 |-> askSizeShort.value,
         cond                         |-> cond.value,
         rii                          |-> rii.value,
         oddLotBidShortFormAttachment |-> oddLotBidShortFormAttachment.value,
         oddLotAskShortFormAttachment |-> oddLotAskShortFormAttachment.value ], oddLotAskShortFormAttachment.rest)

ZeroExchangeCombinedQuoteMessageShortFormMessage ==
    [ orig                         |-> [i \in 1 .. 2 |-> 0],
      timestamp1                   |-> [i \in 1 .. 8 |-> 0],
      feedSequence                 |-> [i \in 1 .. 8 |-> 0],
      partToken                    |-> [i \in 1 .. 8 |-> 0],
      symbolShort                  |-> [i \in 1 .. 5 |-> 0],
      bidShort                     |-> [i \in 1 .. 2 |-> 0],
      bidSizeShort                 |-> [i \in 1 .. 2 |-> 0],
      askShort                     |-> [i \in 1 .. 2 |-> 0],
      askSizeShort                 |-> [i \in 1 .. 2 |-> 0],
      cond                         |-> [i \in 1 .. 1 |-> 0],
      rii                          |-> [i \in 1 .. 1 |-> 0],
      oddLotBidShortFormAttachment |-> << >>,
      oddLotAskShortFormAttachment |-> << >> ]

(* Exchange Combined Quote Message Short Form Message at zero, then each field in turn at the values it is checked at *)
CheckedExchangeCombinedQuoteMessageShortFormMessage ==
    { ZeroExchangeCombinedQuoteMessageShortFormMessage }
        \cup { [ZeroExchangeCombinedQuoteMessageShortFormMessage EXCEPT !.orig = one] : one \in Sample(2) }
        \cup { [ZeroExchangeCombinedQuoteMessageShortFormMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroExchangeCombinedQuoteMessageShortFormMessage EXCEPT !.feedSequence = one] : one \in Sample(8) }
        \cup { [ZeroExchangeCombinedQuoteMessageShortFormMessage EXCEPT !.partToken = one] : one \in Sample(8) }
        \cup { [ZeroExchangeCombinedQuoteMessageShortFormMessage EXCEPT !.symbolShort = one] : one \in Sample(5) }
        \cup { [ZeroExchangeCombinedQuoteMessageShortFormMessage EXCEPT !.bidShort = one] : one \in Sample(2) }
        \cup { [ZeroExchangeCombinedQuoteMessageShortFormMessage EXCEPT !.bidSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroExchangeCombinedQuoteMessageShortFormMessage EXCEPT !.askShort = one] : one \in Sample(2) }
        \cup { [ZeroExchangeCombinedQuoteMessageShortFormMessage EXCEPT !.askSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroExchangeCombinedQuoteMessageShortFormMessage EXCEPT !.cond = one] : one \in Sample(1) }
        \cup { [ZeroExchangeCombinedQuoteMessageShortFormMessage EXCEPT !.rii = one] : one \in Sample(1) }
        \cup { [ZeroExchangeCombinedQuoteMessageShortFormMessage EXCEPT !.oddLotBidShortFormAttachment = one] : one \in SampleLists(OneOddLotBidShortFormAttachment2) }
        \cup { [ZeroExchangeCombinedQuoteMessageShortFormMessage EXCEPT !.oddLotAskShortFormAttachment = one] : one \in SampleLists(OneOddLotAskShortFormAttachment2) }

(***************************************************************************)
(* Odd Lot Bid Long Form Attachment: 10 bytes                              *)
(***************************************************************************)

OddLotBidLongFormAttachment2 ==
    [ olPriceLong : Sample(8),
      olSize      : Sample(2) ]

EncodeOddLotBidLongFormAttachment2(message) ==
    message.olPriceLong
        \o message.olSize

DecodeOddLotBidLongFormAttachment2(bytes) ==
    LET olPriceLong == ReadBytes(bytes, 8) IN IF ~olPriceLong.ok THEN Fail ELSE
    LET olSize == ReadBytes(olPriceLong.rest, 2) IN IF ~olSize.ok THEN Fail ELSE
    Ok([ olPriceLong |-> olPriceLong.value,
         olSize      |-> olSize.value ], olSize.rest)

ZeroOddLotBidLongFormAttachment2 ==
    [ olPriceLong |-> [i \in 1 .. 8 |-> 0],
      olSize      |-> [i \in 1 .. 2 |-> 0] ]

(* Odd Lot Bid Long Form Attachment at zero, then each field in turn at the values it is checked at *)
CheckedOddLotBidLongFormAttachment2 ==
    { ZeroOddLotBidLongFormAttachment2 }
        \cup { [ZeroOddLotBidLongFormAttachment2 EXCEPT !.olPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroOddLotBidLongFormAttachment2 EXCEPT !.olSize = one] : one \in Sample(2) }

(* A run of Odd Lot Bid Long Form Attachment, written one after another *)
RECURSIVE EncodeOddLotBidLongFormAttachment2List(_)
EncodeOddLotBidLongFormAttachment2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOddLotBidLongFormAttachment2(Head(messages)) \o EncodeOddLotBidLongFormAttachment2List(Tail(messages))

(* As many Odd Lot Bid Long Form Attachment as the field that counts them says *)
RECURSIVE ReadOddLotBidLongFormAttachment2List(_, _)
ReadOddLotBidLongFormAttachment2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOddLotBidLongFormAttachment2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOddLotBidLongFormAttachment2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Odd Lot Bid Long Form Attachment of each kind, for the lists that carry them *)
OneOddLotBidLongFormAttachment2 == { ZeroOddLotBidLongFormAttachment2 }

(***************************************************************************)
(* Odd Lot Ask Long Form Attachment: 10 bytes                              *)
(***************************************************************************)

OddLotAskLongFormAttachment2 ==
    [ olPriceLong : Sample(8),
      olSize      : Sample(2) ]

EncodeOddLotAskLongFormAttachment2(message) ==
    message.olPriceLong
        \o message.olSize

DecodeOddLotAskLongFormAttachment2(bytes) ==
    LET olPriceLong == ReadBytes(bytes, 8) IN IF ~olPriceLong.ok THEN Fail ELSE
    LET olSize == ReadBytes(olPriceLong.rest, 2) IN IF ~olSize.ok THEN Fail ELSE
    Ok([ olPriceLong |-> olPriceLong.value,
         olSize      |-> olSize.value ], olSize.rest)

ZeroOddLotAskLongFormAttachment2 ==
    [ olPriceLong |-> [i \in 1 .. 8 |-> 0],
      olSize      |-> [i \in 1 .. 2 |-> 0] ]

(* Odd Lot Ask Long Form Attachment at zero, then each field in turn at the values it is checked at *)
CheckedOddLotAskLongFormAttachment2 ==
    { ZeroOddLotAskLongFormAttachment2 }
        \cup { [ZeroOddLotAskLongFormAttachment2 EXCEPT !.olPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroOddLotAskLongFormAttachment2 EXCEPT !.olSize = one] : one \in Sample(2) }

(* A run of Odd Lot Ask Long Form Attachment, written one after another *)
RECURSIVE EncodeOddLotAskLongFormAttachment2List(_)
EncodeOddLotAskLongFormAttachment2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOddLotAskLongFormAttachment2(Head(messages)) \o EncodeOddLotAskLongFormAttachment2List(Tail(messages))

(* As many Odd Lot Ask Long Form Attachment as the field that counts them says *)
RECURSIVE ReadOddLotAskLongFormAttachment2List(_, _)
ReadOddLotAskLongFormAttachment2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOddLotAskLongFormAttachment2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOddLotAskLongFormAttachment2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Odd Lot Ask Long Form Attachment of each kind, for the lists that carry them *)
OneOddLotAskLongFormAttachment2 == { ZeroOddLotAskLongFormAttachment2 }

(***************************************************************************)
(* Exchange Combined Quote Message Long Form Message                       *)
(***************************************************************************)

ExchangeCombinedQuoteMessageLongFormMessage ==
    [ orig                        : Sample(2),
      timestamp1                  : Sample(8),
      feedSequence                : Sample(8),
      partToken                   : Sample(8),
      symbolLong                  : Sample(11),
      bidLong                     : Sample(8),
      bidSizeLong                 : Sample(4),
      askLong                     : Sample(8),
      askSizeLong                 : Sample(4),
      cond                        : Sample(1),
      rii                         : Sample(1),
      oddLotBidLongFormAttachment : SampleLists(OneOddLotBidLongFormAttachment2),
      oddLotAskLongFormAttachment : SampleLists(OneOddLotAskLongFormAttachment2) ]

EncodeExchangeCombinedQuoteMessageLongFormMessage(message) ==
    message.orig
        \o message.timestamp1
        \o message.feedSequence
        \o message.partToken
        \o message.symbolLong
        \o message.bidLong
        \o message.bidSizeLong
        \o message.askLong
        \o message.askSizeLong
        \o message.cond
        \o message.rii
        \o EncodeUIntBE(Len(message.oddLotBidLongFormAttachment), 2)
        \o EncodeUIntBE(Len(message.oddLotAskLongFormAttachment), 2)
        \o EncodeOddLotBidLongFormAttachment2List(message.oddLotBidLongFormAttachment)
        \o EncodeOddLotAskLongFormAttachment2List(message.oddLotAskLongFormAttachment)

DecodeExchangeCombinedQuoteMessageLongFormMessage(bytes) ==
    LET orig == ReadBytes(bytes, 2) IN IF ~orig.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(orig.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET feedSequence == ReadBytes(timestamp1.rest, 8) IN IF ~feedSequence.ok THEN Fail ELSE
    LET partToken == ReadBytes(feedSequence.rest, 8) IN IF ~partToken.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(partToken.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET bidLong == ReadBytes(symbolLong.rest, 8) IN IF ~bidLong.ok THEN Fail ELSE
    LET bidSizeLong == ReadBytes(bidLong.rest, 4) IN IF ~bidSizeLong.ok THEN Fail ELSE
    LET askLong == ReadBytes(bidSizeLong.rest, 8) IN IF ~askLong.ok THEN Fail ELSE
    LET askSizeLong == ReadBytes(askLong.rest, 4) IN IF ~askSizeLong.ok THEN Fail ELSE
    LET cond == ReadBytes(askSizeLong.rest, 1) IN IF ~cond.ok THEN Fail ELSE
    LET rii == ReadBytes(cond.rest, 1) IN IF ~rii.ok THEN Fail ELSE
    LET olBidLevelCount == ReadUIntBE(rii.rest, 2) IN IF ~olBidLevelCount.ok THEN Fail ELSE
    LET olAskLevelCount == ReadUIntBE(olBidLevelCount.rest, 2) IN IF ~olAskLevelCount.ok THEN Fail ELSE
    LET oddLotBidLongFormAttachment == ReadOddLotBidLongFormAttachment2List(olAskLevelCount.rest, olBidLevelCount.value) IN IF ~oddLotBidLongFormAttachment.ok THEN Fail ELSE
    LET oddLotAskLongFormAttachment == ReadOddLotAskLongFormAttachment2List(oddLotBidLongFormAttachment.rest, olAskLevelCount.value) IN IF ~oddLotAskLongFormAttachment.ok THEN Fail ELSE
    Ok([ orig                        |-> orig.value,
         timestamp1                  |-> timestamp1.value,
         feedSequence                |-> feedSequence.value,
         partToken                   |-> partToken.value,
         symbolLong                  |-> symbolLong.value,
         bidLong                     |-> bidLong.value,
         bidSizeLong                 |-> bidSizeLong.value,
         askLong                     |-> askLong.value,
         askSizeLong                 |-> askSizeLong.value,
         cond                        |-> cond.value,
         rii                         |-> rii.value,
         oddLotBidLongFormAttachment |-> oddLotBidLongFormAttachment.value,
         oddLotAskLongFormAttachment |-> oddLotAskLongFormAttachment.value ], oddLotAskLongFormAttachment.rest)

ZeroExchangeCombinedQuoteMessageLongFormMessage ==
    [ orig                        |-> [i \in 1 .. 2 |-> 0],
      timestamp1                  |-> [i \in 1 .. 8 |-> 0],
      feedSequence                |-> [i \in 1 .. 8 |-> 0],
      partToken                   |-> [i \in 1 .. 8 |-> 0],
      symbolLong                  |-> [i \in 1 .. 11 |-> 0],
      bidLong                     |-> [i \in 1 .. 8 |-> 0],
      bidSizeLong                 |-> [i \in 1 .. 4 |-> 0],
      askLong                     |-> [i \in 1 .. 8 |-> 0],
      askSizeLong                 |-> [i \in 1 .. 4 |-> 0],
      cond                        |-> [i \in 1 .. 1 |-> 0],
      rii                         |-> [i \in 1 .. 1 |-> 0],
      oddLotBidLongFormAttachment |-> << >>,
      oddLotAskLongFormAttachment |-> << >> ]

(* Exchange Combined Quote Message Long Form Message at zero, then each field in turn at the values it is checked at *)
CheckedExchangeCombinedQuoteMessageLongFormMessage ==
    { ZeroExchangeCombinedQuoteMessageLongFormMessage }
        \cup { [ZeroExchangeCombinedQuoteMessageLongFormMessage EXCEPT !.orig = one] : one \in Sample(2) }
        \cup { [ZeroExchangeCombinedQuoteMessageLongFormMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroExchangeCombinedQuoteMessageLongFormMessage EXCEPT !.feedSequence = one] : one \in Sample(8) }
        \cup { [ZeroExchangeCombinedQuoteMessageLongFormMessage EXCEPT !.partToken = one] : one \in Sample(8) }
        \cup { [ZeroExchangeCombinedQuoteMessageLongFormMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroExchangeCombinedQuoteMessageLongFormMessage EXCEPT !.bidLong = one] : one \in Sample(8) }
        \cup { [ZeroExchangeCombinedQuoteMessageLongFormMessage EXCEPT !.bidSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroExchangeCombinedQuoteMessageLongFormMessage EXCEPT !.askLong = one] : one \in Sample(8) }
        \cup { [ZeroExchangeCombinedQuoteMessageLongFormMessage EXCEPT !.askSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroExchangeCombinedQuoteMessageLongFormMessage EXCEPT !.cond = one] : one \in Sample(1) }
        \cup { [ZeroExchangeCombinedQuoteMessageLongFormMessage EXCEPT !.rii = one] : one \in Sample(1) }
        \cup { [ZeroExchangeCombinedQuoteMessageLongFormMessage EXCEPT !.oddLotBidLongFormAttachment = one] : one \in SampleLists(OneOddLotBidLongFormAttachment2) }
        \cup { [ZeroExchangeCombinedQuoteMessageLongFormMessage EXCEPT !.oddLotAskLongFormAttachment = one] : one \in SampleLists(OneOddLotAskLongFormAttachment2) }

(***************************************************************************)
(* Finra Protected Quote Message With Bbo Info Message: 107 bytes          *)
(***************************************************************************)

FinraProtectedQuoteMessageWithBboInfoMessage ==
    [ orig         : Sample(2),
      timestamp1   : Sample(8),
      feedSequence : Sample(8),
      partToken    : Sample(8),
      timestamp2   : Sample(8),
      symbolLong   : Sample(11),
      bidLong      : Sample(8),
      bidSizeLong  : Sample(4),
      askLong      : Sample(8),
      askSizeLong  : Sample(4),
      cond         : Sample(1),
      mpid         : Sample(4),
      bboBid       : Sample(8),
      bboBidSize   : Sample(4),
      bboBidMpid   : Sample(4),
      bboAsk       : Sample(8),
      bboAskSize   : Sample(4),
      bboAskMpid   : Sample(4),
      bboCond      : Sample(1) ]

EncodeFinraProtectedQuoteMessageWithBboInfoMessage(message) ==
    message.orig
        \o message.timestamp1
        \o message.feedSequence
        \o message.partToken
        \o message.timestamp2
        \o message.symbolLong
        \o message.bidLong
        \o message.bidSizeLong
        \o message.askLong
        \o message.askSizeLong
        \o message.cond
        \o message.mpid
        \o message.bboBid
        \o message.bboBidSize
        \o message.bboBidMpid
        \o message.bboAsk
        \o message.bboAskSize
        \o message.bboAskMpid
        \o message.bboCond

DecodeFinraProtectedQuoteMessageWithBboInfoMessage(bytes) ==
    LET orig == ReadBytes(bytes, 2) IN IF ~orig.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(orig.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET feedSequence == ReadBytes(timestamp1.rest, 8) IN IF ~feedSequence.ok THEN Fail ELSE
    LET partToken == ReadBytes(feedSequence.rest, 8) IN IF ~partToken.ok THEN Fail ELSE
    LET timestamp2 == ReadBytes(partToken.rest, 8) IN IF ~timestamp2.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(timestamp2.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET bidLong == ReadBytes(symbolLong.rest, 8) IN IF ~bidLong.ok THEN Fail ELSE
    LET bidSizeLong == ReadBytes(bidLong.rest, 4) IN IF ~bidSizeLong.ok THEN Fail ELSE
    LET askLong == ReadBytes(bidSizeLong.rest, 8) IN IF ~askLong.ok THEN Fail ELSE
    LET askSizeLong == ReadBytes(askLong.rest, 4) IN IF ~askSizeLong.ok THEN Fail ELSE
    LET cond == ReadBytes(askSizeLong.rest, 1) IN IF ~cond.ok THEN Fail ELSE
    LET mpid == ReadBytes(cond.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET bboBid == ReadBytes(mpid.rest, 8) IN IF ~bboBid.ok THEN Fail ELSE
    LET bboBidSize == ReadBytes(bboBid.rest, 4) IN IF ~bboBidSize.ok THEN Fail ELSE
    LET bboBidMpid == ReadBytes(bboBidSize.rest, 4) IN IF ~bboBidMpid.ok THEN Fail ELSE
    LET bboAsk == ReadBytes(bboBidMpid.rest, 8) IN IF ~bboAsk.ok THEN Fail ELSE
    LET bboAskSize == ReadBytes(bboAsk.rest, 4) IN IF ~bboAskSize.ok THEN Fail ELSE
    LET bboAskMpid == ReadBytes(bboAskSize.rest, 4) IN IF ~bboAskMpid.ok THEN Fail ELSE
    LET bboCond == ReadBytes(bboAskMpid.rest, 1) IN IF ~bboCond.ok THEN Fail ELSE
    Ok([ orig         |-> orig.value,
         timestamp1   |-> timestamp1.value,
         feedSequence |-> feedSequence.value,
         partToken    |-> partToken.value,
         timestamp2   |-> timestamp2.value,
         symbolLong   |-> symbolLong.value,
         bidLong      |-> bidLong.value,
         bidSizeLong  |-> bidSizeLong.value,
         askLong      |-> askLong.value,
         askSizeLong  |-> askSizeLong.value,
         cond         |-> cond.value,
         mpid         |-> mpid.value,
         bboBid       |-> bboBid.value,
         bboBidSize   |-> bboBidSize.value,
         bboBidMpid   |-> bboBidMpid.value,
         bboAsk       |-> bboAsk.value,
         bboAskSize   |-> bboAskSize.value,
         bboAskMpid   |-> bboAskMpid.value,
         bboCond      |-> bboCond.value ], bboCond.rest)

ZeroFinraProtectedQuoteMessageWithBboInfoMessage ==
    [ orig         |-> [i \in 1 .. 2 |-> 0],
      timestamp1   |-> [i \in 1 .. 8 |-> 0],
      feedSequence |-> [i \in 1 .. 8 |-> 0],
      partToken    |-> [i \in 1 .. 8 |-> 0],
      timestamp2   |-> [i \in 1 .. 8 |-> 0],
      symbolLong   |-> [i \in 1 .. 11 |-> 0],
      bidLong      |-> [i \in 1 .. 8 |-> 0],
      bidSizeLong  |-> [i \in 1 .. 4 |-> 0],
      askLong      |-> [i \in 1 .. 8 |-> 0],
      askSizeLong  |-> [i \in 1 .. 4 |-> 0],
      cond         |-> [i \in 1 .. 1 |-> 0],
      mpid         |-> [i \in 1 .. 4 |-> 0],
      bboBid       |-> [i \in 1 .. 8 |-> 0],
      bboBidSize   |-> [i \in 1 .. 4 |-> 0],
      bboBidMpid   |-> [i \in 1 .. 4 |-> 0],
      bboAsk       |-> [i \in 1 .. 8 |-> 0],
      bboAskSize   |-> [i \in 1 .. 4 |-> 0],
      bboAskMpid   |-> [i \in 1 .. 4 |-> 0],
      bboCond      |-> [i \in 1 .. 1 |-> 0] ]

(* Finra Protected Quote Message With Bbo Info Message at zero, then each field in turn at the values it is checked at *)
CheckedFinraProtectedQuoteMessageWithBboInfoMessage ==
    { ZeroFinraProtectedQuoteMessageWithBboInfoMessage }
        \cup { [ZeroFinraProtectedQuoteMessageWithBboInfoMessage EXCEPT !.orig = one] : one \in Sample(2) }
        \cup { [ZeroFinraProtectedQuoteMessageWithBboInfoMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroFinraProtectedQuoteMessageWithBboInfoMessage EXCEPT !.feedSequence = one] : one \in Sample(8) }
        \cup { [ZeroFinraProtectedQuoteMessageWithBboInfoMessage EXCEPT !.partToken = one] : one \in Sample(8) }
        \cup { [ZeroFinraProtectedQuoteMessageWithBboInfoMessage EXCEPT !.timestamp2 = one] : one \in Sample(8) }
        \cup { [ZeroFinraProtectedQuoteMessageWithBboInfoMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroFinraProtectedQuoteMessageWithBboInfoMessage EXCEPT !.bidLong = one] : one \in Sample(8) }
        \cup { [ZeroFinraProtectedQuoteMessageWithBboInfoMessage EXCEPT !.bidSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroFinraProtectedQuoteMessageWithBboInfoMessage EXCEPT !.askLong = one] : one \in Sample(8) }
        \cup { [ZeroFinraProtectedQuoteMessageWithBboInfoMessage EXCEPT !.askSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroFinraProtectedQuoteMessageWithBboInfoMessage EXCEPT !.cond = one] : one \in Sample(1) }
        \cup { [ZeroFinraProtectedQuoteMessageWithBboInfoMessage EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroFinraProtectedQuoteMessageWithBboInfoMessage EXCEPT !.bboBid = one] : one \in Sample(8) }
        \cup { [ZeroFinraProtectedQuoteMessageWithBboInfoMessage EXCEPT !.bboBidSize = one] : one \in Sample(4) }
        \cup { [ZeroFinraProtectedQuoteMessageWithBboInfoMessage EXCEPT !.bboBidMpid = one] : one \in Sample(4) }
        \cup { [ZeroFinraProtectedQuoteMessageWithBboInfoMessage EXCEPT !.bboAsk = one] : one \in Sample(8) }
        \cup { [ZeroFinraProtectedQuoteMessageWithBboInfoMessage EXCEPT !.bboAskSize = one] : one \in Sample(4) }
        \cup { [ZeroFinraProtectedQuoteMessageWithBboInfoMessage EXCEPT !.bboAskMpid = one] : one \in Sample(4) }
        \cup { [ZeroFinraProtectedQuoteMessageWithBboInfoMessage EXCEPT !.bboCond = one] : one \in Sample(1) }

(***************************************************************************)
(* Finra Protected Quote Message Without Bbo Info Message: 75 bytes        *)
(***************************************************************************)

FinraProtectedQuoteMessageWithoutBboInfoMessage ==
    [ orig         : Sample(2),
      timestamp1   : Sample(8),
      feedSequence : Sample(8),
      partToken    : Sample(8),
      timestamp2   : Sample(8),
      symbolLong   : Sample(11),
      bidLong      : Sample(8),
      bidSizeLong  : Sample(4),
      askLong      : Sample(8),
      askSizeLong  : Sample(4),
      cond         : Sample(1),
      mpid         : Sample(4),
      bboIndicator : Sample(1) ]

EncodeFinraProtectedQuoteMessageWithoutBboInfoMessage(message) ==
    message.orig
        \o message.timestamp1
        \o message.feedSequence
        \o message.partToken
        \o message.timestamp2
        \o message.symbolLong
        \o message.bidLong
        \o message.bidSizeLong
        \o message.askLong
        \o message.askSizeLong
        \o message.cond
        \o message.mpid
        \o message.bboIndicator

DecodeFinraProtectedQuoteMessageWithoutBboInfoMessage(bytes) ==
    LET orig == ReadBytes(bytes, 2) IN IF ~orig.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(orig.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET feedSequence == ReadBytes(timestamp1.rest, 8) IN IF ~feedSequence.ok THEN Fail ELSE
    LET partToken == ReadBytes(feedSequence.rest, 8) IN IF ~partToken.ok THEN Fail ELSE
    LET timestamp2 == ReadBytes(partToken.rest, 8) IN IF ~timestamp2.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(timestamp2.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET bidLong == ReadBytes(symbolLong.rest, 8) IN IF ~bidLong.ok THEN Fail ELSE
    LET bidSizeLong == ReadBytes(bidLong.rest, 4) IN IF ~bidSizeLong.ok THEN Fail ELSE
    LET askLong == ReadBytes(bidSizeLong.rest, 8) IN IF ~askLong.ok THEN Fail ELSE
    LET askSizeLong == ReadBytes(askLong.rest, 4) IN IF ~askSizeLong.ok THEN Fail ELSE
    LET cond == ReadBytes(askSizeLong.rest, 1) IN IF ~cond.ok THEN Fail ELSE
    LET mpid == ReadBytes(cond.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET bboIndicator == ReadBytes(mpid.rest, 1) IN IF ~bboIndicator.ok THEN Fail ELSE
    Ok([ orig         |-> orig.value,
         timestamp1   |-> timestamp1.value,
         feedSequence |-> feedSequence.value,
         partToken    |-> partToken.value,
         timestamp2   |-> timestamp2.value,
         symbolLong   |-> symbolLong.value,
         bidLong      |-> bidLong.value,
         bidSizeLong  |-> bidSizeLong.value,
         askLong      |-> askLong.value,
         askSizeLong  |-> askSizeLong.value,
         cond         |-> cond.value,
         mpid         |-> mpid.value,
         bboIndicator |-> bboIndicator.value ], bboIndicator.rest)

ZeroFinraProtectedQuoteMessageWithoutBboInfoMessage ==
    [ orig         |-> [i \in 1 .. 2 |-> 0],
      timestamp1   |-> [i \in 1 .. 8 |-> 0],
      feedSequence |-> [i \in 1 .. 8 |-> 0],
      partToken    |-> [i \in 1 .. 8 |-> 0],
      timestamp2   |-> [i \in 1 .. 8 |-> 0],
      symbolLong   |-> [i \in 1 .. 11 |-> 0],
      bidLong      |-> [i \in 1 .. 8 |-> 0],
      bidSizeLong  |-> [i \in 1 .. 4 |-> 0],
      askLong      |-> [i \in 1 .. 8 |-> 0],
      askSizeLong  |-> [i \in 1 .. 4 |-> 0],
      cond         |-> [i \in 1 .. 1 |-> 0],
      mpid         |-> [i \in 1 .. 4 |-> 0],
      bboIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Finra Protected Quote Message Without Bbo Info Message at zero, then each field in turn at the values it is checked at *)
CheckedFinraProtectedQuoteMessageWithoutBboInfoMessage ==
    { ZeroFinraProtectedQuoteMessageWithoutBboInfoMessage }
        \cup { [ZeroFinraProtectedQuoteMessageWithoutBboInfoMessage EXCEPT !.orig = one] : one \in Sample(2) }
        \cup { [ZeroFinraProtectedQuoteMessageWithoutBboInfoMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroFinraProtectedQuoteMessageWithoutBboInfoMessage EXCEPT !.feedSequence = one] : one \in Sample(8) }
        \cup { [ZeroFinraProtectedQuoteMessageWithoutBboInfoMessage EXCEPT !.partToken = one] : one \in Sample(8) }
        \cup { [ZeroFinraProtectedQuoteMessageWithoutBboInfoMessage EXCEPT !.timestamp2 = one] : one \in Sample(8) }
        \cup { [ZeroFinraProtectedQuoteMessageWithoutBboInfoMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroFinraProtectedQuoteMessageWithoutBboInfoMessage EXCEPT !.bidLong = one] : one \in Sample(8) }
        \cup { [ZeroFinraProtectedQuoteMessageWithoutBboInfoMessage EXCEPT !.bidSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroFinraProtectedQuoteMessageWithoutBboInfoMessage EXCEPT !.askLong = one] : one \in Sample(8) }
        \cup { [ZeroFinraProtectedQuoteMessageWithoutBboInfoMessage EXCEPT !.askSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroFinraProtectedQuoteMessageWithoutBboInfoMessage EXCEPT !.cond = one] : one \in Sample(1) }
        \cup { [ZeroFinraProtectedQuoteMessageWithoutBboInfoMessage EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroFinraProtectedQuoteMessageWithoutBboInfoMessage EXCEPT !.bboIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Odd Lot Bid Adf Form Attachment: 14 bytes                               *)
(***************************************************************************)

OddLotBidAdfFormAttachment ==
    [ olPriceLong : Sample(8),
      olSize      : Sample(2),
      mpid        : Sample(4) ]

EncodeOddLotBidAdfFormAttachment(message) ==
    message.olPriceLong
        \o message.olSize
        \o message.mpid

DecodeOddLotBidAdfFormAttachment(bytes) ==
    LET olPriceLong == ReadBytes(bytes, 8) IN IF ~olPriceLong.ok THEN Fail ELSE
    LET olSize == ReadBytes(olPriceLong.rest, 2) IN IF ~olSize.ok THEN Fail ELSE
    LET mpid == ReadBytes(olSize.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    Ok([ olPriceLong |-> olPriceLong.value,
         olSize      |-> olSize.value,
         mpid        |-> mpid.value ], mpid.rest)

ZeroOddLotBidAdfFormAttachment ==
    [ olPriceLong |-> [i \in 1 .. 8 |-> 0],
      olSize      |-> [i \in 1 .. 2 |-> 0],
      mpid        |-> [i \in 1 .. 4 |-> 0] ]

(* Odd Lot Bid Adf Form Attachment at zero, then each field in turn at the values it is checked at *)
CheckedOddLotBidAdfFormAttachment ==
    { ZeroOddLotBidAdfFormAttachment }
        \cup { [ZeroOddLotBidAdfFormAttachment EXCEPT !.olPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroOddLotBidAdfFormAttachment EXCEPT !.olSize = one] : one \in Sample(2) }
        \cup { [ZeroOddLotBidAdfFormAttachment EXCEPT !.mpid = one] : one \in Sample(4) }

(* A run of Odd Lot Bid Adf Form Attachment, written one after another *)
RECURSIVE EncodeOddLotBidAdfFormAttachmentList(_)
EncodeOddLotBidAdfFormAttachmentList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOddLotBidAdfFormAttachment(Head(messages)) \o EncodeOddLotBidAdfFormAttachmentList(Tail(messages))

(* As many Odd Lot Bid Adf Form Attachment as the field that counts them says *)
RECURSIVE ReadOddLotBidAdfFormAttachmentList(_, _)
ReadOddLotBidAdfFormAttachmentList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOddLotBidAdfFormAttachment(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOddLotBidAdfFormAttachmentList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Odd Lot Bid Adf Form Attachment of each kind, for the lists that carry them *)
OneOddLotBidAdfFormAttachment == { ZeroOddLotBidAdfFormAttachment }

(***************************************************************************)
(* Odd Lot Ask Adf Form Attachment: 14 bytes                               *)
(***************************************************************************)

OddLotAskAdfFormAttachment ==
    [ olPriceLong : Sample(8),
      olSize      : Sample(2),
      mpid        : Sample(4) ]

EncodeOddLotAskAdfFormAttachment(message) ==
    message.olPriceLong
        \o message.olSize
        \o message.mpid

DecodeOddLotAskAdfFormAttachment(bytes) ==
    LET olPriceLong == ReadBytes(bytes, 8) IN IF ~olPriceLong.ok THEN Fail ELSE
    LET olSize == ReadBytes(olPriceLong.rest, 2) IN IF ~olSize.ok THEN Fail ELSE
    LET mpid == ReadBytes(olSize.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    Ok([ olPriceLong |-> olPriceLong.value,
         olSize      |-> olSize.value,
         mpid        |-> mpid.value ], mpid.rest)

ZeroOddLotAskAdfFormAttachment ==
    [ olPriceLong |-> [i \in 1 .. 8 |-> 0],
      olSize      |-> [i \in 1 .. 2 |-> 0],
      mpid        |-> [i \in 1 .. 4 |-> 0] ]

(* Odd Lot Ask Adf Form Attachment at zero, then each field in turn at the values it is checked at *)
CheckedOddLotAskAdfFormAttachment ==
    { ZeroOddLotAskAdfFormAttachment }
        \cup { [ZeroOddLotAskAdfFormAttachment EXCEPT !.olPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroOddLotAskAdfFormAttachment EXCEPT !.olSize = one] : one \in Sample(2) }
        \cup { [ZeroOddLotAskAdfFormAttachment EXCEPT !.mpid = one] : one \in Sample(4) }

(* A run of Odd Lot Ask Adf Form Attachment, written one after another *)
RECURSIVE EncodeOddLotAskAdfFormAttachmentList(_)
EncodeOddLotAskAdfFormAttachmentList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOddLotAskAdfFormAttachment(Head(messages)) \o EncodeOddLotAskAdfFormAttachmentList(Tail(messages))

(* As many Odd Lot Ask Adf Form Attachment as the field that counts them says *)
RECURSIVE ReadOddLotAskAdfFormAttachmentList(_, _)
ReadOddLotAskAdfFormAttachmentList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOddLotAskAdfFormAttachment(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOddLotAskAdfFormAttachmentList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Odd Lot Ask Adf Form Attachment of each kind, for the lists that carry them *)
OneOddLotAskAdfFormAttachment == { ZeroOddLotAskAdfFormAttachment }

(***************************************************************************)
(* Finra Adf Odd Lot Quotation Message                                     *)
(***************************************************************************)

FinraAdfOddLotQuotationMessage ==
    [ orig                       : Sample(2),
      timestamp1                 : Sample(8),
      feedSequence               : Sample(8),
      partToken                  : Sample(8),
      timestamp2                 : Sample(8),
      symbolLong                 : Sample(11),
      oddLotBidAdfFormAttachment : SampleLists(OneOddLotBidAdfFormAttachment),
      oddLotAskAdfFormAttachment : SampleLists(OneOddLotAskAdfFormAttachment) ]

EncodeFinraAdfOddLotQuotationMessage(message) ==
    message.orig
        \o message.timestamp1
        \o message.feedSequence
        \o message.partToken
        \o message.timestamp2
        \o message.symbolLong
        \o EncodeUIntBE(Len(message.oddLotBidAdfFormAttachment), 2)
        \o EncodeUIntBE(Len(message.oddLotAskAdfFormAttachment), 2)
        \o EncodeOddLotBidAdfFormAttachmentList(message.oddLotBidAdfFormAttachment)
        \o EncodeOddLotAskAdfFormAttachmentList(message.oddLotAskAdfFormAttachment)

DecodeFinraAdfOddLotQuotationMessage(bytes) ==
    LET orig == ReadBytes(bytes, 2) IN IF ~orig.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(orig.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET feedSequence == ReadBytes(timestamp1.rest, 8) IN IF ~feedSequence.ok THEN Fail ELSE
    LET partToken == ReadBytes(feedSequence.rest, 8) IN IF ~partToken.ok THEN Fail ELSE
    LET timestamp2 == ReadBytes(partToken.rest, 8) IN IF ~timestamp2.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(timestamp2.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET olBidLevelCount == ReadUIntBE(symbolLong.rest, 2) IN IF ~olBidLevelCount.ok THEN Fail ELSE
    LET olAskLevelCount == ReadUIntBE(olBidLevelCount.rest, 2) IN IF ~olAskLevelCount.ok THEN Fail ELSE
    LET oddLotBidAdfFormAttachment == ReadOddLotBidAdfFormAttachmentList(olAskLevelCount.rest, olBidLevelCount.value) IN IF ~oddLotBidAdfFormAttachment.ok THEN Fail ELSE
    LET oddLotAskAdfFormAttachment == ReadOddLotAskAdfFormAttachmentList(oddLotBidAdfFormAttachment.rest, olAskLevelCount.value) IN IF ~oddLotAskAdfFormAttachment.ok THEN Fail ELSE
    Ok([ orig                       |-> orig.value,
         timestamp1                 |-> timestamp1.value,
         feedSequence               |-> feedSequence.value,
         partToken                  |-> partToken.value,
         timestamp2                 |-> timestamp2.value,
         symbolLong                 |-> symbolLong.value,
         oddLotBidAdfFormAttachment |-> oddLotBidAdfFormAttachment.value,
         oddLotAskAdfFormAttachment |-> oddLotAskAdfFormAttachment.value ], oddLotAskAdfFormAttachment.rest)

ZeroFinraAdfOddLotQuotationMessage ==
    [ orig                       |-> [i \in 1 .. 2 |-> 0],
      timestamp1                 |-> [i \in 1 .. 8 |-> 0],
      feedSequence               |-> [i \in 1 .. 8 |-> 0],
      partToken                  |-> [i \in 1 .. 8 |-> 0],
      timestamp2                 |-> [i \in 1 .. 8 |-> 0],
      symbolLong                 |-> [i \in 1 .. 11 |-> 0],
      oddLotBidAdfFormAttachment |-> << >>,
      oddLotAskAdfFormAttachment |-> << >> ]

(* Finra Adf Odd Lot Quotation Message at zero, then each field in turn at the values it is checked at *)
CheckedFinraAdfOddLotQuotationMessage ==
    { ZeroFinraAdfOddLotQuotationMessage }
        \cup { [ZeroFinraAdfOddLotQuotationMessage EXCEPT !.orig = one] : one \in Sample(2) }
        \cup { [ZeroFinraAdfOddLotQuotationMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroFinraAdfOddLotQuotationMessage EXCEPT !.feedSequence = one] : one \in Sample(8) }
        \cup { [ZeroFinraAdfOddLotQuotationMessage EXCEPT !.partToken = one] : one \in Sample(8) }
        \cup { [ZeroFinraAdfOddLotQuotationMessage EXCEPT !.timestamp2 = one] : one \in Sample(8) }
        \cup { [ZeroFinraAdfOddLotQuotationMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroFinraAdfOddLotQuotationMessage EXCEPT !.oddLotBidAdfFormAttachment = one] : one \in SampleLists(OneOddLotBidAdfFormAttachment) }
        \cup { [ZeroFinraAdfOddLotQuotationMessage EXCEPT !.oddLotAskAdfFormAttachment = one] : one \in SampleLists(OneOddLotAskAdfFormAttachment) }

(***************************************************************************)
(* Odd Lot Bid Adf Form Attachment: 14 bytes                               *)
(***************************************************************************)

OddLotBidAdfFormAttachment2 ==
    [ olPriceLong : Sample(8),
      olSize      : Sample(2),
      mpid        : Sample(4) ]

EncodeOddLotBidAdfFormAttachment2(message) ==
    message.olPriceLong
        \o message.olSize
        \o message.mpid

DecodeOddLotBidAdfFormAttachment2(bytes) ==
    LET olPriceLong == ReadBytes(bytes, 8) IN IF ~olPriceLong.ok THEN Fail ELSE
    LET olSize == ReadBytes(olPriceLong.rest, 2) IN IF ~olSize.ok THEN Fail ELSE
    LET mpid == ReadBytes(olSize.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    Ok([ olPriceLong |-> olPriceLong.value,
         olSize      |-> olSize.value,
         mpid        |-> mpid.value ], mpid.rest)

ZeroOddLotBidAdfFormAttachment2 ==
    [ olPriceLong |-> [i \in 1 .. 8 |-> 0],
      olSize      |-> [i \in 1 .. 2 |-> 0],
      mpid        |-> [i \in 1 .. 4 |-> 0] ]

(* Odd Lot Bid Adf Form Attachment at zero, then each field in turn at the values it is checked at *)
CheckedOddLotBidAdfFormAttachment2 ==
    { ZeroOddLotBidAdfFormAttachment2 }
        \cup { [ZeroOddLotBidAdfFormAttachment2 EXCEPT !.olPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroOddLotBidAdfFormAttachment2 EXCEPT !.olSize = one] : one \in Sample(2) }
        \cup { [ZeroOddLotBidAdfFormAttachment2 EXCEPT !.mpid = one] : one \in Sample(4) }

(* A run of Odd Lot Bid Adf Form Attachment, written one after another *)
RECURSIVE EncodeOddLotBidAdfFormAttachment2List(_)
EncodeOddLotBidAdfFormAttachment2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOddLotBidAdfFormAttachment2(Head(messages)) \o EncodeOddLotBidAdfFormAttachment2List(Tail(messages))

(* As many Odd Lot Bid Adf Form Attachment as the field that counts them says *)
RECURSIVE ReadOddLotBidAdfFormAttachment2List(_, _)
ReadOddLotBidAdfFormAttachment2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOddLotBidAdfFormAttachment2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOddLotBidAdfFormAttachment2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Odd Lot Bid Adf Form Attachment of each kind, for the lists that carry them *)
OneOddLotBidAdfFormAttachment2 == { ZeroOddLotBidAdfFormAttachment2 }

(***************************************************************************)
(* Odd Lot Ask Adf Form Attachment: 14 bytes                               *)
(***************************************************************************)

OddLotAskAdfFormAttachment2 ==
    [ olPriceLong : Sample(8),
      olSize      : Sample(2),
      mpid        : Sample(4) ]

EncodeOddLotAskAdfFormAttachment2(message) ==
    message.olPriceLong
        \o message.olSize
        \o message.mpid

DecodeOddLotAskAdfFormAttachment2(bytes) ==
    LET olPriceLong == ReadBytes(bytes, 8) IN IF ~olPriceLong.ok THEN Fail ELSE
    LET olSize == ReadBytes(olPriceLong.rest, 2) IN IF ~olSize.ok THEN Fail ELSE
    LET mpid == ReadBytes(olSize.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    Ok([ olPriceLong |-> olPriceLong.value,
         olSize      |-> olSize.value,
         mpid        |-> mpid.value ], mpid.rest)

ZeroOddLotAskAdfFormAttachment2 ==
    [ olPriceLong |-> [i \in 1 .. 8 |-> 0],
      olSize      |-> [i \in 1 .. 2 |-> 0],
      mpid        |-> [i \in 1 .. 4 |-> 0] ]

(* Odd Lot Ask Adf Form Attachment at zero, then each field in turn at the values it is checked at *)
CheckedOddLotAskAdfFormAttachment2 ==
    { ZeroOddLotAskAdfFormAttachment2 }
        \cup { [ZeroOddLotAskAdfFormAttachment2 EXCEPT !.olPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroOddLotAskAdfFormAttachment2 EXCEPT !.olSize = one] : one \in Sample(2) }
        \cup { [ZeroOddLotAskAdfFormAttachment2 EXCEPT !.mpid = one] : one \in Sample(4) }

(* A run of Odd Lot Ask Adf Form Attachment, written one after another *)
RECURSIVE EncodeOddLotAskAdfFormAttachment2List(_)
EncodeOddLotAskAdfFormAttachment2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOddLotAskAdfFormAttachment2(Head(messages)) \o EncodeOddLotAskAdfFormAttachment2List(Tail(messages))

(* As many Odd Lot Ask Adf Form Attachment as the field that counts them says *)
RECURSIVE ReadOddLotAskAdfFormAttachment2List(_, _)
ReadOddLotAskAdfFormAttachment2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOddLotAskAdfFormAttachment2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOddLotAskAdfFormAttachment2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Odd Lot Ask Adf Form Attachment of each kind, for the lists that carry them *)
OneOddLotAskAdfFormAttachment2 == { ZeroOddLotAskAdfFormAttachment2 }

(***************************************************************************)
(* Finra Adf Combined Quote Message With Bbo                               *)
(***************************************************************************)

FinraAdfCombinedQuoteMessageWithBbo ==
    [ orig                       : Sample(2),
      timestamp1                 : Sample(8),
      feedSequence               : Sample(8),
      partToken                  : Sample(8),
      timestamp2                 : Sample(8),
      symbolLong                 : Sample(11),
      bidLong                    : Sample(8),
      bidSizeLong                : Sample(4),
      askLong                    : Sample(8),
      askSizeLong                : Sample(4),
      cond                       : Sample(1),
      mpid                       : Sample(4),
      rii                        : Sample(1),
      bboBidPrice                : Sample(8),
      bboBidSize                 : Sample(4),
      bboBidMpid                 : Sample(4),
      bboAskPrice                : Sample(8),
      bboAskSize                 : Sample(4),
      bboAskMpid                 : Sample(4),
      bboCond                    : Sample(1),
      oddLotBidAdfFormAttachment : SampleLists(OneOddLotBidAdfFormAttachment2),
      oddLotAskAdfFormAttachment : SampleLists(OneOddLotAskAdfFormAttachment2) ]

EncodeFinraAdfCombinedQuoteMessageWithBbo(message) ==
    message.orig
        \o message.timestamp1
        \o message.feedSequence
        \o message.partToken
        \o message.timestamp2
        \o message.symbolLong
        \o message.bidLong
        \o message.bidSizeLong
        \o message.askLong
        \o message.askSizeLong
        \o message.cond
        \o message.mpid
        \o message.rii
        \o message.bboBidPrice
        \o message.bboBidSize
        \o message.bboBidMpid
        \o message.bboAskPrice
        \o message.bboAskSize
        \o message.bboAskMpid
        \o message.bboCond
        \o EncodeUIntBE(Len(message.oddLotBidAdfFormAttachment), 2)
        \o EncodeUIntBE(Len(message.oddLotAskAdfFormAttachment), 2)
        \o EncodeOddLotBidAdfFormAttachment2List(message.oddLotBidAdfFormAttachment)
        \o EncodeOddLotAskAdfFormAttachment2List(message.oddLotAskAdfFormAttachment)

DecodeFinraAdfCombinedQuoteMessageWithBbo(bytes) ==
    LET orig == ReadBytes(bytes, 2) IN IF ~orig.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(orig.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET feedSequence == ReadBytes(timestamp1.rest, 8) IN IF ~feedSequence.ok THEN Fail ELSE
    LET partToken == ReadBytes(feedSequence.rest, 8) IN IF ~partToken.ok THEN Fail ELSE
    LET timestamp2 == ReadBytes(partToken.rest, 8) IN IF ~timestamp2.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(timestamp2.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET bidLong == ReadBytes(symbolLong.rest, 8) IN IF ~bidLong.ok THEN Fail ELSE
    LET bidSizeLong == ReadBytes(bidLong.rest, 4) IN IF ~bidSizeLong.ok THEN Fail ELSE
    LET askLong == ReadBytes(bidSizeLong.rest, 8) IN IF ~askLong.ok THEN Fail ELSE
    LET askSizeLong == ReadBytes(askLong.rest, 4) IN IF ~askSizeLong.ok THEN Fail ELSE
    LET cond == ReadBytes(askSizeLong.rest, 1) IN IF ~cond.ok THEN Fail ELSE
    LET mpid == ReadBytes(cond.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET rii == ReadBytes(mpid.rest, 1) IN IF ~rii.ok THEN Fail ELSE
    LET bboBidPrice == ReadBytes(rii.rest, 8) IN IF ~bboBidPrice.ok THEN Fail ELSE
    LET bboBidSize == ReadBytes(bboBidPrice.rest, 4) IN IF ~bboBidSize.ok THEN Fail ELSE
    LET bboBidMpid == ReadBytes(bboBidSize.rest, 4) IN IF ~bboBidMpid.ok THEN Fail ELSE
    LET bboAskPrice == ReadBytes(bboBidMpid.rest, 8) IN IF ~bboAskPrice.ok THEN Fail ELSE
    LET bboAskSize == ReadBytes(bboAskPrice.rest, 4) IN IF ~bboAskSize.ok THEN Fail ELSE
    LET bboAskMpid == ReadBytes(bboAskSize.rest, 4) IN IF ~bboAskMpid.ok THEN Fail ELSE
    LET bboCond == ReadBytes(bboAskMpid.rest, 1) IN IF ~bboCond.ok THEN Fail ELSE
    LET olBidLevelCount == ReadUIntBE(bboCond.rest, 2) IN IF ~olBidLevelCount.ok THEN Fail ELSE
    LET olAskLevelCount == ReadUIntBE(olBidLevelCount.rest, 2) IN IF ~olAskLevelCount.ok THEN Fail ELSE
    LET oddLotBidAdfFormAttachment == ReadOddLotBidAdfFormAttachment2List(olAskLevelCount.rest, olBidLevelCount.value) IN IF ~oddLotBidAdfFormAttachment.ok THEN Fail ELSE
    LET oddLotAskAdfFormAttachment == ReadOddLotAskAdfFormAttachment2List(oddLotBidAdfFormAttachment.rest, olAskLevelCount.value) IN IF ~oddLotAskAdfFormAttachment.ok THEN Fail ELSE
    Ok([ orig                       |-> orig.value,
         timestamp1                 |-> timestamp1.value,
         feedSequence               |-> feedSequence.value,
         partToken                  |-> partToken.value,
         timestamp2                 |-> timestamp2.value,
         symbolLong                 |-> symbolLong.value,
         bidLong                    |-> bidLong.value,
         bidSizeLong                |-> bidSizeLong.value,
         askLong                    |-> askLong.value,
         askSizeLong                |-> askSizeLong.value,
         cond                       |-> cond.value,
         mpid                       |-> mpid.value,
         rii                        |-> rii.value,
         bboBidPrice                |-> bboBidPrice.value,
         bboBidSize                 |-> bboBidSize.value,
         bboBidMpid                 |-> bboBidMpid.value,
         bboAskPrice                |-> bboAskPrice.value,
         bboAskSize                 |-> bboAskSize.value,
         bboAskMpid                 |-> bboAskMpid.value,
         bboCond                    |-> bboCond.value,
         oddLotBidAdfFormAttachment |-> oddLotBidAdfFormAttachment.value,
         oddLotAskAdfFormAttachment |-> oddLotAskAdfFormAttachment.value ], oddLotAskAdfFormAttachment.rest)

ZeroFinraAdfCombinedQuoteMessageWithBbo ==
    [ orig                       |-> [i \in 1 .. 2 |-> 0],
      timestamp1                 |-> [i \in 1 .. 8 |-> 0],
      feedSequence               |-> [i \in 1 .. 8 |-> 0],
      partToken                  |-> [i \in 1 .. 8 |-> 0],
      timestamp2                 |-> [i \in 1 .. 8 |-> 0],
      symbolLong                 |-> [i \in 1 .. 11 |-> 0],
      bidLong                    |-> [i \in 1 .. 8 |-> 0],
      bidSizeLong                |-> [i \in 1 .. 4 |-> 0],
      askLong                    |-> [i \in 1 .. 8 |-> 0],
      askSizeLong                |-> [i \in 1 .. 4 |-> 0],
      cond                       |-> [i \in 1 .. 1 |-> 0],
      mpid                       |-> [i \in 1 .. 4 |-> 0],
      rii                        |-> [i \in 1 .. 1 |-> 0],
      bboBidPrice                |-> [i \in 1 .. 8 |-> 0],
      bboBidSize                 |-> [i \in 1 .. 4 |-> 0],
      bboBidMpid                 |-> [i \in 1 .. 4 |-> 0],
      bboAskPrice                |-> [i \in 1 .. 8 |-> 0],
      bboAskSize                 |-> [i \in 1 .. 4 |-> 0],
      bboAskMpid                 |-> [i \in 1 .. 4 |-> 0],
      bboCond                    |-> [i \in 1 .. 1 |-> 0],
      oddLotBidAdfFormAttachment |-> << >>,
      oddLotAskAdfFormAttachment |-> << >> ]

(* Finra Adf Combined Quote Message With Bbo at zero, then each field in turn at the values it is checked at *)
CheckedFinraAdfCombinedQuoteMessageWithBbo ==
    { ZeroFinraAdfCombinedQuoteMessageWithBbo }
        \cup { [ZeroFinraAdfCombinedQuoteMessageWithBbo EXCEPT !.orig = one] : one \in Sample(2) }
        \cup { [ZeroFinraAdfCombinedQuoteMessageWithBbo EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroFinraAdfCombinedQuoteMessageWithBbo EXCEPT !.feedSequence = one] : one \in Sample(8) }
        \cup { [ZeroFinraAdfCombinedQuoteMessageWithBbo EXCEPT !.partToken = one] : one \in Sample(8) }
        \cup { [ZeroFinraAdfCombinedQuoteMessageWithBbo EXCEPT !.timestamp2 = one] : one \in Sample(8) }
        \cup { [ZeroFinraAdfCombinedQuoteMessageWithBbo EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroFinraAdfCombinedQuoteMessageWithBbo EXCEPT !.bidLong = one] : one \in Sample(8) }
        \cup { [ZeroFinraAdfCombinedQuoteMessageWithBbo EXCEPT !.bidSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroFinraAdfCombinedQuoteMessageWithBbo EXCEPT !.askLong = one] : one \in Sample(8) }
        \cup { [ZeroFinraAdfCombinedQuoteMessageWithBbo EXCEPT !.askSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroFinraAdfCombinedQuoteMessageWithBbo EXCEPT !.cond = one] : one \in Sample(1) }
        \cup { [ZeroFinraAdfCombinedQuoteMessageWithBbo EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroFinraAdfCombinedQuoteMessageWithBbo EXCEPT !.rii = one] : one \in Sample(1) }
        \cup { [ZeroFinraAdfCombinedQuoteMessageWithBbo EXCEPT !.bboBidPrice = one] : one \in Sample(8) }
        \cup { [ZeroFinraAdfCombinedQuoteMessageWithBbo EXCEPT !.bboBidSize = one] : one \in Sample(4) }
        \cup { [ZeroFinraAdfCombinedQuoteMessageWithBbo EXCEPT !.bboBidMpid = one] : one \in Sample(4) }
        \cup { [ZeroFinraAdfCombinedQuoteMessageWithBbo EXCEPT !.bboAskPrice = one] : one \in Sample(8) }
        \cup { [ZeroFinraAdfCombinedQuoteMessageWithBbo EXCEPT !.bboAskSize = one] : one \in Sample(4) }
        \cup { [ZeroFinraAdfCombinedQuoteMessageWithBbo EXCEPT !.bboAskMpid = one] : one \in Sample(4) }
        \cup { [ZeroFinraAdfCombinedQuoteMessageWithBbo EXCEPT !.bboCond = one] : one \in Sample(1) }
        \cup { [ZeroFinraAdfCombinedQuoteMessageWithBbo EXCEPT !.oddLotBidAdfFormAttachment = one] : one \in SampleLists(OneOddLotBidAdfFormAttachment2) }
        \cup { [ZeroFinraAdfCombinedQuoteMessageWithBbo EXCEPT !.oddLotAskAdfFormAttachment = one] : one \in SampleLists(OneOddLotAskAdfFormAttachment2) }

(***************************************************************************)
(* Inbound Quote Messages Message Payload, selected by Inbound Quote       *)
(* Messages Message Type                                                   *)
(***************************************************************************)

ProtectedExchangeQuoteMessageShortformMessageCode == 81  \* "Q"
ProtectedExchangeQuoteMessageLongformMessageCode == 76  \* "L"
ExchangeOddLotQuoteMessageShortFormMessageCode == 79  \* "O"
ExchangeOddLotQuoteMessageLongFormMessageCode == 74  \* "J"
ExchangeCombinedQuoteMessageShortFormMessageCode == 80  \* "P"
ExchangeCombinedQuoteMessageLongFormMessageCode == 75  \* "K"
FinraProtectedQuoteMessageWithBboInfoMessageCode == 71  \* "G"
FinraProtectedQuoteMessageWithoutBboInfoMessageCode == 70  \* "F"
FinraAdfOddLotQuotationMessageCode == 72  \* "H"
FinraAdfCombinedQuoteMessageWithBboCode == 82  \* "R"

InboundQuoteMessagesMessagePayload ==
    [ tag : {ProtectedExchangeQuoteMessageShortformMessageCode}, body : ProtectedExchangeQuoteMessageShortformMessage ]
        \cup [ tag : {ProtectedExchangeQuoteMessageLongformMessageCode}, body : ProtectedExchangeQuoteMessageLongformMessage ]
        \cup [ tag : {ExchangeOddLotQuoteMessageShortFormMessageCode}, body : ExchangeOddLotQuoteMessageShortFormMessage ]
        \cup [ tag : {ExchangeOddLotQuoteMessageLongFormMessageCode}, body : ExchangeOddLotQuoteMessageLongFormMessage ]
        \cup [ tag : {ExchangeCombinedQuoteMessageShortFormMessageCode}, body : ExchangeCombinedQuoteMessageShortFormMessage ]
        \cup [ tag : {ExchangeCombinedQuoteMessageLongFormMessageCode}, body : ExchangeCombinedQuoteMessageLongFormMessage ]
        \cup [ tag : {FinraProtectedQuoteMessageWithBboInfoMessageCode}, body : FinraProtectedQuoteMessageWithBboInfoMessage ]
        \cup [ tag : {FinraProtectedQuoteMessageWithoutBboInfoMessageCode}, body : FinraProtectedQuoteMessageWithoutBboInfoMessage ]
        \cup [ tag : {FinraAdfOddLotQuotationMessageCode}, body : FinraAdfOddLotQuotationMessage ]
        \cup [ tag : {FinraAdfCombinedQuoteMessageWithBboCode}, body : FinraAdfCombinedQuoteMessageWithBbo ]

EncodeInboundQuoteMessagesMessagePayload(message) ==
    CASE message.tag = ProtectedExchangeQuoteMessageShortformMessageCode -> EncodeProtectedExchangeQuoteMessageShortformMessage(message.body)
      [] message.tag = ProtectedExchangeQuoteMessageLongformMessageCode -> EncodeProtectedExchangeQuoteMessageLongformMessage(message.body)
      [] message.tag = ExchangeOddLotQuoteMessageShortFormMessageCode -> EncodeExchangeOddLotQuoteMessageShortFormMessage(message.body)
      [] message.tag = ExchangeOddLotQuoteMessageLongFormMessageCode -> EncodeExchangeOddLotQuoteMessageLongFormMessage(message.body)
      [] message.tag = ExchangeCombinedQuoteMessageShortFormMessageCode -> EncodeExchangeCombinedQuoteMessageShortFormMessage(message.body)
      [] message.tag = ExchangeCombinedQuoteMessageLongFormMessageCode -> EncodeExchangeCombinedQuoteMessageLongFormMessage(message.body)
      [] message.tag = FinraProtectedQuoteMessageWithBboInfoMessageCode -> EncodeFinraProtectedQuoteMessageWithBboInfoMessage(message.body)
      [] message.tag = FinraProtectedQuoteMessageWithoutBboInfoMessageCode -> EncodeFinraProtectedQuoteMessageWithoutBboInfoMessage(message.body)
      [] message.tag = FinraAdfOddLotQuotationMessageCode -> EncodeFinraAdfOddLotQuotationMessage(message.body)
      [] message.tag = FinraAdfCombinedQuoteMessageWithBboCode -> EncodeFinraAdfCombinedQuoteMessageWithBbo(message.body)

DecodeInboundQuoteMessagesMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = ProtectedExchangeQuoteMessageShortformMessageCode -> DecodeProtectedExchangeQuoteMessageShortformMessage(bytes)
              [] tag = ProtectedExchangeQuoteMessageLongformMessageCode -> DecodeProtectedExchangeQuoteMessageLongformMessage(bytes)
              [] tag = ExchangeOddLotQuoteMessageShortFormMessageCode -> DecodeExchangeOddLotQuoteMessageShortFormMessage(bytes)
              [] tag = ExchangeOddLotQuoteMessageLongFormMessageCode -> DecodeExchangeOddLotQuoteMessageLongFormMessage(bytes)
              [] tag = ExchangeCombinedQuoteMessageShortFormMessageCode -> DecodeExchangeCombinedQuoteMessageShortFormMessage(bytes)
              [] tag = ExchangeCombinedQuoteMessageLongFormMessageCode -> DecodeExchangeCombinedQuoteMessageLongFormMessage(bytes)
              [] tag = FinraProtectedQuoteMessageWithBboInfoMessageCode -> DecodeFinraProtectedQuoteMessageWithBboInfoMessage(bytes)
              [] tag = FinraProtectedQuoteMessageWithoutBboInfoMessageCode -> DecodeFinraProtectedQuoteMessageWithoutBboInfoMessage(bytes)
              [] tag = FinraAdfOddLotQuotationMessageCode -> DecodeFinraAdfOddLotQuotationMessage(bytes)
              [] tag = FinraAdfCombinedQuoteMessageWithBboCode -> DecodeFinraAdfCombinedQuoteMessageWithBbo(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroInboundQuoteMessagesMessagePayload == [tag |-> ProtectedExchangeQuoteMessageShortformMessageCode, body |-> ZeroProtectedExchangeQuoteMessageShortformMessage]

(* Each Inbound Quote Messages Message Payload in turn, at the values the message it names is checked at *)
CheckedInboundQuoteMessagesMessagePayload ==
    { [tag |-> ProtectedExchangeQuoteMessageShortformMessageCode, body |-> one] : one \in CheckedProtectedExchangeQuoteMessageShortformMessage }
        \cup { [tag |-> ProtectedExchangeQuoteMessageLongformMessageCode, body |-> one] : one \in CheckedProtectedExchangeQuoteMessageLongformMessage }
        \cup { [tag |-> ExchangeOddLotQuoteMessageShortFormMessageCode, body |-> one] : one \in CheckedExchangeOddLotQuoteMessageShortFormMessage }
        \cup { [tag |-> ExchangeOddLotQuoteMessageLongFormMessageCode, body |-> one] : one \in CheckedExchangeOddLotQuoteMessageLongFormMessage }
        \cup { [tag |-> ExchangeCombinedQuoteMessageShortFormMessageCode, body |-> one] : one \in CheckedExchangeCombinedQuoteMessageShortFormMessage }
        \cup { [tag |-> ExchangeCombinedQuoteMessageLongFormMessageCode, body |-> one] : one \in CheckedExchangeCombinedQuoteMessageLongFormMessage }
        \cup { [tag |-> FinraProtectedQuoteMessageWithBboInfoMessageCode, body |-> one] : one \in CheckedFinraProtectedQuoteMessageWithBboInfoMessage }
        \cup { [tag |-> FinraProtectedQuoteMessageWithoutBboInfoMessageCode, body |-> one] : one \in CheckedFinraProtectedQuoteMessageWithoutBboInfoMessage }
        \cup { [tag |-> FinraAdfOddLotQuotationMessageCode, body |-> one] : one \in CheckedFinraAdfOddLotQuotationMessage }
        \cup { [tag |-> FinraAdfCombinedQuoteMessageWithBboCode, body |-> one] : one \in CheckedFinraAdfCombinedQuoteMessageWithBbo }

(***************************************************************************)
(* Inbound Quote Messages Message                                          *)
(***************************************************************************)

InboundQuoteMessagesMessage ==
    [ inboundQuoteMessagesMessagePayload : InboundQuoteMessagesMessagePayload ]

EncodeInboundQuoteMessagesMessage(message) ==
    EncodeUIntBE(message.inboundQuoteMessagesMessagePayload.tag, 1)
        \o EncodeInboundQuoteMessagesMessagePayload(message.inboundQuoteMessagesMessagePayload)

DecodeInboundQuoteMessagesMessage(bytes) ==
    LET inboundQuoteMessagesMessageType == ReadUIntBE(bytes, 1) IN IF ~inboundQuoteMessagesMessageType.ok THEN Fail ELSE
    LET inboundQuoteMessagesMessagePayload == DecodeInboundQuoteMessagesMessagePayload(inboundQuoteMessagesMessageType.value, inboundQuoteMessagesMessageType.rest) IN IF ~inboundQuoteMessagesMessagePayload.ok THEN Fail ELSE
    Ok([ inboundQuoteMessagesMessagePayload |-> inboundQuoteMessagesMessagePayload.value ], inboundQuoteMessagesMessagePayload.rest)

ZeroInboundQuoteMessagesMessage ==
    [ inboundQuoteMessagesMessagePayload |-> ZeroInboundQuoteMessagesMessagePayload ]

(* Inbound Quote Messages Message at zero, then each field in turn at the values it is checked at *)
CheckedInboundQuoteMessagesMessage ==
    { ZeroInboundQuoteMessagesMessage }
        \cup { [ZeroInboundQuoteMessagesMessage EXCEPT !.inboundQuoteMessagesMessagePayload = one] : one \in CheckedInboundQuoteMessagesMessagePayload }

(***************************************************************************)
(* Regular Trade Report Message: 69 bytes                                  *)
(***************************************************************************)

RegularTradeReportMessage ==
    [ orig         : Sample(2),
      timestamp1   : Sample(8),
      feedSequence : Sample(8),
      partToken    : Sample(8),
      timestamp2   : Sample(8),
      symbolLong   : Sample(11),
      tradeId      : Sample(4),
      ttExempt     : Sample(1),
      trcond       : Sample(4),
      ssday        : Sample(2),
      side         : Sample(1),
      price        : Sample(8),
      volume       : Sample(4) ]

EncodeRegularTradeReportMessage(message) ==
    message.orig
        \o message.timestamp1
        \o message.feedSequence
        \o message.partToken
        \o message.timestamp2
        \o message.symbolLong
        \o message.tradeId
        \o message.ttExempt
        \o message.trcond
        \o message.ssday
        \o message.side
        \o message.price
        \o message.volume

DecodeRegularTradeReportMessage(bytes) ==
    LET orig == ReadBytes(bytes, 2) IN IF ~orig.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(orig.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET feedSequence == ReadBytes(timestamp1.rest, 8) IN IF ~feedSequence.ok THEN Fail ELSE
    LET partToken == ReadBytes(feedSequence.rest, 8) IN IF ~partToken.ok THEN Fail ELSE
    LET timestamp2 == ReadBytes(partToken.rest, 8) IN IF ~timestamp2.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(timestamp2.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET tradeId == ReadBytes(symbolLong.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET ttExempt == ReadBytes(tradeId.rest, 1) IN IF ~ttExempt.ok THEN Fail ELSE
    LET trcond == ReadBytes(ttExempt.rest, 4) IN IF ~trcond.ok THEN Fail ELSE
    LET ssday == ReadBytes(trcond.rest, 2) IN IF ~ssday.ok THEN Fail ELSE
    LET side == ReadBytes(ssday.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadBytes(side.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET volume == ReadBytes(price.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    Ok([ orig         |-> orig.value,
         timestamp1   |-> timestamp1.value,
         feedSequence |-> feedSequence.value,
         partToken    |-> partToken.value,
         timestamp2   |-> timestamp2.value,
         symbolLong   |-> symbolLong.value,
         tradeId      |-> tradeId.value,
         ttExempt     |-> ttExempt.value,
         trcond       |-> trcond.value,
         ssday        |-> ssday.value,
         side         |-> side.value,
         price        |-> price.value,
         volume       |-> volume.value ], volume.rest)

ZeroRegularTradeReportMessage ==
    [ orig         |-> [i \in 1 .. 2 |-> 0],
      timestamp1   |-> [i \in 1 .. 8 |-> 0],
      feedSequence |-> [i \in 1 .. 8 |-> 0],
      partToken    |-> [i \in 1 .. 8 |-> 0],
      timestamp2   |-> [i \in 1 .. 8 |-> 0],
      symbolLong   |-> [i \in 1 .. 11 |-> 0],
      tradeId      |-> [i \in 1 .. 4 |-> 0],
      ttExempt     |-> [i \in 1 .. 1 |-> 0],
      trcond       |-> [i \in 1 .. 4 |-> 0],
      ssday        |-> [i \in 1 .. 2 |-> 0],
      side         |-> [i \in 1 .. 1 |-> 0],
      price        |-> [i \in 1 .. 8 |-> 0],
      volume       |-> [i \in 1 .. 4 |-> 0] ]

(* Regular Trade Report Message at zero, then each field in turn at the values it is checked at *)
CheckedRegularTradeReportMessage ==
    { ZeroRegularTradeReportMessage }
        \cup { [ZeroRegularTradeReportMessage EXCEPT !.orig = one] : one \in Sample(2) }
        \cup { [ZeroRegularTradeReportMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroRegularTradeReportMessage EXCEPT !.feedSequence = one] : one \in Sample(8) }
        \cup { [ZeroRegularTradeReportMessage EXCEPT !.partToken = one] : one \in Sample(8) }
        \cup { [ZeroRegularTradeReportMessage EXCEPT !.timestamp2 = one] : one \in Sample(8) }
        \cup { [ZeroRegularTradeReportMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroRegularTradeReportMessage EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroRegularTradeReportMessage EXCEPT !.ttExempt = one] : one \in Sample(1) }
        \cup { [ZeroRegularTradeReportMessage EXCEPT !.trcond = one] : one \in Sample(4) }
        \cup { [ZeroRegularTradeReportMessage EXCEPT !.ssday = one] : one \in Sample(2) }
        \cup { [ZeroRegularTradeReportMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroRegularTradeReportMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroRegularTradeReportMessage EXCEPT !.volume = one] : one \in Sample(4) }

(***************************************************************************)
(* Trade Cancel Error Message: 70 bytes                                    *)
(***************************************************************************)

TradeCancelErrorMessage ==
    [ orig         : Sample(2),
      timestamp1   : Sample(8),
      feedSequence : Sample(8),
      partToken    : Sample(8),
      timestamp2   : Sample(8),
      symbolLong   : Sample(11),
      cancelType   : Sample(1),
      origTradeId  : Sample(4),
      origTtExempt : Sample(1),
      origTrcond   : Sample(4),
      origSsday    : Sample(2),
      origSide     : Sample(1),
      origPrice    : Sample(8),
      origVolume   : Sample(4) ]

EncodeTradeCancelErrorMessage(message) ==
    message.orig
        \o message.timestamp1
        \o message.feedSequence
        \o message.partToken
        \o message.timestamp2
        \o message.symbolLong
        \o message.cancelType
        \o message.origTradeId
        \o message.origTtExempt
        \o message.origTrcond
        \o message.origSsday
        \o message.origSide
        \o message.origPrice
        \o message.origVolume

DecodeTradeCancelErrorMessage(bytes) ==
    LET orig == ReadBytes(bytes, 2) IN IF ~orig.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(orig.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET feedSequence == ReadBytes(timestamp1.rest, 8) IN IF ~feedSequence.ok THEN Fail ELSE
    LET partToken == ReadBytes(feedSequence.rest, 8) IN IF ~partToken.ok THEN Fail ELSE
    LET timestamp2 == ReadBytes(partToken.rest, 8) IN IF ~timestamp2.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(timestamp2.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET cancelType == ReadBytes(symbolLong.rest, 1) IN IF ~cancelType.ok THEN Fail ELSE
    LET origTradeId == ReadBytes(cancelType.rest, 4) IN IF ~origTradeId.ok THEN Fail ELSE
    LET origTtExempt == ReadBytes(origTradeId.rest, 1) IN IF ~origTtExempt.ok THEN Fail ELSE
    LET origTrcond == ReadBytes(origTtExempt.rest, 4) IN IF ~origTrcond.ok THEN Fail ELSE
    LET origSsday == ReadBytes(origTrcond.rest, 2) IN IF ~origSsday.ok THEN Fail ELSE
    LET origSide == ReadBytes(origSsday.rest, 1) IN IF ~origSide.ok THEN Fail ELSE
    LET origPrice == ReadBytes(origSide.rest, 8) IN IF ~origPrice.ok THEN Fail ELSE
    LET origVolume == ReadBytes(origPrice.rest, 4) IN IF ~origVolume.ok THEN Fail ELSE
    Ok([ orig         |-> orig.value,
         timestamp1   |-> timestamp1.value,
         feedSequence |-> feedSequence.value,
         partToken    |-> partToken.value,
         timestamp2   |-> timestamp2.value,
         symbolLong   |-> symbolLong.value,
         cancelType   |-> cancelType.value,
         origTradeId  |-> origTradeId.value,
         origTtExempt |-> origTtExempt.value,
         origTrcond   |-> origTrcond.value,
         origSsday    |-> origSsday.value,
         origSide     |-> origSide.value,
         origPrice    |-> origPrice.value,
         origVolume   |-> origVolume.value ], origVolume.rest)

ZeroTradeCancelErrorMessage ==
    [ orig         |-> [i \in 1 .. 2 |-> 0],
      timestamp1   |-> [i \in 1 .. 8 |-> 0],
      feedSequence |-> [i \in 1 .. 8 |-> 0],
      partToken    |-> [i \in 1 .. 8 |-> 0],
      timestamp2   |-> [i \in 1 .. 8 |-> 0],
      symbolLong   |-> [i \in 1 .. 11 |-> 0],
      cancelType   |-> [i \in 1 .. 1 |-> 0],
      origTradeId  |-> [i \in 1 .. 4 |-> 0],
      origTtExempt |-> [i \in 1 .. 1 |-> 0],
      origTrcond   |-> [i \in 1 .. 4 |-> 0],
      origSsday    |-> [i \in 1 .. 2 |-> 0],
      origSide     |-> [i \in 1 .. 1 |-> 0],
      origPrice    |-> [i \in 1 .. 8 |-> 0],
      origVolume   |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Cancel Error Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCancelErrorMessage ==
    { ZeroTradeCancelErrorMessage }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.orig = one] : one \in Sample(2) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.feedSequence = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.partToken = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.timestamp2 = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.cancelType = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.origTradeId = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.origTtExempt = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.origTrcond = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.origSsday = one] : one \in Sample(2) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.origSide = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.origPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.origVolume = one] : one \in Sample(4) }

(***************************************************************************)
(* Trade Correction Message: 92 bytes                                      *)
(***************************************************************************)

TradeCorrectionMessage ==
    [ orig         : Sample(2),
      timestamp1   : Sample(8),
      feedSequence : Sample(8),
      partToken    : Sample(8),
      timestamp2   : Sample(8),
      symbolLong   : Sample(11),
      tradeId      : Sample(4),
      origTradeId  : Sample(4),
      origTtExempt : Sample(1),
      origTrcond   : Sample(4),
      origSsday    : Sample(2),
      side         : Sample(1),
      origPrice    : Sample(8),
      origVolume   : Sample(4),
      newTtExempt  : Sample(1),
      newTrcond    : Sample(4),
      newSsday     : Sample(2),
      newPrice     : Sample(8),
      newVolume    : Sample(4) ]

EncodeTradeCorrectionMessage(message) ==
    message.orig
        \o message.timestamp1
        \o message.feedSequence
        \o message.partToken
        \o message.timestamp2
        \o message.symbolLong
        \o message.tradeId
        \o message.origTradeId
        \o message.origTtExempt
        \o message.origTrcond
        \o message.origSsday
        \o message.side
        \o message.origPrice
        \o message.origVolume
        \o message.newTtExempt
        \o message.newTrcond
        \o message.newSsday
        \o message.newPrice
        \o message.newVolume

DecodeTradeCorrectionMessage(bytes) ==
    LET orig == ReadBytes(bytes, 2) IN IF ~orig.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(orig.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET feedSequence == ReadBytes(timestamp1.rest, 8) IN IF ~feedSequence.ok THEN Fail ELSE
    LET partToken == ReadBytes(feedSequence.rest, 8) IN IF ~partToken.ok THEN Fail ELSE
    LET timestamp2 == ReadBytes(partToken.rest, 8) IN IF ~timestamp2.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(timestamp2.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET tradeId == ReadBytes(symbolLong.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET origTradeId == ReadBytes(tradeId.rest, 4) IN IF ~origTradeId.ok THEN Fail ELSE
    LET origTtExempt == ReadBytes(origTradeId.rest, 1) IN IF ~origTtExempt.ok THEN Fail ELSE
    LET origTrcond == ReadBytes(origTtExempt.rest, 4) IN IF ~origTrcond.ok THEN Fail ELSE
    LET origSsday == ReadBytes(origTrcond.rest, 2) IN IF ~origSsday.ok THEN Fail ELSE
    LET side == ReadBytes(origSsday.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET origPrice == ReadBytes(side.rest, 8) IN IF ~origPrice.ok THEN Fail ELSE
    LET origVolume == ReadBytes(origPrice.rest, 4) IN IF ~origVolume.ok THEN Fail ELSE
    LET newTtExempt == ReadBytes(origVolume.rest, 1) IN IF ~newTtExempt.ok THEN Fail ELSE
    LET newTrcond == ReadBytes(newTtExempt.rest, 4) IN IF ~newTrcond.ok THEN Fail ELSE
    LET newSsday == ReadBytes(newTrcond.rest, 2) IN IF ~newSsday.ok THEN Fail ELSE
    LET newPrice == ReadBytes(newSsday.rest, 8) IN IF ~newPrice.ok THEN Fail ELSE
    LET newVolume == ReadBytes(newPrice.rest, 4) IN IF ~newVolume.ok THEN Fail ELSE
    Ok([ orig         |-> orig.value,
         timestamp1   |-> timestamp1.value,
         feedSequence |-> feedSequence.value,
         partToken    |-> partToken.value,
         timestamp2   |-> timestamp2.value,
         symbolLong   |-> symbolLong.value,
         tradeId      |-> tradeId.value,
         origTradeId  |-> origTradeId.value,
         origTtExempt |-> origTtExempt.value,
         origTrcond   |-> origTrcond.value,
         origSsday    |-> origSsday.value,
         side         |-> side.value,
         origPrice    |-> origPrice.value,
         origVolume   |-> origVolume.value,
         newTtExempt  |-> newTtExempt.value,
         newTrcond    |-> newTrcond.value,
         newSsday     |-> newSsday.value,
         newPrice     |-> newPrice.value,
         newVolume    |-> newVolume.value ], newVolume.rest)

ZeroTradeCorrectionMessage ==
    [ orig         |-> [i \in 1 .. 2 |-> 0],
      timestamp1   |-> [i \in 1 .. 8 |-> 0],
      feedSequence |-> [i \in 1 .. 8 |-> 0],
      partToken    |-> [i \in 1 .. 8 |-> 0],
      timestamp2   |-> [i \in 1 .. 8 |-> 0],
      symbolLong   |-> [i \in 1 .. 11 |-> 0],
      tradeId      |-> [i \in 1 .. 4 |-> 0],
      origTradeId  |-> [i \in 1 .. 4 |-> 0],
      origTtExempt |-> [i \in 1 .. 1 |-> 0],
      origTrcond   |-> [i \in 1 .. 4 |-> 0],
      origSsday    |-> [i \in 1 .. 2 |-> 0],
      side         |-> [i \in 1 .. 1 |-> 0],
      origPrice    |-> [i \in 1 .. 8 |-> 0],
      origVolume   |-> [i \in 1 .. 4 |-> 0],
      newTtExempt  |-> [i \in 1 .. 1 |-> 0],
      newTrcond    |-> [i \in 1 .. 4 |-> 0],
      newSsday     |-> [i \in 1 .. 2 |-> 0],
      newPrice     |-> [i \in 1 .. 8 |-> 0],
      newVolume    |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Correction Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCorrectionMessage ==
    { ZeroTradeCorrectionMessage }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.orig = one] : one \in Sample(2) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.feedSequence = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.partToken = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.timestamp2 = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.origTradeId = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.origTtExempt = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.origTrcond = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.origSsday = one] : one \in Sample(2) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.origPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.origVolume = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.newTtExempt = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.newTrcond = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.newSsday = one] : one \in Sample(2) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.newPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.newVolume = one] : one \in Sample(4) }

(***************************************************************************)
(* As Of Trade Report Message: 70 bytes                                    *)
(***************************************************************************)

AsOfTradeReportMessage ==
    [ orig         : Sample(2),
      timestamp1   : Sample(8),
      feedSequence : Sample(8),
      partToken    : Sample(8),
      symbolLong   : Sample(11),
      tradeId      : Sample(4),
      ttExempt     : Sample(1),
      trcond       : Sample(4),
      ssday        : Sample(2),
      side         : Sample(1),
      price        : Sample(8),
      volume       : Sample(4),
      tradeTime    : Sample(8),
      reversal     : Sample(1) ]

EncodeAsOfTradeReportMessage(message) ==
    message.orig
        \o message.timestamp1
        \o message.feedSequence
        \o message.partToken
        \o message.symbolLong
        \o message.tradeId
        \o message.ttExempt
        \o message.trcond
        \o message.ssday
        \o message.side
        \o message.price
        \o message.volume
        \o message.tradeTime
        \o message.reversal

DecodeAsOfTradeReportMessage(bytes) ==
    LET orig == ReadBytes(bytes, 2) IN IF ~orig.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(orig.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET feedSequence == ReadBytes(timestamp1.rest, 8) IN IF ~feedSequence.ok THEN Fail ELSE
    LET partToken == ReadBytes(feedSequence.rest, 8) IN IF ~partToken.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(partToken.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET tradeId == ReadBytes(symbolLong.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET ttExempt == ReadBytes(tradeId.rest, 1) IN IF ~ttExempt.ok THEN Fail ELSE
    LET trcond == ReadBytes(ttExempt.rest, 4) IN IF ~trcond.ok THEN Fail ELSE
    LET ssday == ReadBytes(trcond.rest, 2) IN IF ~ssday.ok THEN Fail ELSE
    LET side == ReadBytes(ssday.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadBytes(side.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET volume == ReadBytes(price.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET tradeTime == ReadBytes(volume.rest, 8) IN IF ~tradeTime.ok THEN Fail ELSE
    LET reversal == ReadBytes(tradeTime.rest, 1) IN IF ~reversal.ok THEN Fail ELSE
    Ok([ orig         |-> orig.value,
         timestamp1   |-> timestamp1.value,
         feedSequence |-> feedSequence.value,
         partToken    |-> partToken.value,
         symbolLong   |-> symbolLong.value,
         tradeId      |-> tradeId.value,
         ttExempt     |-> ttExempt.value,
         trcond       |-> trcond.value,
         ssday        |-> ssday.value,
         side         |-> side.value,
         price        |-> price.value,
         volume       |-> volume.value,
         tradeTime    |-> tradeTime.value,
         reversal     |-> reversal.value ], reversal.rest)

ZeroAsOfTradeReportMessage ==
    [ orig         |-> [i \in 1 .. 2 |-> 0],
      timestamp1   |-> [i \in 1 .. 8 |-> 0],
      feedSequence |-> [i \in 1 .. 8 |-> 0],
      partToken    |-> [i \in 1 .. 8 |-> 0],
      symbolLong   |-> [i \in 1 .. 11 |-> 0],
      tradeId      |-> [i \in 1 .. 4 |-> 0],
      ttExempt     |-> [i \in 1 .. 1 |-> 0],
      trcond       |-> [i \in 1 .. 4 |-> 0],
      ssday        |-> [i \in 1 .. 2 |-> 0],
      side         |-> [i \in 1 .. 1 |-> 0],
      price        |-> [i \in 1 .. 8 |-> 0],
      volume       |-> [i \in 1 .. 4 |-> 0],
      tradeTime    |-> [i \in 1 .. 8 |-> 0],
      reversal     |-> [i \in 1 .. 1 |-> 0] ]

(* As Of Trade Report Message at zero, then each field in turn at the values it is checked at *)
CheckedAsOfTradeReportMessage ==
    { ZeroAsOfTradeReportMessage }
        \cup { [ZeroAsOfTradeReportMessage EXCEPT !.orig = one] : one \in Sample(2) }
        \cup { [ZeroAsOfTradeReportMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroAsOfTradeReportMessage EXCEPT !.feedSequence = one] : one \in Sample(8) }
        \cup { [ZeroAsOfTradeReportMessage EXCEPT !.partToken = one] : one \in Sample(8) }
        \cup { [ZeroAsOfTradeReportMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroAsOfTradeReportMessage EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroAsOfTradeReportMessage EXCEPT !.ttExempt = one] : one \in Sample(1) }
        \cup { [ZeroAsOfTradeReportMessage EXCEPT !.trcond = one] : one \in Sample(4) }
        \cup { [ZeroAsOfTradeReportMessage EXCEPT !.ssday = one] : one \in Sample(2) }
        \cup { [ZeroAsOfTradeReportMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAsOfTradeReportMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAsOfTradeReportMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroAsOfTradeReportMessage EXCEPT !.tradeTime = one] : one \in Sample(8) }
        \cup { [ZeroAsOfTradeReportMessage EXCEPT !.reversal = one] : one \in Sample(1) }

(***************************************************************************)
(* Fractional Regular Trade Report Message: 73 bytes                       *)
(***************************************************************************)

FractionalRegularTradeReportMessage ==
    [ orig             : Sample(2),
      timestamp1       : Sample(8),
      feedSequence     : Sample(8),
      partToken        : Sample(8),
      timestamp2       : Sample(8),
      symbolLong       : Sample(11),
      tradeId          : Sample(4),
      ttExempt         : Sample(1),
      trcond           : Sample(4),
      ssday            : Sample(2),
      side             : Sample(1),
      price            : Sample(8),
      volumeFractional : Sample(8) ]

EncodeFractionalRegularTradeReportMessage(message) ==
    message.orig
        \o message.timestamp1
        \o message.feedSequence
        \o message.partToken
        \o message.timestamp2
        \o message.symbolLong
        \o message.tradeId
        \o message.ttExempt
        \o message.trcond
        \o message.ssday
        \o message.side
        \o message.price
        \o message.volumeFractional

DecodeFractionalRegularTradeReportMessage(bytes) ==
    LET orig == ReadBytes(bytes, 2) IN IF ~orig.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(orig.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET feedSequence == ReadBytes(timestamp1.rest, 8) IN IF ~feedSequence.ok THEN Fail ELSE
    LET partToken == ReadBytes(feedSequence.rest, 8) IN IF ~partToken.ok THEN Fail ELSE
    LET timestamp2 == ReadBytes(partToken.rest, 8) IN IF ~timestamp2.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(timestamp2.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET tradeId == ReadBytes(symbolLong.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET ttExempt == ReadBytes(tradeId.rest, 1) IN IF ~ttExempt.ok THEN Fail ELSE
    LET trcond == ReadBytes(ttExempt.rest, 4) IN IF ~trcond.ok THEN Fail ELSE
    LET ssday == ReadBytes(trcond.rest, 2) IN IF ~ssday.ok THEN Fail ELSE
    LET side == ReadBytes(ssday.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadBytes(side.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET volumeFractional == ReadBytes(price.rest, 8) IN IF ~volumeFractional.ok THEN Fail ELSE
    Ok([ orig             |-> orig.value,
         timestamp1       |-> timestamp1.value,
         feedSequence     |-> feedSequence.value,
         partToken        |-> partToken.value,
         timestamp2       |-> timestamp2.value,
         symbolLong       |-> symbolLong.value,
         tradeId          |-> tradeId.value,
         ttExempt         |-> ttExempt.value,
         trcond           |-> trcond.value,
         ssday            |-> ssday.value,
         side             |-> side.value,
         price            |-> price.value,
         volumeFractional |-> volumeFractional.value ], volumeFractional.rest)

ZeroFractionalRegularTradeReportMessage ==
    [ orig             |-> [i \in 1 .. 2 |-> 0],
      timestamp1       |-> [i \in 1 .. 8 |-> 0],
      feedSequence     |-> [i \in 1 .. 8 |-> 0],
      partToken        |-> [i \in 1 .. 8 |-> 0],
      timestamp2       |-> [i \in 1 .. 8 |-> 0],
      symbolLong       |-> [i \in 1 .. 11 |-> 0],
      tradeId          |-> [i \in 1 .. 4 |-> 0],
      ttExempt         |-> [i \in 1 .. 1 |-> 0],
      trcond           |-> [i \in 1 .. 4 |-> 0],
      ssday            |-> [i \in 1 .. 2 |-> 0],
      side             |-> [i \in 1 .. 1 |-> 0],
      price            |-> [i \in 1 .. 8 |-> 0],
      volumeFractional |-> [i \in 1 .. 8 |-> 0] ]

(* Fractional Regular Trade Report Message at zero, then each field in turn at the values it is checked at *)
CheckedFractionalRegularTradeReportMessage ==
    { ZeroFractionalRegularTradeReportMessage }
        \cup { [ZeroFractionalRegularTradeReportMessage EXCEPT !.orig = one] : one \in Sample(2) }
        \cup { [ZeroFractionalRegularTradeReportMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroFractionalRegularTradeReportMessage EXCEPT !.feedSequence = one] : one \in Sample(8) }
        \cup { [ZeroFractionalRegularTradeReportMessage EXCEPT !.partToken = one] : one \in Sample(8) }
        \cup { [ZeroFractionalRegularTradeReportMessage EXCEPT !.timestamp2 = one] : one \in Sample(8) }
        \cup { [ZeroFractionalRegularTradeReportMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroFractionalRegularTradeReportMessage EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroFractionalRegularTradeReportMessage EXCEPT !.ttExempt = one] : one \in Sample(1) }
        \cup { [ZeroFractionalRegularTradeReportMessage EXCEPT !.trcond = one] : one \in Sample(4) }
        \cup { [ZeroFractionalRegularTradeReportMessage EXCEPT !.ssday = one] : one \in Sample(2) }
        \cup { [ZeroFractionalRegularTradeReportMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroFractionalRegularTradeReportMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroFractionalRegularTradeReportMessage EXCEPT !.volumeFractional = one] : one \in Sample(8) }

(***************************************************************************)
(* Fractional Trade Cancel Error Message: 74 bytes                         *)
(***************************************************************************)

FractionalTradeCancelErrorMessage ==
    [ orig                 : Sample(2),
      timestamp1           : Sample(8),
      feedSequence         : Sample(8),
      partToken            : Sample(8),
      timestamp2           : Sample(8),
      symbolLong           : Sample(11),
      cancelType           : Sample(1),
      origTradeId          : Sample(4),
      origTtExempt         : Sample(1),
      origTrcond           : Sample(4),
      origSsday            : Sample(2),
      origSide             : Sample(1),
      origPrice            : Sample(8),
      origVolumeFractional : Sample(8) ]

EncodeFractionalTradeCancelErrorMessage(message) ==
    message.orig
        \o message.timestamp1
        \o message.feedSequence
        \o message.partToken
        \o message.timestamp2
        \o message.symbolLong
        \o message.cancelType
        \o message.origTradeId
        \o message.origTtExempt
        \o message.origTrcond
        \o message.origSsday
        \o message.origSide
        \o message.origPrice
        \o message.origVolumeFractional

DecodeFractionalTradeCancelErrorMessage(bytes) ==
    LET orig == ReadBytes(bytes, 2) IN IF ~orig.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(orig.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET feedSequence == ReadBytes(timestamp1.rest, 8) IN IF ~feedSequence.ok THEN Fail ELSE
    LET partToken == ReadBytes(feedSequence.rest, 8) IN IF ~partToken.ok THEN Fail ELSE
    LET timestamp2 == ReadBytes(partToken.rest, 8) IN IF ~timestamp2.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(timestamp2.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET cancelType == ReadBytes(symbolLong.rest, 1) IN IF ~cancelType.ok THEN Fail ELSE
    LET origTradeId == ReadBytes(cancelType.rest, 4) IN IF ~origTradeId.ok THEN Fail ELSE
    LET origTtExempt == ReadBytes(origTradeId.rest, 1) IN IF ~origTtExempt.ok THEN Fail ELSE
    LET origTrcond == ReadBytes(origTtExempt.rest, 4) IN IF ~origTrcond.ok THEN Fail ELSE
    LET origSsday == ReadBytes(origTrcond.rest, 2) IN IF ~origSsday.ok THEN Fail ELSE
    LET origSide == ReadBytes(origSsday.rest, 1) IN IF ~origSide.ok THEN Fail ELSE
    LET origPrice == ReadBytes(origSide.rest, 8) IN IF ~origPrice.ok THEN Fail ELSE
    LET origVolumeFractional == ReadBytes(origPrice.rest, 8) IN IF ~origVolumeFractional.ok THEN Fail ELSE
    Ok([ orig                 |-> orig.value,
         timestamp1           |-> timestamp1.value,
         feedSequence         |-> feedSequence.value,
         partToken            |-> partToken.value,
         timestamp2           |-> timestamp2.value,
         symbolLong           |-> symbolLong.value,
         cancelType           |-> cancelType.value,
         origTradeId          |-> origTradeId.value,
         origTtExempt         |-> origTtExempt.value,
         origTrcond           |-> origTrcond.value,
         origSsday            |-> origSsday.value,
         origSide             |-> origSide.value,
         origPrice            |-> origPrice.value,
         origVolumeFractional |-> origVolumeFractional.value ], origVolumeFractional.rest)

ZeroFractionalTradeCancelErrorMessage ==
    [ orig                 |-> [i \in 1 .. 2 |-> 0],
      timestamp1           |-> [i \in 1 .. 8 |-> 0],
      feedSequence         |-> [i \in 1 .. 8 |-> 0],
      partToken            |-> [i \in 1 .. 8 |-> 0],
      timestamp2           |-> [i \in 1 .. 8 |-> 0],
      symbolLong           |-> [i \in 1 .. 11 |-> 0],
      cancelType           |-> [i \in 1 .. 1 |-> 0],
      origTradeId          |-> [i \in 1 .. 4 |-> 0],
      origTtExempt         |-> [i \in 1 .. 1 |-> 0],
      origTrcond           |-> [i \in 1 .. 4 |-> 0],
      origSsday            |-> [i \in 1 .. 2 |-> 0],
      origSide             |-> [i \in 1 .. 1 |-> 0],
      origPrice            |-> [i \in 1 .. 8 |-> 0],
      origVolumeFractional |-> [i \in 1 .. 8 |-> 0] ]

(* Fractional Trade Cancel Error Message at zero, then each field in turn at the values it is checked at *)
CheckedFractionalTradeCancelErrorMessage ==
    { ZeroFractionalTradeCancelErrorMessage }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.orig = one] : one \in Sample(2) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.feedSequence = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.partToken = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.timestamp2 = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.cancelType = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.origTradeId = one] : one \in Sample(4) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.origTtExempt = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.origTrcond = one] : one \in Sample(4) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.origSsday = one] : one \in Sample(2) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.origSide = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.origPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.origVolumeFractional = one] : one \in Sample(8) }

(***************************************************************************)
(* Fractional Trade Correction Message: 100 bytes                          *)
(***************************************************************************)

FractionalTradeCorrectionMessage ==
    [ orig                 : Sample(2),
      timestamp1           : Sample(8),
      feedSequence         : Sample(8),
      partToken            : Sample(8),
      timestamp2           : Sample(8),
      symbolLong           : Sample(11),
      tradeId              : Sample(4),
      origTradeId          : Sample(4),
      origTtExempt         : Sample(1),
      origTrcond           : Sample(4),
      origSsday            : Sample(2),
      side                 : Sample(1),
      origPrice            : Sample(8),
      origVolumeFractional : Sample(8),
      newTtExempt          : Sample(1),
      newTrcond            : Sample(4),
      newSsday             : Sample(2),
      newPrice             : Sample(8),
      newVolumeFractional  : Sample(8) ]

EncodeFractionalTradeCorrectionMessage(message) ==
    message.orig
        \o message.timestamp1
        \o message.feedSequence
        \o message.partToken
        \o message.timestamp2
        \o message.symbolLong
        \o message.tradeId
        \o message.origTradeId
        \o message.origTtExempt
        \o message.origTrcond
        \o message.origSsday
        \o message.side
        \o message.origPrice
        \o message.origVolumeFractional
        \o message.newTtExempt
        \o message.newTrcond
        \o message.newSsday
        \o message.newPrice
        \o message.newVolumeFractional

DecodeFractionalTradeCorrectionMessage(bytes) ==
    LET orig == ReadBytes(bytes, 2) IN IF ~orig.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(orig.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET feedSequence == ReadBytes(timestamp1.rest, 8) IN IF ~feedSequence.ok THEN Fail ELSE
    LET partToken == ReadBytes(feedSequence.rest, 8) IN IF ~partToken.ok THEN Fail ELSE
    LET timestamp2 == ReadBytes(partToken.rest, 8) IN IF ~timestamp2.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(timestamp2.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET tradeId == ReadBytes(symbolLong.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET origTradeId == ReadBytes(tradeId.rest, 4) IN IF ~origTradeId.ok THEN Fail ELSE
    LET origTtExempt == ReadBytes(origTradeId.rest, 1) IN IF ~origTtExempt.ok THEN Fail ELSE
    LET origTrcond == ReadBytes(origTtExempt.rest, 4) IN IF ~origTrcond.ok THEN Fail ELSE
    LET origSsday == ReadBytes(origTrcond.rest, 2) IN IF ~origSsday.ok THEN Fail ELSE
    LET side == ReadBytes(origSsday.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET origPrice == ReadBytes(side.rest, 8) IN IF ~origPrice.ok THEN Fail ELSE
    LET origVolumeFractional == ReadBytes(origPrice.rest, 8) IN IF ~origVolumeFractional.ok THEN Fail ELSE
    LET newTtExempt == ReadBytes(origVolumeFractional.rest, 1) IN IF ~newTtExempt.ok THEN Fail ELSE
    LET newTrcond == ReadBytes(newTtExempt.rest, 4) IN IF ~newTrcond.ok THEN Fail ELSE
    LET newSsday == ReadBytes(newTrcond.rest, 2) IN IF ~newSsday.ok THEN Fail ELSE
    LET newPrice == ReadBytes(newSsday.rest, 8) IN IF ~newPrice.ok THEN Fail ELSE
    LET newVolumeFractional == ReadBytes(newPrice.rest, 8) IN IF ~newVolumeFractional.ok THEN Fail ELSE
    Ok([ orig                 |-> orig.value,
         timestamp1           |-> timestamp1.value,
         feedSequence         |-> feedSequence.value,
         partToken            |-> partToken.value,
         timestamp2           |-> timestamp2.value,
         symbolLong           |-> symbolLong.value,
         tradeId              |-> tradeId.value,
         origTradeId          |-> origTradeId.value,
         origTtExempt         |-> origTtExempt.value,
         origTrcond           |-> origTrcond.value,
         origSsday            |-> origSsday.value,
         side                 |-> side.value,
         origPrice            |-> origPrice.value,
         origVolumeFractional |-> origVolumeFractional.value,
         newTtExempt          |-> newTtExempt.value,
         newTrcond            |-> newTrcond.value,
         newSsday             |-> newSsday.value,
         newPrice             |-> newPrice.value,
         newVolumeFractional  |-> newVolumeFractional.value ], newVolumeFractional.rest)

ZeroFractionalTradeCorrectionMessage ==
    [ orig                 |-> [i \in 1 .. 2 |-> 0],
      timestamp1           |-> [i \in 1 .. 8 |-> 0],
      feedSequence         |-> [i \in 1 .. 8 |-> 0],
      partToken            |-> [i \in 1 .. 8 |-> 0],
      timestamp2           |-> [i \in 1 .. 8 |-> 0],
      symbolLong           |-> [i \in 1 .. 11 |-> 0],
      tradeId              |-> [i \in 1 .. 4 |-> 0],
      origTradeId          |-> [i \in 1 .. 4 |-> 0],
      origTtExempt         |-> [i \in 1 .. 1 |-> 0],
      origTrcond           |-> [i \in 1 .. 4 |-> 0],
      origSsday            |-> [i \in 1 .. 2 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      origPrice            |-> [i \in 1 .. 8 |-> 0],
      origVolumeFractional |-> [i \in 1 .. 8 |-> 0],
      newTtExempt          |-> [i \in 1 .. 1 |-> 0],
      newTrcond            |-> [i \in 1 .. 4 |-> 0],
      newSsday             |-> [i \in 1 .. 2 |-> 0],
      newPrice             |-> [i \in 1 .. 8 |-> 0],
      newVolumeFractional  |-> [i \in 1 .. 8 |-> 0] ]

(* Fractional Trade Correction Message at zero, then each field in turn at the values it is checked at *)
CheckedFractionalTradeCorrectionMessage ==
    { ZeroFractionalTradeCorrectionMessage }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.orig = one] : one \in Sample(2) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.feedSequence = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.partToken = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.timestamp2 = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.origTradeId = one] : one \in Sample(4) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.origTtExempt = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.origTrcond = one] : one \in Sample(4) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.origSsday = one] : one \in Sample(2) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.origPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.origVolumeFractional = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.newTtExempt = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.newTrcond = one] : one \in Sample(4) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.newSsday = one] : one \in Sample(2) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.newPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.newVolumeFractional = one] : one \in Sample(8) }

(***************************************************************************)
(* Fractional As Of Trade Report Message: 74 bytes                         *)
(***************************************************************************)

FractionalAsOfTradeReportMessage ==
    [ orig             : Sample(2),
      timestamp1       : Sample(8),
      feedSequence     : Sample(8),
      partToken        : Sample(8),
      symbolLong       : Sample(11),
      tradeId          : Sample(4),
      ttExempt         : Sample(1),
      trcond           : Sample(4),
      ssday            : Sample(2),
      side             : Sample(1),
      price            : Sample(8),
      volumeFractional : Sample(8),
      tradeTime        : Sample(8),
      reversal         : Sample(1) ]

EncodeFractionalAsOfTradeReportMessage(message) ==
    message.orig
        \o message.timestamp1
        \o message.feedSequence
        \o message.partToken
        \o message.symbolLong
        \o message.tradeId
        \o message.ttExempt
        \o message.trcond
        \o message.ssday
        \o message.side
        \o message.price
        \o message.volumeFractional
        \o message.tradeTime
        \o message.reversal

DecodeFractionalAsOfTradeReportMessage(bytes) ==
    LET orig == ReadBytes(bytes, 2) IN IF ~orig.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(orig.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET feedSequence == ReadBytes(timestamp1.rest, 8) IN IF ~feedSequence.ok THEN Fail ELSE
    LET partToken == ReadBytes(feedSequence.rest, 8) IN IF ~partToken.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(partToken.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET tradeId == ReadBytes(symbolLong.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET ttExempt == ReadBytes(tradeId.rest, 1) IN IF ~ttExempt.ok THEN Fail ELSE
    LET trcond == ReadBytes(ttExempt.rest, 4) IN IF ~trcond.ok THEN Fail ELSE
    LET ssday == ReadBytes(trcond.rest, 2) IN IF ~ssday.ok THEN Fail ELSE
    LET side == ReadBytes(ssday.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadBytes(side.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET volumeFractional == ReadBytes(price.rest, 8) IN IF ~volumeFractional.ok THEN Fail ELSE
    LET tradeTime == ReadBytes(volumeFractional.rest, 8) IN IF ~tradeTime.ok THEN Fail ELSE
    LET reversal == ReadBytes(tradeTime.rest, 1) IN IF ~reversal.ok THEN Fail ELSE
    Ok([ orig             |-> orig.value,
         timestamp1       |-> timestamp1.value,
         feedSequence     |-> feedSequence.value,
         partToken        |-> partToken.value,
         symbolLong       |-> symbolLong.value,
         tradeId          |-> tradeId.value,
         ttExempt         |-> ttExempt.value,
         trcond           |-> trcond.value,
         ssday            |-> ssday.value,
         side             |-> side.value,
         price            |-> price.value,
         volumeFractional |-> volumeFractional.value,
         tradeTime        |-> tradeTime.value,
         reversal         |-> reversal.value ], reversal.rest)

ZeroFractionalAsOfTradeReportMessage ==
    [ orig             |-> [i \in 1 .. 2 |-> 0],
      timestamp1       |-> [i \in 1 .. 8 |-> 0],
      feedSequence     |-> [i \in 1 .. 8 |-> 0],
      partToken        |-> [i \in 1 .. 8 |-> 0],
      symbolLong       |-> [i \in 1 .. 11 |-> 0],
      tradeId          |-> [i \in 1 .. 4 |-> 0],
      ttExempt         |-> [i \in 1 .. 1 |-> 0],
      trcond           |-> [i \in 1 .. 4 |-> 0],
      ssday            |-> [i \in 1 .. 2 |-> 0],
      side             |-> [i \in 1 .. 1 |-> 0],
      price            |-> [i \in 1 .. 8 |-> 0],
      volumeFractional |-> [i \in 1 .. 8 |-> 0],
      tradeTime        |-> [i \in 1 .. 8 |-> 0],
      reversal         |-> [i \in 1 .. 1 |-> 0] ]

(* Fractional As Of Trade Report Message at zero, then each field in turn at the values it is checked at *)
CheckedFractionalAsOfTradeReportMessage ==
    { ZeroFractionalAsOfTradeReportMessage }
        \cup { [ZeroFractionalAsOfTradeReportMessage EXCEPT !.orig = one] : one \in Sample(2) }
        \cup { [ZeroFractionalAsOfTradeReportMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroFractionalAsOfTradeReportMessage EXCEPT !.feedSequence = one] : one \in Sample(8) }
        \cup { [ZeroFractionalAsOfTradeReportMessage EXCEPT !.partToken = one] : one \in Sample(8) }
        \cup { [ZeroFractionalAsOfTradeReportMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroFractionalAsOfTradeReportMessage EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroFractionalAsOfTradeReportMessage EXCEPT !.ttExempt = one] : one \in Sample(1) }
        \cup { [ZeroFractionalAsOfTradeReportMessage EXCEPT !.trcond = one] : one \in Sample(4) }
        \cup { [ZeroFractionalAsOfTradeReportMessage EXCEPT !.ssday = one] : one \in Sample(2) }
        \cup { [ZeroFractionalAsOfTradeReportMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroFractionalAsOfTradeReportMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroFractionalAsOfTradeReportMessage EXCEPT !.volumeFractional = one] : one \in Sample(8) }
        \cup { [ZeroFractionalAsOfTradeReportMessage EXCEPT !.tradeTime = one] : one \in Sample(8) }
        \cup { [ZeroFractionalAsOfTradeReportMessage EXCEPT !.reversal = one] : one \in Sample(1) }

(***************************************************************************)
(* Inbound Trade Messages Message Payload, selected by Inbound Trade       *)
(* Messages Message Type                                                   *)
(***************************************************************************)

RegularTradeReportMessageCode == 69  \* "E"
TradeCancelErrorMessageCode == 73  \* "I"
TradeCorrectionMessageCode == 74  \* "J"
AsOfTradeReportMessageCode == 72  \* "H"
FractionalRegularTradeReportMessageCode == 75  \* "K"
FractionalTradeCancelErrorMessageCode == 79  \* "O"
FractionalTradeCorrectionMessageCode == 80  \* "P"
FractionalAsOfTradeReportMessageCode == 81  \* "Q"

InboundTradeMessagesMessagePayload ==
    [ tag : {RegularTradeReportMessageCode}, body : RegularTradeReportMessage ]
        \cup [ tag : {TradeCancelErrorMessageCode}, body : TradeCancelErrorMessage ]
        \cup [ tag : {TradeCorrectionMessageCode}, body : TradeCorrectionMessage ]
        \cup [ tag : {AsOfTradeReportMessageCode}, body : AsOfTradeReportMessage ]
        \cup [ tag : {FractionalRegularTradeReportMessageCode}, body : FractionalRegularTradeReportMessage ]
        \cup [ tag : {FractionalTradeCancelErrorMessageCode}, body : FractionalTradeCancelErrorMessage ]
        \cup [ tag : {FractionalTradeCorrectionMessageCode}, body : FractionalTradeCorrectionMessage ]
        \cup [ tag : {FractionalAsOfTradeReportMessageCode}, body : FractionalAsOfTradeReportMessage ]

EncodeInboundTradeMessagesMessagePayload(message) ==
    CASE message.tag = RegularTradeReportMessageCode -> EncodeRegularTradeReportMessage(message.body)
      [] message.tag = TradeCancelErrorMessageCode -> EncodeTradeCancelErrorMessage(message.body)
      [] message.tag = TradeCorrectionMessageCode -> EncodeTradeCorrectionMessage(message.body)
      [] message.tag = AsOfTradeReportMessageCode -> EncodeAsOfTradeReportMessage(message.body)
      [] message.tag = FractionalRegularTradeReportMessageCode -> EncodeFractionalRegularTradeReportMessage(message.body)
      [] message.tag = FractionalTradeCancelErrorMessageCode -> EncodeFractionalTradeCancelErrorMessage(message.body)
      [] message.tag = FractionalTradeCorrectionMessageCode -> EncodeFractionalTradeCorrectionMessage(message.body)
      [] message.tag = FractionalAsOfTradeReportMessageCode -> EncodeFractionalAsOfTradeReportMessage(message.body)

DecodeInboundTradeMessagesMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = RegularTradeReportMessageCode -> DecodeRegularTradeReportMessage(bytes)
              [] tag = TradeCancelErrorMessageCode -> DecodeTradeCancelErrorMessage(bytes)
              [] tag = TradeCorrectionMessageCode -> DecodeTradeCorrectionMessage(bytes)
              [] tag = AsOfTradeReportMessageCode -> DecodeAsOfTradeReportMessage(bytes)
              [] tag = FractionalRegularTradeReportMessageCode -> DecodeFractionalRegularTradeReportMessage(bytes)
              [] tag = FractionalTradeCancelErrorMessageCode -> DecodeFractionalTradeCancelErrorMessage(bytes)
              [] tag = FractionalTradeCorrectionMessageCode -> DecodeFractionalTradeCorrectionMessage(bytes)
              [] tag = FractionalAsOfTradeReportMessageCode -> DecodeFractionalAsOfTradeReportMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroInboundTradeMessagesMessagePayload == [tag |-> RegularTradeReportMessageCode, body |-> ZeroRegularTradeReportMessage]

(* Each Inbound Trade Messages Message Payload in turn, at the values the message it names is checked at *)
CheckedInboundTradeMessagesMessagePayload ==
    { [tag |-> RegularTradeReportMessageCode, body |-> one] : one \in CheckedRegularTradeReportMessage }
        \cup { [tag |-> TradeCancelErrorMessageCode, body |-> one] : one \in CheckedTradeCancelErrorMessage }
        \cup { [tag |-> TradeCorrectionMessageCode, body |-> one] : one \in CheckedTradeCorrectionMessage }
        \cup { [tag |-> AsOfTradeReportMessageCode, body |-> one] : one \in CheckedAsOfTradeReportMessage }
        \cup { [tag |-> FractionalRegularTradeReportMessageCode, body |-> one] : one \in CheckedFractionalRegularTradeReportMessage }
        \cup { [tag |-> FractionalTradeCancelErrorMessageCode, body |-> one] : one \in CheckedFractionalTradeCancelErrorMessage }
        \cup { [tag |-> FractionalTradeCorrectionMessageCode, body |-> one] : one \in CheckedFractionalTradeCorrectionMessage }
        \cup { [tag |-> FractionalAsOfTradeReportMessageCode, body |-> one] : one \in CheckedFractionalAsOfTradeReportMessage }

(***************************************************************************)
(* Inbound Trade Messages Message                                          *)
(***************************************************************************)

InboundTradeMessagesMessage ==
    [ inboundTradeMessagesMessagePayload : InboundTradeMessagesMessagePayload ]

EncodeInboundTradeMessagesMessage(message) ==
    EncodeUIntBE(message.inboundTradeMessagesMessagePayload.tag, 1)
        \o EncodeInboundTradeMessagesMessagePayload(message.inboundTradeMessagesMessagePayload)

DecodeInboundTradeMessagesMessage(bytes) ==
    LET inboundTradeMessagesMessageType == ReadUIntBE(bytes, 1) IN IF ~inboundTradeMessagesMessageType.ok THEN Fail ELSE
    LET inboundTradeMessagesMessagePayload == DecodeInboundTradeMessagesMessagePayload(inboundTradeMessagesMessageType.value, inboundTradeMessagesMessageType.rest) IN IF ~inboundTradeMessagesMessagePayload.ok THEN Fail ELSE
    Ok([ inboundTradeMessagesMessagePayload |-> inboundTradeMessagesMessagePayload.value ], inboundTradeMessagesMessagePayload.rest)

ZeroInboundTradeMessagesMessage ==
    [ inboundTradeMessagesMessagePayload |-> ZeroInboundTradeMessagesMessagePayload ]

(* Inbound Trade Messages Message at zero, then each field in turn at the values it is checked at *)
CheckedInboundTradeMessagesMessage ==
    { ZeroInboundTradeMessagesMessage }
        \cup { [ZeroInboundTradeMessagesMessage EXCEPT !.inboundTradeMessagesMessagePayload = one] : one \in CheckedInboundTradeMessagesMessagePayload }

(***************************************************************************)
(* General Administrative Message                                          *)
(***************************************************************************)

GeneralAdministrativeMessage ==
    [ orig         : Sample(2),
      timestamp1   : Sample(8),
      feedSequence : Sample(8),
      partToken    : Sample(8),
      textLen      : Sample(2),
      text         : SampleBytes ]

EncodeGeneralAdministrativeMessage(message) ==
    message.orig
        \o message.timestamp1
        \o message.feedSequence
        \o message.partToken
        \o message.textLen
        \o message.text

DecodeGeneralAdministrativeMessage(bytes) ==
    LET orig == ReadBytes(bytes, 2) IN IF ~orig.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(orig.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET feedSequence == ReadBytes(timestamp1.rest, 8) IN IF ~feedSequence.ok THEN Fail ELSE
    LET partToken == ReadBytes(feedSequence.rest, 8) IN IF ~partToken.ok THEN Fail ELSE
    LET textLen == ReadBytes(partToken.rest, 2) IN IF ~textLen.ok THEN Fail ELSE
    LET text == Ok(textLen.rest, << >>) IN IF ~text.ok THEN Fail ELSE
    Ok([ orig         |-> orig.value,
         timestamp1   |-> timestamp1.value,
         feedSequence |-> feedSequence.value,
         partToken    |-> partToken.value,
         textLen      |-> textLen.value,
         text         |-> text.value ], text.rest)

ZeroGeneralAdministrativeMessage ==
    [ orig         |-> [i \in 1 .. 2 |-> 0],
      timestamp1   |-> [i \in 1 .. 8 |-> 0],
      feedSequence |-> [i \in 1 .. 8 |-> 0],
      partToken    |-> [i \in 1 .. 8 |-> 0],
      textLen      |-> [i \in 1 .. 2 |-> 0],
      text         |-> << >> ]

(* General Administrative Message at zero, then each field in turn at the values it is checked at *)
CheckedGeneralAdministrativeMessage ==
    { ZeroGeneralAdministrativeMessage }
        \cup { [ZeroGeneralAdministrativeMessage EXCEPT !.orig = one] : one \in Sample(2) }
        \cup { [ZeroGeneralAdministrativeMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroGeneralAdministrativeMessage EXCEPT !.feedSequence = one] : one \in Sample(8) }
        \cup { [ZeroGeneralAdministrativeMessage EXCEPT !.partToken = one] : one \in Sample(8) }
        \cup { [ZeroGeneralAdministrativeMessage EXCEPT !.textLen = one] : one \in Sample(2) }
        \cup { [ZeroGeneralAdministrativeMessage EXCEPT !.text = one] : one \in SampleBytes }

(***************************************************************************)
(* Trading Action Message: 56 bytes                                        *)
(***************************************************************************)

TradingActionMessage ==
    [ orig           : Sample(2),
      timestamp1     : Sample(8),
      feedSequence   : Sample(8),
      partToken      : Sample(8),
      symbolLong     : Sample(11),
      action         : Sample(1),
      actionSequence : Sample(4),
      actionTime     : Sample(8),
      reason         : Sample(6) ]

EncodeTradingActionMessage(message) ==
    message.orig
        \o message.timestamp1
        \o message.feedSequence
        \o message.partToken
        \o message.symbolLong
        \o message.action
        \o message.actionSequence
        \o message.actionTime
        \o message.reason

DecodeTradingActionMessage(bytes) ==
    LET orig == ReadBytes(bytes, 2) IN IF ~orig.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(orig.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET feedSequence == ReadBytes(timestamp1.rest, 8) IN IF ~feedSequence.ok THEN Fail ELSE
    LET partToken == ReadBytes(feedSequence.rest, 8) IN IF ~partToken.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(partToken.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET action == ReadBytes(symbolLong.rest, 1) IN IF ~action.ok THEN Fail ELSE
    LET actionSequence == ReadBytes(action.rest, 4) IN IF ~actionSequence.ok THEN Fail ELSE
    LET actionTime == ReadBytes(actionSequence.rest, 8) IN IF ~actionTime.ok THEN Fail ELSE
    LET reason == ReadBytes(actionTime.rest, 6) IN IF ~reason.ok THEN Fail ELSE
    Ok([ orig           |-> orig.value,
         timestamp1     |-> timestamp1.value,
         feedSequence   |-> feedSequence.value,
         partToken      |-> partToken.value,
         symbolLong     |-> symbolLong.value,
         action         |-> action.value,
         actionSequence |-> actionSequence.value,
         actionTime     |-> actionTime.value,
         reason         |-> reason.value ], reason.rest)

ZeroTradingActionMessage ==
    [ orig           |-> [i \in 1 .. 2 |-> 0],
      timestamp1     |-> [i \in 1 .. 8 |-> 0],
      feedSequence   |-> [i \in 1 .. 8 |-> 0],
      partToken      |-> [i \in 1 .. 8 |-> 0],
      symbolLong     |-> [i \in 1 .. 11 |-> 0],
      action         |-> [i \in 1 .. 1 |-> 0],
      actionSequence |-> [i \in 1 .. 4 |-> 0],
      actionTime     |-> [i \in 1 .. 8 |-> 0],
      reason         |-> [i \in 1 .. 6 |-> 0] ]

(* Trading Action Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingActionMessage ==
    { ZeroTradingActionMessage }
        \cup { [ZeroTradingActionMessage EXCEPT !.orig = one] : one \in Sample(2) }
        \cup { [ZeroTradingActionMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroTradingActionMessage EXCEPT !.feedSequence = one] : one \in Sample(8) }
        \cup { [ZeroTradingActionMessage EXCEPT !.partToken = one] : one \in Sample(8) }
        \cup { [ZeroTradingActionMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroTradingActionMessage EXCEPT !.action = one] : one \in Sample(1) }
        \cup { [ZeroTradingActionMessage EXCEPT !.actionSequence = one] : one \in Sample(4) }
        \cup { [ZeroTradingActionMessage EXCEPT !.actionTime = one] : one \in Sample(8) }
        \cup { [ZeroTradingActionMessage EXCEPT !.reason = one] : one \in Sample(6) }

(***************************************************************************)
(* Market Center Trading Action Message: 46 bytes                          *)
(***************************************************************************)

MarketCenterTradingActionMessage ==
    [ orig         : Sample(2),
      timestamp1   : Sample(8),
      feedSequence : Sample(8),
      partToken    : Sample(8),
      symbolLong   : Sample(11),
      action       : Sample(1),
      actionTime   : Sample(8) ]

EncodeMarketCenterTradingActionMessage(message) ==
    message.orig
        \o message.timestamp1
        \o message.feedSequence
        \o message.partToken
        \o message.symbolLong
        \o message.action
        \o message.actionTime

DecodeMarketCenterTradingActionMessage(bytes) ==
    LET orig == ReadBytes(bytes, 2) IN IF ~orig.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(orig.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET feedSequence == ReadBytes(timestamp1.rest, 8) IN IF ~feedSequence.ok THEN Fail ELSE
    LET partToken == ReadBytes(feedSequence.rest, 8) IN IF ~partToken.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(partToken.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET action == ReadBytes(symbolLong.rest, 1) IN IF ~action.ok THEN Fail ELSE
    LET actionTime == ReadBytes(action.rest, 8) IN IF ~actionTime.ok THEN Fail ELSE
    Ok([ orig         |-> orig.value,
         timestamp1   |-> timestamp1.value,
         feedSequence |-> feedSequence.value,
         partToken    |-> partToken.value,
         symbolLong   |-> symbolLong.value,
         action       |-> action.value,
         actionTime   |-> actionTime.value ], actionTime.rest)

ZeroMarketCenterTradingActionMessage ==
    [ orig         |-> [i \in 1 .. 2 |-> 0],
      timestamp1   |-> [i \in 1 .. 8 |-> 0],
      feedSequence |-> [i \in 1 .. 8 |-> 0],
      partToken    |-> [i \in 1 .. 8 |-> 0],
      symbolLong   |-> [i \in 1 .. 11 |-> 0],
      action       |-> [i \in 1 .. 1 |-> 0],
      actionTime   |-> [i \in 1 .. 8 |-> 0] ]

(* Market Center Trading Action Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketCenterTradingActionMessage ==
    { ZeroMarketCenterTradingActionMessage }
        \cup { [ZeroMarketCenterTradingActionMessage EXCEPT !.orig = one] : one \in Sample(2) }
        \cup { [ZeroMarketCenterTradingActionMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroMarketCenterTradingActionMessage EXCEPT !.feedSequence = one] : one \in Sample(8) }
        \cup { [ZeroMarketCenterTradingActionMessage EXCEPT !.partToken = one] : one \in Sample(8) }
        \cup { [ZeroMarketCenterTradingActionMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroMarketCenterTradingActionMessage EXCEPT !.action = one] : one \in Sample(1) }
        \cup { [ZeroMarketCenterTradingActionMessage EXCEPT !.actionTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Market Center Mass Trading Action Message: 57 bytes                     *)
(***************************************************************************)

MarketCenterMassTradingActionMessage ==
    [ orig          : Sample(2),
      timestamp1    : Sample(8),
      feedSequence  : Sample(8),
      partToken     : Sample(8),
      firstSecurity : Sample(11),
      lastSecurity  : Sample(11),
      action        : Sample(1),
      actionTime    : Sample(8) ]

EncodeMarketCenterMassTradingActionMessage(message) ==
    message.orig
        \o message.timestamp1
        \o message.feedSequence
        \o message.partToken
        \o message.firstSecurity
        \o message.lastSecurity
        \o message.action
        \o message.actionTime

DecodeMarketCenterMassTradingActionMessage(bytes) ==
    LET orig == ReadBytes(bytes, 2) IN IF ~orig.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(orig.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET feedSequence == ReadBytes(timestamp1.rest, 8) IN IF ~feedSequence.ok THEN Fail ELSE
    LET partToken == ReadBytes(feedSequence.rest, 8) IN IF ~partToken.ok THEN Fail ELSE
    LET firstSecurity == ReadBytes(partToken.rest, 11) IN IF ~firstSecurity.ok THEN Fail ELSE
    LET lastSecurity == ReadBytes(firstSecurity.rest, 11) IN IF ~lastSecurity.ok THEN Fail ELSE
    LET action == ReadBytes(lastSecurity.rest, 1) IN IF ~action.ok THEN Fail ELSE
    LET actionTime == ReadBytes(action.rest, 8) IN IF ~actionTime.ok THEN Fail ELSE
    Ok([ orig          |-> orig.value,
         timestamp1    |-> timestamp1.value,
         feedSequence  |-> feedSequence.value,
         partToken     |-> partToken.value,
         firstSecurity |-> firstSecurity.value,
         lastSecurity  |-> lastSecurity.value,
         action        |-> action.value,
         actionTime    |-> actionTime.value ], actionTime.rest)

ZeroMarketCenterMassTradingActionMessage ==
    [ orig          |-> [i \in 1 .. 2 |-> 0],
      timestamp1    |-> [i \in 1 .. 8 |-> 0],
      feedSequence  |-> [i \in 1 .. 8 |-> 0],
      partToken     |-> [i \in 1 .. 8 |-> 0],
      firstSecurity |-> [i \in 1 .. 11 |-> 0],
      lastSecurity  |-> [i \in 1 .. 11 |-> 0],
      action        |-> [i \in 1 .. 1 |-> 0],
      actionTime    |-> [i \in 1 .. 8 |-> 0] ]

(* Market Center Mass Trading Action Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketCenterMassTradingActionMessage ==
    { ZeroMarketCenterMassTradingActionMessage }
        \cup { [ZeroMarketCenterMassTradingActionMessage EXCEPT !.orig = one] : one \in Sample(2) }
        \cup { [ZeroMarketCenterMassTradingActionMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroMarketCenterMassTradingActionMessage EXCEPT !.feedSequence = one] : one \in Sample(8) }
        \cup { [ZeroMarketCenterMassTradingActionMessage EXCEPT !.partToken = one] : one \in Sample(8) }
        \cup { [ZeroMarketCenterMassTradingActionMessage EXCEPT !.firstSecurity = one] : one \in Sample(11) }
        \cup { [ZeroMarketCenterMassTradingActionMessage EXCEPT !.lastSecurity = one] : one \in Sample(11) }
        \cup { [ZeroMarketCenterMassTradingActionMessage EXCEPT !.action = one] : one \in Sample(1) }
        \cup { [ZeroMarketCenterMassTradingActionMessage EXCEPT !.actionTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Reg Sho Short Sale Price Test Restricted Indicator Message: 38 bytes    *)
(***************************************************************************)

RegShoShortSalePriceTestRestrictedIndicatorMessage ==
    [ orig         : Sample(2),
      timestamp1   : Sample(8),
      feedSequence : Sample(8),
      partToken    : Sample(8),
      symbolLong   : Sample(11),
      action       : Sample(1) ]

EncodeRegShoShortSalePriceTestRestrictedIndicatorMessage(message) ==
    message.orig
        \o message.timestamp1
        \o message.feedSequence
        \o message.partToken
        \o message.symbolLong
        \o message.action

DecodeRegShoShortSalePriceTestRestrictedIndicatorMessage(bytes) ==
    LET orig == ReadBytes(bytes, 2) IN IF ~orig.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(orig.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET feedSequence == ReadBytes(timestamp1.rest, 8) IN IF ~feedSequence.ok THEN Fail ELSE
    LET partToken == ReadBytes(feedSequence.rest, 8) IN IF ~partToken.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(partToken.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET action == ReadBytes(symbolLong.rest, 1) IN IF ~action.ok THEN Fail ELSE
    Ok([ orig         |-> orig.value,
         timestamp1   |-> timestamp1.value,
         feedSequence |-> feedSequence.value,
         partToken    |-> partToken.value,
         symbolLong   |-> symbolLong.value,
         action       |-> action.value ], action.rest)

ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage ==
    [ orig         |-> [i \in 1 .. 2 |-> 0],
      timestamp1   |-> [i \in 1 .. 8 |-> 0],
      feedSequence |-> [i \in 1 .. 8 |-> 0],
      partToken    |-> [i \in 1 .. 8 |-> 0],
      symbolLong   |-> [i \in 1 .. 11 |-> 0],
      action       |-> [i \in 1 .. 1 |-> 0] ]

(* Reg Sho Short Sale Price Test Restricted Indicator Message at zero, then each field in turn at the values it is checked at *)
CheckedRegShoShortSalePriceTestRestrictedIndicatorMessage ==
    { ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.orig = one] : one \in Sample(2) }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.feedSequence = one] : one \in Sample(8) }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.partToken = one] : one \in Sample(8) }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.action = one] : one \in Sample(1) }

(***************************************************************************)
(* Opening Reference Midpoint Price Message: 45 bytes                      *)
(***************************************************************************)

OpeningReferenceMidpointPriceMessage ==
    [ orig         : Sample(2),
      timestamp1   : Sample(8),
      feedSequence : Sample(8),
      partToken    : Sample(8),
      symbolLong   : Sample(11),
      price        : Sample(8) ]

EncodeOpeningReferenceMidpointPriceMessage(message) ==
    message.orig
        \o message.timestamp1
        \o message.feedSequence
        \o message.partToken
        \o message.symbolLong
        \o message.price

DecodeOpeningReferenceMidpointPriceMessage(bytes) ==
    LET orig == ReadBytes(bytes, 2) IN IF ~orig.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(orig.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET feedSequence == ReadBytes(timestamp1.rest, 8) IN IF ~feedSequence.ok THEN Fail ELSE
    LET partToken == ReadBytes(feedSequence.rest, 8) IN IF ~partToken.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(partToken.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET price == ReadBytes(symbolLong.rest, 8) IN IF ~price.ok THEN Fail ELSE
    Ok([ orig         |-> orig.value,
         timestamp1   |-> timestamp1.value,
         feedSequence |-> feedSequence.value,
         partToken    |-> partToken.value,
         symbolLong   |-> symbolLong.value,
         price        |-> price.value ], price.rest)

ZeroOpeningReferenceMidpointPriceMessage ==
    [ orig         |-> [i \in 1 .. 2 |-> 0],
      timestamp1   |-> [i \in 1 .. 8 |-> 0],
      feedSequence |-> [i \in 1 .. 8 |-> 0],
      partToken    |-> [i \in 1 .. 8 |-> 0],
      symbolLong   |-> [i \in 1 .. 11 |-> 0],
      price        |-> [i \in 1 .. 8 |-> 0] ]

(* Opening Reference Midpoint Price Message at zero, then each field in turn at the values it is checked at *)
CheckedOpeningReferenceMidpointPriceMessage ==
    { ZeroOpeningReferenceMidpointPriceMessage }
        \cup { [ZeroOpeningReferenceMidpointPriceMessage EXCEPT !.orig = one] : one \in Sample(2) }
        \cup { [ZeroOpeningReferenceMidpointPriceMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroOpeningReferenceMidpointPriceMessage EXCEPT !.feedSequence = one] : one \in Sample(8) }
        \cup { [ZeroOpeningReferenceMidpointPriceMessage EXCEPT !.partToken = one] : one \in Sample(8) }
        \cup { [ZeroOpeningReferenceMidpointPriceMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroOpeningReferenceMidpointPriceMessage EXCEPT !.price = one] : one \in Sample(8) }

(***************************************************************************)
(* T 1 Adjusted Closing Price Message: 45 bytes                            *)
(***************************************************************************)

T1AdjustedClosingPriceMessage ==
    [ orig         : Sample(2),
      timestamp1   : Sample(8),
      feedSequence : Sample(8),
      partToken    : Sample(8),
      symbolLong   : Sample(11),
      price        : Sample(8) ]

EncodeT1AdjustedClosingPriceMessage(message) ==
    message.orig
        \o message.timestamp1
        \o message.feedSequence
        \o message.partToken
        \o message.symbolLong
        \o message.price

DecodeT1AdjustedClosingPriceMessage(bytes) ==
    LET orig == ReadBytes(bytes, 2) IN IF ~orig.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(orig.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET feedSequence == ReadBytes(timestamp1.rest, 8) IN IF ~feedSequence.ok THEN Fail ELSE
    LET partToken == ReadBytes(feedSequence.rest, 8) IN IF ~partToken.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(partToken.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET price == ReadBytes(symbolLong.rest, 8) IN IF ~price.ok THEN Fail ELSE
    Ok([ orig         |-> orig.value,
         timestamp1   |-> timestamp1.value,
         feedSequence |-> feedSequence.value,
         partToken    |-> partToken.value,
         symbolLong   |-> symbolLong.value,
         price        |-> price.value ], price.rest)

ZeroT1AdjustedClosingPriceMessage ==
    [ orig         |-> [i \in 1 .. 2 |-> 0],
      timestamp1   |-> [i \in 1 .. 8 |-> 0],
      feedSequence |-> [i \in 1 .. 8 |-> 0],
      partToken    |-> [i \in 1 .. 8 |-> 0],
      symbolLong   |-> [i \in 1 .. 11 |-> 0],
      price        |-> [i \in 1 .. 8 |-> 0] ]

(* T 1 Adjusted Closing Price Message at zero, then each field in turn at the values it is checked at *)
CheckedT1AdjustedClosingPriceMessage ==
    { ZeroT1AdjustedClosingPriceMessage }
        \cup { [ZeroT1AdjustedClosingPriceMessage EXCEPT !.orig = one] : one \in Sample(2) }
        \cup { [ZeroT1AdjustedClosingPriceMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroT1AdjustedClosingPriceMessage EXCEPT !.feedSequence = one] : one \in Sample(8) }
        \cup { [ZeroT1AdjustedClosingPriceMessage EXCEPT !.partToken = one] : one \in Sample(8) }
        \cup { [ZeroT1AdjustedClosingPriceMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroT1AdjustedClosingPriceMessage EXCEPT !.price = one] : one \in Sample(8) }

(***************************************************************************)
(* Market Open Message: 26 bytes                                           *)
(***************************************************************************)

MarketOpenMessage ==
    [ orig         : Sample(2),
      timestamp1   : Sample(8),
      feedSequence : Sample(8),
      partToken    : Sample(8) ]

EncodeMarketOpenMessage(message) ==
    message.orig
        \o message.timestamp1
        \o message.feedSequence
        \o message.partToken

DecodeMarketOpenMessage(bytes) ==
    LET orig == ReadBytes(bytes, 2) IN IF ~orig.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(orig.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET feedSequence == ReadBytes(timestamp1.rest, 8) IN IF ~feedSequence.ok THEN Fail ELSE
    LET partToken == ReadBytes(feedSequence.rest, 8) IN IF ~partToken.ok THEN Fail ELSE
    Ok([ orig         |-> orig.value,
         timestamp1   |-> timestamp1.value,
         feedSequence |-> feedSequence.value,
         partToken    |-> partToken.value ], partToken.rest)

ZeroMarketOpenMessage ==
    [ orig         |-> [i \in 1 .. 2 |-> 0],
      timestamp1   |-> [i \in 1 .. 8 |-> 0],
      feedSequence |-> [i \in 1 .. 8 |-> 0],
      partToken    |-> [i \in 1 .. 8 |-> 0] ]

(* Market Open Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketOpenMessage ==
    { ZeroMarketOpenMessage }
        \cup { [ZeroMarketOpenMessage EXCEPT !.orig = one] : one \in Sample(2) }
        \cup { [ZeroMarketOpenMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroMarketOpenMessage EXCEPT !.feedSequence = one] : one \in Sample(8) }
        \cup { [ZeroMarketOpenMessage EXCEPT !.partToken = one] : one \in Sample(8) }

(***************************************************************************)
(* Market Closed Message: 26 bytes                                         *)
(***************************************************************************)

MarketClosedMessage ==
    [ orig         : Sample(2),
      timestamp1   : Sample(8),
      feedSequence : Sample(8),
      partToken    : Sample(8) ]

EncodeMarketClosedMessage(message) ==
    message.orig
        \o message.timestamp1
        \o message.feedSequence
        \o message.partToken

DecodeMarketClosedMessage(bytes) ==
    LET orig == ReadBytes(bytes, 2) IN IF ~orig.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(orig.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET feedSequence == ReadBytes(timestamp1.rest, 8) IN IF ~feedSequence.ok THEN Fail ELSE
    LET partToken == ReadBytes(feedSequence.rest, 8) IN IF ~partToken.ok THEN Fail ELSE
    Ok([ orig         |-> orig.value,
         timestamp1   |-> timestamp1.value,
         feedSequence |-> feedSequence.value,
         partToken    |-> partToken.value ], partToken.rest)

ZeroMarketClosedMessage ==
    [ orig         |-> [i \in 1 .. 2 |-> 0],
      timestamp1   |-> [i \in 1 .. 8 |-> 0],
      feedSequence |-> [i \in 1 .. 8 |-> 0],
      partToken    |-> [i \in 1 .. 8 |-> 0] ]

(* Market Closed Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketClosedMessage ==
    { ZeroMarketClosedMessage }
        \cup { [ZeroMarketClosedMessage EXCEPT !.orig = one] : one \in Sample(2) }
        \cup { [ZeroMarketClosedMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroMarketClosedMessage EXCEPT !.feedSequence = one] : one \in Sample(8) }
        \cup { [ZeroMarketClosedMessage EXCEPT !.partToken = one] : one \in Sample(8) }

(***************************************************************************)
(* Auction Collar Message: 66 bytes                                        *)
(***************************************************************************)

AuctionCollarMessage ==
    [ orig                 : Sample(2),
      timestamp1           : Sample(8),
      feedSequence         : Sample(8),
      partToken            : Sample(8),
      symbolLong           : Sample(11),
      actionSequence       : Sample(4),
      collarReferencePrice : Sample(8),
      collarUpPrice        : Sample(8),
      collarDownPrice      : Sample(8),
      collarExtension      : Sample(1) ]

EncodeAuctionCollarMessage(message) ==
    message.orig
        \o message.timestamp1
        \o message.feedSequence
        \o message.partToken
        \o message.symbolLong
        \o message.actionSequence
        \o message.collarReferencePrice
        \o message.collarUpPrice
        \o message.collarDownPrice
        \o message.collarExtension

DecodeAuctionCollarMessage(bytes) ==
    LET orig == ReadBytes(bytes, 2) IN IF ~orig.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(orig.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET feedSequence == ReadBytes(timestamp1.rest, 8) IN IF ~feedSequence.ok THEN Fail ELSE
    LET partToken == ReadBytes(feedSequence.rest, 8) IN IF ~partToken.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(partToken.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET actionSequence == ReadBytes(symbolLong.rest, 4) IN IF ~actionSequence.ok THEN Fail ELSE
    LET collarReferencePrice == ReadBytes(actionSequence.rest, 8) IN IF ~collarReferencePrice.ok THEN Fail ELSE
    LET collarUpPrice == ReadBytes(collarReferencePrice.rest, 8) IN IF ~collarUpPrice.ok THEN Fail ELSE
    LET collarDownPrice == ReadBytes(collarUpPrice.rest, 8) IN IF ~collarDownPrice.ok THEN Fail ELSE
    LET collarExtension == ReadBytes(collarDownPrice.rest, 1) IN IF ~collarExtension.ok THEN Fail ELSE
    Ok([ orig                 |-> orig.value,
         timestamp1           |-> timestamp1.value,
         feedSequence         |-> feedSequence.value,
         partToken            |-> partToken.value,
         symbolLong           |-> symbolLong.value,
         actionSequence       |-> actionSequence.value,
         collarReferencePrice |-> collarReferencePrice.value,
         collarUpPrice        |-> collarUpPrice.value,
         collarDownPrice      |-> collarDownPrice.value,
         collarExtension      |-> collarExtension.value ], collarExtension.rest)

ZeroAuctionCollarMessage ==
    [ orig                 |-> [i \in 1 .. 2 |-> 0],
      timestamp1           |-> [i \in 1 .. 8 |-> 0],
      feedSequence         |-> [i \in 1 .. 8 |-> 0],
      partToken            |-> [i \in 1 .. 8 |-> 0],
      symbolLong           |-> [i \in 1 .. 11 |-> 0],
      actionSequence       |-> [i \in 1 .. 4 |-> 0],
      collarReferencePrice |-> [i \in 1 .. 8 |-> 0],
      collarUpPrice        |-> [i \in 1 .. 8 |-> 0],
      collarDownPrice      |-> [i \in 1 .. 8 |-> 0],
      collarExtension      |-> [i \in 1 .. 1 |-> 0] ]

(* Auction Collar Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionCollarMessage ==
    { ZeroAuctionCollarMessage }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.orig = one] : one \in Sample(2) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.feedSequence = one] : one \in Sample(8) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.partToken = one] : one \in Sample(8) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.actionSequence = one] : one \in Sample(4) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.collarReferencePrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.collarUpPrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.collarDownPrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.collarExtension = one] : one \in Sample(1) }

(***************************************************************************)
(* Inbound Administrative Messages Message Payload, selected by Inbound    *)
(* Administrative Messages Message Type                                    *)
(***************************************************************************)

GeneralAdministrativeMessageCode == 65  \* "A"
TradingActionMessageCode == 79  \* "O"
MarketCenterTradingActionMessageCode == 74  \* "J"
MarketCenterMassTradingActionMessageCode == 85  \* "U"
RegShoShortSalePriceTestRestrictedIndicatorMessageCode == 86  \* "V"
OpeningReferenceMidpointPriceMessageCode == 77  \* "M"
T1AdjustedClosingPriceMessageCode == 78  \* "N"
MarketOpenMessageCode == 88  \* "X"
MarketClosedMessageCode == 89  \* "Y"
AuctionCollarMessageCode == 69  \* "E"

InboundAdministrativeMessagesMessagePayload ==
    [ tag : {GeneralAdministrativeMessageCode}, body : GeneralAdministrativeMessage ]
        \cup [ tag : {TradingActionMessageCode}, body : TradingActionMessage ]
        \cup [ tag : {MarketCenterTradingActionMessageCode}, body : MarketCenterTradingActionMessage ]
        \cup [ tag : {MarketCenterMassTradingActionMessageCode}, body : MarketCenterMassTradingActionMessage ]
        \cup [ tag : {RegShoShortSalePriceTestRestrictedIndicatorMessageCode}, body : RegShoShortSalePriceTestRestrictedIndicatorMessage ]
        \cup [ tag : {OpeningReferenceMidpointPriceMessageCode}, body : OpeningReferenceMidpointPriceMessage ]
        \cup [ tag : {T1AdjustedClosingPriceMessageCode}, body : T1AdjustedClosingPriceMessage ]
        \cup [ tag : {MarketOpenMessageCode}, body : MarketOpenMessage ]
        \cup [ tag : {MarketClosedMessageCode}, body : MarketClosedMessage ]
        \cup [ tag : {AuctionCollarMessageCode}, body : AuctionCollarMessage ]

EncodeInboundAdministrativeMessagesMessagePayload(message) ==
    CASE message.tag = GeneralAdministrativeMessageCode -> EncodeGeneralAdministrativeMessage(message.body)
      [] message.tag = TradingActionMessageCode -> EncodeTradingActionMessage(message.body)
      [] message.tag = MarketCenterTradingActionMessageCode -> EncodeMarketCenterTradingActionMessage(message.body)
      [] message.tag = MarketCenterMassTradingActionMessageCode -> EncodeMarketCenterMassTradingActionMessage(message.body)
      [] message.tag = RegShoShortSalePriceTestRestrictedIndicatorMessageCode -> EncodeRegShoShortSalePriceTestRestrictedIndicatorMessage(message.body)
      [] message.tag = OpeningReferenceMidpointPriceMessageCode -> EncodeOpeningReferenceMidpointPriceMessage(message.body)
      [] message.tag = T1AdjustedClosingPriceMessageCode -> EncodeT1AdjustedClosingPriceMessage(message.body)
      [] message.tag = MarketOpenMessageCode -> EncodeMarketOpenMessage(message.body)
      [] message.tag = MarketClosedMessageCode -> EncodeMarketClosedMessage(message.body)
      [] message.tag = AuctionCollarMessageCode -> EncodeAuctionCollarMessage(message.body)

DecodeInboundAdministrativeMessagesMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = GeneralAdministrativeMessageCode -> DecodeGeneralAdministrativeMessage(bytes)
              [] tag = TradingActionMessageCode -> DecodeTradingActionMessage(bytes)
              [] tag = MarketCenterTradingActionMessageCode -> DecodeMarketCenterTradingActionMessage(bytes)
              [] tag = MarketCenterMassTradingActionMessageCode -> DecodeMarketCenterMassTradingActionMessage(bytes)
              [] tag = RegShoShortSalePriceTestRestrictedIndicatorMessageCode -> DecodeRegShoShortSalePriceTestRestrictedIndicatorMessage(bytes)
              [] tag = OpeningReferenceMidpointPriceMessageCode -> DecodeOpeningReferenceMidpointPriceMessage(bytes)
              [] tag = T1AdjustedClosingPriceMessageCode -> DecodeT1AdjustedClosingPriceMessage(bytes)
              [] tag = MarketOpenMessageCode -> DecodeMarketOpenMessage(bytes)
              [] tag = MarketClosedMessageCode -> DecodeMarketClosedMessage(bytes)
              [] tag = AuctionCollarMessageCode -> DecodeAuctionCollarMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroInboundAdministrativeMessagesMessagePayload == [tag |-> GeneralAdministrativeMessageCode, body |-> ZeroGeneralAdministrativeMessage]

(* Each Inbound Administrative Messages Message Payload in turn, at the values the message it names is checked at *)
CheckedInboundAdministrativeMessagesMessagePayload ==
    { [tag |-> GeneralAdministrativeMessageCode, body |-> one] : one \in CheckedGeneralAdministrativeMessage }
        \cup { [tag |-> TradingActionMessageCode, body |-> one] : one \in CheckedTradingActionMessage }
        \cup { [tag |-> MarketCenterTradingActionMessageCode, body |-> one] : one \in CheckedMarketCenterTradingActionMessage }
        \cup { [tag |-> MarketCenterMassTradingActionMessageCode, body |-> one] : one \in CheckedMarketCenterMassTradingActionMessage }
        \cup { [tag |-> RegShoShortSalePriceTestRestrictedIndicatorMessageCode, body |-> one] : one \in CheckedRegShoShortSalePriceTestRestrictedIndicatorMessage }
        \cup { [tag |-> OpeningReferenceMidpointPriceMessageCode, body |-> one] : one \in CheckedOpeningReferenceMidpointPriceMessage }
        \cup { [tag |-> T1AdjustedClosingPriceMessageCode, body |-> one] : one \in CheckedT1AdjustedClosingPriceMessage }
        \cup { [tag |-> MarketOpenMessageCode, body |-> one] : one \in CheckedMarketOpenMessage }
        \cup { [tag |-> MarketClosedMessageCode, body |-> one] : one \in CheckedMarketClosedMessage }
        \cup { [tag |-> AuctionCollarMessageCode, body |-> one] : one \in CheckedAuctionCollarMessage }

(***************************************************************************)
(* Inbound Administrative Messages Message                                 *)
(***************************************************************************)

InboundAdministrativeMessagesMessage ==
    [ inboundAdministrativeMessagesMessagePayload : InboundAdministrativeMessagesMessagePayload ]

EncodeInboundAdministrativeMessagesMessage(message) ==
    EncodeUIntBE(message.inboundAdministrativeMessagesMessagePayload.tag, 1)
        \o EncodeInboundAdministrativeMessagesMessagePayload(message.inboundAdministrativeMessagesMessagePayload)

DecodeInboundAdministrativeMessagesMessage(bytes) ==
    LET inboundAdministrativeMessagesMessageType == ReadUIntBE(bytes, 1) IN IF ~inboundAdministrativeMessagesMessageType.ok THEN Fail ELSE
    LET inboundAdministrativeMessagesMessagePayload == DecodeInboundAdministrativeMessagesMessagePayload(inboundAdministrativeMessagesMessageType.value, inboundAdministrativeMessagesMessageType.rest) IN IF ~inboundAdministrativeMessagesMessagePayload.ok THEN Fail ELSE
    Ok([ inboundAdministrativeMessagesMessagePayload |-> inboundAdministrativeMessagesMessagePayload.value ], inboundAdministrativeMessagesMessagePayload.rest)

ZeroInboundAdministrativeMessagesMessage ==
    [ inboundAdministrativeMessagesMessagePayload |-> ZeroInboundAdministrativeMessagesMessagePayload ]

(* Inbound Administrative Messages Message at zero, then each field in turn at the values it is checked at *)
CheckedInboundAdministrativeMessagesMessage ==
    { ZeroInboundAdministrativeMessagesMessage }
        \cup { [ZeroInboundAdministrativeMessagesMessage EXCEPT !.inboundAdministrativeMessagesMessagePayload = one] : one \in CheckedInboundAdministrativeMessagesMessagePayload }

(***************************************************************************)
(* Sequence Inquiry Message: 26 bytes                                      *)
(***************************************************************************)

SequenceInquiryMessage ==
    [ orig         : Sample(2),
      timestamp1   : Sample(8),
      feedSequence : Sample(8),
      partToken    : Sample(8) ]

EncodeSequenceInquiryMessage(message) ==
    message.orig
        \o message.timestamp1
        \o message.feedSequence
        \o message.partToken

DecodeSequenceInquiryMessage(bytes) ==
    LET orig == ReadBytes(bytes, 2) IN IF ~orig.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(orig.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET feedSequence == ReadBytes(timestamp1.rest, 8) IN IF ~feedSequence.ok THEN Fail ELSE
    LET partToken == ReadBytes(feedSequence.rest, 8) IN IF ~partToken.ok THEN Fail ELSE
    Ok([ orig         |-> orig.value,
         timestamp1   |-> timestamp1.value,
         feedSequence |-> feedSequence.value,
         partToken    |-> partToken.value ], partToken.rest)

ZeroSequenceInquiryMessage ==
    [ orig         |-> [i \in 1 .. 2 |-> 0],
      timestamp1   |-> [i \in 1 .. 8 |-> 0],
      feedSequence |-> [i \in 1 .. 8 |-> 0],
      partToken    |-> [i \in 1 .. 8 |-> 0] ]

(* Sequence Inquiry Message at zero, then each field in turn at the values it is checked at *)
CheckedSequenceInquiryMessage ==
    { ZeroSequenceInquiryMessage }
        \cup { [ZeroSequenceInquiryMessage EXCEPT !.orig = one] : one \in Sample(2) }
        \cup { [ZeroSequenceInquiryMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroSequenceInquiryMessage EXCEPT !.feedSequence = one] : one \in Sample(8) }
        \cup { [ZeroSequenceInquiryMessage EXCEPT !.partToken = one] : one \in Sample(8) }

(***************************************************************************)
(* Symbol State Inquiry Message: 37 bytes                                  *)
(***************************************************************************)

SymbolStateInquiryMessage ==
    [ orig         : Sample(2),
      timestamp1   : Sample(8),
      feedSequence : Sample(8),
      partToken    : Sample(8),
      symbolLong   : Sample(11) ]

EncodeSymbolStateInquiryMessage(message) ==
    message.orig
        \o message.timestamp1
        \o message.feedSequence
        \o message.partToken
        \o message.symbolLong

DecodeSymbolStateInquiryMessage(bytes) ==
    LET orig == ReadBytes(bytes, 2) IN IF ~orig.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(orig.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET feedSequence == ReadBytes(timestamp1.rest, 8) IN IF ~feedSequence.ok THEN Fail ELSE
    LET partToken == ReadBytes(feedSequence.rest, 8) IN IF ~partToken.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(partToken.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    Ok([ orig         |-> orig.value,
         timestamp1   |-> timestamp1.value,
         feedSequence |-> feedSequence.value,
         partToken    |-> partToken.value,
         symbolLong   |-> symbolLong.value ], symbolLong.rest)

ZeroSymbolStateInquiryMessage ==
    [ orig         |-> [i \in 1 .. 2 |-> 0],
      timestamp1   |-> [i \in 1 .. 8 |-> 0],
      feedSequence |-> [i \in 1 .. 8 |-> 0],
      partToken    |-> [i \in 1 .. 8 |-> 0],
      symbolLong   |-> [i \in 1 .. 11 |-> 0] ]

(* Symbol State Inquiry Message at zero, then each field in turn at the values it is checked at *)
CheckedSymbolStateInquiryMessage ==
    { ZeroSymbolStateInquiryMessage }
        \cup { [ZeroSymbolStateInquiryMessage EXCEPT !.orig = one] : one \in Sample(2) }
        \cup { [ZeroSymbolStateInquiryMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroSymbolStateInquiryMessage EXCEPT !.feedSequence = one] : one \in Sample(8) }
        \cup { [ZeroSymbolStateInquiryMessage EXCEPT !.partToken = one] : one \in Sample(8) }
        \cup { [ZeroSymbolStateInquiryMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }

(***************************************************************************)
(* End Of Participant Reporting Message: 26 bytes                          *)
(***************************************************************************)

EndOfParticipantReportingMessage ==
    [ orig         : Sample(2),
      timestamp1   : Sample(8),
      feedSequence : Sample(8),
      partToken    : Sample(8) ]

EncodeEndOfParticipantReportingMessage(message) ==
    message.orig
        \o message.timestamp1
        \o message.feedSequence
        \o message.partToken

DecodeEndOfParticipantReportingMessage(bytes) ==
    LET orig == ReadBytes(bytes, 2) IN IF ~orig.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(orig.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET feedSequence == ReadBytes(timestamp1.rest, 8) IN IF ~feedSequence.ok THEN Fail ELSE
    LET partToken == ReadBytes(feedSequence.rest, 8) IN IF ~partToken.ok THEN Fail ELSE
    Ok([ orig         |-> orig.value,
         timestamp1   |-> timestamp1.value,
         feedSequence |-> feedSequence.value,
         partToken    |-> partToken.value ], partToken.rest)

ZeroEndOfParticipantReportingMessage ==
    [ orig         |-> [i \in 1 .. 2 |-> 0],
      timestamp1   |-> [i \in 1 .. 8 |-> 0],
      feedSequence |-> [i \in 1 .. 8 |-> 0],
      partToken    |-> [i \in 1 .. 8 |-> 0] ]

(* End Of Participant Reporting Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfParticipantReportingMessage ==
    { ZeroEndOfParticipantReportingMessage }
        \cup { [ZeroEndOfParticipantReportingMessage EXCEPT !.orig = one] : one \in Sample(2) }
        \cup { [ZeroEndOfParticipantReportingMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroEndOfParticipantReportingMessage EXCEPT !.feedSequence = one] : one \in Sample(8) }
        \cup { [ZeroEndOfParticipantReportingMessage EXCEPT !.partToken = one] : one \in Sample(8) }

(***************************************************************************)
(* Inbound Control Messages Message Payload, selected by Inbound Control   *)
(* Messages Message Type                                                   *)
(***************************************************************************)

SequenceInquiryMessageCode == 67  \* "C"
SymbolStateInquiryMessageCode == 83  \* "S"
EndOfParticipantReportingMessageCode == 71  \* "G"

InboundControlMessagesMessagePayload ==
    [ tag : {SequenceInquiryMessageCode}, body : SequenceInquiryMessage ]
        \cup [ tag : {SymbolStateInquiryMessageCode}, body : SymbolStateInquiryMessage ]
        \cup [ tag : {EndOfParticipantReportingMessageCode}, body : EndOfParticipantReportingMessage ]

EncodeInboundControlMessagesMessagePayload(message) ==
    CASE message.tag = SequenceInquiryMessageCode -> EncodeSequenceInquiryMessage(message.body)
      [] message.tag = SymbolStateInquiryMessageCode -> EncodeSymbolStateInquiryMessage(message.body)
      [] message.tag = EndOfParticipantReportingMessageCode -> EncodeEndOfParticipantReportingMessage(message.body)

DecodeInboundControlMessagesMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = SequenceInquiryMessageCode -> DecodeSequenceInquiryMessage(bytes)
              [] tag = SymbolStateInquiryMessageCode -> DecodeSymbolStateInquiryMessage(bytes)
              [] tag = EndOfParticipantReportingMessageCode -> DecodeEndOfParticipantReportingMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroInboundControlMessagesMessagePayload == [tag |-> SequenceInquiryMessageCode, body |-> ZeroSequenceInquiryMessage]

(* Each Inbound Control Messages Message Payload in turn, at the values the message it names is checked at *)
CheckedInboundControlMessagesMessagePayload ==
    { [tag |-> SequenceInquiryMessageCode, body |-> one] : one \in CheckedSequenceInquiryMessage }
        \cup { [tag |-> SymbolStateInquiryMessageCode, body |-> one] : one \in CheckedSymbolStateInquiryMessage }
        \cup { [tag |-> EndOfParticipantReportingMessageCode, body |-> one] : one \in CheckedEndOfParticipantReportingMessage }

(***************************************************************************)
(* Inbound Control Messages Message                                        *)
(***************************************************************************)

InboundControlMessagesMessage ==
    [ inboundControlMessagesMessagePayload : InboundControlMessagesMessagePayload ]

EncodeInboundControlMessagesMessage(message) ==
    EncodeUIntBE(message.inboundControlMessagesMessagePayload.tag, 1)
        \o EncodeInboundControlMessagesMessagePayload(message.inboundControlMessagesMessagePayload)

DecodeInboundControlMessagesMessage(bytes) ==
    LET inboundControlMessagesMessageType == ReadUIntBE(bytes, 1) IN IF ~inboundControlMessagesMessageType.ok THEN Fail ELSE
    LET inboundControlMessagesMessagePayload == DecodeInboundControlMessagesMessagePayload(inboundControlMessagesMessageType.value, inboundControlMessagesMessageType.rest) IN IF ~inboundControlMessagesMessagePayload.ok THEN Fail ELSE
    Ok([ inboundControlMessagesMessagePayload |-> inboundControlMessagesMessagePayload.value ], inboundControlMessagesMessagePayload.rest)

ZeroInboundControlMessagesMessage ==
    [ inboundControlMessagesMessagePayload |-> ZeroInboundControlMessagesMessagePayload ]

(* Inbound Control Messages Message at zero, then each field in turn at the values it is checked at *)
CheckedInboundControlMessagesMessage ==
    { ZeroInboundControlMessagesMessage }
        \cup { [ZeroInboundControlMessagesMessage EXCEPT !.inboundControlMessagesMessagePayload = one] : one \in CheckedInboundControlMessagesMessagePayload }

(***************************************************************************)
(* Return General Administrative Message                                   *)
(***************************************************************************)

ReturnGeneralAdministrativeMessage ==
    [ orig    : Sample(2),
      sipTime : Sample(8),
      textLen : Sample(2),
      text    : SampleBytes ]

EncodeReturnGeneralAdministrativeMessage(message) ==
    message.orig
        \o message.sipTime
        \o message.textLen
        \o message.text

DecodeReturnGeneralAdministrativeMessage(bytes) ==
    LET orig == ReadBytes(bytes, 2) IN IF ~orig.ok THEN Fail ELSE
    LET sipTime == ReadBytes(orig.rest, 8) IN IF ~sipTime.ok THEN Fail ELSE
    LET textLen == ReadBytes(sipTime.rest, 2) IN IF ~textLen.ok THEN Fail ELSE
    LET text == Ok(textLen.rest, << >>) IN IF ~text.ok THEN Fail ELSE
    Ok([ orig    |-> orig.value,
         sipTime |-> sipTime.value,
         textLen |-> textLen.value,
         text    |-> text.value ], text.rest)

ZeroReturnGeneralAdministrativeMessage ==
    [ orig    |-> [i \in 1 .. 2 |-> 0],
      sipTime |-> [i \in 1 .. 8 |-> 0],
      textLen |-> [i \in 1 .. 2 |-> 0],
      text    |-> << >> ]

(* Return General Administrative Message at zero, then each field in turn at the values it is checked at *)
CheckedReturnGeneralAdministrativeMessage ==
    { ZeroReturnGeneralAdministrativeMessage }
        \cup { [ZeroReturnGeneralAdministrativeMessage EXCEPT !.orig = one] : one \in Sample(2) }
        \cup { [ZeroReturnGeneralAdministrativeMessage EXCEPT !.sipTime = one] : one \in Sample(8) }
        \cup { [ZeroReturnGeneralAdministrativeMessage EXCEPT !.textLen = one] : one \in Sample(2) }
        \cup { [ZeroReturnGeneralAdministrativeMessage EXCEPT !.text = one] : one \in SampleBytes }

(***************************************************************************)
(* Return Market Center Trading Action Acknowledgement Message: 30 bytes   *)
(***************************************************************************)

ReturnMarketCenterTradingActionAcknowledgementMessage ==
    [ orig       : Sample(2),
      sipTime    : Sample(8),
      symbolLong : Sample(11),
      action     : Sample(1),
      actionTime : Sample(8) ]

EncodeReturnMarketCenterTradingActionAcknowledgementMessage(message) ==
    message.orig
        \o message.sipTime
        \o message.symbolLong
        \o message.action
        \o message.actionTime

DecodeReturnMarketCenterTradingActionAcknowledgementMessage(bytes) ==
    LET orig == ReadBytes(bytes, 2) IN IF ~orig.ok THEN Fail ELSE
    LET sipTime == ReadBytes(orig.rest, 8) IN IF ~sipTime.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(sipTime.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET action == ReadBytes(symbolLong.rest, 1) IN IF ~action.ok THEN Fail ELSE
    LET actionTime == ReadBytes(action.rest, 8) IN IF ~actionTime.ok THEN Fail ELSE
    Ok([ orig       |-> orig.value,
         sipTime    |-> sipTime.value,
         symbolLong |-> symbolLong.value,
         action     |-> action.value,
         actionTime |-> actionTime.value ], actionTime.rest)

ZeroReturnMarketCenterTradingActionAcknowledgementMessage ==
    [ orig       |-> [i \in 1 .. 2 |-> 0],
      sipTime    |-> [i \in 1 .. 8 |-> 0],
      symbolLong |-> [i \in 1 .. 11 |-> 0],
      action     |-> [i \in 1 .. 1 |-> 0],
      actionTime |-> [i \in 1 .. 8 |-> 0] ]

(* Return Market Center Trading Action Acknowledgement Message at zero, then each field in turn at the values it is checked at *)
CheckedReturnMarketCenterTradingActionAcknowledgementMessage ==
    { ZeroReturnMarketCenterTradingActionAcknowledgementMessage }
        \cup { [ZeroReturnMarketCenterTradingActionAcknowledgementMessage EXCEPT !.orig = one] : one \in Sample(2) }
        \cup { [ZeroReturnMarketCenterTradingActionAcknowledgementMessage EXCEPT !.sipTime = one] : one \in Sample(8) }
        \cup { [ZeroReturnMarketCenterTradingActionAcknowledgementMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroReturnMarketCenterTradingActionAcknowledgementMessage EXCEPT !.action = one] : one \in Sample(1) }
        \cup { [ZeroReturnMarketCenterTradingActionAcknowledgementMessage EXCEPT !.actionTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Return Market Open Message: 10 bytes                                    *)
(***************************************************************************)

ReturnMarketOpenMessage ==
    [ orig    : Sample(2),
      sipTime : Sample(8) ]

EncodeReturnMarketOpenMessage(message) ==
    message.orig
        \o message.sipTime

DecodeReturnMarketOpenMessage(bytes) ==
    LET orig == ReadBytes(bytes, 2) IN IF ~orig.ok THEN Fail ELSE
    LET sipTime == ReadBytes(orig.rest, 8) IN IF ~sipTime.ok THEN Fail ELSE
    Ok([ orig    |-> orig.value,
         sipTime |-> sipTime.value ], sipTime.rest)

ZeroReturnMarketOpenMessage ==
    [ orig    |-> [i \in 1 .. 2 |-> 0],
      sipTime |-> [i \in 1 .. 8 |-> 0] ]

(* Return Market Open Message at zero, then each field in turn at the values it is checked at *)
CheckedReturnMarketOpenMessage ==
    { ZeroReturnMarketOpenMessage }
        \cup { [ZeroReturnMarketOpenMessage EXCEPT !.orig = one] : one \in Sample(2) }
        \cup { [ZeroReturnMarketOpenMessage EXCEPT !.sipTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Return Market Closed Message: 10 bytes                                  *)
(***************************************************************************)

ReturnMarketClosedMessage ==
    [ orig    : Sample(2),
      sipTime : Sample(8) ]

EncodeReturnMarketClosedMessage(message) ==
    message.orig
        \o message.sipTime

DecodeReturnMarketClosedMessage(bytes) ==
    LET orig == ReadBytes(bytes, 2) IN IF ~orig.ok THEN Fail ELSE
    LET sipTime == ReadBytes(orig.rest, 8) IN IF ~sipTime.ok THEN Fail ELSE
    Ok([ orig    |-> orig.value,
         sipTime |-> sipTime.value ], sipTime.rest)

ZeroReturnMarketClosedMessage ==
    [ orig    |-> [i \in 1 .. 2 |-> 0],
      sipTime |-> [i \in 1 .. 8 |-> 0] ]

(* Return Market Closed Message at zero, then each field in turn at the values it is checked at *)
CheckedReturnMarketClosedMessage ==
    { ZeroReturnMarketClosedMessage }
        \cup { [ZeroReturnMarketClosedMessage EXCEPT !.orig = one] : one \in Sample(2) }
        \cup { [ZeroReturnMarketClosedMessage EXCEPT !.sipTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Reject Message: 29 bytes                                                *)
(***************************************************************************)

RejectMessage ==
    [ orig            : Sample(2),
      sipTime         : Sample(8),
      feedSequence    : Sample(8),
      partToken       : Sample(8),
      rejectCode      : Sample(2),
      syntaxViolation : Sample(1) ]

EncodeRejectMessage(message) ==
    message.orig
        \o message.sipTime
        \o message.feedSequence
        \o message.partToken
        \o message.rejectCode
        \o message.syntaxViolation

DecodeRejectMessage(bytes) ==
    LET orig == ReadBytes(bytes, 2) IN IF ~orig.ok THEN Fail ELSE
    LET sipTime == ReadBytes(orig.rest, 8) IN IF ~sipTime.ok THEN Fail ELSE
    LET feedSequence == ReadBytes(sipTime.rest, 8) IN IF ~feedSequence.ok THEN Fail ELSE
    LET partToken == ReadBytes(feedSequence.rest, 8) IN IF ~partToken.ok THEN Fail ELSE
    LET rejectCode == ReadBytes(partToken.rest, 2) IN IF ~rejectCode.ok THEN Fail ELSE
    LET syntaxViolation == ReadBytes(rejectCode.rest, 1) IN IF ~syntaxViolation.ok THEN Fail ELSE
    Ok([ orig            |-> orig.value,
         sipTime         |-> sipTime.value,
         feedSequence    |-> feedSequence.value,
         partToken       |-> partToken.value,
         rejectCode      |-> rejectCode.value,
         syntaxViolation |-> syntaxViolation.value ], syntaxViolation.rest)

ZeroRejectMessage ==
    [ orig            |-> [i \in 1 .. 2 |-> 0],
      sipTime         |-> [i \in 1 .. 8 |-> 0],
      feedSequence    |-> [i \in 1 .. 8 |-> 0],
      partToken       |-> [i \in 1 .. 8 |-> 0],
      rejectCode      |-> [i \in 1 .. 2 |-> 0],
      syntaxViolation |-> [i \in 1 .. 1 |-> 0] ]

(* Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedRejectMessage ==
    { ZeroRejectMessage }
        \cup { [ZeroRejectMessage EXCEPT !.orig = one] : one \in Sample(2) }
        \cup { [ZeroRejectMessage EXCEPT !.sipTime = one] : one \in Sample(8) }
        \cup { [ZeroRejectMessage EXCEPT !.feedSequence = one] : one \in Sample(8) }
        \cup { [ZeroRejectMessage EXCEPT !.partToken = one] : one \in Sample(8) }
        \cup { [ZeroRejectMessage EXCEPT !.rejectCode = one] : one \in Sample(2) }
        \cup { [ZeroRejectMessage EXCEPT !.syntaxViolation = one] : one \in Sample(1) }

(***************************************************************************)
(* Sequence Acknowledgement Message: 26 bytes                              *)
(***************************************************************************)

SequenceAcknowledgementMessage ==
    [ orig         : Sample(2),
      sipTime      : Sample(8),
      feedSequence : Sample(8),
      partToken    : Sample(8) ]

EncodeSequenceAcknowledgementMessage(message) ==
    message.orig
        \o message.sipTime
        \o message.feedSequence
        \o message.partToken

DecodeSequenceAcknowledgementMessage(bytes) ==
    LET orig == ReadBytes(bytes, 2) IN IF ~orig.ok THEN Fail ELSE
    LET sipTime == ReadBytes(orig.rest, 8) IN IF ~sipTime.ok THEN Fail ELSE
    LET feedSequence == ReadBytes(sipTime.rest, 8) IN IF ~feedSequence.ok THEN Fail ELSE
    LET partToken == ReadBytes(feedSequence.rest, 8) IN IF ~partToken.ok THEN Fail ELSE
    Ok([ orig         |-> orig.value,
         sipTime      |-> sipTime.value,
         feedSequence |-> feedSequence.value,
         partToken    |-> partToken.value ], partToken.rest)

ZeroSequenceAcknowledgementMessage ==
    [ orig         |-> [i \in 1 .. 2 |-> 0],
      sipTime      |-> [i \in 1 .. 8 |-> 0],
      feedSequence |-> [i \in 1 .. 8 |-> 0],
      partToken    |-> [i \in 1 .. 8 |-> 0] ]

(* Sequence Acknowledgement Message at zero, then each field in turn at the values it is checked at *)
CheckedSequenceAcknowledgementMessage ==
    { ZeroSequenceAcknowledgementMessage }
        \cup { [ZeroSequenceAcknowledgementMessage EXCEPT !.orig = one] : one \in Sample(2) }
        \cup { [ZeroSequenceAcknowledgementMessage EXCEPT !.sipTime = one] : one \in Sample(8) }
        \cup { [ZeroSequenceAcknowledgementMessage EXCEPT !.feedSequence = one] : one \in Sample(8) }
        \cup { [ZeroSequenceAcknowledgementMessage EXCEPT !.partToken = one] : one \in Sample(8) }

(***************************************************************************)
(* Participant Input Warning Message: 42 bytes                             *)
(***************************************************************************)

ParticipantInputWarningMessage ==
    [ orig              : Sample(2),
      sipTime           : Sample(8),
      feedSequence      : Sample(8),
      partToken         : Sample(8),
      warningCode       : Sample(2),
      symbolLong        : Sample(11),
      olAttachmenType   : Sample(1),
      olAttachmentCount : Sample(2) ]

EncodeParticipantInputWarningMessage(message) ==
    message.orig
        \o message.sipTime
        \o message.feedSequence
        \o message.partToken
        \o message.warningCode
        \o message.symbolLong
        \o message.olAttachmenType
        \o message.olAttachmentCount

DecodeParticipantInputWarningMessage(bytes) ==
    LET orig == ReadBytes(bytes, 2) IN IF ~orig.ok THEN Fail ELSE
    LET sipTime == ReadBytes(orig.rest, 8) IN IF ~sipTime.ok THEN Fail ELSE
    LET feedSequence == ReadBytes(sipTime.rest, 8) IN IF ~feedSequence.ok THEN Fail ELSE
    LET partToken == ReadBytes(feedSequence.rest, 8) IN IF ~partToken.ok THEN Fail ELSE
    LET warningCode == ReadBytes(partToken.rest, 2) IN IF ~warningCode.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(warningCode.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET olAttachmenType == ReadBytes(symbolLong.rest, 1) IN IF ~olAttachmenType.ok THEN Fail ELSE
    LET olAttachmentCount == ReadBytes(olAttachmenType.rest, 2) IN IF ~olAttachmentCount.ok THEN Fail ELSE
    Ok([ orig              |-> orig.value,
         sipTime           |-> sipTime.value,
         feedSequence      |-> feedSequence.value,
         partToken         |-> partToken.value,
         warningCode       |-> warningCode.value,
         symbolLong        |-> symbolLong.value,
         olAttachmenType   |-> olAttachmenType.value,
         olAttachmentCount |-> olAttachmentCount.value ], olAttachmentCount.rest)

ZeroParticipantInputWarningMessage ==
    [ orig              |-> [i \in 1 .. 2 |-> 0],
      sipTime           |-> [i \in 1 .. 8 |-> 0],
      feedSequence      |-> [i \in 1 .. 8 |-> 0],
      partToken         |-> [i \in 1 .. 8 |-> 0],
      warningCode       |-> [i \in 1 .. 2 |-> 0],
      symbolLong        |-> [i \in 1 .. 11 |-> 0],
      olAttachmenType   |-> [i \in 1 .. 1 |-> 0],
      olAttachmentCount |-> [i \in 1 .. 2 |-> 0] ]

(* Participant Input Warning Message at zero, then each field in turn at the values it is checked at *)
CheckedParticipantInputWarningMessage ==
    { ZeroParticipantInputWarningMessage }
        \cup { [ZeroParticipantInputWarningMessage EXCEPT !.orig = one] : one \in Sample(2) }
        \cup { [ZeroParticipantInputWarningMessage EXCEPT !.sipTime = one] : one \in Sample(8) }
        \cup { [ZeroParticipantInputWarningMessage EXCEPT !.feedSequence = one] : one \in Sample(8) }
        \cup { [ZeroParticipantInputWarningMessage EXCEPT !.partToken = one] : one \in Sample(8) }
        \cup { [ZeroParticipantInputWarningMessage EXCEPT !.warningCode = one] : one \in Sample(2) }
        \cup { [ZeroParticipantInputWarningMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroParticipantInputWarningMessage EXCEPT !.olAttachmenType = one] : one \in Sample(1) }
        \cup { [ZeroParticipantInputWarningMessage EXCEPT !.olAttachmentCount = one] : one \in Sample(2) }

(***************************************************************************)
(* Return Administrative Messages Message Payload, selected by Return      *)
(* Administrative Messages Message Type                                    *)
(***************************************************************************)

ReturnGeneralAdministrativeMessageCode == 65  \* "A"
ReturnMarketCenterTradingActionAcknowledgementMessageCode == 74  \* "J"
ReturnMarketOpenMessageCode == 88  \* "X"
ReturnMarketClosedMessageCode == 89  \* "Y"
RejectMessageCode == 82  \* "R"
SequenceAcknowledgementMessageCode == 75  \* "K"
ParticipantInputWarningMessageCode == 87  \* "W"

ReturnAdministrativeMessagesMessagePayload ==
    [ tag : {ReturnGeneralAdministrativeMessageCode}, body : ReturnGeneralAdministrativeMessage ]
        \cup [ tag : {ReturnMarketCenterTradingActionAcknowledgementMessageCode}, body : ReturnMarketCenterTradingActionAcknowledgementMessage ]
        \cup [ tag : {ReturnMarketOpenMessageCode}, body : ReturnMarketOpenMessage ]
        \cup [ tag : {ReturnMarketClosedMessageCode}, body : ReturnMarketClosedMessage ]
        \cup [ tag : {RejectMessageCode}, body : RejectMessage ]
        \cup [ tag : {SequenceAcknowledgementMessageCode}, body : SequenceAcknowledgementMessage ]
        \cup [ tag : {ParticipantInputWarningMessageCode}, body : ParticipantInputWarningMessage ]

EncodeReturnAdministrativeMessagesMessagePayload(message) ==
    CASE message.tag = ReturnGeneralAdministrativeMessageCode -> EncodeReturnGeneralAdministrativeMessage(message.body)
      [] message.tag = ReturnMarketCenterTradingActionAcknowledgementMessageCode -> EncodeReturnMarketCenterTradingActionAcknowledgementMessage(message.body)
      [] message.tag = ReturnMarketOpenMessageCode -> EncodeReturnMarketOpenMessage(message.body)
      [] message.tag = ReturnMarketClosedMessageCode -> EncodeReturnMarketClosedMessage(message.body)
      [] message.tag = RejectMessageCode -> EncodeRejectMessage(message.body)
      [] message.tag = SequenceAcknowledgementMessageCode -> EncodeSequenceAcknowledgementMessage(message.body)
      [] message.tag = ParticipantInputWarningMessageCode -> EncodeParticipantInputWarningMessage(message.body)

DecodeReturnAdministrativeMessagesMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = ReturnGeneralAdministrativeMessageCode -> DecodeReturnGeneralAdministrativeMessage(bytes)
              [] tag = ReturnMarketCenterTradingActionAcknowledgementMessageCode -> DecodeReturnMarketCenterTradingActionAcknowledgementMessage(bytes)
              [] tag = ReturnMarketOpenMessageCode -> DecodeReturnMarketOpenMessage(bytes)
              [] tag = ReturnMarketClosedMessageCode -> DecodeReturnMarketClosedMessage(bytes)
              [] tag = RejectMessageCode -> DecodeRejectMessage(bytes)
              [] tag = SequenceAcknowledgementMessageCode -> DecodeSequenceAcknowledgementMessage(bytes)
              [] tag = ParticipantInputWarningMessageCode -> DecodeParticipantInputWarningMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroReturnAdministrativeMessagesMessagePayload == [tag |-> ReturnGeneralAdministrativeMessageCode, body |-> ZeroReturnGeneralAdministrativeMessage]

(* Each Return Administrative Messages Message Payload in turn, at the values the message it names is checked at *)
CheckedReturnAdministrativeMessagesMessagePayload ==
    { [tag |-> ReturnGeneralAdministrativeMessageCode, body |-> one] : one \in CheckedReturnGeneralAdministrativeMessage }
        \cup { [tag |-> ReturnMarketCenterTradingActionAcknowledgementMessageCode, body |-> one] : one \in CheckedReturnMarketCenterTradingActionAcknowledgementMessage }
        \cup { [tag |-> ReturnMarketOpenMessageCode, body |-> one] : one \in CheckedReturnMarketOpenMessage }
        \cup { [tag |-> ReturnMarketClosedMessageCode, body |-> one] : one \in CheckedReturnMarketClosedMessage }
        \cup { [tag |-> RejectMessageCode, body |-> one] : one \in CheckedRejectMessage }
        \cup { [tag |-> SequenceAcknowledgementMessageCode, body |-> one] : one \in CheckedSequenceAcknowledgementMessage }
        \cup { [tag |-> ParticipantInputWarningMessageCode, body |-> one] : one \in CheckedParticipantInputWarningMessage }

(***************************************************************************)
(* Return Administrative Messages Message                                  *)
(***************************************************************************)

ReturnAdministrativeMessagesMessage ==
    [ returnAdministrativeMessagesMessagePayload : ReturnAdministrativeMessagesMessagePayload ]

EncodeReturnAdministrativeMessagesMessage(message) ==
    EncodeUIntBE(message.returnAdministrativeMessagesMessagePayload.tag, 1)
        \o EncodeReturnAdministrativeMessagesMessagePayload(message.returnAdministrativeMessagesMessagePayload)

DecodeReturnAdministrativeMessagesMessage(bytes) ==
    LET returnAdministrativeMessagesMessageType == ReadUIntBE(bytes, 1) IN IF ~returnAdministrativeMessagesMessageType.ok THEN Fail ELSE
    LET returnAdministrativeMessagesMessagePayload == DecodeReturnAdministrativeMessagesMessagePayload(returnAdministrativeMessagesMessageType.value, returnAdministrativeMessagesMessageType.rest) IN IF ~returnAdministrativeMessagesMessagePayload.ok THEN Fail ELSE
    Ok([ returnAdministrativeMessagesMessagePayload |-> returnAdministrativeMessagesMessagePayload.value ], returnAdministrativeMessagesMessagePayload.rest)

ZeroReturnAdministrativeMessagesMessage ==
    [ returnAdministrativeMessagesMessagePayload |-> ZeroReturnAdministrativeMessagesMessagePayload ]

(* Return Administrative Messages Message at zero, then each field in turn at the values it is checked at *)
CheckedReturnAdministrativeMessagesMessage ==
    { ZeroReturnAdministrativeMessagesMessage }
        \cup { [ZeroReturnAdministrativeMessagesMessage EXCEPT !.returnAdministrativeMessagesMessagePayload = one] : one \in CheckedReturnAdministrativeMessagesMessagePayload }

(***************************************************************************)
(* Start Of Day Message: 10 bytes                                          *)
(***************************************************************************)

StartOfDayMessage ==
    [ orig    : Sample(2),
      sipTime : Sample(8) ]

EncodeStartOfDayMessage(message) ==
    message.orig
        \o message.sipTime

DecodeStartOfDayMessage(bytes) ==
    LET orig == ReadBytes(bytes, 2) IN IF ~orig.ok THEN Fail ELSE
    LET sipTime == ReadBytes(orig.rest, 8) IN IF ~sipTime.ok THEN Fail ELSE
    Ok([ orig    |-> orig.value,
         sipTime |-> sipTime.value ], sipTime.rest)

ZeroStartOfDayMessage ==
    [ orig    |-> [i \in 1 .. 2 |-> 0],
      sipTime |-> [i \in 1 .. 8 |-> 0] ]

(* Start Of Day Message at zero, then each field in turn at the values it is checked at *)
CheckedStartOfDayMessage ==
    { ZeroStartOfDayMessage }
        \cup { [ZeroStartOfDayMessage EXCEPT !.orig = one] : one \in Sample(2) }
        \cup { [ZeroStartOfDayMessage EXCEPT !.sipTime = one] : one \in Sample(8) }

(***************************************************************************)
(* End Of Day Message: 10 bytes                                            *)
(***************************************************************************)

EndOfDayMessage ==
    [ orig    : Sample(2),
      sipTime : Sample(8) ]

EncodeEndOfDayMessage(message) ==
    message.orig
        \o message.sipTime

DecodeEndOfDayMessage(bytes) ==
    LET orig == ReadBytes(bytes, 2) IN IF ~orig.ok THEN Fail ELSE
    LET sipTime == ReadBytes(orig.rest, 8) IN IF ~sipTime.ok THEN Fail ELSE
    Ok([ orig    |-> orig.value,
         sipTime |-> sipTime.value ], sipTime.rest)

ZeroEndOfDayMessage ==
    [ orig    |-> [i \in 1 .. 2 |-> 0],
      sipTime |-> [i \in 1 .. 8 |-> 0] ]

(* End Of Day Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfDayMessage ==
    { ZeroEndOfDayMessage }
        \cup { [ZeroEndOfDayMessage EXCEPT !.orig = one] : one \in Sample(2) }
        \cup { [ZeroEndOfDayMessage EXCEPT !.sipTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Sequence Inquiry Response Message: 27 bytes                             *)
(***************************************************************************)

SequenceInquiryResponseMessage ==
    [ orig         : Sample(2),
      sipTime      : Sample(8),
      feedSequence : Sample(8),
      partToken    : Sample(8),
      sipState     : Sample(1) ]

EncodeSequenceInquiryResponseMessage(message) ==
    message.orig
        \o message.sipTime
        \o message.feedSequence
        \o message.partToken
        \o message.sipState

DecodeSequenceInquiryResponseMessage(bytes) ==
    LET orig == ReadBytes(bytes, 2) IN IF ~orig.ok THEN Fail ELSE
    LET sipTime == ReadBytes(orig.rest, 8) IN IF ~sipTime.ok THEN Fail ELSE
    LET feedSequence == ReadBytes(sipTime.rest, 8) IN IF ~feedSequence.ok THEN Fail ELSE
    LET partToken == ReadBytes(feedSequence.rest, 8) IN IF ~partToken.ok THEN Fail ELSE
    LET sipState == ReadBytes(partToken.rest, 1) IN IF ~sipState.ok THEN Fail ELSE
    Ok([ orig         |-> orig.value,
         sipTime      |-> sipTime.value,
         feedSequence |-> feedSequence.value,
         partToken    |-> partToken.value,
         sipState     |-> sipState.value ], sipState.rest)

ZeroSequenceInquiryResponseMessage ==
    [ orig         |-> [i \in 1 .. 2 |-> 0],
      sipTime      |-> [i \in 1 .. 8 |-> 0],
      feedSequence |-> [i \in 1 .. 8 |-> 0],
      partToken    |-> [i \in 1 .. 8 |-> 0],
      sipState     |-> [i \in 1 .. 1 |-> 0] ]

(* Sequence Inquiry Response Message at zero, then each field in turn at the values it is checked at *)
CheckedSequenceInquiryResponseMessage ==
    { ZeroSequenceInquiryResponseMessage }
        \cup { [ZeroSequenceInquiryResponseMessage EXCEPT !.orig = one] : one \in Sample(2) }
        \cup { [ZeroSequenceInquiryResponseMessage EXCEPT !.sipTime = one] : one \in Sample(8) }
        \cup { [ZeroSequenceInquiryResponseMessage EXCEPT !.feedSequence = one] : one \in Sample(8) }
        \cup { [ZeroSequenceInquiryResponseMessage EXCEPT !.partToken = one] : one \in Sample(8) }
        \cup { [ZeroSequenceInquiryResponseMessage EXCEPT !.sipState = one] : one \in Sample(1) }

(***************************************************************************)
(* Symbol State Inquiry Response Message: 30 bytes                         *)
(***************************************************************************)

SymbolStateInquiryResponseMessage ==
    [ orig               : Sample(2),
      sipTime            : Sample(8),
      symbolLong         : Sample(11),
      nextTradeId        : Sample(4),
      nextActionSequence : Sample(4),
      symbolState        : Sample(1) ]

EncodeSymbolStateInquiryResponseMessage(message) ==
    message.orig
        \o message.sipTime
        \o message.symbolLong
        \o message.nextTradeId
        \o message.nextActionSequence
        \o message.symbolState

DecodeSymbolStateInquiryResponseMessage(bytes) ==
    LET orig == ReadBytes(bytes, 2) IN IF ~orig.ok THEN Fail ELSE
    LET sipTime == ReadBytes(orig.rest, 8) IN IF ~sipTime.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(sipTime.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET nextTradeId == ReadBytes(symbolLong.rest, 4) IN IF ~nextTradeId.ok THEN Fail ELSE
    LET nextActionSequence == ReadBytes(nextTradeId.rest, 4) IN IF ~nextActionSequence.ok THEN Fail ELSE
    LET symbolState == ReadBytes(nextActionSequence.rest, 1) IN IF ~symbolState.ok THEN Fail ELSE
    Ok([ orig               |-> orig.value,
         sipTime            |-> sipTime.value,
         symbolLong         |-> symbolLong.value,
         nextTradeId        |-> nextTradeId.value,
         nextActionSequence |-> nextActionSequence.value,
         symbolState        |-> symbolState.value ], symbolState.rest)

ZeroSymbolStateInquiryResponseMessage ==
    [ orig               |-> [i \in 1 .. 2 |-> 0],
      sipTime            |-> [i \in 1 .. 8 |-> 0],
      symbolLong         |-> [i \in 1 .. 11 |-> 0],
      nextTradeId        |-> [i \in 1 .. 4 |-> 0],
      nextActionSequence |-> [i \in 1 .. 4 |-> 0],
      symbolState        |-> [i \in 1 .. 1 |-> 0] ]

(* Symbol State Inquiry Response Message at zero, then each field in turn at the values it is checked at *)
CheckedSymbolStateInquiryResponseMessage ==
    { ZeroSymbolStateInquiryResponseMessage }
        \cup { [ZeroSymbolStateInquiryResponseMessage EXCEPT !.orig = one] : one \in Sample(2) }
        \cup { [ZeroSymbolStateInquiryResponseMessage EXCEPT !.sipTime = one] : one \in Sample(8) }
        \cup { [ZeroSymbolStateInquiryResponseMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroSymbolStateInquiryResponseMessage EXCEPT !.nextTradeId = one] : one \in Sample(4) }
        \cup { [ZeroSymbolStateInquiryResponseMessage EXCEPT !.nextActionSequence = one] : one \in Sample(4) }
        \cup { [ZeroSymbolStateInquiryResponseMessage EXCEPT !.symbolState = one] : one \in Sample(1) }

(***************************************************************************)
(* Return Control Messages Message Payload, selected by Return Control     *)
(* Messages Message Type                                                   *)
(***************************************************************************)

StartOfDayMessageCode == 69  \* "E"
EndOfDayMessageCode == 70  \* "F"
SequenceInquiryResponseMessageCode == 67  \* "C"
SymbolStateInquiryResponseMessageCode == 83  \* "S"

ReturnControlMessagesMessagePayload ==
    [ tag : {StartOfDayMessageCode}, body : StartOfDayMessage ]
        \cup [ tag : {EndOfDayMessageCode}, body : EndOfDayMessage ]
        \cup [ tag : {SequenceInquiryResponseMessageCode}, body : SequenceInquiryResponseMessage ]
        \cup [ tag : {SymbolStateInquiryResponseMessageCode}, body : SymbolStateInquiryResponseMessage ]

EncodeReturnControlMessagesMessagePayload(message) ==
    CASE message.tag = StartOfDayMessageCode -> EncodeStartOfDayMessage(message.body)
      [] message.tag = EndOfDayMessageCode -> EncodeEndOfDayMessage(message.body)
      [] message.tag = SequenceInquiryResponseMessageCode -> EncodeSequenceInquiryResponseMessage(message.body)
      [] message.tag = SymbolStateInquiryResponseMessageCode -> EncodeSymbolStateInquiryResponseMessage(message.body)

DecodeReturnControlMessagesMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = StartOfDayMessageCode -> DecodeStartOfDayMessage(bytes)
              [] tag = EndOfDayMessageCode -> DecodeEndOfDayMessage(bytes)
              [] tag = SequenceInquiryResponseMessageCode -> DecodeSequenceInquiryResponseMessage(bytes)
              [] tag = SymbolStateInquiryResponseMessageCode -> DecodeSymbolStateInquiryResponseMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroReturnControlMessagesMessagePayload == [tag |-> StartOfDayMessageCode, body |-> ZeroStartOfDayMessage]

(* Each Return Control Messages Message Payload in turn, at the values the message it names is checked at *)
CheckedReturnControlMessagesMessagePayload ==
    { [tag |-> StartOfDayMessageCode, body |-> one] : one \in CheckedStartOfDayMessage }
        \cup { [tag |-> EndOfDayMessageCode, body |-> one] : one \in CheckedEndOfDayMessage }
        \cup { [tag |-> SequenceInquiryResponseMessageCode, body |-> one] : one \in CheckedSequenceInquiryResponseMessage }
        \cup { [tag |-> SymbolStateInquiryResponseMessageCode, body |-> one] : one \in CheckedSymbolStateInquiryResponseMessage }

(***************************************************************************)
(* Return Control Messages Message                                         *)
(***************************************************************************)

ReturnControlMessagesMessage ==
    [ returnControlMessagesMessagePayload : ReturnControlMessagesMessagePayload ]

EncodeReturnControlMessagesMessage(message) ==
    EncodeUIntBE(message.returnControlMessagesMessagePayload.tag, 1)
        \o EncodeReturnControlMessagesMessagePayload(message.returnControlMessagesMessagePayload)

DecodeReturnControlMessagesMessage(bytes) ==
    LET returnControlMessagesMessageType == ReadUIntBE(bytes, 1) IN IF ~returnControlMessagesMessageType.ok THEN Fail ELSE
    LET returnControlMessagesMessagePayload == DecodeReturnControlMessagesMessagePayload(returnControlMessagesMessageType.value, returnControlMessagesMessageType.rest) IN IF ~returnControlMessagesMessagePayload.ok THEN Fail ELSE
    Ok([ returnControlMessagesMessagePayload |-> returnControlMessagesMessagePayload.value ], returnControlMessagesMessagePayload.rest)

ZeroReturnControlMessagesMessage ==
    [ returnControlMessagesMessagePayload |-> ZeroReturnControlMessagesMessagePayload ]

(* Return Control Messages Message at zero, then each field in turn at the values it is checked at *)
CheckedReturnControlMessagesMessage ==
    { ZeroReturnControlMessagesMessage }
        \cup { [ZeroReturnControlMessagesMessage EXCEPT !.returnControlMessagesMessagePayload = one] : one \in CheckedReturnControlMessagesMessagePayload }

(***************************************************************************)
(* Category Payload, selected by Message Category                          *)
(***************************************************************************)

InboundQuoteMessagesMessageCode == 81  \* "Q"
InboundTradeMessagesMessageCode == 84  \* "T"
InboundAdministrativeMessagesMessageCode == 65  \* "A"
InboundControlMessagesMessageCode == 67  \* "C"
ReturnAdministrativeMessagesMessageCode == 97  \* "a"
ReturnControlMessagesMessageCode == 99  \* "c"

CategoryPayload ==
    [ tag : {InboundQuoteMessagesMessageCode}, body : InboundQuoteMessagesMessage ]
        \cup [ tag : {InboundTradeMessagesMessageCode}, body : InboundTradeMessagesMessage ]
        \cup [ tag : {InboundAdministrativeMessagesMessageCode}, body : InboundAdministrativeMessagesMessage ]
        \cup [ tag : {InboundControlMessagesMessageCode}, body : InboundControlMessagesMessage ]
        \cup [ tag : {ReturnAdministrativeMessagesMessageCode}, body : ReturnAdministrativeMessagesMessage ]
        \cup [ tag : {ReturnControlMessagesMessageCode}, body : ReturnControlMessagesMessage ]

EncodeCategoryPayload(message) ==
    CASE message.tag = InboundQuoteMessagesMessageCode -> EncodeInboundQuoteMessagesMessage(message.body)
      [] message.tag = InboundTradeMessagesMessageCode -> EncodeInboundTradeMessagesMessage(message.body)
      [] message.tag = InboundAdministrativeMessagesMessageCode -> EncodeInboundAdministrativeMessagesMessage(message.body)
      [] message.tag = InboundControlMessagesMessageCode -> EncodeInboundControlMessagesMessage(message.body)
      [] message.tag = ReturnAdministrativeMessagesMessageCode -> EncodeReturnAdministrativeMessagesMessage(message.body)
      [] message.tag = ReturnControlMessagesMessageCode -> EncodeReturnControlMessagesMessage(message.body)

DecodeCategoryPayload(tag, bytes) ==
    LET read ==
            CASE tag = InboundQuoteMessagesMessageCode -> DecodeInboundQuoteMessagesMessage(bytes)
              [] tag = InboundTradeMessagesMessageCode -> DecodeInboundTradeMessagesMessage(bytes)
              [] tag = InboundAdministrativeMessagesMessageCode -> DecodeInboundAdministrativeMessagesMessage(bytes)
              [] tag = InboundControlMessagesMessageCode -> DecodeInboundControlMessagesMessage(bytes)
              [] tag = ReturnAdministrativeMessagesMessageCode -> DecodeReturnAdministrativeMessagesMessage(bytes)
              [] tag = ReturnControlMessagesMessageCode -> DecodeReturnControlMessagesMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroCategoryPayload == [tag |-> InboundQuoteMessagesMessageCode, body |-> ZeroInboundQuoteMessagesMessage]

(* Each Category Payload in turn, at the values the message it names is checked at *)
CheckedCategoryPayload ==
    { [tag |-> InboundQuoteMessagesMessageCode, body |-> one] : one \in CheckedInboundQuoteMessagesMessage }
        \cup { [tag |-> InboundTradeMessagesMessageCode, body |-> one] : one \in CheckedInboundTradeMessagesMessage }
        \cup { [tag |-> InboundAdministrativeMessagesMessageCode, body |-> one] : one \in CheckedInboundAdministrativeMessagesMessage }
        \cup { [tag |-> InboundControlMessagesMessageCode, body |-> one] : one \in CheckedInboundControlMessagesMessage }
        \cup { [tag |-> ReturnAdministrativeMessagesMessageCode, body |-> one] : one \in CheckedReturnAdministrativeMessagesMessage }
        \cup { [tag |-> ReturnControlMessagesMessageCode, body |-> one] : one \in CheckedReturnControlMessagesMessage }

(***************************************************************************)
(* Sequenced Data Packet                                                   *)
(***************************************************************************)

SequencedDataPacket ==
    [ version         : Sample(1),
      categoryPayload : CategoryPayload ]

EncodeSequencedDataPacket(message) ==
    message.version
        \o EncodeUIntBE(message.categoryPayload.tag, 1)
        \o EncodeCategoryPayload(message.categoryPayload)

DecodeSequencedDataPacket(bytes) ==
    LET version == ReadBytes(bytes, 1) IN IF ~version.ok THEN Fail ELSE
    LET messageCategory == ReadUIntBE(version.rest, 1) IN IF ~messageCategory.ok THEN Fail ELSE
    LET categoryPayload == DecodeCategoryPayload(messageCategory.value, messageCategory.rest) IN IF ~categoryPayload.ok THEN Fail ELSE
    Ok([ version         |-> version.value,
         categoryPayload |-> categoryPayload.value ], categoryPayload.rest)

ZeroSequencedDataPacket ==
    [ version         |-> [i \in 1 .. 1 |-> 0],
      categoryPayload |-> ZeroCategoryPayload ]

(* Sequenced Data Packet at zero, then each field in turn at the values it is checked at *)
CheckedSequencedDataPacket ==
    { ZeroSequencedDataPacket }
        \cup { [ZeroSequencedDataPacket EXCEPT !.version = one] : one \in Sample(1) }
        \cup { [ZeroSequencedDataPacket EXCEPT !.categoryPayload = one] : one \in CheckedCategoryPayload }

(***************************************************************************)
(* Debug Packet                                                            *)
(***************************************************************************)

DebugPacket ==
    [ debugText : SampleBytes ]

EncodeDebugPacket(message) ==
    message.debugText

DecodeDebugPacket(bytes) ==
    LET debugText == Ok(bytes, << >>) IN IF ~debugText.ok THEN Fail ELSE
    Ok([ debugText |-> debugText.value ], debugText.rest)

ZeroDebugPacket ==
    [ debugText |-> << >> ]

(* Debug Packet at zero, then each field in turn at the values it is checked at *)
CheckedDebugPacket ==
    { ZeroDebugPacket }
        \cup { [ZeroDebugPacket EXCEPT !.debugText = one] : one \in SampleBytes }

(***************************************************************************)
(* Login Accepted Packet: 30 bytes                                         *)
(***************************************************************************)

LoginAcceptedPacket ==
    [ acceptedSession        : Sample(10),
      acceptedSequenceNumber : Sample(20) ]

EncodeLoginAcceptedPacket(message) ==
    message.acceptedSession
        \o message.acceptedSequenceNumber

DecodeLoginAcceptedPacket(bytes) ==
    LET acceptedSession == ReadBytes(bytes, 10) IN IF ~acceptedSession.ok THEN Fail ELSE
    LET acceptedSequenceNumber == ReadBytes(acceptedSession.rest, 20) IN IF ~acceptedSequenceNumber.ok THEN Fail ELSE
    Ok([ acceptedSession        |-> acceptedSession.value,
         acceptedSequenceNumber |-> acceptedSequenceNumber.value ], acceptedSequenceNumber.rest)

ZeroLoginAcceptedPacket ==
    [ acceptedSession        |-> [i \in 1 .. 10 |-> 0],
      acceptedSequenceNumber |-> [i \in 1 .. 20 |-> 0] ]

(* Login Accepted Packet at zero, then each field in turn at the values it is checked at *)
CheckedLoginAcceptedPacket ==
    { ZeroLoginAcceptedPacket }
        \cup { [ZeroLoginAcceptedPacket EXCEPT !.acceptedSession = one] : one \in Sample(10) }
        \cup { [ZeroLoginAcceptedPacket EXCEPT !.acceptedSequenceNumber = one] : one \in Sample(20) }

(***************************************************************************)
(* Login Rejected Packet: 1 bytes                                          *)
(***************************************************************************)

LoginRejectedPacket ==
    [ rejectReasonCode : Sample(1) ]

EncodeLoginRejectedPacket(message) ==
    message.rejectReasonCode

DecodeLoginRejectedPacket(bytes) ==
    LET rejectReasonCode == ReadBytes(bytes, 1) IN IF ~rejectReasonCode.ok THEN Fail ELSE
    Ok([ rejectReasonCode |-> rejectReasonCode.value ], rejectReasonCode.rest)

ZeroLoginRejectedPacket ==
    [ rejectReasonCode |-> [i \in 1 .. 1 |-> 0] ]

(* Login Rejected Packet at zero, then each field in turn at the values it is checked at *)
CheckedLoginRejectedPacket ==
    { ZeroLoginRejectedPacket }
        \cup { [ZeroLoginRejectedPacket EXCEPT !.rejectReasonCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Server Tcp Payload, selected by Server Packet Type                      *)
(***************************************************************************)

SequencedDataPacketCode == 83  \* "S"
DebugPacketCode == 43  \* "+"
LoginAcceptedPacketCode == 65  \* "A"
LoginRejectedPacketCode == 74  \* "J"
ServerHeartbeatPacketCode == 72  \* "H"
EndOfSessionPacketCode == 90  \* "Z"

ServerTcpPayload ==
    [ tag : {SequencedDataPacketCode}, body : SequencedDataPacket ]
        \cup [ tag : {DebugPacketCode}, body : DebugPacket ]
        \cup [ tag : {LoginAcceptedPacketCode}, body : LoginAcceptedPacket ]
        \cup [ tag : {LoginRejectedPacketCode}, body : LoginRejectedPacket ]
        \cup [ tag : {ServerHeartbeatPacketCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {EndOfSessionPacketCode}, body : {[empty |-> 0]} ]

EncodeServerTcpPayload(message) ==
    CASE message.tag = SequencedDataPacketCode -> EncodeSequencedDataPacket(message.body)
      [] message.tag = DebugPacketCode -> EncodeDebugPacket(message.body)
      [] message.tag = LoginAcceptedPacketCode -> EncodeLoginAcceptedPacket(message.body)
      [] message.tag = LoginRejectedPacketCode -> EncodeLoginRejectedPacket(message.body)
      [] message.tag = ServerHeartbeatPacketCode -> << >>
      [] message.tag = EndOfSessionPacketCode -> << >>

DecodeServerTcpPayload(tag, bytes) ==
    LET read ==
            CASE tag = SequencedDataPacketCode -> DecodeSequencedDataPacket(bytes)
              [] tag = DebugPacketCode -> DecodeDebugPacket(bytes)
              [] tag = LoginAcceptedPacketCode -> DecodeLoginAcceptedPacket(bytes)
              [] tag = LoginRejectedPacketCode -> DecodeLoginRejectedPacket(bytes)
              [] tag = ServerHeartbeatPacketCode -> Ok([empty |-> 0], bytes)
              [] tag = EndOfSessionPacketCode -> Ok([empty |-> 0], bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroServerTcpPayload == [tag |-> SequencedDataPacketCode, body |-> ZeroSequencedDataPacket]

(* Each Server Tcp Payload in turn, at the values the message it names is checked at *)
CheckedServerTcpPayload ==
    { [tag |-> SequencedDataPacketCode, body |-> one] : one \in CheckedSequencedDataPacket }
        \cup { [tag |-> DebugPacketCode, body |-> one] : one \in CheckedDebugPacket }
        \cup { [tag |-> LoginAcceptedPacketCode, body |-> one] : one \in CheckedLoginAcceptedPacket }
        \cup { [tag |-> LoginRejectedPacketCode, body |-> one] : one \in CheckedLoginRejectedPacket }
        \cup { [tag |-> ServerHeartbeatPacketCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> EndOfSessionPacketCode, body |-> [empty |-> 0]] }

(***************************************************************************)
(* Server Packet, framed by Packet Length                                  *)
(***************************************************************************)

ServerPacket ==
    [ serverTcpPayload : ServerTcpPayload ]

EncodeServerPacketBody(message) ==
    EncodeUIntBE(message.serverTcpPayload.tag, 1)
        \o EncodeServerTcpPayload(message.serverTcpPayload)

(* Packet Length counts the bytes it frames, so it is written from them *)
EncodeServerPacket(message) ==
    LET body == EncodeServerPacketBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeServerPacketBody(bytes) ==
    LET serverPacketType == ReadUIntBE(bytes, 1) IN IF ~serverPacketType.ok THEN Fail ELSE
    LET serverTcpPayload == DecodeServerTcpPayload(serverPacketType.value, serverPacketType.rest) IN IF ~serverTcpPayload.ok THEN Fail ELSE
    Ok([ serverTcpPayload |-> serverTcpPayload.value ], serverTcpPayload.rest)

DecodeServerPacket(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeServerPacketBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroServerPacket ==
    [ serverTcpPayload |-> ZeroServerTcpPayload ]

(* Server Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerPacket ==
    { ZeroServerPacket }
        \cup { [ZeroServerPacket EXCEPT !.serverTcpPayload = one] : one \in CheckedServerTcpPayload }

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

(* Every Protected Exchange Quote Message Shortform Message decodes back to what was encoded, and leaves nothing over *)
RoundTripProtectedExchangeQuoteMessageShortformMessage ==
    \A message \in CheckedProtectedExchangeQuoteMessageShortformMessage :
        LET read == DecodeProtectedExchangeQuoteMessageShortformMessage(EncodeProtectedExchangeQuoteMessageShortformMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Protected Exchange Quote Message Longform Message decodes back to what was encoded, and leaves nothing over *)
RoundTripProtectedExchangeQuoteMessageLongformMessage ==
    \A message \in CheckedProtectedExchangeQuoteMessageLongformMessage :
        LET read == DecodeProtectedExchangeQuoteMessageLongformMessage(EncodeProtectedExchangeQuoteMessageLongformMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Odd Lot Bid Short Form Attachment decodes back to what was encoded, and leaves nothing over *)
RoundTripOddLotBidShortFormAttachment ==
    \A message \in CheckedOddLotBidShortFormAttachment :
        LET read == DecodeOddLotBidShortFormAttachment(EncodeOddLotBidShortFormAttachment(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Odd Lot Ask Short Form Attachment decodes back to what was encoded, and leaves nothing over *)
RoundTripOddLotAskShortFormAttachment ==
    \A message \in CheckedOddLotAskShortFormAttachment :
        LET read == DecodeOddLotAskShortFormAttachment(EncodeOddLotAskShortFormAttachment(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Exchange Odd Lot Quote Message Short Form Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExchangeOddLotQuoteMessageShortFormMessage ==
    \A message \in CheckedExchangeOddLotQuoteMessageShortFormMessage :
        LET read == DecodeExchangeOddLotQuoteMessageShortFormMessage(EncodeExchangeOddLotQuoteMessageShortFormMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Odd Lot Bid Long Form Attachment decodes back to what was encoded, and leaves nothing over *)
RoundTripOddLotBidLongFormAttachment ==
    \A message \in CheckedOddLotBidLongFormAttachment :
        LET read == DecodeOddLotBidLongFormAttachment(EncodeOddLotBidLongFormAttachment(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Odd Lot Ask Long Form Attachment decodes back to what was encoded, and leaves nothing over *)
RoundTripOddLotAskLongFormAttachment ==
    \A message \in CheckedOddLotAskLongFormAttachment :
        LET read == DecodeOddLotAskLongFormAttachment(EncodeOddLotAskLongFormAttachment(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Exchange Odd Lot Quote Message Long Form Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExchangeOddLotQuoteMessageLongFormMessage ==
    \A message \in CheckedExchangeOddLotQuoteMessageLongFormMessage :
        LET read == DecodeExchangeOddLotQuoteMessageLongFormMessage(EncodeExchangeOddLotQuoteMessageLongFormMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Odd Lot Bid Short Form Attachment decodes back to what was encoded, and leaves nothing over *)
RoundTripOddLotBidShortFormAttachment2 ==
    \A message \in CheckedOddLotBidShortFormAttachment2 :
        LET read == DecodeOddLotBidShortFormAttachment2(EncodeOddLotBidShortFormAttachment2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Odd Lot Ask Short Form Attachment decodes back to what was encoded, and leaves nothing over *)
RoundTripOddLotAskShortFormAttachment2 ==
    \A message \in CheckedOddLotAskShortFormAttachment2 :
        LET read == DecodeOddLotAskShortFormAttachment2(EncodeOddLotAskShortFormAttachment2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Exchange Combined Quote Message Short Form Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExchangeCombinedQuoteMessageShortFormMessage ==
    \A message \in CheckedExchangeCombinedQuoteMessageShortFormMessage :
        LET read == DecodeExchangeCombinedQuoteMessageShortFormMessage(EncodeExchangeCombinedQuoteMessageShortFormMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Odd Lot Bid Long Form Attachment decodes back to what was encoded, and leaves nothing over *)
RoundTripOddLotBidLongFormAttachment2 ==
    \A message \in CheckedOddLotBidLongFormAttachment2 :
        LET read == DecodeOddLotBidLongFormAttachment2(EncodeOddLotBidLongFormAttachment2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Odd Lot Ask Long Form Attachment decodes back to what was encoded, and leaves nothing over *)
RoundTripOddLotAskLongFormAttachment2 ==
    \A message \in CheckedOddLotAskLongFormAttachment2 :
        LET read == DecodeOddLotAskLongFormAttachment2(EncodeOddLotAskLongFormAttachment2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Exchange Combined Quote Message Long Form Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExchangeCombinedQuoteMessageLongFormMessage ==
    \A message \in CheckedExchangeCombinedQuoteMessageLongFormMessage :
        LET read == DecodeExchangeCombinedQuoteMessageLongFormMessage(EncodeExchangeCombinedQuoteMessageLongFormMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Finra Protected Quote Message With Bbo Info Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFinraProtectedQuoteMessageWithBboInfoMessage ==
    \A message \in CheckedFinraProtectedQuoteMessageWithBboInfoMessage :
        LET read == DecodeFinraProtectedQuoteMessageWithBboInfoMessage(EncodeFinraProtectedQuoteMessageWithBboInfoMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Finra Protected Quote Message Without Bbo Info Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFinraProtectedQuoteMessageWithoutBboInfoMessage ==
    \A message \in CheckedFinraProtectedQuoteMessageWithoutBboInfoMessage :
        LET read == DecodeFinraProtectedQuoteMessageWithoutBboInfoMessage(EncodeFinraProtectedQuoteMessageWithoutBboInfoMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Odd Lot Bid Adf Form Attachment decodes back to what was encoded, and leaves nothing over *)
RoundTripOddLotBidAdfFormAttachment ==
    \A message \in CheckedOddLotBidAdfFormAttachment :
        LET read == DecodeOddLotBidAdfFormAttachment(EncodeOddLotBidAdfFormAttachment(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Odd Lot Ask Adf Form Attachment decodes back to what was encoded, and leaves nothing over *)
RoundTripOddLotAskAdfFormAttachment ==
    \A message \in CheckedOddLotAskAdfFormAttachment :
        LET read == DecodeOddLotAskAdfFormAttachment(EncodeOddLotAskAdfFormAttachment(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Finra Adf Odd Lot Quotation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFinraAdfOddLotQuotationMessage ==
    \A message \in CheckedFinraAdfOddLotQuotationMessage :
        LET read == DecodeFinraAdfOddLotQuotationMessage(EncodeFinraAdfOddLotQuotationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Odd Lot Bid Adf Form Attachment decodes back to what was encoded, and leaves nothing over *)
RoundTripOddLotBidAdfFormAttachment2 ==
    \A message \in CheckedOddLotBidAdfFormAttachment2 :
        LET read == DecodeOddLotBidAdfFormAttachment2(EncodeOddLotBidAdfFormAttachment2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Odd Lot Ask Adf Form Attachment decodes back to what was encoded, and leaves nothing over *)
RoundTripOddLotAskAdfFormAttachment2 ==
    \A message \in CheckedOddLotAskAdfFormAttachment2 :
        LET read == DecodeOddLotAskAdfFormAttachment2(EncodeOddLotAskAdfFormAttachment2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Finra Adf Combined Quote Message With Bbo decodes back to what was encoded, and leaves nothing over *)
RoundTripFinraAdfCombinedQuoteMessageWithBbo ==
    \A message \in CheckedFinraAdfCombinedQuoteMessageWithBbo :
        LET read == DecodeFinraAdfCombinedQuoteMessageWithBbo(EncodeFinraAdfCombinedQuoteMessageWithBbo(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Inbound Quote Messages Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInboundQuoteMessagesMessage ==
    \A message \in CheckedInboundQuoteMessagesMessage :
        LET read == DecodeInboundQuoteMessagesMessage(EncodeInboundQuoteMessagesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Regular Trade Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRegularTradeReportMessage ==
    \A message \in CheckedRegularTradeReportMessage :
        LET read == DecodeRegularTradeReportMessage(EncodeRegularTradeReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Cancel Error Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCancelErrorMessage ==
    \A message \in CheckedTradeCancelErrorMessage :
        LET read == DecodeTradeCancelErrorMessage(EncodeTradeCancelErrorMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Correction Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCorrectionMessage ==
    \A message \in CheckedTradeCorrectionMessage :
        LET read == DecodeTradeCorrectionMessage(EncodeTradeCorrectionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every As Of Trade Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAsOfTradeReportMessage ==
    \A message \in CheckedAsOfTradeReportMessage :
        LET read == DecodeAsOfTradeReportMessage(EncodeAsOfTradeReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fractional Regular Trade Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFractionalRegularTradeReportMessage ==
    \A message \in CheckedFractionalRegularTradeReportMessage :
        LET read == DecodeFractionalRegularTradeReportMessage(EncodeFractionalRegularTradeReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fractional Trade Cancel Error Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFractionalTradeCancelErrorMessage ==
    \A message \in CheckedFractionalTradeCancelErrorMessage :
        LET read == DecodeFractionalTradeCancelErrorMessage(EncodeFractionalTradeCancelErrorMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fractional Trade Correction Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFractionalTradeCorrectionMessage ==
    \A message \in CheckedFractionalTradeCorrectionMessage :
        LET read == DecodeFractionalTradeCorrectionMessage(EncodeFractionalTradeCorrectionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fractional As Of Trade Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFractionalAsOfTradeReportMessage ==
    \A message \in CheckedFractionalAsOfTradeReportMessage :
        LET read == DecodeFractionalAsOfTradeReportMessage(EncodeFractionalAsOfTradeReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Inbound Trade Messages Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInboundTradeMessagesMessage ==
    \A message \in CheckedInboundTradeMessagesMessage :
        LET read == DecodeInboundTradeMessagesMessage(EncodeInboundTradeMessagesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every General Administrative Message decodes back to what was encoded, and leaves nothing over *)
RoundTripGeneralAdministrativeMessage ==
    \A message \in CheckedGeneralAdministrativeMessage :
        LET read == DecodeGeneralAdministrativeMessage(EncodeGeneralAdministrativeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trading Action Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingActionMessage ==
    \A message \in CheckedTradingActionMessage :
        LET read == DecodeTradingActionMessage(EncodeTradingActionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Center Trading Action Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketCenterTradingActionMessage ==
    \A message \in CheckedMarketCenterTradingActionMessage :
        LET read == DecodeMarketCenterTradingActionMessage(EncodeMarketCenterTradingActionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Center Mass Trading Action Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketCenterMassTradingActionMessage ==
    \A message \in CheckedMarketCenterMassTradingActionMessage :
        LET read == DecodeMarketCenterMassTradingActionMessage(EncodeMarketCenterMassTradingActionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reg Sho Short Sale Price Test Restricted Indicator Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRegShoShortSalePriceTestRestrictedIndicatorMessage ==
    \A message \in CheckedRegShoShortSalePriceTestRestrictedIndicatorMessage :
        LET read == DecodeRegShoShortSalePriceTestRestrictedIndicatorMessage(EncodeRegShoShortSalePriceTestRestrictedIndicatorMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Opening Reference Midpoint Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOpeningReferenceMidpointPriceMessage ==
    \A message \in CheckedOpeningReferenceMidpointPriceMessage :
        LET read == DecodeOpeningReferenceMidpointPriceMessage(EncodeOpeningReferenceMidpointPriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every T 1 Adjusted Closing Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripT1AdjustedClosingPriceMessage ==
    \A message \in CheckedT1AdjustedClosingPriceMessage :
        LET read == DecodeT1AdjustedClosingPriceMessage(EncodeT1AdjustedClosingPriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Open Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketOpenMessage ==
    \A message \in CheckedMarketOpenMessage :
        LET read == DecodeMarketOpenMessage(EncodeMarketOpenMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Closed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketClosedMessage ==
    \A message \in CheckedMarketClosedMessage :
        LET read == DecodeMarketClosedMessage(EncodeMarketClosedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Collar Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionCollarMessage ==
    \A message \in CheckedAuctionCollarMessage :
        LET read == DecodeAuctionCollarMessage(EncodeAuctionCollarMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Inbound Administrative Messages Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInboundAdministrativeMessagesMessage ==
    \A message \in CheckedInboundAdministrativeMessagesMessage :
        LET read == DecodeInboundAdministrativeMessagesMessage(EncodeInboundAdministrativeMessagesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sequence Inquiry Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSequenceInquiryMessage ==
    \A message \in CheckedSequenceInquiryMessage :
        LET read == DecodeSequenceInquiryMessage(EncodeSequenceInquiryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol State Inquiry Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolStateInquiryMessage ==
    \A message \in CheckedSymbolStateInquiryMessage :
        LET read == DecodeSymbolStateInquiryMessage(EncodeSymbolStateInquiryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Participant Reporting Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfParticipantReportingMessage ==
    \A message \in CheckedEndOfParticipantReportingMessage :
        LET read == DecodeEndOfParticipantReportingMessage(EncodeEndOfParticipantReportingMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Inbound Control Messages Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInboundControlMessagesMessage ==
    \A message \in CheckedInboundControlMessagesMessage :
        LET read == DecodeInboundControlMessagesMessage(EncodeInboundControlMessagesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Return General Administrative Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReturnGeneralAdministrativeMessage ==
    \A message \in CheckedReturnGeneralAdministrativeMessage :
        LET read == DecodeReturnGeneralAdministrativeMessage(EncodeReturnGeneralAdministrativeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Return Market Center Trading Action Acknowledgement Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReturnMarketCenterTradingActionAcknowledgementMessage ==
    \A message \in CheckedReturnMarketCenterTradingActionAcknowledgementMessage :
        LET read == DecodeReturnMarketCenterTradingActionAcknowledgementMessage(EncodeReturnMarketCenterTradingActionAcknowledgementMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Return Market Open Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReturnMarketOpenMessage ==
    \A message \in CheckedReturnMarketOpenMessage :
        LET read == DecodeReturnMarketOpenMessage(EncodeReturnMarketOpenMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Return Market Closed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReturnMarketClosedMessage ==
    \A message \in CheckedReturnMarketClosedMessage :
        LET read == DecodeReturnMarketClosedMessage(EncodeReturnMarketClosedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRejectMessage ==
    \A message \in CheckedRejectMessage :
        LET read == DecodeRejectMessage(EncodeRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sequence Acknowledgement Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSequenceAcknowledgementMessage ==
    \A message \in CheckedSequenceAcknowledgementMessage :
        LET read == DecodeSequenceAcknowledgementMessage(EncodeSequenceAcknowledgementMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Participant Input Warning Message decodes back to what was encoded, and leaves nothing over *)
RoundTripParticipantInputWarningMessage ==
    \A message \in CheckedParticipantInputWarningMessage :
        LET read == DecodeParticipantInputWarningMessage(EncodeParticipantInputWarningMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Return Administrative Messages Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReturnAdministrativeMessagesMessage ==
    \A message \in CheckedReturnAdministrativeMessagesMessage :
        LET read == DecodeReturnAdministrativeMessagesMessage(EncodeReturnAdministrativeMessagesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Start Of Day Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStartOfDayMessage ==
    \A message \in CheckedStartOfDayMessage :
        LET read == DecodeStartOfDayMessage(EncodeStartOfDayMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Day Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfDayMessage ==
    \A message \in CheckedEndOfDayMessage :
        LET read == DecodeEndOfDayMessage(EncodeEndOfDayMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sequence Inquiry Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSequenceInquiryResponseMessage ==
    \A message \in CheckedSequenceInquiryResponseMessage :
        LET read == DecodeSequenceInquiryResponseMessage(EncodeSequenceInquiryResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol State Inquiry Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolStateInquiryResponseMessage ==
    \A message \in CheckedSymbolStateInquiryResponseMessage :
        LET read == DecodeSymbolStateInquiryResponseMessage(EncodeSymbolStateInquiryResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Return Control Messages Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReturnControlMessagesMessage ==
    \A message \in CheckedReturnControlMessagesMessage :
        LET read == DecodeReturnControlMessagesMessage(EncodeReturnControlMessagesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sequenced Data Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripSequencedDataPacket ==
    \A message \in CheckedSequencedDataPacket :
        LET read == DecodeSequencedDataPacket(EncodeSequencedDataPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Debug Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripDebugPacket ==
    \A message \in CheckedDebugPacket :
        LET read == DecodeDebugPacket(EncodeDebugPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Accepted Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginAcceptedPacket ==
    \A message \in CheckedLoginAcceptedPacket :
        LET read == DecodeLoginAcceptedPacket(EncodeLoginAcceptedPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Rejected Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRejectedPacket ==
    \A message \in CheckedLoginRejectedPacket :
        LET read == DecodeLoginRejectedPacket(EncodeLoginRejectedPacket(message))
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

(* A Inbound Quote Messages Message Payload is selected by the Inbound Quote Messages Message Type it is written under *)
SelectsInboundQuoteMessagesMessagePayload ==
    \A message \in CheckedInboundQuoteMessagesMessagePayload :
        LET read == DecodeInboundQuoteMessagesMessagePayload(message.tag, EncodeInboundQuoteMessagesMessagePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Inbound Trade Messages Message Payload is selected by the Inbound Trade Messages Message Type it is written under *)
SelectsInboundTradeMessagesMessagePayload ==
    \A message \in CheckedInboundTradeMessagesMessagePayload :
        LET read == DecodeInboundTradeMessagesMessagePayload(message.tag, EncodeInboundTradeMessagesMessagePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Inbound Administrative Messages Message Payload is selected by the Inbound Administrative Messages Message Type it is written under *)
SelectsInboundAdministrativeMessagesMessagePayload ==
    \A message \in CheckedInboundAdministrativeMessagesMessagePayload :
        LET read == DecodeInboundAdministrativeMessagesMessagePayload(message.tag, EncodeInboundAdministrativeMessagesMessagePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Inbound Control Messages Message Payload is selected by the Inbound Control Messages Message Type it is written under *)
SelectsInboundControlMessagesMessagePayload ==
    \A message \in CheckedInboundControlMessagesMessagePayload :
        LET read == DecodeInboundControlMessagesMessagePayload(message.tag, EncodeInboundControlMessagesMessagePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Return Administrative Messages Message Payload is selected by the Return Administrative Messages Message Type it is written under *)
SelectsReturnAdministrativeMessagesMessagePayload ==
    \A message \in CheckedReturnAdministrativeMessagesMessagePayload :
        LET read == DecodeReturnAdministrativeMessagesMessagePayload(message.tag, EncodeReturnAdministrativeMessagesMessagePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Return Control Messages Message Payload is selected by the Return Control Messages Message Type it is written under *)
SelectsReturnControlMessagesMessagePayload ==
    \A message \in CheckedReturnControlMessagesMessagePayload :
        LET read == DecodeReturnControlMessagesMessagePayload(message.tag, EncodeReturnControlMessagesMessagePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Category Payload is selected by the Message Category it is written under *)
SelectsCategoryPayload ==
    \A message \in CheckedCategoryPayload :
        LET read == DecodeCategoryPayload(message.tag, EncodeCategoryPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Server Tcp Payload is selected by the Server Packet Type it is written under *)
SelectsServerTcpPayload ==
    \A message \in CheckedServerTcpPayload :
        LET read == DecodeServerTcpPayload(message.tag, EncodeServerTcpPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Packet Length is written from the bytes it frames *)
FramesServerPacket ==
    \A message \in CheckedServerPacket :
        LET bytes == EncodeServerPacket(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
