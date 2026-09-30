--------------------- MODULE Nasdaq_Uqdf_Output_v3_0_c ---------------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Output v3.0.c                                                  *)
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
(* Note: a Message Count of 0 marks Heartbeat and carries no Message.      *)
(*                                                                         *)
(* Note: a Message Count of 0 marks End Of Session and carries no Message. *)
(*                                                                         *)
(* Note: a Nbbo Appendage Indicator of any value but 50 or 51 carries none *)
(* of them.                                                                *)
(*                                                                         *)
(* Note: a Bolo Appendage Indicator of any value but 50 or 51 or 53        *)
(* carries none of them.                                                   *)
(*                                                                         *)
(* Note: a Finra Adf Mpid Appendage Indicator of any value but 50 carries  *)
(* none of them.                                                           *)
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
(* National Bbo Appendage Shortform: 11 bytes                              *)
(***************************************************************************)

NationalBboAppendageShortform ==
    [ nbboQuoteCondition          : Sample(1),
      nationalBestBidMarketCenter : Sample(1),
      nationalBestBidPriceShort   : Sample(2),
      nationalBestBidSizeShort    : Sample(2),
      nationalBestAskMarketCenter : Sample(1),
      nationalBestAskPriceShort   : Sample(2),
      nationalBestAskSizeShort    : Sample(2) ]

EncodeNationalBboAppendageShortform(message) ==
    message.nbboQuoteCondition
        \o message.nationalBestBidMarketCenter
        \o message.nationalBestBidPriceShort
        \o message.nationalBestBidSizeShort
        \o message.nationalBestAskMarketCenter
        \o message.nationalBestAskPriceShort
        \o message.nationalBestAskSizeShort

DecodeNationalBboAppendageShortform(bytes) ==
    LET nbboQuoteCondition == ReadBytes(bytes, 1) IN IF ~nbboQuoteCondition.ok THEN Fail ELSE
    LET nationalBestBidMarketCenter == ReadBytes(nbboQuoteCondition.rest, 1) IN IF ~nationalBestBidMarketCenter.ok THEN Fail ELSE
    LET nationalBestBidPriceShort == ReadBytes(nationalBestBidMarketCenter.rest, 2) IN IF ~nationalBestBidPriceShort.ok THEN Fail ELSE
    LET nationalBestBidSizeShort == ReadBytes(nationalBestBidPriceShort.rest, 2) IN IF ~nationalBestBidSizeShort.ok THEN Fail ELSE
    LET nationalBestAskMarketCenter == ReadBytes(nationalBestBidSizeShort.rest, 1) IN IF ~nationalBestAskMarketCenter.ok THEN Fail ELSE
    LET nationalBestAskPriceShort == ReadBytes(nationalBestAskMarketCenter.rest, 2) IN IF ~nationalBestAskPriceShort.ok THEN Fail ELSE
    LET nationalBestAskSizeShort == ReadBytes(nationalBestAskPriceShort.rest, 2) IN IF ~nationalBestAskSizeShort.ok THEN Fail ELSE
    Ok([ nbboQuoteCondition          |-> nbboQuoteCondition.value,
         nationalBestBidMarketCenter |-> nationalBestBidMarketCenter.value,
         nationalBestBidPriceShort   |-> nationalBestBidPriceShort.value,
         nationalBestBidSizeShort    |-> nationalBestBidSizeShort.value,
         nationalBestAskMarketCenter |-> nationalBestAskMarketCenter.value,
         nationalBestAskPriceShort   |-> nationalBestAskPriceShort.value,
         nationalBestAskSizeShort    |-> nationalBestAskSizeShort.value ], nationalBestAskSizeShort.rest)

ZeroNationalBboAppendageShortform ==
    [ nbboQuoteCondition          |-> [i \in 1 .. 1 |-> 0],
      nationalBestBidMarketCenter |-> [i \in 1 .. 1 |-> 0],
      nationalBestBidPriceShort   |-> [i \in 1 .. 2 |-> 0],
      nationalBestBidSizeShort    |-> [i \in 1 .. 2 |-> 0],
      nationalBestAskMarketCenter |-> [i \in 1 .. 1 |-> 0],
      nationalBestAskPriceShort   |-> [i \in 1 .. 2 |-> 0],
      nationalBestAskSizeShort    |-> [i \in 1 .. 2 |-> 0] ]

(* National Bbo Appendage Shortform at zero, then each field in turn at the values it is checked at *)
CheckedNationalBboAppendageShortform ==
    { ZeroNationalBboAppendageShortform }
        \cup { [ZeroNationalBboAppendageShortform EXCEPT !.nbboQuoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroNationalBboAppendageShortform EXCEPT !.nationalBestBidMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroNationalBboAppendageShortform EXCEPT !.nationalBestBidPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroNationalBboAppendageShortform EXCEPT !.nationalBestBidSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroNationalBboAppendageShortform EXCEPT !.nationalBestAskMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroNationalBboAppendageShortform EXCEPT !.nationalBestAskPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroNationalBboAppendageShortform EXCEPT !.nationalBestAskSizeShort = one] : one \in Sample(2) }

(***************************************************************************)
(* National Bbo Appendage Longform: 27 bytes                               *)
(***************************************************************************)

NationalBboAppendageLongform ==
    [ nbboQuoteCondition          : Sample(1),
      nationalBestBidMarketCenter : Sample(1),
      nationalBestBidPriceLong    : Sample(8),
      nationalBestBidSizeLong     : Sample(4),
      nationalBestAskMarketCenter : Sample(1),
      nationalBestAskPriceLong    : Sample(8),
      nationalBestAskSizeLong     : Sample(4) ]

EncodeNationalBboAppendageLongform(message) ==
    message.nbboQuoteCondition
        \o message.nationalBestBidMarketCenter
        \o message.nationalBestBidPriceLong
        \o message.nationalBestBidSizeLong
        \o message.nationalBestAskMarketCenter
        \o message.nationalBestAskPriceLong
        \o message.nationalBestAskSizeLong

DecodeNationalBboAppendageLongform(bytes) ==
    LET nbboQuoteCondition == ReadBytes(bytes, 1) IN IF ~nbboQuoteCondition.ok THEN Fail ELSE
    LET nationalBestBidMarketCenter == ReadBytes(nbboQuoteCondition.rest, 1) IN IF ~nationalBestBidMarketCenter.ok THEN Fail ELSE
    LET nationalBestBidPriceLong == ReadBytes(nationalBestBidMarketCenter.rest, 8) IN IF ~nationalBestBidPriceLong.ok THEN Fail ELSE
    LET nationalBestBidSizeLong == ReadBytes(nationalBestBidPriceLong.rest, 4) IN IF ~nationalBestBidSizeLong.ok THEN Fail ELSE
    LET nationalBestAskMarketCenter == ReadBytes(nationalBestBidSizeLong.rest, 1) IN IF ~nationalBestAskMarketCenter.ok THEN Fail ELSE
    LET nationalBestAskPriceLong == ReadBytes(nationalBestAskMarketCenter.rest, 8) IN IF ~nationalBestAskPriceLong.ok THEN Fail ELSE
    LET nationalBestAskSizeLong == ReadBytes(nationalBestAskPriceLong.rest, 4) IN IF ~nationalBestAskSizeLong.ok THEN Fail ELSE
    Ok([ nbboQuoteCondition          |-> nbboQuoteCondition.value,
         nationalBestBidMarketCenter |-> nationalBestBidMarketCenter.value,
         nationalBestBidPriceLong    |-> nationalBestBidPriceLong.value,
         nationalBestBidSizeLong     |-> nationalBestBidSizeLong.value,
         nationalBestAskMarketCenter |-> nationalBestAskMarketCenter.value,
         nationalBestAskPriceLong    |-> nationalBestAskPriceLong.value,
         nationalBestAskSizeLong     |-> nationalBestAskSizeLong.value ], nationalBestAskSizeLong.rest)

ZeroNationalBboAppendageLongform ==
    [ nbboQuoteCondition          |-> [i \in 1 .. 1 |-> 0],
      nationalBestBidMarketCenter |-> [i \in 1 .. 1 |-> 0],
      nationalBestBidPriceLong    |-> [i \in 1 .. 8 |-> 0],
      nationalBestBidSizeLong     |-> [i \in 1 .. 4 |-> 0],
      nationalBestAskMarketCenter |-> [i \in 1 .. 1 |-> 0],
      nationalBestAskPriceLong    |-> [i \in 1 .. 8 |-> 0],
      nationalBestAskSizeLong     |-> [i \in 1 .. 4 |-> 0] ]

(* National Bbo Appendage Longform at zero, then each field in turn at the values it is checked at *)
CheckedNationalBboAppendageLongform ==
    { ZeroNationalBboAppendageLongform }
        \cup { [ZeroNationalBboAppendageLongform EXCEPT !.nbboQuoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroNationalBboAppendageLongform EXCEPT !.nationalBestBidMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroNationalBboAppendageLongform EXCEPT !.nationalBestBidPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroNationalBboAppendageLongform EXCEPT !.nationalBestBidSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroNationalBboAppendageLongform EXCEPT !.nationalBestAskMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroNationalBboAppendageLongform EXCEPT !.nationalBestAskPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroNationalBboAppendageLongform EXCEPT !.nationalBestAskSizeLong = one] : one \in Sample(4) }

(***************************************************************************)
(* What Nbbo Appendage Indicator decides is present                        *)
(***************************************************************************)

NationalBboAppendageShortformCode == 50  \* "2"
NationalBboAppendageLongformCode == 51  \* "3"
NbboAppendageIndicatorNoneCode == 0  \* 

NbboAppendageIndicatorChoice ==
    [ tag : {NationalBboAppendageShortformCode}, body : NationalBboAppendageShortform ]
        \cup [ tag : {NationalBboAppendageLongformCode}, body : NationalBboAppendageLongform ]
        \cup [ tag : {NbboAppendageIndicatorNoneCode}, body : {[empty |-> 0]} ]

EncodeNbboAppendageIndicatorChoice(message) ==
    CASE message.tag = NationalBboAppendageShortformCode -> EncodeNationalBboAppendageShortform(message.body)
      [] message.tag = NationalBboAppendageLongformCode -> EncodeNationalBboAppendageLongform(message.body)
      [] OTHER -> << >>

DecodeNbboAppendageIndicatorChoice(tag, bytes) ==
    LET read ==
            CASE tag = NationalBboAppendageShortformCode -> DecodeNationalBboAppendageShortform(bytes)
              [] tag = NationalBboAppendageLongformCode -> DecodeNationalBboAppendageLongform(bytes)
              [] OTHER -> Ok([empty |-> 0], bytes)
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroNbboAppendageIndicatorChoice == [tag |-> NationalBboAppendageShortformCode, body |-> ZeroNationalBboAppendageShortform]

(* Each Nbbo Appendage Indicator in turn, at the values the message it names is checked at *)
CheckedNbboAppendageIndicatorChoice ==
    { [tag |-> NationalBboAppendageShortformCode, body |-> one] : one \in CheckedNationalBboAppendageShortform }
        \cup { [tag |-> NationalBboAppendageLongformCode, body |-> one] : one \in CheckedNationalBboAppendageLongform }
        \cup { [tag |-> NbboAppendageIndicatorNoneCode, body |-> [empty |-> 0]] }

(***************************************************************************)
(* Utp Quote Shortform Message                                             *)
(***************************************************************************)

UtpQuoteShortformMessage ==
    [ marketCenterOriginator       : Sample(1),
      subMarketCenterId            : Sample(1),
      sipTimestamp                 : Sample(8),
      timestamp1                   : Sample(8),
      participantToken             : Sample(8),
      symbolShort                  : Sample(5),
      bidPriceShort                : Sample(2),
      bidSizeShort                 : Sample(2),
      askPriceShort                : Sample(2),
      askSizeShort                 : Sample(2),
      quoteCondition               : Sample(1),
      sipGeneratedUpdateFlag       : Sample(1),
      luldBboIndicator             : Sample(1),
      retailInterestIndicator      : Sample(1),
      luldNationalBboIndicator     : Sample(1),
      nbboAppendageIndicatorChoice : NbboAppendageIndicatorChoice ]

EncodeUtpQuoteShortformMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o message.symbolShort
        \o message.bidPriceShort
        \o message.bidSizeShort
        \o message.askPriceShort
        \o message.askSizeShort
        \o message.quoteCondition
        \o message.sipGeneratedUpdateFlag
        \o message.luldBboIndicator
        \o message.retailInterestIndicator
        \o EncodeUIntBE(message.nbboAppendageIndicatorChoice.tag, 1)
        \o message.luldNationalBboIndicator
        \o EncodeNbboAppendageIndicatorChoice(message.nbboAppendageIndicatorChoice)

DecodeUtpQuoteShortformMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET symbolShort == ReadBytes(participantToken.rest, 5) IN IF ~symbolShort.ok THEN Fail ELSE
    LET bidPriceShort == ReadBytes(symbolShort.rest, 2) IN IF ~bidPriceShort.ok THEN Fail ELSE
    LET bidSizeShort == ReadBytes(bidPriceShort.rest, 2) IN IF ~bidSizeShort.ok THEN Fail ELSE
    LET askPriceShort == ReadBytes(bidSizeShort.rest, 2) IN IF ~askPriceShort.ok THEN Fail ELSE
    LET askSizeShort == ReadBytes(askPriceShort.rest, 2) IN IF ~askSizeShort.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(askSizeShort.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET sipGeneratedUpdateFlag == ReadBytes(quoteCondition.rest, 1) IN IF ~sipGeneratedUpdateFlag.ok THEN Fail ELSE
    LET luldBboIndicator == ReadBytes(sipGeneratedUpdateFlag.rest, 1) IN IF ~luldBboIndicator.ok THEN Fail ELSE
    LET retailInterestIndicator == ReadBytes(luldBboIndicator.rest, 1) IN IF ~retailInterestIndicator.ok THEN Fail ELSE
    LET nbboAppendageIndicator == ReadUIntBE(retailInterestIndicator.rest, 1) IN IF ~nbboAppendageIndicator.ok THEN Fail ELSE
    LET luldNationalBboIndicator == ReadBytes(nbboAppendageIndicator.rest, 1) IN IF ~luldNationalBboIndicator.ok THEN Fail ELSE
    LET nbboAppendageIndicatorChoice == DecodeNbboAppendageIndicatorChoice(nbboAppendageIndicator.value, luldNationalBboIndicator.rest) IN IF ~nbboAppendageIndicatorChoice.ok THEN Fail ELSE
    Ok([ marketCenterOriginator       |-> marketCenterOriginator.value,
         subMarketCenterId            |-> subMarketCenterId.value,
         sipTimestamp                 |-> sipTimestamp.value,
         timestamp1                   |-> timestamp1.value,
         participantToken             |-> participantToken.value,
         symbolShort                  |-> symbolShort.value,
         bidPriceShort                |-> bidPriceShort.value,
         bidSizeShort                 |-> bidSizeShort.value,
         askPriceShort                |-> askPriceShort.value,
         askSizeShort                 |-> askSizeShort.value,
         quoteCondition               |-> quoteCondition.value,
         sipGeneratedUpdateFlag       |-> sipGeneratedUpdateFlag.value,
         luldBboIndicator             |-> luldBboIndicator.value,
         retailInterestIndicator      |-> retailInterestIndicator.value,
         luldNationalBboIndicator     |-> luldNationalBboIndicator.value,
         nbboAppendageIndicatorChoice |-> nbboAppendageIndicatorChoice.value ], nbboAppendageIndicatorChoice.rest)

ZeroUtpQuoteShortformMessage ==
    [ marketCenterOriginator       |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId            |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp                 |-> [i \in 1 .. 8 |-> 0],
      timestamp1                   |-> [i \in 1 .. 8 |-> 0],
      participantToken             |-> [i \in 1 .. 8 |-> 0],
      symbolShort                  |-> [i \in 1 .. 5 |-> 0],
      bidPriceShort                |-> [i \in 1 .. 2 |-> 0],
      bidSizeShort                 |-> [i \in 1 .. 2 |-> 0],
      askPriceShort                |-> [i \in 1 .. 2 |-> 0],
      askSizeShort                 |-> [i \in 1 .. 2 |-> 0],
      quoteCondition               |-> [i \in 1 .. 1 |-> 0],
      sipGeneratedUpdateFlag       |-> [i \in 1 .. 1 |-> 0],
      luldBboIndicator             |-> [i \in 1 .. 1 |-> 0],
      retailInterestIndicator      |-> [i \in 1 .. 1 |-> 0],
      luldNationalBboIndicator     |-> [i \in 1 .. 1 |-> 0],
      nbboAppendageIndicatorChoice |-> ZeroNbboAppendageIndicatorChoice ]

(* Utp Quote Shortform Message at zero, then each field in turn at the values it is checked at *)
CheckedUtpQuoteShortformMessage ==
    { ZeroUtpQuoteShortformMessage }
        \cup { [ZeroUtpQuoteShortformMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroUtpQuoteShortformMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroUtpQuoteShortformMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroUtpQuoteShortformMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroUtpQuoteShortformMessage EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroUtpQuoteShortformMessage EXCEPT !.symbolShort = one] : one \in Sample(5) }
        \cup { [ZeroUtpQuoteShortformMessage EXCEPT !.bidPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroUtpQuoteShortformMessage EXCEPT !.bidSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroUtpQuoteShortformMessage EXCEPT !.askPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroUtpQuoteShortformMessage EXCEPT !.askSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroUtpQuoteShortformMessage EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroUtpQuoteShortformMessage EXCEPT !.sipGeneratedUpdateFlag = one] : one \in Sample(1) }
        \cup { [ZeroUtpQuoteShortformMessage EXCEPT !.luldBboIndicator = one] : one \in Sample(1) }
        \cup { [ZeroUtpQuoteShortformMessage EXCEPT !.retailInterestIndicator = one] : one \in Sample(1) }
        \cup { [ZeroUtpQuoteShortformMessage EXCEPT !.luldNationalBboIndicator = one] : one \in Sample(1) }
        \cup { [ZeroUtpQuoteShortformMessage EXCEPT !.nbboAppendageIndicatorChoice = one] : one \in CheckedNbboAppendageIndicatorChoice }

(***************************************************************************)
(* National Bbo Appendage Shortform: 11 bytes                              *)
(***************************************************************************)

NationalBboAppendageShortform2 ==
    [ nbboQuoteCondition          : Sample(1),
      nationalBestBidMarketCenter : Sample(1),
      nationalBestBidPriceShort   : Sample(2),
      nationalBestBidSizeShort    : Sample(2),
      nationalBestAskMarketCenter : Sample(1),
      nationalBestAskPriceShort   : Sample(2),
      nationalBestAskSizeShort    : Sample(2) ]

EncodeNationalBboAppendageShortform2(message) ==
    message.nbboQuoteCondition
        \o message.nationalBestBidMarketCenter
        \o message.nationalBestBidPriceShort
        \o message.nationalBestBidSizeShort
        \o message.nationalBestAskMarketCenter
        \o message.nationalBestAskPriceShort
        \o message.nationalBestAskSizeShort

DecodeNationalBboAppendageShortform2(bytes) ==
    LET nbboQuoteCondition == ReadBytes(bytes, 1) IN IF ~nbboQuoteCondition.ok THEN Fail ELSE
    LET nationalBestBidMarketCenter == ReadBytes(nbboQuoteCondition.rest, 1) IN IF ~nationalBestBidMarketCenter.ok THEN Fail ELSE
    LET nationalBestBidPriceShort == ReadBytes(nationalBestBidMarketCenter.rest, 2) IN IF ~nationalBestBidPriceShort.ok THEN Fail ELSE
    LET nationalBestBidSizeShort == ReadBytes(nationalBestBidPriceShort.rest, 2) IN IF ~nationalBestBidSizeShort.ok THEN Fail ELSE
    LET nationalBestAskMarketCenter == ReadBytes(nationalBestBidSizeShort.rest, 1) IN IF ~nationalBestAskMarketCenter.ok THEN Fail ELSE
    LET nationalBestAskPriceShort == ReadBytes(nationalBestAskMarketCenter.rest, 2) IN IF ~nationalBestAskPriceShort.ok THEN Fail ELSE
    LET nationalBestAskSizeShort == ReadBytes(nationalBestAskPriceShort.rest, 2) IN IF ~nationalBestAskSizeShort.ok THEN Fail ELSE
    Ok([ nbboQuoteCondition          |-> nbboQuoteCondition.value,
         nationalBestBidMarketCenter |-> nationalBestBidMarketCenter.value,
         nationalBestBidPriceShort   |-> nationalBestBidPriceShort.value,
         nationalBestBidSizeShort    |-> nationalBestBidSizeShort.value,
         nationalBestAskMarketCenter |-> nationalBestAskMarketCenter.value,
         nationalBestAskPriceShort   |-> nationalBestAskPriceShort.value,
         nationalBestAskSizeShort    |-> nationalBestAskSizeShort.value ], nationalBestAskSizeShort.rest)

ZeroNationalBboAppendageShortform2 ==
    [ nbboQuoteCondition          |-> [i \in 1 .. 1 |-> 0],
      nationalBestBidMarketCenter |-> [i \in 1 .. 1 |-> 0],
      nationalBestBidPriceShort   |-> [i \in 1 .. 2 |-> 0],
      nationalBestBidSizeShort    |-> [i \in 1 .. 2 |-> 0],
      nationalBestAskMarketCenter |-> [i \in 1 .. 1 |-> 0],
      nationalBestAskPriceShort   |-> [i \in 1 .. 2 |-> 0],
      nationalBestAskSizeShort    |-> [i \in 1 .. 2 |-> 0] ]

(* National Bbo Appendage Shortform at zero, then each field in turn at the values it is checked at *)
CheckedNationalBboAppendageShortform2 ==
    { ZeroNationalBboAppendageShortform2 }
        \cup { [ZeroNationalBboAppendageShortform2 EXCEPT !.nbboQuoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroNationalBboAppendageShortform2 EXCEPT !.nationalBestBidMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroNationalBboAppendageShortform2 EXCEPT !.nationalBestBidPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroNationalBboAppendageShortform2 EXCEPT !.nationalBestBidSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroNationalBboAppendageShortform2 EXCEPT !.nationalBestAskMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroNationalBboAppendageShortform2 EXCEPT !.nationalBestAskPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroNationalBboAppendageShortform2 EXCEPT !.nationalBestAskSizeShort = one] : one \in Sample(2) }

(***************************************************************************)
(* National Bbo Appendage Longform: 27 bytes                               *)
(***************************************************************************)

NationalBboAppendageLongform2 ==
    [ nbboQuoteCondition          : Sample(1),
      nationalBestBidMarketCenter : Sample(1),
      nationalBestBidPriceLong    : Sample(8),
      nationalBestBidSizeLong     : Sample(4),
      nationalBestAskMarketCenter : Sample(1),
      nationalBestAskPriceLong    : Sample(8),
      nationalBestAskSizeLong     : Sample(4) ]

EncodeNationalBboAppendageLongform2(message) ==
    message.nbboQuoteCondition
        \o message.nationalBestBidMarketCenter
        \o message.nationalBestBidPriceLong
        \o message.nationalBestBidSizeLong
        \o message.nationalBestAskMarketCenter
        \o message.nationalBestAskPriceLong
        \o message.nationalBestAskSizeLong

DecodeNationalBboAppendageLongform2(bytes) ==
    LET nbboQuoteCondition == ReadBytes(bytes, 1) IN IF ~nbboQuoteCondition.ok THEN Fail ELSE
    LET nationalBestBidMarketCenter == ReadBytes(nbboQuoteCondition.rest, 1) IN IF ~nationalBestBidMarketCenter.ok THEN Fail ELSE
    LET nationalBestBidPriceLong == ReadBytes(nationalBestBidMarketCenter.rest, 8) IN IF ~nationalBestBidPriceLong.ok THEN Fail ELSE
    LET nationalBestBidSizeLong == ReadBytes(nationalBestBidPriceLong.rest, 4) IN IF ~nationalBestBidSizeLong.ok THEN Fail ELSE
    LET nationalBestAskMarketCenter == ReadBytes(nationalBestBidSizeLong.rest, 1) IN IF ~nationalBestAskMarketCenter.ok THEN Fail ELSE
    LET nationalBestAskPriceLong == ReadBytes(nationalBestAskMarketCenter.rest, 8) IN IF ~nationalBestAskPriceLong.ok THEN Fail ELSE
    LET nationalBestAskSizeLong == ReadBytes(nationalBestAskPriceLong.rest, 4) IN IF ~nationalBestAskSizeLong.ok THEN Fail ELSE
    Ok([ nbboQuoteCondition          |-> nbboQuoteCondition.value,
         nationalBestBidMarketCenter |-> nationalBestBidMarketCenter.value,
         nationalBestBidPriceLong    |-> nationalBestBidPriceLong.value,
         nationalBestBidSizeLong     |-> nationalBestBidSizeLong.value,
         nationalBestAskMarketCenter |-> nationalBestAskMarketCenter.value,
         nationalBestAskPriceLong    |-> nationalBestAskPriceLong.value,
         nationalBestAskSizeLong     |-> nationalBestAskSizeLong.value ], nationalBestAskSizeLong.rest)

ZeroNationalBboAppendageLongform2 ==
    [ nbboQuoteCondition          |-> [i \in 1 .. 1 |-> 0],
      nationalBestBidMarketCenter |-> [i \in 1 .. 1 |-> 0],
      nationalBestBidPriceLong    |-> [i \in 1 .. 8 |-> 0],
      nationalBestBidSizeLong     |-> [i \in 1 .. 4 |-> 0],
      nationalBestAskMarketCenter |-> [i \in 1 .. 1 |-> 0],
      nationalBestAskPriceLong    |-> [i \in 1 .. 8 |-> 0],
      nationalBestAskSizeLong     |-> [i \in 1 .. 4 |-> 0] ]

(* National Bbo Appendage Longform at zero, then each field in turn at the values it is checked at *)
CheckedNationalBboAppendageLongform2 ==
    { ZeroNationalBboAppendageLongform2 }
        \cup { [ZeroNationalBboAppendageLongform2 EXCEPT !.nbboQuoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroNationalBboAppendageLongform2 EXCEPT !.nationalBestBidMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroNationalBboAppendageLongform2 EXCEPT !.nationalBestBidPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroNationalBboAppendageLongform2 EXCEPT !.nationalBestBidSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroNationalBboAppendageLongform2 EXCEPT !.nationalBestAskMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroNationalBboAppendageLongform2 EXCEPT !.nationalBestAskPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroNationalBboAppendageLongform2 EXCEPT !.nationalBestAskSizeLong = one] : one \in Sample(4) }

(***************************************************************************)
(* What Nbbo Appendage Indicator decides is present                        *)
(***************************************************************************)

NationalBboAppendageShortformCode2 == 50  \* "2"
NationalBboAppendageLongformCode2 == 51  \* "3"
NbboAppendageIndicatorNoneCode2 == 0  \* 

NbboAppendageIndicatorChoice2 ==
    [ tag : {NationalBboAppendageShortformCode2}, body : NationalBboAppendageShortform2 ]
        \cup [ tag : {NationalBboAppendageLongformCode2}, body : NationalBboAppendageLongform2 ]
        \cup [ tag : {NbboAppendageIndicatorNoneCode2}, body : {[empty |-> 0]} ]

EncodeNbboAppendageIndicatorChoice2(message) ==
    CASE message.tag = NationalBboAppendageShortformCode2 -> EncodeNationalBboAppendageShortform2(message.body)
      [] message.tag = NationalBboAppendageLongformCode2 -> EncodeNationalBboAppendageLongform2(message.body)
      [] OTHER -> << >>

DecodeNbboAppendageIndicatorChoice2(tag, bytes) ==
    LET read ==
            CASE tag = NationalBboAppendageShortformCode2 -> DecodeNationalBboAppendageShortform2(bytes)
              [] tag = NationalBboAppendageLongformCode2 -> DecodeNationalBboAppendageLongform2(bytes)
              [] OTHER -> Ok([empty |-> 0], bytes)
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroNbboAppendageIndicatorChoice2 == [tag |-> NationalBboAppendageShortformCode2, body |-> ZeroNationalBboAppendageShortform2]

(* Each Nbbo Appendage Indicator in turn, at the values the message it names is checked at *)
CheckedNbboAppendageIndicatorChoice2 ==
    { [tag |-> NationalBboAppendageShortformCode2, body |-> one] : one \in CheckedNationalBboAppendageShortform2 }
        \cup { [tag |-> NationalBboAppendageLongformCode2, body |-> one] : one \in CheckedNationalBboAppendageLongform2 }
        \cup { [tag |-> NbboAppendageIndicatorNoneCode2, body |-> [empty |-> 0]] }

(***************************************************************************)
(* Utp Quote Longform Message                                              *)
(***************************************************************************)

UtpQuoteLongformMessage ==
    [ marketCenterOriginator         : Sample(1),
      subMarketCenterId              : Sample(1),
      sipTimestamp                   : Sample(8),
      timestamp1                     : Sample(8),
      participantToken               : Sample(8),
      timestamp2                     : Sample(8),
      symbolLong                     : Sample(11),
      bidPriceLong                   : Sample(8),
      bidSizeLong                    : Sample(4),
      askPriceLong                   : Sample(8),
      askSizeLong                    : Sample(4),
      quoteCondition                 : Sample(1),
      sipGeneratedUpdateFlag         : Sample(1),
      luldBboIndicator               : Sample(1),
      retailInterestIndicator        : Sample(1),
      luldNationalBboIndicator       : Sample(1),
      finraAdfMpidAppendageIndicator : Sample(1),
      nbboAppendageIndicatorChoice   : NbboAppendageIndicatorChoice2 ]

EncodeUtpQuoteLongformMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o message.timestamp2
        \o message.symbolLong
        \o message.bidPriceLong
        \o message.bidSizeLong
        \o message.askPriceLong
        \o message.askSizeLong
        \o message.quoteCondition
        \o message.sipGeneratedUpdateFlag
        \o message.luldBboIndicator
        \o message.retailInterestIndicator
        \o EncodeUIntBE(message.nbboAppendageIndicatorChoice.tag, 1)
        \o message.luldNationalBboIndicator
        \o message.finraAdfMpidAppendageIndicator
        \o EncodeNbboAppendageIndicatorChoice2(message.nbboAppendageIndicatorChoice)

DecodeUtpQuoteLongformMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET timestamp2 == ReadBytes(participantToken.rest, 8) IN IF ~timestamp2.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(timestamp2.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET bidPriceLong == ReadBytes(symbolLong.rest, 8) IN IF ~bidPriceLong.ok THEN Fail ELSE
    LET bidSizeLong == ReadBytes(bidPriceLong.rest, 4) IN IF ~bidSizeLong.ok THEN Fail ELSE
    LET askPriceLong == ReadBytes(bidSizeLong.rest, 8) IN IF ~askPriceLong.ok THEN Fail ELSE
    LET askSizeLong == ReadBytes(askPriceLong.rest, 4) IN IF ~askSizeLong.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(askSizeLong.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET sipGeneratedUpdateFlag == ReadBytes(quoteCondition.rest, 1) IN IF ~sipGeneratedUpdateFlag.ok THEN Fail ELSE
    LET luldBboIndicator == ReadBytes(sipGeneratedUpdateFlag.rest, 1) IN IF ~luldBboIndicator.ok THEN Fail ELSE
    LET retailInterestIndicator == ReadBytes(luldBboIndicator.rest, 1) IN IF ~retailInterestIndicator.ok THEN Fail ELSE
    LET nbboAppendageIndicator == ReadUIntBE(retailInterestIndicator.rest, 1) IN IF ~nbboAppendageIndicator.ok THEN Fail ELSE
    LET luldNationalBboIndicator == ReadBytes(nbboAppendageIndicator.rest, 1) IN IF ~luldNationalBboIndicator.ok THEN Fail ELSE
    LET finraAdfMpidAppendageIndicator == ReadBytes(luldNationalBboIndicator.rest, 1) IN IF ~finraAdfMpidAppendageIndicator.ok THEN Fail ELSE
    LET nbboAppendageIndicatorChoice == DecodeNbboAppendageIndicatorChoice2(nbboAppendageIndicator.value, finraAdfMpidAppendageIndicator.rest) IN IF ~nbboAppendageIndicatorChoice.ok THEN Fail ELSE
    Ok([ marketCenterOriginator         |-> marketCenterOriginator.value,
         subMarketCenterId              |-> subMarketCenterId.value,
         sipTimestamp                   |-> sipTimestamp.value,
         timestamp1                     |-> timestamp1.value,
         participantToken               |-> participantToken.value,
         timestamp2                     |-> timestamp2.value,
         symbolLong                     |-> symbolLong.value,
         bidPriceLong                   |-> bidPriceLong.value,
         bidSizeLong                    |-> bidSizeLong.value,
         askPriceLong                   |-> askPriceLong.value,
         askSizeLong                    |-> askSizeLong.value,
         quoteCondition                 |-> quoteCondition.value,
         sipGeneratedUpdateFlag         |-> sipGeneratedUpdateFlag.value,
         luldBboIndicator               |-> luldBboIndicator.value,
         retailInterestIndicator        |-> retailInterestIndicator.value,
         luldNationalBboIndicator       |-> luldNationalBboIndicator.value,
         finraAdfMpidAppendageIndicator |-> finraAdfMpidAppendageIndicator.value,
         nbboAppendageIndicatorChoice   |-> nbboAppendageIndicatorChoice.value ], nbboAppendageIndicatorChoice.rest)

ZeroUtpQuoteLongformMessage ==
    [ marketCenterOriginator         |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId              |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp                   |-> [i \in 1 .. 8 |-> 0],
      timestamp1                     |-> [i \in 1 .. 8 |-> 0],
      participantToken               |-> [i \in 1 .. 8 |-> 0],
      timestamp2                     |-> [i \in 1 .. 8 |-> 0],
      symbolLong                     |-> [i \in 1 .. 11 |-> 0],
      bidPriceLong                   |-> [i \in 1 .. 8 |-> 0],
      bidSizeLong                    |-> [i \in 1 .. 4 |-> 0],
      askPriceLong                   |-> [i \in 1 .. 8 |-> 0],
      askSizeLong                    |-> [i \in 1 .. 4 |-> 0],
      quoteCondition                 |-> [i \in 1 .. 1 |-> 0],
      sipGeneratedUpdateFlag         |-> [i \in 1 .. 1 |-> 0],
      luldBboIndicator               |-> [i \in 1 .. 1 |-> 0],
      retailInterestIndicator        |-> [i \in 1 .. 1 |-> 0],
      luldNationalBboIndicator       |-> [i \in 1 .. 1 |-> 0],
      finraAdfMpidAppendageIndicator |-> [i \in 1 .. 1 |-> 0],
      nbboAppendageIndicatorChoice   |-> ZeroNbboAppendageIndicatorChoice2 ]

(* Utp Quote Longform Message at zero, then each field in turn at the values it is checked at *)
CheckedUtpQuoteLongformMessage ==
    { ZeroUtpQuoteLongformMessage }
        \cup { [ZeroUtpQuoteLongformMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroUtpQuoteLongformMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroUtpQuoteLongformMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroUtpQuoteLongformMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroUtpQuoteLongformMessage EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroUtpQuoteLongformMessage EXCEPT !.timestamp2 = one] : one \in Sample(8) }
        \cup { [ZeroUtpQuoteLongformMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroUtpQuoteLongformMessage EXCEPT !.bidPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroUtpQuoteLongformMessage EXCEPT !.bidSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroUtpQuoteLongformMessage EXCEPT !.askPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroUtpQuoteLongformMessage EXCEPT !.askSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroUtpQuoteLongformMessage EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroUtpQuoteLongformMessage EXCEPT !.sipGeneratedUpdateFlag = one] : one \in Sample(1) }
        \cup { [ZeroUtpQuoteLongformMessage EXCEPT !.luldBboIndicator = one] : one \in Sample(1) }
        \cup { [ZeroUtpQuoteLongformMessage EXCEPT !.retailInterestIndicator = one] : one \in Sample(1) }
        \cup { [ZeroUtpQuoteLongformMessage EXCEPT !.luldNationalBboIndicator = one] : one \in Sample(1) }
        \cup { [ZeroUtpQuoteLongformMessage EXCEPT !.finraAdfMpidAppendageIndicator = one] : one \in Sample(1) }
        \cup { [ZeroUtpQuoteLongformMessage EXCEPT !.nbboAppendageIndicatorChoice = one] : one \in CheckedNbboAppendageIndicatorChoice2 }

(***************************************************************************)
(* Finra Adf Market Participant Quotation Message: 74 bytes                *)
(***************************************************************************)

FinraAdfMarketParticipantQuotationMessage ==
    [ marketCenterOriginator : Sample(1),
      subMarketCenterId      : Sample(1),
      sipTimestamp           : Sample(8),
      timestamp1             : Sample(8),
      participantToken       : Sample(8),
      timestamp2             : Sample(8),
      symbolLong             : Sample(11),
      bidPriceLong           : Sample(8),
      bidSizeLong            : Sample(4),
      askPriceLong           : Sample(8),
      askSizeLong            : Sample(4),
      quoteCondition         : Sample(1),
      finraMarketParticipant : Sample(4) ]

EncodeFinraAdfMarketParticipantQuotationMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o message.timestamp2
        \o message.symbolLong
        \o message.bidPriceLong
        \o message.bidSizeLong
        \o message.askPriceLong
        \o message.askSizeLong
        \o message.quoteCondition
        \o message.finraMarketParticipant

DecodeFinraAdfMarketParticipantQuotationMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET timestamp2 == ReadBytes(participantToken.rest, 8) IN IF ~timestamp2.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(timestamp2.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET bidPriceLong == ReadBytes(symbolLong.rest, 8) IN IF ~bidPriceLong.ok THEN Fail ELSE
    LET bidSizeLong == ReadBytes(bidPriceLong.rest, 4) IN IF ~bidSizeLong.ok THEN Fail ELSE
    LET askPriceLong == ReadBytes(bidSizeLong.rest, 8) IN IF ~askPriceLong.ok THEN Fail ELSE
    LET askSizeLong == ReadBytes(askPriceLong.rest, 4) IN IF ~askSizeLong.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(askSizeLong.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET finraMarketParticipant == ReadBytes(quoteCondition.rest, 4) IN IF ~finraMarketParticipant.ok THEN Fail ELSE
    Ok([ marketCenterOriginator |-> marketCenterOriginator.value,
         subMarketCenterId      |-> subMarketCenterId.value,
         sipTimestamp           |-> sipTimestamp.value,
         timestamp1             |-> timestamp1.value,
         participantToken       |-> participantToken.value,
         timestamp2             |-> timestamp2.value,
         symbolLong             |-> symbolLong.value,
         bidPriceLong           |-> bidPriceLong.value,
         bidSizeLong            |-> bidSizeLong.value,
         askPriceLong           |-> askPriceLong.value,
         askSizeLong            |-> askSizeLong.value,
         quoteCondition         |-> quoteCondition.value,
         finraMarketParticipant |-> finraMarketParticipant.value ], finraMarketParticipant.rest)

ZeroFinraAdfMarketParticipantQuotationMessage ==
    [ marketCenterOriginator |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId      |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp           |-> [i \in 1 .. 8 |-> 0],
      timestamp1             |-> [i \in 1 .. 8 |-> 0],
      participantToken       |-> [i \in 1 .. 8 |-> 0],
      timestamp2             |-> [i \in 1 .. 8 |-> 0],
      symbolLong             |-> [i \in 1 .. 11 |-> 0],
      bidPriceLong           |-> [i \in 1 .. 8 |-> 0],
      bidSizeLong            |-> [i \in 1 .. 4 |-> 0],
      askPriceLong           |-> [i \in 1 .. 8 |-> 0],
      askSizeLong            |-> [i \in 1 .. 4 |-> 0],
      quoteCondition         |-> [i \in 1 .. 1 |-> 0],
      finraMarketParticipant |-> [i \in 1 .. 4 |-> 0] ]

(* Finra Adf Market Participant Quotation Message at zero, then each field in turn at the values it is checked at *)
CheckedFinraAdfMarketParticipantQuotationMessage ==
    { ZeroFinraAdfMarketParticipantQuotationMessage }
        \cup { [ZeroFinraAdfMarketParticipantQuotationMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroFinraAdfMarketParticipantQuotationMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroFinraAdfMarketParticipantQuotationMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroFinraAdfMarketParticipantQuotationMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroFinraAdfMarketParticipantQuotationMessage EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroFinraAdfMarketParticipantQuotationMessage EXCEPT !.timestamp2 = one] : one \in Sample(8) }
        \cup { [ZeroFinraAdfMarketParticipantQuotationMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroFinraAdfMarketParticipantQuotationMessage EXCEPT !.bidPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroFinraAdfMarketParticipantQuotationMessage EXCEPT !.bidSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroFinraAdfMarketParticipantQuotationMessage EXCEPT !.askPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroFinraAdfMarketParticipantQuotationMessage EXCEPT !.askSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroFinraAdfMarketParticipantQuotationMessage EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroFinraAdfMarketParticipantQuotationMessage EXCEPT !.finraMarketParticipant = one] : one \in Sample(4) }

(***************************************************************************)
(* National Bbo Appendage Shortform: 11 bytes                              *)
(***************************************************************************)

NationalBboAppendageShortform3 ==
    [ nbboQuoteCondition          : Sample(1),
      nationalBestBidMarketCenter : Sample(1),
      nationalBestBidPriceShort   : Sample(2),
      nationalBestBidSizeShort    : Sample(2),
      nationalBestAskMarketCenter : Sample(1),
      nationalBestAskPriceShort   : Sample(2),
      nationalBestAskSizeShort    : Sample(2) ]

EncodeNationalBboAppendageShortform3(message) ==
    message.nbboQuoteCondition
        \o message.nationalBestBidMarketCenter
        \o message.nationalBestBidPriceShort
        \o message.nationalBestBidSizeShort
        \o message.nationalBestAskMarketCenter
        \o message.nationalBestAskPriceShort
        \o message.nationalBestAskSizeShort

DecodeNationalBboAppendageShortform3(bytes) ==
    LET nbboQuoteCondition == ReadBytes(bytes, 1) IN IF ~nbboQuoteCondition.ok THEN Fail ELSE
    LET nationalBestBidMarketCenter == ReadBytes(nbboQuoteCondition.rest, 1) IN IF ~nationalBestBidMarketCenter.ok THEN Fail ELSE
    LET nationalBestBidPriceShort == ReadBytes(nationalBestBidMarketCenter.rest, 2) IN IF ~nationalBestBidPriceShort.ok THEN Fail ELSE
    LET nationalBestBidSizeShort == ReadBytes(nationalBestBidPriceShort.rest, 2) IN IF ~nationalBestBidSizeShort.ok THEN Fail ELSE
    LET nationalBestAskMarketCenter == ReadBytes(nationalBestBidSizeShort.rest, 1) IN IF ~nationalBestAskMarketCenter.ok THEN Fail ELSE
    LET nationalBestAskPriceShort == ReadBytes(nationalBestAskMarketCenter.rest, 2) IN IF ~nationalBestAskPriceShort.ok THEN Fail ELSE
    LET nationalBestAskSizeShort == ReadBytes(nationalBestAskPriceShort.rest, 2) IN IF ~nationalBestAskSizeShort.ok THEN Fail ELSE
    Ok([ nbboQuoteCondition          |-> nbboQuoteCondition.value,
         nationalBestBidMarketCenter |-> nationalBestBidMarketCenter.value,
         nationalBestBidPriceShort   |-> nationalBestBidPriceShort.value,
         nationalBestBidSizeShort    |-> nationalBestBidSizeShort.value,
         nationalBestAskMarketCenter |-> nationalBestAskMarketCenter.value,
         nationalBestAskPriceShort   |-> nationalBestAskPriceShort.value,
         nationalBestAskSizeShort    |-> nationalBestAskSizeShort.value ], nationalBestAskSizeShort.rest)

ZeroNationalBboAppendageShortform3 ==
    [ nbboQuoteCondition          |-> [i \in 1 .. 1 |-> 0],
      nationalBestBidMarketCenter |-> [i \in 1 .. 1 |-> 0],
      nationalBestBidPriceShort   |-> [i \in 1 .. 2 |-> 0],
      nationalBestBidSizeShort    |-> [i \in 1 .. 2 |-> 0],
      nationalBestAskMarketCenter |-> [i \in 1 .. 1 |-> 0],
      nationalBestAskPriceShort   |-> [i \in 1 .. 2 |-> 0],
      nationalBestAskSizeShort    |-> [i \in 1 .. 2 |-> 0] ]

(* National Bbo Appendage Shortform at zero, then each field in turn at the values it is checked at *)
CheckedNationalBboAppendageShortform3 ==
    { ZeroNationalBboAppendageShortform3 }
        \cup { [ZeroNationalBboAppendageShortform3 EXCEPT !.nbboQuoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroNationalBboAppendageShortform3 EXCEPT !.nationalBestBidMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroNationalBboAppendageShortform3 EXCEPT !.nationalBestBidPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroNationalBboAppendageShortform3 EXCEPT !.nationalBestBidSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroNationalBboAppendageShortform3 EXCEPT !.nationalBestAskMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroNationalBboAppendageShortform3 EXCEPT !.nationalBestAskPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroNationalBboAppendageShortform3 EXCEPT !.nationalBestAskSizeShort = one] : one \in Sample(2) }

(***************************************************************************)
(* National Bbo Appendage Longform: 27 bytes                               *)
(***************************************************************************)

NationalBboAppendageLongform3 ==
    [ nbboQuoteCondition          : Sample(1),
      nationalBestBidMarketCenter : Sample(1),
      nationalBestBidPriceLong    : Sample(8),
      nationalBestBidSizeLong     : Sample(4),
      nationalBestAskMarketCenter : Sample(1),
      nationalBestAskPriceLong    : Sample(8),
      nationalBestAskSizeLong     : Sample(4) ]

EncodeNationalBboAppendageLongform3(message) ==
    message.nbboQuoteCondition
        \o message.nationalBestBidMarketCenter
        \o message.nationalBestBidPriceLong
        \o message.nationalBestBidSizeLong
        \o message.nationalBestAskMarketCenter
        \o message.nationalBestAskPriceLong
        \o message.nationalBestAskSizeLong

DecodeNationalBboAppendageLongform3(bytes) ==
    LET nbboQuoteCondition == ReadBytes(bytes, 1) IN IF ~nbboQuoteCondition.ok THEN Fail ELSE
    LET nationalBestBidMarketCenter == ReadBytes(nbboQuoteCondition.rest, 1) IN IF ~nationalBestBidMarketCenter.ok THEN Fail ELSE
    LET nationalBestBidPriceLong == ReadBytes(nationalBestBidMarketCenter.rest, 8) IN IF ~nationalBestBidPriceLong.ok THEN Fail ELSE
    LET nationalBestBidSizeLong == ReadBytes(nationalBestBidPriceLong.rest, 4) IN IF ~nationalBestBidSizeLong.ok THEN Fail ELSE
    LET nationalBestAskMarketCenter == ReadBytes(nationalBestBidSizeLong.rest, 1) IN IF ~nationalBestAskMarketCenter.ok THEN Fail ELSE
    LET nationalBestAskPriceLong == ReadBytes(nationalBestAskMarketCenter.rest, 8) IN IF ~nationalBestAskPriceLong.ok THEN Fail ELSE
    LET nationalBestAskSizeLong == ReadBytes(nationalBestAskPriceLong.rest, 4) IN IF ~nationalBestAskSizeLong.ok THEN Fail ELSE
    Ok([ nbboQuoteCondition          |-> nbboQuoteCondition.value,
         nationalBestBidMarketCenter |-> nationalBestBidMarketCenter.value,
         nationalBestBidPriceLong    |-> nationalBestBidPriceLong.value,
         nationalBestBidSizeLong     |-> nationalBestBidSizeLong.value,
         nationalBestAskMarketCenter |-> nationalBestAskMarketCenter.value,
         nationalBestAskPriceLong    |-> nationalBestAskPriceLong.value,
         nationalBestAskSizeLong     |-> nationalBestAskSizeLong.value ], nationalBestAskSizeLong.rest)

ZeroNationalBboAppendageLongform3 ==
    [ nbboQuoteCondition          |-> [i \in 1 .. 1 |-> 0],
      nationalBestBidMarketCenter |-> [i \in 1 .. 1 |-> 0],
      nationalBestBidPriceLong    |-> [i \in 1 .. 8 |-> 0],
      nationalBestBidSizeLong     |-> [i \in 1 .. 4 |-> 0],
      nationalBestAskMarketCenter |-> [i \in 1 .. 1 |-> 0],
      nationalBestAskPriceLong    |-> [i \in 1 .. 8 |-> 0],
      nationalBestAskSizeLong     |-> [i \in 1 .. 4 |-> 0] ]

(* National Bbo Appendage Longform at zero, then each field in turn at the values it is checked at *)
CheckedNationalBboAppendageLongform3 ==
    { ZeroNationalBboAppendageLongform3 }
        \cup { [ZeroNationalBboAppendageLongform3 EXCEPT !.nbboQuoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroNationalBboAppendageLongform3 EXCEPT !.nationalBestBidMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroNationalBboAppendageLongform3 EXCEPT !.nationalBestBidPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroNationalBboAppendageLongform3 EXCEPT !.nationalBestBidSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroNationalBboAppendageLongform3 EXCEPT !.nationalBestAskMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroNationalBboAppendageLongform3 EXCEPT !.nationalBestAskPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroNationalBboAppendageLongform3 EXCEPT !.nationalBestAskSizeLong = one] : one \in Sample(4) }

(***************************************************************************)
(* What Nbbo Appendage Indicator decides is present                        *)
(***************************************************************************)

NationalBboAppendageShortformCode3 == 50  \* "2"
NationalBboAppendageLongformCode3 == 51  \* "3"
NbboAppendageIndicatorNoneCode3 == 0  \* 

NbboAppendageIndicatorChoice3 ==
    [ tag : {NationalBboAppendageShortformCode3}, body : NationalBboAppendageShortform3 ]
        \cup [ tag : {NationalBboAppendageLongformCode3}, body : NationalBboAppendageLongform3 ]
        \cup [ tag : {NbboAppendageIndicatorNoneCode3}, body : {[empty |-> 0]} ]

EncodeNbboAppendageIndicatorChoice3(message) ==
    CASE message.tag = NationalBboAppendageShortformCode3 -> EncodeNationalBboAppendageShortform3(message.body)
      [] message.tag = NationalBboAppendageLongformCode3 -> EncodeNationalBboAppendageLongform3(message.body)
      [] OTHER -> << >>

DecodeNbboAppendageIndicatorChoice3(tag, bytes) ==
    LET read ==
            CASE tag = NationalBboAppendageShortformCode3 -> DecodeNationalBboAppendageShortform3(bytes)
              [] tag = NationalBboAppendageLongformCode3 -> DecodeNationalBboAppendageLongform3(bytes)
              [] OTHER -> Ok([empty |-> 0], bytes)
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroNbboAppendageIndicatorChoice3 == [tag |-> NationalBboAppendageShortformCode3, body |-> ZeroNationalBboAppendageShortform3]

(* Each Nbbo Appendage Indicator in turn, at the values the message it names is checked at *)
CheckedNbboAppendageIndicatorChoice3 ==
    { [tag |-> NationalBboAppendageShortformCode3, body |-> one] : one \in CheckedNationalBboAppendageShortform3 }
        \cup { [tag |-> NationalBboAppendageLongformCode3, body |-> one] : one \in CheckedNationalBboAppendageLongform3 }
        \cup { [tag |-> NbboAppendageIndicatorNoneCode3, body |-> [empty |-> 0]] }

(***************************************************************************)
(* Bolo Appendage Short Form: 10 bytes                                     *)
(***************************************************************************)

BoloAppendageShortForm ==
    [ boloBestBidMarketCenter : Sample(1),
      boloBidPriceShort       : Sample(2),
      boloBidSize             : Sample(2),
      boloBestAskMarketCenter : Sample(1),
      boloAskPriceShort       : Sample(2),
      boloAskSize             : Sample(2) ]

EncodeBoloAppendageShortForm(message) ==
    message.boloBestBidMarketCenter
        \o message.boloBidPriceShort
        \o message.boloBidSize
        \o message.boloBestAskMarketCenter
        \o message.boloAskPriceShort
        \o message.boloAskSize

DecodeBoloAppendageShortForm(bytes) ==
    LET boloBestBidMarketCenter == ReadBytes(bytes, 1) IN IF ~boloBestBidMarketCenter.ok THEN Fail ELSE
    LET boloBidPriceShort == ReadBytes(boloBestBidMarketCenter.rest, 2) IN IF ~boloBidPriceShort.ok THEN Fail ELSE
    LET boloBidSize == ReadBytes(boloBidPriceShort.rest, 2) IN IF ~boloBidSize.ok THEN Fail ELSE
    LET boloBestAskMarketCenter == ReadBytes(boloBidSize.rest, 1) IN IF ~boloBestAskMarketCenter.ok THEN Fail ELSE
    LET boloAskPriceShort == ReadBytes(boloBestAskMarketCenter.rest, 2) IN IF ~boloAskPriceShort.ok THEN Fail ELSE
    LET boloAskSize == ReadBytes(boloAskPriceShort.rest, 2) IN IF ~boloAskSize.ok THEN Fail ELSE
    Ok([ boloBestBidMarketCenter |-> boloBestBidMarketCenter.value,
         boloBidPriceShort       |-> boloBidPriceShort.value,
         boloBidSize             |-> boloBidSize.value,
         boloBestAskMarketCenter |-> boloBestAskMarketCenter.value,
         boloAskPriceShort       |-> boloAskPriceShort.value,
         boloAskSize             |-> boloAskSize.value ], boloAskSize.rest)

ZeroBoloAppendageShortForm ==
    [ boloBestBidMarketCenter |-> [i \in 1 .. 1 |-> 0],
      boloBidPriceShort       |-> [i \in 1 .. 2 |-> 0],
      boloBidSize             |-> [i \in 1 .. 2 |-> 0],
      boloBestAskMarketCenter |-> [i \in 1 .. 1 |-> 0],
      boloAskPriceShort       |-> [i \in 1 .. 2 |-> 0],
      boloAskSize             |-> [i \in 1 .. 2 |-> 0] ]

(* Bolo Appendage Short Form at zero, then each field in turn at the values it is checked at *)
CheckedBoloAppendageShortForm ==
    { ZeroBoloAppendageShortForm }
        \cup { [ZeroBoloAppendageShortForm EXCEPT !.boloBestBidMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroBoloAppendageShortForm EXCEPT !.boloBidPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroBoloAppendageShortForm EXCEPT !.boloBidSize = one] : one \in Sample(2) }
        \cup { [ZeroBoloAppendageShortForm EXCEPT !.boloBestAskMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroBoloAppendageShortForm EXCEPT !.boloAskPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroBoloAppendageShortForm EXCEPT !.boloAskSize = one] : one \in Sample(2) }

(***************************************************************************)
(* Bolo Appendage Long Form: 22 bytes                                      *)
(***************************************************************************)

BoloAppendageLongForm ==
    [ boloBestBidMarketCenter : Sample(1),
      boloBidPriceLong        : Sample(8),
      boloBidSize             : Sample(2),
      boloBestAskMarketCenter : Sample(1),
      boloAskPriceLong        : Sample(8),
      boloAskSize             : Sample(2) ]

EncodeBoloAppendageLongForm(message) ==
    message.boloBestBidMarketCenter
        \o message.boloBidPriceLong
        \o message.boloBidSize
        \o message.boloBestAskMarketCenter
        \o message.boloAskPriceLong
        \o message.boloAskSize

DecodeBoloAppendageLongForm(bytes) ==
    LET boloBestBidMarketCenter == ReadBytes(bytes, 1) IN IF ~boloBestBidMarketCenter.ok THEN Fail ELSE
    LET boloBidPriceLong == ReadBytes(boloBestBidMarketCenter.rest, 8) IN IF ~boloBidPriceLong.ok THEN Fail ELSE
    LET boloBidSize == ReadBytes(boloBidPriceLong.rest, 2) IN IF ~boloBidSize.ok THEN Fail ELSE
    LET boloBestAskMarketCenter == ReadBytes(boloBidSize.rest, 1) IN IF ~boloBestAskMarketCenter.ok THEN Fail ELSE
    LET boloAskPriceLong == ReadBytes(boloBestAskMarketCenter.rest, 8) IN IF ~boloAskPriceLong.ok THEN Fail ELSE
    LET boloAskSize == ReadBytes(boloAskPriceLong.rest, 2) IN IF ~boloAskSize.ok THEN Fail ELSE
    Ok([ boloBestBidMarketCenter |-> boloBestBidMarketCenter.value,
         boloBidPriceLong        |-> boloBidPriceLong.value,
         boloBidSize             |-> boloBidSize.value,
         boloBestAskMarketCenter |-> boloBestAskMarketCenter.value,
         boloAskPriceLong        |-> boloAskPriceLong.value,
         boloAskSize             |-> boloAskSize.value ], boloAskSize.rest)

ZeroBoloAppendageLongForm ==
    [ boloBestBidMarketCenter |-> [i \in 1 .. 1 |-> 0],
      boloBidPriceLong        |-> [i \in 1 .. 8 |-> 0],
      boloBidSize             |-> [i \in 1 .. 2 |-> 0],
      boloBestAskMarketCenter |-> [i \in 1 .. 1 |-> 0],
      boloAskPriceLong        |-> [i \in 1 .. 8 |-> 0],
      boloAskSize             |-> [i \in 1 .. 2 |-> 0] ]

(* Bolo Appendage Long Form at zero, then each field in turn at the values it is checked at *)
CheckedBoloAppendageLongForm ==
    { ZeroBoloAppendageLongForm }
        \cup { [ZeroBoloAppendageLongForm EXCEPT !.boloBestBidMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroBoloAppendageLongForm EXCEPT !.boloBidPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroBoloAppendageLongForm EXCEPT !.boloBidSize = one] : one \in Sample(2) }
        \cup { [ZeroBoloAppendageLongForm EXCEPT !.boloBestAskMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroBoloAppendageLongForm EXCEPT !.boloAskPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroBoloAppendageLongForm EXCEPT !.boloAskSize = one] : one \in Sample(2) }

(***************************************************************************)
(* Bolo Appendage Mpid Form: 30 bytes                                      *)
(***************************************************************************)

BoloAppendageMpidForm ==
    [ boloBestBidMarketCenter                : Sample(1),
      boloBidPriceLong                       : Sample(8),
      boloBidSize                            : Sample(2),
      boloBestAskMarketCenter                : Sample(1),
      boloAskPriceLong                       : Sample(8),
      boloAskSize                            : Sample(2),
      boloBestBidMarketParticipantIdentifier : Sample(4),
      boloBestAskMarketParticipantIdentifier : Sample(4) ]

EncodeBoloAppendageMpidForm(message) ==
    message.boloBestBidMarketCenter
        \o message.boloBidPriceLong
        \o message.boloBidSize
        \o message.boloBestAskMarketCenter
        \o message.boloAskPriceLong
        \o message.boloAskSize
        \o message.boloBestBidMarketParticipantIdentifier
        \o message.boloBestAskMarketParticipantIdentifier

DecodeBoloAppendageMpidForm(bytes) ==
    LET boloBestBidMarketCenter == ReadBytes(bytes, 1) IN IF ~boloBestBidMarketCenter.ok THEN Fail ELSE
    LET boloBidPriceLong == ReadBytes(boloBestBidMarketCenter.rest, 8) IN IF ~boloBidPriceLong.ok THEN Fail ELSE
    LET boloBidSize == ReadBytes(boloBidPriceLong.rest, 2) IN IF ~boloBidSize.ok THEN Fail ELSE
    LET boloBestAskMarketCenter == ReadBytes(boloBidSize.rest, 1) IN IF ~boloBestAskMarketCenter.ok THEN Fail ELSE
    LET boloAskPriceLong == ReadBytes(boloBestAskMarketCenter.rest, 8) IN IF ~boloAskPriceLong.ok THEN Fail ELSE
    LET boloAskSize == ReadBytes(boloAskPriceLong.rest, 2) IN IF ~boloAskSize.ok THEN Fail ELSE
    LET boloBestBidMarketParticipantIdentifier == ReadBytes(boloAskSize.rest, 4) IN IF ~boloBestBidMarketParticipantIdentifier.ok THEN Fail ELSE
    LET boloBestAskMarketParticipantIdentifier == ReadBytes(boloBestBidMarketParticipantIdentifier.rest, 4) IN IF ~boloBestAskMarketParticipantIdentifier.ok THEN Fail ELSE
    Ok([ boloBestBidMarketCenter                |-> boloBestBidMarketCenter.value,
         boloBidPriceLong                       |-> boloBidPriceLong.value,
         boloBidSize                            |-> boloBidSize.value,
         boloBestAskMarketCenter                |-> boloBestAskMarketCenter.value,
         boloAskPriceLong                       |-> boloAskPriceLong.value,
         boloAskSize                            |-> boloAskSize.value,
         boloBestBidMarketParticipantIdentifier |-> boloBestBidMarketParticipantIdentifier.value,
         boloBestAskMarketParticipantIdentifier |-> boloBestAskMarketParticipantIdentifier.value ], boloBestAskMarketParticipantIdentifier.rest)

ZeroBoloAppendageMpidForm ==
    [ boloBestBidMarketCenter                |-> [i \in 1 .. 1 |-> 0],
      boloBidPriceLong                       |-> [i \in 1 .. 8 |-> 0],
      boloBidSize                            |-> [i \in 1 .. 2 |-> 0],
      boloBestAskMarketCenter                |-> [i \in 1 .. 1 |-> 0],
      boloAskPriceLong                       |-> [i \in 1 .. 8 |-> 0],
      boloAskSize                            |-> [i \in 1 .. 2 |-> 0],
      boloBestBidMarketParticipantIdentifier |-> [i \in 1 .. 4 |-> 0],
      boloBestAskMarketParticipantIdentifier |-> [i \in 1 .. 4 |-> 0] ]

(* Bolo Appendage Mpid Form at zero, then each field in turn at the values it is checked at *)
CheckedBoloAppendageMpidForm ==
    { ZeroBoloAppendageMpidForm }
        \cup { [ZeroBoloAppendageMpidForm EXCEPT !.boloBestBidMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroBoloAppendageMpidForm EXCEPT !.boloBidPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroBoloAppendageMpidForm EXCEPT !.boloBidSize = one] : one \in Sample(2) }
        \cup { [ZeroBoloAppendageMpidForm EXCEPT !.boloBestAskMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroBoloAppendageMpidForm EXCEPT !.boloAskPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroBoloAppendageMpidForm EXCEPT !.boloAskSize = one] : one \in Sample(2) }
        \cup { [ZeroBoloAppendageMpidForm EXCEPT !.boloBestBidMarketParticipantIdentifier = one] : one \in Sample(4) }
        \cup { [ZeroBoloAppendageMpidForm EXCEPT !.boloBestAskMarketParticipantIdentifier = one] : one \in Sample(4) }

(***************************************************************************)
(* What Bolo Appendage Indicator decides is present                        *)
(***************************************************************************)

BoloAppendageShortFormCode == 50  \* "2"
BoloAppendageLongFormCode == 51  \* "3"
BoloAppendageMpidFormCode == 53  \* "5"
BoloAppendageIndicatorNoneCode == 0  \* 

BoloAppendageIndicatorChoice ==
    [ tag : {BoloAppendageShortFormCode}, body : BoloAppendageShortForm ]
        \cup [ tag : {BoloAppendageLongFormCode}, body : BoloAppendageLongForm ]
        \cup [ tag : {BoloAppendageMpidFormCode}, body : BoloAppendageMpidForm ]
        \cup [ tag : {BoloAppendageIndicatorNoneCode}, body : {[empty |-> 0]} ]

EncodeBoloAppendageIndicatorChoice(message) ==
    CASE message.tag = BoloAppendageShortFormCode -> EncodeBoloAppendageShortForm(message.body)
      [] message.tag = BoloAppendageLongFormCode -> EncodeBoloAppendageLongForm(message.body)
      [] message.tag = BoloAppendageMpidFormCode -> EncodeBoloAppendageMpidForm(message.body)
      [] OTHER -> << >>

DecodeBoloAppendageIndicatorChoice(tag, bytes) ==
    LET read ==
            CASE tag = BoloAppendageShortFormCode -> DecodeBoloAppendageShortForm(bytes)
              [] tag = BoloAppendageLongFormCode -> DecodeBoloAppendageLongForm(bytes)
              [] tag = BoloAppendageMpidFormCode -> DecodeBoloAppendageMpidForm(bytes)
              [] OTHER -> Ok([empty |-> 0], bytes)
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroBoloAppendageIndicatorChoice == [tag |-> BoloAppendageShortFormCode, body |-> ZeroBoloAppendageShortForm]

(* Each Bolo Appendage Indicator in turn, at the values the message it names is checked at *)
CheckedBoloAppendageIndicatorChoice ==
    { [tag |-> BoloAppendageShortFormCode, body |-> one] : one \in CheckedBoloAppendageShortForm }
        \cup { [tag |-> BoloAppendageLongFormCode, body |-> one] : one \in CheckedBoloAppendageLongForm }
        \cup { [tag |-> BoloAppendageMpidFormCode, body |-> one] : one \in CheckedBoloAppendageMpidForm }
        \cup { [tag |-> BoloAppendageIndicatorNoneCode, body |-> [empty |-> 0]] }

(***************************************************************************)
(* Combined Quote Message Short Form Message                               *)
(***************************************************************************)

CombinedQuoteMessageShortFormMessage ==
    [ marketCenterOriginator       : Sample(1),
      subMarketCenterId            : Sample(1),
      sipTimestamp                 : Sample(8),
      timestamp1                   : Sample(8),
      participantToken             : Sample(8),
      symbolShort                  : Sample(5),
      protectedBidPriceShort       : Sample(2),
      protectedBidSizeShort        : Sample(2),
      protectedAskPriceShort       : Sample(2),
      protectedAskSizeShort        : Sample(2),
      quoteCondition               : Sample(1),
      sipGeneratedUpdateFlag       : Sample(1),
      luldBboIndicator             : Sample(1),
      retailInterestIndicator      : Sample(1),
      luldNationalBboIndicator     : Sample(1),
      oddLotAttachmentType         : Sample(1),
      oddLotAttachmentCount        : Sample(2),
      nbboAppendageIndicatorChoice : NbboAppendageIndicatorChoice3,
      boloAppendageIndicatorChoice : BoloAppendageIndicatorChoice ]

EncodeCombinedQuoteMessageShortFormMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o message.symbolShort
        \o message.protectedBidPriceShort
        \o message.protectedBidSizeShort
        \o message.protectedAskPriceShort
        \o message.protectedAskSizeShort
        \o message.quoteCondition
        \o message.sipGeneratedUpdateFlag
        \o message.luldBboIndicator
        \o message.retailInterestIndicator
        \o EncodeUIntBE(message.nbboAppendageIndicatorChoice.tag, 1)
        \o message.luldNationalBboIndicator
        \o EncodeUIntBE(message.boloAppendageIndicatorChoice.tag, 1)
        \o message.oddLotAttachmentType
        \o message.oddLotAttachmentCount
        \o EncodeNbboAppendageIndicatorChoice3(message.nbboAppendageIndicatorChoice)
        \o EncodeBoloAppendageIndicatorChoice(message.boloAppendageIndicatorChoice)

DecodeCombinedQuoteMessageShortFormMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET symbolShort == ReadBytes(participantToken.rest, 5) IN IF ~symbolShort.ok THEN Fail ELSE
    LET protectedBidPriceShort == ReadBytes(symbolShort.rest, 2) IN IF ~protectedBidPriceShort.ok THEN Fail ELSE
    LET protectedBidSizeShort == ReadBytes(protectedBidPriceShort.rest, 2) IN IF ~protectedBidSizeShort.ok THEN Fail ELSE
    LET protectedAskPriceShort == ReadBytes(protectedBidSizeShort.rest, 2) IN IF ~protectedAskPriceShort.ok THEN Fail ELSE
    LET protectedAskSizeShort == ReadBytes(protectedAskPriceShort.rest, 2) IN IF ~protectedAskSizeShort.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(protectedAskSizeShort.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET sipGeneratedUpdateFlag == ReadBytes(quoteCondition.rest, 1) IN IF ~sipGeneratedUpdateFlag.ok THEN Fail ELSE
    LET luldBboIndicator == ReadBytes(sipGeneratedUpdateFlag.rest, 1) IN IF ~luldBboIndicator.ok THEN Fail ELSE
    LET retailInterestIndicator == ReadBytes(luldBboIndicator.rest, 1) IN IF ~retailInterestIndicator.ok THEN Fail ELSE
    LET nbboAppendageIndicator == ReadUIntBE(retailInterestIndicator.rest, 1) IN IF ~nbboAppendageIndicator.ok THEN Fail ELSE
    LET luldNationalBboIndicator == ReadBytes(nbboAppendageIndicator.rest, 1) IN IF ~luldNationalBboIndicator.ok THEN Fail ELSE
    LET boloAppendageIndicator == ReadUIntBE(luldNationalBboIndicator.rest, 1) IN IF ~boloAppendageIndicator.ok THEN Fail ELSE
    LET oddLotAttachmentType == ReadBytes(boloAppendageIndicator.rest, 1) IN IF ~oddLotAttachmentType.ok THEN Fail ELSE
    LET oddLotAttachmentCount == ReadBytes(oddLotAttachmentType.rest, 2) IN IF ~oddLotAttachmentCount.ok THEN Fail ELSE
    LET nbboAppendageIndicatorChoice == DecodeNbboAppendageIndicatorChoice3(nbboAppendageIndicator.value, oddLotAttachmentCount.rest) IN IF ~nbboAppendageIndicatorChoice.ok THEN Fail ELSE
    LET boloAppendageIndicatorChoice == DecodeBoloAppendageIndicatorChoice(boloAppendageIndicator.value, nbboAppendageIndicatorChoice.rest) IN IF ~boloAppendageIndicatorChoice.ok THEN Fail ELSE
    Ok([ marketCenterOriginator       |-> marketCenterOriginator.value,
         subMarketCenterId            |-> subMarketCenterId.value,
         sipTimestamp                 |-> sipTimestamp.value,
         timestamp1                   |-> timestamp1.value,
         participantToken             |-> participantToken.value,
         symbolShort                  |-> symbolShort.value,
         protectedBidPriceShort       |-> protectedBidPriceShort.value,
         protectedBidSizeShort        |-> protectedBidSizeShort.value,
         protectedAskPriceShort       |-> protectedAskPriceShort.value,
         protectedAskSizeShort        |-> protectedAskSizeShort.value,
         quoteCondition               |-> quoteCondition.value,
         sipGeneratedUpdateFlag       |-> sipGeneratedUpdateFlag.value,
         luldBboIndicator             |-> luldBboIndicator.value,
         retailInterestIndicator      |-> retailInterestIndicator.value,
         luldNationalBboIndicator     |-> luldNationalBboIndicator.value,
         oddLotAttachmentType         |-> oddLotAttachmentType.value,
         oddLotAttachmentCount        |-> oddLotAttachmentCount.value,
         nbboAppendageIndicatorChoice |-> nbboAppendageIndicatorChoice.value,
         boloAppendageIndicatorChoice |-> boloAppendageIndicatorChoice.value ], boloAppendageIndicatorChoice.rest)

ZeroCombinedQuoteMessageShortFormMessage ==
    [ marketCenterOriginator       |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId            |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp                 |-> [i \in 1 .. 8 |-> 0],
      timestamp1                   |-> [i \in 1 .. 8 |-> 0],
      participantToken             |-> [i \in 1 .. 8 |-> 0],
      symbolShort                  |-> [i \in 1 .. 5 |-> 0],
      protectedBidPriceShort       |-> [i \in 1 .. 2 |-> 0],
      protectedBidSizeShort        |-> [i \in 1 .. 2 |-> 0],
      protectedAskPriceShort       |-> [i \in 1 .. 2 |-> 0],
      protectedAskSizeShort        |-> [i \in 1 .. 2 |-> 0],
      quoteCondition               |-> [i \in 1 .. 1 |-> 0],
      sipGeneratedUpdateFlag       |-> [i \in 1 .. 1 |-> 0],
      luldBboIndicator             |-> [i \in 1 .. 1 |-> 0],
      retailInterestIndicator      |-> [i \in 1 .. 1 |-> 0],
      luldNationalBboIndicator     |-> [i \in 1 .. 1 |-> 0],
      oddLotAttachmentType         |-> [i \in 1 .. 1 |-> 0],
      oddLotAttachmentCount        |-> [i \in 1 .. 2 |-> 0],
      nbboAppendageIndicatorChoice |-> ZeroNbboAppendageIndicatorChoice3,
      boloAppendageIndicatorChoice |-> ZeroBoloAppendageIndicatorChoice ]

(* Combined Quote Message Short Form Message at zero, then each field in turn at the values it is checked at *)
CheckedCombinedQuoteMessageShortFormMessage ==
    { ZeroCombinedQuoteMessageShortFormMessage }
        \cup { [ZeroCombinedQuoteMessageShortFormMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroCombinedQuoteMessageShortFormMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroCombinedQuoteMessageShortFormMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroCombinedQuoteMessageShortFormMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroCombinedQuoteMessageShortFormMessage EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroCombinedQuoteMessageShortFormMessage EXCEPT !.symbolShort = one] : one \in Sample(5) }
        \cup { [ZeroCombinedQuoteMessageShortFormMessage EXCEPT !.protectedBidPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroCombinedQuoteMessageShortFormMessage EXCEPT !.protectedBidSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroCombinedQuoteMessageShortFormMessage EXCEPT !.protectedAskPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroCombinedQuoteMessageShortFormMessage EXCEPT !.protectedAskSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroCombinedQuoteMessageShortFormMessage EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroCombinedQuoteMessageShortFormMessage EXCEPT !.sipGeneratedUpdateFlag = one] : one \in Sample(1) }
        \cup { [ZeroCombinedQuoteMessageShortFormMessage EXCEPT !.luldBboIndicator = one] : one \in Sample(1) }
        \cup { [ZeroCombinedQuoteMessageShortFormMessage EXCEPT !.retailInterestIndicator = one] : one \in Sample(1) }
        \cup { [ZeroCombinedQuoteMessageShortFormMessage EXCEPT !.luldNationalBboIndicator = one] : one \in Sample(1) }
        \cup { [ZeroCombinedQuoteMessageShortFormMessage EXCEPT !.oddLotAttachmentType = one] : one \in Sample(1) }
        \cup { [ZeroCombinedQuoteMessageShortFormMessage EXCEPT !.oddLotAttachmentCount = one] : one \in Sample(2) }
        \cup { [ZeroCombinedQuoteMessageShortFormMessage EXCEPT !.nbboAppendageIndicatorChoice = one] : one \in CheckedNbboAppendageIndicatorChoice3 }
        \cup { [ZeroCombinedQuoteMessageShortFormMessage EXCEPT !.boloAppendageIndicatorChoice = one] : one \in CheckedBoloAppendageIndicatorChoice }

(***************************************************************************)
(* National Bbo Appendage Shortform: 11 bytes                              *)
(***************************************************************************)

NationalBboAppendageShortform4 ==
    [ nbboQuoteCondition          : Sample(1),
      nationalBestBidMarketCenter : Sample(1),
      nationalBestBidPriceShort   : Sample(2),
      nationalBestBidSizeShort    : Sample(2),
      nationalBestAskMarketCenter : Sample(1),
      nationalBestAskPriceShort   : Sample(2),
      nationalBestAskSizeShort    : Sample(2) ]

EncodeNationalBboAppendageShortform4(message) ==
    message.nbboQuoteCondition
        \o message.nationalBestBidMarketCenter
        \o message.nationalBestBidPriceShort
        \o message.nationalBestBidSizeShort
        \o message.nationalBestAskMarketCenter
        \o message.nationalBestAskPriceShort
        \o message.nationalBestAskSizeShort

DecodeNationalBboAppendageShortform4(bytes) ==
    LET nbboQuoteCondition == ReadBytes(bytes, 1) IN IF ~nbboQuoteCondition.ok THEN Fail ELSE
    LET nationalBestBidMarketCenter == ReadBytes(nbboQuoteCondition.rest, 1) IN IF ~nationalBestBidMarketCenter.ok THEN Fail ELSE
    LET nationalBestBidPriceShort == ReadBytes(nationalBestBidMarketCenter.rest, 2) IN IF ~nationalBestBidPriceShort.ok THEN Fail ELSE
    LET nationalBestBidSizeShort == ReadBytes(nationalBestBidPriceShort.rest, 2) IN IF ~nationalBestBidSizeShort.ok THEN Fail ELSE
    LET nationalBestAskMarketCenter == ReadBytes(nationalBestBidSizeShort.rest, 1) IN IF ~nationalBestAskMarketCenter.ok THEN Fail ELSE
    LET nationalBestAskPriceShort == ReadBytes(nationalBestAskMarketCenter.rest, 2) IN IF ~nationalBestAskPriceShort.ok THEN Fail ELSE
    LET nationalBestAskSizeShort == ReadBytes(nationalBestAskPriceShort.rest, 2) IN IF ~nationalBestAskSizeShort.ok THEN Fail ELSE
    Ok([ nbboQuoteCondition          |-> nbboQuoteCondition.value,
         nationalBestBidMarketCenter |-> nationalBestBidMarketCenter.value,
         nationalBestBidPriceShort   |-> nationalBestBidPriceShort.value,
         nationalBestBidSizeShort    |-> nationalBestBidSizeShort.value,
         nationalBestAskMarketCenter |-> nationalBestAskMarketCenter.value,
         nationalBestAskPriceShort   |-> nationalBestAskPriceShort.value,
         nationalBestAskSizeShort    |-> nationalBestAskSizeShort.value ], nationalBestAskSizeShort.rest)

ZeroNationalBboAppendageShortform4 ==
    [ nbboQuoteCondition          |-> [i \in 1 .. 1 |-> 0],
      nationalBestBidMarketCenter |-> [i \in 1 .. 1 |-> 0],
      nationalBestBidPriceShort   |-> [i \in 1 .. 2 |-> 0],
      nationalBestBidSizeShort    |-> [i \in 1 .. 2 |-> 0],
      nationalBestAskMarketCenter |-> [i \in 1 .. 1 |-> 0],
      nationalBestAskPriceShort   |-> [i \in 1 .. 2 |-> 0],
      nationalBestAskSizeShort    |-> [i \in 1 .. 2 |-> 0] ]

(* National Bbo Appendage Shortform at zero, then each field in turn at the values it is checked at *)
CheckedNationalBboAppendageShortform4 ==
    { ZeroNationalBboAppendageShortform4 }
        \cup { [ZeroNationalBboAppendageShortform4 EXCEPT !.nbboQuoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroNationalBboAppendageShortform4 EXCEPT !.nationalBestBidMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroNationalBboAppendageShortform4 EXCEPT !.nationalBestBidPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroNationalBboAppendageShortform4 EXCEPT !.nationalBestBidSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroNationalBboAppendageShortform4 EXCEPT !.nationalBestAskMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroNationalBboAppendageShortform4 EXCEPT !.nationalBestAskPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroNationalBboAppendageShortform4 EXCEPT !.nationalBestAskSizeShort = one] : one \in Sample(2) }

(***************************************************************************)
(* National Bbo Appendage Longform: 27 bytes                               *)
(***************************************************************************)

NationalBboAppendageLongform4 ==
    [ nbboQuoteCondition          : Sample(1),
      nationalBestBidMarketCenter : Sample(1),
      nationalBestBidPriceLong    : Sample(8),
      nationalBestBidSizeLong     : Sample(4),
      nationalBestAskMarketCenter : Sample(1),
      nationalBestAskPriceLong    : Sample(8),
      nationalBestAskSizeLong     : Sample(4) ]

EncodeNationalBboAppendageLongform4(message) ==
    message.nbboQuoteCondition
        \o message.nationalBestBidMarketCenter
        \o message.nationalBestBidPriceLong
        \o message.nationalBestBidSizeLong
        \o message.nationalBestAskMarketCenter
        \o message.nationalBestAskPriceLong
        \o message.nationalBestAskSizeLong

DecodeNationalBboAppendageLongform4(bytes) ==
    LET nbboQuoteCondition == ReadBytes(bytes, 1) IN IF ~nbboQuoteCondition.ok THEN Fail ELSE
    LET nationalBestBidMarketCenter == ReadBytes(nbboQuoteCondition.rest, 1) IN IF ~nationalBestBidMarketCenter.ok THEN Fail ELSE
    LET nationalBestBidPriceLong == ReadBytes(nationalBestBidMarketCenter.rest, 8) IN IF ~nationalBestBidPriceLong.ok THEN Fail ELSE
    LET nationalBestBidSizeLong == ReadBytes(nationalBestBidPriceLong.rest, 4) IN IF ~nationalBestBidSizeLong.ok THEN Fail ELSE
    LET nationalBestAskMarketCenter == ReadBytes(nationalBestBidSizeLong.rest, 1) IN IF ~nationalBestAskMarketCenter.ok THEN Fail ELSE
    LET nationalBestAskPriceLong == ReadBytes(nationalBestAskMarketCenter.rest, 8) IN IF ~nationalBestAskPriceLong.ok THEN Fail ELSE
    LET nationalBestAskSizeLong == ReadBytes(nationalBestAskPriceLong.rest, 4) IN IF ~nationalBestAskSizeLong.ok THEN Fail ELSE
    Ok([ nbboQuoteCondition          |-> nbboQuoteCondition.value,
         nationalBestBidMarketCenter |-> nationalBestBidMarketCenter.value,
         nationalBestBidPriceLong    |-> nationalBestBidPriceLong.value,
         nationalBestBidSizeLong     |-> nationalBestBidSizeLong.value,
         nationalBestAskMarketCenter |-> nationalBestAskMarketCenter.value,
         nationalBestAskPriceLong    |-> nationalBestAskPriceLong.value,
         nationalBestAskSizeLong     |-> nationalBestAskSizeLong.value ], nationalBestAskSizeLong.rest)

ZeroNationalBboAppendageLongform4 ==
    [ nbboQuoteCondition          |-> [i \in 1 .. 1 |-> 0],
      nationalBestBidMarketCenter |-> [i \in 1 .. 1 |-> 0],
      nationalBestBidPriceLong    |-> [i \in 1 .. 8 |-> 0],
      nationalBestBidSizeLong     |-> [i \in 1 .. 4 |-> 0],
      nationalBestAskMarketCenter |-> [i \in 1 .. 1 |-> 0],
      nationalBestAskPriceLong    |-> [i \in 1 .. 8 |-> 0],
      nationalBestAskSizeLong     |-> [i \in 1 .. 4 |-> 0] ]

(* National Bbo Appendage Longform at zero, then each field in turn at the values it is checked at *)
CheckedNationalBboAppendageLongform4 ==
    { ZeroNationalBboAppendageLongform4 }
        \cup { [ZeroNationalBboAppendageLongform4 EXCEPT !.nbboQuoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroNationalBboAppendageLongform4 EXCEPT !.nationalBestBidMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroNationalBboAppendageLongform4 EXCEPT !.nationalBestBidPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroNationalBboAppendageLongform4 EXCEPT !.nationalBestBidSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroNationalBboAppendageLongform4 EXCEPT !.nationalBestAskMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroNationalBboAppendageLongform4 EXCEPT !.nationalBestAskPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroNationalBboAppendageLongform4 EXCEPT !.nationalBestAskSizeLong = one] : one \in Sample(4) }

(***************************************************************************)
(* What Nbbo Appendage Indicator decides is present                        *)
(***************************************************************************)

NationalBboAppendageShortformCode4 == 50  \* "2"
NationalBboAppendageLongformCode4 == 51  \* "3"
NbboAppendageIndicatorNoneCode4 == 0  \* 

NbboAppendageIndicatorChoice4 ==
    [ tag : {NationalBboAppendageShortformCode4}, body : NationalBboAppendageShortform4 ]
        \cup [ tag : {NationalBboAppendageLongformCode4}, body : NationalBboAppendageLongform4 ]
        \cup [ tag : {NbboAppendageIndicatorNoneCode4}, body : {[empty |-> 0]} ]

EncodeNbboAppendageIndicatorChoice4(message) ==
    CASE message.tag = NationalBboAppendageShortformCode4 -> EncodeNationalBboAppendageShortform4(message.body)
      [] message.tag = NationalBboAppendageLongformCode4 -> EncodeNationalBboAppendageLongform4(message.body)
      [] OTHER -> << >>

DecodeNbboAppendageIndicatorChoice4(tag, bytes) ==
    LET read ==
            CASE tag = NationalBboAppendageShortformCode4 -> DecodeNationalBboAppendageShortform4(bytes)
              [] tag = NationalBboAppendageLongformCode4 -> DecodeNationalBboAppendageLongform4(bytes)
              [] OTHER -> Ok([empty |-> 0], bytes)
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroNbboAppendageIndicatorChoice4 == [tag |-> NationalBboAppendageShortformCode4, body |-> ZeroNationalBboAppendageShortform4]

(* Each Nbbo Appendage Indicator in turn, at the values the message it names is checked at *)
CheckedNbboAppendageIndicatorChoice4 ==
    { [tag |-> NationalBboAppendageShortformCode4, body |-> one] : one \in CheckedNationalBboAppendageShortform4 }
        \cup { [tag |-> NationalBboAppendageLongformCode4, body |-> one] : one \in CheckedNationalBboAppendageLongform4 }
        \cup { [tag |-> NbboAppendageIndicatorNoneCode4, body |-> [empty |-> 0]] }

(***************************************************************************)
(* Finra Adf Mpid Appendage: 8 bytes                                       *)
(***************************************************************************)

FinraAdfMpidAppendage ==
    [ bidAdfMpid : Sample(4),
      askAdfMpid : Sample(4) ]

EncodeFinraAdfMpidAppendage(message) ==
    message.bidAdfMpid
        \o message.askAdfMpid

DecodeFinraAdfMpidAppendage(bytes) ==
    LET bidAdfMpid == ReadBytes(bytes, 4) IN IF ~bidAdfMpid.ok THEN Fail ELSE
    LET askAdfMpid == ReadBytes(bidAdfMpid.rest, 4) IN IF ~askAdfMpid.ok THEN Fail ELSE
    Ok([ bidAdfMpid |-> bidAdfMpid.value,
         askAdfMpid |-> askAdfMpid.value ], askAdfMpid.rest)

ZeroFinraAdfMpidAppendage ==
    [ bidAdfMpid |-> [i \in 1 .. 4 |-> 0],
      askAdfMpid |-> [i \in 1 .. 4 |-> 0] ]

(* Finra Adf Mpid Appendage at zero, then each field in turn at the values it is checked at *)
CheckedFinraAdfMpidAppendage ==
    { ZeroFinraAdfMpidAppendage }
        \cup { [ZeroFinraAdfMpidAppendage EXCEPT !.bidAdfMpid = one] : one \in Sample(4) }
        \cup { [ZeroFinraAdfMpidAppendage EXCEPT !.askAdfMpid = one] : one \in Sample(4) }

(***************************************************************************)
(* What Finra Adf Mpid Appendage Indicator decides is present              *)
(***************************************************************************)

FinraAdfMpidAppendageCode == 50  \* "2"
FinraAdfMpidAppendageIndicatorNoneCode == 0  \* 

FinraAdfMpidAppendageIndicatorChoice ==
    [ tag : {FinraAdfMpidAppendageCode}, body : FinraAdfMpidAppendage ]
        \cup [ tag : {FinraAdfMpidAppendageIndicatorNoneCode}, body : {[empty |-> 0]} ]

EncodeFinraAdfMpidAppendageIndicatorChoice(message) ==
    CASE message.tag = FinraAdfMpidAppendageCode -> EncodeFinraAdfMpidAppendage(message.body)
      [] OTHER -> << >>

DecodeFinraAdfMpidAppendageIndicatorChoice(tag, bytes) ==
    LET read ==
            CASE tag = FinraAdfMpidAppendageCode -> DecodeFinraAdfMpidAppendage(bytes)
              [] OTHER -> Ok([empty |-> 0], bytes)
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroFinraAdfMpidAppendageIndicatorChoice == [tag |-> FinraAdfMpidAppendageCode, body |-> ZeroFinraAdfMpidAppendage]

(* Each Finra Adf Mpid Appendage Indicator in turn, at the values the message it names is checked at *)
CheckedFinraAdfMpidAppendageIndicatorChoice ==
    { [tag |-> FinraAdfMpidAppendageCode, body |-> one] : one \in CheckedFinraAdfMpidAppendage }
        \cup { [tag |-> FinraAdfMpidAppendageIndicatorNoneCode, body |-> [empty |-> 0]] }

(***************************************************************************)
(* Bolo Appendage Short Form: 10 bytes                                     *)
(***************************************************************************)

BoloAppendageShortForm2 ==
    [ boloBestBidMarketCenter : Sample(1),
      boloBidPriceShort       : Sample(2),
      boloBidSize             : Sample(2),
      boloBestAskMarketCenter : Sample(1),
      boloAskPriceShort       : Sample(2),
      boloAskSize             : Sample(2) ]

EncodeBoloAppendageShortForm2(message) ==
    message.boloBestBidMarketCenter
        \o message.boloBidPriceShort
        \o message.boloBidSize
        \o message.boloBestAskMarketCenter
        \o message.boloAskPriceShort
        \o message.boloAskSize

DecodeBoloAppendageShortForm2(bytes) ==
    LET boloBestBidMarketCenter == ReadBytes(bytes, 1) IN IF ~boloBestBidMarketCenter.ok THEN Fail ELSE
    LET boloBidPriceShort == ReadBytes(boloBestBidMarketCenter.rest, 2) IN IF ~boloBidPriceShort.ok THEN Fail ELSE
    LET boloBidSize == ReadBytes(boloBidPriceShort.rest, 2) IN IF ~boloBidSize.ok THEN Fail ELSE
    LET boloBestAskMarketCenter == ReadBytes(boloBidSize.rest, 1) IN IF ~boloBestAskMarketCenter.ok THEN Fail ELSE
    LET boloAskPriceShort == ReadBytes(boloBestAskMarketCenter.rest, 2) IN IF ~boloAskPriceShort.ok THEN Fail ELSE
    LET boloAskSize == ReadBytes(boloAskPriceShort.rest, 2) IN IF ~boloAskSize.ok THEN Fail ELSE
    Ok([ boloBestBidMarketCenter |-> boloBestBidMarketCenter.value,
         boloBidPriceShort       |-> boloBidPriceShort.value,
         boloBidSize             |-> boloBidSize.value,
         boloBestAskMarketCenter |-> boloBestAskMarketCenter.value,
         boloAskPriceShort       |-> boloAskPriceShort.value,
         boloAskSize             |-> boloAskSize.value ], boloAskSize.rest)

ZeroBoloAppendageShortForm2 ==
    [ boloBestBidMarketCenter |-> [i \in 1 .. 1 |-> 0],
      boloBidPriceShort       |-> [i \in 1 .. 2 |-> 0],
      boloBidSize             |-> [i \in 1 .. 2 |-> 0],
      boloBestAskMarketCenter |-> [i \in 1 .. 1 |-> 0],
      boloAskPriceShort       |-> [i \in 1 .. 2 |-> 0],
      boloAskSize             |-> [i \in 1 .. 2 |-> 0] ]

(* Bolo Appendage Short Form at zero, then each field in turn at the values it is checked at *)
CheckedBoloAppendageShortForm2 ==
    { ZeroBoloAppendageShortForm2 }
        \cup { [ZeroBoloAppendageShortForm2 EXCEPT !.boloBestBidMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroBoloAppendageShortForm2 EXCEPT !.boloBidPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroBoloAppendageShortForm2 EXCEPT !.boloBidSize = one] : one \in Sample(2) }
        \cup { [ZeroBoloAppendageShortForm2 EXCEPT !.boloBestAskMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroBoloAppendageShortForm2 EXCEPT !.boloAskPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroBoloAppendageShortForm2 EXCEPT !.boloAskSize = one] : one \in Sample(2) }

(***************************************************************************)
(* Bolo Appendage Long Form: 22 bytes                                      *)
(***************************************************************************)

BoloAppendageLongForm2 ==
    [ boloBestBidMarketCenter : Sample(1),
      boloBidPriceLong        : Sample(8),
      boloBidSize             : Sample(2),
      boloBestAskMarketCenter : Sample(1),
      boloAskPriceLong        : Sample(8),
      boloAskSize             : Sample(2) ]

EncodeBoloAppendageLongForm2(message) ==
    message.boloBestBidMarketCenter
        \o message.boloBidPriceLong
        \o message.boloBidSize
        \o message.boloBestAskMarketCenter
        \o message.boloAskPriceLong
        \o message.boloAskSize

DecodeBoloAppendageLongForm2(bytes) ==
    LET boloBestBidMarketCenter == ReadBytes(bytes, 1) IN IF ~boloBestBidMarketCenter.ok THEN Fail ELSE
    LET boloBidPriceLong == ReadBytes(boloBestBidMarketCenter.rest, 8) IN IF ~boloBidPriceLong.ok THEN Fail ELSE
    LET boloBidSize == ReadBytes(boloBidPriceLong.rest, 2) IN IF ~boloBidSize.ok THEN Fail ELSE
    LET boloBestAskMarketCenter == ReadBytes(boloBidSize.rest, 1) IN IF ~boloBestAskMarketCenter.ok THEN Fail ELSE
    LET boloAskPriceLong == ReadBytes(boloBestAskMarketCenter.rest, 8) IN IF ~boloAskPriceLong.ok THEN Fail ELSE
    LET boloAskSize == ReadBytes(boloAskPriceLong.rest, 2) IN IF ~boloAskSize.ok THEN Fail ELSE
    Ok([ boloBestBidMarketCenter |-> boloBestBidMarketCenter.value,
         boloBidPriceLong        |-> boloBidPriceLong.value,
         boloBidSize             |-> boloBidSize.value,
         boloBestAskMarketCenter |-> boloBestAskMarketCenter.value,
         boloAskPriceLong        |-> boloAskPriceLong.value,
         boloAskSize             |-> boloAskSize.value ], boloAskSize.rest)

ZeroBoloAppendageLongForm2 ==
    [ boloBestBidMarketCenter |-> [i \in 1 .. 1 |-> 0],
      boloBidPriceLong        |-> [i \in 1 .. 8 |-> 0],
      boloBidSize             |-> [i \in 1 .. 2 |-> 0],
      boloBestAskMarketCenter |-> [i \in 1 .. 1 |-> 0],
      boloAskPriceLong        |-> [i \in 1 .. 8 |-> 0],
      boloAskSize             |-> [i \in 1 .. 2 |-> 0] ]

(* Bolo Appendage Long Form at zero, then each field in turn at the values it is checked at *)
CheckedBoloAppendageLongForm2 ==
    { ZeroBoloAppendageLongForm2 }
        \cup { [ZeroBoloAppendageLongForm2 EXCEPT !.boloBestBidMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroBoloAppendageLongForm2 EXCEPT !.boloBidPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroBoloAppendageLongForm2 EXCEPT !.boloBidSize = one] : one \in Sample(2) }
        \cup { [ZeroBoloAppendageLongForm2 EXCEPT !.boloBestAskMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroBoloAppendageLongForm2 EXCEPT !.boloAskPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroBoloAppendageLongForm2 EXCEPT !.boloAskSize = one] : one \in Sample(2) }

(***************************************************************************)
(* Bolo Appendage Mpid Form: 30 bytes                                      *)
(***************************************************************************)

BoloAppendageMpidForm2 ==
    [ boloBestBidMarketCenter                : Sample(1),
      boloBidPriceLong                       : Sample(8),
      boloBidSize                            : Sample(2),
      boloBestAskMarketCenter                : Sample(1),
      boloAskPriceLong                       : Sample(8),
      boloAskSize                            : Sample(2),
      boloBestBidMarketParticipantIdentifier : Sample(4),
      boloBestAskMarketParticipantIdentifier : Sample(4) ]

EncodeBoloAppendageMpidForm2(message) ==
    message.boloBestBidMarketCenter
        \o message.boloBidPriceLong
        \o message.boloBidSize
        \o message.boloBestAskMarketCenter
        \o message.boloAskPriceLong
        \o message.boloAskSize
        \o message.boloBestBidMarketParticipantIdentifier
        \o message.boloBestAskMarketParticipantIdentifier

DecodeBoloAppendageMpidForm2(bytes) ==
    LET boloBestBidMarketCenter == ReadBytes(bytes, 1) IN IF ~boloBestBidMarketCenter.ok THEN Fail ELSE
    LET boloBidPriceLong == ReadBytes(boloBestBidMarketCenter.rest, 8) IN IF ~boloBidPriceLong.ok THEN Fail ELSE
    LET boloBidSize == ReadBytes(boloBidPriceLong.rest, 2) IN IF ~boloBidSize.ok THEN Fail ELSE
    LET boloBestAskMarketCenter == ReadBytes(boloBidSize.rest, 1) IN IF ~boloBestAskMarketCenter.ok THEN Fail ELSE
    LET boloAskPriceLong == ReadBytes(boloBestAskMarketCenter.rest, 8) IN IF ~boloAskPriceLong.ok THEN Fail ELSE
    LET boloAskSize == ReadBytes(boloAskPriceLong.rest, 2) IN IF ~boloAskSize.ok THEN Fail ELSE
    LET boloBestBidMarketParticipantIdentifier == ReadBytes(boloAskSize.rest, 4) IN IF ~boloBestBidMarketParticipantIdentifier.ok THEN Fail ELSE
    LET boloBestAskMarketParticipantIdentifier == ReadBytes(boloBestBidMarketParticipantIdentifier.rest, 4) IN IF ~boloBestAskMarketParticipantIdentifier.ok THEN Fail ELSE
    Ok([ boloBestBidMarketCenter                |-> boloBestBidMarketCenter.value,
         boloBidPriceLong                       |-> boloBidPriceLong.value,
         boloBidSize                            |-> boloBidSize.value,
         boloBestAskMarketCenter                |-> boloBestAskMarketCenter.value,
         boloAskPriceLong                       |-> boloAskPriceLong.value,
         boloAskSize                            |-> boloAskSize.value,
         boloBestBidMarketParticipantIdentifier |-> boloBestBidMarketParticipantIdentifier.value,
         boloBestAskMarketParticipantIdentifier |-> boloBestAskMarketParticipantIdentifier.value ], boloBestAskMarketParticipantIdentifier.rest)

ZeroBoloAppendageMpidForm2 ==
    [ boloBestBidMarketCenter                |-> [i \in 1 .. 1 |-> 0],
      boloBidPriceLong                       |-> [i \in 1 .. 8 |-> 0],
      boloBidSize                            |-> [i \in 1 .. 2 |-> 0],
      boloBestAskMarketCenter                |-> [i \in 1 .. 1 |-> 0],
      boloAskPriceLong                       |-> [i \in 1 .. 8 |-> 0],
      boloAskSize                            |-> [i \in 1 .. 2 |-> 0],
      boloBestBidMarketParticipantIdentifier |-> [i \in 1 .. 4 |-> 0],
      boloBestAskMarketParticipantIdentifier |-> [i \in 1 .. 4 |-> 0] ]

(* Bolo Appendage Mpid Form at zero, then each field in turn at the values it is checked at *)
CheckedBoloAppendageMpidForm2 ==
    { ZeroBoloAppendageMpidForm2 }
        \cup { [ZeroBoloAppendageMpidForm2 EXCEPT !.boloBestBidMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroBoloAppendageMpidForm2 EXCEPT !.boloBidPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroBoloAppendageMpidForm2 EXCEPT !.boloBidSize = one] : one \in Sample(2) }
        \cup { [ZeroBoloAppendageMpidForm2 EXCEPT !.boloBestAskMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroBoloAppendageMpidForm2 EXCEPT !.boloAskPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroBoloAppendageMpidForm2 EXCEPT !.boloAskSize = one] : one \in Sample(2) }
        \cup { [ZeroBoloAppendageMpidForm2 EXCEPT !.boloBestBidMarketParticipantIdentifier = one] : one \in Sample(4) }
        \cup { [ZeroBoloAppendageMpidForm2 EXCEPT !.boloBestAskMarketParticipantIdentifier = one] : one \in Sample(4) }

(***************************************************************************)
(* What Bolo Appendage Indicator decides is present                        *)
(***************************************************************************)

BoloAppendageShortFormCode2 == 50  \* "2"
BoloAppendageLongFormCode2 == 51  \* "3"
BoloAppendageMpidFormCode2 == 53  \* "5"
BoloAppendageIndicatorNoneCode2 == 0  \* 

BoloAppendageIndicatorChoice2 ==
    [ tag : {BoloAppendageShortFormCode2}, body : BoloAppendageShortForm2 ]
        \cup [ tag : {BoloAppendageLongFormCode2}, body : BoloAppendageLongForm2 ]
        \cup [ tag : {BoloAppendageMpidFormCode2}, body : BoloAppendageMpidForm2 ]
        \cup [ tag : {BoloAppendageIndicatorNoneCode2}, body : {[empty |-> 0]} ]

EncodeBoloAppendageIndicatorChoice2(message) ==
    CASE message.tag = BoloAppendageShortFormCode2 -> EncodeBoloAppendageShortForm2(message.body)
      [] message.tag = BoloAppendageLongFormCode2 -> EncodeBoloAppendageLongForm2(message.body)
      [] message.tag = BoloAppendageMpidFormCode2 -> EncodeBoloAppendageMpidForm2(message.body)
      [] OTHER -> << >>

DecodeBoloAppendageIndicatorChoice2(tag, bytes) ==
    LET read ==
            CASE tag = BoloAppendageShortFormCode2 -> DecodeBoloAppendageShortForm2(bytes)
              [] tag = BoloAppendageLongFormCode2 -> DecodeBoloAppendageLongForm2(bytes)
              [] tag = BoloAppendageMpidFormCode2 -> DecodeBoloAppendageMpidForm2(bytes)
              [] OTHER -> Ok([empty |-> 0], bytes)
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroBoloAppendageIndicatorChoice2 == [tag |-> BoloAppendageShortFormCode2, body |-> ZeroBoloAppendageShortForm2]

(* Each Bolo Appendage Indicator in turn, at the values the message it names is checked at *)
CheckedBoloAppendageIndicatorChoice2 ==
    { [tag |-> BoloAppendageShortFormCode2, body |-> one] : one \in CheckedBoloAppendageShortForm2 }
        \cup { [tag |-> BoloAppendageLongFormCode2, body |-> one] : one \in CheckedBoloAppendageLongForm2 }
        \cup { [tag |-> BoloAppendageMpidFormCode2, body |-> one] : one \in CheckedBoloAppendageMpidForm2 }
        \cup { [tag |-> BoloAppendageIndicatorNoneCode2, body |-> [empty |-> 0]] }

(***************************************************************************)
(* Combined Quote Message Long Form Message                                *)
(***************************************************************************)

CombinedQuoteMessageLongFormMessage ==
    [ marketCenterOriginator               : Sample(1),
      subMarketCenterId                    : Sample(1),
      sipTimestamp                         : Sample(8),
      timestamp1                           : Sample(8),
      participantToken                     : Sample(8),
      adfTimestamp                         : Sample(8),
      symbolLong                           : Sample(11),
      protectedBidPriceLong                : Sample(8),
      protectedBidSizeLong                 : Sample(4),
      protectedAskPriceLong                : Sample(8),
      protectedAskSizeLong                 : Sample(4),
      quoteCondition                       : Sample(1),
      sipGeneratedUpdateFlag               : Sample(1),
      luldBboIndicator                     : Sample(1),
      retailInterestIndicator              : Sample(1),
      luldNationalBboIndicator             : Sample(1),
      oddLotAttachmentType                 : Sample(1),
      oddLotAttachmentCount                : Sample(2),
      nbboAppendageIndicatorChoice         : NbboAppendageIndicatorChoice4,
      finraAdfMpidAppendageIndicatorChoice : FinraAdfMpidAppendageIndicatorChoice,
      boloAppendageIndicatorChoice         : BoloAppendageIndicatorChoice2 ]

EncodeCombinedQuoteMessageLongFormMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o message.adfTimestamp
        \o message.symbolLong
        \o message.protectedBidPriceLong
        \o message.protectedBidSizeLong
        \o message.protectedAskPriceLong
        \o message.protectedAskSizeLong
        \o message.quoteCondition
        \o message.sipGeneratedUpdateFlag
        \o message.luldBboIndicator
        \o message.retailInterestIndicator
        \o EncodeUIntBE(message.nbboAppendageIndicatorChoice.tag, 1)
        \o message.luldNationalBboIndicator
        \o EncodeUIntBE(message.finraAdfMpidAppendageIndicatorChoice.tag, 1)
        \o EncodeUIntBE(message.boloAppendageIndicatorChoice.tag, 1)
        \o message.oddLotAttachmentType
        \o message.oddLotAttachmentCount
        \o EncodeNbboAppendageIndicatorChoice4(message.nbboAppendageIndicatorChoice)
        \o EncodeFinraAdfMpidAppendageIndicatorChoice(message.finraAdfMpidAppendageIndicatorChoice)
        \o EncodeBoloAppendageIndicatorChoice2(message.boloAppendageIndicatorChoice)

DecodeCombinedQuoteMessageLongFormMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET adfTimestamp == ReadBytes(participantToken.rest, 8) IN IF ~adfTimestamp.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(adfTimestamp.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET protectedBidPriceLong == ReadBytes(symbolLong.rest, 8) IN IF ~protectedBidPriceLong.ok THEN Fail ELSE
    LET protectedBidSizeLong == ReadBytes(protectedBidPriceLong.rest, 4) IN IF ~protectedBidSizeLong.ok THEN Fail ELSE
    LET protectedAskPriceLong == ReadBytes(protectedBidSizeLong.rest, 8) IN IF ~protectedAskPriceLong.ok THEN Fail ELSE
    LET protectedAskSizeLong == ReadBytes(protectedAskPriceLong.rest, 4) IN IF ~protectedAskSizeLong.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(protectedAskSizeLong.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET sipGeneratedUpdateFlag == ReadBytes(quoteCondition.rest, 1) IN IF ~sipGeneratedUpdateFlag.ok THEN Fail ELSE
    LET luldBboIndicator == ReadBytes(sipGeneratedUpdateFlag.rest, 1) IN IF ~luldBboIndicator.ok THEN Fail ELSE
    LET retailInterestIndicator == ReadBytes(luldBboIndicator.rest, 1) IN IF ~retailInterestIndicator.ok THEN Fail ELSE
    LET nbboAppendageIndicator == ReadUIntBE(retailInterestIndicator.rest, 1) IN IF ~nbboAppendageIndicator.ok THEN Fail ELSE
    LET luldNationalBboIndicator == ReadBytes(nbboAppendageIndicator.rest, 1) IN IF ~luldNationalBboIndicator.ok THEN Fail ELSE
    LET finraAdfMpidAppendageIndicator == ReadUIntBE(luldNationalBboIndicator.rest, 1) IN IF ~finraAdfMpidAppendageIndicator.ok THEN Fail ELSE
    LET boloAppendageIndicator == ReadUIntBE(finraAdfMpidAppendageIndicator.rest, 1) IN IF ~boloAppendageIndicator.ok THEN Fail ELSE
    LET oddLotAttachmentType == ReadBytes(boloAppendageIndicator.rest, 1) IN IF ~oddLotAttachmentType.ok THEN Fail ELSE
    LET oddLotAttachmentCount == ReadBytes(oddLotAttachmentType.rest, 2) IN IF ~oddLotAttachmentCount.ok THEN Fail ELSE
    LET nbboAppendageIndicatorChoice == DecodeNbboAppendageIndicatorChoice4(nbboAppendageIndicator.value, oddLotAttachmentCount.rest) IN IF ~nbboAppendageIndicatorChoice.ok THEN Fail ELSE
    LET finraAdfMpidAppendageIndicatorChoice == DecodeFinraAdfMpidAppendageIndicatorChoice(finraAdfMpidAppendageIndicator.value, nbboAppendageIndicatorChoice.rest) IN IF ~finraAdfMpidAppendageIndicatorChoice.ok THEN Fail ELSE
    LET boloAppendageIndicatorChoice == DecodeBoloAppendageIndicatorChoice2(boloAppendageIndicator.value, finraAdfMpidAppendageIndicatorChoice.rest) IN IF ~boloAppendageIndicatorChoice.ok THEN Fail ELSE
    Ok([ marketCenterOriginator               |-> marketCenterOriginator.value,
         subMarketCenterId                    |-> subMarketCenterId.value,
         sipTimestamp                         |-> sipTimestamp.value,
         timestamp1                           |-> timestamp1.value,
         participantToken                     |-> participantToken.value,
         adfTimestamp                         |-> adfTimestamp.value,
         symbolLong                           |-> symbolLong.value,
         protectedBidPriceLong                |-> protectedBidPriceLong.value,
         protectedBidSizeLong                 |-> protectedBidSizeLong.value,
         protectedAskPriceLong                |-> protectedAskPriceLong.value,
         protectedAskSizeLong                 |-> protectedAskSizeLong.value,
         quoteCondition                       |-> quoteCondition.value,
         sipGeneratedUpdateFlag               |-> sipGeneratedUpdateFlag.value,
         luldBboIndicator                     |-> luldBboIndicator.value,
         retailInterestIndicator              |-> retailInterestIndicator.value,
         luldNationalBboIndicator             |-> luldNationalBboIndicator.value,
         oddLotAttachmentType                 |-> oddLotAttachmentType.value,
         oddLotAttachmentCount                |-> oddLotAttachmentCount.value,
         nbboAppendageIndicatorChoice         |-> nbboAppendageIndicatorChoice.value,
         finraAdfMpidAppendageIndicatorChoice |-> finraAdfMpidAppendageIndicatorChoice.value,
         boloAppendageIndicatorChoice         |-> boloAppendageIndicatorChoice.value ], boloAppendageIndicatorChoice.rest)

ZeroCombinedQuoteMessageLongFormMessage ==
    [ marketCenterOriginator               |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId                    |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp                         |-> [i \in 1 .. 8 |-> 0],
      timestamp1                           |-> [i \in 1 .. 8 |-> 0],
      participantToken                     |-> [i \in 1 .. 8 |-> 0],
      adfTimestamp                         |-> [i \in 1 .. 8 |-> 0],
      symbolLong                           |-> [i \in 1 .. 11 |-> 0],
      protectedBidPriceLong                |-> [i \in 1 .. 8 |-> 0],
      protectedBidSizeLong                 |-> [i \in 1 .. 4 |-> 0],
      protectedAskPriceLong                |-> [i \in 1 .. 8 |-> 0],
      protectedAskSizeLong                 |-> [i \in 1 .. 4 |-> 0],
      quoteCondition                       |-> [i \in 1 .. 1 |-> 0],
      sipGeneratedUpdateFlag               |-> [i \in 1 .. 1 |-> 0],
      luldBboIndicator                     |-> [i \in 1 .. 1 |-> 0],
      retailInterestIndicator              |-> [i \in 1 .. 1 |-> 0],
      luldNationalBboIndicator             |-> [i \in 1 .. 1 |-> 0],
      oddLotAttachmentType                 |-> [i \in 1 .. 1 |-> 0],
      oddLotAttachmentCount                |-> [i \in 1 .. 2 |-> 0],
      nbboAppendageIndicatorChoice         |-> ZeroNbboAppendageIndicatorChoice4,
      finraAdfMpidAppendageIndicatorChoice |-> ZeroFinraAdfMpidAppendageIndicatorChoice,
      boloAppendageIndicatorChoice         |-> ZeroBoloAppendageIndicatorChoice2 ]

(* Combined Quote Message Long Form Message at zero, then each field in turn at the values it is checked at *)
CheckedCombinedQuoteMessageLongFormMessage ==
    { ZeroCombinedQuoteMessageLongFormMessage }
        \cup { [ZeroCombinedQuoteMessageLongFormMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroCombinedQuoteMessageLongFormMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroCombinedQuoteMessageLongFormMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroCombinedQuoteMessageLongFormMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroCombinedQuoteMessageLongFormMessage EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroCombinedQuoteMessageLongFormMessage EXCEPT !.adfTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroCombinedQuoteMessageLongFormMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroCombinedQuoteMessageLongFormMessage EXCEPT !.protectedBidPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroCombinedQuoteMessageLongFormMessage EXCEPT !.protectedBidSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroCombinedQuoteMessageLongFormMessage EXCEPT !.protectedAskPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroCombinedQuoteMessageLongFormMessage EXCEPT !.protectedAskSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroCombinedQuoteMessageLongFormMessage EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroCombinedQuoteMessageLongFormMessage EXCEPT !.sipGeneratedUpdateFlag = one] : one \in Sample(1) }
        \cup { [ZeroCombinedQuoteMessageLongFormMessage EXCEPT !.luldBboIndicator = one] : one \in Sample(1) }
        \cup { [ZeroCombinedQuoteMessageLongFormMessage EXCEPT !.retailInterestIndicator = one] : one \in Sample(1) }
        \cup { [ZeroCombinedQuoteMessageLongFormMessage EXCEPT !.luldNationalBboIndicator = one] : one \in Sample(1) }
        \cup { [ZeroCombinedQuoteMessageLongFormMessage EXCEPT !.oddLotAttachmentType = one] : one \in Sample(1) }
        \cup { [ZeroCombinedQuoteMessageLongFormMessage EXCEPT !.oddLotAttachmentCount = one] : one \in Sample(2) }
        \cup { [ZeroCombinedQuoteMessageLongFormMessage EXCEPT !.nbboAppendageIndicatorChoice = one] : one \in CheckedNbboAppendageIndicatorChoice4 }
        \cup { [ZeroCombinedQuoteMessageLongFormMessage EXCEPT !.finraAdfMpidAppendageIndicatorChoice = one] : one \in CheckedFinraAdfMpidAppendageIndicatorChoice }
        \cup { [ZeroCombinedQuoteMessageLongFormMessage EXCEPT !.boloAppendageIndicatorChoice = one] : one \in CheckedBoloAppendageIndicatorChoice2 }

(***************************************************************************)
(* Bolo Appendage Short Form: 10 bytes                                     *)
(***************************************************************************)

BoloAppendageShortForm3 ==
    [ boloBestBidMarketCenter : Sample(1),
      boloBidPriceShort       : Sample(2),
      boloBidSize             : Sample(2),
      boloBestAskMarketCenter : Sample(1),
      boloAskPriceShort       : Sample(2),
      boloAskSize             : Sample(2) ]

EncodeBoloAppendageShortForm3(message) ==
    message.boloBestBidMarketCenter
        \o message.boloBidPriceShort
        \o message.boloBidSize
        \o message.boloBestAskMarketCenter
        \o message.boloAskPriceShort
        \o message.boloAskSize

DecodeBoloAppendageShortForm3(bytes) ==
    LET boloBestBidMarketCenter == ReadBytes(bytes, 1) IN IF ~boloBestBidMarketCenter.ok THEN Fail ELSE
    LET boloBidPriceShort == ReadBytes(boloBestBidMarketCenter.rest, 2) IN IF ~boloBidPriceShort.ok THEN Fail ELSE
    LET boloBidSize == ReadBytes(boloBidPriceShort.rest, 2) IN IF ~boloBidSize.ok THEN Fail ELSE
    LET boloBestAskMarketCenter == ReadBytes(boloBidSize.rest, 1) IN IF ~boloBestAskMarketCenter.ok THEN Fail ELSE
    LET boloAskPriceShort == ReadBytes(boloBestAskMarketCenter.rest, 2) IN IF ~boloAskPriceShort.ok THEN Fail ELSE
    LET boloAskSize == ReadBytes(boloAskPriceShort.rest, 2) IN IF ~boloAskSize.ok THEN Fail ELSE
    Ok([ boloBestBidMarketCenter |-> boloBestBidMarketCenter.value,
         boloBidPriceShort       |-> boloBidPriceShort.value,
         boloBidSize             |-> boloBidSize.value,
         boloBestAskMarketCenter |-> boloBestAskMarketCenter.value,
         boloAskPriceShort       |-> boloAskPriceShort.value,
         boloAskSize             |-> boloAskSize.value ], boloAskSize.rest)

ZeroBoloAppendageShortForm3 ==
    [ boloBestBidMarketCenter |-> [i \in 1 .. 1 |-> 0],
      boloBidPriceShort       |-> [i \in 1 .. 2 |-> 0],
      boloBidSize             |-> [i \in 1 .. 2 |-> 0],
      boloBestAskMarketCenter |-> [i \in 1 .. 1 |-> 0],
      boloAskPriceShort       |-> [i \in 1 .. 2 |-> 0],
      boloAskSize             |-> [i \in 1 .. 2 |-> 0] ]

(* Bolo Appendage Short Form at zero, then each field in turn at the values it is checked at *)
CheckedBoloAppendageShortForm3 ==
    { ZeroBoloAppendageShortForm3 }
        \cup { [ZeroBoloAppendageShortForm3 EXCEPT !.boloBestBidMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroBoloAppendageShortForm3 EXCEPT !.boloBidPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroBoloAppendageShortForm3 EXCEPT !.boloBidSize = one] : one \in Sample(2) }
        \cup { [ZeroBoloAppendageShortForm3 EXCEPT !.boloBestAskMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroBoloAppendageShortForm3 EXCEPT !.boloAskPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroBoloAppendageShortForm3 EXCEPT !.boloAskSize = one] : one \in Sample(2) }

(***************************************************************************)
(* Bolo Appendage Long Form: 22 bytes                                      *)
(***************************************************************************)

BoloAppendageLongForm3 ==
    [ boloBestBidMarketCenter : Sample(1),
      boloBidPriceLong        : Sample(8),
      boloBidSize             : Sample(2),
      boloBestAskMarketCenter : Sample(1),
      boloAskPriceLong        : Sample(8),
      boloAskSize             : Sample(2) ]

EncodeBoloAppendageLongForm3(message) ==
    message.boloBestBidMarketCenter
        \o message.boloBidPriceLong
        \o message.boloBidSize
        \o message.boloBestAskMarketCenter
        \o message.boloAskPriceLong
        \o message.boloAskSize

DecodeBoloAppendageLongForm3(bytes) ==
    LET boloBestBidMarketCenter == ReadBytes(bytes, 1) IN IF ~boloBestBidMarketCenter.ok THEN Fail ELSE
    LET boloBidPriceLong == ReadBytes(boloBestBidMarketCenter.rest, 8) IN IF ~boloBidPriceLong.ok THEN Fail ELSE
    LET boloBidSize == ReadBytes(boloBidPriceLong.rest, 2) IN IF ~boloBidSize.ok THEN Fail ELSE
    LET boloBestAskMarketCenter == ReadBytes(boloBidSize.rest, 1) IN IF ~boloBestAskMarketCenter.ok THEN Fail ELSE
    LET boloAskPriceLong == ReadBytes(boloBestAskMarketCenter.rest, 8) IN IF ~boloAskPriceLong.ok THEN Fail ELSE
    LET boloAskSize == ReadBytes(boloAskPriceLong.rest, 2) IN IF ~boloAskSize.ok THEN Fail ELSE
    Ok([ boloBestBidMarketCenter |-> boloBestBidMarketCenter.value,
         boloBidPriceLong        |-> boloBidPriceLong.value,
         boloBidSize             |-> boloBidSize.value,
         boloBestAskMarketCenter |-> boloBestAskMarketCenter.value,
         boloAskPriceLong        |-> boloAskPriceLong.value,
         boloAskSize             |-> boloAskSize.value ], boloAskSize.rest)

ZeroBoloAppendageLongForm3 ==
    [ boloBestBidMarketCenter |-> [i \in 1 .. 1 |-> 0],
      boloBidPriceLong        |-> [i \in 1 .. 8 |-> 0],
      boloBidSize             |-> [i \in 1 .. 2 |-> 0],
      boloBestAskMarketCenter |-> [i \in 1 .. 1 |-> 0],
      boloAskPriceLong        |-> [i \in 1 .. 8 |-> 0],
      boloAskSize             |-> [i \in 1 .. 2 |-> 0] ]

(* Bolo Appendage Long Form at zero, then each field in turn at the values it is checked at *)
CheckedBoloAppendageLongForm3 ==
    { ZeroBoloAppendageLongForm3 }
        \cup { [ZeroBoloAppendageLongForm3 EXCEPT !.boloBestBidMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroBoloAppendageLongForm3 EXCEPT !.boloBidPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroBoloAppendageLongForm3 EXCEPT !.boloBidSize = one] : one \in Sample(2) }
        \cup { [ZeroBoloAppendageLongForm3 EXCEPT !.boloBestAskMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroBoloAppendageLongForm3 EXCEPT !.boloAskPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroBoloAppendageLongForm3 EXCEPT !.boloAskSize = one] : one \in Sample(2) }

(***************************************************************************)
(* Bolo Appendage Mpid Form: 30 bytes                                      *)
(***************************************************************************)

BoloAppendageMpidForm3 ==
    [ boloBestBidMarketCenter                : Sample(1),
      boloBidPriceLong                       : Sample(8),
      boloBidSize                            : Sample(2),
      boloBestAskMarketCenter                : Sample(1),
      boloAskPriceLong                       : Sample(8),
      boloAskSize                            : Sample(2),
      boloBestBidMarketParticipantIdentifier : Sample(4),
      boloBestAskMarketParticipantIdentifier : Sample(4) ]

EncodeBoloAppendageMpidForm3(message) ==
    message.boloBestBidMarketCenter
        \o message.boloBidPriceLong
        \o message.boloBidSize
        \o message.boloBestAskMarketCenter
        \o message.boloAskPriceLong
        \o message.boloAskSize
        \o message.boloBestBidMarketParticipantIdentifier
        \o message.boloBestAskMarketParticipantIdentifier

DecodeBoloAppendageMpidForm3(bytes) ==
    LET boloBestBidMarketCenter == ReadBytes(bytes, 1) IN IF ~boloBestBidMarketCenter.ok THEN Fail ELSE
    LET boloBidPriceLong == ReadBytes(boloBestBidMarketCenter.rest, 8) IN IF ~boloBidPriceLong.ok THEN Fail ELSE
    LET boloBidSize == ReadBytes(boloBidPriceLong.rest, 2) IN IF ~boloBidSize.ok THEN Fail ELSE
    LET boloBestAskMarketCenter == ReadBytes(boloBidSize.rest, 1) IN IF ~boloBestAskMarketCenter.ok THEN Fail ELSE
    LET boloAskPriceLong == ReadBytes(boloBestAskMarketCenter.rest, 8) IN IF ~boloAskPriceLong.ok THEN Fail ELSE
    LET boloAskSize == ReadBytes(boloAskPriceLong.rest, 2) IN IF ~boloAskSize.ok THEN Fail ELSE
    LET boloBestBidMarketParticipantIdentifier == ReadBytes(boloAskSize.rest, 4) IN IF ~boloBestBidMarketParticipantIdentifier.ok THEN Fail ELSE
    LET boloBestAskMarketParticipantIdentifier == ReadBytes(boloBestBidMarketParticipantIdentifier.rest, 4) IN IF ~boloBestAskMarketParticipantIdentifier.ok THEN Fail ELSE
    Ok([ boloBestBidMarketCenter                |-> boloBestBidMarketCenter.value,
         boloBidPriceLong                       |-> boloBidPriceLong.value,
         boloBidSize                            |-> boloBidSize.value,
         boloBestAskMarketCenter                |-> boloBestAskMarketCenter.value,
         boloAskPriceLong                       |-> boloAskPriceLong.value,
         boloAskSize                            |-> boloAskSize.value,
         boloBestBidMarketParticipantIdentifier |-> boloBestBidMarketParticipantIdentifier.value,
         boloBestAskMarketParticipantIdentifier |-> boloBestAskMarketParticipantIdentifier.value ], boloBestAskMarketParticipantIdentifier.rest)

ZeroBoloAppendageMpidForm3 ==
    [ boloBestBidMarketCenter                |-> [i \in 1 .. 1 |-> 0],
      boloBidPriceLong                       |-> [i \in 1 .. 8 |-> 0],
      boloBidSize                            |-> [i \in 1 .. 2 |-> 0],
      boloBestAskMarketCenter                |-> [i \in 1 .. 1 |-> 0],
      boloAskPriceLong                       |-> [i \in 1 .. 8 |-> 0],
      boloAskSize                            |-> [i \in 1 .. 2 |-> 0],
      boloBestBidMarketParticipantIdentifier |-> [i \in 1 .. 4 |-> 0],
      boloBestAskMarketParticipantIdentifier |-> [i \in 1 .. 4 |-> 0] ]

(* Bolo Appendage Mpid Form at zero, then each field in turn at the values it is checked at *)
CheckedBoloAppendageMpidForm3 ==
    { ZeroBoloAppendageMpidForm3 }
        \cup { [ZeroBoloAppendageMpidForm3 EXCEPT !.boloBestBidMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroBoloAppendageMpidForm3 EXCEPT !.boloBidPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroBoloAppendageMpidForm3 EXCEPT !.boloBidSize = one] : one \in Sample(2) }
        \cup { [ZeroBoloAppendageMpidForm3 EXCEPT !.boloBestAskMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroBoloAppendageMpidForm3 EXCEPT !.boloAskPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroBoloAppendageMpidForm3 EXCEPT !.boloAskSize = one] : one \in Sample(2) }
        \cup { [ZeroBoloAppendageMpidForm3 EXCEPT !.boloBestBidMarketParticipantIdentifier = one] : one \in Sample(4) }
        \cup { [ZeroBoloAppendageMpidForm3 EXCEPT !.boloBestAskMarketParticipantIdentifier = one] : one \in Sample(4) }

(***************************************************************************)
(* What Bolo Appendage Indicator decides is present                        *)
(***************************************************************************)

BoloAppendageShortFormCode3 == 50  \* "2"
BoloAppendageLongFormCode3 == 51  \* "3"
BoloAppendageMpidFormCode3 == 53  \* "5"
BoloAppendageIndicatorNoneCode3 == 0  \* 

BoloAppendageIndicatorChoice3 ==
    [ tag : {BoloAppendageShortFormCode3}, body : BoloAppendageShortForm3 ]
        \cup [ tag : {BoloAppendageLongFormCode3}, body : BoloAppendageLongForm3 ]
        \cup [ tag : {BoloAppendageMpidFormCode3}, body : BoloAppendageMpidForm3 ]
        \cup [ tag : {BoloAppendageIndicatorNoneCode3}, body : {[empty |-> 0]} ]

EncodeBoloAppendageIndicatorChoice3(message) ==
    CASE message.tag = BoloAppendageShortFormCode3 -> EncodeBoloAppendageShortForm3(message.body)
      [] message.tag = BoloAppendageLongFormCode3 -> EncodeBoloAppendageLongForm3(message.body)
      [] message.tag = BoloAppendageMpidFormCode3 -> EncodeBoloAppendageMpidForm3(message.body)
      [] OTHER -> << >>

DecodeBoloAppendageIndicatorChoice3(tag, bytes) ==
    LET read ==
            CASE tag = BoloAppendageShortFormCode3 -> DecodeBoloAppendageShortForm3(bytes)
              [] tag = BoloAppendageLongFormCode3 -> DecodeBoloAppendageLongForm3(bytes)
              [] tag = BoloAppendageMpidFormCode3 -> DecodeBoloAppendageMpidForm3(bytes)
              [] OTHER -> Ok([empty |-> 0], bytes)
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroBoloAppendageIndicatorChoice3 == [tag |-> BoloAppendageShortFormCode3, body |-> ZeroBoloAppendageShortForm3]

(* Each Bolo Appendage Indicator in turn, at the values the message it names is checked at *)
CheckedBoloAppendageIndicatorChoice3 ==
    { [tag |-> BoloAppendageShortFormCode3, body |-> one] : one \in CheckedBoloAppendageShortForm3 }
        \cup { [tag |-> BoloAppendageLongFormCode3, body |-> one] : one \in CheckedBoloAppendageLongForm3 }
        \cup { [tag |-> BoloAppendageMpidFormCode3, body |-> one] : one \in CheckedBoloAppendageMpidForm3 }
        \cup { [tag |-> BoloAppendageIndicatorNoneCode3, body |-> [empty |-> 0]] }

(***************************************************************************)
(* Odd Lot Quote Message Short Form Message                                *)
(***************************************************************************)

OddLotQuoteMessageShortFormMessage ==
    [ marketCenterOriginator       : Sample(1),
      subMarketCenterId            : Sample(1),
      sipTimestamp                 : Sample(8),
      timestamp1                   : Sample(8),
      participantToken             : Sample(8),
      symbolShort                  : Sample(5),
      sipGeneratedUpdateFlag       : Sample(1),
      oddLotAttachmentType         : Sample(1),
      oddLotAttachmentCount        : Sample(2),
      boloAppendageIndicatorChoice : BoloAppendageIndicatorChoice3 ]

EncodeOddLotQuoteMessageShortFormMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o message.symbolShort
        \o message.sipGeneratedUpdateFlag
        \o EncodeUIntBE(message.boloAppendageIndicatorChoice.tag, 1)
        \o message.oddLotAttachmentType
        \o message.oddLotAttachmentCount
        \o EncodeBoloAppendageIndicatorChoice3(message.boloAppendageIndicatorChoice)

DecodeOddLotQuoteMessageShortFormMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET symbolShort == ReadBytes(participantToken.rest, 5) IN IF ~symbolShort.ok THEN Fail ELSE
    LET sipGeneratedUpdateFlag == ReadBytes(symbolShort.rest, 1) IN IF ~sipGeneratedUpdateFlag.ok THEN Fail ELSE
    LET boloAppendageIndicator == ReadUIntBE(sipGeneratedUpdateFlag.rest, 1) IN IF ~boloAppendageIndicator.ok THEN Fail ELSE
    LET oddLotAttachmentType == ReadBytes(boloAppendageIndicator.rest, 1) IN IF ~oddLotAttachmentType.ok THEN Fail ELSE
    LET oddLotAttachmentCount == ReadBytes(oddLotAttachmentType.rest, 2) IN IF ~oddLotAttachmentCount.ok THEN Fail ELSE
    LET boloAppendageIndicatorChoice == DecodeBoloAppendageIndicatorChoice3(boloAppendageIndicator.value, oddLotAttachmentCount.rest) IN IF ~boloAppendageIndicatorChoice.ok THEN Fail ELSE
    Ok([ marketCenterOriginator       |-> marketCenterOriginator.value,
         subMarketCenterId            |-> subMarketCenterId.value,
         sipTimestamp                 |-> sipTimestamp.value,
         timestamp1                   |-> timestamp1.value,
         participantToken             |-> participantToken.value,
         symbolShort                  |-> symbolShort.value,
         sipGeneratedUpdateFlag       |-> sipGeneratedUpdateFlag.value,
         oddLotAttachmentType         |-> oddLotAttachmentType.value,
         oddLotAttachmentCount        |-> oddLotAttachmentCount.value,
         boloAppendageIndicatorChoice |-> boloAppendageIndicatorChoice.value ], boloAppendageIndicatorChoice.rest)

ZeroOddLotQuoteMessageShortFormMessage ==
    [ marketCenterOriginator       |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId            |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp                 |-> [i \in 1 .. 8 |-> 0],
      timestamp1                   |-> [i \in 1 .. 8 |-> 0],
      participantToken             |-> [i \in 1 .. 8 |-> 0],
      symbolShort                  |-> [i \in 1 .. 5 |-> 0],
      sipGeneratedUpdateFlag       |-> [i \in 1 .. 1 |-> 0],
      oddLotAttachmentType         |-> [i \in 1 .. 1 |-> 0],
      oddLotAttachmentCount        |-> [i \in 1 .. 2 |-> 0],
      boloAppendageIndicatorChoice |-> ZeroBoloAppendageIndicatorChoice3 ]

(* Odd Lot Quote Message Short Form Message at zero, then each field in turn at the values it is checked at *)
CheckedOddLotQuoteMessageShortFormMessage ==
    { ZeroOddLotQuoteMessageShortFormMessage }
        \cup { [ZeroOddLotQuoteMessageShortFormMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroOddLotQuoteMessageShortFormMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroOddLotQuoteMessageShortFormMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroOddLotQuoteMessageShortFormMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroOddLotQuoteMessageShortFormMessage EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroOddLotQuoteMessageShortFormMessage EXCEPT !.symbolShort = one] : one \in Sample(5) }
        \cup { [ZeroOddLotQuoteMessageShortFormMessage EXCEPT !.sipGeneratedUpdateFlag = one] : one \in Sample(1) }
        \cup { [ZeroOddLotQuoteMessageShortFormMessage EXCEPT !.oddLotAttachmentType = one] : one \in Sample(1) }
        \cup { [ZeroOddLotQuoteMessageShortFormMessage EXCEPT !.oddLotAttachmentCount = one] : one \in Sample(2) }
        \cup { [ZeroOddLotQuoteMessageShortFormMessage EXCEPT !.boloAppendageIndicatorChoice = one] : one \in CheckedBoloAppendageIndicatorChoice3 }

(***************************************************************************)
(* Bolo Appendage Short Form: 10 bytes                                     *)
(***************************************************************************)

BoloAppendageShortForm4 ==
    [ boloBestBidMarketCenter : Sample(1),
      boloBidPriceShort       : Sample(2),
      boloBidSize             : Sample(2),
      boloBestAskMarketCenter : Sample(1),
      boloAskPriceShort       : Sample(2),
      boloAskSize             : Sample(2) ]

EncodeBoloAppendageShortForm4(message) ==
    message.boloBestBidMarketCenter
        \o message.boloBidPriceShort
        \o message.boloBidSize
        \o message.boloBestAskMarketCenter
        \o message.boloAskPriceShort
        \o message.boloAskSize

DecodeBoloAppendageShortForm4(bytes) ==
    LET boloBestBidMarketCenter == ReadBytes(bytes, 1) IN IF ~boloBestBidMarketCenter.ok THEN Fail ELSE
    LET boloBidPriceShort == ReadBytes(boloBestBidMarketCenter.rest, 2) IN IF ~boloBidPriceShort.ok THEN Fail ELSE
    LET boloBidSize == ReadBytes(boloBidPriceShort.rest, 2) IN IF ~boloBidSize.ok THEN Fail ELSE
    LET boloBestAskMarketCenter == ReadBytes(boloBidSize.rest, 1) IN IF ~boloBestAskMarketCenter.ok THEN Fail ELSE
    LET boloAskPriceShort == ReadBytes(boloBestAskMarketCenter.rest, 2) IN IF ~boloAskPriceShort.ok THEN Fail ELSE
    LET boloAskSize == ReadBytes(boloAskPriceShort.rest, 2) IN IF ~boloAskSize.ok THEN Fail ELSE
    Ok([ boloBestBidMarketCenter |-> boloBestBidMarketCenter.value,
         boloBidPriceShort       |-> boloBidPriceShort.value,
         boloBidSize             |-> boloBidSize.value,
         boloBestAskMarketCenter |-> boloBestAskMarketCenter.value,
         boloAskPriceShort       |-> boloAskPriceShort.value,
         boloAskSize             |-> boloAskSize.value ], boloAskSize.rest)

ZeroBoloAppendageShortForm4 ==
    [ boloBestBidMarketCenter |-> [i \in 1 .. 1 |-> 0],
      boloBidPriceShort       |-> [i \in 1 .. 2 |-> 0],
      boloBidSize             |-> [i \in 1 .. 2 |-> 0],
      boloBestAskMarketCenter |-> [i \in 1 .. 1 |-> 0],
      boloAskPriceShort       |-> [i \in 1 .. 2 |-> 0],
      boloAskSize             |-> [i \in 1 .. 2 |-> 0] ]

(* Bolo Appendage Short Form at zero, then each field in turn at the values it is checked at *)
CheckedBoloAppendageShortForm4 ==
    { ZeroBoloAppendageShortForm4 }
        \cup { [ZeroBoloAppendageShortForm4 EXCEPT !.boloBestBidMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroBoloAppendageShortForm4 EXCEPT !.boloBidPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroBoloAppendageShortForm4 EXCEPT !.boloBidSize = one] : one \in Sample(2) }
        \cup { [ZeroBoloAppendageShortForm4 EXCEPT !.boloBestAskMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroBoloAppendageShortForm4 EXCEPT !.boloAskPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroBoloAppendageShortForm4 EXCEPT !.boloAskSize = one] : one \in Sample(2) }

(***************************************************************************)
(* Bolo Appendage Long Form: 22 bytes                                      *)
(***************************************************************************)

BoloAppendageLongForm4 ==
    [ boloBestBidMarketCenter : Sample(1),
      boloBidPriceLong        : Sample(8),
      boloBidSize             : Sample(2),
      boloBestAskMarketCenter : Sample(1),
      boloAskPriceLong        : Sample(8),
      boloAskSize             : Sample(2) ]

EncodeBoloAppendageLongForm4(message) ==
    message.boloBestBidMarketCenter
        \o message.boloBidPriceLong
        \o message.boloBidSize
        \o message.boloBestAskMarketCenter
        \o message.boloAskPriceLong
        \o message.boloAskSize

DecodeBoloAppendageLongForm4(bytes) ==
    LET boloBestBidMarketCenter == ReadBytes(bytes, 1) IN IF ~boloBestBidMarketCenter.ok THEN Fail ELSE
    LET boloBidPriceLong == ReadBytes(boloBestBidMarketCenter.rest, 8) IN IF ~boloBidPriceLong.ok THEN Fail ELSE
    LET boloBidSize == ReadBytes(boloBidPriceLong.rest, 2) IN IF ~boloBidSize.ok THEN Fail ELSE
    LET boloBestAskMarketCenter == ReadBytes(boloBidSize.rest, 1) IN IF ~boloBestAskMarketCenter.ok THEN Fail ELSE
    LET boloAskPriceLong == ReadBytes(boloBestAskMarketCenter.rest, 8) IN IF ~boloAskPriceLong.ok THEN Fail ELSE
    LET boloAskSize == ReadBytes(boloAskPriceLong.rest, 2) IN IF ~boloAskSize.ok THEN Fail ELSE
    Ok([ boloBestBidMarketCenter |-> boloBestBidMarketCenter.value,
         boloBidPriceLong        |-> boloBidPriceLong.value,
         boloBidSize             |-> boloBidSize.value,
         boloBestAskMarketCenter |-> boloBestAskMarketCenter.value,
         boloAskPriceLong        |-> boloAskPriceLong.value,
         boloAskSize             |-> boloAskSize.value ], boloAskSize.rest)

ZeroBoloAppendageLongForm4 ==
    [ boloBestBidMarketCenter |-> [i \in 1 .. 1 |-> 0],
      boloBidPriceLong        |-> [i \in 1 .. 8 |-> 0],
      boloBidSize             |-> [i \in 1 .. 2 |-> 0],
      boloBestAskMarketCenter |-> [i \in 1 .. 1 |-> 0],
      boloAskPriceLong        |-> [i \in 1 .. 8 |-> 0],
      boloAskSize             |-> [i \in 1 .. 2 |-> 0] ]

(* Bolo Appendage Long Form at zero, then each field in turn at the values it is checked at *)
CheckedBoloAppendageLongForm4 ==
    { ZeroBoloAppendageLongForm4 }
        \cup { [ZeroBoloAppendageLongForm4 EXCEPT !.boloBestBidMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroBoloAppendageLongForm4 EXCEPT !.boloBidPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroBoloAppendageLongForm4 EXCEPT !.boloBidSize = one] : one \in Sample(2) }
        \cup { [ZeroBoloAppendageLongForm4 EXCEPT !.boloBestAskMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroBoloAppendageLongForm4 EXCEPT !.boloAskPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroBoloAppendageLongForm4 EXCEPT !.boloAskSize = one] : one \in Sample(2) }

(***************************************************************************)
(* Bolo Appendage Mpid Form: 30 bytes                                      *)
(***************************************************************************)

BoloAppendageMpidForm4 ==
    [ boloBestBidMarketCenter                : Sample(1),
      boloBidPriceLong                       : Sample(8),
      boloBidSize                            : Sample(2),
      boloBestAskMarketCenter                : Sample(1),
      boloAskPriceLong                       : Sample(8),
      boloAskSize                            : Sample(2),
      boloBestBidMarketParticipantIdentifier : Sample(4),
      boloBestAskMarketParticipantIdentifier : Sample(4) ]

EncodeBoloAppendageMpidForm4(message) ==
    message.boloBestBidMarketCenter
        \o message.boloBidPriceLong
        \o message.boloBidSize
        \o message.boloBestAskMarketCenter
        \o message.boloAskPriceLong
        \o message.boloAskSize
        \o message.boloBestBidMarketParticipantIdentifier
        \o message.boloBestAskMarketParticipantIdentifier

DecodeBoloAppendageMpidForm4(bytes) ==
    LET boloBestBidMarketCenter == ReadBytes(bytes, 1) IN IF ~boloBestBidMarketCenter.ok THEN Fail ELSE
    LET boloBidPriceLong == ReadBytes(boloBestBidMarketCenter.rest, 8) IN IF ~boloBidPriceLong.ok THEN Fail ELSE
    LET boloBidSize == ReadBytes(boloBidPriceLong.rest, 2) IN IF ~boloBidSize.ok THEN Fail ELSE
    LET boloBestAskMarketCenter == ReadBytes(boloBidSize.rest, 1) IN IF ~boloBestAskMarketCenter.ok THEN Fail ELSE
    LET boloAskPriceLong == ReadBytes(boloBestAskMarketCenter.rest, 8) IN IF ~boloAskPriceLong.ok THEN Fail ELSE
    LET boloAskSize == ReadBytes(boloAskPriceLong.rest, 2) IN IF ~boloAskSize.ok THEN Fail ELSE
    LET boloBestBidMarketParticipantIdentifier == ReadBytes(boloAskSize.rest, 4) IN IF ~boloBestBidMarketParticipantIdentifier.ok THEN Fail ELSE
    LET boloBestAskMarketParticipantIdentifier == ReadBytes(boloBestBidMarketParticipantIdentifier.rest, 4) IN IF ~boloBestAskMarketParticipantIdentifier.ok THEN Fail ELSE
    Ok([ boloBestBidMarketCenter                |-> boloBestBidMarketCenter.value,
         boloBidPriceLong                       |-> boloBidPriceLong.value,
         boloBidSize                            |-> boloBidSize.value,
         boloBestAskMarketCenter                |-> boloBestAskMarketCenter.value,
         boloAskPriceLong                       |-> boloAskPriceLong.value,
         boloAskSize                            |-> boloAskSize.value,
         boloBestBidMarketParticipantIdentifier |-> boloBestBidMarketParticipantIdentifier.value,
         boloBestAskMarketParticipantIdentifier |-> boloBestAskMarketParticipantIdentifier.value ], boloBestAskMarketParticipantIdentifier.rest)

ZeroBoloAppendageMpidForm4 ==
    [ boloBestBidMarketCenter                |-> [i \in 1 .. 1 |-> 0],
      boloBidPriceLong                       |-> [i \in 1 .. 8 |-> 0],
      boloBidSize                            |-> [i \in 1 .. 2 |-> 0],
      boloBestAskMarketCenter                |-> [i \in 1 .. 1 |-> 0],
      boloAskPriceLong                       |-> [i \in 1 .. 8 |-> 0],
      boloAskSize                            |-> [i \in 1 .. 2 |-> 0],
      boloBestBidMarketParticipantIdentifier |-> [i \in 1 .. 4 |-> 0],
      boloBestAskMarketParticipantIdentifier |-> [i \in 1 .. 4 |-> 0] ]

(* Bolo Appendage Mpid Form at zero, then each field in turn at the values it is checked at *)
CheckedBoloAppendageMpidForm4 ==
    { ZeroBoloAppendageMpidForm4 }
        \cup { [ZeroBoloAppendageMpidForm4 EXCEPT !.boloBestBidMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroBoloAppendageMpidForm4 EXCEPT !.boloBidPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroBoloAppendageMpidForm4 EXCEPT !.boloBidSize = one] : one \in Sample(2) }
        \cup { [ZeroBoloAppendageMpidForm4 EXCEPT !.boloBestAskMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroBoloAppendageMpidForm4 EXCEPT !.boloAskPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroBoloAppendageMpidForm4 EXCEPT !.boloAskSize = one] : one \in Sample(2) }
        \cup { [ZeroBoloAppendageMpidForm4 EXCEPT !.boloBestBidMarketParticipantIdentifier = one] : one \in Sample(4) }
        \cup { [ZeroBoloAppendageMpidForm4 EXCEPT !.boloBestAskMarketParticipantIdentifier = one] : one \in Sample(4) }

(***************************************************************************)
(* What Bolo Appendage Indicator decides is present                        *)
(***************************************************************************)

BoloAppendageShortFormCode4 == 50  \* "2"
BoloAppendageLongFormCode4 == 51  \* "3"
BoloAppendageMpidFormCode4 == 53  \* "5"
BoloAppendageIndicatorNoneCode4 == 0  \* 

BoloAppendageIndicatorChoice4 ==
    [ tag : {BoloAppendageShortFormCode4}, body : BoloAppendageShortForm4 ]
        \cup [ tag : {BoloAppendageLongFormCode4}, body : BoloAppendageLongForm4 ]
        \cup [ tag : {BoloAppendageMpidFormCode4}, body : BoloAppendageMpidForm4 ]
        \cup [ tag : {BoloAppendageIndicatorNoneCode4}, body : {[empty |-> 0]} ]

EncodeBoloAppendageIndicatorChoice4(message) ==
    CASE message.tag = BoloAppendageShortFormCode4 -> EncodeBoloAppendageShortForm4(message.body)
      [] message.tag = BoloAppendageLongFormCode4 -> EncodeBoloAppendageLongForm4(message.body)
      [] message.tag = BoloAppendageMpidFormCode4 -> EncodeBoloAppendageMpidForm4(message.body)
      [] OTHER -> << >>

DecodeBoloAppendageIndicatorChoice4(tag, bytes) ==
    LET read ==
            CASE tag = BoloAppendageShortFormCode4 -> DecodeBoloAppendageShortForm4(bytes)
              [] tag = BoloAppendageLongFormCode4 -> DecodeBoloAppendageLongForm4(bytes)
              [] tag = BoloAppendageMpidFormCode4 -> DecodeBoloAppendageMpidForm4(bytes)
              [] OTHER -> Ok([empty |-> 0], bytes)
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroBoloAppendageIndicatorChoice4 == [tag |-> BoloAppendageShortFormCode4, body |-> ZeroBoloAppendageShortForm4]

(* Each Bolo Appendage Indicator in turn, at the values the message it names is checked at *)
CheckedBoloAppendageIndicatorChoice4 ==
    { [tag |-> BoloAppendageShortFormCode4, body |-> one] : one \in CheckedBoloAppendageShortForm4 }
        \cup { [tag |-> BoloAppendageLongFormCode4, body |-> one] : one \in CheckedBoloAppendageLongForm4 }
        \cup { [tag |-> BoloAppendageMpidFormCode4, body |-> one] : one \in CheckedBoloAppendageMpidForm4 }
        \cup { [tag |-> BoloAppendageIndicatorNoneCode4, body |-> [empty |-> 0]] }

(***************************************************************************)
(* Odd Lot Quote Message Long Form Message                                 *)
(***************************************************************************)

OddLotQuoteMessageLongFormMessage ==
    [ marketCenterOriginator       : Sample(1),
      subMarketCenterId            : Sample(1),
      sipTimestamp                 : Sample(8),
      timestamp1                   : Sample(8),
      participantToken             : Sample(8),
      adfTimestamp                 : Sample(8),
      symbolLong                   : Sample(11),
      sipGeneratedUpdateFlag       : Sample(1),
      oddLotAttachmentType         : Sample(1),
      oddLotAttachmentCount        : Sample(2),
      boloAppendageIndicatorChoice : BoloAppendageIndicatorChoice4 ]

EncodeOddLotQuoteMessageLongFormMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o message.adfTimestamp
        \o message.symbolLong
        \o message.sipGeneratedUpdateFlag
        \o EncodeUIntBE(message.boloAppendageIndicatorChoice.tag, 1)
        \o message.oddLotAttachmentType
        \o message.oddLotAttachmentCount
        \o EncodeBoloAppendageIndicatorChoice4(message.boloAppendageIndicatorChoice)

DecodeOddLotQuoteMessageLongFormMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET adfTimestamp == ReadBytes(participantToken.rest, 8) IN IF ~adfTimestamp.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(adfTimestamp.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET sipGeneratedUpdateFlag == ReadBytes(symbolLong.rest, 1) IN IF ~sipGeneratedUpdateFlag.ok THEN Fail ELSE
    LET boloAppendageIndicator == ReadUIntBE(sipGeneratedUpdateFlag.rest, 1) IN IF ~boloAppendageIndicator.ok THEN Fail ELSE
    LET oddLotAttachmentType == ReadBytes(boloAppendageIndicator.rest, 1) IN IF ~oddLotAttachmentType.ok THEN Fail ELSE
    LET oddLotAttachmentCount == ReadBytes(oddLotAttachmentType.rest, 2) IN IF ~oddLotAttachmentCount.ok THEN Fail ELSE
    LET boloAppendageIndicatorChoice == DecodeBoloAppendageIndicatorChoice4(boloAppendageIndicator.value, oddLotAttachmentCount.rest) IN IF ~boloAppendageIndicatorChoice.ok THEN Fail ELSE
    Ok([ marketCenterOriginator       |-> marketCenterOriginator.value,
         subMarketCenterId            |-> subMarketCenterId.value,
         sipTimestamp                 |-> sipTimestamp.value,
         timestamp1                   |-> timestamp1.value,
         participantToken             |-> participantToken.value,
         adfTimestamp                 |-> adfTimestamp.value,
         symbolLong                   |-> symbolLong.value,
         sipGeneratedUpdateFlag       |-> sipGeneratedUpdateFlag.value,
         oddLotAttachmentType         |-> oddLotAttachmentType.value,
         oddLotAttachmentCount        |-> oddLotAttachmentCount.value,
         boloAppendageIndicatorChoice |-> boloAppendageIndicatorChoice.value ], boloAppendageIndicatorChoice.rest)

ZeroOddLotQuoteMessageLongFormMessage ==
    [ marketCenterOriginator       |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId            |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp                 |-> [i \in 1 .. 8 |-> 0],
      timestamp1                   |-> [i \in 1 .. 8 |-> 0],
      participantToken             |-> [i \in 1 .. 8 |-> 0],
      adfTimestamp                 |-> [i \in 1 .. 8 |-> 0],
      symbolLong                   |-> [i \in 1 .. 11 |-> 0],
      sipGeneratedUpdateFlag       |-> [i \in 1 .. 1 |-> 0],
      oddLotAttachmentType         |-> [i \in 1 .. 1 |-> 0],
      oddLotAttachmentCount        |-> [i \in 1 .. 2 |-> 0],
      boloAppendageIndicatorChoice |-> ZeroBoloAppendageIndicatorChoice4 ]

(* Odd Lot Quote Message Long Form Message at zero, then each field in turn at the values it is checked at *)
CheckedOddLotQuoteMessageLongFormMessage ==
    { ZeroOddLotQuoteMessageLongFormMessage }
        \cup { [ZeroOddLotQuoteMessageLongFormMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroOddLotQuoteMessageLongFormMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroOddLotQuoteMessageLongFormMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroOddLotQuoteMessageLongFormMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroOddLotQuoteMessageLongFormMessage EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroOddLotQuoteMessageLongFormMessage EXCEPT !.adfTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroOddLotQuoteMessageLongFormMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroOddLotQuoteMessageLongFormMessage EXCEPT !.sipGeneratedUpdateFlag = one] : one \in Sample(1) }
        \cup { [ZeroOddLotQuoteMessageLongFormMessage EXCEPT !.oddLotAttachmentType = one] : one \in Sample(1) }
        \cup { [ZeroOddLotQuoteMessageLongFormMessage EXCEPT !.oddLotAttachmentCount = one] : one \in Sample(2) }
        \cup { [ZeroOddLotQuoteMessageLongFormMessage EXCEPT !.boloAppendageIndicatorChoice = one] : one \in CheckedBoloAppendageIndicatorChoice4 }

(***************************************************************************)
(* Quote Message Payload, selected by Quote Message Type                   *)
(***************************************************************************)

UtpQuoteShortformMessageCode == 69  \* "E"
UtpQuoteLongformMessageCode == 70  \* "F"
FinraAdfMarketParticipantQuotationMessageCode == 77  \* "M"
CombinedQuoteMessageShortFormMessageCode == 67  \* "C"
CombinedQuoteMessageLongFormMessageCode == 68  \* "D"
OddLotQuoteMessageShortFormMessageCode == 65  \* "A"
OddLotQuoteMessageLongFormMessageCode == 66  \* "B"

QuoteMessagePayload ==
    [ tag : {UtpQuoteShortformMessageCode}, body : UtpQuoteShortformMessage ]
        \cup [ tag : {UtpQuoteLongformMessageCode}, body : UtpQuoteLongformMessage ]
        \cup [ tag : {FinraAdfMarketParticipantQuotationMessageCode}, body : FinraAdfMarketParticipantQuotationMessage ]
        \cup [ tag : {CombinedQuoteMessageShortFormMessageCode}, body : CombinedQuoteMessageShortFormMessage ]
        \cup [ tag : {CombinedQuoteMessageLongFormMessageCode}, body : CombinedQuoteMessageLongFormMessage ]
        \cup [ tag : {OddLotQuoteMessageShortFormMessageCode}, body : OddLotQuoteMessageShortFormMessage ]
        \cup [ tag : {OddLotQuoteMessageLongFormMessageCode}, body : OddLotQuoteMessageLongFormMessage ]

EncodeQuoteMessagePayload(message) ==
    CASE message.tag = UtpQuoteShortformMessageCode -> EncodeUtpQuoteShortformMessage(message.body)
      [] message.tag = UtpQuoteLongformMessageCode -> EncodeUtpQuoteLongformMessage(message.body)
      [] message.tag = FinraAdfMarketParticipantQuotationMessageCode -> EncodeFinraAdfMarketParticipantQuotationMessage(message.body)
      [] message.tag = CombinedQuoteMessageShortFormMessageCode -> EncodeCombinedQuoteMessageShortFormMessage(message.body)
      [] message.tag = CombinedQuoteMessageLongFormMessageCode -> EncodeCombinedQuoteMessageLongFormMessage(message.body)
      [] message.tag = OddLotQuoteMessageShortFormMessageCode -> EncodeOddLotQuoteMessageShortFormMessage(message.body)
      [] message.tag = OddLotQuoteMessageLongFormMessageCode -> EncodeOddLotQuoteMessageLongFormMessage(message.body)

DecodeQuoteMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = UtpQuoteShortformMessageCode -> DecodeUtpQuoteShortformMessage(bytes)
              [] tag = UtpQuoteLongformMessageCode -> DecodeUtpQuoteLongformMessage(bytes)
              [] tag = FinraAdfMarketParticipantQuotationMessageCode -> DecodeFinraAdfMarketParticipantQuotationMessage(bytes)
              [] tag = CombinedQuoteMessageShortFormMessageCode -> DecodeCombinedQuoteMessageShortFormMessage(bytes)
              [] tag = CombinedQuoteMessageLongFormMessageCode -> DecodeCombinedQuoteMessageLongFormMessage(bytes)
              [] tag = OddLotQuoteMessageShortFormMessageCode -> DecodeOddLotQuoteMessageShortFormMessage(bytes)
              [] tag = OddLotQuoteMessageLongFormMessageCode -> DecodeOddLotQuoteMessageLongFormMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroQuoteMessagePayload == [tag |-> UtpQuoteShortformMessageCode, body |-> ZeroUtpQuoteShortformMessage]

(* Each Quote Message Payload in turn, at the values the message it names is checked at *)
CheckedQuoteMessagePayload ==
    { [tag |-> UtpQuoteShortformMessageCode, body |-> one] : one \in CheckedUtpQuoteShortformMessage }
        \cup { [tag |-> UtpQuoteLongformMessageCode, body |-> one] : one \in CheckedUtpQuoteLongformMessage }
        \cup { [tag |-> FinraAdfMarketParticipantQuotationMessageCode, body |-> one] : one \in CheckedFinraAdfMarketParticipantQuotationMessage }
        \cup { [tag |-> CombinedQuoteMessageShortFormMessageCode, body |-> one] : one \in CheckedCombinedQuoteMessageShortFormMessage }
        \cup { [tag |-> CombinedQuoteMessageLongFormMessageCode, body |-> one] : one \in CheckedCombinedQuoteMessageLongFormMessage }
        \cup { [tag |-> OddLotQuoteMessageShortFormMessageCode, body |-> one] : one \in CheckedOddLotQuoteMessageShortFormMessage }
        \cup { [tag |-> OddLotQuoteMessageLongFormMessageCode, body |-> one] : one \in CheckedOddLotQuoteMessageLongFormMessage }

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
(* General Administrative Message                                          *)
(***************************************************************************)

GeneralAdministrativeMessage ==
    [ marketCenterOriginator : Sample(1),
      subMarketCenterId      : Sample(1),
      sipTimestamp           : Sample(8),
      timestamp1             : Sample(8),
      participantToken       : Sample(8),
      text                   : SampleBytes ]

EncodeGeneralAdministrativeMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o EncodeUIntBE(Len(message.text), 2)
        \o message.text

DecodeGeneralAdministrativeMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET textLength == ReadUIntBE(participantToken.rest, 2) IN IF ~textLength.ok THEN Fail ELSE
    LET text == ReadBytes(textLength.rest, textLength.value) IN IF ~text.ok THEN Fail ELSE
    Ok([ marketCenterOriginator |-> marketCenterOriginator.value,
         subMarketCenterId      |-> subMarketCenterId.value,
         sipTimestamp           |-> sipTimestamp.value,
         timestamp1             |-> timestamp1.value,
         participantToken       |-> participantToken.value,
         text                   |-> text.value ], text.rest)

ZeroGeneralAdministrativeMessage ==
    [ marketCenterOriginator |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId      |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp           |-> [i \in 1 .. 8 |-> 0],
      timestamp1             |-> [i \in 1 .. 8 |-> 0],
      participantToken       |-> [i \in 1 .. 8 |-> 0],
      text                   |-> << >> ]

(* General Administrative Message at zero, then each field in turn at the values it is checked at *)
CheckedGeneralAdministrativeMessage ==
    { ZeroGeneralAdministrativeMessage }
        \cup { [ZeroGeneralAdministrativeMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroGeneralAdministrativeMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroGeneralAdministrativeMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroGeneralAdministrativeMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroGeneralAdministrativeMessage EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroGeneralAdministrativeMessage EXCEPT !.text = one] : one \in SampleBytes }

(***************************************************************************)
(* Cross Sro Trading Action Message: 56 bytes                              *)
(***************************************************************************)

CrossSroTradingActionMessage ==
    [ marketCenterOriginator      : Sample(1),
      subMarketCenterId           : Sample(1),
      sipTimestamp                : Sample(8),
      timestamp1                  : Sample(8),
      participantToken            : Sample(8),
      symbolLong                  : Sample(11),
      tradingActionCode           : Sample(1),
      tradingActionSequenceNumber : Sample(4),
      actionTime                  : Sample(8),
      reasonForTheTradingAction   : Sample(6) ]

EncodeCrossSroTradingActionMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o message.symbolLong
        \o message.tradingActionCode
        \o message.tradingActionSequenceNumber
        \o message.actionTime
        \o message.reasonForTheTradingAction

DecodeCrossSroTradingActionMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(participantToken.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET tradingActionCode == ReadBytes(symbolLong.rest, 1) IN IF ~tradingActionCode.ok THEN Fail ELSE
    LET tradingActionSequenceNumber == ReadBytes(tradingActionCode.rest, 4) IN IF ~tradingActionSequenceNumber.ok THEN Fail ELSE
    LET actionTime == ReadBytes(tradingActionSequenceNumber.rest, 8) IN IF ~actionTime.ok THEN Fail ELSE
    LET reasonForTheTradingAction == ReadBytes(actionTime.rest, 6) IN IF ~reasonForTheTradingAction.ok THEN Fail ELSE
    Ok([ marketCenterOriginator      |-> marketCenterOriginator.value,
         subMarketCenterId           |-> subMarketCenterId.value,
         sipTimestamp                |-> sipTimestamp.value,
         timestamp1                  |-> timestamp1.value,
         participantToken            |-> participantToken.value,
         symbolLong                  |-> symbolLong.value,
         tradingActionCode           |-> tradingActionCode.value,
         tradingActionSequenceNumber |-> tradingActionSequenceNumber.value,
         actionTime                  |-> actionTime.value,
         reasonForTheTradingAction   |-> reasonForTheTradingAction.value ], reasonForTheTradingAction.rest)

ZeroCrossSroTradingActionMessage ==
    [ marketCenterOriginator      |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId           |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp                |-> [i \in 1 .. 8 |-> 0],
      timestamp1                  |-> [i \in 1 .. 8 |-> 0],
      participantToken            |-> [i \in 1 .. 8 |-> 0],
      symbolLong                  |-> [i \in 1 .. 11 |-> 0],
      tradingActionCode           |-> [i \in 1 .. 1 |-> 0],
      tradingActionSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      actionTime                  |-> [i \in 1 .. 8 |-> 0],
      reasonForTheTradingAction   |-> [i \in 1 .. 6 |-> 0] ]

(* Cross Sro Trading Action Message at zero, then each field in turn at the values it is checked at *)
CheckedCrossSroTradingActionMessage ==
    { ZeroCrossSroTradingActionMessage }
        \cup { [ZeroCrossSroTradingActionMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroCrossSroTradingActionMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroCrossSroTradingActionMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroCrossSroTradingActionMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroCrossSroTradingActionMessage EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroCrossSroTradingActionMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroCrossSroTradingActionMessage EXCEPT !.tradingActionCode = one] : one \in Sample(1) }
        \cup { [ZeroCrossSroTradingActionMessage EXCEPT !.tradingActionSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroCrossSroTradingActionMessage EXCEPT !.actionTime = one] : one \in Sample(8) }
        \cup { [ZeroCrossSroTradingActionMessage EXCEPT !.reasonForTheTradingAction = one] : one \in Sample(6) }

(***************************************************************************)
(* Market Center Trading Action Message: 47 bytes                          *)
(***************************************************************************)

MarketCenterTradingActionMessage ==
    [ marketCenterOriginator : Sample(1),
      subMarketCenterId      : Sample(1),
      sipTimestamp           : Sample(8),
      timestamp1             : Sample(8),
      participantToken       : Sample(8),
      symbolLong             : Sample(11),
      tradingActionCode      : Sample(1),
      actionTime             : Sample(8),
      marketCenterIdentifier : Sample(1) ]

EncodeMarketCenterTradingActionMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o message.symbolLong
        \o message.tradingActionCode
        \o message.actionTime
        \o message.marketCenterIdentifier

DecodeMarketCenterTradingActionMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(participantToken.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET tradingActionCode == ReadBytes(symbolLong.rest, 1) IN IF ~tradingActionCode.ok THEN Fail ELSE
    LET actionTime == ReadBytes(tradingActionCode.rest, 8) IN IF ~actionTime.ok THEN Fail ELSE
    LET marketCenterIdentifier == ReadBytes(actionTime.rest, 1) IN IF ~marketCenterIdentifier.ok THEN Fail ELSE
    Ok([ marketCenterOriginator |-> marketCenterOriginator.value,
         subMarketCenterId      |-> subMarketCenterId.value,
         sipTimestamp           |-> sipTimestamp.value,
         timestamp1             |-> timestamp1.value,
         participantToken       |-> participantToken.value,
         symbolLong             |-> symbolLong.value,
         tradingActionCode      |-> tradingActionCode.value,
         actionTime             |-> actionTime.value,
         marketCenterIdentifier |-> marketCenterIdentifier.value ], marketCenterIdentifier.rest)

ZeroMarketCenterTradingActionMessage ==
    [ marketCenterOriginator |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId      |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp           |-> [i \in 1 .. 8 |-> 0],
      timestamp1             |-> [i \in 1 .. 8 |-> 0],
      participantToken       |-> [i \in 1 .. 8 |-> 0],
      symbolLong             |-> [i \in 1 .. 11 |-> 0],
      tradingActionCode      |-> [i \in 1 .. 1 |-> 0],
      actionTime             |-> [i \in 1 .. 8 |-> 0],
      marketCenterIdentifier |-> [i \in 1 .. 1 |-> 0] ]

(* Market Center Trading Action Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketCenterTradingActionMessage ==
    { ZeroMarketCenterTradingActionMessage }
        \cup { [ZeroMarketCenterTradingActionMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroMarketCenterTradingActionMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMarketCenterTradingActionMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMarketCenterTradingActionMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroMarketCenterTradingActionMessage EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroMarketCenterTradingActionMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroMarketCenterTradingActionMessage EXCEPT !.tradingActionCode = one] : one \in Sample(1) }
        \cup { [ZeroMarketCenterTradingActionMessage EXCEPT !.actionTime = one] : one \in Sample(8) }
        \cup { [ZeroMarketCenterTradingActionMessage EXCEPT !.marketCenterIdentifier = one] : one \in Sample(1) }

(***************************************************************************)
(* Issue Symbol Directory Message: 87 bytes                                *)
(***************************************************************************)

IssueSymbolDirectoryMessage ==
    [ marketCenterOriginator      : Sample(1),
      subMarketCenterId           : Sample(1),
      sipTimestamp                : Sample(8),
      timestamp1                  : Sample(8),
      participantToken            : Sample(8),
      symbolLong                  : Sample(11),
      oldSymbol                   : Sample(11),
      issueName                   : Sample(30),
      issueType                   : Sample(1),
      issueSubtype                : Sample(2),
      marketTier                  : Sample(1),
      authenticity                : Sample(1),
      shortSaleThresholdIndicator : Sample(1),
      roundLotSize                : Sample(2),
      financialStatusIndicator    : Sample(1) ]

EncodeIssueSymbolDirectoryMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o message.symbolLong
        \o message.oldSymbol
        \o message.issueName
        \o message.issueType
        \o message.issueSubtype
        \o message.marketTier
        \o message.authenticity
        \o message.shortSaleThresholdIndicator
        \o message.roundLotSize
        \o message.financialStatusIndicator

DecodeIssueSymbolDirectoryMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(participantToken.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET oldSymbol == ReadBytes(symbolLong.rest, 11) IN IF ~oldSymbol.ok THEN Fail ELSE
    LET issueName == ReadBytes(oldSymbol.rest, 30) IN IF ~issueName.ok THEN Fail ELSE
    LET issueType == ReadBytes(issueName.rest, 1) IN IF ~issueType.ok THEN Fail ELSE
    LET issueSubtype == ReadBytes(issueType.rest, 2) IN IF ~issueSubtype.ok THEN Fail ELSE
    LET marketTier == ReadBytes(issueSubtype.rest, 1) IN IF ~marketTier.ok THEN Fail ELSE
    LET authenticity == ReadBytes(marketTier.rest, 1) IN IF ~authenticity.ok THEN Fail ELSE
    LET shortSaleThresholdIndicator == ReadBytes(authenticity.rest, 1) IN IF ~shortSaleThresholdIndicator.ok THEN Fail ELSE
    LET roundLotSize == ReadBytes(shortSaleThresholdIndicator.rest, 2) IN IF ~roundLotSize.ok THEN Fail ELSE
    LET financialStatusIndicator == ReadBytes(roundLotSize.rest, 1) IN IF ~financialStatusIndicator.ok THEN Fail ELSE
    Ok([ marketCenterOriginator      |-> marketCenterOriginator.value,
         subMarketCenterId           |-> subMarketCenterId.value,
         sipTimestamp                |-> sipTimestamp.value,
         timestamp1                  |-> timestamp1.value,
         participantToken            |-> participantToken.value,
         symbolLong                  |-> symbolLong.value,
         oldSymbol                   |-> oldSymbol.value,
         issueName                   |-> issueName.value,
         issueType                   |-> issueType.value,
         issueSubtype                |-> issueSubtype.value,
         marketTier                  |-> marketTier.value,
         authenticity                |-> authenticity.value,
         shortSaleThresholdIndicator |-> shortSaleThresholdIndicator.value,
         roundLotSize                |-> roundLotSize.value,
         financialStatusIndicator    |-> financialStatusIndicator.value ], financialStatusIndicator.rest)

ZeroIssueSymbolDirectoryMessage ==
    [ marketCenterOriginator      |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId           |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp                |-> [i \in 1 .. 8 |-> 0],
      timestamp1                  |-> [i \in 1 .. 8 |-> 0],
      participantToken            |-> [i \in 1 .. 8 |-> 0],
      symbolLong                  |-> [i \in 1 .. 11 |-> 0],
      oldSymbol                   |-> [i \in 1 .. 11 |-> 0],
      issueName                   |-> [i \in 1 .. 30 |-> 0],
      issueType                   |-> [i \in 1 .. 1 |-> 0],
      issueSubtype                |-> [i \in 1 .. 2 |-> 0],
      marketTier                  |-> [i \in 1 .. 1 |-> 0],
      authenticity                |-> [i \in 1 .. 1 |-> 0],
      shortSaleThresholdIndicator |-> [i \in 1 .. 1 |-> 0],
      roundLotSize                |-> [i \in 1 .. 2 |-> 0],
      financialStatusIndicator    |-> [i \in 1 .. 1 |-> 0] ]

(* Issue Symbol Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedIssueSymbolDirectoryMessage ==
    { ZeroIssueSymbolDirectoryMessage }
        \cup { [ZeroIssueSymbolDirectoryMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroIssueSymbolDirectoryMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroIssueSymbolDirectoryMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroIssueSymbolDirectoryMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroIssueSymbolDirectoryMessage EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroIssueSymbolDirectoryMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroIssueSymbolDirectoryMessage EXCEPT !.oldSymbol = one] : one \in Sample(11) }
        \cup { [ZeroIssueSymbolDirectoryMessage EXCEPT !.issueName = one] : one \in Sample(30) }
        \cup { [ZeroIssueSymbolDirectoryMessage EXCEPT !.issueType = one] : one \in Sample(1) }
        \cup { [ZeroIssueSymbolDirectoryMessage EXCEPT !.issueSubtype = one] : one \in Sample(2) }
        \cup { [ZeroIssueSymbolDirectoryMessage EXCEPT !.marketTier = one] : one \in Sample(1) }
        \cup { [ZeroIssueSymbolDirectoryMessage EXCEPT !.authenticity = one] : one \in Sample(1) }
        \cup { [ZeroIssueSymbolDirectoryMessage EXCEPT !.shortSaleThresholdIndicator = one] : one \in Sample(1) }
        \cup { [ZeroIssueSymbolDirectoryMessage EXCEPT !.roundLotSize = one] : one \in Sample(2) }
        \cup { [ZeroIssueSymbolDirectoryMessage EXCEPT !.financialStatusIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Reg Sho Short Sale Price Test Restricted Indicator Message: 38 bytes    *)
(***************************************************************************)

RegShoShortSalePriceTestRestrictedIndicatorMessage ==
    [ marketCenterOriginator : Sample(1),
      subMarketCenterId      : Sample(1),
      sipTimestamp           : Sample(8),
      timestamp1             : Sample(8),
      participantToken       : Sample(8),
      symbolLong             : Sample(11),
      regShoAction           : Sample(1) ]

EncodeRegShoShortSalePriceTestRestrictedIndicatorMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o message.symbolLong
        \o message.regShoAction

DecodeRegShoShortSalePriceTestRestrictedIndicatorMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(participantToken.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET regShoAction == ReadBytes(symbolLong.rest, 1) IN IF ~regShoAction.ok THEN Fail ELSE
    Ok([ marketCenterOriginator |-> marketCenterOriginator.value,
         subMarketCenterId      |-> subMarketCenterId.value,
         sipTimestamp           |-> sipTimestamp.value,
         timestamp1             |-> timestamp1.value,
         participantToken       |-> participantToken.value,
         symbolLong             |-> symbolLong.value,
         regShoAction           |-> regShoAction.value ], regShoAction.rest)

ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage ==
    [ marketCenterOriginator |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId      |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp           |-> [i \in 1 .. 8 |-> 0],
      timestamp1             |-> [i \in 1 .. 8 |-> 0],
      participantToken       |-> [i \in 1 .. 8 |-> 0],
      symbolLong             |-> [i \in 1 .. 11 |-> 0],
      regShoAction           |-> [i \in 1 .. 1 |-> 0] ]

(* Reg Sho Short Sale Price Test Restricted Indicator Message at zero, then each field in turn at the values it is checked at *)
CheckedRegShoShortSalePriceTestRestrictedIndicatorMessage ==
    { ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.regShoAction = one] : one \in Sample(1) }

(***************************************************************************)
(* Limit Up Limit Down Price Band Message: 62 bytes                        *)
(***************************************************************************)

LimitUpLimitDownPriceBandMessage ==
    [ marketCenterOriginator     : Sample(1),
      subMarketCenterId          : Sample(1),
      sipTimestamp               : Sample(8),
      timestamp1                 : Sample(8),
      participantToken           : Sample(8),
      symbolLong                 : Sample(11),
      luldPriceBandIndicator     : Sample(1),
      luldPriceBandEffectiveTime : Sample(8),
      limitDownPrice             : Sample(8),
      limitUpPrice               : Sample(8) ]

EncodeLimitUpLimitDownPriceBandMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o message.symbolLong
        \o message.luldPriceBandIndicator
        \o message.luldPriceBandEffectiveTime
        \o message.limitDownPrice
        \o message.limitUpPrice

DecodeLimitUpLimitDownPriceBandMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(participantToken.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET luldPriceBandIndicator == ReadBytes(symbolLong.rest, 1) IN IF ~luldPriceBandIndicator.ok THEN Fail ELSE
    LET luldPriceBandEffectiveTime == ReadBytes(luldPriceBandIndicator.rest, 8) IN IF ~luldPriceBandEffectiveTime.ok THEN Fail ELSE
    LET limitDownPrice == ReadBytes(luldPriceBandEffectiveTime.rest, 8) IN IF ~limitDownPrice.ok THEN Fail ELSE
    LET limitUpPrice == ReadBytes(limitDownPrice.rest, 8) IN IF ~limitUpPrice.ok THEN Fail ELSE
    Ok([ marketCenterOriginator     |-> marketCenterOriginator.value,
         subMarketCenterId          |-> subMarketCenterId.value,
         sipTimestamp               |-> sipTimestamp.value,
         timestamp1                 |-> timestamp1.value,
         participantToken           |-> participantToken.value,
         symbolLong                 |-> symbolLong.value,
         luldPriceBandIndicator     |-> luldPriceBandIndicator.value,
         luldPriceBandEffectiveTime |-> luldPriceBandEffectiveTime.value,
         limitDownPrice             |-> limitDownPrice.value,
         limitUpPrice               |-> limitUpPrice.value ], limitUpPrice.rest)

ZeroLimitUpLimitDownPriceBandMessage ==
    [ marketCenterOriginator     |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId          |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp               |-> [i \in 1 .. 8 |-> 0],
      timestamp1                 |-> [i \in 1 .. 8 |-> 0],
      participantToken           |-> [i \in 1 .. 8 |-> 0],
      symbolLong                 |-> [i \in 1 .. 11 |-> 0],
      luldPriceBandIndicator     |-> [i \in 1 .. 1 |-> 0],
      luldPriceBandEffectiveTime |-> [i \in 1 .. 8 |-> 0],
      limitDownPrice             |-> [i \in 1 .. 8 |-> 0],
      limitUpPrice               |-> [i \in 1 .. 8 |-> 0] ]

(* Limit Up Limit Down Price Band Message at zero, then each field in turn at the values it is checked at *)
CheckedLimitUpLimitDownPriceBandMessage ==
    { ZeroLimitUpLimitDownPriceBandMessage }
        \cup { [ZeroLimitUpLimitDownPriceBandMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroLimitUpLimitDownPriceBandMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroLimitUpLimitDownPriceBandMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroLimitUpLimitDownPriceBandMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroLimitUpLimitDownPriceBandMessage EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroLimitUpLimitDownPriceBandMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroLimitUpLimitDownPriceBandMessage EXCEPT !.luldPriceBandIndicator = one] : one \in Sample(1) }
        \cup { [ZeroLimitUpLimitDownPriceBandMessage EXCEPT !.luldPriceBandEffectiveTime = one] : one \in Sample(8) }
        \cup { [ZeroLimitUpLimitDownPriceBandMessage EXCEPT !.limitDownPrice = one] : one \in Sample(8) }
        \cup { [ZeroLimitUpLimitDownPriceBandMessage EXCEPT !.limitUpPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Market Wide Circuit Breaker Decline Level Message: 50 bytes             *)
(***************************************************************************)

MarketWideCircuitBreakerDeclineLevelMessage ==
    [ marketCenterOriginator : Sample(1),
      subMarketCenterId      : Sample(1),
      sipTimestamp           : Sample(8),
      timestamp1             : Sample(8),
      participantToken       : Sample(8),
      mwcbLevel1             : Sample(8),
      mwcbLevel2             : Sample(8),
      mwcbLevel3             : Sample(8) ]

EncodeMarketWideCircuitBreakerDeclineLevelMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o message.mwcbLevel1
        \o message.mwcbLevel2
        \o message.mwcbLevel3

DecodeMarketWideCircuitBreakerDeclineLevelMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET mwcbLevel1 == ReadBytes(participantToken.rest, 8) IN IF ~mwcbLevel1.ok THEN Fail ELSE
    LET mwcbLevel2 == ReadBytes(mwcbLevel1.rest, 8) IN IF ~mwcbLevel2.ok THEN Fail ELSE
    LET mwcbLevel3 == ReadBytes(mwcbLevel2.rest, 8) IN IF ~mwcbLevel3.ok THEN Fail ELSE
    Ok([ marketCenterOriginator |-> marketCenterOriginator.value,
         subMarketCenterId      |-> subMarketCenterId.value,
         sipTimestamp           |-> sipTimestamp.value,
         timestamp1             |-> timestamp1.value,
         participantToken       |-> participantToken.value,
         mwcbLevel1             |-> mwcbLevel1.value,
         mwcbLevel2             |-> mwcbLevel2.value,
         mwcbLevel3             |-> mwcbLevel3.value ], mwcbLevel3.rest)

ZeroMarketWideCircuitBreakerDeclineLevelMessage ==
    [ marketCenterOriginator |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId      |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp           |-> [i \in 1 .. 8 |-> 0],
      timestamp1             |-> [i \in 1 .. 8 |-> 0],
      participantToken       |-> [i \in 1 .. 8 |-> 0],
      mwcbLevel1             |-> [i \in 1 .. 8 |-> 0],
      mwcbLevel2             |-> [i \in 1 .. 8 |-> 0],
      mwcbLevel3             |-> [i \in 1 .. 8 |-> 0] ]

(* Market Wide Circuit Breaker Decline Level Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketWideCircuitBreakerDeclineLevelMessage ==
    { ZeroMarketWideCircuitBreakerDeclineLevelMessage }
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelMessage EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelMessage EXCEPT !.mwcbLevel1 = one] : one \in Sample(8) }
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelMessage EXCEPT !.mwcbLevel2 = one] : one \in Sample(8) }
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelMessage EXCEPT !.mwcbLevel3 = one] : one \in Sample(8) }

(***************************************************************************)
(* Market Wide Circuit Breaker Status Message: 27 bytes                    *)
(***************************************************************************)

MarketWideCircuitBreakerStatusMessage ==
    [ marketCenterOriginator   : Sample(1),
      subMarketCenterId        : Sample(1),
      sipTimestamp             : Sample(8),
      timestamp1               : Sample(8),
      participantToken         : Sample(8),
      mwcbStatusLevelIndicator : Sample(1) ]

EncodeMarketWideCircuitBreakerStatusMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o message.mwcbStatusLevelIndicator

DecodeMarketWideCircuitBreakerStatusMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET mwcbStatusLevelIndicator == ReadBytes(participantToken.rest, 1) IN IF ~mwcbStatusLevelIndicator.ok THEN Fail ELSE
    Ok([ marketCenterOriginator   |-> marketCenterOriginator.value,
         subMarketCenterId        |-> subMarketCenterId.value,
         sipTimestamp             |-> sipTimestamp.value,
         timestamp1               |-> timestamp1.value,
         participantToken         |-> participantToken.value,
         mwcbStatusLevelIndicator |-> mwcbStatusLevelIndicator.value ], mwcbStatusLevelIndicator.rest)

ZeroMarketWideCircuitBreakerStatusMessage ==
    [ marketCenterOriginator   |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId        |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp             |-> [i \in 1 .. 8 |-> 0],
      timestamp1               |-> [i \in 1 .. 8 |-> 0],
      participantToken         |-> [i \in 1 .. 8 |-> 0],
      mwcbStatusLevelIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Market Wide Circuit Breaker Status Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketWideCircuitBreakerStatusMessage ==
    { ZeroMarketWideCircuitBreakerStatusMessage }
        \cup { [ZeroMarketWideCircuitBreakerStatusMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroMarketWideCircuitBreakerStatusMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMarketWideCircuitBreakerStatusMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMarketWideCircuitBreakerStatusMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroMarketWideCircuitBreakerStatusMessage EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroMarketWideCircuitBreakerStatusMessage EXCEPT !.mwcbStatusLevelIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Auction Collar Message: 66 bytes                                        *)
(***************************************************************************)

AuctionCollarMessage ==
    [ marketCenterOriginator      : Sample(1),
      subMarketCenterId           : Sample(1),
      sipTimestamp                : Sample(8),
      timestamp1                  : Sample(8),
      participantToken            : Sample(8),
      symbolLong                  : Sample(11),
      tradingActionSequenceNumber : Sample(4),
      collarReferencePrice        : Sample(8),
      collarUpPrice               : Sample(8),
      collarDownPrice             : Sample(8),
      collarExtensionIndicator    : Sample(1) ]

EncodeAuctionCollarMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o message.symbolLong
        \o message.tradingActionSequenceNumber
        \o message.collarReferencePrice
        \o message.collarUpPrice
        \o message.collarDownPrice
        \o message.collarExtensionIndicator

DecodeAuctionCollarMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(participantToken.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET tradingActionSequenceNumber == ReadBytes(symbolLong.rest, 4) IN IF ~tradingActionSequenceNumber.ok THEN Fail ELSE
    LET collarReferencePrice == ReadBytes(tradingActionSequenceNumber.rest, 8) IN IF ~collarReferencePrice.ok THEN Fail ELSE
    LET collarUpPrice == ReadBytes(collarReferencePrice.rest, 8) IN IF ~collarUpPrice.ok THEN Fail ELSE
    LET collarDownPrice == ReadBytes(collarUpPrice.rest, 8) IN IF ~collarDownPrice.ok THEN Fail ELSE
    LET collarExtensionIndicator == ReadBytes(collarDownPrice.rest, 1) IN IF ~collarExtensionIndicator.ok THEN Fail ELSE
    Ok([ marketCenterOriginator      |-> marketCenterOriginator.value,
         subMarketCenterId           |-> subMarketCenterId.value,
         sipTimestamp                |-> sipTimestamp.value,
         timestamp1                  |-> timestamp1.value,
         participantToken            |-> participantToken.value,
         symbolLong                  |-> symbolLong.value,
         tradingActionSequenceNumber |-> tradingActionSequenceNumber.value,
         collarReferencePrice        |-> collarReferencePrice.value,
         collarUpPrice               |-> collarUpPrice.value,
         collarDownPrice             |-> collarDownPrice.value,
         collarExtensionIndicator    |-> collarExtensionIndicator.value ], collarExtensionIndicator.rest)

ZeroAuctionCollarMessage ==
    [ marketCenterOriginator      |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId           |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp                |-> [i \in 1 .. 8 |-> 0],
      timestamp1                  |-> [i \in 1 .. 8 |-> 0],
      participantToken            |-> [i \in 1 .. 8 |-> 0],
      symbolLong                  |-> [i \in 1 .. 11 |-> 0],
      tradingActionSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      collarReferencePrice        |-> [i \in 1 .. 8 |-> 0],
      collarUpPrice               |-> [i \in 1 .. 8 |-> 0],
      collarDownPrice             |-> [i \in 1 .. 8 |-> 0],
      collarExtensionIndicator    |-> [i \in 1 .. 1 |-> 0] ]

(* Auction Collar Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionCollarMessage ==
    { ZeroAuctionCollarMessage }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.tradingActionSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.collarReferencePrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.collarUpPrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.collarDownPrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.collarExtensionIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Market Center Close Recap: 33 bytes                                     *)
(***************************************************************************)

MarketCenterCloseRecap ==
    [ marketCenterIdentifier : Sample(1),
      marketCenterBidPrice   : Sample(8),
      marketCenterBidSize    : Sample(8),
      marketCenterAskPrice   : Sample(8),
      marketCenterAskSize    : Sample(8) ]

EncodeMarketCenterCloseRecap(message) ==
    message.marketCenterIdentifier
        \o message.marketCenterBidPrice
        \o message.marketCenterBidSize
        \o message.marketCenterAskPrice
        \o message.marketCenterAskSize

DecodeMarketCenterCloseRecap(bytes) ==
    LET marketCenterIdentifier == ReadBytes(bytes, 1) IN IF ~marketCenterIdentifier.ok THEN Fail ELSE
    LET marketCenterBidPrice == ReadBytes(marketCenterIdentifier.rest, 8) IN IF ~marketCenterBidPrice.ok THEN Fail ELSE
    LET marketCenterBidSize == ReadBytes(marketCenterBidPrice.rest, 8) IN IF ~marketCenterBidSize.ok THEN Fail ELSE
    LET marketCenterAskPrice == ReadBytes(marketCenterBidSize.rest, 8) IN IF ~marketCenterAskPrice.ok THEN Fail ELSE
    LET marketCenterAskSize == ReadBytes(marketCenterAskPrice.rest, 8) IN IF ~marketCenterAskSize.ok THEN Fail ELSE
    Ok([ marketCenterIdentifier |-> marketCenterIdentifier.value,
         marketCenterBidPrice   |-> marketCenterBidPrice.value,
         marketCenterBidSize    |-> marketCenterBidSize.value,
         marketCenterAskPrice   |-> marketCenterAskPrice.value,
         marketCenterAskSize    |-> marketCenterAskSize.value ], marketCenterAskSize.rest)

ZeroMarketCenterCloseRecap ==
    [ marketCenterIdentifier |-> [i \in 1 .. 1 |-> 0],
      marketCenterBidPrice   |-> [i \in 1 .. 8 |-> 0],
      marketCenterBidSize    |-> [i \in 1 .. 8 |-> 0],
      marketCenterAskPrice   |-> [i \in 1 .. 8 |-> 0],
      marketCenterAskSize    |-> [i \in 1 .. 8 |-> 0] ]

(* Market Center Close Recap at zero, then each field in turn at the values it is checked at *)
CheckedMarketCenterCloseRecap ==
    { ZeroMarketCenterCloseRecap }
        \cup { [ZeroMarketCenterCloseRecap EXCEPT !.marketCenterIdentifier = one] : one \in Sample(1) }
        \cup { [ZeroMarketCenterCloseRecap EXCEPT !.marketCenterBidPrice = one] : one \in Sample(8) }
        \cup { [ZeroMarketCenterCloseRecap EXCEPT !.marketCenterBidSize = one] : one \in Sample(8) }
        \cup { [ZeroMarketCenterCloseRecap EXCEPT !.marketCenterAskPrice = one] : one \in Sample(8) }
        \cup { [ZeroMarketCenterCloseRecap EXCEPT !.marketCenterAskSize = one] : one \in Sample(8) }

(* A run of Market Center Close Recap, written one after another *)
RECURSIVE EncodeMarketCenterCloseRecapList(_)
EncodeMarketCenterCloseRecapList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMarketCenterCloseRecap(Head(messages)) \o EncodeMarketCenterCloseRecapList(Tail(messages))

(* As many Market Center Close Recap as the field that counts them says *)
RECURSIVE ReadMarketCenterCloseRecapList(_, _)
ReadMarketCenterCloseRecapList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMarketCenterCloseRecap(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMarketCenterCloseRecapList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Market Center Close Recap of each kind, for the lists that carry them *)
OneMarketCenterCloseRecap == { ZeroMarketCenterCloseRecap }

(***************************************************************************)
(* Session Close Recap Message                                             *)
(***************************************************************************)

SessionCloseRecapMessage ==
    [ marketCenterOriginator      : Sample(1),
      subMarketCenterId           : Sample(1),
      sipTimestamp                : Sample(8),
      timestamp1                  : Sample(8),
      participantToken            : Sample(8),
      symbolLong                  : Sample(11),
      nationalBestBidMarketCenter : Sample(1),
      nationalBestBidPriceLong    : Sample(8),
      nationalBestBidSize         : Sample(8),
      nationalBestAskMarketCenter : Sample(1),
      nationalBestAskPriceLong    : Sample(8),
      nationalBestAskSize         : Sample(8),
      specialCondition            : Sample(1),
      marketCenterCloseRecap      : SampleLists(OneMarketCenterCloseRecap) ]

EncodeSessionCloseRecapMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o message.symbolLong
        \o message.nationalBestBidMarketCenter
        \o message.nationalBestBidPriceLong
        \o message.nationalBestBidSize
        \o message.nationalBestAskMarketCenter
        \o message.nationalBestAskPriceLong
        \o message.nationalBestAskSize
        \o message.specialCondition
        \o EncodeUIntBE(Len(message.marketCenterCloseRecap), 2)
        \o EncodeMarketCenterCloseRecapList(message.marketCenterCloseRecap)

DecodeSessionCloseRecapMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(participantToken.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET nationalBestBidMarketCenter == ReadBytes(symbolLong.rest, 1) IN IF ~nationalBestBidMarketCenter.ok THEN Fail ELSE
    LET nationalBestBidPriceLong == ReadBytes(nationalBestBidMarketCenter.rest, 8) IN IF ~nationalBestBidPriceLong.ok THEN Fail ELSE
    LET nationalBestBidSize == ReadBytes(nationalBestBidPriceLong.rest, 8) IN IF ~nationalBestBidSize.ok THEN Fail ELSE
    LET nationalBestAskMarketCenter == ReadBytes(nationalBestBidSize.rest, 1) IN IF ~nationalBestAskMarketCenter.ok THEN Fail ELSE
    LET nationalBestAskPriceLong == ReadBytes(nationalBestAskMarketCenter.rest, 8) IN IF ~nationalBestAskPriceLong.ok THEN Fail ELSE
    LET nationalBestAskSize == ReadBytes(nationalBestAskPriceLong.rest, 8) IN IF ~nationalBestAskSize.ok THEN Fail ELSE
    LET specialCondition == ReadBytes(nationalBestAskSize.rest, 1) IN IF ~specialCondition.ok THEN Fail ELSE
    LET numberOfMarketCenterAttachments == ReadUIntBE(specialCondition.rest, 2) IN IF ~numberOfMarketCenterAttachments.ok THEN Fail ELSE
    LET marketCenterCloseRecap == ReadMarketCenterCloseRecapList(numberOfMarketCenterAttachments.rest, numberOfMarketCenterAttachments.value) IN IF ~marketCenterCloseRecap.ok THEN Fail ELSE
    Ok([ marketCenterOriginator      |-> marketCenterOriginator.value,
         subMarketCenterId           |-> subMarketCenterId.value,
         sipTimestamp                |-> sipTimestamp.value,
         timestamp1                  |-> timestamp1.value,
         participantToken            |-> participantToken.value,
         symbolLong                  |-> symbolLong.value,
         nationalBestBidMarketCenter |-> nationalBestBidMarketCenter.value,
         nationalBestBidPriceLong    |-> nationalBestBidPriceLong.value,
         nationalBestBidSize         |-> nationalBestBidSize.value,
         nationalBestAskMarketCenter |-> nationalBestAskMarketCenter.value,
         nationalBestAskPriceLong    |-> nationalBestAskPriceLong.value,
         nationalBestAskSize         |-> nationalBestAskSize.value,
         specialCondition            |-> specialCondition.value,
         marketCenterCloseRecap      |-> marketCenterCloseRecap.value ], marketCenterCloseRecap.rest)

ZeroSessionCloseRecapMessage ==
    [ marketCenterOriginator      |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId           |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp                |-> [i \in 1 .. 8 |-> 0],
      timestamp1                  |-> [i \in 1 .. 8 |-> 0],
      participantToken            |-> [i \in 1 .. 8 |-> 0],
      symbolLong                  |-> [i \in 1 .. 11 |-> 0],
      nationalBestBidMarketCenter |-> [i \in 1 .. 1 |-> 0],
      nationalBestBidPriceLong    |-> [i \in 1 .. 8 |-> 0],
      nationalBestBidSize         |-> [i \in 1 .. 8 |-> 0],
      nationalBestAskMarketCenter |-> [i \in 1 .. 1 |-> 0],
      nationalBestAskPriceLong    |-> [i \in 1 .. 8 |-> 0],
      nationalBestAskSize         |-> [i \in 1 .. 8 |-> 0],
      specialCondition            |-> [i \in 1 .. 1 |-> 0],
      marketCenterCloseRecap      |-> << >> ]

(* Session Close Recap Message at zero, then each field in turn at the values it is checked at *)
CheckedSessionCloseRecapMessage ==
    { ZeroSessionCloseRecapMessage }
        \cup { [ZeroSessionCloseRecapMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroSessionCloseRecapMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroSessionCloseRecapMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroSessionCloseRecapMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroSessionCloseRecapMessage EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroSessionCloseRecapMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroSessionCloseRecapMessage EXCEPT !.nationalBestBidMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroSessionCloseRecapMessage EXCEPT !.nationalBestBidPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroSessionCloseRecapMessage EXCEPT !.nationalBestBidSize = one] : one \in Sample(8) }
        \cup { [ZeroSessionCloseRecapMessage EXCEPT !.nationalBestAskMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroSessionCloseRecapMessage EXCEPT !.nationalBestAskPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroSessionCloseRecapMessage EXCEPT !.nationalBestAskSize = one] : one \in Sample(8) }
        \cup { [ZeroSessionCloseRecapMessage EXCEPT !.specialCondition = one] : one \in Sample(1) }
        \cup { [ZeroSessionCloseRecapMessage EXCEPT !.marketCenterCloseRecap = one] : one \in SampleLists(OneMarketCenterCloseRecap) }

(***************************************************************************)
(* Administrative Message Payload, selected by Administrative Message Type *)
(***************************************************************************)

GeneralAdministrativeMessageCode == 65  \* "A"
CrossSroTradingActionMessageCode == 72  \* "H"
MarketCenterTradingActionMessageCode == 75  \* "K"
IssueSymbolDirectoryMessageCode == 66  \* "B"
RegShoShortSalePriceTestRestrictedIndicatorMessageCode == 86  \* "V"
LimitUpLimitDownPriceBandMessageCode == 80  \* "P"
MarketWideCircuitBreakerDeclineLevelMessageCode == 67  \* "C"
MarketWideCircuitBreakerStatusMessageCode == 68  \* "D"
AuctionCollarMessageCode == 69  \* "E"
SessionCloseRecapMessageCode == 82  \* "R"

AdministrativeMessagePayload ==
    [ tag : {GeneralAdministrativeMessageCode}, body : GeneralAdministrativeMessage ]
        \cup [ tag : {CrossSroTradingActionMessageCode}, body : CrossSroTradingActionMessage ]
        \cup [ tag : {MarketCenterTradingActionMessageCode}, body : MarketCenterTradingActionMessage ]
        \cup [ tag : {IssueSymbolDirectoryMessageCode}, body : IssueSymbolDirectoryMessage ]
        \cup [ tag : {RegShoShortSalePriceTestRestrictedIndicatorMessageCode}, body : RegShoShortSalePriceTestRestrictedIndicatorMessage ]
        \cup [ tag : {LimitUpLimitDownPriceBandMessageCode}, body : LimitUpLimitDownPriceBandMessage ]
        \cup [ tag : {MarketWideCircuitBreakerDeclineLevelMessageCode}, body : MarketWideCircuitBreakerDeclineLevelMessage ]
        \cup [ tag : {MarketWideCircuitBreakerStatusMessageCode}, body : MarketWideCircuitBreakerStatusMessage ]
        \cup [ tag : {AuctionCollarMessageCode}, body : AuctionCollarMessage ]
        \cup [ tag : {SessionCloseRecapMessageCode}, body : SessionCloseRecapMessage ]

EncodeAdministrativeMessagePayload(message) ==
    CASE message.tag = GeneralAdministrativeMessageCode -> EncodeGeneralAdministrativeMessage(message.body)
      [] message.tag = CrossSroTradingActionMessageCode -> EncodeCrossSroTradingActionMessage(message.body)
      [] message.tag = MarketCenterTradingActionMessageCode -> EncodeMarketCenterTradingActionMessage(message.body)
      [] message.tag = IssueSymbolDirectoryMessageCode -> EncodeIssueSymbolDirectoryMessage(message.body)
      [] message.tag = RegShoShortSalePriceTestRestrictedIndicatorMessageCode -> EncodeRegShoShortSalePriceTestRestrictedIndicatorMessage(message.body)
      [] message.tag = LimitUpLimitDownPriceBandMessageCode -> EncodeLimitUpLimitDownPriceBandMessage(message.body)
      [] message.tag = MarketWideCircuitBreakerDeclineLevelMessageCode -> EncodeMarketWideCircuitBreakerDeclineLevelMessage(message.body)
      [] message.tag = MarketWideCircuitBreakerStatusMessageCode -> EncodeMarketWideCircuitBreakerStatusMessage(message.body)
      [] message.tag = AuctionCollarMessageCode -> EncodeAuctionCollarMessage(message.body)
      [] message.tag = SessionCloseRecapMessageCode -> EncodeSessionCloseRecapMessage(message.body)

DecodeAdministrativeMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = GeneralAdministrativeMessageCode -> DecodeGeneralAdministrativeMessage(bytes)
              [] tag = CrossSroTradingActionMessageCode -> DecodeCrossSroTradingActionMessage(bytes)
              [] tag = MarketCenterTradingActionMessageCode -> DecodeMarketCenterTradingActionMessage(bytes)
              [] tag = IssueSymbolDirectoryMessageCode -> DecodeIssueSymbolDirectoryMessage(bytes)
              [] tag = RegShoShortSalePriceTestRestrictedIndicatorMessageCode -> DecodeRegShoShortSalePriceTestRestrictedIndicatorMessage(bytes)
              [] tag = LimitUpLimitDownPriceBandMessageCode -> DecodeLimitUpLimitDownPriceBandMessage(bytes)
              [] tag = MarketWideCircuitBreakerDeclineLevelMessageCode -> DecodeMarketWideCircuitBreakerDeclineLevelMessage(bytes)
              [] tag = MarketWideCircuitBreakerStatusMessageCode -> DecodeMarketWideCircuitBreakerStatusMessage(bytes)
              [] tag = AuctionCollarMessageCode -> DecodeAuctionCollarMessage(bytes)
              [] tag = SessionCloseRecapMessageCode -> DecodeSessionCloseRecapMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroAdministrativeMessagePayload == [tag |-> GeneralAdministrativeMessageCode, body |-> ZeroGeneralAdministrativeMessage]

(* Each Administrative Message Payload in turn, at the values the message it names is checked at *)
CheckedAdministrativeMessagePayload ==
    { [tag |-> GeneralAdministrativeMessageCode, body |-> one] : one \in CheckedGeneralAdministrativeMessage }
        \cup { [tag |-> CrossSroTradingActionMessageCode, body |-> one] : one \in CheckedCrossSroTradingActionMessage }
        \cup { [tag |-> MarketCenterTradingActionMessageCode, body |-> one] : one \in CheckedMarketCenterTradingActionMessage }
        \cup { [tag |-> IssueSymbolDirectoryMessageCode, body |-> one] : one \in CheckedIssueSymbolDirectoryMessage }
        \cup { [tag |-> RegShoShortSalePriceTestRestrictedIndicatorMessageCode, body |-> one] : one \in CheckedRegShoShortSalePriceTestRestrictedIndicatorMessage }
        \cup { [tag |-> LimitUpLimitDownPriceBandMessageCode, body |-> one] : one \in CheckedLimitUpLimitDownPriceBandMessage }
        \cup { [tag |-> MarketWideCircuitBreakerDeclineLevelMessageCode, body |-> one] : one \in CheckedMarketWideCircuitBreakerDeclineLevelMessage }
        \cup { [tag |-> MarketWideCircuitBreakerStatusMessageCode, body |-> one] : one \in CheckedMarketWideCircuitBreakerStatusMessage }
        \cup { [tag |-> AuctionCollarMessageCode, body |-> one] : one \in CheckedAuctionCollarMessage }
        \cup { [tag |-> SessionCloseRecapMessageCode, body |-> one] : one \in CheckedSessionCloseRecapMessage }

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
(* Start Of Day Message: 26 bytes                                          *)
(***************************************************************************)

StartOfDayMessage ==
    [ marketCenterOriginator : Sample(1),
      subMarketCenterId      : Sample(1),
      sipTimestamp           : Sample(8),
      timestamp1             : Sample(8),
      participantToken       : Sample(8) ]

EncodeStartOfDayMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken

DecodeStartOfDayMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginator |-> marketCenterOriginator.value,
         subMarketCenterId      |-> subMarketCenterId.value,
         sipTimestamp           |-> sipTimestamp.value,
         timestamp1             |-> timestamp1.value,
         participantToken       |-> participantToken.value ], participantToken.rest)

ZeroStartOfDayMessage ==
    [ marketCenterOriginator |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId      |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp           |-> [i \in 1 .. 8 |-> 0],
      timestamp1             |-> [i \in 1 .. 8 |-> 0],
      participantToken       |-> [i \in 1 .. 8 |-> 0] ]

(* Start Of Day Message at zero, then each field in turn at the values it is checked at *)
CheckedStartOfDayMessage ==
    { ZeroStartOfDayMessage }
        \cup { [ZeroStartOfDayMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroStartOfDayMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroStartOfDayMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroStartOfDayMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroStartOfDayMessage EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* End Of Day Message: 26 bytes                                            *)
(***************************************************************************)

EndOfDayMessage ==
    [ marketCenterOriginator : Sample(1),
      subMarketCenterId      : Sample(1),
      sipTimestamp           : Sample(8),
      timestamp1             : Sample(8),
      participantToken       : Sample(8) ]

EncodeEndOfDayMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken

DecodeEndOfDayMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginator |-> marketCenterOriginator.value,
         subMarketCenterId      |-> subMarketCenterId.value,
         sipTimestamp           |-> sipTimestamp.value,
         timestamp1             |-> timestamp1.value,
         participantToken       |-> participantToken.value ], participantToken.rest)

ZeroEndOfDayMessage ==
    [ marketCenterOriginator |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId      |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp           |-> [i \in 1 .. 8 |-> 0],
      timestamp1             |-> [i \in 1 .. 8 |-> 0],
      participantToken       |-> [i \in 1 .. 8 |-> 0] ]

(* End Of Day Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfDayMessage ==
    { ZeroEndOfDayMessage }
        \cup { [ZeroEndOfDayMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroEndOfDayMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroEndOfDayMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroEndOfDayMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroEndOfDayMessage EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* Market Session Open Message: 26 bytes                                   *)
(***************************************************************************)

MarketSessionOpenMessage ==
    [ marketCenterOriginator : Sample(1),
      subMarketCenterId      : Sample(1),
      sipTimestamp           : Sample(8),
      timestamp1             : Sample(8),
      participantToken       : Sample(8) ]

EncodeMarketSessionOpenMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken

DecodeMarketSessionOpenMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginator |-> marketCenterOriginator.value,
         subMarketCenterId      |-> subMarketCenterId.value,
         sipTimestamp           |-> sipTimestamp.value,
         timestamp1             |-> timestamp1.value,
         participantToken       |-> participantToken.value ], participantToken.rest)

ZeroMarketSessionOpenMessage ==
    [ marketCenterOriginator |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId      |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp           |-> [i \in 1 .. 8 |-> 0],
      timestamp1             |-> [i \in 1 .. 8 |-> 0],
      participantToken       |-> [i \in 1 .. 8 |-> 0] ]

(* Market Session Open Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketSessionOpenMessage ==
    { ZeroMarketSessionOpenMessage }
        \cup { [ZeroMarketSessionOpenMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroMarketSessionOpenMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMarketSessionOpenMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMarketSessionOpenMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroMarketSessionOpenMessage EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* Market Session Close Message: 26 bytes                                  *)
(***************************************************************************)

MarketSessionCloseMessage ==
    [ marketCenterOriginator : Sample(1),
      subMarketCenterId      : Sample(1),
      sipTimestamp           : Sample(8),
      timestamp1             : Sample(8),
      participantToken       : Sample(8) ]

EncodeMarketSessionCloseMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken

DecodeMarketSessionCloseMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginator |-> marketCenterOriginator.value,
         subMarketCenterId      |-> subMarketCenterId.value,
         sipTimestamp           |-> sipTimestamp.value,
         timestamp1             |-> timestamp1.value,
         participantToken       |-> participantToken.value ], participantToken.rest)

ZeroMarketSessionCloseMessage ==
    [ marketCenterOriginator |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId      |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp           |-> [i \in 1 .. 8 |-> 0],
      timestamp1             |-> [i \in 1 .. 8 |-> 0],
      participantToken       |-> [i \in 1 .. 8 |-> 0] ]

(* Market Session Close Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketSessionCloseMessage ==
    { ZeroMarketSessionCloseMessage }
        \cup { [ZeroMarketSessionCloseMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroMarketSessionCloseMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMarketSessionCloseMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMarketSessionCloseMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroMarketSessionCloseMessage EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* End Of Transmissions Message: 26 bytes                                  *)
(***************************************************************************)

EndOfTransmissionsMessage ==
    [ marketCenterOriginator : Sample(1),
      subMarketCenterId      : Sample(1),
      sipTimestamp           : Sample(8),
      timestamp1             : Sample(8),
      participantToken       : Sample(8) ]

EncodeEndOfTransmissionsMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken

DecodeEndOfTransmissionsMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginator |-> marketCenterOriginator.value,
         subMarketCenterId      |-> subMarketCenterId.value,
         sipTimestamp           |-> sipTimestamp.value,
         timestamp1             |-> timestamp1.value,
         participantToken       |-> participantToken.value ], participantToken.rest)

ZeroEndOfTransmissionsMessage ==
    [ marketCenterOriginator |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId      |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp           |-> [i \in 1 .. 8 |-> 0],
      timestamp1             |-> [i \in 1 .. 8 |-> 0],
      participantToken       |-> [i \in 1 .. 8 |-> 0] ]

(* End Of Transmissions Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfTransmissionsMessage ==
    { ZeroEndOfTransmissionsMessage }
        \cup { [ZeroEndOfTransmissionsMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroEndOfTransmissionsMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroEndOfTransmissionsMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroEndOfTransmissionsMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroEndOfTransmissionsMessage EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* Quote Wipe Out Message: 26 bytes                                        *)
(***************************************************************************)

QuoteWipeOutMessage ==
    [ marketCenterOriginator : Sample(1),
      subMarketCenterId      : Sample(1),
      sipTimestamp           : Sample(8),
      timestamp1             : Sample(8),
      participantToken       : Sample(8) ]

EncodeQuoteWipeOutMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken

DecodeQuoteWipeOutMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginator |-> marketCenterOriginator.value,
         subMarketCenterId      |-> subMarketCenterId.value,
         sipTimestamp           |-> sipTimestamp.value,
         timestamp1             |-> timestamp1.value,
         participantToken       |-> participantToken.value ], participantToken.rest)

ZeroQuoteWipeOutMessage ==
    [ marketCenterOriginator |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId      |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp           |-> [i \in 1 .. 8 |-> 0],
      timestamp1             |-> [i \in 1 .. 8 |-> 0],
      participantToken       |-> [i \in 1 .. 8 |-> 0] ]

(* Quote Wipe Out Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteWipeOutMessage ==
    { ZeroQuoteWipeOutMessage }
        \cup { [ZeroQuoteWipeOutMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroQuoteWipeOutMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroQuoteWipeOutMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroQuoteWipeOutMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroQuoteWipeOutMessage EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* Control Message Payload, selected by Control Message Type               *)
(***************************************************************************)

StartOfDayMessageCode == 73  \* "I"
EndOfDayMessageCode == 74  \* "J"
MarketSessionOpenMessageCode == 79  \* "O"
MarketSessionCloseMessageCode == 67  \* "C"
EndOfTransmissionsMessageCode == 90  \* "Z"
QuoteWipeOutMessageCode == 80  \* "P"

ControlMessagePayload ==
    [ tag : {StartOfDayMessageCode}, body : StartOfDayMessage ]
        \cup [ tag : {EndOfDayMessageCode}, body : EndOfDayMessage ]
        \cup [ tag : {MarketSessionOpenMessageCode}, body : MarketSessionOpenMessage ]
        \cup [ tag : {MarketSessionCloseMessageCode}, body : MarketSessionCloseMessage ]
        \cup [ tag : {EndOfTransmissionsMessageCode}, body : EndOfTransmissionsMessage ]
        \cup [ tag : {QuoteWipeOutMessageCode}, body : QuoteWipeOutMessage ]

EncodeControlMessagePayload(message) ==
    CASE message.tag = StartOfDayMessageCode -> EncodeStartOfDayMessage(message.body)
      [] message.tag = EndOfDayMessageCode -> EncodeEndOfDayMessage(message.body)
      [] message.tag = MarketSessionOpenMessageCode -> EncodeMarketSessionOpenMessage(message.body)
      [] message.tag = MarketSessionCloseMessageCode -> EncodeMarketSessionCloseMessage(message.body)
      [] message.tag = EndOfTransmissionsMessageCode -> EncodeEndOfTransmissionsMessage(message.body)
      [] message.tag = QuoteWipeOutMessageCode -> EncodeQuoteWipeOutMessage(message.body)

DecodeControlMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = StartOfDayMessageCode -> DecodeStartOfDayMessage(bytes)
              [] tag = EndOfDayMessageCode -> DecodeEndOfDayMessage(bytes)
              [] tag = MarketSessionOpenMessageCode -> DecodeMarketSessionOpenMessage(bytes)
              [] tag = MarketSessionCloseMessageCode -> DecodeMarketSessionCloseMessage(bytes)
              [] tag = EndOfTransmissionsMessageCode -> DecodeEndOfTransmissionsMessage(bytes)
              [] tag = QuoteWipeOutMessageCode -> DecodeQuoteWipeOutMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroControlMessagePayload == [tag |-> StartOfDayMessageCode, body |-> ZeroStartOfDayMessage]

(* Each Control Message Payload in turn, at the values the message it names is checked at *)
CheckedControlMessagePayload ==
    { [tag |-> StartOfDayMessageCode, body |-> one] : one \in CheckedStartOfDayMessage }
        \cup { [tag |-> EndOfDayMessageCode, body |-> one] : one \in CheckedEndOfDayMessage }
        \cup { [tag |-> MarketSessionOpenMessageCode, body |-> one] : one \in CheckedMarketSessionOpenMessage }
        \cup { [tag |-> MarketSessionCloseMessageCode, body |-> one] : one \in CheckedMarketSessionCloseMessage }
        \cup { [tag |-> EndOfTransmissionsMessageCode, body |-> one] : one \in CheckedEndOfTransmissionsMessage }
        \cup { [tag |-> QuoteWipeOutMessageCode, body |-> one] : one \in CheckedQuoteWipeOutMessage }

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
(* Category Payload, selected by Message Category                          *)
(***************************************************************************)

QuoteMessageCode == 81  \* "Q"
AdministrativeMessageCode == 65  \* "A"
ControlMessageCode == 67  \* "C"

CategoryPayload ==
    [ tag : {QuoteMessageCode}, body : QuoteMessage ]
        \cup [ tag : {AdministrativeMessageCode}, body : AdministrativeMessage ]
        \cup [ tag : {ControlMessageCode}, body : ControlMessage ]

EncodeCategoryPayload(message) ==
    CASE message.tag = QuoteMessageCode -> EncodeQuoteMessage(message.body)
      [] message.tag = AdministrativeMessageCode -> EncodeAdministrativeMessage(message.body)
      [] message.tag = ControlMessageCode -> EncodeControlMessage(message.body)

DecodeCategoryPayload(tag, bytes) ==
    LET read ==
            CASE tag = QuoteMessageCode -> DecodeQuoteMessage(bytes)
              [] tag = AdministrativeMessageCode -> DecodeAdministrativeMessage(bytes)
              [] tag = ControlMessageCode -> DecodeControlMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroCategoryPayload == [tag |-> QuoteMessageCode, body |-> ZeroQuoteMessage]

(* Each Category Payload in turn, at the values the message it names is checked at *)
CheckedCategoryPayload ==
    { [tag |-> QuoteMessageCode, body |-> one] : one \in CheckedQuoteMessage }
        \cup { [tag |-> AdministrativeMessageCode, body |-> one] : one \in CheckedAdministrativeMessage }
        \cup { [tag |-> ControlMessageCode, body |-> one] : one \in CheckedControlMessage }

(***************************************************************************)
(* Message                                                                 *)
(***************************************************************************)

Message ==
    [ messageLength   : 0 .. 255,
      version         : Sample(1),
      categoryPayload : CategoryPayload ]

EncodeMessage(message) ==
    EncodeUIntBE(message.messageLength, 2)
        \o message.version
        \o EncodeUIntBE(message.categoryPayload.tag, 1)
        \o EncodeCategoryPayload(message.categoryPayload)

DecodeMessage(bytes) ==
    LET messageLength == ReadUIntBE(bytes, 2) IN IF ~messageLength.ok THEN Fail ELSE
    LET version == ReadBytes(messageLength.rest, 1) IN IF ~version.ok THEN Fail ELSE
    LET messageCategory == ReadUIntBE(version.rest, 1) IN IF ~messageCategory.ok THEN Fail ELSE
    LET categoryPayload == DecodeCategoryPayload(messageCategory.value, messageCategory.rest) IN IF ~categoryPayload.ok THEN Fail ELSE
    Ok([ messageLength   |-> messageLength.value,
         version         |-> version.value,
         categoryPayload |-> categoryPayload.value ], categoryPayload.rest)

ZeroMessage ==
    [ messageLength   |-> 0,
      version         |-> [i \in 1 .. 1 |-> 0],
      categoryPayload |-> ZeroCategoryPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.messageLength = one] : one \in {0, 1, 255} }
        \cup { [ZeroMessage EXCEPT !.version = one] : one \in Sample(1) }
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
    { [ZeroMessage EXCEPT !.categoryPayload = [tag |-> QuoteMessageCode, body |-> ZeroQuoteMessage]],
      [ZeroMessage EXCEPT !.categoryPayload = [tag |-> AdministrativeMessageCode, body |-> ZeroAdministrativeMessage]],
      [ZeroMessage EXCEPT !.categoryPayload = [tag |-> ControlMessageCode, body |-> ZeroControlMessage]] }

(***************************************************************************)
(* Mold Udp 64 Packet                                                      *)
(***************************************************************************)

MoldUdp64Packet ==
    [ udpSession        : Sample(10),
      udpSequenceNumber : Sample(8),
      message           : SampleLists(OneMessage) ]

EncodeMoldUdp64Packet(message) ==
    message.udpSession
        \o message.udpSequenceNumber
        \o EncodeUIntBE(Len(message.message), 2)
        \o EncodeMessageList(message.message)

DecodeMoldUdp64Packet(bytes) ==
    LET udpSession == ReadBytes(bytes, 10) IN IF ~udpSession.ok THEN Fail ELSE
    LET udpSequenceNumber == ReadBytes(udpSession.rest, 8) IN IF ~udpSequenceNumber.ok THEN Fail ELSE
    LET messageCount == ReadUIntBE(udpSequenceNumber.rest, 2) IN IF ~messageCount.ok THEN Fail ELSE
    LET message == ReadMessageList(messageCount.rest, messageCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ udpSession        |-> udpSession.value,
         udpSequenceNumber |-> udpSequenceNumber.value,
         message           |-> message.value ], message.rest)

ZeroMoldUdp64Packet ==
    [ udpSession        |-> [i \in 1 .. 10 |-> 0],
      udpSequenceNumber |-> [i \in 1 .. 8 |-> 0],
      message           |-> << >> ]

(* Mold Udp 64 Packet at zero, then each field in turn at the values it is checked at *)
CheckedMoldUdp64Packet ==
    { ZeroMoldUdp64Packet }
        \cup { [ZeroMoldUdp64Packet EXCEPT !.udpSession = one] : one \in Sample(10) }
        \cup { [ZeroMoldUdp64Packet EXCEPT !.udpSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroMoldUdp64Packet EXCEPT !.message = one] : one \in SampleLists(OneMessage) }

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

(* Every National Bbo Appendage Shortform decodes back to what was encoded, and leaves nothing over *)
RoundTripNationalBboAppendageShortform ==
    \A message \in CheckedNationalBboAppendageShortform :
        LET read == DecodeNationalBboAppendageShortform(EncodeNationalBboAppendageShortform(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every National Bbo Appendage Longform decodes back to what was encoded, and leaves nothing over *)
RoundTripNationalBboAppendageLongform ==
    \A message \in CheckedNationalBboAppendageLongform :
        LET read == DecodeNationalBboAppendageLongform(EncodeNationalBboAppendageLongform(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Utp Quote Shortform Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUtpQuoteShortformMessage ==
    \A message \in CheckedUtpQuoteShortformMessage :
        LET read == DecodeUtpQuoteShortformMessage(EncodeUtpQuoteShortformMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every National Bbo Appendage Shortform decodes back to what was encoded, and leaves nothing over *)
RoundTripNationalBboAppendageShortform2 ==
    \A message \in CheckedNationalBboAppendageShortform2 :
        LET read == DecodeNationalBboAppendageShortform2(EncodeNationalBboAppendageShortform2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every National Bbo Appendage Longform decodes back to what was encoded, and leaves nothing over *)
RoundTripNationalBboAppendageLongform2 ==
    \A message \in CheckedNationalBboAppendageLongform2 :
        LET read == DecodeNationalBboAppendageLongform2(EncodeNationalBboAppendageLongform2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Utp Quote Longform Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUtpQuoteLongformMessage ==
    \A message \in CheckedUtpQuoteLongformMessage :
        LET read == DecodeUtpQuoteLongformMessage(EncodeUtpQuoteLongformMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Finra Adf Market Participant Quotation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFinraAdfMarketParticipantQuotationMessage ==
    \A message \in CheckedFinraAdfMarketParticipantQuotationMessage :
        LET read == DecodeFinraAdfMarketParticipantQuotationMessage(EncodeFinraAdfMarketParticipantQuotationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every National Bbo Appendage Shortform decodes back to what was encoded, and leaves nothing over *)
RoundTripNationalBboAppendageShortform3 ==
    \A message \in CheckedNationalBboAppendageShortform3 :
        LET read == DecodeNationalBboAppendageShortform3(EncodeNationalBboAppendageShortform3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every National Bbo Appendage Longform decodes back to what was encoded, and leaves nothing over *)
RoundTripNationalBboAppendageLongform3 ==
    \A message \in CheckedNationalBboAppendageLongform3 :
        LET read == DecodeNationalBboAppendageLongform3(EncodeNationalBboAppendageLongform3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bolo Appendage Short Form decodes back to what was encoded, and leaves nothing over *)
RoundTripBoloAppendageShortForm ==
    \A message \in CheckedBoloAppendageShortForm :
        LET read == DecodeBoloAppendageShortForm(EncodeBoloAppendageShortForm(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bolo Appendage Long Form decodes back to what was encoded, and leaves nothing over *)
RoundTripBoloAppendageLongForm ==
    \A message \in CheckedBoloAppendageLongForm :
        LET read == DecodeBoloAppendageLongForm(EncodeBoloAppendageLongForm(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bolo Appendage Mpid Form decodes back to what was encoded, and leaves nothing over *)
RoundTripBoloAppendageMpidForm ==
    \A message \in CheckedBoloAppendageMpidForm :
        LET read == DecodeBoloAppendageMpidForm(EncodeBoloAppendageMpidForm(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Combined Quote Message Short Form Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCombinedQuoteMessageShortFormMessage ==
    \A message \in CheckedCombinedQuoteMessageShortFormMessage :
        LET read == DecodeCombinedQuoteMessageShortFormMessage(EncodeCombinedQuoteMessageShortFormMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every National Bbo Appendage Shortform decodes back to what was encoded, and leaves nothing over *)
RoundTripNationalBboAppendageShortform4 ==
    \A message \in CheckedNationalBboAppendageShortform4 :
        LET read == DecodeNationalBboAppendageShortform4(EncodeNationalBboAppendageShortform4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every National Bbo Appendage Longform decodes back to what was encoded, and leaves nothing over *)
RoundTripNationalBboAppendageLongform4 ==
    \A message \in CheckedNationalBboAppendageLongform4 :
        LET read == DecodeNationalBboAppendageLongform4(EncodeNationalBboAppendageLongform4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Finra Adf Mpid Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripFinraAdfMpidAppendage ==
    \A message \in CheckedFinraAdfMpidAppendage :
        LET read == DecodeFinraAdfMpidAppendage(EncodeFinraAdfMpidAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bolo Appendage Short Form decodes back to what was encoded, and leaves nothing over *)
RoundTripBoloAppendageShortForm2 ==
    \A message \in CheckedBoloAppendageShortForm2 :
        LET read == DecodeBoloAppendageShortForm2(EncodeBoloAppendageShortForm2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bolo Appendage Long Form decodes back to what was encoded, and leaves nothing over *)
RoundTripBoloAppendageLongForm2 ==
    \A message \in CheckedBoloAppendageLongForm2 :
        LET read == DecodeBoloAppendageLongForm2(EncodeBoloAppendageLongForm2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bolo Appendage Mpid Form decodes back to what was encoded, and leaves nothing over *)
RoundTripBoloAppendageMpidForm2 ==
    \A message \in CheckedBoloAppendageMpidForm2 :
        LET read == DecodeBoloAppendageMpidForm2(EncodeBoloAppendageMpidForm2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Combined Quote Message Long Form Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCombinedQuoteMessageLongFormMessage ==
    \A message \in CheckedCombinedQuoteMessageLongFormMessage :
        LET read == DecodeCombinedQuoteMessageLongFormMessage(EncodeCombinedQuoteMessageLongFormMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bolo Appendage Short Form decodes back to what was encoded, and leaves nothing over *)
RoundTripBoloAppendageShortForm3 ==
    \A message \in CheckedBoloAppendageShortForm3 :
        LET read == DecodeBoloAppendageShortForm3(EncodeBoloAppendageShortForm3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bolo Appendage Long Form decodes back to what was encoded, and leaves nothing over *)
RoundTripBoloAppendageLongForm3 ==
    \A message \in CheckedBoloAppendageLongForm3 :
        LET read == DecodeBoloAppendageLongForm3(EncodeBoloAppendageLongForm3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bolo Appendage Mpid Form decodes back to what was encoded, and leaves nothing over *)
RoundTripBoloAppendageMpidForm3 ==
    \A message \in CheckedBoloAppendageMpidForm3 :
        LET read == DecodeBoloAppendageMpidForm3(EncodeBoloAppendageMpidForm3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Odd Lot Quote Message Short Form Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOddLotQuoteMessageShortFormMessage ==
    \A message \in CheckedOddLotQuoteMessageShortFormMessage :
        LET read == DecodeOddLotQuoteMessageShortFormMessage(EncodeOddLotQuoteMessageShortFormMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bolo Appendage Short Form decodes back to what was encoded, and leaves nothing over *)
RoundTripBoloAppendageShortForm4 ==
    \A message \in CheckedBoloAppendageShortForm4 :
        LET read == DecodeBoloAppendageShortForm4(EncodeBoloAppendageShortForm4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bolo Appendage Long Form decodes back to what was encoded, and leaves nothing over *)
RoundTripBoloAppendageLongForm4 ==
    \A message \in CheckedBoloAppendageLongForm4 :
        LET read == DecodeBoloAppendageLongForm4(EncodeBoloAppendageLongForm4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bolo Appendage Mpid Form decodes back to what was encoded, and leaves nothing over *)
RoundTripBoloAppendageMpidForm4 ==
    \A message \in CheckedBoloAppendageMpidForm4 :
        LET read == DecodeBoloAppendageMpidForm4(EncodeBoloAppendageMpidForm4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Odd Lot Quote Message Long Form Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOddLotQuoteMessageLongFormMessage ==
    \A message \in CheckedOddLotQuoteMessageLongFormMessage :
        LET read == DecodeOddLotQuoteMessageLongFormMessage(EncodeOddLotQuoteMessageLongFormMessage(message))
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

(* Every General Administrative Message decodes back to what was encoded, and leaves nothing over *)
RoundTripGeneralAdministrativeMessage ==
    \A message \in CheckedGeneralAdministrativeMessage :
        LET read == DecodeGeneralAdministrativeMessage(EncodeGeneralAdministrativeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cross Sro Trading Action Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCrossSroTradingActionMessage ==
    \A message \in CheckedCrossSroTradingActionMessage :
        LET read == DecodeCrossSroTradingActionMessage(EncodeCrossSroTradingActionMessage(message))
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

(* Every Issue Symbol Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIssueSymbolDirectoryMessage ==
    \A message \in CheckedIssueSymbolDirectoryMessage :
        LET read == DecodeIssueSymbolDirectoryMessage(EncodeIssueSymbolDirectoryMessage(message))
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

(* Every Limit Up Limit Down Price Band Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLimitUpLimitDownPriceBandMessage ==
    \A message \in CheckedLimitUpLimitDownPriceBandMessage :
        LET read == DecodeLimitUpLimitDownPriceBandMessage(EncodeLimitUpLimitDownPriceBandMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Wide Circuit Breaker Decline Level Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketWideCircuitBreakerDeclineLevelMessage ==
    \A message \in CheckedMarketWideCircuitBreakerDeclineLevelMessage :
        LET read == DecodeMarketWideCircuitBreakerDeclineLevelMessage(EncodeMarketWideCircuitBreakerDeclineLevelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Wide Circuit Breaker Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketWideCircuitBreakerStatusMessage ==
    \A message \in CheckedMarketWideCircuitBreakerStatusMessage :
        LET read == DecodeMarketWideCircuitBreakerStatusMessage(EncodeMarketWideCircuitBreakerStatusMessage(message))
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

(* Every Market Center Close Recap decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketCenterCloseRecap ==
    \A message \in CheckedMarketCenterCloseRecap :
        LET read == DecodeMarketCenterCloseRecap(EncodeMarketCenterCloseRecap(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Session Close Recap Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSessionCloseRecapMessage ==
    \A message \in CheckedSessionCloseRecapMessage :
        LET read == DecodeSessionCloseRecapMessage(EncodeSessionCloseRecapMessage(message))
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

(* Every Market Session Open Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketSessionOpenMessage ==
    \A message \in CheckedMarketSessionOpenMessage :
        LET read == DecodeMarketSessionOpenMessage(EncodeMarketSessionOpenMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Session Close Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketSessionCloseMessage ==
    \A message \in CheckedMarketSessionCloseMessage :
        LET read == DecodeMarketSessionCloseMessage(EncodeMarketSessionCloseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Transmissions Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfTransmissionsMessage ==
    \A message \in CheckedEndOfTransmissionsMessage :
        LET read == DecodeEndOfTransmissionsMessage(EncodeEndOfTransmissionsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Wipe Out Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteWipeOutMessage ==
    \A message \in CheckedQuoteWipeOutMessage :
        LET read == DecodeQuoteWipeOutMessage(EncodeQuoteWipeOutMessage(message))
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

(* Every Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMessage ==
    \A message \in CheckedMessage :
        LET read == DecodeMessage(EncodeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mold Udp 64 Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripMoldUdp64Packet ==
    \A message \in CheckedMoldUdp64Packet :
        LET read == DecodeMoldUdp64Packet(EncodeMoldUdp64Packet(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Nbbo Appendage Indicator is selected by the Nbbo Appendage Indicator it is written under *)
SelectsNbboAppendageIndicatorChoice ==
    \A message \in CheckedNbboAppendageIndicatorChoice :
        LET read == DecodeNbboAppendageIndicatorChoice(message.tag, EncodeNbboAppendageIndicatorChoice(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Nbbo Appendage Indicator is selected by the Nbbo Appendage Indicator it is written under *)
SelectsNbboAppendageIndicatorChoice2 ==
    \A message \in CheckedNbboAppendageIndicatorChoice2 :
        LET read == DecodeNbboAppendageIndicatorChoice2(message.tag, EncodeNbboAppendageIndicatorChoice2(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Nbbo Appendage Indicator is selected by the Nbbo Appendage Indicator it is written under *)
SelectsNbboAppendageIndicatorChoice3 ==
    \A message \in CheckedNbboAppendageIndicatorChoice3 :
        LET read == DecodeNbboAppendageIndicatorChoice3(message.tag, EncodeNbboAppendageIndicatorChoice3(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Bolo Appendage Indicator is selected by the Bolo Appendage Indicator it is written under *)
SelectsBoloAppendageIndicatorChoice ==
    \A message \in CheckedBoloAppendageIndicatorChoice :
        LET read == DecodeBoloAppendageIndicatorChoice(message.tag, EncodeBoloAppendageIndicatorChoice(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Nbbo Appendage Indicator is selected by the Nbbo Appendage Indicator it is written under *)
SelectsNbboAppendageIndicatorChoice4 ==
    \A message \in CheckedNbboAppendageIndicatorChoice4 :
        LET read == DecodeNbboAppendageIndicatorChoice4(message.tag, EncodeNbboAppendageIndicatorChoice4(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Finra Adf Mpid Appendage Indicator is selected by the Finra Adf Mpid Appendage Indicator it is written under *)
SelectsFinraAdfMpidAppendageIndicatorChoice ==
    \A message \in CheckedFinraAdfMpidAppendageIndicatorChoice :
        LET read == DecodeFinraAdfMpidAppendageIndicatorChoice(message.tag, EncodeFinraAdfMpidAppendageIndicatorChoice(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Bolo Appendage Indicator is selected by the Bolo Appendage Indicator it is written under *)
SelectsBoloAppendageIndicatorChoice2 ==
    \A message \in CheckedBoloAppendageIndicatorChoice2 :
        LET read == DecodeBoloAppendageIndicatorChoice2(message.tag, EncodeBoloAppendageIndicatorChoice2(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Bolo Appendage Indicator is selected by the Bolo Appendage Indicator it is written under *)
SelectsBoloAppendageIndicatorChoice3 ==
    \A message \in CheckedBoloAppendageIndicatorChoice3 :
        LET read == DecodeBoloAppendageIndicatorChoice3(message.tag, EncodeBoloAppendageIndicatorChoice3(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Bolo Appendage Indicator is selected by the Bolo Appendage Indicator it is written under *)
SelectsBoloAppendageIndicatorChoice4 ==
    \A message \in CheckedBoloAppendageIndicatorChoice4 :
        LET read == DecodeBoloAppendageIndicatorChoice4(message.tag, EncodeBoloAppendageIndicatorChoice4(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Quote Message Payload is selected by the Quote Message Type it is written under *)
SelectsQuoteMessagePayload ==
    \A message \in CheckedQuoteMessagePayload :
        LET read == DecodeQuoteMessagePayload(message.tag, EncodeQuoteMessagePayload(message))
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
