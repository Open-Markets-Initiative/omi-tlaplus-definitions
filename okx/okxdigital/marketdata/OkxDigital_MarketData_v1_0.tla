-------------------- MODULE OkxDigital_MarketData_v1_0 ---------------------
(***************************************************************************)
(* OKX Market Data v1.0                                                    *)
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
(* Bbo Tbt Channel Event Message: 74 bytes                                 *)
(***************************************************************************)

BboTbtChannelEventMessage ==
    [ instIdCode    : Sample(8),
      tsUs          : Sample(8),
      outTime       : Sample(8),
      seqId         : Sample(8),
      askPxMantissa : Sample(8),
      askSzMantissa : Sample(8),
      bidPxMantissa : Sample(8),
      bidSzMantissa : Sample(8),
      askOrdCount   : Sample(4),
      bidOrdCount   : Sample(4),
      pxExponent    : Sample(1),
      szExponent    : Sample(1) ]

EncodeBboTbtChannelEventMessage(message) ==
    message.instIdCode
        \o message.tsUs
        \o message.outTime
        \o message.seqId
        \o message.askPxMantissa
        \o message.askSzMantissa
        \o message.bidPxMantissa
        \o message.bidSzMantissa
        \o message.askOrdCount
        \o message.bidOrdCount
        \o message.pxExponent
        \o message.szExponent

DecodeBboTbtChannelEventMessage(bytes) ==
    LET instIdCode == ReadBytes(bytes, 8) IN IF ~instIdCode.ok THEN Fail ELSE
    LET tsUs == ReadBytes(instIdCode.rest, 8) IN IF ~tsUs.ok THEN Fail ELSE
    LET outTime == ReadBytes(tsUs.rest, 8) IN IF ~outTime.ok THEN Fail ELSE
    LET seqId == ReadBytes(outTime.rest, 8) IN IF ~seqId.ok THEN Fail ELSE
    LET askPxMantissa == ReadBytes(seqId.rest, 8) IN IF ~askPxMantissa.ok THEN Fail ELSE
    LET askSzMantissa == ReadBytes(askPxMantissa.rest, 8) IN IF ~askSzMantissa.ok THEN Fail ELSE
    LET bidPxMantissa == ReadBytes(askSzMantissa.rest, 8) IN IF ~bidPxMantissa.ok THEN Fail ELSE
    LET bidSzMantissa == ReadBytes(bidPxMantissa.rest, 8) IN IF ~bidSzMantissa.ok THEN Fail ELSE
    LET askOrdCount == ReadBytes(bidSzMantissa.rest, 4) IN IF ~askOrdCount.ok THEN Fail ELSE
    LET bidOrdCount == ReadBytes(askOrdCount.rest, 4) IN IF ~bidOrdCount.ok THEN Fail ELSE
    LET pxExponent == ReadBytes(bidOrdCount.rest, 1) IN IF ~pxExponent.ok THEN Fail ELSE
    LET szExponent == ReadBytes(pxExponent.rest, 1) IN IF ~szExponent.ok THEN Fail ELSE
    Ok([ instIdCode    |-> instIdCode.value,
         tsUs          |-> tsUs.value,
         outTime       |-> outTime.value,
         seqId         |-> seqId.value,
         askPxMantissa |-> askPxMantissa.value,
         askSzMantissa |-> askSzMantissa.value,
         bidPxMantissa |-> bidPxMantissa.value,
         bidSzMantissa |-> bidSzMantissa.value,
         askOrdCount   |-> askOrdCount.value,
         bidOrdCount   |-> bidOrdCount.value,
         pxExponent    |-> pxExponent.value,
         szExponent    |-> szExponent.value ], szExponent.rest)

ZeroBboTbtChannelEventMessage ==
    [ instIdCode    |-> [i \in 1 .. 8 |-> 0],
      tsUs          |-> [i \in 1 .. 8 |-> 0],
      outTime       |-> [i \in 1 .. 8 |-> 0],
      seqId         |-> [i \in 1 .. 8 |-> 0],
      askPxMantissa |-> [i \in 1 .. 8 |-> 0],
      askSzMantissa |-> [i \in 1 .. 8 |-> 0],
      bidPxMantissa |-> [i \in 1 .. 8 |-> 0],
      bidSzMantissa |-> [i \in 1 .. 8 |-> 0],
      askOrdCount   |-> [i \in 1 .. 4 |-> 0],
      bidOrdCount   |-> [i \in 1 .. 4 |-> 0],
      pxExponent    |-> [i \in 1 .. 1 |-> 0],
      szExponent    |-> [i \in 1 .. 1 |-> 0] ]

(* Bbo Tbt Channel Event Message at zero, then each field in turn at the values it is checked at *)
CheckedBboTbtChannelEventMessage ==
    { ZeroBboTbtChannelEventMessage }
        \cup { [ZeroBboTbtChannelEventMessage EXCEPT !.instIdCode = one] : one \in Sample(8) }
        \cup { [ZeroBboTbtChannelEventMessage EXCEPT !.tsUs = one] : one \in Sample(8) }
        \cup { [ZeroBboTbtChannelEventMessage EXCEPT !.outTime = one] : one \in Sample(8) }
        \cup { [ZeroBboTbtChannelEventMessage EXCEPT !.seqId = one] : one \in Sample(8) }
        \cup { [ZeroBboTbtChannelEventMessage EXCEPT !.askPxMantissa = one] : one \in Sample(8) }
        \cup { [ZeroBboTbtChannelEventMessage EXCEPT !.askSzMantissa = one] : one \in Sample(8) }
        \cup { [ZeroBboTbtChannelEventMessage EXCEPT !.bidPxMantissa = one] : one \in Sample(8) }
        \cup { [ZeroBboTbtChannelEventMessage EXCEPT !.bidSzMantissa = one] : one \in Sample(8) }
        \cup { [ZeroBboTbtChannelEventMessage EXCEPT !.askOrdCount = one] : one \in Sample(4) }
        \cup { [ZeroBboTbtChannelEventMessage EXCEPT !.bidOrdCount = one] : one \in Sample(4) }
        \cup { [ZeroBboTbtChannelEventMessage EXCEPT !.pxExponent = one] : one \in Sample(1) }
        \cup { [ZeroBboTbtChannelEventMessage EXCEPT !.szExponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Books L 2 Tbt Channel Event Message asks Group: 20 bytes                *)
(***************************************************************************)

BooksL2TbtChannelEventMessageAsksGroup ==
    [ pxMantissa : Sample(8),
      szMantissa : Sample(8),
      ordCount   : Sample(4) ]

EncodeBooksL2TbtChannelEventMessageAsksGroup(message) ==
    message.pxMantissa
        \o message.szMantissa
        \o message.ordCount

DecodeBooksL2TbtChannelEventMessageAsksGroup(bytes) ==
    LET pxMantissa == ReadBytes(bytes, 8) IN IF ~pxMantissa.ok THEN Fail ELSE
    LET szMantissa == ReadBytes(pxMantissa.rest, 8) IN IF ~szMantissa.ok THEN Fail ELSE
    LET ordCount == ReadBytes(szMantissa.rest, 4) IN IF ~ordCount.ok THEN Fail ELSE
    Ok([ pxMantissa |-> pxMantissa.value,
         szMantissa |-> szMantissa.value,
         ordCount   |-> ordCount.value ], ordCount.rest)

ZeroBooksL2TbtChannelEventMessageAsksGroup ==
    [ pxMantissa |-> [i \in 1 .. 8 |-> 0],
      szMantissa |-> [i \in 1 .. 8 |-> 0],
      ordCount   |-> [i \in 1 .. 4 |-> 0] ]

(* Books L 2 Tbt Channel Event Message asks Group at zero, then each field in turn at the values it is checked at *)
CheckedBooksL2TbtChannelEventMessageAsksGroup ==
    { ZeroBooksL2TbtChannelEventMessageAsksGroup }
        \cup { [ZeroBooksL2TbtChannelEventMessageAsksGroup EXCEPT !.pxMantissa = one] : one \in Sample(8) }
        \cup { [ZeroBooksL2TbtChannelEventMessageAsksGroup EXCEPT !.szMantissa = one] : one \in Sample(8) }
        \cup { [ZeroBooksL2TbtChannelEventMessageAsksGroup EXCEPT !.ordCount = one] : one \in Sample(4) }

(* A run of Books L 2 Tbt Channel Event Message asks Group, written one after another *)
RECURSIVE EncodeBooksL2TbtChannelEventMessageAsksGroupList(_)
EncodeBooksL2TbtChannelEventMessageAsksGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeBooksL2TbtChannelEventMessageAsksGroup(Head(messages)) \o EncodeBooksL2TbtChannelEventMessageAsksGroupList(Tail(messages))

(* As many Books L 2 Tbt Channel Event Message asks Group as the field that counts them says *)
RECURSIVE ReadBooksL2TbtChannelEventMessageAsksGroupList(_, _)
ReadBooksL2TbtChannelEventMessageAsksGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeBooksL2TbtChannelEventMessageAsksGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadBooksL2TbtChannelEventMessageAsksGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Books L 2 Tbt Channel Event Message asks Group of each kind, for the lists that carry them *)
OneBooksL2TbtChannelEventMessageAsksGroup == { ZeroBooksL2TbtChannelEventMessageAsksGroup }

(***************************************************************************)
(* Books L 2 Tbt Channel Event Message asks Groups                         *)
(***************************************************************************)

BooksL2TbtChannelEventMessageAsksGroups ==
    [ blockLength                            : Sample(2),
      booksL2TbtChannelEventMessageAsksGroup : SampleLists(OneBooksL2TbtChannelEventMessageAsksGroup) ]

EncodeBooksL2TbtChannelEventMessageAsksGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.booksL2TbtChannelEventMessageAsksGroup), 2)
        \o EncodeBooksL2TbtChannelEventMessageAsksGroupList(message.booksL2TbtChannelEventMessageAsksGroup)

DecodeBooksL2TbtChannelEventMessageAsksGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroup.ok THEN Fail ELSE
    LET booksL2TbtChannelEventMessageAsksGroup == ReadBooksL2TbtChannelEventMessageAsksGroupList(numInGroup.rest, numInGroup.value) IN IF ~booksL2TbtChannelEventMessageAsksGroup.ok THEN Fail ELSE
    Ok([ blockLength                            |-> blockLength.value,
         booksL2TbtChannelEventMessageAsksGroup |-> booksL2TbtChannelEventMessageAsksGroup.value ], booksL2TbtChannelEventMessageAsksGroup.rest)

ZeroBooksL2TbtChannelEventMessageAsksGroups ==
    [ blockLength                            |-> [i \in 1 .. 2 |-> 0],
      booksL2TbtChannelEventMessageAsksGroup |-> << >> ]

(* Books L 2 Tbt Channel Event Message asks Groups at zero, then each field in turn at the values it is checked at *)
CheckedBooksL2TbtChannelEventMessageAsksGroups ==
    { ZeroBooksL2TbtChannelEventMessageAsksGroups }
        \cup { [ZeroBooksL2TbtChannelEventMessageAsksGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroBooksL2TbtChannelEventMessageAsksGroups EXCEPT !.booksL2TbtChannelEventMessageAsksGroup = one] : one \in SampleLists(OneBooksL2TbtChannelEventMessageAsksGroup) }

(***************************************************************************)
(* Books L 2 Tbt Channel Event Message bids Group: 20 bytes                *)
(***************************************************************************)

BooksL2TbtChannelEventMessageBidsGroup ==
    [ pxMantissa : Sample(8),
      szMantissa : Sample(8),
      ordCount   : Sample(4) ]

EncodeBooksL2TbtChannelEventMessageBidsGroup(message) ==
    message.pxMantissa
        \o message.szMantissa
        \o message.ordCount

DecodeBooksL2TbtChannelEventMessageBidsGroup(bytes) ==
    LET pxMantissa == ReadBytes(bytes, 8) IN IF ~pxMantissa.ok THEN Fail ELSE
    LET szMantissa == ReadBytes(pxMantissa.rest, 8) IN IF ~szMantissa.ok THEN Fail ELSE
    LET ordCount == ReadBytes(szMantissa.rest, 4) IN IF ~ordCount.ok THEN Fail ELSE
    Ok([ pxMantissa |-> pxMantissa.value,
         szMantissa |-> szMantissa.value,
         ordCount   |-> ordCount.value ], ordCount.rest)

ZeroBooksL2TbtChannelEventMessageBidsGroup ==
    [ pxMantissa |-> [i \in 1 .. 8 |-> 0],
      szMantissa |-> [i \in 1 .. 8 |-> 0],
      ordCount   |-> [i \in 1 .. 4 |-> 0] ]

(* Books L 2 Tbt Channel Event Message bids Group at zero, then each field in turn at the values it is checked at *)
CheckedBooksL2TbtChannelEventMessageBidsGroup ==
    { ZeroBooksL2TbtChannelEventMessageBidsGroup }
        \cup { [ZeroBooksL2TbtChannelEventMessageBidsGroup EXCEPT !.pxMantissa = one] : one \in Sample(8) }
        \cup { [ZeroBooksL2TbtChannelEventMessageBidsGroup EXCEPT !.szMantissa = one] : one \in Sample(8) }
        \cup { [ZeroBooksL2TbtChannelEventMessageBidsGroup EXCEPT !.ordCount = one] : one \in Sample(4) }

(* A run of Books L 2 Tbt Channel Event Message bids Group, written one after another *)
RECURSIVE EncodeBooksL2TbtChannelEventMessageBidsGroupList(_)
EncodeBooksL2TbtChannelEventMessageBidsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeBooksL2TbtChannelEventMessageBidsGroup(Head(messages)) \o EncodeBooksL2TbtChannelEventMessageBidsGroupList(Tail(messages))

(* As many Books L 2 Tbt Channel Event Message bids Group as the field that counts them says *)
RECURSIVE ReadBooksL2TbtChannelEventMessageBidsGroupList(_, _)
ReadBooksL2TbtChannelEventMessageBidsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeBooksL2TbtChannelEventMessageBidsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadBooksL2TbtChannelEventMessageBidsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Books L 2 Tbt Channel Event Message bids Group of each kind, for the lists that carry them *)
OneBooksL2TbtChannelEventMessageBidsGroup == { ZeroBooksL2TbtChannelEventMessageBidsGroup }

(***************************************************************************)
(* Books L 2 Tbt Channel Event Message bids Groups                         *)
(***************************************************************************)

BooksL2TbtChannelEventMessageBidsGroups ==
    [ blockLength                            : Sample(2),
      booksL2TbtChannelEventMessageBidsGroup : SampleLists(OneBooksL2TbtChannelEventMessageBidsGroup) ]

EncodeBooksL2TbtChannelEventMessageBidsGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.booksL2TbtChannelEventMessageBidsGroup), 2)
        \o EncodeBooksL2TbtChannelEventMessageBidsGroupList(message.booksL2TbtChannelEventMessageBidsGroup)

DecodeBooksL2TbtChannelEventMessageBidsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroup.ok THEN Fail ELSE
    LET booksL2TbtChannelEventMessageBidsGroup == ReadBooksL2TbtChannelEventMessageBidsGroupList(numInGroup.rest, numInGroup.value) IN IF ~booksL2TbtChannelEventMessageBidsGroup.ok THEN Fail ELSE
    Ok([ blockLength                            |-> blockLength.value,
         booksL2TbtChannelEventMessageBidsGroup |-> booksL2TbtChannelEventMessageBidsGroup.value ], booksL2TbtChannelEventMessageBidsGroup.rest)

ZeroBooksL2TbtChannelEventMessageBidsGroups ==
    [ blockLength                            |-> [i \in 1 .. 2 |-> 0],
      booksL2TbtChannelEventMessageBidsGroup |-> << >> ]

(* Books L 2 Tbt Channel Event Message bids Groups at zero, then each field in turn at the values it is checked at *)
CheckedBooksL2TbtChannelEventMessageBidsGroups ==
    { ZeroBooksL2TbtChannelEventMessageBidsGroups }
        \cup { [ZeroBooksL2TbtChannelEventMessageBidsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroBooksL2TbtChannelEventMessageBidsGroups EXCEPT !.booksL2TbtChannelEventMessageBidsGroup = one] : one \in SampleLists(OneBooksL2TbtChannelEventMessageBidsGroup) }

(***************************************************************************)
(* Books L 2 Tbt Channel Event Message                                     *)
(***************************************************************************)

BooksL2TbtChannelEventMessage ==
    [ instIdCode                              : Sample(8),
      tsUs                                    : Sample(8),
      outTime                                 : Sample(8),
      seqId                                   : Sample(8),
      prevSeqId                               : Sample(8),
      pxExponent                              : Sample(1),
      szExponent                              : Sample(1),
      booksL2TbtChannelEventMessageAsksGroups : BooksL2TbtChannelEventMessageAsksGroups,
      booksL2TbtChannelEventMessageBidsGroups : BooksL2TbtChannelEventMessageBidsGroups ]

EncodeBooksL2TbtChannelEventMessage(message) ==
    message.instIdCode
        \o message.tsUs
        \o message.outTime
        \o message.seqId
        \o message.prevSeqId
        \o message.pxExponent
        \o message.szExponent
        \o EncodeBooksL2TbtChannelEventMessageAsksGroups(message.booksL2TbtChannelEventMessageAsksGroups)
        \o EncodeBooksL2TbtChannelEventMessageBidsGroups(message.booksL2TbtChannelEventMessageBidsGroups)

DecodeBooksL2TbtChannelEventMessage(bytes) ==
    LET instIdCode == ReadBytes(bytes, 8) IN IF ~instIdCode.ok THEN Fail ELSE
    LET tsUs == ReadBytes(instIdCode.rest, 8) IN IF ~tsUs.ok THEN Fail ELSE
    LET outTime == ReadBytes(tsUs.rest, 8) IN IF ~outTime.ok THEN Fail ELSE
    LET seqId == ReadBytes(outTime.rest, 8) IN IF ~seqId.ok THEN Fail ELSE
    LET prevSeqId == ReadBytes(seqId.rest, 8) IN IF ~prevSeqId.ok THEN Fail ELSE
    LET pxExponent == ReadBytes(prevSeqId.rest, 1) IN IF ~pxExponent.ok THEN Fail ELSE
    LET szExponent == ReadBytes(pxExponent.rest, 1) IN IF ~szExponent.ok THEN Fail ELSE
    LET booksL2TbtChannelEventMessageAsksGroups == DecodeBooksL2TbtChannelEventMessageAsksGroups(szExponent.rest) IN IF ~booksL2TbtChannelEventMessageAsksGroups.ok THEN Fail ELSE
    LET booksL2TbtChannelEventMessageBidsGroups == DecodeBooksL2TbtChannelEventMessageBidsGroups(booksL2TbtChannelEventMessageAsksGroups.rest) IN IF ~booksL2TbtChannelEventMessageBidsGroups.ok THEN Fail ELSE
    Ok([ instIdCode                              |-> instIdCode.value,
         tsUs                                    |-> tsUs.value,
         outTime                                 |-> outTime.value,
         seqId                                   |-> seqId.value,
         prevSeqId                               |-> prevSeqId.value,
         pxExponent                              |-> pxExponent.value,
         szExponent                              |-> szExponent.value,
         booksL2TbtChannelEventMessageAsksGroups |-> booksL2TbtChannelEventMessageAsksGroups.value,
         booksL2TbtChannelEventMessageBidsGroups |-> booksL2TbtChannelEventMessageBidsGroups.value ], booksL2TbtChannelEventMessageBidsGroups.rest)

ZeroBooksL2TbtChannelEventMessage ==
    [ instIdCode                              |-> [i \in 1 .. 8 |-> 0],
      tsUs                                    |-> [i \in 1 .. 8 |-> 0],
      outTime                                 |-> [i \in 1 .. 8 |-> 0],
      seqId                                   |-> [i \in 1 .. 8 |-> 0],
      prevSeqId                               |-> [i \in 1 .. 8 |-> 0],
      pxExponent                              |-> [i \in 1 .. 1 |-> 0],
      szExponent                              |-> [i \in 1 .. 1 |-> 0],
      booksL2TbtChannelEventMessageAsksGroups |-> ZeroBooksL2TbtChannelEventMessageAsksGroups,
      booksL2TbtChannelEventMessageBidsGroups |-> ZeroBooksL2TbtChannelEventMessageBidsGroups ]

(* Books L 2 Tbt Channel Event Message at zero, then each field in turn at the values it is checked at *)
CheckedBooksL2TbtChannelEventMessage ==
    { ZeroBooksL2TbtChannelEventMessage }
        \cup { [ZeroBooksL2TbtChannelEventMessage EXCEPT !.instIdCode = one] : one \in Sample(8) }
        \cup { [ZeroBooksL2TbtChannelEventMessage EXCEPT !.tsUs = one] : one \in Sample(8) }
        \cup { [ZeroBooksL2TbtChannelEventMessage EXCEPT !.outTime = one] : one \in Sample(8) }
        \cup { [ZeroBooksL2TbtChannelEventMessage EXCEPT !.seqId = one] : one \in Sample(8) }
        \cup { [ZeroBooksL2TbtChannelEventMessage EXCEPT !.prevSeqId = one] : one \in Sample(8) }
        \cup { [ZeroBooksL2TbtChannelEventMessage EXCEPT !.pxExponent = one] : one \in Sample(1) }
        \cup { [ZeroBooksL2TbtChannelEventMessage EXCEPT !.szExponent = one] : one \in Sample(1) }
        \cup { [ZeroBooksL2TbtChannelEventMessage EXCEPT !.booksL2TbtChannelEventMessageAsksGroups = one] : one \in CheckedBooksL2TbtChannelEventMessageAsksGroups }
        \cup { [ZeroBooksL2TbtChannelEventMessage EXCEPT !.booksL2TbtChannelEventMessageBidsGroups = one] : one \in CheckedBooksL2TbtChannelEventMessageBidsGroups }

(***************************************************************************)
(* Books L 2 Tbt Exponent Update Event Message: 42 bytes                   *)
(***************************************************************************)

BooksL2TbtExponentUpdateEventMessage ==
    [ instIdCode : Sample(8),
      tsUs       : Sample(8),
      outTime    : Sample(8),
      seqId      : Sample(8),
      prevSeqId  : Sample(8),
      pxExponent : Sample(1),
      szExponent : Sample(1) ]

EncodeBooksL2TbtExponentUpdateEventMessage(message) ==
    message.instIdCode
        \o message.tsUs
        \o message.outTime
        \o message.seqId
        \o message.prevSeqId
        \o message.pxExponent
        \o message.szExponent

DecodeBooksL2TbtExponentUpdateEventMessage(bytes) ==
    LET instIdCode == ReadBytes(bytes, 8) IN IF ~instIdCode.ok THEN Fail ELSE
    LET tsUs == ReadBytes(instIdCode.rest, 8) IN IF ~tsUs.ok THEN Fail ELSE
    LET outTime == ReadBytes(tsUs.rest, 8) IN IF ~outTime.ok THEN Fail ELSE
    LET seqId == ReadBytes(outTime.rest, 8) IN IF ~seqId.ok THEN Fail ELSE
    LET prevSeqId == ReadBytes(seqId.rest, 8) IN IF ~prevSeqId.ok THEN Fail ELSE
    LET pxExponent == ReadBytes(prevSeqId.rest, 1) IN IF ~pxExponent.ok THEN Fail ELSE
    LET szExponent == ReadBytes(pxExponent.rest, 1) IN IF ~szExponent.ok THEN Fail ELSE
    Ok([ instIdCode |-> instIdCode.value,
         tsUs       |-> tsUs.value,
         outTime    |-> outTime.value,
         seqId      |-> seqId.value,
         prevSeqId  |-> prevSeqId.value,
         pxExponent |-> pxExponent.value,
         szExponent |-> szExponent.value ], szExponent.rest)

ZeroBooksL2TbtExponentUpdateEventMessage ==
    [ instIdCode |-> [i \in 1 .. 8 |-> 0],
      tsUs       |-> [i \in 1 .. 8 |-> 0],
      outTime    |-> [i \in 1 .. 8 |-> 0],
      seqId      |-> [i \in 1 .. 8 |-> 0],
      prevSeqId  |-> [i \in 1 .. 8 |-> 0],
      pxExponent |-> [i \in 1 .. 1 |-> 0],
      szExponent |-> [i \in 1 .. 1 |-> 0] ]

(* Books L 2 Tbt Exponent Update Event Message at zero, then each field in turn at the values it is checked at *)
CheckedBooksL2TbtExponentUpdateEventMessage ==
    { ZeroBooksL2TbtExponentUpdateEventMessage }
        \cup { [ZeroBooksL2TbtExponentUpdateEventMessage EXCEPT !.instIdCode = one] : one \in Sample(8) }
        \cup { [ZeroBooksL2TbtExponentUpdateEventMessage EXCEPT !.tsUs = one] : one \in Sample(8) }
        \cup { [ZeroBooksL2TbtExponentUpdateEventMessage EXCEPT !.outTime = one] : one \in Sample(8) }
        \cup { [ZeroBooksL2TbtExponentUpdateEventMessage EXCEPT !.seqId = one] : one \in Sample(8) }
        \cup { [ZeroBooksL2TbtExponentUpdateEventMessage EXCEPT !.prevSeqId = one] : one \in Sample(8) }
        \cup { [ZeroBooksL2TbtExponentUpdateEventMessage EXCEPT !.pxExponent = one] : one \in Sample(1) }
        \cup { [ZeroBooksL2TbtExponentUpdateEventMessage EXCEPT !.szExponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Books L 2 Tbt Elp Channel Event Message asks Group: 20 bytes            *)
(***************************************************************************)

BooksL2TbtElpChannelEventMessageAsksGroup ==
    [ pxMantissa : Sample(8),
      szMantissa : Sample(8),
      ordCount   : Sample(4) ]

EncodeBooksL2TbtElpChannelEventMessageAsksGroup(message) ==
    message.pxMantissa
        \o message.szMantissa
        \o message.ordCount

DecodeBooksL2TbtElpChannelEventMessageAsksGroup(bytes) ==
    LET pxMantissa == ReadBytes(bytes, 8) IN IF ~pxMantissa.ok THEN Fail ELSE
    LET szMantissa == ReadBytes(pxMantissa.rest, 8) IN IF ~szMantissa.ok THEN Fail ELSE
    LET ordCount == ReadBytes(szMantissa.rest, 4) IN IF ~ordCount.ok THEN Fail ELSE
    Ok([ pxMantissa |-> pxMantissa.value,
         szMantissa |-> szMantissa.value,
         ordCount   |-> ordCount.value ], ordCount.rest)

ZeroBooksL2TbtElpChannelEventMessageAsksGroup ==
    [ pxMantissa |-> [i \in 1 .. 8 |-> 0],
      szMantissa |-> [i \in 1 .. 8 |-> 0],
      ordCount   |-> [i \in 1 .. 4 |-> 0] ]

(* Books L 2 Tbt Elp Channel Event Message asks Group at zero, then each field in turn at the values it is checked at *)
CheckedBooksL2TbtElpChannelEventMessageAsksGroup ==
    { ZeroBooksL2TbtElpChannelEventMessageAsksGroup }
        \cup { [ZeroBooksL2TbtElpChannelEventMessageAsksGroup EXCEPT !.pxMantissa = one] : one \in Sample(8) }
        \cup { [ZeroBooksL2TbtElpChannelEventMessageAsksGroup EXCEPT !.szMantissa = one] : one \in Sample(8) }
        \cup { [ZeroBooksL2TbtElpChannelEventMessageAsksGroup EXCEPT !.ordCount = one] : one \in Sample(4) }

(* A run of Books L 2 Tbt Elp Channel Event Message asks Group, written one after another *)
RECURSIVE EncodeBooksL2TbtElpChannelEventMessageAsksGroupList(_)
EncodeBooksL2TbtElpChannelEventMessageAsksGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeBooksL2TbtElpChannelEventMessageAsksGroup(Head(messages)) \o EncodeBooksL2TbtElpChannelEventMessageAsksGroupList(Tail(messages))

(* As many Books L 2 Tbt Elp Channel Event Message asks Group as the field that counts them says *)
RECURSIVE ReadBooksL2TbtElpChannelEventMessageAsksGroupList(_, _)
ReadBooksL2TbtElpChannelEventMessageAsksGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeBooksL2TbtElpChannelEventMessageAsksGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadBooksL2TbtElpChannelEventMessageAsksGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Books L 2 Tbt Elp Channel Event Message asks Group of each kind, for the lists that carry them *)
OneBooksL2TbtElpChannelEventMessageAsksGroup == { ZeroBooksL2TbtElpChannelEventMessageAsksGroup }

(***************************************************************************)
(* Books L 2 Tbt Elp Channel Event Message asks Groups                     *)
(***************************************************************************)

BooksL2TbtElpChannelEventMessageAsksGroups ==
    [ blockLength                               : Sample(2),
      booksL2TbtElpChannelEventMessageAsksGroup : SampleLists(OneBooksL2TbtElpChannelEventMessageAsksGroup) ]

EncodeBooksL2TbtElpChannelEventMessageAsksGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.booksL2TbtElpChannelEventMessageAsksGroup), 2)
        \o EncodeBooksL2TbtElpChannelEventMessageAsksGroupList(message.booksL2TbtElpChannelEventMessageAsksGroup)

DecodeBooksL2TbtElpChannelEventMessageAsksGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroup.ok THEN Fail ELSE
    LET booksL2TbtElpChannelEventMessageAsksGroup == ReadBooksL2TbtElpChannelEventMessageAsksGroupList(numInGroup.rest, numInGroup.value) IN IF ~booksL2TbtElpChannelEventMessageAsksGroup.ok THEN Fail ELSE
    Ok([ blockLength                               |-> blockLength.value,
         booksL2TbtElpChannelEventMessageAsksGroup |-> booksL2TbtElpChannelEventMessageAsksGroup.value ], booksL2TbtElpChannelEventMessageAsksGroup.rest)

ZeroBooksL2TbtElpChannelEventMessageAsksGroups ==
    [ blockLength                               |-> [i \in 1 .. 2 |-> 0],
      booksL2TbtElpChannelEventMessageAsksGroup |-> << >> ]

(* Books L 2 Tbt Elp Channel Event Message asks Groups at zero, then each field in turn at the values it is checked at *)
CheckedBooksL2TbtElpChannelEventMessageAsksGroups ==
    { ZeroBooksL2TbtElpChannelEventMessageAsksGroups }
        \cup { [ZeroBooksL2TbtElpChannelEventMessageAsksGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroBooksL2TbtElpChannelEventMessageAsksGroups EXCEPT !.booksL2TbtElpChannelEventMessageAsksGroup = one] : one \in SampleLists(OneBooksL2TbtElpChannelEventMessageAsksGroup) }

(***************************************************************************)
(* Books L 2 Tbt Elp Channel Event Message bids Group: 20 bytes            *)
(***************************************************************************)

BooksL2TbtElpChannelEventMessageBidsGroup ==
    [ pxMantissa : Sample(8),
      szMantissa : Sample(8),
      ordCount   : Sample(4) ]

EncodeBooksL2TbtElpChannelEventMessageBidsGroup(message) ==
    message.pxMantissa
        \o message.szMantissa
        \o message.ordCount

DecodeBooksL2TbtElpChannelEventMessageBidsGroup(bytes) ==
    LET pxMantissa == ReadBytes(bytes, 8) IN IF ~pxMantissa.ok THEN Fail ELSE
    LET szMantissa == ReadBytes(pxMantissa.rest, 8) IN IF ~szMantissa.ok THEN Fail ELSE
    LET ordCount == ReadBytes(szMantissa.rest, 4) IN IF ~ordCount.ok THEN Fail ELSE
    Ok([ pxMantissa |-> pxMantissa.value,
         szMantissa |-> szMantissa.value,
         ordCount   |-> ordCount.value ], ordCount.rest)

ZeroBooksL2TbtElpChannelEventMessageBidsGroup ==
    [ pxMantissa |-> [i \in 1 .. 8 |-> 0],
      szMantissa |-> [i \in 1 .. 8 |-> 0],
      ordCount   |-> [i \in 1 .. 4 |-> 0] ]

(* Books L 2 Tbt Elp Channel Event Message bids Group at zero, then each field in turn at the values it is checked at *)
CheckedBooksL2TbtElpChannelEventMessageBidsGroup ==
    { ZeroBooksL2TbtElpChannelEventMessageBidsGroup }
        \cup { [ZeroBooksL2TbtElpChannelEventMessageBidsGroup EXCEPT !.pxMantissa = one] : one \in Sample(8) }
        \cup { [ZeroBooksL2TbtElpChannelEventMessageBidsGroup EXCEPT !.szMantissa = one] : one \in Sample(8) }
        \cup { [ZeroBooksL2TbtElpChannelEventMessageBidsGroup EXCEPT !.ordCount = one] : one \in Sample(4) }

(* A run of Books L 2 Tbt Elp Channel Event Message bids Group, written one after another *)
RECURSIVE EncodeBooksL2TbtElpChannelEventMessageBidsGroupList(_)
EncodeBooksL2TbtElpChannelEventMessageBidsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeBooksL2TbtElpChannelEventMessageBidsGroup(Head(messages)) \o EncodeBooksL2TbtElpChannelEventMessageBidsGroupList(Tail(messages))

(* As many Books L 2 Tbt Elp Channel Event Message bids Group as the field that counts them says *)
RECURSIVE ReadBooksL2TbtElpChannelEventMessageBidsGroupList(_, _)
ReadBooksL2TbtElpChannelEventMessageBidsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeBooksL2TbtElpChannelEventMessageBidsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadBooksL2TbtElpChannelEventMessageBidsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Books L 2 Tbt Elp Channel Event Message bids Group of each kind, for the lists that carry them *)
OneBooksL2TbtElpChannelEventMessageBidsGroup == { ZeroBooksL2TbtElpChannelEventMessageBidsGroup }

(***************************************************************************)
(* Books L 2 Tbt Elp Channel Event Message bids Groups                     *)
(***************************************************************************)

BooksL2TbtElpChannelEventMessageBidsGroups ==
    [ blockLength                               : Sample(2),
      booksL2TbtElpChannelEventMessageBidsGroup : SampleLists(OneBooksL2TbtElpChannelEventMessageBidsGroup) ]

EncodeBooksL2TbtElpChannelEventMessageBidsGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.booksL2TbtElpChannelEventMessageBidsGroup), 2)
        \o EncodeBooksL2TbtElpChannelEventMessageBidsGroupList(message.booksL2TbtElpChannelEventMessageBidsGroup)

DecodeBooksL2TbtElpChannelEventMessageBidsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroup.ok THEN Fail ELSE
    LET booksL2TbtElpChannelEventMessageBidsGroup == ReadBooksL2TbtElpChannelEventMessageBidsGroupList(numInGroup.rest, numInGroup.value) IN IF ~booksL2TbtElpChannelEventMessageBidsGroup.ok THEN Fail ELSE
    Ok([ blockLength                               |-> blockLength.value,
         booksL2TbtElpChannelEventMessageBidsGroup |-> booksL2TbtElpChannelEventMessageBidsGroup.value ], booksL2TbtElpChannelEventMessageBidsGroup.rest)

ZeroBooksL2TbtElpChannelEventMessageBidsGroups ==
    [ blockLength                               |-> [i \in 1 .. 2 |-> 0],
      booksL2TbtElpChannelEventMessageBidsGroup |-> << >> ]

(* Books L 2 Tbt Elp Channel Event Message bids Groups at zero, then each field in turn at the values it is checked at *)
CheckedBooksL2TbtElpChannelEventMessageBidsGroups ==
    { ZeroBooksL2TbtElpChannelEventMessageBidsGroups }
        \cup { [ZeroBooksL2TbtElpChannelEventMessageBidsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroBooksL2TbtElpChannelEventMessageBidsGroups EXCEPT !.booksL2TbtElpChannelEventMessageBidsGroup = one] : one \in SampleLists(OneBooksL2TbtElpChannelEventMessageBidsGroup) }

(***************************************************************************)
(* Books L 2 Tbt Elp Channel Event Message                                 *)
(***************************************************************************)

BooksL2TbtElpChannelEventMessage ==
    [ instIdCode                                 : Sample(8),
      tsUs                                       : Sample(8),
      outTime                                    : Sample(8),
      seqId                                      : Sample(8),
      prevSeqId                                  : Sample(8),
      pxExponent                                 : Sample(1),
      szExponent                                 : Sample(1),
      booksL2TbtElpChannelEventMessageAsksGroups : BooksL2TbtElpChannelEventMessageAsksGroups,
      booksL2TbtElpChannelEventMessageBidsGroups : BooksL2TbtElpChannelEventMessageBidsGroups ]

EncodeBooksL2TbtElpChannelEventMessage(message) ==
    message.instIdCode
        \o message.tsUs
        \o message.outTime
        \o message.seqId
        \o message.prevSeqId
        \o message.pxExponent
        \o message.szExponent
        \o EncodeBooksL2TbtElpChannelEventMessageAsksGroups(message.booksL2TbtElpChannelEventMessageAsksGroups)
        \o EncodeBooksL2TbtElpChannelEventMessageBidsGroups(message.booksL2TbtElpChannelEventMessageBidsGroups)

DecodeBooksL2TbtElpChannelEventMessage(bytes) ==
    LET instIdCode == ReadBytes(bytes, 8) IN IF ~instIdCode.ok THEN Fail ELSE
    LET tsUs == ReadBytes(instIdCode.rest, 8) IN IF ~tsUs.ok THEN Fail ELSE
    LET outTime == ReadBytes(tsUs.rest, 8) IN IF ~outTime.ok THEN Fail ELSE
    LET seqId == ReadBytes(outTime.rest, 8) IN IF ~seqId.ok THEN Fail ELSE
    LET prevSeqId == ReadBytes(seqId.rest, 8) IN IF ~prevSeqId.ok THEN Fail ELSE
    LET pxExponent == ReadBytes(prevSeqId.rest, 1) IN IF ~pxExponent.ok THEN Fail ELSE
    LET szExponent == ReadBytes(pxExponent.rest, 1) IN IF ~szExponent.ok THEN Fail ELSE
    LET booksL2TbtElpChannelEventMessageAsksGroups == DecodeBooksL2TbtElpChannelEventMessageAsksGroups(szExponent.rest) IN IF ~booksL2TbtElpChannelEventMessageAsksGroups.ok THEN Fail ELSE
    LET booksL2TbtElpChannelEventMessageBidsGroups == DecodeBooksL2TbtElpChannelEventMessageBidsGroups(booksL2TbtElpChannelEventMessageAsksGroups.rest) IN IF ~booksL2TbtElpChannelEventMessageBidsGroups.ok THEN Fail ELSE
    Ok([ instIdCode                                 |-> instIdCode.value,
         tsUs                                       |-> tsUs.value,
         outTime                                    |-> outTime.value,
         seqId                                      |-> seqId.value,
         prevSeqId                                  |-> prevSeqId.value,
         pxExponent                                 |-> pxExponent.value,
         szExponent                                 |-> szExponent.value,
         booksL2TbtElpChannelEventMessageAsksGroups |-> booksL2TbtElpChannelEventMessageAsksGroups.value,
         booksL2TbtElpChannelEventMessageBidsGroups |-> booksL2TbtElpChannelEventMessageBidsGroups.value ], booksL2TbtElpChannelEventMessageBidsGroups.rest)

ZeroBooksL2TbtElpChannelEventMessage ==
    [ instIdCode                                 |-> [i \in 1 .. 8 |-> 0],
      tsUs                                       |-> [i \in 1 .. 8 |-> 0],
      outTime                                    |-> [i \in 1 .. 8 |-> 0],
      seqId                                      |-> [i \in 1 .. 8 |-> 0],
      prevSeqId                                  |-> [i \in 1 .. 8 |-> 0],
      pxExponent                                 |-> [i \in 1 .. 1 |-> 0],
      szExponent                                 |-> [i \in 1 .. 1 |-> 0],
      booksL2TbtElpChannelEventMessageAsksGroups |-> ZeroBooksL2TbtElpChannelEventMessageAsksGroups,
      booksL2TbtElpChannelEventMessageBidsGroups |-> ZeroBooksL2TbtElpChannelEventMessageBidsGroups ]

(* Books L 2 Tbt Elp Channel Event Message at zero, then each field in turn at the values it is checked at *)
CheckedBooksL2TbtElpChannelEventMessage ==
    { ZeroBooksL2TbtElpChannelEventMessage }
        \cup { [ZeroBooksL2TbtElpChannelEventMessage EXCEPT !.instIdCode = one] : one \in Sample(8) }
        \cup { [ZeroBooksL2TbtElpChannelEventMessage EXCEPT !.tsUs = one] : one \in Sample(8) }
        \cup { [ZeroBooksL2TbtElpChannelEventMessage EXCEPT !.outTime = one] : one \in Sample(8) }
        \cup { [ZeroBooksL2TbtElpChannelEventMessage EXCEPT !.seqId = one] : one \in Sample(8) }
        \cup { [ZeroBooksL2TbtElpChannelEventMessage EXCEPT !.prevSeqId = one] : one \in Sample(8) }
        \cup { [ZeroBooksL2TbtElpChannelEventMessage EXCEPT !.pxExponent = one] : one \in Sample(1) }
        \cup { [ZeroBooksL2TbtElpChannelEventMessage EXCEPT !.szExponent = one] : one \in Sample(1) }
        \cup { [ZeroBooksL2TbtElpChannelEventMessage EXCEPT !.booksL2TbtElpChannelEventMessageAsksGroups = one] : one \in CheckedBooksL2TbtElpChannelEventMessageAsksGroups }
        \cup { [ZeroBooksL2TbtElpChannelEventMessage EXCEPT !.booksL2TbtElpChannelEventMessageBidsGroups = one] : one \in CheckedBooksL2TbtElpChannelEventMessageBidsGroups }

(***************************************************************************)
(* Books L 2 Tbt Elp Exponent Update Event Message: 42 bytes               *)
(***************************************************************************)

BooksL2TbtElpExponentUpdateEventMessage ==
    [ instIdCode : Sample(8),
      tsUs       : Sample(8),
      outTime    : Sample(8),
      seqId      : Sample(8),
      prevSeqId  : Sample(8),
      pxExponent : Sample(1),
      szExponent : Sample(1) ]

EncodeBooksL2TbtElpExponentUpdateEventMessage(message) ==
    message.instIdCode
        \o message.tsUs
        \o message.outTime
        \o message.seqId
        \o message.prevSeqId
        \o message.pxExponent
        \o message.szExponent

DecodeBooksL2TbtElpExponentUpdateEventMessage(bytes) ==
    LET instIdCode == ReadBytes(bytes, 8) IN IF ~instIdCode.ok THEN Fail ELSE
    LET tsUs == ReadBytes(instIdCode.rest, 8) IN IF ~tsUs.ok THEN Fail ELSE
    LET outTime == ReadBytes(tsUs.rest, 8) IN IF ~outTime.ok THEN Fail ELSE
    LET seqId == ReadBytes(outTime.rest, 8) IN IF ~seqId.ok THEN Fail ELSE
    LET prevSeqId == ReadBytes(seqId.rest, 8) IN IF ~prevSeqId.ok THEN Fail ELSE
    LET pxExponent == ReadBytes(prevSeqId.rest, 1) IN IF ~pxExponent.ok THEN Fail ELSE
    LET szExponent == ReadBytes(pxExponent.rest, 1) IN IF ~szExponent.ok THEN Fail ELSE
    Ok([ instIdCode |-> instIdCode.value,
         tsUs       |-> tsUs.value,
         outTime    |-> outTime.value,
         seqId      |-> seqId.value,
         prevSeqId  |-> prevSeqId.value,
         pxExponent |-> pxExponent.value,
         szExponent |-> szExponent.value ], szExponent.rest)

ZeroBooksL2TbtElpExponentUpdateEventMessage ==
    [ instIdCode |-> [i \in 1 .. 8 |-> 0],
      tsUs       |-> [i \in 1 .. 8 |-> 0],
      outTime    |-> [i \in 1 .. 8 |-> 0],
      seqId      |-> [i \in 1 .. 8 |-> 0],
      prevSeqId  |-> [i \in 1 .. 8 |-> 0],
      pxExponent |-> [i \in 1 .. 1 |-> 0],
      szExponent |-> [i \in 1 .. 1 |-> 0] ]

(* Books L 2 Tbt Elp Exponent Update Event Message at zero, then each field in turn at the values it is checked at *)
CheckedBooksL2TbtElpExponentUpdateEventMessage ==
    { ZeroBooksL2TbtElpExponentUpdateEventMessage }
        \cup { [ZeroBooksL2TbtElpExponentUpdateEventMessage EXCEPT !.instIdCode = one] : one \in Sample(8) }
        \cup { [ZeroBooksL2TbtElpExponentUpdateEventMessage EXCEPT !.tsUs = one] : one \in Sample(8) }
        \cup { [ZeroBooksL2TbtElpExponentUpdateEventMessage EXCEPT !.outTime = one] : one \in Sample(8) }
        \cup { [ZeroBooksL2TbtElpExponentUpdateEventMessage EXCEPT !.seqId = one] : one \in Sample(8) }
        \cup { [ZeroBooksL2TbtElpExponentUpdateEventMessage EXCEPT !.prevSeqId = one] : one \in Sample(8) }
        \cup { [ZeroBooksL2TbtElpExponentUpdateEventMessage EXCEPT !.pxExponent = one] : one \in Sample(1) }
        \cup { [ZeroBooksL2TbtElpExponentUpdateEventMessage EXCEPT !.szExponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Trades Channel Event Message: 62 bytes                                  *)
(***************************************************************************)

TradesChannelEventMessage ==
    [ instIdCode : Sample(8),
      tsUs       : Sample(8),
      outTime    : Sample(8),
      seqId      : Sample(8),
      pxMantissa : Sample(8),
      szMantissa : Sample(8),
      tradeId    : Sample(8),
      count      : Sample(2),
      side       : Sample(1),
      pxExponent : Sample(1),
      szExponent : Sample(1),
      source     : Sample(1) ]

EncodeTradesChannelEventMessage(message) ==
    message.instIdCode
        \o message.tsUs
        \o message.outTime
        \o message.seqId
        \o message.pxMantissa
        \o message.szMantissa
        \o message.tradeId
        \o message.count
        \o message.side
        \o message.pxExponent
        \o message.szExponent
        \o message.source

DecodeTradesChannelEventMessage(bytes) ==
    LET instIdCode == ReadBytes(bytes, 8) IN IF ~instIdCode.ok THEN Fail ELSE
    LET tsUs == ReadBytes(instIdCode.rest, 8) IN IF ~tsUs.ok THEN Fail ELSE
    LET outTime == ReadBytes(tsUs.rest, 8) IN IF ~outTime.ok THEN Fail ELSE
    LET seqId == ReadBytes(outTime.rest, 8) IN IF ~seqId.ok THEN Fail ELSE
    LET pxMantissa == ReadBytes(seqId.rest, 8) IN IF ~pxMantissa.ok THEN Fail ELSE
    LET szMantissa == ReadBytes(pxMantissa.rest, 8) IN IF ~szMantissa.ok THEN Fail ELSE
    LET tradeId == ReadBytes(szMantissa.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET count == ReadBytes(tradeId.rest, 2) IN IF ~count.ok THEN Fail ELSE
    LET side == ReadBytes(count.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET pxExponent == ReadBytes(side.rest, 1) IN IF ~pxExponent.ok THEN Fail ELSE
    LET szExponent == ReadBytes(pxExponent.rest, 1) IN IF ~szExponent.ok THEN Fail ELSE
    LET source == ReadBytes(szExponent.rest, 1) IN IF ~source.ok THEN Fail ELSE
    Ok([ instIdCode |-> instIdCode.value,
         tsUs       |-> tsUs.value,
         outTime    |-> outTime.value,
         seqId      |-> seqId.value,
         pxMantissa |-> pxMantissa.value,
         szMantissa |-> szMantissa.value,
         tradeId    |-> tradeId.value,
         count      |-> count.value,
         side       |-> side.value,
         pxExponent |-> pxExponent.value,
         szExponent |-> szExponent.value,
         source     |-> source.value ], source.rest)

ZeroTradesChannelEventMessage ==
    [ instIdCode |-> [i \in 1 .. 8 |-> 0],
      tsUs       |-> [i \in 1 .. 8 |-> 0],
      outTime    |-> [i \in 1 .. 8 |-> 0],
      seqId      |-> [i \in 1 .. 8 |-> 0],
      pxMantissa |-> [i \in 1 .. 8 |-> 0],
      szMantissa |-> [i \in 1 .. 8 |-> 0],
      tradeId    |-> [i \in 1 .. 8 |-> 0],
      count      |-> [i \in 1 .. 2 |-> 0],
      side       |-> [i \in 1 .. 1 |-> 0],
      pxExponent |-> [i \in 1 .. 1 |-> 0],
      szExponent |-> [i \in 1 .. 1 |-> 0],
      source     |-> [i \in 1 .. 1 |-> 0] ]

(* Trades Channel Event Message at zero, then each field in turn at the values it is checked at *)
CheckedTradesChannelEventMessage ==
    { ZeroTradesChannelEventMessage }
        \cup { [ZeroTradesChannelEventMessage EXCEPT !.instIdCode = one] : one \in Sample(8) }
        \cup { [ZeroTradesChannelEventMessage EXCEPT !.tsUs = one] : one \in Sample(8) }
        \cup { [ZeroTradesChannelEventMessage EXCEPT !.outTime = one] : one \in Sample(8) }
        \cup { [ZeroTradesChannelEventMessage EXCEPT !.seqId = one] : one \in Sample(8) }
        \cup { [ZeroTradesChannelEventMessage EXCEPT !.pxMantissa = one] : one \in Sample(8) }
        \cup { [ZeroTradesChannelEventMessage EXCEPT !.szMantissa = one] : one \in Sample(8) }
        \cup { [ZeroTradesChannelEventMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroTradesChannelEventMessage EXCEPT !.count = one] : one \in Sample(2) }
        \cup { [ZeroTradesChannelEventMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroTradesChannelEventMessage EXCEPT !.pxExponent = one] : one \in Sample(1) }
        \cup { [ZeroTradesChannelEventMessage EXCEPT !.szExponent = one] : one \in Sample(1) }
        \cup { [ZeroTradesChannelEventMessage EXCEPT !.source = one] : one \in Sample(1) }

(***************************************************************************)
(* Snapshot Depth Response Event Message asks Group: 20 bytes              *)
(***************************************************************************)

SnapshotDepthResponseEventMessageAsksGroup ==
    [ pxMantissa : Sample(8),
      szMantissa : Sample(8),
      ordCount   : Sample(4) ]

EncodeSnapshotDepthResponseEventMessageAsksGroup(message) ==
    message.pxMantissa
        \o message.szMantissa
        \o message.ordCount

DecodeSnapshotDepthResponseEventMessageAsksGroup(bytes) ==
    LET pxMantissa == ReadBytes(bytes, 8) IN IF ~pxMantissa.ok THEN Fail ELSE
    LET szMantissa == ReadBytes(pxMantissa.rest, 8) IN IF ~szMantissa.ok THEN Fail ELSE
    LET ordCount == ReadBytes(szMantissa.rest, 4) IN IF ~ordCount.ok THEN Fail ELSE
    Ok([ pxMantissa |-> pxMantissa.value,
         szMantissa |-> szMantissa.value,
         ordCount   |-> ordCount.value ], ordCount.rest)

ZeroSnapshotDepthResponseEventMessageAsksGroup ==
    [ pxMantissa |-> [i \in 1 .. 8 |-> 0],
      szMantissa |-> [i \in 1 .. 8 |-> 0],
      ordCount   |-> [i \in 1 .. 4 |-> 0] ]

(* Snapshot Depth Response Event Message asks Group at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotDepthResponseEventMessageAsksGroup ==
    { ZeroSnapshotDepthResponseEventMessageAsksGroup }
        \cup { [ZeroSnapshotDepthResponseEventMessageAsksGroup EXCEPT !.pxMantissa = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotDepthResponseEventMessageAsksGroup EXCEPT !.szMantissa = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotDepthResponseEventMessageAsksGroup EXCEPT !.ordCount = one] : one \in Sample(4) }

(* A run of Snapshot Depth Response Event Message asks Group, written one after another *)
RECURSIVE EncodeSnapshotDepthResponseEventMessageAsksGroupList(_)
EncodeSnapshotDepthResponseEventMessageAsksGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSnapshotDepthResponseEventMessageAsksGroup(Head(messages)) \o EncodeSnapshotDepthResponseEventMessageAsksGroupList(Tail(messages))

(* As many Snapshot Depth Response Event Message asks Group as the field that counts them says *)
RECURSIVE ReadSnapshotDepthResponseEventMessageAsksGroupList(_, _)
ReadSnapshotDepthResponseEventMessageAsksGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSnapshotDepthResponseEventMessageAsksGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSnapshotDepthResponseEventMessageAsksGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Snapshot Depth Response Event Message asks Group of each kind, for the lists that carry them *)
OneSnapshotDepthResponseEventMessageAsksGroup == { ZeroSnapshotDepthResponseEventMessageAsksGroup }

(***************************************************************************)
(* Snapshot Depth Response Event Message asks Groups                       *)
(***************************************************************************)

SnapshotDepthResponseEventMessageAsksGroups ==
    [ blockLength                                : Sample(2),
      snapshotDepthResponseEventMessageAsksGroup : SampleLists(OneSnapshotDepthResponseEventMessageAsksGroup) ]

EncodeSnapshotDepthResponseEventMessageAsksGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.snapshotDepthResponseEventMessageAsksGroup), 2)
        \o EncodeSnapshotDepthResponseEventMessageAsksGroupList(message.snapshotDepthResponseEventMessageAsksGroup)

DecodeSnapshotDepthResponseEventMessageAsksGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroup.ok THEN Fail ELSE
    LET snapshotDepthResponseEventMessageAsksGroup == ReadSnapshotDepthResponseEventMessageAsksGroupList(numInGroup.rest, numInGroup.value) IN IF ~snapshotDepthResponseEventMessageAsksGroup.ok THEN Fail ELSE
    Ok([ blockLength                                |-> blockLength.value,
         snapshotDepthResponseEventMessageAsksGroup |-> snapshotDepthResponseEventMessageAsksGroup.value ], snapshotDepthResponseEventMessageAsksGroup.rest)

ZeroSnapshotDepthResponseEventMessageAsksGroups ==
    [ blockLength                                |-> [i \in 1 .. 2 |-> 0],
      snapshotDepthResponseEventMessageAsksGroup |-> << >> ]

(* Snapshot Depth Response Event Message asks Groups at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotDepthResponseEventMessageAsksGroups ==
    { ZeroSnapshotDepthResponseEventMessageAsksGroups }
        \cup { [ZeroSnapshotDepthResponseEventMessageAsksGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSnapshotDepthResponseEventMessageAsksGroups EXCEPT !.snapshotDepthResponseEventMessageAsksGroup = one] : one \in SampleLists(OneSnapshotDepthResponseEventMessageAsksGroup) }

(***************************************************************************)
(* Snapshot Depth Response Event Message bids Group: 20 bytes              *)
(***************************************************************************)

SnapshotDepthResponseEventMessageBidsGroup ==
    [ pxMantissa : Sample(8),
      szMantissa : Sample(8),
      ordCount   : Sample(4) ]

EncodeSnapshotDepthResponseEventMessageBidsGroup(message) ==
    message.pxMantissa
        \o message.szMantissa
        \o message.ordCount

DecodeSnapshotDepthResponseEventMessageBidsGroup(bytes) ==
    LET pxMantissa == ReadBytes(bytes, 8) IN IF ~pxMantissa.ok THEN Fail ELSE
    LET szMantissa == ReadBytes(pxMantissa.rest, 8) IN IF ~szMantissa.ok THEN Fail ELSE
    LET ordCount == ReadBytes(szMantissa.rest, 4) IN IF ~ordCount.ok THEN Fail ELSE
    Ok([ pxMantissa |-> pxMantissa.value,
         szMantissa |-> szMantissa.value,
         ordCount   |-> ordCount.value ], ordCount.rest)

ZeroSnapshotDepthResponseEventMessageBidsGroup ==
    [ pxMantissa |-> [i \in 1 .. 8 |-> 0],
      szMantissa |-> [i \in 1 .. 8 |-> 0],
      ordCount   |-> [i \in 1 .. 4 |-> 0] ]

(* Snapshot Depth Response Event Message bids Group at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotDepthResponseEventMessageBidsGroup ==
    { ZeroSnapshotDepthResponseEventMessageBidsGroup }
        \cup { [ZeroSnapshotDepthResponseEventMessageBidsGroup EXCEPT !.pxMantissa = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotDepthResponseEventMessageBidsGroup EXCEPT !.szMantissa = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotDepthResponseEventMessageBidsGroup EXCEPT !.ordCount = one] : one \in Sample(4) }

(* A run of Snapshot Depth Response Event Message bids Group, written one after another *)
RECURSIVE EncodeSnapshotDepthResponseEventMessageBidsGroupList(_)
EncodeSnapshotDepthResponseEventMessageBidsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSnapshotDepthResponseEventMessageBidsGroup(Head(messages)) \o EncodeSnapshotDepthResponseEventMessageBidsGroupList(Tail(messages))

(* As many Snapshot Depth Response Event Message bids Group as the field that counts them says *)
RECURSIVE ReadSnapshotDepthResponseEventMessageBidsGroupList(_, _)
ReadSnapshotDepthResponseEventMessageBidsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSnapshotDepthResponseEventMessageBidsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSnapshotDepthResponseEventMessageBidsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Snapshot Depth Response Event Message bids Group of each kind, for the lists that carry them *)
OneSnapshotDepthResponseEventMessageBidsGroup == { ZeroSnapshotDepthResponseEventMessageBidsGroup }

(***************************************************************************)
(* Snapshot Depth Response Event Message bids Groups                       *)
(***************************************************************************)

SnapshotDepthResponseEventMessageBidsGroups ==
    [ blockLength                                : Sample(2),
      snapshotDepthResponseEventMessageBidsGroup : SampleLists(OneSnapshotDepthResponseEventMessageBidsGroup) ]

EncodeSnapshotDepthResponseEventMessageBidsGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.snapshotDepthResponseEventMessageBidsGroup), 2)
        \o EncodeSnapshotDepthResponseEventMessageBidsGroupList(message.snapshotDepthResponseEventMessageBidsGroup)

DecodeSnapshotDepthResponseEventMessageBidsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroup.ok THEN Fail ELSE
    LET snapshotDepthResponseEventMessageBidsGroup == ReadSnapshotDepthResponseEventMessageBidsGroupList(numInGroup.rest, numInGroup.value) IN IF ~snapshotDepthResponseEventMessageBidsGroup.ok THEN Fail ELSE
    Ok([ blockLength                                |-> blockLength.value,
         snapshotDepthResponseEventMessageBidsGroup |-> snapshotDepthResponseEventMessageBidsGroup.value ], snapshotDepthResponseEventMessageBidsGroup.rest)

ZeroSnapshotDepthResponseEventMessageBidsGroups ==
    [ blockLength                                |-> [i \in 1 .. 2 |-> 0],
      snapshotDepthResponseEventMessageBidsGroup |-> << >> ]

(* Snapshot Depth Response Event Message bids Groups at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotDepthResponseEventMessageBidsGroups ==
    { ZeroSnapshotDepthResponseEventMessageBidsGroups }
        \cup { [ZeroSnapshotDepthResponseEventMessageBidsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSnapshotDepthResponseEventMessageBidsGroups EXCEPT !.snapshotDepthResponseEventMessageBidsGroup = one] : one \in SampleLists(OneSnapshotDepthResponseEventMessageBidsGroup) }

(***************************************************************************)
(* Snapshot Depth Response Event Message                                   *)
(***************************************************************************)

SnapshotDepthResponseEventMessage ==
    [ instIdCode                                  : Sample(8),
      tsUs                                        : Sample(8),
      seqId                                       : Sample(8),
      pxExponent                                  : Sample(1),
      szExponent                                  : Sample(1),
      snapshotDepthResponseEventMessageAsksGroups : SnapshotDepthResponseEventMessageAsksGroups,
      snapshotDepthResponseEventMessageBidsGroups : SnapshotDepthResponseEventMessageBidsGroups ]

EncodeSnapshotDepthResponseEventMessage(message) ==
    message.instIdCode
        \o message.tsUs
        \o message.seqId
        \o message.pxExponent
        \o message.szExponent
        \o EncodeSnapshotDepthResponseEventMessageAsksGroups(message.snapshotDepthResponseEventMessageAsksGroups)
        \o EncodeSnapshotDepthResponseEventMessageBidsGroups(message.snapshotDepthResponseEventMessageBidsGroups)

DecodeSnapshotDepthResponseEventMessage(bytes) ==
    LET instIdCode == ReadBytes(bytes, 8) IN IF ~instIdCode.ok THEN Fail ELSE
    LET tsUs == ReadBytes(instIdCode.rest, 8) IN IF ~tsUs.ok THEN Fail ELSE
    LET seqId == ReadBytes(tsUs.rest, 8) IN IF ~seqId.ok THEN Fail ELSE
    LET pxExponent == ReadBytes(seqId.rest, 1) IN IF ~pxExponent.ok THEN Fail ELSE
    LET szExponent == ReadBytes(pxExponent.rest, 1) IN IF ~szExponent.ok THEN Fail ELSE
    LET snapshotDepthResponseEventMessageAsksGroups == DecodeSnapshotDepthResponseEventMessageAsksGroups(szExponent.rest) IN IF ~snapshotDepthResponseEventMessageAsksGroups.ok THEN Fail ELSE
    LET snapshotDepthResponseEventMessageBidsGroups == DecodeSnapshotDepthResponseEventMessageBidsGroups(snapshotDepthResponseEventMessageAsksGroups.rest) IN IF ~snapshotDepthResponseEventMessageBidsGroups.ok THEN Fail ELSE
    Ok([ instIdCode                                  |-> instIdCode.value,
         tsUs                                        |-> tsUs.value,
         seqId                                       |-> seqId.value,
         pxExponent                                  |-> pxExponent.value,
         szExponent                                  |-> szExponent.value,
         snapshotDepthResponseEventMessageAsksGroups |-> snapshotDepthResponseEventMessageAsksGroups.value,
         snapshotDepthResponseEventMessageBidsGroups |-> snapshotDepthResponseEventMessageBidsGroups.value ], snapshotDepthResponseEventMessageBidsGroups.rest)

ZeroSnapshotDepthResponseEventMessage ==
    [ instIdCode                                  |-> [i \in 1 .. 8 |-> 0],
      tsUs                                        |-> [i \in 1 .. 8 |-> 0],
      seqId                                       |-> [i \in 1 .. 8 |-> 0],
      pxExponent                                  |-> [i \in 1 .. 1 |-> 0],
      szExponent                                  |-> [i \in 1 .. 1 |-> 0],
      snapshotDepthResponseEventMessageAsksGroups |-> ZeroSnapshotDepthResponseEventMessageAsksGroups,
      snapshotDepthResponseEventMessageBidsGroups |-> ZeroSnapshotDepthResponseEventMessageBidsGroups ]

(* Snapshot Depth Response Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotDepthResponseEventMessage ==
    { ZeroSnapshotDepthResponseEventMessage }
        \cup { [ZeroSnapshotDepthResponseEventMessage EXCEPT !.instIdCode = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotDepthResponseEventMessage EXCEPT !.tsUs = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotDepthResponseEventMessage EXCEPT !.seqId = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotDepthResponseEventMessage EXCEPT !.pxExponent = one] : one \in Sample(1) }
        \cup { [ZeroSnapshotDepthResponseEventMessage EXCEPT !.szExponent = one] : one \in Sample(1) }
        \cup { [ZeroSnapshotDepthResponseEventMessage EXCEPT !.snapshotDepthResponseEventMessageAsksGroups = one] : one \in CheckedSnapshotDepthResponseEventMessageAsksGroups }
        \cup { [ZeroSnapshotDepthResponseEventMessage EXCEPT !.snapshotDepthResponseEventMessageBidsGroups = one] : one \in CheckedSnapshotDepthResponseEventMessageBidsGroups }

(***************************************************************************)
(* Payload, selected by Template Id                                        *)
(***************************************************************************)

BboTbtChannelEventMessageCode == 1000  \* 0x3e8
BooksL2TbtChannelEventMessageCode == 1001  \* 0x3e9
BooksL2TbtExponentUpdateEventMessageCode == 1002  \* 0x3ea
BooksL2TbtElpChannelEventMessageCode == 1003  \* 0x3eb
BooksL2TbtElpExponentUpdateEventMessageCode == 1004  \* 0x3ec
TradesChannelEventMessageCode == 1005  \* 0x3ed
SnapshotDepthResponseEventMessageCode == 1006  \* 0x3ee

Payload ==
    [ tag : {BboTbtChannelEventMessageCode}, body : BboTbtChannelEventMessage ]
        \cup [ tag : {BooksL2TbtChannelEventMessageCode}, body : BooksL2TbtChannelEventMessage ]
        \cup [ tag : {BooksL2TbtExponentUpdateEventMessageCode}, body : BooksL2TbtExponentUpdateEventMessage ]
        \cup [ tag : {BooksL2TbtElpChannelEventMessageCode}, body : BooksL2TbtElpChannelEventMessage ]
        \cup [ tag : {BooksL2TbtElpExponentUpdateEventMessageCode}, body : BooksL2TbtElpExponentUpdateEventMessage ]
        \cup [ tag : {TradesChannelEventMessageCode}, body : TradesChannelEventMessage ]
        \cup [ tag : {SnapshotDepthResponseEventMessageCode}, body : SnapshotDepthResponseEventMessage ]

EncodePayload(message) ==
    CASE message.tag = BboTbtChannelEventMessageCode -> EncodeBboTbtChannelEventMessage(message.body)
      [] message.tag = BooksL2TbtChannelEventMessageCode -> EncodeBooksL2TbtChannelEventMessage(message.body)
      [] message.tag = BooksL2TbtExponentUpdateEventMessageCode -> EncodeBooksL2TbtExponentUpdateEventMessage(message.body)
      [] message.tag = BooksL2TbtElpChannelEventMessageCode -> EncodeBooksL2TbtElpChannelEventMessage(message.body)
      [] message.tag = BooksL2TbtElpExponentUpdateEventMessageCode -> EncodeBooksL2TbtElpExponentUpdateEventMessage(message.body)
      [] message.tag = TradesChannelEventMessageCode -> EncodeTradesChannelEventMessage(message.body)
      [] message.tag = SnapshotDepthResponseEventMessageCode -> EncodeSnapshotDepthResponseEventMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = BboTbtChannelEventMessageCode -> DecodeBboTbtChannelEventMessage(bytes)
              [] tag = BooksL2TbtChannelEventMessageCode -> DecodeBooksL2TbtChannelEventMessage(bytes)
              [] tag = BooksL2TbtExponentUpdateEventMessageCode -> DecodeBooksL2TbtExponentUpdateEventMessage(bytes)
              [] tag = BooksL2TbtElpChannelEventMessageCode -> DecodeBooksL2TbtElpChannelEventMessage(bytes)
              [] tag = BooksL2TbtElpExponentUpdateEventMessageCode -> DecodeBooksL2TbtElpExponentUpdateEventMessage(bytes)
              [] tag = TradesChannelEventMessageCode -> DecodeTradesChannelEventMessage(bytes)
              [] tag = SnapshotDepthResponseEventMessageCode -> DecodeSnapshotDepthResponseEventMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> BboTbtChannelEventMessageCode, body |-> ZeroBboTbtChannelEventMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> BboTbtChannelEventMessageCode, body |-> one] : one \in CheckedBboTbtChannelEventMessage }
        \cup { [tag |-> BooksL2TbtChannelEventMessageCode, body |-> one] : one \in CheckedBooksL2TbtChannelEventMessage }
        \cup { [tag |-> BooksL2TbtExponentUpdateEventMessageCode, body |-> one] : one \in CheckedBooksL2TbtExponentUpdateEventMessage }
        \cup { [tag |-> BooksL2TbtElpChannelEventMessageCode, body |-> one] : one \in CheckedBooksL2TbtElpChannelEventMessage }
        \cup { [tag |-> BooksL2TbtElpExponentUpdateEventMessageCode, body |-> one] : one \in CheckedBooksL2TbtElpExponentUpdateEventMessage }
        \cup { [tag |-> TradesChannelEventMessageCode, body |-> one] : one \in CheckedTradesChannelEventMessage }
        \cup { [tag |-> SnapshotDepthResponseEventMessageCode, body |-> one] : one \in CheckedSnapshotDepthResponseEventMessage }

(***************************************************************************)
(* Sbe Message                                                             *)
(***************************************************************************)

SbeMessage ==
    [ blockLength : Sample(2),
      schemaId    : Sample(2),
      version     : Sample(2),
      payload     : Payload ]

EncodeSbeMessage(message) ==
    message.blockLength
        \o EncodeUIntLE(message.payload.tag, 2)
        \o message.schemaId
        \o message.version
        \o EncodePayload(message.payload)

DecodeSbeMessage(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET templateId == ReadUIntLE(blockLength.rest, 2) IN IF ~templateId.ok THEN Fail ELSE
    LET schemaId == ReadBytes(templateId.rest, 2) IN IF ~schemaId.ok THEN Fail ELSE
    LET version == ReadBytes(schemaId.rest, 2) IN IF ~version.ok THEN Fail ELSE
    LET payload == DecodePayload(templateId.value, version.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ blockLength |-> blockLength.value,
         schemaId    |-> schemaId.value,
         version     |-> version.value,
         payload     |-> payload.value ], payload.rest)

ZeroSbeMessage ==
    [ blockLength |-> [i \in 1 .. 2 |-> 0],
      schemaId    |-> [i \in 1 .. 2 |-> 0],
      version     |-> [i \in 1 .. 2 |-> 0],
      payload     |-> ZeroPayload ]

(* Sbe Message at zero, then each field in turn at the values it is checked at *)
CheckedSbeMessage ==
    { ZeroSbeMessage }
        \cup { [ZeroSbeMessage EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSbeMessage EXCEPT !.schemaId = one] : one \in Sample(2) }
        \cup { [ZeroSbeMessage EXCEPT !.version = one] : one \in Sample(2) }
        \cup { [ZeroSbeMessage EXCEPT !.payload = one] : one \in CheckedPayload }

(***************************************************************************)
(* Frame                                                                   *)
(***************************************************************************)

Frame ==
    [ sbeMessage : SbeMessage ]

EncodeFrame(message) ==
    EncodeSbeMessage(message.sbeMessage)

DecodeFrame(bytes) ==
    LET sbeMessage == DecodeSbeMessage(bytes) IN IF ~sbeMessage.ok THEN Fail ELSE
    Ok([ sbeMessage |-> sbeMessage.value ], sbeMessage.rest)

ZeroFrame ==
    [ sbeMessage |-> ZeroSbeMessage ]

(* Frame at zero, then each field in turn at the values it is checked at *)
CheckedFrame ==
    { ZeroFrame }
        \cup { [ZeroFrame EXCEPT !.sbeMessage = one] : one \in CheckedSbeMessage }

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

(* Every Bbo Tbt Channel Event Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBboTbtChannelEventMessage ==
    \A message \in CheckedBboTbtChannelEventMessage :
        LET read == DecodeBboTbtChannelEventMessage(EncodeBboTbtChannelEventMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Books L 2 Tbt Channel Event Message asks Group decodes back to what was encoded, and leaves nothing over *)
RoundTripBooksL2TbtChannelEventMessageAsksGroup ==
    \A message \in CheckedBooksL2TbtChannelEventMessageAsksGroup :
        LET read == DecodeBooksL2TbtChannelEventMessageAsksGroup(EncodeBooksL2TbtChannelEventMessageAsksGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Books L 2 Tbt Channel Event Message asks Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripBooksL2TbtChannelEventMessageAsksGroups ==
    \A message \in CheckedBooksL2TbtChannelEventMessageAsksGroups :
        LET read == DecodeBooksL2TbtChannelEventMessageAsksGroups(EncodeBooksL2TbtChannelEventMessageAsksGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Books L 2 Tbt Channel Event Message bids Group decodes back to what was encoded, and leaves nothing over *)
RoundTripBooksL2TbtChannelEventMessageBidsGroup ==
    \A message \in CheckedBooksL2TbtChannelEventMessageBidsGroup :
        LET read == DecodeBooksL2TbtChannelEventMessageBidsGroup(EncodeBooksL2TbtChannelEventMessageBidsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Books L 2 Tbt Channel Event Message bids Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripBooksL2TbtChannelEventMessageBidsGroups ==
    \A message \in CheckedBooksL2TbtChannelEventMessageBidsGroups :
        LET read == DecodeBooksL2TbtChannelEventMessageBidsGroups(EncodeBooksL2TbtChannelEventMessageBidsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Books L 2 Tbt Channel Event Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBooksL2TbtChannelEventMessage ==
    \A message \in CheckedBooksL2TbtChannelEventMessage :
        LET read == DecodeBooksL2TbtChannelEventMessage(EncodeBooksL2TbtChannelEventMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Books L 2 Tbt Exponent Update Event Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBooksL2TbtExponentUpdateEventMessage ==
    \A message \in CheckedBooksL2TbtExponentUpdateEventMessage :
        LET read == DecodeBooksL2TbtExponentUpdateEventMessage(EncodeBooksL2TbtExponentUpdateEventMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Books L 2 Tbt Elp Channel Event Message asks Group decodes back to what was encoded, and leaves nothing over *)
RoundTripBooksL2TbtElpChannelEventMessageAsksGroup ==
    \A message \in CheckedBooksL2TbtElpChannelEventMessageAsksGroup :
        LET read == DecodeBooksL2TbtElpChannelEventMessageAsksGroup(EncodeBooksL2TbtElpChannelEventMessageAsksGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Books L 2 Tbt Elp Channel Event Message asks Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripBooksL2TbtElpChannelEventMessageAsksGroups ==
    \A message \in CheckedBooksL2TbtElpChannelEventMessageAsksGroups :
        LET read == DecodeBooksL2TbtElpChannelEventMessageAsksGroups(EncodeBooksL2TbtElpChannelEventMessageAsksGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Books L 2 Tbt Elp Channel Event Message bids Group decodes back to what was encoded, and leaves nothing over *)
RoundTripBooksL2TbtElpChannelEventMessageBidsGroup ==
    \A message \in CheckedBooksL2TbtElpChannelEventMessageBidsGroup :
        LET read == DecodeBooksL2TbtElpChannelEventMessageBidsGroup(EncodeBooksL2TbtElpChannelEventMessageBidsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Books L 2 Tbt Elp Channel Event Message bids Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripBooksL2TbtElpChannelEventMessageBidsGroups ==
    \A message \in CheckedBooksL2TbtElpChannelEventMessageBidsGroups :
        LET read == DecodeBooksL2TbtElpChannelEventMessageBidsGroups(EncodeBooksL2TbtElpChannelEventMessageBidsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Books L 2 Tbt Elp Channel Event Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBooksL2TbtElpChannelEventMessage ==
    \A message \in CheckedBooksL2TbtElpChannelEventMessage :
        LET read == DecodeBooksL2TbtElpChannelEventMessage(EncodeBooksL2TbtElpChannelEventMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Books L 2 Tbt Elp Exponent Update Event Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBooksL2TbtElpExponentUpdateEventMessage ==
    \A message \in CheckedBooksL2TbtElpExponentUpdateEventMessage :
        LET read == DecodeBooksL2TbtElpExponentUpdateEventMessage(EncodeBooksL2TbtElpExponentUpdateEventMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trades Channel Event Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradesChannelEventMessage ==
    \A message \in CheckedTradesChannelEventMessage :
        LET read == DecodeTradesChannelEventMessage(EncodeTradesChannelEventMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Depth Response Event Message asks Group decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotDepthResponseEventMessageAsksGroup ==
    \A message \in CheckedSnapshotDepthResponseEventMessageAsksGroup :
        LET read == DecodeSnapshotDepthResponseEventMessageAsksGroup(EncodeSnapshotDepthResponseEventMessageAsksGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Depth Response Event Message asks Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotDepthResponseEventMessageAsksGroups ==
    \A message \in CheckedSnapshotDepthResponseEventMessageAsksGroups :
        LET read == DecodeSnapshotDepthResponseEventMessageAsksGroups(EncodeSnapshotDepthResponseEventMessageAsksGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Depth Response Event Message bids Group decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotDepthResponseEventMessageBidsGroup ==
    \A message \in CheckedSnapshotDepthResponseEventMessageBidsGroup :
        LET read == DecodeSnapshotDepthResponseEventMessageBidsGroup(EncodeSnapshotDepthResponseEventMessageBidsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Depth Response Event Message bids Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotDepthResponseEventMessageBidsGroups ==
    \A message \in CheckedSnapshotDepthResponseEventMessageBidsGroups :
        LET read == DecodeSnapshotDepthResponseEventMessageBidsGroups(EncodeSnapshotDepthResponseEventMessageBidsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Depth Response Event Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotDepthResponseEventMessage ==
    \A message \in CheckedSnapshotDepthResponseEventMessage :
        LET read == DecodeSnapshotDepthResponseEventMessage(EncodeSnapshotDepthResponseEventMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sbe Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSbeMessage ==
    \A message \in CheckedSbeMessage :
        LET read == DecodeSbeMessage(EncodeSbeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Frame decodes back to what was encoded, and leaves nothing over *)
RoundTripFrame ==
    \A message \in CheckedFrame :
        LET read == DecodeFrame(EncodeFrame(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Payload is selected by the Template Id it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
