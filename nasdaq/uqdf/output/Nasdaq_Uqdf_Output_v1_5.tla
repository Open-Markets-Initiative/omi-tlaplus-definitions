---------------------- MODULE Nasdaq_Uqdf_Output_v1_5 ----------------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Output v1.5                                                    *)
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
(* Note: a Nbbo Appendage Indicator of any value but 50 or 51 carries none *)
(* of them.                                                                *)
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
(* Message Info: 26 bytes                                                  *)
(***************************************************************************)

MessageInfo ==
    [ marketCenterOriginatorId : Sample(1),
      subMarketCenterId        : Sample(1),
      sipTimestamp             : Sample(8),
      participantTimestamp     : Sample(8),
      participantToken         : Sample(8) ]

EncodeMessageInfo(message) ==
    message.marketCenterOriginatorId
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.participantTimestamp
        \o message.participantToken

DecodeMessageInfo(bytes) ==
    LET marketCenterOriginatorId == ReadBytes(bytes, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginatorId.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET participantTimestamp == ReadBytes(sipTimestamp.rest, 8) IN IF ~participantTimestamp.ok THEN Fail ELSE
    LET participantToken == ReadBytes(participantTimestamp.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         subMarketCenterId        |-> subMarketCenterId.value,
         sipTimestamp             |-> sipTimestamp.value,
         participantTimestamp     |-> participantTimestamp.value,
         participantToken         |-> participantToken.value ], participantToken.rest)

ZeroMessageInfo ==
    [ marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId        |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp             |-> [i \in 1 .. 8 |-> 0],
      participantTimestamp     |-> [i \in 1 .. 8 |-> 0],
      participantToken         |-> [i \in 1 .. 8 |-> 0] ]

(* Message Info at zero, then each field in turn at the values it is checked at *)
CheckedMessageInfo ==
    { ZeroMessageInfo }
        \cup { [ZeroMessageInfo EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo EXCEPT !.participantTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* Short Form National Bbo Appendage: 11 bytes                             *)
(***************************************************************************)

ShortFormNationalBboAppendage ==
    [ nbboQuoteCondition          : Sample(1),
      nationalBestBidMarketCenter : Sample(1),
      nationalBestBidPriceShort   : Sample(2),
      nationalBestBidSizeShort    : Sample(2),
      nationalBestAskMarketCenter : Sample(1),
      nationalBestAskPriceShort   : Sample(2),
      nationalBestAskSizeShort    : Sample(2) ]

EncodeShortFormNationalBboAppendage(message) ==
    message.nbboQuoteCondition
        \o message.nationalBestBidMarketCenter
        \o message.nationalBestBidPriceShort
        \o message.nationalBestBidSizeShort
        \o message.nationalBestAskMarketCenter
        \o message.nationalBestAskPriceShort
        \o message.nationalBestAskSizeShort

DecodeShortFormNationalBboAppendage(bytes) ==
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

ZeroShortFormNationalBboAppendage ==
    [ nbboQuoteCondition          |-> [i \in 1 .. 1 |-> 0],
      nationalBestBidMarketCenter |-> [i \in 1 .. 1 |-> 0],
      nationalBestBidPriceShort   |-> [i \in 1 .. 2 |-> 0],
      nationalBestBidSizeShort    |-> [i \in 1 .. 2 |-> 0],
      nationalBestAskMarketCenter |-> [i \in 1 .. 1 |-> 0],
      nationalBestAskPriceShort   |-> [i \in 1 .. 2 |-> 0],
      nationalBestAskSizeShort    |-> [i \in 1 .. 2 |-> 0] ]

(* Short Form National Bbo Appendage at zero, then each field in turn at the values it is checked at *)
CheckedShortFormNationalBboAppendage ==
    { ZeroShortFormNationalBboAppendage }
        \cup { [ZeroShortFormNationalBboAppendage EXCEPT !.nbboQuoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroShortFormNationalBboAppendage EXCEPT !.nationalBestBidMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroShortFormNationalBboAppendage EXCEPT !.nationalBestBidPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroShortFormNationalBboAppendage EXCEPT !.nationalBestBidSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroShortFormNationalBboAppendage EXCEPT !.nationalBestAskMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroShortFormNationalBboAppendage EXCEPT !.nationalBestAskPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroShortFormNationalBboAppendage EXCEPT !.nationalBestAskSizeShort = one] : one \in Sample(2) }

(***************************************************************************)
(* Long Form National Bbo Appendage: 27 bytes                              *)
(***************************************************************************)

LongFormNationalBboAppendage ==
    [ nbboQuoteCondition  : Sample(1),
      bestBidMarketCenter : Sample(1),
      bestBidPrice        : Sample(8),
      bestBidSize         : Sample(4),
      bestAskMarketCenter : Sample(1),
      bestAskPrice        : Sample(8),
      bestAskSize         : Sample(4) ]

EncodeLongFormNationalBboAppendage(message) ==
    message.nbboQuoteCondition
        \o message.bestBidMarketCenter
        \o message.bestBidPrice
        \o message.bestBidSize
        \o message.bestAskMarketCenter
        \o message.bestAskPrice
        \o message.bestAskSize

DecodeLongFormNationalBboAppendage(bytes) ==
    LET nbboQuoteCondition == ReadBytes(bytes, 1) IN IF ~nbboQuoteCondition.ok THEN Fail ELSE
    LET bestBidMarketCenter == ReadBytes(nbboQuoteCondition.rest, 1) IN IF ~bestBidMarketCenter.ok THEN Fail ELSE
    LET bestBidPrice == ReadBytes(bestBidMarketCenter.rest, 8) IN IF ~bestBidPrice.ok THEN Fail ELSE
    LET bestBidSize == ReadBytes(bestBidPrice.rest, 4) IN IF ~bestBidSize.ok THEN Fail ELSE
    LET bestAskMarketCenter == ReadBytes(bestBidSize.rest, 1) IN IF ~bestAskMarketCenter.ok THEN Fail ELSE
    LET bestAskPrice == ReadBytes(bestAskMarketCenter.rest, 8) IN IF ~bestAskPrice.ok THEN Fail ELSE
    LET bestAskSize == ReadBytes(bestAskPrice.rest, 4) IN IF ~bestAskSize.ok THEN Fail ELSE
    Ok([ nbboQuoteCondition  |-> nbboQuoteCondition.value,
         bestBidMarketCenter |-> bestBidMarketCenter.value,
         bestBidPrice        |-> bestBidPrice.value,
         bestBidSize         |-> bestBidSize.value,
         bestAskMarketCenter |-> bestAskMarketCenter.value,
         bestAskPrice        |-> bestAskPrice.value,
         bestAskSize         |-> bestAskSize.value ], bestAskSize.rest)

ZeroLongFormNationalBboAppendage ==
    [ nbboQuoteCondition  |-> [i \in 1 .. 1 |-> 0],
      bestBidMarketCenter |-> [i \in 1 .. 1 |-> 0],
      bestBidPrice        |-> [i \in 1 .. 8 |-> 0],
      bestBidSize         |-> [i \in 1 .. 4 |-> 0],
      bestAskMarketCenter |-> [i \in 1 .. 1 |-> 0],
      bestAskPrice        |-> [i \in 1 .. 8 |-> 0],
      bestAskSize         |-> [i \in 1 .. 4 |-> 0] ]

(* Long Form National Bbo Appendage at zero, then each field in turn at the values it is checked at *)
CheckedLongFormNationalBboAppendage ==
    { ZeroLongFormNationalBboAppendage }
        \cup { [ZeroLongFormNationalBboAppendage EXCEPT !.nbboQuoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroLongFormNationalBboAppendage EXCEPT !.bestBidMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroLongFormNationalBboAppendage EXCEPT !.bestBidPrice = one] : one \in Sample(8) }
        \cup { [ZeroLongFormNationalBboAppendage EXCEPT !.bestBidSize = one] : one \in Sample(4) }
        \cup { [ZeroLongFormNationalBboAppendage EXCEPT !.bestAskMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroLongFormNationalBboAppendage EXCEPT !.bestAskPrice = one] : one \in Sample(8) }
        \cup { [ZeroLongFormNationalBboAppendage EXCEPT !.bestAskSize = one] : one \in Sample(4) }

(***************************************************************************)
(* What Nbbo Appendage Indicator decides is present                        *)
(***************************************************************************)

ShortFormNationalBboAppendageCode == 50  \* "2"
LongFormNationalBboAppendageCode == 51  \* "3"
NbboAppendageIndicatorNoneCode == 0  \* 

NbboAppendageIndicatorChoice ==
    [ tag : {ShortFormNationalBboAppendageCode}, body : ShortFormNationalBboAppendage ]
        \cup [ tag : {LongFormNationalBboAppendageCode}, body : LongFormNationalBboAppendage ]
        \cup [ tag : {NbboAppendageIndicatorNoneCode}, body : {[empty |-> 0]} ]

EncodeNbboAppendageIndicatorChoice(message) ==
    CASE message.tag = ShortFormNationalBboAppendageCode -> EncodeShortFormNationalBboAppendage(message.body)
      [] message.tag = LongFormNationalBboAppendageCode -> EncodeLongFormNationalBboAppendage(message.body)
      [] OTHER -> << >>

DecodeNbboAppendageIndicatorChoice(tag, bytes) ==
    LET read ==
            CASE tag = ShortFormNationalBboAppendageCode -> DecodeShortFormNationalBboAppendage(bytes)
              [] tag = LongFormNationalBboAppendageCode -> DecodeLongFormNationalBboAppendage(bytes)
              [] OTHER -> Ok([empty |-> 0], bytes)
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroNbboAppendageIndicatorChoice == [tag |-> ShortFormNationalBboAppendageCode, body |-> ZeroShortFormNationalBboAppendage]

(* Each Nbbo Appendage Indicator in turn, at the values the message it names is checked at *)
CheckedNbboAppendageIndicatorChoice ==
    { [tag |-> ShortFormNationalBboAppendageCode, body |-> one] : one \in CheckedShortFormNationalBboAppendage }
        \cup { [tag |-> LongFormNationalBboAppendageCode, body |-> one] : one \in CheckedLongFormNationalBboAppendage }
        \cup { [tag |-> NbboAppendageIndicatorNoneCode, body |-> [empty |-> 0]] }

(***************************************************************************)
(* Quote Short Form Message                                                *)
(***************************************************************************)

QuoteShortFormMessage ==
    [ messageInfo                  : MessageInfo,
      symbolShort                  : Sample(5),
      bidPriceShort                : Sample(2),
      bidSizeShort                 : Sample(2),
      askPriceShort                : Sample(2),
      askSizeShort                 : Sample(2),
      quoteCondition               : Sample(1),
      sipGeneratedUpdate           : Sample(1),
      luldBboIndicator             : Sample(1),
      retailInterestIndicator      : Sample(1),
      luldNationalBboIndicator     : Sample(1),
      nbboAppendageIndicatorChoice : NbboAppendageIndicatorChoice ]

EncodeQuoteShortFormMessage(message) ==
    EncodeMessageInfo(message.messageInfo)
        \o message.symbolShort
        \o message.bidPriceShort
        \o message.bidSizeShort
        \o message.askPriceShort
        \o message.askSizeShort
        \o message.quoteCondition
        \o message.sipGeneratedUpdate
        \o message.luldBboIndicator
        \o message.retailInterestIndicator
        \o EncodeUIntBE(message.nbboAppendageIndicatorChoice.tag, 1)
        \o message.luldNationalBboIndicator
        \o EncodeNbboAppendageIndicatorChoice(message.nbboAppendageIndicatorChoice)

DecodeQuoteShortFormMessage(bytes) ==
    LET messageInfo == DecodeMessageInfo(bytes) IN IF ~messageInfo.ok THEN Fail ELSE
    LET symbolShort == ReadBytes(messageInfo.rest, 5) IN IF ~symbolShort.ok THEN Fail ELSE
    LET bidPriceShort == ReadBytes(symbolShort.rest, 2) IN IF ~bidPriceShort.ok THEN Fail ELSE
    LET bidSizeShort == ReadBytes(bidPriceShort.rest, 2) IN IF ~bidSizeShort.ok THEN Fail ELSE
    LET askPriceShort == ReadBytes(bidSizeShort.rest, 2) IN IF ~askPriceShort.ok THEN Fail ELSE
    LET askSizeShort == ReadBytes(askPriceShort.rest, 2) IN IF ~askSizeShort.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(askSizeShort.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET sipGeneratedUpdate == ReadBytes(quoteCondition.rest, 1) IN IF ~sipGeneratedUpdate.ok THEN Fail ELSE
    LET luldBboIndicator == ReadBytes(sipGeneratedUpdate.rest, 1) IN IF ~luldBboIndicator.ok THEN Fail ELSE
    LET retailInterestIndicator == ReadBytes(luldBboIndicator.rest, 1) IN IF ~retailInterestIndicator.ok THEN Fail ELSE
    LET nbboAppendageIndicator == ReadUIntBE(retailInterestIndicator.rest, 1) IN IF ~nbboAppendageIndicator.ok THEN Fail ELSE
    LET luldNationalBboIndicator == ReadBytes(nbboAppendageIndicator.rest, 1) IN IF ~luldNationalBboIndicator.ok THEN Fail ELSE
    LET nbboAppendageIndicatorChoice == DecodeNbboAppendageIndicatorChoice(nbboAppendageIndicator.value, luldNationalBboIndicator.rest) IN IF ~nbboAppendageIndicatorChoice.ok THEN Fail ELSE
    Ok([ messageInfo                  |-> messageInfo.value,
         symbolShort                  |-> symbolShort.value,
         bidPriceShort                |-> bidPriceShort.value,
         bidSizeShort                 |-> bidSizeShort.value,
         askPriceShort                |-> askPriceShort.value,
         askSizeShort                 |-> askSizeShort.value,
         quoteCondition               |-> quoteCondition.value,
         sipGeneratedUpdate           |-> sipGeneratedUpdate.value,
         luldBboIndicator             |-> luldBboIndicator.value,
         retailInterestIndicator      |-> retailInterestIndicator.value,
         luldNationalBboIndicator     |-> luldNationalBboIndicator.value,
         nbboAppendageIndicatorChoice |-> nbboAppendageIndicatorChoice.value ], nbboAppendageIndicatorChoice.rest)

ZeroQuoteShortFormMessage ==
    [ messageInfo                  |-> ZeroMessageInfo,
      symbolShort                  |-> [i \in 1 .. 5 |-> 0],
      bidPriceShort                |-> [i \in 1 .. 2 |-> 0],
      bidSizeShort                 |-> [i \in 1 .. 2 |-> 0],
      askPriceShort                |-> [i \in 1 .. 2 |-> 0],
      askSizeShort                 |-> [i \in 1 .. 2 |-> 0],
      quoteCondition               |-> [i \in 1 .. 1 |-> 0],
      sipGeneratedUpdate           |-> [i \in 1 .. 1 |-> 0],
      luldBboIndicator             |-> [i \in 1 .. 1 |-> 0],
      retailInterestIndicator      |-> [i \in 1 .. 1 |-> 0],
      luldNationalBboIndicator     |-> [i \in 1 .. 1 |-> 0],
      nbboAppendageIndicatorChoice |-> ZeroNbboAppendageIndicatorChoice ]

(* Quote Short Form Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteShortFormMessage ==
    { ZeroQuoteShortFormMessage }
        \cup { [ZeroQuoteShortFormMessage EXCEPT !.messageInfo = one] : one \in CheckedMessageInfo }
        \cup { [ZeroQuoteShortFormMessage EXCEPT !.symbolShort = one] : one \in Sample(5) }
        \cup { [ZeroQuoteShortFormMessage EXCEPT !.bidPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroQuoteShortFormMessage EXCEPT !.bidSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroQuoteShortFormMessage EXCEPT !.askPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroQuoteShortFormMessage EXCEPT !.askSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroQuoteShortFormMessage EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroQuoteShortFormMessage EXCEPT !.sipGeneratedUpdate = one] : one \in Sample(1) }
        \cup { [ZeroQuoteShortFormMessage EXCEPT !.luldBboIndicator = one] : one \in Sample(1) }
        \cup { [ZeroQuoteShortFormMessage EXCEPT !.retailInterestIndicator = one] : one \in Sample(1) }
        \cup { [ZeroQuoteShortFormMessage EXCEPT !.luldNationalBboIndicator = one] : one \in Sample(1) }
        \cup { [ZeroQuoteShortFormMessage EXCEPT !.nbboAppendageIndicatorChoice = one] : one \in CheckedNbboAppendageIndicatorChoice }

(***************************************************************************)
(* Message Info: 26 bytes                                                  *)
(***************************************************************************)

MessageInfo2 ==
    [ marketCenterOriginatorId : Sample(1),
      subMarketCenterId        : Sample(1),
      sipTimestamp             : Sample(8),
      participantTimestamp     : Sample(8),
      participantToken         : Sample(8) ]

EncodeMessageInfo2(message) ==
    message.marketCenterOriginatorId
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.participantTimestamp
        \o message.participantToken

DecodeMessageInfo2(bytes) ==
    LET marketCenterOriginatorId == ReadBytes(bytes, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginatorId.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET participantTimestamp == ReadBytes(sipTimestamp.rest, 8) IN IF ~participantTimestamp.ok THEN Fail ELSE
    LET participantToken == ReadBytes(participantTimestamp.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         subMarketCenterId        |-> subMarketCenterId.value,
         sipTimestamp             |-> sipTimestamp.value,
         participantTimestamp     |-> participantTimestamp.value,
         participantToken         |-> participantToken.value ], participantToken.rest)

ZeroMessageInfo2 ==
    [ marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId        |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp             |-> [i \in 1 .. 8 |-> 0],
      participantTimestamp     |-> [i \in 1 .. 8 |-> 0],
      participantToken         |-> [i \in 1 .. 8 |-> 0] ]

(* Message Info at zero, then each field in turn at the values it is checked at *)
CheckedMessageInfo2 ==
    { ZeroMessageInfo2 }
        \cup { [ZeroMessageInfo2 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo2 EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo2 EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo2 EXCEPT !.participantTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo2 EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* Short Form National Bbo Appendage: 11 bytes                             *)
(***************************************************************************)

ShortFormNationalBboAppendage2 ==
    [ nbboQuoteCondition          : Sample(1),
      nationalBestBidMarketCenter : Sample(1),
      nationalBestBidPriceShort   : Sample(2),
      nationalBestBidSizeShort    : Sample(2),
      nationalBestAskMarketCenter : Sample(1),
      nationalBestAskPriceShort   : Sample(2),
      nationalBestAskSizeShort    : Sample(2) ]

EncodeShortFormNationalBboAppendage2(message) ==
    message.nbboQuoteCondition
        \o message.nationalBestBidMarketCenter
        \o message.nationalBestBidPriceShort
        \o message.nationalBestBidSizeShort
        \o message.nationalBestAskMarketCenter
        \o message.nationalBestAskPriceShort
        \o message.nationalBestAskSizeShort

DecodeShortFormNationalBboAppendage2(bytes) ==
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

ZeroShortFormNationalBboAppendage2 ==
    [ nbboQuoteCondition          |-> [i \in 1 .. 1 |-> 0],
      nationalBestBidMarketCenter |-> [i \in 1 .. 1 |-> 0],
      nationalBestBidPriceShort   |-> [i \in 1 .. 2 |-> 0],
      nationalBestBidSizeShort    |-> [i \in 1 .. 2 |-> 0],
      nationalBestAskMarketCenter |-> [i \in 1 .. 1 |-> 0],
      nationalBestAskPriceShort   |-> [i \in 1 .. 2 |-> 0],
      nationalBestAskSizeShort    |-> [i \in 1 .. 2 |-> 0] ]

(* Short Form National Bbo Appendage at zero, then each field in turn at the values it is checked at *)
CheckedShortFormNationalBboAppendage2 ==
    { ZeroShortFormNationalBboAppendage2 }
        \cup { [ZeroShortFormNationalBboAppendage2 EXCEPT !.nbboQuoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroShortFormNationalBboAppendage2 EXCEPT !.nationalBestBidMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroShortFormNationalBboAppendage2 EXCEPT !.nationalBestBidPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroShortFormNationalBboAppendage2 EXCEPT !.nationalBestBidSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroShortFormNationalBboAppendage2 EXCEPT !.nationalBestAskMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroShortFormNationalBboAppendage2 EXCEPT !.nationalBestAskPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroShortFormNationalBboAppendage2 EXCEPT !.nationalBestAskSizeShort = one] : one \in Sample(2) }

(***************************************************************************)
(* Long Form National Bbo Appendage: 27 bytes                              *)
(***************************************************************************)

LongFormNationalBboAppendage2 ==
    [ nbboQuoteCondition  : Sample(1),
      bestBidMarketCenter : Sample(1),
      bestBidPrice        : Sample(8),
      bestBidSize         : Sample(4),
      bestAskMarketCenter : Sample(1),
      bestAskPrice        : Sample(8),
      bestAskSize         : Sample(4) ]

EncodeLongFormNationalBboAppendage2(message) ==
    message.nbboQuoteCondition
        \o message.bestBidMarketCenter
        \o message.bestBidPrice
        \o message.bestBidSize
        \o message.bestAskMarketCenter
        \o message.bestAskPrice
        \o message.bestAskSize

DecodeLongFormNationalBboAppendage2(bytes) ==
    LET nbboQuoteCondition == ReadBytes(bytes, 1) IN IF ~nbboQuoteCondition.ok THEN Fail ELSE
    LET bestBidMarketCenter == ReadBytes(nbboQuoteCondition.rest, 1) IN IF ~bestBidMarketCenter.ok THEN Fail ELSE
    LET bestBidPrice == ReadBytes(bestBidMarketCenter.rest, 8) IN IF ~bestBidPrice.ok THEN Fail ELSE
    LET bestBidSize == ReadBytes(bestBidPrice.rest, 4) IN IF ~bestBidSize.ok THEN Fail ELSE
    LET bestAskMarketCenter == ReadBytes(bestBidSize.rest, 1) IN IF ~bestAskMarketCenter.ok THEN Fail ELSE
    LET bestAskPrice == ReadBytes(bestAskMarketCenter.rest, 8) IN IF ~bestAskPrice.ok THEN Fail ELSE
    LET bestAskSize == ReadBytes(bestAskPrice.rest, 4) IN IF ~bestAskSize.ok THEN Fail ELSE
    Ok([ nbboQuoteCondition  |-> nbboQuoteCondition.value,
         bestBidMarketCenter |-> bestBidMarketCenter.value,
         bestBidPrice        |-> bestBidPrice.value,
         bestBidSize         |-> bestBidSize.value,
         bestAskMarketCenter |-> bestAskMarketCenter.value,
         bestAskPrice        |-> bestAskPrice.value,
         bestAskSize         |-> bestAskSize.value ], bestAskSize.rest)

ZeroLongFormNationalBboAppendage2 ==
    [ nbboQuoteCondition  |-> [i \in 1 .. 1 |-> 0],
      bestBidMarketCenter |-> [i \in 1 .. 1 |-> 0],
      bestBidPrice        |-> [i \in 1 .. 8 |-> 0],
      bestBidSize         |-> [i \in 1 .. 4 |-> 0],
      bestAskMarketCenter |-> [i \in 1 .. 1 |-> 0],
      bestAskPrice        |-> [i \in 1 .. 8 |-> 0],
      bestAskSize         |-> [i \in 1 .. 4 |-> 0] ]

(* Long Form National Bbo Appendage at zero, then each field in turn at the values it is checked at *)
CheckedLongFormNationalBboAppendage2 ==
    { ZeroLongFormNationalBboAppendage2 }
        \cup { [ZeroLongFormNationalBboAppendage2 EXCEPT !.nbboQuoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroLongFormNationalBboAppendage2 EXCEPT !.bestBidMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroLongFormNationalBboAppendage2 EXCEPT !.bestBidPrice = one] : one \in Sample(8) }
        \cup { [ZeroLongFormNationalBboAppendage2 EXCEPT !.bestBidSize = one] : one \in Sample(4) }
        \cup { [ZeroLongFormNationalBboAppendage2 EXCEPT !.bestAskMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroLongFormNationalBboAppendage2 EXCEPT !.bestAskPrice = one] : one \in Sample(8) }
        \cup { [ZeroLongFormNationalBboAppendage2 EXCEPT !.bestAskSize = one] : one \in Sample(4) }

(***************************************************************************)
(* What Nbbo Appendage Indicator decides is present                        *)
(***************************************************************************)

ShortFormNationalBboAppendageCode2 == 50  \* "2"
LongFormNationalBboAppendageCode2 == 51  \* "3"
NbboAppendageIndicatorNoneCode2 == 0  \* 

NbboAppendageIndicatorChoice2 ==
    [ tag : {ShortFormNationalBboAppendageCode2}, body : ShortFormNationalBboAppendage2 ]
        \cup [ tag : {LongFormNationalBboAppendageCode2}, body : LongFormNationalBboAppendage2 ]
        \cup [ tag : {NbboAppendageIndicatorNoneCode2}, body : {[empty |-> 0]} ]

EncodeNbboAppendageIndicatorChoice2(message) ==
    CASE message.tag = ShortFormNationalBboAppendageCode2 -> EncodeShortFormNationalBboAppendage2(message.body)
      [] message.tag = LongFormNationalBboAppendageCode2 -> EncodeLongFormNationalBboAppendage2(message.body)
      [] OTHER -> << >>

DecodeNbboAppendageIndicatorChoice2(tag, bytes) ==
    LET read ==
            CASE tag = ShortFormNationalBboAppendageCode2 -> DecodeShortFormNationalBboAppendage2(bytes)
              [] tag = LongFormNationalBboAppendageCode2 -> DecodeLongFormNationalBboAppendage2(bytes)
              [] OTHER -> Ok([empty |-> 0], bytes)
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroNbboAppendageIndicatorChoice2 == [tag |-> ShortFormNationalBboAppendageCode2, body |-> ZeroShortFormNationalBboAppendage2]

(* Each Nbbo Appendage Indicator in turn, at the values the message it names is checked at *)
CheckedNbboAppendageIndicatorChoice2 ==
    { [tag |-> ShortFormNationalBboAppendageCode2, body |-> one] : one \in CheckedShortFormNationalBboAppendage2 }
        \cup { [tag |-> LongFormNationalBboAppendageCode2, body |-> one] : one \in CheckedLongFormNationalBboAppendage2 }
        \cup { [tag |-> NbboAppendageIndicatorNoneCode2, body |-> [empty |-> 0]] }

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
(* Quote Long Form Message                                                 *)
(***************************************************************************)

QuoteLongFormMessage ==
    [ messageInfo                          : MessageInfo2,
      finraTimestamp                       : Sample(8),
      symbolLong                           : Sample(11),
      bidPrice                             : Sample(8),
      bidSize                              : Sample(4),
      askPrice                             : Sample(8),
      askSize                              : Sample(4),
      quoteCondition                       : Sample(1),
      sipGeneratedUpdate                   : Sample(1),
      luldBboIndicator                     : Sample(1),
      retailInterestIndicator              : Sample(1),
      luldNationalBboIndicator             : Sample(1),
      nbboAppendageIndicatorChoice         : NbboAppendageIndicatorChoice2,
      finraAdfMpidAppendageIndicatorChoice : FinraAdfMpidAppendageIndicatorChoice ]

EncodeQuoteLongFormMessage(message) ==
    EncodeMessageInfo2(message.messageInfo)
        \o message.finraTimestamp
        \o message.symbolLong
        \o message.bidPrice
        \o message.bidSize
        \o message.askPrice
        \o message.askSize
        \o message.quoteCondition
        \o message.sipGeneratedUpdate
        \o message.luldBboIndicator
        \o message.retailInterestIndicator
        \o EncodeUIntBE(message.nbboAppendageIndicatorChoice.tag, 1)
        \o message.luldNationalBboIndicator
        \o EncodeUIntBE(message.finraAdfMpidAppendageIndicatorChoice.tag, 1)
        \o EncodeNbboAppendageIndicatorChoice2(message.nbboAppendageIndicatorChoice)
        \o EncodeFinraAdfMpidAppendageIndicatorChoice(message.finraAdfMpidAppendageIndicatorChoice)

DecodeQuoteLongFormMessage(bytes) ==
    LET messageInfo == DecodeMessageInfo2(bytes) IN IF ~messageInfo.ok THEN Fail ELSE
    LET finraTimestamp == ReadBytes(messageInfo.rest, 8) IN IF ~finraTimestamp.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(finraTimestamp.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(symbolLong.rest, 8) IN IF ~bidPrice.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPrice.rest, 4) IN IF ~bidSize.ok THEN Fail ELSE
    LET askPrice == ReadBytes(bidSize.rest, 8) IN IF ~askPrice.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPrice.rest, 4) IN IF ~askSize.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(askSize.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET sipGeneratedUpdate == ReadBytes(quoteCondition.rest, 1) IN IF ~sipGeneratedUpdate.ok THEN Fail ELSE
    LET luldBboIndicator == ReadBytes(sipGeneratedUpdate.rest, 1) IN IF ~luldBboIndicator.ok THEN Fail ELSE
    LET retailInterestIndicator == ReadBytes(luldBboIndicator.rest, 1) IN IF ~retailInterestIndicator.ok THEN Fail ELSE
    LET nbboAppendageIndicator == ReadUIntBE(retailInterestIndicator.rest, 1) IN IF ~nbboAppendageIndicator.ok THEN Fail ELSE
    LET luldNationalBboIndicator == ReadBytes(nbboAppendageIndicator.rest, 1) IN IF ~luldNationalBboIndicator.ok THEN Fail ELSE
    LET finraAdfMpidAppendageIndicator == ReadUIntBE(luldNationalBboIndicator.rest, 1) IN IF ~finraAdfMpidAppendageIndicator.ok THEN Fail ELSE
    LET nbboAppendageIndicatorChoice == DecodeNbboAppendageIndicatorChoice2(nbboAppendageIndicator.value, finraAdfMpidAppendageIndicator.rest) IN IF ~nbboAppendageIndicatorChoice.ok THEN Fail ELSE
    LET finraAdfMpidAppendageIndicatorChoice == DecodeFinraAdfMpidAppendageIndicatorChoice(finraAdfMpidAppendageIndicator.value, nbboAppendageIndicatorChoice.rest) IN IF ~finraAdfMpidAppendageIndicatorChoice.ok THEN Fail ELSE
    Ok([ messageInfo                          |-> messageInfo.value,
         finraTimestamp                       |-> finraTimestamp.value,
         symbolLong                           |-> symbolLong.value,
         bidPrice                             |-> bidPrice.value,
         bidSize                              |-> bidSize.value,
         askPrice                             |-> askPrice.value,
         askSize                              |-> askSize.value,
         quoteCondition                       |-> quoteCondition.value,
         sipGeneratedUpdate                   |-> sipGeneratedUpdate.value,
         luldBboIndicator                     |-> luldBboIndicator.value,
         retailInterestIndicator              |-> retailInterestIndicator.value,
         luldNationalBboIndicator             |-> luldNationalBboIndicator.value,
         nbboAppendageIndicatorChoice         |-> nbboAppendageIndicatorChoice.value,
         finraAdfMpidAppendageIndicatorChoice |-> finraAdfMpidAppendageIndicatorChoice.value ], finraAdfMpidAppendageIndicatorChoice.rest)

ZeroQuoteLongFormMessage ==
    [ messageInfo                          |-> ZeroMessageInfo2,
      finraTimestamp                       |-> [i \in 1 .. 8 |-> 0],
      symbolLong                           |-> [i \in 1 .. 11 |-> 0],
      bidPrice                             |-> [i \in 1 .. 8 |-> 0],
      bidSize                              |-> [i \in 1 .. 4 |-> 0],
      askPrice                             |-> [i \in 1 .. 8 |-> 0],
      askSize                              |-> [i \in 1 .. 4 |-> 0],
      quoteCondition                       |-> [i \in 1 .. 1 |-> 0],
      sipGeneratedUpdate                   |-> [i \in 1 .. 1 |-> 0],
      luldBboIndicator                     |-> [i \in 1 .. 1 |-> 0],
      retailInterestIndicator              |-> [i \in 1 .. 1 |-> 0],
      luldNationalBboIndicator             |-> [i \in 1 .. 1 |-> 0],
      nbboAppendageIndicatorChoice         |-> ZeroNbboAppendageIndicatorChoice2,
      finraAdfMpidAppendageIndicatorChoice |-> ZeroFinraAdfMpidAppendageIndicatorChoice ]

(* Quote Long Form Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteLongFormMessage ==
    { ZeroQuoteLongFormMessage }
        \cup { [ZeroQuoteLongFormMessage EXCEPT !.messageInfo = one] : one \in CheckedMessageInfo2 }
        \cup { [ZeroQuoteLongFormMessage EXCEPT !.finraTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroQuoteLongFormMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroQuoteLongFormMessage EXCEPT !.bidPrice = one] : one \in Sample(8) }
        \cup { [ZeroQuoteLongFormMessage EXCEPT !.bidSize = one] : one \in Sample(4) }
        \cup { [ZeroQuoteLongFormMessage EXCEPT !.askPrice = one] : one \in Sample(8) }
        \cup { [ZeroQuoteLongFormMessage EXCEPT !.askSize = one] : one \in Sample(4) }
        \cup { [ZeroQuoteLongFormMessage EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroQuoteLongFormMessage EXCEPT !.sipGeneratedUpdate = one] : one \in Sample(1) }
        \cup { [ZeroQuoteLongFormMessage EXCEPT !.luldBboIndicator = one] : one \in Sample(1) }
        \cup { [ZeroQuoteLongFormMessage EXCEPT !.retailInterestIndicator = one] : one \in Sample(1) }
        \cup { [ZeroQuoteLongFormMessage EXCEPT !.luldNationalBboIndicator = one] : one \in Sample(1) }
        \cup { [ZeroQuoteLongFormMessage EXCEPT !.nbboAppendageIndicatorChoice = one] : one \in CheckedNbboAppendageIndicatorChoice2 }
        \cup { [ZeroQuoteLongFormMessage EXCEPT !.finraAdfMpidAppendageIndicatorChoice = one] : one \in CheckedFinraAdfMpidAppendageIndicatorChoice }

(***************************************************************************)
(* Message Info: 26 bytes                                                  *)
(***************************************************************************)

MessageInfo3 ==
    [ marketCenterOriginatorId : Sample(1),
      subMarketCenterId        : Sample(1),
      sipTimestamp             : Sample(8),
      participantTimestamp     : Sample(8),
      participantToken         : Sample(8) ]

EncodeMessageInfo3(message) ==
    message.marketCenterOriginatorId
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.participantTimestamp
        \o message.participantToken

DecodeMessageInfo3(bytes) ==
    LET marketCenterOriginatorId == ReadBytes(bytes, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginatorId.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET participantTimestamp == ReadBytes(sipTimestamp.rest, 8) IN IF ~participantTimestamp.ok THEN Fail ELSE
    LET participantToken == ReadBytes(participantTimestamp.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         subMarketCenterId        |-> subMarketCenterId.value,
         sipTimestamp             |-> sipTimestamp.value,
         participantTimestamp     |-> participantTimestamp.value,
         participantToken         |-> participantToken.value ], participantToken.rest)

ZeroMessageInfo3 ==
    [ marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId        |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp             |-> [i \in 1 .. 8 |-> 0],
      participantTimestamp     |-> [i \in 1 .. 8 |-> 0],
      participantToken         |-> [i \in 1 .. 8 |-> 0] ]

(* Message Info at zero, then each field in turn at the values it is checked at *)
CheckedMessageInfo3 ==
    { ZeroMessageInfo3 }
        \cup { [ZeroMessageInfo3 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo3 EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo3 EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo3 EXCEPT !.participantTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo3 EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* Finra Adf Market Participant Quotation Message: 74 bytes                *)
(***************************************************************************)

FinraAdfMarketParticipantQuotationMessage ==
    [ messageInfo            : MessageInfo3,
      finraTimestamp         : Sample(8),
      symbolLong             : Sample(11),
      bidPrice               : Sample(8),
      bidSize                : Sample(4),
      askPrice               : Sample(8),
      askSize                : Sample(4),
      quoteCondition         : Sample(1),
      finraMarketParticipant : Sample(4) ]

EncodeFinraAdfMarketParticipantQuotationMessage(message) ==
    EncodeMessageInfo3(message.messageInfo)
        \o message.finraTimestamp
        \o message.symbolLong
        \o message.bidPrice
        \o message.bidSize
        \o message.askPrice
        \o message.askSize
        \o message.quoteCondition
        \o message.finraMarketParticipant

DecodeFinraAdfMarketParticipantQuotationMessage(bytes) ==
    LET messageInfo == DecodeMessageInfo3(bytes) IN IF ~messageInfo.ok THEN Fail ELSE
    LET finraTimestamp == ReadBytes(messageInfo.rest, 8) IN IF ~finraTimestamp.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(finraTimestamp.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(symbolLong.rest, 8) IN IF ~bidPrice.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPrice.rest, 4) IN IF ~bidSize.ok THEN Fail ELSE
    LET askPrice == ReadBytes(bidSize.rest, 8) IN IF ~askPrice.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPrice.rest, 4) IN IF ~askSize.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(askSize.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET finraMarketParticipant == ReadBytes(quoteCondition.rest, 4) IN IF ~finraMarketParticipant.ok THEN Fail ELSE
    Ok([ messageInfo            |-> messageInfo.value,
         finraTimestamp         |-> finraTimestamp.value,
         symbolLong             |-> symbolLong.value,
         bidPrice               |-> bidPrice.value,
         bidSize                |-> bidSize.value,
         askPrice               |-> askPrice.value,
         askSize                |-> askSize.value,
         quoteCondition         |-> quoteCondition.value,
         finraMarketParticipant |-> finraMarketParticipant.value ], finraMarketParticipant.rest)

ZeroFinraAdfMarketParticipantQuotationMessage ==
    [ messageInfo            |-> ZeroMessageInfo3,
      finraTimestamp         |-> [i \in 1 .. 8 |-> 0],
      symbolLong             |-> [i \in 1 .. 11 |-> 0],
      bidPrice               |-> [i \in 1 .. 8 |-> 0],
      bidSize                |-> [i \in 1 .. 4 |-> 0],
      askPrice               |-> [i \in 1 .. 8 |-> 0],
      askSize                |-> [i \in 1 .. 4 |-> 0],
      quoteCondition         |-> [i \in 1 .. 1 |-> 0],
      finraMarketParticipant |-> [i \in 1 .. 4 |-> 0] ]

(* Finra Adf Market Participant Quotation Message at zero, then each field in turn at the values it is checked at *)
CheckedFinraAdfMarketParticipantQuotationMessage ==
    { ZeroFinraAdfMarketParticipantQuotationMessage }
        \cup { [ZeroFinraAdfMarketParticipantQuotationMessage EXCEPT !.messageInfo = one] : one \in CheckedMessageInfo3 }
        \cup { [ZeroFinraAdfMarketParticipantQuotationMessage EXCEPT !.finraTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroFinraAdfMarketParticipantQuotationMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroFinraAdfMarketParticipantQuotationMessage EXCEPT !.bidPrice = one] : one \in Sample(8) }
        \cup { [ZeroFinraAdfMarketParticipantQuotationMessage EXCEPT !.bidSize = one] : one \in Sample(4) }
        \cup { [ZeroFinraAdfMarketParticipantQuotationMessage EXCEPT !.askPrice = one] : one \in Sample(8) }
        \cup { [ZeroFinraAdfMarketParticipantQuotationMessage EXCEPT !.askSize = one] : one \in Sample(4) }
        \cup { [ZeroFinraAdfMarketParticipantQuotationMessage EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroFinraAdfMarketParticipantQuotationMessage EXCEPT !.finraMarketParticipant = one] : one \in Sample(4) }

(***************************************************************************)
(* Quote Message Payload, selected by Quote Message Type                   *)
(***************************************************************************)

QuoteShortFormMessageCode == 69  \* "E"
QuoteLongFormMessageCode == 70  \* "F"
FinraAdfMarketParticipantQuotationMessageCode == 77  \* "M"

QuoteMessagePayload ==
    [ tag : {QuoteShortFormMessageCode}, body : QuoteShortFormMessage ]
        \cup [ tag : {QuoteLongFormMessageCode}, body : QuoteLongFormMessage ]
        \cup [ tag : {FinraAdfMarketParticipantQuotationMessageCode}, body : FinraAdfMarketParticipantQuotationMessage ]

EncodeQuoteMessagePayload(message) ==
    CASE message.tag = QuoteShortFormMessageCode -> EncodeQuoteShortFormMessage(message.body)
      [] message.tag = QuoteLongFormMessageCode -> EncodeQuoteLongFormMessage(message.body)
      [] message.tag = FinraAdfMarketParticipantQuotationMessageCode -> EncodeFinraAdfMarketParticipantQuotationMessage(message.body)

DecodeQuoteMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = QuoteShortFormMessageCode -> DecodeQuoteShortFormMessage(bytes)
              [] tag = QuoteLongFormMessageCode -> DecodeQuoteLongFormMessage(bytes)
              [] tag = FinraAdfMarketParticipantQuotationMessageCode -> DecodeFinraAdfMarketParticipantQuotationMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroQuoteMessagePayload == [tag |-> QuoteShortFormMessageCode, body |-> ZeroQuoteShortFormMessage]

(* Each Quote Message Payload in turn, at the values the message it names is checked at *)
CheckedQuoteMessagePayload ==
    { [tag |-> QuoteShortFormMessageCode, body |-> one] : one \in CheckedQuoteShortFormMessage }
        \cup { [tag |-> QuoteLongFormMessageCode, body |-> one] : one \in CheckedQuoteLongFormMessage }
        \cup { [tag |-> FinraAdfMarketParticipantQuotationMessageCode, body |-> one] : one \in CheckedFinraAdfMarketParticipantQuotationMessage }

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
(* Message Info: 26 bytes                                                  *)
(***************************************************************************)

MessageInfo4 ==
    [ marketCenterOriginatorId : Sample(1),
      subMarketCenterId        : Sample(1),
      sipTimestamp             : Sample(8),
      participantTimestamp     : Sample(8),
      participantToken         : Sample(8) ]

EncodeMessageInfo4(message) ==
    message.marketCenterOriginatorId
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.participantTimestamp
        \o message.participantToken

DecodeMessageInfo4(bytes) ==
    LET marketCenterOriginatorId == ReadBytes(bytes, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginatorId.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET participantTimestamp == ReadBytes(sipTimestamp.rest, 8) IN IF ~participantTimestamp.ok THEN Fail ELSE
    LET participantToken == ReadBytes(participantTimestamp.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         subMarketCenterId        |-> subMarketCenterId.value,
         sipTimestamp             |-> sipTimestamp.value,
         participantTimestamp     |-> participantTimestamp.value,
         participantToken         |-> participantToken.value ], participantToken.rest)

ZeroMessageInfo4 ==
    [ marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId        |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp             |-> [i \in 1 .. 8 |-> 0],
      participantTimestamp     |-> [i \in 1 .. 8 |-> 0],
      participantToken         |-> [i \in 1 .. 8 |-> 0] ]

(* Message Info at zero, then each field in turn at the values it is checked at *)
CheckedMessageInfo4 ==
    { ZeroMessageInfo4 }
        \cup { [ZeroMessageInfo4 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo4 EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo4 EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo4 EXCEPT !.participantTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo4 EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* General Administrative Message                                          *)
(***************************************************************************)

GeneralAdministrativeMessage ==
    [ messageInfo : MessageInfo4,
      text        : SampleBytes ]

EncodeGeneralAdministrativeMessage(message) ==
    EncodeMessageInfo4(message.messageInfo)
        \o EncodeUIntBE(Len(message.text), 2)
        \o message.text

DecodeGeneralAdministrativeMessage(bytes) ==
    LET messageInfo == DecodeMessageInfo4(bytes) IN IF ~messageInfo.ok THEN Fail ELSE
    LET textLength == ReadUIntBE(messageInfo.rest, 2) IN IF ~textLength.ok THEN Fail ELSE
    LET text == ReadBytes(textLength.rest, textLength.value) IN IF ~text.ok THEN Fail ELSE
    Ok([ messageInfo |-> messageInfo.value,
         text        |-> text.value ], text.rest)

ZeroGeneralAdministrativeMessage ==
    [ messageInfo |-> ZeroMessageInfo4,
      text        |-> << >> ]

(* General Administrative Message at zero, then each field in turn at the values it is checked at *)
CheckedGeneralAdministrativeMessage ==
    { ZeroGeneralAdministrativeMessage }
        \cup { [ZeroGeneralAdministrativeMessage EXCEPT !.messageInfo = one] : one \in CheckedMessageInfo4 }
        \cup { [ZeroGeneralAdministrativeMessage EXCEPT !.text = one] : one \in SampleBytes }

(***************************************************************************)
(* Message Info: 26 bytes                                                  *)
(***************************************************************************)

MessageInfo5 ==
    [ marketCenterOriginatorId : Sample(1),
      subMarketCenterId        : Sample(1),
      sipTimestamp             : Sample(8),
      participantTimestamp     : Sample(8),
      participantToken         : Sample(8) ]

EncodeMessageInfo5(message) ==
    message.marketCenterOriginatorId
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.participantTimestamp
        \o message.participantToken

DecodeMessageInfo5(bytes) ==
    LET marketCenterOriginatorId == ReadBytes(bytes, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginatorId.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET participantTimestamp == ReadBytes(sipTimestamp.rest, 8) IN IF ~participantTimestamp.ok THEN Fail ELSE
    LET participantToken == ReadBytes(participantTimestamp.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         subMarketCenterId        |-> subMarketCenterId.value,
         sipTimestamp             |-> sipTimestamp.value,
         participantTimestamp     |-> participantTimestamp.value,
         participantToken         |-> participantToken.value ], participantToken.rest)

ZeroMessageInfo5 ==
    [ marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId        |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp             |-> [i \in 1 .. 8 |-> 0],
      participantTimestamp     |-> [i \in 1 .. 8 |-> 0],
      participantToken         |-> [i \in 1 .. 8 |-> 0] ]

(* Message Info at zero, then each field in turn at the values it is checked at *)
CheckedMessageInfo5 ==
    { ZeroMessageInfo5 }
        \cup { [ZeroMessageInfo5 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo5 EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo5 EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo5 EXCEPT !.participantTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo5 EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* Cross Sro Trading Action Message: 56 bytes                              *)
(***************************************************************************)

CrossSroTradingActionMessage ==
    [ messageInfo                 : MessageInfo5,
      symbolLong                  : Sample(11),
      tradingActionCode           : Sample(1),
      tradingActionSequenceNumber : Sample(4),
      actionTimestamp             : Sample(8),
      tradingActionReason         : Sample(6) ]

EncodeCrossSroTradingActionMessage(message) ==
    EncodeMessageInfo5(message.messageInfo)
        \o message.symbolLong
        \o message.tradingActionCode
        \o message.tradingActionSequenceNumber
        \o message.actionTimestamp
        \o message.tradingActionReason

DecodeCrossSroTradingActionMessage(bytes) ==
    LET messageInfo == DecodeMessageInfo5(bytes) IN IF ~messageInfo.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(messageInfo.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET tradingActionCode == ReadBytes(symbolLong.rest, 1) IN IF ~tradingActionCode.ok THEN Fail ELSE
    LET tradingActionSequenceNumber == ReadBytes(tradingActionCode.rest, 4) IN IF ~tradingActionSequenceNumber.ok THEN Fail ELSE
    LET actionTimestamp == ReadBytes(tradingActionSequenceNumber.rest, 8) IN IF ~actionTimestamp.ok THEN Fail ELSE
    LET tradingActionReason == ReadBytes(actionTimestamp.rest, 6) IN IF ~tradingActionReason.ok THEN Fail ELSE
    Ok([ messageInfo                 |-> messageInfo.value,
         symbolLong                  |-> symbolLong.value,
         tradingActionCode           |-> tradingActionCode.value,
         tradingActionSequenceNumber |-> tradingActionSequenceNumber.value,
         actionTimestamp             |-> actionTimestamp.value,
         tradingActionReason         |-> tradingActionReason.value ], tradingActionReason.rest)

ZeroCrossSroTradingActionMessage ==
    [ messageInfo                 |-> ZeroMessageInfo5,
      symbolLong                  |-> [i \in 1 .. 11 |-> 0],
      tradingActionCode           |-> [i \in 1 .. 1 |-> 0],
      tradingActionSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      actionTimestamp             |-> [i \in 1 .. 8 |-> 0],
      tradingActionReason         |-> [i \in 1 .. 6 |-> 0] ]

(* Cross Sro Trading Action Message at zero, then each field in turn at the values it is checked at *)
CheckedCrossSroTradingActionMessage ==
    { ZeroCrossSroTradingActionMessage }
        \cup { [ZeroCrossSroTradingActionMessage EXCEPT !.messageInfo = one] : one \in CheckedMessageInfo5 }
        \cup { [ZeroCrossSroTradingActionMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroCrossSroTradingActionMessage EXCEPT !.tradingActionCode = one] : one \in Sample(1) }
        \cup { [ZeroCrossSroTradingActionMessage EXCEPT !.tradingActionSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroCrossSroTradingActionMessage EXCEPT !.actionTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroCrossSroTradingActionMessage EXCEPT !.tradingActionReason = one] : one \in Sample(6) }

(***************************************************************************)
(* Message Info: 26 bytes                                                  *)
(***************************************************************************)

MessageInfo6 ==
    [ marketCenterOriginatorId : Sample(1),
      subMarketCenterId        : Sample(1),
      sipTimestamp             : Sample(8),
      participantTimestamp     : Sample(8),
      participantToken         : Sample(8) ]

EncodeMessageInfo6(message) ==
    message.marketCenterOriginatorId
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.participantTimestamp
        \o message.participantToken

DecodeMessageInfo6(bytes) ==
    LET marketCenterOriginatorId == ReadBytes(bytes, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginatorId.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET participantTimestamp == ReadBytes(sipTimestamp.rest, 8) IN IF ~participantTimestamp.ok THEN Fail ELSE
    LET participantToken == ReadBytes(participantTimestamp.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         subMarketCenterId        |-> subMarketCenterId.value,
         sipTimestamp             |-> sipTimestamp.value,
         participantTimestamp     |-> participantTimestamp.value,
         participantToken         |-> participantToken.value ], participantToken.rest)

ZeroMessageInfo6 ==
    [ marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId        |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp             |-> [i \in 1 .. 8 |-> 0],
      participantTimestamp     |-> [i \in 1 .. 8 |-> 0],
      participantToken         |-> [i \in 1 .. 8 |-> 0] ]

(* Message Info at zero, then each field in turn at the values it is checked at *)
CheckedMessageInfo6 ==
    { ZeroMessageInfo6 }
        \cup { [ZeroMessageInfo6 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo6 EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo6 EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo6 EXCEPT !.participantTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo6 EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* Market Center Trading Action Message: 47 bytes                          *)
(***************************************************************************)

MarketCenterTradingActionMessage ==
    [ messageInfo            : MessageInfo6,
      symbolLong             : Sample(11),
      tradingActionCode      : Sample(1),
      actionTimestamp        : Sample(8),
      marketCenterIdentifier : Sample(1) ]

EncodeMarketCenterTradingActionMessage(message) ==
    EncodeMessageInfo6(message.messageInfo)
        \o message.symbolLong
        \o message.tradingActionCode
        \o message.actionTimestamp
        \o message.marketCenterIdentifier

DecodeMarketCenterTradingActionMessage(bytes) ==
    LET messageInfo == DecodeMessageInfo6(bytes) IN IF ~messageInfo.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(messageInfo.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET tradingActionCode == ReadBytes(symbolLong.rest, 1) IN IF ~tradingActionCode.ok THEN Fail ELSE
    LET actionTimestamp == ReadBytes(tradingActionCode.rest, 8) IN IF ~actionTimestamp.ok THEN Fail ELSE
    LET marketCenterIdentifier == ReadBytes(actionTimestamp.rest, 1) IN IF ~marketCenterIdentifier.ok THEN Fail ELSE
    Ok([ messageInfo            |-> messageInfo.value,
         symbolLong             |-> symbolLong.value,
         tradingActionCode      |-> tradingActionCode.value,
         actionTimestamp        |-> actionTimestamp.value,
         marketCenterIdentifier |-> marketCenterIdentifier.value ], marketCenterIdentifier.rest)

ZeroMarketCenterTradingActionMessage ==
    [ messageInfo            |-> ZeroMessageInfo6,
      symbolLong             |-> [i \in 1 .. 11 |-> 0],
      tradingActionCode      |-> [i \in 1 .. 1 |-> 0],
      actionTimestamp        |-> [i \in 1 .. 8 |-> 0],
      marketCenterIdentifier |-> [i \in 1 .. 1 |-> 0] ]

(* Market Center Trading Action Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketCenterTradingActionMessage ==
    { ZeroMarketCenterTradingActionMessage }
        \cup { [ZeroMarketCenterTradingActionMessage EXCEPT !.messageInfo = one] : one \in CheckedMessageInfo6 }
        \cup { [ZeroMarketCenterTradingActionMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroMarketCenterTradingActionMessage EXCEPT !.tradingActionCode = one] : one \in Sample(1) }
        \cup { [ZeroMarketCenterTradingActionMessage EXCEPT !.actionTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMarketCenterTradingActionMessage EXCEPT !.marketCenterIdentifier = one] : one \in Sample(1) }

(***************************************************************************)
(* Message Info: 26 bytes                                                  *)
(***************************************************************************)

MessageInfo7 ==
    [ marketCenterOriginatorId : Sample(1),
      subMarketCenterId        : Sample(1),
      sipTimestamp             : Sample(8),
      participantTimestamp     : Sample(8),
      participantToken         : Sample(8) ]

EncodeMessageInfo7(message) ==
    message.marketCenterOriginatorId
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.participantTimestamp
        \o message.participantToken

DecodeMessageInfo7(bytes) ==
    LET marketCenterOriginatorId == ReadBytes(bytes, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginatorId.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET participantTimestamp == ReadBytes(sipTimestamp.rest, 8) IN IF ~participantTimestamp.ok THEN Fail ELSE
    LET participantToken == ReadBytes(participantTimestamp.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         subMarketCenterId        |-> subMarketCenterId.value,
         sipTimestamp             |-> sipTimestamp.value,
         participantTimestamp     |-> participantTimestamp.value,
         participantToken         |-> participantToken.value ], participantToken.rest)

ZeroMessageInfo7 ==
    [ marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId        |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp             |-> [i \in 1 .. 8 |-> 0],
      participantTimestamp     |-> [i \in 1 .. 8 |-> 0],
      participantToken         |-> [i \in 1 .. 8 |-> 0] ]

(* Message Info at zero, then each field in turn at the values it is checked at *)
CheckedMessageInfo7 ==
    { ZeroMessageInfo7 }
        \cup { [ZeroMessageInfo7 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo7 EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo7 EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo7 EXCEPT !.participantTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo7 EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* Issue Symbol Directory Message: 87 bytes                                *)
(***************************************************************************)

IssueSymbolDirectoryMessage ==
    [ messageInfo                 : MessageInfo7,
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
    EncodeMessageInfo7(message.messageInfo)
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
    LET messageInfo == DecodeMessageInfo7(bytes) IN IF ~messageInfo.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(messageInfo.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET oldSymbol == ReadBytes(symbolLong.rest, 11) IN IF ~oldSymbol.ok THEN Fail ELSE
    LET issueName == ReadBytes(oldSymbol.rest, 30) IN IF ~issueName.ok THEN Fail ELSE
    LET issueType == ReadBytes(issueName.rest, 1) IN IF ~issueType.ok THEN Fail ELSE
    LET issueSubtype == ReadBytes(issueType.rest, 2) IN IF ~issueSubtype.ok THEN Fail ELSE
    LET marketTier == ReadBytes(issueSubtype.rest, 1) IN IF ~marketTier.ok THEN Fail ELSE
    LET authenticity == ReadBytes(marketTier.rest, 1) IN IF ~authenticity.ok THEN Fail ELSE
    LET shortSaleThresholdIndicator == ReadBytes(authenticity.rest, 1) IN IF ~shortSaleThresholdIndicator.ok THEN Fail ELSE
    LET roundLotSize == ReadBytes(shortSaleThresholdIndicator.rest, 2) IN IF ~roundLotSize.ok THEN Fail ELSE
    LET financialStatusIndicator == ReadBytes(roundLotSize.rest, 1) IN IF ~financialStatusIndicator.ok THEN Fail ELSE
    Ok([ messageInfo                 |-> messageInfo.value,
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
    [ messageInfo                 |-> ZeroMessageInfo7,
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
        \cup { [ZeroIssueSymbolDirectoryMessage EXCEPT !.messageInfo = one] : one \in CheckedMessageInfo7 }
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
(* Message Info: 26 bytes                                                  *)
(***************************************************************************)

MessageInfo8 ==
    [ marketCenterOriginatorId : Sample(1),
      subMarketCenterId        : Sample(1),
      sipTimestamp             : Sample(8),
      participantTimestamp     : Sample(8),
      participantToken         : Sample(8) ]

EncodeMessageInfo8(message) ==
    message.marketCenterOriginatorId
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.participantTimestamp
        \o message.participantToken

DecodeMessageInfo8(bytes) ==
    LET marketCenterOriginatorId == ReadBytes(bytes, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginatorId.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET participantTimestamp == ReadBytes(sipTimestamp.rest, 8) IN IF ~participantTimestamp.ok THEN Fail ELSE
    LET participantToken == ReadBytes(participantTimestamp.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         subMarketCenterId        |-> subMarketCenterId.value,
         sipTimestamp             |-> sipTimestamp.value,
         participantTimestamp     |-> participantTimestamp.value,
         participantToken         |-> participantToken.value ], participantToken.rest)

ZeroMessageInfo8 ==
    [ marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId        |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp             |-> [i \in 1 .. 8 |-> 0],
      participantTimestamp     |-> [i \in 1 .. 8 |-> 0],
      participantToken         |-> [i \in 1 .. 8 |-> 0] ]

(* Message Info at zero, then each field in turn at the values it is checked at *)
CheckedMessageInfo8 ==
    { ZeroMessageInfo8 }
        \cup { [ZeroMessageInfo8 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo8 EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo8 EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo8 EXCEPT !.participantTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo8 EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* Regulation Sho Short Sale Price Test Restricted Indicator Message: 32   *)
(* bytes                                                                   *)
(***************************************************************************)

RegulationShoShortSalePriceTestRestrictedIndicatorMessage ==
    [ messageInfo  : MessageInfo8,
      symbolShort  : Sample(5),
      regShoAction : Sample(1) ]

EncodeRegulationShoShortSalePriceTestRestrictedIndicatorMessage(message) ==
    EncodeMessageInfo8(message.messageInfo)
        \o message.symbolShort
        \o message.regShoAction

DecodeRegulationShoShortSalePriceTestRestrictedIndicatorMessage(bytes) ==
    LET messageInfo == DecodeMessageInfo8(bytes) IN IF ~messageInfo.ok THEN Fail ELSE
    LET symbolShort == ReadBytes(messageInfo.rest, 5) IN IF ~symbolShort.ok THEN Fail ELSE
    LET regShoAction == ReadBytes(symbolShort.rest, 1) IN IF ~regShoAction.ok THEN Fail ELSE
    Ok([ messageInfo  |-> messageInfo.value,
         symbolShort  |-> symbolShort.value,
         regShoAction |-> regShoAction.value ], regShoAction.rest)

ZeroRegulationShoShortSalePriceTestRestrictedIndicatorMessage ==
    [ messageInfo  |-> ZeroMessageInfo8,
      symbolShort  |-> [i \in 1 .. 5 |-> 0],
      regShoAction |-> [i \in 1 .. 1 |-> 0] ]

(* Regulation Sho Short Sale Price Test Restricted Indicator Message at zero, then each field in turn at the values it is checked at *)
CheckedRegulationShoShortSalePriceTestRestrictedIndicatorMessage ==
    { ZeroRegulationShoShortSalePriceTestRestrictedIndicatorMessage }
        \cup { [ZeroRegulationShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.messageInfo = one] : one \in CheckedMessageInfo8 }
        \cup { [ZeroRegulationShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.symbolShort = one] : one \in Sample(5) }
        \cup { [ZeroRegulationShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.regShoAction = one] : one \in Sample(1) }

(***************************************************************************)
(* Message Info: 26 bytes                                                  *)
(***************************************************************************)

MessageInfo9 ==
    [ marketCenterOriginatorId : Sample(1),
      subMarketCenterId        : Sample(1),
      sipTimestamp             : Sample(8),
      participantTimestamp     : Sample(8),
      participantToken         : Sample(8) ]

EncodeMessageInfo9(message) ==
    message.marketCenterOriginatorId
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.participantTimestamp
        \o message.participantToken

DecodeMessageInfo9(bytes) ==
    LET marketCenterOriginatorId == ReadBytes(bytes, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginatorId.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET participantTimestamp == ReadBytes(sipTimestamp.rest, 8) IN IF ~participantTimestamp.ok THEN Fail ELSE
    LET participantToken == ReadBytes(participantTimestamp.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         subMarketCenterId        |-> subMarketCenterId.value,
         sipTimestamp             |-> sipTimestamp.value,
         participantTimestamp     |-> participantTimestamp.value,
         participantToken         |-> participantToken.value ], participantToken.rest)

ZeroMessageInfo9 ==
    [ marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId        |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp             |-> [i \in 1 .. 8 |-> 0],
      participantTimestamp     |-> [i \in 1 .. 8 |-> 0],
      participantToken         |-> [i \in 1 .. 8 |-> 0] ]

(* Message Info at zero, then each field in turn at the values it is checked at *)
CheckedMessageInfo9 ==
    { ZeroMessageInfo9 }
        \cup { [ZeroMessageInfo9 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo9 EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo9 EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo9 EXCEPT !.participantTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo9 EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* Limit Up Limit Down Price Band Message: 62 bytes                        *)
(***************************************************************************)

LimitUpLimitDownPriceBandMessage ==
    [ messageInfo            : MessageInfo9,
      symbolLong             : Sample(11),
      luldPriceBandIndicator : Sample(1),
      luldTimestamp          : Sample(8),
      limitDownPrice         : Sample(8),
      limitUpPrice           : Sample(8) ]

EncodeLimitUpLimitDownPriceBandMessage(message) ==
    EncodeMessageInfo9(message.messageInfo)
        \o message.symbolLong
        \o message.luldPriceBandIndicator
        \o message.luldTimestamp
        \o message.limitDownPrice
        \o message.limitUpPrice

DecodeLimitUpLimitDownPriceBandMessage(bytes) ==
    LET messageInfo == DecodeMessageInfo9(bytes) IN IF ~messageInfo.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(messageInfo.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET luldPriceBandIndicator == ReadBytes(symbolLong.rest, 1) IN IF ~luldPriceBandIndicator.ok THEN Fail ELSE
    LET luldTimestamp == ReadBytes(luldPriceBandIndicator.rest, 8) IN IF ~luldTimestamp.ok THEN Fail ELSE
    LET limitDownPrice == ReadBytes(luldTimestamp.rest, 8) IN IF ~limitDownPrice.ok THEN Fail ELSE
    LET limitUpPrice == ReadBytes(limitDownPrice.rest, 8) IN IF ~limitUpPrice.ok THEN Fail ELSE
    Ok([ messageInfo            |-> messageInfo.value,
         symbolLong             |-> symbolLong.value,
         luldPriceBandIndicator |-> luldPriceBandIndicator.value,
         luldTimestamp          |-> luldTimestamp.value,
         limitDownPrice         |-> limitDownPrice.value,
         limitUpPrice           |-> limitUpPrice.value ], limitUpPrice.rest)

ZeroLimitUpLimitDownPriceBandMessage ==
    [ messageInfo            |-> ZeroMessageInfo9,
      symbolLong             |-> [i \in 1 .. 11 |-> 0],
      luldPriceBandIndicator |-> [i \in 1 .. 1 |-> 0],
      luldTimestamp          |-> [i \in 1 .. 8 |-> 0],
      limitDownPrice         |-> [i \in 1 .. 8 |-> 0],
      limitUpPrice           |-> [i \in 1 .. 8 |-> 0] ]

(* Limit Up Limit Down Price Band Message at zero, then each field in turn at the values it is checked at *)
CheckedLimitUpLimitDownPriceBandMessage ==
    { ZeroLimitUpLimitDownPriceBandMessage }
        \cup { [ZeroLimitUpLimitDownPriceBandMessage EXCEPT !.messageInfo = one] : one \in CheckedMessageInfo9 }
        \cup { [ZeroLimitUpLimitDownPriceBandMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroLimitUpLimitDownPriceBandMessage EXCEPT !.luldPriceBandIndicator = one] : one \in Sample(1) }
        \cup { [ZeroLimitUpLimitDownPriceBandMessage EXCEPT !.luldTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroLimitUpLimitDownPriceBandMessage EXCEPT !.limitDownPrice = one] : one \in Sample(8) }
        \cup { [ZeroLimitUpLimitDownPriceBandMessage EXCEPT !.limitUpPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Message Info: 26 bytes                                                  *)
(***************************************************************************)

MessageInfo10 ==
    [ marketCenterOriginatorId : Sample(1),
      subMarketCenterId        : Sample(1),
      sipTimestamp             : Sample(8),
      participantTimestamp     : Sample(8),
      participantToken         : Sample(8) ]

EncodeMessageInfo10(message) ==
    message.marketCenterOriginatorId
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.participantTimestamp
        \o message.participantToken

DecodeMessageInfo10(bytes) ==
    LET marketCenterOriginatorId == ReadBytes(bytes, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginatorId.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET participantTimestamp == ReadBytes(sipTimestamp.rest, 8) IN IF ~participantTimestamp.ok THEN Fail ELSE
    LET participantToken == ReadBytes(participantTimestamp.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         subMarketCenterId        |-> subMarketCenterId.value,
         sipTimestamp             |-> sipTimestamp.value,
         participantTimestamp     |-> participantTimestamp.value,
         participantToken         |-> participantToken.value ], participantToken.rest)

ZeroMessageInfo10 ==
    [ marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId        |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp             |-> [i \in 1 .. 8 |-> 0],
      participantTimestamp     |-> [i \in 1 .. 8 |-> 0],
      participantToken         |-> [i \in 1 .. 8 |-> 0] ]

(* Message Info at zero, then each field in turn at the values it is checked at *)
CheckedMessageInfo10 ==
    { ZeroMessageInfo10 }
        \cup { [ZeroMessageInfo10 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo10 EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo10 EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo10 EXCEPT !.participantTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo10 EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* Market Wide Circuit Breaker Decline Level Message: 50 bytes             *)
(***************************************************************************)

MarketWideCircuitBreakerDeclineLevelMessage ==
    [ messageInfo : MessageInfo10,
      mwcbLevel1  : Sample(8),
      mwcbLevel2  : Sample(8),
      mwcbLevel3  : Sample(8) ]

EncodeMarketWideCircuitBreakerDeclineLevelMessage(message) ==
    EncodeMessageInfo10(message.messageInfo)
        \o message.mwcbLevel1
        \o message.mwcbLevel2
        \o message.mwcbLevel3

DecodeMarketWideCircuitBreakerDeclineLevelMessage(bytes) ==
    LET messageInfo == DecodeMessageInfo10(bytes) IN IF ~messageInfo.ok THEN Fail ELSE
    LET mwcbLevel1 == ReadBytes(messageInfo.rest, 8) IN IF ~mwcbLevel1.ok THEN Fail ELSE
    LET mwcbLevel2 == ReadBytes(mwcbLevel1.rest, 8) IN IF ~mwcbLevel2.ok THEN Fail ELSE
    LET mwcbLevel3 == ReadBytes(mwcbLevel2.rest, 8) IN IF ~mwcbLevel3.ok THEN Fail ELSE
    Ok([ messageInfo |-> messageInfo.value,
         mwcbLevel1  |-> mwcbLevel1.value,
         mwcbLevel2  |-> mwcbLevel2.value,
         mwcbLevel3  |-> mwcbLevel3.value ], mwcbLevel3.rest)

ZeroMarketWideCircuitBreakerDeclineLevelMessage ==
    [ messageInfo |-> ZeroMessageInfo10,
      mwcbLevel1  |-> [i \in 1 .. 8 |-> 0],
      mwcbLevel2  |-> [i \in 1 .. 8 |-> 0],
      mwcbLevel3  |-> [i \in 1 .. 8 |-> 0] ]

(* Market Wide Circuit Breaker Decline Level Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketWideCircuitBreakerDeclineLevelMessage ==
    { ZeroMarketWideCircuitBreakerDeclineLevelMessage }
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelMessage EXCEPT !.messageInfo = one] : one \in CheckedMessageInfo10 }
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelMessage EXCEPT !.mwcbLevel1 = one] : one \in Sample(8) }
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelMessage EXCEPT !.mwcbLevel2 = one] : one \in Sample(8) }
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelMessage EXCEPT !.mwcbLevel3 = one] : one \in Sample(8) }

(***************************************************************************)
(* Message Info: 26 bytes                                                  *)
(***************************************************************************)

MessageInfo11 ==
    [ marketCenterOriginatorId : Sample(1),
      subMarketCenterId        : Sample(1),
      sipTimestamp             : Sample(8),
      participantTimestamp     : Sample(8),
      participantToken         : Sample(8) ]

EncodeMessageInfo11(message) ==
    message.marketCenterOriginatorId
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.participantTimestamp
        \o message.participantToken

DecodeMessageInfo11(bytes) ==
    LET marketCenterOriginatorId == ReadBytes(bytes, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginatorId.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET participantTimestamp == ReadBytes(sipTimestamp.rest, 8) IN IF ~participantTimestamp.ok THEN Fail ELSE
    LET participantToken == ReadBytes(participantTimestamp.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         subMarketCenterId        |-> subMarketCenterId.value,
         sipTimestamp             |-> sipTimestamp.value,
         participantTimestamp     |-> participantTimestamp.value,
         participantToken         |-> participantToken.value ], participantToken.rest)

ZeroMessageInfo11 ==
    [ marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId        |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp             |-> [i \in 1 .. 8 |-> 0],
      participantTimestamp     |-> [i \in 1 .. 8 |-> 0],
      participantToken         |-> [i \in 1 .. 8 |-> 0] ]

(* Message Info at zero, then each field in turn at the values it is checked at *)
CheckedMessageInfo11 ==
    { ZeroMessageInfo11 }
        \cup { [ZeroMessageInfo11 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo11 EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo11 EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo11 EXCEPT !.participantTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo11 EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* Market Wide Circuit Breaker Status Message: 27 bytes                    *)
(***************************************************************************)

MarketWideCircuitBreakerStatusMessage ==
    [ messageInfo              : MessageInfo11,
      mwcbStatusLevelIndicator : Sample(1) ]

EncodeMarketWideCircuitBreakerStatusMessage(message) ==
    EncodeMessageInfo11(message.messageInfo)
        \o message.mwcbStatusLevelIndicator

DecodeMarketWideCircuitBreakerStatusMessage(bytes) ==
    LET messageInfo == DecodeMessageInfo11(bytes) IN IF ~messageInfo.ok THEN Fail ELSE
    LET mwcbStatusLevelIndicator == ReadBytes(messageInfo.rest, 1) IN IF ~mwcbStatusLevelIndicator.ok THEN Fail ELSE
    Ok([ messageInfo              |-> messageInfo.value,
         mwcbStatusLevelIndicator |-> mwcbStatusLevelIndicator.value ], mwcbStatusLevelIndicator.rest)

ZeroMarketWideCircuitBreakerStatusMessage ==
    [ messageInfo              |-> ZeroMessageInfo11,
      mwcbStatusLevelIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Market Wide Circuit Breaker Status Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketWideCircuitBreakerStatusMessage ==
    { ZeroMarketWideCircuitBreakerStatusMessage }
        \cup { [ZeroMarketWideCircuitBreakerStatusMessage EXCEPT !.messageInfo = one] : one \in CheckedMessageInfo11 }
        \cup { [ZeroMarketWideCircuitBreakerStatusMessage EXCEPT !.mwcbStatusLevelIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Message Info: 26 bytes                                                  *)
(***************************************************************************)

MessageInfo12 ==
    [ marketCenterOriginatorId : Sample(1),
      subMarketCenterId        : Sample(1),
      sipTimestamp             : Sample(8),
      participantTimestamp     : Sample(8),
      participantToken         : Sample(8) ]

EncodeMessageInfo12(message) ==
    message.marketCenterOriginatorId
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.participantTimestamp
        \o message.participantToken

DecodeMessageInfo12(bytes) ==
    LET marketCenterOriginatorId == ReadBytes(bytes, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginatorId.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET participantTimestamp == ReadBytes(sipTimestamp.rest, 8) IN IF ~participantTimestamp.ok THEN Fail ELSE
    LET participantToken == ReadBytes(participantTimestamp.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         subMarketCenterId        |-> subMarketCenterId.value,
         sipTimestamp             |-> sipTimestamp.value,
         participantTimestamp     |-> participantTimestamp.value,
         participantToken         |-> participantToken.value ], participantToken.rest)

ZeroMessageInfo12 ==
    [ marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId        |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp             |-> [i \in 1 .. 8 |-> 0],
      participantTimestamp     |-> [i \in 1 .. 8 |-> 0],
      participantToken         |-> [i \in 1 .. 8 |-> 0] ]

(* Message Info at zero, then each field in turn at the values it is checked at *)
CheckedMessageInfo12 ==
    { ZeroMessageInfo12 }
        \cup { [ZeroMessageInfo12 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo12 EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo12 EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo12 EXCEPT !.participantTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo12 EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* Auction Collar Message: 66 bytes                                        *)
(***************************************************************************)

AuctionCollarMessage ==
    [ messageInfo                 : MessageInfo12,
      symbolLong                  : Sample(11),
      tradingActionSequenceNumber : Sample(4),
      collarReferencePrice        : Sample(8),
      collarUpPrice               : Sample(8),
      collarDownPrice             : Sample(8),
      collarExtensionIndicator    : Sample(1) ]

EncodeAuctionCollarMessage(message) ==
    EncodeMessageInfo12(message.messageInfo)
        \o message.symbolLong
        \o message.tradingActionSequenceNumber
        \o message.collarReferencePrice
        \o message.collarUpPrice
        \o message.collarDownPrice
        \o message.collarExtensionIndicator

DecodeAuctionCollarMessage(bytes) ==
    LET messageInfo == DecodeMessageInfo12(bytes) IN IF ~messageInfo.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(messageInfo.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET tradingActionSequenceNumber == ReadBytes(symbolLong.rest, 4) IN IF ~tradingActionSequenceNumber.ok THEN Fail ELSE
    LET collarReferencePrice == ReadBytes(tradingActionSequenceNumber.rest, 8) IN IF ~collarReferencePrice.ok THEN Fail ELSE
    LET collarUpPrice == ReadBytes(collarReferencePrice.rest, 8) IN IF ~collarUpPrice.ok THEN Fail ELSE
    LET collarDownPrice == ReadBytes(collarUpPrice.rest, 8) IN IF ~collarDownPrice.ok THEN Fail ELSE
    LET collarExtensionIndicator == ReadBytes(collarDownPrice.rest, 1) IN IF ~collarExtensionIndicator.ok THEN Fail ELSE
    Ok([ messageInfo                 |-> messageInfo.value,
         symbolLong                  |-> symbolLong.value,
         tradingActionSequenceNumber |-> tradingActionSequenceNumber.value,
         collarReferencePrice        |-> collarReferencePrice.value,
         collarUpPrice               |-> collarUpPrice.value,
         collarDownPrice             |-> collarDownPrice.value,
         collarExtensionIndicator    |-> collarExtensionIndicator.value ], collarExtensionIndicator.rest)

ZeroAuctionCollarMessage ==
    [ messageInfo                 |-> ZeroMessageInfo12,
      symbolLong                  |-> [i \in 1 .. 11 |-> 0],
      tradingActionSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      collarReferencePrice        |-> [i \in 1 .. 8 |-> 0],
      collarUpPrice               |-> [i \in 1 .. 8 |-> 0],
      collarDownPrice             |-> [i \in 1 .. 8 |-> 0],
      collarExtensionIndicator    |-> [i \in 1 .. 1 |-> 0] ]

(* Auction Collar Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionCollarMessage ==
    { ZeroAuctionCollarMessage }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.messageInfo = one] : one \in CheckedMessageInfo12 }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.tradingActionSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.collarReferencePrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.collarUpPrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.collarDownPrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.collarExtensionIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Message Info: 26 bytes                                                  *)
(***************************************************************************)

MessageInfo13 ==
    [ marketCenterOriginatorId : Sample(1),
      subMarketCenterId        : Sample(1),
      sipTimestamp             : Sample(8),
      participantTimestamp     : Sample(8),
      participantToken         : Sample(8) ]

EncodeMessageInfo13(message) ==
    message.marketCenterOriginatorId
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.participantTimestamp
        \o message.participantToken

DecodeMessageInfo13(bytes) ==
    LET marketCenterOriginatorId == ReadBytes(bytes, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginatorId.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET participantTimestamp == ReadBytes(sipTimestamp.rest, 8) IN IF ~participantTimestamp.ok THEN Fail ELSE
    LET participantToken == ReadBytes(participantTimestamp.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         subMarketCenterId        |-> subMarketCenterId.value,
         sipTimestamp             |-> sipTimestamp.value,
         participantTimestamp     |-> participantTimestamp.value,
         participantToken         |-> participantToken.value ], participantToken.rest)

ZeroMessageInfo13 ==
    [ marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId        |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp             |-> [i \in 1 .. 8 |-> 0],
      participantTimestamp     |-> [i \in 1 .. 8 |-> 0],
      participantToken         |-> [i \in 1 .. 8 |-> 0] ]

(* Message Info at zero, then each field in turn at the values it is checked at *)
CheckedMessageInfo13 ==
    { ZeroMessageInfo13 }
        \cup { [ZeroMessageInfo13 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo13 EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo13 EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo13 EXCEPT !.participantTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo13 EXCEPT !.participantToken = one] : one \in Sample(8) }

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
    [ messageInfo                 : MessageInfo13,
      symbolLong                  : Sample(11),
      nationalBestBidMarketCenter : Sample(1),
      nationalBestBidPrice        : Sample(8),
      nationalBestBidSize         : Sample(8),
      nationalBestAskMarketCenter : Sample(1),
      nationalBestAskPrice        : Sample(8),
      nationalBestAskSize         : Sample(8),
      specialCondition            : Sample(1),
      marketCenterCloseRecap      : SampleLists(OneMarketCenterCloseRecap) ]

EncodeSessionCloseRecapMessage(message) ==
    EncodeMessageInfo13(message.messageInfo)
        \o message.symbolLong
        \o message.nationalBestBidMarketCenter
        \o message.nationalBestBidPrice
        \o message.nationalBestBidSize
        \o message.nationalBestAskMarketCenter
        \o message.nationalBestAskPrice
        \o message.nationalBestAskSize
        \o message.specialCondition
        \o EncodeUIntBE(Len(message.marketCenterCloseRecap), 2)
        \o EncodeMarketCenterCloseRecapList(message.marketCenterCloseRecap)

DecodeSessionCloseRecapMessage(bytes) ==
    LET messageInfo == DecodeMessageInfo13(bytes) IN IF ~messageInfo.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(messageInfo.rest, 11) IN IF ~symbolLong.ok THEN Fail ELSE
    LET nationalBestBidMarketCenter == ReadBytes(symbolLong.rest, 1) IN IF ~nationalBestBidMarketCenter.ok THEN Fail ELSE
    LET nationalBestBidPrice == ReadBytes(nationalBestBidMarketCenter.rest, 8) IN IF ~nationalBestBidPrice.ok THEN Fail ELSE
    LET nationalBestBidSize == ReadBytes(nationalBestBidPrice.rest, 8) IN IF ~nationalBestBidSize.ok THEN Fail ELSE
    LET nationalBestAskMarketCenter == ReadBytes(nationalBestBidSize.rest, 1) IN IF ~nationalBestAskMarketCenter.ok THEN Fail ELSE
    LET nationalBestAskPrice == ReadBytes(nationalBestAskMarketCenter.rest, 8) IN IF ~nationalBestAskPrice.ok THEN Fail ELSE
    LET nationalBestAskSize == ReadBytes(nationalBestAskPrice.rest, 8) IN IF ~nationalBestAskSize.ok THEN Fail ELSE
    LET specialCondition == ReadBytes(nationalBestAskSize.rest, 1) IN IF ~specialCondition.ok THEN Fail ELSE
    LET numberOfMarketCenterAttachments == ReadUIntBE(specialCondition.rest, 2) IN IF ~numberOfMarketCenterAttachments.ok THEN Fail ELSE
    LET marketCenterCloseRecap == ReadMarketCenterCloseRecapList(numberOfMarketCenterAttachments.rest, numberOfMarketCenterAttachments.value) IN IF ~marketCenterCloseRecap.ok THEN Fail ELSE
    Ok([ messageInfo                 |-> messageInfo.value,
         symbolLong                  |-> symbolLong.value,
         nationalBestBidMarketCenter |-> nationalBestBidMarketCenter.value,
         nationalBestBidPrice        |-> nationalBestBidPrice.value,
         nationalBestBidSize         |-> nationalBestBidSize.value,
         nationalBestAskMarketCenter |-> nationalBestAskMarketCenter.value,
         nationalBestAskPrice        |-> nationalBestAskPrice.value,
         nationalBestAskSize         |-> nationalBestAskSize.value,
         specialCondition            |-> specialCondition.value,
         marketCenterCloseRecap      |-> marketCenterCloseRecap.value ], marketCenterCloseRecap.rest)

ZeroSessionCloseRecapMessage ==
    [ messageInfo                 |-> ZeroMessageInfo13,
      symbolLong                  |-> [i \in 1 .. 11 |-> 0],
      nationalBestBidMarketCenter |-> [i \in 1 .. 1 |-> 0],
      nationalBestBidPrice        |-> [i \in 1 .. 8 |-> 0],
      nationalBestBidSize         |-> [i \in 1 .. 8 |-> 0],
      nationalBestAskMarketCenter |-> [i \in 1 .. 1 |-> 0],
      nationalBestAskPrice        |-> [i \in 1 .. 8 |-> 0],
      nationalBestAskSize         |-> [i \in 1 .. 8 |-> 0],
      specialCondition            |-> [i \in 1 .. 1 |-> 0],
      marketCenterCloseRecap      |-> << >> ]

(* Session Close Recap Message at zero, then each field in turn at the values it is checked at *)
CheckedSessionCloseRecapMessage ==
    { ZeroSessionCloseRecapMessage }
        \cup { [ZeroSessionCloseRecapMessage EXCEPT !.messageInfo = one] : one \in CheckedMessageInfo13 }
        \cup { [ZeroSessionCloseRecapMessage EXCEPT !.symbolLong = one] : one \in Sample(11) }
        \cup { [ZeroSessionCloseRecapMessage EXCEPT !.nationalBestBidMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroSessionCloseRecapMessage EXCEPT !.nationalBestBidPrice = one] : one \in Sample(8) }
        \cup { [ZeroSessionCloseRecapMessage EXCEPT !.nationalBestBidSize = one] : one \in Sample(8) }
        \cup { [ZeroSessionCloseRecapMessage EXCEPT !.nationalBestAskMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroSessionCloseRecapMessage EXCEPT !.nationalBestAskPrice = one] : one \in Sample(8) }
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
RegulationShoShortSalePriceTestRestrictedIndicatorMessageCode == 86  \* "V"
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
        \cup [ tag : {RegulationShoShortSalePriceTestRestrictedIndicatorMessageCode}, body : RegulationShoShortSalePriceTestRestrictedIndicatorMessage ]
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
      [] message.tag = RegulationShoShortSalePriceTestRestrictedIndicatorMessageCode -> EncodeRegulationShoShortSalePriceTestRestrictedIndicatorMessage(message.body)
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
              [] tag = RegulationShoShortSalePriceTestRestrictedIndicatorMessageCode -> DecodeRegulationShoShortSalePriceTestRestrictedIndicatorMessage(bytes)
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
        \cup { [tag |-> RegulationShoShortSalePriceTestRestrictedIndicatorMessageCode, body |-> one] : one \in CheckedRegulationShoShortSalePriceTestRestrictedIndicatorMessage }
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
(* Message Info: 26 bytes                                                  *)
(***************************************************************************)

MessageInfo14 ==
    [ marketCenterOriginatorId : Sample(1),
      subMarketCenterId        : Sample(1),
      sipTimestamp             : Sample(8),
      participantTimestamp     : Sample(8),
      participantToken         : Sample(8) ]

EncodeMessageInfo14(message) ==
    message.marketCenterOriginatorId
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.participantTimestamp
        \o message.participantToken

DecodeMessageInfo14(bytes) ==
    LET marketCenterOriginatorId == ReadBytes(bytes, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginatorId.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET participantTimestamp == ReadBytes(sipTimestamp.rest, 8) IN IF ~participantTimestamp.ok THEN Fail ELSE
    LET participantToken == ReadBytes(participantTimestamp.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         subMarketCenterId        |-> subMarketCenterId.value,
         sipTimestamp             |-> sipTimestamp.value,
         participantTimestamp     |-> participantTimestamp.value,
         participantToken         |-> participantToken.value ], participantToken.rest)

ZeroMessageInfo14 ==
    [ marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId        |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp             |-> [i \in 1 .. 8 |-> 0],
      participantTimestamp     |-> [i \in 1 .. 8 |-> 0],
      participantToken         |-> [i \in 1 .. 8 |-> 0] ]

(* Message Info at zero, then each field in turn at the values it is checked at *)
CheckedMessageInfo14 ==
    { ZeroMessageInfo14 }
        \cup { [ZeroMessageInfo14 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo14 EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo14 EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo14 EXCEPT !.participantTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo14 EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* Start Of Day Message: 26 bytes                                          *)
(***************************************************************************)

StartOfDayMessage ==
    [ messageInfo : MessageInfo14 ]

EncodeStartOfDayMessage(message) ==
    EncodeMessageInfo14(message.messageInfo)

DecodeStartOfDayMessage(bytes) ==
    LET messageInfo == DecodeMessageInfo14(bytes) IN IF ~messageInfo.ok THEN Fail ELSE
    Ok([ messageInfo |-> messageInfo.value ], messageInfo.rest)

ZeroStartOfDayMessage ==
    [ messageInfo |-> ZeroMessageInfo14 ]

(* Start Of Day Message at zero, then each field in turn at the values it is checked at *)
CheckedStartOfDayMessage ==
    { ZeroStartOfDayMessage }
        \cup { [ZeroStartOfDayMessage EXCEPT !.messageInfo = one] : one \in CheckedMessageInfo14 }

(***************************************************************************)
(* Message Info: 26 bytes                                                  *)
(***************************************************************************)

MessageInfo15 ==
    [ marketCenterOriginatorId : Sample(1),
      subMarketCenterId        : Sample(1),
      sipTimestamp             : Sample(8),
      participantTimestamp     : Sample(8),
      participantToken         : Sample(8) ]

EncodeMessageInfo15(message) ==
    message.marketCenterOriginatorId
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.participantTimestamp
        \o message.participantToken

DecodeMessageInfo15(bytes) ==
    LET marketCenterOriginatorId == ReadBytes(bytes, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginatorId.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET participantTimestamp == ReadBytes(sipTimestamp.rest, 8) IN IF ~participantTimestamp.ok THEN Fail ELSE
    LET participantToken == ReadBytes(participantTimestamp.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         subMarketCenterId        |-> subMarketCenterId.value,
         sipTimestamp             |-> sipTimestamp.value,
         participantTimestamp     |-> participantTimestamp.value,
         participantToken         |-> participantToken.value ], participantToken.rest)

ZeroMessageInfo15 ==
    [ marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId        |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp             |-> [i \in 1 .. 8 |-> 0],
      participantTimestamp     |-> [i \in 1 .. 8 |-> 0],
      participantToken         |-> [i \in 1 .. 8 |-> 0] ]

(* Message Info at zero, then each field in turn at the values it is checked at *)
CheckedMessageInfo15 ==
    { ZeroMessageInfo15 }
        \cup { [ZeroMessageInfo15 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo15 EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo15 EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo15 EXCEPT !.participantTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo15 EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* End Of Day Message: 26 bytes                                            *)
(***************************************************************************)

EndOfDayMessage ==
    [ messageInfo : MessageInfo15 ]

EncodeEndOfDayMessage(message) ==
    EncodeMessageInfo15(message.messageInfo)

DecodeEndOfDayMessage(bytes) ==
    LET messageInfo == DecodeMessageInfo15(bytes) IN IF ~messageInfo.ok THEN Fail ELSE
    Ok([ messageInfo |-> messageInfo.value ], messageInfo.rest)

ZeroEndOfDayMessage ==
    [ messageInfo |-> ZeroMessageInfo15 ]

(* End Of Day Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfDayMessage ==
    { ZeroEndOfDayMessage }
        \cup { [ZeroEndOfDayMessage EXCEPT !.messageInfo = one] : one \in CheckedMessageInfo15 }

(***************************************************************************)
(* Message Info: 26 bytes                                                  *)
(***************************************************************************)

MessageInfo16 ==
    [ marketCenterOriginatorId : Sample(1),
      subMarketCenterId        : Sample(1),
      sipTimestamp             : Sample(8),
      participantTimestamp     : Sample(8),
      participantToken         : Sample(8) ]

EncodeMessageInfo16(message) ==
    message.marketCenterOriginatorId
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.participantTimestamp
        \o message.participantToken

DecodeMessageInfo16(bytes) ==
    LET marketCenterOriginatorId == ReadBytes(bytes, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginatorId.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET participantTimestamp == ReadBytes(sipTimestamp.rest, 8) IN IF ~participantTimestamp.ok THEN Fail ELSE
    LET participantToken == ReadBytes(participantTimestamp.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         subMarketCenterId        |-> subMarketCenterId.value,
         sipTimestamp             |-> sipTimestamp.value,
         participantTimestamp     |-> participantTimestamp.value,
         participantToken         |-> participantToken.value ], participantToken.rest)

ZeroMessageInfo16 ==
    [ marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId        |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp             |-> [i \in 1 .. 8 |-> 0],
      participantTimestamp     |-> [i \in 1 .. 8 |-> 0],
      participantToken         |-> [i \in 1 .. 8 |-> 0] ]

(* Message Info at zero, then each field in turn at the values it is checked at *)
CheckedMessageInfo16 ==
    { ZeroMessageInfo16 }
        \cup { [ZeroMessageInfo16 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo16 EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo16 EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo16 EXCEPT !.participantTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo16 EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* Market Session Open Message: 26 bytes                                   *)
(***************************************************************************)

MarketSessionOpenMessage ==
    [ messageInfo : MessageInfo16 ]

EncodeMarketSessionOpenMessage(message) ==
    EncodeMessageInfo16(message.messageInfo)

DecodeMarketSessionOpenMessage(bytes) ==
    LET messageInfo == DecodeMessageInfo16(bytes) IN IF ~messageInfo.ok THEN Fail ELSE
    Ok([ messageInfo |-> messageInfo.value ], messageInfo.rest)

ZeroMarketSessionOpenMessage ==
    [ messageInfo |-> ZeroMessageInfo16 ]

(* Market Session Open Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketSessionOpenMessage ==
    { ZeroMarketSessionOpenMessage }
        \cup { [ZeroMarketSessionOpenMessage EXCEPT !.messageInfo = one] : one \in CheckedMessageInfo16 }

(***************************************************************************)
(* Message Info: 26 bytes                                                  *)
(***************************************************************************)

MessageInfo17 ==
    [ marketCenterOriginatorId : Sample(1),
      subMarketCenterId        : Sample(1),
      sipTimestamp             : Sample(8),
      participantTimestamp     : Sample(8),
      participantToken         : Sample(8) ]

EncodeMessageInfo17(message) ==
    message.marketCenterOriginatorId
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.participantTimestamp
        \o message.participantToken

DecodeMessageInfo17(bytes) ==
    LET marketCenterOriginatorId == ReadBytes(bytes, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginatorId.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET participantTimestamp == ReadBytes(sipTimestamp.rest, 8) IN IF ~participantTimestamp.ok THEN Fail ELSE
    LET participantToken == ReadBytes(participantTimestamp.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         subMarketCenterId        |-> subMarketCenterId.value,
         sipTimestamp             |-> sipTimestamp.value,
         participantTimestamp     |-> participantTimestamp.value,
         participantToken         |-> participantToken.value ], participantToken.rest)

ZeroMessageInfo17 ==
    [ marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId        |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp             |-> [i \in 1 .. 8 |-> 0],
      participantTimestamp     |-> [i \in 1 .. 8 |-> 0],
      participantToken         |-> [i \in 1 .. 8 |-> 0] ]

(* Message Info at zero, then each field in turn at the values it is checked at *)
CheckedMessageInfo17 ==
    { ZeroMessageInfo17 }
        \cup { [ZeroMessageInfo17 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo17 EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo17 EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo17 EXCEPT !.participantTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo17 EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* Market Session Close Message: 26 bytes                                  *)
(***************************************************************************)

MarketSessionCloseMessage ==
    [ messageInfo : MessageInfo17 ]

EncodeMarketSessionCloseMessage(message) ==
    EncodeMessageInfo17(message.messageInfo)

DecodeMarketSessionCloseMessage(bytes) ==
    LET messageInfo == DecodeMessageInfo17(bytes) IN IF ~messageInfo.ok THEN Fail ELSE
    Ok([ messageInfo |-> messageInfo.value ], messageInfo.rest)

ZeroMarketSessionCloseMessage ==
    [ messageInfo |-> ZeroMessageInfo17 ]

(* Market Session Close Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketSessionCloseMessage ==
    { ZeroMarketSessionCloseMessage }
        \cup { [ZeroMarketSessionCloseMessage EXCEPT !.messageInfo = one] : one \in CheckedMessageInfo17 }

(***************************************************************************)
(* Message Info: 26 bytes                                                  *)
(***************************************************************************)

MessageInfo18 ==
    [ marketCenterOriginatorId : Sample(1),
      subMarketCenterId        : Sample(1),
      sipTimestamp             : Sample(8),
      participantTimestamp     : Sample(8),
      participantToken         : Sample(8) ]

EncodeMessageInfo18(message) ==
    message.marketCenterOriginatorId
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.participantTimestamp
        \o message.participantToken

DecodeMessageInfo18(bytes) ==
    LET marketCenterOriginatorId == ReadBytes(bytes, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginatorId.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET participantTimestamp == ReadBytes(sipTimestamp.rest, 8) IN IF ~participantTimestamp.ok THEN Fail ELSE
    LET participantToken == ReadBytes(participantTimestamp.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         subMarketCenterId        |-> subMarketCenterId.value,
         sipTimestamp             |-> sipTimestamp.value,
         participantTimestamp     |-> participantTimestamp.value,
         participantToken         |-> participantToken.value ], participantToken.rest)

ZeroMessageInfo18 ==
    [ marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId        |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp             |-> [i \in 1 .. 8 |-> 0],
      participantTimestamp     |-> [i \in 1 .. 8 |-> 0],
      participantToken         |-> [i \in 1 .. 8 |-> 0] ]

(* Message Info at zero, then each field in turn at the values it is checked at *)
CheckedMessageInfo18 ==
    { ZeroMessageInfo18 }
        \cup { [ZeroMessageInfo18 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo18 EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo18 EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo18 EXCEPT !.participantTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo18 EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* End Of Transmissions Message: 26 bytes                                  *)
(***************************************************************************)

EndOfTransmissionsMessage ==
    [ messageInfo : MessageInfo18 ]

EncodeEndOfTransmissionsMessage(message) ==
    EncodeMessageInfo18(message.messageInfo)

DecodeEndOfTransmissionsMessage(bytes) ==
    LET messageInfo == DecodeMessageInfo18(bytes) IN IF ~messageInfo.ok THEN Fail ELSE
    Ok([ messageInfo |-> messageInfo.value ], messageInfo.rest)

ZeroEndOfTransmissionsMessage ==
    [ messageInfo |-> ZeroMessageInfo18 ]

(* End Of Transmissions Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfTransmissionsMessage ==
    { ZeroEndOfTransmissionsMessage }
        \cup { [ZeroEndOfTransmissionsMessage EXCEPT !.messageInfo = one] : one \in CheckedMessageInfo18 }

(***************************************************************************)
(* Message Info: 26 bytes                                                  *)
(***************************************************************************)

MessageInfo19 ==
    [ marketCenterOriginatorId : Sample(1),
      subMarketCenterId        : Sample(1),
      sipTimestamp             : Sample(8),
      participantTimestamp     : Sample(8),
      participantToken         : Sample(8) ]

EncodeMessageInfo19(message) ==
    message.marketCenterOriginatorId
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.participantTimestamp
        \o message.participantToken

DecodeMessageInfo19(bytes) ==
    LET marketCenterOriginatorId == ReadBytes(bytes, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginatorId.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET participantTimestamp == ReadBytes(sipTimestamp.rest, 8) IN IF ~participantTimestamp.ok THEN Fail ELSE
    LET participantToken == ReadBytes(participantTimestamp.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         subMarketCenterId        |-> subMarketCenterId.value,
         sipTimestamp             |-> sipTimestamp.value,
         participantTimestamp     |-> participantTimestamp.value,
         participantToken         |-> participantToken.value ], participantToken.rest)

ZeroMessageInfo19 ==
    [ marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId        |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp             |-> [i \in 1 .. 8 |-> 0],
      participantTimestamp     |-> [i \in 1 .. 8 |-> 0],
      participantToken         |-> [i \in 1 .. 8 |-> 0] ]

(* Message Info at zero, then each field in turn at the values it is checked at *)
CheckedMessageInfo19 ==
    { ZeroMessageInfo19 }
        \cup { [ZeroMessageInfo19 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo19 EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMessageInfo19 EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo19 EXCEPT !.participantTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessageInfo19 EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* Quote Wipe Out Message: 26 bytes                                        *)
(***************************************************************************)

QuoteWipeOutMessage ==
    [ messageInfo : MessageInfo19 ]

EncodeQuoteWipeOutMessage(message) ==
    EncodeMessageInfo19(message.messageInfo)

DecodeQuoteWipeOutMessage(bytes) ==
    LET messageInfo == DecodeMessageInfo19(bytes) IN IF ~messageInfo.ok THEN Fail ELSE
    Ok([ messageInfo |-> messageInfo.value ], messageInfo.rest)

ZeroQuoteWipeOutMessage ==
    [ messageInfo |-> ZeroMessageInfo19 ]

(* Quote Wipe Out Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteWipeOutMessage ==
    { ZeroQuoteWipeOutMessage }
        \cup { [ZeroQuoteWipeOutMessage EXCEPT !.messageInfo = one] : one \in CheckedMessageInfo19 }

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
(* Payload, selected by Message Category                                   *)
(***************************************************************************)

QuoteMessageCode == 81  \* "Q"
AdministrativeMessageCode == 65  \* "A"
ControlMessageCode == 67  \* "C"

Payload ==
    [ tag : {QuoteMessageCode}, body : QuoteMessage ]
        \cup [ tag : {AdministrativeMessageCode}, body : AdministrativeMessage ]
        \cup [ tag : {ControlMessageCode}, body : ControlMessage ]

EncodePayload(message) ==
    CASE message.tag = QuoteMessageCode -> EncodeQuoteMessage(message.body)
      [] message.tag = AdministrativeMessageCode -> EncodeAdministrativeMessage(message.body)
      [] message.tag = ControlMessageCode -> EncodeControlMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = QuoteMessageCode -> DecodeQuoteMessage(bytes)
              [] tag = AdministrativeMessageCode -> DecodeAdministrativeMessage(bytes)
              [] tag = ControlMessageCode -> DecodeControlMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> QuoteMessageCode, body |-> ZeroQuoteMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> QuoteMessageCode, body |-> one] : one \in CheckedQuoteMessage }
        \cup { [tag |-> AdministrativeMessageCode, body |-> one] : one \in CheckedAdministrativeMessage }
        \cup { [tag |-> ControlMessageCode, body |-> one] : one \in CheckedControlMessage }

(***************************************************************************)
(* Message, framed by Message Length                                       *)
(***************************************************************************)

Message ==
    [ version : Sample(1),
      payload : Payload ]

EncodeMessageBody(message) ==
    message.version
        \o EncodeUIntBE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeMessageBody(bytes) ==
    LET version == ReadBytes(bytes, 1) IN IF ~version.ok THEN Fail ELSE
    LET messageCategory == ReadUIntBE(version.rest, 1) IN IF ~messageCategory.ok THEN Fail ELSE
    LET payload == DecodePayload(messageCategory.value, messageCategory.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ version |-> version.value,
         payload |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroMessage ==
    [ version |-> [i \in 1 .. 1 |-> 0],
      payload |-> ZeroPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.version = one] : one \in Sample(1) }
        \cup { [ZeroMessage EXCEPT !.payload = one] : one \in CheckedPayload }

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
    { [ZeroMessage EXCEPT !.payload = [tag |-> QuoteMessageCode, body |-> ZeroQuoteMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AdministrativeMessageCode, body |-> ZeroAdministrativeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ControlMessageCode, body |-> ZeroControlMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ session  : Sample(10),
      sequence : Sample(8),
      message  : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.session
        \o message.sequence
        \o EncodeUIntBE(Len(message.message), 2)
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET session == ReadBytes(bytes, 10) IN IF ~session.ok THEN Fail ELSE
    LET sequence == ReadBytes(session.rest, 8) IN IF ~sequence.ok THEN Fail ELSE
    LET count == ReadUIntBE(sequence.rest, 2) IN IF ~count.ok THEN Fail ELSE
    LET message == ReadMessageList(count.rest, count.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ session  |-> session.value,
         sequence |-> sequence.value,
         message  |-> message.value ], message.rest)

ZeroPacket ==
    [ session  |-> [i \in 1 .. 10 |-> 0],
      sequence |-> [i \in 1 .. 8 |-> 0],
      message  |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.session = one] : one \in Sample(10) }
        \cup { [ZeroPacket EXCEPT !.sequence = one] : one \in Sample(8) }
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

(* Every Message Info decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageInfo ==
    \A message \in CheckedMessageInfo :
        LET read == DecodeMessageInfo(EncodeMessageInfo(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Short Form National Bbo Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripShortFormNationalBboAppendage ==
    \A message \in CheckedShortFormNationalBboAppendage :
        LET read == DecodeShortFormNationalBboAppendage(EncodeShortFormNationalBboAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Form National Bbo Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripLongFormNationalBboAppendage ==
    \A message \in CheckedLongFormNationalBboAppendage :
        LET read == DecodeLongFormNationalBboAppendage(EncodeLongFormNationalBboAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Short Form Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteShortFormMessage ==
    \A message \in CheckedQuoteShortFormMessage :
        LET read == DecodeQuoteShortFormMessage(EncodeQuoteShortFormMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message Info decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageInfo2 ==
    \A message \in CheckedMessageInfo2 :
        LET read == DecodeMessageInfo2(EncodeMessageInfo2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Short Form National Bbo Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripShortFormNationalBboAppendage2 ==
    \A message \in CheckedShortFormNationalBboAppendage2 :
        LET read == DecodeShortFormNationalBboAppendage2(EncodeShortFormNationalBboAppendage2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Form National Bbo Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripLongFormNationalBboAppendage2 ==
    \A message \in CheckedLongFormNationalBboAppendage2 :
        LET read == DecodeLongFormNationalBboAppendage2(EncodeLongFormNationalBboAppendage2(message))
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

(* Every Quote Long Form Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteLongFormMessage ==
    \A message \in CheckedQuoteLongFormMessage :
        LET read == DecodeQuoteLongFormMessage(EncodeQuoteLongFormMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message Info decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageInfo3 ==
    \A message \in CheckedMessageInfo3 :
        LET read == DecodeMessageInfo3(EncodeMessageInfo3(message))
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

(* Every Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteMessage ==
    \A message \in CheckedQuoteMessage :
        LET read == DecodeQuoteMessage(EncodeQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message Info decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageInfo4 ==
    \A message \in CheckedMessageInfo4 :
        LET read == DecodeMessageInfo4(EncodeMessageInfo4(message))
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

(* Every Message Info decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageInfo5 ==
    \A message \in CheckedMessageInfo5 :
        LET read == DecodeMessageInfo5(EncodeMessageInfo5(message))
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

(* Every Message Info decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageInfo6 ==
    \A message \in CheckedMessageInfo6 :
        LET read == DecodeMessageInfo6(EncodeMessageInfo6(message))
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

(* Every Message Info decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageInfo7 ==
    \A message \in CheckedMessageInfo7 :
        LET read == DecodeMessageInfo7(EncodeMessageInfo7(message))
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

(* Every Message Info decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageInfo8 ==
    \A message \in CheckedMessageInfo8 :
        LET read == DecodeMessageInfo8(EncodeMessageInfo8(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Regulation Sho Short Sale Price Test Restricted Indicator Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRegulationShoShortSalePriceTestRestrictedIndicatorMessage ==
    \A message \in CheckedRegulationShoShortSalePriceTestRestrictedIndicatorMessage :
        LET read == DecodeRegulationShoShortSalePriceTestRestrictedIndicatorMessage(EncodeRegulationShoShortSalePriceTestRestrictedIndicatorMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message Info decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageInfo9 ==
    \A message \in CheckedMessageInfo9 :
        LET read == DecodeMessageInfo9(EncodeMessageInfo9(message))
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

(* Every Message Info decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageInfo10 ==
    \A message \in CheckedMessageInfo10 :
        LET read == DecodeMessageInfo10(EncodeMessageInfo10(message))
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

(* Every Message Info decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageInfo11 ==
    \A message \in CheckedMessageInfo11 :
        LET read == DecodeMessageInfo11(EncodeMessageInfo11(message))
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

(* Every Message Info decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageInfo12 ==
    \A message \in CheckedMessageInfo12 :
        LET read == DecodeMessageInfo12(EncodeMessageInfo12(message))
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

(* Every Message Info decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageInfo13 ==
    \A message \in CheckedMessageInfo13 :
        LET read == DecodeMessageInfo13(EncodeMessageInfo13(message))
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

(* Every Message Info decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageInfo14 ==
    \A message \in CheckedMessageInfo14 :
        LET read == DecodeMessageInfo14(EncodeMessageInfo14(message))
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

(* Every Message Info decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageInfo15 ==
    \A message \in CheckedMessageInfo15 :
        LET read == DecodeMessageInfo15(EncodeMessageInfo15(message))
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

(* Every Message Info decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageInfo16 ==
    \A message \in CheckedMessageInfo16 :
        LET read == DecodeMessageInfo16(EncodeMessageInfo16(message))
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

(* Every Message Info decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageInfo17 ==
    \A message \in CheckedMessageInfo17 :
        LET read == DecodeMessageInfo17(EncodeMessageInfo17(message))
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

(* Every Message Info decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageInfo18 ==
    \A message \in CheckedMessageInfo18 :
        LET read == DecodeMessageInfo18(EncodeMessageInfo18(message))
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

(* Every Message Info decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageInfo19 ==
    \A message \in CheckedMessageInfo19 :
        LET read == DecodeMessageInfo19(EncodeMessageInfo19(message))
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

(* Every Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripPacket ==
    \A message \in CheckedPacket :
        LET read == DecodePacket(EncodePacket(message))
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

(* A Finra Adf Mpid Appendage Indicator is selected by the Finra Adf Mpid Appendage Indicator it is written under *)
SelectsFinraAdfMpidAppendageIndicatorChoice ==
    \A message \in CheckedFinraAdfMpidAppendageIndicatorChoice :
        LET read == DecodeFinraAdfMpidAppendageIndicatorChoice(message.tag, EncodeFinraAdfMpidAppendageIndicatorChoice(message))
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

(* A Payload is selected by the Message Category it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Message Length is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
